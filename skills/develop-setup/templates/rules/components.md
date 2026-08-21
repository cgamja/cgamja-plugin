---
paths: ["src/domains/**/ui/**/*.tsx", "src/shared/ui/**/*.tsx"]
---
# 컴포넌트
- 파일명 = 컴포넌트명(PascalCase). 훅 `use*`, 핸들러 `handle*`, props `on*`
- 200줄 또는 책임 2개면 분리. props 7개 넘으면 객체로
- 빈·로딩·에러 상태는 spec에 없어도 기본 포함
- `role`/`aria-*`(RN: `accessibilityRole`) 수동 추가 전에 네이티브 요소로 해결되는지 먼저
- 스타일 값은 토큰만. Figma 출력의 `leading-[22.126px]`류는 토큰으로 치환, 없으면 물어라
- 정본 예시: `src/shared/ui/button/Button.tsx` — 새 컴포넌트는 이 파일의 구조를 따른다
