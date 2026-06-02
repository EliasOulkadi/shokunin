"""Shokunin ChromaDB Memory CLI."""
from __future__ import annotations

import hashlib
import json
import logging as _logging
import math
import os
import re
import sys
import threading
import uuid
from collections import Counter
from datetime import datetime, timezone
from typing import Any

import chromadb
from chromadb.config import Settings

_LOGGER = _logging.getLogger("shokunin.chroma")
_LOGGER.setLevel(_logging.WARNING)

_HOME = os.getenv("USERPROFILE") or os.getenv("HOME") or os.path.expanduser("~")
BASE_DIR = os.path.join(_HOME, ".shokunin", "memory")
CHROMA_PATH = os.path.join(BASE_DIR, "chroma_db")
SESSIONS_PATH = os.path.join(BASE_DIR, "sessions")
COLLECTION_NAME = "shokunin_memory"
RECENCY_HALFLIFE_DAYS = 30
MAX_TEXT_SIZE = 50000

_client: chromadb.PersistentClient | None = None
_collection: chromadb.Collection | None = None
_lock = threading.Lock()

def _get_db() -> chromadb.Collection:
    global _client, _collection
    if _client is None:
        with _lock:
            if _client is None:
                _client = chromadb.PersistentClient(
                    path=CHROMA_PATH,
                    settings=Settings(anonymized_telemetry=False),
                )
                _collection = _client.get_or_create_collection(name=COLLECTION_NAME)
    return _collection

def _sanitize_id(sid: str) -> str:
    h = hashlib.sha256(sid.encode()).hexdigest()[:32]
    return re.sub(r'[^a-zA-Z0-9_-]', '-', h)

def _freshness_score(timestamp: str, half_life_days: int = RECENCY_HALFLIFE_DAYS) -> float:
    """Decaying recency score. 1.0 = just stored, approaches 0 for old entries."""
    if not timestamp:
        return 0.5
    try:
        ts = datetime.fromisoformat(timestamp.replace("Z", "+00:00"))
        if ts.tzinfo is None:
            ts = ts.replace(tzinfo=timezone.utc)
        days = (datetime.now(timezone.utc) - ts).total_seconds() / 86400.0
        return math.exp(-days * math.log(2) / max(half_life_days, 1))
    except (ValueError, TypeError):
        return 0.5

def save(text: str, session_id: str, entry_type: str = "general", tags: list[str] | None = None, project: str = "") -> dict[str, Any]:
    if not text or not session_id:
        return {"error": "text and session_id required", "stored": False}
    if len(text) > MAX_TEXT_SIZE:
        text = text[:MAX_TEXT_SIZE]
    tags = tags or []
    entry_id = str(uuid.uuid4())
    timestamp = datetime.now(timezone.utc).isoformat()
    metadata = {
        "type": entry_type,
        "tags": json.dumps(tags),
        "project": project,
        "session_id": session_id,
        "timestamp": timestamp,
    }
    _get_db().add(documents=[text], metadatas=[metadata], ids=[entry_id])
    os.makedirs(SESSIONS_PATH, exist_ok=True)
    safe_id = _sanitize_id(session_id)
    filepath = os.path.join(SESSIONS_PATH, f"{safe_id}.md")
    with open(filepath, "a", encoding="utf-8") as f:
        f.write(f"## {timestamp} | type: {entry_type}\n- **project:** {project}\n- **tags:** {json.dumps(tags)}\n\n{text}\n\n---\n")
    return {"id": entry_id, "stored": True}

def search(query: str, project: str | None = None, n_results: int = 10, freshness_boost: float = 0.0) -> list[dict[str, Any]]:
    where_filter = {"project": project} if project else None
    try:
        results = _get_db().query(query_texts=[query], n_results=n_results, where=where_filter)
    except Exception as e:
        _LOGGER.warning(f"Search query failed: {e}")
        return []
    entries = []
    if results.get("ids") and results["ids"][0]:
        for i in range(len(results["ids"][0])):
            meta = results["metadatas"][0][i]
            dist = results["distances"][0][i]
            vector_sim = 1.0 / (1.0 + dist)
            if freshness_boost > 0:
                recency = _freshness_score(meta.get("timestamp", ""))
                sim = round((1.0 - freshness_boost) * vector_sim + freshness_boost * recency, 4)
            else:
                sim = round(vector_sim, 4)
            try:
                entry_tags = json.loads(meta.get("tags", "[]"))
            except (json.JSONDecodeError, TypeError):
                entry_tags = []
            entries.append({
                "text": results["documents"][0][i][:500],
                "type": meta.get("type", "general"),
                "tags": entry_tags,
                "project": meta.get("project", ""),
                "session_id": meta.get("session_id", ""),
                "timestamp": meta.get("timestamp", ""),
                "similarity": sim,
            })
    entries.sort(key=lambda e: e["similarity"], reverse=True)
    return entries

def _tokenize(text: str) -> list[str]:
    return re.findall(r'\w+', text.lower())

def _bm25(query_tokens: list[str], doc_tokens: list[str], avgdl: float, N: int, df: dict[str, int], k1: float = 1.5, b: float = 0.75) -> float:
    score = 0.0
    for qt in set(query_tokens):
        if qt not in df or df[qt] == 0:
            continue
        idf = math.log((N - df[qt] + 0.5) / (df[qt] + 0.5) + 1.0)
        tf = doc_tokens.count(qt)
        score += idf * (tf * (k1 + 1)) / (tf + k1 * (1 - b + b * len(doc_tokens) / max(avgdl, 1)))
    return score

def _build_bm25_index(entries: list[dict[str, Any]]) -> tuple[list[list[str]], dict[str, int], float, int]:
    index = []
    N = len(entries)
    df: dict[str, int] = Counter()  # type: ignore[assignment]
    all_tokens = []
    for e in entries:
        tokens = _tokenize(e.get("text", ""))
        index.append(tokens)
        all_tokens.extend(tokens)
        for t in set(tokens):
            df[t] += 1
    avgdl = len(all_tokens) / max(N, 1)
    return index, df, avgdl, N

def _in_date_range(entry: dict[str, Any], from_date: str | None = None, to_date: str | None = None) -> bool:
    ts = entry.get("timestamp", "")
    if not ts:
        return True
    date_part = ts[:10]
    if from_date and date_part < from_date:
        return False
    if to_date and date_part > to_date:
        return False
    return True

def _rrf_fuse(ranked_lists: list[tuple[list[dict[str, Any]], str]], k: int = 60) -> list[dict[str, Any]]:
    scores: dict[str, float] = {}
    all_items: dict[str, dict[str, Any]] = {}
    for rank_list, source in ranked_lists:
        for rank, item in enumerate(rank_list):
            sid = item.get("session_id") or item.get("session", "")
            txt = item.get("text", "")[:80]
            key = f"{sid}:{hashlib.sha256(txt.encode()).hexdigest()[:12]}"
            scores[key] = scores.get(key, 0) + 1.0 / (k + rank)
            all_items[key] = item
    ranked = sorted(scores.items(), key=lambda x: -x[1])
    return [all_items[key] for key, _ in ranked]

def recall(query: str, project: str | None = None, n_results: int = 10, from_date: str | None = None, to_date: str | None = None, freshness_boost: float = 0.0) -> list[dict[str, Any]]:
    vector_results = search(query, project, n_results * 2, freshness_boost=freshness_boost)
    vector_results = [e for e in vector_results if _in_date_range(e, from_date, to_date)]

    sessions_dir = SESSIONS_PATH
    md_entries = []
    if os.path.isdir(sessions_dir):
        for fname in sorted(os.listdir(sessions_dir)):
            if fname.endswith(".md") and not fname.endswith("-parsed.md"):
                fpath = os.path.join(sessions_dir, fname)
                try:
                    with open(fpath, encoding="utf-8", errors="replace") as f:
                        content = f.read()
                    if content.strip():
                        md_entries.append({"text": content, "session": fname.replace(".md", "")})
                except Exception as e:
                    _LOGGER.warning(f"Failed to read md file {fname}: {e}")
                    pass

    try:
        where_filter = {"project": project} if project else None
        chroma_data = _get_db().get(limit=500, where=where_filter)
        chroma_entries = []
        if chroma_data.get("ids"):
            for i in range(len(chroma_data["ids"])):
                sid = chroma_data["metadatas"][i].get("session_id", "")
                if sid and sid != "unknown":
                    chroma_entries.append({"text": chroma_data["documents"][i], "session_id": sid})
    except Exception as e:
        _LOGGER.warning(f"Failed to get chroma data: {e}")
        chroma_entries = []

    bm25_results = []
    chroma_session_ids = {e.get("session_id", "") for e in chroma_entries}
    all_entries = chroma_entries + [e for e in md_entries if e["session"] not in chroma_session_ids]
    if all_entries:
        index, df, avgdl, N = _build_bm25_index(all_entries)
        qt = _tokenize(query)
        scored = []
        for i, tokens in enumerate(index):
            score = _bm25(qt, tokens, avgdl, N, df)
            if score > 0:
                entry = all_entries[i]
                scored.append({"text": entry["text"][:500], "session_id": entry.get("session_id") or entry.get("session", ""), "bm25_score": round(score, 4)})
        scored.sort(key=lambda x: -x["bm25_score"])
        bm25_results = scored[:n_results]

    fused = _rrf_fuse([(vector_results, "vector"), (bm25_results, "bm25")], k=60)
    return fused[:n_results]


def consolidate(project: str | None = None, max_entries: int = 100) -> dict[str, Any]:
    try:
        where_filter = {"project": project} if project else None
        all_data = _get_db().get(limit=max_entries, where=where_filter)
    except Exception:
        return {"consolidated": 0, "message": "query failed"}

    if not all_data.get("ids"):
        return {"consolidated": 0, "message": "no entries"}

    projects: dict[str, list[Any]] = {}
    for i in range(len(all_data["ids"])):
        meta = all_data["metadatas"][i]
        p = meta.get("project", "unknown")
        if p not in projects:
            projects[p] = []
        projects[p].append(all_data["documents"][i][:300])

    consolidated = 0
    for proj, texts in projects.items():
        tokens = []
        for t in texts:
            tokens.extend(_tokenize(t))
        common = [w for w, _ in Counter(tokens).most_common(10) if len(w) > 3][:5]
        word_count = sum(len(t.split()) for t in texts)
        summary = (
            f"Consolidated: {len(texts)} entries, ~{word_count} words total.\n"
            f"Project: {proj}\n"
            f"Key terms: {', '.join(common)}"
        )
        save(summary, f"consolidated-{proj}", "consolidated", ["consolidated", proj], proj)
        consolidated += 1

    return {"consolidated": consolidated}


def session_list(limit: int = 5, project: str | None = None, page: int = 1, per_page: int = 10, brief: bool = False) -> list[dict[str, Any]]:
    try:
        where_filter = {"project": project} if project else None
        all_data = _get_db().get(limit=500, where=where_filter)
    except Exception:
        return []

    summ_len = 150 if brief else 300
    session_ids = {}
    if all_data.get("ids"):
        for i in range(len(all_data["ids"])):
            meta = all_data["metadatas"][i]
            sid = meta.get("session_id", "")
            proj = meta.get("project", "")
            if not sid or sid == "unknown":
                continue
            if proj in ("healthcheck", "healthcheck-project", "test-project", "ci-project"):
                continue
            if sid not in session_ids:
                session_ids[sid] = {
                    "session_id": sid,
                    "first_ts": meta.get("timestamp", ""),
                    "last_ts": meta.get("timestamp", ""),
                    "project": proj,
                    "entry_count": 0,
                    "types": set(),
                    "summary": all_data["documents"][i][:summ_len],
                }
            session_ids[sid]["last_ts"] = meta.get("timestamp", "")
            session_ids[sid]["entry_count"] += 1
            session_ids[sid]["types"].add(meta.get("type", ""))

    sessions = list(session_ids.values())
    sessions = [s for s in sessions if not (
        s["session_id"].startswith("healthcheck-") or
        s["session_id"].startswith("mcp-test-") or
        s["session_id"].startswith("test-") or
        s["session_id"].startswith("consolidated-") or
        s["session_id"].startswith("sesion-") or
        s["session_id"] in ("entries", "file", "session_end") or
        (set(s["types"]) <= {"test", "general"} and s["entry_count"] <= 2) or
        not any(t for t in s["types"] if t)
    )]
    sessions.sort(key=lambda s: s["first_ts"] or "", reverse=True)
    sessions.sort(key=lambda s: "session_end" in s["types"], reverse=True)
    for s in sessions:
        s["types"] = sorted(list(s["types"]))
    start = (page - 1) * per_page
    return sessions[start:start + per_page][:limit]


def _parse_section(text: str, header: str) -> list[str]:
    lines = text.split("\n")
    in_section = False
    items = []
    for line in lines:
        stripped = line.strip()
        if stripped.lower().startswith(header.lower()):
            in_section = True
            continue
        if in_section and not stripped:
            in_section = False
            continue
        if in_section and (stripped.startswith("-") or stripped.startswith("*")) and len(stripped) > 3:
            items.append(stripped.lstrip("- * ")[:300])
    return items

def _parse_session_text(text: str) -> dict[str, list[str]]:
    extracted: dict[str, list[str]] = {"decisions": [], "files": [], "commands": [], "checkpoints": []}
    for pattern_name, patterns in [
        ("decisions", ["## decisions", "## decisiones", "decisions:", "decisiones:", "## what we decided"]),
        ("files", ["## files", "## archivos", "files changed:", "archivos cambiados:", "archivos modificados:", "files modified:"]),
        ("commands", ["## commands", "## comandos", "commands:", "comandos:"]),
        ("checkpoints", ["## checkpoints"]),
    ]:
        for p in patterns:
            extracted[pattern_name].extend(_parse_section(text, p))
    for line in text.split("\n"):
        stripped = line.strip()
        if stripped.lower().startswith("archivo:") or stripped.lower().startswith("file:"):
            extracted["files"].append(stripped[:300])
        if stripped.lower().startswith("decision") and ":" in stripped[:20]:
            extracted["decisions"].append(stripped[:300])
        if stripped.lower().startswith("comando:") or stripped.lower().startswith("command:"):
            extracted["commands"].append(stripped[:300])
    in_files = False
    for line in text.split("\n"):
        stripped = line.strip()
        if re.match(r'^\d+\.\s*files?\s*(changed|modif|creat|touched)', stripped, re.IGNORECASE):
            in_files = True
            continue
        if in_files and not stripped:
            in_files = False
        if in_files and (stripped.startswith("-") or stripped.startswith("*")):
            extracted["files"].append(stripped.lstrip("- * ")[:300])
    return extracted

def session_continue(session_id: str, summary_only: bool = False) -> dict[str, Any]:
    if not session_id:
        return {"error": "session_id required", "entries": []}
    all_data = _get_db().get(where={"session_id": session_id}, limit=1000)
    if not all_data.get("ids"):
        return {"session_id": session_id, "entry_count": 0, "entries": []}

    entries = []
    full_decisions = []
    full_files = []
    full_commands = []
    full_checkpoints = []

    for i in range(len(all_data["ids"])):
        meta = all_data["metadatas"][i]
        text = all_data["documents"][i]
        etype = meta.get("type", "")
        try:
            entry_tags = json.loads(meta.get("tags", "[]"))
        except (json.JSONDecodeError, TypeError):
            entry_tags = []
        entry = {
            "text": text[:400] if summary_only else text[:2000],
            "type": etype,
            "tags": entry_tags,
            "project": meta.get("project", ""),
            "timestamp": meta.get("timestamp", ""),
        }
        entries.append(entry)

        if etype == "session_end":
            parsed = _parse_session_text(text)
            full_decisions.extend(parsed["decisions"])
            full_files.extend(parsed["files"])
            full_commands.extend(parsed["commands"])
        elif etype == "decision":
            full_decisions.append(text[:300])
        elif etype == "file":
            full_files.append(text[:300])
        elif etype == "command":
            full_commands.append(text[:300])
        elif etype == "checkpoint":
            full_checkpoints.append(text[:300])

    result = {
        "session_id": session_id,
        "entry_count": len(entries),
        "context": {
            "session_ends": len([e for e in entries if e["type"] == "session_end"]),
            "decisions": len(full_decisions),
            "decisions_list": full_decisions[:10],
            "files_modified": len(full_files),
            "files_list": full_files[:10],
            "commands": len(full_commands),
            "commands_list": full_commands[:5],
            "checkpoints": len(full_checkpoints),
        },
    }
    if not summary_only:
        result["entries"] = entries
    safe_id = _sanitize_id(session_id)
    jsonl_path = os.path.join(SESSIONS_PATH, f"{safe_id}.jsonl")
    jsonl_messages = []
    if os.path.isfile(jsonl_path):
        try:
            with open(jsonl_path, encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if line:
                        jsonl_messages.append(json.loads(line))
        except Exception as e:
            _LOGGER.warning(f"Failed to read jsonl for {session_id}: {e}")
            pass
    result["jsonl_count"] = len(jsonl_messages)
    if not summary_only and jsonl_messages:
        result["jsonl_messages"] = jsonl_messages[-20:]
    return result


def session_save(text: str, session_id: str, role: str = "user") -> dict[str, Any]:
    if not text or not session_id:
        return {"error": "text and session_id required", "stored": False}
    ts = datetime.now(timezone.utc).isoformat()
    entry = json.dumps({"t": "msg", "ts": ts, "role": role, "content": text}, ensure_ascii=False)
    safe_id = _sanitize_id(session_id)
    filepath = os.path.join(SESSIONS_PATH, f"{safe_id}.jsonl")
    os.makedirs(SESSIONS_PATH, exist_ok=True)
    with open(filepath, "a", encoding="utf-8") as f:
        f.write(entry + "\n")
    return {"stored": True, "file": filepath}


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    if cmd == "save" and len(sys.argv) >= 4:
        text = sys.argv[2]
        sid = sys.argv[3]
        etype = sys.argv[4] if len(sys.argv) > 4 else "general"
        tags = sys.argv[5].split(",") if len(sys.argv) > 5 and sys.argv[5] else []
        project = sys.argv[6] if len(sys.argv) > 6 else ""
        result = save(text, sid, etype, tags, project)
        print(json.dumps(result))
    elif cmd == "search" and len(sys.argv) >= 3:
        query = sys.argv[2]
        project = sys.argv[3] if len(sys.argv) > 3 else None  # type: ignore[assignment]
        n_results = min(int(sys.argv[4]), 50) if len(sys.argv) > 4 else 10
        freshness_boost = float(sys.argv[5]) if len(sys.argv) > 5 else 0.0
        result: Any = search(query, project, n_results, freshness_boost)  # type: ignore[no-redef]
        print(json.dumps(result))
    elif cmd == "recall" and len(sys.argv) >= 3:
        query = sys.argv[2]
        project = sys.argv[3] if len(sys.argv) > 3 else None  # type: ignore[assignment]
        n_results = min(int(sys.argv[4]), 50) if len(sys.argv) > 4 else 10
        from_date = sys.argv[5] if len(sys.argv) > 5 else None
        to_date = sys.argv[6] if len(sys.argv) > 6 else None
        freshness_boost = float(sys.argv[7]) if len(sys.argv) > 7 else 0.0
        result: Any = recall(query, project, n_results, from_date, to_date, freshness_boost)  # type: ignore[no-redef]
        print(json.dumps(result))
    elif cmd == "consolidate":
        project = sys.argv[2] if len(sys.argv) > 2 else None  # type: ignore[assignment]
        result: Any = consolidate(project)  # type: ignore[no-redef]
        print(json.dumps(result))
    elif cmd == "recent":
        n_results = int(sys.argv[2]) if len(sys.argv) > 2 else 10
        try:
            all_results = _get_db().get(limit=n_results)
            entries = []
            if all_results.get("ids"):
                for i in range(len(all_results["ids"])):
                    meta = all_results["metadatas"][i]
                    try:
                        entry_tags = json.loads(meta.get("tags", "[]"))
                    except (json.JSONDecodeError, TypeError):
                        entry_tags = []
                    entries.append({
                        "text": all_results["documents"][i][:500],
                        "type": meta.get("type", "general"),
                        "tags": entry_tags,
                        "project": meta.get("project", ""),
                        "session_id": meta.get("session_id", ""),
                        "timestamp": meta.get("timestamp", ""),
                    })
            print(json.dumps(entries))
        except Exception as e:
            print(json.dumps({"error": str(e)}))
    elif cmd == "count":
        print(json.dumps({"count": _get_db().count()}))
    elif cmd == "delete" and len(sys.argv) >= 3:
        tag_filter = sys.argv[2]
        try:
            ids_to_delete = []
            offset = 0
            while True:
                batch = _get_db().get(limit=1000, offset=offset)
                if not batch.get("ids"):
                    break
                for i in range(len(batch["ids"])):
                    meta = batch["metadatas"][i]
                    try:
                        entry_tags = json.loads(meta.get("tags", "[]"))
                    except (json.JSONDecodeError, TypeError):
                        entry_tags = []
                    if tag_filter in entry_tags or meta.get("project") == tag_filter:
                        ids_to_delete.append(batch["ids"][i])
                offset += len(batch["ids"])
            if ids_to_delete:
                _get_db().delete(ids=ids_to_delete)
            print(json.dumps({"deleted": len(ids_to_delete), "tag_filter": tag_filter}))
        except Exception as e:
            print(json.dumps({"error": str(e), "deleted": 0}))
    elif cmd == "session" and len(sys.argv) >= 3:
        sub = sys.argv[2]
        if sub == "list":
            brief = "--brief" in sys.argv
            limit = int(sys.argv[3]) if len(sys.argv) > 3 and not sys.argv[3].startswith("--") else 3
            project = sys.argv[4] if len(sys.argv) > 4 and not sys.argv[4].startswith("--") else None  # type: ignore[assignment]
            print(json.dumps(session_list(limit, project, brief=brief)))
        elif sub == "continue" and len(sys.argv) >= 4:
            summary_only = "--summary" in sys.argv
            print(json.dumps(session_continue(sys.argv[3], summary_only=summary_only)))
        elif sub == "save" and len(sys.argv) >= 5:
            print(json.dumps(session_save(sys.argv[3], sys.argv[4], sys.argv[5] if len(sys.argv) > 5 else "user")))
        else:
            print(json.dumps({"error": "session list|continue|save"}))
    else:
        print(json.dumps({"error": "Usage: save|search|recall|consolidate|count|recent|session"}))
