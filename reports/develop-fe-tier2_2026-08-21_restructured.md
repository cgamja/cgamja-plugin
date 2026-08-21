# develop-fe — Tier-2 기능, 분리 구조 1차 (todos 목록+추가, adr/0010~0012 검증) (2026-08-21)
- 대상: `/cgamja:develop-fe` · headless `claude -p --dangerously-skip-permissions`, **`TDD_PHASE=red` 세션**(사람이 띄운 우회 키 — red 게이트 없음, adr/0009) · 세션 모델 fable · 2.1.238 · 플러그인 커밋: 분리 구조(미커밋 워킹트리)
- 프로젝트: 새 스크래치 `todos-app`(같은 날 develop-setup이 만듦 — Vite 8 + React 19 + TanStack Router/Query + Tailwind v4, 프로필 **web-mobile**, a11y 린트·axe 포함, 47턴·$7.56·9.8분)
- 요청: "할 일 목록 보기 + 새 할 일 추가. 서버 API 없음" + Tier-2 질문 답 선입력(이전 리포트와 같은 시나리오)
- 소요: **118턴 · 40.3분 · $33.07** (이전 같은 시나리오: 47턴 · 8.5분 · $7.20)
- 적용 ADR: 0001, 0004, 0008, 0009, **0010, 0011, 0012**
- 모델: 본체 fable · 서브에이전트 — L1/L2/L3/L6 opus, L4/L5 sonnet, ce-code-review 4개(1 fable + 3 sonnet) · **서브에이전트 토큰 합 ≈610k**(persona 6개 ≈307k, ce-code-review ≈304k) · 탐색·구현·테스트 작성·스크린샷은 본체가 직접(haiku/sonnet 위임 0건)

## 결과
| # | 항목 | 확인 방법 | 결과 |
|---|---|---|---|
| 1 | 티어 판정 Tier-2, change 1개 `feature` 스키마 | `openspec/changes/archive/2026-08-21-todos-list-create/` | ✅ |
| 2 | 계약 상태 B → DRAFT 스텁 → `api:gen` → 생성물만 import | `chore(api)` 커밋이 첫 커밋, L6 렌즈 "생성물 밖 fetch 0" | ✅ |
| 3 | 테스트 먼저 — `test()` 커밋이 `feat()`보다 앞 | `git log`: `eb2f97b test` → `20dc426 feat`, 이후 루프 2번 더 같은 순서 | ✅ (red 출력·이유 본문에 있음) |
| 4 | `feat` diff에 테스트 파일 없음 | L3 렌즈 + `git show --stat` | ✅ |
| 5 | **test-fe 스킬을 Skill 도구로 호출** | 트랜스크립트에 `cgamja:test-fe` 호출 | ❌ **본체가 `references/tdd-frontend.md`를 직접 읽고 작성** — 계층·쿼리 규칙은 지켰으나 스킬 경계 무시 |
| 6 | **review-fe 스킬을 Skill 도구로 호출**, 렌즈 선택 보고 | 최종 보고의 렌즈 표 | ✅ L1 L2 L3 L4 L5 L6 (UI+API 조건 판정 정확) |
| 7 | 렌즈마다 `model:` 명시 | 서브에이전트 표 | ✅ 표대로(opus/sonnet) |
| 8 | persona 파일을 프롬프트로 사용(즉석 제작 아님) | `review_nudge.sh` 발동 0회, 렌즈 이름이 persona명과 일치 | ✅ |
| 9 | ce-code-review 병행 + 스펙 경로 조립 | `plan:` 인자, skill_guard 거부 0회 | ✅ (Ready with fixes → 2건 반영) |
| 10 | **L5 플랫폼 렌즈가 프로필 위반을 잡음** | 1차 증거는 375만 → L5 blocker → 390/430/768-landscape + 입력 포커스 스크린샷 추가 | ✅ **새 렌즈가 실제 결함을 잡은 첫 사례** |
| 11 | L4 접근성 — axe serious+ 0, Tab 시퀀스, 44px 터치 타깃 | `reports/todos-list-create/report.json` | ✅ |
| 12 | 증거 위치 | 이전엔 `/tmp/todos-evidence/`, 이번엔 **프로젝트 `reports/todos-list-create/`** | ✅ (우연 — 규약은 아직 없음) |
| 13 | blocker 루프 규칙 "2차에도 blocker면 멈춤" | 2차 L2 blocker 2 → 3차 persona 없이 직접 닫음 | ⚠ 절차 이탈(자진 보고). 결과는 타당 |
| 14 | `/ce-simplify-code` 1회 | — | ❌ 미실행(자진 보고) |
| 15 | archive + `validate --archived --strict` | `openspec/specs/todos/spec.md` | ✅ |
| 16 | `pnpm verify` 초록, e2e 2/2, browser 13/13 | 최종 보고 | ✅ |

## 비용 분해 (왜 4.6배인가)
| 구간 | 토큰/비용 | 비고 |
|---|---|---|
| 본체 (fable) | 출력 90k(thinking 21k) · 캐시 읽기 13.9M | 118턴 — 이전 47턴. 리뷰 루프 3회(1차 6렌즈 → 반영 → 2차 L2 → 보강)와 스펙 개정 3회가 턴을 키움 |
| persona 6개 | ≈307k | L6 64k가 최대(openapi·ADR·토큰 파일 다 읽음) |
| ce-code-review 4개 | ≈304k | correctness(fable 75k) + standards/testing/validator(sonnet 97k/75k/57k). **persona와 지적 중복** — 액셔너블 2건만 새로움 |
| 합 | $33.07 | 리뷰 관련이 절반 이상 |

## 발견한 결함 → 조치
| # | 결함 | 심각도 | 조치 |
|---|---|---|---|
| 1 | **리뷰 비용 = 구현 비용 이상** — `review-lenses-frontend.md` §5 재검토 조건("리뷰 비용 > 구현 비용 2회") 1회째 | 높음 | 2차 실행(#2)을 **ce-code-review 병행 제거 변형**으로 돌려 persona만으로 blocker 누락이 생기는지 측정 → adr/0012 §3 개정 여부 결정 |
| 2 | 테스트 task가 `test-fe` 스킬을 거치지 않음 — workflow.md 한 줄 지시("Skill 도구로 cgamja:test-fe")를 본체가 references 직접 읽기로 대체 | 중간 | `review_nudge.sh`처럼 **훅으로** — 테스트 파일 Edit 전 이번 세션에 `test-fe` Skill 호출이 없으면 additionalContext로 상기(차단 아님). adr/0007 범위 |
| 3 | 본체가 구현·테스트 작성·스크린샷을 전부 직접 → sonnet/haiku 라우팅이 **실제로 적용된 구간 0** | 높음 | adr/0011의 한계 확인: 라우팅 표는 "뺄 때만" 적용된다. 선택지 (a) 세션 `/model opus` + 판단 순간만 fable (b) workflow.md 구현 task를 sonnet 서브에이전트 위임으로. **#2 결과 본 뒤 결정** |
| 4 | blocker 루프 3차 진입 규칙을 자의로 건너뜀 | 낮음 | "2차 blocker가 **자기 반영으로 새로 생긴 스펙 문장**의 테스트 누락이면 직접 닫고 보고"를 review-fe에 예외로 명문화(현실적 경로) |
| 5 | `/ce-simplify-code` 생략 | 낮음 | 2회 반복되면 workflow.md에서 Tier-2 선택 항목으로 내림 |

## 관찰 (수정 안 함)
- L5가 **이번 구조에서 새로 추가된 가치를 증명** — 이전 Tier-2 리포트에서 "375만 찍음"은 아무도 안 잡았다.
- ce-code-review의 고유 기여는 "생성 훅이 비-2xx를 성공으로 resolve"(정확성)와 "refetch 실패 시 목록 유지" 2건 — 둘 다 L1 persona 범위인데 L1은 못 잡았다. **L1 persona 약점**인지 **모델(opus vs fable) 차이**인지 → 같은 diff의 A/B(`logs/ab-t2a-*`)로 분리 중.
- 본체가 archive 후 "스펙에 없는 관찰 불가 문장"(재요청 중 비활성)을 발견해 스펙을 고친 것은 살아있는 스펙 유지의 좋은 사례.
- 알려진 한계에 "Lighthouse 미실행"을 스스로 적음 — 프로필의 성능 증거 행이 읽혔다는 뜻. 강제는 아직 없음.

## 다음
- #2(`t2b`, persona만) 결과와 A/B 결과를 이 파일 아래 또는 별도 리포트에 추가
- 결함 1·3의 결정 → adr/0011, 0012 개정(검증 란 채움)
- 결함 2 훅 추가 + 테스트

---
## A/B — 같은 diff(`02a14d3..65cf481`, 스펙 `openspec/specs/todos/spec.md`)에 L1·L2 persona를 opus vs fable로 (adr/0011 검증)
실행: `claude -p --model <m>` 단독, persona 본문 + diff 범위 + 스펙 경로. 사전 판정 규칙: "fable이 opus가 놓친 **blocker**를 1개 이상 잡으면 Tier-2 L1·L2를 fable로 승격".

| 렌즈 | 모델 | 턴 | 비용 | blocker / should / nit | 고유하게 잡은 것 |
|---|---|---|---|---|---|
| L1 정확성·중복 | **opus** | 27 | $2.45 | 0 / 4 / 3 | dev 서버에 MSW 부트스트랩이 없어 `pnpm dev`가 항상 에러 화면(실행으로 확인) · e2e smoke가 그 에러 화면에 axe를 돌리며 통과 · POST 201 응답을 버리고 invalidate만 해서 refetch 실패 시 "추가됐는데 안 보임" · 도달 불가 `add.reset()`(변이 실험으로 확정) |
| L1 | fable | 8 | $1.68 | 0 / 2 / 1 | e2e의 손 타입 `Todo` 중복 · 생성 훅 vs 래퍼 "다르다" 판정(근거 정확) · 나머지는 "문제 없음" 목록 |
| L2 스펙 완전성 | **opus** | 12 | $1.16 | 2 / 4 / 1 | S7 "이어 입력 보존" 테스트 없음 · **S1 감속 모드 테스트·증거 없음(blocker)** · 체크 표시 assertion 없음 · 375만 자동 검증 · archive 시 `## Contract` 유실 · `maxLength` 미명문화 |
| L2 | fable | 8 | $1.26 | 1 / 3 / 0 | S7 동일 blocker · 감속 모드는 should · heading 테스트 없음 · scope creep 4건 |

**판정: opus 유지.** fable이 opus가 놓친 blocker는 0건. 오히려 opus가 더 많이 잡았고(L1 3건은 실행해서 확인한 실질 결함), 이유는 모델이 아니라 **행동** — opus는 27턴 동안 dev 서버 probe·변이 실험·grep을 돌렸고 fable은 8턴 만에 읽고 판정했다. 좁은 렌즈에선 "더 오래 뒤지는 쪽"이 이긴다. 비용도 opus가 렌즈당 $1.2~2.5로 예산 안.
- adr/0011 검증 란: L1·L2 opus 유지 확정(1회). Tier-3/PR의 fable 승격은 아직 근거 없음 — 다음 Tier-3에서 같은 A/B.
- 부작용: opus L1이 변이 실험으로 `TodoForm.tsx`를 고쳤다 되돌리는 사이 **같은 트리에서 #2 세션이 작업 중**이었다. → 모든 persona에 "읽기전용, 변이는 글로" 규칙 추가(조치 완료).
- ce-code-review가 #1에서 잡았던 2건(비-2xx resolve, refetch 실패 시 목록 유지)은 A/B 시점엔 이미 반영된 코드라 비교 불가. 다만 opus L1의 #1(201 응답 버림)은 그 연장선의 결함을 더 깊이 본 것 — persona L1이 ce-code-review correctness를 대체할 수 있다는 약한 근거.

---
## #2 — Tier-2 `todos-toggle-filter` (완료 토글 + URL 필터), **persona만(ce-code-review 제외)** 변형
- 같은 스크래치, #1 위에 21커밋 · `TDD_PHASE=red` headless · 세션 fable
- 소요: **$45.65** (#1 $33.07) · archive까지 완료, `pnpm verify` 초록(browser 27/27, e2e 3/3, jscpd 2.0%)
- 모델: L1/L2/L3/L6 opus, L4/L5 sonnet, ce-simplify 3개 sonnet · 서브에이전트 ≈676k(persona 2회 ≈508k + simplify ≈168k)

| # | 항목 | 결과 |
|---|---|---|
| 1 | 계약 상태 D → DRAFT 0.0.3 `updateTodo` **먼저** → `api:gen` | ✅ |
| 2 | test→feat 순서, red 출력 커밋 본문 | ✅ (red→fix 루프 4회) |
| 3 | UI 증거 처음부터 프로필대로(4뷰포트×5상태, axe 0, 44px, Tab) | ✅ — #1의 L5 학습이 같은 트리의 다음 change에 전이됨(`reports/` 선례) |
| 4 | review-fe persona만 — 1차 blocker 3(L1 롤백 스냅샷 / L2·L3 낙관·롤백 **판별 불가** / L5 포커스 샷) → 2차 L2 2 → 예외 경로로 종료 | ✅ 규칙·예외 모두 명문화된 대로 |
| 5 | **실제 버그 2개** — '전체' 필터 항상 활성(`activeOptions.exact`), 동시 토글 시 alert 누락 — 스크린샷·L1에서 발견, red 테스트 후 수정 | ✅ |
| 6 | L3 변이 확인 4건 전부 판별(onMutate/onError/isMutating 가드/exact 제거 → 각각 실패) | ✅ — **ce-code-review 없이 품질 유지** |
| 7 | `/ce-simplify-code` 실행(reuse 1·quality 1, jscpd 5.0→2.0%) | ✅ (#1에서 빠진 것 회복) |
| 8 | `test-fe` Skill 호출 | ❌ 여전히 직접(훅 `test_nudge.sh`는 이 런 이후 추가) |
| 9 | 훅 오탐 2건 — lefthook `no-test-edit-in-feat`가 **직전 커밋 메시지**를 읽음 / `protect-bash` gen.ts 패턴이 `2>&1`을 `>`로 잡음 | 우회 없이 대처·메모리 기록 → **템플릿 수정 완료**(commit-msg `{1}`, fd 리다이렉트 제외) + 테스트 2개 |
| 10 | 병합 스펙 106줄(80줄 규칙) | 관찰 — capability 분할 후보 |

## 비용의 진짜 원인 — 모델별 분해 (`modelUsage`)
| 런 | fable(본체) | opus(persona) | sonnet(L4/L5/simplify/ce) | 합 |
|---|---|---|---|---|
| #1 (ce-code-review 병행) | **$26.06** (79%) | $4.20 | $2.82 | $33.07 |
| #2 (persona만, change 더 큼) | **$35.57** (78%) | $7.39 | $2.69 | $45.65 |

- **본체가 ~78%.** 서브에이전트 라우팅(opus/sonnet)은 잘 작동했고 전부 합쳐도 $7~10. ce-code-review 유무는 오차 범위(#2가 더 비싼 건 change 크기·리뷰 2회·simplify 3개).
- 본체 비용 = fable × (구현·테스트 작성·스크린샷 스크립트·스펙 개정·리뷰 결과 반영을 전부 직접) × 캐시 읽기 14M~23M 토큰. 라우팅 표의 "구현 sonnet"은 **위임이 없으니 0% 적용**.
- 따라서 비용을 줄이는 첫 번째 레버는 ce-code-review 제거가 아니라 **본체 모델**이다.

## 결정 (adr/0011·0012 개정)
1. **adr/0012 §3 개정**: Tier-2 리뷰는 persona만. `ce-code-review`는 Tier-3 통합·PR 모드에서 선택(#1 고유 기여 2건 중 1건은 이후 opus L1이 더 깊게 잡음, #2는 없이도 blocker 5·버그 2). 훅의 bare 호출 거부는 유지.
2. **adr/0011 개정**: develop-fe 세션의 **권장 모델 = opus**. Fable은 Tier-3(`ce-brainstorm`·change 분해)·디자인 갭 루프·새 방법론 평가·플러그인 자체 개선에서 사람이 `/model fable`로 올린다. 근거: 두 런 모두 본체가 78%, 본체가 하는 일의 대부분은 구현·스크립트·반영(라우팅 표상 sonnet/opus 급). **다음 Tier-2는 세션 opus로 돌려 품질 동일·비용 1/2 이하인지 확인**(예상 $12~18).
3. 구현 task를 sonnet 서브에이전트로 위임(선택지 b)은 **보류** — 컨텍스트 전달 비용과 테스트 파일 보호 훅(서브에이전트도 같은 훅)을 검증해야 하고, 2번이 더 싸고 단순.

## 다음
- 세션 opus로 Tier-2 1회(같은 스크래치, 다음 기능) → 품질(blocker·버그 발견)·비용 비교 → adr/0011 "채택"
- Tier-3 1회에서 L1~L3 fable A/B
- `test_nudge.sh` 효과 확인(다음 런에서 `test-fe` 호출 여부)
- `openspec/specs/todos/spec.md` 80줄 초과 → capability 분할 규칙을 `openspec-setup.md`에
