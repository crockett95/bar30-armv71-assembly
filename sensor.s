@ IOmemory.s
@ Opens the /dev/gpiomem device and maps GPIO memory
@ into program virtual address space.
@ 2017-09-29: Bob Plantz 

@ Define my Raspberry Pi
    .fpu    vfp
    .syntax unified         @ modern syntax

    .extern delay, delayMicroseconds, calculate_bar30

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
    .equ    BAR_30_OSR_256, 0
    .equ    BAR_30_OSR_512, 1
    .equ    BAR_30_OSR_1024, 2
    .equ    BAR_30_OSR_2048, 3
    .equ    BAR_30_OSR_4096, 4

@ Constant program data
    .section .rodata
    .align  2
device:
    .asciz  "/dev/i2c-1"
sensor: 
    .asciz "D1: %d \tD2: %d\n"
output: 
    .asciz "Pressure: %d (mbar*10)\tTemperature: %d (C*100)\n"

@ The program
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

    mov     r2, r1
    mov     r1, r0
    ldr     r0, outputAddr
    bl      printf

    mov     r0, #0
    bl      time

    sub     r0, r0, r6
    cmp     r0, #30
    blt     _main_loop

    mov     r0, r5
    bl      close_bar30
    
    add     sp, #16

    mov     r0, 0           @ return 0;
    pop     {r4, r5, r6, r7, r8, r9, fp, lr}
    bx      lr              @ return

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
outputAddr:
    .word   output
sensorAddr:
    .word   sensor
