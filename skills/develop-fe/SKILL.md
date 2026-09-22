---
name: develop-fe
description: 프론트엔드 개발 작업(기능 추가, 화면 구현, 버그 수정, 리팩토링, Figma 디자인 구현)을 티어 판정(Tier-1 바로 / Tier-2 OpenSpec) → 테스트 먼저(TDD) → 구현 → 브라우저·스크린샷 증거 → 리뷰(review-cgamja+code-review) → 비주얼 QA(qa-cgamja) → 커밋/PR까지 끌고 가는 워크플로우. 사용자가 "이 기능 만들어줘", "이 화면 구현해줘", "이거 고쳐줘", "PR 올려줘", "작업 시작하자"처럼 코드를 바꾸는 요청을 하거나 /develop-fe 를 호출하면 반드시 사용한다. 한 줄짜리 수정이라도 이 스킬을 거친다(Tier-1로 빠르게 끝난다). Figma 디자인 구현, "디자인이 아직 없는" 부분(후보 → 확정 → 구현)도 담당. 디자인 산출만 하는 플래그 --only-wf(와이어프레임만 보고 와이어프레임 제작) / --only-design(디자인만 보고 디자인 제작) / --wf-and-design(와이어프레임 보고 디자인 제작)도 이 스킬로 진입한다.
hooks:
  PreToolUse:
    - matcher: "Skill"
      hooks:
        - type: command
          command: "${CLAUDE_PLUGIN_ROOT}/skills/develop-fe/hooks/skill_guard.sh"
          timeout: 10
    - matcher: "Edit|Write|MultiEdit"
      hooks:
        - type: command
          once: true
          command: "${CLAUDE_PLUGIN_ROOT}/skills/develop-fe/hooks/setup_check.sh"
          timeout: 10
        - type: command
          command: "${CLAUDE_PLUGIN_ROOT}/skills/develop-fe/hooks/test_nudge.sh"
          timeout: 10
    - matcher: "Agent"
      hooks:
        - type: command
          command: "${CLAUDE_PLUGIN_ROOT}/skills/develop-fe/hooks/review_nudge.sh"
          timeout: 10
---

# develop-fe (v2 — adr/0026)

프론트엔드 작업을 받아서 PR까지 가는 **오케스트레이터** — 메인 세션은 티어 판정·스펙·task 분해·결과 통합·커밋만 소유하고, **구현·테스트 작성은 unit packet 서브에이전트로 위임**한다(adr/0027; inline 예외는 Tier-1·1~2파일 trivial). 절차 전체는 `workflow.md`에 있고, 이 파일은 **언제 무엇을 읽고 어떤 스킬을 부를지**만 정한다. 독립 change 병렬 작업은 `workflow.md` 2-P(터미널별 `claude --worktree <slug>`). `docs/guides/`·`adr/`·`agents/`·`docs/spec/` 경로는 **플러그인 루트** 기준이다.

## 왜 이런 구조인가 (한 문단)
에이전트 개발 방법론은 전부 같은 다섯 동작으로 환원된다 — 의도를 글로 고정, 편집 전 계획, **돌릴 수 있는 체크를 먼저**, 작성자와 검증자 분리, 컨텍스트 작게. v2는 그 다섯을 자작 대신 **검증된 외부 스킬 조합**으로 채운다(adr/0026): 스펙·tasks는 OpenSpec, TDD는 `test-driven-development`(vendored), 런타임 검증은 `browser-testing-with-devtools`, 비주얼 QA는 `qa-cgamja`, 리뷰는 `review-cgamja`(철학 대조) + `/code-review`(신뢰도 스코어링 버그 리뷰) 2축. 코드 작성 기준(SPEC)은 `docs/spec/`가 원천이고, 커밋·푸시 품질은 git pre-commit/pre-push 훅이 강제한다.

## 시작 절차
-1. **Fast-path**(adr/0019): 즉시 실행 가능한 첫 행동이 있으면 그것이 첫 도구 호출. 첫 가시 보고(티어 한 줄)는 30초 안에.
0. **플래그 확인**: `--only-wf` / `--only-design` / `--wf-and-design`이 있으면 코드 구현 없이 **디자인 산출 모드**(`workflow.md` 1-b)로 — 티어 절차를 돌지 않는다.
1. `workflow.md` 0장(세션 시작 + **0-b git 훅 설치**)을 실행한다.
2. 티어 판정(`workflow.md` 1장): diff 한 문장 → **Tier-1**(그냥 진행, 아티팩트 없음) / 파일 여러 개·새 컴포넌트·접근법 둘 이상 → **Tier-2**(OpenSpec change 1개). 큰 작업은 Tier-2 change 여러 개로 분해(Tier-3 폐지, adr/0026). 버그 → `/ce-debug` + 재현 테스트 먼저.
3. 티어 절차(`workflow.md` 2장) + 공통 규칙(3장). 코드 기준은 **`docs/spec/`**(CLEAN-CODE·ARCHITECTURE·WEB/APP-SPEC·GOOD-BAD-PATTERN·LIBRARY).
4. 끝나면 5장(커밋 — pre-push 게이트) · 6장(PR). 삽질이 있었으면 `/ce-compound`.

## 단계별 스킬 호출 (전체 표는 `workflow.md` 배치표)
- **테스트 task**: `cgamja:test-driven-development` 로드 — 실패하는 테스트 먼저, 버그는 재현 테스트 먼저. red 게이트·`test(scope):` 커밋 분리·**테스트 예산**(시나리오를 덮는 최소, adr/0034)은 workflow 3-2.
- **UI 검증**: `cgamja:browser-testing-with-devtools`(콘솔 0·DOM·네트워크) → 스크린샷 증거(`docs/guides/evidence-capture.md`).
- **비주얼 QA**: `cgamja:qa-cgamja` — 동작 플로우 THEN 시점 스냅샷, baseline은 사람 승인. Figma 실시간 픽셀 대조는 하지 않는다.
- **리뷰 2축**: `cgamja:review-cgamja`(docs/spec 철학 대조, blocker → 수정 → 재검사 1회) + `/code-review`(Tier-1 low, Tier-2 medium). **두 축은 한 메시지에서 동시에 띄운다**(adr/0035). blocker는 모아서 수정 패스 1번 → `fix(review)` 커밋 1개, 재검사는 지적이 나온 축만.
- **디자인 산출**: `frontend-design` + `design-taste-frontend` + `frontend-ui-engineering`(설치 시) — 후보 2~3안, 토큰·기존 컴포넌트만.
- **구현 보조**: 컴포넌트 합성 `vercel-composition-patterns`, 네이티브 `react-native-skills`, 성능 task `performance-optimization`, 계측 task `observability-and-instrumentation`(설치 시).

## 디자인은 Figma가 원천, 작업 입력은 `design/` 스냅샷
- 화면 task는 `design/screens/<slug>/summary.md`와 `reference@2x.png`를 읽고 시작한다. 있으면 **Figma를 열지 않는다**(비용). Figma MCP 호출은 네 경우뿐: 새 화면, 디자인 변경, 최종 검증 `get_screenshot` 1회, 토큰 동기화 — 판단 표는 `docs/guides/figma-design-source.md` §3.
- Figma 노드에 `📝 TODO:` / `🚧 WIP` / `⬜ PLACEHOLDER`가 있으면 구현하지 않고 `workflow.md` 2-D 디자인 갭 루프로.
- Figma 읽기 전엔 `figma:figma-design-to-code`를 먼저 로드한다(플러그인 규칙). **Figma에 쓰지 않는다** — 디자인 산출물은 `design` 스킬 캔버스 Artifact와 `design/screens/<slug>/summary.md`에만(adr/0026).

## API 계약은 `api/openapi.yaml` 하나, 코드는 생성물만
- 계약 상태 A/B/C/D 판정은 `workflow.md` 1장, 절차는 `docs/guides/api-contract.md`(adr/0008). 스펙에 없는 게 필요하면 코드·목에 먼저 넣지 않는다 — 멈추고 스펙 diff 제안.

## 프로젝트 세팅이 없을 때
`package.json`의 `verify` · `openspec/config.yaml` · `.claude/rules/` · `.claude/cgamja.json` 중 하나라도 없으면 **`/develop-setup`을 먼저 하라고 안내하고 멈춘다.** 예외: Tier-1 한 줄 수정. git 훅(pre-commit/pre-push)은 이 스킬이 0-b에서 직접 설치한다(`templates/git-hooks/`).

## 절대 하지 않는 것 (앞 항목들은 훅 `hooks/skill_guard.sh`가 거부 — adr/0007)
- `ce-plan` / `lfg` 호출 — OpenSpec change와 플랜이 두 군데 생긴다.
- Agent 도구로 리뷰어·테스트 작성자를 즉석 제작 — `review-cgamja`/`code-review`/`test-driven-development`를 쓴다. 서브에이전트는 `model:` 명시(`docs/guides/model-routing.md`).
- 테스트를 초록으로 만들기 위한 assertion 완화·skip·snapshot 재생성. 못 만들면 실패 원문과 함께 멈춘다.
- `git push --no-verify`·훅 삭제로 pre-push 게이트 우회 — 막히면 커밋을 고친다(fixup/reword, `workflow.md` 5장).
- "됐습니다"만 보고하기. 테스트 출력·스크린샷 경로 없이는 완료가 아니다.
- 규칙을 어겼을 때 CLAUDE.md에 지시문 추가하기. 린트·훅·config rules로 내린다.

## 파일 안내
| 파일 | 언제 읽나 |
|---|---|
| `workflow.md` | 항상. 절차 본문 |
| `docs/spec/` (PHILOSOPHY·CLEAN-CODE·ARCHITECTURE·WEB/APP-SPEC·GOOD-BAD-PATTERN·LIBRARY·COMMIT·PR·ISSUE) | 코드 작성·커밋·PR의 SPEC 원천 — 구현 전 해당 문서 확인 |
| `docs/spec/AI-SPEC.md` | 외부 스킬의 설치 원천·목록 |
| `templates/git-hooks/` | 0-b 훅 설치 시 복사 원본 |
| `docs/guides/openspec-setup.md` | OpenSpec 세팅·`/opsx:*` 이상 동작 시 |
| `docs/guides/figma-design-source.md` | 화면 task 시작 전(§3), 스냅샷(§2), 디자인 갭(§5) |
| `docs/guides/api-contract.md` | API task — 계약 판정·DRAFT 스텁·retrofit |
| `docs/guides/evidence-capture.md` | UI 증거 촬영 전 — 수단 탐색 순서(adr/0021·0025) |
| `docs/guides/a11y-frontend.md` | UI task 접근성 체크·증거 |
| `docs/guides/platform-fit-frontend.md` | 플랫폼 프로필 기준 |
| `docs/guides/model-routing.md` | 서브에이전트 띄울 때마다 |
| `docs/guides/project-conventions.md` | 규칙 배치표·아키텍처 경계 |
| `adr/` | 절차·도구를 바꾸려 할 때 — 먼저 ADR(v2 전환은 0026) |
| `hooks/` | 스킬 frontmatter 훅 스크립트 |

## 이 스킬 자체의 개선
`workflow.md` 7장의 재검토 조건(10개 task마다, `/retro-fe`)을 만나면 **workflow.md를 바로 고치지 말고** `adr/`에 새 번호로 기록한 뒤 반영한다.
