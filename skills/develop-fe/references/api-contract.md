# API 계약 — 원천은 `api/openapi.yaml` 하나 (검증: orval 8.24.0 · msw 2.15 · zod 4.4 · @tanstack/react-query 5.101, 2026-08-21 스크래치 Vite)

**원칙**: 스펙이 있든 없든 계약의 원천은 저장소의 `api/openapi.yaml` 한 파일. 타입·클라이언트·TanStack Query 훅·MSW 핸들러·zod는 전부 **생성**(`src/api/**/*.gen.ts`, 커밋)하고, 코드는 생성물만 import한다. 에이전트가 없는 엔드포인트·필드를 지어내면 **tsc 에러**가 난다 — 이게 환각 대책의 전부다(산문이 아니라 타입). 결정 근거·대안은 `adr/0008`.

## 1. 계약 상태 판정 (티어와 직교 — `workflow.md` 1장)
| 상태 | 판정 | 처리 |
|---|---|---|
| **A 스펙 있음** | `api/openapi.yaml`이 백엔드 원천과 일치(`api:pull` 후 diff 없음) | `api:gen` → 생성물만 사용 |
| **B 스펙 없음** | 파일 없음 / 새 엔드포인트 | 프론트가 **DRAFT 스텁**(§3)을 쓴다 → Tier-2 질문에 포함 → 생성 → 생성된 MSW 핸들러 = 실행 가능한 계약. 백엔드가 나오면 §6으로 화해 |
| **C 기존 코드, 스펙 없음(retrofit)** | `fetch/axios/useQuery` 호출은 있는데 스펙 없음 | **별도 Tier-2 change** `api-contract` (§5). 기능 change와 섞지 않는다 |
| **D 스펙에 없는 필드/엔드포인트가 필요** | 구현 중 발견 | 코드·목에 먼저 넣지 않는다. 멈춤 → 스펙 diff 제안 → 사용자 확정 → `api:gen` → 계속 (= 디자인 갭 루프의 API판) |

## 2. 도구 (실측 결과)
| | orval 8 | @hey-api/openapi-ts 0.99 |
|---|---|---|
| 타입·fetch 클라이언트·TanStack 훅 | ✓ (`useListProjects`, POST는 `useCreateProject` mutation 자동) | ✓ (options 객체 스타일) |
| MSW 핸들러 | ✓ **faker 데이터 포함**, `getXxxResponseMock(override)` + `getXxxMockHandler()` + 전체 묶음 `get<Title>Mock()` | 타입 팩토리만 — 본문을 직접 줘야 하고 기본 응답 **501**. faker 플러그인은 설치해도 **무음 0 files** |
| zod | ✓ 별도 job(`client: "zod"`) | ✓ + `sdk.validator` |
| 걸림돌 | `mock: true` 또는 `mock: { generators: [{type:"msw"}] }` (v7식 `mock.type`은 TypeError) | **TypeScript 6과 충돌**(`ts.SyntaxKind` undefined) — TS 5 고정 필요 |
→ **기본 orval.** GraphQL이면 `graphql-codegen` + `typescript-msw`. `openapi-fetch`/`openapi-react-query`는 유지보수 모드라 신규 금지. Pact는 솔로엔 과함(브로커 필요).

`orval.config.ts` (검증본):
```ts
import { defineConfig } from "orval";
export default defineConfig({
  api: { input: "./api/openapi.yaml",
    output: { target: "./src/api/client.gen.ts", schemas: "./src/api/model", client: "react-query", httpClient: "fetch", mock: true,
              baseUrl: { getBaseUrlFromSpecification: true } } },   // 없으면 servers.url(/api/v1)을 무시하고 `/todos`를 부른다 — retrofit 리뷰 P1(실측)
  zod: { input: "./api/openapi.yaml", output: { target: "./src/api/zod.gen.ts", client: "zod", fileExtension: ".gen.ts" } },
});
```
- **`baseUrl` 누락 시 생성 클라이언트가 `servers.url`을 무시**(`/api/v1/notes`→`/notes` 회귀, 2026-08-21). 스펙 servers를 쓰려면 `getBaseUrlFromSpecification: true`, 프록시 규약이면 문자열. MSW 핸들러는 `*/path` 와일드카드라 둘 다 맞는다.
- `mock: true`면 MSW 핸들러가 `client.gen.ts`에 인라인된다(별도 `.msw.ts` 아님). 묶음 이름은 `info.title`에서 나오므로 title은 짧게(`App API`), DRAFT 표시는 `info.description`에.
- 재생성은 결정적(두 번 돌려도 diff 0) → `api:check`가 성립한다.

`package.json`:
```json
"api:pull":  "curl -sf $API_SPEC_URL -o api/openapi.yaml",
"api:gen":   "orval",
"api:check": "orval && git diff --exit-code -- src/api",
"verify":    "pnpm api:check && tsc --noEmit && eslint . && vitest run && knip"
```

## 3. DRAFT 스텁 (상태 B) — 최소 단위
path 1개 + schema + 에러는 RFC 9457 Problem 하나. 이보다 크게 쓰지 않는다(백엔드와 어긋날수록 화해 비용).
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
- ESLint (`src/api/**`, 테스트 제외): `no-restricted-globals` `fetch`, `no-restricted-imports` `axios`/`ky` — 메시지에 "생성 클라이언트를 써라, 계약은 api/openapi.yaml". 검증: 위반 파일 2 errors, 생성 폴더 0.
- `PreToolUse` 보호 훅(`protect-files.sh`)에 `src/api/**/*.gen.ts` 추가 — "스펙을 고치고 `api:gen`" 안내 + exit 2.
- MSW `setupServer(...).listen({ onUnhandledRequest: "error" })` — 계약 밖 호출은 테스트에서 throw(검증: `fetch("/api/v1/userz")` rejects).
- CI: `api:check`는 `verify`에 포함 + `oasdiff breaking`(base 브랜치 스펙 vs HEAD) — `develop-setup/templates/ci.yml`.

## 5. Retrofit (상태 C) — 기존 코드에 계약 붙이기, change 1개
1. **인벤토리**: `grep -rnE "fetch\(|axios\.|useQuery\(|useMutation\(" src` → `docs/api-inventory.md` 표 `{method, path, file, 손 타입}`. 엔드포인트별 그룹.
2. **스펙 확보**: 백엔드가 내 것이면 export(FastAPI `/openapi.json`, NestJS `@nestjs/swagger` CLI 플러그인, springdoc). 아니면 주요 플로우를 HAR로 기록 → `mitmproxy2swagger -i capture.har -o api/openapi.yaml -p <base>` (`--examples/--headers` 끄기 — 토큰 유출; HAR은 gitignore).
3. 스펙 린트(`redocly lint`) → 커밋 → oasdiff CI.
4. `api:gen` → 기존 코드 옆에 생성. ESLint 금지 규칙은 **warn** + 레거시 경로 `ignores`.
5. **엔드포인트 단위 strangler**: 손 타입 삭제 → `tsc` 에러가 worklist → 호출부를 생성 훅/타입으로 교체 → 테스트 → 커밋. 엔드포인트당 커밋 1개.
6. 전부 끝나면 린트 **error**, `src/types/api*.ts` 삭제, 보호 훅 활성.
증거: 인벤토리 표 · `oasdiff breaking` 0 · `tsc` green · 삭제한 손 타입 목록. (Optic은 2026-01 아카이브 — `capture` 대체재 없음, `diff`는 oasdiff.)

## 6. 화해 (DRAFT → 실제 백엔드)
1. 백엔드 스펙 export → `oasdiff breaking api/openapi.yaml <backend>.yaml` → 차이 목록을 사용자에게.
2. dev에서 런타임 검증: `queryFn`에서 생성 zod `safeParse`(`import.meta.env.DEV`만) → 실제 API 클릭스루 → 불일치는 query error로 드러남.
3. (선택) `schemathesis run api/openapi.yaml --url <staging>` 로 스펙 vs 라이브.
4. 백엔드 스펙을 `api/openapi.yaml`로 **교체**하고 `description`의 DRAFT 제거 → `api:gen` → tsc가 깨지는 곳이 수정 목록.
