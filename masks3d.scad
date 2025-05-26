//////////////////////////////////////////////////////////////////////
// LibFile: masks3d.scad
//   This file defines 3D masks for applying chamfers, roundovers, and teardrop roundovers to straight edges and circular
//   edges in three dimensions.  
// Includes:
//   include <BOSL2/std.scad>
// FileGroup: Basic Modeling
// FileSummary: 3D masks for rounding or chamfering edges and corners.
// FileFootnotes: STD=Included in std.scad
//////////////////////////////////////////////////////////////////////


// Section: Chamfer Masks


// Module: chamfer_edge_mask()
// Synopsis: Creates a shape to chamfer a 90° edge.
// SynTags: Geom
// Topics: Masking, Chamfers, Shapes (3D)
// See Also: chamfer_corner_mask(), chamfer_cylinder_mask(), chamfer_edge_mask(), default_tag(), diff()
// Usage:
//   chamfer_edge_mask(l|h=|length=|height=, chamfer, [excess]) [ATTACHMENTS];
// Description:
//   Creates a shape that can be used to chamfer a 90° edge.
//   Difference it from the object to be chamfered.  The center of
//   the mask object should align exactly with the edge to be chamfered.
// Arguments:
//   l/h/length/height = Length of mask.  Default: $edge_length if defined
//   chamfer = Size of chamfer.
//   excess = The extra amount to add to the length of the mask so that it differences away from other shapes cleanly.  Default: `0.1`
//   ---
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Side Effects:
//   Tags the children with "remove" (and hence sets `$tag`) if no tag is already set.
// Example:
//   chamfer_edge_mask(l=50, chamfer=10);
// Example:
//   difference() {
//       cube(50, anchor=BOTTOM+FRONT);
//       #chamfer_edge_mask(l=50, chamfer=10, orient=RIGHT);
//   }
// Example: Masking by Attachment
//   diff()
//   cube(50, center=true) {
//       edge_mask(TOP+RIGHT)
//           #chamfer_edge_mask(l=50, chamfer=10);
//   }
function chamfer_edge_mask(l, chamfer=1, excess=0.1, h, length, height, anchor=CENTER, spin=0, orient=UP) = no_function("chamfer_edge_mask");
module chamfer_edge_mask(l, chamfer=1, excess=0.1, h, length, height, anchor=CENTER, spin=0, orient=UP) {
    l = is_def($edge_length) && !any_defined([l,length,h,height]) ? $edge_length
      : one_defined([l,length,h,height],"l,length,h,height");
    default_tag("remove") {
        attachable(anchor,spin,orient, size=[chamfer*2, chamfer*2, l]) {
            cylinder(r=chamfer, h=l+excess, center=true, $fn=4);
            children();
        }
    }
}


// Module: chamfer_corner_mask()
// Synopsis: Creates a shape to chamfer a 90° corner.
// SynTags: Geom
// Topics: Masking, Chamfers, Shapes (3D)
// See Also: chamfer_corner_mask(), chamfer_cylinder_mask(), chamfer_edge_mask(), default_tag(), diff()
// Usage:
//   chamfer_corner_mask(chamfer) [ATTACHMENTS];
// Description:
//   Creates a shape that can be used to chamfer a 90° corner.
//   Difference it from the object to be chamfered.  The center of
//   the mask object should align exactly with the corner to be chamfered.
// Arguments:
//   chamfer = Size of chamfer.
//   ---
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Side Effects:
//   Tags the children with "remove" (and hence sets `$tag`) if no tag is already set.
// Example:
//   chamfer_corner_mask(chamfer=10);
// Example:
//   difference() {
//       cuboid(50, chamfer=10, trimcorners=false);
//       move(25*[1,-1,1]) #chamfer_corner_mask(chamfer=10);
//   }
// Example: Masking by Attachment
//   diff()
//   cuboid(100, chamfer=20, trimcorners=false) {
//       corner_mask(TOP+FWD+RIGHT)
//           chamfer_corner_mask(chamfer=20);
//   }
// Example: Anchors
//   chamfer_corner_mask(chamfer=20)
//       show_anchors();
function chamfer_corner_mask(chamfer=1, anchor=CENTER, spin=0, orient=UP) = no_function("chamfer_corner_mask");
module chamfer_corner_mask(chamfer=1, anchor=CENTER, spin=0, orient=UP) {
    default_tag("remove") {
        octahedron(chamfer*4, anchor=anchor, spin=spin, orient=orient) children();
    }
}


// Module: chamfer_cylinder_mask()
// Synopsis: Creates a shape to chamfer the end of a cylinder.
// SynTags: Geom
// Topics: Masking, Chamfers, Cylinders
// See Also: chamfer_corner_mask(), chamfer_cylinder_mask(), chamfer_edge_mask(), default_tag(), diff()
// Usage:
//   chamfer_cylinder_mask(r|d=, chamfer, [ang], [from_end]) [ATTACHMENTS];
// Description:
//   Create a mask that can be used to bevel/chamfer the end of a cylindrical region.
//   Difference it from the end of the region to be chamfered.  The center of the mask
//   object should align exactly with the center of the end of the cylindrical region
//   to be chamfered.
// Arguments:
//   r = Radius of cylinder to chamfer.
//   chamfer = Size of the edge chamfered, inset from edge.
//   ---
//   d = Diameter of cylinder to chamfer. Use instead of r.
//   ang = Angle of chamfer in degrees from the horizontal.  (Default: 45)
//   from_end = If true, chamfer size is measured from end of cylinder.  If false, chamfer is measured outset from the radius of the cylinder.  (Default: false)
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Side Effects:
//   Tags the children with "remove" (and hence sets `$tag`) if no tag is already set.
// Example:
//   difference() {
//       cylinder(r=50, h=100, center=true);
//       up(50) #chamfer_cylinder_mask(r=50, chamfer=10);
//   }
// Example:
//   difference() {
//       cylinder(r=50, h=100, center=true);
//       up(50) chamfer_cylinder_mask(r=50, chamfer=10);
//   }
// Example: Changing the chamfer angle
//   difference() {
//       cylinder(r=50, h=100, center=true);
//       up(50) #chamfer_cylinder_mask(r=50, chamfer=10, ang=70);
//   }
// Example:
//   difference() {
//       cylinder(r=50, h=100, center=true);
//       up(50) chamfer_cylinder_mask(r=50, chamfer=10, ang=70);
//   }
// Example: Masking by Attachment
//   diff()
//   cyl(d=100,h=40)
//      attach([TOP,BOT])
//         tag("remove")chamfer_cylinder_mask(d=100, chamfer=10);
function chamfer_cylinder_mask(r, chamfer, d, ang=45, from_end=false, anchor=CENTER, spin=0, orient=UP) = no_function("chamfer_cylinder_mask");
module chamfer_cylinder_mask(r, chamfer, d, ang=45, from_end=false, anchor=CENTER, spin=0, orient=UP)
{
    r = get_radius(r=r, d=d, dflt=1);
    dummy = assert(all_nonnegative([chamfer]), "Chamfer must be a nonnegative number");
    ch = from_end? chamfer : opp_ang_to_adj(chamfer,90-ang);
    default_tag("remove"){
        attachable(anchor,spin,orient, r=r, l=ch*2) {
            difference() {
                cyl(r=r+chamfer, l=ch*2, anchor=CENTER);
                cyl(r=r, l=ch*3, chamfer=chamfer, chamfang=ang, from_end=from_end, anchor=TOP);
            }
            children();
        }
    }
}


// Section: Rounding Masks

// Module: rounding_edge_mask()
// Synopsis: Creates a shape to round an arbitrary 3d edge.
// SynTags: Geom
// Topics: Masks, Rounding, Shapes (3D)
// See Also: edge_profile(), rounding_corner_mask(), default_tag(), diff() 
// Usage:
//   rounding_edge_mask(l|h=|length=|height=, r|d=, [ang], [excess=], [rounding=|chamfer=], ) [ATTACHMENTS];
//   rounding_edge_mask(l|h=|length=|height=, r1=|d1=, r2=|d2=, [ang=], [excess=], [rounding=|chamfer=]) [ATTACHMENTS];
// Description:
//   Creates a mask shape that can be used to round a straight edge at any angle, with
//   different rounding radii at each end.  The corner of the mask appears on the Z axis with one face on the XZ plane.
//   You must align the mask corner with the edge you want to round.  If your parent object is a cuboid, the easiest way to
//   do this is to use {{diff()}} and {{edge_mask()}}.  However, this method is somewhat inflexible regarding orientation of a tapered
//   mask, and it does not support other parent shapes.  You can attach the mask to a larger range of shapes using 
//   {{attach()}} to anchor the `LEFT+FWD` anchor of the mask to a desired corner on the parent with `inside=true`.
//   Many shapes propagate `$edge_angle` and `$edge_length` which can aid in configuring the mask, and you can adjust the
//   mask as needed to align the taper as desired.  The default "remove" tag is set so {{diff()}} will automatically difference
//   away the mask.  You can of course also position the mask manually and use `difference()`.
//   .
//   For mating with other roundings or chamfers on cuboids or regular prisms, you can choose end roundings and end chamfers.  These affect
//   only the curved edge of the mask ends and will only work if the terminating face is perpendicular to the masked edge.  The `excess`
//   parameter will add extra length to the mask when you use these settings.  
//   
// Arguments:
//   l/h/length/height = Length of mask.  Default: $edge_length if defined
//   r = Radius of the rounding.
//   ang = Angle between faces for rounding.  Default: $edge_angle if defined, otherwise 90
//   ---
//   r1 = Bottom radius of rounding.
//   r2 = Top radius of rounding.
//   d = Diameter of the rounding.
//   d1 = Bottom diameter of rounding.
//   d2 = Top diameter of rounding.
//   excess = Extra size for the mask.  Defaults: 0.1
//   rounding = Radius of roundong along ends.  Default: 0
//   rounding1 = Radius of rounding along bottom end
//   rounding2 = Radius of rounding along top end
//   chamfer = Chamfer size of end chamfers.  Default: 0
//   chamfer1 = Chamfer size of chamfer at bottom end
//   chamfer2 = Chamfer size of chamfer at top end
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Side Effects:
//   Tags the children with "remove" (and hence sets `$tag`) if no tag is already set.
// Example(VPD=200,VPR=[55,0,120]):
//   rounding_edge_mask(l=50, r=15);
// Example(VPD=200,VPR=[55,0,120]): With different radii at each end
//   rounding_edge_mask(l=50, r1=10, r2=25);
// Example(VPD=200,VPR=[55,0,120]): Acute angle
//   rounding_edge_mask(l=50, r=10, ang=45);
// Example(VPD=200,VPR=[55,0,120]): A large excess
//   rounding_edge_mask(l=50, r=15,excess=4);
// Example: Subtracting from a cube
//   difference() {
//       cube(size=100, center=false);
//       #rounding_edge_mask(l=100, r=25, anchor=BOTTOM);
//   }
// Example: Varying Rounding Radius
//   difference() {
//       cube(size=50, center=false);
//       down(1)rounding_edge_mask(l=52, r1=25, r2=10, anchor=BOTTOM);
//   }
// Example: Angle not 90 degrees
//   difference() {
//       pie_slice(ang=70, h=50, d=100, center=true);
//       #rounding_edge_mask(h=51, r=20.0, ang=70, $fn=32);
//   }
// Example: Varying Rounding Radius
//   difference() {
//       pie_slice(ang=70, h=50, d=100, center=true);
//       #rounding_edge_mask(h=51, r1=10, r2=25, ang=70, $fn=32);
//   }
// Example: Rounding a non-right angled edge, with a zero radius at the bottom.  
//   difference(){
//     linear_extrude(height=50)xflip(x=25)right_triangle([50,50]);
//     rounding_edge_mask(l=51, ang=45, r1=0, r2=15, anchor=BOT);
//   }
// Example: Masking by Attachment
//   diff()
//   cube(100, center=true)
//       edge_mask(FRONT+RIGHT)
//           #rounding_edge_mask(l=$parent_size.z+0.01, r=25);
// Example: Multiple Masking by Attachment
//   diff()
//   cube([80,90,100], center=true) {
//       let(p = $parent_size*1.01) {
//           edge_mask(TOP)
//               rounding_edge_mask(l=p.z, r=25);
//       }
//   }
// Example(3D,VPT=[5.02872,6.37039,-0.503894],VPR=[75.3,0,107.4],VPD=74.4017): Mask shape with end rounding at the top, chamfer at the bottom, and a large excess value:
//   rounding_edge_mask(r=10,h=20, chamfer1=3, rounding2=3, excess=1);
// Example(3D,VPT=[1.05892,1.10442,2.20513],VPR=[60.6,0,118.1],VPD=74.4017): Attaching masks using {{attach()}} with automatic angle and length from the parent.  Note that sometimes the automatic length is too short because it is the length of the edge itself.  
//   diff()
//   prismoid([20,30],[12,19], h=10,shift=[4,7])
//     attach([TOP+RIGHT,RIGHT+FRONT],LEFT+FWD,inside=true)
//       rounding_edge_mask(r1=2,r2=4);
// Example(3D): The mask does not need to be the full length of the edge
//   diff()
//   cuboid(20)
//     attach(RIGHT+TOP,LEFT+FWD,inside=true,inset=-.1,align=FWD)
//       rounding_edge_mask(r1=0,r2=10,length=10);

function rounding_edge_mask(l, r, ang=90, r1, r2, d, d1, d2, excess=0.1, anchor=CENTER, spin=0, orient=UP, h,height,length) = no_function("rounding_edge_mask");
module rounding_edge_mask(l, r, ang, r1, r2, excess=0.01, d1, d2,d,r,length, h, height, anchor=CENTER, spin=0, orient=UP,
                          rounding,rounding1,rounding2,chamfer,chamfer1,chamfer2,
                         _remove_tag=true)
{
    ang = first_defined([ang,$edge_angle,90]);
    length = is_def($edge_length) && !any_defined([l,length,h,height]) ? $edge_length
           : one_defined([l,length,h,height],"l,length,h,height");
    r1 = get_radius(r1=r1, d1=d1,d=d,r=r);
    r2 = get_radius(r2=r2, d1=d2,d=d,r=r);
    dummy1 = assert(num_defined([chamfer,rounding])<2, "Cannot give both rounding and chamfer")
            assert(num_defined([chamfer1,rounding1])<2, "Cannot give both rounding1 and chamfer1")
            assert(num_defined([chamfer2,rounding2])<2, "Cannot give both rounding2 and chamfer2");
    rounding1 = first_defined([rounding1,rounding,0]);
    rounding2 = first_defined([rounding2,rounding,0]);
    chamfer1 = first_defined([chamfer1,chamfer,0]);
    chamfer2 = first_defined([chamfer2,chamfer,0]);
    dummy = assert(all_nonnegative([r1,r2]), "radius/diameter value(s) must be nonnegative")
            assert(all_positive([length]), "length/l/h/height must be a positive value")
            assert(is_finite(ang) && ang>0 && ang<180, "ang must be a number between 0 and 180")
            assert(all_nonnegative([chamfer1,chamfer2,rounding1,rounding2]), "chamfers and roundings must be nonnegative");
    steps = ceil(segs(max(r1,r2))*(180-ang)/360);
    function make_path(r) =
         r==0 ? repeat([0,0],steps+1)
              : arc(n=steps+1, r=r, corner=[polar_to_xy(r,ang),[0,0],[r,0]]);
    path1 = path3d(make_path(r1),-length/2);
    path2 = path3d(make_path(r2),length/2);

    function getarc(bigr,r,chamfer,p1,p2,h,print=false) =
      r==0 && chamfer==0? [p2]
    :  
      let(
          steps = ceil(segs(r)/4)+1,
          center = [bigr/tan(ang/2), bigr,h],
          refplane = plane_from_normal([-(p2-center).y, (p2-center).x, 0], p2),
          refnormal = plane_normal(refplane), 
          mplane = plane3pt(p2,p1,center),
          A = plane_normal(mplane),
          basept = lerp(p2,p1,max(r,chamfer)/2/h),
          corner = [basept+refnormal*(refplane[3]-basept*refnormal)/(refnormal*refnormal),
                    p2,
                    center],
          bare_arc = chamfer ? [p2+chamfer*unit(corner[0]-corner[1]),p2+chamfer*unit(corner[2]-corner[1])]
                  : arc(r=r, corner = corner, n=steps),
          arc_with_excess = [each bare_arc, up(excess, last(bare_arc))], 
          arc = [for(pt=arc_with_excess) pt+refnormal*(mplane[3]-pt*A)/(refnormal*A)]
      )
      arc;
    cp = [-excess/tan(ang/2), -excess];
    extra1 = rounding1 || chamfer1 ? [0,0,excess] : CTR;
    extra2 = rounding2 || chamfer2 ? [0,0,excess] : CTR;    
    pathlist = [for(i=[0:len(path1)-1])
                  let(
                       path = [
                               if (i==0) move(polar_to_xy( excess, 90+ang),path1[i]-extra1)
                                 else if (i==len(path1)-1) fwd(excess,last(path1)-extra1)
                                 else point3d(cp,-length/2-extra1.z),
                               each reverse(zflip(getarc(r1,rounding1,chamfer1,zflip(path2[i]), zflip(path1[i]),length/2))),
                               each getarc(r2,rounding2,chamfer2,path1[i],path2[i],length/2,print=rounding2!=0&&!is_undef(rounding2)&&i==3),
                               if (i==0) move(polar_to_xy( excess, 90+ang),path2[i]+extra2)
                                 else if (i==len(path2)-1) fwd(excess,last(path2)+extra2)
                                 else point3d(cp, length/2+extra2.z),
                       ]
                   )
                   path];

    left_normal = cylindrical_to_xyz(1,90+ang,0);
    left_dir = cylindrical_to_xyz(1,ang,0);
    zdir = unit([length, 0,-(r2-r1)/tan(ang/2)]);
    cutfact = 1/sin(ang/2)-1;

    v=unit(zrot(ang,zdir)+left_normal);
    ref = UP - (v*UP)*v;
    backleft_spin=-vector_angle(rot(from=UP,to=v,p=BACK),ref);

    override = [
       [CENTER, [CENTER,UP]],
       [TOP, [[0,0,length/2]]],
       [BOT, [[0,0,-length/2]]],
       [FWD, [[(r1+r2)/tan(ang/2)/4,0,0]]],
       [FWD+BOT, [[r1/tan(ang/2)/2,0,-length/2]]],
       [FWD+TOP, [[r2/tan(ang/2)/2,0,length/2]]],
       [LEFT, [(r1+r2)/tan(ang/2)/4*left_dir, left_normal,ang-180]],
       [LEFT+BOT, [down(length/2,r1/tan(ang/2)/2*left_dir), rot(v=left_dir,-45,p=left_normal),ang-180]],
       [LEFT+TOP, [up(length/2,r2/tan(ang/2)/2*left_dir), rot(v=left_dir, 45, p=left_normal),ang-180]],
       [LEFT+FWD, [CENTER, left_normal+FWD,ang/2-90]],
       [LEFT+FWD+TOP, [[0,0,length/2], left_normal+FWD+UP,ang/2-90]],
       [LEFT+FWD+BOT, [[0,0,-length/2], left_normal+FWD+DOWN,ang/2-90]],
       [RIGHT, [[(r1+r2)/2/tan(ang/2),0,0],zdir]],
       [RIGHT+TOP, [[r2/tan(ang/2),0,length/2],zdir+UP]],
       [RIGHT+BOT, [[r1/tan(ang/2),0,-length/2],zdir+DOWN]],
       [RIGHT+FWD, [[(r1+r2)/2/tan(ang/2),0,0],zdir+FWD]],
       [RIGHT+TOP+FWD, [[r2/tan(ang/2),0,length/2],zdir+UP+FWD]],
       [RIGHT+BOT+FWD, [[r1/tan(ang/2),0,-length/2],zdir+DOWN+FWD]],
       [BACK, [ (r1+r2)/2/tan(ang/2)*left_dir,zrot(ang,zdir),ang+90]],
       [BACK+BOT, [ down(length/2,r1/tan(ang/2)*left_dir),zrot(ang,zdir)+DOWN,ang+90]],
       [BACK+UP, [ up(length/2,r2/tan(ang/2)*left_dir),zrot(ang,zdir)+UP,ang+90]],              
       [BACK+LEFT, [ (r1+r2)/2/tan(ang/2)*left_dir,zrot(ang,zdir)+left_normal, backleft_spin]],
       [BACK+BOT+LEFT, [ down(length/2,r1/tan(ang/2)*left_dir),zrot(ang,zdir)+left_normal+DOWN,backleft_spin]],
       [BACK+UP+LEFT, [ up(length/2,r2/tan(ang/2)*left_dir),zrot(ang,zdir)+left_normal+UP,backleft_spin]],
       [BACK+RIGHT, [cylindrical_to_xyz(cutfact*(r1+r2)/2,ang/2,0), zrot(ang/2,zdir),ang/2+90]],
       [BACK+RIGHT+TOP, [cylindrical_to_xyz(cutfact*r2,ang/2,length/2), zrot(ang/2,zdir)+UP,ang/2+90]],
       [BACK+RIGHT+BOT, [cylindrical_to_xyz(cutfact*r1,ang/2,-length/2), zrot(ang/2,zdir)+DOWN,ang/2+90]],
       ];
    vnf = vnf_vertex_array(reverse(pathlist), col_wrap=true,caps=true);
    default_tag("remove", _remove_tag)
      attachable(anchor,spin,orient,size=[1,1,length],override=override){
        vnf_polyhedron(vnf);
        children();
      }
}



// Module: rounding_corner_mask()
// Synopsis: Creates a shape to round 90° corners.
// SynTags: Geom
// Topics: Masking, Rounding, Shapes (3D)
// See Also: rounding_edge_mask(), default_tag(), diff()
// Usage:
//   rounding_corner_mask(r|d, [ang], [excess=], [style=]) [ATTACHMENTS];
// Description:
//   Creates a shape that you can use to round corners where the top and bottom faces are parallel and the two side
//   faces are perpendicular to the top and bottom, e.g. cubes or pie_slice corners.  
//   Difference it from the object to be rounded.  The center of the mask
//   object should align exactly with the corner to be rounded.
// Arguments:
//   r = Radius of corner rounding.
//   ang = Angle of corner (measured around the z axis).  Default: 90
//   ---
//   d = Diameter of corner rounding.
//   excess = Extra size for the mask.  Defaults: 0.1
//   style = The style of the sphere cutout's construction. One of "orig", "aligned", "stagger", "octa", or "icosa".  Default: "octa"
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Side Effects:
//   Tags the children with "remove" (and hence sets `$tag`) if no tag is already set.
// Example:
//   rounding_corner_mask(r=20);
// Example: Adding a huge excess
//   rounding_corner_mask(r=20, excess=5);
// Example: Position masks manually
//   difference() {
//       cube(size=[50, 60, 70], center=true);
//       translate([-25, -30, 35])
//           #rounding_corner_mask(r=20, spin=90, orient=DOWN);
//       translate([25, -30, 35])
//           #rounding_corner_mask(r=20, orient=DOWN);
//       translate([25, -30, -35])
//           #rounding_corner_mask(r=20, spin=90);
//   }
// Example: Masking by Attachment
//   diff()
//   cube(size=[50, 60, 70]) {
//       corner_mask(TOP)
//           #rounding_corner_mask(r=20);
//   }
// Example(VPR=[71.8,0,345.8],VPT=[57.0174,43.8496,24.5863],VPD=263.435,NoScales): Acute angle 
//   ang=60;
//   difference() {
//       pie_slice(ang=ang, h=50, r=100);
//       zflip_copy(z=25)
//          #rounding_corner_mask(r=20, ang=ang);
//   }
// Example(VPR=[62.7,0,5.4],VPT=[6.9671,22.7592,20.7513],VPD=192.044): Obtuse angle 
//   ang=120;
//   difference() {
//       pie_slice(ang=ang, h=50, r=30);
//       zflip_copy(z=25)
//          #rounding_corner_mask(r=20, ang=ang);
//   }

function rounding_corner_mask(r, ang, d, style="octa", excess=0.1, anchor=CENTER, spin=0, orient=UP) = no_function("rounding_corner_mask");
module rounding_corner_mask(r, ang=90, d, style="octa", excess=0.1, anchor=CENTER, spin=0, orient=UP)
{
    r = get_radius(r=r, d=d, dflt=1);
    joint = r/tan(ang/2);
    path = [
             [joint,r],
             [joint,-excess],
             [-excess/tan(ang/2),-excess],
             polar_to_xy(joint,ang)+polar_to_xy(excess,90+ang)
           ];
    default_tag("remove") {
        attachable(anchor,spin,orient, size=[2,2,2]*r) {
            difference() {
                down(excess)
                    linear_extrude(height=r+excess) polygon(path);
                translate([joint,r,r])
                    spheroid(r=r, style=style);
            }
            children();
        }
    }
}


function rounding_angled_edge_mask(h, r, r1, r2, d, d1, d2, ang=90, anchor=CENTER, spin=0, orient=UP,l,height,length) = no_function("rounding_angled_edge_mask");
module rounding_angled_edge_mask(h, r, r1, r2, d, d1, d2, ang=90, anchor=CENTER, spin=0, orient=UP,l,height,length)
{
    deprecate("angled_edge_mask");
    rounding_edge_mask(h=h,r=r,r1=r1,r2=r2,d=d,d1=d1,d2=d1,ang=ang,anchor=anchor,spin=spin,orient=orient,l=l,height=height,length=length)
      children();
}


function rounding_angled_corner_mask(r, ang=90, d, anchor=CENTER, spin=0, orient=UP) = no_function("rounding_angled_corner_mask");
module rounding_angled_corner_mask(r, ang=90, d, anchor=CENTER, spin=0, orient=UP)
{
    deprecate("rounding_corner_mask");
    zflip()rounding_corner_mask(r=r,ang=ang,d=d,anchor=anchor,spin=spin,orient=orient)
       children();
}


// Module: rounding_cylinder_mask()
// Synopsis: Creates a shape to round the end of a cylinder.
// SynTags: Geom
// Topics: Masking, Rounding, Cylinders
// See Also: rounding_hole_mask(), rounding_corner_mask(), default_tag(), diff()
// Usage:
//   rounding_cylinder_mask(r|d=, rounding);
// Description:
//   Create a mask that can be used to round the end of a cylinder.
//   Difference it from the cylinder to be rounded.  The center of the
//   mask object should align exactly with the center of the end of the
//   cylinder to be rounded.
// Arguments:
//   r = Radius of cylinder.
//   rounding = Radius of the edge rounding.
//   ---
//   d = Diameter of cylinder.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Side Effects:
//   Tags the children with "remove" (and hence sets `$tag`) if no tag is already set.
// Example:
//   difference() {
//     cylinder(r=50, h=50, center=false);
//     up(50) #rounding_cylinder_mask(r=50, rounding=10);
//   }
// Example:
//   difference() {
//     cylinder(r=50, h=50, center=false);
//     up(50) rounding_cylinder_mask(r=50, rounding=10);
//   }
// Example: Masking by Attachment
//   diff()
//   cyl(h=30, d=30) {
//       attach(TOP)
//         #tag("remove")
//           rounding_cylinder_mask(d=30, rounding=5);
//   }
function rounding_cylinder_mask(r, rounding, d, anchor, spin, orient) = no_function("rounding_cylinder_mask");
module rounding_cylinder_mask(r, rounding, d, anchor=CENTER, spin=0, orient=UP)
{
    r = get_radius(r=r, d=d, dflt=1);
    default_tag("remove") {
        attachable(anchor,spin,orient, r=r+rounding, l=rounding*2) {
            difference() {
                cyl(r=r+rounding, l=rounding*2, anchor=CENTER);
                cyl(r=r, l=rounding*3, rounding=rounding, anchor=TOP);
            }
            children();
        }
    }
}



// Module: rounding_hole_mask()
// Synopsis: Creates a shape to round the edge of a round hole.
// SynTags: Geom
// Topics: Masking, Rounding
// See Also: rounding_cylinder_mask(), rounding_hole_mask(), rounding_corner_mask(), default_tag(), diff()
// Usage:
//   rounding_hole_mask(r|d, rounding, [excess]) [ATTACHMENTS];
// Description:
//   Create a mask that can be used to round the edge of a circular hole.
//   Difference it from the hole to be rounded.  The center of the
//   mask object should align exactly with the center of the end of the
//   hole to be rounded.
// Arguments:
//   r = Radius of hole.
//   rounding = Radius of the rounding.
//   excess = The extra thickness of the mask.  Default: `0.1`.
//   ---
//   d = Diameter of hole to rounding.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Side Effects:
//   Tags the children with "remove" (and hence sets `$tag`) if no tag is already set.
// Example:
//   rounding_hole_mask(r=40, rounding=20, $fa=2, $fs=2);
// Example(Med):
//   difference() {
//     cube([150,150,100], center=true);
//     cylinder(r=50, h=100.1, center=true);
//     up(50) #rounding_hole_mask(r=50, rounding=10);
//   }
// Example(Med):
//   difference() {
//     cube([150,150,100], center=true);
//     cylinder(r=50, h=100.1, center=true);
//     up(50) rounding_hole_mask(r=50, rounding=10);
//   }
function rounding_hole_mask(r, rounding, excess=0.1, d, anchor=CENTER, spin=0, orient=UP) = no_function("rounding_hole_mask");
module rounding_hole_mask(r, rounding, excess=0.1, d, anchor=CENTER, spin=0, orient=UP)
{
    r = get_radius(r=r, d=d, dflt=1);
    default_tag("remove") {
        attachable(anchor,spin,orient, r=r+rounding, l=2*rounding) {
            rotate_extrude(convexity=4) {
                difference() {
                    right(r-excess) fwd(rounding) square(rounding+excess, center=false);
                    right(r+rounding) fwd(rounding) circle(r=rounding);
                }
            }
            children();
        }
    }
}


// Section: Teardrop Masking

// Module: teardrop_edge_mask()
// Synopsis: Creates a shape to round a 90° edge but limit the angle of overhang.
// SynTags: Geom
// Topics: Masking, Rounding, Shapes (3D), FDM Optimized
// See Also: teardrop_corner_mask(), teardrop_edge_mask(), default_tag(), diff()
// Usage:
//   teardrop_edge_mask(l|h=|length=|height=, r|d=, [angle], [excess], [anchor], [spin], [orient]) [ATTACHMENTS];
// Description:
//   Makes an apropriate 3D edge rounding mask that keeps within `angle` degrees of vertical.
// Arguments:
//   l/h/length/height = length of mask
//   r = Radius of the mask rounding.
//   angle = Maximum angle from vertical. Default: 45
//   excess = Excess mask size.  Default: 0.1
//   ---
//   d = Diameter of the mask rounding.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Side Effects:
//   Tags the children with "remove" (and hence sets `$tag`) if no tag is already set.
// Example(VPD=50,VPR=[55,0,120]):
//   teardrop_edge_mask(l=20, r=10, angle=40);
// Example(VPD=300,VPR=[75,0,25]):
//   diff()
//   cuboid([50,60,70],rounding=10,edges="Z",anchor=CENTER) {
//       edge_mask(BOT)
//           teardrop_edge_mask(l=max($parent_size)+1, r=10, angle=40);
//       corner_mask(BOT)
//           teardrop_corner_mask(r=10, angle=40);
//   }
function teardrop_edge_mask(l, r, angle=45, excess=0.1, d, anchor, spin, orient,h,height,length) = no_function("teardrop_edge_mask");
module teardrop_edge_mask(l, r, angle=45, excess=0.1, d, anchor=CTR, spin=0, orient=UP,h,height,length)
{
    l = one_defined([l, h, height, length], "l,h,height,length");
    check = 
      assert(is_num(l) && l>0, "Length of mask must be positive")
      assert(is_num(angle) && angle>0 && angle<90, "Angle must be a number between 0 and 90")
      assert(is_num(excess));
    r = get_radius(r=r, d=d, dflt=1);
    path = mask2d_teardrop(r=r, angle=angle, excess=excess);
    default_tag("remove") {
        linear_sweep(path, height=l, center=true, atype="bbox", anchor=anchor, spin=spin, orient=orient) children();
    }
}


// Module: teardrop_corner_mask()
// Synopsis: Creates a shape to round a 90° corner but limit the angle of overhang.
// SynTags: Geom
// Topics: Masking, Rounding, Shapes (3D), FDM Optimized
// See Also: teardrop_corner_mask(), teardrop_edge_mask(), default_tag(), diff()
// Usage:
//   teardrop_corner_mask(r|d=, [angle], [excess], [anchor], [spin], [orient]) [ATTACHMENTS];
// Description:
//   Makes an apropriate 3D corner rounding mask that keeps within `angle` degrees of vertical.
// Arguments:
//   r = Radius of the mask rounding.
//   angle = Maximum angle from vertical. Default: 45
//   excess = Excess mask size.  Default: 0.1
//   ---
//   d = Diameter of the mask rounding.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Side Effects:
//   Tags the children with "remove" (and hence sets `$tag`) if no tag is already set.
// Example:
//   teardrop_corner_mask(r=20, angle=40);
// Example:
//   diff()
//   cuboid([50,60,70],rounding=10,edges="Z",anchor=CENTER) {
//       edge_profile(BOT)
//           mask2d_teardrop(r=10, angle=40);
//       corner_mask(BOT)
//           teardrop_corner_mask(r=10, angle=40);
//   }
function teardrop_corner_mask(r, angle=45, excess=0.1, d, anchor, spin, orient) = no_function("teardrop_corner_mask");
module teardrop_corner_mask(r, angle=45, excess=0.1, d, anchor=CTR, spin=0, orient=UP)
{  
    assert(is_num(angle));
    assert(is_num(excess));
    assert(angle>0 && angle<90);
    r = get_radius(r=r, d=d, dflt=1);
    size = (r+excess) * [1,1,1];
    midpt = (r-excess)/2 * [1,1,1];
    default_tag("remove") {
        attachable(anchor,spin,orient, size=size, offset=midpt) {
            difference() {
                translate(-[1,1,1]*excess) cube(r+excess, center=false);
                translate([1,1,1]*r) onion(r=r, ang=angle, orient=DOWN);
            }
            children();
        }
    }
}



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
