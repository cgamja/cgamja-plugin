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
check "files: package.json ask (adr/0017)" "\"ask\"" "$(hook $F "$(filecmd package.json)")"
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
check "alt: Gemfile ask (adr/0017)" "\"ask\"" "$(hook $F '{"cwd":"'"$Q"'","tool_input":{"file_path":"'"$Q"'/Gemfile"}}')"
check "alt: gen.ts allowed (no contract)" "" "$(hook $F '{"cwd":"'"$Q"'","tool_input":{"file_path":"'"$Q"'/src/api/client.gen.ts"}}')"
check "alt: bash sed cypress deny" "읽기전용" "$(hook $B '{"cwd":"'"$Q"'","tool_input":{"command":"sed -i s/a/b/ cypress/e2e/x.cy.ts"}}')"
# CodeRabbit PR#1: npm 옵션 우회, 인터프리터 일회성 실행, lockfile 설치는 허용
check "bash: npm install --save pkg deny" "deny" "$(hook $B "$(bashcmd 'npm install --save lodash')")"
check "bash: npm i -D pkg deny"          "deny" "$(hook $B "$(bashcmd 'npm i -D lodash')")"
check "bash: pnpm add -D pkg deny"       "deny" "$(hook $B "$(bashcmd 'pnpm add -D vitest')")"
check "bash: pnpm install (lockfile) allow" "" "$(hook $B "$(bashcmd 'pnpm install --frozen-lockfile')")"
check "bash: npm ci allow"               ""     "$(hook $B "$(bashcmd 'npm ci')")"
check "bash: python -c writes cgamja.json deny" "deny" "$(hook $B "$(bashcmd "python3 -c 'from pathlib import Path; Path(\".claude/cgamja.json\").write_text(\"{}\")'")")"
check "bash: node -e writes test file deny"     "deny" "$(hook $B "$(bashcmd "node -e \"require('fs').writeFileSync('src/a.test.ts','')\"")")"
check "bash: node -e harmless allow"            ""     "$(hook $B "$(bashcmd "node -e \"console.log(1)\"")")"
# adr/0017: 읽기/쓰기 구분 — 조회·읽기 실행은 허용, 설정·쓰기 실행만 deny
check "bash: hooksPath query allow"       ""     "$(hook $B "$(bashcmd 'git fetch origin && git status && git config core.hooksPath')")"
check "bash: hooksPath --get allow"       ""     "$(hook $B "$(bashcmd 'git config --get core.hooksPath 2>/dev/null')")"
check "bash: hooksPath set deny"          "deny" "$(hook $B "$(bashcmd 'git config core.hooksPath /dev/null')")"
check "bash: hooksPath -c inline deny"    "deny" "$(hook $B "$(bashcmd 'git -c core.hooksPath=/tmp/x commit -m y')")"
check "bash: python -c reads cgamja.json allow" "" "$(hook $B "$(bashcmd "python3 -c \"import json;print(json.load(open('.claude/cgamja.json')))\"")")"
check "bash: node -e reads package.json allow"  "" "$(hook $B "$(bashcmd "node -e \"const p=require('./package.json'); console.log(p.scripts?.verify)\"")")"
check "bash: expo install deny"           "deny" "$(hook $B "$(bashcmd 'npx expo install expo-image-picker')")"
# adr/0023: heredoc 커밋 메시지·세그먼트 판정 — 오탐 2종 회귀
check "bash: commit heredoc naming test file allow" "" "$(hook $B "$(bashcmd 'git add src/a.test.ts && git commit -m "$(cat <<EOF
test(a): a.test.ts 갱신
EOF
)"')")"
check "bash: write src + run test in next segment allow" "" "$(hook $B "$(bashcmd "perl -pi -e s/a/b/ src/x.ts && pnpm exec vitest run src/x.test.ts")")"
check "bash: sed test file same segment still deny" "읽기전용" "$(hook $B "$(bashcmd "sed -i '' s/a/b/ src/x.test.ts && echo done")")"
check "bash: heredoc redirect to test still deny" "읽기전용" "$(hook $B "$(bashcmd 'cat <<EOF > src/a.test.ts
x
EOF')")"
# adr/0017: 커밋된 적 없는 스크래치 테스트 rm 허용, 추적 중이면 deny
(cd "$P" && git init -q 2>/dev/null; git -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1 || true)
mkdir -p "$P/src"; echo x > "$P/src/tracked.test.ts"
(cd "$P" && git add src/tracked.test.ts && git -c user.email=t@t -c user.name=t commit -qm t >/dev/null 2>&1)
check "bash: rm untracked scratch test allow" ""  "$(hook $B "$(bashcmd 'rm src/debug-step3.test.tsx')")"
check "bash: rm tracked test deny"        "deny" "$(hook $B "$(bashcmd 'rm src/tracked.test.ts')")"
# adr/0017: verify-on-stop handoff 마커 — 1회 통과 + 사유 노출
S=skills/develop-setup/templates/hooks/verify-on-stop.sh
(cd "$P" && printf '{"commands":{"verify":"false"},"tests":{"patterns":["**/*.test.*"]},"protected":["package.json"]}' > .claude/cgamja.json && echo y > src/changed.ts)
mkdir -p "$P/.claude/state"; echo "knip: 보호 파일이 원인" > "$P/.claude/state/handoff"
out="$(printf '{"session_id":"h","cwd":"%s"}' "$P" | bash $S 2>&1)"; code=$?
check "stop: handoff → pass with reason"  "넘김" "$out"
check "stop: handoff consumed"            ""     "$(ls "$P/.claude/state/handoff" 2>/dev/null)"
out="$(printf '{"session_id":"h","cwd":"%s"}' "$P" | bash $S 2>&1)"; code=$?
check "stop: verify fail blocks (exit 2)" "2"    "$code"
cp skills/develop-setup/templates/cgamja.json "$P/.claude/cgamja.json"
# adr/0018: red 게이트 세션당 1회 — 첫 편집 ask → 승인(편집 성공 = red-mark) → 같은 세션은 묻지 않음
M=skills/develop-setup/templates/hooks/red-mark.sh
rm -f "$P/.claude/state/red-approved-h"
check "files: first test edit ask (adr/0018)" "\"ask\"" "$(hook $F "$(filecmd src/a.test.ts)")"
hook $M "$(filecmd src/a.test.ts)" >/dev/null
check "red-mark: marker written"          "red-approved-h" "$(ls "$P/.claude/state/" 2>/dev/null)"
check "files: same session test edit allow" ""   "$(hook $F "$(filecmd src/b.test.ts)")"
check "files: other session still ask"    "\"ask\"" "$(hook $F '{"session_id":"h2","cwd":"'"$P"'","tool_input":{"file_path":"'"$P"'/src/c.test.ts"}}')"
hook $M '{"session_id":"h3","cwd":"'"$P"'","tool_input":{"file_path":"'"$P"'/src/n.ts"}}' >/dev/null
check "red-mark: non-test file no marker" ""     "$(ls "$P/.claude/state/" 2>/dev/null | grep h3)"
