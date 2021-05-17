%define SYS_CALL 0x80
%define FREAD 0x03
%define FOPEN 0x05
%define FCLOSE 0x06
%define READ_ONLY 0x0

SECTION .data
 
        message1: db "Enter first operand in hex: 0x", 0
        message2: db "Enter second operand in hex: 0x", 0
        message3: db "Multiplication result: ", 10,"0x", 0
        message_err: db "Wrong operand!", 10, 0
        message_crit: db "Problem occured. Ending program...", 10, 0

        formatins: db "%s", 0
        formatout_hhx_pad: db "%02hhX", 0
        formatout_hhx: db "%hhX", 0
        formatouts: db "%s", 10, 0

        operand_1_num: times 100 db 0
        operand_2_num: times 100 db 0
        output_num: times 200 db 0
        
SECTION .bss
        input_buffer: resb 256
        

SECTION .text

        global main

        extern scanf
        extern printf
        extern memset
        extern putchar

     main:
        push ebx        ;save registers
        push ecx

        first_operand:

        push message1
        call printf
        add esp, 4      ;remove parameters

        push input_buffer       ;address of integer1 (second parameter)
        push formatins          ; args are right to left (first parameter)
        call scanf
        add esp, 8              ; remove parameters

        mov eax, input_buffer
        call str_len            ; how long was the string provided?
        cmp eax, 0              ; if no digits were provided, we ask for them
        je first_operand_not_ok ; again

        cmp eax, 255            ; if length of string provided exceeded buffer      
        ja critical             ; we might have overwritten sth important
                                ; so we just end the program

        cmp eax, 200            ; if we exceeded length of number
        je first_operand_not_ok ; but not the buffer, we can deal with it

        mov ebx, input_buffer
        add eax, ebx
        dec eax
        push ebx                ; last argument - byte 0 of source string
        push eax                ; second argument - last byte of source address
        push operand_1_num      ; first argument - destination for enourmous int
        call parse
        add esp, 12

        cmp al, 0xFF            ; we catch any errors occured while parsing
        je first_operand_not_ok

        jmp second_operand

        first_operand_not_ok:
        push message_err
        call printf
        add esp, 4

        push DWORD 100          ; problem might have occured during string parsing
        push DWORD 0x0          ; leaving rubbish in operand_1_num
        push operand_1_num      ; we get rid of that to be able to
        call memset             ; use that space for parsing again
        add esp, 12

        jmp first_operand


        second_operand:

        push message2
        call printf
        add esp, 4      ;remove parameters

        push input_buffer       ;address of integer1 (second parameter)
        push formatins          ; args are right to left (first parameter)
        call scanf
        add esp, 8              ; remove parameters

        mov eax, input_buffer
        call str_len                ; how long was the string provided?
        cmp eax, 0                  ; if no digits were provided, we ask for them
        je second_operand_not_ok    ; again

        cmp eax, 255                ; if length of string provided exceeded buffer      
        ja critical                 ; we might have overwritten sth important
                                    ; so we just end the program

        cmp eax, 200                ; if we exceeded length of number
        je second_operand_not_ok    ; but not the buffer, we can deal with it

        mov ebx, input_buffer
        add eax, ebx
        dec eax
        push ebx                    ; last argument - byte 0 of source string
        push eax                    ; second argument - last byte of source address
        push operand_2_num          ; first argument - destination for enourmous int
        call parse
        add esp, 12

        cmp al, 0xFF                ; we catch any errors occured while parsing
        je second_operand_not_ok

        jmp second_operand_ok

        second_operand_not_ok:
        push message_err
        call printf
        add esp, 4

        push DWORD 100          ; problem might have occured during string parsing
        push DWORD 0x0          ; leaving rubbish in operand_1_num
        push operand_2_num      ; we get rid of that to be able to
        call memset             ; use that space for parsing again
        add esp, 12

        jmp second_operand


        second_operand_ok:

        ;call multiply_enormous

        push message3
        call printf
        add esp, 4


        ;#####################       

        push DWORD 100
        push DWORD 0xA
        push operand_1_num
        push output_num
        call mul_enormous_by_const
        add esp, 16

        ;#####################

        mov eax, output_num
        mov ebx, 200
        call print_large

        jmp main_end

        critical:

        push message_crit
        call printf
        add esp, 4

        main_end:
        pop ecx
        pop ebx         ; restore registers in reverse order
        mov eax, 0

        ret

    ;parameters:
    ;destination address        esp + 4
    ;source last byte address   esp + 8
    ;source zero byte address   esp + 12
    parse:
        mov edx, [esp + 4]      ;current byte's destination in edx
        mov ecx, [esp + 8]      ;current char's source in ecx

        parse_loop:
        mov al, [ecx]
        call parse_digit        ;translate character to 4-bit value

        cmp al, 0xFF
        je parse_err            ;if there was an error when parsing this character

        mov bl, al
        push bx             ;we store our value on stack, so we can use al to call parse_digit again
        
        dec ecx
        cmp ecx, [esp + 14]     ;if we just read last character but need one more
        jb end_of_string

        mov al, [ecx]

        call parse_digit        ;translate character to 4-bit value

        cmp al, 0xFF
        je parse_err_sec        ;if there was an error when parsing this character

        jmp rest_of_loop
        end_of_string:          ;we just pad the string with leading 0, no need to translate
        mov al, 0x0

        rest_of_loop:

        mov ah, al              ;move older bits to ah

        pop bx                  ;
        ;mov ah, bl
        mov al, bl              ;younger bits in al, older in ah
        call merge_2_digits

        mov [edx], al

        inc edx
        dec ecx
        cmp ecx, [esp + 12]     ;if we haven't exceeded first character in the string yet
        jae parse_loop          ;we loop

        mov eax, 0x0
        jmp parse_end

        parse_err_sec:      ; if error occured after pushing bx, but before popping it
        pop bx
        parse_err:          ; if error occured before pushing bx
        mov al, 0xFF
        parse_end:
        ret

    ;ascii character in al 
    ;translates HEX digit to 4-bit value, returns in al
    ;returns 0xFF if character provided was no digit
    parse_digit:
        sub al, 0x30        ;we assume it is a decimal digit
        cmp al, 0x0A        ;if so
        jb parse_byte_end   ;we jump to return
        sub al, 0x07        ;otherwise we assume it's from range A - F
        cmp al, 0x0A        ;if it was below A, we return error code
        jb parse_byte_err
        cmp al, 0x10        ;if in the range, we return translated value
        jb parse_byte_end
        sub al, 0x20        ;if not, we assume it was from range a - f
        cmp al, 0x0A        ;if below a, we return error code
        jb parse_byte_err   
        cmp al, 0x10
        jb parse_byte_end   ;if in the range, we return translated value
        parse_byte_err:     ;otherwise we return error code
        mov al, 0xFF
        parse_byte_end:
        ret

    ;parameters:
    ;older 4 bits in ah
    ;younger 4 bits in al
    ;returns 8-bit value like ah|al in al
    merge_2_digits:
        shl ah, 0x04
        add al, ah
        ret

    ;parameters:
    ; first (youngest) byte address in eax
    ; number of bytes in ebx (like sizeof(enormous_int_type))
    ; we assume little-endiannes here!!!
    print_large:
        add ebx, eax
        leading_zeros:  ; no need to print all the leading zeros
            dec ebx     ; last byte of the enormous_int_type address
            mov dl, [ebx]
            cmp ebx, eax
            jbe first_printable

            cmp dl, 0x0
            je leading_zeros

        
        first_printable:
        push eax
        push ebx
        push edx
        push formatout_hhx
        call printf
        add esp, 8
        pop ebx
        pop eax

        p_large_loop:
            dec ebx
            cmp ebx, eax
            jb p_large_end

            push eax
            push ebx
            mov dl, [ebx]
            push edx
            push formatout_hhx_pad
            call printf
            add esp, 8
            pop ebx
            pop eax

            jmp p_large_loop

        p_large_end:

        push DWORD 10
        call putchar
        add esp, 4

        ret

    ;parameters:
    ;first character in a string address in eax
    ;returns number of characters in a string in eax
    str_len:
        push ecx
        mov ecx, 0x0
        mov bl, [eax + ecx]
        cmp bl, 0x0
        je str_len_end

        strlen_loop:
        inc ecx
        mov bl, [eax + ecx]
        cmp bl, 0x0
        jne strlen_loop

        dec eax
        jmp str_len_end

        str_len_end:
        mov eax, ecx
        pop ecx
        ret

    ;arguments:
    ;destination        [esp + 4]
    ;source             [esp + 8]
    ;const              [esp + 12]
    ;source length      [esp + 16]
    mul_enormous_by_const:
                ; prepare destination by setting all bits to 0
        mov eax, [esp + 16]         ; max size of output
        add eax, 4
        mov ebx, [esp + 4]          ; dest address
        push eax                    ; max output size
        push DWORD 0x0              ; we want to reset all bits
        push ebx                    ; destination address
        call memset
        add esp, 12

        mov ebx, 0

        mov ecx, [esp + 16]         ; operand length
        and ecx, 0x3                ; equivalent of [eax]%3, but faster
        ; ecx is counter now


        multiplication_bytes:
            cmp ecx, 0
            je multiplication_bytes_end
            dec ecx
            mov ebx, [esp + 8]
            mov eax, 0
            mov al, [eax + ecx]     ; read interesting byte from memory
            mov edx, [esp + 12]

            mul edx

            push ecx
            mov ebx, [esp + 8]
            add ebx, ecx
            add [ebx], eax

            bytes_while_carry:
                adc [ebx + 4], edx
                jc bytes_if_carry
                add ebx, 4
                mov edx, 0
                jmp bytes_while_carry_end

                bytes_if_carry:
                    add ebx, 4
                    mov edx, 0
                    stc

                bytes_while_carry_end:
                    jc while_carry          ; we keep propagating carry while there is any
            pop ecx

            jmp multiplication_bytes
        multiplication_bytes_end:


        mov ebx, 0

        mov ecx, [esp + 16]         ; operand length
        and ecx, 0x3                ; ecx is index now

        mov ebx, [esp + 8]          ; ebx is the beginning of source aligned by 4
        add ebx, ecx

        mov ecx, [esp + 16]
        shr ecx, 2


        multiplication_dwords:
            cmp ecx, 0
            je multiplication_dwords_end
            dec ecx
            mov eax, [ebx, ecx * 4]
            mov edx, [esp + 12]

            mul edx
            
            push ebx
            push ecx
            mov ebx, [esp + 12]
            add [ebx, ecx * 4], eax

            dwords_while_carry:
                inc ecx
                adc [ebx, ecx * 4], edx
                mov edx, 0
                jc while_carry          ; we keep propagating carry while there is any
            pop ecx
            pop ebx

            jmp multiplication_dwords

        multiplication_dwords_end:

        ret


    multiply_enormous:
        ; prepare destination by setting all bits to 0
        push DWORD 200          ; twice the length of operand
        push DWORD 0x0          ; we want to reset all bits
        push output_num         ; destination address
        call memset
        add esp, 12

        mov ebx, 0
        ;multiplication algorithm
        mul_ext_loop:

        mov ecx, 0

        mul_inner_loop:
            mov eax, [operand_1_num + ebx]
            mov edx, [operand_2_num + ecx]
            mul edx

            push ecx                ; temporarily we need ecx for destination address
            add ecx, output_num     ; of current byte
            add ecx, ebx
            clc

            add [ecx], eax          ; we add younger bits of multiplying
            add ecx, 4              ; properly shifted to output

            while_carry:
            adc [ecx], edx          ; the same about older bits, but with carry
          jc if_carry
            add ecx, 4
            mov edx, 0
          jmp while_carry_end

          if_carry:
          add ecx, 4
          mov edx, 0
          stc

          while_carry_end:
            jc while_carry          ; we keep propagating carry while there is any

            pop ecx                 ; we want our counter back
            add ecx, 4
            cmp ecx, 100
            jb mul_inner_loop       ; while counter is lower than 100

        add ebx, 4
        cmp ebx, 100
        jb mul_ext_loop             ; while counter < 100

        ret

    add_enormous:
        ; prepare destination by setting all bits to 0
        push DWORD 200          ; twice the length of operand
        push DWORD 0x0          ; we want to reset all bits
        push output_num         ; destination address
        call memset
        add esp, 12

        mov ecx, 0                  ; ecx is index

        clc

        add_loop:
            mov eax, [operand_1_num, ecx * 4]
            mov edx, [operand_2_num, ecx * 4]
            adc eax, edx

            mov [output_num, ecx * 4], eax

            inc ecx

            cmp ecx, 25
            jb add_loop             ; while counter < 100

        mov eax, 0
        adc eax, 0
        mov [output_num + 100], eax

        ret

    ; arguments:
    ; adres odjemnej    esp + 4
    ; adres odjemnika   esp + 8

    sub_enormous:
        ; prepare destination by setting all bits to 0
        push DWORD 200          ; twice the length of operand
        push DWORD 0x0          ; we want to reset all bits
        push output_num         ; destination address
        call memset
        add esp, 12

        mov ecx, 0                  ; ecx is index

        clc

        sub_loop:
            mov eax, [esp + 4]
            mov eax, [eax, ecx * 4]
            mov edx, [esp + 8]
            mov edx, [edx, ecx * 4]
            sbb eax, edx

            mov [output_num, ecx * 4], eax

            inc ecx

            cmp ecx, 25
            jb sub_loop             ; while counter < 100

        mov eax, 0
        sbb eax, 0
        mov [output_num + 100], eax

        ret

        ; arguments:
        ; eax adres pierwszej liczby
        ; ebx adres drugiej liczby
        ; ecx rozmiar liczb w bajtach
        ; zwraca w eax
        ; 0xFF jezeli pierwsza mniejsza
        ; 0 jezeli rowne
        ; 0x1 jezeli druga mniejsza
        compare_enormous:
            cmp ecx, 0
            jmp cmp_equal

            dec ecx

            mov dl, [eax + ecx]
            cmp dl, [ebx + ecx]
            
            jb cmp_second_larger
            ja cmp_first_larger

            jmp compare_enormous


            cmp_equal:
                mov eax, 0
                jmp compare_end

            cmp_first_larger:
                mov eax, 1
                jmp compare_end

            cmp_second_larger:
                mov eax, 0xFF

            compare_end:
            ret