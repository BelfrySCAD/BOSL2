//////////////////////////////////////////////////////////////////////
// LibFile: std.scad
//   File that includes the standard BOSL include files.
// Includes:
//   include <BOSL2/std.scad>
//////////////////////////////////////////////////////////////////////

assert(version_num()>=20190500, "BOSL2 requires OpenSCAD version 2019.05 or later.");


include <version.scad>

include <constants.scad>
include <transforms.scad>
include <distributors.scad>
include <miscellaneous.scad>
include <color.scad>
include <attachments.scad>
include <beziers.scad>
include <shapes3d.scad>
include <shapes2d.scad>
include <drawing.scad>
include <masks3d.scad>
include <masks2d.scad>
include <math.scad>
include <paths.scad>
include <lists.scad>
include <comparisons.scad>
include <linalg.scad>
include <trigonometry.scad>
include <vectors.scad>
include <affine.scad>
include <coords.scad>
include <geometry.scad>
include <regions.scad>
include <strings.scad>
include <vnf.scad>
include <structs.scad>
include <rounding.scad>
include <skin.scad>
include <utility.scad>
include <partitions.scad>

// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap

