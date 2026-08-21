#!/usr/bin/env bash
# develop-setup preflight: 무엇이 이미 있는지 표로 출력. 0 = 전부 있음, 1 = 일부 없음.
# 사용: bash scripts/preflight.sh [project-dir]
set -u
ROOT="${1:-.}"
cd "$ROOT" || { echo "no such dir: $ROOT"; exit 2; }

missing=0
row() { # name, condition(0/1), hint
  if [ "$2" -eq 0 ]; then printf "  ✓ %-32s %s\n" "$1" ""; else printf "  ✗ %-32s %s\n" "$1" "$3"; missing=1; fi
}
has_file() { [ -e "$1" ]; }
has_script() { [ -f package.json ] && grep -q "\"$1\"[[:space:]]*:" package.json; }
has_dep() { [ -f package.json ] && grep -q "\"$1\"" package.json; }

echo "develop-setup preflight @ $(pwd)"
echo "— 플랫폼"
if has_dep next; then echo "  · next (App Router)"; elif has_dep expo; then echo "  · expo (expo-router)"; elif has_dep vite; then echo "  · vite"; else echo "  · (package.json 없음 또는 프레임워크 미감지 → 1단계 스캐폴드 필요)"; fi

echo "— 문서/규칙"
row "CLAUDE.md"                  $([ -f CLAUDE.md ] && echo 0 || echo 1)                       "templates/CLAUDE.md"
row "CLAUDE.md has no @import"   $([ -f CLAUDE.md ] && ! grep -qE '^@|[[:space:]]@[a-zA-Z./]' CLAUDE.md && echo 0 || echo 1) "@ import는 eager — 백틱 포인터로"
row ".claude/rules/*.md"         $(ls .claude/rules/*.md >/dev/null 2>&1 && echo 0 || echo 1)  "templates/rules/"
row ".claude/rules/platform.md"   $(has_file .claude/rules/platform.md && echo 0 || echo 1)  "templates/rules/platform-{web,expo}.md"
row "docs/adr/0001-domain-structure.md" $(has_file docs/adr/0001-domain-structure.md && echo 0 || echo 1) "templates/adr-0001-domain-structure.md"
row "docs/conventions.md"        $(has_file docs/conventions.md && echo 0 || echo 1)           "templates/conventions.md"

echo "— 구조"
row "src/domains/"               $([ -d src/domains ] && echo 0 || echo 1)                     "domains/<name>/{ui,model,api,index.ts}"
row "src/shared/"                $([ -d src/shared ] && echo 0 || echo 1)                      "shared/{ui,lib,config}"

echo "— 린트/검증"
row "eslint config"              $(ls eslint.config.* >/dev/null 2>&1 && echo 0 || echo 1)     "templates/eslint.boundaries.js"
row "eslint-plugin-boundaries"   $(has_dep eslint-plugin-boundaries && echo 0 || echo 1)       "pnpm add -D eslint-plugin-boundaries"
row "script: verify"             $(has_script verify && echo 0 || echo 1)                      "tsc --noEmit && eslint . && <test> && knip"
row "knip"                       $(has_dep knip && echo 0 || echo 1)                           "pnpm add -D knip"
row "test runner"                $( (has_dep vitest || has_dep jest-expo) && echo 0 || echo 1) "vitest(웹) / jest-expo(RN)"
row "e2e"                        $( (has_dep @playwright/test || [ -d .maestro ] || [ -d maestro ]) && echo 0 || echo 1) "playwright(웹) / maestro(RN)"
row "commitlint"                 $(ls commitlint.config.* >/dev/null 2>&1 && echo 0 || echo 1) "templates/lefthook.yml + commitlint"
row "lefthook.yml"               $(has_file lefthook.yml && echo 0 || echo 1)                  "templates/lefthook.yml"

echo "— Claude Code"
row ".claude/settings.json"      $(has_file .claude/settings.json && echo 0 || echo 1)         "templates/settings.json"
row "settings: Stop hook"        $(has_file .claude/settings.json && grep -q '"Stop"' .claude/settings.json && echo 0 || echo 1) "pnpm verify on Stop"
row "settings: permissions.deny" $(has_file .claude/settings.json && grep -q '"deny"' .claude/settings.json && echo 0 || echo 1) "--no-verify 등"

echo "— API 계약"
row "api/openapi.yaml"            $(has_file api/openapi.yaml && echo 0 || echo 1)               "templates/openapi.draft.yaml (또는 api:pull)"
row "orval.config.ts"             $(has_file orval.config.ts && echo 0 || echo 1)                "templates/orval.config.ts"
row "script: api:check"           $(has_script api:check && echo 0 || echo 1)                    "orval && git diff --exit-code -- src/api"
row "src/api/*.gen.ts"            $(ls src/api/*.gen.ts >/dev/null 2>&1 && echo 0 || echo 1)     "pnpm api:gen"

echo "— OpenSpec"
row "@fission-ai/openspec (devDep)"  $(has_dep @fission-ai/openspec && echo 0 || echo 1)          "pnpm add -D @fission-ai/openspec"
row "openspec/config.yaml"       $(has_file openspec/config.yaml && echo 0 || echo 1)          "openspec init --tools claude --profile core ."
row "openspec/schemas/feature"   $(has_file openspec/schemas/feature/schema.yaml && echo 0 || echo 1) "schema fork spec-driven feature"
row ".claude/commands/opsx"      $([ -d .claude/commands/opsx ] && echo 0 || echo 1)           "openspec init이 생성"

if [ -d design ] && ! has_file design/NO_FIGMA; then   # Figma 없음(design/ 없음 또는 design/NO_FIGMA)이면 섹션 자체를 생략
echo "— 디자인"
row "design/tokens.json"         $(has_file design/tokens.json && echo 0 || echo 1)            "Figma Variables export"
row "design/map.md"              $(has_file design/map.md && echo 0 || echo 1)                 "get_metadata 트리"
fi

echo "— CI"
row ".github/workflows"          $(ls .github/workflows/*.yml >/dev/null 2>&1 && echo 0 || echo 1) "templates/ci.yml"

echo
if [ $missing -eq 0 ]; then echo "세팅 완료. /develop-fe 로 진행."; exit 0; else echo "✗ 항목을 develop-setup 2장 순서대로 만든다."; exit 1; fi
