// orval.config.ts — api/openapi.yaml → src/api/*.gen.ts (타입·fetch 클라이언트·TanStack Query 훅·MSW 핸들러+faker·zod)
// 검증: orval 8.24 / msw 2.15 / zod 4 / react-query 5 (2026-08-21). 생성물은 커밋하고 `api:check`가 드리프트를 잡는다.
// MSW 핸들러는 client.gen.ts에 인라인(`mock: true`). 묶음 이름은 info.title에서 나오니 title은 짧게.
import { defineConfig } from "orval";
export default defineConfig({
  api: {
    input: "./api/openapi.yaml",
    output: {
      target: "./src/api/client.gen.ts",
      schemas: "./src/api/model",
      client: "react-query",
      httpClient: "fetch",       // Expo(RN)에서 문제 시 "axios"
      mock: true,                // = { generators: [{ type: "msw" }] } — v7식 mock.type은 TypeError
      baseUrl: { getBaseUrlFromSpecification: true }, // 없으면 servers(/api/v1)를 무시하고 `/todos`를 호출한다(2026-08-21 retrofit 리뷰에서 P1으로 발견). MSW 핸들러는 `*/todos` 와일드카드라 영향 없음
    },
  },
  zod: {
    input: "./api/openapi.yaml",
    output: { target: "./src/api/zod.gen.ts", client: "zod", fileExtension: ".gen.ts" },
  },
});
