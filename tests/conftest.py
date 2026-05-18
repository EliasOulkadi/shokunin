from __future__ import annotations

import os
import tempfile
from pathlib import Path
from typing import Any

import pytest


@pytest.fixture
def temp_dir() -> str:
    with tempfile.TemporaryDirectory(prefix="shokunin_test_") as d:
        yield d


@pytest.fixture
def chroma_path(temp_dir: str) -> str:
    path = str(Path(temp_dir) / "chroma_db")
    os.makedirs(path, exist_ok=True)
    return path


@pytest.fixture
def sessions_path(temp_dir: str) -> str:
    path = str(Path(temp_dir) / "sessions")
    os.makedirs(path, exist_ok=True)
    return path


@pytest.fixture(autouse=True)
def monkeypatch_shokunin_home(monkeypatch: Any, temp_dir: str) -> None:
    """Force all tests to use a temp directory instead of real ~/.shokunin."""
    monkeypatch.setenv("USERPROFILE", temp_dir)
    monkeypatch.setenv("HOME", temp_dir)
    monkeypatch.setattr(os.path, "expanduser", lambda p: temp_dir)
