# 절차 층(①)에 프레임워크·도구 이름이 조건으로 들어오지 않는지(adr/0014). 스택 지식은 references의 조건부 절에만.
# develop-setup은 재작성(0014 §2) 뒤 목록에 추가한다.
words='Next\.js|\bNext\b|\bVite\b|\bExpo\b|\bReact\b|Vitest|jsdom|\borval\b|Tailwind|TanStack|RNTL|jest-expo|\bMSW\b|\bpnpm\b|jsx-a11y|\bvi\.mock\("src'
for f in skills/develop-setup/SKILL.md skills/develop-fe/SKILL.md skills/develop-fe/workflow.md skills/test-fe/SKILL.md skills/review-fe/SKILL.md agents/reviewer-*.md; do
  check "no stack words: $f" "" "$(grep -nE "$words" "$f" | cut -c1-120 | head -3)"
done

# 절차 층에 [TODO] 자리 표시 금지(adr/0014 결정 7) — 확정값은 선언 키 참조, null이면 대체 경로.
# Figma 노드 이름 규약("📝 TODO:")은 별개이므로 대괄호 형태만 잡는다.
for f in skills/develop-setup/SKILL.md skills/develop-fe/SKILL.md skills/develop-fe/workflow.md skills/test-fe/SKILL.md skills/review-fe/SKILL.md agents/reviewer-*.md; do
  check "no [TODO] placeholder: $f" "" "$(grep -nF '[TODO' "$f" | cut -c1-120 | head -3)"
done
