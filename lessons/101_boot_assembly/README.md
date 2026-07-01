## Lesson 101 Boot Assembly 引导汇编

### 代码

    /* kernel/boot.S 核心启动序列 */
    .globl _start
    _start:
        /* 1. 关中断 */
        msr daifset, #0xf           // 屏蔽 Debug/SError/IRQ/FIQ

        /* 2. 设置栈指针 */
        ldr x0, =stack_top          // 链接脚本定义的栈顶
        mov sp, x0

        /* 3. 清零 BSS */
        adrp    x0, __bss_start
        add     x0, x0, :lo12:__bss_start
        adrp    x1, __bss_end
        add     x1, x1, :lo12:__bss_end
        mov     x2, #0
    clear_bss:
        cmp     x0, x1
        b.ge    clear_bss_done
        str     x2, [x0], #8       // 每次清 8 字节，x0 自增
        b       clear_bss
    clear_bss_done:

        /* 4. 调用 C 函数验证栈 */
        bl      boot_check

    hang:
        wfe
        b       hang

    /* kernel/main.c 栈验证示例 */
    #define UART0 ((volatile unsigned char *)0x09000000)

    static void uart_puts(const char *s)
    {
        while (*s) {
            *UART0 = (unsigned char)*s++;
        }
    }

    void boot_check(void)
    {
        volatile unsigned long stack_probe[4];

        stack_probe[0] = 0x11111111;
        stack_probe[1] = 0x22222222;
        stack_probe[2] = 0x33333333;
        stack_probe[3] = 0x44444444;

        if (stack_probe[0] == 0x11111111 &&
            stack_probe[1] == 0x22222222 &&
            stack_probe[2] == 0x33333333 &&
            stack_probe[3] == 0x44444444) {
            uart_puts("BOOT_OK\n");
        }
    }

### 知识点

- 引导代码的四件事（任何架构都一样）
  - ① 关中断 —— 此时中断向量表未设置，收到中断只能死
  - ② 设栈指针 —— C 函数调用需要栈。栈未设好就 `bl` 会覆盖随机内存
  - ③ 清 BSS —— C 语言保证未初始化全局变量为零，但 DRAM 上电后是随机值
  - ④ 跳 C —— `bl boot_check`，用 C 函数验证栈可读写
- 栈验证
  - `bl boot_check` 会使用链接寄存器和 C 调用约定
  - `boot_check()` 中的局部数组会实际落到栈上
  - 局部数组读写成功后输出 `BOOT_OK`，证明栈已经指向可用 RAM，且不会立即破坏代码、只读数据或 BSS
- RISC-V 特有：OpenSBI
  - RISC-V 的 M-mode 固件（OpenSBI）负责基本初始化，然后跳到 S-mode 的 `_start`
  - 入口约定：`a0` = hart ID，`a1` = 设备树地址
- `adrp` + `add` 模式
  - `adrp x0, symbol` 加载 symbol 所在 4KB 页的高位地址
  - `add x0, x0, :lo12:symbol` 补上页内偏移 —— 合起来得到完整地址
  - 这是 AArch64 常见的 PC-relative 取地址方式，真实内核启动代码中很常见

### 进阶：EL2/VHE

- Avatar OS 的完整启动路径支持从 EL2 启动，并可以启用 VHE (`HCR_EL2.E2H`)
- VHE 让宿主内核运行在 EL2 时仍接近 EL1 内核的编程模型，主要服务虚拟化/Hypervisor 场景
- 本教学主线默认不要求实现 EL2/VHE；理解基础启动、异常、MMU 后再阅读参考源码中的相关初始化更合适

### 课堂讨论

- 如果不关中断就跳 C，最可能在哪一步出错？
- 为什么 `stack_top` 要按 16 字节对齐？AArch64 函数调用约定对 SP 有什么要求？
- 如果 `boot_check()` 中的局部数组读写失败，最可能是哪一步启动初始化有问题？

### 课后练习

- 测试：设置栈、清零 BSS 后调用 C 函数 `boot_check()`，在函数中使用局部数组验证栈可读写，成功后输出 `BOOT_OK`
- 扩展：阅读 `boot/riscv64/boot.S`，对比启动序列的异同，画出对照表
- 挑战：阅读 `_secondary_start`（次级核启动），理解为什么不需要清 BSS 和建页表

### 参考资料

- ARM Architecture Reference Manual — Reset behavior
- RISC-V Privileged ISA — Machine-mode boot sequence
- Avatar OS 源码：`boot/aarch64/boot.S`, `boot/riscv64/boot.S`, `boot/x86_64/boot.S`

---

### 参考源码

以下为 Avatar OS 中相关实现位置，仅供参考；学生可以在 `kernel/` 目录下自行设计实现结构。

    boot/aarch64/boot.S
    boot/riscv64/boot.S
    boot/x86_64/boot.S

### 预期输出

    BOOT_OK
