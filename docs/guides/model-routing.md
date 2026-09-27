# 모델·effort 라우팅 — 어떤 일을 어떤 모델·effort에 (`adr/0011` → `adr/0040`)

**원칙**: 본 세션(오케스트레이터) 모델은 **사용자 선택**(Opus 또는 Fable). 서브에이전트는 **역할 에이전트 파일**(`agents/*.md` frontmatter의 `model:`·`effort:`)로 고정한다 — Agent 도구에는 호출별 effort 인자가 없고, `model`을 생략하면 세션 모델을, `effort`를 생략하면 세션의 명시 effort(없으면 그 모델의 설정·기본값)를 물려받는다(adr/0040 요청 프록시 실험). 표의 값은 2026-09-27 실측(탐색 30회·구현 22회·오케스트레이터 25회, 이름을 가린 채점)에서 **품질 1순위, 같은 품질이면 속도**로 골랐다.

## 1. 라우팅 표
| 작업 | 에이전트 | 모델 · effort | 근거 (adr/0040) |
|---|---|---|---|
| 오케스트레이터 — 세션이 Opus | 세션 | Opus 5.5 · **medium** | 티어·계약 판정 5/5. high는 위험 예견이 나아지지 않고 1.6배 느림. low는 티어 오판 2/5 |
| 오케스트레이터 — 세션이 Fable | 세션 | Fable 5.1 · **high** | 위험 예견·task 분해 1위. medium은 Opus medium보다 낮음. 계획 1회 약 3배 시간 |
| `/ce-brainstorm`, `/opsx:propose` 등 Skill | 세션 | 세션 값 | 인라인 스킬 frontmatter의 `effort:`는 실측에서 적용되지 않았다. fork 스킬(`context: fork`)만 `model`·`effort`가 먹는다 |
| 코드 탐색(유사 컴포넌트·사용처·호출 경로) | `cgamja:explorer` | opus · medium | 재현율 0.93·틀린 주장 1건. haiku 0.72·13건, sonnet medium 0.80·4건. 시간은 sonnet과 비슷 |
| 구현 unit | `cgamja:unit-worker` | opus · medium | 합칠 수 있음 4/4·코드 품질 1위·sonnet medium보다 2배 빠름 |
| 구현 unit — 주간 사용량 절약 | `cgamja:unit-worker-lite` | sonnet · medium | 합칠 수 있음 4/4, 시간 2배. sonnet low·high는 어려운 과제에서 테스트 통과 후 회귀 |
| 테스트 unit | `cgamja:test-worker` | opus · medium | 실측 없음 — 구현 결과를 따른다 |
| 버그 리뷰(②축) | `cgamja-private:code-review-opus` | opus · medium | 실측 무효(환경 오류). 남은 결과에서 모든 설정이 같은 부류를 놓침 → effort가 아니라 탐색 각도 ⑨로 보강 |
| 철학 리뷰(①축) | `cgamja:reviewer-cgamja` | opus · medium | 실측 없음 — 문서 조항 대조 |
| 정확성 리뷰(baby) | `cgamja:reviewer-correctness` | opus · medium (baby는 호출 시 `model: sonnet`, adr/0020) | 실측 없음 |
| simsimee 자체 검증 6항목(③축) | `cgamja-private:reviewer-agents6` | opus · medium | 즉석 서브에이전트일 때 모델이 섞였다(opus 34·sonnet 11·상속) |
| 스크린샷 촬영·목록 수집·린트 정리 | general-purpose + `model: "haiku"` | haiku · (effort 미지원) | 기계적 수집. haiku는 effort 파라미터가 요청에서 빠진다 |

## 2. 호출 방법
- **Agent 도구**: `subagent_type`에 위 역할 에이전트를 준다. `model:`은 기계적 수집(haiku) 외에는 넘기지 않는다 — 넘기면 에이전트 파일 값을 덮는다.
- **Workflow**: `agent(prompt, {agentType: 'cgamja:unit-worker'})` 또는 `{model, effort}` — Workflow의 `agent()`는 호출별 `effort`를 받는다.
- **세션 effort**: `~/.claude/settings.json`의 `modelSettings.<정식 모델 ID>.effortLevel` — 키는 정확한 모델 ID여야 한다(`claude-fable-5`는 `claude-fable-5-1`에 적용되지 않았다). 어려운 propose 한 번만 올리려면 사람이 `/effort high`.
- `agents/*.md`의 frontmatter가 기본값이다. 플러그인 에이전트에서도 `effort:`가 적용된다(실측).

## 3. 하지 않는 것
- 오케스트레이터를 low로, 또는 haiku/sonnet으로 — 티어가 낮은 쪽으로 샌다(실측 low 오판 2/5).
- 탐색·구현을 haiku나 low로 — 틀린 주장("컴파일러가 잡는다")과 테스트 밖 회귀가 늘었다.
- xhigh/max를 기본값으로 — 문서상 30분+ 장기 작업용이고 max는 과한 사고 경향. 실측 대상에서도 뺐다.
- 모델별로 프롬프트를 다르게 쓰기 — 같은 에이전트 파일에서 `model`/`effort`만 바꾼다. 결과 차이는 `reports/`에 기록해 표를 고친다.

## 4. 재검토 조건
- `unit-worker`가 같은 unit에서 blocked 2회 연속 → 그 유형만 effort high 검토
- `code-review-opus`가 놓친 회귀 2회(각도 ⑨ 반영 뒤) → 리뷰 실측을 verify 훅을 끈 환경에서 다시 돌려 effort 비교
- Fable 세션 계획이 3회 연속 1시간 대기를 만든다 → Fable medium 재검토
- 주간 사용량 한도에 2주 연속 닿음 → `unit-worker-lite`를 기본으로
