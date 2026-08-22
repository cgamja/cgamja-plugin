#!/usr/bin/env bash
# Stop: 코드가 바뀐 턴만 commands.verify(.claude/cgamja.json). 실패하면 마지막 50줄과 함께 block.
source "$(dirname "$0")/_lib.sh"
[ "$(j stop_hook_active)" = "true" ] && exit 0
cd "$ROOT" 2>/dev/null || exit 0
verify="$(cfg commands.verify)"; [ -z "$verify" ] && { echo "[stop] commands.verify 선언 없음 — 완료 정의가 없습니다(/develop-setup)" >&2; exit 0; }
changed="$( { git diff --name-only; git diff --cached --name-only; git ls-files --others --exclude-standard; } 2>/dev/null | grep -vE '^(openspec|docs|design)/|\.md$' || true)"
[ -z "$changed" ] && exit 0
if git diff --name-only 2>/dev/null | grep -qE "$(cfg protected | globs_to_regex)"; then
  echo "[stop] 보호 파일(의존성·설정)이 바뀌었습니다 — 사용자 확인이 필요합니다." >&2; fi
out="$(bash -c "$verify" 2>&1)" || { echo "[stop] \`$verify\` 실패 — 고치기 전엔 끝난 게 아닙니다:" >&2; echo "$out" | tail -50 >&2; exit 2; }
exit 0
