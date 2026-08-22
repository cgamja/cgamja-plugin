# brownfield 런 — Vue 3 기존 앱에 `/develop-setup` (2026-08-22)

adr/0014의 첫 검증: "React가 아닌 기존 프로젝트에서 절차가 도는가". 4층(스크래치 런, `references/skill-verification.md` §1) — 발견은 1층 케이스로 내린다.

## 대상·조건
- 프로젝트: `mutoe/vue3-realworld-example-app` 클론(`~/cgamja-scratch/brownfield-vue`). Vue 3 + Vite + Vitest + Playwright + MSW + `eslint-plugin-vuejs-accessibility` + `simple-git-hooks` + `generate:api`(swagger-typescript-api). 타입별 평면 구조(`src/{pages,components,composable,store,services}`). **기존 유닛테스트 5개가 baseline에서 실패 중**.
- 실행: `claude -p "/cgamja:develop-setup …" --plugin-dir cgamja-plugin-wt --model sonnet --max-turns 150 --dangerously-skip-permissions`. 비대화형이라 질문 대신 "발견값 + 기본값(web-desktop, design none) + 새 의존성 설치 금지(null로 남김)" 지시.
- 결과: **89턴 · $2.42 · 11.4분**, exit 0.

## 에이전트가 한 것 (diff 4파일 +66, 신규 `.claude/`·`docs/`·`design/NO_FIGMA`·`scripts/check-docs.sh`)
| 원칙 | 조치 | 판정 |
|---|---|---|
| 선언 | `.claude/cgamja.json` 28줄 — 발견값(pnpm, vitest, playwright/specs, msw, `src/services/openapi.yml`+`generate:api`+`api.ts`, vuejs-accessibility, `src/pages`) | ✓ preflight 초안과 일치 |
| P3 verify | `"verify": "pnpm type-check && pnpm lint && pnpm test:unit"` 추가 — **baseline 실패 테스트 5개 때문에 빨강**. `git stash`로 세션 이전부터 실패였음을 확인하고 **고치지 않고 보고** | ✓ 올바른 행동(세팅은 기능 코드·테스트를 안 건드린다) |
| P5 a11y.lint | **실제 버그 발견**: `@mutoe/eslint-config`가 `vue-a11y/*` 전부를 `warn`으로 낮춰 `pnpm lint`가 절대 막지 않았음 → 대표 규칙 19개를 `error`로 복원(기존 위반 0 확인 후) | ✓ 플러그인의 가치가 드러난 지점 |
| P7 계약 | 기존 인프라 그대로 선언 + `no-restricted-globals fetch`/`no-restricted-imports axios`(`src/services/**` 제외) 추가 | ✓ |
| P8 경계 | 평면 구조를 바꾸지 않고 `domains.root: src/pages` + "pages 간 import 금지"만 `no-restricted-imports` `patterns: ['src/pages/*']`로 | △ **상대경로 우회 가능** — smoke 프로브(`src/_cgamja_probe.ts`에서 `./pages/<x>` import)가 통과함. 별칭 경로만 막는 규칙 |
| 스택·구조·러너 | 변경 0(lock·vite·tsconfig diff 없음) | ✓ |
| null로 남긴 것 | a11y.runtime(axe), commitlint, OpenSpec init(외부 패키지 실행 금지 지시에 걸림), design tokens | ✓ 지시대로. 단 OpenSpec은 척추라 null이면 develop-fe가 못 돈다 → 스킬에서 "필수, 설치 승인 질문" 명시 필요 |
| CLAUDE.md | 92줄(목표 ≤60) | ✗ |

## smoke.sh check (프로브 수정 후 재실행)
`passed 27, failed 3, skipped 3` — 실패: verify(baseline 버그), 경계 상대경로(위 △), CLAUDE.md 92줄. skip: 재생성(네트워크 없어 `generate:api` 실패 → skip+원복), commitlint, openspec.
수정 전 첫 실행은 `failed 6`이었고 그중 3건은 **프로브가 React를 가정**한 오탐(`@/` 별칭, `src/shared/lib`, JSX 문법) — 아래 1층으로 내림.

## 플러그인 쪽 발견 → 조치
| # | 발견 | 층 | 조치 |
|---|---|---|---|
| 1 | smoke 경계 프로브가 `@/` 별칭·`src/shared/lib`을 가정 | 1 | 상대경로 import, 프로브 위치 = `domains.root` 부모(커밋) |
| 2 | smoke a11y 프로브가 JSX만 | 1 | `lint_file.extensions`에 따라 `.vue`/`.svelte` SFC 프로브(커밋) |
| 3 | smoke 재생성 프로브가 네트워크 실패를 "드리프트"로 판정 | 1 | 생성 실패 → skip + `git checkout` 원복, 성공 시만 diff(커밋) |
| 4 | 테스트 파일 프로브 경로 `src/src/x.spec.ts` | 1 | 패턴이 디렉터리로 시작하면 접두 안 붙임(커밋) |
| 5 | 경계 린트가 상대경로를 못 막음(에이전트 산출물) | 절차 | develop-setup 대조표 P8 "있음의 기준"에 "상대경로 import도 막는다(프로브 기준)" 명시 |
| 6 | OpenSpec을 "새 의존성"으로 묶어 건너뜀 | 절차 | develop-setup: OpenSpec은 척추 — 설치 승인을 별도 질문으로, null 불가 |
| 7 | CLAUDE.md 92줄 | 절차 | 2장 2번에 "60줄 넘으면 줄인 뒤 보고" |
| 8 | preflight 초안과 에이전트 선언이 거의 같음(`lint_file.command`만 에이전트가 `pnpm eslint --fix {file}`로 개선) | — | 초안을 그대로 쓰고 사람이 고치는 흐름이 맞다 |

## 2차: 같은 프로젝트에서 `/develop-fe` Tier-1 (sonnet, 25턴 · $0.74 · 3.5분)
task: "유닛테스트 5개가 `localStorage` undefined로 실패 — 원인 확인·수정, verify 초록". 사전에 OpenSpec을 설치(세팅이 null로 남긴 것을 승인한 셈)하고 bootstrap 커밋.
| 관찰 | 판정 |
|---|---|
| 티어 판정 Tier-1("원인 명확한 버그", 파일 1개) — 아티팩트 없이 진입 | ✓ |
| 근본 원인: Node 22+의 `globalThis.localStorage` 접근자(파일 미설정 시 undefined) + happy-dom `populateGlobal`이 이미 있는 전역 키를 덮지 않음 → 기존 폴리필 가드 조건이 발동 안 함 | ✓ 진짜 원인(환경 의존) |
| 수정: `src/setup-tests.ts` 가드 조건 1줄 + 중복 `defineProperty` 제거. 테스트 파일 편집 0(red 게이트 준수) | ✓ |
| 증거: `pnpm verify` exit 0 — vue-tsc·eslint·vitest 25 files/63 tests 통과 | ✓ |
| 커밋 `fix(test): …` 1개, 푸시 안 함 | ✓ |
선언(`commands.verify`, `tests.patterns`)이 실제 개발 루프에서 읽혔다: Stop 훅이 verify를 돌렸고 테스트 파일은 보호됐다.

## 판정
**범용 증거 성립(세팅 + Tier-1)**: 절차·훅·프로브가 React 없는 프로젝트에서 돌았고, 기존 도구 위에서만 강제 수단을 붙였으며, 프로젝트의 실제 결함(a11y 린트 무력화)을 찾았다. 비용 $2.42는 Tier-2 React 런($33~46)의 1/15 — 세팅은 저렴하다. Tier-1 런이 선언 기반 루프까지 확인했다. 다음 검증은 비React Tier-2(스펙·red 게이트·리뷰 렌즈).
