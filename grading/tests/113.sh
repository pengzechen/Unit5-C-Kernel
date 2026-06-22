#!/usr/bin/env bash
# Lesson 113: 任务控制块 — 3 个任务打印名字和 ID
# 模式: 内核

STUDENT_DIR="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"

make_kernel_quiet "$STUDENT_DIR" "ARCH=aarch64 LOG=debug kernel" || exit 1

OUTPUT=$(run_qemu_aarch64 "$(kernel_bin_path "$STUDENT_DIR")" 10)
check_output_count "$OUTPUT" "[Tt]ask.*[0-9]|task_[a-zA-Z]|Thread|thread" 3 || exit 1
