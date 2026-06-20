## Lesson 21 User Mode 用户态

### 代码

    /* 从内核态切换到用户态 (AArch64) */

    /* task_trampoline_user — 新用户进程首次调度时执行 */
    task_trampoline_user:
        /* 设置 SPSR_EL1: 返回 EL0 (用户态) */
        mov x0, #0                          // SPSR = 0 → EL0, 中断开
        msr spsr_el1, x0

        /* 设置 ELR_EL1: 用户态入口地址 */
        ldr x0, [current_task, #USER_ENTRY]  // task->user_entry
        msr elr_el1, x0

        /* 设置 SP_EL0: 用户栈指针 */
        ldr x0, [current_task, #USER_SP]
        msr sp_el0, x0

        /* 切换页表到用户地址空间 */
        ldr x0, [current_task, #PGD]         // task->pgd (物理地址)
        msr ttbr0_el1, x0
        isb
        tlbi vmalle1                         // 刷新 TLB
        dsb sy
        isb

        /* 跳到用户态！ */
        eret                                 // ELR → PC, SPSR → PSTATE

    /* 用户态测试程序 (apps/aarch64/hello.S) */
    .globl _start
    _start:
        mov x0, #1              // fd = stdout
        ldr x1, =msg            // buf = "hello"
        mov x2, #6              // len = 6
        mov x8, #64             // syscall: write
        svc #0                  // → 陷入内核
        mov x8, #93             // syscall: exit
        svc #0
    msg:
        .ascii "hello\n"

### 知识点

- 用户态 = CPU 的低特权级
  - AArch64: EL0（用户）vs EL1（内核）—— 用户态不能执行特权指令（`msr`, `eret` 等）
  - RISC-V: U-mode vs S-mode —— 用户态不能访问 CSR 寄存器
  - x86_64: Ring 3 vs Ring 0 —— 用户态不能执行 `in/out`, `lgdt` 等
  - 目的：保护内核不被用户程序破坏 —— 用户程序的 bug 只能 crash 自己，不会搞坏内核
- `eret` 的双重作用
  - 同时设置 PC（从 ELR）和特权级（从 SPSR）—— 这是唯一的特权级切换方式
  - SPSR 中 M[3:0]=0b0000 表示 EL0 —— `eret` 之后 CPU 进入用户态
  - 用户态要回到内核只能通过 `svc`（系统调用）或异常/中断
- 地址空间隔离
  - 每个用户进程有自己的 `pgd`（页表），加载到 `TTBR0_EL1`
  - 用户空间地址 (`0x0000_xxxx`) 通过 TTBR0 翻译 —— 不同进程的 TTBR0 指向不同页表
  - 内核空间 (`0xFFFF_xxxx`) 通过 TTBR1 翻译 —— 所有进程共享同一个内核页表
  - 切换进程 = 切换 TTBR0 + 刷 TLB
- Avatar OS 的进程创建
  - `process_create()`: 分配用户页表 + 映射用户代码 + 设置用户栈 + 创建任务
  - `process_create_with_pgd()`: 使用外部已准备好的页表（ELF 加载器用 —— Lesson 23）

### 课堂讨论

- 用户程序执行 `msr vbar_el1, x0` 会发生什么？内核如何处理这个异常？
- 为什么切换 TTBR0 后需要 `tlbi vmalle1` + `dsb sy` + `isb`？省略任何一个会怎样？
- x86_64 没有 `eret`，它怎么从 Ring 0 跳到 Ring 3？（提示：`sysret` 或 `iret`）

### 课后练习

- 测试：用 `apps/aarch64/hello.S` 编译一个用户程序，用 `process_create` 加载运行
- 扩展：比较 `task_trampoline`（内核线程入口）和 `task_trampoline_user`（用户进程入口）的区别
- 挑战：写一个用户程序故意访问 `0xFFFF_xxxx`（内核地址），观察 Data Abort

### 参考资料

- ARM Architecture Reference Manual — D1.6: Exception level and Security state
- RISC-V Privileged ISA — U-mode
- Intel SDM — Chapter 5: Protection (Ring 0-3)
- Avatar OS 源码：`kernel/task/task.c` (process_create), `apps/aarch64/hello.S`

---

### 本课文件

    kernel/task/task.c
    kernel/task/switch.h
    apps/aarch64/hello.S
    apps/riscv64/hello.S
    apps/x86_64/hello.S

### 在本仓验证

    make ARCH=aarch64 LOG=debug
    make ARCH=aarch64 run
    # 观察用户进程启动和系统调用日志
