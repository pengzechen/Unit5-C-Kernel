#!/usr/bin/env bash
# Lesson 120: SMP 多核 — 4 核启动
# 模式: 内核 (SMP=4)

STUDENT_DIR="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"

make_kernel_quiet "$STUDENT_DIR" "ARCH=aarch64 LOG=debug SMP=4 kernel" || exit 1

OUTPUT=$(run_qemu_aarch64_smp "$(kernel_bin_path "$STUDENT_DIR")" 4 15)
check_output_contains "$OUTPUT" "CPU.*1.*online|cpu.*1.*online|CPU 1" || exit 1
check_output_contains "$OUTPUT" "CPU.*2.*online|cpu.*2.*online|CPU 2" || exit 1
check_output_contains "$OUTPUT" "CPU.*3.*online|cpu.*3.*online|CPU 3" || exit 1
