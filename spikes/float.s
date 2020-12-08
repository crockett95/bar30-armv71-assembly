	.arch armv6
	.eabi_attribute 28, 1
	.eabi_attribute 20, 1
	.eabi_attribute 21, 1
	.eabi_attribute 23, 3
	.eabi_attribute 24, 1
	.eabi_attribute 25, 1
	.eabi_attribute 26, 2
	.eabi_attribute 30, 6
	.eabi_attribute 34, 1
	.eabi_attribute 18, 4
	.file	"float.c"
	.text
	.section	.rodata
	.align	2
.LC0:
	.ascii	"Pi: %f\012%f\000"
	.text
	.align	2
	.global	main
	.arch armv6
	.syntax unified
	.arm
	.fpu vfp
	.type	main, %function
main:
	@ args = 0, pretend = 0, frame = 16
	@ frame_needed = 1, uses_anonymous_args = 0
	push	{fp, lr}
	add	fp, sp, #4
	sub	sp, sp, #24
	mov	r0, #0
	bl	time
	vmov	s15, r0	@ int
	vcvt.f64.s32	d6, s15
	vldr.64	d5, .L3
	vdiv.f64	d7, d6, d5
	vstr.64	d7, [fp, #-12]
	mov	r0, #0
	bl	time
	vmov	s15, r0	@ int
	vcvt.f64.s32	d6, s15
	vldr.64	d5, .L3+8
	vdiv.f64	d7, d6, d5
	vstr.64	d7, [fp, #-20]
	ldrd	r2, [fp, #-20]
	strd	r2, [sp]
	ldrd	r2, [fp, #-12]
	ldr	r0, .L3+16
	bl	printf
	mov	r3, #0
	mov	r0, r3
	sub	sp, fp, #4
	@ sp needed
	pop	{fp, pc}
.L4:
	.align	3
.L3:
	.word	0
	.word	1073741824
	.word	0
	.word	1074266112
	.word	.LC0
	.size	main, .-main
	.ident	"GCC: (Raspbian 8.3.0-6+rpi1) 8.3.0"
	.section	.note.GNU-stack,"",%progbits
