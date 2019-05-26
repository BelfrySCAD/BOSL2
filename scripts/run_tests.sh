#!/bin/bash

OPENSCAD=/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD

for testscript in tests/test_*.scad ; do
    echo -n "$testscript: "
    ${OPENSCAD} -o .off --hardwarnings --check-parameters true --check-parameter-ranges true $testscript >>/dev/null 2>&1
    [ $? != 0 ] && echo "PASS" || echo "FAIL!"
done

