#!/usr/bin/env bash
# PreToolUse (Edit|Write): 테스트 파일을 편집하려는데 이 세션에서 cgamja:test-fe 스킬을 부른 적이 없으면 상기(차단 아님).
# 보강용(2026-08-21 실측에서는 세 런 모두 test-fe를 호출했다 — 처음엔 미호출로 오독). 호출 없이 테스트 파일부터 쓰는 경로만 막는다.
source "$(dirname "$0")/_lib.sh"
f="$(j tool_input.file_path)"
grep -qE '(\.test\.|\.browser\.test\.|\.spec\.|/e2e/|\.stories\.)' <<<"$f" || exit 0
[ -f "$STATE/test-fe" ] && exit 0
context "[develop-fe] 테스트 파일($f)을 쓰기 전에 Skill 도구로 cgamja:test-fe 를 부른다 — 계층 선택(jsdom/Browser Mode/E2E)·쿼리·MSW 규칙·red 출력 형식이 거기 있다(adr/0010). 이 Edit를 멈추고 스킬을 먼저 호출하라. 이미 test-fe 절차를 따르는 중이면 무시해도 된다."
