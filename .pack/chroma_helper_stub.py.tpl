"""Lightweight stub for chroma-helper functions used by MCP server.

Loads the full chroma-helper module lazily only when a function is called,
so the MCP server can start even if chromadb import fails.
"""
import importlib.util
import os

_ch_mod = None


def _load_chroma_helper():
    """Load chroma-helper.py on first use, with graceful fallback."""
    global _ch_mod
    if _ch_mod is not None:
        return _ch_mod
    stub_dir = os.path.dirname(os.path.abspath(__file__))
    helper_path = os.path.join(stub_dir, "chroma-helper.py")
    if not os.path.isfile(helper_path):
        raise ImportError(f"chroma-helper.py not found at {helper_path}")
    spec = importlib.util.spec_from_file_location("chroma_helper", helper_path)
    if spec is None or spec.loader is None:
        raise ImportError(f"Cannot load spec from {helper_path}")
    _ch_mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(_ch_mod)
    return _ch_mod


def search(*args, **kwargs):
    return _load_chroma_helper().search(*args, **kwargs)


def recall(*args, **kwargs):
    return _load_chroma_helper().recall(*args, **kwargs)


def save(*args, **kwargs):
    return _load_chroma_helper().save(*args, **kwargs)


def consolidate(*args, **kwargs):
    return _load_chroma_helper().consolidate(*args, **kwargs)


def session_list(*args, **kwargs):
    return _load_chroma_helper().session_list(*args, **kwargs)


def session_continue(*args, **kwargs):
    return _load_chroma_helper().session_continue(*args, **kwargs)


def session_save(*args, **kwargs):
    return _load_chroma_helper().session_save(*args, **kwargs)
