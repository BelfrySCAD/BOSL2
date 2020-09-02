#!/bin/bash


function ucase
{
    echo "$1" | tr '[:lower:]' '[:upper:]'
}

function lcase
{
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

function columnize
{
    cols=$2
    TMPFILE=$(mktemp -t $(basename $0).XXXXXX) || exit 1
    cat >>$TMPFILE
    if [[ $(wc -l $TMPFILE | awk '{print $1}') -gt 1 ]] ; then
        totcnt=$(wc -l $TMPFILE | awk '{print $1}')
        maxrows=$((($totcnt+$cols-1)/$cols))
        maxcols=$cols
        if [[ $maxcols -gt $totcnt ]] ; then
            maxcols=$totcnt
        fi
        cnt=0
        hdrln1="| $(ucase $1)  "
        hdrln2='|:-----'
        n=1
        while [[ $n -lt $maxcols ]] ; do
            hdrln1+=' | &nbsp;'
            hdrln2+=' |:------'
            n=$(($n+1))
        done
        hdrln1+=' |'
        hdrln2+=' |'
        n=0
        while [[ $n -lt $maxrows ]] ; do
            lines[$n]=""
            n=$(($n+1))
        done
        col=0
        while IFS= read -r line; do
            if [[ $col != 0 ]] ; then
                lines[$cnt]+=" | "
            fi
            lines[$cnt]+="$line"
            cnt=$(($cnt+1))
            if [[ $cnt = $maxrows ]] ; then
                cnt=0
                col=$(($col+1))
            fi
        done <$TMPFILE
        rm -f $TMPFILE

        echo
        echo $hdrln1
        echo $hdrln2
        n=0
        while [[ $n -lt $maxrows ]] ; do
            echo "| ${lines[$n]} |"
            n=$(($n+1))
        done
    fi
}

function mkconstindex
{
    sed 's/([^)]*)//g' | sed 's/[^a-zA-Z0-9_.:$]//g' | awk -F ':' '{printf "[%s](%s#%s)\n", $3, $1, $3}'
}

function mkconstindex2
{
    sed 's/ *=.*$//' | sed 's/[^a-zA-Z0-9_.:$]//g' | awk -F ':' '{printf "[%s](%s#%s)\n", $2, $1, $2}'
}

function mkotherindex
{
    sed 's/([^)]*)//g' | sed 's/[^a-zA-Z0-9_.:$]//g' | awk -F ':' '{printf "[%s()](%s#%s)\n", $3, $1, $3}'
}

CHEAT_FILES=$(grep '^include' std.scad | sed 's/^.*<\([a-zA-Z0-9.]*\)>/\1/' | grep -v 'version.scad' | grep -v 'primitives.scad')

(
    echo '## Belfry OpenScad Library Cheat Sheet'
    echo
    echo '( [Alphabetic Index](Index) )'
    echo
    (
        grep -H '// Constant: ' $CHEAT_FILES | mkconstindex
        grep -H '^[A-Z$][A-Z0-9_]* *=.*//' $CHEAT_FILES | mkconstindex2
    ) | sort -u | columnize 'Constants' 6
    for f in $CHEAT_FILES ; do
        egrep -H '// Function: |// Function&Module: |// Module: ' $f | mkotherindex | columnize "[$f]($f)" 4
        echo
    done
) > BOSL2.wiki/CheatSheet.md

