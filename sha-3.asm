SECTION .data
 
       message1: db "Enter the first number: ", 0
        message2: db "Enter the second number: ", 0
        formatin: db "%d", 0
        formatout: db "%d", 10, 0 ; newline, nul terminator

        integer1: times 4 db 0
        integer2: times 4 db 0    ; 32-bits integer = 4 bytes

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

        push integer1   ;address of integer1 (second parameter)
        push formatin   ; args are right to left (first parameter)
        call scanf
        add esp, 8      ; remove parameters

        push message2
        call printf
        add esp, 4      ; remove parameters

        push integer2   ; address of integer2
        push formatin   ; arguments are right ot left
        call scanf
        add esp, 8      ; remove parameters

        mov ebx, dword [integer1]
        mov ecx, dword [integer2]
        add ebx, ecx    ; add the values

        push ebx
        push formatout
        call printf     ; display the sum
        add esp, 8      ; remove parameters

        pop ecx
        pop ebx         ; restore registers in reverse order
        mov eax, 0      

     ret