# develop-fe — Tier-1 한 줄 수정 (2026-08-21)
- 대상: `/cgamja:develop-fe` · headless `claude -p --dangerously-skip-permissions` · 기본 모델 · 2.1.238
- 프로젝트: 같은 날 develop-setup이 만든 스크래치(Vite+React, todos 도메인, 부트스트랩 커밋 1개)
- 요청: "TodosPage h1을 '할 일'로"
- 소요: 13턴 · 2.0분 · **$1.58**
- 적용 ADR: 0004, 0005

## 결과
| # | 항목 | 확인 방법 | 결과 |
|---|---|---|---|
| 1 | 티어 판정 | "diff 한 문장" → Tier-1, OpenSpec 없음 | ✅ |
| 2 | 체크 선택 | 기존 e2e 스모크가 `heading "Todos"` 단언 → 테스트 수정 택함 | ✅ 합리적 |
| 3 | 증거 | red: e2e 실패 출력(미구현 사유) · green: `pnpm verify` + e2e 1 passed | ✅ |
| 4 | 커밋 | `test(todos):` → `feat(todos):` 2개, feat diff에 테스트 파일 없음, lefthook 통과 | ✅ (Tier-1 규칙은 "커밋 1개" — 기존 테스트를 고친 경우라 분리가 더 맞음. 문구 정리 후보) |
| 5 | Stop 훅 | `pnpm verify` 거짓 차단 없음 | ✅ |
| 6 | 0장 세션 시작 | `openspec` CLI 없음 → `openspec list` 실패(진행엔 무관) | ⚠️ |
| 7 | **테스트 파일 보호** | Edit는 거부됐으나 **`TDD_PHASE=red perl -pi -e … e2e/smoke.spec.ts` 로 Bash 우회** | ❌ **핵심 게이트 무력** |

## 발견한 결함 → 조치
| # | 결함 | 심각도 | 조치 |
|---|---|---|---|
| 1 | **테스트 파일 읽기전용 훅이 Bash로 우회됨** — 템플릿 `protect-bash.sh`가 `perl -pi`/`sed -i`/리다이렉트의 테스트 파일 쓰기를 안 잡고, `TDD_PHASE`를 에이전트가 인라인으로 세팅해 "red 턴"을 자칭 → 사람 게이트(adr/0004 핵심) 소멸 | **높음** | `templates/settings.json` `$hooks_spec.protect-bash.sh`에 ① 쓰기 명령 × 테스트 파일 패턴 동시 출현 거부 ② `TDD_PHASE=` 인라인 거부. `tdd-frontend.md` §4·CLAUDE.md 템플릿에 "TDD_PHASE는 사람이 세션 시작 시" 명시. 자가 검증 3번에 Bash 우회 2건 추가 |
| 2 | `openspec` CLI가 PATH에 없음 — `/opsx:*` 명령이 bare `openspec`을 부르므로 Tier-2는 깨짐 | 높음(Tier-2) | develop-setup 11행: `@fission-ai/openspec` devDep 고정 + knip ignore. 플러그인 `bin/openspec` 래퍼(프로젝트 devDep → pnpm exec → npx 순) — PATH 주입 여부 검증 중 |
| 3 | knip이 openspec devDep을 미사용으로 잡아 `verify` 빨강 | 중간 | knip `ignoreDependencies` (develop-setup 11행) |

## 관찰 (수정 안 함)
- 한 줄 수정에 $1.58·13턴 — 0장 세션 시작(git/openspec/solutions/typecheck) + e2e 실행 + 커밋 2회. Tier-1 비용 상한을 정할지(예: 스크린샷 1장으로 끝내는 "순수 스타일" 경로를 더 공격적으로).
- 에이전트는 우회를 "TDD_PHASE=red 턴에서"라고 **정직하게 보고**했다 — 속인 게 아니라 규칙이 "누가 red를 여는가"를 안 정해 둔 것. 규칙 결함이지 행동 결함이 아님.
- 따옴표 중첩으로 첫 test 커밋이 lint에 막혀 재커밋 — 정상.

## 다음
- 스크래치 `protect-bash.sh`를 템플릿 스펙대로 갱신 → 우회 2건 재현해 거부 확인 → Tier-2(`todos` 목록+추가, 상태 B·D)
