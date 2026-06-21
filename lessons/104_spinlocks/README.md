## Lesson 104 Spinlocks 自旋锁

### 代码

    /* AArch64 spin_lock 实现 (include/aarch64/spin_lock_impl.h) */
    static inline void spin_lock(spinlock_t *lock) {
        uint64_t tmp;
        asm volatile(
            "1: ldaxr   %0, [%1]    \n"   // Load-Acquire Exclusive: 读锁值
            "   cbnz    %0, 1b      \n"   // 非零(已锁) → 重试
            "   stxr    %w0, %2, [%1]\n"  // Store Exclusive: 尝试写 1
            "   cbnz    %w0, 1b     \n"   // store 失败 → 重试
            : "=&r"(tmp)
            : "r"(&lock->lock), "r"(1ULL)
            : "memory"
        );
    }

    static inline void spin_unlock(spinlock_t *lock) {
        asm volatile(
            "stlr xzr, [%0]"              // Store-Release: 写 0 = 解锁
            :: "r"(&lock->lock) : "memory"
        );
    }

    /* 带中断保护的变体 */
    spinlock_noirq_t lock = SPINLOCK_NOIRQ_INIT;
    spin_lock_irqsave(&lock);       // 关中断 + 加锁
    // 临界区
    spin_unlock_irqrestore(&lock);  // 解锁 + 恢复中断

### 知识点

- 自旋锁 = 最简单的多核同步原语
  - 核心思想：原子地检查并设置一个标志位。拿到锁的继续执行，没拿到的在原地循环等待（"自旋"）
  - 与 mutex 的区别：自旋锁不睡眠，适合临界区很短的场景（几十条指令以内）
  - 在内核中，自旋锁是保护共享数据结构的基础 —— 调度器、内存分配器、设备驱动都用它
- 原子指令：LL/SC vs CAS
  - AArch64 用 `ldaxr/stxr`（Load-Linked/Store-Conditional）：读取时独占标记，写入时检查独占是否被破坏
  - RISC-V 用 `lr/sc`（同样的 LL/SC 模型）或 `amoswap`（原子交换）
  - x86 用 `lock xchg`（硬件总线锁 / CAS）
  - 三种机制语义相同：确保"检查-修改"是不可分割的
- 为什么需要关中断 (`spin_lock_irqsave`)
  - 场景：核 A 拿了锁 → 中断到来 → 中断处理函数试图拿同一把锁 → 死锁（同一核自旋等自己）
  - `spin_lock_irqsave` 先关中断再加锁，杜绝了这种自死锁
  - Avatar OS 的 `spinlock_noirq_t` 额外保存 `irq_flags`，解锁时恢复到加锁前的中断状态
- Acquire/Release 语义内嵌
  - `ldaxr` 中的 `a` = acquire：锁拿到后，临界区内的读写不会被重排到锁之前
  - `stlr` 中的 `l` = release：解锁前，临界区内的读写不会被重排到锁之后
  - 这就是 Lesson 103 屏障的直接应用 —— 不需要额外加 `dmb`

### 课堂讨论

- 自旋锁的 "自旋" 在单核系统上有意义吗？（提示：单核 + 中断关闭 → 没人会释放锁）
- `stxr` 返回 1（store 失败）的原因是什么？是否只有另一个核写了同一地址才会失败？
- Avatar OS 的任务调度器（Lesson 115）内部用的是哪种自旋锁？为什么？

### 课后练习

- 测试：在两个内核任务中对同一个全局计数器 `++count` 10000 次，不加锁 → 结果不对；加锁 → 结果正确
- 扩展：阅读 `include/riscv64/spin_lock_impl.h`，对比 AArch64 版本的指令差异
- 挑战：把 `spin_lock` 中的 `ldaxr` 换成普通 `ldr`（去掉 acquire），观察在多核场景下是否还能正确工作

### 参考资料

- ARM Architecture Reference Manual — Exclusive access instructions
- RISC-V ISA Manual — Atomic Memory Operations (AMO)
- Avatar OS 文档：`docs/SPINLOCK.md`
- Avatar OS 源码：`include/spinlock.h`, `include/aarch64/spin_lock_impl.h`

---

### 本课文件

    include/spinlock.h
    include/aarch64/spin_lock_impl.h
    include/riscv64/spin_lock_impl.h
    include/x86_64/spin_lock_impl.h
    docs/SPINLOCK.md

### 在本仓验证

    make ARCH=aarch64 LOG=debug
    # 运行多核测试：make ARCH=aarch64 SMP=4 run
    # 观察 spinlock_test 的输出
