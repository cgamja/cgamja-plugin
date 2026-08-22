# reports — 실제로 돌린 기록과 런 비교표

규약: 런 1회 = `<skill>_<날짜>[_tag].md`(템플릿 `TEMPLATE.md`). 결정은 여기서 하지 않는다 — 리포트가 근거, `adr/`의 "검증" 란이 결론, `references/`·스킬 본문이 현재 규칙. 리포트를 추가하면 아래 표에 **한 줄** 추가한다(벤치마킹표의 "내 것" 열이 된다).

## 런 비교표
| 날짜 | 런 | 스킬 | 세션 모델 | 구조 | 비용 | 시간/메시지 | 핵심 결과 | 리포트 |
|---|---|---|---|---|---|---|---|---|
| 2026-08-21 | setup (Vite) | develop-setup | fable | 단일 스킬 | $? | — | 경계 린트 조용히 꺼짐 발견 | [develop-setup](develop-setup_2026-08-21.md) |
| 2026-08-21 | Tier-1 | develop-fe | fable | 단일 스킬 | $? | — | Bash로 테스트 파일 보호 우회됨 → 훅 강화 | [tier1](develop-fe-tier1_2026-08-21.md) |
| 2026-08-21 | Tier-2 todos 목록+추가 | develop-fe | fable | 단일 스킬, 즉석 리뷰 Agent | $7.20 | 8.5분/47턴 | 리뷰가 orval baseUrl 결함 잡음; red 게이트가 headless에서 막힘 | [tier2](develop-fe-tier2_2026-08-21.md) |
| 2026-08-21 | setup (Vite+TanStack, web-mobile) | develop-setup | fable | 분리 구조 | $7.56 | 9.8분/47턴 | 전항목 ✅, 템플릿 결함 4건 | [restructured](develop-fe-tier2_2026-08-21_restructured.md) |
| 2026-08-21 | Tier-2 #1 목록+추가 | develop-fe + test-fe + review-fe | fable | persona 6 + ce-code-review | $33.07 | 40분/192msg | L5가 뷰포트 누락 잡음; 본체 79% | [restructured](develop-fe-tier2_2026-08-21_restructured.md) |
| 2026-08-21 | A/B L1·L2 | review-fe persona 단독 | opus vs fable | — | $6.55 | — | fable이 opus 놓친 blocker 0 → opus 유지 | [restructured](develop-fe-tier2_2026-08-21_restructured.md) |
| 2026-08-21 | Tier-2 #2 토글+필터 | develop-fe + test-fe + review-fe | fable | persona만 | $45.65 | 52분/269msg | 버그 2·판별 불가 테스트 2 잡음; ce-code-review 없이 품질 유지 | [restructured](develop-fe-tier2_2026-08-21_restructured.md) |
| 2026-08-21 | Tier-2 #3 삭제+되돌리기 | develop-fe + test-fe + review-fe | **opus** | persona만 | $44.88 | ~50분/357msg | "세션 opus=절반" 기각; 비용 = 절차 부피 | [restructured](develop-fe-tier2_2026-08-21_restructured.md) |
| 2026-08-22 | setup (brownfield **Vue 3**, 타사 레포) | develop-setup(adr/0014) | sonnet | 발견·대조·최소 제안 | $2.42 | 11.4분/89턴 | 스택 변경 0, a11y 린트 무력화 발견, smoke 오탐 3건→수정 | [brownfield-vue](brownfield-vue_2026-08-22.md) |

## 스크래치 프로젝트
`~/cgamja-scratch/todos-app` — 2026-08-21 런 4개가 쌓인 Vite+TanStack 프로젝트(51커밋, 브랜치 `feat/todos-list-create`, change 3개 archive). 다음 Tier-2/Tier-3 실험의 베이스. 런 원본 JSON·프롬프트·A/B 스크립트는 `~/cgamja-scratch/logs/`.

## 읽는 법
- 비용은 `claude -p --output-format json`의 `total_cost_usd`, 모델별 분해는 `modelUsage`.
- "메시지"는 트랜스크립트의 assistant 메시지 수(`num_turns`는 세그먼트 단위라 신뢰하지 않는다).
- 같은 스크래치(`todos-app`)에서 change를 쌓아 가며 돌린 런은 **앞 런의 결함 수정이 뒤 런에 전이**된다(예: #1의 L5 지적 → #2·#3은 처음부터 4뷰포트). 비용 비교 시 change 크기 차이를 감안한다.
