#!/bin/bash

if [ "$(uname -s)" != "Darwin" ]; then
    OPENSCAD=openscad
else
    OPENSCAD=/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD
fi

OUTCODE=0
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
	OUTCODE=-1
    fi
    rm -f out.echo
done
exit $OUTCODE

