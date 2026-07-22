#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="/workspaces/shaye-stage9a/SHAYE-STAGE-09A-CODESPACES/backend/shaye-api"

if [ ! -f "$ROOT/package.json" ]; then
  echo "پروژه استخراج‌شده مرحله 9A پیدا نشد."
  exit 1
fi

python3 - <<'PY'
from pathlib import Path

root = Path('/workspaces/shaye-stage9a/SHAYE-STAGE-09A-CODESPACES/backend/shaye-api')

def replace_once(path: Path, old: str, new: str) -> None:
    text = path.read_text()
    if new in text:
        return
    if old not in text:
        raise SystemExit(f'عبارت مورد انتظار در {path} پیدا نشد')
    path.write_text(text.replace(old, new, 1))

# Express route parameter is guaranteed by /notifications/:id.
p = root / 'src/controllers/user.controller.ts'
replace_once(
    p,
    'service.markNotificationRead(req.auth!.userId,req.params.id)',
    'service.markNotificationRead(req.auth!.userId,req.params.id!)',
)

# HD mnemonic derivation returns HDNodeWallet, not Wallet.
p = root / 'src/services/sweep-signer.service.ts'
replace_once(
    p,
    '): Wallet {\n  if (!Number.isSafeInteger(derivationIndex)',
    '): HDNodeWallet {\n  if (!Number.isSafeInteger(derivationIndex)',
)

# Give ethers dynamic balanceOf methods an explicit callable type.
p = root / 'src/services/wallet-sweeper.service.ts'
text = p.read_text()
abi = '''const ERC20_ABI = [\n  "function balanceOf(address account) view returns (uint256)",\n] as const;\n'''
alias = '''type Erc20BalanceContract = Contract & {\n  balanceOf(account: string): Promise<bigint>;\n};\n'''
if alias not in text:
    if abi not in text:
        raise SystemExit('ERC20_ABI در wallet-sweeper پیدا نشد')
    text = text.replace(abi, abi + alias, 1)
replacements = {
    'new Contract(controls.tokenContract!, ERC20_ABI, provider);':
        'new Contract(controls.tokenContract!, ERC20_ABI, provider) as Erc20BalanceContract;',
    'new Contract(current.token_contract, ERC20_ABI, provider);':
        'new Contract(current.token_contract, ERC20_ABI, provider) as Erc20BalanceContract;',
    'new Contract(row.token_contract, ERC20_ABI, provider);':
        'new Contract(row.token_contract, ERC20_ABI, provider) as Erc20BalanceContract;',
    'new Contract(controls.tokenContract, ERC20_ABI, provider);':
        'new Contract(controls.tokenContract, ERC20_ABI, provider) as Erc20BalanceContract;',
}
for old, new in replacements.items():
    if new not in text:
        if old not in text:
            raise SystemExit(f'قرارداد مورد انتظار در wallet-sweeper پیدا نشد: {old}')
        text = text.replace(old, new)
p.write_text(text)

p = root / 'src/services/withdrawal-execution.service.ts'
text = p.read_text()
abi = '''const ERC20_BALANCE_ABI = [\n  "function balanceOf(address account) view returns (uint256)",\n] as const;\n'''
alias = '''type Erc20BalanceContract = Contract & {\n  balanceOf(account: string): Promise<bigint>;\n};\n'''
if alias not in text:
    if abi not in text:
        raise SystemExit('ERC20_BALANCE_ABI در withdrawal-execution پیدا نشد')
    text = text.replace(abi, abi + alias, 1)
old = 'new Contract(row.token_contract, ERC20_BALANCE_ABI, provider).balanceOf('
new = '(new Contract(row.token_contract, ERC20_BALANCE_ABI, provider) as Erc20BalanceContract).balanceOf('
if new not in text:
    if old not in text:
        raise SystemExit('balanceOf برداشت پیدا نشد')
    text = text.replace(old, new, 1)
old = '''      const token = new Contract(\n        blockchainConfig.tokenAddress,\n        ERC20_BALANCE_ABI,\n        provider,\n      );'''
new = '''      const token = new Contract(\n        blockchainConfig.tokenAddress,\n        ERC20_BALANCE_ABI,\n        provider,\n      ) as Erc20BalanceContract;'''
if new not in text:
    if old not in text:
        raise SystemExit('قرارداد موجودی Hot Wallet پیدا نشد')
    text = text.replace(old, new, 1)
p.write_text(text)

p = root / 'src/constants.ts'
text = p.read_text()
if 'export const MAX_MONEY' not in text:
    if not text.endswith('\n'):
        text += '\n'
    text += 'export const MAX_MONEY = 1_000_000_000;\n'
p.write_text(text)

# Ensure package-lock uses the public npm registry in Codespaces.
p = root / 'package-lock.json'
text = p.read_text()
text = text.replace(
    'https://packages.applied-caas-gateway1.internal.api.openai.org/artifactory/api/npm/npm-public/',
    'https://registry.npmjs.org/',
)
p.write_text(text)
PY

cd "$ROOT"
npm run typecheck

echo
printf '%s\n' "✅ اصلاحات TypeScript اعمال شد و typecheck بدون خطا تمام شد."
