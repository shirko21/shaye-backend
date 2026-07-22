#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="/workspaces/shaye-stage9a/SHAYE-STAGE-09A-CODESPACES"
COMPOSE="$ROOT/docker-compose.codespaces.yml"

if [ ! -f "$COMPOSE" ]; then
  echo "فایل docker-compose.codespaces.yml پیدا نشد."
  exit 1
fi

if [ -z "${CODESPACE_NAME:-}" ] || [ -z "${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:-}" ]; then
  echo "این اصلاح باید داخل GitHub Codespaces اجرا شود."
  exit 1
fi

ORIGIN="https://${CODESPACE_NAME}-5000.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"

python3 - <<'PY'
from pathlib import Path

path = Path('/workspaces/shaye-stage9a/SHAYE-STAGE-09A-CODESPACES/docker-compose.codespaces.yml')
text = path.read_text()
old = '      FRONTEND_URL: ${FRONTEND_URL:-http://localhost:5000}\n'
new = '      FRONTEND_URL: "http://localhost:5000,https://${CODESPACE_NAME}-5000.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"\n'
if new not in text:
    if old not in text:
        raise SystemExit('خط FRONTEND_URL مورد انتظار پیدا نشد')
    text = text.replace(old, new, 1)
path.write_text(text)
PY

cd "$ROOT"
docker compose -f docker-compose.codespaces.yml up -d --force-recreate app

for i in $(seq 1 40); do
  if curl -fsS http://127.0.0.1:5000/ready >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

HEADERS="$(mktemp)"
curl -sS -D "$HEADERS" -o /dev/null -X OPTIONS \
  -H "Origin: $ORIGIN" \
  -H 'Access-Control-Request-Method: POST' \
  -H 'Access-Control-Request-Headers: content-type' \
  http://127.0.0.1:5000/api/auth/login || true

if ! grep -qi "^Access-Control-Allow-Origin: ${ORIGIN}\r\?$" "$HEADERS"; then
  echo "هدر مجاز CORS دریافت نشد."
  cat "$HEADERS"
  exit 1
fi

rm -f "$HEADERS"
echo "✅ مبدا Codespaces مجاز شد و ورود/ثبت‌نام دوباره قابل استفاده است."
echo "$ORIGIN"
