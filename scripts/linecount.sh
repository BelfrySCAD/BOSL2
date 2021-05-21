#!/bin/bash

lib_comment_lines=$(cat -- *.scad | grep -c '^// ')
tutorial_lines=$(cat tutorials/*.md | grep -c '^ *[^ /]')

printf '%-20s: %6d\n' \
  'Documentation Lines'  "$(( lib_comment_lines + tutorial_lines ))" \
  'Example Code Lines'   "$(cat examples/*.scad | grep -c '^ *[^ /]')" \
  'Library Code Lines'   "$(cat -- *.scad | grep -c '^ *[^ /]')" \
  'Support Script Lines' "$(cat scripts/*.sh scripts/*.py | grep -c '^ *[^ /]')" \
  'Test Code Lines'      "$(cat tests/*.scad | grep -c '^ *[^ /]')"

