#!/bin/bash


nasm -g -f elf64 -o printf.o src/printf.s
g++ --pie -c src/main.cpp -o main.o -g
g++ -pie main.o printf.o -o program_tested -g
