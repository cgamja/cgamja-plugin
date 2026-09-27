#!/usr/bin/env bash
# 첫 push·PR 생성 게이트(adr/0038) — 아직 origin에 없는 브랜치를 내보낼 때 기준 브랜치 이후 비머지 커밋이
# 6개를 넘으면 막는다. 첫 push 전이라 강제 push 없이 재구성할 수 있으므로 차단이 정당하다. 이미 origin에
# 있는 브랜치는 다시 쓸 수 없으니 막지 않는다(0034 — push 뒤 수정은 커밋을 더한다).
source "$(dirname "$0")/_lib.sh"
cmd="$(j tool_input.command)"
case "$cmd" in *"gh pr create"*|*"git "*push*) ;; *) exit 0;; esac
# push·pr create가 든 세그먼트 하나만 본다(다른 명령의 인자를 refspec으로 읽지 않게)
seg="$(printf '%s' "$cmd" | tr ';&|' '\n\n\n' | grep -m1 -E '(^|[[:space:]])git( -C [^ ]+)? push([[:space:]]|$)|gh pr create')" || exit 0

# -C 경로는 문자열로만 해석한다 — eval 하면 `$(…)` 같은 명령 치환이 훅 안에서 실행된다(PR#14 CodeRabbit, CWE-78).
dir="$(j cwd)"
c="$(printf '%s' "$seg" | sed -nE 's/.*git -C ([^ ]+) push.*/\1/p')"
if [ -n "$c" ]; then
  c="${c#[\"\']}"; c="${c%[\"\']}"
  case "$c" in "~"|"~/"*) c="$HOME${c#\~}";; esac
  case "$c" in /*) dir="$c";; *) dir="$dir/$c";; esac
fi
[ -d "$dir" ] || exit 0
g() { git -C "$dir" "$@" 2>/dev/null; }
g rev-parse --verify -q origin/main >/dev/null || exit 0

# 내보낼 (로컬 소스, 원격 브랜치) 쌍 — 현재 HEAD가 아니라 refspec이 가리키는 소스를 센다.
# `git push origin feature` 를 다른 브랜치에서 실행해도 feature 의 커밋을 센다(PR#14 CodeRabbit).
pairs=()
if grep -q 'gh pr create' <<<"$seg"; then
  h="$(printf '%s' "$seg" | sed -nE 's/.*--head[ =]([^ ]+).*/\1/p')"
  pairs+=("${h:-HEAD} ${h:-$(g rev-parse --abbrev-ref HEAD)}")
else
  args="$(printf '%s' "$seg" | sed -E 's/.*[[:space:]]push([[:space:]]|$)//')"
  pos=(); for a in $args; do case "$a" in -*) ;; *) pos+=("$a");; esac; done
  if [ "${#pos[@]}" -le 1 ]; then pairs+=("HEAD $(g rev-parse --abbrev-ref HEAD)")
  else
    for r in "${pos[@]:1}"; do
      r="${r#+}"; src="${r%%:*}"; dst="${r#*:}"
      [ -n "$src" ] || continue                       # `:branch` 는 원격 삭제
      pairs+=("$src ${dst#refs/heads/}")
    done
  fi
fi

limit="${CGAMJA_PR_COMMIT_LIMIT:-6}"
pr_base="$(printf '%s' "$seg" | sed -nE 's/.*gh pr create.*--base[ =]([^ ]+).*/\1/p')"
for p in "${pairs[@]}"; do
  src="${p%% *}"; dst="${p#* }"
  [ -n "$dst" ] && [ "$dst" != "HEAD" ] || continue
  g rev-parse --verify -q "origin/$dst" >/dev/null && continue   # 이미 나간 브랜치 — 다시 쓰지 않는다
  tip="$(g rev-parse --verify -q "$src^{commit}")" || continue
  # 기준 = tip의 조상인 origin 브랜치 중 가장 가까운 것 — 스택 PR(아래 PR 브랜치 위에 쌓은 PR)은 아래 PR의
  # 커밋까지 세면 안 된다. `gh pr create --base X`가 있으면 그걸 쓴다.
  if [ -n "$pr_base" ] && g rev-parse --verify -q "origin/$pr_base" >/dev/null; then base="origin/$pr_base"
  else
    base="origin/main"; best="$(g rev-list --count --no-merges "origin/main..$tip")"
    for r in $(g for-each-ref --format='%(refname:short)' refs/remotes/origin); do
      case "$r" in origin/HEAD|origin|"origin/$dst") continue;; esac
      g merge-base --is-ancestor "$r" "$tip" || continue
      n="$(g rev-list --count --no-merges "$r..$tip")"
      [ "${n:-999}" -lt "${best:-999}" ] && { best="$n"; base="$r"; }
    done
  fi
  n="$(g rev-list --count --no-merges "$base..$tip")"; n="${n:-0}"
  [ "$n" -le "$limit" ] && continue
  script="$(cd "$(dirname "$0")/../scripts" && pwd)/restack.sh"
  deny "[commits] 첫 push 전 커밋 ${n}개(${dst}, 기준 ${base}) — PR당 ${limit}개 이하(adr/0038). 지금이 강제 push 없이 접을 수 있는 마지막 시점이다.
  bash $script -C $dir --base ${base#origin/} [--type fix] <scope> \"<feat 요약>\" [\"<test 요약>\"] [\"<design 요약>\"] [\"<openspec 요약>\"]
test · chore(design) · feat|fix · docs(openspec) 최대 4개로 경로 재구성한다(트리 불변 확인·되돌리는 명령 출력). 커밋 본문은 BODY_TEST/BODY_FEAT, 트레일러는 TRAILER 환경변수. 그다음 다시 push."
done
exit 0
