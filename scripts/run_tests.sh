#!/bin/bash

OPENSCAD=/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD

for testscript in tests/test_*.scad ; do
    repname="$(basename $testscript|sed 's/^test_//')"
    ${OPENSCAD} -o .off --hardwarnings --check-parameters true --check-parameter-ranges true $testscript 2>&1 && echo "$repname: PASS" || echo -e "$repname: FAIL!\n"
done

