// eslint.config.js — boundaries 부분. 전체 config에 spread해서 쓴다.
// 키 이름은 eslint-plugin-boundaries 7.x 기준(jsboundaries.dev에서 확인). `entry-point` 규칙은 deprecated.
import boundaries from "eslint-plugin-boundaries";
import importX from "eslint-plugin-import-x";
import { createTypeScriptImportResolver } from "eslint-import-resolver-typescript";

/** 허용된 도메인 간 엣지 — docs/adr/0001-domain-structure.md 표와 항상 같아야 한다 */
const ALLOWED_DOMAIN_EDGES = [
  // { from: "billing", to: "auth" },
];

export const boundariesConfig = {
  files: ["src/**/*.{ts,tsx}", "{{ROUTER_GLOB}}"],
  plugins: { boundaries, "import-x": importX },
  settings: {
    // eslint-plugin-boundaries v7은 eslint-module-utils의 레거시 `import/resolver` 키만 읽는다.
    // import-x용 `import-x/resolver-next`만 있으면 `@/…`와 .ts 경로가 전부 external로 분류돼 경계 린트가 **조용히 통과**한다
    // (2026-08-21 스크래치 실측). 두 키를 모두 둔다. 의존성: eslint-import-resolver-typescript.
    "import/resolver": { typescript: { project: "./tsconfig.app.json" } },
    "import-x/resolver-next": [createTypeScriptImportResolver({ project: "./tsconfig.app.json" })],
    "boundaries/elements": [
      // boundaries 7.2: `mode:`는 deprecated → `partialMatch: false`(=full). 요소 패턴에 **파일**(src/main.tsx)을 넣으면 경고+no-unknown-files 오탐 —
      // Vite는 main.tsx·routeTree.gen.ts를 src/app/ 으로 옮긴다(generatedRouteTree: "src/app/routeTree.gen.ts"). 실측 2026-08-21
      { type: "app", pattern: "src/app/**", partialMatch: false },
      { type: "router", pattern: "{{ROUTER_DIR}}/**", partialMatch: false },
      { type: "domain", pattern: "src/domains/*", capture: ["name"] },
      { type: "shared", pattern: "src/shared/*" },
      { type: "api", pattern: "src/api/**", partialMatch: false },      // orval 생성물 — 누구나 import, 아무도 수정 못 함(훅)
      { type: "styles", pattern: "src/styles/**", partialMatch: false },
    ],
  },
  rules: {
    "boundaries/no-unknown-files": 2,
    "boundaries/dependencies": [2, {
      default: "disallow",
      message:
        "{{from.type}}:{{from.captured.name}} → {{to.type}}:{{to.captured.name}}: docs/adr/0001 위반. " + // v7 템플릿 변수는 from/to (실측 2026-08-21). ${} 구문은 deprecated 경고, file/dependency 키는 빈 문자열
        "도메인 간은 기본 금지 — 정말 필요하면 ADR 표와 ALLOWED_DOMAIN_EDGES에 같이 추가하고 index.ts로만 import. 공통이면 src/shared로 옮긴다.",
      policies: [
        { from: { element: { type: "shared" } }, allow: { to: { element: { type: "shared" } } } },
        { from: { element: { type: "domain" } }, allow: { to: { element: { type: "shared" } } } },
        { from: { element: { type: "domain" } },
          allow: { to: { element: { type: "domain", captured: { name: "{{from.captured.name}}" } } } } },
        ...ALLOWED_DOMAIN_EDGES.map(({ from, to }) => ({
          from: { element: { type: "domain", captured: { name: from } } },
          allow: { to: { element: { type: "domain", captured: { name: to }, fileInternalPath: "index.ts" } } },
        })),
        { from: { element: { type: "router" } }, allow: { to: { element: { type: "shared" } } } },
        { from: { element: { type: "router" } }, allow: { to: { element: { type: "domain", fileInternalPath: "index.ts" } } } },
      ],
    }],
    "import-x/no-cycle": [2, { maxDepth: 4 }],
    "max-lines": [2, { max: {{MAX_LINES}}, skipBlankLines: true, skipComments: true }],
    "no-restricted-syntax": [2, {
      selector: "ExportAllDeclaration",
      message: "export * 금지 — index.ts는 named export만(ADR 0001).",
    }],
  },
};

// API 계약 강제 — 계약은 api/openapi.yaml, 코드는 생성물(src/api/*.gen.ts)만 (develop-fe adr/0008). 검증: 위반 2 errors, src/api 0.
export const apiContractConfig = {
  files: ["src/**/*.{ts,tsx}"],
  ignores: ["src/api/**", "src/test/**", "**/*.test.*", "**/*.browser.test.*", "e2e/**"],
  rules: {
    "no-restricted-globals": [2, { name: "fetch", message: "직접 fetch 금지 — src/api 생성 클라이언트를 쓴다. 없는 엔드포인트면 api/openapi.yaml부터(스펙 diff 제안)." }],
    "no-restricted-imports": [2, { paths: [
      { name: "axios", message: "직접 axios 금지 — src/api 생성 클라이언트." },
      { name: "ky", message: "직접 ky 금지 — src/api 생성 클라이언트." },
    ] }],
  },
};
