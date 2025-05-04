//////////////////////////////////////////////////////////////////////
// LibFile: geometry.scad
//   Perform calculations on lines, polygons, planes and circles, including
//   normals, intersections of objects, distance between objects, and tangent lines.
//   Throughout this library, lines can be treated as either unbounded lines, as rays with
//   a single endpoint or as segments, bounded by endpoints at both ends.  
// Includes:
//   include <BOSL2/std.scad>
// FileGroup: Math
// FileSummary: Geometrical calculations including intersections of lines, circles and planes, circle from 3 points
// FileFootnotes: STD=Included in std.scad
//////////////////////////////////////////////////////////////////////


// Section: Lines, Rays, and Segments

// Function: is_point_on_line()
// Synopsis: Determine if a point is on a line, ray or segment. 
// Topics: Geometry, Points, Segments
// See Also: is_collinear(), is_point_on_line(), point_line_distance(), line_from_points()
// Usage:
//   pt = is_point_on_line(point, line, [bounded], [eps]);
// Description:
//   Determine if the point is on the line segment, ray or segment defined by the two between two points.
//   Returns true if yes, and false if not.  If bounded is set to true it specifies a segment, with
//   both lines bounded at the ends.  Set bounded to `[true,false]` to get a ray.  You can use
//   the shorthands RAY and SEGMENT to set bounded.  
// Arguments:
//   point = The point to test.
//   line = Array of two points defining the line, ray, or segment to test against.
//   bounded = boolean or list of two booleans defining endpoint conditions for the line. If false treat the line as an unbounded line.  If true treat it as a segment.  If [true,false] treat as a ray, based at the first endpoint.  Default: false
//   eps = Tolerance in geometric comparisons.  Default: `EPSILON` (1e-9)
function is_point_on_line(point, line, bounded=false, eps=EPSILON) =
    assert(is_finite(eps) && (eps>=0), "\nThe tolerance should be a non-negative value." )
    assert(is_vector(point), "\nPoint must be a vector.")
    assert(_valid_line(line, len(point),eps),"\nGiven line is not valid.")
    _is_point_on_line(point, line, bounded,eps);

function _is_point_on_line(point, line, bounded=false, eps=EPSILON) =
    let( 
        v1 = (line[1]-line[0]),
        v0 = (point-line[0]),
        t  = v0*v1/(v1*v1),
        bounded = force_list(bounded,2),
        norm_crossprod = len(v1)==2 ? abs(cross(v0,v1)) : norm(cross(v0,v1))
    ) 
    norm_crossprod <= eps*norm(v1) 
    && (!bounded[0] || t>=-eps) 
    && (!bounded[1] || t<1+eps) ;


///Internal - distance from point `d` to the line passing through the origin with unit direction n
///_dist2line works for any dimension
function _dist2line(d,n) = norm(d-(d * n) * n);


///Internal
function _valid_line(line,dim,eps=EPSILON) =
    is_matrix(line,2,dim)
    && norm(line[1]-line[0])>eps*max(norm(line[1]),norm(line[0]));

//Internal
function _valid_plane(p, eps=EPSILON) = is_vector(p,4) && ! approx(norm(p),0,eps);


/// Internal Function: _is_at_left()
/// Usage:
///   pt = point_left_of_line2d(point, line);
/// Topics: Geometry, Points, Lines
/// Description:
///   Return true iff a 2d point is on or at left of the line defined by `line`.
/// Arguments:
///   pt = The 2d point to check position of.
///   line  = Array of two 2d points forming the line segment to test against.
///   eps = Tolerance in the geometrical tests.
function _is_at_left(pt,line,eps=EPSILON) = _tri_class([pt,line[0],line[1]],eps) <= 0;


/// Internal Function: _degenerate_tri()
/// Usage:
///   degen = _degenerate_tri(triangle);
/// Topics: Geometry, Triangles
/// Description:
///   Return true for a specific kind of degeneracy: any two triangle vertices are equal
/// Arguments:
///   tri = A list of three 2d points
///   eps = Tolerance in the geometrical tests.
function _degenerate_tri(tri,eps) =
    max(norm(tri[0]-tri[1]), norm(tri[1]-tri[2]), norm(tri[2]-tri[0])) < eps ;
    

/// Internal Function: _tri_class()
/// Usage:
///   class = _tri_class(triangle);
/// Topics: Geometry, Triangles
/// Description:
///   Return  1 if the triangle `tri` is CW.
///   Return  0 if the triangle `tri` has colinear vertices.
///   Return -1 if the triangle `tri` is CCW.
/// Arguments:
///   tri = A list of the three 2d vertices of a triangle.
///   eps = Tolerance in the geometrical tests.
function _tri_class(tri, eps=EPSILON) =
    let( crx = cross(tri[1]-tri[2],tri[0]-tri[2]) )
    abs( crx ) <= eps*norm(tri[1]-tri[2])*norm(tri[0]-tri[2]) ? 0 : sign( crx );
    
    
/// Internal Function: _pt_in_tri()
/// Usage:
///   class = _pt_in_tri(point, tri);
/// Topics: Geometry, Points, Triangles
/// Description:
//   For CW triangles `tri` :
///    return  1 if point is inside the triangle interior.
///    return =0 if point is on the triangle border.
///    return -1 if point is outside the triangle.
/// Arguments:
///   point = The point to check position of.
///   tri  =  A list of the three 2d vertices of a triangle.
///   eps = Tolerance in the geometrical tests.
function _pt_in_tri(point, tri, eps=EPSILON) = 
    min(  _tri_class([tri[0],tri[1],point],eps), 
          _tri_class([tri[1],tri[2],point],eps), 
          _tri_class([tri[2],tri[0],point],eps) );
        

/// Internal Function: _point_left_of_line2d()
/// Usage:
///   pt = point_left_of_line2d(point, line);
/// Topics: Geometry, Points, Lines
/// Description:
///   Return >0 if point is left of the line defined by `line`.
///   Return =0 if point is on the line.
///   Return <0 if point is right of the line.
/// Arguments:
///   point = The point to check position of.
///   line  = Array of two points forming the line segment to test against.
function _point_left_of_line2d(point, line, eps=EPSILON) =
    assert( is_vector(point,2) && is_vector(line*point, 2), "\nImproper input." )
//    cross(line[0]-point, line[1]-line[0]);
    _tri_class([point,line[1],line[0]],eps);
    

// Function: is_collinear()
// Synopsis: Determine if points are collinear.
// Topics: Geometry, Points, Collinearity
// See Also: is_collinear(), is_point_on_line(), point_line_distance(), line_from_points()
// Usage:
//   bool = is_collinear(a, [b, c], [eps]);
// Description:
//   Returns true if the points `a`, `b` and `c` are co-linear or if the list of points `a` is collinear.
// Arguments:
//   a = First point or list of points.
//   b = Second point or undef; it should be undef if `c` is undef
//   c = Third point or undef.
//   eps = Tolerance in geometric comparisons.  Default: `EPSILON` (1e-9)
function is_collinear(a, b, c, eps=EPSILON) =
    assert( is_path([a,b,c],dim=undef)
            || ( is_undef(b) && is_undef(c) && is_path(a,dim=undef) ),
            "\nInput should be 3 points or a list of points with same dimension.")
    assert( is_finite(eps) && (eps>=0), "\nThe tolerance should be a non-negative value." )
    let( points = is_def(c) ? [a,b,c]: a )
    len(points)<3 ? true :
    _noncollinear_triple(points,error=false,eps=eps) == [];


// Function: point_line_distance()
// Synopsis: Find shortest distance from point to a line, segment or ray.
// Topics: Geometry, Points, Lines, Distance
// See Also: is_collinear(), is_point_on_line(), point_line_distance(), line_from_points()
// Usage:
//   dist = point_line_distance(pt, line, [bounded]);
// Description:
//   Finds the shortest distance from the point `pt` to the specified line, segment or ray.
//   The bounded parameter specifies the whether the endpoints give a ray or segment.
//   By default assumes an unbounded line.  
// Arguments:
//   pt = A point to find the distance of from the line.
//   line = A list of two points defining a line.
//   bounded = a boolean or list of two booleans specifiying whether each end is bounded.  Default: false
// Example:
//   dist1 = point_line_distance([3,8], [[-10,0], [10,0]]);  // Returns: 8
//   dist2 = point_line_distance([3,8], [[-10,0], [10,0]],SEGMENT);  // Returns: 8
//   dist3 = point_line_distance([14,3], [[-10,0], [10,0]],SEGMENT);  // Returns: 5
function point_line_distance(pt, line, bounded=false) =
    assert(is_bool(bounded) || is_bool_list(bounded,2), "\n\"bounded\" is invalid.")
    assert( _valid_line(line) && is_vector(pt,len(line[0])),
            "\nInvalid line, invalid point or incompatible dimensions." )
    bounded == LINE ? _dist2line(pt-line[0],unit(line[1]-line[0]))
                    : norm(pt-line_closest_point(line,pt,bounded));

                           
// Function: segment_distance()
// Synopsis: Find smallest distance between two line semgnets.
// Topics: Geometry, Segments, Distance
// See Also: convex_collision(), convex_distance()
// Usage:
//   dist = segment_distance(seg1, seg2, [eps]);
// Description:
//   Returns the smallest distance of the points on two given line segments.
// Arguments:
//   seg1 = The list of two points representing the first line segment to check the distance of.
//   seg2 = The list of two points representing the second line segment to check the distance of.
//   eps = tolerance for point comparisons
// Example:
//   dist = segment_distance([[-14,3], [-15,9]], [[-10,0], [10,0]]);  // Returns: 5
//   dist2 = segment_distance([[-5,5], [5,-5]], [[-10,3], [10,-3]]);  // Returns: 0
function segment_distance(seg1, seg2,eps=EPSILON) =
    assert( is_matrix(concat(seg1,seg2),4), "\nInputs should be two valid segments." )
    convex_distance(seg1,seg2,eps);


// Function: line_normal()
// Synopsis: Return normal vector to given line. 
// Topics: Geometry, Lines
// See Also: line_intersection(), line_from_points()
// Usage:
//   vec = line_normal([P1,P2])
//   vec = line_normal(p1,p2)
// Description:
//   Returns the 2D normal vector to the given 2D line. This is otherwise known as the perpendicular vector counter-clockwise to the given ray.
// Arguments:
//   p1 = First point on 2D line.
//   p2 = Second point on 2D line.
// Example(2D):
//   p1 = [10,10];
//   p2 = [50,30];
//   n = line_normal(p1,p2);
//   stroke([p1,p2], endcap2="arrow2");
//   color("green") stroke([p1,p1+10*n], endcap2="arrow2");
//   color("blue") move_copies([p1,p2]) circle(d=2, $fn=12);
function line_normal(p1,p2) =
    is_undef(p2)
      ? assert( len(p1)==2 && !is_undef(p1[1]) , "\nInvalid input." )
        line_normal(p1[0],p1[1])
      : assert( _valid_line([p1,p2],dim=2), "\nInvalid line." )
        unit([p1.y-p2.y,p2.x-p1.x]);


// 2D Line intersection from two segments.
// This function returns [p,t,u] where p is the intersection point of
// the lines defined by the two segments, t is the proportional distance
// of the intersection point along s1, and u is the proportional distance
// of the intersection point along s2.  The proportional values run over
// the range of 0 to 1 for each segment, so if it is in this range, then
// the intersection lies on the segment.  Otherwise it lies somewhere on
// the extension of the segment.  If lines are parallel or coincident then
// it returns undef.

function _general_line_intersection(s1,s2,eps=EPSILON) =
    let(
        denominator = cross(s1[0]-s1[1],s2[0]-s2[1])
    )
    approx(denominator,0,eps=eps) ? undef :
    let(
        t = cross(s1[0]-s2[0],s2[0]-s2[1]) / denominator,
        u = cross(s1[0]-s2[0],s1[0]-s1[1]) / denominator
    )
    [s1[0]+t*(s1[1]-s1[0]), t, u];
                  

// Function: line_intersection()
// Synopsis: Compute intersection of two lines, segments or rays.
// Topics: Geometry, Lines
// See Also: line_normal(), line_from_points()
// Usage:
//    pt = line_intersection(line1, line2, [bounded1], [bounded2], [bounded=], [eps=]);
// Description:
//    Returns the intersection point of any two 2D lines, segments or rays.  Returns undef
//    if they do not intersect.  You specify a line by giving two distinct points on the
//    line.  You specify rays or segments by giving a pair of points and indicating
//    bounded[0]=true to bound the line at the first point, creating rays based at l1[0] and l2[0],
//    or bounded[1]=true to bound the line at the second point, creating the reverse rays bounded
//    at l1[1] and l2[1].  If bounded=[true, true] then you have segments defined by their two
//    endpoints.  By using bounded1 and bounded2 you can mix segments, rays, and lines as needed.
//    You can set the bounds parameters to true as a shorthand for [true,true] to sepcify segments.
// Arguments:
//    line1 = List of two points in 2D defining the first line, segment or ray
//    line2 = List of two points in 2D defining the second line, segment or ray
//    bounded1 = boolean or list of two booleans defining which ends are bounded for line1.  Default: [false,false]
//    bounded2 = boolean or list of two booleans defining which ends are bounded for line2.  Default: [false,false]
//    ---
//    bounded = boolean or list of two booleans defining which ends are bounded for both lines.  The bounded1 and bounded2 parameters override this if both are given.
//    eps = tolerance for geometric comparisons.  Default: `EPSILON` (1e-9)
// Example(2D):  The segments do not intersect but the lines do in this example. 
//    line1 = 10*[[9, 4], [5, 7]];
//    line2 = 10*[[2, 3], [6, 5]];
//    stroke(line1, endcaps="arrow2");
//    stroke(line2, endcaps="arrow2");
//    isect = line_intersection(line1, line2);
//    color("red") translate(isect) circle(r=1,$fn=12);
// Example(2D): Specifying a ray and segment using the shorthand variables.
//    line1 = 10*[[0, 2], [4, 7]];
//    line2 = 10*[[10, 4], [3, 4]];
//    stroke(line1);
//    stroke(line2, endcap2="arrow2");
//    isect = line_intersection(line1, line2, SEGMENT, RAY);
//    color("red") translate(isect) circle(r=1,$fn=12);
// Example(2D): Here we use the same example as above, but specify two segments using the bounded argument.
//    line1 = 10*[[0, 2], [4, 7]];
//    line2 = 10*[[10, 4], [3, 4]];
//    stroke(line1);
//    stroke(line2);
//    isect = line_intersection(line1, line2, bounded=true);  // Returns undef
function line_intersection(line1, line2, bounded1, bounded2, bounded, eps=EPSILON) =
    assert( is_finite(eps) && (eps>=0), "\nThe tolerance should be a non-negative value." )
    assert( _valid_line(line1,dim=2,eps=eps), "\nFirst line invalid.")
    assert( _valid_line(line2,dim=2,eps=eps), "\nSecond line invalid.")
    assert( is_undef(bounded) || is_bool(bounded) || is_bool_list(bounded,2), "\nInvalid value for \"bounded\".")
    assert( is_undef(bounded1) || is_bool(bounded1) || is_bool_list(bounded1,2), "\nInvalid value for \"bounded1\".")
    assert( is_undef(bounded2) || is_bool(bounded2) || is_bool_list(bounded2,2), "\nInvalid value for \"bounded2\".")
    let(isect = _general_line_intersection(line1,line2,eps=eps))
    is_undef(isect) ? undef :
    let(
        bounded1 = force_list(first_defined([bounded1,bounded,false]),2),
        bounded2 = force_list(first_defined([bounded2,bounded,false]),2),
        good =  (!bounded1[0] || isect[1]>=0-eps)
             && (!bounded1[1] || isect[1]<=1+eps)
             && (!bounded2[0] || isect[2]>=0-eps)
             && (!bounded2[1] || isect[2]<=1+eps)
    )
    good ? isect[0] : undef;
    

// Function: line_closest_point()
// Synopsis: Find point on given line, segment or ray that is closest to a given point. 
// Topics: Geometry, Lines, Distance
// See Also: line_normal(), point_line_distance()
// Usage:
//   pt = line_closest_point(line, pt, [bounded]);
// Description:
//   Returns the point on the given line, segment or ray that is closest to the given point `pt`.
//   The inputs `line` and `pt` args should be of the same dimension.  The parameter bounded indicates
//   whether the points of `line` should be treated as endpoints. 
// Arguments:
//   line = A list of two points that are on the unbounded line.
//   pt = The point to find the closest point on the line to.
//   bounded = boolean or list of two booleans indicating that the line is bounded at that end.  Default: [false,false]
// Example(2D):
//   line = [[-30,0],[30,30]];
//   pt = [-32,-10];
//   p2 = line_closest_point(line,pt);
//   stroke(line, endcaps="arrow2");
//   color("blue") translate(pt) circle(r=1,$fn=12);
//   color("red") translate(p2) circle(r=1,$fn=12);
// Example(2D):  If the line is bounded on the left you get the endpoint instead
//   line = [[-30,0],[30,30]];
//   pt = [-32,-10];
//   p2 = line_closest_point(line,pt,bounded=[true,false]);
//   stroke(line, endcap2="arrow2");
//   color("blue") translate(pt) circle(r=1,$fn=12);
//   color("red") translate(p2) circle(r=1,$fn=12);
// Example(2D):  In this case it doesn't matter how bounded is set.  Using SEGMENT is the most restrictive option. 
//   line = [[-30,0],[30,30]];
//   pt = [-5,0];
//   p2 = line_closest_point(line,pt,SEGMENT);
//   stroke(line);
//   color("blue") translate(pt) circle(r=1,$fn=12);
//   color("red") translate(p2) circle(r=1,$fn=12);
// Example(2D):  The result here is the same for a line or a ray. 
//   line = [[-30,0],[30,30]];
//   pt = [40,25];
//   p2 = line_closest_point(line,pt,RAY);
//   stroke(line, endcap2="arrow2");
//   color("blue") translate(pt) circle(r=1,$fn=12);
//   color("red") translate(p2) circle(r=1,$fn=12);
// Example(2D):  But with a segment we get a different result
//   line = [[-30,0],[30,30]];
//   pt = [40,25];
//   p2 = line_closest_point(line,pt,SEGMENT);
//   stroke(line);
//   color("blue") translate(pt) circle(r=1,$fn=12);
//   color("red") translate(p2) circle(r=1,$fn=12);
// Example(2D): The shorthand RAY uses the first point as the base of the ray.  But you can specify a reversed ray directly, and in this case the result is the same as the result above for the segment.
//   line = [[-30,0],[30,30]];
//   pt = [40,25];
//   p2 = line_closest_point(line,pt,[false,true]);
//   stroke(line,endcap1="arrow2");
//   color("blue") translate(pt) circle(r=1,$fn=12);
//   color("red") translate(p2) circle(r=1,$fn=12);
// Example(FlatSpin,VPD=200,VPT=[0,0,15]): A 3D example
//   line = [[-30,-15,0],[30,15,30]];
//   pt = [5,5,5];
//   p2 = line_closest_point(line,pt);
//   stroke(line, endcaps="arrow2");
//   color("blue") translate(pt) sphere(r=1,$fn=12);
//   color("red") translate(p2) sphere(r=1,$fn=12);
function line_closest_point(line, pt, bounded=false) =
    assert(_valid_line(line), "\nInvalid line.")
    assert(is_vector(pt, len(line[0])), "\nInvalid point or incompatible dimensions.")
    assert(is_bool(bounded) || is_bool_list(bounded,2), "\nInvalid value for \"bounded\".")
    let(
        bounded = force_list(bounded,2)
    )
    bounded==[false,false] ?
          let( n = unit( line[0]- line[1]) )
          line[1] + ((pt- line[1]) * n) * n
    : bounded == [true,true] ?
          pt + _closest_s1([line[0]-pt, line[1]-pt])[0]
    : 
          let(
               ray = bounded==[true,false] ? line : reverse(line),
               seglen = norm(ray[1]-ray[0]),
               segvec = (ray[1]-ray[0])/seglen,
               projection = (pt-ray[0]) * segvec
          )
          projection<=0 ? ray[0] :
                          ray[0] + projection*segvec;
            

// Function: line_from_points()
// Synopsis: Given a list of collinear points, return the line they define. 
// Topics: Geometry, Lines, Points
// Usage:
//   line = line_from_points(points, [check_collinear], [eps]);
// Description:
//   Given a list of 2 or more collinear points, returns two points defining a line containing them.
//   If `check_collinear=true` a line is returned if the points are collinear; otherwise `undef` is returned.
//   if `check_collinear=false`, then the collinearity test is skipped and a best-fit line is returned (where "best fit"
//   means minimal perpendiclular point-line distances, not minimal vertical distances as one would get with least-squares fitting).
// Arguments:
//   points = The list of points to find the line through.
//   check_collinear = If true, don't verify that all points are collinear.  Default: false
//   eps = How much variance is allowed in testing each point against the line.  Default: `EPSILON` (1e-9)
// Example(FlatSpin,VPD=250): A line fitted to a cloud of points.
//   points = rot(45, v=[-0.5,1,0],
//       p=random_points(100,3,scale=[5,5,50],seed=47));
//   line = line_from_points(points);
//   stroke(line, color="#06f");
//   %move_copies(points) sphere(d=2, $fn=12);

function _line_greatest_distance(points,line) = // internal function
    is_undef(line) ? INF
    : let(d = [ for(p=points) point_line_distance(p, line) ])
        max(d);

function line_from_points(points, check_collinear=false, eps=EPSILON, fast) =
    assert( is_path(points), "\nInvalid point list." )
    assert( is_finite(eps) && (eps>=0), "\nThe tolerance should be a non-negative value." )
    len(points) == 2
      ? points 
      : let(
            dep = is_def(fast) ? echo("In line_from_points() the 'fast' parameter is deprecated; use 'check_collinear' instead.") true : false,
            check = dep ? fast : check_collinear,
            twod = is_path(points,2),
            covmix = _covariance_evec_eval(path3d(points), 0), // pass 0 to use largest eigenvalue
            pm     = covmix[0], // point mean
            evec   = unit(covmix[1]), // normalized eigenvector corresponding to largest eigenvalue
            maxext = let(b=pointlist_bounds(points)) norm(b[1]-b[0])/2,
            line3d = [pm-evec*maxext, pm+evec*maxext],
            line = twod ? path2d(line3d) : line3d
        )
        check && _line_greatest_distance(points,line)>eps ? undef
        : line;



// Section: Planes


// Function: is_coplanar()
// Synopsis: Check if 3d points are coplanar and not collinear.  
// Topics: Geometry, Coplanarity
// See Also: plane3pt(), plane3pt_indexed(), plane_from_normal(), plane_from_points(), plane_from_polygon()
// Usage:
//   bool = is_coplanar(points,[eps]);
// Description:
//   Returns true if the given 3D points are non-collinear and are on a plane.
// Arguments:
//   points = The points to test.
//   eps = Tolerance in geometric comparisons.  Default: `EPSILON` (1e-9)
function is_coplanar(points, eps=EPSILON) =
    assert( is_path(points,dim=3) , "\nInput should be a list of 3D points." )
    assert( is_finite(eps) && eps>=0, "\nThe tolerance should be a non-negative value." )
    len(points)<=2 ? false
      : let( ip = _noncollinear_triple(points,error=false,eps=eps) )
        ip == [] ? false :
        let( plane  = plane3pt(points[ip[0]],points[ip[1]],points[ip[2]]) )
        _pointlist_greatest_distance(points,plane) < eps;



// Function: plane3pt()
// Synopsis: Return a plane from 3 points. 
// Topics: Geometry, Planes
// See Also: plane3pt(), plane3pt_indexed(), plane_from_normal(), plane_from_points(), plane_from_polygon()
// Usage:
//   plane = plane3pt(p1, p2, p3);
//   plane = plane3pt([p1, p2, p3]);
// Description:
//   Generates the normalized cartesian equation of a plane from three 3d points.
//   Returns [A,B,C,D] where Ax + By + Cz = D is the equation of a plane.
//   Returns undef, if the points are collinear.
// Arguments:
//   p1 = The first point on the plane.
//   p2 = The second point on the plane.
//   p3 = The third point on the plane.
function plane3pt(p1, p2, p3) =
    is_undef(p2) && is_undef(p3) && is_path(p1,dim=3) ? plane3pt(p1[0],p1[1],p1[2])
  : assert( is_path([p1,p2,p3],dim=3) && len(p1)==3,
            "\nInvalid points or incompatible dimensions." )
    let(
        crx = cross(p3-p1, p2-p1),
        nrm = norm(crx)
    ) approx(nrm,0) ? undef :
    concat(crx, crx*p1)/nrm;


// Function: plane3pt_indexed()
// Synopsis: Given list of 3d points and 3 indices, return the plane they define.  
// Topics: Geometry, Planes
// See Also: plane3pt(), plane3pt_indexed(), plane_from_normal(), plane_from_points(), plane_from_polygon()
// Usage:
//   plane = plane3pt_indexed(points, i1, i2, i3);
// Description:
//   Given a list of 3d points, and the indices of three of those points,
//   generates the normalized cartesian equation of a plane that those points all
//   lie on. If the points are not collinear, returns [A,B,C,D] where Ax+By+Cz=D is the equation of a plane.
//   If they are collinear, returns [].
// Arguments:
//   points = A list of points.
//   i1 = The index into `points` of the first point on the plane.
//   i2 = The index into `points` of the second point on the plane.
//   i3 = The index into `points` of the third point on the plane.
function plane3pt_indexed(points, i1, i2, i3) =
    is_undef(i3) && is_undef(i2) && is_vector(i1) ? plane3pt_indexed(points, i1[0], i1[1], i1[2])
  :
    assert( is_vector([i1,i2,i3]) && min(i1,i2,i3)>=0 && is_list(points) && max(i1,i2,i3)<len(points),
            "\nInvalid or out of range indices." )
    assert( is_path([points[i1], points[i2], points[i3]],dim=3),
            "\nImproper points or improper dimensions." )
    let(
        p1 = points[i1],
        p2 = points[i2],
        p3 = points[i3]
    ) plane3pt(p1,p2,p3);


// Function: plane_from_normal()
// Synopsis: Return plane defined by normal vector and a point. 
// Topics: Geometry, Planes
// See Also: plane3pt(), plane3pt_indexed(), plane_from_normal(), plane_from_points(), plane_from_polygon()
// Usage:
//   plane = plane_from_normal(normal, [pt])
// Description:
//   Returns a plane defined by a normal vector and a point.  If you omit `pt`, you get a plane
//   passing through the origin.  
// Arguments:
//   normal = Normal vector to the plane to find.
//   pt = Point 3D on the plane to find.
// Example:
//   plane_from_normal([0,0,1], [2,2,2]);  // Returns the xy plane passing through the point (2,2,2)
function plane_from_normal(normal, pt=[0,0,0]) =
    assert( is_matrix([normal,pt],2,3) && !approx(norm(normal),0),
            "\nInputs `normal` and `pt` should be 3d vectors/points and `normal` cannot be zero." )
    concat(normal, normal*pt) / norm(normal);


// Eigenvalues for a 3×3 symmetrical matrix in decreasing order
// Based on: https://en.wikipedia.org/wiki/Eigenvalue_algorithm
function _eigenvals_symm_3(M) =
  let( p1 = pow(M[0][1],2) + pow(M[0][2],2) + pow(M[1][2],2) )
  (p1<EPSILON)
  ? -sort(-[ M[0][0], M[1][1], M[2][2] ]) //  diagonal matrix: eigenvals in decreasing order
  : let(  q  = (M[0][0]+M[1][1]+M[2][2])/3,
          B  = (M - q*ident(3)),
          dB = [B[0][0], B[1][1], B[2][2]],
          p2 = dB*dB + 2*p1,
          p  = sqrt(p2/6),
          r  = det3(B/p)/2,
          ph = acos(constrain(r,-1,1))/3,
          e1 = q + 2*p*cos(ph),
          e3 = q + 2*p*cos(ph+120),
          e2 = 3*q - e1 - e3 )
    [ e1, e2, e3 ];


// the i-th normalized eigenvector of a 3×3 symmetrical matrix M from its eigenvalues
// using Cayley–Hamilton theorem according to:
// https://en.wikipedia.org/wiki/Eigenvalue_algorithm
function _eigenvec_symm_3(M,evals,i=0) =
    let(
        I = ident(3),
        A = (M - evals[(i+1)%3]*I) * (M - evals[(i+2)%3]*I) ,
        k = max_index( [for(i=[0:2]) norm(A[i]) ])
    )
    norm(A[k])<EPSILON ? I[k] : A[k]/norm(A[k]);


// finds the eigenvector corresponding to the smallest eigenvalue of the covariance matrix of a pointlist
// returns the mean of the points, the eigenvector and the greatest eigenvalue
function _covariance_evec_eval(points, eigenvalue_id) =
    let(  pm    = sum(points)/len(points), // mean point
          Y     = [ for(i=[0:len(points)-1]) points[i] - pm ],
          M     = transpose(Y)*Y ,     // covariance matrix
          evals = _eigenvals_symm_3(M), // eigenvalues in decreasing order
          evec  = _eigenvec_symm_3(M,evals,i=eigenvalue_id) )
    [pm, evec, evals[0] ];
    

// Function: plane_from_points()
// Synopsis: Return plane defined by a set of 3D points, with arbitrary normal direction.
// Topics: Geometry, Planes, Points
// See Also: plane3pt(), plane3pt_indexed(), plane_from_normal(), plane_from_points(), plane_from_polygon()
// Usage:
//   plane = plane_from_points(points, [check_coplanar], [eps]);
// Description:
//   Given a list of 3 or more 3D points, returns the coefficients of the normalized cartesian equation of a plane,
//   that is [A,B,C,D] where Ax+By+Cz=D is the equation of the plane and norm([A,B,C])=1.
//   .
//   If `check_coplanar=true`, the plane is returned if the points are all coplanar; otherwise `undef` is returned if the points are collinear or not coplanar.
//   If `check_coplanar=false`, then the coplanarity check is skipped and a best-fit plane is returned (where "best fit"
//   means minimal perpendiclular point-plane distances, not minimal vertical distances as one would get with least-squares fitting).
//   The direction of the plane's normal is arbitrary and is not determined by the point order, unlike {{plane_from_polygon()}}.
// Arguments:
//   points = The list of points to find the best-fit plane.
//   check_coplanar = If true, verify the point coplanarity within `eps` tolerance.  Default: false
//   eps = Tolerance in geometric comparisons.  Default: `EPSILON` (1e-9)
// Example(FlatSpin,VPD=320,VPT=[-2,5,-2]): 100 non-coplanar random points (yellow spheres) distributed in a volume, showing the best-fit plane (transparent square) with its normal vector.
//   points = rot(45, v=[-0.3,1,0],
//       p=random_points(100,3,scale=[50,50,15],seed=47));
//   plane = plane_from_points(points);
//   move_copies(points) sphere(d=3, $fn=12);
//   cp = mean(points);
//   move(cp) rot(from=UP,to=plane_normal(plane)) {
//       color("#06f") anchor_arrow(50, flag=false);
//       %linear_extrude(0.1) square(100, center=true);
//   }
function plane_from_points(points, check_coplanar=false, eps=EPSILON, fast) =
    assert( is_path(points,dim=3), "\nImproper 3d point list." )
    assert( is_finite(eps) && (eps>=0), "\nThe tolerance should be a non-negative value." )
    len(points) == 3
      ? plane3pt(points[0],points[1],points[2]) 
      : let(
            dep = is_def(fast) ? echo("In plane_from_points() the 'fast' parameter is deprecated; use 'check_coplanar' instead.") true : false,
            check = dep ? fast : check_coplanar,
            covmix = _covariance_evec_eval(points,2),
            pm     = covmix[0], // point mean
            evec   = covmix[1], // eigenvector corresponding to smallest eigenvalue
            eval0  = covmix[2], // smallest eigenvalue
            plane  = [ each evec, pm*evec]
        )
        check && _pointlist_greatest_distance(points,plane)>eps*eval0 ? undef :
        plane ;


// Function: plane_from_polygon()
// Synopsis: Given a 3d planar polygon, returns directed plane.  
// Topics: Geometry, Planes, Polygons
// See Also: plane3pt(), plane3pt_indexed(), plane_from_normal(), plane_from_points(), plane_from_polygon()
// Usage:
//   plane = plane_from_polygon(points, [check_coplanar], [eps]);
// Description:
//   Given a 3D planar polygon, returns the normalized cartesian equation of its plane. 
//   Returns [A,B,C,D] where Ax+By+Cz=D is the equation of the plane where norm([A,B,C])=1.
//   If not all the points in the polygon are coplanar, then [] is returned.
//   If `check_coplanar=true` and the points in the list are collinear or not coplanar, then `undef` is returned.
//   if `check_coplanar=false`, then the coplanarity test is skipped and a plane passing through 3 non-collinear arbitrary points is returned.
//   The normal direction is determined by the order of the points and the right hand rule.
// Arguments:
//   poly = The planar 3D polygon to find the plane of.
//   check_coplanar = If false, doesn't verify that all points in the polygon are coplanar.  Default: true
//   eps = Tolerance in geometric comparisons.  Default: `EPSILON` (1e-9)
// Example(3D):
//   xyzpath = rot(45, v=[0,1,0], p=path3d(star(n=5,step=2,d=100), 70));
//   plane = plane_from_polygon(xyzpath);
//   #stroke(xyzpath,closed=true,width=3);
//   cp = centroid(xyzpath);
//   move(cp) rot(from=UP,to=plane_normal(plane)) anchor_arrow(45);
function plane_from_polygon(poly, check_coplanar=true, eps=EPSILON, fast) =
    assert( is_path(poly,dim=3), "\nInvalid polygon." )
    assert( is_finite(eps) && (eps>=0), "\nThe tolerance should be a non-negative value." )
    let(
        dep = is_def(fast) ? echo("In plane_from_polygon() the 'fast' parameter is deprecated; use 'check_coplanar' instead.") true : false,
        check = dep ? fast : check_coplanar,
        poly_normal = polygon_normal(poly)
    )
    is_undef(poly_normal) ? undef :
    let(
        plane = plane_from_normal(poly_normal, poly[0])
    )
    !check ? plane : are_points_on_plane(poly, plane, eps=eps) ? plane : undef;


// Function: plane_normal()
// Synopsis: Returns the normal vector to a plane. 
// Topics: Geometry, Planes
// See Also: plane3pt(), plane3pt_indexed(), plane_from_normal(), plane_from_points(), plane_from_polygon(), plane_normal(), plane_offset()
// Usage:
//   vec = plane_normal(plane);
// Description:
//   Returns the unit length normal vector for the given plane.
// Arguments:
//   plane = The `[A,B,C,D]` plane definition where `Ax+By+Cz=D` is the formula of the plane.
function plane_normal(plane) =
    assert( _valid_plane(plane), "\nInvalid input plane." )
    unit([plane.x, plane.y, plane.z]);


// Function: plane_offset()
// Synopsis: Returns the signed offset of the plane from the origin.  
// Topics: Geometry, Planes
// See Also: plane3pt(), plane3pt_indexed(), plane_from_normal(), plane_from_points(), plane_from_polygon(), plane_normal(), plane_offset()
// Usage:
//   d = plane_offset(plane);
// Description:
//   Returns coeficient D of the normalized plane equation `Ax+By+Cz=D`, or the scalar offset of the plane from the origin.
//   This value may be negative.
//   The absolute value of this coefficient is the distance of the plane from the origin.
// Arguments:
//   plane = The `[A,B,C,D]` plane definition where `Ax+By+Cz=D` is the formula of the plane.
function plane_offset(plane) =
    assert( _valid_plane(plane), "\nInvalid input plane." )
    plane[3]/norm([plane.x, plane.y, plane.z]);



// Returns [POINT, U] if line intersects plane at one point, where U is zero at line[0] and 1 at line[1]
// Returns [LINE, undef] if the line is on the plane.
// Returns undef if line is parallel to, but not on the given plane.
function _general_plane_line_intersection(plane, line, eps=EPSILON) =
    let(
        a = plane*[each line[0],-1],         //  evaluation of the plane expression at line[0]
        b = plane*[each(line[1]-line[0]),0]  // difference between the plane expression evaluation at line[1] and at line[0]
    )
    approx(b,0,eps)                          // is  (line[1]-line[0]) "parallel" to the plane ?
      ? approx(a,0,eps)                      // is line[0] on the plane ?
        ? [line,undef]                       // line is on the plane
        : undef                              // line is parallel but not on the plane
      : [ line[0]-a/b*(line[1]-line[0]), -a/b ];


/// Internal Function: normalize_plane()
/// Usage:
///   nplane = normalize_plane(plane);
/// Topics: Geometry, Planes
/// Description:
///   Returns a new representation [A,B,C,D] of `plane` where norm([A,B,C]) is equal to one.
function _normalize_plane(plane) =
    assert( _valid_plane(plane), str("\nInvalid plane ",plane, ".") )
    plane/norm(point3d(plane));


// Function: plane_line_intersection()
// Synopsis: Returns the intersection of a plane and 3d line, segment or ray.  
// Topics: Geometry, Planes, Lines, Intersection
// See Also: plane3pt(), plane_from_normal(), plane_from_points(), plane_from_polygon(), line_intersection()
// Usage:
//   pt = plane_line_intersection(plane, line, [bounded], [eps]);
// Description:
//   Takes a line, and a plane [A,B,C,D] where the equation of that plane is `Ax+By+Cz=D`.
//   If `line` intersects `plane` at one point, then that intersection point is returned.
//   If `line` lies on `plane`, then the original given `line` is returned.
//   If `line` is parallel to, but not on `plane`, then undef is returned.
// Arguments:
//   plane = The [A,B,C,D] values for the equation of the plane.
//   line = A list of two distinct 3D points that are on the line.
//   bounded = If false, the line is considered unbounded.  If true, it is treated as a bounded line segment.  If given as `[true, false]` or `[false, true]`, the boundedness of the points are specified individually, allowing the line to be treated as a half-bounded ray.  Default: false (unbounded)
//   eps = Tolerance in geometric comparisons.  Default: `EPSILON` (1e-9)
function plane_line_intersection(plane, line, bounded=false, eps=EPSILON) =
    assert( is_finite(eps) && eps>=0, "\nThe tolerance should be a positive number." )
    assert(_valid_plane(plane,eps=eps) && _valid_line(line,dim=3,eps=eps), "\nInvalid plane and/or 3d line.")
    assert(is_bool(bounded) || is_bool_list(bounded,2), "\nInvalid bound condition.")
    let(
        bounded = is_list(bounded)? bounded : [bounded, bounded],
        res = _general_plane_line_intersection(plane, line, eps=eps)
    ) is_undef(res) ? undef :
    is_undef(res[1]) ? res[0] :
    bounded[0] && res[1]<0 ? undef :
    bounded[1] && res[1]>1 ? undef :
    res[0];



// Function: plane_intersection()
// Synopsis: Returns the intersection of two or three planes.  
// Topics: Geometry, Planes, Intersection
// See Also: plane3pt(), plane_from_normal(), plane_from_points(), plane_from_polygon(), line_intersection()
// Usage:
//   line = plane_intersection(plane1, plane2)
//   pt = plane_intersection(plane1, plane2, plane3)
// Description:
//   Compute the point that is the intersection of the three planes, or the line intersection of two planes.
//   If you give three planes the intersection is returned as a point.  If you give two planes the intersection
//   is returned as a list of two points on the line of intersection.  If any two input planes are parallel
//   or coincident then returns undef.
// Arguments:
//   plane1 = The [A,B,C,D] coefficients for the first plane equation `Ax+By+Cz=D`.
//   plane2 = The [A,B,C,D] coefficients for the second plane equation `Ax+By+Cz=D`.
//   plane3 = The [A,B,C,D] coefficients for the third plane equation `Ax+By+Cz=D`.
function plane_intersection(plane1,plane2,plane3) =
    assert( _valid_plane(plane1) && _valid_plane(plane2) && (is_undef(plane3) ||_valid_plane(plane3)),
                "\nThe input must be 2 or 3 planes." )
    is_def(plane3)
      ? let(
            matrix = [for(p=[plane1,plane2,plane3]) point3d(p)],
            rhs = [for(p=[plane1,plane2,plane3]) p[3]]
        )
        linear_solve(matrix,rhs)
      : let( normal = cross(plane_normal(plane1), plane_normal(plane2)) )
        approx(norm(normal),0) ? undef :
        let(
            matrix = [for(p=[plane1,plane2]) point3d(p)],
            rhs = [plane1[3], plane2[3]],
            point = linear_solve(matrix,rhs)
        )
        point==[]? undef:
        [point, point+normal];



// Function: plane_line_angle()
// Synopsis: Returns the angle between a plane and a 3d line. 
// Topics: Geometry, Planes, Lines, Angle
// See Also: plane3pt(), plane_from_normal(), plane_from_points(), plane_from_polygon(), plane_intersection(), line_intersection(), vector_angle()
// Usage:
//   angle = plane_line_angle(plane,line);
// Description:
//   Compute the angle between a plane [A, B, C, D] and a 3d line, specified as a pair of 3d points [p1,p2].
//   The resulting angle is signed, with the sign positive if the vector p2-p1 lies above the plane, on
//   the same side of the plane as the plane's normal vector.
function plane_line_angle(plane, line) =
    assert( _valid_plane(plane), "\nInvalid plane." )
    assert( _valid_line(line,dim=3), "\nInvalid 3d line." )
    let(
        linedir   = unit(line[1]-line[0]),
        normal    = plane_normal(plane),
        sin_angle = linedir*normal,
        cos_angle = norm(cross(linedir,normal))
    ) atan2(sin_angle,cos_angle);



// Function: plane_closest_point()
// Synopsis: Returns the orthogonal projection of points onto a plane. 
// Topics: Geometry, Planes, Projection
// See Also: plane3pt(), line_closest_point(), point_plane_distance()
// Usage:
//   pts = plane_closest_point(plane, points);
// Description:
//   Given a plane definition `[A,B,C,D]`, where `Ax+By+Cz=D`, and a list of 2d or
//   3d points, return the closest 3D orthogonal projection of the points on the plane.
//   In other words, for every point given, returns the closest point to it on the plane.
//   If points is a single point then returns a single point result.  
// Arguments:
//   plane = The `[A,B,C,D]` plane definition where `Ax+By+Cz=D` is the formula of the plane.
//   points = List of points to project
// Example(FlatSpin,VPD=500,VPT=[2,20,10]):
//   points = move([10,20,30], p=yrot(25, p=path3d(circle(d=100, $fn=36))));
//   plane = plane_from_normal([1,0,1]);
//   proj = plane_closest_point(plane,points);
//   color("red") move_copies(points) sphere(d=4,$fn=12);
//   color("blue") move_copies(proj) sphere(d=4,$fn=12);
//   move(centroid(proj)) {
//       rot(from=UP,to=plane_normal(plane)) {
//           anchor_arrow(50);
//           %cube([120,150,0.1],center=true);
//       }
//   }
function plane_closest_point(plane, points) =
    is_vector(points,3) ? plane_closest_point(plane,[points])[0] :
    assert( _valid_plane(plane), "\nInvalid plane." )
    assert( is_matrix(points,undef,3), "\nMust supply 3D points.")
    let(
        plane = _normalize_plane(plane),
        n = point3d(plane)
    )
    [for(pi=points) pi - (pi*n - plane[3])*n];


// Function: point_plane_distance()
// Synopsis: Determine distance between a point and plane. 
// Topics: Geometry, Planes, Distance
// See Also: plane3pt(), line_closest_point(), plane_closest_point()
// Usage:
//   dist = point_plane_distance(plane, point)
// Description:
//   Given a plane as [A,B,C,D] where the cartesian equation for that plane
//   is Ax+By+Cz=D, determines how far from that plane the given point is.
//   The returned distance is positive if the point is above the
//   plane, meaning on the side where the plane normal points.  
//   If the point is below the plane, then the distance returned
//   is negative.  The normal of the plane is [A,B,C].
// Arguments:
//   plane = The `[A,B,C,D]` plane definition where `Ax+By+Cz=D` is the formula of the plane.
//   point = The distance evaluation point.
function point_plane_distance(plane, point) =
    assert( _valid_plane(plane), "\nInvalid input plane." )
    assert( is_vector(point,3), "\nThe point should be a 3D point." )
    let( plane = _normalize_plane(plane) )
    point3d(plane)* point - plane[3];



// the maximum distance from points to the plane
function _pointlist_greatest_distance(points,plane) =
    let(
        normal = [plane[0],plane[1],plane[2]],
        pt_nrm = points*normal
    )
    max( max(pt_nrm) - plane[3], -min(pt_nrm) + plane[3]) / norm(normal);


// Function: are_points_on_plane()
// Synopsis: Determine if all of the listed points are on a plane. 
// Topics: Geometry, Planes, Points
// See Also: plane3pt(), line_closest_point(), plane_closest_point(), is_coplanar()
// Usage:
//   bool = are_points_on_plane(points, plane, [eps]);
// Description:
//   Returns true if the given 3D points are on the given plane.
// Arguments:
//   plane = The plane to test the points on.
//   points = The list of 3D points to test.
//   eps = Tolerance in geometric comparisons.  Default: `EPSILON` (1e-9)
function are_points_on_plane(points, plane, eps=EPSILON) =
    assert( _valid_plane(plane), "\nInvalid plane." )
    assert( is_matrix(points,undef,3) && len(points)>0, "\nInvalid pointlist." ) // using is_matrix it accepts len(points)==1
    assert( is_finite(eps) && eps>=0, "\nThe tolerance should be a positive number." )
    _pointlist_greatest_distance(points,plane) < eps;


/// Internal Function: is_point_above_plane()
/// Usage:
///   bool = _is_point_above_plane(plane, point);
/// Topics: Geometry, Planes
/// Description:
///   Given a plane as [A,B,C,D] where the cartesian equation for that plane
///   is Ax+By+Cz=D, determines if the given 3D point is on the side of that
///   plane that the normal points toward.  The normal of the plane is the
///   same as [A,B,C].
/// Arguments:
///   plane = The [A,B,C,D] coefficients for the first plane equation `Ax+By+Cz=D`.
///   point = The 3D point to test.
function _is_point_above_plane(plane, point) =
    point_plane_distance(plane, point) > EPSILON;


// Module: show_plane()
// Synopsis: Display (part of) a plane
// SynTags: Geom
// Topics: Planes
// Usage:
//   show_plane(plane, size, [offset]) [ATTACHMENTS];
// Description:
//   Display a rectangular portion of the specified plane for debugging or visualization purposes.
//   The size parameter specifies the size of the plane when projected along the coordinate axis that is closest to
//   the plane's normal vector.  The offset parameter shifts the plane location perpendicular to the normal vector.
//   This object is a non-manifold VNF (it has edges) so it will not render.
// Arguments:
//   plane = Plane to display
//   size = scalar or 2-vector size parameter
//   offset = scalar of 2-vector offset
// Example(3D):
//   sphere(r=15,$fn=48);
//   plane = plane_from_normal([2,-3,9],[4,-5,12]);
//   %show_plane(plane, [35,25], [4,-7]);

module show_plane(plane, size, offset=0)
{
    size = force_list(size,2);
    offset = force_list(offset, 2, 0);
    checks =
      assert(is_vector(size,2), "\nThe size parameter must be a scalar or 2-vector")
      assert(is_vector(offset,2), "\nThe offset parameter must be a scalar or 2-vector");
    pts = move(offset,rect(size));
    axes = [UP, BACK, RIGHT];
    n = plane_normal(plane);
    ang = [for(v=axes) abs(plane_line_angle(plane, [CTR,v]))];
    axis = axes[max_index(ang)];
    face = [for(pt=pts)
             axis==UP? [pt.x,pt.y,(plane[3]-plane.x*pt.x-plane.y*pt.y)/plane.z]
           : axis==BACK? [pt[0],(plane[3]-plane.x*pt[0]-plane.z*pt[1])/plane.y,pt[1]]
           :             [(plane[3]-plane.y*pt[0]-plane.z*pt[1])/plane.x,pt[0],pt[1]]
           ];
    vnf = [face, [count(face)]];
    vnf_polyhedron(vnf) children();
}



// Section: Circle Calculations

// Function: circle_line_intersection()
// Synopsis: Find the intersection points between a 2d circle and a line, ray or segment.
// Topics: Geometry, Circles, Lines, Intersection
// See Also: circle_line_intersection(), circle_circle_intersection(), circle_2tangents(), circle_3points(), circle_point_tangents(), circle_circle_tangents()
// Usage:
//   pts = circle_line_intersection(r|d=, cp, line, [bounded], [eps=]);
// Description:
//   Find intersection points between a 2D circle and a line, ray or segment specified by two points.
//   By default the line is unbounded.  Returns the list of zero or more intersection points.
// Arguments:
//   r = Radius of circle
//   cp = Center of circle
//   line = Two points defining the line
//   bounded = False for unbounded line, true for a segment, or a vector [false,true] or [true,false] to specify a ray with the first or second end unbounded.  Default: false
//   ---
//   d = Diameter of circle
//   eps = Epsilon used for identifying the case with one solution.  Default: `1e-9`
// Example(2D): Standard intersection returns two points.
//   line = [[-15,2], [15,7]];
//   cp = [1,2]; r = 10;
//   translate(cp) circle(r=r);
//   color("black") stroke(line, endcaps="arrow2", width=0.5);
//   isects = circle_line_intersection(r=r, cp=cp, line=line);
//   color("red") move_copies(isects) circle(d=1);
// Example(2D): Tangent intersection returns one point.
//   line = [[-10,12], [10,12]];
//   cp = [1,2]; r = 10;
//   translate(cp) circle(r=r);
//   color("black") stroke(line, endcaps="arrow2", width=0.5);
//   isects = circle_line_intersection(r=r, cp=cp, line=line);
//   color("#f44") move_copies(isects) circle(d=1);
// Example(2D): A bounded ray might intersect only in one direction.
//   line = [[-5,2], [5,7]];
//   extended = [line[0], line[0]+22*unit(line[1]-line[0])];
//   cp = [1,2]; r = 10;
//   translate(cp) circle(r=r);
//   color("gray") dashed_stroke(extended, width=0.2);
//   color("black") stroke(line, endcap2="arrow2", width=0.5);
//   isects = circle_line_intersection(r=r, cp=cp, line=line, bounded=[true,false]);
//   color("#f44") move_copies(isects) circle(d=1);
// Example(2D): If they don't intersect at all, then an empty list is returned.
//   line = [[-12,12], [12,8]];
//   cp = [-5,-2]; r = 10;
//   translate(cp) circle(r=r);
//   color("black") stroke(line, endcaps="arrow2", width=0.5);
//   isects = circle_line_intersection(r=r, cp=cp, line=line);
//   color("#f44") move_copies(isects) circle(d=1);
function circle_line_intersection(r, cp, line, bounded=false, d, eps=EPSILON) =
  assert(_valid_line(line,2), "\nInvalid 2d line.")
  assert(is_vector(cp,2), "\nCircle center must be a 2-vector")
  _circle_or_sphere_line_intersection(r, cp, line, bounded, d, eps);



function _circle_or_sphere_line_intersection(r, cp, line, bounded=false, d, eps=EPSILON) =
  let(r=get_radius(r=r,d=d,dflt=undef))
  assert(is_num(r) && r>0, "\nRadius must be positive")
  assert(is_bool(bounded) || is_bool_list(bounded,2), "\nInvalid bound condition")
  let(
      bounded = force_list(bounded,2),
      closest = line_closest_point(line,cp),
      d = norm(closest-cp)
  )
  d > r ? [] :
  let(
     isect = approx(d,r,eps) ? [closest] :
             let( offset = sqrt(r*r-d*d),
                  uvec=unit(line[1]-line[0])
             ) [closest-offset*uvec, closest+offset*uvec]
  )
  [for(p=isect)
     if ((!bounded[0] || (p-line[0])*(line[1]-line[0])>=0)
        && (!bounded[1] || (p-line[1])*(line[0]-line[1])>=0)) p];


// Function: circle_circle_intersection()
// Synopsis: Find the intersection points of two 2d circles.
// Topics: Geometry, Circles
// See Also: circle_line_intersection(), circle_circle_intersection(), circle_2tangents(), circle_3points(), circle_point_tangents(), circle_circle_tangents()
// Usage:
//   pts = circle_circle_intersection(r1|d1=, cp1, r2|d2=, cp2, [eps]);
// Description:
//   Compute the intersection points of two circles.  Returns a list of the intersection points, which
//   contains two points in the general case, one point for tangent circles, or returns an empty list
//   if the circles do not intersect.
// Arguments:
//   r1 = Radius of the first circle.
//   cp1 = Centerpoint of the first circle.
//   r2 = Radius of the second circle.
//   cp2 = Centerpoint of the second circle.
//   eps = Tolerance for detecting tangent circles.  Default: EPSILON
//   ---
//   d1 = Diameter of the first circle.
//   d2 = Diameter of the second circle.
// Example(2D,NoAxes): Circles intersect in two points. 
//   $fn=32;
//   cp1 = [4,4];  r1 = 3;
//   cp2 = [7,7];  r2 = 2;
//   pts = circle_circle_intersection(r1, cp1, r2, cp2);
//   move(cp1) stroke(circle(r=r1), width=0.2, closed=true);
//   move(cp2) stroke(circle(r=r2), width=0.2, closed=true);
//   color("red") move_copies(pts) circle(r=.3);
// Example(2D,NoAxes): Circles are tangent, so one intersection point:
//   $fn=32;
//   cp1 = [4,4];  r1 = 4;
//   cp2 = [4,10]; r2 = 2;
//   pts = circle_circle_intersection(r1, cp1, r2, cp2);
//   move(cp1) stroke(circle(r=r1), width=0.2, closed=true);
//   move(cp2) stroke(circle(r=r2), width=0.2, closed=true);
//   color("red") move_copies(pts) circle(r=.3);
// Example(2D,NoAxes): Another tangent example:
//   $fn=32;
//   cp1 = [4,4];  r1 = 4;
//   cp2 = [5,5];  r2 = 4-sqrt(2);
//   pts = circle_circle_intersection(r1, cp1, r2, cp2);
//   move(cp1) stroke(circle(r=r1), width=0.2, closed=true);
//   move(cp2) stroke(circle(r=r2), width=0.2, closed=true);
//   color("red") move_copies(pts) circle(r=.3);
// Example(2D,NoAxes): Circles do not intersect.  Returns empty list. 
//   $fn=32;
//   cp1 = [3,4];  r1 = 2;
//   cp2 = [7,10]; r2 = 3;
//   pts = circle_circle_intersection(r1, cp1, r2, cp2);
//   move(cp1) stroke(circle(r=r1), width=0.2, closed=true);
//   move(cp2) stroke(circle(r=r2), width=0.2, closed=true);
//   color("red") move_copies(pts) circle(r=.3);
function circle_circle_intersection(r1, cp1, r2, cp2, eps=EPSILON, d1, d2) =
    assert( is_path([cp1,cp2],dim=2), "\nInvalid center point(s)." )
    let(
        r1 = get_radius(r1=r1,d1=d1),
        r2 = get_radius(r1=r2,d1=d2),
        d = norm(cp2-cp1),
        a = (cp2-cp1)/d,
        b = [-a.y,a.x],
        L = (r1^2-r2^2+d^2)/2/d,
        hsqr = r1^2-L^2
    )
    approx(hsqr,0,eps) ? [L*a+cp1]
  : hsqr<0 ? []
  : let(h=sqrt(hsqr))
    [L*a+h*b+cp1, L*a-h*b+cp1];


// Function: circle_2tangents()
// Synopsis: Given two 2d or 3d rays, find a circle tangent to both.  
// Topics: Geometry, Circles, Tangents
// See Also: circle_line_intersection(), circle_circle_intersection(), circle_2tangents(), circle_3points(), circle_point_tangents(), circle_circle_tangents()
// Usage:
//   circ = circle_2tangents(r|d=, pt1, pt2, pt3, [tangents=]);
//   circ = circle_2tangents(r|d=, [PT1, PT2, PT3], [tangents=]);
// Description:
//   Given a pair of 2d or 3d rays with a common origin, and a known circle radius/diameter, finds
//   the centerpoint for the circle of that size that touches both rays tangentally.
//   Both rays start at `pt2`, one passing through `pt1`, and the other through `pt3`.
//   .
//   When called with collinear rays, returns `undef`.
//   Otherwise, when called with `tangents=false`, returns `[CP,NORMAL]`.
//   Otherwise, when called with `tangents=true`, returns `[CP,NORMAL,TANPT1,TANPT2]`.
//   - CP is the centerpoint of the circle.
//   - NORMAL is the normal vector of the plane that the circle is on (UP or DOWN if the points are 2D).
//   - TANPT1 is the point where the circle is tangent to the ray `[pt2,pt1]`.
//   - TANPT2 is the point where the circle is tangent to the ray `[pt2,pt3]`.
// Figure(3D,Med,NoAxes,VPD=130,VPT=[29,19,3],VPR=[55,0,25]):
//   pts = [[45,10,-5], [10,5,10], [15,40,5]];
//   rad = 15;
//   circ = circle_2tangents(r=rad, pt1=pts[0], pt2=pts[1], pt3=pts[2], tangents=true);
//   cp = circ[0]; n = circ[1]; tp1 = circ[2]; tp2 = circ[3];
//   color("yellow") stroke(pts, endcaps="arrow2");
//   color("purple") move_copies([cp,tp1,tp2]) sphere(d=2, $fn=12);
//   color("lightgray") stroke([cp,tp2], width=0.5);
//   stroke([cp,cp+n*20], endcap2="arrow2");
//   labels = [
//       ["pt1",    "blue",  2.5, [ 4, 0, 1], pts[0]],
//       ["pt2",    "blue",  2.5, [-4, 0,-3], pts[1]],
//       ["pt3",    "blue",  2.5, [ 4, 0, 1], pts[2]],
//       ["r",      "blue",  2.5, [ 0,-2, 2], (cp+tp2)/2],
//       ["CP",     "brown", 2.5, [ 6,-4, 3], cp],
//       ["Normal", "brown", 2.0, [ 5, 2, 1], cp+20*n],
//       ["TanPt1", "brown", 2.0, [-5,-4, 0], tp1],
//       ["TanPt2", "brown", 2.0, [-5, 0, 2], tp2],
//   ];
//   for(l=labels)
//       color(l[1]) move(l[4]+l[3]) rot([55,0,25])
//           linear_extrude(height=0.1)
//               text(text=l[0], size=l[2], halign="center", valign="center");
//   color("green",0.5) move(cp) cyl(h=0.1, r=rad, orient=n, $fn=36);
// Arguments:
//   r = The radius of the circle to find.
//   pt1 = A point that the first ray passes though.
//   pt2 = The starting point of both rays.
//   pt3 = A point that the second ray passes though.
//   ---
//   d = The diameter of the circle to find.
//   tangents = If true, extended information about the tangent points is calculated and returned.  Default: false
// Example(2D):
//   pts = [[40,40], [10,10], [55,5]];  rad = 10;
//   circ = circle_2tangents(r=rad, pt1=pts[0], pt2=pts[1], pt3=pts[2]);
//   stroke(pts, endcaps="arrow2");
//   color("red") move(circ[0]) circle(r=rad);
// Example(2D):
//   pts = [[20,40], [10,10], [55,20]];  rad = 10;
//   circ = circle_2tangents(r=rad, pt1=pts[0], pt2=pts[1], pt3=pts[2], tangents=true);
//   stroke(pts, endcaps="arrow2");
//   color("red") move(circ[0]) circle(r=rad);
//   color("blue") move_copies(select(circ,2,3)) circle(d=2);
// Example(3D): Fit into 3D path corner.
//   pts = [[45,5,10], [10,10,15], [30,40,30]];  rad = 10;
//   circ = circle_2tangents(rad, [pts[0], pts[1], pts[2]]);
//   stroke(pts, endcaps="arrow2");
//   color("red") move(circ[0]) cyl(h=10, r=rad, orient=circ[1]);
// Example(3D):
//   path = yrot(20, p=path3d(star(d=100, n=5, step=2)));
//   stroke(path, closed=true);
//   for (i = [0:1:5]) {
//       crn = select(path, i*2-1, i*2+1);
//       ci = circle_2tangents(5, crn[0], crn[1], crn[2]);
//       move(ci[0]) cyl(h=10,r=5,orient=ci[1]);
//   }
function circle_2tangents(r, pt1, pt2, pt3, tangents=false, d) =
    let(r = get_radius(r=r, d=d, dflt=undef))
    assert(r!=undef, "\nMust specify either r or d.")
    assert( ( is_path(pt1) && len(pt1)==3 && is_undef(pt2) && is_undef(pt3))
            || (is_matrix([pt1,pt2,pt3]) && (len(pt1)==2 || len(pt1)==3) ),
            str("\nInvalid input points. pt1=",pt1,", pt2=",pt2,", pt3=",pt3))
    is_undef(pt2)
    ? circle_2tangents(r, pt1[0], pt1[1], pt1[2], tangents=tangents)
    : is_collinear(pt1, pt2, pt3)? undef :
        let(
            v1 = unit(pt1 - pt2),
            v2 = unit(pt3 - pt2),
            vmid = unit(mean([v1, v2])),
            n = vector_axis(v1, v2),
            a = vector_angle(v1, v2),
            hyp = r / sin(a/2),
            cp = pt2 + hyp * vmid
        )
        !tangents ? [cp, n] :
        let(
            x = hyp * cos(a/2),
            tp1 = pt2 + x * v1,
            tp2 = pt2 + x * v2
        )
        [cp, n, tp1, tp2];


// Function: circle_3points()
// Synopsis: Find a circle passing through three 2d or 3d points. 
// Topics: Geometry, Circles
// See Also: circle_line_intersection(), circle_circle_intersection(), circle_2tangents(), circle_3points(), circle_point_tangents(), circle_circle_tangents()
// Usage:
//   circ = circle_3points(pt1, pt2, pt3);
//   circ = circle_3points([PT1, PT2, PT3]);
// Description:
//   Returns the [CENTERPOINT, RADIUS, NORMAL] of the circle that passes through three non-collinear
//   points where NORMAL is the normal vector of the plane that the circle is on (UP or DOWN if the points are 2D).
//   The centerpoint is a 2D or 3D vector, depending on the points input.  If all three
//   points are 2D, then the resulting centerpoint will be 2D, and the normal is UP ([0,0,1]).
//   If any of the points are 3D, then the resulting centerpoint will be 3D.  If the three points are
//   collinear, then `[undef,undef,undef]` is returned.  The normal is a normalized 3D
//   vector with a non-negative Z axis.  Instead of 3 arguments, it is acceptable to input the 3 points
//   as a list given in `pt1`, leaving `pt2`and `pt3` as undef.
// Arguments:
//   pt1 = The first point.
//   pt2 = The second point.
//   pt3 = The third point.
// Example(2D):
//   pts = [[60,40], [10,10], [65,5]];
//   circ = circle_3points(pts[0], pts[1], pts[2]);
//   translate(circ[0]) color("green") stroke(circle(r=circ[1]),closed=true,$fn=72);
//   translate(circ[0]) color("red") circle(d=3, $fn=12);
//   move_copies(pts) color("blue") circle(d=3, $fn=12);
function circle_3points(pt1, pt2, pt3) =
    (is_undef(pt2) && is_undef(pt3) && is_list(pt1))
      ? circle_3points(pt1[0], pt1[1], pt1[2])
      : assert( is_vector(pt1) && is_vector(pt2) && is_vector(pt3)
                && max(len(pt1),len(pt2),len(pt3))<=3 && min(len(pt1),len(pt2),len(pt3))>=2,
                "\nInvalid point(s)." )
        is_collinear(pt1,pt2,pt3)? [undef,undef,undef] :
        let(
            v  = [ point3d(pt1), point3d(pt2), point3d(pt3) ], // triangle vertices
            ed = [for(i=[0:2]) v[(i+1)%3]-v[i] ],    // triangle edge vectors
            pm = [for(i=[0:2]) v[(i+1)%3]+v[i] ]/2,  // edge mean points
            es = sortidx( [for(di=ed) norm(di) ] ),
            e1 = ed[es[1]],                          // take the 2 longest edges
            e2 = ed[es[2]],
            n0 = vector_axis(e1,e2),                 // normal standardization
            n  = n0.z<0? -n0 : n0,
            sc = plane_intersection(
                    [ each e1, e1*pm[es[1]] ],       // planes orthogonal to 2 edges
                    [ each e2, e2*pm[es[2]] ],
                    [ each n,  n*v[0] ]
                ),  // triangle plane
            cp = len(pt1)+len(pt2)+len(pt3)>6 ? sc : [sc.x, sc.y],
            r  = norm(sc-v[0])
        ) [ cp, r, n ];



// Function: circle_point_tangents()
// Synopsis: Given a circle and point, find tangents to circle passing through the point.
// Topics: Geometry, Circles, Tangents
// See Also: circle_line_intersection(), circle_circle_intersection(), circle_2tangents(), circle_3points(), circle_point_tangents(), circle_circle_tangents()
// Usage:
//   tangents = circle_point_tangents(r|d=, cp, pt);
// Description:
//   Given a 2d circle and a 2d point outside that circle, finds the 2d tangent point(s) on the circle for a
//   line passing through the point.  Returns a list of zero or more 2D tangent points.
// Arguments:
//   r = Radius of the circle.
//   cp = The coordinates of the 2d circle centerpoint.
//   pt = The coordinates of the 2d external point.
//   ---
//   d = Diameter of the circle.
// Example(2D):
//   cp = [-10,-10];  r = 30;  pt = [30,10];
//   tanpts = circle_point_tangents(r=r, cp=cp, pt=pt);
//   color("yellow") translate(cp) circle(r=r);
//   color("cyan") for(tp=tanpts) {stroke([tp,pt]); stroke([tp,cp]);}
//   color("red") move_copies(tanpts) circle(d=3,$fn=12);
//   color("blue") move_copies([cp,pt]) circle(d=3,$fn=12);
function circle_point_tangents(r, cp, pt, d) =
    assert(is_finite(r) || is_finite(d), "\nInvalid radius or diameter." )
    assert(is_path([cp, pt],dim=2), "\nInvalid center point or external point.")
    let(
        r = get_radius(r=r, d=d, dflt=1),
        delta = pt - cp,
        dist = norm(delta),
        baseang = atan2(delta.y,delta.x)
    ) dist < r? [] :
    approx(dist,r)? [pt] :
    let(
        relang = acos(r/dist),
        angs = [baseang + relang, baseang - relang]
    ) [for (ang=angs) cp + r*[cos(ang),sin(ang)]];


// Function: circle_circle_tangents()
// Synopsis: Find tangents to a pair of circles in 2d.  
// Topics: Geometry, Circles, Tangents
// See Also: circle_line_intersection(), circle_circle_intersection(), circle_2tangents(), circle_3points(), circle_point_tangents(), circle_circle_tangents()
// Usage:
//   segs = circle_circle_tangents(r1|d1=, cp1, r2|d2=, cp2);
// Description:
//   Computes 2d lines tangents to a pair of circles in 2d.  Returns a list of line endpoints [p1,p2] where
//   p1 is the tangent point on circle 1 and p2 is the tangent point on circle 2.
//   If four tangents exist then the first one is the left hand exterior tangent as regarded looking from
//   circle 1 toward circle 2.  The second value is the right hand exterior tangent.  The third entry
//   gives the interior tangent that starts on the left of circle 1 and crosses to the right side of
//   circle 2.  And the fourth entry is the last interior tangent that starts on the right side of
//   circle 1.  If the circles intersect then the interior tangents don't exist and the function
//   returns only two entries.  If one circle is inside the other one then no tangents exist
//   so the function returns the empty set.  When the circles are tangent a degenerate tangent line
//   passes through the point of tangency of the two circles:  this degenerate line is NOT returned.
// Arguments:
//   r1 = Radius of the first circle.
//   cp1 = Centerpoint of the first circle.
//   r2 = Radius of the second circle.
//   cp2 = Centerpoint of the second circle.
//   ---
//   d1 = Diameter of the first circle.
//   d2 = Diameter of the second circle.
// Example(2D,NoAxes): Four tangents, first in green, second in black, third in blue, last in red.
//   $fn=32;
//   cp1 = [3,4];  r1 = 2;
//   cp2 = [7,10]; r2 = 3;
//   pts = circle_circle_tangents(r1, cp1, r2, cp2);
//   move(cp1) stroke(circle(r=r1), width=0.2, closed=true);
//   move(cp2) stroke(circle(r=r2), width=0.2, closed=true);
//   colors = ["green","black","blue","red"];
//   for(i=[0:len(pts)-1]) color(colors[i]) stroke(pts[i],width=0.2);
// Example(2D,NoAxes): Circles overlap so only exterior tangents exist.
//   $fn=32;
//   cp1 = [4,4];  r1 = 3;
//   cp2 = [7,7];  r2 = 2;
//   pts = circle_circle_tangents(r1, cp1, r2, cp2);
//   move(cp1) stroke(circle(r=r1), width=0.2, closed=true);
//   move(cp2) stroke(circle(r=r2), width=0.2, closed=true);
//   colors = ["green","black","blue","red"];
//   for(i=[0:len(pts)-1]) color(colors[i]) stroke(pts[i],width=0.2);
// Example(2D,NoAxes): Circles are tangent.  Only exterior tangents are returned.  The degenerate internal tangent is not returned.
//   $fn=32;
//   cp1 = [4,4];  r1 = 4;
//   cp2 = [4,10]; r2 = 2;
//   pts = circle_circle_tangents(r1, cp1, r2, cp2);
//   move(cp1) stroke(circle(r=r1), width=0.2, closed=true);
//   move(cp2) stroke(circle(r=r2), width=0.2, closed=true);
//   colors = ["green","black","blue","red"];
//   for(i=[0:1:len(pts)-1]) color(colors[i]) stroke(pts[i],width=0.2);
// Example(2D,NoAxes): One circle is inside the other: no tangents exist.  If the interior circle is tangent the single degenerate tangent is not returned.
//   $fn=32;
//   cp1 = [4,4];  r1 = 4;
//   cp2 = [5,5];  r2 = 2;
//   pts = circle_circle_tangents(r1, cp1, r2, cp2);
//   move(cp1) stroke(circle(r=r1), width=0.2, closed=true);
//   move(cp2) stroke(circle(r=r2), width=0.2, closed=true);
//   echo(pts);   // Returns []
function circle_circle_tangents(r1, cp1, r2, cp2, d1, d2) =
    assert( is_path([cp1,cp2],dim=2), "\nInvalid center point(s)." )
    let(
        r1 = get_radius(r1=r1,d1=d1),
        r2 = get_radius(r1=r2,d1=d2),
        Rvals = [r2-r1, r2-r1, -r2-r1, -r2-r1]/norm(cp1-cp2),
        kvals = [-1,1,-1,1],
        ext = [1,1,-1,-1],
        N = 1-sqr(Rvals[2])>=0 ? 4 :
            1-sqr(Rvals[0])>=0 ? 2 : 0,
        coef= [
            for(i=[0:1:N-1]) [
                [Rvals[i], -kvals[i]*sqrt(1-sqr(Rvals[i]))],
                [kvals[i]*sqrt(1-sqr(Rvals[i])), Rvals[i]]
            ] * unit(cp2-cp1)
        ]
    ) [
        for(i=[0:1:N-1]) let(
            pt = [
                cp1-r1*coef[i],
                cp2-ext[i]*r2*coef[i]
            ]
        ) if (pt[0]!=pt[1]) pt
    ];



/// Internal Function: _noncollinear_triple()
/// Usage:
///   bool = _noncollinear_triple(points);
/// Topics: Geometry, Noncollinearity
/// Description:
///   Finds the indices of three non-collinear points from the pointlist `points`.
///   It selects two well separated points to define a line and chooses the third point
///   to be the point farthest off the line.  The points do not necessarily having the
///   same winding direction as the polygon so they cannot be used to determine the
///   winding direction or the direction of the normal.  
///   If all points are collinear returns [] when `error=true` or an error otherwise .
/// Arguments:
///   points = List of input points.
///   error = Defines the behaviour for collinear input points. When `true`, produces an error, otherwise returns []. Default: `true`.
///   eps = Tolerance for collinearity test. Default: EPSILON.
function _noncollinear_triple(points,error=true,eps=EPSILON) =
    assert( is_path(points), "\nInvalid input points." )
    assert( is_finite(eps) && (eps>=0), "The tolerance should be a non-negative value." )
    len(points)<3 ? [] :
    let(
        pa = points[0],
        b  = furthest_point(pa, points),
        pb = points[b],
        nrm = norm(pa-pb)
    )
    nrm <= eps ?
        assert(!error, "\nCannot find three noncollinear points in pointlist.") [] :
    let(
        n = (pb-pa)/nrm,
        distlist = [for(i=[0:len(points)-1]) _dist2line(points[i]-pa, n)]
    )
    max(distlist) < eps*nrm ?
        assert(!error, "\nCannot find three noncollinear points in pointlist.") [] :
    [0, b, max_index(distlist)];



// Section: Sphere Calculations


// Function: sphere_line_intersection()
// Synopsis: Find intersection between a sphere and line, ray or segment. 
// Topics: Geometry, Spheres, Lines, Intersection
// See Also: circle_line_intersection(), circle_circle_intersection(), circle_2tangents(), circle_3points(), circle_point_tangents(), circle_circle_tangents()
// Usage:
//   isect = sphere_line_intersection(r|d=, cp, line, [bounded], [eps=]);
// Description:
//   Find intersection points between a sphere and a line, ray or segment specified by two points.
//   By default the line is unbounded.
// Arguments:
//   r = Radius of sphere
//   cp = Centerpoint of sphere
//   line = Two points defining the line
//   bounded = false for unbounded line, true for a segment, or a vector [false,true] or [true,false] to specify a ray with the first or second end unbounded.  Default: false
//   ---
//   d = diameter of sphere
//   eps = epsilon used for identifying the case with one solution.  Default: 1e-9
// Example(3D):
//   cp = [10,20,5];  r = 40;
//   line = [[-50,-10,25], [70,0,40]];
//   isects = sphere_line_intersection(r=r, cp=cp, line=line);
//   color("cyan") stroke(line);
//   move(cp) sphere(r=r, $fn=72);
//   color("red") move_copies(isects) sphere(d=3, $fn=12);
function sphere_line_intersection(r, cp, line, bounded=false, d, eps=EPSILON) =
  assert(_valid_line(line,3), "\nInvalid 3d line.")
  assert(is_vector(cp,3), "\nSphere center must be a 3-vector")
  _circle_or_sphere_line_intersection(r, cp, line, bounded, d, eps);




// Section: Polygons

// Function: polygon_area()
// Synopsis: Calculate area of a 2d or 3d polygon. 
// Topics: Geometry, Polygons, Area
// See Also: polygon_area(), centroid(), polygon_normal(), point_in_polygon(), polygon_line_intersection()
// Usage:
//   area = polygon_area(poly, [signed]);
// Description:
//   Given a 2D or 3D simple planar polygon, returns the area of that polygon.
//   If the polygon is non-planar the result is `undef.`  If the polygon is self-intersecting
//   then the returned area is a meaningless number.  
//   When `signed` is true and the polygon is 2d, a signed area is returned: a positive area indicates a counter-clockwise polygon.
//   The area of 3d polygons is always nonnegative.  
// Arguments:
//   poly = Polygon to compute the area of.
//   signed = If true, a signed area is returned. Default: false.
function polygon_area(poly, signed=false) =
    assert(is_path(poly), "\nInvalid polygon." )
    len(poly)<3 ? 0 :
    len(poly)==3 ?
        let( total= len(poly[0])==2 ? 0.5*cross(poly[2]-poly[0],poly[2]-poly[1]) : 0.5*norm(cross(poly[2]-poly[0],poly[2]-poly[1])))
        signed ? total : abs(total) :
    len(poly[0])==2
      ? let( total = sum([for(i=[1:1:len(poly)-2]) cross(poly[i]-poly[0],poly[i+1]-poly[0]) ])/2 )
        signed ? total : abs(total)
      : let( plane = plane_from_polygon(poly) )
        is_undef(plane) ? undef :
        let( 
            n = plane_normal(plane),  
            total = 
                -sum([ for(i=[1:1:len(poly)-2])
                        cross(poly[i]-poly[0], poly[i+1]-poly[0]) 
                    ]) * n/2
        ) 
        signed ? total : abs(total);


// Function: centroid()
// Synopsis: Compute centroid of a 2d or 3d polygon or a VNF. 
// Topics: Geometry, Polygons, Centroid
// See Also: polygon_area(), centroid(), polygon_normal(), point_in_polygon(), polygon_line_intersection()
// Usage:
//   c = centroid(object, [eps]);
// Description:
//   Given a simple 2D polygon, returns the 2D coordinates of the polygon's centroid.
//   Given a simple 3D planar polygon, returns the 3D coordinates of the polygon's centroid.
//   Providing a non-planar or collinear polygon results in an error.  For self-intersecting
//   polygons you may get an error or you may get meaningless results.
//   .
//   Given a [region](regions.scad), returns the 2D coordinates of the region's centroid.
//   .
//   Given a manifold [VNF](vnf.scad) then returns the 3D centroid of the polyhedron.  The VNF must
//   describe a valid polyhedron with consistent face direction and no holes in the mesh; otherwise
//   the results are undefined.
// Arguments:
//   object = object to compute the centroid of
//   eps = epsilon value for identifying degenerate cases
// Example(2D):
//   path = [
//       [-10,10], [-5,15], [15,15], [20,0],
//       [15,-5], [25,-20], [25,-27], [15,-20],
//       [0,-30], [-15,-25], [-5,-5]
//   ];
//   linear_extrude(height=0.01) polygon(path);
//   cp = centroid(path);
//   color("red") move(cp) sphere(d=2);
function centroid(object,eps=EPSILON) =
    assert(is_finite(eps) && (eps>=0), "\nThe tolerance should a non-negative value." )
    is_vnf(object) ? _vnf_centroid(object,eps)
  : is_path(object,[2,3]) ? _polygon_centroid(object,eps)
  : is_region(object) ? (len(object)==1 ? _polygon_centroid(object[0],eps) : _region_centroid(object,eps))
  : assert(false, "\nInput must be a VNF, a region, or a 2D or 3D polygon");


/// Internal Function: _region_centroid()
/// Compute centroid of region
function _region_centroid(region,eps=EPSILON) =
   let(
       region=force_region(region),
       parts = region_parts(region),
       // Rely on region_parts returning all outside polygons clockwise
       // and inside (hole) polygons counterclockwise, so areas have reversed sign
       cent_area = [for(R=parts, p=R)
                       let(A=polygon_area(p,signed=true))
                       [A*_polygon_centroid(p),A]],
       total = sum(cent_area)
   )
   total[0]/total[1];


/// Internal Function: _polygon_centroid()
/// Usage:
///   cpt = _polygon_centroid(poly);
/// Topics: Geometry, Polygons, Centroid
/// Description:
///   Given a simple 2D polygon, returns the 2D coordinates of the polygon's centroid.
///   Given a simple 3D planar polygon, returns the 3D coordinates of the polygon's centroid.
///   Collinear points produce an error.  The results are meaningless for self-intersecting
///   polygons or an error is produced.
/// Arguments:
///   poly = Points of the polygon from which the centroid is calculated.
///   eps = Tolerance in geometric comparisons.  Default: `EPSILON` (1e-9)
function _polygon_centroid(poly, eps=EPSILON) =
    assert( is_path(poly,dim=[2,3]), "\nThe input must be a 2D or 3D polygon." )
    let(
        n = len(poly[0])==2 ? 1 :
            let( plane = plane_from_points(poly, check_coplanar=true))
            assert(!is_undef(plane), "\nThe polygon must be planar." )
            plane_normal(plane),
        v0 = poly[0] ,
        val = sum([
            for(i=[1:len(poly)-2])
            let(
                v1 = poly[i],
                v2 = poly[i+1],
                area = cross(v2-v0,v1-v0)*n
            ) [ area, (v0+v1+v2)*area ]
        ])
    )
    assert(!approx(val[0],0, eps), "\nThe polygon is self-intersecting or its points are collinear.")
    val[1]/val[0]/3;



// Function: polygon_normal()
// Synopsis: Return normal to a polygon.  
// Topics: Geometry, Polygons
// See Also: polygon_area(), centroid(), polygon_normal(), point_in_polygon(), polygon_line_intersection()
// Usage:
//   vec = polygon_normal(poly);
// Description:
//   Given a 3D simple planar polygon, returns a unit normal vector for the polygon.  The vector
//   is oriented so that if the normal points toward the viewer, the polygon winds in the clockwise
//   direction.  If the polygon has zero area, returns `undef`.  If the polygon is self-intersecting
//   the the result is undefined.  It doesn't check for coplanarity.
// Arguments:
//   poly = The list of 3D path points for the perimeter of the polygon.
// Example(3D):
//   path = rot([0,30,15], p=path3d(star(n=5, d=100, step=2)));
//   stroke(path, closed=true);
//   n = polygon_normal(path);
//   rot(from=UP, to=n)
//       color("red")
//           stroke([[0,0,0], [0,0,20]], endcap2="arrow2");
function polygon_normal(poly) =
    assert(is_path(poly,dim=3), "\nInvalid 3D polygon." )
    let(
        area_vec = sum([for(i=[1:len(poly)-2])
                           cross(poly[i]-poly[0],
                                 poly[i+1]-poly[i])])
    )
    unit(-area_vec, error=undef);


// Function: point_in_polygon()
// Synopsis: Checks if a 2d point is inside or on the boundary of a 2d polygon. 
// Topics: Geometry, Polygons
// See Also: polygon_area(), centroid(), polygon_normal(), point_in_polygon(), polygon_line_intersection()
// Usage:
//   bool = point_in_polygon(point, poly, [nonzero], [eps])
// Description:
//   This function tests whether the given 2D point is inside, outside or on the boundary of
//   the specified 2D polygon.  
//   The polygon is given as a list of 2D points, not including the repeated end point.
//   Returns -1 if the point is outside the polygon.
//   Returns 0 if the point is on the boundary.
//   Returns 1 if the point lies in the interior.
//   The polygon does not need to be simple: it may have self-intersections.
//   But the polygon cannot have holes (it must be simply connected).
//   Rounding errors may give mixed results for points on or near the boundary.
//   .
//   When polygons intersect themselves different definitions exist for determining which points
//   are inside the polygon.  The figure below shows the difference.
//   OpenSCAD uses the Even-Odd rule when creating polygons, where membership in overlapping regions
//   depends on how many times they overlap.  The Nonzero rule considers point inside the polygon if
//   the polygon overlaps them any number of times.  For more information see
//   https://en.wikipedia.org/wiki/Nonzero-rule and https://en.wikipedia.org/wiki/Even–odd_rule.
// Figure(2D,Med,NoAxes):
//   a=20;
//   b=30;
//   ofs = 17;
//   curve = [for(theta=[0:10:140])  [a * theta/360*2*PI - b*sin(theta), a-b*cos(theta)-20]];
//   path = deduplicate(concat( reverse(offset(curve,r=ofs,closed=false)),
//                  xflip(offset(curve,r=ofs,closed=false)),
//                  xflip(reverse(curve)),
//                  curve
//                ));
//   left(40){
//     polygon(path);
//     color("red")stroke(path, width=1, closed=true);
//     color("red")back(28/(2/3))text("Even-Odd", size=5/(2/3), halign="center");
//   }
//   right(40){
//      dp = polygon_parts(path,nonzero=true);
//      region(dp);
//      color("red"){stroke(path,width=1,closed=true);
//                   back(28/(2/3))text("Nonzero", size=5/(2/3), halign="center");
//                   }
//   }  
// Arguments:
//   point = The 2D point to check
//   poly = The list of 2D points forming the perimeter of the polygon.
//   nonzero = The rule to use: true for "Nonzero" rule and false for "Even-Odd". Default: false (Even-Odd)
//   eps = Tolerance in geometric comparisons.  Default: `EPSILON` (1e-9)
// Example(2D): With nonzero set to false (the default), we get this result. Green dots are inside the polygon and red are outside:
//   a=20*2/3;
//   b=30*2/3;
//   ofs = 17*2/3;
//   curve = [for(theta=[0:10:140])  [a * theta/360*2*PI - b*sin(theta), a-b*cos(theta)]];
//   path = deduplicate(concat( reverse(offset(curve,r=ofs,closed=false)),
//                  xflip(offset(curve,r=ofs,closed=false)),
//                  xflip(reverse(curve)),
//                  curve
//                ));
//   stroke(path,closed=true);
//   pts = [[0,0],[10,0],[0,20]];
//   for(p=pts){
//     color(point_in_polygon(p,path)==1 ? "green" : "red")
//     move(p)circle(r=1.5, $fn=12);
//   }
// Example(2D): With nonzero set to true, one dot changes color:
//   a=20*2/3;
//   b=30*2/3;
//   ofs = 17*2/3;
//   curve = [for(theta=[0:10:140])  [a * theta/360*2*PI - b*sin(theta), a-b*cos(theta)]];
//   path = deduplicate(concat( reverse(offset(curve,r=ofs,closed=false)),
//                  xflip(offset(curve,r=ofs,closed=false)),
//                  xflip(reverse(curve)),
//                  curve
//                ));
//   stroke(path,closed=true);
//   pts = [[0,0],[10,0],[0,20]];
//   for(p=pts){
//     color(point_in_polygon(p,path,nonzero=true)==1 ? "green" : "red")
//     move(p)circle(r=1.5, $fn=12);
//   }

// Internal function for point_in_polygon

function _point_above_below_segment(point, edge) =
    let( edge = edge - [point, point] )
    edge[0].y <= 0
      ? (edge[1].y >  0 && cross(edge[0], edge[1]-edge[0]) > 0) ?  1 : 0
      : (edge[1].y <= 0 && cross(edge[0], edge[1]-edge[0]) < 0) ? -1 : 0;


function point_in_polygon(point, poly, nonzero=false, eps=EPSILON) =
    // Original algorithms from http://geomalgorithms.com/a03-_inclusion.html
    assert( is_vector(point,2) && is_path(poly,dim=2) && len(poly)>2,
            "\nThe point and polygon should be in 2D. The polygon should have more that 2 points." )
    assert( is_finite(eps) && (eps>=0), "\nThe tolerance should be a non-negative value." )
    // Check bounding box
    let(
        box = pointlist_bounds(poly)
    )
    point.x<box[0].x-eps || point.x>box[1].x+eps
        || point.y<box[0].y-eps || point.y>box[1].y+eps  ? -1
    :
    // Does the point lie on any edges?  If so return 0.
    let(
        segs = pair(poly,true),
        on_border = [for (seg=segs)
                       if (norm(seg[0]-seg[1])>eps && _is_point_on_line(point, seg, SEGMENT, eps=eps)) 1]
    )
    on_border != [] ? 0 :
    nonzero    // Compute winding number and return 1 for interior, -1 for exterior
      ? let(
            winding = [
                       for(seg=segs)
                         let(
                             p0=seg[0]-point,
                             p1=seg[1]-point
                         )
                         if (norm(p0-p1)>eps)
                             p0.y <=0
                                ? p1.y > 0 && cross(p0,p1-p0)>0 ? 1 : 0
                                : p1.y <=0 && cross(p0,p1-p0)<0 ? -1: 0
            ]
        )
        sum(winding) != 0 ? 1 : -1
      : // or compute the crossings with the ray [point, point+[1,0]]
        let(
            cross = [
                     for(seg=segs)
                       let(
                           p0 = seg[0]-point,
                           p1 = seg[1]-point
                       )
                       if (
                           ( (p1.y>eps && p0.y<=eps) || (p1.y<=eps && p0.y>eps) )
                           &&  -eps < p0.x - p0.y *(p1.x - p0.x)/(p1.y - p0.y)
                       )
                       1
            ]
        )
        2*(len(cross)%2)-1;



// Function: polygon_line_intersection()
// Synopsis: Find intersection between 2d or 3d polygon and a line, segment or ray.  
// Topics: Geometry, Polygons, Lines, Intersection
// See Also: polygon_area(), centroid(), polygon_normal(), point_in_polygon(), polygon_line_intersection()
// Usage:
//   pt = polygon_line_intersection(poly, line, [bounded], [nonzero], [eps]);
// Description:
//   Takes a possibly bounded line, and a 2D or 3D planar polygon, and finds their intersection.  Note the polygon is
//   treated as its boundary and interior, so the intersection may include both points and line segments.  
//   If the line does not intersect the polygon then returns `undef`.  
//   In 3D if the line is not on the plane of the polygon but intersects it then you get a single intersection point.
//   Otherwise the polygon and line are in the same plane, or when your input is 2D, you get a list of segments and 
//   single point lists.  Use `is_vector` to distinguish these two cases.
//   .
//   In the 2D case, a common result is a list containing a single segment, which lists the two intersection points
//   with the boundary of the polygon.
//   When single points are in the intersection (the line just touches a polygon corner) they appear on the segment
//   list as lists of a single point
//   (like single point segments) so a single point intersection in 2D has the form `[[[x,y,z]]]` as compared
//   to a single point intersection in 3D, which has the form `[x,y,z]`.  You can identify whether an entry in the
//   segment list is a true segment by checking its length, which is 2 for a segment and 1 for a point.  
// Arguments:
//   poly = The 3D planar polygon to find the intersection with.
//   line = A list of two distinct 3D points on the line.
//   bounded = If false, the line is considered unbounded.  If true, it is treated as a bounded line segment.  If given as `[true, false]` or `[false, true]`, the boundedness of the points are specified individually, allowing the line to be treated as a half-bounded ray.  Default: false (unbounded)
//   nonzero = set to true to use the nonzero rule for determining it points are in a polygon.  See point_in_polygon.  Default: false.
//   eps = Tolerance in geometric comparisons.  Default: `EPSILON` (1e-9)
// Example(3D): The line intersects the 3d hexagon in a single point. 
//   hex = zrot(140,p=rot([-45,40,20],p=path3d(hexagon(r=15))));
//   line = [[5,0,-13],[-3,-5,13]];
//   isect = polygon_line_intersection(hex,line);
//   stroke(hex,closed=true);
//   stroke(line);
//   color("red")move(isect)sphere(r=1,$fn=12);
// Example(2D): In 2D things are more complicated.  The output is a list of intersection parts, in the simplest case a single segment.
//   hex = hexagon(r=15);
//   line = [[-20,10],[25,-7]];
//   isect = polygon_line_intersection(hex,line);
//   stroke(hex,closed=true);
//   stroke(line,endcaps="arrow2");
//   color("red")
//     for(part=isect)
//        if(len(part)==1)
//          move(part[0]) sphere(r=1);
//        else
//          stroke(part);
// Example(2D): Here the line is treated as a ray. 
//   hex = hexagon(r=15);
//   line = [[0,0],[25,-7]];
//   isect = polygon_line_intersection(hex,line,RAY);
//   stroke(hex,closed=true);
//   stroke(line,endcap2="arrow2");
//   color("red")
//     for(part=isect)
//        if(len(part)==1)
//          move(part[0]) circle(r=1,$fn=12);
//        else
//          stroke(part);
// Example(2D): Here the intersection is a single point, which is returned as a single point "path" on the path list.
//   hex = hexagon(r=15);
//   line = [[15,-10],[15,13]];
//   isect = polygon_line_intersection(hex,line,RAY);
//   stroke(hex,closed=true);
//   stroke(line,endcap2="arrow2");
//   color("red")
//     for(part=isect)
//        if(len(part)==1)
//          move(part[0]) circle(r=1,$fn=12);
//        else
//          stroke(part);
// Example(2D): Another way to get a single segment
//   hex = hexagon(r=15);
//   line = rot(30,p=[[15,-10],[15,25]],cp=[15,0]);
//   isect = polygon_line_intersection(hex,line,RAY);
//   stroke(hex,closed=true);
//   stroke(line,endcap2="arrow2");
//   color("red")
//     for(part=isect)
//        if(len(part)==1)
//          move(part[0]) circle(r=1,$fn=12);
//        else
//          stroke(part);
// Example(2D): Single segment again
//   star = star(r=15,n=8,step=2);
//   line = [[20,-5],[-5,20]];
//   isect = polygon_line_intersection(star,line,RAY);
//   stroke(star,closed=true);
//   stroke(line,endcap2="arrow2");
//   color("red")
//     for(part=isect)
//        if(len(part)==1)
//          move(part[0]) circle(r=1,$fn=12);
//        else
//          stroke(part);
// Example(2D): Solution is two points
//   star = star(r=15,n=8,step=3);
//   line = rot(22.5,p=[[15,-10],[15,20]],cp=[15,0]);
//   isect = polygon_line_intersection(star,line,SEGMENT);
//   stroke(star,closed=true);
//   stroke(line);
//   color("red")
//     for(part=isect)
//        if(len(part)==1)
//          move(part[0]) circle(r=1,$fn=12);
//        else
//          stroke(part);
// Example(2D): Solution is list of three segments
//   star = star(r=25,ir=9,n=8);
//   line = [[-25,12],[25,12]];
//   isect = polygon_line_intersection(star,line);
//   stroke(star,closed=true);
//   stroke(line,endcaps="arrow2");
//   color("red")
//     for(part=isect)
//        if(len(part)==1)
//          move(part[0]) circle(r=1,$fn=12);
//        else
//          stroke(part);
// Example(2D): Solution is a mixture of segments and points
//   star = star(r=25,ir=9,n=7);
//   line = [left(10,p=star[8]), right(50,p=star[8])];
//   isect = polygon_line_intersection(star,line);
//   stroke(star,closed=true);
//   stroke(line,endcaps="arrow2");
//   color("red")
//     for(part=isect)
//        if(len(part)==1)
//          move(part[0]) circle(r=1,$fn=12);
//        else
//          stroke(part);
function polygon_line_intersection(poly, line, bounded=false, nonzero=false, eps=EPSILON) =
    assert( is_finite(eps) && eps>=0, "\nThe tolerance should be a positive number." )
    assert(is_path(poly,dim=[2,3]), "\nInvalid polygon." )
    assert(is_bool(bounded) || is_bool_list(bounded,2), "\nInvalid bound condition.")
    assert(_valid_line(line,dim=len(poly[0]),eps=eps), "\nLine invalid or does not match polygon dimension." )
    let(
        bounded = force_list(bounded,2),
        poly = deduplicate(poly)
    )
    len(poly[0])==2 ?  // planar case
       let( 
            linevec = unit(line[1] - line[0]),
            bound = 100*max(v_abs(flatten(pointlist_bounds(poly)))),
            boundedline = [line[0] + (bounded[0]? 0 : -bound) * linevec,
                           line[1] + (bounded[1]? 0 :  bound) * linevec],
            parts = split_region_at_region_crossings(boundedline, [poly], closed1=false)[0][0],
            inside = [
                      if(point_in_polygon(parts[0][0], poly, nonzero=nonzero, eps=eps) == 0)
                         [parts[0][0]],   // Add starting point if it is on the polygon
                      for(part = parts)
                         if (point_in_polygon(mean(part), poly, nonzero=nonzero, eps=eps) >=0 )
                             part
                         else if(len(part)==2 && point_in_polygon(part[1], poly, nonzero=nonzero, eps=eps) == 0)
                             [part[1]]   // Add segment end if it is on the polygon
                     ]
        )
        (len(inside)==0 ? undef : _merge_segments(inside, [inside[0]], eps))
    : // 3d case
       let(indices = _noncollinear_triple(poly))
       indices==[] ? undef :   // Polygon is collinear
       let(
           plane = plane3pt(poly[indices[0]], poly[indices[1]], poly[indices[2]]),
           plane_isect = plane_line_intersection(plane, line, bounded, eps)
       )
       is_undef(plane_isect) ? undef :  
       is_vector(plane_isect,3) ?  
           let(
               poly2d = project_plane(plane,poly),
               pt2d = project_plane(plane, plane_isect)
           )
           (point_in_polygon(pt2d, poly2d, nonzero=nonzero, eps=eps) < 0 ? undef : plane_isect)
       : // Case where line is on the polygon plane
           let(
               poly2d = project_plane(plane, poly),
               line2d = project_plane(plane, line),
               segments = polygon_line_intersection(poly2d, line2d, bounded=bounded, nonzero=nonzero, eps=eps)
           )
           segments==undef ? undef
         : [for(seg=segments) len(seg)==2 ? lift_plane(plane,seg) : [lift_plane(plane,seg[0])]];

function _merge_segments(insegs,outsegs, eps, i=1) = 
    i==len(insegs) ? outsegs : 
    approx(last(last(outsegs)), insegs[i][0], eps) 
        ? _merge_segments(insegs, [each list_head(outsegs),[last(outsegs)[0],last(insegs[i])]], eps, i+1)
        : _merge_segments(insegs, [each outsegs, insegs[i]], eps, i+1);



// Function: polygon_triangulate()
// Synopsis: Divide a polygon into triangles. 
// Topics: Geometry, Triangulation
// See Also: vnf_triangulate()
// Usage:
//   triangles = polygon_triangulate(poly, [ind], [error], [eps])
// Description:
//   Given a simple polygon in 2D or 3D, triangulates it and returns a list 
//   of triples indexing into the polygon vertices. When the optional argument `ind` is 
//   given, it is used as an index list into `poly` to define the polygon vertices. In that case, 
//   `poly` may have a length greater than `ind`. When `ind` is undefined, all points in `poly` 
//   are considered as vertices of the polygon.
//   .
//   For 2d polygons, the output triangleshave the same winding (CW or CCW) of
//   the input polygon. For 3d polygons, the triangle windings induce a normal
//   vector with the same direction of the polygon normal.
//   .
//   The function produces correct triangulations for some non-twisted non-simple polygons. 
//   A polygon is non-twisted if it is simple or it has a partition in
//   simple polygons with the same winding such that the intersection of any two partitions is
//   made of full edges and/or vertices of both partitions. These polygons may have "touching" vertices 
//   (two vertices having the same coordinates, but distinct adjacencies) and "contact" edges 
//   (edges whose vertex pairs have the same pairwise coordinates but are in reversed order) but has 
//   no self-crossing. See examples bellow. If all polygon edges are contact edges (polygons with 
//   zero area), it returns an empty list for 2d polygons and reports an error for 3d polygons. 
//   Triangulation errors are reported either by an assert error (when `error=true`) or by returning 
//   `undef` (when `error=false`). Invalid arguments always produce an assert error.
//   .
//   Twisted polygons have no consistent winding and when input to this function usually reports 
//   an error but when an error is not reported the outputs are not correct triangulations. The function
//   can work for 3d non-planar polygons if they are close enough to planar but may otherwise 
//   report an error for this case. 
// Arguments:
//   poly = Array of the polygon vertices.
//   ind = If given, a list of indices indexing the vertices of the polygon in `poly`.  Default: use all the points of poly
//   error = If false, returns `undef` when the polygon cannot be triangulated; otherwise, issues an assert error. Default: true.
//   eps = A maximum tolerance in geometrical tests. Default: EPSILON
// Example(2D,NoAxes): a simple polygon; see from above
//   poly = star(id=10, od=15,n=11);
//   tris =  polygon_triangulate(poly);
//   color("lightblue") for(tri=tris) polygon(select(poly,tri));
//   color("blue")    up(1) for(tri=tris) { stroke(select(poly,tri),.15,closed=true); }
//   color("magenta") up(2) stroke(poly,.25,closed=true); 
//   color("black")   up(3) debug_vnf([path3d(poly),[]],faces=false,size=1);
// Example(2D,NoAxes): a polygon with a hole and one "contact" edge; see from above
//   poly = [ [-10,0], [10,0], [0,10], [-10,0], [-4,4], [4,4], [0,2], [-4,4] ];
//   tris =  polygon_triangulate(poly);
//   color("lightblue") for(tri=tris) polygon(select(poly,tri));
//   color("blue")    up(1) for(tri=tris) { stroke(select(poly,tri),.15,closed=true); }
//   color("magenta") up(2) stroke(poly,.25,closed=true); 
//   color("black")   up(3) debug_vnf([path3d(poly),[]],faces=false,size=1);
// Example(2D,NoAxes): a polygon with "touching" vertices and no holes; see from above
//   poly = [ [0,0], [5,5], [-5,5], [0,0], [-5,-5], [5,-5] ];
//   tris =  polygon_triangulate(poly);
//   color("lightblue") for(tri=tris) polygon(select(poly,tri));
//   color("blue")    up(1) for(tri=tris) { stroke(select(poly,tri),.15,closed=true); }
//   color("magenta") up(2) stroke(poly,.25,closed=true); 
//   color("black")   up(3) debug_vnf([path3d(poly),[]],faces=false,size=1);
// Example(2D,NoAxes): a polygon with "contact" edges and no holes; see from above
//   poly = [ [0,0], [10,0], [10,10], [0,10], [0,0], [3,3], [7,3], 
//            [7,7], [7,3], [3,3] ];
//   tris =  polygon_triangulate(poly);
//   color("lightblue") for(tri=tris) polygon(select(poly,tri));
//   color("blue")    up(1) for(tri=tris) { stroke(select(poly,tri),.15,closed=true); }
//   color("magenta") up(2) stroke(poly,.25,closed=true); 
//   color("black")   up(3) debug_vnf([path3d(poly),[]],faces=false,size=1);
// Example(3D): 
//   include <BOSL2/polyhedra.scad>
//   vnf = regular_polyhedron_info(name="dodecahedron",side=5,info="vnf");
//   vnf_polyhedron(vnf);
//   vnf_tri = [vnf[0], [for(face=vnf[1]) each polygon_triangulate(vnf[0], face) ] ];
//   color("blue")
//   vnf_wireframe(vnf_tri, width=.15);
function polygon_triangulate(poly, ind, error=true, eps=EPSILON) =
    assert(is_path(poly) && len(poly)>=3, "\nPolygon `poly` should be a list of at least three 2d or 3d points")
    assert(is_undef(ind) || (is_vector(ind) && min(ind)>=0 && max(ind)<len(poly) ),
           "Improper or out of bounds list of indices")
    let( ind = is_undef(ind) ? count(len(poly)) : ind )
    len(ind) <=2 ? [] :
    len(ind) == 3 
      ? _degenerate_tri([poly[ind[0]], poly[ind[1]], poly[ind[2]]], eps) ? [] : 
        // non zero area
        let(
            cp = cross(poly[ind[1]]-poly[ind[0]], poly[ind[2]]-poly[ind[0]]), 
            degen = is_num(cp) ? abs(cp) < 2*eps
                               : norm(cp) < 2*eps
        )
        assert( ! error || ! degen, "\nThe polygon vertices are collinear.") 
        degen ? undef : [ind]
      : len(poly[ind[0]]) == 3 
          ? // find a representation of the polygon as a 2d polygon by projecting it on its own plane
            let( 
                ind = deduplicate_indexed(poly, ind, eps) 
            )
            len(ind)<3 ? [] :
            let(
                pts = select(poly,ind),
                nrm = -polygon_normal(pts)
            )
            assert( ! error || (nrm != undef), 
                    "\nThe polygon has self-intersections or zero area or its vertices are collinear or non coplanar.") 
            nrm == undef ? undef :
            let(
                imax  = max_index([for(p=pts) norm(p-pts[0]) ]),
                v1    = unit( pts[imax] - pts[0] ),
                v2    = cross(v1,nrm),
                prpts = pts*transpose([v1,v2]) // the 2d projection of pts on the polygon plane
            )
            let( tris = _triangulate(prpts, count(len(ind)), error, eps) )
            tris == undef ? undef :
            [for(tri=tris) select(ind,tri) ]
          : is_polygon_clockwise(select(poly, ind)) 
              ? _triangulate( poly, ind, error, eps )
              : let( tris = _triangulate( poly, reverse(ind), error, eps ) )
                tris == undef ? undef :
                [for(tri=tris) reverse(tri) ];


// poly is supposed to be a 2d cw polygon
// implements a modified version of ear cut method for non-twisted polygons
// the polygons accepted by this function are those decomposable in simple
// CW polygons.
function _triangulate(poly, ind,  error, eps=EPSILON, tris=[]) =
    len(ind)==3 
    ?   _degenerate_tri(select(poly,ind),eps) 
        ?   tris // if last 3 pts perform a degenerate triangle, ignore it
        :   concat(tris,[ind]) // otherwise, include it
    :   let( ear = _get_ear(poly,ind,eps) )
        assert( ! error || (ear != undef), 
            "\nThe polygon has twists or all its vertices are collinear or non coplanar.") 
        ear == undef ? undef :
        is_list(ear) // is it a degenerate ear ?
        ?   len(ind) <= 4 ? tris :
            _triangulate(poly, select(ind,ear[0]+3, ear[0]), error, eps, tris) // discard it
        :   let(
                ear_tri = select(ind,ear,ear+2),
                indr    = select(ind,ear+2, ear) //  indices of the remaining path
            )
            _triangulate(poly, indr, error, eps, concat(tris,[ear_tri]));


/// a returned ear will be:
/// 1. a CW non-reflex triangle, made of subsequent poly vertices, without any other 
///    poly points inside except possibly at its own vertices
/// 2. or a degenerate triangle where two vertices are coincident
/// the returned ear is specified by the index of `ind` of its first vertex
function _get_ear(poly, ind,  eps, _i=0) =
    let( lind = len(ind) )
    lind==3 ? 0 :
    let( // the _i-th ear candidate
        p0 = poly[ind[_i]],
        p1 = poly[ind[(_i+1)%lind]],
        p2 = poly[ind[(_i+2)%lind]]
    )
    // if vertex p1 is a convex candidate to be an ear,
    // check if the triangle [p0,p1,p2] contains any other point
    // except possibly p0 and p2
    // exclude the ear candidate central vertex p1 from the verts to check 
    _tri_class([p0,p1,p2],eps) > 0  
    &&  _none_inside(select(ind,_i+2, _i),poly,p0,p1,p2,eps) ? _i : // found an ear
    // otherwise check the next ear candidate 
    _i<lind-1 ?  _get_ear(poly, ind,  eps, _i=_i+1) :
    // poly has no ears, look for wiskers
    let( wiskers = [for(j=idx(ind)) if(norm(poly[ind[j]]-poly[ind[(j+2)%lind]])<eps) j ] )
    wiskers==[] ? undef : [wiskers[0]];
    
    

/// returns false ASA it finds some reflex vertex of poly[idxs[.]] 
/// inside the triangle different from p0 and p2
/// note: to simplify the expressions it is assumed that the input polygon has no twists 
function _none_inside(idxs,poly,p0,p1,p2,eps,i=0) =
    i>=len(idxs) ? true :
    let( 
        vert      = poly[idxs[i]], 
        prev_vert = poly[select(idxs,i-1)], 
        next_vert = poly[select(idxs,i+1)]
    )
    // check if vert prevent [p0,p1,p2] to be an ear
    // this conditions might have a simpler expression
    _tri_class([prev_vert, vert, next_vert],eps) <= 0  // reflex condition
    &&  (  // vert is a cw reflex poly vertex inside the triangle [p0,p1,p2]
          ( _tri_class([p0,p1,vert],eps)>0 && 
            _tri_class([p1,p2,vert],eps)>0 && 
            _tri_class([p2,p0,vert],eps)>=0  )
          // or it is equal to p1 and some of its adjacent edges cross the open segment (p0,p2)
          ||  ( norm(vert-p1) < eps 
                && _is_at_left(p0,[prev_vert,p1],eps) && _is_at_left(p2,[p1,prev_vert],eps) 
                && _is_at_left(p2,[p1,next_vert],eps) && _is_at_left(p0,[next_vert,p1],eps) 
              ) 
        )
    ?   false
    :   _none_inside(idxs,poly,p0,p1,p2,eps,i=i+1);


// Function: is_polygon_clockwise()
// Synopsis: Determine if a 2d polygon winds clockwise.  
// Topics: Geometry, Polygons, Clockwise
// See Also: clockwise_polygon(), ccw_polygon(), reverse_polygon()
// Usage:
//   bool = is_polygon_clockwise(poly);
// Description:
//   Return true if the given 2D simple polygon is in clockwise order, false otherwise.
//   Results for complex (self-intersecting) polygon are indeterminate.
// Arguments:
//   poly = The list of 2D path points for the perimeter of the polygon.

// For algorithm see 2.07 here: http://www.faqs.org/faqs/graphics/algorithms-faq/
function is_polygon_clockwise(poly) =
    assert(is_path(poly,dim=2), "\nInput should be a 2d path.")
    let(
        minx = min(poly*[1,0]),
        lowind = search(minx, poly, 0, 0),
        lowpts = select(poly,lowind),
        miny = min(lowpts*[0,1]),
        extreme_sub = search(miny, lowpts, 1, 1)[0],
        extreme = lowind[extreme_sub]
    )
    cross(select(poly,extreme+1)-poly[extreme],
          select(poly,extreme-1)-poly[extreme])<0;


// Function: clockwise_polygon()
// Synopsis: Return clockwise version of a polygon. 
// Topics: Geometry, Polygons, Clockwise
// See Also: is_polygon_clockwise(), ccw_polygon(), reverse_polygon()
// Usage:
//   newpoly = clockwise_polygon(poly);
// Description:
//   Given a 2D polygon path, returns the clockwise winding version of that path.
// Arguments:
//   poly = The list of 2D path points for the perimeter of the polygon.
function clockwise_polygon(poly) =
    assert(is_path(poly,dim=2), "\nInput should be a 2d polygon.")
    is_polygon_clockwise(poly) ? poly : reverse_polygon(poly);


// Function: ccw_polygon()
// Synopsis: Return counter-clockwise version of a polygon. 
// Topics: Geometry, Polygons, Clockwise
// See Also: is_polygon_clockwise(), clockwise_polygon(), reverse_polygon()
// Usage:
//   newpoly = ccw_polygon(poly);
// Description:
//   Given a 2D polygon poly, returns the counter-clockwise winding version of that poly.
// Arguments:
//   poly = The list of 2D path points for the perimeter of the polygon.
function ccw_polygon(poly) =
    assert(is_path(poly,dim=2), "\nInput should be a 2d polygon.")
    is_polygon_clockwise(poly) ? reverse_polygon(poly) : poly;


// Function: reverse_polygon()
// Synopsis: Reverse winding direction of polygon. 
// Topics: Geometry, Polygons, Clockwise
// See Also: is_polygon_clockwise(), ccw_polygon(), clockwise_polygon()
// Usage:
//   newpoly = reverse_polygon(poly)
// Description:
//   Reverses a polygon's winding direction, while still using the same start point.
// Arguments:
//   poly = The list of the path points for the perimeter of the polygon.
function reverse_polygon(poly) =
    let(poly=force_path(poly,"poly"))
    assert(is_path(poly), "\nInput should be a polygon.")
    [ poly[0], for(i=[len(poly)-1:-1:1]) poly[i] ];


// Function: reindex_polygon()
// Synopsis: Adjust point indexing of polygon to minimize pointwise distance to a reference polygon. 
// Topics: Geometry, Polygons
// See Also: reindex_polygon(), align_polygon(), are_polygons_equal()
// Usage:
//   newpoly = reindex_polygon(reference, poly);
// Description:
//   Rotates and possibly reverses the point order of a 2d or 3d polygon path to optimize its pairwise point
//   association with a reference polygon.  The two polygons must have the same number of vertices and be the same dimension.
//   The optimization is done by computing the distance, norm(reference[i]-poly[i]), between
//   corresponding pairs of vertices of the two polygons and choosing the polygon point index rotation that
//   makes the total sum over all pairs as small as possible.  Returns the reindexed polygon.  Note
//   that the geometry of the polygon is not changed by this operation, just the labeling of its
//   vertices.  If the input polygon is 2d and is oriented opposite the reference then its point order is
//   reversed.
// Arguments:
//   reference = reference polygon path
//   poly = input polygon to reindex
// Example(2D):  The red dots show the 0th entry in the two input path lists.  Note that the red dots are not near each other.  The blue dot shows the 0th entry in the output polygon
//   pent = subdivide_path([for(i=[0:4])[sin(72*i),cos(72*i)]],30);
//   circ = circle($fn=30,r=2.2);
//   reindexed = reindex_polygon(circ,pent);
//   move_copies(concat(circ,pent)) circle(r=.1,$fn=32);
//   color("red") move_copies([pent[0],circ[0]]) circle(r=.1,$fn=32);
//   color("blue") translate(reindexed[0])circle(r=.1,$fn=32);
// Example(2D): The indexing that minimizes the total distance does not necessarily associate the nearest point of `poly` with the reference, as in this example where again the blue dot indicates the 0th entry in the reindexed result.
//   pent = move([3.5,-1],p=subdivide_path([for(i=[0:4])[sin(72*i),cos(72*i)]],30));
//   circ = circle($fn=30,r=2.2);
//   reindexed = reindex_polygon(circ,pent);
//   move_copies(concat(circ,pent)) circle(r=.1,$fn=32);
//   color("red") move_copies([pent[0],circ[0]]) circle(r=.1,$fn=32);
//   color("blue") translate(reindexed[0])circle(r=.1,$fn=32);
function reindex_polygon(reference, poly, return_error=false) =
    let(reference=force_path(reference,"reference"),
        poly=force_path(poly,"poly"))
    assert(is_path(reference) && is_path(poly,dim=len(reference[0])),
           "\nInvalid polygon(s) or incompatible dimensions." )
    assert(len(reference)==len(poly), "\nThe polygons must have the same length.")
    let(
        dim = len(reference[0]),
        N = len(reference),
        fixpoly = dim != 2? poly :
                  is_polygon_clockwise(reference)
                  ? clockwise_polygon(poly)
                  : ccw_polygon(poly),
        I   = [for(i=reference) 1],
        val = [ for(k=[0:N-1])
                    [for(i=[0:N-1])
                      norm(reference[i]-fixpoly[(i+k)%N]) ] ]*I,
        min_ind = min_index(val),
        optimal_poly = list_rotate(fixpoly, min_ind)
    )
    return_error? [optimal_poly, val[min_ind]] :
    optimal_poly;


// Function: align_polygon()
// Synopsis: Find best alignment of a 2d polygon to a reference 2d polygon over a set of transformations.  
// Topics: Geometry, Polygons
// See Also: reindex_polygon(), align_polygon(), are_polygons_equal()
// Usage:
//   newpoly = align_polygon(reference, poly, [angles], [cp], [tran], [return_ind]);
// Description:
//   Find the best alignment of a specified 2D polygon with a reference 2D polygon over a set of
//   transformations.  You can specify a list or range of angles and a centerpoint or you can
//   give a list of arbitrary 2d transformation matrices.  For each transformation or angle, the polygon is
//   reindexed, which is a costly operation so if run time is a problem, use a smaller sampling of angles or
//   transformations.  By default returns the rotated and reindexed polygon.  You can also request that
//   the best angle or the index into the transformation list be returned.  
// Arguments:
//   reference = reference polygon
//   poly = polygon to rotate into alignment with the reference
//   angles = list or range of angles to test
//   cp = centerpoint for rotations
//   ---
//   tran = list of 2D transformation matrices to optimize over
//   return_ind = if true, return the best angle (if you specified angles) or the index into tran otherwise of best alignment
// Example(2D): Rotating the poorly aligned light gray triangle by 105 degrees produces the best alignment, shown in blue:
//   ellipse = yscale(3,circle(r=10, $fn=32));
//   tri = move([-50/3,-9],
//              subdivide_path([[0,0], [50,0], [0,27]], 32));
//   aligned = align_polygon(ellipse,tri, [0:5:180]);
//   color("white")stroke(tri,width=.5,closed=true);
//   stroke(ellipse, width=.5, closed=true);
//   color("blue")stroke(aligned,width=.5,closed=true);
// Example(2D,NoAxes): Translating a triangle (light gray) to the best alignment (blue)
//   ellipse = yscale(2,circle(r=10, $fn=32));
//   tri = subdivide_path([[0,0], [27,0], [-7,50]], 32);
//   T = [for(x=[-10:0], y=[-30:-15]) move([x,y])];
//   aligned = align_polygon(ellipse,tri, trans=T);
//   color("white")stroke(tri,width=.5,closed=true);
//   stroke(ellipse, width=.5, closed=true);
//   color("blue")stroke(aligned,width=.5,closed=true);
function align_polygon(reference, poly, angles, cp, trans, return_ind=false) =
    let(reference=force_path(reference,"reference"),
        poly=force_path(poly,"poly"))
    assert(is_undef(trans) || (is_undef(angles) && is_undef(cp)), "\nCannot give both angles/cp and trans as input.")
    let(
        trans = is_def(trans) ? trans :
            assert( (is_vector(angles) && len(angles)>0) || valid_range(angles),
                "\nThe `angle` parameter must be a range or a non void list of numbers.")
            [for(angle=angles) zrot(angle,cp=cp)]
    )
    assert(is_path(reference,dim=2), "reference must be a 2D polygon")
    assert(is_path(poly,dim=2), "poly must be a 2D polygon")
    assert(len(reference)==len(poly), "The polygons must have the same length.")
    let(     // alignments is a vector of entries of the form: [polygon, error]
        alignments = [
            for(T=trans)
              reindex_polygon(
                  reference,
                  apply(T,poly),
                  return_error=true
              )
        ],
        scores = column(alignments,1),
        minscore = min(scores),
        minind = [for(i=idx(scores)) if (scores[i]<minscore+EPSILON) i],
        dummy = is_def(angles) ? echo(best_angles = select(list(angles), minind)):0,
        best = minind[0]
    )
    return_ind ? (is_def(angles) ? list(angles)[best] : best)
    : alignments[best][0];
    

// Function: are_polygons_equal()
// Synopsis: Check if two polygons (not necessarily in the same point order) are equal.  
// Topics: Geometry, Polygons, Comparators
// See Also: reindex_polygon(), align_polygon(), are_polygons_equal()
// Usage:
//    bool = are_polygons_equal(poly1, poly2, [eps])
// Description:
//    Returns true if poly1 and poly2 are the same polongs
//    within given epsilon tolerance.
// Arguments:
//    poly1 = first polygon
//    poly2 = second polygon
//    eps = tolerance for comparison
// Example(NORENDER):
//    are_polygons_equal(pentagon(r=4),
//                   rot(360/5, p=pentagon(r=4))); // returns true
//    are_polygons_equal(pentagon(r=4),
//                   rot(90, p=pentagon(r=4)));    // returns false
function are_polygons_equal(poly1, poly2, eps=EPSILON) =
    let(
        poly1 = list_unwrap(poly1),
        poly2 = list_unwrap(poly2),
        l1 = len(poly1),
        l2 = len(poly2)
    ) l1 != l2 ? false :
    let( maybes = find_approx(poly1[0], poly2, eps=eps, all=true) )
    maybes == []? false :
    [for (i=maybes) if (_are_polygons_equal(poly1, poly2, eps, i)) 1] != [];

function _are_polygons_equal(poly1, poly2, eps, st) =
    max([for(d=poly1-select(poly2,st,st-1)) d*d])<eps*eps;


/// Function: _is_polygon_in_list()
/// Topics: Polygons, Comparators
/// See Also: are_polygons_equal(), are_regions_equal()
/// Usage:
///   bool = _is_polygon_in_list(poly, polys);
/// Description:
///   Returns true if one of the polygons in `polys` is equivalent to the polygon `poly`.
/// Arguments:
///   poly = The polygon to search for.
///   polys = The list of polygons to look for the polygon in.
function _is_polygon_in_list(poly, polys) =
    ___is_polygon_in_list(poly, polys, 0);

function ___is_polygon_in_list(poly, polys, i) =
    i >= len(polys)? false :
    are_polygons_equal(poly, polys[i])? true :
    ___is_polygon_in_list(poly, polys, i+1);


// Section: Convex Hull

// This section originally based on Oskar Linde's Hull:
//   - https://github.com/openscad/scad-utils


// Function: hull()
// Synopsis: Convex hull of a list of 2d or 3d points.
// SynTags: Ext
// Topics: Geometry, Hulling
// See Also: hull_points(), hull2d_path(), hull3d_faces()
// Usage:
//   face_list_or_index_list = hull(points);
// Description:
//   Takes a list of 2D or 3D points (but not both in the same list) and returns either the list of
//   indexes into `points` that forms the 2D convex hull perimeter path, or the list of faces that
//   form the 3d convex hull surface.  Each face is a list of indexes into `points`.  If the input
//   points are collinear, the indexes of the two extrema points are returned.  If the input
//   points are coplanar, then a simple list of vertex indices forming a planar perimeter is
//   returned. Otherwise a list of faces is returned, where each face is a simple list of
//   vertex indices for the perimeter of the face.
// Arguments:
//   points = The set of 2D or 3D points to find the hull of.
function hull(points) =
    assert(is_path(points),"\nInvalid input to hull.")
    len(points[0]) == 2
      ? hull2d_path(points)
      : hull3d_faces(points);


// Module: hull_points()
// Synopsis: Convex hull of a list of 2d or 3d points.  
// Topics: Geometry, Hulling
// See Also: hull(), hull_points(), hull2d_path(), hull3d_faces()
// Usage:
//   hull_points(points, [fast]);
// Description:
//   If given a list of 2D points, creates a 2D convex hull polygon that encloses all those points.
//   If given a list of 3D points, creates a 3D polyhedron that encloses all the points.  This should
//   handle about 4000 points in slow mode.  If `fast` is set to true, this should be able to handle
//   far more.  When fast mode is off, 3d hulls that lie in a plane produce a single face of a polyhedron, which can be viewed in preview but will not render.
// Arguments:
//   points = The list of points to form a hull around.
//   fast = If true for 3d case, uses a faster cheat that may handle more points, but also may emit warnings that can stop your script if you have "Halt on first warning" enabled.  Ignored for the 2d case.  Default: false
// Example(2D):
//   pts = [[-10,-10], [0,10], [10,10], [12,-10]];
//   hull_points(pts);
// Example(3D):
//   pts = [for (phi = [30:60:150], theta = [0:60:359]) spherical_to_xyz(10, theta, phi)];
//   hull_points(pts);
module hull_points(points, fast=false) {
    no_children($children);
    check = assert(is_path(points))
            assert(len(points)>=3, "\nPoint list must contain 3 points");
    attachable(){
      if (len(points[0])==2)
         hull() polygon(points=points);
      else if (len(points)==3)
         polyhedron(points=points, faces=[[0,1,2]]);
      else {
        if (fast) {
           extra = len(points)%3;
           faces = [
                     [for(i=[0:1:extra+2])i], // If vertex count not divisible by 3, combine extras with first 3
                     for(i=[extra+3:3:len(points)-3])[i,i+1,i+2]
                   ];
           hull() polyhedron(points=points, faces=faces);
        } else {
          faces = hull(points);
          if (is_num(faces[0])){
            if (len(faces)<=2) echo("Hull contains only two points");
            else polyhedron(points=points, faces=[faces]);
          }
          else polyhedron(points=points, faces=faces);
        }
      }
      union();
    }
}



function _backtracking(i,points,h,t,m,all) =
    m<t || _is_cw(points[i], points[h[m-1]], points[h[m-2]],all) ? m :
    _backtracking(i,points,h,t,m-1,all) ;

// clockwise check (2d)
function _is_cw(a,b,c,all) = 
    all ? cross(a-c,b-c)<=EPSILON*norm(a-c)*norm(b-c) :
    cross(a-c,b-c)<-EPSILON*norm(a-c)*norm(b-c);


// Function: hull2d_path()
// Synopsis: Convex hull of a list of 2d points. 
// Topics: Geometry, Hulling
// See Also: hull(), hull_points(), hull2d_path(), hull3d_faces()
// Usage:
//   index_list = hull2d_path(points,all)
// Description:
//   Takes a list of arbitrary 2D points, and finds the convex hull polygon to enclose them.
//   Returns a path as a list of indices into `points`. 
//   When all==true, returns extra points that are on edges of the hull.
// Arguments:
//   points = list of 2d points to get the hull of.
//   all = when true, includes all points on the edges of the convex hull. Default: false.
// Example(2D):
//   pts = [[-10,-10], [0,10], [10,10], [12,-10]];
//   path = hull2d_path(pts);
//   move_copies(pts) color("red") circle(1,$fn=12);
//   polygon(points=pts, paths=[path]);
//
// Code based on this method:
// https://www.hackerearth.com/practice/math/geometry/line-sweep-technique/tutorial/
//
function hull2d_path(points, all=false) =
    assert(is_path(points,2),"\nInvalid input to hull2d_path.")
    len(points) < 2 ? [] :
    let( n  = len(points), 
         ip = sortidx(points) )
    // lower hull points
    let( lh = 
            [ for(   i = 2,
                    k = 2, 
                    h = [ip[0],ip[1]]; // current list of hull point indices 
                  i <= n;
                    k = i<n ? _backtracking(ip[i],points,h,2,k,all)+1 : k,
                    h = i<n ? [for(j=[0:1:k-2]) h[j], ip[i]] : [], 
                    i = i+1
                 ) if( i==n ) h ][0] )
    // concat lower hull points with upper hull ones
    [ for(   i = n-2,
            k = len(lh), 
            t = k+1,
            h = lh; // current list of hull point indices 
          i >= -1;
            k = i>=0 ? _backtracking(ip[i],points,h,t,k,all)+1 : k,
            h = [for(j=[0:1:k-2]) h[j], if(i>0) ip[i]],
            i = i-1
         ) if( i==-1 ) h ][0] ;
       

function _hull_collinear(points) =
    let(
        a = points[0],
        i = max_index([for(pt=points) norm(pt-a)]),
        n = points[i] - a
    )
    norm(n)==0 ? [0]
    :
    let(
        points1d = [ for(p = points) (p-a)*n ],
        min_i = min_index(points1d),
        max_i = max_index(points1d)
    ) [min_i, max_i];



// Function: hull3d_faces()
// Synopsis: Convex hull of a list of 3d points. 
// Topics: Geometry, Hulling
// See Also: hull(), hull_points(), hull2d_path(), hull3d_faces()
// Usage:
//   faces = hull3d_faces(points)
// Description:
//   Takes a list of arbitrary 3D points, and finds the convex hull polyhedron to enclose
//   them.  Returns a list of triangular faces, where each face is a list of indexes into the given `points`
//   list.  The output is valid for use with the `polyhedron()` command, but may include vertices that are in the interior of a face of the hull, so it is not
//   necessarily the minimal representation of the hull.  
//   If all points passed to it are coplanar, then the return is the list of indices of points
//   forming the convex hull polygon.
// Example(3D):
//   pts = [[-20,-20,0], [20,-20,0], [0,20,5], [0,0,20]];
//   faces = hull3d_faces(pts);
//   move_copies(pts) color("red") sphere(1);
//   %polyhedron(points=pts, faces=faces);
function hull3d_faces(points) =
    assert(is_path(points,3),"\nInvalid input to hull3d_faces.")
    len(points) < 3 ? count(len(points))
  : let ( // start with a single non-collinear triangle
          tri = _noncollinear_triple(points, error=false)
        )
    tri==[] ? _hull_collinear(points)
  : let(
        a = tri[0],
        b = tri[1],
        c = tri[2],
        plane = plane3pt_indexed(points, a, b, c),
        d = _find_first_noncoplanar(plane, points)
    )
    d == len(points)
  ? /* all coplanar*/
    let (
        pts2d =  project_plane([points[a], points[b], points[c]],points),
        hull2d = hull2d_path(pts2d)
    ) hull2d
  : let(
        remaining = [for (i = [0:1:len(points)-1]) if (i!=a && i!=b && i!=c && i!=d) i],
        // Build an initial tetrahedron.
        // Swap b, c if d is in front of triangle t.
        ifop = _is_point_above_plane(plane, points[d]),
        bc = ifop? [c,b] : [b,c],
        b = bc[0],
        c = bc[1],
        triangles = [
            [a,b,c],
            [d,b,a],
            [c,d,a],
            [b,d,c]
        ],
        // calculate the plane equations
        planes = [ for (t = triangles) plane3pt_indexed(points, t[0], t[1], t[2]) ]
    ) _hull3d_iterative(points, triangles, planes, remaining);


// Adds the remaining points one by one to the convex hull
function _hull3d_iterative(points, triangles, planes, remaining, _i=0) = //let( EPSILON=1e-12 )
    _i >= len(remaining) ? triangles : 
    let (
        // pick a point
        i = remaining[_i],
        // evaluate the triangle plane equations at point i
        planeq_val = planes*[each points[i], -1],
        // find the triangles that are in conflict with the point (point not inside)
        conflicts = [for (i = [0:1:len(planeq_val)-1]) if (planeq_val[i]>EPSILON) i ],
        // collect the halfedges of all triangles that are in conflict 
        halfedges = [ 
            for(c = conflicts, i = [0:2])
                [triangles[c][i], triangles[c][(i+1)%3]]
        ],
        // find the outer perimeter of the set of conflicting triangles
        horizon = _remove_internal_edges(halfedges),
        // generate new triangles connecting point i to each horizon halfedge vertices
        tri2add = [ for (h = horizon) concat(h,i) ],
        // add tria2add and remove conflict triangles
        new_triangles = 
            concat( tri2add,
                    [ for (i = [0:1:len(planes)-1]) if (planeq_val[i]<=EPSILON) triangles[i] ] 
                  ),
        // add the plane equations of new added triangles and remove the plane equations of the conflict ones
        new_planes = 
            [ for (t = tri2add) plane3pt_indexed(points, t[0], t[1], t[2]) ,
              for (i = [0:1:len(planes)-1]) if (planeq_val[i]<=EPSILON) planes[i] ] 
    ) _hull3d_iterative(
        points,
        new_triangles,
        new_planes,
        remaining,
        _i+1
    );


function _remove_internal_edges(halfedges) = [
    for (h = halfedges)  
        if (!in_list(reverse(h), halfedges))
            h
];

function _find_first_noncoplanar(plane, points, i=0) = 
    (i >= len(points) || !are_points_on_plane([points[i]],plane))? i :
    _find_first_noncoplanar(plane, points, i+1);


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap





// Section: Convex Sets


// Function: is_polygon_convex()
// Synopsis: Check if a polygon is convex. 
// Topics: Geometry, Convexity, Test
// See Also: clockwise_polygon(), ccw_polygon()
// Usage:
//   bool = is_polygon_convex(poly, [eps]);
// Description:
//   Returns true if the given 2D or 3D polygon is convex.
//   The result is meaningless if the polygon is not simple (self-crossing) or non coplanar.
//   If the points are collinear or not coplanar an error may be generated.
// Arguments:
//   poly = Polygon to check.
//   eps = Tolerance for the collinearity and coplanarity tests. Default: EPSILON.
// Example:
//   test1 = is_polygon_convex(circle(d=50));                                 // Returns: true
//   test2 = is_polygon_convex(rot([50,120,30], p=path3d(circle(1,$fn=50)))); // Returns: true
//   spiral = [for (i=[0:36]) let(a=-i*10) (10+i)*[cos(a),sin(a)]];
//   test = is_polygon_convex(spiral);                                        // Returns: false
function is_polygon_convex(poly,eps=EPSILON) =
    assert(is_path(poly), "\nThe input should be a 2D or 3D polygon." )
    let(
        lp = len(poly),
        p0 = poly[0]
    )
    assert( lp>=3 , "\nA polygon must have at least 3 points." )
    let( crosses = [for(i=[0:1:lp-1]) cross(poly[(i+1)%lp]-poly[i], poly[(i+2)%lp]-poly[(i+1)%lp]) ] )
    len(p0)==2
      ? let( size = max([for(p=poly) norm(p-p0)]), tol=pow(size,2)*eps )
        assert( size>eps, "\nThe polygon is self-crossing or its points are collinear." )
        min(crosses) >=-tol || max(crosses)<=tol
      : let( ip = _noncollinear_triple(poly,error=false,eps=eps) )
        assert( ip!=[], "\nThe points are collinear.")
        let( 
            crx   = cross(poly[ip[1]]-poly[ip[0]],poly[ip[2]]-poly[ip[1]]),
            nrm   = crx/norm(crx),
            plane = concat(nrm, nrm*poly[0]), 
            prod  = crosses*nrm,
            size  = norm(poly[ip[1]]-poly[ip[0]]),
            tol   = pow(size,2)*eps
        )
        assert(_pointlist_greatest_distance(poly,plane) < size*eps, "\nThe polygon points are not coplanar.")
        let(
            minc = min(prod),
            maxc = max(prod) ) 
        minc>=-tol || maxc<=tol;


// Function: convex_distance()
// Synopsis: Compute distance between convex hull of two point lists. 
// Topics: Geometry, Convexity, Distance
// See also: convex_collision(), hull()
// Usage:
//   dist = convex_distance(points1, points2,eps);
// Description:
//   Returns the smallest distance between a point in convex hull of `points1`
//   and a point in the convex hull of `points2`. All the points in the lists
//   should have the same dimension, either 2D or 3D.
//   A zero result means the hulls intercept whithin a tolerance `eps`.
// Arguments:
//   points1 = first list of 2d or 3d points.
//   points2 = second list of 2d or 3d points.
//   eps = tolerance in distance evaluations. Default: EPSILON.
// Example(2D):
//    pts1 = move([-3,0], p=square(3,center=true));
//    pts2 = rot(a=45, p=square(2,center=true));
//    pts3 = [ [2,0], [1,2],[3,2], [3,-2], [1,-2] ];
//    polygon(pts1);
//    polygon(pts2);
//    polygon(pts3);
//    echo(convex_distance(pts1,pts2)); // Returns: 0.0857864
//    echo(convex_distance(pts2,pts3)); // Returns: 0
// Example(3D):
//    sphr1 = sphere(2,$fn=10);
//    sphr2 = move([4,0,0], p=sphr1);
//    sphr3 = move([4.5,0,0], p=sphr1);
//    vnf_polyhedron(sphr1);
//    vnf_polyhedron(sphr2);
//    echo(convex_distance(sphr1[0], sphr2[0])); // Returns: 0
//    echo(convex_distance(sphr1[0], sphr3[0])); // Returns: 0.5
function convex_distance(points1, points2, eps=EPSILON) =
    assert(is_matrix(points1) && is_matrix(points2,undef,len(points1[0])), 
           "\nThe input lists should be compatible consistent non empty lists of points.")
    assert(len(points1[0])==2 || len(points1[0])==3 ,
           "\nThe input points should be 2d or 3d points.")
    let( d = points1[0]-points2[0] )
    norm(d)<eps ? 0 :
    let( v = _support_diff(points1,points2,-d) )
    norm(_GJK_distance(points1, points2, eps, 0, v, [v]));


// Finds the vector difference between the hulls of the two pointsets by the GJK algorithm
// Based on:
// http://www.dtecta.com/papers/jgt98convex.pdf
function _GJK_distance(points1, points2, eps=EPSILON, lbd, d, simplex=[]) =
    let( nrd = norm(d) ) // distance upper bound
    nrd<eps ? d :
    let(
        v     = _support_diff(points1,points2,-d),
        lbd   = max(lbd, d*v/nrd), // distance lower bound
        close = (nrd-lbd <= eps*nrd)
    )
    close ? d :
    let( newsplx = _closest_simplex(concat(simplex,[v]),eps) )
    _GJK_distance(points1, points2, eps, lbd, newsplx[0], newsplx[1]);


// Function: convex_collision()
// Synopsis: Check whether the convex hulls of two point lists intersect. 
// Topics: Geometry, Convexity, Collision, Intersection
// See also: 
//   convex_distance(), hull()
// Usage:
//   bool = convex_collision(points1, points2, [eps]);
// Description:
//   Returns `true` if the convex hull of `points1` intersects the convex hull of `points2`
//   otherwise, `false`.
//   All the points in the lists should have the same dimension, either 2D or 3D.
//   This function is tipically faster than `convex_distance` to find a non-collision.
// Arguments:
//   points1 = first list of 2d or 3d points.
//   points2 = second list of 2d or 3d points.
//   eps - tolerance for the intersection tests. Default: EPSILON.
// Example(2D):
//    pts1 = move([-3,0], p=square(3,center=true));
//    pts2 = rot(a=45, p=square(2,center=true));
//    pts3 = [ [2,0], [1,2],[3,2], [3,-2], [1,-2] ];
//    polygon(pts1);
//    polygon(pts2);
//    polygon(pts3);
//    echo(convex_collision(pts1,pts2)); // Returns: false
//    echo(convex_collision(pts2,pts3)); // Returns: true
// Example(3D):
//    sphr1 = sphere(2,$fn=10);
//    sphr2 = move([4,0,0], p=sphr1);
//    sphr3 = move([4.5,0,0], p=sphr1);
//    vnf_polyhedron(sphr1);
//    vnf_polyhedron(sphr2);
//    echo(convex_collision(sphr1[0], sphr2[0])); // Returns: true
//    echo(convex_collision(sphr1[0], sphr3[0])); // Returns: false
//
function convex_collision(points1, points2, eps=EPSILON) =
    assert(is_matrix(points1) && is_matrix(points2,undef,len(points1[0])), 
           "\nThe input lists should be compatible consistent non empty lists of points.")
    assert(len(points1[0])==2 || len(points1[0])==3 ,
           "\nThe input points should be 2d or 3d points.")
    let( d = points1[0]-points2[0] )
    norm(d)<eps ? true :
    let( v = _support_diff(points1,points2,-d) )
    _GJK_collide(points1, points2, v, [v], eps);


// Based on the GJK collision algorithms found in:
// http://uu.diva-portal.org/smash/get/diva2/FFULLTEXT01.pdf
// or
// http://www.dtecta.com/papers/jgt98convex.pdf
function _GJK_collide(points1, points2, d, simplex, eps=EPSILON) =
    norm(d) < eps ? true :          // does collide
    let( v = _support_diff(points1,points2,-d) ) 
    v*d > eps*eps ? false : // no collision
    let( newsplx = _closest_simplex(concat(simplex,[v]),eps) )
    norm(v-newsplx[0])<eps ? norm(v)<eps :
    _GJK_collide(points1, points2, newsplx[0], newsplx[1], eps);


// given a simplex s, returns a pair:
//  - the point of the s closest to the origin
//  - the smallest sub-simplex of s that contains that point
function _closest_simplex(s,eps=EPSILON) =
    len(s)==2 ? _closest_s1(s,eps) :
    len(s)==3 ? _closest_s2(s,eps) :
    len(s)==4 ? _closest_s3(s,eps) :
    assert(false, "\nInternal error.");


// find the point of a 1-simplex closest to the origin
function _closest_s1(s,eps=EPSILON) =
    norm(s[1]-s[0])<=eps*(norm(s[0])+norm(s[1]))/2 ? [ s[0], [s[0]] ] :
    let(
        c = s[1]-s[0],
        t = -s[0]*c/(c*c)
    )
    t<0 ? [ s[0], [s[0]] ] :
    t>1 ? [ s[1], [s[1]] ] :
    [ s[0]+t*c, s ];


// find the point of a 2-simplex closest to the origin
function _closest_s2(s, eps=EPSILON) =
    // considering that s[2] was the last inserted vertex in s by GJK, 
    // the plane orthogonal to the triangle [ origin, s[0], s[1] ] that 
    // contains [s[0],s[1]] have the origin and s[2] on the same side;
    // that reduces the cases to test and the only possible simplex
    // outcomes are s, [s[0],s[2]] and [s[1],s[2]] 
    let(
        area  = cross(s[2]-s[0], s[1]-s[0]), 
        area2 = area*area                     // tri area squared
    )
    area2<=eps*max([for(si=s) pow(si*si,2)]) // degenerate tri
    ?   norm(s[2]-s[0]) < norm(s[2]-s[1]) 
        ? _closest_s1([s[1],s[2]])
        : _closest_s1([s[0],s[2]])
    :   let(
            crx1  = cross(s[0], s[2])*area,
            crx2  = cross(s[1], s[0])*area,
            crx0  = cross(s[2], s[1])*area
        )
        // all have the same signal -> origin projects inside the tri 
        max(crx1, crx0, crx2) < 0  || min(crx1, crx0, crx2) > 0
        ?   // baricentric coords of projection   
            [ [abs(crx0),abs(crx1),abs(crx2)]*s/area2, s ] 
       :   let( 
               cl12 = _closest_s1([s[1],s[2]]),
               cl02 = _closest_s1([s[0],s[2]])
            )
            norm(cl12[0])<norm(cl02[0]) ? cl12 : cl02;
        

// find the point of a 3-simplex closest to the origin
function _closest_s3(s,eps=EPSILON) =
    let( nr = cross(s[1]-s[0],s[2]-s[0]),
         sz = [ norm(s[0]-s[1]), norm(s[1]-s[2]), norm(s[2]-s[0]) ] )
    norm(nr)<=eps*pow(max(sz),2)
    ?   let( i = max_index(sz) )
        _closest_s2([ s[i], s[(i+1)%3], s[3] ], eps) // degenerate case
    :   // considering that s[3] was the last inserted vertex in s by GJK,
        // the only possible outcomes will be:
        //    s or some of the 3 faces of s containing s[3]
        let(
            tris = [ [s[0], s[1], s[3]],
                     [s[1], s[2], s[3]],
                     [s[2], s[0], s[3]] ],
            cntr = sum(s)/4,
            // indicator of the tris facing the origin
            facing = [for(i=[0:2])
                        let( nrm = _tri_normal(tris[i]) )
                        if( ((nrm*(s[i]-cntr))>0)==(nrm*s[i]<0) ) i ]
        )
        len(facing)==0 ? [ [0,0,0], s ] : // origin is inside the simplex
        len(facing)==1 ? _closest_s2(tris[facing[0]], eps) :
        let( // look for the origin-facing tri closest to the origin
            closest = [for(i=facing) _closest_s2(tris[i], eps) ],
            dist    = [for(cl=closest) norm(cl[0]) ],
            nearest = min_index(dist) 
        )
        closest[nearest];


function _tri_normal(tri) = cross(tri[1]-tri[0],tri[2]-tri[0]);


function _support_diff(p1,p2,d) =
    let( p1d = p1*d, p2d = p2*d )
    p1[search(max(p1d),p1d,1)[0]] - p2[search(min(p2d),p2d,1)[0]];


// Section: Rotation Decoding

// Function: rot_decode()
// Synopsis: Extract axis and rotation angle from a rotation matrix. 
// Topics: Affine, Matrices, Transforms
// Usage:
//   info = rot_decode(rotation,[long]); // Returns: [angle,axis,cp,translation]
// Description:
//   Given an input 3D rigid transformation operator (one composed of just rotations and translations) represented
//   as a 4x4 matrix, compute the rotation and translation parameters of the operator.  Returns a list of the
//   four parameters, the angle, in the interval [0,180], the rotation axis as a unit vector, a centerpoint for
//   the rotation, and a translation.  If you set `parms = rot_decode(rotation)` then the transformation can be
//   reconstructed from parms as `move(parms[3]) * rot(a=parms[0],v=parms[1],cp=parms[2])`.  This decomposition
//   makes it possible to perform interpolation.  If you construct a transformation using `rot` the decoding
//   may flip the axis (if you gave an angle outside of [0,180]).  The returned axis is a unit vector, and
//   the centerpoint lies on the plane through the origin that is perpendicular to the axis.  It may be different
//   than the centerpoint you used to construct the transformation.
//   .
//   If you set `long` to true then return the reversed rotation, with the angle in [180,360].
// Arguments:
//   rotation = rigid transformation to decode
//   long = if true return the "long way" around, with the angle in [180,360].  Default: false
// Example:
//   info = rot_decode(rot(45));
//          // Returns: [45, [0,0,1], [0,0,0], [0,0,0]]
//   info = rot_decode(rot(a=37, v=[1,2,3], cp=[4,3,-7])));
//          // Returns: [37, [0.26, 0.53, 0.80], [4.8, 4.6, -4.6], [0,0,0]]
//   info = rot_decode(left(12)*xrot(-33));
//          // Returns: [33, [-1,0,0], [0,0,0], [-12,0,0]]
//   info = rot_decode(translate([3,4,5]));
//          // Returns: [0, [0,0,1], [0,0,0], [3,4,5]]
function rot_decode(M,long=false) =
    assert(is_matrix(M,4,4) && approx(M[3],[0,0,0,1]), "\nInput matrix must be a 4×4 matrix representing a 3d transformation.")
    let(R = submatrix(M,[0:2],[0:2]))
    assert(approx(det3(R),1) && approx(norm_fro(R * transpose(R)-ident(3)),0),"\nInput matrix is not a rotation.")
    let(
        translation = [for(row=[0:2]) M[row][3]],   // translation vector
        largest  = max_index([R[0][0], R[1][1], R[2][2]]),
        axis_matrix = R + transpose(R) - (matrix_trace(R)-1)*ident(3),   // Each row is on the rotational axis
            // Construct quaternion q = c * [x sin(theta/2), y sin(theta/2), z sin(theta/2), cos(theta/2)]
        q_im = axis_matrix[largest],
        q_re = R[(largest+2)%3][(largest+1)%3] - R[(largest+1)%3][(largest+2)%3],
        c_sin = norm(q_im),              // c * sin(theta/2) for some c
        c_cos = abs(q_re)                // c * cos(theta/2)
    )
    approx(c_sin,0) ? [0,[0,0,1],[0,0,0],translation] :
    let(
        angle = 2*atan2(c_sin, c_cos),    // This is supposed to be more accurate than acos or asin
        axis  = (q_re>=0 ? 1:-1)*q_im/c_sin,
        tproj = translation - (translation*axis)*axis,    // Translation perpendicular to axis determines centerpoint
        cp    = (tproj + cross(axis,tproj)*c_cos/c_sin)/2
    )
    [long ? 360-angle:angle,
     long? -axis : axis,
     cp,
     (translation*axis)*axis];




// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
