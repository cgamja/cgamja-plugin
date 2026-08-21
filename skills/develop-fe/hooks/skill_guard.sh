#!/usr/bin/env bash
# PreToolUse (Skill): SKILL.md '절대 하지 않는 것'의 기계 버전. adr/0001, adr/0007
#  - ce-plan, lfg             → deny (OpenSpec change와 플랜이 두 군데 생김)
#  - ce-work                  → mode:return-to-caller 없으면 deny (실험 B 경로만)
#  - ce-code-review           → args에 plan: 없으면 deny (OpenSpec 포맷을 못 읽어 요구사항 누락 검사가 조용히 빠짐)
# 끄기: 세션 시작 전 env DEVELOP_SKILL_GUARD=off
source "$(dirname "$0")/_lib.sh"
[ "${DEVELOP_SKILL_GUARD:-on}" = "off" ] && exit 0
skill="$(j tool_input.skill)"; args="$(j tool_input.args)"
name="${skill##*:}"   # "compound-engineering:ce-plan" → "ce-plan"
case "$name" in
  ce-plan|lfg)
    deny "[develop-fe] /$name 은 이 워크플로우에서 쓰지 않습니다 — OpenSpec change가 스펙·tasks의 단일 원천이라 플랜이 두 군데 생깁니다(adr/0001). Tier-2는 \`/opsx:new\` 로 change를 만들고, Tier-3는 \`/ce-brainstorm\` 결과를 proposal 입력으로 쓰세요.";;
  ce-work)
    grep -q 'mode:return-to-caller' <<<"$args" || deny "[develop-fe] /ce-work 기본 호출 금지 — 구현 루프는 \`/opsx:apply\`. 실험 B(adr/0001)로 쓸 때만 \`mode:return-to-caller <plan path>\` 인자를 넘기세요.";;
  ce-code-review)
    grep -q 'plan:' <<<"$args" || deny "[develop-fe] /ce-code-review 는 스펙 경로 없이 부르면 OpenSpec 포맷을 못 읽어 Requirements Completeness 검사가 조용히 빠집니다(adr/0001). \`plan:openspec/changes/<slug>/specs/<cap>/spec.md\` 와 힌트('각 ### Requirement:/#### Scenario:를 요구사항으로 취급')를 args에 넣어 다시 호출하세요.";;
esac
exit 0
