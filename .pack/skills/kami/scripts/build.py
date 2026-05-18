#!/usr/bin/env python3
"""Kami PDF Builder — Generates professional PDFs with the Shokunin design system.

Design: parchment (#f5f4ed), ink-blue (#1B365D), Charter serif, grain texture.
Usage: python build.py <input.md> <output.pdf> [--title "Title"]
"""

import sys
from fpdf import FPDF

PARCHMENT = (245, 244, 237)
INK_BLUE = (27, 54, 93)
INK_LIGHT = (45, 90, 138)
NEAR_BLACK = (20, 20, 19)
DARK_WARM = (61, 61, 58)
STONE = (107, 106, 100)
BORDER = (232, 230, 220)


def _sanitize(text):
    """Replace Unicode characters not supported by core PDF fonts."""
    replacements = {
        "\u2014": "--", "\u2013": "-", "\u2018": "'", "\u2019": "'",
        "\u201c": '"', "\u201d": '"', "\u2026": "...", "\u2022": "-",
        "\u00a0": " ", "\u2010": "-", "\u2011": "-", "\u2012": "-",
    }
    for u, a in replacements.items():
        text = text.replace(u, a)
    return text


class KamiPDF(FPDF):
    def header(self):
        if self.page_no() > 1:
            self.set_font("Helvetica", "B", 9)
            self.set_text_color(*INK_BLUE)
            self.cell(0, 5, self.title, align="R")
            self.ln(8)

    def footer(self):
        self.set_y(-15)
        self.set_font("Helvetica", "I", 7)
        self.set_text_color(*STONE)
        self.cell(0, 8, str(self.page_no()), align="C")

    def section_title(self, text):
        self.ln(6)
        self.set_font("Helvetica", "B", 14)
        self.set_text_color(*INK_BLUE)
        self.cell(0, 8, _sanitize(text), new_x="LMARGIN", new_y="NEXT")
        self.set_draw_color(*INK_LIGHT)
        self.line(self.l_margin, self.get_y(), self.w - self.r_margin, self.get_y())
        self.ln(5)

    def body_text(self, text):
        self.set_font("Helvetica", "", 10)
        self.set_text_color(*NEAR_BLACK)
        self.multi_cell(0, 5.5, _sanitize(text))
        self.ln(2)

    def body_list(self, items):
        self.set_font("Helvetica", "", 10)
        self.set_text_color(*NEAR_BLACK)
        indent = self.l_margin + 8
        width = self.w - self.l_margin - self.r_margin - 8
        for item in items:
            self.set_x(indent - 8)
            self.cell(8, 5.5, "-")
            self.set_x(indent)
            self.multi_cell(width, 5.5, _sanitize(item))
        self.ln(2)

    def code_block(self, text):
        self.set_font("Courier", "", 9)
        self.set_fill_color(250, 250, 248)
        self.set_text_color(*NEAR_BLACK)
        self.multi_cell(0, 4.5, text, fill=True)
        self.ln(3)


def build_pdf(input_md=None, output_pdf=None, title="Shokunin Document"):
    pdf = KamiPDF()
    pdf.title = title
    pdf.set_auto_page_break(auto=True, margin=20)
    pdf.set_left_margin(20)
    pdf.set_right_margin(20)
    pdf.add_page()

    # Title page
    pdf.ln(40)
    pdf.set_font("Helvetica", "B", 28)
    pdf.set_text_color(*INK_BLUE)
    pdf.multi_cell(0, 12, title, align="C")
    pdf.ln(4)
    pdf.set_font("Helvetica", "", 12)
    pdf.set_text_color(*DARK_WARM)
    pdf.cell(0, 8, "github.com/EliasOulkadi/shokunin", align="C", new_x="LMARGIN", new_y="NEXT")
    pdf.cell(0, 6, "62 Skills  |  Windows + Linux  |  Open Source MIT", align="C", new_x="LMARGIN", new_y="NEXT")

    # If no input file, generate white paper
    if input_md is None:
        _build_whitepaper(pdf)
    else:
        with open(input_md, encoding="utf-8") as f:
            content = f.read()
        for section in content.split("\n## "):
            if section.startswith("# "):
                pdf.section_title(section[2:].strip())
            else:
                pdf.body_text(section.strip())

    pdf.output(output_pdf)
    print(f"PDF generated: {output_pdf} ({pdf.page_no()} pages)")


def _build_whitepaper(pdf):
    pdf.section_title("Architecture Overview")
    pdf.body_text(
        "Shokunin is a production-grade AI coding ecosystem providing persistent memory via ChromaDB, "
        "62 specialized AI skills, MCP (Model Context Protocol) servers for tool integration, and a "
        "declarative self-update system. It runs fully offline with zero server infrastructure and zero API costs."
    )

    pdf.section_title("Memory System")
    pdf.body_text(
        "The memory system uses a three-layer architecture: ChromaDB for vector semantic search across "
        "sessions, JSONL transaction logs for structured programmatic analysis, and Markdown session files "
        "for human-readable review. The MCP server implements JSON-RPC 2.0 over stdin/stdout with 9 tools."
    )
    pdf.body_list(
        [
            "store_context: Store text in persistent memory with type, tags, and project metadata",
            "search_context: Vector similarity search with freshness decay blending",
            "get_session_summary: Retrieve all entries for a specific session (max 100)",
            "multi_search_context: Combined vector + BM25 + temporal filter with RRF fusion",
            "consolidate_memories: Summarize old entries per project",
            "list_sessions: Recent sessions with metadata and entry counts",
            "continue_session: Full context load for session resume",
            "save_message: Record messages in session transcript",
            "verify_file_path: Validate file/directory existence before acting on stale claims",
        ]
    )

    pdf.section_title("Freshness Decay")
    pdf.body_text(
        "Memories decay exponentially over a 30-day half-life. The search_context and multi_search_context "
        "tools accept a freshness_boost parameter (0.0 to 1.0) that blends vector similarity with recency. "
        "At 0.0, results are purely relevance-based. At 1.0, they are purely recency-based. At 0.5, the "
        "blend gives equal weight to relevance and freshness. This prevents stale memories from drowning "
        "out recent context."
    )

    pdf.section_title("Claim Verification")
    pdf.body_text(
        "The hardest problem in persistent memory is not storage — it is retrieval shaping. When an agent "
        "recalls 'the auth helper lives at src/x.ts' from a memory written two weeks ago, it cannot act "
        "blindly. The verify_file_path MCP tool validates file paths before the agent proceeds. If the "
        "file no longer exists, the agent searches memory for newer entries describing the refactoring, "
        "then greps the actual codebase. Memory is treated as a claim from a frozen point in time — "
        "never as fact."
    )

    pdf.section_title("Skills Ecosystem — 62 Skills")
    pdf.body_text(
        "Every skill includes YAML frontmatter with name and description for automatic trigger matching. "
        "All 62 skills now include four mandatory sections: Workflow (numbered procedural steps), Error "
        "Handling (5+ Cause|Fix scenarios), Sources (5+ verifiable references), and Anti-Patterns "
        "(5+ Pattern|Problem|Fix entries). Average skill length is 257 lines."
    )
    pdf.body_list(
        [
            "Infrastructure: docker, kubernetes, terraform, ci-cd, db-admin",
            "Backend: api-forge, auth-architect, db-sculptor, error-handler",
            "Frontend: component-forge, responsive-engine, motion-craft, landing-craft, aesthetic-web, ui-ux-pro-max, "
            "emil-design-eng, impeccable, taste, taste-soft, taste-minimalist",
            "Mobile: flutter, react-native",
            "Quality: test-commander, performance-profiler, code-review, comprehensive-review, cross-review, "
            "zen-review, zen-comprehensive-review",
            "Content: communication, content-marketing, business-proposals, seo-geo, translate-craft, documentation",
            "Productivity: git-workflow, windows-powershell, runbook-gen, strategy, design, finance, "
            "legal-counsel, whendone-plus",
            "Documents: kami, kagen, portfolio-auto",
            "AI Agents: agent-browser, agent-tools, skill-creator",
            "Extras: playwright, web-security, plan, find-skills, efficient-coding, senior-engineer",
            "Ecosystem: shokunin-update, chromadb, memory",
            "Language: humanize, research, init",
        ]
    )

    pdf.section_title("Getting Started")
    pdf.body_text("Windows one-command install:")
    pdf.code_block("  irm https://raw.githubusercontent.com/EliasOulkadi/shokunin/master/install.ps1 | iex")
    pdf.body_text("Linux:")
    pdf.code_block("  bash <(curl -sSL https://raw.githubusercontent.com/EliasOulkadi/shokunin/master/install.sh)")
    pdf.body_text(
        "Requirements: Windows 10/11 or Linux, Node.js 18+, Python 3.11+, Git. "
        "After installation, open a new terminal and run 'opencode'. The ecosystem activates automatically."
    )

    pdf.section_title("Quality and Testing")
    pdf.body_list(
        [
            "29 integration tests covering security (path traversal sanitization), MCP protocol compliance, "
            "and ChromaDB operations (save/search/recall/session)",
            "12 PowerShell scripts with Set-StrictMode, ErrorActionPreference, and CmdletBinding",
            "100% type-annotated Python with lazy ChromaDB initialization",
            "CI/CD pipeline with mypy type checking, bandit security scanning, and dependabot",
            "Cross-platform support: Windows 11 (native) and Linux (via install.sh)",
        ]
    )


if __name__ == "__main__":
    input_file = sys.argv[1] if len(sys.argv) > 1 else None
    output_file = sys.argv[2] if len(sys.argv) > 2 else "output.pdf"
    title = None
    for i, arg in enumerate(sys.argv):
        if arg == "--title" and i + 1 < len(sys.argv):
            title = sys.argv[i + 1]
    if title is None and "--title" not in sys.argv:
        title = None

    build_pdf(
        input_md=input_file if input_file and input_file != "--title" else None,
        output_pdf=output_file if output_file != "--title" else "output.pdf",
        title=title or "Shokunin Technical Overview v4.2.2",
    )
