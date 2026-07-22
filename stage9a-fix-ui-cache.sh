#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="/workspaces/shaye-stage9a/SHAYE-STAGE-09A-CODESPACES"
FRONTEND="$ROOT/frontend"
BACKEND="$ROOT/backend/shaye-api"
COMPOSE="$ROOT/docker-compose.codespaces.yml"
STAMP="20260722rc3"

for required in \
  "$FRONTEND/assets/js/lucky-wheel.js" \
  "$FRONTEND/assets/js/stage9a-ui-bridge.js" \
  "$FRONTEND/assets/css/lucky-wheel.css" \
  "$FRONTEND/assets/css/stage9a-ui.css" \
  "$BACKEND/src/app.ts" \
  "$COMPOSE"; do
  if [ ! -f "$required" ]; then
    echo "فایل لازم پیدا نشد: $required"
    echo "ابتدا اصلاح RC2 باید با موفقیت اجرا شده باشد."
    exit 1
  fi
done

python3 - <<'PY'
from pathlib import Path
import re

root = Path('/workspaces/shaye-stage9a/SHAYE-STAGE-09A-CODESPACES')
frontend = root / 'frontend'
app = root / 'backend/shaye-api/src/app.ts'
stamp = '20260722rc3'

# در محیط آزمایشی Codespaces کش همه فایل‌های ظاهری غیرفعال می‌شود.
text = app.read_text()
old = '''    express.static(frontendPath, {
      extensions: ["html"],
      maxAge: env.NODE_ENV === "production" ? "1h" : 0,
      setHeaders(res, filePath) {
        if (filePath.endsWith(".html")) {
          res.setHeader("Cache-Control", "no-cache");
        }
      },
    }),'''
new = '''    express.static(frontendPath, {
      extensions: ["html"],
      maxAge:
        process.env.STAGE9A_TEST_MODE === "true"
          ? 0
          : env.NODE_ENV === "production"
            ? "1h"
            : 0,
      setHeaders(res, filePath) {
        if (process.env.STAGE9A_TEST_MODE === "true") {
          res.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
          res.setHeader("Pragma", "no-cache");
          res.setHeader("Expires", "0");
        } else if (filePath.endsWith(".html")) {
          res.setHeader("Cache-Control", "no-cache");
        }
      },
    }),'''
if old in text:
    text = text.replace(old, new, 1)
elif 'process.env.STAGE9A_TEST_MODE === "true"' not in text:
    raise SystemExit('بخش کش فایل‌های استاتیک در app.ts پیدا نشد')
app.write_text(text)

# شماره نسخه فایل‌های اصلاحی عوض می‌شود تا مرورگر نسخه قدیمی را استفاده نکند.
for path in frontend.glob('*.html'):
    html = path.read_text()
    html = re.sub(r'assets/css/lucky-wheel\.css(?:\?v=[^"\']+)?', f'assets/css/lucky-wheel.css?v={stamp}', html)
    html = re.sub(r'assets/css/stage9a-ui\.css(?:\?v=[^"\']+)?', f'assets/css/stage9a-ui.css?v={stamp}', html)
    html = re.sub(r'assets/js/lucky-wheel\.js(?:\?v=[^"\']+)?', f'assets/js/lucky-wheel.js?v={stamp}', html)
    html = re.sub(r'assets/js/stage9a-ui-bridge\.js(?:\?v=[^"\']+)?', f'assets/js/stage9a-ui-bridge.js?v={stamp}', html)
    path.write_text(html)
PY

cd "$BACKEND"
npm run typecheck
npm run build

cd "$ROOT"
docker compose -f docker-compose.codespaces.yml build --no-cache app
docker compose -f docker-compose.codespaces.yml up -d --force-recreate app

for i in $(seq 1 45); do
  if curl -fsS http://127.0.0.1:5000/ready >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

DASH="$(mktemp)"
HEADERS="$(mktemp)"
curl -fsS -D "$HEADERS" http://127.0.0.1:5000/dashboard.html -o "$DASH"

grep -q "lucky-wheel.js?v=$STAMP" "$DASH"
grep -q "stage9a-ui-bridge.js?v=$STAMP" "$DASH"
curl -fsS "http://127.0.0.1:5000/assets/js/lucky-wheel.js?v=$STAMP" | grep -q "shaye-wheel-fab"
curl -fsS "http://127.0.0.1:5000/assets/js/stage9a-ui-bridge.js?v=$STAMP" | grep -q "wallet-action-btn.deposit"

if ! grep -qi '^Cache-Control: no-store, no-cache, must-revalidate' "$HEADERS"; then
  echo "هشدار: هدر ضدکش مورد انتظار دیده نشد."
  cat "$HEADERS"
  exit 1
fi

rm -f "$DASH" "$HEADERS"
echo "✅ نسخه تازه رابط کاربری بدون کش فعال شد؛ گردونه و دکمه‌ها از فایل‌های جدید بارگذاری می‌شوند."
