.section .text
.global _start

_start:
    ldr x0, =0x09000000
    ldr x1, =message

1:
    ldrb w2, [x1], #1
    cbz w2, 2f
    strb w2, [x0]
    b 1b

2:
    wfe
    b 2b

.section .rodata
message:
    .asciz "Hello\n"
