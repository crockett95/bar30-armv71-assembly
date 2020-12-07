	.text
	.section	.rodata
	.align	2
format:
	.ascii	"Pi: %f\012\000"
	.text
	.align	2
	.global	main
	.syntax unified
	.arm
	.fpu vfp
	.type	main, %function
main:
	@ args = 0, pretend = 0, frame = 8
	@ frame_needed = 1, uses_anonymous_args = 0
	push	{fp, lr}
	add	fp, sp, #4
	sub	sp, sp, #8


	mov	r0, #0
	bl	time

	vmov	s15, r0	@ int
	vcvt.f64.s32	d6, s15 // (double) time(NULL)

	vldr.64	d5, .L3 // 2.0
	vdiv.f64	d7, d6, d5 //time(NULL)/2.0

	vmov 	r2, r3, d7
	ldr	r0, formatAddr
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
formatAddr:
	.word	format

