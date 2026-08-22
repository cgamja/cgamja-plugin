# 0008. API 계약 — 원천은 OpenAPI 파일 하나, 스펙 유무는 "누가 쓰나"의 차이일 뿐; 생성물만 import
- 상태: 제안
- 개정(2026-08-22, adr/0014): orval·OpenAPI는 조건부 "검증된 구현"으로 강등. 원칙(원천 한 파일·생성물만 import·상태 A/B/C/D)은 계약 형식 무관으로 유지, 선언은 `.claude/cgamja.json` `contract.*`. `contract: null` 수동 모드 추가(`references/api-contract.md` §7).
- 날짜: 2026-08-21
- 검증: 스크래치 Tier-2(B)·상태 D·retrofit C 각 1회(2026-08-21, `reports/develop-fe-tier2_2026-08-21.md`). 실제 백엔드와의 화해(§6)는 미검증

## 맥락
워크플로우에 `api/` 세그먼트와 "mock은 MSW에서만"은 있었지만 **계약이 어디서 오는지**가 없었다. 사용자 요구: ① API 명세가 있을 때/없을 때를 구분해 개발, ② "기존 코드에 명세 붙이기"를 task로 줄 수 있어야 함. 리서치(2026-08)에서 에이전트 실패 모드는 "없는 파라미터·엔드포인트 환각"이고, 수렴한 대책은 "스펙을 머신리더블로 컨텍스트에 + 생성 클라이언트만 + CI가 판정". 도구 실측: orval 8은 MSW+faker+TanStack+zod를 한 스펙에서 생성하고 재생성이 결정적; hey-api 0.99는 TS 6과 충돌, MSW는 본문 없는 팩토리(기본 501), faker 플러그인은 무음 0 files.

## 결정
1. 계약의 원천은 저장소의 `api/openapi.yaml` **한 파일**. 상태 A(있음)/B(없음→프론트 DRAFT)/C(기존 코드 retrofit)/D(스펙에 없는 것 필요)는 **판정표**로 직교 처리(`workflow.md` 1장) — 절차를 두 갈래로 만들지 않는다.
2. 타입·클라이언트·TanStack 훅·MSW 핸들러·zod는 orval로 생성, `src/api/**/*.gen.ts`에 **커밋**(에이전트는 빌드 산출물이 아니라 파일을 읽는다). `api:check`(재생성 후 `git diff --exit-code`)가 `verify`에 들어간다.
3. 코드는 생성물만 import: ESLint(raw `fetch`/`axios` 금지, `src/api/**` 제외) + `*.gen.ts` 읽기전용 훅 + MSW `onUnhandledRequest: "error"`.
4. B의 DRAFT는 **최소**(path 1·schema·Problem). `info.description`에 DRAFT 표기. 백엔드 스펙이 나오면 oasdiff + dev 런타임 zod 검증으로 화해 후 **교체**.
5. C는 기능 change와 분리된 Tier-2 change `api-contract`: 인벤토리 → 스펙(export 또는 HAR→mitmproxy2swagger) → 생성 → 엔드포인트 단위 strangler(tsc 에러가 worklist). 증거는 인벤토리·oasdiff 0·tsc green.
6. D는 코드·목에 먼저 넣지 않고 스펙 diff 제안 → 확정 → 생성.
7. 안 쓰는 것: Pact(브로커), zod를 원천으로(생성물), `openapi-fetch`/`openapi-react-query`(유지보수 모드), Optic(아카이브).

## 전제
- REST + OpenAPI 3.x. GraphQL이면 `graphql-codegen`+`typescript-msw`로 같은 구조.
- 백엔드가 스펙을 주거나, 최소한 프론트 DRAFT를 리뷰해 줄 사람이 있다. 아무도 안 보면 DRAFT가 곧 사양이 되는 위험.
- TypeScript 5.x(hey-api 재검토 시) / orval은 TS 6에서 동작 확인.

## 재검토 조건
- DRAFT와 실제 백엔드의 breaking 차이가 change 2개 연속 5건 이상 → DRAFT 범위를 더 줄이거나 백엔드와 스펙 선합의 절차 추가.
- `api:check`가 환경(Node/orval 버전)차로 거짓 실패 2회 → 생성기 버전 고정 + CI에서만 검사.
- hey-api가 TS 6 + faker 플러그인 안정화 → MSW 데이터 생성 비교 재실측.
- Expo(RN)에서 생성 fetch 클라이언트·MSW node 설정 문제 → RN 전용 httpClient/axios 옵션 결정.

## 결과 / 영향
- `references/api-contract.md` 신설, `workflow.md` 0·1·2·3장, `openspec-setup.md` Contract 섹션, `tdd-frontend.md` §3, develop-setup 2장 14행 + `preflight.sh` + 템플릿(`orval.config.ts`, `openapi.draft.yaml`, settings/ci/eslint/CLAUDE.md).
