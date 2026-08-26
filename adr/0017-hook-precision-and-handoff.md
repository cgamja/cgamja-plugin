# 0017. 훅 정밀화 — 읽기/쓰기 구분, 보호 파일은 deny가 아니라 ask, Stop 훅 handoff

- 상태: 제안
- 날짜: 2026-08-26
- 관련: 0007(스킬 훅), 0009(red 게이트 = ask — 이 메커니즘을 보호 파일에도 확장), 0014(선언이 패턴의 원천)
- 검증: 실사용 4세션 회고(2026-08-25~26, RN/Expo 프로젝트 Tier-2 change 2개 완주 + 시작 세션 2개)에서 훅 마찰이 최대 비용 요인으로 확인 — 본 ADR의 각 결정은 그 회고의 관찰 1건 이상에 대응한다. 수정 후 재검증: 다음 Tier-2 change 1개에서 훅 deny/ask 오탐 0, 사용자 대리 타이핑 0, Stop 데드락 0

## 맥락
develop-setup이 심는 훅 3종(protect-bash / protect-files / verify-on-stop)은 전부 **하드 차단** 설계였다. 실사용 회고에서 다음이 반복됐다:
1. **읽기 전용 명령 오탐**: `git fetch && git status && git config core.hooksPath`(조회)가 "훅 우회"로, `python3 -c "json.load(open('.claude/cgamja.json'))"`·`node -e "require('./package.json')"`(읽기)가 "인터프리터 일회성 실행"으로 차단. 3세션에서 각 1~2턴 우회 재시도 비용.
2. **승인 경로 부재**: 보호 파일 수정을 AskUserQuestion으로 승인받아도 Edit가 재차 deny → 에이전트가 scratchpad에 완성본을 쓰고 사용자에게 `! cp …` 셸 명령을 대리 타이핑시키는 지경(2회, 그중 1회는 사용자가 `...`를 그대로 입력해 실패). 게이트가 "사람이 결정한다"를 강제하는 게 아니라 "사람이 타이핑한다"를 강제하고 있었다.
3. **protect ↔ Stop 데드락**: 미사용 의존성이 verify를 빨갛게 만듦 → protect 때문에 에이전트가 못 고침 → 사용자에게 물으려고 턴을 멈추면 Stop 훅이 "verify 실패 — 끝난 게 아니다"로 걷어참(2회). Stop 훅 출력은 실제 실패 스텝이 아니라 무관한 경고의 tail만 보여줌.
4. **의존성 훅 비대칭**: `npx expo install`(추가)은 통과·사후 보고, `npm uninstall`(제거)은 차단 — 위험도가 거꾸로.
5. **스크래치 테스트**: 디버깅용으로 만든 `debug-*.test.tsx` 삭제가 "테스트 파일 쉘 쓰기"로 차단 → `git clean -f` 우회를 유발(훅이 우회 습관을 가르침).
6. **setup_check 오경보**: 직전 Bash의 `cd` 때문에 cwd가 하위 디렉터리인 상태에서 훅이 프로젝트 루트를 못 찾아 세팅 완비 상태에서 "세팅 누락"을 6회 출력 — 모델이 훅을 무시하는 학습을 하게 만드는 최악 유형.

## 결정
1. **보호 파일 Edit/Write는 deny → `ask`.** adr/0009가 테스트 파일에 쓰는 메커니즘(사람이 diff를 보고 승인 = 게이트)을 보호 파일에도 적용한다. 승인 경로가 권한 프롬프트 하나로 통일되고, "승인받았는데 또 막힘"과 셸 대리 타이핑이 사라진다. **Bash를 통한 보호 파일 쓰기는 여전히 deny**(diff가 안 보이는 경로로는 승인이 성립하지 않는다 — 0009 3항과 동일 논리). 계약 생성물은 ask 대상이 아니다 — 원천 수정 + 재생성이 정답이므로 deny 유지.
2. **읽기/쓰기 구분.** `core.hooksPath`는 값 설정·`-c` 인라인만 deny, 조회(`git config [--flags] core.hooksPath`)는 허용. 인터프리터 일회성 실행(`node -e`/`python -c` 등)은 보호 경로가 등장해도 **쓰기 호출**(`open(…,'w')`, `write*`, `unlink` 등)이 함께 있을 때만 deny. settings.json `permissions.deny`의 `git config*core.hooksPath*` 항목은 제거한다 — glob으로는 읽기/쓰기를 구분할 수 없고, 정밀 판정은 훅이 한다.
3. **의존성 패턴 대칭화.** `expo install`(`npx expo install` 포함)을 추가/제거 감지에 포함한다. 의존성 변경의 승인 경로는 1항과 결합된다: 매니페스트 Edit(ask, 사람이 diff 승인) → lockfile 동기화 설치(인자 없는 install, 기존 허용) — 데드락 3의 정상 탈출로이기도 하다.
4. **스크래치 테스트 예외.** 커밋된 적 없는(untracked) 테스트 파일의 `rm`은 허용한다. 변조 방지의 대상은 리뷰를 통과해 커밋된 테스트이지, 에이전트가 방금 만든 디버그 스크래치가 아니다.
5. **Stop 훅 handoff.** verify 실패 시 (a) 오류 줄 요약(`error|fail` 매치 상위 15줄)을 먼저 보여주고, (b) 에이전트가 고칠 수 없는 원인(보호 파일·환경)이면 이유를 `.claude/state/handoff`에 쓰고 멈출 수 있다 — 훅은 마커를 1회 소비하고 "verify 미해결 상태로 사용자에게 넘김: <이유>"를 **시끄럽게** 남긴 뒤 통과시킨다. 조용한 fail-open이 아니라 fail-loud: 남용은 트랜스크립트와 로그에 그대로 보인다.
6. **setup_check 루트 고정.** cwd에서 위로 올라가며 `.claude/cgamja.json`/`package.json`을 찾고, 없으면 `git rev-parse --show-toplevel`, 그것도 없으면 cwd. 하위 디렉터리 cwd에서 오경보가 나지 않는다.

## 전제
- ask는 대화형 세션에서만 승인자가 있다(0009와 동일). 비대화형에서 보호 파일은 사실상 deny로 동작 — 의도된 것.
- handoff 마커는 에이전트가 쓸 수 있어 이론상 우회 가능하다. 방어는 은닉이 아니라 가시성: 마커 사유가 Stop 출력·`verify.last.log`에 남고, 리뷰 렌즈와 사람이 본다.

## 재검토 조건
- 보호 파일 ask가 한 세션에 5회 이상 떠서 피로 → `protected` 목록이 과대(선언 축소) 또는 batch 승인 메커니즘(0018)을 보호 파일로 확장.
- handoff 마커가 "verify 고치기 귀찮음"의 탈출구로 쓰인 사례 2회 → 마커에 보호 경로 사유 필수 + 리뷰 렌즈 L3에 handoff 사유 검사 추가.
- 인터프리터 쓰기 판정(`IWRITE`)의 오탐/누락 각 2회 → 패턴 조정, 누락이면 deny 우선으로 복귀.

## 결과 / 영향
`templates/hooks/protect-bash.sh`(hooksPath 조회 허용, IWRITE 동반 판정, expo install, 스크래치 rm), `templates/hooks/protect-files.sh`(protected → ask), `templates/hooks/verify-on-stop.sh`(오류 요약 + handoff), `templates/settings.json`(deny 목록·$hooks_spec), `skills/develop-fe/hooks/setup_check.sh`(루트 탐색), `templates/CLAUDE.md`·develop-setup SKILL.md 문구, `scripts/smoke.sh` 보호 파일 프로브(ask 기대), `tests/test_setup_hooks.sh` 회귀 갱신·추가.
