## Lesson 112 Interrupt Controllers 中断控制器

### 代码

    /* AArch64: GICv3 (Generic Interrupt Controller v3) */

    /* driver/irq/gicv3.c — 初始化 */
    void gicv3_init(void) {
        /* Distributor: 全局中断路由 */
        mmio_write32(GICD_BASE + GICD_CTLR, GICD_CTLR_ENABLE);

        /* Redistributor: 每核私有 (SGI/PPI) */
        mmio_write32(GICR_BASE + GICR_WAKER, 0);   // 唤醒 redistributor

        /* CPU Interface: 系统寄存器方式 */
        uint64_t sre = read_icc_sre_el1();
        sre |= 1;                                    // SRE=1
        write_icc_sre_el1(sre);
        write_icc_pmr_el1(0xFF);                     // 接受所有优先级
        write_icc_igrpen1_el1(1);                    // 使能 Group1 中断
    }

    /* 中断处理流程 */
    void gicv3_handle_irq(void) {
        uint32_t iar = read_icc_iar1_el1();          // 读中断号 (acknowledge)
        uint32_t irq_id = iar & 0x3FF;

        if (irq_id == 30)       timer_irq_handler(); // PPI #30 = Physical Timer
        else if (irq_id == 33)  uart_irq_handler();  // SPI #33 = UART
        else                    KLOG_WARN("Unknown IRQ: %u\n", irq_id);

        write_icc_eoir1_el1(iar);                    // End of Interrupt
    }

### 知识点

- 中断控制器 = 中断的路由器
  - CPU 只有少量中断引脚。几十个设备要共享，需要中断控制器做仲裁和分发
  - 中断控制器负责：启用/禁用单个中断源、设置优先级、决定中断发往哪个核
  - 三种架构各有自己的中断控制器
- GICv2/GICv3 (ARM)
  - **Distributor (GICD)**：全局共享，管理 SPI（共享外设中断），路由到目标核
  - **Redistributor (GICR)**：每核一个，管理 SGI（软件生成中断）和 PPI（私有外设中断）
  - **CPU Interface**：GICv3 用系统寄存器（`ICC_*`），GICv2 用 MMIO（`GICC_*`）
  - Avatar OS 同时支持 GICv2 和 GICv3 —— 由平台配置决定
- PLIC (RISC-V)
  - Platform-Level Interrupt Controller：功能类似 GIC 的 Distributor
  - 通过 `claim/complete` 机制：读 claim 寄存器获取中断号，写 complete 寄存器确认处理完毕
  - 比 GIC 简单得多，但也不支持优先级抢占
- LAPIC + I/O APIC (x86_64)
  - Local APIC (LAPIC)：每核私有，处理定时器中断和 IPI
  - I/O APIC：管理外部设备中断，路由到指定核的 LAPIC
  - x86 还有传统的 8259 PIC，但现代系统都用 APIC
- 中断处理的 ACK/EOI 模式
  - **ACK (Acknowledge)**：读 IAR 寄存器告诉中断控制器"我开始处理了"
  - **EOI (End of Interrupt)**：写 EOIR 寄存器告诉中断控制器"我处理完了"
  - 不写 EOI → 中断控制器认为你还在处理 → 同一中断源不再触发 → 系统卡死

### 课堂讨论

- GICv3 的 SGI（Software Generated Interrupt）有什么用？（提示：多核间通信 —— Lesson 120）
- 为什么 UART 中断号是 33（SPI #1）而不是从 0 开始？（提示：SPI 编号从 32 开始）
- 如果在 `gicv3_handle_irq` 中漏写了 `write_icc_eoir1_el1(iar)`，系统会表现出什么症状？

### 课后练习

- 测试：在 GIC 初始化后打印当前启用的中断列表
- 扩展：对比 `driver/irq/gicv2.c` 和 `gicv3.c`，列出 CPU Interface 访问方式的差异
- 挑战：阅读 `boot/aarch64/boot.S` 中的 `ICC_SRE_EL2` 设置，理解为什么必须在 EL2 启用 SRE

### 参考资料

- ARM GICv3 Architecture Specification
- RISC-V PLIC Specification: https://github.com/riscv/riscv-plic-spec
- Intel SDM — Chapter 10: Advanced Programmable Interrupt Controller
- Avatar OS 源码：`driver/irq/gicv3.c`, `driver/irq/plic.c`, `driver/irq/lapic.c`

---

### 参考源码

以下为 Avatar OS 中相关实现位置，仅供参考；学生可以在 `kernel/` 目录下自行设计实现结构。

    driver/irq/gicv3.c
    driver/irq/gicv3.h
    driver/irq/gicv2.c
    driver/irq/plic.c
    driver/irq/lapic.c
    driver/irq/irq.h

### 预期输出

    GIC、IRQ、Interrupt 或 irq
