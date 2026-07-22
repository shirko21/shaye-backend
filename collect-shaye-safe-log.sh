#!/usr/bin/env bash
set -u

REPO="/workspaces/shaye-backend"
RAW="$REPO/.shaye-run-raw.log"
SAFE="$REPO/SHAYE-SAFE-ERROR-LOG.txt"

cd "$REPO" || exit 1

git switch stage-9a-codespaces >/dev/null 2>&1 || true
git pull origin stage-9a-codespaces >/dev/null 2>&1 || true

: > "$RAW"
{
  echo "=== SHAYE FINAL RC2 RUN ==="
  echo "UTC: $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  echo "Branch: $(git branch --show-current 2>/dev/null)"
  echo
  bash run-shaye-final-rc2.sh
} >"$RAW" 2>&1
STATUS=$?

python3 - <<'PY'
from pathlib import Path
import re

raw = Path('/workspaces/shaye-backend/.shaye-run-raw.log')
safe = Path('/workspaces/shaye-backend/SHAYE-SAFE-ERROR-LOG.txt')
text = raw.read_text(errors='replace')
lines = text.splitlines()[-700:]
text = '\n'.join(lines)

patterns = [
    r'(?i)(password|passwd|secret|token|api[_-]?key|private[_-]?key|mnemonic|seed|jwt[_-]?secret|session[_-]?secret|encryption[_-]?key|database_url)\s*[:=]\s*[^\s]+',
    r'(?i)(postgres(?:ql)?://[^:\s]+:)[^@\s]+(@)',
    r'(?i)(authorization:\s*bearer\s+)[A-Za-z0-9._\-]+',
]
for p in patterns:
    if 'postgres' in p:
        text = re.sub(p, r'\1[REDACTED]\2', text)
    else:
        text = re.sub(p, lambda m: m.group(1) + '=[REDACTED]' if m.lastindex else '[REDACTED]', text)

safe.write_text(text + f'\n\nEXIT_STATUS={Path("/tmp/shaye_status").read_text().strip() if Path("/tmp/shaye_status").exists() else "unknown"}\n')
PY

printf '%s' "$STATUS" > /tmp/shaye_status
python3 - <<'PY'
from pathlib import Path
p = Path('/workspaces/shaye-backend/SHAYE-SAFE-ERROR-LOG.txt')
status = Path('/tmp/shaye_status').read_text().strip()
text = p.read_text()
text = re.sub(r'EXIT_STATUS=unknown', f'EXIT_STATUS={status}', text)
p.write_text(text)
PY

rm -f "$RAW" /tmp/shaye_status

git add SHAYE-SAFE-ERROR-LOG.txt
if ! git diff --cached --quiet; then
  git commit -m "Add sanitized SHAYE test error log" >/dev/null 2>&1 || true
fi
git push origin stage-9a-codespaces

echo
echo "✅ گزارش امن خطاها داخل GitHub فرستاده شد."
echo "نام فایل: SHAYE-SAFE-ERROR-LOG.txt"
exit 0
