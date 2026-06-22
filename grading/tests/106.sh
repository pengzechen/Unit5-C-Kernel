#!/usr/bin/env bash
# Lesson 106: 页表结构 — 手算虚拟地址索引
# 模式: 单文件（文本回答）

STUDENT_DIR="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"

ANSWER="$STUDENT_DIR/lessons/106_page_tables/answer.txt"
check_file_exists "$ANSWER" || exit 1

CONTENT=$(cat "$ANSWER")
check_output_contains "$CONTENT" "L[0-3]|索引|index|offset" || exit 1
check_output_contains "$CONTENT" "234" || exit 1
