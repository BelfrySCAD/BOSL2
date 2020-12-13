#!/bin/bash

FORCED=""
IMGGEN=""
TESTONLY=""
FILES=""
DISPMD=""
for opt in "$@" ; do
  case $opt in
    -f ) FORCED=$opt ;;
    -i ) IMGGEN=$opt ;;
    -t ) TESTONLY=$opt ;;
    -d ) DISPMD=$opt ;;
    -* ) echo "Unknown option $opt"; exit -1 ;;
    * ) FILES="$FILES $opt" ;;
  esac
done

if [[ "$FILES" != "" ]]; then
    PREVIEW_LIBS="$FILES"
else
    PREVIEW_LIBS=$(git ls-files | grep '\.scad$' | grep -v / | grep -v -f .nodocsfiles)
fi

dir="$(basename $PWD)"
if [ "$dir" = "BOSL2" ]; then
    cd BOSL2.wiki
elif [ "$dir" != "BOSL2.wiki" ]; then
    echo "Must run this script from the BOSL2 or BOSL2/BOSL2.wiki directories."
    exit 1
fi

rm -f tmpscad*.scad
for lib in $PREVIEW_LIBS; do
    lib="$(basename $lib .scad)"
    mkdir -p images/$lib
    if [ "$IMGGEN" != "" -a "$TESTONLY" != "" ]; then
        rm -f images/$lib/*.png images/$lib/*.gif
    fi
    echo "$lib.scad"
    ../scripts/docs_gen.py ../$lib.scad -o $lib.scad.md -c $IMGGEN $FORCED $TESTONLY -I images/$lib/ || exit 1
    if [ "$DISPMD" != "" ]; then
        open -a Typora $lib.scad.md
    fi
done


