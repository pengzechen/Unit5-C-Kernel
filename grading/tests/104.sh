#!/usr/bin/env bash
# Lesson 104: 自旋锁 — 两任务计数器竞争
# 模式: 内核

STUDENT_DIR="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"

OUTPUT=$(build_and_run_kernel_smp "$STUDENT_DIR" 2 15)
check_output_contains "$OUTPUT" "20000" || exit 1
