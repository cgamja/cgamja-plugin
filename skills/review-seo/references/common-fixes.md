# 자주 나오는 지적과 고치는 방향 (Next.js 정적 export 기준)

## 초기 HTML에 숨김 상태가 실림
motion/framer의 `initial={{opacity:0}}`은 서버 렌더에 inline style로 들어간다. `useReducedMotion()`은 서버에서 null이라 가드가 안 된다.
- Reveal류: 마운트 전(`useSyncExternalStore`로 만든 `useMounted`)에는 animate=보임, `initial={false}`. 숨김은 `<html data-motion="on">`(head 인라인 스크립트, reduced-motion이면 안 켬)일 때만 CSS `[data-reveal="out"]{opacity:0}`.
- 글자별 애니메이션: 마운트 전에는 평문 span 하나(`data-*="pending"`), 마운트 뒤 글자 span. sr-only 사본은 제거(문장 중복).
- 장식 SVG 안의 opacity:0은 남겨도 된다.
- 검색 엔진 렌더러는 긴 뷰포트 한 장으로 보고 스크롤하지 않으므로 `once:false`는 유지 가능. 바꾸는 건 사용자 결정.

## 폰트
- `next/font/google` 한글 계열은 unicode-range 조각을 전부 `<link rel=preload as=font>`로 낸다(수십~수백 KB, 최우선). `preload: false`.
- 외부 CDN CSS(jsdelivr 등)는 `<link rel="preconnect" crossOrigin="anonymous">`를 앞에. 자체 호스팅 전환은 LIBRARY 게이트 대상.
- `priority` 이미지는 실제 LCP 후보 하나만.

## 메타데이터 (Next App Router)
- `openGraph`·`twitter`·`alternates`는 깊은 병합이 아니다. 하위 페이지가 title만 주면 url·image·siteName이 루트(홈) 값으로 남는다 → 페이지마다 전부 채우는 헬퍼(`pageOpenGraph`).
- `not-found.tsx`에 `metadata`를 export해 `robots: noindex`, `alternates: {}`. 안 하면 홈 canonical·"index,follow"를 물려받는다.
- 동적 라우트의 빈 자리 페이지(coming-soon 등)도 독립 title/description/canonical.
- 한글 `<title>`은 20~24자 넘으면 SERP에서 잘린다. 문안 소유자에게.

## 스키마
- Organization: `logo`는 ImageObject(≥112px 정사각형), `alternateName`으로 다른 표기, `address`에 도시를 `streetAddress`와 중복 넣지 않기. `sameAs`는 사실이 있을 때만.
- BlogPosting: `image` 폴백(사이트 OG), `publisher.logo`, 보이는 빵부스러기가 있으면 `BreadcrumbList`.
- MobileApplication/SoftwareApplication: `featureList`·`screenshot`은 화면에 있는 문장·실제 스크린샷만. `aggregateRating` 지어내지 않기.
- FAQPage 리치 결과는 종료(2026-05). 새로 넣지 않는다. HowTo도.

## robots · sitemap · 헤더
- robots.txt의 `Host:`는 제거(Yandex 폐기, 스킴 붙으면 형식도 틀림). AI 검색 크롤러(OAI-SearchBot·Claude-SearchBot·PerplexityBot)와 네이버 Yeti는 명시 허용. 학습 전용 크롤러 허용 여부는 팀 결정.
- 정적 export는 `route.ts`의 Response 헤더를 버린다 → rss.xml MIME은 호스팅 헤더(netlify.toml `[[headers]]`).
- HSTS 추가. CSP는 인라인 스크립트(테마·모션 초기화·JSON-LD) 해시가 필요해 별도 작업.

## AI 검색(GEO)
- "X는 ~이다" 정의문이 페이지 어딘가에 있어야 인용된다. 디자인상 본문에 못 넣으면 `/llms.txt`(route.ts로 문안 파일에서 빌드)에라도.
- 회사명·브랜드명 표기를 하나로. 여러 개면 `alternateName`.
- 푸터 열 제목이 `<h2>`면 문서 개요를 오염시킨다 → `<p>` 또는 `nav aria-label`.
