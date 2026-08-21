# 0004. TDD는 품질 기법이 아니라 리뷰 게이트 + 변조 방지; 인터랙션 테스트 기본은 Vitest Browser Mode
- 상태: 제안
- 날짜: 2026-08-21
- 검증: (없음)

## 맥락
`references/verdicts-2026-08-21.md` ②. 통제 비교(Böckeler 2026)에서 에이전트 자체 red-green 루프는 품질 차이 없이 토큰 3~8.5배. 에이전트는 red를 건너뛰거나 위조하고(ImpossibleBench: 쓰기 가능한 테스트에서 치팅 최대 76%, 읽기전용이면 제거), 사람보다 mock을 많이 쓴다(36% vs 26%). 한편 Vitest 4 Browser Mode 안정화, RTL 저자·user-event 메인테이너가 jsdom/user-event 이탈 권고(2026), `@playwright/experimental-ct-*` 삭제(2026-08).

## 결정
1. TDD의 목적을 "① 실패 테스트 = 사람이 리뷰하는 스펙 ② 커밋된 읽기전용 테스트 = 변조 방지"로 정의한다. 품질 향상은 주장하지 않는다.
2. red 단계는 요청이 아니라 **메커니즘**: 실패 출력+이유 제시 → 사람이 `test()` 커밋 → 구현 턴은 PreToolUse 훅으로 `*.test.*` 읽기전용 → `feat()` diff에 테스트 파일 없음을 리뷰어가 확인.
3. 계층: 순수 로직·훅·텍스트 확인 = jsdom(`*.test.ts(x)`); **인터랙션·레이아웃·포커스·반응형 = Vitest Browser Mode chromium**(`*.browser.test.tsx`, `vitest-browser-react`, `vitest/browser`의 userEvent). 브라우저 프로젝트는 별도 CI job·retry 1·shard.
4. E2E 3~5개 이름 지정. Playwright CT 사용 금지. Storybook은 있을 때만 addon-vitest로.
5. MSW 단일 `handlers.ts`를 세 층 공유, Chromium 전용, `vi.mock`과 혼용 금지.
6. 매 턴 정적 게이트(`eslint-plugin-vitest` + captain-obvious), Stryker는 node 프로젝트 `model/**`만 주간.

## 전제
- 사람이 테스트 커밋을 실제로 읽는다(30초). 무인 모드면 "stage + 훅"으로 대체.
- Chromium 하나로 충분한 제품(크로스브라우저 요구 없음).
- 브라우저 테스트 CI 비용을 감수한다(2코어 러너에서 shard 필요).

## 재검토 조건
- 브라우저 프로젝트가 CI에서 주 2회 이상 flaky → jsdom 기본으로 되돌리고 브라우저는 레이아웃 시나리오만.
- 사람이 테스트 커밋을 안 읽고 승인하는 습관 → 게이트 가치 소멸 → 정적 게이트+리뷰어만 남기고 커밋 분리 완화.
- Böckeler가 검증 안 한 "사람 체크포인트 변형"이 측정되어 반대 결과 → 재평가.
- Playwright story-gallery CT가 안정화 → 비교 재검토.

## 결과 / 영향
- tasks.md 테스트 task에 "실패 출력+이유" 증거 요구. 커밋 수 2배(test/feat).
- 훅 2개 추가(테스트 파일 보호, 정적 게이트). `tdd-frontend.md` 전면 개정.
