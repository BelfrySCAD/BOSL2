#!/bin/bash

OPENSCAD=/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD

for testscript in tests/test_*.scad ; do
    repname="$(basename $testscript|sed 's/^test_//')"
    ${OPENSCAD} -o out.echo --hardwarnings --check-parameters true --check-parameter-ranges true $testscript 2>&1
    res=$(cat out.echo)
    if [ "$res" = "" ] ; then
	echo "$repname: PASS"
    else
	echo "$repname: FAIL!"
	cat out.echo
	echo
    fi
    rm -f out.echo
done

