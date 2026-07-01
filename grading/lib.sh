#!/usr/bin/env bash
# grading/lib.sh — 评测系统公共函数库

set -euo pipefail

GRADING_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$GRADING_DIR/.." && pwd)"
QEMU_TIMEOUT="${QEMU_TIMEOUT:-10}"

# --- 颜色 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# --- 路径 ---

kernel_dir() {
    local student_dir="$1"
    echo "$student_dir/kernel"
}

kernel_elf_path() {
    local student_dir="$1"
    echo "$(kernel_dir "$student_dir")/build/kernel.elf"
}

# --- 编译辅助 ---

make_kernel_clean() {
    local student_dir="$1"
    make -C "$(kernel_dir "$student_dir")" clean >/dev/null
}

make_kernel_build() {
    local student_dir="$1"
    local log_file
    log_file="$(mktemp /tmp/kernel_build_XXXXXX.log)"

    if make -C "$(kernel_dir "$student_dir")" build >"$log_file" 2>&1; then
        rm -f "$log_file"
        return 0
    fi

    echo "===== kernel build failed =====" >&2
    cat "$log_file" >&2
    echo "===== end of build log =====" >&2
    rm -f "$log_file"
    return 1
}

build_kernel() {
    local student_dir="$1"

    make_kernel_clean "$student_dir"
    make_kernel_build "$student_dir"
    check_file_exists "$(kernel_elf_path "$student_dir")"
}

# --- QEMU 运行 ---

_run_qemu() {
    local timeout_sec="$1"
    shift
    local outfile
    outfile="$(mktemp /tmp/qemu_out_XXXXXX)"

    timeout "$timeout_sec" \
        qemu-system-aarch64 "$@" \
            -display none \
            -serial file:"$outfile" \
        >/dev/null 2>&1 || true

    cat "$outfile"
    rm -f "$outfile"
}

run_qemu_kernel() {
    local kernel_elf="$1"
    local timeout_sec="${2:-$QEMU_TIMEOUT}"

    _run_qemu "$timeout_sec" \
        -machine virt \
        -cpu cortex-a57 \
        -m 128M \
        -kernel "$kernel_elf"
}

run_qemu_kernel_smp() {
    local kernel_elf="$1"
    local cores="${2:-4}"
    local timeout_sec="${3:-$QEMU_TIMEOUT}"

    _run_qemu "$timeout_sec" \
        -machine virt \
        -cpu cortex-a57 \
        -smp "$cores" \
        -m 128M \
        -kernel "$kernel_elf"
}

build_and_run_kernel() {
    local student_dir="$1"
    local timeout_sec="${2:-$QEMU_TIMEOUT}"

    build_kernel "$student_dir"
    run_qemu_kernel "$(kernel_elf_path "$student_dir")" "$timeout_sec"
}

build_and_run_kernel_smp() {
    local student_dir="$1"
    local cores="${2:-4}"
    local timeout_sec="${3:-$QEMU_TIMEOUT}"

    build_kernel "$student_dir"
    run_qemu_kernel_smp "$(kernel_elf_path "$student_dir")" "$cores" "$timeout_sec"
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
    actual="$(echo "$output" | grep -cE "$pattern" || true)"
    [[ "$actual" -ge "$min_count" ]]
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
