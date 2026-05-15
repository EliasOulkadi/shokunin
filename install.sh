#!/usr/bin/env bash
set -euo pipefail

VERSION="4.2"
CORES_DIR="$HOME/.shokunin"
SKILLS_DIR="$HOME/.config/opencode/skills"
CONFIG_DIR="$HOME/.config/opencode"
CLAUDE_DIR="$HOME/.claude"
LOG_FILE="/tmp/shokunin-install-$(date +%Y%m%d-%H%M%S).log"

step=1
log() { echo "  $1" | tee -a "$LOG_FILE"; }
step_msg() { echo ""; echo "[$step] $1"; step=$((step + 1)); }
ok() { echo "    OK"; }
skip() { echo "    SKIP (already exists)"; }

echo ""
echo "=========================================="
echo "  Shokunin AI Ecosystem v$VERSION"
echo "  Linux Installer"
echo "  github.com/EliasOulkadi/shokunin"
echo "=========================================="
echo ""
echo "  Requires: bash 4+, Node.js 18+, Python 3.11+"
echo ""

read -r -p "  Continue? (y/n): " CONFIRM
if [ "$CONFIRM" != "y" ]; then echo "  Cancelled."; exit 0; fi

# === PREREQUISITES ===
step_msg "Verifying prerequisites..."
ALL_OK=true

if bash --version | grep -q "GNU bash"; then log "bash OK"; else log "bash required"; ALL_OK=false; fi

if command -v node &>/dev/null; then
    NODE_VER=$(node --version | sed 's/v//' | cut -d. -f1)
    if [ "$NODE_VER" -ge 18 ]; then log "Node.js $(node --version)"; else log "Node.js 18+ required"; ALL_OK=false; fi
else
    log "Node.js 18+ required (apt install nodejs or https://nodejs.org)"; ALL_OK=false
fi

if command -v python3 &>/dev/null; then
    PY_VER=$(python3 --version 2>&1 | sed 's/Python //' | cut -d. -f1-2)
    PY_MAJOR=$(echo "$PY_VER" | cut -d. -f1)
    PY_MINOR=$(echo "$PY_VER" | cut -d. -f2)
    if [ "$PY_MAJOR" -ge 3 ] && [ "$PY_MINOR" -ge 11 ]; then log "Python $PY_VER"; else log "Python 3.11+ required"; ALL_OK=false; fi
else
    log "Python 3.11+ required (apt install python3 python3-pip)"; ALL_OK=false
fi

if command -v git &>/dev/null; then log "Git $(git --version | cut -d' ' -f3)"; else log "Git required (apt install git)"; ALL_OK=false; fi

if command -v opencode &>/dev/null; then
    log "OpenCode detected"
else
    log "Installing OpenCode..."
    npm install -g opencode 2>/dev/null && log "OpenCode installed" || { log "npm install -g opencode failed"; ALL_OK=false; }
fi

$ALL_OK || { echo "  Install missing requirements and re-run."; exit 1; }

# === DEPENDENCIES ===
step_msg "Installing Python dependencies..."
pip3 install chromadb 2>/dev/null && ok || log "pip install chromadb failed (try: pip install chromadb)"

# === DIRECTORIES ===
step_msg "Creating directories..."
mkdir -p "$CORES_DIR/memory/chroma_db" "$CORES_DIR/memory/sessions" "$CORES_DIR/scripts/linux" "$CORES_DIR/backups"
mkdir -p "$SKILLS_DIR" "$CONFIG_DIR" "$CLAUDE_DIR"
ok

# === SKILLS ===
step_msg "Installing skills..."
REPO_DIR="/tmp/shokunin-repo"
if [ -d "$REPO_DIR" ]; then rm -rf "$REPO_DIR"; fi
for retry in 1 2 3; do
    git clone --depth 1 https://github.com/EliasOulkadi/shokunin.git "$REPO_DIR" 2>/dev/null && break
    sleep 1
done

COUNT=0
for dir in "$REPO_DIR"/*/; do
    if [ -f "${dir}SKILL.md" ]; then
        NAME=$(basename "$dir")
        TARGET="$SKILLS_DIR/$NAME"
        mkdir -p "$TARGET"
        cp -r "${dir}"* "$TARGET/" 2>/dev/null || true
        COUNT=$((COUNT + 1))
    fi
done
log "$COUNT skills installed"

# === MEMORY SYSTEM ===
step_msg "Installing memory system..."
cp "$REPO_DIR/.pack/memory/mcp-server.py" "$CORES_DIR/memory/mcp-server.py" 2>/dev/null || curl -sL "https://raw.githubusercontent.com/EliasOulkadi/shokunin/master/.pack/memory/mcp-server.py" -o "$CORES_DIR/memory/mcp-server.py"
cp "$REPO_DIR/.pack/scripts/chroma-helper.py" "$CORES_DIR/scripts/chroma-helper.py" 2>/dev/null || curl -sL "https://raw.githubusercontent.com/EliasOulkadi/shokunin/master/.pack/scripts/chroma-helper.py" -o "$CORES_DIR/scripts/chroma-helper.py"
ok

# === LINUX SCRIPTS ===
step_msg "Installing Linux scripts..."
for script in run-opencode.sh memory-healthcheck.sh weekly-maintenance.sh profile.sh; do
    SRC="$REPO_DIR/.pack/scripts/linux/$script"
    if [ -f "$SRC" ]; then
        cp "$SRC" "$CORES_DIR/scripts/linux/$script"
        chmod +x "$CORES_DIR/scripts/linux/$script"
    else
        curl -sL "https://raw.githubusercontent.com/EliasOulkadi/shokunin/master/.pack/scripts/linux/$script" -o "$CORES_DIR/scripts/linux/$script" 2>/dev/null
        chmod +x "$CORES_DIR/scripts/linux/$script" 2>/dev/null || true
    fi
done
log "Linux scripts installed"

# === OPENCODE CONFIG ===
step_msg "Configuring OpenCode..."
CONFIG_SRC="$REPO_DIR/.pack/opencode.json"
if [ -f "$CONFIG_DIR/opencode.json" ]; then
    cp "$CONFIG_DIR/opencode.json" "$CONFIG_DIR/opencode.json.shokunin-backup-$(date +%Y%m%d-%H%M%S)"
fi

NVIDIA_KEY="${NVIDIA_API_KEY:-}"
if [ -z "$NVIDIA_KEY" ]; then
    echo ""
    echo "  For AI you need a free NVIDIA API key:"
    echo "  1. Go to https://build.nvidia.com/ (free signup)"
    echo "  2. Generate an API key"
    echo "  3. Paste it below (or leave empty to configure later)"
    echo ""
    read -r -p "  NVIDIA API Key: " NVIDIA_KEY
fi

if [ -f "$CONFIG_SRC" ]; then
    # Detect Python binary (python3 on Debian/Ubuntu, python on others)
    PYTHON_BIN="python3"
    command -v python3 &>/dev/null || PYTHON_BIN="python"

    # Generate config with all substitutions
    sed "s|YOUR_NVIDIA_API_KEY|$NVIDIA_KEY|g; \
         s|{{MCP_ROOT_PATH}}|$HOME|g; \
         s|{{PYTHON_BIN}}|$PYTHON_BIN|g; \
         s|{{MCP_MEMORY_PATH}}|$CORES_DIR/memory/mcp-server.py|g" \
      "$CONFIG_SRC" > "$CONFIG_DIR/opencode.json" 2>/dev/null || cp "$CONFIG_SRC" "$CONFIG_DIR/opencode.json"

    # Validate no unsubstituted placeholders remain
    if grep -q "{{MCP_\|{{PYTHON_BIN}}" "$CONFIG_DIR/opencode.json" 2>/dev/null; then
        log "WARNING: MCP placeholders not substituted. Check opencode.json"
    fi
fi
if [ -n "$NVIDIA_KEY" ] && ! grep -q "NVIDIA_API_KEY" "$HOME/.bashrc" 2>/dev/null; then
    echo "export NVIDIA_API_KEY='$NVIDIA_KEY'" >> "$HOME/.bashrc"
fi
log "Config generated"

# === INSTRUCTIONS ===
step_msg "Configuring global instructions..."
CLAUDE_SRC="$REPO_DIR/.pack/CLAUDE.md"
if [ -f "$CLAUDE_SRC" ]; then
    if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
        cp "$CLAUDE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md.shokunin-backup-$(date +%Y%m%d-%H%M%S)"
    fi
    cp "$CLAUDE_SRC" "$CLAUDE_DIR/CLAUDE.md"
fi

AGENTS_SRC="$REPO_DIR/.pack/AGENTS.md"
if [ -f "$AGENTS_SRC" ]; then
    cp "$AGENTS_SRC" "$HOME/AGENTS.md"
fi
log "Instructions configured"

# === PROFILE ===
step_msg "Configuring shell profile..."
PROFILE_FILE=""
if [ -f "$HOME/.zshrc" ]; then PROFILE_FILE="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then PROFILE_FILE="$HOME/.bashrc"
elif [ -f "$HOME/.bash_profile" ]; then PROFILE_FILE="$HOME/.bash_profile"
fi

if [ -n "$PROFILE_FILE" ]; then
    if grep -q "Shokunin" "$PROFILE_FILE" 2>/dev/null; then
        log "Shokunin already in $PROFILE_FILE"
    else
        echo "" >> "$PROFILE_FILE"
        echo "# Shokunin AI Ecosystem" >> "$PROFILE_FILE"
        echo "source \$HOME/.shokunin/scripts/linux/profile.sh" >> "$PROFILE_FILE"
        log "Added to $PROFILE_FILE"
    fi
else
    log "No .bashrc/.zshrc found. Add 'source ~/.shokunin/scripts/linux/profile.sh' manually"
fi

# === CRONTAB ===
step_msg "Setting up weekly maintenance..."
if crontab -l 2>/dev/null | grep -q "shokunin"; then
    log "Crontab already configured"
else
    (crontab -l 2>/dev/null; echo "0 21 * * 0 \$HOME/.shokunin/scripts/linux/weekly-maintenance.sh") | crontab -
    log "Crontab added (Sunday 21:00)"
fi

# === CLEANUP ===
rm -rf "$REPO_DIR"

# === SUMMARY ===
echo ""
echo "=========================================="
echo "  Shokunin AI Ecosystem - Installed"
echo "=========================================="
echo ""
echo "  Skills: $COUNT installed"
echo "  Memory: ChromaDB in $CORES_DIR/memory"
echo "  Shell: source ~/.shokunin/scripts/linux/profile.sh"
echo "  Crontab: Sunday 21:00 (backup + cleanup)"
echo ""
echo "  NEXT STEPS:"
echo "  1. Reload your shell: source ~/.bashrc"
echo "  2. Start coding: opencode"
echo "  3. Test memory: ./memory-healthcheck.sh"
echo ""
echo "  Repo: https://github.com/EliasOulkadi/shokunin"
echo "=========================================="
