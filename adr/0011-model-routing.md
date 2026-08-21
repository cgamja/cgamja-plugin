# 0011 — 모델 라우팅: 본체는 판단, 서브에이전트는 명시한 모델로

- 상태: 제안(개정 1 — 2026-08-21 실측 후 결정 1)
- 날짜: 2026-08-21
- 관련: 0010, 0012 · 표 원문 `references/model-routing.md`

## 맥락
Tier-2 한 번에 $7.20(2026-08-21 리포트). 본체 ~65k 토큰은 절차상 불가피하지만 리뷰 서브에이전트 58k는 세션 모델을 그대로 상속한 결과다. Agent/Workflow 호출은 `model:`을 받지만 이 플러그인의 스킬은 어디에도 지정하지 않았다 — **생략이 가장 비싼 기본값**이었다.

## 결정
1. ~~본 세션은 Fable 권장~~ → **개정(2026-08-21)**: develop-fe 세션의 **권장 모델은 opus**. 근거: Tier-2 두 런 모두 본체가 총비용의 78%($26/$33, $36/$46)였고 본체가 하는 일의 대부분은 구현·테스트 작성·스크립트·리뷰 반영(라우팅 표상 sonnet/opus 급)이다. Fable은 **사람이 `/model fable`로 올리는 자리**: Tier-3(`ce-brainstorm`, change 분해), 디자인 갭 루프 후보 판단, 새 방법론·도구 평가, 플러그인 자체 개선. 티어 판정·질문 설계·계약 판정은 opus로도 충분하다고 가정하고 다음 런에서 검증한다.
2. 서브에이전트는 역할별 고정: 탐색·수집 `haiku`, 구현·테스트 작성·스냅샷 문서 `sonnet`, 리뷰 렌즈 `opus`(Tier-3·PR의 L1~L3는 `fable`), a11y·플랫폼 렌즈 `sonnet`. 플러그인의 모든 Agent/Workflow 호출은 `model:`을 **명시**한다.
3. Skill 도구(ce-*, opsx:*)는 모델 지정이 불가 → 세션 모델. 이 상수항은 사람이 `/model`로 조절한다. 스킬이 세션 모델을 바꾸려 들지 않는다.
4. persona 파일의 frontmatter `model:`이 기본값, review-fe가 티어로 승격한다. 프롬프트는 모델과 무관하게 하나.

## 기각한 대안
- 본체를 sonnet으로, 필요할 때 올리기 — 티어 판정을 약한 모델이 하면 "작업량" 기준으로 낮은 티어에 새는 쪽으로 틀린다.
- 리뷰 렌즈 haiku — 리뷰어가 작성자보다 약하면 게이트가 아니다.

## 검증
- **2026-08-21 A/B(1회)**: 같은 Tier-2 diff에 L1·L2 persona를 opus/fable로 단독 실행(`reports/develop-fe-tier2_2026-08-21_restructured.md` A/B 절). fable이 opus가 놓친 blocker 0건; opus가 L1 should 3건(dev MSW 없음·smoke가 에러 화면 검사·201 응답 버림)과 L2 blocker 1건(감속 모드)을 더 잡음. 차이는 모델보다 **행동**(opus 27턴 실행 확인 vs fable 8턴 읽고 판정). → **L1·L2 opus 유지 확정.** Tier-3/PR의 fable 승격(`review-lenses-frontend.md` §3)은 근거 없음 — 다음 Tier-3에서 같은 A/B 전까지 표는 유지하되 "미검증" 표시.
- **같은 날 Tier-2 #1 실측의 한계**: 본체가 구현·테스트 작성·스크린샷을 전부 직접 해 sonnet/haiku 라우팅이 적용된 구간이 0이었다(서브에이전트 = 리뷰만). 라우팅 표는 "뺄 때만" 작동한다 — 결정 1·2는 유효하나 비용 절감은 **구현 위임 여부**에 달려 있음. Tier-2 #2 결과로 (a) 세션 opus + 판단 순간 fable / (b) 구현 task sonnet 위임 중 결정.
- **2026-08-21 Tier-2 ×2 모델별 분해**: fable 본체 78% / opus persona 13~16% / sonnet 6~8%. 서브에이전트 라우팅은 설계대로 작동(전부 합쳐 $7~10). ce-code-review 유무는 오차 범위. → 결정 1 개정. **다음**: 같은 스크래치에서 세션 opus로 Tier-2 1회 — blocker·버그 발견이 같고 비용 1/2 이하면 "채택".
- `references/model-routing.md` §4 재검토 조건.
