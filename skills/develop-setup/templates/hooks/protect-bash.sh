#!/usr/bin/env bash
# PreToolUse (Bash): 훅·검증 우회, 보호 파일·생성물·테스트 파일의 쉘 쓰기 차단. 패턴은 .claude/cgamja.json(adr/0014). permissions.deny와 이중.
# 리다이렉트 패턴은 `2>&1`, `>/dev/null`(fd 리다이렉트)을 제외한다 — 2026-08-21 `cat x.test.tsx 2>&1` 류 읽기 명령 오차단.
source "$(dirname "$0")/_lib.sh"
cmd="$(j tool_input.command)"; [ -z "$cmd" ] && exit 0
stripped="$(sed -E 's/[0-9]*>&[0-9]+//g; s/[0-9]*>>?[[:space:]]*\/dev\/null//g' <<<"$cmd")"
WRITE='(sed -i|perl -p?i|tee |>|>>|rm |cp |mv |cat <<|open\([^)]*["'"'"']w)'
if grep -qE -- '--no-verify|git commit[^|]* -n |HUSKY=0|LEFTHOOK=0|core\.hooksPath|push[^|]*(--force|-f )' <<<"$cmd"; then
  deny "[protect] 훅 우회 금지(--no-verify, LEFTHOOK=0, hooksPath, push --force). 막힌 이유를 고치거나 사용자에게 물어라."; fi
if grep -qE '(pnpm|yarn|bun) (add|remove) |npm (i|install|uninstall) [^-]|pip install|cargo add|go get ' <<<"$cmd"; then
  deny "[protect] 의존성은 쉘로 바꾸지 않는다 — 새 의존성은 사용자에게 먼저 물어라(CLAUDE.md)."; fi
prot="$(cfg protected | globs_to_regex)"
if grep -qE "$prot" <<<"$cmd" && grep -qE "$WRITE" <<<"$stripped"; then
  deny "[protect] 보호 파일(cgamja.json protected)을 쉘로 바꾸지 않는다 — 사용자에게 먼저 물어라."; fi
gen="$(cfg contract.generated | globs_to_regex)"
if [ "$gen" != "^$" ] && grep -qE "$gen" <<<"$cmd" && grep -qE "$WRITE" <<<"$stripped"; then
  deny "[protect] 계약 생성물 — $(cfg contract.source) 을 고치고 \`$(cfg contract.generate)\`."; fi
if grep -qE '(^|[;&| ])TDD_PHASE=' <<<"$cmd"; then
  deny "[tdd] TDD_PHASE는 사람이 세션을 띄울 때 정한다(TDD_PHASE=red claude). 인라인 설정 금지 — red 턴이 필요하면 사용자에게 말하고 멈춰라."; fi
tests="$(cfg tests.patterns | globs_to_regex)"
if grep -qE "$tests" <<<"$cmd" && grep -qE "$WRITE" <<<"$stripped" && [ "${TDD_PHASE:-}" != "red" ]; then
  deny "[tdd] 테스트 파일은 쉘로 쓰지 않는다(sed -i/perl -pi/리다이렉트) — 구현 턴엔 읽기전용. 바꿔야 하면 사용자에게 red 턴을 요청해라."; fi
exit 0
