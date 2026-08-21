---
name: develop-fe
description: 프론트엔드 개발 작업(기능 추가, 화면 구현, 버그 수정, 리팩토링, Figma 디자인 구현)을 티어 판정 → 스펙/tasks(OpenSpec) → 테스트 먼저 → 구현 → 스크린샷·테스트 증거 → 리뷰 → 커밋/PR까지 끌고 가는 워크플로우. 사용자가 "이 기능 만들어줘", "이 화면 구현해줘", "이거 고쳐줘", "PR 올려줘", "작업 시작하자"처럼 코드를 바꾸는 요청을 하거나 /develop-fe 을 호출하면 반드시 사용한다. 한 줄짜리 수정이라도 이 스킬을 거친다(Tier-1로 빠르게 끝난다). Figma 디자인을 구현하거나 Figma 링크가 주어진 화면 작업, "디자인이 아직 없는데 만들어야 하는" 부분(후보 디자인 → 확정 → 구현)도 이 스킬이 담당한다. 작업 규모 판단, OpenSpec change 생성, Figma 스냅샷/호출 여부 판단, 테스트/스크린샷 검증, PR 템플릿이 필요한 모든 경우에 해당.
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

# develop-fe

프론트엔드 작업을 받아서 PR까지 가는 **오케스트레이터**. 절차 전체는 `workflow.md`에 있고, 이 파일은 **언제 무엇을 읽을지**만 정한다. 테스트 작성은 `test-fe`, 리뷰는 `review-fe` 스킬이 맡는다(adr/0010). `references/`·`adr/`·`agents/` 경로는 **플러그인 루트** 기준이다.

## 왜 이런 구조인가 (한 문단)
에이전트 개발 방법론(SDD, Compound Engineering, Harness, Loop, EDD …)은 전부 같은 다섯 동작으로 환원된다 — 의도를 글로 고정, 편집 전 계획, **돌릴 수 있는 체크를 먼저**, 작성자와 검증자 분리, 컨텍스트 작게. 이 스킬은 그 다섯을 가장 싼 도구로 채운다: 스펙·tasks는 OpenSpec, 브레인스토밍·리뷰·학습·커밋·PR은 Compound Engineering 플러그인, 프론트 특화 규칙과 검증 스택은 여기서. 프론트엔드는 `tsc` 같은 오라클이 없어서 **스크린샷과 테스트 출력을 증거로 내는 것**이 핵심이다. 근거는 `references/methodologies.md`, 도구 선택 결정은 `adr/0001`.

## 시작 절차
0. **예상 비용 한 줄**: Tier-2 한 change는 세션 모델과 무관하게 **≈$30~45**(2026-08-21 3런 실측, `reports/README.md`)다 — 리뷰 렌즈 6개×2회차·증거·변이 확인의 가격. 첫 보고에 티어와 함께 적는다. 더 싸게 하려면 티어를 낮추거나 `/review-fe --lens`로 렌즈를 줄이는 것이 사용자 선택.
1. **`workflow.md` 0장(세션 시작)** 을 그대로 실행한다 — git 상태, 열린 OpenSpec change, `docs/solutions/` grep, typecheck.
2. **티어를 판정**한다 (`workflow.md` 1장 표). 기준은 작업량이 아니라 불확실성·파급 범위. 1분 넘게 고민하지 말고 낮은 티어로 시작한다.
   - diff를 한 문장으로 말할 수 있다 → **Tier-1** (아티팩트 없음)
   - 파일 여러 개 / 새 컴포넌트·라우트 / 접근법 둘 이상 → **Tier-2** (OpenSpec change 1개, `feature` 스키마)
   - 여러 기능이 엮임 / 모르는 영역 / 아키텍처 결정 → **Tier-3** (`/ce-brainstorm` → change 여러 개, `spec-driven` 스키마, change마다 새 세션)
   - 버그 → `/ce-debug` (원인이 뻔하면 Tier-1)
3. 판정한 티어의 절차를 `workflow.md` 2장에서 따라간다. 공통 규칙(3장: 검증 스택·테스트·코드·컨텍스트)은 티어와 무관하게 적용된다.
4. 끝나면 5·6장(커밋, PR 템플릿)으로 마무리하고, 삽질이 있었으면 `/ce-compound`.

## 디자인은 Figma가 원천, 작업 입력은 `design/` 스냅샷
- 화면 task는 `design/screens/<slug>/summary.md`와 `reference@2x.png`를 읽고 시작한다. 있으면 **Figma를 열지 않는다** — 화면 하나가 2~3만 토큰이고 Pro 한도가 200회/일이라, 단순 기능마다 부르면 비용이 구현보다 커진다.
- Figma MCP를 부르는 경우는 네 가지뿐: 새 화면(스냅샷 없음), 디자인 변경(해당 섹션 재스냅샷), Ready 화면 최종 검증의 `get_screenshot` 1회, 토큰 동기화(보고만). 판단 표는 `references/figma-design-source.md` §3.
- Figma 노드 이름에 `📝 TODO:` / `🚧 WIP` / `⬜ PLACEHOLDER`가 있으면 그 부분은 **구현하지 않는다.** `workflow.md` 2-D 디자인 갭 루프로: `design` 스킬로 후보 2~3안 Artifact → 사용자 확정 → 코드 먼저 구현 → `generate_figma_design`으로 Figma에 평면 캡처(거울) → 스냅샷.
- Figma 읽기 전엔 `figma:figma-design-to-code` 스킬, 쓰기 전엔 `figma:figma-use`/`figma-generate-design`을 먼저 로드한다(플러그인 규칙).

## API 계약은 `api/openapi.yaml` 하나, 코드는 생성물만
- 스펙이 있으면 받아오고(`api:pull`), 없으면 프론트가 **DRAFT 스텁**을 쓰고, 기존 코드엔 **별도 change로 뽑아 붙인다**(retrofit). 그 다음은 전부 같다: `api:gen` → `src/api/*.gen.ts`(타입·TanStack 훅·MSW·zod)만 import. 없는 필드·엔드포인트를 지어내면 tsc가 막는다 — 판정표는 `workflow.md` 1장, 절차·도구는 `references/api-contract.md`, 결정은 `adr/0008`.
- 스펙에 없는 게 필요하면 **코드·목에 먼저 넣지 않는다**: 멈추고 스펙 diff를 제안해 확정받는다.

## 프로젝트 세팅이 없을 때
`package.json`의 `verify` 스크립트 · `openspec/config.yaml` · `.claude/rules/` 중 하나라도 없으면 이 스킬은 절반만 작동한다(훅·린트·스펙이 없으면 규칙이 산문으로만 남는다). **`/develop-setup`을 먼저 하라고 안내하고 멈춘다.** (첫 Edit/Write 직전에 훅 `hooks/setup_check.sh`가 누락 항목을 컨텍스트로 알려 준다 — 차단은 아니다) 여기서 즉흥으로 세팅을 만들지 않는다 — 세팅은 1회성이고 질문·설치·자가 검증이 필요해 별도 스킬이다. 예외: Tier-1 한 줄 수정은 세팅 없이도 진행한다.

## 절대 하지 않는 것 (앞 세 항목은 훅 `hooks/skill_guard.sh`가 Skill 호출 시점에 거부한다 — adr/0007)
- `ce-plan` / `lfg` 호출 — OpenSpec change와 아티팩트가 겹쳐 플랜이 두 군데 생긴다. `ce-work`는 실험 B(`adr/0001`)로만, 기본은 `opsx:apply`.
- `/ce-code-review`를 스펙 경로 없이 호출 — OpenSpec 포맷을 못 읽어 요구사항 누락 검사가 조용히 빠진다. 리뷰는 `/review-fe`가 경로를 조립해 부른다; 직접 부르면 항상 `plan:<changeRoot>/specs/<cap>/spec.md` + 힌트.
- Agent 도구로 리뷰어·테스트 작성자를 즉석 제작 — persona(`agents/`)와 `test-fe`/`review-fe` 스킬을 쓴다. 서브에이전트는 `model:`을 명시한다(`references/model-routing.md`).
- 테스트를 초록으로 만들기 위해 assertion 완화·skip·snapshot 재생성. 못 만들면 실패한 assertion 원문과 함께 멈춘다.
- "됐습니다"만 보고하기. 테스트 출력이나 스크린샷 경로 없이는 완료가 아니다.
- 규칙을 어겼을 때 CLAUDE.md에 지시문 추가하기. 린트·훅·`openspec/config.yaml` rules로 내린다.

## 파일 안내
| 파일 | 언제 읽나 |
|---|---|
| `workflow.md` | 항상. 절차 본문 |
| `references/openspec-setup.md` | 프로젝트에 OpenSpec 세팅할 때, `/opsx:*` 동작이 이상할 때 |
| `references/figma-design-source.md` | 화면 task 시작 전(호출 규칙 §3), 스냅샷 만들 때(§2), 디자인 갭(§5), Figma 대조 검증(§6) |
| `references/api-contract.md` | API가 걸린 task — 계약 상태 A/B/C/D 판정, orval 설정, DRAFT 스텁 템플릿, retrofit 절차, 백엔드와 화해 |
| `skills/test-fe/` → `references/tdd-frontend.md` | 테스트 task — Skill 도구로 `cgamja:test-fe`. 직접 읽지 않는다 |
| `skills/review-fe/` → `references/review-lenses-frontend.md`, `agents/reviewer-*.md` | 리뷰 단계 — Skill 도구로 `cgamja:review-fe`. 직접 읽지 않는다 |
| `references/a11y-frontend.md` | UI task 증거(§3)와 코드 규칙이 막지 못하는 접근성 체크(§2) |
| `references/platform-fit-frontend.md` | `.claude/rules/platform.md`가 없을 때 프로필 기준, `summary.md`의 platform 필드 |
| `references/model-routing.md` | 서브에이전트를 띄울 때마다 — 어떤 일을 어떤 모델에 |
| `references/project-conventions.md` | 프로젝트 시작 시 — 규칙 배치표, 아키텍처(도메인 vertical + 경계 린트), CLAUDE.md/conventions.md 템플릿 |
| `references/methodologies.md` | "왜 이렇게 하나"를 설명해야 할 때, 새 방법론을 평가할 때 |
| `references/verdicts-2026-08-21.md` | CE 분담·TDD·규칙 배치·아키텍처 결정의 근거를 따질 때 — 재검증 판정표 |
| `adr/` | 절차·도구를 바꾸려 할 때 — 먼저 ADR, 그다음 workflow.md (플러그인 루트) |
| `hooks/` | 스킬 frontmatter 훅 스크립트(Skill 가드, 세팅 점검, test-fe 상기, 리뷰 Agent 상기). 규칙을 추가·완화할 때 — adr/0007 |

## 이 스킬 자체의 개선
`workflow.md` 7장의 재검토 조건(10개 task마다)을 만나면 **workflow.md를 바로 고치지 말고** `adr/`에 새 번호로 기록한 뒤 반영한다. `[TODO]`는 프로젝트 스택이 정해지는 순간 채운다 — 훅·린트가 없으면 이 워크플로우는 절반만 작동한다.
