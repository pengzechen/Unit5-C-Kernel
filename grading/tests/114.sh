#!/usr/bin/env bash
# Lesson 114: 上下文切换 — 输出切换耗时
# 模式: 内核

STUDENT_DIR="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"

OUTPUT=$(build_and_run_kernel "$STUDENT_DIR" 10)
check_output_contains "$OUTPUT" "[Ss]witch|[Cc]ontext" || exit 1
check_output_contains "$OUTPUT" "[0-9].*cycle|[0-9].*ns|[0-9].*tick|cost|elapsed" || exit 1
