ENTRY(_start)

SECTIONS
{
    . = 0x40080000;

    .text : { *(.text*) }
    .rodata : { *(.rodata*) }
    .data : { *(.data*) }

    . = ALIGN(16);
    __bss_start = .;
    .bss : { *(.bss*) *(COMMON) }
    __bss_end = .;

    . = ALIGN(16);
    . += 0x4000;
    stack_top = .;
}
