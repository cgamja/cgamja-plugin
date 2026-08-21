# 모델 라우팅 — 어떤 일을 어떤 모델에 (`adr/0011`)

**원칙**: 본 세션(오케스트레이터) 모델은 **사용자 선택**(fable/opus — 2026-08-21 세 런에서 비용 차이 없음, adr/0011 개정 2). 서브에이전트는 역할별로 `model:`을 **명시**한다(3런 검증·채택). 비용을 줄이는 레버는 모델이 아니라 절차 부피(`review-lenses-frontend.md` §5). 추론·판단·리서치가 필요한 자리만 본체가 직접 하고, 나머지는 Agent/Workflow 호출에 `model:`을 명시한다. 비용 측정은 `reports/`의 "소요" 줄로(2026-08-21 Tier-2 한 번 $7.20 중 리뷰 서브에이전트 58k 토큰이 기준선).

## 1. 라우팅 표
| 작업 | 모델 | 근거 |
|---|---|---|
| 티어 판정, Tier-2 질문 설계, 계약 상태 판정(A/B/C/D), 스펙 diff 제안, 디자인 갭 후보 판단, 구현·테스트 작성(위임 안 할 때) | **본체**(세션 모델) | Tier-2 1회 ≈ $30~45는 세션 모델과 무관(3런 실측). 판단 품질이 걱정되면 fable, 아니면 opus — 사용자 선택 |
| 리서치(새 방법론 평가, 라이브러리 비교, 외부 문서 읽기) | **본체** 또는 `opus` Agent | 요약의 정확성이 결과물. 리서치는 `feedback-install-and-verify` 원칙대로 설치·실행까지 |
| `/ce-brainstorm`, `/opsx:propose` 스펙 작성 | **본체** (Skill 도구는 모델 지정 불가) | — |
| 코드 탐색(Explore: 유사 컴포넌트 검색, 사용처 찾기, `docs/solutions` grep) | **`haiku`** | 읽고 위치만 보고. 결론은 본체가 |
| 구현 task(`opsx:apply` 안에서 서브에이전트로 뺄 때), 테스트 코드 작성, 스냅샷 `summary.md` 작성 | **`sonnet`** | 스펙·테스트가 정해진 뒤의 실행. 초록/빨강이 오라클 |
| 스크린샷 촬영·비교 나열, computed style 수집, 린트 결과 정리 | **`haiku`** | 기계적 수집 |
| 코드 리뷰 렌즈 에이전트(`review-fe`의 persona, `agents/`) | **`opus`** 기본, 정확성·스펙 완전성 렌즈는 Tier-3에서 **`fable`** | 리뷰어는 작성자보다 약하면 안 된다. 단 a11y·플랫폼 렌즈는 체크리스트 대조라 `sonnet` |
| `/ce-code-review`, `/ce-simplify-code`, `/ce-commit*` | 세션 모델 (지정 불가) | CE 스킬은 Skill 도구 — 내부에서 자체 서브에이전트를 띄움 |
| 변이 테스트 결과 해석, flaky 원인 분류 | `sonnet` | — |

## 2. 호출 방법
- **Agent 도구**: `model: "haiku" | "sonnet" | "opus" | "fable"`. 생략하면 세션 모델을 상속한다 — **생략 = 비싼 기본값**이므로 이 플러그인의 스킬은 Agent 호출마다 표대로 명시한다.
- **Workflow**: `agent(prompt, {model: 'sonnet'})`. 렌즈별로 다르게.
- **Skill 도구**: 모델 인자 없음. ce-*·opsx:* 는 세션 모델. 이게 비용의 상수항 — 줄이려면 세션 자체를 `/model opus`로 띄우고, 티어 판정·갭 루프처럼 Fable이 필요한 순간만 `/model fable`로 올린다(사람이 결정).
- `agents/*.md` persona 파일의 frontmatter `model:`이 기본값이고, review-fe가 티어에 따라 올린다(`review-lenses-frontend.md` §3).

## 3. 하지 않는 것
- 본체를 haiku/sonnet으로 띄우고 "중요하면 올리기" — 티어 판정을 약한 모델이 하면 낮은 티어로 새는 쪽으로 틀린다(관찰: 작업량으로 판단해 버림).
- 리뷰 렌즈를 비용 때문에 haiku로 — 리뷰가 작성자(sonnet)보다 약하면 게이트가 아니다.
- 모델별로 프롬프트를 다르게 쓰기 — 같은 persona 파일을 쓰고 모델만 바꾼다. 결과 차이는 `reports/`에 기록해 표를 고친다.

## 4. 재검토 조건
- sonnet 구현 task가 같은 스펙에서 2회 연속 초록을 못 만들고 본체가 다시 짬 → 그 task 유형을 `opus`로 승격
- haiku Explore 결과가 틀려 본체가 재탐색한 게 3회 → Explore 프롬프트에 "모르면 후보 전부 나열" 추가 후에도 반복되면 sonnet
- 리뷰 렌즈 sonnet이 opus와 같은 지적을 3회 연속 → 그 렌즈는 sonnet으로 내림
