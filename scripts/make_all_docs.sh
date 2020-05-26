#!/bin/bash

FORCED=""
IMGGEN=""
FILES=""
DISPMD=""
for opt in "$@" ; do
  case $opt in
    -f ) FORCED=$opt ;;
    -i ) IMGGEN=$opt ;;
    -d ) DISPMD=$opt ;;
    -* ) echo "Unknown option $opt"; exit -1 ;;
    * ) FILES="$FILES $opt" ;;
  esac
done

if [[ "$FILES" != "" ]]; then
    PREVIEW_LIBS="$FILES"
else
    PREVIEW_LIBS="affine arrays attachments beziers bottlecaps common constants coords cubetruss debug distributors edges errors geometry hingesnaps hull involute_gears joiners knurling linear_bearings masks math metric_screws mutators nema_steppers partitions paths phillips_drive polyhedra primitives quaternions queues regions rounding screws shapes shapes2d skin sliders stacks strings structs threading torx_drive transforms triangulation vectors version vnf walls wiring"
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
    if [ "$IMGGEN" != "" ]; then
        rm -f images/$lib/*.png images/$lib/*.gif
    fi
    echo "$lib.scad"
    ../scripts/docs_gen.py ../$lib.scad -o $lib.scad.md -c $IMGGEN $FORCED -I images/$lib/ || exit 1
    if [ "$DISPMD" != "" ]; then
        open -a Typora $lib.scad.md
    fi
done


