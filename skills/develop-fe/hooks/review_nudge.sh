#!/usr/bin/env bash
# PreToolUse (Agent): 리뷰를 서브에이전트로 즉석 제작하려 하면 /ce-code-review 스킬을 쓰라고 상기(차단 아님). workflow 2장 5번.
source "$(dirname "$0")/_lib.sh"
d="$(j tool_input.description) $(j tool_input.prompt)"
grep -qiE 'review|리뷰|코드 ?검토' <<<"$d" || exit 0
context "[develop-fe] 코드 리뷰는 Agent 도구가 아니라 Skill 도구로 compound-engineering:ce-code-review 를 부른다 — args에 plan:openspec/changes/<slug>/specs/<cap>/spec.md 와 힌트 포함(workflow 2장 5번). 이 Agent 호출이 리뷰 목적이면 취소하고 스킬로 대체하라."
