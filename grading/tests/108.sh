#!/usr/bin/env bash
# Lesson 108: 内核地址空间 — 打印 VA 和 PA 地址对
# 模式: 内核

STUDENT_DIR="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"

make_kernel_quiet "$STUDENT_DIR" "ARCH=aarch64 LOG=debug kernel" || exit 1

OUTPUT=$(run_qemu_aarch64 "$(kernel_bin_path "$STUDENT_DIR")" 10)
check_output_contains "$OUTPUT" "0x[Ff][Ff][Ff][Ff]" || exit 1
check_output_contains "$OUTPUT" "kernel_main|VA|PA|virt|phys" || exit 1
