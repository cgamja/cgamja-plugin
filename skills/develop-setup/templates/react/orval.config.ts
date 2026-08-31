// orval.config.ts — api/openapi.yaml → 도메인별 생성물 (타입·fetch 클라이언트·TanStack Query 훅·MSW 핸들러+faker·zod)
// 검증: orval 8.24 / msw 2.15 / zod 4 / react-query 5 (2026-08-21). 생성물은 커밋하고 `api:check`가 드리프트를 잡는다.
// 도메인 분리(adr/0027): `mode: "tags-split"` — OpenAPI `tags`(= 도메인 이름)별로 폴더가 갈라져 각 도메인의 api 세그먼트에 앉는다.
//   전제: 모든 endpoint에 tags 1개 필수(태그 없는 endpoint는 스펙 린트로 거부 — api-contract.md §8-b).
//   생성 경로는 태그별 폴더(<target 디렉터리>/<tag>/)로 나오고, mock은 <tag>.msw.ts·<tag>.faker.ts로 갈라진다 — 선언 generated glob은 .gen/.msw/.faker 셋 다 포함(cgamja.json 템플릿). 첫 적용 시 실제 경로를 실측해 이 주석과 선언 glob을 갱신할 것(2026-08-31 문서 반영, 경로 미실측).
// 공유 스키마(model)는 도메인 밖 한 곳 — 도메인 간 타입 공유는 여기(=shared)로만.
// MSW 핸들러는 인라인(`mock: true`). 묶음 이름은 info.title에서 나오니 title은 짧게.
import { defineConfig } from "orval";
export default defineConfig({
  api: {
    input: "./api/openapi.yaml",
    output: {
      mode: "tags-split",        // 도메인(태그)별 폴더 분리 — FSD 응집(adr/0027)
      target: "./src/domains/api.gen.ts", // → src/domains/<tag>/api.gen.ts (도메인의 api 세그먼트)
      schemas: "./src/api/model",         // 공유 스키마는 한 곳(shared 취급)
      client: "react-query",
      httpClient: "fetch",       // Expo(RN)에서 문제 시 "axios"
      mock: true,                // = { generators: [{ type: "msw" }] } — v7식 mock.type은 TypeError
      baseUrl: { getBaseUrlFromSpecification: true }, // 없으면 servers(/api/v1)를 무시하고 `/todos`를 호출한다(2026-08-21 retrofit 리뷰에서 P1으로 발견). MSW 핸들러는 `*/todos` 와일드카드라 영향 없음
    },
  },
  zod: {
    input: "./api/openapi.yaml",
    output: { mode: "tags-split", target: "./src/domains/zod.gen.ts", client: "zod", fileExtension: ".gen.ts" },
  },
});
