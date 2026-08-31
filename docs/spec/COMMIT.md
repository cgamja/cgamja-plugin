## Commit Convention

- 형식: Conventional Commits (AngularJS 컨벤션 계열)
- 제목·본문은 **한국어**

### 형식

```
<type>(<scope>): <제목>

<본문 — 선택>
```

- type: `feat` / `fix` / `refactor` / `test` / `chore` / `docs` / `style` / `perf`
- scope는 feature 디렉토리명 기준 (예: `feat(login): ...`) — 선택
- 제목: 50자 이내, 명사형 종결 ("~구현", "~수정"), 마침표 없이
- 본문: 한 줄 72자에서 줄바꿈. **"무엇"은 diff가 보여주니 "왜"를 쓴다** (주석·PR 철학과 동일). 제목으로 충분하면 본문 생략

### 원칙

- 커밋 하나 = 의도 하나 (기능 추가와 리팩토링을 한 커밋에 섞지 않는다)
- 테스트는 `test:`로 구현 커밋과 분리
