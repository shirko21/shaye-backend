#!/usr/bin/env bash
set -Eeuo pipefail

REPO="/workspaces/shaye-backend"
OLD_APP="/workspaces/shaye-stage9a/SHAYE-STAGE-09A-CODESPACES"
DEST="/workspaces/shaye-final-rc2"
ZIP_PATH="/workspaces/SHAYE-FINAL-RC2.zip"
APP="$DEST/SHAYE-FINAL-RC2"
API="$APP/backend/shaye-api"

fail() {
  echo "❌ $*" >&2
  exit 1
}

[ -d "$REPO/.git" ] || fail "مخزن shaye-backend در Codespaces پیدا نشد."
command -v unzip >/dev/null 2>&1 || fail "دستور unzip پیدا نشد."
command -v docker >/dev/null 2>&1 || fail "Docker در Codespaces فعال نیست."
command -v node >/dev/null 2>&1 || fail "Node.js در Codespaces پیدا نشد."
command -v npm >/dev/null 2>&1 || fail "npm در Codespaces پیدا نشد."

[ -n "${CODESPACE_NAME:-}" ] || fail "نام Codespace پیدا نشد."
[ -n "${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:-}" ] || fail "دامنه Codespaces پیدا نشد."

cd "$REPO"
echo "[1/7] دریافت فایل نهایی از شاخه main"
git fetch origin main stage-9a-codespaces
if ! git cat-file -e origin/main:SHAYE-FINAL-RC2.zip 2>/dev/null; then
  fail "فایل SHAYE-FINAL-RC2.zip در شاخه main پیدا نشد."
fi
git show origin/main:SHAYE-FINAL-RC2.zip > "$ZIP_PATH"

if [ -f "$OLD_APP/docker-compose.codespaces.yml" ]; then
  echo "[2/7] توقف نسخه قبلی بدون حذف دیتابیس قبلی"
  docker compose -f "$OLD_APP/docker-compose.codespaces.yml" down || true
else
  echo "[2/7] نسخه قبلی در حال اجرا پیدا نشد"
fi

if [ -f "$APP/docker-compose.codespaces.yml" ]; then
  docker compose -f "$APP/docker-compose.codespaces.yml" down || true
fi

rm -rf "$DEST"
mkdir -p "$DEST"
echo "[3/7] استخراج نسخه نهایی"
unzip -q "$ZIP_PATH" -d "$DEST"
[ -f "$APP/docker-compose.codespaces.yml" ] || fail "ساختار فایل ZIP درست نیست."
[ -f "$API/package.json" ] || fail "فایل package.json بک‌اند پیدا نشد."
chmod +x "$APP"/scripts/*.sh

export FRONTEND_URL="http://localhost:5000,https://${CODESPACE_NAME}-5000.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"

echo "[4/7] آماده‌سازی ابزارهای بررسی TypeScript و CSS"
cd "$API"
npm ci --no-audit --no-fund
npm install --no-save --no-package-lock postcss@8
ln -sfn "$API/node_modules" "$APP/node_modules"

echo "[5/7] بررسی کامل فایل نهایی"
cd "$APP"
bash scripts/validate-final-release.sh

echo "[6/7] نصب و اجرای نسخه نهایی در Codespaces"
bash scripts/codespaces-stage9a.sh

echo "[7/7] تست عملی ورود، API، گردونه و پشتیبانی"
bash scripts/codespaces-final-smoke.sh

URL="https://${CODESPACE_NAME}-5000.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"
echo
echo "✅ SHAYE-FINAL-RC2 با موفقیت نصب و تست شد."
echo "آدرس سایت: $URL"
echo "حساب آزمایشی مدیر: admin-stage9a@example.com"
echo "رمز آزمایشی مدیر: Stage9A-Test-Only-Change-Me"
echo "نسخه قبلی و دیتابیس قبلی حذف نشده‌اند."
