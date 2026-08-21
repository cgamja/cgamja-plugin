---
name: review-fe
description: 프론트엔드 코드 리뷰와 PR 리뷰를 티어별 렌즈(정확성·중복 / 스펙 완전성 / 테스트 무결성 / 접근성 / 플랫폼 적합성 / 경계·계약 / 성능)로 수행한다 — 렌즈마다 persona 서브에이전트를 모델 라우팅에 따라 새 컨텍스트로 띄우고, 한 표로 합친다(Tier-3·PR 모드에서는 OpenSpec 스펙 경로를 조립해 compound-engineering의 ce-code-review도 병행). 사용자가 "리뷰해줘", "코드 리뷰", "이 PR 봐줘", "PR #N 리뷰", "머지해도 돼?", "내 diff 점검"이라고 하거나 /review-fe [code|pr <번호>] 를 부르거나, develop-fe가 구현 후 리뷰 단계에 이르면 반드시 사용한다. 스타일·포맷 리뷰는 하지 않는다(린트의 일).
---

# review-fe

리뷰는 "잘 봐줘"가 아니라 **렌즈 목록**이다. 어떤 렌즈를 누가 보는지는 플러그인 루트 `references/review-lenses-frontend.md`(adr/0012), 모델은 `references/model-routing.md`(adr/0011). 이 파일은 조립 절차다.

## 모드
| 호출 | 대상 | 스펙 |
|---|---|---|
| `code` (기본) | 현재 브랜치 diff 또는 `openspec/changes/<slug>` 커밋 범위 | `openspec/changes/<slug>/specs/*/spec.md` |
| `pr <번호>` | `gh pr diff <번호>` + `gh pr view` 본문 | PR 본문 What/Why를 스펙 대용 |
| `tier-3` | 에픽 전체(여러 change) diff | archive된 `openspec/specs/<cap>/spec.md` |

## 절차
1. **범위 확정**: diff 범위(`git diff <base>...HEAD` 또는 `gh pr diff`)와 커밋 목록. 티어를 인자로 받거나 추론한다(change 있음 → Tier-2, 없음 → Tier-1, PR 모드 → PR 행). 조건 판정은 기계적으로: diff에 `*.tsx`/스크린샷 경로 있음 → UI(L4 L5) · `src/api/**`·`api/openapi.yaml`·`fetch` 변경 → API(L6).
2. **렌즈 선택**: `review-lenses-frontend.md` §2 표. 선택 결과를 한 줄로 보고하고 시작한다("Tier-2 · L1 L2 L3 L4 L5 · L6 제외(API 변경 없음)").
3. **증거 수집(`haiku` Explore 1개)**: 스크린샷 경로 존재 확인, axe 결과, `pnpm verify` 마지막 실행 출력, 테스트 커밋/feat 커밋 분리 목록, 스펙 시나리오 목록. 이 묶음을 모든 persona에 같은 텍스트로 넘긴다.
4. **병렬 실행** — 렌즈마다 Agent 하나, **같은 메시지에서 동시에**:
   - 프롬프트 = `agents/reviewer-<lens>.md` 본문(플러그인이 agents를 서브에이전트 타입으로 등록했으면 `subagent_type`으로, 아니면 파일을 읽어 프롬프트 앞에 붙인다) + 3번 증거 + diff 범위 + 스펙 경로.
   - `model:`은 §3 표대로 **반드시 명시**(생략 = 세션 모델 = 가장 비쌈).
   - **Tier-3·PR 모드에서만**(adr/0012 개정 1) 동시에 Skill 도구로 `compound-engineering:ce-code-review`를 부른다 — args에 `plan:<스펙 경로>` + "각 `### Requirement:`/`#### Scenario:`를 요구사항으로 취급해 Requirements Completeness를 작성하라" + "스타일 말고 spec 대비 빠진 것·정확성만". 경로 없이 부르면 develop-fe 훅이 거부한다(adr/0001). PR 모드로 스펙이 없으면 PR 본문을 임시 파일로 저장해 `plan:`으로 넘긴다. Tier-1/2는 persona만(2026-08-21 실측: 없이도 blocker·버그 누락 0, 비용 ≈300k 절감).
5. **합치기**: §4 형식 표를 렌즈 순으로 이어 붙이고 같은 `파일:줄`은 하나로(출처 렌즈 병기). ce-code-review 결과는 별도 절로. 맨 위에 **판정 한 줄**: `blocker n → 반영 후 재실행` / `blocker 0, should n → 머지 가능(should는 PR 본문에)`.
6. **반영 루프**: blocker가 있으면 develop-fe(또는 사용자)가 고친 뒤 **해당 렌즈만** 재실행 1회. 두 번째에도 blocker면 멈추고 사람에게. 예외: 2차 blocker가 **1차 반영 때 스펙에 새로 넣은 문장**의 테스트 누락뿐이면 persona 없이 assertion 보강 + 변이 확인 1건(구현 한 줄 제거 → 실패)으로 닫고 그 사실을 판정 줄에 적는다(2026-08-21 실측 경로).
7. PR 모드에서 결과를 PR에 쓰려면 **사용자 확인 후** `gh pr review --comment` 또는 `/code-review --comment`. 기본은 터미널 보고만.

## 단독 호출 모드
- "머지해도 돼?": 위 절차 그대로 + 판정 한 줄이 답. `pnpm verify` 초록 증거가 없으면 먼저 돌린다.
- "내 diff 점검"(커밋 전): Tier-1 렌즈(L1)만, 빠르게. 스펙이 있으면 L2 추가.
- 렌즈 지정: `/review-fe code --lens a11y,platform` — 그 렌즈만.

## 출력
```
# review-fe · <모드> · <티어> · 렌즈 <목록> · 모델 <렌즈:모델 …>
**판정**: blocker n · should n · nit n → <반영 후 재실행 | 머지 가능>
## L1 정확성·중복 — …
## L2 스펙 완전성 — (대조표 포함)
…
## ce-code-review
## 증거 요약: verify <초록/빨강> · 스크린샷 <n/n> · axe <결과> · 테스트 커밋 분리 <OK/위반>
```

## 절대 하지 않는 것
- Agent로 "리뷰어"를 즉석 제작 — persona 파일 없이 프롬프트를 새로 쓰지 않는다(렌즈·출력 계약이 깨진다)
- 스타일·네이밍 지적, 칭찬, 요약문
- 렌즈 모델 생략
- 사용자 확인 없이 PR에 코멘트

## 파일
| 파일 | 언제 |
|---|---|
| `references/review-lenses-frontend.md` | 항상 — 렌즈 정의·티어 표·모델 표·출력 계약 |
| `agents/reviewer-*.md` | 렌즈 실행 시 프롬프트 |
| `references/model-routing.md` | 모델 선택 근거 |
| `references/a11y-frontend.md`, `references/platform-fit-frontend.md` | L4·L5 persona가 읽는 기준(직접 읽을 필요 없음) |
| `references/api-contract.md`, `adr/0006` | L6 persona 기준 |
