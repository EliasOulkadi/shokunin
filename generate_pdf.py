"""Generate Shokunin Enterprise White Paper v4.2.2 using fpdf2."""

from fpdf import FPDF
from datetime import datetime

INK_BLUE = (27, 54, 93)
INK_LIGHT = (45, 90, 138)
STONE = (107, 106, 100)
PARCHMENT = (245, 244, 237)
NEAR_BLACK = (20, 20, 19)
TAG_BG = (228, 236, 245)

PAGE_W = 190
PAGE_H = 277
MARGIN = 18
BODY_W = PAGE_W - MARGIN * 2
LINE_H = 5.5
PARA_GAP = 3


def safe(text):
    return text.replace("\u2014", " -- ").replace("\u2013", "--").replace("\u2022", "-")


class ShokuninPDF(FPDF):
    def __init__(self):
        super().__init__("P", "mm", (PAGE_W, PAGE_H))
        self.set_auto_page_break(True, MARGIN + 4)
        self.set_margin(MARGIN)

    def header(self):
        if self.page_no() == 1:
            return
        self.set_font("Helvetica", "I", 7)
        self.set_text_color(*STONE)
        self.cell(0, 8, "Shokunin Enterprise", align="L")
        self.cell(0, 8, f"v4.2.2  |  {datetime.now().year}", align="R", new_x="LMARGIN", new_y="NEXT")

    def footer(self):
        self.set_y(-MARGIN)
        self.set_font("Helvetica", "I", 7)
        self.set_text_color(*STONE)
        self.cell(0, 8, str(self.page_no()), align="C")

    def cover(self):
        self.add_page()
        self.ln(40)
        self.set_fill_color(*INK_BLUE)
        self.rect(0, 0, PAGE_W, 3, "F")
        self.set_font("Times", "B", 32)
        self.set_text_color(*NEAR_BLACK)
        self.cell(0, 12, "Shokunin", align="L", new_x="LMARGIN", new_y="NEXT")
        self.set_font("Times", "", 14)
        self.set_text_color(*STONE)
        self.ln(4)
        self.cell(0, 7, "Persistent AI Memory for Developers", new_x="LMARGIN", new_y="NEXT")
        self.ln(4)
        self.set_draw_color(*INK_BLUE)
        self.set_line_width(0.4)
        self.line(self.l_margin, self.get_y(), self.l_margin + 50, self.get_y())
        self.ln(8)
        self.set_font("Helvetica", "", 10)
        self.set_text_color(*STONE)
        self.cell(0, 6, "Enterprise White Paper v4.2.2", new_x="LMARGIN", new_y="NEXT")
        self.cell(0, 6, f"Generated {datetime.now().strftime('%B %Y')}", new_x="LMARGIN", new_y="NEXT")
        self.ln(6)
        self.set_font("Helvetica", "", 8)
        self.set_text_color(*INK_LIGHT)
        self.multi_cell(0, 5, safe(
            "62 skills. 9 MCP memory tools. Multi-strategy recall (vector + BM25 + temporal + RRF). "
            "Freshness decay with 30-day half-life. Claim verification for stale memory paths. "
            "Zero servers, zero API costs, fully offline. MIT licensed."))

    def section(self, title):
        self.ln(4)
        self.set_font("Helvetica", "B", 12)
        self.set_text_color(*INK_BLUE)
        self.cell(0, 7, safe(title), new_x="LMARGIN", new_y="NEXT")
        self.set_draw_color(*INK_BLUE)
        self.set_line_width(0.3)
        self.line(self.l_margin, self.get_y(), self.l_margin + BODY_W * 0.35, self.get_y())
        self.ln(4)

    def body(self, text):
        self.set_font("Times", "", 10)
        self.set_text_color(*NEAR_BLACK)
        self.multi_cell(0, LINE_H, safe(text), new_x="LMARGIN", new_y="NEXT")
        self.ln(PARA_GAP)

    def bullet(self, text):
        self.set_font("Times", "", 10)
        self.set_text_color(*NEAR_BLACK)
        self.set_x(self.l_margin + 5)
        self.cell(4, LINE_H, "-")
        self.multi_cell(BODY_W - 9, LINE_H, safe(text), new_x="LMARGIN", new_y="NEXT")
        self.ln(PARA_GAP)

    def tag(self, text):
        self.set_font("Helvetica", "B", 9)
        self.set_text_color(*INK_BLUE)
        self.set_fill_color(*TAG_BG)
        w = self.get_string_width(safe(text)) + 8
        self.cell(w, 7, safe(text), fill=True, new_x="RIGHT", new_y="NEXT", align="C")
        self.ln(2)


def build():
    pdf = ShokuninPDF()
    pdf.cover()

    # ── Introduction ──
    pdf.section("Shokunin Ecosystem Overview")
    pdf.body(
        "Shokunin is a comprehensive AI coding ecosystem that gives developers persistent memory across "
        "sessions, 62 domain-expert skills that auto-activate, and a fully offline architecture. "
        "The memory system uses three complementary retrieval strategies \u2014 vector similarity (semantic), "
        "BM25 (keyword), and temporal (recency) \u2014 fused via Reciprocal Rank Fusion to ensure the most "
        "relevant context surfaces for every query."
    )
    pdf.body(
        "Skills cover infrastructure (Docker, Kubernetes, Terraform), backend (auth, APIs, databases), "
        "frontend (React/Vue/Svelte with Emil Kowalski and Paul Bakaus design standards), mobile (Flutter "
        "and React Native), quality (testing, performance, code review), and content/business domains."
    )

    # ── Memory Architecture ──
    pdf.section("Memory Architecture")
    pdf.body(
        "The memory system is built on ChromaDB with a custom MCP (Model Context Protocol) server "
        "providing 9 tools for context storage, retrieval, and management. Data lives entirely on the "
        "developer's machine at ~/.shokunin/memory/ \u2014 no cloud, no telemetry, no subscriptions."
    )

    pdf.body("Core storage layers:")
    pdf.bullet("ChromaDB vector store for semantic similarity search")
    pdf.bullet("BM25 full-text index for keyword recall")
    pdf.bullet("JSONL session transcripts for replay and debugging")
    pdf.bullet("Markdown fallback files for human-readable history")
    pdf.bullet("Freshness decay blending: exponential recency with 30-day half-life")

    pdf.body("Search methods:")
    pdf.bullet("search_context \u2014 pure vector similarity with optional type/tag/project filters")
    pdf.bullet("multi_search_context \u2014 vector + BM25 + temporal, fused via RRF")
    pdf.bullet("Both methods accept freshness_boost (0.0\u20131.0) to blend relevance with recency")

    # ── Session Management ──
    pdf.section("Session Management")
    pdf.body(
        "Shokunin introduces explicit session management. Every AI interaction belongs to a session "
        "identified by session-YYYYMMDD-HHMMSS-NNNN. The agent lists recent sessions at startup, lets "
        "the user choose which one to continue, and loads full context from that session including all "
        "decisions, files, commands, and preferences."
    )
    pdf.bullet("No guessing \u2014 user explicitly selects which session to resume")
    pdf.bullet("Full context load on session continue (not just a summary)")
    pdf.bullet("Consolidation support for summarizing old entries per project")

    # ── MCP Tool Suite ──
    pdf.section("MCP Tool Suite \u2014 9 Tools")
    pdf.body(
        "The memory MCP server exposes 9 tools (up from 8 in v4.2.1), each with enriched schemas "
        "including freshness_boost parameters for time-weighted retrieval:"
    )
    pdf.bullet("store_context \u2014 Store entries with type classification and tags")
    pdf.bullet("search_context \u2014 Vector similarity search with freshness blending")
    pdf.bullet("multi_search_context \u2014 Vector + BM25 + RRF + temporal filtering")
    pdf.bullet("get_session_summary \u2014 Aggregate overview of a session")
    pdf.bullet("continue_session \u2014 Load full context from a session")
    pdf.bullet("list_sessions \u2014 Browse recent sessions with metadata")
    pdf.bullet("consolidate_memories \u2014 Summarize old entries per project")
    pdf.bullet("save_message \u2014 Record individual message exchanges")
    pdf.bullet("verify_file_path \u2014 Validate file/directory existence on local filesystem")

    # ── Multi-Runtime Compatibility ──
    pdf.section("Multi-Runtime Compatibility")
    pdf.body(
        "Shokunin works across multiple AI coding environments. Skills are runtime-agnostic SKILL.md "
        "files with trigger-optimized descriptions. Memory integrates via MCP or rule files. Config "
        "templates are provided for OpenCode (native), Claude Code, Cline, Cursor, Continue.dev, "
        "and Windsurf."
    )

    # ── Production Quality ──
    pdf.section("Production Quality")
    pdf.body(
        "Every component is validated in CI on every push. Skills are checked for frontmatter, workflow "
        "completeness, error handling patterns, and cited sources. The memory system has 29 integration "
        "tests covering security, MCP protocol compliance, and ChromaDB operations. 12 PowerShell scripts "
        "use Set-StrictMode, ErrorActionPreference, and CmdletBinding throughout."
    )
    pdf.bullet("GitHub Actions CI with Windows + Linux matrix")
    pdf.bullet("Memory test suite with one-command validation (test-memory.ps1 / memory-healthcheck.ps1)")
    pdf.bullet("OWASP-informed security patterns across all web features")
    pdf.bullet("Benchmark suite for recall performance and RRF scoring")

    # ── Retrieval Shaping ──
    pdf.section("Retrieval Shaping \u2014 Memory That Respects Time")
    pdf.body(
        "The hardest problem in persistent memory is not storage \u2014 it is retrieval. Shokunin solves "
        "this with exponential freshness decay blended with vector similarity. Each memory entry decays "
        "over a 30-day half-life, so recent context surfaces before stale claims. The agent can control "
        "the blend: freshness_boost=0.0 for pure relevance, 1.0 for pure recency, or any value between."
    )
    pdf.body(
        "When an agent recalls 'the auth helper lives at src/x.ts,' it does not act blindly. The new "
        "verify_file_path MCP tool validates file paths before the agent proceeds. If the file no longer "
        "exists, the agent searches memory for newer entries describing the refactoring, then greps the "
        "actual codebase. Memory is treated as a claim from a frozen point in time \u2014 never as fact."
    )

    # ── What Is New in v4.2.2 ──
    pdf.section("What Is New in v4.2.2")
    pdf.bullet("Freshness decay: exponential recency blending with 30-day half-life across all search methods")
    pdf.bullet("Claim types: claim_file, claim_function, claim_flag, claim_api for structured fact tracking")
    pdf.bullet("verify_file_path MCP tool: validates file/directory existence before agents act on stale claims")
    pdf.bullet("9 MCP tools (up from 8): all with freshness_boost parameter and enriched schemas")
    pdf.bullet("Claim Verification Rule in agent instructions: memory paths must be verified before use")
    pdf.bullet("30+ bug fixes: recursion, filter overwrite, RRF session collision, BM25 duplication, similarity formulas")
    pdf.bullet("29 integration tests covering security, MCP protocol, and ChromaDB operations")
    pdf.bullet("12 PowerShell scripts with Set-StrictMode, ErrorActionPreference, CmdletBinding")

    # ── Getting Started ──
    pdf.section("Getting Started")
    pdf.body("Windows (PowerShell):")
    pdf.tag("irm https://raw.githubusercontent.com/EliasOulkadi/shokunin/master/install.ps1 | iex")
    pdf.ln(2)
    pdf.body("Linux (bash):")
    pdf.tag("bash <(curl -sL https://raw.githubusercontent.com/EliasOulkadi/shokunin/master/install.sh)")
    pdf.ln(2)

    pdf.body(
        "Requirements: Python 3.11+, Node.js 18+, Git. The installer sets up everything: OpenCode CLI, "
        "ChromaDB, PowerShell/Bash profiles, MCP server configuration, and skill files. Start a session "
        "with opencode (or .\\run-opencode.ps1 for memory capture on Windows)."
    )

    # ── License ──
    pdf.section("License & Links")
    pdf.bullet("MIT License \u2014 free as in freedom, free as in zero cost")
    pdf.bullet("GitHub: github.com/EliasOulkadi/shokunin")
    pdf.bullet("Website: eliasoulkadi.github.io/shokunin")
    pdf.bullet("Documentation: docs/ARCHITECTURE.md, CHANGELOG.md")

    # ── Final ──
    pdf.ln(6)
    pdf.set_font("Times", "I", 10)
    pdf.set_text_color(*STONE)
    pdf.multi_cell(0, LINE_H, safe(
        "Shokunin v4.2.2 -- Persistent memory, multi-strategy recall, and claim verification "
        "for developers who demand production-grade tooling. Built for Windows 11 and Linux. "
        "Open source since 2024."), align="C")

    pdf.output("docs/Shokunin-Enterprise-White-Paper.pdf")
    print("PDF generated: docs/Shokunin-Enterprise-White-Paper.pdf")


if __name__ == "__main__":
    build()
