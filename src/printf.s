; nasm -f elf64 -l 1-nasm.lst 1-nasm.s  ;  ld -s -o 1-nasm 1-nasm.o

section .text

global _start

_start:     mov rdi, test_format
            mov rsi, '!'
            call MyPrintf

            mov rax, 0x3C
            xor rdi, rdi
            syscall

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
; Entry: [rdi] = спецификтор
;        rbp   = аргумент
;
; Exit:  rbp += 8, если всё хорошо
;                  если произошла ошибка //FIXME обрабатывать ошибки
; Destr: rcx
; ----------------------------------------------------------------------------------------
SpecialSymbolProc:
            cmp byte [rdi], 'a'
            jb process_invalid
            cmp byte [rdi], 'z'
            ja process_invalid

            xor rcx, rcx          ;!!!
            mov cl, [rdi]
            mov rcx, [jump_table - 8*('a' - rcx)]
            jmp rcx
return_here_after_jmp_table:
            add rbp, 8
            ret
process_invalid:                ;//FIXME обрабатывать ошибки
            ret


ProcessBinary:                  ;//TODO
            jmp return_here_after_jmp_table

; ----------------------------------------------------------------------------------------
; НЕ функция, а просто обработчик
;
; Entry: rbp = адрес, по которому лежит символ, который нужно напечатать
; Exit:  None
; Destr:
; ----------------------------------------------------------------------------------------
ProcessChar:
            push rdi
            mov rdi, rbp
            call PrintChar
            pop rdi

            jmp return_here_after_jmp_table

ProcessDecimal:               ;//TODO
            jmp return_here_after_jmp_table

ProcessOct:                   ;//TODO
            jmp return_here_after_jmp_table

ProcessHex:                   ;//TODO
            jmp return_here_after_jmp_table

ProcessString:                ;//TODO
            jmp return_here_after_jmp_table

ProcessInvalid:               ;//TODO
            jmp return_here_after_jmp_table

; ----------------------------------------------------------------------------------------
; Выводит символ в stdout
;
; Entry: rdi = адрес, по которому лежит символ, который нужно напечатать
; Exit:  ...
;
; Destr: ...
; ----------------------------------------------------------------------------------------
PrintChar:
            push rdi
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

section     .data

test_format db "check = %c", 0xd, 0xa, 0
test_string db "test string", 0
jump_table:
            dq ProcessInvalid ; a
            dq ProcessBinary  ; b
            dq ProcessChar    ; c
            dq ProcessDecimal ; d
            dq ProcessInvalid ; e
            dq ProcessInvalid ; f
            dq ProcessInvalid ; g
            dq ProcessInvalid ; h
            dq ProcessInvalid ; i
            dq ProcessInvalid ; j
            dq ProcessInvalid ; k
            dq ProcessInvalid ; l
            dq ProcessInvalid ; m
            dq ProcessInvalid ; n
            dq ProcessOct     ; o
            dq ProcessInvalid ; p
            dq ProcessInvalid ; q
            dq ProcessInvalid ; r
            dq ProcessString  ; s
            dq ProcessInvalid ; t
            dq ProcessInvalid ; u
            dq ProcessInvalid ; v
            dq ProcessInvalid ; w
            dq ProcessHex     ; x
            dq ProcessInvalid ; y
            dq ProcessInvalid ; z
