#!/bin/bash


function ucase
{
    echo "$1" | tr '[:lower:]' '[:upper:]'
}


function lcase
{
    echo "$1" | tr '[:upper:]' '[:lower:]'
}


function alphaindex
{
    alpha="A B C D E F G H I J K L M N O P Q R S T U V W X Y Z"
    TMPFILE=$(mktemp -t $(basename $0).XXXXXX) || exit 1
    sort -d -f >> $TMPFILE
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


function constlist
{
    sed 's/([^)]*)//g' | sed 's/[^a-zA-Z0-9_.:$]//g' | awk -F ':' '{printf "- [%s](%s#%s) (in %s)\n", $3, $1, $3, $1}'
}
 
function constlist2
{
    sed 's/ *=.*$//' | sed 's/[^a-zA-Z0-9_.:$]//g' | awk -F ':' '{printf "- [%s](%s#%s) (in %s)\n", $2, $1, $2, $1}'
}
 

function funclist
{
    sed 's/([^)]*)//g' | sed 's/[^a-zA-Z0-9_.:$]//g' | awk -F ':' '{printf "- [%s()](%s#%s) (in %s)\n", $3, $1, $3, $1}'
}


(
    echo "## Belfry OpenScad Library Index"
    (
    	(
	    grep 'Constant: ' *.scad | constlist
	    grep '^[A-Z]* *=.*//' *.scad | constlist2
	) | sort -u
        egrep 'Function: |Function&Module: |Module: ' *.scad | sort -u | funclist
    ) | sort | alphaindex
) > BOSL2.wiki/Index.md

