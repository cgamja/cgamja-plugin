#!/usr/bin/env bash
# develop-setup 자가 검증 프로브 — 검증 1층(adr/0013, references/skill-verification.md §1). LLM 호출 없음, 스택 가정 없음.
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
  local verify lint domain_root gen_first
  verify="$(cfg commands.verify)"; lint="$(cfg commands.lint)"; domain_root="$(cfg domains.root)"
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
    mkdir -p src/shared/lib
    printf 'import "@/%s/%s";\nexport const probe = 1;\n' "${domain_root#src/}" "$domain" > src/shared/lib/_probe.ts
    out="$(runlint src/shared/lib/_probe.ts)"
    expect_grep "shared→domain import is an error" "boundaries|boundary|restricted|no-restricted-imports|dependency" "$out"
    rm -f src/shared/lib/_probe.ts
  else skp "boundary probe"; fi

  echo "# 3 a11y lint (a11y.lint)"
  if [ -n "$(cfg a11y.lint)" ] && [ -n "$lint" ]; then
    mkdir -p src/shared/lib
    if [ "$(cfg platform.profile)" = native ]; then
      printf 'import { Pressable } from "react-native";\nexport const P = () => <Pressable onPress={() => {}} />;\n' > src/shared/lib/_probe.tsx
      out="$(runlint src/shared/lib/_probe.tsx)"; expect_grep "touchable without role is an error" "a11y" "$out"
    else
      printf 'export const P = () => (<><img src="x" /><div onClick={() => {}} /></>);\n' > src/shared/lib/_probe.tsx
      out="$(runlint src/shared/lib/_probe.tsx)"
      expect_grep "img without alt is an error" "alt" "$out"
      expect_grep "div onClick without key handler is an error" "key-events|click-events|a11y" "$out"
    fi
    rm -f src/shared/lib/_probe.tsx
  else skp "a11y lint probe"; fi

  echo "# 4 contract (contract.*)"
  if [ -n "$(cfg contract.source)" ]; then
    [ -f "$(cfg contract.source)" ] && ok "contract.source exists" || bad "contract.source exists" "$(cfg contract.source)"
    if [ -n "$lint" ]; then
      mkdir -p src/shared/lib
      printf 'import axios from "axios";\nexport const p = () => { void axios; return fetch("/x"); };\n' > src/shared/lib/_probe.ts
      out="$(runlint src/shared/lib/_probe.ts)"
      expect_grep "raw HTTP call is an error" "no-restricted-globals|restricted|fetch" "$out"
      rm -f src/shared/lib/_probe.ts
    fi
    gen_first="$(python3 -c "
import glob,sys
for p in sys.stdin.read().split('\n'):
    m=[f for f in glob.glob(p,recursive=True) if f.endswith(('.ts','.tsx','.js'))]
    if m: print(m[0]); break" <<<"$(cfg contract.generated)")"
    if [ -n "$gen_first" ] && [ -n "$lint" ]; then
      out="$(runlint "$gen_first")"; code=$?; expect_exit "generated client passes lint (exception path)" 0 "$code" "$out"
    else bad "contract.generated has files" "none matched"; fi
    out="$(bash -c "$(cfg contract.generate)" 2>&1 && git diff --exit-code --stat -- $(cfg contract.generated | sed 's#/\*\*.*##' | sort -u | tr '\n' ' ') 2>&1)"; code=$?
    expect_exit "regenerate → no diff (deterministic)" 0 "$code" "$out"
  else skp "contract probes"; fi

  echo "# 5 hooks (stdin JSON → decision, patterns from declaration)"
  hook() { printf '%s' "$2" | bash ".claude/hooks/$1" 2>/dev/null; }
  local tp; tp="$(cfg tests.patterns | head -1 | sed 's#\*\*/##; s#\*#x#g')"   # 첫 패턴에서 예시 파일명 하나 만든다
  local tfile="src/$tp"; [[ "$tfile" == *.* ]] || tfile="$(cfg tests.patterns | head -1 | sed 's#/\*\*##; s#\*\*/##')/x.spec.ts"
  out="$(hook protect-files.sh "{\"cwd\":\"$PWD\",\"tool_input\":{\"file_path\":\"$PWD/$tfile\"}}")"
  expect_grep "test file edit → ask (red gate): $tfile" '"permissionDecision": ?"ask"' "$out"
  out="$(TDD_PHASE=red hook protect-files.sh "{\"cwd\":\"$PWD\",\"tool_input\":{\"file_path\":\"$PWD/$tfile\"}}")"
  expect_nogrep "test file edit with TDD_PHASE=red → allow" 'permissionDecision' "$out"
  if [ -n "$gen_first" ]; then
    hook protect-files.sh "{\"cwd\":\"$PWD\",\"tool_input\":{\"file_path\":\"$PWD/$gen_first\"}}" >/dev/null; code=$?
    expect_exit "generated file edit → deny" 2 "$code" ""; fi
  local pf; pf="$(cfg protected | head -1)"
  hook protect-files.sh "{\"cwd\":\"$PWD\",\"tool_input\":{\"file_path\":\"$PWD/$pf\"}}" >/dev/null; code=$?
  expect_exit "protected file edit → deny: $pf" 2 "$code" ""
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

  echo; echo "smoke check: passed $pass, failed $fail, skipped $skip"; [ "$fail" -eq 0 ]
}

case "${1:-}" in
  check) check "${2:?project dir}";;
  *) sed -n 2,5p "$0"; exit 1;;
esac
