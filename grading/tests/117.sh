#!/usr/bin/env bash
# Lesson 117: 用户态 — 用户进程运行输出
# 模式: 内核

STUDENT_DIR="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"

OUTPUT=$(build_and_run_kernel "$STUDENT_DIR" 10)
check_output_contains "$OUTPUT" "[Uu]ser|EL0|process|[Pp]rocess" || exit 1
