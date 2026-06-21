# Avatar OS Kernel 学习课程

基于 Avatar OS 真实内核代码的 24 节由浅入深课程。每一课对应内核的一个子系统，代码示例直接取自本仓库。

## 课程结构

### 第一阶段：裸机基础 (Lesson 97-102)

从零开始：一个字符的输出 → 类型系统 → 日志 → 链接脚本 → 引导汇编 → 架构抽象。完成后你拥有一个能跨三个架构编译、在 QEMU 上运行的最小内核骨架。

| 编号 | 标题 | 关键文件 |
|------|------|----------|
| [97](97_bare_metal_hello/) | Bare-Metal Hello 裸机第一声 | boot_hello.S |
| [98](98_freestanding_types/) | Freestanding Types 独立类型系统 | include/types.h |
| [99](99_kernel_logging/) | Kernel Logging 内核日志系统 | include/klog.h, lib/klog.c |
| [100](100_linker_script/) | Linker Script 链接脚本 | boot/\*/link.ld |
| [101](101_boot_assembly/) | Boot Assembly 引导汇编 | boot/\*/boot.S |
| [102](102_arch_abstraction/) | Architecture Abstraction 架构抽象层 | include/arch.h, include/barrier.h |

### 第二阶段：内存与同步 (Lesson 103-108)

内存屏障 → 自旋锁 → 物理内存分配 → 页表结构 → 启用 MMU → 地址空间布局。完成后内核运行在虚拟地址空间中，拥有保护模式下的内存管理能力。

| 编号 | 标题 | 关键文件 |
|------|------|----------|
| [103](103_memory_barriers/) | Memory Barriers 内存屏障 | include/barrier.h, docs/BARRIER.md |
| [104](104_spinlocks/) | Spinlocks 自旋锁 | include/spinlock.h |
| [105](105_physical_memory/) | Physical Memory Manager 物理内存管理器 | kernel/mm/pmm.c |
| [106](106_page_tables/) | Page Tables 页表结构 | include/aarch64/mmu.h |
| [107](107_mmu_enable/) | MMU Enable 启用内存管理单元 | kernel/mm/\*/mmu.S |
| [108](108_kernel_address_space/) | Kernel Address Space 内核地址空间布局 | include/mm_vm.h |

### 第三阶段：中断与定时器 (Lesson 109-112)

异常向量表 → 异常处理 → 定时器驱动 → 中断控制器。完成后内核能响应硬件事件，拥有了"心跳"。

| 编号 | 标题 | 关键文件 |
|------|------|----------|
| [109](109_exception_vectors/) | Exception Vectors 异常向量表 | boot/\*/exception.S |
| [110](110_exception_handling/) | Exception Handling 异常处理 | boot/\*/exception.c |
| [111](111_timer_driver/) | Timer Driver 定时器驱动 | driver/timer/timer.c |
| [112](112_interrupt_controllers/) | Interrupt Controllers 中断控制器 | driver/irq/gicv3.c, plic.c, lapic.c |

### 第四阶段：多任务 (Lesson 113-116)

任务控制块 → 上下文切换 → 轮转调度 → 抢占式调度。完成后内核实现了完整的多任务并发。

| 编号 | 标题 | 关键文件 |
|------|------|----------|
| [113](113_task_control_block/) | Task Control Block 任务控制块 | kernel/task/task.h |
| [114](114_context_switch/) | Context Switch 上下文切换 | kernel/task/\*/switch.S |
| [115](115_round_robin_scheduler/) | Round-Robin Scheduler 轮转调度器 | kernel/task/sched.c |
| [116](116_preemptive_scheduling/) | Preemptive Scheduling 抢占式调度 | kernel/task/preempt.c |

### 第五阶段：用户态与多核 (Lesson 117-120)

用户态切换 → 系统调用 → ELF 加载 → 多核启动。完成后 Avatar OS 可以运行 busybox shell，在多核处理器上并行调度。

| 编号 | 标题 | 关键文件 |
|------|------|----------|
| [117](117_user_mode/) | User Mode 用户态 | kernel/task/task.c |
| [118](118_system_calls/) | System Calls 系统调用 | kernel/syscall/syscall.c |
| [119](119_elf_loader/) | ELF Loader ELF 加载器 | kernel/loader/elf_loader.c |
| [120](120_smp_multicore/) | SMP Multicore 多核启动与调度 | kernel/task/cpu.c |

## 里程碑

- **M1 (Lesson 105)**: 最小内核基础设施 — UART + 日志 + 栈 + 锁 + 物理内存
- **M2 (Lesson 108)**: 虚拟内存完备 — 页表 + MMU + 地址空间隔离
- **M3 (Lesson 116)**: 抢占式多任务 — 定时器驱动的上下文切换
- **M4 (Lesson 120)**: 完整操作系统 — 用户态 + 系统调用 + 多核

## 支持的架构

每一课涉及的概念都在三个架构上实现：

| 架构 | 工具链 | QEMU 命令 |
|------|--------|-----------|
| AArch64 | `aarch64-linux-musl-gcc` | `make ARCH=aarch64 run` |
| RISC-V 64 | `riscv64-linux-musl-gcc` | `make ARCH=riscv64 run` |
| x86_64 | `gcc` | `make ARCH=x86_64 run` |

## 每课格式

每课 README 包含：
- **代码**：直接取自 Avatar OS 的代码片段和汇编输出
- **知识点**：概念解释、跨架构对比、和其他课程的关联
- **课堂讨论**：苏格拉底式问题，探究设计决策背后的"为什么"
- **课后练习**：测试（验证行为）、扩展（添加功能）、挑战（深度探索）
- **参考资料**：架构手册、经典教材、Avatar OS 源码文件
- **在本仓验证**：可复制粘贴的编译和运行命令
