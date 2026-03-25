#!/bin/bash

nasm -f elf64 src/experiment.s -o experiment.o
g++ -no-pie experiment.o -o experiment
