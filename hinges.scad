//////////////////////////////////////////////////////////////////////
// LibFile: hinges.scad
//   Functions and modules for creating hinges and snap-locking hinged parts. 
// Includes:
//   include <BOSL2/std.scad>
//   include <BOSL2/hinges.scad>
// FileGroup: Parts
// FileSummary: Hinges and snap-locking hinged parts.  
//////////////////////////////////////////////////////////////////////

include <rounding.scad>
include <screws.scad>

// Section: Hinges

// Module: knuckle_hinge()
// Synopsis: Creates a knuckle-hinge shape.
// SynTags: Geom
// Topics: Hinges, Parts
// See Also: living_hinge_mask(), snap_lock(), snap_socket()
// Usage:
//   knuckle_hinge(length, offset, segs, [inner], [arm_height=], [arm_angle=], [fill=], [clear_top=], [gap=], [round_top=], [round_bot=], [knuckle_diam=], [pin_diam=], [pin_fn=], [anchor=], [spin=], [orient=]) [ATTACHMENTS];
// Description:
//   Construct standard knuckle hinge in two parts using a hinge pin that must be separately supplied,
//   or a print-in-place knuckle hinge.  The default is configured to use a piece of 1.75 mm filament
//   as the hinge pin, but you can select any dimensions you like to use a screw or other available pin material.
//   The hinge appears with what is typically the mounting surface restong on the XY plane with the hinge rotational axis
//   parallel to the X axis.  The BOTTOM
//   of the hinge is its mount point, which, if clearance is not set, is in line with the hinge pin rotational center.
//   In this case the hinge pin hole is the CENTER of the hinge. 
//   The offset is the distance the base (the mounting point) to the center
//   of the hinge pin.  The offset cannot be smaller than the knuckle diameter.
//   The hinge barrel is held by an angled support and vertical support.  The
//   length of the angled support is determined by its angle and the offset.  You specify the length
//   of the vertical support with the arm_height parameter.
//   .
//   A hinge requires clearance so its parts don't interfere.  If the hinge pin is exactly centered on
//   the top of your part, then the hinge may not close all the way due to interference at the edge.
//   A small clearance, specified with `clearance=`, move the hinge in the Y direction (which would be UP if
//   it were mounted on the side of a cube).  This shifts the rotation slightly and can ease the interference. 
//   It should probably be equal to a layer thickness or two.  Note that clearance moves the rotational center
//   but the CENTER, BOTTOM and TOP anchors stay fixed, so if you give a nonzero clearance, the center of rotation
//   will be offset by the clearance from the center anchor.  
//   .
//   If the hinge knuckle is
//   close to the hinged part then the mating part may interfere.  You can create clearance to address
//   this problem by increasing the offset to move the hinge knuckles farther away.  Another method is
//   to cut out a curved recess on the parts to allow space for the other hinges.  This is possible
//   using the `knuckle_clearance=` parameter, which specifies the extra space to cut away to leave
//   room for the hinge knuckles.  It must be positive for any space to be cut, and to use this option
//   you must make the hinge a child of some object and specify {{diff()}} for the parent object of
//   the hinge.
//   .
//   To create a print-in-place hinge set `in_place=true` to create a hinge with interlocking cones
//   instead of leaving a hole for an inserted pin.  In this case, `pin_diam` gives the diameter of
//   the base of the cones and defaults to 1 less than the knuckle diameter.  You can also set `in_place`
//   to a cone angle.  This is the angle of the bottom edge of the cone, measured from the vertical---the overhang
//   angle for printing.  A larger angle produces a pointier cone that is more difficult to print and has
//   a smaller clearance gap inside.  
// Figure(2D,Med,NoScales):  The basic hinge form appears on the left.  If fill is set to true the gap between the mount surface and hinge arm is filled as shown on the right. 
//   _knuckle_hinge_profile(4, 5, $fn=32, fill=false);
//   right(13)_knuckle_hinge_profile(4, 5, $fn=32, fill=true);
//   fwd(9)stroke([[0,0],[4,4],[4,9]], width=.3,color="black");
//   stroke([[5,-5],[5,0]], endcaps="arrow2", color="blue",width=.15);
//   color("blue"){move([6.2,-2.5])text("arm_height",size=.75,valign="center");
//      stroke(arc(r=3, cp=[0,-9], angle=[47,90],$fn=64),width=.15,endcaps="arrow2");
//      move([-.5,-6])text("arm_angle", size=0.75,halign="right");
//      move([14,-4])text("fill=true", size=1);
//   }
// Continues:
//   As shown in the above figure, the fill option fills the gap between the hinge arm and the mount surface to make a stronger connection.  When the
//   arm height is set to zero, only a single segment connects the hinge barrel to the mount surface.  
// Figure(2D,Med,NoScales): Zero arm height with 45 deg arm
//   right(10)   _knuckle_hinge_profile(4, 0, $fn=32);
//   _knuckle_hinge_profile(4, 0, $fn=32,fill=false);
//   right(11)fwd(-3)color("blue")text("fill=true",size=1);
//   right(.5)fwd(-3)color("blue")text("fill=false",size=1);
// Continues:
// Figure(2D,Med,NoScales): Zero arm height with 90 deg arm.  The clear_top parameter removes the hinge support material that is above the x axis
//   _knuckle_hinge_profile(4, 0, 90, $fn=32);
//   right(10)  _knuckle_hinge_profile(4, 0, 90, $fn=32,clear_top=true);
//   right(9.5)fwd(-3)color("blue")text("clear_top=true",size=.76);
//   right(.5)fwd(-3)color("blue")text("clear_top=false",size=.76);
// Figure(2D,Med,NoScales):  An excessively large clearance value raises up the hinge center.  Note that the hinge mounting remains bounded by the X axis, so when `fill=true` or `clear_top=true` this is different than simply raising up the entire hinge.  
//   right(10)  _knuckle_hinge_profile(4, 0, 90, $fn=32,clear_top=true,clearance=.5);
//   _knuckle_hinge_profile(4, 0, $fn=32,fill=true,clearance=.5);
// Continues:
//   For 3D printability, you may prefer a teardrop shaped hole, which you can get with `teardrop=true`; 
//   if necessary you can specify the teardrop direction to be UP, DOWN, FORWARD, or BACK.
//   (These directions assume that the base of the hinge is mounted on the back of something.)
//   Another option for printability is to use an octagonal hole, though it does seem more
//   difficult to size these for robust printability.  To get an octagonal hole set `pin_fn=8`.
// Figure(2D,Med,NoScales): Alternate hole shapes for improved 3D printabililty
//   right(10)   _knuckle_hinge_profile(4, 0, $fn=32,pin_fn=8);
//   _knuckle_hinge_profile(4, 0, $fn=32,tearspin=0);
//   right(11)fwd(-3)color("blue")text("octagonal",size=1);
//   right(1.5)fwd(-3)color("blue")text("teardrop",size=1);
// Continues:
//   The default pin hole size admits a piece of 1.75 mm filament.  If you prefer to use a machine
//   screw you can set the pin_diam to a screw specification like `"M3"` or "#6".  In this case,
//   a clearance hole is created through most of the hinge with a self-tap hole for the last segment.
//   If the last segment is very long you may shrink the self-tap portion using the tap_depth parameter.
//   The pin hole diameter is enlarged by the `2*$slop` for numerically specified holes.
//   Screw holes are made using {{screw_hole()}} which enlarges the hole by `4*$slop`.
//   .
//   Instead of a hinge pin you can set `in_place=true` to produce a print-in-place hinge that uses
//   cones to interlock the hinge segments.  The default cones are 45 degrees; you can set `in_place` to an
//   angle from the vertical to adjust the cone angle.  (This means larger angles are pointier, and also less likely to print successfully.)
//   Use `gap` to adjust the clearance in the hinge
//   to get something that separates after printing.  When you adjust the cone hangle, higher angles result in a smaller
//   clearance where the cones meet for the same gap size, so you can somewhat adjust the tightness of the hinge
//   by changing the cone angle.  The default cone diameter, which is controlled by `pin_diam` is 1 unit smaller than the knuckle diameter, which should work well
//   for larger hinges, but for small hinges you may want to specify a larger `pin_diam`.  
// Figure(3D,Small,NoScales): A print-in-place hinge with part of the hinge cut away so you can see the interlocking cones that hold it together:  
//   difference()
//   {
//      union(){
//        knuckle_hinge(length=35, segs=9, offset=3.1, in_place=true,$fn=32);
//        zrot(180)knuckle_hinge(length=35, inner=true, segs=9, offset=3.1, in_place=true,$fn=32);
//      }
//      up(3)cuboid(100, anchor=LEFT+BOT);
//   }
// Continues:
//   To blend hinges better with a model you can round off the joint with the mounting surface using
//   the `round_top` and `round_bot` parameters, which specify the cut distance, the amount of material to add.
//   They make a continuous curvature "smooth" roundover with `k=0.8`.  See [smooth roundovers](rounding.scad#section-types-of-roundovers) for more
//   information.  If you specify too large of a roundover you will get an error that the rounding doesn't fit.  
// Figure(2D,Med,NoScales): Top and bottom roundovers for smooth hinge attachment
//   right(12)_knuckle_hinge_profile(6, 0, $fn=32,fill=false,round_top=1.5);
//   _knuckle_hinge_profile(4, 0, $fn=32,fill=false,round_bot=1.5);
//   right(12)fwd(11)color("blue")text("round_top=1.8",size=1);
//   right(.5)fwd(-3)color("blue")text("round_bot=1.5",size=1);
// Arguments:
//   length = total length of the entire hinge
//   segs = number of hinge segments
//   offset = horizontal offset of the hinge pin center from the mount point
//   inner = set to true for the "inner" hinge.  Default: false
//   ---
//   arm_height = vertical height of the arm that holds the hinge barrel.  Default: 0
//   arm_angle = angle of the arm down from the vertical.  Default: 45
//   fill = if true fill in space between arm and mount surface.  Default: true
//   clear_top = if true remove any excess arm geometry that appears above the top of the mount surface.  Default: false
//   gap = gap between hinge segments.  Default: 0.2
//   round_top = rounding amount to add where top of hinge arm joins the mount surface.  Generally only useful when fill=false.  Default: 0
//   round_bot = rounding amount to add where bottom of hinge arm joins the mount surface.  Default: 0
//   knuckle_diam = diameter of hinge barrel.  Default: 4
//   pin_diam = for regular hinges, diameter of hinge pin hole as a numerical dimension or as a screw specification.  For print-in-place hinges, the diameter of the base of the interlocking cones inside the hinge.  Default: 1.75 for regular hinges, 1 less than knuckle_diameter for print-in-place hinges. 
//   pin_fn = $fn value to use for the pin.
//   teardrop = Set to true or UP/DOWN/FWD/BACK to specify teardrop shape for the pin hole.  Default: false
//   screw_head = screw head to use for countersink
//   screw_tolerance = screw hole tolerance.  Default: "close"
//   tap_depth = Don't make the tapped part of the screw hole larger than this.
//   in_place = If true create a print-in-place hinge with 45 deg angle interlocking cones.  If set to an angle, measures the angle from the vertical to the lower cone angle.  Default: false
//   $slop = increases pin hole diameter
//   clearance = raises pin hole to create clearance at the edge of the mounted surface.  Default: 0.15
//   knuckle_clearance = clear space to create specified clearance for hinge knuckle of mating part.  Must use with {{diff()}}.  Default: 0 
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `BOTTOM`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Example: Basic hinge, inner=false in front and inner=true in the back
//   $fn=32;
//   ydistribute(30){
//     knuckle_hinge(length=35, segs=5, offset=3, arm_height=1);
//     knuckle_hinge(length=35, segs=5, offset=3, arm_height=1,inner=true);
//   }
// Example(NoScales):  Basic hinge, mounted.  Odd segment count means the "outside" hinge is on the outside at both ends.  
//   $fn=32;
//   cuboid([2,40,15])
//     position(TOP+RIGHT) orient(anchor=RIGHT)
//       knuckle_hinge(length=35, segs=9, offset=3, arm_height=1);
// Example(NoScales):  Corresponding inner hinge to go with previous example.  Note that the total number of hinge segments adds to the 9 specified.  
//   $fn=32;
//   cuboid([2,40,15])
//     position(TOP+RIGHT) orient(anchor=RIGHT)
//       knuckle_hinge(length=35, segs=9, offset=3, arm_height=1, inner=true);
// Example(NoScales):  This example shows how to position and orient the hinge onto the front of an object instead of the right side. 
//   $fn=32;
//   cuboid([40,2,15])
//     position(TOP+FRONT) orient(anchor=FWD)
//       knuckle_hinge(length=35, segs=9, offset=3, arm_height=1);
// Example(NoScales):  Hinge with round_bot set to create a smooth transition, but octagonal hinge pin holes for printing
//   $fn=32;
//   cuboid([2,40,15])
//     position(TOP+RIGHT) orient(anchor=RIGHT)
//       knuckle_hinge(length=35, segs=9, offset=3, arm_height=1,
//             round_bot=1, pin_fn=8);
// Example(NoScales):  Hinge with no vertical arm, just angled arm
//   $fn=32;
//   cuboid([2,40,15])
//     position(TOP+RIGHT) orient(anchor=RIGHT)
//       knuckle_hinge(length=35, segs=9, offset=3, pin_fn=8);
// Example(NoScales): Setting the arm_angle to a large value like 90 produces a hinge that doesn't look great
//   $fn=32;
//   cuboid([2,40,15])
//     position(TOP+RIGHT) orient(anchor=RIGHT)
//       knuckle_hinge(length=35, segs=9, offset=3, arm_angle=90,
//             arm_height=0, pin_fn=8);
// Example(NoScales): The above hinge is improved with clear_top, which allows nice attachment to a shape half the thickness of the hinge barrel
//   $fn=32;
//   cuboid([20,40,2])
//     position(TOP+RIGHT) orient(anchor=RIGHT)
//       knuckle_hinge(length=35, segs=9, offset=3, arm_height=0,
//             arm_angle=90, pin_fn=8, clear_top=true);
// Example(NoScales): Uneven hinge using seg_ratio.  Here the inner hinge segments are 1/3 the outer, a rather extreme difference.  Note also that it's a little simpler to mount the inner hinge on the LEFT side of the top section to interface with the hinge mounted on the RIGHT. 
//   $fn=32;
//   cuboid([2,40,15]){
//     position(TOP+RIGHT) orient(anchor=RIGHT)
//       knuckle_hinge(length=35, segs=9, offset=3, arm_height=1,
//             seg_ratio=1/3);
//     attach(TOP,TOP) color("green")
//       cuboid([2,40,15],anchor=TOP)
//         position(TOP+LEFT) orient(anchor=LEFT)
//           knuckle_hinge(length=35, segs=9, offset=3, arm_height=1,
//                 seg_ratio=1/3, inner=true);
//    }
// Example(NoScales): A single hinge with an even number of segments will probably look strange, but they work together neatly in a pair.  This example also shows that the arm_height can change between the inner and outer hinge parts and they will still interface properly.
//   $fn=32;
//   cuboid([2,40,15]){
//     yflip_copy()
//       position(TOP+RIGHT+FRONT) orient(anchor=RIGHT)
//         knuckle_hinge(length=12, segs=2, offset=2, arm_height=2,
//               anchor=BOT+LEFT);
//     attach(TOP,TOP) color("green")
//       cuboid([2,40,15],anchor=TOP)
//         yflip_copy()
//           position(TOP+LEFT+FRONT) orient(anchor=LEFT)
//             knuckle_hinge(length=12, segs=2, offset=2, arm_height=0,
//                   inner=true, anchor=BOT+RIGHT);
//    }
// Example(NoScales): Hinge with self-tapping screw hole.  Note that last segment has smaller diameter for screw to bite, whereas other segments have clearance holes. 
//   $fn=32;
//   bottom_half(z=.01)
//     cuboid([2,40,15],anchor=TOP)
//       position(TOP+RIGHT) orient(anchor=RIGHT)
//         knuckle_hinge(length=35, segs=5, offset=5, knuckle_diam=9, pin_diam="#6", fill=false,inner=false, screw_head="flat");
// Example(NoScales): If you give a non-flat screw head then a counterbore for that head is generated.  If you don't want the counterbore, don't give a head type.  In this example, tap_depth limits the narrower self-tap section of the hole.  
//   $fn=32;
//   bottom_half(z=.01)
//      cuboid([2,40,15],anchor=TOP)
//        position(TOP+RIGHT) orient(anchor=RIGHT)
//           knuckle_hinge(length=35, segs=3, offset=5, knuckle_diam=9, pin_diam="#6",
//                 fill=false, inner=false, tap_depth=6, screw_head="socket");
// Example(NoScales): This hinge has a small offset, so the hinged parts may interfere.  To prevent this, use `knuckle_clearance`.  This example shows an excessive clearance value to make the effect obvious.  Note that you **must** use {{diff()}} when you set `knuckle_clearance`, and the hinge must be a child of the object it mounts to.  Otherwise the cylinders that are supposed to be subtracted will appear as extra objects.  This is an inner hinge, so it has clearance zones for the larger outer hinge that will mate with it.  
//   $fn=32;
//   diff()
//     cuboid([4,40,15])
//       position(TOP+RIGHT) orient(anchor=RIGHT)
//         knuckle_hinge(length=35, segs=5, offset=2, inner=true, knuckle_clearance=1);
// Example(NoScales): Oh no! Forgot to use {{diff()}} with knuckle_clearance!
//   $fn=32;
//     cuboid([4,40,15])
//       position(TOP+RIGHT) orient(anchor=RIGHT)
//         knuckle_hinge(length=35, segs=5, offset=2, inner=true, knuckle_clearance=1);
// Example(3D,NoScales,VPR=[57.80,0.00,308.00],VPD=54.24,VPT=[2.34,0.76,0.15]): If you want the hinge leaves to fold flat together, pick a hinge configuration that places the centerline of the hinge pin on the plane of the hinge leaf.  Hinges that fold entirely flat probably won't work, so we add some clearance between the leaves.
//    $fn=32;
//    thickness=2;
//    clearance=0.2;
//    zrot_copies([0,180])
//      color(["green","gold"][$idx])
//      diff()
//        fwd(clearance/2)
//          cuboid([20,thickness,7],anchor=BACK)
//            down(thickness/3)
//            position(TOP+BACK)
//              knuckle_hinge(20, segs=5, offset=thickness+clearance,
//                            inner=$idx==0, knuckle_clearance=clearance,
//                            clearance=clearance/2, arm_angle=90, 
//                            knuckle_diam=2*thickness+clearance,
//                            clear_top=true);
// Example(3D,NoScales,VPR=[55.00,0.00,25.00],VPD=82.67,VPT=[9.42,-0.23,1.39]): Here's a print-in-place hinge positioned for printing.  The next three examples show some different ways to position a hinge like this.  In this case, we create the hinge leaf, put the hinge on it, put the second hinge leaf next to it, and put the hinge on that.  It would be hard to rotate this hinge.  This hinge works with a 0.2mm layer height on a Prusa MK3S.  
//   $fn=64;
//   leaf_gap = 0.4;
//   seg_gap = 0.2;
//   module myhinge(inner)
//      knuckle_hinge(length=25, segs=7, offset=3.1, inner=inner, in_place=true,
//                    clearance=leaf_gap/2, round_bot=0.5, gap=seg_gap, seg_ratio=1/3);
//   cuboid([20,25,2],rounding=7,edges=[LEFT+FWD,LEFT+BACK]){
//     position(TOP+RIGHT) orient(UP,-90) 
//       myhinge(false);
//     align(RIGHT) right(leaf_gap) cuboid([20,25,2],rounding=7,edges=[RIGHT+FWD,RIGHT+BACK])
//       position(TOP+LEFT) orient(UP,90) 
//         myhinge(true);
//   }
// Example(3D,VPR=[66.20,0.00,66.30],VPD=60.27,VPT=[0.01,-0.19,-0.36],NoAxes): A very small print-in-place hinge with a 2mm hinge barrel that printed successfully on a Prusa MK3S with 0.15 mm layer height.  The 0.15 clearance places the rotation axis above the hinge leaves which enables the hinge to close all the way.  This construction makes the hinge leaf a child of the hinge, which enables easy rotation of hinge leaf and anything connected to it.  We do have to adjust the rotation center for the clearance.  This construction also makes the leaves symmetrically so they can be made with identical code, instead of needing to round opposite ends.  
//   $fn = 64;
//   diam = 2;       // Hinge knuckle diameter
//   seg_gap = 0.15; // Gap between hinge segments
//   clear = 0.15;   // Clearance so hinge will close all the way
//   ang=0;          // Hinge rotation angle
//   module myhinge(inner)
//      knuckle_hinge(length=25, segs=11,offset=1.2, inner=inner, clearance=clear, knuckle_diam=diam,
//                    pin_diam=diam-0.2, arm_angle=28, gap=seg_gap, in_place=true, anchor=CTR,clip=2+clear)
//         children();
//   module leaf() cuboid([25,2,12],anchor=TOP+BACK,rounding=7,edges=[BOT+LEFT,BOT+RIGHT]);
//   xrot(90){    // Rotate to printing orientation
//     myhinge(true) position(BOT) leaf();
//     color("lightblue")
//       xrot(180-ang,cp=[0,clear,0])
//       zrot(180,cp=[0,clear,0]) 
//       myhinge(false) position(BOT) leaf();
//   }
// Example(3D,NoAxes,VPR=[72.50,0.00,117.40],VPD=113.40,VPT=[5.64,1.70,6.16]): Here is a print-in-place hinge where the hinge barrel matches the thickness of the leaves.  In this hinge we show another way to mate the parts where we {{attach()}} one hinge section to the other and the leaves are children of the hinges.  This hinge printed successfully (with ang=0) on a Prusa MK3S with a 0.2mm layer thickness.  This hinge is shown folded at an angle; for printing, set `ang=0`.  
//   $fn=64;
//   thickness=4;
//   seg_gap = 0.2;
//   end_space = 0.6;
//   ang=35;
//   module myhinge(inner)
//      knuckle_hinge(length=25, segs=13,offset=thickness/2+end_space, inner=inner, clearance=-thickness/2, knuckle_diam=thickness,
//                    arm_angle=45, gap=seg_gap, in_place=true, clip=thickness/2)
//                    children();
//   module leaf() cuboid([25,thickness,25],anchor=TOP+BACK, rounding=7, edges=[BOT+LEFT,BOT+RIGHT]);
//   xrot(90)
//     myhinge(true){
//       position(BOT) leaf();
//       color("lightblue")
//         up(end_space) attach(BOT,TOP,inside=true)
//         tag("")  // cancel default "remove" tag
//         xrot(-ang,cp=[0,-thickness/2,thickness/2]) myhinge(false)
//           position(BOT) leaf();
//     }

function knuckle_hinge(length, segs, offset, inner=false, arm_height=0, arm_angle=45, gap=0.2,
             seg_ratio=1, knuckle_diam=4, pin_diam=1.75, fill=true, clear_top=false,
             round_bot=0, round_top=0, pin_fn, clearance, in_place=false, clip, 
             tap_depth, screw_head, screw_tolerance="close", 
             anchor=BOT,orient,spin) = no_function("hinge");

module knuckle_hinge(length, segs, offset, inner=false, arm_height=0, arm_angle=45, gap=0.2,
             seg_ratio=1, knuckle_diam=4, pin_diam, fill=true, clear_top=false,
             round_bot=0, round_top=0, pin_fn, clearance=0, teardrop, in_place=false, clip, 
             tap_depth, screw_head, screw_tolerance="close", knuckle_clearance, 
             anchor=BOT,orient,spin)
{
  pin_diam = default(pin_diam, in_place==false ? 1.75 : knuckle_diam-1);
  dummy =
    assert(is_str(pin_diam) || all_positive([pin_diam]), "pin_diam must be a screw spec string or a positive number")
    assert(all_positive(length), "length must be a postive number")
    assert(is_int(segs) && segs>=2, "segs must be an integer 2 or greater")
    assert(is_finite(offset) && offset>=knuckle_diam/2, "offset must be a valid number that is not smaller than radius of the hinge knuckle")
    assert(is_finite(arm_angle) && arm_angle>0 && arm_angle<=90, "arm_angle must be greater than zero and less than or equal to 90");
  segs1 = ceil(segs/2);
  segs2 = floor(segs/2);
  seglen1 = gap + (length-(segs-1)*gap) / (segs1 + segs2*seg_ratio);
  seglen2 = gap + (length-(segs-1)*gap) / (segs1 + segs2*seg_ratio) * seg_ratio;
  numsegs = inner?segs2:segs1;
  z_adjust = segs%2==1 ? 0
           : inner? seglen1/2
           : seglen2/2;
  tearspin = is_undef(teardrop) || teardrop==false ? undef
           : teardrop==UP || teardrop==true ? 0
           : teardrop==DOWN ? 180
           : teardrop==BACK ? 270
           : teardrop==FWD ? 90
           : assert(false, "Illegal value for teardrop");
  knuckle_segs = segs(knuckle_diam);
  transform = down(offset)*yrot(-90)*zmove(z_adjust);

  if(knuckle_clearance){
    knuckle_clearance_diam = knuckle_diam / cos(180/knuckle_segs) + 2*knuckle_clearance;
    tag("remove")
      attachable(anchor,spin,orient,
                 size=[length,
                       arm_height+offset/tan(arm_angle)+knuckle_diam/2+knuckle_diam/2/sin(arm_angle),
                       offset+knuckle_diam/2],
                 offset=[0,
                         -arm_height/2-offset/tan(arm_angle)/2-knuckle_diam/sin(arm_angle)/4+knuckle_diam/4,
                         -offset/2+knuckle_diam/4]
      )
      {
        multmatrix(transform) down(segs%2==1? 0 : (seglen1+seglen2)/2){
          move([offset,clearance])
            intersection(){
              n = inner && segs%2==1 ? segs1
                
                : inner ? segs1
                : segs2;
              zcopies(n=n, spacing=seglen1+seglen2)
                 cyl(h=(inner?seglen1:seglen2)+gap-.01, d=knuckle_clearance_diam, circum=true, $fn=knuckle_segs, realign=true);
              //cyl(h=length+2*gap, d=knuckle_clearance_diam, circum=true, $fn=knuckle_segs, realign=true);
            }
        }
        union(){}
    }
  }
  attachable(anchor,spin,orient,
             size=[length,
                   arm_height+offset/tan(arm_angle)+knuckle_diam/2+knuckle_diam/2/sin(arm_angle),
                   offset+knuckle_diam/2],
             offset=[0,
                     -arm_height/2-offset/tan(arm_angle)/2-knuckle_diam/sin(arm_angle)/4+knuckle_diam/4,
                     -offset/2+knuckle_diam/4]
  )
  {
    multmatrix(transform)
      force_tag() difference() {
        zcopies(n=numsegs, spacing=seglen1+seglen2){
          linear_extrude((inner?seglen2:seglen1)-gap,center=true,convexity=4)
            _knuckle_hinge_profile(offset=offset, arm_height=arm_height, arm_angle=arm_angle, knuckle_diam=knuckle_diam, pin_diam=pin_diam,clip=clip,
                                   fill=fill, clear_top=clear_top, round_bot=round_bot, round_top=round_top, pin_fn=pin_fn,clearance=clearance,tearspin=tearspin);

          if (in_place!=false){
            angle = is_bool(in_place) ? 45 : in_place;
            doflip = inner?yflip():IDENT;
            len = (inner?seglen2:seglen1)-gap;
            cone_h = pin_diam/2*tan(angle);
            tag("keep")back(clearance)right(offset)
              rotate_extrude() polygon(apply(doflip,[
                                         [0,-len/2 + ((!inner && segs%2==1 && $idx==0) || ($idx==numsegs-1 && inner && segs%2==0) ? 0:cone_h)],
                                         [pin_diam/2, -len/2],
                                         [pin_diam/2+.01, -len/2],
                                         [pin_diam/2+.01, len/2],                                                                                                          
                                         [pin_diam/2, len/2],
                                         if ($idx==numsegs-1 && !inner) [0,len/2]
                                         else each [
                                           [pin_diam*.1, len/2+cone_h*.8],
                                           [0,len/2+cone_h*.8]
                                         ]
                                       ]));
          }
        }
        if (!in_place && is_str(pin_diam)) back(clearance)right(offset) up(length/2-(inner?1:1)*z_adjust) zrot(default(tearspin,0)){
          $fn = default(pin_fn,$fn);
          tap_depth = min(segs%2==1?seglen1-gap/2:seglen2-gap/2, default(tap_depth, length));
          screw_hole(pin_diam, length=length+.01, tolerance="self tap", bevel=false, anchor=TOP, teardrop=is_def(tearspin));
          multmatrix(inner ? zflip(z=-length/2) : IDENT)
            if (is_undef(screw_head) || screw_head=="none" || starts_with(screw_head,"flat"))
              screw_hole(pin_diam, length=length-tap_depth, tolerance=screw_tolerance, bevel=false, anchor=TOP, head=screw_head, teardrop=is_def(tearspin));
            else {
              screw_hole(pin_diam, length=length-tap_depth, tolerance=screw_tolerance, bevel=false, anchor=TOP, teardrop=is_def(tearspin));
              screw_hole(pin_diam, length=.01, tolerance=screw_tolerance, bevel=false, anchor=TOP, head=screw_head, teardrop=is_def(tearspin));
            }
        }
      }
    children();
  }    
}  


module _knuckle_hinge_profile(offset, arm_height, arm_angle=45, knuckle_diam=4, pin_diam=1.75, fill=true, clear_top=false, 
                              round_bot=0, round_top=0, pin_fn, clearance=0, tearspin, clip)
{
  extra = .01;
  skel = turtle(["left", 90-arm_angle, "untilx", offset+extra, "left", arm_angle,
                 if (arm_height>0) each ["move", arm_height]]);
  ofs = arm_height+offset/tan(arm_angle);
  start=round_bot==0 && round_top==0 ? os_flat(abs_angle=90)
                                     : os_round(abs_angle=90, cut=[-round_top,-round_bot],k=.8);
  back(clearance)
  difference(){
    union(){
      difference(){
        fwd(ofs){
          left(extra)offset_stroke(skel, width=knuckle_diam, start=start);
          if (fill) polygon([each list_head(skel,-2), fwd(clearance,last(skel)), [-extra,ofs-clearance]]);
        }
        if (clear_top==true || clear_top=="all") left(.1)fwd(clearance) rect([offset+knuckle_diam,knuckle_diam+1+clearance],anchor=BOT+LEFT);
        if (is_num(clear_top)) left(.1)fwd(clearance) rect([.1+clear_top, knuckle_diam+1+clearance], anchor=BOT+LEFT);
        if (is_def(clip)) fwd(clip) left(.1) rect([offset+knuckle_diam, ofs+round_bot+knuckle_diam+abs(clip)],anchor=BACK+LEFT);
      }
      right(offset)ellipse(d=knuckle_diam,realign=true,circum=true);
    }
    if (is_num(pin_diam) && pin_diam>0){
      $fn = default(pin_fn,$fn);
      right(offset)
        if (is_def(tearspin)){
          teardrop2d(d=pin_diam+2*get_slop(), realign=true, circum=true, spin=tearspin);
        }
        else ellipse(d=pin_diam+2*get_slop(), realign=true, circum=true);
    }
  }
} 


// Module: living_hinge_mask()
// Synopsis: Creates a mask to make a folding "living" hinge.
// SynTags: Geom
// Topics: Hinges, Parts
// See Also: knuckle_hinge(), living_hinge_mask(), snap_lock(), snap_socket(), apply_folding_hinges_and_snaps()
// Usage:
//   living_hinge_mask(l, thick, [layerheight=], [foldangle=], [hingegap=], [$slop=], [anchor=], [spin=], [orient=]) [ATTACHMENTS];
// Description:
//   Creates a mask to be differenced away from a plate to create a "live" hinge, where a thin layer of plastic holds two parts together.  
//   Center the mask at the bottom of the part you want to make a hinge in.
//   The mask will leave  hinge material `2*layerheight` thick on the bottom of the hinge.
// Arguments:
//   l = Length of the hinge in mm.
//   thick = Thickness in mm of the material to make the hinge in.
//   ---
//   layerheight = The expected printing layer height in mm.
//   foldangle = The interior angle in degrees of the joint to be created with the hinge.  Default: 90
//   hingegap = Size in mm of the gap at the bottom of the hinge, to make room for folding.
//   $slop = Increase size of hinge gap by double this amount
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Example:
//   living_hinge_mask(l=100, thick=3, foldangle=60);
module living_hinge_mask(l, thick, layerheight=0.2, foldangle=90, hingegap=undef, anchor=CENTER, spin=0, orient=UP)
{
    hingegap = default(hingegap, layerheight)+2*get_slop();
    size = [l, hingegap, 2*thick];
    size2 = [l, hingegap+2*thick*tan(foldangle/2)];
    attachable(anchor,spin,orient, size=size, size2=size2) {
        up(layerheight*2) prismoid([l,hingegap], [l, hingegap+2*thick/tan(foldangle/2)], h=thick, anchor=BOT);
        children();
    }
}

module folding_hinge_mask(l, thick, layerheight=0.2, foldangle=90, hingegap=undef, anchor=CENTER, spin=0, orient=UP)
{
    deprecate("living_hinge_mask");
    living_hinge_mask(l, thick, layerheight, foldangle, hingegap, anchor, spin, orient);
}



// Section: Snap Locks


// Module: apply_folding_hinges_and_snaps()
// Synopsis: Adds snap shapes and removes living hinges from a child shape.
// SynTags: Geom
// Topics: Hinges, Parts
// See Also: knuckle_hinge(), living_hinge_mask(), snap_lock(), snap_socket()
// Usage:
//   apply_folding_hinges_and_snaps(thick, [foldangle=], [hinges=], [snaps=], [sockets=], [snaplen=], [snapdiam=], [hingegap=], [layerheight=], [$slop=]) CHILDREN;
// Description:
//   Adds snaplocks and create hinges in children at the given positions.
// Arguments:
//   thick = Thickness in mm of the material to make the hinge in.
//   foldangle = The interior angle in degrees of the joint to be created with the hinge.  Default: 90
//   hinges = List of [LENGTH, POSITION, SPIN] for each hinge to difference from the children.
//   snaps = List of [POSITION, SPIN] for each central snaplock to add to the children.
//   sockets = List of [POSITION, SPIN] for each outer snaplock sockets to add to the children.
//   snaplen = Length of locking snaps.
//   snapdiam = Diameter/width of locking snaps.
//   hingegap = Size in mm of the gap at the bottom of the hinge, to make room for folding.
//   layerheight = The expected printing layer height in mm.
//   ---
//   $slop = increase hinge gap by twice this amount
// Example(Med):
//   size=100;
//   apply_folding_hinges_and_snaps(
//       thick=3, foldangle=acos(1/3),
//       hinges=[
//           for (a=[0,120,240], b=[-size/2,size/4]) each [
//               [200, polar_to_xy(b,a), a+90]
//           ]
//       ],
//       snaps=[
//           for (a=[0,120,240]) each [
//               [rot(a,p=[ size/4, 0        ]), a+90],
//               [rot(a,p=[-size/2,-size/2.33]), a-90]
//           ]
//       ],
//       sockets=[
//           for (a=[0,120,240]) each [
//               [rot(a,p=[ size/4, 0        ]), a+90],
//               [rot(a,p=[-size/2, size/2.33]), a+90]
//           ]
//       ]
//   ) {
//       $fn=3;
//       difference() {
//           cylinder(r=size-1, h=3);
//           down(0.01) cylinder(r=size/4.5, h=3.1, spin=180);
//           down(0.01) for (a=[0:120:359.9]) zrot(a) right(size/2) cylinder(r=size/4.5, h=3.1);
//       }
//   }
module apply_folding_hinges_and_snaps(thick, foldangle=90, hinges=[], snaps=[], sockets=[], snaplen=5, snapdiam=5, hingegap=undef, layerheight=0.2)
{
    hingegap = default(hingegap, layerheight)+2*get_slop();
    difference() {
        children();
        for (hinge = hinges) {
            translate(hinge[1]) {
                living_hinge_mask(
                    l=hinge[0], thick=thick, layerheight=layerheight,
                    foldangle=foldangle, hingegap=hingegap, spin=hinge[2]
                );
            }
        }
    }
    for (snap = snaps) {
        translate(snap[0]) {
            snap_lock(
                thick=thick, snaplen=snaplen, snapdiam=snapdiam,
                layerheight=layerheight, foldangle=foldangle,
                hingegap=hingegap, spin=snap[1]
            );
        }
    }
    for (socket = sockets) {
        translate(socket[0]) {
            snap_socket(
                thick=thick, snaplen=snaplen, snapdiam=snapdiam,
                layerheight=layerheight, foldangle=foldangle,
                hingegap=hingegap, spin=socket[1]
            );
        }
    }
}



// Module: snap_lock()
// Synopsis: Creates a snap-lock shape.
// SynTags: Geom
// Topics: Hinges, Parts
// See Also: knuckle_hinge(), living_hinge_mask(), snap_lock(), snap_socket()
// Usage:
//   snap_lock(thick, [snaplen=], [snapdiam=], [layerheight=], [foldangle=], [hingegap=], [$slop=], [anchor=], [spin=], [orient=]) [ATTACHMENTS];
// Description:
//   Creates the central snaplock part.
// Arguments:
//   thick = Thickness in mm of the material to make the hinge in.
//   ---
//   snaplen = Length of locking snaps.
//   snapdiam = Diameter/width of locking snaps.
//   layerheight = The expected printing layer height in mm.
//   foldangle = The interior angle in degrees of the joint to be created with the hinge.  Default: 90
//   hingegap = Size in mm of the gap at the bottom of the hinge, to make room for folding.
//   $slop = increase size of hinge gap by double this amount
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Example:
//   snap_lock(thick=3, foldangle=60);
module snap_lock(thick, snaplen=5, snapdiam=5, layerheight=0.2, foldangle=90, hingegap=undef, anchor=CENTER, spin=0, orient=UP)
{
    hingegap = default(hingegap, layerheight)+2*get_slop();
    snap_x = (snapdiam/2) / tan(foldangle/2) + (thick-2*layerheight)/tan(foldangle/2) + hingegap/2;
    size = [snaplen, snapdiam, 2*thick];
    attachable(anchor,spin,orient, size=size) {
        back(snap_x) {
            cube([snaplen, snapdiam, snapdiam/2+thick], anchor=BOT) {
                attach(TOP) xcyl(l=snaplen, d=snapdiam, $fn = max(16,quant(segs(snapdiam/2),4)));
                attach(TOP) xcopies(snaplen-snapdiam/4/3) xscale(0.333) sphere(d=snapdiam*0.8, $fn = max(12,quant(segs(snapdiam/2),4)));
            }
        }
        children();
    }
}


// Module: snap_socket()
// Synopsis: Creates a snap-lock socket shape.
// SynTags: Geom
// Topics: Hinges, Parts
// See Also: knuckle_hinge(), living_hinge_mask(), snap_lock(), snap_socket()
// Usage:
//   snap_socket(thick, [snaplen=], [snapdiam=], [layerheight=], [foldangle=], [hingegap=], [$slop=], [anchor=], [spin=], [orient=]) [ATTACHMENTS];
// Description:
//   Creates the outside snaplock socketed part.
// Arguments:
//   thick = Thickness in mm of the material to make the hinge in.
//   ---
//   snaplen = Length of locking snaps.
//   snapdiam = Diameter/width of locking snaps.
//   layerheight = The expected printing layer height in mm.
//   foldangle = The interior angle in degrees of the joint to be created with the hinge.  Default: 90
//   hingegap = Size in mm of the gap at the bottom of the hinge, to make room for folding.
//   $slop = Increase size of hinge gap by double this amount
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Example:
//   snap_socket(thick=3, foldangle=60);
module snap_socket(thick, snaplen=5, snapdiam=5, layerheight=0.2, foldangle=90, hingegap=undef, anchor=CENTER, spin=0, orient=UP)
{
    hingegap = default(hingegap, layerheight)+2*get_slop();
    snap_x = (snapdiam/2) / tan(foldangle/2) + (thick-2*layerheight)/tan(foldangle/2) + hingegap/2;
    size = [snaplen, snapdiam, 2*thick];
    attachable(anchor,spin,orient, size=size) {
        fwd(snap_x) {
            zrot_copies([0,180], r=snaplen+get_slop()) {
                diff("divot")
                cube([snaplen, snapdiam, snapdiam/2+thick], anchor=BOT) {
                    attach(TOP) xcyl(l=snaplen, d=snapdiam, $fn=max(16,quant(segs(snapdiam/2),4)));
                    tag("divot") attach(TOP) left((snaplen+snapdiam/4/3)/2) xscale(0.333) sphere(d=snapdiam*0.8, $fn = max(12,quant(segs(snapdiam/2),4)));
                }
            }
        }
        children();
    }
}



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
