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
include <mutators.scad>
include <attachments.scad>
include <primitives.scad>
include <shapes.scad>
include <shapes2d.scad>
include <masks.scad>
include <paths.scad>
include <edges.scad>
include <arrays.scad>
include <math.scad>
include <vectors.scad>
include <quaternions.scad>
include <affine.scad>
include <coords.scad>
include <geometry.scad>
include <hull.scad>
include <regions.scad>
include <strings.scad>
include <skin.scad>
include <vnf.scad>
include <common.scad>
include <debug.scad>


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap

