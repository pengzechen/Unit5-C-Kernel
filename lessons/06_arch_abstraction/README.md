## Lesson 06 Architecture Abstraction 架构抽象层

### 代码

    /* include/arch.h — 编译时架构检测 */
    #if defined(__aarch64__)
        #define ARCH_AARCH64 1
        #define ARCH_NAME "AArch64"
    #elif defined(__riscv) && (__riscv_xlen == 64)
        #define ARCH_RISCV64 1
        #define ARCH_NAME "RISC-V 64"
    #elif defined(__x86_64__)
        #define ARCH_X86_64  1
        #define ARCH_NAME "x86_64"
    #endif

    /* include/barrier.h — 统一接口 + 架构特化 */
    static inline void barrier_data(void);      // 声明

    #if ARCH_AARCH64
        #include "aarch64/barrier_impl.h"       // dsb sy
    #elif ARCH_RISCV64
        #include "riscv64/barrier_impl.h"       // fence rw, rw
    #elif ARCH_X86_64
        #include "x86_64/barrier_impl.h"        // mfence
    #endif

    /* include/aarch64/barrier_impl.h */
    static inline void barrier_data(void) {
        asm volatile("dsb sy" ::: "memory");
    }

### 知识点

- 一份头文件，三种实现
  - 公共头文件（`barrier.h`, `spinlock.h`）定义接口和数据结构
  - 架构目录（`aarch64/`, `riscv64/`, `x86_64/`）提供 `_impl.h` 内联实现
  - Makefile 不需要 `#ifdef` 选源文件 —— 头文件通过 `#include` 自动分派
- 为什么用 `static inline` 而不是 `.c` + 链接
  - 内核的热路径（锁、屏障、中断开关）每秒执行百万次
  - 函数调用开销（保存/恢复寄存器）不可接受 —— 必须内联
  - `static inline` 在每个翻译单元内联展开，不产生外部符号，不会重复定义
- 架构检测的两层
  - 编译器内置宏：`__aarch64__`, `__riscv`, `__x86_64__` —— 由交叉编译器自动定义
  - Avatar OS 宏：`ARCH_AARCH64`, `ARCH_RISCV64`, `ARCH_X86_64` —— 统一命名，避免直接依赖编译器行为
- Linux 内核也这么做
  - Linux 的 `arch/arm64/include/asm/barrier.h` 对应 Avatar OS 的 `include/aarch64/barrier_impl.h`
  - 但 Linux 用 Makefile + Kconfig 选择 `arch/` 目录，Avatar OS 用头文件 `#if` 更简单

### 课堂讨论

- 如果一个函数太复杂（100 行），不适合 `static inline`，应该放在哪里？（提示：`lib/` 目录）
- `asm volatile("dsb sy" ::: "memory")` 中的 `"memory"` clobber 是给编译器看的还是给 CPU 看的？
- 能否用 C11 `_Generic` 替代 `#if` 做架构分派？为什么内核通常不这么做？

### 课后练习

- 测试：在 `kernel_main` 中 `kprintf("Architecture: %s\n", ARCH_NAME);`，用三个架构分别编译运行
- 扩展：阅读 `include/spinlock.h`，画出接口层 → 实现层的 include 关系图
- 挑战：尝试在 `barrier.h` 中 `#include` 一个不存在的架构实现，观察编译错误信息

### 参考资料

- GCC Predefined Macros: https://gcc.gnu.org/onlinedocs/cpp/Predefined-Macros.html
- Linux kernel arch/ layout: https://www.kernel.org/doc/html/latest/process/howto.html
- Avatar OS 源码：`include/arch.h`, `include/barrier.h`, `include/spinlock.h`

---

### 本课文件

    include/arch.h
    include/barrier.h
    include/aarch64/barrier_impl.h
    include/riscv64/barrier_impl.h
    include/x86_64/barrier_impl.h

### 在本仓验证

    make ARCH=aarch64 && make ARCH=riscv64 && make ARCH=x86_64
    # 三个架构都能编译通过，证明抽象层完备
