#!/usr/bin/env bash
set -u

REPO="/workspaces/shaye-backend"
RAW="/tmp/shaye-main-run-raw.log"
SAFE="$REPO/SHAYE-SAFE-ERROR-LOG.txt"

cd "$REPO" || exit 1

git switch main >/dev/null 2>&1 || true
git pull origin main >/dev/null 2>&1 || true

{
  echo "SHAYE safe run log"
  echo "UTC: $(date -u '+%Y-%m-%d %H:%M:%S')"
  echo "Branch: $(git branch --show-current 2>/dev/null || true)"
  echo "Commit: $(git rev-parse --short HEAD 2>/dev/null || true)"
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
      RUN_STATUS=$?
      echo "runner exit status: $RUN_STATUS"
    fi
  fi
} >"$RAW" 2>&1

python3 - "$RAW" "$SAFE" <<'PY'
from pathlib import Path
import re, sys
src = Path(sys.argv[1]).read_text(errors='replace')
patterns = [
    (r'(?im)^\s*(JWT_SECRET|PRIVATE_KEY|MNEMONIC|SEED_PHRASE|POSTGRES_PASSWORD|DATABASE_PASSWORD|API_KEY|SECRET_KEY|ACCESS_TOKEN|REFRESH_TOKEN)\s*=.*$', r'\1=[REDACTED]'),
    (r'(?i)(authorization:\s*bearer\s+)[A-Za-z0-9._~+/=-]+', r'\1[REDACTED]'),
    (r'(?i)(postgres(?:ql)?://[^:\s/@]+:)[^@\s]+(@)', r'\1[REDACTED]\2'),
    (r'(?i)(https://[^:\s/@]+:)[^@\s]+(@)', r'\1[REDACTED]\2'),
    (r'gh[pousr]_[A-Za-z0-9_]{20,}', '[REDACTED_GITHUB_TOKEN]'),
    (r'(?i)(cookie:\s*).+', r'\1[REDACTED]'),
]
for pattern, repl in patterns:
    src = re.sub(pattern, repl, src)
Path(sys.argv[2]).write_text(src)
PY

rm -f "$RAW"

git add SHAYE-SAFE-ERROR-LOG.txt run-shaye-final-rc2.sh 2>/dev/null || true
if ! git diff --cached --quiet; then
  git -c user.name="SHAYE Error Collector" -c user.email="shaye-error@users.noreply.github.com" commit -m "Add latest sanitized SHAYE error log" >/dev/null 2>&1 || true
  git push origin main
fi

echo "✅ گزارش امن خطا داخل SHAYE-SAFE-ERROR-LOG.txt در شاخه main ذخیره شد."
