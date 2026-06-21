## Lesson 119 ELF Loader ELF 加载器

### 代码

    /* kernel/loader/elf_loader.c — 加载 ELF 到用户空间 */

    int elf_loader_load_from_file(const char *path, char *argv[], char *envp[]) {
        /* 1. 读取 ELF 头 */
        Elf64_Ehdr ehdr;
        fs_read(path, &ehdr, sizeof(ehdr), 0);

        /* 验证: 魔数 0x7F 'E' 'L' 'F' */
        if (ehdr.e_ident[0] != 0x7F || ehdr.e_ident[1] != 'E')
            return -ENOEXEC;

        /* 2. 创建新的用户地址空间 */
        uint64_t *pgd = vm_create_user_pgd();

        /* 3. 遍历 Program Header，加载 LOAD 段 */
        for (int i = 0; i < ehdr.e_phnum; i++) {
            Elf64_Phdr phdr;
            fs_read(path, &phdr, sizeof(phdr), ehdr.e_phoff + i * sizeof(phdr));

            if (phdr.p_type != PT_LOAD) continue;

            /* 分配物理页 → 映射到用户虚拟地址 → 拷贝段内容 */
            for (uint64_t off = 0; off < phdr.p_memsz; off += PAGE_SIZE) {
                void *page = pmm_alloc_page();
                vm_map_user_page(pgd, phdr.p_vaddr + off, VIRT_TO_PHYS(page));
            }
            fs_read(path, PHYS_TO_VIRT(va_to_pa(pgd, phdr.p_vaddr)),
                    phdr.p_filesz, phdr.p_offset);
        }

        /* 4. 设置用户栈 (放 argv, envp, auxv) */
        uint64_t user_sp = setup_user_stack(pgd, argv, envp);

        /* 5. 创建用户进程 */
        process_create_with_pgd("user", ehdr.e_entry, user_sp, 5, pgd, ...);
        return 0;
    }

### 知识点

- ELF = Executable and Linkable Format
  - 所有 Linux 可执行文件和共享库的标准格式
  - ELF 头告诉你：架构、入口点地址、Program Header 表的位置
  - Program Header 描述运行时需要加载的段（`PT_LOAD`），包括虚拟地址和文件偏移
  - 交叉编译器（`aarch64-linux-musl-gcc`）生成的 ELF 就是 Avatar OS 能加载的用户程序
- 加载过程 = "把文件内容放到用户看到的正确地址上"
  - ① 解析 ELF 头 → 获取入口点和段表
  - ② 为每个 `PT_LOAD` 段分配物理页 → 映射到段指定的虚拟地址
  - ③ 从文件读取段内容 → 拷贝到映射好的物理页中
  - ④ `.bss` 段（`p_memsz > p_filesz` 的部分）需要清零 —— 和 boot.S 清 BSS 一样的道理
  - ⑤ 设置用户栈（放 `argv`、`envp`、`auxv`）→ 创建进程 → `eret` 到入口点
- 用户栈的初始布局
  - Linux ABI 规定用户栈顶的布局：`[argc][argv[0]][argv[1]]...[NULL][envp[0]]...[NULL][auxv]...`
  - `auxv` (Auxiliary Vector) 包含页大小、入口点、平台信息等 —— musl libc 的 `_start` 会读取
  - Avatar OS 必须正确构造这个栈，否则 busybox 的 `main(argc, argv)` 收到垃圾参数
- `execve` 系统调用
  - 用户进程调用 `execve("/bin/ls", argv, envp)` → 内核把当前进程的地址空间替换为新 ELF
  - 不创建新进程！而是复用当前 `task_t`，替换页表和入口点
  - 这就是 `fork + exec` 模型的 `exec` 部分

### 课堂讨论

- ELF 文件中 `e_entry = 0x400080`。这个地址是虚拟地址还是物理地址？加载器需要什么才能让 CPU 跳到这个地址？
- 为什么 `.text` 段（代码）和 `.data` 段（数据）要分开成两个 `PT_LOAD`？（提示：权限不同）
- 动态链接的 ELF（依赖 `ld.so`）能在 Avatar OS 上运行吗？为什么 busybox 要静态编译？

### 课后练习

- 测试：用 `aarch64-linux-musl-gcc -static -o hello hello.c` 编译一个 C 程序，放入 rootfs 镜像，启动后运行
- 扩展：用 `readelf -l build/apps/hello.elf` 查看 Program Header，标注每个 `PT_LOAD` 段的地址和大小
- 挑战：阅读 `kernel/loader/elf_image.c`，理解 `auxv` 的构造过程

### 参考资料

- ELF Specification: https://refspecs.linuxfoundation.org/elf/elf.pdf
- Linux kernel — fs/binfmt_elf.c
- System V AMD64 ABI — Process Initialization (stack layout)
- Avatar OS 源码：`kernel/loader/elf_loader.c`, `kernel/loader/elf_image.c`, `include/elf.h`

---

### 本课文件

    kernel/loader/elf_loader.c
    kernel/loader/elf_loader.h
    kernel/loader/elf_image.c
    kernel/loader/elf_image.h
    include/elf.h

### 在本仓验证

    make ARCH=aarch64 kernel
    make ARCH=aarch64 rootfs
    make ARCH=aarch64 run-fs
    # busybox shell 启动 = ELF 加载器工作正常
