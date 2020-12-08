    .fpu    vfp
    .syntax unified         @ modern syntax

    .extern delayMicroseconds

@ Constants for assembler
    .equ    O_RDWR,00000002   @ open for read/write
    .equ    I2C_SLAVE,	0x0703  @from i2c-dev.h
    .equ    BAR_30,	0x76  
    .equ    BAR_30_RESET, 0x1e
    .equ    BAR_30_READ_C_START, 0xa0
    .equ    BAR_30_READ_C_END, 0xac
    .equ    BAR_30_READ_D1_BASE, 0x40
    .equ    BAR_30_READ_D2_BASE, 0x50
    .equ    BAR_30_READ_ADC, 0x00

@ Constant program data
    .section .rodata
    .align  2
device:
    .asciz  "/dev/i2c-1"

@ The program
    .text
    .align  2
    .global reset_bar30, read_bar30_c, read_bar30_d1, read_bar30_d2, open_bar30, close_bar30

@ r0 = fd
reset_bar30:
    push    {fp, lr}
    mov     r1, BAR_30_RESET
    bl      write_bar30
    pop     {fp, pc}

@ Read the calibration data
@ r0 = fd, r1 = char[8] c, void
read_bar30_c:
    push    {r4, r5, r6, fp, lr}

    mov     r4, r0 // fd
    mov     r5, r1  // *c
    mov     r6, BAR_30_READ_C_START // current = start

_read_bar30_c_loop:
    cmp     r6, BAR_30_READ_C_END   // while (current <= end)
    bgt     _read_bar30_c_exit

    // call read
    mov     r0, r4
    mov     r1, r6
    mov     r2, #2
    bl      read_bar30

    strh    r0, [r5], #2            // *(c++) = read_bar30(fd, current, 2)
    add     r6, r6, #2              // current++
    b       _read_bar30_c_loop      // [end while]

_read_bar30_c_exit:
    pop     {r4, r5, r6, fp, pc}

@ r0 = fd, r1 = osr
read_bar30_d1:
    push    {fp, lr}
    mov     r2, r1
    mov     r1, BAR_30_READ_D1_BASE
    bl      read_bar30_sensor_value
    pop     {fp, pc}

@ r0 = fd, r1 = osr
read_bar30_d2:
    push    {fp, lr}
    mov     r2, r1
    mov     r1, BAR_30_READ_D2_BASE
    bl      read_bar30_sensor_value
    pop     {fp, pc}

@ r0 = fd, r1 = base_cmd, r2 = osr
read_bar30_sensor_value:
    push    {r4, r5, r6, fp, lr}
    mov     r4, r0 // fd
    add     r5, r1, r2, lsl #1 // signal = base + (osr << 1)

    mov     r6, #640
    lsl     r6, r6, r2 // delay = 640 << osr

    mov     r1, r5
    bl      write_bar30

    mov     r0, r6
    bl      delayMicroseconds

    mov     r0, r4
    mov     r1, BAR_30_READ_ADC
    mov     r2, #3
    bl      read_bar30

    pop     {r4, r5, r6, fp, pc}

@ no params, void
open_bar30:
    push    {r4, fp, lr}
    ldr     r0, deviceAddr
    mov     r1, O_RDWR
    bl      open

    mov     r4, r0
    mov     r1, I2C_SLAVE
    mov     r2, BAR_30
    bl      ioctl

    mov     r0, r4

    pop     {r4, fp, pc}

@ r0 = fd, void
close_bar30:
    push    {fp, lr}
    bl      close           @ close the file
    pop     {fp, pc}

@ r0 = fd, r1 = data (byte), void
write_bar30:
    push    {r4, fp, lr}

    @ Add buffer data
    strb    r1, [sp, #-8]!

    mov     r1, sp
    mov     r2, #1
    bl      write

    add     sp, sp, #8
    pop     {r4, fp, pc}

    pop     {r4, fp, pc}

@ r0 = fd, r1 = data (byte), r2 = length (up to 4), ret data read (word)
read_bar30:
    push    {r4, r5, r6, fp, lr}

    @ Add buffer data
    strb    r1, [sp, #-8]!
    mov     r4, sp // buffer
    mov     r5, r0 // fd
    mov     r6, r2 // length

    bl      write_bar30 // send the command first

    mov     r0, r5
    mov     r1, r4
    mov     r2, r6
    bl      read        // read(fd, buffer, length)

    // return value, then read off bytes individually because of endianness
    mov     r0, #0
    mov     r3, #0 // counter i

_read_bar_buffer_read:
    cmp     r3, r6                  // for (i = 0; i < length; i++)
    bge     _read_bar30_exit
    ldrb    r12, [sp, r3]           // buffer[i]
    lsl     r0, #8                  // result = (result << 8) | buffer[i]
    orr     r0, r0, r12
    add     r3, r3, #1
    b       _read_bar_buffer_read

_read_bar30_exit:
    add     sp, sp, #8
    pop     {r4, r5, r6, fp, pc}

    .align  2
@ addresses of messages
deviceAddr:
    .word   device
