#!/usr/bin/env python3
"""Lightweight tests for scripts/build.py and scripts/shared.py.

Run with: python3 scripts/tests/test_build.py
The harness uses plain assertions and a tiny runner so it has no third-party
dependency (matching the rest of the repo's lean tooling).
"""
from __future__ import annotations

import contextlib
import io
import sys
import tempfile
from pathlib import Path

# Make scripts/ importable when running this file directly.
ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

from build import (  # noqa: E402
    DIAGRAM_TARGETS,
    HTML_TARGETS,
    PPTX_TARGETS,
    _BG_B,
    _BG_G,
    _BG_R,
    _last_content_y,
    _parse_slide_sequence,
    check_placeholders,
    scan_file,
)
from shared import (  # noqa: E402
    HTML_TEMPLATES,
    PARCHMENT_RGB,
    TEMPLATES,
    build_targets,
    stabilize_targets,
)
from stabilize import (  # noqa: E402
    blend_rgba_on_parchment,
    clamp,
    clamp_line_heights,
    luminance,
    normalize_cool_grays,
    normalize_rgba,
    parse_hex,
    rgb_to_hex,
)


# --------------------------- helpers ---------------------------

_PASS = 0
_FAIL = 0


def check(name: str, predicate: bool, detail: str = "") -> None:
    global _PASS, _FAIL
    if predicate:
        _PASS += 1
        print(f"OK: {name}")
    else:
        _FAIL += 1
        print(f"ERROR: {name}{(' - ' + detail) if detail else ''}")


def write_temp_html(body: str, suffix: str = "-en.html") -> Path:
    f = tempfile.NamedTemporaryFile(mode="w", suffix=suffix, delete=False, encoding="utf-8")
    f.write(body)
    f.close()
    return Path(f.name)


def silently(callable_, *args, **kwargs):
    """Run a function with stdout suppressed, return its result."""
    sink = io.StringIO()
    with contextlib.redirect_stdout(sink):
        return callable_(*args, **kwargs)


# --------------------------- shared registry ---------------------------

def test_registry_consistency() -> None:
    check("HTML_TEMPLATES has 16 entries", len(HTML_TEMPLATES) == 16,
          f"got {len(HTML_TEMPLATES)}")
    check("build_targets matches HTML_TEMPLATES key set",
          set(build_targets()) == set(HTML_TEMPLATES))
    check("stabilize_targets is a subset of HTML_TEMPLATES",
          set(stabilize_targets()) <= set(HTML_TEMPLATES))
    check("HTML_TARGETS in build.py matches build_targets()",
          dict(HTML_TARGETS) == build_targets())
    check("DIAGRAM_TARGETS has 14 entries", len(DIAGRAM_TARGETS) == 14,
          f"got {len(DIAGRAM_TARGETS)}")
    check("PPTX_TARGETS has 2 entries", len(PPTX_TARGETS) == 2,
          f"got {len(PPTX_TARGETS)}")
    check("PARCHMENT_RGB is canonical", PARCHMENT_RGB == (0xF5, 0xF4, 0xED))


def test_chinese_html_templates_keep_single_serif_stack() -> None:
    """Chinese templates must keep --sans pinned to --serif for PDF glyph safety."""
    offenders: list[str] = []
    for name, (source, _build_max, _stabilize_max) in HTML_TEMPLATES.items():
        if name.endswith("-en"):
            continue
        text = (TEMPLATES / source).read_text(encoding="utf-8")
        if "--sans: var(--serif)" not in text and "--sans:  var(--serif)" not in text:
            offenders.append(source)

    check("Chinese HTML templates keep --sans: var(--serif)",
          not offenders,
          f"offenders: {', '.join(offenders)}")


def test_chinese_slides_mono_has_cjk_fallback() -> None:
    """Slide labels may mix mono Latin and CJK; the mono stack needs CJK fallback."""
    text = (TEMPLATES / "slides-weasy.html").read_text(encoding="utf-8")
    check("slides-weasy mono stack includes TsangerJinKai02 fallback",
          '"TsangerJinKai02"' in text and '"Source Han Serif SC"' in text)


# --------------------------- scan_file ---------------------------

def test_scan_file_skip_bug() -> None:
    """Lines starting with '#' (CSS id selectors) must NOT be skipped."""
    fixture = """<!doctype html>
<html><head><style>
#card { background: rgba(0,0,0,0.5); }
</style></head><body></body></html>
"""
    p = write_temp_html(fixture)
    try:
        findings = scan_file(p)
        rules = {f.rule for f in findings}
        check("scan_file flags rgba on #id-prefixed CSS line",
              "rgba-background" in rules,
              f"rules found: {rules or '(none)'}")
    finally:
        p.unlink(missing_ok=True)


def test_scan_file_arrow_in_en() -> None:
    """`→` in -en.html body should trigger arrow-unicode-in-en."""
    fixture = """<!doctype html>
<html lang="en"><head><style>
.tag { color: #1B365D; }
</style></head><body>
<p>Step 1 → Step 2</p>
</body></html>
"""
    p = write_temp_html(fixture, suffix="-en.html")
    try:
        findings = scan_file(p)
        rules = {f.rule for f in findings}
        check("scan_file flags U+2192 arrow in -en.html",
              "arrow-unicode-in-en" in rules,
              f"rules found: {rules or '(none)'}")
    finally:
        p.unlink(missing_ok=True)


def test_scan_file_clean_template() -> None:
    """A clean template should produce zero findings."""
    fixture = """<!doctype html>
<html><head><style>
:root { --brand: #1B365D; }
.card { background: var(--ivory); }
.tag { background: #EEF2F7; color: var(--brand); }
</style></head><body></body></html>
"""
    p = write_temp_html(fixture)
    try:
        findings = scan_file(p)
        check("scan_file produces no findings on clean template",
              len(findings) == 0,
              f"got {len(findings)} finding(s): {[f.rule for f in findings]}")
    finally:
        p.unlink(missing_ok=True)


# --------------------------- slide sequence ---------------------------

def test_parse_slide_sequence_empty() -> None:
    fixture = """def main():
    pass
"""
    p = write_temp_html(fixture, suffix=".py")
    try:
        seq = _parse_slide_sequence(p)
        check("_parse_slide_sequence returns [] for empty main()",
              seq == [], f"got {seq}")
    finally:
        p.unlink(missing_ok=True)


def test_parse_slide_sequence_basic() -> None:
    fixture = """def main():
    cover_slide()
    content_slide()
    content_slide()
    chapter_slide()
    metrics_slide()

def helper():
    other_call()
"""
    p = write_temp_html(fixture, suffix=".py")
    try:
        seq = _parse_slide_sequence(p)
        expected = ["cover_slide", "content_slide", "content_slide", "chapter_slide", "metrics_slide"]
        check("_parse_slide_sequence parses ordered slide calls",
              seq == expected, f"got {seq}")
    finally:
        p.unlink(missing_ok=True)


# --------------------------- scan_file extra rules ---------------------------

def test_scan_file_line_height_too_loose() -> None:
    """line-height >= 1.6 should trigger line-height-too-loose."""
    fixture = """<!doctype html>
<html><head><style>
p { line-height: 1.8; }
</style></head><body></body></html>
"""
    p = write_temp_html(fixture)
    try:
        findings = scan_file(p)
        rules = {f.rule for f in findings}
        check("scan_file flags line-height 1.8 (too loose)",
              "line-height-too-loose" in rules,
              f"rules found: {rules or '(none)'}")
    finally:
        p.unlink(missing_ok=True)


def test_scan_file_cool_gray() -> None:
    """Cool-gray hex literals should be flagged."""
    fixture = """<!doctype html>
<html><head><style>
.muted { color: #888; }
</style></head><body></body></html>
"""
    p = write_temp_html(fixture)
    try:
        findings = scan_file(p)
        rules = {f.rule for f in findings}
        check("scan_file flags cool gray #888",
              "cool-gray" in rules,
              f"rules found: {rules or '(none)'}")
    finally:
        p.unlink(missing_ok=True)


def test_scan_file_thin_border_with_radius() -> None:
    """Sub-1pt closed border in a block with border-radius should fire pitfall #2."""
    fixture = """<!doctype html>
<html><head><style>
.tag {
  border: 0.5pt solid #1B365D;
  border-radius: 3pt;
  background: #EEF2F7;
}
</style></head><body></body></html>
"""
    p = write_temp_html(fixture)
    try:
        findings = scan_file(p)
        rules = {f.rule for f in findings}
        check("scan_file flags thin border with border-radius",
              "thin-border-radius" in rules,
              f"rules found: {rules or '(none)'}")
    finally:
        p.unlink(missing_ok=True)


# --------------------------- check_placeholders ---------------------------

def test_check_placeholders_flags_unfilled() -> None:
    """A doc with `{{ name }}` left over should fail the check."""
    p = write_temp_html("<html><body><h1>{{ name }}</h1><p>{{ role }}</p></body></html>")
    try:
        rc = silently(check_placeholders, [str(p)])
        check("check_placeholders fails on {{ name }}", rc == 1, f"rc={rc}")
    finally:
        p.unlink(missing_ok=True)


def test_check_placeholders_passes_clean() -> None:
    """A doc with no placeholder syntax should pass."""
    p = write_temp_html("<html><body><h1>Real Name</h1><p>Real role</p></body></html>")
    try:
        rc = silently(check_placeholders, [str(p)])
        check("check_placeholders passes clean file", rc == 0, f"rc={rc}")
    finally:
        p.unlink(missing_ok=True)


# --------------------------- stabilize pure functions ---------------------------

def test_clamp_basic() -> None:
    check("clamp inside range", clamp(0.5, 0.0, 1.0) == 0.5)
    check("clamp clips low", clamp(-0.1, 0.0, 1.0) == 0.0)
    check("clamp clips high", clamp(1.5, 0.0, 1.0) == 1.0)


def test_parse_hex_3_and_6() -> None:
    check("parse_hex handles #fff -> (255,255,255)", parse_hex("#fff") == (255, 255, 255))
    check("parse_hex handles #1B365D", parse_hex("#1B365D") == (27, 54, 93))


def test_rgb_to_hex_pads_uppercase() -> None:
    check("rgb_to_hex emits uppercase 6-char form",
          rgb_to_hex((27, 54, 93)) == "#1B365D")


def test_blend_rgba_on_parchment_alpha_zero() -> None:
    """alpha=0 returns the parchment background (overlay invisible)."""
    out = blend_rgba_on_parchment(0, 0, 0, 0.0)
    check("blend alpha=0 -> parchment", out == "#F5F4ED", f"got {out}")


def test_blend_rgba_on_parchment_alpha_one() -> None:
    """alpha=1 returns the overlay color exactly."""
    out = blend_rgba_on_parchment(0, 0, 0, 1.0)
    check("blend alpha=1 -> overlay", out == "#000000", f"got {out}")


def test_normalize_rgba_blends_to_solid() -> None:
    """rgba() should be replaced by a solid hex on parchment."""
    css = ".a { background: rgba(0, 0, 0, 0.5); }"
    out, hits = normalize_rgba(css)
    check("normalize_rgba removes rgba(", "rgba(" not in out, f"out: {out}")
    check("normalize_rgba reports one hit", hits == 1, f"hits={hits}")


def test_normalize_rgba_skips_invalid() -> None:
    """Channel > 255 should be left alone (not a real color)."""
    css = ".a { background: rgba(300, 0, 0, 0.5); }"
    out, hits = normalize_rgba(css)
    check("normalize_rgba skips out-of-range channel", "rgba(300" in out)
    check("normalize_rgba reports zero hits for invalid", hits == 0)


def test_normalize_cool_grays_replaces_blocklisted() -> None:
    """A blocklisted cool gray hex should be rewritten; brand color stays."""
    css = ".a { color: #888; } .b { color: #1B365D; }"
    out, hits = normalize_cool_grays(css)
    check("normalize_cool_grays drops #888", "#888" not in out, f"out: {out}")
    check("normalize_cool_grays preserves #1B365D", "#1B365D" in out)
    check("normalize_cool_grays reports >= 1 hit", hits >= 1)


def test_clamp_line_heights_clamps_loose() -> None:
    """1.7 outside [1.30, 1.55] should clamp; 1.4 in-range stays."""
    css = "p { line-height: 1.7; } q { line-height: 1.4; }"
    out, hits = clamp_line_heights(css, 1.30, 1.55)
    check("clamp_line_heights pulls 1.7 down", "1.55" in out, f"out: {out}")
    check("clamp_line_heights leaves 1.4 alone", "1.4" in out)
    check("clamp_line_heights reports one hit", hits == 1, f"hits={hits}")


def test_luminance_known_values() -> None:
    """Luminance matches expected boundary values."""
    check("luminance(black) ~ 0", abs(luminance((0, 0, 0))) < 1e-3)
    check("luminance(white) ~ 1", abs(luminance((255, 255, 255)) - 1.0) < 1e-3)


# --------------------------- _last_content_y ---------------------------

def _make_samples(rows_with_content: int, w: int, h: int, n: int = 3) -> bytes:
    """Build a flat RGB buffer: parchment everywhere, ink in the top N rows.

    Returns bytes matching the layout PyMuPDF's Pixmap uses, so we can drive
    _last_content_y without depending on a real PDF or numpy.
    """
    parchment_row = bytes((_BG_R, _BG_G, _BG_B)) * w
    ink_row = bytes((27, 54, 93)) * w
    out = bytearray()
    for y in range(h):
        out.extend(ink_row if y < rows_with_content else parchment_row)
    return bytes(out)


def test_last_content_y_dense_page() -> None:
    """Page with content all the way to the bottom: returns h-1."""
    w, h, n = 80, 100, 3
    samples = _make_samples(rows_with_content=h, w=w, h=h, n=n)
    y = _last_content_y(samples, w, h, w * n, n)
    check("_last_content_y dense page returns last row", y == h - 1, f"got {y}")


def test_last_content_y_sparse_page() -> None:
    """Page with content only in top 10 rows: returns 9."""
    w, h, n = 80, 100, 3
    samples = _make_samples(rows_with_content=10, w=w, h=h, n=n)
    y = _last_content_y(samples, w, h, w * n, n)
    check("_last_content_y sparse page returns last content row",
          y == 9, f"got {y}")


def test_last_content_y_blank_page() -> None:
    """Page with no content at all: returns 0."""
    w, h, n = 80, 100, 3
    samples = _make_samples(rows_with_content=0, w=w, h=h, n=n)
    y = _last_content_y(samples, w, h, w * n, n)
    check("_last_content_y blank page returns 0", y == 0, f"got {y}")


# --------------------------- runner ---------------------------

def main() -> int:
    test_registry_consistency()
    test_chinese_html_templates_keep_single_serif_stack()
    test_chinese_slides_mono_has_cjk_fallback()
    test_scan_file_skip_bug()
    test_scan_file_arrow_in_en()
    test_scan_file_clean_template()
    test_scan_file_line_height_too_loose()
    test_scan_file_cool_gray()
    test_scan_file_thin_border_with_radius()
    test_parse_slide_sequence_empty()
    test_parse_slide_sequence_basic()
    test_check_placeholders_flags_unfilled()
    test_check_placeholders_passes_clean()
    test_clamp_basic()
    test_parse_hex_3_and_6()
    test_rgb_to_hex_pads_uppercase()
    test_blend_rgba_on_parchment_alpha_zero()
    test_blend_rgba_on_parchment_alpha_one()
    test_normalize_rgba_blends_to_solid()
    test_normalize_rgba_skips_invalid()
    test_normalize_cool_grays_replaces_blocklisted()
    test_clamp_line_heights_clamps_loose()
    test_luminance_known_values()
    test_last_content_y_dense_page()
    test_last_content_y_sparse_page()
    test_last_content_y_blank_page()
    print()
    print(f"Passed: {_PASS} | Failed: {_FAIL}")
    return 0 if _FAIL == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
