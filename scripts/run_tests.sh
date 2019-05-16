#!/bin/bash

OPENSCAD=/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD

for testscript in tests/test_*.scad ; do
    ${OPENSCAD} -o .off --hardwarnings --check-parameters true --check-parameter-ranges true $testscript
done

