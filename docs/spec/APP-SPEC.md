## Spec for Application (Front-End)

> 버전은 2026-08 기준 (Expo SDK 57 = RN 0.86 + React 19.2). 최신화는 [DOCTOR.md](./DOCTOR.md).
> 웹과 마찬가지로 "이유 + 버린 대안 + 감수한 비용"을 기록한다. 프로젝트별 이탈은 `adr/`에 ([ADR.md](./ADR.md)).
> 이 스펙에 없는 라이브러리를 추가할 때는 [LIBRARY.md](./LIBRARY.md)의 게이트를 거친다.

### Language

**TypeScript 5.x (strict)** — [WEB-SPEC.md](./WEB-SPEC.md)와 동일

### Framework

**React Native 0.86 (Expo SDK 57)**
- 이유: 웹(React)과 멘탈 모델·상태 관리·테스트 철학·유틸 코드를 공유 — 한 사람이 웹/앱을 오갈 수 있다는 게 1인~소규모에서 가장 큰 레버리지
- 버린 대안: Flutter — 성능·일관성은 좋으나 Dart 생태계가 웹과 단절, 코드 공유 0 / 네이티브(Swift/Kotlin) — 두 플랫폼 두 벌 개발은 소규모에서 불가
- 감수한 비용: 네이티브 브릿지 디버깅 난이도, 네이티브 신기능 지원 지연, 웹과 "비슷하지만 다른" 부분(스타일·네비게이션)에서 오는 함정

**Expo (SDK 57)**
- 이유: 네이티브 빌드 설정 없이 시작, EAS Update(OTA), expo-doctor로 의존성 검증 — [DOCTOR.md](./DOCTOR.md) 워크플로우와 직결
- 버린 대안: bare RN — 네이티브 모듈 자유도는 높으나 빌드·업그레이드를 전부 직접 관리. 요즘은 config plugin/CNG로 Expo에서도 대부분 가능
- 감수한 비용: SDK 릴리스 주기에 의존성 버전이 묶임(→ 개별 패키지 대신 SDK 단위 업그레이드 규칙), 특수 네이티브 커스텀 시 prebuild 이해 필요

**Expo Router** — 파일 기반 라우팅, Next.js와 같은 멘탈 모델. 버린 대안: React Navigation 직접 사용(Expo Router가 그 위의 추상화 — 설정 코드 감소). 비용: 추상화 아래 문제는 React Navigation을 알아야 풀림

### CSS

**NativeWind 4.x**
- 이유: RN엔 CSS가 없어 TailwindCSS 직접 사용 불가 — NativeWind가 Tailwind 문법을 StyleSheet로 컴파일해 웹과 스타일 작성 방식을 통일
- 버린 대안: StyleSheet API — 웹과 작성 방식 단절, 네이밍 비용 / Tamagui — 강력하나 러닝커브·종속이 큼
- 감수한 비용: 빌드 설정(babel/metro) 추가, 일부 웹 전용 유틸 미지원 — 안 되는 속성은 StyleSheet 폴백

### State Management

웹과 동일 (**Tanstack Query 5.x + Zustand 5.x**) — 이유·대안·비용은 [WEB-SPEC.md](./WEB-SPEC.md). 웹/앱이 같은 상태 관리 코드를 공유할 수 있는 것 자체가 선택 이유다.

### Bundler

- **Metro** (Expo 기본) — RN은 Vite 사용 불가. 버린 대안: Re.Pack(webpack 기반) — 커스텀 유연성은 있으나 Expo 생태계와 마찰. 커스텀할 이유가 생기기 전까지 기본 유지

### Tester

**Jest + jest-expo preset**
- 이유: RN 공식 권장 러너, jest-expo가 네이티브 모듈 mock 처리
- 버린 대안: Vitest — RN transform 미지원. 웹(Vitest)과 러너가 갈라지는 건 비용이지만 RTL 계열 API가 같아 테스트 작성 경험은 동일
- 감수한 비용: 웹과 러너 이원화, Jest 속도

**React Native Testing Library** — 웹 RTL과 동일한 역할 기반 철학. 비용: 네이티브 모듈은 mock 필요

**Maestro** (E2E)
- 이유: YAML 선언형 — 시나리오가 문서처럼 읽히고 유지보수 쉬움
- 버린 대안: Detox — 세밀한 제어는 좋으나 설정 무겁고 flaky 관리 비용 큼
- 감수한 비용: 복잡한 네이티브 상호작용 제어 한계 — 핵심 플로우만 커버

**MSW** — 네트워크 경계 mock, 웹과 동일

### Lint / Format

- ESLint (import 단방향 규칙 강제) + Prettier — 웹과 동일

### 추가하면 좋은 거

- React Compiler — RN 0.76+ / Expo SDK 52+ 지원. 비용은 WEB-SPEC 동일
- es-toolkit — 웹과 동일 (번들 크기 이득)
- EAS Build/Update — CI 빌드·OTA 배포. 비용: EAS 요금·Expo 클라우드 종속
