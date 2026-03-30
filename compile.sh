#!/bin/bash


nasm -g -f elf64 -o printf.o src/printf.s
g++ -c src/main.cpp -o main.o -g
g++ main.o printf.o -o program_tested -g
