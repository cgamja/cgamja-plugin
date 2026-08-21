#!/usr/bin/env bash
# PostToolUse (Edit|Write): 편집한 ts/tsx 파일만 prettier + eslint --fix. tsc 금지(느림).
source "$(dirname "$0")/_lib.sh"
f="$(j tool_input.file_path)"
case "$f" in *.ts|*.tsx) ;; *) exit 0;; esac
case "$f" in */src/api/*|*/openspec/*|*/node_modules/*) exit 0;; esac
[ -f "$f" ] || exit 0
cd "$(j cwd)" 2>/dev/null || exit 0
pnpm exec prettier --log-level warn --write "$f" >/dev/null 2>&1 || true
out="$(pnpm exec eslint --fix "$f" 2>&1)" || { echo "$out" | tail -30 >&2; exit 2; }
exit 0
