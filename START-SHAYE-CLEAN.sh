#!/usr/bin/env bash
set -Eeuo pipefail

REPO="/workspaces/shaye-backend"
ZIP_NAME="SHAYE-CLEAN-CODESPACES-v1.zip"
DEST="/workspaces/shaye-clean-v1"
APP="$DEST/SHAYE-CLEAN-CODESPACES-v1"

fail(){ echo "❌ $*" >&2; exit 1; }

cd "$REPO" || fail "مخزن shaye-backend پیدا نشد."
git switch main >/dev/null 2>&1 || true
git pull origin main

[ -f "$ZIP_NAME" ] || fail "فایل $ZIP_NAME داخل شاخه main پیدا نشد."
command -v unzip >/dev/null 2>&1 || fail "unzip پیدا نشد."

rm -rf "$DEST"
mkdir -p "$DEST"
unzip -q "$ZIP_NAME" -d "$DEST"
[ -f "$APP/START-CODESPACES.sh" ] || fail "ساختار فایل ZIP درست نیست."
chmod +x "$APP/START-CODESPACES.sh" "$APP"/scripts/*.sh

cd "$APP"
bash START-CODESPACES.sh
