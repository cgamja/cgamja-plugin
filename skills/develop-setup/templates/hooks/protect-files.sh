#!/usr/bin/env bash
# PreToolUse (Edit|Write): 보호 파일·계약 생성물·테스트 파일. 패턴은 .claude/cgamja.json(adr/0014) — 하드코딩 없음.
source "$(dirname "$0")/_lib.sh"
f="$(j tool_input.file_path)"; [ -z "$f" ] && exit 0
rel="${f#"$ROOT"/}"
if matches "$(cfg protected)" "$rel"; then
  # 보호 파일 = ask(adr/0017): 사람이 diff를 보고 승인하는 것이 escape hatch. 쉘 쓰기는 protect-bash가 여전히 deny(diff가 안 보이면 승인이 성립하지 않는다).
  ask "[protect] $rel 은 보호 파일(cgamja.json protected) — 왜 바꾸는지와 diff를 보고 승인하세요. 거부되면 쉘로 우회하지 말고 멈춰서 사용자에게 알릴 것. 의존성 변경이면 승인 후 인자 없는 install로 lockfile 동기화."; fi
if matches "$(cfg contract.generated)" "$rel"; then
  deny "[protect] $rel 은 계약 생성물 — $(cfg contract.source) 을 고치고 \`$(cfg contract.generate)\` 으로 재생성한다."; fi
if matches "$(cfg tests.patterns)" "$rel"; then
  # red 게이트 = 사람 승인. TDD_PHASE=red 세션이면 묻지 않고 허용, 아니면 Edit 권한 프롬프트로 사람이 diff를 보고 승인한다(adr/0009).
  # 비대화형(-p)에서는 ask가 승인자가 없어 거부되므로 테스트 파일은 손대지 못한다 — 의도된 동작.
  [ "${TDD_PHASE:-}" = "red" ] && exit 0
  ask "[tdd] 테스트 파일 편집 = red 턴. 이 diff가 스펙의 시나리오를 그대로 단언하는지 보고 승인하세요(구현 전 실패해야 정상). 승인 후 test(scope): 커밋으로 분리."; fi
exit 0
