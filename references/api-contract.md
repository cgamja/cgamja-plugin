# API 계약 — 원천은 한 파일, 코드는 생성물만 (`adr/0008`, `adr/0014`)

§0~§6은 스택·계약 형식 무관 원칙이다. 프로젝트는 `.claude/cgamja.json` `contract.{source,generate,generated}`에 원천 파일·생성 명령·생성물 glob을 선언하고, 절차·훅·리뷰어는 그 값만 읽는다. `contract`가 `null`인 프로젝트(계약 생성이 없음)는 §7의 "수동 모드"를 따른다. §8은 특정 스택에서 **검증된 구현**(날짜 표기).

**원칙**: 스펙이 있든 없든 계약의 원천은 저장소의 **한 파일**(OpenAPI, GraphQL SDL, protobuf, tRPC 라우터 타입 — 무엇이든). 타입·클라이언트·쿼리 훅·경계 mock 핸들러·스키마는 전부 거기서 **생성**하고 커밋하며, 코드는 생성물만 import한다. 에이전트가 없는 엔드포인트·필드를 지어내면 **타입 검사가 실패**한다 — 이게 환각 대책의 전부다(산문이 아니라 타입).

## 1. 계약 상태 판정 (티어와 직교 — `workflow.md` 1장)
| 상태 | 판정 | 처리 |
|---|---|---|
| **A 스펙 있음** | `contract.source`가 백엔드 원천과 일치(받아온 뒤 diff 없음) | 생성 → 생성물만 사용 |
| **B 스펙 없음** | 파일 없음 / 새 엔드포인트 | 프론트가 **DRAFT 스텁**(§3)을 쓴다 → Tier-2 질문에 포함 → 생성 → 생성된 경계 mock 핸들러 = 실행 가능한 계약. 백엔드가 나오면 §6으로 화해 |
| **C 기존 코드, 스펙 없음(retrofit)** | 직접 HTTP 호출·손 타입은 있는데 원천 없음 | **별도 Tier-2 change** `api-contract`(§5). 기능 change와 섞지 않는다 |
| **D 스펙에 없는 필드/엔드포인트가 필요** | 구현 중 발견 | 코드·mock에 먼저 넣지 않는다. 멈춤 → 원천 diff 제안 → 사용자 확정 → 생성 → 계속 (= 디자인 갭 루프의 API판) |

## 2. 도구 선택 기준 (형식별)
- 생성기가 **한 원천**에서 타입 + 클라이언트 + 경계 mock 핸들러(가능하면 fake 데이터 포함) + 런타임 스키마를 내고, **재생성이 결정적**(두 번 돌려 diff 0)이어야 한다 — 그래야 드리프트 검사(§4)가 성립한다.
- 유지보수 모드·아카이브된 생성기는 신규 도입 금지. 브로커가 필요한 소비자 주도 계약 테스트(Pact류)는 솔로·소규모엔 과함.
- 실측 없이 고르지 않는다: 설치 → 생성 → 파일 수·타입 검사·결정성 확인 → §8에 날짜와 함께 기록.

## 3. DRAFT 스텁 (상태 B) — 최소 단위
경로 1개 + 스키마 + 에러 형식 하나. 이보다 크게 쓰지 않는다(백엔드와 어긋날수록 화해 비용). 원천의 설명 필드에 `DRAFT — proposed by frontend; replace with backend spec`를 넣는다. OpenAPI 예시:
```yaml
openapi: 3.1.0
info: { title: App API, version: 0.0.1, description: "DRAFT — proposed by frontend; replace with backend spec" }
servers: [{ url: /api/v1 }]
paths:
  /projects:
    get:
      operationId: listProjects
      parameters: [{ name: cursor, in: query, schema: { type: string } }]
      responses:
        '200': { description: ok, content: { application/json: { schema: { $ref: '#/components/schemas/ProjectPage' } } } }
        '401': { $ref: '#/components/responses/Problem' }
components:
  schemas:
    Project: { type: object, required: [id, name, createdAt], properties: { id: {type: string, format: uuid}, name: {type: string, maxLength: 120}, createdAt: {type: string, format: date-time} } }
    ProjectPage: { type: object, required: [items, nextCursor], properties: { items: {type: array, items: {$ref: '#/components/schemas/Project'}}, nextCursor: {type: [string, 'null']} } }
    Problem: { type: object, required: [type, title, status], properties: { type: {type: string}, title: {type: string}, status: {type: integer}, detail: {type: string} } }
  responses:
    Problem: { description: error, content: { application/problem+json: { schema: { $ref: '#/components/schemas/Problem' } } } }
```
스펙의 `## Contract` 섹션(OpenSpec `feature` 스키마가 요구): operationId · 요청/응답 schema · 에러 상태(400/401/404/409/5xx) → 각각 UI 상태(loading/empty/error)와 시나리오 1:1.

## 4. 강제 (산문 아님)
- **린트**: 생성물 밖(`contract.generated` 제외, 테스트 제외)에서 직접 HTTP 호출·HTTP 클라이언트 import 금지 — 메시지에 "생성 클라이언트를 써라, 계약은 `contract.source`".
- **훅**: `PreToolUse` 보호 훅이 `contract.generated`를 막는다 — "원천을 고치고 `contract.generate`" 안내 + exit 2(Edit/Write·Bash 모두).
- **경계 mock**: 계약 밖 호출은 테스트에서 **에러**(조용히 통과 금지).
- **드리프트 검사**: `commands.verify`에 "재생성 후 생성물 diff 0"이 포함된다. 재생성은 드리프트가 **있을 때만** 트리를 바꾼다(그 diff가 곧 수정 목록) — 읽기전용이어야 하는 곳(리뷰어, Stop 훅 증거 수집)은 생성 없이 `git diff --exit-code -- <contract.generated>`만 본다. CI는 base 브랜치 원천 vs HEAD의 **breaking 변경 검사**를 추가.

## 5. Retrofit (상태 C) — 기존 코드에 계약 붙이기, change 1개
1. **인벤토리**: 직접 호출·쿼리 훅·손 타입을 grep → `docs/api-inventory.md` 표 `{method, path, file, 손 타입}`. 엔드포인트별 그룹.
2. **원천 확보**: 백엔드가 내 것이면 export(프레임워크의 스펙 엔드포인트/플러그인). 아니면 주요 플로우를 HAR로 기록해 스펙으로 변환(예시·헤더 끄기 — 토큰 유출; HAR은 gitignore).
3. 원천 린트 → 커밋 → CI breaking 검사.
4. 생성 → 기존 코드 옆에. 린트 금지 규칙은 **warn** + 레거시 경로 `ignores`.
5. **엔드포인트 단위 strangler**: 손 타입 삭제 → 타입 에러가 worklist → 호출부를 생성물로 교체 → 테스트 → 커밋. 엔드포인트당 커밋 1개.
6. 전부 끝나면 린트 **error**, 손 타입 파일 삭제, 보호 훅 활성.
증거: 인벤토리 표 · breaking 검사 0 · 타입 검사 green · 삭제한 손 타입 목록.

## 6. 화해 (DRAFT → 실제 백엔드)
1. 백엔드 원천 export → DRAFT와 **breaking diff** → 차이 목록을 사용자에게.
2. dev에서 런타임 검증: 생성된 스키마로 응답을 `safeParse`(dev 빌드만) → 실제 API 클릭스루 → 불일치는 query error로 드러남.
3. (선택) 스펙 vs 라이브 퍼징(schemathesis류).
4. 백엔드 원천으로 **교체**하고 DRAFT 표기 제거 → 생성 → 타입 검사가 깨지는 곳이 수정 목록.

## 7. `contract: null` — 계약 생성이 없는 프로젝트 (수동 모드)
원칙 P7을 바로 강제할 수 없으니 **경계를 선언으로 대체**한다: `contract: { "source": null, "generate": null, "generated": null, "client": "<손으로 쓴 HTTP 클라이언트·타입 디렉터리>" }`.
① 직접 HTTP 호출 금지 린트(§4)는 `contract.client` **밖**에만 적용 — 그 디렉터리가 유일한 HTTP 경계다. 리뷰어 L6도 "생성물 밖"이 아니라 "`contract.client` 밖 손 타입·호출"을 본다.
② 경계 mock(`mock.boundary`) 핸들러 목록이 허용 요청의 **allowlist**다 — 핸들러 없는 요청은 여전히 에러. 새 엔드포인트는 코드보다 핸들러(+`contract.client` 타입)를 먼저 추가한다(상태 D의 수동판).
③ 세팅 대조표에 "계약 생성 없음"이 남아 다음 세팅 때 §5 retrofit을 제안한다. 계약 생성 도입은 기능 change와 섞지 않는다.
`client`도 없으면(손 타입이 흩어져 있음) 수동 모드가 아니라 **상태 C** — retrofit change가 먼저다.

## 8. 검증된 구현 — React + OpenAPI (orval 8.24.0 · msw 2.15 · zod 4.4 · @tanstack/react-query 5.101, 2026-08-21 스크래치 Vite)
| | orval 8 | @hey-api/openapi-ts 0.99 |
|---|---|---|
| 타입·fetch 클라이언트·TanStack 훅 | ✓ (`useListProjects`, POST는 `useCreateProject` mutation 자동) | ✓ (options 객체 스타일) |
| MSW 핸들러 | ✓ **faker 데이터 포함**, `getXxxResponseMock(override)` + `getXxxMockHandler()` + 전체 묶음 `get<Title>Mock()` | 타입 팩토리만 — 본문을 직접 줘야 하고 기본 응답 **501**. faker 플러그인은 설치해도 **무음 0 files** |
| zod | ✓ 별도 job(`client: "zod"`) | ✓ + `sdk.validator` |
| 걸림돌 | `mock: true` 또는 `mock: { generators: [{type:"msw"}] }` (v7식 `mock.type`은 TypeError) | **TypeScript 6과 충돌**(`ts.SyntaxKind` undefined) — TS 5 고정 필요 |
→ **orval.** GraphQL이면 `graphql-codegen` + `typescript-msw`로 같은 구조(미실측). `openapi-fetch`/`openapi-react-query`는 유지보수 모드라 신규 금지. Optic은 2026-01 아카이브(`diff`는 oasdiff).

`orval.config.ts` (검증본 — `develop-setup/templates/react/orval.config.ts`):
```ts
import { defineConfig } from "orval";
export default defineConfig({
  api: { input: "./api/openapi.yaml",
    output: { target: "./src/api/client.gen.ts", schemas: "./src/api/model", client: "react-query", httpClient: "fetch", mock: true,
              baseUrl: { getBaseUrlFromSpecification: true } } },   // 없으면 servers.url(/api/v1)을 무시하고 `/todos`를 부른다 — retrofit 리뷰 P1(실측)
  zod: { input: "./api/openapi.yaml", output: { target: "./src/api/zod.gen.ts", client: "zod", fileExtension: ".gen.ts" } },
});
```
- `mock: true`면 MSW 핸들러가 `client.gen.ts`에 인라인. 묶음 이름은 `info.title`에서 나오므로 title은 짧게(`App API`), DRAFT 표시는 `info.description`에.
- 재생성은 결정적(두 번 돌려도 diff 0). **단 포맷터가 생성물을 건드리면 깨진다** — `.prettierignore`에 `src/api`·lockfile·`routeTree.gen.ts` 필수(2026-08-22 smoke 실측: 누락 시 첫 커밋의 lint-staged가 포맷해 `api:check` 항상 빨강).
- 선언 예: `contract: { source: "api/openapi.yaml", generate: "pnpm api:gen", generated: ["src/api/**/*.gen.ts", "src/api/model/**"] }`, `package.json` `"api:pull": "curl -sf $API_SPEC_URL -o api/openapi.yaml"`, `"api:gen": "orval"`, `"api:check": "orval && git diff --exit-code -- src/api"`, `verify`에 `api:check` 포함.
- 린트: `no-restricted-globals` `fetch` + `no-restricted-imports` `axios`/`ky`(`src/api/**`·테스트 제외). 검증: 위반 파일 2 errors, 생성 폴더 0.
- MSW: `setupServer(...).listen({ onUnhandledRequest: "error" })` — 검증: `fetch("/api/v1/userz")` rejects.
- CI: `oasdiff breaking`(base vs HEAD). 스펙 확보 도구: FastAPI `/openapi.json`, NestJS `@nestjs/swagger` CLI 플러그인, springdoc; 없으면 `mitmproxy2swagger -i capture.har -o api/openapi.yaml -p <base>` (`--examples/--headers` 끄기). 린트 `redocly lint`. 화해 퍼징 `schemathesis run api/openapi.yaml --url <staging>`.
- Expo(RN): 생성 fetch 클라이언트·MSW node 설정은 **미실측**(adr/0008 재검토 조건).
