# 절차 층(①)에 프레임워크·도구 이름이 조건으로 들어오지 않는지(adr/0014). 스택 지식은 references의 조건부 절에만.
# develop-setup은 재작성(0014 §2) 뒤 목록에 추가한다.
words='Next\.js|\bNext\b|\bVite\b|\bExpo\b|\bReact\b|Vitest|jsdom|\borval\b|Tailwind|TanStack|RNTL|jest-expo|\bMSW\b|\bpnpm\b|jsx-a11y|\bvi\.mock\("src'
for f in skills/develop-setup/SKILL.md skills/develop-fe/SKILL.md skills/develop-fe/workflow.md skills/test-fe/SKILL.md skills/review-fe/SKILL.md agents/reviewer-*.md; do
  check "no stack words: $f" "" "$(grep -nE "$words" "$f" | cut -c1-120 | head -3)"
done
