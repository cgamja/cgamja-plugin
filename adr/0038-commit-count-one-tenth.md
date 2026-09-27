# ADR 0038 — 커밋은 PR당 6개 이하, 첫 push 전에 기계로 재구성한다

- 상태: 제안 (2026-09-24)
- 관련: adr/0019(단계 단위 커밋), adr/0027(커밋 주체는 메인·worktree 병렬), adr/0031(산문 규칙은 기계로), adr/0034(첫 push는 리뷰 뒤), adr/0036(훅 없는 레포의 검사), retro 2026-09-24(care-app 세션 4개)

## 문제

care-app 리디자인 v2(2026-09-22~24) PR 5개가 커밋 **89·75·69·25·41개**를 main에 남겼다. 사흘간 care-app 310개(main 306개). 같은 기간 직렬로 돈 PR #38·#39·#40·#44는 1~9개였다. 담당자 판단: "작업 분리용 커밋이 trash급으로 쌓인다" — 목표는 **지금의 약 10%**.

규칙은 이미 있었다 — 「단계 1개 = 커밋 1개(change당 4~8)」·「첫 push는 리뷰 뒤」·「worker는 커밋 금지」·「task마다 커밋하지 않는다」. 지켜지지 않은 이유(retro 분류):

| 원인 | 비중(PR #46~48 합 135개 기준) | 규칙이 왜 못 막았나 |
|---|---|---|
| worktree 병렬 워커가 자기 브랜치에 커밋 + `git merge`로 통합 | 워커 커밋 대부분 + merge 8 | 2-P 「integrate → commit」이 방법을 안 정함 — merge가 워커 커밋을 전부 가져온다 |
| 코디네이터·사용자 피드백·CI 라운드마다 test+fix 쌍 | fix 19 · coordinator 8 · CI 7 | push가 먼저 나가 fixup으로 접을 창이 닫혔다 |
| 잡무 커밋 — tasks 체크 · 재캡처 · 스펙 개정 | 5 · 6 · 13 | 「task마다 커밋 안 함」은 산문, 체크박스·캡처는 예외처럼 굴었다 |
| 스택 PR merge commit | PR 내부 커밋이 main에 전부 | 머지 방식 기본값이 없었다 |
| 개수 검사가 경고뿐 | 전 PR | 경고는 PR 본문 한 줄로 흡수됐다(0031이 말한 산문화 그대로) |

## 결정

### 1. 목표 수 — PR당 ≤6
- **첫 push 시점 ≤5**: `docs(openspec)` 1(스펙+아카이브, 마지막) · `test(scope)` 1 · `feat|fix(scope)` 1 · `chore(design)` 0~1(재캡처·에셋). Tier-1은 1~2.
- **push 뒤** 라운드(CI·사용자 피드백 배치)당 커밋 **1개**, 테스트가 바뀐 라운드만 `test`+`fix` 2개.
- **머지 방식은 바꾸지 않는다**(merge commit 유지 — 담당자 결정 09-24). PR 안 커밋을 6개로 줄이면 main에 남는 것도 그만큼이다. squash 머지는 PR 안 단계(test·feat·디자인·스펙)가 main에서 한 덩어리가 돼 추적이 어려워진다(담당자 판단) — 채택하지 않는다.

### 2. 첫 push 전 재구성 — 레시피 하나(`fixup` 대신 기본)
작업 중 커밋은 자유(WIP·체크박스·캡처 전부). 첫 push(또는 `gh pr create`) 직전에 브랜치를 **경로로 다시 쌓는다** — 비대화형이고 test/feat 분리가 경로로 보장된다:
```bash
git fetch origin && git merge origin/main          # 충돌 해소 후
git reset --soft origin/main && git restore --staged .
git add -- '*.test.*' '*.spec.*' 'test/' 'e2e/' '.maestro/' 2>/dev/null; git commit -m "test(<scope>): <요약>"
git add -- 'design/' 2>/dev/null;  git diff --cached --quiet || git commit -m "chore(design): <요약>"
git add -A -- . ':!openspec/';     git commit -m "feat(<scope>): <요약>"
git add -A -- openspec/;           git diff --cached --quiet || git commit -m "docs(openspec): <change> 스펙·아카이브"
```
커밋 본문에 원래 단계(red 원문·리뷰 반영 요약)를 옮긴다 — 정보는 본문으로, 개수는 줄인다. 이미 push된 커밋은 다시 쓰지 않는다(강제 push 금지).

### 3. worktree 워커 통합은 squash
2-P 머지는 `git merge --squash <워커 브랜치>` → 메인이 test/feat로 나눠 커밋. `Merge branch 'worktree-agent-…'` 커밋을 만들지 않는다. 워커 packet: "커밋은 네 브랜치에서 자유, push 금지 — 통합 때 접힌다".

### 4. 기계 강제 — 첫 push 게이트는 차단
- 스킬 훅 `hooks/pr_gate.sh`(PreToolUse Bash): `gh pr create` 또는 upstream 없는 브랜치의 `git push`에서 `origin/main..HEAD` 비머지 커밋이 6 초과면 **deny** + §2 레시피. 기준은 HEAD의 조상인 origin 브랜치 중 가장 가까운 것(스택 PR은 아래 PR 브랜치 — `gh pr create --base`가 있으면 그것), `restack.sh --base`도 같은 기준. 첫 push 전이라 강제 push 없이 고칠 수 있으므로 차단이 정당하다(0031의 "경고만" 예외를 이 지점에서 거둔다).
- `templates/scripts/check-commits.sh`(CI·pre-push)의 경고 기준 8 → 6.

## 결과
- 리디자인 v2 규모 PR(60개 안팎) → 5~7개(+ 머지 커밋 1). 목표 10% 충족.
- 잃는 것: 단계별 red 커밋의 세분(→ 커밋 본문으로 이동), 워커별 이력. bisect 해상도는 PR 단위로 내려간다 — PR을 작게 나누는 것(스택)이 그 보완이다.

## 재검토 조건
- PR당 커밋 6 초과가 2회 → 게이트 우회 경로 점검(훅 미로드·레시피 실패)
- 재구성 뒤 test/feat 경로 분류가 틀린 사례(테스트 유틸이 src에 있는 등) 2회 → 레시피 경로 목록을 선언(`.claude/cgamja.json`)으로
