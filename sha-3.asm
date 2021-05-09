%define SYS_CALL 0x80
%define FREAD 0x03
%define FOPEN 0x05
%define FCLOSE 0x06
%define READ_ONLY 0x0

%define LSEEK 0x13
%define SEEK_SET 0
%define SEEK_CUR 1
%define SEEK_END 2

SECTION .data
 
        message1: db "Enter file name: ", 0
        formatins: db "%s", 0
        formatouts: db "%s", 10, 0
        
        fname_w_prefix: db "./"
        file_name: times 200 db 0
        
SECTION .bss
        descriptor: resb 4
        file_size: resb 4
        file_buffer: resb 1024
        lane_pointers: resb 25
        lane_pointers_alt: resb 25
        

SECTION .text

        global main

        extern scanf
        extern printf
        extern ftell
        extern malloc
        extern free

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

    ;2 arguments:
    ;file descriptor
    ;long address to put value
    ;not finished yet!
    file_length:
        mov eax, LSEEK
        mov ebx, [esp + 4]
        mov ecx, 0
        mov edx, SEEK_END
        int SYS_CALL

        mov eax, [esp + 4]
        push eax
        call ftell
        pop eax

        mov ebx, [esp + 8]
        mov [ebx], eax

        

        ret

    ;4 arguments:
    ;destination address
    ;source address
    ;number of bytes to xor
    xor_strings:
        mov ecx, [esp + 12]
        mov edx, 0x0            ;loop counter

        xstr_loop:
            mov eax, [esp + 4]
            mov ebx, [esp + 8]

            mov al, [eax + edx]
            mov bl, [ebx + edx]

            xor bl, al

            mov eax, [esp + 4]
            mov [eax + edx], bl

            inc edx
            cmp edx, ecx
            jb xstr_loop

        ret

    ;function to rotate string slightly up to seven bits
    ;to the right
    ;arguments:
    ;string address
    ;string length in bytes
    ;offset
    shift_string_small:
        mov ebx, [esp + 4]
        mov edx, [esp + 8]
        mov ecx, [esp + 12]

        add ebx, edx
        dec ebx

        mov eax, 0
        mov al, [ebx]
        push eax        ;now arguments are 4 bytes further on the stack

        sh_str_s_loop:
            dec ebx
            mov ax, [ebx]
            shr ax, cl

            inc ebx
            mov [ebx], al
            dec ebx

            mov eax, [esp + 8]      ;string address
            cmp ebx, eax
            ja sh_str_s_loop

        pop eax
        mov ah, al
        mov ebx, [esp + 4]
        mov al, [ebx]

        shr ax, cl

        mov [ebx], al

        ret


    ;rotates string by offset given in bytes
    ;arguments:
    ;string address
    ;string length
    ;offset
    shift_string_big:
        mov edx, [esp + 12]
        push edx

        call malloc

        add esp, 4
        mov ebx, [esp + 4]
        mov ecx, [esp + 8]
        mov edx, [esp + 12]

        push eax                ; so we don't lose our pointer

        add ebx, ecx
        dec ebx

        add eax, edx
        dec eax

        sh_buffer_loop:
            push ebx
            mov bl, [ebx]
            mov [eax], bl
            pop ebx
            dec eax
            dec ebx
            cmp eax, [esp]
            jae sh_buffer_loop

        mov eax, ebx        ; source pointer
        add ebx, edx        ; destination pointer

        mov ecx, [esp + 8]  ; string address

        sh_loop:
            mov dl, [eax]
            mov [ebx], dl
            dec eax
            dec ebx
            cmp eax, ecx
            jae sh_loop

        mov eax, [esp]      ; buffer address
        mov ebx, ecx        ; string address
        add ecx, [esp + 16] ; first byte after first [offset] bytes in the string

        sh_loop_2:
            mov dl, [eax]
            mov [ebx], dl
            inc eax
            inc ebx
            cmp ebx, ecx
            jb sh_loop_2
        
        ; top of stack is now buffer address

        call free
        add esp, 4

        ret