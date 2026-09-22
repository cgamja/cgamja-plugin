#!/usr/bin/env bash
# 커밋 범위 검사 — pre-push 템플릿의 "나가는 커밋 검사"와 같은 세 가지를 훅 밖에서 돌린다(adr/0036).
# 팀이 git 훅을 소유해 pre-push를 깔 수 없는 레포에서 CI·Stop 훅이 부른다. 사용: check-commits.sh <base-sha> <head-sha>
# 형식·혼입은 차단(exit 1), 커밋 수는 경고만 — 리뷰 라운드가 커밋을 정당하게 늘린다(adr/0031).
set -uo pipefail
base="${1:?base sha}"; head="${2:?head sha}"; fail=0
bad_msg="$(git log --no-merges --format='%h %s' "$base..$head" | grep -vE '^[0-9a-f]+ (feat|fix|refactor|test|chore|docs|style|perf|ci|build|revert)(\([^)]+\))?!?: ' || true)"
if [ -n "$bad_msg" ]; then echo "✗ 커밋 메시지 형식 위반 (docs/spec/COMMIT.md — type(scope): 요약):"; echo "$bad_msg"; fail=1; fi
for sha in $(git rev-list --no-merges "$base..$head"); do
  subject="$(git log -1 --format='%s' "$sha")"
  case "$subject" in
    feat*|fix*)
      mixed="$(git show --name-only --format='' "$sha" | grep -E '\.(test|spec)\.[jt]sx?$|/e2e/' || true)"
      if [ -n "$mixed" ]; then echo "✗ $sha ($subject) 에 테스트 파일 혼입 — test(scope): 별도 커밋으로:"; echo "$mixed"; fail=1; fi;;
  esac
done
n="$(git rev-list --count --no-merges "$base..$head" 2>/dev/null || echo 0)"
[ "$n" -gt 8 ] && echo "⚠ 커밋 ${n}개 — workflow 5장 기준(change당 4~8)을 넘었다(경고일 뿐 차단 아님). 리뷰 반영 때문이면 PR 본문에 사유 한 줄."
[ $fail -eq 0 ] && echo "commits OK"
exit $fail
