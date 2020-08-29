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
    cols=4
    TMPFILE=$(mktemp -t $(basename $0).XXXXXX) || exit 1
    cat >>$TMPFILE
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
    while [[ $n < $maxcols ]] ; do
        hdrln1+=' | &nbsp;'
        hdrln2+=' |:------'
        n=$(($n+1))
    done
    hdrln1+=' |'
    hdrln2+=' |'
    n=0
    while [[ $n < $maxrows ]] ; do
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
    while [[ $n < $maxrows ]] ; do
        echo "| ${lines[$n]} |"
        n=$(($n+1))
    done
}

function mkconstindex
{
    sed 's/([^)]*)//g' | sed 's/[^a-zA-Z0-9_.:$]//g' | awk -F ':' '{printf "[%s](%s#%s)\n", $3, $1, $3}'
}

function mkotherindex
{
    sed 's/([^)]*)//g' | sed 's/[^a-zA-Z0-9_.:$]//g' | awk -F ':' '{printf "[%s()](%s#%s)\n", $3, $1, $3}'
}

CHEAT_FILES=$(grep '^include' std.scad | sed 's/^.*<\([a-zA-Z0-9.]*\)>/\1/'|grep -v 'version.scad')

(
    echo '## Belfry OpenScad Library Cheat Sheet'
    echo
    echo '( [Alphabetic Index](Index) )'
    echo
    for f in $CHEAT_FILES ; do
        #echo "### $f"
        (
            egrep -H 'Constant: ' $f | mkconstindex
            egrep -H 'Function: |Function&Module: |Module: ' $f | mkotherindex
        ) | columnize $f
        echo
    done
) > BOSL2.wiki/CheatSheet.md

