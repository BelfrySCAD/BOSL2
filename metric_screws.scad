//////////////////////////////////////////////////////////////////////
// LibFile: metric_screws.scad
//   Screws, Bolts, and Nuts.
// Includes:
//   include <BOSL2/std.scad>
//   include <BOSL2/metric_screws.scad>
// FileGroup: Threaded Parts
// FileSummary: Metric screws, nuts, and screwholes.
//////////////////////////////////////////////////////////////////////


include <threading.scad>
include <screw_drive.scad>

warn = echo("*** WARNING: metric_screws.scad is deprecated and may be removed in the future.  Use screws.scad instead. ***");


// Section: Functions


// Function: get_metric_bolt_head_size()
// Description: Returns the diameter of a typical metric bolt's head, based on the bolt `size`.
function get_metric_bolt_head_size(size) = lookup(size, [
        [ 3.0,  5.5],
        [ 4.0,  7.0],
        [ 5.0,  8.0],
        [ 6.0, 10.0],
        [ 7.0, 11.0],
        [ 8.0, 13.0],
        [10.0, 17.0],
        [12.0, 19.0],
        [14.0, 22.0],
        [16.0, 24.0],
        [18.0, 27.0],
        [20.0, 30.0],
        [24.0, 36.0],
        [30.0, 46.0],
        [36.0, 55.0],
        [42.0, 65.0],
        [48.0, 75.0],
        [56.0, 85.0],
        [64.0, 95.0]
    ]);


// Function: get_metric_bolt_head_height()
// Description: Returns the height of a typical metric bolt's head, based on the bolt `size`.
function get_metric_bolt_head_height(size) = lookup(size, [
        [ 1.6,  1.23],
        [ 2.0,  1.53],
        [ 2.5,  1.83],
        [ 3.0,  2.13],
        [ 4.0,  2.93],
        [ 5.0,  3.65],
        [ 6.0,  4.15],
        [ 8.0,  5.45],
        [10.0,  6.58],
        [12.0,  7.68],
        [14.0,  8.98],
        [16.0, 10.18],
        [20.0, 12.72],
        [24.0, 15.35],
        [30.0, 19.12],
        [36.0, 22.92],
        [42.0, 26.42],
        [48.0, 30.42],
        [56.0, 35.50],
        [64.0, 40.50]
    ]);


// Function: get_metric_socket_cap_diam()
// Description: Returns the diameter of a typical metric socket cap bolt's head, based on the bolt `size`.
function get_metric_socket_cap_diam(size) = lookup(size, [
        [ 1.6,  3.0],
        [ 2.0,  3.8],
        [ 2.5,  4.5],
        [ 3.0,  5.5],
        [ 4.0,  7.0],
        [ 5.0,  8.5],
        [ 6.0, 10.0],
        [ 8.0, 13.0],
        [10.0, 16.0],
        [12.0, 18.0],
        [14.0, 21.0],
        [16.0, 24.0],
        [18.0, 27.0],
        [20.0, 30.0],
        [22.0, 33.0],
        [24.0, 36.0],
        [27.0, 40.0],
        [30.0, 45.0],
        [33.0, 50.0],
        [36.0, 54.0],
        [42.0, 63.0],
        [48.0, 72.0],
        [56.0, 84.0],
        [64.0, 96.0]
    ]);


// Function: get_metric_socket_cap_height()
// Description: Returns the height of a typical metric socket cap bolt's head, based on the bolt `size`.
function get_metric_socket_cap_height(size) = lookup(size, [
        [ 1.6,  1.7],
        [ 2.0,  2.0],
        [ 2.5,  2.5],
        [ 3.0,  3.0],
        [ 4.0,  4.0],
        [ 5.0,  5.0],
        [ 6.0,  6.0],
        [ 8.0,  8.0],
        [10.0, 10.0],
        [12.0, 12.0],
        [14.0, 14.0],
        [16.0, 16.0],
        [18.0, 18.0],
        [20.0, 20.0],
        [22.0, 22.0],
        [24.0, 24.0],
        [27.0, 27.0],
        [30.0, 30.0],
        [33.0, 33.0],
        [36.0, 36.0],
        [42.0, 42.0],
        [48.0, 48.0],
        [56.0, 56.0],
        [64.0, 64.0]
    ]);


// Function: get_metric_socket_cap_socket_size()
// Description: Returns the diameter of a typical metric socket cap bolt's hex drive socket, based on the bolt `size`.
function get_metric_socket_cap_socket_size(size) = lookup(size, [
        [ 1.6,  1.5],
        [ 2.0,  1.5],
        [ 2.5,  2.0],
        [ 3.0,  2.5],
        [ 4.0,  3.0],
        [ 5.0,  4.0],
        [ 6.0,  5.0],
        [ 8.0,  6.0],
        [10.0,  8.0],
        [12.0, 10.0],
        [14.0, 12.0],
        [16.0, 14.0],
        [18.0, 14.0],
        [20.0, 17.0],
        [22.0, 17.0],
        [24.0, 19.0],
        [27.0, 19.0],
        [30.0, 22.0],
        [33.0, 24.0],
        [36.0, 27.0],
        [42.0, 32.0],
        [48.0, 36.0],
        [56.0, 41.0],
        [64.0, 46.0]
    ]);


// Function: get_metric_socket_cap_socket_depth()
// Description: Returns the depth of a typical metric socket cap bolt's hex drive socket, based on the bolt `size`.
function get_metric_socket_cap_socket_depth(size) = lookup(size, [
        [ 1.6,  0.7],
        [ 2.0,  1.0],
        [ 2.5,  1.1],
        [ 3.0,  1.3],
        [ 4.0,  2.0],
        [ 5.0,  2.5],
        [ 6.0,  3.0],
        [ 8.0,  4.0],
        [10.0,  5.0],
        [12.0,  6.0],
        [14.0,  7.0],
        [16.0,  8.0],
        [18.0,  9.0],
        [20.0, 10.0],
        [22.0, 11.0],
        [24.0, 12.0],
        [27.0, 13.5],
        [30.0, 15.5],
        [33.0, 18.0],
        [36.0, 19.0],
        [42.0, 24.0],
        [48.0, 28.0],
        [56.0, 34.0],
        [64.0, 38.0]
    ]);


// Function: get_metric_iso_coarse_thread_pitch()
// Description: Returns the ISO metric standard coarse threading pitch for a given bolt `size`.
function get_metric_iso_coarse_thread_pitch(size) = lookup(size, [
        [ 1.6, 0.35],
        [ 2.0, 0.40],
        [ 2.5, 0.45],
        [ 3.0, 0.50],
        [ 4.0, 0.70],
        [ 5.0, 0.80],
        [ 6.0, 1.00],
        [ 7.0, 1.00],
        [ 8.0, 1.25],
        [10.0, 1.50],
        [12.0, 1.75],
        [14.0, 2.00],
        [16.0, 2.00],
        [18.0, 2.50],
        [20.0, 2.50],
        [22.0, 2.50],
        [24.0, 3.00],
        [27.0, 3.00],
        [30.0, 3.50],
        [33.0, 3.50],
        [36.0, 4.00],
        [39.0, 4.00],
        [42.0, 4.50],
        [45.0, 4.50],
        [48.0, 5.00],
        [56.0, 5.50],
        [64.0, 6.00]
    ]);


// Function: get_metric_iso_fine_thread_pitch()
// Description: Returns the ISO metric standard fine threading pitch for a given bolt `size`.
function get_metric_iso_fine_thread_pitch(size) = lookup(size, [
        [ 1.6, 0.35],
        [ 2.0, 0.40],
        [ 2.5, 0.45],
        [ 3.0, 0.50],
        [ 4.0, 0.70],
        [ 5.0, 0.80],
        [ 6.0, 1.00],
        [ 7.0, 1.00],
        [ 8.0, 1.00],
        [10.0, 1.25],
        [12.0, 1.50],
        [14.0, 1.50],
        [16.0, 2.00],
        [18.0, 2.50],
        [20.0, 2.50],
        [22.0, 2.50],
        [24.0, 3.00],
        [27.0, 3.00],
        [30.0, 3.50],
        [33.0, 3.50],
        [36.0, 4.00],
        [39.0, 4.00],
        [42.0, 4.50],
        [45.0, 4.50],
        [48.0, 5.00],
        [56.0, 5.50],
        [64.0, 6.00]
    ]);


// Function: get_metric_iso_superfine_thread_pitch()
// Description: Returns the ISO metric standard superfine threading pitch for a given bolt `size`.
function get_metric_iso_superfine_thread_pitch(size) = lookup(size, [
        [ 1.6, 0.35],
        [ 2.0, 0.40],
        [ 2.5, 0.45],
        [ 3.0, 0.50],
        [ 4.0, 0.70],
        [ 5.0, 0.80],
        [ 6.0, 1.00],
        [ 7.0, 1.00],
        [ 8.0, 1.00],
        [10.0, 1.00],
        [12.0, 1.25],
        [14.0, 1.50],
        [16.0, 2.00],
        [18.0, 2.50],
        [20.0, 2.50],
        [22.0, 2.50],
        [24.0, 3.00],
        [27.0, 3.00],
        [30.0, 3.50],
        [33.0, 3.50],
        [36.0, 4.00],
        [39.0, 4.00],
        [42.0, 4.50],
        [45.0, 4.50],
        [48.0, 5.00],
        [56.0, 5.50],
        [64.0, 6.00]
    ]);


// Function: get_metric_jis_thread_pitch()
// Description: Returns the JIS metric standard threading pitch for a given bolt `size`.
function get_metric_jis_thread_pitch(size) = lookup(size, [
        [ 2.0, 0.40],
        [ 2.5, 0.45],
        [ 3.0, 0.50],
        [ 4.0, 0.70],
        [ 5.0, 0.80],
        [ 6.0, 1.00],
        [ 7.0, 1.00],
        [ 8.0, 1.25],
        [10.0, 1.25],
        [12.0, 1.25],
        [14.0, 1.50],
        [16.0, 1.50],
        [18.0, 1.50],
        [20.0, 1.50]
    ]);


// Function: get_metric_nut_size()
// Description: Returns the typical metric nut flat-to-flat diameter for a given bolt `size`.
function get_metric_nut_size(size) = lookup(size, [
        [ 2.0,  4.0],
        [ 2.5,  5.0],
        [ 3.0,  5.5],
        [ 4.0,  7.0],
        [ 5.0,  8.0],
        [ 6.0, 10.0],
        [ 7.0, 11.0],
        [ 8.0, 13.0],
        [10.0, 17.0],
        [12.0, 19.0],
        [14.0, 22.0],
        [16.0, 24.0],
        [18.0, 27.0],
        [20.0, 30.0]
    ]);


// Function: get_metric_nut_thickness()
// Description: Returns the typical metric nut thickness for a given bolt `size`.
function get_metric_nut_thickness(size) = lookup(size, [
        [ 1.6,  1.3],
        [ 2.0,  1.6],
        [ 2.5,  2.0],
        [ 3.0,  2.4],
        [ 4.0,  3.2],
        [ 5.0,  4.0],
        [ 6.0,  5.0],
        [ 7.0,  5.5],
        [ 8.0,  6.5],
        [10.0,  8.0],
        [12.0, 10.0],
        [14.0, 11.0],
        [16.0, 13.0],
        [18.0, 15.0],
        [20.0, 16.0],
        [24.0, 21.5],
        [30.0, 25.6],
        [36.0, 31.0],
        [42.0, 34.0],
        [48.0, 38.0],
        [56.0, 45.0],
        [64.0, 51.0]
    ]);



// Section: Modules


// Module: generic_screw()
// Description:
//   Makes a very simple screw model, useful for making screwholes.
// Usage:
//   generic_screw(screwsize, screwlen, headsize, headlen)
// Arguments:
//   screwsize = diameter of threaded part of screw.
//   screwlen = length of threaded part of screw.
//   headsize = diameter of the screw head.
//   headlen = length of the screw head.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Named Anchors:
//   "base" = At the base of the head.
//   "countersunk" = At the head height that would be just barely exposed when countersunk.
// Examples:
//   generic_screw(screwsize=3,screwlen=10,headsize=6,headlen=3, anchor="countersunk");
//   generic_screw(screwsize=3,screwlen=10,headsize=6,headlen=3, anchor="base");
// Example(FlatSpin,VPD=75): Standard Anchors
//   generic_screw(screwsize=3,screwlen=10,headsize=6,headlen=3)
//       show_anchors(5, custom=false);
// Example(FlatSpin,VPD=55): Custom Named Anchors
//   expose_anchors()
//     generic_screw(screwsize=3,screwlen=10,headsize=6,headlen=3)
//       show_anchors(5, std=false);
module generic_screw(
    screwsize=3,
    screwlen=10,
    headsize=6,
    headlen=3,
    pitch=undef,
    anchor="base",
    spin=0,
    orient=UP
) {
    sides = max(12, segs(screwsize/2));
    anchors = [
        named_anchor("countersunk", [0,0,(headlen+screwlen)/2-0.01]),
        named_anchor("base", [0,0,-headlen/2+screwlen/2])
    ];
    attachable(anchor,spin,orient, d=screwsize, l=headlen+screwlen, anchors=anchors) {
        down(headlen/2-screwlen/2) {
            down(screwlen/2) {
                if (pitch == undef) {
                    cylinder(r=screwsize/2, h=screwlen+0.05, center=true, $fn=sides);
                } else {
                    threaded_rod(d=screwsize, l=screwlen+0.05, pitch=pitch, $fn=sides);
                }
            }
            cylinder(r=headsize/2, h=headlen, center=false, $fn=sides*2);
        }
        children();
    }
}


// Module: metric_bolt()
// Description:
//   Makes a standard metric screw model.
// Arguments:
//   size = Diameter of threaded part of screw.
//   headtype = One of `"hex"`, `"pan"`, `"button"`, `"round"`, `"countersunk"`, `"oval"`, `"socket`".  Default: `"socket"`
//   l = Length of screw, except for the head.
//   shank = Length of unthreaded portion of the shaft.
//   pitch = If given, render threads of the given pitch.  If 0, then no threads.  Overrides coarse argument.
//   details = If true model should be rendered with extra details.  (Default: false)
//   coarse = If true, make coarse threads instead of fine threads.  Default = true
//   flange = Radius of flange beyond the head.  Default = 0 (no flange)
//   phillips = If given, the size of the phillips drive hole to add.  (ie: "#1", "#2", or "#3")
//   torx = If given, the size of the torx drive hole to add.  (ie: 10, 20, 30, etc.)
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Named Anchors:
//   "base" = At the base of the head.
//   "countersunk" = At the head height that would be just barely exposed when countersunk.
//   "shank" = At the bottom start of the unthreaded shank.
// Example: Bolt Head Types
//   ydistribute(40) {
//       xdistribute(30) {
//           // Front Row, Left to Right
//           metric_bolt(headtype="pan", size=10, l=15, details=true, phillips="#2");
//           metric_bolt(headtype="button", size=10, l=15, details=true, phillips="#2");
//           metric_bolt(headtype="round", size=10, l=15, details=true, phillips="#2");
//       }
//       xdistribute(30) {
//           // Back Row, Left to Right
//           metric_bolt(headtype="socket", size=10, l=15, details=true);
//           metric_bolt(headtype="hex", size=10, l=15, details=true, phillips="#2");
//           metric_bolt(headtype="countersunk", size=10, l=15, details=true, phillips="#2");
//           metric_bolt(headtype="oval", size=10, l=15, details=true, phillips="#2");
//       }
//   }
// Example: Details
//   metric_bolt(size=10, l=15, details=true, $fn=32);
// Example: No Details Except Threads
//   metric_bolt(size=10, l=15);
// Example: No Details, No Threads
//   metric_bolt(size=10, l=15, pitch=0);
// Example: Fine Threads
//   metric_bolt(size=10, l=15, coarse=false);
// Example: Flange
//   metric_bolt(size=10, l=15, flange=5);
// Example: Shank
//   metric_bolt(size=10, l=25, shank=10);
// Example: Hex Head with Phillips
//   metric_bolt(headtype="hex", size=10, l=15, phillips="#2");
// Example: Hex Head with Torx
//   metric_bolt(headtype="hex", size=10, l=15, torx=50);
// Example(FlatSpin,VPD=100): Standard Anchors
//   metric_bolt(headtype="oval", size=10, l=15, shank=5, details=true, phillips="#2")
//       show_anchors(5, custom=false);
// Example(FlatSpin,VPD=100): Custom Named Anchors
//   expose_anchors(0.125)
//     metric_bolt(headtype="oval", size=10, l=15, shank=5, details=true, phillips="#2")
//       show_anchors(5, std=false);
module metric_bolt(
    headtype="socket",
    size=3,
    l=12,
    shank=0,
    pitch=undef,
    details=false,
    coarse=true,
    phillips=undef,
    torx=undef,
    flange=0,
    anchor="base",
    spin=0,
    orient=UP
) {
    D = headtype != "hex"?
        get_metric_socket_cap_diam(size) :
        get_metric_bolt_head_size(size);
    H = headtype == "socket"?
        get_metric_socket_cap_height(size) :
        get_metric_bolt_head_height(size);
    P = coarse?
        (pitch==undef? get_metric_iso_coarse_thread_pitch(size) : pitch) :
        (pitch==undef? get_metric_iso_fine_thread_pitch(size) : pitch);
    tlen = l - min(l, shank);
    sides = max(12, segs(size/2));
    tcirc = D/cos(30);
    bevtop = (tcirc-D)/2;
    bevbot = P/2;

    headlen = (
        (headtype == "pan" || headtype == "round" || headtype == "button")? H*0.75 :
        (headtype == "countersunk")? (D-size)/2 :
        (headtype == "oval")? ((D-size)/2 + D/2/3) :
        H
    );
    base = l/2 - headlen/2;
    sunklen = (
        (headtype == "oval")? (D-size)/2 :
        headlen-0.001
    );

    anchors = [
        named_anchor("countersunk", [0,0,base+sunklen]),
        named_anchor("base",   [0,0,base]),
        named_anchor("shank",  [0,0,base-shank])
    ];

    //color("silver")
    attachable(anchor,spin,orient, d=size, l=headlen+l, anchors=anchors) {
        up(base) {
            difference() {
                union() {
                    // Head
                    if (headtype == "hex") {
                        difference() {
                            cylinder(d=tcirc, h=H, $fn=6);

                            // Bevel hex nut top
                            if (details) {
                                up(H-bevtop) {
                                    difference() {
                                        cube([tcirc+1, tcirc+1, bevtop+0.5], anchor=BOTTOM);
                                        down(0.01) cylinder(d1=tcirc, d2=tcirc-bevtop*2, h=bevtop+0.02, center=false);
                                    }
                                }
                            }
                        }
                    } else if (headtype == "socket") {
                        sockw = get_metric_socket_cap_socket_size(size);
                        sockd = get_metric_socket_cap_socket_depth(size);
                        difference() {
                            cylinder(d=D, h=H);
                            up(H-sockd) cylinder(h=sockd+0.1, d=sockw/cos(30), $fn=6);
                            if (details) {
                                kcnt = 36;
                                zrot_copies(n=kcnt, r=D/2) up(H/3) cube([PI*D/kcnt/2, PI*D/kcnt/2, H], anchor=BOTTOM);
                            }
                        }
                    } else if (headtype == "pan") {
                        cyl(l=H*0.75, d=D, rounding2=H*0.75/2, anchor=DOWN);
                    } else if (headtype == "round") {
                        top_half(D) zscale(H*0.75/D*2) sphere(d=D);
                    } else if (headtype == "button") {
                        up(H*0.75/3) top_half(D) zscale(H*0.75*2/3/D*2) sphere(d=D);
                        cylinder(d=D, h=H*0.75/3+0.01, center=false);
                    } else if (headtype == "countersunk") {
                        cylinder(h=(D-size)/2, d1=size, d2=D);
                    } else if (headtype == "oval") {
                        up((D-size)/2) top_half(D) zscale(0.333) sphere(d=D);
                        cylinder(h=(D-size)/2, d1=size, d2=D);
                    }

                    // Flange
                    if (flange>0) {
                        up(headtype == "countersunk" || headtype == "oval"? (D-size)/2 : 0) {
                            cylinder(d=D+flange, h=H/8, center=false);
                            up(H/8) cylinder(d1=D+flange, d2=D, h=H/8, center=false);
                        }
                    }

                    // Unthreaded Shank
                    if (tlen < l) {
                        down(l-tlen) cylinder(d=size, h=l-tlen+0.05, center=false, $fn=sides);
                    }

                    // Threads
                    down(l) {
                        difference() {
                            up(tlen/2+0.05) {
                                if (tlen > 0) {
                                    if (P > 0) {
                                        threaded_rod(d=size, l=tlen+0.05, pitch=P, $fn=sides);
                                    } else {
                                        cylinder(d=size, h=tlen+0.05, $fn=sides, center=true);
                                    }
                                }
                            }

                            // Bevel bottom end of threads
                            if (details) {
                                difference() {
                                    down(0.5) cube([size+1, size+1, bevbot+0.5], anchor=BOTTOM);
                                    cylinder(d1=size-bevbot*2, d2=size, h=bevbot+0.01, center=false);
                                }
                            }
                        }
                    }
                }

                // Phillips drive hole
                if (headtype != "socket" && phillips != undef) {
                    down(headtype != "hex"? H/6 : 0) {
                        phillips_mask(size=phillips); //, shaft=D);
                    }
                }

                // Torx drive hole
                if (headtype != "socket" && torx != undef) {
                    up(1) torx_mask(size=torx, l=H+0.1, center=false);
                }
            }
        }
        children();
    }
}


// Module: metric_nut()
// Description:
//   Makes a model of a standard nut for a standard metric screw.
// Arguments:
//   size = standard metric screw size in mm. (Default: 3)
//   hole = include the hole in the nut.  (Default: true)
//   pitch = pitch of threads in the hole.  No threads if not given.
//   flange = radius of flange beyond the head.  Default = 0 (no flange)
//   details = true if model should be rendered with extra details.  (Default: false)
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   center = If true, centers the nut at the origin.  If false, sits on top of XY plane.  Overrides `anchor` if given.
// Example: No details, No Hole.  Useful for a mask.
//   metric_nut(size=10, hole=false);
// Example:  Hole, with No Threads
//   metric_nut(size=10, hole=true);
// Example:  Threads
//   metric_nut(size=10, hole=true, pitch=1.5);
// Example:  Details
//   metric_nut(size=10, hole=true, pitch=1.5, details=true);
// Example:  Centered
//   metric_nut(size=10, hole=true, pitch=1.5, details=true, center=true);
// Example:  Flange
//   metric_nut(size=10, hole=true, pitch=1.5, flange=3, details=true);
module metric_nut(
    size=3,
    hole=true,
    pitch=undef,
    details=false,
    flange=0,
    center,
    anchor,
    spin=0,
    orient=UP
) {
    H = get_metric_nut_thickness(size);
    D = get_metric_nut_size(size);
    boltfn = max(12, segs(size/2));
    nutfn = max(12, segs(D/2));
    dcirc = D/cos(30);
    bevtop = (dcirc - D)/2;

    //color("silver")
    anchor = get_anchor(anchor,center,BOT,CENTER);
    attachable(anchor,spin,orient, d=dcirc+flange, l=H) {
        difference() {
            union() {
                difference() {
                    cylinder(d=dcirc, h=H, center=true, $fn=6);
                    if (details) {
                        up(H/2-bevtop) {
                            difference() {
                                cube([dcirc+1, dcirc+1, bevtop+0.5], anchor=BOTTOM);
                                down(0.01) cylinder(d1=dcirc, d2=dcirc-bevtop*2, h=bevtop+0.02, center=false, $fn=nutfn);
                            }
                        }
                        if (flange == 0) {
                            down(H/2) {
                                difference() {
                                    down(0.5) cube([dcirc+1, dcirc+1, bevtop+0.5], anchor=BOTTOM);
                                    down(0.01) cylinder(d1=dcirc-bevtop*2, d2=dcirc, h=bevtop+0.02, center=false, $fn=nutfn);
                                }
                            }
                        }
                    }
                }
                if (flange>0) {
                    down(H/2) {
                        cylinder(d=D+flange, h=H/8, center=false);
                        up(H/8) cylinder(d1=D+flange, d2=D, h=H/8, center=false);
                    }
                }
            }
            if (hole == true) {
                if (pitch == undef) {
                    cylinder(r=size/2, h=H+0.5, center=true, $fn=boltfn);
                } else {
                    threaded_rod(d=size, l=H+0.5, pitch=pitch, $fn=boltfn);
                }
            }
        }
        children();
    }
}


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
