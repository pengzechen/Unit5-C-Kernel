#!/usr/bin/env bash
# Lesson 97: 裸机第一声 — 输出 "Hello\n"
# 模式: 内核

STUDENT_DIR="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"

OUTPUT=$(build_and_run_kernel "$STUDENT_DIR" 5)
check_output_contains "$OUTPUT" "Hello" || exit 1
