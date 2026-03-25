extern printf

section .text

global main

main:
    push rbp
    mov  rbp, rsp                   ; (***) зафиксировали значение rsp в rbp

    mov  rdi, format_string         ; 1-й аргумент: форматная строка
    mov  rsi, string                ; 2-й аргумент:
    mov  rdx, 42                    ; 3-й аргумент: число 42
    mov  rcx, 'A'                   ; 4-й аргумент: символ 'A'
    mov  r8,  0xFAFADADA            ; 5-й аргумент: шестнадцатеричное число
    mov  r9,  100                   ; 6-й аргумент

    ; Сейчас стек смещен на 8 байт от начала main (8 байт rbp)
    ; Потом будет еще 2 пуша (16 байт)
    ; (Стандарт System V ABI требует, чтобы перед вызовом функции указатель стека rsp был кратен 16 байтам)
    ; Однако если мы сначала запушим аргументы, и только потом выровняем стек, то со стека будет браться мусорное
    ; значение в качестве аргумента
    sub rsp, 8

    push 300                        ; 8-й аргумент
    push 200                        ; 7-й аргумент

    xor  rax, rax                   ; rax = 0 (нет аргументов с плавающей точкой)
    call printf

    add  rsp, 24                    ; rsp изменен на 24 байта после (***)

    mov  rsp, rbp
    pop  rbp
    xor  rax, rax                   ; вернем ноль
    ret


section .data
    format_string db "Hello there I'm from %s! Число: %d, символ: %c, hex: %x, extra: %d, extra2: %d, extra3: %d", 10, 0
    string db "assembler", 0
