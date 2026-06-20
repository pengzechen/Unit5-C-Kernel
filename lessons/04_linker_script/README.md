## Lesson 04 Linker Script 链接脚本

### 代码

    /* boot/aarch64/link.ld 核心片段 */
    ENTRY(_start)

    SECTIONS
    {
        . = 0xFFFF000040080000;     /* 内核虚拟地址起始 (高半区) */

        .text : {
            *(.text .text.*)        /* 所有 .text 段合并 */
        }

        .rodata : {
            *(.rodata .rodata.*)    /* 只读数据 */
        }

        .data : {
            *(.data .data.*)        /* 可读写数据 */
        }

        . = ALIGN(4096);           /* BSS 起始对齐到页边界 */
        __bss_start = .;
        .bss : {
            *(.bss .bss.*)
            *(COMMON)
        }
        __bss_end = .;

        /* 栈空间（BSS 之后，16KB） */
        . = ALIGN(16);
        stack_bottom = .;
        . += 0x4000;
        stack_top = .;
    }

### 知识点

- 链接脚本 = 内核的内存地图
  - 告诉链接器：哪些段放在哪个地址、顺序是什么、导出哪些符号
  - `.text`（代码）→ `.rodata`（常量）→ `.data`（已初始化全局变量）→ `.bss`（未初始化全局变量）
  - 这个顺序不是随意的：只读段在前，可以在 MMU 开启后设为不可写（安全）
- 虚拟地址 vs 加载地址
  - `0xFFFF000040080000` 是链接地址（VMA），编译器生成的所有 PC 相对偏移都基于它
  - QEMU 把内核加载到物理地址 `0x40080000`，boot.S 用 AT 或 identity map 让 CPU 在 MMU 开启前能执行
  - boot.S 的 trampoline（`ldr x0, =1f; br x0`）从低物理地址跳到高虚拟地址 —— Lesson 11 详解
- `__bss_start` / `__bss_end` —— 由链接器导出的符号
  - boot.S 用这两个符号把 BSS 清零：`extern char __bss_start, __bss_end;`
  - 不清零 BSS 会导致灾难 —— Avatar OS 真实 bug：UART 的 spinlock 初始值是 DRAM 垃圾，死锁
- 栈的定义
  - 栈在链接脚本中分配，`stack_top` 是栈顶（高地址）—— 栈向下生长
  - AArch64 要求 SP 16 字节对齐（否则 alignment fault）

### 课堂讨论

- 如果把 `.bss` 放在 `.text` 之前，会发生什么？生成的 ELF 文件大小会变吗？
- RISC-V 的链接脚本（`boot/riscv64/link.ld`）和 AArch64 有什么区别？虚拟地址起始不同吗？
- 为什么 `stack_top = .;` 而不是 `stack_top = . - 1;`？SP 初始值应指向栈的最后一个字节还是下一个位置？

### 课后练习

- 测试：在链接脚本中添加 `kernel_size = . - 0xFFFF000040080000;`，在 C 代码中用 `extern char kernel_size;` 读取内核大小并打印
- 扩展：比较三个架构的链接脚本，列出 VMA 起始地址差异
- 挑战：故意把 BSS 清零代码注释掉，观察内核启动时哪里最先崩溃

### 参考资料

- GNU ld Linker Scripts: https://sourceware.org/binutils/docs/ld/Scripts.html
- OSDev Wiki — Linker Scripts: https://wiki.osdev.org/Linker_Scripts
- Avatar OS 源码：`boot/aarch64/link.ld`, `boot/riscv64/link.ld`, `boot/x86_64/link.ld`

---

### 本课文件

    boot/aarch64/link.ld
    boot/riscv64/link.ld
    boot/x86_64/link.ld

### 在本仓验证

    make ARCH=aarch64
    aarch64-linux-musl-readelf -S build/kernel.elf | head -30
    # 观察各段的 VMA 地址
