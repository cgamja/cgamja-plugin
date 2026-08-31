## Issue Convention

### 원칙

- 이슈 하나 = 작업 단위 하나 — PR 하나로 닫을 수 있는 크기로 쪼갠다
- 제목만 보고 무슨 일인지 알 수 있게 (`[feat] 로그인 화면 구현`, `[fix] 잔액 갱신 시 로딩 무한 루프`)
- 라벨: `feat` / `fix` / `refactor` / `chore` / `docs`
- 버그 이슈는 **재현 절차 없으면 안 닫힌 것** — 기대 동작 vs 실제 동작을 반드시 쓴다

### 본문 구성

- **배경/문제**: 왜 이 작업이 필요한가
- **할 일**: 체크박스로 완료 조건을 명시 (Definition of Done)
- **버그인 경우**: 재현 절차 · 기대 동작 · 실제 동작 · 환경

### 템플릿

[.github/ISSUE-TEMPLATE.md](../.github/ISSUE-TEMPLATE.md) 사용.
