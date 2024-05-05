#!/bin/bash

OUTFILE_BASE="BOSL2_Docs"
FORMATS="html5"
SOURCES="constants.scad.md transforms.scad.md attachments.scad.md shapes2d.scad.md shapes3d.scad.md drawing.scad.md masks2d.scad.md masks3d.scad.md distributors.scad.md color.scad.md partitions.scad.md miscellaneous.scad.md paths.scad.md regions.scad.md skin.scad.md vnf.scad.md beziers.scad.md rounding.scad.md turtle3d.scad.md math.scad.md linalg.scad.md vectors.scad.md coords.scad.md geometry.scad.md trigonometry.scad.md version.scad.md comparisons.scad.md lists.scad.md utility.scad.md strings.scad.md structs.scad.md fnliterals.scad.md threading.scad.md screws.scad.md screw_drive.scad.md bottlecaps.scad.md ball_bearings.scad.md cubetruss.scad.md gears.scad.md hinges.scad.md joiners.scad.md linear_bearings.scad.md modular_hose.scad.md nema_steppers.scad.md polyhedra.scad.md sliders.scad.md tripod_mounts.scad.md walls.scad.md wiring.scad.md Tutorial-*.md Topics.md AlphaIndex.md"
PANDOC="/usr/local/Cellar/pandoc/3.1/bin/pandoc"
TITLE="Documentation for the Belfry OpenSCAD Library v2"
AUTHOR="Garth Minette"

if [[ ! -d BOSL2.wiki ]] ; then
	echo "Must be in the BOSL2 directory."
	exit 255
fi

cd BOSL2.wiki

for format in ${FORMATS} ; do
	suffix=$(echo ${format} | sed 's/html5/html/')
	outfile="${OUTFILE_BASE}.${suffix}"

	echo "Generating ${outfile} ..."
	${PANDOC} -f gfm -t ${format} -o ../${outfile} \
		-s --embed-resources --mathjax --file-scope --pdf-engine=xelatex \
		--columns=100 --epub-cover-image=../images/BOSL2logo.png \
		--toc -N --toc-depth=2 --css=../resources/docs_custom.css \
		--lua-filter=../resources/links-filter-html.lua \
		--resource-path='.:images:images/*' \
		--variable mainfont=Arial --variable sansfont=Arial \
		--metadata title="${TITLE}" \
		--metadata author="${AUTHOR}" \
		--metadata date="$(date -j "+%B %e, %Y")" \
		--metadata geometry=left=3cm,right=3cm,top=2cm,bottom=2cm \
		${SOURCES}
done

cd ..

