# 0006. 아키텍처 = bulletproof-react features + FSD 세그먼트; 도메인 간 import 기본 금지; ADR+린트에 둔다
- 상태: 제안
- 개정(2026-08-22, adr/0014): bulletproof-react+FSD 구조는 greenfield 기본값(`references/project-conventions.md` §6). brownfield는 기존 구조를 `domains.root`로 선언하고 경계 원칙만 린트로 건다.
- 날짜: 2026-08-21
- 검증: (없음)

## 맥락
`references/verdicts-2026-08-21.md` ④. FSD 2.1은 "pages부터, 거기서 멈춰도 됨"으로 이동했고 FSD 블로그는 솔로·단기에 풀 FSD 비추. 이전 안("도메인 vertical + FSD 규칙 2개")의 실체는 bulletproof-react `features/` + FSD 세그먼트명 + public API다. 이전 안의 "도메인→도메인은 index.ts로 허용"은 FSD·bulletproof 둘 다 기본 금지하는 규칙을 완화한 것이라 가장 먼저 무너진다. `boundaries/entry-point`는 v7에서 deprecated. Next에서는 `src/app`이 라우터 폴더. 에이전트 코드베이스의 실증된 실패는 층 위반이 아니라 **의미적 중복(1.87배)·상태 sprawl**. 폴더 구조가 에이전트 정확도를 올린다는 통제 벤치마크는 없다 — 주장하지 않는다.

## 결정
1. 레이아웃: `src/app`(Next: 라우터 폴더·한 줄 re-export / Vite: 부트스트랩), `src/routes`(Vite+TanStack만, 평면), `src/domains/<name>/{ui,model,api,index.ts}`, `src/shared/{ui/<mod>/index.ts, lib, config}`.
2. 규칙: shared→domains 금지 / **도메인→도메인 기본 금지, 허용 엣지는 린트 설정+이 ADR에 명시** / app·routes→domains는 index.ts만 / 도메인 내부 상대경로 / 한 라우트용 UI는 그 도메인에.
3. 배럴: 도메인당 `index.ts` 1개, named export만, `export *` 금지, shared·layer 배럴 없음, `import-x/no-cycle`.
4. 도구: eslint-plugin-boundaries 7.x(`dependencies`+`no-unknown-files`, 에러 메시지에 고치는 법) PostToolUse에서; dependency-cruiser는 CI 선택; steiger·sheriff 불사용.
5. 센서: `max-lines` 300~400, jscpd, colocated 테스트, "만들기 전 grep" 규칙, LSP 플러그인.
6. 아키텍처는 `docs/adr/0001-domain-structure.md`(프로젝트 쪽) + 린트. OpenSpec spec·design.md에는 ADR 번호만.
7. `widgets/` 층 추가 트리거 = **허용 엣지 3개째**.

## 전제
- 솔로 MVP, 도메인 3~8개. 도메인 간 데이터 의존이 드묾(auth 정도).
- React. Next면 RSC 경계는 린트 불가 → 리뷰 항목.

## 재검토 조건
- 허용 엣지가 3개 → widgets/ 층 ADR.
- 같은 기능을 두 도메인이 중복 구현한 사례 2회(jscpd 검출) → 해당 코드를 shared로 올리는 규칙 또는 도메인 병합.
- 도메인이 10개 넘음 → FSD pages 층 도입 검토.
- Next가 `src/app` 외부 라우팅을 지원 → 조립층 분리 재검토.

## 결과 / 영향
- `project-conventions.md` §2 개정(이름, 기본 금지, boundaries v7 설정, 프레임워크 매핑, 센서).
- 새 도메인 간 import가 필요할 때마다 린트 설정+ADR 두 곳 수정 — 의도된 마찰.
