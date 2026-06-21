## Lesson 99 Kernel Logging 内核日志系统

### 代码

    /* 使用 klog 输出 */
    #include "klog.h"

    KLOG_INFO("=== Avatar OS Kernel ===\n");
    KLOG_ERROR("Critical error: %s\n", msg);
    KLOG_MODULE_DEBUG(LOG_MODULE_MM, "page alloc: pa=0x%llx\n", pa);

    /* klog 的宏展开真面目 */
    #define KLOG_INFO(fmt, ...) \
        do { \
            if (g_log_level >= LOG_LEVEL_INFO) { \
                kprintf("\x1b[32m" "[INFO][C%u] " "%s:%d: " fmt \
                       "\x1b[0m" "", \
                       klog_cpu_id(), __FILE__, __LINE__, ##__VA_ARGS__); \
            } \
        } while (0)

    /* 调用链: KLOG_INFO → kprintf → kvprintf → klog_putchar → uart_putchar */

### 知识点

- 内核日志 vs printf
  - 内核没有 libc，`kprintf` 是 Avatar OS 自己实现的格式化输出 —— 见 `lib/vsnprintf.c`
  - 调用链的最底层是 `uart_putchar(char c)`：Lesson 97 的单字节写 UART，由平台层提供
  - 和 Linux 的 `printk` 角色相同：所有内核调试信息的唯一窗口
- 日志级别与模块控制
  - 5 级过滤：NONE < ERROR < WARN < INFO < DEBUG < TRACE
  - 模块掩码：64 位 bitmask，每个子系统占 1 位（UART、TIMER、MM、TASK...）
  - 编译时 `LOG=none` 可以通过 `#if` 把所有日志宏替换为空 `do {} while(0)` —— 零开销
- `do { ... } while(0)` 包装宏的理由
  - 让宏在 if/else 中表现得像单条语句：`if (x) KLOG_INFO("ok"); else ...` 不会断裂
  - 这是 Linux 内核风格，Avatar OS 全面采用
- ANSI 颜色码
  - `\x1b[31m` = 红色，`\x1b[32m` = 绿色 —— 让 ERROR 和 INFO 在终端上一眼可辨
  - `[C%u]` 显示 CPU 编号 —— 多核调试时区分是哪个核在说话（Lesson 120）

### 课堂讨论

- `##__VA_ARGS__` 中的 `##` 有什么特殊作用？（提示：当可变参数为空时，逗号怎么办？）
- 如果在中断处理函数中调用 `KLOG_INFO`，而 UART 驱动用了 spinlock，会发生什么？
- `LOG=none` 编译的内核比 `LOG=debug` 小多少？怎么测量？

### 课后练习

- 测试：在 `kernel_main` 中添加 `KLOG_DEBUG("hello from kernel\n")`，用 `make ARCH=aarch64 LOG=debug` 编译运行
- 扩展：添加一个新的日志模块 `LOG_MODULE_TEST (1ULL << 9)`，用 `KLOG_MODULE_DEBUG` 输出
- 挑战：阅读 `lib/vsnprintf.c`，理解 `%p` 格式是如何输出指针的（与 Linux 的 `%px` / `%pK` 对比）

### 参考资料

- Linux kernel printk: https://www.kernel.org/doc/html/latest/core-api/printk-basics.html
- Avatar OS 文档：`docs/KLOG_GUIDE.md`
- Avatar OS 源码：`include/klog.h`, `lib/klog.c`, `lib/vsnprintf.c`

---

### 本课文件

    include/klog.h
    lib/klog.c
    lib/vsnprintf.c

### 在本仓验证

    make ARCH=aarch64 LOG=debug
    make ARCH=aarch64 run
    # 观察串口输出的彩色日志
