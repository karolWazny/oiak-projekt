%define SYS_CALL 0x80
%define FREAD 0x03
%define FOPEN 0x05
%define FCLOSE 0x06
%define READ_ONLY 0x0

SECTION .data
 
        message1: db "Enter first operand: ", 0
        message2: db "Enter second operand: ", 0
        message3: db "Result: ", 10, 0
        message_err: db "Wrong operand!", 10, 0
        message_crit: db "Problem occured. Ending program...", 10, 0
        message_div_zer: db "Error: Attempt to divide by zero.", 10, 0

        message_res: db "Residue:",10, 0

        message_menu: db "Choose operation:",10,"1. +", 10, "2. -", 10, "3. *", 10, "4. /", 10, 0

        formatins: db "%s", 0
        formatout_hhx_pad: db "%02hhX", 0
        formatout_hhx: db "%hhX", 0
        formatouts: db "%s", 10, 0

        operand_1_sign: times 4 db 0
        operand_1_num: times 200 db 0
        operand_2_sign: times 4 db 0
        operand_2_num: times 100 db 0
        output_num: times 200 db 0
        
SECTION .bss
        input_buffer: resb 256

        operation_id: resb 4
        

SECTION .text

        global main

        extern scanf
        extern printf
        extern memset
        extern putchar
        extern malloc
        extern free

     main:

        menu:
            push message_menu
            call printf
            add esp, 4

            push input_buffer
            push formatins
            call scanf
            add esp, 8

            mov al, [input_buffer]

            cmp al, '1'
            je op_1
            cmp al, '+'
            je op_1
            cmp al, '2'
            je op_2
            cmp al, '-'
            je op_2
            cmp al, '3'
            je op_3
            cmp al, '*'
            je op_3
            cmp al, '4'
            je op_4
            cmp al, '/'
            je op_4

        jmp menu

        op_1:
            mov DWORD [operation_id], 1
            jmp first_operand

        op_2:
            mov DWORD [operation_id], 2
            jmp first_operand

        op_3:
            mov DWORD [operation_id], 3
            jmp first_operand

        op_4:
            mov DWORD [operation_id], 4
            jmp first_operand

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

        cmp eax, 240            ; if we exceeded length of number
        ja first_operand_not_ok ; but not the buffer, we can deal with it

        ;mov ebx, input_buffer
        ;add eax, ebx
        ;dec eax
        ;push ebx                ; last argument - byte 0 of source string
        ;push eax                ; second argument - last byte of source address
        ;push operand_1_num      ; first argument - destination for enourmous int

        push input_buffer
        push operand_1_sign
        push operand_1_num
        call parse_signed_dec
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

        cmp eax, 240                ; if we exceeded length of number
        ja second_operand_not_ok    ; but not the buffer, we can deal with it

        push input_buffer
        push operand_2_sign
        push operand_2_num
        call parse_signed_dec
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

        mov eax, [operation_id]
        cmp eax, 1
        je call_adding

        cmp eax, 2
        je call_subtracting

        cmp eax, 3
        je call_multiplying

        jmp call_dividing

        call_adding:
            call adding
            jmp main_end

        call_subtracting:
            call subtracting
            jmp main_end

        call_multiplying:
            call multiplying
            jmp main_end

        call_dividing:
            call dividing
            jmp main_end

        critical:

        push message_crit
        call printf
        add esp, 4

        main_end:
        mov eax, 0

        ret

    adding:

        push DWORD 200
        push DWORD 0x0
        push output_num
        call memset
        add esp, 12

        call add_enormous
        push message3
        call printf
        add esp, 4

        mov eax, output_num
        mov ebx, 200
        call print_large_dec

        ret

    subtracting:

        push DWORD 200
        push DWORD 0x0
        push output_num
        call memset
        add esp, 12

        mov eax, operand_1_num
        mov ebx, operand_2_num
        mov ecx, 100
        call compare_enormous

        push DWORD 0
        push operand_1_num
        mov ebx, operand_2_num
        mov ecx, operand_1_num
        cmp eax, 0xFF
        jne change_order_end    
    
        change_order:
            add esp, 8
            push DWORD 1
            push operand_2_num
            mov ebx, operand_1_num
            mov ecx, operand_2_num      
        change_order_end:

        push ebx
        push ecx
        call sub_enormous
        add esp, 8

        push message3
        call printf
        add esp, 4

    mov eax, [esp + 4]

    cmp eax, 0
    je print_module
    push DWORD '-'
    call putchar
    add esp, 4
    
    print_module:
        pop eax
        mov ebx, 0
        op_to_output_loop:
            mov ecx, [eax, ebx * 4]
            mov [output_num, ebx * 4], ecx
            inc ebx
            cmp ebx, 25
            jb op_to_output_loop

        add esp, 4
        mov eax, output_num
        mov ebx, 200
        call print_large_dec
        ret

    multiplying:
        call multiply_enormous
        push message3
        call printf
        add esp, 4

        mov eax, output_num
        mov ebx, 200
        call print_large_dec

        ret

    dividing:
        push DWORD 200
        push DWORD 0x0
        push output_num
        call memset
        add esp, 12

        mov eax, operand_2_num
        mov ebx, output_num
        call compare_enormous
        cmp eax, 0
        je divide_by_zero

        call divide_enormous

        push message3
        call printf
        add esp, 4

        mov eax, output_num
        mov ebx, 200
        call print_large_dec

        push message_res
        call printf
        add esp, 4

        mov eax, operand_1_num
        mov ebx, 100
        call print_large_dec

        jmp dividing_end

        divide_by_zero:
            push message_div_zer
            call printf
            add esp, 4

        dividing_end:
        ret

    ; parameters:
    ; destination address        esp + 4
    ; destination sign address   esp + 8
    ; source beginning           esp + 12
    parse_signed_dec:
        mov eax, [esp + 12]
        mov bl, [eax]

        mov ecx, [esp + 12]
        mov ebx, [esp + 4]

        cmp bl, '-'
        jne not_minus

        minus:
            mov eax, [esp + 8]
            mov DWORD [eax], 1
            inc ecx
            jmp sign_end

        not_minus:
            mov eax, [esp + 8]
            mov DWORD [eax], 0
        sign_end:

        mov eax, 0

        parse_dec_loop:
            mov dl, [ecx]
            cmp dl, 0x0
            je parse_dec_end

            sub dl, 0x30
            cmp dl, 0xA
            jae parse_dec_err

            push eax
            push ebx
            push ecx
            push edx

            push DWORD 200
            push DWORD 0x0
            push output_num
            call memset
            add esp, 12

            push DWORD 100
            push DWORD 10
            push ebx
            push output_num
            call mul_enormous_by_const
            add esp, 16

            mov eax, 0
            mov ebx, [esp + 20]

            rewrite_loop:
                mov edx, [output_num, eax * 4]
                mov [ebx, eax * 4], edx
                inc eax
                cmp eax, 25
                jb rewrite_loop

            pop edx
            pop ecx
            pop ebx
            pop eax

            add [ebx], dl

        inc ecx
        jmp parse_dec_loop

        parse_dec_err:
            mov eax, 0xFF
        parse_dec_end:
        ret

    ; parametry:
    ; eax - source
    ; ebx - number of bytes
    print_large_dec:
        push eax
        push ebx
        push DWORD 500
        call malloc
        add esp, 4
        mov edx, eax
        pop ebx
        pop eax
        push edx
        push eax
        push ebx

        push DWORD 200
        call malloc
        add esp, 4
        push eax
        push DWORD 100
        call malloc
        add esp, 4
        push eax
        push DWORD 100
        call malloc
        add esp, 4
        push eax
        ; teraz tak:
        ;     output buffer     [esp + 20]
        ;            source     [esp + 16]
        ;   number of bytes     [esp + 12]
        ;  200 bytes buffer     [esp + 8]
        ;  operand 2 buffer     [esp + 4]
        ;  operand 1 buffer     [esp]
        ; zabezpieczenie outputu i operandow:

        mov eax, operand_1_num
        mov ebx, [esp]
        mov ecx, 0
        preserve_op_1_loop:
            mov edx, [eax, ecx * 4]
            mov [ebx, ecx * 4], edx
            inc ecx
            cmp ecx, 25
            jb preserve_op_1_loop

        mov eax, operand_2_num
        mov ebx, [esp + 4]
        mov ecx, 0
        preserve_op_2_loop:
            mov edx, [eax, ecx * 4]
            mov [ebx, ecx * 4], edx
            inc ecx
            cmp ecx, 25
            jb preserve_op_2_loop

        mov eax, output_num
        mov ebx, [esp + 8]
        mov ecx, 0
        preserve_output_loop:
            mov edx, [eax, ecx * 4]
            mov [ebx, ecx * 4], edx
            inc ecx
            cmp ecx, 50
            jb preserve_output_loop

        push DWORD 100
        push DWORD 0x0
        push operand_2_num
        call memset
        add esp, 12

        ; przygotowanie do uzyskiwania reszty raz za razem
        mov DWORD [operand_2_num], 10

        mov eax, [esp + 16]
        mov ebx, [esp + 12]
        mov ecx, 0
        prepare_number_loop:
            mov dl, [eax + ecx]
            mov [output_num + ecx], dl
            inc ecx
            cmp ecx, ebx
            jb prepare_number_loop

        deb_lab_1:

        mov ecx, 0      ;licznik, ktora to cyfra

        number_to_string_loop:
            push ecx

            mov eax, output_num
            mov ebx, operand_1_num
            mov ecx, 0
            output_to_op1_loop:
                mov edx, [eax, ecx * 4]
                mov [ebx, ecx * 4], edx
                inc ecx
                cmp ecx, 50
                jb output_to_op1_loop

            call divide_enormous

            mov ecx, output_num
            sub ecx, 4
            mov DWORD [ecx], 0

            pop ecx
            mov dl, [operand_1_num]
            add dl, 0x30
            mov ebx, [esp + 20]
            mov [ebx + ecx], dl
            inc ecx

            deb_lab_2:

            mov DWORD [operand_2_num], 0
            push ecx
            mov eax, output_num
            mov ebx, operand_2_num
            mov cx, 200
            call compare_enormous
            pop ecx

            cmp eax, 0
            je number_to_string_loop_end

            mov DWORD [operand_2_num], 10

            jmp number_to_string_loop
        number_to_string_loop_end:

        mov eax, [esp + 20]
        print_dec_loop:
            push eax
            push ecx
            mov ebx, 0
            mov bl, [eax + ecx]
            push ebx
            call putchar
            add esp, 4
            pop ecx
            pop eax
            cmp ecx, 0
            je print_dec_loop_end
            dec ecx
            jmp print_dec_loop
        print_dec_loop_end:

        mov eax, output_num
        mov ebx, [esp + 8]
        mov ecx, 0
        restore_output_loop:
            mov edx, [ebx, ecx * 4]
            mov [eax, ecx * 4], edx
            inc ecx
            cmp ecx, 50
            jb restore_output_loop

        mov eax, operand_2_num
        mov ebx, [esp + 4]
        mov ecx, 0
        restore_op_2_loop:
            mov edx, [ebx, ecx * 4]
            mov [eax, ecx * 4], edx
            inc ecx
            cmp ecx, 25
            jb restore_op_2_loop

        mov eax, operand_1_num
        mov ebx, [esp]
        mov ecx, 0
        restore_op_1_loop:
            mov edx, [ebx, ecx * 4]
            mov [eax, ecx * 4], edx
            inc ecx
            cmp ecx, 25
            jb restore_op_1_loop

        call free
        add esp, 4
        call free
        add esp, 4
        call free
        add esp, 12
        call free
        add esp, 4

        mov eax, 10
        push eax
        call putchar
        add esp, 4

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

            jc add_if_carry

            add_not_carry:
                cmp ecx, 25
                jae add_loop_end            ; while counter < 100
                clc
                jmp add_loop

            add_if_carry:
                cmp ecx, 25
                jae add_loop_end            ; while counter < 100
                stc
                jmp add_loop

        add_loop_end:

        mov eax, [operand_1_num + 96]
        add eax, [operand_2_num + 96]
        mov eax, 0
        adc eax, 0
        mov [output_num + 100], eax

        ret

    ; arguments:
    ; adres odjemnej    esp + 4
    ; adres odjemnika   esp + 8

    sub_enormous:
        mov ecx, 0                  ; ecx is index

        clc

        sub_loop:

            mov eax, [esp + 4]
            mov eax, [eax, ecx * 4]
            mov edx, [esp + 8]
            mov edx, [edx, ecx * 4]
            sbb eax, edx

            mov ebx, [esp + 4]
            mov [ebx, ecx * 4], eax

            inc ecx

            jc sub_if_carry

            sub_not_carry:
                cmp ecx, 25
                jae sub_loop_end            ; while counter < 100
                clc
                jmp sub_loop

            sub_if_carry:
                cmp ecx, 25
                jae sub_loop_end            ; while counter < 100
                stc
                jmp sub_loop

        sub_loop_end:

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
        je cmp_equal

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


        ; arguments:
        ; eax - adres referencyjny
        ; ebx - offset (w BITACH!)
        ; ecx - wartosc bitu
    write_bit:
        push ebx

        shr ebx, 3
        add eax, ebx

        pop ebx
        and ebx, 0x7

        push ecx

        mov ecx, ebx
        mov edx, 1
        shl edx, cl

        pop ecx

        cmp ecx, 0
        jne write_one

        write_zero:
            mov cl, [eax]
            not dl
            and cl, dl
            mov [eax], cl
            jmp write_bit_end

        write_one:
            mov cl, [eax]
            or cl, dl
            mov [eax], cl

        write_bit_end:
            ret

    ; przesuniecie jest koncepcyjnie w lewo (zwiekszenie wartosci)
    ; ale w pamieci bity sa przesuwane w prawo ze wzgledu na
    ; konwencje little-endian
    ; argumenty:
    ; poczatek                  [esp + 4]
    ; dlugosc w bajtach         [esp + 8]
    ; przesuniecie w bajtach    [esp + 12]
    shift_huge_left:
        mov eax, [esp + 4]
        add eax, [esp + 8]
        mov ebx, eax
        sub ebx, [esp + 12]
        
        shift_loop:
            cmp eax, [esp + 4]
            jbe shift_loop_end

            sub eax, 4
            sub ebx, 4

            mov ecx, [ebx]
            mov [eax], ecx

            jmp shift_loop
        shift_loop_end:

        mov eax, [esp + 12]
        mov ebx, [esp + 4]

        push eax
        push DWORD 0x0
        push ebx
        call memset
        add esp, 12

        ret

    ; argumenty
    ; poczatek liczby       [esp + 4]
    ; dlugosc liczby        [esp + 8]
    shift_bit_right:
        mov edx, [esp + 4]
        mov ecx, 0

        sh_b_right_loop:
            cmp ecx, [esp + 8]
            jae shr_loop_end

            mov ax, [edx + ecx]
            shr ax, 1
            mov [edx + ecx], al

            inc ecx

            jmp sh_b_right_loop
        shr_loop_end:
        mov edx, [esp + 4]
        add edx, [esp + 8]
        mov al, [edx]
        and al, 0x7F
        mov [edx], al

        ret

    ; tu rezygnujemy z ponownego wykorzystania kodu
    ; i dzialamy na zmiennych statycznych,
    ; ten kod i tak bedzie sie dlugo wykonywal
    ; wynik dzielenia w output_num, reszta w operand_1_num
    divide_enormous:

        push DWORD 200
        push DWORD 0
        push output_num
        call memset
        add esp, 12

        mov eax, 0
        
        rescale_divisor_loop:
            push eax
            mov eax, operand_1_num
            mov ebx, operand_2_num
            mov ecx, 100
            call compare_enormous
            cmp eax, 1
            pop eax
            jne rescale_divisor_loop_end

            inc eax
            push eax

            push DWORD 1
            push DWORD 100
            push operand_2_num
            call shift_huge_left
            add esp, 12

            pop eax

            jmp rescale_divisor_loop
        rescale_divisor_loop_end:

        ; w eax mamy liczbe bajtow o ktora
        ; przeskalowalismy dzielnik
        mov ebx, 8
        mul ebx    ; teraz mamy juz liczbe bitow w eax

        divide_loop:
            push eax

            mov eax, operand_1_num
            mov ebx, operand_2_num
            mov ecx, 100
            call compare_enormous

            cmp eax, 0xFF
            je div_writ_0

            div_writ_1:
                ; write_bit(output_num, eax, 1)
                mov eax, output_num
                mov ebx, [esp]
                mov ecx, 1
                call write_bit

                push operand_2_num
                push operand_1_num
                call sub_enormous
                add esp, 8

                jmp div_writ_end

            div_writ_0:
                ; write_bit(output_num, eax, 0)
                mov eax, output_num
                mov ebx, [esp]
                mov ecx, 0
                call write_bit

            div_writ_end:
                push DWORD 100
                push operand_2_num
                call shift_bit_right
                add esp, 8

                pop eax
                dec eax

                cmp eax, 0
                jl divide_loop_end

                jmp divide_loop

        divide_loop_end:

        ret
