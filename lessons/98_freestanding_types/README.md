## Lesson 98 Freestanding Types 独立类型系统

### 代码

    /* include/types.h 核心片段 */
    typedef unsigned char        uint8_t;
    typedef unsigned short       uint16_t;
    typedef unsigned int         uint32_t;
    typedef unsigned long long   uint64_t;

    typedef unsigned long size_t;
    typedef unsigned long uintptr_t;

    typedef uint64_t vaddr_t;   /* 虚拟地址 */
    typedef uint64_t paddr_t;   /* 物理地址 */

    #define NULL ((void *)0)

    /* 类型安全的 MIN 宏 */
    #define MIN(a, b) __extension__ ({  \
        __typeof__(a) _a = (a);         \
        __typeof__(b) _b = (b);         \
        _a < _b ? _a : _b;             \
    })

    /* 对齐宏 */
    #define ALIGN_UP(x, a)   (((x) + ((a) - 1)) & ~((a) - 1))
    #define IS_ALIGNED(x, a) (((x) & ((a) - 1)) == 0)

### 知识点

- 为什么不用 `<stdint.h>`
  - Freestanding 环境没有标准库，只有编译器提供的少数头文件（`<stdarg.h>`, `<stddef.h>` 等）
  - `<stdint.h>` 虽然部分编译器支持 freestanding 版，但 Avatar OS 选择自行定义以消除依赖
  - 关键前提：三个目标架构都是 64 位 LP64 数据模型 —— `long` = 8 字节，`int` = 4 字节
- 地址类型的重要性
  - `vaddr_t` / `paddr_t` 类型上都是 `uint64_t`，但语义不同 —— 一个是 CPU 看到的地址，一个是总线上的地址
  - MMU 开启前两者相同；开启后完全不同。将 `paddr_t` 直接当指针解引用是最常见的内核 bug 之一
- 宏的陷阱与防御
  - 天真的 `#define MIN(a,b) ((a)<(b)?(a):(b))` 会让参数求值两次 —— 如果 `a` 是 `i++` 就会增加两次
  - `__typeof__` + GCC statement expression `({...})` 解决了这个问题，代价是不再是标准 C
  - `ALIGN_UP` 利用位运算：`(x + a-1) & ~(a-1)` 将 x 对齐到 a 的倍数，前提是 a 必须是 2 的幂
- `container_of` —— 内核数据结构的基石
  - 通过结构体成员的指针，反推出整个结构体的指针
  - Avatar OS 的链表、任务队列全部依赖这个宏 —— 见 Lesson 99 的 list.h

### 课堂讨论

- `long` 在 ILP32 数据模型下是 4 字节，如果 Avatar OS 要支持 32 位 RISC-V，`size_t` 的定义要怎么改？
- `ALIGN_UP(0, 4096)` 返回多少？`ALIGN_UP(1, 4096)` 呢？手算一遍位运算过程
- 为什么 `offsetof` 使用 `__builtin_offsetof` 而不是经典的 `((size_t)&((type*)0)->member)`？

### 课后练习

- 测试：写一个裸机程序验证 `sizeof(uint64_t)==8`，`sizeof(uintptr_t)==sizeof(void*)`，失败时输出 'F' 到 UART
- 扩展：实现 `CLAMP(x, lo, hi)` 宏，确保类型安全且参数只求值一次
- 挑战：阅读 `include/types.h` 中 `container_of` 的实现，画出指针算术示意图

### 参考资料

- C11 N1570 §7.20 Integer types `<stdint.h>`
- GCC Extensions: Statement Expressions https://gcc.gnu.org/onlinedocs/gcc/Statement-Exprs.html
- Avatar OS 源码：`include/types.h`

---

### 参考源码

以下为 Avatar OS 中相关实现位置，仅供参考；学生可以在 `kernel/` 目录下自行设计实现结构。

    include/types.h

### 预期输出

    串口输出中不应包含失败标记 F
