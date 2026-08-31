# ADR의 결정이 실제 스킬 문서·훅·템플릿에 남아 있는가.
# 왜 있나: adr/0031 — 산문으로만 있는 규칙은 지켜지지 않는다. ADR도 마찬가지다. ADR을 쓰고
# 문서에 반영한 뒤, 다음 리팩터에서 그 문단이 조용히 사라지면 결정은 없던 일이 된다.
# 여기서 고정하는 것은 **결정의 존재**지 문장이 아니다 — 표현이 바뀌면 이 키워드도 같이 고친다.
W=skills/develop-fe/workflow.md
S=skills/develop-setup/SKILL.md
R=skills/retro-fe/SKILL.md

# adr/0029 — 게이트 기본값은 전진, 정지는 열거된 5종만
check "0029: workflow 에 정지 허용 목록"      "정지 허용 목록"   "$(cat $W)"
check "0029: workflow 에 가정 3줄 형식"        "되돌리는 비용"     "$(cat $W)"
check "0029: 2-D 는 허가 없이 진입"            "허가를 묻지 않고"  "$(cat $W)"

# adr/0030 — 병렬 전제는 develop-setup 이 깐다
check "0030: 2-P 진입 전제 체크"               "전제 체크"         "$(cat $W)"
check "0030: setup 이 병렬 전제를 만든다"      "병렬 전제"         "$(cat $S)"
check "0030: strictPort 요구"                  "strictPort"        "$(cat $S)"

# adr/0031 — 산문 규칙 금지
check "0031: rules 에 강제 수단 표기 지시"     "강제 수단"         "$(cat $S)"
check "0031: 커밋 수 경고가 pre-push 에"       "상한"              "$(cat skills/develop-fe/templates/git-hooks/pre-push)"
check "0031: 회고가 산출물↔rules 를 본다"      "산출물 ↔ rules"    "$(cat $R)"
check "0031: 회고가 정지 원인을 분류"          "정지 원인 분류"    "$(cat $R)"

# adr/0032 — 빈 레포의 스택 원천은 SPEC
check "0032: setup §0 이 SPEC 을 원천으로"     "WEB-SPEC"          "$(cat $S)"
check "0032: 대조표에 스택 축"                 "스택 축"           "$(cat $S)"

# 훅에 실제로 반영됐는가 (문서만 고치고 훅을 안 고치는 것이 가장 흔한 이탈)
check "0031: review_nudge 가 correctness 를 예외" "reviewer-correctness" "$(cat skills/develop-fe/hooks/review_nudge.sh)"
check "0031: review_nudge 가 subagent_type 판정"  "subagent_type"        "$(cat skills/develop-fe/hooks/review_nudge.sh)"
check "0030: protect-bash 가 worktree 사본 제외"  "worktree"             "$(cat skills/develop-setup/templates/hooks/protect-bash.sh)"
check "0030: smoke 에 병렬 프로브"                "병렬 전제"            "$(cat skills/develop-setup/scripts/smoke.sh)"
check "0031: smoke 에 rules 무결성 프로브"        "rules 무결성"         "$(cat skills/develop-setup/scripts/smoke.sh)"
check "0032: smoke 에 스택↔SPEC 프로브"           "스택 ↔ SPEC"          "$(cat skills/develop-setup/scripts/smoke.sh)"
