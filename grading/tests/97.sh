#!/usr/bin/env bash
# Lesson 97: 裸机第一声 — 输出 "Hello\n"
# 模式: 单文件
# 学生提交: lessons/97_bare_metal_hello/boot_hello.S

STUDENT_DIR="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"

SRC="$STUDENT_DIR/lessons/97_bare_metal_hello/boot_hello.S"
check_file_exists "$SRC" || exit 1

TMPELF=$(mktemp /tmp/grade_97_XXXXXX.elf)
trap "rm -f $TMPELF" EXIT

aarch64-linux-musl-gcc -nostdlib -Wl,--build-id=none \
    -T "$STUDENT_DIR/$AVATAR_DIR/boot/aarch64/link.ld" \
    "$SRC" -o "$TMPELF" 2>/dev/null || exit 1

OUTPUT=$(run_qemu_simple "$TMPELF" 5)
check_output_contains "$OUTPUT" "Hello" || exit 1
