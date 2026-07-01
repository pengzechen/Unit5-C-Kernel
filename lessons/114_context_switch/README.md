## Lesson 114 Context Switch 上下文切换

### 代码

    /* kernel/task/aarch64/switch.S — AArch64 上下文切换 */
    .globl arch_task_switch
    arch_task_switch:
        /* x0 = &prev->sp,  x1 = next->sp */

        /* 保存 callee-saved 寄存器到当前栈 */
        stp x19, x20, [sp, #-16]!
        stp x21, x22, [sp, #-16]!
        stp x23, x24, [sp, #-16]!
        stp x25, x26, [sp, #-16]!
        stp x27, x28, [sp, #-16]!
        stp x29, x30, [sp, #-16]!       // x30 = LR (返回地址)

        /* 保存当前 SP 到 prev->sp */
        mov x2, sp
        str x2, [x0]

        /* 从 next->sp 恢复 SP */
        mov sp, x1

        /* 恢复 callee-saved 寄存器 */
        ldp x29, x30, [sp], #16
        ldp x27, x28, [sp], #16
        ldp x25, x26, [sp], #16
        ldp x23, x24, [sp], #16
        ldp x21, x22, [sp], #16
        ldp x19, x20, [sp], #16

        ret                              // 跳到恢复的 LR → 新任务继续执行

### 知识点

- 上下文切换 = 在两个任务之间切换 CPU 状态
  - "上下文" 就是寄存器的值 —— 保存旧任务的寄存器，恢复新任务的寄存器
  - 切换之后，CPU 认为自己一直在执行新任务 —— 对任务来说，它感知不到自己被切走过
  - 这是操作系统多任务的核心魔法：一个 CPU 模拟多个同时执行的程序
- 为什么只保存 callee-saved 寄存器
  - AArch64 ABI 规定：`x19-x28` 是 callee-saved（被调用者保存），调用函数时这些值不变
  - `x0-x18` 是 caller-saved（调用者保存），C 代码在调用 `arch_task_switch` 前已经由编译器自动处理
  - 所以只需保存 `x19-x28` + `x29`(FP) + `x30`(LR) = 12 个寄存器 —— 而不是全部 31 个
  - 这比异常入口的 `save_all_regs`（Lesson 109）高效得多
- `stp/ldp` —— AArch64 的配对存取
  - `stp x19, x20, [sp, #-16]!` = 先 `sp -= 16`，再把 x19 和 x20 存到 [sp]
  - 一条指令完成两个寄存器的存储 —— AArch64 的 RISC 设计中少有的"复杂"指令
- 切换发生的时刻
  - `str x2, [x0]` 保存完旧栈指针的那一刻，旧任务的上下文已完全保存
  - `mov sp, x1` 加载新栈指针的那一刻，CPU 开始运行在新任务的栈上
  - `ret` 跳到新任务保存的 LR —— 如果是新任务第一次运行，LR = `task_trampoline`
- 三种架构的对比
  - AArch64：保存 `x19-x30`（12 个寄存器）
  - RISC-V：保存 `s0-s11`, `ra`（13 个寄存器）
  - x86_64：保存 `rbx, rbp, r12-r15`（6 个寄存器）—— x86 callee-saved 更少

### 课堂讨论

- 如果上下文切换时不保存 `x30`(LR)，`ret` 会跳到哪里？
- 新任务的 `setup_initial_stack` 在栈上放了什么值？第一次 `ret` 后 PC 在哪？
- 上下文切换的性能开销是多少？一次切换大约多少纳秒？（提示：几十条 load/store 指令）

### 课后练习

- 测试：在 `arch_task_switch` 入口和出口各加一条 `mrs x9, cntpct_el0` 记录时间戳，计算切换耗时
- 扩展：阅读 `kernel/task/riscv64/switch.S`，列出保存的寄存器对照表
- 挑战：阅读 `task_trampoline` 的实现，理解新任务如何"第一次"开始执行

### 参考资料

- ARM Architecture Reference Manual — Procedure Call Standard (AAPCS64)
- RISC-V Calling Convention
- Avatar OS 源码：`kernel/task/aarch64/switch.S`, `kernel/task/switch.h`

---

### 参考源码

以下为 Avatar OS 中相关实现位置，仅供参考；学生可以在 `kernel/` 目录下自行设计实现结构。

    kernel/task/aarch64/switch.S
    kernel/task/riscv64/switch.S
    kernel/task/x86_64/switch.S
    kernel/task/switch.h

### 预期输出

    Switch 或 Context，并包含 cycle、ns、tick、cost 或 elapsed
