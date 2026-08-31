## Spec for Web (Front-End)

> 버전은 2026-08 기준. 최신화는 [DOCTOR.md](./DOCTOR.md) 워크플로우로 관리한다.
> 모든 선택은 "이유 + 버린 대안 + 감수한 비용"을 함께 기록한다 — 비용 없는 선택은 없고, 비용을 안 적은 문서는 검증할 수 없다.
> 프로젝트가 이 스펙에서 벗어날 때는 해당 프로젝트의 `adr/`에 기록한다 ([ADR.md](./ADR.md)).
> 이 스펙에 없는 라이브러리를 추가할 때는 [LIBRARY.md](./LIBRARY.md)의 게이트를 거친다.

### Language

**TypeScript 5.x (strict)**
- 이유: 타입이 곧 문서·계약 — "예측 가능성" 원칙의 기반. AI 하네스가 코드를 쓸 때 타입 에러가 즉각적인 피드백 루프가 된다
- 버린 대안: JS + JSDoc — 타입 표현력 한계, strict 강제 불가
- 감수한 비용: 타입 작성 비용, 빌드 단계 필수. 복잡한 제네릭은 오히려 가독성을 해칠 수 있어 "타입 체조" 금지

### Framework — React vs Next.js 고르는 기준

**기본값은 Next.js.** 아래 기준으로 판단하고, 프로젝트별 최종 결정은 ADR로 남긴다:

| 상황 | 선택 |
| --- | --- |
| 대외 서비스 — SEO, 초기 로딩 속도(SSR), OG 태그가 중요 | **Next.js** |
| 서버 컴포넌트/서버 액션으로 API 레이어를 줄이고 싶다 | **Next.js** |
| 로그인 뒤에서만 쓰는 내부 도구·어드민·대시보드 (SEO 불필요) | **React + Vite SPA** |
| 서버 없이 정적 호스팅만으로 배포하고 싶다 | **React + Vite SPA** |
| RN 앱 안에 들어가는 웹뷰 페이지 | 가볍게: React + Vite / SSR 필요하면 Next.js |

- 판단이 안 서면 Next.js — SPA→Next 이전이 그 반대보다 훨씬 비싸다
- 참고: 토스는 SSR·파일 라우팅·최신 React 기능 조기 도입을 이유로 Next.js를 쓴다. 단 이는 수백 명 규모의 맥락 — 내 기본값이 Next인 이유는 그게 아니라 **위 표의 첫 두 행이 내 프로젝트에서 실제로 자주 참이기 때문**

**React 19.2.x**
- 이유: Suspense·use()·Actions로 비동기를 선언적으로 처리. RN과 멘탈 모델 공유
- 버린 대안: Vue/Svelte — 프레임워크 자체는 훌륭하나 RN(앱)과 코드·철학 공유 불가, 생태계·레퍼런스 규모
- 감수한 비용: 런타임 크기, JSX 러닝커브, 잦은 패러다임 변화(클래스→훅→RSC)를 따라가는 비용

**Next.js 16.x (Active LTS)**
- 이유: 위 기준 표. App Router + RSC로 데이터 페칭이 서버로 이동해 클라이언트 번들·워터폴 감소
- 버린 대안: Remix/React Router v7 — 웹 표준 지향은 매력적이나 RSC 성숙도·생태계에서 밀림 / TanStack Start — 아직 초기
- 감수한 비용: 프레임워크 매직(캐싱 규칙 등)이 많아 디버깅 시 내부를 알아야 함, Vercel 중심 생태계 종속 인상, 메이저 업그레이드 비용 (→ [DOCTOR.md](./DOCTOR.md)의 codemod 규칙으로 완화)

### CSS

**TailwindCSS 4.x**
- 이유: 스타일이 마크업 옆에 붙어 응집도↑, 클래스 네이밍 비용 제거, 디자인 토큰(@theme)이 곧 제약이 됨. v4는 CSS-first 설정·빌드 속도 개선
- 버린 대안: CSS Modules — 네이밍·파일 왕복 비용 / styled-components 등 런타임 CSS-in-JS — RSC와 상성 나쁨(서버 컴포넌트에서 런타임 스타일 주입 불가)
- 감수한 비용: 클래스 나열로 마크업 가독성 저하 (→ cn 유틸 + 반복 시 컴포넌트화로 완화), 유틸 클래스 러닝커브

**cn (clsx + tailwind-merge)**
- 이유: 조건부 클래스 병합 시 Tailwind 우선순위 충돌 해결
- 감수한 비용: 미미한 런타임 비용

### State Management

**Tanstack Query 5.x** (서버 상태)
- 이유: 서버 상태를 선언적으로 관리(캐싱·재검증·로딩/에러). TkDodo의 "서버 상태는 내 것이 아닌 스냅샷" 관점 채택
- 버린 대안: SWR — 기능 범위(mutation·optimistic update) 부족 / RTK Query — Redux 종속
- 감수한 비용: 캐시 키·staleTime 등 캐시 모델 러닝커브, 잘못 쓰면 "왜 안 갱신되지" 디버깅 비용

**Zustand 5.x** (클라이언트 상태)
- 이유: 보일러플레이트 최소, 번들 ~1KB, 셀렉터로 리렌더 제어. "맥락 줄이기"에 부합
- 버린 대안: Redux Toolkit — 소규모에서 보일러플레이트 과다 / Jotai — atom 모델은 상태 흐름 추적이 분산됨 / Context — 리렌더 제어 불가
- 감수한 비용: 구조를 강제하지 않아 규칙이 없으면 스토어가 잡동사니가 됨 (→ [ARCHITECTURE.md](./ARCHITECTURE.md) "상태 위치 규칙"이 그 규칙)

- 서버 상태를 Zustand에 복사하지 않는다 — [ARCHITECTURE.md](./ARCHITECTURE.md)

### Bundler

- Next.js 프로젝트: **Turbopack** (내장) — 별도 번들러 없음
- React SPA: **Vite** — 빠른 HMR, 설정 최소. 버린 대안: webpack(설정 비용), Rspack(생태계)

### Tester

**Vitest** (러너)
- 이유: Vite 기반이라 SPA와 설정 공유, Jest 호환 API, 빠름
- 버린 대안: Jest — Vite 프로젝트에서 transform 설정 이중화
- 감수한 비용: 일부 생태계 도구가 Jest 전제

**React Testing Library**
- 이유: 역할(role) 기반 쿼리 — "테스트는 소프트웨어가 사용되는 방식을 닮을수록 좋다"(Testing Trophy). 구현이 아니라 동작을 검증하므로 리팩토링에 테스트가 안 깨짐
- 버린 대안: Enzyme류 구현 접근 — 리팩토링마다 테스트 수정
- 감수한 비용: role 없는 마크업은 테스트가 어려움 — 이건 비용이 아니라 접근성 결함의 조기 발견이라고 본다

**Playwright** (E2E) — 핵심 플로우만. 버린 대안: Cypress(멀티탭·병렬 제약). 비용: 실행 시간 → 개수 제한으로 관리

**MSW**
- 이유: 네트워크 경계(HTTP 레벨)에서 mock — fetch 함수 mock과 달리 실제와 같은 코드 경로를 테스트
- 감수한 비용: 핸들러 유지보수 — API 스펙 변경 시 함께 갱신 필요

### Lint / Format

- ESLint — [ARCHITECTURE.md](./ARCHITECTURE.md)의 import 단방향 규칙을 룰로 강제. "린트로 강제 못 하는 규칙은 리뷰 렌즈로"가 철학의 축
- Prettier — 스타일 논쟁 제거

### Utility

**es-toolkit**
- 이유: lodash 대비 2~3배 빠르고 최대 97% 작음. Storybook도 채택
- 버린 대안: lodash — 10년 전 설계(ESM·트리셰이킹 이전) / 직접 구현 — 엣지 케이스 비용
- 감수한 비용: 함수 커버리지가 lodash보다 좁음 (→ es-toolkit/compat으로 해소 가능)

**overlay-kit** — 모달·바텀시트 open/close 상태 관리 제거(선언적). 비용: 라이브러리 의존 하나 추가
**use-funnel** — 다단계 플로우를 한 파일에서 관리. 비용: 퍼널이 없는 프로젝트엔 불필요 — 필요할 때만
**suspensive** — Suspense 유틸. 비용: Suspense 미사용 프로젝트엔 불필요

### 추가하면 좋은 거

- React Compiler — 수동 memo/useMemo 제거. 비용: 컴파일러 규칙(Rules of React) 위반 코드에서 조용히 최적화 제외
- Zod — API 경계 런타임 검증 + 타입 추론. 비용: 스키마 이중 관리 (→ OpenAPI 코드젠과 결합해 완화)
