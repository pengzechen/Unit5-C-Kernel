#!/usr/bin/env bash
# Lesson 98: 独立类型系统 — 验证 sizeof
# 模式: 内核

STUDENT_DIR="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"

OUTPUT=$(build_and_run_kernel "$STUDENT_DIR" 5)
check_output_not_contains "$OUTPUT" "F" || exit 1
