#!/usr/bin/env bash
# PreToolUse (Agent): 리뷰를 서브에이전트로 즉석 제작하려 하면 /ce-code-review 스킬을 쓰라고 상기(차단 아님). workflow 2장 5번.
source "$(dirname "$0")/_lib.sh"
d="$(j tool_input.description) $(j tool_input.prompt)"
grep -qiE 'review|리뷰|코드 ?검토' <<<"$d" || exit 0
grep -q 'agents/reviewer-' <<<"$d" && exit 0   # review-fe가 persona 파일로 띄우는 렌즈 에이전트는 정상 경로
context "[develop-fe] 코드 리뷰는 Agent 도구로 즉석 제작하지 않는다 — Skill 도구로 cgamja:review-fe 를 부른다(렌즈 persona agents/reviewer-*.md + compound-engineering:ce-code-review 에 plan:<spec.md> 경로 조립, workflow 2장 5번, adr/0012). 이 Agent 호출이 리뷰 목적이면 취소하고 스킬로 대체하라."
