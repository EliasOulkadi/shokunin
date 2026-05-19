#!/bin/bash
# Ensure required fonts for Kami PDF generation are installed
set -euo pipefail

FONTS=(
  "Charter"
  "TsangerJinKai02"
  "YuMincho"
)

for font in "${FONTS[@]}"; do
  if fc-list | grep -qi "$font"; then
    echo "✓ $font found"
  else
    echo "✗ $font missing — PDF may fall back to system fonts"
  fi
done
