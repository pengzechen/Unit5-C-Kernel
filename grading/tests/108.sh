#!/usr/bin/env bash
# Lesson 108: 内核地址空间 — 打印 VA 和 PA 地址对
# 模式: 内核

STUDENT_DIR="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"

OUTPUT=$(build_and_run_kernel "$STUDENT_DIR" 10)
check_output_contains "$OUTPUT" "0x[Ff][Ff][Ff][Ff]" || exit 1
check_output_contains "$OUTPUT" "kernel_main|VA|PA|virt|phys" || exit 1
