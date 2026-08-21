---
paths: ["src/domains/**/model/**", "src/domains/**/api/**"]
---
# 상태·데이터
- 위치: 로컬 `useState` → 공유 UI는 context → 서버 상태는 {{SERVER_STATE}} → URL 상태는 {{URL_STATE}}. **같은 진실을 두 곳에 두지 않는다**
- `api/`에서 응답·에러를 정규화(스키마 검증 포함). `ui/`는 성공·빈·로딩·에러 상태만 렌더
- 도메인 밖으로 나가는 타입·훅만 `index.ts`에 named export. `export *` 금지
- `model/**`은 순수 로직 위주 — 테스트 밀도가 가장 높은 곳(변이 테스트 대상)
