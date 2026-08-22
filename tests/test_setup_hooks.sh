# develop-setup 템플릿 훅(프로젝트에 복사되는 것) 회귀
B=skills/develop-setup/templates/hooks/protect-bash.sh; F=skills/develop-setup/templates/hooks/protect-files.sh
# 훅은 프로젝트 선언(.claude/cgamja.json, adr/0014)을 읽는다 — 템플릿 선언을 픽스처로
P="$TMPDIR/proj"; mkdir -p "$P/.claude"; cp skills/develop-setup/templates/cgamja.json "$P/.claude/cgamja.json"
bashcmd(){ printf '{"session_id":"h","cwd":"%s","tool_input":{"command":%s}}' "$P" "$(python3 -c 'import json,sys;print(json.dumps(sys.argv[1]))' "$1")"; }
filecmd(){ printf '{"session_id":"h","cwd":"%s","tool_input":{"file_path":"%s/%s"}}' "$P" "$P" "$1"; }
check "bash: --no-verify deny"            "deny" "$(hook $B "$(bashcmd 'git commit --no-verify -m x')")"
check "bash: inline TDD_PHASE deny"       "TDD_PHASE" "$(hook $B "$(bashcmd 'TDD_PHASE=red perl -pi -e s/a/b/ e2e/smoke.spec.ts')")"
check "bash: sed -i test file deny"       "읽기전용" "$(hook $B "$(bashcmd "sed -i '' s/a/b/ src/x.test.ts")")"
check "bash: redirect to test deny"       "읽기전용" "$(hook $B "$(bashcmd 'echo x > src/a.browser.test.tsx')")"
check "bash: read test allow"             ""     "$(hook $B "$(bashcmd 'cat e2e/smoke.spec.ts')")"
check "bash: run vitest allow"            ""     "$(hook $B "$(bashcmd 'pnpm exec vitest run src/x.test.ts')")"
check "bash: sed non-test allow"          ""     "$(hook $B "$(bashcmd "sed -i '' s/a/b/ src/x.ts")")"
check "bash: pnpm add deny"               "deny" "$(hook $B "$(bashcmd 'pnpm add lodash')")"
check "bash: gen.ts sed deny"             "생성물" "$(hook $B "$(bashcmd 'sed -i s/a/b/ src/api/client.gen.ts')")"
check "files: test edit ask (no phase)"   "\"ask\"" "$(hook $F "$(filecmd src/a.test.ts)")"
check "files: test edit allow (red)"      ""     "$(TDD_PHASE=red hook $F "$(filecmd src/a.test.ts)")"
check "files: gen.ts deny"                "생성물" "$(hook $F "$(filecmd src/api/client.gen.ts)")"
check "files: package.json deny"          "deny" "$(hook $F "$(filecmd package.json)")"
check "files: normal allow"               ""     "$(hook $F "$(filecmd src/domains/a/ui/B.tsx)")"
check "bash: cat test 2>&1 allow"         ""     "$(hook $B "$(bashcmd 'cat src/a.test.tsx 2>&1 | head')")"
check "bash: vitest test >/dev/null allow" ""    "$(hook $B "$(bashcmd 'pnpm exec vitest run e2e/x.spec.ts >/dev/null 2>&1')")"
check "bash: grep test 2>/dev/null allow"  ""    "$(hook $B "$(bashcmd 'grep -n it src/a.test.ts 2>/dev/null')")"
check "bash: append >> test deny"         "읽기전용" "$(hook $B "$(bashcmd 'echo x >> src/a.test.ts')")"
check "bash: gen.ts read with 2>&1 allow" "" "$(hook $B "$(bashcmd 'grep -n foo src/api/client.gen.ts 2>&1')")"
check "bash: gen.ts redirect still deny" "deny" "$(hook $B "$(bashcmd 'echo x > src/api/client.gen.ts')")"
# 선언 없는 프로젝트: 막지 않되 stderr에 세팅 누락 안내(fail-open이 아니라 명시적)
check "files: no declaration → allow + notice" "" "$(hook $F '{"session_id":"h","cwd":"'"$TMPDIR"'/none","tool_input":{"file_path":"'"$TMPDIR"'/none/src/a.test.ts"}}')"
# 다른 스택 선언(Jest+cypress, 계약 없음)으로 패턴이 선언을 따르는지
Q="$TMPDIR/proj2"; mkdir -p "$Q/.claude"; printf '{"commands":{"verify":"npm run ci"},"tests":{"patterns":["**/*.spec.ts","cypress/**"]},"contract":null,"protected":["package.json","Gemfile"]}' > "$Q/.claude/cgamja.json"
check "alt: .spec.ts edit ask"    "\"ask\"" "$(hook $F '{"cwd":"'"$Q"'","tool_input":{"file_path":"'"$Q"'/src/a.spec.ts"}}')"
check "alt: .test.ts not protected" ""       "$(hook $F '{"cwd":"'"$Q"'","tool_input":{"file_path":"'"$Q"'/src/a.test.ts"}}')"
check "alt: Gemfile deny"          "deny"    "$(hook $F '{"cwd":"'"$Q"'","tool_input":{"file_path":"'"$Q"'/Gemfile"}}')"
check "alt: gen.ts allowed (no contract)" "" "$(hook $F '{"cwd":"'"$Q"'","tool_input":{"file_path":"'"$Q"'/src/api/client.gen.ts"}}')"
check "alt: bash sed cypress deny" "읽기전용" "$(hook $B '{"cwd":"'"$Q"'","tool_input":{"command":"sed -i s/a/b/ cypress/e2e/x.cy.ts"}}')"
