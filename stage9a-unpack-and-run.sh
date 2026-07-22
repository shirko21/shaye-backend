#!/usr/bin/env bash
set -Eeuo pipefail

WORKSPACE_ROOT="/workspaces"
ZIP_NAME="SHAYE-STAGE-09A-CODESPACES.zip"
ZIP_PATH="$(find "$WORKSPACE_ROOT" -maxdepth 4 -type f -name "$ZIP_NAME" -print -quit 2>/dev/null || true)"

if [ -z "$ZIP_PATH" ]; then
  echo "فایل $ZIP_NAME پیدا نشد. ابتدا ZIP را داخل Codespaces آپلود کنید."
  exit 1
fi

TARGET="$WORKSPACE_ROOT/shaye-stage9a"
rm -rf "$TARGET"
mkdir -p "$TARGET"
unzip -q "$ZIP_PATH" -d "$TARGET"
PROJECT="$TARGET/SHAYE-STAGE-09A-CODESPACES"

if [ ! -f "$PROJECT/scripts/codespaces-stage9a.sh" ]; then
  echo "ساختار ZIP درست نیست."
  exit 1
fi

cd "$PROJECT"
chmod +x scripts/*.sh
bash scripts/codespaces-stage9a.sh
