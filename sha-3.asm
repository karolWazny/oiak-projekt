%define STDIN 0x0
%define STDOUT 0x1
%define SYSCALL int 0x80
%define SYSEXIT 0x1
%define SYSWRITE 0x4
%define SYSREAD 0x3
%define SYSOPEN 0x5
%define READONLY 0x0

global _start

section .text:

_start:
            ;putting stuff in the registers
    mov ecx, message                    ;message is the buffer
    mov edx, message_length             ;message length is the number of bytes needed
    call print

    mov ecx, buffer
    mov edx, buffer_size
    call read

    call rot

    call print

    call end

print:
    mov eax, SYSWRITE                        ;use the write syscall
    mov ebx, STDOUT                          ;1 is stdout (desination)
    SYSCALL
    ret

read:
    mov eax, SYSREAD
    mov ebx, STDIN
    SYSCALL
    ret

end:
    mov eax, SYSEXIT
    mov ebx, 0x0
    SYSCALL
    ret

section .data:

    message: db "Input sentence: "    ;define bytes
    message_length equ $-message        ;equal to
section .bss
    buffer resb 100
    buffer_size equ $-buffer