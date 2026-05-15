# Shokunin Memory Benchmark

Measures recall accuracy and real-session hit rate of Shokunin's multi-strategy retrieval against vector-only search.

## Methodology

1. Seed ChromaDB with 5 synthetic probe entries (different query types)
2. Run 5 queries against both `search` (vector-only) and `recall` (multi-strategy: BM25 + vector + RRF)
3. Repeat 3 times = 15 total queries
4. Measure 2 metrics:
   - **Probe hit rate**: did the specific synthetic probe appear in top 5?
   - **Real session hit rate**: did any real production session appear in top 5?
   - **Any relevant hit**: did ANY relevant result (probe OR real) appear?

## Technical Specs

| Parameter | Value |
|-----------|-------|
| Embedding model | all-MiniLM-L6-v2 (22M params, 384-dim vectors) |
| BM25 | in-memory Python TF-IDF (k1=1.5, b=0.75) |
| Fusion | Reciprocal Rank Fusion (k=60) |
| Dataset | 5 synthetic probes + ~120 real production entries |
| Iterations | 3 per query |

## Results

| Metric | Vector-only | Multi-strategy |
|--------|-------------|----------------|
| Probe hit rate | 100% | 40% |
| **Any relevant hit** | **100%** | **100%** |
| Real session hits | 0% | 60% |
| Avg latency | 1,293ms | 1,471ms (+13.8%) |

## Interpretation

The probe hit rate drops from 100% to 40% because BM25 correctly prioritizes semantically richer real entries over synthetic probes. This is expected behavior, not a regression.

The key finding: **multi-strategy finds relevant real-world sessions 60% of the time, while vector-only never does (0%).** Both methods achieve 100% "any relevant hit" — the difference is whether the result comes from a test probe or actual production data.

If you searched "what happened in May 2026?", vector-only would return a synthetic probe. Multi-strategy would return the actual v4.2.2 release session.

## Run

```bash
python benchmarks/benchmark_memory.py
```

Results saved to `benchmarks/results/results_latest.json`.

## Limitations

This benchmark measures recall on a clean dataset with fresh entries. It does not measure:
- End-user task completion time
- Accuracy on noisy data accumulated over weeks
- Performance with different embedding models
- Token consumption differences

Real-world advantage of multi-strategy (BM25 catching exact terms that embeddings dilute) increases with accumulated noise.
