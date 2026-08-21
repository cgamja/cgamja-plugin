# 0009. red 게이트 = Edit 권한 `ask`(사람이 diff 승인); `TDD_PHASE`는 사람이 띄운 세션의 우회 키일 뿐
- 상태: 제안
- 날짜: 2026-08-21
- 검증: 스크래치 Tier-2b(2026-08-21, headless — 승인자 없음 → red에서 멈추고 구현 안 함 확인; `reports/develop-fe-tier2_2026-08-21.md` 추가 실행). 대화형 승인 경로는 미검증

## 맥락
adr/0004는 red 단계를 "PreToolUse 훅으로 `*.test.*` 읽기전용, `TDD_PHASE=red` 예외"로 정했지만 **누가 red를 여는지**를 정하지 않았다. Tier-1 실측: 에이전트가 `TDD_PHASE=red perl -pi -e … e2e/smoke.spec.ts`로 스스로 red를 열었다(우회가 아니라 규칙 공백). Bash 훅을 막자 Tier-2 실측: 단일 세션에서 red를 열 방법이 없어 **테스트 없이 구현이 먼저 들어가고** 테스트 task 3개가 "사람이 `TDD_PHASE=red claude`로 다시 띄워 달라"로 남았다 — 게이트가 워크플로우를 두 세션으로 쪼갠다.
Claude Code 훅은 `permissionDecision: "ask"`를 지원한다: 대화형이면 diff를 보여주는 권한 프롬프트; **비대화형(`-p`)에서는 `--dangerously-skip-permissions`를 줘도 거부**된다 — 승인자가 없으면 막힌다(실측 2026-08-21, 정정: 처음엔 `ask()` 미정의로 빈 출력이 허용돼 "자동 허용"으로 오판했음).

## 결정
1. 테스트 파일(`*.test.*`, `*.browser.test.*`, `*.stories.*`, `e2e/*.spec.ts`) Edit/Write는 **`ask`** — 사람이 diff를 보고 승인하는 것이 곧 red 게이트. 승인한 테스트는 `test(scope):` 커밋으로 분리(기존 규칙 유지).
2. `TDD_PHASE=red`는 사람이 세션을 띄울 때만 주는 **우회 키**(묻지 않고 허용). 에이전트의 인라인 `TDD_PHASE=`는 Bash 훅이 거부.
3. Bash를 통한 테스트 파일 쓰기(`sed -i`, `perl -pi`, 리다이렉트, `tee`, `cp/mv`)는 항상 **deny** — diff가 안 보이는 경로로는 승인이 성립하지 않는다. fd 리다이렉트(`2>&1`, `>/dev/null`)는 제외.
4. 구현 파일은 기존대로 자유. 테스트 task가 ask에서 거부되면(비대화형) 에이전트는 **구현으로 넘어가지 말고 멈춘다**(workflow 2장 Tier-2 4번).

## 전제
- 사람이 대화형으로 세션을 쓴다. 헤드리스(`-p`)에서는 어떤 권한 모드든 테스트 파일을 쓸 수 없으므로 **TDD 경로는 헤드리스 evals로 검증 불가** — 대화형 또는 사람이 `TDD_PHASE=red`를 준 세션에서만.
- Edit 권한 프롬프트가 diff를 충분히 보여준다(30초 리뷰 가정, adr/0004 전제와 동일).

## 재검토 조건
- 사람이 ask를 읽지 않고 승인하는 습관 → adr/0004 재검토 조건과 동일하게 게이트 가치 소멸 → 정적 게이트+리뷰어만.
- ask 프롬프트가 한 change에 10회 이상 떠서 피로 → 테스트 파일 단위가 아니라 "red 턴 시작" 1회 승인으로 바꾸는 메커니즘(세션 플래그 파일을 사람이 touch) 검토.
- Claude Code가 `ask`의 비대화형 동작을 바꾸면 재실측.

## 결과 / 영향
- `develop-setup/templates/hooks/protect-files.sh` ask 경로, `_lib.sh` `ask()`, `protect-bash.sh` 테스트 쓰기 deny + fd 리다이렉트 제외. `tdd-frontend.md` §2·§4, workflow Tier-2 4번, CLAUDE.md 템플릿, develop-setup 자가 검증 3번 개정. adr/0004 2항의 메커니즘은 이 ADR로 대체(0004 자체는 유지).
