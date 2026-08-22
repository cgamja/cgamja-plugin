#!/usr/bin/env bash
# develop-setup preflight — 프로젝트를 읽어 "발견 표"와 "대조표(철학 원칙 ↔ 강제 수단)"를 출력한다(adr/0014). 스택을 정하지 않는다.
# 사용: bash scripts/preflight.sh [project-dir]   종료코드 0 = 대조표에 ✗ 없음, 1 = ✗ 있음, 2 = 디렉터리 없음
set -u
ROOT="${1:-.}"; cd "$ROOT" || { echo "no such dir: $ROOT"; exit 2; }
missing=0
row() { if [ "$2" -eq 0 ]; then printf "  ✓ %-30s %s\n" "$1" "${4:-}"; else printf "  ✗ %-30s %s\n" "$1" "$3"; missing=1; fi; }
has() { [ -e "$1" ]; }
pj() { [ -f package.json ] && python3 -c "import json,sys;d=json.load(open('package.json'));print(json.dumps({**d.get('dependencies',{}),**d.get('devDependencies',{}),'__scripts':d.get('scripts',{})}))" 2>/dev/null; }
PKG="$(pj)"
dep() { [ -n "$PKG" ] && grep -q "\"$1\"" <<<"$PKG"; }
script() { [ -n "$PKG" ] && python3 -c "import json,sys;d=json.loads(sys.argv[1]);sys.exit(0 if sys.argv[2] in d['__scripts'] else 1)" "$PKG" "$1" 2>/dev/null; }
cfgkey() { [ -f .claude/cgamja.json ] && python3 -c "
import json,sys;d=json.load(open('.claude/cgamja.json'))
for k in sys.argv[1].split('.'): d=d.get(k) if isinstance(d,dict) else None
sys.exit(0 if d not in (None,'',[]) else 1)" "$1" 2>/dev/null; }

echo "develop-setup preflight @ $(pwd)"
echo "— 발견"
if [ -f package.json ]; then
  pm=npm; [ -f pnpm-lock.yaml ] && pm=pnpm; [ -f yarn.lock ] && pm=yarn; [ -f bun.lockb ] && pm=bun
  fw=""; for d in next nuxt @sveltejs/kit astro remix @remix-run/react expo react-native vue svelte solid-js @angular/core react vite; do dep "$d" && fw="$fw $d"; done
  echo "  · 매니페스트 package.json · 러너 $pm · 프레임워크:${fw:- (미감지)}"
  tr_=""; for d in vitest jest jest-expo @playwright/test cypress @testing-library/react @testing-library/vue @testing-library/svelte @vue/test-utils; do dep "$d" && tr_="$tr_ $d"; done
  echo "  · 테스트 도구:${tr_:- 없음}"
  li=""; for d in eslint oxlint biome @biomejs/biome prettier stylelint; do dep "$d" && li="$li $d"; done
  echo "  · 린트/포맷:${li:- 없음}"
  hk=""; for d in lefthook husky simple-git-hooks @commitlint/cli; do dep "$d" && hk="$hk $d"; done
  echo "  · 커밋 훅:${hk:- 없음}"
elif [ -f pyproject.toml ] || [ -f Gemfile ] || [ -f go.mod ] || [ -f Cargo.toml ] || [ -f pubspec.yaml ]; then
  echo "  · 매니페스트 $(ls pyproject.toml Gemfile go.mod Cargo.toml pubspec.yaml 2>/dev/null | tr '\n' ' ')— JS 프론트가 아님: 검증된 조각 없음, 원칙만 적용"
else
  echo "  · 매니페스트 없음 → 빈 폴더. 스캐폴더를 사용자에게 묻고 그 명령만 실행한 뒤 다시 preflight"
fi
tests_found="$(find . -path ./node_modules -prune -o \( -name '*.test.*' -o -name '*.spec.*' -o -name '*_test.*' \) -type f -print 2>/dev/null | head -200 | sed -E 's#.*/##; s#^[^.]*##' | sort | uniq -c | sort -rn | head -3 | awk '{printf "%s×%s ", $2, $1}')"
echo "  · 기존 테스트 파일 규약: ${tests_found:-없음}  (e2e 디렉터리: $(ls -d e2e cypress tests/e2e .maestro 2>/dev/null | tr '\n' ' '))"
echo "  · 계약 원천 후보: $(ls api/openapi.* openapi.* swagger.* schema.graphql *.graphql *.proto 2>/dev/null | tr '\n' ' ')$( [ -d src/api ] && echo '· src/api/ 있음')"
echo "  · 디자인 자산: $( [ -d design ] && echo 'design/' )$( has design/NO_FIGMA && echo '(NO_FIGMA)' )$( ls design/tokens.json src/styles/tokens.css tokens.json 2>/dev/null | tr '\n' ' ')"
echo "  · CI: $(ls .github/workflows/*.yml .gitlab-ci.yml 2>/dev/null | tr '\n' ' ')"
echo "  · 에이전트 설정: $(ls CLAUDE.md AGENTS.md .claude/settings.json .claude/cgamja.json 2>/dev/null | tr '\n' ' ')$( [ -d .claude/rules ] && echo '.claude/rules/ ' )$( [ -d openspec ] && echo 'openspec/ ' )"
echo "  · 다른 도구의 채널: $(ls CONCEPTS.md STRATEGY.md .compound-engineering/config.local.yaml 2>/dev/null | tr '\n' ' ')$( [ -d docs/solutions ] && echo 'docs/solutions/ ' )$( [ -d docs/plans ] && echo 'docs/plans/(CE — 이 플러그인은 OpenSpec change를 쓴다) ' )  ← 있으면 그대로 쓴다, 중복 원천을 만들지 않는다"

echo "— 대조표 (철학 원칙 ↔ 강제 수단)"
row "선언 .claude/cgamja.json"     $(has .claude/cgamja.json && echo 0 || echo 1)   "templates/cgamja.json — 발견값으로 채운다"
row "P3 commands.verify"           $( (cfgkey commands.verify || script verify) && echo 0 || echo 1) "타입·린트·테스트(·계약 드리프트·미사용) 한 명령"
row "P2 tests.patterns + 훅"       $( (cfgkey tests.patterns && has .claude/hooks/protect-files.sh) && echo 0 || echo 1) "templates/hooks/ + 선언 tests.patterns"
row "P7 contract.source"           $(cfgkey contract.source && echo 0 || echo 1)   "원천 파일 선언 또는 null(retrofit change 안내)"
row "P7 contract.generated + 드리프트" $( (cfgkey contract.generated && script api:check) && echo 0 || echo 1) "생성물 glob + 재생성 diff 0 검사가 verify에"
row "P7 mock.boundary"             $(cfgkey mock.boundary && echo 0 || echo 1)     "경계 mock(계약 밖 요청 = 에러)"
row "P8 domains.root + 경계 린트"  $( (cfgkey domains.root && ls eslint.config.* biome.json* .oxlintrc* >/dev/null 2>&1) && echo 0 || echo 1) "기존 린터에 경계 규칙(React: templates/react/eslint.boundaries.js)"
row "P5 a11y.lint"                 $(cfgkey a11y.lint && echo 0 || echo 1)         "프레임워크별 a11y 린트 또는 null"
row "P5 a11y.runtime"              $(cfgkey a11y.runtime && echo 0 || echo 1)      "axe 등 또는 null"
row "P4 design.source"             $(cfgkey design.source && echo 0 || echo 1)     "figma:<fileKey> 또는 none"
row "P4 design.tokens"             $(cfgkey design.tokens && echo 0 || echo 1)     "토큰 파일 경로"
row "P6 platform.profile"          $( (cfgkey platform.profile && has .claude/rules/platform.md) && echo 0 || echo 1) "web-desktop | web-mobile | native + rules/platform.md"
row "P10 커밋 규약"                $( (ls commitlint.config.* >/dev/null 2>&1 && (has lefthook.yml || has .husky || dep simple-git-hooks)) && echo 0 || echo 1) "commitlint + commit-msg 훅(테스트/구현 분리)"
row "보호 protected + 훅"          $( (cfgkey protected && has .claude/hooks/protect-bash.sh && has .claude/settings.json) && echo 0 || echo 1) "templates/settings.json + hooks/"
row "Stop 훅 verify"               $( (has .claude/settings.json && grep -q '"Stop"' .claude/settings.json) && echo 0 || echo 1) "settings.json Stop → commands.verify"
row "CLAUDE.md (@import 없음)"     $( (has CLAUDE.md && ! grep -qE '^@|[[:space:]]@[a-zA-Z./]' CLAUDE.md) && echo 0 || echo 1) "templates/CLAUDE.md — 백틱 포인터만"
row ".claude/rules/*.md"           $(ls .claude/rules/*.md >/dev/null 2>&1 && echo 0 || echo 1) "templates/rules/"
row "docs/adr/0001 + conventions"  $( (has docs/adr/0001-domain-structure.md && has docs/conventions.md) && echo 0 || echo 1) "templates/adr-0001-domain-structure.md, conventions.md"
row "OpenSpec feature 스키마"      $(has openspec/schemas/feature/schema.yaml && echo 0 || echo 1) "openspec init → schema fork spec-driven feature"
row "CI에 verify"                  $(grep -lE "verify" .github/workflows/*.yml .gitlab-ci.yml 2>/dev/null | grep -q . && echo 0 || echo 1) "기존 CI에 verify·commitlint·openspec validate 단계 추가"

echo
if [ $missing -eq 0 ]; then echo "대조표 ✗ 없음. /develop-fe 로 진행."; exit 0; else echo "✗ 항목만 develop-setup 1장 질문 → 2장 순서로 붙인다. 스택은 바꾸지 않는다."; exit 1; fi
