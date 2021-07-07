/////////////////////////////////////////////////////////////////////
// LibFile: rounding.scad
//   Routines to create rounded corners, with either circular rounding,
//   or continuous curvature rounding with no sudden curvature transitions.
// Includes:
//   include <BOSL2/std.scad>
//   include <BOSL2/rounding.scad>
//////////////////////////////////////////////////////////////////////
include <beziers.scad>
include <structs.scad>


// Section: Functions

// Function: round_corners()
//
// Usage:
//   rounded_path = round_corners(path, [method], [radius=], [cut=], [joint=], [closed=], [verbose=]);
//
// Description:
//   Takes a 2D or 3D path as input and rounds each corner
//   by a specified amount.  The rounding at each point can be different and some points can have zero
//   rounding.  The `round_corners()` function supports three types of corner treatment: chamfers, circular rounding,
//   and continuous curvature rounding using 4th order bezier curves.  Circular rounding can produce a
//   tactile "bump" where the curvature changes from flat to circular.
//   See https://hackernoon.com/apples-icons-have-that-shape-for-a-very-good-reason-720d4e7c8a14
//   .
//   You select the type of rounding using the `method` parameter, which should be `"smooth"` to
//   get continuous curvature rounding, `"circle"` to get circular rounding, or `"chamfer"` to get chamfers.  The default is circle
//   rounding.  Each method accepts multiple options to specify the amount of rounding.
//   .
//   The `cut` parameter specifies the distance from the unrounded corner to the rounded tip, so how
//   much of the corner to "cut" off.  This can be easier to understand than setting a circular radius, which can be
//   unexpectedly extreme when the corner is very sharp.  It also allows a systematic specification of
//   corner treatments that are the same size for all three methods.
//   .
//   The `joint` parameter specifies the distance
//   away from the corner along the path where the roundover or chamfer should start.  The figure below shows
//   the cut and joint distances for a given roundover.  This parameter is good for ensuring that your roundover will
//   fit on the polygon, since you can easily tell whether adjacent corner treatments will interfere.  
//   .
//   For circular rounding you can also use the `radius` parameter, which sets a circular rounding
//   radius.
//   .
//   The `"smooth"` method rounding also has a parameter that specifies how smooth the curvature match
//   is.  This parameter, `k`, ranges from 0 to 1, with a default of 0.5.  Larger values give a more
//   abrupt transition and smaller ones a more gradual transition.  If you set the value much higher
//   than 0.8 the curvature changes abruptly enough that though it is theoretically continuous, it may
//   not be continuous in practice.  If you set it very small then the transition is so gradual that
//   the length of the roundover may be extremely long. 
//   .
//   If you select curves that are too large to fit the function will fail with an error.  You can set `verbose=true` to
//   get a message showing a list of scale factors you can apply to your rounding parameters so that the
//   roundovers will fit on the curve.  If the scale factors are larger than one
//   then they indicate how much you can increase the curve sizes before collisions will occur.
//   .
//   The parameters `radius`, `cut`, `joint` and `k` can be numbers, which round every corner using the same parameters, or you
//   can specify a list to round each corner with different parameters.  If the curve is not closed then the first and last points
//   of the curve are not rounded.  In this case you can specify a full list of points anyway, and the endpoint values are ignored,
//   or you can specify a list that has length len(path)-2, omitting the two dummy values.
//   .
//   If your input path includes collinear points you must use a cut or radius value of zero for those "corners".  You can
//   choose a nonzero joint parameter when the collinear points form a 180 degree angle.  This will cause extra points to be inserted. 
//   If the collinear points form a spike (0 degree angle) then round_corners will fail. 
//   .
//   Examples:
//   * `method="circle", radius=2`:
//       Rounds every point with circular, radius 2 roundover
//   * `method="smooth", cut=2`:
//       Rounds every point with continuous curvature rounding with a cut of 2, and a default 0.5 smoothing parameter
//   * `method="smooth", cut=2, k=0.3`:
//       Rounds every point with continuous curvature rounding with a cut of 2, and a very gentle 0.3 smoothness setting
//   .
//   The number of segments used for roundovers is determined by `$fa`, `$fs` and `$fn` as usual for
//   circular roundovers.  For continuous curvature roundovers `$fs` and `$fn` are used and `$fa` is
//   ignored.  Note that $fn is interpreted as the number of points on the roundover curve, which is
//   not equivalent to its meaning for rounding circles because roundovers are usually small fractions
//   of a circular arc.  As usual, $fn overrides $fs.  When doing continuous curvature rounding be sure to use lots of segments or the effect
//   will be hidden by the discretization.  Note that if you use $fn with "smooth" then $fn points are added at each corner, even
//   if the "corner" is flat, with collinear points, so this guarantees a specific output length.  
//
// Figure(2D,Med):
//   h = 18;
//   w = 12.6;
//   example = [[0,0],[w,h],[2*w,0]];
//   color("red")stroke(round_corners(example, joint=18, method="smooth",closed=false),width=.1);
//   stroke(example, width=.1);
//   color("green")stroke([[w,h], [w,h-cos(vector_angle(example)/2) *3/8*h]], width=.1);
//   ll=lerp([w,h], [0,0],18/norm([w,h]-[0,0]) );
//   color("blue")stroke(_shift_segment([[w,h], ll], -.7), width=.1);
//   color("green")translate([w-.3,h-4])scale(.1)rotate(90)text("cut");
//   color("blue")translate([w/2-1.1,h/2+.6])  scale(.1)rotate(90-vector_angle(example)/2)text("joint");
//
// Arguments:
//   path = list of 2d or 3d points defining the path to be rounded.
//   method = rounding method to use.  Set to "chamfer" for chamfers, "circle" for circular rounding and "smooth" for continuous curvature 4th order bezier rounding.  Default: "circle"
//   ---
//   radius = rounding radius, only compatible with `method="circle"`. Can be a number or vector.
//   cut = rounding cut distance, compatible with all methods.  Can be a number or vector.
//   joint = rounding joint distance, compatible with `method="chamfer"` and `method="smooth"`.  Can be a number or vector.
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
// Example(2D,Med): Continuous curvature rounding, different at every corner, with varying smoothness parameters as well, and `$fs` set very small.  Note that `$fa` is ignored here with method set to "smooth".
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
//   spiral = flatten(repeat(concat(square,reverse(square)),5));  // Squares repeat 10 times, forward and backward
//   squareind = [for(i=[0:9]) each [i,i,i,i]];                   // Index of the square for each point
//   z = count(40)*.2+squareind;
//   path3d = hstack(spiral,z);                                   // 3D spiral
//   rounding = squareind/20;
//       // Setting k=1 means curvature won't be continuous, but curves are as round as possible
//       // Try changing the value to see the effect.
//   rpath = round_corners(path3d, joint=rounding, k=1, method="smooth", closed=false);
//   path_sweep( regular_ngon(n=36, or=.1), rpath);
// Example(2D): The rounding invocation that is commented out gives an error because the rounding parameters interfere with each other.  The error message gives a list of factors that can help you fix this: [0.852094, 0.852094, 1.85457, 10.1529]
//   $fn=64;
//   path = [[0, 0],[10, 0],[20, 20],[30, -10]];
//   debug_polygon(path);
//   //polygon(round_corners(path,cut = [1,3,1,1], method="circle"));
// Example(2D): The list of factors shows that the problem is in the first two rounding values, because the factors are smaller than one.  If we multiply the first two parameters by 0.85 then the roundings fit.  The verbose option gives us the same fit factors.  
//   $fn=64;
//   path = [[0, 0],[10, 0],[20, 20],[30, -10]];
//   polygon(round_corners(path,cut = [0.85,3*0.85,1,1], method="circle", verbose=true));
// Example(2D): From the fit factors we can see that rounding at vertices 2 and 3 could be increased a lot.  Applying those factors we get this more rounded shape.  The new fit factors show that we can still further increase the rounding parameters if we wish.  
//   $fn=64;
//   path = [[0, 0],[10, 0],[20, 20],[30, -10]];
//   polygon(round_corners(path,cut = [0.85,3*0.85,2.13, 10.15], method="circle",verbose=true));
// Example(2D): Using the `joint` parameter it's easier to understand whether your roundvers will fit.  We can guarantee a fairly large roundover on any path by picking each one to use up half the segment distance along the shorter of its two segments:
//   $fn=64;
//   path = [[0, 0],[10, 0],[20, 20],[30, -10]];
//   path_len = path_segment_lengths(path,closed=true);
//   halflen = [for(i=idx(path)) min(select(path_len,i-1,i))/2];
//   polygon(round_corners(path,joint = halflen, method="circle",verbose=true));

module round_corners(path, method="circle", radius, cut, joint, k, closed=true, verbose=false) {no_module();}
function round_corners(path, method="circle", radius, cut, joint, k, closed=true, verbose=false) =
    assert(in_list(method,["circle", "smooth", "chamfer"]), "method must be one of \"circle\", \"smooth\" or \"chamfer\"")
    let(
        default_k = 0.5,
        size=one_defined([radius, cut, joint], "radius,cut,joint"),
        path = is_region(path)?
                   assert(len(path)==1, "Region supplied as path does not have exactly one component")
                   path[0] : path,
        size_ok = is_num(size) || len(size)==len(path) || (!closed && len(size)==len(path)-2),
        k_ok = is_undef(k) || (method=="smooth" && (is_num(k) || len(k)==len(path) || (!closed && len(k)==len(path)-2))),
        measure = is_def(radius) ? "radius" :
                    is_def(cut) ? "cut" : "joint"
    )
    assert(is_path(path,[2,3]), "input path must be a 2d or 3d path")
    assert(len(path)>2,str("Path has length ",len(path),".  Length must be 3 or more."))
    assert(size_ok,str("Input ",measure," must be a number or list with length ",len(path), closed?"":str(" or ",len(path)-2)))
    assert(k_ok,method=="smooth" ? str("Input k must be a number or list with length ",len(path), closed?"":str(" or ",len(path)-2)) :
                                   "Input k is only allowed with method=\"smooth\"")
    assert(method=="circle" || measure!="radius", "radius parameter allowed only with method=\"circle\"")
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
    [
        for(i=[0:1:len(path)-1]) each
            (dk[i][0] == 0)? [path[i]] :
            (method=="smooth")? _bezcorner(select(path,i-1,i+1), dk[i]) :
            (method=="chamfer") ? _chamfcorner(select(path,i-1,i+1), dk[i]) :
            _circlecorner(select(path,i-1,i+1), dk[i])
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
                                prev = unit(points[0]-points[1]),
                                next = unit(points[2]-points[1])
                        ) [
                                points[1]+d*prev,
                                points[1]+k*d*prev,
                                points[1],
                                points[1]+k*d*next,
                                points[1]+d*next
                        ] : _smooth_bez_fill(points,parm),
                N = max(3,$fn>0 ?$fn : ceil(bezier_segment_length(P)/$fs))
        )
        bezier_curve(P,N+1,endpoint=true);

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
                        edgetype == "circle"? radius==0? [] : [for(i=[1:N]) [radius*(cos(i*90/N)-1), z_dir*abs(radius)*sin(i*90/N)]] :
                        /* smooth */ joint==0 ? [] :
                        list_tail(
                                _bezcorner([[0,0],[0,z_dir*abs(joint)],[-joint,z_dir*abs(joint)]], k, $fn=N+2)
                        )
        )
  
        quant(extra > 0? concat(offsets, [last(offsets)+[0,z_dir*extra]]) : offsets, 1/1024);



// Function: smooth_path()
// Usage:
//   smoothed = smooth_path(path, [tangents], <size=|relsize=>, [splinesteps=], [closed=], [uniform=]);
// Description:
//   Smooths the input path using a cubic spline.  Every segment of the path will be replaced by a cubic curve
//   with `splinesteps` points.  The cubic interpolation will pass through every input point on the path
//   and will match the tangents at every point.  If you do not specify tangents they will be computed using
//   path_tangents with uniform=false by default.  Note that setting uniform to true with non-uniform
//   sampling may be desirable in some cases but tends to produces curves that overshoot the point on the path.  
//   .
//   The size or relsize parameter determines how far the curve can bend away from
//   the input path.  In the case where the curve has a single hump, the size specifies the exact distance
//   between the specified path and the curve.  If you give relsize then it is relative to the segment
//   length (e.g. 0.05 means 5% of the segment length).  In 2d when the spline may make an S-curve,
//   in which case the size parameter specifies the sum of the deviations of the two peaks of the curve.  In 3-space
//   the bezier curve may have three extrema: two maxima and one minimum.  In this case the size specifies
//   the sum of the maxima minus the minimum.  At a given segment there is a maximum size: if your size
//   value is too large it will be rounded down.  See also path_to_bezier().
// Arguments:
//   path = path to smooth
//   tangents = tangents constraining curve direction at each point.  Default: computed automatically
//   ---
//   relsize = relative size specification for the curve, a number or vector.  Default: 0.1
//   size = absolute size specification for the curve, a number or vector
//   uniform = set to true to compute tangents with uniform=true.  Default: false
//   closed = true if the curve is closed.  Default: false. 
// Example(2D): Original path in green, smoothed path in yellow:
//   color("green")stroke(square(4), width=0.1);
//   stroke(smooth_path(square(4),size=0.4), width=0.1);
// Example(2D): Closing the path changes the end tangents
//   polygon(smooth_path(square(4),size=0.4,closed=true));
// Example(2D): Turning on uniform tangent calculation also changes the end derivatives:
//   color("green")stroke(square(4), width=0.1);
//   stroke(smooth_path(square(4),size=0.4,uniform=true), width=0.1);
// Example(2D): Here's a wide rectangle.  Using size means all edges bulge the same amount, regardless of their length. 
//   color("green")stroke(square([10,4]), closed=true, width=0.1);
//   stroke(smooth_path(square([10,4]),size=1,closed=true),width=0.1);
// Example(2D): Here's a wide rectangle.  With relsize the bulge is proportional to the side length. 
//   color("green")stroke(square([10,4]), closed=true, width=0.1);
//   stroke(smooth_path(square([10,4]),relsize=0.1,closed=true),width=0.1);
// Example(2D): Here's a wide rectangle.  Settting uniform to true biases the tangents to aline more with the line sides
//   color("green")stroke(square([10,4]), closed=true, width=0.1);
//   stroke(smooth_path(square([10,4]),uniform=true,relsize=0.1,closed=true),width=0.1);
// Example(2D): A more interesting shape:
//   path = [[0,0], [4,0], [7,14], [-3,12]];
//   polygon(smooth_path(path,size=1,closed=true));
// Example(2D): Here's the square again with less smoothing.
//   polygon(smooth_path(square(4), size=.25,closed=true));
// Example(2D): Here's the square with a size that's too big to achieve, so you get the maximum possible curve:
//   color("green")stroke(square(4), width=0.1,closed=true);
//   stroke(smooth_path(square(4), size=4, closed=true),closed=true,width=.1);
// Example(2D): You can alter the shape of the curve by specifying your own arbitrary tangent values
//   polygon(smooth_path(square(4),tangents=1.25*[[-2,-1], [-4,1], [1,2], [6,-1]],size=0.4,closed=true));
// Example(2D): Or you can give a different size for each segment
//   polygon(smooth_path(square(4),size = [.4, .05, 1, .3],closed=true));
// Example(FlatSpin,VPD=35,VPT=[4.5,4.5,1]):  Works on 3d paths as well
//   path = [[0,0,0],[3,3,2],[6,0,1],[9,9,0]];
//   stroke(smooth_path(path,relsize=.1),width=.3);
// Example(2D): This shows the type of overshoot that can occur with uniform=true.  You can produce overshoots like this if you supply a tangent that is difficult to connect to the adjacent points  
//   pts = [[-3.3, 1.7], [-3.7, -2.2], [3.8, -4.8], [-0.9, -2.4]];
//   stroke(smooth_path(pts, uniform=true, relsize=0.1),width=.1);
//   color("red")move_copies(pts)circle(r=.15,$fn=12);
// Example(2D): With the default of uniform false no overshoot occurs.  Note that the shape of the curve is quite different.  
//   pts = [[-3.3, 1.7], [-3.7, -2.2], [3.8, -4.8], [-0.9, -2.4]];
//   stroke(smooth_path(pts, uniform=false, relsize=0.1),width=.1);
//   color("red")move_copies(pts)circle(r=.15,$fn=12);
module smooth_path(path, tangents, size, relsize, splinesteps=10, uniform=false, closed=false) {no_module();}
function smooth_path(path, tangents, size, relsize, splinesteps=10, uniform=false, closed=false) =
  let (
     bez = path_to_bezier(path, tangents=tangents, size=size, relsize=relsize, uniform=uniform, closed=closed)
  )
  bezier_path(bez,splinesteps=splinesteps);



function _scalar_to_vector(value,length,varname) = 
  is_vector(value)
    ? assert(len(value)==length, str(varname," must be length ",length))
      value
    : assert(is_num(value), str(varname, " must be a numerical value"))
      repeat(value, length);


// Function: path_join()
// Usage:
//   joined_path = path_join(paths, [joint], [k=], [relocate=], [closed=]);
// Description:
//   Connect a sequence of paths together into a single path with optional rounding
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
//   previous path sections.
//   .
//   The rounding is created by extending the two clipped paths to define a corner point.  If the extensions of
//   the paths do not intersect, the function issues an error.  When closed=true the final path should actually close
//   the shape, repeating the starting point of the shape.  If it does not, then the rounding will fill the gap.
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
//   stroke(path_join([horiz, vert, -horiz],joint=[[4,1],[1,4]],$fn=16),width=.3);
// Example(2D): A closed square
//   horiz = [[0,0],[10,0]];
//   vert = [[0,0],[0,10]];
//   stroke(path_join([horiz, vert, -horiz, -vert],joint=3,k=1,closed=true,$fn=16),closed=true);
// Example(2D): Different curve at each corner by changing the joint size
//   horiz = [[0,0],[10,0]];
//   vert = [[0,0],[0,10]];
//   stroke(path_join([horiz, vert, -horiz, -vert],joint=[3,0,1,2],k=1,closed=true,$fn=16),closed=true,width=0.4);
// Example(2D): Different curve at each corner by changing the curvature parameter.  Note that k=0 still gives a small curve, unlike joint=0 which gives a sharp corner.
//   horiz = [[0,0],[10,0]];
//   vert = [[0,0],[0,10]];
//   stroke(path_join([horiz, vert, -horiz, -vert],joint=3,k=[1,.5,0,.7],closed=true,$fn=16),closed=true,width=0.4);
// Example(2D): Joint value of 7 is larger than half the square so curves interfere with each other, which breaks symmetry because they are computed sequentially
//   horiz = [[0,0],[10,0]];
//   vert = [[0,0],[0,10]];
//   stroke(path_join([horiz, vert, -horiz, -vert],joint=7,k=.4,closed=true,$fn=16),closed=true);
// Example(2D): Unlike round_corners, we can add curves onto curves.
//   $fn=64;
//   myarc = arc(width=20, thickness=5 );
//   stroke(path_join(repeat(myarc,3), joint=4));
// Example(2D): Here we make a closed shape from two arcs and round the sharp tips
//   arc1 = arc(width=20, thickness=4,$fn=75);
//   arc2 = reverse(arc(width=20, thickness=2,$fn=75));
//   stroke(path_join([arc1,arc2]),width=.3);    // Join without rounding
//   color("red")stroke(path_join([arc1,arc2], 3,k=1,closed=true), width=.3,closed=true,$fn=12);  // Join with rounding
// Example(2D): Combining arcs with segments
//   arc1 = arc(width=20, thickness=4,$fn=75);
//   arc2 = reverse(arc(width=20, thickness=2,$fn=75));
//   vpath = [[0,0],[0,-5]];
//   stroke(path_join([arc1,vpath,arc2,reverse(vpath)]),width=.2);
//   color("red")stroke(path_join([arc1,vpath,arc2,reverse(vpath)], [1,2,2,1],k=1,closed=true), width=.2,closed=true,$fn=12);
// Example(2D): Here relocation is off.  We have three segments (in yellow) and add the curves to the segments.  Notice that joint zero still produces a curve because it refers to the endpoints of the supplied paths.  
//   p1 = [[0,0],[2,0]];
//   p2 = [[3,1],[1,3]];
//   p3 = [[0,3],[-1,1]];
//   color("red")stroke(path_join([p1,p2,p3], joint=0, relocate=false,closed=true),width=.3,$fn=12);
//   for(x=[p1,p2,p3]) stroke(x,width=.3);
// Example(2D): If you specify closed=true when the last path doesn't meet the first one then it is similar to using relocate=false: the function tries to close the path using a curve.  In the example below, this results in a long curve to the left, when given the unclosed three segments as input.  Note that if the segments are parallel the function fails with an error.  The extension of the curves must intersect in a corner for the rounding to be well-defined.  To get a normal rounding of the closed shape, you must include a fourth path, the last segment that closes the shape.
//   horiz = [[0,0],[10,0]];
//   vert = [[0,0],[0,10]];
//   h2 = [[0,-3],[10,0]];
//   color("red")stroke(path_join([horiz, vert, -h2],closed=true,joint=3,$fn=25),closed=true,width=.5);
//   stroke(path_join([horiz, vert, -h2]),width=.3);
// Example(2D): With a single path with closed=true the start and end junction is rounded.
//   tri = regular_ngon(n=3, r=7);
//   stroke(path_join([tri], joint=3,closed=true,$fn=12),closed=true,width=.5);
module path_join(paths,joint=0,k=0.5,relocate=true,closed=false) { no_module();}
function path_join(paths,joint=0,k=0.5,relocate=true,closed=false)=
  assert(is_list(paths),"Input paths must be a list of paths")
  let(
      badpath = [for(j=idx(paths)) if (!is_path(paths[j])) j]
  )
  assert(badpath==[], str("Entries in paths are not valid paths: ",badpath))
  len(paths)==0 ? [] :
  len(paths)==1 && !closed ? paths[0] :
  let(
      paths = !closed || len(paths)>1
            ? paths
            : [close_path(paths[0])],
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
  closed ? cleanup_path(result) : result;

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
     corner = ray_intersection([firstcut[0], firstcut[0]-first_dir], [nextcut[0], nextcut[0]-next_dir])
  )
  assert(is_def(corner), str("Curve directions at cut points don't intersect in a corner when ",
                             loop?"closing the path":str("adding path ",i+1)))
  let(
      bezpts = _smooth_bez_fill([firstcut[0], corner, nextcut[0]],k[i]),
      N = max(3,$fn>0 ?$fn : ceil(bezier_segment_length(bezpts)/$fs)),
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


// Function&Module: offset_sweep()
// Usage: most common module arguments.  See Arguments list below for more.
//    offset_sweep(path, <height|h|l>, [bottom], [top], [offset=], [convexity=],...) [attachments]
// Usage: most common function arguments.  See Arguments list below for more.
//    vnf = offset_sweep(path, <height|h|l>, [bottom], [top], [offset=], ...)
// Description:
//   Takes a 2d path as input and extrudes it upwards and/or downward.  Each layer in the extrusion is produced using `offset()` to expand or shrink the previous layer.  When invoked as a function returns a VNF; when invoked as a module produces geometry.  
//   Using the `top` and/or `bottom` arguments you can specify a sequence of offsets values, or you can use several built-in offset profiles that
//   provide end treatments such as roundovers.
//   The height of the resulting object can be specified using the `height` argument, in which case `height` must be larger than the combined height
//   of the end treatments.  If you omit `height` then the object height will be the height of just the top and bottom end treatments.  
//   .
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
//   .
//   The build-in profiles are: circular rounding, teardrop rounding, chamfer, continuous curvature rounding, and chamfer.
//   Also note that when a rounding radius is negative the rounding will flare outwards.  The easiest way to specify
//   the profile is by using the profile helper functions.  These functions take profile parameters, as well as some
//   general settings and translate them into a profile specification, with error checking on your input.  The description below
//   describes the helper functions and the parameters specific to each function.  Below that is a description of the generic
//   settings that you can optionally use with all of the helper functions.
//   .
//   - profile: os_profile(points)
//     Define the offset profile with a list of points.  The first point must be [0,0] and the roundover should rise in the positive y direction, with positive x values for inward motion (standard roundover) and negative x values for flaring outward.  If the y value ever decreases then you might create a self-intersecting polyhedron, which is invalid.  Such invalid polyhedra will create cryptic assertion errors when you render your model and it is your responsibility to avoid creating them.  Note that the starting point of the profile is the center of the extrusion.  If you use a profile as the top it will rise upwards.  If you use it as the bottom it will be inverted, and will go downward.
//   - circle: os_circle(r|cut).  Define circular rounding either by specifying the radius or cut distance.
//   - smooth: os_smooth(cut|joint).  Define continuous curvature rounding, with `cut` and `joint` as for round_corners.
//   - teardrop: os_teardrop(r|cut).  Rounding using a 1/8 circle that then changes to a 45 degree chamfer.  The chamfer is at the end, and enables the object to be 3d printed without support.  The radius gives the radius of the circular part.
//   - chamfer: os_chamfer([height], [width], [cut], [angle]).  Chamfer the edge at desired angle or with desired height and width.  You can specify height and width together and the angle will be ignored, or specify just one of height and width and the angle is used to determine the shape.  Alternatively, specify "cut" along with angle to specify the cut back distance of the chamfer.
//   - mask: os_mask(mask, [out]).  Create a profile from one of the [2d masking shapes](shapes2d.scad#5-2d-masking-shapes).  The `out` parameter specifies that the mask should flare outward (like crown molding or baseboard).  This is set false by default.  
//   .
//   The general settings that you can use with all of the helper functions are mostly used to control how offset_sweep() calls the offset() function.
//   - extra: Add an extra vertical step of the specified height, to be used for intersections or differences.  This extra step will extend the resulting object beyond the height you specify.  Default: 0
//   - check_valid: passed to offset().  Default: true
//   - quality: passed to offset().  Default: 1
//   - steps: Number of vertical steps to use for the profile.  (Not used by os_profile).  Default: 16
//   - offset_maxstep: The maxstep distance for offset() calls; controls the horizontal step density.  Set smaller if you don't get the expected rounding.  Default: 1
//   - offset: Select "round" (r=) or "delta" (delta=) offset types for offset. You can also choose "chamfer" but this leads to exponential growth in the number of vertices with the steps parameter.  Default: "round"
//   .
//   Many of the arguments are described as setting "default" values because they establish settings which may be overridden by
//   the top and bottom profile specifications.
//   .
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
//   - "offset" - select "round" (r=), "delta" (delta=), or "chamfer" offset type for offset.  Default: "round"
//   .
//   Note that if you set the "offset" parameter to "chamfer" then every exterior corner turns from one vertex into two vertices with
//   each offset operation.  Since the offsets are done one after another, each on the output of the previous one, this leads to
//   exponential growth in the number of vertices.  This can lead to long run times or yield models that
//   run out of recursion depth and give a cryptic error.  Furthermore, the generated vertices are distributed non-uniformly.  Generally you
//   will get a similar or better looking model with fewer vertices using "round" instead of
//   "chamfer".  Use the "chamfer" style offset only in cases where the number of steps is very small or just one (such as when using
//   the `os_chamfer` profile type).
//
// Arguments:
//   path = 2d path (list of points) to extrude
//   height / l / h = total height (including rounded portions, but not extra sections) of the output.  Default: combined height of top and bottom end treatments.
//   bottom = rounding spec for the bottom end
//   top = rounding spec for the top end.
//   ---
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
//   convexity = convexity setting for use with polyhedron.  (module only) Default: 10
//   anchor = Translate so anchor point is at the origin.  (module only) Default: "origin"
//   spin = Rotate this many degrees around Z axis after anchor.  (module only) Default: 0
//   orient = Vector to rotate top towards after spin  (module only)
//   extent = use extent method for computing anchors. (module only)  Default: false
//   cp = set centerpoint for anchor computation.  (module only) Default: object centroid
// Example: Rounding a star shaped prism with postive radius values
//   star = star(5, r=22, ir=13);
//   rounded_star = round_corners(star, cut=flatten(repeat([.5,0],5)), $fn=24);
//   offset_sweep(rounded_star, height=20, bottom=os_circle(r=4), top=os_circle(r=1), steps=15);
// Example: Rounding a star shaped prism with negative radius values
//   star = star(5, r=22, ir=13);
//   rounded_star = round_corners(star, cut=flatten(repeat([.5,0],5)), $fn=24);
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
//    star = star(5, r=22, ir=13);
//    rounded_star = round_corners(star, cut=flatten(repeat([.5,0],5)), $fn=24);
//    offset_sweep(rounded_star, height=20, bottom=os_teardrop(r=4), top=os_chamfer(width=4,offset_maxstep=.1));
// Example: We round a cube using the continous curvature rounding profile.  But note that the corners are not smooth because the curved square collapses into a square with corners.    When a collapse like this occurs, we cannot turn `check_valid` off.
//   square = square(1);
//   rsquare = round_corners(square, method="smooth", cut=0.1, k=0.7, $fn=36);
//   end_spec = os_smooth(cut=0.1, k=0.7, steps=22);
//   offset_sweep(rsquare, height=1, bottom=end_spec, top=end_spec);
// Example: A nice rounded box, with a teardrop base and circular rounded interior and top
//   box = square([255,50]);
//   rbox = round_corners(box, method="smooth", cut=4, $fn=12);
//   thickness = 2;
//   difference(){
//     offset_sweep(rbox, height=50, check_valid=false, steps=22, bottom=os_teardrop(r=2), top=os_circle(r=1));
//     up(thickness)
//       offset_sweep(offset(rbox, r=-thickness, closed=true,check_valid=false),
//                     height=48, steps=22, check_valid=false, bottom=os_circle(r=4), top=os_circle(r=-1,extra=1));
//   }
// Example: This box is much thicker, and cut in half to show the profiles.  Note also that we can turn `check_valid` off for the outside and for the top inside, but not for the bottom inside.  This example shows use of the direct keyword syntax without the helper functions.
//   smallbox = square([75,50]);
//   roundbox = round_corners(smallbox, method="smooth", cut=4, $fn=12);
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
//   box = square([255,50]);
//   cutpoints = [0, 125, 190, 255];
//   rbox = round_corners(box, method="smooth", cut=4, $fn=12);
//   back_half(y=25, s=700)
//     difference(){
//       offset_sweep(rbox, height=50, check_valid=false, steps=22, bottom=os_teardrop(r=2), top=os_circle(r=1));
//       up(thickness)
//         for(i=[0:2]){
//           ofs = i==1 ? 2 : 0;
//           hole = round_corners([[cutpoints[i]-ofs,0], [cutpoints[i]-ofs,50], [cutpoints[i+1]+ofs, 50], [cutpoints[i+1]+ofs,0]],
//                                method="smooth", cut=4, $fn=36);
//           offset_sweep(offset(hole, r=-thickness, closed=true,check_valid=false),
//                         height=48, steps=22, check_valid=false, bottom=os_circle(r=4), top=os_circle(r=-1,extra=1));
//         }
//     }
// Example: Star shaped box
//   star = star(5, r=22, ir=13);
//   rounded_star = round_corners(star, cut=flatten(repeat([.5,0],5)), $fn=24);
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
//   rounded_star = round_corners(star, cut=flatten(repeat([.5,0],5)), $fn=24);
//   profile = os_profile(points=[[0,0],[.3,.1],[.6,.3],[.9,.9], [1.2, 2.7],[.8,2.7],[.8,3]]);
//   offset_sweep(reverse(rounded_star), height=20, top=profile, bottom=profile);
// Example: Parabolic rounding
//   star = star(5, r=22, ir=13);
//   rounded_star = round_corners(star, cut=flatten(repeat([.5,0],5)), $fn=24);
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
//   rhex = round_corners(hexagon(side=10), method="smooth", joint=2, $fs=0.2);
//   back_half()
//     difference(){
//       offset_sweep(rhex, height=10, bottom=os_teardrop(r=2), top=os_teardrop(r=-4, extra=0.2));
//       up(1)
//         offset_sweep(offset(rhex,r=-1), height=9.5, bottom=os_circle(r=2), top=os_teardrop(r=-4));
//     }
// Example: Using os_mask to create ogee profiles:
//   ogee = mask2d_ogee([
//       "xstep",1,  "ystep",1,  // Starting shoulder.
//       "fillet",5, "round",5,  // S-curve.
//       "ystep",1,              // Ending shoulder.
//   ]);
//   star = star(5, r=220, ir=130);
//   rounded_star = round_corners(star, cut=flatten(repeat([5,0],5)), $fn=24);
//   offset_sweep(rounded_star, height=100, top=os_mask(ogee), bottom=os_mask(ogee,out=true));


// This function does the actual work of repeatedly calling offset() and concatenating the resulting face and vertex lists to produce
// the inputs for the polyhedron module.
function _make_offset_polyhedron(path,offsets, offset_type, flip_faces, quality, check_valid, maxstep, offsetind=0,
                                 vertexcount=0, vertices=[], faces=[] )=
        offsetind==len(offsets)? (
                let(
                        bottom = count(len(path),vertexcount),
                        oriented_bottom = !flip_faces? bottom : reverse(bottom)
                ) [vertices, concat(faces,[oriented_bottom])]
        ) : (
                let(
                        this_offset = offsetind==0? offsets[0][0] : offsets[offsetind][0] - offsets[offsetind-1][0],
                        delta = offset_type=="delta" || offset_type=="chamfer" ? this_offset : undef,
                        r = offset_type=="round"? this_offset : undef,
                        do_chamfer = offset_type == "chamfer"
                )
                let(
                        vertices_faces = offset(
                                path, r=r, delta=delta, chamfer = do_chamfer, closed=true,
                                check_valid=check_valid, quality=quality,
                                maxstep=maxstep, return_faces=true,
                                firstface_index=vertexcount,
                                flip_faces=flip_faces
                        )
                )
                _make_offset_polyhedron(
                        vertices_faces[0], offsets, offset_type,
                        flip_faces, quality, check_valid, maxstep,
                        offsetind+1, vertexcount+len(path),
                        vertices=concat(
                                vertices,
                                path3d(vertices_faces[0],offsets[offsetind][1])
                        ),
                        faces=concat(faces, vertices_faces[1])
                )
        );


function offset_sweep(
                       path, height, 
                       bottom=[], top=[], 
                       h, l,
                       offset="round", r=0, steps=16,
                       quality=1, check_valid=true,
                       offset_maxstep=1, extra=0,
                       cut=undef, chamfer_width=undef, chamfer_height=undef,
                       joint=undef, k=0.75, angle=45
                      ) =
    let(
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
        ],
        path = check_and_fix_path(path, [2], closed=true),
        clockwise = polygon_is_clockwise(path),
        
        top = struct_set(argspec, top, grow=false),
        bottom = struct_set(argspec, bottom, grow=false),

        //  This code does not work.  It hits the error in _make_offset_polyhedron from offset being wrong
        //  before this code executes.  Had to move the test into _make_offset_polyhedron, which is ugly since it's in the loop
        offsetsok = in_list(struct_val(top, "offset"),["round","delta"])
                    && in_list(struct_val(bottom, "offset"),["round","delta"])
    )
    assert(offsetsok,"Offsets must be one of \"round\" or \"delta\"")
    let(
        offsets_bot = _rounding_offsets(bottom, -1),
        offsets_top = _rounding_offsets(top, 1),
        dummy = offset == "chamfer" && (len(offsets_bot)>5 || len(offsets_top)>5)
                ? echo("WARNING: You have selected offset=\"chamfer\", which leads to exponential growth in the vertex count and requested more than 5 layers.  This can be slow or run out of recursion depth.")
                : 0,

        // "Extra" height enlarges the result beyond the requested height, so subtract it
        bottom_height = len(offsets_bot)==0 ? 0 : abs(last(offsets_bot)[1]) - struct_val(bottom,"extra"),
        top_height = len(offsets_top)==0 ? 0 : abs(last(offsets_top)[1]) - struct_val(top,"extra"),

        height = one_defined([l,h,height], "l,h,height", dflt=u_add(bottom_height,top_height)),
        middle = height-bottom_height-top_height
    )
    assert(height>0, "Height must be positive") 
    assert(middle>=0, str("Specified end treatments (bottom height = ",bottom_height,
                          " top_height = ",top_height,") are too large for extrusion height (",height,")"
                         )
    )
    let(
        initial_vertices_bot = path3d(path),

        vertices_faces_bot = _make_offset_polyhedron(
                path, offsets_bot, struct_val(bottom,"offset"), clockwise,
                struct_val(bottom,"quality"),
                struct_val(bottom,"check_valid"),
                struct_val(bottom,"offset_maxstep"),
                vertices=initial_vertices_bot
        ),

        top_start_ind = len(vertices_faces_bot[0]),
        initial_vertices_top = path3d(path, middle),
        vertices_faces_top = _make_offset_polyhedron(
                path, move(p=offsets_top,[0,middle]),
                struct_val(top,"offset"), !clockwise,
                struct_val(top,"quality"),
                struct_val(top,"check_valid"),
                struct_val(top,"offset_maxstep"),
                vertexcount=top_start_ind,
                vertices=initial_vertices_top
        ),
        middle_faces = middle==0 ? [] : [
                for(i=[0:len(path)-1]) let(
                        oneface=[i, (i+1)%len(path), top_start_ind+(i+1)%len(path), top_start_ind+i]
                ) !clockwise ? reverse(oneface) : oneface
        ]
    )
    [up(bottom_height, concat(vertices_faces_bot[0],vertices_faces_top[0])),  // Vertices
     concat(vertices_faces_bot[1], vertices_faces_top[1], middle_faces)];     // Faces


module offset_sweep(path, height, 
                    bottom=[], top=[], 
                    h, l,
                    offset="round", r=0, steps=16,
                    quality=1, check_valid=true,
                    offset_maxstep=1, extra=0,
                    cut=undef, chamfer_width=undef, chamfer_height=undef,
                    joint=undef, k=0.75, angle=45,
                    convexity=10,anchor="origin",cp,
                    spin=0, orient=UP, extent=false)
{
    vnf = offset_sweep(path=path, height=height, h=h, l=l, top=top, bottom=bottom, offset=offset, r=r, steps=steps,
                       quality=quality, check_valid=true, offset_maxstep=offset_maxstep, extra=extra, cut=cut, chamfer_width=chamfer_width,
                       chamfer_height=chamfer_height, joint=joint, k=k, angle=angle);
  
    attachable(anchor=anchor, spin=spin, orient=orient, vnf=vnf, extent=extent, cp=is_def(cp) ? cp : vnf_centroid(vnf))
    {
        vnf_polyhedron(vnf,convexity=convexity);
        children();
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


function os_mask(mask, out=false, extra,check_valid, quality, offset_maxstep, offset) =
  let(
      origin_index = [for(i=idx(mask)) if (mask[i].x<0 && mask[i].y<0) i],
      xfactor = out ? -1 : 1
  )
  assert(len(origin_index)==1,"Cannot find origin in the mask")
  let(
      points = ([for(pt=polygon_shift(mask,origin_index[0])) [xfactor*max(pt.x,0),-max(pt.y,0)]])
  )
  os_profile(deduplicate(move(-points[1],p=list_tail(points))), extra,check_valid,quality,offset_maxstep,offset);


// Module: convex_offset_extrude()
//
// Description:
//   Extrudes 2d children with layers formed from the convex hull of the offset of each child according to a sequence of offset values.
//   Like `offset_sweep` this module can use built-in offset profiles to provide treatments such as roundovers or chamfers but unlike `offset_sweep()` it
//   operates on 2d children rather than a point list.  Each offset is computed using
//   the native `offset()` module from the input geometry.  If your geometry has internal holes or is too small for the specified offset then you may get
//   unexpected results.
//   .
//   The build-in profiles are: circular rounding, teardrop rounding, chamfer, continuous curvature rounding, and chamfer.
//   Also note that when a rounding radius is negative the rounding will flare outwards.  The easiest way to specify
//   the profile is by using the profile helper functions.  These functions take profile parameters, as well as some
//   general settings and translate them into a profile specification, with error checking on your input.  The description below
//   describes the helper functions and the parameters specific to each function.  Below that is a description of the generic
//   settings that you can optionally use with all of the helper functions.
//   .
//   The final shape is created by combining convex hulls of small extrusions.  The thickness of these small extrusions may result
//   your model being slightly too long (if the curvature at the end is flaring outward), so if the exact length is very important
//   you may need to intersect with a bounding cube.  (Note that extra length can also be intentionally added with the `extra` argument.)
//   .
//   - profile: os_profile(points)
//     Define the offset profile with a list of points.  The first point must be [0,0] and the roundover should rise in the positive y direction, with positive x values for inward motion (standard roundover) and negative x values for flaring outward.  If the y value ever decreases then you might create a self-intersecting polyhedron, which is invalid.  Such invalid polyhedra will create cryptic assertion errors when you render your model and it is your responsibility to avoid creating them.  Note that the starting point of the profile is the center of the extrusion.  If you use a profile as the top it will rise upwards.  If you use it as the bottom it will be inverted, and will go downward.
//   - circle: os_circle(r|cut).  Define circular rounding either by specifying the radius or cut distance.
//   - smooth: os_smooth(cut|joint).  Define continuous curvature rounding, with `cut` and `joint` as for round_corners.
//   - teardrop: os_teardrop(r|cut).  Rounding using a 1/8 circle that then changes to a 45 degree chamfer.  The chamfer is at the end, and enables the object to be 3d printed without support.  The radius gives the radius of the circular part.
//   - chamfer: os_chamfer([height], [width], [cut], [angle]).  Chamfer the edge at desired angle or with desired height and width.  You can specify height and width together and the angle will be ignored, or specify just one of height and width and the angle is used to determine the shape.  Alternatively, specify "cut" along with angle to specify the cut back distance of the chamfer.
//   .
//   The general settings that you can use with all of the helper functions are mostly used to control how offset_sweep() calls the offset() function.
//   - extra: Add an extra vertical step of the specified height, to be used for intersections or differences.  This extra step will extend the resulting object beyond the height you specify.  Default: 0
//   - steps: Number of vertical steps to use for the profile.  (Not used by os_profile).  Default: 16
//   - offset: Select "round" (r=), "delta" (delta=), or "chamfer" offset types for offset.  Default: "round"
//   .
//   Many of the arguments are described as setting "default" values because they establish settings which may be overridden by
//   the top and bottom profile specifications.
//   .
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
//   - "steps" - number of vertical steps to use for the roundover.  Default: 16.
//   - "offset" - select "round" (r=) or "delta" (delta=) offset type for offset.  Default: "round"
//   .
//   Note that unlike `offset_sweep`, because the offset operation is always performed from the base shape, using chamfered offsets does not increase the
//   number of vertices or lead to any special complications.
//
// Arguments:
//   height / l / h = total height (including rounded portions, but not extra sections) of the output.  Default: combined height of top and bottom end treatments.
//   top = rounding spec for the top end.
//   bottom = rounding spec for the bottom end
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
// Example: Chamfered elliptical prism.  If you stretch a chamfered cylinder the chamfer will be uneven.
//   convex_offset_extrude(bottom = os_chamfer(height=-2), top=os_chamfer(height=1), height=7)
//   xscale(4)circle(r=6,$fn=64);
// Example: Elliptical prism with circular roundovers.
//   convex_offset_extrude(bottom=os_circle(r=-2), top=os_circle(r=1), height=7,steps=10)
//   xscale(4)circle(r=6,$fn=64);
// Example: If you give a non-convex input you get a convex hull output
//   right(50) linear_extrude(height=7) star(5,r=22,ir=13);
//   convex_offset_extrude(bottom = os_chamfer(height=-2), top=os_chamfer(height=1), height=7)
//     star(5,r=22,ir=13);
function convex_offset_extrude(
        height, h, l,
        top=[], bottom=[],
        offset="round", r=0, steps=16,
        extra=0,
        cut=undef, chamfer_width=undef, chamfer_height=undef,
        joint=undef, k=0.75, angle=45,
        convexity=10, thickness = 1/1024
) = no_function("convex_offset_extrude");
module convex_offset_extrude(
        height, h, l,
        top=[], bottom=[],
        offset="round", r=0, steps=16,
        extra=0,
        cut=undef, chamfer_width=undef, chamfer_height=undef,
        joint=undef, k=0.75, angle=45,
        convexity=10, thickness = 1/1024
) {
        argspec = [
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

        height = one_defined([l,h,height], "l,h,height", dflt=u_add(bottom_height,top_height));
        assert(height>=0, "Height must be nonnegative");

        middle = height-bottom_height-top_height;
        assert(
                middle>=0, str(
                        "Specified end treatments (bottom height = ",bottom_height,
                        " top_height = ",top_height,") are too large for extrusion height (",height,")"
                )
        );
        // The entry r[i] is [radius,z] for a given layer
        r = move([0,bottom_height],p=concat(
                          reverse(offsets_bot), [[0,0], [0,middle]], move([0,middle], p=offsets_top)));
        delta = [for(val=deltas(subindex(r,0))) sign(val)];
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
}



function _remove_undefined_vals(list) =
        let(ind=search([undef],list,0)[0])
        list_remove(list, concat(ind, add_scalar(ind,-1)));


// Function&Module: offset_stroke()
// Usage: as module
//   offset_stroke(path, [width], [rounded=], [chamfer=], [start=], [end=], [check_valid=], [quality=], [maxstep=], [closed=]);
// Usage: as function
//   path = offset_stroke(path, [width], closed=false, [rounded=], [chamfer=], [start=], [end=], [check_valid=], [quality=], [maxstep=]);
//   region = offset_stroke(path, [width], closed=true, [rounded=], [chamfer=], [start=], [end=], [check_valid=], [quality=], [maxstep=]);
// Description:
//   Uses `offset()` to compute a stroke for the input path.  Unlike `stroke`, the result does not need to be
//   centered on the input path.  The corners can be rounded, pointed, or chamfered, and you can make the ends
//   rounded, flat or pointed with the `start` and `end` parameters.
//   .
//   The `check_valid`, `quality` and `maxstep` parameters are passed through to `offset()`
//   .
//   If `width` is a scalar then the output will be a centered stroke of the specified width.  If width
//   is a list of two values then those two values will define the stroke side positions relative to the center line, where
//   as with offset(), the shift is to the left for open paths and outward for closed paths.  For example,
//   setting `width` to `[0,1]` will create a stroke of width 1 that extends entirely to the left of the input, and and [-4,-6]
//   will create a stroke of width 2 offset 4 units to the right of the input path.
//   .
//   If closed==false then the function form will return a path.  If closed==true then it will return a region.  The `start` and
//   `end` parameters are forbidden for closed paths.
//   .
//   Three simple end treatments are supported, "flat" (the default), "round" and "pointed".  The "flat" treatment
//   cuts off the ends perpendicular to the path and the "round" treatment applies a semicircle to the end.  The
//   "pointed" end treatment caps the stroke with a centered triangle that has 45 degree angles on each side.
//   .
//   More complex end treatments are available through parameter lists with helper functions to ease parameter passing.  The parameter list
//   keywords are
//      - "type": the type of end treatment, one of "shifted_point", "roundover", or "flat"
//      - "angle": relative angle (relative to the path)
//      - "abs_angle": absolute angle (angle relative to x-axis)
//      - "cut": cut distance for roundovers, a single value to round both corners identically or a list of two values for the two corners.  Negative values round outward.
//      - "k": curvature smoothness parameter for roundovers, default 0.75
//   .
//   Function helpers for defining ends, prefixed by "os" for offset_stroke.
//   .
//   os_flat(angle|absangle): specify a flat end either relative to the path or relative to the x-axis
//   os_pointed(loc,dist): specify a pointed tip where the point is distance `loc` from the centerline (positive is the left direction as for offset), and `dist` is the distance from the path end to the point tip.  The default value for `loc` is zero (the center).  You must specify `dist` when using this option.
//   os_round(cut,angle|absangle,k).  Rounded ends with the specified cut distance, based on the specified angle or absolute angle.  The `k` parameter is the smoothness parameter for continuous curvature rounding.
//   .
//   Note that `offset_stroke()` will attempt to apply roundovers and angles at the ends even when it means deleting segments of the stroke, unlike round_corners which only works on a segment adjacent to a corner.  If you specify an overly extreme angle it will fail to find an intersection with the stroke and display an error.  When you specify an angle the end segment is rotated around the center of the stroke and the last segment of the stroke one one side is extended to the corner.
//   .
//   The $fn and $fs variables are used to determine the number of segments for rounding, while maxstep is used to determine the segments of `offset`.  If you
//   get the expected rounding along the path, decrease `maxstep` and if the curves created by `os_round()` are too coarse, adjust $fn or $fs.
//
// Arguments:
//   path = 2d path that defines the stroke
//   width = width of the stroke, a scalar or a vector of 2 values giving the offset from the path.  Default: 1
//   ---
//   rounded = set to true to use rounded offsets, false to use sharp (delta) offsets.  Default: true
//   chamfer = set to true to use chamfers when `rounded=false`.  Default: false
//   start = end treatment for the start of the stroke.  See above for details.  Default: "flat"
//   end = end treatment for the end of the stroke.  See above for details.  Default: "flat"
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
//   $fn=36;
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
//   offset_stroke(path, width=2, rounded=false,start=os_round(cut=-1, abs_angle=90), end=os_round(cut=-0.5, abs_angle=0),$fn=36);
//   right(10)
//      offset_stroke(arc, width=2, rounded=false, start=os_round(cut=[-.75,-.2], angle=-45), end=os_round(cut=[-.2,.2], angle=20),$fn=36);
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
//   offset_stroke(path, check_valid=true,rounded=false,width = [1.4, 1.5]);
//   right(2)
//     offset_stroke(path, check_valid=false,rounded=false,width = [1.4, 1.5]);
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
        assert(is_path(path,2),"path is not a 2d path")
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
                parallel_dir = unit(left[0]-right[0]),
                normal_dir = unit(normal_seg[1]-normal_seg[0]),
                width_dir = sign(width[0]-width[1])
        )
        type == "round"? [arc(points=[right[0],normal_pt,left[0]],N=ceil(segs(width/2)/2)),1,1]  :
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
                        roundover_fits = jointleft+jointright < norm(rightcorner-leftcorner)
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
                       prev_degenerate = is_undef(ray_intersection(path2d([far_corner, far_corner+prev]), path2d([prev_offset, prev_offset+in_prev]))),
                       next_degenerate = is_undef(ray_intersection(path2d([far_corner, far_corner+next]), path2d([next_offset, next_offset+in_next])))
                    )
                    [ prev_degenerate ? far_corner : prev_corner,
                      far_corner,
                      next_degenerate ? far_corner : next_corner]
            ) _smooth_bez_fill(
                      [for(row=[row0, row2, row4]) _smooth_bez_fill(row,ksides[i])],
                      ktop)];


// Function&Module: rounded_prism()
// Usage: as a module
//   rounded_prism(bottom, [top], <height=|h=|length=|l=>, [joint_top=], [joint_bot=], [joint_sides=], [k=], [k_top=], [k_bot=], [k_sides=], [splinesteps=], [debug=], [convexity=],...) [attachments];
// Usage: as a function
//   vnf = rounded_prism(bottom, [top], <height=|h=|length=|l=>, [joint_top=], [joint_bot=], [joint_sides=], [k=], [k_top=], [k_bot=], [k_sides=], [splinesteps=], [debug=]);
// Description:
//   Construct a generalized prism with continuous curvature rounding.  You supply the polygons for the top and bottom of the prism.  The only
//   limitation is that joining the edges must produce a valid polyhedron with coplanar side faces.  You specify the rounding by giving
//   the joint distance away from the corner for the rounding curve.  The k parameter ranges from 0 to 1 with a default of 0.5.  Larger
//   values give a more abrupt transition and smaller ones a more gradual transition.  If you set the value much higher
//   than 0.8 the curvature changes abruptly enough that though it is theoretically continuous, it may
//   not be continuous in practice.  A value of 0.92 is a good approximation to a circle.  If you set it very small then the transition
//   is so gradual that the roundover may be very small.  If you want a very smooth roundover, set the joint parameter as large as possible and
//   then adjust the k value down as low as gives a sufficiently large roundover.
//   .
//   You can specify the bottom and top polygons by giving two compatible 3d paths.  You can also give 2d paths and a height/length and the
//   two shapes will be offset in the z direction from each other.  The final option is to specify just the bottom along with a height/length;
//   in this case the top will be a copy of the bottom, offset in the z direction by the specified height.
//   .
//   You define rounding for all of the top edges, all of the bottom edges, and independently for each of the connecting side edges.
//   You specify rounding the rounding by giving the joint distance for where the curved section should start.  If the joint distance is 1 then
//   it means the curved section begins 1 unit away from the edge (in the perpendicular direction).  Typically each joint distance is a scalar
//   value and the rounding is symmetric around each edge.  However, you can specify a 2-vector for the joint distance to produce asymmetric
//   rounding which is different on the two sides of the edge.  This may be useful when one one edge in your polygon is much larger than another.
//   For the top and bottom you can specify negative joint distances.  If you give a scalar negative value then the roundover will flare
//   outward.  If you give a vector value then a negative value then if joint_top[0] is negative the shape will flare outward, but if
//   joint_top[1] is negative the shape will flare upward.  At least one value must be non-negative.  The same rules apply for joint_bot.
//   The joint_sides parameter must be entirely nonnegative.
//   .
//   If you set `debug` to true the module version will display the polyhedron even when it is invalid and it will show the bezier patches at the corners.
//   This can help troubleshoot problems with your parameters.  With the function form setting debug to true causes it to return [patches,vnf] where
//   patches is a list of the bezier control points for the corner patches.
//   .
// Arguments:
//   bottom = 2d or 3d path describing bottom polygon
//   top = 2d or 3d path describing top polygon (must be the same dimension as bottom)
//   ---
//   height/length/h/l = height of the shape when you give 2d bottom
//   joint_top = rounding length for top (number or 2-vector).  Default: 0
//   joint_bot = rounding length for bottom (number or 2-vector).  Default: 0
//   joint_sides = rounding length for side edges, a number/2-vector or list of them.  Default: 0
//   k = continuous curvature rounding parameter for all edges.  Default: 0.5
//   k_top = continuous curvature rounding parameter for top
//   k_bot = continuous curvature rounding parameter for bottom
//   k_bot = continuous curvature rounding parameter for bottom
//   splinesteps = number of segments to use for curved patches.  Default: 16
//   debug = turn on debug mode which displays illegal polyhedra and shows the bezier corner patches for troubleshooting purposes.  Default: False
//   convexity = convexity parameter for polyhedron(), only for module version.  Default: 10
//   anchor = Translate so anchor point is at the origin.  (module only) Default: "origin"
//   spin = Rotate this many degrees around Z axis after anchor.  (module only) Default: 0
//   orient = Vector to rotate top towards after spin  (module only)
//   extent = use extent method for computing anchors. (module only)  Default: false
//   cp = set centerpoint for anchor computation.  (module only) Default: object centroid
// Example: Uniformly rounded pentagonal prism
//   rounded_prism(pentagon(3), height=3, joint_top=0.5, joint_bot=0.5, joint_sides=0.5);
// Example: Maximum possible rounding.
//   rounded_prism(pentagon(3), height=3, joint_top=1.5, joint_bot=1.5, joint_sides=1.5);
// Example: Decreasing k from the default of 0.5 to 0.3 gives a smoother round over which takes up more space, so it appears less rounded.
//   rounded_prism(pentagon(3), height=3, joint_top=1.5, joint_bot=1.5, joint_sides=1.5, k=0.3, splinesteps=32);
// Example: Increasing k from the default of 0.5 to 0.92 approximates a circular roundover, which does not have continuous curvature.  Notice the visible "edges" at the boundary of the corner and edge patches.  
//   rounded_prism(pentagon(3), height=3, joint_top=0.5, joint_bot=0.5, joint_sides=0.5, k=0.92);
// Example: rounding just one edge
//   rounded_prism(pentagon(side=3), height=3, joint_top=0.5, joint_bot=0.5, joint_sides=[0,0,0.5,0,0], splinesteps=16);
// Example: rounding all the edges differently
//   rounded_prism(pentagon(side=3), height=3, joint_top=0.25, joint_bot=0.5, joint_sides=[1.7,.5,.7,1.2,.4], splinesteps=32);
// Example: different k values for top, bottom and sides
//   rounded_prism(pentagon(side=3.0), height=3.0, joint_top=1.4, joint_bot=1.4, joint_sides=0.7, k_top=0.7, k_bot=0.3, k_sides=0.5, splinesteps=48);
// Example: flared bottom
//   rounded_prism(pentagon(3), height=3, joint_top=1.0, joint_bot=-0.5, joint_sides=0.5);
// Example: truncated pyramid
//   rounded_prism(pentagon(3), apply(scale(.7),pentagon(3)), height=3, joint_top=0.5, joint_bot=0.5, joint_sides=0.5);
// Example: top translated
//   rounded_prism(pentagon(3), apply(right(2),pentagon(3)), height=3, joint_top=0.5, joint_bot=0.5, joint_sides=0.5);
// Example(NORENDER): top rotated: fails due to non-coplanar side faces
//   rounded_prism(pentagon(3), apply(rot(45),pentagon(3)), height=3, joint_top=0.5, joint_bot=0.5, joint_sides=0.5);
// Example: skew top
//   rounded_prism(path3d(pentagon(3)), apply(affine3d_skew_yz(0,-20),path3d(pentagon(3),3)), joint_top=0.5, joint_bot=0.5, joint_sides=0.5);
// Example: this rotation gives coplanar sides
//   rounded_prism(path3d(square(4)), apply(yrot(-100)*right(2),path3d(square(4),3)), joint_top=0.5, joint_bot=0.5, joint_sides=0.5);
// Example: a shape with concave corners
//   M = path3d(turtle(["left", 180, "length",3,"move", "left", "move", 3, "right", "move", "right", "move", 4, "right", "move", 3, "right", "move", 2]));
//   rounded_prism(M, apply(up(3),M), joint_top=0.75, joint_bot=0.2, joint_sides=[.2,2.5,2,0.5,1.5,.5,2.5], splinesteps=32);
// Example: using debug mode to see the corner patch sizes, which may help figure out problems with interfering corners or invalid polyhedra.  The corner patches must not intersect each other.
//   M = path3d(turtle(["left", 180, "length",3,"move", "left", "move", 3, "right", "move", "right", "move", 4, "right", "move", 3, "right", "move", 2]));
//   rounded_prism(M, apply(up(3),M), joint_top=0.75, joint_bot=0.2, joint_sides=[.2,2.5,2,0.5,1.5,.5,2.5], splinesteps=16,debug=true);
// Example: applying transformation to the previous example
//   M = path3d(turtle(["left", 180, "length",3,"move", "left", "move", 3, "right", "move", "right", "move", 4, "right", "move", 3, "right", "move", 2]));
//   rounded_prism(M, apply(right(1)*scale(.75)*up(3),M), joint_top=0.5, joint_bot=0.2, joint_sides=[.2,1,1,0.5,1.5,.5,2], splinesteps=32);
// Example: this example shows most of the different types of patches that rounded_prism creates.  Note that some of the patches are close to interfering with each other across the top of the polyhedron, which would create an invalid result.
//   N = apply(rot(180)*yscale(.8),turtle(["length",3,"left", "move", 2, "right", 135, "move", sqrt(2), "left", "move", sqrt(2), "right", 135, "move", 2]));
//   rounded_prism(N, height=3, joint_bot=0.5, joint_top=1.25, joint_sides=[[1,1.75],0,.5,.5,2], debug=true);
// Example: This object has different scales on its different axies.  Here is the largest symmetric rounding that fits.  Note that the rounding is slightly smaller than the object dimensions because of roundoff error.
//   rounded_prism(square([100.1,30.1]), height=8.1, joint_top=4, joint_bot=4, joint_sides=15, k_sides=0.3, splinesteps=32);
// Example: Using asymetric rounding enables a much more rounded form:
//   rounded_prism(square([100.1,30.1]), height=8.1, joint_top=[15,4], joint_bot=[15,4], joint_sides=[[15,50],[50,15],[15,50],[50,15]], k_sides=0.3, splinesteps=32);
// Example: Flaring the top upward instead of outward.  The bottom has an asymmetric rounding with a small flare but a large rounding up the side.
//   rounded_prism(pentagon(3), height=3, joint_top=[1,-1], joint_bot=[-0.5,2], joint_sides=0.5);
// Example: Sideways polygons:
//   rounded_prism(apply(yrot(95),path3d(hexagon(3))), apply(yrot(95), path3d(hexagon(3),3)), joint_top=2, joint_bot=1, joint_sides=1);
// Example: Chamfer a polyhedron by setting splinesteps to 1
//   N = apply(rot(180)*yscale(.8),turtle(["length",3,"left", "move", 2, "right", 135, "move", sqrt(2), "left", "move", sqrt(2), "right", 135, "move", 2]));
//   rounded_prism(N, height=3, joint_bot=-0.3, joint_top=.4, joint_sides=[.75,0,.2,.2,.7], splinesteps=1);


module rounded_prism(bottom, top, joint_bot=0, joint_top=0, joint_sides=0, k_bot, k_top, k_sides,
                     k=0.5, splinesteps=16, h, length, l, height, convexity=10, debug=false,
                     anchor="origin",cp,spin=0, orient=UP, extent=false)
{
  result = rounded_prism(bottom=bottom, top=top, joint_bot=joint_bot, joint_top=joint_top, joint_sides=joint_sides,
                         k_bot=k_bot, k_top=k_top, k_sides=k_sides, k=k, splinesteps=splinesteps, h=h, length=length, height=height, l=l,debug=debug);
  vnf = debug ? result[1] : result;
  attachable(anchor=anchor, spin=spin, orient=orient, vnf=vnf, extent=extent, cp=is_def(cp) ? cp : vnf_centroid(vnf))
  {
    if (debug){
        vnf_polyhedron(vnf, convexity=convexity);
        trace_bezier_patches(result[0], showcps=true, splinesteps=splinesteps, $fn=16, showdots=false, showpatch=false);
    }
    else vnf_polyhedron(vnf,convexity=convexity);
    children();
  }
}


function rounded_prism(bottom, top, joint_bot=0, joint_top=0, joint_sides=0, k_bot, k_top, k_sides, k=0.5, splinesteps=16,
                       h, length, l, height, debug=false) =
   assert(is_path(bottom) && len(bottom)>=3)
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
     bottom_sign = polygon_is_clockwise(bot_proj) ? 1 : -1,
     concave = [for(i=[0:N-1]) bottom_sign*sign(point_left_of_line2d(select(bot_proj,i+1), select(bot_proj, i-1,i)))>0],
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
   assert(coplanar(bottom))
   assert(coplanar(top))
   assert(!is_num(k_sides) || (k_sides>=0 && k_sides<=1), "Curvature parameter k_sides must be in interval [0,1]")
   let(
     non_coplanar=[for(i=[0:N-1]) if (!coplanar(concat(select(top,i,i+1), select(bottom,i,i+1)))) [i,(i+1)%N]],
     k_sides_vec = is_num(k_sides) ? repeat(k_sides, N) : k_sides,
     kbad = [for(i=[0:N-1]) if (k_sides_vec[i]<0 || k_sides_vec[i]>1) i],
     joint_sides_vec = jssingleok ? repeat(joint_sides,N) : joint_sides,
     top_collinear = [for(i=[0:N-1]) if (collinear(select(top,i-1,i+1))) i],
     bot_collinear = [for(i=[0:N-1]) if (collinear(select(bottom,i-1,i+1))) i]
   )
   assert(non_coplanar==[], str("Side faces are non-coplanar at edges: ",non_coplanar))
   assert(top_collinear==[], str("Top has collinear or duplicated points at indices: ",top_collinear))
   assert(bot_collinear==[], str("Bottom has collinear or duplicated points at indices: ",bot_collinear))
   assert(kbad==[], str("k_sides parameter outside interval [0,1] at indices: ",kbad))
   let(
     top_patch = _rp_compute_patches(top, bottom, joint_top, joint_sides_vec, k_top, k_sides_vec, concave),
     bot_patch = _rp_compute_patches(bottom, top, joint_bot, joint_sides_vec, k_bot, k_sides_vec, concave),

     vertbad = [for(i=[0:N-1])
                   if (norm(top[i]-top_patch[i][4][2]) + norm(bottom[i]-bot_patch[i][4][2]) > norm(bottom[i]-top[i])) i],
     topbad = [for(i=[0:N-1])
                   if (norm(top_patch[i][2][4]-top_patch[i][2][2]) + norm(select(top_patch,i+1)[2][0]-select(top_patch,i+1)[2][2])
                  > norm(top_patch[i][2][2] - select(top_patch,i+1)[2][2]))   [i,(i+1)%N]],
     botbad = [for(i=[0:N-1])
                   if (norm(bot_patch[i][2][4]-bot_patch[i][2][2]) + norm(select(bot_patch,i+1)[2][0]-select(bot_patch,i+1)[2][2])
                  > norm(bot_patch[i][2][2] - select(bot_patch,i+1)[2][2]))   [i,(i+1)%N]],
     topinbad = [for(i=[0:N-1])
                   if (norm(top_patch[i][0][2]-top_patch[i][0][4]) + norm(select(top_patch,i+1)[0][0]-select(top_patch,i+1)[0][2])
                          > norm(top_patch[i][0][2]-select(top_patch,i+1)[0][2])) [i,(i+1)%N]],
     botinbad = [for(i=[0:N-1])
                   if (norm(bot_patch[i][0][2]-bot_patch[i][0][4]) + norm(select(bot_patch,i+1)[0][0]-select(bot_patch,i+1)[0][2])
                          > norm(bot_patch[i][0][2]-select(bot_patch,i+1)[0][2])) [i,(i+1)%N]]
   )
   assert(debug || vertbad==[], str("Top and bottom joint lengths are too large; they interfere with each other at vertices: ",vertbad))
   assert(debug || topbad==[], str("Joint lengths too large at top edges: ",topbad))
   assert(debug || botbad==[], str("Joint lengths too large at bottom edges: ",botbad))
   assert(debug || topinbad==[], str("Joint length too large on the top face at edges: ", topinbad))
   assert(debug || botinbad==[], str("Joint length too large on the bottom face at edges: ", botinbad))
   let(
     // Entries in the next two lists have the form [edges, vnf] where
     // edges is a list [leftedge, rightedge, topedge, botedge]
     top_samples = [for(patch=top_patch) bezier_patch_degenerate(patch,splinesteps,reverse=false,return_edges=true) ],
     bot_samples = [for(patch=bot_patch) bezier_patch_degenerate(patch,splinesteps,reverse=true,return_edges=true) ],
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
     top_intersections = path_self_intersections(faces[0]),
     bot_intersections = path_self_intersections(faces[1]),
     // verify vertical edges
     verify_vert =
       [for(i=[0:N-1],j=[0:4])
         let(
               vline = concat(select(subindex(top_patch[i],j),2,4),
                              select(subindex(bot_patch[i],j),2,4))
             )
         if (!collinear(vline)) [i,j]],
     //verify horiz edges
     verify_horiz=[for(i=[0:N-1], j=[0:4])
         let(
             hline_top = concat(select(top_patch[i][j],2,4), select(select(top_patch, i+1)[j],0,2)),
             hline_bot = concat(select(bot_patch[i][j],2,4), select(select(bot_patch, i+1)[j],0,2))
         )
         if (!collinear(hline_top) || !collinear(hline_bot)) [i,j]]
    )
    assert(debug || top_intersections==[],
          "Roundovers interfere with each other on top face: either input is self intersecting or top joint length is too large")
    assert(debug || bot_intersections==[],
          "Roundovers interfere with each other on bottom face: either input is self intersecting or top joint length is too large")
    assert(debug || (verify_vert==[] && verify_horiz==[]), "Curvature continuity failed")
    let(
        vnf = vnf_merge([ each subindex(top_samples,0),
                          each subindex(bot_samples,0),
                          for(pts=edge_points) vnf_vertex_array(pts),
                          vnf_triangulate(vnf_add_faces(EMPTY_VNF,faces))
                       ])
    )
    debug ? [concat(top_patch, bot_patch), vnf] : vnf;



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
//   this will cause self-intersection in the mask polyhedron, resulting in CGAL failures.
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
//       bent_cutout_mask(10, 1.05, apply(xscale(3),circle(r=3)),$fn=64);
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
//       bent_cutout_mask(10, 1.05, apply(scale(3),supershape(step=2,m1=5, n1=0.3,n2=1.7)),$fn=32);
//     }
//   }
// Example: this shape is invalid due to self-intersections at the inner corners
//   rot(-90) {
//     $fn=128;
//     difference(){
//       cylinder(r=10.5, h=10,center=true);
//       cylinder(r=9.5, h=11,center=true);
//       bent_cutout_mask(10, 1.05, apply(scale(3),supershape(step=2,m1=5, n1=0.1,n2=1.7)),$fn=32);
//     }
//   }
// Example: increasing the step gives a valid shape, but the shape looks terrible with so few points.
//   rot(-90) {
//     $fn=128;
//     difference(){
//       cylinder(r=10.5, h=10,center=true);
//       cylinder(r=9.5, h=11,center=true);
//       bent_cutout_mask(10, 1.05, apply(scale(3),supershape(step=12,m1=5, n1=0.1,n2=1.7)),$fn=32);
//     }
//   }
// Example: uniform resampling produces a somewhat better result, but room remains for improvement.  The lesson is that concave corners in your cutout cause trouble.  To get a very good result we need to non-uniformly sample the supershape with more points at the star tips and few points at the inner corners.
//   rot(-90) {
//     $fn=128;
//     difference(){
//       cylinder(r=10.5, h=10,center=true);
//       cylinder(r=9.5, h=11,center=true);
//       bent_cutout_mask(10, 1.05, apply(scale(3),resample_path(supershape(step=1,m1=5, n1=0.10,n2=1.7),60,closed=true)),$fn=32);
//     }
//   }
// Example: The cutout spans 177 degrees.  If you decrease the tube radius to 2.5 the cutout spans over 180 degrees and the model fails.
//   r=2.6;     // Don't make this much smaller or it will fail
//   rot(-90) {
//     $fn=128;
//     difference(){
//       tube(or=r, wall=1, h=10, anchor=CENTER);
//       bent_cutout_mask(r-0.5, 1.05, apply(scale(3),supershape(step=1,m1=5, n1=0.15,n2=1.7)),$fn=32);
//     }
//   }
// Example: A square hole is not as simple as it seems.  The model valid, but wrong, because the square didn't have enough samples to follow the curvature of the cylinder.
//   r=25;
//   rot(-90) {
//     $fn=128;
//     difference(){
//       tube(or=r, wall=2, h=45);
//       bent_cutout_mask(r-1, 2.1, back(5,p=square([18,18])));
//     }
//   }
// Example: Adding additional points fixed this problem
//   r=25;
//   rot(-90) {
//     $fn=128;
//     difference(){
//       tube(or=r, wall=2, h=45);
//       bent_cutout_mask(r-1, 2.1, subdivide_path(back(5,p=square([18,18])),64,closed=true));
//     }
//   }
// Example: Rounding just the exterior corners of this star avoids the problems we had above with concave corners of the supershape, as long as we don't oversample the star.
//   r=25;
//   rot(-90) {
//     $fn=128;
//     difference(){
//       tube(or=r, wall=2, h=45);
//       bent_cutout_mask(r-1, 2.1, apply(back(15),subdivide_path(round_corners(star(n=7,ir=5,or=10), cut=flatten(repeat([0.5,0],7)),$fn=32),14*15,closed=true)));
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
//   ) apply(left(max(subindex(slot,0))/2)*fwd(min(subindex(slot,1))), slot);
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
//   ) apply(left(max(subindex(slot,0))/2)*fwd(min(subindex(slot,1))), slot);
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
  no_children($children);
  r = get_radius(r1=r, r2=radius);
  dummy=assert(is_def(r) && r>0,"Radius of the cylinder to bend around must be positive");
  assert(is_path(path,2),"Input path must be a 2d path");
  assert(r-thickness>0, "Thickness too large for radius");
  assert(thickness>0, "Thickness must be positive");
  path = clockwise_polygon(path);
  curvepoints = arc(d=thickness, angle = [-180,0]);
  profiles = [for(pt=curvepoints) _cyl_hole(r+pt.x,apply(xscale((r+pt.x)/r), offset(path,delta=thickness/2+pt.y,check_valid=false,closed=true)))];
  pathx = subindex(path,0);
  minangle = (min(pathx)-thickness/2)*360/(2*PI*r);
  maxangle = (max(pathx)+thickness/2)*360/(2*PI*r);
  mindist = (r+thickness/2)/cos((maxangle-minangle)/2);
  assert(maxangle-minangle<180,"Cutout angle span is too large.  Must be smaller than 180.");
  zmean = mean(subindex(path,1));
  innerzero = repeat([0,0,zmean], len(path));
  outerpt = repeat( [1.5*mindist*cos((maxangle+minangle)/2),1.5*mindist*sin((maxangle+minangle)/2),zmean], len(path));
  vnf_polyhedron(vnf_vertex_array([innerzero, each profiles, outerpt],col_wrap=true),convexity=convexity);
}


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
