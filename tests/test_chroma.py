import json
import os
import subprocess
import time

CHROMA = os.path.expanduser("~/.shokunin/scripts/chroma-helper.py")
TEST_PROJ = "pytest-ci"


def _run(*args):
    result = subprocess.run(
        ["python", CHROMA] + list(args),
        capture_output=True,
        text=True,
        timeout=30,
    )
    return result.stdout.strip()


def test_save_search():
    sid = f"pytest-{os.urandom(4).hex()}"
    save_out = _run("save", "save_search content", sid, "test", "pytest", TEST_PROJ)
    assert "stored" in save_out, f"save failed: {save_out}"

    time.sleep(0.5)
    search_out = _run("search", "save_search", TEST_PROJ, "10")
    data = json.loads(search_out) if search_out else []
    found = any(sid in e.get("session_id", "") for e in data)
    assert found, f"search didn't find {sid} in {len(data)} results"


def test_recall_bm25():
    sid = f"pytest-{os.urandom(4).hex()}"
    save_out = _run("save", "BM25_KEYWORD_zebra_99", sid, "test", "pytest", TEST_PROJ)
    assert "stored" in save_out, f"save failed: {save_out}"

    time.sleep(0.5)
    recall_out = _run("recall", "zebra_99", TEST_PROJ, "5")
    data = json.loads(recall_out) if recall_out else []
    texts = [e.get("text", "") for e in data]
    found_any = any("zebra_99" in t for t in texts)
    found_sid = any(sid in e.get("session_id", "") for e in data)
    assert found_any or found_sid, f"recall didn't find keyword: texts={texts[:3]}"


def test_recall_date_filter():
    sid = f"pytest-{os.urandom(4).hex()}"
    _run("save", f"recall_date_test_{sid}", sid, "test", "pytest", TEST_PROJ)
    time.sleep(0.5)
    today = time.strftime("%Y-%m-%d")

    result = _run("recall", "recall_date_test", TEST_PROJ, "5", today, today)
    data = json.loads(result) if result else []
    found = any(sid in e.get("session_id", "") for e in data)
    assert found, f"date-filtered recall didn't find: {len(data)} results"


def test_session_list():
    result = _run("session", "list", "5")
    data = json.loads(result)
    assert isinstance(data, list), f"session list should return a list: {result}"


def test_session_continue():
    sessions = json.loads(_run("session", "list", "5"))
    if not sessions:
        return
    sid = sessions[0]["session_id"]
    result = _run("session", "continue", sid)
    data = json.loads(result)
    assert "context" in data, f"session continue missing context: {result}"
    assert "decisions" in data["context"], f"context missing decisions: {result}"
