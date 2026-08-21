#!/usr/bin/env bash
# 결정적 스크립트(훅·preflight·CLI) 회귀 테스트. 사용: bash tests/run.sh   (LLM 호출 없음, 수 초)
cd "$(dirname "$0")/.." || exit 1
export TMPDIR="$(mktemp -d)"; trap 'rm -rf "$TMPDIR"' EXIT
pass=0; fail=0
check() { # name, expected-substring-or-empty, actual
  if [ -z "$2" ] && [ -z "$3" ] || { [ -n "$2" ] && grep -q -- "$2" <<<"$3"; }; then pass=$((pass+1)); printf "  ✓ %s\n" "$1"
  else fail=$((fail+1)); printf "  ✗ %s\n      expected: %s\n      got:      %s\n" "$1" "${2:-<empty>}" "$(head -c 200 <<<"$3")"; fi; }
hook() { printf '%s' "$2" | "$1" 2>/dev/null; }   # script, stdin json
for t in tests/test_*.sh; do echo "## $t"; source "$t"; done
echo; echo "passed $pass, failed $fail"; [ "$fail" -eq 0 ]
