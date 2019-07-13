//////////////////////////////////////////////////////////////////////
// LibFile: roundcorners.scad
//   Routines to create rounded corners, with either circular rounding,
//   or continuous curvature rounding with no sudden curvature transitions.
//   To use, add the following lines to the beginning of your file:
//   ```
//   include <BOSL2/std.scad>
//   include <BOSL2/roundcorners.scad>
//   ```
//////////////////////////////////////////////////////////////////////

include <BOSL2/beziers.scad>
include <BOSL2/structs.scad>


// CommonCode:
//   $fn=36;


// Section: Functions


// Function: round_corners()
//
// Description:
//   Takes a 2D or 3D point list as input (a path or the points of a polygon) and rounds each corner
//   by a specified amount.  The rounding at each point can be different and some points can have zero
//   rounding.  The `round_corners()` function supports two types of rounding: circular rounding and
//   continuous curvature rounding using 4th order bezier curves.  Circular rounding can produce a
//   tactile "bump" where the curvature changes from flat to circular.
//   See https://hackernoon.com/apples-icons-have-that-shape-for-a-very-good-reason-720d4e7c8a14
//   
//   You select the type of rounding using the `curve` option, which should be either `"smooth"` to
//   get continuous curvature rounding or `"circle"` to get circular rounding.  The default is circle
//   rounding.  Each rounding method has two options for how you measure the amount of rounding, which
//   you specify using the `measure` argument.  Both rounding methods accept `measure="cut"`, which is
//   the default.  This mode specifies the amount of rounding as the minimum distance from the corner
//   to the curve.  This can be easier to understand than setting a circular radius, which can be
//   unexpectedly extreme when the corner is very sharp.  It also allows a systematic specification of
//   curves that is the same for both `"circle"` and `"smooth"`.
//   
//   The second `measure` setting for circular rounding is `"radius"`, which sets a circular rounding
//   radius.  The second `measure` setting for smooth rounding is `"joint"` which specifies the distance
//   away from the corner along the path where the roundover should start.  The figure below shows
//   the cut and joint distances for a given roundover.  
//   
//   The `"smooth"` type rounding also has a parameter that specifies how smooth the curvature match
//   is.  This parameter, `k`, ranges from 0 to 1, with a default of 0.5.  Larger values give a more
//   abrupt transition and smaller ones a more gradual transition.  If you set the value much higher
//   than 0.8 the curvature changes abruptly enough that though it is theoretically continuous, it may
//   not be continous in practice.  If you set it very small then the transition is so gradual that
//   the length of the roundover may be extremely long.
//   
//   If you select curves that are too large to fit the function will fail with an error.  It displays
//   a set of scale factors that you can apply to the (first) smoothing parameter that will reduce the
//   size of the curves so that they will fit on your path.  If the scale factors are larger than one
//   then they indicate how much you can increase the curve sizes before collisions will occur.
//   
//   To specify rounding parameters you can use the `size` option to round every point in a path.
//   
//   Examples:
//   * `curve="circle", measure="radius", size=2`:
//       Rounds every point with circular, radius 2 roundover
//   * `curve="smooth", measure="cut", size=2`:
//       Rounds every point with continuous curvature rounding with a cut of 2, and a default 0.5 smoothing parameter
//   * `curve="smooth", measure="cut", size=[2,.3]`:
//       Rounds every point with continuous curvature rounding with a cut of 2, and a very gentle 0.3 smoothness setting
//   
//   The path is a list of 2D or 3D points, possibly with an extra coordinate giving smoothing
//   parameters.  It is important to specify if the path is a closed path or not using the `closed`
//   parameter.  The default is a closed path for making polygons.
//   
//   Path examples:
//   * `[[0,0],[0,1],[1,1],[0,1]]`:
//       2D point list (a square), `size` was given to set rounding
//   * `[[0,0,0], [0,1,1], [1,1,2], [0,1,3]]`:
//       3D point list, `size` was given to set rounding
//   * `[[0,0,0.2],[0,1,0.1],[1,1,0],[0,1,0.3]]`:
//       2D point list with smoothing parameters different at every corner, `size` not given
//   * `[[0,0,0,.2], [0,1,1,.1], [1,1,2,0], [0,1,3,.3]]`:
//       3D point list with smoothing parameters, `size` not given
//   * `[[0,0,[.3,.7], [4,0,[.2,.6]], [4,4,0], [0,4,1]]`:
//       3D point list with smoothing parameters for the `"smooth"` type roundover, `size` not given.
//       Note the third entry is sometimes a pair giving both smoothing parameters, sometimes it's zero
//       specifying no smoothing, and sometimes a single number, specifying the amount of smoothing but
//       using the default smoothness parameter.
//   
//   The number of segments used for roundovers is determined by `$fa`, `$fs` and `$fn` as usual for
//   circular roundovers.  For continuous curvature roundovers `$fs` and `$fn` are used and `$fa` is
//   ignored.  When doing continuous curvature rounding be sure to use lots of segments or the effect
//   will be hidden by the discretization.
//
// Figure(2DMed):
//   h = 18;
//   w = 12.6;
//   example = [[0,0],[w,h],[2*w,0]];
//   color("red")stroke(round_corners(example, size=18, measure="joint", curve="smooth",closed=false),width=.1);
//   stroke(example, width=.1);
//   color("green")stroke([[w,h], [w,h-cos(vector_angle(example)/2) *3/8*h]], width=.1);
//   ll=lerp([w,h], [0,0],18/norm([w,h]-[0,0]) );
//   color("blue")stroke(_shift_segment([[w,h], ll], -.7), width=.1);
//   color("green")translate([w-.3,h-4])scale(.1)rotate(90)text("cut");
//   color("blue")translate([w/2-1.1,h/2+.6])  scale(.1)rotate(90-vector_angle(example)/2)text("joint");
//   
// Arguments:
//   path = list of points defining the path to be rounded.  Can be 2D or 3D, and may have an extra coordinate giving rounding parameters.  If you specify rounding parameters you must do so on every point.  
//   curve = rounding method to use.  Set to "circle" for circular rounding and "smooth" for continuous curvature 4th order bezier rounding
//   measure = how to measure the amount of rounding.  Set to "cut" to specify the cut back with either "smooth" or "circle" rounding curves.  Set to "radius" with `curve="circle"` to set circular radius rounding.  Set to "joint" with `curve="smooth"` for joint type rounding.  (See above for details on these rounding options.)
//   size = curvature parameter(s).  Set this to a single curvature parameter or parameter pair to apply uniform roundovers to every corner.  Alternatively set this to a list of curvature parameters with the same length as `path` to specify the curvature at every corner.  If you set this then all values given in `path` are treated as geometric coordinates.  If you don't set this then the last value of each entry in `path` is treated as a rounding parameter.
//   closed = if true treat the path as a closed polygon, otherwise treat it as open.  Default: true.
//   k = continuous curvature smoothness parameter default value.  This value will apply with `curve=="smooth"` if you don't otherwise specify a smoothness parameter for a corner.  Default: 0.5.  
//
// Example(Med2D): Standard circular roundover with radius the same at every point. Compare results at the different corners.  
//   shape = [[0,0], [10,0], [15,12], [6,6], [6, 12], [-3,7]];
//   polygon(round_corners(shape, curve="circle", measure="radius", size=1));
//   color("red") down(.1) polygon(shape);
// Example(Med2D): Circular roundover using the "cut" specification, the same at every corner.  
//   shape = [[0,0], [10,0], [15,12], [6,6], [6, 12], [-3,7]];
//   polygon(round_corners(shape, curve="circle", measure="cut", size=1));
//   color("red") down(.1) polygon(shape);
// Example(Med2D): Continous curvature roundover using "cut", still the same at every corner.  The default smoothness parameter of 0.5 was too gradual for these roundovers to fit, but 0.7 works.  
//   shape = [[0,0], [10,0], [15,12], [6,6], [6, 12], [-3,7]];
//   polygon(round_corners(shape, curve="smooth", measure="cut", size=[1,.7]));
//   color("red") down(.1) polygon(shape);
// Example(Med2D): Continuous curvature roundover using "joint", for the last time the same at every corner.  Notice how small the roundovers are.  
//   shape = [[0,0], [10,0], [15,12], [6,6], [6, 12], [-3,7]];
//   polygon(round_corners(shape, curve="smooth", measure="joint", size=[1,.7]));
//   color("red") down(.1) polygon(shape);
// Example(Med2D): Circular rounding, different at every corner, some corners left unrounded
//   shape = [[0,0,1.8], [10,0,0], [15,12,2], [6,6,.3], [6, 12,1.2], [-3,7,0]];
//   polygon(round_corners(shape, curve="circle", measure="radius"));
//   color("red") down(.1) polygon(subindex(shape,[0:1]));
// Example(Med2D): Continuous curvature rounding, different at every corner, with varying smoothness parameters as well, and `$fs` set very small
//   shape = [[0,0,[1.5,.6]], [10,0,0], [15,12,2], [6,6,[.3,.7]], [6, 12,[1.2,.3]], [-3,7,0]];
//   polygon(round_corners(shape, curve="smooth", measure="cut", $fs=0.1));
//   color("red") down(.1) polygon(subindex(shape,[0:1]));
// Example(Med3D): 3D printing test pieces to display different curvature shapes.  You can see the discontinuity in the curvature on the "C" piece in the rendered image.  
//   ten = [[0,0,5],[50,0,5],[50,50,5],[0,50,5]];
//   linear_extrude(height=14){
//   translate([25,25,0])text("C",size=30, valign="center", halign="center");
//     translate([85,25,0])text("5",size=30, valign="center", halign="center");
//     translate([85,85,0])text("3",size=30, valign="center", halign="center");
//     translate([25,85,0])text("7",size=30, valign="center", halign="center");
//   }
//   linear_extrude(height=13)
//   {
//     polygon(round_corners(ten, curve="circle", measure="cut"));
//     translate([60,0,0])polygon(round_corners(ten,  curve="smooth", measure="cut"));
//     translate([60,60,0])polygon(round_corners([[0,0],[50,0],[50,50],[0,50]],size=[5,.32],$fs=5,$fa=0,
//                                             curve="smooth", measure="cut"));
//     translate([0,60,0])polygon(round_corners([[0,0],[50,0],[50,50],[0,50]],size=[5,.7],
//                                             curve="smooth", measure="cut"));
//   }   
// Example(Med2D): Rounding a path that is not closed in a three different ways.
//   $fs=.25;
//   $fa=1;
//   zigzagx = [-10, 0, 10, 20, 29, 38, 46, 52, 59, 66, 72, 78, 83, 88, 92, 96, 99, 102, 112];
//   zigzagy = concat([0], flatten(replist([-10,10],8)), [-10,0]);
//   zig = zip(zigzagx,zigzagy);
//   stroke(zig,width=1);   // Original shape
//   fwd(20)            // Smooth size corners with a cut of 4 and curvature parameter 0.6
//     stroke(round_corners(zig,size=[4,0.6],closed=false, curve="smooth", measure="cut"),width=1);
//   fwd(40)            // Smooth size corners with circular arcs and a cut of 4
//     stroke(round_corners(zig,size=4,closed=false, curve="circle", measure="cut"),width=1);
//                      // Smooth size corners with a circular arc and radius 1.5 (close to maximum possible)
//   fwd(60)            // Note how the different points are cut back by different amounts
//     stroke(round_corners(zig,size=1.5,closed=false, curve="circle", measure="radius"),width=1);
// Example(FlatSpin): Rounding some random 3D paths
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
//   path_sweep(regular_ngon(n=36,or=.1),round_corners(list1,closed=false, curve="smooth", measure="cut", size=.65));
//   right(6) 
//     path_sweep(regular_ngon(n=36,or=.1),round_corners(list2,closed=false, curve="circle", measure="cut", size=.75));  
// Example(FlatSpin):  Rounding a spiral with increased rounding along the length
//   // Construct a square spiral path in 3D
//   square = [[0,0],[1,0],[1,1],[0,1]];
//   spiral = flatten(replist(concat(square,reverse(square)),5));  // Squares repeat 10 times, forward and backward
//   squareind = [for(i=[0:9]) each [i,i,i,i]];                    // Index of the square for each point
//   z = list_range(40)*.2+squareind;                              
//   path3d = zip(spiral,z);                                       // 3D spiral 
//   rounding = squareind/20;      // Rounding parameters get larger up the spiral
//       // Setting k=1 means curvature won't be continuous, but curves are as round as possible
//       // Try changing the value to see the effect.  
//   rpath = round_corners(path3d, size=rounding, k=1, curve="smooth", measure="joint",closed=false);
//   path_sweep( regular_ngon(n=36, or=.1), rpath);
function round_corners(path, curve="circle", measure="cut", size=undef,  k=0.5, closed=true) =
	let(    
		default_curvature = k,   // default curvature for "smooth" curves
		measureok = (
			measure == "cut" ||
			(curve=="circle" && measure=="radius") ||
			(curve=="smooth" && measure=="joint")
		),
				path = is_region(path) ?
				  assert(len(path)==1, "Region supplied as path does not have exactly one component")
				  path[0] : path,
		pathdim = array_dim(path,1),
		have_size = size==undef ? 0 : 1,
		pathsize_ok = is_num(pathdim) && pathdim >= 3-have_size && pathdim <= 4-have_size,
				size_ok = !have_size || is_num(size) ||
				   is_list(size) && ((len(size)==2 && curve=="smooth") || len(size)==len(path))
	)
	assert(curve=="smooth" || curve=="circle", "Unknown 'curve' setting in round_corners")
	assert(measureok, curve=="circle"?
		"In round_corners curve==\"circle\" requires 'measure' of 'radius' or 'cut'" :
		"In round_corners curve==\"smooth\" requires 'measure' of 'joint' or 'cut'"
	)
	assert(pathdim!=undef, "Input 'path' has entries with inconsistent length")
	assert(pathsize_ok, str(
		"Input 'path' must have entries with length ",
		2+have_size, " or ", 3+have_size,
		have_size ? " when 'size' is specified" : "when 'all' is not specified"
	))
		assert(len(path)>2,str("Path has length ",len(path),".  Length must be 3 or more."))
		assert(size_ok, is_list(size)?
						  (str("Input `size` has length ", len(size),".  Length must be ",
							  (curve=="smooth"?"2 or ":""), len(path))) :
									  str("Input `size` is ",size," which is not a number"))
	let(
				dim = pathdim - 1 + have_size,
				points = have_size ? path : subindex(path, [0:dim-1]),
				parm = have_size && is_list(size) && len(size)>2 ? size :
					   have_size ? replist(size, len(path)) :
					   subindex(path, dim),
		// dk will be a list of parameters, for the "smooth" curve the distance and curvature parameter pair,
		// and for the "circle" curve, distance and radius.
		dk = [
			for(i=[0:1:len(points)-1]) let(  
				angle = vector_angle(select(points,i-1,i+1))/2,
				parm0 = is_list(parm[i]) ? parm[i][0] : parm[i],
				k = (curve=="circle" && measure=="radius")? parm0 :
					(curve=="circle" && measure=="cut")? parm0 / (1/sin(angle) - 1) : 
					(is_list(parm[i]) && len(parm[i])==2)? parm[i][1] :
					default_curvature
			)
			(!closed && (i==0 || i==len(points)-1))? [0,0] :
			(curve=="circle")? [k/tan(angle), k] :
			(curve=="smooth" && measure=="joint")? [parm0,k] :
			[8*parm0/cos(angle)/(1+4*k),k]
		],
		lengths = [for(i=[0:1:len(points)]) norm(select(points,i)-select(points,i-1))],
		scalefactors = [
			for(i=[0:1:len(points)-1])
				min(
					lengths[i]/sum(subindex(select(dk,i-1,i),0)),
					lengths[i+1]/sum(subindex(select(dk,i,i+1),0))
				)
		]
	)
	echo("Roundover scale factors:",scalefactors)
	assert(min(scalefactors)>=1,"Curves are too big for the path")
	[
		for(i=[0:1:len(points)-1]) each
			(dk[i][0] == 0)? [points[i]] :
			(curve=="smooth")? _bezcorner(select(points,i-1,i+1), dk[i]) :
			_circlecorner(select(points,i-1,i+1), dk[i])
	];

// Computes the continuous curvature control points for a corner when given as
// input three points in a list defining the corner.  The points must be
// equidistant from each other to produce the continuous curvature result.
// The output control points will include the 3 input points plus two
// interpolated points.  
//
// k is the curvature parameter, ranging from 0 for very slow transition
// up to 1 for a sharp transition that doesn't have continuous curvature any more
function _smooth_bez_fill(points,k) = 
			[
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
// calculated from the input point list and the control point list will not
// necessarily include points[0] or points[2] on its output.
//
// The number of points output is $fn if it is set.  Otherwise $fs is used
// to calculate the point count.  

function _bezcorner(points, parm) =
		let(
			P = is_list(parm) ?
				let(
		 d = parm[0],
		 k = parm[1],
		 prev = normalize(points[0]-points[1]),
		 next = normalize(points[2]-points[1]))
			   [
				points[1]+d*prev,
				points[1]+k*d*prev,
				points[1],
				points[1]+k*d*next,
				points[1]+d*next
			   ] :
			_smooth_bez_fill(points,parm),
			N = $fn>0 ? max(3,$fn) : ceil(bezier_segment_length(P)/$fs)
	)
	bezier_curve(P,N);


function _circlecorner(points, parm) =
	let(
		angle = vector_angle(points)/2,
		d = parm[0],
		r = parm[1],
		prev = normalize(points[0]-points[1]),
		next = normalize(points[2]-points[1]),
		center = r/sin(angle) * normalize(prev+next)+points[1],
				start = points[1]+prev*d,
				end = points[1]+next*d
	)
	arc(segs(norm(start-center)), cp=center, points=[start,end]);

function bezier_curve(P,N) =
   [for(i=[0:1:N-1]) bez_point(P, i/(N-1))];


// Module: rounded_sweep()
//
// Description:
//   Takes a 2d path as input and extrudes it to a specified height with roundovers or chamfers at the ends.
//   The rounding is accomplished by using offset to shift the input path.  The path is shifted multiple times
//   in sequence to produce the profile (not multiple shifts from one parent), so coarse definition of the input path will
//   degrade from the successive shifts.  If the result seems rough or strange try increasing the number of points you use for your input.
//   However, be aware that large numbers of points (especially when check_valid is true) can lead to lengthy run times.
//   If your shape doesn't develop corners you may be able to save a lot of time by setting `check_valid=false`.  Be aware that disabling the
//   validity check when it is needed can generate invalid polyhedra that will produce CGAL errors upon rendering.  
//   Multiple rounding shapes are available, including circular rounding, teardrop rounding, and chamfer "rounding".
//   Also note that if the rounding radius is negative then the rounding will flare outwards.
//   
//   Rounding options:
//   - "circle": Circular rounding with radius as specified
//   - "teardrop": Rounding using a 1/8 circle that then changes to a 45 degree chamfer.  The chamfer is at the end, and enables the object to be 3d printed without support.  The radius gives the radius of the circular part.
//   - "chamfer": Chamfer the edge at desired angle or with desired height and width.  You can specify height and width together and the angle will be ignored, or specify just one of height and width and the angle is used to determine the shape.  Alternatively, specify "cut" along with angle to specify the cut back distance of the chamfer.  
//   - "smooth": Continuous curvature rounding, with "cut" and "joint" as for round_corners
//   - "custom": Specify "points",[list] to get a custom "roundover".  The first point must be [0,0] and the roundover should rise in the positive y direction, with positive x values for inward motion (standard roundover) and negative x values for flaring outward.  It is recommended that the y values are increasing, but this condition is not enforced.  It is the user's responsibility to avoid creating invalid self-intersecting polyhedra when violating this condition.  
//   
//   The rounding spec is a list of pairs of keywords and values, e.g. ["r",12, type, "circle"]. The keywords are
//   - "type" - type of rounding to apply, one of "circle", "teardrop", "chamfer", "smooth", or "custom" (Default: "circle")
//   - "r" - the radius of the roundover, which may be zero for no roundover, or negative to round or flare outward.  Default: 0
//   - "cut" - the cut distance for the roundover or chamfer, which may be negative for flares
//   - "width" - the width of a chamfer
//   - "height" - the height of a chamfer
//   - "angle" - the chamfer angle, measured from the vertical (so zero is vertical, 90 is horizontal).  Default: 45
//   - "joint" - the joint distance for a "smooth" roundover
//   - "k" - the curvature smoothness parameter for "smooth" roundovers, a value in [0,1].  Default: 0.75
//   - "points" - point list for use with the "custom" type
//   - "extra" - extra height added for unions/differences.  This makes the shape taller than the requested height.  (Default: 0) 
//   - "check_valid" - passed to offset.  Default: true.
//   - "quality" - passed to offset.  Default: 1.
//   - "steps" - number of vertical steps to use for the roundover.  Default: 16.
//   - "offset_maxstep" - maxstep distance for offset() calls; controls the horizontal step density.  Default: 1
//   - "offset" - select "round" (r=) or "delta" (delta=) offset type for offset.  Default: "round"
//
//   You can change the the defaults by passing an argument to the rounded_sweep, which is more convenient if you want
//   a setting to be the same at both ends.  
//
//   You can use several helper functions to provide the rounding spec.  These use function arguments to set the same parameters listed above, where the
//   function name indicates the type of rounding and only parameters valid for that rounding type are accepted:
//   - rs_circle(r,cut,extra,check_valid, quality,steps, offset_maxstep, offset)
//   - rs_teardrop(r,cut,extra,check_valid, quality,steps, offset_maxstep, offset)
//   - rs_chamfer(height, width, cut, extra,check_valid, quality,steps, offset_maxstep, offset)
//   - rs_smooth(cut, joint, extra,check_valid, quality,steps, offset_maxstep, offset)
//   - rs_custom(points, extra,check_valid, quality,steps, offset_maxstep, offset)
// 
//   For example, you could round a path using `rounded_sweep(path, top=rs_teardrop(r=10), bottom=rs_chamfer(height=-10,extra=1))`
//   Many of the arguments are described as setting "default" values because they establish settings which may be overridden by 
//   the top and bottom rounding specifications.  
//
// Arguments:
//   path = 2d path (list of points) to extrude
//   height = total height (including rounded portions, but not extra sections) of the output
//   top = rounding spec for the top end.  
//   bottom = rounding spec for the bottom end 
//   offset = default offset, `"round"` or `"delta"`.  Default: `"round"`
//   steps = default step count.  Default: 16
//   quality = default quality.  Default: 1
//   check_valid = default check_valid.  Default: true.
//   offset_maxstep = default maxstep value to pass to offset.  Default: 1
//   extra = default extra height.  Default: 0
//   cut = default cut value.
//   width = default width value for chamfers.
//   height = default height value for chamfers.
//   angle = default angle for chamfers.  Default: 45
//   joint = default joint value for smooth roundover.
//   k = default curvature parameter value for "smooth" roundover
//   convexity = convexity setting for use with polyhedron.  Default: 10
//
// Example: Rounding a star shaped prism with postive radius values
//   star = star(5, r=22, ir=13);
//   rounded_star = round_corners(zip(star, flatten(replist([.5,0],5))), curve="circle", measure="cut", $fn=12);
//   rounded_sweep(rounded_star, height=20, bottom=rs_circle(r=4), top=rs_circle(r=1), steps=15);
// Example: Rounding a star shaped prism with negative radius values
//   star = star(5, r=22, ir=13);
//   rounded_star = round_corners(zip(star, flatten(replist([.5,0],5))), curve="circle", measure="cut", $fn=12);
//   rounded_sweep(rounded_star, height=20, bottom=rs_circle(r=-4), top=rs_circle(r=-1), steps=15);
// Example: Here is the star chamfered at the top with a teardrop rounding at the bottom. Check out the rounded corners on the chamfer.  Note that a very small value of `offset_maxstep` is needed to keep these round.  Observe how the rounded star points vanish at the bottom in the teardrop: the number of vertices does not remain constant from layer to layer.  
//   star = star(5, r=22, ir=13);
//   rounded_star = round_corners(zip(star, flatten(replist([.5,0],5))), curve="circle", measure="cut", $fn=12);
//   rounded_sweep(rounded_star, height=20, bottom=rs_teardrop(r=4), top=rs_chamfer(width=4,offset_maxstep=.1));
// Example: We round a cube using the continous curvature rounding profile.  But note that the corners are not smooth because the curved square collapses into a square with corners.    When a collapse like this occurs, we cannot turn `check_valid` off.  
//   square = [[0,0],[1,0],[1,1],[0,1]];
//   rsquare = round_corners(square, curve="smooth", measure="cut", size=[.1,.7], $fn=36);
//   end_spec = rs_smooth(cut=0.1, k=0.7, steps=22);
//   rounded_sweep(rsquare, height=1, bottom=end_spec, top=end_spec);
// Example: A nice rounded box, with a teardrop base and circular rounded interior and top
//   box = ([[0,0], [0,50], [255,50], [255,0]]);
//   rbox = round_corners(box, curve="smooth", measure="cut", size=4, $fn=36);
//   thickness = 2;
//   difference(){
//     rounded_sweep(rbox, height=50, check_valid=false, steps=22, bottom=rs_teardrop(r=2), top=rs_circle(r=1));
//     up(thickness)
//       rounded_sweep(offset(rbox, r=-thickness, closed=true,check_valid=false),
//                     height=48, steps=22, check_valid=false, bottom=rs_circle(r=4), top=rs_circle(r=-1,extra=1));
//   }
// Example: This box is much thicker, and cut in half to show the profiles.  Note also that we can turn `check_valid` off for the outside and for the top inside, but not for the bottom inside.  This example shows use of the direct keyword syntax without the helper functions.  
//   smallbox = [[0,0], [0,50], [75,50], [75,0]];
//   roundbox = round_corners(smallbox, curve="smooth", measure="cut", size=4, $fn=36);
//   thickness=4;
//   height=50;
//   back_half(y=37, s=200)
//     difference(){
//       rounded_sweep(roundbox, height=height, bottom=["r",10,"type","teardrop"], top=["r",2], steps = 22, check_valid=false);
//       up(thickness)
//         rounded_sweep(offset(roundbox, r=-thickness, closed=true),
//                       height=height-thickness, steps=22,
//                       bottom=["r",6],
//                       top=["type","chamfer","angle",30,"height",-3,"extra",1,"check_valid",false]); 
//     }
// Example: Star shaped box
//   star = star(5, r=22, ir=13);
//   rounded_star = round_corners(zip(star, flatten(replist([.5,0],5))), curve="circle", measure="cut", $fn=12);
//   thickness = 2;
//   ht=20;
//   difference(){
//     rounded_sweep(rounded_star, height=ht, bottom=["r",4], top=["r",1], steps=15);
//     up(thickness)
//         rounded_sweep(offset(rounded_star,r=thickness,closed=true),
//                       height=ht-thickness, check_valid=false,
//                       bottom=rs_circle(r=7), top=rs_circle(r=-1, extra=1));
//     }
// Example: A custom profile defined by an arbitrary sequence of points. 
//   star = star(5, r=22, ir=13);
//   rounded_star = round_corners(zip(star, flatten(replist([.5,0],5))), curve="circle", measure="cut", $fn=12);
//   custom = rs_custom(points=[[0,0],[.3,.1],[.6,.3],[.9,.9], [1.2, 2.7],[.8,2.7],[.8,3]]);
//   rounded_sweep(reverse(rounded_star), height=20, top=custom, bottom=custom);
// Example: Custom parabolic rounding
//   star = star(5, r=22, ir=13);
//   rounded_star = round_corners(zip(star, flatten(replist([.5,0],5))), curve="circle", measure="cut", $fn=12);
//   rounded_sweep(rounded_star, height=20, top=rs_custom(points=[for(r=[0:.1:2])[sqr(r),r]]),
//                                          bottom=rs_custom(points=[for(r=[0:.2:5])[-sqrt(r),r]]));
// Example: This example takes the roundover concept to an extreme with a sine wave custom roundover.  Note that because the offsets occur sequentially and the path grows incrementally the offset needs a very fine resolution to produce the proper result.  Note that we give no specification for the bottom and it is left unrounded.  
//   sq = [[0,0],[20,0],[20,20],[0,20]];
//   sinwave = rs_custom(points=[for(theta=[0:5:720]) [4*sin(theta), theta/700*15]]);
//   rounded_sweep(sq, height=20, top=sinwave, offset_maxstep=.05);
// Example: The same as the previous example but `offset="delta"`
//   sq = [[0,0],[20,0],[20,20],[0,20]];
//   sinwave = rs_custom(points=[for(theta=[0:5:720]) [4*sin(theta), theta/700*15]]);
//   rounded_sweep(sq, height=20, top=sinwave, offset_maxstep=.05, offset="delta");
// Example: a box with a flared top.  A nice roundover on the top requires a custom edge, but we can use "extra" to create a small chamfer.
//   rhex = round_corners(hexagon(side=10), curve="smooth",measure="joint", size=2, $fs=0.2);
//   back_half()
//     difference(){
//       rounded_sweep(rhex, height=10, bottom=rs_teardrop(r=2), top=rs_teardrop(r=-4, extra=0.2));
//       up(1)
//         rounded_sweep(offset(rhex,r=1), height=9.5, bottom=rs_circle(r=2), top=rs_teardrop(r=-4));
//     }
module rounded_sweep(path, height, top=[], bottom=[], offset="round", r=undef, steps=16, quality=1, check_valid=true, offset_maxstep=1, extra=0, 
                     cut=undef, width=undef, joint=undef, k=0.75, angle=45, convexity=10)
{
    // This function does the actual work of repeatedly calling offset() and concatenating the resulting face and vertex lists to produce
    // the inputs for the polyhedron module.  
    function make_polyhedron(path,offsets, offset_type, flip_faces, quality, check_valid, maxstep, offsetind=0, vertexcount=0, vertices=[], faces=[] )=
     offsetind==len(offsets) ?
         let( bottom = list_range(n=len(path),s=vertexcount),
              oriented_bottom = !flip_faces ? bottom : reverse(bottom)
           )
         [vertices, concat(faces,[oriented_bottom])] :
      let( this_offset = offsetind==0 ? offsets[0][0] : offsets[offsetind][0] - offsets[offsetind-1][0],
           delta = offset_type=="delta" ? this_offset : undef,
           r = offset_type=="round" ? this_offset : undef)
      assert(num_defined([r,delta])==1,"Must set `offset` to \"round\" or \"delta")
      let(
           vertices_faces = offset(path, r=r, delta=delta, closed=true, check_valid=check_valid, quality=quality, maxstep=maxstep, 
                                       return_faces=true, firstface_index=vertexcount, flip_faces=flip_faces)
          )
        make_polyhedron(vertices_faces[0], offsets, offset_type, flip_faces, quality, check_valid, maxstep, offsetind+1, vertexcount+len(path),
                                    vertices=concat(vertices, zip(vertices_faces[0],replist(offsets[offsetind][1],len(vertices_faces[0])))),
                                    faces=concat(faces, vertices_faces[1]));
  

    // Produce edge profile curve from the edge specification
    // z_dir is the direction multiplier (1 to build up, -1 to build down)
    function rounding_offsets(edgespec,flipR,z_dir=1) =
      let( 
        edgetype = struct_val(edgespec, "type"),
        extra = struct_val(edgespec,"extra"),
        N = struct_val(edgespec, "steps"),
        r = flipR * struct_val(edgespec,"r"),
        cut = flipR * struct_val(edgespec,"cut"),
        k = struct_val(edgespec,"k"),
        radius = in_list(edgetype,["circle","teardrop"]) ?
                        first_defined([cut/(sqrt(2)-1),r]) : 
                 edgetype=="chamfer" ? first_defined([sqrt(2)*cut,r]) :
                 undef,
        chamf_angle = struct_val(edgespec, "angle"),
        cheight = struct_val(edgespec, "height"),
        cwidth = flipR * struct_val(edgespec, "width"),
        chamf_width = first_defined([cut/cos(chamf_angle), cwidth, cheight*tan(chamf_angle)]),
        chamf_height = first_defined([cut/sin(chamf_angle),cheight, cwidth/tan(chamf_angle)]),
        joint = first_defined([flipR*struct_val(edgespec,"joint"),
                               16*cut/sqrt(2)/(1+4*k)]),
        points = struct_val(edgespec, "points"), 
        argsOK = in_list(edgetype,["circle","teardrop"]) ? is_def(radius) :
                 edgetype == "chamfer" ? angle>0 && angle<90 && num_defined([chamf_height,chamf_width])==2 :
                 edgetype == "smooth" ? num_defined([k,joint])==2 :
                 edgetype == "custom" ? points[0]==[0,0] :
                 false)
    assert(argsOK,str("Invalid specification with type ",edgetype))
    let(
        offsets =  edgetype == "custom" ? scale([-flipR,z_dir], slice(points,1,-1)) :
                   edgetype == "chamfer" ?  width==0 && height==0 ? [] : [[-chamf_width,z_dir*abs(chamf_height)]] :
                   edgetype == "teardrop" ? radius==0 ? [] : concat([for(i=[1:N]) [radius*(cos(i*45/N)-1),z_dir*abs(radius)* sin(i*45/N)]],
                                   [[-2*radius*(1-sqrt(2)/2), z_dir*abs(radius)]]):
                   edgetype == "circle" ?  radius==0 ? [] : [for(i=[1:N]) [radius*(cos(i*90/N)-1), z_dir*abs(radius)*sin(i*90/N)]] :
                   /* smooth */  joint==0 ? [] :
                                 select(
                                        _bezcorner([[0,0],[0,z_dir*abs(joint)],[-joint,z_dir*abs(joint)]], k, $fn=N+2),
                                        1, -1) 
      ) 
      extra > 0 ? concat(offsets, [select(offsets,-1)+[0,z_dir*extra]]) : offsets;

  
  argspec = [["r",0],
             ["extra",0],
             ["type","circle"],
             ["check_valid",check_valid],
             ["quality",quality],
             ["offset_maxstep", offset_maxstep],
             ["steps",steps],
             ["offset",offset],
             ["width",width],
             ["height",undef],
             ["angle",angle],
             ["cut",cut],
             ["joint",joint],
             ["k", k],
             ["points", []],
            ];
  top = struct_set(argspec, top, grow=false);
  bottom = struct_set(argspec, bottom, grow=false);

  struct_echo(top,"top");
  
  clockwise = polygon_clockwise(path);
  flipR = clockwise ? 1 : -1;

  assert(height>=0, "Height must be nonnegative");

  /*  This code does not work.  It hits the error in make_polyhedron from offset being wrong
      before this code executes.  Had to move the test into make_polyhedron, which is ugly since it's in the loop
  offsetsok = in_list(struct_val(top, "offset"),["round","delta"])
               && in_list(struct_val(bottom, "offset"),["round","delta"]);
  assert(offsetsok,"Offsets must be one of \"round\" or \"delta\"");
  */
  
  offsets_bot = rounding_offsets(bottom, flipR,-1);
  offsets_top = rounding_offsets(top, flipR,1);

  echo(ofstop = offsets_top);
  
  // "Extra" height enlarges the result beyond the requested height, so subtract it
  bottom_height = len(offsets_bot)==0 ? 0 : abs(select(offsets_bot,-1)[1]) - struct_val(bottom,"extra");
  top_height = len(offsets_top)==0 ? 0 : abs(select(offsets_top,-1)[1]) - struct_val(top,"extra");

  middle = height-bottom_height-top_height;
  assert(middle>=0,str("Specified end treatments (bottom height = ",bottom_height,
                       " top_height = ",top_height,") are too large for extrusion height (",height,")"));
  initial_vertices_bot = path3d(path);

  vertices_faces_bot = make_polyhedron(path, offsets_bot, struct_val(bottom,"offset"), clockwise,
                                       struct_val(bottom,"quality"),struct_val(bottom,"check_valid"),struct_val(bottom,"offset_maxstep"),
                                       vertices=initial_vertices_bot);

  top_start_ind = len(vertices_faces_bot[0]);
  initial_vertices_top = zip(path, replist(middle,len(path)));
  vertices_faces_top = make_polyhedron(path, translate_points(offsets_top,[0,middle]), struct_val(top,"offset"), !clockwise,
                                                 struct_val(top,"quality"),struct_val(top,"check_valid"),struct_val(top,"offset_maxstep"),
                                                 vertexcount=top_start_ind, vertices=initial_vertices_top);
  middle_faces = middle==0 ? [] :
    [for(i=[0:len(path)-1]) let(oneface=[i, (i+1)%len(path), top_start_ind+(i+1)%len(path), top_start_ind+i])
                              !clockwise ? reverse(oneface) : oneface];
  up(bottom_height)
    polyhedron(concat(vertices_faces_bot[0],vertices_faces_top[0]),
               faces=concat(vertices_faces_bot[1], vertices_faces_top[1], middle_faces),convexity=convexity);
  echo(botv=vertices_faces_bot[0]);
  echo(topv=vertices_faces_top[0]);
  echo(fbot=vertices_faces_bot[1]);
  echo(ftop=vertices_faces_top[1]);
  echo(fmid=middle_faces);
}

function rs_circle(r,cut,extra,check_valid, quality,steps, offset_maxstep, offset) =
     assert(num_defined([r,cut])==1, "Must define exactly one of `r` and `cut`")
     _remove_undefined_vals(
     [
      "type", "circle",
      "r",r,
      "cut",cut,
      "extra",extra,
      "check_valid",check_valid,
      "quality", quality,
      "steps", steps,
      "offset_maxstep", offset_maxstep,
      "offset", offset
     ]);

function rs_teardrop(r,cut,extra,check_valid, quality,steps, offset_maxstep, offset) =
     assert(num_defined([r,cut])==1, "Must define exactly one of `r` and `cut`")
     _remove_undefined_vals(
     [
      "type", "teardrop",
      "r",r,
      "cut",cut,
      "extra",extra,
      "check_valid",check_valid,
      "quality", quality,
      "steps", steps,
      "offset_maxstep", offset_maxstep,
      "offset", offset
     ]);

function rs_chamfer(height, width, cut, angle, extra,check_valid, quality,steps, offset_maxstep, offset) =
     let(ok = (is_def(cut) && num_defined([height,width])==0) || num_defined([height,width])>0)
     assert(ok, "Must define `cut`, or one or both of `width` and `height`")
     _remove_undefined_vals(
     [
      "type", "chamfer",
      "width",width,
      "height",height,
      "cut",cut,
      "angle",angle,
      "extra",extra,
      "check_valid",check_valid,
      "quality", quality,
      "steps", steps,
      "offset_maxstep", offset_maxstep,
      "offset", offset
     ]);

function rs_smooth(cut, joint, k, extra,check_valid, quality,steps, offset_maxstep, offset) =
     assert(num_defined([joint,cut])==1, "Must define exactly one of `joint` and `cut`")
     _remove_undefined_vals(
     [
      "type", "smooth",
      "joint",joint,
      "k",k,
      "cut",cut,
      "extra",extra,
      "check_valid",check_valid,
      "quality", quality,
      "steps", steps,
      "offset_maxstep", offset_maxstep,
      "offset", offset
     ]);

function rs_custom(points, extra,check_valid, quality,steps, offset_maxstep, offset) =
     //assert(is_path(points),"Custom point list is not valid")
     _remove_undefined_vals(
     [
      "type", "custom",
      "points", points,
      "extra",extra,
      "check_valid",check_valid,
      "quality", quality,
      "steps", steps,
      "offset_maxstep", offset_maxstep,
      "offset", offset
     ]);
          

function _remove_undefined_vals(list) =
     let(ind=search([undef],list,0)[0]) 
     list_remove(list, concat(ind, add_scalar(ind,-1)));


// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap


