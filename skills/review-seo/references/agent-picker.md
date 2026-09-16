# claude-seo 렌즈 고르기

에이전트 이름은 `claude-seo:<name>` 으로 Agent 도구의 subagent_type에 넣는다. 스킬(seo-page·seo-audit·seo-plan·seo-cluster·seo-hreflang·seo-images·seo-competitor-pages·seo-content-brief·seo-programmatic)은 Skill 도구로 부른다. `seo-audit` 스킬은 15개까지 병렬 위임하는 전체 감사라 사이트가 수십 페이지 이상일 때만.

## 항상 후보

| 에이전트 | 보는 것 | 넘겨야 할 것 |
|---|---|---|
| `seo-technical` | robots·sitemap·canonical·trailing slash·404·메타 길이/중복·H1·OG/Twitter·이미지 속성·렌더 차단 리소스·보안 헤더·번들 크기 | 페이지 경로 목록, 메타/sitemap/robots 소스 파일, 의도된 것(빈 alt, null 링크, 인라인 스크립트, 단일 언어) |
| `seo-schema` | JSON-LD 타입·필수 속성·중복·폐기된 타입(HowTo·FAQ 리치 결과)·기회(Breadcrumb·publisher.logo·image 폴백) | 스키마를 내는 파일 경로, 사실값 파일(지어내면 안 되는 값 명시) |

## 상황별

| 상황 | 에이전트 | 특히 |
|---|---|---|
| 브랜드가 일반 명사 · AI 답변 인용이 목표 · 정의문이 없음 | `seo-geo` | 인용 가능 문단, 엔티티 일관성(회사명 여러 개), 크롤러 허용, llms.txt, 초기 HTML에서 글이 보이는지 |
| 움직임·폰트·이미지·번들 변경 뒤 | `seo-performance` | LCP 후보와 경쟁 리소스(프리로드 폭주), 렌더 차단 CSS, DOM 노드 수(글자별 span), CLS. Playwright 경로를 알려주면 실측한다 |
| 글 많은 페이지 | `seo-content` | E-E-A-T, 얇은 콘텐츠, 가독성, 날짜 신호 |
| 첫 화면·모바일 | `seo-visual` | Playwright 스크린샷, above-the-fold |
| 매장·지역 | `seo-local`, `seo-maps` | NAP, GBP, LocalBusiness |
| 상품 | `seo-ecommerce` | Product 스키마, 가격, 재고 |
| 다국어 | `seo-hreflang`(스킬) | hreflang 쌍 |
| 백링크·경쟁 | `seo-backlinks`, `seo-competitor-pages`(스킬) | 외부 API 키 필요할 수 있음 |
| 재감사 | `seo-drift` | 첫 감사 때 기준선을 저장해 뒀을 때만 |
| 실측 데이터(CrUX·GSC·GA4) | `seo-google`, `seo-dataforseo` | 인증·API 키 필요. 배포 전 로컬 감사에는 무의미 |

## 프롬프트에 넣을 것 (예)

```
Audit <lens> of a Korean static site served at http://localhost:3100/ (static export of https://example.com,
NOT deployed there yet — use curl on localhost only). Source: /path/to/repo (metadata in src/app/layout.tsx, ...).
Pages: / , /blog/ , /404.html , /robots.txt , /sitemap.xml
Known constraints (do not flag): App Store link is intentionally null; decorative images have empty alt;
theme init inline script is intentional; single language so no hreflang.
Copy rules any suggested wording must respect: <규칙>.
Output: prioritized findings (Critical/High/Medium/Low) with evidence (URL + what you saw) and the exact fix
with the source file to change. Do not modify files.
```

한 메시지에 여러 Agent 호출을 넣어 병렬로 돌린다. 각 에이전트는 자기 파일을 고치지 않게 "Do not modify files"를 꼭 넣는다.
