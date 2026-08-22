# cgamja-plugin

개인 Claude Code 플러그인(프론트엔드). 네임스페이스 `cgamja` → `/cgamja:develop-setup`, `/cgamja:develop-fe`, `/cgamja:test-fe`, `/cgamja:review-fe`.
(앱 화면 수집 스킬 `app-ref-to-figma`는 앱별 리포트가 쌓여 비공개 저장소 `cgamja-private`에 따로 있다.)

## 설치 (skills-directory plugin — 마켓플레이스·install 불필요)
```bash
ln -s ~/cgamja-plugin ~/.claude/skills/cgamja   # 다음 세션부터 cgamja@skills-dir 로 자동 로드, 수정도 바로 반영
```
심링크라 제자리에서 로드된다 — 스킬이 쓰는 `adr/`·`reports/`가 이 저장소에 바로 쌓이고, 훅의 `${CLAUDE_PLUGIN_ROOT}`도 이 경로로 풀린다. 개발 중 특정 세션만 다른 체크아웃을 쓰려면 `claude --plugin-dir <path>`(같은 이름이면 그 세션에서 우선). 변경 후 세션 중 반영은 `/reload-plugins`.
`agents/`의 persona는 마켓플레이스 설치면 서브에이전트 타입으로 등록되고, skills-dir 설치면 `review-fe`가 파일을 읽어 Agent 프롬프트로 넘긴다 — 두 경로 모두 같은 파일(adr/0010).

## 구조 (adr/0010)
```
skills/
  develop-setup/   프로젝트 1회 세팅(규칙·린트·훅·OpenSpec·design/·플랫폼 프로필)
  develop-fe/      오케스트레이터 — 티어 → 스펙 → 구현 루프 → 증거 → 리뷰 → PR. test-fe/review-fe를 호출
  test-fe/         테스트 작성 — 계층 선택, 역할 쿼리·MSW, red 게이트(사람 승인), test() 커밋
  review-fe/       리뷰 — 티어별 렌즈 L1~L7을 persona 서브에이전트로(Tier-3/PR만 ce-code-review 병행), PR 모드
references/        스킬 공유 지식(-frontend 접미사 = 스택 지식). 스킬은 "언제 읽나"만, 내용은 여기
agents/            리뷰 렌즈 persona reviewer-{correctness,spec,tests,a11y,platform,architecture,performance}.md
adr/               결정 기록(0001~0013). 절차를 바꾸려면 ADR 먼저
reports/           스킬을 실제로 돌린 기록(시나리오·비용·모델·통과표·결함)
tests/             훅·preflight·문서 경로의 결정적 회귀 테스트
bin/               openspec 래퍼
```
스킬 이름은 `-fe`를 유지한다 — 접근성·플랫폼·테스트 계층처럼 FE 고유한 것이 지식이 아니라 절차에 박혀 있어서. 백엔드가 생기면 `review-be` 형제로 복제하고, 둘을 써 본 뒤에만 공통 코어를 추출한다(adr/0010 §3).

## 스킬

### `develop-setup`
새 프론트 프로젝트(Next/Vite/Expo)를 develop-fe가 작동하는 상태로 **1회** 세팅. 스택 질문 → CLAUDE.md·`.claude/rules`(+`platform.md` 프로필)·ADR·conventions → ESLint 경계·**a11y 린트**·commitlint·훅·`pnpm verify` → 테스트 스택(+axe) → OpenSpec init+feature 스키마 → `design/` 초기 → 자가 검증(일부러 경계·a11y 위반을 만들어 린트가 빨개지는지). `scripts/preflight.sh`로 현재 상태 확인.

### `develop-fe`
프론트엔드 작업을 티어 판정 → 스펙/tasks(OpenSpec) → 테스트 먼저(`test-fe`) → 구현 → 스크린샷·axe·테스트 증거 → 리뷰(`review-fe`) → 커밋/PR까지 끌고 간다.
- Tier-1(한 문장 diff)은 아티팩트 없이, Tier-2는 OpenSpec change 1개(`feature` 스키마), Tier-3는 `/ce-brainstorm` 후 change 여러 개
- OpenSpec이 스펙·tasks 척추, Compound Engineering 플러그인이 brainstorm·compound·commit·PR(`ce-plan`/`ce-work`는 자리가 겹쳐 미사용)
- 디자인 원천은 Figma, 작업 입력은 저장소 `design/` 스냅샷. 미완성 부분은 Artifact 후보 → 확정 → 코드 먼저 → Figma에 평면 캡처
- UI 증거는 `.claude/rules/platform.md` 프로필(웹/모바일 웹/Expo)대로 — 뷰포트·다크·키보드 + axe + Tab 시퀀스
- 서브에이전트는 `model:` 명시(`references/model-routing.md`): 탐색 haiku · 구현 sonnet · 리뷰 opus · 판단은 본체
- 훅(`hooks/`, adr/0007): `ce-plan`·`lfg`·인자 없는 `ce-code-review`/`ce-work` 호출을 Skill 도구 시점에 거부, 즉석 리뷰어 Agent에 `/review-fe` 안내, 첫 편집 전 세팅 누락 경고

### `test-fe`
시나리오(OpenSpec `#### Scenario` 또는 문장) → 계층 하나(jsdom / Vitest Browser Mode / E2E) → 역할 쿼리·MSW 경계 mock → **실패 출력 + 이유**를 보여 사람 승인(red 게이트, adr/0009) → `test(scope):` 커밋. 구현은 하지 않는다. 단독: "커버 안 된 시나리오 찾기", "flaky 원인 분류". assertion 완화·skip로 초록 만들기는 거부. 기준 `references/tdd-frontend.md`.

### `review-fe`
`code`(현재 change) / `pr <번호>` / `tier-3`. 티어가 렌즈를 정한다(`references/review-lenses-frontend.md`): Tier-1 L1 · Tier-2 L1 L2 L3 + UI면 L4 L5 + API면 L6 · Tier-3/PR 전부. 렌즈마다 `agents/reviewer-*.md` persona를 새 컨텍스트로 병렬(모델은 라우팅 표; Tier-3/PR에서만 `ce-code-review`를 스펙 경로 조립해 병행), 한 표로 합쳐 `blocker n → 재실행 / 머지 가능` 판정. 스타일 지적 없음. PR 코멘트는 사용자 확인 후.

## 훅
`develop-fe`은 SKILL.md frontmatter에 훅을 선언한다 — 스킬을 부른 시점에 등록돼 그 세션 동안 유지된다. 플러그인 전역 `hooks/hooks.json`은 의도적으로 쓰지 않는다(모든 세션에 켜지므로). `skills/develop-fe/hooks/`와 `adr/0007` 참조.

## bin/
`bin/openspec` — 플러그인이 켜져 있으면 Bash PATH에 들어간다. 프로젝트 devDependency(`@fission-ai/openspec`) → `pnpm exec` → `npx` 순으로 실행. OpenSpec의 `/opsx:*` 명령이 bare `openspec`을 부르기 때문(실측: `which openspec` → 이 래퍼).

## 테스트·기록
- `bash tests/run.sh` — 훅·preflight·문서 경로 링크의 회귀 테스트(LLM 호출 없음, 수 초). 스킬 스크립트나 파일 위치를 바꾸면 먼저 이걸 돌린다. 이것이 검증 1층이고, 트리거·행동 eval·스크래치 런과의 역할 분담은 `references/skill-verification.md`(adr/0013).
- `reports/` — 스킬을 실제로 돌린 기록(시나리오·비용·모델·통과표·결함·조치). ADR의 "검증" 란은 여기서 채운다. LLM 행동 evals(`claude plugin eval`)는 수동 리포트에서 실패 모드가 보인 뒤에 3~5개만 만든다.
- 2026-08-21 새 구조 검증(`reports/develop-fe-tier2_2026-08-21_restructured.md`): Tier-2 ×2 + opus/fable A/B. 결과 — 렌즈·모델 라우팅은 설계대로 작동(L5가 뷰포트 누락, L3가 판별 불가 테스트를 잡음), 비용은 세션 모델(fable/opus)·ce-code-review 유무와 무관하게 Tier-2 ≈$33~46 = **절차 부피**(adr/0011 개정 2). Tier-2 리뷰는 persona만, simplify는 선택(adr/0012 개정 2). 런 비교표는 `reports/README.md`.
