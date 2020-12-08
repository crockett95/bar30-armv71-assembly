    .fpu    vfp
    .syntax unified         @ modern syntax

    .extern delay, 
    .extern delayMicroseconds
    .extern calculate_bar30
    .extern open_bar30
    .extern reset_bar30
    .extern read_bar30_c
    .extern read_bar30_d1
    .extern read_bar30_d2
    .extern close_bar30

    .equ    BAR_30_OSR_256, 0
    .equ    BAR_30_OSR_512, 1
    .equ    BAR_30_OSR_1024, 2
    .equ    BAR_30_OSR_2048, 3
    .equ    BAR_30_OSR_4096, 4

@ Constant program data
    .section .rodata
    .align  2
sensor: 
    .asciz "D1: %d \tD2: %d\n"
output: 
    .asciz "Pressure: %2$.1f mbar\tTemperature: %1$.2f C\n"

    .text
    .align  2
    .global main
main:
    push    {r4, r5, r6, r7, r8, r9, fp, lr}
    
    @ Note: it looks like fp should come into play here but I don't know how to
    @ use it and the resources I've found are not great
    sub     sp, sp, #16 // make room for C array
    mov     r4, sp      // C start

    bl      open_bar30
    mov     r5, r0  // fd

    bl      reset_bar30

    mov     r0, r5
    mov     r1, r4
    bl      read_bar30_c

    // Allow a moment for start up
    mov     r0, #1000
    bl      delay

    mov     r0, #0 // NULL
    bl      time
    mov     r6, r0 // int start = time(NULL)

    sub     sp, sp, #8 // make room to store double

_main_loop:
    mov     r0, #500 // small interval
    bl      delay
    
    mov     r0, r5
    mov     r1, BAR_30_OSR_4096
    bl      read_bar30_d2
    mov     r7, r0 // d2

    mov     r0, r5
    mov     r1, BAR_30_OSR_4096
    bl      read_bar30_d1
    mov     r8, r0 // d1

    @diagnostic code
    @ mov     r2, r7
    @ mov     r1, r8
    @ ldr     r0, sensorAddr
    @ bl      printf

    mov     r0, r8
    mov     r1, r7
    mov     r2, r4
    bl      calculate_bar30

    strd    r0, r1, [sp]
    ldr     r0, outputAddr
    bl      printf

    mov     r0, #0
    bl      time

    sub     r0, r0, r6
    cmp     r0, #30
    blt     _main_loop

    mov     r0, r5
    bl      close_bar30
    
    add     sp, #24

    mov     r0, 0           @ return 0;
    pop     {r4, r5, r6, r7, r8, r9, fp, lr}
    bx      lr              @ return

    .align  2
@ addresses of messages
outputAddr:
    .word   output
sensorAddr:
    .word   sensor
