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
# 두 스킬이 같은 트리거 문구("…해줘" 인용구)를 쓰면 라우팅이 갈린다
dups="$(grep -ohE '"[^"]{4,30}"' skills/*/SKILL.md | sort | uniq -d | grep -E '해줘|하자|시작' | head -5 | tr '\n' ' ')"
check "no duplicated trigger phrases across skills" "" "$dups"
