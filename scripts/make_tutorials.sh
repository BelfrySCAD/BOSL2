#!/bin/bash

DISPMD=0
GEN_ARGS=()
FILES=()
for opt in "$@" ; do
  case "$opt" in
    -f ) GEN_ARGS+=(-f) ;;
    -d ) DISPMD=1 ;;
    -* ) echo "Unknown option $opt" >&2; exit 1 ;;
    * ) FILES+=("$opt") ;;
  esac
done

if (( ${#FILES[@]} == 0 )); then
    FILES=(Shapes2d Shapes3d Transforms Distributors Mutators Attachments Paths FractalTree)
fi

# Try to cd to the BOSL2.wiki directory if run from the BOSL2 root
if [[ "$(basename "$PWD")" != "BOSL2.wiki" ]]; then
  if ! cd BOSL2.wiki; then
    echo "BOSL2.wiki directory not found, try running from the BOSL2 or BOSL2/BOSL2.wiki directory" >&2
    exit 1
  fi
fi

rm -f tmp_*.scad
for base in "${FILES[@]}"; do
    base="$(basename "$base" .md)"
    mkdir -p images/tutorials
    rm -f "images/tutorials/${base}"_*.png "images/tutorials/${base}"_*.gif
    echo "${base}.md"
    ../scripts/tutorial_gen.py "../tutorials/${base}.md" -o "Tutorial-${base}.md" "${GEN_ARGS[@]}" -I images/tutorials/ || exit 1
    if (( DISPMD )); then
        open -a Typora "Tutorial-${base}.md"
    fi
done


