#!/usr/bin/env bash
set -euo pipefail

CORES_DIR="$HOME/.shokunin"
BACKUP_DIR="$CORES_DIR/backups"
MEMORY_DIR="$CORES_DIR/memory"
DATE_STAMP=$(date +%Y-%m-%d)

mkdir -p "$BACKUP_DIR"

# Backup ChromaDB
echo "Backing up memory..."
tar -czf "$BACKUP_DIR/memory-$DATE_STAMP.tar.gz" -C "$CORES_DIR" memory/ 2>/dev/null || \
    zip -r "$BACKUP_DIR/memory-$DATE_STAMP.zip" "$MEMORY_DIR" 2>/dev/null || true

# Clean old backups (keep last 4 weeks)
find "$BACKUP_DIR" -name "memory-*.tar.gz" -mtime +28 -delete 2>/dev/null || true
find "$BACKUP_DIR" -name "memory-*.zip" -mtime +28 -delete 2>/dev/null || true

# Clean temp logs older than 30 days
find "$MEMORY_DIR/sessions" -name "*.log" -mtime +30 -delete 2>/dev/null || true

# Disk space
DISK=$(df -h "$HOME" | awk 'NR==2{print $4}')
echo "Disk available: $DISK"
echo "Maintenance complete: $(date)"
