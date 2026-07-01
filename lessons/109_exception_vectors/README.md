## Lesson 109 Exception Vectors 异常向量表

### 代码

    /* AArch64 异常向量表 (boot/aarch64/exception.S) */

    /*
     * 每个向量项固定 128 字节（32 条指令），必须 2KB 对齐
     * 4 组 × 4 种异常 = 16 个向量项
     *
     * 组别：
     *   Current EL, SP_EL0    ← 内核用 SP_EL0（Avatar OS 不用）
     *   Current EL, SP_ELx    ← 内核用 SP_EL1（主要路径）
     *   Lower EL, AArch64     ← 用户态异常（Lesson 117）
     *   Lower EL, AArch32     ← 32位用户态（不支持）
     *
     * 异常类型：
     *   Synchronous    ← SVC (系统调用), 缺页, 非法指令
     *   IRQ            ← 外部中断 (定时器, 设备)
     *   FIQ            ← 快速中断 (通常不用)
     *   SError         ← 异步异常 (总线错误)
     */

    .align 11                               // 2KB 对齐
    .globl exception_vector_base
    exception_vector_base:
        /* Current EL, SP_ELx, Synchronous */
        save_all_regs                        // 保存 x0-x30, ELR, SPSR, SP
        mov x0, #0                           // 异常类型编号
        bl  exception_handler_c              // 跳 C 处理
        restore_all_regs                     // 恢复寄存器
        eret                                 // Exception Return

        .align 7                             // 每项 128 字节对齐
        /* Current EL, SP_ELx, IRQ */
        save_all_regs
        mov x0, #1
        bl  exception_handler_c
        restore_all_regs
        eret
        ...

### 知识点

- 异常向量表 = CPU 遇到异常时的跳转目标
  - CPU 检测到异常 → 自动查向量表 → 跳到对应地址执行
  - AArch64 用 `VBAR_EL1` 寄存器指向向量表基址
  - RISC-V 用 `stvec` 寄存器（MODE=0 直接模式，MODE=1 向量模式）
  - x86_64 用 IDT (Interrupt Descriptor Table)，由 `LIDT` 指令加载
- 异常的四种来源
  - **同步异常 (Synchronous)**：指令执行直接触发 —— SVC（系统调用）、缺页、非法指令、断点
  - **IRQ**：外部中断 —— 定时器到期、设备完成操作、其他核发来的 IPI
  - **FIQ**：快速中断 —— 通常保留给安全世界或调试器
  - **SError**：异步异常 —— 总线错误，发生在写缓冲提交时
- 保存/恢复现场
  - 进入异常时 CPU 只自动保存 PC（→ ELR）和状态（→ SPSR）
  - 其余 31 个通用寄存器必须由软件保存 —— 这就是 `save_all_regs` 宏做的事
  - `eret` 指令同时恢复 PC 和状态，是异常返回的唯一正确方式
- `eret` vs `ret`
  - `ret` 是普通函数返回（从 LR 取地址）
  - `eret` 是异常返回（从 ELR 取地址 + 恢复 SPSR 中的中断掩码和特权级）
  - 用错会导致特权级不对、中断状态错乱

### 课堂讨论

- 每个向量项只有 128 字节（32 条指令）。如果处理代码超过 32 条指令怎么办？（提示：`b` 跳转）
- RISC-V 的 `stvec` 直接模式只有一个入口点，所有异常都跳到同一个地址。优缺点是什么？
- 如果异常处理函数中又发生异常（嵌套异常），会发生什么？

### 课后练习

- 测试：在 `exception_handler_c` 中加 `KLOG_INFO("Exception: type=%d\n", type);`，然后故意触发一个非法内存访问
- 扩展：对比 `boot/aarch64/exception.S` 和 `boot/riscv64/exception.S` 的向量表结构
- 挑战：计算 AArch64 向量表的总大小（16 × 128 字节），理解为什么要 2KB 对齐

### 参考资料

- ARM Architecture Reference Manual — D1.10: Exception vectors
- RISC-V Privileged ISA — stvec register
- Intel SDM — Chapter 6: Interrupt and Exception Handling
- Avatar OS 源码：`boot/aarch64/exception.S`, `boot/aarch64/exception.c`

---

### 参考源码

以下为 Avatar OS 中相关实现位置，仅供参考；学生可以在 `kernel/` 目录下自行设计实现结构。

    boot/aarch64/exception.S
    boot/aarch64/exception.c
    boot/riscv64/exception.S
    boot/riscv64/exception.c
    boot/x86_64/exception.S
    boot/x86_64/exception.c

### 预期输出

    Exception type
