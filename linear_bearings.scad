//////////////////////////////////////////////////////////////////////
// LibFile: linear_bearings.scad
//   Linear Bearing clips/holders.
//   To use, add these lines to the top of your file:
//   ```
//   include <BOSL2/std.scad>
//   include <BOSL2/linear_bearings.scad>
//   ```
//////////////////////////////////////////////////////////////////////


include <BOSL2/metric_screws.scad>


// Section: Functions


// Function: get_lmXuu_bearing_diam()
// Description: Get outside diameter, in mm, of a standard lmXuu bearing.
// Arguments:
//   size = Inner size of lmXuu bearing, in mm.
function get_lmXuu_bearing_diam(size) = lookup(size, [
		[  4.0,   8.0],
		[  5.0,  10.0],
		[  6.0,  12.0],
		[  8.0,  15.0],
		[ 10.0,  19.0],
		[ 12.0,  21.0],
		[ 13.0,  23.0],
		[ 16.0,  28.0],
		[ 20.0,  32.0],
		[ 25.0,  40.0],
		[ 30.0,  45.0],
		[ 35.0,  52.0],
		[ 40.0,  60.0],
		[ 50.0,  80.0],
		[ 60.0,  90.0],
		[ 80.0, 120.0],
		[100.0, 150.0]
	]);


// Function: get_lmXuu_bearing_length()
// Description: Get length, in mm, of a standard lmXuu bearing.
// Arguments:
//   size = Inner size of lmXuu bearing, in mm.
function get_lmXuu_bearing_length(size) = lookup(size, [
		[  4.0,  12.0],
		[  5.0,  15.0],
		[  6.0,  19.0],
		[  8.0,  24.0],
		[ 10.0,  29.0],
		[ 12.0,  30.0],
		[ 13.0,  32.0],
		[ 16.0,  37.0],
		[ 20.0,  42.0],
		[ 25.0,  59.0],
		[ 30.0,  64.0],
		[ 35.0,  70.0],
		[ 40.0,  80.0],
		[ 50.0, 100.0],
		[ 60.0, 110.0],
		[ 80.0, 140.0],
		[100.0, 175.0]
	]);


// Module: linear_bearing_housing()
// Description:
//   Creates a model of a clamp to hold a generic linear bearing cartridge.
// Arguments:
//   d = Diameter of linear bearing. (Default: 15)
//   l = Length of linear bearing. (Default: 24)
//   tab = Clamp tab height. (Default: 7)
//   tabwall = Clamp Tab thickness. (Default: 5)
//   wall = Wall thickness of clamp housing. (Default: 3)
//   gap = Gap in clamp. (Default: 5)
//   screwsize = Size of screw to use to tighten clamp. (Default: 3)
//   orient = Orientation of the housing.  Use the `ORIENT_` constants from `constants.scad`.  Default: `ORIENT_X`.
//   anchor = Alignment of the housing by the axis-negative (size1) end.  Use the constants from `constants.scad`.  Default: `UP`
// Example:
//   linear_bearing_housing(d=19, l=29, wall=2, tab=6, screwsize=2.5);
module linear_bearing_housing(d=15, l=24, tab=7, gap=5, wall=3, tabwall=5, screwsize=3, orient=ORIENT_X, anchor=UP)
{
	od = d+2*wall;
	ogap = gap+2*tabwall;
	tabh = tab/2+od/2*sqrt(2)-ogap/2;
	orient_and_anchor([l, od, od], orient, anchor, orig_orient=ORIENT_X, chain=true) {
		difference() {
			union() {
				zrot(90) teardrop(r=od/2,h=l);
				up(tabh) cube(size=[l,ogap,tab+0.05], center=true);
				down(od/4) cube(size=[l,od,od/2], center=true);
			}
			zrot(90) teardrop(r=d/2,h=l+0.05);
			up((d*sqrt(2)+tab)/2)
				cube(size=[l+0.05,gap,d+tab], center=true);
			up(tabh) {
				fwd(ogap/2-2+0.01)
					xrot(90) screw(screwsize=screwsize*1.06, screwlen=ogap, headsize=screwsize*2, headlen=10);
				back(ogap/2+0.01)
					xrot(90) metric_nut(size=screwsize, hole=false);
			}
		}
		children();
	}
}


// Module: lmXuu_housing()
// Description:
//   Creates a model of a clamp to hold a standard sized lmXuu linear bearing cartridge.
// Arguments:
//   size = Standard lmXuu inner size.
//   tab = Clamp tab height.  Default: 7
//   tabwall = Clamp Tab thickness.  Default: 5
//   wall = Wall thickness of clamp housing.  Default: 3
//   gap = Gap in clamp.  Default: 5
//   screwsize = Size of screw to use to tighten clamp.  Default: 3
//   orient = Orientation of the housing.  Use the `ORIENT_` constants from `constants.scad`.  Default: `ORIENT_X`.
//   anchor = Alignment of the housing by the axis-negative (size1) end.  Use the constants from `constants.scad`.  Default: `UP`
// Example:
//   lmXuu_housing(size=10, wall=2, tab=6, screwsize=2.5);
module lmXuu_housing(size=8, tab=7, gap=5, wall=3, tabwall=5, screwsize=3, orient=ORIENT_X, anchor=UP)
{
	d = get_lmXuu_bearing_diam(size);
	l = get_lmXuu_bearing_length(size);
	linear_bearing_housing(d=d,l=l,tab=tab,gap=gap,wall=wall,tabwall=tabwall,screwsize=screwsize, orient=orient, anchor=anchor) children();
}


// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
