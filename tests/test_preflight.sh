P=skills/develop-setup/scripts/preflight.sh
E=$(mktemp -d); out="$(bash $P $E)"; check "empty dir → exit 1 + scaffold hint" "스캐폴더" "$out"
check "empty dir → 대조표 has ✗" "✗ 항목" "$out"
check "no stack words in preflight output" "" "$(grep -E 'Next|Vite|Expo|orval|Vitest' <<<"$out")"
# 선언이 있는 프로젝트(템플릿 선언 그대로)는 선언 기반 행이 ✓
mkdir -p $E/.claude; cp skills/develop-setup/templates/cgamja.json $E/.claude/; out="$(bash $P $E)"
check "declaration → P7 contract.source ✓" "✓ P7 contract.source" "$out"
check "declaration → P6 platform ✗ without rules" "✗ P6 platform.profile" "$out"
# 다른 스택 발견(Vue + Jest + husky)
rm -f $E/.claude/cgamja.json
printf '{"dependencies":{"vue":"3"},"devDependencies":{"jest":"29","@vue/test-utils":"2","husky":"9","@commitlint/cli":"19","msw":"2","eslint-plugin-vuejs-accessibility":"2","eslint":"9"},"scripts":{"verify":"npm run ci","lint":"eslint .","generate:api":"openapi-ts"}}' > $E/package.json; touch $E/yarn.lock
out="$(bash $P $E)"; check "discovers vue/jest/yarn" "yarn" "$(grep '러너' <<<"$out")"; check "discovers framework vue" "vue" "$(grep '프레임워크' <<<"$out")"
check "P3 verify ✓ from package.json script" "✓ P3 commands.verify" "$out"
check "draft: mock.boundary msw discovered" '"boundary": "msw"' "$out"
check "draft: a11y.lint vuejs discovered" 'vuejs-accessibility' "$out"
check "draft: contract.generate from script" 'yarn generate:api' "$out"
check "draft: lint_file from lint script" 'yarn lint {file}' "$out"
