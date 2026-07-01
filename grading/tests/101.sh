#!/usr/bin/env bash
# Lesson 101: 引导汇编 — BSS 清零后输出 BOOT_OK
# 模式: 内核

STUDENT_DIR="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"

OUTPUT=$(build_and_run_kernel "$STUDENT_DIR" 10)
check_output_contains "$OUTPUT" "BOOT_OK" || exit 1
