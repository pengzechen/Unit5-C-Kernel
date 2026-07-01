#!/usr/bin/env bash
# Lesson 102: 架构抽象层 — 三架构编译 + 输出 ARCH_NAME
# 模式: 内核

STUDENT_DIR="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"

OUTPUT=$(build_and_run_kernel "$STUDENT_DIR" 10)
check_output_contains "$OUTPUT" "Architecture:" || exit 1
