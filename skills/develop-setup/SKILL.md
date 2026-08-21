---
name: develop-setup
description: 새 프론트엔드 프로젝트(웹 React/Next/Vite 또는 RN Expo)를 develop-fe 스킬이 작동하는 상태로 1회 세팅한다 — 스택 질문 → CLAUDE.md·.claude/rules·docs/adr·docs/conventions 생성 → ESLint 경계 규칙·commitlint·훅·`pnpm verify` → OpenSpec init + feature 스키마 → design/ 초기 스냅샷 → 자가 검증. 사용자가 "프로젝트 시작하자", "새 프로젝트 세팅해줘", "개발 환경 잡아줘", "보일러플레이트 만들어줘", "/develop-setup"이라고 하거나, develop-fe 스킬이 "세팅이 없다"고 멈췄을 때 반드시 사용한다. 빈 폴더든 이미 `create-next-app`/`create-expo-app`을 돌린 폴더든 모두 해당.
---

# develop-setup

develop-fe 스킬은 **절차**를, 프로젝트 저장소는 **사실**(규칙·구조·스펙)을 갖는다. 이 스킬은 그 사실 파일들을 `templates/`에서 복사·치환해 만들고, 실제로 강제되는지 확인한 뒤 끝난다. 한 프로젝트에 1회. 왜 이 배치인지는 develop-fe 스킬 `references/project-conventions.md`와 `adr/0004~0006`.

## 0. 현재 상태 파악
`bash scripts/preflight.sh`를 먼저 실행한다. 이미 있는 항목은 건드리지 않고 없는 것만 만든다(멱등). 기존 파일을 덮어써야 하면 diff를 보여주고 묻는다.

## 1. 질문 1회 (AskUserQuestion, 묶어서)
코드로 답이 나오는 건 묻지 않는다(`package.json`에 next/expo가 있으면 플랫폼은 정해진 것).
1. **플랫폼**: Next(App Router) / Vite+TanStack Router / **Expo(expo-router)** — 이후 템플릿 분기의 유일한 축
2. 스타일: Tailwind v4(+shadcn) / NativeWind / StyleSheet+토큰 객체
3. 서버 상태: TanStack Query / 기타 · URL 상태: nuqs / 라우터 search params
3-1. 라우터(Vite만): TanStack Router / React Router / 없음 — 묻지 않으면 에이전트가 임의로 고르고 설치한다(2026-08-21 실측)
4-1. API: 백엔드 OpenAPI 스펙 URL/파일 있나 (있으면 `api:pull`, 없으면 DRAFT 스텁으로 시작 — 없는 엔드포인트는 코드에 먼저 안 쓴다)
4. Figma: 파일 URL 있나 (있으면 `design/` 초기 스냅샷까지, 없으면 건너뜀) · Figma 플랜/seat
5. 패키지 매니저(기본 pnpm), 첫 도메인 이름 1~3개(예: auth, feed)

내가 가정한 기본값은 질문 안에 적어 반박만 받는다: 도메인 간 import 기본 금지, E2E 3~5개, 테스트 커밋 분리, Chromium 전용.

## 2. 생성 순서 (각 단계 끝에 무엇을 만들었는지 한 줄)
| # | 만드는 것 | 출처 | 비고 |
|---|---|---|---|
| 1 | 앱 스캐폴드(없을 때만) | `create-next-app` / `create vite` / `create-expo-app` | TS strict. 질문 없이 기본 옵션 |
| 2 | `src/{app|routes,domains/<name>/{ui,model,api,index.ts},shared/{ui,lib,config}}` | — | Expo는 `app/`이 expo-router, Next는 `src/app`이 라우터 폴더 — "조립층"이 아니라 프레임워크 소유 |
| 3 | `CLAUDE.md` | `templates/CLAUDE.md` | ≤60줄, **`@` import 없음**, 금지 5개 맨 위 |
| 4 | `.claude/rules/{components,state,tests}.md` | `templates/rules/` | `paths:` frontmatter. Expo는 paths의 확장자·경로 치환 |
| 5 | `docs/adr/0001-domain-structure.md`, `docs/conventions.md` | `templates/adr-0001-domain-structure.md`, `templates/conventions.md` | 허용 엣지 목록은 비워 둔다(필요할 때 린트+ADR 동시 추가) |
| 6 | ESLint flat config: boundaries(`dependencies`+`no-unknown-files`), `import-x/no-cycle`, `max-lines`, 스타일 플러그인, `eslint-plugin-vitest`(또는 jest) | `templates/eslint.boundaries.js` | 에러 메시지에 고치는 법 포함 |
| 7 | 테스트: 웹 = Vitest projects(unit jsdom + browser chromium) + `vitest-browser-react` + MSW + Playwright(3~5 flows 자리) / Expo = `jest-expo` + RNTL + MSW + Maestro 폴더 | `templates/vitest.config.ts` / `templates/jest.expo.md` | develop-fe `tdd-frontend.md`와 일치 |
| 7-1 | **API 계약 계층**: `api/openapi.yaml`(백엔드 스펙 있으면 `api:pull`로 받고, 없으면 `templates/openapi.draft.yaml`) + orval + `src/api/*.gen.ts` 커밋 + scripts `api:pull/api:gen/api:check` + ESLint `apiContractConfig` + `protect-files`에 `*.gen.ts` | `templates/orval.config.ts`, `templates/openapi.draft.yaml`, develop-fe `references/api-contract.md` | `pnpm api:gen` 후 `git diff --exit-code src/api`가 0인지(결정적 재생성) |
| 8 | `package.json` scripts: `verify`(api:check+tsc+eslint+test+knip), `e2e`, `typecheck` · Knip · jscpd(CI) | — | **DoD는 `verify` 한 곳** |
| 9 | commitlint + lefthook(`commit-msg`, `pre-commit` lint-staged, `pre-push` verify) | `templates/lefthook.yml` | 대화형 훅 금지 |
| 10 | `.claude/settings.json` + `.claude/hooks/*.sh`: PostToolUse 파일 린트 / PreToolUse 보호(Write\|Edit **+ Bash**: 테스트 파일 쉘 쓰기·인라인 `TDD_PHASE=` 거부) / Stop `pnpm verify` / `permissions.deny` / `GIT_PAGER=cat` | `templates/settings.json`, **`templates/hooks/*.sh` 그대로 복사**(검증본 — 새로 쓰지 않는다) | `update-config` 스킬 규칙을 따른다(settings는 이 스킬이 씀) |
| 11 | OpenSpec: `pnpm add -D @fission-ai/openspec`(버전 고정 — 세션마다 `openspec list`·`/opsx:*`가 쓴다) → `pnpm exec openspec init --tools claude --profile core .` · knip `ignoreDependencies`에 `@fission-ai/openspec` (CLI 전용이라 미사용으로 잡힘) → `schema fork spec-driven feature` → 템플릿 교체 → `config.yaml` | develop-fe `references/openspec-setup.md` | `schema validate feature` 통과 확인 |
| 12 | `design/`: Figma URL 있으면 `get_metadata`→`map.md`, Variables→`tokens.json`→`tokens.css`, `components.md` 골격. **없으면 `touch design/NO_FIGMA`**(preflight가 디자인 항목을 생략) | develop-fe `references/figma-design-source.md` §2 | Figma 읽기 전 `figma:figma-design-to-code` 로드. 화면 스냅샷은 여기서 안 함(첫 화면 작업 때) |
| 13 | CI 워크플로우: verify → browser(별도 job) → e2e → `openspec validate --archived --strict` → jscpd → 문서 경로 검사 | `templates/ci.yml` | 주간 Stryker는 주석으로 |

## 3. 자가 검증 — 만들었다가 아니라 작동한다를 보인다
1. `pnpm verify` 초록(빈 프로젝트 기준)
2. **경계 위반을 일부러 만든다**: `src/shared/lib/_probe.ts`에서 `@/domains/<a>`를 import → `eslint`가 `boundaries/dependencies` 에러를 **내는지 확인** → 파일 삭제. 통과해 버리면 resolver 설정 문제(`settings["import/resolver"]` 없음)다 — 템플릿 주석 참고. 이 검증이 없으면 경계 린트가 꺼진 채 "세팅 완료"가 된다
3. 테스트 보호 훅: `*.test.*` Edit 시 **권한 프롬프트(ask)가 뜨는지**(대화형) — 스크립트 검증은 `printf '{"tool_input":{"file_path":"x.test.ts"}}' | bash .claude/hooks/protect-files.sh`에 `"permissionDecision": "ask"`. Bash 쪽: `TDD_PHASE=red perl -pi -e s/a/b/ x.test.ts` 거부, `echo x > y.test.ts` 거부, `cat x.test.ts 2>&1` 허용. Bash 쪽이 뚫리면 보호는 없는 것이다(2026-08-21 실측, adr/0009)
4. `openspec new change probe-tmp --schema feature` → `status`에 specs·tasks 2개 → 삭제 (change 이름에 `_` 불가. CLI가 PATH에 없으면 `npx -y @fission-ai/openspec@latest`)
5. `git commit -m "bad message"`가 commitlint에 막히는지 → `--no-verify`가 deny되는지
5-1. **계약 강제**: `src/shared/lib/_probe.ts`에 `fetch("/x")`와 `import axios` → eslint 2 errors → 삭제. `src/api/client.gen.ts` 편집 시도가 훅에 막히는지
6. 결과를 표로 보고한다(항목 / 확인 방법 / 결과). 하나라도 실패면 완료라고 하지 않는다

## 4. 끝맺음
- develop-fe 스킬 `workflow.md`와 `openspec-setup.md`의 `[TODO]`에 해당하는 값(스택, 명령, 훅)을 **프로젝트 CLAUDE.md에** 적는다. 스킬 파일은 건드리지 않는다(여러 프로젝트 공용).
- 첫 커밋 `chore: bootstrap develop-fe workflow`. 이후 작업은 `/develop-fe`.
- `docs/solutions/`는 비워 둔다. 첫 삽질 때 `/ce-compound`가 만든다.

## 하지 않는 것
- 기능 코드 작성, 화면 스냅샷(`design/screens/`) — develop의 일
- 사용자가 이미 만든 설정을 묻지 않고 덮어쓰기
- 질문 5개 넘게 하기 — 나머지는 기본값으로 쓰고 CLAUDE.md 하단 "가정" 항목에 적는다

## 파일
| 파일 | 용도 |
|---|---|
| `scripts/preflight.sh` | 무엇이 이미 있는지 표로 출력(종료코드 0=세팅 완료, 1=일부 없음) |
| `templates/` | 복사·치환용 원본. `{{PROJECT}}`, `{{PLATFORM}}`, `{{PM}}`, `{{DOMAINS}}` 치환 |
| develop-fe `references/project-conventions.md` | 왜 이렇게 배치하는가(이 스킬은 그 "어떻게") |
