# ADR 0040 — 역할별 모델·effort는 에이전트 파일로 고정하고, 값은 실측으로 정한다

- 상태: 제안 (2026-09-27)
- 관련: adr/0011(모델 라우팅), adr/0020(baby 하향), adr/0027(unit 위임), adr/0037(버그 리뷰 Opus 고정), adr/0039(멈춤 세 줄)
- 근거 자료: 아티팩트 「cgamja Effort 라우팅」(https://claude.ai/artifact/QZ39D1K46ZW9SePpQnnYx2) — 실험 스크립트·원자료는 세션 scratchpad(probe/·explore-eval/·impl-eval/·orch-eval/·review-eval/)

## 문제
1. **effort를 정한 곳이 없었다.** Agent 도구에는 호출별 effort가 없다. 요청 프록시로 확인한 결과, effort를 안 적은 서브에이전트는 세션을 `--effort`/`/effort`로 띄우면 그 값을, settings로만 정하면 자기 모델의 설정·기본값을 쓴다 — 같은 리뷰어가 세션에 따라 low·medium·high로 돌았다.
2. **모델도 샜다.** 최근 30일 서브에이전트 1,088건 중 모델 미지정 719건, 그중 297건이 Fable을 물려받았다. 내장 Explore는 v2.1.198부터 세션 모델 상속이라 "탐색 haiku" 규칙은 한 번도 지켜지지 않았다(18건 중 haiku 0). simsimee 6항목 축은 즉석 서브에이전트라 모델이 섞였다.
3. **settings 키 불일치.** `modelSettings.claude-fable-5`는 `claude-fable-5-1`에 적용되지 않아, medium으로 둔 Fable 세션이 high로 돌았다.
4. 기존 표(탐색 haiku·구현 sonnet)는 실측 근거가 없었다.

## 결정
1. 서브에이전트 역할마다 **에이전트 파일**을 두고 frontmatter에 `model`·`effort`를 고정한다: `explorer`·`unit-worker`·`test-worker`(opus·medium), `unit-worker-lite`(sonnet·medium, 사용량 절약용), 리뷰어 `reviewer-cgamja`·`reviewer-correctness`·`code-review-opus`·`reviewer-agents6`(opus·medium). workflow 2-4·3-4는 `subagent_type`으로 부른다.
2. 오케스트레이터(세션)는 **Opus면 medium, Fable이면 high**. settings는 정식 모델 ID 키로 적는다.
3. `code-review-opus`에 탐색 각도 ⑨(모든 설정이 놓친 부류 — 시간대 경계·검증 누락·저장값/표시값 불일치·움직이는 기준 대비 상대값·재시도 경로 플래그·같은 커밋 헬퍼 누락)를 넣는다.
4. xhigh/max는 기본값으로 쓰지 않는다.

## 검증 (2026-09-27, 모델 이름을 가린 opus 채점)
| 실측 | 결과 |
|---|---|
| 요청 프록시 16회 | frontmatter `effort`는 플러그인 에이전트에도 적용 · 인라인 스킬 `effort`는 미적용 · fork 스킬은 적용 · haiku는 effort 미전송 |
| 탐색 6문항 × 5설정 | opus medium 재현율 0.93·오류 1 / sonnet medium 0.80·4 / haiku 0.72·13 |
| 구현(care-app test→fix 쌍) 5과제 | opus medium 합칠 수 있음 4/4·품질 5.0·10.9분 / sonnet medium 4/4·4.25·22.4분 / sonnet high 3/4 / sonnet low 3/5 / haiku 4/5(어려운 과제 실패) |
| 오케스트레이터(과거 작업 계획) 5건 | opus medium 티어·계약 5/5·위험 0.59 / opus high 4/5·0.58 / opus low 3/5 / fable high 위험 0.69(1위)·345s / fable medium 0.50 |
| 버그 리뷰 5건 | **무효** — 작업 폴더의 verify 훅 오류로 24건 중 약 13건이 리뷰 대신 환경 오류. 남은 결과는 모든 설정이 주요 버그 5개를 놓침 |

한계: 칸마다 1회, 과제 4~6개. 오케스트레이터 실측은 작업 폴더에서 이후 커밋이 보여 일부 답이 샜다(채점에서 절반만 인정). 정답지·채점 모두 opus.

## 결과
- 서브에이전트 값이 세션(Opus/Fable, effort)과 무관하게 같아진다. 역할 값을 바꾸려면 에이전트 파일 한 곳만 고친다.
- 구현·탐색이 opus가 되면서 Opus 사용량 비중이 오른다 — 주간 한도가 빠듯하면 `unit-worker-lite`.
- DeskPeng `develop` 스킬은 `ce-work`가 띄우는 워커의 모델·effort를 제어할 수 없다(세션 상속) — 리뷰만 에이전트 값을 따른다.

## 재검토 조건
- `docs/guides/model-routing.md` §4
- 리뷰 실측을 verify 훅을 끈 환경에서 다시 돌려 effort 비교 결과가 나오면 표를 갱신
