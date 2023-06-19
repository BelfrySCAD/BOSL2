//////////////////////////////////////////////////////////////////////
// LibFile: screw_drive.scad
//   Masks for Phillips, Torx and square (Robertson) driver holes.
// Includes:
//   include <BOSL2/std.scad>
//   include <BOSL2/screw_drive.scad>
// FileGroup: Threaded Parts
// FileSummary: Masks for Phillips, Torx and square (Robertson) driver holes.
//////////////////////////////////////////////////////////////////////


include <structs.scad>

// Section: Phillips Drive

// Module: phillips_mask()
// Synopsis: Creates a mask for a Philips screw drive.
// SynTags: Geom
// Topics: Screws, Masks
// See Also: hex_drive_mask(), phillips_depth(), phillips_diam(), torx_mask(), robertson_mask()
// Usage:
//   phillips_mask(size) [ATTACHMENTS];
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
    dummy = assert(in_list(size,["#0","#1","#2","#3","#4",0,1,2,3,4]));
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
// Synopsis: Returns the depth a phillips recess needs to be for a given diameter.
// Topics: Screws, Masks
// See Also: phillips_mask(), hex_drive_mask(), phillips_depth(), phillips_diam(), torx_mask()
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
// Synopsis: Returns the diameter of a phillips recess of a given depth.
// Topics: Screws, Masks
// See Also: phillips_mask(), hex_drive_mask(), phillips_depth(), phillips_diam(), torx_mask()
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


// Section: Hex drive

// Module: hex_drive_mask()
// Synopsis: Creates a mask for a hex drive recess.
// SynTags: Geom
// Topics: Screws, Masks
// See Also: phillips_mask(), hex_drive_mask(), torx_mask(),  phillips_depth(), phillips_diam(), robertson_mask()
// Usage:
//   hex_drive_mask(size, length, [anchor], [spin], [orient], [$slop]) [ATTACHMENTS];
// Description:
//   Creates a mask for hex drive.  Note that the hex recess specs requires
//   a slightly oversized recess.  You can use $slop to increase the size by 
//   `2 * $slop` if necessary.  
// 
module hex_drive_mask(size,length,l,h,height,anchor,spin,orient)
{
   length = one_defined([length,height,l,h],"length,height,l,h");
   realsize = 1.0072*size + 0.0341 + 2 * get_slop();  // Formula emperically determined from ISO standard
   linear_sweep(height=length,hexagon(id=realsize),anchor=anchor,spin=spin,orient=orient) children();
}
function hex_drive_mask(size,length,l,h,height,anchor,spin,orient) = no_function("hex_drive_mask");


// Section: Torx Drive

// Module: torx_mask()
// Synopsis: Creates a mask for a torx drive recess.
// SynTags: Geom
// Topics: Screws, Masks
// See Also: phillips_mask(), hex_drive_mask(), torx_mask(),  phillips_depth(), phillips_diam(), robertson_mask()
// Usage:
//   torx_mask(size, l, [center]) [ATTACHMENTS];
// Description: Creates a torx bit tip.  The anchors are located on the circumscribing cylinder.  See {{torx_info()}} for allowed sizes.
// Arguments:
//   size = Torx size.
//   l = Length of bit.
//   center = If true, centers mask vertically.
//   ---
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Examples:
//   torx_mask(size=30, l=10, $fa=1, $fs=1);
module torx_mask(size, l=5, center, anchor, spin=0, orient=UP) {
    od = torx_diam(size);
    anchor = get_anchor(anchor, center, BOT, BOT);
    attachable(anchor,spin,orient, d=od, l=l) {
        linear_extrude(height=l, convexity=4, center=true) {
            torx_mask2d(size);
        }
        children();
    }
}


// Module: torx_mask2d()
// Synopsis: Creates the 2D cross section for a torx drive recess.
// SynTags: Geom
// Topics: Screws, Masks
// See Also: phillips_mask(), hex_drive_mask(), torx_mask(),  phillips_depth(), phillips_diam(), torx_info(), robertson_mask()
// Usage:
//   torx_mask2d(size);
// Description: Creates a torx bit 2D profile.  The anchors are located on the circumscribing circle.   See {{torx_info()}} for allowed sizes.
// Arguments:
//   size = Torx size.
// Example(2D):
//   torx_mask2d(size=30, $fa=1, $fs=1);
module torx_mask2d(size,anchor=CENTER,spin) {
    info = torx_info(size);
    od = info[0];
    id = info[1];
    tip = info[3];
    rounding = info[4];
    base = od - 2*tip;
    $fn = quantup(segs(od/2),12);
    attachable(anchor,spin,two_d=true,d=od){
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
        children();
    }
}


// Function: torx_info()
// Synopsis: Returns the dimensions of a torx drive.
// Topics: Screws, Masks
// See Also: phillips_mask(), hex_drive_mask(), torx_mask(),  phillips_depth(), phillips_diam(), torx_info()
// Usage:
//   info = torx_info(size);
// Description:
//   Get the typical dimensional info for a given Torx size.
//   Returns a list containing, in order:
//   - Outer Diameter
//   - Inner Diameter
//   - Drive Hole Depth
//   - External Tip Rounding Radius
//   - Inner Rounding Radius
// .
//   The allowed torx sizes are:
//   1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 15, 20, 25, 27, 30, 40, 45, 50, 55,
//   60, 70, 80, 90, 100.
// Arguments:
//   size = Torx size.
function torx_info(size) =
    let( 
        info_arr = [      // Depth is from metric socket head screws, ISO 14583
            //T#     OD     ID     H        Re     Ri
            [  1, [  0.90,  0.65,  0.40,  0.059, 0.201]],  // depth interpolated
            [  2, [  1.00,  0.73,  0.44,  0.069, 0.224]],  // depth interpolated
            [  3, [  1.20,  0.87,  0.53,  0.081, 0.266]],  // depth interpolated
            [  4, [  1.35,  0.98,  0.59,  0.090, 0.308]],  // depth interpolated
            [  5, [  1.48,  1.08,  0.65,  0.109, 0.330]],  // depth interpolated
            [  6, [  1.75,  1.27,  0.775, 0.132, 0.383]],
            [  7, [  2.08,  1.50,  0.886, 0.161, 0.446]],  // depth interpolated
            [  8, [  2.40,  1.75,  1.0,   0.190, 0.510]],
            [  9, [  2.58,  1.87,  1.078, 0.207, 0.554]],  // depth interpolated
            [ 10, [  2.80,  2.05,  1.142, 0.229, 0.598]],
            [ 15, [  3.35,  2.40,  1.2,   0.267, 0.716]],  // depth interpolated
            [ 20, [  3.95,  2.85,  1.4,   0.305, 0.859]],  // depth interpolated
            [ 25, [  4.50,  3.25,  1.61,  0.375, 0.920]],  
            [ 27, [  5.07,  3.65,  1.84,  0.390, 1.108]],
            [ 30, [  5.60,  4.05,  2.22,  0.451, 1.194]],
            [ 40, [  6.75,  4.85,  2.63,  0.546, 1.428]],
            [ 45, [  7.93,  5.64,  3.115, 0.574, 1.796]],
            [ 50, [  8.95,  6.45,  3.82,  0.775, 1.816]],
            [ 55, [ 11.35,  8.05,  5.015, 0.867, 2.667]],
            [ 60, [ 13.45,  9.60,  5.805, 1.067, 2.883]],
            [ 70, [ 15.70, 11.20,  6.815, 1.194, 3.477]],
            [ 80, [ 17.75, 12.80,  7.75,  1.526, 3.627]],
            [ 90, [ 20.20, 14.40,  8.945, 1.530, 4.468]],
            [100, [ 22.40, 16.00, 10.79,  1.720, 4.925]],
        ],
        found = struct_val(info_arr,size)
    )
    assert(found, str("Unsupported Torx size, ",size))
    found;


// Function: torx_diam()
// Synopsis: Returns the diameter of a torx drive.
// Topics: Screws, Masks
// See Also: phillips_mask(), hex_drive_mask(), torx_mask(),  phillips_depth(), phillips_diam(), torx_info()
// Usage:
//   diam = torx_diam(size);
// Description: Get the typical outer diameter of Torx profile.
// Arguments:
//   size = Torx size.
function torx_diam(size) = torx_info(size)[0];


// Function: torx_depth()
// Synopsis: Returns the typical depth of a torx drive recess.
// Topics: Screws, Masks
// See Also: phillips_mask(), hex_drive_mask(), torx_mask(),  phillips_depth(), phillips_diam(), torx_info()
// Usage:
//   depth = torx_depth(size);
// Description: Gets typical drive hole depth.
// Arguments:
//   size = Torx size.
function torx_depth(size) = torx_info(size)[2];



// Section: Robertson/Square Drives

// Module: robertson_mask()
// Synopsis: Creates a mask for a Robertson/Square drive recess.
// SynTags: Geom
// Topics: Screws, Masks
// See Also: phillips_mask(), hex_drive_mask(), torx_mask(),  phillips_depth(), phillips_diam(), torx_info(), robertson_mask()
// Usage:
//   robertson_mask(size, [extra], [ang], [$slop=]);
// Description:
//   Creates a mask for creating a Robertson/Square drive recess given the drive size as an integer.
//   The width of the recess will be oversized by `2 * $slop`.  Note that this model is based
//   on an incomplete spec.   https://www.aspenfasteners.com/content/pdf/square_drive_specification.pdf
//   We determined the angle by doing print tests on a Prusa MK3S with $slop set to 0.05.
// Arguments:
//   size = The size of the square drive, as an integer from 0 to 4.
//   extra = Extra length of drive mask to create.
//   ang = taper angle of each face.  Default: 2.5
//   ---
//   $slop = enlarge recess by this twice amount.  Default: 0
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: TOP
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Side Effects:
//   Sets tag to "remove" if no tag is set.  
// Example:
//   robertson_mask(size=2);
// Example:
//   difference() {
//       cyl(d1=2, d2=8, h=4, anchor=TOP);
//       robertson_mask(size=2);
//   }
module robertson_mask(size, extra=1, ang=2.5,anchor=TOP,spin,orient) {
    dummy=assert(is_int(size) && size>=0 && size<=4);
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
    Mtop = Mslop + 2*adj_ang_to_opp(F+extra,ang);
    Mbot = Mslop - 2*adj_ang_to_opp(T-F,ang);
    anchors = [named_anchor("standard",[0,0,T-h/2], UP, 0)];
    default_tag("remove")
      attachable(anchor,spin,orient,size=[Mbot,Mbot,T],size2=[Mtop,Mtop],anchors=anchors){
        down(T/2)
            intersection(){
                prismoid([Mbot,Mbot],[Mtop,Mtop],h=h,anchor=BOT);
                cyl(d1=0, d2=Mslop/(T-F)*sqrt(2)*h, h=h, anchor=BOT);
            }
        children();
      }
}



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
