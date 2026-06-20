## Lesson 19 Round-Robin Scheduler 轮转调度器

### 代码

    /* kernel/task/sched.c — 调度器核心 */

    static list_t run_queue = LIST_INIT(run_queue);   // 就绪队列
    static spinlock_noirq_t sched_lock = SPINLOCK_NOIRQ_INIT;

    void sched_enqueue(task_t *task) {
        spin_lock_irqsave(&sched_lock);
        task->state = TASK_READY;
        list_add_tail(&task->run_node, &run_queue);   // 加到队尾
        spin_unlock_irqrestore(&sched_lock);
    }

    void schedule(void) {
        spin_lock_irqsave(&sched_lock);

        task_t *prev = task_current();
        if (prev->state == TASK_RUNNING) {
            prev->state = TASK_READY;
            list_add_tail(&prev->run_node, &run_queue); // 当前任务回到队尾
        }

        /* 从队头取下一个就绪任务 */
        task_t *next = list_first_entry(&run_queue, task_t, run_node);
        list_del(&next->run_node);
        next->state = TASK_RUNNING;

        spin_unlock_irqrestore(&sched_lock);

        if (prev != next)
            arch_task_switch(&prev->sp, next->sp);     // Lesson 18
    }

    /* 主动让出 CPU */
    void task_yield(void) {
        schedule();
    }

### 知识点

- 轮转调度 (Round-Robin) = 最公平的调度算法
  - 所有就绪任务按顺序排成环形队列
  - 每次调度取队头任务运行，时间片用完或主动让出后放回队尾
  - 每个任务获得等量的 CPU 时间 —— 简单、公平、容易理解
- 调度器 = 决定"下一个跑谁"的策略
  - `schedule()` 是调度器的核心入口 —— 从就绪队列选一个任务，调用 `arch_task_switch` 切换
  - 调度器不关心任务做什么，只关心谁在队列里、谁的优先级高
  - Avatar OS 当前用简单轮转；Linux 用 CFS（完全公平调度器）—— 但底层都是"选任务 + 切换"
- 调度的触发时机
  - **task_yield()**：任务主动让出 —— 协作式
  - **task_block()**：任务等待事件（如 mutex）—— 从就绪队列移除，不再被调度
  - **sched_tick()**：定时器中断设 `need_resched`，异常返回时调度 —— 抢占式（Lesson 20）
- 就绪队列的数据结构
  - Avatar OS 用 `list_t`（双向链表，Lesson 02 的 `container_of` 实际应用）
  - 入队 O(1)（`list_add_tail`），出队 O(1)（`list_first_entry` + `list_del`）
  - 多核时每核一个就绪队列（通过 `cpu_rq(cpu_id)` 访问）—— Lesson 24 扩展
- 调度器的锁
  - 就绪队列在中断上下文（timer tick）和任务上下文都可能被修改
  - 必须用 `spin_lock_irqsave` 保护 —— Lesson 08 的直接应用

### 课堂讨论

- 轮转调度对 I/O 密集型任务（频繁 block/unblock）和 CPU 密集型任务（长时间计算）公平吗？
- 如果就绪队列为空（没有任何任务可以运行），`schedule()` 应该怎么办？（提示：idle 任务）
- Avatar OS 的 `task_t` 有 `priority` 字段但当前未使用。如何修改 `schedule()` 支持优先级？

### 课后练习

- 测试：创建 3 个任务（A、B、C），各打印 5 次自己的名字后 `task_yield()`，观察交替顺序
- 扩展：在 `schedule()` 中加日志 `KLOG_TRACE("switch: %s → %s\n", prev->name, next->name)`
- 挑战：实现简单的优先级调度 —— 高优先级任务永远排在低优先级前面

### 参考资料

- Operating Systems: Three Easy Pieces — Chapter 7: CPU Scheduling
- Linux kernel — kernel/sched/core.c, kernel/sched/fair.c (CFS)
- Avatar OS 源码：`kernel/task/sched.c`, `kernel/task/sched.h`

---

### 本课文件

    kernel/task/sched.c
    kernel/task/sched.h

### 在本仓验证

    make ARCH=aarch64 LOG=debug
    make ARCH=aarch64 run
    # 观察多任务交替执行的日志
