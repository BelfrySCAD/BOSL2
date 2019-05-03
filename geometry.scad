//////////////////////////////////////////////////////////////////////
// LibFile: geometry.scad
//   Geometry helpers.
//   To use, add the following lines to the beginning of your file:
//   ```
//   use <BOSL2/std.scad>
//   ```
//////////////////////////////////////////////////////////////////////


// Section: Lines and Triangles

// Function: point_on_segment2d()
// Usage:
//   point_on_segment2d(point, edge);
// Description:
//   Determine if the point is on the line segment between two points.
//   Returns true if yes, and false if not.  
// Arguments:
//   point = The point to test.
//   edge = Array of two points forming the line segment to test against.
function point_on_segment2d(point, edge) =
	point==edge[0] || point==edge[1] ||  // The point is an endpoint
	sign(edge[0].x-point.x)==sign(point.x-edge[1].x)  // point is in between the
		&& sign(edge[0].y-point.y)==sign(point.y-edge[1].y)  // edge endpoints 
		&& point_left_of_segment2d(point, edge)==0;  // and on the line defined by edge


// Function: point_left_of_segment2d()
// Usage:
//   point_left_of_segment2d(point, edge);
// Description:
//   Return >0 if point is left of the line defined by edge.
//   Return =0 if point is on the line.
//   Return <0 if point is right of the line.
// Arguments:
//   point = The point to check position of.
//   edge = Array of two points forming the line segment to test against.
function point_left_of_segment2d(point, edge) =
	(edge[1].x-edge[0].x) * (point.y-edge[0].y) - (point.x-edge[0].x) * (edge[1].y-edge[0].y);
  

// Internal non-exposed function.
function _point_above_below_segment(point, edge) =
	edge[0].y <= point.y? (
		(edge[1].y > point.y && point_left_of_segment2d(point, edge) > 0)? 1 : 0
	) : (
		(edge[1].y <= point.y && point_left_of_segment2d(point, edge) < 0)? -1 : 0
	);


// Function: right_of_line2d()
// Usage:
//   right_of_line2d(line, pt)
// Description:
//   Returns true if the given point is to the left of the extended line defined by two points on it.
// Arguments:
//   line = A list of two points.
//   pt = The point to test.
function right_of_line2d(line, pt) =
	triangle_area2d(line[0], line[1], pt) < 0;


// Function: collinear()
// Usage:
//   collinear(a, b, c, [eps]);
// Description:
//   Returns true if three points are co-linear.
// Arguments:
//   a = First point.
//   b = Second point.
//   c = Third point.
//   eps = Acceptable variance.  Default: `EPSILON` (1e-9)
function collinear(a, b, c, eps=EPSILON) =
	distance_from_line([a,b], c) < eps;


// Function: collinear_indexed()
// Usage:
//   collinear_indexed(points, a, b, c, [eps]);
// Description:
//   Returns true if three points are co-linear.
// Arguments:
//   points = A list of points.
//   a = Index in `points` of first point.
//   b = Index in `points` of second point.
//   c = Index in `points` of third point.
//   eps = Acceptable max angle variance.  Default: EPSILON (1e-9) degrees.
function collinear_indexed(points, a, b, c, eps=EPSILON) =
	let(
		p1=points[a],
		p2=points[b],
		p3=points[c]
	) collinear(p1, p2, p3, eps);


// Function: distance_from_line()
// Usage:
//   distance_from_line(line, pt);
// Description:
//   Finds the perpendicular distance of a point `pt` from the line `line`.
// Arguments:
//   line = A list of two points, defining a line that both are on.
//   pt = A point to find the distance of from the line.
// Example:
//   distance_from_line([[-10,0], [10,0]], [3,8]);  // Returns: 8
function distance_from_line(line, pt) =
	let(a=line[0], n=normalize(line[1]-a), d=a-pt)
	norm(d - ((d * n) * n));



// Function: triangle_area2d()
// Usage:
//   triangle_area2d(a,b,c);
// Description:
//   Returns the area of a triangle formed between three vertices.
//   Result will be negative if the points are in clockwise order.
// Examples:
//   triangle_area2d([0,0], [5,10], [10,0]);  // Returns -50
//   triangle_area2d([10,0], [5,10], [0,0]);  // Returns 50
function triangle_area2d(a,b,c) =
	(
		a.x * (b.y - c.y) + 
		b.x * (c.y - a.y) + 
		c.x * (a.y - b.y)
	) / 2;


// Section: Planes

// Function: plane3pt()
// Usage:
//   plane3pt(p1, p2, p3);
// Description:
//   Generates the cartesian equation of a plane from three non-collinear points on the plane.
//   Returns [A,B,C,D] where Ax+By+Cz+D=0 is the equation of a plane.
// Arguments:
//   p1 = The first point on the plane.
//   p2 = The second point on the plane.
//   p3 = The third point on the plane.
function plane3pt(p1, p2, p3) =
	let(
		p1=point3d(p1),
		p2=point3d(p2),
		p3=point3d(p3),
		normal = normalize(cross(p3-p1, p2-p1))
	) concat(normal, [normal*p1]);


// Function: plane3pt_indexed()
// Usage:
//   plane3pt_indexed(points, i1, i2, i3);
// Description:
//   Given a list of points, and the indexes of three of those points,
//   generates the cartesian equation of a plane that those points all
//   lie on.  Requires that the three indexed points be non-collinear.
//   Returns [A,B,C,D] where Ax+By+Cz+D=0 is the equation of a plane.
// Arguments:
//   points = A list of points.
//   i1 = The index into `points` of the first point on the plane.
//   i2 = The index into `points` of the second point on the plane.
//   i3 = The index into `points` of the third point on the plane.
function plane3pt_indexed(points, i1, i2, i3) =
	let(
		p1 = points[i1],
		p2 = points[i2],
		p3 = points[i3]
	) plane3pt(p1,p2,p3);


// Function: distance_from_plane()
// Usage:
//   distance_from_plane(plane, point)
// Description:
//   Given a plane as [A,B,C,D] where the cartesian equation for that plane
//   is Ax+By+Cz+D=0, determines how far from that plane the given point is.
//   The returned distance will be positive if the point is in front of the
//   plane; on the same side of the plane as the normal of that plane points
//   towards.  If the point is behind the plane, then the distance returned
//   will be negative.  The normal of the plane is the same as [A,B,C].
// Arguments:
//   plane = The [A,B,C,D] values for the equation of the plane.
//   point = The point to test.
function distance_from_plane(plane, point) =
	[plane.x, plane.y, plane.z] * point - plane[3];


// Function: coplanar()
// Usage:
//   coplanar(plane, point);
// Description:
//   Given a plane as [A,B,C,D] where the cartesian equation for that plane
//   is Ax+By+Cz+D=0, determines if the given point is on that plane.
//   Returns true if the point is on that plane.
// Arguments:
//   plane = The [A,B,C,D] values for the equation of the plane.
//   point = The point to test.
function coplanar(plane, point) =
	abs(distance_from_plane(plane, point)) <= EPSILON;


// Function: in_front_of_plane()
// Usage:
//   in_front_of_plane(plane, point);
// Description:
//   Given a plane as [A,B,C,D] where the cartesian equation for that plane
//   is Ax+By+Cz+D=0, determines if the given point is on the side of that
//   plane that the normal points towards.  The normal of the plane is the
//   same as [A,B,C].
// Arguments:
//   plane = The [A,B,C,D] values for the equation of the plane.
//   point = The point to test.
function in_front_of_plane(plane, point) =
	distance_from_plane(plane, point) > EPSILON;



// Section: Paths and Polygons


// Function: simplify_path()
// Description:
//   Takes a path and removes unnecessary collinear points.
// Usage:
//   simplify_path(path, [eps])
// Arguments:
//   path = A list of 2D path points.
//   eps = Largest positional variance allowed.  Default: `EPSILON` (1-e9)
function simplify_path(path, eps=EPSILON) =
	len(path)<=2? path : let(
		indices = concat([0], [for (i=[1:len(path)-2]) if (!collinear_indexed(path, i-1, i, i+1, eps=eps)) i], [len(path)-1])
	) [for (i = indices) path[i]];



// Function: simplify_path_indexed()
// Description:
//   Takes a list of points, and a path as a list of indexes into `points`,
//   and removes all path points that are unecessarily collinear.
// Usage:
//   simplify_path_indexed(path, eps)
// Arguments:
//   points = A list of points.
//   path = A list of indexes into `points` that forms a path.
//   eps = Largest angle variance allowed.  Default: EPSILON (1-e9) degrees.
function simplify_path_indexed(points, path, eps=EPSILON) =
	len(path)<=2? path : let(
		indices = concat([0], [for (i=[1:len(path)-2]) if (!collinear_indexed(points, path[i-1], path[i], path[i+1], eps=eps)) i], [len(path)-1])
	) [for (i = indices) path[i]];



// Function: point_in_polygon()
// Usage:
//   point_in_polygon(point, path)
// Description:
//   This function tests whether the given point is inside, outside or on the boundary of
//   the specified polygon using the Winding Number method.
//   The polygon is given as a list of points, not including the repeated end point.
//   Returns -1 if the point is outside the polyon.
//   Returns 0 if the point is on the boundary.
//   Returns 1 if the point lies in the interior.
//   The polygon does not need to be simple: it can have self-intersections.
//   But the polygon cannot have holes (it must be simply connected).
//   Rounding error may give mixed results for points on or near the boundary.
// Arguments:
//   point = The point to check position of.
//   path = The list of 2D path points forming the perimeter of the polygon.
function point_in_polygon(point, path) =
	// Does the point lie on any edges?  If so return 0. 
	sum([for(i=[0:len(path)-1]) point_on_segment2d(point, select(path, i, i+1))?1:0])>0 ? 0 : 
	// Otherwise compute winding number and return 1 for interior, -1 for exterior
	sum([for(i=[0:len(path)-1]) _point_above_below_segment(point, select(path, i, i+1))]) != 0 ? 1 : -1;


// Function: pointlist_bounds()
// Usage:
//   pointlist_bounds(pts);
// Description:
//   Finds the bounds containing all the points in pts.
//   Returns [[minx, miny, minz], [maxx, maxy, maxz]]
// Arguments:
//   pts = List of points.
function pointlist_bounds(pts) = [
	[for (a=[0:2]) min([ for (x=pts) point3d(x)[a] ]) ],
	[for (a=[0:2]) max([ for (x=pts) point3d(x)[a] ]) ]
];


// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
