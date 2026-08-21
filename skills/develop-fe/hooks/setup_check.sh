#!/usr/bin/env bash
# PreToolUse (Edit|Write|MultiEdit) once:true — 프로젝트 세팅이 없으면 경고 컨텍스트(차단 아님: Tier-1 예외).
source "$(dirname "$0")/_lib.sh"
cwd="$(j cwd)"; cd "${cwd:-.}" 2>/dev/null || exit 0
pm="$(j permission_mode)"
warn=""; case "$pm" in bypassPermissions|dontAsk) warn="[develop-fe] permission_mode=$pm — 승인자가 없는 세션일 수 있다. 테스트 파일 Edit는 사람 승인(ask)이 필요해 Tier-2 테스트 task에서 멈추게 된다(adr/0009). Tier-2 이상이면 사용자에게 대화형 세션을 권하고, 진행하더라도 테스트 없이 구현으로 넘어가지 마라. ";; esac
m=""
{ [ -f package.json ] && grep -q '"verify"[[:space:]]*:' package.json; } || m="$m package.json#verify"
[ -f openspec/config.yaml ] || m="$m openspec/config.yaml"
ls .claude/rules/*.md >/dev/null 2>&1 || m="$m .claude/rules/"
[ -f .claude/settings.json ] && grep -q '"Stop"' .claude/settings.json || m="$m settings.json#Stop훅"
[ -z "$m" ] && { [ -n "$warn" ] && context "$warn"; exit 0; }
context "${warn}[develop-fe] 프로젝트 세팅 누락:$m — 훅·린트·스펙이 없으면 규칙이 산문으로만 남습니다. Tier-1 한 줄 수정이 아니면 여기서 멈추고 /develop-setup 을 먼저 하라고 안내하세요(즉흥 세팅 금지)."
