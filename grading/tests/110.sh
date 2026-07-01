#!/usr/bin/env bash
# Lesson 110: 异常处理 — 触发 Data Abort
# 模式: 内核

STUDENT_DIR="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"

OUTPUT=$(build_and_run_kernel "$STUDENT_DIR" 10)
check_output_contains "$OUTPUT" "[Dd]ata [Aa]bort|[Ff]ault|FAR|ESR|abort" || exit 1
