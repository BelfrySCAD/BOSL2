//////////////////////////////////////////////////////////////////////
// LibFile: screw_drive.scad
//   Masks for Phillips, Torx and square (Robertson) driver holes.
// Includes:
//   include <BOSL2/std.scad>
//   include <BOSL2/screw_drive.scad>
// FileGroup: Threaded Parts
// FileSummary: Masks for Phillips, Torx and square (Robertson) driver holes.
//////////////////////////////////////////////////////////////////////


// Section: Phillips Drive

// Module: phillips_mask()
// Usage: phillips_mask(size) [ATTACHMENTS];
// Description:
//   Creates a mask for creating a Phillips drive recess given the Phillips size.  Each mask can
//   be lowered to different depths to create different sizes of recess.  
// Arguments:
//   size = The size of the bit as an integer or string.  "#0", "#1", "#2", "#3", or "#4"
//   ---
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Example:
//   xdistribute(10) {
//      phillips_mask(size="#1");
//      phillips_mask(size="#2");
//      phillips_mask(size=3);
//      phillips_mask(size=4);
//   }

// Specs for phillips recess here:
//   https://www.fasteners.eu/tech-info/ISO/4757/

function _phillips_shaft(x) = [3,4.5,6,8,10][x];
function _ph_bot_angle() = 28.0;
function _ph_side_angle() = 26.5;

module phillips_mask(size="#2", $fn=36, anchor=BOTTOM, spin=0, orient=UP) {
    assert(in_list(size,["#0","#1","#2","#3","#4",0,1,2,3,4]));
    num = is_num(size) ? size : ord(size[1]) - ord("0");
    shaft = _phillips_shaft(num);
    b =     [0.61, 0.97, 1.47, 2.41, 3.48][num];
    e =     [0.31, 0.435, 0.815, 2.005, 2.415][num];
    g =     [0.81, 1.27, 2.29, 3.81, 5.08][num];
    alpha = [ 136,  138,  140,  146,  153][num];
    beta  = [7.00, 7.00, 5.75, 5.75, 7.00][num];
    gamma = 92.0;
    h1 = adj_ang_to_opp(g/2, _ph_bot_angle());   // height of the small conical tip
    h2 = adj_ang_to_opp((shaft-g)/2, 90-_ph_side_angle());   // height of larger cone
    l = h1+h2;
    h3 = adj_ang_to_opp(b/2, _ph_bot_angle());   // height where cutout starts
    p0 = [0,0];
    p1 = [adj_ang_to_opp(e/2, 90-alpha/2), -e/2];
    p2 = p1 + [adj_ang_to_opp((shaft-e)/2, 90-gamma/2),-(shaft-e)/2];
    attachable(anchor,spin,orient, d=shaft, l=l) {
        down(l/2) {
            difference() {
                rotate_extrude()
                    polygon([[0,0],[g/2,h1],[shaft/2,l],[0,l]]);
                zrot(45)
                zrot_copies(n=4, r=b/2) {                   
                    up(h3) {
                        yrot(beta) {
                            down(1)
                            linear_extrude(height=l+2, convexity=4, center=false) {
                                path = [p0, p1, p2, [p2.x,-p2.y], [p1.x,-p1.y]];
                                polygon(path);
                            }
                        }
                    }
                }
            }
        }
        children();
    }
}



// Function: phillips_depth()
// Usage:
//   depth = phillips_depth(size, d);
// Description:
//   Returns the depth of the Phillips recess required to produce the specified diameter, or
//   undef if not possible.
// Arguments:
//   size = size as a number or text string like "#2"
//   d = desired diameter
function phillips_depth(size, d) =
    assert(in_list(size,["#0","#1","#2","#3","#4",0,1,2,3,4]))
    let(
        num = is_num(size) ? size : ord(size[1]) - ord("0"),
        shaft = [3,4.5,6,8,10][num],
        g =     [0.81, 1.27, 2.29, 3.81, 5.08][num],
        h1 = adj_ang_to_opp(g/2, _ph_bot_angle()),   // height of the small conical tip
        h2 = adj_ang_to_opp((shaft-g)/2, 90-_ph_side_angle())   // height of larger cone
    )
    d>=shaft || d<g ? undef :
    (d-g) / 2 / tan(_ph_side_angle()) + h1;


// Function: phillips_diam()
// Usage:
//   diam = phillips_diam(size, depth);
// Description:
//   Returns the diameter at the top of the Phillips recess when constructed at the specified depth,
//   or undef if that depth is not valid.  
// Arguments:
//   size = size as number or text string like "#2"
//   depth = depth of recess to find the diameter of
function phillips_diam(size, depth) =
    assert(in_list(size,["#0","#1","#2","#3","#4",0,1,2,3,4]))
    let(
        num = is_num(size) ? size : ord(size[1]) - ord("0"),
        shaft = _phillips_shaft(num),
        g =     [0.81, 1.27, 2.29, 3.81, 5.08][num],
        h1 = adj_ang_to_opp(g/2, _ph_bot_angle()),   // height of the small conical tip
        h2 = adj_ang_to_opp((shaft-g)/2, 90-_ph_side_angle())   // height of larger cone
    )
    depth<h1 || depth>= h1+h2 ? undef :
    2 * tan(_ph_side_angle())*(depth-h1) + g;



// Section: Torx Drive



// Module: torx_mask()
// Usage:
//   torx_mask(size, l, [center]) [ATTACHMENTS];
// Description: Creates a torx bit tip.
// Arguments:
//   size = Torx size.
//   l = Length of bit.
//   center = If true, centers bit vertically.
//   ---
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Examples:
//   torx_mask(size=30, l=10, $fa=1, $fs=1);
module torx_mask(size, l=5, center, anchor, spin=0, orient=UP) {
    anchor = get_anchor(anchor, center, BOT, BOT);
    od = torx_diam(size);
    attachable(anchor,spin,orient, d=od, l=l) {
        linear_extrude(height=l, convexity=4, center=true) {
            torx_mask2d(size);
        }
        children();
    }
}



// Module: torx_mask2d()
// Usage:
//   torx_mask2d(size);
// Description: Creates a torx bit 2D profile.
// Arguments:
//   size = Torx size.
// Example(2D):
//   torx_mask2d(size=30, $fa=1, $fs=1);
module torx_mask2d(size) {
    no_children($children);
    od = torx_diam(size);
    id = _torx_inner_diam(size);
    tip = _torx_tip_radius(size);
    rounding = _torx_rounding_radius(size);
    base = od - 2*tip;
    $fn = quantup(segs(od/2),12);
    difference() {
        union() {
            circle(d=base);
            zrot_copies(n=2) {
                hull() {
                    zrot_copies(n=3) {
                        translate([base/2,0,0]) {
                            circle(r=tip, $fn=$fn/2);
                        }
                    }
                }
            }
        }
        zrot_copies(n=6) {
            zrot(180/6) {
                translate([id/2+rounding,0,0]) {
                    circle(r=rounding);
                }
            }
        }
    }
}


// Function: torx_diam()
// Usage:
//   diam = torx_diam(size);
// Description: Get the typical outer diameter of Torx profile.
// Arguments:
//   size = Torx size.
function torx_diam(size) = lookup(size, [
    [  6,  1.75],
    [  8,  2.40],
    [ 10,  2.80],
    [ 15,  3.35],
    [ 20,  3.95],
    [ 25,  4.50],
    [ 30,  5.60],
    [ 40,  6.75],
    [ 45,  7.93],
    [ 50,  8.95],
    [ 55, 11.35],
    [ 60, 13.45],
    [ 70, 15.70],
    [ 80, 17.75],
    [ 90, 20.20],
    [100, 22.40]
]);
 

/// Internal Function: torx_inner_diam()
/// Usage:
///   diam = torx_inner_diam(size);
/// Description: Get typical inner diameter of Torx profile.
/// Arguments:
///   size = Torx size.
function _torx_inner_diam(size) = lookup(size, [
    [  6,  1.27],
    [  8,  1.75],
    [ 10,  2.05],
    [ 15,  2.40],
    [ 20,  2.85],
    [ 25,  3.25],
    [ 30,  4.05],
    [ 40,  4.85],
    [ 45,  5.64],
    [ 50,  6.45],
    [ 55,  8.05],
    [ 60,  9.60],
    [ 70, 11.20],
    [ 80, 12.80],
    [ 90, 14.40],
    [100, 16.00]
]);
 

// Function: torx_depth()
// Usage:
//   depth = torx_depth(size);
// Description: Gets typical drive hole depth.
// Arguments:
//   size = Torx size.
function torx_depth(size) = lookup(size, [
    [  6,  1.82],
    [  8,  3.05],
    [ 10,  3.56],
    [ 15,  3.81],
    [ 20,  4.07],
    [ 25,  4.45],
    [ 30,  4.95],
    [ 40,  5.59],
    [ 45,  6.22],
    [ 50,  6.48],
    [ 55,  6.73],
    [ 60,  8.17],
    [ 70,  8.96],
    [ 80,  9.90],
    [ 90, 10.56],
    [100, 11.35]
]);
 

/// Internal Function: torx_tip_radius()
/// Usage:
///   rad = torx_tip_radius(size);
/// Description: Gets minor rounding radius of Torx profile.
/// Arguments:
///   size = Torx size.
function _torx_tip_radius(size) = lookup(size, [
    [  6, 0.132],
    [  8, 0.190],
    [ 10, 0.229],
    [ 15, 0.267],
    [ 20, 0.305],
    [ 25, 0.375],
    [ 30, 0.451],
    [ 40, 0.546],
    [ 45, 0.574],
    [ 50, 0.775],
    [ 55, 0.867],
    [ 60, 1.067],
    [ 70, 1.194],
    [ 80, 1.526],
    [ 90, 1.530],
    [100, 1.720]
]);


/// Internal Function: torx_rounding_radius()
/// Usage:
///   rad = torx_rounding_radius(size);
/// Description: Gets major rounding radius of Torx profile.
/// Arguments:
///   size = Torx size.
function _torx_rounding_radius(size) = lookup(size, [
    [  6, 0.383],
    [  8, 0.510],
    [ 10, 0.598],
    [ 15, 0.716],
    [ 20, 0.859],
    [ 25, 0.920],
    [ 30, 1.194],
    [ 40, 1.428],
    [ 45, 1.796],
    [ 50, 1.816],
    [ 55, 2.667],
    [ 60, 2.883],
    [ 70, 3.477],
    [ 80, 3.627],
    [ 90, 4.468],
    [100, 4.925]
]);




// Section: Robertson/Square Drives

// Module: robertson_mask()
// Usage:
//   robertson_mask(size, [extra]);
// Description:
//   Creates a mask for creating a Robertson/Square drive recess given the drive size as an integer.
//   The width of the recess will be oversized by `2 * $slop`.  Note that this model is based
//   on an incomplete spec.   https://www.aspenfasteners.com/content/pdf/square_drive_specification.pdf
//   We determined the angle by doing print tests on a Prusa MK3S with $slop set to 0.05.
// Arguments:
//   size = The size of the square drive, as an integer from 0 to 4.
//   extra = Extra length of drive mask to create.
//   ang = taper angle of each face.  Default: 2.5
//   $slop = enlarge recess by this twice amount.  Default: 0
// Example:
//   robertson_mask(size=2);
// Example:
//   difference() {
//       cyl(d1=2, d2=8, h=4, anchor=TOP);
//       robertson_mask(size=2);
//   }
module robertson_mask(size, extra=1, ang=2.5) {
    assert(is_int(size) && size>=0 && size<=4);
    Mmin = [0.0696, 0.0900, 0.1110, 0.1315, 0.1895][size];
    Mmax = [0.0710, 0.0910, 0.1126, 0.1330, 0.1910][size];
    M = (Mmin + Mmax) / 2 * INCH;
    Tmin = [0.063, 0.105, 0.119, 0.155, 0.191][size];
    Tmax = [0.073, 0.113, 0.140, 0.165, 0.201][size];
    T = (Tmin + Tmax) / 2 * INCH;
    Fmin = [0.032, 0.057, 0.065, 0.085, 0.090][size];
    Fmax = [0.038, 0.065, 0.075, 0.095, 0.100][size];
    F = (Fmin + Fmax) / 2 * INCH;
    h = T + extra;
    Mslop=M+2*get_slop();
    down(T) {
        intersection(){
            Mtop = Mslop + 2*adj_ang_to_opp(F+extra,ang);
            Mbot = Mslop - 2*adj_ang_to_opp(T-F,ang);
            prismoid([Mbot,Mbot],[Mtop,Mtop],h=h,anchor=BOT);
            cyl(d1=0, d2=Mslop/(T-F)*sqrt(2)*h, h=h, anchor=BOT);
        }
    }
}



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
