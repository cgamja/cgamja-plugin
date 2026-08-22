# 0013 — 스킬 검증은 4층 피라미드, 스크래치 런은 탐색이지 기본값이 아니다

- 상태: 제안
- 날짜: 2026-08-22
- 관련: 0007(훅 테스트), 0009(훅 우회 사례), 0011·0012(런 비용 실측) · 표·도구 실측 원문 `references/skill-verification.md`
- 검증: 1층(`tests/run.sh` 52 케이스)은 운영 중. 2층 도구 실측 1회(skill-creator 트리거 eval, 부적합 판정). 3층 미구축. 공식 `plugin eval`은 게이트(미실행)

## 맥락
지금까지 스킬 변경의 검증은 스크래치 프로젝트에서 Tier-2 change를 끝까지 돌리는 것(회당 $7.56, 47턴, `reports/`)이 사실상 유일했다. 거기서 나온 결함("경계 린트 조용히 꺼짐", "템플릿 결함 4건", "즉석 리뷰어 제작 2회")은 대부분 에이전트 없이 잡을 수 있는 것이었고, 반대로 고친 뒤 회귀 확인은 같은 비용을 다시 내야 했다. 사용자 질문 "꼭 스크래치 런을 해야 하나, 원래 그렇게 하나"에 리서치(2026-08-22)로 답함: 업계는 결정적 테스트 / 트리거 / 행동 eval / 전체 런의 층 분리로 수렴했고, 회귀는 old-vs-new A/B·pass^k로 보며 golden transcript 문자열 비교는 아무도 쓰지 않는다. Next·Expo는 설계상 지원 축이지만 런 4회가 전부 Vite였다 — "커버된다"와 "검증됐다"가 구분되지 않은 상태.

## 결정
1. 검증은 **4층**: 1 결정적(`tests/` + 템플릿 스모크) / 2 트리거 / 3 행동 eval / 4 스크래치 런. 층·비용·정확도·변경 종류별 배분은 `references/skill-verification.md` §1~2.
2. **4층은 탐색 전용** — 절차 설계가 바뀌거나 새 스택·스킬을 넣을 때 1회. 거기서 찾은 결함은 즉시 1층(결정적이면) 또는 3층 케이스로 내려보낸다. 4층만으로 "검증됐다"고 적지 않는다.
3. 3층 케이스는 **공식 `claude plugin eval` 포맷**(`evals/<case>/prompt.md` + `graders/*.md`)으로 쓴다. 게이트가 열릴 때까지 `claude -p --output-format stream-json` + jq 채점 스크립트로 같은 케이스를 돌린다. 규칙: 결정적 그레이더 먼저, 결과 채점(경로 아님), with/without 델타가 메트릭, 근접 negative, 모델 핀.
4. 2·3층 판정은 **3~5회 반복 + pass^k, 임계 80%**. n=1·모델 미핀 숫자는 비교하지 않는다.
5. 스택 커버리지의 증거는 **1층 템플릿 스모크**(`smoke.sh <vite|next|expo>`). 4층 런은 절차가 분기되는 스택(Expo — 시뮬레이터 증거 경로)에만.
6. 월 1회 드리프트 점검(§6): 날짜 박힌 사실·ADR 재검토 조건·3층 전체. 산출물은 보고, 절차 변경은 실측 후.
7. 안 쓰는 것: 개발 루프(develop-fe) 안의 런타임 웹 리서치(검증 안 된 답이 절차에 섞임), golden transcript diff, 100% 임계, LLM 루브릭 단독 채점.

## 전제
- `claude -p`가 세션 안에서 중첩 실행 가능(`env -u CLAUDECODE`) — 2.1.239 실측.
- skill-creator 트리거 스크립트는 전역 설치된 진짜 스킬과 충돌(항상 0) — 쓰려면 플러그인 disable.
- 3층 케이스당 비용(~$0.5~3)은 추정. 첫 5케이스를 `--max-cost-usd` 상한으로 돌려 실측치로 교체.

## 재검토 조건
- `plugin eval` 게이트가 열림 → 임시 러너 폐기, 케이스는 그대로.
- 3층 케이스의 with/without 델타가 0인 것이 절반 이상 → 케이스가 모델을 테스트하고 있음, 전면 재작성.
- 2층 80% 임계에서 같은 description이 런마다 합/불 뒤집힘 3회 → 반복 횟수 5로 고정 또는 TF-IDF 층 추가.
- 4층 런에서 1·3층이 못 잡은 결함이 2회 연속 0건 → 4층 빈도를 더 줄인다.

## 결과 / 영향
- `references/skill-verification.md` 신설. `README.md` tests/ 설명과 `reports/README.md`의 위치(4층 기록)가 이 ADR을 참조.
- 다음 작업: `tests/test_frontmatter.sh`, `skills/develop-setup/scripts/smoke.sh`, `evals/triggers.json`, `evals/<case>/` 5~10개 + 임시 러너 `tests/eval.sh`.
