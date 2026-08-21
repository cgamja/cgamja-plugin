# develop-setup 템플릿 훅(프로젝트에 복사되는 것) 회귀
B=skills/develop-setup/templates/hooks/protect-bash.sh; F=skills/develop-setup/templates/hooks/protect-files.sh
bashcmd(){ printf '{"session_id":"h","tool_input":{"command":%s}}' "$(python3 -c 'import json,sys;print(json.dumps(sys.argv[1]))' "$1")"; }
filecmd(){ printf '{"session_id":"h","tool_input":{"file_path":"%s"}}' "$1"; }
check "bash: --no-verify deny"            "deny" "$(hook $B "$(bashcmd 'git commit --no-verify -m x')")"
check "bash: inline TDD_PHASE deny"       "TDD_PHASE" "$(hook $B "$(bashcmd 'TDD_PHASE=red perl -pi -e s/a/b/ e2e/smoke.spec.ts')")"
check "bash: sed -i test file deny"       "읽기전용" "$(hook $B "$(bashcmd "sed -i '' s/a/b/ src/x.test.ts")")"
check "bash: redirect to test deny"       "읽기전용" "$(hook $B "$(bashcmd 'echo x > src/a.browser.test.tsx')")"
check "bash: read test allow"             ""     "$(hook $B "$(bashcmd 'cat e2e/smoke.spec.ts')")"
check "bash: run vitest allow"            ""     "$(hook $B "$(bashcmd 'pnpm exec vitest run src/x.test.ts')")"
check "bash: sed non-test allow"          ""     "$(hook $B "$(bashcmd "sed -i '' s/a/b/ src/x.ts")")"
check "bash: pnpm add deny"               "deny" "$(hook $B "$(bashcmd 'pnpm add lodash')")"
check "bash: gen.ts sed deny"             "생성물" "$(hook $B "$(bashcmd 'sed -i s/a/b/ src/api/client.gen.ts')")"
check "files: test edit ask (no phase)"   "\"ask\"" "$(hook $F "$(filecmd /p/src/a.test.ts)")"
check "files: test edit allow (red)"      ""     "$(TDD_PHASE=red hook $F "$(filecmd /p/src/a.test.ts)")"
check "files: gen.ts deny"                "생성물" "$(hook $F "$(filecmd /p/src/api/client.gen.ts)")"
check "files: package.json deny"          "deny" "$(hook $F "$(filecmd /p/package.json)")"
check "files: normal allow"               ""     "$(hook $F "$(filecmd /p/src/domains/a/ui/B.tsx)")"
check "bash: cat test 2>&1 allow"         ""     "$(hook $B "$(bashcmd 'cat src/a.test.tsx 2>&1 | head')")"
check "bash: vitest test >/dev/null allow" ""    "$(hook $B "$(bashcmd 'pnpm exec vitest run e2e/x.spec.ts >/dev/null 2>&1')")"
check "bash: grep test 2>/dev/null allow"  ""    "$(hook $B "$(bashcmd 'grep -n it src/a.test.ts 2>/dev/null')")"
check "bash: append >> test deny"         "읽기전용" "$(hook $B "$(bashcmd 'echo x >> src/a.test.ts')")"
check "bash: gen.ts read with 2>&1 allow" "" "$(hook $B '{"session_id":"t","tool_input":{"command":"grep -n foo src/api/client.gen.ts 2>&1"}}')"
check "bash: gen.ts redirect still deny" "deny" "$(hook $B '{"session_id":"t","tool_input":{"command":"echo x > src/api/client.gen.ts"}}')"
