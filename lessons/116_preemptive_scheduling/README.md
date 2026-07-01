## Lesson 116 Preemptive Scheduling 抢占式调度

### 代码

    /* 抢占式调度的三步走 */

    /* 第一步：定时器中断 → 只设标志 */
    void sched_tick(void) {
        task_t *t = task_current();
        t->time_slice--;
        if (t->time_slice <= 0) {
            need_resched = 1;           // 标记"需要调度"
        }
    }

    /* 第二步：异常返回路径检查标志 */
    /* boot/aarch64/exception.S (简化) */
    exception_return:
        bl  sched_check_and_yield       // 检查 need_resched
        restore_all_regs
        eret

    /* 第三步：在安全点执行调度 */
    void sched_check_and_yield(void) {
        if (need_resched) {
            need_resched = 0;
            schedule();                  // → arch_task_switch
        }
    }

### 知识点

- 协作式 vs 抢占式
  - **协作式**：任务必须主动调用 `task_yield()` 才能让出 CPU —— 恶意或有 bug 的任务可以独占 CPU
  - **抢占式**：定时器中断强制打断任务 —— 即使任务不合作，内核也能收回 CPU
  - Avatar OS 使用抢占式调度（`timer_set_tick_cb(sched_tick)`），定时器到期即触发调度检查
- 为什么不在中断处理函数中直接切换任务
  - 中断处理函数运行在被中断任务的栈上
  - 如果在 ISR 中调用 `arch_task_switch`，保存的上下文是"中断状态的寄存器" → 恢复时混乱
  - 正确做法：ISR 只设 `need_resched` 标志 → 异常返回路径（`sched_check_and_yield`）才真正切换
  - 这就是 Avatar OS 文档 `docs/INTERRUPT_CONTEXT_SWITCH.md` 描述的**延迟调度**机制
- `preempt_count` —— 内核抢占控制
  - 有些内核代码不能被抢占（如持有 spinlock 时）
  - `preempt_count > 0` 时，即使 `need_resched=1`，也不执行调度
  - `preempt_disable()` / `preempt_enable()` 增减计数器 —— 见 `kernel/task/preempt.c`
- 中断开关策略
  - **EL0 任务的内核侧**（syscall/异常处理）：关中断运行，因为关键状态正在修改
  - **独立内核线程**（含 idle）：开中断运行，可被抢占
  - 这是 Avatar OS 的核心约定 —— 详见 `docs/INTERRUPT_CONTROL_COMPARISON.md`

### 课堂讨论

- 如果 `sched_tick()` 直接调用 `schedule()` 而不是设 `need_resched`，会出什么问题？
- `preempt_count` 是每任务的。为什么不用全局变量？（提示：多核）
- Linux 的 `PREEMPT_NONE` / `PREEMPT_VOLUNTARY` / `PREEMPT_FULL` 三种抢占模式有什么区别？

### 课后练习

- 测试：创建一个死循环任务（`while(1){}`），不调用 `task_yield()`。验证定时器中断是否能抢占它
- 扩展：在 `sched_check_and_yield` 中加日志，统计每秒发生多少次抢占
- 挑战：故意在持有 spinlock 时启用抢占（注释掉 `preempt_disable`），观察死锁现象

### 参考资料

- Operating Systems: Three Easy Pieces — Chapter 8: Multi-Level Feedback Queue
- Linux kernel — kernel/sched/core.c (preempt_count)
- Avatar OS 文档：`docs/INTERRUPT_CONTEXT_SWITCH.md`, `docs/INTERRUPT_CONTROL_COMPARISON.md`
- Avatar OS 源码：`kernel/task/preempt.c`, `kernel/task/sched.c`

---

### 参考源码

以下为 Avatar OS 中相关实现位置，仅供参考；学生可以在 `kernel/` 目录下自行设计实现结构。

    kernel/task/preempt.c
    kernel/task/preempt.h
    kernel/task/sched.c
    docs/INTERRUPT_CONTEXT_SWITCH.md
    docs/INTERRUPT_CONTROL_COMPARISON.md

### 预期输出

    preempt、Preemption、sched_tick、need_resched，或至少 2 行 Task/Thread 输出
