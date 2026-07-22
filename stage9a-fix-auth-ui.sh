#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="/workspaces/shaye-stage9a/SHAYE-STAGE-09A-CODESPACES"
INDEX="$ROOT/frontend/index.html"
FIX_JS="$ROOT/frontend/assets/js/stage9a-auth-fix.js"

if [ ! -f "$INDEX" ]; then
  echo "فایل صفحه ورود مرحله 9A پیدا نشد."
  exit 1
fi

cat > "$FIX_JS" <<'JS'
(function () {
  'use strict';

  function byId(id) {
    return document.getElementById(id);
  }

  function message(text, type) {
    var box = byId('message');
    if (!box) return;
    box.textContent = text || '';
    box.className = type || '';
  }

  function activate(name) {
    var login = byId('loginForm');
    var register = byId('registerForm');
    var loginTab = byId('stage9aLoginTab');
    var registerTab = byId('stage9aRegisterTab');
    if (!login || !register) return;

    var isRegister = name === 'register';
    login.classList.toggle('active', !isRegister);
    register.classList.toggle('active', isRegister);
    if (loginTab) loginTab.classList.toggle('active', !isRegister);
    if (registerTab) registerTab.classList.toggle('active', isRegister);
    message('', '');
  }

  async function submitLogin(event) {
    event.preventDefault();
    var email = (byId('loginEmail').value || '').trim().toLowerCase();
    var password = byId('loginPassword').value || '';

    if (!email || !password) {
      message('ایمیل و رمز عبور را وارد کنید.', 'error');
      return;
    }
    if (!window.ShayeAPI || !window.ShayeAPI.auth) {
      message('فایل ارتباط با سرور بارگذاری نشده است.', 'error');
      return;
    }

    try {
      message('در حال ورود...', '');
      await window.ShayeAPI.auth.login({ email: email, password: password });
      message('ورود موفق بود.', 'success');
      window.setTimeout(function () { window.location.href = 'dashboard.html'; }, 300);
    } catch (error) {
      message(error && error.message ? error.message : 'ورود انجام نشد.', 'error');
    }
  }

  async function submitRegister(event) {
    event.preventDefault();
    var email = (byId('registerEmail').value || '').trim().toLowerCase();
    var password = byId('registerPassword').value || '';
    var confirmPassword = byId('confirmPassword').value || '';
    var inviteCode = (byId('inviteCode').value || '').trim();

    if (!email || !password || !confirmPassword) {
      message('ایمیل، رمز عبور و تکرار رمز را کامل کنید.', 'error');
      return;
    }
    if (password !== confirmPassword) {
      message('رمز عبور و تکرار آن یکسان نیست.', 'error');
      return;
    }
    if (!window.ShayeAPI || !window.ShayeAPI.auth) {
      message('فایل ارتباط با سرور بارگذاری نشده است.', 'error');
      return;
    }

    try {
      message('در حال ساخت حساب...', '');
      await window.ShayeAPI.auth.register({
        email: email,
        password: password,
        inviteCode: inviteCode || null
      });
      message('ثبت‌نام موفق بود.', 'success');
      window.setTimeout(function () { window.location.href = 'dashboard.html'; }, 300);
    } catch (error) {
      message(error && error.message ? error.message : 'ثبت‌نام انجام نشد.', 'error');
    }
  }

  function boot() {
    var loginTab = byId('stage9aLoginTab');
    var registerTab = byId('stage9aRegisterTab');
    var loginForm = byId('loginForm');
    var registerForm = byId('registerForm');

    if (loginTab) loginTab.addEventListener('click', function (event) {
      event.preventDefault();
      activate('login');
    });
    if (registerTab) registerTab.addEventListener('click', function (event) {
      event.preventDefault();
      activate('register');
    });
    if (loginForm) loginForm.addEventListener('submit', submitLogin, true);
    if (registerForm) registerForm.addEventListener('submit', submitRegister, true);

    var invite = new URLSearchParams(window.location.search).get('invite');
    if (invite && byId('inviteCode')) {
      byId('inviteCode').value = invite;
      activate('register');
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', boot, { once: true });
  } else {
    boot();
  }
})();
JS

python3 - <<'PY'
from pathlib import Path

path = Path('/workspaces/shaye-stage9a/SHAYE-STAGE-09A-CODESPACES/frontend/index.html')
text = path.read_text()

text = text.replace(
    '<button \nclass="tab active"\nonclick="showLogin()">',
    '<button id="stage9aLoginTab" type="button"\nclass="tab active">',
    1,
)
text = text.replace(
    '<button \nclass="tab"\nonclick="showRegister()">',
    '<button id="stage9aRegisterTab" type="button"\nclass="tab">',
    1,
)

marker = 'assets/js/stage9a-auth-fix.js?v=1'
if marker not in text:
    anchor = '<script src="assets/js/app.js"></script>'
    if anchor not in text:
        raise SystemExit('محل فایل app.js پیدا نشد')
    text = text.replace(anchor, anchor + '\n<script src="assets/js/stage9a-auth-fix.js?v=1"></script>', 1)

style_marker = 'data-stage9a-auth-style="1"'
if style_marker not in text:
    style = '''\n<style data-stage9a-auth-style="1">\n#message{min-height:24px;margin-bottom:12px;text-align:center;line-height:1.8}\n#message.error{color:#ff6b6b}\n#message.success{color:#2ad382}\n.stage9a-direct-links{display:flex;justify-content:space-between;gap:10px;margin-top:16px;font-size:13px}\n.stage9a-direct-links a{color:#10d065;text-decoration:none}\n</style>\n'''
    text = text.replace('</head>', style + '</head>', 1)

links_marker = 'data-stage9a-direct-links="1"'
if links_marker not in text:
    links = '''\n<div class="stage9a-direct-links" data-stage9a-direct-links="1">\n<a href="login.html">صفحه جداگانه ورود</a>\n<a href="register.html">صفحه جداگانه ثبت‌نام</a>\n</div>\n'''
    text = text.replace('</div>\n\n\n\n\n<div class="footer">', links + '\n</div>\n\n\n\n\n<div class="footer">', 1)

path.write_text(text)
PY

node --check "$FIX_JS"
cd "$ROOT"
docker compose -f docker-compose.codespaces.yml build --no-cache app
docker compose -f docker-compose.codespaces.yml up -d app

for i in $(seq 1 45); do
  if curl -fsS http://127.0.0.1:5000/ready >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

curl -fsS http://127.0.0.1:5000/assets/js/stage9a-auth-fix.js | grep -q "submitRegister"
STATUS="$(curl -sS -o /tmp/stage9a-auth-check.json -w '%{http_code}' \
  -H 'Content-Type: application/json' \
  -d '{"email":"not-a-user-stage9a@example.com","password":"wrong-password"}' \
  http://127.0.0.1:5000/api/auth/login || true)"

if [ "$STATUS" != "401" ] && [ "$STATUS" != "400" ] && [ "$STATUS" != "429" ]; then
  echo "بررسی API ورود پاسخ غیرمنتظره داد: HTTP $STATUS"
  cat /tmp/stage9a-auth-check.json || true
  exit 1
fi

echo "✅ تب ثبت‌نام و دکمه‌های ورود/ثبت‌نام اصلاح شدند؛ API نیز پاسخ می‌دهد."
