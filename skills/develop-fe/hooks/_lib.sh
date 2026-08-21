#!/usr/bin/env bash
# 훅 공통: stdin JSON을 $IN에, 세션 상태 디렉터리를 $STATE에. source 해서 쓴다.
IN="$(cat)"
j() { printf '%s' "$IN" | python3 -c 'import sys,json
d=json.load(sys.stdin)
for k in sys.argv[1].split("."):
    d=d.get(k) if isinstance(d,dict) else None
print("" if d is None else (d if isinstance(d,str) else json.dumps(d,ensure_ascii=False)))' "$1" 2>/dev/null; }
SID="$(j session_id)"; SID="${SID:-nosession}"
STATE="${TMPDIR:-/tmp}/cgamja-hooks/$SID"; mkdir -p "$STATE"; [ -f "$STATE/.start" ] || touch "$STATE/.start"
deny() { # $1 reason  → PreToolUse deny
  python3 -c 'import json,sys;print(json.dumps({"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":sys.argv[1]}},ensure_ascii=False))' "$1"; exit 0; }
context() { # $1 text → PreToolUse additionalContext (non-blocking)
  python3 -c 'import json,sys;print(json.dumps({"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":sys.argv[1]}},ensure_ascii=False))' "$1"; exit 0; }
block_stop() { # $1 reason → Stop block
  python3 -c 'import json,sys;print(json.dumps({"decision":"block","reason":sys.argv[1]},ensure_ascii=False))' "$1"; exit 0; }
