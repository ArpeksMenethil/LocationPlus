#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SRC_DIR")"
BACKUP_DIR="$PARENT_DIR/backup"

VERSION="$(sed -n 's/^## Version:[[:space:]]*//p' "$SRC_DIR/LocationPlus.toc" | head -1)"
VERSION="${VERSION:-$(date +%Y%m%d)}"
ZIP_NAME="LocationPlus-v${VERSION}.zip"

mkdir -p "$BACKUP_DIR"
rm -f "$BACKUP_DIR/$ZIP_NAME"

(cd "$PARENT_DIR" && zip -r "$BACKUP_DIR/$ZIP_NAME" LocationPlus \
  -x "*/.*" \
  -x "LocationPlus/lps_types.lua" \
  -x "LocationPlus/zip.sh")

echo "Created: $BACKUP_DIR/$ZIP_NAME"

