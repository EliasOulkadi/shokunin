"""Shared constants and helpers for kami build and stabilize scripts."""
from __future__ import annotations

import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TEMPLATES = ROOT / "assets" / "templates"
DIAGRAMS = ROOT / "assets" / "diagrams"
EXAMPLES = ROOT / "assets" / "examples"
TOKENS_FILE = ROOT / "references" / "tokens.json"

# Canonical parchment background color, kept here so build/stabilize/density
# checks share one source of truth instead of redefining the RGB triple.
PARCHMENT_HEX = "#f5f4ed"
PARCHMENT_RGB = (0xF5, 0xF4, 0xED)

_HOMEBREW_PREFIXES = (Path("/opt/homebrew"), Path("/usr/local"))


def _default_cache_dir() -> Path:
    """Return a sensible per-platform fontconfig cache directory."""
    if sys.platform == "darwin":
        return Path("/private/tmp/kami-fontconfig-cache")
    xdg = os.environ.get("XDG_CACHE_HOME")
    if xdg:
        return Path(xdg) / "kami"
    return Path.home() / ".cache" / "kami"


def configure_weasyprint_runtime() -> None:
    """Make platform-native libraries discoverable before importing WeasyPrint.

    On macOS, also surface Homebrew's gobject lib so cairo/pango can load.
    On Linux/other, only the fontconfig cache hint is set; the system loader
    is expected to find the libraries.
    """
    os.environ.setdefault("XDG_CACHE_HOME", str(_default_cache_dir()))

    if sys.platform != "darwin":
        return

    brew_lib = next(
        (p / "lib" for p in _HOMEBREW_PREFIXES if (p / "lib" / "libgobject-2.0.dylib").exists()),
        None,
    )
    if brew_lib is None:
        return

    existing = os.environ.get("DYLD_FALLBACK_LIBRARY_PATH", "")
    paths = [path for path in existing.split(":") if path]
    brew_lib_str = str(brew_lib)
    if brew_lib_str in paths:
        return

    os.environ["DYLD_FALLBACK_LIBRARY_PATH"] = ":".join([brew_lib_str, *paths])

# Cool / neutral gray hex values that violate the "warm undertone only" rule.
COOL_GRAY_BLOCKLIST = {
    "#888", "#888888", "#666", "#666666", "#999", "#999999",
    "#ccc", "#cccccc", "#ddd", "#dddddd", "#eee", "#eeeeee",
    "#111", "#111111", "#222", "#222222", "#333", "#333333",
    "#444", "#444444", "#555", "#555555", "#777", "#777777",
    "#aaa", "#aaaaaa", "#bbb", "#bbbbbb",
    # Tailwind cool grays
    "#6b7280", "#9ca3af", "#d1d5db", "#e5e7eb", "#f3f4f6",
    "#4b5563", "#374151", "#1f2937", "#111827",
    # Bootstrap-like neutrals
    "#f8f9fa", "#e9ecef", "#dee2e6", "#ced4da", "#adb5bd",
    "#6c757d", "#495057", "#343a40", "#212529",
}


# ---------------------------------------------------------------------------
# Template registry
#
# Single source of truth for HTML targets across build.py and stabilize.py.
#
# Each entry is (source_filename, build_max_pages, stabilize_max_pages):
#   - build_max_pages: hard ceiling enforced by `build.py --verify`. 0 = no
#     limit.
#   - stabilize_max_pages: target pages for the overflow solver in
#     `stabilize.py`. 0 = solver disabled. The two values can differ because
#     stabilize aims to keep doc-style targets within an editorial range while
#     build only catches gross overflow.
# ---------------------------------------------------------------------------
HTML_TEMPLATES: dict[str, tuple[str, int, int]] = {
    # Core six
    "one-pager":    ("one-pager.html",    1, 1),
    "letter":       ("letter.html",       1, 1),
    "long-doc":     ("long-doc.html",     0, 9),
    "portfolio":    ("portfolio.html",    0, 8),
    "resume":       ("resume.html",       2, 2),
    "one-pager-en": ("one-pager-en.html", 1, 1),
    "letter-en":    ("letter-en.html",    1, 1),
    "long-doc-en":  ("long-doc-en.html",  0, 9),
    "portfolio-en": ("portfolio-en.html", 0, 8),
    "resume-en":    ("resume-en.html",    2, 2),
    # Equity report
    "equity-report":    ("equity-report.html",    3, 0),
    "equity-report-en": ("equity-report-en.html", 3, 0),
    # Changelog
    "changelog":    ("changelog.html",    2, 0),
    "changelog-en": ("changelog-en.html", 2, 0),
    # Slides (WeasyPrint default)
    "slides-weasy":    ("slides-weasy.html",    0, 0),
    "slides-weasy-en": ("slides-weasy-en.html", 0, 0),
}


def build_targets() -> dict[str, tuple[str, int]]:
    """Return target -> (source, max_pages) mapping for build.py."""
    return {name: (src, build_max) for name, (src, build_max, _) in HTML_TEMPLATES.items()}


def stabilize_targets() -> dict[str, tuple[str, int]]:
    """Return target -> (source, max_pages) mapping for stabilize.py.

    Only includes templates with a non-zero stabilize ceiling (the ones the
    overflow solver should constrain).
    """
    return {
        name: (src, stab_max)
        for name, (src, _build_max, stab_max) in HTML_TEMPLATES.items()
        if stab_max > 0
    }
