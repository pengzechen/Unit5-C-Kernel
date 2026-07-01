#!/usr/bin/env bash
# Lesson 112: 中断控制器 — 打印中断列表
# 模式: 内核

STUDENT_DIR="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"

OUTPUT=$(build_and_run_kernel "$STUDENT_DIR" 10)
check_output_contains "$OUTPUT" "GIC|IRQ|[Ii]nterrupt|irq" || exit 1
