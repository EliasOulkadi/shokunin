#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="$HOME/.shokunin/logs"
LIMIT_DAYS=7

mkdir -p "$LOG_DIR"

log() {
    local entry="$(date -Iseconds) | $1"
    echo "$entry" >> "$LOG_DIR/cleanup.log"
}

clean_temp() {
    local count=0
    local bytes=0
    while IFS= read -r -d '' file; do
        size=$(stat -c%s "$file" 2>/dev/null || echo 0)
        rm -f "$file" 2>/dev/null || true
        count=$((count + 1))
        bytes=$((bytes + size))
    done < <(find /tmp -type f -mtime +$LIMIT_DAYS -print0 2>/dev/null)
    echo "$count|$bytes"
}

clean_pdfs() {
    local dir="$1"
    local count=0
    local bytes=0
    if [ -d "$dir" ]; then
        while IFS= read -r -d '' file; do
            size=$(stat -c%s "$file" 2>/dev/null || echo 0)
            if command -v gio &>/dev/null; then
                gio trash "$file" 2>/dev/null || rm -f "$file" 2>/dev/null || true
            elif command -v trash-put &>/dev/null; then
                trash-put "$file" 2>/dev/null || rm -f "$file" 2>/dev/null || true
            else
                rm -f "$file" 2>/dev/null || true
            fi
            count=$((count + 1))
            bytes=$((bytes + size))
        done < <(find "$dir" -maxdepth 1 -name "Shokunin-*.pdf" -mtime +1 -print0 2>/dev/null)
    fi
    echo "$count|$bytes"
}

echo "Escaneando..."

temp_result=$(clean_temp)
temp_count=$(echo "$temp_result" | cut -d'|' -f1)
temp_bytes=$(echo "$temp_result" | cut -d'|' -f2)
temp_mb=$((temp_bytes / 1048576))
echo "  TEMP: $temp_count archivos ($temp_mb MB)"
log "TEMP: $temp_count files, $temp_mb MB"

pdf_result=$(clean_pdfs "$HOME/Desktop")
pdf_count=$(echo "$pdf_result" | cut -d'|' -f1)
pdf_bytes=$(echo "$pdf_result" | cut -d'|' -f2)
pdf_mb=$((pdf_bytes / 1048576))
echo "  PDFs: $pdf_count archivos ($pdf_mb MB)"
log "PDFs: $pdf_count files, $pdf_mb MB"

docs_result=$(clean_pdfs "$HOME/.shokunin/docs")
docs_count=$(echo "$docs_result" | cut -d'|' -f1)
docs_bytes=$(echo "$docs_result" | cut -d'|' -f2)
docs_mb=$((docs_bytes / 1048576))
echo "  DOCS: $docs_count archivos ($docs_mb MB)"
log "DOCS: $docs_count files, $docs_mb MB"

total=$((temp_count + pdf_count + docs_count))
total_mb=$(( (temp_bytes + pdf_bytes + docs_bytes) / 1048576 ))
echo "Hecho: $total archivos limpiados ($total_mb MB)"
log "TOTAL: $total files, $total_mb MB"
