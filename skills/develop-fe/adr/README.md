# ADR — develop-fe 스킬의 결정 기록

규약: 파일명 `NNNN-slug.md`, 상태 `제안`(검증 1~2회) → `채택`(3회 이상 유지) → `대체됨(→NNNN)` / `폐기`. 에이전트는 ADR을 법칙이 아니라 기본값으로 대한다. 새 결정은 SKILL.md/workflow.md에 바로 쓰지 말고 ADR 먼저 → 문서는 ADR을 참조. 같은 이탈이 2회 반복되면 ADR을 새 번호로 개정한다. 검증 단위는 "change 1개"(Tier-2/3) 또는 "task 10개"(Tier-1). 재검증 리서치의 판정 원문은 `references/verdicts-2026-08-21.md`.

## 목록
| # | 제목 | 상태 | 검증 |
|---|---|---|---|
| [0001](0001-openspec-spine-ce-periphery.md) | OpenSpec이 아티팩트 척추, CE는 주변부 — ce-plan/lfg 미사용, ce-work는 실험 B, ce-code-review엔 스펙 경로 필수 | 제안(개정) | — |
| [0002](0002-figma-snapshot-not-live.md) | Figma는 원천, `design/` 스냅샷이 입력 — 새 화면·변경 때만 호출 | 제안 | — |
| [0003](0003-design-gap-artifact-loop.md) | 미완성 디자인: Artifact 후보 → 확정 → 코드 먼저 → Figma엔 평면 캡처 거울 | 제안 | — |
| [0004](0004-tdd-as-gate-not-quality.md) | TDD = 리뷰 게이트+변조 방지; 인터랙션 테스트는 Vitest Browser Mode | 제안 | — |
| [0005](0005-rule-placement.md) | 규칙 배치 — path-scoped rules, `@` import 금지, DoD는 `pnpm verify` 한 곳, 훅은 Bash까지 | 제안 | — |
| [0006](0006-domain-structure.md) | bulletproof-react features + FSD 세그먼트, 도메인 간 import 기본 금지, ADR+린트 | 제안 | — |
| [0007](0007-skill-hooks.md) | 스킬 frontmatter 훅 — 금지 스킬 호출 차단(Skill 매처), 세팅 누락 경고(once) | 제안 | — |
| [0008](0008-api-contract.md) | API 계약 — 원천은 `api/openapi.yaml` 하나, 상태 A/B/C/D 판정, orval 생성물만 import, retrofit은 별도 change | 제안 | — |
| [0009](0009-red-gate-is-permission-ask.md) | red 게이트 = Edit 권한 `ask`(사람이 diff 승인), `TDD_PHASE`는 사람이 띄운 세션의 우회 키, Bash 테스트 쓰기는 항상 deny | 제안 | — |
