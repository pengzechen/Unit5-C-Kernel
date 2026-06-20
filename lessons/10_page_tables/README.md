## Lesson 10 Page Tables 页表结构

### 代码

    /* AArch64 4 级页表 (4KB 粒度) */

    /*
     * 虚拟地址结构 (48-bit):
     *   [63:48] 符号扩展 (0xFFFF = 内核, 0x0000 = 用户)
     *   [47:39] L0 索引 (9 bit, 512 entries)
     *   [38:30] L1 索引 (9 bit, 512 entries)
     *   [29:21] L2 索引 (9 bit, 512 entries)
     *   [20:12] L3 索引 (9 bit, 512 entries)
     *   [11:0]  页内偏移 (12 bit, 4KB)
     */

    /* 页表项 (PTE) 格式 */
    #define PTE_VALID       (1ULL << 0)    // 有效位
    #define PTE_TABLE       (1ULL << 1)    // 表描述符 (指向下级页表)
    #define PTE_PAGE        (1ULL << 1)    // 页描述符 (L3 级)
    #define PTE_AF          (1ULL << 10)   // Access Flag
    #define PTE_AP_RW       (0ULL << 6)    // EL1 读写
    #define PTE_AP_RO       (1ULL << 7)    // EL1 只读
    #define PTE_UXN         (1ULL << 54)   // 用户不可执行
    #define PTE_PXN         (1ULL << 53)   // 特权不可执行

    /* 建立一个 L3 页表项 */
    pte = phys_addr | PTE_VALID | PTE_PAGE | PTE_AF | PTE_AP_RW;

### 知识点

- 页表 = 虚拟地址 → 物理地址的查找表
  - MMU 硬件自动查表（hardware page walk）：CPU 发出虚拟地址 → MMU 逐级查页表 → 得到物理地址
  - 每个进程有自己的页表 → 每个进程有独立的地址空间 → 进程间内存隔离
  - 页表本身也存在物理内存中（用 Lesson 09 的 PMM 分配）
- 多级页表的设计哲学
  - 如果只用一级页表：48 位虚拟地址空间 / 4KB 页 = 2^36 个表项 = 512GB 页表 —— 不可能
  - 四级页表：只有实际使用的虚拟地址区域才分配页表页，稀疏空间几乎不占内存
  - 每级 512 项 × 8 字节/项 = 4KB = 恰好一个物理页 —— 这不是巧合
- 三种架构的页表对比
  - AArch64：L0→L1→L2→L3，页表基址在 `TTBR0_EL1`（用户）/ `TTBR1_EL1`（内核）
  - RISC-V (Sv48)：同样 4 级，页表基址在 `satp` 寄存器
  - x86_64：PML4→PDPT→PD→PT，页表基址在 `CR3` 寄存器
  - 结构几乎相同 —— 只是寄存器名和 PTE 位域布局不同
- 内存属性
  - 普通内存 vs 设备内存（Device-nGnRnE）：MMIO 区域必须标记为设备内存，禁止缓存和重排
  - 可执行 vs 不可执行（XN/NX）：数据页标记为不可执行，防止代码注入攻击
  - AArch64 用 MAIR 寄存器定义属性索引 —— 见 `include/aarch64/mair.h`

### 课堂讨论

- 4 级页表的一次 page walk 需要多少次内存访问？TLB 起什么作用？
- 如果某个虚拟地址的 L1 表项用的是 1GB Block（而不是指向 L2 表），有什么好处和限制？
- Avatar OS 的内核空间用 `0xFFFF_xxxx` 高半区。这和 x86_64 的 canonical address 有什么关系？

### 课后练习

- 测试：给定虚拟地址 `0xFFFF_0000_4008_1234`，手算 L0/L1/L2/L3 索引和页内偏移
- 扩展：阅读 `include/aarch64/mmu.h`，列出所有 PTE 标志位的含义
- 挑战：阅读 `kernel/mm/aarch64/vm_early.c`，理解 Avatar OS 如何在启动时建立初始页表

### 参考资料

- ARM Architecture Reference Manual — D5: The AArch64 Virtual Memory System Architecture
- RISC-V Privileged ISA — Section 4.5: Sv48 Page-Based Virtual Memory
- Intel SDM Volume 3 — Chapter 4: Paging
- Avatar OS 源码：`include/aarch64/mmu.h`, `kernel/mm/aarch64/vm_early.c`

---

### 本课文件

    include/aarch64/mmu.h
    include/aarch64/mair.h
    include/aarch64/tcr.h
    kernel/mm/aarch64/vm_early.c

### 在本仓验证

    make ARCH=aarch64 LOG=debug
    # 在启动日志中观察页表建立的输出
