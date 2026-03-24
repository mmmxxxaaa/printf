#!/bin/bash

nasm -f elf64 -o printf.o printf.s
g++ -fno-pie -c main.cpp -o main.o -g
g++ -no-pie main.o printf.o -o program_tested -g
