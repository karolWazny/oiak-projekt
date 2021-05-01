%define SYS_CALL 0x80
%define FREAD 0x03
%define FOPEN 0x05
%define FCLOSE 0x06
%define READ_ONLY 0x0

SECTION .data
 
        message1: db "Enter file name: ", 0
        formatins: db "%s", 0
        formatouts: db "%s", 10, 0
        
        fname_w_prefix: db "./"
        file_name: times 200 db 0
        file_buffer: times 1024 db 0
        
SECTION .bss
        descriptor: resb 4
        

SECTION .text

        global main

        extern scanf
        extern printf

     main:
        push ebx        ;save registers
        push ecx

        push message1
        call printf
        add esp, 4      ;remove parameters

        push file_name   ;address of integer1 (second parameter)
        push formatins   ; args are right to left (first parameter)
        call scanf
        add esp, 8      ; remove parameters
        
        push fname_w_prefix
        call open_file
        pop DWORD [descriptor]
        
        push DWORD 1024
        push file_buffer
        push DWORD [descriptor]
        call read_file
        add esp, 12
        
        push DWORD [descriptor]
        call close_file
        add esp, 4

        push file_buffer
        push formatouts
        call printf     ; display the sum
        add esp, 8      ; remove parameters

        pop ecx
        pop ebx         ; restore registers in reverse order
        mov eax, 0      

     ret
     
     open_file:
        mov eax, FOPEN
        mov ebx,[esp+4]
        mov ecx, READ_ONLY
        int SYS_CALL
        mov [esp+4], eax
        ret
        
    close_file:
        mov eax, FCLOSE
        mov ebx, [esp+4]
        int SYS_CALL
        ret
        
    ;3 arguments:
    ;file descriptor
    ;buffer address
    ;number of bytes to read
    ;push to stack in reversed order!
    read_file:
        mov eax, FREAD
        mov ebx, [esp+4]
        mov ecx, [esp+8]
        mov edx, [esp+12]
        int SYS_CALL
        mov ecx, [esp+8]
        mov bl, 0x0
        mov [ecx+eax], bl       ;to assure string read from file is terminated with nul
        ret