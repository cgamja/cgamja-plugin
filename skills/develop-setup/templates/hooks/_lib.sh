#!/usr/bin/env bash
# 훅 공통: stdin JSON을 $IN에. source 해서 쓴다.
IN="$(cat)"
j() { printf '%s' "$IN" | python3 -c 'import sys,json
d=json.load(sys.stdin)
for k in sys.argv[1].split("."):
    d=d.get(k) if isinstance(d,dict) else None
print("" if d is None else (d if isinstance(d,str) else json.dumps(d,ensure_ascii=False)))' "$1" 2>/dev/null; }
deny() { # $1 reason → PreToolUse deny (exit 2 + stderr도 함께: 구버전 호환)
  python3 -c 'import json,sys;print(json.dumps({"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":sys.argv[1]}},ensure_ascii=False))' "$1"
  echo "$1" >&2; exit 2; }
ask() { # $1 reason → PreToolUse ask: 사람이 diff를 보고 승인(대화형). 비대화형(-p)에서는 skip-permissions여도 거부(실측 adr/0009)
  python3 -c 'import json,sys;print(json.dumps({"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":sys.argv[1]}},ensure_ascii=False))' "$1"; exit 0; }
