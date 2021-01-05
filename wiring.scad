//////////////////////////////////////////////////////////////////////
// LibFile: wiring.scad
//   Rendering for wiring bundles
// Includes:
//   include <BOSL2/std.scad>
//   include <BOSL2/wiring.scad>
//////////////////////////////////////////////////////////////////////


include <beziers.scad>


// Section: Functions


// Function: hex_offset_ring()
// Description:
//   Returns a hexagonal ring of points, with a spacing of `d`.
//   If `lev=0`, returns a single point at `[0,0]`.  All greater
//   levels return 6 times `lev` points.
// Usage:
//   hex_offset_ring(d, lev)
// Arguments:
//   d = Base unit diameter to build rings upon.
//   lev = How many rings to produce.
// Example:
//   hex_offset_ring(d=1, lev=3); // Returns a hex ring of 18 points.
function hex_offset_ring(d, lev=0) =
    (lev == 0)? [[0,0]] : [
        for (
            sideang = [0:60:359.999],
            sidenum = [1:1:lev]
        ) [
            lev*d*cos(sideang)+sidenum*d*cos(sideang+120),
            lev*d*sin(sideang)+sidenum*d*sin(sideang+120)
        ]
    ];


// Function: hex_offsets()
// Description:
//   Returns the centerpoints for the optimal hexagonal packing
//   of at least `n` circular items, of diameter `d`.  Will return
//   enough points to fill out the last ring, even if that is more
//   than `n` points.
// Usage:
//   hex_offsets(n, d)
// Arguments:
//   n = Number of items to bundle.
//   d = How far to space each point away from others.
function hex_offsets(n, d, lev=0, arr=[]) =
    (len(arr) >= n)? arr :
        hex_offsets(
            n=n,
            d=d,
            lev=lev+1,
            arr=concat(arr, hex_offset_ring(d, lev=lev))
        );



// Section: Modules


// Module: wiring()
// Description:
//   Returns a 3D object representing a bundle of wires that follow a given path,
//   with the corners rounded to a given radius.  There are 17 base wire colors.
//   If you have more than 17 wires, colors will get re-used.
// Usage:
//   wiring(path, wires, [wirediam], [rounding], [wirenum], [bezsteps]);
// Arguments:
//   path = The 3D path that the wire bundle should follow.
//   wires = The number of wires in the wiring bundle.
//   wirediam = The diameter of each wire in the bundle.
//   rounding = The radius that the path corners will be rounded to.
//   wirenum = The first wire's offset into the color table.
//   bezsteps = The corner roundings in the path will be converted into this number of segments.
// Example:
//   wiring([[50,0,-50], [50,50,-50], [0,50,-50], [0,0,-50], [0,0,0]], rounding=10, wires=13);
module wiring(path, wires, wirediam=2, rounding=10, wirenum=0, bezsteps=12) {
    colors = [
        [0.2, 0.2, 0.2], [1.0, 0.2, 0.2], [0.0, 0.8, 0.0], [1.0, 1.0, 0.2],
        [0.3, 0.3, 1.0], [1.0, 1.0, 1.0], [0.7, 0.5, 0.0], [0.5, 0.5, 0.5],
        [0.2, 0.9, 0.9], [0.8, 0.0, 0.8], [0.0, 0.6, 0.6], [1.0, 0.7, 0.7],
        [1.0, 0.5, 1.0], [0.5, 0.6, 0.0], [1.0, 0.7, 0.0], [0.7, 1.0, 0.5],
        [0.6, 0.6, 1.0],
    ];
    offsets = hex_offsets(wires, wirediam);
    bezpath = fillet_path(path, rounding);
    poly = simplify_path(path3d(bezier_path(bezpath, bezsteps)));
    n = max(segs(wirediam), 8);
    r = wirediam/2;
    for (i = [0:1:wires-1]) {
        extpath = [for (j = [0:1:n-1]) let(a=j*360/n) [r*cos(a)+offsets[i][0], r*sin(a)+offsets[i][1]]];
        color(colors[(i+wirenum)%len(colors)]) {
            path_sweep(extpath, poly);
        }
    }
}



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
