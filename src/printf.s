section .text

global MyPrintf

;global _start

;_start:     mov rdi, test_format
;            mov rsi, -1
;            call MyPrintf
;
;            mov rax, syscall_of_exit
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
; Exit:  rax   = количество выведенных символов (или -1 при ошибке)
; Destr: rax, rdi, r10
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
; Функция анализирующая форматную строку, разделяя обычные символы и спецификаторы
;
; Entry: rdi   - форматная строка
;        stack - все аргументы в таком порядке (вершина стека->1-ый->2-ой->...)
; Exit:  rax = количество выведенных символов (или -1 при ошибке)
; Destr: rcx, rdx, rsi, rdi
; ----------------------------------------------------------------------------------------
ProcessingStack:
            push rbp
            push r10            ; используем для счетчика символов в буфере
            push r12
            xor r10, r10
            xor r12, r12

            mov rbp, rsp        ;
            add rbp, 32         ; в стеке до первого аргумента лежит еще [r12], [r10]; [старое значение rbp] и [адрес возврата]
.printing_loop:
            cmp byte [rdi], 0       ; выводим символы, пока не встретим терминирующий нулевой байт
            je .exit_ok

            cmp byte [rdi], '%'
            jne .common_symbol

            inc rdi
            cmp byte [rdi], '%'     ;если встретили "%%" в строке, ничего не должны делать и считаем % обычным символом
            je .common_symbol

            call SpecialSymbolProc
            cmp rax, -1             ; обрабатываем ошибку
            je .exit_error
            inc rdi
            jmp .printing_loop
.common_symbol:
            call PrintChar
            inc rdi
            jmp .printing_loop
.exit_ok:
            call FlushBuffer
            mov rax, r12
            pop r12
            pop r10
            pop rbp
            ret
.exit_error:
            mov rax, -1             ;//FIXME там вроде уже единица лежит
            pop r12
            pop r10
            pop rbp
            ret

; -----------------------------------------------------------------------------------------
; Обрабатывает спецификатор после символа '%'
;
; Entry: rdi = адрес в строке, по которому лежит спецификтор
;        rbp = адрес аргумента в стеке
;
; Exit:  rbp += 8, если всё хорошо
;        rax = -1  если произошла ошибка
; Destr: rax, rcx
; ----------------------------------------------------------------------------------------
SpecialSymbolProc:
            cmp byte [rdi], 'a'
            jb processInvalid
            cmp byte [rdi], 'z'
            ja processInvalid

            xor rcx, rcx            ;!!!
            mov cl, [rdi]           ;берем ASCII код символа, лежащего по адресу [rdi]
            mov rcx, [jump_table + 8*(rcx - 'a')]
            jmp rcx
return_here_after_jmp_table:
            add rbp, 8
            ret
processInvalid:
            mov rax, -1
            ret

; ----------------------------------------------------------------------------------------
; НЕ функция, а просто обработчик вывода символа в двоичной системе счисления
;
; Entry: rbp = адрес, по которому лежит число, которое нужно напечатать в двоичной системе счисления
; Exit:
; Destr: rsi, r10, r12
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
; Exit:
; Destr: r10, r12
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
; Exit:
; Destr: rsi, r10, r12
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
; Exit:
; Destr: rsi, r10, r12
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
; Exit:
; Destr: rsi, r10, r12
; ----------------------------------------------------------------------------------------
processHex: push rdi
            mov rdi, rbp
            mov rsi, 16
            call NumberToASCII
            pop rdi
            jmp return_here_after_jmp_table

; ----------------------------------------------------------------------------------------
; НЕ функция, а просто обработчик вывода строки
;
; Entry: rbp = адрес в стеке, содержащий указатель на строку
; Exit:
; Destr: r10, r12
; ----------------------------------------------------------------------------------------
processString:
            push rdi
            mov rdi, [rbp]
            call PrintString
            pop rdi
            jmp return_here_after_jmp_table

; ----------------------------------------------------------------------------------------
; Сохраняет символ в буфер
;
; Entry: rdi = адрес, по которому лежит символ, который нужно напечатать
; Exit:  r10 += 1 (позиция в буфере)
;        r12 += 1 (общее количество выведенных символов)
;
; Destr: ...
; ----------------------------------------------------------------------------------------
PrintChar:
            push rax                            ;//FIXME
            cmp r10, print_buffer_size
            jb .no_flush

            call FlushBuffer

.no_flush:
            inc r12
            mov al, [rdi]
            mov byte [print_buffer + r10], al       ;нельзя 2 операнда в памяти, надо через регистр

            inc r10
            pop rax
            ret

; ----------------------------------------------------------------------------------------
; Выводит буфер в stdout
;
; Entry: r10 = количество символов, которое нужно напечатать
; Exit:  r10 = 0  (количество символов в буфере зануляется)
;
; Destr: ...
; ----------------------------------------------------------------------------------------
FlushBuffer:
            push rdi                    ; сохрянем регистры, которые испортим при syscall
            push rsi
            push rdx
            push rax
            push rcx                    ; //ЭТО ИМЕННО РЕСПЕКТ syscall всегда ломает rcx и r11
            push r11

            mov rax, syscall_of_write   ; syscall of "write"
            mov rsi, print_buffer       ; адрес буфера
            mov rdi, stdout_descr       ; файловый дескриптор stdout
            mov rdx, r10                ; количество символов для вывода
            syscall

            xor r10, r10

            pop r11
            pop rcx
            pop rax
            pop rdx
            pop rsi
            pop rdi

            ret
; ----------------------------------------------------------------------------------------
; Выводит строку, переданную в качестве аргумента к спецификатору %s
;
; Entry: rdi = адрес, по которому лежит строка, которую нужно напечатать
; Exit: r10, r12 увеличиваются на длину строки
;
; Destr: ...
; ----------------------------------------------------------------------------------------
PrintString:
            push rsi
            mov rsi, rdi            ; можно было бы и без использования rsi, т.к. мой PrintChar не меняет rdi,
.print_loop:                        ; но так надёжнее, чтобы не зависеть от того, сохраняет ли PrintChar rdi
            cmp byte [rsi], 0
            je .exit
            mov rdi, rsi
            call PrintChar
            inc rsi
            jmp .print_loop
.exit:
            pop rsi
            ret

; ----------------------------------------------------------------------------------------
; Переводит число в набор ASCII кодов для вывода в консоль
; Entry: rdi = адрес, по которому лежит начало числа
;        rsi = основание системы счисления
; Exit:  r10, r12 увеличиваются на количество выведенных цифр (плюс знак, если отрицательное)
; Destr: rsi
; ----------------------------------------------------------------------------------------
NumberToASCII:
            push rax            ; используется для хранения значения числа
            push rbx            ; используется для адресации к буферу
            push rcx            ; cl используется для сдвига, rcx в конце используется для syscall
            push rdx            ; занулим его перед делением (то есть испортим)
            push rdi            ; испортим его минусом/испортим при syscall
            push r8             ; используется для подсчёта количества разрядов
            push r9             ; используем для хранения сдвига в зависимости от основания СС, кратной двум
            push r11            ; используем для хранения маски  в зависимости от основания СС, кратной двум

            mov eax, [rdi]      ; в eax число, которое нужно напечатать
                                ; важно, что именно в eax, иначе он будет их воспринимать как большие положительные

            cmp eax, 0
            jge .number_is_positive

.number_is_negative:
            mov rdi, minus_symbol
            call PrintChar
            neg eax


.number_is_positive:
            mov rbx, num_buffer + num_buffer_size - 1   ;rbx-конец буфера

            xor r8, r8;                     ; счётчик разрядов (не rcx, так как в rcx будет сдвиг)
            cmp rsi, 10                     ; //ДЕЛО СДЕЛАНО если СС кратна двум, то сдвиг вместо деления и побитовые операции
            jne .powers_of_two_base_process

.ten_base_loop:
            inc r8
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
            mov r11, 1
            jmp .powers_of_two_base_loop
.next_check_1:
            cmp rsi, 8
            jne .next_check_2
            mov r9, 3
            mov r11, 7
            jmp .powers_of_two_base_loop
.next_check_2:
            mov r9, 4
            mov r11, 15

.powers_of_two_base_loop:
            inc r8
            mov rdx, rax
            and rdx, r11
            jmp .digit_ready

.digit_ready:
            mov dl, [array_for_converting_numbers + rdx]
            mov [rbx], dl
            dec rbx
            mov rcx, r9
            shr rax, cl          ; в качестве второго операнда можно использовать только cl/константу
            test rax, rax
            jnz .powers_of_two_base_loop

.output:
            mov rcx, r8                         ; теперь в rcx количество разрядов в числе
            mov rsi, num_buffer + num_buffer_size
            sub rsi, rcx

.printing_loop:
            test rcx, rcx
            jz .done

            mov rdi, rsi
            call PrintChar
            inc rsi
            dec rcx
            jmp .printing_loop
.done:
            pop r11
            pop r9
            pop r8
            pop rdi
            pop rdx
            pop rcx
            pop rbx
            pop rax

            ret


section     .data

syscall_of_write    equ 0x01
syscall_of_exit     equ 0x3C

stdout_descr        equ 1

num_buffer_size     equ 64
num_buffer:         db num_buffer_size dup(0)
print_buffer_size   equ 64
print_buffer:       db print_buffer_size dup(0)

mask_for_converting db 0
minus_symbol:       db '-'
test_format:        db "check = %d", 0xd, 0xa, 0
test_string:        db "test string", 0

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
