#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="/workspaces/shaye-final-rc2/SHAYE-FINAL-RC2"
FRONTEND="$ROOT/frontend"
INDEX="$FRONTEND/index.html"
APP_JS="$FRONTEND/assets/js/app.js"
STYLE="$FRONTEND/assets/css/style.css"
COMPOSE="$ROOT/docker-compose.codespaces.yml"
ORIGIN="https://${CODESPACE_NAME}-5000.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"
STAMP="rc2-authfix2"

for f in "$INDEX" "$APP_JS" "$STYLE" "$COMPOSE"; do
  [ -f "$f" ] || { echo "❌ فایل لازم پیدا نشد: $f"; exit 1; }
done

python3 - <<'PY'
from pathlib import Path
import re

root = Path('/workspaces/shaye-final-rc2/SHAYE-FINAL-RC2/frontend')
index = root / 'index.html'
html = index.read_text()

# Inline onclickها ممکن است توسط سیاست امنیتی مرورگر مسدود شوند؛ کنترل‌ها شناسه می‌گیرند.
html = re.sub(r'<button\s+class="tab active"\s+onclick="showLogin\(\)"\s*>', '<button type="button" id="authTabLogin" class="tab active">', html, count=1)
html = re.sub(r'<button\s+class="tab"\s+onclick="showRegister\(\)"\s*>', '<button type="button" id="authTabRegister" class="tab">', html, count=1)

# حالت‌های قالب‌بندی متفاوت را هم پوشش می‌دهیم.
html = html.replace('class="tab active"\nonclick="showLogin()"', 'id="authTabLogin" class="tab active"')
html = html.replace('class="tab"\nonclick="showRegister()"', 'id="authTabRegister" class="tab"')

# دکمه‌های نمایش رمز بدون onclick داخلی.
html = re.sub(r'<button\s+type="button"\s+class="eye"\s+onclick="togglePassword\(\'loginPassword\'\)"\s*>', '<button type="button" id="toggleLoginPassword" class="eye">', html, count=1)
html = re.sub(r'<button\s+type="button"\s+class="eye"\s+onclick="togglePassword\(\'registerPassword\'\)"\s*>', '<button type="button" id="toggleRegisterPassword" class="eye">', html, count=1)
html = re.sub(r'<button\s+type="button"\s+class="eye"\s+onclick="togglePassword\(\'confirmPassword\'\)"\s*>', '<button type="button" id="toggleConfirmPassword" class="eye">', html, count=1)

# اطمینان از نسخه جدید بدون کش.
html = re.sub(r'<script src="assets/js/app\.js(?:\?v=[^"]+)?"></script>', f'<script src="assets/js/app.js?v={"rc2-authfix2"}"></script>', html, count=1)
index.write_text(html)
PY

cat > "$APP_JS" <<'JS'
"use strict";

function byId(id) { return document.getElementById(id); }

function showMessage(text, type) {
  var node = byId("message");
  if (!node) return;
  node.textContent = text || "";
  node.className = type || "";
}

function setAuthView(view) {
  var login = byId("loginForm");
  var register = byId("registerForm");
  var loginTab = byId("authTabLogin") || document.querySelectorAll(".tab")[0];
  var registerTab = byId("authTabRegister") || document.querySelectorAll(".tab")[1];
  var isRegister = view === "register";

  if (login) {
    login.classList.toggle("active", !isRegister);
    login.hidden = isRegister;
  }
  if (register) {
    register.classList.toggle("active", isRegister);
    register.hidden = !isRegister;
  }
  if (loginTab) loginTab.classList.toggle("active", !isRegister);
  if (registerTab) registerTab.classList.toggle("active", isRegister);
  showMessage("", "");
}

function showLogin(event) {
  if (event && event.preventDefault) event.preventDefault();
  setAuthView("login");
}

function showRegister(event) {
  if (event && event.preventDefault) event.preventDefault();
  setAuthView("register");
}

function togglePassword(id, event) {
  if (event && event.preventDefault) event.preventDefault();
  var input = byId(id);
  if (!input) return;
  input.type = input.type === "password" ? "text" : "password";
}

async function loginUser(event) {
  if (event && event.preventDefault) event.preventDefault();
  var emailNode = byId("loginEmail");
  var passwordNode = byId("loginPassword");
  var email = emailNode ? (emailNode.value || "").trim().toLowerCase() : "";
  var password = passwordNode ? passwordNode.value : "";
  if (!email || !password) return showMessage("ایمیل و رمز عبور را وارد کنید.", "error");
  try {
    showMessage("در حال ورود...", "");
    await ShayeAPI.auth.login({ email: email, password: password });
    showMessage("ورود موفق بود.", "success");
    setTimeout(function () { location.href = "dashboard.html"; }, 250);
  } catch (error) {
    showMessage(error && error.message ? error.message : "ورود انجام نشد.", "error");
  }
}

async function registerUser(event) {
  if (event && event.preventDefault) event.preventDefault();
  var emailNode = byId("registerEmail");
  var passwordNode = byId("registerPassword");
  var confirmNode = byId("confirmPassword");
  var inviteNode = byId("inviteCode");
  var email = emailNode ? (emailNode.value || "").trim().toLowerCase() : "";
  var password = passwordNode ? passwordNode.value : "";
  var confirm = confirmNode ? confirmNode.value : "";
  var invite = inviteNode ? (inviteNode.value || "").trim() : "";
  if (!email || !password) return showMessage("ایمیل و رمز عبور را وارد کنید.", "error");
  if (password !== confirm) return showMessage("رمز عبور و تکرار آن یکسان نیست.", "error");
  try {
    showMessage("در حال ساخت حساب...", "");
    await ShayeAPI.auth.register({ email: email, password: password, inviteCode: invite || null });
    showMessage("ثبت‌نام موفق بود.", "success");
    setTimeout(function () { location.href = "dashboard.html"; }, 250);
  } catch (error) {
    showMessage(error && error.message ? error.message : "ثبت‌نام انجام نشد.", "error");
  }
}

function removeLoader() {
  var loader = byId("loader");
  if (!loader) return;
  loader.style.pointerEvents = "none";
  loader.classList.add("hide");
  setTimeout(function () { if (loader && loader.parentNode) loader.remove(); }, 300);
}

function bindClick(id, handler) {
  var node = byId(id);
  if (!node) return;
  node.onclick = null;
  node.addEventListener("click", handler, false);
}

function initAuthControls() {
  bindClick("authTabLogin", showLogin);
  bindClick("authTabRegister", showRegister);
  bindClick("toggleLoginPassword", function (e) { togglePassword("loginPassword", e); });
  bindClick("toggleRegisterPassword", function (e) { togglePassword("registerPassword", e); });
  bindClick("toggleConfirmPassword", function (e) { togglePassword("confirmPassword", e); });

  var loginForm = byId("loginForm");
  var registerForm = byId("registerForm");
  if (loginForm) loginForm.addEventListener("submit", loginUser, false);
  if (registerForm) registerForm.addEventListener("submit", registerUser, false);

  setAuthView("login");
  removeLoader();
}

document.addEventListener("DOMContentLoaded", initAuthControls, { once: true });
window.addEventListener("load", removeLoader, { once: true });
setTimeout(removeLoader, 1200);

window.showLogin = showLogin;
window.showRegister = showRegister;
window.togglePassword = togglePassword;
window.loginUser = loginUser;
window.registerUser = registerUser;
JS

cat >> "$STYLE" <<'CSS'

/* SHAYE RC2 auth controls hardening */
.loader.hide { pointer-events: none !important; }
.auth-container, .auth-card, .tabs, .tab, .form, .main-btn, .eye {
  position: relative;
  pointer-events: auto !important;
}
.auth-container { z-index: 2; }
.auth-card { z-index: 3; }
.tabs { z-index: 4; }
.tab, .main-btn, .eye { z-index: 5; touch-action: manipulation; }
.form[hidden] { display: none !important; }
.form.active:not([hidden]) { display: block !important; }
CSS

node --check "$APP_JS"
grep -q 'id="authTabLogin"' "$INDEX"
grep -q 'id="authTabRegister"' "$INDEX"
grep -q 'app.js?v=rc2-authfix2' "$INDEX"
grep -q 'bindClick("authTabRegister"' "$APP_JS"

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
JSFILE="$(mktemp)"
curl -fsS http://127.0.0.1:5000/ -o "$PAGE"
curl -fsS "http://127.0.0.1:5000/assets/js/app.js?v=$STAMP" -o "$JSFILE"
grep -q 'id="authTabRegister"' "$PAGE"
grep -q 'bindClick("authTabRegister"' "$JSFILE"
rm -f "$PAGE" "$JSFILE"

echo "✅ تب ثبت‌نام، دکمه‌های ورود و نمایش رمز بدون onclick داخلی فعال شدند."
echo "$ORIGIN/?authfix=2"
