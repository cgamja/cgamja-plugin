---
paths:
  - "src/**/*.tsx"
  - "src/**/*.css"
---
# 플랫폼 프로필: {{PLATFORM_PROFILE}}  <!-- web-desktop | web-mobile 중 develop-setup이 치환. 둘 다면 web-mobile 기준 -->

UI task의 증거와 리뷰 2축(review-cgamja·code-review)이 이 파일을 읽는다. 기준 원문은 cgamja `docs/guides/platform-fit-frontend.md` §1.

각 항목 끝 **[대괄호]** 는 그 규칙을 **무엇이 강제하는가**다(adr/0031). `[없음]`·`[사람 — …]` 도 유효한 답이며, 요점은 강제 수단이 없다는 사실이 읽는 사람에게 보이는 것이다.

- 뷰포트 스크린샷: {{VIEWPORTS}}  **[evidence.screenshot]**  <!-- web-desktop: 375 / 768 / 1280 · web-mobile: 375 / 390 / 430 세로 + 768 가로 -->
- 다크 모드: {{DARK_MODE}}  **[evidence.dark]**  <!-- tokens.css에 dark 토큰 있으면 "각 뷰포트 2배", 없으면 "없음" -->
- 입력 기본: {{INPUT}}  **[사람 — 리뷰 2축]**  <!-- web-desktop: 포인터+키보드 · web-mobile: 터치(hover 없음) -->
- 터치 타깃: {{TOUCH_TARGET}}  **[oxlint-jsx-a11y + 리뷰 2축]**  <!-- 24px(WCAG 2.2) · 44px(모바일) -->
- 안전영역·키보드: {{SAFE_AREA}}  **[evidence.screenshot]**  <!-- web-mobile: env(safe-area-inset-*) + viewport-fit=cover, 입력 포커스 시 하단 CTA 스크린샷 1장 · web-desktop: 해당 없음 -->
- 성능 증거: Lighthouse {{LH_PRESET}} 프리셋 LCP/INP/CLS 1회(기준 2.5s / 200ms / 0.1)  **[commands.perf]** — `null` 이면 이 줄을 `[없음]` 으로 바꾸거나 삭제한다(adr/0031: 지키지 않을 규칙은 없는 게 낫다)
- 금지 **[oxlint + contrast 테스트 + 리뷰 2축]**: 고정 `px` 폭, `100vh`(→ `dvh`), hover에만 있는 액션(모바일), 토큰 외 색·간격, 임의값(`[22.126px]`)
- 텍스트: `rem`, 200% 확대에서 잘림 0  **[evidence.zoom200]** — 촬영 스크립트가 선언을 읽어 `-zoom200` 컷을 자동 포함한다(사람이 인자를 빠뜨릴 여지를 없앤다)
