#!/usr/bin/env bash
# 첫 push 전 커밋 재구성(adr/0038) — origin/$base 이후 작업을 경로로 다시 쌓아 test · chore(design) · feat|fix ·
# docs(openspec) 최대 4개로 만든다. test/feat 분리는 경로로 보장된다(check-commits 통과). 이미 origin에 있는
# 브랜치에는 쓰지 않는다(강제 push 금지 — 스크립트가 거부).
# 사용: restack.sh [-C <dir>] [--base <브랜치>] [--type fix] <scope> "<feat 요약>" ["<test 요약>"] ["<design 요약>"] ["<openspec 요약>"]
# 커밋 본문: 환경변수 BODY_TEST / BODY_FEAT (red 원문·리뷰 반영 요약을 옮긴다). Co-Authored-By 등 트레일러는 TRAILER.
set -euo pipefail
dir=.; type=feat; base=main   # 스택 PR이면 --base <아래 PR 브랜치>
while [ $# -gt 0 ]; do case "$1" in -C) dir="$2"; shift 2;; --base) base="$2"; shift 2;; --type) type="$2"; shift 2;; *) break;; esac; done
scope="${1:?scope}"; feat="${2:?feat 요약}"; tsum="${3:-$feat 테스트}"; dsum="${4:-$feat 화면·에셋}"; osum="${5:-스펙·아카이브}"
cd "$dir"
br="$(git rev-parse --abbrev-ref HEAD)"
git fetch -q origin
if git rev-parse --verify -q "origin/$br" >/dev/null; then echo "✗ origin/$br 이 이미 있다 — push된 브랜치는 다시 쓰지 않는다(adr/0034)" >&2; exit 1; fi
git diff --quiet && git diff --cached --quiet || { echo "✗ 커밋 안 된 변경이 있다 — 먼저 커밋하거나 치워라" >&2; exit 1; }
# 추적 안 되는 파일도 막는다 — 재구성 커밋에 섞이고, 실패 시 안내하는 `reset --hard` 가 지운다(PR#14 CodeRabbit).
[ -z "$(git ls-files --others --exclude-standard)" ] || { echo "✗ 추적 안 되는 파일이 있다 — 커밋하거나 .gitignore·다른 곳으로 옮긴 뒤 다시" >&2; git ls-files --others --exclude-standard | head -5 >&2; exit 1; }
git merge -q --no-edit origin/$base || { echo "✗ origin/$base 병합 충돌 — 해소·커밋 후 다시" >&2; exit 1; }
before="$(git rev-parse HEAD)"
git reset -q --soft origin/$base && git restore --staged .
# 경로는 따옴표 없이(한글 파일명) 받고, git add 에는 --pathspec-from-file 로 넘긴다 — xargs 는 공백 든 파일명을 쪼갠다(PR#14 CodeRabbit).
# reset --soft 뒤 새 파일은 untracked 로 돌아온다 — 시작 전 untracked 0 을 확인했으므로 여기 목록은 전부 재구성 대상이다.
changed() { { git -c core.quotePath=false diff --name-only origin/$base --; git -c core.quotePath=false ls-files --others --exclude-standard; } | sort -u; }
addp() { git add -A --pathspec-from-file=- ; }
msg() { printf '%s\n' "$1"; [ -n "${2:-}" ] && printf '\n%s\n' "$2"; [ -n "${TRAILER:-}" ] && printf '\n%s\n' "$TRAILER"; }
t="$(changed | grep -E '\.(test|spec)\.[a-z]+$|^(test|e2e|\.maestro)/|/e2e/|/__tests__/' || true)"
[ -n "$t" ] && { printf '%s\n' "$t" | addp; git commit -q -m "$(msg "test($scope): $tsum" "${BODY_TEST:-}")"; }
d="$(changed | grep -E '^design/' || true)"
[ -n "$d" ] && { printf '%s\n' "$d" | addp; git commit -q -m "$(msg "chore(design): $dsum")"; }
git add -A -- . ':!openspec/'; git diff --cached --quiet || git commit -q -m "$(msg "$type($scope): $feat" "${BODY_FEAT:-}")"
git add -A -- openspec/ 2>/dev/null || true; git diff --cached --quiet || git commit -q -m "$(msg "docs(openspec): $osum")"
[ "$(git rev-parse HEAD^{tree})" = "$(git rev-parse "$before^{tree}")" ] || { echo "✗ 트리가 달라졌다 — 되돌림: git reset --hard $before" >&2; exit 1; }
git log --oneline origin/$base..HEAD
echo "✓ 재구성 완료 — 코드 트리는 그대로($before 와 같다). 되돌리려면: git reset --hard $before"
