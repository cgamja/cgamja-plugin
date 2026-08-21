---
paths:
  - "src/**/*.tsx"
  - "src/**/*.css"
---
# 플랫폼 프로필: {{PLATFORM_PROFILE}}  <!-- web-desktop | web-mobile 중 develop-setup이 치환. 둘 다면 web-mobile 기준 -->

UI task의 증거와 리뷰 렌즈 L5(`reviewer-platform`)가 이 파일을 읽는다. 기준 원문은 cgamja `references/platform-fit-frontend.md` §1.

- 뷰포트 스크린샷: {{VIEWPORTS}}  <!-- web-desktop: 375 / 768 / 1280 · web-mobile: 375 / 390 / 430 세로 + 768 가로 -->
- 다크 모드: {{DARK_MODE}}  <!-- tokens.css에 dark 토큰 있으면 "각 뷰포트 2배", 없으면 "없음" -->
- 입력 기본: {{INPUT}}  <!-- web-desktop: 포인터+키보드 · web-mobile: 터치(hover 없음) -->
- 터치 타깃: {{TOUCH_TARGET}}  <!-- 24px(WCAG 2.2) · 44px(모바일) -->
- 안전영역·키보드: {{SAFE_AREA}}  <!-- web-mobile: env(safe-area-inset-*) + viewport-fit=cover, 입력 포커스 시 하단 CTA 스크린샷 1장 · web-desktop: 해당 없음 -->
- 성능 증거: Lighthouse {{LH_PRESET}} 프리셋 LCP/INP/CLS 1회(기준 2.5s / 200ms / 0.1)
- 금지: 고정 `px` 폭, `100vh`(→ `dvh`), hover에만 있는 액션(모바일), 토큰 외 색·간격, 임의값(`[22.126px]`)
- 텍스트: `rem`, 200% 확대에서 잘림 0
