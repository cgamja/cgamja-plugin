# conventions — 이유와 예시 (규칙 자체는 `.claude/rules/`와 린트에 있다; 여기는 "왜"와 정본 파일 포인터)

> 이 문서는 `@`로 CLAUDE.md에 불러오지 않는다. 필요할 때 읽는다. 규칙을 여기에 **추가로** 쓰지 않는다 — 린트나 `.claude/rules/`에 쓰고 여기엔 이유만.

## 네이밍
- 컴포넌트 파일명 = 컴포넌트명: 에이전트가 grep으로 재사용 대상을 찾는 유일한 경로라서. `index.tsx` 컴포넌트 금지
- 정본: `src/shared/ui/button/Button.tsx`

## 상태 위치
- 로컬 → context → 서버({{SERVER_STATE}}) → URL({{URL_STATE}}). 순서를 건너뛰어 전역 store로 가면 "같은 진실 두 곳"이 생긴다(에이전트 코드베이스 2위 실패)
- 정본: `src/domains/{{FIRST_DOMAIN}}/model/`

## 컴포넌트 분리
- 200줄/책임 2개/props 7개 — 숫자는 임의지만 에이전트에게 "언제"가 없으면 분리하지 않는다. 의심되면 `.browser.test.tsx`에서 시나리오가 2개 이상 섞이는지로 판단

## 에러 처리
- `api/`에서 정규화해 `ui/`가 분기하지 않게. 빈·로딩·에러 상태 기본 포함 — Figma에 없어도(에이전트 UI 누락 1위)

## 스타일
- 토큰만, 임의값 금지, 반응형 {{VIEWPORTS}}. Figma 토큰 파이프라인: `design/tokens.json` → `{{TOKENS_PATH}}`

## 테스트 / 커밋
- `references/tdd-frontend.md`(cgamja 플러그인). TDD는 품질 기법이 아니라 **리뷰 게이트 + 변조 방지** — 실패 테스트를 사람이 보고 커밋한 뒤 구현
- `type(scope): 요약`. 테스트 커밋과 구현 커밋 분리(테스트 약화가 diff에 보이게)

## 이 문서의 rot 방지
CI `scripts/check-docs.sh`가 여기·CLAUDE.md·rules가 가리키는 경로와 명령이 존재하는지 검사한다. 깨지면 문서를 고치거나 지운다.
