## Lesson 110 Exception Handling 异常处理

### 代码

    /* boot/aarch64/exception.c — C 异常处理入口 */
    void exception_handler_c(uint64_t type, uint64_t esr, uint64_t elr,
                             uint64_t far, uint64_t sp) {
        uint32_t ec = (esr >> 26) & 0x3F;    // Exception Class

        switch (ec) {
            case 0x15:  // SVC (AArch64)
                handle_svc(elr, sp);          // → syscall 分发
                break;
            case 0x20:  // Instruction Abort (lower EL)
            case 0x21:  // Instruction Abort (same EL)
                handle_instruction_abort(far, esr, elr);
                break;
            case 0x24:  // Data Abort (lower EL)
            case 0x25:  // Data Abort (same EL)
                handle_data_abort(far, esr, elr);
                break;
            default:
                KLOG_ERROR("Unhandled exception: EC=0x%x ELR=0x%llx FAR=0x%llx\n",
                           ec, elr, far);
                panic();
        }
    }

    /* RISC-V: scause 寄存器包含异常原因 */
    /* scause[63] = 1 → 中断, scause[63] = 0 → 异常 */
    if (scause & (1ULL << 63)) {
        uint64_t code = scause & 0xFF;
        if (code == 5) timer_interrupt();       // S-mode timer
        else if (code == 9) plic_handle_irq();  // External interrupt
    } else {
        if (scause == 8) handle_ecall();        // Environment call (syscall)
        else if (scause == 13 || scause == 15)  // Load/Store page fault
            handle_page_fault(stval);
    }

### 知识点

- ESR (Exception Syndrome Register) —— 异常的身份证
  - AArch64: `ESR_EL1` 的 EC 字段（bit[31:26]）告诉你是哪种异常
  - `EC=0x15` = SVC（系统调用），`EC=0x24` = Data Abort（数据访问错误）
  - ISS 字段（bit[24:0]）提供更细的信息（如数据故障的类型、是读还是写）
- FAR (Fault Address Register)
  - 当发生地址相关异常时，`FAR_EL1` 保存触发异常的虚拟地址
  - 用于缺页处理：知道哪个地址访问失败了 → 可以分配物理页并映射
  - 不是所有异常都设 FAR —— 如 SVC 调用，FAR 无意义
- ELR (Exception Link Register)
  - 保存异常返回地址 —— `eret` 会跳回这个地址
  - 同步异常：ELR = 触发异常的指令地址（SVC）或下一条指令（取决于异常类型）
  - IRQ：ELR = 被中断的指令的下一条
- 中断 vs 异常的处理差异
  - 异常是同步的：处理完可以修复原因（如映射缺页），然后返回重试
  - 中断是异步的：来自外部设备，处理完直接返回被中断的代码继续执行
  - Avatar OS 的 `exception_handler_c` 统一入口，用 `type` 参数区分

### 课堂讨论

- Data Abort 的 FAR 指向一个未映射的地址。内核应该 panic 还是尝试分配物理页？什么时候该 panic？
- 异常处理函数中能否调用 `task_yield()`（让出 CPU）？为什么 Avatar OS 不在异常处理函数中做上下文切换？
- RISC-V 的 `scause` 用最高位区分中断/异常。AArch64 是怎么区分的？

### 课后练习

- 测试：在 `kernel_main` 中写 `*(volatile int *)0 = 42;`，触发 Data Abort，观察异常信息输出
- 扩展：列出 AArch64 ESR_EL1 中所有常见的 EC 值及其含义
- 挑战：阅读 `docs/INTERRUPT_CONTEXT_SWITCH.md`，理解为什么不能在 ISR 内切换任务

### 参考资料

- ARM Architecture Reference Manual — D13.2: Exception syndrome register
- RISC-V Privileged ISA — scause, stval registers
- Avatar OS 文档：`docs/INTERRUPT_CONTEXT_SWITCH.md`
- Avatar OS 源码：`boot/aarch64/exception.c`, `boot/riscv64/exception.c`

---

### 本课文件

    boot/aarch64/exception.c
    boot/riscv64/exception.c
    boot/x86_64/exception.c
    include/aarch64/exception.h
    include/riscv64/exception.h
    docs/INTERRUPT_CONTEXT_SWITCH.md

### 在本仓验证

    make ARCH=aarch64 LOG=debug
    make ARCH=aarch64 run
    # 观察异常处理输出
