#!/usr/bin/env bash
# grading/grade.sh — 学生自测入口
#
# 用法:
#   bash grading/grade.sh              # 评测所有课程
#   bash grading/grade.sh -l 97        # 只评测 Lesson 97
#   bash grading/grade.sh -l 97,98,99  # 评测多个课程

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

# --- 参数解析 ---
FILTER_LESSONS=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -l)
            FILTER_LESSONS="$2"
            shift 2
            ;;
        -h|--help)
            echo "用法: $0 [-l lesson_nums]"
            echo ""
            echo "  -l  指定课程编号（逗号分隔），如 -l 97,98,99"
            echo ""
            echo "示例:"
            echo "  bash grading/grade.sh              # 评测所有课程"
            echo "  bash grading/grade.sh -l 97        # 评测 Lesson 97"
            echo "  bash grading/grade.sh -l 97,98,99  # 评测多个课程"
            exit 0
            ;;
        *)
            echo "未知参数: $1 (用 -h 查看帮助)"
            exit 1
            ;;
    esac
done

# --- 确定要评测的课程 ---
ALL_LESSONS=(97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120)

if [[ -n "$FILTER_LESSONS" ]]; then
    IFS=',' read -ra LESSONS <<< "$FILTER_LESSONS"
else
    LESSONS=("${ALL_LESSONS[@]}")
fi

# --- 检查 avatar-next submodule ---
if [[ ! -f "$REPO_ROOT/$AVATAR_DIR/Makefile" ]]; then
    echo "错误: avatar-next submodule 未初始化"
    echo "请运行: git submodule update --init --recursive"
    exit 1
fi

# --- 运行评测 ---
PASS=0
FAIL=0
SKIP=0

log_info "开始评测 ${#LESSONS[@]} 个课程"
echo ""

for lesson in "${LESSONS[@]}"; do
    test_script="$SCRIPT_DIR/tests/${lesson}.sh"
    if [[ ! -f "$test_script" ]]; then
        log_skip "Lesson $lesson: 无评测脚本"
        SKIP=$((SKIP + 1))
        continue
    fi

    if bash "$test_script" "$REPO_ROOT" 2>/dev/null; then
        log_pass "Lesson $lesson"
        PASS=$((PASS + 1))
    else
        log_fail "Lesson $lesson"
        FAIL=$((FAIL + 1))
    fi
done

# --- 汇总 ---
echo ""
TOTAL=$((PASS + FAIL + SKIP))
echo -e "${BOLD}===== 结果汇总 =====${NC}"
echo -e "  通过: ${GREEN}${PASS}${NC} / $TOTAL"
echo -e "  失败: ${RED}${FAIL}${NC} / $TOTAL"
if [[ $SKIP -gt 0 ]]; then
    echo -e "  跳过: ${YELLOW}${SKIP}${NC} / $TOTAL"
fi
