#!/usr/bin/env bash
set -Eeuo pipefail

REPO="/workspaces/shaye-backend"
DEST="/workspaces/shaye-clean-v1"

fail(){ echo "❌ $*" >&2; exit 1; }

cd "$REPO" || fail "مخزن shaye-backend پیدا نشد."
git switch main >/dev/null 2>&1 || true
git pull origin main
command -v unzip >/dev/null 2>&1 || fail "unzip پیدا نشد."

ZIP=""
for candidate in \
  "SHAYE-CLEAN-CODESPACES-v1.zip" \
  "SHAYE-FINAL-RC2.zip" \
  "✅ SHAYE-FINAL-RC2.zip"; do
  if [ -f "$candidate" ]; then
    ZIP="$candidate"
    break
  fi
done

if [ -z "$ZIP" ]; then
  ZIP="$(find . -maxdepth 1 -type f \( -iname '*SHAYE*FINAL*RC2*.zip' -o -iname '*SHAYE*CLEAN*.zip' \) -printf '%f\n' | head -n 1)"
fi

[ -n "$ZIP" ] && [ -f "$ZIP" ] || fail "فایل ZIP پروژه در شاخه main پیدا نشد."
echo "✅ فایل پیدا شد: $ZIP"

rm -rf "$DEST"
mkdir -p "$DEST"
unzip -q "$ZIP" -d "$DEST"

START="$(find "$DEST" -maxdepth 5 -type f -name 'START-CODESPACES.sh' -print -quit)"
[ -n "$START" ] || fail "داخل ZIP فایل START-CODESPACES.sh پیدا نشد؛ احتمالاً فایل اشتباه آپلود شده است."
APP="$(dirname "$START")"
chmod +x "$START"
find "$APP/scripts" -maxdepth 1 -type f -name '*.sh' -exec chmod +x {} + 2>/dev/null || true

cd "$APP"
bash "$START"
