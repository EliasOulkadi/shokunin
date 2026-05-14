import os, sys, json, uuid
from datetime import datetime, timezone
import chromadb
from chromadb.config import Settings

_HOME = os.getenv("USERPROFILE") or os.getenv("HOME") or os.path.expanduser("~")
BASE_DIR = os.path.join(_HOME, ".shokunin", "memory")
CHROMA_PATH = os.path.join(BASE_DIR, "chroma_db")
SESSIONS_PATH = os.path.join(BASE_DIR, "sessions")
COLLECTION_NAME = "shokunin_memory"

client = chromadb.PersistentClient(path=CHROMA_PATH, settings=Settings(anonymized_telemetry=False))
collection = client.get_or_create_collection(name=COLLECTION_NAME)

def save(text, session_id, entry_type="general", tags=None, project=""):
    if not text or not session_id:
        return {"error": "text and session_id required", "stored": False}
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
    collection.add(documents=[text], metadatas=[metadata], ids=[entry_id])
    os.makedirs(SESSIONS_PATH, exist_ok=True)
    safe_id = session_id.replace(":", "-").replace("/", "-")
    filepath = os.path.join(SESSIONS_PATH, f"{safe_id}.md")
    with open(filepath, "a", encoding="utf-8") as f:
        f.write(f"## {timestamp} | type: {entry_type}\n- **project:** {project}\n- **tags:** {json.dumps(tags)}\n\n{text}\n\n---\n")
    return {"id": entry_id, "stored": True}

def search(query, project=None, n_results=10):
    where_filter = {"project": project} if project else None
    try:
        results = collection.query(query_texts=[query], n_results=n_results, where=where_filter)
    except Exception as e:
        return []
    entries = []
    if results.get("ids") and results["ids"][0]:
        for i in range(len(results["ids"][0])):
            meta = results["metadatas"][0][i]
            dist = results["distances"][0][i]
            entries.append({
                "text": results["documents"][0][i][:500],
                "type": meta.get("type", "general"),
                "tags": json.loads(meta.get("tags", "[]")),
                "project": meta.get("project", ""),
                "session_id": meta.get("session_id", ""),
                "timestamp": meta.get("timestamp", ""),
                "similarity": round(1.0 - dist, 4),
            })
    return entries

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
        project = sys.argv[3] if len(sys.argv) > 3 else None
        result = search(query, project)
        print(json.dumps(result))
    elif cmd == "recent":
        n_results = int(sys.argv[2]) if len(sys.argv) > 2 else 10
        try:
            all_results = collection.get(limit=n_results)
            entries = []
            if all_results.get("ids"):
                for i in range(len(all_results["ids"])):
                    meta = all_results["metadatas"][i]
                    entries.append({
                        "text": all_results["documents"][i][:500],
                        "type": meta.get("type", "general"),
                        "tags": json.loads(meta.get("tags", "[]")),
                        "project": meta.get("project", ""),
                        "session_id": meta.get("session_id", ""),
                        "timestamp": meta.get("timestamp", ""),
                    })
            print(json.dumps(entries))
        except Exception as e:
            print(json.dumps({"error": str(e)}))
    elif cmd == "count":
        print(json.dumps({"count": collection.count()}))
    else:
        print(json.dumps({"error": "Usage: save|search|count|recent"}))
