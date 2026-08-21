# OpenSpec 설정 (검증: 1.10.0, 2026-08-21, 스크래치 프로젝트에서 schema validate 통과)

## 설치
```bash
npm i -g @fission-ai/openspec          # 또는 매번 npx -y @fission-ai/openspec@latest
export OPENSPEC_TELEMETRY=0
cd <project> && openspec init --tools claude --profile core .
# 생성: openspec/config.yaml, .claude/commands/opsx/{propose,apply,archive,explore,sync,update}.md, .claude/skills/openspec-*/
```
`core` 프로필엔 `/opsx:continue`, `/opsx:verify`가 없다(커맨드 파일 6개). 필요하면 `--profile custom`으로 추가.

> **한국어 스펙과 `--strict`**: strict는 각 `### Requirement:` 본문에 RFC 2119 키워드(SHALL/MUST)가 없으면 경고하고 exit 1을 낸다(2026-08-21 실측). 한국어로 쓰면 전부 걸리므로 **Requirement 첫 문장에 `SHALL`을 병기**한다 — 예: "시스템은 SHALL 빈 목록일 때 '할 일이 없습니다'를 표시한다". 병기하지 않을 거면 CI·workflow의 `--strict`를 빼고 기본 `validate`를 쓴다(둘 중 하나를 프로젝트 CLAUDE.md에 적는다).

## 티어 = 스키마
| 티어 | 스키마 | 아티팩트 |
|---|---|---|
| Tier-1 | 없음 (OpenSpec 안 씀) | — |
| Tier-2 | `feature` (아래 포크본) | `specs/**/spec.md` + `tasks.md` |
| Tier-3 | `spec-driven` (기본) | proposal → specs + design → tasks |

```bash
openspec schema fork spec-driven feature
rm openspec/schemas/feature/templates/{proposal,design}.md
# schema.yaml 을 아래로 교체
openspec schema validate feature
openspec new change <slug> --schema feature
```

### `openspec/schemas/feature/schema.yaml`
```yaml
name: feature
version: 1
description: Tier-2 feature - delta spec + tasks only
artifacts:
  - id: specs
    generates: "specs/**/*.md"
    description: Delta spec - behavior contract; scenarios become tests/screenshots
    template: spec.md
    instruction: |
      Delta spec (## ADDED / MODIFIED / REMOVED Requirements). Each `### Requirement:` MUST have
      >=1 `#### Scenario:` with WHEN/THEN. UI scenarios state the viewport(s) and the visible
      evidence (text, state, screenshot). Include empty / loading / error states unless the user
      excluded them. If the feature touches an API, add a `## Contract` section: operationId(s),
      request/response schema refs into api/openapi.yaml, error statuses (400/401/404/409/5xx) —
      each error/empty/loading maps 1:1 to a UI scenario. If api/openapi.yaml lacks it, write the
      DRAFT stub first (develop-fe references/api-contract.md §3); never invent fields in code or mocks.
      Mark anything you had to guess with `[NEEDS CLARIFICATION: ...]` and ask (max 5 questions,
      batched) before writing tasks.
    requires: []
  - id: tasks
    generates: tasks.md
    description: Checklist; every task names its verification
    template: tasks.md
    instruction: |
      `- [ ] X.Y <task> → verify: <vitest path | screenshot 375/768/1280 | tsc | axe>`.
      A test-writing task comes BEFORE the implementation task it verifies.
      Search for existing components/utils before any "create" task; reference them by path.
      Last group is always "Converge": compare code against every scenario in the spec and
      append tasks for anything missing.
    requires: [specs]
apply:
  requires: [tasks]
  tracks: tasks.md
  instruction: |
    For each test task: run it, paste the failure output, state why it fails (missing behavior,
    not import/typo), commit as `test(scope): ...`, then stop for the human to review.
    Implementation tasks: test files are read-only; green + all previously green tests still green;
    commit `feat(scope): ...`. Mark [x] only with evidence (test output or screenshot path).
    Never edit assertions/skip/tolerances to get green; stop and report the failing assertion.
    Done = `pnpm verify` green; show its output.
```
> 실험 B(adr/0001): 위 `apply.instruction`을 "Skill 도구로 `compound-engineering:ce-work`를 `mode:return-to-caller <changeRoot>/tasks.md`로 호출하고 envelope으로 체크박스 반영"으로 바꿔 Tier-2 change 2개를 돌려본다. ce-work는 체크박스를 안 찍으므로 수동 반영 필수.

### `openspec/config.yaml` (프로젝트 시작 시 `[TODO]` 채움)
```yaml
schema: feature            # 기본 스키마 = Tier-2. Tier-3만 --schema spec-driven
context: |
  Stack: [TODO]. Components in src/components/ui (shadcn-style). Tokens only, no arbitrary
  Tailwind values. State: local useState / shared context / server [TODO] / url [TODO].
  No new dependencies without asking. Figma: [TODO file]. Conventional commits.
rules:
  specs:
    - One capability per file; keep under 80 lines
    - Scenarios must be observable (what the user sees), not implementation
  tasks:
    - Max 8 tasks per change; if more, split the change
operations:
  apply:
    guidance:
      - Commit after each task (feat|fix|test(scope): ...); tests in a separate commit before implementation
      - UI tasks: screenshot at 375/768/1280 with agent-browser, console errors = 0
      - Run `pnpm verify` before marking the last task complete
  archive:
    guidance:
      - Before archiving run compound-engineering:ce-code-review with `plan:<changeRoot>/specs/<cap>/spec.md`
        and the instruction "treat each `### Requirement:` / `#### Scenario:` as a requirement for the
        Requirements Completeness section; report correctness and spec gaps only". Resolve gaps first.
      - Confirm every `#### Scenario:` has a matching test or screenshot (Converge group) before archive
```
CI: `openspec validate --archived --strict` — archive 누락이 "오래된 스펙을 믿는" 실패로 이어지므로 필수(adr/0001).

## 일상 커맨드
```bash
openspec list                       # 열린 change
openspec status --change <slug>     # 아티팩트 진행
openspec validate <slug> --strict   # 스펙 형식 검사 (#### Scenario 4개 해시 필수)
openspec archive <slug>             # delta → openspec/specs/ 병합, changes/archive/로 이동
openspec view                       # 대시보드
```

## 주의 (해보며 확인한 것)
- `--profile expanded`는 1.10에 없다(core | custom).
- `status`는 파일 존재만 본다. tasks.md를 먼저 쓰면 specs 없이도 done으로 보임 → propose 스킬이 `requires` 엣지를 따라가게 돼 있으니 순서를 지킬 것.
- 시나리오 헤더는 정확히 `####`. `###`이나 불릿은 조용히 무시된다.
- MODIFIED는 요구사항 블록 전체를 복사해서 수정해야 archive 때 내용이 안 날아간다.
