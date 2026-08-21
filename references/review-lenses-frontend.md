# 리뷰 렌즈 — 티어별로 무엇을 누가 보나 (`adr/0012`)

**원칙**: 리뷰는 "잘 봐줘"가 아니라 **렌즈 목록**이다. 렌즈 하나 = persona 파일 하나(`agents/reviewer-*.md`) = 새 컨텍스트의 서브에이전트 하나. 티어가 렌즈 개수를 정하고, 모델은 `model-routing.md`가 정한다. 실행은 `review-fe` 스킬. 스타일 지적은 어느 렌즈에도 없다 — 린트가 한다.

## 1. 렌즈 목록
| # | 렌즈 | persona | 보는 것 | 보지 않는 것 |
|---|---|---|---|---|
| L1 | **정확성·중복** | `reviewer-correctness` | 로직 오류, 경계 조건, 비동기 경쟁, 상태 이중화, **같은 기능의 기존 컴포넌트/유틸이 있는데 새로 만든 것**(에이전트 1위 실패), 새 의존성 | 네이밍, 포맷, "더 나은 패턴" |
| L2 | **스펙 완전성** | `reviewer-spec` | `spec.md`의 각 `### Requirement`/`#### Scenario` ↔ 코드·테스트 1:1 대조. 빠진 시나리오, 스펙에 없는 동작(scope creep), 빈·로딩·에러 상태 | 구현 방식 |
| L3 | **테스트 무결성** | `reviewer-tests` | `feat` diff에 `*.test.*` 섞임, assertion 약화·skip·`expect(true)`, mock 수·대상(자식 컴포넌트·React 내부 mock), `getByTestId` 남용, "각 assertion이 명백히 틀린 구현을 구분하는가" | 커버리지 숫자 |
| L4 | **접근성** | `reviewer-a11y` | `a11y-frontend.md` §2 체크 + axe 결과 존재 여부 + 라벨 품질(동작 이름인가) | 디자인 취향 |
| L5 | **플랫폼 적합성** | `reviewer-platform` | `.claude/rules/platform.md` 프로필 대비: 뷰포트 증거 전부 있나, 안전영역·키보드·터치 타깃·다크모드, `px`/`100vh`/hover-only | 픽셀 단위 Figma 차이(그건 SSIM 단계) |
| L6 | **경계·계약** | `reviewer-architecture` | 도메인 간 import(린트 통과했어도 `index.ts` 우회·`shared` 오염), `src/api/*.gen.ts` 외 fetch/타입, 스펙에 없는 필드, 상태 위치(로컬/서버/URL) 규칙, 토큰 외 색·간격 | 폴더 취향 |
| L7 | **성능** | `reviewer-performance` | 목록 가상화, 불필요한 클라이언트 컴포넌트(Next), 이미지 최적화, 번들에 새로 들어온 큰 의존성, 워터폴 fetch | 마이크로 최적화(useMemo 남발 권고 금지) |

## 2. 티어 → 렌즈
| 티어 | 렌즈 | 형태 |
|---|---|---|
| Tier-1 | L1만 | persona 1개, 짧게. 스펙이 없으니 L2 없음 |
| Tier-2 | L1 L2 L3 + (UI task 있으면 L4 L5) + (API 걸리면 L6) | persona 병렬만 (adr/0012 개정 1 — `ce-code-review`는 안 부른다) |
| Tier-3 통합 | L1~L7 전부 | change 전체 diff. L2는 archive된 `openspec/specs/` 기준. `ce-code-review`(스펙 경로 조립) 병행 선택 |
| PR 리뷰(남의 PR) | L1 L3 L4 L5 + PR 본문 What/Why를 스펙 대용으로 L2 | `gh pr diff`. 스펙 없으면 L2는 "PR 본문 주장 ↔ diff" 대조 |
| 버그 수정(`ce-debug` 경로) | L1 L3 + 회귀 테스트 존재 | — |

## 3. 티어 → 모델 (`model-routing.md`)
| 렌즈 | Tier-1/2 | Tier-3 · PR |
|---|---|---|
| L1 L2 L3 | `opus` (A/B 2026-08-21 확정) | `fable` (**미검증** — Tier-3 A/B 전까지 가설) |
| L4 L5 | `sonnet` | `sonnet` |
| L6 L7 | `opus` | `opus` |

## 4. 출력 계약 (모든 persona 공통)
```
## <렌즈 이름> — <심각도별 개수: blocker n · should n · nit n>
| # | 심각도 | 파일:줄 | 문제(한 문장) | 근거(스펙 시나리오/규칙/파일) | 제안 |
- 스타일·네이밍은 쓰지 않는다. 확신 없으면 "확인 필요"로 표시하고 무엇을 돌려보면 판정되는지 적는다.
- 없으면 "없음"이라고 한 줄. 칭찬 금지.
```
`review-fe`가 표를 합치고 중복(같은 파일:줄)은 하나로, blocker가 하나라도 있으면 "반영 후 재실행"을 지시한다.

## 5. 재검토 조건
- 어떤 렌즈가 3개 change 연속 "없음" → 그 렌즈는 Tier-3에서만
- 두 렌즈가 같은 지적을 반복 → 합친다
- 렌즈 지적이 린트로 잡을 수 있는 것이었음 2회 → 린트 규칙으로 승격하고 렌즈에서 뺀다
- 리뷰 비용이 구현 비용을 넘는 change 2개 → Tier-2 기본 렌즈를 L1 L2 L3로 줄이고 나머지는 UI/API 조건부 유지
