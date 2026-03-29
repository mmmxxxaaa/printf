section .text

extern printf

global MyPrintf
default rel

%macro  PRINT_NUMBER 2
        push rdi
        mov rdi, rbp
        mov rsi, %1
        %2
        call NumberToASCII
        pop rdi
%endmacro

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
                        ;rsp = ...F8 (был положен адрес возврата)
            pop r14     ;rsp - ...00 (сохранили адрес возврата из стека)
            push r9     ;rsp = ...F8
            push r8     ;rsp = ...F0
            push rcx    ;rsp = ...E8
            push rdx    ;rsp = ...E0
            push rsi    ;rsp = ...D8
            push rdi    ;rsp = ...D0

            call ProcessingStack

            pop rdi     ;rsp = ...D8
            pop rsi     ;rsp = ...E0
            pop rdx     ;rsp = ...E8
            pop rcx     ;rsp = ...F0
            pop r8      ;rsp = ...F8
            pop r9      ;rsp - ...00 (ПОСЛЕ ПОСЛЕДНЕГО ПУША ВЕРНУЛИСЬ В ИСХОДНОЕ СОСТОЯНИЕ СТЕКА)
                        ;оно кратно 16 => выравнивать не нужно

            xor rax, rax
            call printf wrt ..plt

            push r14

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
            push r10                ; используем для счетчика символов в буфере
            push r12
            xor r10, r10
            xor r12, r12

            mov rbp, rsp
            add rbp, 40             ; в стеке до первого аргумента лежит еще [сохраненный rdi] [r12], [r10]; [старое значение rbp] и [адрес возврата]
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
            mov rax, -1
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
; Destr: rax, rcx, rdx
; ----------------------------------------------------------------------------------------
SpecialSymbolProc:
            xor rcx, rcx            ;!!!
            mov cl, [rdi]           ;берем ASCII код символа, лежащего по адресу [rdi]

            cmp cl, 'b'
            jb processInvalid
            cmp cl, 'x'
            ja processInvalid

            lea rdx, [jump_table]
            mov rcx, [rdx + 8*(rcx-'b')]
            add rdx, rcx
            jmp rdx
return_here_after_jmp_table:
            add rbp, 8
            ret
processInvalid:
            mov rax, -1
            ret

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
; Обработчик модификатора длины 'l' (long). Если следующий символ один из 'd', 'b', 'o', 'x',
; то выводит 64-битное число в соответствующей системе счисления. Иначе вызывает обработку ошибки
;
; Entry: rdi = адрес символа 'l' в форматной строке
;        rbp = адрес текущего аргумента в стеке (указывает на 64-битное значение)
;
; Exit:  при успехе rdi смещается на два символа (за спецификатор),
;        rbp увеличивается на 8 (переход к следующему аргументу)
;        при ошибке возвращается -1 через processInvalid
;
; Destr: rax, rcx, rdx, r10, r12 (через NumberToASCII и PrintChar)
; ----------------------------------------------------------------------------------------
processLSpecifier:
            inc rdi
            ;push rdi                ; сохраняем после увеличения на 1

            xor rcx, rcx            ;!!!
            mov cl, [rdi]           ;берем ASCII код символа, лежащего по адресу [rdi]

            cmp cl, 'b'
            jb miniHandleInvalid
            cmp cl, 'x'
            ja miniHandleInvalid

            lea rdx, [mini_jump_table]
            mov rcx, [rdx + 8*(rcx - 'b')]
            add rdx, rcx
            jmp rdx
return_here_after_mini_jmp_table:
            ;pop rdi
            jmp return_here_after_jmp_table

miniHandleBinary:
            PRINT_NUMBER 2, stc
            jmp return_here_after_mini_jmp_table

miniHandleDecimal:
            PRINT_NUMBER 10, stc
            jmp return_here_after_mini_jmp_table

miniHandleOct:
            PRINT_NUMBER 8, stc
            jmp return_here_after_mini_jmp_table

miniHandleHex:
            PRINT_NUMBER 16, stc
            jmp return_here_after_mini_jmp_table

miniHandleInvalid:
            ;pop rdi
            jmp processInvalid

; ----------------------------------------------------------------------------------------
; НЕ функция, а просто обработчик вывода символа в двоичной системе счисления
;
; Entry: rbp = адрес, по которому лежит число, которое нужно напечатать в двоичной системе счисления
; Exit:
; Destr: rsi, r10, r12
; ----------------------------------------------------------------------------------------
processBinary:
            PRINT_NUMBER 2, clc
            jmp return_here_after_jmp_table

; ----------------------------------------------------------------------------------------
; НЕ функция, а просто обработчик вывода символа в десятичной системе счисления
;
; Entry: rbp = адрес, по которому лежит число, которое нужно напечатать в десятичной системе счисления
; Exit:
; Destr: rsi, r10, r12
; ----------------------------------------------------------------------------------------
processDecimal:
            PRINT_NUMBER 10, clc
            jmp return_here_after_jmp_table

; ----------------------------------------------------------------------------------------
; НЕ функция, а просто обработчик вывода символа в восьмеричной системе счисления
;
; Entry: rbp = адрес, по которому лежит число, которое нужно напечатать в восьмеричной системе счисления
; Exit:
; Destr: rsi, r10, r12
; ----------------------------------------------------------------------------------------
processOct:
            push rdi
            mov rdi, rbp
            mov rsi, 8
            clc
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
processHex:
            PRINT_NUMBER 16, clc
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
            push rax
            push r9
            cmp r10, print_buffer_size
            jb .no_flush

            call FlushBuffer
.no_flush:
            inc r12
            mov al, [rdi]
            lea r9, [print_buffer]
            mov byte [r9 + r10], al       ;нельзя 2 операнда в памяти, надо через регистр

            inc r10
            pop r9
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
            push rbp
            mov rbp, rsp

            and rsp, -16                ; делаем жёсткое выравнивание стека

            push rdi
            push rsi
            push rdx
            push rax
            push rcx
            push r11                    ; 6 * 8 = 48 - кратно 16, выравнивание сохраняется

            mov rax, syscall_of_write   ; syscall of "write"
            mov rdi, stdout_descr       ; файловый дескриптор stdout
            lea rsi, [print_buffer]     ; адрес буфера
            mov rdx, r10                ; количество символов для вывода
            syscall                     ; //ЭТО ИМЕННО РЕСПЕКТ syscall всегда ломает rcx и r11

            xor r10, r10

            pop r11
            pop rcx
            pop rax
            pop rdx
            pop rsi
            pop rdi

            mov rbp, rsp
            pop rbp
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
;        CF  = 0 работаем с 32-битным числом
;        CF  = 1 работаем с 64-битным числом
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
            push r13            ; используем для хранения базы таблицы
            lea r13, [array_for_converting_numbers]

            jc .working_with_64
            mov eax, [rdi]      ; в eax число, которое нужно напечатать
                                ; важно, что именно в eax, иначе он будет их воспринимать как большие положительные
            cmp rsi, 10
            je .signed_32
            mov eax, eax        ; беззнаковое расширение eax до rax
            jmp .check_sign
.signed_32:
            cdqe                ; используем знаковое расширение eax до rax
            jmp .check_sign

.working_with_64:
            mov rax, [rdi]

.check_sign:
            cmp rax, 0
            jge .number_is_positive

.number_is_negative:
            cmp rsi, 10
            jne .number_is_positive          ; если основание СС не 10, то минус не выводим
            lea rdi, [minus_symbol]
            call PrintChar
            neg rax

.number_is_positive:
            lea rbx, [num_buffer + num_buffer_size - 1]   ;rbx-конец буфера

            xor r8, r8;                     ; счётчик разрядов (не rcx, так как в rcx будет сдвиг)
            cmp rsi, 10                     ; //ДЕЛО СДЕЛАНО если СС кратна двум, то сдвиг вместо деления и побитовые операции
            jne .powers_of_two_base_process
.ten_base_loop:
            inc r8
            xor rdx, rdx                    ; div считает делимым большое 128-битное число [rdx][rax]
            div rsi
            mov dl, [r13 + rdx]
            mov [rbx], dl
            dec rbx                         ; декрементируем, так как идем справа налево по буферу
            test rax, rax
            jnz .ten_base_loop              ; продолжаем до тех пор, пока не получим ноль
            jmp .output

.powers_of_two_base_process:
            cmp rsi, 2
            jne .check_for_oct
            mov r9, shift_for_binary
            mov r11, mask_for_binary
            jmp .powers_of_two_base_loop
.check_for_oct:
            cmp rsi, 8
            jne .check_for_hex
            mov r9, shift_for_oct
            mov r11, mask_for_oct
            jmp .powers_of_two_base_loop
.check_for_hex:
            mov r9, shift_for_hex
            mov r11, mask_for_hex
.powers_of_two_base_loop:
            inc r8
            mov rdx, rax
            and rdx, r11

            mov dl, [r13 + rdx]
            mov [rbx], dl
            dec rbx
            mov rcx, r9
            shr rax, cl                         ; в качестве второго операнда можно использовать только cl/константу
            test rax, rax
            jnz .powers_of_two_base_loop

.output:
            mov rcx, r8                         ; теперь в rcx количество разрядов в числе
            lea rsi, [num_buffer + num_buffer_size]
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
            pop r13
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

shift_for_binary    equ 1
mask_for_binary     equ 1

shift_for_oct       equ 3
mask_for_oct        equ 7

shift_for_hex       equ 4
mask_for_hex        equ 15

syscall_of_write    equ 0x01

stdout_descr        equ 1

num_buffer_size     equ 64
num_buffer:         db num_buffer_size dup(0)
print_buffer_size   equ 64
print_buffer:       db print_buffer_size dup(0)

minus_symbol:       db '-'

array_for_converting_numbers: db "0123456789ABCDEF"
jump_table:
            dq processBinary     - jump_table  ; b
            dq processChar       - jump_table  ; c
            dq processDecimal    - jump_table  ; d
            times ('k' - 'e' + 1)   dq processInvalid - jump_table
            dq processLSpecifier - jump_table  ; l
            times ('n' - 'm' + 1)   dq processInvalid - jump_table
            dq processOct        - jump_table  ; o
            times ('r' - 'p' + 1)   dq processInvalid - jump_table
            dq processString     - jump_table  ; s
            times ('w' - 't' + 1)   dq processInvalid - jump_table
            dq processHex        - jump_table  ; x

mini_jump_table:
            dq miniHandleBinary  - mini_jump_table ; b
            dq miniHandleInvalid - mini_jump_table ; c
            dq miniHandleDecimal - mini_jump_table ; d
            times ('n' - 'e' + 1) dq miniHandleInvalid - mini_jump_table
            dq miniHandleOct     - mini_jump_table ; o
            times ('w' - 'p' + 1) dq miniHandleInvalid - mini_jump_table
            dq miniHandleHex     - mini_jump_table ; x
