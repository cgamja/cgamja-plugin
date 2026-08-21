# 접근성(a11y) — 기계로 강제하고, 산문은 여기만 (`adr/0010`)

**원칙**: 접근성은 에이전트가 "신경 써서" 되는 게 아니라 **린트 → axe → 역할 쿼리 테스트** 세 층이 막아야 한다. 이 문서는 그 세 층이 못 잡는 것(의미·순서·모바일)의 체크 기준이다. 리뷰 렌즈(`review-lenses-frontend.md` L4)와 UI task 증거(`develop-fe/workflow.md` 2장)가 이 파일을 참조한다.

## 1. 세 층 (세팅 시 `develop-setup`이 깐다)
| 층 | 웹(Next/Vite) | Expo | 언제 | 잡는 것 |
|---|---|---|---|---|
| 린트 | `eslint-plugin-jsx-a11y` (strict) | `eslint-plugin-react-native-a11y` (all) | PostToolUse, 밀리초 | `img` alt 없음, `onClick`만 있는 div, `accessibilityRole` 없는 터치 요소, 라벨 없는 input |
| 런타임 | `@axe-core/playwright`(E2E) + `vitest-axe`(Browser Mode) | Expo web 빌드에 axe / 네이티브는 없음 → 수동 표 | UI task 끝, `pnpm verify` | 대비, 이름 없는 버튼, 중첩 인터랙티브, ARIA 오용, 헤딩 순서 |
| 테스트 | `getByRole`/`getByLabelText` 우선 (`tdd-frontend.md` §3) | RNTL `getByRole`/`getByLabelText` | 모든 컴포넌트 테스트 | 역할로 못 찾으면 = 보조기기도 못 찾음 |

axe violations는 **블로킹**(`serious`/`critical`). `moderate` 이하는 PR 본문에 나열하고 넘어갈 수 있다 — 단 같은 규칙이 2회 나오면 린트로 승격.

## 2. 세 층이 못 잡는 것 — UI task 체크 (에이전트가 코드로 확인, 스크린샷으로 안 함)
- [ ] **네이티브 요소 먼저**: `button`/`a`/`input`/`select`/`dialog`. `div role="button"`은 키보드·포커스·활성화 이벤트를 손으로 다 재현해야 하므로 리뷰에서 거부. Expo: `Pressable`+`accessibilityRole`.
- [ ] **이름**: 아이콘만 있는 버튼은 `aria-label`(웹)/`accessibilityLabel`(RN). 라벨 텍스트는 **동작**("닫기", "검색")이지 아이콘 이름("X", "돋보기")이 아니다. 같은 화면에서 같은 이름의 버튼 2개면 구분자를 붙인다("할 일 '장보기' 삭제").
- [ ] **폼**: 모든 input에 보이는 `label`(`htmlFor`) 또는 `aria-labelledby`. placeholder는 라벨이 아니다. 에러는 `aria-describedby`로 input에 연결하고 `aria-invalid`. 제출 후 첫 에러로 포커스 이동.
- [ ] **포커스**: 모달 열림 → 안으로, 닫힘 → 연 요소로. 라우트 전환 → 페이지 제목/h1로. 삭제 후 → 다음 항목 또는 목록 제목. `outline: none`은 `:focus-visible` 대체 스타일이 있을 때만.
- [ ] **동적 변화**: 토스트·검증 결과·목록 갱신은 `aria-live="polite"`(에러는 `assertive`). 로딩은 `aria-busy` 또는 "불러오는 중" 텍스트 — 스피너만은 안 됨.
- [ ] **헤딩·랜드마크**: 페이지마다 h1 하나, 레벨 건너뛰기 없음. `main`/`nav`/`header` 랜드마크. 시각적 크기는 CSS로, 레벨은 의미로.
- [ ] **터치 타깃**: 44×44pt(iOS)/48dp(Android) 이상 — 아이콘 버튼은 padding으로 채운다. 인접 타깃 간 8px.
- [ ] **대비**: 토큰에서만 색을 쓰면 자동으로 충족돼야 한다. 토큰 조합이 4.5:1 미만이면 **토큰 문제**로 보고(Figma 원천 수정 제안), 코드에서 색을 덮어쓰지 않는다.
- [ ] **모션**: `prefers-reduced-motion` 존중. 자동 재생 캐러셀·무한 애니메이션은 정지 수단.
- [ ] **텍스트 크기**: 웹은 `rem`, RN은 `allowFontScaling` 기본 유지. 200%에서 잘림·겹침 없음(375 뷰포트 + 브라우저 확대로 1회 확인).

## 3. 증거 (UI task 완료 정의에 추가되는 것)
- axe 결과: `violations: 0 (serious+)`, 도구·URL·뷰포트
- 키보드 1회: Tab 순서가 시각 순서와 같고 모든 인터랙션이 Enter/Space로 되는지 — 에이전트가 `agent-browser`로 Tab 시퀀스를 찍어 포커스된 요소 이름 목록을 낸다
- Expo 네이티브: 위 §2 체크 표를 PR에 붙인다(도구 없음을 명시)

## 4. 에이전트 실패 모드 → 대응
| 증상 | 대응 |
|---|---|
| `aria-label`을 모든 요소에 붙임(과잉) | 린트 `jsx-a11y/no-redundant-roles` + 리뷰 렌즈: "보이는 텍스트가 있으면 aria-label 금지" |
| `role="button"` div로 디자인 맞춤 | 네이티브 요소 + CSS reset. 리뷰 거부 사유 |
| 테스트를 `getByTestId`로 통과시킴 | `tdd-frontend.md` §3 쿼리 순서 + 린트 `testing-library/prefer-screen-queries` |
| Figma에 라벨이 없어서 안 붙임 | 디자인 원천에 없는 보조기기 텍스트는 **코드가 원천**. `summary.md` "디자인 결정"에 라벨 목록 기록 |
| 색 대비를 코드에서 보정 | 토큰 문제로 보고. `tokens.css` 외 색 사용은 린트(`better-tailwindcss`/토큰 린트)가 막음 |
