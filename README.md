# cgamja-plugin

개인 Claude Code 플러그인. 스킬 2개. 네임스페이스 `cgamja` → `/cgamja:develop-fe`, `/cgamja:develop-setup`.
(앱 화면 수집 스킬 `app-ref-to-figma`는 앱별 리포트가 쌓여 비공개 저장소 `cgamja-plugin-private`에 따로 있다.)

## 설치 (skills-directory plugin — 마켓플레이스·install 불필요)
```bash
ln -s ~/cgamja-plugin ~/.claude/skills/cgamja   # 다음 세션부터 cgamja@skills-dir 로 자동 로드, 수정도 바로 반영
```
심링크라 제자리에서 로드된다 — 스킬이 쓰는 `adr/`가 이 저장소에 바로 쌓이고, 훅의 `${CLAUDE_PLUGIN_ROOT}`도 이 경로로 풀린다. 개발 중 특정 세션만 다른 체크아웃을 쓰려면 `claude --plugin-dir <path>`(같은 이름이면 그 세션에서 우선). 변경 후 세션 중 반영은 `/reload-plugins`.

## 스킬

### `develop-setup`
새 프론트 프로젝트(Next/Vite/Expo)를 develop이 작동하는 상태로 **1회** 세팅. 스택 질문 → CLAUDE.md·`.claude/rules`·ADR·conventions → ESLint 경계·commitlint·훅·`pnpm verify` → OpenSpec init+feature 스키마 → `design/` 초기 → 자가 검증(일부러 경계 위반을 만들어 린트가 빨개지는지). `scripts/preflight.sh`로 현재 상태 확인.

### `develop-fe`
프론트엔드 작업을 티어 판정 → 스펙/tasks(OpenSpec) → 테스트 먼저 → 구현 → 스크린샷·테스트 증거 → 리뷰 → 커밋/PR까지 끌고 간다.
- Tier-1(한 문장 diff)은 아티팩트 없이, Tier-2는 OpenSpec change 1개(`feature` 스키마: specs+tasks), Tier-3는 `/ce-brainstorm` 후 change 여러 개
- OpenSpec이 스펙·tasks 척추, Compound Engineering 플러그인이 brainstorm·review·compound·commit·PR (`ce-plan`/`ce-work`는 자리가 겹쳐 미사용)
- 디자인 원천은 Figma, 작업 입력은 저장소 `design/` 스냅샷(새 화면·변경 때만 Figma 호출). 미완성 표시된 부분은 Artifact 후보 → 확정 → 코드 먼저 → Figma에 평면 캡처
- `workflow.md` 절차 · `references/methodologies.md` 근거 리서치 · `references/openspec-setup.md` 스키마/설정 · `references/figma-design-source.md` Figma 규칙 · `adr/` 결정 기록
- 요구: compound-engineering 플러그인, OpenSpec CLI(프로젝트별 `openspec init`)
- 훅(`hooks/`, adr/0007): `ce-plan`·`lfg`·인자 없는 `ce-code-review`/`ce-work` 호출을 Skill 도구 시점에 거부, 첫 편집 전 세팅 누락 경고


## 훅
`develop-fe`은 SKILL.md frontmatter에 훅을 선언한다 — 스킬을 부른 시점에 등록돼 그 세션 동안 유지된다. 플러그인 전역 `hooks/hooks.json`은 의도적으로 쓰지 않는다(모든 세션에 켜지므로). `skills/develop-fe/hooks/`와 `develop-fe/adr/0007` 참조.

## bin/
`bin/openspec` — 플러그인이 켜져 있으면 Bash PATH에 들어간다. 프로젝트 devDependency(`@fission-ai/openspec`) → `pnpm exec` → `npx` 순으로 실행. OpenSpec의 `/opsx:*` 명령이 bare `openspec`을 부르기 때문(실측: `which openspec` → 이 래퍼).

## 테스트·기록
- `bash tests/run.sh` — 훅·preflight 같은 결정적 스크립트의 회귀 테스트(LLM 호출 없음, 수 초). 스킬 스크립트를 고치면 먼저 이걸 돌린다.
- `skills/develop-fe/reports/` — 스킬을 실제로 돌린 기록(시나리오·비용·통과표·결함·조치). ADR의 "검증" 란은 여기서 채운다. LLM 행동 evals(`claude plugin eval`)는 수동 리포트에서 실패 모드가 보인 뒤에 3~5개만 만든다.
