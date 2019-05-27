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


// CommonCode:
//   $fn=200;


// Section: Functions


// Function: round_corners()
//
// Description:
//   Takes a 2d or 3d point list as input (a path or the points of a polygon) and rounds each corner
//   by a specified amount.  The rounding at each point can be different and some points can have zero
//   rounding.  The `round_corners()` function supports two types of rounding, circular rounding and
//   continuous curvature rounding using 4th order bezier curves.  Circular rounding can produce a
//   tactile "bump" where the curvature changes from flat to circular.
//   See https://hackernoon.com/apples-icons-have-that-shape-for-a-very-good-reason-720d4e7c8a14
//   
//   You select the type of rounding using the `curve` option, which should be either `"smooth"` to get
//   continuous curvature rounding or `"circle"` to get circular rounding.  Each rounding method has two
//   options for how you specify the amount of rounding, which you select using the `type` argument.
//   Both rounding methods accept `type="cut"`.  This mode specifies the amount of rounding as the
//   distance from the corner to the curve.  This can be easier to understand than setting a circular
//   radius, which can be unexpectedly extreme when the corner is very sharp.  It also allows a
//   systematic specification of curves that is the same for both `"circle"` and `"smooth"`.
//   
//   The second `type` setting for circular rounding is `"radius"`, which sets a circular rounding
//   radius.  The second `type` setting for smooth rounding is `"joint"` which specifies the distance
//   away from the corner where the roundover should start.  The `"smooth"` type rounding also has a
//   parameter that specifies how smooth the curvature match is.  This parameter ranges from 0 to 1,
//   with a default of 0.5.  Larger values give a more abrupt transition and smaller ones a more
//   gradual transition.  If you set the value much higher than 0.8 the curvature changes abruptly
//   enough that though it is theoretically continuous, it may not be continous in practice.  If you
//   set it very small then the transition is so gradual that the length of the roundover may be
//   extremely long.
//   
//   If you select curves that are too large to fit the function will fail with an error.  It displays
//   a set of scale factors that you can apply to the (first) smoothing parameter that will reduce the
//   size of the curves so that they will fit on your path.  If the scale factors are larger than one
//   then they indicate how much you can increase the curve sizes before collisions will occur.
//   
//   To specify rounding parameters you can use the `all` option to round every point in a path.
//   Examples:
//   * `curve="circle", type="radius", all=2`: Rounds every point with circular, radius 2 roundover
//   * `curve="smooth", type="cut", all=2`: Rounds every point with continuous curvature rounding with a cut of 2, and a default 0.5 smoothing parameter
//   * `curve="smooth", type="cut", all=[2,.3]`: Rounds every point with continuous curvature rounding with a cut of 2, and a very gentle 0.3 smooth setting
//   
//   The path is a list of 2d or 3d points, possibly with an extra coordinate giving smoothing
//   parameters.  It is important to specify if the path is a closed path or not using the `closed`
//   parameter.  The default is a closed path for making polygons.
//   Path examples:
//   * `[[0,0],[0,1],[1,1],[0,1]]`: 2d point list (a square), `all` was given to set rounding
//   * `[[0,0,0], [0,1,1], [1,1,2], [0,1,3]]`: 3d point list, `all` was given to set rounding
//   * `[[0,0,0.2],[0,1,0.1],[1,1,0],[0,1,0.3]]`: 2d point list with smoothing parameters different at every corner, `all` not given
//   * `[[0,0,0,.2], [0,1,1,.1], [1,1,2,0], [0,1,3,.3]]`: 3d point list with smoothing parameters, `all` not given
//   * `[[0,0,[.3,.7], [4,0,[.2,.6]], [4,4,0], [0,4,1]]`: 3d point list with smoothing parameters for the `"smooth"` type roundover, `all` not given.  Note the third entry is sometimes a pair giving both smoothing parameters, sometimes it's zero specifying no smoothing, and sometimes a single number, specifying the amount of smoothing but using the default smoothness parameter.
//   
//   The number of segments used for roundovers is determined by `$fa`, `$fs` and `$fn` as usual for
//   circular roundovers.  For continuous curvature roundovers `$fs` and `$fn` are used and `$fa` is ignored.
//   When doing continuous curvature rounding be sure to use lots of segments or the effect will be
//   hidden by the discretization.
//
// Arguments:
//   path = list of points defining the path to be rounded.  Can be 2d or 3d, and may have an extra coordinate giving rounding parameters.  If you specify rounding parameters you must do so on every point.  
//   curve = rounding method to use.  Set to "circle" for circular rounding and "smooth" for continuous curvature 4th order bezier rounding
//   type = rounding parameter type.  Set to "cut" to specify the cut back with either "smooth" or "circle" rounding methods.  Set to "radius" with `curve="circle"` to set circular radius rounding.  Set to "joint" with `curve="smooth"` for joint type rounding.  (See above for details on these rounding options.)
//   all = curvature parameter(s).  Set this to the curvature parameter or parameters to apply to all points on the list.  If you set this then all values given in the path are treated as geometrical coordinates.  If you don't set this then the last value of each entry in `path` is treated as a smoothing parameter.
//   closed = if true treat the path as a closed polygon, otherwise treat it as open.  Default: true.
//
// Example(Med2D): Standard circular roundover with radius the same at every point. Compare results at the different corners.  
//   shape = [[0,0], [10,0], [15,12], [6,6], [6, 12], [-3,7]];
//   polygon(round_corners(shape, curve="circle", type="radius", all=1));
//   color("red") down(.1) polygon(shape);
// Example(Med2D): Circular roundover using the "cut" specification, the same at every corner.  
//   shape = [[0,0], [10,0], [15,12], [6,6], [6, 12], [-3,7]];
//   polygon(round_corners(shape, curve="circle", type="cut", all=1));
//   color("red") down(.1) polygon(shape);
// Example(Med2D): Continous curvature roundover using "cut", still the same at every corner.  The default smoothness parameter of 0.5 was too gradual for these roundovers to fit, but 0.7 works.  
//   shape = [[0,0], [10,0], [15,12], [6,6], [6, 12], [-3,7]];
//   polygon(round_corners(shape, curve="smooth", type="cut", all=[1,.7]));
//   color("red") down(.1) polygon(shape);
// Example(Med2D): Continuous curvature roundover using "joint", for the last time the same at every corner.  Notice how small the roundovers are.  
//   shape = [[0,0], [10,0], [15,12], [6,6], [6, 12], [-3,7]];
//   polygon(round_corners(shape, curve="smooth", type="joint", all=[1,.7]));
//   color("red") down(.1) polygon(shape);
// Example(Med2D): Circular rounding, different at every corner, some corners left unrounded
//   shape = [[0,0,1.8], [10,0,0], [15,12,2], [6,6,.3], [6, 12,1.2], [-3,7,0]];
//   polygon(round_corners(shape, curve="circle", type="radius"));
//   color("red") down(.1) polygon(subindex(shape,[0:1]));
// Example(Med2D): Continuous curvature rounding, different at every corner, with varying smoothness parameters as well, and `$fs` set very small
//   shape = [[0,0,[1.5,.6]], [10,0,0], [15,12,2], [6,6,[.3,.7]], [6, 12,[1.2,.3]], [-3,7,0]];
//   polygon(round_corners(shape, curve="smooth", type="cut", $fs=0.1));
//   color("red") down(.1) polygon(subindex(shape,[0:1]));
// Example(Med3D): 3d printing test pieces to display different curvature shapes.  You can see the discontinuity in the curvature on the "C" piece in the rendered image.  
//   ten = [[0,0,5],[50,0,5],[50,50,5],[0,50,5]];
//   linear_extrude(height=14){
//   translate([25,25,0])text("C",size=30, valign="center", halign="center");
//     translate([85,25,0])text("5",size=30, valign="center", halign="center");
//     translate([85,85,0])text("3",size=30, valign="center", halign="center");
//     translate([25,85,0])text("7",size=30, valign="center", halign="center");
//   }
//   linear_extrude(height=13)
//   {
//     polygon(round_corners(ten, curve="circle", type="cut"));
//     translate([60,0,0])polygon(round_corners(ten,  curve="smooth", type="cut"));
//     translate([60,60,0])polygon(round_corners([[0,0],[50,0],[50,50],[0,50]],all=[5,.32],$fs=5,$fa=0,
//                                             curve="smooth", type="cut"));
//     translate([0,60,0])polygon(round_corners([[0,0],[50,0],[50,50],[0,50]],all=[5,.7],
//                                             curve="smooth", type="cut"));
//   }   

function round_corners(path, curve, type, all=undef,  closed=true) =
	let(
		default_curvature = 0.5,   // default curvature for "smooth" curves
		typeok = (
			type == "cut" ||
			(curve=="circle" && type=="radius") ||
			(curve=="smooth" && type=="joint")
		),
		pathdim = array_dim(path,1),
		have_all = all==undef ? 1 : 0,
		pathsize_ok = is_num(pathdim) && pathdim >= 2+have_all && pathdim <= 3+have_all
	)
	assert(curve=="smooth" || curve=="circle", "Unknown 'curve' setting in round_corners")
	assert(typeok, curve=="circle"?
		"In round_corners curve==\"circle\" requires 'type' of 'radius' or 'cut'" :
		"In round_corners curve==\"smooth\" requires 'type' of 'joint' or 'cut'"
	)
	assert(pathdim!=undef, "Input 'path' has entries with inconsistent length")
	assert(pathsize_ok, str(
		"Input 'path' must have entries with length ",
		2+have_all, " or ", 3+have_all,
		all==undef ? " when 'all' is not specified" : "when 'all' is specified"
	))
	let(
		pathfixed= all == undef ? path : zip([path, replist([all],len(path))]),
		dim = len(pathfixed[0])-1,
		points = subindex(pathfixed, [0:dim-1]),
		parm = subindex(pathfixed, dim),
		// dk will be a list of parameters, for the "smooth" type the distance and curvature parameter pair,
		// and for the circle type, distance and radius.  
		dk = [
			for(i=[0:1:len(points)-1]) let(  
				angle = pathangle(select(points,i-1,i+1))/2,
				parm0 = is_list(parm[i]) ? parm[i][0] : parm[i],
				k = (curve=="circle" && type=="radius")? parm0 :
					(curve=="circle" && type=="cut")? parm0 / (1/sin(angle) - 1) : 
					(is_list(parm[i]) && len(parm[i])==2)? parm[i][1] :
					default_curvature
			)
			(!closed && (i==0 || i==len(points)-1))? [0,0] :
			(curve=="circle")? [k/tan(angle), k] :
			(curve=="smooth" && type=="joint")? [parm0,k] :
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
			(curve=="smooth")? bezcorner(select(points,i-1,i+1), dk[i]) :
			circlecorner(select(points,i-1,i+1), dk[i])
	];


function bezcorner(points, parm) =
	let(
		d = parm[0],
		k = parm[1],
		prev = normalize(points[0]-points[1]),
		next = normalize(points[2]-points[1]),
		P = [
			points[1]+d*prev,
			points[1]+k*d*prev,
			points[1],
			points[1]+k*d*next,
			points[1]+d*next
		],
		N = $fn>0 ? max(3,$fn) : ceil(bezier_segment_length(P)/$fs)
	)
	bezier_curve(P,N);


function circlecorner(points, parm) =
	let(
		angle = pathangle(points)/2,
		d = parm[0],
		r = parm[1],
		prev = normalize(points[0]-points[1]),
		next = normalize(points[2]-points[1]),
		center = r/sin(angle) * normalize(prev+next)+points[1]
	)
	circular_arc(center, points[1]+prev*d, points[1]+next*d, 300);


// Compute points for the shortest circular arc that is centered at
// the specified center, starts at p1, and ends on the vector
// p2-center.  The radius is the length of (p1-center).  If (p2-center)
// has the same length then the arc will end at p2.

function circular_arc(center, p1, p2, N) =
	let(
		angle = pathangle([p1,center,p2]),
		v1 = p1-center,
		v2 = p2-center,
		N = ceil(angle/360) * segs(norm(v1))
	)
	len(center)==2? (
		let(
			dir = sign(v1.x*v2.y-v1.y*v2.x),   // z component of cross product
			r=norm(v1)
		)
		assert(dir != 0, "Colinear inputs don't define a unique arc")
		[
			for(i=[0:1:N-1]) let(
				theta=atan2(v1.y,v1.x)+i*dir*angle/(N-1)
			) r*[cos(theta),sin(theta)]+center
		]
	) : (
		let(axis = cross(v1,v2))
		assert(axis != [0,0,0], "Colinear inputs don't define a unique arc")
		[
			for(i=[0:1:N-1])
				matrix3_rot_by_axis(axis, i*angle/(N-1)) * v1 + center
		]
	);


function bezier_curve(P,N) =
   [for(i=[0:1:N-1]) bez_point(P, i/(N-1))];


function pathangle(pts) = vector_angle(pts[0]-pts[1], pts[2]-pts[1]);


// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
