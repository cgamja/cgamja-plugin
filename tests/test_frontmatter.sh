# 스킬 frontmatter — name 일치, description 존재·길이, 스킬 간 트리거 문구 중복. 검증 1층(adr/0013).
for d in skills/*/; do
  s="${d%/}"; n="$(basename "$s")"
  fm="$(awk 'NR==1&&$0!="---"{exit} NR>1&&$0=="---"{exit} NR>1' "$s/SKILL.md")"
  check "$n: name matches dir" "name: $n" "$(grep -E '^name:' <<<"$fm")"
  desc="$(python3 - "$s/SKILL.md" <<'EOF'
import sys,re
t=open(sys.argv[1]).read().split('\n---',2)[0]
m=re.search(r'^description:\s*(.*)$',t,re.M); print(m.group(1).strip() if m else '')
EOF
)"
  check "$n: description present" "" "$([ ${#desc} -ge 80 ] || echo "too short (${#desc} chars)")"
  check "$n: description ≤ 1200 chars" "" "$([ ${#desc} -le 1200 ] || echo "too long (${#desc})")"
  check "$n: description mentions /$n" "/$n" "$desc"
done
# 두 스킬이 같은 트리거 문구("…해줘" 인용구)를 쓰면 라우팅이 갈린다.
# 파일 안 중복(frontmatter 문구를 본문에서 다시 인용)은 정상이므로 파일별로 먼저 유일화하고,
# 로케일 조합이 서로 다른 한글 문구를 같다고 보는 오탐을 피하려 바이트 비교(LC_ALL=C)로 파일 경계를 넘는 중복만 본다.
dups="$(for f in skills/*/SKILL.md; do grep -ohE '"[^"]{4,30}"' "$f" | LC_ALL=C sort -u; done \
  | LC_ALL=C sort | LC_ALL=C uniq -d | grep -E '해줘|하자|시작' | head -5 | tr '\n' ' ')"
check "no duplicated trigger phrases across skills" "" "$dups"
