/////////////////////////////////////////////////////////////////////
// LibFile: rounding.scad
//   Routines to create rounded corners, with either circular rounding,
//   or continuous curvature rounding with no sudden curvature transitions.
//   Provides rounding of corners or rounding that preserves corner points and curves the edges.
//   Also provides some 3D rounding functions, and a powerful function for joining
//   two prisms together with a rounded fillet at the joint.  
// Includes:
//   include <BOSL2/std.scad>
// FileGroup: Advanced Modeling
// FileSummary: Round path corners, rounded prisms, rounded cutouts in tubes, filleted prism joints
// FileFootnotes: STD=Included in std.scad
//////////////////////////////////////////////////////////////////////

// Section: Types of Roundovers
//   The functions and modules in this file support two different types of roundovers and some different mechanisms for specifying
//   the size of the roundover.  The usual circular roundover can produce a tactile "bump" where the curvature changes from flat to
//   circular.  See https://hackernoon.com/apples-icons-have-that-shape-for-a-very-good-reason-720d4e7c8a14 for details.
//   We compute continuous curvature rounding using 4th order Bezier curves.  This type of rounding, which we call "smooth" rounding,
//   does not have a "radius" so we need different ways to specify the size of the roundover.  We introduce the `cut` and `joint`
//   parameters for this purpose.  They can specify dimensions of circular roundovers, continuous curvature "smooth" roundovers, and even chamfers.  
//   .
//   The `cut` parameter specifies the distance from the unrounded corner to the rounded tip, so how
//   much of the corner to "cut" off.  This can be easier to understand than setting a circular radius, which can be
//   unexpectedly extreme when the corner is sharp.  It also allows a systematic specification of
//   corner treatments that are the same size for all corner treatments.
//   .
//   The `joint` parameter specifies the distance
//   away from the corner along the path where the roundover or chamfer should start.  This parameter is good for ensuring that
//   your roundover fits on the polygon or polyhedron, because you can easily tell whether you have enough space, and whether
//   adjacent corner treatments interfere.
//   .
//   For circular rounding you can use the `radius` or `r` parameter to set the rounding radius.
//   .
//   For chamfers you can use `width` to set the width of the chamfer.  
//   .
//   The "smooth" rounding method also has a parameter that specifies how smooth the curvature match is.  This parameter, `k`,
//   ranges from 0 to 1, with a default of 0.5.  Larger values gives a more 
//   abrupt transition and smaller ones a more gradual transition.  If you set the value much higher
//   than 0.8 the curvature changes abruptly enough that though it is theoretically continuous, it may
//   not be continuous in practice.  If you set it small then the transition is so gradual that
//   the length of the roundover may be extremely long, and the actual rounded part of the curve may be small.  
// Figure(2D,Med,NoAxes):  Parameters of a "circle" roundover
//   h = 18;
//   w = 12.6;
//   strokewidth = .3;
//   example = [[0,0],[w,h],[2*w,0]];
//   stroke(example, width=strokewidth*1.5);
//   textangle = 90-vector_angle(example)/2;
//   theta = vector_angle(example)/2;
//   color("green"){ stroke([[w,h], [w,h-18*(1-sin(theta))/cos(theta)]], width=strokewidth, endcaps="arrow2");
//                   translate([w-1.75,h-7])scale(.1)rotate(textangle)text("cut",size=14); }
//   ll=lerp([w,h], [0,0],18/norm([w,h]-[0,0]) );
//   color("blue"){ stroke(_shift_segment([[w,h], ll], -.7), width=strokewidth,endcaps="arrow2");
//                  translate([w/2-1.3,h/2+.6])  scale(.1)rotate(textangle)text("joint",size=14);}
//   color("red")stroke(
//         select(round_corners(example, joint=18, method="circle",$fn=64,closed=false),1,-2),
//         width=strokewidth);
//   r=18*tan(theta);
//   color("black"){
//     stroke([ll, [w,h-r-18*(1-sin(theta))/cos(theta)]], width=strokewidth, endcaps="arrow2");
//     translate([w/1.6,0])text("radius", size=1.4);
//   }
// Figure(2D,Med,NoAxes):  Parameters of a "smooth" roundover with the default of `k=0.5`.  Note the long, slow transition from flat to round.  
//   h = 18;
//   w = 12.6;
//   strokewidth = .3;
//   example = [[0,0],[w,h],[2*w,0]];
//   stroke(example, width=strokewidth*1.5);
//   textangle = 90-vector_angle(example)/2;
//   color("green"){ stroke([[w,h], [w,h-cos(vector_angle(example)/2) *3/8*h]], width=strokewidth, endcaps="arrow2");
//                   translate([w-1.75,h-5.5])scale(.1)rotate(textangle)text("cut",size=14); }
//   ll=lerp([w,h], [0,0],18/norm([w,h]-[0,0]) );
//   color("blue"){ stroke(_shift_segment([[w,h], ll], -.7), width=strokewidth,endcaps="arrow2");
//                  translate([w/2-1.3,h/2+.6])  scale(.1)rotate(textangle)text("joint",size=14);}
//   color("red")stroke(
//         select(round_corners(example, joint=18, method="smooth",closed=false),1,-2),
//         width=strokewidth);
// Figure(2D,Med,NoAxes):  Parameters of a "smooth" roundover, with `k=0.75`.  The transition into the roundover is shorter, and faster.  The cut length is bigger for the same joint length.
//   h = 18;
//   w = 12.6;
//   strokewidth = .3;
//   example = [[0,0],[w,h],[2*w,0]];
//   stroke(example, width=strokewidth*1.5);
//   textangle = 90-vector_angle(example)/2;
//   color("green"){ stroke([[w,h], [w,h-cos(vector_angle(example)/2) *4/8*h]], width=strokewidth, endcaps="arrow2");
//                   translate([w-1.75,h-5.5])scale(.1)rotate(textangle)text("cut",size=14); }
//   ll=lerp([w,h], [0,0],18/norm([w,h]-[0,0]) );
//   color("blue"){ stroke(_shift_segment([[w,h], ll], -.7), width=strokewidth,endcaps="arrow2");
//                  translate([w/2-1.3,h/2+.6])  scale(.1)rotate(textangle)text("joint",size=14);}
//   color("red")stroke(
//         select(round_corners(example, joint=18, method="smooth",closed=false,k=.75),1,-2),
//         width=strokewidth);
// Figure(2D,Med,NoAxes):  Parameters of a "smooth" roundover, with `k=0.15`.  The transition is so gradual that it appears that the roundover is much smaller than specified.  The cut length is much smaller for the same joint length.  
//   h = 18;
//   w = 12.6;
//   strokewidth = .3;
//   example = [[0,0],[w,h],[2*w,0]];
//   stroke(example, width=strokewidth*1.5);
//   textangle = 90-vector_angle(example)/2;
//   color("green"){ stroke([[w,h], [w,h-cos(vector_angle(example)/2) *1.6/8*h]], width=strokewidth, endcaps="arrow2");
//                   translate([w+.3,h])text("cut",size=1.4); }
//   ll=lerp([w,h], [0,0],18/norm([w,h]-[0,0]) );
//   color("blue"){ stroke(_shift_segment([[w,h], ll], -.7), width=strokewidth,endcaps="arrow2");
//                  translate([w/2-1.3,h/2+.6])  scale(.1)rotate(textangle)text("joint",size=14);}
//   color("red")stroke(
//         select(round_corners(example, joint=18, method="smooth",closed=false,k=.15),1,-2),
//         width=strokewidth);
// Figure(2D,Med,NoAxes):  Parameters of a symmetric "chamfer".
//   h = 18;
//   w = 12.6;
//   strokewidth = .3;
//   example = [[0,0],[w,h],[2*w,0]];
//   stroke(example, width=strokewidth*1.5);
//   textangle = 90-vector_angle(example)/2;
//   color("black"){
//        stroke(fwd(1,
//         select(round_corners(example, joint=18, method="chamfer",closed=false),1,-2)),
//         width=strokewidth,endcaps="arrow2");
//        translate([w,.3])text("width", size=1.4,halign="center");
//   }     
//   color("green"){ stroke([[w,h], [w,h-18*cos(vector_angle(example)/2)]], width=strokewidth, endcaps="arrow2");
//                   translate([w-1.75,h-5.5])scale(.1)rotate(textangle)text("cut",size=14); }
//   ll=lerp([w,h], [0,0],18/norm([w,h]-[0,0]) );
//   color("blue"){ stroke(_shift_segment([[w,h], ll], -.7), width=strokewidth,endcaps="arrow2");
//                  translate([w/2-1.3,h/2+.6]) rotate(textangle)text("joint",size=1.4);}
//   color("red")stroke(
//         select(round_corners(example, joint=18, method="chamfer",closed=false),1,-2),
//         width=strokewidth);


// Section: Rounding Paths

// Function: round_corners()
// Synopsis: Round or chamfer the corners of a path (clipping them off).
// SynTags: Path
// Topics: Rounding, Paths
// See Also: round_corners(), smooth_path(), path_join(), offset_stroke()
// Usage:
//   rounded_path = round_corners(path, [method], [radius=], [cut=], [joint=], [closed=], [verbose=]);
// Description:
//   Takes a 2D or 3D path as input and rounds each corner
//   by a specified amount.  The rounding at each point can be different and some points can have zero
//   rounding.  The `round_corners()` function supports three types of corner treatment: chamfers, circular rounding,
//   and continuous curvature rounding using 4th order bezier curves.  See
//   [Types of Roundover](rounding.scad#subsection-types-of-roundover) for details on rounding types.  
//   .
//   You select the type of rounding using the `method` parameter, which should be `"smooth"` to
//   get continuous curvature rounding, `"circle"` to get circular rounding, or `"chamfer"` to get chamfers.  The default is circle
//   rounding.  Each method accepts multiple options to specify the amount of rounding.  See
//   [Types of Roundover](rounding.scad#subsection-types-of-roundover) for example diagrams.
//   .
//   * The `cut` parameter specifies the distance from the unrounded corner to the rounded tip, so how
//   much of the corner to "cut" off.  
//   * The `joint` parameter specifies the distance
//   away from the corner along the path where the roundover or chamfer should start.  This makes it easy to ensure your roundover fits,
//   so use it if you want the largest possible roundover.  
//   * For circular rounding you can use the `radius` or `r` parameter to set the rounding radius.
//   * For chamfers you can use the `width` parameter, which sets the width of the chamfer edge.  
//   .
//   As explained in [Types of Roundover](rounding.scad#subsection-types-of-roundover), the continuous curvature "smooth"
//   type of rounding also accepts the `k` parameter, between 0 and 1, which specifies how fast the curvature changes at
//   the joint.  The default is `k=0.5`.  
//   .
//   If you select curves that are too large to fit, the function fails with an error.  You can set `verbose=true` to
//   get a message showing a list of scale factors you can apply to your rounding parameters so that the
//   roundovers fit on the curve.  If the scale factors are larger than one
//   then they indicate how much you can increase the curve sizes before collisions occur.
//   .
//   The parameters `radius`, `cut`, `joint` and `k` can be numbers, which round every corner using the same parameters, or you
//   can specify a list to round each corner with different parameters.  If the curve is not closed then the first and last points
//   of the curve are not rounded.  In this case you can specify a full list of points anyway, and the endpoint values are ignored,
//   or you can specify a list that has length len(path)-2, omitting the two dummy values.
//   .
//   If your input path includes collinear points you must use a cut or radius value of zero for those "corners".  You can
//   choose a nonzero joint parameter when the collinear points form a 180 degree angle.  This causes extra points to be inserted. 
//   If the collinear points form a spike (0 degree angle), then `round_corners()` fails. 
//   .
//   Examples:
//   * `method="circle", radius=2`:
//       Rounds every point with circular, radius 2 roundover
//   * `method="smooth", cut=2`:
//       Rounds every point with continuous curvature rounding with a cut of 2, and a default 0.5 smoothing parameter
//   * `method="smooth", cut=2, k=0.3`:
//       Rounds every point with continuous curvature rounding with a cut of 2, and a gentle 0.3 smoothness setting
//   .
//   The number of segments used for roundovers is determined by `$fa`, `$fs` and `$fn` as usual for
//   circular roundovers.  For continuous curvature roundovers `$fs` and `$fn` are used and `$fa` is
//   ignored.  Note that $fn is interpreted as the number of points on the roundover curve, which is
//   not equivalent to its meaning for rounding circles because roundovers are usually small fractions
//   of a circular arc.  As usual, $fn overrides $fs.  When doing continuous curvature rounding, be sure to use lots of segments or the effect
//   would be hidden by the discretization.  Note that if you use $fn with "smooth" then $fn points are added at each corner.
//   This guarantees a specific output length.  It also means that if
//   you set `joint` nonzero on a flat "corner", with collinear points, you get `$fn` points at that "corner."
//   If you have two roundovers that fully consume a segment, then they share a point where they meet in the segment, which means the output
//   point count decreases by one.  
// Arguments:
//   path = list of 2d or 3d points defining the path to be rounded.
//   method = rounding method to use.  Set to "chamfer" for chamfers, "circle" for circular rounding and "smooth" for continuous curvature 4th order bezier rounding.  Default: "circle"
//   ---
//   radius/r = rounding radius, only compatible with `method="circle"`. Can be a number or vector.
//   cut = rounding cut distance, compatible with all methods.  Can be a number or vector.
//   joint = rounding joint distance, compatible with `method="chamfer"` and `method="smooth"`.  Can be a number or vector.
//   width = width of the flat edge created by chamfering, compatible with `method="chamfer"`.  Can be a number or vector. 
//   k = continuous curvature smoothness parameter for `method="smooth"`.  Can be a number or vector.  Default: 0.5
//   closed = if true treat the path as a closed polygon, otherwise treat it as open.  Default: true.
//   verbose = if true display rounding scale factors that show how close roundovers are to overlapping.  Default: false
//
// Example(2D,Med): Standard circular roundover with radius the same at every point. Compare results at the different corners.
//   $fn=36;
//   shape = [[0,0], [10,0], [15,12], [6,6], [6, 12], [-3,7]];
//   polygon(round_corners(shape, radius=1));
//   color("red") down(.1) polygon(shape);
// Example(2D,Med): Circular roundover using the "cut" specification, the same at every corner.
//   $fn=36;
//   shape = [[0,0], [10,0], [15,12], [6,6], [6, 12], [-3,7]];
//   polygon(round_corners(shape, cut=1));
//   color("red") down(.1) polygon(shape);
// Example(2D,Med): Continous curvature roundover using "cut", still the same at every corner.  The default smoothness parameter of 0.5 was too gradual for these roundovers to fit, but 0.7 works.
//   $fn=36;
//   shape = [[0,0], [10,0], [15,12], [6,6], [6, 12], [-3,7]];
//   polygon(round_corners(shape, method="smooth", cut=1, k=0.7));
//   color("red") down(.1) polygon(shape);
// Example(2D,Med): Continuous curvature roundover using "joint", for the last time the same at every corner.  Notice how small the roundovers are.
//   $fn=36;
//   shape = [[0,0], [10,0], [15,12], [6,6], [6, 12], [-3,7]];
//   polygon(round_corners(shape, method="smooth", joint=1, k=0.7));
//   color("red") down(.1) polygon(shape);
// Example(2D,Med): Circular rounding, different at every corner, some corners left unrounded
//   shape = [[0,0], [10,0], [15,12], [6,6], [6, 12], [-3,7]];
//   radii = [1.8, 0, 2, 0.3, 1.2, 0];
//   polygon(round_corners(shape, radius = radii,$fn=64));
//   color("red") down(.1) polygon(shape);
// Example(2D,Med): Continuous curvature rounding, different at every corner, with varying smoothness parameters as well, and `$fs` set small.  Note that `$fa` is ignored here with method set to "smooth".
//   shape = [[0,0], [10,0], [15,12], [6,6], [6, 12], [-3,7]];
//   cuts = [1.5,0,2,0.3, 1.2, 0];
//   k = [0.6, 0.5, 0.5, 0.7, 0.3, 0.5];
//   polygon(round_corners(shape, method="smooth", cut=cuts, k=k, $fs=0.1));
//   color("red") down(.1) polygon(shape);
// Example(2D,Med): Chamfers
//   $fn=36;
//   shape = [[0,0], [10,0], [15,12], [6,6], [6, 12], [-3,7]];
//   polygon(round_corners(shape, method="chamfer", cut=1));
//   color("red") down(.1) polygon(shape);
// Example(Med3D): 3D printing test pieces to display different curvature shapes.  You can see the discontinuity in the curvature on the "C" piece in the rendered image.
//   ten = square(50);
//   cut = 5;
//   linear_extrude(height=14) {
//     translate([25,25,0])text("C",size=30, valign="center", halign="center");
//     translate([85,25,0])text("5",size=30, valign="center", halign="center");
//     translate([85,85,0])text("3",size=30, valign="center", halign="center");
//     translate([25,85,0])text("7",size=30, valign="center", halign="center");
//   }
//   linear_extrude(height=13) {
//     polygon(round_corners(ten, cut=cut, $fn=96*4));
//     translate([60,0,0])polygon(round_corners(ten,  method="smooth", cut=cut, $fn=96));
//     translate([60,60,0])polygon(round_corners(ten, method="smooth", cut=cut, k=0.32, $fn=96));
//     translate([0,60,0])polygon(round_corners(ten, method="smooth", cut=cut, k=0.7, $fn=96));
//   }
// Example(2D,Med): Rounding a path that is not closed in a three different ways.
//   $fs=.1;
//   $fa=1;
//   zigzagx = [-10, 0, 10, 20, 29, 38, 46, 52, 59, 66, 72, 78, 83, 88, 92, 96, 99, 102, 112];
//   zigzagy = concat([0], flatten(repeat([-10,10],8)), [-10,0]);
//   zig = hstack(zigzagx,zigzagy);
//   stroke(zig,width=1);   // Original shape
//   fwd(20)            // Smooth size corners with a cut of 4 and curvature parameter 0.6
//     stroke(round_corners(zig,cut=4, k=0.6, method="smooth", closed=false),width=1);
//   fwd(40)            // Smooth size corners with circular arcs and a cut of 4
//     stroke(round_corners(zig,cut=4,closed=false, method="circle"),width=1);
//                      // Smooth size corners with a circular arc and radius 1.5 (close to maximum possible)
//   fwd(60)            // Note how the different points are cut back by different amounts
//     stroke(round_corners(zig,radius=1.5,closed=false),width=1);
// Example(FlatSpin,VPD=42,VPT=[7.75,6.69,5.22]): Rounding some random 3D paths
//   $fn=36;
//   list1= [
//     [2.887360, 4.03497, 6.372090],
//     [5.682210, 9.37103, 0.783548],
//     [7.808460, 4.39414, 1.843770],
//     [0.941085, 5.30548, 4.467530],
//     [1.860540, 9.81574, 6.497530],
//     [6.938180, 7.21163, 5.794530]
//   ];
//   list2= [
//     [1.079070, 4.74091, 6.900390],
//     [8.775850, 4.42248, 6.651850],
//     [5.947140, 9.17137, 6.156420],
//     [0.662660, 6.95630, 5.884230],
//     [6.564540, 8.86334, 9.953110],
//     [5.420150, 4.91874, 3.866960]
//   ];
//   path_sweep(regular_ngon(n=36,or=.1),round_corners(list1,closed=false, method="smooth", cut = 0.65));
//   right(6)
//     path_sweep(regular_ngon(n=36,or=.1),round_corners(list2,closed=false, method="circle", cut = 0.75));
// Example(3D,Med):  Rounding a spiral with increased rounding along the length
//   // Construct a square spiral path in 3D
//   $fn=36;
//   square = [[0,0],[1,0],[1,1],[0,1]];
//   spiral = flatten(repeat(concat(square,reverse(square)),5));  // Squares repeat 10x, forward and backward
//   squareind = [for(i=[0:9]) each [i,i,i,i]];                   // Index of the square for each point
//   z = count(40)*.2+squareind;
//   path3d = hstack(spiral,z);                                   // 3D spiral
//   rounding = squareind/20;
//       // Setting k=1 means curvature is not continuous, but curves are as round as possible
//       // Try changing the value to see the effect.
//   rpath = round_corners(path3d, joint=rounding, k=1, method="smooth", closed=false);
//   path_sweep( regular_ngon(n=36, or=.1), rpath);
// Example(2D): The rounding invocation that is commented out gives an error because the rounding parameters interfere with each other.  The error message gives a list of factors that can help you fix this: [0.852094, 0.852094, 1.85457, 10.1529]
//   $fn=64;
//   path = [[0, 0],[10, 0],[20, 20],[30, -10]];
//   debug_polygon(path);
//   //polygon(round_corners(path,cut = [1,3,1,1],
//   //        method="circle"));
// Example(2D): The list of factors shows that the problem is in the first two rounding values, because the factors are smaller than one.  If we multiply the first two parameters by 0.85 then the roundings fit.  The verbose option gives us the same fit factors.  
//   $fn=64;
//   path = [[0, 0],[10, 0],[20, 20],[30, -10]];
//   polygon(round_corners(path,cut = [0.85,3*0.85,1,1],
//                         method="circle", verbose=true));
// Example(2D): From the fit factors we can see that rounding at vertices 2 and 3 could be increased a lot.  Applying those factors we get this more rounded shape.  The new fit factors show that we can still further increase the rounding parameters if we wish.  
//   $fn=64;
//   path = [[0, 0],[10, 0],[20, 20],[30, -10]];
//   polygon(round_corners(path,cut = [0.85,3*0.85,2.13, 10.15],
//                         method="circle",verbose=true));
// Example(2D): Using the `joint` parameter, it's easier to understand whether your roundvers can fit.  We can guarantee a fairly large roundover on any path by picking each one to use up half the segment distance along the shorter of its two segments:
//   $fn=64;
//   path = [[0, 0],[10, 0],[20, 20],[30, -10]];
//   path_len = path_segment_lengths(path,closed=true);
//   halflen = [for(i=idx(path)) min(select(path_len,i-1,i))/2];
//   polygon(round_corners(path,joint = halflen,
//                         method="circle",verbose=true));
// Example(2D): Chamfering, specifying the chamfer width
//   path = star(5, step=2, d=100);
//   path2 = round_corners(path, method="chamfer", width=5);
//   polygon(path2);
// Example(2D): Chamfering, specifying the cut
//   path = star(5, step=2, d=100);
//   path2 = round_corners(path, method="chamfer", cut=5);
//   polygon(path2);
// Example(2D): Chamfering, specifying joint length
//   path = star(5, step=2, d=100);
//   path2 = round_corners(path, method="chamfer", joint=5);
//   polygon(path2);
// Example(2D): Two passes to apply chamfers first, and then round the unchamfered corners.  Chamfers always add one point, so it's not hard to keep track of the vertices
//   $fn=32;
//   shape = square(10);
//   chamfered = round_corners(shape, method="chamfer",
//                             cut=[2,0,2,0]);
//   rounded = round_corners(chamfered, 
//              cut = [0, 0,  // 1st original vertex, chamfered
//                     1.5,   // 2nd original vertex
//                     0, 0,  // 3rd original vertex, chamfered
//                     2.5]); // 4th original vertex
//   polygon(rounded);
// Example(2D): Another example of mixing chamfers and roundings with two passes
//   path = star(5, step=2, d=100);
//   chamfcut = [for (i=[0:4]) each [7,0]];
//   radii = [for (i=[0:4]) each [0,0,10]];
//   path2=round_corners(
//           round_corners(path,
//                         method="chamfer",
//                         cut=chamfcut),
//           radius=radii);
//   stroke(path2, closed=true);
// Example(2D,Med,NoAxes): Specifying by corner index.  Use {{list_set()}} to construct the full chamfer cut list. 
//   path = star(47, ir=25, or=50);  // long path, lots of corners
//   chamfind = [8, 28, 60];         // But only want 3 chamfers
//   chamfcut = list_set([],chamfind,[10,13,15],minlen=len(path));
//   rpath = round_corners(path, cut=chamfcut, method="chamfer");   
//   polygon(rpath);
// Example(2D,Med,NoAxes): Two-pass to chamfer and round by index.  Use {{repeat_entries()}} to correct for first pass chamfers.
//   $fn=32;
//   path = star(47, ir=32, or=65);  // long path, lots of corners
//   chamfind = [8, 28, 60];         // But only want 3 chamfers
//   roundind = [7,9,27,29,59,61];   // And 6 roundovers
//   chamfcut = list_set([],chamfind,[10,13,15],minlen=len(path));
//   roundcut = list_set([],roundind,repeat(8,6),minlen=len(path));
//   dups = list_set([], chamfind, repeat(2,len(chamfind)), dflt=1, minlen=len(path));
//   rpath1 = round_corners(path, cut=chamfcut, method="chamfer");
//   rpath2 = round_corners(rpath1, cut=repeat_entries(roundcut,dups));
//   polygon(rpath2);
module round_corners(path, method="circle", radius, r, cut, joint, width, k, closed=true, verbose=false) {no_module();}
function round_corners(path, method="circle", radius, r, cut, joint, width, k, closed=true, verbose=false) =
    assert(in_list(method,["circle", "smooth", "chamfer"]), "method must be one of \"circle\", \"smooth\" or \"chamfer\"")
    let(
        default_k = 0.5,
        size=one_defined([radius, r, cut, joint, width], "radius,r,cut,joint,width"),
        path = force_path(path), 
        size_ok = is_num(size) || len(size)==len(path) || (!closed && len(size)==len(path)-2),
        k_ok = is_undef(k) || (method=="smooth" && (is_num(k) || len(k)==len(path) || (!closed && len(k)==len(path)-2))),
        measure = is_def(radius) ? "radius"
                : is_def(r) ? "radius"
                : is_def(cut) ? "cut" 
                : is_def(joint) ? "joint"
                : "width"
    )
    assert(is_path(path,[2,3]), "input path must be a 2d or 3d path")
    assert(len(path)>2,str("Path has length ",len(path),".  Length must be 3 or more."))
    assert(size_ok,str("Input ",measure," must be a number or list with length ",len(path), closed?"":str(" or ",len(path)-2)))
    assert(k_ok,method=="smooth" ? str("Input k must be a number or list with length ",len(path), closed?"":str(" or ",len(path)-2)) :
                                   "Input k is only allowed with method=\"smooth\"")
    assert(method=="circle" || measure!="radius", "radius parameter allowed only with method=\"circle\"")
    assert(method=="chamfer" || measure!="width", "width parameter  allowed only with method=\"chamfer\"")
    let(
        parm = is_num(size) ? repeat(size, len(path)) :
               len(size)<len(path) ? [0, each size, 0] :
                                     size,
        k = is_undef(k) ? repeat(default_k,len(path)) :
            is_num(k) ? repeat(k, len(path)) :
            len(k)<len(path) ? [0, each k, 0] :
                               k,
        badparm = [for(i=idx(parm)) if(parm[i]<0)i],
        badk = [for(i=idx(k)) if(k[i]<0 || k[i]>1)i]
     )
     assert(is_vector(parm) && badparm==[], str(measure," must be nonnegative"))
     assert(is_vector(k) && badk==[], "k parameter must be in the interval [0,1]")
     let(
        // dk is a list of parameters, where distance is the joint length to move away from the corner
        //     "smooth" method: [distance, curvature]
        //     "circle" method: [distance, radius]
        //     "chamfer" method: [distance]
        dk = [
              for(i=[0:1:len(path)-1])
                  let(
                      pathbit = select(path,i-1,i+1),
                      // This is the half-angle at the corner
                      angle = approx(pathbit[0],pathbit[1]) || approx(pathbit[1],pathbit[2]) ? undef
                            : vector_angle(select(path,i-1,i+1))/2
                  )
                  (!closed && (i==0 || i==len(path)-1))  ? [0] :          // Force zeros at ends for non-closed
                  parm[i]==0 ? [0]    : // If no rounding requested then don't try to compute parameters
                  assert(is_def(angle), str("Repeated point in path at index ",i," with nonzero rounding"))
                  assert(!approx(angle,0), closed && i==0 ? "Closing the path causes it to turn back on itself at the end" :
                                                            str("Path turns back on itself at index ",i," with nonzero rounding"))
                  (method=="chamfer" && measure=="joint")? [parm[i]] :
                  (method=="chamfer" && measure=="cut")  ? [parm[i]/cos(angle)] :
                  (method=="chamfer" && measure=="width") ? [parm[i]/sin(angle)/2] :
                  (method=="smooth" && measure=="joint") ? [parm[i],k[i]] :
                  (method=="smooth" && measure=="cut")   ? [8*parm[i]/cos(angle)/(1+4*k[i]),k[i]] :
                  (method=="circle" && measure=="radius")? [parm[i]/tan(angle), parm[i]] :
                  (method=="circle" && measure=="joint") ? [parm[i], parm[i]*tan(angle)] : 
                /*(method=="circle" && measure=="cut")*/   approx(angle,90) ? [INF] : 
                                                           let( circ_radius = parm[i] / (1/sin(angle) - 1))
                                                           [circ_radius/tan(angle), circ_radius],
        ],
        lengths = [for(i=[0:1:len(path)]) norm(select(path,i)-select(path,i-1))],
        scalefactors = [
            for(i=[0:1:len(path)-1])
                if (closed || (i!=0 && i!=len(path)-1))
                 min(
                    lengths[i]/(select(dk,i-1)[0]+dk[i][0]),
                    lengths[i+1]/(dk[i][0]+select(dk,i+1)[0])
                 )
        ],
        dummy = verbose ? echo("Roundover scale factors:",scalefactors) : 0
    )
    assert(min(scalefactors)>=1,str("Roundovers are too big for the path.  If you multitply them by this vector they should fit: ",scalefactors))
    // duplicates are introduced when roundings fully consume a segment, so remove them
    deduplicate([
        for(i=[0:1:len(path)-1]) each
            (dk[i][0] == 0)? [path[i]] :
            (method=="smooth")? _bezcorner(select(path,i-1,i+1), dk[i]) :
            (method=="chamfer") ? _chamfcorner(select(path,i-1,i+1), dk[i]) :
            _circlecorner(select(path,i-1,i+1), dk[i])
    ]);

// Computes the continuous curvature control points for a corner when given as
// input three points in a list defining the corner.  The points must be
// equidistant from each other to produce the continuous curvature result.
// The output control points include the 3 input points plus two
// interpolated points.
//
// k is the curvature parameter, ranging from 0 for slow transition
// up to 1 for a sharp transition that doesn't have continuous curvature any more
function _smooth_bez_fill(points,k) = [
        points[0],
        lerp(points[1],points[0],k),
        points[1],
        lerp(points[1],points[2],k),
        points[2],
];

// Computes the points of a continuous curvature roundover given as input
// the list of 3 points defining the corner and a parameter specification
//
// If parm is a scalar then it is treated as the curvature and the control
// points are calculated using _smooth_bez_fill.  Otherwise, parm is assumed
// to be a pair [d,k] where d is the length of the curve.  The length is
// calculated from the input point list and the control point list does not
// necessarily include points[0] or points[2] on its output.
//
// The number of points output is $fn if it is set.  Otherwise $fs is used
// to calculate the point count.

function _bezcorner(points, parm) =
        let(
                P = is_list(parm)?
                        let(
                                d = parm[0],
                                k = parm[1],
                                prev = unit(points[0]-points[1]),
                                next = unit(points[2]-points[1])
                        ) [
                                points[1]+d*prev,
                                points[1]+k*d*prev,
                                points[1],
                                points[1]+k*d*next,
                                points[1]+d*next
                        ] : _smooth_bez_fill(points,parm),
                N = max(3,$fn>0 ?$fn : ceil(bezier_length(P)/$fs))
        )
        bezier_curve(P,N,endpoint=true);

function _chamfcorner(points, parm) =
        let(
                d = parm[0],
                prev = unit(points[0]-points[1]),
                next = unit(points[2]-points[1])
          )
       [points[1]+prev*d, points[1]+next*d];

function _circlecorner(points, parm) =
        let(
            angle = vector_angle(points)/2,
            d = parm[0],
            r = parm[1],
            prev = unit(points[0]-points[1]),
            next = unit(points[2]-points[1])
        )
        approx(angle,90) ? [points[1]+prev*d, points[1]+next*d] :
        let(
            center = r/sin(angle) * unit(prev+next)+points[1],
                    start = points[1]+prev*d,
                    end = points[1]+next*d
        )     // 90-angle is half the angle of the circular arc
        arc(max(3,ceil((90-angle)/180*segs(r))), cp=center, points=[start,end]);


// Used by offset_sweep and convex_offset_extrude.
// Produce edge profile curve from the edge specification
// z_dir is the direction multiplier (1 to build up, -1 to build down)
function _rounding_offsets(edgespec,z_dir=1) =
        let(
                edgetype = struct_val(edgespec, "type"),
                extra = struct_val(edgespec,"extra"),
                N = struct_val(edgespec, "steps"),
                r = struct_val(edgespec,"r"),
                cut = struct_val(edgespec,"cut"),
                k = struct_val(edgespec,"k"),
                angle = struct_val(edgespec, "angle"), 
                radius = in_list(edgetype,["circle","teardrop"])
                            ? (is_def(cut) ? cut/(sqrt(2)-1) : r)
                         :edgetype=="chamfer"
                            ? (is_def(cut) ? sqrt(2)*cut : r)
                         : undef,
                chamf_angle = struct_val(edgespec, "angle"),
                cheight = struct_val(edgespec, "chamfer_height"),
                cwidth = struct_val(edgespec, "chamfer_width"),
                chamf_width = first_defined([!all_defined([cut,chamf_angle]) ? undef : cut/cos(chamf_angle),
                                             cwidth,
                                             !all_defined([cheight,chamf_angle]) ? undef : cheight*tan(chamf_angle)]),
                chamf_height = first_defined([
                                              !all_defined([cut,chamf_angle]) ? undef : cut/sin(chamf_angle),
                                              cheight,
                                              !all_defined([cwidth, chamf_angle]) ? undef : cwidth/tan(chamf_angle)]),
                joint = first_defined([
                        struct_val(edgespec,"joint"),
                        all_defined([cut,k]) ? 16*cut/sqrt(2)/(1+4*k) : undef
                ]),
                points = struct_val(edgespec, "points"),
                argsOK = in_list(edgetype,["circle","teardrop"])? is_def(radius) :
                        edgetype == "chamfer"? chamf_angle>0 && chamf_angle<90 && num_defined([chamf_height,chamf_width])==2 :
                        edgetype == "smooth"? num_defined([k,joint])==2 :
                        edgetype == "profile"? points[0]==[0,0] :
                        false
        )
        assert(argsOK,str("Invalid specification with type ",edgetype))
        let(
                offsets =
                        edgetype == "profile"? scale([-1,z_dir], p=list_tail(points)) :
                        edgetype == "chamfer"?  chamf_width==0 && chamf_height==0? [] : [[-chamf_width,z_dir*abs(chamf_height)]] :
                        edgetype == "teardrop"? (
                                radius==0? [] : concat(
                                        [for(i=[1:N]) [radius*(cos(i*45/N)-1),z_dir*abs(radius)* sin(i*45/N)]],
                                        [[-2*radius*(1-sqrt(2)/2), z_dir*abs(radius)]]
                                )
                        ) :
                        edgetype == "circle"? radius==0? [] : [for(i=[1:N]) [radius*(cos(i*angle/N)-1), z_dir*abs(radius)*sin(i*angle/N)]] :
                        /* smooth */ joint==0 ? [] :
                        list_tail(
                                _bezcorner([[0,0],[0,z_dir*abs(joint)],[-joint,z_dir*abs(joint)]], k, $fn=N+2)
                        )
        )
        quant(extra > 0 && len(offsets)>0 ? concat(offsets, [last(offsets)+[0,z_dir*extra]]) : offsets, 1/1024);



// Function: smooth_path()
// Synopsis: Create a smoothed path passing through all the points of a given path, or passing through all the segment midpoint tangents.
// SynTags: Path
// Topics: Rounding, Paths
// See Also: round_corners(), smooth_path(), path_join(), offset_stroke()
// Usage: "edges" method
//   smoothed = smooth_path(path, [tangents], [size=|relsize=], [method="edges"], [splinesteps=], [closed=], [uniform=]);
// Usage: "corners" method
//   smoothed = smooth_path(path, [size=|relsize=], method="corners", [splinesteps=], [closed=]);
// Description:
//   Smooths the input path, creating a continuous curve using a cubic spline, using one of two methods.
//   .
//   For `method="edges"` (default), every segment (edge) of the path is replaced by a cubic curve with `splinesteps`
//   points, and the cubic interpolation passes through every input point on the path, matching the tangents at every
//   point. If you do not specify `tangents`, they are computed using {{path_tangents()}} with `uniform=false` by
//   default. Only the dirction of a tangent vector matters, not the vector length.
//   Setting `uniform=true` with non-uniform sampling may be desirable in some cases but tends to
//   produces curves that overshoot the point on the path.  
//   .
//   For `method="corners"`, every corner of the path is replaced by two cubic curves, each with
//   `splinesteps` points. The two curves are joined at the corner bisector, and the cubic interpolations
//   are tangent to the midpoint of every segment. The `tangents` and `uniform` parameters don't apply to the
//   "corners" method. Using either one with "corners" causes an error.
//   .
//   The `size` or `relsize` parameters apply to both methods. They determine how far the curve can bend away
//   from the input path. In the case where the path has three non-collinear points, the size specifies the
//   exact distance between the specified path and the curve (maximum distance from edge if for the "edges"
//   method, or distance from corner with the "corners" method).
//   In 2D when the spline may make an S-curve, for the "edges" method the size parameter specifies the sum
//   of the deviations of the two peaks of the curve. In 3-space the bezier curve may have three extrema: two
//   maxima and one minimum.  In this case the size specifies the sum of the maxima minus the minimum.
//   .
//   If you give `relsize` instead, then for the "edges" method, the maximum deviation from the segment is
//   relative to  the segment length (e.g. 0.05 means 5% of the segment length). For the "corners" method,
//   `relsize` determines where the curve intersects the corner bisector, relative to the maximum deviation
//   possible (which corresponds to a circle rounding from the shortest leg of the corner). For example,
//   `relsize=1` is the maximum deviation from the corner (a circle arc from the shortest leg), and `relsize=0.5`
//   causes the curve to intersect the corner bisector halfway between that maximum and the tip of the corner.
//   .
//   At a given segment or corner (depending on the method) there is a maximum size: a size value that is too
//   large is rounded down. See also path_to_bezpath().
// Arguments:
//   path = path to smooth
//   tangents = tangents constraining curve direction vectors (vector length doesn't matter) at each point for `method="edges"`. Default: computed automatically
//   ---
//   relsize = relative maximum devation between the curve and edge (for method="edges") or corner (for method="corners"), a number or vector, expressed as proportion of edge length or proportion of max distance from corner (typically between 0 and 1). Default: 0.1 for `method="edges"` or 0.5 for `method="corners"`
//   size = absolute deviation between the curve and edge (for method="edges") or corner (for method="corners"), a number or vector.
//   method = type of curve; "edges" makes a curve that intersects all the path vertices but deviates from the path edges, and "corners" makes a curve that is tangent to all segment midpoints but deviates from the corners. Default: "edges"
//   splinesteps = Number of steps for each bezier curve section. Default: 10
//   uniform = set to true to compute tangents with uniform=true. Applies only to "edges" method. Default: false
//   closed = true if the curve is closed.  Default: false.
// Example(2D): Original path in green, smoothed "edges" path in yellow, "corners" path in red:
//   color("green")stroke(square(4), width=0.06);
//   stroke(smooth_path(square(4),size=0.4), width=0.1);
//   stroke(smooth_path(square(4),method="corners",size=0.4),
//          color="red", width=0.1);
// Example(2D): Closing the path changes the end tangents. Original path in green, "edges" path in yellow, "corners" in red.
//   polygon(smooth_path(square(4),method="edges",size=0.4,closed=true));
//   color("red")
//     polygon(smooth_path(square(4),method="corners",size=0.4,closed=true));
//   stroke(square(4), color="green", closed=true, width=0.06);
// Example(2D): Here's the square again with less smoothing. The "edges" curve is closer to the edge of the square, and the "corners" curve is closer to the square's corners.
//   polygon(smooth_path(square(4), size=.25,closed=true));
//   color("red") polygon(smooth_path(square(4),
//        method="corners",size=.25,closed=true));
//   stroke(square(4), closed=true, color="green", width=0.05);
// Example(2D): Turning on uniform tangent calculation also changes the end derivatives for the "edges" curve:
//   color("green")stroke(square(4), width=0.1);
//   stroke(smooth_path(square(4),size=0.4,uniform=true),
//          width=0.1);
// Example(2D): Here's a wide rectangle. With `method="edges"` (yellow), using `size` means all edges bulge the same amount, regardless of their length. With `method="corners"` (red), the curve is `size` distance from the corners (up to a maximum theoretical circular arc).
//   color("green")
//     stroke(square([10,5]), closed=true, width=0.06);
//   stroke(smooth_path(square([10,5]), method="edges",
//     size=1, closed=true), width=0.1);
//   stroke(smooth_path(square([10,5]), method="corners",
//     size=1, closed=true), width=0.1, color="red");
// Example(2D): For the "edges" curve, with relsize the bulge is proportional to the side length. 
//   color("green")stroke(square([10,4]), closed=true, width=0.1);
//   stroke(smooth_path(square([10,4]),relsize=0.1,closed=true),
//          width=0.1);
// Example(2D,Med,NoScales): For the "corners" curve, with relsize the distance from the corner is proportional to the maximum distance corresponding to a circular arc (shown in red) from the shorter leg of the corner. As `relsize` approaches zero, the curve approaches the corner.
//   stroke(smooth_path(square([20,15]), method="corners", relsize=1, closed=true),
//          color="red", closed=true, width=0.1);
//   stroke(smooth_path(square([20,15]), method="corners", relsize=0.66, closed=true),
//          color="gold", closed=true, width=0.1);
//   stroke(smooth_path(square([20,15]), method="corners", relsize=0.33, closed=true),
//          color="blue", closed=true, width=0.1);
//   stroke(smooth_path(square([20,15]), method="corners", relsize=0.001, closed=true),
//          color="green", closed=true, width=0.1);
// Example(2D): Settting uniform to true biases the tangents to align more with the line sides (applicable only to "edges" method).
//   color("green")
//     stroke(square([10,4]), closed=true, width=0.1);
//   stroke(smooth_path(square([10,4]),uniform=true,
//                      relsize=0.1,closed=true),
//          width=0.1);
// Example(2D): A more interesting shape, comparing the "edges" method (yellow) with "corners" method (red).
//   path = [[0,0], [4,0], [7,14], [-3,12]];
//   polygon(smooth_path(path,size=1,closed=true));
//   color("red") polygon(smooth_path(path,method="corners",relsize=0.7,closed=true));
//   stroke(path, color="green", width=0.2, closed=true);
// Example(2D,NoScales): Here's the square with a size that's too big to achieve, giving the the maximum possible curve with `method="edges"` (yellow). For `method="corners"` (red), the maximum possible distance from the corners is a circle.
//   color("green")stroke(square(4), width=0.06,closed=true);
//   stroke(smooth_path(square(4), method="edges", size=4, closed=true),
//          closed=true, width=0.1);
//   stroke(smooth_path(square(4), method="corners", size=4, closed=true),
//          color="red", closed=true, width=0.1);
// Example(2D): For `method="edges"`, you can alter the shape of the curve by specifying your own arbitrary tangent values. Only the vector direction matters, not the vector length.
//   polygon(smooth_path(square(4),
//           tangents=[[-2,-1], [-4,1], [1,2], [6,-1]],
//           size=0.4,closed=true));
// Example(2D): You can give a different size for each segment ("edges" method in yellow) or corner ("corners" method in red). The first vertex of the square (green) is the lower right corner, and the first edge is the bottom segment.
//   polygon(smooth_path(square(4),size = [.4, .05, 1, .3],
//                       method="edges", closed=true));
//   color("red")
//     polygon(smooth_path(square(4), size = [.4, .05, 1, .3],
//                         method="corners", closed=true));
//   stroke(square(4), color="green", width=0.03,closed=true);
// Example(FlatSpin,VPD=35,VPT=[4.5,4.5,1]): Works on 3d paths also.
//   path = [[0,0,0],[3,3,2],[6,0,1],[9,9,0]];
//   stroke(smooth_path(path,relsize=.1),width=.3);
//   color("red") for(p=path) translate(p) sphere(d=0.3);
//   stroke(path, width=0.1, color="red");
// Example(FlatSpin,VPD=45): Comparison of "edges" and "corners" 3D path resembling a [trefoil knot](https://en.wikipedia.org/wiki/Trefoil_knot).
//   shape = [[8.66, -5, -5], [8.66, 5, 5], [-2, 3.46, 0],
//       [-8.66, -5, -5], [0, -10, 5], [4, 0, 0],
//       [0, 10, -5], [-8.66, 5, 5], [-2, -3.46, 0]];
//   stroke(smooth_path(shape, method="corners", relsize=1, closed=true), color="red", closed=true, width=0.5);
//   stroke(smooth_path(shape, method="edges", size=1.5, closed=true, splinesteps=20), closed=true, width=0.5);
//   stroke(shape, color="green", width=0.15, closed=true);
// Example(2D): For the default "edges" method, this shows the type of overshoot that can occur with `uniform=true`.  You can produce overshoots like this if you supply a tangent that is difficult to connect to the adjacent points  
//   pts = [[-3.3, 1.7], [-3.7, -2.2], [3.8, -4.8], [-0.9, -2.4]];
//   stroke(smooth_path(pts, uniform=true, relsize=0.1),width=.1);
//   color("red")move_copies(pts)circle(r=.15,$fn=12);
// Example(2D): With the default of `uniform=false` no overshoot occurs.  Note that the shape of the curve is quite different.  
//   pts = [[-3.3, 1.7], [-3.7, -2.2], [3.8, -4.8], [-0.9, -2.4]];
//   stroke(smooth_path(pts, uniform=false, relsize=0.1),width=.1);
//   color("red")move_copies(pts)circle(r=.15,$fn=12);
module smooth_path(path, tangents, size, relsize, method="edges", splinesteps=10, uniform, closed=false) {no_module();}
function smooth_path(path, tangents, size, relsize, method="edges", splinesteps=10, uniform, closed) =
is_1region(path)
    ? smooth_path(path[0], tangents, size, relsize, method, splinesteps, uniform, default(closed,true))
    : assert(method=="edges" || method=="corners", "method must be \"edges\" or \"corners\".")
assert(method=="edges" || (is_undef(tangents) && is_undef(uniform)), "The tangents and uniform parameters are incompatible with method=\"corners\".")
let (
    uniform = default(uniform,false),
    bez = method=="edges"
        ? path_to_bezpath(path, tangents=tangents, size=size, relsize=relsize, uniform=uniform, closed=default(closed,false))
        : path_to_bezcornerpath(path, size=size, relsize=relsize, closed=default(closed,false)),
    smoothed = bezpath_curve(bez,splinesteps=splinesteps)
)
closed ? list_unwrap(smoothed) : smoothed;



function _scalar_to_vector(value,length,varname) = 
  is_vector(value)
    ? assert(len(value)==length, str(varname," must be length ",length))
      value
    : assert(is_num(value), str(varname, " must be a numerical value"))
      repeat(value, length);


// Function: path_join()
// Synopsis: Join paths end to end with optional rounding.
// SynTags: Path
// Topics: Rounding, Paths
// See Also: round_corners(), smooth_path(), path_join(), offset_stroke()
// Usage:
//   joined_path = path_join(paths, [joint], [k=], [relocate=], [closed=]);
// Description:
//   Connect a sequence of paths together into a single path with optional continuous curvature rounding
//   applied at the joints.  By default the first path is taken as specified and subsequent paths are
//   translated into position so that each path starts where the previous path ended.
//   If you set relocate to false then this relocation is skipped.
//   You specify rounding using the `joint` parameter, which specifies the distance away from the corner
//   where the roundover should start.  The path_join function may remove many path points to cut the path 
//   back by the joint length.  Rounding is using continous curvature 4th order bezier splines and
//   the parameter `k` specifies how smooth the curvature match is.  This parameter ranges from 0 to 1 with
//   a default of 0.5.  Use a larger k value to get a curve that is bigger for the same joint value.  When
//   k=1 the curve may be similar to a circle if your curves are symmetric.  As the path is built up, the joint
//   parameter applies to the growing path, so if you pick a large joint parameter it may interact with the
//   previous path sections.  See [Types of Roundover](rounding.scad#subsection-types-of-roundover) for more details
//   on continuous curvature rounding. 
//   .
//   The rounding is created by extending the two clipped paths to define a corner point.  If the extensions of
//   the paths do not intersect, the function issues an error.  When closed=true the final path should actually close
//   the shape, repeating the starting point of the shape.  If it does not, then the rounding fills the gap.
//   .
//   The number of segments in the roundovers is set based on $fn and $fs.  If you use $fn it specifies the number of
//   segments in the roundover, regardless of its angular extent.
// Arguments:
//   paths = list of paths to join
//   joint = joint distance, either a number, a pair (giving the previous and next joint distance) or a list of numbers and pairs.  Default: 0
//   ---
//   k = curvature parameter, either a number or vector.  Default: 0.5
//   relocate = set to false to prevent paths from being arranged tail to head.  Default: true
//   closed = set to true to round the junction between the last and first paths.  Default: false
// Example(2D): Connection of 3 simple paths.  
//   horiz = [[0,0],[10,0]];
//   vert = [[0,0],[0,10]];
//   stroke(path_join([horiz, vert, -horiz]));
// Example(2D): Adding curvature with joint of 3
//   horiz = [[0,0],[10,0]];
//   vert = [[0,0],[0,10]];
//   stroke(path_join([horiz, vert, -horiz],joint=3,$fn=16));
// Example(2D): Setting k=1 increases the amount of curvature
//   horiz = [[0,0],[10,0]];
//   vert = [[0,0],[0,10]];
//   stroke(path_join([horiz, vert, -horiz],joint=3,k=1,$fn=16));
// Example(2D): Specifying pairs of joint values at a path joint creates an asymmetric curve
//   horiz = [[0,0],[10,0]];
//   vert = [[0,0],[0,10]];
//   stroke(path_join([horiz, vert, -horiz],
//                    joint=[[4,1],[1,4]],$fn=16),width=.3);
// Example(2D): A closed square
//   horiz = [[0,0],[10,0]];
//   vert = [[0,0],[0,10]];
//   stroke(path_join([horiz, vert, -horiz, -vert],
//                    joint=3,k=1,closed=true,$fn=16),closed=true);
// Example(2D): Different curve at each corner by changing the joint size
//   horiz = [[0,0],[10,0]];
//   vert = [[0,0],[0,10]];
//   stroke(path_join([horiz, vert, -horiz, -vert],
//                    joint=[3,0,1,2],k=1,closed=true,$fn=16),
//          closed=true,width=0.4);
// Example(2D): Different curve at each corner by changing the curvature parameter.  Note that k=0 still gives a small curve, unlike joint=0 which gives a sharp corner.
//   horiz = [[0,0],[10,0]];
//   vert = [[0,0],[0,10]];
//   stroke(path_join([horiz, vert, -horiz, -vert],joint=3,
//                    k=[1,.5,0,.7],closed=true,$fn=16),
//          closed=true,width=0.4);
// Example(2D): Joint value of 7 is larger than half the square so curves interfere with each other, which breaks symmetry because they are computed sequentially
//   horiz = [[0,0],[10,0]];
//   vert = [[0,0],[0,10]];
//   stroke(path_join([horiz, vert, -horiz, -vert],joint=7,
//                     k=.4,closed=true,$fn=16),
//          closed=true);
// Example(2D): Unlike round_corners, we can add curves onto curves.
//   $fn=64;
//   myarc = arc(width=20, thickness=5 );
//   stroke(path_join(repeat(myarc,3), joint=4));
// Example(2D): Here we make a closed shape from two arcs and round the sharp tips
//   arc1 = arc(width=20, thickness=4,$fn=75);
//   arc2 = reverse(arc(width=20, thickness=2,$fn=75));
//   // Without rounding
//   stroke(path_join([arc1,arc2]),width=.3);
//   // With rounding
//   color("red")stroke(path_join([arc1,arc2], 3,k=1,closed=true),
//                      width=.3,closed=true,$fn=12); 
// Example(2D): Combining arcs with segments
//   arc1 = arc(width=20, thickness=4,$fn=75);
//   arc2 = reverse(arc(width=20, thickness=2,$fn=75));
//   vpath = [[0,0],[0,-5]];
//   stroke(path_join([arc1,vpath,arc2,reverse(vpath)]),width=.2);
//   color("red")stroke(path_join([arc1,vpath,arc2,reverse(vpath)],
//                                [1,2,2,1],k=1,closed=true),
//                      width=.2,closed=true,$fn=12);
// Example(2D): Here relocation is off.  We have three segments (in yellow) and add the curves to the segments.  Notice that joint zero still produces a curve because it refers to the endpoints of the supplied paths.  
//   p1 = [[0,0],[2,0]];
//   p2 = [[3,1],[1,3]];
//   p3 = [[0,3],[-1,1]];
//   color("red")stroke(
//     path_join([p1,p2,p3], joint=0, relocate=false,
//               closed=true),
//     width=.3,$fn=48);
//   for(x=[p1,p2,p3]) stroke(x,width=.3);
// Example(2D): If you specify closed=true when the last path doesn't meet the first one then it is similar to using relocate=false: the function tries to close the path using a curve.  In the example below, this results in a long curve to the left, when given the unclosed three segments as input.  Note that if the segments are parallel the function fails with an error.  The extension of the curves must intersect in a corner for the rounding to be well-defined.  To get a normal rounding of the closed shape, you must include a fourth path, the last segment that closes the shape.
//   horiz = [[0,0],[10,0]];
//   vert = [[0,0],[0,10]];
//   h2 = [[0,-3],[10,0]];
//   color("red")stroke(
//     path_join([horiz, vert, -h2],closed=true,
//               joint=3,$fn=25),
//     closed=true,width=.5);
//   stroke(path_join([horiz, vert, -h2]),width=.3);
// Example(2D): With a single path with closed=true the start and end junction is rounded.
//   tri = regular_ngon(n=3, r=7);
//   stroke(path_join([tri], joint=3,closed=true,$fn=12),
//          closed=true,width=.5);
module path_join(paths,joint=0,k=0.5,relocate=true,closed=false) { no_module();}
function path_join(paths,joint=0,k=0.5,relocate=true,closed=false)=
  assert(is_list(paths),"Input paths must be a list of paths")
  let(
      paths = [for(i=idx(paths)) force_path(paths[i],str("paths[",i,"]"))],
      badpath = [for(j=idx(paths)) if (!is_path(paths[j])) j]
  )
  assert(badpath==[], str("Entries in paths are not valid paths: ",badpath))
  len(paths)==0 ? [] :
  len(paths)==1 && !closed ? paths[0] :
  let(
      paths = !closed || len(paths)>1
            ? paths
            : [list_wrap(paths[0])],
      N = len(paths) + (closed?0:-1),
      k = _scalar_to_vector(k,N),
      repjoint = is_num(joint) || (is_vector(joint,2) && len(paths)!=3),
      joint = repjoint ? repeat(joint,N) : joint
  )
  assert(all_nonnegative(k), "k must be nonnegative")
  assert(len(joint)==N,str("Input joint must be scalar or length ",N))
  let(
      bad_j = [for(j=idx(joint)) if (!is_num(joint[j]) && !is_vector(joint[j],2)) j]
  )
  assert(bad_j==[], str("Invalid joint values at indices ",bad_j))
  let(result=_path_join(paths,joint,k, relocate=relocate, closed=closed))
  closed ? list_unwrap(result) : result;

function _path_join(paths,joint,k=0.5,i=0,result=[],relocate=true,closed=false) =
  let( 
      result = result==[] ? paths[0] : result,
      loop = i==len(paths)-1,
      revresult = reverse(result),
      nextpath = loop     ? result
               : relocate ? move(revresult[0]-paths[i+1][0], p=paths[i+1])
               : paths[i+1],
      d_first = is_vector(joint[i]) ? joint[i][0] : joint[i],
      d_next = is_vector(joint[i]) ? joint[i][1] : joint[i]
  )
  assert(d_first>=0 && d_next>=0, str("Joint value negative when adding path ",i+1))
  
  assert(d_first<path_length(revresult),str("Path ",i," is too short for specified cut distance ",d_first))
  assert(d_next<path_length(nextpath), str("Path ",i+1," is too short for specified cut distance ",d_next))
  let(
      firstcut = path_cut_points(revresult, d_first, direction=true),
      nextcut = path_cut_points(nextpath, d_next, direction=true)
  )
  assert(!loop || nextcut[1] < len(revresult)-1-firstcut[1], "Path is too short to close the loop")
  let(
     first_dir=firstcut[2],
     next_dir=nextcut[2],
     corner = approx(firstcut[0],nextcut[0]) ? firstcut[0]
            : line_intersection([firstcut[0], firstcut[0]-first_dir], [nextcut[0], nextcut[0]-next_dir],RAY,RAY)
  )
  assert(is_def(corner), str("Curve directions at cut points don't intersect in a corner when ",
                             loop?"closing the path":str("adding path ",i+1)))
  let(
      bezpts = _smooth_bez_fill([firstcut[0], corner, nextcut[0]],k[i]),
      N = max(3,$fn>0 ?$fn : ceil(bezier_length(bezpts)/$fs)),
      bezpath = approx(firstcut[0],corner) && approx(corner,nextcut[0])
                  ? []
                  : bezier_curve(bezpts,N),
      new_result = [each select(result,loop?nextcut[1]:0,len(revresult)-1-firstcut[1]),
                    each bezpath,
                    nextcut[0],
                    if (!loop) each list_tail(nextpath,nextcut[1])
                   ]
  )
  i==len(paths)-(closed?1:2)
     ? new_result
     : _path_join(paths,joint,k,i+1,new_result, relocate,closed);



// Function&Module: offset_stroke()
// Synopsis: Draws a line along a path with options to specify angles and roundings at the ends.
// SynTags: Path, Region
// Topics: Rounding, Paths
// See Also: round_corners(), smooth_path(), path_join(), offset_stroke()
// Usage: as module
//   offset_stroke(path, [width], [rounded=], [chamfer=], [start=], [end=], [check_valid=], [quality=], [closed=],...) [ATTACHMENTS];
// Usage: as function
//   path = offset_stroke(path, [width], closed=false, [rounded=], [chamfer=], [start=], [end=], [check_valid=], [quality=],...);
//   region = offset_stroke(path, [width], closed=true, [rounded=], [chamfer=], [start=], [end=], [check_valid=], [quality=],...);
// Description:
//   Uses `offset()` to compute a stroke for the input path.  Unlike `stroke`, the result does not need to be
//   centered on the input path.  The corners can be rounded, pointed, or chamfered, and you can make the ends
//   rounded, flat or pointed with the `start` and `end` parameters.
//   .
//   The `check_valid` and `quality`  parameters are passed through to `offset()`
//   .
//   If `width` is a scalar then the output is a centered stroke of the specified width.  If width
//   is a list of two values then those two values define the stroke side positions relative to the center line, where
//   as with offset(), the shift is to the left for open paths and outward for closed paths.  For example,
//   setting `width` to `[0,1]` creates a stroke of width 1 that extends entirely to the left of the input, and and [-4,-6]
//   creates a stroke of width 2 offset 4 units to the right of the input path.
//   .
//   If closed==false then the function form returns a path.  If closed==true then it returns a region. The `start` and
//   `end` parameters are forbidden for closed paths.
//   .
//   Three simple end treatments are supported, "flat" (the default), "round" and "pointed".  The "flat" treatment
//   cuts off the ends perpendicular to the path and the "round" treatment applies a semicircle to the end.  The
//   "pointed" end treatment caps the stroke with a centered triangle that has 45 degree angles on each side.
//   .
//   More complex end treatments are available through parameter lists with helper functions to ease parameter passing.  The parameter list
//   keywords are
//      - "for" : must appear first in the list and have the value "offset_stroke"
//      - "type": the type of end treatment, one of "shifted_point", "roundover", or "flat"
//      - "angle": relative angle (relative to the path)
//      - "abs_angle": absolute angle (angle relative to x-axis)
//      - "cut": cut distance for roundovers, a single value to round both corners identically or a list of two values for the two corners.  Negative values round outward.
//      - "k": curvature smoothness parameter for roundovers, default 0.75
//   .
//   Function helpers for defining ends, prefixed by "os" for offset_stroke, are:
//      - os_flat(angle|absangle): specify a flat end either relative to the path or relative to the x-axis
//      - os_pointed(dist, [loc]): specify a pointed tip where the point is distance `loc` from the centerline (positive is the left direction as for offset), and `dist` is the distance from the path end to the point tip.  The default value for `loc` is zero (the center).  You must specify `dist` when using this option.
//      - os_round(cut, [angle|absangle], [k]).  Rounded ends with the specified cut distance, based on the specified angle or absolute angle.  The `k` parameter is the smoothness parameter for continuous curvature rounding.  See [Types of Roundover](rounding.scad#subsection-types-of-roundover) for more details on
//        continuous curvature rounding.  
//   .
//   Note that `offset_stroke()` attempts to apply roundovers and angles at the ends even when it means deleting segments of the stroke, unlike `round_corners()`, which works only on a segment adjacent to a corner.  If you specify an overly extreme angle, it fails to find an intersection with the stroke and display an error.  When you specify an angle, the end segment is rotated around the center of the stroke and the last segment of the stroke one one side is extended to the corner.
//   .
//   The `$fn` and `$fs` variables are used in the usual way to determine the number of segments for roundings produced by the offset
//   invocations and roundings produced by the semi-circular "round" end treatment.  The os_round() end treatment
//   uses a bezier curve, and produces segments of approximate length `$fs` or it produces `$fn` segments.
//   This means that even a quarter circle has `$fn` segments, unlike the usual case where it would have `$fn/4` segments.
// Arguments:
//   path = 2d path that defines the stroke
//   width = width of the stroke, a scalar or a vector of 2 values giving the offset from the path.  Default: 1
//   ---
//   rounded = set to true to use rounded offsets, false to use sharp (delta) offsets.  Default: true
//   chamfer = set to true to use chamfers when `rounded=false`.  Default: false
//   start = end treatment for the start of the stroke when closed=false.  See above for details.  Default: "flat"
//   end = end treatment for the end of the stroke when closed=false.  See above for details.  Default: "flat"
//   check_valid = passed to offset().  Default: true
//   quality = passed to offset().  Default: 1
//   closed = true if the curve is closed, false otherwise.  Default: false
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `"origin"`
//   spin = Rotate this many degrees after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   cp = Centerpoint for determining intersection anchors or centering the shape.  Determintes the base of the anchor vector.  Can be "centroid", "mean", "box" or a 2D point.  Default: "centroid"
//   atype = Set to "hull" or "intersect" to select anchor type.  Default: "hull"
// Named Anchors:
//   "origin" = The native position of the region.
// Anchor Types:
//   "hull" = Anchors to the virtual convex hull of the region.
//   "intersect" = Anchors to the outer edge of the region.
// Example(2D):  Basic examples illustrating flat, round, and pointed ends, on a finely sampled arc and a path made from 3 segments.
//   arc = arc(points=[[1,1],[3,4],[6,3]],n=50);
//   path = [[0,0],[6,2],[9,7],[8,10]];
//   xdistribute(spacing=10){
//     offset_stroke(path, width = 2);
//     offset_stroke(path, start="round", end="round", width = 2, $fn=32);
//     offset_stroke(path, start="pointed", end="pointed", width = 2);
//   }
//   fwd(10) xdistribute(spacing=10){
//     offset_stroke(arc, width = 2);
//     offset_stroke(arc, start="round", end="round", width = 2, $fn=32);
//     offset_stroke(arc, start="pointed", end="pointed", width = 2);
//   }
// Example(2D):  The effect of the `rounded` and `chamfer` options is most evident at sharp corners.  This only affects the middle of the path, not the ends.
//   sharppath = [[0,0], [1.5,5], [3,0]];
//   xdistribute(spacing=5){
//     offset_stroke(sharppath, $fn=16);
//     offset_stroke(sharppath, rounded=false);
//     offset_stroke(sharppath, rounded=false, chamfer=true);
//   }
// Example(2D):  When closed is enabled all the corners are affected by those options.
//   sharppath = [[0,0], [1.5,5], [3,0]];
//   xdistribute(spacing=5){
//     offset_stroke(sharppath,closed=true, $fn=16);
//     offset_stroke(sharppath, rounded=false, closed=true);
//     offset_stroke(sharppath, rounded=false, chamfer=true,
//                   closed=true);
//   }
// Example(2D):  The left stroke uses flat ends with a relative angle of zero.  The right hand one uses flat ends with an absolute angle of zero, so the ends are parallel to the x-axis.
//   path = [[0,0],[6,2],[9,7],[8,10]];
//   offset_stroke(path, start=os_flat(angle=0), end=os_flat(angle=0));
//   right(5)
//     offset_stroke(path, start=os_flat(abs_angle=0), end=os_flat(abs_angle=0));
// Example(2D):  With continuous sampling the end treatment can remove segments or extend the last segment linearly, as shown here.  Again the left side uses relative angle flat ends and the right hand example uses absolute angle.
//   arc = arc(points=[[4,0],[3,4],[6,3]],n=50);
//   offset_stroke(arc, start=os_flat(angle=45), end=os_flat(angle=45));
//   right(5)
//     offset_stroke(arc, start=os_flat(abs_angle=45), end=os_flat(abs_angle=45));
// Example(2D):  The os_pointed() end treatment allows adjustment of the point tip, as shown here.  The width is 2 so a location of 1 is at the edge.
//   arc = arc(points=[[1,1],[3,4],[6,3]],n=50);
//   offset_stroke(arc, width=2, start=os_pointed(loc=1,dist=3),end=os_pointed(loc=1,dist=3));
//   right(10)
//     offset_stroke(arc, width=2, start=os_pointed(dist=4),end=os_pointed(dist=-1));
//   fwd(7)
//     offset_stroke(arc, width=2, start=os_pointed(loc=2,dist=2),end=os_pointed(loc=.5,dist=-1));
// Example(2D):  The os_round() end treatment adds roundovers to the end corners by specifying the `cut` parameter.  In the first example, the cut parameter is the same at each corner.  The bezier smoothness parameter `k` is given to allow a larger cut.  In the second example, each corner is given a different roundover, including zero for no rounding at all.  The red shows the same strokes without the roundover.
//   $fn=36;
//   arc = arc(points=[[1,1],[3,4],[6,3]],n=50);
//   path = [[0,0],[6,2],[9,7],[8,10]];
//   offset_stroke(path, width=2, rounded=false,start=os_round(angle=-20, cut=0.4,k=.9),
//                                              end=os_round(angle=-35, cut=0.4,k=.9));
//   color("red")down(.1)offset_stroke(path, width=2, rounded=false,start=os_flat(-20),
//                                                                  end=os_flat(-35));
//   right(9){
//     offset_stroke(arc, width=2, rounded=false, start=os_round(cut=[.3,.6],angle=-45),
//                                                end=os_round(angle=20,cut=[.6,0]));
//     color("red")down(.1)offset_stroke(arc, width=2, rounded=false, start=os_flat(-45),
//                                                                    end=os_flat(20));
//   }
// Example(2D):  Negative cut values produce a flaring end.  Note how the absolute angle aligns the ends of the first example withi the axes.  In the second example positive and negative cut values are combined.  Also, different cuts are needed at the start end to produce a similar-looking flare.
//   arc = arc(points=[[1,1],[3,4],[6,3]],n=50);
//   path = [[0,0],[6,2],[9,7],[8,10]];
//   offset_stroke(path, width=2, rounded=false,start=os_round(cut=-1, abs_angle=90),
//                                              end=os_round(cut=-0.5, abs_angle=0),$fn=36);
//   right(10)
//      offset_stroke(arc, width=2, rounded=false, start=os_round(cut=[-.75,-.2], angle=-45),
//                                                 end=os_round(cut=[-.2,.2], angle=20),$fn=36);
// Example(2D):  Setting the width to a vector allows you to offset the stroke.  Here with successive increasing offsets we create a set of parallel strokes
//   path = [[0,0],[4,4],[8,4],[2,9],[10,10]];
//   for(i=[0:.25:2])
//     offset_stroke(path, rounded=false,width = [i,i+.08]);
// Example(2D):  Setting rounded=true in the above example makes a big difference in the result.  
//   path = [[0,0],[4,4],[8,4],[2,9],[10,10]];
//   for(i=[0:.25:2])
//     offset_stroke(path, rounded=true,width = [i,i+.08], $fn=36);
// Example(2D):  In this example a spurious triangle appears.  This results from overly enthusiastic validity checking.  Turning validity checking off fixes it in this case.
//   path = [[0,0],[4,4],[8,4],[2,9],[10,10]];
//   offset_stroke(path, check_valid=true,rounded=false,
//                 width = [1.4, 1.5]);
//   right(2)
//     offset_stroke(path, check_valid=false,rounded=false,
//                   width = [1.4, 1.5]);
// Example(2D):  But in this case, disabling the validity check produces an invalid result.
//   path = [[0,0],[4,4],[8,4],[2,9],[10,10]];
//   offset_stroke(path, check_valid=true,rounded=false,
//                 width = [1.9, 2]);
//   translate([1,-0.25])
//     offset_stroke(path, check_valid=false,rounded=false,
//                   width = [1.9, 2]);
// Example(2D): Self-intersecting paths are handled differently than with the `stroke()` module.
//   $fn=16;
//   path = turtle(["move",10,"left",144], repeat=4);
//   stroke(path, closed=true);
//   right(12)
//     offset_stroke(path, width=1, closed=true);
function offset_stroke(path, width=1, rounded=true, start, end, check_valid=true, quality=1, chamfer=false, closed=false,
                       atype="hull", anchor="origin", spin, cp="centroid") =
        let(path = force_path(path))
        assert(is_path(path,2),"path is not a 2d path")
        let(
            closedok = !closed || (is_undef(start) && is_undef(end)),
            start = default(start,"flat"),
            end = default(end,"flat")
        )
        assert(closedok, "Parameters `start` and `end` not allowed with closed path")
        let(
            start = closed? [] : _parse_stroke_end(default(start,"flat"),"start"),
            end = closed? [] : _parse_stroke_end(default(end,"flat"),"end"),
            width = is_list(width)? reverse(sort(width)) : [1,-1]*width/2,
            left_r = !rounded? undef : width[0],
            left_delta = rounded? undef : width[0],
            right_r = !rounded? undef : width[1],
            right_delta = rounded? undef : width[1],
            left_path = offset(
                    path, delta=left_delta, r=left_r, closed=closed,
                    check_valid=check_valid, quality=quality,
                    chamfer=chamfer 
            ),
            right_path = offset(
                    path, delta=right_delta, r=right_r, closed=closed,
                    check_valid=check_valid, quality=quality,
                    chamfer=chamfer 
            )
         )
         closed? let(pts = [left_path, right_path])
                 reorient(anchor=anchor, spin=spin, two_d=true, region=pts, extent=atype=="hull", cp=cp, p=pts)
         :
         let(
             startpath = _stroke_end(width,left_path, right_path, start),
             endpath = _stroke_end(reverse(width),reverse(right_path), reverse(left_path),end),
             clipping_ok = startpath[1]+endpath[2]<=len(left_path) && startpath[2]+endpath[1]<=len(right_path)
         )
         assert(clipping_ok, "End treatment removed the whole stroke")
         let(
             pts = concat(
                          slice(left_path,startpath[1],-1-endpath[2]),
                          endpath[0],
                          reverse(slice(right_path,startpath[2],-1-endpath[1])),
                          startpath[0]
                  )
         ) 
         reorient(anchor=anchor, spin=spin, two_d=true, path=pts, extent=atype=="hull", cp=cp, p=pts);

function os_pointed(dist,loc=0) =
        assert(is_def(dist), "Must specify `dist`")
        [
                "for", "offset_stroke",
                "type", "shifted_point",
                "loc",loc,
                "dist",dist
        ];

function os_round(cut, angle, abs_angle, k, r) =
        assert(is_undef(r), "Radius not supported for os_round with offset_stroke.  (Did you mean os_circle for offset_sweep?)")
        let(
                acount = num_defined([angle,abs_angle]),
                use_angle = first_defined([angle,abs_angle,0])
        )
        assert(acount<2, "You must define only one of `angle` and `abs_angle`")
        assert(is_def(cut), "Parameter `cut` not defined.")
        [
                "for", "offset_stroke",
                "type", "roundover",
                "angle", use_angle,
                "absolute", is_def(abs_angle),
                "cut", is_vector(cut)? point2d(cut) : [cut,cut],
                "k", first_defined([k, 0.75])
        ];


function os_flat(angle, abs_angle) =
        let(
                acount = num_defined([angle,abs_angle]),
                use_angle = first_defined([angle,abs_angle,0])
        )
        assert(acount<2, "You must define only one of `angle` and `abs_angle`")
        [
                "for", "offset_stroke",
                "type", "flat",
                "angle", use_angle,
                "absolute", is_def(abs_angle)
        ];



// Return angle in (-90,90] required to map line1 onto line2 (lines specified as lists of two points)
function angle_between_lines(line1,line2) =
        let(angle = atan2(det2([line1,line2]),line1*line2))
        angle > 90 ? angle-180 :
        angle <= -90 ? angle+180 :
        angle;


function _parse_stroke_end(spec,name) =
        is_string(spec)?
            assert(
                    in_list(spec,["flat","round","pointed"]),
                    str("Unknown \"",name,"\" string specification \"", spec,"\".  Must be \"flat\", \"round\", or \"pointed\"")
            )
            [["type", spec]]
        : let(
              dummy = _struct_valid(spec,"offset_stroke",name)
          )
          struct_set([], spec);


function _stroke_end(width,left, right, spec) =
        let(
                type = struct_val(spec, "type"),
                user_angle = default(struct_val(spec, "angle"), 0),
                normal_seg = _normal_segment(right[0], left[0]),
                normal_pt = normal_seg[1],
                center = normal_seg[0],
                parallel_dir = unit(left[0]-right[0]),
                normal_dir = unit(normal_seg[1]-normal_seg[0]),
                width_dir = sign(width[0]-width[1])
        )
        type == "round"? [arc(points=[right[0],normal_pt,left[0]],n=ceil(segs(width/2)/2)),1,1]  :
        type == "pointed"? [[normal_pt],0,0] :
        type == "shifted_point"? (
                let(shiftedcenter = center + width_dir * parallel_dir * struct_val(spec, "loc"))
                [[shiftedcenter+normal_dir*struct_val(spec, "dist")],0,0]
        ) :
        // Remaining types all support angled cutoff, so compute that
        assert(abs(user_angle)<=90, "End angle must be in [-90,90]")
        let(
                angle = struct_val(spec,"absolute")?
                        angle_between_lines(left[0]-right[0],[cos(user_angle),sin(user_angle)]) :
                        user_angle,
                endseg = [center, rot(p=[left[0]], angle, cp=center)[0]],
                intright = angle>0,
                pathclip = _path_line_intersection(intright? right : left, endseg),
                pathextend = line_intersection(endseg, select(intright? left:right,0,1))
        )
        type == "flat"? (
                intright?
                        [[pathclip[0], pathextend], 1, pathclip[1]] :
                        [[pathextend, pathclip[0]], pathclip[1],1]
        ) :
        type == "roundover"? (
                let(
                        bez_k = struct_val(spec,"k"),
                        cut = struct_val(spec,"cut"),
                        cutleft = cut[0],
                        cutright = cut[1],
                        // Create updated paths taking into account clipping for end rotation
                        newright = intright?
                                concat([pathclip[0]],list_tail(right,pathclip[1])) :
                                concat([pathextend],list_tail(right)),
                        newleft = !intright?
                                concat([pathclip[0]],list_tail(left,pathclip[1])) :
                                concat([pathextend],list_tail(left)),
                        // calculate corner angles, which are different when the cut is negative (outside corner)
                        leftangle = cutleft>=0?
                                vector_angle([newleft[1],newleft[0],newright[0]])/2 :
                                90-vector_angle([newleft[1],newleft[0],newright[0]])/2,
                        rightangle = cutright>=0?
                                vector_angle([newright[1],newright[0],newleft[0]])/2 :
                                90-vector_angle([newright[1],newright[0],newleft[0]])/2,
                        jointleft = 8*cutleft/cos(leftangle)/(1+4*bez_k),
                        jointright = 8*cutright/cos(rightangle)/(1+4*bez_k),
                        pathcutleft = path_cut_points(newleft,abs(jointleft)),
                        pathcutright = path_cut_points(newright,abs(jointright)),
                        leftdelete = intright? pathcutleft[1] : pathcutleft[1] + pathclip[1] -1,
                        rightdelete = intright? pathcutright[1] + pathclip[1] -1 : pathcutright[1],
                        leftcorner = line_intersection([pathcutleft[0], newleft[pathcutleft[1]]], [newright[0],newleft[0]]),
                        rightcorner = line_intersection([pathcutright[0], newright[pathcutright[1]]], [newright[0],newleft[0]]),
                        roundover_fits = is_def(rightcorner) && is_def(leftcorner) &&
                                         jointleft+jointright < norm(rightcorner-leftcorner)
                )
                assert(roundover_fits,"Roundover too large to fit")
                let(
                        angled_dir = unit(newleft[0]-newright[0]),
                        nPleft = [
                                leftcorner - jointleft*angled_dir,
                                leftcorner,
                                pathcutleft[0]
                        ],
                        nPright = [
                                pathcutright[0],
                                rightcorner,
                                rightcorner + jointright*angled_dir
                        ],
                        leftcurve = _bezcorner(nPleft, bez_k),
                        rightcurve = _bezcorner(nPright, bez_k)
                )
                [concat(rightcurve, leftcurve), leftdelete, rightdelete]
        ) : [[],0,0];  // This case shouldn't occur

// returns [intersection_pt, index of first point in path after the intersection]
function _path_line_intersection(path, line, ind=0) =
        ind==len(path)-1 ? undef :
        let(intersect=line_intersection(line, select(path,ind,ind+1),LINE,SEGMENT))
        // If it intersects the segment excluding its final point, then we're done
        // The final point is treated as part of the next segment
        is_def(intersect) && intersect != path[ind+1]?
                [intersect, ind+1] :
                _path_line_intersection(path, line, ind+1);

module offset_stroke(path, width=1, rounded=true, start, end, check_valid=true, quality=1, chamfer=false, closed=false,
                     atype="hull", anchor="origin", spin, cp="centroid")
{
        result = offset_stroke(
                path, width=width, rounded=rounded,
                start=start, end=end,
                check_valid=check_valid, quality=quality,
                chamfer=chamfer,
                closed=closed,anchor="origin"
        );
        region(result,atype=atype, anchor=anchor, spin=spin, cp=cp) children();
}


// Section: Three-Dimensional Rounding

// Function&Module: offset_sweep()
// Synopsis: Make a solid from a polygon with offset that changes along its length.
// SynTags: Geom, VNF
// Topics: Rounding, Offsets
// See Also: convex_offset_extrude(), rounded_prism(), bent_cutout_mask(), join_prism(), linear_sweep()
// Usage: most common module arguments.  See Arguments list below for more.
//   offset_sweep(path, [height|length=|h=|l=], [bottom], [top], [offset=], [convexity=],...) [ATTACHMENTS];
// Usage: most common function arguments.  See Arguments list below for more.
//   vnf = offset_sweep(path, [height|length=|h=|l=], [bottom], [top], [offset=], ...);
// Description:
//   Takes a 2d path as input and extrudes it upward and/or downward.  Each layer in the extrusion is produced using `offset()` to expand or shrink the previous layer.  When invoked as a function returns a VNF; when invoked as a module produces geometry.  
//   Using the `top` and/or `bottom` arguments you can specify a sequence of offsets values, or you can use several built-in offset profiles that
//   provide end treatments such as roundovers.
//   The height of the resulting object can be specified using the `height` argument, in which case `height` must be larger than the combined height
//   of the end treatments.  If you omit `height`, then the object height is the height of just the top and bottom end treatments.  
//   .
//   The path is shifted by `offset()` multiple times in sequence
//   to produce the final shape (not multiple shifts from one parent), so coarse definition of the input path degrades
//   from the successive shifts.  If the result seems rough or strange try increasing the number of points you use for
//   your input.  If you get unexpected corners in your result you may have forgotten to set `$fn` or `$fa` and `$fs`.  
//   Be aware that large numbers of points (especially when check_valid is true) can lead to lengthy run times.  If your
//   shape doesn't develop new corners from the offsetting you may be able to save a lot of time by setting `check_valid=false`.  Be aware that
//   disabling the validity check when it is needed can generate invalid polyhedra that produce CGAL errors upon
//   rendering.  Such validity errors also occur if you specify a self-intersecting shape.
//   The offset profile is quantized to 1/1024 steps to avoid failures in offset() that can occur with tiny offsets.
//   .
//   The build-in profiles are: circular rounding, teardrop rounding, continuous curvature rounding, and chamfer.
//   Also, when a rounding radius is negative, the rounding flares outward.  The easiest way to specify
//   the profile is by using the profile helper functions.  These functions take profile parameters, as well as some
//   general settings and translate them into a profile specification, with error checking on your input.  The description below
//   describes the helper functions and the parameters specific to each function.  Below that is a description of the generic
//   settings that you can optionally use with all of the helper functions.  For more details on the "cut" and "joint" rounding parameters, and
//   on continuous curvature rounding, see [Types of Roundover](rounding.scad#subsection-types-of-roundover). 
//   .
//   - profile: os_profile(points)
//     Define the offset profile with a list of points.  The first point must be [0,0] and the roundover should rise in the positive y direction, with positive x values for inward motion (standard roundover) and negative x values for flaring outward.  If the y value ever decreases then you might create a self-intersecting polyhedron, which is invalid.  Such invalid polyhedra create cryptic assertion errors when you render your model and it is your responsibility to avoid creating them.  Note that the starting point of the profile is the center of the extrusion.  If you use a profile as the top, it rises upward.  If you use it as the bottom, it is inverted and goes downward.
//   - circle: os_circle(r|cut=,height=|h=,[clip_angle=],).  Define circular rounding or clipped circle rounding.  You specify a full circle rounding by giving the radius, cut distance or height (which is equivalent to radius in this case).  For a clipped circle rounding you can use two methods.  You can specify the clip angle and then give a radius, cut, or height.  (The cut distance in this case is the usual cut for a full circular arc.)  Alternatively you can give a height and radius (or cut) and the appropriate clip angle is chosen for you.  
//   - smooth: os_smooth(cut|joint, [k]).  Define continuous curvature rounding, with `cut` and `joint` as for round_corners. The k parameter controls how fast the curvature changes and should be between 0 and 1.  
//   - teardrop: os_teardrop(r|cut).  Rounding using a 1/8 circle that then changes to a 45 degree chamfer.  The chamfer is at the end, and enables the object to be 3d printed without support.  The radius gives the radius of the circular part.
//   - chamfer: os_chamfer([height], [width], [cut], [angle]).  Chamfer the edge at desired angle or with desired height and width.  You can specify height and width together and the angle is ignored, or specify just one of height and width and the angle is used to determine the shape.  Alternatively, specify "cut" along with angle to specify the cut back distance of the chamfer.
//   - mask: os_mask(mask, [out]).  Create a profile from one of the [2d masking shapes](masks2d.scad#section-2d-masking-shapes).  The `out` parameter specifies that the mask should flare outward (like crown molding or baseboard).  This is set false by default.  
//   .
//   The general settings that you can use with all of the helper functions are mostly used to control how offset_sweep() calls the offset() function.
//   - extra: Add an extra vertical step of the specified height, to be used for intersections or differences.  This extra step extends the resulting object beyond the height you specify.  It is ignored by anchoring.  Default: 0
//   - check_valid: passed to offset().  Default: true
//   - quality: passed to offset().  Default: 1
//   - steps: Number of vertical steps to use for the profile.  (Not used by os_profile).  Default: 16
//   - offset: Select "round" (r=) or "delta" (delta=) offset types for offset. You can also choose "chamfer" but this leads to exponential growth in the number of vertices with the steps parameter.  Default: "round"
//   .
//   Many of the arguments are described as setting "default" values because they establish settings which may be overridden by
//   the top and bottom profile specifications.
//   .
//   You should use the above helper functions to generate the profiles.
//   The profile specification is a list of pairs of keywords and values, e.g. ["for","offset_sweep","r",12, type, "circle"]. The keywords are
//   - "for" - must appear first in the list and have the value "offset_sweep"
//   - "type" - type of rounding to apply, one of "circle", "teardrop", "chamfer", "smooth", or "profile" (Default: "circle")
//   - "r" - the radius of the roundover, which may be zero for no roundover, or negative to round or flare outward.  Default: 0
//   - "cut" - the cut distance for the roundover or chamfer, which may be negative for flares
//   - "chamfer_width" - the width of a chamfer
//   - "chamfer_height" - the height of a chamfer
//   - "angle" - the chamfer angle, measured from the vertical (so zero is vertical, 90 is horizontal).  Default: 45
//   - "joint" - the joint distance for a "smooth" roundover
//   - "k" - the curvature smoothness parameter for "smooth" roundovers, a value in [0,1].  Default: 0.75
//   - "points" - point list for use with the "profile" type
//   - "extra" - extra height added for unions/differences.  This makes the shape taller than the requested height.  (Default: 0)
//   - "check_valid" - passed to offset.  Default: true.
//   - "quality" - passed to offset.  Default: 1.
//   - "steps" - number of vertical steps to use for the roundover.  Default: 16.
//   - "offset" - select "round" (r=), "delta" (delta=), or "chamfer" offset type for offset.  Default: "round"
//   .
//   Note that if you set the "offset" parameter to "chamfer" then every exterior corner turns from one vertex into two vertices with
//   each offset operation.  Since the offsets are done one after another, each on the output of the previous one, this leads to
//   exponential growth in the number of vertices.  This can lead to long run times or yield models that
//   run out of recursion depth and give a cryptic error.  Furthermore, the generated vertices are distributed non-uniformly.  Generally you
//   get a similar or better looking model with fewer vertices using "round" instead of
//   "chamfer".  Use the "chamfer" style offset only in cases where the number of steps is small or just one (such as when using
//   the `os_chamfer` profile type).
//   .
//   The module form only can support a region as input.  You can provide different profiles for the cutouts in a region using the `bottom_hole`, `top_hole`
//   or `ends_hole` parameters.  
//   .
//   This module offers four anchor types.  The default is "hull" in which VNF anchors are placed on the VNF of the **unrounded** object.  You
//   can also use "intersect" to get the intersection anchors to the unrounded object. If you prefer anchors that respect the rounding
//   then use "surf_hull" or "intersect_hull". 
// Arguments:
//   path = 2d path (list of points) to extrude or a region for the module form
//   height / length / l / h = total height (including rounded portions, but not extra sections) of the output.  Default: combined height of top and bottom end treatments.
//   bottom / bot = rounding spec for the bottom end
//   top = rounding spec for the top end.
//   ---
//   ends = give a rounding spec that applies to both the top and bottom
//   offset = default offset, `"round"` or `"delta"`.  Default: `"round"`
//   steps = default step count.  Default: 16
//   quality = default quality.  Default: 1
//   check_valid = default check_valid.  Default: true.
//   extra = default extra height.  Default: 0
//   caps = if false do not create end faces.  Can be a boolean vector to control ends independent.  (function only) Default: true. 
//   cut = default cut value.
//   chamfer_width = default width value for chamfers.
//   chamfer_height = default height value for chamfers.
//   angle = default angle for chamfers.  Default: 45
//   joint = default joint value for smooth roundover.
//   k = default curvature parameter value for "smooth" roundover
//   ends_hole = (module only) rounding spec that applies to top and bottom of holes in a region
//   bot_hole / bottom_hole = (module only) rounding spec for bottom end of holes in a region
//   top_hole = (module only) rounding spec for top end of holes in a region
//   convexity = convexity setting for use with polyhedron.  (module only) Default: 10
//   anchor = Translate so anchor point is at the origin.  Default: "base"
//   spin = Rotate this many degrees around Z axis after anchor.  Default: 0
//   orient = Vector to rotate top toward after spin  
//   atype = Select "hull", "intersect", "surf_hull" or "surf_intersect" anchor types.  Default: "hull"
//   cp = Centerpoint for determining "intersect" anchors or centering the shape.  Determintes the base of the anchor vector.  Can be "centroid", "mean", "box" or a 3D point.  Default: "centroid"
// Anchor Types:
//   "hull" = Anchors to the convex hull of the linear sweep of the path, ignoring any end roundings.  (default)
//   "intersect" = Anchors to the surface of the linear sweep of the path, ignoring any end roundings.
//   "surf_hull" = Anchors to the convex hull of the offset_sweep shape, including end treatments.
//   "surf_intersect" = Anchors to the surface of the offset_sweep shape, including any end treatments.
// Named Anchors:
//   "base" = Anchor to the base of the shape in its native position, ignoring any "extra"
//   "top" = Anchor to the top of the shape in its native position, ignoring any "extra"
//   "zcenter" = Center shape in the Z direction in the native XY position, ignoring any "extra"
// Example: Rounding a star shaped prism with postive radius values
//   star = star(5, r=22, ir=13);
//   rounded_star = round_corners(star, cut=flatten(repeat([.5,0],5)), $fn=24);
//   offset_sweep(rounded_star, height=20, bottom=os_circle(r=4), top=os_circle(r=1), steps=15);
// Example: Rounding a star shaped prism with negative radius values.  The starting shape has no corners, so the value of `$fn` does not matter.
//   star = star(5, r=22, ir=13); 
//   rounded_star = round_corners(star, cut=flatten(repeat([.5,0],5)), $fn=36);
//   offset_sweep(rounded_star, height=20, bottom=os_circle(r=-4), top=os_circle(r=-1), steps=15);
// Example: If the shape has sharp corners, make sure to set `$fn/$fs/$fa`.  The corners of this triangle are not round, even though `offset="round"` (the default) because the number of segments is small.
//   triangle = [[0,0],[10,0],[5,10]];
//   offset_sweep(triangle, height=6, bottom = os_circle(r=-2),steps=4);
// Example: Can improve the result by increasing `$fn`
//   $fn=12;
//   triangle = [[0,0],[10,0],[5,10]];
//   offset_sweep(triangle, height=6, bottom = os_circle(r=-2),steps=4);
// Example: Using `$fa` and `$fs` works too; it produces a different looking triangulation of the rounded corner
//   $fa=1;$fs=0.3;
//   triangle = [[0,0],[10,0],[5,10]];
//   offset_sweep(triangle, height=6, bottom = os_circle(r=-2),steps=4);
// Example: Here is the star chamfered at the top with a teardrop rounding at the bottom. Check out the rounded corners on the chamfer.  The large `$fn` value ensures a smooth curve on the concave corners of the chamfer.  It has no effect anywhere else on the model.  Observe how the rounded star points vanish at the bottom in the teardrop: the number of vertices does not remain constant from layer to layer.
//    star = star(5, r=22, ir=13);
//    rounded_star = round_corners(star, cut=flatten(repeat([.5,0],5)), $fn=24);
//    offset_sweep(rounded_star, height=20, bottom=os_teardrop(r=4), top=os_chamfer(width=4),$fn=64);
// Example(3D,NoAxes,VPR=[99.80,0.00,62.10],VPD=155.56,VPT=[-2.78,0.61,14.66]): Clipped circle rounding on the bottom (for 3d printability and regular circular rounding on the top, both with the same radius.  The clipped circle rounding takes up less vertical space.  
//   $fn=64;
//   offset_sweep(rect(50,rounding=6), h=30,bot=os_circle(r=6, clip_angle=50), top=os_circle(r=6));
// Example(3D,NoAxes,VPR=[99.80,0.00,62.10],VPD=155.56,VPT=[-2.78,0.61,14.66]): The same as the previous example but with roundings specified by height.  This means that they have different radii, but the height maches.  
//   $fn=64;
//   offset_sweep(rect(50,rounding=6), h=30,bot=os_circle(h=6, clip_angle=50), top=os_circle(h=6));
// Example: We round a cube using the continous curvature rounding profile.  But note that the corners are not smooth because the curved square collapses into a square with corners.    When a collapse like this occurs, we cannot turn `check_valid` off.  For a better result use {{rounded_prism()}} instead.
//   square = square(1);
//   rsquare = round_corners(square, method="smooth", cut=0.1, k=0.7, $fn=36);
//   end_spec = os_smooth(cut=0.1, k=0.7, steps=22);
//   offset_sweep(rsquare, height=1, bottom=end_spec, top=end_spec);
// Example(3D,Med): A nice rounded box, with a teardrop base and circular rounded interior and top
//   box = square([255,50]);
//   rbox = round_corners(box, method="smooth", cut=4, $fn=12);
//   thickness = 2;
//   difference(){
//     offset_sweep(rbox, height=50, check_valid=false, steps=22,
//                  bottom=os_teardrop(r=2), top=os_circle(r=1));
//     up(thickness)
//       offset_sweep(offset(rbox, r=-thickness, closed=true,check_valid=false),
//                    height=48, steps=22, check_valid=false,
//                    bottom=os_circle(r=4), top=os_circle(r=-1,extra=1));
//   }
// Example: This box is much thicker, and cut in half to show the profiles.  Note also that we can turn `check_valid` off for the outside and for the top inside, but not for the bottom inside.  This example shows use of the direct keyword syntax without the helper functions.
//   smallbox = square([75,50]);
//   roundbox = round_corners(smallbox, method="smooth", cut=4, $fn=12);
//   thickness=4;
//   height=50;
//   back_half(y=25, s=200)
//     difference(){
//       offset_sweep(roundbox, height=height, bottom=["for","offset_sweep","r",10,"type","teardrop"],
//                                             top=["for","offset_sweep","r",2], steps = 22, check_valid=false);
//       up(thickness)
//         offset_sweep(offset(roundbox, r=-thickness, closed=true),
//                       height=height-thickness, steps=22,
//                       bottom=["for","offset_sweep","r",6],
//                       top=["for","offset_sweep","type","chamfer","angle",30,
//                            "chamfer_height",-3,"extra",1,"check_valid",false]);
//   }
// Example(3D,Med): A box with multiple sections and rounded dividers
//   thickness = 2;
//   box = square([255,50]);
//   cutpoints = [0, 125, 190, 255];
//   rbox = round_corners(box, method="smooth", cut=4, $fn=12);
//   back_half(y=25, s=700)
//     difference(){
//       offset_sweep(rbox, height=50, check_valid=false, steps=22,
//                    bottom=os_teardrop(r=2), top=os_circle(r=1));
//       up(thickness)
//         for(i=[0:2]){
//           ofs = i==1 ? 2 : 0;
//           hole = round_corners([[cutpoints[i]-ofs,0], [cutpoints[i]-ofs,50],
//                                 [cutpoints[i+1]+ofs, 50], [cutpoints[i+1]+ofs,0]],
//                                method="smooth", cut=4, $fn=36);
//           offset_sweep(offset(hole, r=-thickness, closed=true,check_valid=false),
//                         height=48, steps=22, check_valid=false,
//                         bottom=os_circle(r=4), top=os_circle(r=-1,extra=1));
//         }
//     }
// Example(3D,Med): Star shaped box
//   star = star(5, r=22, ir=13);
//   rounded_star = round_corners(star, cut=flatten(repeat([.5,0],5)), $fn=24);
//   thickness = 2;
//   ht=20;
//   difference(){
//     offset_sweep(rounded_star, height=ht, bottom=["for","offset_sweep","r",4],
//                                           top=["for","offset_sweep","r",1], steps=15);
//     up(thickness)
//         offset_sweep(offset(rounded_star,r=-thickness,closed=true),
//                       height=ht-thickness, check_valid=false,
//                       bottom=os_circle(r=7), top=os_circle(r=-1, extra=1),$fn=40);
//     }
// Example: A profile defined by an arbitrary sequence of points.
//   star = star(5, r=22, ir=13);
//   rounded_star = round_corners(star, cut=flatten(repeat([.5,0],5)), $fn=24);
//   profile = os_profile(points=[[0,0],[.3,.1],[.6,.3],[.9,.9], [1.2, 2.7],[.8,2.7],[.8,3]]);
//   offset_sweep(reverse(rounded_star), height=20, top=profile, bottom=profile, $fn=32);
// Example: Parabolic rounding
//   star = star(5, r=22, ir=13);
//   rounded_star = round_corners(star, cut=flatten(repeat([.5,0],5)), $fn=24);
//   offset_sweep(rounded_star, height=20, top=os_profile(points=[for(r=[0:.1:2])[sqr(r),r]]),
//                                          bottom=os_profile(points=[for(r=[0:.2:5])[-sqrt(r),r]]),$fn=32);
// Example: This example uses a sine wave offset profile.  Note that we give no specification for the bottom, so it is straight.
//   sq = [[0,0],[20,0],[20,20],[0,20]];
//   sinwave = os_profile(points=[for(theta=[0:5:720]) [4*sin(theta), theta/700*15]]);
//   offset_sweep(sq, height=20, top=sinwave, $fn=32);
// Example: The same as the previous example but `offset="delta"`
//   sq = [[0,0],[20,0],[20,20],[0,20]];
//   sinwave = os_profile(points=[for(theta=[0:5:720]) [4*sin(theta), theta/700*15]]);
//   offset_sweep(sq, height=20, top=sinwave, offset="delta");
// Example(3D,NoAxes,VPR=[59.20,0.00,24.80],VPD=54.24,VPT=[-4.12,10.66,0.96]): a box with a flared top.  A nice roundover on the top requires a profile edge, but we can use "extra" to create a small chamfer.
//   rhex = round_corners(hexagon(side=10), method="smooth", joint=2, $fs=0.2);
//   back_half()
//     difference(){
//       offset_sweep(rhex, height=10, bottom=os_teardrop(r=2), top=os_teardrop(r=-4, extra=0.2));
//       up(1)
//         offset_sweep(offset(rhex,r=-1), height=9.5, bottom=os_circle(r=2), top=os_teardrop(r=-4));
//     }
// Example(3D,NoAxes,VPR=[53.60,0.00,190.20],VPD=1036.38,VPT=[6.09,5.67,59.25]): Using os_mask to create ogee profiles:
//   ogee = mask2d_ogee([
//       "xstep",3,  "ystep",3,  // Starting shoulder.
//       "fillet",15, "round",15,  // S-curve.
//       "ystep",3,              // Ending shoulder.
//   ]);
//   star = star(5, r=220, ir=130);
//   rounded_star = round_corners(star, cut=flatten(repeat([5,0],5)), $fn=24);
//   offset_sweep(rounded_star, height=150, top=os_mask(ogee), bottom=os_mask(ogee,out=true));
// Example(3D,NoAxes): Applying to a region, with different profiles for the outside in inside curves.  
//   $fn = 32;
//   rgn = difference(
//       [
//           rect(50, rounding=5),
//           move([15,15], circle(d=10)),
//           move([-15,-15], circle(d=10)),
//           move([0,25], rect([10,7],anchor=BACK,
//                             rounding=[-2,-2,2,2])),
//           zrot(55, square([4, 100], center=true)),
//           ellipse([12,4])
//       ]
//   );
//   offset_sweep(rgn, height=12, steps=6, ends_hole=os_chamfer(width=2),
//                                         ends=os_circle(r=1.7));


module _offset_sweep_region(region, height, 
                    bottom, top, 
                    h, l, length, ends, bot, top_hole, bot_hole, bottom_hole, ends_hole, 
                    offset="round", r=0, steps=16,
                    quality=1, check_valid=true,
                    extra=0,
                    cut=undef, chamfer_width=undef, chamfer_height=undef,
                    joint=undef, k=0.75, angle=45,
                    convexity=10,anchor="base",cp="centroid",
                    spin=0, orient=UP, atype="hull")
{
    connected_reg = region_parts(region);
    vnf_h_list = [for(reg=connected_reg)
                    offset_sweep(path=reg[0], height=height, h=h, l=l, length=length, bot=bot, top=top, bottom=bottom, ends=ends,
                                 offset=offset, r=r, steps=steps,
                                 quality=quality, check_valid=check_valid, extra=extra, cut=cut, chamfer_width=chamfer_width,
                                 chamfer_height=chamfer_height, joint=joint, k=k, angle=angle, _return_height=true)];
    vnf_list = column(vnf_h_list,0);
    height = vnf_h_list[0][1];

    holes = [for(reg=connected_reg, i=[1:1:len(reg)-1]) reg[i]];

    anchors = [
          named_anchor("zcenter", [0,0,0], UP),
          named_anchor("base", [0,0,-height/2], UP),
          named_anchor("top", [0,0,height/2], UP)          
        ];
    bottom_hole=first_defined([bottom_hole, bot_hole, ends_hole, bottom, ends]);
    top_hole = first_defined([top_hole,ends_hole,top,ends]);
    if (in_list(atype,["hull","intersect"]))
        attachable(anchor,spin,orient,region=region,h=height,cp=cp,anchors=anchors,extent=atype=="hull"){
            down(height/2)
              difference(){
                 for(vnf=vnf_list)
                     polyhedron(vnf[0],vnf[1],convexity=convexity);
                 for(path=holes)
                     offset_sweep(path=path, height=height, h=h, l=l, length=length, bot=bot, top=top_hole, bottom=bottom_hole, 
                                  offset=offset, r=r, steps=steps,
                                  quality=quality, check_valid=check_valid, extra=extra+0.1, cut=cut, chamfer_width=chamfer_width,
                                  chamfer_height=chamfer_height, joint=joint, k=k, angle=angle, _flipdir=true,convexity=convexity);
              }
            children();
        }
    else {
        allvnf=vnf_join(vnf_list);
        attachable(anchor,spin.orient,vnf=allvnf, cp=cp,anchors=anchors, extent = atype=="surf_hull"){
              difference(){
                 for(vnf=vnf_list)
                     vnf_polyhedron(vnf,convexity=convexity);
                 for(path=holes)
                     offset_sweep(path=path, height=height, h=h, l=l, length=length, bot=bot, top=top_hole, bottom=bottom_hole, 
                                  offset=offset, r=r, steps=steps,
                                  quality=quality, check_valid=check_valid, extra=extra+0.1, cut=cut, chamfer_width=chamfer_width,
                                  chamfer_height=chamfer_height, joint=joint, k=k, angle=angle, _flipdir=true,convexity=convexity);
              }
            children();
        }
    }
}   




// This function does the actual work of repeatedly calling offset() and concatenating the resulting face and vertex lists to produce
// the inputs for the polyhedron module.
function _make_offset_polyhedron(path,offsets, offset_type, flip_faces, quality, check_valid, cap=true,
                                 offsetind=0, vertexcount=0, vertices=[], faces=[] )=
    offsetind==len(offsets)? 
        let(
            bottom = count(len(path),vertexcount),
            oriented_bottom = !flip_faces? bottom : reverse(bottom)
        )
        [
         vertices,
         [each faces,
          if (cap) oriented_bottom]
        ]
  :
        let(
            this_offset = offsetind==0? offsets[0][0] : offsets[offsetind][0] - offsets[offsetind-1][0],
            delta = offset_type=="delta" || offset_type=="chamfer" ? this_offset : undef,
            r = offset_type=="round"? this_offset : undef,
            do_chamfer = offset_type == "chamfer",
            vertices_faces = offset(
                    path, r=r, delta=delta, chamfer = do_chamfer, closed=true,
                    check_valid=check_valid, quality=quality,
                    return_faces=true,
                    firstface_index=vertexcount,
                    flip_faces=flip_faces
            )
        )
        _make_offset_polyhedron(
                vertices_faces[0], offsets, offset_type,
                flip_faces, quality, check_valid, cap, 
                offsetind+1, vertexcount+len(path),
                vertices=concat(
                        vertices,
                        path3d(vertices_faces[0],offsets[offsetind][1])
                ),
                faces=concat(faces, vertices_faces[1])
        );  


function _struct_valid(spec, func, name) =
        spec==[] ? true :
        assert(is_list(spec) && len(spec)>=2 && spec[0]=="for",str("Specification for \"", name, "\" is an invalid structure"))
        assert(spec[1]==func, str("Specification for \"",name,"\" is for a different function (",func,")"));

function offset_sweep(
                       path, height, 
                       bottom, top, 
                       h, l, length,
                       ends,bot,
                       offset="round", r=0, steps=16,
                       quality=1, check_valid=true,
                       extra=0, caps=true, 
                       cut=undef, chamfer_width=undef, chamfer_height=undef,
                       joint=undef, k=0.75, angle=45, anchor="base", orient=UP, spin=0,atype="hull", cp="centroid",
                       _return_height=false, _flipdir=false
                      ) =
    let(
        argspec = [
                   ["for",""],
                   ["r",r],
                   ["extra",extra],
                   ["type","circle"],
                   ["check_valid",check_valid],
                   ["quality",quality],
                   ["steps",steps],
                   ["offset",offset],
                   ["chamfer_width",chamfer_width],
                   ["chamfer_height",chamfer_height],
                   ["angle",angle],
                   ["cut",cut],
                   ["joint",joint],
                   ["k", k],
                   ["points", []],
        ],
        path = force_path(path)
    )
    assert(is_path(path,2), "Input path must be a 2D path")
    assert(is_bool(caps) || is_bool_list(caps,2), "caps must be boolean or a list of two booleans")
    let(
        caps = is_bool(caps) ? [caps,caps] : caps, 
        clockwise = is_polygon_clockwise(path),
        top_temp = one_defined([ends,top],"ends,top",dflt=[]),
        bottom_temp = one_defined([ends,bottom,bot],"ends,bottom,bot",dflt=[]),
        dummy1 = _struct_valid(top_temp,"offset_sweep","top"),
        dummy2 = _struct_valid(bottom_temp,"offset_sweep","bottom"),
        top = struct_set(argspec, top_temp, grow=false),
        bottom = struct_set(argspec, bottom_temp, grow=false),
        offsetsok = in_list(struct_val(top, "offset"),["round","delta","chamfer"])
                    && in_list(struct_val(bottom, "offset"),["round","delta","chamfer"])
    )
    assert(offsetsok,"Offsets must be one of \"round\", \"delta\", or \"chamfer\"")
    let(
        do_flip = _flipdir ? function(x) xflip(x) : function(x) x , 
        offsets_bot = do_flip(_rounding_offsets(bottom, -1)),
        offsets_top = do_flip(_rounding_offsets(top, 1)),
        dummy = (struct_val(top,"offset")=="chamfer" && len(offsets_top)>5)
                        || (struct_val(bottom,"offset")=="chamfer" && len(offsets_bot)>5)
                ? echo("WARNING: You have selected offset=\"chamfer\", which leads to exponential growth in the vertex count and requested more than 5 layers.  This can be slow or run out of recursion depth.")
                : 0,

        // "Extra" height enlarges the result beyond the requested height, so subtract it
        bottom_height = len(offsets_bot)==0 ? 0 : abs(last(offsets_bot)[1]) - struct_val(bottom,"extra"),
        top_height = len(offsets_top)==0 ? 0 : abs(last(offsets_top)[1]) - struct_val(top,"extra"),

        height = one_defined([l,h,height,length], "l,h,height,length", dflt=u_add(bottom_height,top_height)),
        dummy1 = assert(is_finite(height) && height>0, "Height must be positive"),
        middle = height-bottom_height-top_height,
        dummy2= assert(middle>=0, str("Specified end treatments (bottom height = ",bottom_height,
                                      " top_height = ",top_height,") are too large for extrusion height (",height,")")),
        initial_vertices_bot = path3d(path),

        vertices_faces_bot = _make_offset_polyhedron(
                path, offsets_bot, struct_val(bottom,"offset"), clockwise,
                struct_val(bottom,"quality"),
                struct_val(bottom,"check_valid"),
                caps[0], 
                vertices=initial_vertices_bot
        ),

        top_start_ind = len(vertices_faces_bot[0]),
        initial_vertices_top = path3d(path, middle),
        vertices_faces_top = _make_offset_polyhedron(
                path, move(p=offsets_top,[0,middle]),
                struct_val(top,"offset"), !clockwise,
                struct_val(top,"quality"),
                struct_val(top,"check_valid"),
                caps[1],
                vertexcount=top_start_ind,
                vertices=initial_vertices_top
        ),
        middle_faces = middle==0 ? [] : [
                for(i=[0:len(path)-1]) let(
                        oneface=[i, (i+1)%len(path), top_start_ind+(i+1)%len(path), top_start_ind+i]
                ) !clockwise ? reverse(oneface) : oneface
        ],
        vnf = [up(bottom_height-height/2, concat(vertices_faces_bot[0],vertices_faces_top[0])),  // Vertices
               concat(vertices_faces_bot[1], vertices_faces_top[1], middle_faces)],     // Faces
        anchors = [
          named_anchor("zcenter", [0,0,0], UP),
          named_anchor("base", [0,0,-height/2], UP),
          named_anchor("top", [0,0,height/2], UP)          
        ],
        final_vnf = in_list(atype,["hull","intersect"])
                  ? reorient(anchor,spin,orient, path=path, h=height, extent=atype=="hull", cp=cp, p=vnf, anchors=anchors)
                  : reorient(anchor,spin,orient, vnf=vnf, p=vnf, extent=atype=="surf_hull", cp=cp, anchors=anchors)
     ) _return_height ? [final_vnf,height] : final_vnf;


module offset_sweep(path, height, 
                    bottom, top, 
                    h, l, length, ends, bot,
                    offset="round", r=0, steps=16,
                    quality=1, check_valid=true,
                    extra=0, top_hole, bot_hole, bottom_hole, ends_hole,
                    cut=undef, chamfer_width=undef, chamfer_height=undef,
                    joint=undef, k=0.75, angle=45,
                    convexity=10,anchor="base",cp="centroid",
                    spin=0, orient=UP, atype="hull", _flipdir)
{
    assert(in_list(atype, ["intersect","hull","surf_hull","surf_intersect"]), "Anchor type must be \"hull\" or \"intersect\"");
    if (is_region(path) && len(path)>1)
       _offset_sweep_region(region=path, height=height, bottom=bottom, top=top, h=h, l=l, length=length, ends=ends, bot=bot,
                            offset=offset, r=r, steps=steps, quality=quality, check_valid=check_valid, extra=extra,
                            cut=cut, chamfer_width=chamfer_width, chamfer_height=chamfer_height, joint=joint, k=k, angle=angle,
                            bot_hole=bot_hole,top_hole=top_hole,bottom_hole=bottom_hole,ends_hole=ends_hole,
                            convexity=convexity, anchor=anchor, cp=cp, spin=spin, orient=orient, atype=atype) children();
    else {
        vnf_h = offset_sweep(path=path, height=height, h=h, l=l, length=length, bot=bot, top=top, bottom=bottom, ends=ends,
                             offset=offset, r=r, steps=steps,
                             quality=quality, check_valid=check_valid, extra=extra, cut=cut, chamfer_width=chamfer_width,
                             chamfer_height=chamfer_height, joint=joint, k=k, angle=angle, _return_height=true, _flipdir=_flipdir);
        vnf = vnf_h[0];
        height = vnf_h[1];
        anchors = [
              named_anchor("zcenter", [0,0,0], UP),
              named_anchor("base", [0,0,-height/2], UP),
              named_anchor("top", [0,0,height/2], UP)          
            ];
        if (in_list(atype,["hull","intersect"]))
            attachable(anchor,spin,orient,region=force_region(path),h=height,cp=cp,anchors=anchors,extent=atype=="hull"){
                down(height/2)polyhedron(vnf[0],vnf[1],convexity=convexity);
                children();
            }
        else
            attachable(anchor,spin.orient,vnf=vnf, cp=cp,anchors=anchors, extent = atype=="surf_hull"){
                vnf_polyhedron(vnf,convexity=convexity);
                children();
            }
    }
}   


function os_circle(r,cut,h,height,clip_angle,extra,check_valid, quality,steps, offset) =
        assert(is_undef(clip_angle) || is_finite(clip_angle) && clip_angle>0 && clip_angle<=90, "clip angle must a number be in the interval (0,90]")
        let(
             h = one_defined([h,height],"h,height",dflt=undef),
             r_ang = is_def(clip_angle) ?
                         assert(num_defined([r,h,cut])==1, "When clip_angle is given must give exactly one of r, h/height, or cut")
                           is_def(r) ? [r,clip_angle]
                         : is_def(cut) ? [cut/(sqrt(2)-1),clip_angle]
                         : [h / sin(clip_angle),clip_angle]
                   :
                         assert(num_defined([r,cut])<=1, "Cannot give both r and cut")
                         let(
                              r = is_def(r) ? r
                                : is_def(cut) ?  cut/(sqrt(2)-1)
                                : undef
                         )
                         is_def(r) ? [r, is_def(h) ? assert(h<=r, "height cannot be larger than radius") asin(h/r) : 90]
                                   : [h, 90]
        )
        _remove_undefined_vals([
                "for", "offset_sweep",
                "type", "circle",
                "r",r_ang[0],
                "angle",r_ang[1],
                "extra",extra,
                "check_valid",check_valid,
                "quality", quality,
                "steps", steps,
                "offset", offset
        ]);


function os_teardrop(r,cut,extra,check_valid, quality,steps, offset) =
        assert(num_defined([r,cut])==1, "Must define exactly one of `r` and `cut`")
        _remove_undefined_vals([
                "for", "offset_sweep",
                "type", "teardrop",
                "r",r,
                "cut",cut,
                "extra",extra,
                "check_valid",check_valid,
                "quality", quality,
                "steps", steps,
                "offset", offset
        ]);

function os_chamfer(height, width, cut, angle, extra,check_valid, quality,steps, offset) =
        let(ok = (is_def(cut) && num_defined([height,width])==0) || num_defined([height,width])>0)
        assert(ok, "Must define `cut`, or one or both of `width` and `height`")
        _remove_undefined_vals([
                "for", "offset_sweep",
                "type", "chamfer",
                "chamfer_width",width,
                "chamfer_height",height,
                "cut",cut,
                "angle",angle,
                "extra",extra,
                "check_valid",check_valid,
                "quality", quality,
                "steps", steps,
                "offset", offset
        ]);

function os_smooth(cut, joint, k, extra,check_valid, quality,steps, offset) =
        assert(num_defined([joint,cut])==1, "Must define exactly one of `joint` and `cut`")
        _remove_undefined_vals([
                "for", "offset_sweep",
                "type", "smooth",
                "joint",joint,
                "k",k,
                "cut",cut,
                "extra",extra,
                "check_valid",check_valid,
                "quality", quality,
                "steps", steps,
                "offset", offset
        ]);

function os_profile(points, extra,check_valid, quality, offset) =
        assert(is_path(points),"Profile point list is not valid")
        _remove_undefined_vals([
                "for", "offset_sweep",
                "type", "profile",
                "points", points,
                "extra",extra,
                "check_valid",check_valid,
                "quality", quality,
                "offset", offset
        ]);


function os_mask(mask, out=false, extra,check_valid, quality, offset) =
  let(
      origin_index = [for(i=idx(mask)) if (mask[i].x<0 && mask[i].y<0) i],
      xfactor = out ? -1 : 1
  )
  assert(len(origin_index)==1,"Cannot find origin in the mask")
  let(
      points = ([for(pt=list_rotate(mask,origin_index[0])) [xfactor*max(pt.x,0),-max(pt.y,0)]])
  )
  os_profile(deduplicate(move(-points[1],p=list_tail(points))), extra,check_valid,quality,offset);


// Module: convex_offset_extrude()
// Synopsis: Make a solid from geometry where offset changes along the object's length.
// SynTags: Geom
// Topics: Rounding, Offsets
// See Also: offset_sweep(), rounded_prism(), bent_cutout_mask(), join_prism(), linear_sweep()
// Usage: Basic usage.  See below for full options
//   convex_offset_extrude(height, [bottom], [top], ...) 2D-CHILDREN;
// Description:
//   Extrudes 2d children with layers formed from the convex hull of the offset of each child according to a sequence of offset values.
//   Like `offset_sweep` this module can use built-in offset profiles to provide treatments such as roundovers or chamfers but unlike `offset_sweep()` it
//   operates on 2d children rather than a point list.  Each offset is computed using
//   the native `offset()` module from the input geometry.
//   If your shape has corners that you want rounded by offset be sure to set `$fn` or `$fs` appropriately.
//   If your geometry has internal holes or is too small for the specified offset then you may get
//   unexpected results.
//   .
//   The build-in profiles are: circular rounding, teardrop rounding, continuous curvature rounding, and chamfer.
//   Also, when a rounding radius is negative, the rounding flares outward.  The easiest way to specify
//   the profile is by using the profile helper functions.  These functions take profile parameters, as well as some
//   general settings and translate them into a profile specification, with error checking on your input.  The description below
//   describes the helper functions and the parameters specific to each function.  Below that is a description of the generic
//   settings that you can optionally use with all of the helper functions.
//   For more details on the "cut" and "joint" rounding parameters, and
//   on continuous curvature rounding, see [Types of Roundover](rounding.scad#subsection-types-of-roundover). 
//   .
//   The final shape is created by combining convex hulls of small extrusions.  The thickness of these small extrusions may result
//   your model being slightly too long (if the curvature at the end is flaring outward), so if the exact length is important,
//   you may need to intersect with a bounding cube.  (Note that extra length can also be intentionally added with the `extra` argument.)
//   .
//   - profile: os_profile(points)
//     Define the offset profile with a list of points.  The first point must be [0,0] and the roundover should rise in the positive y direction, with positive x values for inward motion (standard roundover) and negative x values for flaring outward.  If the y value ever decreases then you might create a self-intersecting polyhedron, which is invalid.  Such invalid polyhedra create cryptic assertion errors when you render your model and it is your responsibility to avoid creating them.  Note that the starting point of the profile is the center of the extrusion.  If you use a profile as the top, it rises upward. If you use it as the bottom, it is inverted and goes downward.
//   - circle: os_circle(r|cut=,height=|h=,[clip_angle=],).  Define circular rounding or clipped circle rounding.  You specify a full circle rounding by giving the radius, cut distance or height (which is equivalent to radius in this case).  For a clipped circle rounding you can use two methods.  You can specify the clip angle and then give a radius, cut, or height.  (The cut distance in this case is the usual cut for a full circular arc.)  Alternatively you can give a height and radius (or cut) and the appropriate clip angle is chosen for you.  
//   - smooth: os_smooth(cut|joint, [k]).  Define continuous curvature rounding, with `cut` and `joint` as for round_corners.  The k parameter controls how fast the curvature changes and should be between 0 and 1.
//   - teardrop: os_teardrop(r|cut).  Rounding using a 1/8 circle that then changes to a 45 degree chamfer.  The chamfer is at the end, and enables the object to be 3d printed without support.  The radius gives the radius of the circular part.
//   - chamfer: os_chamfer([height], [width], [cut], [angle]).  Chamfer the edge at desired angle or with desired height and width.  You can specify height and width together and the angle is ignored, or specify just one of height and width and the angle is used to determine the shape.  Alternatively, specify "cut" along with angle to specify the cut back distance of the chamfer.
//   .
//   The general settings that you can use with all of the helper functions are mostly used to control how offset_sweep() calls the offset() function.
//   - extra: Add an extra vertical step of the specified height, to be used for intersections or differences.  This extra step extends the resulting object beyond the height you specify.  Default: 0
//   - steps: Number of vertical steps to use for the profile.  (Not used by os_profile).  Default: 16
//   - offset: Select "round" (r=), "delta" (delta=), or "chamfer" offset types for offset.  Default: "round"
//   .
//   Many of the arguments are described as setting "default" values because they establish settings which may be overridden by
//   the top and bottom profile specifications.
//   .
//   You should use the above helper functions to generate the profiles.
//   The profile specification is a list of pairs of keywords and values, e.g. ["r",12, type, "circle"]. The keywords are
//   - "type" - type of rounding to apply, one of "circle", "teardrop", "chamfer", "smooth", or "profile" (Default: "circle")
//   - "r" - the radius of the roundover, which may be zero for no roundover, or negative to round or flare outward.  Default: 0
//   - "cut" - the cut distance for the roundover or chamfer, which may be negative for flares
//   - "chamfer_width" - the width of a chamfer
//   - "chamfer_height" - the height of a chamfer
//   - "angle" - the chamfer angle, measured from the vertical (so zero is vertical, 90 is horizontal).  Default: 45
//   - "joint" - the joint distance for a "smooth" roundover
//   - "k" - the curvature smoothness parameter for "smooth" roundovers, a value in [0,1].  Default: 0.75
//   - "points" - point list for use with the "profile" type
//   - "extra" - extra height added for unions/differences.  This makes the shape taller than the requested height.  (Default: 0)
//   - "steps" - number of vertical steps to use for the roundover.  Default: 16.
//   - "offset" - select "round" (r=) or "delta" (delta=) offset type for offset.  Default: "round"
//   .
//   Note that unlike `offset_sweep`, because the offset operation is always performed from the base shape, using chamfered offsets does not increase the
//   number of vertices or lead to any special complications.
//
// Arguments:
//   height / length / l / h = total height (including rounded portions, but not extra sections) of the output.  Default: combined height of top and bottom end treatments.
//   bottom = rounding spec for the bottom end
//   top = rounding spec for the top end.
//   ---
//   offset = default offset, `"round"`, `"delta"`, or `"chamfer"`.  Default: `"round"`
//   steps = default step count.  Default: 16
//   extra = default extra height.  Default: 0
//   cut = default cut value.
//   chamfer_width = default width value for chamfers.
//   chamfer_height = default height value for chamfers.
//   angle = default angle for chamfers.  Default: 45
//   joint = default joint value for smooth roundover.
//   k = default curvature parameter value for "smooth" roundover
//   convexity = convexity setting for use with polyhedron.  Default: 10
// Example: Chamfered elliptical prism.  If you stretch a chamfered cylinder, the chamfer becomes uneven.
//   convex_offset_extrude(bottom = os_chamfer(height=-2),
//                         top=os_chamfer(height=1), height=7)
//     xscale(4)circle(r=6,$fn=64);
// Example: Elliptical prism with circular roundovers.
//   convex_offset_extrude(bottom=os_circle(r=-2),
//                         top=os_circle(r=1), height=7,steps=10)
//     xscale(4)circle(r=6,$fn=64);
// Example: If you give a non-convex input you get a convex hull output
//   right(50) linear_extrude(height=7) star(5,r=22,ir=13);
//   convex_offset_extrude(bottom = os_chamfer(height=-2),
//                         top=os_chamfer(height=1), height=7, $fn=32)
//     star(5,r=22,ir=13);
function convex_offset_extrude(
        height, 
        bottom=[], top=[], 
        h, l, length,
        offset="round", r=0, steps=16,
        extra=0,
        cut=undef, chamfer_width=undef, chamfer_height=undef,
        joint=undef, k=0.75, angle=45,
        convexity=10, thickness = 1/1024
) = no_function("convex_offset_extrude");
module convex_offset_extrude(
        height,
        bottom=[],
        top=[], 
        h, l, length,
        offset="round", r=0, steps=16,
        extra=0,
        cut=undef, chamfer_width=undef, chamfer_height=undef,
        joint=undef, k=0.75, angle=45,
        convexity=10, thickness = 1/1024
) {
        req_children($children);  
        argspec = [
                ["for", ""],
                ["r",r],
                ["extra",extra],
                ["type","circle"],
                ["steps",steps],
                ["offset",offset],
                ["chamfer_width",chamfer_width],
                ["chamfer_height",chamfer_height],
                ["angle",angle],
                ["cut",cut],
                ["joint",joint],
                ["k", k],
                ["points", []],
        ];
        top = struct_set(argspec, top, grow=false);
        bottom = struct_set(argspec, bottom, grow=false);

        offsets_bot = _rounding_offsets(bottom, -1);
        offsets_top = _rounding_offsets(top, 1);

        // "Extra" height enlarges the result beyond the requested height, so subtract it
        bottom_height = len(offsets_bot)==0 ? 0 : abs(last(offsets_bot)[1]) - struct_val(bottom,"extra");
        top_height = len(offsets_top)==0 ? 0 : abs(last(offsets_top)[1]) - struct_val(top,"extra");

        height = one_defined([l,h,height,length], "l,h,height,length", dflt=u_add(bottom_height,top_height));
        middle = height-bottom_height-top_height;
        check =
          assert(height>=0, "Height must be nonnegative")
          assert(middle>=0, str(
                                "Specified end treatments (bottom height = ",bottom_height,
                                " top_height = ",top_height,") are too large for extrusion height (",height,")"
                            )
          );
        // The entry r[i] is [radius,z] for a given layer
        r = move([0,bottom_height],p=concat(
                          reverse(offsets_bot), [[0,0], [0,middle]], move([0,middle], p=offsets_top)));
        delta = [for(val=deltas(column(r,0))) sign(val)];
        below=[-thickness,0];
        above=[0,thickness];
           // layers is a list of pairs of the relative positions for each layer, e.g. [0,thickness]
           // puts the layer above the polygon, and [-thickness,0] puts it below.
        layers = [for (i=[0:len(r)-1])
          i==0 ? (delta[0]<0 ? below : above) :
          i==len(r)-1 ? (delta[len(delta)-1] < 0 ? below : above) :
          delta[i]==0 ? above :
          delta[i+1]==0 ? below :
          delta[i]==delta[i-1] ? [-thickness/2, thickness/2] :
          delta[i] == 1 ? above :
          /* delta[i] == -1 ? */ below];
        dochamfer = offset=="chamfer";
        attachable(){
          for(i=[0:len(r)-2])
            for(j=[0:$children-1])
             hull(){
               up(r[i][1]+layers[i][0])
                 linear_extrude(convexity=convexity,height=layers[i][1]-layers[i][0])
                   if (offset=="round")
                     offset(r=r[i][0])
                       children(j);
                   else
                     offset(delta=r[i][0],chamfer = dochamfer)
                       children(j);
               up(r[i+1][1]+layers[i+1][0])
                 linear_extrude(convexity=convexity,height=layers[i+1][1]-layers[i+1][0])
                   if (offset=="round")
                     offset(r=r[i+1][0])
                       children(j);
                   else
                     offset(delta=r[i+1][0],chamfer=dochamfer)
                       children(j);
             }
          union();
        }
}



function _remove_undefined_vals(list) =
        let(ind=search([undef],list,0)[0])
        list_remove(list, concat(ind, add_scalar(ind,-1)));



function _rp_compute_patches(top, bot, rtop, rsides, ktop, ksides, concave) =
   let(
     N = len(top),
     plane = plane3pt_indexed(top,0,1,2),
     rtop_in = is_list(rtop) ? rtop[0] : rtop,
     rtop_down = is_list(rtop) ? rtop[1] : abs(rtop)
   )
  [for(i=[0:N-1])
           let(
               rside_prev = is_list(rsides[i])? rsides[i][0] : rsides[i],
               rside_next = is_list(rsides[i])? rsides[i][1] : rsides[i],
               concave_sign = (concave[i] ? -1 : 1) * (rtop_in>=0 ? 1 : -1),  // Negative if normals need to go "out"
               prev = select(top,i-1) - top[i],
               next = select(top,i+1) - top[i],
               prev_offset = top[i] + rside_prev * unit(prev) / sin(vector_angle(prev,bot[i]-top[i])),
               next_offset = top[i] + rside_next * unit(next) / sin(vector_angle(next,bot[i]-top[i])),
               down = rtop_down * unit(bot[i]-top[i]) / sin(abs(plane_line_angle(plane, [bot[i],top[i]]))),
               row2 = [prev_offset,     top[i],     next_offset     ],
               row4 = [prev_offset+down,top[i]+down,next_offset+down],
               in_prev = concave_sign * unit(next-(next*prev)*prev/(prev*prev)),
               in_next = concave_sign * unit(prev-(prev*next)*next/(next*next)),
               far_corner = top[i]+ concave_sign*unit(unit(prev)+unit(next))* abs(rtop_in) / sin(vector_angle(prev,next)/2),
               row0 =
                 concave_sign<0 ?
                    [prev_offset+abs(rtop_in)*in_prev, far_corner, next_offset+abs(rtop_in)*in_next]
                 :
                    let(
                       prev_corner = prev_offset + abs(rtop_in)*in_prev,
                       next_corner = next_offset + abs(rtop_in)*in_next,
                       line = project_plane(plane, [
                                                       [far_corner, far_corner+prev],
                                                       [prev_offset, prev_offset+in_prev],
                                                       [far_corner, far_corner+next],
                                                       [next_offset, next_offset+in_next]
                                                   ]),
                       prev_degenerate = is_undef(line_intersection(line[0],line[1],RAY,RAY)),
                       next_degenerate = is_undef(line_intersection(line[2],line[3],RAY,RAY))
                    )
                    [ prev_degenerate ? far_corner : prev_corner,
                      far_corner,
                      next_degenerate ? far_corner : next_corner]
            ) _smooth_bez_fill(
                      [for(row=[row0, row2, row4]) _smooth_bez_fill(row,ksides[i])],
                      ktop)];


// Function&Module: rounded_prism()
// Synopsis: Make a rounded 3d object by connecting two polygons with the same vertex count.
// SynTags: Geom, VNF
// Topics: Rounding, Offsets
// See Also: offset_sweep(), convex_offset_extrude(), rounded_prism(), bent_cutout_mask(), join_prism()
// Usage: as a module
//   rounded_prism(bottom, [top], [height=|h=|length=|l=], [joint_top=], [joint_bot=], [joint_sides=], [k=], [k_top=], [k_bot=], [k_sides=], [splinesteps=], [debug=], [convexity=],...) [ATTACHMENTS];
// Usage: as a function
//   vnf = rounded_prism(bottom, [top], [height=|h=|length=|l=], [joint_top=], [joint_bot=], [joint_sides=], [k=], [k_top=], [k_bot=], [k_sides=], [splinesteps=], [debug=]);
// Description:
//   Construct a generalized prism with continuous curvature rounding.  You supply the polygons for the top and bottom of the prism.  The only
//   limitation is that joining the edges must produce a valid polyhedron with coplanar side faces.  The vertices of the top and bottom
//   are joined in the order listed.  The top should have the standard vertex order for a polyhedron: clockwise as seen when viewing the prism
//   from the outside. 
//   .
//   You specify the rounding by giving
//   the joint distance away from the corner for the rounding curve.  The k parameter ranges from 0 to 1 with a default of 0.5.  Larger
//   values give a more abrupt transition and smaller ones a more gradual transition.  If you set the value much higher
//   than 0.8 the curvature changes abruptly enough that though it is theoretically continuous, it may
//   not be continuous in practice.  A value of 0.92 is a good approximation to a circle.  If you set it small then the transition
//   is so gradual that the roundover may be small.  If you want a smooth roundover, set the joint parameter as large as possible and
//   then adjust the k value down as low as gives a sufficiently large roundover.  See
//   [Types of Roundover](rounding.scad#subsection-types-of-roundover) for more information on continuous curvature rounding.  
//   .
//   You can specify the bottom and top polygons by giving two compatible 3d paths.  You can also give 2d paths and a height/length and the
//   two shapes are offset in the z direction from each other.  The final option is to specify just the bottom along with a height/length;
//   in this case the top is a copy of the bottom, offset in the z direction by the specified height.
//   .
//   You define rounding for all of the top edges, all of the bottom edges, and independently for each of the connecting side edges.
//   You specify rounding the rounding by giving the joint distance for where the curved section should start.  If the joint distance is 1 then
//   it means the curved section begins 1 unit away from the edge (in the perpendicular direction).  Typically each joint distance is a scalar
//   value and the rounding is symmetric around each edge.  However, you can specify a 2-vector for the joint distance to produce asymmetric
//   rounding which is different on the two sides of the edge.  This may be useful when one one edge in your polygon is much larger than another.
//   For the top and bottom you can specify negative joint distances.  If you give a scalar negative value, then the roundover flares
//   outward.  If you give a vector value then a negative value, then if `joint_top[0]` is negative the shape flares outward, but if
//   `joint_top[1]` is negative, the shape flares upward.  At least one value must be non-negative.  The same rules apply for joint_bot.
//   The joint_sides parameter must be entirely nonnegative.
//   .
//   If the roundings at two adjacent side edges exceed the width of the face then the polyhedron becomes invalid due to self-intersecting faces.
//   Similarly, if the roundings on the top or bottom edges cross the top face and intersect with each other, the resulting polyhedron is invalid:
//   the top face after the roundings are applied must be a valid, non-degenerate polyhedron.  There are two exceptions:  it is permissible to
//   construct a top that is a single point or two points.  This means you can completely round a cube by setting the joint to half of
//   the cube's width.  
//   If you set `debug` to true, the module version displays the polyhedron even when it is invalid and it shows the bezier patches at the corners.
//   This can help troubleshoot problems with your parameters.  With the function form setting debug to true causes run even on invalid cases and to return [patches,vnf] where
//   patches is a list of the bezier control points for the corner patches.
//   .
//   This module offers five anchor types.  The default is "hull" in which VNF anchors are placed on the VNF of the **unrounded** object.  You
//   can also use "intersect" to get the intersection anchors to the unrounded object. If you prefer anchors that respect the rounding
//   then use "surf_hull" or "intersect_hull".  Lastly, in the special case of a prism with four sides, you can use "prismoid" anchoring
//   which attempts to assign standard prismoid anchors to the shape by assigning as RIGHT the face that is closest to the RIGHT direction,
//   and defining the other anchors around the shape baesd on that choice.  
//   .
//   Note that rounded_prism() is not well suited to rounding shapes that have already been rounded, or that have many points.
//   It works best when the top and bottom are polygons with well-defined corners.  When the polygons have been rounded already,
//   further rounding generates tiny bezier patches patches that can more easily
//   interfere, giving rise to an invalid polyhedron.  It's also slow because you get bezier patches for every corner in the model.  
//   .
// Named Anchors:
//   "origin" = The native position of the prism.
//   "top" = Top face, with spin BACK if face is parallel to the XY plane, or with positive Z otherwise
//   "bot" = Bottom face, with spin BACK if face is parallel to the XY plane, or with positive Z otherwise
//   "edge0", "edge1", etc. = Center of each side edge, spin pointing up along the edge
//   "face0", "face1", etc. = Center of each side face, spin pointing up
//   "top_edge0", "top_edge1", etc = Center of each top edge, spin pointing clockwise (from top)
//   "bot_edge0", "bot_edge1", etc = Center of each bottom edge, spin pointing clockwise (from bottom)
//   "top_corner0", "top_corner1", etc = Top corner, pointing in direction of associated edge anchor, spin up along associated edge
//   "bot_corner0", "bot_2corner1", etc = Bottom corner, pointing in direction of associated edge anchor, spin up along associated edge
// Arguments:
//   bottom = 2d or 3d path describing bottom polygon
//   top = 2d or 3d path describing top polygon (must be the same dimension as bottom)
//   ---
//   height/length/h/l = height of the shape when you give 2d bottom
//   joint_top = joint distance or [joint,k] pair for top roundover (number or 2-vector).  Default: 0
//   joint_bot = joint distance or [joint,k] for bottom roundover (number or 2-vector).  Default: 0
//   joint_sides = joint distance or [joint,k] for rounding of side edges, a number/2-vector or list of them.  Default: 0
//   k = continuous curvature rounding parameter for all edges.  Default: 0.5
//   k_top = continuous curvature rounding parameter for top
//   k_bot = continuous curvature rounding parameter for bottom
//   k_sides = continuous curvature rounding parameter side edges, a number or vector.  
//   splinesteps = number of segments to use for curved patches.  Default: 16
//   debug = turn on debug mode which displays illegal polyhedra and shows the bezier corner patches for troubleshooting purposes.  Default: False
//   convexity = convexity parameter for polyhedron(), only for module version.  Default: 10
//   anchor = Translate so anchor point is at the origin.  (module only) Default: "origin"
//   spin = Rotate this many degrees around Z axis after anchor.  (module only) Default: 0
//   orient = Vector to rotate top toward after spin  (module only)
//   atype = Select "prismoid", "hull", "intersect", "surf_hull" or "surf_intersect" anchor types. (module only) Default: "hull"
//   cp = Centerpoint for determining "intersect" anchors or centering the shape.  Determintes the base of the anchor vector.  Can be "centroid", "mean", "box" or a 3D point.  (module only) Default: "centroid"
// Named Anchors:
//   "top" = center of top face pointing normal to that face
//   "bot" = center of bottom face pointing normal to that face
//   "edge0", "edge1", etc. = Center of each side edge, spin pointing up along the edge.  Can access with EDGE(i)
//   "face0", "face1", etc. = Center of each side face, spin pointing up.  Can access with FACE(i)
//   "top_edge0", "top_edge1", etc = Center of each top edge, spin pointing clockwise (from top). Can access with EDGE(TOP,i)
//   "bot_edge0", "bot_edge1", etc = Center of each bottom edge, spin pointing clockwise (from bottom).  Can access with EDGE(BOT,i)
//   "top_corner0", "top_corner1", etc = Top corner, pointing in direction of associated edge anchor, spin up along associated edge
//   "bot_corner0", "bot_corner1", etc = Bottom corner, pointing in direction of associated edge anchor, spin up along associated edge
// Anchor Types:
//   "hull" = Anchors to the VNF of the **unrounded** prism using VNF hull anchors (default)
//   "intersect" = Anchors to the VNF of the **unrounded** prism using VNF intersection anchors
//   "surf_hull" = Use VNF hull anchors to the rounded VNF
//   "surf_intersect" = USe VFN intersection anchors to the rounded VNF
//   "prismoid" = For four sided prisms only, defined standard prismsoid anchors, with RIGHT set to the face closest to the RIGHT direction.  
// Example: Uniformly rounded pentagonal prism
//   rounded_prism(pentagon(3), height=3,
//                 joint_top=0.5, joint_bot=0.5, joint_sides=0.5) position(FWD) cube(1);
// Example: Maximum possible rounding.
//   rounded_prism(pentagon(3), height=3,
//                 joint_top=1.5, joint_bot=1.5, joint_sides=1.5);
// Example: Decreasing k from the default of 0.5 to 0.3 gives a smoother round over which takes up more space, so it appears less rounded.
//   rounded_prism(pentagon(3), height=3, joint_top=1.5, joint_bot=1.5,
//                 joint_sides=1.5, k=0.3, splinesteps=32);
// Example: Increasing k from the default of 0.5 to 0.92 approximates a circular roundover, which does not have continuous curvature.  Notice the visible "edges" at the boundary of the corner and edge patches.  
//   rounded_prism(pentagon(3), height=3, joint_top=0.5,
//                 joint_bot=0.5, joint_sides=0.5, k=0.92);
// Example: rounding just one edge
//   rounded_prism(pentagon(side=3), height=3, joint_top=0.5, joint_bot=0.5,
//                 joint_sides=[0,0,0.5,0,0], splinesteps=16);
// Example: rounding all the edges differently
//   rounded_prism(pentagon(side=3), height=3, joint_top=0.25, joint_bot=0.5,
//                 joint_sides=[1.7,.5,.7,1.2,.4], splinesteps=32);
// Example: different k values for top, bottom and sides
//   rounded_prism(pentagon(side=3.0), height=3.0, joint_top=1.4, joint_bot=1.4,
//                 joint_sides=0.7, k_top=0.7, k_bot=0.3, k_sides=0.5, splinesteps=48);
// Example: flared bottom
//   rounded_prism(pentagon(3), height=3, joint_top=1.0,
//                 joint_bot=-0.5, joint_sides=0.5);
// Example: truncated pyramid
//   rounded_prism(pentagon(3), apply(scale(.7),pentagon(3)),
//                 height=3, joint_top=0.5, joint_bot=0.5, joint_sides=0.5);
// Example: top translated
//   rounded_prism(pentagon(3), apply(right(2),pentagon(3)),
//                 height=3, joint_top=0.5, joint_bot=0.5, joint_sides=0.5);
// Example(NORENDER): top rotated: fails due to non-coplanar side faces
//   rounded_prism(pentagon(3), apply(rot(45),pentagon(3)), height=3,
//                 joint_top=0.5, joint_bot=0.5, joint_sides=0.5);
// Example: skew top
//   rounded_prism(path3d(pentagon(3)), apply(skew(azy=-20),path3d(pentagon(3),3)),
//                 joint_top=0.5, joint_bot=0.5, joint_sides=0.5);
// Example: this rotation gives coplanar sides
//   rounded_prism(path3d(square(4)), apply(yrot(-100)*right(2),path3d(square(4),3)),
//                 joint_top=0.5, joint_bot=0.5, joint_sides=0.5);
// Example: a shape with concave corners
//   M = path3d(turtle(["left", 180, "length",3,"move", "left", "move", 3, "right",
//                      "move", "right", "move", 4, "right", "move", 3, "right", "move", 2]));
//   rounded_prism(M, apply(up(3),M), joint_top=0.75, joint_bot=0.2,
//                 joint_sides=[.2,2.5,2,0.5,1.5,.5,2.5], splinesteps=32);
// Example: using debug mode to see the corner patch sizes, which may help figure out problems with interfering corners or invalid polyhedra.  The corner patches must not intersect each other.
//   M = path3d(turtle(["left", 180, "length",3,"move", "left", "move", 3, "right",
//                      "move", "right", "move", 4, "right", "move", 3, "right", "move", 2]));
//   rounded_prism(M, apply(up(3),M), joint_top=0.75, joint_bot=0.2,
//                 joint_sides=[.2,2.5,2,0.5,1.5,.5,2.5], splinesteps=16,debug=true);
// Example: applying transformation to the previous example
//   M = path3d(turtle(["left", 180, "length",3,"move", "left", "move", 3, "right",
//                      "move", "right", "move", 4, "right", "move", 3, "right", "move", 2]));
//   rounded_prism(M, apply(right(1)*scale(.75)*up(3),M), joint_top=0.5, joint_bot=0.2,
//                 joint_sides=[.2,1,1,0.5,1.5,.5,2], splinesteps=32);
// Example: this example shows most of the different types of patches that rounded_prism creates.  Note that some of the patches are close to interfering with each other across the top of the polyhedron, which would create an invalid result.
//   N = apply(rot(180)*yscale(.8),turtle(["length",3,"left", "move", 2, "right", 135,"move", sqrt(2), 
//                                         "left", "move", sqrt(2), "right", 135, "move", 2]));
//   rounded_prism(N, height=3, joint_bot=0.5, joint_top=1.25, joint_sides=[[1,1.75],0,.5,.5,2], debug=true);
// Example: This object has different scales on its different axies.  Here is the largest symmetric rounding that fits.  Note that the rounding is slightly smaller than the object dimensions because of roundoff error.
//   rounded_prism(square([100.1,30.1]), height=8.1, joint_top=4, joint_bot=4,
//                 joint_sides=15, k_sides=0.3, splinesteps=32);
// Example: Using asymetric rounding enables a much more rounded form:
//   rounded_prism(square([100.1,30.1]), height=8.1, joint_top=[15,4], joint_bot=[15,4],
//                 joint_sides=[[15,50],[50,15],[15,50],[50,15]], k_sides=0.3, splinesteps=32);
// Example: Flaring the top upward instead of outward.  The bottom has an asymmetric rounding with a small flare but a large rounding up the side.
//   rounded_prism(pentagon(3), height=3, joint_top=[1,-1],
//                 joint_bot=[-0.5,2], joint_sides=0.5);
// Example: Sideways polygons:
//   rounded_prism(apply(yrot(95),path3d(hexagon(3))), apply(yrot(95), path3d(hexagon(3),3)),
//                 joint_top=2, joint_bot=1, joint_sides=1);
// Example: Chamfer a polyhedron by setting splinesteps to 1
//   N = apply(rot(180)*yscale(.8),turtle(["length",3,"left", "move", 2, "right", 135,"move", sqrt(2), 
//                                         "left", "move", sqrt(2), "right", 135, "move", 2]));
//   rounded_prism(N, height=3, joint_bot=-0.3, joint_top=.4, joint_sides=[.75,0,.2,.2,.7], splinesteps=1);


module rounded_prism(bottom, top, joint_bot=0, joint_top=0, joint_sides=0, k_bot, k_top, k_sides,
                     k=0.5, splinesteps=16, h, length, l, height, convexity=10, debug=false,
                     anchor="origin",cp="centroid",spin=0, orient=UP, atype="hull")
{
  dummy1 = assert(in_list(atype, ["intersect","hull","surf_intersect","surf_hull","prismoid"]),
                  "Anchor type must be one of: \"hull\", \"intersect\", \"surf_hull\", \"surf_intersect\" or \"prismoid\"")
           assert(atype!="prismoid" || len(bottom)==4, "Anchor type \"prismoid\" requires that len(bottom)=4");
  
  result = rounded_prism(bottom=bottom, top=top, joint_bot=joint_bot, joint_top=joint_top, joint_sides=joint_sides,
                         k_bot=k_bot, k_top=k_top, k_sides=k_sides, k=k, splinesteps=splinesteps, h=h, length=length, height=height, l=l,
                         debug=debug, _full_info=true);
  height = one_defined([l,h,height,length], "l,h,height,length", dflt=undef);
  top = is_undef(top) ? path3d(bottom,height/2) :
        len(top[0])==2 ? path3d(top,height/2) :
        top;
  bottom = len(bottom[0])==2 ? path3d(bottom,-height/2) : bottom;
  unrounded = vnf_vertex_array([top,bottom],caps=true, col_wrap=true,reverse=true);

  vnf = result[1];
  geom = atype=="prismoid" ?
               let(
                    botbounds = pointlist_bounds(bottom),
                    topbounds = pointlist_bounds(top),
                    allz = column(concat(bottom,top),2),
                    height = max(allz)-min(allz),
                    size = [botbounds[1].x-botbounds[0].x, botbounds[1].x-botbounds[0].x, height],
                    size2 = [topbounds[1].x-topbounds[0].x, topbounds[1].x-topbounds[0].x],
                    shift = point2d(mean(topbounds)-mean(botbounds))
                )    
                attach_geom(size=size, size2=size2, shift=shift,anchors=result[2], override=result[3])
       : in_list(atype,["hull","intersect"]) ? attach_geom(vnf=unrounded, extent=atype=="hull", cp=cp, anchors=result[2])
       : attach_geom(vnf=vnf, extent=atype=="surf_hull", cp=cp, anchors=result[2]);
  attachable(anchor=anchor, spin=spin, orient=orient, geom=geom)
  {
    if (debug){
        vnf_polyhedron(vnf, convexity=convexity);
        debug_bezier_patches(result[0], showcps=true, splinesteps=splinesteps, $fn=16, showdots=false, showpatch=false);
    }
    else vnf_polyhedron(vnf,convexity=convexity);
    children();
  }
}


function rounded_prism(bottom, top, joint_bot=0, joint_top=0, joint_sides=0, k_bot, k_top, k_sides, k=0.5, splinesteps=16,
                       h, length, l, height, debug=false, _full_info=false) =
   let(
       bottom = force_path(bottom,"bottom"),
       top = force_path(top,"top")
   )
   assert(is_path(bottom,[2,3]) && len(bottom)>=3, "bottom must be a 2D or 3D path")
   assert(is_num(k) && k>=0 && k<=1, "Curvature parameter k must be in interval [0,1]")
   let(
     N=len(bottom),
     k_top = default(k_top, k),
     k_bot = default(k_bot, k),
     k_sides = default(k_sides, k),
     height = one_defined([h,l,height,length],"height,length,l,h", dflt=undef),
     shapedimok = (len(bottom[0])==3 && is_path(top,3)) || (len(bottom[0])==2 && (is_undef(top) || is_path(top,2)))
   )
   assert(is_num(k_top) && k_top>=0 && k_top<=1, "Curvature parameter k_top must be in interval [0,1]")
   assert(is_num(k_bot) && k_bot>=0 && k_bot<=1, "Curvature parameter k_bot must be in interval [0,1]")
   assert(shapedimok,"bottom and top must be 2d or 3d paths with the same dimension")
   assert(len(bottom[0])==3 || is_num(height),"Must give height/length with 2d polygon input")
   let(
     // Determine which points are concave by making bottom 2d if necessary
     bot_proj = len(bottom[0])==2 ? bottom :  project_plane(select(bottom,0,2),bottom),
     bottom_sign = is_polygon_clockwise(bot_proj) ? 1 : -1,
     concave = [for(i=[0:N-1]) bottom_sign*sign(_point_left_of_line2d(select(bot_proj,i+1), select(bot_proj, i-1,i)))>0],
     top = is_undef(top) ? path3d(bottom,height/2) :
           len(top[0])==2 ? path3d(top,height/2) :
           top,
     bottom = len(bottom[0])==2 ? path3d(bottom,-height/2) : bottom,
     jssingleok = (is_num(joint_sides) && joint_sides >= 0) || (is_vector(joint_sides,2) && joint_sides[0]>=0 && joint_sides[1]>=0),
     jsvecok = is_list(joint_sides) && len(joint_sides)==N && []==[for(entry=joint_sides) if (!(is_num(entry) || is_vector(entry,2))) entry]
   )
   assert(is_num(joint_top) || is_vector(joint_top,2))
   assert(is_num(joint_bot) || is_vector(joint_bot,2))
   assert(is_num(joint_top) || (joint_top[0]>=0 ||joint_top[1]>=0), "Both entries in joint_top cannot be negative")
   assert(is_num(joint_bot) || (joint_bot[0]>=0 ||joint_bot[1]>=0), "Both entries in joint_bot cannot be negative")
   assert(jsvecok || jssingleok,
          str("Argument joint_sides is invalid.  All entries must be nonnegative, and it must be a number, 2-vector, or a length ",N," list those."))
   assert(is_num(k_sides) || is_vector(k_sides,N), str("Curvature parameter k_sides must be a number or length ",N," vector"))
   assert(is_coplanar(bottom))
   assert(is_coplanar(top))
   assert(!is_num(k_sides) || (k_sides>=0 && k_sides<=1), "Curvature parameter k_sides must be in interval [0,1]")
   let(
     non_coplanar=[for(i=[0:N-1]) if (!is_coplanar(concat(select(top,i,i+1), select(bottom,i,i+1)))) [i,(i+1)%N]],
     k_sides_vec = is_num(k_sides) ? repeat(k_sides, N) : k_sides,
     kbad = [for(i=[0:N-1]) if (k_sides_vec[i]<0 || k_sides_vec[i]>1) i],
     joint_sides_vec = jssingleok ? repeat(joint_sides,N) : joint_sides,
     top_collinear = [for(i=[0:N-1]) if (is_collinear(select(top,i-1,i+1))) i],
     bot_collinear = [for(i=[0:N-1]) if (is_collinear(select(bottom,i-1,i+1))) i]
   )
   assert(non_coplanar==[], str("Side faces are non-coplanar at edges: ",non_coplanar))
   assert(top_collinear==[], str("Top has collinear or duplicated points at indices: ",top_collinear))
   assert(bot_collinear==[], str("Bottom has collinear or duplicated points at indices: ",bot_collinear))
   assert(kbad==[], str("k_sides parameter outside interval [0,1] at indices: ",kbad))
   let(
     top_patch = _rp_compute_patches(top, bottom, joint_top, joint_sides_vec, k_top, k_sides_vec, concave),
     bot_patch = _rp_compute_patches(bottom, top, joint_bot, joint_sides_vec, k_bot, k_sides_vec, concave),

     vertbad = [for(i=[0:N-1])
                   if (norm(top[i]-top_patch[i][4][2]) + norm(bottom[i]-bot_patch[i][4][2]) > EPSILON + norm(bottom[i]-top[i])) i],
     // Check that the patch fits on the polygon edge
     topbad = [for(i=[0:N-1])
                   if (norm(top_patch[i][2][4]-top_patch[i][2][2]) + norm(select(top_patch,i+1)[2][0]-select(top_patch,i+1)[2][2])
                  > EPSILON + norm(top_patch[i][2][2] - select(top_patch,i+1)[2][2]))   [i,(i+1)%N]],
     botbad = [for(i=[0:N-1])
                   if (norm(bot_patch[i][2][4]-bot_patch[i][2][2]) + norm(select(bot_patch,i+1)[2][0]-select(bot_patch,i+1)[2][2])
                  > EPSILON + norm(bot_patch[i][2][2] - select(bot_patch,i+1)[2][2]))   [i,(i+1)%N]],
     // If top/bot is L-shaped, check that arms of L from adjacent patches don't cross
     topLbad = [for(i=[0:N-1])
                   if (norm(top_patch[i][0][2]-top_patch[i][0][4]) + norm(select(top_patch,i+1)[0][0]-select(top_patch,i+1)[0][2])
                          > EPSILON + norm(top_patch[i][0][2]-select(top_patch,i+1)[0][2])) [i,(i+1)%N]],
     botLbad = [for(i=[0:N-1])
                   if (norm(bot_patch[i][0][2]-bot_patch[i][0][4]) + norm(select(bot_patch,i+1)[0][0]-select(bot_patch,i+1)[0][2])
                          > EPSILON + norm(bot_patch[i][0][2]-select(bot_patch,i+1)[0][2])) [i,(i+1)%N]],
     // Check that the inner edges of the patch don't cross
     topinbad = [for(i=[0:N-1]) 
                     let(
                          line1 = project_plane(top,[top_patch[i][2][0],top_patch[i][0][0]]),
                          line2 = project_plane(top,[select(top_patch,i+1)[2][4],select(top_patch,i+1)[0][4]])
                     )
                     if (!approx(line1[0],line1[1]) && !approx(line2[0],line2[1]) &&
                         line_intersection(line1,line2, SEGMENT,SEGMENT))
                          [i,(i+1)%N]],
     botinbad = [for(i=[0:N-1])
                     let(
                          line1 = project_plane(bottom,[bot_patch[i][2][0],bot_patch[i][0][0]]),
                          line2 = project_plane(bottom,[select(bot_patch,i+1)[2][4],select(bot_patch,i+1)[0][4]])
                     )
                     if (!approx(line1[0],line1[1]) && !approx(line2[0],line2[1]) &&
                         line_intersection(line1,line2, SEGMENT,SEGMENT))
                          [i,(i+1)%N]]
   )
   assert(debug || vertbad==[], str("Top and bottom joint lengths are too large; they interfere with each other at vertices: ",vertbad))
   assert(debug || topbad==[], str("Joint lengths too large at top or side edges: ",topbad))
   assert(debug || botbad==[], str("Joint lengths too large at bottom or side edges: ",botbad))
   assert(debug || topLbad==[], str("Joint length too large on the top face or side at edges: ", topLbad))
   assert(debug || botLbad==[], str("Joint length too large on the bottom face or side at edges: ", botLbad))
   assert(debug || topinbad==[], str("Joint length too large on the top face at edges: ", topinbad))
   assert(debug || botinbad==[], str("Joint length too large on the bottom face at edges: ", botinbad))
   let(
     // Entries in the next two lists have the form [edges, vnf] where
     // edges is a list [leftedge, rightedge, topedge, botedge]
     top_samples = [for(patch=top_patch) bezier_vnf_degenerate_patch(patch,splinesteps,reverse=false,return_edges=true) ],
     bot_samples = [for(patch=bot_patch) bezier_vnf_degenerate_patch(patch,splinesteps,reverse=true,return_edges=true) ],
     leftidx=0,
     rightidx=1,
     topidx=2,
     botidx=3,
     edge_points =
       [for(i=[0:N-1])
            let(
               top_edge  = [ top_samples[i][1][rightidx], select(top_samples, i+1)[1][leftidx]],
               bot_edge  = [ select(bot_samples, i+1)[1][leftidx], bot_samples[i][1][rightidx]],
               vert_edge = [ bot_samples[i][1][botidx], top_samples[i][1][botidx]]
               )
               each [top_edge, bot_edge, vert_edge] ],
     faces = [
              [for(i=[0:N-1]) each top_samples[i][1][topidx]],
              [for(i=[N-1:-1:0]) each reverse(bot_samples[i][1][topidx])],
              for(i=[0:N-1]) [
                                 bot_patch[i][4][4],
                                 select(bot_patch,i+1)[4][0],
                                 select(top_patch,i+1)[4][0],
                                 top_patch[i][4][4]
                             ]
             ],
     top_collinear = is_collinear(faces[0]),
     bot_collinear = is_collinear(faces[1]),
     top_degen_ok = top_collinear && len(deduplicate(faces[0]))<=2,
     bot_degen_ok = bot_collinear && len(deduplicate(faces[1]))<=2,
     top_simple = top_degen_ok || (!top_collinear && is_path_simple(project_plane(faces[0],faces[0]),closed=true)),
     bot_simple = bot_degen_ok || (!bot_collinear && is_path_simple(project_plane(faces[1],faces[1]),closed=true)),                                   
     // verify vertical edges
     verify_vert =
       [for(i=[0:N-1],j=[0:4])
         let(
               vline = concat(select(column(top_patch[i],j),2,4),
                              select(column(bot_patch[i],j),2,4))
             )
         if (!is_collinear(vline)) [i,j]],
     //verify horiz edges
     verify_horiz=[for(i=[0:N-1], j=[0:4])
         let(
             hline_top = concat(select(top_patch[i][j],2,4), select(select(top_patch, i+1)[j],0,2)),
             hline_bot = concat(select(bot_patch[i][j],2,4), select(select(bot_patch, i+1)[j],0,2))
         )
         if (!is_collinear(hline_top) || !is_collinear(hline_bot)) [i,j]]
    )
    assert(debug || top_simple,
          "Roundovers interfere with each other on top face: either input is self intersecting or top joint length is too large")
    assert(debug || bot_simple,
          "Roundovers interfere with each other on bottom face: either input is self intersecting or top joint length is too large")
    assert(debug || (verify_vert==[] && verify_horiz==[]), "Curvature continuity failed")
    let( 
        vnf = vnf_join([ each column(top_samples,0),
                          each column(bot_samples,0),
                          for(pts=edge_points) vnf_vertex_array(pts),
                          debug ? vnf_from_polygons(faces,fast=true) 
                                : vnf_triangulate(vnf_from_polygons(faces))
                       ]),

        topnormal = unit(cross(top[0]-top[1],top[2]-top[1])),
        botnormal = -unit(cross(bottom[0]-bottom[1],bottom[2]-bottom[1])),
        sidenormal = [for(i=idx(top))
                         unit(cross(select(top,i+1)-top[i], bottom[i]-top[i]))],

        //pos, orient, spin, info=...
        
        anchors = [
            for(i=idx(top))
              let(
                   face = concat(select(top,[i+1,i]), select(bottom,i,i+1)),
                   face_ctr = mean(concat(select(top,[i+1,i]), select(bottom,i,i+1))),
                   bot_edge = bottom[i]-select(bottom,i+1), 
                   bot_edge_ctr = mean(select(bottom,i,i+1)),
                   bot_edge_normal = unit(mean([sidenormal[i],botnormal])),
                   top_edge_normal = unit(mean([sidenormal[i],topnormal])),
                   top_edge = select(top,i+1)-top[i],
                   top_edge_ctr = mean(select(top,i,i+1)),
                   top_edge_dir = select(top,i+1)-top[i],
                   edge = [top[i],bottom[i]],
                   edge_ctr = mean([top[i],bottom[i]]),
                   edge_normal = unit(mean(select(sidenormal,[i,i-1]))),
                   top_corner_dir = _three_edge_corner_dir([select(sidenormal,i-1),sidenormal[i],topnormal],
                                                           [top[i]-select(top,i-1), top_edge]),
                   bot_corner_dir = _three_edge_corner_dir([select(sidenormal,i-1),sidenormal[i],botnormal],
                                                           [bottom[i]-select(bottom,i-1), bot_edge])
              )
              each[
                named_anchor(EDGE(i),edge_ctr,edge_normal, _compute_spin(edge_normal,top[i]-bottom[i]),
                             info=[["edge_angle",180-vector_angle(sidenormal[i],select(sidenormal,i-1))], ["edge_length",norm(top[i]-bottom[i])]]),
                named_anchor(EDGE(UP,i),top_edge_ctr, top_edge_normal, _compute_spin(top_edge_normal,  top_edge),
                             info=[["edge_angle",180-vector_angle(topnormal,sidenormal[i])], ["edge_length",norm(top_edge)]]),
                named_anchor(EDGE(DOWN,i),bot_edge_ctr, bot_edge_normal, _compute_spin(bot_edge_normal,  bot_edge),
                             info=[["edge_angle",180-vector_angle(botnormal,sidenormal[i])], ["edge_length",norm(bot_edge)]]), 
                named_anchor(FACE(i),mean(face), sidenormal[i], _compute_spin(sidenormal[i],UP)),
                named_anchor(str("top_corner",i),top[i], top_corner_dir, _compute_spin(top_corner_dir,UP)), 
                named_anchor(str("bot_corner",i),bottom[i], bot_corner_dir, _compute_spin(bot_corner_dir,UP)) 
              ],
            named_anchor("top", mean(top), topnormal, _compute_spin(topnormal, approx(v_abs(topnormal),UP)?BACK:UP)),
            named_anchor("bot", mean(bottom), botnormal, _compute_spin(botnormal, approx(v_abs(botnormal),UP)?BACK:UP)),
        ],
        override = len(top)!=4 ? undef
           :
            let(
                stddir = [RIGHT,FWD,LEFT,BACK],
                getanch = function(name) search([name], anchors, num_returns_per_match=1)[0],
                dir_angle = [for(i=[0:3])  vector_angle(anchors[6*i+3][2],RIGHT)],
                ofs = search([min(dir_angle)], dir_angle, num_returns_per_match=1)[0]
            )
            [
              [UP, select(anchors[24],1,3)],
              [DOWN, select(anchors[25],1,3)],
              for(i=[0:3])
                let(
                    edgeanch=anchors[((i+ofs)%4)*6],
                    upedge=anchors[((i+ofs)%4)*6+1],
                    downedge=anchors[((i+ofs)%4)*6+2],                    
                    faceanch=anchors[((i+ofs)%4)*6+3],
                    upcorner=anchors[((i+ofs)%4)*6+4],
                    downcorner=anchors[((i+ofs)%4)*6+5]
                )    
                each [
                      [stddir[i],select(faceanch,1,3)],
                      [stddir[i]+select(stddir,i-1), select(edgeanch,1,3)],
                      [stddir[i]+UP, select(upedge,1,3)], 
                      [stddir[i]+DOWN, select(downedge,1,3)],
                      [stddir[i]+select(stddir,i-1)+UP, select(upcorner,1,3)],
                      [stddir[i]+select(stddir,i-1)+DOWN, select(downcorner,1,3)],
                     ] 
           ]
    )
    !debug && !_full_info ? vnf
  : _full_info ? [concat(top_patch, bot_patch), vnf, anchors, override]
  : [concat(top_patch, bot_patch), vnf];



// Converts a 2d path to a path on a cylinder at radius r
function _cyl_hole(r, path) =
    [for(point=path) cylindrical_to_xyz(concat([r],xscale(360/(2*PI*r),p=point)))];

// Mask profile of 180 deg of a circle to round an edge
function _circle_mask(r) =
   let(eps=0.1)

   fwd(r+.01,p=
   [
    [r+eps,0],
    each arc(r=r, angle=[0, 180]),
    [-r-eps,0],
    [-r-eps, r+3*eps],
    [r+eps, r+3*eps]
   ]);


// Module: bent_cutout_mask()
// Synopsis: Create a mask for making a round-edged cutout in a cylindrical shell.
// SynTags: Geom
// Topics: Rounding, Offsets
// See Also: offset_sweep(), convex_offset_extrude(), rounded_prism(), bent_cutout_mask(), join_prism()
// Usage:
//   bent_cutout_mask(r|radius, thickness, path);
// Description:
//   Creates a mask for cutting a round-edged hole out of a vertical cylindrical shell.  The specified radius
//   is the center radius of the cylindrical shell.  The path needs to be sampled finely enough
//   so that it can follow the curve of the cylinder.  The thickness may need to be slighly oversized to
//   handle the faceting of the cylinder.  The path is wrapped around a cylinder, keeping the
//   same dimensions that is has on the plane, with y axis mapping to the z axis and the x axis bending
//   around the curve of the cylinder.  The angular span of the path on the cylinder must be somewhat
//   less than 180 degrees, and the path shouldn't have closely spaced points at concave points of high curvature because
//   this causes self-intersection in the mask polyhedron, resulting in CGAL failures.  The path also cannot include
//   sharp corners: construction of the mask requires the use of {{offset()}}, which expands sharp corners into long single
//   segments leading to incorrect results.  
// Arguments:
//   r / radius = center radius of the cylindrical shell to cut a hole in
//   thickness = thickness of cylindrical shell (may need to be slighly oversized)
//   path = 2d path that defines the hole to cut
// Example: The mask as long pointed ends because this was the most efficient way to close off those ends.
//   bent_cutout_mask(10, 1, apply(xscale(3),circle(r=3)),$fn=64);
// Example: An elliptical hole.  Note the thickness is slightly increased to 1.05 compared to the actual thickness of 1.
//   rot(-90) {
//     $fn=128;
//     difference(){
//       cyl(r=10.5, h=10);
//       cyl(r=9.5, h=11);
//       bent_cutout_mask(10, 1.05, apply(xscale(3),circle(r=3)),
//                        $fn=64);
//     }
//   }
// Example: An elliptical hole in a thick cylinder
//   rot(-90) {
//     $fn=128;
//     difference(){
//       cyl(r=14.5, h=15);
//       cyl(r=9.5, h=16);
//       bent_cutout_mask(12, 5.1, apply(xscale(3),circle(r=3)));
//     }
//   }
// Example: Complex shape example
//   rot(-90) {
//     $fn=128;
//     difference(){
//       cyl(r=10.5, h=10, $fn=128);
//       cyl(r=9.5, h=11, $fn=128);
//       bent_cutout_mask(10, 1.05,
//         apply(scale(3),
//           supershape(step=2,m1=5, n1=0.3,n2=1.7)),$fn=32);
//     }
//   }
// Example: this shape is invalid due to self-intersections at the inner corners
//   rot(-90) {
//     $fn=128;
//     difference(){
//       cylinder(r=10.5, h=10,center=true);
//       cylinder(r=9.5, h=11,center=true);
//       bent_cutout_mask(10, 1.05,
//         apply(scale(3),
//           supershape(step=2,m1=5, n1=0.1,n2=1.7)),$fn=32);
//     }
//   }
// Example: increasing the step gives a valid shape, but the shape looks terrible with so few points.
//   rot(-90) {
//     $fn=128;
//     difference(){
//       cylinder(r=10.5, h=10,center=true);
//       cylinder(r=9.5, h=11,center=true);
//       bent_cutout_mask(10, 1.05,
//         apply(scale(3),
//           supershape(step=12,m1=5, n1=0.1,n2=1.7)),$fn=32);
//     }
//   }
// Example: uniform resampling produces a somewhat better result, but room remains for improvement.  The lesson is that concave corners in your cutout cause trouble.  To get a good result we need to non-uniformly sample the supershape with more points at the star tips and few points at the inner corners.
//   rot(-90) {
//     $fn=128;
//     difference(){
//       cylinder(r=10.5, h=10,center=true);
//       cylinder(r=9.5, h=11,center=true);
//       bent_cutout_mask(10, 1.05,
//         apply(scale(3), resample_path(
//              supershape(step=1,m1=5, n1=0.10,n2=1.7),
//              60,closed=true)),
//         $fn=32);
//     }
//   }
// Example: The cutout spans 177 degrees.  If you decrease the tube radius to 2.5 the cutout spans over 180 degrees and the model fails.
//   r=2.6;     // Don't make this much smaller or it fails
//   rot(-90) {
//     $fn=128;
//     difference(){
//       tube(or=r, wall=1, h=10, anchor=CENTER);
//       bent_cutout_mask(r-0.5, 1.05,
//         apply(scale(3),
//           supershape(step=1,m1=5, n1=0.15,n2=1.7)),$fn=32);
//     }
//   }
// Example: A square hole is not as simple as it seems.  The model valid, but wrong, because the square didn't have enough samples to follow the curvature of the cylinder.
//   r=25;
//   rot(-90) {
//     $fn=128;
//     difference(){
//       tube(or=r, wall=2, h=35, anchor=BOT);
//       bent_cutout_mask(r-1, 2.1, back(5,p=square([18,18])));
//     }
//   }
// Example: Adding additional points fixed this problem
//   r=25;
//   rot(-90) {
//     $fn=128;
//     difference(){
//       tube(or=r, wall=2, h=35, anchor=BOT);
//       bent_cutout_mask(r-1, 2.1,
//         subdivide_path(back(5,p=square([18,18])),64,closed=true));
//     }
//   }
// Example: Rounding just the exterior corners of this star avoids the problems we had above with concave corners of the supershape, as long as we don't oversample the star.
//   r=25;
//   rot(-90) {
//     $fn=128;
//     difference(){
//       tube(or=r, wall=2, h=35, anchor=BOT);
//       bent_cutout_mask(r-1, 2.1,
//         apply(back(15),
//           subdivide_path(
//             round_corners(star(n=7,ir=5,or=10),
//                           cut=flatten(repeat([0.5,0],7)),$fn=32),
//             14*15,closed=true)));
//     }
//   }
// Example(2D): Cutting a slot in a cylinder is tricky if you want rounded corners at the top.  This slot profile has slightly angled top edges to blend into the top edge of the cylinder.
//   function slot(slotwidth, slotheight, slotradius) = let(
//       angle = 85,
//       slot = round_corners(
//           turtle([
//               "right",
//               "move", slotwidth,
//               "left", angle,
//               "move", 2*slotwidth,
//               "right", angle,
//               "move", slotheight,
//               "left",
//               "move", slotwidth,
//               "left",
//               "move", slotheight,
//               "right", angle,
//               "move", 2*slotwidth,
//               "left", angle,
//               "move", slotwidth
//           ]),
//           radius = [0,0,each repeat(slotradius,4),0,0], closed=false
//       )
//   ) apply(left(max(column(slot,0))/2)*fwd(min(column(slot,1))), slot);
//   stroke(slot(15,29,7));
// Example: A cylindrical container with rounded edges and a rounded finger slot.
//   function slot(slotwidth, slotheight, slotradius) = let(
//       angle = 85,
//       slot = round_corners(
//           turtle([
//               "right",
//               "move", slotwidth,
//               "left", angle,
//               "move", 2*slotwidth,
//               "right", angle,
//               "move", slotheight,
//               "left",
//               "move", slotwidth,
//               "left",
//               "move", slotheight,
//               "right", angle,
//               "move", 2*slotwidth,
//               "left", angle,
//               "move", slotwidth
//           ]),
//           radius = [0,0,each repeat(slotradius,4),0,0], closed=false
//       )
//   ) apply(left(max(column(slot,0))/2)*fwd(min(column(slot,1))), slot);
//   diam = 80;
//   wall = 4;
//   height = 40;
//   rot(-90) {
//       $fn=128;
//       difference(){
//           cyl(d=diam, rounding=wall/2, h=height, anchor=BOTTOM);
//           up(wall)cyl(d=diam-2*wall, rounding1=wall, rounding2=-wall/2, h=height-wall+.01, anchor=BOTTOM);
//           bent_cutout_mask(diam/2-wall/2, wall+.1, subdivide_path(apply(back(10),slot(15, 29, 7)),250));
//       }
//   }
function bent_cutout_mask(r, thickness, path, radius, convexity=10) = no_function("bent_cutout_mask");
module bent_cutout_mask(r, thickness, path, radius, convexity=10)
{
  r = get_radius(r1=r, r2=radius);
  dummy1=assert(is_def(r) && r>0,"Radius of the cylinder to bend around must be positive");
  path2 = force_path(path);
  dummy2=assert(is_path(path2,2),"Input path must be a 2D path")
         assert(r-thickness>0, "Thickness too large for radius")
         assert(thickness>0, "Thickness must be positive");
  fixpath = clockwise_polygon(path2);
  curvepoints = arc(d=thickness, angle = [-180,0]);
  profiles = [for(pt=curvepoints) _cyl_hole(r+pt.x,apply(xscale((r+pt.x)/r), offset(fixpath,delta=thickness/2+pt.y,check_valid=false,closed=true)))];
  pathx = column(fixpath,0);
  minangle = (min(pathx)-thickness/2)*360/(2*PI*r);
  maxangle = (max(pathx)+thickness/2)*360/(2*PI*r);
  mindist = (r+thickness/2)/cos((maxangle-minangle)/2);
  dummy3 = assert(maxangle-minangle<180,"Cutout angle span is too large.  Must be smaller than 180.");
  zmean = mean(column(fixpath,1));
  innerzero = repeat([0,0,zmean], len(fixpath));
  outerpt = repeat( [1.5*mindist*cos((maxangle+minangle)/2),1.5*mindist*sin((maxangle+minangle)/2),zmean], len(fixpath));
  default_tag("remove")
    vnf_polyhedron(vnf_vertex_array([innerzero, each profiles, outerpt],col_wrap=true),convexity=convexity) children();
}



/*

join_prism To Do List:

special handling for planar joins?
   offset method
   cut, radius?
Access to the derivative smoothing parameter?   

*/



// Function&Module: join_prism()
// Synopsis: Join an arbitrary prism to a plane, sphere, cylinder or another arbitrary prism with a fillet.
// SynTags: Geom, VNF
// Topics: Rounding, Offsets
// See Also: offset_sweep(), convex_offset_extrude(), rounded_prism(), bent_cutout_mask(), join_prism()
// Usage: The two main forms with most common options
//   join_prism(polygon, base, length=|height=|l=|h=, fillet=, [base_T=], [scale=], [prism_end_T=], [short=], ...) [ATTACHMENTS];
//   join_prism(polygon, base, aux=, fillet=, [base_T=], [aux_T=], [scale=], [prism_end_T=], [short=], ...) [ATTACHMENTS];
// Usage: As function
//   vnf = join_prism( ... );
// Description:
//   This function creates a smooth fillet between one or both ends of an arbitrary prism and various other shapes: a plane, a sphere, a cylinder,
//   or another arbitrary prism.  The fillet is a continuous curvature rounding with a specified width/height.  This module is general
//   and therefore has a complex interface.  The examples below form a tutorial on how to use `join_prism` that steps
//   through the various options and how they affect the results.  Be sure to check the examples for help understanding how the various options work.
//   .
//   When joining between planes this function produces similar results to {{rounded_prism()}}.  This function works best when the prism
//   cross section is a continuous shape with a high sampling rate and without sharp corners.  If you have sharp corners you should consider
//   giving them a small rounding first.  When the prism cross section has concavities the fillet size is limited by the curvature of those concavities.
//   In contrast, {{rounded_prism()}} works best on a prism that has fewer points and does well with sharp corners, but may encounter problems
//   with a high sampling rate.  
//   .
//   You specify the prism by giving its cross section as a 2D path.  The cross section is always the orthogonal cross
//   section of the prism.  Depending on end conditions, the ends may not be perpendicular to the
//   axis of the prism, but the cross section you give *is* always perpendicular to that cross section.
// Figure(3D,Big,NoScales,VPR=[74.6, 0, 329.7], VPT=[28.5524, 35.3006, 22.522], VPD=325.228): The layout and terminology used by `join_prism`.  The "base object" is centered on the origin.  The "auxiliary object" (if present) is some distance away so there is room for the "joiner prism" to connect the two objects.  The blue line is the axis of the jointer prism.  It is at the origin of the shape you supply for defining that prism.  The "root" point of the joiner prism is the point where the prism axis intersects the base.  The prism end point is where the prism axis intersects the auxiliary object.  If you don't give an auxiliary object then the prism end point is distance `length` along the axis from the root.  
//   aT = right(-10)*back(0)*up(75)*xrot(-35)*zrot(75);
//   br = 17;
//   ar = 15;
//   xcyl(r=br, l=50, circum=true, $fn=64);
//   multmatrix(aT)right(15)xcyl(r=ar,circum=true,l=50,$fn=64);
//   %join_prism(circle(r=10), base = "cyl", base_r=br, aux="cyl", aux_r=ar, aux_T=aT,fillet=3);
//   root = [-2.26667, 0, 17];
//   rback = [15,0,25];
//   endpt =  [-7.55915, 0, 56.6937];
//   endback = [10,0,55];
//   stroke([root,endpt],
//          width=1,endcap_width=3,endcaps="dot",endcap_color="red",color="blue",$fn=16);
//   stroke(move(3*unit(rback-root), [rback,root]), endcap2="arrow2",width=1/2,$fn=16,color="black");
//   down(0)right(4)color("black")move(rback)rot($vpr)text("prism root point",size=4);
//   stroke(move(3*unit(endback-endpt), [endback,endpt]), endcap2="arrow2", width=1/2, $fn=16, color="black");
//   down(2)right(4)color("black")move(endback)rot($vpr)text("prism end point",size=4);
//   right(4)move(-20*[1,1])color("black")rot($vpr)text("base",size=8);
//   up(83)right(-10)move(-20*[1,1])color("black")rot($vpr)text("aux",size=8);
//   aend=[-13,13,30];
//   ast=aend+10*[-1,1,0];
//   stroke([ast,aend],endcap2="arrow2", width=1/2, color="black");
//   left(2)move(ast)rot($vpr)color("black")text("joiner prism",size=5,anchor=RIGHT);
// Continues:
//   You must include a base ("plane", "sphere", "cylinder", "cyl"), or a polygon describing the cross section of a base prism.  If you specify a
//   sphere or cylinder you must give `base_r` or `base_d` to specify the radius or diameter of the base object.  If you choose a cylinder or a polygonal
//   prism then the base object appears aligned with the X axis.  In the case of the planar base, the
//   joining prism has one end of its axis at the origin.  As shown above, the point where the joining prism attaches to its base is the "root" of the prism.
//   If you use some other base shape, the root is adjusted so that it is on the boundary of your shape.  This happens by finding the intersection
//   of the joiner prisms's axis and using that as the root.  By default the prism axis is parallel to the Z axis.  
//   .
//   You may give `base_T`, a rotation operator that is applied to the base.  This is
//   useful to tilt a planar or cylindrical base.  The `base_T` operator must be an origin-centered rotation like yrot(25).  
//   .
//   You may optionally specify an auxiliary shape.  When you do this, the joining prism connects the base to the auxiliary shape,
//   which must be one of "none", "plane", "sphere", "cyl", or "cylinder".  You can also set it to a polygon to create an arbitrary
//   prism for the auxiliary shape.  As is the case for the base, auxiliary cylinders and prisms appear oriented along the X axis.  
//   For a cylinder or sphere you must use `aux_r` or `aux_d` to specify the radius or diameter.
//   The auxiliary shape appears centered on the origin and is likely to be an invalid end location unless you translate it to a position
//   away from the base object.  The `aux_T` operator operates on the auxiliary object, and unlike `base_T` can be a rotation that includes translation
//   operations (or is a non-centered rotation).
//   .
//   When you specify an auxiliary object, the joiner prism axis is initially the line connecting the origin (the base center point) to the auxiliary
//   object center point.  The joiner prism end point is determined analogously to how the root is determined, by intersecting the joiner
//   prism axis with the auxiliary object.  Note that this means that if `aux_T` is a rotation it changes the joiner prism root, because
//   the rotated prism axis intersects the base in a different location.  If you do not give an auxiliary object then you must give
//   the length/height parameter to specify the prism length.  This gives the length of the prism measured from the root to the end point.
//   Note that the joint with a curved base may significantly extend the length of the joiner prism: its total length is often larger than
//   the length you request.  
//   .
//   For the cylinder and spherical objects you may wish to joint a prism to the concave surface.  You can do this by setting a negative
//   radius for the base or auxiliary object.  When `base_r` is negative, and the joiner prism axis is vertical, the prism root is **below** the
//   XY plane.  In this case it is actually possible to use the same object for base and aux and you can get a joiner prism that crosses a cylindrical
//   or spherical hole.  You can also attach to the inside of a prism object by setting the corresponding radius to a negative value.  Only the sign
//   matters in this case.  
//   .
//   When placing prisms inside a hole, an ambiguity can arise about how to identify the root and end of the joiner prism.  The prism axis has
//   two intersections with a cylinder and both are potentially valid roots.  When the auxiliary object is entirely inside the hole, or the auxiliary
//   object is a sphere or cylinder with negative radius that intersections the base, both prism directions produce a valid
//   joiner prism that meets the hole's concave surface, so two valid interpretations exist.  By default, the longer prism is returned.
//   You can select the shorter prism by setting `short=true`.  If you specify `short=true` when the base has a negative radius, but only one valid
//   prism exists, you get an error that doesn't clearly identify that a bogus `short=true` was the real cause.  
//   .
//   You can also alter your prism by using the `prism_end_T` operator which applies to the end point of the prism.  It does not effect
//   the root  of the prism.  The `prism_end_T` operator is applied in a coordinate system where the root of the
//   prism is the origin, so if you set it to a rotation, the prism base remains rooted at the same location and the prism rotates
//   in the specified fashion.  Applying `prism_end_T` likely results in the prism axis being different and the new end point not being on the auxiliary object, or the length of the prism may change.  Therefore, the end point is recalculated
//   to achieve the specified length (if aux is "none") or to contact the auxiliary object, if you have specified one.  This means, for example,
//   that setting `prism_end_T` to a scale operation doesn't change the result because it doesn't alter the prism axis.
//   .
//   A different way to specify the prism position is using the `start` and `end` parameters, which specify the axis of the prism's centerline.
//   You cannot combine `prism_end_T` with either `start` or `end`.  if you give only `start` then the prism's anchor point on the base
//   will be shifted but its direction will remain the same.  If you give only `end` then the prism's anchor point on the base remains
//   fixed (as computed based on the center-to-center line) and only the point on the auxiliary object moves.  
//   .
//   The size of the fillets is determined by the fillet, `fillet_base`, and `fillet_aux` parameters.  The fillet parameter controls both
//   ends of the prism, or you can set the ends independently.  The fillets must be nonnegative except when the prism joints a plane.
//   In this case a negative fillet gives a roundover.  In the case of no auxiliary object you can use `round_end` to round over the planar
//   far end of the joiner prism.  By default, the fillet is constructed using a method that produces a fillet with a uniform height along
//   the joiner prism.  This can be limiting when connectijng to objects with high curvature, so you can turn it off using the `uniform` option.
//   See the figures below for an explanation of the uniform and non-uniform filleting methods.  
//   .
//   The overlap is a potentially tricky parameter.  It specifies how much extra material to
//   create underneath the filleted prism so it overlaps the object that it joins to, ensuring valid unions.
//   For joins to convex objects you can choose a small value, but when joining to a concave object the overlap may need to be
//   large to ensure that the base of the joiner prism is well-behaved.  In such cases you may need to use an intersection
//   remove excess base.
//   .
//   When connecting to a base or auxiliary object that is a prism, the `smooth_normals` parameter controls how normals on that prism are
//   computed.  If `smooth_normals=true` (the default) then the normals are interpolated across the faces to create a more continuously varying normal.
//   This generally produces good results if the prism is a continous shape that is uniformly and finely sampled.  But if the shape has
//   large faces it can produce inferior or even incorrect results.  For example, {{prism_connector()}} makes connections to edges of objects
//   and must set `smooth_normals=false` to get correct results in this situation, or the constructed prism ends up hidden inside the object in
//   joins to.  If you create a prism that appears to suffer from this problem an informational (nonfatal) message will be displayed.
//   Note that the messages appears once for every problematic point in your joining profile.  
// Figure(2D,Med,NoAxes): Uniform fillet method.  This image shows how we construct a uniform fillet.  The pictures shows the cross section that is perpendicular to the prism.  The blue curve represents the base object surface.  The vertical line is the side of the prism.  To construct a fillet we travel along the surface of the base, following the curve, until we have moved the fillet length, `a`.  This defines the point `u`.  We then construct a tangent line to the base and find its intersection, `v`, with the prism.  Note that if the base is steeply curved, this tangent may fail to intersect, and the algorithm fails with an error because `v` does not exist.  Finally we locate `w` to be distance `a` above the point where the prism intersects the base object.  The fillet is defined by the `[u,v,w]` triple and is shown in red.  Note that with this method, the fillet is always height `a` above the base, so it makes a uniform curve parallel to the base object.  However, when the base curvature is more extreme, point `v` may end up above point `w`, resulting in an invalid configuration.  It also happens that point `v`, while below `w`, is close to `w`, so the resulting fillet has an abrupt angle near `w` instead of a smooth transition.  
//   R=60;
//   base = R*[cos(70),sin(70)];
//   end = R*[cos(45),sin(45)];
//   tang = [-sin(45),cos(45)];
//   isect = line_intersection([base,back(1,base)], [end,end+tang]);
//   toppt = base+[0,2*PI*R*25/360];
//   bez = _smooth_bez_fill([toppt, isect,end], 0.8);
//   color("red")
//     stroke(bezier_curve(bez,30,endpoint=true), width=.5);
//   color("blue"){
//      stroke(arc(n=50,angle=[35,80], r=R), width=1);
//      stroke([base, back(40,base)]);
//      move(R*[cos(35),sin(35)])text("Base", size=5,anchor=BACK);
//      back(1)move(base+[0,40]) text("Prism", size=5, anchor=FWD);
//   }
//   color([.3,1,.3]){
//     right(2)move(toppt)text("w",size=5);
//     right(2)move(end)text("u",size=5);
//     stroke([isect+[1,1/4], isect+[16,4]], width=.5, endcap1="arrow2");
//     move([16.5,3])move(isect)text("v",size=5);
//     stroke([end,isect],dots=true);
//     stroke([isect,toppt], dots=true);
//   }
//   color("black")  {
//      stroke(arc(n=50, angle=[45,70], r=R-3), color="black", width=.6, endcaps="arrow2");
//       move( (R-10)*[cos(57.5),sin(57.5)]) text("a",size=5);
//      left(3)move( base+[0,PI*R*25/360]) text("a", size=5,anchor=RIGHT);
//      left(2)stroke( [base, toppt],endcaps="arrow2",width=.6);
//   }
// Figure(2D,Med,NoAxes): Non-Uniform fillet method.  This method differs because point `w` is found by moving the fillet distance `a` starting at the intersection point `v` instead of at the base surface.  This means that the `[u,v,w]` triple is always in the correct order to produce a valid fillet.  However, the height of the fillet above the surface varies.  When the base concave, point `v` is below the surface of the base, which in more extreme cases can produce a fillet that goes below the base surface.  The uniform method is less likely to produce this kind of result.  When the base surface is a plane, the uniform and non-uniform methods are identical.
//   R=60;
//   base = R*[cos(70),sin(70)];
//   end = R*[cos(45),sin(45)];
//   tang = [-sin(45),cos(45)];
//   isect = line_intersection([base,back(1,base)], [end,end+tang]);
//   toppt = isect+[0,2*PI*R*25/360];
//   bez = _smooth_bez_fill([toppt, isect,end], 0.8);
//   color("red")stroke(bezier_curve(bez,30,endpoint=true), width=.5);
//   color("blue"){
//      stroke(arc(n=50,angle=[35,80], r=R), width=1);
//      stroke([base, back(40,base)]);
//      move(R*[cos(35),sin(35)])text("Base", size=5,anchor=BACK);
//      back(1)move(base+[0,40]) text("Prism", size=5, anchor=FWD);
//   }
//   color([.3,1,.3]){
//     right(2)move(toppt)text("w",size=5);
//     right(2)move(end)text("u",size=5);
//     stroke([isect+[1,1/4], isect+[16,4]], width=.5, endcap1="arrow2");
//     move([16.5,3])move(isect)text("v",size=5);
//     stroke([end,isect],dots=true);
//     stroke([isect,toppt], dots=true);
//   }
//   color("black")  {
//      stroke(arc(n=50, angle=[45,70], r=R-3), width=.6, endcaps="arrow2");
//      move( (R-10)*[cos(57.5),sin(57.5)]) text("a",size=5);
//      left(3)move( (isect+toppt)/2) text("a", size=5,anchor=RIGHT);
//      left(2)stroke( [isect, toppt],endcaps="arrow2",width=.6);
//   }
// Arguments:
//   polygon = polygon giving prism cross section
//   base = string specifying base object to join to ("plane","cyl","cylinder", "sphere") or a point list to use an arbitrary prism as the base.
//   ---
//   length / height / l / h = length/height of prism if aux=="none"
//   scale = scale factor for prism far end.  Default: 1
//   prism_end_T = root-centered arbitrary transform to apply to the prism's far point.  Default: IDENT
//   short = flip prism direction for concave sphere or cylinder base, when there are two valid prisms.  Default: false
//   base_T = origin-centered rotation operator to apply to the base
//   base_r / base_d = base radius or diameter if you picked sphere or cylinder
//   aux = string specifying auxilary object to connect to ("none", "plane", "cyl", "cylinder", or "sphere") or a point list to use an arbitrary prism.  Default: "none"
//   aux_T = rotation operator that may include translation when aux is not "none" to apply to aux
//   aux_r / aux_d = radius or diameter of auxiliary object if you picked sphere or cylinder
//   start = starting endpoint for the axis of the prism center
//   end = ending endpoint for the axis of the prism center
//   n = number of segments in the fillet at both ends.  Default: 15
//   base_n = number of segments to use in fillet at the base
//   aux_n = number of segments to use in fillet at the aux object
//   end_n = number of segments to use in roundover at the end of prism with no aux object
//   fillet = fillet for both ends of the prism (if applicable)  Must be nonnegative except for joiner prisms with planar ends
//   base_fillet = fillet for base end of prism 
//   aux_fillet = fillet for joint with aux object
//   end_round = roundover of end of prism with no aux object 
//   overlap = amount of overlap of prism fillet into objects at both ends.  Default: 1 for normal fillets, 0 for negative fillets and roundovers
//   base_overlap = amount of overlap of prism fillet into the base object
//   aux_overlap = amount of overlap of the prism fillet into aux object
//   k = fillet curvature parameter for both ends of prism
//   base_k = fillet curvature parameter for base end of prism
//   end_k / aux_k = fillet curvature parameter for end of prism where the aux object is
//   uniform = set to false to get non-uniform filleting at both ends (see Figures 2-3).  Default: true
//   base_uniform = set to false to get non-uniform filleting at the base
//   aux_uniform = set to false to get non-uniform filleting at the auxiliary object
//   smooth_normals = if true then smooth normals to the base and auxiliary objects when those objects are prisms.  If false do not smooth the normals. No effect for objects that are not prisms.  Default: true
//   base_smooth_normals = set to true or false to control smoothing of normals on the base prism object only
//   aux_smooth_normals = set to true or false to control smoothing of normals on the auxiliary prism object only
//   debug = set to true to allow return of various cases where self-intersection was detected
//   anchor = Translate so anchor point is at the origin.  (module only) Default: "origin"
//   spin = Rotate this many degrees around Z axis after anchor.  (module only) Default: 0
//   orient = Vector to rotate top toward after spin  (module only)
//   atype = Select "hull" or "intersect" anchor types.  (module only) Default: "hull"
//   cp = Centerpoint for determining "intersect" anchors or centering the shape.  Determintes the base of the anchor vector.  Can be "centroid", "mean", "box" or a 3D point.  (module only) Default: "centroid"
// Named Anchors:
//   "root" = Root point of the joiner prism, pointing out in the direction of the prism axis
//   "end" = End point of the joiner prism, pointing out in the direction of the prism axis
// Example(3D,NoScales): Here is the simplest case, a circular prism with a specified length standing vertically on a plane.  
//   join_prism(circle(r=15,$fn=60),base="plane",
//              length=18, fillet=3, n=12);
//   cube([50,50,5],anchor=TOP);
// Example(3D,NoScales): Here we substitute an abitrary prism. 
//   flower = [for(theta=lerpn(0,360,180,endpoint=false))
//             (15+1.3*sin(6*theta))*[cos(theta),sin(theta)]];
//   join_prism(flower,base="plane",length=18, fillet=3, n=12);
//   cube([50,50,5],anchor=TOP);
// Example(3D,NoScales): Here we apply a rotation of the prism, using prism_end_T, which rotates around the prism root.  Note that aux_T rotates around the origin, which is the same when the prism is joined to a plane.  
//   flower = [for(theta=lerpn(0,360,180,endpoint=false))
//             (15+1.3*sin(6*theta))*[cos(theta),sin(theta)]];
//   join_prism(flower,base="plane",length=18, fillet=3,
//              n=12, prism_end_T=yrot(25));
//   cube([50,50,5],anchor=TOP);
// Example(3D,NoScales): We can use `end_round` to get a roundover
//   flower = [for(theta=lerpn(0,360,180,endpoint=false))
//             (15+1.3*sin(6*theta))*[cos(theta),sin(theta)]];
//   join_prism(flower,base="plane",length=18, fillet=3,
//              n=12, prism_end_T=yrot(25), end_round=4);
//   cube([50,50,5],anchor=TOP);
// Example(3D,NoScales): We can tilt the base plane by applying a base rotation.  Note that because we did not tilt the prism, it still points upward.  
//   flower = [for(theta=lerpn(0,360,180,endpoint=false))
//             (15+1.3*sin(6*theta))*[cos(theta),sin(theta)]];
//   join_prism(flower,base="plane",length=18, fillet=3,
//              n=12, base_T=yrot(25));
//   yrot(25)cube([50,50,5],anchor=TOP);
// Example(3D,NoScales): Next consider attaching the prism to a sphere.  You must use a circumscribed sphere to avoid a lip or gap between the sphere and prism.  Note that the prism is attached to the sphere's boundary above the origin and projects by the specified length away from the attachment point.  
//   flower = [for(theta=lerpn(0,360,180,endpoint=false))
//             (15+1.3*sin(6*theta))*[cos(theta),sin(theta)]];
//   join_prism(flower,base="sphere",base_r=30, length=18,
//              fillet=3, n=12);
//   spheroid(r=30,circum=true,$fn=64);
// Example(3D,NoScales): Rotating using the prism_end_T option rotates around the attachment point.  Note that if you rotate too far, some points of the prism miss the sphere, which is an error.  
//   flower = [for(theta=lerpn(0,360,180,endpoint=false))
//             (15+1.3*sin(6*theta))*[cos(theta),sin(theta)]];
//   join_prism(flower,base="sphere",base_r=30, length=18,
//              fillet=3, n=12, prism_end_T=yrot(-15));
//   spheroid(r=30,circum=true,$fn=64);
// Example(3D,NoScales): Rotating using the aux_T option rotates around the origin.  You could get the same result in this case by rotating the whole model.  
//   flower = [for(theta=lerpn(0,360,180,endpoint=false))
//             (15+1.3*sin(6*theta))*[cos(theta),sin(theta)]];
//   join_prism(flower,base="sphere",base_r=30, length=18,
//              fillet=3, n=12, aux_T=yrot(-45));
//   spheroid(r=30,circum=true,$fn=64);
// Example(3D,NoScales): The origin in the prism cross section always aligns with the origin of the object you attach to.  If you want to attach off center, then shift your prism cross section.  If you shift too far so that parts of the prism miss the base object then you get an error.  
//   flower = [for(theta=lerpn(0,360,180,endpoint=false))
//             (15+1.3*sin(6*theta))*[cos(theta),sin(theta)]];
//   join_prism(right(10,flower),base="sphere",base_r=30,
//              length=18, fillet=3, n=12);
//   spheroid(r=30,circum=true,$fn=64);
// Example(3D,NoScales): The third available base shape is the cylinder.  
//   flower = [for(theta=lerpn(0,360,180,endpoint=false))
//             (15+1.3*sin(6*theta))*[cos(theta),sin(theta)]];
//   join_prism(flower,base="cylinder",base_r=30,
//              length=18, fillet=4, n=12); 
//   xcyl(r=30,l=75,circum=true,$fn=64);
// Example(3D,NoScales): You can rotate the cylinder the same way we rotated the plane.
//   flower = [for(theta=lerpn(0,360,180,endpoint=false))
//             (15+1.3*sin(6*theta))*[cos(theta),sin(theta)]];
//   join_prism(flower,base="cylinder",base_r=30, length=18,
//              fillet=4, n=12, base_T=zrot(33)); 
//   zrot(33)xcyl(r=30,l=75,circum=true,$fn=64);
// Example(3D,NoScales): And you can rotate the prism around its attachment point with prism_end_T
//   flower = [for(theta=lerpn(0,360,180,endpoint=false))
//             (15+1.3*sin(6*theta))*[cos(theta),sin(theta)]];
//   join_prism(flower,base="cylinder",base_r=30, length=18,
//              fillet=4, n=12, prism_end_T=yrot(22));
//   xcyl(r=30,l=75,circum=true,$fn=64);
// Example(3D,NoScales): Or you can rotate the prism around the origin with aux_T
//   flower = [for(theta=lerpn(0,360,180,endpoint=false))
//             (15+1.3*sin(6*theta))*[cos(theta),sin(theta)]];
//   join_prism(flower,base="cylinder",base_r=30, length=18,
//              fillet=4, n=12, aux_T=xrot(22));
//   xcyl(r=30,l=75,circum=true,$fn=64);
// Example(3D,NoScales): Here's a prism where the scale changes
//   flower = [for(theta=lerpn(0,360,180,endpoint=false))
//             (15+1.3*sin(6*theta))*[cos(theta),sin(theta)]];
//   join_prism(flower,base="cylinder",base_r=30, length=18,
//              fillet=4, n=12,scale=.5);
//   xcyl(r=30,l=75,circum=true,$fn=64);
// Example(3D,NoScales,VPD=190,VPR=[61.3,0,69.1],VPT=[41.8956,-9.49649,4.896]): Giving a negative radius attaches to the inside of a sphere or cylinder.  Note you want the inscribed cylinder for the inner wall.  
//   flower = [for(theta=lerpn(0,360,180,endpoint=false))
//             (15+1.3*sin(6*theta))*[cos(theta),sin(theta)]];
//   join_prism(flower,base="cylinder",base_r=-30, length=18,
//              fillet=4, n=12);
//   bottom_half(z=-10)
//     tube(ir=30,wall=3,l=74,$fn=64,orient=RIGHT,anchor=CENTER);
// Example(3D,NoScales,VPD=140,VPR=[72.5,0,73.3],VPT=[40.961,-19.8319,-3.03302]): A hidden problem lurks with concave attachments.  The bottom of the prism does not follow the curvature of the base.  Here you can see a gap.  In some cases you can create a self-intersection in the prism.  
//   flower = [for(theta=lerpn(0,360,180,endpoint=false))
//             (15+1.3*sin(6*theta))*[cos(theta),sin(theta)]];
//   left_half(){
//     join_prism(flower,base="cylinder",base_r=-30, length=18,
//                fillet=4, n=12);
//     bottom_half(z=-10)
//       tube(ir=30,wall=3,l=74,$fn=64,orient=RIGHT,anchor=CENTER);
//   }
// Example(3D,NoScales,VPD=140,VPR=[72.5,0,73.3],VPT=[40.961,-19.8319,-3.03302]): The solution to both problems is to increase the overlap parameter, but you may then have excess base that must be differenced or intersected away.  In this case, an overlap of 2 is sufficient to eliminate the hole.  
//   flower = [for(theta=lerpn(0,360,180,endpoint=false))
//             (15+1.3*sin(6*theta))*[cos(theta),sin(theta)]];
//   left_half(){
//     join_prism(flower,base="cylinder",base_r=-30, length=18,
//                fillet=4, n=12, overlap=2);     
//     bottom_half(z=-10)
//       tube(ir=30,wall=3,l=74,$fn=64,orient=RIGHT,anchor=CENTER);
//   }
// Example(3D,NoScales,VPD=126,VPR=[76.7,0,111.1],VPT=[6.99093,2.52831,-14.8461]): Here is an example with a spherical base.  This overlap is near the minimum required to eliminate the gap, but it creates a large excess structure around the base of the prism.  
//   flower = [for(theta=lerpn(0,360,180,endpoint=false))
//             (15+1.3*sin(6*theta))*[cos(theta),sin(theta)]];
//   left_half(){
//     join_prism(flower,base="sphere",base_r=-30, length=18,
//                fillet=4, n=12, overlap=7);
//     bottom_half(z=-10) difference(){
//       sphere(r=33,$fn=16);
//       sphere(r=30,$fn=64);
//     }
//   }
// Example(3D,NoScales,VPD=126,VPR=[55,0,25],VPT=[1.23541,-1.80334,-16.9789]): Here is the previous example with the excess structure differenced away. 
//   flower = [for(theta=lerpn(0,360,180,endpoint=false))
//             (15+1.3*sin(6*theta))*[cos(theta),sin(theta)]];
//   intersection(){
//     union(){
//       join_prism(flower,base="sphere",base_r=-30, length=18, 
//                  fillet=4, n=12, overlap=7);
//       difference(){
//         down(18)cuboid([68,68,30],anchor=TOP);
//         sphere(r=30,$fn=64);
//       }
//     }
//     sphere(r=33,$fn=16);
//   }
// Example(3D,NoScales,VPD=126,VPR=[55,0,25],VPT=[1.23541,-1.80334,-16.9789]): As before, rotating with aux_T rotates around the origin. 
//   flower = [for(theta=lerpn(0,360,180,endpoint=false))
//             (15+1.3*sin(6*theta))*[cos(theta),sin(theta)]];
//   intersection(){
//     union(){
//       join_prism(flower,base="sphere",base_r=-30, length=18,
//                  fillet=4, n=12, overlap=7, aux_T=yrot(13));
//       difference(){
//         down(18)cuboid([68,68,30],anchor=TOP);
//         sphere(r=30,$fn=64);
//       }
//     }
//     sphere(r=33,$fn=16);
//   }
// Example(3D,NoScales,VPD=102.06,VPR=[55,0,25],VPT=[3.96744,-2.80884,-19.9293]): Rotating with prism_end_T rotates around the attachment point.  We shrank the prism to allow a significant rotation.
//   flower = [for(theta=lerpn(0,360,180,endpoint=false))
//             (15+1.3*sin(6*theta))*[cos(theta),sin(theta)]];
//   intersection(){
//     union(){
//       join_prism(scale(.5,flower),base="sphere",base_r=-30,
//                  length=18, fillet=2, n=12, overlap=7,
//                  prism_end_T=yrot(25));
//       difference(){
//         down(23)cuboid([68,68,30],anchor=TOP);
//         sphere(r=30,$fn=64);
//       }
//     }
//     sphere(r=33,$fn=16);
//   }
// Example(3D,NoScales,VPR=[65.5,0,105.3],VPT=[8.36329,13.0211,9.98397],VPD=237.091): You can create a prism that crosses the inside of a cylinder or sphere by giving the same negative radius twice and leaving both objects with the same center, as shown here.  
//   left_half(x=7){
//     join_prism(circle(r=15),base="cylinder",base_r=-30, n=12,
//                aux="cylinder", aux_r=-30, fillet=8, overlap=3);
//     tube(ir=30,wall=5,l=74,$fn=64,orient=RIGHT,anchor=CENTER);     
//   }
// Example(3D,NoScales,VPR=[65.5,0,105.3],VPT=[8.36329,13.0211,9.98397],VPD=237.091): Here's a similar example with a plane for the auxiliary object.  Note that we observe the 1 unit overlap on the top surface.  
//   left_half(x=7){
//     join_prism(circle(r=15),base="cylinder",base_r=-30,
//                aux="plane", fillet=8, n=12, overlap=3);
//     tube(ir=30,wall=5,l=74,$fn=64,orient=RIGHT,anchor=CENTER);     
//   }
// Example(3D,NoScales,VPR=[65.5,0,105.3],VPT=[8.36329,13.0211,9.98397],VPD=237.091): We have tweaked the previous example just slightly by lowering the height of the plane.  The result is a bit of a surprise:  the prism flips upside down!  This happens because there is an ambiguity in creating a prism between a plane and the inside of the cylinder.  By default, this ambiguity is resolved by choosing the longer prism.  
//   left_half(x=7){
//     join_prism(circle(r=15),base="cylinder",base_r=-30, n=12,
//                aux="plane", aux_T=down(5), fillet=8, overlap=3);
//     tube(ir=30,wall=5,l=74,$fn=64,orient=RIGHT,anchor=CENTER);     
//   }
// Example(3D,NoScales,VPR=[65.5,0,105.3],VPT=[8.36329,13.0211,9.98397],VPD=237.091): Adding `short=true` resolves the ambiguity of which prism to construct in the other way, by choosing the shorter option.  
//   left_half(x=7){
//     join_prism(circle(r=15),base="cylinder",base_r=-30,
//                aux="plane", aux_T=down(5), fillet=8,
//                n=12, overlap=3, short=true);
//     tube(ir=30,wall=5,l=74,$fn=64,orient=RIGHT,anchor=CENTER);
//   }
// Example(3D,NoScales,VPR=[85.1,0,107.4],VPT=[8.36329,13.0211,9.98397],VPD=237.091): The problem does not arise in this case because the auxiliary object only allows one possible way to make the connection. 
//   left_half(x=7){
//     join_prism(circle(r=15),base="cylinder",base_r=-30,
//                aux="cylinder", aux_r=30, aux_T=up(20),
//                fillet=8, n=12, overlap=3);
//     tube(ir=30,wall=5,l=74,$fn=64,orient=RIGHT,anchor=CENTER);
//     up(20)xcyl(r=30,l=74,$fn=64);
//   }
// Example(3D,NoScales,VPT=[-1.23129,-3.61202,-0.249883],VPR=[87.9,0,295.7],VPD=213.382): When the aux cylinder is inside the base cylinder we can select the two options, shown here as red for the default and blue for the `short=true` case. 
//   color("red")
//     join_prism(circle(r=5),base="cylinder",base_r=-30, 
//                aux="cyl",aux_r=10, aux_T=up(12), fillet=4,
//                 n=12, overlap=3, short=false);
//   color("blue")
//     join_prism(circle(r=5),base="cylinder",base_r=-30, 
//                aux="cyl",aux_r=10, aux_T=up(12), fillet=4,
//                n=12, overlap=3, short=true);
//   tube(ir=30,wall=5,$fn=64,l=18,orient=RIGHT,anchor=CENTER);
//   up(12)xcyl(r=10, circum=true, l=18);
// Example(3D,NoScales,VPR=[94.9,0,106.7],VPT=[4.34503,1.48579,-2.32228],VPD=237.091): The same thing is true when you use a negative radius for the aux cylinder. This is the default long case.  
//   join_prism(circle(r=5,$fn=64),base="cylinder",base_r=-30, 
//              aux="cyl",aux_r=-10, aux_T=up(12), fillet=4,
//              n=12, overlap=3, short=false);
//   tube(ir=30,wall=5,l=24,$fn=64,orient=RIGHT,anchor=CENTER);
//   up(12) top_half()
//      tube(ir=10,wall=4,l=24,$fn=64,orient=RIGHT,anchor=CENTER);
// Example(3D,NoScales,VPR=[94.9,0,106.7],VPT=[4.34503,1.48579,-2.32228],VPD=237.091): And here is the short case:
//   join_prism(circle(r=5,$fn=64),base="cylinder",base_r=-30, 
//              aux="cyl",aux_r=-10, aux_T=up(12), fillet=4,
//              n=12, overlap=3, short=true);
//   tube(ir=30,l=24,wall=5,$fn=64,orient=RIGHT,anchor=CENTER);
//   up(12) bottom_half()
//     tube(ir=10,wall=4,l=24,$fn=64,orient=RIGHT,anchor=CENTER);
// Example(3D,NoScales,VPR=[94.9,0,106.7],VPT=[0.138465,6.78002,24.2731],VPD=325.228): Another example where the cylinders overlap, with the long case here:
//   auxT=up(40);
//   join_prism(circle(r=5,$fn=64),base="cylinder",base_r=-30, 
//              aux="cyl",aux_r=-40, aux_T=auxT, fillet=4,
//              n=12, overlap=3, short=false);
//   tube(ir=30,wall=4,l=24,$fn=64,orient=RIGHT,anchor=CENTER);
//   multmatrix(auxT)
//     tube(ir=40,wall=4,l=24,$fn=64,orient=RIGHT,anchor=CENTER);
// Example(3D,NoScales,VPR=[94.9,0,106.7],VPT=[0.138465,6.78002,24.2731],VPD=325.228): And the short case:
//   auxT=up(40);
//   join_prism(circle(r=5,$fn=64),base="cylinder",base_r=-30, 
//              aux="cyl",aux_r=-40, aux_T=auxT, fillet=4,
//              n=12, overlap=3, short=true);
//   tube(ir=30,wall=4,l=24,$fn=64,orient=RIGHT,anchor=CENTER);
//   multmatrix(auxT)
//     tube(ir=40,wall=4,l=24,$fn=64,orient=RIGHT,anchor=CENTER);
// Example(3D,NoScales): Many of the preceeding examples feature a prism with a concave shape cross section.  Concave regions can limit the amount of rounding that is possible.  This occurs because the algorithm is not able to handle a fillet that intersects itself.  Fillets on a convex prism always grow larger as they move away from the prism, so they cannot self intersect.  This means that you can make the fillet as big as can fit on the base shape.  The fillet fails to fit if the tangent plane to the base at the fillet distance from the prism fails to intersect the prism.  Here is an extreme example, almost the largest possible fillet to the convex elliptical convex prism.  
//   ellipse = ellipse([17,10],$fn=164);  
//   join_prism(ellipse,base="sphere",base_r=30, length=18,
//              fillet=18, n=25, overlap=1);
//   spheroid(r=30,circum=true, $fn=96);
// Example(3D,NoScales): This example shows a failed rounding attempt where the result is self-intersecting.  Using the `debug=true` option makes it possible to view the result to understand what went wrong.  Note that the concave corners have a crease where the fillet crosses itself.  The error message advises you to decrease the size of the fillet.  You can also fix the problem by making your concave curves shallower.  
//   flower = [for(theta=lerpn(0,360,180,endpoint=false))
//             (15+2.5*sin(6*theta))*[cos(theta),sin(theta)]];
//   join_prism(flower,base="cylinder",base_r=30, length=18,
//              fillet=6, n=12, debug=true); 
// Example(3D,NoScales): Your prism needs to be finely sampled enough to follow the contour of the base you are attaching it to.  If it is not, you get a result like this.  The fillet joints the prism smoothly, but makes a poor transition to the sphere. 
//   sq = rect(15);
//   join_prism(sq, base="sphere", base_r=25,
//              length=18, fillet=4, n=12);
//   spheroid(r=25, circum=true, $fn=96);
// Example(3D,NoScales): To fix the problem, you must subdivide the polygon that defines the prism.  But note that the join_prism method works poorly at sharp corners.
//   sq = subdivide_path(rect(15),n=64);
//   join_prism(sq, base="sphere", base_r=25,
//              length=18, fillet=4, n=12);
//   spheroid(r=25, circum=true,$fn=96);
// Example(3D,NoScales): In the previous example, a small rounding of the prism corners produces a nicer result.
//   sq = subdivide_path(
//          round_corners(rect(15),cut=.5,$fn=32),
//          n=128);
//   join_prism(sq, base="sphere", base_r=25,
//              length=18, fillet=4, n=12);
//   spheroid(r=25, circum=true,$fn=96);
// Example(3D,NoScales): The final option for specifying the base is to use an arbitrary prism, specified by a polygon.  Note that the base prism is oriented to the RIGHT, so the attached prism remains Z oriented.  
//   ellipse = ellipse([17,10],$fn=164);  
//   join_prism(zrot(90,ellipse), base=2*ellipse, length=19,
//              fillet=4, n=12);
//   linear_sweep(2*ellipse,height=60, center=true, orient=RIGHT);
// Example(3D,NoScales): As usual, you can rotate around the attachment point using prism_end_T. 
//   ellipse = ellipse([17,10],$fn=164);  
//   join_prism(zrot(90,ellipse), base=2*ellipse, length=19,
//              fillet=4, n=12, prism_end_T=yrot(22));
//   linear_sweep(2*ellipse,height=60, center=true, orient=RIGHT);
// Example(3D,NoScales): And you can rotate around the origin with aux_T.
//   ellipse = ellipse([17,10],$fn=164);  
//   join_prism(zrot(90,ellipse), base=2*ellipse, length=19,
//              fillet=4, n=12, aux_T=yrot(22));
//   linear_sweep(2*ellipse,height=60, center=true, orient=RIGHT);
// Example(3D,NoScales): The base prism can be a more complicated shape.
//   flower = [for(theta=lerpn(0,360,180,endpoint=false))
//             (15+1.3*sin(6*theta))*[cos(theta),sin(theta)]];
//   join_prism(flower,base=1.4*flower, fillet=3,
//              n=15, length=20);
//   linear_sweep(1.4*flower,height=60,center=true,
//                convexity=10,orient=RIGHT);
// Example(3D,NoScales): Here's an example with both prism_end_T and aux_T 
//   flower = [for(theta=lerpn(0,360,180,endpoint=false))
//             (15+1.3*sin(6*theta))*[cos(theta),sin(theta)]];
//   join_prism(flower,base=1.4*flower, length=20,
//              prism_end_T=yrot(20),aux_T=xrot(10),
//              fillet=3, n=25);
//   linear_sweep(1.4*flower,height=60,center=true,
//                convexity=10,orient=RIGHT);
// Example(3D,NoScales): The same example as above with `smooth_normals=false` produces a banding pattern in the fillet.  
//   flower = [for(theta=lerpn(0,360,180,endpoint=false))
//             (15+1.3*sin(6*theta))*[cos(theta),sin(theta)]];
//   join_prism(flower,base=1.4*flower, length=20,
//              prism_end_T=yrot(20),aux_T=xrot(10),
//              fillet=3, n=25,smooth_normals=false);
//   linear_sweep(1.4*flower,height=60,center=true,
//                convexity=10,orient=RIGHT);
// Example(3D,NoScales,VPR=[78,0,42],VPT=[12.45,-12.45,10.4],VPD=130): Instead of terminating your prism in a flat face perpendicular to its axis you can attach it to a second object.  The simplest case is to connect to planar attachments.  When connecting to a second object you must position and orient the second object using aux_T, which is now allowed to be a rotation and translation operator.  The `length` parameter is no longer allowed.  
//   flower = [for(theta=lerpn(0,360,180,endpoint=false))
//             (15+1.3*sin(6*theta))*[cos(theta),sin(theta)]];
//   join_prism(flower,base="plane", fillet=4, n=12,
//              aux="plane", aux_T=up(12));
//   %up(12)cuboid([40,40,4],anchor=BOT); 
//   cuboid([40,40,4],anchor=TOP);
// Example(3D,NoScales,VPR=[78,0,42],VPT=[12.45,-12.45,10.4],VPD=130): Here's an example where the second object is rotated.  The prism goes from the origin to the origin point of the object.  In this case because the rotation is applied first, the prism is vertical.  
//   flower = [for(theta=lerpn(0,360,180,endpoint=false))
//             (15+1.3*sin(6*theta))*[cos(theta),sin(theta)]];
//   aux_T = up(12)*xrot(-22);
//   join_prism(flower,base="plane",fillet=2.75, n=12,
//              aux="plane", aux_T=aux_T); 
//   multmatrix(aux_T)cuboid([42,42,4],anchor=BOT);
//   cuboid([40,40,4],anchor=TOP);
// Example(3D,NoScales,VPR=[78,0,42],VPT=[12.45,-12.45,10.4],VPD=130): In this example, the aux_T transform moves the centerpoint (origin) of the aux object, and the resulting prism connects centerpoints, so it is no longer vertical. 
//   flower = [for(theta=lerpn(0,360,180,endpoint=false))
//             (15+1.3*sin(6*theta))*[cos(theta),sin(theta)]];
//   aux_T = xrot(-22)*up(12);
//   join_prism(flower,base="plane",fillet=2.75, n=12,
//              aux="plane", aux_T=aux_T);
//   multmatrix(aux_T)cuboid([42,42,4],anchor=BOT);
//   cuboid([43,43,4],anchor=TOP);
// Example(3D,NoScales,VPR=[78,0,42],VPT=[9.95,-9.98,13.0],VPD=142]): You can combine with base_T
//   flower = [for(theta=lerpn(0,360,180,endpoint=false))
//             (15+1.3*sin(6*theta))*[cos(theta),sin(theta)]];
//   aux_T = xrot(-22)*up(22);
//   base_T = xrot(5)*yrot(-12);
//   join_prism(flower,base="plane",base_T=base_T, 
//              aux="plane",aux_T=aux_T, fillet=4, n=12);
//   multmatrix(aux_T)cuboid([42,42,4],anchor=BOT);
//   multmatrix(base_T)cuboid([45,45,4],anchor=TOP);
// Example(3D,NoScales,VPR=[76.6,0,29.4],VPT=[11.4009,-8.43978,16.1934],VPD=157.778): Using prism_end_T shifts the prism's end without tilting the plane, so the prism ends are not perpendicular to the prism axis.  
//   flower = [for(theta=lerpn(0,360,180,endpoint=false))
//             (15+1.3*sin(6*theta))*[cos(theta),sin(theta)]];
//   join_prism(flower,base="plane", prism_end_T=right(14),
//              aux="plane",aux_T=up(24), fillet=4, n=12);
//   right(7){
//     %up(24)cuboid([65,42,4],anchor=BOT);
//     cuboid([65,42,4],anchor=TOP);
//   }
// Example(3D,NoAxes,NoScales,VPR=[101.9, 0, 205.6], VPT=[5.62846, -5.13283, 12.0751], VPD=102.06): Negative fillets give roundovers and are pemitted only for joints to planes.  Note that overlap defaults to zero for negative fillets.  
//   flower = [for(theta=lerpn(0,360,180,endpoint=false))
//             (15+1.3*sin(6*theta))*[cos(theta),sin(theta)]];
//   aux_T = xrot(-22)*up(22);
//   base_T = xrot(5)*yrot(-12);
//   join_prism(flower,base="plane",base_T=base_T,
//              aux="plane", aux_T=aux_T, fillet=-4,n=12);
// Example(3D,NoScales,VPR=[84,0,21],VPT=[13.6,-1,46.8],VPD=446): It works the same way with the other shapes, but make sure you move the shapes far enough apart that there is room for a prism.  
//   flower = [for(theta=lerpn(0,360,180,endpoint=false))
//             (15+1.3*sin(6*theta))*[cos(theta),sin(theta)]];
//   aux_T = up(85);
//   base_T = xrot(5)*yrot(-12);
//   join_prism(flower,base="cylinder",base_r=25, fillet=4, n=12,
//              aux="sphere",aux_r=35,base_T=base_T, aux_T=aux_T);
//   multmatrix(aux_T)spheroid(35,circum=true);
//   multmatrix(base_T)xcyl(l=75,r=25,circum=true);
// Example(3D,NoScales,VPR=[84,0,21],VPT=[13.6,-1,46.8],VPD=446): Here we translate the sphere to the right and the prism goes with it
//   flower = [for(theta=lerpn(0,360,180,endpoint=false))
//             (15+1.3*sin(6*theta))*[cos(theta),sin(theta)]];
//   aux_T = right(40)*up(85);
//   join_prism(flower,base="cylinder",base_r=25, n=12,
//              aux="sphere",aux_r=35, aux_T=aux_T, fillet=4);
//   multmatrix(aux_T)spheroid(35,circum=true);
//   xcyl(l=75,r=25,circum=true);
// Example(3D,NoScales,VPR=[84,0,21],VPT=[13.6,-1,46.8],VPD=446): This is the previous example with the prism_end_T transformation used to shift the far end of the prism away from the sphere center.  Note that prism_end_T can be any transformation, but it just acts on the location of the prism endpoint to shift the direction the prism points.  
//   flower = [for(theta=lerpn(0,360,180,endpoint=false))
//             (15+1.3*sin(6*theta))*[cos(theta),sin(theta)]];
//   aux_T = right(40)*up(85);
//   join_prism(flower,base="cylinder",base_r=25,
//              prism_end_T=left(4), fillet=3, n=12, 
//              aux="sphere",aux_r=35, aux_T=aux_T); 
//   multmatrix(aux_T)spheroid(35,circum=true);
//   xcyl(l=75,r=25,circum=true);
// Example(3D,NoScales,VPR=[96.9,0,157.5],VPT=[-7.77616,-2.272,37.9424],VPD=366.527): Here the base is a cylinder but the auxilary object is a generic prism, and the joiner prism has a scale factor.  
//   flower = [for(theta=lerpn(0,360,180,endpoint=false))
//             (15+1.3*sin(6*theta))*[cos(theta),sin(theta)]];
//   aux_T = up(85)*zrot(-75);
//   ellipse = ellipse([17,10],$fn=164);  
//   join_prism(flower,base="cylinder",base_r=25,
//              fillet=4, n=12,
//              aux=ellipse, aux_T=aux_T,scale=.5);
//   multmatrix(aux_T)
//     linear_sweep(ellipse,orient=RIGHT,height=75,center=true);
//   xcyl(l=75,r=25,circum=true,$fn=100);
// Example(3D,NoAxes,VPT=[10.0389,1.71153,26.4635],VPR=[89.3,0,39],VPD=237.091): Base and aux are both a general prism in this case.
//   ellipse = ellipse([10,17]/2,$fn=96);  
//   flower = [for(theta=lerpn(0,360,180,endpoint=false))
//             (15+1.3*sin(6*theta))*[cos(theta),sin(theta)]];
//   aux_T=up(50);   
//   join_prism(ellipse,base=flower,aux_T=aux_T,aux=flower,
//              fillet=3, n=12, prism_end_T=right(9));
//   multmatrix(aux_T)
//     linear_sweep(flower,height=60,center=true,orient=RIGHT);
//   linear_sweep(flower,height=60,center=true,orient=RIGHT);
// Example(3D,NoAxes,VPT=[8.57543,0.531762,26.8046],VPR=[89.3,0,39],VPD=172.84): Shifting the joiner prism forward brings it close to a steeply curved edge of the auxiliary prism at the top.  Note that a funny looking bump with a sharp corner has appeared in the fillet.  This bump/corner is a result of the uniform filleting method running out of space.  If we move the joiner prism farther forward, the algorithm fails completely.  
//   ellipse = ellipse([10,17]/2,$fn=96);  
//   flower = [for(theta=lerpn(0,360,180,endpoint=false))
//             (15+1.3*sin(6*theta))*[cos(theta),sin(theta)]];
//   aux_T=up(50);   
//   join_prism(ellipse,base=flower,aux_T=aux_T,aux=flower,
//              fillet=3, n=12, prism_end_T=fwd(1.6));
//   multmatrix(aux_T)
//     linear_sweep(flower,height=60,center=true,orient=RIGHT);
//   linear_sweep(flower,height=60,center=true,orient=RIGHT);
// Example(3D,NoAxes,VPT=[8.57543,0.531762,26.8046],VPR=[89.3,0,39],VPD=172.84): This is the same example as above but with uniform turned off.  Note how the line the fillet makes on the joiner prism is not uniform, but the overall curved shape is more pleasing than the previous result, and we can bring the joiner prism a little farther forward and still construct a model. 
//   ellipse = ellipse([10,17]/2,$fn=96);  
//   flower = [for(theta=lerpn(0,360,180,endpoint=false))
//             (15+1.3*sin(6*theta))*[cos(theta),sin(theta)]];
//   aux_T=up(50);   
//   join_prism(ellipse,base=flower,aux_T=aux_T,aux=flower,
//              fillet=3, n=12, prism_end_T=fwd(1.7),
//              uniform=false);
//   multmatrix(aux_T)
//     linear_sweep(flower,height=60,center=true,orient=RIGHT);
//   linear_sweep(flower,height=60,center=true,orient=RIGHT);
// Example(3D,NoScales): By setting the base and auxiliary to the same thing you can create a hole cutting mask with rounded ends.  
//   difference(){
//     spheroid(r=30,circum=true);    
//     join_prism(circle(r=15),base="sphere",base_r=-30, n=15,
//                aux="sphere",aux_r=-30,fillet=8, overlap=17);
//   }
// Example(3D,VPT=[0.59633,-3.01826,-3.89606],VPR=[129.2,0,26.4],VPD=192.044,NoScales): Here we have rotated the auxiliary sphere, resulting in a hole that is off-center through the sphere.  Because we rotate the auxiliary object, both ends of the prism have moved.  Note that setting k to a large value better matches the bezier curve to the curvature of the sphere, resulting in a better result.  
//   difference(){
//     spheroid(r=30,circum=true);    
//     join_prism(circle(r=15),base="sphere",base_r=-30, n=15,
//                aux="sphere",aux_T=xrot(30), aux_r=-30,fillet=8, overlap=17, k=0.9);
//   }
// Example(3D,VPT=[-12.5956,-5.1125,-0.322237],VPR=[82.3,0,116.7],VPD=213.382,NoScales): Here we adjust just the auxiliary end, which is at the bottom.  We rotate it by 45 deg, but this rotation would normally be relative to the other prism end, so we add a centerpoint based on the radius so that the rotation is relative to the sphere center instead.
//   difference(){
//     spheroid(r=30,circum=true);    
//     join_prism(circle(r=15),base="sphere",base_r=-30, n=15,
//                aux="sphere",prism_end_T=xrot(45,cp=[0,0,-30]), aux_r=-30,fillet=8, overlap=17, k=0.9);               
//   }
// Example(3D,NoScales,VPT=[12.3373,11.6037,-1.87883],VPR=[40.3,0,323.4],VPD=292.705): A diagonal hole through a cylinder with rounded ends, created by shifting the auxiliary prism end along the prism length.  
//   back_half(200)
//     difference(){
//       right(15)xcyl(r=30,l=100,circum=true); 
//       join_prism(circle(r=15),base="cyl",base_r=-30, n=15,
//                  aux="cyl",prism_end_T=right(35),aux_r=-30,fillet=7, overlap=17);
//     }
// Example(3D,NoScales,VPT=[-7.63774,-0.808304,13.8874],VPR=[46.6,0,71.2],VPD=237.091): A hole created by shifting along prism width.  
//   left_half()
//     difference(){
//       xcyl(r=30,l=100,circum=true); 
//       join_prism(circle(r=15),base="cyl",base_r=-30, n=15,
//                  aux="cyl",prism_end_T=fwd(9),aux_r=-30,fillet=7, overlap=17);
//     }
// Example(3D,NoScales,VPT=[1.99307,-2.05618,-0.363144],VPR=[64.8,0,15],VPD=237.091): Shifting the auxiliary cylinder changes both ends of the prism
//   back_half(200)
//      difference(){
//         xcyl(r=30,l=100,circum=true); 
//         join_prism(circle(r=15),base="cyl",base_r=-30, n=15,
//                    aux="cyl",aux_T=right(20),aux_r=-30,fillet=7, overlap=17);
//      }
// Example(3D): Positioning a joiner prism as an attachment
//   cuboid([20,30,40])
//     attach(RIGHT,"root")
//       join_prism(circle(r=8,$fn=32),
//                  l=10, base="plane", fillet=4);
// Example(3D,NoScales,VPR=[47.3,0,14.5],VPT=[-2.8467,-2.05938,-10.6999],VPD=220): Two join_prism objects are placed on the parent cylinder using anchors, and then their descriptions are used to contruct a curved handle with a bezier.
//   $fs=.5; $fa=4;
//   vspace=25;
//   bezlen=40;
//   cylr=20;
//   straightlen=10;
//   circ = circle(r=6);
//   cyl(r=cylr,h=50, rounding=3)
//     let(cyl=parent())
//       down(vspace/2)
//       attach(RIGHT+FWD, "root", spin=90)
//         join_prism(circ, base="cyl", base_r=20, height=straightlen, fillet=4)
//         let(base1=parent())
//     restore(cyl)
//       up(vspace/2)
//       attach(LEFT+FWD, "root", spin=90)
//         join_prism(circ, base="cyl", base_r=20, height=straightlen, fillet=4)
//           let(base2=parent())
//     let(
//         avg_dir = desc_dir(base1,anchor=TOP)+desc_dir(base2,anchor=TOP),
//         bez=[
//           desc_point(base1,anchor=TOP),
//           desc_point(base1,anchor=TOP)+bezlen*desc_dir(base1,anchor=TOP),
//           (cylr+straightlen+bezlen)*avg_dir,
//           desc_point(base2,anchor=TOP)+bezlen*desc_dir(base2,anchor=TOP),
//           desc_point(base2,anchor=TOP)]
//       )
//       path_sweep(circ,bezier_curve(bez,40));

module join_prism(polygon, base, base_r, base_d, base_T=IDENT,
                    scale=1, prism_end_T=IDENT, short=false, 
                    length, l, height, h,
                    aux="none", aux_T=IDENT, aux_r, aux_d,
                    overlap, base_overlap,aux_overlap,
                    n=15, base_n, end_n, aux_n,
                    fillet, base_fillet,aux_fillet,end_round,
                    k=0.7, base_k,aux_k,end_k,start,end,
                    uniform=true, base_uniform, aux_uniform,
                    smooth_normals=true, base_smooth_normals, aux_smooth_normals, 
                    debug=false, anchor="origin", extent=true, cp="centroid", atype="hull", orient=UP, spin=0,
                    convexity=10,_name1="base",_name2="aux")
{
    assert(in_list(atype, _ANCHOR_TYPES), "Anchor type must be \"hull\" or \"intersect\"");
    vnf_start_end = join_prism(polygon,base, base_r=base_r, base_d=base_d, base_T=base_T,
                   scale=scale, prism_end_T=prism_end_T, short=short,
                   length=length, l=l, height=height, h=h,
                   aux=aux, aux_T=aux_T, aux_r=aux_r, aux_d=aux_d,
                   overlap=overlap, base_overlap=base_overlap, aux_overlap=aux_overlap,
                   n=n,base_n=base_n, end_n=end_n, aux_n=aux_n,
                   fillet=fillet, base_fillet=base_fillet, aux_fillet=aux_fillet, end_round=end_round,
                   k=k, base_k=base_k, aux_k=aux_k, end_k=end_k,
                   uniform=uniform, base_uniform=base_uniform, aux_uniform=aux_uniform, 
                   debug=debug, start=start, end=end,
                   smooth_normals=smooth_normals, base_smooth_normals=base_smooth_normals, aux_smooth_normals=aux_smooth_normals,
                   return_axis=true, _name1=_name1, _name2=_name2
    );
    axis = vnf_start_end[2] - vnf_start_end[1];
    anchors = [
               named_anchor("root",vnf_start_end[1], -axis),
               named_anchor("end",vnf_start_end[2], axis)
              ];
    attachable(anchor,spin,orient,vnf=vnf_start_end[0], extent=atype=="hull", cp=cp, anchors=anchors) {
      vnf_polyhedron(vnf_start_end[0],convexity=convexity);
      children();
    }
}



function join_prism(polygon, base, base_r, base_d, base_T=IDENT,
                    scale=1, prism_end_T=IDENT, short=false, 
                    length, l, height, h,
                    aux="none", aux_T=IDENT, aux_r, aux_d,
                    overlap, base_overlap,aux_overlap,
                    n=15, base_n, aux_n, end_n, 
                    fillet, base_fillet,aux_fillet,end_round,
                    k=0.7, base_k,aux_k,end_k,
                    uniform=true, base_uniform, aux_uniform, 
                    debug=false, return_axis=false,
                    smooth_normals=true, base_smooth_normals, aux_smooth_normals, 
                    start, end, _name1="base", _name2="aux") =
  let(
      objects=["cyl","cylinder","plane","sphere"],
      length = one_defined([h,height,l,length], "h,height,l,length", dflt=undef)
  )
  assert(is_path(polygon,2),"Prism polygon must be a 2d path")
  assert(is_rotation(base_T,3,centered=true),"Base transformation must be a rotation around the origin")
  assert(is_rotation(aux_T,3),"Aux transformation must be a rotation")
  assert(aux!="none" || is_rotation(aux_T,centered=true), "With no aux, aux_T must be a rotation centered on the origin")
  assert(is_matrix(prism_end_T,4), "Prism endpoint transformation is invalid")
  assert(aux!="none" || (is_num(length) && length>0),"With no aux must give positive length")
  assert(aux=="none" || is_undef(length), "length parameter allowed only when aux is \"none\"")
  assert(aux=="none" || is_path(aux,2) || in_list(aux,objects), "Unknown aux type")
  assert(is_path(base,2) || in_list(base,objects), "Unknown base type")
  assert(is_undef(length) || (is_num(length) && length>0), "Prism length must be positive")
  assert(is_num(scale) && scale>=0, "Prism scale must be non-negative")
  assert(num_defined([end_k,aux_k])<2, "Cannot define both end_k and aux_k")
  assert(num_defined([end_n,aux_n])<2, "Cannot define both end_n and aux_n")
  assert(prism_end_T==IDENT || num_defined([start,end])==0, "Cannot give prism_end_T with either start or end")
  let(
      base_r = get_radius(r=base_r,d=base_d),
      aux_r = get_radius(r=aux_r,d=aux_d),
      base_k= first_defined([base_k,k]),
      aux_k = first_defined([end_k,aux_k,k]),
      aux_n = first_defined([end_n,aux_n,n]),
      base_n = first_defined([base_n,n]),
      base_fillet = one_defined([fillet,base_fillet],"fillet,base_fillet"),
      aux_fillet = aux=="none" ? one_defined([aux_fillet,u_mul(-1,end_round)],"aux_fillet,end_round",0)
              : one_defined([fillet,aux_fillet],"fillet,aux_fillet"),
      base_overlap = one_defined([base_overlap,overlap],"base_overlap,overlap",base_fillet>0?1:0),
      aux_overlap = one_defined([aux_overlap,overlap],"aux_overlap,overlap",aux_fillet>0?1:0),
      base_uniform = first_defined([base_uniform, uniform]),
      aux_uniform = first_defined([aux_uniform, uniform]),
      base_smooth_normals = first_defined([base_smooth_normals, smooth_normals]),
      aux_smooth_normals = first_defined([aux_smooth_normals, smooth_normals])
      
  )
  assert(is_num(base_fillet),"Must give a numeric fillet or base_fillet value")
  assert(base=="plane" || base_fillet>=0, "Fillet for non-planar base object must be nonnegative")
  assert(is_num(aux_fillet), "Must give numeric fillet or aux_fillet")
  assert(in_list(aux,["none","plane"]) || aux_fillet>=0, "Fillet for aux object must be nonnegative")
  assert(!in_list(base,["sphere","cyl","cylinder"]) || (is_num(base_r) && !approx(base_r,0)), str("Must give nonzero base_r with base ",base))
  assert(!in_list(aux,["sphere","cyl","cylinder"]) || (is_num(aux_r) && !approx(aux_r,0)), str("Must give nonzero aux_r with base ",base))
  assert(!short || (in_list(base,["sphere","cyl","cylinder"]) && base_r<0), "You can only set short to true if the base is a sphere or cylinder with radius<0")
  let(
      base_r=default(base_r,1),
      aux_r=default(aux_r,1),
      polygon=clockwise_polygon(polygon),
      start_center = CENTER,
      aux_T_horiz = submatrix(aux_T,[0:2],[0:2]) == ident(3) && aux_T[2][3]==0, 
      dir = num_defined([start,end])==2 ? end-start
          : aux=="none" ? apply(aux_T,UP)
          : aux_T_horiz && in_list([base,aux], [["sphere","sphere"], ["cyl","cylinder"],["cylinder","cyl"], ["cyl","cyl"], ["cylinder", "cylinder"]]) ?
            unit(apply(aux_T, aux_r*UP))
          : apply(aux_T,CENTER)==CENTER ? apply(aux_T,UP)
          : apply(aux_T,CENTER),
      flip = short ? -1 : 1,
      axisline = [CENTER, flip*dir] +  repeat(default(start,CENTER),2), 
      start = base=="sphere" ?
                let( answer = _sphere_line_isect_best(abs(base_r),axisline, sign(base_r)*flip*dir))
                assert(answer,"Prism center doesn't intersect sphere (base)")
                answer
            : base=="cyl" || base=="cylinder" ?
                assert(dir.y!=0 || dir.z!=0, "Prism direction parallel to the cylinder")
                let(
                     mapped = apply(yrot(90),axisline),
                     answer = _cyl_line_intersection(abs(base_r),mapped,sign(base_r)*mapped[1])
                 )
                 assert(answer,"Prism center doesn't intersect cylinder (base)")
                 apply(yrot(-90),answer)
            : is_path(base) ?
                let( 
                     mapped = apply(yrot(-90),axisline),
                     answer = _prism_line_isect(pair(base,wrap=true),mapped,sign(base_r)*mapped[1])[0]
                 )
                 assert(answer,"Prism center doesn't intersect prism (base)")
                 apply(yrot(90),answer)
            : start_center,
      aux_T = aux=="none" ? move(start)*prism_end_T*move(-start)*move(length*dir)*move(start)
              : aux_T,
      prism_end_T = aux=="none" ? IDENT : prism_end_T,
      aux = aux=="none" && aux_fillet!=0 ? "plane" : aux, 
      end_center = apply(aux_T,CENTER), 
      ndir = base_r<0 && in_list(base,["cylinder","cyl","sphere"]) ? unit(start_center-start) : unit(end_center-start_center,UP),
      end_prelim = is_def(end) ? end
        :apply(move(start)*prism_end_T*move(-start),
            aux=="sphere" ?
                let( answer = _sphere_line_isect_best(abs(aux_r), [start,start+ndir], -sign(aux_r)*ndir))
                assert(answer,"Prism center doesn't intersect sphere (aux)")
                apply(aux_T,answer)
          : aux=="cyl" || aux=="cylinder" ? 
                let(
                     mapped = apply(yrot(90)*rot_inverse(aux_T),[start,start+ndir]),
                     answer = _cyl_line_intersection(abs(aux_r),mapped, -sign(aux_r)*(mapped[1]-mapped[0]))
                 )
                 assert(answer,"Prism center doesn't intersect cylinder (aux)")
                 apply(aux_T*yrot(-90),answer)
          : is_path(aux) ?
                let( 
                     mapped = apply(yrot(90),[start,start+ndir]),
                     answer = _prism_line_isect(pair(aux,wrap=true),mapped,sign(aux_r)*(mapped[0]-mapped[1]))[0] 
                 )
                 assert(answer,"Prism center doesn't intersect prism (aux)")
                 apply(aux_T*yrot(-90),answer)
          : end_center
      ),
      end = prism_end_T == IDENT ? end_prelim
          : aux=="sphere" ?
                let( answer = _sphere_line_isect_best(abs(aux_r), move(-end_center,[start,end_prelim]), -sign(aux_r)*(end_prelim-start)))
                assert(answer,"Prism center doesn't intersect sphere (aux)")
                answer+end_center
          : aux=="cyl" || aux=="cylinder" ? 
                let(
                     mapped = apply(yrot(90)*move(-end_center),[start,end_prelim]),
                     answer = _cyl_line_intersection(abs(aux_r),mapped, -sign(aux_r)*(mapped[1]-mapped[0]))
                 )
                 assert(answer,"Prism center doesn't intersect cylinder (aux)")
                 apply(move(end_center)*yrot(-90),answer)
          : is_path(aux) ?
                let( 
                     mapped = apply(yrot(90)*move(-end_center),[start,end_prelim]),
                     answer = _prism_line_isect(pair(aux,wrap=true),mapped,sign(aux_r)*(mapped[0]-mapped[1]))[0]
                 )
                 assert(answer,"Prism center doesn't intersect prism (aux)")
                 apply(move(end_center)*yrot(-90),answer)
          : plane_line_intersection( plane_from_normal(apply(aux_T,UP), end_prelim),[start,end_prelim]),
      pangle = rot(from=UP, to=end-start),
      truetop = apply(move(start)*pangle,path3d(scale(scale,polygon),norm(start-end))),      
      truebot = apply(move(start)*pangle,path3d(polygon)),
      base_trans = rot_inverse(base_T),
      base_top = apply(base_trans, truetop),
      base_bot = apply(base_trans, truebot),
      botmesh = apply(base_T,_prism_fillet(_name1, base, base_r, base_bot, base_top, base_fillet, base_k, base_n, base_overlap,base_uniform,base_smooth_normals,debug)),
      aux_trans = rot_inverse(aux_T),
      aux_top = apply(aux_trans, reverse_polygon(truetop)),
      aux_bot = apply(aux_trans, reverse_polygon(truebot)),
      topmesh_reversed = _prism_fillet(_name2,aux, aux_r, aux_top, aux_bot, aux_fillet, aux_k, aux_n, aux_overlap,aux_uniform,aux_smooth_normals,debug),
      topmesh = apply(aux_T,[for(i=[len(topmesh_reversed)-1:-1:0]) reverse_polygon(topmesh_reversed[i])]),
      round_dir = select(topmesh,-1)-botmesh[0],
      roundings_cross = [for(i=idx(truetop)) if (round_dir[i]*(truetop[i]-truebot[i])<0) i],
      vnf = vnf_vertex_array(concat(topmesh,botmesh),col_wrap=true, caps=true, reverse=true)
  )
  assert(debug || roundings_cross==[],"Roundings from the two ends cross on the prism: decrease size of roundings")
  return_axis ? [vnf,start,end] : vnf;

function _fix_angle_list(list,ind=0, result=[]) =
    ind==0 ? _fix_angle_list(list,1,[list[0]])
  : ind==len(list) ? result 
  : list[ind]-result[ind-1]>90 ? _fix_angle_list(list,ind+1,concat(result,[list[ind]-360]))
  : list[ind]-result[ind-1]<-90 ? _fix_angle_list(list,ind+1,concat(result,[list[ind]+360]))
  : _fix_angle_list(list,ind+1,concat(result,[list[ind]]));
                 


// intersection with cylinder of radius R oriented on Z axis, with infinite extent
// if ref is given, return point with larger inner product with ref.  
function _cyl_line_intersection(R, line, ref) =
   assert(point2d(line[1]-line[0]) != [0,0], "Prism appears to be parallel to cylinder.  Unable to find prism endpoints.")
   let(
       line2d = path2d(line),
       cisect = circle_line_intersection(r=R, cp=[0,0], line=line2d)
   )
   len(cisect)<2 ? [] :
   let(
       linevec = line2d[1]-line2d[0],
       dz = line[1].z-line[0].z,
       pts = [for(pt=cisect)
          let(t = (pt-line2d[0])*linevec/(linevec*linevec))  // position parameter for line
          [pt.x,pt.y,dz * t + line[0].z]]
   )
   is_undef(ref) ? pts :
   let(   
      dist = [for(pt=pts) ref*pt]
   )
   dist[0]>dist[1] ? pts[0] : pts[1];


function _sphere_line_isect_best(R, line, ref) =
   let(
        pts = sphere_line_intersection(abs(R), [0,0,0], line=line)
   )
   len(pts)<2 ? [] :
   let(  
        dist = [for(pt=pts) ref*pt]
   )
   dist[0]>dist[1] ? pts[0] : pts[1];

// First input is all the pairs of the polygon, e.g. pair(poly,wrap=true)
// Unlike the others this returns [point, ind, u], where point is the actual intersection
// point, ind ind and u are the segment index and u value.  Prism is z-aligned.  
function _prism_line_isect(poly_pairs, line, ref) =
   let(

       line2d = path2d(line),
       ref=point2d(ref),
       ilist = [for(j=idx(poly_pairs)) 
                 let(segisect = _general_line_intersection(poly_pairs[j],line2d))
                 if (segisect && segisect[1]>=-EPSILON && segisect[1]<=1+EPSILON)
                    [segisect[0],j,segisect[1],segisect[0]*ref]]
   )
   len(ilist)==0 ? [] :
   let (
       ind = max_index(column(ilist,3)),
       isect2d = ilist[ind][0],
       isect_ind = ilist[ind][1],
       isect_u = ilist[ind][2],
       slope = (line[1].z-line[0].z)/norm(line2d[1]-line2d[0]),
       z = slope * norm(line2d[0]-isect2d) + line[0].z
   )
   [point3d(isect2d,z),isect_ind, isect_u];

  
function _prism_fillet(name, base, R, bot, top, d, k, N, overlap,uniform,smooth_normals, debug) =
    base=="none" ? [bot] 
  : base=="plane" ? _prism_fillet_plane(name,bot, top, d, k, N, overlap,debug)
  : base=="cyl" || base=="cylinder" ? _prism_fillet_cyl(name, R, bot, top, d, k, N, overlap,uniform,debug)
  : base=="sphere" ? _prism_fillet_sphere(name, R, bot, top, d, k, N, overlap,uniform,debug)
  : is_path(base,2) ? _prism_fillet_prism(name, base, bot, top, d, k, N, overlap,uniform,smooth_normals, R, debug)
  : assert(false,"Unknown base type");


function _prism_fillet_plane(name, bot, top, d, k, N, overlap,debug) = 
    let(
        dir = sign(top[0].z-bot[0].z),    // Negative if we are upside down, with "top" below "bot"
        isect = [for (i=idx(top)) plane_line_intersection([0,0,1,0], [top[i],bot[i]])]
    )
    d==0 ? [isect,
            if (overlap!=0) isect,
            if (overlap!=0) move(overlap*dir*DOWN,isect),
      ] :
    let(
        base_normal = -path3d(path_normals(path2d(isect), closed=true)),
        mesh = transpose([for(i=idx(top))
          assert(norm(top[i]-isect[i])>=d,"Prism is too short for fillet to fit")
          let(
              d_step = isect[i]+abs(d)*unit(top[i]-isect[i]),
              edgepoint = isect[i]+d*dir*base_normal[i],
              bez = _smooth_bez_fill([d_step, isect[i], edgepoint],k)
          )
          [
            each bezier_curve(bez,N,endpoint=true),
            if (overlap!=0) edgepoint + overlap*dir*DOWN
          ]
        ])
    )
    assert(debug || is_path_simple(path2d(select(mesh,-2)),closed=true),"Fillet doesn't fit: it intersects itself")
    mesh;


// This function was written for a z-aligned cylinder but the actual
// upstream assumption is an x-aligned cylinder, so input is rotated and
// output is un-rotated.  
function _prism_fillet_cyl(name, R, bot, top, d, k, N, overlap, uniform, debug) =
    let(
        top = yrot(-90,top),
        bot = yrot(-90,bot),
        isect = [for (i=idx(top))
                   let (cisect = _cyl_line_intersection(abs(R), [top[i],bot[i]], sign(R)*(top[i]-bot[i])))
                   assert(cisect, str("Prism doesn't fully intersect cylinder (",name,")"))
                   cisect
                ]
    )
    d==0 ? yrot(90,[ 
                    isect,
                    if (overlap!=0) isect,
                    if (overlap!=0) [for(p=isect) point3d(unit(point2d(p))*(norm(point2d(p))-sign(R)*overlap),p.z)]
                   ])
  :
    let(
        tangent = path_tangents(isect,closed=true),
        mesh = transpose([for(i=idx(top))
           assert(norm(top[i]-isect[i])>=d,str("Prism is too short for fillet to fit (",name,")"))
           let(
               dir = sign(R)*unit(cross([isect[i].x,isect[i].y,0],tangent[i])),
               zpart = d*dir.z,
               curvepart = d*norm(point2d(dir)),
               curveang = sign(cross(point2d(isect[i]),point2d(dir))) * curvepart * 180 / PI / abs(R), 
               edgepoint = apply(up(zpart)*zrot(curveang), isect[i]),
               corner = plane_line_intersection(plane_from_normal([edgepoint.x,edgepoint.y,0], edgepoint),
                                                [isect[i],top[i]],
                                                bounded=false/*[R>0,true]*/),
               d_step = abs(d)*unit(top[i]-isect[i])+(uniform?isect[i]:corner)
           )
           assert(is_vector(corner,3),str("Fillet does not fit.  Decrease size of fillet (",name,")."))
           assert(debug || R<0 || (d_step-corner)*(corner-isect[i])>=-EPSILON,
                 str("Unable to fit fillet, probably due to steep curvature of the cylinder (",name,")."))
           let(
                bez = _smooth_bez_fill([d_step,corner,edgepoint], k)
           )
           [ 
             each bezier_curve(bez, N, endpoint=true),
             if (overlap!=0) point3d(unit(point2d(edgepoint))*(norm(point2d(edgepoint))-sign(R)*overlap),edgepoint.z)
           ]
        ]),
        angle_list = _fix_angle_list([for(pt=select(mesh,-2)) atan2(pt.y,pt.x)]),
        z_list = [for(pt=select(mesh,-2)) pt.z],
        is_simple = debug || is_path_simple(hstack([angle_list,z_list]), closed=true)
    )
    assert(is_simple, str("Fillet doesn't fit: its edge is self-intersecting.  Decrease size of roundover. (",name,")"))
    yrot(90,mesh);



function _prism_fillet_sphere(name, R,bot, top, d, k, N, overlap, uniform, debug) = 
    let(
        isect = [for (i=idx(top))
                    let( isect_pt = _sphere_line_isect_best(abs(R), [top[i],bot[i]],sign(R)*(top[i]-bot[i])))
                    assert(isect_pt, str("Prism doesn't fully intersect sphere (",name,")"))
                    isect_pt
                ]
    )
    d==0 ? [isect,
            if (overlap!=0) isect,
            if (overlap!=0) [for(p=isect) p - overlap*sign(R)*unit(p)]
           ] :
    let(          
        tangent = path_tangents(isect,closed=true),
        mesh = transpose([for(i=idx(top))
           assert(norm(top[i]-isect[i])>=d,str("Prism is too short for fillet to fit (",name,")"))
           let(   
               dir = sign(R)*unit(cross(isect[i],tangent[i])),
               curveang = d * 180 / PI / R,
               edgepoint = rot(-curveang,v=tangent[i],p=isect[i]),
               corner = plane_line_intersection(plane_from_normal(edgepoint, edgepoint),
                                                [isect[i],top[i]],
                                                bounded=[R>0,true]),
               d_step = d*unit(top[i]-isect[i])+(uniform?isect[i]:corner)
           ) 
           assert(is_vector(corner,3),str("Fillet does not fit (",name,")"))
           assert(debug || R<0 || (d_step-corner)*(corner-isect[i])>0, 
                  str("Unable to fit fillet, probably due to steep curvature of the sphere (",name,")."))
           let(
               bez = _smooth_bez_fill([d_step,corner,edgepoint], k)         
           ) 
           [ 
             each bezier_curve(bez, N, endpoint=true),
             if (overlap!=0) edgepoint - overlap*sign(R)*unit(edgepoint)
           ]
        ]),
        test_profile = project_plane(plane_from_normal(centroid(top)-centroid(bot)), select(mesh,-2))
      )
      assert(debug || is_path_simple(test_profile,closed=true),str("Fillet doesn't fit: it intersects itself (",name,")"))
      mesh;



// Return an interpolated normal to the polygon at segment i, fraction u along the segment.

function _getnormal(polygon,index,u,smooth_normals) =
  let(
      flat = smooth_normals ? 1/8 : 1, // Normals are interpolated between faces.  The middle frac portion of each face gets the true face normal
                                       // and then interpolation starts at the end of the flat region.  With flat=1 only endpoints are interpolated.
      edge = (1-flat)/2,
      L=len(polygon),
      next_ind = posmod(index+1,L),
      prev_ind = posmod(index-1,L),
      this_normal = line_normal(select(polygon,index,index+1))
  )
    u >= 1-edge ? lerp(this_normal,line_normal(select(polygon,index+1,index+2)), edge==0? 0.5 : (u-edge-flat)/edge/2)
  : u <= edge ? lerp(line_normal(select(polygon,index-1,index)),this_normal, edge==0? 0.5 : 0.5+u/edge/2)
  : this_normal;


// Start at segment ind, position u on the polygon and find a point length units
// from that starting point.  If dir<0 goes backward through polygon segments
// and if dir>0 goes forward through polygon segments.
// Returns [ point, ind, u] where point is the actual point desired.  
function _polygon_step(poly, ind, u, dir, length) =
    let(ind = posmod(ind,len(poly)))
    u==0 && dir<0 ? _polygon_step(poly, ind-1, 1, dir, length)
  : u==1 && dir>0 ? _polygon_step(poly, ind+1, 0, dir, length)
  : let(
        seg = select(poly,ind,ind+1),
        seglen = norm(seg[1]-seg[0]),
        frac_needed = length / seglen
    )
    dir>0 ?
            ( (1-u) < frac_needed ? _polygon_step(poly,ind+1,0,dir,length-(1-u)*seglen)
                                 : [lerp(seg[0],seg[1],u+frac_needed),ind,u+frac_needed]
            )
          :
            ( u < frac_needed ? _polygon_step(poly,ind-1,1,dir,length-u*seglen)
                                 : [lerp(seg[0],seg[1],u-frac_needed),ind,u-frac_needed]
            );


// This function needs more error checking?
// Needs check for zero overlap case and zero joint case
function _prism_fillet_prism(name, basepoly, bot, top, d, k, N, overlap, uniform, smooth_normals,inside, debug)=
    let(
         inside=sign(inside), 
         top = yrot(-90,top),
         bot = yrot(-90,bot),
         basepoly = clockwise_polygon(basepoly),
         segpairs = pair(basepoly,wrap=true),
         isect_ind = [for (i=idx(top))
                         let(isect = _prism_line_isect(segpairs, [top[i], bot[i]], inside*top[i]))
                         assert(isect, str("Prism doesn't fully intersect prism (",name,")"))
                         isect
                     ],
         isect=column(isect_ind,0),
         index = column(isect_ind,1),
         uval = column(isect_ind,2),
         tangent = path_tangents(isect,closed=true)
     )
     d==0 ? yrot(90,[ 
                    isect,
                    if (overlap!=0) isect,
                    if (overlap!=0) 
                         [for(i=idx(isect))
                             let(normal = point3d(_getnormal(basepoly,index[i],uval[i],smooth_normals)))
                             isect[i]-unit(point3d(normal))*overlap
                         ]
                   ])
   : let(
         mesh = transpose([for(i=idx(top))
           let(
               normal = point3d(_getnormal(basepoly,index[i],uval[i],smooth_normals)),
               dir = inside*unit(cross(normal,tangent[i])),
               zpart = d*dir.z,
               length_needed = d*norm(point2d(dir)),
               edgept2d = _polygon_step(basepoly, index[i], uval[i], sign(cross(point2d(dir),point2d(normal))), length_needed),
               edgepoint = point3d(edgept2d[0],isect[i].z+zpart),
               corner = plane_line_intersection(plane_from_normal(point3d(_getnormal(basepoly, edgept2d[1],edgept2d[2],smooth_normals)),edgepoint),
                                                [top[i],isect[i]],
                                                bounded=false), // should be true, but fails to intersect sometimes at isect[i] end
               d_step = abs(d)*unit(top[i]-isect[i])+(uniform?isect[i]:corner),
               within_top = is_point_on_line(corner, [top[i],isect[i]], RAY),
               within_bottom = is_point_on_line(corner, [isect[i],top[i]], RAY, 1e-1),   // Not sure what epsilon should be here, but 0.1 units under the object seems OK
               dummy = within_bottom ? 0
                     : echo(str("Warning: fillet appears to be inside the ",name,
                                " object.  If so you can try changing 'smooth_normals' or 'uniform'"))
           )
           assert(within_top,str("Fillet does not fit.  Decrease size of fillet (",name,")."))
           assert(debug  || (top[i]-d_step)*(d_step-isect[i])>=0,
                   str("Unable to fit fillet, probably due to steep curvature of the prism (",name,").",
                     d_step," ",corner," ", edgepoint," ", isect[i], " ", top[i]
                     ))
           let(
                bez = _smooth_bez_fill([d_step,corner,edgepoint], k)
           )
           [ 
             each bezier_curve(bez, N, endpoint=true),
             if (overlap!=0) edgepoint-unit(point3d(normal))*overlap*inside
           ]
          ])
         )
        yrot(90,mesh);



// Module: prism_connector()
// Synopsis: Construct a filleted prism that connects objects
// SynTags: Geom
// Topics: Rounding, Extrusion, Sweep, Descriptions
// See Also: parent(), join_prism(), linear_sweep()
// Usage:
//   prism_connector(desc1, anchor1, desc2, anchor2, [spin_align=]);
// Description:
//   Given descriptions and anchors for two objects, construct a filleted prism that connects the
//   anchor points on those objects, with a filleted joint at each end.  This is an alternative interface
//   to {{join_prism()}}, and the arguments which describe the prism are the same.  You obtain the
//   object descriptions using {{parent()}}, which can enable prisms to be constructed between objects
//   at different levels in the object tree.  You can also connect an object with itself, for example to
//   create a hole through an object, or to create an interior connection through a hole.
//   If you specify a CENTER anchor for an object then the prism will be aimed at the object's CENTER anchor
//   and joined at a shifted anchor located on the object's surface.  
//   .
//   The prism will connect anchor points described by the two descriptions you supply.  The supported object
//   types are prismoids, VNFs, cylinders, spheres, and linear sweeps.  For prismoids and VNFs you can use any anchor on a face
//   or edge anchors that include edge geometry.  For spheres you can use any anchor.  In the case of cylinders and linear sweeps you can
//   attach to the flat top or bottom, or to named face anchors in any case.  When you do this, the attachment is treated as an infinite plane.
//   You can attach to the side of the extrusion and follow the shape of the extrusion using the standard anchors only, but the
//   shape must not have scaling (so it cannot
//   be conical) and it must not have any shift.  Only right angle cylinders and extrusions are supported.
//   Anchors on the top and bottom edges are also not supported.  When connecting to an extrusion the selected anchor
//   point must lie on the surface of the shape.  This may requires setting `atype="intersect"` when creating the extrusion.
//   Because of how {{join_prism()}} works, the prism will always make a joint to the shape, but it may be in the wrong location
//   when the anchor point is not on the surface, something that may be particularly puzzling with CENTER anchors.  
//   .
//   If you want to shift the prism away from the anchor point you can do that using the `shift1` and `shift2` parameters.
//   For anchoring to a flat face, the shift is a 2-vector where the y direction corresponds to the direction of the anchor's spin.
//   For a cylinder or extrusion the shift must be a scalar and shifts along the axis.  For spheres, shift is not permitted.
//   .
//   You can rotate the prism by applying {{zrot()}} to your profile, but the `spin_align` option will enable you to rotate it
//   relative to the spin directions of the two descriptions you supply.  If you set `spin_align=1` then the Y direction of the
//   profile will align with the spin direction on object 1.  If you set `spin_align=2` then it will align with the spin direction on object 2.
//   You can also set `spin_align` to either 12 or 21 to get an average value between the spins of the two shapes.  The 12 and 21 options
//   produce the same result except when the spins are exactly 180 degrees apart.  The default is to align the spin with object 1.
//   .
//   When you connect to a flat surface, the prism may extend beyond the edge of the surface if it doesn't fit, and the same thing happens if
//   a connector runs off either end of a cylinder.  But if you connect to a sphere the prism must fully intersect it and if you connect to the curved side
//   of a cylinder or extrusion the prism must fully intersect the infinite extension of that object.  If the prism doesn't intersect
//   the curved surface in that required fashion, it will not be displayed and you will get an error.  You can debug errors
//   like this by setting `debug_pos=true` which debugs the prism position by displaying an unfilleted prism to help you understand why
//   your prism did not work.  Children are not rendered when `debug_pos=true`.  
//   .
//   Another failure can occur if your fillet is too large to accomodate the requested fillet size.  The fillet is constructed by offsetting every point
//   in the profile separately and for a large enough fillet size, concave profiles will cross each other, resulting in an invalid self-intersecting fillet.
//   Normally {{join_prism()}} will issue an error in this situation.  The `debug` parameter is passed through to {{join_prism()}} and
//   tells that module to display invalid self-intersecting geometry to help you understand the problem.
//   .
//   When connecting to an edge, artifacts may occur at the corners where the prism doesn't meet the object in the ideal fashion.
//   Adjsting the points on your prism profile so that a point falls close to the corner will achieve the best result, and make sure
//   that `smooth_normals` is disabled (the default for edges) because it results in a completely incorrect fillet in this case.
//   If you connect to an extrusion object, the default value for `smooth_normals` is true, which generally works better when
//   for a uniformly sampled smooth object, but if your object has corners you may get better results by setting `smooth_normals=false`.  
// Arguments:
//   profile = path giving cross section to extrude to create the connecting prism
//   desc1 = description of first object to connect
//   anchor1 = connection on point first object
//   desc2 = description of second object to connect
//   anchor2 = connection point on second object
//   ---
//   shift1 = shift connection point on object1, a scalar for cylinders, extrusions, or edges, a 2-vector for faces, not permitted for spheres
//   shift2 = shift connection point on object2, a scalar for cylinders, extrusions, or edges, a 2-vector for faces, not permitted for spheres
//   spin_align = align the spin of the connecting prism to specified object (1 or 2) or if you give 12 or 21, the average of the two spins.  Default: 1
//   scale = scale the profile by this factor at anchor2.  Default: 1
//   n = number of facets to use for the fillets.  Default: 15
//   n1 = number of facets at object1
//   n2 = number of facets at object2
//   fillet = fillet for both ends of the prism.  Default: 0
//   fillet1 = fillet for the joint at object1
//   fillet2 = fillet for the joint at object2
//   k = fillet curvature parameter for both ends.   Default: 0.7
//   k1 = fillet curvature parameter at object1
//   k2 = fillet curvature parameter at object2
//   uniform = set to false to get non-uniform filleting at both ends.  Default: true
//   uniform1 = set to false for non-uniform filleting at object1
//   uniform2 = set to false for non-uniform filleting at object2
//   overlap = amount of overlap of the prism fillet into both objects.  Default: 1
//   overlap1 = amount of overlap of the prism fillet into object1
//   overlap2 = amount of overlap of the prism fillet into object2
//   smooth_normals = controls whether normals are smoothed when the object is a prism or edge; no effect otherwise.  Default: false if object is an edge, true otherwise
//   smooth_normals1 = controls whether normals are smoothed when the object1 is a prism or edge; no effect otherwise. 
//   smooth_normals2 = controls whether normals are smoothed when the object2 is a prism or edge; no effect otherwise. 
//   debug = pass-through to the {{join_prism()}} debug parameter.  If true then various cases where the fillet self intersects will be displayed instead of creating an error.  Default: false
//   debug_pos = if set to true display an unfilleted prism instead of invoking {{join_prism()}} so that you can diagnose errors about the prism not intersecting the object.  Default: false
// Named Anchors:
//   "root" = Root point of the connector prism at the desc1 end, pointing out in the direction of the prism axis (anchor inherited from {{join_prism()}}
//   "end" = Root point of the connector prism at the desc2 end, pointing out in the direction of the prism axis (anchor inherited from {{join_prism()}}
// Example(3D,NoAxes,VPT=[11.5254,0.539284,6.44131],VPR=[71.8,0,29.2],VPD=113.4): A circular prism connects a prismoid to a sphere.  Note different fillet sizes at each length.  
//   circ = circle(r=3, $fn=48);
//   prismoid(20,13,shift=[-2,1],h=15) let(prism=parent())
//     right(30) zrot(20)spheroid(r=10,circum=true,$fn=48) let(ball=parent())
//       prism_connector(circ,prism,RIGHT,ball,LEFT,fillet1=4,fillet2=1);
// Example(3D,NoAxes,VPT=[17.1074,4.56034,8.8345],VPR=[71.8,0,29.2],VPD=126): Here we attach a rounded rectangular prism to a prismoid on the left and a regular prism (vnf geometry type) on the right.  Note that the long direction of the rectangle which was is the Y axis in the profile specification is aligned with the spin direction of the first object, the prismoid.  This is the default alignment for the prism and is equivalent to `spin_align=1`.  Note also that we can get away with having long rectangle sides that are not subdivided because the mating surfaces are flat.  
//   bar = rect([1,12],rounding=.4, $fn=32);
//   prismoid(20,15,h=19) let(p1=parent())
//     back(15)right(33)zrot(62)xrot(37)zrot(0) regular_prism(n=5, h=30, side=13) let(p2=parent())
//       prism_connector(bar, p1, RIGHT, p2, FACE(2), fillet=1);
// Example(3D,NoAxes,VPT=[17.1074,4.56034,8.8345],VPR=[71.8,0,29.2],VPD=126): Here is the same example with `spin_align=2` which aligns the connecting prism on the second object.  Note how it is now aligned parallel to the sides of the face where it attaches on the second object.  
//   bar = rect([1,12],rounding=.4, $fn=32);
//   prismoid(20,15,h=19) let(p1=parent())
//     back(15)right(33)zrot(62)xrot(37)zrot(0) regular_prism(n=5, h=30, side=13) let(p2=parent())
//       prism_connector(bar, p1, RIGHT, p2, FACE(2), fillet=1, spin_align=2);
// Example(3D,NoAxes,VPT=[17.1074,4.56034,8.8345],VPR=[71.8,0,29.2],VPD=126): Here the connector prism is aligned midway between the spins on the two described objects using `spin_align=12`.
//   bar = rect([1,12],rounding=.4, $fn=32);
//   prismoid(20,15,h=19) let(p1=parent())
//     back(15)right(33)zrot(62)xrot(37)zrot(0) regular_prism(n=5, h=30, side=13) let(p2=parent())
//       prism_connector(bar, p1, RIGHT, p2, FACE(2), fillet=3, spin_align=12);
// Example(3D,NoAxes,Med,VPT=[17.2141,0.995544,-0.788367],VPR=[55,0,25],VPD=140): Here we apply a shift on object 1. Since this object has a planar connection surface the shift is a 2-vector.  Note that the prism has shifted a little too far and is poking out of the cube it connects to.  When connecting to a planar surface there is no constraint on the extent of the connecting prism.  It may be much larger than the object it connects to.  Note also that the connection on the sphere has shifted to accomodate the change in direction of the prism. If you shift it just a little bit farther forward (perhaps to fit onto a larger cube) the connection to the sphere will fail because the prism doesn't fully intersect the sphere.  
//  circ = circle(r=3, $fn=64);
//  cuboid(21) let(cube=parent())
//    right(40) spheroid(r=15, circum=true,$fn=32) let(ball=parent()){
//      prism_connector(circ,cube,RIGHT, ball, [-1,0,.4], fillet=2);
//      %prism_connector(circ,cube,RIGHT, ball, [-1,0,.4], fillet=2,shift1=[-6,0]);
//    }
// Example(3D,NoAxes,VPT=[17.2141,0.995544,-0.788367],VPR=[55,0,25],VPD=140): In this case because of how the connecting prism is shifted, it does not fully intersect the sphere and you will get an error message stating this.  To understand what is happening you can enable the `debug_pos` option which displays an unfilleted prism. You can inspect the result and see that the edge of the prism will not intersect the sphere, especially after a fillet is added.   
//  circ = circle(r=3, $fn=64);
//  cuboid(25) let(cube=parent())
//    right(40) spheroid(r=15, circum=true,$fn=32) let(ball=parent())
//      prism_connector(circ,cube,RIGHT, ball, [-1,0,.4], fillet=4, shift1=[0,-6],debug_pos=true);
// Example(3D,Big,NoAxes,VPT=[15.9312,-2.44829,-4.47156],VPR=[55,0,25],VPD=155.556): Here two cylinders are connected using a prism shift a shift at each end.  Note that the shift is always along the axis of the cylinder.  Note that the prisms are a little above the faceted cylinders, exposing a small edge that is visible as a kind of dotted line where the fillet meets the cylinder.  Using the circum option to enlarge the cylinders will hide this edge inside the cylinders.
//   circ = circle(r=3, $fn=64);
//   zrot(-20)
//   ycyl(l=40,d=20) let(x=parent())
//     right(40) back(9) cyl(l=40,d=20) let(z=parent()){
//       prism_connector(circ, x, RIGHT, z, LEFT+FWD, fillet=2);
//       %prism_connector(circ, x, RIGHT, z, LEFT+FWD, fillet=2, shift1=-9, shift2=8);
//   }
// Example(Med,NoAxes,VPT=[18.1393,-0.425481,0.777083],VPR=[64.1,0,8.2],VPD=113.4): Here the model has an error and attachment point on the cylinder is on the wrong side so the prism passes through the cylinder.  The shape you see on the front is the base of the prism connector that would usually be buried inside an object.  Later we will see that this can be used for making holes.  
//   circ = circle(r=3, $fn=64);
//   prismoid(20,13,shift=[-2,1],h=15) let(a=parent())
//     right(30) fwd(9) rot([20,15,17]) cyl(r=10,h=30)
//       prism_connector(circ,parent(),FWD,a,RIGHT,fillet=2);
// Example(3D,NoAxes,VPT=[16.5169,0.0116901,1.07281],VPR=[79.5,0,336.7],VPD=91.854): Using the CENTER anchor lets you create a connection, especially for spheres and cylinders, that puts the connecting prism in the best spot, without the need to figure out what the right anchor is.  
//  circ = circle(r=3, $fn=64);
//  cuboid([18,10,20],anchor=LEFT) let(cube=parent())
//    move([11,-23,14])
//      sphere(d=10) let(ball=parent())
//        prism_connector(circ,cube,CTR,ball,CTR,fillet=2);
// Example(3D,NoAxes,VPT=[-3.84547,-8.36131,0.0624037],VPR=[71.1,0,15.9],VPD=113.4): You can still apply shifts with CENTER anchors.  In this case we shift the two connectors outward so that their fillets don't interfere on the cube.  Note that we give shift as a scalar, which is interpreted as shift in just the x direction.  
//  circ = circle(r=3, $fn=64);
//  cuboid([30,10,20]) let(cube=parent())
//    fwd(22)
//      xcopies(n=2,spacing=45)
//        cyl(d=10,h=10,circum=true,$fn=64) let(cyl=parent())
//          prism_connector(circ,cube,CTR,cyl,CTR,fillet1=3,fillet2=2,shift1=2*(2*$idx-1));
// Example(3D,NoAxes,VPT=[2.5679,-1.74152,15.5561],VPR=[72.5,0,14.5],VPD=113.4): Here is a center anchor connection using an extrusion
//   flower = [for(theta=lerpn(0,360,180,endpoint=false))
//             (15+1.3*sin(6*theta))*[cos(theta),sin(theta)]];
//   linear_sweep(flower, height=29,scale=1,atype="intersect")
//   let(sweep=parent())
//     move([24,-22,20]) sphere(d=10)
//       prism_connector(circle(r=2.2,$fn=32), sweep, CTR, parent(),CTR, fillet=2);
// Example(3D,NoAxes,VPT=[2.96309,-4.73627,6.77988],VPR=[55,0,25],VPD=113.4): The {{rounded_prism()}} module supplies anchors for its faces and edges that you can use with this module.  It also has an `atype="prismoid"` anchor type, which provides a prismoid geometry object.  This prismoid geometry is sometimes not accurate enough to find center anchors of rounded prism objects.  It will work properly only if your object could be constructed (without rounding) by the {{prismoid()}} module.  Here is an example where it works correctly.  Note that the top and bottom are rectangular and parallel to the XY plane.  If you instead use `atype="intersect"` with {{rounded_prism()}} then the CENTER anchor will be more robust, but the model below doesn't work in that case because the resulting object has VNF geometry, which {{attach()}} may not properly align.  
//  ellipse = ellipse([2,1.5],$fn=64);
//  cuboid([40,40,5]) let(cubeframe=parent())
//    align(TOP,LEFT)
//      rounded_prism(top=rect([10,15]), bottom=rect([14,21]), height=13,
//                    joint_sides=3, joint_top=3, atype="prismoid",anchor=BOT) 
//      let(first=parent())
//      restore(cubeframe)
//      align(TOP,RIGHT+BACK)
//        rounded_prism(top=rect([10,15]), bottom=rect([14,21]), height=17,
//                      joint_sides=3, joint_top=3, atype="prismoid",anchor=BOT) 
//        let(second=parent())
//          prism_connector(ellipse, first, CTR, parent(), CTR, fillet=2);
// Example(3D,NoAxes,VPT=[60.3443,19.0185,6.2929],VPR=[50.8,0,8.9],VPD=263.435): Here arbitrary rounded prisms are connected using CENTER anchors with `atype="intersect"`.  
//   shape1 = [[0,0],[22,-5],[41,27], [-3,21]];
//   shape2 = scale(1.5,[[-12,0],[14,0],[6,8],[0,30]]);
//   flower = [for(theta=lerpn(0,360,180,endpoint=false))
//             (15+1.3*sin(6*theta))*[cos(theta),sin(theta)]]/2;
//   rounded_prism(bottom=shape1,top=move([5,7],shape1), h=40, joint_top=5, joint_bot=5, joint_sides=7, atype="intersect")
//   let(first=parent())
//     move([70,15,12])
//     zrot(-72)
//     rounded_prism(bottom=shape2,top=move([9,11],shape2), h=37, joint_top=5, joint_bot=5, joint_sides=3, atype="intersect")
//     let(second=parent())
//       prism_connector(flower, first, CTR, second, CTR, fillet=2);
// Example(3D,NoAxes,Med,VPT=[21.6303,-17.7214,-1.32542],VPR=[25.8,0,344.4],VPD=60.2654):  Connecting to edges is possible but problems may arise.  In this example the skinny rectangular connector prism connects to edge anchors on the two cubes.  By default as usual it aligns its direction with the spin of the first object, so the prism lines up with the edge on the left hand cube.  Since the edges are not parallel, the prism does **not** align with the second edge.  When aligning a skinny object like this with an edge, artifacts are likely to occur if the connector doesn't align neatly with the edge, as happens on the second object.  
//   bar = subdivide_path(rect([2,12],rounding=.5, $fn=32),maxlen=.5,closed=true);
//   cuboid(30) let(big=parent())
//     move([35,-30,0]) rot(a=35,v=[-1,1,0]) cuboid(20)  let(small=parent())
//       prism_connector(bar, big, RIGHT+FWD, small, BACK+LEFT, fillet=1);
// Example(3D,NoAxes,Med,VPT=[21.6303,-17.7214,-1.32542],VPR=[25.8,0,344.4],VPD=60.2654):  Here with `spin_align=2` the prism now aligns neatly with the edge on the right hand cube.  In this case the artifacts that arise have lead to problems that prevent the shape from rendering in CGAL, but this can be worked around by decreasing `overlap` from its default of 1 to 0.5.  When the edges are not parallel, it is impossible to line the prism up with both at the same time: that would require the connecting prism to twist.  Setting `spin_align=12` will simply result in the prism aligning with **neither** edge.  
//   bar = subdivide_path(rect([2,12],rounding=.5, $fn=32),maxlen=.5,closed=true);
//   cuboid(30) let(big=parent())
//     move([35,-30,0]) rot(a=35,v=[-1,1,0]) cuboid(20)  let(small=parent())
//       prism_connector(bar, big, RIGHT+FWD, small, BACK+LEFT, fillet=1, spin_align=2, overlap=0.5);
// Example(3D,VPR=[80.9,0,55.8],VPT=[11.9865,-12.0228,4.48816],VPD=15.3187): As noted above, attaching to edges doesn't always produce a good looking result, and sometimes you may get unexpected errors about the fit of the fillet, or failure to render.  These things happen because the implementation assumes an approximately smooth shape, which is a bad assumption for edges.  You can even get artifacts when shapes appear neatly aligned with the edges.  For example, if you connect a circular prism to an edge you definitely want an even number of points so the top and bottom can line up with the edge.  But you may find that artifacts appear when you increase the point count like in this example below where the prism's joint to the edge has a little groove:
//   circ = circle(r=3, $fn=64);
//   cuboid(20) let(edge=parent())
//     move([30,-30,-8]) zrot(-45) cuboid(20) let(extra=parent())
//       prism_connector(circ, edge, RIGHT+FWD, extra, LEFT, fillet=2);
// Example(3D,VPR=[80.9,0,55.8],VPT=[11.9865,-12.0228,4.48816],VPD=15.3187): The artifact shown above occurs because of normals to the prism that cross the edge at a small angle.  You can remove it by either decreasing the number of points (32 works in this case) or as shown below, by stretching out the circle so that the top is flatter, which makes the normals parallel to the edge so they don't cross it.  Generally results will be best if you can get a point on the edge and if the top surface is perpendicular to the edge, or at least angled such that the a normal to the prism does not cross the edge when extended by the fillet distance.  
//   circ = xscale(1.2,circle(r=3, $fn=64));
//   cuboid(20) let(edge=parent())
//     move([30,-30,-8]) zrot(-45) cuboid(20) let(extra=parent())
//       prism_connector(circ, edge, RIGHT+FWD, extra, LEFT, fillet=2);
// Example(3D,VPR=[80.9,0,55.8],VPT=[11.9865,-12.0228,4.48816],VPD=15.3187): When no point falls on the edge you can get an artifact like this, where the connector prism is underneath the corner.  
//   circ = xscale(1.2,circle(r=3, $fn=31));
//   cuboid(20) let(edge=parent())
//     move([30,-30,-8]) zrot(-45) cuboid(20) let(extra=parent())
//       #prism_connector(circ, edge, RIGHT+FWD, extra, LEFT, fillet=2);
// Example(3D,NoAxes): We can attach to the top surface of a shifted cone, but when attaching to the curved surface, only a right angle cylinder is supported.
//   $fn=32;
//   flower = scale(.6,[for(theta=lerpn(0,360,90,endpoint=false)) (15+1.3*sin(6*theta))*[cos(theta),sin(theta)]]);
//   cyl(d1=40, d2=30,h=30, shift=[4,9]) let(cone=parent())
//     up(40) back(30)xcyl(d=30,l=30,$fn=64,circum=true)
//       prism_connector(flower, cone, TOP, parent(), FWD+BOT, fillet=2.5);
// Example(3D,NoAxes,VPT=[2.33096,4.77324,9.30076],VPR=[85.8,0,358.4],VPD=102.06): This example scales the end of the prism, has different fillets at each end, and uses shifting to adjust its position.  
//  cyl(d=30,h=8) let(bot=parent())
//    up(20)right(8)xrot(-20)yrot(11)cyl(d=18,h=8) let(top=parent())
//      prism_connector(circle(d=20,$fn=64), bot, TOP, top, BOT, scale=0.4,
//                      fillet1=2.5, shift1=3,fillet2=2, shift2=[-2,-2.2]);
// Example(3D,NoAxes,VPT=[15.0136,12.2965,5.31287],VPR=[62.7,0,25.7],VPD=113.4): Here we connect a prism to a linear sweep.  (Note that you must use {{linear_sweep()}}, not linear_extrude().)
//  circ = circle(r=3, $fn=64);
//  flower = scale(.4,[for(theta=lerpn(0,360,180,endpoint=false)) (15+1.3*sin(6*theta))*[cos(theta),sin(theta)]]);
//  zrot(-90)
//  linear_sweep(flower, h=22) let(sweep=parent())
//    zrot(90)right(40)zrot(15)yrot(12) cuboid(12) let(cube=parent())
//      prism_connector(circ,sweep,BACK,cube,LEFT,fillet=2);
// Example(3D,NoAxes): You can use the same object for `desc1` and `desc2` with different anchors to create a filleted hole.  Note that if you don't enlarge overlap from its default value of 1 then parts of the cylinder don't get removed by the difference.  
//   circ = circle(r=8, $fn=64);
//   back_half()
//   diff()
//     cyl(d=40,h=50,$fn=32)
//        tag("remove") prism_connector(circ,parent(),LEFT,parent(),RIGHT,
//                                      shift1=-8,shift2=7,fillet=6,overlap=3);
// Example(3D,NoAxes,VPT=[1.42957,2.47871,-3.63111],VPR=[40.3,0,29.2],VPD=263.435): You can also use interior connectors to bridge across holes as shown in this example.  Note also that you can apply operations like rotation to the connector.
//   circ = circle(r=3, $fn=64);
//   diff()
//     highlight_this() cyl(d=85,h=39)
//       tag("remove") cyl(d=75,h=40,$fn=128)
//       tag("keep") zrot_copies(n=4)
//         prism_connector(circ,parent(),[-1,.2],parent(),[1,.4],shift1=12,shift2=-12,fillet=2);
// Example(3D,Med,NoAxes): You can also make a connection between the "inside" part of a tube and the outside of a tube
//    diff()
//    tube(or=10,wall=2,h=10,rounding=1,$fn=40)
//      let(outside=parent())
//      attach_part("inside")
//      tag("remove")
//        for(where = [LEFT,RIGHT,FRONT,BACK])
//          prism_connector(circle(3,$fn=100),
//                          outside, where,
//                          parent(), where,
//                          fillet=1);
// Example(3D,Med,NoAxes,VPT=[1.42957,2.47871,-3.63111],VPR=[40.3,0,29.2],VPD=263.435): Here we use the {{zrot_copies()}} distributor to create copies of objects and create a connector to a non-symmetrically placed object.  All all the connectors are different because we change the anchor point that goes with the second description.
//   circ = circle(r=3, $fn=64);
//   right(4)up(25)xrot(15) cyl(r=20,h=30,circum=true,$fn=64) let(cyl=parent())
//     restore()
//     zrot_copies(n=5) right(40)zrot(45)cuboid(18)
//       prism_connector(circ, parent(), TOP, cyl, [cos(360/5*$idx), sin(360/5*$idx), 0], fillet1=3,fillet2=7);
// Example(3D,Med,NoAxes,VPT=[-4.51969,7.59952,4.54054],VPR=[48.7,0,30.6],VPD=361.364): In the previous example we used a distributor to create copies of an object and build connectors from those copies to a different object.  What if you want to create connectors between copies created by a distributor?  One powerful way to do this is to create an array of descriptions and use that array to make the connectors.  It's convenient to put your object into a module so you don't have to repeat it, but make sure that your module takes children, or the connectors won't run!  Here we create the objects first, and then we separately create the connectors as a child of a single hidden instance of the object.  That second construction is needed so we can get the description of the object, but we don't want it to show up in the model.
//   circ = circle(r=3, $fn=64);
//   module object() cuboid(18)children();
//   T_list = arc_copies(rx=80,ry=60,n=5,sa=0,ea=180);
//   for(T=T_list) multmatrix(T) object();
//   hide_this()object()
//     let(desc = transform_desc(T_list,parent()))
//     for(d=pair(desc))
//       prism_connector(circ, d[0], BACK, d[1], FWD, fillet=5);
// Example(3D,NoAxes,Med,VPT=[-4.51969,7.59952,4.54054],VPR=[48.7,0,30.6],VPD=361.364):  We can change the object in the above example to vary between cube and cylinder.  
//   circ = circle(r=3, $fn=64);
//   T_list = arc_copies(rx=80,ry=60,n=5,sa=0,ea=180);
//   module object(ind)
//       if (ind%2==0) cuboid(18)children();
//       else cyl(d=30,h=18,circum=true) children();
//   for(i=idx(T_list)) multmatrix(T_list[i]) object(i);
//   hide_this() object(0) let(even=parent())
//     hide_this() object(1) let(obj=[even,parent()], p=pair(T_list))
//       for(i=[0:len(T_list)-2])
//         prism_connector(circ, transform_desc(T_list[i],select(obj,i)),BACK,
//                               transform_desc(T_list[i+1],select(obj,i+1)), FWD,
//                         fillet=4);
// Example(3D,NoAxes,Med,VPT=[-0.963453,0.924861,-2.75661],VPR=[34,0,31.3],VPD=401.516): Another way to establish connections between objects is with {{desc_copies()}} which provides functions to access the descriptions of the other objects in the set.  Note that in OpenSCAD 2021.01 you cannot call `$prev()` and `$next()` directly.  In development versions you can call them directly and hence the example could be slightly simplified.  
//   circ = circle(r=3, $fn=64);
//   desc_copies(arc_copies(rx=80,ry=60,n=7,sa=0,ea=360))
//     spheroid(11,circum=true) let(next=$next,prev=$prev)
//        prism_connector(circ, prev(),BACK+LEFT, next(), FWD+LEFT, fillet=5, debug_pos=false);
// Example(3D,Med,NoAxes,VPT=[1.15472,1.59934,-3.16205],VPR=[55,0,25],VPD=361.364): Using CENTER anchors can make a construction like this much easier.  In this example the anchors need to shift around from the pointy end to the flat end of the ellipse, which would be annoying to calculate by hand.  
//   desc_copies(arc_copies(rx=85,ry=45,n=12)) let(next=$next)
//     cyl(d=15,h=27,circum=true,rounding=5,$fn=64) 
//       prism_connector(circle(r=3,$fn=32), parent(), CTR, next(), CTR, fillet=4);
// Example(3D,NoAxes,Med,VPT=[-3.18586,5.10784,4.59099],VPR=[58.5,0,19.4],VPD=325.228): When using {{desc_copies()}} with a varying shape you have to conditionally show only the correct shape for each index, but still specify all the shapes so you can collect their descriptions.  
//  circ = circle(r=3, $fn=64);
//  desc_copies(arc_copies(rx=60,ry=80,n=5,sa=-20,ea=200))
//     hide($idx%2==0?"cyl":"cube")
//     tag_this("cyl")cyl(d=30,h=30) let(cyl=parent())
//     tag_this("cube")cuboid([22,22,30])
//        let(
//             obj=[parent(),cyl],
//             next=$next,
//             shift=$idx%2==0?[0,6]:-6
//        )
//        if($idx<$count-2)
//          prism_connector(scale(.8,circ),
//                          select(obj,$idx),BACK,
//                          next(2,select(obj,$idx+2)), FWD, fillet=4,shift1=shift,debug_pos=false);
// Example(3D,NoAxes,Med,VPT=[15.3147,3.4204,-0.243801],VPR=[78.8,0,352.1],VPD=102.06): Here we create a connected pipe configuration by making the outside assembly of connected cylinders first, and then subtracting the interior assembly.  Note that a correction is needed to the shift in order to create uniform pipe walls because the length of the connector changes, so different shifts are needed to keep everything parallel.  
//  bigpipe_d=15;
//  smallpipe_d=9;
//  wall=1;
//  h=30;
//  fillet=3;
//  sep=30;
//  shift=5;
//  shift_fix=wall/(sep-bigpipe_d)*shift;
//  $fn=128;
//  back_half()
//    difference(){
//      // Pipe exterior 
//      cyl(d=bigpipe_d,h=h,circum=true) let(leftpipe=parent())
//      right(sep)
//        cyl(d=bigpipe_d,h=h,circum=true) let(rightpipe=parent())
//          prism_connector(circle(d=smallpipe_d,$fn=48),
//                          leftpipe, RIGHT, rightpipe, LEFT, fillet=fillet, shift2=shift);
//      // Interior that will be removed
//      cyl(d=bigpipe_d-2*wall,h=h+1,circum=true) let(leftpipe=parent())
//      right(sep)
//        cyl(d=bigpipe_d-2*wall,h=h+1,circum=true) let(rightpipe=parent())
//          prism_connector(circle(d=smallpipe_d-2*wall,$fn=48),
//                          leftpipe, RIGHT, rightpipe, LEFT, fillet=fillet,
//                          shift1=-shift_fix,shift2=shift+shift_fix);
//    }


// Get the object type from the specified geometry and anchor point

// Note that profile is needed just to find its dimensions for making a big enough edge profile
function _get_obj_type(ind,geom,anchor,prof) =
     geom[0]=="spheroid" ? "sphere"
   : geom[0]=="conoid" ? let(
                             axis = geom[5],
                             anchor = rot(from=axis, to=UP, p=anchor)
                         )
                         anchor==UP || anchor==DOWN ? "plane"
                       : assert(geom[1]==geom[2], str("For anchors other than TOP/BOTTOM, cylinder from desc",ind," must be non-conical, with same size at each end"))
                         assert(geom[4]==[0,0], str("For anchors other than TOP/BOTTOM, cylinder from desc",ind," must be a right-angle cylinder with zero shift"))
                         assert(anchor.z==0,str("Anchor for cylinder for desc",ind," is on the cylinder's edge.  This is not supported."))
                         "cyl"
   : in_list(geom[0],["prismoid","vnf_extent","vnf_isect"]) ?
                           assert(geom[0]!="prismoid" || sum(v_abs(anchor))<3, "Cannot give a corner anchor for prismoid geometry")
                           let(
                                anch = _find_anchor(anchor, geom),
                                edge_angle = len(anch)==5 ? struct_val(anch[4],"edge_angle") : undef
                           )
                           is_undef(edge_angle)
                              ? "plane"
                              : let(
                                    y = 20*max(v_abs(full_flatten(prof))),
                                    x = y/tan(edge_angle/2)
                                )
                                [[x,-y],[0,0], [x,y]]
   : starts_with(geom[0], "extrusion") ?
                   anchor==UP || anchor==DOWN || starts_with(anchor,"face") ? "plane"
                 :
                   assert(geom[3]==0, str("Extrusion in desc", ind, " has nonzero twist, which is not supported."))
                   assert(geom[5]==[0,0], str("Extrusion in desc", ind, " has nonzero shift, which is not supported."))
                   assert(geom[4]==[1,1], str("Extrusion in desc",ind, " is conical, which is not supported."))
                   assert(anchor.z==0,str("Anchor for extrusion for desc",ind," is on the extrusions top/bottom edge.  This is not supported."))   
                   let(reg = region_parts(geom[1]))
                   assert(len(reg)==1, "Region has multiple disconnected components, which is not supported")
                   let(     // Here we shift the region so that the anchor point is at the origin
                        anch = _find_anchor(anchor, geom)
                   )
                   rot(from=anch[2],to=LEFT, p=move(-anch[1], reg[0][0]))
   : assert(false, str("Unsupported geometry:", geom[0]));


/// Check and compute the shift parameter for different object types
/// Arguments
///   ind = object index for error messages, either 1 or 2
///   type = object type
///   shift = given shift parameter

function _check_join_shift(ind,type,shift,flip) = 
    type=="sphere" ? assert(shift==0, str("Cannot give a (nonzero) shift",ind," for joining to a spherical object")) [0,0,0]
  : type=="cyl" ? assert(is_finite(shift), str("Value shift",ind," for cylinder object must be a scalar")) shift*RIGHT
  : is_list(type) ? assert(is_finite(shift), str("Value shift",ind," for an edge must be a scalar")) shift*RIGHT
  : /*type==plane*/ assert(is_finite(shift) || is_vector(shift,2), str("Value for shift",ind," for planar face of object must be a scalar or 2-vector"))
    is_list(shift)? flip ? [shift.y,-shift.x]: shift
                  : flip ? [0,-shift] : [shift,0];


function _is_geom_an_edge(geom,anchor) = 
   (geom[0]=="prismoid" || geom[0]=="vnf_extent")
   && (
        let(anch = _find_anchor(anchor, geom))
        is_def(struct_val(anch[4], "edge_angle"))
      );



function _prismoid_isect(geom, line, bounded, flip=false) =
   let(
       size = [for (c = geom[1]) max(0,c)],
       size2 = [for (c = geom[2]) max(0,c)],
       shift=point2d(geom[3]),
       axis=point3d(geom[4]),
       h=size.z,
       bot=path3d(rect(point2d(size)),-h/2),
       top=path3d(move(shift, rect(size2)),h/2),
       modline = move(shift/2,rot(from=axis,to=UP, p=line)), 
       isect = [ polygon_line_intersection(top, modline, bounded),
                 polygon_line_intersection(bot, modline, bounded),
                 for(i=[0:3]) polygon_line_intersection([top[i], bot[i], select(bot,i+1),select(top,i+1)], modline, bounded)
               ],
       faceanch = [TOP, BOT, FWD, LEFT, BACK, RIGHT],
       hits = [for(i=idx(isect)) if (isect[i]) [faceanch[i], isect[i]]],
       check = assert(len(hits)>0, "Line does not intersect the prismoid."), 
       anchor = rot(from=UP,to=axis,p=sum(column(hits,0))),
       anchlen = sum(v_abs(anchor)), 
       ipt = hits[0][1],
       anch = _find_anchor(anchor, geom),
       anchpt = anch[1],
       myshift = anchlen==3 ? 0
               : let(
                     z = anch[2],
                     y = rot(from=UP,to=z, p=zrot(anch[3], BACK)),
                     x = cross(y,z)
                 )
                 anchlen==2 ? (ipt-anchpt) * y * RIGHT
               : (!flip?ident(2):[[0,1],[-1,0]])*[x,y]*(ipt-anchpt)
      )
      [anchor, myshift];

// Find intersection with tops of a cone or if those don't intersect,
// then the sides of a right angle cylinder only.  
function _cone_isect(geom,line,bounded,flip) =
   let(
       rr1=geom[1],
       rr2=geom[2],
       r1 = is_num(rr1)? [rr1,rr1] : point2d(rr1),
       r2 = is_num(rr2)? [rr2,rr2] : point2d(rr2),
       r=[r1,r2],
       length=geom[3],
       shift=point2d(geom[4]),
       axis=point3d(geom[5]),
       modline = rot(from=axis,to=UP, p=line), 

       btisect = [for(dir=[-1,1]) plane_line_intersection(plane_from_normal(UP,dir*length/2*UP), modline, RAY)],
       tbhit = [for(i=[0:1])
                  if (is_def(btisect[i]) && (btisect[i].x-shift.x)^2/r[i].x^2+(btisect[i].y-shift.y)^2/r[i].y^2<=1) i ],
       tbresult = len(tbhit)==0 ? undef
                : let(
                       anchor = rot(from=UP,to=axis,p=[0,0,2*tbhit[0]-1]),
                       anch = _find_anchor(anchor,geom),
                       z = anch[2],
                       y = rot(from=UP,to=z, p=zrot(anch[3], BACK)),
                       x = cross(y,z),
                       shift = (!flip?ident(2):[[0,1],[-1,0]])*[x,y]*(rot(from=UP,to=axis,p=btisect[tbhit[0]])-anch[1])
                   )
                   [anchor,shift]
    )
    is_def(tbresult) ? tbresult
  :
    assert(r1==r2 && r1[0]==r2[0] && shift==[0,0], "Center anchor intersects curved side of cone or shifted cylinder, which is not allowed")
    let(
        ray = modline[1]-modline[0],
        anchor = rot(from=UP,to=axis,p=point3d(unit(point2d(ray)))),
        slope = ray.z/norm([ray.x,ray.y]),
        anch = _find_anchor(anchor,geom),
        z = anch[2],
        y = rot(from=UP,to=z,p=zrot(anch[3], BACK)),
        shift = (r1[0]*slope)*(axis==UP?1:(cross(y,z)*axis))
    )
    [anchor,shift*RIGHT];



function _extrusion_isect(geom,line,bounded,flip) =
   let(
       region=geom[1],
       length=geom[2],
       twist = geom[3],
       scale=point2d(geom[4]),
       shift=point2d(geom[5]),

       reg=region_parts(region),
       check1 = assert(len(reg)==1, "Region has multiple disconnected components, which is not supported"),
       path = reg[0][0],
       
       bot_top = [path3d(path, -length/2),
                  move(shift,zrot(twist,scale(scale,path3d(path, length/2))))],

       btisect = [for(poly=bot_top) polygon_line_intersection(poly, line, bounded)],
       tbhit = [for(i=[0:1]) if (is_vector(btisect[i])) i],

       tbresult = len(tbhit)==0 ? undef
                :
                  let(
                      anchor = [0,0,2*tbhit[0]-1],
                      anch = _find_anchor(anchor,geom),
                      z = anch[2],
                      y = rot(from=UP,to=z, p=zrot(anch[3], BACK)),
                      x = cross(y,z),
                      shift = (!flip?ident(2):[[0,1],[-1,0]])*[x,y]*(btisect[tbhit[0]]-anch[1])
                   )
                   [anchor,shift]
    )
    is_def(tbresult) ? tbresult
  : 
    assert(twist==0, "Extrusion has nonzero twist which is not supported")
    assert(shift==[0,0], "Extrusion has nonzero shift, which is not supported.")
    assert(scale==[1,1], "Extrusion is conical, which is not supposrted")
    let(
        isect = polygon_line_intersection(path, path2d(line), RAY),
        check1=assert(is_def(isect), "Cannot find side anchor to extrusion"),
        
        pt = let(
                 pts = flatten(isect),
                 dists = [for(pt=pts) norm(pt-line[0])]
             )
             pts[max_index(dists)],
        ray = line[1]-line[0],
        anchor = point3d(unit(point2d(ray))),
        slope = ray.z/norm([ray.x,ray.y]),
        anch = _find_anchor(anchor,geom),
        z = anch[2],
        y = rot(from=UP,to=z,p=zrot(anch[3], BACK)),
        shift = (norm(pt)*slope)
    )
    [anchor,shift*RIGHT];


function _find_center_anchor(desc1, desc2, anchor2, flip) =
  let(
       pt2 = desc_point(desc2, anchor=anchor2),
       line = [CTR,desc_attach(desc1,CTR,p=pt2,reverse=true)],
       geom = desc1[1]
  )
    geom[0]=="prismoid" ? _prismoid_isect(geom, line, RAY, flip)
  : geom[0]=="conoid" ? _cone_isect(geom,line,RAY,flip)
  : geom[0]=="spheroid" ? [unit(line[1]-line[0]), [0,0,0]]
  : starts_with(geom[0],"extrusion") ? _extrusion_isect(geom,line,RAY,flip)
  : geom[0]=="vnf_isect" ? [unit(line[1]-line[0]), [0,0,0]]
  : assert(false,str("Center anchor not supported with geometry type ",geom[0]));




module prism_connector(profile, desc1, anchor1, desc2, anchor2, shift1=0, shift2=0, spin_align=1,
                       scale=1,
                       fillet, fillet1, fillet2,
                       overlap, overlap1, overlap2,
                       k, k1, k2, n, n1, n2,
                       uniform, uniform1, uniform2,
                       smooth_normals, smooth_normals1, smooth_normals2, 
                       debug=false, debug_pos=false)
{
    base_fillet = first_defined([fillet1,fillet,0]);
    aux_fillet = first_defined([fillet2,fillet,0]);

    base_overlap = first_defined([overlap1,overlap,1]);
    aux_overlap = first_defined([overlap2,overlap,1]);

    base_n = first_defined([n1,n,15]);
    aux_n = first_defined([n2,n,15]);

    base_uniform = first_defined([uniform1, uniform, true]);
    aux_uniform = first_defined([uniform2, uniform, true]);
    
    base_k = first_defined([k1,k,0.7]);
    aux_k = first_defined([k2,k,0.7]);

    profile = force_path(profile,"profile");
    dummy0 = assert(is_path(profile,2), "profile must be a 2d path");

    corrected_base_anchor = is_vector(anchor1) && norm(anchor1)==0 ? _find_center_anchor(desc1,desc2,anchor2,true) : undef;
    corrected_aux_anchor = is_vector(anchor2) && norm(anchor2)==0 ? _find_center_anchor(desc2,desc1,anchor1,false) : undef;      


    base_anchor=is_string(anchor1) ? anchor1
               : is_def(corrected_base_anchor) ? corrected_base_anchor[0]
               : point3d(anchor1);
    aux_anchor=is_string(anchor2) ? anchor2
               : is_def(corrected_aux_anchor) ? corrected_aux_anchor[0]
               : point3d(anchor2);
    
    base=desc1;
    aux=desc2;

    current = parent();
    tobase = current==base ? ident(4) : linear_solve(current[0],base[0]);   // Maps from current frame into the base frame
    auxmap = linear_solve(base[0], aux[0]);   // Map from the base (desc1) coordinate frame into the aux (desc2) coordinate frame

    dummy = assert(is_vector(base_anchor) || is_string(base_anchor), "anchor1 must be a string or a 3-vector")
            assert(is_vector(aux_anchor) || is_string(aux_anchor), "anchor2 must be a string or a 3-vector")    
            assert(is_rotation(auxmap), "desc1 and desc2 are not related to each other by a rotation (and translation)");

    base_type = _get_obj_type(1,base[1],base_anchor,profile);
    base_axis = base_type=="cyl" ? base[1][5] : RIGHT;
    base_edge = _is_geom_an_edge(base[1],base_anchor);
    base_r = in_list(base_type,["cyl","sphere"]) ? base[1][1] : 1;
    base_anch = _find_anchor(base_anchor, base[1]);
    base_spin = base_anch[3];
    base_anch_pos = base_anch[1];
    base_anch_dir = base_anch[2];

    prelim_shift1 = _check_join_shift(1,base_type,shift1,true);
    shift1 = corrected_base_anchor ? corrected_base_anchor[1] + prelim_shift1 : prelim_shift1;
    aux_type = _get_obj_type(2,aux[1],aux_anchor,profile);
    aux_anch = _find_anchor(aux_anchor, aux[1]);
    aux_edge = _is_geom_an_edge(aux[1],aux_anchor);
    aux_r = in_list(aux_type,["cyl","sphere"]) ? aux[1][1] : 1;
    aux_anch_pos = aux_anch[1];
    aux_anch_dir = aux_anch[2];
    aux_spin = aux_anch[3];
    aux_spin_dir = apply(rot(from=UP,to=aux_anch[2])*zrot(aux_spin),BACK);
    aux_axis = aux_type=="cyl" ? aux[1][5] : RIGHT;
    prelim_shift2 = _check_join_shift(2,aux_type,shift2,false);
    shift2 = corrected_aux_anchor ? corrected_aux_anchor[1] + prelim_shift2 : prelim_shift2;
    

    base_smooth_normals = first_defined([smooth_normals1, smooth_normals,!base_edge]);
    aux_smooth_normals = first_defined([smooth_normals2, smooth_normals,!aux_edge]);    
    
    backdir = base_type=="cyl" ? base_axis
            : apply(rot(from=UP,to=base_anch_dir)*zrot(base_spin),BACK);
    anch_shift = base_type=="plane" || is_list(base_type) ? base_anch_pos : CENTER;

    
    // Map from the starting position for a join_prism object to
    // the standard position for the object.
    // If the aux object is an edge (type is a list) then the starting position
    // of the prism is with the edge lying on the X axis and the object below.  
    aux_to_canonical = aux_type=="sphere" ? IDENT
                     : aux_type=="cyl" ? frame_map(x=aux_axis, z=aux_anch[2])
                     : aux_type=="plane" ? move(aux_anch_pos) * rot(from=UP, to=aux_anch[2])*zrot(aux_spin)
                     : /* list */  move(aux_anch_pos) * frame_map(z=aux_anch[2],x=aux_spin_dir) ;

    // aux_T is the map that maps the auxiliary object from its initial position to
    // the position for the prism.  The initial position is centered for a sphere,
    // with the axis X aligned for a cylinder, and with the face of a polyhedron
    // laying in the XY plane for polyhedra.  
    aux_T =    move(-shift1)
            * frame_map(x=backdir, z=base_anch_dir, reverse=true)
            * move(-anch_shift)
            * auxmap
            * aux_to_canonical
            * move(shift2);
    aux_root = aux_type=="plane" || is_list(aux_type) || aux_anchor==CTR ? apply(aux_T,CTR)
             : apply(aux_T * matrix_inverse(aux_to_canonical), aux_anch_pos);

    base_root = base_type=="plane" || is_list(base_type) || base_anchor==CTR ? CENTER : base_r*UP;

    prism_axis = aux_root-base_root;

    base_inside = prism_axis.z<0 ? -1 : 1;

    aux_normal = aux_type=="cyl" || aux_type=="sphere" ? apply(aux_T*matrix_inverse(aux_to_canonical), aux_anch[2]) - apply(aux_T*matrix_inverse(aux_to_canonical), CTR) 
               : apply(aux_T, UP) - apply(aux_T,CTR);  // Is this right?  Added second term
    aux_inside = aux_normal*(base_root-aux_root) < 0 ? -1 : 1;
    
    shaft = rot(from=UP,to=prism_axis, p=zrot(base_spin,BACK));

    obj1_back = apply(frame_map(x=backdir,z=base_anch_dir,reverse=true)*rot(from=UP,to=base_anch_dir)*zrot(base_spin),BACK);
    obj2_back = aux_type=="plane" ? apply(aux_T,BACK)-apply(aux_T,CTR)
              : is_list(aux_type) ? apply(aux_T*matrix_inverse(frame_map(z=aux_anch[2],x=aux_spin_dir)),aux_spin_dir)-apply(aux_T,CTR)
              : aux_type=="sphere"? apply(aux_T,aux_spin_dir)-apply(aux_T,CTR)
                /*cyl*/           :  apply(aux_T*matrix_inverse(aux_to_canonical),aux_spin_dir)-apply(aux_T,CTR);

    v1 = vector_perp(prism_axis, shaft);
    v2 = vector_perp(prism_axis, obj1_back);  
    v3 = vector_perp(prism_axis, obj2_back);
    sign1 = cross(v1,v2)*prism_axis < 0 ? 1 : -1;
    sign2 = cross(v3,v1)*prism_axis < 0 ? 1 : -1;

    spin1 =  sign1 * vector_angle(v1,v2);
    spin2 = -sign2 * vector_angle(v3,v1);
    spin = spin_align==1 ? spin1
         : spin_align==2 ? spin2
         : spin_align==12 ? mean_angle(spin1,spin2)
         : spin_align==21 ? mean_angle(spin2,spin1)
         : assert(false, str("spin_align must be one of 1, 2, 12, or 21 but was ",spin_align));
    multmatrix(tobase)
      move(anch_shift)
      frame_map(x=backdir, z=base_anch_dir)
      move(shift1){
        //  For debugging spin, shows line in the spin direction
        //stroke([aux_root,aux_root+unit(obj2_back)*15], width=1,color="lightblue");
        //stroke([base_root,base_root+unit(obj1_back)*15], width=1,color="lightgreen");

        if (debug_pos)
          move(base_root)rot(from=UP,to=prism_axis) 
            linear_extrude(height=norm(base_root-aux_root))zrot(base_spin-spin)polygon(profile);
        else{
          join_prism(zrot(base_spin-spin,profile),
                     base=base_type, base_r=u_mul(base_r,base_inside),
                     aux=aux_type, aux_T=aux_T, aux_r=u_mul(aux_r,aux_inside),
                     scale=scale, 
                     start=base_root, end=aux_root,
                     base_k=base_k, aux_k=aux_k, base_overlap=base_overlap, aux_overlap=aux_overlap,
                     base_n=base_n, aux_n=aux_n, base_fillet=base_fillet, aux_fillet=aux_fillet,
                     base_smooth_normals = base_smooth_normals, aux_smooth_normals=aux_smooth_normals, 
                     debug=debug,
                     _name1="desc1", _name2="desc2") children();
          }
      }
}


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
