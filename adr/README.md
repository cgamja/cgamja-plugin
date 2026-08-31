# ADR — develop-fe 스킬의 결정 기록

규약: 파일명 `NNNN-slug.md`, 상태 `제안`(검증 1~2회) → `채택`(3회 이상 유지) → `대체됨(→NNNN)` / `폐기`. 에이전트는 ADR을 법칙이 아니라 기본값으로 대한다. 새 결정은 SKILL.md/workflow.md에 바로 쓰지 말고 ADR 먼저 → 문서는 ADR을 참조. 같은 이탈이 2회 반복되면 ADR을 새 번호로 개정한다. 검증 단위는 "change 1개"(Tier-2/3) 또는 "task 10개"(Tier-1). 재검증 리서치의 판정 원문은 `reports/verdicts-2026-08-21.md`(역사 기록). 이 디렉터리와 `docs/`(spec: 판정 기준 · guides: 작업 지식)·`reports/`·`agents/`는 플러그인 루트에 있고 모든 스킬이 공유한다(0010, 폴더 재편은 0027 §8).

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
| [0009](0009-red-gate-is-permission-ask.md) | red 게이트 = Edit 권한 `ask`(사람이 diff 승인), `TDD_PHASE`는 사람이 띄운 세션의 우회 키, Bash 테스트 쓰기는 항상 deny | 대체됨(→0018) | 2세션 |
| [0010](0010-orchestrator-and-specialists.md) | develop-fe는 오케스트레이터, `test-fe`/`review-fe` 분리, references·adr·agents는 루트, `-fe` 접미사 유지, a11y 세 층, 플랫폼 프로필 | 제안 | — |
| [0011](0011-model-routing.md) | 모델 라우팅 — 본체는 판단, 서브에이전트는 `model:` 명시(haiku 탐색 / sonnet 구현 / opus 리뷰) | 제안 | — |
| [0012](0012-review-lenses-by-tier.md) | 리뷰 렌즈 L1~L7 = persona, 티어가 렌즈 수를 정함, ce-code-review 병행, PR 모드 | 제안 | — |
| [0013](0013-skill-verification-pyramid.md) | 스킬 검증 4층 피라미드 — 결정적/트리거/행동 eval/스크래치 런, 4층은 탐색 전용, 3층은 `plugin eval` 포맷, pass^k 80% | 제안 | — |
| [0014](0014-stack-agnostic-three-layers.md) | 절차/프로젝트 선언(`.claude/cgamja.json`)/관심사별 references 세 층 — 스택은 정하지 않고 읽는다, develop-setup은 발견·대조·최소 제안, 스캐폴드 없음 | 제안 | — |
| [0015](0015-positioning-differentiators.md) | 차별점 재정의 — 기계 강제·자기 테스트는 전제, 고유 가치는 증거 스택·선언 brownfield·비용 투명성. 지형표 `docs/positioning.md` | 제안 | — |
| [0016](0016-lens-ledger-review-budget.md) | 렌즈 원장 — 렌즈별 반영률·토큰을 `reports/lens-ledger.md`에 누적, 0012 §5 판정을 데이터로, Tier-2 예산(기본/라이트)은 사용자 선택 | 제안 | — |
| [0017](0017-hook-precision-and-handoff.md) | 훅 정밀화 — 읽기/쓰기 구분, 보호 파일 Edit는 deny→ask, 의존성 패턴 대칭, 스크래치 테스트 rm 허용, Stop 훅 handoff | 제안 | — |
| [0018](0018-red-gate-batch-approval.md) | red 게이트 = 세션당 1회 승인 + 실패 원문 배치 확인 — 편집마다 ask 폐지, 변조 방지는 커밋 분리+L3 | 제안 | — |
| [0019](0019-lean-workflow.md) | 워크플로우 다이어트 — 시작 fast-path, 단계 단위 커밋(change당 4~8), 리뷰 반영 배치+잔여 diff 0, 계획 컨텍스트 예산, propose planning boundary, 폰트 대조 | 제안 | — |
| [0020](0020-develop-baby-fe.md) | develop-baby-fe — MVP 경량 경로: 별도 진입점, 절차 오프(스펙·red 게이트·렌즈 다중), L1 1회(sonnet), 에스컬레이션은 안내, 목표 <$5 | 제안 | — |
| [0021](0021-evidence-declaration.md) | 증거 선언 — 촬영 기본 동선 반전(에이전트 직접 시도 → 최후에 사용자), `evidence.dark`/`platforms` 슬롯 확장, 렌즈는 선언 밖 부재를 blocker가 아니라 "선언된 한계"로 | 제안 | — |
| [0022](0022-retro-fe.md) | retro-fe — 세션 트랜스크립트 감사로 마찰을 측정해 재검토 조건에 데이터 공급, 자동 반영 금지(제안·리포트까지) | 제안 | — |
| [0023](0023-hook-false-positive-round2.md) | 훅 오탐 2차 정밀화(0017 개정) — cat<< 제외, 세그먼트 단위 쓰기 판정, advisory 세션당 1회, 훅 버전 마커·드리프트 감지 | 제안 | — |
| [0024](0024-detection-blindspot-checklists.md) | 검출 사각지대 체크리스트 승격 — 스펙에 실패 의미론 3질문(유실 재시도·자원 만료·동시 입력), L1에 React 관용구 3항목 | 제안 | — |
| [0025](0025-evidence-drive-scripting.md) | 증거 캡처 운전 스크립트화(0021 개정) — 화면당 레시피 스크립트, 상태당 1장·재조정 상한 3회·재읽기 금지, 미검증 플랫폼 조기 스킵 | 제안 | — |
| [0026](0026-develop-fe-v2-external-skills.md) | develop-fe v2 — 티어 2단계(Tier-3 폐지), test-fe 삭제→TDD 스킬 vendoring, 리뷰 2축(review-cgamja+code-review), QA=qa-cgamja, SPEC 문서 docs/spec/ 이관, git pre-commit/pre-push 게이트, 디자인 플래그 3종 | 제안 | — |
| [0027](0027-orchestrator-delegation-and-friction-fixes.md) | 실사용 마찰 반영 — 메인은 오케스트레이터만(구현·테스트는 unit packet 서브에이전트 위임), worktree 병렬(Parallel Safety Check), orval tags-split 도메인 분리, 테스트 동결, 증거 비저장(.claude/state/evidence), jscpd 폐지, 컨텍스트 예산 ~50% | 제안 | — |
