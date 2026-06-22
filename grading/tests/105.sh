#!/usr/bin/env bash
# Lesson 105: 物理内存管理器 — 分配 10 页并打印地址
# 模式: 内核

STUDENT_DIR="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"

make_kernel_quiet "$STUDENT_DIR" "ARCH=aarch64 LOG=debug kernel" || exit 1

OUTPUT=$(run_qemu_aarch64 "$(kernel_bin_path "$STUDENT_DIR")" 10)
check_output_contains "$OUTPUT" "PMM|pmm|alloc" || exit 1
check_output_count "$OUTPUT" "0x[0-9a-fA-F]+000\b" 10 || exit 1
