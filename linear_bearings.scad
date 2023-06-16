//////////////////////////////////////////////////////////////////////
// LibFile: linear_bearings.scad
//   Mounts and models for LMxUU style linear bearings.
// Includes:
//   include <BOSL2/std.scad>
//   include <BOSL2/linear_bearings.scad>
// FileGroup: Parts
// FileSummary: Mounts for LMxUU style linear bearings.
//////////////////////////////////////////////////////////////////////

include <screws.scad>


// Section: Generic Linear Bearings

// Module: linear_bearing_housing()
// Synopsis: Creates a generic linear bearing mount clamp.
// SynTags: Geom
// Topics: Parts, Bearings
// See Also: linear_bearing(), lmXuu_info(), ball_bearing()
// Usage:
//   linear_bearing_housing(d, l, tab, gap, wall, tabwall, screwsize) [ATTACHMENTS];
// Description:
//   Creates a model of a clamp to hold a generic linear bearing cartridge.
// Arguments:
//   d = Diameter of linear bearing. (Default: 15)
//   l = Length of linear bearing. (Default: 24)
//   tab = Clamp tab height. (Default: 8)
//   tabwall = Clamp Tab thickness. (Default: 5)
//   wall = Wall thickness of clamp housing. (Default: 3)
//   gap = Gap in clamp. (Default: 5)
//   screwsize = Size of screw to use to tighten clamp. (Default: 3)
//   ---
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Example:
//   linear_bearing_housing(d=19, l=29, wall=2, tab=8, screwsize=2.5);
module linear_bearing_housing(d=15, l=24, tab=8, gap=5, wall=3, tabwall=5, screwsize=3, anchor=BOTTOM, spin=0, orient=UP)
{
    od = d+2*wall;
    ogap = gap+2*tabwall;
    tabh = tab/2+od/2*sqrt(2)-ogap/2-1;
    h = od+tab/2;
    anchors = [
        named_anchor("axis", [0,0,-tab/2/2]),
        named_anchor("screw", [0,2-ogap/2,tabh-tab/2/2],FWD),
        named_anchor("nut", [0,ogap/2-2,tabh-tab/2/2],FWD)
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
                screwsize = is_string(screwsize)? screwsize : str("M",screwsize);

                // Screwhole
                fwd(ogap/2-2+0.01)
                    screw_hole(str(screwsize,",",ogap), head="socket", counterbore=3, anchor="head_bot", orient=FWD, $fn=12);

                // Nut holder
                back(ogap/2-2+0.01)
                    nut_trap_inline(tabwall, screwsize, orient=BACK);
            }
        }
        children();
    }
}


// Module: linear_bearing()
// Synopsis: Creates a generic linear bearing cartridge.
// SynTags: Geom
// Topics: Parts, Bearings
// See Also: linear_bearing_housing(), lmXuu_info(), ball_bearing()
// Usage:
//   linear_bearing(l, od, id, length) [ATTACHMENTS];
// Description:
//   Creates a rough model of a generic linear ball bearing cartridge.
// Arguments:
//   l/length = The length of the linear bearing cartridge.
//   od = The outer diameter of the linear bearing cartridge.
//   id = The inner diameter of the linear bearing cartridge.
//   ---
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Example:
//   linear_bearing(l=24, od=15, id=8);
module linear_bearing(l, od=15, id=8, length, anchor=CTR, spin=0, orient=UP) {
    l = first_defined([l, length, 24]);
    attachable(anchor,spin,orient, d=od, l=l) {
        color("silver") {
            tube(id=id, od=od, l=l-1);
            tube(id=od-1, od=od, l=l);
            tube(id=id, od=id+1, l=l);
            tube(id=id+2, od=od-2, l=l);
        }
        children();
    }
}


// Section: lmXuu Linear Bearings

// Module: lmXuu_housing()
// Synopsis: Creates a standardized LM*UU linear bearing mount clamp.
// SynTags: Geom
// Topics: Parts, Bearings
// See Also: linear_bearing(), linear_bearing_housing(), lmXuu_info(), lmXuu_bearing(), lmXuu_housing(), ball_bearing()
// Usage:
//   lmXuu_housing(size, tab, gap, wall, tabwall, screwsize) [ATTACHMENTS];
// Description:
//   Creates a model of a clamp to hold a standard sized lmXuu linear bearing cartridge.
// Arguments:
//   size = Standard lmXuu inner size.
//   tab = Clamp tab height.  Default: 7
//   tabwall = Clamp Tab thickness.  Default: 5
//   wall = Wall thickness of clamp housing.  Default: 3
//   gap = Gap in clamp.  Default: 5
//   screwsize = Size of screw to use to tighten clamp.  Default: 3
//   ---
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Example:
//   lmXuu_housing(size=10, wall=2, tab=6, screwsize=2.5);
module lmXuu_housing(size=8, tab=7, gap=5, wall=3, tabwall=5, screwsize=3, anchor=BOTTOM, spin=0, orient=UP)
{
    info = lmXuu_info(size);
    d = info[0];
    l = info[1];
    linear_bearing_housing(d=d, l=l, tab=tab, gap=gap, wall=wall, tabwall=tabwall, screwsize=screwsize, orient=orient, spin=spin, anchor=anchor) children();
}


// Module: lmXuu_bearing()
// Synopsis: Creates a standardized LM*UU linear bearing cartridge.
// SynTags: Geom
// Topics: Parts, Bearings
// See Also: linear_bearing(), linear_bearing_housing(), lmXuu_info(), lmXuu_bearing(), lmXuu_housing(), ball_bearing()
// Usage:
//   lmXuu_bearing(size) [ATTACHMENTS];
// Description:
//   Creates a model of an lmXuu linear ball bearing cartridge.
// Arguments:
//   size = Standard lmXuu inner size.
//   ---
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Example:
//   lmXuu_bearing(size=10);
module lmXuu_bearing(size=8, anchor=CTR, spin=0, orient=UP) {
    info = lmXuu_info(size);
    linear_bearing(l=info[1], id=size, od=info[0], anchor=anchor, spin=spin, orient=orient) children();
}


// Section: lmXuu Linear Bearing Info


// Function: lmXuu_info()
// Synopsis: Returns the sizes of a standard LM*UU linear bearing cartridge.
// Topics: Parts, Bearings
// See Also: linear_bearing(), linear_bearing_housing(), lmXuu_info(), lmXuu_bearing(), lmXuu_housing(), ball_bearing()
// Usage:
//   diam_len = lmXuu_info(size);
// Description:
//   Get dimensional info for a standard metric lmXuu linear bearing cartridge.
//   Returns `[DIAM, LENGTH]` for the cylindrical cartridge.
// Arguments:
//   size = Inner diameter of lmXuu bearing, in mm.
function lmXuu_info(size) =
    let(
        data = [
            // size, diam, length
            [  4,   8,  12],
            [  5,  10,  15],
            [  6,  12,  19],
            [  8,  15,  24],
            [ 10,  19,  29],
            [ 12,  21,  30],
            [ 13,  23,  32],
            [ 16,  28,  37],
            [ 20,  32,  42],
            [ 25,  40,  59],
            [ 30,  45,  64],
            [ 35,  52,  70],
            [ 40,  60,  80],
            [ 50,  80, 100],
            [ 60,  90, 110],
            [ 80, 120, 140],
            [100, 150, 175],
        ],
        found = search([size], data, 1)[0]
    )
    assert(found!=[], str("Unsupported lmXuu linear bearing size: ", size))
    select(data[found], 1, -1);



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
