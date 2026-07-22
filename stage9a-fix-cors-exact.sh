#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="/workspaces/shaye-stage9a/SHAYE-STAGE-09A-CODESPACES"
COMPOSE="$ROOT/docker-compose.codespaces.yml"
ORIGIN="https://supreme-space-goldfish-qrrpqqq74jrh65xv-5000.app.github.dev"

if [ ! -f "$COMPOSE" ]; then
  echo "فایل اجرای مرحله 9A پیدا نشد."
  exit 1
fi

python3 - <<'PY'
from pathlib import Path
import re

path = Path('/workspaces/shaye-stage9a/SHAYE-STAGE-09A-CODESPACES/docker-compose.codespaces.yml')
text = path.read_text()
exact = '      FRONTEND_URL: "http://localhost:5000,https://supreme-space-goldfish-qrrpqqq74jrh65xv-5000.app.github.dev"'
text, count = re.subn(r'^\s{6}FRONTEND_URL:.*$', exact, text, count=1, flags=re.M)
if count != 1:
    raise SystemExit('خط FRONTEND_URL پیدا نشد')
path.write_text(text)
PY

cd "$ROOT"
docker compose -f docker-compose.codespaces.yml up -d --force-recreate app

for i in $(seq 1 45); do
  if curl -fsS http://127.0.0.1:5000/ready >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

ACTUAL="$(docker compose -f docker-compose.codespaces.yml exec -T app printenv FRONTEND_URL | tr -d '\r')"
EXPECTED="http://localhost:5000,$ORIGIN"

if [ "$ACTUAL" != "$EXPECTED" ]; then
  echo "تنظیم داخل Backend درست اعمال نشده است."
  echo "مقدار فعلی: $ACTUAL"
  echo "مقدار لازم: $EXPECTED"
  exit 1
fi

BODY="$(mktemp)"
STATUS="$(curl -sS -o "$BODY" -w '%{http_code}' \
  -H "Origin: $ORIGIN" \
  -H 'Content-Type: application/json' \
  -d '{"email":"cors-check-stage9a@example.com","password":"wrong-password"}' \
  http://127.0.0.1:5000/api/auth/login || true)"

if grep -q 'مبدأ درخواست مجاز نیست' "$BODY"; then
  echo "Backend هنوز مبدا را رد می‌کند."
  cat "$BODY"
  exit 1
fi

if [ "$STATUS" != "400" ] && [ "$STATUS" != "401" ] && [ "$STATUS" != "429" ]; then
  echo "پاسخ ورود غیرمنتظره بود: HTTP $STATUS"
  cat "$BODY"
  exit 1
fi

rm -f "$BODY"
echo "✅ آدرس دقیق فعلی سایت داخل Backend ثبت و آزمایش شد."
echo "$ORIGIN"
