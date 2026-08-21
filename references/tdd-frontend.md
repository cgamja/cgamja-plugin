# 프론트엔드 TDD — 실제로 어떻게 하나 (2026-08-21 재검증 반영, `adr/0004`)

## 0. 왜 하는가 — 솔직한 정의
통제 비교(Böckeler 2026)에서 에이전트가 자기 루프 안에서 red-green을 돌려도 **품질 차이는 없고 토큰은 3~8배**였다. 에이전트는 red를 건너뛰거나 위조한다. 그래서 여기서 TDD는 설계 기법이 아니라 **두 가지 통제 장치**다:
1. **실패하는 테스트 = 사람이 30초에 리뷰하는 스펙.** 구현 전에 "이게 맞는 기대냐"를 본다.
2. **커밋된, 구현자가 못 고치는 테스트 = 변조 방지.** ImpossibleBench: 테스트를 읽기전용으로 만들면 assertion 완화·skip·테스트 수정 치팅이 사라진다.

테스트는 spec의 `#### Scenario`를 실행 가능하게 옮긴 것이다. 시나리오 1개 = 테스트 1개가 기본(Converge 그룹이 이걸 대조한다).

## 1. 시나리오 → 계층 결정표 (계층 하나만 고른다)
| 시나리오가 다루는 것 | 계층 | 도구 | 파일명 |
|---|---|---|---|
| 순수 로직(계산·변환·검증·리듀서), 훅의 상태 전이, 렌더 후 텍스트 확인만 | node/jsdom | Vitest + (필요시) RTL `render` | `*.test.ts(x)` |
| **사용자 인터랙션, 포커스, 포인터, 레이아웃, 브라우저 API, 반응형** | **브라우저** | Vitest Browser Mode(`@vitest/browser-playwright`, chromium만) + `vitest-browser-react`, `page.getByRole`, `userEvent` from `vitest/browser`, `await expect.element(...)` | `*.browser.test.tsx` |
| 네트워크가 끼는 컴포넌트 | 위 둘 중 하나 + MSW | 한 `handlers.ts` 공유 | — |
| 여러 화면을 건너는 플로우 | E2E | Playwright (+ `@axe-core/playwright`) | `e2e/*.spec.ts` |
| 시각(색·간격) | 스크린샷 | `toMatchScreenshot`은 디자인시스템 프리미티브만(CI에서만 유효), 화면은 Figma 대조(`figma-design-source.md` §6) | — |

- 인터랙션 기본값이 jsdom이 아닌 이유: Vitest 4 Browser Mode 안정화, RTL 저자 본인이 jsdom 불사용 선언, `@testing-library/user-event` 메인테이너가 "새 브라우저 테스트엔 쓰지 말라"(2026-08), jsdom은 유지보수 모드.
- 브라우저 프로젝트는 CI에서 깨지기 쉽다(Chromium 메모리 누수, iframe 행). **반드시**: 별도 CI job, Playwright 바이너리 캐시, `retry: 1`, 프로젝트 config 안에 `optimizeDeps.include`, 50파일 넘으면 `--shard`. 그래도 flaky하면 그 테스트만 jsdom+RTL로 내린다 — 끄지 않는다.
- **E2E는 3~5개, 이름을 정해둔다**: 진입(가입/로그인) · 핵심 동작 · 결제(돈이 움직이면) · 파괴적/설정 플로우 1개. 회귀가 새어나갔을 때만 추가, 고친 뒤 2번 flaky하면 삭제. `waitForTimeout` 금지.
- **Playwright Component Testing은 쓰지 않는다** — `@playwright/experimental-ct-*`는 2026-08 삭제됐고 후속(story gallery)은 미정착. 컴포넌트 브라우저 테스트는 Vitest Browser Mode.
- Storybook: 이미 있으면 `@storybook/addon-vitest`로 스토리를 돌리고 같은 시나리오를 `*.browser.test.tsx`에 중복하지 않는다. 없으면 **테스트 목적만으로 도입하지 않는다**(`vitest-browser-react` + `vitest-axe`로 동일 커버, 설정면 하나).

## 2. 루프 (task 하나 = 이 루프 한 번) — 사람 게이트 + 훅이 핵심
```
1. 시나리오를 테스트 이름으로: it("WHEN 빈 이메일로 제출 THEN '이메일을 입력하세요'가 보이고 요청은 가지 않는다")
2. 테스트 작성. 껍데기(빈 export)만 만들어 import는 통과시킨다
3. 실행 → 실패 출력을 **그대로 붙여넣고, 왜 실패했는지 한 줄**: "요소 없음 — 기능 미구현" (import 에러·오타면 진짜 red가 아님, 2로)
4. 사람이 읽고 커밋: test(scope): <시나리오>        ← 여기가 리뷰 게이트
5. 구현 턴: 테스트 파일은 읽기전용(훅이 막는다). 통과할 만큼만
6. 실행 → 초록 + 기존 전부 초록(PASS_TO_PASS). 커밋: feat(scope): ...
7. 리팩터 → 다시 초록
```
- 3번 없으면 TDD가 아니다. tasks.md 테스트 task에 `→ verify: 실패 출력 + 이유`를 적는다.
- 구현 중 테스트를 고쳐야 하면 **새 red 턴**: 이유 한 줄 + 별도 `test()` 커밋. `feat` diff에 `*.test.*`가 섞이면 리뷰어가 거부.
- 무인 실행이면 4번 "커밋"을 "stage + 훅이 staged 테스트 편집 차단"으로 대체.

## 3. 쿼리·mock 규칙
- 쿼리: `getByRole` > `getByLabelText` > `getByPlaceholderText` > `getByText` > `getByTestId`(최후). 역할로 못 찾으면 접근성이 깨진 것 — 마크업을 고친다
- 브라우저 프로젝트: `toBeVisible`, `expect.element`. `toBeInTheDocument`류는 jsdom에서만
- 비동기: `findBy*`/`waitFor`/자동 재시도 expect. `setTimeout` 금지
- **mock은 네트워크 경계(MSW)에서만.** 한 `handlers.ts`를 세 층이 공유: jsdom `setupServer` / browser `setupWorker`를 test-context fixture(`auto: true`)로 / E2E `@msw/playwright` `createNetworkFixture`. 규칙: 브라우저 테스트에서 API 클라이언트 모듈 `vi.mock`과 MSW **혼용 금지**; 브라우저는 Chromium 전용(vi.mock+서비스워커 수정이 Chromium만); E2E는 `@msw/playwright` 또는 `page.route` 중 하나만 + `serviceWorkers: 'block'`
- **핸들러는 생성물**(orval `get<Title>Mock()`)을 기본으로 `setupServer`에 넣고, 시나리오별 빈/에러 상태는 테스트 안 `server.use(getXxxMockHandler(override))`로. 손으로 쓰는 핸들러는 생성 타입으로 타입을 맞춘다. `onUnhandledRequest: "error"` — 계약 밖 호출은 throw(`api-contract.md` §4)
- 자식 컴포넌트·훅·React 내부·store mock 금지. mock 3개 넘으면 컴포넌트 분리 신호
- 검증은 렌더 결과로. "핸들러가 호출됐다"는 mutation의 요청 본문 확인에만
- 테스트 데이터는 `test/factories/`

## 4. 에이전트 특유의 실패 → 기계로 막는다
| 증상 | 대응 |
|---|---|
| 테스트+구현 한 턴, "통과합니다" | red 출력 없으면 되돌리고 2~3부터. `Stop` 훅: `pnpm verify` |
| assertion 완화, `skip`, `.only`, `expect(true)` | `PreToolUse` 훅: `*.test.*`/`*.stories.*`/`e2e/*.spec.ts` Edit는 **`ask`** — 사람이 diff를 보고 승인하는 것이 red 게이트(adr/0009). `TDD_PHASE=red`는 사람이 세션을 띄울 때만 주는 우회 키; 에이전트의 인라인 `TDD_PHASE=`와 `sed -i`/`perl -pi`/`>`로 테스트 파일 쓰기는 Bash 훅이 deny(2026-08-21 실측 우회 사례); 비대화형에서 ask가 거부되면 **구현으로 넘어가지 말고 멈춘다**; `it.skip`/`.only`/`expect(true)`/`vi.mock("src/**")`(api 제외) 거부 |
| 못 실패하는 assertion(`toBeDefined`, mock 값 그대로 기대) | `eslint-plugin-vitest` `expect-expect`·`no-disabled-tests`·`no-focused-tests` error + `captain-obvious --check`(또는 `eslint-plugin-test-signal`) — PostToolUse, 밀리초 |
| 약하지만 실행되는 assertion | Stryker(§5)만 잡는다 |
| `vi.mock("../Child")` 남발 | 리뷰어 지시에 "mock 수·대상" 포함 |
| 리뷰어가 자기 코드 채점 | **새 컨텍스트** 리뷰어: diff+시나리오만 주고 "각 assertion이 명백히 틀린 구현을 구분하는가?" 정확성 갭만 보고 |
| `page.waitForTimeout` | 로케이터 자동 대기 |
| E2E에서 실제 OAuth | `storageState` |

## 5. 변이 테스트
- Stryker는 **Browser Mode 미지원** → node/jsdom 프로젝트의 `src/domains/**/model/**`만(강제된 범위). `incremental: true`, `coverageAnalysis: perTest`, 주 1회 또는 model 변경 PR. 살아남은 변이는 게이트가 아니라 리뷰 입력; 점수가 안정되면 `break`를 현재치 바로 아래에.
- 매 턴 정적 게이트(§4 표)가 흔한 실패(assertion 없음, 동어반복)를 대신 잡는다.

## 6. 예시 — spec 시나리오에서 테스트까지 (브라우저 프로젝트)
spec:
```
#### Scenario: 빈 이메일 제출
- **WHEN** 사용자가 이메일을 비우고 "구독"을 누른다
- **THEN** 입력 아래에 "이메일을 입력하세요"가 보이고, 서버 요청은 발생하지 않는다
```
tasks.md:
```
- [ ] 2.1 SubscribeForm 빈 이메일 시나리오 테스트 → verify: 실패 출력 + 이유, test() 커밋
- [ ] 2.2 SubscribeForm 빈 값 검증 구현 → verify: 2.1 초록 + PASS_TO_PASS, diff에 *.test.* 없음
```
`SubscribeForm.browser.test.tsx`:
```tsx
import { render } from "vitest-browser-react";
import { page, userEvent } from "vitest/browser";
import { http, HttpResponse } from "msw";
import { test, expect } from "@/test/browser"; // worker fixture(auto: true) 확장
import { SubscribeForm } from "./SubscribeForm";

test("WHEN 빈 이메일로 제출 THEN 오류 문구가 보이고 요청은 가지 않는다", async ({ worker }) => {
  const calls: Request[] = [];
  worker.use(http.post("/api/subscribe", ({ request }) => { calls.push(request); return HttpResponse.json({}); }));
  render(<SubscribeForm />);

  await userEvent.click(page.getByRole("button", { name: "구독" }));

  await expect.element(page.getByText("이메일을 입력하세요")).toBeVisible();
  expect(calls).toHaveLength(0);
});
```
첫 실행: `Cannot find element with role "button"` — 기능 미구현, 진짜 red → `test(subscribe): 빈 이메일 제출 시나리오` 커밋 → 구현 → `feat(subscribe): 이메일 필수 검증`.

## 7. 프로젝트 설정 (`[TODO]`, 시작 시 1회)
- `vitest.config.ts`: `projects: [{ name: "unit", environment: "jsdom", include: ["**/*.test.ts?(x)"], exclude: ["**/*.browser.test.tsx"] }, { name: "browser", browser: { enabled: true, provider: playwright(), instances: [{ browser: "chromium" }] }, include: ["**/*.browser.test.tsx"], optimizeDeps: { include: [...] } }]`
- `test/msw/handlers.ts` + `test/msw/server.ts`(node) + `test/browser.ts`(worker fixture) + `test/factories/`
- `playwright.config.ts`: chromium 1개, `storageState` 픽스처, `@axe-core/playwright`, `serviceWorkers: 'block'`
- `package.json` `verify`: `tsc --noEmit && eslint . && vitest run && knip` (전체 진실, Stop 훅·CI·CLAUDE.md가 이 이름만 참조)
- 훅: `PostToolUse(*.test.*)` → eslint-plugin-vitest + captain-obvious / `PreToolUse` 테스트 파일 보호 / `Stop` → `pnpm verify` (코드 편집한 턴만, `stop_hook_active` 가드, 실패 시 exit 2 + 마지막 50줄)
- CI: unit → browser(별도 job, shard) → playwright 스모크 → (주간) Stryker
