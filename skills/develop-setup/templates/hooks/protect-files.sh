#!/usr/bin/env bash
# PreToolUse (Edit|Write): 의존성·설정·생성물·테스트 파일 보호.
source "$(dirname "$0")/_lib.sh"
f="$(j tool_input.file_path)"; [ -z "$f" ] && exit 0
rel="${f#"$(j cwd)"/}"   # cwd 기준 상대경로. cwd가 없거나 밖이어도 잡히게 아래는 `*/` 접두로 매칭
case "/$rel" in
  */package.json|*/pnpm-lock.yaml|*/package-lock.json|*/yarn.lock|*/eslint.config.*|*/.env|*/.env.*|*/lefthook.yml|*/commitlint.config.*|*/.claude/settings.json|*/.claude/hooks/*)
    deny "[protect] $rel 은 보호 파일 — 의존성·린트·훅 설정은 사용자에게 먼저 물어라(CLAUDE.md '하지 않는 것')." ;;
  */src/api/*.gen.ts|*/src/api/model/*)
    deny "[protect] $rel 은 생성물 — api/openapi.yaml 을 고치고 pnpm api:gen 으로 재생성한다." ;;
  *.browser.test.tsx|*.test.ts|*.test.tsx|*.stories.tsx|*/e2e/*.spec.ts)
    # red 게이트 = 사람 승인. TDD_PHASE=red 세션이면 묻지 않고 허용, 아니면 Edit 권한 프롬프트로 사람이 diff를 보고 승인한다(adr/0009).
    # 비대화형(-p)에서는 ask가 승인자가 없어 거부되므로 테스트 파일은 손대지 못한다 — 의도된 동작.
    [ "${TDD_PHASE:-}" = "red" ] && exit 0
    ask "[tdd] 테스트 파일 편집 = red 턴. 이 diff가 스펙의 시나리오를 그대로 단언하는지 보고 승인하세요(구현 전 실패해야 정상). 승인 후 test(scope): 커밋으로 분리." ;;
esac
exit 0
