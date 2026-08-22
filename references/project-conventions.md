# 프로젝트 규칙은 어디에 두나 — 배치표와 시작 템플릿 (`adr/0005`, `adr/0006`, `adr/0014`)

원칙: **기계가 검사할 수 있는 건 린트·훅으로, 판단이 필요한 건 해당 파일을 건드릴 때 주입되는 짧은 규칙으로, 규칙은 한 곳에.** 플러그인이 읽는 사실(명령·패턴·원천)은 `.claude/cgamja.json`(선언, adr/0014 §슬롯)에, 사람이 읽는 이유는 `CLAUDE.md`·`docs/`에. 알아둘 사실 세 가지:
- CLAUDE.md 길이(25~500줄)는 준수율을 바꾸지 않았다(McMillan 2026, 1,650세션). 짧게 쓰는 이유는 **컨텍스트 예산**이지 준수율이 아니다. 준수율은 **세션 안에서** 떨어진다(함수 1개 생성마다 -5.6%) → 그건 훅만 고친다.
- `@path` import는 **eager** — 런치 시 전부 로드된다. 백틱 경로(`` `docs/x.md` ``)는 lazy.
- "한 줄 산문 + 강제 훅"은 중복이 아니라 한 규칙의 두 층이다. 산문은 "왜"를 설명해서 우회 시도를 줄이고, 훅이 막는다.

## 1. 배치표 (스택 무관)
| 규칙 종류 | 위치 | 검사 주체 |
|---|---|---|
| 플러그인이 읽는 사실(명령·테스트 패턴·계약·디자인 원천·프로필·경계) | `.claude/cgamja.json` ≤40줄 | 훅·스모크·리뷰어 |
| 명령어, 스택 특이점, 절대 금지 5개(맨 위), 포인터 | `CLAUDE.md` — 레포가 `AGENTS.md`를 쓰면 그 파일(CE `project-standards` 리뷰어도 둘 다 읽는다) (≤60줄 soft, 폴더맵·의존성 목록처럼 코드에서 유추되는 건 제외) | 에이전트 |
| **완료 정의(DoD)** | 프로젝트의 검증 스크립트 **한 곳**(`commands.verify`). CLAUDE.md 한 줄·Stop 훅·OpenSpec guidance·CI는 이름만 참조 | Stop 훅, CI |
| 파일 타입별 판단 규칙(컴포넌트·상태·에러·테스트) | `.claude/rules/<topic>.md` + `paths:` frontmatter, 각 ≤30줄, 명령형, 정본 예시 파일 1개 포인터 | 해당 파일을 읽을 때 재주입 |
| 긴 이유·예시 | `docs/conventions.md` — 백틱 포인터로만 참조, **`@` import 금지** | 사람, 필요시 에이전트 |
| 커밋 형식 | conventional commit 린터 + git 훅 매니저(`commit-msg`, `pre-commit` staged 린트) + CI | 훅, CI |
| 임포트 경계(아키텍처) | 경계 린트(`domains.root`·`allowed_edges`와 1:1) + 순환 금지 | 린트(PostToolUse) |
| 토큰만 | 스타일 린트(임의값·토큰 외 색 금지) | 린트 |
| 크기·중복·죽은 코드 | 파일 길이 상한, 복제 검사(CI), 미사용 export 검사 | 린트·CI |
| 의존성·설정 보호 | `PreToolUse` Write\|Edit **그리고** Bash 매처(쉘 우회 차단) + `permissions.deny` + Stop에서 보호 파일 diff 확인 — 패턴은 `protected` | 훅 |
| `--no-verify` 등 우회 | `PreToolUse` Bash 거부 + `permissions.deny` + CI | 훅, CI |
| 아키텍처 결정과 허용 엣지 | `docs/adr/0001-domain-structure.md` (명령형 불릿) | 사람 |
| 행동 스펙 | `openspec/specs/<capability>/spec.md` | `openspec validate --archived`(CI) |
| OpenSpec 생성 시 주입 | `openspec/config.yaml` `context`/`rules` | propose/apply |
| 해결한 문제 · 용어 · 전략 | `docs/solutions/` · `CONCEPTS.md` · `STRATEGY.md` (compound-engineering 채널 — 있으면 그대로 쓴다) | `/ce-compound`, 리뷰어 입력 |
| 스택 산문 컨텍스트 | `openspec/config.yaml` `context:` — **`cgamja.json`에서 생성**, 손으로 중복 작성 금지 | propose/apply |
| 절차("새 도메인 추가하는 법") | 스킬 | 호출 시 |

문서 rot 방지: CI에 20줄 스크립트 — CLAUDE.md/rules/conventions가 가리키는 경로가 존재하는지, `cgamja.json`의 명령이 실제 스크립트와 일치하는지. 주기적 트림.

## 2. 아키텍처 — spec이 아니라 ADR + 린트에 (`adr/0006`)
OpenSpec 스펙은 사용자가 보는 동작만. `design.md`는 archive 시 버려진다(OpenSpec 자체 인정) → 아키텍처는 ADR 번호를 참조만.

### 원칙 (구조 이름과 무관)
1. **기능 단위 수직 분할**이 있고 각 단위에 **public 진입점 하나**가 있다(`domains.root`/<name>/진입 파일). 다른 단위·조립층은 그 진입점으로만 import.
2. **단위 간 import 기본 금지.** 필요한 엣지만 `allowed_edges`(선언)와 ADR 표에 **동시에** 명시. 허용 엣지가 3개째면 중간 층 추가 ADR의 신호.
3. 공용(`shared`) 층은 기능 단위를 모른다. 조립층(앱 부트스트랩·라우터)은 공용은 자유, 기능 단위는 진입점으로만. 아무도 조립층을 import하지 않는다.
4. 단위 내부는 상대경로(자기 진입점 경유 금지 — HMR 전체 리로드·순환).
5. 한 화면만 쓰는 UI는 그 단위에. 화면 하나 때문에 단위를 만들지 않는다.
6. 린트가 못 보는 경계(서버/클라이언트 컴포넌트 경계 등)는 명시 + 리뷰 항목.

**brownfield**: 기존 구조(`features/`, `modules/`, `pages/`…)가 있으면 그 이름을 `domains.root`에 선언하고 위 원칙만 린트로 건다. 구조를 바꾸자고 하지 않는다. greenfield 기본값은 §6.

### 진화성 센서 (에이전트 코드베이스의 실증된 실패 = 의미적 중복 1.87배, 상태 sprawl)
파일 길이 상한 · 복제 검사 임계치 · colocated 테스트 · CLAUDE.md "만들기 전 공용 층과 대상 단위 진입점을 grep하고 재사용한 걸 PR에 적어라" · LSP · 단위 진입점을 인벤토리로 읽히게 유지.

## 3. `CLAUDE.md` 시작 템플릿 (≤60줄, `@` import 없음) — `develop-setup/templates/CLAUDE.md`
맨 위 "하지 않는 것" 5~7개(의존성 추가·토큰 외 색·검색 없는 새 컴포넌트·초록 위한 테스트 수정·훅 우회·디자인 원천 호출·직접 HTTP/손 타입) → 스택 한 줄 → 명령(`commands.*`와 동일) → 구조 한 단락 → 참고 포인터. 값은 세팅 스킬이 **발견한 것**으로 채운다(템플릿 변수는 선언과 1:1).

## 4. `.claude/rules/` (`develop-setup/templates/rules/`)
`components.md`(네이티브 요소·빈/로딩/에러 필수·정본 예시 경로) · `state.md`(로컬 → 공유 → 서버 → URL, 같은 진실 두 곳 금지) · `tests.md`(시나리오 1 = 테스트 1, 역할 쿼리, 경계 mock만) · `platform.md`(프로필). `paths:`는 `tests.patterns`·`domains.root`와 일치. path-scoped rule은 compaction 후 재주입되지 않는다 → "절대" 규칙은 여기 두지 않는다(훅).

## 5. 훅 세트 (`.claude/settings.json` + `.claude/hooks/*.sh` — 템플릿 그대로 복사, 패턴·명령은 `cgamja.json`에서 읽는다)
| 이벤트 | 매처 | 동작 | 선언 키 |
|---|---|---|---|
| PostToolUse | `Edit\|Write` | 그 파일만 포맷+린트 | `lint_file` |
| PreToolUse | `Edit\|Write` **+ `Bash`** | 보호 파일 deny · 계약 생성물 deny · 테스트 파일 `ask`(red 게이트, `TDD_PHASE=red`만 우회) · 쉘 쓰기 우회 deny | `protected`, `contract.generated`, `tests.patterns` |
| PreToolUse | `Bash` | `--no-verify`/`-n`/`HUSKY=0`/`LEFTHOOK=0`/`core.hooksPath`/`push --force`/패키지 추가 거부 | — |
| Stop | — | 코드 편집한 턴만 `commands.verify`(`stop_hook_active` 가드, 실패 exit 2 + 마지막 50줄). 8회 차단 후 강제 종료됨 | `commands.verify` |
| `permissions.deny` | — | 위 Bash 패턴을 **deny에도** 넣는다 — 훅 `if` 필터는 fail-open | |
| env | — | `GIT_PAGER=cat` | |

전체 타입검사를 PostToolUse에 넣지 않는다(편집 50회 × 20초). 전체 검사는 Stop. 훅이 너무 자주 막으면 범위를 줄인다 — 우회 습관이 더 위험. 선언이 없으면 훅은 막지 않고 "세팅 누락"을 stderr에 남긴다(fail-open이 아니라 명시).

## 6. 검증된 구현 — React greenfield 기본 구조 (2026-08-21, `adr/0006`)
**bulletproof-react의 `features/` 구조 + FSD 세그먼트명(`ui/model/api`) + FSD public API 규칙.** "FSD-lite"가 아니다. FSD 2.1 자체가 "pages부터 시작하고 거기서 멈춰도 된다"고 하고, FSD 블로그는 솔로·단기 프로젝트에 풀 FSD를 권하지 않는다.
```
src/
  app/          Next: App Router 폴더(layout·providers·한 줄 re-export page.tsx). Vite: providers+router 부트스트랩
  routes/       Vite+TanStack만. 평면. Route + loader만 export
  domains/<name>/
    index.ts    다른 도메인·app이 import할 유일한 경로. named export만, export * 금지
    ui/ model/ api/   (테스트는 ui 옆에 colocate; model이 변이 테스트 대상)
  shared/ui/button/index.ts   모듈별 entry. shared/ui/index.ts, shared/index.ts 없음
  shared/lib/ shared/config/
```
- 린트: `eslint-plugin-boundaries` 7.x `dependencies`(`entry-point`는 deprecated) + `no-unknown-files` + `import-x/no-cycle`. 검증본 `develop-setup/templates/react/eslint.boundaries.js`. **실측 함정**: boundaries v7은 레거시 `import/resolver` 키만 읽는다 — `import-x/resolver-next`만 있으면 `@/…`가 external로 분류돼 경계 린트가 **조용히 통과**(2026-08-21). 두 키를 모두 둔다. 템플릿 변수는 `{{from.type}}`(v7; `${}` 구문은 deprecated). 요소 패턴에 파일(main.tsx)을 넣으면 `no-unknown-files` 오탐 → 엔트리는 `src/app/`으로.
- 세팅 자가검증: `src/shared/lib/_probe.ts`에서 도메인 import → `boundaries/dependencies` 에러가 **실제로 나는지**(`smoke.sh check` 2번 항목). 통과해 버리면 resolver 설정 문제.
- 보조: dependency-cruiser는 CI 그래프용(선택). steiger·sheriff는 쓰지 않는다.
- Next RSC 경계(`'use client'`)는 린트 불가 — `ui/`에서 명시, 리뷰 항목(L7).
