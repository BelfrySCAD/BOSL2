#!/bin/bash

if [ "$(uname -s)" != "Darwin" ]; then
    OPENSCAD=openscad
else
    OPENSCAD=/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD
fi

if [ "$*" != "" ] ; then
    INFILES="$*"
else
    INFILES="tests/test_*.scad"
fi

OUTCODE=0
for testscript in $INFILES ; do
    repname="$(basename $testscript | sed 's/^test_//')"
    testfile="tests/test_$repname"
    if [ -f "$testfile" ] ; then
        ${OPENSCAD} -o out.echo --hardwarnings --check-parameters true --check-parameter-ranges true $testfile 2>&1
        retcode=$?
        res=$(cat out.echo)
        if [ $retcode -eq 0 ] && [ "$res" = "" ] ; then
            echo "$repname: PASS"
        else
            echo "$repname: FAIL!"
            cat out.echo
            echo
            OUTCODE=-1
        fi
        rm -f out.echo
    fi
done
exit $OUTCODE

