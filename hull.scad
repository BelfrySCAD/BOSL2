//////////////////////////////////////////////////////////////////////
// LibFile: hull.scad
//   Functions to create 2D and 3D convex hulls.
//   To use, add the following line to the beginning of your file:
//   ```
//   include <BOSL2/std.scad>
//   include <BOSL2/hull.scad>
//   ```
//   Derived from Oskar Linde's Hull:
//   - https://github.com/openscad/scad-utils
//////////////////////////////////////////////////////////////////////


// Section: Convex Hulls


// Function: hull()
// Usage:
//   hull(points);
// Description:
//   Takes a list of 2D or 3D points (but not both in the same list) and returns either the list of
//   indexes into `points` that forms the 2D convex hull perimeter path, or the list of faces that
//   form the 3d convex hull surface.  Each face is a list of indexes into `points`.  If the input
//   points are co-linear, the result will be the indexes of the two extrema points.  If the input
//   points are co-planar, the results will be a simple list of vertex indices that will form a planar
//   perimeter.  Otherwise a list of faces will be returned, where each face is a simple list of
//   vertex indices for the perimeter of the face.
// Arguments:
//   points = The set of 2D or 3D points to find the hull of.
function hull(points) = let(two_d = len(points[0]) == 2) two_d? hull2d_path(points) : hull3d_faces(points);


// Module: hull_points()
// Usage:
//   hull_points(points, [fast]);
// Description:
//   If given a list of 2D points, creates a 2D convex hull polygon that encloses all those points.
//   If given a list of 3D points, creates a 3D polyhedron that encloses all the points.  This should
//   handle about 4000 points in slow mode.  If `fast` is set to true, this should be able to handle
//   far more.
// Arguments:
//   points = The list of points to form a hull around.
//   fast = If true, uses a faster cheat that may handle more points, but also may emit warnings that can stop your script if you have "Halt on first warning" enabled.  Default: false
// Example(2D):
//   pts = [[-10,-10], [0,10], [10,10], [12,-10]];
//   hull_points(pts);
// Example:
//   pts = [for (phi = [30:60:150], theta = [0:60:359]) spherical_to_xyz(10, theta, phi)];
//   hull_points(pts);
module hull_points(points, fast=false) {
	assert(is_list(points));
	if (points) {
		assert(is_list(points[0]));
		if (fast) {
			if (len(points[0]) == 2) {
				hull() polygon(points=points);
			} else {
				extra = len(points)%3;
				faces = concat(
					[[for(i=[0:1:extra+2])i]],
					[for(i=[extra+3:3:len(points)-3])[i,i+1,i+2]]
				);
				hull() polyhedron(points=points, faces=faces);
			}
		} else {
			perim = hull(points);
			if (is_num(perim[0])) {
				polygon(points=points, paths=[perim]);
			} else {
				polyhedron(points=points, faces=perim);
			}
		}
	}
}


// Function: hull2d_path()
// Usage:
//   hull2d_path(points)
// Description:
//   Takes a list of arbitrary 2D points, and finds the minimal convex hull polygon to enclose them.
//   Returns a path as a list of indices into `points`.
// Example(2D):
//   pts = [[-10,-10], [0,10], [10,10], [12,-10]];
//   path = hull2d_path(pts);
//   place_copies(pts) color("red") sphere(1);
//   polygon(points=pts, paths=[path]);
function hull2d_path(points) =
	(len(points) < 3)? [] : let(
		a=0, b=1,
		c = _find_first_noncollinear([a,b], points, 2)
	) (c == len(points))? _hull2d_collinear(points) : let(
		remaining = [ for (i = [2:1:len(points)-1]) if (i != c) i ],
		ccw = triangle_area2d(points[a], points[b], points[c]) > 0,
		polygon = ccw? [a,b,c] : [a,c,b]
	) _hull2d_iterative(points, polygon, remaining);


// Adds the remaining points one by one to the convex hull
function _hull2d_iterative(points, polygon, remaining, _i=0) =
	(_i >= len(remaining))? polygon : let (
		// pick a point
		i = remaining[_i],
		// find the segments that are in conflict with the point (point not inside)
		conflicts = _find_conflicting_segments(points, polygon, points[i])
		// no conflicts, skip point and move on
	) (len(conflicts) == 0)? _hull2d_iterative(points, polygon, remaining, _i+1) : let(
		// find the first conflicting segment and the first not conflicting
		// conflict will be sorted, if not wrapping around, do it the easy way
		polygon = _remove_conflicts_and_insert_point(polygon, conflicts, i)
	) _hull2d_iterative(points, polygon, remaining, _i+1);


function _hull2d_collinear(points) =
	let(
		a = points[0],
		n = points[1] - a,
		points1d = [ for(p = points) (p-a)*n ],
		min_i = min_index(points1d),
		max_i = max_index(points1d)
	) [min_i, max_i];


function _find_first_noncollinear(line, points, i) = 
    (i>=len(points) || !collinear_indexed(points, line[0], line[1], i))? i :
	_find_first_noncollinear(line, points, i+1);


function _find_conflicting_segments(points, polygon, point) = [
	for (i = [0:1:len(polygon)-1]) let(
		j = (i+1) % len(polygon),
		p1 = points[polygon[i]],
		p2 = points[polygon[j]],
		area = triangle_area2d(p1, p2, point)
	) if (area < 0) i
];


// remove the conflicting segments from the polygon
function _remove_conflicts_and_insert_point(polygon, conflicts, point) = 
	(conflicts[0] == 0)? let(
		nonconflicting = [ for(i = [0:1:len(polygon)-1]) if (!in_list(i, conflicts)) i ],
		new_indices = concat(nonconflicting, (nonconflicting[len(nonconflicting)-1]+1) % len(polygon)),
		polygon = concat([ for (i = new_indices) polygon[i] ], point)
	) polygon : let(
		before_conflicts = [ for(i = [0:1:min(conflicts)]) polygon[i] ],
		after_conflicts  = (max(conflicts) >= (len(polygon)-1))? [] : [ for(i = [max(conflicts)+1:1:len(polygon)-1]) polygon[i] ],
		polygon = concat(before_conflicts, point, after_conflicts)
	) polygon;



// Function: hull3d_faces()
// Usage:
//   hull3d_faces(points)
// Description:
//   Takes a list of arbitrary 3D points, and finds the minimal convex hull polyhedron to enclose
//   them.  Returns a list of faces, where each face is a list of indexes into the given `points`
//   list.  If all points passed to it are coplanar, then the return is the list of indices of points
//   forming the minimal convex hull polygon.
// Example(3D):
//   pts = [[-20,-20,0], [20,-20,0], [0,20,5], [0,0,20]];
//   faces = hull3d_faces(pts);
//   place_copies(pts) color("red") sphere(1);
//   %polyhedron(points=pts, faces=faces);
function hull3d_faces(points) = 
	(len(points) < 3)? list_range(len(points)) : let (	
		// start with a single non-collinear triangle
		a = 0,
		b = 1,
		c = _find_first_noncollinear([a,b], points, 2)
	) (c == len(points))? _hull2d_collinear(points) : let(
		plane = plane3pt_indexed(points, a, b, c),
		d = _find_first_noncoplanar(plane, points, 3)
	) (d == len(points))? /* all coplanar*/ let (
		pts2d = [ for (p = points) project_plane(p, points[a], points[b], points[c]) ],
		hull2d = hull2d_path(pts2d)
	) hull2d : let(
		remaining = [for (i = [3:1:len(points)-1]) if (i != d) i],
		// Build an initial tetrahedron.
		// Swap b, c if d is in front of triangle t.
		ifop = in_front_of_plane(plane, points[d]),
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
function _hull3d_iterative(points, triangles, planes, remaining, _i=0) =
	_i >= len(remaining) ? triangles : 
	let (
		// pick a point
		i = remaining[_i],
		// find the triangles that are in conflict with the point (point not inside)
		conflicts = _find_conflicts(points[i], planes),
		// for all triangles that are in conflict, collect their halfedges
		halfedges = [ 
			for(c = conflicts, i = [0:2]) let(
				j = (i+1)%3
			) [triangles[c][i], triangles[c][j]]
		],
		// find the outer perimeter of the set of conflicting triangles
		horizon = _remove_internal_edges(halfedges),
		// generate a new triangle for each horizon halfedge together with the picked point i
		new_triangles = [ for (h = horizon) concat(h,i) ],
		// calculate the corresponding plane equations
		new_planes = [ for (t = new_triangles) plane3pt_indexed(points, t[0], t[1], t[2]) ]
	) _hull3d_iterative(
		points,
		//  remove the conflicting triangles and add the new ones
		concat(list_remove(triangles, conflicts), new_triangles),
		concat(list_remove(planes, conflicts), new_planes),
		remaining,
		_i+1
	);


function _remove_internal_edges(halfedges) = [
	for (h = halfedges)
		if (!in_list(reverse(h), halfedges))
			h
];


function _find_conflicts(point, planes) = [
	for (i = [0:1:len(planes)-1])
		if (in_front_of_plane(planes[i], point))
			i
];


function _find_first_noncoplanar(plane, points, i) = 
	(i >= len(points) || !coplanar(plane, points[i]))? i :
	_find_first_noncoplanar(plane, points, i+1);


// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
