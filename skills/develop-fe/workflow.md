# develop-fe 워크플로우

프론트엔드 작업을 받아서 PR까지 가는 절차. 근거는 `references/methodologies.md`, 도구 설정은 `references/openspec-setup.md`, 결정 기록은 `adr/` — 경로는 모두 **플러그인 루트** 기준(adr/0010). 테스트 작성은 `test-fe`, 리뷰는 `review-fe` 스킬이 맡고 이 파일은 호출만 한다.

**구조**: OpenSpec이 아티팩트의 척추(스펙·tasks·아카이브), Compound Engineering은 주변부(brainstorm·review·simplify·compound·commit·PR·debug). `ce-plan`/`lfg`는 쓰지 않는다(OpenSpec change와 아티팩트가 겹침). `ce-work`는 증거 계약·멱등성이 있어 실험 B(adr/0001)로 검증 중, 기본은 `opsx:apply`. `ce-code-review`엔 항상 스펙 경로를 넘긴다.
**원칙**: 체크를 먼저 정하고, 빨간 불을 보고, 구현하고, 증거를 낸다. 문서는 결정(WHAT)만, 코드(HOW)는 안 쓴다. 규칙은 프롬프트가 아니라 훅·린트로 강제한다.
**디자인**: 원천은 Figma, 작업 입력은 저장소의 `design/` 스냅샷. Figma MCP는 새 화면·디자인 변경·최종 검증 때만 부른다(`references/figma-design-source.md`, `adr/0002`). 미완성 표시(`📝 TODO:`/`🚧 WIP`/`⬜ PLACEHOLDER`)된 부분은 구현하지 않고 디자인 갭 루프(2-D)로 보낸다(`adr/0003`).

> `[TODO]` = 프로젝트 시작 시 확정할 것(스택, 테스트 러너, 린터, 훅). 확정하면 이 파일과 `openspec/config.yaml`에서 `[TODO]`를 없앤다.

---

## 0. 세션 시작 (매번, 30초)
0. 세팅 확인: `package.json`에 `verify` 스크립트, `openspec/config.yaml`, `.claude/rules/`가 없으면 **멈추고 `/develop-setup`을 먼저 하라고 안내**한다(여기서 세팅을 즉흥으로 만들지 않는다). Tier-1 한 줄 수정은 예외로 진행 가능
1. `git status` / `git log --oneline -10`
2. `pnpm exec openspec list` — 열린 change 있으면 그 `tasks.md`부터 읽는다(CLI는 프로젝트 devDependency. 없으면 세팅 누락 → `/develop-setup`)
3. `docs/solutions/` 를 task 키워드로 grep — 이미 푼 문제인가
4. `[TODO: pnpm typecheck]` 한 번 — 깨져 있으면 **새 작업 전에 고친다**
4-1. API가 걸린 작업이면 `api/openapi.yaml` 있나 + `pnpm api:check` — 없거나 빨강이면 1장 "계약 상태 판정"으로
5. 화면 작업이면 `design/screens/<slug>/summary.md` 있나 확인. 없으면 Figma 호출 규칙(`figma-design-source.md` §3)대로 스냅샷부터. `design/` 자체가 없으면(프로젝트 첫 화면) §2 초기 스냅샷(토큰·map·components)을 먼저 한다 — 이건 Tier와 무관하게 1회

## 1. Task 분석 → 티어 판정
기준은 **작업량이 아니라 불확실성과 파급 범위**. 판정에 1분 이상 쓰지 않는다. 애매하면 낮은 티어로 시작하고 기준을 넘으면 올린다.

| | Tier-1 패치 | Tier-2 기능 | Tier-3 에픽 |
|---|---|---|---|
| 판정 | **diff를 한 문장으로 설명할 수 있나?** | 파일 여러 개 / 새 컴포넌트·라우트 / 상태 추가 / 접근법 둘 이상 | 여러 기능이 엮임, 모르는 영역, 새 의존성·아키텍처 결정 |
| 예 | 스타일, 오타, 조건 하나, 원인 명확한 버그 | 폼 하나, 리스트+상세, API 연동 하나 | 인증 전체, 디자인시스템 도입, 결제 |
| OpenSpec | 안 씀 | change 1개, 스키마 `feature`(specs+tasks) | brainstorm → change N개, 스키마 `spec-driven`(full) |
| 사람 게이트 | 없음 | 구현 전 질문 1회(묶어서, 최대 5개) | 결정 지도 합의 + change마다 시작 확인 |
| 컨텍스트 | 한 세션 | change 1개 = 세션 1개 | **change마다 새 세션** |

버그는 티어와 별개로 **`/ce-debug`** 로 진입(원인 명확하면 Tier-1).

**디자인 상태 판정** (화면이 걸린 task만, 티어와 직교):
| `design/screens/<slug>` | Figma 노드 이름 | 처리 |
|---|---|---|
| 있음 | — | 스냅샷만 읽고 진행. **Figma 호출 없음** |
| 없음 | `✅ Ready` 섹션 | 스냅샷 생성(5~15 호출) → 진행 |
| 없음/있음 | `📝 TODO:` / `🚧 WIP` / `⬜ PLACEHOLDER` 포함 | 그 부분은 **2-D 디자인 갭 루프**. 나머지는 정상 진행 |
| — | 디자인 자체가 없음 | 2-D, 입력은 `tokens.css`+`components.md`+같은 플로우 Ready 화면 |

**계약 상태 판정** (API가 걸린 task만, 티어와 직교 — 상세·도구 `references/api-contract.md`, `adr/0008`):
| 상태 | 판정 | 처리 |
|---|---|---|
| A 스펙 있음 | `api/openapi.yaml`이 백엔드 원천과 일치 | `api:gen` → **생성물(`src/api/*.gen.ts`)만 import**. 손으로 타입·fetch 금지(린트·훅) |
| B 스펙 없음 | 파일 없음 / 새 엔드포인트 | 프론트가 **DRAFT 스텁**(최소: path 1·schema·Problem) → Tier-2 질문 ⑥에 포함 → 생성 → 생성된 MSW 핸들러가 실행 가능한 계약 |
| C 기존 코드, 스펙 없음 | 호출은 있는데 스펙 없음 | **별도 Tier-2 change `api-contract`**(retrofit: 인벤토리 → 스펙 → 생성 → 엔드포인트 단위 strangler). 기능 change와 섞지 않는다 |
| D 스펙에 없는 게 필요 | 구현 중 발견 | 코드·목에 먼저 넣지 않는다. 멈춤 → 스펙 diff 제안 → 확정 → `api:gen` (디자인 갭 루프의 API판) |

## 2. 티어별 절차

### Tier-1 패치
1. 관련 코드 읽기. **같은 걸 하는 컴포넌트/유틸 먼저 검색**(중복 생성이 에이전트 1위 실패)
2. 체크 정하기: 기존 테스트 수정/추가(`/test-fe`) **또는** 스크린샷 1장(프로필 뷰포트 중 1개). 순수 스타일이면 스크린샷만
3. 고친다 → `[TODO: typecheck + lint + 관련 test]` + 증거
4. `/review-fe code`(Tier-1 = L1 정확성·중복만) → 커밋 1개 → 5장

### Tier-2 기능
1. **탐색**: 관련 코드, 기존 컴포넌트, `openspec/specs/`(해당 capability 있나), `docs/solutions/`, **`design/screens/<slug>/summary.md` + `reference@2x.png`**(있으면 Figma를 열지 않는다). 코드·스냅샷이 이미 답하는 건 묻지 않는다
2. **질문 1회** (AskUserQuestion, 최대 5개 묶어서). 항상 포함: ① 참고할 비슷한 기존 코드 있나 ② Figma 노드 URL(스냅샷 없을 때만) ③ 빈·로딩·에러 상태 — summary.md에 "Figma에 없음"이면 여기서 확정 ④ 반응형 범위 ⑤ 내가 가정한 기본값 목록 — 반박만 받는다 ⑥ **계약**: 스펙 URL/파일 있나? 없으면 "내가 DRAFT 스텁을 쓴다 — 이 shape(요청·응답·에러)가 맞나"를 스텁 요약과 함께
3. **`/opsx:propose`** → `openspec/changes/<slug>/` 에 `specs/<capability>/spec.md`(delta, 시나리오 = 테스트 원천) + `tasks.md`(task마다 `→ verify:`). `[NEEDS CLARIFICATION]`이 남아 있으면 tasks 전에 해소. `openspec validate <slug> --strict`
4. **`/opsx:apply`** — task 하나씩:
   - 테스트 task: **`/test-fe`**(Skill 도구)로 — 계층 선택·쿼리·mock 규칙은 거기. Edit 시 권한 프롬프트가 뜬다 — **사람이 diff를 승인하는 것이 red 게이트**(adr/0009). 승인되면 실행 → **실패 출력과 이유("기능 미구현", import 오류 아님)를 보여주고** `test(scope):` 커밋. 거부되거나 비대화형이라 승인자가 없으면 **구현 task로 넘어가지 말고 멈춰서** 사람에게 알린다(테스트 없는 구현 금지)
   - 구현 task: 테스트 파일은 건드리지 않는다(Edit는 ask, Bash 쓰기는 deny). 초록 + PASS_TO_PASS → `[x]` → `feat(scope):` 커밋. diff에 `*.test.*`가 섞이면 안 됨
   - UI task: 뷰포트·다크모드·키보드 증거는 **`.claude/rules/platform.md` 프로필**대로(`references/platform-fit-frontend.md`; 없으면 웹 375/768/1280) `agent-browser`(`[TODO]`)로 찍고, 콘솔 에러 0. 접근성 증거: axe `serious+` 0건 + Tab 시퀀스 목록(`references/a11y-frontend.md` §3). 스냅샷이 있으면 `reference@2x.png`와 나란히 비교해 차이 나열 — 값은 스크린샷이 아니라 `getComputedStyle`로 확인(`figma-design-source.md` §6)
   - Figma 출력(`context.tsx`)은 참고지 복사 대상이 아니다: `leading-[22.126px]`류는 토큰으로, 토큰이 없으면 사용자에게 올린다. 아이콘·이미지는 export된 에셋을 받아 커밋(URL은 7일 만료)
   - 마지막 "Converge" 그룹: spec의 모든 시나리오 ↔ 코드 대조, 빠진 건 task로 append하고 마저 한다
5. **`/review-fe code`** (Skill 도구로 `cgamja:review-fe`, change slug·티어를 넘긴다) — 렌즈(L1 정확성·중복 / L2 스펙 완전성 / L3 테스트 무결성 + UI면 L4 접근성·L5 플랫폼 + API면 L6 경계·계약)를 persona 서브에이전트로 병렬 실행해 한 표로 합친다(adr/0012 개정 1 — Tier-2는 `ce-code-review` 없이). **Agent 도구로 리뷰어를 즉석 제작하지 않는다**(2026-08-21 두 번 연속 이탈). blocker 있으면 반영 후 해당 렌즈만 재실행 1회. 그다음 `/ce-simplify-code` 1회
6. **Figma 대조** (Ready 화면일 때): 토큰 린트 0건 → computed style 5~10개 → 2x 픽셀/SSIM 97% 이상, EXPECTED/ACTUAL/DIFF 3장 저장. `get_screenshot` 1회로 기준 PNG 갱신 가능(`figma-design-source.md` §6)
7. **`/opsx:archive`** → delta가 `openspec/specs/`에 병합 → 5장, 6장

### 2-D. 디자인 갭 루프 (미완성·미디자인 부분) — `adr/0003`
Tier-2 3단계(propose) **전에** 돈다. 디자인이 확정돼야 시나리오를 쓸 수 있다.
1. **입력**: 해당 노드 `get_design_context`(와이어프레임의 구조·카피는 살린다, 호출 1회) + `tokens.css` + `components.md` + 같은 플로우의 Ready 화면 `reference@2x.png`. 레퍼런스 피그마(`app-ref-to-figma`)에 같은 기능 타앱 화면이 있으면 2~3장
2. **후보**: `design` 스킬로 캔버스 Artifact에 **2~3안** 나란히. 제약: 토큰·기존 컴포넌트만, 와이어프레임 정보 구조 유지, 안마다 "무엇이 다른가" 한 줄. 사용자가 캔버스에서 직접 고친다
3. **확정**: 고른 안(또는 합친 안)과 이유를 `design/screens/<slug>/summary.md` "디자인 결정"에 한 줄. 여기서부터 Tier-2 3단계로
4. **구현 후 거울**: 실행 화면을 `generate_figma_design`으로 Figma `🧩 Built-in-code` 섹션에 평면 캡처, 프레임 이름 `<slug> · source: code · <날짜>`. `use_figma` 재조립은 하지 않는다. Full seat 없으면 생략하고 Artifact 링크를 summary에
5. 스냅샷 생성(§2) → 이후 Ready 화면과 동일 취급

### Tier-3 에픽
1. **`/ce-brainstorm`** — 모르는 영역이면 blindspot pass로 결정 지도(3~7개) 합의. 산출물(`docs/plans/*requirements-only*`)은 **proposal의 입력**이지 플랜이 아니다
2. **change 분해** (graph-engineering 휴리스틱): 후보 단계 나열 → 쌍마다 "B가 A의 출력(타입·컴포넌트·API)을 읽나?" → 읽으면 순차, 아니면 독립. **숨은 엣지** 확인: 같은 파일 쓰기, 시그니처/스키마 변경은 반드시 선행. 없으면 "없음"이라고 명시
3. 첫 change를 `/opsx:propose --schema spec-driven`(proposal + specs + design + tasks). 나머지 change는 이름만 예약
4. **change마다 새 세션에서 Tier-2 4~6단계.** 세션 간 상태는 `tasks.md`·git log·`docs/solutions/`뿐이라고 가정
5. 독립 change 2개 이상이 **둘 다 오래 걸릴 때만** worktree 병렬(`[TODO: 포트 규칙]` 정하기 전엔 금지)
6. 전부 archive 후 통합: e2e 스모크 + 주요 플로우 스크린샷 + `/review-fe tier-3`(렌즈 L1~L7 전부)

## 3. 공통 규칙

### 3-1. 검증 스택 — 싸게 → 비싸게, 위가 깨지면 아래로 안 내려간다
1. **결정적** = **`pnpm verify`** 한 스크립트(`api:check && tsc --noEmit && eslint . && vitest run && knip` — `api:check` = 재생성 후 `git diff --exit-code src/api`). 완료 정의는 이 이름 한 곳에만 있고 Stop 훅·CLAUDE.md·OpenSpec guidance·CI는 이름만 참조한다(adr/0005). ESLint엔 boundaries·better-tailwindcss·vitest 규칙 포함
2. **행동**: Playwright 스모크 2~3개 + `@axe-core/playwright`(violations 블로킹) · 다이얼로그는 `toMatchAriaSnapshot`
3. **시각**: 뷰포트 3개 스크린샷을 **사람이 본다**. `toMatchScreenshot`은 디자인시스템 프리미티브에만. Ready 화면은 추가로 Figma 대조(토큰 린트 → computed style → 2x SSIM 97%+, `figma-design-source.md` §6)
4. **LLM judge**: 안 쓴다. 취향은 사람

훅(`[TODO: settings.json]`, 표는 `project-conventions.md` §5): `PostToolUse(Write|Edit)` → 그 파일 format+lint(1초 이내, tsc 금지) / `Stop` → `pnpm verify`(코드 편집 턴만) / `PreToolUse` Write|Edit **+ Bash** → `package.json`·lockfile·린터 설정·`*.test.*`(구현 턴) 보호, `--no-verify` 거부 — 같은 패턴을 `permissions.deny`에도(훅 `if`는 fail-open).

### 3-2. 테스트 규칙 → `/test-fe` 스킬
- 테스트 task는 **Skill 도구로 `cgamja:test-fe`를 부른다**(시나리오·change slug를 넘긴다). 계층 선택(jsdom / Browser Mode / E2E), 쿼리·mock 규칙, red 게이트(adr/0009)는 거기에 있다. 여기서는 결과만 받는다: 실패 출력 원문 + 이유 + `test(scope):` 커밋
- TDD의 목적은 품질이 아니라 **리뷰 게이트 + 변조 방지**(adr/0004). 구현 턴은 테스트 파일을 건드리지 않고(Edit ask, Bash 쓰기 deny), 기존 초록은 초록 유지(PASS_TO_PASS), `feat` diff에 `*.test.*` 금지
- 못 만들면 **실패한 assertion 원문**과 함께 멈춘다. assertion 완화·skip·snapshot 재생성 금지

### 3-3. 코드 규칙 (프론트 실패 모드 대응; 프로젝트별 규칙 배치와 아키텍처 경계는 `references/project-conventions.md`)
- 아키텍처는 spec이 아니라 `docs/adr/0001-domain-structure.md` + ESLint 경계 규칙에. 기본값은 bulletproof-react features + FSD 세그먼트(`app/domains/<name>/{ui,model,api,index.ts}/shared`). **도메인 간 import는 기본 금지**, 허용 엣지는 린트 설정+ADR에 명시(adr/0006). 경계에 막히면 우회하지 말고 묻는다
- 만들기 전에 `src/shared`와 대상 도메인 `index.ts`를 grep, 재사용한 걸 PR에 적는다(에이전트 코드베이스 1위 실패 = 의미적 중복)
- 만들기 전에 검색. 비슷한 게 있으면 확장/합성, `V2` 금지
- 상태 위치: 로컬 `useState` / 공유 UI context / 서버 `[TODO]` / URL `[TODO]`. 같은 진실을 두 곳에 두지 않는다
- 색·간격·폰트는 **토큰만**(`tokens.css` = Figma Variables export, 리뷰되는 원천). Figma의 `leading-[22.126px]` 류는 토큰으로 치환, 없으면 질문. 토큰 동기화는 `get_variable_defs` diff **보고만**, 자동 덮어쓰기 금지
- Figma 호출은 `figma-design-source.md` §3 표로만 판단. "이 값이 뭐지"로 Figma를 열지 않는다 — 스냅샷 갭이면 한 번 채운다
- 새 의존성은 승인 없이 추가 안 함
- 접근성은 세 층(린트 `jsx-a11y`/`react-native-a11y` → axe → 역할 쿼리)이 막고, 못 잡는 것은 `references/a11y-frontend.md` §2 체크. `role`/`aria-*` 수동 추가 전에 네이티브 요소로, 아이콘 버튼 이름은 동작("닫기")
- 빈·로딩·에러 상태는 spec에 없어도 기본 포함

### 3-4. 컨텍스트 규칙
- 같은 수정 2번 실패 → `/clear`, `docs/solutions/` 확인, 접근 변경. "더 열심히"가 아니라 **빠진 도구/규칙**을 찾는다
- 탐색은 Explore 서브에이전트로 — 본 컨텍스트에 파일 덤프 금지. **서브에이전트는 `model:`을 항상 명시**(`references/model-routing.md`, adr/0011): 탐색·수집 `haiku`, 구현·테스트 작성 `sonnet`, 리뷰 렌즈 `opus`. 티어 판정·질문 설계·갭 판단·계약 판정은 본체가 직접
- 에이전트가 규칙을 어기면 CLAUDE.md에 줄을 늘리지 말고 **린트·훅·`openspec/config.yaml` rules**로 내린다

## 4. 기록 (Compound)
- **살아있는 스펙** = `openspec/specs/`. archive가 갱신한다. 직접 고칠 땐 `/opsx:sync`
- **학습** = `/ce-compound` → `docs/solutions/`. 세션당 0~1개, 억지로 만들지 않는다
- **결정** = `docs/adr/NNNN-*.md`(아키텍처·도구 선택). 규약은 이 스킬의 `adr/README.md`와 동일
- **디자인 스냅샷** = `design/`(map, tokens, components, screens/). 재스냅샷은 덮어쓰기 → `git diff design/`이 디자인 변경 이력. summary.md의 "디자인 결정"이 코드 우선 부분의 원천
- **일회용** = `docs/plans/`(brainstorm 산출물), `openspec/changes/archive/`, Artifact 후보 캔버스. 끝나면 갱신 안 함

## 5. 커밋
- `feat|fix|refactor|test|chore|docs(scope): 요약`. task 1개 = 커밋 1개 기본
- 테스트 변경은 **별도 커밋**(테스트 약화가 리뷰에 바로 보이게). 스펙은 `docs(spec): ...`
- `/ce-commit` 사용. 푸시는 change 단위

## 6. PR
- Tier-1: 모아서 1개 / Tier-2: change 1개 = PR 1개 / Tier-3: change마다, 400줄 넘는 레이어 diff만 stacked
- `/ce-commit-push-pr`, 대기 중 필요 시 `/ce-babysit-pr`

```md
## What
<한 문장>

## Why
<proposal.md 요약 또는 이슈 링크>

## Spec
- openspec/changes/<slug>/ (archive 후엔 openspec/specs/<capability>/)

## 검증 증거
- [ ] tsc / lint / vitest: <출력 요약>
- [ ] Playwright 스모크 + axe: <결과>
- [ ] 스크린샷(프로필 뷰포트 전부, 다크·키보드 해당 시): <경로>
- [ ] 접근성: axe serious+ <n건> · Tab 시퀀스 <경로>
- [ ] 리뷰: review-fe 판정 <blocker 0 · should n> · 렌즈 <목록>
- [ ] Figma 대조: 토큰 린트 <n건> · computed style <n/n> · SSIM <xx%> · DIFF 이미지 <경로> (Ready 화면만; 코드 우선 부분은 Artifact 확정본 링크)

## 범위 밖 / 알려진 한계

## 리뷰어가 볼 곳
<판단이 들어간 파일 1~3개>
```

## 7. 재검토 조건 (10개 task마다 점검)
- Tier-2 스펙 작성이 구현보다 오래 걸린 게 2번 → `feature` 스키마 instruction을 더 줄인다
- **스펙이 테스트된 동작과 모순된 채 출하된 change 2개** → 살아있는 스펙 유지 실패, CE-only로 (adr/0001). 에이전트는 스펙을 읽으므로 "안 읽음"이 아니라 "오래된 걸 믿음"이 위험. CI `openspec validate --archived` 필수
- 실험 B(`ce-work` 브리지, adr/0001) 2개 change 후 채택/폐기 기록
- 브라우저 테스트가 CI에서 주 2회 flaky → jsdom 기본으로 복귀(adr/0004)
- 도메인 간 허용 엣지 3개째 → `widgets/` 층 ADR(adr/0006)
- 리뷰 지적 3회 연속 스타일뿐 → persona 지시문 수정(`agents/`) · 렌즈별 "없음" 3연속 → 그 렌즈 Tier-3 전용(`review-lenses-frontend.md` §5)
- sonnet 구현이 같은 스펙에서 2회 실패 → 그 task 유형 opus로(`model-routing.md` §4)
- 같은 실패가 `docs/solutions/`에 2번 → 린트/훅/config rules로 승격
- 훅을 우회하는 습관이 생김 → 훅 범위 축소
- 오래된 스냅샷으로 잘못 구현 2번 → 세션 시작 시 `get_metadata` 1회 변경 감지 추가(adr/0002)
- 디자인 갭 확정 후 사용자가 Figma에서 다시 손보는 일 2번 → 후보를 Figma에서 직접 만드는 경로 검토(adr/0003)
- Figma 호출이 하루 50회를 넘는 날이 생김 → 스냅샷 범위가 좁은 것. §2 항목 확대
- 새 방법론을 보게 되면: "5가지 동작(스펙·계획·체크·검증 분리·컨텍스트) 중 어느 걸 더 싸게 하나?"로만 평가. 답이 없으면 리브랜딩
