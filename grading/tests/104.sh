#!/usr/bin/env bash
# Lesson 104: 自旋锁 — 两任务计数器竞争
# 模式: 内核

STUDENT_DIR="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"

make_kernel_quiet "$STUDENT_DIR" "ARCH=aarch64 LOG=debug SMP=2 kernel" || exit 1

OUTPUT=$(run_qemu_aarch64_smp "$(kernel_bin_path "$STUDENT_DIR")" 2 15)
check_output_contains "$OUTPUT" "20000" || exit 1
