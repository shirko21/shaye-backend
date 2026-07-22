#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="/workspaces/shaye-final-rc2/SHAYE-FINAL-RC2"
COMPOSE="$ROOT/docker-compose.codespaces.yml"
ORIGIN="https://${CODESPACE_NAME}-5000.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"

[ -f "$COMPOSE" ] || { echo "❌ فایل اجرای نسخه نهایی پیدا نشد."; exit 1; }

cd "$ROOT"
export FRONTEND_URL="http://localhost:5000,$ORIGIN"

echo "[1/3] بررسی وضعیت سرویس"
docker compose -f docker-compose.codespaces.yml ps || true

if ! curl -fsS http://127.0.0.1:5000/ready >/dev/null 2>&1; then
  echo "[2/3] سرویس در دسترس نیست؛ راه‌اندازی دوباره"
  docker compose -f docker-compose.codespaces.yml up -d --force-recreate app
else
  echo "[2/3] سرویس در حال اجراست"
fi

for i in $(seq 1 60); do
  if curl -fsS http://127.0.0.1:5000/ready >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

if ! curl -fsS http://127.0.0.1:5000/ready >/dev/null 2>&1; then
  echo "❌ سرویس هنوز بالا نیامده است."
  docker compose -f docker-compose.codespaces.yml logs --tail=120 app
  exit 1
fi

if ! curl -fsS http://127.0.0.1:5000/ >/dev/null 2>&1; then
  echo "❌ صفحه اصلی از داخل Codespaces باز نمی‌شود."
  docker compose -f docker-compose.codespaces.yml logs --tail=120 app
  exit 1
fi

echo "[3/3] لینک فعلی Codespace"
echo "✅ سایت فعال است."
echo "$ORIGIN/?authfix=2"
