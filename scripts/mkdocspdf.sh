#!/bin/bash

FORMAT=pdf
SUFFIX=pdf
SOURCES="*.scad.md Tutorial-*.md Topics.md AlphaIndex.md"
PANDOC="/usr/local/Cellar/pandoc/3.1/bin/pandoc"
TITLE="Documentation for the Belfry OpenSCAD Library v2"
AUTHOR="Garth Minette"

if [[ ! -d BOSL2.wiki ]] ; then
	echo "Must be in the BOSL2 directory."
	exit 255
fi

cd BOSL2.wiki

${PANDOC} -f gfm -t ${FORMAT} -o ../documentation.${SUFFIX} \
	-s --embed-resources --mathjax --file-scope --pdf-engine=xelatex \
	--toc --columns=100 --epub-cover-image=../images/BOSL2logo.png \
	--variable mainfont=Arial --variable sansfont=Arial \
	--metadata title="${TITLE}" \
	--metadata author="${AUTHOR}" \
	--metadata date="$(date -j "+%B %e, %Y")" \
	--metadata geometry=left=3cm,right=3cm,top=2cm,bottom=2cm \
	${SOURCES}

cd ..


