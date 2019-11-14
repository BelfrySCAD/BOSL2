//////////////////////////////////////////////////////////////////////
// LibFile: rounding.scad
//   Routines to create rounded corners, with either circular rounding,
//   or continuous curvature rounding with no sudden curvature transitions.
//   To use, add the following lines to the beginning of your file:
//   ```
//   include <BOSL2/std.scad>
//   include <BOSL2/rounding.scad>
//   ```
//////////////////////////////////////////////////////////////////////

include <BOSL2/beziers.scad>
include <BOSL2/strings.scad>
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
		path = is_region(path)?
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
	assert(size_ok,
		is_list(size)?  (
			str(
				"Input `size` has length ", len(size),
				".  Length must be ",
				(curve=="smooth"?"2 or ":""), len(path)
			)
		) : str("Input `size` is ",size," which is not a number")
	)
	let(
		dim = pathdim - 1 + have_size,
		points = have_size ? path : subindex(path, [0:dim-1]),
		parm = have_size && is_list(size) && len(size)>2? size :
			have_size? replist(size, len(path)) :
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
// calculated from the input point list and the control point list will not
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
				prev = normalize(points[0]-points[1]),
				next = normalize(points[2]-points[1])
			) [
				points[1]+d*prev,
				points[1]+k*d*prev,
				points[1],
				points[1]+k*d*next,
				points[1]+d*next
			] : _smooth_bez_fill(points,parm),
		N = max(3,$fn>0 ?$fn : ceil(bezier_segment_length(P)/$fs))
	)
	bezier_curve(P,N);


function _circlecorner(points, parm) =
	let(
		angle = vector_angle(points)/2,
                df=echo(angle=angle),
		d = parm[0],
		r = parm[1],
		prev = normalize(points[0]-points[1]),
		next = normalize(points[2]-points[1]),
		center = r/sin(angle) * normalize(prev+next)+points[1],
			start = points[1]+prev*d,
			end = points[1]+next*d
	)
	arc(max(3,angle/180*segs(norm(start-center))), cp=center, points=[start,end]);


// Module: offset_sweep()
//
// Description:
//   Takes a 2d path as input and extrudes it upwards and/or downward.  Each layer in the extrusion is produced using `offset()` to expand or shrink the previous layer. 
//   You can specify a sequence of offsets values, or you can use several built-in offset profiles that are designed to provide end treatments such as roundovers.  
//   The path is shifted by `offset()` multiple times in sequence
//   to produce the final shape (not multiple shifts from one parent), so coarse definition of the input path will degrade
//   from the successive shifts.  If the result seems rough or strange try increasing the number of points you use for
//   your input.  If you get unexpected corners in your result, decrease `offset_maxstep` or decrease `steps`.  You must
//   choose `offset_maxstep` small enough so that the first offset step rounds, otherwise you will probably not get any
//   rounding, even if you have selected rounding.  This may require a much smaller value than you expect.  However, be
//   aware that large numbers of points (especially when check_valid is true) can lead to lengthy run times.  If your
//   shape doesn't develop corners you may be able to save a lot of time by setting `check_valid=false`.  Be aware that
//   disabling the validity check when it is needed can generate invalid polyhedra that will produce CGAL errors upon
//   rendering.  Such validity errors will also occur if you specify a self-intersecting shape.
//   The offset profile is quantized to 1/1024 steps to avoid failures in offset() that can occur with very tiny offsets.  
//   
//   The build-in profiles are: circular rounding, teardrop rounding, chamfer, continuous curvature rounding, and chamfer.  
//   Also note that when a rounding radius is negative the rounding will flare outwards.  The easieast way to specify
//   the profile is by using the profile helper functions.  These functions take profile parameters, as well as some
//   general settings and translate them into a profile specification, with error checking on your input.  The description below
//   describes the helper functions and the parameters specific to each function.  Below that is a description of the generic
//   settings that you can optionally use with all of the helper functions.  
//   
//   - profile: os_profile(points)
//     Define the offset profile with a list of points.  The first point must be [0,0] and the roundover should rise in the positive y direction, with positive x values for inward motion (standard roundover) and negative x values for flaring outward.  If the y value ever decreases then you might create a self-intersecting polyhedron, which is invalid.  Such invalid polyhedra will create cryptic assertion errors when you render your model and it is your responsibility to avoid creating them.  Note that the starting point of the profile is the center of the extrusion.  If you use a profile as the top it will rise upwards.  If you use it as the bottom it will be inverted, and will go downward.  
//   - circle: os_circle(r|cut).  Define circular rounding either by specifying the radius or cut distance.  
//   - smooth: os_smooth(cut|joint).  Define continuous curvature rounding, with `cut` and `joint` as for round_corners.
//   - teardrop: os_teardrop(r|cut).  Rounding using a 1/8 circle that then changes to a 45 degree chamfer.  The chamfer is at the end, and enables the object to be 3d printed without support.  The radius gives the radius of the circular part.
//   - chamfer: os_chamfer([height], [width], [cut], [angle]).  Chamfer the edge at desired angle or with desired height and width.  You can specify height and width together and the angle will be ignored, or specify just one of height and width and the angle is used to determine the shape.  Alternatively, specify "cut" along with angle to specify the cut back distance of the chamfer.
//   
//   The general settings that you can use with all of the helper functions are mostly used to control how offset_sweep() calls the offset() function.
//   - extra: Add an extra vertical step of the specified height, to be used for intersections or differences.  This extra step will extend the resulting object beyond the height you specify.  Default: 0
//   - check_valid: passed to offset().  Default: true
//   - quality: passed to offset().  Default: 1
//   - steps: Number of vertical steps to use for the profile.  (Not used by os_profile).  Default: 16
//   - offset_maxstep: The maxstep distance for offset() calls; controls the horizontal step density.  Set smaller if you don't get the expected rounding.  Default: 1
//   - offset: Select "round" (r=) or "delta" (delta=) offset types for offset.  Default: "round"
//   
//   Many of the arguments are described as setting "default" values because they establish settings which may be overridden by 
//   the top and bottom profile specifications.  
//   
//   You will generally want to use the above helper functions to generate the profiles.  
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
//   - "check_valid" - passed to offset.  Default: true.
//   - "quality" - passed to offset.  Default: 1.
//   - "steps" - number of vertical steps to use for the roundover.  Default: 16.
//   - "offset_maxstep" - maxstep distance for offset() calls; controls the horizontal step density.  Set smaller if you don't get expected rounding.  Default: 1
//   - "offset" - select "round" (r=) or "delta" (delta=) offset type for offset.  Default: "round"
//
// Arguments:
//   path = 2d path (list of points) to extrude
//   height / l / h = total height (including rounded portions, but not extra sections) of the output.  Default: combined height of top and bottom end treatments.  
//   top = rounding spec for the top end.  
//   bottom = rounding spec for the bottom end 
//   offset = default offset, `"round"` or `"delta"`.  Default: `"round"`
//   steps = default step count.  Default: 16
//   quality = default quality.  Default: 1
//   check_valid = default check_valid.  Default: true.
//   offset_maxstep = default maxstep value to pass to offset.  Default: 1
//   extra = default extra height.  Default: 0
//   cut = default cut value.
//   chamfer_width = default width value for chamfers.
//   chamfer_height = default height value for chamfers.
//   angle = default angle for chamfers.  Default: 45
//   joint = default joint value for smooth roundover.
//   k = default curvature parameter value for "smooth" roundover
//   convexity = convexity setting for use with polyhedron.  Default: 10
//
// Example: Rounding a star shaped prism with postive radius values
//   star = star(5, r=22, ir=13);
//   rounded_star = round_corners(zip(star, flatten(replist([.5,0],5))), curve="circle", measure="cut", $fn=12);
//   offset_sweep(rounded_star, height=20, bottom=os_circle(r=4), top=os_circle(r=1), steps=15);
// Example: Rounding a star shaped prism with negative radius values
//   star = star(5, r=22, ir=13);
//   rounded_star = round_corners(zip(star, flatten(replist([.5,0],5))), curve="circle", measure="cut", $fn=12);
//   offset_sweep(rounded_star, height=20, bottom=os_circle(r=-4), top=os_circle(r=-1), steps=15);
// Example: Unexpected corners in the result even with `offset="round"` (the default), even with offset_maxstep set small.  
//   triangle = [[0,0],[10,0],[5,10]];
//   offset_sweep(triangle, height=6, bottom = os_circle(r=-2),steps=16,offset_maxstep=0.25);
// Example: Can improve the result by decreasing the number of steps
//   triangle = [[0,0],[10,0],[5,10]];
//   offset_sweep(triangle, height=6, bottom = os_circle(r=-2),steps=4,offset_maxstep=0.25);
// Example: Or by decreasing `offset_maxstep`
//   triangle = [[0,0],[10,0],[5,10]];
//   offset_sweep(triangle, height=6, bottom = os_circle(r=-2),steps=16,offset_maxstep=0.01);
// Example: Here is the star chamfered at the top with a teardrop rounding at the bottom. Check out the rounded corners on the chamfer.  Note that a very small value of `offset_maxstep` is needed to keep these round.  Observe how the rounded star points vanish at the bottom in the teardrop: the number of vertices does not remain constant from layer to layer.  
//   star = star(5, r=22, ir=13);
//   rounded_star = round_corners(zip(star, flatten(replist([.5,0],5))), curve="circle", measure="cut", $fn=12);
//   offset_sweep(rounded_star, height=20, bottom=os_teardrop(r=4), top=os_chamfer(width=4,offset_maxstep=.1));
// Example: We round a cube using the continous curvature rounding profile.  But note that the corners are not smooth because the curved square collapses into a square with corners.    When a collapse like this occurs, we cannot turn `check_valid` off.  
//   square = [[0,0],[1,0],[1,1],[0,1]];
//   rsquare = round_corners(square, curve="smooth", measure="cut", size=[.1,.7], $fn=36);
//   end_spec = os_smooth(cut=0.1, k=0.7, steps=22);
//   offset_sweep(rsquare, height=1, bottom=end_spec, top=end_spec);
// Example: A nice rounded box, with a teardrop base and circular rounded interior and top
//   box = ([[0,0], [0,50], [255,50], [255,0]]);
//   rbox = round_corners(box, curve="smooth", measure="cut", size=4, $fn=36);
//   thickness = 2;
//   difference(){
//     offset_sweep(rbox, height=50, check_valid=false, steps=22, bottom=os_teardrop(r=2), top=os_circle(r=1));
//     up(thickness)
//       offset_sweep(offset(rbox, r=-thickness, closed=true,check_valid=false),
//                     height=48, steps=22, check_valid=false, bottom=os_circle(r=4), top=os_circle(r=-1,extra=1));
//   }
// Example: This box is much thicker, and cut in half to show the profiles.  Note also that we can turn `check_valid` off for the outside and for the top inside, but not for the bottom inside.  This example shows use of the direct keyword syntax without the helper functions.  
//   smallbox = [[0,0], [0,50], [75,50], [75,0]];
//   roundbox = round_corners(smallbox, curve="smooth", measure="cut", size=4, $fn=36);
//   thickness=4;
//   height=50;
//   back_half(y=25, s=200)
//     difference(){
//       offset_sweep(roundbox, height=height, bottom=["r",10,"type","teardrop"], top=["r",2], steps = 22, check_valid=false);
//       up(thickness)
//         offset_sweep(offset(roundbox, r=-thickness, closed=true),
//                       height=height-thickness, steps=22,
//                       bottom=["r",6],
//                       top=["type","chamfer","angle",30,"chamfer_height",-3,"extra",1,"check_valid",false]); 
//     }
// Example: A box with multiple sections and rounded dividers
//   thickness = 2;
//   box = ([[0,0], [0,50], [255,50], [255,0]]);
//   cutpoints = [0, 125, 190, 255];
//   rbox = round_corners(box, curve="smooth", measure="cut", size=4, $fn=36);
//   back_half(y=25, s=700)
//     difference(){
//       offset_sweep(rbox, height=50, check_valid=false, steps=22, bottom=os_teardrop(r=2), top=os_circle(r=1));
//       up(thickness)
//         for(i=[0:2]){
//           ofs = i==1 ? 2 : 0;
//           hole = round_corners([[cutpoints[i]-ofs,0], [cutpoints[i]-ofs,50], [cutpoints[i+1]+ofs, 50], [cutpoints[i+1]+ofs,0]],
//                                curve="smooth", measure="cut", size=4, $fn=36);
//           offset_sweep(offset(hole, r=-thickness, closed=true,check_valid=false),
//                         height=48, steps=22, check_valid=false, bottom=os_circle(r=4), top=os_circle(r=-1,extra=1));
//   
//         }
//     }
// Example: Star shaped box
//   star = star(5, r=22, ir=13);
//   rounded_star = round_corners(zip(star, flatten(replist([.5,0],5))), curve="circle", measure="cut", $fn=12);
//   thickness = 2;
//   ht=20;
//   difference(){
//     offset_sweep(rounded_star, height=ht, bottom=["r",4], top=["r",1], steps=15);
//     up(thickness)
//         offset_sweep(offset(rounded_star,r=-thickness,closed=true),
//                       height=ht-thickness, check_valid=false,
//                       bottom=os_circle(r=7), top=os_circle(r=-1, extra=1));
//     }
// Example: A profile defined by an arbitrary sequence of points. 
//   star = star(5, r=22, ir=13);
//   rounded_star = round_corners(zip(star, flatten(replist([.5,0],5))), curve="circle", measure="cut", $fn=12);
//   profile = os_profile(points=[[0,0],[.3,.1],[.6,.3],[.9,.9], [1.2, 2.7],[.8,2.7],[.8,3]]);
//   offset_sweep(reverse(rounded_star), height=20, top=profile, bottom=profile);
// Example: Parabolic rounding
//   star = star(5, r=22, ir=13);
//   rounded_star = round_corners(zip(star, flatten(replist([.5,0],5))), curve="circle", measure="cut", $fn=12);
//   offset_sweep(rounded_star, height=20, top=os_profile(points=[for(r=[0:.1:2])[sqr(r),r]]),
//                                          bottom=os_profile(points=[for(r=[0:.2:5])[-sqrt(r),r]]));
// Example: This example uses a sine wave offset profile.  Note that because the offsets occur sequentially and the path grows incrementally the offset needs a very fine resolution to produce the proper result.  Note that we give no specification for the bottom, so it is straight.  
//   sq = [[0,0],[20,0],[20,20],[0,20]];
//   sinwave = os_profile(points=[for(theta=[0:5:720]) [4*sin(theta), theta/700*15]]);
//   offset_sweep(sq, height=20, top=sinwave, offset_maxstep=.05);
// Example: The same as the previous example but `offset="delta"`
//   sq = [[0,0],[20,0],[20,20],[0,20]];
//   sinwave = os_profile(points=[for(theta=[0:5:720]) [4*sin(theta), theta/700*15]]);
//   offset_sweep(sq, height=20, top=sinwave, offset_maxstep=.05, offset="delta");
// Example: a box with a flared top.  A nice roundover on the top requires a profile edge, but we can use "extra" to create a small chamfer.
//   rhex = round_corners(hexagon(side=10), curve="smooth",measure="joint", size=2, $fs=0.2);
//   back_half()
//     difference(){
//       offset_sweep(rhex, height=10, bottom=os_teardrop(r=2), top=os_teardrop(r=-4, extra=0.2));
//       up(1)
//         offset_sweep(offset(rhex,r=1), height=9.5, bottom=os_circle(r=2), top=os_teardrop(r=-4));
//     }
module offset_sweep(
	path, height, h, l, 
	top=[], bottom=[],
	offset="round", r=0, steps=16,
	quality=1, check_valid=true,
	offset_maxstep=1, extra=0,
	cut=undef, chamfer_width=undef, chamfer_height=undef,
	joint=undef, k=0.75, angle=45,
	convexity=10
) {
	// This function does the actual work of repeatedly calling offset() and concatenating the resulting face and vertex lists to produce
	// the inputs for the polyhedron module.  
	function make_polyhedron(path,offsets, offset_type, flip_faces, quality, check_valid, maxstep, offsetind=0, vertexcount=0, vertices=[], faces=[] )=
		offsetind==len(offsets)? (
			let(
				bottom = list_range(n=len(path),s=vertexcount),
				oriented_bottom = !flip_faces? bottom : reverse(bottom)
			) [vertices, concat(faces,[oriented_bottom])]
		) : (
			let(
				this_offset = offsetind==0? offsets[0][0] : offsets[offsetind][0] - offsets[offsetind-1][0],
				delta = offset_type=="delta"? this_offset : undef,
				r = offset_type=="round"? this_offset : undef
			)
			assert(num_defined([r,delta])==1,"Must set `offset` to \"round\" or \"delta")
			let(
				vertices_faces = offset(
					path, r=r, delta=delta, closed=true,
					check_valid=check_valid, quality=quality,
					maxstep=maxstep, return_faces=true,
					firstface_index=vertexcount,
					flip_faces=flip_faces
				)
			)
			make_polyhedron(
				vertices_faces[0], offsets, offset_type,
				flip_faces, quality, check_valid, maxstep,
				offsetind+1, vertexcount+len(path),
				vertices=concat(
					vertices,
					zip(vertices_faces[0],replist(offsets[offsetind][1],len(vertices_faces[0])))
				),
				faces=concat(faces, vertices_faces[1])
			)
		);

	// Produce edge profile curve from the edge specification
	// z_dir is the direction multiplier (1 to build up, -1 to build down)
	function rounding_offsets(edgespec,z_dir=1) =
                let(                  
			edgetype = struct_val(edgespec, "type"),
			extra = struct_val(edgespec,"extra"),
			N = struct_val(edgespec, "steps"),
			r = struct_val(edgespec,"r"),
			cut = struct_val(edgespec,"cut"),
			k = struct_val(edgespec,"k"),
			radius = in_list(edgetype,["circle","teardrop"])?
				first_defined([cut/(sqrt(2)-1),r]) :
				edgetype=="chamfer"? first_defined([sqrt(2)*cut,r]) : undef,
			chamf_angle = struct_val(edgespec, "angle"),
			cheight = struct_val(edgespec, "chamfer_height"),
			cwidth = struct_val(edgespec, "chamfer_width"),
			chamf_width = first_defined([cut/cos(chamf_angle), cwidth, cheight*tan(chamf_angle)]),
			chamf_height = first_defined([cut/sin(chamf_angle),cheight, cwidth/tan(chamf_angle)]),
			joint = first_defined([
				struct_val(edgespec,"joint"),
				16*cut/sqrt(2)/(1+4*k)
			]),
			points = struct_val(edgespec, "points"), 
			argsOK = in_list(edgetype,["circle","teardrop"])? is_def(radius) :
				edgetype == "chamfer"? angle>0 && angle<90 && num_defined([chamf_height,chamf_width])==2 :
				edgetype == "smooth"? num_defined([k,joint])==2 :
				edgetype == "profile"? points[0]==[0,0] :
				false
		)
		assert(argsOK,str("Invalid specification with type ",edgetype))
		let(
			offsets =
				edgetype == "profile"? scale([-1,z_dir], slice(points,1,-1)) :
				edgetype == "chamfer"?  chamf_width==0 && chamf_height==0? [] : [[-chamf_width,z_dir*abs(chamf_height)]] :
				edgetype == "teardrop"? (
					radius==0? [] : concat(
						[for(i=[1:N]) [radius*(cos(i*45/N)-1),z_dir*abs(radius)* sin(i*45/N)]],
						[[-2*radius*(1-sqrt(2)/2), z_dir*abs(radius)]]
					)
				) :
				edgetype == "circle"? radius==0? [] : [for(i=[1:N]) [radius*(cos(i*90/N)-1), z_dir*abs(radius)*sin(i*90/N)]] :
				/* smooth */ joint==0 ? [] :
				select(
					_bezcorner([[0,0],[0,z_dir*abs(joint)],[-joint,z_dir*abs(joint)]], k, $fn=N+2),
					1, -1
				)
		) 
		quant(extra > 0? concat(offsets, [select(offsets,-1)+[0,z_dir*extra]]) : offsets, 1/1024);

	argspec = [
		["r",r],
		["extra",extra],
		["type","circle"],
		["check_valid",check_valid],
		["quality",quality],
		["offset_maxstep", offset_maxstep],
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

	path = check_and_fix_path(path, [2], closed=true);
	clockwise = polygon_is_clockwise(path);

	top = struct_set(argspec, top, grow=false);
	bottom = struct_set(argspec, bottom, grow=false);

	//  This code does not work.  It hits the error in make_polyhedron from offset being wrong
	//  before this code executes.  Had to move the test into make_polyhedron, which is ugly since it's in the loop
	//offsetsok = in_list(struct_val(top, "offset"),["round","delta"]) &&
	//	in_list(struct_val(bottom, "offset"),["round","delta"]);
	//assert(offsetsok,"Offsets must be one of \"round\" or \"delta\"");
        
        
	offsets_bot = rounding_offsets(bottom, -1);
	offsets_top = rounding_offsets(top, 1);

	// "Extra" height enlarges the result beyond the requested height, so subtract it
	bottom_height = len(offsets_bot)==0 ? 0 : abs(select(offsets_bot,-1)[1]) - struct_val(bottom,"extra");
	top_height = len(offsets_top)==0 ? 0 : abs(select(offsets_top,-1)[1]) - struct_val(top,"extra");

        height = get_height(l=l,h=h,height=height,dflt=bottom_height+top_height);
	assert(height>=0, "Height must be nonnegative");
        
	middle = height-bottom_height-top_height;
	assert(
		middle>=0, str(
			"Specified end treatments (bottom height = ",bottom_height,
			" top_height = ",top_height,") are too large for extrusion height (",height,")"
		)
	);
	initial_vertices_bot = path3d(path);

	vertices_faces_bot = make_polyhedron(
		path, offsets_bot, struct_val(bottom,"offset"), clockwise,
		struct_val(bottom,"quality"),
		struct_val(bottom,"check_valid"),
		struct_val(bottom,"offset_maxstep"),
		vertices=initial_vertices_bot
	);

	top_start_ind = len(vertices_faces_bot[0]);
	initial_vertices_top = zip(path, replist(middle,len(path)));
	vertices_faces_top = make_polyhedron(
		path, translate_points(offsets_top,[0,middle]),
		struct_val(top,"offset"), !clockwise,
		struct_val(top,"quality"),
		struct_val(top,"check_valid"),
		struct_val(top,"offset_maxstep"),
		vertexcount=top_start_ind,
		vertices=initial_vertices_top
	);
	middle_faces = middle==0 ? [] : [
		for(i=[0:len(path)-1]) let(
			oneface=[i, (i+1)%len(path), top_start_ind+(i+1)%len(path), top_start_ind+i]
		) !clockwise ? reverse(oneface) : oneface
	];
	up(bottom_height) {
		polyhedron(
			concat(vertices_faces_bot[0],vertices_faces_top[0]),
			faces=concat(vertices_faces_bot[1], vertices_faces_top[1], middle_faces),
			convexity=convexity
		);
	}
}

function os_circle(r,cut,extra,check_valid, quality,steps, offset_maxstep, offset) =
	assert(num_defined([r,cut])==1, "Must define exactly one of `r` and `cut`")
	_remove_undefined_vals([
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

function os_teardrop(r,cut,extra,check_valid, quality,steps, offset_maxstep, offset) =
	assert(num_defined([r,cut])==1, "Must define exactly one of `r` and `cut`")
	_remove_undefined_vals([
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

function os_chamfer(height, width, cut, angle, extra,check_valid, quality,steps, offset_maxstep, offset) =
	let(ok = (is_def(cut) && num_defined([height,width])==0) || num_defined([height,width])>0)
	assert(ok, "Must define `cut`, or one or both of `width` and `height`")
	_remove_undefined_vals([
		"type", "chamfer",
		"chamfer_width",width,
		"chamfer_height",height,
		"cut",cut,
		"angle",angle,
		"extra",extra,
		"check_valid",check_valid,
		"quality", quality,
		"steps", steps,
		"offset_maxstep", offset_maxstep,
		"offset", offset
	]);

function os_smooth(cut, joint, k, extra,check_valid, quality,steps, offset_maxstep, offset) =
	assert(num_defined([joint,cut])==1, "Must define exactly one of `joint` and `cut`")
	_remove_undefined_vals([
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

function os_profile(points, extra,check_valid, quality, offset_maxstep, offset) =
	assert(is_path(points),"Profile point list is not valid")
	_remove_undefined_vals([
		"type", "profile",
		"points", points,
		"extra",extra,
		"check_valid",check_valid,
		"quality", quality,
		"offset_maxstep", offset_maxstep,
		"offset", offset
	]);


function _remove_undefined_vals(list) =
	let(ind=search([undef],list,0)[0]) 
	list_remove(list, concat(ind, add_scalar(ind,-1)));


// Function&Module: offset_stroke()
// Usage:
//   offset_stroke(path, [width], [rounded], [chamfer], [start], [end], [check_valid], [quality], [maxstep], [closed])
// Description:
//   Uses `offset()` to compute a stroke for the input path.  Unlike `stroke`, the result does not need to be
//   centered on the input path.  The corners can be rounded, pointed, or chamfered, and you can make the ends
//   rounded, flat or pointed with the `start` and `end` parameters.
//   
//   The `check_valid`, `quality` and `maxstep` parameters are passed through to `offset()`
//   
//   If `width` is a scalar then the output will be a centered stroke of the specified width.  If width
//   is a list of two values then those two values will define the stroke side positions relative to the center line, where
//   as with offset(), the shift is to the left for open paths and outward for closed paths.  For example,
//   setting `width` to `[0,1]` will create a stroke of width 1 that extends entirely to the left of the input, and and [-4,-6]
//   will create a stroke of width 2 offset 4 units to the right of the input path.
//   
//   If closed==false then the function form will return a path.  If closed==true then it will return a region.  The `start` and
//   `end` parameters are forbidden for closed paths.  
//   
//   Three simple end treatments are supported, "flat" (the default), "round" and "pointed".  The "flat" treatment
//   cuts off the ends perpendicular to the path and the "round" treatment applies a semicircle to the end.  The
//   "pointed" end treatment caps the stroke with a centered triangle that has 45 degree angles on each side.
//   
//   More complex end treatments are available through parameter lists with helper functions to ease parameter passing.  The parameter list 
//   keywords are
//      - "type": the type of end treatment, one of "shifted_point", "roundover", or "flat"
//      - "angle": relative angle (relative to the path)
//      - "abs_angle": absolute angle (angle relative to x-axis)
//      - "cut": cut distance for roundovers, a single value to round both corners identically or a list of two values for the two corners.  Negative values round outward.
//      - "k": curvature smoothness parameter for roundovers, default 0.75
//   
//   Function helpers for defining ends, prefixed by "os" for offset_stroke.
//   
//   os_flat(angle|absangle): specify a flat end either relative to the path or relative to the x-axis
//   os_pointed(loc,dist): specify a pointed tip where the point is distance `loc` from the centerline (positive is the left direction as for offset), and `dist` is the distance from the path end to the point tip.  The default value for `loc` is zero (the center).  You must specify `dist` when using this option.
//   os_round(cut,angle|absangle,k).  Rounded ends with the specified cut distance, based on the specified angle or absolute angle.  The `k` parameter is the smoothness parameter for continuous curvature rounding.
//   
//   Note that `offset_stroke()` will attempt to apply roundovers and angles at the ends even when it means deleting segments of the stroke, unlike round_corners which only works on a segment adjacent to a corner.  If you specify an overly extreme angle it will fail to find an intersection with the stroke and display an error.  When you specify an angle the end segment is rotated around the center of the stroke and the last segment of the stroke one one side is extended to the corner.  
//   
//   The $fn and $fs variables are used to determine the number of segments for rounding, while maxstep is used to determine the segments of `offset`.  If you
//   get the expected rounding along the path, decrease `maxstep` and if the curves created by `os_round()` are too coarse, adjust $fn or $fs.  
//   
// Arguments:
//   path = path that defines the stroke
//   width = width of the stroke, a scalar or a vector of 2 values giving the offset from the path.  Default: 1
//   rounded = set to true to use rounded offsets, false to use sharp (delta) offsets.  Default: true
//   chamfer = set to true to use chamfers when `rounded=false`.  Default: false
//   start = end streatment for the start of the stroke.  See above for details.  Default: "flat"
//   end = end streatment for the end of the stroke.  See above for details.  Default: "flat"
//   check_valid = passed to offset().  Default: true
//   quality = passed to offset().  Default: 1
//   maxstep = passed to offset() to define number of points in the offset.  Default: 0.1
//   closed = true if the curve is closed, false otherwise.  Default: false
//
// Example(2D):  Basic examples illustrating flat, round, and pointed ends, on a finely sampled arc and a path made from 3 segments. 
//   arc = arc(points=[[1,1],[3,4],[6,3]],N=50);
//   path = [[0,0],[6,2],[9,7],[8,10]];  
//   xdistribute(spacing=10){
//     offset_stroke(path, width = 2);
//     offset_stroke(path, start="round", end="round", width = 2);
//     offset_stroke(path, start="pointed", end="pointed", width = 2);
//   }  
//   fwd(10) xdistribute(spacing=10){
//     offset_stroke(arc, width = 2);
//     offset_stroke(arc, start="round", end="round", width = 2);
//     offset_stroke(arc, start="pointed", end="pointed", width = 2);
//   }
// Example(2D):  The effect of the `rounded` and `chamfer` options is most evident at sharp corners.  This only affects the middle of the path, not the ends. 
//   sharppath = [[0,0], [1.5,5], [3,0]];
//   xdistribute(spacing=5){
//     offset_stroke(sharppath);
//     offset_stroke(sharppath, rounded=false);
//     offset_stroke(sharppath, rounded=false, chamfer=true);
//   }
// Example(2D):  When closed is enabled all the corners are affected by those options.  
//   sharppath = [[0,0], [1.5,5], [3,0]];
//   xdistribute(spacing=5){
//     offset_stroke(sharppath,closed=true);
//     offset_stroke(sharppath, rounded=false, closed=true);
//     offset_stroke(sharppath, rounded=false, chamfer=true, closed=true);
//   }
// Example(2D):  The left stroke uses flat ends with a relative angle of zero.  The right hand one uses flat ends with an absolute angle of zero, so the ends are parallel to the x-axis.  
//   path = [[0,0],[6,2],[9,7],[8,10]];  
//   offset_stroke(path, start=os_flat(angle=0), end=os_flat(angle=0));
//   right(5)
//     offset_stroke(path, start=os_flat(abs_angle=0), end=os_flat(abs_angle=0));
// Example(2D):  With continuous sampling the end treatment can remove segments or extend the last segment linearly, as shown here.  Again the left side uses relative angle flat ends and the right hand example uses absolute angle. 
//   arc = arc(points=[[4,0],[3,4],[6,3]],N=50);
//   offset_stroke(arc, start=os_flat(angle=45), end=os_flat(angle=45));
//   right(5)
//     offset_stroke(arc, start=os_flat(abs_angle=45), end=os_flat(abs_angle=45));
// Example(2D):  The os_pointed() end treatment allows adjustment of the point tip, as shown here.  The width is 2 so a location of 1 is at the edge.  
//   arc = arc(points=[[1,1],[3,4],[6,3]],N=50);
//   offset_stroke(arc, width=2, start=os_pointed(loc=1,dist=3),end=os_pointed(loc=1,dist=3));
//   right(10)
//     offset_stroke(arc, width=2, start=os_pointed(dist=4),end=os_pointed(dist=-1));
//   fwd(7)  
//     offset_stroke(arc, width=2, start=os_pointed(loc=2,dist=2),end=os_pointed(loc=.5,dist=-1));
// Example(2D):  The os_round() end treatment adds roundovers to the end corners by specifying the `cut` parameter.  In the first example, the cut parameter is the same at each corner.  The bezier smoothness parameter `k` is given to allow a larger cut.  In the second example, each corner is given a different roundover, including zero for no rounding at all.  The red shows the same strokes without the roundover.  
//   arc = arc(points=[[1,1],[3,4],[6,3]],N=50);
//   path = [[0,0],[6,2],[9,7],[8,10]];  
//   offset_stroke(path, width=2, rounded=false,start=os_round(angle=-20, cut=0.4,k=.9), end=os_round(angle=-35, cut=0.4,k=.9));
//   color("red")down(.1)offset_stroke(path, width=2, rounded=false,start=os_flat(-20), end=os_flat(-35));
//   right(9){
//     offset_stroke(arc, width=2, rounded=false, start=os_round(cut=[.3,.6],angle=-45), end=os_round(angle=20,cut=[.6,0]));
//     color("red")down(.1)offset_stroke(arc, width=2, rounded=false, start=os_flat(-45), end=os_flat(20));
//   }
// Example(2D):  Negative cut values produce a flaring end.  Note how the absolute angle aligns the ends of the first example withi the axes.  In the second example positive and negative cut values are combined.  Note also that very different cuts are needed at the start end to produce a similar looking flare.  
//   arc = arc(points=[[1,1],[3,4],[6,3]],N=50);
//   path = [[0,0],[6,2],[9,7],[8,10]];  
//   offset_stroke(path, width=2, rounded=false,start=os_round(cut=-1, abs_angle=90), end=os_round(cut=-0.5, abs_angle=0));
//   right(10)
//      offset_stroke(arc, width=2, rounded=false, start=os_round(cut=[-.75,-.2], angle=-45), end=os_round(cut=[-.2,.2], angle=20));
// Example(2D):  Setting the width to a vector allows generation of a set of parallel strokes
//   path = [[0,0],[4,4],[8,4],[2,9],[10,10]];   
//   for(i=[0:.25:2])
//     offset_stroke(path, rounded=false,width = [i,i+.08]);
// Example(2D):  Setting rounded=true in the above example makes a very big difference in the result.  
//   path = [[0,0],[4,4],[8,4],[2,9],[10,10]];   
//   for(i=[0:.25:2])
//     offset_stroke(path, rounded=true,width = [i,i+.08]);
// Example(2D):  In this example a spurious triangle appears.  This results from overly enthusiastic validity checking.  Turning validity checking off fixes it in this case.  
//   path = [[0,0],[4,4],[8,4],[2,9],[10,10]];   
//   offset_stroke(path, check_valid=true,rounded=false,width = [1.4, 1.45]);
//   right(2)
//     offset_stroke(path, check_valid=false,rounded=false,width = [1.4, 1.45]);
// Example(2D):  But in this case, disabling the validity check produces an invalid result.  
//   path = [[0,0],[4,4],[8,4],[2,9],[10,10]];   
//   offset_stroke(path, check_valid=true,rounded=false,width = [1.9, 2]);
//   translate([1,-0.25])
//     offset_stroke(path, check_valid=false,rounded=false,width = [1.9, 2]);
// Example(2D): Self-intersecting paths are handled differently than with the `stroke()` module.
//   path = turtle(["move",10,"left",144], repeat=4);
//   stroke(path, closed=true);
//   right(12)
//     offset_stroke(path, width=1, closed=true);
function offset_stroke(path, width=1, rounded=true, start="flat", end="flat", check_valid=true, quality=1, maxstep=0.1, chamfer=false, closed=false) =
	let(closedok = !closed || (is_undef(start) && is_undef(end)))
	assert(closedok, "Parameters `start` and `end` not allowed with closed path")
	let(
		start = closed? [] : _parse_stroke_end(default(start,"flat")),
		end = closed? [] : _parse_stroke_end(default(end,"flat")),
		width = is_list(width)? reverse(sort(width)) : [1,-1]*width/2,  
		left_r = !rounded? undef : width[0], 
		left_delta = rounded? undef : width[0], 
		right_r = !rounded? undef : width[1], 
		right_delta = rounded? undef : width[1],
		left_path = offset(
			path, delta=left_delta, r=left_r, closed=closed,
			check_valid=check_valid, quality=quality,
			chamfer=chamfer, maxstep=maxstep
		),
		right_path = offset(
			path, delta=right_delta, r=right_r, closed=closed,
			check_valid=check_valid, quality=quality,
			chamfer=chamfer, maxstep=maxstep
		)
	)
	closed? [left_path, right_path] :
	let(
		startpath = _stroke_end(width,left_path, right_path, start),
		endpath = _stroke_end(reverse(width),reverse(right_path), reverse(left_path),end),
		clipping_ok = startpath[1]+endpath[2]<=len(left_path) && startpath[2]+endpath[1]<=len(right_path)
	)
	assert(clipping_ok, "End treatment removed the whole stroke")
	concat(
		slice(left_path,startpath[1],-1-endpath[2]),
		endpath[0],
		reverse(slice(right_path,startpath[2],-1-endpath[1])),
		startpath[0]
	);


function os_pointed(loc=0,dist) =
	assert(is_def(dist), "Must specify `dist`")
	[
		"type", "shifted_point",
		"loc",loc,
		"dist",dist
	];

function os_round(cut, angle, abs_angle, k) =
	let(
		acount = num_defined([angle,abs_angle]),
		use_angle = first_defined([angle,abs_angle,0])
	)
	assert(acount<2, "You must define only one of `angle` and `abs_angle`")
	assert(is_def(cut), "Parameter `cut` not defined.")
	[
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


function _parse_stroke_end(spec) =
	is_string(spec)?
		assert(
			in_list(spec,["flat","round","pointed"]),
			str("Unknown end string specification \"", spec,"\".  Must be \"flat\", \"round\", or \"pointed\"")
		)
		[["type", spec]] :
		struct_set([], spec);


function _stroke_end(width,left, right, spec) =
	let(
		type = struct_val(spec, "type"),
		user_angle = default(struct_val(spec, "angle"), 0),
		normal_seg = _normal_segment(right[0], left[0]),
		normal_pt = normal_seg[1],
		center = normal_seg[0],
		parallel_dir = normalize(left[0]-right[0]),
		normal_dir = normalize(normal_seg[1]-normal_seg[0]),
		width_dir = sign(width[0]-width[1])
	)
	type == "round"? [arc(points=[right[0],normal_pt,left[0]],N=50),1,1]  :
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
		endseg = [center, rotate_points2d([left[0]],angle, cp=center)[0]],
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
				concat([pathclip[0]],select(right,pathclip[1],-1)) :
				concat([pathextend],select(right,1,-1)),
			newleft = !intright?
				concat([pathclip[0]],select(left,pathclip[1],-1)) :
				concat([pathextend],select(left,1,-1)),
			// calculate corner angles, which are different when the cut is negative (outside corner)
			leftangle = cutleft>=0?
				vector_angle([newleft[1],newleft[0],newright[0]])/2 :
				90-vector_angle([newleft[1],newleft[0],newright[0]])/2,
			rightangle = cutright>=0?
				vector_angle([newright[1],newright[0],newleft[0]])/2 :
				90-vector_angle([newright[1],newright[0],newleft[0]])/2,
			jointleft = 8*cutleft/cos(leftangle)/(1+4*bez_k),
			jointright = 8*cutright/cos(rightangle)/(1+4*bez_k),
			pathcutleft = path_cut(newleft,abs(jointleft)),  
			pathcutright = path_cut(newright,abs(jointright)),
			leftdelete = intright? pathcutleft[1] : pathcutleft[1] + pathclip[1] -1,
			rightdelete = intright? pathcutright[1] + pathclip[1] -1 : pathcutright[1],
			leftcorner = line_intersection([pathcutleft[0], newleft[pathcutleft[1]]], [newright[0],newleft[0]]),
			rightcorner = line_intersection([pathcutright[0], newright[pathcutright[1]]], [newright[0],newleft[0]]),
			roundover_fits = jointleft+jointright < norm(rightcorner-leftcorner)
		)
		assert(roundover_fits,"Roundover too large to fit")
		let(
			angled_dir = normalize(newleft[0]-newright[0]),
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
	let(intersect=line_segment_intersection(line, select(path,ind,ind+1)))
	// If it intersects the segment excluding it's final point, then we're done
	// The final point is treated as part of the next segment
	is_def(intersect) && intersect != path[ind+1]?
		[intersect, ind+1] :
		_path_line_intersection(path, line, ind+1);

module offset_stroke(path, width=1, rounded=true, start, end, check_valid=true, quality=1, maxstep=0.1, chamfer=false, closed=false) 
{
        no_children($children);
	result = offset_stroke(
		path, width=width, rounded=rounded,
		start=start, end=end,
		check_valid=check_valid, quality=quality,
		maxstep=maxstep, chamfer=chamfer,
		closed=closed
	);
	if (closed) {
		region(result);
	} else {
		polygon(result);
	}
}



// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap


