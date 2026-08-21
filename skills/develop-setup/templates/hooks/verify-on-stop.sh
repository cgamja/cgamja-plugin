#!/usr/bin/env bash
# Stop: 코드가 바뀐 턴만 pnpm verify. 실패하면 마지막 50줄과 함께 block.
source "$(dirname "$0")/_lib.sh"
[ "$(j stop_hook_active)" = "true" ] && exit 0
cd "$(j cwd)" 2>/dev/null || exit 0
changed="$( { git diff --name-only; git diff --cached --name-only; git ls-files --others --exclude-standard; } 2>/dev/null | grep -E '\.(ts|tsx|css|yaml|json)$' | grep -vE '^(openspec|docs|design)/' || true)"
[ -z "$changed" ] && exit 0
if git diff --name-only 2>/dev/null | grep -qE '^(package\.json|pnpm-lock\.yaml)$'; then
  echo "[stop] package.json/lockfile 이 바뀌었습니다 — 새 의존성은 사용자 확인이 필요합니다." >&2
fi
out="$(pnpm verify 2>&1)" || { echo "[stop] pnpm verify 실패 — 고치기 전엔 끝난 게 아닙니다:" >&2; echo "$out" | tail -50 >&2; exit 2; }
exit 0
