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
| 2026-08-22 | Tier-1 (brownfield Vue 3, 테스트 환경 버그) | develop-fe(adr/0014) | sonnet | 선언 기반 훅 | $0.74 | 3.5분/25턴 | 근본 원인·1파일 수정·verify 63/63·테스트 파일 무편집 | [brownfield-vue](brownfield-vue_2026-08-22.md) |
| 2026-08-26 | retro (~/app SIM-141·SIM-139 세션 3개, 0017~0022 이전 수행분) | retro-fe(adr/0022) | fable + sonnet×3 | 세션당 분석 병렬 | $? | 감사 대상 7.7h | ask 87회→0018 사후 검증, CI 5라운드 미수렴 원인 규명, 훅 오탐 12회 중 2계열 잔존, ADR 후보 3 | [retro](retro-2026-08-26.md) |
| 2026-08-27 | retro (~/app SIM-145 세션 4개) | retro-fe(adr/0022) | fable + sonnet×4 | 세션당 분석 병렬 (서브 합 ≈350k) | $? | 감사 대상 2.4h | 마찰 70%가 훅 오탐(advisory 스팸 31회·오탐 deny 3·Stop 훅 스펙 불일치), raw Agent 리뷰 누적 4회 → 가드 하드화 후보, CI 루프 규모 게이트 후보, ADR 후보 5 | [retro](retro-2026-08-27.md) |
| 2026-08-27 | retro_audit (~/app 세션 4개 + 코드 감사 입력 통합 — ee7057d9·779c0f99·3b8e·0101 재집계) | retro-fe(adr/0022) | fable + sonnet×4 | 세션당 분석 병렬(서브 ≈361k) + 당일 코드 감사(렌즈 4, ≈490k)를 회고 입력으로 | $? | 감사 대상 ≈7.9h | 훅 오탐 deny 12/17(3회째 지속)·증거 국면 실측 ≈$11~14/세션(주범=운전 루프)·커밋 초과 3회째(원인 상이)·스킬 사각지대 3종(실패 의미론 스펙 부재→⛔ 2건 통과, diff 렌즈의 전역 일관성 한계, L1 React 관용구 미검출)·선행 리포트 정정 2(779c 제외 오판·advisory 귀속 오류), ADR 후보 8(보강 3·신규 5) | [retro_audit](retro-2026-08-27_audit.md) (부록: [계약](retro-2026-08-27_api-contract-sync.md)·[779c](retro-2026-08-27_779c0f99.md)·[0101](retro-2026-08-27_0101f9e8-full.md)) |

| 2026-08-31 | retro (~/skill-test 세션 2개 — setup + change 2건을 한 세션에서) | retro-fe(adr/0022) | opus + sonnet×2 | 세션당 분석 병렬 | $? | 감사 대상 2.9h | 훅 오탐 4+과잉1(**4회차**, 전부 문자열 매칭 계열: heredoc 본문·`2>&1`·프로젝트 밖 경로), 공허한 가드 3~4건("초록을 보고 통과라고 믿음"), bypass 세션에서 red 게이트 무력화를 늦게 발견해 되물음 2회, 커밋 초과 2회(11·16 — 원인은 리뷰 라운드 분리 커밋), code-review 지적 12건 전원 a11y·로직 0, ADR 후보 4 | [retro](retro-2026-08-31.md) |
| 2026-08-31 | retro_evening (~/skill-test 하루 전체 재집계 — 세션 4개/로그 5개) | retro-fe(adr/0022) | opus + sonnet×3 | 세션당 분석 병렬 | $72.08(저녁만) | 감사 대상 8.4h | **"병렬 세션 2개" 오판 정정**(밀리초 동일 커밋·sessionKind:bg → 같은 스트림 이중 로그, 하루 완전 직렬), 시간 분해 = 사람 대기 181m(36%)·서브에이전트 25m·실작업 286m, **110분 정지 후 사용자 답변 2건 모두 "네가 알아서 해"**(차단형 질문이 최대 병목), review_nudge 오탐/미탐이 한 원인에서 나옴을 소스로 확정(예외목록에 reviewer-correctness 누락 — **오탐 5회차**, 누적 10), 리뷰 축 침식(review-cgamja 스킬 경유 1/3), 커밋 초과 3회차, 병렬 세팅 전무(worktree 0·포트 미분리), ADR 후보 5 | [retro_evening](retro-2026-08-31_evening.md) |

## 스크래치 프로젝트
`~/cgamja-scratch/todos-app` — 2026-08-21 런 4개가 쌓인 Vite+TanStack 프로젝트(51커밋, 브랜치 `feat/todos-list-create`, change 3개 archive). 다음 Tier-2/Tier-3 실험의 베이스. 런 원본 JSON·프롬프트·A/B 스크립트는 `~/cgamja-scratch/logs/`.

## 읽는 법
- 비용은 `claude -p --output-format json`의 `total_cost_usd`, 모델별 분해는 `modelUsage`.
- "메시지"는 트랜스크립트의 assistant 메시지 수(`num_turns`는 세그먼트 단위라 신뢰하지 않는다).
- 같은 스크래치(`todos-app`)에서 change를 쌓아 가며 돌린 런은 **앞 런의 결함 수정이 뒤 런에 전이**된다(예: #1의 L5 지적 → #2·#3은 처음부터 4뷰포트). 비용 비교 시 change 크기 차이를 감안한다.
