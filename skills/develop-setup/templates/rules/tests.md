---
paths: ["**/*.test.ts", "**/*.test.tsx", "**/*.browser.test.tsx", "e2e/**", ".maestro/**"]
---
# 테스트
- spec의 `#### Scenario` 1개 = 테스트 1개. 테스트 이름은 "WHEN … THEN …"
- 먼저 실패를 보여준다: 실패 출력 + 이유("기능 미구현"). import 오류·오타는 red가 아니다
- 계층: 로직·훅 → `*.test.ts(x)`(jsdom/node) · 인터랙션·레이아웃 → `*.browser.test.tsx`(Vitest Browser Mode) / RN은 RNTL · 플로우 → e2e 3~5개만
- 쿼리는 역할·라벨 우선, `userEvent`, 자동 재시도 expect. `setTimeout`/`waitForTimeout` 금지
- mock은 네트워크 경계(MSW `test/msw/handlers.ts`)에서만. 자식 컴포넌트·훅·store mock 금지. 브라우저 테스트에서 `vi.mock`과 MSW 혼용 금지
- `it.skip`/`.only`/`expect(true)`/빈 assertion 금지(린트가 막는다)
- 상세 루프와 예시: cgamja 플러그인 `references/tdd-frontend.md` (`/test-fe` 스킬이 적용)
