//////////////////////////////////////////////////////////////////////
// LibFile: geometry.scad
//   Geometry helpers.
//   To use, add the following lines to the beginning of your file:
//   ```
//   use <BOSL2/std.scad>
//   ```
//////////////////////////////////////////////////////////////////////


// CommonCode:
//   include <BOSL2/roundcorners.scad>


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
//   eps = Acceptable variance.  Default: `EPSILON` (1e-9)
function point_on_segment2d(point, edge, eps=EPSILON) =
	approx(point,edge[0],eps=eps) || approx(point,edge[1],eps=eps) ||  // The point is an endpoint
	sign(edge[0].x-point.x)==sign(point.x-edge[1].x)  // point is in between the
		&& sign(edge[0].y-point.y)==sign(point.y-edge[1].y)  // edge endpoints
		&& approx(point_left_of_segment2d(point, edge),0,eps=eps);  // and on the line defined by edge


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
function _point_above_below_segment(point, edge, eps=EPSILON) =
	edge[0].y <= point.y+eps? (
		(edge[1].y > point.y-eps && point_left_of_segment2d(point, edge) > eps)? 1 : 0
	) : (
		(edge[1].y <= point.y+eps && point_left_of_segment2d(point, edge) < eps)? -1 : 0
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



// Function: line_normal()
// Usage:
//   line_normal([P1,P2])
//   line_normal(p1,p2)
// Description: Returns the 2D normal vector to the given 2D line.
// Arguments:
//   p1 = First point on 2D line.
//   p2 = Second point on 2D line.
function line_normal(p1,p2) =
	is_undef(p2)? line_normal(p1[0],p1[1]) :
	normalize([p1.y-p2.y,p2.x-p1.x]);


// 2D Line intersection from two segments.
// This function returns [p,t,u] where p is the intersection point of
// the lines defined by the two segments, t is the bezier parameter
// for the intersection point on s1 and u is the bezier parameter for
// the intersection point on s2.  The bezier parameter runs over [0,1]
// for each segment, so if it is in this range, then the intersection
// lies on the segment.  Otherwise it lies somewhere on the extension
// of the segment.
function _general_line_intersection(s1,s2,eps=EPSILON) =
	let(
		denominator = det2([s1[0],s2[0]]-[s1[1],s2[1]])
	) approx(denominator,0,eps=eps)? [undef,undef,undef] : let(
		t = det2([s1[0],s2[0]]-s2) / denominator,
		u = det2([s1[0],s1[0]]-[s1[1],s2[1]]) /denominator
	) [s1[0]+t*(s1[1]-s1[0]), t, u];


// Function: line_intersection()
// Usage:
//   line_intersection(l1, l2);
// Description:
//   Returns the 2D intersection point of two unbounded 2D lines.
//   Returns `undef` if the lines are parallel.
// Arguments:
//   l1 = First 2D line, given as a list of two 2D points on the line.
//   l2 = Second 2D line, given as a list of two 2D points on the line.
function line_intersection(l1,l2,eps=EPSILON) =
	let(isect = _general_line_intersection(l1,l2,eps=eps)) isect[0];


// Function: segment_intersection()
// Usage:
//   segment_intersection(s1, s2);
// Description:
//   Returns the 2D intersection point of two 2D line segments.
//   Returns `undef` if they do not intersect.
// Arguments:
//   s1 = First 2D segment, given as a list of the two 2D endpoints of the line segment.
//   s2 = Second 2D segment, given as a list of the two 2D endpoints of the line segment.
//   eps = Acceptable variance.  Default: `EPSILON` (1e-9)
function segment_intersection(s1,s2,eps=EPSILON) =
	let(
		isect = _general_line_intersection(s1,s2,eps=eps)
	) isect[1]<0-eps || isect[1]>1+eps || isect[2]<0-eps || isect[2]>1+eps ? undef : isect[0];


// Function: line_segment_intersection()
// Usage:
//   line_segment_intersection(line, segment);
// Description:
//   Returns the 2D intersection point of an unbounded 2D line, and a bounded 2D line segment.
//   Returns `undef` if they do not intersect.
// Arguments:
//   line = The unbounded 2D line, defined by two 2D points on the line.
//   segment = The bounded 2D line  segment, given as a list of the two 2D endpoints of the segment.
//   eps = Acceptable variance.  Default: `EPSILON` (1e-9)
function line_segment_intersection(line,segment,eps=EPSILON) =
	let(
		isect = _general_line_intersection(line,segment,eps=eps)
	) isect[2]<0-eps || isect[2]>1+eps ? undef : isect[0];


// Function: find_circle_2tangents()
// Usage:
//   find_circle_2tangents(pt1, pt2, pt3, r|d);
// Description:
//   Returns [centerpoint, normal] of a circle of known size that is between and tangent to two rays with the same starting point.
//   Both rays start at `pt2`, and one passes through `pt1`, while the other passes through `pt3`.
//   If the rays given are 180º apart, `undef` is returned.  If the rays are 3D, the normal returned is the plane normal of the circle.
// Arguments:
//   pt1 = A point that the first ray passes though.
//   pt2 = The starting point of both rays.
//   pt3 = A point that the second ray passes though.
//   r = The radius of the circle to find.
//   d = The diameter of the circle to find.
function find_circle_2tangents(pt1, pt2, pt3, r=undef, d=undef) =
	let(
		r = get_radius(r=r, d=d, dflt=undef),
		v1 = normalize(pt1 - pt2),
		v2 = normalize(pt3 - pt2)
	) approx(norm(v1+v2))? undef :
	assert(r!=undef, "Must specify either r or d.")
	let(
		a = vector_angle(v1,v2),
		n = vector_axis(v1,v2),
		v = normalize(mean([v1,v2])),
		s = r/sin(a/2),
		cp = pt2 + s*v/norm(v)
	) [cp, n];


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


// Function: plane_normal()
// Usage:
//   plane_normal(plane);
// Description:
//   Returns the normal vector for the given plane.
function plane_normal(plane) = [for (i=[0:2]) plane[i]];


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


// Function: is_path()
// Usage:
//   is_path(x);
// Description:
//   Returns true if the given item looks like a path.
function is_path(x) = is_list(x) && is_vector(x.x);


// Function: is_closed_path()
// Usage:
//   is_closed_path(path, [eps]);
// Description:
//   Returns true if the first and last points in the given path are coincident.
function is_closed_path(path, eps=EPSILON) = approx(path[0], path[len(path)-1], eps=eps);


// Function: close_path(path)
// Usage:
//   close_path(path);
// Description:
//   If a path's last point does not coincide with its first point, closes the path so it does.
function close_path(path, eps=EPSILON) = is_closed_path(path,eps=eps)? path : concat(path,[path[0]]);


// Function path_subselect()
// Usage:
//   path_subselect(path,s1,u1,s2,u2):
// Description:
//   Returns a portion of a path, from between the `u1` part of segment `s1`, to the `u2` part of
//   segment `s2`.  Both `u1` and `u2` are values between 0.0 and 1.0, inclusive, where 0 is the start
//   of the segment, and 1 is the end.  Both `s1` and `s2` are integers, where 0 is the first segment.
// Arguments:
//   s1 = The number of the starting segment.
//   u1 = The proportion along the starting segment, between 0.0 and 1.0, inclusive.
//   s2 = The number of the ending segment.
//   u2 = The proportion along the ending segment, between 0.0 and 1.0, inclusive.
function path_subselect(path,s1,u1,s2,u2) =
	let(
		l = len(path)-1,
		u1 = s1<0? 0 : s1>l? 1 : u1,
		u2 = s2<0? 0 : s2>l? 1 : u2,
		s1 = constrain(s1,0,l),
		s2 = constrain(s2,0,l),
		pathout = concat(
			(s1<l)? [lerp(path[s1],path[s1+1],u1)] : [],
			[for (i=[s1+1:1:s2]) path[i]],
			(s2<l)? [lerp(path[s2],path[s2+1],u2)] : []
		)
	) pathout;


// Function: assemble_path_fragments()
// Usage:
//   assemble_path_fragments(subpaths);
// Description:
//   Given a list of incomplete paths, assembles them together into complete closed paths if it can.
function assemble_path_fragments(subpaths,eps=EPSILON,_finished=[]) =
	len(subpaths)<=1? concat(_finished, subpaths) :
	let(
		path = subpaths[0]
	) is_closed_path(path, eps=eps)? (
		assemble_path_fragments(
			[for (i=[1:1:len(subpaths)-1]) subpaths[i]],
			eps=eps,
			_finished=concat(_finished, [path])
		)
	) : let(
		matches = [
			for (i=[1:1:len(subpaths)-1], rev1=[0,1], rev2=[0,1]) let(
				idx1 = rev1? 0 : len(path)-1,
				idx2 = rev2? len(subpaths[i])-1 : 0
			) if (approx(path[idx1], subpaths[i][idx2], eps=eps)) [
				i, concat(
					rev1? reverse(path) : path,
					select(rev2? reverse(subpaths[i]) : subpaths[i], 1,-1)
				)
			]
		]
	) len(matches)==0? (
		assemble_path_fragments(
			select(subpaths,1,-1),
			eps=eps,
			_finished=concat(_finished, [path])
		)
	) : is_closed_path(matches[0][1], eps=eps)? (
		assemble_path_fragments(
			[for (i=[1:1:len(subpaths)-1]) if(i != matches[0][0]) subpaths[i]],
			eps=eps,
			_finished=concat(_finished, [matches[0][1]])
		)
	) : (
		assemble_path_fragments(
			concat(
				[matches[0][1]],
				[for (i = [1:1:len(subpaths)-1]) if(i != matches[0][0]) subpaths[i]]
			),
			eps=eps,
			_finished=_finished
		)
	);


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
		indices = concat([0], [for (i=[1:1:len(path)-2]) if (!collinear_indexed(path, i-1, i, i+1, eps=eps)) i], [len(path)-1])
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
		indices = concat([0], [for (i=[1:1:len(path)-2]) if (!collinear_indexed(points, path[i-1], path[i], path[i+1], eps=eps)) i], [len(path)-1])
	) [for (i = indices) path[i]];



// Function: point_in_polygon()
// Usage:
//   point_in_polygon(point, path)
// Description:
//   This function tests whether the given point is inside, outside or on the boundary of
//   the specified 2D polygon using the Winding Number method.
//   The polygon is given as a list of 2D points, not including the repeated end point.
//   Returns -1 if the point is outside the polyon.
//   Returns 0 if the point is on the boundary.
//   Returns 1 if the point lies in the interior.
//   The polygon does not need to be simple: it can have self-intersections.
//   But the polygon cannot have holes (it must be simply connected).
//   Rounding error may give mixed results for points on or near the boundary.
// Arguments:
//   point = The point to check position of.
//   path = The list of 2D path points forming the perimeter of the polygon.
//   eps = Acceptable variance.  Default: `EPSILON` (1e-9)
function point_in_polygon(point, path, eps=EPSILON) =
	// Does the point lie on any edges?  If so return 0.
	sum([for(i=[0:1:len(path)-1]) point_on_segment2d(point, select(path, i, i+1), eps=eps)?1:0])>0 ? 0 :
	// Otherwise compute winding number and return 1 for interior, -1 for exterior
	sum([for(i=[0:1:len(path)-1]) _point_above_below_segment(point, select(path, i, i+1), eps=eps)]) != 0 ? 1 : -1;


// Function: point_in_region()
// Usage:
//   point_in_region(point, region);
// Description:
//   Tests if a point is inside, outside, or on the border of a region.
//   Returns -1 if the point is outside the region.
//   Returns 0 if the point is on the boundary.
//   Returns 1 if the point lies inside the region.
// Arguments:
//   point = The point to test.
//   region = The region to test against.  Given as a list of polygon paths.
//   eps = Acceptable variance.  Default: `EPSILON` (1e-9)
function point_in_region(point, region, eps=EPSILON, _i=0, _cnt=0) =
	(_i >= len(region))? ((_cnt%2==1)? 1 : -1) : let(
		pip = point_in_polygon(point, region[_i], eps=eps)
	) approx(pip,0,eps=eps)? 0 : point_in_region(point, region, eps=eps, _i=_i+1, _cnt = _cnt + (pip>eps? 1 : 0));


// Function: pointlist_bounds()
// Usage:
//   pointlist_bounds(pts);
// Description:
//   Finds the bounds containing all the 2D or 3D points in `pts`.
//   Returns [[minx, miny, minz], [maxx, maxy, maxz]]
// Arguments:
//   pts = List of points.
function pointlist_bounds(pts) = [
	[for (a=[0:2]) min([ for (x=pts) point3d(x)[a] ]) ],
	[for (a=[0:2]) max([ for (x=pts) point3d(x)[a] ]) ]
];


// Function: polygon_clockwise()
// Usage:
//   polygon_clockwise(path);
// Description:
//   Return true if the given 2D simple polygon is in clockwise order, false otherwise.
//   Results for complex (self-intersecting) polygon are indeterminate.
// Arguments:
//   path = The list of 2D path points for the perimeter of the polygon.
function polygon_clockwise(path) =
	let(
		minx = min(subindex(path,0)),
		lowind = search(minx, path, 0, 0),
		lowpts = select(path, lowind),
		miny = min(subindex(lowpts, 1)),
		extreme_sub = search(miny, lowpts, 1, 1)[0],
		extreme = select(lowind,extreme_sub)
	) det2([select(path,extreme+1)-path[extreme], select(path, extreme-1)-path[extreme]])<0;



// Section: Regions and Boolean 2D Geometry


// Function: is_region()
// Usage:
//   is_region(x);
// Description:
//   Returns true if the given item looks like a region, which is a list of paths.
function is_region(x) = is_list(x) && is_path(x.x);


// Function: close_region(path)
// Usage:
//   close_region(region);
// Description:
//   Closes all paths within a given region.
function close_region(region, eps=EPSILON) = [for (path=region) close_path(path, eps=eps)];


// Function: region_path_crossings()
// Usage:
//   region_path_crossings(path, region);
// Description:
//   Returns a sorted list of [SEGMENT, U] that describe where a given path is crossed by a second path.
// Arguments:
//   path = The path to find crossings on.
//   region = Region to test for crossings of.
//   eps = Acceptable variance.  Default: `EPSILON` (1e-9)
function region_path_crossings(path, region, eps=EPSILON) = sort([
	for (
		s1=enumerate(pair(close_path(path))),
		p=close_region(region),
		s2=pair(p)
	) let(
		isect = _general_line_intersection(s1[1],s2,eps=eps)
	) if (
		!is_undef(isect) &&
		isect[1] >= 0-eps && isect[1] < 1+eps &&
		isect[2] >= 0-eps && isect[2] < 1+eps
	)
	[s1[0], isect[1]]
]);


function _offset_chamfer(center, points, delta) =
	let(
		dist = sign(delta)*norm(center-line_intersection(select(points,[0,2]), [center, points[1]])),
		endline = _shift_segment(select(points,[0,2]), delta-dist)
	) [
		line_intersection(endline, select(points,[0,1])),
		line_intersection(endline, select(points,[1,2]))
	];


function _shift_segment(segment, d) =
	move(d*line_normal(segment),segment);


// Extend to segments to their intersection point.  First check if the segments already have a point in common,
// which can happen if two colinear segments are input to the path variant of `offset()`
function _segment_extension(s1,s2) =
	norm(s1[1]-s2[0])<1e-6 ? s1[1] : line_intersection(s1,s2);


function _makefaces(direction, startind, good, pointcount, closed) =
	let(
		lenlist = list_bset(good, pointcount),
		numfirst = len(lenlist),
		numsecond = sum(lenlist),
		prelim_faces = _makefaces_recurse(startind, startind+len(lenlist), numfirst, numsecond, lenlist, closed)
	)
	direction? [for(entry=prelim_faces) reverse(entry)] : prelim_faces;


function _makefaces_recurse(startind1, startind2, numfirst, numsecond, lenlist, closed, firstind=0, secondind=0, faces=[]) =
	// We are done if *both* firstind and secondind reach their max value, which is the last point if !closed or one past
	// the last point if closed (wrapping around).  If you don't check both you can leave a triangular gap in the output.
	((firstind == numfirst - (closed?0:1)) && (secondind == numsecond - (closed?0:1)))? faces :
	_makefaces_recurse(
		startind1, startind2, numfirst, numsecond, lenlist, closed, firstind+1, secondind+lenlist[firstind],
		lenlist[firstind]==0? (
			// point in original path has been deleted in offset path, so it has no match.  We therefore
			// make a triangular face using the current point from the offset (second) path
			// (The current point in the second path can be equal to numsecond if firstind is the last point)
			concat(faces,[[secondind%numsecond+startind2, firstind+startind1, (firstind+1)%numfirst+startind1]])
			// in this case a point or points exist in the offset path corresponding to the original path
		) : (
			concat(faces,
				// First generate triangular faces for all of the extra points (if there are any---loop may be empty)
				[for(i=[0:1:lenlist[firstind]-2]) [firstind+startind1, secondind+i+1+startind2, secondind+i+startind2]],
				// Finish (unconditionally) with a quadrilateral face
				[
					[
						firstind+startind1,
						(firstind+1)%numfirst+startind1,
						(secondind+lenlist[firstind])%numsecond+startind2,
						(secondind+lenlist[firstind]-1)%numsecond+startind2
					]
				]
			)
		)
	);


// Determine which of the shifted segments are good
function _good_segments(path, d, shiftsegs, closed, quality) =
	let(
		maxind = len(path)-(closed ? 1 : 2),
		pathseg = [for(i=[0:maxind]) select(path,i+1)-path[i]],
		pathseg_len =  [for(seg=pathseg) norm(seg)],
		pathseg_unit = [for(i=[0:maxind]) pathseg[i]/pathseg_len[i]],
		// Order matters because as soon as a valid point is found, the test stops
		// This order works better for circular paths because they succeed in the center
		alpha = concat([for(i=[1:1:quality]) i/(quality+1)],[0,1])
	) [
		for (i=[0:len(shiftsegs)-1])
			(i>maxind)? true :
			_segment_good(path,pathseg_unit,pathseg_len, d - 1e-4, shiftsegs[i], alpha)
	];


// Determine if a segment is good (approximately)
// Input is the path, the path segments normalized to unit length, the length of each path segment
// the distance threshold, the segment to test, and the locations on the segment to test (normalized to [0,1])
// The last parameter, index, gives the current alpha index.
//
// A segment is good if any part of it is farther than distance d from the path.  The test is expensive, so
// we want to quit as soon as we find a point with distance > d, hence the recursive code structure.
//
// This test is approximate because it only samples the points listed in alpha.  Listing more points
// will make the test more accurate, but slower.
function _segment_good(path,pathseg_unit,pathseg_len, d, seg,alpha ,index=0) =
	index == len(alpha) ? false :
	_point_dist(path,pathseg_unit,pathseg_len, alpha[index]*seg[0]+(1-alpha[index])*seg[1]) > d ? true :
	_segment_good(path,pathseg_unit,pathseg_len,d,seg,alpha,index+1);


// Input is the path, the path segments normalized to unit length, the length of each path segment
// and a test point.  Computes the (minimum) distance from the path to the point, taking into
// account that the minimal distance may be anywhere along a path segment, not just at the ends.
function _point_dist(path,pathseg_unit,pathseg_len,pt) =
	min([
		for(i=[0:len(pathseg_unit)-1]) let(
			v = pt-path[i],
			projection = v*pathseg_unit[i],
			segdist = projection < 0? norm(pt-path[i]) :
				projection > pathseg_len[i]? norm(pt-select(path,i+1)) :
				norm(v-projection*pathseg_unit[i])
		) segdist
	]);


function _offset_region(
	paths, r, delta, chamfer, closed,
	maxstep, check_valid, quality,
	return_faces, firstface_index,
	flip_faces, _acc=[], _i=0
) =
	_i>=len(paths)? _acc :
	_offset_region(
		paths, _i=_i+1,
		_acc = (paths[_i].x % 2 == 0)? (
			union(_acc, [
				offset(
					paths[_i].y,
					r=r, delta=delta, chamfer=chamfer, closed=closed,
					maxstep=maxstep, check_valid=check_valid, quality=quality,
					return_faces=return_faces, firstface_index=firstface_index,
					flip_faces=flip_faces
				)
			])
		) : (
			difference(_acc, [
				offset(
					paths[_i].y,
					r=-r, delta=-delta, chamfer=chamfer, closed=closed,
					maxstep=maxstep, check_valid=check_valid, quality=quality,
					return_faces=return_faces, firstface_index=firstface_index,
					flip_faces=flip_faces
				)
			])
		),
		r=r, delta=delta, chamfer=chamfer, closed=closed,
		maxstep=maxstep, check_valid=check_valid, quality=quality,
		return_faces=return_faces, firstface_index=firstface_index, flip_faces=flip_faces
	);


// Function: offset()
//
// Description:
//   Takes an input path and returns a path offset by the specified amount.  As with offset(), you can use
//   r to specify rounded offset and delta to specify offset with corners.  Positive offsets shift the path
//   to the left (relative to the direction of the path).
//
//   When offsets shrink the path, segments cross and become invalid.  By default `offset()` checks for this situation.
//   To test validity the code checks that segments have distance larger than (r or delta) from the input path.
//   This check takes O(N^2) time and may mistakenly eliminate segments you wanted included in various situations,
//   so you can disable it if you wish by setting check_valid=false.  Another situation is that the test is not
//   sufficiently thorough and some segments persist that should be eliminated.  In this case, increase `quality`
//   to 2 or 3.  (This increases the number of samples on the segment that are checked.)  Run time will increase.
//   In some situations you may be able to decrease run time by setting quality to 0, which causes only segment
//   ends to be checked.
//
//   For construction of polyhedra `offset()` can also return face lists.  These list faces between the
//   original path and the offset path where the vertices are ordered with the original path first,
//   starting at `firstface_index` and the offset path vertices appearing afterwords.  The direction
//   of the faces can be flipped using `flip_faces`.  When you request faces the return value
//   is a list: [offset_path, face_list].
//
// Arguments:
//   path = the path to process.  A list of 2d points.
//   r = offset radius.  Distance to offset.  Will round over corners.
//   delta = offset distance.  Distance to offset with pointed corners.
//   chamfer = chamfer corners when you specify `delta`.  Default: false
//   closed = path is a closed curve. Default: False.
//   check_valid = perform segment validity check.  Default: True.
//   quality = validity check quality parameter, a small integer.  Default: 1.
//   return_faces = return face list.  Default: False.
//   firstface_index = starting index for face list.  Default: 0.
//   flip_faces = flip face direction.  Default: false
// Example(2D):
//   test = [[0,0],[10,0],[10,7],[0,7], [-1,-3]];
//   polygon(offset(test,r=1.9, closed=true, check_valid=true,quality=2));
//   %down(.1)polygon(test);
// Example(2D):
//   star = star(5, r=100, ir=30);
//   #stroke(close=true, star);
//   stroke(close=true, offset(star, delta=-10, closed=true));
// Example(2D):
//   star = star(5, r=100, ir=30);
//   #stroke(close=true, star);
//   stroke(close=true, offset(star, delta=-10, chamfer=true, closed=true));
// Example(2D):
//   star = star(5, r=100, ir=30);
//   #stroke(close=true, star);
//   stroke(close=true, offset(star, r=-10, closed=true));
// Example(2D):
//   star = star(5, r=100, ir=30);
//   #stroke(close=true, star);
//   stroke(close=true, offset(star, delta=10, closed=true));
// Example(2D):
//   star = star(5, r=100, ir=30);
//   #stroke(close=true, star);
//   stroke(close=true, offset(star, delta=-10, chamfer=true, closed=true));
// Example(2D):
//   star = star(5, r=100, ir=30);
//   #stroke(close=true, star);
//   stroke(close=true, offset(star, r=10, closed=true));
// Example(2D):
//   ellipse = scale([1,0.3,1], p=circle(r=100));
//   #stroke(close=true, ellipse);
//   stroke(close=true, offset(ellipse, r=-15, check_valid=true, closed=true));
// Example(2D):
//   sinpath = 2*[for(theta=[-180:5:180]) [theta/4,45*sin(theta)]];
//   #stroke(sinpath);
//   stroke(offset(sinpath, r=17.5));
// Example(2D): Region
//   rgn = difference(circle(d=100), union(square([20,40], center=true), square([40,20], center=true)));
//   #linear_extrude(height=1.1) for (p=rgn) stroke(close=true, width=0.5, p);
//   region(offset(rgn, r=-5));
function offset(
	path, r=undef, delta=undef, chamfer=false,
	maxstep=0.1, closed=false, check_valid=true,
	quality=1, return_faces=false, firstface_index=0,
	flip_faces=false
) =
	is_region(path)? (
		let(
			path = [for (p=path) polygon_clockwise(p)? p : reverse(p)],
			rgn = exclusive_or([for (p = path) [p]]),
			pathlist = sort(idx=0,[
				for (i=[0:1:len(rgn)-1]) [
					sum([
						for (j=[0:1:len(rgn)-1]) if (i!=j)
							point_in_polygon(rgn[i][0],rgn[j])>=0? 1 : 0
					]),
					rgn[i]
				]
			])
		) _offset_region(
			pathlist, r=r, delta=delta, chamfer=chamfer, closed=true,
			maxstep=maxstep, check_valid=check_valid, quality=quality,
			return_faces=return_faces, firstface_index=firstface_index,
			flip_faces=flip_faces
		)
	) : let(rcount = num_defined([r,delta]))
	assert(rcount==1,"Must define exactly one of 'delta' and 'r'")
	let(
		chamfer = is_def(r) ? false : chamfer,
		quality = max(0,round(quality)),
		d = is_def(r)? r : delta,
		shiftsegs = [for(i=[0:len(path)-1]) _shift_segment(select(path,i,i+1), d)],
		// good segments are ones where no point on the segment is less than distance d from any point on the path
		good = check_valid ? _good_segments(path, abs(d), shiftsegs, closed, quality) : replist(true,len(shiftsegs)),
		goodsegs = bselect(shiftsegs, good),
		goodpath = bselect(path,good)
	)
	assert(len(goodsegs)>0,"Offset of path is degenerate")
	let(
		// Extend the shifted segments to their intersection points
		sharpcorners = [for(i=[0:len(goodsegs)-1]) _segment_extension(select(goodsegs,i-1), select(goodsegs,i))],
		// If some segments are parallel then the extended segments are undefined.  This case is not handled
		// Note if !closed the last corner doesn't matter, so exclude it
		parallelcheck =
			(len(sharpcorners)==2 && !closed) ||
			all_defined(select(sharpcorners,closed?0:1,-1))
	)
	assert(parallelcheck, "Path turns back on itself (180 deg turn)")
	let(
		// This is a boolean array that indicates whether a corner is an outside or inside corner
		// For outside corners, the newcorner is an extension (angle 0), for inside corners, it turns backward
		// If either side turns back it is an inside corner---must check both.
		// Outside corners can get rounded (if r is specified and there is space to round them)
		outsidecorner = [
			for(i=[0:len(goodsegs)-1]) let(
				prevseg=select(goodsegs,i-1)
			) (
				(goodsegs[i][1]-goodsegs[i][0]) *
				(goodsegs[i][0]-sharpcorners[i]) > 0
			) && (
				(prevseg[1]-prevseg[0]) *
				(sharpcorners[i]-prevseg[1]) > 0
			)
		],
		steps = is_def(delta) ? [] : [
			for(i=[0:len(goodsegs)-1])
			ceil(
				abs(r)*vector_angle(
					select(goodsegs,i-1)[1]-goodpath[i],
					goodsegs[i][0]-goodpath[i]
				)*PI/180/maxstep
			)
		],
		// If rounding is true then newcorners replaces sharpcorners with rounded arcs where needed
		// Otherwise it's the same as sharpcorners
		// If rounding is on then newcorners[i] will be the point list that replaces goodpath[i] and newcorners later
		// gets flattened.  If rounding is off then we set it to [sharpcorners] so we can later flatten it and get
		// plain sharpcorners back.
		newcorners = is_def(delta) && !chamfer ? [sharpcorners] : [
			for(i=[0:len(goodsegs)-1]) (
				(!chamfer && steps[i] <=2)  //Chamfer all points but only round if steps is 3 or more
				|| !outsidecorner[i]        // Don't round inside corners
				|| (!closed && (i==0 || i==len(goodsegs)-1))  // Don't round ends of an open path
			)? [sharpcorners[i]] : (
				chamfer?
					_offset_chamfer(
						goodpath[i], [
							select(goodsegs,i-1)[1],
							sharpcorners[i],
							goodsegs[i][0]
						], d
					) :
				arc(
					cp=goodpath[i],
					points=[
						select(goodsegs,i-1)[1],
						goodsegs[i][0]
					],
					N=steps[i]
				)
			)
		],
		pointcount = (is_def(delta) && !chamfer)?
			replist(1,len(sharpcorners)) :
			[for(i=[0:len(goodsegs)-1]) len(newcorners[i])],
		start = [goodsegs[0][0]],
		end = [goodsegs[len(goodsegs)-2][1]],
		edges =  closed?
			flatten(newcorners) :
			concat(start,slice(flatten(newcorners),1,-2),end),
		faces = !return_faces? [] :
			_makefaces(
				flip_faces, firstface_index, good,
				pointcount, closed
			)
	) return_faces? [edges,faces] : edges;


function _split_path_at_region_crossings(path, region, eps=EPSILON) =
	let(
		path = deduplicate(path, eps=eps),
		region = [for (path=region) deduplicate(path, eps=eps)],
		xings = region_path_crossings(path, region, eps=eps),
		crossings = deduplicate(
			concat(
				[[0,0]],
				xings,
				[[len(path)-2,1]]
			),
			eps=eps
		),
		subpaths = [
			for (p = pair(crossings))
				deduplicate(eps=eps,
					path_subselect(path, p[0][0], p[0][1], p[1][0], p[1][1])
				)
		]
	)
	subpaths;


function _tag_subpaths(path, region, eps=EPSILON) =
	let(
		subpaths = _split_path_at_region_crossings(path, region, eps=eps),
		tagged = [
			for (sub = subpaths) let(
				subpath = deduplicate(sub)
			) if (len(sub)>1) let(
				midpt = lerp(subpath[0], subpath[1], 0.5),
				rel = point_in_region(midpt,region,eps=eps)
			) rel<0? ["O", subpath] : rel>0? ["I", subpath] : let(
				vec = normalize(subpath[1]-subpath[0]),
				perp = rot(90, planar=true, p=vec),
				sidept = midpt + perp*0.01,
				rel1 = point_in_polygon(sidept,path,eps=eps)>0,
				rel2 = point_in_region(sidept,region,eps=eps)>0
			) rel1==rel2? ["S", subpath] : ["U", subpath]
		]
	) tagged;


function _tag_region_subpaths(region1, region2, eps=EPSILON) =
	[for (path=region1) each _tag_subpaths(path, region2, eps=eps)];


function _tagged_region(region1,region2,keep1,keep2,eps=EPSILON) =
	let(
		region1 = close_region(region1, eps=eps),
		region2 = close_region(region2, eps=eps),
		tagged1 = _tag_region_subpaths(region1, region2, eps=eps),
		tagged2 = _tag_region_subpaths(region2, region1, eps=eps),
		tagged = concat(
			[for (tagpath = tagged1) if (in_list(tagpath[0], keep1)) tagpath[1]],
			[for (tagpath = tagged2) if (in_list(tagpath[0], keep2)) tagpath[1]]
		),
		outregion = assemble_path_fragments(tagged, eps=eps)
	) outregion;


// Function&Module: union()
// Usage:
//   union() {...}
//   region = union(regions);
//   region = union(REGION1,REGION2);
//   region = union(REGION1,REGION2,REGION3);
// Description:
//   When called as a function and given a list of regions, where each region is a list of closed
//   2D paths, returns the boolean union of all given regions.  Result is a single region.
//   When called as the built-in module, makes the boolean union of the given children.
// Arguments:
//   regions = List of regions to union.  Each region is a list of closed paths.
// Example(2D):
//   shape1 = move([-8,-8,0], p=circle(d=50));
//   shape2 = move([ 8, 8,0], p=circle(d=50));
//   for (shape = [shape1,shape2]) color("red") stroke(shape, width=0.5, close=true);
//   color("green") region(union(shape1,shape2));
function union(regions=[],b=undef,c=undef,eps=EPSILON) =
	b!=undef? union(concat([regions],[b],c==undef?[]:[c]), eps=eps) :
	len(regions)<=1? regions[0] :
	union(
		let(regions=[for (r=regions) is_path(r)? [r] : r])
		concat(
			[_tagged_region(regions[0],regions[1],["O","S"],["O"], eps=eps)],
			[for (i=[2:1:len(regions)-1]) regions[i]]
		),
		eps=eps
	);


// Function&Module: difference()
// Usage:
//   difference() {...}
//   region = difference(regions);
//   region = difference(REGION1,REGION2);
//   region = difference(REGION1,REGION2,REGION3);
// Description:
//   When called as a function, and given a list of regions, where each region is a list of closed
//   2D paths, takes the first region and differences away all other regions from it.  The resulting
//   region is returned.
//   When called as the built-in module, makes the boolean difference of the given children.
// Arguments:
//   regions = List of regions to difference.  Each region is a list of closed paths.
// Example(2D):
//   shape1 = move([-8,-8,0], p=circle(d=50));
//   shape2 = move([ 8, 8,0], p=circle(d=50));
//   for (shape = [shape1,shape2]) color("red") stroke(shape, width=0.5, close=true);
//   color("green") region(difference(shape1,shape2));
function difference(regions=[],b=undef,c=undef,eps=EPSILON) =
	b!=undef? difference(concat([regions],[b],c==undef?[]:[c]), eps=eps) :
	len(regions)<=1? regions[0] :
	difference(
		let(regions=[for (r=regions) is_path(r)? [r] : r])
		concat(
			[_tagged_region(regions[0],regions[1],["O","U"],["I"], eps=eps)],
			[for (i=[2:1:len(regions)-1]) regions[i]]
		),
		eps=eps
	);


// Function&Module: intersection()
// Usage:
//   intersection() {...}
//   region = intersection(regions);
//   region = intersection(REGION1,REGION2);
//   region = intersection(REGION1,REGION2,REGION3);
// Description:
//   When called as a function, and given a list of regions, where each region is a list of closed
//   2D paths, returns the boolean intersection of all given regions.  Result is a single region.
//   When called as the built-in module, makes the boolean intersection of all the given children.
// Arguments:
//   regions = List of regions to intersection.  Each region is a list of closed paths.
// Example(2D):
//   shape1 = move([-8,-8,0], p=circle(d=50));
//   shape2 = move([ 8, 8,0], p=circle(d=50));
//   for (shape = [shape1,shape2]) color("red") stroke(shape, width=0.5, close=true);
//   color("green") region(intersection(shape1,shape2));
function intersection(regions=[],b=undef,c=undef,eps=EPSILON) =
	b!=undef? intersection(concat([regions],[b],c==undef?[]:[c]),eps=eps) :
	len(regions)<=1? regions[0] :
	intersection(
		let(regions=[for (r=regions) is_path(r)? [r] : r])
		concat(
			[_tagged_region(regions[0],regions[1],["I","S"],["I"],eps=eps)],
			[for (i=[2:1:len(regions)-1]) regions[i]]
		),
		eps=eps
	);


// Function&Module: exclusive_or()
// Usage:
//   exclusive_or() {...}
//   region = exclusive_or(regions);
//   region = exclusive_or(REGION1,REGION2);
//   region = exclusive_or(REGION1,REGION2,REGION3);
// Description:
//   When called as a function and given a list of regions, where each region is a list of closed
//   2D paths, returns the boolean exclusive_or of all given regions.  Result is a single region.
//   When called as a module, performs a boolean exclusive-or of up to 10 children.
// Arguments:
//   regions = List of regions to exclusive_or.  Each region is a list of closed paths.
// Example(2D): As Function
//   shape1 = move([-8,-8,0], p=circle(d=50));
//   shape2 = move([ 8, 8,0], p=circle(d=50));
//   for (shape = [shape1,shape2])
//       color("red") stroke(shape, width=0.5, close=true);
//   color("green") region(exclusive_or(shape1,shape2));
// Example(2D): As Module
//   exclusive_or() {
//       square(40,center=false);
//       circle(d=40);
//   }
function exclusive_or(regions=[],b=undef,c=undef,eps=EPSILON) =
	b!=undef? exclusive_or(concat([regions],[b],c==undef?[]:[c]),eps=eps) :
	len(regions)<=1? regions[0] :
	exclusive_or(
		let(regions=[for (r=regions) is_path(r)? [r] : r])
		concat(
			[union([
				difference([regions[0],regions[1]], eps=eps),
				difference([regions[1],regions[0]], eps=eps)
			], eps=eps)],
			[for (i=[2:1:len(regions)-1]) regions[i]]
		),
		eps=eps
	);


module exclusive_or() {
	if ($children==1) {
		children();
	} else if ($children==2) {
		difference() {
			children(0);
			children(1);
		}
		difference() {
			children(1);
			children(0);
		}
	} else if ($children==3) {
		exclusive_or() {
			exclusive_or() {
				children(0);
				children(1);
			}
			children(2);
		}
	} else if ($children==4) {
		exclusive_or() {
			exclusive_or() {
				children(0);
				children(1);
			}
			exclusive_or() {
				children(2);
				children(3);
			}
		}
	} else if ($children==5) {
		exclusive_or() {
			exclusive_or() {
				children(0);
				children(1);
				children(2);
				children(3);
			}
			children(4);
		}
	} else if ($children==6) {
		exclusive_or() {
			exclusive_or() {
				children(0);
				children(1);
				children(2);
				children(3);
			}
			children(4);
			children(5);
		}
	} else if ($children==7) {
		exclusive_or() {
			exclusive_or() {
				children(0);
				children(1);
				children(2);
				children(3);
			}
			children(4);
			children(5);
			children(6);
		}
	} else if ($children==8) {
		exclusive_or() {
			exclusive_or() {
				children(0);
				children(1);
				children(2);
				children(3);
			}
			exclusive_or() {
				children(4);
				children(5);
				children(6);
				children(7);
			}
		}
	} else if ($children==9) {
		exclusive_or() {
			exclusive_or() {
				children(0);
				children(1);
				children(2);
				children(3);
			}
			exclusive_or() {
				children(4);
				children(5);
				children(6);
				children(7);
			}
			children(8);
		}
	} else if ($children==10) {
		exclusive_or() {
			exclusive_or() {
				children(0);
				children(1);
				children(2);
				children(3);
			}
			exclusive_or() {
				children(4);
				children(5);
				children(6);
				children(7);
			}
			children(8);
			children(9);
		}
	}
}


// Module: region()
// Usage:
//   region(r);
// Description:
//   Creates 2D polygons for the given region.  The region given is a list of closed 2D paths.
//   Each path will be effectively exclusive-ORed from all other paths in the region, so if a
//   path is inside another path, it will be effectively subtracted from it.
// Example(2D):
//   region([circle(d=50), square(25,center=true)]);
// Example(2D):
//   rgn = concat(
//       [for (d=[50:-10:10]) circle(d=d-5)],
//       [square([60,10], center=true)]
//   );
//   region(rgn);
module region(r)
{
	points = flatten(r);
	paths = [
		for (i=[0:1:len(r)-1]) let(
			start = default(sum([for (j=[0:1:i-1]) len(r[j])]),0)
		) [for (k=[0:1:len(r[i])-1]) start+k]
	];
	polygon(points=points, paths=paths);
}



// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
