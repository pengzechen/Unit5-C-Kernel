## Lesson 113 Task Control Block 任务控制块

### 代码

    /* kernel/task/task.h — 任务控制块核心字段 */
    typedef struct task {
        uintptr_t       sp;                  /* 保存的内核栈指针 */
        task_state_t    state;               /* READY / RUNNING / BLOCKED / DEAD */
        uint32_t        id;                  /* 唯一任务 ID */
        uint8_t         priority;            /* 0 = 最高, 255 = 最低 */
        char            name[16];            /* 任务名称 */
        uint8_t        *stack_base;          /* 栈底地址 */
        void          (*entry)(void *);      /* 入口函数 */
        void           *arg;                 /* 入口参数 */
        list_node_t     run_node;            /* 就绪队列链表节点 */
    } task_t;

    /* kernel/task/task.c — 创建任务 */
    task_t *task_create(const char *name, void (*entry)(void *),
                        void *arg, uint8_t priority) {
        task_t *t = alloc_task_slot();       // 从静态任务池分配
        t->stack_base = pmm_alloc_pages(4);  // 16KB 内核栈
        t->entry = entry;
        t->arg = arg;

        /* 在栈上构造初始上下文（假装刚被切换出去） */
        t->sp = setup_initial_stack(t);

        sched_enqueue(t);                    // 放入就绪队列
        return t;
    }

### 知识点

- 任务 = 内核调度的基本单位
  - 每个任务有自己的**栈**（存放函数调用链和局部变量）和**上下文**（寄存器状态）
  - 任务控制块（TCB）记录了一切：栈指针、状态、入口点、调度信息
  - Avatar OS 的 `task_t` 结构体就是 TCB —— Linux 中对应 `task_struct`
- 四种任务状态
  - `READY`：在就绪队列中等待被调度执行
  - `RUNNING`：当前正在 CPU 上运行（每核最多一个 RUNNING 任务）
  - `BLOCKED`：等待某个事件（I/O 完成、锁释放、子进程退出）
  - `DEAD`：已退出，等待资源回收
- 静态任务池 vs 动态分配
  - Avatar OS 使用静态数组 `task_pool[TASK_MAX]`，最多 64 个并发任务
  - 优点：不需要 `malloc`（内核可能还没实现），分配是 O(n) 扫描空闲槽
  - Linux 用 slab 分配器动态分配 `task_struct` —— 更灵活但更复杂
- `setup_initial_stack` —— 把新任务"伪装"成被切换出去的任务
  - 上下文切换恢复寄存器时，看到的和一个真正被中断的任务一样
  - 关键：`LR`（返回地址）设为 `task_trampoline`，首次调度时跳到入口函数
  - 这个技巧避免了"第一次调度"需要特殊路径的问题
- `list_node_t run_node` —— 侵入式链表
  - 任务通过 `run_node` 挂在就绪队列上，用 `container_of` 反推出 `task_t*`
  - 这就是 Lesson 98 介绍的 `container_of` 宏的实际应用

### 课堂讨论

- 为什么 `sp` 字段必须是 `task_t` 的第一个成员？（提示：汇编代码直接用偏移 0 访问）
- 如果 `stack_base` 指向的是 PMM 分配的物理页，任务栈会在哪个虚拟地址？（提示：Lesson 108 的线性映射）
- `TASK_MAX = 64` 够用吗？busybox shell 会创建多少任务？

### 课后练习

- 测试：创建 3 个内核任务，每个打印自己的名字和 ID，观察输出顺序
- 扩展：阅读 `task_t` 的完整定义，标注哪些字段是 Lesson 117（用户态）才用到的
- 里程碑自查：L01-L17 构建了一个完整的基础设施：输出(L01) → 类型(L02) → 日志(L03) → 链接(L04) → 启动(L05) → 抽象(L06) → 屏障(L07) → 锁(L08) → 物理内存(L09) → 页表(L10) → MMU(L11) → 地址空间(L12) → 异常(L13-14) → 定时器(L15) → 中断(L16) → 任务(L17)

### 参考资料

- Linux kernel — include/linux/sched.h (task_struct)
- OSDev Wiki — Kernel Multitasking
- Avatar OS 源码：`kernel/task/task.h`, `kernel/task/task.c`

---

### 参考源码

以下为 Avatar OS 中相关实现位置，仅供参考；学生可以在 `kernel/` 目录下自行设计实现结构。

    kernel/task/task.h
    kernel/task/task.c

### 预期输出

    至少 3 行 Task、task 或 Thread 相关输出
