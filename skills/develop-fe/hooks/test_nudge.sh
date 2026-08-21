#!/usr/bin/env bash
# PreToolUse (Edit|Write): 테스트 파일을 편집하려는데 이 세션에서 cgamja:test-fe 스킬을 부른 적이 없으면 상기(차단 아님).
# 2026-08-21 Tier-2 실측: 본체가 workflow.md의 "Skill 도구로 test-fe" 한 줄을 무시하고 references를 직접 읽어 작성 → reports/develop-fe-tier2_2026-08-21_restructured.md 결함 2
source "$(dirname "$0")/_lib.sh"
f="$(j tool_input.file_path)"
grep -qE '(\.test\.|\.browser\.test\.|\.spec\.|/e2e/|\.stories\.)' <<<"$f" || exit 0
[ -f "$STATE/test-fe" ] && exit 0
context "[develop-fe] 테스트 파일($f)을 쓰기 전에 Skill 도구로 cgamja:test-fe 를 부른다 — 계층 선택(jsdom/Browser Mode/E2E)·쿼리·MSW 규칙·red 출력 형식이 거기 있다(adr/0010). 이 Edit를 멈추고 스킬을 먼저 호출하라. 이미 test-fe 절차를 따르는 중이면 무시해도 된다."
