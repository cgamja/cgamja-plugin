# 문서 안의 플러그인 경로(`docs/guides/*.md`, `adr/NNNN`, `agents/*.md`, `skills/*/`)가 실제로 존재하는지. 루트 승격(adr/0010) 이후 깨진 링크 방지.
missing=""
for f in $(git ls-files '*.md' '*.sh' '*.json' | grep -v '^reports/\|^adr/'); do   # adr/·reports/는 역사 기록 — 폐지된 경로 언급 허용(adr/0026)
  # 앞에 /·영문·-가 붙은 것(docs/adr, ce-work/references 등 외부 경로)은 제외
  for ref in $(grep -oE '(^|[^/A-Za-z-])(docs/guides/[a-z0-9._-]+\.md|agents/reviewer-[a-z]+\.md|adr/[0-9]{4}[a-z0-9-]*(\.md)?|skills/(develop|test|review)-[a-z]+/)' "$f" | sed -E 's#^[^a-z]*##' | sort -u); do
    case "$ref" in
      adr/[0-9][0-9][0-9][0-9]) ls adr/"${ref#adr/}"-*.md >/dev/null 2>&1 || missing="$missing $f→$ref";;
      *) [ -e "$ref" ] || missing="$missing $f→$ref";;
    esac
  done
done
check "plugin doc paths exist" "" "$missing"
# 새 스킬의 frontmatter
for s in review-cgamja qa-cgamja test-driven-development browser-testing-with-devtools; do check "$s SKILL.md has name" "name: $s" "$(head -3 skills/$s/SKILL.md)"; done
for a in agents/reviewer-*.md; do check "$(basename $a) has model" "model:" "$(head -6 $a)"; done
