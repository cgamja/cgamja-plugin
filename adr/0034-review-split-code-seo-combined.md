# ADR 0034 — 리뷰를 셋으로: review-code · review-seo · review-cgamja(종합)

- 상태: 제안 (2026-09-16)
- 관련: adr/0026(리뷰 2축), adr/0011(모델 라우팅 — 리뷰는 opus), adr/0013(스킬 검증 피라미드)

## 맥락

2026-09-16 랜딩 레포(`simsimeestudio-intro`, SEO 최우선 선언)에서 배포 전 점검을 하며 두 종류의 리뷰가 한 세션에 같이 돌았다.

1. 철학 리뷰(`reviewer-cgamja`) — should 6건: 시간표 매직 넘버, reduced-motion 경로 혼합, 물건 전용 상수의 shared 모듈 배치, 커밋 제목 규칙.
2. SEO 감사 — claude-seo 플러그인의 에이전트 넷(technical·schema·geo·performance)을 병렬로 돌려 본문 64%가 정적 HTML에 `opacity:0`으로 실리는 것, 손글씨 문장 중복, 폰트 프리로드 91개, 404·빈 글의 메타 상속을 찾았다.

둘은 **같은 파일**(애니메이션 컴포넌트)을 다른 이유로 가리켰고, 한 번에 고쳐야 두 판정을 다 만족하는 구조가 나왔다(마운트 게이트 + reduce 얼리 리턴). 따로 돌리면 두 번 고치고 두 번 검증한다.

또 하나 배운 것: claude-seo 렌즈는 **고정 목록이 아니다.** 스키마만 볼 때 여섯 개를 돌리면 합치는 비용만 든다. 반대로 SEO 최우선 프로젝트의 첫 감사에는 넷이 기본이다. 고르는 기준이 스킬에 있어야 한다.

## 결정

1. **`review-code`** — 철학(reviewer-cgamja) + 정확성(있으면 `cgamja-private:code-review-opus`, 없으면 `reviewer-correctness`) 두 축을 한 메시지에 스폰하고, 위반 수정 → 철학 재검사 1회 → 검증 명령 1회. 기존 `review-cgamja`의 철학 게이트 절차를 여기로 옮긴다.
2. **`review-seo`** — 빌드 결과를 로컬로 띄운 URL을 감사 대상으로 만들고(`references/agent-picker.md`의 표로 렌즈 선택), 보고를 세 통(코드로 고침 / 팀 판정 / 사이트 밖)으로 합쳐 고친 뒤 `scripts/inspect_html.py` 숫자로 전후를 비교한다. 사실을 지어내지 않는다(null이면 그리지 않는 규칙 우선).
3. **`review-cgamja`** — 두 스킬의 오케스트레이터. 한 메시지에 전부 스폰, 겹치는 파일은 한 번에 수정, 축마다 재검사 1회, 검증·커밋·보고 한 번. SEO 축은 공개 페이지에 닿은 변경일 때만 켠다.

## 따라오는 것

- `develop-fe`·`develop-baby-fe`의 "리뷰 2축(review-cgamja + code-review)"은 이 ADR로 의미가 바뀐다 — review-cgamja가 종합판이 되면서 페이지 변경 시 SEO 축이 켜질 수 있다. 워크플로우 안에서는 `review-code`를 부르도록 바꾸는 것이 맞고, 이는 후속 change(0026 개정)로 둔다. 이번 ADR은 스킬 셋을 두는 것까지.
- 사용자 레벨 `~/.claude/skills/review-*`는 이 레포의 `skills/review-*`를 가리키는 심링크(adr/0033 — 복사본을 두지 않는다).
- 세 스킬의 `evals/evals.json`은 프롬프트만 있다(adr/0013 3층). 행동 eval은 비용(에이전트 5~6개·40만 토큰)이 커서 사용자가 실행을 정한다.

## 재검토 조건

- claude-seo 플러그인의 에이전트 이름·범위가 바뀌면 `agent-picker.md` 개정.
- 종합 리뷰를 3회 돌린 뒤 "두 축이 같은 파일을 가리킨 비율"이 낮으면 오케스트레이터 대신 순차 호출로 되돌린다.
