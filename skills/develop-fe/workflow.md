# develop-fe v2 워크플로우

프론트엔드 작업을 받아서 PR까지 가는 절차. 결정 기록은 `adr/`(v2 전환은 adr/0026), 경로는 모두 **플러그인 루트** 기준. 코드 작성 기준(SPEC)은 **`docs/spec/`** — CLEAN-CODE·ARCHITECTURE·WEB-SPEC/APP-SPEC·GOOD-BAD-PATTERN·LIBRARY가 코드의 원천이고, COMMIT·PR·ISSUE가 산출물 형식의 원천이다.

**구조**: OpenSpec이 아티팩트의 척추(스펙·tasks·아카이브, Tier-2만). 테스트는 `test-driven-development` 스킬, 브라우저 검증은 `browser-testing-with-devtools`, 비주얼 QA는 `cgamja:qa-cgamja`, 리뷰는 `cgamja:review-cgamja` + `code-review`. Compound Engineering은 주변부(brainstorm·commit·PR·debug·compound)만. `ce-plan`/`lfg` 금지(adr/0001).
**원칙**: 체크를 먼저 정하고, 빨간 불을 보고, 구현하고, 증거를 낸다. 규칙은 프롬프트가 아니라 훅·린트·git 훅으로 강제한다. 문서는 결정(WHAT)만, 코드(HOW)는 안 쓴다.
**디자인**: 원천은 Figma, 작업 입력은 저장소의 `design/` 스냅샷(adr/0002). 미완성 표시(`📝 TODO:`/`🚧 WIP`/`⬜ PLACEHOLDER`)는 구현하지 않고 2-D 디자인 갭 루프로(adr/0003).

> 프로젝트 확정값(명령·패턴·수단)은 본문에 쓰지 않는다 — `.claude/cgamja.json` **선언 키**로 참조한다(adr/0014). 키가 null이면 명시된 대체 경로로 간다.

## 외부 스킬 배치표 (adr/0026 §8 — 설치 원천은 `docs/spec/AI-SPEC.md`)

| 단계 | 스킬 (Skill 도구로 호출) | 미설치 시 대체 |
|---|---|---|
| 탐색·컨텍스트 | `context-engineering` | 3-4 컨텍스트 규칙만 적용 |
| 스펙·tasks | OpenSpec (`/opsx:*`) | 없으면 `/develop-setup` 안내 후 멈춤 |
| 디자인 산출 | `frontend-design` + `design-taste-frontend`(taste-skill) + `frontend-ui-engineering` | `design` 스킬 + `docs/spec/WEB-SPEC.md` 토큰 규칙 |
| 구현 | `vercel-composition-patterns`(컴포넌트 합성), `react-native-skills`(네이티브), typescript-lsp MCP | `docs/spec/` SPEC만으로 진행 |
| 테스트 | `cgamja:test-driven-development` (vendored, MIT) | — (내장, 항상 있음) |
| 브라우저 검증 | `cgamja:browser-testing-with-devtools` (vendored — chrome-devtools MCP 필요) | 스크린샷 수단 탐색(`docs/guides/evidence-capture.md`) |
| 비주얼 QA | `cgamja:qa-cgamja` | — (플러그인 내장, 항상 있음) |
| 리뷰 | `cgamja:review-cgamja` + `/code-review`(공식 플러그인) | — (review-cgamja는 내장) |
| 성능 task | `performance-optimization` | `docs/guides/platform-fit-frontend.md` 기준만 |
| 관측 task | `observability-and-instrumentation` | 생략(스펙에 없으면 안 만든다) |
| 보안 점검 | `claude-security` | 사용자 요청 시에만 |
| 설명·현황 | `eli5`, `project-artifact` | 사용자 요청 시에만 |

미설치 스킬을 대체 경로로 탄 경우 세션 보고에 한 줄 남긴다(3회 누적 → vendoring 검토, adr/0026 재검토 조건).

---

## 0. 세션 시작 (매번 — fast-path 먼저, 점검은 뒤이어)
**Fast-path (adr/0019)**: 사용자 지시에 즉시 실행 가능한 첫 행동(브랜치 생성, "바로 X부터")이 있으면 그것이 첫 도구 호출이다. **첫 가시 보고(티어 한 줄)는 30초 안에**, 아래 점검은 그 뒤에(가능한 것은 병렬로).
0. 세팅 확인: `package.json`의 `verify` 스크립트 · `openspec/config.yaml` · `.claude/rules/` · `.claude/cgamja.json` 중 없는 게 있으면 **멈추고 `/develop-setup` 안내**. Tier-1 한 줄 수정은 예외로 진행 가능
0-b. **git 훅 확인/설치**: `git config core.hooksPath`가 비어 있거나 pre-push가 없으면 — `mkdir -p .githooks && cp <플러그인>/skills/develop-fe/templates/git-hooks/* .githooks/ && chmod +x .githooks/* && git config core.hooksPath .githooks`. 이미 husky 등이 있으면 덮지 말고 기존 훅에 같은 검사가 있는지 대조만 하고 보고. **pre-push가 막으면 커밋을 고친다**(5장) — `--no-verify` 금지(스킬 훅이 거부)
1. `git status` / `git log --oneline -10`
2. `openspec list` — 열린 change 있으면 그 `tasks.md`부터
3. `docs/solutions/` 를 task 키워드로 grep — 이미 푼 문제인가
4. `commands.typecheck` 1회 — 깨져 있으면 새 작업 전에 고친다
4-1. API가 걸린 작업이면 계약 원천(`contract.source`) + 생성물 드리프트 검사(1장 계약 판정)
5. 화면 작업이면 `design/screens/<slug>/summary.md` 확인. 없으면 Figma 호출 규칙(`docs/guides/figma-design-source.md` §3)대로 스냅샷부터

## 1. Task 분석 → 티어 판정 (2단계, adr/0026)
기준은 작업량이 아니라 **불확실성과 파급 범위**. 판정에 1분 이상 쓰지 않는다. 애매하면 Tier-1로 시작하고 기준을 넘으면 올린다.

| | Tier-1 패치 | Tier-2 기능 |
|---|---|---|
| 판정 | **diff를 한 문장으로 설명할 수 있나?** | 파일 여러 개 / 새 컴포넌트·라우트 / 상태 추가 / 접근법 둘 이상 |
| 예 | 스타일, 오타, 조건 하나, 원인 명확한 버그 | 폼 하나, 리스트+상세, API 연동 하나 |
| OpenSpec | 안 씀 | **change 1개, 스키마 `feature`** (specs+tasks) |
| 사람 게이트 | 없음 | 질문 1회(묶어서, 최대 5개) + red 게이트 1회(세션당, adr/0018) |

- **큰 작업(구 Tier-3)**: 여러 기능이 엮이거나 모르는 영역이면 `/ce-brainstorm`으로 결정 지도를 합의한 뒤 **Tier-2 change 여러 개로 분해**한다. 분해 휴리스틱: 후보 단계 나열 → 쌍마다 "B가 A의 출력(타입·컴포넌트·API)을 읽나?" → 읽으면 순차, 아니면 독립. 숨은 엣지(같은 파일 쓰기, 시그니처 변경)는 반드시 선행. change 4개 초과가 반복되면 adr/0026 재검토
- 버그는 티어와 별개로 **`/ce-debug`** 로 진입(원인 명확하면 Tier-1). 수정 전 **재현 테스트 먼저**(`test-driven-development` 스킬 규칙)

**디자인 상태 판정** (화면 task만, 티어와 직교):
| `design/screens/<slug>` | Figma 노드 이름 | 처리 |
|---|---|---|
| 있음 | — | 스냅샷만 읽고 진행. Figma 호출 없음 |
| 없음 | `✅ Ready` | 스냅샷 생성 → 진행 |
| — | `📝 TODO:`/`🚧 WIP`/`⬜ PLACEHOLDER` | 그 부분은 2-D 디자인 갭 루프 |
| — | 디자인 자체가 없음 | 2-D, 입력은 `tokens.css`+`components.md`+같은 플로우 Ready 화면 |

**계약 상태 판정** (API task만 — 상세 `docs/guides/api-contract.md`, adr/0008): A 스펙 있음 → 생성물만 import / B 스펙 없음 → DRAFT 스텁 → 질문 ⑥ → 생성 / C 기존 코드에 스펙 없음 → 별도 Tier-2 change `api-contract`(retrofit) / D 스펙에 없는 게 필요 → 멈추고 스펙 diff 제안.

## 1-b. 디자인 플래그 (adr/0026 §7)

`/develop-fe --only-wf | --only-design | --wf-and-design` — 플래그가 있으면 이 세션의 산출물은 **디자인 아티팩트**이고, 코드 구현·티어 절차는 돌지 않는다(구현은 후속 `/develop-fe` 세션).

| 플래그 | 입력 | 산출 | 로드할 스킬 |
|---|---|---|---|
| `--only-wf` | 와이어프레임(Figma 노드·스케치·요구사항)만 | **와이어프레임** — 정보 구조·플로우·상태(빈/로딩/에러)만, 스타일 없음(그레이스케일·플레이스홀더) | `design` 스킬 캔버스 |
| `--only-design` | 확정 디자인(Figma·스타일 가이드)만 | **하이파이 디자인** — 토큰·컴포넌트 준수한 신규/변형 화면 | `frontend-design` + `taste-skills` + `frontend-ui-engineering` |
| `--wf-and-design` | 와이어프레임 | **하이파이 디자인** — 와이어프레임의 정보 구조를 유지하며 스타일 입힘 | 위 셋 + 와이어프레임 구조 보존 검증 |

공통 절차:
1. 입력 수집: 지정된 입력만 읽는다(--only-wf에서 기존 하이파이 화면을 참조해 스타일을 끌어오지 않는다; --only-design에서 와이어프레임이 있어도 무시하지 않되 "입력이 디자인뿐"임을 보고)
2. 산출: 후보 **2~3안**을 `design` 스킬 캔버스 Artifact에 나란히 — 안마다 "무엇이 다른가" 한 줄. **Figma에 쓰지 않는다**(Figma는 읽기 전용 원천, adr/0026). 제약: `tokens.css`·기존 컴포넌트만(하이파이일 때), 새 색·간격 값 발명 금지
3. **디자인 리뷰**: `cgamja:qa-cgamja` 기준으로 검증 시점(THEN 상태 — 모달·에러·다크모드)이 커버되는지 체크리스트로 확인 + 사용자 확정
4. 확정안과 이유를 `design/screens/<slug>/summary.md` "디자인 결정"에 기록 → 여기서 세션 종료. 구현은 별도 세션

## 2. 티어별 절차

### Tier-1 패치 — "그냥" 진행
1. 관련 코드 읽기. **같은 걸 하는 컴포넌트/유틸 먼저 검색**(중복 생성이 에이전트 1위 실패, `docs/spec/GOOD-BAD-PATTERN.md` §6)
2. 체크 정하기: 기존 테스트 수정/추가(`test-driven-development` 규칙) **또는** 스크린샷 1장. 순수 스타일이면 스크린샷만
3. 고친다 → `commands.typecheck`·`commands.lint`·관련 테스트 실행 + 증거
4. 리뷰: `code-review` 스킬 low 레벨 1회 (철학 리뷰는 생략 가능 — diff 한 문장짜리에 문서 대조는 과함) → 커밋 1개 → 5장

### Tier-2 기능 — OpenSpec
1. **탐색**: 관련 코드, 기존 컴포넌트, `openspec/specs/`, `docs/solutions/`, `design/screens/<slug>/`(있으면 Figma 안 연다). 긴 문서·티켓은 서브에이전트가 읽고 요약만(`context-engineering` 원칙). 코드가 이미 답하는 건 묻지 않는다
2. **질문은 예외다 — 기본은 전진**(adr/0029). 정지 허용 목록(3-0)에 없으면 묻지 말고 **가정 3줄**을 남기고 같은 턴에서 계속한다. 목록에 해당해 진짜로 물을 때만 AskUserQuestion 1회(묶어서, 최대 5개): ① 참고할 기존 코드 ② Figma 노드 URL(스냅샷 없을 때만) ③ 빈·로딩·에러 상태 ④ 반응형 범위 ⑤ 계약 DRAFT 스텁 shape(해당 시). 각 질문에 **"답이 없으면 이것으로 진행합니다"** 기본값을 명시한다
   > 구 ⑤ "가정한 기본값 목록(반박만 받기)"은 폐지 — AskUserQuestion은 답이 올 때까지 턴이 끝나므로 "반박만 받기"가 성립하지 않았다. 가정은 3-0의 3줄로 낸다
3. **`/opsx:propose`** → `openspec/changes/<slug>/` 에 spec delta(시나리오 = 테스트 원천) + `tasks.md`(task마다 `→ verify:`). `openspec validate <slug> --strict`. propose 중엔 프로젝트 코드를 편집하지 않는다(planning boundary, adr/0019)
4. **`/opsx:apply`** — task 하나씩, **메인은 위임·판정·커밋만 한다(adr/0027)**:
   - **위임 기본**: 구현·테스트 작성 unit은 서브에이전트 1개(fresh context, `model:` 명시 — 구현·테스트 sonnet)로 내린다. inline 예외: 1~2파일 trivial, 사용자 상호작용이 중간에 필요한 task. **unit packet**(위임 프롬프트)에 넣을 것: 해당 requirement 발췌 + 대상 파일 + 테스트 시나리오 + 검증 명령 + `docs/spec/` 절대 경로(서브에이전트는 대화 이력·로드된 스킬을 못 본다 — CLAUDE.md·rules·훅은 자동 적용) + "커밋 금지, 최종 메시지는 `{status, changed_files, evidence(red 관찰·검증 결과)}` JSON". "스펙 전체를 읽어라"는 금지
   - **수신·검증**: worker 리포트 JSON만 받고, diff 전문은 컨텍스트에 넣지 않는다 — `git diff --stat` + 검증 명령 재실행으로 실물 확인 후 메인이 커밋. `blocked`/`scope_expansion`이면 packet을 고쳐 1회 re-dispatch, 2회 실패 시 inline 강등. 깨진 트리 위에 다음 unit을 보내지 않는다
   - **테스트 unit**: `test-driven-development` 스킬 규칙(packet에 명시) — 실패하는 테스트 먼저, 버그는 재현 테스트 먼저. red 게이트는 세션당 1회 승인(adr/0018)이되, worker는 각 red의 **실패 출력 원문과 이유("기능 미구현", import 오류 아님)를 리포트로 반환**하고, 메인이 그것을 본문에 붙여 `test(scope):` 커밋을 만든다(커밋 주체는 항상 메인 — adr/0027). 쿼리 우선순위는 role/label > 텍스트 > testID(3-2). 승인자가 없으면 구현으로 넘어가지 말고 멈춘다
   - **구현 unit**: 테스트 파일은 건드리지 않는다(Edit ask, Bash 쓰기 deny). 코드 기준은 `docs/spec/`(CLEAN-CODE·ARCHITECTURE·WEB/APP-SPEC — packet에 경로 포함). 컴포넌트 합성은 `vercel-composition-patterns`, 네이티브면 `react-native-skills`(packet에 명시). worker가 초록 + PASS_TO_PASS를 리포트로 반환 → 메인이 확인 후 `[x]` → `feat(scope):` 커밋(커밋 주체는 메인)
   - **UI task**: 뷰포트·다크모드 증거는 `.claude/rules/platform.md` 프로필대로. 런타임 확인은 `browser-testing-with-devtools`(DOM·콘솔 에러 0·네트워크) 우선, 안 되면 `docs/guides/evidence-capture.md` 순서로 촬영 — **저장은 `.claude/state/evidence/<slug>/`(gitignored)에만, 커밋 금지**(adr/0027). 접근성: axe serious+ 0건 + Tab 시퀀스(`docs/guides/a11y-frontend.md`)
   - Figma 값(`leading-[22.126px]`류)은 토큰으로, 토큰 없으면 질문. 아이콘·이미지는 export 에셋 커밋
   - 마지막 Converge: spec 시나리오 ↔ 코드 대조, 빠진 건 task로 append
5. **리뷰 (2축, adr/0026 §3)**:
   - ① `cgamja:review-cgamja` — 철학·SPEC(`docs/spec/`) 대조, blocker는 수정 → 재검사 1회
   - ② `code-review` 스킬 (medium; PR이면 그 대상) — 버그·정확성
   - blocker는 전부 모아 **수정 패스 1번 → `fix(review)` 커밋 1개 → 재검사 1회**(adr/0019). 이후 새 수정 diff가 남으면 판정 줄에 명시
6. **비주얼 QA** (UI change일 때): `cgamja:qa-cgamja` — 동작 플로우의 THEN 시점에 스냅샷 검증을 심는다(플로우당 ≤5장, baseline은 사람 승인 후 커밋). Figma와의 픽셀 실시간 대조는 하지 않는다(qa-cgamja 원칙 4 — 디자인 대조는 사람 리뷰 + 회귀 baseline)
7. **`/opsx:archive`** → 5장 커밋 → 6장 PR

### 2-D. 디자인 갭 루프 (미완성·미디자인 부분, adr/0003)
Tier-2 3단계(propose) 전에 돈다. **허가를 묻지 않고 진입한다**(adr/0029 §3 — "디자인 세션이 필요합니다"라며 턴을 끝내는 것이 2026-08-31 런의 61분 공백이었다). 1-b의 `--wf-and-design` 절차와 동일하되 같은 세션에서 이어간다: 입력 수집(해당 노드 `get_design_context` 1회 + tokens + components + Ready 화면) → `frontend-design`·`taste-skills`·`frontend-ui-engineering` 로드해 후보 2~3안 → **그중 하나를 골라 구현까지 진행**하고 고른 이유와 나머지 안을 함께 보고 → 사용자가 다른 안을 고르면 교체(섹션 하나 교체는 되돌리는 비용이 낮다) → `summary.md` 기록(확정 Artifact 링크 포함 — 이것이 코드 우선 부분의 디자인 원천). **Figma로의 역캡처(거울)는 하지 않는다**(adr/0026 — Figma는 읽기 전용 원천).

### 2-P. 병렬 작업 (독립 change — adr/0027 §3)
직렬이 필요한 건 직렬로, 독립인 건 병렬로 — 실제 개발처럼. 진입은 두 경로:
- **사용자 주도(기본)**: 독립 change마다 터미널을 띄워 `claude --worktree <change-slug>` 세션에서 각각 `/develop-fe`. 세션 간 상태 공유는 git·파일뿐이라고 가정한다
- **세션 내**: 서브에이전트 `isolation: worktree`. **메인이 `git worktree add`를 직접 하지 않는다** — 격리는 하네스의 일

**병렬 가능 판정** (하나라도 걸리면 직렬 — 불확실해도 직렬, 속도는 옵션):
0. **전제 체크**(adr/0030): 선언 `parallel`이 `null`이거나 `.worktreeinclude`가 없으면 → **직렬**. 병렬을 원하면 `/develop-setup`으로 전제부터 깐다. 문서에만 있는 2-P는 실행되지 않는다 — 2026-08-31 런은 61커밋을 쌓고도 worktree가 0개였다
1. 의존하는 unit/change가 아직 커밋 안 됨 → 직렬
2. 파일 겹침 — 겹치지 않아도 **semantic 표면**(공유 타입·계약(`api/openapi.yaml`)·lockfile·생성물(`*.gen.ts`)·config)이 겹치면 직렬
3. 환경 싱글턴 충돌 — dev server 포트·브라우저 세션·패키지 설치가 필요한 unit은 한 번에 하나
4. 동시 상한 3

**머지**: 의존성 순서로 **1개씩 integrate → verify → commit**. clean merge는 호환 증명이 아니다 — 전진한 트리에서 재검증하고, 충돌 unit은 새 base에 re-dispatch.

**세팅은 `develop-setup`이 깐다**(adr/0030) — 선언 `parallel.{worktrees, port_env, max_concurrent}`, `.gitignore`의 `.claude/worktrees/`·`.env`, `.worktreeinclude`(worktree별 `.env`), dev 포트를 `port_env`로 파라미터화 + **strictPort**. strictPort가 핵심이다: 포트가 잡혔을 때 조용히 옆 포트로 옮겨 뜨면 증거 캡처가 엉뚱한 포트를 때린다 — 자동 이동은 사람에겐 편의지만 에이전트에겐 관측 불가능한 상태다.

## 3. 공통 규칙

### 3-0. 게이트 — 정지는 예외, 전진이 기본 (adr/0029)
2026-08-31 런에서 하루의 36%(181분)가 사람 대기였고, 최장 두 공백 110분이 얻어낸 답은 두 번 다 "네가 알아서 해"였다. 그래서 기본값을 뒤집는다.

**정지 허용 목록 — 이것만 사람을 기다린다**
| | 사유 |
|---|---|
| a | 되돌리기 어렵거나 밖으로 나가는 행동 — 배포·푸시·외부 전송·삭제 |
| b | 계약 판정 **D**(스펙에 없는 필드가 필요) |
| c | 사용자만 아는 사실 — 비즈니스 규칙·우선순위·법적 제약·실제 데이터 형태 |
| d | red 게이트 세션당 1회(adr/0018) |
| e | 디자인 후보 **확정** — 후보를 낸 *뒤*의 사후 확인이지 진입 허가가 아니다 |

**그 외는 가정 전진** — 멈추는 대신 세 줄을 남기고 같은 턴에서 계속한다:
```
가정: <무엇을 정했나>
근거: <PRD §n / 기존 코드 / 토큰 / 관례>
되돌리는 비용: <틀렸을 때 다시 해야 하는 것>
```
정지 직전 자문 한 줄: **"이 답이 '알아서 해'로 돌아올 확률이 높은가?"** 높으면 가정 전진이다. "되돌리는 비용"이 섹션 하나 다시 만들기보다 크면 정지 목록으로 올린다. 가정은 작업 **시작 시점**에 내고, 세션 마무리 보고에 누적 목록을 다시 낸다.

### 3-1. 검증 스택 — 싸게 → 비싸게, 위가 깨지면 아래로 안 내려간다
1. **결정적** = `commands.verify` 한 명령(계약 드리프트+타입+린트+테스트). 완료 정의는 이 이름 한 곳(adr/0005). git 훅이 같은 명령을 pre-push에서 강제한다(0-b)
2. **행동** = `browser-testing-with-devtools`로 실제 런타임 확인(DOM·콘솔·네트워크) + Playwright 스모크 2~3개 + axe
3. **시각** = `cgamja:qa-cgamja` 회귀 스냅샷(THEN 시점, baseline 게이트)이 유일한 저장 경로다. **저장소에 커밋되는 시각 파일은 qa-cgamja baseline(LFS)뿐**(adr/0027) — 확인용 스크린샷은 `.claude/state/evidence/`(gitignored)에 찍고 사람이 본 뒤 버린다. `evidence/` 류 디렉터리를 저장소에 만들지 않는다
4. **LLM judge**: 안 쓴다. 취향은 사람

### 3-2. 테스트 규칙 — `test-driven-development` 스킬 + 게이트
- 방법은 스킬이(실패 먼저·재현 먼저·"seems right"는 done이 아님), **게이트는 워크플로우가**: red 승인(세션당 1회, adr/0018) → `test(scope):` 커밋 분리 → 구현 turn 테스트 파일 보호(훅) → PASS_TO_PASS
- 잃지 않는 v1 규칙 요약: 쿼리는 role/접근성 label > 텍스트 > testID · mock은 네트워크 경계(선언된 `mock.boundary` 도구)에서만, 내부 모듈 mock 금지 · 계층은 프로젝트 선언 `tests.layers`에서 하나 고른다(단위/브라우저/E2E) · assertion 완화·skip·snapshot 재생성으로 초록 만들기 금지 — 못 만들면 실패 원문과 함께 멈춘다
- **테스트 동결 — 수정 최소화(adr/0027)**: `test(scope):` 커밋 이후 테스트는 동결이다. 다시 여는 조건은 둘뿐 — ① 스펙 변경이 확정됐을 때 ② 테스트 자체 결함(구현이 아니라 테스트의 버그)일 때. 어느 쪽이든 **모아서 `test(scope):` 커밋 1개**로, 사유를 커밋 본문에 한 줄. 리뷰 지적이 테스트 수정을 요구하면 즉시 고치지 말고 스펙과 대조해 위 ①/②인지 판정부터 — 아니면 "수정 안 함 + 이유"로 답한다. 리뷰→테스트 수정→코드 수정 루프는 재검사 1회 상한(2장 5번)을 넘겨 돌지 않는다
- 비주얼 스냅샷은 일반 TDD의 red가 성립하지 않는다 — `qa-cgamja`의 baseline 게이트(사람 승인)를 따른다

### 3-3. 코드 규칙 — 원천은 `docs/spec/`
- **아키텍처**: `docs/spec/ARCHITECTURE.md` — import 단방향(shared→features→app), feature 간 직접 import 금지, 공개 API는 `index.ts`. 경계에 막히면 우회하지 말고 묻는다
- **클린코드**: `docs/spec/CLEAN-CODE.md` — 숨은 부수효과 금지, 매직 넘버 이름·위치, 중첩 삼항 금지, "무엇" 주석 금지
- **패턴**: `docs/spec/GOOD-BAD-PATTERN.md` — 같이 실행되지 않는 코드 분리, 성급한 공통화 금지(§6). 만들기 전에 검색, 비슷한 게 있으면 확장/합성, `V2` 금지
- **라이브러리**: `docs/spec/LIBRARY.md` + `WEB-SPEC.md`/`APP-SPEC.md` — 스펙 외 라이브러리는 승인+ADR 없이 추가 금지
- 상태 위치 4곳(로컬/공유 UI/서버/URL), 같은 진실을 두 곳에 두지 않는다. 색·간격·폰트는 토큰만. 빈·로딩·에러 상태는 spec에 없어도 기본 포함
- 성능 요구가 있는 task는 `performance-optimization`, 로깅·계측 task는 `observability-and-instrumentation` 로드

### 3-4. 컨텍스트 규칙 (`context-engineering` 원칙)
- **컨텍스트 예산(adr/0027 §2)**: 페이즈 경계(스펙 확정 후·구현 완료 후)에서 컨텍스트 ~50% 초과면 보존 지시 포함 `/compact` 또는 handoff 문서 작성 후 **새 세션에서 리뷰~PR**. 구현 diff·테스트 로그 전문을 메인에 들이지 않는 것이 수치 관리보다 우선
- 같은 수정 2번 실패 → `/clear`, `docs/solutions/` 확인, 접근 변경 — "더 열심히"가 아니라 빠진 도구/규칙을 찾는다
- 탐색은 Explore 서브에이전트로, 본 컨텍스트에 파일 덤프 금지. 서브에이전트는 `model:` 명시(`docs/guides/model-routing.md`): 탐색 haiku / 구현 sonnet / 리뷰 opus
- 에이전트가 규칙을 어기면 CLAUDE.md에 줄을 늘리지 말고 린트·훅·config rules로 내린다

## 4. 기록
- **살아있는 스펙** = `openspec/specs/`(archive가 갱신) · **학습** = `/ce-compound` → `docs/solutions/` · **결정** = 프로젝트 `docs/adr/`(형식은 `docs/spec/ADR` 규약과 philosophy 레포 ADR.md) · **디자인** = `design/`(스냅샷 덮어쓰기 = 이력) · **일회용** = `docs/plans/`, archive, 후보 캔버스

## 5. 커밋 — pre-commit/pre-push가 게이트
- 형식은 `docs/spec/COMMIT.md`: `feat|fix|refactor|test|chore|docs(scope): 요약`. **단계 1개 = 커밋 1개**(change당 4~8개): `docs(spec)` 1 · `test` 1~3 · `feat` 1~3 · `fix(review)` 1. task마다 커밋하지 않는다 **[pre-push 경고 — adr/0031]**
  > 2026-08-31 런은 5개 change 전원이 상한을 넘겼다(12·16·12·9·9). 산문으로만 있어서 아무도 세지 않았다. 이제 pre-push가 나가는 커밋을 세어 초과면 **경고**한다(차단 아님 — 리뷰 라운드가 정당하게 커밋을 늘린다). 초과 시 사유를 PR 본문에 한 줄
- 테스트 변경은 **별도 커밋**(pre-push가 feat/fix 커밋의 테스트 혼입을 차단한다)
- **pre-push에 막히면**: 커밋을 고치는 게 정답이다 — verify 실패면 `git commit --fixup <실패 원인 sha>` → `git rebase --autosquash`, 메시지 형식이면 `git rebase -i`로 reword, 테스트 혼입이면 커밋 분리. `--no-verify`·훅 삭제로 우회하지 않는다(스킬 훅이 거부)
- `/ce-commit` 사용. 푸시는 change 단위

## 6. PR
- Tier-1: 모아서 1개 / Tier-2: change 1개 = PR 1개. 형식은 `docs/spec/PR.md` + 아래 증거 블록. `/ce-commit-push-pr`, 대기 중 `/ce-babysit-pr`

```md
## 검증 증거
- [ ] verify (typecheck/lint/test): <출력 요약>
- [ ] 브라우저 검증(devtools) / Playwright+axe: <결과>
- [ ] 스크린샷(프로필 뷰포트, 다크 해당 시): <PR 본문 첨부 또는 .claude/state/evidence/ 경로 — 저장소 커밋 아님>
- [ ] 비주얼 QA: qa-cgamja 스냅샷 <n장> · baseline <신규/갱신 승인 여부>
- [ ] 리뷰: review-cgamja <PASS/FAIL·수정 n건> · code-review <blocker 0 · should n>
```

## 7. 재검토 조건 (10개 task마다 점검 — `/retro-fe`)
- 2축 리뷰가 못 잡은 회귀 2회 → 렌즈 리뷰(구 review-fe, git 이력에 있음) 선택 재도입 검토(adr/0026)
- 외부 스킬 미설치 대체 경로 3회 → vendoring 검토
- Tier-2 분해가 change 4개 초과 2회 → 에픽 절차 부분 복원
- pre-push 실패→fixup 루프 세션당 3회 → pre-commit 게이트 강화
- change당 커밋 10개 초과 2회 → 단계 커밋 규칙 위반 지점 점검
- 브라우저 계층 테스트 주 2회 flaky → 단위 계층 기본 복귀(adr/0004)
- 오래된 스냅샷으로 잘못 구현 2번 → 세션 시작 `get_metadata` 변경 감지 추가(adr/0002)
- 새 방법론 평가는 "5가지 동작(스펙·계획·체크·검증 분리·컨텍스트) 중 어느 걸 더 싸게 하나?"로만
