//////////////////////////////////////////////////////////////////////
// LibFile: hooks.scad
//   Functions and modules for creating hooks and hook like parts.
// Includes:
//   include <BOSL2/std.scad>
//   include <BOSL2/hooks.scad>
// FileGroup: Parts
// FileSummary: Hooks and hook-like parts. 
//////////////////////////////////////////////////////////////////////

_BOSL2_HOOKS = is_undef(_BOSL2_STD) && (is_undef(BOSL2_NO_STD_WARNING) || !BOSL2_NO_STD_WARNING) ?
       echo("Warning: hooks.scad included without std.scad; dependencies may be missing\nSet BOSL2_NO_STD_WARNING = true to mute this warning.") true : true;


// Module: ring_hook()
// Synopsis: A hook with a circular hole or attached cylinder
// SynTags: Geom
// Topics: Parts
// See Also: prismoid(), rounded_prism(), ycyl()
// Usage:
//   ring_hook(base_size, hole_z, or, od=, [ir=], [hole=], [rounding=], [fillet=], [hole_rounding=], [anchor=], [spin=], [orient=])
// Description:
//   Form a part that attaches a loop hook with a cylindrical hole a specified distance away from its mount point.
//   You specify a rectangle defining the base a hole diameter or radius, and `hole_z`, a distance from the base to the hole.
//   You can set the hole diameter to zero to create a solid paddle with no hole.  
//   .
//   In order to calculate a tangent where the base joins the cylinder, 
//   the lower corners of the base must be outside the cylinder (see Example 3).  This scenario occurs when
//   the base is narrower than the Y-cylinder and hole_z is less than Y-cylinder radius.  Also, hole_z must 
//   be large enough to accommodate hole rounding and base rounding.
//   .
//   The roundings use `$fn`, `$fa` and `$fs`, but if you want to explicitly control the outer shape of the hook
//   you can separately specify a facet count for the curved portion using `outside_segments`.  
// Arguments:
//   base_size = 2-vector specifying x and y sizes of the base
//   hole_z = distance in the z direction from the base to the center of the hole
//   or = radius of the cylindrical portion of the part (or zero to create no hole)
//   ---
//   od = diameter of the cylindrical portion of the part
//   ir / id = optional radius/diameter of the center hole
//   wall = set thickness of the wall around the central hole
//   hole = Set to "circle" for a circle hole, "D" for a D-shaped (semicircular) hole or a path to create a custom hole.  Default: "circle"
//   rounding = rounding of the vertical-ish edges of the prismoid and the exposed edges of the cylinder.  Default: 0
//   fillet = base fillet.  If negative produces a rounded edge instead of a fillet.  Default: 0
//   hole_rounding = rounding of the optional hole.  Default: 0
//   outside_segments = number of segments to use for the outer curved part of the hook instead of using `$fn`, `$fa` and `$fs`.  
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: CENTER
//   spin = Rotate this many degrees around the Z axis.  See [spin](attachments.scad#subsection-spin).  Default: 0
//   orient = Vector to rotate top towards.  See [orient](attachments.scad#subsection-orient).  Default: UP
// Named anchors:
//   hole_front = front, center of the cylindrical portion of the part (same as the part FRONT if hole_z=or)
//   hole_back = back, center of the cylindrical portion of the part (same as the part BACK if hole_z=or)
//   tangent_right = right side anchor at the point where the prismoid merges with Y-cylinder, at y=0
//   tangent_left = left side anchor at the point where the prismoid merges with Y-cylinder, at y=0
// Attachable Parts:
//   "inside" = The inner hole (not defined if there is no hole) 
// Example: Ring connector
//   ring_hook([50, 10], 25, 25, ir=20);
// Example: Widen the base, add base fillet, no hole
//   $fa=4;$fs=1/2;
//   ring_hook([70, 10], 25, or=25, ir=0, fillet=3, rounding=1.5);
// Example: Narrow base
//   $fa=4;$fs=1/2;
//   ring_hook([40, 10], 25, or=25, ir=0, fillet=3, rounding=1.5);
// Example: Negative fillet value
//   $fa=4;$fs=1/2;
//   ring_hook([40, 10], 25, or=25, ir=0, fillet=-3, rounding=1.5);
// Example(3D,VPR=[90,0,0]): If the base is narrower than the cylinder diameter then its corners have to be outside the cylinder for this shape to be defined because it requires a tangent line to the cylinder.  This example shows a valid base corner point in blue.  An invalid corner point appears in red: no tangent to the circle exists through the red point.  
//   hole_z = 20;
//   base_size = [40, 10];
//   outer_radius = 25;
//   ring_hook(base_size, hole_z, outer_radius, ir=0);
//   up(hole_z) color("blue", 0.25) ycyl(r=outer_radius, h=base_size.y + 2);
//   right(0.5*base_size.x) color("blue") ycyl(r=1, h=base_size.y + 2, $fn=12);
//   right(0.3*base_size.x) color("red") ycyl(r=1, h=base_size.y + 2, $fn=12);
// Example(3D,VPR=[60.60,0.00,62.10]): Through hole can be specified using or/od, ir/id, wall variables.  All of these are equivalent.  
//   ydistribute(spacing = 25) {
//     ring_hook([50, 10], 40, or=25, ir=20);
//     ring_hook([50, 10], 40, 25, wall=5);
//     ring_hook([50, 10], 40, wall=5, ir=20);
//     ring_hook([50, 10], 40, od=50, id=40);
//     ring_hook([50, 10], 40, od=50, wall=5);
//     ring_hook([50, 10], 40, wall=5, id=40);
//   }
// Example: Semi-circular through hole (a D-hole):
//   ring_hook([50, 10], 12, 25, ir=15, hole="D", rounding=3, hole_rounding=3, fillet=2);
// Example: hole_z must be greater than 0 with no hole or with hole="D".  Here hole_z is 1, close to the minimum value of zero.  
//   xdistribute(spacing=60){
//     ring_hook([50, 10], 1, 25, ir=0);
//     ring_hook([50, 10], 1, 25, ir=15, hole="D");
//   }
// Example: hole_z must be greater than ir + hole_rounding + fillet when hole="circle".  Here hole_z is only 1 larger than the minimum.
//    $fs=1;$fa=5;
//    ring_hook([50, 10], hole_z=27, or=25, ir=20, hole_rounding=3, fillet=3);
// Example: Rounding all edges
//   ring_hook([50, 10], 40, 25, ir=15, rounding=5, hole_rounding=5, fillet=5);
// Example: Giving an arbitrary path for the hole, in this case an octagon to make the object printable without support.  
//   ring_hook([50, 20],30, 25, hole=octagon(side=10,realign=true), hole_rounding=3, rounding=4) ;
// Example: Using `outside_segments`
//   $fs=.2;$fa=2;
//   ring_hook(base_size=[40,10],hole_z=14, od=29,hole=rect(12),
//             rounding=1,hole_rounding=1,fillet=1,outside_segments=3);
// Example(3D,Med): The ring_hook includes 4 custom anchors: front & back at the center of the cylinder component and left & right at the tangent points.
//   ring_hook([55, 10], 12, 25, ir=0) show_anchors(std=false);
// Example: Use the custom anchor to place a screw hole
//   include <BOSL2/screws.scad>
//   diff()
//   ring_hook([20, 10], 15, 7, ir=0, fillet=3) 
//      attach("hole_front") 
//        screw_hole("M5", length=20, head="socket", atype="head", anchor=TOP, orient=UP);
// Example: Use the custom anchor to create a cylindrical extension instead of a hole
//  $fs=1;$fa=2;
//  ring_hook([30,10], hole_z=17, or=10, ir=0, rounding=1.5)
//     attach("hole_front", BOT)
//       cyl(d=10, h=14, rounding1=-2, rounding2=2);
// Example(3D,VPR=[83.70,0.00,29.20]): Use the "inner" part to create a bar across the hole:
//   diff() 
//   ring_hook([50, 20],30, 25, ir=10, hole_rounding=3, rounding=4) 
//     attach_part("inner") 
//     prism_connector( circle(3, $fn=16), 
//        parent(), LEFT, 
//        parent(), RIGHT, fillet=1);


function ring_hook(base_size, hole_z, or, ir, od, id, wall, hole="circle",
            rounding=0, fillet=0, hole_rounding=0, outside_segments,
            anchor=BOTTOM, spin=0, orient=UP) = no_function("ring_hook");
module ring_hook(base_size, hole_z, or, ir, od, id, wall, hole="circle",
            rounding=0, fillet=0, hole_rounding=0, outside_segments,
            anchor=BOTTOM, spin=0, orient=UP)
{
    or_tmp = get_radius(r=or, d=od);
    ir_tmp = get_radius(r=ir, d=id);
    dummy = assert(is_path(hole) || num_defined([ir_tmp, or_tmp, wall])==2,
                   "Must define exactly two of or/od, ir/id and wall (unless you give a custom hole)")
            assert(!is_path(hole) || num_defined([ir_tmp, wall])==0,
                   "Canot define ir/id or wall with a custom hole");
    ir = is_path(hole) ? 0
        : is_def(ir_tmp) ? ir_tmp
        : or_tmp - wall;
    or = is_def(or_tmp) ? or_tmp : ir + wall;
    dummy2 = assert(is_path(hole) || ir <= or, "Hole doesn't fit or wall size is negative")
             assert(sqrt((0.5*base_size.x)^2 + hole_z^2) > or, "Base corners must be outside the cylinder")
             assert(in_list(hole,["circle","D"]) || is_path(hole,2), "hole must be \"circle\", \"D\" or a 2d path")
             assert(is_undef(outside_segments) || outside_segments>=2, "outside_segments must be at least 2")
             assert(all_nonnegative([hole_rounding]), "hole_rounding must be greater than or equal to 0");
    
    if (ir > 0 && hole=="circle")
       assert(ir + hole_rounding < hole_z-fillet,str("ir + hole_rounding must be less than ",hole_z-fillet));

    z_offset = (hole_z - or)/2;
    tangents = circle_point_tangents(
        r=or, 
        cp=[0,hole_z], 
        pt=[0.5*base_size.x, 0]);

    // we want the tangent with the larger y value
    tangent = tangents[0].y > tangents[1].y
            ? tangents[0] : tangents[1];
            
    // anchor calcs
    angle = atan((tangent.x - 0.5*base_size.x)/tangent.y);
    top_x = 0.5*base_size.x + (hole_z + or)*tan(angle);
    // when or > 0.5*base_size.x, need to move the anchor
    // use x^2 + y^2 = r^2, x = sqrt(r^2 - y^2)
    delta_y = z_offset;
    mid_x = sqrt(or^2 - delta_y^2);
    
    h = hole_z + or;
    w = base_size.y;
    size = [base_size.x, w];
    size2 = [2*top_x, w];

    right_tang_dir = unit([tangent.x, 0, tangent.y-hole_z]);
    left_tang_dir =  unit([-tangent.x,0, tangent.y-hole_z]);

    prism_steps = segs(max(rounding,abs(fillet)),90);
    hole_rounding_steps = segs(hole_rounding,90);

    anchors = [
        named_anchor("hole_front", [0, -w/2, z_offset], FRONT, 0),
        named_anchor("hole_back", [0, w/2, z_offset], BACK, 180),
        named_anchor("tangent_right", [tangent[0], 0, tangent[1] - hole_z + z_offset], right_tang_dir, _compute_spin(right_tang_dir,UP,BACK)),
        named_anchor("tangent_left", [-tangent[0], 0, tangent[1] - hole_z + z_offset], left_tang_dir, _compute_spin(left_tang_dir,UP,BACK)),
    ];
    override = [
        for (i = [-1, 1], j=[-1:1], k=[0:1])
            if (k==0 && j!=0 && or > 0.5*base_size.x)
                [[i, j, 0], 
                [mid_x*unit([i, 0, 0]) + 0.5*base_size.y*unit([0, j, 0])]]
            else if (k==0 && or > 0.5*base_size.x) 
                [[i, 0, 0], [mid_x*unit([i, 0, 0])]]
            else if (k==1 && j==0) 
                [[i, 0, 1], [or*sin(45)*unit([i, 0, 0]) 
                            + (z_offset + or*sin(45))*unit([0, 0, k])]]
            else if (k==1)
                [[i, j, 1], [or*sin(45)*unit([i, 0, 0]) 
                                + 0.5*base_size.y*unit([0, j, 0])
                                + (z_offset + or*sin(45))*unit([0, 0, k])]]
    ];



    hole = is_path(hole) ? hole
            : hole=="D" ? arc(angle=180, r=ir, rounding=hole_rounding, wedge=true)
            : ir > 0 ? circle(ir)
            : undef;
    
    parts = is_undef(hole) ? undef
          :[
            define_part("inner",
                        attach_geom(
                                    region=[ymove(z_offset,hole)], l=size.y), 
                                    T=xrot(90),
                                    inside=true)
           ];
    
    attachable( anchor, spin, orient, 
                size=point3d(size,h),
                size2=size2,
                anchors=anchors, 
                override=override,
                parts=parts
    ) {
        down(h/2) 
        difference() {
            union() {
                startangle = atan2(tangent.y-hole_z, tangent.x);
                endangle = posmod(atan2(tangent.y-hole_z, -tangent.x),360);
                steps = 1+first_defined([outside_segments,segs(or,endangle-startangle)]);
                delta = (endangle-startangle)/(steps-1);

                
                profile = rounding == 0 ? [[or,0,-base_size.y/2],[or,0,base_size.y/2]]
                        : let(
                               // rounded prism roundings are computed on top face, so cos() correction is needed
                               // to get them to align properly
                               bez = _smooth_bez_fill([//[or-rounding*(startangle>0?cos(startangle):1),0,-base_size.y/2],
                                                       [or-rounding,0,-base_size.y/2],
                                                       [or,0,-base_size.y/2],
                                                       [or,0,-base_size.y/2+rounding]],0.92),
                               pts = bezier_curve(bez,splinesteps=prism_steps)
                          )
                          concat(pts, reverse(zflip(pts)));
                
                toplist = [
                           [for(pt=profile) [0,-or,pt.z]],
                           if (startangle<0)
                             move(-[tangent.x-base_size.x/2,tangent.y] ,zrot(startangle, profile)),
                           for(angle = lerpn(startangle, endangle, steps)) zrot(angle, profile),
                           if (startangle<0)
                             move(-[-tangent.x+base_size.x/2,tangent.y] ,zrot(endangle, profile)),
                          ];
                intersection(){
                  up(hole_z)xrot(90)
                     vnf_vertex_array(transpose(toplist),caps=true,col_wrap=true,reverse=true,triangulate=true);
                  up(abs(fillet))cuboid([max(base_size.x,2*or),w+1, or+hole_z+1],anchor=BOT);
                }

                // When base is outside the circle the base needs to be clipped so the roundings don't interfere
                // This mask does this clipping
                maskpath2 = [zrot(startangle,[or+1,0,0]),
                            zrot(startangle,[or-rounding, 0, 0]),
                            zrot(startangle+delta, [or-rounding-.1, 0, 0]),
                 ];
                maskpath = up(hole_z,xrot(90, [each maskpath2,
                           [maskpath2[0].x, maskpath2[0].x*tan(startangle+delta),0]
                          ]));
               
                difference(){
                  rounded_prism(
                      rect(base_size), 
                      rect( [ 2*tangent.x, w ] ), 
                      h=tangent.y, 
                      joint_bot=-fillet, 
                      joint_sides=rounding, 
                      k_sides=0.92, k_bot=0.92,
                      anchor=BOT,splinesteps=prism_steps);
                  if (startangle>0)
                      xflip_copy()
                        vnf_vertex_array([fwd(w/2+1, maskpath), back(w/2+1, maskpath)],
                                         col_wrap=true,caps=true,reverse=true);
                }
            }
            
            if (is_def(hole)) {
                up(hole_z) 
                prism_connector( 
                    hole, 
                    parent(), FRONT, 
                    parent(), BACK, 
                    fillet=hole_rounding, n=hole_rounding_steps);
            }
        }
        children();
    }
}


// Module: s_hook()
// Synopsis: Creates an S-shaped hook
// SynTags: Geom
// Topics: Parts, Hooks
// See Also: ring_hook()
// Usage:
//   s_hook(or, [sides], [l_shaft=], [r_loop1=], [angle1=], [r_loop2=], [angle2=], ...) [ATTACHMENTS];
// Description:
//   Creates an S-shaped hook by sweeping a cross-section profile along a turtle-graphics path.
//   The hook consists of a central shaft with configurable loops on each end.  Each loop can
//   have an optional straight stem extension and a reverse curl.  The cross-section can be a
//   regular polygon (controlled by `sides`) or a circle (when `sides` < 3).
//   .
//   The hook is oriented along the Y axis, centered at the origin.  The +Y end has loop1 and
//   the -Y end has loop2.  By default both loops curve 180 degrees creating a classic S shape.
//   .
//   End caps are generated using rotate_sweep to close the ends of the swept shape cleanly.
// Arguments:
//   or = outside radius of the cross-section shape.  Default: 2
//   sides = number of sides for the cross-section polygon.  Values less than 3 produce a circle.  Default: 6
//   ---
//   l_shaft = length of the straight central shaft.  Default: 25
//   r_loop1 = radius of the loop at the +Y end.  Default: 5
//   angle1 = arc angle in degrees for loop1.  Default: 180
//   l_stem1 = length of straight segment after loop1.  Default: 0
//   r_curl1 = radius of the reverse curl at the +Y end.  Default: 0
//   angle_curl1 = arc angle in degrees for curl1.  Default: 0
//   r_loop2 = radius of the loop at the -Y end.  Default: 5
//   angle2 = arc angle in degrees for loop2.  Default: 180
//   l_stem2 = length of straight segment after loop2.  Default: 0
//   r_curl2 = radius of the reverse curl at the -Y end.  Default: 0
//   angle_curl2 = arc angle in degrees for curl2.  Default: 0
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: CENTER
//   spin = Rotate this many degrees around the Z axis.  See [spin](attachments.scad#subsection-spin).  Default: 0
//   orient = Vector to rotate top towards.  See [orient](attachments.scad#subsection-orient).  Default: UP
// Example(3D): Default S-hook with hexagonal cross-section
//   s_hook();
// Example(3D): Circular cross-section
//   s_hook(sides=0);
// Example(3D): Longer shaft
//   s_hook(l_shaft=50);
// Example(3D): Larger loop on +Y end
//   s_hook(r_loop1=12);
// Example(3D): Added stem on +Y end
//   s_hook(l_stem1=5);
// Example(3D): Stem and curl on -Y end
//   s_hook(l_stem2=4, r_curl2=5, angle_curl2=70);
// Example(3D): Extended arc with curl
//   s_hook(sides=0, angle1=230, l_stem1=3, r_curl1=3, angle_curl1=90);
// Example(3D): Asymmetric hook
//   s_hook(or=3, r_loop1=10, angle1=220, r_loop2=6, angle2=160, l_shaft=30);

function s_hook(or=2, sides=6, l_shaft=25,
    r_loop1=5, angle1=180, l_stem1=0, r_curl1=0, angle_curl1=0,
    r_loop2=5, angle2=180, l_stem2=0, r_curl2=0, angle_curl2=0,
    anchor=CENTER, spin=0, orient=UP) = no_function("s_hook");
module s_hook(or=2, sides=6, l_shaft=25,
    r_loop1=5, angle1=180, l_stem1=0, r_curl1=0, angle_curl1=0,
    r_loop2=5, angle2=180, l_stem2=0, r_curl2=0, angle_curl2=0,
    anchor=CENTER, spin=0, orient=UP)
{
    dummy = assert(is_finite(l_shaft) && l_shaft > 0, "l_shaft must be positive")
            assert(is_int(sides), "sides must be an integer")
            assert(is_finite(or) && or > 0, "or must be positive")
            assert(is_finite(r_loop1) && r_loop1 >= 0, "r_loop1 must be non-negative")
            assert(is_finite(r_loop2) && r_loop2 >= 0, "r_loop2 must be non-negative")
            assert(is_finite(angle1) && angle1 >= 0, "angle1 must be non-negative")
            assert(is_finite(angle2) && angle2 >= 0, "angle2 must be non-negative");
    _stem1 = max(l_stem1, 1e-10);
    _stem2 = max(l_stem2, 1e-10);
    shape = sides > 2 ? regular_ngon(sides, or, align_side=FWD) : circle(or);
    path1 = turtle(["setdir", 90, "ymove", l_shaft/2,
                     "arcleft", r_loop1, angle1,
                     "move", _stem1,
                     "arcright", r_curl1, angle_curl1]);
    path2 = turtle(["setdir", -90, "ymove", -l_shaft/2,
                     "arcleft", r_loop2, angle2,
                     "move", _stem2,
                     "arcright", r_curl2, angle_curl2]);
    all_pts = concat(path1, path2);
    bnds = pointlist_bounds(all_pts);
    sz = [bnds[1].x - bnds[0].x + 2*or,
          bnds[1].y - bnds[0].y + 2*or,
          2*or];
    off = [(bnds[0].x + bnds[1].x)/2,
           (bnds[0].y + bnds[1].y)/2,
           0];
    endcap = right_half(shape);
    anchors = [
        named_anchor("loop1", point3d(last(path1)), UP),
        named_anchor("loop2", point3d(last(path2)), DOWN),
        named_anchor("shaft_top", [0, l_shaft/2, 0], BACK),
        named_anchor("shaft_bot", [0, -l_shaft/2, 0], FWD),
    ];
    attachable(anchor, spin, orient, size=sz, offset=off, anchors=anchors) {
        union() {
            path_sweep(shape, path1);
            path_sweep(shape, path2);
            move(last(path1)) rotate_sweep(endcap);
            move(last(path2)) rotate_sweep(endcap);
        }
        children();
    }
}


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
