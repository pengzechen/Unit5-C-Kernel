#!/usr/bin/env bash
# grading/lib.sh — 评测系统公共函数库

set -euo pipefail

GRADING_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$GRADING_DIR/.." && pwd)"
QEMU_TIMEOUT="${QEMU_TIMEOUT:-10}"

# avatar-next 子目录名
AVATAR_DIR="avatar-next"

# --- 颜色 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# --- QEMU 运行 ---
# 对齐 avatar-next Makefile: cortex-a76, virt+virtualization=on (EL2 启动)
# 内核产物是 .bin (objcopy 后的 raw binary)

# 内部辅助: 运行 QEMU 并通过文件捕获串口输出（避免管道缓冲丢失）
_run_qemu() {
    local timeout_sec="$1"
    shift
    local outfile
    outfile=$(mktemp /tmp/qemu_out_XXXXXX)
    timeout "$timeout_sec" \
        qemu-system-aarch64 "$@" \
            -display none \
            -serial file:"$outfile" \
        >/dev/null 2>&1 || true
    cat "$outfile"
    rm -f "$outfile"
}

run_qemu_aarch64() {
    local kernel_bin="$1"
    local timeout_sec="${2:-$QEMU_TIMEOUT}"

    _run_qemu "$timeout_sec" \
        -M virt,virtualization=on \
        -cpu cortex-a76 \
        -m 2G \
        -kernel "$kernel_bin"
}

run_qemu_aarch64_smp() {
    local kernel_bin="$1"
    local cores="${2:-4}"
    local timeout_sec="${3:-$QEMU_TIMEOUT}"

    _run_qemu "$timeout_sec" \
        -M virt,virtualization=on \
        -cpu cortex-a76 \
        -smp "$cores" \
        -m 2G \
        -kernel "$kernel_bin"
}

run_qemu_aarch64_fs() {
    local kernel_bin="$1"
    local rootfs_img="$2"
    local timeout_sec="${3:-15}"
    local rootfs_addr="${4:-0x48000000}"

    _run_qemu "$timeout_sec" \
        -M virt,virtualization=on \
        -cpu cortex-a76 \
        -m 2G \
        -kernel "$kernel_bin" \
        -device loader,file="$rootfs_img",addr="$rootfs_addr",force-raw=on
}

# 简单模式 QEMU: 用于单文件课程 (97, 98), 不需要 EL2
run_qemu_simple() {
    local kernel_bin="$1"
    local timeout_sec="${2:-5}"

    _run_qemu "$timeout_sec" \
        -machine virt \
        -cpu cortex-a57 \
        -m 128M \
        -kernel "$kernel_bin"
}

# --- 输出验证 ---

check_output_contains() {
    local output="$1"
    local pattern="$2"
    echo "$output" | grep -qE "$pattern"
}

check_output_not_contains() {
    local output="$1"
    local pattern="$2"
    ! echo "$output" | grep -qE "$pattern"
}

check_output_count() {
    local output="$1"
    local pattern="$2"
    local min_count="$3"
    local actual
    actual=$(echo "$output" | grep -cE "$pattern" || true)
    [[ "$actual" -ge "$min_count" ]]
}

# --- 编译辅助 ---
# 内核编译在 avatar-next 子目录下执行

make_kernel_quiet() {
    local student_dir="$1"
    local extra_args="${2:-}"

    make -C "$student_dir/$AVATAR_DIR" $extra_args >/dev/null 2>&1
}

# 获取内核 bin 路径
kernel_bin_path() {
    local student_dir="$1"
    local arch="${2:-aarch64}"
    echo "$student_dir/$AVATAR_DIR/build/kernel_${arch}.bin"
}

# 获取 rootfs 路径
rootfs_img_path() {
    local student_dir="$1"
    local arch="${2:-aarch64}"
    echo "$student_dir/$AVATAR_DIR/build/rootfs-${arch}.img"
}

# --- 文件检查 ---

check_file_exists() {
    local filepath="$1"
    [[ -f "$filepath" ]]
}

# --- 日志 ---

log_info()  { echo -e "${CYAN}[INFO]${NC}  $*"; }
log_pass()  { echo -e "${GREEN}[PASS]${NC}  $*"; }
log_fail()  { echo -e "${RED}[FAIL]${NC}  $*"; }
log_skip()  { echo -e "${YELLOW}[SKIP]${NC}  $*"; }
