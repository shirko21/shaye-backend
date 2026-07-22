#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="/workspaces/shaye-final-rc2/SHAYE-FINAL-RC2"
FRONTEND="$ROOT/frontend"
APP_JS="$FRONTEND/assets/js/app.js"
INDEX="$FRONTEND/index.html"
COMPOSE="$ROOT/docker-compose.codespaces.yml"
ORIGIN="https://${CODESPACE_NAME}-5000.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"

[ -f "$APP_JS" ] || { echo "❌ فایل app.js پیدا نشد."; exit 1; }
[ -f "$INDEX" ] || { echo "❌ فایل index.html پیدا نشد."; exit 1; }
[ -f "$COMPOSE" ] || { echo "❌ فایل اجرای Codespaces پیدا نشد."; exit 1; }

cat > "$APP_JS" <<'JS'
"use strict";

function showMessage(text, type) {
  var m = document.getElementById("message");
  if (!m) return;
  m.textContent = text || "";
  m.className = type || "";
}

function showLogin() {
  var login = document.getElementById("loginForm");
  var register = document.getElementById("registerForm");
  if (login) login.classList.add("active");
  if (register) register.classList.remove("active");
  var tabs = document.querySelectorAll(".tab");
  if (tabs[0]) tabs[0].classList.add("active");
  if (tabs[1]) tabs[1].classList.remove("active");
}

function showRegister() {
  var login = document.getElementById("loginForm");
  var register = document.getElementById("registerForm");
  if (register) register.classList.add("active");
  if (login) login.classList.remove("active");
  var tabs = document.querySelectorAll(".tab");
  if (tabs[1]) tabs[1].classList.add("active");
  if (tabs[0]) tabs[0].classList.remove("active");
}

function togglePassword(id) {
  var x = document.getElementById(id);
  if (x) x.type = x.type === "password" ? "text" : "password";
}

async function loginUser(e) {
  if (e && e.preventDefault) e.preventDefault();
  var email = (document.getElementById("loginEmail").value || "").trim().toLowerCase();
  var password = document.getElementById("loginPassword").value;
  if (!email || !password) return showMessage("ایمیل و رمز عبور را وارد کنید.", "error");
  try {
    showMessage("در حال ورود...", "");
    await ShayeAPI.auth.login({ email: email, password: password });
    showMessage("ورود موفق بود.", "success");
    setTimeout(function () { location.href = "dashboard.html"; }, 250);
  } catch (x) {
    showMessage(x && x.message ? x.message : "ورود انجام نشد.", "error");
  }
}

async function registerUser(e) {
  if (e && e.preventDefault) e.preventDefault();
  var email = (document.getElementById("registerEmail").value || "").trim().toLowerCase();
  var password = document.getElementById("registerPassword").value;
  var confirm = document.getElementById("confirmPassword").value;
  var invite = (document.getElementById("inviteCode").value || "").trim();
  if (!email || !password) return showMessage("ایمیل و رمز عبور را وارد کنید.", "error");
  if (password !== confirm) return showMessage("رمز عبور و تکرار آن یکسان نیست.", "error");
  try {
    showMessage("در حال ساخت حساب...", "");
    await ShayeAPI.auth.register({ email: email, password: password, inviteCode: invite || null });
    showMessage("ثبت‌نام موفق بود.", "success");
    setTimeout(function () { location.href = "dashboard.html"; }, 250);
  } catch (x) {
    showMessage(x && x.message ? x.message : "ثبت‌نام انجام نشد.", "error");
  }
}

function hideLoader() {
  var loader = document.getElementById("loader");
  if (!loader) return;
  loader.classList.add("hide");
  setTimeout(function () {
    if (loader && loader.parentNode) loader.parentNode.removeChild(loader);
  }, 800);
}

document.addEventListener("DOMContentLoaded", function () {
  var loginForm = document.getElementById("loginForm");
  var registerForm = document.getElementById("registerForm");
  if (loginForm) loginForm.addEventListener("submit", loginUser);
  if (registerForm) registerForm.addEventListener("submit", registerUser);
  setTimeout(hideLoader, 450);
});

window.addEventListener("load", hideLoader, { once: true });
setTimeout(hideLoader, 1800);

window.loginUser = loginUser;
window.registerUser = registerUser;
window.showLogin = showLogin;
window.showRegister = showRegister;
window.togglePassword = togglePassword;
JS

python3 - <<'PY'
from pathlib import Path
import re

index = Path('/workspaces/shaye-final-rc2/SHAYE-FINAL-RC2/frontend/index.html')
html = index.read_text()

fallback = '''
<script data-shaye-auth-bootstrap>
(function(){
  function hide(){
    var x=document.getElementById('loader');
    if(!x)return;
    x.classList.add('hide');
    setTimeout(function(){if(x&&x.parentNode)x.parentNode.removeChild(x);},800);
  }
  document.addEventListener('DOMContentLoaded',function(){setTimeout(hide,500);});
  window.addEventListener('load',hide,{once:true});
  setTimeout(hide,1800);
})();
</script>
'''

if 'data-shaye-auth-bootstrap' not in html:
    html = html.replace('<script src="assets/js/api.js"></script>', fallback + '\n<script src="assets/js/api.js"></script>', 1)

html = re.sub(r'<script src="assets/js/app\.js(?:\?v=[^"]+)?"></script>', '<script src="assets/js/app.js?v=rc2-authfix1"></script>', html, count=1)
index.write_text(html)
PY

node --check "$APP_JS"
grep -q 'data-shaye-auth-bootstrap' "$INDEX"
grep -q 'app.js?v=rc2-authfix1' "$INDEX"
grep -q 'loginForm.addEventListener' "$APP_JS"
grep -q 'setTimeout(hideLoader, 1800)' "$APP_JS"

cd "$ROOT"
export FRONTEND_URL="http://localhost:5000,$ORIGIN"
docker compose -f docker-compose.codespaces.yml build --no-cache app
docker compose -f docker-compose.codespaces.yml up -d --force-recreate app

for i in $(seq 1 60); do
  if curl -fsS http://127.0.0.1:5000/ready >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

PAGE="$(mktemp)"
curl -fsS http://127.0.0.1:5000/ -o "$PAGE"
grep -q 'data-shaye-auth-bootstrap' "$PAGE"
grep -q 'app.js?v=rc2-authfix1' "$PAGE"
rm -f "$PAGE"

echo "✅ صفحه ورود اصلاح شد؛ لودر بسته می‌شود و فرم‌های ورود و ثبت‌نام فعال هستند."
echo "$ORIGIN/?authfix=1"
