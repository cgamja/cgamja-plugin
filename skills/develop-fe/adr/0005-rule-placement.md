# 0005. 규칙 배치 — path-scoped rules, eager import 금지, DoD는 `pnpm verify` 한 곳, 훅은 Bash까지
- 상태: 제안
- 날짜: 2026-08-21
- 검증: (없음)

## 맥락
`references/verdicts-2026-08-21.md` ③. 사실관계: `@path` import는 런치 시 전부 로드(eager); CLAUDE.md 길이 25~500줄은 준수율을 바꾸지 않음(McMillan 2026), 준수율은 세션 내에서 떨어짐; `.claude/rules/*.md`+`paths:`는 해당 파일을 읽을 때 재주입(Anthropic 권장, 단 compaction 후 재주입 안 됨); Write/Edit 훅은 `tee`/`sed -i`로 우회됨(#63786); Opus 4.6이 CLAUDE.md 금지에도 `--no-verify` 6연속 우회(#40117); 훅 `if` 필터는 fail-open; Stop 훅 8회 차단 후 강제 종료.

## 결정
1. CLAUDE.md ≤60줄 soft. 금지 5개 맨 위, 명령, 스택 특이점, 백틱 포인터. **`@` import 없음.** 코드에서 유추되는 폴더맵·의존성 목록은 제외.
2. 파일 타입별 판단 규칙은 `.claude/rules/<topic>.md` + `paths:`, 각 ≤30줄, 정본 예시 파일 포인터 1개. `docs/conventions.md`는 이유·예시(lazy).
3. 완료 정의는 `package.json` `verify` 스크립트 **한 곳**. Stop 훅·CLAUDE.md 한 줄·OpenSpec guidance·CI는 이름만 참조.
4. 훅: PostToolUse는 파일 단위 1초 이내만(tsc 금지), 전체 검사는 Stop(코드 편집 턴만, `stop_hook_active`). PreToolUse 보호는 Write|Edit **+ Bash 매처**, 같은 패턴을 `permissions.deny`에도. `--no-verify`류 거부 + CI commitlint 백스톱. `GIT_PAGER=cat`.
5. "산문 한 줄(이유) + 강제 훅"은 한 규칙의 두 층으로 보고 허용. 그 외 같은 규칙 두 곳 금지.
6. CI에 경로·명령 존재 검사(ctxlint 또는 스크립트)로 문서 rot 방지.

## 전제
- Claude Code의 rules/hooks 동작이 2026-08 문서대로 유지된다(`InstructionsLoaded` 훅·`/context`로 확인 가능).
- 솔로라 CLAUDE.md에 "owner"는 본인; PR처럼 리뷰한다.

## 재검토 조건
- path-scoped rule이 compaction 뒤 빠져서 규칙 위반 2회 → 해당 규칙을 훅/린트로 승격하거나 루트 CLAUDE.md로.
- Stop 훅이 하루 3회 이상 8회 차단 강제 종료 → `verify` 범위를 changed-files로 줄임.
- Claude Code가 `@` import의 lazy 모드나 rules "description 기반 자동 로드"를 제공 → 배치 단순화.

## 결과 / 영향
- `project-conventions.md` 개정: 배치표, CLAUDE.md 템플릿(`@` 제거), rules 예시 3개, 훅 표.
- 프로젝트 시작 시 설정 항목 증가(rules 3개, 훅 5개, deny 목록, verify 스크립트) — 1회 비용.
