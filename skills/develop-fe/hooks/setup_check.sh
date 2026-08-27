#!/usr/bin/env bash
# PreToolUse (Edit|Write|MultiEdit) once:true — 프로젝트 세팅이 없으면 경고 컨텍스트(차단 아님: Tier-1 예외).
# adr/0023: once:true가 실사용에서 보장되지 않아(회고 3b8e61e1에서 경고 31회 발화) 세션 키 마커로 스크립트가 직접 1회를 보장한다. 훅 버전 드리프트 감지도 여기서(세션당 1회).
source "$(dirname "$0")/_lib.sh"
# 프로젝트 루트 고정(adr/0017): 직전 Bash의 cd로 cwd가 하위 디렉터리여도 오경보가 나지 않게 — 위로 올라가며 선언/매니페스트를 찾고, 없으면 git 루트, 그것도 없으면 cwd
cwd="$(j cwd)"; d="${cwd:-$PWD}"
while [ "$d" != "/" ] && [ ! -f "$d/.claude/cgamja.json" ] && [ ! -f "$d/package.json" ]; do d="$(dirname "$d")"; done
[ "$d" = "/" ] && d="$(git -C "${cwd:-.}" rev-parse --show-toplevel 2>/dev/null || echo "${cwd:-.}")"
cd "$d" 2>/dev/null || exit 0
# advisory 경고는 세션당 1회(adr/0023) — 세팅 누락 안내는 마커와 무관하게 기존 동작 유지
sid="$(j session_id)"; mark=".claude/state/develop-fe.warned.${sid:-na}"
warn=""
if [ ! -f "$mark" ]; then
  pm="$(j permission_mode)"
  case "$pm" in bypassPermissions|dontAsk) warn="[develop-fe] permission_mode=$pm — 승인자가 없는 세션일 수 있다. 첫 테스트 파일 Edit는 사람 승인(ask, 세션당 1회)이 필요해 Tier-2 테스트 task에서 멈추게 된다(adr/0018). Tier-2 이상이면 사용자에게 대화형 세션을 권하고, 진행하더라도 테스트 없이 구현으로 넘어가지 마라. ";; esac
  # 훅 버전 드리프트(adr/0023): 프로젝트에 심긴 훅이 템플릿보다 낮으면 경고 — 고치는 건 /develop-setup 재실행(사람)
  tmpl="$(dirname "$0")/../../develop-setup/templates/hooks/protect-bash.sh"
  if [ -f .claude/hooks/protect-bash.sh ] && [ -f "$tmpl" ]; then
    tv="$(sed -n 's/^# cgamja-hooks v\([0-9][0-9]*\)$/\1/p' "$tmpl" | head -1)"
    pv="$(sed -n 's/^# cgamja-hooks v\([0-9][0-9]*\)$/\1/p' .claude/hooks/protect-bash.sh | head -1)"
    if [ -n "$tv" ] && [ "${pv:-0}" -lt "$tv" ]; then
      warn="${warn}[develop-fe] 프로젝트 훅이 구판(v${pv:-0} < v$tv) — 오탐 수정이 반영 안 된 상태다. /develop-setup 재실행으로 .claude/hooks/ 동기화를 사용자에게 제안하라(adr/0023). "; fi
  fi
  [ -n "$warn" ] && { mkdir -p .claude/state 2>/dev/null; : > "$mark" 2>/dev/null; }
fi
m=""
{ [ -f package.json ] && grep -q '"verify"[[:space:]]*:' package.json; } || m="$m package.json#verify"
[ -f openspec/config.yaml ] || m="$m openspec/config.yaml"
[ -f .claude/cgamja.json ] || m="$m .claude/cgamja.json"
ls .claude/rules/*.md >/dev/null 2>&1 || m="$m .claude/rules/"
[ -f .claude/settings.json ] && grep -q '"Stop"' .claude/settings.json || m="$m settings.json#Stop훅"
[ -z "$m" ] && { [ -n "$warn" ] && context "$warn"; exit 0; }
context "${warn}[develop-fe] 프로젝트 세팅 누락:$m — 훅·린트·스펙이 없으면 규칙이 산문으로만 남습니다. Tier-1 한 줄 수정이 아니면 여기서 멈추고 /develop-setup 을 먼저 하라고 안내하세요(즉흥 세팅 금지)."
