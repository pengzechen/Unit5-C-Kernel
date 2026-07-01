## Lesson 111 Timer Driver 定时器驱动

### 代码

    /* driver/timer/timer.h — 定时器 API */
    void timer_init(uint32_t freq_hz);            // 初始化，设置中断频率
    void timer_set_tick_cb(void (*cb)(void));      // 设置每 tick 回调
    uint64_t timer_get_ticks(void);                // 返回累计 tick 数

    /* AArch64 Generic Timer (driver/timer/timer_aarch64_impl.h) */
    static inline void timer_arch_set(uint64_t ticks) {
        asm volatile("msr cntp_tval_el0, %0" :: "r"(ticks));
        /* 启用定时器 */
        uint64_t ctl = 1;  // ENABLE=1, IMASK=0
        asm volatile("msr cntp_ctl_el0, %0" :: "r"(ctl));
    }

    /* 定时器中断处理（在 exception_handler_c 中被调用）*/
    void timer_irq_handler(void) {
        g_system_ticks++;
        cpu_bump_local_ticks();     // 更新本核 tick 计数
        timer_arch_set(interval);   // 重新装载，准备下一次中断

        if (g_tick_cb)
            g_tick_cb();            // → sched_tick() → 设 need_resched
    }

### 知识点

- 定时器 = 操作系统的心跳
  - 没有定时器，内核只能协作式调度（靠任务主动让出 CPU）
  - 有了定时器中断，内核可以在固定间隔（如 100Hz = 每 10ms）强制抢占当前任务
  - 这就是**抢占式调度**的硬件基础 —— Lesson 116 详解
- 三种架构的定时器
  - AArch64：Generic Timer（`CNTP_TVAL_EL0`, `CNTP_CTL_EL0`），ARM 标准外设
  - RISC-V：`mtimecmp`（M-mode 设置）或 SBI timer 调用，中断号 5
  - x86_64：LAPIC Timer（本地高级可编程中断控制器的定时器）
  - Avatar OS 用架构抽象（`timer_aarch64_impl.h` 等）统一接口
- 定时器中断的处理流程
  - ① 中断到来 → 异常向量表 IRQ 项 → `exception_handler_c`
  - ② 识别为定时器 → `timer_irq_handler()`
  - ③ 增加全局 tick 计数 + 重装载定时器 + 调用 `sched_tick()`
  - ④ `sched_tick()` 只设 `need_resched` 标志（不在中断中切换！—— Lesson 116 解释原因）
  - ⑤ 异常返回路径检查 `need_resched`，如果为真才真正做上下文切换
- Avatar OS 真实 bug：x86_64 LAPIC timer 只增加 `g_system_ticks` 没调 `cpu_bump_local_ticks()`
  - 结果：多核健康检查看到全局 tick 在涨，本核 tick 永远是 0 → 误判核挂了
  - 修复：一行代码 `cpu_bump_local_ticks();` —— 见 commit `dc7c131`

### 课堂讨论

- 100Hz 和 1000Hz 的 tick 频率各有什么优缺点？Linux 默认 250Hz 是怎么权衡的？
- AArch64 的 `CNTFRQ_EL0` 是什么？为什么需要读取系统计数器频率而不是硬编码？
- 如果 `timer_arch_set()` 忘记重装载（不重新设 `TVAL`），定时器中断还会再来吗？

### 课后练习

- 测试：修改 tick 频率为 10Hz（100ms 间隔），观察调度延迟的变化
- 扩展：阅读三个架构的 `timer_*_impl.h`，列出定时器寄存器名称对照表
- 挑战：在 `timer_irq_handler` 中打印 tick 计数，观察是否影响系统性能（为什么？）

### 参考资料

- ARM Architecture Reference Manual — Generic Timer
- RISC-V Privileged ISA — Timer and Counter Registers
- Intel SDM — Chapter 10: APIC (Local APIC Timer)
- Avatar OS 源码：`driver/timer/timer.h`, `driver/timer/timer.c`

---

### 参考源码

以下为 Avatar OS 中相关实现位置，仅供参考；学生可以在 `kernel/` 目录下自行设计实现结构。

    driver/timer/timer.h
    driver/timer/timer.c
    driver/timer/timer_aarch64_impl.h
    driver/timer/timer_riscv64_impl.h
    driver/timer/timer_x86_64_impl.h

### 预期输出

    Timer 或 Tick
