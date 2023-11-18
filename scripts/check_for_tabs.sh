#!/bin/bash

if grep -H -n -P '\t' *.scad ; then
    echo "Tabs found in source code." 2>&1
    exit 1
fi
exit 0


