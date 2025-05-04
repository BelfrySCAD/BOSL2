//////////////////////////////////////////////////////////////////////
// LibFile: masks2d.scad
//   This file provides 2D masking shapes that you can use with {{edge_profile()}} to mask edges.
//   The shapes include the simple roundover and chamfer as well as more elaborate shapes
//   like the cove and ogee found in furniture and architecture.  You can make the masks
//   as geometry or as 2D paths.
// Includes:
//   include <BOSL2/std.scad>
// FileGroup: Basic Modeling
// FileSummary: 2D masking shapes for edge profiling: including roundover, cove, teardrop, ogee.
// FileFootnotes: STD=Included in std.scad
//////////////////////////////////////////////////////////////////////


function _inset_corner(corner, mask_angle, inset, excess, flat_top) =
    let(
        vertex = [inset.x/sin(mask_angle)+inset.y/tan(mask_angle), inset.y],
        corner = move(vertex, corner), 
        outside = [
                     [corner[2].x,-excess],
                     [-(excess)/tan(mask_angle/2), -excess],
                     if (!flat_top) corner[0] + polar_to_xy(inset.x+excess,90+mask_angle),
                     if (flat_top) corner[0] - [(excess+inset.x)/sin(mask_angle),0]
                  ]
    )
    [outside, corner];
    


// Section: 2D Masking Shapes

// Function&Module: mask2d_roundover()
// Synopsis: Creates a circular mask shape for rounding edges or beading.
// SynTags: Geom, Path
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable, Masks (2D)
// See Also: corner_profile(), edge_profile(), face_profile(), fillet()
// Usage: As module
//   mask2d_roundover(r|d=|h=|height=|cut=|joint=, [inset], [mask_angle], [excess], [flat_top=], [quarter_round=], [clip_angle=]) [ATTACHMENTS];
// Usage: As function
//   path = mask2d_roundover(r|d=|h=|height=|cut=|joint=, [inset], [mask_angle], [excess], [flat_top=], [quarter_round=], [clip_angle=]);
// Description:
//   Creates a 2D roundover/bead mask shape that is useful for extruding into a 3D mask for an edge.
//   Conversely, you can use that same extruded shape to make an interior fillet between two walls.
//   As a 2D mask, this is designed to be differenced away from the edge of a shape that with its corner at the origin and one edge on the X+ axis and the other mask_angle degrees counterclockwise from the X+ axis.  
//   If called as a function, returns a 2D path of the outline of the mask shape.
//   .
//   The roundover can be specified by radius, diameter, height, cut, or joint length.
//   ![Types of Roundovers](images/rounding/figure_1_1.png)
//   .
//   If you need roundings to agree on edges of different mask_angle, e.g. to round the base of a prismoid, then you need all of the
//   masks used to have the same height.  (Note that it may appear that matching joint would also work, but it does not because the joint distances are measured
//   in different directions.)  You can get the same height by setting the `height` parameter, which is an alternate way to control the size of the rounding.
//   You can also set `quarter_round=true`, which creates a rounding that uses a quarter circle of the specified radius for all mask angles.  If you have set inset
//   you will need `flat_top=true` as well.  Note that this is the default if you use `quarter_round=true` but not otherwise.  Generally if you want a roundover
//   results are best using the `height` option but if you want a bead as you get using `inset` the results are often best using the `quarter_round=true` option.
//   .
//   If you set the `clip_angle` option then the bottom of the arc is clipped at the specified angle from vertical.  This
//   can be useful for creating bottom roundings for 3d printing.  If you specify the radius either directly or indirectly
//   using `cut` or `joint` and combine that with a height specification using `h` or `height`, then `clip_angle` is automatically
//   calculated and a clipped circle of the specified height and radius is produced.  
// Arguments:
//   r = Radius of the roundover.
//   inset = Optional bead inset size, perpendicular to the two edges.  Scalar or 2-vector.  Default: 0
//   mask_angle = Number of degrees in the corner angle to mask.  Default: 90
//   excess = Extra amount of mask shape to creates on the X and quasi-Y sides of the shape.  Default: 0.01
//   ---
//   d = Diameter of the roundover.
//   h / height = Mask height excluding inset and excess.  Give instead of r / d, cut or joint when you want a consistent mask height, no matter what the mask angle.
//   cut = Cut distance.  IE: How much of the corner to cut off.  See [Types of Roundovers](rounding.scad#section-types-of-roundovers).
//   joint = Joint distance.  IE: How far from the edge the roundover should start.  See [Types of Roundovers](rounding.scad#section-types-of-roundovers).
//   flat_top = If true, the top inset of the mask will be horizontal instead of angled by the mask_angle.  Default: true if quarter_round is set, false otherwise.
//   quarter_round = If true, make a roundover independent of the mask_angle, defined based on a quarter circle of the specified size.  Creates mask with angle-independent height.  Default: false.
//   clip_angle = Clip the bottom of the rounding where the circle is this angle from the vertical.  Must be between mask_angle-90 and 90 degrees.  Default: 90 (no clipping)
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//
// Example(2D): 2D Roundover Mask by Radius
//   mask2d_roundover(r=10);
// Example(2D): 2D Bead Mask
//   mask2d_roundover(r=10,inset=2);
// Example(2D): 2D Roundover Mask by Radius, acute angle
//   mask2d_roundover(r=10, mask_angle=50);
// Example(2D): 2D Bead Mask by Radius, acute angle
//   mask2d_roundover(r=10, inset=2, mask_angle=50);
// Example(2D): 2D Bead Mask for obtuse angle, by height
//   mask2d_roundover(h=10, inset=2, mask_angle=135, $fn=64);
// Example(2D): 2D Bead Mask for obtuse angle, by height with flat top
//   mask2d_roundover(h=10, inset=2, mask_angle=135, flat_top=true, $fn=64);
// Example(2D): 2D Angled Bead Mask by Joint Length.  Joint length does not include the inset.  
//   mask2d_roundover(joint=10, inset=2, mask_angle=75);
// Example(2D): Increasing the Excess
//   mask2d_roundover(r=10, inset=2, mask_angle=75, excess=2);
// Example(2D): quarter_round bead on an acute angle
//   mask2d_roundover(r=10, inset=2, mask_angle=50, quarter_round=true);
// Example(2D): quarter_round bead on an obtuse angle
//   mask2d_roundover(r=10, inset=2, mask_angle=135, quarter_round=true);
// Example(2D): clipping a circle to a 50 deg angle 
//   mask2d_roundover(r=10, inset=1/2, clip_angle=50);
// Example(2D): clipping a circle to a 50 deg angle.  The bottom of the arc is not tangent to the x axis.   
//   mask2d_roundover(r=10, inset=1/2, clip_angle=50);
// Example(2D): clipping the arc by specifying `r` and `h`
//   mask2d_roundover(mask_angle=66, r=10, h=12, inset=1);
// Example: Masking by Edge Attachment
//   diff()
//   cube([50,60,70],center=true)
//       edge_profile([TOP,"Z"],except=[BACK,TOP+LEFT])
//           mask2d_roundover(h=12, inset=2);
// Example: Making an interior fillet
//   %render() difference() {
//       move(-[5,0,5]) cube(30, anchor=BOT+LEFT);
//       cube(310, anchor=BOT+LEFT);
//   }
//   xrot(90)
//       linear_extrude(height=30, center=true)
//           mask2d_roundover(r=10);
// Example(3D,Med,VPT=[25,30,12],VPR=[68,0,12],VPD=180): Rounding over top of an extreme prismoid using height option
//   diff()
//     prismoid([30,20], [50,60], h=20, shift=[40,50])
//        edge_profile(TOP, excess=27)
//           mask2d_roundover(height=5, mask_angle=$edge_angle, $fn=128);
// Example(3D,Med,VPT=[25,30,12],VPR=[68,0,12],VPD=180): Using the quarter_round option results in a lip on obtuse angles, so it may not be the best choice for pure roundings.  
//   diff()
//     prismoid([30,20], [50,60], h=20, shift=[40,50])
//        edge_profile(TOP, excess=27)
//           mask2d_roundover(r=5, mask_angle=$edge_angle, quarter_round=true, $fn=128);
// // Example(3D,Med,VPT=[25,30,12],VPR=[68,0,12],VPD=180): Can improve the quarter round option by using it only for acute angles and falling back on regular rounding for obtuse angles. Note that in this case, obtuse angles are fully rounded, but acute angles still have a corner, but one that is not as sharp as the original angle.  
//   diff()
//     prismoid([30,20], [50,60], h=20, shift=[40,50])
//        edge_profile(TOP, excess=27)
//           mask2d_roundover(r=5, mask_angle=$edge_angle, quarter_round=$edge_angle<90, $fn=32);
// Example(3D,Med,VPT=[25,30,12],VPR=[68,0,12],VPD=180): Creating a bead on the prismoid using the height option with flat_top=true:
//   diff()
//     prismoid([30,20], [50,60], h=20, shift=[40,50])
//        edge_profile(TOP, excess=27)
//           mask2d_roundover(height=5, mask_angle=$edge_angle, inset=1.5, flat_top=true, $fn=128);
// Example(3D,Med,VPT=[25,30,12],VPR=[68,0,12],VPD=180): Bead may be more pleasing using the quarter_round option, with curves terminating in a plane parallel to the prismoid top.  The size of the inset edge will be larger than requested when the angle is obtuse.  
//   diff()
//     prismoid([30,20], [50,60], h=20, shift=[40,50])
//        edge_profile(TOP, excess=27)
//           mask2d_roundover(r=5, mask_angle=$edge_angle, quarter_round=true, inset=1.5, $fn=128);
module mask2d_roundover(r, inset=0, mask_angle=90, excess=0.01, flat_top, d, h, height, cut, quarter_round=false, joint, anchor=CENTER,spin=0, clip_angle) {
    path = mask2d_roundover(r=r, d=d, h=h, height=height, cut=cut, joint=joint, inset=inset, clip_angle=clip_angle, 
                            flat_top=flat_top, mask_angle=mask_angle, excess=excess, quarter_round=quarter_round);
    attachable(anchor,spin, two_d=true, path=path) {
        polygon(path);
        children();
    }
}



function mask2d_roundover(r, inset=0, mask_angle=90, excess=0.01, clip_angle, flat_top, quarter_round=false, d, h, height, cut, joint, anchor=CENTER, spin=0) =
    assert(num_defined([r,d,cut,joint])<=1, "Must define at most one of r, d, cut and joint")
    assert(num_defined([h,height])<=1, "Must define at most one of h and height")
    assert(all_nonnegative([excess]), "excess must be a nonnegative value")
    assert(is_finite(mask_angle) && mask_angle>0 && mask_angle<180)
    assert(is_finite(inset)||is_vector(inset,2))
    assert(is_bool(quarter_round))
    let(flat_top=default(flat_top, quarter_round))
    assert(is_bool(flat_top))
    assert(is_undef(clip_angle) || (is_finite(clip_angle) && clip_angle<=90 && clip_angle>(quarter_round?90:mask_angle)-90),
           str("\nclip_angle must be between ",(quarter_round?90:mask_angle)-90," and 90"))
    let(
        inset = is_list(inset)? inset : [inset,inset],
        r = get_radius(r=r,d=d,dflt=undef),
        dummy2=assert(is_def(r) || !quarter_round,"Must give r / d when quarter_round is true"),
        h = u_add(one_defined([h,height],"h,hight",dflt=undef),flat_top || mask_angle>=90?0:-inset.x*cos(mask_angle)),
        // compute [joint length, radius] for different types of input
        rcalc = is_def(r) ?  assert(all_positive([r]), "r / d must be a positive value") r
              : is_def(joint) ? assert(all_positive([joint]), "joint must be a positive value") joint*tan(mask_angle/2)
              : is_def(cut) ? assert(all_positive([cut]),"cut must be a positive value") cut/(1/sin(mask_angle/2)-1)
              : undef,
        jra = is_def(clip_angle)?
                      assert(num_defined([rcalc,h])==1, "When clip_angle is given must give exactly one of r, joint, h/height, or cut")
                      let(  r = is_def(rcalc) ? rcalc
                              : h/(sin(mask_angle)/tan(mask_angle/2)-1+sin(clip_angle))
                         )
                      [r/tan(mask_angle/2), r, clip_angle]
            : num_defined([rcalc,h])==2 ? let( a=-sin(mask_angle)/tan(mask_angle/2)+1)
                                           assert(h/rcalc + a <= 1,str("\nheight cannot be larger than ", rcalc*(1-a)))
                                          [rcalc/tan(mask_angle/2) ,rcalc, asin(h/rcalc + a)]
            : is_def(rcalc) ? [rcalc/tan(mask_angle/2), rcalc, 90]
            : [ each h/sin(mask_angle)*[1,tan(mask_angle/2)], 90],
        dist=jra[0],
        radius=jra[1],
        clip_angle = jra[2], 
        
        clipshift = clip_angle==90 ? [0,0]
                  : let( v=1-cos(90-clip_angle))
                    radius*[v/tan(mask_angle),v],
        quarter_round_top = approx(mask_angle,90) ? 0
                          : radius/tan(mask_angle),
        extra = radius/20,  // Exact solution is tangent, which will make bad geometry, so insert an offset factor
        quarter_round_shift = !quarter_round || mask_angle<=90 ? 0
                            : radius/sin(180-mask_angle)-radius+extra,
        outside_corner = _inset_corner(
                            quarter_round ?
                            [
                              [quarter_round_top,radius],
                              [0,0],
                              [radius+quarter_round_top+quarter_round_shift,0]
                              ]
                           :
                            [
                              dist*[cos(mask_angle),sin(mask_angle)],
                              [0,0],
                              [dist,0]
                            ],
                            mask_angle, inset, excess, flat_top),
        // duplicates arise at one or both ends if excess and inset are both zero there
        cornerpath = !quarter_round ? outside_corner[1]
                   : mask_angle<=90 ? outside_corner[1]+[[0,0],[quarter_round_top,0],[0,0]]
                   : [ outside_corner[1][0]+[quarter_round_shift,0],
                       [outside_corner[1][0].x+quarter_round_shift,inset.y],
                       outside_corner[1][2]
                     ],
        dummy=assert(last(cornerpath).x>=0,str("inset.y is too large to fit roundover at angle ",mask_angle)),
        arcpath = let (basic = arc(corner=cornerpath, r=radius))
                  clip_angle==90 ? basic
                :
                  let(
                       cutind = [for(i=idx(basic)) if (basic[i].y-inset.y < clipshift.y) i],
                       ipt = line_intersection([basic[cutind[0]-1],basic[cutind[0]]], [[0,clipshift.y+inset.y],[1,clipshift.y+inset.y]])
                  )
                  move(-clipshift, [ each select(basic, 0,cutind[0]), ipt]),
          path = deduplicate([
                             [last(arcpath).x,-excess],
                             outside_corner[0][1],
                             move(-clipshift, outside_corner[0][2]),
                             each arcpath,
                             [last(arcpath).x,inset.y]
                           ]
                          ,closed=true)
    ) reorient(anchor,spin, two_d=true, path=path, extent=false, p=path);



// Function&Module: mask2d_teardrop()
// Synopsis: Creates a 2D teardrop shape with specified max angle from vertical.
// SynTags: Geom, Path
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable, Masks (2D), FDM Optimized
// See Also: corner_profile(), edge_profile(), face_profile()
// Usage: As Module
//   mask2d_teardrop(r|d=, [angle], [inset] [mask_angle], [excess], [cut=], [joint=], [h=|height=]) [ATTACHMENTS];
// Usage: As Function
//   path = mask2d_teardrop(r|d=, [angle], [inset], [mask_angle], [excess], [cut=], [joint=], [h=|height=]);
// Description:
//   Creates a 2D teardrop mask shape that is useful for extruding into a 3D mask for an edge.
//   Conversely, you can use that same extruded shape to make an interior teardrop fillet between two walls.
//   As a 2D mask, this is designed to be differenced away from the edge of a shape that with its corner at the origin and one edge on the X+ axis and the other mask_angle degrees counterclockwise from the X+ axis.  
//   If called as a function, returns a 2D path of the outline of the mask shape.
//   This is particularly useful to make partially rounded bottoms, that don't need support to print.
//   The roundover can be specified by radius, diameter, height, cut, or joint length.
//   ![Types of Roundovers](images/rounding/figure_1_1.png)
// Arguments:
//   r = Radius of the rounding.
//   angle = The angle from vertical of the flat section.  Must be between mask_angle-90 and 90 degrees.  Default: 45.  
//   inset = Optional bead inset size perpendicular to edges.  Default: 0
//   mask_angle = Number of degrees in the corner angle to mask.  Default: 90
//   excess = Extra amount of mask shape to creates on the X- and Y- sides of the shape. Default: 0.01
//   ---
//   d = Diameter of the rounding.
//   h / height = Mask height excluding inset and excess.  Given instead of r or d when you want a consistent mask height, no matter what the mask angle.
//   cut = Cut distance.  IE: How much of the corner to cut off.  See [Types of Roundovers](rounding.scad#section-types-of-roundovers).
//   joint = Joint distance.  IE: How far from the edge the roundover should start.  See [Types of Roundovers](rounding.scad#section-types-of-roundovers).
//   flat_top = If true, the top inset of the mask will be horizontal instead of angled by the mask_angle.  Default: true.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
// Example(2D): 2D Teardrop Mask
//   mask2d_teardrop(r=10,$fn=64);
// Example(2D): 2D Teardrop Mask for acute angle
//   mask2d_teardrop(r=10, mask_angle=75,$fn=64);
// Example(2D): 2D Teardrop Mask for obtuse angle, specifying height
//   mask2d_teardrop(h=10, mask_angle=115,$fn=128);
// Example(2D): Increasing Excess
//   mask2d_teardrop(r=10, mask_angle=75, excess=2);
// Example(2D): Using a Custom Angle
//   mask2d_teardrop(r=10,angle=30,$fn=128);
// Example(2D): With an acute mask_angle you can choose an angle of zero:
//   mask2d_teardrop(r=10,mask_angle=44,angle=0);
// Example(2D): With an acute mask_angle you can even choose a negative angle
//   mask2d_teardrop(r=10,mask_angle=44,angle=-15);
// Example(2D): With an obtuse angle you need to choose a larger angle.  Here we add inset.
//   mask2d_teardrop(h=10, mask_angle=135,angle=60, inset=2);
// Example(2D): Same thing with `flat_top=true`.  
//   mask2d_teardrop(h=10, mask_angle=135,angle=60, inset=2, flat_top=true);
// Example: Masking by Edge Attachment
//   diff()
//   cube([50,60,70],center=true)
//       edge_profile(BOT)
//           mask2d_teardrop(r=10, angle=40);
// Example: Making an interior teardrop fillet
//   %render() difference() {
//       move(-[5,0,5]) cube(30, anchor=BOT+LEFT);
//       cube(310, anchor=BOT+LEFT);
//   }
//   xrot(90)
//       linear_extrude(height=30, center=true)
//           mask2d_teardrop(r=10);

function mask2d_teardrop(r, angle=45, inset=[0,0], mask_angle=90, excess=0.01, flat_top=false, d, h, height, cut, joint, anchor=CENTER, spin=0) =  
    assert(one_defined([r,height,d,h,cut,joint],"r,height,d,h,cut,joint"))
    assert(is_finite(angle) && angle>mask_angle-90 && angle<90)
    assert(is_finite(mask_angle) && mask_angle>0 && mask_angle<180)
    assert(all_nonnegative([excess]), "excess must be a nonnegative value")
    assert(is_finite(inset)||is_vector(inset,2))
    assert(is_bool(flat_top))
    let(
        inset = is_list(inset)? inset : [inset,inset],
        r = get_radius(r=r,d=d,dflt=undef),
        h = one_defined([h,height],"h,hight",dflt=undef),
        // compute [joint length, radius] for different types of input
        jr = is_def(h) ? assert(all_positive([h]), "height / h must be a positive value")
                         (flat_top ? (h+inset.x*cos(mask_angle))/sin(mask_angle)*[1,tan(mask_angle/2)]
                                   : h/sin(mask_angle)*[1,tan(mask_angle/2)])
           : is_def(r) ?  assert(all_positive([r]), "r / d must be a positive value")
                          [r/tan(mask_angle/2), r]
           : is_def(joint) ? assert(all_positive([joint]), "joint must be a positive value")
                             joint*[1, tan(mask_angle/2)]
           : assert(all_positive([cut]),"cut must be a positive value")
             let(circ_radius=cut/(1/sin(mask_angle/2)-1))
             [circ_radius/tan(mask_angle/2), circ_radius],
        dist=jr[0],
        radius=jr[1],
        outside_corner = _inset_corner(
                            [
                              dist*[cos(mask_angle),sin(mask_angle)],
                              [0,0],
                              [dist,0]
                            ],
                            mask_angle, inset, excess, flat_top),

        arcpts = arc(r=radius, corner=outside_corner[1]),
        arcpts2 = [
            for (i = idx(arcpts))
              if(i==0 || v_theta(arcpts[i]-arcpts[i-1]) <= angle-90)
                arcpts[i]
        ],
        line1 = [last(arcpts2), last(arcpts2) + polar_to_xy(1, angle-90)],
        line2 = [[0,inset.y], [100,inset.y]],
        ipt = line_intersection(line1,line2),
        path = deduplicate([
                             [ipt.x, -excess],
                             each select(outside_corner[0],1,-1),
                             each arcpts2,
                             ipt
                           ], closed=true)
    ) reorient(anchor,spin, two_d=true, path=path, extent=false, p=path);
    


module mask2d_teardrop(r, angle=45, mask_angle=90, excess=0.01, inset=0, flat_top=false, height, d, h, cut, joint, anchor=CENTER, spin=0) {
    path = mask2d_teardrop(r=r, d=d, h=h, height=height, flat_top=flat_top, cut=cut, joint=joint, angle=angle,inset=inset, mask_angle=mask_angle, excess=excess);
    attachable(anchor,spin, two_d=true, path=path) {
        polygon(path);
        children();
    }
}




// Function&Module: mask2d_cove()
// Synopsis: Creates a 2D cove (quarter-round) mask shape.
// SynTags: Geom, Path
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable, Masks (2D)
// See Also: corner_profile(), edge_profile(), face_profile()
// Usage: As module
//   mask2d_cove(r|d=|h=|height=, [inset], [mask_angle], [excess], [bulge=], [flat_top=], [quarter_round=]) [ATTACHMENTS];
// Usage: As function
//   path = mask2d_cove(r|d=|h=, [inset], [mask_angle], [excess], [bulge=], [flat_top=]);
// Description:
//   Creates a 2D cove mask shape that is useful for extruding into a 3D mask for an edge.
//   Conversely, you can use that same extruded shape to make an interior rounded shelf decoration between two walls.
//   As a 2D mask, this is designed to be differenced away from the edge of a shape that with its corner at the origin and one edge on the X+ axis and the other mask_angle degrees counterclockwise from the X+ axis.  
//   If called as a function, returns a 2D path of the outline of the mask shape.
//   .
//   If you need coves to agree on edges of different mask_angle, e.g. on the top of a prismoid, then you need all of the
//   masks used to have the same height.   You can get the same height by setting the `height` parameter.  For obtuse angles, however, the cove mask may not
//   have is maximum height at the edge, which means it won't mate with adjacent coves.  You can fix this using `flat_top=true` which extends the circle
//   with a line to maintain a flat top.  Another way to fix it is to set `bulge`.  You can also achieve constant height using the `quarter_round=` option,
//   which uses a quarter circle of the specified size for all mask_angle values.  This option often produces a nice result because coves all terminate in a
//   plane at 90 degrees.  
// Arguments:
//   r = Radius of the cove.
//   inset = Optional amount to inset in the perpendicular direction from the edges.  Scalar or 2-vector.  Default: 0
//   mask_angle = Number of degrees in the corner angle to mask.  Default: 90
//   excess = Extra amount of mask shape to creates on the X and quasi-Y sides of the shape.  Default: 0.01
//   ---
//   d = Diameter of the cove.
//   h / height = Mask height, excluding inset and excess.  Given instead of r or d when you want a consistent mask height, no matter what the mask angle.
//   bulge = specify arc as the distance away from a straight line chamfer.  The arc will not meet the sides at a 90 deg angle. 
//   quarter_round = If true, make cove independent of the mask_angle, defined based on a quarter circle, with angle-independent radius. The mask will have constant height.  Default: false.
//   flat_top = If true, the top inset of the mask will be horizontal instead of angled by the mask_angle.  In the case of obtuse angles force the mask to have a flat section at its left side instead of a circular arc.  Default: true if quarter_round is set, false otherwise.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
// Example(2D): 2D Cove Mask by Radius
//   mask2d_cove(r=10);
// Example(2D): 2D Inset Cove Mask (not much different than a regular cove of larger radius)
//   mask2d_cove(r=10,inset=3);
// Example(2D): 2D Cove Mask for acute angle, specified by height, with the bulge set to change the curve.  Note that the circular arc is not perpendicular to the sides.  
//   mask2d_cove(h=10,mask_angle=55, bulge=3);
// Example(2D): 2D Cove Mask for obtuse angle, specified by height.  This will produce an odd result if combined with other masks because the maximum height is in the middle.  
//   mask2d_cove(h=10,mask_angle=145);
// Example(2D): 2D Cove Mask for obtuse angle with flat top.  This is one solution to the problem of the previous example.  Max height is achieved at the left corner. 
//   mask2d_cove(h=10,mask_angle=145,flat_top=true);
// Example(2D): 2D Cove Mask for obtuse angle, specified by height with bulge parameter.  Another way to fix the problem of the previous example: the max height is again achieved at the left corner.  
//   mask2d_cove(h=10,mask_angle=145, bulge=3, $fn=128);
// Example(2D): 2D Cove Mask for acute angle with quarter_round enabled
//   mask2d_cove(r=10,mask_angle=55,quarter_round=true);
// Example(2D): 2D Cove Mask for obtuse angle, specified by height.  Note that flat_top is on by default in quarter_round mode.  
//   mask2d_cove(r=10,mask_angle=145,quarter_round=true);
// Example(2D): Increasing the Excess
//   mask2d_cove(r=10,inset=3,mask_angle=75, excess=2);
// Example: Masking by Edge Attachment
//   diff()
//   cube([50,60,70],center=true)
//       edge_profile([TOP,"Z"],except=[BACK,TOP+LEFT])
//           mask2d_cove(h=10, inset=3);
// Example: Making an interior rounded shelf
//   %render() difference() {
//       move(-[5,0,5]) cube(30, anchor=BOT+LEFT);
//       cube(310, anchor=BOT+LEFT);
//   }
//   xrot(90)
//       linear_extrude(height=30, center=true)
//           mask2d_cove(r=5, inset=5);
// Example(3D,Med): A cove on top of an extreme prismoid top by setting height and using flat_top mode.  This creates **long** flat tops sections at obtuse angles. 
//   diff()
//   prismoid([50,60], [20,30], h=20, shift=[25,16])
//       edge_profile(TOP, excess=20)
//           mask2d_cove(h=5, inset=0, mask_angle=$edge_angle, flat_top=true, $fn=128);
// Example(3D,Med): Cove on an extreme prismoid top by setting height and bulge.  Obtuse angles have long **curved** sections.  
//   diff()
//   prismoid([50,60], [20,30], h=20, shift=[25,16])
//       edge_profile(TOP, excess=20)
//           mask2d_cove(h=5, inset=0, mask_angle=$edge_angle, bulge=1, $fn=128);
// Example(3D,Med): Rounding an extreme prismoid top using quarter_round.  Another way to handle this situation. 
//   diff()
//   prismoid([50,60], [20,30], h=20, shift=[25,16])
//       edge_profile(TOP, excess=20)
//           mask2d_cove(r=5, inset=0, mask_angle=$edge_angle, quarter_round=true, $fn=128);

module mask2d_cove(r, inset=0, mask_angle=90, excess=0.01, flat_top, bulge, d, h, height, quarter_round=false, anchor=CENTER, spin=0) {
    path = mask2d_cove(r=r, d=d, h=h, height=height, bulge=bulge, flat_top=flat_top, quarter_round=quarter_round, inset=inset, mask_angle=mask_angle, excess=excess);
    attachable(anchor,spin, two_d=true, path=path) {
        polygon(path);
        children();
    }
}


function mask2d_cove(r, inset=0, mask_angle=90, excess=0.01, flat_top, d, h, height,bulge, quarter_round=false, anchor=CENTER, spin=0) =
    assert(one_defined([r,d,h,height],"r,d,h,height"))
    assert(is_finite(mask_angle) && mask_angle>0 && mask_angle<180)
    assert(is_finite(excess))
    assert(is_finite(inset)||(is_vector(inset)&&len(inset)==2))
    assert(is_bool(quarter_round))
    let(flat_top=default(flat_top,quarter_round))
    assert(is_bool(flat_top))
    assert(is_undef(bulge) || all_positive([bulge]),"bulge must be a positive value")
    let(
        inset = force_list(inset,2),
        r = get_radius(r=r,d=d,dflt=undef),
        h = u_add(one_defined([h,height],"h,hight",dflt=undef),flat_top || mask_angle>=90?0:-inset.x*cos(mask_angle)),
        radius = is_def(h) ? assert(all_positive([h]), "height / h must be a larger than y inset")
                             !bulge && (quarter_round || mask_angle>90) ? h-inset.y
                           : h/sin(mask_angle)
               : assert(all_positive([r]), "r / d must be a positive value") r,
        quarter_round_ofs = quarter_round ? radius/tan(mask_angle) : 0,
        outside_corner = _inset_corner(
                           quarter_round ?
                             [
                              [quarter_round_ofs,radius],
                              [0,0],
                              [quarter_round_ofs+radius,0]
                             ]
                           : mask_angle>90 && flat_top && is_undef(bulge) ? 
                            [
                              [radius/tan(mask_angle),radius],
                              [0,0],
                              [radius,0]
                            ]
                           :
                            [
                              radius*[cos(mask_angle),sin(mask_angle)],
                              [0,0],
                              [radius,0]
                            ],
                            mask_angle, inset, excess, flat_top),
        quarter_round_big_fix = quarter_round && mask_angle>135 ? quarter_round_ofs+radius
                      : 0,
        flatfix = !quarter_round && is_undef(bulge) && flat_top && mask_angle>90 ? radius/tan(mask_angle)
                  : 0,
        corners = select(outside_corner[1], [0,2]) - [[quarter_round_big_fix+flatfix,0],[quarter_round_big_fix,0]],
        bulgept = is_undef(bulge) ? undef
                : let(
                      normal = line_normal(corners)
                  )
                  mean(corners)+bulge*normal,
        dummy=assert(corners[1].x>=0, str("inset.y is too large to fit cove at angle ",mask_angle)),
        cp = quarter_round ? [corners[0].x,inset.y] : outside_corner[1][1],
        path = deduplicate([
                            [corners[1].x,-excess],
                            each select(outside_corner[0],1,-1),
                            if (bulge) each arc(points=[corners[0], bulgept, corners[1]]),           
                            if (!bulge) each arc(cp=cp, points = corners),
                           ],
                           closed=true)
    ) reorient(anchor,spin, two_d=true, path=path, extent=false, p=path);



// Function&Module: mask2d_chamfer()
// Synopsis: Produces a 2D chamfer mask shape.
// SynTags: Geom, Path
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable, Masks (2D)
// See Also: corner_profile(), edge_profile(), face_profile()
// Usage: As Module
//   mask2d_chamfer(edge, [angle], [inset], [excess]) [ATTACHMENTS];
//   mask2d_chamfer(y=, [angle=], [inset=], [excess=]) [ATTACHMENTS];
//   mask2d_chamfer(x=, [angle=], [inset=], [excess=]) [ATTACHMENTS];
// Usage: As Function
//   path = mask2d_chamfer(edge, [angle], [inset], [excess]);
//   path = mask2d_chamfer(y=, [angle=], [inset=], [excess=]);
//   path = mask2d_chamfer(x=, [angle=], [inset=], [excess=]);
// Description:
//   Creates a 2D chamfer mask shape that is useful for extruding into a 3D mask for an edge. 
//   Conversely, you can use that same extruded shape to make an interior chamfer between two walls.
//   As a 2D mask, this is designed to be differenced away from the edge of a shape that with its corner at the origin and one edge on the X+ axis and the other mask_angle degrees counterclockwise from the X+ axis.  
//   If called as a function, returns a 2D path of the outline of the mask shape.
//   The edge parameter specifies the length of the chamfer's slanted edge.  The x parameter specifies the width.  The y parameter
//   specfies the length of the non-horizontal arm of the chamfer.  The height specifies the height of the chamfer independent
//   of angle.  You can specify any combination of parameters that determines a chamfer geometry.  
// Arguments:
//   edge = The length of the edge of the chamfer.
//   angle = The angle of the chamfer edge, away from vertical.  Default: mask_angle/2.
//   inset = Optional amount to inset perpendicular to each edge.  Scalar or 2-vector.  Default: 0
//   mask_angle = Number of degrees in the corner angle to mask.  Default: 90
//   excess = Extra amount of mask shape to creates on the X- and Y- sides of the shape.  Default: 0.01
//   ---
//   x = The width of the chamfer (joint distance in x direction)
//   y = The set-back (joint distance) in the non-x direction of the chamfer. 
//   h / height = The height of the chamfer (excluding inset and excess).
//   w/ width = The width of the chamfer (excluding inset and excess).
//   quarter_round = If true, make a roundover independent of the mask_angle, defined based on a 90 deg angle, with a constant height.  Default: false.
//   flat_top = If true, the top inset of the mask will be horizontal instead of angled by the mask_angle.  Default: true.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
// Example(2D): 2D Chamfer Mask, at 45 deg by default
//   mask2d_chamfer(x=10);
// Example(2D): 2D Chamfer Mask, at 30 deg (measured down from vertical)
//   mask2d_chamfer(x=10,angle=30);
// Example(2D): 2D Chamfer Mask on an acute angle.  The default chamfer angle is to produce a symmetric chamfer.  
//   mask2d_chamfer(x=10,mask_angle=45);
// Example(2D): 2D Chamfer Mask on an acute angle.  Here we specify the angle of the chamfer
//   mask2d_chamfer(x=10,mask_angle=45,angle=45);
// Example(2D): 2D Chamfer Mask specified by x and y length
//   mask2d_chamfer(x=4,y=10);
// Example(2D): 2D Chamfer Mask specified by x and y length.  The y length is along the top side of the chamfer, not parallel to the Y axis.
//   mask2d_chamfer(x=4,y=5,mask_angle=44);
// Example(2D): 2D Chamfer Mask specified by width and height.  
//   mask2d_chamfer(w=4,h=5,mask_angle=44);
// Example(2D): 2D Chamfer Mask on obtuse angle, specifying x.  The right tip is 10 units from the origin. 
//   mask2d_chamfer(x=10,mask_angle=127);
// Example(2D): 2D Chamfer Mask on obtuse angle, specifying width.  The entire width is 10. 
//   mask2d_chamfer(w=10,mask_angle=127);
// Example(2D): 2D Chamfer Mask by edge
//    mask2d_chamfer(edge=10);
// Example(2D): 2D Chamfer Mask by edge, acute case
//    mask2d_chamfer(edge=10, mask_angle=44);
// Example(2D): 2D Chamfer Mask by edge, obtuse case
//    mask2d_chamfer(edge=10, mask_angle=144);
// Example(2D): 2D Chamfer Mask by edge and angle
//    mask2d_chamfer(edge=10, angle=30);
// Example(2D): 2D Chamfer Mask by edge and x
//    mask2d_chamfer(edge=10, x=9);
// Example(2D): 2D Inset Chamfer Mask
//     mask2d_chamfer(x=10, inset=2);
// Example(2D): 2D Inset Chamfer Mask on acute angle
//     mask2d_chamfer(x=10, inset=2, mask_angle=77);
// Example(2D): 2D Inset Chamfer Mask on acute angle with flat top
//     mask2d_chamfer(x=10, inset=2, mask_angle=77, flat_top=true);
// Example: Masking by Edge Attachment
//   diff()
//   cube([50,60,70],center=true)
//       edge_profile([TOP,"Z"],except=[BACK,TOP+LEFT])
//           mask2d_chamfer(x=10, inset=2);
// Example: Making an interior chamfer
//   %render() difference() {
//       move(-[5,0,5]) cube(30, anchor=BOT+LEFT);
//       cube(310, anchor=BOT+LEFT);
//   }
//   xrot(90)
//       linear_extrude(height=30, center=true)
//           mask2d_chamfer(edge=10);
// Example(3D,Med): Chamfering an extreme prismoid by setting height
//   diff()
//   prismoid([50,60], [20,30], h=20, shift=[25,16])
//       edge_profile(TOP, excess=20)//let(f=$edge_angle)
//           mask2d_chamfer(h=5,mask_angle=$edge_angle);
// Example(3D,Med): Chamfering an extreme prismoid with a fixed chamfer angle.  Note that a very large chamfer angle is required because of the large obtuse angles.  
//   diff()
//   prismoid([50,60], [20,30], h=20, shift=[25,16])
//       edge_profile(TOP, excess=20)//let(f=$edge_angle)
//           mask2d_chamfer(h=5,mask_angle=$edge_angle,angle=64);
// Example(3D,Med): Chamfering an extreme prismoid by setting height with inset and flat_top=true.
//   diff()
//   prismoid([50,60], [20,30], h=20, shift=[25,16])
//       edge_profile(TOP, excess=20)//let(f=$edge_angle)
//           mask2d_chamfer(h=4,inset=1,flat_top=true,mask_angle=$edge_angle);

module mask2d_chamfer(edge, angle, inset=0, excess=0.01, mask_angle=90, flat_top=false, x, y, h, w, height, width, anchor=CENTER,spin=0) {
    path = mask2d_chamfer(x=x, y=y, edge=edge, angle=angle, height=height, h=h, excess=excess, w=w,
                          inset=inset, mask_angle=mask_angle, flat_top=flat_top,width=width);
    attachable(anchor,spin, two_d=true, path=path, extent=true) {
        polygon(path);
        children();
    }
}

function mask2d_chamfer(edge, angle, inset=0, excess=0.01, mask_angle=90, flat_top=false, x, y, h, w, width, height, anchor=CENTER,spin=0) =
    assert(is_undef(x) || all_positive([x]))
    assert(is_undef(y) || all_positive([y]))
    assert(is_undef(w) || all_positive([w]))
    assert(is_undef(h) || all_positive([h]))
    assert(is_undef(height) || all_positive([height]))
    assert(is_undef(width) || all_positive([width]))
    assert(is_undef(edge) || all_positive([edge]))            
    assert(all_nonnegative([excess]))
    assert(is_finite(mask_angle) && mask_angle>0 && mask_angle<180)
    assert(is_finite(inset)||is_vector(inset,2))
    assert(is_undef(angle) || angle>mask_angle-90, str("angle must be larger than ",mask_angle-90," for chamfer to fit"))
    let(
        inset = is_list(inset)? inset : [inset,inset],
        h = one_defined([h,height],"h,height",dflt=undef),
        w = one_defined([w,width],"w,width",dflt=undef),
        dummy = assert(num_defined([y,h])<=1, "Cannot defined both h / height and y")
                assert(num_defined([x,w])<=1, "Cannot defined both w / width and x"),
        y = is_def(h) ? assert(all_positive([h]), "height / h must be postitive")
                        h/sin(mask_angle) : y, 
        xy = is_def(w) ? assert(is_undef(edge), "Cannot combine edge with width")
                         assert(num_defined([y,angle])<=1, "Conflicting values of width, y and angle given")
                         let(
                             angle=default(angle,mask_angle/2),
                             y = is_def(y) ? y
                               : w/tan(angle)
                         )                               
                         [w+y*cos(mask_angle),y]
           : is_def(x) ? assert(num_defined([y,edge,angle])<=1, "Conflicting values of x, y, height, edge and angle given")
                         (
                             is_def(y) ? [x,y]
                           : is_def(edge) ? let(yopt=quadratic_roots(1,-2*x*cos(mask_angle), x^2-edge^2,real=true))
                                           assert(yopt!=[] && max(yopt)>0, "edge too short for x value")
                                           [x,max(yopt)]
                           : let(angle=default(angle,mask_angle/2))
                             [x,law_of_sines(a=x,A=90-mask_angle+angle,B=90-angle)]
                         )
           : is_def(y) ? assert(num_defined([edge,angle])<=1, "Conflicting or insufficient values of x, y, height, edge and angle given")
                         (
                             is_def(edge) ? let(xopt=quadratic_roots(1,-2*y,cos(mask_angle), y^2-edge^2,real=true))
                                            assert(xopt!=[], "edge too short for y value")
                                            [x,max(xopt)]
                           : let(angle=default(angle,mask_angle/2))
                             [law_of_sines(a=y,A=90-angle,B=90-mask_angle+angle), y]
                         )
           : assert(is_def(edge), "Must give one of x, y, w/width, h/height, or edge")
             let(angle=default(angle,mask_angle/2))
             [law_of_sines(a=edge,A=mask_angle, B=90-mask_angle+angle),
              law_of_sines(a=edge,A=mask_angle, B=90-angle)],
        dummy3=assert(xy.x > xy.y*cos(mask_angle), str("Chamfer does not fit with mask_angle ",mask_angle)),
        // These computations are just for the error message...actually only work without inset
        // ref_pt = polar_to_xy(xy.y, mask_angle),
        // angle = 90-atan(ref_pt.y/(xy.x-ref_pt.x)),
        outside_corner = _inset_corner(
                            [
                              polar_to_xy(xy.y,mask_angle),
                              [0,0],
                              [xy.x,0]
                            ],
                            mask_angle, inset, excess, flat_top),
        dummy2=assert(outside_corner[1][2].x>0,str("Angle of chamfer is too small to fit on mask angle ",mask_angle,
                                                   ".  Either increase angle or add x inset to make space.")),
        path = deduplicate(concat(outside_corner[0], select(outside_corner[1],[0,2])),closed=true)
    ) reorient(anchor,spin, two_d=true, path=path, extent=false, p=path);


// Function&Module: mask2d_rabbet()
// Synopsis: Creates a rabbet mask shape.
// SynTags: Geom, Path
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable, Masks (2D)
// See Also: corner_profile(), edge_profile(), face_profile()
// Usage: As Module
//   mask2d_rabbet(size, [mask_angle], [excess]) [ATTACHMENTS];
// Usage: As Function
//   path = mask2d_rabbet(size, [mask_angle], [excess]);
// Description:
//   Creates a 2D rabbet mask shape.  When differenced away, this mask
//   creates at the corner a rectanguler space of the specified size.
//   This mask can be extruding into a 3D mask for an edge, or
//   you can use that same extruded shape to make an interior shelf decoration between two walls.
//   As a 2D mask, this is designed to be differenced away from the edge of a shape that with its corner at the origin and one edge on the X+ axis and the other mask_angle degrees counterclockwise from the X+ axis.  
//   If called as a function, returns a 2D path of the outline of the mask shape.
// Arguments:
//   size = The size of the rabbet, either as a scalar or an [X,Y] list.
//   mask_angle = Number of degrees in the corner angle to mask.  Default: 90
//   excess = Extra amount of mask shape to creates on the X and quasi-Y sides of the shape. Default: 0.01
//   ---
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
// Example(2D): 2D Rabbet Mask
//   mask2d_rabbet(size=10);
// Example(2D): 2D Asymmetrical Rabbet Mask
//   mask2d_rabbet(size=[5,10]);
// Example(2D): 2D Mask for a acute angle edge
//   mask2d_rabbet(size=10, mask_angle=75);
// Example(2D): 2D Mask for obtuse angle edge.  If the obtuse angle is too large the rabbet will not fit.  If that happens, you will need to increase the rabbet width.  
//   mask2d_rabbet(size=10, mask_angle=125);
// Example: Masking by Edge Attachment
//   diff()
//   cube([50,60,70],center=true)
//       edge_profile([TOP,"Z"],except=[BACK,TOP+LEFT])
//           mask2d_rabbet(size=10);
// Example: Making an interior shelf
//   %render() difference() {
//       move(-[5,0,5]) cube(30, anchor=BOT+LEFT);
//       cube(310, anchor=BOT+LEFT);
//   }
//   xrot(90)
//       linear_extrude(height=30, center=true)
//           mask2d_rabbet(size=[5,10]);
module mask2d_rabbet(size, mask_angle=90, excess=0.01, anchor=CTR, spin=0) {
    path = mask2d_rabbet(size=size, mask_angle=mask_angle, excess=excess);
    attachable(anchor,spin, two_d=true, path=path, extent=false) {
        polygon(path);
        children();
    }
}



function mask2d_rabbet(size, mask_angle=90, excess=0.01, anchor=CTR, spin=0) =
    assert(is_finite(size)||is_vector(size,2))
    assert(is_finite(mask_angle) && mask_angle>0 && mask_angle<180)
    assert(all_nonnegative([excess]))
    let( 
        size = force_list(size,2),
        top = polar_to_xy(size.y/sin(mask_angle),mask_angle),
        bot = [top.x+size.x,0],
        dummy=assert(top.x+size.x>=0, str("Rabbet of size ",size, " does not fit on ",mask_angle," corner.")),
        outside_corner = _inset_corner([top,[0,0],bot],mask_angle, [0,0], excess, flat_top=true),
        path =deduplicate([
                each outside_corner[0],
                outside_corner[1][0],
                [outside_corner[1][2].x, outside_corner[1][0].y],
                outside_corner[1][2]
                ],closed=true)
    ) reorient(anchor,spin, two_d=true, path=path, extent=false, p=path);


// Function&Module: mask2d_dovetail()
// Synopsis: Creates a 2D dovetail mask shape.
// SynTags: Geom, Path
// Topics: Masks (2D), Shapes (2D), Paths (2D), Path Generators, Attachable 
// See Also: corner_profile(), edge_profile(), face_profile()
// Usage: As Module
//   mask2d_dovetail(edge, angle, [inset], [shelf], [excess], ...) [ATTACHMENTS];
//   mask2d_dovetail(width=, angle=, [inset=], [shelf=], [excess=], ...) [ATTACHMENTS];
//   mask2d_dovetail(height=, angle=, [inset=], [shelf=], [excess=], ...) [ATTACHMENTS];
//   mask2d_dovetail(width=, height=, [inset=], [shelf=], [excess=], ...) [ATTACHMENTS];
// Usage: As Function
//   path = mask2d_dovetail(edge, [angle], [inset], [shelf], [excess]);
// Description:
//   Creates a 2D dovetail mask shape that is useful for extruding into a 3D mask for a 90° edge.
//   Conversely, you can use that same extruded shape to make an interior dovetail between two walls at a 90º angle.
//   As a 2D mask, this is designed to be differenced away from the edge of a shape that with its corner at the origin and one edge on the X+ axis and the other mask_angle degrees counterclockwise from the X+ axis.  
//   If called as a function, returns a 2D path of the outline of the mask shape.
// Arguments:
//   edge = The length of the edge of the dovetail.
//   angle = The angle of the chamfer edge, away from vertical.  
//   shelf = The extra height to add to the inside corner of the dovetail.  Default: 0
//   inset = Optional amount to inset in perpendicular direction from each edge.  Default: 0
//   mask_angle = Number of degrees in the corner angle to mask.  Default: 90
//   excess = Extra amount of mask shape to creates on the X and quasi-Y sides of the shape.  Default: 0.01
//   ---
//   width = The width of the dovetail (excluding any inset)
//   height = The height of the dovetail (excluding any inset or shelf). 
//   flat_top = If true, the top inset of the mask will be horizontal instead of angled by the mask_angle.  Default: true.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
// Example(2D): 2D Dovetail Mask
//   mask2d_dovetail(width=10,angle=14);
// Example(2D): 2D Dovetail Mask by height and slope.  A slope of 1/6 is a common choice. 
//   mask2d_dovetail(height=20, slope=1/6);
// Example(2D): 2D Inset Dovetail Mask to make the dovetail wider
//   mask2d_dovetail(width=5, angle=12, inset=[4,0]);
// Example(2D): 2D Inset Dovetail Mask on an obtuse angle
//   mask2d_dovetail(width=5, mask_angle=110, angle=12);
// Example(2D): 2D Inset Dovetail Mask on an acute angle will generally require an inset in order to fit.  
//   mask2d_dovetail(width=5, mask_angle=70, angle=12, inset=[6,0]);
// Example(2D): 2D dovetail mask by edge length and angle
//   mask2d_dovetail(edge=10,width=4);
// Example(2D): 2D dovetail mask by width and height
//   mask2d_dovetail(width=5,height=25);
// Example: Masking by Edge Attachment
//   diff()
//   cube([50,60,70],center=true)
//       edge_profile([TOP,"Z"],except=[BACK,TOP+LEFT])
//           mask2d_dovetail(width=10, angle=30, inset=2);
// Example: Making an interior dovetail
//   %render() difference() {
//       move(-[5,0,5]) cube(30, anchor=BOT+LEFT);
//       cube(310, anchor=BOT+LEFT);
//   }
//   xrot(90)
//       linear_extrude(height=30, center=true)
//           mask2d_dovetail(width=10,angle=30);
module mask2d_dovetail(edge, angle, shelf=0, inset=0, mask_angle=90, excess=0.01, flat_top=true, w,h,width,height, slope, anchor=CENTER, spin=0,x,y) {
    path = mask2d_dovetail(w=w,width=width,h=h,height=height, edge=edge, angle=angle, inset=inset, shelf=shelf, excess=excess, slope=slope, flat_top=flat_top, mask_angle=mask_angle,x=x,y=y);
    attachable(anchor,spin, two_d=true, path=path) {
        polygon(path);
        children();
    }
}

function mask2d_dovetail(edge, angle, slope, shelf=0, inset=0, mask_angle=90, excess=0.01, flat_top=true, w,width,h,height, anchor=CENTER, spin=0,x,y) =
    assert(num_defined([slope,angle])<=1, "Cannot give both slope and angle")
    assert(is_finite(excess))
    assert(is_undef(w) || all_positive([w]))
    assert(is_undef(h) || all_positive([h]))
    assert(is_undef(height) || all_positive([height]))
    assert(is_undef(width) || all_positive([width]))
    assert(is_finite(inset)||is_vector(inset,2))
    let(
        y = one_defined([h,height,y],"h,height,y",dflt=undef),
        x = one_defined([w,width,x],"w,width,x",dflt=undef),
        angle = is_def(slope) ? atan(slope) : angle,
        dummy2=//assert(num_defined([x,y])==2 || (all_positive([angle]) && angle<90), "Invalid angle or slope")
               assert(num_defined([x,y])<2 || is_undef(angle), "Cannot give both width and height if you give slope or angle"),
        inset = force_list(inset,2),
        width = is_def(x)? x
              : is_def(y)? adj_ang_to_opp(adj=y,ang=angle)
              : assert(all_positive([edge]))
                hyp_ang_to_opp(hyp=edge,ang=angle),
        height = is_def(y) ? y
               : num_defined([width,angle])==2 ? opp_ang_to_adj(opp=width,ang=angle)+shelf
               : all_defined([edge,angle]) ? hyp_ang_to_adj(hyp=edge,ang=angle)
               : assert(is_def(edge) && edge>width) sqrt(edge^2-width^2),
        top = polar_to_xy(height/sin(mask_angle),mask_angle),
        outside_corner = _inset_corner([top,[0,0],[0,0]], mask_angle, inset, excess, flat_top),
        dummy=assert(outside_corner[1][1].x+width > top.x, "Dovetail doesn't fit on that angled edge.  Try increasing x inset.")
              assert(outside_corner[1][1].x>=0, "Dovetails doesn't fit on the edge.  Try decreasing y inset."),
        path = deduplicate([
                            each outside_corner[0],
                            outside_corner[1][0],
                            if (shelf>0) outside_corner[1][1]+[width,height],
                            outside_corner[1][1]+[width,height-shelf],
                            outside_corner[1][1]
                           ], closed=true)
    ) reorient(anchor,spin, two_d=true, path=path, p=path);



// Function&Module: mask2d_ogee()
// Synopsis: Creates a 2D ogee mask shape.
// SynTags: Geom, Path
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable, Masks (2D)
// See Also: corner_profile(), edge_profile(), face_profile()
// Usage: As Module
//   mask2d_ogee(pattern, [excess], ...) [ATTACHMENTS];
// Usage: As Function
//   path = mask2d_ogee(pattern, [excess], ...);
// Description:
//   Creates a 2D Ogee mask shape that is useful for extruding into a 3D mask for a 90° edge.
//   Conversely, you can use that same extruded shape to make an interior ogee decoration between two walls at a 90º angle.
//   As a 2D mask, this is designed to be differenced away from the edge of a shape that with its corner at the origin and one edge on the X+ axis and the other mask_angle degrees counterclockwise from the X+ axis.  
//   Since there are a number of shapes that fall under the name ogee, the shape of this mask is given as a pattern.
//   Patterns are given as TYPE, VALUE pairs.  ie: `["fillet",10, "xstep",2, "step",[5,5], ...]`.  See Patterns below.
//   If called as a function, returns a 2D path of the outline of the mask shape.
//   .
//   ### Patterns
//   .
//   Type     | Argument  | Description
//   -------- | --------- | ----------------
//   "step"   | [x,y]     | Makes a line to a point `x` right and `y` down.
//   "xstep"  | dist      | Makes a `dist` length line towards X+.
//   "ystep"  | dist      | Makes a `dist` length line towards Y-.
//   "round"  | radius    | Makes an arc that will mask a roundover.
//   "fillet" | radius    | Makes an arc that will mask a fillet.
//
// Arguments:
//   pattern = A list of pattern pieces to describe the Ogee.
//   excess = Extra amount of mask shape to creates on the X- and Y- sides of the shape. Default: 0.01
//   ---
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//
// Example(2D): 2D Ogee Mask
//   mask2d_ogee([
//       "xstep",1,  "ystep",1,  // Starting shoulder.
//       "fillet",5, "round",5,  // S-curve.
//       "ystep",1,  "xstep",1   // Ending shoulder.
//   ]);
// Example: Masking by Edge Attachment
//   diff()
//   cube([50,60,70],center=true)
//       edge_profile(TOP)
//           mask2d_ogee([
//               "xstep",1,  "ystep",1,  // Starting shoulder.
//               "fillet",5, "round",5,  // S-curve.
//               "ystep",1,  "xstep",1   // Ending shoulder.
//           ]);
// Example: Making an interior ogee
//   %render() difference() {
//       move(-[5,0,5]) cube(30, anchor=BOT+LEFT);
//       cube(310, anchor=BOT+LEFT);
//   }
//   xrot(90)
//       linear_extrude(height=30, center=true)
//           mask2d_ogee([
//               "xstep", 1, "round",5,
//               "ystep",1, "fillet",5,
//               "xstep", 1, "ystep", 1,
//           ]);
module mask2d_ogee(pattern, excess=0.01, anchor=CENTER,spin=0) {
    path = mask2d_ogee(pattern, excess=excess);
    attachable(anchor,spin, two_d=true, path=path) {
        polygon(path);
        children();
    }
}

function mask2d_ogee(pattern, excess=0.01, anchor=CENTER, spin=0) =
    assert(is_list(pattern))
    assert(len(pattern)>0)
    assert(len(pattern)%2==0,"pattern must be a list of TYPE, VAL pairs.")
    assert(all([for (i = idx(pattern,step=2)) in_list(pattern[i],["step","xstep","ystep","round","fillet"])]))
    let(
        x = concat([0], cumsum([
            for (i=idx(pattern,step=2)) let(
                type = pattern[i],
                val = pattern[i+1]
            ) (
                type=="step"?   val.x :
                type=="xstep"?  val :
                type=="round"?  val :
                type=="fillet"? val :
                0
            )
        ])),
        y = concat([0], cumsum([
            for (i=idx(pattern,step=2)) let(
                type = pattern[i],
                val = pattern[i+1]
            ) (
                type=="step"?   val.y :
                type=="ystep"?  val :
                type=="round"?  val :
                type=="fillet"? val :
                0
            )
        ])),
        tot_x = last(x),
        tot_y = last(y),
        data = [
            for (i=idx(pattern,step=2)) let(
                type = pattern[i],
                val = pattern[i+1],
                pt = [x[i/2], tot_y-y[i/2]] + (
                    type=="step"?   [val.x,-val.y] :
                    type=="xstep"?  [val,0] :
                    type=="ystep"?  [0,-val] :
                    type=="round"?  [val,0] :
                    type=="fillet"? [0,-val] :
                    [0,0]
                )
            ) [type, val, pt]
        ],
        path = [
            [tot_x,-excess],
            [-excess,-excess],
            [-excess,tot_y],
            for (pat = data) each
                pat[0]=="step"?  [pat[2]] :
                pat[0]=="xstep"? [pat[2]] :
                pat[0]=="ystep"? [pat[2]] :
                let(
                    r = pat[1],
                    steps = segs(abs(r)),
                    step = 90/steps
                ) [
                    for (i=[0:1:steps]) let(
                        a = pat[0]=="round"? (180+i*step) : (90-i*step)
                    ) pat[2] + abs(r)*[cos(a),sin(a)]
                ]
        ],
        path2 = deduplicate(path)
    ) reorient(anchor,spin, two_d=true, path=path2, p=path2);


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
