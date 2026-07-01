#!/usr/bin/env bash
# Lesson 118: 系统调用 — 用汇编写用户程序输出 "OK"
# 模式: 内核

STUDENT_DIR="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"

OUTPUT=$(build_and_run_kernel "$STUDENT_DIR" 10)
check_output_contains "$OUTPUT" "OK" || exit 1
