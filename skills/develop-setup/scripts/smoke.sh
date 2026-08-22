#!/usr/bin/env bash
# develop-setup 템플릿 스모크 — 검증 1층(adr/0013, references/skill-verification.md §1). LLM 호출 없음.
#   smoke.sh check <project-dir>            세팅된 프로젝트에서 SKILL.md §3 자가 검증을 결정적으로 실행
#   smoke.sh setup <vite|next|expo> <dir>   스캐폴드 + 템플릿 적용(기본값 치환) + 설치 → 이어서 check
# 종료코드 0 = 전부 통과. 각 항목은 "무엇을 / 기대 / 결과"로 출력.
set -u
PLUGIN="$(cd "$(dirname "$0")/../../.." && pwd)"
TPL="$PLUGIN/skills/develop-setup/templates"
pass=0; fail=0
ok()   { pass=$((pass+1)); printf "  ✓ %s\n" "$1"; }
bad()  { fail=$((fail+1)); printf "  ✗ %s\n      %s\n" "$1" "$(head -c 300 <<<"${2:-}")"; }
expect_grep() { # name, pattern, text
  if grep -qE -- "$2" <<<"$3"; then ok "$1"; else bad "$1" "expected /$2/ in: $3"; fi; }
expect_nogrep() { if grep -qE -- "$2" <<<"$3"; then bad "$1" "unexpected /$2/"; else ok "$1"; fi; }
expect_exit() { # name, expected-code, actual-code, output
  if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "exit $3 (want $2): $4"; fi; }

# ---------- check ----------
check() {
  local dir="$1"; cd "$dir" || { echo "no dir $dir"; exit 1; }
  local PM=pnpm; [ -f yarn.lock ] && PM=yarn; [ -f package-lock.json ] && PM=npm
  local platform=vite
  grep -q '"expo"' package.json && platform=expo
  grep -q '"next"' package.json && platform=next
  local domain; domain="$(ls src/domains 2>/dev/null | head -1)"
  echo "## smoke check: $dir ($platform, $PM, domain=${domain:-none})"

  echo "# 1 verify"
  out="$($PM verify 2>&1)"; code=$?
  expect_exit "verify green" 0 "$code" "$(tail -20 <<<"$out")"

  echo "# 2 boundary lint actually fires"
  if [ -n "$domain" ]; then
    mkdir -p src/shared/lib
    printf 'import "@/domains/%s";\nexport const probe = 1;\n' "$domain" > src/shared/lib/_probe.ts
    out="$($PM exec eslint src/shared/lib/_probe.ts 2>&1)"
    expect_grep "shared→domain import is an error (boundaries/dependencies)" "boundaries/dependencies" "$out"
    rm -f src/shared/lib/_probe.ts
  else bad "boundary probe" "no src/domains/* to import"; fi

  echo "# 3 a11y lint"
  if [ "$platform" = expo ]; then
    printf 'import { Pressable } from "react-native";\nexport const P = () => <Pressable onPress={() => {}} />;\n' > src/shared/lib/_probe.tsx
    out="$($PM exec eslint src/shared/lib/_probe.tsx 2>&1)"
    expect_grep "Pressable without accessibilityRole is an error" "react-native-a11y" "$out"
  else
    printf 'export const P = () => (<><img src="x" /><div onClick={() => {}} /></>);\n' > src/shared/lib/_probe.tsx
    out="$($PM exec eslint src/shared/lib/_probe.tsx 2>&1)"
    expect_grep "img without alt is an error" "jsx-a11y/alt-text" "$out"
    expect_grep "div onClick without key handler is an error" "click-events-have-key-events" "$out"
  fi
  rm -f src/shared/lib/_probe.tsx

  echo "# 4 API contract lint"
  printf 'import axios from "axios";\nexport const p = () => { void axios; return fetch("/x"); };\n' > src/shared/lib/_probe.ts
  out="$($PM exec eslint src/shared/lib/_probe.ts 2>&1)"
  expect_grep "raw fetch is an error" "no-restricted-globals" "$out"
  expect_grep "axios import is an error" "no-restricted-imports" "$out"
  rm -f src/shared/lib/_probe.ts
  gen="$(ls src/api/*.gen.ts 2>/dev/null | head -1)"
  if [ -n "$gen" ]; then
    out="$($PM exec eslint "$gen" 2>&1)"; code=$?
    expect_exit "generated client passes lint (exception path works)" 0 "$code" "$out"
  else bad "src/api/*.gen.ts exists" "none"; fi

  echo "# 5 hooks (stdin JSON → decision)"
  hook() { printf '%s' "$2" | bash ".claude/hooks/$1" 2>/dev/null; }
  out="$(hook protect-files.sh '{"tool_input":{"file_path":"src/x.test.ts"}}')"
  expect_grep "test file edit → ask (red gate)" '"permissionDecision": ?"ask"' "$out"
  out="$(TDD_PHASE=red hook protect-files.sh '{"tool_input":{"file_path":"src/x.test.ts"}}')"
  expect_nogrep "test file edit with TDD_PHASE=red → allow" 'permissionDecision' "$out"
  hook protect-files.sh '{"tool_input":{"file_path":"src/api/client.gen.ts"}}' >/dev/null; code=$?
  expect_exit "gen.ts edit → deny" 2 "$code" ""
  hook protect-files.sh '{"tool_input":{"file_path":"package.json"}}' >/dev/null; code=$?
  expect_exit "package.json edit → deny" 2 "$code" ""
  for c in 'TDD_PHASE=red perl -pi -e s/a/b/ x.test.ts' 'echo x > y.test.ts' "sed -i '' s/a/b/ src/a.test.tsx" 'git commit --no-verify -m x' 'pnpm add lodash'; do
    hook protect-bash.sh "{\"tool_input\":{\"command\":\"$c\"}}" >/dev/null; code=$?
    expect_exit "bash deny: $c" 2 "$code" ""
  done
  for c in 'cat x.test.ts 2>&1' 'pnpm vitest run x.test.ts' 'sed -n 1,5p src/a.ts'; do
    hook protect-bash.sh "{\"tool_input\":{\"command\":\"$c\"}}" >/dev/null; code=$?
    expect_exit "bash allow: $c" 0 "$code" ""
  done
  expect_grep "settings deny has --no-verify" 'no-verify' "$(cat .claude/settings.json)"

  echo "# 6 commitlint + lefthook"
  out="$(printf 'bad message' | $PM exec commitlint 2>&1)"; code=$?
  expect_exit "commitlint rejects 'bad message'" 1 "$code" "$out"
  out="$(printf 'feat(todo): 추가' | $PM exec commitlint 2>&1)"; code=$?
  expect_exit "commitlint accepts conventional + Korean" 0 "$code" "$out"
  expect_grep "lefthook installed in .git" "lefthook" "$(cat .git/hooks/commit-msg 2>/dev/null)"

  echo "# 7 api:check deterministic"
  out="$($PM api:gen 2>&1 && git diff --exit-code --stat -- src/api 2>&1)"; code=$?
  expect_exit "regenerate → no diff" 0 "$code" "$out"

  echo "# 8 openspec"
  out="$($PM exec openspec new change probe-tmp --schema feature 2>&1 && $PM exec openspec status --change probe-tmp 2>&1)"; code=$?
  expect_grep "openspec new change (feature schema) works" "specs|tasks" "$out"
  rm -rf openspec/changes/probe-tmp

  echo "# 9 rules/ docs present"
  for f in .claude/rules/components.md .claude/rules/state.md .claude/rules/tests.md .claude/rules/platform.md docs/adr/0001-domain-structure.md docs/conventions.md CLAUDE.md api/openapi.yaml orval.config.ts; do
    [ -f "$f" ] && ok "exists: $f" || bad "exists: $f" "missing"; done
  expect_nogrep "CLAUDE.md has no unreplaced {{VAR}}" '\{\{[A-Z_]+\}\}' "$(cat CLAUDE.md .claude/rules/*.md 2>/dev/null)"
  expect_grep "CLAUDE.md ≤ 60 lines" "^ *[0-5]?[0-9]$" "$(wc -l < CLAUDE.md)"

  echo; echo "smoke check: passed $pass, failed $fail"; [ "$fail" -eq 0 ]
}

# ---------- setup ----------
setup() {
  local platform="$1" dir="$2"
  bash "$PLUGIN/skills/develop-setup/scripts/setup-$platform.sh" "$dir" || { echo "setup-$platform.sh failed"; exit 1; }
  check "$dir"
}

case "${1:-}" in
  check) check "${2:?project dir}";;
  setup) setup "${2:?vite|next|expo}" "${3:?target dir}";;
  *) sed -n 2,6p "$0"; exit 1;;
esac
