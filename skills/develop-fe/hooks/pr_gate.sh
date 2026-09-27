#!/usr/bin/env bash
# 첫 push·PR 생성 게이트(adr/0038) — 아직 origin에 없는 브랜치를 내보낼 때 origin/main 이후 비머지 커밋이
# 6개를 넘으면 막는다. 첫 push 전이라 강제 push 없이 재구성할 수 있으므로 차단이 정당하다. 이미 origin에
# 있는 브랜치는 다시 쓸 수 없으니 막지 않는다(0034 — push 뒤 수정은 커밋을 더한다).
source "$(dirname "$0")/_lib.sh"
cmd="$(j tool_input.command)"
case "$cmd" in *"gh pr create"*|*"git "*push*) ;; *) exit 0;; esac
printf '%s' "$cmd" | grep -qE '(^|[;&| ])git( -C [^ ]+)? push|gh pr create' || exit 0

dir="$(j cwd)"; c="$(printf '%s' "$cmd" | sed -nE 's/.*git -C ([^ ;&|]+) push.*/\1/p' | head -1)"
[ -n "$c" ] && dir="$(eval echo "$c" 2>/dev/null)"
[ -d "$dir" ] || exit 0
g() { git -C "$dir" "$@" 2>/dev/null; }
g rev-parse --verify -q origin/main >/dev/null || exit 0

target="$(printf '%s' "$cmd" | sed -nE 's/.*push [^ ]+ [^ :]*:([^ ;&|]+).*/\1/p' | head -1)"
[ -n "$target" ] || target="$(g rev-parse --abbrev-ref HEAD)"
[ -n "$target" ] && [ "$target" != "HEAD" ] || exit 0
g rev-parse --verify -q "origin/$target" >/dev/null && exit 0   # 이미 나간 브랜치 — 다시 쓰지 않는다

limit="${CGAMJA_PR_COMMIT_LIMIT:-6}"
# 기준 = HEAD의 조상인 origin 브랜치 중 가장 가까운 것 — 스택 PR(아래 PR 브랜치 위에 쌓은 PR)은 아래 PR의
# 커밋까지 세면 안 된다. `gh pr create --base X`가 있으면 그걸 쓴다.
base="$(printf '%s' "$cmd" | sed -nE 's/.*gh pr create.*--base[ =]([^ ;&|]+).*/\1/p' | head -1)"
if [ -n "$base" ] && g rev-parse --verify -q "origin/$base" >/dev/null; then base="origin/$base"
else
  base="origin/main"; best="$(g rev-list --count --no-merges origin/main..HEAD)"
  for r in $(g for-each-ref --format='%(refname:short)' refs/remotes/origin); do
    case "$r" in origin/HEAD|origin|"origin/$target") continue;; esac
    g merge-base --is-ancestor "$r" HEAD || continue
    c="$(g rev-list --count --no-merges "$r..HEAD")"
    [ "${c:-999}" -lt "${best:-999}" ] && { best="$c"; base="$r"; }
  done
fi
n="$(g rev-list --count --no-merges "$base..HEAD")"; n="${n:-0}"
[ "$n" -le "$limit" ] && exit 0
script="$(cd "$(dirname "$0")/../scripts" && pwd)/restack.sh"
deny "[commits] 첫 push 전 커밋 ${n}개(기준 ${base}) — PR당 ${limit}개 이하(adr/0038). 지금이 강제 push 없이 접을 수 있는 마지막 시점이다.
  bash $script -C $dir --base ${base#origin/} [--type fix] <scope> \"<feat 요약>\" [\"<test 요약>\"] [\"<design 요약>\"] [\"<openspec 요약>\"]
test · chore(design) · feat|fix · docs(openspec) 최대 4개로 경로 재구성한다(트리 불변 확인·되돌리는 명령 출력). 커밋 본문은 BODY_TEST/BODY_FEAT, 트레일러는 TRAILER 환경변수. 그다음 다시 push."
