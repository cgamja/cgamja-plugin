# 프론트엔드 TDD — 게이트로서의 테스트 (`adr/0004`, `adr/0009`, `adr/0014`)

§0~§5는 스택 무관 원칙이다 — 절차(`test-fe`, `develop-fe`)는 여기만 참조한다. 계층의 실행 명령·파일 규약은 프로젝트 선언 `.claude/cgamja.json`의 `tests.layers`·`tests.patterns`에서 읽는다. §6은 특정 스택에서 **검증된 구현**(날짜 표기) — 세팅 스킬이 강제 수단이 없을 때 붙이는 조각이지 절차의 전제가 아니다.

## 0. 왜 하는가 — 솔직한 정의
통제 비교(Böckeler 2026)에서 에이전트가 자기 루프 안에서 red-green을 돌려도 **품질 차이는 없고 토큰은 3~8배**였다. 에이전트는 red를 건너뛰거나 위조한다. 그래서 여기서 TDD는 설계 기법이 아니라 **두 가지 통제 장치**다:
1. **실패하는 테스트 = 사람이 30초에 리뷰하는 스펙.** 구현 전에 "이게 맞는 기대냐"를 본다.
2. **커밋된, 구현자가 못 고치는 테스트 = 변조 방지.** ImpossibleBench: 테스트를 읽기전용으로 만들면 assertion 완화·skip·테스트 수정 치팅이 사라진다.

테스트는 spec의 `#### Scenario`를 실행 가능하게 옮긴 것이다. 시나리오 1개 = 테스트 1개가 기본(Converge 그룹이 이걸 대조한다).

## 1. 시나리오 → 계층 결정표 (계층 하나만 고른다)
| 시나리오가 다루는 것 | 계층(`tests.layers` 키) | 판단 기준 |
|---|---|---|
| 순수 로직(계산·변환·검증·리듀서), 훅/스토어의 상태 전이, 렌더 후 텍스트 확인만 | `unit` | DOM API·레이아웃이 결과에 영향 없음 |
| **사용자 인터랙션, 포커스, 포인터, 레이아웃, 브라우저 API, 반응형** | `browser` | 실제 브라우저 엔진이 있어야 참/거짓이 갈림. 프로젝트에 `browser` 계층이 없으면(`null`) `unit`+DOM 시뮬레이션으로 내리고 **레이아웃·포커스 시나리오는 E2E나 스크린샷 증거로** 보낸다 |
| 네트워크가 끼는 컴포넌트 | 위 둘 중 하나 + 경계 mock(`mock.boundary`) | 핸들러 한 벌을 모든 계층이 공유 |
| 여러 화면을 건너는 플로우 | `e2e` | 3~5개 고정 목록에 있을 때만 |
| 시각(색·간격) | 스크린샷 | 픽셀 비교는 디자인시스템 프리미티브만(CI에서만 유효), 화면은 디자인 원천 대조(`figma-design-source.md` §6) |

- **E2E는 3~5개, 이름을 정해둔다**: 진입(가입/로그인) · 핵심 동작 · 결제(돈이 움직이면) · 파괴적/설정 플로우 1개. 회귀가 새어나갔을 때만 추가, 고친 뒤 2번 flaky하면 삭제. 고정 시간 대기 금지.
- 브라우저 계층은 CI에서 깨지기 쉽다(메모리, iframe 행). **반드시**: 별도 CI job, 브라우저 바이너리 캐시, retry 1, 파일 많으면 shard. 그래도 flaky하면 그 테스트만 `unit`으로 내린다 — 끄지 않는다.
- 스토리북류 카탈로그가 이미 있으면 같은 시나리오를 테스트에 중복하지 않는다. 없으면 **테스트 목적만으로 도입하지 않는다**.

## 2. 루프 (task 하나 = 이 루프 한 번) — 사람 게이트 + 훅이 핵심
```
1. 시나리오를 테스트 이름으로: "WHEN 빈 이메일로 제출 THEN '이메일을 입력하세요'가 보이고 요청은 가지 않는다"
2. 테스트 작성. 껍데기(빈 export)만 만들어 import는 통과시킨다
3. 실행 → 실패 출력을 **그대로 붙여넣고, 왜 실패했는지 한 줄**: "요소 없음 — 기능 미구현" (import 에러·오타면 진짜 red가 아님, 2로)
4. 사람이 읽고 커밋: test(scope): <시나리오>        ← 여기가 리뷰 게이트
5. 구현 턴: 테스트 파일(`tests.patterns`)은 읽기전용(훅이 막는다). 통과할 만큼만
6. 실행 → 초록 + 기존 전부 초록(PASS_TO_PASS). 커밋: feat(scope): ...
7. 리팩터 → 다시 초록
```
- 3번 없으면 TDD가 아니다. tasks.md 테스트 task에 `→ verify: 실패 출력 + 이유`를 적는다.
- 구현 중 테스트를 고쳐야 하면 **새 red 턴**: 이유 한 줄 + 별도 `test()` 커밋. `feat` diff에 테스트 파일이 섞이면 리뷰어가 거부.
- 무인 실행이면 4번 "커밋"을 "stage + 훅이 staged 테스트 편집 차단"으로 대체.

## 3. 쿼리·mock 규칙
- 쿼리: 역할(role) > 라벨 > placeholder > 텍스트 > test-id(최후, 이유 주석). 역할로 못 찾으면 접근성이 깨진 것 — 마크업을 고친다. (Testing Library 계열 공통 규칙; 다른 러너면 동등한 "보조기기가 보는 방식" 쿼리를 쓴다)
- 비동기: 자동 재시도 assertion. 고정 `setTimeout` 금지
- **mock은 네트워크 경계(`mock.boundary`)에서만.** 핸들러 한 벌을 모든 계층이 공유하고, 계약 밖 요청은 **에러**(조용히 통과 금지). 브라우저 계층에서 모듈 mock과 경계 mock **혼용 금지**. E2E는 경계 mock 또는 브라우저 라우트 가로채기 중 하나만.
- **핸들러는 계약 생성물**이 제공하면 그것을 기본으로, 시나리오별 빈/에러 상태는 테스트 안에서 override. 손으로 쓰는 핸들러는 계약 타입으로 shape를 맞춘다(`api-contract.md` §4)
- 자식 컴포넌트·훅·프레임워크 내부·store mock 금지. mock 3개 넘으면 컴포넌트 분리 신호
- 검증은 렌더 결과로. "핸들러가 호출됐다"는 mutation의 요청 본문 확인에만
- 테스트 데이터는 팩토리 한 곳(`test/factories/` 류), 계약 타입으로 shape 고정

## 4. 에이전트 특유의 실패 → 기계로 막는다
| 증상 | 대응 |
|---|---|
| 테스트+구현 한 턴, "통과합니다" | red 출력 없으면 되돌리고 2~3부터. `Stop` 훅: `commands.verify` |
| assertion 완화, `skip`, `.only`, `expect(true)` | `PreToolUse` 훅: `tests.patterns` Edit는 **`ask`** — 사람이 diff를 보고 승인하는 것이 red 게이트(adr/0009). `TDD_PHASE=red`는 사람이 세션을 띄울 때만 주는 우회 키; 에이전트의 인라인 `TDD_PHASE=`와 쉘 쓰기(`sed -i`/`perl -pi`/리다이렉트)는 Bash 훅이 deny(2026-08-21 실측 우회 사례); 비대화형에서 ask가 거부되면 **구현으로 넘어가지 말고 멈춘다**; skip/only/`expect(true)`/소스 모듈 mock은 리뷰어가 거부 |
| 못 실패하는 assertion(존재 확인만, mock 값 그대로 기대) | 러너의 린트 규칙(`expect-expect`·`no-disabled-tests`·`no-focused-tests` 상당) — PostToolUse, 밀리초 |
| 약하지만 실행되는 assertion | 변이 테스트(§5)만 잡는다 |
| 모듈 mock 남발 | 리뷰어 지시에 "mock 수·대상" 포함 |
| 리뷰어가 자기 코드 채점 | **새 컨텍스트** 리뷰어: diff+시나리오만 주고 "각 assertion이 명백히 틀린 구현을 구분하는가?" 정확성 갭만 보고 |
| 고정 시간 대기 | 로케이터 자동 대기 |
| E2E에서 실제 OAuth | 저장된 인증 상태 픽스처 |

## 5. 변이 테스트
- 순수 로직 디렉터리(`domains.root/**/model/**` 상당)만, 증분 실행, 주 1회 또는 model 변경 PR. 살아남은 변이는 게이트가 아니라 리뷰 입력; 점수가 안정되면 break 임계를 현재치 바로 아래에.
- 매 턴 정적 게이트(§4 표)가 흔한 실패(assertion 없음, 동어반복)를 대신 잡는다.

## 6. 검증된 구현 — React + Vite (Vitest 4 · MSW 2.15 · Playwright 1.62, 2026-08-21 스크래치)
세팅 스킬이 `tests.layers`가 비어 있는 React 프로젝트에 붙일 때 쓰는 조각. 다른 스택은 같은 원칙으로 조사·실측 후 여기에 절을 추가한다.
- 계층 매핑: `unit` = Vitest jsdom(`*.test.ts(x)`, RTL `render`) / `browser` = **Vitest Browser Mode**(`@vitest/browser-playwright`, **Chromium만** — `vi.mock`+서비스워커 수정이 Chromium만) + `vitest-browser-react`, `page.getByRole`, `userEvent` from `vitest/browser`, `await expect.element(...)` (`*.browser.test.tsx`) / `e2e` = Playwright(+`@axe-core/playwright`, `e2e/*.spec.ts`).
- 인터랙션 기본값이 jsdom이 아닌 이유: Vitest 4 Browser Mode 안정화, RTL 저자 본인이 jsdom 불사용 선언, `@testing-library/user-event` 메인테이너 "새 브라우저 테스트엔 쓰지 말라"(2026-08), jsdom은 유지보수 모드. **Playwright Component Testing은 쓰지 않는다** — `@playwright/experimental-ct-*` 2026-08 삭제, 후속 미정착.
- 경계 mock = MSW: 한 `test/msw/handlers.ts`를 세 층이 공유 — jsdom `setupServer` / browser `setupWorker`를 test-context fixture(`auto: true`)로 / E2E `@msw/playwright` `createNetworkFixture` 또는 `page.route` 중 하나 + `serviceWorkers: 'block'`. `onUnhandledRequest: "error"`. 핸들러 기본은 orval 생성 `get<Title>Mock()`, 시나리오별 `server.use(getXxxMockHandler(override))`.
- 설정: `vitest.config.ts` `projects: [{name:"unit", environment:"jsdom", include:["**/*.test.ts?(x)"], exclude:["**/*.browser.test.tsx"]}, {name:"browser", browser:{enabled:true, provider:playwright(), instances:[{browser:"chromium"}]}, include:["**/*.browser.test.tsx"], optimizeDeps:{include:[...]}}]` (`optimizeDeps.include` 없으면 CI flaky) · `playwright.config.ts` chromium 1개, `storageState` 픽스처 · 린트 `@vitest/eslint-plugin` `expect-expect`·`no-disabled-tests`·`no-focused-tests` + `captain-obvious --check`.
- 변이: Stryker는 Browser Mode 미지원 → jsdom 프로젝트의 `src/domains/**/model/**`만, `incremental: true`, `coverageAnalysis: perTest`.
- Storybook이 이미 있으면 `@storybook/addon-vitest`로 스토리를 돌린다. 없으면 `vitest-browser-react` + `vitest-axe`로 동일 커버.
- Expo(RN): 브라우저가 없으므로 `browser` 계층 없음 → `jest-expo` + `@testing-library/react-native` 한 층(`unit`)에 인터랙션까지, 레이아웃 픽셀은 시뮬레이터 스크린샷. MSW는 `setupServer`(Node). E2E는 Maestro. (`develop-setup/templates/react/jest.expo.md`)
- 예시(브라우저 계층, spec → 테스트):
```
#### Scenario: 빈 이메일 제출
- **WHEN** 사용자가 이메일을 비우고 "구독"을 누른다
- **THEN** 입력 아래에 "이메일을 입력하세요"가 보이고, 서버 요청은 발생하지 않는다
```
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
첫 실행 `Cannot find element with role "button"` — 기능 미구현, 진짜 red → `test(subscribe): 빈 이메일 제출 시나리오` 커밋 → 구현 → `feat(subscribe): 이메일 필수 검증`.
