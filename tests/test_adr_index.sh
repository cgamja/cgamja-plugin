# ADR 파일 ↔ adr/README.md 목록 일치. adr/README 규약: "새 결정은 ADR 먼저 → 문서는 ADR을 참조".
# 왜 있나: 2026-08-31 회고에서 adr/0028 이 **파일은 있는데 목록 표에 없었다** — 목록이 원장인데
# 원장에서 빠지면 다음 사람이 그 결정을 못 찾는다. 사람이 표를 손으로 관리하는 한 계속 빠진다.
missing=""; for f in adr/[0-9][0-9][0-9][0-9]-*.md; do
  n="$(basename "$f")"
  grep -q "($n)" adr/README.md || missing="$missing $n"
done
check "adr: 모든 ADR 파일이 README 목록에 있다" "" "$missing"

# 반대 방향 — 목록에 있는데 파일이 없는 링크(깨진 참조)
dangling=""; while IFS= read -r n; do
  [ -f "adr/$n" ] || dangling="$dangling $n"
done < <(grep -o '(\([0-9][0-9][0-9][0-9]-[^)]*\.md\))' adr/README.md | tr -d '()')
check "adr: README 목록의 링크가 전부 실재" "" "$dangling"

# 상태 값은 규약의 셋 중 하나(제안 / 채택 / 대체됨 / 폐기)
badstate=""; for f in adr/[0-9][0-9][0-9][0-9]-*.md; do
  s="$(sed -n 's/^- 상태: *\([^ (]*\).*/\1/p' "$f" | head -1)"
  case "$s" in 제안|채택|대체됨|폐기) ;; *) badstate="$badstate $(basename "$f"):${s:-없음}";; esac
done
check "adr: 상태 값이 규약대로" "" "$badstate"
