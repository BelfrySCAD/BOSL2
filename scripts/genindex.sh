#!/bin/bash


function ucase
{
    echo "$1" | tr '[:lower:]' '[:upper:]'
}

function lcase
{
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

function mkindex
{
    TMPFILE=$(mktemp -t $(basename $0)) || exit 1
    sed 's/([^)]*)//g' | sed 's/[^a-zA-Z0-9_.:$]//g' | awk -F ':' '{printf "- [%s](%s#%s)\n", $3, $1, $3}' | sort -d -f -u >> $TMPFILE
    alpha="A B C D E F G H I J K L M N O P Q R S T U V W X Y Z"
    for a in $alpha; do
        echo -n "[$a](#$(lcase "$a")) "
    done
    echo
    echo
    for a in $alpha; do
        links=$(cat $TMPFILE | grep -i "^- .[$(lcase "$a")]")
        if [ "$links" != "" ]; then
            echo "### $(ucase "$a")"
            echo "$links"
            echo
        fi
    done
    rm -f $TMPFILE
}


(
    echo "## Belfry OpenScad Library Index"
    (
        grep 'Constant: ' *.scad
        grep 'Function: ' *.scad
        grep 'Function&Module: ' *.scad
        grep 'Module: ' *.scad
    ) | mkindex
) > BOSL2.wiki/Index.md

