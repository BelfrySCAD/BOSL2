//////////////////////////////////////////////////////////////////////
// LibFile: wiring.scad
//   Rendering for routed wire bundles
// Includes:
//   include <BOSL2/std.scad>
//   include <BOSL2/wiring.scad>
// FileGroup: Parts
// FileSummary: Routed bundles of wires.
//////////////////////////////////////////////////////////////////////

include <rounding.scad>


/// Function: _hex_offset_ring()
/// Usage:
///   _hex_offset_ring(d, lev)
/// Description:
///   Returns a hexagonal ring of points, with a spacing of `d`.
///   If `lev=0`, returns a single point at `[0,0]`.  All greater
///   levels return `6 * lev` points.
/// Arguments:
///   d = Base unit diameter to build rings upon.
///   lev = How many rings to produce.
/// Example:
///   _hex_offset_ring(d=1, lev=3); // Returns a hex ring of 18 points.
function _hex_offset_ring(d, lev=0) =
    (lev == 0)? [[0,0]] :
    reverse(subdivide_path(hexagon(r=lev*d), refine=lev));


/// Function: _hex_offsets()
/// Usage:
///   _hex_offsets(n, d)
/// Description:
///   Returns the centerpoints for the optimal hexagonal packing
///   of at least `n` circular items, of diameter `d`.  Will return
///   enough points to fill out the last ring, even if that is more
///   than `n` points.
/// Arguments:
///   n = Number of items to bundle.
///   d = How far to space each point away from others.
function _hex_offsets(n, d, lev=0, arr=[]) =
    (len(arr) >= n)? arr :
        _hex_offsets(
            n=n,
            d=d,
            lev=lev+1,
            arr=concat(arr, _hex_offset_ring(d, lev=lev))
        );



// Section: Modules


// Module: wire_bundle()
// Synopsis: Creates a wire bundle for a given number of wires.
// SynTags: Geom
// Topics: Wiring
// See Also: path_sweep(), path_sweep2d()
// Usage:
//   wire_bundle(path, wires, [wirediam], [rounding], [wirenum=], [corner_steps=]);
// Description:
//   Returns a 3D object representing a bundle of wires that follow a given path,
//   with the corners rounded to a given radius.  There are 17 base wire colors.
//   If you have more than 17 wires, colors will get re-used.
// Arguments:
//   path = The 3D path that the wire bundle should follow.
//   wires = The number of wires in the wire bundle.
//   wirediam = The diameter of each wire in the bundle.
//   rounding = The radius that the path corners will be rounded to.
//   ---
//   wirenum = The first wire's offset into the color table.
//   corner_steps = The corner roundings in the path will be converted into this number of segments.
// Example:
//   wire_bundle([[50,0,-50], [50,50,-50], [0,50,-50], [0,0,-50], [0,0,0]], rounding=10, wires=13);
module wire_bundle(path, wires, wirediam=2, rounding=10, wirenum=0, corner_steps=15) {
    no_children($children);
    colors = [
        [0.2, 0.2, 0.2], [1.0, 0.2, 0.2], [0.0, 0.8, 0.0], [1.0, 1.0, 0.2],
        [0.3, 0.3, 1.0], [1.0, 1.0, 1.0], [0.7, 0.5, 0.0], [0.5, 0.5, 0.5],
        [0.2, 0.9, 0.9], [0.8, 0.0, 0.8], [0.0, 0.6, 0.6], [1.0, 0.7, 0.7],
        [1.0, 0.5, 1.0], [0.5, 0.6, 0.0], [1.0, 0.7, 0.0], [0.7, 1.0, 0.5],
        [0.6, 0.6, 1.0],
    ];
    sides = max(segs(wirediam/2), 8);
    offsets = _hex_offsets(wires, wirediam);
    rounded_path = round_corners(path, radius=rounding, $fn=(corner_steps+1)*4, closed=false);
    attachable(){
      for (i = [0:1:wires-1]) {
          extpath = move(offsets[i], p=circle(d=wirediam, $fn=sides));
          color(colors[(i+wirenum)%len(colors)]) {
              path_sweep(extpath, rounded_path);
          }
      }
      union();
    }
}



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
