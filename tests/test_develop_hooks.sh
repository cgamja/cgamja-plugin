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
check "setup_check silent when complete" "" "$(hook $C '{"session_id":"t","cwd":"'$E'","tool_input":{}}')"
R=skills/develop-fe/hooks/review_nudge.sh
check "review nudge on Agent review" "ce-code-review" "$(hook $R '{"session_id":"t","tool_input":{"description":"Code review of todos","prompt":"review the diff"}}')"
check "no nudge on explore agent"   ""     "$(hook $R '{"session_id":"t","tool_input":{"description":"Explore codebase","prompt":"find usages"}}')"
check "setup_check bypass warn"     "승인자" "$(hook $C '{"session_id":"t2","cwd":"'$E'","permission_mode":"bypassPermissions","tool_input":{}}')"
check "setup_check default no warn" ""     "$(hook $C '{"session_id":"t3","cwd":"'$E'","permission_mode":"default","tool_input":{}}')"
N=skills/develop-fe/hooks/test_nudge.sh
check "test nudge without test-fe"  "test-fe" "$(hook $N '{"session_id":"tn1","tool_input":{"file_path":"src/a/B.browser.test.tsx"}}')"
check "test nudge non-test silent"  ""        "$(hook $N '{"session_id":"tn1","tool_input":{"file_path":"src/a/B.tsx"}}')"
hook $G '{"session_id":"tn2","tool_input":{"skill":"cgamja:test-fe"}}' >/dev/null
check "test nudge silent after test-fe" "" "$(hook $N '{"session_id":"tn2","tool_input":{"file_path":"e2e/x.spec.ts"}}')"
