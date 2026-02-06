//////////////////////////////////////////////////////////////////////
// LibFile: hooks.scad
//   Functions and modules for creating hooks and hook like parts.
//   At the moment only one part is supported, a ring hook.  
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


