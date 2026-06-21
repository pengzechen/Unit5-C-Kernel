## Lesson 101 Boot Assembly 引导汇编

### 代码

    /* boot/aarch64/boot.S 核心启动序列 */
    .globl _start
    _start:
        /* 1. 关中断 */
        msr daifset, #2             // DAIF.I = 1，屏蔽 IRQ

        /* 2. 设置栈指针 */
        ldr x0, =stack_top          // 链接脚本定义的栈顶
        and x0, x0, #0xFFFFFFFF     // MMU 未开，截断为物理地址
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

        /* 4. 跳转到 C */
        bl      kernel_main

    hang:
        wfe
        b       hang

### 知识点

- 引导代码的四件事（任何架构都一样）
  - ① 关中断 —— 此时中断向量表未设置，收到中断只能死
  - ② 设栈指针 —— C 函数调用需要栈。栈未设好就 `bl` 会覆盖随机内存
  - ③ 清 BSS —— C 语言保证未初始化全局变量为零，但 DRAM 上电后是随机值
  - ④ 跳 C —— `bl kernel_main`，汇编的使命到此结束
- AArch64 特有：EL2/VHE
  - QEMU virt + virtualization=on 从 EL2 启动。Avatar OS 启用 VHE（`HCR_EL2.E2H`）
  - VHE 让内核用 EL1 寄存器名（`vbar_el1`, `ttbr0_el1`），硬件自动别名到 EL2 对应寄存器
  - 这是 boot.S 中 `init_el2_vhe` 宏做的事 —— 见源码注释
- RISC-V 特有：OpenSBI
  - RISC-V 的 M-mode 固件（OpenSBI）负责基本初始化，然后跳到 S-mode 的 `_start`
  - 入口约定：`a0` = hart ID，`a1` = 设备树地址
- `adrp` + `add` 模式
  - `adrp x0, symbol` 加载 symbol 所在 4KB 页的高位地址
  - `add x0, x0, :lo12:symbol` 补上页内偏移 —— 合起来得到完整地址
  - 这是 AArch64 的标准寻址模式，PC-relative，位置无关

### 课堂讨论

- 如果不关中断就跳 C，最可能在哪一步出错？
- `and x0, x0, #0xFFFFFFFF` 把高 32 位清零 —— 为什么 MMU 开启前需要这样做？
- RISC-V 的 `csrw stvec, t0` 和 AArch64 的 `msr vbar_el1, x0` 做的是同一件事吗？

### 课后练习

- 测试：在 BSS 清零后、跳 C 前，往 UART 输出 'B'（证明栈已可用）
- 扩展：阅读 `boot/riscv64/boot.S`，对比启动序列的异同，画出对照表
- 挑战：阅读 `_secondary_start`（次级核启动），理解为什么不需要清 BSS 和建页表

### 参考资料

- ARM Architecture Reference Manual — Reset behavior
- RISC-V Privileged ISA — Machine-mode boot sequence
- Avatar OS 源码：`boot/aarch64/boot.S`, `boot/riscv64/boot.S`, `boot/x86_64/boot.S`

---

### 本课文件

    boot/aarch64/boot.S
    boot/riscv64/boot.S
    boot/x86_64/boot.S

### 在本仓验证

    make ARCH=aarch64 LOG=debug
    make ARCH=aarch64 run
    # 观察第一行日志输出，证明 kernel_main 被成功调用
