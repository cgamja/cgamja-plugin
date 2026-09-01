#!/usr/bin/env bash
# 복사본 드리프트 대조 — 플러그인 템플릿 ↔ 프로젝트에 심긴 사본.
#
# 왜 내용으로 보나: adr/0023 이 정수 마커(`# cgamja-hooks v<N>`)로 드리프트를 잡게 했는데,
# 마커를 손으로 올려야 해서 2026-09-01 세 번의 훅 수정에서 한 번도 안 올랐다. 마커가 같아도
# 내용은 90줄 달랐다. 손으로 지키는 규칙은 지켜지지 않는다(adr/0031) — 그래서 내용을 본다.
#
#   bash drift.sh <project-dir> [--apply]
# 종료코드 0 = 격차 없음, 1 = 격차 있음, 2 = 이 스킬의 대상이 아님(선언 없음)
set -uo pipefail
DIR="${1:?project dir}"; APPLY=0; [ "${2:-}" = "--apply" ] && APPLY=1
HERE="$(cd "$(dirname "$0")" && pwd)"
TPL="$HERE/../../develop-setup/templates"
[ -d "$TPL" ] || { echo "✗ 템플릿을 못 찾음: $TPL"; exit 1; }
[ -f "$DIR/.claude/cgamja.json" ] || {
  echo "✗ $DIR/.claude/cgamja.json 없음 — update 가 아니라 setup 대상이다."
  echo "  훅은 선언에서 패턴을 읽는다(adr/0014). 선언 없이 훅만 새로 깔면"
  echo "  '최신인데 아무것도 안 막는' 상태가 된다. /develop-setup 을 먼저."; exit 2; }

gap=0
note() { printf '  %-8s %s\n' "$1" "$2"; }

echo "## 1. 훅 스크립트 — 내용 대조"
for t in "$TPL"/hooks/*.sh; do
  f="$(basename "$t")"; i="$DIR/.claude/hooks/$f"
  if [ ! -f "$i" ]; then
    note "신규" "$f — 파일 자체가 없다(새 강제 수단)"; gap=1
    [ "$APPLY" = 1 ] && { cp "$t" "$i" && chmod +x "$i" && note "→설치" "$f"; }
  elif ! diff -q "$t" "$i" >/dev/null 2>&1; then
    note "다름" "$f ($(diff "$t" "$i" | grep -c '^[<>]') 라인차)"; gap=1
    [ "$APPLY" = 1 ] && { cp "$t" "$i" && chmod +x "$i" && note "→갱신" "$f"; }
  else note "같음" "$f"; fi
done

echo
echo "## 2. 훅 등록 — 파일이 있어도 안 불리면 없는 것과 같다"
reg="$DIR/.claude/settings.json"
if [ ! -f "$reg" ]; then note "없음" "settings.json"; gap=1; else
  for t in "$TPL"/hooks/*.sh; do
    f="$(basename "$t")"
    # `_` 로 시작하는 건 훅이 아니라 source 되는 라이브러리다 — 등록될 자리가 없다.
    case "$f" in _*) note "라이브러리" "$f (등록 대상 아님)"; continue;; esac
    grep -q "hooks/$f" "$reg" && note "등록됨" "$f" || { note "미등록" "$f — settings.json 에 command 가 없다"; gap=1; }
  done
fi

echo
echo "## 3. 선언 슬롯 — 새 강제 수단이 읽을 자리가 있는가"
missing="$(python3 - "$TPL/cgamja.json" "$DIR/.claude/cgamja.json" <<'PY'
import json,sys
def keys(o,p=""):
    out=set()
    for k,v in (o or {}).items():
        if k.startswith("$"): continue
        out.add(p+k)
        if isinstance(v,dict): out|=keys(v,p+k+".")
    return out
t=keys(json.load(open(sys.argv[1]))); i=keys(json.load(open(sys.argv[2])))
# 최상위 슬롯만 본다 — 하위 키는 프로젝트마다 정당하게 다르다(layers·allowed_edges 등)
print(" ".join(sorted(k for k in t-i if "." not in k)))
PY
)"
if [ -n "$missing" ]; then
  note "없음" "$missing — 값은 null 로 두고 setup 이 채운다"; gap=1
  if [ "$APPLY" = 1 ]; then
    if added="$(python3 "$HERE/merge-slots.py" "$TPL/cgamja.json" "$DIR/.claude/cgamja.json")"
    then note "→추가" "$added"
    else note "→실패" "선언에 키를 못 넣었다 — 손으로 추가한다"; fi
  fi
else note "같음" "최상위 슬롯 전부 있음"; fi

echo
echo "## 4. rules 구조 — 자동으로 덮지 않는다(내용이 프로젝트 고유다)"
if ls "$DIR"/.claude/rules/*.md >/dev/null 2>&1; then
  un="$(grep -hc '^- ' "$DIR"/.claude/rules/*.md 2>/dev/null | paste -sd+ - | bc)"
  mk="$(grep -h '^- ' "$DIR"/.claude/rules/*.md 2>/dev/null | grep -c '\*\*\[')"
  if [ "${un:-0}" -ne "${mk:-0}" ]; then
    note "격차" "불릿 $un 개 중 $mk 개만 [강제 수단] 표기(adr/0031) — 사람이 채운다"; gap=1
  else note "같음" "불릿 $un 개 전부 표기"; fi
else note "없음" ".claude/rules/"; gap=1; fi

echo
[ "$gap" = 0 ] && echo "drift: 격차 없음" || echo "drift: 격차 있음$([ "$APPLY" = 1 ] && echo ' (--apply 로 1~3 적용함 · 4는 사람)')"
[ "$gap" = 0 ]
