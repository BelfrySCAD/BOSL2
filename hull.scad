//////////////////////////////////////////////////////////////////////
// LibFile: hull.scad
//   Functions to create 2D and 3D convex hulls.
//   Derived from Oskar Linde's Hull:
//   - https://github.com/openscad/scad-utils
// Includes:
//   include <BOSL2/std.scad>
//   include <BOSL2/hull.scad>
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
function hull(points) =
    assert(is_path(points),"Invalid input to hull")
    len(points[0]) == 2
      ? hull2d_path(points)
      : hull3d_faces(points);


// Module: hull_points()
// Usage:
//   hull_points(points, [fast]);
// Description:
//   If given a list of 2D points, creates a 2D convex hull polygon that encloses all those points.
//   If given a list of 3D points, creates a 3D polyhedron that encloses all the points.  This should
//   handle about 4000 points in slow mode.  If `fast` is set to true, this should be able to handle
//   far more.  When fast mode is off, 3d hulls that lie in a plane will produce a single face of a polyhedron, which can be viewed in preview but will not render.  
// Arguments:
//   points = The list of points to form a hull around.
//   fast = If true for 3d case, uses a faster cheat that may handle more points, but also may emit warnings that can stop your script if you have "Halt on first warning" enabled.  Ignored for the 2d case.  Default: false
// Example(2D):
//   pts = [[-10,-10], [0,10], [10,10], [12,-10]];
//   hull_points(pts);
// Example:
//   pts = [for (phi = [30:60:150], theta = [0:60:359]) spherical_to_xyz(10, theta, phi)];
//   hull_points(pts);
module hull_points(points, fast=false) {
    assert(is_path(points))
    assert(len(points)>=3, "Point list must contain 3 points")
    if (len(points[0])==2)
       hull() polygon(points=points);
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
}



function _backtracking(i,points,h,t,m,all) =
    m<t || _is_cw(points[i], points[h[m-1]], points[h[m-2]],all) ? m :
    _backtracking(i,points,h,t,m-1,all) ;

// clockwise check (2d)
function _is_cw(a,b,c,all) = 
    all ? cross(a-c,b-c)<=EPSILON*norm(a-c)*norm(b-c) :
    cross(a-c,b-c)<-EPSILON*norm(a-c)*norm(b-c);


// Function: hull2d_path()
// Usage:
//   hull2d_path(points,all)
// Description:
//   Takes a list of arbitrary 2D points, and finds the convex hull polygon to enclose them.
//   Returns a path as a list of indices into `points`. 
//   When all==true, returns extra points that are on edges of the hull.
// Arguments:
//   points - list of 2d points to get the hull of.
//   all - when true, includes all points on the edges of the convex hull. Default: false.
// Example(2D):
//   pts = [[-10,-10], [0,10], [10,10], [12,-10]];
//   path = hull2d_path(pts);
//   move_copies(pts) color("red") sphere(1);
//   polygon(points=pts, paths=[path]);
//
// Code based on this method:
// https://www.hackerearth.com/practice/math/geometry/line-sweep-technique/tutorial/
//
function hull2d_path(points, all=false) =
    assert(is_path(points,2),"Invalid input to hull2d_path")
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
// Usage:
//   hull3d_faces(points)
// Description:
//   Takes a list of arbitrary 3D points, and finds the convex hull polyhedron to enclose
//   them.  Returns a list of triangular faces, where each face is a list of indexes into the given `points`
//   list.  The output will be valid for use with the polyhedron command, but may include vertices that are in the interior of a face of the hull, so it is not
//   necessarily the minimal representation of the hull.  
//   If all points passed to it are coplanar, then the return is the list of indices of points
//   forming the convex hull polygon.
// Example(3D):
//   pts = [[-20,-20,0], [20,-20,0], [0,20,5], [0,0,20]];
//   faces = hull3d_faces(pts);
//   move_copies(pts) color("red") sphere(1);
//   %polyhedron(points=pts, faces=faces);
function hull3d_faces(points) =
    assert(is_path(points,3),"Invalid input to hull3d_faces")
    len(points) < 3 ? count(len(points))
  : let ( // start with a single non-collinear triangle
          tri = noncollinear_triple(points, error=false)
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
    (i >= len(points) || !points_on_plane([points[i]],plane))? i :
    _find_first_noncoplanar(plane, points, i+1);


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
