#!/bin/sh

awk '
    /^module/{
        m=1
        split($2,narr,"(")
        module=narr[1]"()"
    }
    /^function/{
        m=0
        module=""
    }
    /[^=] *assert\(/{
        if(m) {
            if(fname!=FILENAME) {
                fname=FILENAME
                print "File",fname
            }
            if(prevmodule!=module) {
                prevmodule=module
                print "  Module",module
            }
            assertline=$0
            sub(/^ */, "", assertline)
            print "    ",FNR,":",assertline
        }
    }
' *.scad

