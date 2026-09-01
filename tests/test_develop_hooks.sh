G=skills/develop-fe/hooks/skill_guard.sh; C=skills/develop-fe/hooks/setup_check.sh
check "ce-plan deny"        "deny" "$(hook $G '{"session_id":"t","tool_input":{"skill":"compound-engineering:ce-plan","args":"x"}}')"
check "lfg deny"            "deny" "$(hook $G '{"session_id":"t","tool_input":{"skill":"lfg"}}')"
check "ce-work bare deny"   "deny" "$(hook $G '{"session_id":"t","tool_input":{"skill":"compound-engineering:ce-work","args":"docs/plans/a.md"}}')"
check "ce-work rtc allow"   ""     "$(hook $G '{"session_id":"t","tool_input":{"skill":"compound-engineering:ce-work","args":"mode:return-to-caller x/tasks.md"}}')"
check "review bare deny"    "plan:" "$(hook $G '{"session_id":"t","tool_input":{"skill":"compound-engineering:ce-code-review"}}')"
check "review plan allow"   ""     "$(hook $G '{"session_id":"t","tool_input":{"skill":"compound-engineering:ce-code-review","args":"plan:openspec/changes/a/specs/b/spec.md"}}')"
check "other skill allow"   ""     "$(hook $G '{"session_id":"t","tool_input":{"skill":"compound-engineering:ce-brainstorm"}}')"
check "guard off env"       ""     "$(DEVELOP_SKILL_GUARD=off hook $G '{"session_id":"t","tool_input":{"skill":"lfg"}}')"
E=$(mktemp -d); check "setup_check warns on empty dir" "세팅 누락" "$(hook $C '{"session_id":"t","cwd":"'$E'","tool_input":{}}')"
mkdir -p $E/.claude/rules $E/openspec; echo '{"scripts":{"verify":"x"}}' > $E/package.json; touch $E/openspec/config.yaml $E/.claude/rules/a.md; echo '{"hooks":{"Stop":[]}}' > $E/.claude/settings.json
check "setup_check warns without declaration" "cgamja.json" "$(hook $C '{"session_id":"t","cwd":"'$E'","tool_input":{}}')"
echo '{"commands":{"verify":"x"}}' > $E/.claude/cgamja.json
check "setup_check silent when complete" "" "$(hook $C '{"session_id":"t","cwd":"'$E'","tool_input":{}}')"
R=skills/develop-fe/hooks/review_nudge.sh
check "review nudge on Agent review" "review-cgamja" "$(hook $R '{"session_id":"t","tool_input":{"description":"Code review of todos","prompt":"review the diff"}}')"
# adr/0031 — 2026-08-31 회고: 오탐 누적 10회와 미탐이 한 줄(예외목록)에서 나왔다. 판정은 subagent_type 기준.
check "no nudge: reviewer-correctness (L1 정상 경로)" "" "$(hook $R '{"session_id":"rn1","tool_input":{"subagent_type":"cgamja:reviewer-correctness","description":"L1 정확성 리뷰","prompt":"diff 검토"}}')"
check "NUDGE: reviewer-cgamja 스킬 없이 직접"  "Skill 없이" "$(hook $R '{"session_id":"rn2","tool_input":{"subagent_type":"cgamja:reviewer-cgamja","description":"철학 리뷰","prompt":"docs/spec 대조"}}')"
hook skills/develop-fe/hooks/skill_guard.sh '{"session_id":"rn3","tool_input":{"skill":"cgamja:review-cgamja"}}' >/dev/null
check "no nudge: reviewer-cgamja 스킬 경유"    ""     "$(hook $R '{"session_id":"rn3","tool_input":{"subagent_type":"cgamja:reviewer-cgamja","description":"철학 리뷰","prompt":"docs/spec 대조"}}')"
check "no nudge: 회고 분석 에이전트(리뷰 언급)" ""     "$(hook $R '{"session_id":"rn4","tool_input":{"description":"Analyze session transcript","prompt":"리뷰 2축이 몇 번 돌았는지 세어라"}}')"
check "no nudge: 프롬프트에만 리뷰"            ""     "$(hook $R '{"session_id":"rn5","tool_input":{"subagent_type":"general-purpose","description":"Explore codebase","prompt":"review-cgamja 스킬이 어디서 호출되나 찾아라"}}')"
check "no nudge on explore agent"   ""     "$(hook $R '{"session_id":"t","tool_input":{"description":"Explore codebase","prompt":"find usages"}}')"
check "setup_check bypass warn"     "승인자" "$(hook $C '{"session_id":"t2","cwd":"'$E'","permission_mode":"bypassPermissions","tool_input":{}}')"
# adr/0023: advisory 경고는 세션당 1회 — 같은 세션 두 번째 호출은 무경고
check "setup_check bypass warn once" ""     "$(hook $C '{"session_id":"t2","cwd":"'$E'","permission_mode":"bypassPermissions","tool_input":{}}')"
check "setup_check default no warn" ""     "$(hook $C '{"session_id":"t3","cwd":"'$E'","permission_mode":"default","tool_input":{}}')"

# 훅 드리프트: 정수 마커가 아니라 내용으로 본다. 옛 로직은 두 겹으로 깨져 있었다 —
# (1) `# cgamja-hooks v<N>` 을 손으로 올려야 해서 2026-09-01 세 번의 수정에서 안 올랐고
# (2) 템플릿 경로가 상대경로라 `cd "$d"` 뒤에 해석되지 않아 애초에 비교가 안 됐다.
D=$(mktemp -d); mkdir -p $D/.claude/rules $D/.claude/hooks $D/openspec
echo '{"scripts":{"verify":"x"}}' > $D/package.json; touch $D/openspec/config.yaml $D/.claude/rules/a.md
echo '{"hooks":{"Stop":[]}}' > $D/.claude/settings.json; echo '{"commands":{"verify":"x"}}' > $D/.claude/cgamja.json
cp skills/develop-setup/templates/hooks/*.sh $D/.claude/hooks/
check "drift: 최신 사본이면 조용" "" "$(hook $C '{"session_id":"d1","cwd":"'$D'","tool_input":{}}')"
# 마커는 그대로 두고 내용만 바꾼다 — 옛 로직이 못 잡던 바로 그 형태
printf '\n# drifted\n' >> $D/.claude/hooks/protect-bash.sh
check "drift: 마커 같아도 내용 다르면 경고" "플러그인과 다르다" "$(hook $C '{"session_id":"d2","cwd":"'$D'","tool_input":{}}')"
check "drift: 어느 파일인지 지목" "protect-bash.sh" "$(hook $C '{"session_id":"d3","cwd":"'$D'","tool_input":{}}')"
rm $D/.claude/hooks/red-mark.sh
check "drift: 없는 훅도 잡는다" "red-mark.sh(없음)" "$(hook $C '{"session_id":"d4","cwd":"'$D'","tool_input":{}}')"
check "drift: /develop-update 로 안내" "develop-update" "$(hook $C '{"session_id":"d5","cwd":"'$D'","tool_input":{}}')"
N=skills/develop-fe/hooks/test_nudge.sh
check "test nudge without tdd skill" "test-driven-development" "$(hook $N '{"session_id":"tn1","tool_input":{"file_path":"src/a/B.browser.test.tsx"}}')"
check "test nudge non-test silent"  ""        "$(hook $N '{"session_id":"tn1","tool_input":{"file_path":"src/a/B.tsx"}}')"
hook $G '{"session_id":"tn2","tool_input":{"skill":"cgamja:test-driven-development"}}' >/dev/null
check "test nudge silent after tdd skill" "" "$(hook $N '{"session_id":"tn2","tool_input":{"file_path":"e2e/x.spec.ts"}}')"
