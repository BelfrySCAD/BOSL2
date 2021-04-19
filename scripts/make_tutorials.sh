#!/bin/bash

FORCED=""
FILES=""
DISPMD=""
for opt in "$@" ; do
  case $opt in
    -f ) FORCED=$opt ;;
    -d ) DISPMD=$opt ;;
    -* ) echo "Unknown option $opt"; exit -1 ;;
    * ) FILES="$FILES $opt" ;;
  esac
done

if [[ "$FILES" != "" ]]; then
    PREVIEW_LIBS="$FILES"
else
    PREVIEW_LIBS="Shapes2d Shapes3d Transforms Distributors Mutators Attachments Paths FractalTree"
fi

dir="$(basename $PWD)"
if [ "$dir" = "BOSL2" ]; then
    cd BOSL2.wiki
elif [ "$dir" != "BOSL2.wiki" ]; then
    echo "Must run this script from the BOSL2 or BOSL2/BOSL2.wiki directories."
    exit 1
fi

rm -f tmp_*.scad
for base in $PREVIEW_LIBS; do
    base="$(basename $base .md)"
    mkdir -p images/tutorials
    rm -f images/tutorials/${base}_*.png images/tutorials/${base}_*.gif
    echo "$base.md"
    ../scripts/tutorial_gen.py ../tutorials/$base.md -o Tutorial-$base.md $FORCED -I images/tutorials/ || exit 1
    if [ "$DISPMD" != "" ]; then
        open -a Typora Tutorial-$base.md
    fi
done


