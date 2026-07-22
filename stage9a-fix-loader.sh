#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="/workspaces/shaye-stage9a/SHAYE-STAGE-09A-CODESPACES"
INDEX="$ROOT/frontend/index.html"

if [ ! -f "$INDEX" ]; then
  echo "فایل index.html مرحله 9A پیدا نشد."
  exit 1
fi

python3 - <<'PY'
from pathlib import Path

path = Path('/workspaces/shaye-stage9a/SHAYE-STAGE-09A-CODESPACES/frontend/index.html')
text = path.read_text()
marker = 'data-stage9a-loader-fix="1"'
script = '''\n<script data-stage9a-loader-fix="1">\n(function () {\n  function hideLoader() {\n    var loader = document.getElementById('loader');\n    if (!loader) return;\n    loader.classList.add('hide');\n    window.setTimeout(function () {\n      if (loader && loader.parentNode) loader.parentNode.removeChild(loader);\n    }, 800);\n  }\n  if (document.readyState === 'complete') {\n    window.setTimeout(hideLoader, 250);\n  } else {\n    window.addEventListener('load', function () {\n      window.setTimeout(hideLoader, 250);\n    }, { once: true });\n  }\n  window.setTimeout(hideLoader, 2500);\n})();\n</script>\n'''

if marker not in text:
    if '</body>' not in text:
        raise SystemExit('تگ body پایانی پیدا نشد')
    text = text.replace('</body>', script + '\n</body>', 1)
    path.write_text(text)
PY

cd "$ROOT"
node --check frontend/assets/js/app.js

docker compose -f docker-compose.codespaces.yml up -d --build app

for i in $(seq 1 40); do
  if curl -fsS http://127.0.0.1:5000/ready >/dev/null 2>&1; then
    echo "✅ صفحه ورود اصلاح شد و سرویس آماده است."
    exit 0
  fi
  sleep 2
done

echo "سرویس بازسازی شد اما پاسخ آماده‌بودن دریافت نشد."
docker compose -f docker-compose.codespaces.yml ps
exit 1
