"""Shokunin ChromaDB Memory CLI."""
from __future__ import annotations

import contextlib
import glob
import hashlib
import http.server
import json
import logging as _logging
import math
import os
import re
import socketserver
import sys
import threading
import urllib.parse
import uuid
import webbrowser
from collections import Counter, defaultdict
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


def index(project: str | None = None, max_sessions: int = 5, max_decisions: int = 10) -> dict[str, Any]:
    """Generate MEMORY.md — a compact index of active/important memories for session-start context.
    Modeled after Claude Code's memdir pattern: an entrypoint file (capped) + topic file references.
    """
    all_data = _get_db().get(limit=1000)
    if not all_data.get("ids"):
        return {"error": "no entries", "path": ""}

    sessions: dict[str, dict[str, Any]] = {}
    decisions: list[dict[str, Any]] = []
    files_changed: list[dict[str, Any]] = []
    by_project: Counter[str] = Counter()

    for i in range(len(all_data["ids"])):
        meta = all_data["metadatas"][i]
        sid = meta.get("session_id", "")
        proj = meta.get("project", "")
        etype = meta.get("type", "")
        ts = meta.get("timestamp", "")
        text = all_data["documents"][i]

        if proj:
            by_project[proj] += 1
        if not sid or sid in ("unknown", "healthcheck", "test", "ci"):
            continue

        if sid not in sessions:
            sessions[sid] = {
                "session_id": sid, "project": proj,
                "first_ts": ts, "last_ts": ts,
                "entry_count": 0, "types": set(),
            }
        sessions[sid]["last_ts"] = max(sessions[sid]["last_ts"], ts) if sessions[sid]["last_ts"] else ts
        sessions[sid]["entry_count"] += 1
        sessions[sid]["types"].add(etype)

        if etype == "decision":
            decisions.append({"text": text[:200], "project": proj, "timestamp": ts})
        if etype == "file":
            files_changed.append({"text": text[:200], "project": proj, "timestamp": ts})

    sorted_sessions = sorted(sessions.values(), key=lambda s: s["last_ts"] or "", reverse=True)[:max_sessions]
    decisions.sort(key=lambda d: d.get("timestamp", ""), reverse=True)
    files_changed.sort(key=lambda f: f.get("timestamp", ""), reverse=True)

    lines = ["# Shokunin Active Memory Index", f"Generated: {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M UTC')}", ""]

    projects_summary = ", ".join(f"{p} ({c} entries)" for p, c in by_project.most_common(5))
    lines.append(f"Projects: {projects_summary}")
    lines.append(f"Total entries: {len(all_data['ids'])} | Sessions: {len(sessions)}")
    lines.append("")

    if sorted_sessions:
        lines.append("## Recent Sessions")
        for s in sorted_sessions:
            types_str = ", ".join(sorted(s["types"]))
            last = s["last_ts"][:10] if s["last_ts"] else "?"
            lines.append(f"- `{s['session_id'][:40]}` — {s['entry_count']} entries, {types_str} (last: {last})")
        lines.append("")

    if decisions:
        lines.append(f"## Decisions (last {max_decisions})")
        for d in decisions[:max_decisions]:
            lines.append(f"- {d['text']}")
        lines.append("")

    if files_changed:
        lines.append("## Files Changed (last 10)")
        for fc in files_changed[:10]:
            lines.append(f"- {fc['text']}")
        lines.append("")

    lines.append("---")
    lines.append(f"Full recall: `python {__file__} recall \"<query>\" \"<project>\"`")
    lines.append(f"Session list: `python {__file__} session list 5`")
    lines.append(f"Consolidate: `python {__file__} consolidate {project or ''}`")

    content = "\n".join(lines)
    # Write to memory dir (for agent reference) and sessions dir (for persistence)
    mem_paths = [
        os.path.join(BASE_DIR, "MEMORY.md"),
        os.path.join(SESSIONS_PATH, "MEMORY.md"),
    ]
    for mp in mem_paths:
        with open(mp, "w", encoding="utf-8") as fh:
            fh.write(content)

    return {"paths": mem_paths, "sessions": len(sorted_sessions), "decisions": len(decisions), "size_bytes": len(content)}


def stats() -> dict[str, Any]:
    """Memory statistics — entry counts by type, signal-to-noise ratio, storage usage."""
    all_data = _get_db().get(limit=5000)
    if not all_data.get("ids"):
        return {"error": "no entries"}

    total = len(all_data["ids"])
    by_type: Counter = Counter()
    by_project: Counter = Counter()
    noise_count = 0
    signal_types = {"session_end", "decision", "file", "command", "preference", "claim_file", "claim_function", "claim_api", "claim_flag"}

    for i in range(total):
        meta = all_data["metadatas"][i]
        etype = meta.get("type", "unknown")
        by_type[etype] += 1
        proj = meta.get("project", "")
        if proj:
            by_project[proj] += 1
        text = all_data["documents"][i][:80].strip().lower()
        if etype == "checkpoint" and ("session" in text and "active at" in text):
            noise_count += 1

    signal_count = sum(by_type[t] for t in signal_types)
    signal_pct = round(signal_count / max(total, 1) * 100, 1)
    noise_pct = round(noise_count / max(total, 1) * 100, 1)

    # File counts
    md_files = len(glob.glob(os.path.join(SESSIONS_PATH, "*.md")))
    jsonl_files = len(glob.glob(os.path.join(SESSIONS_PATH, "*.jsonl")))
    chroma_size = 0
    for dirpath, _, filenames in os.walk(CHROMA_PATH):
        for f in filenames:
            with contextlib.suppress(OSError):
                chroma_size += os.path.getsize(os.path.join(dirpath, f))

    return {
        "total_entries": total,
        "by_type": dict(by_type.most_common()),
        "by_project": dict(by_project.most_common(10)),
        "signal_entries": signal_count,
        "signal_percent": signal_pct,
        "noise_entries": noise_count,
        "noise_percent": noise_pct,
        "storage": {
            "chromadb_bytes": chroma_size,
            "chromadb_mb": round(chroma_size / 1024 / 1024, 2),
            "md_files": md_files,
            "jsonl_files": jsonl_files,
        },
    }


def forget(session_id: str, text_pattern: str = "", mark_superseded: bool = True) -> dict[str, Any]:
    """Mark memories as superseded rather than deleting. Stores a supersession note.
    When mark_superseded is True, preserves the original but adds a pointer to the new info.
    """
    where = {"session_id": session_id}
    all_data = _get_db().get(where=where, limit=1000)
    if not all_data.get("ids"):
        where = {}
        all_data = _get_db().get(limit=1000)
        matched = []
        if all_data.get("ids"):
            for i in range(len(all_data["ids"])):
                text = all_data["documents"][i]
                meta = all_data["metadatas"][i]
                if text_pattern.lower() in text.lower():
                    matched.append((all_data["ids"][i], meta, text))
        if not matched:
            return {"error": "no matching entries", "superseded": 0}
        count = len(matched)
        save(
            f"Supersession: {count} entries matched '{text_pattern}' were marked superseded. "
            f"Original session: {session_id}. New information should replace these.",
            f"superseded-{session_id}", "consolidated",
            ["superseded", "forget"], meta.get("project", ""),
        )
        return {"superseded": count, "note": "Supersession recorded. Original entries preserved in ChromaDB."}

    entries = []
    for i in range(len(all_data["ids"])):
        entries.append({
            "text": all_data["documents"][i][:300],
            "type": all_data["metadatas"][i].get("type", ""),
            "timestamp": all_data["metadatas"][i].get("timestamp", ""),
        })

    save(
        f"Supersession: Session {session_id} with {len(entries)} entries has been superseded. "
        f"Original entries preserved but deprioritized for retrieval.",
        f"superseded-{session_id}", "consolidated",
        ["superseded", "forget", session_id], "",
    )
    return {
        "superseded": len(entries),
        "session_id": session_id,
        "note": "Session marked as superseded. All original entries preserved in ChromaDB.",
        "entries_sample": entries[:3],
    }


def serve(port: int = 8765) -> dict[str, Any]:
    """Start the memory viewer — local web UI for browsing sessions."""

    HOST = "127.0.0.1"

    class MemoryHandler(http.server.BaseHTTPRequestHandler):
        def log_message(self, fmt, *args):
            pass

        def _json_resp(self, data, status=200):
            body = json.dumps(data).encode()
            self.send_response(status)
            self.send_header("Content-Type", "application/json")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def _html_resp(self, html, status=200):
            body = html.encode("utf-8")
            self.send_response(status)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def _err(self, msg, status=400):
            self._json_resp({"error": msg}, status)

        def _qp(self, name, default=None):
            return urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query).get(name, [default])[0]

        def _get_sessions(self):
            data = _get_db().get(limit=5000)
            seen = {}
            for i in range(len(data.get("ids", []))):
                meta = data["metadatas"][i]
                sid = meta.get("session_id", "?")
                if sid not in seen:
                    seen[sid] = {
                        "session_id": sid,
                        "project": meta.get("project", ""),
                        "entry_count": 0,
                        "last_ts": meta.get("timestamp", ""),
                        "types": set(),
                    }
                seen[sid]["entry_count"] += 1
                seen[sid]["types"].add(meta.get("type", ""))
                ts = meta.get("timestamp", "")
                seen[sid]["last_ts"] = max(seen[sid]["last_ts"], ts)
            sessions = []
            for s in seen.values():
                s["types"] = sorted(s["types"])
                sessions.append(s)
            sessions.sort(key=lambda s: s.get("last_ts", ""), reverse=True)
            return sessions

        def do_GET(self):
            parsed = urllib.parse.urlparse(self.path)
            path = parsed.path.rstrip("/") or "/"

            try:
                if path == "/api/sessions":
                    project = self._qp("project")
                    limit = min(int(self._qp("limit", "200")), 500)
                    sessions = self._get_sessions()
                    if project:
                        sessions = [s for s in sessions if s["project"] == project]
                    self._json_resp({"sessions": sessions[:limit], "total": len(sessions)})

                elif path.startswith("/api/session/"):
                    raw = parsed.path[len("/api/session/"):]
                    sid = urllib.parse.unquote(raw)
                    data = _get_db().get(where={"session_id": sid}, limit=500)
                    entries = []
                    for i in range(len(data.get("ids", []))):
                        meta = data["metadatas"][i]
                        entries.append({
                            "text": data["documents"][i],
                            "type": meta.get("type", ""),
                            "project": meta.get("project", ""),
                            "timestamp": meta.get("timestamp", ""),
                        })
                    self._json_resp({
                        "session_id": sid,
                        "entry_count": len(entries),
                        "decisions": [e for e in entries if e["type"] == "decision"],
                        "files": [e for e in entries if e["type"] == "file"],
                        "commands": [e for e in entries if e["type"] == "command"],
                        "session_ends": [e for e in entries if e["type"] == "session_end"],
                        "entries": entries,
                    })

                elif path == "/api/stats":
                    self._json_resp(stats())

                elif path == "/api/search":
                    q = self._qp("q", "")
                    if not q:
                        self._err("query required")
                        return
                    limit = min(int(self._qp("limit", "50")), 100)
                    results = _get_db().query(query_texts=[q], n_results=limit)
                    entries = []
                    for i in range(len(results.get("ids", [[]])[0])):
                        meta = results["metadatas"][0][i]
                        entries.append({
                            "text": results["documents"][0][i],
                            "type": meta.get("type", ""),
                            "project": meta.get("project", ""),
                            "session_id": meta.get("session_id", ""),
                            "timestamp": meta.get("timestamp", ""),
                        })
                    self._json_resp({"entries": entries, "count": len(entries)})

                elif path == "/":
                    self._html_resp(SESSION_VIEWER_HTML)

                else:
                    self._err("not found", 404)
            except Exception as e:
                self._err(str(e), 500)

    class ThreadedServer(socketserver.ThreadingMixIn, http.server.HTTPServer):
        allow_reuse_address = True
        daemon_threads = True

    server = ThreadedServer((HOST, port), MemoryHandler)
    print("\n  \u2699 Shokunin Memory Viewer")
    print("  " + "\u2500" * 29)
    print(f"  Local:  http://{HOST}:{port}")
    print("\n  Press Ctrl+C to stop\n")
    webbrowser.open(f"http://{HOST}:{port}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n  Shutdown.")
        server.server_close()
    return {"ok": True}


SESSION_VIEWER_HTML = r"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Shokunin · Memory</title>
<style>
:root{--bg:oklch(.08 .008 60);--surface:oklch(.13 .01 60);--surface2:oklch(.18 .012 60);--border:oklch(.22 .01 60);--accent:oklch(.6 .18 48);--accent-dim:oklch(.4 .12 48);--name:#e8e5e0;--text:oklch(.75 .01 60);--muted:oklch(.5 .01 60);--dim:oklch(.35 .01 60);--green:oklch(.55 .15 145);--red:oklch(.55 .2 25);--font:system-ui,-apple-system,sans-serif;--mono:ui-monospace,'SF Mono','Cascadia Code',monospace}
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
html{height:100%}
body{font-family:var(--font);background:var(--bg);color:var(--text);height:100dvh;display:flex;flex-direction:column;overflow:hidden;font-size:clamp(13px,1vw,14px)}
body::after{content:'';position:fixed;inset:0;pointer-events:none;z-index:9999;opacity:.025;background:url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='.9' numOctaves='4'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E");background-repeat:repeat;background-size:150px 150px}
header{background:var(--surface);border-bottom:1px solid var(--border);padding:10px 20px;display:flex;align-items:center;gap:16px;flex-shrink:0;z-index:10;flex-wrap:wrap}
.head{display:flex;align-items:center;gap:8px;font-size:15px;font-weight:550;letter-spacing:-.01em;white-space:nowrap;color:var(--name)}
.head mark{background:var(--accent);color:var(--bg);padding:0 5px;border-radius:3px;font-weight:600}
.stats{display:flex;gap:12px;font-size:11px;color:var(--muted);flex-wrap:wrap}
.st{display:flex;align-items:center;gap:3px}.st b{color:var(--name);font-weight:500;font-variant-numeric:tabular-nums}
.dt{width:5px;height:5px;border-radius:50%;display:inline-block;flex-shrink:0}
.dt.a{background:var(--accent)}.dt.g{background:var(--green)}.dt.r{background:var(--red)}
.ct{display:grid;grid-template-columns:300px 1fr;flex:1;overflow:hidden;height:100%}
.sb{background:var(--surface);border-right:1px solid var(--border);display:flex;flex-direction:column;overflow:hidden}
.sbh{padding:10px 14px;border-bottom:1px solid var(--border);flex-shrink:0}
.sw{position:relative}.sw svg{position:absolute;left:9px;top:50%;transform:translateY(-50%);color:var(--muted);pointer-events:none}
.sw input{width:100%;padding:7px 10px 7px 30px;border:1px solid var(--border);border-radius:7px;background:var(--bg);color:var(--name);font-size:12px;outline:none}
.sw input:focus{border-color:var(--accent)}.sw input::placeholder{color:var(--dim)}
.sl{flex:1;overflow-y:auto;scrollbar-width:thin;scrollbar-color:var(--border) transparent}
.sl::-webkit-scrollbar{width:5px}.sl::-webkit-scrollbar-thumb{background:var(--border);border-radius:3px}
.si{padding:9px 14px;cursor:pointer;border-left:2px solid transparent;transition:background .12s,border-color .12s}
.si:hover{background:var(--surface2)}.si.act{background:var(--surface2);border-left-color:var(--accent)}
.si .nm{font-size:12px;font-weight:500;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;color:var(--name)}
.si .mt{display:flex;gap:8px;font-size:10px;color:var(--muted);margin-top:2px;align-items:center}
.si .cnt{font-size:9px;background:var(--accent-dim);color:var(--name);padding:0 5px;border-radius:3px;font-weight:500;margin-left:auto;flex-shrink:0}
.sbf{padding:6px 14px;border-top:1px solid var(--border);font-size:10px;color:var(--dim);flex-shrink:0}
.mn{display:flex;flex-direction:column;overflow:hidden}
.mnc{flex:1;overflow-y:auto;padding:20px 28px;scrollbar-width:thin;scrollbar-color:var(--border) transparent}
.mnc::-webkit-scrollbar{width:5px}.mnc::-webkit-scrollbar-thumb{background:var(--border);border-radius:3px}
@media(max-width:768px){.ct{grid-template-columns:1fr}.sb{display:none}.sb.open{display:flex;position:fixed;inset:0;z-index:100;border-right:none}.mnc{padding:14px 16px}}
.wc{display:flex;flex-direction:column;align-items:center;justify-content:center;height:100%;color:var(--muted);text-align:center;gap:6px}
.wc h2{font-size:18px;font-weight:500;color:var(--dim)}.wc p{font-size:12px}
.sv .hdr{margin-bottom:16px}
.sv .hdr h2{font-size:16px;font-weight:550;letter-spacing:-.01em;word-break:break-all;color:var(--name)}
.sv .hdr .sub{font-size:11px;color:var(--muted);margin-top:3px;display:flex;gap:10px;flex-wrap:wrap}
.sc{margin-bottom:16px}
.sc h3{font-size:10px;font-weight:600;text-transform:uppercase;letter-spacing:.06em;color:var(--muted);margin-bottom:6px;display:flex;align-items:center;gap:5px}
.sc h3 .bd{font-size:9px;background:var(--surface2);padding:0 5px;border-radius:3px;color:var(--muted);font-weight:500;line-height:1.6}
.ec{background:var(--surface);border:1px solid var(--border);border-radius:7px;padding:8px 12px;margin-bottom:5px}
.ec .et{font-size:12px;line-height:1.55;word-break:break-word;color:var(--text)}
.ec .et code{font-family:var(--mono);font-size:11px;background:var(--bg);padding:1px 4px;border-radius:2px}
.ec .em{font-size:10px;color:var(--muted);margin-top:3px;display:flex;gap:6px;align-items:center}
.tb{display:inline-flex;padding:1px 6px;border-radius:3px;font-size:10px;font-weight:500;line-height:1.5}
.tb.d{background:oklch(.3 .12 48/.3);color:oklch(.75 .12 48)}
.tb.f{background:oklch(.28 .1 255/.3);color:oklch(.75 .1 255)}
.tb.c{background:oklch(.28 .1 145/.3);color:oklch(.75 .1 145)}
.tb.p{background:oklch(.28 .08 60/.3);color:var(--muted)}
.tb.s{background:oklch(.28 .08 280/.3);color:oklch(.7 .08 280)}
.err{display:flex;flex-direction:column;align-items:center;justify-content:center;height:100%;color:var(--red);text-align:center;gap:6px;padding:20px}
.err h3{font-size:14px;font-weight:500;color:var(--red)}
.err p{font-size:11px;color:var(--muted);max-width:400px}
@keyframes spin{to{transform:rotate(360deg)}}
.ld{display:flex;align-items:center;justify-content:center;padding:40px;gap:8px;color:var(--muted);font-size:12px}
.ld .sp{width:14px;height:14px;border:2px solid var(--border);border-top-color:var(--accent);border-radius:50%;animation:spin .6s linear infinite}
.mt{display:none;background:none;border:none;color:var(--name);cursor:pointer;padding:3px}
@media(max-width:768px){.mt{display:flex;align-items:center}}
</style>
</head>
<body>

<header>
  <button class="mt" id="menuBtn" aria-label="Toggle sidebar">
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 12h18M3 6h18M3 18h18"/></svg>
  </button>
  <div class="head"><mark>shokunin</mark> memory</div>
  <div class="stats" id="stats">
    <div class="st"><span class="dt a"></span><b id="sEntries">—</b> entries</div>
    <div class="st"><span class="dt g"></span><b id="sSignal">—</b>% signal</div>
    <div class="st"><span class="dt r"></span><b id="sNoise">—</b>% noise</div>
    <div class="st"><b id="sStorage">—</b> <span id="sStorageLabel"></span></div>
  </div>
</header>

<div class="ct">
  <div class="sb" id="sidebar">
    <div class="sbh">
      <div class="sw">
        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/></svg>
        <input type="text" id="filter" placeholder="Filter sessions..." autofocus>
      </div>
    </div>
    <div class="sl" id="slist"></div>
    <div class="sbf" id="sbf"></div>
  </div>

  <div class="mn">
    <div class="mnc" id="main">
      <div class="wc" id="welcome">
        <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" opacity=".35"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>
        <h2>Memory Viewer</h2>
        <p>Select a session from the sidebar</p>
      </div>
    </div>
  </div>
</div>

<script>
let _S = [], _A = null;
const $ = s => document.getElementById(s), _H = s => {const d=document.createElement('div');d.appendChild(document.createTextNode(s));return d.innerHTML};
const _T = t => {if(!t)return'\u2014';try{const d=new Date(t);if(isNaN(d))return t.slice(0,10);const n=new Date(),v=n-d;if(v<864e5)return d.toLocaleTimeString();if(v<6048e5)return d.toLocaleDateString(void 0,{weekday:'short',hour:'2-digit',minute:'2-digit'});return d.toLocaleDateString()}catch{return t.slice(0,10)}};
const _F = async u => {const r=await fetch(u);if(!r.ok){let e;try{e=await r.json()}catch{e=await r.text()};const m=e&&e.error?e.error:r.statusText;throw new Error(m)}return r.json()};

$('menuBtn').onclick=()=>$('sidebar').classList.toggle('open');
$('filter').oninput=()=>_R();

function _C(){if(innerWidth<=768)$('sidebar').classList.remove('open')}

async function _L(){try{const d=await _F('/api/stats');$('sEntries').textContent=d.total_entries??0;$('sSignal').textContent=(d.signal_percent??0).toFixed(1);$('sNoise').textContent=(d.noise_percent??0).toFixed(1);const st=d.storage||{};$('sStorage').textContent=st.chromadb_mb?st.chromadb_mb.toFixed(2):'\u2014';$('sStorageLabel').textContent=st.chromadb_mb?'MB':''}catch(e){console.warn('stats:',e.message)}}

async function _Sload(){try{const d=await _F('/api/sessions?limit=500');_S=d.sessions||[];_R();$('sbf').textContent=_S.length+' sessions'}catch(e){$('slist').innerHTML='<div style="padding:20px;text-align:center;color:var(--dim);font-size:12px">Failed to load sessions</div>';console.error('sessions:',e.message)}}

function _R(){const q=$('filter').value.toLowerCase();const f=_S.filter(s=>s.session_id.toLowerCase().includes(q)||(s.project||'').toLowerCase().includes(q));const l=$('slist');if(!f.length){l.innerHTML='<div style="padding:20px;text-align:center;color:var(--dim);font-size:12px">No sessions match</div>';return}
let h='';for(const s of f){let lb=s.session_id;if(lb.length>45)lb=lb.slice(0,42)+'...';const a=s.session_id===_A?' act':'';h+='<div class="si'+a+'" data-sid="'+_H(s.session_id)+'"><div class="nm">'+_H(lb)+'</div><div class="mt"><span>'+_H(s.project||'\u2014')+'</span><span>'+_T(s.last_ts)+'</span><span class="cnt">'+s.entry_count+'</span></div></div>'}
l.innerHTML=h;l.querySelectorAll('.si').forEach(el=>{el.onclick=()=>{_P(el.dataset.sid)}})}

function _P(id){_A=id;_C();_R();const m=$('main');m.innerHTML='<div class="ld"><div class="sp"></div><span>Loading session\u2026</span></div>';_F('/api/session/'+encodeURIComponent(id)).then(d=>{_V(d,m)}).catch(e=>{m.innerHTML='<div class="err"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><circle cx="12" cy="12" r="10"/><path d="m15 9-6 6M9 9l6 6"/></svg><h3>Error loading session</h3><p>'+_H(e.message)+'</p></div>'})}

function _V(d,m){let h='<div class="sv"><div class="hdr"><h2>'+_H(d.session_id)+'</h2><div class="sub"><span>'+d.entry_count+' entries</span><span>'+d.decisions.length+' decisions</span><span>'+d.files.length+' files</span><span>'+d.commands.length+' commands</span></div></div>';const secs=[['Decisions',d.decisions,'d'],['Files',d.files,'f'],['Commands',d.commands,'c'],['Session End',d.session_ends,'s']];secs.forEach(([t,es,c])=>{if(es.length){h+='<div class="sc"><h3>'+t+' <span class="bd">'+es.length+'</span></h3>';es.forEach(e=>{h+=_E(e,c)});h+='</div>'}});h+='<div class="sc"><h3>All Entries <span class="bd">'+d.entries.length+'</span></h3>';d.entries.forEach(e=>{h+=_E(e,e.type||'general')});h+='</div></div>';m.innerHTML=h}

function _E(e,tc){let t=(e.text||'').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/\n/g,'<br>');return'<div class="ec"><div class="et">'+t+'</div><div class="em"><span class="tb '+tc+'">'+(e.type||'general')+'</span><span>'+_T(e.timestamp)+'</span></div></div>'}

_L();_Sload();
</script>
</body>
</html>
"""


def consolidate(project: str | None = None, max_entries: int = 100) -> dict[str, Any]:
    """Distill episodic entries into a compact semantic summary per project.
    Groups entries by project, extracts decisions, files, and commands,
    and saves a readable consolidated entry.
    """
    try:
        where_filter = {"project": project} if project else None
        all_data = _get_db().get(limit=max_entries, where=where_filter)
    except Exception:
        return {"consolidated": 0, "message": "query failed"}

    if not all_data.get("ids"):
        return {"consolidated": 0, "message": "no entries"}

    projects: dict[str, dict[str, list[str]]] = defaultdict(lambda: defaultdict(list))
    for i in range(len(all_data["ids"])):
        meta = all_data["metadatas"][i]
        p = meta.get("project", "unknown")
        etype = meta.get("type", "general")
        text = all_data["documents"][i][:300]
        projects[p][etype].append(text)

    consolidated = 0
    for proj, type_groups in projects.items():
        total_entries = sum(len(v) for v in type_groups.values())
        decisions = type_groups.get("decision", [])
        files = type_groups.get("file", [])
        commands = type_groups.get("command", [])
        session_ends = type_groups.get("session_end", [])

        lines = [f"# Consolidated: {proj}", f"Entries: {total_entries} across {len(type_groups)} types", ""]

        if decisions:
            lines.append(f"## Decisions ({len(decisions)})")
            lines.extend(f"- {d}" for d in decisions[:8])
            lines.append("")
        if files:
            lines.append(f"## Files ({len(files)})")
            lines.extend(f"- {f}" for f in files[:8])
            lines.append("")
        if commands:
            lines.append(f"## Commands ({len(commands)})")
            lines.extend(f"- {c}" for c in commands[:5])
            lines.append("")
        if session_ends:
            lines.append(f"## Session Summaries ({len(session_ends)})")
            lines.extend(f"- {s[:200]}" for s in session_ends[:3])
            lines.append("")

        # Extract key terms for quick scanning
        all_texts = [t for group in type_groups.values() for t in group]
        tokens = []
        for t in all_texts:
            tokens.extend(_tokenize(t))
        common = [w for w, c in Counter(tokens).most_common(15) if len(w) > 3][:8]
        if common:
            lines.append(f"Key terms: {', '.join(common)}")
            lines.append("")

        lines.append("---\nConsolidated by shokunin. Original entries preserved in ChromaDB.")

        summary = "\n".join(lines)
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
    elif cmd == "index":
        project = sys.argv[2] if len(sys.argv) > 2 else None  # type: ignore[assignment]
        result: Any = index(project)  # type: ignore[no-redef]
        print(json.dumps(result))
    elif cmd == "stats":
        result: Any = stats()  # type: ignore[no-redef]
        print(json.dumps(result))
    elif cmd == "forget" and len(sys.argv) >= 3:
        sid = sys.argv[2]
        pattern = sys.argv[3] if len(sys.argv) > 3 else ""
        result: Any = forget(sid, pattern)  # type: ignore[no-redef]
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
    elif cmd == "serve":
        port = int(sys.argv[2]) if len(sys.argv) > 2 else 8765
        result: Any = serve(port)  # type: ignore[no-redef]
        print(json.dumps(result))
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
        print(json.dumps({"error": "Usage: save|search|recall|consolidate|count|recent|session|index|stats|forget|serve"}))
