## Lesson 118 System Calls 系统调用

### 代码

    /* 用户态发起系统调用 (AArch64) */
    mov x8, #64             // syscall number: write
    mov x0, #1              // arg0: fd = stdout
    ldr x1, =buf            // arg1: buffer address
    mov x2, #5              // arg2: length
    svc #0                  // 陷入内核 → ESR_EL1.EC = 0x15

    /* 内核态 syscall 分发 (kernel/syscall/syscall.c) */
    int64_t syscall_dispatch(uint64_t nr, uint64_t a0, uint64_t a1,
                             uint64_t a2, uint64_t a3, uint64_t a4,
                             uint64_t a5) {
        switch (nr) {
            case SYS_READ:    return sys_read(a0, a1, a2);
            case SYS_WRITE:   return sys_write(a0, a1, a2);
            case SYS_OPENAT:  return sys_openat(a0, a1, a2, a3);
            case SYS_CLOSE:   return sys_close(a0);
            case SYS_BRK:     return sys_brk(a0);
            case SYS_MMAP:    return sys_mmap(a0, a1, a2, a3, a4, a5);
            case SYS_EXIT:    sys_exit(a0); /* no return */
            case SYS_CLONE:   return sys_clone(a0, a1, a2, a3, a4);
            case SYS_EXECVE:  return sys_execve(a0, a1, a2);
            case SYS_WAIT4:   return sys_wait4(a0, a1, a2, a3);
            ...
            default:
                KLOG_WARN("Unknown syscall: %llu\n", nr);
                return -ENOSYS;
        }
    }

### 知识点

- 系统调用 = 用户程序请求内核服务的唯一合法通道
  - 用户态不能直接访问硬件、修改页表、创建进程 —— 必须通过系统调用请求内核代劳
  - AArch64: `svc #0` → Synchronous Exception (EC=0x15)
  - RISC-V: `ecall` → Environment Call from U-mode (scause=8)
  - x86_64: `syscall` 指令 → 通过 MSR 寄存器跳到内核入口
- 系统调用约定 (ABI)
  - **调用号**：AArch64 用 `x8`，RISC-V 用 `a7`，x86_64 用 `rax`
  - **参数**：AArch64 用 `x0-x5`，RISC-V 用 `a0-a5`，x86_64 用 `rdi,rsi,rdx,r10,r8,r9`
  - **返回值**：都用第一个通用寄存器（`x0`/`a0`/`rax`），负值表示错误
  - Avatar OS 遵循 Linux ABI —— 这样可以运行为 Linux 编译的用户程序（如 busybox）
- Avatar OS 已实现的系统调用
  - **进程管理**：`clone`, `execve`, `exit`, `wait4`, `getpid`, `getppid`
  - **文件 I/O**：`read`, `write`, `openat`, `close`, `lseek`, `fstat`
  - **内存管理**：`brk`, `mmap`, `munmap`
  - **信号**：`rt_sigaction`, `rt_sigprocmask`, `rt_sigreturn`
  - **同步**：`futex`
  - 足以运行 busybox shell 和基本命令
- 系统调用的性能
  - 每次 `svc` → 异常入口 → 保存全部寄存器 → C 分发 → 恢复寄存器 → `eret`
  - 开销约 1-5 微秒 —— 对比普通函数调用的 1-10 纳秒
  - 这就是为什么高性能程序（如数据库）会尽量减少 syscall 次数

### 课堂讨论

- `write(1, "hello", 5)` 从用户 `svc` 到字符出现在 UART 上，经过了多少层函数调用？
- 为什么系统调用号不能由用户任意选择？如果传了一个无效号码，内核返回什么？
- x86_64 的 `syscall` 指令和 `svc` 有什么本质区别？（提示：`syscall` 不经过中断向量表）

### 课后练习

- 测试：用汇编写一个用户程序，依次调用 `write`（打印 "OK"）和 `exit`（退出码 42）
- 扩展：在 `syscall_dispatch` 中加日志，统计最常被调用的 5 个系统调用
- 挑战：实现一个新的系统调用 `sys_uptime()`，返回系统启动以来的 tick 数

### 参考资料

- Linux syscall table: https://filippo.io/linux-syscall-table/
- ARM Architecture Reference Manual — SVC instruction
- Avatar OS 源码：`kernel/syscall/syscall.c`, `kernel/syscall/syscall.h`

---

### 参考源码

以下为 Avatar OS 中相关实现位置，仅供参考；学生可以在 `kernel/` 目录下自行设计实现结构。

    kernel/syscall/syscall.c
    kernel/syscall/syscall.h
    kernel/syscall/core/proc_lifecycle.c
    kernel/syscall/fs/file_io.c
    kernel/syscall/mm/brk.c
    kernel/syscall/mm/mmap.c
    include/syscall_abi.h

### 预期输出

    OK
