SECTION .data
 
        message1: db "Enter file name: ", 0
        formatins: db "%s", 0
        formatouts: db "%s", 10, 0
        
SECTION .bss
        file_name: resb 200

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

        push file_name
        push formatouts
        call printf     ; display the sum
        add esp, 8      ; remove parameters

        pop ecx
        pop ebx         ; restore registers in reverse order
        mov eax, 0      

     ret