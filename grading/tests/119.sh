#!/usr/bin/env bash
# Lesson 119: ELF 加载器 — busybox shell 启动
# 模式: 内核 (需要 rootfs)

STUDENT_DIR="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"

make_kernel_quiet "$STUDENT_DIR" "ARCH=aarch64 kernel" || exit 1
make_kernel_quiet "$STUDENT_DIR" "ARCH=aarch64 rootfs" || exit 1

KBIN=$(kernel_bin_path "$STUDENT_DIR")
ROOTFS=$(rootfs_img_path "$STUDENT_DIR")
check_file_exists "$KBIN" || exit 1
check_file_exists "$ROOTFS" || exit 1

OUTPUT=$(run_qemu_aarch64_fs "$KBIN" "$ROOTFS" 20)
check_output_contains "$OUTPUT" "busybox|BusyBox|/ #|/bin/sh|Welcome" || exit 1
