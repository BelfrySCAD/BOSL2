#!/bin/bash

INFILES=("$@")
if (( ${#INFILES[@]} == 0 )); then
    INFILES=(tests/test_*.scadtest)
fi

openscad-test "${INFILES[@]}"
