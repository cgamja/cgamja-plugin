---
name: qa-cgamja
description: 크로스 플랫폼 비주얼 회귀 QA — 사용자의 행동 흐름을 검증하는 동작 스크립트(웹 Playwright / 앱 Maestro) 안에 비주얼 스냅샷 검증을 심는 기준과 규칙. 사용자가 "비주얼 회귀", "비주얼 QA", "스냅샷 테스트", "화면 깨졌는지 확인", "스크린샷 비교", "UI 회귀 테스트", "디자인이랑 맞는지 테스트"를 언급하거나, E2E 테스트에 시각 검증을 추가하려 하거나, Percy·Chromatic·비주얼 테스팅 도구를 검토할 때, 또는 /qa-cgamja 호출 시 반드시 사용한다. 피그마 디자인과 구현을 픽셀로 대조하려는 요청도 이 스킬이 받아서 회귀 비교 방식으로 유도한다.
---

# cgamja-qa — 비주얼 회귀 QA

**막으려는 문제**: 기능 assertion은 전부 통과하는데 시각적으로 깨진 회귀(밀린 레이아웃, 사라진 스타일, 깨진 다크모드)가 배포까지 새어나간다.

**핵심 설계**: 정적 페이지 스크린샷이 아니라 **동작 플로우 스크립트 안의 검증 시점에 스냅샷을 심는다.** 모달 열림·에러 상태·입력 중 상태는 로드 직후 스냅샷으로는 잡을 수 없다.

## 공통 원칙

1. **스냅샷은 THEN 시점에서만 찍는다.** 동작 assertion이 있는 곳(시나리오의 THEN)이 시각 검증도 의미 있는 곳이다. 클릭·입력마다 찍지 않는다 — 스냅샷 수가 늘수록 리뷰가 기계적으로 변해 오히려 회귀를 놓친다.
2. THEN 중에서도 **시각으로만 구분되는 상태를 우선한다**: 모달/바텀시트 열림, 에러·빈 상태, 다크모드, 반응형 분기. 텍스트 assertion으로 이미 잡히는 상태는 스냅샷이 중복이다.
3. **플로우당 스냅샷 상한을 정한다** (기본 5장). 넘치면 가장 시각적인 상태만 남긴다.
4. **피그마 API·디자인 링크를 실시간 파싱해서 픽셀을 비교하지 않는다.** 폰트 렌더링·안티앨리어싱·브라우저 차이로 노이즈만 나온다. 디자인 대조는 사람 리뷰의 몫이고, 스크립트의 몫은 "승인된 baseline 대비 회귀 감지"다. 사용자가 디자인-구현 픽셀 대조를 요청하면 이 이유를 설명하고 회귀 비교로 전환한다.
5. **셀렉터는 추론하지 않는다.** 코드를 읽고 실제 role·label·testID를 확인한다. 없으면 식별자 추가를 선행 작업으로 제안한다 — 지어낸 셀렉터는 flaky가 아니라 거짓 실패를 만든다. 우선순위는 role/접근성 label > 텍스트 > testID.

## 웹 — Playwright `toHaveScreenshot()`

Percy 같은 유료 SaaS를 기본값으로 쓰지 않는다(스냅샷 과금, $599/월~). 내장 `toHaveScreenshot()`이 마스킹·애니메이션 비활성·안정화 자동 재시도·pixelmatch diff를 전부 제공한다.

**결정론 규칙 — 이게 없으면 diff의 대부분이 거짓 양성이다:**

```ts
// playwright.config.ts
expect: {
  toHaveScreenshot: {
    animations: 'disabled',   // flaky 원인 1순위: 애니메이션 중간 프레임
    maxDiffPixelRatio: 0.01,  // 안티앨리어싱 오차만 허용
  },
},
use: { viewport: { width: 1280, height: 720 } }, // viewport 고정
```

```ts
// 테스트 안에서
await page.clock.setFixedTime(new Date('2026-01-01T00:00:00')); // 시간 고정
await page.evaluate(() => document.fonts.ready);                // 폰트 로딩 대기
await expect(page).toHaveScreenshot('checkout-error.png', {
  mask: [page.getByTestId('user-avatar')], // 런마다 바뀌는 건 전부 마스킹
});
```

- 네트워크 데이터는 고정 픽스처로 mock한다(MSW 또는 `page.route`) — 실데이터 스냅샷은 항상 깨진다.
- **고정 시간 대기(`waitForTimeout`) 금지.** 애니메이션·전환이 끝나길 기다려야 하면 상태 신호를 기다린다 — `toHaveScreenshot`의 자동 안정화 재시도, `transitionend`, 라이브러리의 "열림 완료" 클래스. 300ms 대기는 CI가 느린 날 flaky의 씨앗이 된다.
- **baseline은 CI(Playwright Docker 이미지)에서 생성한다.** 로컬 macOS와 CI Linux는 폰트 렌더링이 달라 로컬 baseline은 CI에서 무조건 깨진다. 로컬에서는 `--update-snapshots`를 CI와 같은 컨테이너로 돌린다.

## 앱 (RN / Expo) — Maestro `assertScreenshot`

`takeScreenshot`은 파일만 떨구는 촬영 명령이다 — 비교 주체가 없다. **검증에는 `assertScreenshot`(CLI v2.2.0+)을 쓴다**: baseline과 픽셀 비교하고 실패 시 diff 이미지를 생성한다.

```yaml
# flows/checkout.yaml
- launchApp
- tapOn:
    id: "checkout-button"      # 코드에서 확인한 실제 testID — 추론 금지
- assertVisible: "주문 확인"
- assertScreenshot:
    baseline: "checkout-confirm"
    thresholdPercentage: 95    # 차트 등 픽셀 민감 화면은 98~99
    cropOn:
      id: "order-summary"      # 동적 영역(시계·배터리·타임스탬프) 제외
```

- `takeScreenshot`은 baseline 최초 생성 시에만 쓴다.
- 시뮬레이터 기종·OS 버전을 고정하고, 상태바를 고정한다: `xcrun simctl status_bar <device> override --time "9:41"`.
- 애니메이션·전환 효과는 테스트 빌드에서 비활성화하고, 데이터는 mock 서버 고정 픽스처를 쓴다.

## Baseline 게이트 — 스냅샷은 첫 실행이 무조건 green이다

일반 테스트의 "red 먼저"가 성립하지 않으므로 별도 게이트를 둔다:

1. **생성**: 첫 실행이 만든 baseline 이미지를 사람에게 보여주고, 승인받은 뒤에만 커밋한다. 승인 없는 baseline은 "현재 버그를 정답으로 박제"하는 것이다.
2. **갱신**: 의도된 UI 변경이면 `--update-snapshots`(웹) / baseline 재촬영(앱) 후, **변경된 baseline만 담은 커밋**을 만들어 사람이 이미지를 보고 승인한다. 기능 커밋에 섞지 않는다.
3. baseline 이미지는 **Git LFS**로 추적한다(`*.png` in snapshot dirs) — repo 비대화 방지.
4. diff가 났을 때 "threshold를 올려서" 통과시키지 않는다 — 원인(비결정론 요소)을 마스킹·고정으로 제거하거나, 의도된 변경이면 갱신 절차를 밟는다.

## 승격 경로

비주얼 테스트가 ~50개를 넘거나 PR에서 이미지 diff 승인이 고통스러워지면(GitHub은 이미지 diff를 인라인으로 못 보여준다), 리뷰 UI가 있는 서비스로 승격을 검토한다 — 1순위 Argos(무료 5,000장/월, 예산 상한 설정 가능). 승격은 새 의존성이므로 대안·비용과 함께 사람 승인을 받고 결정 기록(ADR)을 남긴다.
