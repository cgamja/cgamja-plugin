# ADR 0037 — 버그 리뷰 축은 세션 모델과 무관하게 Opus로 돈다

- 상태: 제안 (2026-09-22)
- 관련: adr/0026 §3(리뷰 2축), adr/0031(reviewer는 스킬 경유), adr/0035(축 동시 실행), 강룡 결정 2026-09-09

## 문제

리뷰 2축의 ②(버그·회귀·재사용·단순화)는 내장 `/code-review` 스킬이었다. 이 스킬은 **fork로 실행돼 세션 모델을 물려받는다** — 모델을 지정할 수 없다. Fable 세션에서 부르면 리뷰가 Fable로 돌고, 리뷰는 Opus/Sonnet으로만 돌리기로 한 결정(2026-09-09)과 어긋난다. 작성자와 검증자를 분리한다는 v2의 다섯 동작(SKILL.md) 중 하나가 모델 층위에서 조용히 무너진다.

`review_nudge.sh`는 description에 "review"가 든 Agent 호출마다 "스킬로 대체하라"를 붙였다. 모델을 고정하려면 Agent 도구로 에이전트를 띄워야 하는데, 그 호출이 이 훅에 걸린다 — 훅이 올바른 경로를 넛지했다.

## 결정

1. 리뷰 ②축은 `code-review-opus` 에이전트(`model: opus` frontmatter, 읽기 전용)를 **Agent 도구로** 띄운다. 현재 위치는 `cgamja-private:code-review-opus`.
2. 에이전트가 없는 환경(플러그인 미설치)에서만 내장 `/code-review`로 대신하고, **그렇게 했다고 판정 줄에 말한다**.
3. `review_nudge.sh`는 `code-review-opus`를 항상 통과시킨다(`reviewer-correctness`와 같은 갈래).

레벨(Tier-1 low · Tier-2 medium), 동시 실행(adr/0035), 수정 패스 1번·재검사 1회(adr/0019)는 그대로다. 축의 내용은 바뀌지 않는다 — 실행 주체의 모델만 고정한다.

## 버린 대안

- **세션을 Opus로 열기**: 리뷰 하나 때문에 세션 전체 모델을 정하는 것은 거꾸로다. 세션 모델은 작업이 정한다.
- **`/code-review`에 모델 인자를 기다리기**: 내장 스킬의 fork 구조는 우리가 바꿀 수 없고, 기다리는 동안 리뷰가 Fable로 돈다.
- **reviewer-correctness(L1 렌즈)로 대체**: L1은 정확성·중복만 본다. `/code-review`가 보던 재사용·단순화·효율 정리가 빠진다.

## 비용

- 공개 플러그인이 비공개 플러그인의 에이전트를 가리킨다. 대체 규칙(결정 2)이 있어 남이 써도 깨지지 않지만, 에이전트 프롬프트에 care-app 전용 줄(금지 워딩 SPRINT-GOAL §3)이 섞여 있다. **이관 조건**: 에이전트를 이 레포 `agents/code-review-opus.md`로 옮기고 팀 전용 줄은 simsimee 오버레이 packet으로 뺀다 — 별도 change.
- 내장 `/code-review`의 신뢰도 스코어링·`--comment`·`ultra`는 잃는다. PR 코멘트 게시가 필요하면 사람이 붙인다.

## 강제

`hooks/review_nudge.sh` — `code-review-opus`는 통과, 그 외 리뷰 목적 Agent 호출은 2축(review-cgamja + code-review-opus)으로 넛지. `hooks/skill_guard.sh` 안내 문구 동일.

## 재검토 조건

- 이관 조건이 충족되면 결정 1의 위치를 `cgamja:code-review-opus`로 고치고 이 ADR에 개정 줄.
- 대체 경로(결정 2)가 실제로 탄 세션 2회 → 에이전트 이관을 앞당긴다.
- 내장 `/code-review`가 모델 지정을 지원하면 → 새 ADR로 되돌릴지 판단.
