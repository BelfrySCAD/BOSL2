//////////////////////////////////////////////////////////////////////
// LibFile: linear_bearings.scad
//   Linear Bearing clips/holders.
// Includes:
//   include <BOSL2/std.scad>
//   include <BOSL2/linear_bearings.scad>
//////////////////////////////////////////////////////////////////////


include <metric_screws.scad>


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
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
// Example:
//   linear_bearing_housing(d=19, l=29, wall=2, tab=6, screwsize=2.5);
module linear_bearing_housing(d=15, l=24, tab=7, gap=5, wall=3, tabwall=5, screwsize=3, anchor=BOTTOM, spin=0, orient=UP)
{
    od = d+2*wall;
    ogap = gap+2*tabwall;
    tabh = tab/2+od/2*sqrt(2)-ogap/2;
    h = od+tab/2;
    anchors = [
        anchorpt("axis", [0,0,-tab/2/2]),
        anchorpt("screw", [0,2-ogap/2,tabh-tab/2/2],FWD),
        anchorpt("nut", [0,ogap/2-2,tabh-tab/2/2],FWD)
    ];
    attachable(anchor,spin,orient, size=[l, od, h], anchors=anchors) {
        down(tab/2/2)
        difference() {
            union() {
                // Housing
                zrot(90) teardrop(r=od/2,h=l);

                // Base
                cube([l,od,od/2], anchor=TOP);

                // Tabs
                cube([l,ogap,od/2+tab/2], anchor=BOTTOM);
            }

            // Clear bearing space
            zrot(90) teardrop(r=d/2,h=l+0.05);

            // Clear gap
            cube([l+0.05,gap,od], anchor=BOTTOM);

            up(tabh) {
                // Screwhole
                fwd(ogap/2-2+0.01) generic_screw(screwsize=screwsize*1.06, screwlen=ogap, headsize=screwsize*2, headlen=10, orient=FWD);

                // Nut holder
                back(ogap/2-2+0.01) metric_nut(size=screwsize, hole=false, anchor=BOTTOM, orient=BACK);
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
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
// Example:
//   lmXuu_housing(size=10, wall=2, tab=6, screwsize=2.5);
module lmXuu_housing(size=8, tab=7, gap=5, wall=3, tabwall=5, screwsize=3, anchor=BOTTOM, spin=0, orient=UP)
{
    d = get_lmXuu_bearing_diam(size);
    l = get_lmXuu_bearing_length(size);
    linear_bearing_housing(d=d, l=l, tab=tab, gap=gap, wall=wall, tabwall=tabwall, screwsize=screwsize, orient=orient, spin=spin, anchor=anchor) children();
}


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
