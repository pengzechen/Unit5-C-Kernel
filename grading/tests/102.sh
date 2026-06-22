#!/usr/bin/env bash
# Lesson 102: 架构抽象层 — 三架构编译 + 输出 ARCH_NAME
# 模式: 内核

STUDENT_DIR="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"

make_kernel_quiet "$STUDENT_DIR" "ARCH=aarch64 kernel" || exit 1
make_kernel_quiet "$STUDENT_DIR" "ARCH=riscv64 kernel" || exit 1
make_kernel_quiet "$STUDENT_DIR" "ARCH=x86_64 kernel"  || exit 1

OUTPUT=$(run_qemu_aarch64 "$(kernel_bin_path "$STUDENT_DIR")" 10)
check_output_contains "$OUTPUT" "Architecture:" || exit 1
