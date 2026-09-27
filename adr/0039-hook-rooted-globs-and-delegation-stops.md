# ADR 0039 — 보호 glob은 루트 기준·hooksPath 판정은 세그먼트 단위, 위임에는 멈춤 세 줄

- 상태: 제안 (2026-09-24)
- 관련: adr/0017·0023·0028(훅 정밀화), adr/0025(재조정 상한 3), adr/0027(위임 packet), adr/0029(전진 기본), retro 2026-09-24

## 문제
1. **hooksPath 오탐** — `protect-bash.sh`가 전체 명령 텍스트(`$cmd`)에서 `core.hooksPath`를 찾았다. heredoc 본문에 이름이 적혀 있기만 해도(파일 작성·스킬 문서 편집), `git -C <워크트리> config core.hooksPath` 조회도 막았다(care-app 09-24 4회 이상 — AGENTS.md가 지시하는 "조회 후 비어 있으면 설정"의 조회까지, 이 ADR을 쓰는 명령도 막혔다).
2. **`specs/**` 오탐** — 보호 glob이 경로 어디서든 매칭돼 OpenSpec 델타 `openspec/changes/<c>/specs/…`가 팀 캐논 사본 `specs/**`로 읽혔다(Edit `ask` 2회, Bash는 쉘 쓰기 차단 — 메모리에 우회법까지 쌓임).
3. **끝나지 않는 위임** — 수정 패스 서브에이전트가 같은 시각 버그(값 칸 잘림)를 픽셀 대조로 세 방식 시도하고도 계속 파서 95분(전체 331분). 그동안 사용자는 진행을 5회 물었다. 재조정 상한 3(0025)은 증거 캡처 문서에만 있고 packet에는 없었다.

## 결정
1. hooksPath: heredoc 본문을 뺀 명령을 `&& || ; |`로 나눈 **세그먼트마다** 판정. `git [-C dir]… config [--flags] core.hooksPath [N>…]` 형태면 조회로 통과, 그 밖(값 설정·`-c` 인라인)은 deny.
2. 보호 glob 의미를 `.gitignore`와 맞춘다 — **슬래시가 든 glob은 루트 기준**(`specs/**`·`.claude/hooks/*`), 슬래시 없는 파일명(`package.json`·`.env`)만 어느 폴더에서든. Bash(`anchor_rooted`)·Edit(`_lib.sh matches`) 둘 다.
3. unit packet에 **멈춤 세 줄**: ① 같은 증상에 방법 3개 실패 → `blocked` 반환 ② 시간 예산(45분, 큰 수정 패스 90분) 초과 → 반환 ③ 단계 전환마다 `SendMessage(to:"main")` 한 줄. 메인은 위임 시작·단계 보고를 사용자에게 먼저 알린다.

## 검증
`hook-cases.sh` 36 → 43케이스(조회 -C·리다이렉트·세그먼트, heredoc 본문, OpenSpec 델타 허용 / -C 설정·-c 인라인·명세 사본 쓰기 차단) 전부 통과. Edit 훅: `specs/a.md` ask · `openspec/changes/a/specs/b/spec.md` 통과 · `sub/package.json` ask.

## 결과
- 프로젝트에 설치된 훅 사본은 자동으로 바뀌지 않는다 — `develop-update`(0033)로 갱신. care-app은 `.claude/hooks/`가 세팅 PR 산출물이라 갱신 PR 1개가 필요하다.
- 중첩 경로의 슬래시 glob(예: `packages/a/specs/**`를 의도한 `specs/**`)은 이제 안 걸린다 — 그런 뜻이면 `**/specs/**`로 선언.

## 재검토 조건
- 세그먼트 분할이 놓친 hooksPath 설정 사례 1회 → 전체 매칭 복귀 검토
- 멈춤 세 줄 뒤에도 한 unit이 예산 2배를 넘긴 사례 2회 → 예산을 선언(`.claude/cgamja.json`)으로
