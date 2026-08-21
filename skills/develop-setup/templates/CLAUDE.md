# {{PROJECT}}

## 하지 않는 것 (훅·린트가 막는다 — 이유를 알고 우회하지 않는다)
- 새 의존성 추가 — 먼저 물어라. lockfile diff를 Stop 훅이 본다
- 색·간격·폰트 하드코딩 — `{{TOKENS_PATH}}`만 (린트)
- 기존 컴포넌트 검색 없이 새 컴포넌트 — `src/shared/ui`, 대상 도메인 `index.ts`, `design/components.md`를 먼저 grep하고 재사용한 걸 PR에 적어라
- 테스트를 초록으로 만들기 위한 테스트 수정 — 테스트 파일 Edit는 **사람 승인**(권한 프롬프트 = red 게이트), 쉘로 쓰기(`sed -i`/`perl -pi`/리다이렉트)와 인라인 `TDD_PHASE=`는 거부된다. 승인이 없으면 구현으로 넘어가지 말고 멈춰라. 못 고치면 실패한 assertion 원문과 함께 멈춰라
- `--no-verify`, `git push --force` (거부됨)
- Figma MCP 호출 — `design/screens/<slug>/`가 있으면 그걸 읽는다
- 직접 `fetch`/`axios`, 손으로 쓴 API 타입 — 계약은 `api/openapi.yaml`, 코드는 `src/api/*.gen.ts`만(린트). 스펙에 없는 필드가 필요하면 코드에 넣지 말고 스펙 diff를 제안하라

스택: {{PLATFORM}} · TypeScript strict · {{STYLE}} · {{SERVER_STATE}} · {{PM}}
명령: `{{PM}} dev` · **`{{PM}} verify`**(= 완료 정의: api:check + typecheck + eslint + test + knip. 끝났다고 말하기 전에 이 출력을 보여라) · `{{PM}} e2e`

## 구조
`src/domains/<name>/{ui,model,api,index.ts}` vertical. **도메인 간 import는 기본 금지** — 허용 엣지는 `docs/adr/0001-domain-structure.md`와 eslint 설정 두 곳에만. `src/shared`는 도메인을 모른다. 경계는 ESLint가 막는다 — 막히면 우회하지 말고 물어라.
{{ROUTER_NOTE}}

## 참고 (필요할 때 읽기 — `@`로 불러오지 않는다)
`docs/conventions.md`(이유·예시) · `docs/adr/` · `openspec/specs/`(행동 스펙) · `design/`(디자인 스냅샷) · 파일별 규칙은 `.claude/rules/`
작업 절차는 develop-fe 스킬. 세션 시작 시 `openspec list`로 열린 change부터.

## 가정 (세팅 때 묻지 않고 정한 것 — 틀리면 고쳐라)
{{ASSUMPTIONS}}
