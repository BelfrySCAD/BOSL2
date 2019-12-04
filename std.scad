//////////////////////////////////////////////////////////////////////
// LibFile: std.scad
//   File that includes the standard BOSL include files.
//   To use, add the following lines to the beginning of your file:
//   ```
//   include <BOSL2/std.scad>
//   ```
//////////////////////////////////////////////////////////////////////

assert(version_num()>=20190301, "BOSL2 requires OpenSCAD version 2019.03.01 or later.");

include <version.scad>

include <constants.scad>
include <edges.scad>
include <common.scad>
include <errors.scad>
include <arrays.scad>
include <vnf.scad>

include <math.scad>
include <vectors.scad>
include <quaternions.scad>
include <affine.scad>
include <coords.scad>
include <geometry.scad>
include <regions.scad>

include <transforms.scad>
include <attachments.scad>
include <primitives.scad>
include <shapes.scad>
include <shapes2d.scad>
include <masks.scad>
include <paths.scad>


// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap

