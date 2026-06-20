## Lesson 07 Memory Barriers 内存屏障

### 代码

    /* 三条核心屏障指令 */

    /* AArch64 */
    dsb sy      // Data Synchronization Barrier — 所有内存操作完成
    dmb sy      // Data Memory Barrier — 所有内存操作排序
    isb         // Instruction Synchronization Barrier — 流水线冲刷

    /* RISC-V */
    fence rw, rw    // 等价于 dsb sy — 全屏障
    fence r, r      // 读屏障
    fence w, w      // 写屏障
    fence.i         // 指令屏障（刷 I-cache）

    /* x86_64 */
    mfence          // 全屏障（x86 TSO 模型下很少需要）
    lfence          // 读屏障
    sfence          // 写屏障

    /* Avatar OS 的统一封装 */
    barrier_data();         // → dsb sy / fence rw,rw / mfence
    barrier_data_read();    // → dmb ld / fence r,r   / lfence
    barrier_data_write();   // → dmb st / fence w,w   / sfence
    barrier_acquire();      // 获取语义：之后的操作不能重排到此之前
    barrier_release();      // 释放语义：之前的操作不能重排到此之后

### 知识点

- 为什么需要内存屏障
  - 现代 CPU 有乱序执行、写缓冲、缓存层次 —— 程序员写的代码顺序 ≠ 实际执行顺序
  - 单核无感知（CPU 保证单线程语义不变），多核时可观察到：核 A 写了 flag=1 再写 data=42，核 B 可能先看到 flag=1、再看到 data=旧值
  - 屏障强制 CPU 按指定顺序完成内存操作 —— 代价是性能损失，所以不能滥用
- 三种屏障的区别
  - **编译器屏障** `barrier_compiler()`：只阻止编译器重排，不生成 CPU 指令，零开销
  - **数据屏障** `barrier_data()`：CPU 级别的排序点，前面的 load/store 必须在后面的之前完成
  - **指令屏障** `barrier_instr_full()`：冲刷流水线 —— 修改系统寄存器（页表、中断向量）后必须加
- x86 TSO 模型 vs ARM/RISC-V 弱序模型
  - x86 是 Total Store Order：store 之间自动有序，所以 `mfence` 很少需要
  - ARM/RISC-V 是弱序：几乎任何重排都可能发生，必须显式加屏障
  - 这就是为什么从 x86 移植到 ARM 常出 bug —— x86 上偶然正确的代码在 ARM 上翻车
- Avatar OS 的使用场景
  - MMIO 写 + 屏障：`mmio_write32()` 内部加 `barrier_release()` 确保设备看到正确顺序
  - Spinlock：`spin_lock()` 用 acquire，`spin_unlock()` 用 release —— Lesson 08 详解
  - MMU 启用：`msr sctlr_el1, x0; isb` —— 不加 isb，后续指令可能用旧的翻译结果

### 课堂讨论

- 在单核系统上还需要 `barrier_data()` 吗？什么时候需要？（提示：DMA 设备也能读写内存）
- `asm volatile("" ::: "memory")` 是最轻量的屏障。你能想到哪些场景只需要编译器屏障？
- 为什么 `isb` 在设置 `VBAR_EL1`（中断向量基址）后是必须的？

### 课后练习

- 测试：阅读 `include/aarch64/barrier_impl.h`，列出每个函数对应的汇编指令
- 扩展：在 `include/mmio.h` 中找到 `mmio_write32`，标注哪里用了哪种屏障
- 挑战：写一个双核场景（纸上推演）：核 A 写 `data=42; flag=1;`，核 B 轮询 `while(!flag);`。不加屏障时核 B 可能读到什么？

### 参考资料

- ARM Architecture Reference Manual — Barrier instructions (DSB, DMB, ISB)
- RISC-V ISA Manual — FENCE instruction
- Avatar OS 文档：`docs/BARRIER.md`
- A Primer on Memory Consistency and Cache Coherence (Sorin, Hill, Wood)

---

### 本课文件

    include/barrier.h
    include/aarch64/barrier_impl.h
    include/riscv64/barrier_impl.h
    include/x86_64/barrier_impl.h
    docs/BARRIER.md

### 在本仓验证

    # 查看屏障在汇编中的展开
    make ARCH=aarch64
    aarch64-linux-musl-objdump -d build/kernel.elf | grep -A2 "dsb"
