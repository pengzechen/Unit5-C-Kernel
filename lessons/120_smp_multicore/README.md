## Lesson 120 SMP Multicore 多核启动与调度

### 代码

    /* boot/aarch64/boot.S — 次级核启动 */
    .globl _secondary_start
    _secondary_start:
        mov     x19, x0                 // x0 = cpu_id (PSCI CPU_ON 传入)

        init_el2_vhe                     // 与 BSP 相同的 EL2/VHE 初始化
        msr     daifset, #2              // 关中断

        /* 使用 per-CPU 启动栈 */
        ldr     x0, =secondary_boot_stacks
        add     x1, x19, #1
        lsl     x1, x1, #12             // (cpu_id+1) * 4096
        add     x0, x0, x1
        mov     sp, x0

        /* 复用 BSP 的内核页表 */
        bl      vm_get_kernel_pgtable
        mov     x1, x0                  // TTBR1 = 内核页表
        bl      mmu_init                 // 开 MMU

        /* Trampoline 跳到高 VA */
        ldr     x0, =1f
        br      x0
    1:
        /* 安装异常向量（与 BSP 同一份） */
        msr     vbar_el1, exception_vector_base
        dsb sy
        isb

        /* 进入 C: cpu_secondary_bootstrap(cpu_id) */
        mov     x0, x19
        bl      cpu_secondary_bootstrap

    /* kernel/task/cpu.c — per-CPU 数据与 AP 启动 */
    typedef struct per_cpu {
        task_t      *current_task;       // 当前运行的任务
        task_t       idle_task;          // 本核 idle 任务
        list_t       run_queue;          // 本核就绪队列
        spinlock_noirq_t rq_lock;       // 就绪队列锁
        uint64_t     local_ticks;        // 本核 tick 计数
    } per_cpu_t;

    per_cpu_t g_per_cpu[MAX_CPUS];

    void cpu_secondary_bootstrap(uint32_t cpu_id) {
        /* 安装 per-CPU 指针到 TPIDR_EL1 */
        write_tpidr_el1(&g_per_cpu[cpu_id]);

        /* 初始化本核 idle 任务和就绪队列 */
        idle_task_init(cpu_id);

        /* 启用本核定时器 */
        timer_init_secondary();

        /* 开中断，进入 idle 循环 */
        arch_irq_enable();
        idle_loop();    // while(1) { schedule(); wfi(); }
    }

### 知识点

- SMP (Symmetric Multi-Processing) = 多核对称处理
  - BSP (Bootstrap Processor)：第一个启动的核，执行全部初始化
  - AP (Application Processor)：其他核，由 BSP 通过 PSCI/SIPI 唤醒
  - AP 复用 BSP 已建好的页表和异常向量 —— 不需要重新建立
- BSP 与 AP 的启动差异
  - BSP：清 BSS → 建页表 → 开 MMU → 初始化所有子系统 → `kernel_main`
  - AP：跳过 BSS/页表 → 复用 BSP 页表开 MMU → 只初始化 per-CPU 状态 → `idle_loop`
  - 关键：AP 使用独立的启动栈（`secondary_boot_stacks[cpu_id]`），避免和 BSP 冲突
- Per-CPU 数据
  - 每核有自己的 `current_task`、`run_queue`、`idle_task` —— 不能共享
  - AArch64 用 `TPIDR_EL1` 寄存器存 per-CPU 指针，每核读自己的
  - RISC-V 用 `tp` 寄存器，x86_64 用 `GS` 段基址
- 多核调度
  - 每核运行独立的 `schedule()`，从自己的 `run_queue` 取任务
  - `task_create` 时由 `sched_enqueue` 决定新任务放到哪个核（round-robin 或指定亲和性）
  - `task_set_cpu_affinity` 可以把任务迁移到指定核 —— 但代价较高
- PSCI (Power State Coordination Interface)
  - ARM 标准：BSP 通过 `PSCI CPU_ON` SMC 调用唤醒 AP
  - 参数：目标核 ID + AP 入口地址 + context_id
  - RISC-V 用 SBI `hart_start()`，x86 用 LAPIC SIPI (Startup IPI)

### 课堂讨论

- 如果两个核同时调用 `pmm_alloc_page()`，不加锁会发生什么？（提示：两核分到同一个物理页）
- `TPIDR_EL1` 在上下文切换时需要保存/恢复吗？（提示：per-CPU 指针是否随任务变化？）
- 4 核系统，只有 1 个 CPU 密集型任务，其余 3 核都在 idle。有没有办法让 3 核都帮忙？

### 课后练习

- 测试：`make ARCH=aarch64 SMP=4 run`，观察 4 核启动日志和 per-CPU tick 计数
- 扩展：阅读 `cpu_smp_timer_test`，理解多核健康检查如何验证每核定时器都在工作
- 挑战：创建 8 个内核任务，绑定不同核（`task_set_cpu_affinity`），验证并行执行

### 参考资料

- ARM PSCI Specification: https://developer.arm.com/documentation/den0022
- RISC-V SBI Specification — Hart State Management Extension
- Intel MultiProcessor Specification — SIPI
- Avatar OS 源码：`kernel/task/cpu.c`, `kernel/task/cpu.h`, `boot/aarch64/boot.S` (_secondary_start)

---

### 参考源码

以下为 Avatar OS 中相关实现位置，仅供参考；学生可以在 `kernel/` 目录下自行设计实现结构。

    kernel/task/cpu.c
    kernel/task/cpu.h
    kernel/task/smp_thread_test.c
    boot/aarch64/boot.S (_secondary_start)

### 预期输出

    CPU 1、CPU 2、CPU 3 online
