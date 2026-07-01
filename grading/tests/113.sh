#!/usr/bin/env bash
# Lesson 113: 任务控制块 — 3 个任务打印名字和 ID
# 模式: 内核

STUDENT_DIR="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"

OUTPUT=$(build_and_run_kernel "$STUDENT_DIR" 10)
check_output_count "$OUTPUT" "[Tt]ask.*[0-9]|task_[a-zA-Z]|Thread|thread" 3 || exit 1
