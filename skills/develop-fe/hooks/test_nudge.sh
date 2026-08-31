#!/usr/bin/env bash
# PreToolUse (Edit|Write): 테스트 파일을 편집하려는데 이 세션에서 cgamja:test-driven-development 스킬을 부른 적이 없으면 상기(차단 아님). adr/0026
source "$(dirname "$0")/_lib.sh"
f="$(j tool_input.file_path)"
grep -qE '(\.test\.|\.browser\.test\.|\.spec\.|/e2e/|\.stories\.)' <<<"$f" || exit 0
[ -f "$STATE/test-driven-development" ] && exit 0
context "[develop-fe] 테스트 파일($f)을 쓰기 전에 Skill 도구로 cgamja:test-driven-development 를 부른다 — 실패하는 테스트 먼저(RED), 버그는 재현 테스트 먼저, 스택 발견 후 그 명령 사용(adr/0026). red 게이트·test(scope): 커밋 분리는 workflow 3-2. 이 Edit를 멈추고 스킬을 먼저 호출하라. 이미 TDD 절차를 따르는 중이면 무시해도 된다."
