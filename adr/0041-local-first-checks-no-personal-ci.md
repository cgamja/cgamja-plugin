# ADR 0041 — 검사는 로컬이 기본, 개인 CI 워크플로는 만들지 않는다 — PR 직전은 `commands.verify_pr` + pr_gate

- 상태: 제안 (2026-10-14)
- 관련: adr/0036(훅 없는 레포의 검사 — 그중 "CI(PR 범위)" 경로를 이 ADR이 대체), adr/0005(DoD는 verify 한 곳 — "CI 백스톱·CI 문서 검사" 표기를 대체), adr/0001(openspec validate의 위치), adr/0027(CI는 사후 고발), adr/0038(pr_gate), care-app 2026-10-14 실측

## 문제

develop-setup 2장 행 10은 "기존 워크플로에 verify·commitlint·openspec validate·문서 경로 검사 단계 추가"였고, 기존 CI가 팀 소유라 손댈 수 없는 레포(care-app)에서는 새 파일 `.github/workflows/ci.yml`로 풀었다. adr/0036도 훅을 못 까는 레포의 대체 경로를 "CI(PR 범위) + Stop 훅"으로 정했다.

care-app 실측(2026-09-01~10-14): 그 개인 `ci.yml`이 push·PR·main 머지마다 같은 검사를 다시 돌려 레포 Actions 시간의 약 3분의 2를 썼고, org 무료 한도(비공개 레포 월 2,000분)가 바닥나 팀 자동 리뷰까지 멈췄다. 그런데 그 단계 대부분은 **이미 로컬에서 같은 검사를 하고 있었다** — verify는 Stop 훅, commitlint는 commit-msg 훅. CI만 하던 것은 openspec validate·문서 경로 검사·커밋 범위 검사(check-commits) 셋뿐이었다. 게다가 비공개 무료 플랜은 브랜치 보호를 못 걸어 CI 빨간불이 머지를 막지도 못했다 — 비용은 내고 강제력은 없었다.

## 결정

1. **개인 CI 워크플로를 기본으로 만들지 않는다.** 검사는 로컬 두 명령에 모은다.
   - `commands.verify`(Stop 훅·완료 정의): 기존 + `openspec validate --archived` + 문서 경로 검사(`check-docs.sh`) — 둘 다 상태 없는 빠른 검사라 턴마다 돌아도 된다.
   - `commands.verify_pr`(**새 슬롯**, PR 직전): verify + 커밋 범위 검사(`check-commits.sh <merge-base origin/main> HEAD`). 작업 중에는 커밋이 정리 전이라 턴마다 돌리면 계속 빨갛다 — 그래서 verify와 나눈다.
2. **pr_gate가 `gh pr create` 직전에 `commands.verify_pr`를 실행하고, 실패하면 deny한다**(산문이 아니라 기계 — adr/0031). 선언이 `null`이거나 없으면 지나간다 — 템플릿 pre-push를 깐 레포는 그 훅이 같은 검사를 하므로 `null`이 맞다.
3. **기존 CI는 대체하지 않는다**(행 10의 원래 단서 유지). 팀·조직 CI가 있으면 그대로 두고 단계를 덧붙이지도 않는다. `templates/react/ci.yml`은 사용자가 CI를 원할 때 쓰는 **선택 예시**로 남긴다.
4. preflight 대조표의 "CI에 verify" 행은 "PR 직전 검사"로 바꾼다 — pre-push 훅에 verify가 있거나 `commands.verify_pr`이 선언돼 있으면 ✓.

## 버린 대안

- **CI 트리거만 줄이기**(`push: main` + `pull_request`): 시간은 줄지만 같은 검사의 이중 실행·무강제력은 그대로.
- **문서로만 안내**("PR 전에 verify:pr 출력 확인"): adr/0031 — 산문 규칙은 지켜지지 않는다.
- **check-commits를 verify에 넣기**: 작업 중 커밋 미정리 상태에서 Stop 훅이 매 턴 실패한다.

## 비용

- Claude 없이 사람이 직접 고친 코드는 commit-msg 훅만 거친다(팀 소유 pre-commit에 verify를 못 붙이는 레포). 비공개 무료 플랜에서는 CI도 머지를 못 막았으므로 실제 강제력 차이는 작다.
- `gh pr create` 때 verify가 한 번 더 돈다(care-app 기준 1~2분). pr_gate 훅 timeout을 10초 → 900초로 올린다.

## 강제

- `skills/develop-fe/hooks/pr_gate.sh` — `gh pr create` 세그먼트에서 `.claude/cgamja.json` `commands.verify_pr` 실행, 실패 시 deny(출력 마지막 줄 동봉).
- `skills/develop-setup/scripts/preflight.sh` — "PR 직전 검사" 행.
- `tests/test_develop_hooks.sh` — verify_pr 실패 deny · 성공 통과 · 미선언 통과.

## 재검토 조건

- 공개 레포·유료 플랜이라 브랜치 보호로 CI가 머지를 **막을 수 있는** 프로젝트가 생기면, 그 프로젝트에서는 CI를 강제 수단으로 다시 쓸지 develop-setup 1장에서 묻는다.
- pr_gate의 verify_pr 실행이 timeout(900초)에 걸리는 프로젝트가 나오면 verify_pr를 범위 검사만으로 줄이고 verify는 Stop 훅 증거(`.claude/state/verify.last.log`)로 갈음하는 안을 검토한다.
