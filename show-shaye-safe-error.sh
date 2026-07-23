#!/usr/bin/env bash
set +e

REPO="/workspaces/shaye-backend"
RAW="/tmp/shaye-show-error-raw.log"
SAFE="/tmp/shaye-show-error-safe.log"

cd "$REPO" || { echo "❌ پوشه مخزن پیدا نشد."; exit 1; }

{
  echo "=== SHAYE SAFE ERROR REPORT ==="
  echo "UTC: $(date -u '+%Y-%m-%d %H:%M:%S')"
  echo "Branch: $(git branch --show-current 2>/dev/null)"
  echo "Commit: $(git rev-parse --short HEAD 2>/dev/null)"
  echo "---"

  git fetch origin stage-9a-codespaces
  FETCH_STATUS=$?
  echo "git fetch status: $FETCH_STATUS"

  if [ "$FETCH_STATUS" -eq 0 ]; then
    git checkout origin/stage-9a-codespaces -- run-shaye-final-rc2.sh
    CHECKOUT_STATUS=$?
    echo "runner checkout status: $CHECKOUT_STATUS"

    if [ "$CHECKOUT_STATUS" -eq 0 ] && [ -f run-shaye-final-rc2.sh ]; then
      bash run-shaye-final-rc2.sh
      echo "runner exit status: $?"
    fi
  fi
} >"$RAW" 2>&1

python3 - "$RAW" "$SAFE" <<'PY'
from pathlib import Path
import re, sys
text = Path(sys.argv[1]).read_text(errors='replace')
patterns = [
    (r'(?im)^\s*(JWT_SECRET|PRIVATE_KEY|MNEMONIC|SEED_PHRASE|POSTGRES_PASSWORD|DATABASE_PASSWORD|API_KEY|SECRET_KEY|ACCESS_TOKEN|REFRESH_TOKEN)\s*=.*$', r'\1=[REDACTED]'),
    (r'(?i)(authorization:\s*bearer\s+)[A-Za-z0-9._~+/=-]+', r'\1[REDACTED]'),
    (r'(?i)(postgres(?:ql)?://[^:\s/@]+:)[^@\s]+(@)', r'\1[REDACTED]\2'),
    (r'gh[pousr]_[A-Za-z0-9_]{20,}', '[REDACTED_GITHUB_TOKEN]'),
    (r'(?i)(cookie:\s*).+', r'\1[REDACTED]'),
]
for pattern, repl in patterns:
    text = re.sub(pattern, repl, text)
Path(sys.argv[2]).write_text(text)
PY

echo
echo "آخرین خطوط خطا:"
echo "----------------------------------------"
tail -n 120 "$SAFE"
echo "----------------------------------------"
echo "✅ از بخش بالا عکس بگیر و ارسال کن."

rm -f "$RAW" "$SAFE"
exit 0
