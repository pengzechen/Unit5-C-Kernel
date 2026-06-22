#!/usr/bin/env bash
# Lesson 103: 内存屏障 — 列出指令对应关系
# 模式: 单文件（文本回答）

STUDENT_DIR="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"

ANSWER="$STUDENT_DIR/lessons/103_memory_barriers/answer.txt"
check_file_exists "$ANSWER" || exit 1

CONTENT=$(cat "$ANSWER")
check_output_contains "$CONTENT" "dmb|dsb|isb" || exit 1
