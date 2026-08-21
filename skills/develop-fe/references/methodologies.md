# 방법론 리서치 요약 (2026-08-21)

develop-fe 스킬 설계 근거. 원문 링크는 각 항목에. 결론은 맨 아래.

## 1. 공통 분모 — 2025~26 방법론들은 결국 같은 5가지 동작으로 환원된다
1. **의도를 글로 된 스펙/플랜으로** (WHAT·결정 기록. HOW·코드 시그니처는 쓰지 않는다 — 스펙 오류가 구현으로 전파되는 걸 막기 위해)
2. **편집 전에 계획** — 단, "diff를 한 문장으로 설명할 수 있으면 계획을 건너뛴다" (Anthropic best practices)
3. **에이전트가 직접 돌릴 수 있는 체크를 먼저 정한다** (test / tsc / lint / 스크린샷 비교). 체크가 없으면 "된 것 같음"이 유일한 신호가 된다
4. **작성자와 검증자를 분리** — 새 컨텍스트의 리뷰어 서브에이전트. 자기 채점은 부풀려진다
5. **컨텍스트를 작게** — 진입 파일(CLAUDE.md/AGENTS.md) ~100줄 이하 목차, 상태는 디스크(plan/progress 파일/git)에, 실패 2회면 `/clear`

브랜드 차이는 **의식(ceremony)의 양**과 **에이전트 수**뿐이다.

## 2. 각 방법론 한 줄 평
| 방법론 | 가져갈 것 | 버릴 것 / 한계 |
|---|---|---|
| **SDD — OpenSpec** | `changes/<name>/{proposal,design,tasks}.md` + **delta spec**(ADDED/MODIFIED/REMOVED) → archive 시 본 spec에 병합(반-living spec) | 기본 스키마는 4개 아티팩트 고정 — 단 1.10은 로컬 스키마로 줄일 수 있음(§5). 살아있는 스펙의 가치는 미검증 |
| SDD — spec-kit / Kiro | Kiro **Quick Spec**(질문→한 번에 생성, 게이트 없음), bugfix spec(현재/기대/불변 동작) | 버그 하나에 "4 user story, 16 AC"(Böckeler). 2000줄 마크다운 바다. spec rot. 에이전트는 어차피 steering 무시하고 컴포넌트 중복 생성(Teo) |
| **Compound Engineering** | Lightweight/Standard/Deep 티어, 플랜은 "가드레일이지 안무가 아님", `docs/solutions/` 환류, **blindspot pass**(모르는 영역 결정 지도 3~7개) | 30+ 스킬, 14개 리뷰어 병렬 → 토큰. 이미 플러그인 설치돼 있으니 **재구현 말고 호출**하면 됨 |
| **Harness Eng. (OpenAI/Anthropic)** | 짧은 AGENTS.md + docs/가 진실, **린트 에러 메시지에 고치는 법을 박아** 에이전트에게 주입, 플랜 크기를 작업에 맞춤(ephemeral vs execution plan), `init.sh`+`progress` 파일, **한 세션 한 기능**, "실패하면 더 노력시키지 말고 빠진 도구/가드레일을 추가" | 팀·장기 자율 실행용. 솔로 초기엔 doc-gardening 에이전트 같은 건 과함 |
| **Loop Eng. (Ralph)** | 한 루프 한 작업, 빌드/테스트는 서브에이전트 1개만(back-pressure), "구현 안 됐다고 가정 말고 먼저 검색" | 종료 조건 없음, 실패 기억 없음, 기존 코드베이스엔 Huntley 본인도 비추. **UI는 컴파일이 보상이 될 수 없음** |
| fix-until-green | PASS_TO_PASS 유지, 테스트 파일 수정 금지, diff 예산, "테스트 통과시켜"가 아니라 "실패한 assertion 원문 + 목표"로 steer | 테스트 삭제/skip/tolerance 완화/`if NODE_ENV==='test'` 같은 reward hacking 실증됨(EvilGenie) |
| autoresearch | 메트릭 하나 + keep/revert 래칫 | seed 바꿔 점수 올림, 노이즈 플로어. 앱 개발엔 **측정 가능한 단일 지표가 있을 때만**(번들 크기, LCP, a11y 위반 수) |
| **EDD** | "프론트는 오라클이 없다" → 사람 눈을 **실행 가능한 그레이더**로 바꾸는 것: ① 결정적(tsc/lint/axe/overflow/console error) ② 행동(Playwright goal run, 별도 verifier) ③ 루브릭(LLM judge, 비쌈·노이즈) 순서로 계층화. 에이전트는 "됐다"가 아니라 **산출물(스크린샷 경로, 테스트 출력)**을 내야 함 | judge는 "망가졌나"는 답해도 "좋은가"는 못 답함. 취향은 사람 |
| **Graph Eng.** | 한 가지 휴리스틱만: "B가 A의 출력을 읽나? 아니면 병렬" — epic 분해할 때 | 서브에이전트+task 의존성의 리브랜딩. 멀티에이전트 그래프는 토큰 ~15x. 프론트 기능은 대부분 순차(타입→컴포넌트→테스트) |
| Context Eng. | 위 5번 | 방법론이 아니라 위생 규칙 |
| AI-DLC(AWS) / BMAD / Agent OS / Intent-driven | "구현 전 질문" 정도 | 팀 의식, 롤플레이, 이미 OpenSpec/CE와 중복 |
| Worktree 병렬 | epic에서 독립 슬라이스 2개 이상일 때만 | 프론트 특유: dev 서버 포트 충돌, node_modules 중복(9.8GB/20분 사례) |
| Stacked PR | 400줄 넘는 레이어 diff일 때만 | 솔로는 리뷰어가 없어 자기 문서화 이상의 가치 없음 |
| 적대적 리뷰 패널 | 새 컨텍스트 리뷰어 **1명**, "스타일 말고 정확성·요구사항 갭만 보고" | "갭 찾으라면 항상 찾는다" → 과잉 설계. 3명이 5명보다 낫다는 연구(arXiv 2608.18167). 패널은 러버스탬프 증거 보일 때만 |

출처: OpenSpec https://openspec.dev/docs/the-workflow · Böckeler https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html · INNOQ https://www.innoq.com/en/blog/2026/04/versteckte-kosten-spec-driven-development/ · CE https://github.com/EveryInc/compound-engineering-plugin · OpenAI harness https://openai.com/index/harness-engineering/ · Anthropic harness https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents · Anthropic best practices https://code.claude.com/docs/en/best-practices · Ralph https://ghuntley.com/ralph/ · EvilGenie https://arxiv.org/html/2511.21654v2 · Graph eng skill https://github.com/VineeTagarwaL-code/graph-engineering · Osmani 80% https://addyo.substack.com/p/the-80-problem-in-agentic-coding

## 3. 프론트엔드 특화 — 에이전트가 UI를 검증하게 만드는 법
- **브라우저 도구**: "드라이브"는 `agent-browser`(Vercel, 토큰 최저, 세션 분리, 뷰포트별 스크린샷) 또는 Playwright CLI, "디버그"는 Chrome DevTools MCP(콘솔/네트워크/perf). Next 16.3+면 `next-dev-loop` 스킬이 둘 다 묶음.
- **컴포넌트 테스트**: Vitest Browser Mode(인터랙션·레이아웃 — 2026 재검증으로 기본값, `tdd-frontend.md`) / jsdom(훅·로직만) / MSW(네트워크 경계에서만 mock). `toMatchScreenshot()`은 디자인시스템 프리미티브 몇 개에만, 요소 단위로.
- **a11y**: `@axe-core/playwright`(wcag2a/2aa) — violations는 블로킹, incomplete는 사람 큐. 다이얼로그엔 `toMatchAriaSnapshot`.
- **TDD for UI**: 역할/라벨로 쿼리, `userEvent`, 자식 컴포넌트 mock 금지. **빨간 불을 먼저 보여주게** 할 것 — 에이전트는 사람보다 mock을 많이 쓴다(36% vs 26%), 동어반복 테스트는 Stryker로.
- **디자인 시스템 준수는 프롬프트로 안 됨**(Builder.io): 모델은 지시보다 주변 예시를 따른다 → `no-restricted-imports`, `eslint-plugin-better-tailwindcss`(no-unknown/no-conflicting classes), Deslint `no-arbitrary-colors`, 컴파일되는 `examples/` 폴더. Figma MCP `get_design_context`는 `leading-[22.126px]` 같은 임의값을 뱉으니 "토큰 먼저 추출" 단계를 분리.
- **훅 분담**: `PostToolUse(Write|Edit)` → 해당 파일 format+lint, 배치마다 `tsc --noEmit`, `Stop` → `vitest run`, `PreToolUse` → package.json/lockfile/린터 설정 수정 차단.
- **대표 실패 모드**: 컴포넌트 중복(PricingCardV2), 상태 3곳 중복, 임의 색/간격, 반응형 깨짐(모델은 렌더를 못 봄 → 375/768/1280 스크린샷 필수), 기존 컴포넌트 무시, 과잉 mock, 의미 없는 e2e("page loaded"), a11y 카고컬트(`role` 남발), healer가 assertion을 바꿔서 "고침".
- 빌려올 것: Vercel `agent-skills`(react-best-practices, web-design-guidelines), Anthropic `frontend-design` 플러그인, Storybook MCP(컴포넌트 10개 넘으면), everything-claude-code `react-testing` 스킬, Knip.

## 4. 결론 → workflow.md에 반영한 것
- 티어는 **작업량이 아니라 불확실성·파급 범위**로 자른다. 티어 판정 자체가 비용이면 안 된다.
- Tier-1은 아티팩트 0개. Tier-2는 OpenSpec change 하나. Tier-3만 brainstorm/blindspot → 스펙 → 세션 분리.
- 모든 티어 공통: **체크 먼저 정의 → 빨간 불 확인 → 구현 → 증거 제출**. 프론트는 스크린샷이 테스트의 일부.
- OpenSpec이 스펙·tasks 척추, CE는 주변부(ce-brainstorm, ce-code-review, ce-simplify-code, ce-compound, ce-commit-push-pr, ce-debug). `ce-plan`/`ce-work`는 `opsx:propose`/`apply`와 자리가 겹쳐 미사용(adr/0001). 재구현 금지.
- 규칙은 프롬프트가 아니라 훅·린트로. 에이전트가 규칙을 어기면 "더 강하게 지시"가 아니라 가드레일을 추가한다(OpenAI).

## 5. 직접 설치해서 본 것 (2026-08-21, 스크래치 프로젝트)
| 도구 | 확인 | 가져간 것 |
|---|---|---|
| **OpenSpec 1.10.0** | `init --profile core` → 커맨드 6개(propose/apply/archive/explore/sync/update), 스킬 6개. `schema fork spec-driven <name>` 로 프로젝트 로컬 스키마, **specs+tasks 2개로 줄인 스키마 `schema validate` 통과, `new change --schema` 동작**. `config.yaml`에 `context`/아티팩트별 `rules`/`operations.{apply,archive}.guidance`. `validate --strict`, `skip_specs`. `status`는 파일 존재만 봄 | 척추로 채택. 티어=스키마. 설정은 `openspec-setup.md` |
| **spec-kit** (main) | 템플릿 14개 3,028줄, 커맨드 10개(constitution/specify/clarify/plan/checklist/tasks/analyze/implement/converge/taskstoissues), 스펙마다 브랜치 생성, user story별 P1/P2 + "Independent Test" | `clarify`(최대 5문, 답을 스펙에 기록), `converge`(스펙↔코드 갭 → tasks append), `[NEEDS CLARIFICATION]` 마커 |
| **BMAD** (main) | `src/` md 182개, 모듈·에이전트·party-mode. `quick-dev`는 deprecated → `bmad-build` | 없음 |
| **Agent OS** (main) | 커맨드 5개(plan-product/shape-spec/discover-standards/index-standards/inject-standards). shape-spec은 plan mode 강제 | shape-spec 질문 2개: "참고할 비슷한 코드?", "목업/스크린샷?" |
| **graph-engineering 스킬** | SKILL.md 1개 + plan-schema. 의존성 감사 + 숨은 엣지(같은 파일 쓰기, 시그니처 변경, 레이트리밋, 비가역) + 20~30개 단위 fan-in | Tier-3 change 분해 휴리스틱 |
| Kiro | IDE라 미설치. 문서상 Quick Spec / bugfix spec | OpenSpec 스키마로 동일 효과 |
