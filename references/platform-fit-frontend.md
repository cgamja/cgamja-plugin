# 플랫폼 적합성 — 데스크톱 웹 / 모바일 웹 / 네이티브, 같은 화면이라도 증거가 다르다 (`adr/0010`, `adr/0014`)

**원칙**: "반응형"은 체크 항목이 아니라 **프로필**이다. 프로젝트가 `.claude/cgamja.json` `platform.profile`(`web-desktop` | `web-mobile` | `native`)을 선언하고 `.claude/rules/platform.md`(템플릿 `templates/rules/platform-{web,expo}.md`)에 뷰포트·증거·금지 목록을 둔다. develop-fe UI task와 review-fe L5 렌즈는 그 프로필만 읽는다. 스킬 본문에는 스택 분기를 쓰지 않는다. §5는 검증된 구현.

## 1. 프로필 표
| | `web-desktop` | `web-mobile` / PWA | `native` (iOS·Android) |
|---|---|---|---|
| 뷰포트 증거 | 375 / 768 / 1280 (+1920이면 최대폭 컨테이너 확인) | **375 / 390 / 430** 세로 + 768 가로 1회 | 소형(375×667) / 표준(393×852) / Android(412×915) 시뮬레이터 스크린샷, **라이트·다크 각 1회** |
| 입력 기본 | 포인터+키보드 | 터치(hover 상태 없음 가정) | 터치, 하드웨어 뒤로가기(Android) |
| 안전 영역 | — | `env(safe-area-inset-*)` + `viewport-fit=cover` | 안전영역 insets API — 상단·하단 탭바 겹침 0 |
| 키보드 | — | 입력 포커스 시 뷰포트 축소 — 고정 하단 CTA가 키보드 위로 오는지 | 키보드 회피 컨테이너; 입력이 키보드에 가려지면 실패 |
| 네비게이션 관례 | URL이 상태, 뒤로가기=브라우저 | 같음 + 하단 탭이면 fixed 안전영역 | 스택/탭 네비게이터. iOS는 스와이프백, Android는 하드웨어 뒤로가기 동작 명시 |
| 스크롤 | 페이지 | 페이지 + 풀투리프레시 여부 | 가상화 목록 — 스크롤 컨테이너 안의 긴 목록 통째로 금지 |
| 로딩·빈·에러 | 인라인 | 전체 화면(공간 부족) + 재시도 버튼 | 같음 + 오프라인 상태 |
| 성능 증거 | Lighthouse 또는 Core Web Vitals 3개(LCP/INP/CLS) 수치 1회 | 같음, **모바일 프리셋 + 4G 스로틀** | 목록 스크롤 시 JS 스레드 FPS 또는 가상화 목록 사용 여부 |
| 터치 타깃 | 24px(WCAG 2.2 AA) | 44px | 44pt / 48dp |
| 텍스트 | 상대 단위, 200% 확대 | 같음 + 시스템 글꼴 크기 | 시스템 스케일링 유지, 최대 2단계 확대에서 잘림 0 |
| 다크 모드 | 토큰에 있으면 스크린샷 2배 | 같음 | **필수** — 시스템 설정 따라감 |

## 2. 디자인 스냅샷이 말해줘야 하는 것
`design/screens/<slug>/summary.md`에 다음 필드가 없으면 Tier-2 질문 ④(반응형 범위)에서 채운다:
- `platform:` web-desktop | web-mobile | native | (복수)
- `breakpoints:` 디자인 프레임 폭 목록(예: 375, 1440) — 한 폭만 있으면 **다른 폭은 디자인 갭**(2-D 루프 대상이 아니라 "규칙으로 유추": 컨테이너 최대폭·그리드 컬럼 수를 `components.md`에서)
- `orientation:` portrait | both (네이티브·태블릿만)

## 3. 에이전트 실패 모드 → 대응
| 증상 | 대응 |
|---|---|
| 1280 한 장만 찍고 "반응형 확인" | UI task 증거 = 프로필 뷰포트 **전부**. 하나라도 없으면 완료 아님 |
| 모바일에서 hover로만 드러나는 액션(삭제 아이콘 등) | 프로필이 터치면 항상 보이거나 스와이프/롱프레스 + 접근 가능한 대안 |
| `px` 고정 폭, `100vh`(모바일 주소창 문제) | `dvh`, 컨테이너 쿼리, 토큰. 린트: 임의값 금지 규칙 |
| 네이티브에서 웹 관례(`div`, `onClick`) | 린트가 잡음. 공용 컴포넌트는 플랫폼 분기 파일 |
| 키보드 올라오면 CTA 가려짐 | 프로필 "키보드" 행 증거 — 입력 포커스 상태 스크린샷 1장 추가 |
| 다크 모드 토큰 없는 색 | 토큰만 사용(`a11y-frontend.md` §2 대비 항목과 동일 원천) |

## 4. 증거 형식 (PR 템플릿 "스크린샷" 줄을 프로필에 맞게 바꾼다)
```
- [ ] 스크린샷 <프로필 뷰포트 나열>: <경로들>  · 다크: <경로>(해당 시)
- [ ] 키보드/안전영역: <입력 포커스 스크린샷 경로>(모바일 프로필만)
- [ ] 성능: LCP x.xs · INP xxms · CLS 0.xx (모바일 프리셋)  또는 목록 FPS
```

## 5. 검증된 구현 (2026-08-21)
- **웹(React, Tailwind v4)**: 임의값·`h-screen` 금지는 `eslint-plugin-better-tailwindcss` `no-restricted-classes`(`^.*\[.+\].*$`, `^h-screen$|^min-h-screen$` → `dvh`). 뷰포트 스크린샷은 `agent-browser`/Playwright. 스크래치 Tier-2에서 L5 렌즈가 뷰포트 누락을 실제로 잡음(`reports/develop-fe-tier2_2026-08-21_restructured.md`).
- **Expo(React Native)**: 안전영역 `SafeAreaView`/`useSafeAreaInsets`, 키보드 `KeyboardAvoidingView` 또는 `react-native-keyboard-controller`, 목록 `FlatList`/`FlashList`, 오프라인 `NetInfo`, 분기 `*.web.tsx`/`*.native.tsx`, 네비 `expo-router`. 스크린샷은 시뮬레이터, 웹 렌더 필요 시 Expo Web. 절차 런은 **미실시**.
- 그 외 스택: 표의 증거는 그대로, 도구만 조사·실측 후 여기에 추가.
