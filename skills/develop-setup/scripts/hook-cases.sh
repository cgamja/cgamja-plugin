#!/usr/bin/env bash
# 훅 케이스 표 — protect-bash.sh 가 "무엇을 막고 무엇을 통과시키는가"를 고정한다.
#
# 왜 있나: 훅 오탐이 네 번 재발했고(adr/0017·0023, retro 2026-08-26·08-27·08-31),
# 매번 "정규식을 조금 더 정밀하게" 로 고쳤지만 테스트가 없어 회귀를 못 잡았다.
# 정밀화의 방향은 항상 같다 — **명령의 대상**과 **명령 텍스트에 등장하는 문자열**을 구분하는 것.
#
#   bash hook-cases.sh <project-dir> [hook-path]
# hook-path 를 주면 설치 전 템플릿을 그대로 검증할 수 있다(프로젝트 훅은 보호 파일이라 쉘 복사가 막힌다).
# 종료코드 0 = 전부 기대대로.
set -uo pipefail
DIR="${1:?project dir (cgamja.json 이 있는 곳)}"
HOOK="${2:-$DIR/.claude/hooks/protect-bash.sh}"
[ -f "$HOOK" ] || { echo "✗ $HOOK 없음"; exit 1; }

pass=0; fail=0
run() { printf '{"cwd":"%s","tool_input":{"command":%s}}' "$DIR" "$(python3 -c 'import json,sys;print(json.dumps(sys.argv[1]))' "$1")" | bash "$HOOK" >/dev/null 2>&1; echo $?; }
want() { # $1 deny|allow  $2 설명  $3 명령
  local got; got="$(run "$3")"
  local ok
  case "$1" in
    deny)  [ "$got" = 2 ] && ok=1 || ok=0;;
    allow) [ "$got" = 0 ] && ok=1 || ok=0;;
  esac
  if [ "$ok" = 1 ]; then pass=$((pass+1)); printf "  ✓ %-6s %s\n" "$1" "$2"
  else fail=$((fail+1)); printf "  ✗ %-6s %s\n      exit=%s (want %s)\n      cmd: %s\n" "$1" "$2" "$got" "$1" "$3"; fi
}

echo "## 진짜 막아야 하는 것 (이게 통과하면 훅이 무의미하다)"
want deny "훅 우회 --no-verify"                 'git commit --no-verify -m x'
want deny "푸시 강제"                            'git push --force origin main'
want deny "패키지 추가"                          'npm install lodash'
want deny "패키지 추가(pnpm)"                    'pnpm add lodash'
want deny "테스트 파일 리다이렉트 쓰기"          'echo x > src/x.test.ts'
want deny "테스트 파일 sed -i"                   "sed -i '' s/a/b/ src/x.test.ts"
want deny "테스트 파일 perl -pi"                 'perl -pi -e s/a/b/ src/x.test.ts'
want deny "보호 파일 리다이렉트 쓰기"            'echo x > package.json'
want deny "TDD_PHASE 인라인"                     'TDD_PHASE=red npx vitest run'
want deny "core.hooksPath 설정"                  'git config core.hooksPath /dev/null'

echo
echo "## 읽기·조회는 통과해야 한다"
want allow "테스트 파일 읽기 + 리다이렉트"       'cat src/x.test.ts 2>&1'
want allow "부분 읽기"                           'sed -n 1,5p src/a.ts'
want allow "git diff"                            'git diff'
want allow "hooksPath 조회"                      'git config core.hooksPath'

echo
echo "## 오탐 — 명령의 '대상'이 아니라 '텍스트'에 반응하던 것들"
want allow "인자 없는 install + 리다이렉트 (훅이 스스로 권장한 복구 경로)" \
  'npm install 2>&1 | tail -4'
want allow "인자 없는 install + 로그 리다이렉트" \
  'npm install > /tmp/install.log 2>&1'
want allow "heredoc 본문에 보호 파일명이 '적혀 있을' 뿐" \
  'cat > notes.md <<EOF
package.json 을 고치려면 Edit 도구를 쓴다
.claude/hooks/protect-bash.sh 가 막는다
EOF'
want allow "커밋 메시지에 테스트 파일명 언급" \
  'git commit -m "test(x): src/x.test.ts 추가"'
# 실측(2026-08-31): tasks.md 를 heredoc 으로 쓰다 거부됨 — 본문의 `.claude/hooks/...` 언급과
# 플레이스홀더 `<develop-setup>` 의 `>` 가 겹쳐 "보호 파일에 리다이렉트 쓰기"로 읽혔다.
want allow "heredoc 본문의 파일명 + 꺾쇠 플레이스홀더" \
  'cat > openspec/changes/x/tasks.md <<EOF
- [ ] 3.2 보호 훅(.claude/hooks/protect-files.sh)에 경로를 stdin 으로 넣어 프로브한다
  → verify: bash <develop-setup>/scripts/smoke.sh check .
EOF'
want allow "프로젝트 밖(절대경로) 테스트 파일 생성" \
  'cat > /tmp/scratch/probe.test.tsx <<EOF
export const a = 1;
EOF'
want allow "프로젝트 밖(절대경로) 보호 파일명 쓰기" \
  'echo "{}" > /tmp/scratch/package.json'
# 실측(2026-08-31, 0028 적용 직후): 설명용 echo 안의 "npm install" 이 설치 명령으로 읽혔다.
want allow "echo 문자열에 적힌 설치 명령" \
  'echo "--- npm install + 리다이렉트 재현 ---"'
want allow "주석처럼 쓴 문자열 + 실제로는 인자 없는 install" \
  'echo "npm install lodash 는 막혀야 한다"
npm install'

# 실측(2026-08-31, adr/0030 병렬 프로브): worktree 사본의 .env 쓰기가 차단돼 프로브 자체가 못 돌았다.
# .claude/worktrees/ 아래는 gitignore된 일회용 트리다 — 원본이 아니므로 보호 대상이 아니다(adr/0031).
want allow "worktree 사본의 .env 쓰기(상대경로)" \
  'printf "PORT=5301\n" > .claude/worktrees/probe-a/.env'
want allow "worktree 사본의 보호 파일(절대경로)" \
  "echo '{}' > $DIR/.claude/worktrees/probe-b/package.json"

want allow "worktree 사본의 테스트 파일 생성" \
  'cat > .claude/worktrees/probe-a/src/x.test.ts <<EOF
export const a = 1;
EOF'

echo
echo "## 위 완화가 진짜 차단을 뚫지 않았는가"
want deny "원본 .env 는 여전히 보호"             'printf "PORT=1\n" > .env'
want deny "worktrees 와 이름만 비슷한 경로"      'echo x > .claude/worktrees-backup/.env'
want deny "따옴표로 감싼 패키지명"               'npm install "lodash"'
want deny "cd 뒤에 오는 설치"                    'cd packages/web && npm install lodash'
want deny "echo 뒤 세그먼트의 설치"              'echo start; npm install lodash'

echo
echo "hook-cases: passed $pass, failed $fail"
[ "$fail" -eq 0 ]
