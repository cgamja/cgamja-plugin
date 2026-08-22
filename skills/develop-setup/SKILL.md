---
name: develop-setup
description: 기존 또는 새 프론트엔드 프로젝트(스택 불문, brownfield 포함)를 develop-fe·test-fe·review-fe 스킬이 작동하는 상태로 만든다 — 프로젝트를 읽어 스택·도구를 발견 → 철학의 강제 수단(테스트 파일 보호, 계약 생성, 경계 린트, 접근성 린트, 완료 명령 한 곳, 디자인 원천, 플랫폼 프로필)이 있는지 대조 → 없는 것만 기존 도구 위에 최소로 제안·설치 → 프로브로 "진짜 막나" 확인 → `.claude/cgamja.json` 선언·CLAUDE.md·.claude/rules·훅 기록. 사용자가 "프로젝트 시작하자", "이 프로젝트에 세팅해줘", "개발 환경 잡아줘", "/develop-setup"이라고 하거나, develop-fe 스킬이 "세팅이 없다"고 멈췄을 때 반드시 사용한다. 빈 폴더든 수년 된 레포든 모두 해당. 스택을 정하거나 스캐폴드를 찍어내지 않는다.
---

# develop-setup

develop-fe 스킬은 **절차**를, 프로젝트 저장소는 **사실**(선언·규칙·스펙)을 갖는다(adr/0014). 이 스킬은 프로젝트를 읽어 그 사실을 `.claude/cgamja.json`에 선언하고, 철학(`docs/philosophy.md`)의 강제 수단이 빠진 곳만 기존 도구 위에 붙인 뒤, 실제로 강제되는지 확인하고 끝난다. 한 프로젝트에 1회(이후엔 대조표에 ✗가 생겼을 때만). **스택을 묻지 않고, 바꾸자고 하지 않고, 스캐폴드하지 않는다.**

## 0. 발견 — 묻기 전에 읽는다
`bash scripts/preflight.sh [dir]` — 매니페스트(package.json / pyproject / Gemfile / …), 프레임워크, 패키지 러너, 테스트 러너·기존 테스트 위치·파일 규약, 린터, 포맷터, 커밋 훅, CI, 계약 원천 후보(openapi·graphql·proto), 디자인 자산, 기존 `.claude/`·CLAUDE.md·AGENTS.md를 읽어 **발견 표**와 **대조표**(§1)를 출력한다. 이미 있는 것은 건드리지 않는다(멱등). 빈 폴더면 "스캐폴드가 필요합니다 — 어떤 것으로?"를 묻고 사용자가 고른 스캐폴더 명령을 **그대로 실행만** 한 뒤 다시 0으로.

## 1. 대조표 — 철학 원칙 ↔ 이 프로젝트의 강제 수단
| 원칙 | 선언 키 | 있음의 기준 | 없을 때 제안(기존 도구 위에, 최소) |
|---|---|---|---|
| P3 완료 정의 한 곳 | `commands.verify` | 한 명령이 타입·린트·테스트(·계약 드리프트·미사용)를 전부 돈다 | 기존 스크립트들을 묶는 `verify` 한 줄 추가 |
| P2 테스트는 게이트 | `tests.patterns`, `tests.layers` | 테스트 파일 glob이 정확하고 훅이 그 파일 Edit를 `ask`로 막는다 | 훅 설치(§2-4) — 러너는 그대로 |
| P7 계약 한 곳 | `contract.*` | 원천 파일 + 생성 명령 + 생성물 glob, 재생성 diff 0 | 원천이 있으면 생성기 제안(`references/api-contract.md` §2·§8), 없으면 `null` + retrofit change 안내(§5). 기능 change와 섞지 않는다 |
| P7 경계 mock | `mock.boundary` | 계약 밖 요청이 테스트에서 에러 | 러너에 맞는 경계 mock 도구(JS면 `references/tdd-frontend.md` §6) |
| P8 경계는 기계가 | `domains.root`, `domains.allowed_edges` | 기존 구조 이름으로 경계 린트가 **실제로** 에러를 낸다 — 별칭 경로뿐 아니라 **상대경로 import도**(smoke 프로브 기준; 2026-08-22 Vue 런에서 `patterns: ['src/pages/*']`가 `./pages/x`를 못 막음) | 기존 린터에 경계 규칙 추가(ESLint면 `templates/react/eslint.boundaries.js` 조각). 구조를 바꾸자고 하지 않는다 |
| P5 접근성 기본값 | `a11y.lint`, `a11y.runtime` | 린트 1층 + 런타임 2층 | 프레임워크별 a11y 린트 + axe(`references/a11y-frontend.md` §5). 없으면 `null`로 두고 리뷰 렌즈가 넓게 본다 |
| P4 디자인 원천 | `design.source`, `design.tokens` | 원천 선언 + 토큰 파일 + 토큰 외 값 린트 | Figma면 `design/` 스냅샷(`references/figma-design-source.md` §2), 없으면 `none` + 토큰 파일 위치 |
| P6 플랫폼 | `platform.profile` | `.claude/rules/platform.md` 프로필 | 사용자에게 프로필 1개 확인 |
| P10 작게 자주 | (commitlint·훅) | conventional commit 린트 + 테스트/구현 커밋 분리 규칙 | 기존 훅 매니저에 `commit-msg` 규칙 추가(없으면 lefthook) |
| 보호 | `protected`, `lint_file` | 매니페스트·lockfile·린트 설정·훅 보호, 편집 파일 포맷+린트 | 훅 설치 |

✗마다 "제안 / 설치 / 건너뜀(null)"을 사용자에게 **한 번에 묶어** 묻는다(AskUserQuestion, 5개 이하). 코드로 답이 나오는 건 묻지 않는다. 사용자가 거부한 항목은 `null`로 선언하고 대조표에 남긴다 — 다음 세팅 때 다시 보인다.

## 2. 만드는 것 (각 단계 끝에 무엇을 만들었는지 한 줄)
| # | 만드는 것 | 출처 | 비고 |
|---|---|---|---|
| 1 | `.claude/cgamja.json` | `templates/cgamja.json`을 **발견한 값으로** 채움 | ≤40줄. 없는 강제 수단은 `null` |
| 2 | `CLAUDE.md` (없을 때만; 있으면 "하지 않는 것"·명령·구조 단락만 병합 제안) | `templates/CLAUDE.md` | **≤60줄**(넘으면 줄이고 보고 — 2026-08-22 Vue 런 92줄), `@` import 없음, 값은 선언과 1:1 |
| 3 | `.claude/rules/{components,state,tests,platform}.md` | `templates/rules/` | `paths:`는 `tests.patterns`·`domains.root`와 일치. 기존 rules가 있으면 추가만 |
| 4 | `.claude/settings.json` + `.claude/hooks/*.sh` | `templates/settings.json`, `templates/hooks/` **그대로 복사** | 훅은 선언을 읽는다 — 수정 금지. 기존 settings가 있으면 hooks·deny 병합. `.claude/state/`(Stop 훅의 verify 로그)를 `.gitignore`에 |
| 5 | `docs/adr/0001-domain-structure.md`, `docs/conventions.md` | `templates/adr-0001-domain-structure.md`, `templates/conventions.md` | 구조 이름은 발견한 것(`domains.root`) |
| 6 | 커밋 규약: commitlint + 훅 매니저 `commit-msg`/`pre-commit` | `templates/lefthook.yml`(기존 husky 등이 있으면 그 안에 규칙만) | 대화형 훅 금지 |
| 7 | `verify` 한 줄 + 대조표 ✗ 중 사용자가 승인한 강제 수단 | `references/*` 의 "검증된 구현" 절 조각(`templates/react/`는 그 절에서 검증된 스택용 — 각 파일 머리에 스택·날짜) | **새 의존성은 승인 후에만.** 검증된 조각이 없는 스택이면: 조사 → 설치 → 프로브 → 되면 references에 날짜와 함께 추가(`feedback-install-and-verify`) |
| 8 | OpenSpec(**척추 — null 불가**. 설치가 필요하면 "새 의존성" 일반 규칙과 별개로 승인을 묻는다; 비대화형이면 설치하고 보고): `openspec init --tools claude --profile core .` → `schema fork spec-driven feature` → 템플릿 교체 → `config.yaml` `context:`를 **`.claude/cgamja.json`에서 생성**(같은 사실을 두 번 손으로 쓰지 않는다) | `references/openspec-setup.md` | 이미 있으면 `feature` 스키마만 확인 |
| 9 | `design/`: `design.source`가 Figma면 초기 스냅샷(map·tokens·components), 아니면 `design/NO_FIGMA` | `references/figma-design-source.md` §2 | 화면 스냅샷은 여기서 안 함 |
| 10 | CI: 기존 워크플로우에 `verify`·commitlint·`openspec validate`·문서 경로 검사 단계 추가 | `templates/check-docs.sh`, 예시 `templates/react/ci.yml` | 기존 CI를 대체하지 않는다 |

## 3. 자가 검증 — 만들었다가 아니라 작동한다를 보인다
`bash scripts/smoke.sh check <dir>` — 선언을 읽어 프로브를 돌린다: `commands.verify` 초록 / 경계 린트가 **실제로** 에러를 내는가(`domains.root` 밖에서 import 주입) / a11y 린트가 대체 텍스트 없는 이미지·클릭만 있는 컨테이너를 잡는가 / 계약 린트가 직접 HTTP 호출을 잡는가(`contract` 선언 시) / 훅 9종(테스트 Edit `ask`, 생성물 deny, 보호 파일 deny, 쉘 우회 deny, 읽기 허용) / commitlint / 재생성 diff 0 / openspec `new change` / 선언·규칙 파일 존재·미치환 변수 0. **하나라도 ✗면 완료라고 하지 않는다.** 통과해 버리는 프로브(예: 경계 린트가 조용히 통과)는 설정 문제다 — `references/project-conventions.md` §6 함정 참고.

## 4. 끝맺음
- 결과를 표로 보고한다: 발견한 것 / 붙인 것 / `null`로 남긴 것(이유) / 프로브 결과.
- 첫 커밋 `chore: bootstrap develop-fe workflow`(기존 레포면 변경분만). 이후 작업은 `/develop-fe`.
- `docs/solutions/`는 비워 둔다.

## 하지 않는 것
- 스택·프레임워크·러너를 고르거나 바꾸자고 하기, 스캐폴드 찍기, 버전 고정 의존성 목록 적용
- 기존 설정·구조를 묻지 않고 덮어쓰기
- 질문 5개 넘게 하기 — 나머지는 발견값·기본값으로 쓰고 CLAUDE.md "가정" 항목에 적는다
- 기능 코드 작성, 화면 스냅샷 — develop의 일

## 파일
| 파일 | 용도 |
|---|---|
| `scripts/preflight.sh` | 발견 표 + 대조표(종료코드 0=✗ 없음, 1=✗ 있음) |
| `scripts/smoke.sh check` | 자가 검증 프로브(LLM 없음) |
| `templates/` | 스택 무관 조각: `cgamja.json`, `CLAUDE.md`, `rules/`, `hooks/`, `settings.json`, `lefthook.yml`, `adr-0001`, `conventions.md`, `check-docs.sh`, `openapi.draft.yaml`(OpenAPI일 때) |
| `templates/react/` | 특정 스택에서 **검증된** 조각(각 파일 머리에 스택·날짜; `references/*` 검증 구현 절이 가리킨다) — 발견한 스택이 맞을 때만 |
| cgamja `references/project-conventions.md` | 배치표·훅 표·brownfield 규칙 |
