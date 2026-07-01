## Lesson 108 Kernel Address Space 内核地址空间布局

### 代码

    /* 典型的 AArch64 内核地址空间布局 (Avatar OS) */

    /*
     * 0xFFFF_FFFF_FFFF_FFFF  ┌─────────────────────┐
     *                        │   (保留)              │
     * 0xFFFF_0000_C000_0000  ├─────────────────────┤
     *                        │   内核堆 (kmalloc)    │ ← pmm_alloc + 线性映射
     * 0xFFFF_0000_8000_0000  ├─────────────────────┤
     *                        │   RAM 线性映射        │ ← PA + KERNEL_VA_OFFSET
     *                        │   (1GB, 含内核代码)   │
     * 0xFFFF_0000_4008_0000  ├─────────────────────┤
     *                        │   _start (内核入口)   │
     * 0xFFFF_0000_4000_0000  ├─────────────────────┤
     *                        │   设备 MMIO 映射      │ ← Device memory
     * 0xFFFF_0000_0000_0000  ├─────────────────────┤
     *                        │   (高半区起始)         │
     *                        │                       │
     *  ─────── 内核/用户分界线 ───────────────────────
     *                        │                       │
     * 0x0000_FFFF_FFFF_FFFF  ├─────────────────────┤
     *                        │   用户空间 (TTBR0)    │
     * 0x0000_0000_0040_0000  ├─────────────────────┤
     *                        │   用户代码加载地址     │
     * 0x0000_0000_0000_0000  └─────────────────────┘
     */

    /* 地址转换宏 */
    #define KERNEL_VA_OFFSET    0xFFFF000000000000ULL
    #define PHYS_TO_VIRT(pa)    ((void *)((uint64_t)(pa) + KERNEL_VA_OFFSET))
    #define VIRT_TO_PHYS(va)    ((paddr_t)((uint64_t)(va) - KERNEL_VA_OFFSET))

### 知识点

- 内核与用户的地址空间分割
  - AArch64 用 TTBR0/TTBR1 天然分割：高半区（`0xFFFF_xxxx`）= 内核，低半区（`0x0000_xxxx`）= 用户
  - x86_64 共用 CR3，通过页表权限位区分：`U/S` 位 = 0 的页只有 Ring 0 能访问
  - 每个用户进程有自己的 TTBR0，但所有进程共享同一个 TTBR1（内核空间）
- 线性映射 (Direct Map)
  - 内核直接映射所有物理 RAM 到连续的虚拟地址范围：`VA = PA + KERNEL_VA_OFFSET`
  - 好处：任何物理地址都可以通过简单加法得到内核虚拟地址，O(1) 转换
  - Linux 称之为 `PAGE_OFFSET` / `__va()` / `__pa()`，Avatar OS 用 `PHYS_TO_VIRT` / `VIRT_TO_PHYS`
- 设备内存映射
  - QEMU virt 的设备（UART 0x0900_0000、GIC 0x0800_0000）也需要映射到高半区
  - 这些区域在页表中标记为 Device 属性（不缓存）—— Lesson 106 的 MAIR idx0
  - boot.S 在 MMU 开启后用 `vm_init` 建立这些映射
- `vm_early.c` —— Avatar OS 的早期页表
  - 使用静态分配的页表（因为此时 PMM 还未初始化，无法动态分配内存）
  - 建立 1GB 块映射（L1 block entry）：0x00000000~0x3FFFFFFF → 设备，0x40000000~0x7FFFFFFF → RAM
  - 简单粗暴但有效 —— 后续可用 L2/L3 细化权限

### 课堂讨论

- 为什么不把内核放在 `0x0000_0000_xxxx`（低地址）？历史上有没有这样做的 OS？
- 如果 RAM 有 4GB，线性映射需要多少页表页？如果用 1GB Block 映射呢？
- Meltdown 漏洞的缓解措施（KPTI）要求用户态无法看到内核页表。Avatar OS 目前有 KPTI 吗？

### 课后练习

- 测试：在 `kernel_main` 中打印 `kernel_main` 函数的虚拟地址和对应的物理地址（用 `VIRT_TO_PHYS`）
- 扩展：画出 RISC-V Sv48 的内核地址空间布局，对比 AArch64
- 挑战：阅读 `include/aarch64/mm_vm.h`，理解 `vm_get_boot_pgtable()` 和 `vm_get_kernel_pgtable()` 返回什么

### 参考资料

- Linux kernel — Documentation/arm64/memory.rst
- RISC-V Privileged ISA — Sv48 virtual address layout
- Avatar OS 源码：`include/mm_vm.h`, `kernel/mm/aarch64/vm_early.c`

---

### 参考源码

以下为 Avatar OS 中相关实现位置，仅供参考；学生可以在 `kernel/` 目录下自行设计实现结构。

    include/mm_vm.h
    include/aarch64/mm_vm.h
    kernel/mm/aarch64/vm_early.c

### 预期输出

    0xFFFF 开头的地址，并包含 kernel_main、VA、PA、virt 或 phys
