    
	.syntax unified
	.arm
	.fpu vfp
    
    .global calculate_bar30
    .text

calculate_bar30:
    push    {r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
    mov     r4, r0  // save d1
    mov     r5, r1  // save d2
    mov     r6, r2  // save C

    // long dt = d2 - (c[5] << 8);
    ldrh    r3, [r6, #10]
    lsl     r3, r3, #8
    sub     r7, r5, r3

    // long temp = 2000 + (dt * c[6] >> 23);
    ldrh    r3, [r6, #12]   // c6
    mul     r2, r3, r7      // dt * c6
    asr     r3, r2, #23
    add     r8, r3, #2000

    //long long off = (c[2] << 16) + (c[4] * dt >> 7);
    ldrh    r0, [r6, #8] // c4
    smull   r2, r1, r7, r0 // c4 * dt

    // shifting a 64 bit means shift lower bits down 7,
    // then shift on lower 7 of upper (lsr 32-7 = 25) with orr, then shift down upper
    lsr     r2, r2, #7
    lsl     r3, r1, #25
    orr     r2, r2, r3
    asr     r1, r1, #7

    ldrh    r0, [r6, #4] // c2
    lsl     r0, r0, #16  // c2 is 16-bit so it will fit in 32 after shift

    adds    r10, r0, r2  // off lo
    adc     r9, r1, #0   // off hi

    // long long sens = (c[1] << 15) + (c[3] * dt >> 8);
    ldrh    r0, [r6, #6] // c3
    smull   r2, r1, r7, r0 // c3 * dt

    // shifting a 64 bit means shift lower bits down 8,
    // then shift on lower 8 of upper (lsr 32-8 = 24) with orr, then shift down upper
    lsr     r2, r2, #8
    lsl     r3, r1, #24
    orr     r2, r2, r3
    asr     r1, r1, #8

    ldrh    r0, [r6, #2] // c1
    lsl     r0, r0, #15  // c1 is 15-bit so it will fit in 32 after shift

    adds    r12, r0, r2  // sens lo
    adc     r11, r1, #0   // sens hi

    // long p = ((d1 * sens >> 21) - off) >> 13;
    smull   r2, r1, r4, r12
    mla     r1, r4, r11, r1

    // shifting a 64 bit means shift lower bits down 21,
    // then shift on lower 21 of upper (lsr 32-21 = 11) with orr, then shift down upper
    lsr     r2, r2, #21
    lsl     r3, r1, #11
    orr     r2, r2, r3
    asr     r1, r1, #21

    subs    r2, r2, r10
    sbc     r1, r1, r9

    // shifting a 64 bit means shift lower bits down 13,
    // then shift on lower 13 of upper (lsr 32-13 = 19) with orr, then shift down upper
    lsr     r2, r2, #13
    lsl     r3, r1, #19
    orr     r2, r2, r3   // p
    asr     r1, r1, #13  // should be zero

    mov     r0, r2

    vmov            s15, r2 // p
    vcvt.f64.s32    d4, s15
    mov             r2, #10
    vmov            s15, r2
    vcvt.f64.s32    d5, s15

    vdiv.f64        d7, d4, d5

    vmov    r0, r1, d7

    vmov            s15, r8 // temp
    vcvt.f64.s32    d4, s15
    mov             r2, #100
    vmov            s15, r2
    vcvt.f64.s32    d5, s15

    vdiv.f64        d7, d4, d5

    vmov    r2, r3, d7

    pop     {r4, r5, r6, r7, r8, r9, r10, r11, r12, pc}

@ main:
@     ldr     r0, bar30_d1
@     ldr     r1, bar30_d2
@     adr     r2, bar30_c

@     bl      calculate_bar30


@     mov     r2, r1
@     mov     r1, r0
@     adr     r0, output
@     bl      printf

@     mov     r7, #1		// Exit system call
@ 	swi     0

@ output: .asciz "Pressure: %d (mbar*10)\tTemperature: %d (C*100)\n"
@ bar30_c: .hword 0, 34982, 36352, 20328, 22354, 26646, 26146, 0
@ bar30_d1: .word 4958179
@ bar30_d2: .word 6815414
@ output_addr: .word output
