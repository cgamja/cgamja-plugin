#!/usr/bin/env bash
# develop-setup 자가 검증 프로브 — 검증 1층(adr/0013, docs/guides/skill-verification.md §1). LLM 호출 없음, 스택 가정 없음.
#   smoke.sh check <project-dir>   .claude/cgamja.json(adr/0014)을 읽어 "강제 수단이 실제로 작동하는가"를 프로브한다
# 종료코드 0 = 전부 통과. 선언에 없는(null) 강제 수단은 "skip"으로 표시(실패 아님 — 대조표의 몫).
set -u
pass=0; fail=0; skip=0
ok()   { pass=$((pass+1)); printf "  ✓ %s\n" "$1"; }
bad()  { fail=$((fail+1)); printf "  ✗ %s\n      %s\n" "$1" "$(head -c 300 <<<"${2:-}")"; }
skp()  { skip=$((skip+1)); printf "  – %s (선언 없음, skip)\n" "$1"; }
expect_grep()   { if grep -qE -- "$2" <<<"$3"; then ok "$1"; else bad "$1" "expected /$2/ in: $3"; fi; }
expect_nogrep() { if grep -qE -- "$2" <<<"$3"; then bad "$1" "unexpected /$2/"; else ok "$1"; fi; }
expect_exit()   { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "exit $3 (want $2): $4"; fi; }
cfg() { python3 - "$1" <<'PY' 2>/dev/null
import sys,json
d=json.load(open('.claude/cgamja.json'))
for k in sys.argv[1].split('.'): d=d.get(k) if isinstance(d,dict) else None
if d is None: print('')
elif isinstance(d,list): print('\n'.join(str(x) for x in d))
else: print(d)
PY
}

check() {
  local dir="$1"; cd "$dir" || { echo "no dir $dir"; exit 1; }
  [ -f .claude/cgamja.json ] || { echo "✗ .claude/cgamja.json 없음 — /develop-setup 먼저"; exit 1; }
  local verify lint domain_root gen_first pdir
  verify="$(cfg commands.verify)"; lint="$(cfg commands.lint)"; domain_root="$(cfg domains.root)"
  pdir="$( [ -n "$domain_root" ] && dirname "$domain_root" || { [ -d src ] && echo src; } )"   # 프로브 위치 = 선언된 루트의 부모(없으면 src, 그것도 없으면 skip)
  echo "## smoke check: $dir (verify=\`$verify\`)"
  local lintfile; lintfile="$(cfg lint_file.command)"   # 파일 단위 린트(선언 lint_file.command, {file} 치환). 없으면 commands.lint
  [ -z "$lintfile" ] && lintfile="${lint} {file}"
  runlint() { bash -c "${lintfile//\{file\}/\"$1\"}" 2>&1; }

  echo "# 1 verify"
  out="$(bash -c "$verify" 2>&1)"; code=$?
  expect_exit "verify green" 0 "$code" "$(tail -20 <<<"$out")"

  echo "# 2 boundary lint actually fires (domains.root)"
  local domain; domain="$(ls "$domain_root" 2>/dev/null | head -1)"
  if [ -n "$domain_root" ] && [ -n "$domain" ] && [ -n "$lint" ]; then
    # 별칭(@/) 가정 없이 상대경로. 프로브는 domains.root 의 부모(보통 src)에 둔다 — 밖에서 단위 내부로 들어가는 import
    local pdir="$(dirname "$domain_root")"; local probe="$pdir/_cgamja_probe.ts"
    printf 'import "./%s/%s";\nexport const probe = 1;\n' "$(basename "$domain_root")" "$domain" > "$probe"
    out="$(runlint "$probe")"
    expect_grep "outside→unit internal import is an error" "boundaries|boundary|restricted|no-restricted-imports|dependency" "$out"
    rm -f "$probe"
  else skp "boundary probe"; fi

  echo "# 3 a11y lint (a11y.lint)"
  if [ -n "$(cfg a11y.lint)" ] && [ -n "$lint" ] && [ -n "$pdir" ]; then
    local ap="$pdir/_cgamja_probe"
    if [ "$(cfg platform.profile)" = native ]; then
      printf 'import { Pressable } from "react-native";\nexport const P = () => <Pressable onPress={() => {}} />;\n' > "$ap.tsx"
      out="$(runlint "$ap.tsx")"; expect_grep "touchable without role is an error" "a11y" "$out"
    elif cfg lint_file.extensions | grep -qx vue; then
      printf '<template><div><img src="x" /><div @click="f" /></div></template>\n<script setup lang="ts">const f = () => {}</script>\n' > "$ap.vue"
      out="$(runlint "$ap.vue")"
      expect_grep "img without alt is an error (vue)" "alt" "$out"
      expect_grep "div @click without key handler is an error (vue)" "key-events|click-events|a11y" "$out"
    elif cfg lint_file.extensions | grep -qx svelte; then
      printf '<img src="x" />\n<div on:click={() => {}} />\n' > "$ap.svelte"
      out="$(runlint "$ap.svelte")"
      expect_grep "a11y warnings surface as errors (svelte)" "a11y" "$out"
    else
      printf 'export const P = () => (<><img src="x" /><div onClick={() => {}} /></>);\n' > "$ap.tsx"
      out="$(runlint "$ap.tsx")"
      expect_grep "img without alt is an error" "alt" "$out"
      expect_grep "div onClick without key handler is an error" "key-events|click-events|a11y" "$out"
    fi
    rm -f "$ap".*
  else skp "a11y lint probe"; fi

  echo "# 4 contract (contract.*)"
  if [ -n "$(cfg contract.source)" ]; then
    [ -f "$(cfg contract.source)" ] && ok "contract.source exists" || bad "contract.source exists" "$(cfg contract.source)"
    if [ -n "$lint" ] && [ -n "$pdir" ]; then
      printf 'import axios from "axios";\nexport const p = () => { void axios; return fetch("/x"); };\n' > "$pdir/_cgamja_probe_http.ts"
      out="$(runlint "$pdir/_cgamja_probe_http.ts")"
      expect_grep "raw HTTP call is an error" "no-restricted-globals|restricted|fetch" "$out"
      rm -f "$pdir/_cgamja_probe_http.ts"
    fi
    gen_first="$(python3 -c "
import glob,sys
for p in sys.stdin.read().split('\n'):
    m=[f for f in glob.glob(p,recursive=True) if f.endswith(('.ts','.tsx','.js'))]
    if m: print(m[0]); break" <<<"$(cfg contract.generated)")"
    if [ -n "$gen_first" ] && [ -n "$lint" ]; then
      out="$(runlint "$gen_first")"; code=$?; expect_exit "generated client passes lint (exception path)" 0 "$code" "$out"
    else bad "contract.generated has files" "none matched"; fi
    local genpaths; genpaths="$(cfg contract.generated | sed 's#/\*\*.*##; s#/\*.*##' | sort -u | tr '\n' ' ')"
    # 사용자 작업을 지우지 않는다: 생성물·원천에 미커밋 변경이 있으면 재생성 프로브를 건너뛴다
    if ! git diff --quiet -- $genpaths "$(cfg contract.source)" 2>/dev/null; then skp "regenerate (생성물/원천에 미커밋 변경 있음 — 커밋 후 다시)"
    elif out="$(bash -c "$(cfg contract.generate)" 2>&1)"; then
      out="$(git diff --exit-code --stat -- $genpaths "$(cfg contract.source)" 2>&1)"; code=$?
      expect_exit "regenerate → no diff (deterministic)" 0 "$code" "$out"
      git checkout -q -- $genpaths "$(cfg contract.source)" 2>/dev/null   # 프로브가 만든 diff만 원복(위에서 깨끗함을 확인했다)
    else skp "regenerate (contract.generate failed: $(tail -1 <<<"$out" | head -c 120))"; git checkout -q -- $genpaths "$(cfg contract.source)" 2>/dev/null; fi
  else skp "contract probes"; fi

  echo "# 5 hooks (stdin JSON → decision, patterns from declaration)"
  hook() { printf '%s' "$2" | bash ".claude/hooks/$1" 2>/dev/null; }
  local tp; tp="$(cfg tests.patterns | head -1 | sed 's#\*\*/##g; s#\*#x#g')"   # 첫 패턴에서 예시 파일명 하나 만든다
  local tfile="$tp"; [[ "$tfile" == */* ]] || tfile="src/$tp"; [[ "$tfile" == *.* ]] || tfile="${tfile%/}/x.spec.ts"
  out="$(hook protect-files.sh "{\"cwd\":\"$PWD\",\"tool_input\":{\"file_path\":\"$PWD/$tfile\"}}")"
  expect_grep "test file edit → ask (red gate): $tfile" '"permissionDecision": ?"ask"' "$out"
  out="$(TDD_PHASE=red hook protect-files.sh "{\"cwd\":\"$PWD\",\"tool_input\":{\"file_path\":\"$PWD/$tfile\"}}")"
  expect_nogrep "test file edit with TDD_PHASE=red → allow" 'permissionDecision' "$out"
  if [ -n "$gen_first" ]; then
    hook protect-files.sh "{\"cwd\":\"$PWD\",\"tool_input\":{\"file_path\":\"$PWD/$gen_first\"}}" >/dev/null; code=$?
    expect_exit "generated file edit → deny" 2 "$code" ""; fi
  local pf; pf="$(cfg protected | head -1)"
  out="$(hook protect-files.sh "{\"cwd\":\"$PWD\",\"tool_input\":{\"file_path\":\"$PWD/$pf\"}}")"
  expect_grep "protected file edit → ask (adr/0017): $pf" '"permissionDecision": ?"ask"' "$out"
  for c in "TDD_PHASE=red perl -pi -e s/a/b/ $tfile" "echo x > $tfile" "sed -i '' s/a/b/ $tfile" 'git commit --no-verify -m x' 'pnpm add lodash' 'npm install lodash'; do
    hook protect-bash.sh "{\"cwd\":\"$PWD\",\"tool_input\":{\"command\":\"$c\"}}" >/dev/null; code=$?
    expect_exit "bash deny: $c" 2 "$code" ""
  done
  for c in "cat $tfile 2>&1" "sed -n 1,5p src/a.ts" "git diff"; do
    hook protect-bash.sh "{\"cwd\":\"$PWD\",\"tool_input\":{\"command\":\"$c\"}}" >/dev/null; code=$?
    expect_exit "bash allow: $c" 0 "$code" ""
  done
  expect_grep "settings deny has --no-verify" 'no-verify' "$(cat .claude/settings.json)"
  expect_grep "settings has Stop hook" '"Stop"' "$(cat .claude/settings.json)"

  echo "# 6 commit convention"
  if ls commitlint.config.* >/dev/null 2>&1; then
    out="$(printf 'bad message' | npx --no-install commitlint 2>&1)"; code=$?; expect_exit "commitlint rejects 'bad message'" 1 "$code" "$out"
    out="$(printf 'feat(x): 추가' | npx --no-install commitlint 2>&1)"; code=$?; expect_exit "commitlint accepts conventional + Korean" 0 "$code" "$out"
    expect_grep "commit-msg git hook installed" "lefthook|husky|commitlint" "$(cat .git/hooks/commit-msg 2>/dev/null)"
  else skp "commitlint"; fi

  echo "# 7 openspec"
  if [ -f openspec/config.yaml ]; then
    out="$(npx --no-install openspec new change probe-tmp --schema feature 2>&1 && npx --no-install openspec status --change probe-tmp 2>&1)"
    expect_grep "openspec new change (feature schema) works" "specs|tasks" "$out"; rm -rf openspec/changes/probe-tmp
  else skp "openspec"; fi

  echo "# 8 declaration & docs"
  for f in .claude/cgamja.json CLAUDE.md .claude/rules/tests.md .claude/rules/platform.md docs/adr/0001-domain-structure.md; do
    [ -f "$f" ] && ok "exists: $f" || bad "exists: $f" "missing"; done
  expect_nogrep "no unreplaced {{VAR}}" '\{\{[A-Z_]+\}\}' "$(cat CLAUDE.md .claude/rules/*.md .claude/cgamja.json 2>/dev/null)"
  expect_grep "cgamja.json ≤ 40 lines" "^ *[0-3]?[0-9]$|^ *40$" "$(wc -l < .claude/cgamja.json)"
  expect_grep "CLAUDE.md ≤ 60 lines" "^ *[0-5]?[0-9]$|^ *60$" "$(wc -l < CLAUDE.md)"

  echo "# 9 rules 무결성 (adr/0031)"
  # 산문으로만 있는 규칙은 지켜지지 않는다 — 2026-08-31 런에서 Lighthouse 규칙이 5개 change 전원
  # 미실행이었고, rules 가 정본으로 가리킨 경로에는 컴포넌트가 0개였다.
  if ls .claude/rules/*.md >/dev/null 2>&1; then
    local unmarked; unmarked="$(grep -hn '^- ' .claude/rules/*.md 2>/dev/null | grep -v '\*\*\[' | head -5)"
    [ -z "$unmarked" ] && ok "rules: 모든 불릿에 [강제 수단] 표기" \
      || bad "rules: [강제 수단] 표기 없는 불릿" "$unmarked"
    # rules 가 가리키는 저장소 경로가 실재하는가(백틱 안의 src/… 경로만)
    local missing=""; local ref
    while IFS= read -r ref; do
      [ -z "$ref" ] && continue
      [ -e "$ref" ] || missing="$missing $ref"
    done < <(grep -ho '`[a-z][a-zA-Z0-9_/.-]*/`\?' .claude/rules/*.md 2>/dev/null | tr -d '`' | grep -E '^(src|app|lib|test)/' | sort -u)
    [ -z "$missing" ] && ok "rules: 가리키는 경로가 실재" || bad "rules: 없는 경로를 가리킴" "$missing"
  else skp "rules 무결성"; fi

  echo "# 10 병렬 전제 (adr/0030)"
  local wt; wt="$(cfg parallel.worktrees)"
  if [ -z "$wt" ]; then skp "병렬(parallel 선언 없음)"; else
    [ -f .worktreeinclude ] && ok "exists: .worktreeinclude" || bad "exists: .worktreeinclude" "missing"
    grep -q "$wt" .gitignore 2>/dev/null && ok ".gitignore 가 $wt 를 무시" || bad ".gitignore 가 $wt 를 무시" "없음"
    local penv dev; penv="$(cfg parallel.port_env)"; dev="$(cfg commands.dev)"
    if [ -z "$dev" ] || ! command -v git >/dev/null; then skp "병렬 실행 프로브(commands.dev 없음)"; else
      # worktree 2개에 서로 다른 포트로 dev 를 띄워 **둘 다** 응답하는지. 판정 3(환경 싱글턴)의 실물 검사다.
      # 실패했을 때 왜인지 보이게 만든다 — dev 로그를 남기고 마지막 줄을 실패 메시지에 싣는다.
      # 진단 안 되는 프로브는 프로브가 아니다(2026-08-31: 첫 구현이 조용히 실패해 원인을 못 봤다).
      local p1=5391 p2=5392 wa="$wt/_probe_a" wb="$wt/_probe_b" okcount=0
      local logdir; logdir="$(mktemp -d)"
      git worktree add -q --detach "$wa" >/dev/null 2>&1; git worktree add -q --detach "$wb" >/dev/null 2>&1
      if [ -d "$wa" ] && [ -d "$wb" ]; then
        local pids=""
        for w in "$wa:$p1" "$wb:$p2"; do
          local d="${w%%:*}" pt="${w##*:}"
          [ -d node_modules ] && ln -sfn "$PWD/node_modules" "$d/node_modules" 2>/dev/null
          if ! printf '%s=%s\n' "${penv:-PORT}" "$pt" > "$d/.env"; then
            bad "worktree .env 쓰기" "$d/.env 를 쓰지 못했다"; fi
          # `( … ) &` 형태여야 $! 가 서브셸의 pid 다. `( … & echo $! )` 는 pid 기록이
          # 원래 디렉터리에서 실행돼 엉뚱한 곳에 파일을 남긴다(같은 날 실측).
          # 러너(npm)가 서버(vite)를 손자로 띄우므로 서브셸 pid 만 죽이면 서버가 남아 포트를
          # 계속 문다(2026-08-31 실측). setsid 는 macOS 에 없어 못 쓴다 — 대신 정리를
          # **포트 기준**으로 한다(아래). 누가 물고 있든 포트가 비면 정리된 것이다.
          ( cd "$d" && env "${penv:-PORT}=$pt" bash -c "$dev" ) >"$logdir/$pt.log" 2>&1 &
          pids="$pids $!"
        done
        local t=0
        while [ $t -lt 30 ]; do
          okcount=0
          curl -sf -o /dev/null --max-time 2 "http://localhost:$p1/" && okcount=$((okcount+1))
          curl -sf -o /dev/null --max-time 2 "http://localhost:$p2/" && okcount=$((okcount+1))
          [ "$okcount" = 2 ] && break; sleep 1; t=$((t+1))
        done
        if [ "$okcount" = 2 ]; then ok "worktree 2개가 서로 다른 포트($p1/$p2)로 동시에 응답"
        else bad "worktree 동시 실행" "응답 $okcount/2 — port_env(${penv:-PORT}) 미반영 또는 포트 충돌
  $p1: $(tail -3 "$logdir/$p1.log" 2>/dev/null | tr '\n' ' ')
  $p2: $(tail -3 "$logdir/$p2.log" 2>/dev/null | tr '\n' ' ')"; fi
        # 3단 정리: 서브셸 → 그 자식 → 그래도 포트를 물고 있으면 포트 기준으로.
        # 마지막 단이 실질적인 보증이다 — 다음 실행이 같은 포트를 쓰므로 여기서 안 비우면
        # 그다음 프로브가 "포트 충돌"로 거짓 빨강을 낸다.
        for pid in $pids; do pkill -P "$pid" 2>/dev/null; kill "$pid" 2>/dev/null; done
        sleep 1
        for pt in $p1 $p2; do
          lp="$(lsof -ti "tcp:$pt" 2>/dev/null)"; [ -n "$lp" ] && kill -9 $lp 2>/dev/null; done
        sleep 1
        git worktree remove --force "$wa" 2>/dev/null; git worktree remove --force "$wb" 2>/dev/null
        rm -rf "$wa" "$wb" "$logdir"; git worktree prune 2>/dev/null
      else bad "worktree 생성" "git worktree add 실패"; fi
    fi
  fi

  echo "# 11 스택 ↔ SPEC 대조 (adr/0032)"
  # 빈 레포에서 스택의 원천은 SPEC 이다. SPEC 과 다른 선택은 **docs/adr/ 에 기록해야** 완료다.
  local spec="$(dirname "$0")/../../../docs/spec/WEB-SPEC.md"
  if [ ! -f "$spec" ] || [ ! -f package.json ]; then skp "스택↔SPEC(웹 SPEC 또는 매니페스트 없음)"; else
    local undocumented=""
    while IFS= read -r tok; do
      [ -z "$tok" ] && continue
      grep -qi "\"$tok" package.json && continue                       # 의존성에 있음 = 준수
      grep -qi "$tok" package.json && continue
      grep -rliq -- "$tok" docs/adr/ 2>/dev/null && continue           # 이탈이지만 ADR 있음 = 완료
      undocumented="$undocumented $tok"
    done < <(sed -n 's/^\*\*\([A-Za-z][A-Za-z0-9.@/-]*\).*/\1/p' "$spec" | sort -u)
    [ -z "$undocumented" ] && ok "SPEC 이탈이 없거나 전부 docs/adr/ 에 기록됨" \
      || bad "SPEC 이탈인데 docs/adr/ 기록 없음" "$undocumented — WEB-SPEC 머리말: '이 스펙에서 벗어날 때는 해당 프로젝트의 adr/에 기록한다'"
    if [ -f tsconfig.app.json ] || [ -f tsconfig.json ]; then
      grep -qs '"strict"[[:space:]]*:[[:space:]]*true' tsconfig*.json && ok "TypeScript strict" \
        || bad "TypeScript strict" "SPEC 첫 항목이 'TypeScript 5.x (strict)' 인데 strict 가 켜져 있지 않다"
    fi
  fi

  echo; echo "smoke check: passed $pass, failed $fail, skipped $skip"; [ "$fail" -eq 0 ]
}

case "${1:-}" in
  check) check "${2:?project dir}";;
  *) sed -n 2,5p "$0"; exit 1;;
esac
