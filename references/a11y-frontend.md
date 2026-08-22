# 접근성(a11y) — 기계로 강제하고, 산문은 여기만 (`adr/0010`, `adr/0014`)

**원칙**: 접근성은 에이전트가 "신경 써서" 되는 게 아니라 **린트 → 런타임 검사 → 역할 쿼리 테스트** 세 층이 막아야 한다. 프로젝트는 `.claude/cgamja.json` `a11y.lint`·`a11y.runtime`에 1·2층 도구를 선언하고(없으면 `null` — 세팅 대조표의 제안 항목), 이 문서는 세 층이 못 잡는 것(의미·순서·모바일)의 체크 기준이다. 리뷰 렌즈(`review-lenses-frontend.md` L4)와 UI task 증거(`develop-fe/workflow.md` 2장)가 이 파일을 참조한다. §5는 검증된 구현.

## 1. 세 층
| 층 | 선언 키 | 언제 | 잡는 것 | 없을 때(`null`) |
|---|---|---|---|---|
| 린트 | `a11y.lint` | PostToolUse, 밀리초 | 이미지 대체 텍스트 없음, 클릭만 있는 비대화형 요소, 역할 없는 터치 요소, 라벨 없는 input | 리뷰 렌즈 L4가 §2 전 항목을 diff에서 본다 |
| 런타임 | `a11y.runtime` | UI task 끝, `commands.verify` 또는 E2E | 대비, 이름 없는 버튼, 중첩 인터랙티브, ARIA 오용, 헤딩 순서 | 수동 표(§3) + 키보드 1회 |
| 테스트 | (`tdd-frontend.md` §3 쿼리 규칙) | 모든 컴포넌트 테스트 | 역할로 못 찾으면 = 보조기기도 못 찾음 | — |

런타임 violations는 **블로킹**(`serious`/`critical`). `moderate` 이하는 PR 본문에 나열하고 넘어갈 수 있다 — 단 같은 규칙이 2회 나오면 린트로 승격.

## 2. 세 층이 못 잡는 것 — UI task 체크 (에이전트가 코드로 확인, 스크린샷으로 안 함)
- [ ] **네이티브 요소 먼저**: 버튼·링크·입력·선택·대화상자는 플랫폼의 의미 요소로. 일반 컨테이너에 role만 붙이면 키보드·포커스·활성화 이벤트를 손으로 다 재현해야 하므로 리뷰에서 거부. 네이티브 앱은 터치 요소에 접근성 role 필수.
- [ ] **이름**: 아이콘만 있는 버튼은 접근성 라벨. 라벨 텍스트는 **동작**("닫기", "검색")이지 아이콘 이름("X", "돋보기")이 아니다. 같은 화면에서 같은 이름의 버튼 2개면 구분자를 붙인다("할 일 '장보기' 삭제").
- [ ] **폼**: 모든 input에 보이는 라벨(연결된) 또는 labelledby. placeholder는 라벨이 아니다. 에러는 describedby로 input에 연결하고 invalid 상태 표시. 제출 후 첫 에러로 포커스 이동.
- [ ] **포커스**: 모달 열림 → 안으로, 닫힘 → 연 요소로. 라우트 전환 → 페이지 제목/h1로. 삭제 후 → 다음 항목 또는 목록 제목. 포커스 링 제거는 `:focus-visible` 대체 스타일이 있을 때만.
- [ ] **동적 변화**: 토스트·검증 결과·목록 갱신은 live region(polite; 에러는 assertive). 로딩은 busy 상태 또는 "불러오는 중" 텍스트 — 스피너만은 안 됨.
- [ ] **헤딩·랜드마크**: 페이지마다 h1 하나, 레벨 건너뛰기 없음. main/nav/header 랜드마크. 시각적 크기는 스타일로, 레벨은 의미로.
- [ ] **터치 타깃**: 44×44pt(iOS)/48dp(Android) 이상 — 아이콘 버튼은 padding으로 채운다. 인접 타깃 간 8px. 데스크톱 웹 최소 24px(WCAG 2.2).
- [ ] **대비**: 토큰(`design.tokens`)에서만 색을 쓰면 자동으로 충족돼야 한다. 토큰 조합이 4.5:1 미만이면 **토큰 문제**로 보고(디자인 원천 수정 제안), 코드에서 색을 덮어쓰지 않는다.
- [ ] **모션**: reduced-motion 설정 존중. 자동 재생 캐러셀·무한 애니메이션은 정지 수단.
- [ ] **텍스트 크기**: 웹은 상대 단위, 네이티브는 시스템 글꼴 스케일링 유지. 200%에서 잘림·겹침 없음(375 뷰포트 + 확대로 1회 확인).

## 3. 증거 (UI task 완료 정의에 추가되는 것)
- 런타임 결과: `violations: 0 (serious+)`, 도구·URL·뷰포트. `a11y.runtime`이 null이면 "도구 없음"을 명시하고 §2 표를 PR에 붙인다.
- 키보드 1회: Tab 순서가 시각 순서와 같고 모든 인터랙션이 Enter/Space로 되는지 — 에이전트가 브라우저 자동화로 Tab 시퀀스를 찍어 포커스된 요소 이름 목록을 낸다.
- 네이티브(`platform.profile: native`): 위 §2 체크 표를 PR에 붙인다(런타임 도구 없음을 명시).

## 4. 에이전트 실패 모드 → 대응
| 증상 | 대응 |
|---|---|
| 접근성 라벨을 모든 요소에 붙임(과잉) | 린트의 중복 role 규칙 + 리뷰 렌즈: "보이는 텍스트가 있으면 별도 라벨 금지" |
| 컨테이너에 role="button"으로 디자인 맞춤 | 네이티브 요소 + 스타일 reset. 리뷰 거부 사유 |
| 테스트를 test-id로 통과시킴 | `tdd-frontend.md` §3 쿼리 순서 + 린트(쿼리 우선순위 규칙) |
| 디자인 원천에 라벨이 없어서 안 붙임 | 디자인 원천에 없는 보조기기 텍스트는 **코드가 원천**. `summary.md` "디자인 결정"에 라벨 목록 기록 |
| 색 대비를 코드에서 보정 | 토큰 문제로 보고. 토큰 외 색 사용은 린트가 막음 |

## 5. 검증된 구현 (2026-08-21)
| 스택 | `a11y.lint` | `a11y.runtime` | 테스트 쿼리 |
|---|---|---|---|
| React 웹(Next/Vite) | `eslint-plugin-jsx-a11y` (strict) — `alt-text`, `click-events-have-key-events`, `no-redundant-roles` | `@axe-core/playwright`(E2E) + `vitest-axe`(Browser Mode, `expect.extend(axeMatchers)`) | RTL/`vitest-browser-react` `getByRole`·`getByLabelText`, `eslint-plugin-testing-library` `prefer-screen-queries` |
| React Native(Expo) | `eslint-plugin-react-native-a11y` (all) — `Pressable`에 `accessibilityRole` 없음 = 에러 | Expo web 빌드에 axe / 네이티브는 없음 → §3 수동 표 | RNTL `getByRole`·`getByLabelText`. 속성: `accessibilityRole`/`accessibilityLabel`/`accessibilityState`, `allowFontScaling` 유지 |
| 그 외(Vue/Svelte/…) | 미실측 — `vue-a11y`/`svelte` 컴파일러 경고 등 조사·설치·프로브 후 여기에 추가 | axe는 프레임워크 무관(Playwright 경유) | |
