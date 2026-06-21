## Lesson 105 Physical Memory Manager 物理内存管理器

### 代码

    /* include/pmm.h — 物理页分配 API */
    void  pmm_initialize(void);              // 扫描平台配置，建立空闲页链表
    void *pmm_alloc_page(void);              // 分配一个 4KB 物理页，返回虚拟地址
    void  pmm_free_page(void *page);         // 释放一个物理页
    void *pmm_alloc_pages(uint32_t count);   // 分配连续 count 个物理页

    /* kernel/mm/pmm.c — 位图分配器核心 */
    static uint8_t page_bitmap[MAX_PAGES / 8];  // 每 bit 对应一个 4KB 页

    void *pmm_alloc_page(void) {
        spin_lock_irqsave(&pmm_lock);
        for (int i = 0; i < total_pages; i++) {
            if (!bitmap_test(page_bitmap, i)) {     // 找到空闲位
                bitmap_set(page_bitmap, i, 1);      // 标记为已分配
                spin_unlock_irqrestore(&pmm_lock);
                paddr_t pa = ram_start + i * PAGE_SIZE;
                return (void *)PHYS_TO_VIRT(pa);    // 返回内核虚拟地址
            }
        }
        spin_unlock_irqrestore(&pmm_lock);
        return NULL;    // 内存耗尽
    }

### 知识点

- 物理内存管理 = 管理真实的 DRAM 页
  - RAM 被划分为固定大小的**页**（通常 4KB），PMM 负责追踪每页是空闲还是已使用
  - 所有高层内存操作（页表、任务栈、用户进程内存）最终都要通过 PMM 获取物理页
  - 类似于仓库管理员：不关心货物是什么，只管登记进出
- 位图分配器
  - 最简单的策略：一个 bit 数组，第 i 位 = 1 表示第 i 页已分配
  - 优点：实现简单，只需 `MAX_PAGES/8` 字节额外内存
  - 缺点：分配是 O(n) 线性扫描；不擅长分配大块连续内存
  - Linux 用 **伙伴系统 (Buddy System)** 解决这两个问题 —— 但位图足够教学使用
- `PHYS_TO_VIRT` / `VIRT_TO_PHYS`
  - MMU 开启后，CPU 只能用虚拟地址访问内存
  - Avatar OS 的内核空间是 **线性映射**：`VA = PA + KERNEL_VA_OFFSET`
  - 所以转换只是加减一个常数 —— 但这个宏必须用对，否则就是 Lesson 98 提到的 PA/VA 混淆 bug
- 多核安全
  - `pmm_alloc_page` 和 `pmm_free_page` 用 `spin_lock_irqsave` 保护 —— Lesson 104 的直接应用
  - 中断中也可能分配内存（如网络包到达），所以必须关中断版本

### 课堂讨论

- 位图分配器分配 N 个连续页的时间复杂度是多少？伙伴系统呢？
- 如果 RAM 有 1GB（262144 页），位图需要多大？这个开销可以接受吗？
- `pmm_free_page` 如果被调用两次（double free），会发生什么？如何检测？

### 课后练习

- 测试：在 `kernel_main` 中分配 10 页并打印物理地址，验证地址是连续的且 4KB 对齐
- 扩展：阅读 `lib/bitmap.c`，理解 `bitmap_set` 和 `bitmap_test` 的位操作实现
- 里程碑自查：此时你有了 UART 输出 (L01) + 日志 (L03) + 栈 (L05) + 锁 (L08) + 物理内存 (L09)。这是一个最小可用内核基础设施

### 参考资料

- OSDev Wiki — Page Frame Allocation: https://wiki.osdev.org/Page_Frame_Allocation
- Linux kernel — Buddy allocator: mm/page_alloc.c
- Avatar OS 源码：`include/pmm.h`, `kernel/mm/pmm.c`, `lib/bitmap.c`

---

### 本课文件

    include/pmm.h
    kernel/mm/pmm.c
    include/bitmap.h
    lib/bitmap.c

### 在本仓验证

    make ARCH=aarch64 LOG=debug
    make ARCH=aarch64 run
    # 观察 "PMM: initialized" 日志和页分配测试输出
