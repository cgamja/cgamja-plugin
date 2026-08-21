# 0012 — 리뷰는 티어별 렌즈 목록, 렌즈 = persona = 새 컨텍스트 서브에이전트

- 상태: 제안(개정 2 — 2026-08-21 3런 후 절차 부피 축소)
- 날짜: 2026-08-21
- 관련: 0001(ce-code-review 스펙 경로 필수), 0010, 0011 · 표 원문 `references/review-lenses-frontend.md`

## 맥락
리뷰 절차가 "ce-code-review에 스펙 경로를 넘겨라 + 스타일 말고 정확성만"이라는 지시문 하나였다. 2026-08-21 두 번 연속 에이전트가 Agent 도구로 리뷰어를 즉석 제작했고, 그 리뷰어에는 docs/solutions 조회·보안·테스트 검사가 빠졌다. 또 접근성·플랫폼·계약 관점은 어느 리뷰에도 없었다. PR 리뷰(남의 PR)는 절차 자체가 없었다.

## 결정
1. 리뷰 관점을 **렌즈 L1~L7**로 명명하고 렌즈마다 persona 파일(`agents/reviewer-*.md`) 하나. 렌즈는 "보는 것 / 보지 않는 것"을 둘 다 적는다 — 스타일 지적은 어떤 렌즈에도 없다.
2. **티어가 렌즈 개수를 정한다**: Tier-1 L1 / Tier-2 L1 L2 L3 + UI면 L4 L5 + API면 L6 / Tier-3·PR 전부. 조건부 렌즈는 diff에 `*.tsx`·스크린샷이 있는지, `src/api`·`openapi.yaml`이 바뀌었는지로 기계적으로 판정한다.
3. ~~`ce-code-review`는 대체가 아니라 병행~~ → **개정(2026-08-21)**: Tier-2는 **persona만**. `ce-code-review`는 Tier-3 통합·PR 모드에서 선택(docs/solutions·보안 관점이 필요할 때). 근거: 같은 날 Tier-2 두 번 — 병행 런에서 ce-code-review 고유 기여 2건(≈304k 토큰), persona-only 런에서 blocker 5·실제 버그 2를 놓치지 않음(`reports/develop-fe-tier2_2026-08-21_restructured.md`). 스펙 경로 필수 규칙(0001)과 훅의 bare 호출 거부는 유지.
4. 출력 계약 하나(§4 표). review-fe가 합치고 blocker 있으면 반영 후 **blocker를 낸 렌즈만** 재실행 1회까지.
6. **개정 2(비용)**: 3런 모두 리뷰 비용 ≥ 구현 비용(§5 조건 3회) → `/ce-simplify-code`는 Tier-2 선택 항목, persona 토큰 예산(diff+증거로 시작, 렌즈당 ≤50k, `review-lenses-frontend.md` §6). 렌즈 수·증거 상태 수는 줄이지 않는다 — L4/L5/L3가 실제 결함(뷰포트 누락, 판별 불가 테스트, WCAG 2.2.1)을 잡은 원천이다.
5. PR 리뷰 모드: 스펙이 없으므로 L2는 PR 본문의 What/Why를 스펙 대용으로. `--comment`로 PR에 쓰는 건 사용자 확인 후.

## 기각한 대안
- ce-code-review 하나에 지시문으로 렌즈 추가 — 한 컨텍스트에서 7관점은 서로 희석되고, 모델도 하나로 묶인다.
- Claude Code 내장 `/code-review` — 스펙 대조·FE 렌즈 없음. `ultra`는 비용·클라우드. PR 모드의 `--comment`만 빌려 쓴다.

## 검증
- 2026-08-21 Tier-2 ×2: 렌즈 선택 정확(UI/API 조건), L5가 뷰포트 누락을 잡음(#1), L3 변이 확인이 "판별 불가" 테스트 2건을 잡음(#2). 리뷰 비용은 persona 6개 ≈300k/회. 모델 A/B는 adr/0011.
- Tier-2 change 2개: persona 병렬 vs ce-code-review 단독의 지적 비교(`reports/`). 렌즈별 "없음" 빈도로 §5 재검토.
- PR 리뷰 1회(실제 GitHub PR).
