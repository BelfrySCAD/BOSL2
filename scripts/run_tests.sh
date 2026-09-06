#!/bin/bash

# Runs the .scadtest suite. `belfryscad --test` is a drop-in replacement for
# openscad-test -- same TOML format, same output, same exit code -- but runs
# the scripts in-process instead of launching the OpenSCAD binary once per
# test, which makes it several times faster and removes the dependency on a
# downloaded OpenSCAD AppImage.
#
# Falls back to openscad-test when belfryscad is not installed, so a
# checkout without it still tests the way it always did.

INFILES=("$@")
if (( ${#INFILES[@]} == 0 )); then
    INFILES=(tests/test_*.scadtest)
fi

if command -v belfryscad > /dev/null 2>&1; then
    belfryscad --test "${INFILES[@]}"
else
    echo "belfryscad not found; falling back to openscad-test." >&2
    openscad-test "${INFILES[@]}"
fi
