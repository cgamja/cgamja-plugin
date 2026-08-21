# Expo(RN) 테스트 설정 — 웹 템플릿과의 차이만

브라우저가 없으므로 Vitest Browser Mode 대신 **`jest-expo` + `@testing-library/react-native`** 한 층. 계층 결정표에서 "인터랙션·레이아웃"도 RNTL로 간다(레이아웃 픽셀은 시뮬레이터 스크린샷으로).

```jsonc
// package.json
"jest": { "preset": "jest-expo", "setupFilesAfterEnv": ["./test/setup.ts"] },
"scripts": {
  "test": "jest",
  "verify": "tsc --noEmit && eslint . && jest --ci && knip",
  "e2e": "maestro test .maestro/"
}
```
- `test/setup.ts`: MSW `setupServer`(Node), `@testing-library/jest-native` 매처
- 쿼리: `getByRole`/`getByLabelText`(accessibilityLabel) 우선, `userEvent`는 RNTL 내장(`userEvent.setup()`)
- E2E: **Maestro** `.maestro/*.yaml` 3개(진입·핵심 동작·파괴적 플로우). Detox보다 설정이 가볍고 YAML이라 에이전트가 쓰기 쉬움
- 스크린샷: `xcrun simctl io booted screenshot out.png` / `adb exec-out screencap -p > out.png`. 기기 2~3종(iPhone 소형·대형, Android 1). Figma 375×812 대조는 동일. cgamja `app-ref-to-figma/scripts/snap.sh` 재사용 가능
- computed style 대조 불가 → RNTL `toHaveStyle` + 스크린샷
- 변이 테스트: Stryker jest 러너는 정상 동작(`src/domains/**/model/**`)
- 스타일 린트: NativeWind면 `eslint-plugin-better-tailwindcss` 그대로, `StyleSheet`면 `no-restricted-syntax`로 리터럴 색(`/#[0-9a-f]{3,8}/i`)·매직 넘버 차단
- 라우터: `app/`이 expo-router 폴더(프레임워크 소유). 라우트 파일은 `export { Screen as default } from "@/domains/<d>"` 한 줄. boundaries의 `router` 요소 = `app/**`
- 코드→Figma 거울(`generate_figma_design`)은 웹 렌더 필요 → Expo Web으로 띄우거나 시뮬레이터 스크린샷을 `upload_assets`로
