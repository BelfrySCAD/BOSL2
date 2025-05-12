//////////////////////////////////////////////////////////////////////
// LibFile: beziers.scad
//   Bezier curves and surfaces are ways to represent smooth curves and smoothly curving
//   surfaces with a set of control points.  The curve or surface is defined by
//   the control points, but usually passes through only the first and last control point (the endpoints).
//   This file provides some
//   aids to constructing the control points, and highly optimized functions for
//   computing the Bezier curves and surfaces given by the control points, 
// Includes:
//   include <BOSL2/std.scad>
// FileGroup: Advanced Modeling
// FileSummary: Bezier curves and surfaces.
// FileFootnotes: STD=Included in std.scad
//////////////////////////////////////////////////////////////////////

// Terminology:
//   Path = A series of points joined by straight line segements.
//   Bezier Curve = A polynomial curve defined by a list of control points.  The curve starts at the first control point and ends at the last one.  The other control points define the shape of the curve and they are often *NOT* on the curve
//   Control Point = A point that influences the shape of the Bezier curve.
//   Degree = The degree of the polynomial used to make the bezier curve.  A bezier curve of degree N has N+1 control points.  Most beziers are cubic (degree 3).  The higher the degree, the more the curve can wiggle.  
//   Bezier Parameter = A parameter, usually `u` below, that ranges from 0 to 1 to trace out the bezier curve.  When `u=0` you get the first control point and when `u=1` you get the last control point. Intermediate points are traced out *non-uniformly*.  
//   Bezier Path = A list of bezier control points corresponding to a series of Bezier curves that connect together, end to end.  Because they connect, the endpoints are shared between control points and are not repeated, so a degree 3 bezier path representing two bezier curves has seven entries to represent two sets of four control points.    **NOTE:** A "bezier path" is *NOT* a standard path
//   Bezier Patch = A two-dimensional arrangement of Bezier control points that generate a bounded curved Bezier surface.  A Bezier patch is a (N+1) by (M+1) grid of control points, which defines surface with four edges (in the non-degenerate case). 
//   Bezier Surface = A surface defined by a list of one or more bezier patches.
//   Spline Steps = The number of straight-line segments used to approximate a Bezier curve.  The more spline steps, the better the approximation to the curve, but the slower it generates.  This plays a role analogous to `$fn` for circles.  Usually defaults to 16.


// Section: Bezier Curves

// Function: bezier_points()
// Synopsis: Computes one or more specified points along a bezier curve.
// SynTags: Path
// Topics: Bezier Curves
// See Also: bezier_curve(), bezier_curvature(), bezier_tangent(), bezier_derivative(), bezier_points()
// Usage:
//   pt = bezier_points(bezier, u);
//   ptlist = bezier_points(bezier, RANGE);
//   ptlist = bezier_points(bezier, LIST);
// Description:
//   Computes points on a bezier curve with control points specified by `bezier` at parameter values
//   specified by `u`, which can be a scalar or a list.  The value `u=0` gives the first endpoint; `u=1` gives the final endpoint,
//   and intermediate values of `u` fill in the curve in a non-uniform fashion.  This function uses an optimized method that
//   works best when `u` is a long list and the bezier degree is 10 or less.  The degree of the bezier
//   curve is `len(bezier)-1`.
//   .
//   Note that if you have a bezier **path** (see below) then you should use {{bezpath_points()}} to
//   evaluate the points on that bezier path.  This function is for a single bezier.  
// Arguments:
//   bezier = The list of endpoints and control points for this bezier curve.
//   u = Parameter values for evaluating the curve, given as a single value, a list or a range.  
// Example(2D): Quadratic (Degree 2) Bezier.
//   bez = [[0,0], [30,30], [80,0]];
//   debug_bezier(bez, N=len(bez)-1);
//   translate(bezier_points(bez, 0.3)) color("red") sphere(1);
// Example(2D): Cubic (Degree 3) Bezier
//   bez = [[0,0], [5,35], [60,-25], [80,0]];
//   debug_bezier(bez, N=len(bez)-1);
//   translate(bezier_points(bez, 0.4)) color("red") sphere(1);
// Example(2D): Degree 4 Bezier.
//   bez = [[0,0], [5,15], [40,20], [60,-15], [80,0]];
//   debug_bezier(bez, N=len(bez)-1);
//   translate(bezier_points(bez, 0.8)) color("red") sphere(1);
// Example(2D): Giving a List of `u`
//   bez = [[0,0], [5,35], [60,-25], [80,0]];
//   debug_bezier(bez, N=len(bez)-1);
//   pts = bezier_points(bez, [0, 0.2, 0.3, 0.7, 0.8, 1]);
//   rainbow(pts) move($item) sphere(1.5, $fn=12);
// Example(2D): Giving a Range of `u`
//   bez = [[0,0], [5,35], [60,-25], [80,0]];
//   debug_bezier(bez, N=len(bez)-1);
//   pts = bezier_points(bez, [0:0.2:1]);
//   rainbow(pts) move($item) sphere(1.5, $fn=12);

// Ugly but speed optimized code for computing bezier curves using the matrix representation
// See https://pomax.github.io/bezierinfo/#matrix for explanation.
//
// All of the loop unrolling makes and the use of the matrix lookup table make a big difference
// in the speed of execution.  For orders 10 and below this code is 10-20 times faster than
// the recursive code using the de Casteljau method depending on the bezier order and the
// number of points evaluated in one call (more points is faster).  For orders 11 and above without the
// lookup table or hard coded powers list the code is about twice as fast as the recursive method.
// Note that everything I tried to simplify or tidy this code made is slower, sometimes a lot slower.
function bezier_points(curve, u) =
    is_num(u) ? bezier_points(curve,[u])[0] :
    let(
        N = len(curve)-1,
        M = _bezier_matrix(N)*curve
    )
    N==0 ? [for(uval=u)[1]*M] :
    N==1 ? [for(uval=u)[1, uval]*M] :
    N==2 ? [for(uval=u)[1, uval, uval^2]*M] :
    N==3 ? [for(uval=u)[1, uval, uval^2, uval^3]*M] :          
    N==4 ? [for(uval=u)[1, uval, uval^2, uval^3, uval^4]*M] :
    N==5 ? [for(uval=u)[1, uval, uval^2, uval^3, uval^4, uval^5]*M] :
    N==6 ? [for(uval=u)[1, uval, uval^2, uval^3, uval^4, uval^5,uval^6]*M] :
    N==7 ? [for(uval=u)[1, uval, uval^2, uval^3, uval^4, uval^5,uval^6, uval^7]*M] :
    N==8 ? [for(uval=u)[1, uval, uval^2, uval^3, uval^4, uval^5,uval^6, uval^7, uval^8]*M] :
    N==9 ? [for(uval=u)[1, uval, uval^2, uval^3, uval^4, uval^5,uval^6, uval^7, uval^8, uval^9]*M] :
    N==10? [for(uval=u)[1, uval, uval^2, uval^3, uval^4, uval^5,uval^6, uval^7, uval^8, uval^9, uval^10]*M] :
    /* N>=11 */  [for(uval=u)[for (i=[0:1:N]) uval^i]*M];


// Not public.
function _signed_pascals_triangle(N,tri=[[-1]]) =
    len(tri)==N+1 ? tri :
    let(last=tri[len(tri)-1])
    _signed_pascals_triangle(N,concat(tri,[[-1, for(i=[0:1:len(tri)-2]) (i%2==1?-1:1)*(abs(last[i])+abs(last[i+1])),len(last)%2==0? -1:1]]));


// Not public.
function _compute_bezier_matrix(N) =
    let(tri = _signed_pascals_triangle(N))
    [for(i=[0:N]) concat(tri[N][i]*tri[i], repeat(0,N-i))];


// The bezier matrix, which is related to Pascal's triangle, enables nonrecursive computation
// of bezier points.  This method is much faster than the recursive de Casteljau method
// in OpenScad, but we have to precompute the matrices to reap the full benefit.

// Not public.
_bezier_matrix_table = [
    [[1]],
    [[ 1, 0],
     [-1, 1]],
    [[1, 0, 0],
     [-2, 2, 0],
     [1, -2, 1]],
    [[ 1, 0, 0, 0],
     [-3, 3, 0, 0],
     [ 3,-6, 3, 0],
     [-1, 3,-3, 1]],
    [[ 1,  0,  0, 0, 0],
     [-4,  4,  0, 0, 0],
     [ 6,-12,  6, 0, 0],
     [-4, 12,-12, 4, 0],
     [ 1, -4,  6,-4, 1]],
    [[  1,  0, 0,   0, 0, 0],
     [ -5,  5, 0,   0, 0, 0],
     [ 10,-20, 10,  0, 0, 0],
     [-10, 30,-30, 10, 0, 0],
     [  5,-20, 30,-20, 5, 0],
     [ -1,  5,-10, 10,-5, 1]],
    [[  1,  0,  0,  0,  0, 0, 0],
     [ -6,  6,  0,  0,  0, 0, 0],
     [ 15,-30, 15,  0,  0, 0, 0],
     [-20, 60,-60, 20,  0, 0, 0],
     [ 15,-60, 90,-60, 15, 0, 0],
     [ -6, 30,-60, 60,-30, 6, 0],
     [  1, -6, 15,-20, 15,-6, 1]],
    [[  1,   0,   0,   0,  0,   0, 0, 0],
     [ -7,   7,   0,   0,  0,   0, 0, 0],
     [ 21, -42,  21,   0,  0,   0, 0, 0],
     [-35, 105,-105,  35,  0,   0, 0, 0],
     [ 35,-140, 210,-140,  35,  0, 0, 0],
     [-21, 105,-210, 210,-105, 21, 0, 0],
     [  7, -42, 105,-140, 105,-42, 7, 0],
     [ -1,   7, -21,  35, -35, 21,-7, 1]],
    [[  1,   0,   0,   0,   0,   0,  0, 0, 0],
     [ -8,   8,   0,   0,   0,   0,  0, 0, 0],
     [ 28, -56,  28,   0,   0,   0,  0, 0, 0],
     [-56, 168,-168,  56,   0,   0,  0, 0, 0],
     [ 70,-280, 420,-280,  70,   0,  0, 0, 0],
     [-56, 280,-560, 560,-280,  56,  0, 0, 0],
     [ 28,-168, 420,-560, 420,-168, 28, 0, 0],
     [ -8,  56,-168, 280,-280, 168,-56, 8, 0],
     [  1,  -8,  28, -56,  70, -56, 28,-8, 1]],
    [[1, 0, 0, 0, 0, 0, 0,  0, 0, 0], [-9, 9, 0, 0, 0, 0, 0, 0, 0, 0], [36, -72, 36, 0, 0, 0, 0, 0, 0, 0], [-84, 252, -252, 84, 0, 0, 0, 0, 0, 0],
     [126, -504, 756, -504, 126, 0, 0, 0, 0, 0], [-126, 630, -1260, 1260, -630, 126, 0, 0, 0, 0], [84, -504, 1260, -1680, 1260, -504, 84, 0, 0, 0],
     [-36, 252, -756, 1260, -1260, 756, -252, 36, 0, 0], [9, -72, 252, -504, 630, -504, 252, -72, 9, 0], [-1, 9, -36, 84, -126, 126, -84, 36, -9, 1]],
    [[1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [-10, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0], [45, -90, 45, 0, 0, 0, 0, 0, 0, 0, 0], [-120, 360, -360, 120, 0, 0, 0, 0, 0, 0, 0],
     [210, -840, 1260, -840, 210, 0, 0, 0, 0, 0, 0], [-252, 1260, -2520, 2520, -1260, 252, 0, 0, 0, 0, 0],
     [210, -1260, 3150, -4200, 3150, -1260, 210, 0, 0, 0, 0], [-120, 840, -2520, 4200, -4200, 2520, -840, 120, 0, 0, 0],
     [45, -360, 1260, -2520, 3150, -2520, 1260, -360, 45, 0, 0], [-10, 90, -360, 840, -1260, 1260, -840, 360, -90, 10, 0],
     [1, -10, 45, -120, 210, -252, 210, -120, 45, -10, 1]]
];


// Not public.
function _bezier_matrix(N) =
    N>10 ? _compute_bezier_matrix(N) :
    _bezier_matrix_table[N];


// Function: bezier_curve()
// Synopsis: Computes a specified number of points on a bezier curve.
// SynTags: Path
// Topics: Bezier Curves
// See Also: bezier_curve(), bezier_curvature(), bezier_tangent(), bezier_derivative(), bezier_points()
// Usage:
//   path = bezier_curve(bezier, [splinesteps], [endpoint]);
// Description:
//   Takes a list of bezier control points and generates splinesteps segments (splinesteps+1 points)
//   along the bezier curve they define.
//   Points start at the first control point and are sampled uniformly along the bezier parameter.
//   The endpoints of the output are *exactly* equal to the first and last bezier control points
//   when endpoint is true.  If endpoint is false the sampling stops one step before the final point
//   of the bezier curve, but you still get the same number of (more tightly spaced) points.  
//   The distance between the points are *not* equidistant.  
//   The degree of the bezier curve is one less than the number of points in `curve`.
//   .
//   Note that if you have a bezier **path** (see below) then you should use {{bezpath_curve()}} to
//   evaluate the that bezier path.  This function is for a single bezier.  
// Arguments:
//   bezier = The list of control points that define the Bezier curve. 
//   splinesteps = The number of segments to create on the bezier curve.  Default: 16
//   endpoint = if false then exclude the endpoint.  Default: True
// Example(2D): Quadratic (Degree 2) Bezier.
//   bez = [[0,0], [30,30], [80,0]];
//   move_copies(bezier_curve(bez, 8)) sphere(r=1.5, $fn=12);
//   debug_bezier(bez, N=len(bez)-1);
// Example(2D): Cubic (Degree 3) Bezier
//   bez = [[0,0], [5,35], [60,-25], [80,0]];
//   move_copies(bezier_curve(bez, 8)) sphere(r=1.5, $fn=12);
//   debug_bezier(bez, N=len(bez)-1);
// Example(2D): Degree 4 Bezier.
//   bez = [[0,0], [5,15], [40,20], [60,-15], [80,0]];
//   move_copies(bezier_curve(bez, 8)) sphere(r=1.5, $fn=12);
//   debug_bezier(bez, N=len(bez)-1);
function bezier_curve(bezier,splinesteps=16,endpoint=true) =
    bezier_points(bezier, lerpn(0,1,splinesteps+1,endpoint));


// Function: bezier_derivative()
// Synopsis: Evaluates the derivative of the bezier curve at the given point or points.
// Topics: Bezier Curves
// See Also: bezier_curvature(), bezier_tangent(), bezier_points()
// Usage:
//   deriv = bezier_derivative(bezier, u, [order]);
//   derivs = bezier_derivative(bezier, LIST, [order]);
//   derivs = bezier_derivative(bezier, RANGE, [order]);
// Description:
//   Evaluates the derivative of the bezier curve at the given parameter value or values, `u`.  The `order` gives the order of the derivative. 
//   The degree of the bezier curve is one less than the number of points in `bezier`.
// Arguments:
//   bezier = The list of control points that define the Bezier curve. 
//   u = Parameter values for evaluating the curve, given as a single value, a list or a range.
//   order = The order of the derivative to return.  Default: 1 (for the first derivative)
function bezier_derivative(bezier, u, order=1) =
    assert(is_int(order) && order>=0)
    order==0? bezier_points(bezier, u) : let(
        N = len(bezier) - 1,
        dpts = N * deltas(bezier)
    ) order==1? bezier_points(dpts, u) :
    bezier_derivative(dpts, u, order-1);



// Function: bezier_tangent()
// Synopsis: Calculates unit tangent vectors along the bezier curve at one or more given positions.
// Topics: Bezier Curves
// See Also: bezier_curvature(), bezier_derivative(), bezier_points()
// Usage:
//   tanvec = bezier_tangent(bezier, u);
//   tanvecs = bezier_tangent(bezier, LIST);
//   tanvecs = bezier_tangent(bezier, RANGE);
// Description:
//   Returns the unit tangent vector at the given parameter values on a bezier curve with control points `bezier`.
// Arguments:
//   bezier = The list of control points that define the Bezier curve. 
//   u = Parameter values for evaluating the curve, given as a single value, a list or a range.
function bezier_tangent(bezier, u) =
    let(
        res = bezier_derivative(bezier, u)
    ) is_vector(res)? unit(res) :
    [for (v=res) unit(v)];



// Function: bezier_curvature()
// Synopsis: Returns the curvature at one or more given positions along a bezier curve.
// Topics: Bezier Curves
// See Also: bezier_tangent(), bezier_derivative(), bezier_points()
// Usage:
//   crv = bezier_curvature(curve, u);
//   crvlist = bezier_curvature(curve, LIST);
//   crvlist = bezier_curvature(curve, RANGE);
// Description:
//   Returns the curvature value for the given parameters `u` on the bezier curve with control points `bezier`. 
//   The curvature is the inverse of the radius of the tangent circle at the given point.
//   Thus, the tighter the curve, the larger the curvature value.  Curvature is 0 for
//   a position with no curvature, since 1/0 is not a number.
// Arguments:
//   bezier = The list of control points that define the Bezier curve.
//   u = Parameter values for evaluating the curve, given as a single value, a list or a range.
function bezier_curvature(bezier, u) =
    is_num(u) ? bezier_curvature(bezier,[u])[0] :
    let(
        d1 = bezier_derivative(bezier, u, 1),
        d2 = bezier_derivative(bezier, u, 2)
    ) [
        for(i=idx(d1))
        sqrt(
            sqr(norm(d1[i])*norm(d2[i])) -
            sqr(d1[i]*d2[i])
        ) / pow(norm(d1[i]),3)
    ];



// Function: bezier_closest_point()
// Synopsis: Finds the closest position on a bezier curve to a given point.
// Topics: Bezier Curves
// See Also: bezier_points()
// Usage:
//   u = bezier_closest_point(bezier, pt, [max_err]);
// Description:
//   Finds the closest part of the given bezier curve to point `pt`.
//   The degree of the curve, N, is one less than the number of points in `curve`.
//   Returns `u` for the closest position on the bezier curve to the given point `pt`.
// Arguments:
//   bezier = The list of control points that define the Bezier curve. 
//   pt = The point to find the closest curve point to.
//   max_err = The maximum allowed error when approximating the closest approach.
// Example(2D):
//   pt = [40,15];
//   bez = [[0,0], [20,40], [60,-25], [80,0]];
//   u = bezier_closest_point(bez, pt);
//   debug_bezier(bez, N=len(bez)-1);
//   color("red") translate(pt) sphere(r=1);
//   color("blue") translate(bezier_points(bez,u)) sphere(r=1);
function bezier_closest_point(bezier, pt, max_err=0.01, u=0, end_u=1) =
    let(
        steps = len(bezier)*3,
        uvals = [u, for (i=[0:1:steps]) (end_u-u)*(i/steps)+u, end_u],
        path = bezier_points(bezier,uvals),
        minima_ranges = [
            for (i = [1:1:len(uvals)-2]) let(
                d1 = norm(path[i-1]-pt),
                d2 = norm(path[i  ]-pt),
                d3 = norm(path[i+1]-pt)
            ) if (d2<=d1 && d2<=d3) [uvals[i-1],uvals[i+1]]
        ]
    ) len(minima_ranges)>1? (
        let(
            min_us = [
                for (minima = minima_ranges)
                    bezier_closest_point(bezier, pt, max_err=max_err, u=minima.x, end_u=minima.y)
            ],
            dists = [for (v=min_us) norm(bezier_points(bezier,v)-pt)],
            min_i = min_index(dists)
        ) min_us[min_i]
    ) : let(
        minima = minima_ranges[0],
        pp = bezier_points(bezier, minima),
        err = norm(pp[1]-pp[0])
    ) err<max_err? mean(minima) :
    bezier_closest_point(bezier, pt, max_err=max_err, u=minima[0], end_u=minima[1]);


// Function: bezier_length()
// Synopsis: Approximate the length of part of a bezier curve.
// Topics: Bezier Curves
// See Also: bezier_points()
// Usage:
//   pathlen = bezier_length(bezier, [start_u], [end_u], [max_deflect]);
// Description:
//   Approximates the length of the portion of the bezier curve between start_u and end_u.
// Arguments:
//   bezier = The list of control points that define the Bezier curve. 
//   start_u = The Bezier parameter to start measuring measuring from.  Between 0 and 1.
//   end_u = The Bezier parameter to end measuring at.  Between 0 and 1.  Greater than start_u.
//   max_deflect = The largest amount of deflection from the true curve to allow for approximation.
// Example:
//   bez = [[0,0], [5,35], [60,-25], [80,0]];
//   echo(bezier_length(bez));
function bezier_length(bezier, start_u=0, end_u=1, max_deflect=0.01) =
    let(
        segs = len(bezier) * 2,
        uvals = lerpn(start_u, end_u, segs+1),
        path = bezier_points(bezier,uvals),
        defl = max([
            for (i=idx(path,e=-3)) let(
                mp = (path[i] + path[i+2]) / 2
            ) norm(path[i+1] - mp)
        ]),
        mid_u = lerp(start_u, end_u, 0.5)
    )
    defl <= max_deflect? path_length(path) :
    sum([
        for (i=[0:1:segs-1]) let(
            su = lerp(start_u, end_u, i/segs),
            eu = lerp(start_u, end_u, (i+1)/segs)
        ) bezier_length(bezier, su, eu, max_deflect)
    ]);



// Function: bezier_line_intersection()
// Synopsis: Calculates where a bezier curve intersects a line.
// Topics: Bezier Curves, Geometry, Intersection
// See Also: bezier_points(), bezier_length(), bezier_closest_point()
// Usage: 
//   u = bezier_line_intersection(bezier, line);
// Description:
//   Finds the intersection points of the 2D Bezier curve with control points `bezier` and the given line, specified as a pair of points.  
//   Returns the intersection as a list of `u` values for the Bezier.  
// Arguments:
//   bezier = The list of control points that define a 2D Bezier curve. 
//   line = a list of two distinct 2d points defining a line
function bezier_line_intersection(bezier, line) =
    assert(is_path(bezier,2), "\nThe input 'bezier' must be a 2d bezier.")
    assert(_valid_line(line,2), "\nThe input 'line' is not a valid 2d line.")
    let( 
        a = _bezier_matrix(len(bezier)-1)*bezier, // bezier algebraic coeffs. 
        n = [-line[1].y+line[0].y, line[1].x-line[0].x], // line normal
        q = [for(i=[len(a)-1:-1:1]) a[i]*n, (a[0]-line[0])*n] // bezier SDF to line
    )
    [for(u=real_roots(q)) if (u>=0 && u<=1) u];




// Section: Bezier Path Functions
//   To contruct more complicated curves you can connect a sequence of Bezier curves end to end.  
//   A Bezier path is a flattened list of control points that, along with the degree, represents such a sequence of bezier curves where all of the curves have the same degree.
//   A Bezier path looks like a regular path, since it is just a list of points, but it is not a regular path.  Use {{bezpath_curve()}} to convert a Bezier path to a regular path.
//   We interpret a degree N Bezier path as groups of N+1 control points that
//   share endpoints, so they overlap by one point.  So if you have an order 3 bezier path `[p0,p1,p2,p3,p4,p5,p6]` then the first
//   Bezier curve control point set is `[p0,p1,p2,p3]` and the second one is `[p3,p4,p5,p6]`.  The endpoint, `p3`, is shared between the control point sets.
//   The Bezier degree, which must be known to interpret the Bezier path, defaults to 3. 


// Function: bezpath_points()
// Synopsis: Computes one or more specified points along a bezier path.
// SynTags: Path
// Topics: Bezier Paths
// See Also: bezier_points(), bezier_curve()
// Usage:
//   pt = bezpath_points(bezpath, curveind, u, [N]);
//   ptlist = bezpath_points(bezpath, curveind, LIST, [N]);
//   path = bezpath_points(bezpath, curveind, RANGE, [N]);
// Description:
//   Extracts from the Bezier path `bezpath` the control points for the Bezier curve whose index is `curveind` and
//   computes the point or points on the corresponding Bezier curve specified by `u`.  If `curveind` is zero you
//   get the first curve.  The number of curves is `(len(bezpath)-1)/N` so the maximum index is that number minus one.  
// Arguments:
//   bezpath = A Bezier path path to approximate.
//   curveind = Curve number along the path.  
//   u = Parameter values for evaluating the curve, given as a single value, a list or a range.
//   N = The degree of the Bezier path curves.  Default: 3
function bezpath_points(bezpath, curveind, u, N=3) =
    bezier_points(select(bezpath,curveind*N,(curveind+1)*N), u);


// Function: bezpath_curve()
// Synopsis: Converts bezier path into a path of points. 
// SynTags: Path
// Topics: Bezier Paths
// See Also: bezier_points(), bezier_curve(), bezpath_points()
// Usage:
//   path = bezpath_curve(bezpath, [splinesteps], [N], [endpoint])
// Description:
//   Computes a number of uniformly distributed points along a bezier path.
// Arguments:
//   bezpath = A bezier path to approximate.
//   splinesteps = Number of straight lines to split each bezier curve into. default=16
//   N = The degree of the bezier curves.  Cubic beziers have N=3.  Default: 3
//   endpoint = If true, include the last point of the bezier path.  Default: true
// Example(2D):
//   bez = [
//       [0,0], [-5,30],
//       [20,60], [50,50], [110,30],
//       [60,25], [70,0], [80,-25],
//       [80,-50], [50,-50]
//   ];
//   path = bezpath_curve(bez);
//   stroke(path,dots=true,dots_color="red");
function bezpath_curve(bezpath, splinesteps=16, N=3, endpoint=true) =
    assert(is_path(bezpath))
    assert(is_int(N))
    assert(is_int(splinesteps) && splinesteps>0)
    assert(len(bezpath)%N == 1, str("\nA degree ",N," bezier path should have a multiple of ",N," points in it, plus 1."))
    let(
        segs = (len(bezpath)-1) / N,
        step = 1 / splinesteps,
        path = [
            for (seg = [0:1:segs-1])
                each bezier_points(select(bezpath, seg*N, (seg+1)*N), [0:step:1-step/2]),
            if (endpoint) last(bezpath)
        ],
        is_closed = approx(path[0], last(path)),
        out = path_merge_collinear(path, closed=is_closed)
    ) out;


// Function: bezpath_closest_point()
// Synopsis: Finds the closest point on a bezier path to a given point.
// Topics: Bezier Paths
// See Also: bezpath_points(), bezpath_curve(), bezier_points(), bezier_curve(), bezier_closest_point()
// Usage:
//   res = bezpath_closest_point(bezpath, pt, [N], [max_err]);
// Description:
//   Finds an approximation to the closest part of the given bezier path to point `pt`.
//   Returns [segnum, u] for the closest position on the bezier path to the given point `pt`.
// Arguments:
//   bezpath = A bezier path to approximate.
//   pt = The point to find the closest curve point to.
//   N = The degree of the bezier curves.  Cubic beziers have N=3.  Default: 3
//   max_err = The maximum allowed error when approximating the closest approach.
// Example(2D):
//   pt = [100,0];
//   bez = [[0,0], [20,40], [60,-25], [80,0],
//          [100,25], [140,25], [160,0]];
//   pos = bezpath_closest_point(bez, pt);
//   xy = bezpath_points(bez,pos[0],pos[1]);
//   debug_bezier(bez, N=3);
//   color("red") translate(pt) sphere(r=1);
//   color("blue") translate(xy) sphere(r=1);
function bezpath_closest_point(bezpath, pt, N=3, max_err=0.01, seg=0, min_seg=undef, min_u=undef, min_dist=undef) =
    assert(is_vector(pt))
    assert(is_int(N))
    assert(is_num(max_err))
    assert(len(bezpath)%N == 1, str("\nA degree ",N," bezier path should have a multiple of ",N," points in it, plus 1."))
    let(curve = select(bezpath,seg*N,(seg+1)*N))
    (seg*N+1 >= len(bezpath))? (
        let(curve = select(bezpath, min_seg*N, (min_seg+1)*N))
        [min_seg, bezier_closest_point(curve, pt, max_err=max_err)]
    ) : (
        let(
            curve = select(bezpath,seg*N,(seg+1)*N),
            u = bezier_closest_point(curve, pt, max_err=0.05),
            dist = norm(bezier_points(curve, u)-pt),
            mseg = (min_dist==undef || dist<min_dist)? seg : min_seg,
            mdist = (min_dist==undef || dist<min_dist)? dist : min_dist,
            mu = (min_dist==undef || dist<min_dist)? u : min_u
        )
        bezpath_closest_point(bezpath, pt, N, max_err, seg+1, mseg, mu, mdist)
    );



// Function: bezpath_length()
// Synopsis: Approximate the length of a bezier path.
// Topics: Bezier Paths
// See Also: bezier_points(), bezier_curve(), bezier_length()
// Usage:
//   plen = bezpath_length(path, [N], [max_deflect]);
// Description:
//   Approximates the length of the bezier path.
// Arguments:
//   path = A bezier path to approximate.
//   N = The degree of the bezier curves.  Cubic beziers have N=3.  Default: 3
//   max_deflect = The largest amount of deflection from the true curve to allow for approximation.
function bezpath_length(bezpath, N=3, max_deflect=0.001) =
    assert(is_int(N))
    assert(is_num(max_deflect))
    assert(len(bezpath)%N == 1, str("\nA degree ",N," bezier path should have a multiple of ",N," points in it, plus 1."))
    sum([
        for (seg=[0:1:(len(bezpath)-1)/N-1]) (
            bezier_length(
                select(bezpath, seg*N, (seg+1)*N),
                max_deflect=max_deflect
            )
        )
    ]);



// Function: path_to_bezpath()
// Synopsis: Generates a bezier path that passes through all points in a given linear path.
// SynTags: Path
// Topics: Bezier Paths, Rounding
// See Also: path_tangents()
// Usage:
//   bezpath = path_to_bezpath(path, [closed], [tangents], [uniform], [size=]|[relsize=]);
// Description:
//   Given a 2d or 3d input path and optional list of tangent vectors, computes a cubic (degree 3) bezier
//   path that passes through every point on the input path and matches the tangent vectors. If you do not
//   supply the tangents then they are computed using `path_tangents()` with `uniform=false` by default.
//   Only the direction of the tangent vectors matter, not their magnitudes.
//   If the path is closed, specify this by setting `closed=true`.
//   The `size` or `relsize` parameter determines how far the curve can deviate from
//   the input path.  In the case where the curve has a single hump, the size specifies the exact distance
//   between the specified path and the bezier.  If you give relsize then it is relative to the segment
//   length (e.g. 0.05 means 5% of the segment length).  In 2d when the bezier curve makes an S-curve
//   the size parameter specifies the sum of the deviations of the two peaks of the curve.  In 3-space
//   the bezier curve may have three extrema: two maxima and one minimum.  In this case the size specifies
//   the sum of the maxima minus the minimum. Tangents computed on non-uniform data tend
//   to display overshoots.  See `smooth_path()` for examples.
// Arguments:
//   path = 2D or 3D point list or 1-region that the curve must pass through
//   closed = true if the curve is closed .  Default: false
//   tangents = tangents constraining curve direction at each point
//   uniform = set to true to compute tangents with uniform=true.  Default: false
//   ---
//   size = absolute size specification for the curve, a number or vector
//   relsize = relative size specification for the curve, a number or vector.  Default: 0.1. 
function path_to_bezpath(path, closed, tangents, uniform=false, size, relsize) =
    is_1region(path) ? path_to_bezpath(path[0], default(closed,true), tangents, uniform, size, relsize) :
    let(closed=default(closed,false))
    assert(is_bool(closed))
    assert(is_bool(uniform))
    assert(num_defined([size,relsize])<=1, "\nCan't define both size and relsize.")
    assert(is_path(path,[2,3]),"\nInput path is not a valid 2d or 3d path.")
    assert(is_undef(tangents) || is_path(tangents,[2,3]),"\nTangents must be a 2d or 3d path.")
    assert(is_undef(tangents) || len(path)==len(tangents), "\nInput tangents must be the same length as the input path.")
    let(
        curvesize = first_defined([size,relsize,0.1]),
        relative = is_undef(size),
        lastpt = len(path) - (closed?0:1)
    )
    assert(is_num(curvesize) || len(curvesize)==lastpt, str("\nSize or relsize must have length ",lastpt,"."))
    let(
        sizevect = is_num(curvesize) ? repeat(curvesize, lastpt) : curvesize,
        tangents = is_def(tangents) ? [for(t=tangents) let(n=norm(t)) assert(!approx(n,0),"\nZero tangent vector.") t/n] :
                                      path_tangents(path, uniform=uniform, closed=closed)
    )
    assert(min(sizevect)>0, "\nSize and relsize must be greater than zero.")
    [
        for(i=[0:1:lastpt-1])
            let(
                first = path[i],
                second = select(path,i+1),
                seglength = norm(second-first),
                dummy = assert(seglength>0, str("\nPath segment has zero length from index ",i," to ",i+1,".")),
                segdir = (second-first)/seglength,
                tangent1 = tangents[i],
                tangent2 = -select(tangents,i+1),                        // Need this to point backward, in direction of the curve
                parallel = abs(tangent1*segdir) + abs(tangent2*segdir), // Total component of tangents parallel to the segment
                Lmax = seglength/parallel,    // May be infinity
                size = relative ? sizevect[i]*seglength : sizevect[i],
                normal1 = tangent1-(tangent1*segdir)*segdir,   // Components of the tangents orthogonal to the segment
                normal2 = tangent2-(tangent2*segdir)*segdir,
                p = [ [-3 ,6,-3 ],                   // polynomial in power form
                      [ 7,-9, 2 ],
                      [-5, 3, 0 ],
                      [ 1, 0, 0 ] ]*[normal1*normal1, normal1*normal2, normal2*normal2],
                uextreme = approx(norm(p),0) ? []
                                             : [for(root = real_roots(p)) if (root>0 && root<1) root],
                distlist = [for(d=bezier_points([normal1*0, normal1, normal2, normal2*0], uextreme)) norm(d)],
                scale = len(distlist)==0 ? 0 :
                        len(distlist)==1 ? distlist[0]
                                         : sum(distlist) - 2*min(distlist),
                Ldesired = size/scale,   // This is infinity when the polynomial is zero
                L = min(Lmax, Ldesired)
            )
            each [
                  first, 
                  first + L*tangent1,
                  second + L*tangent2 
                 ],
        select(path,lastpt)
    ];



/// Function: path_to_bezcornerpath()
/// Synopsis: Generates a bezier path tangent to all midpoints of the path segments, deviating from the corners by a specified amount or proportion.
/// SynTags: Path
/// Topics: Bezier Paths, Rounding
/// See Also: path_to_bezpath()
/// Usage:
///   bezpath = path_to_bezcornerpath(path, [closed], [size=]|[relsize=]);
/// Description:
///   Given a 2d or 3d input path, computes a cubic (degree 3) bezier path passing through, and tangent to,
///   every segment midpoint on the input path and deviating from the corners by a specified amount.
///   If the path is closed, specify this by setting `closed=true`.
///   The `size` or `relsize` parameter determines how far the curve can deviate from
///   the corners of the input path. The `size` parameter specifies the exact distance
///   between the specified path and the corner.  If you give a `relsize` between 0 and 1, then it is
///   relative to the maximum distance from the corner that would produce a circular rounding, with 0 being
///   the actual corner and 1 being the circular rounding from the midpoint of the shortest leg of the corner.
///   For example, `relsize=0.25` means the "corner" of the rounded path is 25% of the distance from the path
///   corner to the theoretical circular rounding.
///   See `smooth_path()` for examples.
/// Arguments:
///   path = 2D or 3D point list or 1-region that the curve must pass through
///   closed = true if the curve is closed .  Default: false
///   ---
///   size = absolute curve deviation from the corners, a number or vector
///   relsize = relative curve deviation (between 0 and 1) from the corners, a number or vector. Default: 0.5. 
function path_to_bezcornerpath(path, closed, size, relsize) =
    is_1region(path) ? path_to_bezcornerpath(path[0], default(closed,true), tangents, size, relsize) :
    let(closed=default(closed,false))
        assert(is_bool(closed))
        assert(num_defined([size,relsize])<=1, "\nCan't define both size and relsize.")
        assert(is_path(path,[2,3]),"\nInput path is not a valid 2d or 3d path.")
        let(
            curvesize = first_defined([size,relsize,0.5]),
            relative = is_undef(size),
            pathlen = len(path)
        )
        assert(is_num(curvesize) || len(curvesize)==pathlen, str("\nSize or relsize must have length ",pathlen,"."))
        let(sizevect = is_num(curvesize) ? repeat(curvesize, pathlen) : curvesize)
            assert(min(sizevect)>0, "\nSize or relsize must be greater than zero.")
        let(
            roundpath = closed ? [
            for(i=[0:pathlen-1]) let(p3=select(path,[i-1:i+1]))
                _bez_path_corner([0.5*(p3[0]+p3[1]), p3[1], 0.5*(p3[1]+p3[2])], sizevect[i], relative),
            [0.5*(path[0]+path[pathlen-1])]
        ]
        : [ for(i=[1:pathlen-2]) let(p3=select(path,[i-1:i+1]))
            _bez_path_corner(
                [i>1?0.5*(p3[0]+p3[1]):p3[0], p3[1], i<pathlen-2?0.5*(p3[1]+p3[2]):p3[2]],
                sizevect[i], relative),
            [path[pathlen-1]]
        ]
    )
    flatten(roundpath);


/// Internal function: _bez_path_corner()
/// Usage:
///   _bez_path_corner(three_point_path, curvesize, relative);
/// Description:
///   Used by path_to_bezcornerpath()
///   Given a path with three points [p1, p2, p3] (2D or 3D), return a bezier path (minus the last control point) that creates a curve from p1 to p3.
///   The curvesize (roundness or inverse sharpness) parameter determines how close to a perfect circle (curvesize=1) or the p2 corner (curvesize=0) the path is, coming from the shortest leg. The longer leg path is stretched appropriately.
///   The error in using a cubic bezier curve to approximate a circular arc is about 0.00026 for a unit circle, with zero error at the endpoint and the corner bisector.
/// Arguments:
///   p = List of 3 points [p1, p2, p3]. The points may be 2D or 3D.
///   curvesize = curve is circular (curvesize=1) or sharp to the corner (curvesize=0) or anywhere in between
///   relative = if true, curvesize is a proportion between 0 and 1. If false, curvesize is an absolute distance that gets converted to a proportion internally.
function _bez_path_corner(p, curvesize, relative, mincurvesize=0.001) =
is_collinear(p)
? lerpn(p[0], lerp(p[0],p[2],5/6), 6)
: let(
    p1 = p[0], p2 = p[1], p3 = p[2],
    a0 = 0.5*vector_angle(p1, p2, p3),
    d1 = norm(p1-p2),
    d3 = norm(p3-p2),
    tana = tan(a0),
    rmin = min(d1, d3) * tana,
    rmax = max(d1, d3) * tana,
    // A "perfect" unit circle quadrant constructed from cubic bezier points [1,0], [1,d], [d,1], [0,1], with d=0.55228474983 has exact radius=1 at 0°, 45°, and 90°, with a maximum radius (at 22.5° and 67.5°) of 1.00026163152; nearly a perfect circle arc.
    fleg = let(a2=a0*a0)
    // model of "perfect" circle leg lengths for a bezier unit circle arc depending on arc angle a0; the model error is ~1e-5
        -4.4015E-08 * a2*a0 // tiny term, but reduces error by an order of magnitude
        +0.0000113366 * a2
        -0.00680018 * a0
        +0.552244,
    leglenmin = rmin * fleg,
    leglenmax = rmax * fleg,
    cp = circle_2tangents(rmin, p1, p2, p3)[0], // circle center
    middir = unit(cp-p2), // unit vector from corner pointing to circle center
    bzmid = cp - rmin*middir, // location of bezier point joining both halves of curve
    maxcut = norm(bzmid-p2), // maximum possible distance from corner to curve
    roundness = max(mincurvesize, relative ? curvesize : min(1, curvesize/maxcut)),
    bzdist = maxcut * roundness, // distance from corner to tip of curve
    cornerlegmin = min(leglenmin, bzdist*tana),
    cornerlegmax = min(leglenmax, bzdist*tana),
    p21unit = unit(p1-p2),
    p23unit = unit(p3-p2),
    midto12unit = unit(p21unit-p23unit),
    // bezier points around the corner p1,p2,p3 (p2 is the vertex):
    // bz0 is p1
    // bz1 is on same leg as p1
    // bz2 is on line perpendicular to bisector for first half of curve
    // bz3 is bezier start/end point on the corner bisector
    // bz4 is on line perpendicular to bisector for second half of curve
    // bz5 is on same leg as p3
    // bz6 is p3
    bz3 = p2 + middir * bzdist, // center control point
    bz2 = bz3 + midto12unit*(d1<d3 ? cornerlegmin : cornerlegmax),
    bz1 = p1 - (d1<=d3 ? leglenmin : leglenmax)*p21unit,
    bz4 = bz3 - midto12unit*(d3<d1 ? cornerlegmin : cornerlegmax),
    bz5 = p3 - (d3<=d1 ? leglenmin : leglenmax)*p23unit
) [p1, bz1, bz2, bz3, bz4, bz5]; // do not include last control point



// Function: bezpath_close_to_axis()
// Synopsis: Closes a 2D bezier path to the specified axis.
// SynTags: Path
// Topics: Bezier Paths
// See Also: bezpath_offset()
// Usage:
//   bezpath = bezpath_close_to_axis(bezpath, [axis], [N]);
// Description:
//   Takes a 2D bezier path and closes it to the specified axis.
// Arguments:
//   bezpath = The 2D bezier path to close to the axis.
//   axis = The axis to close to, "X", or "Y".  Default: "X"
//   N = The degree of the bezier curves.  Cubic beziers have N=3.  Default: 3
// Example(2D):
//   bez = [[50,30], [40,10], [10,50], [0,30],
//          [-10, 10], [-30,10], [-50,20]];
//   closed = bezpath_close_to_axis(bez);
//   debug_bezier(closed);
// Example(2D):
//   bez = [[30,50], [10,40], [50,10], [30,0],
//          [10, -10], [10,-30], [20,-50]];
//   closed = bezpath_close_to_axis(bez, axis="Y");
//   debug_bezier(closed);
function bezpath_close_to_axis(bezpath, axis="X", N=3) =
    assert(is_path(bezpath,2), "\nbezpath_close_to_axis() works only on 2D bezier paths.")
    assert(is_int(N))
    assert(len(bezpath)%N == 1, str("\nA degree ",N," bezier path should have a multiple of ",N," points in it, plus 1."))
    let(
        sp = bezpath[0],
        ep = last(bezpath)
    ) (axis=="X")? concat(
        lerpn([sp.x,0], sp, N, false),
        list_head(bezpath),
        lerpn(ep, [ep.x,0], N, false),
        lerpn([ep.x,0], [sp.x,0], N+1)
    ) : (axis=="Y")? concat(
        lerpn([0,sp.y], sp, N, false),
        list_head(bezpath),
        lerpn(ep, [0,ep.y], N, false),
        lerpn([0,ep.y], [0,sp.y], N+1)
    ) : (
        assert(in_list(axis, ["X","Y"]))
    );


// Function: bezpath_offset()
// Synopsis: Forms a closed bezier path loop with a translated and reversed copy of itself.
// SynTags: Path
// Topics: Bezier Paths
// See Also: bezpath_close_to_axis()
// Usage:
//   bezpath = bezpath_offset(offset, bezier, [N]);
// Description:
//   Takes a 2D bezier path and closes it with a matching reversed path that is offset by the given `offset` [X,Y] distance.
// Arguments:
//   offset = Amount to offset second path by.
//   bezier = The 2D bezier path.
//   N = The degree of the bezier curves.  Cubic beziers have N=3.  Default: 3
// Example(2D):
//   bez = [[50,30], [40,10], [10,50], [0,30], [-10, 10], [-30,10], [-50,20]];
//   closed = bezpath_offset([0,-5], bez);
//   debug_bezier(closed);
// Example(2D):
//   bez = [[30,50], [10,40], [50,10], [30,0], [10, -10], [10,-30], [20,-50]];
//   closed = bezpath_offset([-5,0], bez);
//   debug_bezier(closed);
function bezpath_offset(offset, bezier, N=3) =
    assert(is_vector(offset,2))
    assert(is_path(bezier,2), "\nbezpath_offset() works only on 2D bezier paths.")
    assert(is_int(N))
    assert(len(bezier)%N == 1, str("\nA degree ",N," bezier path should have a multiple of ",N," points in it, plus 1."))
    let(
        backbez = reverse([ for (pt = bezier) pt+offset ]),
        bezend = len(bezier)-1
    ) concat(
        list_head(bezier),
        lerpn(bezier[bezend], backbez[0], N, false),
        list_head(backbez),
        lerpn(backbez[bezend], bezier[0], N+1)
    );



// Section: Cubic Bezier Path Construction

// Function: bez_begin()
// Synopsis: Calculates starting bezier path control points.
// Topics: Bezier Paths
// See Also: bez_tang(), bez_joint(), bez_end()
// Usage:
//   pts = bez_begin(pt, a, r, [p=]);
//   pts = bez_begin(pt, VECTOR, [r], [p=]);
// Description:
//   This is used to create the first endpoint and control point of a cubic bezier path.
// Arguments:
//   pt = The starting endpoint for the bezier path.
//   a = If given a scalar, specifies the theta (XY plane) angle in degrees from X+.  If given a vector, specifies the direction and possibly distance of the first control point.
//   r = Specifies the distance of the control point from the endpoint `pt`.
//   ---
//   p = If given, specifies the number of degrees away from the Z+ axis.
// Example(2D): 2D Bezier Path by Angle
//   bezpath = flatten([
//       bez_begin([-50,  0],  45,20),
//       bez_tang ([  0,  0],-135,20),
//       bez_joint([ 20,-25], 135, 90, 10, 15),
//       bez_end  ([ 50,  0], -90,20),
//   ]);
//   debug_bezier(bezpath);
// Example(2D): 2D Bezier Path by Vector
//   bezpath = flatten([
//       bez_begin([-50,0],[0,-20]),
//       bez_tang ([-10,0],[0,-20]),
//       bez_joint([ 20,-25], [-10,10], [0,15]),
//       bez_end  ([ 50,0],[0, 20]),
//   ]);
//   debug_bezier(bezpath);
// Example(2D): 2D Bezier Path by Vector and Distance
//   bezpath = flatten([
//       bez_begin([-30,0],FWD, 30),
//       bez_tang ([  0,0],FWD, 30),
//       bez_joint([ 20,-25], 135, 90, 10, 15),
//       bez_end  ([ 30,0],BACK,30),
//   ]);
//   debug_bezier(bezpath);
// Example(3D,FlatSpin,VPD=200): 3D Bezier Path by Angle
//   bezpath = flatten([
//       bez_begin([-30,0,0],90,20,p=135),
//       bez_tang ([  0,0,0],-90,20,p=135),
//       bez_joint([20,-25,0], 135, 90, 15, 10, p1=135, p2=45),
//       bez_end  ([ 30,0,0],-90,20,p=45),
//   ]);
//   debug_bezier(bezpath);
// Example(3D,FlatSpin,VPD=225): 3D Bezier Path by Vector
//   bezpath = flatten([
//       bez_begin([-30,0,0],[0,-20, 20]),
//       bez_tang ([  0,0,0],[0,-20,-20]),
//       bez_joint([20,-25,0],[0,10,-10],[0,15,15]),
//       bez_end  ([ 30,0,0],[0,-20,-20]),
//   ]);
//   debug_bezier(bezpath);
// Example(3D,FlatSpin,VPD=225): 3D Bezier Path by Vector and Distance
//   bezpath = flatten([
//       bez_begin([-30,0,0],FWD, 20),
//       bez_tang ([  0,0,0],DOWN,20),
//       bez_joint([20,-25,0],LEFT,DOWN,r1=20,r2=15),
//       bez_end  ([ 30,0,0],DOWN,20),
//   ]);
//   debug_bezier(bezpath);
function bez_begin(pt,a,r,p) =
    assert(is_finite(r) || is_vector(a))
    assert(len(pt)==3 || is_undef(p))
    is_vector(a)? [pt, pt+(is_undef(r)? a : r*unit(a))] :
    is_finite(a)? [pt, pt+spherical_to_xyz(r,a,default(p,90))] :
    assert(false, "\nBad arguments.");


// Function: bez_tang()
// Synopsis: Calculates control points for a smooth bezier path joint.
// Topics: Bezier Paths
// See Also: bez_begin(), bez_joint(), bez_end()
// Usage:
//   pts = bez_tang(pt, a, r1, r2, [p=]);
//   pts = bez_tang(pt, VECTOR, [r1], [r2], [p=]);
// Description:
//   This creates a smooth joint in a cubic bezier path.  It creates three points, being the
//   approaching control point, the fixed bezier control point, and the departing control
//   point.  The two control points are collinear with the fixed point, making for a
//   smooth bezier curve at the fixed point. See {{bez_begin()}} for examples.
// Arguments:
//   pt = The fixed point for the bezier path.
//   a = If given a scalar, specifies the theta (XY plane) angle in degrees from X+.  If given a vector, specifies the direction and possibly distance of the departing control point.
//   r1 = Specifies the distance of the approching control point from the fixed point.  Overrides the distance component of the vector if `a` contains a vector.
//   r2 = Specifies the distance of the departing control point from the fixed point.  Overrides the distance component of the vector if `a` contains a vector.  If `r1` is given and `r2` is not, uses the value of `r1` for `r2`.
//   ---
//   p = If given, specifies the number of degrees away from the Z+ axis.
function bez_tang(pt,a,r1,r2,p) =
    assert(is_finite(r1) || is_vector(a))
    assert(len(pt)==3 || is_undef(p))
    let(
        r1 = is_num(r1)? r1 : norm(a),
        r2 = default(r2,r1),
        p = default(p, 90)
    )
    is_vector(a)? [pt-r1*unit(a), pt, pt+r2*unit(a)] :
    is_finite(a)? [
        pt-spherical_to_xyz(r1,a,p),
        pt,
        pt+spherical_to_xyz(r2,a,p)
    ] :
    assert(false, "\nBad arguments.");


// Function: bez_joint()
// Synopsis: Calculates control points for a disjointed corner bezier path joint.
// Topics: Bezier Paths
// See Also: bez_begin(), bez_tang(), bez_end()
// Usage:
//   pts = bez_joint(pt, a1, a2, r1, r2, [p1=], [p2=]);
//   pts = bez_joint(pt, VEC1, VEC2, [r1=], [r2=], [p1=], [p2=]);
// Description:
//   This creates a disjoint corner joint in a cubic bezier path.  It creates three points, being
//   the aproaching control point, the fixed bezier control point, and the departing control point.
//   The two control points can be directed in different arbitrary directions from the fixed bezier
//   point. See {{bez_begin()}} for examples.
// Arguments:
//   pt = The fixed point for the bezier path.
//   a1 = If given a scalar, specifies the theta (XY plane) angle in degrees from X+.  If given a vector, specifies the direction and possibly distance of the approaching control point.
//   a2 = If given a scalar, specifies the theta (XY plane) angle in degrees from X+.  If given a vector, specifies the direction and possibly distance of the departing control point.
//   r1 = Specifies the distance of the approching control point from the fixed point.  Overrides the distance component of the vector if `a1` contains a vector.
//   r2 = Specifies the distance of the departing control point from the fixed point.  Overrides the distance component of the vector if `a2` contains a vector.
//   ---
//   p1 = If given, specifies the number of degrees away from the Z+ axis of the approaching control point.
//   p2 = If given, specifies the number of degrees away from the Z+ axis of the departing control point.
function bez_joint(pt,a1,a2,r1,r2,p1,p2) =
    assert(is_finite(r1) || is_vector(a1))
    assert(is_finite(r2) || is_vector(a2))
    assert(len(pt)==3 || (is_undef(p1) && is_undef(p2)))
    let(
        r1 = is_num(r1)? r1 : norm(a1),
        r2 = is_num(r2)? r2 : norm(a2),
        p1 = default(p1, 90),
        p2 = default(p2, 90)
    ) [
        if (is_vector(a1)) (pt+r1*unit(a1))
        else if (is_finite(a1)) (pt+spherical_to_xyz(r1,a1,p1))
        else assert(false, "\nBad arguments."),
        pt,
        if (is_vector(a2)) (pt+r2*unit(a2))
        else if (is_finite(a2)) (pt+spherical_to_xyz(r2,a2,p2))
        else assert(false, "\nBad arguments.")
    ];


// Function: bez_end()
// Synopsis: Calculates ending bezier path control points.
// Topics: Bezier Paths
// See Also: bez_tang(), bez_joint(), bez_end()
// Usage:
//   pts = bez_end(pt, a, r, [p=]);
//   pts = bez_end(pt, VECTOR, [r], [p=]);
// Description:
//   This is used to create the approaching control point, and the endpoint of a cubic bezier path.
//   See {{bez_begin()}} for examples.
// Arguments:
//   pt = The starting endpoint for the bezier path.
//   a = If given a scalar, specifies the theta (XY plane) angle in degrees from X+.  If given a vector, specifies the direction and possibly distance of the first control point.
//   r = Specifies the distance of the control point from the endpoint `pt`.
//   p = If given, specifies the number of degrees away from the Z+ axis.
function bez_end(pt,a,r,p) =
    assert(is_finite(r) || is_vector(a))
    assert(len(pt)==3 || is_undef(p))
    is_vector(a)? [pt+(is_undef(r)? a : r*unit(a)), pt] :
    is_finite(a)? [pt+spherical_to_xyz(r,a,default(p,90)), pt] :
    assert(false, "\nBad arguments.");



// Section: Bezier Surfaces


// Function: is_bezier_patch()
// Synopsis: Returns true if the given item is a bezier patch.
// Topics: Bezier Patches, Type Checking
// Usage:
//   bool = is_bezier_patch(x);
// Description:
//   Returns true if the given item is a bezier patch. (a 2D array of 3D points.)
// Arguments:
//   x = The value to check the type of.
function is_bezier_patch(x) =
    is_list(x) && is_list(x[0]) && is_vector(x[0][0]) && len(x[0]) == len(x[len(x)-1]);  


// Function: bezier_patch_flat()
// Synopsis: Creates a flat bezier patch.
// Topics: Bezier Patches
// See Also: bezier_patch_points()
// Usage:
//   patch = bezier_patch_flat(size, [N=], [spin=], [orient=], [trans=]);
// Description:
//   Returns a flat rectangular bezier patch of degree `N`, centered on the XY plane.
// Arguments:
//   size = scalar or 2-vector giving the X and Y dimensions of the patch. 
//   ---
//   N = Degree of the patch to generate.  Since this is flat, a degree of 1 should usually be sufficient.  Default: 1
//   orient = A direction vector.  Point the patch normal in this direction.  
//   spin = Spin angle to apply to the patch
//   trans = Amount to translate patch, after orient and spin. 
// Example(3D):
//   patch = bezier_patch_flat(size=[100,100]);
//   debug_bezier_patches([patch], size=1, showcps=true);
function bezier_patch_flat(size, N=1, spin=0, orient=UP, trans=[0,0,0]) =
    assert(N>0)
    let(size = force_list(size,2))
    assert(is_vector(size,2))
    let(
        patch = [
            for (x=[0:1:N]) [
                for (y=[0:1:N])
                v_mul(point3d(size), [x/N-0.5, 0.5-y/N, 0])
            ]
        ],
        m = move(trans) * rot(a=spin, from=UP, to=orient)
    ) [for (row=patch) apply(m, row)];



// Function: bezier_patch_reverse()
// Synopsis: Reverses the orientation of a bezier patch.
// Topics: Bezier Patches
// See Also: bezier_patch_points(), bezier_patch_flat()
// Usage:
//   rpatch = bezier_patch_reverse(patch);
// Description:
//   Reverses the patch, so that the faces generated from it are flipped back to front.
// Arguments:
//   patch = The patch to reverse.
function bezier_patch_reverse(patch) =
    [for (row=patch) reverse(row)];


// Function: bezier_patch_points()
// Synopsis: Computes one or more specified points across a bezier surface patch.
// Topics: Bezier Patches
// See Also: bezier_patch_normals(), bezier_points(), bezier_curve(), bezpath_curve()
// Usage:
//   pt = bezier_patch_points(patch, u, v);
//   ptgrid = bezier_patch_points(patch, LIST, LIST);
//   ptgrid = bezier_patch_points(patch, RANGE, RANGE);
// Description:
//   Sample a bezier patch on a listed point set.  The bezier patch must be a rectangular array of
//   points, and it is sampled at all the (u,v) pairs that you specify.  If you give u and v
//   as single numbers you'll get a single point back.  If you give u and v as lists or ranges you'll
//   get a 2d rectangular array of points.  If one but not both of u and v is a list or range then you'll
//   get a list of points.  
// Arguments:
//   patch = The 2D array of control points for a Bezier patch.
//   u = The bezier u parameter (inner list of patch).  Generally between 0 and 1. Can be a list, range or value.
//   v = The bezier v parameter (outer list of patch).  Generally between 0 and 1. Can be a list, range or value.
// Example(3D):
//   patch = [
//       [[-50,-50,  0], [-16,-50,  20], [ 16,-50,  20], [50,-50,  0]],
//       [[-50,-16, 20], [-16,-16,  40], [ 16,-16,  40], [50,-16, 20]],
//       [[-50, 16, 20], [-16, 16,  40], [ 16, 16,  40], [50, 16, 20]],
//       [[-50, 50,  0], [-16, 50,  20], [ 16, 50,  20], [50, 50,  0]]
//   ];
//   debug_bezier_patches(patches=[patch], size=1, showcps=true);
//   pt = bezier_patch_points(patch, 0.6, 0.75);
//   translate(pt) color("magenta") sphere(d=3, $fn=12);
// Example(3D): Getting Multiple Points at Once
//   patch = [
//       [[-50,-50,  0], [-16,-50,  20], [ 16,-50,  20], [50,-50,  0]],
//       [[-50,-16, 20], [-16,-16,  40], [ 16,-16,  40], [50,-16, 20]],
//       [[-50, 16, 20], [-16, 16,  40], [ 16, 16,  40], [50, 16, 20]],
//       [[-50, 50,  0], [-16, 50,  20], [ 16, 50,  20], [50, 50,  0]]
//   ];
//   debug_bezier_patches(patches=[patch], size=1, showcps=true);
//   pts = bezier_patch_points(patch, [0:0.2:1], [0:0.2:1]);
//   for (row=pts) move_copies(row) color("magenta") sphere(d=3, $fn=12);
function bezier_patch_points(patch, u, v) =
    assert(is_range(u) || is_vector(u) || is_finite(u), "\nInput u is invalid.")
    assert(is_range(v) || is_vector(v) || is_finite(v), "\nInput v is invalid.")
      !is_num(u) && !is_num(v) ?
            let(
                vbezes = [for (i = idx(patch[0])) bezier_points(column(patch,i), u)]
            )
            [for (i = idx(vbezes[0])) bezier_points(column(vbezes,i), v)]
    : is_num(u) && is_num(v)? bezier_points([for (bez = patch) bezier_points(bez, v)], u)
    : is_num(u) ? bezier_patch_points(patch,force_list(u),v)[0]
    :             column(bezier_patch_points(patch,u,force_list(v)),0);


  

function _bezier_rectangle(patch, splinesteps=16, style="default") =
    let(
        uvals = lerpn(0,1,splinesteps.x+1),
        vvals = lerpn(1,0,splinesteps.y+1),
        pts = bezier_patch_points(patch, uvals, vvals)
    )
    vnf_vertex_array(pts, style=style, reverse=false);


// Function: bezier_vnf()
// Synopsis: Generates a (probably non-manifold) VNF for one or more bezier surface patches.
// SynTags: VNF
// Topics: Bezier Patches
// See Also: bezier_patch_points(), bezier_patch_flat()
// Usage:
//   vnf = bezier_vnf(patches, [splinesteps], [style]);
// Description:
//   Convert a patch or list of patches into the corresponding Bezier surface, representing the
//   result as a [VNF structure](vnf.scad).  The `splinesteps` argument specifies the sampling grid of
//   the surface for each patch by specifying the number of segments on the borders of the surface.
//   It can be a scalar, which gives a uniform grid, or
//   it can be [USTEPS, VSTEPS], which gives difference spacing in the U and V parameters. 
//   Note that the surface you produce may be disconnected and is not necessarily a valid manifold in OpenSCAD.
//   The patches must mate exactly along their edges to ensure a valid VNF.  
// Arguments:
//   patches = The bezier patch or list of bezier patches to convert into a vnf.
//   splinesteps = Number of segments on the border of the bezier surface.  You can specify [USTEPS,VSTEPS].  Default: 16
//   style = The style of subdividing the quads into faces.  Valid options are "default", "alt", "min_edge", "quincunx", "convex" and "concave".  See {{vnf_vertex_array()}}.  Default: "default"
// Example(3D):
//   patch = [
//       // u=0,v=0                                         u=1,v=0
//       [[-50,-50,  0], [-16,-50,  20], [ 16,-50, -20], [50,-50,  0]],
//       [[-50,-16, 20], [-16,-16,  20], [ 16,-16, -20], [50,-16, 20]],
//       [[-50, 16, 20], [-16, 16, -20], [ 16, 16,  20], [50, 16, 20]],
//       [[-50, 50,  0], [-16, 50, -20], [ 16, 50,  20], [50, 50,  0]],
//       // u=0,v=1                                         u=1,v=1
//   ];
//   vnf = bezier_vnf(patch, splinesteps=16);
//   vnf_polyhedron(vnf);
// Example(3D,FlatSpin,VPD=444): Combining multiple patches
//   patch = 100*[
//       // u=0,v=0                                u=1,v=0
//       [[0,  0,0], [1/3,  0,  0], [2/3,  0,  0], [1,  0,0]],
//       [[0,1/3,0], [1/3,1/3,1/3], [2/3,1/3,1/3], [1,1/3,0]],
//       [[0,2/3,0], [1/3,2/3,1/3], [2/3,2/3,1/3], [1,2/3,0]],
//       [[0,  1,0], [1/3,  1,  0], [2/3,  1,  0], [1,  1,0]],
//       // u=0,v=1                                u=1,v=1
//   ];
//   fpatch = bezier_patch_flat([100,100]);
//   tpatch = translate([-50,-50,50], patch);
//   flatpatch = translate([0,0,50], fpatch);
//   vnf = bezier_vnf([
//                     tpatch,
//                     xrot(90, tpatch),
//                     xrot(-90, tpatch),
//                     xrot(180, tpatch),
//                     yrot(90, flatpatch),
//                     yrot(-90, tpatch)]);
//   vnf_polyhedron(vnf);
// Example(3D):
//   patch1 = [
//       [[18,18,0], [33,  0,  0], [ 67,  0,  0], [ 82, 18,0]],
//       [[ 0,40,0], [ 0,  0,100], [100,  0, 20], [100, 40,0]],
//       [[ 0,60,0], [ 0,100,100], [100,100, 20], [100, 60,0]],
//       [[18,82,0], [33,100,  0], [ 67,100,  0], [ 82, 82,0]],
//   ];
//   patch2 = [
//       [[18,82,0], [33,100,  0], [ 67,100,  0], [ 82, 82,0]],
//       [[ 0,60,0], [ 0,100,-50], [100,100,-50], [100, 60,0]],
//       [[ 0,40,0], [ 0,  0,-50], [100,  0,-50], [100, 40,0]],
//       [[18,18,0], [33,  0,  0], [ 67,  0,  0], [ 82, 18,0]],
//   ];
//   vnf = bezier_vnf(patches=[patch1, patch2], splinesteps=16);
//   vnf_polyhedron(vnf);
// Example(3D): Connecting Patches with asymmetric splinesteps.  Note it is fastest to join all the VNFs at once, which happens in vnf_polyhedron, rather than generating intermediate joined partial surfaces.  
//   steps = 8;
//   edge_patch = [
//       // u=0, v=0                    u=1,v=0
//       [[-60, 0,-40], [0, 0,-40], [60, 0,-40]],
//       [[-60, 0,  0], [0, 0,  0], [60, 0,  0]],
//       [[-60,40,  0], [0,40,  0], [60,40,  0]],
//       // u=0, v=1                    u=1,v=1
//   ];
//   corner_patch = [
//       // u=0, v=0                    u=1,v=0
//       [[ 0, 40,-40], [ 0,  0,-40], [40,  0,-40]],
//       [[ 0, 40,  0], [ 0,  0,  0], [40,  0,  0]],
//       [[40, 40,  0], [40, 40,  0], [40, 40,  0]],
//       // u=0, v=1                    u=1,v=1
//   ];
//   face_patch = bezier_patch_flat([120,120],orient=LEFT);
//   edges = [
//       for (axrot=[[0,0,0],[0,90,0],[0,0,90]], xang=[-90:90:180])
//           bezier_vnf(
//               splinesteps=[steps,1],
//               rot(a=axrot,
//                   p=rot(a=[xang,0,0],
//                       p=translate(v=[0,-100,100],p=edge_patch)
//                   )
//               )
//           )
//   ];
//   corners = [
//       for (xang=[0,180], zang=[-90:90:180])
//           bezier_vnf(
//               splinesteps=steps,
//               rot(a=[xang,0,zang],
//                   p=translate(v=[-100,-100,100],p=corner_patch)
//               )
//           )
//   ];
//   faces = [
//       for (axrot=[[0,0,0],[0,90,0],[0,0,90]], zang=[0,180])
//           bezier_vnf(
//               splinesteps=1,
//               rot(a=axrot,
//                   p=zrot(zang,move([-100,0,0], face_patch))
//               )
//           )
//   ];
//   vnf_polyhedron(concat(edges,corners,faces));
function bezier_vnf(patches=[], splinesteps=16, style="default") =
    assert(is_num(splinesteps) || is_vector(splinesteps,2))
    assert(all_positive(splinesteps))
    let(splinesteps = force_list(splinesteps,2))
    is_bezier_patch(patches)? _bezier_rectangle(patches, splinesteps=splinesteps,style=style)
  : assert(is_list(patches),"\nInvalid patch list.")
    vnf_join(
      [
        for (patch=patches)
          is_bezier_patch(patch)? _bezier_rectangle(patch, splinesteps=splinesteps,style=style)
        : assert(false,"\nInvalid patch list.")
      ]
    );


// Function: bezier_vnf_degenerate_patch()
// Synopsis: Generates a VNF for a degenerate bezier surface patch.
// SynTags: VNF
// Topics: Bezier Patches
// See Also: bezier_patch_points(), bezier_patch_flat(), bezier_vnf()
// Usage:
//   vnf = bezier_vnf_degenerate_patch(patch, [splinesteps], [reverse]);
//   vnf_edges = bezier_vnf_degenerate_patch(patch, [splinesteps], [reverse], return_edges=true);
// Description:
//   Returns a [VNF](vnf.scad) for a degenerate rectangular bezier patch where some of the corners of the patch are
//   equal.  If the resulting patch has no faces then returns an empty VNF.  Note that due to the degeneracy,
//   the shape of the surface can be triangular even though the underlying patch is a rectangle.  
//   If you specify return_edges then the return is a list whose first element is the VNF and whose second
//   element lists the edges in the order [left (index zero of rows), right (last index of rows), top (first row), bottom (last row)],
//   where each list is a list of the actual
//   point values, but possibly only a single point if that edge is degenerate.
//   The method checks for various types of degeneracy and uses a triangular or partly triangular array of sample points. 
//   See examples below for the types of degeneracy detected and how the patch is sampled for those cases.
//   Note that splinesteps is the same for both directions of the patch, so it cannot be an array. 
// Arguments:
//   patch = Patch to process
//   splinesteps = Number of segments to produce on each side.  Default: 16
//   reverse = reverse direction of faces.  Default: false
//   return_edges = if true return the points on the four edges of the array: [left (index zero of rows), right (last index of rows)  , top (first row), bottom (last row)].  Default: false
// Example(3D,NoAxes): This quartic patch is degenerate at one corner, where a row of control points are equal.  Processing this degenerate patch normally produces excess triangles near the degenerate point. 
//   splinesteps=8;
//   patch=[
//         repeat([-12.5, 12.5, 15],5),
//          [[-6.25, 11.25, 15], [-6.25, 8.75, 15], [-6.25, 6.25, 15], [-8.75, 6.25, 15], [-11.25, 6.25, 15]],
//          [[0, 10, 15], [0, 5, 15], [0, 0, 15], [-5, 0, 15], [-10, 0, 15]],
//          [[0, 10, 8.75], [0, 5, 8.75], [0, 0, 8.75], [-5, 0, 8.75], [-10, 0, 8.75]],
//          [[0, 10, 2.5], [0, 5, 2.5], [0, 0, 2.5], [-5, 0, 2.5], [-10, 0, 2.5]]
//         ];
//   vnf_wireframe((bezier_vnf(patch, splinesteps)),width=0.1);
//   color("red")move_copies(flatten(patch)) sphere(r=0.3,$fn=9);
// Example(3D,NoAxes): With bezier_vnf_degenerate_patch the degenerate point does not have excess triangles.  The top half of the patch decreases the number of sampled points by 2 for each row.  
//   splinesteps=8;
//   patch=[
//          repeat([-12.5, 12.5, 15],5),
//          [[-6.25, 11.25, 15], [-6.25, 8.75, 15], [-6.25, 6.25, 15], [-8.75, 6.25, 15], [-11.25, 6.25, 15]],
//          [[0, 10, 15], [0, 5, 15], [0, 0, 15], [-5, 0, 15], [-10, 0, 15]],
//          [[0, 10, 8.75], [0, 5, 8.75], [0, 0, 8.75], [-5, 0, 8.75], [-10, 0, 8.75]],
//          [[0, 10, 2.5], [0, 5, 2.5], [0, 0, 2.5], [-5, 0, 2.5], [-10, 0, 2.5]]
//         ];
//   vnf_wireframe(bezier_vnf_degenerate_patch(patch, splinesteps),width=0.1);
//   color("red")move_copies(flatten(patch)) sphere(r=0.3,$fn=9);
// Example(3D,NoAxes): With splinesteps odd you get one "odd" row where the point count decreases by 1 instead of 2.  You may prefer even values for splinesteps to avoid this. 
//   splinesteps=7;
//   patch=[
//          repeat([-12.5, 12.5, 15],5),
//          [[-6.25, 11.25, 15], [-6.25, 8.75, 15], [-6.25, 6.25, 15], [-8.75, 6.25, 15], [-11.25, 6.25, 15]],
//          [[0, 10, 15], [0, 5, 15], [0, 0, 15], [-5, 0, 15], [-10, 0, 15]],
//          [[0, 10, 8.75], [0, 5, 8.75], [0, 0, 8.75], [-5, 0, 8.75], [-10, 0, 8.75]],
//          [[0, 10, 2.5], [0, 5, 2.5], [0, 0, 2.5], [-5, 0, 2.5], [-10, 0, 2.5]]
//         ];
//   vnf_wireframe(bezier_vnf_degenerate_patch(patch, splinesteps),width=0.1);
//   color("red")move_copies(flatten(patch)) sphere(r=0.3,$fn=9);
// Example(3D,NoAxes): A more extreme degeneracy occurs when the top half of a patch is degenerate to a line.  (For odd length patches the middle row must be degenerate to trigger this style.)  In this case the number of points in each row decreases by 1 for every row.  It doesn't matter if splinesteps is odd or even. 
//   splinesteps=8;
//   patch = [[[10, 0, 0], [10, -10.4, 0], [10, -20.8, 0], [1.876, -14.30, 0], [-6.24, -7.8, 0]],
//            [[5, 0, 0], [5, -5.2, 0], [5, -10.4, 0], [0.938, -7.15, 0], [-3.12, -3.9, 0]],
//            repeat([0,0,0],5),
//            repeat([0,0,5],5),
//            repeat([0,0,10],5)
//           ];
//   vnf_wireframe(bezier_vnf_degenerate_patch(patch, splinesteps),width=0.1);
//   color("red")move_copies(flatten(patch)) sphere(r=0.3,$fn=9);
// Example(3D,NoScales): Here is a degenerate cubic patch.
//   splinesteps=8;
//   patch = [ [ [-20,0,0],  [-10,0,0],[0,10,0],[0,20,0] ],
//             [ [-20,0,10], [-10,0,10],[0,10,10],[0,20,10]],
//             [ [-10,0,20], [-5,0,20], [0,5,20], [0,10,20]],
//              repeat([0,0,30],4)
//               ];
//   color("red")move_copies(flatten(patch)) sphere(r=0.3,$fn=9);
//   vnf_wireframe(bezier_vnf_degenerate_patch(patch, splinesteps),width=0.1);
// Example(3D,NoScales): A more extreme degenerate cubic patch, where two rows are equal.
//   splinesteps=8;
//   patch = [ [ [-20,0,0], [-10,0,0],[0,10,0],[0,20,0] ],
//             [ [-20,0,10], [-10,0,10],[0,10,10],[0,20,10] ],
//              repeat([-10,10,20],4),
//              repeat([-10,10,30],4)          
//           ];
//   color("red")move_copies(flatten(patch)) sphere(r=0.3,$fn=9);
//   vnf_wireframe(bezier_vnf_degenerate_patch(patch, splinesteps),width=0.1);
// Example(3D,NoScales): Quadratic patch degenerate at the right side:
//   splinesteps=8;
//   patch = [[[0, -10, 0],[10, -5, 0],[20, 0, 0]],
//            [[0, 0, 0],  [10, 0, 0], [20, 0, 0]],
//            [[0, 0, 10], [10, 0, 5], [20, 0, 0]]];
//   vnf_wireframe(bezier_vnf_degenerate_patch(patch, splinesteps),width=0.1);
//   color("red")move_copies(flatten(patch)) sphere(r=0.3,$fn=9);
// Example(3D,NoAxes): Cubic patch degenerate at both ends.  In this case the point count changes by 2 at every row.  
//   splinesteps=8;
//   patch = [
//            repeat([10,-10,0],4),
//            [ [-20,0,0], [-1,0,0],[0,10,0],[0,20,0] ],
//            [ [-20,0,10], [-10,0,10],[0,10,10],[0,20,10] ],
//            repeat([-10,10,20],4),
//           ];
//   vnf_wireframe(bezier_vnf_degenerate_patch(patch, splinesteps),width=0.1);
//   color("red")move_copies(flatten(patch)) sphere(r=0.3,$fn=9);
function bezier_vnf_degenerate_patch(patch, splinesteps=16, reverse=false, return_edges=false) =
    !return_edges ? bezier_vnf_degenerate_patch(patch, splinesteps, reverse, true)[0] :
    assert(is_bezier_patch(patch), "\nInput is not a Bezier patch.")
    assert(is_int(splinesteps) && splinesteps>0, "\nsplinesteps must be a positive integer.")
    let(
        row_degen = [for(row=patch) all_equal(row,eps=EPSILON)],
        col_degen = [for(col=transpose(patch)) all_equal(col,eps=EPSILON)],
        top_degen = row_degen[0],
        bot_degen = last(row_degen),
        left_degen = col_degen[0],
        right_degen = last(col_degen),
        samplepts = lerpn(0,1,splinesteps+1)
    )
    all(row_degen) && all(col_degen) ?  // fully degenerate case
        [EMPTY_VNF, repeat([patch[0][0]],4)] :
    all(row_degen) ?                         // degenerate to a line (top to bottom)
        let(pts = bezier_points(column(patch,0), samplepts))
        [EMPTY_VNF, [pts,pts,[pts[0]],[last(pts)]]] :
    all(col_degen) ?                         // degenerate to a line (left to right)
        let(pts = bezier_points(patch[0], samplepts))
        [EMPTY_VNF, [[pts[0]], [last(pts)], pts, pts]] :
    !top_degen && !bot_degen && !left_degen && !right_degen ?       // non-degenerate case
       let(pts = bezier_patch_points(patch, samplepts, samplepts))
       [
        vnf_vertex_array(pts, reverse=!reverse),
        [column(pts,0), column(pts,len(pts)-1), pts[0], last(pts)]
       ] :
    top_degen && bot_degen ?
       let(
            rowcount = [
                        each list([3:2:splinesteps]),
                        if (splinesteps%2==0) splinesteps+1,
                        each reverse(list([3:2:splinesteps]))
                       ],
            bpatch = [for(i=[0:1:len(patch[0])-1]) bezier_points(column(patch,i), samplepts)],
            pts = [
                  [bpatch[0][0]],
                  for(j=[0:splinesteps-2]) bezier_points(column(bpatch,j+1), lerpn(0,1,rowcount[j])),
                  [last(bpatch[0])]
                  ],
            vnf = vnf_tri_array(pts, reverse=!reverse)
         ) [
            vnf,
            [
             column(pts,0),
             [for(row=pts) last(row)],
             pts[0],
             last(pts),
            ]
          ]  :    
    bot_degen ?                                           // only bottom is degenerate
       let(
           result = bezier_vnf_degenerate_patch(reverse(patch), splinesteps=splinesteps, reverse=!reverse, return_edges=true)
       )
       [
          result[0],
          [reverse(result[1][0]), reverse(result[1][1]), (result[1][3]), (result[1][2])]
       ] :
    top_degen ?                                          // only top is degenerate
       let(
           full_degen = len(patch)>=4 && all(select(row_degen,1,ceil(len(patch)/2-1))),
           rowmax = full_degen ? count(splinesteps+1) :
                                 [for(j=[0:splinesteps]) j<=splinesteps/2 ? 2*j : splinesteps],
           bpatch = [for(i=[0:1:len(patch[0])-1]) bezier_points(column(patch,i), samplepts)],
           pts = [
                  [bpatch[0][0]],
                  for(j=[1:splinesteps]) bezier_points(column(bpatch,j), lerpn(0,1,rowmax[j]+1))
                 ],
           vnf = vnf_tri_array(pts, reverse=!reverse)
        ) [
            vnf,
            [
             column(pts,0),
             [for(row=pts) last(row)],
             pts[0],
             last(pts),
            ]
          ] :
      // must have left or right degeneracy, so transpose and recurse
      let(
          result = bezier_vnf_degenerate_patch(transpose(patch), splinesteps=splinesteps, reverse=!reverse, return_edges=true)
      )
      [result[0],
       select(result[1],[2,3,0,1])
      ];


// Function: bezier_patch_normals()
// Synopsis: Computes surface normals for one or more places on a bezier surface patch.
// Topics: Bezier Patches
// See Also: bezier_patch_points(), bezier_points(), bezier_curve(), bezpath_curve()
// Usage:
//   n = bezier_patch_normals(patch, u, v);
//   ngrid = bezier_patch_normals(patch, LIST, LIST);
//   ngrid = bezier_patch_normals(patch, RANGE, RANGE);
// Description:
//   Compute the unit normal vector to a bezier patch at the listed point set.  The bezier patch must be a rectangular array of
//   points, and the normal is computed at all the (u,v) pairs that you specify.  If you give u and v
//   as single numbers you'll get a single point back.  If you give u and v as lists or ranges you'll
//   get a 2d rectangular array of points.  If one but not both of u and v is a list or range then you'll
//   get a list of points.
//   .
//   This function works by computing the cross product of the tangents.  In some degenerate cases the one of the tangents
//   can be zero, so the normal vector does not exist.  In this case, undef is returned.  Another degenerate case
//   occurs when the tangents are parallel, or nearly parallel.  In this case you get a unit vector returned but it is not
//   the correct normal vector. This can happen if you use a degenerate patch, or if you give two of the edges of your patch a smooth "corner"
//   so that the u and v directions are parallel at the corner.  
// Arguments:
//   patch = The 2D array of control points for a Bezier patch.
//   u = The bezier u parameter (inner list of patch).  Generally between 0 and 1. Can be a list, range or value.
//   v = The bezier v parameter (outer list of patch).  Generally between 0 and 1. Can be a list, range or value.
// Example(3D,Med,VPR=[71.1,0,155.9],VPD=292.705,VPT=[20.4724,38.7273,22.7683],NoAxes): Normal vectors on a patch
//   patch = [
//        // u=0,v=0                                         u=1,v=0
//        [[-50,-50,  0], [-16,-50,  20], [ 16,-50, -20], [50,-50,  0]],
//        [[-50,-16, 40], [-16,-16,  20], [ 16,-16, -20], [50,-16, 70]],
//        [[-50, 16, 20], [-16, 16, -20], [ 16, 37,  20], [70, 16, 20]],
//        [[-50, 50,  0], [73, 50, -40], [ 16, 50,  20], [50, 50,  0]],
//        // u=0,v=1                                         u=1,v=1
//   ];
//   vnf_polyhedron(bezier_vnf(patch,splinesteps=30));
//   uv = lerpn(0,1,12);
//   pts = bezier_patch_points(patch, uv, uv);
//   normals = bezier_patch_normals(patch, uv, uv);
//     for(i=idx(uv),j=idx(uv)){
//        stroke([pts[i][j],pts[i][j]-6*normals[i][j]], width=0.5,
//               endcap1="dot",endcap2="arrow2",color="blue");
//   }
// Example(3D,NoAxes,Med,VPR=[72.5,0,288.9],VPD=192.044,VPT=[51.6089,48.118,5.89088]): This example gives invalid normal vectors at the four corners of the patch where the u and v directions are parallel.  You can see how the line of triangulation is approaching parallel at the edge, and the invalid vectors in red point in a completely incorrect direction.  
//   patch = [
//       [[18,18,0], [33,  0,  0], [ 67,  0,  0], [ 82, 18,0]],
//       [[ 0,40,0], [ 0,  0,100], [100,  0, 20], [100, 40,0]],
//       [[ 0,60,0], [ 0,100,100], [100,100, 20], [100, 60,0]],
//       [[18,82,0], [33,100,  0], [ 67,100,  0], [ 82, 82,0]],
//   ];
//   vnf_polyhedron(bezier_vnf(patch,splinesteps=30));
//   uv = lerpn(0,1,7);
//   pts = bezier_patch_points(patch, uv, uv);
//   normals = bezier_patch_normals(patch, uv, uv);
//     for(i=idx(uv),j=idx(uv)){
//        color=((uv[i]==0 || uv[i]==1) && (uv[j]==0 || uv[j]==1))
//             ? "red" : "blue";
//        stroke([pts[i][j],pts[i][j]-8*normals[i][j]], width=0.5,
//               endcap1="dot",endcap2="arrow2",color=color);
//   }
// Example(3D,Med,NoAxes,VPR=[56.4,0,71.9],VPD=66.9616,VPT=[10.2954,1.33721,19.4484]): This degenerate patch has normals everywhere, but computation of the normal fails at the point of degeneracy, the top corner.  
//    patch=[
//             repeat([-12.5, 12.5, 15],5),
//              [[-6.25, 11.25, 15], [-6.25, 8.75, 15], [-6.25, 6.25, 15], [-8.75, 6.25, 15], [-11.25, 6.25, 15]],
//              [[0, 10, 15], [0, 5, 15], [0, 0, 15], [-5, 0, 15], [-10, 0, 15]],
//              [[0, 10, 8.75], [0, 5, 8.75], [0, 0, 8.75], [-5, 0, 8.75], [-10, 0, 8.75]],
//              [[0, 10, 2.5], [0, 5, 2.5], [0, 0, 2.5], [-5, 0, 2.5], [-10, 0, 2.5]]
//             ];
//    vnf_polyhedron(bezier_vnf(patch, 32));
//    uv = lerpn(0,1,8);
//    pts = bezier_patch_points(patch, uv, uv);
//    normals = bezier_patch_normals(patch, uv, uv);
//      for(i=idx(uv),j=idx(uv)){
//        if (is_def(normals[i][j]))
//          stroke([pts[i][j],pts[i][j]-2*normals[i][j]], width=0.1,
//                 endcap1="dot",endcap2="arrow2",color="blue");
//    }
// Example(3D,Med,NoAxes,VPR=[48,0,23.6],VPD=32.0275,VPT=[-0.145727,-0.0532125,1.74224]): This example has a singularities where the tangent lines don't exist, so the normal is undef at those points.  
//    pts1 = [ [-5,0,0], [5,0,5], [-5,0,5], [5,0,0] ];
//    pts2 = [ [0,-5,0], [0,5,5], [0,-5,5], [0,5,0] ];
//    patch = [for(i=[0:3])
//            [for(j=[0:3]) pts1[i]+pts2[j] ] ];
//    vnf_polyhedron(bezier_vnf(patch, 163));
//    uv = [0,.1,.2,.3,.7,.8,.9,1];//lerpn(0,1,8);
//    pts = bezier_patch_points(patch, uv, uv);
//    normals = bezier_patch_normals(patch, uv, uv);
//    for(i=idx(uv),j=idx(uv))
//      stroke([pts[i][j],pts[i][j]+2*normals[i][j]], width=0.08,
//               endcap1="dot",endcap2="arrow2",color="blue");
  
function bezier_patch_normals(patch, u, v) =
    assert(is_range(u) || is_vector(u) || is_finite(u), "\nInput u is invalid.")
    assert(is_range(v) || is_vector(v) || is_finite(v), "\nInput v is invalid.")
      !is_num(u) && !is_num(v) ?
          let(
              vbezes = [for (i = idx(patch[0])) bezier_points(column(patch,i), u)],
              dvbezes = [for (i = idx(patch[0])) bezier_derivative(column(patch,i), u)],
              v_tangent = [for (i = idx(vbezes[0])) bezier_derivative(column(vbezes,i), v)],
              u_tangent = [for (i = idx(vbezes[0])) bezier_points(column(dvbezes,i), v)]
          )
          [for(i=idx(u_tangent)) [for(j=idx(u_tangent[0])) unit(cross(u_tangent[i][j],v_tangent[i][j]),undef)]]
    : is_num(u) && is_num(v)?
          let(
                du = bezier_derivative([for (bez = patch) bezier_points(bez, v)], u),
                dv = bezier_points([for (bez = patch) bezier_derivative(bez, v)], u)
          )
          unit(cross(du,dv),undef)
    : is_num(u) ? bezier_patch_normals(patch,force_list(u),v)[0]
    :             column(bezier_patch_normals(patch,u,force_list(v)),0);


// Function: bezier_sheet()
// Synopsis: Creates a thin sheet from a bezier patch by extruding in normal to the patch
// SynTags: VNF
// Topics: Bezier Patches
// See Also: bezier_patch_normals(), vnf_sheet()
// Usage:
//   vnf = bezier_sheet(patch, delta, [splinesteps=], [style=]);
// Description:
//   Constructs a thin sheet from a bezier patch by offsetting the given patch along the normal vectors
//   to the patch surface.
//   The `delta` parameter is a 2-vector specifying the offset distances for both surfaces that form the
//   final sheet. The values for each offset must be small enough so that no points cross each other
//   when the offset is computed, because that results in invalid geometry and rendering errors.
//   Rendering errors may not manifest until you add other objects to your model.  
//   **It is your responsibility to avoid invalid geometry!**
//   .
//   Once the offset surfaces from the bezier patch are computed, they are connected by filling
//   in the boundary strips between them.
//   .
//   A negative offset value extends the patch toward its "inside", which is the side that appears purple
//   in the "thrown together" view when the patch is viewed by itself. Extending only toward the inside with a delta of `[0,-value]` or
//   `[-value,0]` (the order doesn't matter) means that your original bezier patch surface remains unchanged in the output.
//   Both offset surfaces may be extended in the same direction as long as the offset values are different.
// Arguments:
//   patch = bezier patch to process
//   delta = a 2-vector specifying two different offsets from the bezier patch, in any order. Positive values offset the patch from its "exterior" side, and negative values offset from the "interior" side.
//   ---
//   splinesteps = Number of segments on the border edges of the bezier surface.  You can specify [USTEPS,VSTEPS].  Default: 16
//   style = {{vnf_vertex_array()}} style to use.  Default: "default"
// Example(3D): A negative delta extends downward from the "inside" surface of the bezier patch, leaving the original bezier patch unchanged on the top surface.
//   patch = [
//        // u=0,v=0                                         u=1,v=0
//        [[-50,-50,  0], [-16,-50,  20], [ 16,-50, -20], [50,-50,  0]],
//        [[-50,-16, 20], [-16,-16,  20], [ 16,-16, -20], [50,-16, 20]],
//        [[-50, 16, 20], [-16, 16, -20], [ 16, 16,  20], [50, 16, 20]],
//        [[-50, 50,  0], [-16, 50, -20], [ 16, 50,  20], [50, 50,  0]],
//        // u=0,v=1                                         u=1,v=1
//   ];
//   vnf_polyhedron(bezier_sheet(patch, [0,-10]));
// Example(3D): Using the previous example, setting two positive offsets results in a sheet above the original bezier patch. The original bezier patch is shown in green for comparison.
//   patch = [
//        // u=0,v=0                                         u=1,v=0
//        [[-50,-50,  0], [-16,-50,  20], [ 16,-50, -20], [50,-50,  0]],
//        [[-50,-16, 20], [-16,-16,  20], [ 16,-16, -20], [50,-16, 20]],
//        [[-50, 16, 20], [-16, 16, -20], [ 16, 16,  20], [50, 16, 20]],
//        [[-50, 50,  0], [-16, 50, -20], [ 16, 50,  20], [50, 50,  0]],
//        // u=0,v=1                                         u=1,v=1
//   ];
//   color("lime") vnf_polyhedron(bezier_vnf(patch));
//   vnf_polyhedron(bezier_sheet(patch, [10,15]));

function bezier_sheet(patch, delta, splinesteps=16, style="default", thickness=undef) =
  assert(is_bezier_patch(patch))
    assert(is_num(delta) || is_vector(delta,2,zero=false), "\ndelta must be a 2-vector designating two different offset distances.")
  let(
        dumwarn = is_def(thickness) || is_num(delta) ? echo("\nThe 'thickness' parameter is deprecated and has been replaced by 'delta'. Use the range [0,-thickness] or [-thickness,0] to reproduce the former behavior.") : 0,
        del = is_def(thickness) ? [0,-thickness] : is_num(delta) ? [0,-delta] : delta,
        splinesteps = force_list(splinesteps,2),
        uvals = lerpn(0,1,splinesteps.x+1),
        vvals = lerpn(1,0,splinesteps.y+1),
        pts = bezier_patch_points(patch, uvals, vvals),
        normals = bezier_patch_normals(patch, uvals, vvals),
        dummy=assert(is_matrix(flatten(normals)),"\nBezier patch has degenerate normals."),
        offset0 = pts - del[0]*normals,
        offset1 = pts - del[1]*normals,
        allpoints = [for(i=idx(offset0)) concat(offset0[i], reverse(offset1[i]))],
        vnf = vnf_vertex_array(allpoints, col_wrap=true, caps=true, style=style)        
  )
  del[0]<del[1] ? vnf_reverse_faces(vnf) : vnf;



// Section: Debugging Beziers


// Module: debug_bezier()
// Synopsis: Shows a bezier path and its associated control points.
// SynTags: Geom
// Topics: Bezier Paths, Debugging
// See Also: bezpath_curve()
// Usage:
//   debug_bezier(bez, [size], [N=]);
// Description:
//   Renders 2D or 3D bezier paths and their associated control points to help debug bezier paths. 
//   The endpoints of each bezier curve in the bezier path are marked with a blue circle and the intermediate control
//   points with a red plus sign.  For cubic (degree 3) bezier paths, the module displays the standard representation
//   of the control points as "handles" at each endpoint.  For other degrees the control points are drawn as
//   a polygon.  You can of course give a single bezier curve as input, but you must in that case explicitly specify
//   the bezier degree when it is not a cubic bezier.  
// Arguments:
//   bez = the array of points in the bezier.
//   size = diameter of the lines drawn.
//   ---
//   N = The degree of the bezier curves.  Cubic beziers have N=3.  Default: 3
// Example(2D): Cubic bezier path
//   bez = [
//       [-10,   0],  [-15,  -5],
//       [ -5, -10],  [  0, -10],  [ 5, -10],
//       [ 14,  -5],  [ 15,   0],  [16,   5],
//       [  5,  10],  [  0,  10]
//   ];
//   debug_bezier(bez, N=3, width=0.5);
// Example(2D): Quartic (degree 4) bezier path
//   bez = [
//       [-10,   0],  [-15,  -5],
//       [ -9, -10],  [  0, -12],  [ 5, -10],
//       [ 14,  -5],  [ 18,   0],  [16,   5],
//       [  5,  10] 
//   ];
//   debug_bezier(bez, N=4, width=0.5);

module debug_bezier(bezpath, width=1, N=3) {
    no_children($children);
    check = 
      assert(is_path(bezpath),"bezpath must be a path")
      assert(is_int(N) && N>0, "N must be a positive integer")
      assert(len(bezpath)%N == 1, str("A degree ",N," bezier path should have a multiple of ",N," points in it, plus 1."));
    $fn=8;
    stroke(bezpath_curve(bezpath, N=N), width=width, color="cyan");
    color("green")
      if (N!=3) 
           stroke(bezpath, width=width);
      else 
           for(i=[1:3:len(bezpath)]) stroke(select(bezpath,max(0,i-2), min(len(bezpath)-1,i)), width=width);
    twodim = len(bezpath[0])==2;
    color("red") move_copies(bezpath)
      if ($idx % N !=0)
          if (twodim){
            rect([width/2, width*3]);
            rect([width*3, width/2]);
          } else {
           zcyl(d=width/2, h=width*3);
           xcyl(d=width/2, h=width*3);
           ycyl(d=width/2, h=width*3);
        }
    color("blue") move_copies(bezpath)
      if ($idx % N ==0)
        if (twodim) circle(d=width*2.25); else sphere(d=width*2.25);
    if (twodim) color("red") move_copies(bezpath)
      if ($idx % N !=0) circle(d=width/2);
}


// Module: debug_bezier_patches()
// Synopsis: Shows a bezier surface patch and its associated control points.
// SynTags: Geom
// Topics: Bezier Patches, Debugging
// See Also: bezier_patch_points(), bezier_patch_flat(), bezier_vnf()
// Usage:
//   debug_bezier_patches(patches, [size=], [splinesteps=], [showcps=], [showdots=], [showpatch=], [convexity=], [style=]);
// Description:
//   Shows the surface, and optionally, control points of a list of bezier patches.
// Arguments:
//   patches = A list of rectangular bezier patches.
//   ---
//   splinesteps = Number of segments to divide each bezier curve into. Default: 16
//   showcps = If true, show the controlpoints as well as the surface.  Default: true.
//   showdots = If true, shows the calculated surface vertices.  Default: false.
//   showpatch = If true, shows the surface faces.  Default: true.
//   size = Size to show control points and lines.  Default: 1% of the maximum side length of a box bounding the patch.
//   style = The style of subdividing the quads into faces.  Valid options are "default", "alt", and "quincunx".
//   convexity = Max number of times a line could intersect a wall of the shape.
// Example:
//   patch1 = [
//       [[15,15,0], [33,  0,  0], [ 67,  0,  0], [ 85, 15,0]],
//       [[ 0,33,0], [33, 33, 50], [ 67, 33, 50], [100, 33,0]],
//       [[ 0,67,0], [33, 67, 50], [ 67, 67, 50], [100, 67,0]],
//       [[15,85,0], [33,100,  0], [ 67,100,  0], [ 85, 85,0]],
//   ];
//   patch2 = [
//       [[15,85,0], [33,100,  0], [ 67,100,  0], [ 85, 85,0]],
//       [[ 0,67,0], [33, 67,-50], [ 67, 67,-50], [100, 67,0]],
//       [[ 0,33,0], [33, 33,-50], [ 67, 33,-50], [100, 33,0]],
//       [[15,15,0], [33,  0,  0], [ 67,  0,  0], [ 85, 15,0]],
//   ];
//   debug_bezier_patches(patches=[patch1, patch2], splinesteps=8, showcps=true);
module debug_bezier_patches(patches=[], size, splinesteps=16, showcps=true, showdots=false, showpatch=true, convexity=10, style="default")
{
    no_children($children);
    assert(is_undef(size)||is_num(size));
    assert(is_int(splinesteps) && splinesteps>0);
    assert(is_list(patches) && all([for (patch=patches) is_bezier_patch(patch)]));
    assert(is_bool(showcps));
    assert(is_bool(showdots));
    assert(is_bool(showpatch));
    assert(is_int(convexity) && convexity>0);
    for (patch = patches) {
        size = is_num(size)? size :
               let( bounds = pointlist_bounds(flatten(patch)) )
               max(bounds[1]-bounds[0])*0.01;
        if (showcps) {
            move_copies(flatten(patch)) color("red") sphere(d=size*2);
            color("cyan") 
                for (i=[0:1:len(patch)-1], j=[0:1:len(patch[i])-1]) {
                        if (i<len(patch)-1) extrude_from_to(patch[i][j], patch[i+1][j]) circle(d=size);
                        if (j<len(patch[i])-1) extrude_from_to(patch[i][j], patch[i][j+1]) circle(d=size);
                }        
        }
        if (showpatch || showdots){
            vnf = bezier_vnf(patch, splinesteps=splinesteps, style=style);
            if (showpatch) vnf_polyhedron(vnf, convexity=convexity);
            if (showdots) color("blue") move_copies(vnf[0]) sphere(d=size);
        }
    }
}


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
