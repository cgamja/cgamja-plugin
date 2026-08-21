# 0001. 도메인 구조 — bulletproof-react features + FSD 세그먼트, 도메인 간 import 기본 금지
- 상태: 채택
- 날짜: {{DATE}}

## 규칙 (린트 `eslint.config.*`의 boundaries 정책과 1:1)
- `src/shared/**` → `src/domains/**`, `{{ROUTER_DIR}}` import 금지
- `src/domains/<a>` → `src/domains/<b>` **기본 금지**. 허용 엣지는 아래 표와 린트 설정에 동시에 추가한다
- `{{ROUTER_DIR}}` → 도메인은 `index.ts`로만. 아무도 `{{ROUTER_DIR}}`를 import하지 않는다
- 도메인 내부는 상대경로. 자기 `index.ts` 경유 금지(순환·HMR)
- 배럴은 도메인당 `index.ts` 1개. named export만, `export *` 금지. `shared`에 layer 배럴 없음(`shared/ui/<mod>/index.ts`만)
- 한 라우트만 쓰는 UI는 그 도메인에 둔다. 화면 하나 때문에 도메인을 만들지 않는다
- 파일 ≤ {{MAX_LINES}}줄. 넘으면 분리

## 허용된 도메인 간 엣지
| from | to (index.ts만) | 이유 | 날짜 |
|---|---|---|---|
| (없음) | | | |

3개째 엣지가 필요해지면 `widgets/` 층 추가를 새 ADR로 검토한다.

## 프레임워크 매핑
{{ROUTER_NOTE}}
{{RSC_NOTE}}

## 왜
- FSD 2.1 자체가 "pages부터, 거기서 멈춰도 됨". 솔로·단기엔 풀 FSD 비추(FSD 블로그). 이 구조는 bulletproof-react `features/` + FSD 세그먼트명 + public API
- 에이전트 코드베이스의 실증된 실패는 층 위반이 아니라 **의미적 중복**(사람의 1.87배)과 상태 sprawl → 경계 린트 + jscpd + "만들기 전 grep"
- 아키텍처는 spec(행동)이 아니라 여기+린트에. OpenSpec `design.md`는 archive 때 버려진다
- 근거 리서치: cgamja `skills/develop-fe/references/verdicts-2026-08-21.md` ④, `adr/0006`
