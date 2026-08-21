# develop-fe — Tier-2 기능 (todos 목록+추가, 스펙 없음→DRAFT) (2026-08-21)
- 대상: `/cgamja:develop-fe` · headless `claude -p --dangerously-skip-permissions`(Tier-2 질문 답 선입력) · 기본 모델 · 2.1.238
- 프로젝트: 같은 스크래치(Tier-1 이후, Bash 훅 강화본 적용 상태)
- 요청: "할 일 목록 보기 + 새 할 일 추가. 서버 API 없음" + 계약 ⑥ 답(DRAFT `GET/POST /todos`, Todo shape)
- 소요: 47턴 · 8.5분 · **$7.20** (본체 ~65k + 리뷰 서브에이전트 58k 토큰)
- 적용 ADR: 0001, 0004, 0005, 0006, 0008

## 결과
| # | 항목 | 확인 방법 | 결과 |
|---|---|---|---|
| 1 | 계약 상태 B | `api/openapi.yaml`에 `/todos` GET/POST + `Todo`/`CreateTodoRequest` 추가 → `api:gen` → 생성 훅(`listTodos`/`createTodo`/zod `CreateTodoBody`)만 사용, 1~120자 제한은 계약에만 | ✅ ADR 0008 핵심 동작 |
| 2 | OpenSpec change | `todos-list-create` feature 스키마, delta spec 9 시나리오 + `## Contract`, tasks 13 | ✅ |
| 3 | 구현 | `model/validateTitle`, `api/useTodos`·`useAddTodo`, `ui/TodoList`·`TodoForm`·`TodosPage`, shared button/cn 재사용 | ✅ |
| 4 | 증거 | `pnpm verify` 초록, e2e 1/1, 375px 스크린샷 7장(list/empty/loading/error/validation/add-success/add-fail), 콘솔 에러 0 | ✅ |
| 5 | 리뷰 | 스펙 대조 0 gap, 5건 중 4건 수정(`fix(todos)`) | ✅ 내용 / ❌ **`/ce-code-review` Skill 호출 없음** — 서브에이전트로 즉석 리뷰(아래 관찰 2) |
| 6 | **테스트** | tasks 2.1~2.3 **미작성** — `TDD_PHASE` 미설정이라 훅이 막음, 우회하지 않고 보고. **구현은 진행됨** | ❌ 규칙 결함(아래 결함 1) |
| 7 | 상태 D | 스펙 diff 제안이 필요한 상황이 없었음 | — 미검증 |
| 8 | 아카이브 | 테스트 없어 보류 — 맞는 판단 | ✅ |
| 9 | 커밋 | `chore(api)` → `docs(spec)` → `feat` → `fix` → `docs(spec)` 5개. test 커밋 0 | ⚠️ (6의 결과) |

## 발견한 결함 → 조치
| # | 결함 | 심각도 | 조치 |
|---|---|---|---|
| 1 | **단일 세션에서 red 턴을 열 방법이 없음** — Tier-1 구멍을 막자(인라인 `TDD_PHASE` 거부) 테스트 task가 전부 막히고, 워크플로우가 "테스트 먼저" 대신 "구현 먼저, 테스트는 다른 세션에서"로 뒤집힘. 규칙이 누가 red를 여는지를 정하지 않았던 것 | **높음** | **adr/0009**: 테스트 파일 Edit = `permissionDecision: "ask"`(사람이 diff 승인 = red 게이트; 실측: 대화형 프롬프트 / 비대화형은 skip-permissions여도 거부). `TDD_PHASE=red`는 사람이 띄운 세션의 우회 키. Bash 쓰기는 항상 deny. workflow Tier-2 4번에 "승인 없으면 구현으로 넘어가지 말고 멈춤" |
| 2 | Bash 훅 리다이렉트 패턴이 `2>&1`·`>/dev/null`을 쓰기로 오인 → 읽기 명령 오차단(실측 7건, 에이전트 체감 ~20) | 중간 | fd 리다이렉트를 제거한 뒤 판정. 테스트 4건 추가(33/33) |
| 3 | `protect-files.sh`가 `cwd` 상대경로 전제 | 낮음 | `*/` 접두 매칭 |

## 관찰 (수정 안 함)
1. **$7.20/8.5분** — 리뷰 서브에이전트가 절반. Tier-2 1건 비용 기준선으로 기록.
2. **`/ce-code-review`를 안 부르고 Agent 도구로 리뷰** — 결과는 좋았지만 워크플로우 5번 이탈이고 `plan:` 가드는 발동 기회가 없었음. 원인 후보: (a) 스킬 호출보다 서브에이전트가 더 싸다고 판단 (b) CE 플러그인 스킬이 -p 세션에 로드는 됐는지 미확인. 다음 실행에서 "리뷰는 반드시 `/ce-code-review`"를 명시해 분리 관찰.
3. `openspec` CLI가 `operations.apply.guidance must be an array of strings` 경고 — config는 배열인데 경고. 1.10 CLI 쪽 파싱 문제 가능성, 동작엔 영향 없음. 추적 보류.
4. 스크린샷이 `/tmp/todos-evidence/`(저장소 밖) — PR 증거로 쓰려면 위치 규약 필요(`.evidence/` gitignore?).
5. 상태 D(스펙에 없는 필드)는 이번엔 발동 안 함 — 일부러 유도하는 시나리오 필요.

## 다음
- adr/0009 적용본으로 Tier-2 재실행(대화형이 이상적; headless면 skip-permissions = 게이트 없음 명시) → 테스트 task가 구현보다 먼저 커밋되는지
- 상태 D 유도 시나리오, retrofit(상태 C)

## 추가 실행 — Tier-2b "완료 토글" (adr/0009 적용 후, 승인자 없는 headless)
- 26턴 · 5.6분 · **$4.79**
- **task 2.1(red 테스트)에서 멈춤**: `Write` → ask 거부(`[tdd]` 3회) → 우회 없음(쉘 쓰기·인라인 `TDD_PHASE` 0건) → **구현 task 진행 안 함**(`src/domains/todos` diff 0). 테스트 초안은 `openspec/changes/todos-toggle-done/drafts/…test.tsx.md`로 보관 — 다음 대화형 세션에서 승인만 하면 되게 함. ✅ adr/0009 4항 동작 확인
- 그 전까지는 정상 진행: DRAFT `PATCH /todos/{id}` + `api:gen`(`useUpdateTodo`·MSW·zod 생성), change `todos-toggle-done`(시나리오 5 + Contract, tasks 8, `validate --strict` 통과), 커밋 3개(`docs(api)`, `docs(spec)` ×2)
- 관찰: "멈추기"에 $4.79 — 스펙·계약 작업이 포함된 값이라 낭비는 아니지만, 대화형이 아닌 세션에서 Tier-2를 시작하는 것 자체를 0장에서 경고할지 검토(승인자 없음을 감지할 방법: `permission_mode`가 hook 입력에 옴).
- 다음: 대화형 세션에서 초안 승인 → red 확인 → `test(todos):` → 구현 → 두 change 아카이브

## 추가 실행 — 상태 D "우선순위 배지" (스펙을 백엔드 소유 확정으로 바꾼 뒤)
- 18턴 · 4.3분 · **$3.35**
- **`api/openapi.yaml` 미수정, 코드·목·테스트에 `priority` 0건**(grep 확인). 대신 `openspec/changes/todos-priority/contract-proposal.md`에 백엔드용 최소 diff(`Priority` enum, `Todo.priority` required, `CreateTodoRequest.priority` optional) + 질문 3개 + 확정 후 절차(`api:pull`→`api:gen`→`api:check`). tasks에 "1.1 백엔드 확정 전 2.x 진행 금지". ✅ adr/0008 6항(상태 D) 동작 확인
- 부수: 0장에서 `api:check` 빨강(내가 fixture 커밋 때 재생성 안 함)을 발견해 먼저 고침 — 0장 4-1 규칙이 실제로 작동
- 관찰: `openspec validate --strict`가 한국어 스펙의 SHALL/MUST 부재를 경고(exit 1) — 영어 관례. strict를 CI에 쓰면 한국어 스펙이 전부 빨강 → `openspec-setup.md`에 "한국어 스펙이면 strict 대신 기본 validate" 또는 "Requirement 문장에 SHALL 병기" 결정 필요

## 추가 실행 — 상태 C retrofit "notes 손 API에 명세 붙이기"
- 63턴 · 20.7분 · **$14.18** (ce-code-review가 리뷰어 4 + 독립 validator 1 서브에이전트 — 비용의 큰 몫)
- 절차 전부 수행: 별도 change `api-contract-notes`(기능과 분리 ✓) → `docs/api-inventory.md` 2행 ✓ → DRAFT `GET /notes`·`POST /notes/{id}/pin` + 재생성 ✓ → `refactor(notes)`: 손 fetch·`Note` 타입·eslint-disable 제거, 생성 `listNotes`/`pinNote` 래핑 ✓ → `api:check` 0·tsc·eslint 초록 ✓. 테스트는 red 게이트로 보류(의도대로). ✅ adr/0008 5항(C)
- **이번엔 `/ce-code-review`를 Skill로 `plan:` 붙여 호출** ✓ — 앞선 두 번의 이탈과 달리. 차이: workflow 5번 문구 강화 + `review_nudge.sh`(넛지 발동 기록은 0 — Skill을 먼저 불러 Agent 경유 리뷰가 없었음). 인과는 단정 못 함, 관찰 계속
- **리뷰가 진짜 P1을 잡음**: 생성 클라이언트가 `servers: /api/v1`을 무시하고 `/notes` 호출 — 원인은 **내 `orval.config.ts` 템플릿에 `baseUrl` 누락**. 실측 후 `baseUrl: { getBaseUrlFromSpecification: true }`로 템플릿·`api-contract.md`·스크래치 수정. P2(테스트 없음)는 red 게이트 보류와 일치
- 관찰: retrofit 1건 $14는 비쌈 — 대부분 ce-code-review. 손 코드 20줄짜리엔 리뷰어 4명이 과함 → Tier-2 "작은 change"엔 ce-code-review에 `reviewers:correctness,api-contract`처럼 범위를 줄여 넘기는 옵션이 있는지 확인할 것

## 오늘 전체 비용·결과 요약
| 실행 | 턴 | 시간 | 비용 | 핵심 결과 |
|---|---|---|---|---|
| develop-setup | 24+ | ~15분 | $3.02+ | 산출물 정상, 경계 린트 무력 발견 |
| Tier-1 | 13 | 2.0분 | $1.58 | 통과, 테스트 보호 Bash 우회 발견 |
| Tier-2 (B) | 47 | 8.5분 | $7.20 | 계약 B 동작, 테스트 없이 구현(규칙 결함) |
| Tier-2b (0009 후) | 26 | 5.6분 | $4.79 | red에서 정지 ✓ |
| 상태 D | 18 | 4.3분 | $3.35 | 스펙 diff 제안, 코드 오염 0 ✓ |
| 상태 C retrofit | 63 | 20.7분 | $14.18 | 절차 전부 ✓, ce-code-review 호출 ✓, 템플릿 baseUrl 버그 발견 |
| **합계** | | **~57분** | **~$34** | ADR 0008 A·B·C·D 전부 실측, ADR 0009 신설, 템플릿 결함 4건 수정 |
