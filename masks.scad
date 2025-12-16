//////////////////////////////////////////////////////////////////////
// LibFile: masks.scad
//   This file provides 2D and 3D masks that you can use to add edge treatments to your models.
//   You can apply 2D masking shapes with {{edge_profile()}} to mask edges of cubes,
//   prismoids or cylinders creating edge treatments like roundovers, chamfers, or more elaborate shapes like
//   like the cove and ogee found in furniture and architecture.  You can also create 3D masks
//   objects that you can apply to specific edges or corners.  
// Includes:
//   include <BOSL2/std.scad>
// FileGroup: Basic Modeling
// FileSummary: Masking shapes for edge profiling including roundover, cove, teardrop, ogee.
// FileFootnotes: STD=Included in std.scad
//////////////////////////////////////////////////////////////////////

_BOSL2_MASKS = is_undef(_BOSL2_STD) && (is_undef(BOSL2_NO_STD_WARNING) || !BOSL2_NO_STD_WARNING) ?
       echo("Warning: masks.scad included without std.scad; dependencies may be missing\nSet BOSL2_NO_STD_WARNING = true to mute this warning.") true : true;


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
//   .
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
//   mask_angle = Number of degrees in the corner angle to mask.  Default: $edge_angle if defined, otherwise 90
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
module mask2d_roundover(r, inset=0, mask_angle, excess=0.01, flat_top, d, h, height, cut, quarter_round=false, joint, anchor=CENTER,spin=0, clip_angle) {
    path = mask2d_roundover(r=r, d=d, h=h, height=height, cut=cut, joint=joint, inset=inset, clip_angle=clip_angle, 
                            flat_top=flat_top, mask_angle=mask_angle, excess=excess, quarter_round=quarter_round);
    attachable(anchor,spin, two_d=true, path=path) {
        polygon(path);
        children();
    }
}



function mask2d_roundover(r, inset=0, mask_angle=90, excess=0.01, clip_angle, flat_top, quarter_round=false, d, h, height, cut, joint, anchor=CENTER, spin=0) =
    let(mask_angle = first_defined([mask_angle, $edge_angle, 90]))
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


// Function&Module: mask2d_smooth()
// Synopsis: Creates a continuous curvature mask for rounding edges.
// SynTags: Geom, Path
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable, Masks (2D)
// See Also: corner_profile(), edge_profile(), face_profile()
// Usage: As module
//   mask2d_smooth([mask_angle], [cut=], [joint=], [inset=], [excess=], [flat_top=], [anchor=], [spin=]) [ATTACHMENTS];
// Usage: As function
//   path = mask2d_smooth([mask_angle], [cut=], [joint=], [inset=], [excess=], [flat_top=], [anchor=], [spin=]);
// Description:
//   Creates a 2D continuous curvature rounding mask shape that is useful for extruding into a 3D mask for an edge.
//   Conversely, you can use that same extruded shape to make an interior fillet between two walls.
//   As a 2D mask, this is designed to be differenced away from the edge of a shape that with its corner at the
//   origin and one edge on the X+ axis and the other mask_angle degrees counterclockwise from the X+ axis.  
//   If called as a function, returns a 2D path of the outline of the mask shape.
//   .
//   The roundover can be specified by joint length or cut distance.  (Radius is not meaningful for this type of mask.)  You must also specify the
//   continuous curvature smoothness parameter, `k`, which defaults to 0.5.  This diagram shows a roundover for the default k value.
//   .
//   ![Types of Roundovers](images/rounding/figure_1_2.png)
//   .
//   With `k=0.75` the transition into the roundover is shorter and faster.  The cut length is bigger for the same joint length.
//   .
//   ![Types of Roundovers](images/rounding/figure_1_3.png)
//   .
//   The diagrams above show symmetric roundovers, but you can also create asymmetric roundovers by giving a list of two values for `joint`.  In this
//   case the first one is the horizontal joint length and the second one is the joint length along the other side of the rounding.  
//   .
//   If you need roundings to agree on edges of different mask_angle, e.g. to round the base of a prismoid, then you need all of the
//   masks used to have the same height.  (Note that it may appear that matching joint would also work, but it does not because the joint distances are measured
//   in different directions.)  You can get the same height by setting the joint parameter to a scalar to define the joint length in the horizontal direction and then setting
//   the `height` parameter, which determines the length of the other joint so that it has the desired height.  
// Arguments:
//   mask_angle = Number of degrees in the corner angle to mask.  Default: $edge_angle if set, 90 otherwise
//   ---
//   inset = Optional bead inset size, perpendicular to the two edges.  Scalar or 2-vector.  Default: 0
//   excess = Extra amount of mask shape to creates on the X and quasi-Y sides of the shape.  Default: 0.01
//   cut = Cut distance.  IE: How much of the corner to cut off.  See [Types of Roundovers](rounding.scad#section-types-of-roundovers).
//   joint = Joint distance.  IE: How far from the edge the roundover should start.  See [Types of Roundovers](rounding.scad#section-types-of-roundovers).
//   h / height = Mask height excluding inset and excess.  This determines the height of the mask when you want a consistent mask height, no matter what the mask angle.  You must provide a scalar joint value to define the mask width, and you cannot give cut.  
//   flat_top = If true, the top inset of the mask will be horizontal instead of angled by the mask_angle.  Default: false
//   splinesteps = Numbers of segments to create on the roundover.  Default: 16
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
// Example(2D): Mask defined by cut
//   mask2d_smooth(cut=3);
// Example(2D): Mask defined by symmetric joint length with larger excess (which helps show the ends of the mask)
//   mask2d_smooth(joint=10,excess=0.5);
// Example(2D): Asymmetric mask by joint length with different lengths
//   mask2d_smooth(joint=[10,7],excess=0.5);
// Example(2D): Acute angle mask by cut
//   mask2d_smooth(mask_angle=66,cut=3,excess=0.5);
// Example(2D): Acute angle mask by cut, but large k value
//   mask2d_smooth(mask_angle=66,cut=3,excess=0.5, k=.9);
// Example(2D): Acute angle mask by cut, but small k value
//   mask2d_smooth(mask_angle=66,cut=3,excess=0.5, k=.2);
// Example(2D): Obtuse angle mask
//   mask2d_smooth(mask_angle=116,joint=12,excess=0.5);
// Example(2D): Inset mask
//   mask2d_smooth(mask_angle=75,joint=12,inset=2);
// Example(2D): Inset mask, flat top
//   mask2d_smooth(mask_angle=75,joint=12,inset=2, flat_top=true);
// Example(3D): Masking by Edge Attachment
//   diff()
//   cube([50,60,70],center=true)
//       edge_profile([TOP,"Z"],except=[BACK,TOP+LEFT])
//           mask2d_smooth(cut=3);
// Example(3D): Masking a cylinder by edge attachment
//   diff()
//   cyl(h=25,d=15)
//       edge_profile()
//           mask2d_smooth(joint=5);
// Example(3D,Med,VPT=[25,30,12],VPR=[68,0,12],VPD=180): Rounding over top of an extreme prismoid using height option
//   diff()
//     prismoid([30,20], [50,60], h=20, shift=[40,50])
//        edge_profile(TOP, excess=27)
//           mask2d_smooth(height=5, joint=5);

function mask2d_smooth( mask_angle,  cut, joint, height, h, k=0.5, excess=.01, inset=0,flat_top=false,splinesteps=16,anchor=CENTER,spin=0) =
    let(
         mask_angle=first_defined([mask_angle, $edge_angle, 90]),
         inset = is_list(inset)? inset : [inset,inset],
         height = one_defined([h,height], "h,height",dflt=undef)
    )
    assert(num_defined([cut,joint])==1, "Must define exactly one of cut and joint")
    assert(num_defined([height,cut])<2, "With height cannot give a cut value")
    assert(is_undef(cut) || all_positive([cut]), "cut must be a positive value")
    assert(is_undef(joint) || (is_finite(joint) && joint>0) || (is_vector(joint) && all_positive(joint)),
           "joint must be a positive value or list of two positive values")
    assert(is_undef(height) || is_finite(joint), "With height must give a scalar joint value")
    assert(all_nonnegative([excess]), "excess must be a nonnegative value")
    assert(is_finite(mask_angle) && mask_angle>0 && mask_angle<180)
    assert(is_finite(k) && k>=0 && k<=1, "k must be a number between 0 and 1")
    assert(is_vector(inset,2) && all_nonnegative(inset), "inset must be a nonnegative value or a list of two such values")
    let(

         joint = is_def(cut)? 8*cut/cos(mask_angle/2)/(1+4*k)*[1,1]
               : is_def(height) ? [joint, height/sin(mask_angle)]
               : force_list(joint,2),
         angle_path = [
                        zrot(mask_angle, [joint[1],0]),
                        [0,0],
                        [joint[0],0],
                      ],
         outside_corner = _inset_corner(angle_path, mask_angle, inset, excess, flat_top),
         bez = _smooth_bez_fill(outside_corner[1],k),
         path = deduplicate([
                              each outside_corner[0],
                              each bezier_curve(bez, splinesteps=splinesteps)
                            ],
                            closed=true)
     )
     reorient(anchor,spin, two_d=true, path=path, extent=false, p=path);

module mask2d_smooth(mask_angle, cut, joint, height, h, k=0.5, excess=.01, inset=0, flat_top=false, splinesteps=16, anchor=CENTER, spin=0)
{
    path = mask2d_smooth(mask_angle=mask_angle, cut=cut, joint=joint, height=height, h=h, k=k, excess=excess, inset=inset,
                         flat_top=flat_top, splinesteps=splinesteps,anchor=anchor, spin=spin);
    attachable(anchor,spin, two_d=true, path=path) {
        polygon(path);
        children();
    }
}


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
//   .
//   ![Types of Roundovers](images/rounding/figure_1_1.png)
// Arguments:
//   r = Radius of the rounding.
//   angle = The angle from vertical of the flat section.  Must be between mask_angle-90 and 90 degrees.  Default: 45.  
//   inset = Optional bead inset size perpendicular to edges.  Default: 0
//   mask_angle = Number of degrees in the corner angle to mask.  Default: $edge_angle if defined, otherwise 90
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
    let(mask_angle = first_defined([mask_angle, $edge_angle, 90]))
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
    


module mask2d_teardrop(r, angle=45, mask_angle, excess=0.01, inset=0, flat_top=false, height, d, h, cut, joint, anchor=CENTER, spin=0) {
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
//   mask_angle = Number of degrees in the corner angle to mask.  Default: $edge_angle if defined, otherwise 90
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

module mask2d_cove(r, inset=0, mask_angle, excess=0.01, flat_top, bulge, d, h, height, quarter_round=false, anchor=CENTER, spin=0)
{
    path = mask2d_cove(r=r, d=d, h=h, height=height, bulge=bulge, flat_top=flat_top, quarter_round=quarter_round, inset=inset, mask_angle=mask_angle, excess=excess);
    attachable(anchor,spin, two_d=true, path=path) {
        polygon(path);
        children();
    }
}


function mask2d_cove(r, inset=0, mask_angle=90, excess=0.01, flat_top, d, h, height,bulge, quarter_round=false, anchor=CENTER, spin=0) =
    let(mask_angle = first_defined([mask_angle, $edge_angle, 90]))
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
//   mask_angle = Number of degrees in the corner angle to mask.  Default: $edge_angle if defined, otherwise 90
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
    let(mask_angle = first_defined([mask_angle, $edge_angle, 90]))
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
//   mask_angle = Number of degrees in the corner angle to mask.  Default: $edge_angle if defined, otherwise 90
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
    let(mask_angle = first_defined([mask_angle, $edge_angle, 90]))
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
//   mask_angle = Number of degrees in the corner angle to mask.  Default: $edge_angle if defined, otherwise 90
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
    let(mask_angle = first_defined([mask_angle, $edge_angle, 90]))
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


// Section: Modules for Applying 2D Masks

// Module: face_profile()
// Synopsis: Extrudes a 2D edge profile into a mask for all edges and corners of the given faces on the parent.
// SynTags: Geom
// Topics: Attachments, Masking
// See Also: attachable(), position(), attach(), edge_profile(), corner_profile(), face_mask(), edge_mask(), corner_mask()
// Usage:
//   PARENT() face_profile(faces, r|d=, [convexity=]) CHILDREN;
// Description:
//   Given a 2D edge profile, extrudes it into a mask for all edges and corners bounding each given face. If no tag is set
//   then `face_profile` sets the tag for children to "remove" so that it works with the default {{diff()}} tag.
//   See  [Specifying Faces](attachments.scad#subsection-specifying-faces) for information on specifying faces.
//   For a step-by-step explanation of masking attachments, see the [Attachments Tutorial](Tutorial-Attachment-Edge-Profiling).
// Arguments:
//   faces = Faces to mask edges and corners of.
//   r = Radius of corner mask.
//   ---
//   d = Diameter of corner mask.
//   excess = Excess length to extrude the profile to make edge masks.  Default: 0.01
//   convexity = Max number of times a line could intersect the perimeter of the mask shape.  Default: 10
// Side Effects:
//   Tags the children with "remove" (and hence sets `$tag`) if no tag is already set.
//   `$idx` is set to the index number of each face.
//   `$attach_anchor` is set for each edge or corner given, to the `[ANCHOR, POSITION, ORIENT, SPIN]` information for that anchor.
//   `$profile_type` is set to `"edge"` or `"corner"`, depending on what is being masked.
// Example:
//   diff()
//   cube([50,60,70],center=true)
//       face_profile(TOP,r=10)
//           mask2d_roundover(r=10);
module face_profile(faces=[], r, d, excess=0.01, convexity=10) {
    req_children($children);
    faces = is_vector(faces)? [faces] : faces;
    assert(all([for (face=faces) is_vector(face) && sum([for (x=face) x!=0? 1 : 0])==1]), "\nVector in faces doesn't point at a face.");
    r = get_radius(r=r, d=d, dflt=undef);
    assert(is_num(r) && r>=0);
    edge_profile(faces, excess=excess) children();
    corner_profile(faces, convexity=convexity, r=r) children();
}


// Module: edge_profile()
// Synopsis: Extrudes a 2d edge profile into a mask on the given edges of the parent.
// SynTags: Geom
// Topics: Attachments, Masking
// See Also: attachable(), position(), attach(), face_profile(), edge_profile_asym(), corner_profile(), edge_mask(), face_mask(), corner_mask()
// Usage:
//   PARENT() edge_profile([edges], [except], [convexity]) CHILDREN;
// Description:
//   Takes a 2D mask shape and attaches it to the selected edges, with the appropriate orientation and
//   extruded length to be `diff()`ed away, to give the edge a matching profile.  If no tag is set
//   then `edge_profile` sets the tag for children to "remove" so that it works with the default {{diff()}} tag.
//   For details on specifying the edges to mask see [Specifying Edges](attachments.scad#subsection-specifying-edges).
//   For a step-by-step explanation of masking attachments, see the [Attachments Tutorial](Tutorial-Attachment-Edge-Profiling).
// Arguments:
//   edges = Edges to mask.  See [Specifying Edges](attachments.scad#subsection-specifying-edges).  Default: All edges.
//   except = Edges to explicitly NOT mask.  See [Specifying Edges](attachments.scad#subsection-specifying-edges).  Default: No edges.
//   excess = Excess length to extrude the profile to make edge masks.  Default: 0.01
//   convexity = Max number of times a line could intersect the perimeter of the mask shape.  Default: 10
// Side Effects:
//   Tags the children with "remove" (and hence sets `$tag`) if no tag is already set.
//   `$idx` is set to the index number of each edge.
//   `$attach_anchor` is set for each edge given, to the `[ANCHOR, POSITION, ORIENT, SPIN]` information for that anchor.
//   `$profile_type` is set to `"edge"`.
//   `$edge_angle` is set to the inner angle of the current edge.
// Example:
//   diff()
//   cube([50,60,70],center=true)
//       edge_profile([TOP,"Z"],except=[BACK,TOP+LEFT])
//           mask2d_roundover(r=10, inset=2);
// Example: Using $edge_angle on a conoid
//   diff()
//   cyl(d1=50, d2=30, l=40, anchor=BOT) {
//       edge_profile([TOP,BOT], excess=10, convexity=6) {
//           mask2d_roundover(r=8, inset=1, excess=1, mask_angle=$edge_angle);
//       }
//   }
// Example: Using $edge_angle on a prismoid
//   diff()
//   prismoid([60,50],[30,20],h=40,shift=[-25,15]) {
//       edge_profile(excess=10, convexity=20) {
//           mask2d_roundover(r=5,inset=1,mask_angle=$edge_angle,$fn=32);
//       }
//   }

module edge_profile(edges=EDGES_ALL, except=[], excess=0.01, convexity=10) {
    req_children($children);
    check1 = assert($parent_geom != undef, "\nNo object to attach to!");
    conoid = $parent_geom[0] == "conoid";
    edges = !conoid? _edges(edges, except=except) :
        edges==EDGES_ALL? [TOP,BOT] :
        assert(all([for (e=edges) in_list(e,[TOP,BOT])]), "\nInvalid conoid edge spec.")
        edges;
    vecs = conoid
      ? [for (e=edges) e+FWD]
      : [
            for (i = [0:3], axis=[0:2])
            if (edges[axis][i]>0)
            EDGE_OFFSETS[axis][i]
        ];
    all_vecs_are_edges = all([for (vec = vecs) sum(v_abs(vec))==2]);
    check2 = assert(all_vecs_are_edges, "\nAll vectors must be edges.");
    default_tag("remove")
    for ($idx = idx(vecs)) {
        vec = vecs[$idx];
        anch = _find_anchor(vec, $parent_geom);
        path_angs_T = _attach_geom_edge_path($parent_geom, vec);
        path = path_angs_T[0];
        vecs = path_angs_T[1];
        post_T = path_angs_T[2];
        $attach_to = undef;
        $attach_anchor = anch;
        $profile_type = "edge";
        multmatrix(post_T) {
            for (i = idx(path,e=-2)) {
                pt1 = select(path,i);
                pt2 = select(path,i+1);
                cp = (pt1 + pt2) / 2;
                v1 = vecs[i][0];
                v2 = vecs[i][1];
                $edge_angle = 180 - vector_angle(v1,v2);
                if (!approx(pt1,pt2)) {
                    seglen = norm(pt2-pt1) + 2 * excess;
                    move(cp) {
                        frame_map(x=-v2, z=unit(pt2-pt1)) {
                            linear_extrude(height=seglen, center=true, convexity=convexity)
                                mirror([-1,1]) children();
                        }
                    }
                }
            }
        }
    }
}


// Module: edge_profile_asym()
// Synopsis: Extrudes an asymmetric 2D profile into a mask on the given edges and corners of the parent.
// SynTags: Geom
// Topics: Attachments, Masking
// See Also: attachable(), position(), attach(), face_profile(), edge_profile(), corner_profile(), edge_mask(), face_mask(), corner_mask()
// Usage:
//   PARENT() edge_profile([edges], [except], [convexity=], [flip=], [corner_type=]) CHILDREN;
// Description:
//   Takes an asymmetric 2D mask shape and attaches it to the selected edges and corners, with the appropriate
//   orientation and extruded length to be `diff()`ed away, to give the edges and corners a matching profile.
//   If no tag is set then `edge_profile_asym()` sets the tag for children to "remove" so that it works
//   with the default {{diff()}} tag.  For details on specifying the edges to mask see [Specifying Edges](attachments.scad#subsection-specifying-edges).
//   For a step-by-step explanation of masking attachments, see the [Attachments Tutorial](Tutorial-Attachment-Edge-Profiling).
//   The asymmetric profiles are joined consistently at the corners.  This is impossible if all three edges at a corner use the profile, hence
//   this situation is not permitted.  The profile orientation can be inverted using the `flip=true` parameter.
//   .
//   The standard profiles are located in the first quadrant and have positive X values.  If you provide a profile located in the second quadrant,
//   where the X values are negative, then it produces a fillet.  You can flip any of the standard profiles using {{xflip()}}.
//   Do **not** flip one of the standard first quadrant masks into the 4th quadrant $(y<0)$ using {{yflip()}}, as this will not work correctly.  
//   Fillets are always asymmetric because at a given edge, they can blend in two different directions, so even for symmetric profiles,
//   the asymmetric logic is required.  You can set the `corner_type` parameter to select rounded, chamfered or sharp corners.
//   However, when the corners are inside (concave) corners, you must provide the size of the profile ([width,height]), because the
//   this information is required to produce the correct corner and cannot be obtain from the profile itself, which is a child object.
//   .
//   Because the profiles are asymmetric they can be placed on a given edge in two different orientations.  It is easiest to understand
//   the orientation by thinking about fillets and in which direction a filleted cube will make a smooth joint.  Given a string of connected
//   edges, we must identify the orientation of the fillet at just one edge; the orentation of the fillets on the remaining edges is forced
//   to maintain consistency across the string of edges.  The module uses a set of priority rules as follows:
//   .
//     1. Bottom
//     2. Top
//     3. Front or Back
//   . 
//   What this means is that if an edge string contains any edge on the bottom then the bottom edges will be oriented to join the bottom face
//   to something, and the rest of the string consistently oriented.  If the string contains no bottom edges but it has top edges then 
//   the edge string will be oriented so that the object can join its top face to something.  If the string has no top or bottom edges then it
//   must be just a single edge and it will be is oriented so that either the front or back face of the cube can make a smooth joint.
//   If the edge orientation is reversed from what you need, set `flip=true`.  If these rules seem complicated, just create your model,
//   examine the edges, and flip them as required.  Note that creating fillets with {{yflip()}} may seem similar to setting `flip=true` and
//   may partially work but is **not** the correct way to flip edge profile; it can produce incomplete results.  
//   
// Arguments:
//   edges = Edges to mask.  See [Specifying Edges](attachments.scad#subsection-specifying-edges).  Default: All edges.
//   except = Edges to explicitly NOT mask.  See [Specifying Edges](attachments.scad#subsection-specifying-edges).  Default: No edges.
//   ---
//   excess = Excess length to extrude the profile to make edge masks.  Default: 0.01
//   convexity = Max number of times a line could intersect the perimeter of the mask shape.  Default: 10
//   flip = If true, reverses the orientation of any external profile parts at each edge.  Default false
//   corner_type = Specifies how exterior corners should be formed.  Must be one of `"none"`, `"chamfer"`, `"round"`, or `"sharp"`.  Default: `"none"`
//   size = If given the width and height of the 2D profile, enable rounding and chamfering of internal corners when given a negative profile.
// Side Effects:
//   Tags the children with "remove" (and hence sets `$tag`) if no tag is already set.
//   `$idx` is set to the index number of each edge.
//   `$attach_anchor` is set for each edge given, to the `[ANCHOR, POSITION, ORIENT, SPIN]` information for that anchor.
//   `$profile_type` is set to `"edge"`.
//   `$edge_angle` is set to the inner angle of the current edge.
// Example:
//   ogee = [
//       "xstep",1,  "ystep",1,  // Starting shoulder.
//       "fillet",5, "round",5,  // S-curve.
//       "ystep",1,  "xstep",1   // Ending shoulder.
//   ];
//   diff()
//   cuboid(50) {
//       edge_profile_asym(FRONT)
//          mask2d_ogee(ogee);
//   }
// Example: Flipped
//   ogee = [
//       "xstep",1,  "ystep",1,  // Starting shoulder.
//       "fillet",5, "round",5,  // S-curve.
//       "ystep",1,  "xstep",1   // Ending shoulder.
//   ];
//   diff()
//   cuboid(50) {
//       edge_profile_asym(FRONT, flip=true)
//          mask2d_ogee(ogee);
//   }
// Example: Negative Chamfering
//   cuboid(50) {
//       edge_profile_asym(FWD, flip=false)
//           xflip() mask2d_chamfer(10);
//       edge_profile_asym(BACK, flip=true, corner_type="sharp")
//           xflip() mask2d_chamfer(10);
//   }
// Example: Negative Roundings
//   cuboid(50) {
//       edge_profile_asym(FWD, flip=false)
//           xflip() mask2d_roundover(10);
//       edge_profile_asym(BACK, flip=true, corner_type="round")
//           xflip() mask2d_roundover(10);
//   }
// Example: Cornerless
//   cuboid(50) {
//       edge_profile_asym(
//           "ALL", except=[TOP+FWD+RIGHT, BOT+BACK+LEFT]
//        ) xflip() mask2d_roundover(10);
//   }
// Example: More complicated edge sets
//   cuboid(50) {
//       edge_profile_asym(
//           [FWD,BACK,BOT+RIGHT], except=[FWD+RIGHT,BOT+BACK],
//           corner_type="round"
//        ) xflip() mask2d_roundover(10);
//   }
// Example: Mixing it up a bit.
//   diff()
//   cuboid(60) {
//       tag("keep") edge_profile_asym(LEFT, flip=true, corner_type="chamfer")
//           xflip() mask2d_chamfer(10);
//       edge_profile_asym(RIGHT)
//           mask2d_roundover(10);
//   }
// Example: Chamfering internal corners.
//   cuboid(40) {
//       edge_profile_asym(
//           [FWD+DOWN,FWD+LEFT],
//           corner_type="chamfer", size=[10,10]/sqrt(2)
//        ) xflip() mask2d_chamfer(10);
//   }
// Example: Rounding internal corners.
//   cuboid(40) {
//       edge_profile_asym(
//           [FWD+DOWN,FWD+LEFT],
//           corner_type="round", size=[10,10]
//        ) xflip() mask2d_roundover(10);
//   }
// Example(3D,NoScales): This string of 3 edges rounds so that the cuboid joins smoothly to the bottom
//   color_this("lightblue")cuboid([70,70,10])
//     attach(TOP,BOT,align=RIGHT+BACK)
//       cuboid(50) 
//         edge_profile_asym([BOT+FRONT, RIGHT+FRONT, TOP+RIGHT],corner_type="round")
//            xflip()mask2d_roundover(10);
// Example(3D,NoScales): No top or bottom edges appear in the edge set, so the edges are oriented to joint smoothly to the FRONT and BACK
//   color_this("lightblue") cuboid([90,10,50])
//     align(FWD) cuboid(50){
//       edge_profile_asym("Z",corner_type="round")
//         xflip() mask2d_roundover(10);
//       align(FWD)
//         color_this("lightblue") cuboid([90,10,50]);
//     }

module edge_profile_asym(
    edges=EDGES_ALL, except=[],
    excess=0.01, convexity=10,
    flip=false, corner_type="none",
    size=[0,0]
) {
    function _corner_orientation(pos,pvec) =
        let(
            j = [for (i=[0:2]) if (pvec[i]) i][0],
            T = (pos.x>0? xflip() : ident(4)) *
                (pos.y>0? yflip() : ident(4)) *
                (pos.z>0? zflip() : ident(4)) *
                rot(-120*(2-j), v=[1,1,1])
        ) T;

    function _default_edge_orientation(edge) =
        edge.z < 0? [[-edge.x,-edge.y,0], UP] :
        edge.z > 0? [[-edge.x,-edge.y,0], DOWN] :
        edge.y < 0? [[-edge.x,0,0], BACK] :
        [[-edge.x,0,0], FWD] ;

    function _edge_transition_needs_flip(from,to) =
        let(
            flip_edges = [
                [BOT+FWD, [FWD+LEFT, FWD+RIGHT]],
                [BOT+BACK, [BACK+LEFT, BACK+RIGHT]],
                [BOT+LEFT, []],
                [BOT+RIGHT, []],
                [TOP+FWD, [FWD+LEFT, FWD+RIGHT]],
                [TOP+BACK, [BACK+LEFT, BACK+RIGHT]],
                [TOP+LEFT, []],
                [TOP+RIGHT, []],
                [FWD+LEFT, [TOP+FWD, BOT+FWD]],
                [FWD+RIGHT, [TOP+FWD, BOT+FWD]],
                [BACK+LEFT, [TOP+BACK, BOT+BACK]],
                [BACK+RIGHT, [TOP+BACK, BOT+BACK]],
            ],
            i = search([from], flip_edges, num_returns_per_match=1)[0],
            check = assert(i!=[], "\nBad edge vector.")
        ) in_list(to,flip_edges[i][1]);

    function _edge_corner_numbers(vec) =
        let(
            v2 = [for (i=idx(vec)) vec[i]? (vec[i]+1)/2*pow(2,i) : 0],
            off = v2.x + v2.y + v2.z,
            xs = [0, if (!vec.x) 1],
            ys = [0, if (!vec.y) 2],
            zs = [0, if (!vec.z) 4]
        ) [for (x=xs, y=ys, z=zs) x+y+z + off];

    function _gather_contiguous_edges(edge_corners) =
        let(
            no_tri_corners = all([for(cn = [0:7]) len([for (ec=edge_corners) if(in_list(cn,ec[1])) 1])<3]),
            check = assert(no_tri_corners, "\nCannot have three edges that meet at the same corner.")
        )
        _gather_contiguous_edges_r(
            [for (i=idx(edge_corners)) if(i) edge_corners[i]],
            edge_corners[0][1],
            [edge_corners[0][0]], []);

    function _gather_contiguous_edges_r(edge_corners, ecns, curr, out) =
        len(edge_corners)==0? [each out, curr] :
        let(
            i1 = [
                for (i = idx(edge_corners))
                if (in_list(ecns[0], edge_corners[i][1]))
                i
            ],
            i2 = [
                for (i = idx(edge_corners))
                if (in_list(ecns[1], edge_corners[i][1]))
                i
            ]
        ) !i1 && !i2? _gather_contiguous_edges_r(
            [for (i=idx(edge_corners)) if(i) edge_corners[i]],
            edge_corners[0][1],
            [edge_corners[0][0]],
            [each out, curr]
        ) : let(
            nu_curr = [
                if (i1) edge_corners[i1[0]][0],
                each curr,
                if (i2) edge_corners[i2[0]][0],
            ],
            nu_ecns = [
                if (!i1) ecns[0] else [
                    for (ecn = edge_corners[i1[0]][1])
                    if (ecn != ecns[0]) ecn
                ][0],
                if (!i2) ecns[1] else [
                    for (ecn = edge_corners[i2[0]][1])
                    if (ecn != ecns[1]) ecn
                ][0],
            ],
            rem = [
                for (i = idx(edge_corners))
                if (i != i1[0] && i != i2[0])
                edge_corners[i]
            ]
        )
        _gather_contiguous_edges_r(rem, nu_ecns, nu_curr, out);

    function _edge_transition_inversions(edge_string) =
        let(
            // boolean cumulative sum
            bcs = function(list, i=0, inv=false, out=[])
                    i>=len(list)? out :
                    let( nu_inv = list[i]? !inv : inv )
                    bcs(list, i+1, nu_inv, [each out, nu_inv]),
            inverts = bcs([
                false,
                for(i = idx(edge_string)) if (i)
                    _edge_transition_needs_flip(
                        edge_string[i-1],
                        edge_string[i]
                    )
            ]),
            boti = [for(i = idx(edge_string)) if (edge_string[i].z<0) i],
            topi = [for(i = idx(edge_string)) if (edge_string[i].z>0) i],
            lfti = [for(i = idx(edge_string)) if (edge_string[i].x<0) i],
            rgti = [for(i = idx(edge_string)) if (edge_string[i].x>0) i],
            idx = [for (m = [boti, topi, lfti, rgti]) if(m) m[0]][0],
            rinverts = inverts[idx] == false? inverts : [for (x = inverts) !x]
        ) rinverts;

    function _is_closed_edge_loop(edge_string) =
        let(
            e1 = edge_string[0],
            e2 = last(edge_string)
        )
        len([for (i=[0:2]) if (abs(e1[i])==1 && e1[i]==e2[i]) 1]) == 1 &&
        len([for (i=[0:2]) if (e1[i]==0 && abs(e2[i])==1) 1]) == 1 &&
        len([for (i=[0:2]) if (e2[i]==0 && abs(e1[i])==1) 1]) == 1;

    function _edge_pair_perp_vec(e1,e2) =
        [for (i=[0:2]) if (abs(e1[i])==1 && e1[i]==e2[i]) -e1[i] else 0];

    req_children($children);
    check1 = assert($parent_geom != undef, "\nNo object to attach to!")
        assert(in_list(corner_type, ["none", "round", "chamfer", "sharp"]))
        assert(is_bool(flip));
    edges = _edges(edges, except=except);
    vecs = [
        for (i = [0:3], axis=[0:2])
        if (edges[axis][i]>0)
        EDGE_OFFSETS[axis][i]
    ];
    all_vecs_are_edges = all([for (vec = vecs) sum(v_abs(vec))==2]);
    check2 = assert(all_vecs_are_edges, "\nAll vectors must be edges.");
    edge_corners = [for (vec = vecs) [vec, _edge_corner_numbers(vec)]];
    edge_strings = _gather_contiguous_edges(edge_corners);
    default_tag("remove")
    for (edge_string = edge_strings) {
        inverts = _edge_transition_inversions(edge_string);
        flipverts = [for (x = inverts) flip? !x : x];
        vecpairs = [
            for (i = idx(edge_string))
            let (p = _default_edge_orientation(edge_string[i]))
            flipverts[i]? [p.y,p.x] : p
        ];
        is_loop = _is_closed_edge_loop(edge_string);
        for (i = idx(edge_string)) {
            if (corner_type!="none" && (i || is_loop)) {
                e1 = select(edge_string,i-1);
                e2 = select(edge_string,i);
                vp1 = select(vecpairs,i-1);
                vp2 = select(vecpairs,i);
                pvec = _edge_pair_perp_vec(e1,e2);
                pos = [for (i=[0:2]) e1[i]? e1[i] : e2[i]];
                mirT = _corner_orientation(pos, pvec);
                $attach_to = undef;
                $attach_anchor = _find_anchor(pos, $parent_geom);
                $profile_type = "corner";
                position(pos) {
                    multmatrix(mirT) {
                        if (vp1.x == vp2.x && size.y > 0) {
                            zflip() {
                                if (corner_type=="chamfer") {
                                    fn = $fn;
                                    move([size.y,size.y]) {
                                        rotate_extrude(angle=90, $fn=4)
                                            left_half(planar=true, $fn=fn)
                                                zrot(-90) fwd(size.y) children();
                                    }
                                    difference() {
                                        down(0.01) cube([size.x, size.x, size.y+0.01]);
                                        move([size.x+0.01, size.x+0.01])
                                            zrot(180)
                                                rotate_extrude(angle=90, $fn=4)
                                                    square([size.x+0.01, size.y+0.01]);
                                    }
                                } else if (corner_type=="round") {
                                    move([size.y,size.y]) {
                                        rotate_extrude(angle=90)
                                            left_half(planar=true)
                                                zrot(-90) fwd(size.y) children();
                                    }
                                    difference() {
                                        down(0.01) cube([size.x, size.x, size.y+0.01]);
                                        move([size.x+0.01, size.x+0.01])
                                            zrot(180)
                                                rotate_extrude(angle=90)
                                                    square([size.x+0.01, size.y+0.01]);
                                    }
                                }
                            }
                        } else if (vp1.y == vp2.y) {
                            if (corner_type=="chamfer") {
                                fn = $fn;
                                rotate_extrude(angle=90, $fn=4)
                                    right_half(planar=true, $fn=fn)
                                        children();
                                rotate_extrude(angle=90, $fn=4)
                                    left_half(planar=true, $fn=fn)
                                        children();
                            } else if (corner_type=="round") {
                                rotate_extrude(angle=90)
                                    right_half(planar=true)
                                        children();
                                rotate_extrude(angle=90)
                                    left_half(planar=true)
                                        children();
                            } else { //corner_type == "sharp"
                                intersection() {
                                    rot([90,0, 0]) linear_extrude(height=100,center=true,convexity=convexity) children();
                                    rot([90,0,90]) linear_extrude(height=100,center=true,convexity=convexity) children();
                                }
                            }
                        }
                    }
                }
            }
        }
        for (i = idx(edge_string)) {
            $attach_to = undef;
            $attach_anchor = _find_anchor(edge_string[i], $parent_geom);
            $profile_type = "edge";
            edge_profile(edge_string[i], excess=excess, convexity=convexity) {
                if (flipverts[i]) {
                    mirror([-1,1]) children();
                } else {
                    children();
                }
            }
        }
    }
}



// Module: corner_profile()
// Synopsis: Rotationally extrudes a 2d edge profile into corner mask on the given corners of the parent.
// SynTags: Geom
// Topics: Attachments, Masking
// See Also: attachable(), position(), attach(), face_profile(), edge_profile(), corner_mask(), face_mask(), edge_mask()
// Usage:
//   PARENT() corner_profile([corners], [except], [r=|d=], [convexity=]) CHILDREN;
// Description:
//   Takes a 2D mask shape, rotationally extrudes and converts it into a corner mask, and attaches it
//   to the selected corners with the appropriate orientation. If no tag is set then `corner_profile()`
//   sets the tag for children to "remove" so that it works with the default {{diff()}} tag.
//   See [Specifying Corners](attachments.scad#subsection-specifying-corners) for information on how to specify corner sets.
//   For a step-by-step explanation of masking attachments, see the [Attachments Tutorial](Tutorial-Attachment-Edge-Profiling).
// Arguments:
//   corners = Corners to mask.  See [Specifying Corners](attachments.scad#subsection-specifying-corners).  Default: All corners.
//   except = Corners to explicitly NOT mask.  See [Specifying Corners](attachments.scad#subsection-specifying-corners).  Default: No corners.
//   ---
//   r = Radius of corner mask.
//   d = Diameter of corner mask.
//   axis = Can be set to "X", "Y", or "Z" to specify the axis that the corner mask will be rotated around.  Default: "Z"
//   convexity = Max number of times a line could intersect the perimeter of the mask shape.  Default: 10
// Side Effects:
//   Tags the children with "remove" (and hence sets `$tag`) if no tag is already set.
//   `$idx` is set to the index number of each corner.
//   `$attach_anchor` is set for each corner given, to the `[ANCHOR, POSITION, ORIENT, SPIN]` information for that anchor.
//   `$profile_type` is set to `"corner"`.
// Example:
//   diff()
//   cuboid([50,60,70],rounding=10,edges="Z",anchor=CENTER) {
//       corner_profile(TOP,r=10)
//           mask2d_teardrop(r=10, angle=40);
//   }
// Example: Rotate the mask around the X axis instead.
//   diff()
//   cuboid([50,60,70],rounding=10,edges="Z",anchor=CENTER) {
//       corner_profile(TOP,r=10,axis="X")
//           mask2d_teardrop(r=10, angle=40);
//   }
module corner_profile(corners=CORNERS_ALL, except=[], r, d, axis="Z", convexity=10) {
    check1 = assert($parent_geom != undef, "\nNo object to attach to!");
    r = max(0.01, get_radius(r=r, d=d, dflt=undef));
    check2 = assert(is_num(r), "\nBad r/d argument.");
    corners = _corners(corners, except=except);
    vecs = [for (i = [0:7]) if (corners[i]>0) CORNER_OFFSETS[i]];
    all_vecs_are_corners = all([for (vec = vecs) sum(v_abs(vec))==3]);
    check3 = assert(all_vecs_are_corners, "\nAll vectors must be corners.");
    module rot_to_axis(axis) {
        if (axis == "X")
            rot(120, v=[1,1,1]) children();
        else if (axis == "Y")
            rot(-120, v=[1,1,1]) children();
        else
            children();
    }
    module mirror_if(cond,plane) {
        if (cond) mirror(plane) children();
        else children();
    }
    module mirror_to_corner(corner) {
        mirror_if(corner.x > 0, RIGHT)
            mirror_if(corner.y > 0, BACK)
                mirror_if(corner.z > 0, UP)
                    children();
    }
    module corner_round_mask2d(r) {
        excess = 0.01;
        path = [
            [-excess,-excess],
            [-excess, r],
            each arc(cp=[r,r], r=r, start=180, angle=90),
            [r, -excess]
        ];
        polygon(path);
    }
    for ($idx = idx(vecs)) {
        vec = vecs[$idx];
        anch = _find_anchor(vec, $parent_geom);
        $attach_to = undef;
        $attach_anchor = anch;
        $profile_type = "corner";
        default_tag("remove") attachable() {
            translate(anch[1]) {
                mirror_to_corner(vec) {
                    rot_to_axis(axis) {
                        down(0.01) {
                            linear_extrude(height=r+0.01, center=false, convexity=convexity) {
                                corner_round_mask2d(r);
                            }
                        }
                        translate([r,r]) zrot(180) {
                            rotate_extrude(angle=90, convexity=convexity) {
                                right(r) xflip() {
                                    children();
                                }
                            }
                        }
                    }
                }
            }
            union();
        }
    }
}



// Section: 3D Edge Masks

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
// Example(3D, NoScales): Here we blend a tapered mask applied with `rounding_edge_mask()` with {{cuboid()}} rounding and a 2d mask applied with {{edge_profile()}}.
//    $fa=5;$fs=0.5;
//    diff()
//    cuboid(25,rounding=2,edges=[TOP+RIGHT,TOP+FRONT]){
//      attach(RIGHT+FRONT, LEFT+FWD, inside=true)
//         rounding_edge_mask(r1=5, r2=9, rounding2=2, rounding1=3);
//      edge_profile([BOT+RIGHT,BOT+FRONT]) mask2d_roundover(r=3);
//    }   


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
    steps = max(2,segs(max(r1,r2), 180-ang)); 
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




// Module: polygon_edge_mask()
// Synopsis: Extrudes a 2d mask polygon to an edge mask with a correct corner anchor
// SynTags: Geom
// Topics: Masks, Shapes (3D)
// See Also: edge_profile(), edge_profile_asym(), diff()
// Usage:
//   polygon_edge_mask(mask, l|h=|length=|height=, [scale=]) [ATTACHMENTS];
// Description:
//   Creates a 3d mask shape by extruding a polygon point list that specifies a 2d mask shape.  This is different than using {{edge_profile()}} because it
//   creates the actual 3D shape and does not require a parent object.  You can attach it to any corner with a suitable anchor. 
//   This is different from a simple {{linear_sweep()}}
//   because it creates a "corner" named anchor that is correctly located to attach the mask.  Note that since the
//   2d masks have excess to ensure clean differences, the "corner" anchor is not at the actual corner of the mask
//   object but at the corner point that needs to align with the corner being masked.  If you use {{linear_sweep()}}
//   you will need to adjust for the excess manually, because the FWD+LEFT anchor is at the actual corner of the geometry.
//   .
//   For correct definition of the "corner" anchor this module assumes that the bottom edge is parallel to the Y axis, the bottom and
//   left edges are at the same angle as the corner the mask applies to, and that the mask corner point aligns with the origin.
// Example(3D): Creating a roundover with a large excess
//   polygon_edge_mask(mask2d_roundover(r=5, excess=2), length=20);
// Example(3D): Scaled roundover (with the much smaller default excess)
//   polygon_edge_mask(mask2d_roundover(r=5), length=20, scale=2);
// Example(3D): Masking a prismoid edge with a scaled cove using attachment
//   diff()
//     prismoid([30,40],[60,30],h=44)
//       attach(RIGHT+FWD,"corner",inside=true)
//         polygon_edge_mask(mask2d_cove(h=6,inset=2,mask_angle=$edge_angle,excess=2), $edge_length+10, scale=1/4);
// Arguments:
//   mask = path describing the 2d mask
//   l / h / length / height = Length of mask.  Default: $edge_length if defined
//   ---
//   scale = Scaling multiplier for the top end of the mask object compared to the bottom.  Default: 1
//   atype = Anchor type, either "hull" or "intersect".  Default: "intersect"
// Anchor Types:
//   "hull" = Anchors to the virtual convex hull of the shape.
//   "intersect" = Anchors to the surface of the shape.
// Named Anchors:
//   "corner" = The center point of the mask with the correct direiction to anchor to an edge
// Side Effects:
//   Tags the children with "remove" (and hence sets `$tag`) if no tag is already set.
function polygon_edge_mask(mask, length, height, l, h, scale=1, anchor="origin", atype="hull", spin=0, orient=UP) = no_function("polygon_edge_mask");
module polygon_edge_mask(mask, length, height, l, h, scale=1, anchor="origin", atype="hull", spin=0, orient=UP)
{
  dummy = assert(is_path(mask), "mask must be a path")
          assert(in_list(atype, ["hull","intersect"]), "\nAnchor type must be \"hull\" or \"intersect\"");
  length = is_def($edge_length) && !any_defined([l,length,h,height]) ? $edge_length
         : one_defined([l,length,h,height],"l,length,h,height");
  bounds = pointlist_bounds(mask);
  bottompts = [for(i=idx(mask)) if (approx(mask[i].y,bounds[0].y)) [mask[i].x,i]];
  corner = bottompts[min_index(column(bottompts,0))][1];
  angle = vector_angle(select(mask,corner-1,corner+1));
  anchor_dir = -zrot(angle/2,RIGHT);
  anchors = [named_anchor("corner", CTR,anchor_dir, _compute_spin(anchor_dir, UP))];
  echo(anchors=anchors);
  default_tag("remove")
     attachable(anchor=anchor, spin=spin, orient=orient, h=length, scale=scale, path=mask, extent=atype=="hull", anchors=anchors){
       linear_sweep(mask,h=length,anchor="origin", scale=scale);
       children();
     }
}


// Section: 3D Masks for 90° Corners


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



// Section: 3D Cylinder End Masks


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


// Section: 3D Cylindrical Hole Masks


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


// Section: Modules for Applying 3D Masks


// Module: face_mask()
// Synopsis: Ataches a 3d mask shape to the given faces of the parent.
// SynTags: Trans
// Topics: Attachments, Masking
// See Also: attachable(), position(), attach(), edge_mask(), corner_mask(), face_profile(), edge_profile(), corner_profile()
// Usage:
//   PARENT() face_mask(faces) CHILDREN;
// Description:
//   Takes a 3D mask shape, and attaches it to the given faces, with the appropriate orientation to be
//   differenced away.  The mask shape should be vertically oriented (Z-aligned) with the bottom half
//   (Z-) shaped to be diffed away from the face of parent attachable shape.  If no tag is set then
//   `face_mask()` sets the tag for children to "remove" so that it works with the default {{diff()}} tag.
//   For details on specifying the faces to mask see [Specifying Faces](attachments.scad#subsection-specifying-faces).
//   For a step-by-step explanation of masking attachments, see the [Attachments Tutorial](Tutorial-Attachment-Edge-Profiling).
// Arguments:
//   edges = Faces to mask.  See  [Specifying Faces](attachments.scad#subsection-specifying-faces) for information on specifying faces.  Default: All faces
// Side Effects:
//   Tags the children with "remove" (and hence sets `$tag`) if no tag is already set.
//   `$idx` is set to the index number of each face in the list of faces given.
//   `$attach_anchor` is set for each face given, to the `[ANCHOR, POSITION, ORIENT, SPIN]` information for that anchor.
// Example:
//   diff()
//   cylinder(r=30, h=60)
//       face_mask(TOP) {
//           rounding_cylinder_mask(r=30,rounding=5);
//           cuboid([5,61,10]);
//       }
// Example: Using `$idx`
//   diff()
//   cylinder(r=30, h=60)
//       face_mask([TOP, BOT])
//           zrot(45*$idx) zrot_copies([0,90]) cuboid([5,61,10]);
module face_mask(faces=[LEFT,RIGHT,FRONT,BACK,BOT,TOP]) {
    req_children($children);
    faces = is_vector(faces)? [faces] : faces;
    assert(all([for (face=faces) is_vector(face) && sum([for (x=face) x!=0? 1 : 0])==1]), "\nVector in faces doesn't point at a face.");
    assert($parent_geom != undef, "\nNo object to attach to!");
    attach(faces) {
       default_tag("remove") children();
    }
}


// Module: edge_mask()
// Synopsis: Attaches a 3D mask shape to the given edges of the parent.
// SynTags: Trans
// Topics: Attachments, Masking
// See Also: attachable(), position(), attach(), face_mask(), corner_mask(), face_profile(), edge_profile(), corner_profile()
// Usage:
//   PARENT() edge_mask([edges], [except]) CHILDREN;
// Description:
//   Takes a 3D mask shape, and attaches it to the given edges of a cuboid parent, with the appropriate orientation to be
//   differenced away.  The mask shape should be vertically oriented (Z-aligned) with the back-right
//   quadrant (X+Y+) shaped to be diffed away from the edge of parent attachable shape.  If no tag is set
//   then `edge_mask` sets the tag for children to "remove" so that it works with the default {{diff()}} tag.
//   For details on specifying the edges to mask see [Specifying Edges](attachments.scad#subsection-specifying-edges).
//   For a step-by-step explanation of masking attachments, see the [Attachments Tutorial](Tutorial-Attachment-Edge-Profiling).
// Figure: A Typical Edge Rounding Mask
//   module roundit(l,r) difference() {
//       translate([-1,-1,-l/2])
//           cube([r+1,r+1,l]);
//       translate([r,r])
//           cylinder(h=l+1,r=r,center=true, $fn=quantup(segs(r),4));
//   }
//   roundit(l=30,r=10);
// Arguments:
//   edges = Edges to mask.  See [Specifying Edges](attachments.scad#subsection-specifying-edges).  Default: All edges.
//   except = Edges to explicitly NOT mask.  See [Specifying Edges](attachments.scad#subsection-specifying-edges).  Default: No edges.
// Side Effects:
//   Tags the children with "remove" (and hence sets `$tag`) if no tag is already set.
//   `$idx` is set to the index number of each edge.
//   `$attach_anchor` is set for each edge given, to the `[ANCHOR, POSITION, ORIENT, SPIN]` information for that anchor.
//   `$parent_size` is set to the size of the parent object.
// Example:
//   diff()
//   cube([50,60,70],center=true)
//       edge_mask([TOP,"Z"],except=[BACK,TOP+LEFT])
//           rounding_edge_mask(l=71,r=10);
module edge_mask(edges=EDGES_ALL, except=[]) {
    req_children($children);
    assert($parent_geom != undef, "\nNo object to attach to!");
    edges = _edges(edges, except=except);
    vecs = [
        for (i = [0:3], axis=[0:2])
        if (edges[axis][i]>0)
        EDGE_OFFSETS[axis][i]
    ];
    for ($idx = idx(vecs)) {
        vec = vecs[$idx];
        vcount = (vec.x?1:0) + (vec.y?1:0) + (vec.z?1:0);
        dummy=assert(vcount == 2, "\nNot an edge vector!");
        anch = _find_anchor(vec, $parent_geom);
        $edge_angle = len(anch)==5 ? struct_val(anch[4],"edge_angle") : undef;
        $edge_length = len(anch)==5 ? struct_val(anch[4],"edge_length") : undef;
        $attach_to = undef;
        $attach_anchor = anch;
        rotang =
            vec.z<0? [90,0,180+v_theta(vec)] :
            vec.z==0 && sign(vec.x)==sign(vec.y)? 135+v_theta(vec) :
            vec.z==0 && sign(vec.x)!=sign(vec.y)? [0,180,45+v_theta(vec)] :
            [-90,0,180+v_theta(vec)];
        translate(anch[1]) rot(rotang)
           default_tag("remove") children();
    }
}


// Module: corner_mask()
// Synopsis: Attaches a 3d mask shape to the given corners of the parent.
// SynTags: Trans
// Topics: Attachments, Masking
// See Also: attachable(), position(), attach(), face_mask(), edge_mask(), face_profile(), edge_profile(), corner_profile()
// Usage:
//   PARENT() corner_mask([corners], [except]) CHILDREN;
// Description:
//   Takes a 3D corner mask shape, and attaches it to the specified corners, with the appropriate orientation to
//   be differenced away.  The 3D corner mask shape should be designed to mask away the X+Y+Z+ octant.  If no tag is set
//   then `corner_mask` sets the tag for children to "remove" so that it works with the default {{diff()}} tag.
//   See [Specifying Corners](attachments.scad#subsection-specifying-corners) for information on how to specify corner sets.
//   For a step-by-step explanation of masking attachments, see the [Attachments Tutorial](Tutorial-Attachment-Edge-Profiling).
// Arguments:
//   corners = Corners to mask.  See [Specifying Corners](attachments.scad#subsection-specifying-corners).  Default: All corners.
//   except = Corners to explicitly NOT mask.  See [Specifying Corners](attachments.scad#subsection-specifying-corners).  Default: No corners.
// Side Effects:
//   Tags the children with "remove" (and hence sets `$tag`) if no tag is already set.
//   `$idx` is set to the index number of each corner.
//   `$attach_anchor` is set for each corner given, to the `[ANCHOR, POSITION, ORIENT, SPIN]` information for that anchor.
// Example:
//   diff()
//   cube(100, center=true)
//       corner_mask([TOP,FRONT],LEFT+FRONT+TOP)
//           difference() {
//               translate(-0.01*[1,1,1]) cube(20);
//               translate([20,20,20]) sphere(r=20);
//           }
module corner_mask(corners=CORNERS_ALL, except=[]) {
    req_children($children);
    assert($parent_geom != undef, "\nNo object to attach to!");
    corners = _corners(corners, except=except);
    vecs = [for (i = [0:7]) if (corners[i]>0) CORNER_OFFSETS[i]];
    for ($idx = idx(vecs)) {
        vec = vecs[$idx];
        vcount = (vec.x?1:0) + (vec.y?1:0) + (vec.z?1:0);
        dummy=assert(vcount == 3, "\nNot an edge vector!");
        anch = _find_anchor(vec, $parent_geom);
        $attach_to = undef;
        $attach_anchor = anch;
        rotang = vec.z<0?
            [  0,0,180+v_theta(vec)-45] :
            [180,0,-90+v_theta(vec)-45];
        translate(anch[1]) rot(rotang)
            default_tag("remove") children();
    }
}



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap






