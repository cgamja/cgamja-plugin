# 프로젝트 규칙은 어디에 두나 — 배치표와 시작 템플릿 (2026-08-21 재검증 반영, `adr/0005`, `adr/0006`)

원칙: **기계가 검사할 수 있는 건 린트·훅으로, 판단이 필요한 건 해당 파일을 건드릴 때 주입되는 짧은 규칙으로, 규칙은 한 곳에.** 알아둘 사실 세 가지:
- CLAUDE.md 길이(25~500줄)는 준수율을 바꾸지 않았다(McMillan 2026, 1,650세션). 짧게 쓰는 이유는 **컨텍스트 예산**이지 준수율이 아니다. 준수율은 **세션 안에서** 떨어진다(함수 1개 생성마다 -5.6%) → 그건 훅만 고친다.
- `@path` import는 **eager** — 런치 시 전부 로드된다. `@docs/conventions.md`를 넣으면 60줄이 아니라 160줄이다. 백틱 경로(`` `docs/x.md` ``)는 lazy.
- "한 줄 산문 + 강제 훅"은 중복이 아니라 한 규칙의 두 층이다. 산문은 "왜"를 설명해서 우회 시도를 줄이고, 훅이 막는다.

## 1. 배치표
| 규칙 종류 | 위치 | 검사 주체 |
|---|---|---|
| 명령어, 스택 특이점, 절대 금지 5개(맨 위), 포인터 | `CLAUDE.md` (≤60줄 soft, 폴더맵·의존성 목록처럼 코드에서 유추되는 건 제외) | 에이전트 |
| **완료 정의(DoD)** | `package.json` `"verify"` 스크립트 **한 곳**. CLAUDE.md 한 줄·Stop 훅·OpenSpec guidance·CI는 이름만 참조 | Stop 훅, CI |
| 파일 타입별 판단 규칙(컴포넌트·상태·에러·테스트) | `.claude/rules/<topic>.md` + `paths:` frontmatter, 각 ≤30줄, 명령형, 정본 예시 파일 1개 포인터 | 해당 파일을 읽을 때 재주입 |
| 긴 이유·예시 | `docs/conventions.md` — 백틱 포인터로만 참조, **`@` import 금지** | 사람, 필요시 에이전트 |
| 커밋 형식 | `commitlint` + lefthook(`commit-msg`, `pre-commit` lint-staged) + CI `commitlint --from origin/main` | 훅, CI |
| 임포트 경계(아키텍처) | ESLint `boundaries/dependencies` + `no-unknown-files` + `import-x/no-cycle` | 린트(PostToolUse) |
| 토큰만 | `eslint-plugin-better-tailwindcss`, `no-arbitrary-*` | 린트 |
| 크기·중복·죽은 코드 | `max-lines` 300~400, **jscpd**(CI), Knip | 린트·CI |
| 의존성·설정 보호 | `PreToolUse` Write\|Edit **그리고** Bash 매처(`tee`/`sed -i`/`>` 우회 차단) + `permissions.deny` + Stop에서 lockfile diff 확인 | 훅 |
| `--no-verify` 등 우회 | `PreToolUse` Bash 거부 + `permissions.deny` + CI | 훅, CI |
| 아키텍처 결정과 허용 엣지 | `docs/adr/0001-domain-structure.md` (명령형 불릿) | 사람 |
| 행동 스펙 | `openspec/specs/<capability>/spec.md` | `openspec validate --archived`(CI) |
| OpenSpec 생성 시 주입 | `openspec/config.yaml` `context`/`rules` | propose/apply |
| 해결한 문제 | `docs/solutions/` | `/ce-compound` |
| 절차("새 도메인 추가하는 법") | 스킬 | 호출 시 |

문서 rot 방지: CI에 20줄 스크립트(또는 `ctxlint`) — CLAUDE.md/rules/conventions가 가리키는 경로가 존재하는지, 명령이 `package.json` scripts와 일치하는지. `/doctor`로 주기적 트림.

## 2. 아키텍처 — spec이 아니라 ADR + 린트에 (`adr/0006`)
OpenSpec 스펙은 사용자가 보는 동작만. `design.md`는 archive 시 버려진다(OpenSpec 자체 인정) → 아키텍처는 ADR 번호를 참조만.

### 이름과 출처
**bulletproof-react의 `features/` 구조 + FSD 세그먼트명(`ui/model/api`) + FSD public API 규칙.** "FSD-lite"가 아니다. FSD 2.1 자체가 "pages부터 시작하고 거기서 멈춰도 된다"고 하고, FSD 블로그는 솔로·단기 프로젝트에 풀 FSD를 권하지 않는다. 에이전트용 참고 문서: bulletproof-react `docs/project-structure.md`, `feature-sliced/skills` SKILL.md.

### 레이아웃
```
src/
  app/          Next: App Router 폴더(layout·providers·한 줄 re-export page.tsx). Vite: providers+router 부트스트랩
  routes/       Vite+TanStack만. 평면. Route + loader만 export
  domains/<name>/
    index.ts    다른 도메인·app이 import할 유일한 경로. named export만, export * 금지, 문장 없음
    ui/         컴포넌트 (+ 같은 폴더에 *.test.tsx / *.browser.test.tsx)
    model/      훅, 스토어, 스키마, 순수 로직 (테스트 밀도 최고, Stryker 대상)
    api/        서버 통신. Next route handler는 app/에서 한 줄 re-export
    CLAUDE.md   선택 — 코드에서 유추 불가한 불변식("금액은 정수 센트")이 있을 때만
  shared/
    ui/button/index.ts   모듈별 entry. shared/ui/index.ts, shared/index.ts **없음**
    lib/  config/
```
### 규칙 (린트로)
1. `shared` → `domains`/`app`/`routes` 금지
2. **`domains/<a>` → `domains/<b>` 기본 금지.** 필요한 엣지만 린트 설정에 명시(예: `billing → auth`의 `index.ts`). FSD·bulletproof 둘 다 같은 층 import를 기본 금지한다 — "index로만 허용"은 가장 먼저 무너지는 규칙이었다. **허용 엣지가 3개째**가 되면 `widgets/` 층 추가 ADR의 측정 가능한 신호
3. `app`/`routes` → `domains`는 `index.ts`로만, `shared`는 자유. 아무도 `app`/`routes`를 import 못 함
4. 도메인 내부는 상대경로(자기 index 경유 금지 — Vite HMR 전체 리로드·순환)
5. 한 라우트만 쓰는 UI는 그 도메인에. 화면 하나 때문에 도메인을 만들지 않는다
6. Next RSC 경계(`'use client'`)는 린트 불가 — `ui/`에서 명시, 리뷰 항목

### 린트 설정 (eslint-plugin-boundaries 7.x — `entry-point`는 deprecated, `dependencies`로)
```js
// eslint.config.js  (키는 jsboundaries.dev 최신 문서로 확인)
import boundaries from "eslint-plugin-boundaries";
export default [{
  plugins: { boundaries },
  settings: { "boundaries/elements": [
    { type: "app",    pattern: "src/app/**",    mode: "full" },
    { type: "routes", pattern: "src/routes/**", mode: "full" },
    { type: "domain", pattern: "src/domains/*", mode: "folder", capture: ["name"] },
    { type: "shared", pattern: "src/shared/*",  mode: "folder" },
  ]},
  rules: {
    "boundaries/no-unknown-files": 2,
    "boundaries/dependencies": [2, {
      default: "disallow",
      message: "${file.type} → ${dependency.type}: docs/adr/0001 위반. 도메인 index.ts로 import하거나 shared/로 옮기세요.",
      policies: [
        { from: { element: { type: "shared" } }, allow: { to: { element: { type: "shared" } } } },
        { from: { element: { type: "domain" } }, allow: { to: { element: { type: "shared" } } } },
        { from: { element: { type: "domain" } }, allow: { to: { element: { type: "domain", captured: { name: "${from.captured.name}" } } } } },
        // 허용 엣지는 여기에만 추가 (ADR에 같은 목록)
        { from: { element: { type: "domain", captured: { name: "billing" } } },
          allow: { to: { element: { type: "domain", captured: { name: "auth" }, fileInternalPath: "index.ts" } } } },
        { from: { element: { type: ["app", "routes"] } }, allow: { to: { element: { type: "shared" } } } },
        { from: { element: { type: ["app", "routes"] } }, allow: { to: { element: { type: "domain", fileInternalPath: "index.ts" } } } },
      ],
    }],
  },
}];
```
에러 메시지에 고치는 법을 넣는다(OpenAI harness). 보조: dependency-cruiser는 CI에서 순환·고아·그래프용(선택). steiger(FSD 층 이름 고정, 0.x)·sheriff(정체)는 쓰지 않는다.

### 진화성 센서 (에이전트 코드베이스의 실증된 실패 = 의미적 중복 1.87배, 상태 sprawl)
`max-lines` · `jscpd` 임계치 · colocated 테스트 · CLAUDE.md "만들기 전 `src/shared`와 대상 도메인 `index.ts`를 grep하고 재사용한 걸 PR에 적어라" · TypeScript LSP 플러그인 · 도메인 `index.ts`를 인벤토리로 읽히게 유지.

## 3. `CLAUDE.md` 시작 템플릿 (≤60줄, `@` import 없음)
```md
# <project>

## 하지 않는 것 (훅·린트가 막지만, 이유를 안다)
- 새 의존성 추가 — 먼저 물어라 (lockfile diff를 Stop 훅이 본다)
- 색·간격·폰트 하드코딩 — `src/styles/tokens.css`만 (린트)
- 기존 컴포넌트 검색 없이 새 컴포넌트 — `src/shared/ui`, 대상 도메인 `index.ts`, `design/components.md`를 먼저 grep하고 재사용한 걸 PR에 적어라
- 테스트를 초록으로 만들기 위한 테스트 수정 — 구현 턴엔 테스트 파일이 읽기전용이다 (훅)
- `--no-verify`, `git push --force` (거부됨)
- Figma MCP 호출 — `design/screens/<slug>/`가 있으면 그걸 읽는다

스택: [TODO]. pnpm.
명령: `pnpm dev` · **`pnpm verify`**(= 완료 정의: tsc+eslint+vitest+knip. 끝났다고 말하기 전에 이 출력을 보여라) · `pnpm e2e`

## 구조
`src/domains/<name>/{ui,model,api,index.ts}` vertical. 도메인 간 import는 기본 금지(허용 엣지는 `docs/adr/0001`). `src/shared`는 도메인을 모른다. 경계는 ESLint가 막는다 — 막히면 우회하지 말고 물어라.
Next: `src/app`은 라우터 폴더. page.tsx는 도메인 re-export 한 줄.

## 참고 (필요할 때 읽기)
`docs/conventions.md`(이유·예시) · `docs/adr/` · `openspec/specs/` · `design/` · 파일별 규칙은 `.claude/rules/`
작업 절차는 develop-fe 스킬.
```

## 4. `.claude/rules/` 예시
```md
---
paths: ["src/domains/**/ui/**/*.tsx", "src/shared/ui/**/*.tsx"]
---
# 컴포넌트
- 파일명 = 컴포넌트명(PascalCase). 훅 `use*`, 핸들러 `handle*`, props `on*`
- 200줄 또는 책임 2개면 분리. props 7개 넘으면 객체로
- 빈·로딩·에러 상태 필수. `role`/`aria-*` 수동 추가 전에 네이티브 요소
- 정본 예시: `src/shared/ui/button/Button.tsx`
```
```md
---
paths: ["src/domains/**/model/**"]
---
# 상태
- 로컬 `useState` → 공유 UI context → 서버 [TODO: query lib] → URL [TODO]. 같은 진실 두 곳 금지
- 에러는 `api/`에서 정규화, `ui/`는 에러 상태만 렌더
```
```md
---
paths: ["**/*.test.ts?(x)", "**/*.browser.test.tsx", "e2e/**"]
---
# 테스트
- 계층 결정표·루프는 develop-fe 스킬 `tdd-frontend.md`. 역할 쿼리, mock은 MSW만, 시나리오 1개 = 테스트 1개
```
path-scoped rule은 compaction 후 재주입되지 않는다 → "절대" 규칙은 여기 두지 않는다(훅).

## 5. 훅 세트 (`.claude/settings.json`, `[TODO]`)
| 이벤트 | 매처 | 동작 | 시간 |
|---|---|---|---|
| PostToolUse | `Edit\|Write` | 그 파일만 `prettier --write` + `eslint --fix`(boundaries·tailwind·vitest 규칙 포함) | <1s |
| PreToolUse | `Edit\|Write` **+ `Bash`** | `package.json`·lockfile·린터 설정·`.env`: Bash 쪽은 `tee`/`sed -i`/`>`/`npm i` 패턴 검사. `*.test.*`는 `TDD_PHASE=red` 아닐 때 거부 | |
| PreToolUse | `Bash` | `--no-verify`/`-n`/`HUSKY=0`/`LEFTHOOK=0`/`core.hooksPath`/`push --force` 거부 | |
| Stop | — | 코드 편집한 턴만 `pnpm verify`(`stop_hook_active` 가드, 실패 exit 2 + 마지막 50줄, timeout 올릴 것). 8회 차단 후 강제 종료됨 | 전체 |
| `permissions.deny` | — | 위 Bash 패턴을 **deny에도** 넣는다 — 훅 `if` 필터는 fail-open | |
| env | — | `GIT_PAGER=cat` (pager 행 방지) | |

`tsc`를 PostToolUse에 넣지 않는다(편집 50회 × 20초). 전체 검사는 Stop. 훅이 너무 자주 막으면 범위를 줄인다 — 우회 습관이 더 위험.
