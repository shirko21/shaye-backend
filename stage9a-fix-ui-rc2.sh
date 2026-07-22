#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="/workspaces/shaye-stage9a/SHAYE-STAGE-09A-CODESPACES"
FRONTEND="$ROOT/frontend"
BACKEND="$ROOT/backend/shaye-api"

if [ ! -f "$FRONTEND/dashboard.html" ] || [ ! -f "$BACKEND/package.json" ]; then
  echo "پروژه استخراج‌شده مرحله 9A پیدا نشد."
  exit 1
fi

python3 - <<'PY'
from pathlib import Path

root = Path('/workspaces/shaye-stage9a/SHAYE-STAGE-09A-CODESPACES')
frontend = root / 'frontend'
backend = root / 'backend/shaye-api'

wheel_js = r"""(function(){'use strict';var C=['#2ad382','#ffc857','#7298ff','#e87ad8','#52d9e6','#ff7b7b','#a98bff','#ff9f43'];function e(v){return String(v==null?'':v).replace(/[&<>\"']/g,function(c){return{'&':'&amp;','<':'&lt;','>':'&gt;','\"':'&quot;',\"'\":'&#39;'}[c]})}function d(n){if(!n)return'#2ad382';var s=360/n,p=[];for(var i=0;i<n;i++)p.push(C[i%C.length]+' '+i*s+'deg '+(i+1)*s+'deg');return'conic-gradient('+p.join(',')+')'}function l(x,p){x.innerHTML='';var n=p.length||1,s=360/n;p.forEach(function(a,i){var q=document.createElement('div');q.className='shaye-wheel-label';q.style.transform='rotate('+(i*s+s/2)+'deg) translate(36px,-50%)';q.innerHTML='<span>'+e(a.title)+'</span>'+(a.subtitle?'<small>'+e(a.subtitle)+'</small>':'');x.appendChild(q)})}async function m(){var pg=location.pathname.split('/').pop()||'dashboard.html';if(pg!=='dashboard.html'||document.querySelector('.shaye-wheel-fab')||!window.ShayeAPI?.wheel)return;var st;try{st=await ShayeAPI.wheel.status()}catch(x){console.warn(x);return}var p=Array.isArray(st.prizes)?st.prizes:[],cfg=st.settings||{},sp=Number(st.spins||0),f=document.createElement('button');f.type='button';f.className='shaye-wheel-fab';f.setAttribute('aria-label','باز کردن گردونه شانس');f.innerHTML='<span class="shaye-wheel-credit" id="shayeWheelCredit">'+sp+'</span>';var o=document.createElement('div');o.className='shaye-wheel-overlay';o.innerHTML='<div class="shaye-wheel-modal"><div class="shaye-wheel-head"><div><h3>گردونه شانس</h3><p>فرصت باقی‌مانده: <strong id="shayeWheelSpins">'+sp+'</strong></p></div><button type="button" class="shaye-wheel-close">×</button></div><p class="shaye-wheel-launch-note">'+e(cfg.notice||'هر فرصت فقط یک‌بار قابل استفاده است.')+'</p><div class="shaye-wheel-stage"><div class="shaye-wheel-pointer"></div><div class="shaye-wheel-disk" id="shayeWheelDisk"></div><button type="button" class="shaye-wheel-center" id="shayeWheelSpin">بچرخان</button></div><div class="shaye-wheel-status" id="shayeWheelStatus">'+(sp>0?'گردونه آماده است.':'در حال حاضر فرصت گردونه ندارید.')+'</div><div class="shaye-wheel-info"><div><span>استفاده‌شده</span><strong id="shayeWheelUsed">'+Number(st.spinsUsed||0)+'</strong></div><div><span>وضعیت</span><strong>'+(cfg.enabled?'فعال':'غیرفعال')+'</strong></div></div></div>';document.body.append(f,o);var disk=document.getElementById('shayeWheelDisk'),b=document.getElementById('shayeWheelSpin'),msg=document.getElementById('shayeWheelStatus'),sb=document.getElementById('shayeWheelSpins'),cb=document.getElementById('shayeWheelCredit'),ub=document.getElementById('shayeWheelUsed'),cl=o.querySelector('.shaye-wheel-close');disk.style.background=d(p.length);l(disk,p);var dur=Math.max(1500,Number(cfg.spinDurationMs||3500)),rot=0,busy=false;disk.style.transitionDuration=dur+'ms';function open(v){o.classList.toggle('open',v);document.body.classList.toggle('shaye-wheel-open',v)}function sync(){b.disabled=busy||!cfg.enabled||sp<=0||!p.length;b.textContent=busy?'...':'بچرخان'}f.onclick=function(){open(true)};cl.onclick=function(){open(false)};o.onclick=function(x){if(x.target===o)open(false)};b.onclick=async function(){if(busy||sp<=0)return;busy=true;sync();msg.className='shaye-wheel-status';msg.textContent='در حال تعیین جایزه...';try{var r=await ShayeAPI.wheel.spin(),i=p.findIndex(function(a){return a.id===r.prize.id});if(i<0)i=0;var s=360/Math.max(1,p.length),land=360-(i*s+s/2),mod=((rot%360)+360)%360;rot+=2160+((land-mod+360)%360);disk.style.transform='rotate('+rot+'deg)';msg.textContent='گردونه در حال چرخش است...';setTimeout(function(){sp=Number(r.spinsRemaining||0);sb.textContent=cb.textContent=String(sp);ub.textContent=String(Number(ub.textContent||0)+1);msg.className='shaye-wheel-status success';msg.innerHTML='🎉 جایزه شما: <strong>'+e(r.prize.title)+'</strong>'+(Number(r.rewardAmount||0)>0?' — '+Number(r.rewardAmount).toFixed(2)+' USDT':'');busy=false;sync()},dur+180)}catch(x){msg.className='shaye-wheel-status error';msg.textContent=x?.message||'چرخاندن گردونه انجام نشد.';busy=false;sync()}};sync();if(sp>0&&sessionStorage.getItem('shayeWheelOpened')!=='1'){sessionStorage.setItem('shayeWheelOpened','1');setTimeout(function(){open(true)},700)}}if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',m,{once:true});else m()})();
"""

wheel_css = r""".shaye-wheel-fab{position:fixed;right:14px;bottom:88px;z-index:9000;width:54px;height:54px;border:3px solid rgba(255,255,255,.9);border-radius:50%;background:conic-gradient(#2ad382 0 60deg,#ffc857 60deg 120deg,#7298ff 120deg 180deg,#e87ad8 180deg 240deg,#52d9e6 240deg 300deg,#ff7b7b 300deg);box-shadow:0 12px 34px rgba(0,0,0,.55),0 0 20px rgba(42,211,130,.25);cursor:pointer;animation:wf 2.4s ease-in-out infinite}.shaye-wheel-fab:after{content:'🎁';position:absolute;inset:9px;display:grid;place-items:center;border-radius:50%;background:#07110c;font-size:18px}.shaye-wheel-credit{position:absolute;top:-8px;left:-8px;z-index:2;min-width:22px;height:22px;padding:0 6px;display:grid;place-items:center;border-radius:999px;background:#ff5757;color:#fff;font:900 11px/1 Arial;box-shadow:0 4px 12px rgba(0,0,0,.4)}@keyframes wf{0%,100%{transform:translateY(0) rotate(0)}50%{transform:translateY(-6px) rotate(7deg)}}.shaye-wheel-overlay{position:fixed;inset:0;z-index:10000;display:none;align-items:center;justify-content:center;padding:16px;background:rgba(0,0,0,.82);backdrop-filter:blur(6px)}.shaye-wheel-overlay.open{display:flex}.shaye-wheel-open{overflow:hidden}.shaye-wheel-modal{width:min(94vw,430px);max-height:92vh;overflow:auto;padding:18px;border:1px solid rgba(255,255,255,.14);border-radius:24px;background:linear-gradient(160deg,#101820,#07100c);color:#fff;box-shadow:0 28px 90px rgba(0,0,0,.75);text-align:center}.shaye-wheel-head{display:flex;align-items:flex-start;justify-content:space-between;gap:12px;margin-bottom:10px;text-align:right}.shaye-wheel-head h3{margin:0 0 4px;font-size:20px;color:#2ad382}.shaye-wheel-head p{margin:0;font-size:12px;opacity:.75}.shaye-wheel-close{width:38px;height:38px;border:1px solid rgba(255,255,255,.14);border-radius:50%;background:rgba(255,255,255,.06);color:#fff;font-size:21px}.shaye-wheel-launch-note{margin:0 0 14px;padding:10px 12px;border:1px solid rgba(255,200,87,.28);border-radius:12px;background:rgba(255,200,87,.08);color:#ffe29a;font-size:11px;line-height:1.9}.shaye-wheel-stage{position:relative;width:min(78vw,330px);aspect-ratio:1;margin:5px auto 16px}.shaye-wheel-pointer{position:absolute;top:-8px;left:50%;z-index:6;width:0;height:0;transform:translateX(-50%);border-left:16px solid transparent;border-right:16px solid transparent;border-top:32px solid #fff;filter:drop-shadow(0 4px 5px rgba(0,0,0,.55))}.shaye-wheel-disk{position:absolute;inset:0;overflow:hidden;border:8px solid #e7fff3;border-radius:50%;box-shadow:0 0 0 8px rgba(42,211,130,.12),0 20px 48px rgba(0,0,0,.5);transition-property:transform;transition-timing-function:cubic-bezier(.12,.72,.08,1)}.shaye-wheel-label{position:absolute;left:50%;top:50%;width:38%;transform-origin:0 50%;color:#07100c;font:900 10px/1.35 Arial;text-align:center;text-shadow:0 1px rgba(255,255,255,.42)}.shaye-wheel-label span,.shaye-wheel-label small{display:block}.shaye-wheel-label small{font-size:7px;opacity:.75}.shaye-wheel-center{position:absolute;left:50%;top:50%;z-index:5;width:88px;height:88px;transform:translate(-50%,-50%);border:6px solid rgba(255,255,255,.92);border-radius:50%;background:#08120d;color:#fff;font-weight:900;box-shadow:0 8px 24px rgba(0,0,0,.45)}.shaye-wheel-center[disabled]{opacity:.58}.shaye-wheel-status{min-height:48px;padding:11px;border:1px solid rgba(255,255,255,.07);border-radius:13px;background:rgba(255,255,255,.045);font-size:12px;line-height:2}.shaye-wheel-status.success{color:#8af0bb;border-color:rgba(42,211,130,.3);background:rgba(42,211,130,.09)}.shaye-wheel-status.error{color:#ff9b9b;border-color:rgba(255,87,87,.3);background:rgba(255,87,87,.08)}.shaye-wheel-info{display:flex;gap:9px;margin-top:11px}.shaye-wheel-info div{flex:1;padding:9px;border-radius:11px;background:rgba(255,255,255,.04)}.shaye-wheel-info span{display:block;font-size:9px;opacity:.62}.shaye-wheel-info strong{direction:ltr;display:block;font-size:12px}
"""

bridge_js = r"""(function(){'use strict';function pg(){return location.pathname.split('/').pop()||'dashboard.html'}document.addEventListener('click',function(e){var b=e.target.closest?.('.bottom-nav [data-page]');if(b){e.preventDefault();location.href=b.dataset.page;return}b=e.target.closest?.('.wallet-action-btn.deposit,[data-action="deposit"]');if(b){e.preventDefault();location.href='deposit.html';return}b=e.target.closest?.('.wallet-action-btn.withdraw,[data-action="withdraw"]');if(b){e.preventDefault();location.href='withdraw.html'}},true);function nav(){var n=document.querySelector('.bottom-nav');if(!n)return;var cur=pg(),exp=['deposit.html','withdraw.html'].includes(cur)?'wallet.html':cur;n.querySelectorAll('button').forEach(function(b){var t=b.dataset.page;if(!t){var x=b.getAttribute('onclick')||'',m=x.match(/goPage\(['\"]([^'\"]+)['\"]\)/);if(m)t=m[1]}if(t){b.dataset.page=t;b.classList.toggle('active',t===exp)}})}function back(){if(!['deposit.html','withdraw.html'].includes(pg())||document.querySelector('.stage9a-back-button'))return;var h=document.querySelector('.main-header');if(!h)return;var b=document.createElement('button');b.type='button';b.className='stage9a-back-button';b.textContent='بازگشت به کیف پول';b.onclick=function(){location.href='wallet.html'};h.appendChild(b)}function test(){if(pg()!=='deposit.html'||document.getElementById('stage9aTestDepositCard')||!ShayeAPI?.deposits?.testCredit)return;var main=document.querySelector('.dashboard-container'),s=document.createElement('section');if(!main)return;s.className='card stage9a-test-card';s.id='stage9aTestDepositCard';s.innerHTML='<div class="stage9a-test-badge">فقط محیط آزمایشی Codespaces</div><h3>افزایش سرمایه آزمایشی</h3><p>بدون ارسال تتر واقعی، مبلغ آزمایشی را اضافه و VIP، وظایف، معرفی و گردونه را بررسی کن.</p><div class="stage9a-test-row"><input id="stage9aTestAmount" type="number" min="10" max="10000" step="1" value="10"><button type="button" class="btn-green" id="stage9aTestDepositButton">افزودن آزمایشی</button></div><div id="stage9aTestDepositMessage" class="stage9a-test-message"></div>';var m=document.getElementById('manualDepositSection');m?m.before(s):main.appendChild(s);document.getElementById('stage9aTestDepositButton').onclick=async function(){var a=Number(document.getElementById('stage9aTestAmount').value||0),q=document.getElementById('stage9aTestDepositMessage');if(a<10||a>10000){q.className='stage9a-test-message error';q.textContent='مبلغ باید بین ۱۰ تا ۱۰٬۰۰۰ باشد.';return}this.disabled=true;this.textContent='در حال ثبت...';try{await ShayeAPI.deposits.testCredit({amount:a});q.className='stage9a-test-message success';q.textContent='سرمایه آزمایشی اضافه شد.';setTimeout(function(){location.reload()},700)}catch(x){q.className='stage9a-test-message error';q.textContent=x?.message||'انجام نشد.';this.disabled=false;this.textContent='افزودن آزمایشی'}}}function boot(){nav();back();setTimeout(test,500)}document.readyState==='loading'?document.addEventListener('DOMContentLoaded',boot,{once:true}):boot()})();
"""

bridge_css = r""".stage9a-test-card{border:1px solid rgba(255,200,87,.32)!important;background:linear-gradient(145deg,rgba(255,200,87,.1),rgba(42,211,130,.06))!important}.stage9a-test-card p{font-size:12px;line-height:1.9;opacity:.82}.stage9a-test-badge{display:inline-flex;padding:5px 9px;border-radius:999px;background:rgba(255,200,87,.16);color:#ffd978;font-size:10px;font-weight:800}.stage9a-test-row{display:flex;gap:10px;align-items:center;margin-top:13px}.stage9a-test-row input{min-width:0;flex:1;height:46px;padding:0 12px;border:1px solid rgba(255,255,255,.12);border-radius:12px;background:rgba(0,0,0,.24);color:#fff}.stage9a-test-row button{flex:1;margin:0}.stage9a-test-message{min-height:24px;margin-top:10px;font-size:11px}.stage9a-test-message.success{color:#82efb8}.stage9a-test-message.error{color:#ff9b9b}.stage9a-back-button{margin-inline-start:auto;padding:8px 11px;border:1px solid rgba(255,255,255,.12);border-radius:10px;background:rgba(255,255,255,.06);color:#fff;font-family:inherit;font-size:10px}.bottom-nav button{touch-action:manipulation;cursor:pointer}@media(max-width:370px){.stage9a-test-row{flex-direction:column}.stage9a-test-row input,.stage9a-test-row button{width:100%}}
"""

(frontend/'assets/js/lucky-wheel.js').write_text(wheel_js)
(frontend/'assets/css/lucky-wheel.css').write_text(wheel_css)
(frontend/'assets/js/stage9a-ui-bridge.js').write_text(bridge_js)
(frontend/'assets/css/stage9a-ui.css').write_text(bridge_css)

for name in ['dashboard.html','wallet.html','deposit.html','withdraw.html','team.html','tasks.html','report.html']:
    p=frontend/name
    t=p.read_text()
    if 'assets/css/stage9a-ui.css?v=2' not in t:
        t=t.replace('</head>','  <link rel="stylesheet" href="assets/css/stage9a-ui.css?v=2">\n</head>',1)
    if 'assets/js/navigation.js' not in t:
        pos=t.find('<script>ShayePages.init')
        if pos<0: raise SystemExit(f'init marker missing: {name}')
        t=t[:pos]+'<script src="assets/js/navigation.js?v=2"></script>\n  '+t[pos:]
    else:
        t=t.replace('assets/js/navigation.js"','assets/js/navigation.js?v=2"')
    t=t.replace('assets/css/lucky-wheel.css"','assets/css/lucky-wheel.css?v=2"')
    t=t.replace('assets/js/lucky-wheel.js"','assets/js/lucky-wheel.js?v=2"')
    if 'assets/js/stage9a-ui-bridge.js?v=2' not in t:
        t=t.replace('</body>','  <script src="assets/js/stage9a-ui-bridge.js?v=2"></script>\n</body>',1)
    p.write_text(t)

p=frontend/'assets/js/api.js';t=p.read_text();old="deposits:{list:()=>request('/deposits'),create:b=>request('/deposits',{method:'POST',body:b})}";new="deposits:{list:()=>request('/deposits'),create:b=>request('/deposits',{method:'POST',body:b}),testCredit:b=>request('/deposits/test-credit',{method:'POST',body:b})}"
if new not in t:
    if old not in t: raise SystemExit('deposit API marker missing')
    t=t.replace(old,new,1)
p.write_text(t)

p=backend/'src/services/deposit.service.ts';t=p.read_text()
if 'import crypto from "crypto";' not in t:t='import crypto from "crypto";\n'+t
if 'createStage9ATestDeposit' not in t:
    marker='export async function listUserDeposits(userId: string) {'
    fn='''export async function createStage9ATestDeposit(userId: string, value: number) {\n  if (process.env.STAGE9A_TEST_MODE !== "true") throw new AppError(404, "این مسیر فقط در محیط آزمایشی مرحله ۹A فعال است.", "TEST_MODE_DISABLED");\n  const amount = money(value);\n  if (amount > 10_000) throw new AppError(400, "حداکثر افزایش آزمایشی ۱۰٬۰۰۰ USDT است.", "TEST_AMOUNT_LIMIT");\n  const txHash = `0x${crypto.randomBytes(32).toString("hex")}`;\n  const deposit = await createDeposit(userId, amount, txHash);\n  await approveDeposit(userId, deposit.id, "Stage 9A Codespaces test credit");\n  return { ...deposit, status: "APPROVED", testMode: true };\n}\n\n'''
    if marker not in t:raise SystemExit('deposit service marker missing')
    t=t.replace(marker,fn+marker,1)
p.write_text(t)

p=backend/'src/controllers/deposit.controller.ts';t=p.read_text()
if 'export const testCredit' not in t:t+='\nexport const testCredit: RequestHandler = async (req, res) => ok(res, await service.createStage9ATestDeposit(req.auth!.userId, req.body.amount), "سرمایه آزمایشی اضافه شد.", 201);\n'
p.write_text(t)

p=backend/'src/routes/deposit.routes.ts';t=p.read_text();old='router.get("/", asyncHandler(controller.list)); router.post("/", validateBody(z.object({ amount: amountSchema, txHash: z.string().trim().max(128).optional() })), asyncHandler(controller.create)); export default router;';new='router.get("/", asyncHandler(controller.list)); router.post("/test-credit", validateBody(z.object({ amount: amountSchema })), asyncHandler(controller.testCredit)); router.post("/", validateBody(z.object({ amount: amountSchema, txHash: z.string().trim().max(128).optional() })), asyncHandler(controller.create)); export default router;'
if new not in t:
    if old not in t:raise SystemExit('deposit route marker missing')
    t=t.replace(old,new,1)
p.write_text(t)

p=root/'docker-compose.codespaces.yml';t=p.read_text()
if 'STAGE9A_TEST_MODE:' not in t:t=t.replace('      DEPOSIT_WALLET_ENABLED: "false"\n','      DEPOSIT_WALLET_ENABLED: "false"\n      STAGE9A_TEST_MODE: "true"\n',1)
p.write_text(t)
PY

cd "$BACKEND"
npm run typecheck
npm test

find "$FRONTEND" -type f -name '*.js' -print0 | xargs -0 -n1 node --check

cd "$ROOT"
docker compose -f docker-compose.codespaces.yml build --no-cache app
docker compose -f docker-compose.codespaces.yml up -d app

for i in $(seq 1 50); do
  if curl -fsS http://127.0.0.1:5000/ready >/dev/null 2>&1; then
    curl -fsS http://127.0.0.1:5000/assets/js/lucky-wheel.js?v=2 | grep -q 'shaye-wheel-disk'
    curl -fsS http://127.0.0.1:5000/assets/js/stage9a-ui-bridge.js?v=2 | grep -q 'stage9aTestDepositCard'
    echo "✅ اصلاحات RC2 اعمال شد: گردونه گرافیکی، منوها و واریز آزمایشی آماده‌اند."
    exit 0
  fi
  sleep 2
done

echo "سرویس در زمان تعیین‌شده آماده نشد."
docker compose -f docker-compose.codespaces.yml ps
exit 1
