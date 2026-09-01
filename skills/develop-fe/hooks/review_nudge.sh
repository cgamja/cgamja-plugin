#!/usr/bin/env bash
# PreToolUse (Agent): 리뷰를 서브에이전트로 즉석 제작하려 하면 리뷰 2축 스킬을 쓰라고 상기(차단 아님). workflow 2장 5번, adr/0026.
#
# 판정 대상은 **subagent_type** 이다(adr/0031 — 0028 의 "명령 텍스트가 아니라 대상" 원칙을 이 훅에도 적용).
# 프롬프트 전문을 보면 "리뷰에 대해 이야기하는" 에이전트(회고 분석·탐색)까지 걸린다 —
# 2026-08-31 회고에서 오탐 누적 10회, 그중 3회가 회고 자신의 분석 에이전트였다.
#
# 예외 두 갈래가 다르다(같은 회고에서 오탐과 미탐이 한 줄에서 나왔다):
#   reviewer-correctness  → 항상 정상 경로. develop-baby-fe·L1 렌즈가 직접 띄운다
#   reviewer-cgamja       → **review-cgamja 스킬을 부른 세션에서만** 정상. 스킬 없이 직접 띄우면
#                           재검사 1회 상한·fix(review) 커밋 규칙이 스킬 밖으로 새므로 넛지한다
#                           (2026-08-31: change 3개 중 스킬 경유는 1개뿐이었고 훅은 침묵했다)
source "$(dirname "$0")/_lib.sh"

st="$(j tool_input.subagent_type)"
st="${st##*:}"                       # "cgamja:reviewer-cgamja" → "reviewer-cgamja"

case "$st" in
  reviewer-correctness) exit 0 ;;                                   # 정상 경로 — 항상 통과
  reviewer-cgamja)      [ -f "$STATE/review-cgamja" ] && exit 0     # 스킬 경유일 때만 통과
                        context "[develop-fe] reviewer-cgamja 를 Skill 없이 Agent 로 직접 띄우고 있다 — Skill 도구로 cgamja:review-cgamja 를 부른다(workflow 2장 5번). 스킬을 거치지 않으면 blocker 수정 패스·재검사 1회 상한·fix(review) 커밋 1개 규칙이 적용되지 않는다(adr/0031)." ;;
esac

# subagent_type 이 비어 있거나(범용 에이전트) 위에 없으면, 이름/설명이 리뷰 목적인지 본다.
# prompt 는 보지 않는다 — 리뷰를 *언급* 하는 것과 리뷰를 *수행* 하는 것을 구분하기 위해서다.
d="$st $(j tool_input.description)"
grep -qiE 'review|리뷰|코드 ?검토' <<<"$d" || exit 0
grep -qiE 'retro|회고|analy|분석|audit|감사|transcript|트랜스크립트' <<<"$d" && exit 0   # 리뷰를 소재로 다루는 에이전트

context "[develop-fe] 코드 리뷰는 Agent 도구로 즉석 제작하지 않는다 — Skill 도구로 cgamja:review-cgamja(철학·SPEC 대조) 와 /code-review(버그 리뷰) 2축을 부른다(workflow 2장 5번, adr/0026). 이 Agent 호출이 리뷰 목적이면 취소하고 스킬로 대체하라."
