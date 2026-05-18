from __future__ import annotations

import re

import pytest


def _sanitize_id(sid: str) -> str:
    """Copy of _sanitize_id from chroma-helper.py for isolated testing."""
    safe = re.sub(r"\.\.", "", sid).replace(":", "-").replace("/", "-").replace("\\", "-")
    return re.sub(r'[<>"|?*\0]', "-", safe)


def _safe_id(sid: str) -> str:
    """Copy of _safe_id from mcp-server.py for isolated testing."""
    safe = re.sub(r"\.\.", "", sid).replace(":", "-").replace("/", "-").replace("\\", "-")
    return re.sub(r'[<>"|?*\0]', "-", safe)


@pytest.mark.parametrize("sid,expected", [
    ("session-20260101-120000-1234", "session-20260101-120000-1234"),
    ("test:colon", "test-colon"),
    ("test/path", "test-path"),
    ("test\\path", "test-path"),
    ("<script>", "-script-"),
    ("hello|world", "hello-world"),
    ("test?query", "test-query"),
    ("test*star", "test-star"),
    ("..a..b", "ab"),
])
def test_sanitize_id_basic(sid: str, expected: str) -> None:
    result = _sanitize_id(sid)
    assert result == expected, f"_sanitize_id({sid!r}) = {result!r}, expected {expected!r}"


@pytest.mark.parametrize("sid", [
    "../escape",
    "..\\windows",
    "../etc",
    "../../../etc/passwd",
    "..\\..\\..\\windows\\system32",
])
def test_sanitize_id_no_path_separators(sid: str) -> None:
    """Path traversal attempts must not leave / or \\ in the output."""
    result = _sanitize_id(sid)
    assert "/" not in result, f"Found / in {result!r} from {sid!r}"
    assert "\\" not in result, f"Found \\ in {result!r} from {sid!r}"


@pytest.mark.parametrize("sid", [
    "../escape",
    "..\\windows",
    "../etc",
    "..\\..\\..\\windows\\system32",
])
def test_safe_id_no_path_separators(sid: str) -> None:
    """Path traversal attempts must not leave / or \\ in the output."""
    result = _safe_id(sid)
    assert "/" not in result, f"Found / in {result!r} from {sid!r}"
    assert "\\" not in result, f"Found \\ in {result!r} from {sid!r}"


def test_sanitize_id_preserves_valid_ids() -> None:
    assert _sanitize_id("session-20260101-120000-1234") == "session-20260101-120000-1234"


def test_safe_id_preserves_valid_ids() -> None:
    assert _safe_id("session-20260101-120000-1234") == "session-20260101-120000-1234"


def test_sanitize_id_double_dots_removed() -> None:
    result = _sanitize_id("..a..b")
    assert result == "ab"
