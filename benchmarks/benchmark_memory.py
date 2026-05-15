import json
import os
import subprocess
import sys
import time
from datetime import datetime

CHROMA = os.path.expanduser("~/.shokunin/scripts/chroma-helper.py")
RESULTS_DIR = os.path.join(os.path.dirname(__file__), "results")
RESULTS_FILE = os.path.join(RESULTS_DIR, "results_latest.json")


def run(*args):
    result = subprocess.run(
        ["python", CHROMA] + list(args),
        capture_output=True,
        text=True,
        timeout=30,
    )
    return result.stdout.strip()


def jload(text):
    if not text:
        return []
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        return []


def seed_entries():
    """Seed ChromaDB with known entries that have specific keywords."""
    ts = datetime.utcnow().strftime("%Y%m%d%H%M%S")
    entries = {
        "exact": "BENCH_EXACT_unicorn_xkcd42_project_alpha",
        "semantic": "BENCH_SEMANTIC_auth_flow_discussion_oauth2_jwt_session_tokens",
        "temporal": "BENCH_TEMPORAL_may_2026_release_planning_deployment_schedule",
        "mixed": "BENCH_MIXED_python_package_index_pypi_install_chromadb_issues",
        "hybrid": "BENCH_HYBRID_bm25_vs_vector_search_reciprocal_rank_fusion_test",
    }

    sids = {}
    for key, text in entries.items():
        sid = f"bench-{key}-{ts}"
        sids[key] = sid
        res = run("save", text, sid, "test", "benchmark,test", "benchmark")
        assert "stored" in res, f"Seed failed for {key}: {res}"

    time.sleep(0.4)
    return sids


def find_in_results(session_id, results_list, top_n=5):
    """Check if session_id appears in top N results."""
    top = results_list[:top_n]
    for i, entry in enumerate(top):
        if entry.get("session_id", "") == session_id:
            return True, i + 1
    return False, -1


def test_query(query, expected_key, sids, strategy="search"):
    """Run a single query and check if expected session was found."""
    cmd = "search" if strategy == "search" else "recall"
    result_text = run(cmd, query, "benchmark", "5")
    results = jload(result_text)

    if not results:
        return {"found": False, "position": -1, "total": 0}

    found, pos = find_in_results(sids[expected_key], results, 5)
    return {
        "found": found,
        "position": pos,
        "total": len(results),
    }


def run_benchmark():
    """Main benchmark: compare vector-only search vs multi-strategy recall."""
    print("Shokunin Memory Benchmark")
    print("=" * 55)

    sids = seed_entries()
    print(f"Seeded {len(sids)} known entries\n")

    queries = [
        ("BENCH_EXACT_unicorn_xkcd42", "exact", "Exact keyword match"),
        ("auth_flow_oauth2_jwt_session", "semantic", "Semantic auth tokens"),
        ("May 2026 release deployment schedule", "temporal", "Temporal query"),
        ("python pip chromadb install issues", "mixed", "Mixed keywords"),
        ("BM25 vs vector RRF fusion reciprocal rank", "hybrid", "Hybrid query"),
    ]

    vector_total = 0
    multi_total = 0

    for query, key, label in queries:
        vec = test_query(query, key, sids, "search")
        mul = test_query(query, key, sids, "recall")

        vector_total += 1 if vec["found"] else 0
        multi_total += 1 if mul["found"] else 0

        v = "HIT" if vec["found"] else "MISS"
        m = "HIT" if mul["found"] else "MISS"
        print(f"  {label:30s}  vec={v}  mul={m}")

    n = len(queries)
    results = {
        "timestamp": datetime.utcnow().isoformat(),
        "total_queries": n,
        "dataset_size": "119 existing + 5 seeded entries",
        "embedding_model": "all-MiniLM-L6-v2",
        "bm25_index": "in-memory Python TF-IDF",
        "rrf_k": 60,
        "vector_only": {
            "found": vector_total,
            "recall_at_5_pct": round(vector_total / n * 100, 1),
        },
        "multi_strategy": {
            "found": multi_total,
            "recall_at_5_pct": round(multi_total / n * 100, 1),
        },
        "delta": multi_total - vector_total,
        "verdict": (
            "Vector-only search performs at parity with multi-strategy on this dataset."
            if multi_total == vector_total
            else f"Multi-strategy found {multi_total} vs vector {vector_total} queries."
        ),
        "note": "This benchmark tests recall accuracy: 'does the correct entry appear in the top 5 results?'. It does not measure end-user productivity or task completion speed.",
    }

    print(f"\n  Vector search:       {vector_total}/{n} ({results['vector_only']['recall_at_5_pct']}%)")
    print(f"  Multi-strategy:      {multi_total}/{n} ({results['multi_strategy']['recall_at_5_pct']}%)")
    print(f"\n  {results['verdict']}")
    print(f"\n  Note: {results['note']}")

    os.makedirs(RESULTS_DIR, exist_ok=True)
    with open(RESULTS_FILE, "w") as f:
        json.dump(results, f, indent=2)
    print(f"  Results saved to {RESULTS_FILE}")

    return results


if __name__ == "__main__":
    run_benchmark()
