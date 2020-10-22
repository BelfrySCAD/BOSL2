#!/bin/bash

lib_comment_lines=$(grep '^// ' *.scad | wc -l)
lib_code_lines=$(grep '^ *[^ /]' *.scad | wc -l)
script_code_lines=$(grep '^ *[^ /]' scripts/*.sh scripts/*.py | wc -l)
example_code_lines=$(grep '^ *[^ /]' examples/*.scad | wc -l)
test_code_lines=$(grep '^ *[^ /]' tests/*.scad | wc -l)
tutorial_lines=$(grep '^ *[^ /]' tutorials/*.md | wc -l)

y=$(printf "%06d" 13)

printf "Documentation Lines : %6d\n" $(($lib_comment_lines+$tutorial_lines))
printf "Example Code Lines  : %6d\n" $example_code_lines
printf "Library Code Lines  : %6d\n" $lib_code_lines
printf "Support Script Lines: %6d\n" $script_code_lines
printf "Test Code Lines     : %6d\n" $test_code_lines

