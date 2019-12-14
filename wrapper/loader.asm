; libfakeinit for x86_64 Linux & SysV ABI
; Copyright (C) 2019 Menhera.org Developers

; nasm -f elf64 loader.asm

; This source is compiled into an ELF shared object (DSO) which is
; both an executable file and a shared library at the same time.
; This code must be position independent. (PIE)


[warning +all]

BITS 64
CPU X64
DEFAULT REL

GLOBAL _init:function hidden
GLOBAL _start:function hidden


; syscalls
_SYS_WRITE	equ	0x1
_SYS_MMAP	equ	0x9
_SYS_MPROTECT	equ	0xa
_SYS_EXIT	equ	0x3c

_PROT_READ	equ	0x1
_PROT_WRITE	equ	0x2
_PROT_EXEC	equ	0x4
_MAP_PRIVATE	equ	0x2
_MAP_ANONYMOUS	equ	0x20

; constants: adjust accordingly
_MMAP_SIZE	equ	0x2000


SECTION .init
_init:
	lea	rax, [rel _init_real_orig]
	add	rax, _init_real_offset
	jmp	rax

SECTION .text
_start:
	lea	rax, [rel _start_real_orig]
	sub	rax, _start_real_offset
	jmp	rax

SECTION .fini
_fini:
	ret

	incbin	"./wrapper/random.0"
; payload
_payload_1:
	incbin	"./payload/payload.1"
_payload_orig_length	equ	$ - _payload_1
_payload_2:
	incbin	"./payload/payload.2"

	incbin	"./wrapper/random.1"
_init_real_orig:
	incbin	"./wrapper/random.8"
_init_real_offset	equ	$ - _init_real_orig
_init_real:
	; these are registers which must be saved
	push	r12
	push	r13
	push	r14
	push	r15
	push	rbx
	push	rbp
	
	; we are called by dynamic linker
	push	qword	0x1
	
	; argc
	push	rdi
	
	; argv
	push	rsi
	
	; environ
	push	rdx
	
	jmp	_load
	incbin	"./wrapper/random.2"
_load_2:
	mov	r10b, _MAP_PRIVATE | _MAP_ANONYMOUS
	mov	r8, -1
	xor	r9, r9
	syscall
	push	rax
	
	; abort if return value = MAP_FAILED
	xor	rax, -1 ; (-MAP_FAILED)
	test	rax, -1
	jz	_abort
	
	; abort if return value = -EINVAL
	pop	rax
	push	rax
	jmp	_load_3
	incbin	"./wrapper/random.4"
_start_real_2:
	; set argc
	mov	rax, [rsp + 8]
	push	rax
	
	; set argv - may be NULL!
	mov	rsi, rsp
	add	rsi, 24
	push	rsi
	
	; set environ - may be NULL!
	inc	rax
	imul	rax, 8
	add	rsi, rax
	push	rsi
	jmp	_load

_start_real:
	; we are directly executed
	push	qword	0x0
	jmp	_start_real_2
_load:
	; mmap R/W
	xor	eax, eax
	mov	al, _SYS_MMAP
	xor	edi, edi
	xor	esi, esi
	mov	esi, _MMAP_SIZE
	xor	edx, edx
	mov	dl, _PROT_READ | _PROT_WRITE
	xor	r10, r10
	jmp	_load_2
_start_real_orig:
_start_real_offset	equ	$ - _start_real
	incbin	"./wrapper/random.3"
_load_3:
	xor	rax, -0x16 ; (-EINVAL)
	test	rax, -1
	jz	_abort
	
	; copy the payload byte-to-byte
	pop	rdi
	push	rdi
	mov	rcx, _payload_orig_length
	lea	rsi, [rel _payload_1]
	lea	rax, [rel _payload_2]
_load_byte_loop:
	mov	dl, [rsi + rcx - 1]
	mov	bl, [rax + rcx - 1]
	xor	dl, bl
	jmp	_load_byte_loop_2
	incbin	"./wrapper/random.6"

; exit(0)
_exit:
	xor	edi, edi
	jmp	_exit_call

; exit(-1)
_abort:
	mov	rdi, -1

_exit_call:
	xor	eax, eax
	mov	al, _SYS_EXIT
	syscall
_end:
	jmp	_end
	incbin	"./wrapper/random.5"

_load_byte_loop_2:
	mov	[rdi + rcx - 1], dl
	loop	_load_byte_loop
	
	; mprotect R/X
	xor	eax, eax
	mov	al, _SYS_MPROTECT
	pop	rdi
	push	rdi
	xor	esi, esi
	mov	esi, _MMAP_SIZE
	xor	edx, edx
	mov	dl, _PROT_READ | _PROT_EXEC
	syscall
	test	rax, -1
	jnz	_abort
	
	; payload
	pop	rax
	jmp	_load_4
	incbin	"./wrapper/random.5"
_execute:
	; execute payload
	call	rax
	
	; payload returned
	pop	rdx
	test	rdx, rdx
	
	; exit if directly executed
	jz	_exit
	
	; return otherwise
	
	; restore saved registers
	pop	rbp
	jmp	_load_5
_load_4:
	; environ
	pop	rdx
	
	; argv
	pop	rsi
	
	; argc
	pop	rdi
	jmp	_execute

	incbin	"./wrapper/random.10"
_load_5:
	pop	rbx
	pop	r15
	pop	r14
	pop	r13
	pop	r12
	ret
	incbin	"./wrapper/random.7"

