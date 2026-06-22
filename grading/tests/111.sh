#!/usr/bin/env bash
# Lesson 111: 定时器驱动 — tick 相关日志
# 模式: 内核

STUDENT_DIR="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"

make_kernel_quiet "$STUDENT_DIR" "ARCH=aarch64 LOG=debug kernel" || exit 1

OUTPUT=$(run_qemu_aarch64 "$(kernel_bin_path "$STUDENT_DIR")" 10)
check_output_contains "$OUTPUT" "[Tt]imer|[Tt]ick|TIMER|TICK" || exit 1
