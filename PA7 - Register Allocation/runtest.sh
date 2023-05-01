#!/bin/bash

# make clean;
# make compiler;
./runme inputs/2.micro output.out;
g++ tiny4regs.C -o tiny;
# echo "******************Expected*******************";
# ./tiny outputs/test_expr.out; # output expected
echo "*******************Output*******************";
./tiny output.out; # output by my prog

