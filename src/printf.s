section .text

global MyPrintf
;
;_start:     mov rdi, test_format
;            mov rsi, 12
;            call MyPrintf
;
;            mov rax, 0x3C
;            xor rdi, rdi
;            syscall

; ----------------------------------------------------------------------------------------
; Главная функция printf, также является просто обёрткой для своеобразной функции printf, которая
; работает только со стеком
;
; Entry: rdi   = форматная строка (формально первый    аргумент функции)
;        rsi   = 1 аргумент       (формально второй    аргумент функции)
;        rdx   = 2 аргумент       (формально третий    аргумент функции)
;        rcx   = 3 аргумент       (формально четвертый аргумент функции)
;        r8    = 4 аргумент       (формально пятый     аргумент функции)
;        r9    = 5 аргумент       (формально шестой    аргумент функции)
;        stack = 6 и последующие аргументы
; Exit:  ...
; Destr: r10
; ----------------------------------------------------------------------------------------
MyPrintf:
            pop r10;            ; сохранили адрес возврата
            push r9
            push r8
            push rcx
            push rdx
            push rsi

            call ProcessingStack

            pop rsi
            pop rdx
            pop rcx
            pop r8
            pop r9
            push r10

            ret

; ----------------------------------------------------------------------------------------
; Функция разделяющая места, куда нужно подставить данные, и которые нужно просто вывести
;
; Entry: rdi   - форматная строка
;        stack - все аргументы в таком порядке (вершина стека->1-ый->2-ой->...)
; Exit:  ...
; Destr: ...
; ----------------------------------------------------------------------------------------
ProcessingStack:
            push rbp
            mov rbp, rsp

            add rbp, 16         ; в стеке до первого аргумента лежит еще [старое значение rbp] и [адрес возврата]

.printing_loop:
            cmp byte [rdi], 0
            je .exit

            cmp byte [rdi], '%'
            jne .common_symbol

            inc rdi
            cmp byte [rdi], '%'     ;если встретили "%%" в строке, ничего не должны делать и считаем % обычным символом
            je .common_symbol

            call SpecialSymbolProc
            cmp rax, -1
            je .exit
            inc rdi
            jmp .printing_loop
.common_symbol:
            call PrintChar
            inc rdi
            jmp .printing_loop
.exit:
            pop rbp
            ret

; -----------------------------------------------------------------------------------------
; Обрабатывает спецификатор после символа '%'
;
; Entry: rdi = адрес в строке, по которому лежит спецификтор
;        rbp = адрес аргумента в стеке
;
; Exit:  rbp += 8, если всё хорошо
;        rax = -1  если произошла ошибка //FIXME обрабатывать ошибки
; Destr: rax, rcx
; ----------------------------------------------------------------------------------------
SpecialSymbolProc:
            cmp byte [rdi], 'a'
            jb processInvalid
            cmp byte [rdi], 'z'
            ja processInvalid

            xor rcx, rcx           ;!!!
            mov cl, [rdi]
            mov rcx, [jump_table - 8*('a' - rcx)]
            jmp rcx
return_here_after_jmp_table:
            add rbp, 8
            ret
processInvalid:
            mov rax, -1                   ;//FIXME обрабатывать ошибки
            ret

; ----------------------------------------------------------------------------------------
; НЕ функция, а просто обработчик вывода символа в двоичной системе счисления
;
; Entry: rbp = адрес, по которому лежит число, которое нужно напечатать в двоичной системе счисления
; Exit:  None
; Destr:
; ----------------------------------------------------------------------------------------
processBinary:
            push rdi
            mov rdi, rbp
            mov rsi, 2
            call NumberToASCII
            pop rdi
            jmp return_here_after_jmp_table

; ----------------------------------------------------------------------------------------
; НЕ функция, а просто обработчик вывода одного символа
;
; Entry: rbp = адрес, по которому лежит символ, который нужно напечатать
; Exit:  None
; Destr:
; ----------------------------------------------------------------------------------------
processChar:
            push rdi
            mov rdi, rbp
            call PrintChar
            pop rdi
            jmp return_here_after_jmp_table

; ----------------------------------------------------------------------------------------
; НЕ функция, а просто обработчик вывода символа в десятичной системе счисления
;
; Entry: rbp = адрес, по которому лежит число, которое нужно напечатать в десятичной системе счисления
; Exit:  None
; Destr:
; ----------------------------------------------------------------------------------------
processDecimal:
            push rdi
            mov rdi, rbp
            mov rsi, 10
            call NumberToASCII
            pop rdi
            jmp return_here_after_jmp_table

; ----------------------------------------------------------------------------------------
; НЕ функция, а просто обработчик вывода символа в восьмеричной системе счисления
;
; Entry: rbp = адрес, по которому лежит число, которое нужно напечатать в восьмеричной системе счисления
; Exit:  None
; Destr:
; ----------------------------------------------------------------------------------------
processOct: push rdi
            mov rdi, rbp
            mov rsi, 8
            call NumberToASCII
            pop rdi
            jmp return_here_after_jmp_table

; ----------------------------------------------------------------------------------------
; НЕ функция, а просто обработчик вывода символа в шестнадцатеричной системе счисления
;
; Entry: rbp = адрес, по которому лежит число, которое нужно напечатать в шестнадцатеричной системе счисления
; Exit:  None
; Destr:
; ----------------------------------------------------------------------------------------
processHex: push rdi
            mov rdi, rbp
            mov rsi, 16
            call NumberToASCII
            pop rdi
            jmp return_here_after_jmp_table

processString:                ;//TODO
            jmp return_here_after_jmp_table

;processInvalid:               ;//TODO
;            jmp return_here_after_jmp_table

; ----------------------------------------------------------------------------------------
; Выводит символ в stdout
;
; Entry: rdi = адрес, по которому лежит символ, который нужно напечатать
; Exit:  ...
;
; Destr: ...
; ----------------------------------------------------------------------------------------
PrintChar:
            push rdi            ; сохрянем регистры, которые испортим при syscall
            push rsi
            push rdx
            push rax

            mov rax, 0x01       ; syscall of "write"
            mov rsi, rdi        ; адрес буфера
            mov rdi, 1          ; файловый дескриптор stdout
            mov rdx, 1          ; количество символов для вывода
            syscall

            pop rax
            pop rdx
            pop rsi
            pop rdi

            ret

; ----------------------------------------------------------------------------------------
; Переводит число в набор ASCII кодов для вывода в консоль
; Entry: rdi = адрес, по которому лежит начало числа
;        rsi = основание системы счисления
;
; Destr:
; ----------------------------------------------------------------------------------------
NumberToASCII:
            push rax            ; используется для хранения значения числа
            push rbx            ; используется для адресации к буферу
            push rcx            ; используется для подсчёта количества разрядов
            push rdx            ; занулим его перед делением (то есть испортим)
            push rdi            ; испортим его минусом/испортим при syscall

            mov rax, [rdi]      ; в rax число, которое нужно напечатать
            test rax, rax
            jns .number_is_positive

.number_is_negative:
            mov rdi, '-'
            call PrintChar
            neg rax

.number_is_positive:
            mov rbx, num_buffer + num_buffer_size - 1   ;rbx-конец буфера

            cmp rsi, 10                     ; //ДЕЛО СДЕЛАНО если СС кратна двум, то сдвиг вместо деления и побитовые операции
            jne .powers_of_two_base_process

.ten_base_loop:
            xor rcx, rcx        ; считаем количество разрядов
            inc rcx
            xor rdx, rdx        ; div считает делимым большое 128-битное число [rdx][rax]
            div rsi
            mov dl, [array_for_converting_numbers + rdx]
            mov [rbx], dl
            dec rbx             ; декрементируем, так как идем справа налево по буферу
            test rax, rax
            jnz .ten_base_loop  ; продолжаем до тех пор, пока не получим ноль
            jmp .output

.powers_of_two_base_process:
            cmp rsi, 2
            jne .next_check_1
            mov r9, 1
            jmp .powers_of_two_base_loop
.next_check_1:
            cmp rsi, 8
            jne .next_check_2
            mov r9, 3
            jmp .powers_of_two_base_loop
.next_check_2:
            mov r9, 4

.powers_of_two_base_loop:
            mov rdx, rax

            cmp r9, 1
            jne .check_next_3
            and rdx, 1          ;mask = 1
            jmp .digit_ready

.check_next_3:
            cmp r9, 3
            jne .check_next_4
            and rdx, 7          ; mask = 7
            jmp .digit_ready
.check_next_4:
            and rdx, 15         ; mask = 15
            jmp .digit_ready                    ;//FIXME добавить бы еще ветку, которая обрабатывает ошибки, или пофиг?

.digit_ready:
            mov dl, [array_for_converting_numbers + rdx]
            mov [rbx], dl
            dec rbx
            mov rcx, r9
            shr rax, cl          ; в качестве второго операнда можно использовать только cl/константу
            test rax, rax
            jnz .powers_of_two_base_loop

.output:
            mov rax, 0x01
            mov rsi, num_buffer + num_buffer_size
            sub rsi, rcx
            mov rdi, 1
            mov rdx, rcx
            syscall

            pop rdi
            pop rdx
            pop rcx
            pop rbx
            pop rax

            ret


section     .data


num_buffer_size equ 64
num_buffer:  db num_buffer_size dup(0)
test_format: db "check = %o", 0xd, 0xa, 0
test_string: db "test string", 0
array_for_converting_numbers: db "0123456789ABCDEF"
jump_table:
            dq processInvalid ; a
            dq processBinary  ; b
            dq processChar    ; c
            dq processDecimal ; d
            dq processInvalid ; e
            dq processInvalid ; f
            dq processInvalid ; g
            dq processInvalid ; h
            dq processInvalid ; i
            dq processInvalid ; j
            dq processInvalid ; k
            dq processInvalid ; l
            dq processInvalid ; m
            dq processInvalid ; n
            dq processOct     ; o
            dq processInvalid ; p
            dq processInvalid ; q
            dq processInvalid ; r
            dq processString  ; s
            dq processInvalid ; t
            dq processInvalid ; u
            dq processInvalid ; v
            dq processInvalid ; w
            dq processHex     ; x
            dq processInvalid ; y
            dq processInvalid ; z
