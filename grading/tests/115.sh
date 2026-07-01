#!/usr/bin/env bash
# Lesson 115: 轮转调度 — A/B/C 交替输出各 5 次
# 模式: 内核

STUDENT_DIR="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"

OUTPUT=$(build_and_run_kernel "$STUDENT_DIR" 15)

A_COUNT=$(echo "$OUTPUT" | grep -c "[Tt]ask.*A\|task_A\|Thread.*A" || true)
B_COUNT=$(echo "$OUTPUT" | grep -c "[Tt]ask.*B\|task_B\|Thread.*B" || true)
C_COUNT=$(echo "$OUTPUT" | grep -c "[Tt]ask.*C\|task_C\|Thread.*C" || true)

[[ "$A_COUNT" -ge 5 && "$B_COUNT" -ge 5 && "$C_COUNT" -ge 5 ]] || exit 1
