#!/bin/bash
# Package Kami skill for distribution
set -euo pipefail

VERSION="${1:-$(grep 'version:' SKILL.md | head -1 | awk '{print $2}' | tr -d '"')}"
OUTPUT="kami-skill-v${VERSION}.tar.gz"

tar czf "$OUTPUT" \
  SKILL.md \
  references/ \
  scripts/ \
  assets/ \
  CHEATSHEET.md

echo "Packaged: $OUTPUT"
