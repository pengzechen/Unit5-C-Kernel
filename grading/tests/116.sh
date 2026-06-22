#!/usr/bin/env bash
# Lesson 116: 抢占式调度 — 死循环任务被抢占
# 模式: 内核

STUDENT_DIR="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"

make_kernel_quiet "$STUDENT_DIR" "ARCH=aarch64 LOG=debug kernel" || exit 1

OUTPUT=$(run_qemu_aarch64 "$(kernel_bin_path "$STUDENT_DIR")" 15)

check_output_contains "$OUTPUT" "preempt|[Pp]reemption|sched_tick|need_resched" || \
check_output_count "$OUTPUT" "[Tt]ask|[Tt]hread" 2 || exit 1
