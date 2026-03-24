#include "../include/my_io.h"
#include <stdio.h>

int main()
{
    MyPrintf("=== Тест Деда ===\n");
    MyPrintf("\n%d %s %x %d%%%c%b\n", -1, "love", 3802, 100, 33, 126);

    MyPrintf("=== Базовые тесты ===\n");
    MyPrintf("Пустая форматная строка:\n");
    MyPrintf("");
    MyPrintf("Несколько переносов строки:\n\n");
    MyPrintf("Просто текст без спецификаторов: Hello, world!\n");

    MyPrintf("\n=== Тесты спецификаторов ===\n");
    MyPrintf("%c - вывод символа:\n",                  'A');
    MyPrintf("%d - вывод десятичного числа:\n",        42);
    MyPrintf("%o - вывод восьмеричного числа:\n",      42);
    MyPrintf("%x - вывод шестнадцатеричного числа:\n", 42);
    MyPrintf("%b - вывод двоичного числа:\n",          42);
    MyPrintf("%s - вывод строки:\n",                   "Hello, world!");

    MyPrintf("\n=== Отрицательные числа ===\n");
    MyPrintf("%d, %d, %d\n", -1, -255, -32768);
    MyPrintf("%o, %o\n", -1, -8);
    MyPrintf("%x, %x\n", -1, -16);
    MyPrintf("%b, %b\n", -1, -2);

    MyPrintf("\n=== Ноль ===\n");
    MyPrintf("%d %o %x %b\n", 0, 0, 0, 0);

    MyPrintf("\n=== Проверка на обработку ошибок ===\n");
    int ret = 0;
    ret = MyPrintf("Before error %q after error\n");                        //буфер не сбрасываю, поэтому строка не выводится
    MyPrintf("Возвращаемое значение MyPrintf c неверным спецификатором: %d\n", ret);
    int res_off_ru = printf("Дед\n");
    printf("Возвращаемое значение СТАНДАРТНОЙ функции при вызове c аргументом \"Дед\\n\" = %d\n", res_off_ru);
    int res_my_ru = MyPrintf("Дед\n");
    printf("Возвращаемое значение МОЕЙ функции при вызове c аргументом \"Дед\\n\" = %d\n", res_my_ru);

    int res_off_eng = printf("Ded\n");
    printf("Возвращаемое значение СТАНДАРТНОЙ функции при вызове c аргументом \"Ded\\n\" = %d\n", res_off_eng);
    int res_my_eng = MyPrintf("Ded\n");
    printf("Возвращаемое значение МОЕЙ функции при вызове c аргументом \"Ded\\n\" = %d\n", res_my_eng);

    MyPrintf("\n=== Проверка передачи аргументов ===\n");
    MyPrintf(" %d %c %s %x %o %b\n", 100, 'Z', "тест", 0xABC, 0777, 0b1010);
    MyPrintf("Передача через регистры + стек %d %d %d %d %d %d %d %d\n", 1, 2, 3, 4, 5, 6, 7, 8);

    MyPrintf("\n=== Двойной процент ===\n");
    MyPrintf("100%% правильно\n");
    MyPrintf("Процент в конце: %%\n");
    MyPrintf("%%d должен напечатать %%d прям так буквально\n");
    MyPrintf("\n=== Пустая строка в аргументе ===\n");
    MyPrintf("Пустота: '%s'\n", "");
    //MyPrintf("Нулевой указатель %s\n", (char*)0);   //Моя прога не поддерживает обработку таког
    MyPrintf("\n=== Тест сбрасывания буфера ===\n");
    MyPrintf("Я так написал, чтобы длина этой строки ровно 64 символа!!!!!!!!!");
    MyPrintf("1234567890123456789012345678901234567890123456789012345678901234567890\n"); //строка длиннее 64 символо
    MyPrintf("\n=== Граничные значения ===\n");
    MyPrintf("%d, %d, %d\n", 2147483647, -2147483648, 0);  // int min/max
    MyPrintf("%x, %x\n", 0xFFFFFFFF, 0x7FFFFFFF);
    MyPrintf("%b\n", 0b11111111111111111111111111111111);

    MyPrintf("\n=== Ещё тесты на числа ===\n");
    MyPrintf("Result: %d + %d = %d\n", 5, 3, 5+3);
    MyPrintf("Char: %c, Hex: %x, Oct: %o, Bin: %b\n", 'X', 255, 255, 255);

    return 0;
}
