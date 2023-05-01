#!/bin/bash

make clean;
make compiler;
./runme inputs/fibonacci2.micro output.out;
g++ tinyNew.C -o tiny;
echo "******************Expected*******************";
./tiny outputs/fibonacci2.out; # output expected
echo "*******************Actual*******************";
./tiny output.out; # output by my prog

