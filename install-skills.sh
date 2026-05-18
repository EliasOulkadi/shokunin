#!/usr/bin/env bash
# Shokunin Skills-Only Installer v4.2.2
# Installs only the 62 skills without the full ecosystem
# Run: bash <(curl -sSL https://raw.githubusercontent.com/EliasOulkadi/shokunin/master/install-skills.sh)

set -euo pipefail

SKILLS_DIR="$HOME/.config/opencode/skills"
VERSION="4.2.2"

echo ""
echo "  Shokunin Skills Installer v$VERSION"
echo "  62 skills across 10 domains"
echo ""

mkdir -p "$SKILLS_DIR"

REPO_DIR="/tmp/shokunin-skills"
rm -rf "$REPO_DIR"

for retry in 1 2 3; do
    git clone --depth 1 https://github.com/EliasOulkadi/shokunin.git "$REPO_DIR" 2>/dev/null && break
    sleep 1
done

if [ ! -d "$REPO_DIR" ]; then
    echo "  FAIL: Could not clone repository. Check network connectivity."
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

rm -rf "$REPO_DIR"
echo "  $COUNT skills installed to $SKILLS_DIR"
echo ""
