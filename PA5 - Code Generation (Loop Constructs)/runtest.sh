#!/bin/bash

make clean;
./runme inputs/step4_testcase.micro output.out;
g++ tinyNew.C -o tiny;
echo "******************Expected*******************";
./tiny outputs/step4_testcase.out; # output expected
echo "*******************Actual*******************";
./tiny output.out; # output by my prog

