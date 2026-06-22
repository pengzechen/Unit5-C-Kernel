.globl _start
_start:
    ldr x0, =0x09000000

    mov w1, #'H'
    strb w1, [x0]
    mov w1, #'e'
    strb w1, [x0]
    mov w1, #'l'
    strb w1, [x0]
    mov w1, #'l'
    strb w1, [x0]
    mov w1, #'o'
    strb w1, [x0]
    mov w1, #'\n'
    strb w1, [x0]

hang:
    wfe
    b hang
