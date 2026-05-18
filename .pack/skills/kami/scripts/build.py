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
    # Page 1 — Title page
    pdf.ln(20)
    pdf.set_font("Helvetica", "", 10)
    pdf.set_text_color(*STONE)
    pdf.cell(0, 6, "Technical Overview", align="C", new_x="LMARGIN", new_y="NEXT")
    pdf.cell(0, 6, "Open Source -- MIT License", align="C", new_x="LMARGIN", new_y="NEXT")
    pdf.cell(0, 6, "github.com/EliasOulkadi/shokunin", align="C", new_x="LMARGIN", new_y="NEXT")
    pdf.ln(16)
    pdf.set_draw_color(*INK_BLUE)
    pdf.set_line_width(0.5)
    pdf.line(pdf.l_margin + 80, pdf.get_y(), pdf.w - pdf.r_margin - 80, pdf.get_y())
    pdf.ln(16)

    # Page 1 — Architecture Overview
    pdf.section_title("1. Architecture Overview")
    pdf.body_text(
        "Shokunin is a production-grade AI coding ecosystem that provides persistent memory via ChromaDB, "
        "62 specialized AI skills across 10 domains, MCP (Model Context Protocol) servers for tool "
        "integration, and a declarative self-update system. It runs fully offline with zero server "
        "infrastructure and zero API costs."
    )
    pdf.body_text(
        "The ecosystem operates on two levels: a local runtime (~/.shokunin/) that manages memory, "
        "sessions, and script execution, and a distribution layer (.pack/) that contains 62 skills, "
        "MCP server implementations, CLI tools, and installer scripts. The update system uses a "
        "declarative JSON manifest (shokunin.json) with template-based regeneration and backup/rollback."
    )

    pdf.section_title("2. Memory System Architecture")
    pdf.body_text(
        "The memory system stores AI agent context across sessions using three complementary layers:"
    )
    pdf.body_list([
        "Layer 1 — ChromaDB Vector Store: Semantic embeddings enable similarity search across all "
        "stored entries. Default embedding model is all-MiniLM-L6-v2 (384 dimensions), running "
        "locally via ONNX with no API dependency. Collection stores documents with metadata including "
        "type, tags, project, session_id, and timestamp.",
        "Layer 2 — JSONL Transaction Log: Every interaction is logged as line-delimited JSON in "
        "per-session files. Provides structured, machine-parseable records for programmatic analysis "
        "and replay. Includes entry type, timestamp, session_id, content, and role tracking.",
        "Layer 3 — Markdown Session Files: Human-readable summaries for manual review and debugging. "
        "Each session produces a .md file with timestamped entries organized by type (decisions, files, "
        "commands, checkpoints, session_end).",
    ])
    pdf.body_text(
        "The MCP server (mcp-server.py, 559 lines) implements JSON-RPC 2.0 over stdin/stdout, "
        "requiring zero network configuration. It exposes 9 tools for memory operations, session "
        "management, and file path verification. All Python code is 100% type-annotated with lazy "
        "ChromaDB initialization and double-checked locking for thread safety."
    )

    pdf.section_title("3. Multi-Strategy Search")
    pdf.body_text(
        "The multi_search_context tool combines four search strategies with Reciprocal Rank Fusion:"
    )
    pdf.body_list([
        "Vector Search: ChromaDB semantic similarity using cosine distance on document embeddings.",
        "BM25 Keyword Search: Term frequency-inverse document frequency with tunable k1 and b "
        "parameters. Builds an index from session documents and tokenizes for full-text matching.",
        "Temporal Filtering: Date-range filtering using ISO 8601 timestamps (from_date/to_date) "
        "to narrow results to specific time windows.",
        "Reciprocal Rank Fusion (RRF): Merges vector and BM25 result lists with a weighted k "
        "constant (default 60). Entries appearing in both lists receive combined scores. "
        "Deduplication by session_id + content hash prevents double-weighting.",
    ])

    # Page ~3 — Freshness Decay
    pdf.section_title("4. Freshness Decay System")
    pdf.body_text(
        "One of the hardest problems in persistent memory is retrieval shaping: ensuring recent "
        "context surfaces before stale claims. Shokunin solves this with exponential freshness "
        "decay blended with vector similarity."
    )
    pdf.body_text(
        "Each memory entry carries a UTC timestamp. When searching with freshness_boost > 0, "
        "the similarity score becomes a weighted blend:"
    )
    pdf.code_block(
        "  blended_score = (1 - freshness_boost) * vector_similarity\n"
        "                  + freshness_boost * exp(-days_since_stored / 30)"
    )
    pdf.body_text(
        "At freshness_boost = 0.0, results are purely relevance-based (default). At 0.5, "
        "relevance and recency receive equal weight. At 1.0, results are purely recency-based. "
        "The 30-day half-life means an entry from 30 days ago receives 50% of the recency weight "
        "of an entry stored today. After 90 days, recency weight drops below 5%."
    )
    pdf.body_text(
        "This system prevents the common failure mode where an agent recalls 'the auth helper lives "
        "at src/x.ts' from a memory written two weeks ago, after the file has been refactored. "
        "The freshness decay naturally deprioritizes stale claims, while the verify_file_path "
        "tool (detailed below) provides explicit verification."
    )

    pdf.section_title("5. Claim Verification System")
    pdf.body_text(
        "The verify_file_path MCP tool is the centerpiece of Shokunin's approach to memory safety. "
        "When an agent recalls a specific file path from old memory, the tool validates whether the "
        "path still exists on the local filesystem before the agent acts on it."
    )
    pdf.body_text("The verification workflow:")
    pdf.body_list([
        "1. Agent recalls a memory mentioning a file path (e.g., 'auth helper at src/auth.ts')",
        "2. Agent calls verify_file_path('src/auth.ts') before acting",
        "3. If the file exists: returns {exists: true, path, last_modified, kind}",
        "4. If the file does not exist: returns {exists: false}. Agent searches memory for newer "
        "entries describing the refactoring, then greps the codebase for the current location",
        "5. Agent acts only after confirming the path, never on stale claims alone",
    ])
    pdf.body_text(
        "The CLAUDE.md and AGENTS.md files contain a mandatory CLAIM VERIFICATION section that "
        "instructs the agent: 'When a memory mentions a specific FILE PATH, FUNCTION NAME, or "
        "CONFIG FLAG: It is a CLAIM FROM A FROZEN POINT IN TIME — not guaranteed current. "
        "BEFORE acting on it, verify the file/function/flag still exists.'"
    )
    pdf.body_text(
        "Claim types (claim_file, claim_function, claim_flag, claim_api) extend VALID_TYPES to "
        "enable structured fact tracking. Each claim carries enriched metadata including the "
        "claimed path, function name, or flag value, plus a verified_at timestamp when the "
        "claim is validated."
    )

    # Page ~5 — Full MCP Tools
    pdf.section_title("6. MCP Tool Suite (9 Tools)")
    pdf.body_text(
        "All tools are exposed via the MCP server over JSON-RPC 2.0 stdin/stdout transport:"
    )
    pdf.body_list([
        "store_context — Store text in persistent memory with type (12 valid types including "
        "decision, file, command, preference, checkpoint, session_end, claim_file, "
        "claim_function, claim_flag, claim_api), tags, project, and session_id",
        "search_context — Vector similarity search with freshness_boost parameter (0.0-1.0). "
        "Returns ranked results with similarity scores, metadata, and timestamps",
        "get_session_summary — Retrieve all entries for a specific session with aggregated "
        "statistics (tags, projects, types). Limited to 100 entries maximum to prevent OOM",
        "multi_search_context — Combined vector + BM25 + temporal filter with RRF fusion. "
        "Accepts freshness_boost and date range parameters",
        "consolidate_memories — Summarize old entries per project by extracting common terms "
        "and generating consolidated summary documents",
        "list_sessions — Recent sessions with metadata (project, entry count, first/last "
        "timestamp, types). Filters out healthcheck and test entries",
        "continue_session — Full context load for session resume. Returns decisions, files, "
        "commands, checkpoints, and JSONL message transcript",
        "save_message — Record an individual message exchange (user or assistant) in the "
        "session transcript as line-delimited JSON",
        "verify_file_path — Validate file/directory existence on local filesystem. Supports "
        "~ expansion and relative paths. Returns exists, path, last_modified, and kind",
    ])

    # Page ~6-7 — All 62 skills
    pdf.section_title("7. Skills Ecosystem — 62 Skills")
    pdf.body_text(
        "Every skill includes YAML frontmatter with name and description for automatic trigger "
        "matching. All 62 skills include four mandatory sections: Workflow (numbered procedural "
        "steps), Error Handling (5+ Cause|Fix scenarios), Sources (5+ verifiable references), "
        "and Anti-Patterns (5+ Pattern|Problem|Fix entries). Average skill length is 257 lines."
    )

    skill_categories = [
        ("Infrastructure (5)", ["docker — Multi-stage Dockerfiles with BuildKit, distroless, "
        "seccomp profiles, and CVE scanning", "kubernetes — Gateway API, zero-trust networking, "
        "Helm charts, Kustomize overlays, pod hardening", "terraform — Remote state, modules, "
        "Stacks, cost estimation, state surgery", "ci-cd — GitHub Actions, GitLab CI, CircleCI, "
        "matrix builds, canary deployments", "db-admin — Replication, PITR, vacuum strategy, "
        "connection pooling"]),
        ("Backend (5)", ["api-forge — REST/GraphQL APIs with OpenAPI 3.1, rate limiting, "
        "webhooks, idempotency", "auth-architect — OAuth2 + OIDC, PKCE, WebAuthn, RBAC/ABAC, "
        "OWASP-aligned", "db-sculptor — Prisma/Drizzle schemas, PostgreSQL indexes (B-tree, "
        "GIN, GiST), EXPLAIN ANALYZE", "error-handler — OpenTelemetry, circuit breaker, retry "
        "with jitter, error budgets", "neon-postgres — Serverless Postgres, connection pooling, "
        "branching workflows"]),
        ("Frontend (11)", ["component-forge — React/Vue/Svelte components with 5 states "
        "(loading/empty/error/success/idle)", "responsive-engine — Container Queries, clamp(), "
        "dvh/svh, subgrid", "motion-craft — WAAPI, CSS animations, FLIP technique, 17-item "
        "pre-flight checklist", "landing-craft — CRO frameworks, LIFT Model, A/B testing, "
        "4 vibe archetypes", "aesthetic-web — OKLCH color, grain textures, gradient meshes, "
        "3D scroll", "ui-ux-pro-max — 67 styles, 96 palettes, 57 font pairings, CLI tool",
        "emil-design-eng — Sonner/Vaul/Linear patterns, animation decisions", "impeccable — "
        "Paul Bakaus design laws, AI slop test, 10 manual checks", "taste — Leon Lin variance "
        "engine, anti-center bias, GPU-safe rules", "taste-soft — Double-Bezel architecture, "
        "Button-in-Button pattern", "taste-minimalist — Warm monochrome, bento grids, muted pastels"]),
        ("Mobile (2)", ["flutter — Clean Architecture, Riverpod, GoRouter, Impeller, Pigeon",
        "react-native — Expo Router, FlashList, Reanimated 4, New Architecture"]),
        ("Quality (7)", ["test-commander — Testing Trophy (80% integration), MSW, Playwright, "
        "visual regression", "performance-profiler — Lighthouse, Core Web Vitals, bundle analysis",
        "code-review — Structured review P0-P3, security checklist, architectural review"]),
    ]
    for category, items in skill_categories:
        pdf.set_font("Helvetica", "B", 10)
        pdf.set_text_color(*INK_BLUE)
        pdf.cell(0, 6, category, new_x="LMARGIN", new_y="NEXT")
        pdf.set_font("Helvetica", "", 10)
        for item in items:
            pdf.set_text_color(*NEAR_BLACK)
            pdf.cell(4)
            pdf.cell(4, 5, "-")
            pdf.multi_cell(pdf.w - pdf.l_margin - pdf.r_margin - 12, 5, _sanitize(item))
        pdf.ln(1)

    more_cats = [
        ("Content & Business (6)", ["communication, content-marketing, business-proposals, seo-geo, translate-craft, documentation"]),
        ("Productivity (8)", ["git-workflow, windows-powershell, runbook-gen, strategy, design, finance, legal-counsel, whendone-plus"]),
        ("Documents (3)", ["kami, kagen, portfolio-auto"]),
        ("AI Agents & Ecosystem (9)", ["agent-browser, agent-tools, skill-creator, shokunin-update, chromadb, memory"]),
        ("Extras & Language (7)", ["playwright, web-security, plan, find-skills, efficient-coding, senior-engineer, humanize, research, init"]),
    ]
    for cat, items in more_cats:
        pdf.set_font("Helvetica", "B", 10)
        pdf.set_text_color(*INK_BLUE)
        pdf.cell(4) 
        pdf.cell(0, 5, cat, new_x="LMARGIN", new_y="NEXT")
        pdf.set_font("Helvetica", "", 10)
        pdf.set_text_color(*NEAR_BLACK)
        pdf.set_x(pdf.l_margin + 8)
        pdf.multi_cell(pdf.w - pdf.l_margin - pdf.r_margin - 8, 5, _sanitize(items[0]))
        pdf.ln(1)

    # Page ~8 — Quality
    pdf.section_title("8. Quality and Testing Infrastructure")
    pdf.body_list([
        "29 integration tests covering security (path traversal sanitization with 21 test cases), "
        "MCP protocol compliance (tools/list, invalid methods, tool not found), and ChromaDB "
        "operations (save, search, recall, session management). All tests pass on every commit.",
        "CI/CD pipeline with 3 workflows: CI (frontmatter validation, mypy type checking, "
        "bandit security scanning), Memory Tests (lint, integration tests, cross-platform "
        "validation on Windows and Linux), and Release (automatic versioning and deployment).",
        "12 PowerShell scripts with Set-StrictMode -Version Latest, ErrorActionPreference, "
        "CmdletBinding, and comment-based help on all public scripts.",
        "100% type-annotated Python codebase (from __future__ import annotations). Lazy "
        "ChromaDB initialization with threading.Lock for thread safety. _dispatch pattern "
        "for JSON-RPC routing with proper notification suppression.",
        "Dependabot for automated dependency updates, CODEOWNERS for review assignment, "
        ".editorconfig for consistent formatting across editors.",
    ])

    pdf.section_title("9. Security Architecture")
    pdf.body_list([
        "Path traversal prevention via regex-based session ID sanitization (_sanitize_id / "
        "_safe_id). All special characters replaced with safe alternatives before file I/O.",
        "Error message sanitization: MCP server returns generic 'Internal server error' to "
        "clients; full error details logged server-side only.",
        "All exception handlers include logging with context (session ID, operation, data "
        "involved). No bare except blocks remain in the codebase.",
        "Double-checked locking pattern on ChromaDB initialization prevents race conditions "
        "in multi-threaded access scenarios.",
        "JSON-RPC 2.0 compliance: notifications (requests without id) receive no response, "
        "preventing protocol-level information leaks.",
    ])

    pdf.section_title("10. Getting Started")
    pdf.body_text("Windows one-command install:")
    pdf.code_block("  irm https://raw.githubusercontent.com/EliasOulkadi/shokunin/master/install.ps1 | iex")
    pdf.body_text("Linux:")
    pdf.code_block("  bash <(curl -sSL https://raw.githubusercontent.com/EliasOulkadi/shokunin/master/install.sh)")
    pdf.body_text(
        "Requirements: Windows 10/11 or Linux, Node.js 18+, Python 3.11+, Git. "
        "The installer sets up ChromaDB, 62 skills, PowerShell/Linux profiles, MCP servers, "
        "scheduled maintenance tasks, and the OpenCode configuration. After installation, "
        "open a new terminal and run 'opencode'. The ecosystem activates automatically with "
        "persistent memory across sessions."
    )
    pdf.body_text(
        "The skills browser at https://eliasoulkadi.github.io/shokunin/skills.html provides "
        "an interactive catalog of all 62 skills with search, domain grouping, and expandable "
        "content previews."
    )


if __name__ == "__main__":
    input_file = None
    output_file = "output.pdf"
    title = "Shokunin Technical Overview v4.2.2"
    args = sys.argv[1:]
    i = 0
    while i < len(args):
        if args[i] == "--title" and i + 1 < len(args):
            title = args[i + 1]; i += 2
        elif args[i] == "--output" and i + 1 < len(args):
            output_file = args[i + 1]; i += 2
        elif args[i] == "--input" and i + 1 < len(args):
            input_file = args[i + 1]; i += 2
        elif not args[i].startswith("--"):
            if input_file is None:
                input_file = args[i]
            else:
                output_file = args[i]
            i += 1
        else:
            i += 1

    build_pdf(
        input_md=input_file,
        output_pdf=output_file,
        title=title,
    )
