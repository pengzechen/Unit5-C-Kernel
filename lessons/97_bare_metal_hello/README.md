## Lesson 97 Bare-Metal Hello 裸机第一声

### 代码

    /* 目标：让 QEMU 串口打印一个字符 'A' */

    /* AArch64: PL011 UART 地址 0x0900_0000 (QEMU virt) */
    .globl _start
    _start:
        ldr x0, =0x09000000     // UART 数据寄存器地址
        mov w1, #'A'            // 字符 'A' = 0x41
        strb w1, [x0]           // 往数据寄存器写一字节 → 串口输出
    hang:
        wfe                     // 等待事件（低功耗等待）
        b hang                  // 永不退出

    /* RISC-V: 相同逻辑，UART 地址 0x1000_0000 (QEMU virt) */
    .globl _start
    _start:
        li   a0, 0x10000000     // UART 基址
        li   a1, 'A'            // 字符 'A'
        sb   a1, 0(a0)          // store byte 到 UART THR
    hang:
        wfi
        j    hang

### 知识点

- 裸机 = 没有操作系统
  - 无标准库、无 printf、无文件系统 —— CPU 上电后执行的第一条指令就是你写的
  - 唯一的输出通道：硬件寄存器。UART 数据寄存器写入一个字节，串口终端就显示一个字符
  - 这就是 `uart_putchar` 的本质 —— Avatar OS 所有的 kprintf 最终都走这条路
- MMIO (Memory-Mapped I/O)
  - ARM/RISC-V 没有 x86 的 `in/out` 指令，设备寄存器被映射到物理地址空间
  - 写 `0x0900_0000` 和写普通内存语法完全相同（`str`/`sw`），但硬件效果截然不同
  - Avatar OS 的 `mmio_write32()` 就是对这一机制的封装 —— 见 `include/mmio.h`
- 为什么选 QEMU
  - 真实硬件需要 JTAG/串口线，调试周期长
  - QEMU `-machine virt` 提供标准化的虚拟平台，UART 地址固定已知
  - Avatar OS 支持 `qemu-virt-aarch64`、`qemu-virt-riscv64`、`qemu-virt-x86_64` 三个平台

### 课堂讨论

- CPU 上电后的第一条指令在哪个地址？ARM 和 RISC-V 的复位地址分别是什么？
- 如果把 `strb w1, [x0]` 改成 `str w1, [x0]`（4 字节写），串口会输出什么？
- 为什么 hang 循环要用 `wfe/wfi` 而不是空转 `b hang`？（提示：功耗）

### 课后练习

- **必做（评测项）**：编写 `boot_hello.S`，让 QEMU 串口输出包含 "Hello" 的字符串
- 扩展：在 x86_64 上用 `outb` 指令向串口 `0x3F8` 输出字符，对比 MMIO 方式
- 挑战：不用 `.globl _start`，观察链接器报什么错误

### 参考资料

- ARM PL011 Technical Reference Manual — Data Register
- RISC-V QEMU virt platform memory map: https://github.com/qemu/qemu/blob/master/hw/riscv/virt.c
- Avatar OS UART 驱动：`driver/uart/uart_pl011.c` (AArch64), `driver/uart/uart_x86.c` (x86_64)

---

### 提交文件

    lessons/97_bare_metal_hello/boot_hello.S （自行编写）

### 手动验证

所有命令在**仓库根目录**下执行：

    # 编译
    aarch64-linux-musl-gcc -nostdlib -Wl,--build-id=none \
        -T grading/simple.ld \
        lessons/97_bare_metal_hello/boot_hello.S \
        -o /tmp/hello.elf

    # 运行（Ctrl-A X 退出 QEMU）
    qemu-system-aarch64 -machine virt -cpu cortex-a57 -m 128M -nographic -kernel /tmp/hello.elf

    # 预期输出: Hello

### 自动评测

    bash grading/grade.sh -l 97
