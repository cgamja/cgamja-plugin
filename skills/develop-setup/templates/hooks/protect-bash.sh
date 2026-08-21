#!/usr/bin/env bash
# PreToolUse (Bash): 훅·검증 우회와 설정 파일 쉘 편집 차단. permissions.deny와 이중.
# 리다이렉트 패턴은 `2>&1`, `>/dev/null`(fd 리다이렉트)을 제외한다 — 2026-08-21 Tier-2에서 `cat x.test.tsx 2>&1` 류 읽기 명령 ~20건 오차단.
source "$(dirname "$0")/_lib.sh"
cmd="$(j tool_input.command)"; [ -z "$cmd" ] && exit 0
if grep -qE -- '--no-verify|git commit[^|]* -n |HUSKY=0|LEFTHOOK=0|core\.hooksPath|push[^|]*(--force|-f )' <<<"$cmd"; then
  deny "[protect] 훅 우회 금지(--no-verify, LEFTHOOK=0, hooksPath, push --force). 막힌 이유를 고치거나 사용자에게 물어라."
fi
if grep -qE 'tee [^|]*package\.json|sed -i[^|]*(package\.json|eslint\.config|lefthook\.yml)|> *(package\.json|pnpm-lock\.yaml|eslint\.config\.[a-z]+)|(pnpm|yarn|bun) (add|remove) |npm (i|install|uninstall) [^-]' <<<"$cmd"; then
  deny "[protect] 의존성·설정 파일을 쉘로 바꾸지 않는다 — 새 의존성은 사용자에게 먼저 물어라(CLAUDE.md)."
fi
if grep -qE 'src/api/[^ ]*\.gen\.ts' <<<"$cmd" && grep -qE '(sed -i|tee |>|rm )' <<<"$cmd"; then
  deny "[protect] src/api/*.gen.ts 는 생성물 — api/openapi.yaml 을 고치고 pnpm api:gen."
fi
if grep -qE '(^|[;&| ])TDD_PHASE=' <<<"$cmd"; then
  deny "[tdd] TDD_PHASE는 사람이 세션을 띄울 때 정한다(TDD_PHASE=red claude). 인라인 설정 금지 — red 턴이 필요하면 사용자에게 말하고 멈춰라."
fi
if grep -qE '(\.test\.|\.browser\.test\.|\.spec\.|(^|[ /])e2e/|\.stories\.)' <<<"$cmd" && grep -qE '(sed -i|perl -p?i|tee |>|cp |mv |cat <<|open\([^)]*["'"'"']w)' <<<"$(sed -E 's/[0-9]*>&[0-9]+//g; s/[0-9]*>>?[[:space:]]*\/dev\/null//g' <<<"$cmd")" && [ "${TDD_PHASE:-}" != "red" ]; then
  deny "[tdd] 테스트 파일은 쉘로 쓰지 않는다(sed -i/perl -pi/리다이렉트) — 구현 턴엔 읽기전용. 바꿔야 하면 사용자에게 red 턴을 요청해라."
fi
exit 0
