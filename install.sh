#!/usr/bin/env bash
set -euo pipefail

VERSION="4.2.3"
CORES_DIR="$HOME/.shokunin"
SKILLS_DIR="$HOME/.config/opencode/skills"
CONFIG_DIR="$HOME/.config/opencode"
CLAUDE_DIR="$HOME/.claude"
LOG_FILE="/tmp/shokunin-install-$(date +%Y%m%d-%H%M%S).log"

NONINTERACTIVE=false

step=1
log() { echo "  $1" | tee -a "$LOG_FILE"; }
step_msg() { echo ""; echo "[$step] $1"; step=$((step + 1)); }
ok() { echo "    OK"; }
skip() { echo "    SKIP (already exists)"; }
fail() { echo "    FAIL: $1" | tee -a "$LOG_FILE"; }

for arg in "$@"; do
  case "$arg" in
    -y|--yes) NONINTERACTIVE=true ;;
  esac
done

if [ -z "${BASH_VERSION:-}" ]; then
  echo "ERROR: This script must be run with bash, not sh."
  echo "  Correct: bash install.sh"
  exit 1
fi

echo ""
echo "=========================================="
echo "  Shokunin AI Ecosystem v$VERSION"
echo "  Linux Installer"
echo "  github.com/EliasOulkadi/shokunin"
echo "=========================================="
echo ""
echo "  Requires: bash 4+, Node.js 18+, Python 3.11+"
echo ""

if [ "$NONINTERACTIVE" = false ] && [ -t 0 ]; then
  read -r -p "  Continue? (y/n): " CONFIRM
  if [ "$CONFIRM" != "y" ]; then echo "  Cancelled."; exit 0; fi
fi

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
    log "Python 3.11+ required (apt install python3)"; ALL_OK=false
fi

if command -v git &>/dev/null; then log "Git $(git --version | cut -d' ' -f3)"; else log "Git required (apt install git)"; ALL_OK=false; fi

if command -v opencode &>/dev/null; then
    log "OpenCode detected"
else
    log "Installing OpenCode..."
    if command -v npm &>/dev/null; then
      if npm install -g opencode >> "$LOG_FILE" 2>&1; then
        log "OpenCode installed"
      else
        fail "npm install -g opencode failed. Try: sudo npm install -g opencode"
        ALL_OK=false
      fi
    else
      fail "npm not found. Install Node.js first: https://nodejs.org"
      ALL_OK=false
    fi
fi

$ALL_OK || { echo "  Install missing requirements and re-run."; exit 1; }

# === PYTHON DEPENDENCIES ===
step_msg "Installing Python dependencies..."

if ! python3 -m pip --version &>/dev/null; then
  log "Installing python3-pip..."
  if command -v apt-get &>/dev/null; then
    if [ "$(id -u)" -ne 0 ]; then
      SUDO="sudo"
    fi
    $SUDO apt-get install -y python3-pip >> "$LOG_FILE" 2>&1 || {
      fail "Could not install python3-pip. Try: sudo apt-get install python3-pip"
      exit 1
    }
  else
    fail "pip3 not found. Install python3-pip for your distro."
    exit 1
  fi
fi

PIP_FLAGS=""
if python3 -m pip install --dry-run chromadb 2>&1 | grep -q "externally-managed"; then
  log "Detected PEP 668, using --break-system-packages"
  PIP_FLAGS="$PIP_FLAGS --break-system-packages"
fi

if python3 -m pip list 2>/dev/null | grep -qi "typing-extensions"; then
  log "Detected typing-extensions, ignoring installed"
  PIP_FLAGS="$PIP_FLAGS --ignore-installed typing-extensions"
fi

python3 -m pip install chromadb $PIP_FLAGS >> "$LOG_FILE" 2>&1 && ok || {
  fail "pip install chromadb failed. Try: python3 -m pip install chromadb $PIP_FLAGS"
  exit 1
}

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

if [ ! -d "$REPO_DIR" ]; then
    fail "git clone failed after 3 attempts. Check network connectivity."
    exit 1
fi

COUNT=0
for dir in "$REPO_DIR/.pack/skills"/*/; do
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
cp "$REPO_DIR/.pack/scripts/chroma_helper_stub.py" "$CORES_DIR/scripts/chroma_helper_stub.py" 2>/dev/null || curl -sL "https://raw.githubusercontent.com/EliasOulkadi/shokunin/master/.pack/scripts/chroma_helper_stub.py" -o "$CORES_DIR/scripts/chroma_helper_stub.py"
ok

# === LINUX SCRIPTS ===
step_msg "Installing Linux scripts..."
for script in run-opencode.sh memory-healthcheck.sh weekly-maintenance.sh profile.sh test-memory.sh scan-cleanup.sh; do
    SRC="$REPO_DIR/.pack/scripts/linux/$script"
    if [ -f "$SRC" ]; then
        cp "$SRC" "$CORES_DIR/scripts/linux/$script"
        chmod +x "$CORES_DIR/scripts/linux/$script"
    else
         curl -sL "https://raw.githubusercontent.com/EliasOulkadi/shokunin/master/.pack/scripts/linux/$script" -o "$CORES_DIR/scripts/linux/$script" 2>/dev/null
         for retry in 1 2 3; do
           curl -sL "https://raw.githubusercontent.com/EliasOulkadi/shokunin/master/.pack/scripts/linux/$script" -o "$CORES_DIR/scripts/linux/$script" 2>/dev/null && break
           sleep 1
         done
        chmod +x "$CORES_DIR/scripts/linux/$script" 2>/dev/null || true
    fi
done
log "Linux scripts installed"

# === OPENCODE CONFIG ===
step_msg "Configuring OpenCode..."
CONFIG_SRC="$REPO_DIR/.pack/opencode.json"

NVIDIA_KEY="${NVIDIA_API_KEY:-}"
if [ -z "$NVIDIA_KEY" ] && [ "$NONINTERACTIVE" = false ] && [ -t 0 ]; then
    echo ""
    echo "  Optional: NVIDIA API key for NVIDIA models"
    echo "  Leave empty to skip — OpenCode Go works without it."
    echo "  Get a key: https://build.nvidia.com/ (free signup)"
    echo ""
    read -r -p "  NVIDIA API Key (optional): " NVIDIA_KEY
fi

if [ -f "$CONFIG_SRC" ]; then
    PYTHON_BIN="python3"
    command -v python3 &>/dev/null || PYTHON_BIN="python"

    # Process template: substitute placeholders
    TEMPLATE_CONTENT=$(sed "s#{{MCP_ROOT_PATH}}#$HOME#g; \
         s#{{PYTHON_BIN}}#$PYTHON_BIN#g; \
         s#{{MCP_MEMORY_PATH}}#$CORES_DIR/memory/mcp-server.py#g" \
      "$CONFIG_SRC" 2>/dev/null)

    if grep -q "{{MCP_\|{{PYTHON_BIN}}" <<< "$TEMPLATE_CONTENT" 2>/dev/null; then
        log "WARNING: Placeholders remain in template. Check the file."
    fi

    if [ -f "$CONFIG_DIR/opencode.json" ]; then
        BACKUP_FILE="$CONFIG_DIR/opencode.json.shokunin-backup-$(date +%Y%m%d-%H%M%S)"
        cp "$CONFIG_DIR/opencode.json" "$BACKUP_FILE"
        log "Backup saved: $(basename $BACKUP_FILE)"

        $PYTHON_BIN -c "
import json, sys

with open('$CONFIG_DIR/opencode.json') as f:
    config = json.load(f)

shokunin_mcp = {
    'filesystem': {
        'type': 'local',
        'command': ['npx', '-y', '@modelcontextprotocol/server-filesystem', '$HOME']
    },
    'fetch': {
        'type': 'local',
        'command': ['$PYTHON_BIN', '-m', 'mcp_server_fetch'],
        'environment': {'PYTHONIOENCODING': 'utf-8'}
    },
    'memory': {
        'type': 'local',
        'command': ['$PYTHON_BIN', '$CORES_DIR/memory/mcp-server.py']
    }
}

existing_mcp = config.get('mcp', {})
added = 0
for name, server_cfg in shokunin_mcp.items():
    if name not in existing_mcp:
        config.setdefault('mcp', {})[name] = server_cfg
        added += 1

with open('$CONFIG_DIR/opencode.json', 'w') as f:
    json.dump(config, f, indent=2)
    f.write(chr(10))
if added > 0:
    print(f'ADDED_MCP: {added}')
else:
    print('ALL_MCP_EXIST')
" 2>&1 || {
        log "Merge failed, restoring backup." Yellow
        cp "$BACKUP_FILE" "$CONFIG_DIR/opencode.json" 2>/dev/null || true
    }
    else
        echo "$TEMPLATE_CONTENT" > "$CONFIG_DIR/opencode.json"
        log "Config created (new)"
    fi
fi

NVIDIA_PROFILE=""
if [ -f "$HOME/.zshrc" ]; then NVIDIA_PROFILE="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then NVIDIA_PROFILE="$HOME/.bashrc"
elif [ -f "$HOME/.bash_profile" ]; then NVIDIA_PROFILE="$HOME/.bash_profile"
elif [ -f "$HOME/.profile" ]; then NVIDIA_PROFILE="$HOME/.profile"
fi
if [ -n "$NVIDIA_KEY" ] && [ -n "$NVIDIA_PROFILE" ] && ! grep -q "NVIDIA_API_KEY" "$NVIDIA_PROFILE" 2>/dev/null; then
    printf 'export NVIDIA_API_KEY="%s"\n' "$NVIDIA_KEY" >> "$NVIDIA_PROFILE"
fi
log "Config generated"

# === INSTRUCTIONS ===
step_msg "Configuring global instructions..."
CLAUDE_SRC="$REPO_DIR/.pack/CLAUDE.md"
AGENTS_SRC="$REPO_DIR/.pack/AGENTS.md"

if [ -f "$CLAUDE_SRC" ]; then
    if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
        skip "CLAUDE.md already exists — not overwriting"
    else
        cp "$CLAUDE_SRC" "$CLAUDE_DIR/CLAUDE.md"
        ok "CLAUDE.md installed"
    fi
fi

if [ -f "$AGENTS_SRC" ]; then
    if [ -f "$HOME/AGENTS.md" ]; then
        skip "AGENTS.md already exists — not overwriting"
    else
        cp "$AGENTS_SRC" "$HOME/AGENTS.md"
        ok "AGENTS.md installed"
    fi
fi
log "Instructions configured"

# === PROFILE ===
step_msg "Configuring shell profile..."
PROFILE_FILE=""
if [ -f "$HOME/.zshrc" ]; then PROFILE_FILE="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then PROFILE_FILE="$HOME/.bashrc"
elif [ -f "$HOME/.bash_profile" ]; then PROFILE_FILE="$HOME/.bash_profile"
elif [ -f "$HOME/.profile" ]; then PROFILE_FILE="$HOME/.profile"
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
if command -v crontab &>/dev/null; then
  if crontab -l 2>/dev/null | grep -q "shokunin"; then
      log "Crontab already configured"
  else
      if [ -f "$HOME/.shokunin/scripts/linux/weekly-maintenance.sh" ]; then
          (crontab -l 2>/dev/null; echo "0 21 * * 0 \$HOME/.shokunin/scripts/linux/weekly-maintenance.sh") | crontab -
          log "Crontab added (Sunday 21:00)"
      else
          log "weekly-maintenance.sh not found — skipping crontab setup"
      fi
  fi
else
  log "crontab not available — weekly maintenance won't auto-schedule"
fi

# === VERIFICATION ===
step_msg "Verifying installation..."
if [ -f "$CORES_DIR/scripts/linux/memory-healthcheck.sh" ]; then
  bash "$CORES_DIR/scripts/linux/memory-healthcheck.sh" && ok || fail "Some checks failed"
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
echo "  3. Test memory: ~/.shokunin/scripts/linux/memory-healthcheck.sh"
echo ""
echo "  Repo: https://github.com/EliasOulkadi/shokunin"
echo "=========================================="
