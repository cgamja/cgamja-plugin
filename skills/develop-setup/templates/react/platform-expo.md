---
paths:
  - "app/**/*.tsx"
  - "src/**/*.tsx"
---
# 플랫폼 프로필: expo (iOS · Android)

UI task의 증거와 리뷰 렌즈 L5(`reviewer-platform`)가 이 파일을 읽는다. 기준 원문은 cgamja `references/platform-fit-frontend.md` §1.

- 스크린샷: iPhone SE(375×667) · iPhone 15(393×852) · Pixel 7(412×915), **라이트·다크 각 1회**
- 안전영역: `useSafeAreaInsets`/`SafeAreaView` — 상단·하단 탭바 겹침 0
- 키보드: `KeyboardAvoidingView` 또는 `react-native-keyboard-controller`. 입력 포커스 상태 스크린샷 1장(CTA가 키보드 위에)
- 목록: 20개 넘을 수 있으면 `FlatList`/`FlashList`. `ScrollView` 안의 긴 목록 금지
- 네비게이션: expo-router. Android 하드웨어 뒤로가기 동작을 화면 spec에 명시
- 접근성: `accessibilityRole`/`accessibilityLabel`/`accessibilityState`, 터치 타깃 44pt, `allowFontScaling` 끄지 않음
- 오프라인: 네트워크 화면은 오프라인 상태(NetInfo) 표시 + 재시도
- 성능 증거: 목록 스크롤 JS FPS(Perf monitor) 또는 FlashList 사용 명시
- 금지: `div`/`onClick` 등 웹 관례(린트), 토큰 외 색, 플랫폼 분기 없이 웹 전용 API 사용(`window`, `document`) — 필요하면 `*.web.tsx`/`*.native.tsx`
