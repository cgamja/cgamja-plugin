# 스킬 검증 — 4층 피라미드 (실측: Claude Code 2.1.239, 2026-08-22)

**원칙**: 스크래치 런은 검증의 기본값이 아니라 **탐색** 수단이다. 스킬(절차 문서 + 템플릿 + 훅)은 소프트웨어처럼 층을 나눠 검증하고, 비싼 층에서 찾은 결함은 즉시 싼 층의 케이스로 내려보낸다. 결정 근거·재검토 조건은 `adr/0013`.

## 1. 층과 메트릭

| 층 | 무엇을 | 비용/1회 | 시간 | 결정성 | 잡는 것 | 못 잡는 것 |
|---|---|---|---|---|---|---|
| **1 결정적** | `tests/run.sh`(훅·preflight·문서 경로) + frontmatter 린트 + **템플릿 스모크**(스캐폴드 → develop-setup 템플릿 적용 → `verify` 초록 + 위반 주입 빨강) | $0 | 수 초~3분 | 100% | 훅 로직, 템플릿 깨짐, 린트가 실제로 막는지, 깨진 링크 | 에이전트가 절차를 *따르는지* 전부 |
| **2 트리거** | positive·**근접 negative** 쿼리 → 스킬이 호출되나 | $0(TF-IDF) / ~$0.02~0.05/쿼리(`claude -p`) | 8회 28초(실측) | 낮음 — 3~5회 반복, **80% 임계** | description 누락·충돌, 잘못 뜨는 스킬 | 뜬 뒤 무엇을 하는지 |
| **3 행동 eval** | 프롬프트 → 격리 레포 실행 → 결정적 체크 우선, LLM 루브릭 보조, with/without 델타 | ~$0.5~3/케이스·회(추정) × 3~5회 | 3~10분/케이스 | 낮음 — **pass^k**(전부 성공)로 판정 | 절차 이탈(테스트 먼저 안 씀, `gen.ts` 손편집, 티어 판정 생략, 즉석 리뷰어) | "맞게 했지만 다르게 한" 경우, UX 품질 |
| **4 스크래치 런** | 실제 프로젝트에서 끝까지 + 사람 관찰 → `reports/` | $7.56/회(Tier-2 실측) + 사람 30분+ | 10분+ | n=1 | 사전에 assertion을 쓸 수 없던 것(린트 조용히 꺼짐, 훅 우회, 즉석 리뷰어) | 회귀 — 재현 불가 |

정확도의 뜻이 층마다 다르다: 1층은 정밀·재현 ~100%지만 범위가 좁고(알려진 실패 고정), 2·3층은 **분산**이 지배해 n=1은 신호가 아니며, 4층은 재현율이 가장 높지만 정밀도를 정의할 수 없다. 4층 1회 비용으로 3층 케이스 3개×3회를 돌릴 수 있고 후자만 회귀를 잡는다.

## 2. 변경 종류별 돌릴 층

| 변경 | 층 | 예상 비용 |
|---|---|---|
| 훅·템플릿·references 문구 | 1 | $0 |
| SKILL.md `description` | 1 + 2 (4스킬 × 10쿼리 × 3회) | ~$3~5 |
| `workflow.md`·SKILL.md 절차 | 1 + 3 (관련 케이스 2~3개 × 3회) | ~$5~15 |
| 새 스택·새 스킬·새 프로토콜 | 1 + 2 + 3 + **4를 1회** | ~$20 |
| 월 1회 드리프트(§6) | 1 + 3 전체 | ~$15~30 |

## 3. 도구 (실측)

| 도구 | 상태 | 비고 |
|---|---|---|
| `claude plugin eval` | **early access 게이트** — `init --bare`까지 "currently in early access" | 공식 포맷: `evals/<case>/prompt.md`(frontmatter: runs·max_turns·allowed_tools·model) + `graders/*.md`(`regex`/`tool_used`/`tool_order`/`file_exists`/`llm` 2-of-3/`baseline`), `--ablation with-without` 기본, `--max-cost-usd`, `--threshold`, HTML 리포트. **케이스는 이 포맷으로 쓴다** — 열리면 그대로 실행 |
| skill-creator `scripts/run_eval.py` (트리거) | 동작함, 단 **이 레포엔 부적합** | 임시 커맨드 `<skill>-skill-<id>`가 호출되는지 세는데 진짜 `cgamja:*`가 전역에 떠 있으면 모델이 진짜를 골라 항상 0. 쓰려면 플러그인 disable 후 실행. `python3 -m scripts.run_eval`(skill-creator 디렉터리에서 모듈로) |
| skill-creator 행동 eval (`evals/evals.json` + `agents/grader.md` + `aggregate_benchmark`) | 게이트 없음(서브에이전트 기반) | old-skill vs new-skill A/B, 블라인드 comparator, `benchmark.json` mean±stddev. `grading.json`은 `text/passed/evidence` 필드 고정 |
| 직접 `claude -p --output-format stream-json` + `Skill` 호출 grep | 동작함 | 3층 임시 러너의 뼈대. `env -u CLAUDECODE`로 세션 안에서 중첩 실행. `--model` 핀 필수 |

## 4. 케이스 작성 규칙
- **결정적 체크 먼저**: `file_exists openspec/changes/*`, `tool_used Skill(cgamja:test-fe)`, 커밋 메시지 `^test\(`·`^feat\(` 분리, `*.gen.ts` diff 없음. LLM 루브릭은 "시나리오가 스펙과 1:1인가"처럼 문자열로 못 잡는 것에만.
- **결과를 채점, 경로를 채점하지 않는다**: 툴 호출 순서 고정은 brittle. 순서가 규칙 자체인 것(테스트 커밋이 구현 커밋보다 먼저)만 `tool_order`.
- **판별력**: 스킬 없이도 통과하는 assertion은 정보량 0 — with/without 델타가 메트릭. 델타 0인 케이스는 더 어렵게 고치거나 삭제.
- **negative는 근접으로**: "git log 보여줘"는 무의미. "React Query와 SWR 차이"(설명 요청, 개발 아님) 같은 것.
- **스킬을 테스트, 모델을 테스트하지 않는다**: 모델이 원래 잘하는 것(버튼 하나 추가)은 케이스가 아니다. 스킬이 *바꾸는* 것(티어 판정·red 게이트·리뷰 렌즈)만.
- 20~50 케이스면 충분. 실제 실패(`reports/`, 4층)에서 뽑는다. 0% 통과는 모델 문제가 아니라 케이스 결함.
- 모델 핀: 2·3층은 `--model` 없이 돌린 숫자를 비교하지 않는다.

## 5. 트리거 실측 (2026-08-22, develop-fe)
"로그인 화면에 비밀번호 보기 토글 추가해줘" → sonnet·haiku 모두 답변에서 `cgamja:develop-fe`를 **정확히 지목**하지만, 원 쿼리 3턴 안에 `Skill` 호출 없이 Bash/Agent 탐색부터 시작(plan 모드, n=1). description은 맞고 **호출 타이밍**이 보장되지 않는다 — 2층 케이스 작성 시 이 쿼리를 첫 항목으로. n을 늘려 확인 전까지 결론 내지 않는다.

## 6. 드리프트 점검 (월 1회)
문서에 박힌 날짜 있는 사실(hey-api TS 6 충돌, Playwright CT 삭제, openapi-fetch 유지보수 모드, orval 8.24/msw 2.15/zod 4.4 검증)과 ADR "재검토 조건"을 대조한다: ① 고정 버전의 릴리스 노트, ② 재검토 조건 트리거 여부, ③ 3층 전체 1회. 산출물은 "재검토 필요 항목" 보고 — 절차 변경은 사람이 실측 후.

## 7. 흐름
4층에서 발견 → 결정적으로 잡히면 1층 케이스(훅 우회 사례: `sed -i`·인라인 `TDD_PHASE=` → `tests/test_setup_hooks.sh`), 아니면 3층 케이스 → 고친 뒤 그 케이스로 회귀 확인. `reports/`는 4층의 사람용 기록으로 유지하고, 숫자 비교는 3층 결과가 맡는다.

출처: Anthropic "Demystifying evals for AI agents"(pass@k vs pass^k, 경로 채점 경고) · anthropics/skills skill-creator · addyosmani/agent-skills `evals/`(TF-IDF rank-1 80% 바닥선) · obra/superpowers `docs/testing.md`(tests/ vs evals/ 분리, evals는 CI 밖) · OpenAI "Testing Agent Skills with Evals"(JSONL 결정적 체크 먼저) · mgechev "Unit Tests for AI Agent Skills"(≥5회) · philschmid(3~5회, 분포) · Skill Eval GitHub Action(80% 임계) · Scott Spence(250회 $5.59, LLM-eval 훅 거짓 양성 80%) · ETH AGENTS.md 연구(LLM 생성 지시문 −3%/비용 +20%, 2차 출처).
