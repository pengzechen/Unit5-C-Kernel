#!/usr/bin/env bash
# Lesson 106: 页表结构 — 手算虚拟地址索引
# 模式: 内核

STUDENT_DIR="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"

OUTPUT=$(build_and_run_kernel "$STUDENT_DIR" 10)
check_output_contains "$OUTPUT" "L[0-3]|索引|index|offset" || exit 1
check_output_contains "$OUTPUT" "234" || exit 1
