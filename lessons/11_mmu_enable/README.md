## Lesson 11 MMU Enable 启用内存管理单元

### 代码

    /* kernel/mm/aarch64/mmu.S — 启用 MMU */
    .globl mmu_init
    mmu_init:
        /* x0 = TTBR0 (用户/恒等映射), x1 = TTBR1 (内核映射) */
        msr ttbr0_el1, x0           // 设置用户页表基址
        msr ttbr1_el1, x1           // 设置内核页表基址

        /* 设置 TCR_EL1 (Translation Control Register) */
        ldr x2, =TCR_VALUE          // T0SZ=16, T1SZ=16, TG0=4KB, TG1=4KB
        msr tcr_el1, x2

        /* 设置 MAIR (Memory Attribute Indirection Register) */
        ldr x2, =MAIR_VALUE         // idx0=Device, idx1=Normal-WB
        msr mair_el1, x2

        /* 启用 MMU */
        mrs x2, sctlr_el1
        orr x2, x2, #1             // SCTLR_EL1.M = 1 (启用 MMU)
        orr x2, x2, #(1 << 2)     // SCTLR_EL1.C = 1 (启用 D-cache)
        orr x2, x2, #(1 << 12)    // SCTLR_EL1.I = 1 (启用 I-cache)
        msr sctlr_el1, x2
        isb                         // ← 关键：冲刷流水线，新翻译立即生效
        ret

    /* boot.S — 从低物理地址跳到高虚拟地址 (trampoline) */
        bl      mmu_init            // MMU 开启，但 PC 仍在低地址
        ldr     x0, =1f            // 加载 label 1 的链接地址 (高 VA)
        br      x0                  // 跳到高虚拟地址！
    1:
        /* 此后所有代码在 0xFFFF_xxxx 高虚拟地址下运行 */

### 知识点

- MMU 启用是内核启动中最惊险的一步
  - 开启 MMU 的那一条指令（`msr sctlr_el1, x2`）之前，PC 是物理地址；之后，PC 必须是虚拟地址
  - 如果页表没有覆盖当前 PC 所在的物理地址 → CPU 取下一条指令时 Translation Fault → 死机
  - Avatar OS 的解决方案：TTBR0 建立恒等映射（VA=PA），让低地址代码在 MMU 开启后仍可执行
- Trampoline 跳板
  - `ldr x0, =1f` 从字面量池加载 label 的**链接地址**（由链接脚本决定，是高 VA）
  - `br x0` 跳过去，之后 PC = `0xFFFF_0000_4008_xxxx`，进入 TTBR1 映射的内核空间
  - 跳板之后，TTBR0 的恒等映射理论上可以拆掉（但 Avatar OS 保留用于用户空间）
- TCR 与地址空间划分
  - `T0SZ=16`：TTBR0 管理的虚拟地址范围 = `0x0000_0000_0000_0000` ~ `0x0000_FFFF_FFFF_FFFF`（用户空间）
  - `T1SZ=16`：TTBR1 管理的虚拟地址范围 = `0xFFFF_0000_0000_0000` ~ `0xFFFF_FFFF_FFFF_FFFF`（内核空间）
  - 中间的 `0x0001_xxxx` ~ `0xFFFE_xxxx` 是无效地址 → 越界访问自动 fault
- MAIR 与内存属性
  - MAIR 寄存器定义最多 8 种内存属性（通过索引选择）
  - 索引 0：Device-nGnRnE（不缓存、不重排、不合并）—— 用于 MMIO
  - 索引 1：Normal Write-Back（正常缓存）—— 用于 DRAM

### 课堂讨论

- 如果 `msr sctlr_el1, x2` 之后不加 `isb`，CPU 的下一条指令是用旧翻译还是新翻译？
- RISC-V 用 `sfence.vma` 刷 TLB，和 AArch64 的 `tlbi` 有什么区别？
- x86_64 启用分页是写 CR0.PG=1。为什么 x86 不需要显式的 trampoline？（提示：x86 长模式必须先有 identity mapping）

### 课后练习

- 测试：在 `mmu_init` 返回后、trampoline 之前，输出 'M' 到 UART（证明恒等映射有效）
- 扩展：阅读 `kernel/mm/riscv64/mmu.S`，对比 RISC-V 的 MMU 启用流程
- 挑战：故意把 TTBR0 设为 0（不建恒等映射），观察 MMU 启用后的异常

### 参考资料

- ARM Architecture Reference Manual — D13: The AArch64 System Level MMU
- RISC-V Privileged ISA — satp register and SFENCE.VMA
- Avatar OS 源码：`kernel/mm/aarch64/mmu.S`, `boot/aarch64/boot.S` (trampoline)

---

### 本课文件

    kernel/mm/aarch64/mmu.S
    kernel/mm/riscv64/mmu.S
    kernel/mm/x86_64/mmu.S
    include/aarch64/mair.h
    include/aarch64/tcr.h

### 在本仓验证

    make ARCH=aarch64 LOG=debug
    make ARCH=aarch64 run
    # 观察 "MMU enabled" 日志，之后所有地址都是高 VA
