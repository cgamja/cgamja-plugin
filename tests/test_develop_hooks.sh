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
check "no nudge on reviewer-cgamja agent" "" "$(hook $R '{"session_id":"t","tool_input":{"subagent_type":"reviewer-cgamja","description":"철학 리뷰","prompt":"docs/spec 대조"}}')"
check "no nudge on explore agent"   ""     "$(hook $R '{"session_id":"t","tool_input":{"description":"Explore codebase","prompt":"find usages"}}')"
check "setup_check bypass warn"     "승인자" "$(hook $C '{"session_id":"t2","cwd":"'$E'","permission_mode":"bypassPermissions","tool_input":{}}')"
# adr/0023: advisory 경고는 세션당 1회 — 같은 세션 두 번째 호출은 무경고
check "setup_check bypass warn once" ""     "$(hook $C '{"session_id":"t2","cwd":"'$E'","permission_mode":"bypassPermissions","tool_input":{}}')"
check "setup_check default no warn" ""     "$(hook $C '{"session_id":"t3","cwd":"'$E'","permission_mode":"default","tool_input":{}}')"
N=skills/develop-fe/hooks/test_nudge.sh
check "test nudge without tdd skill" "test-driven-development" "$(hook $N '{"session_id":"tn1","tool_input":{"file_path":"src/a/B.browser.test.tsx"}}')"
check "test nudge non-test silent"  ""        "$(hook $N '{"session_id":"tn1","tool_input":{"file_path":"src/a/B.tsx"}}')"
hook $G '{"session_id":"tn2","tool_input":{"skill":"cgamja:test-driven-development"}}' >/dev/null
check "test nudge silent after tdd skill" "" "$(hook $N '{"session_id":"tn2","tool_input":{"file_path":"e2e/x.spec.ts"}}')"
