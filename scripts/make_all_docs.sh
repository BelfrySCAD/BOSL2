#!/bin/bash

if [[ $# > 0 ]]; then
    PREVIEW_LIBS="$@"
else
    PREVIEW_LIBS="common errors attachments math arrays vectors affine coords geometry triangulation quaternions hull constants edges transforms primitives shapes masks shapes2d paths beziers roundcorners walls metric_screws threading involute_gears sliders joiners linear_bearings nema_steppers wiring phillips_drive torx_drive polyhedra debug"
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
    rm -f images/$lib/*.png images/$lib/*.gif
    # echo ../scripts/docs_gen.py ../$lib.scad -o $lib.scad.md -c -i -I images/$lib/
    echo "$lib.scad"
    ../scripts/docs_gen.py ../$lib.scad -o $lib.scad.md -c -i -I images/$lib/ || exit 1
    open -a Typora $lib.scad.md
done


