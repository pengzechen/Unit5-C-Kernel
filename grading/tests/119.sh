#!/usr/bin/env bash
# Lesson 119: ELF 加载器 — busybox shell 启动
# 模式: 内核

STUDENT_DIR="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"

OUTPUT=$(build_and_run_kernel "$STUDENT_DIR" 20)
check_output_contains "$OUTPUT" "busybox|BusyBox|/ #|/bin/sh|Welcome" || exit 1
