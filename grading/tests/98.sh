#!/usr/bin/env bash
# Lesson 98: 独立类型系统 — 验证 sizeof
# 模式: 单文件
# 学生提交: lessons/98_freestanding_types/type_check.c (或 .S)

STUDENT_DIR="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"

SRC_C="$STUDENT_DIR/lessons/98_freestanding_types/type_check.c"
SRC_S="$STUDENT_DIR/lessons/98_freestanding_types/type_check.S"

if check_file_exists "$SRC_C"; then
    SRC="$SRC_C"
elif check_file_exists "$SRC_S"; then
    SRC="$SRC_S"
else
    exit 1
fi

TMPELF=$(mktemp /tmp/grade_98_XXXXXX.elf)
trap "rm -f $TMPELF" EXIT

aarch64-linux-musl-gcc -nostdlib -ffreestanding -Wl,--build-id=none \
    -I "$STUDENT_DIR/$AVATAR_DIR/include" \
    -T "$GRADING_DIR/simple.ld" \
    "$SRC" -o "$TMPELF" 2>/dev/null || exit 1

OUTPUT=$(run_qemu_simple "$TMPELF" 5)
check_output_not_contains "$OUTPUT" "F" || exit 1
