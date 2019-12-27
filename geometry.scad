//////////////////////////////////////////////////////////////////////
// LibFile: geometry.scad
//   Geometry helpers.
//   To use, add the following lines to the beginning of your file:
//   ```
//   use <BOSL2/std.scad>
//   ```
//////////////////////////////////////////////////////////////////////


// Section: Lines, Rays, and Segments

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
function _point_above_below_segment(point, edge) =
	edge[0].y <= point.y? (
		(edge[1].y > point.y && point_left_of_segment2d(point, edge) > 0)? 1 : 0
	) : (
		(edge[1].y <= point.y && point_left_of_segment2d(point, edge) < 0)? -1 : 0
	);


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
//   color("blue") place_copies([p1,p2]) circle(d=2, $fn=12);
function line_normal(p1,p2) =
	is_undef(p2)? line_normal(p1[0],p1[1]) :
	normalize([p1.y-p2.y,p2.x-p1.x]);


// 2D Line intersection from two segments.
// This function returns [p,t,u] where p is the intersection point of
// the lines defined by the two segments, t is the proportional distance
// of the intersection point along s1, and u is the proportional distance
// of the intersection point along s2.  The proportional values run over
// the range of 0 to 1 for each segment, so if it is in this range, then
// the intersection lies on the segment.  Otherwise it lies somewhere on
// the extension of the segment.  Result is undef for coincident lines.
function _general_line_intersection(s1,s2,eps=EPSILON) =
	let(
		denominator = det2([s1[0],s2[0]]-[s1[1],s2[1]])
	) approx(denominator,0,eps=eps)? [undef,undef,undef] : let(
		t = det2([s1[0],s2[0]]-s2) / denominator,
		u = det2([s1[0],s1[0]]-[s2[0],s1[1]]) / denominator
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
//   eps = Acceptable variance.  Default: `EPSILON` (1e-9)
function line_intersection(l1,l2,eps=EPSILON) =
	let(isect = _general_line_intersection(l1,l2,eps=eps)) isect[0];


// Function: line_ray_intersection()
// Usage:
//   line_ray_intersection(line, ray);
// Description:
//   Returns the 2D intersection point of an unbounded 2D line, and a half-bounded 2D ray.
//   Returns `undef` if they do not intersect.
// Arguments:
//   line = The unbounded 2D line, defined by two 2D points on the line.
//   ray = The 2D ray, given as a list `[START,POINT]` of the 2D start-point START, and a 2D point POINT on the ray.
//   eps = Acceptable variance.  Default: `EPSILON` (1e-9)
function line_ray_intersection(line,ray,eps=EPSILON) =
	let(
		isect = _general_line_intersection(line,ray,eps=eps)
	) isect[2]<0-eps? undef : isect[0];


// Function: line_segment_intersection()
// Usage:
//   line_segment_intersection(line, segment);
// Description:
//   Returns the 2D intersection point of an unbounded 2D line, and a bounded 2D line segment.
//   Returns `undef` if they do not intersect.
// Arguments:
//   line = The unbounded 2D line, defined by two 2D points on the line.
//   segment = The bounded 2D line segment, given as a list of the two 2D endpoints of the segment.
//   eps = Acceptable variance.  Default: `EPSILON` (1e-9)
function line_segment_intersection(line,segment,eps=EPSILON) =
	let(
		isect = _general_line_intersection(line,segment,eps=eps)
	) isect[2]<0-eps || isect[2]>1+eps ? undef : isect[0];


// Function: ray_intersection()
// Usage:
//   ray_intersection(s1, s2);
// Description:
//   Returns the 2D intersection point of two 2D line rays.
//   Returns `undef` if they do not intersect.
// Arguments:
//   r1 = First 2D ray, given as a list `[START,POINT]` of the 2D start-point START, and a 2D point POINT on the ray.
//   r2 = Second 2D ray, given as a list `[START,POINT]` of the 2D start-point START, and a 2D point POINT on the ray.
//   eps = Acceptable variance.  Default: `EPSILON` (1e-9)
function ray_intersection(r1,r2,eps=EPSILON) =
	let(
		isect = _general_line_intersection(r1,r2,eps=eps)
	) isect[1]<0-eps || isect[2]<0-eps? undef : isect[0];


// Function: ray_segment_intersection()
// Usage:
//   ray_segment_intersection(ray, segment);
// Description:
//   Returns the 2D intersection point of a half-bounded 2D ray, and a bounded 2D line segment.
//   Returns `undef` if they do not intersect.
// Arguments:
//   ray = The 2D ray, given as a list `[START,POINT]` of the 2D start-point START, and a 2D point POINT on the ray.
//   segment = The bounded 2D line segment, given as a list of the two 2D endpoints of the segment.
//   eps = Acceptable variance.  Default: `EPSILON` (1e-9)
function ray_segment_intersection(ray,segment,eps=EPSILON) =
	let(
		isect = _general_line_intersection(ray,segment,eps=eps)
	) isect[1]<0-eps || isect[2]<0-eps || isect[2]>1+eps ? undef : isect[0];


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


// Function: line_closest_point()
// Usage:
//   line_closest_point(line,pt);
// Description:
//   Returns the point on the given `line` that is closest to the given point `pt`.
// Arguments:
//   line = A list of two points that are on the unbounded line.
//   pt = The point to find the closest point on the line to.
function line_closest_point(line,pt) =
	let(
		n = line_normal(line),
		isect = _general_line_intersection(line,[pt,pt+n])
	) isect[0];


// Function: segment_closest_point()
// Usage:
//   segment_closest_point(seg,pt);
// Description:
//   Returns the point on the given line segment `seg` that is closest to the given point `pt`.
// Arguments:
//   seg = A list of two points that are the endpoints of the bounded line segment.
//   pt = The point to find the closest point on the segment to.
function segment_closest_point(seg,pt) =
	let(
		n = line_normal(seg),
		isect = _general_line_intersection(seg,[pt,pt+n])
	)
	norm(n)==0? seg[0] :
	isect[1]<=0? seg[0] :
	isect[1]>=1? seg[1] :
	isect[0];


// Section: 2D Triangles

// Function: tri_calc()
// Usage:
//   tri_calc(ang,ang2,adj,opp,hyp);
// Description:
//   Given a side length and an angle, or two side lengths, calculates the rest of the side lengths
//   and angles of a right triangle.  Returns [ADJACENT, OPPOSITE, HYPOTENUSE, ANGLE, ANGLE2] where
//   ADJACENT is the length of the side adjacent to ANGLE, and OPPOSITE is the length of the side
//   opposite of ANGLE and adjacent to ANGLE2.  ANGLE and ANGLE2 are measured in degrees.
//   This is certainly more verbose and slower than writing your own calculations, but has the nice
//   benefit that you can just specify the info you have, and don't have to figure out which trig
//   formulas you need to use.
// Figure(2D):
//   color("#ccc") {
//       stroke(closed=false, width=0.5, [[45,0], [45,5], [50,5]]);
//       stroke(closed=false, width=0.5, arc(N=6, r=15, cp=[0,0], start=0, angle=30));
//       stroke(closed=false, width=0.5, arc(N=6, r=14, cp=[50,30], start=212, angle=58));
//   }
//   color("black") stroke(closed=true, [[0,0], [50,30], [50,0]]);
//   color("#0c0") {
//       translate([10.5,2.5]) text(size=3,text="ang",halign="center",valign="center");
//       translate([44.5,22]) text(size=3,text="ang2",halign="center",valign="center");
//   }
//   color("blue") {
//       translate([25,-3]) text(size=3,text="Adjacent",halign="center",valign="center");
//       translate([53,15]) rotate(-90) text(size=3,text="Opposite",halign="center",valign="center");
//       translate([25,18]) rotate(30) text(size=3,text="Hypotenuse",halign="center",valign="center");
//   }
// Arguments:
//   ang = The angle in degrees of the primary corner of the triangle.
//   ang2 = The angle in degrees of the other non-right corner of the triangle.
//   adj = The length of the side adjacent to the primary corner.
//   opp = The length of the side opposite to the primary corner.
//   hyp = The length of the hypotenuse.
// Example:
//   tri = tri_calc(opp=15,hyp=30);
//   echo(adjacent=tri[0], opposite=tri[1], hypotenuse=tri[2], angle=tri[3], angle2=tri[4]);
// Examples:
//   adj = tri_calc(ang=30,opp=10)[0];
//   opp = tri_calc(ang=20,hyp=30)[1];
//   hyp = tri_calc(ang2=50,adj=20)[2];
//   ang = tri_calc(adj=20,hyp=30)[3];
//   ang2 = tri_calc(adj=20,hyp=40)[4];
function tri_calc(ang,ang2,adj,opp,hyp) =
	assert(ang==undef || ang2==undef,"You cannot specify both ang and ang2.")
	assert(num_defined([ang,ang2,adj,opp,hyp])==2, "You must specify exactly two arguments.")
	let(
		ang = ang!=undef? assert(ang>0&&ang<90) ang :
			ang2!=undef? (90-ang2) :
			adj==undef? asin(constrain(opp/hyp,-1,1)) :
			opp==undef? acos(constrain(adj/hyp,-1,1)) :
			atan2(opp,adj),
		ang2 = ang2!=undef? assert(ang2>0&&ang2<90) ang2 : (90-ang),
		adj = adj!=undef? assert(adj>0) adj :
			(opp!=undef? (opp/tan(ang)) : (hyp*cos(ang))),
		opp = opp!=undef? assert(opp>0) opp :
			(adj!=undef? (adj*tan(ang)) : (hyp*sin(ang))),
		hyp = hyp!=undef? assert(hyp>0) assert(adj<hyp) assert(opp<hyp) hyp :
			(adj!=undef? (adj/cos(ang)) : (opp/sin(ang)))
	)
	[adj, opp, hyp, ang, ang2];


// Function: hyp_opp_to_adj()
// Usage:
//   adj = hyp_opp_to_adj(hyp,opp);
// Description:
//   Given the lengths of the hypotenuse and opposite side of a right triangle, returns the length
//   of the adjacent side.
// Arguments:
//   hyp = The length of the hypotenuse of the right triangle.
//   opp = The length of the side of the right triangle that is opposite from the primary angle.
// Example:
//   hyp = hyp_opp_to_adj(5,3);  // Returns: 4
function hyp_opp_to_adj(hyp,opp) =
	assert(is_num(hyp)&&hyp>=0)
	assert(is_num(opp)&&opp>=0)
	sqrt(hyp*hyp-opp*opp);


// Function: hyp_ang_to_adj()
// Usage:
//   adj = hyp_ang_to_adj(hyp,ang);
// Description:
//   Given the length of the hypotenuse and the angle of the primary corner of a right triangle,
//   returns the length of the adjacent side.
// Arguments:
//   hyp = The length of the hypotenuse of the right triangle.
//   ang = The angle in degrees of the primary corner of the right triangle.
// Example:
//   adj = hyp_ang_to_adj(8,60);  // Returns: 4
function hyp_ang_to_adj(hyp,ang) =
	assert(is_num(hyp)&&hyp>=0)
	assert(is_num(ang)&&ang>0&&ang<90)
	hyp*cos(ang);


// Function: opp_ang_to_adj()
// Usage:
//   adj = opp_ang_to_adj(opp,ang);
// Description:
//   Given the angle of the primary corner of a right triangle, and the length of the side opposite of it,
//   returns the length of the adjacent side.
// Arguments:
//   opp = The length of the side of the right triangle that is opposite from the primary angle.
//   ang = The angle in degrees of the primary corner of the right triangle.
// Example:
//   adj = opp_ang_to_adj(8,30);  // Returns: 4
function opp_ang_to_adj(opp,ang) =
	assert(is_num(opp)&&opp>=0)
	assert(is_num(ang)&&ang>0&&ang<90)
	opp/tan(ang);


// Function: hyp_adj_to_opp()
// Usage:
//   opp = hyp_adj_to_opp(hyp,adj);
// Description:
//   Given the length of the hypotenuse and the adjacent side, returns the length of the opposite side.
// Arguments:
//   hyp = The length of the hypotenuse of the right triangle.
//   adj = The length of the side of the right triangle that is adjacent to the primary angle.
// Example:
//   opp = hyp_adj_to_opp(5,4);  // Returns: 3
function hyp_adj_to_opp(hyp,adj) =
	assert(is_num(hyp)&&hyp>=0)
	assert(is_num(adj)&&adj>=0)
	sqrt(hyp*hyp-adj*adj);


// Function: hyp_ang_to_opp()
// Usage:
//   opp = hyp_ang_to_opp(hyp,adj);
// Description:
//   Given the length of the hypotenuse of a right triangle, and the angle of the corner, returns the length of the opposite side.
// Arguments:
//   hyp = The length of the hypotenuse of the right triangle.
//   ang = The angle in degrees of the primary corner of the right triangle.
// Example:
//   opp = hyp_ang_to_opp(8,30);  // Returns: 4
function hyp_ang_to_opp(hyp,ang) =
	assert(is_num(hyp)&&hyp>=0)
	assert(is_num(ang)&&ang>0&&ang<90)
	hyp*sin(ang);


// Function: adj_ang_to_opp()
// Usage:
//   opp = adj_ang_to_opp(adj,ang);
// Description:
//   Given the length of the adjacent side of a right triangle, and the angle of the corner, returns the length of the opposite side.
// Arguments:
//   adj = The length of the side of the right triangle that is adjacent to the primary angle.
//   ang = The angle in degrees of the primary corner of the right triangle.
// Example:
//   opp = adj_ang_to_opp(8,45);  // Returns: 8
function adj_ang_to_opp(adj,ang) =
	assert(is_num(adj)&&adj>=0)
	assert(is_num(ang)&&ang>0&&ang<90)
	adj*tan(ang);


// Function: adj_opp_to_hyp()
// Usage:
//   hyp = adj_opp_to_hyp(adj,opp);
// Description:
//   Given the length of the adjacent and opposite sides of a right triangle, returns the length of thee hypotenuse.
// Arguments:
//   adj = The length of the side of the right triangle that is adjacent to the primary angle.
//   opp = The length of the side of the right triangle that is opposite from the primary angle.
// Example:
//   hyp = adj_opp_to_hyp(3,4);  // Returns: 5
function adj_opp_to_hyp(adj,opp) =
	assert(is_num(adj)&&adj>=0)
	assert(is_num(opp)&&opp>=0)
	norm([opp,adj]);


// Function: adj_ang_to_hyp()
// Usage:
//   hyp = adj_ang_to_hyp(adj,ang);
// Description:
//   For a right triangle, given the length of the adjacent side, and the corner angle, returns the length of the hypotenuse.
// Arguments:
//   adj = The length of the side of the right triangle that is adjacent to the primary angle.
//   ang = The angle in degrees of the primary corner of the right triangle.
// Example:
//   hyp = adj_ang_to_hyp(4,60);  // Returns: 8
function adj_ang_to_hyp(adj,ang) =
	assert(is_num(adj)&&adj>=0)
	assert(is_num(ang)&&ang>=0&&ang<90)
	adj/cos(ang);


// Function: opp_ang_to_hyp()
// Usage:
//   hyp = opp_ang_to_hyp(opp,ang);
// Description:
//   For a right triangle, given the length of the opposite side, and the corner angle, returns the length of the hypotenuse.
// Arguments:
//   opp = The length of the side of the right triangle that is opposite from the primary angle.
//   ang = The angle in degrees of the primary corner of the right triangle.
// Example:
//   hyp = opp_ang_to_hyp(4,30);  // Returns: 8
function opp_ang_to_hyp(opp,ang) =
	assert(is_num(opp)&&opp>=0)
	assert(is_num(ang)&&ang>0&&ang<=90)
	opp/sin(ang);


// Function: hyp_adj_to_ang()
// Usage:
//   ang = hyp_adj_to_ang(hyp,adj);
// Description:
//   For a right triangle, given the lengths of the hypotenuse and the adjacent sides, returns the angle of the corner.
// Arguments:
//   hyp = The length of the hypotenuse of the right triangle.
//   adj = The length of the side of the right triangle that is adjacent to the primary angle.
// Example:
//   ang = hyp_adj_to_ang(8,4);  // Returns: 60 degrees
function hyp_adj_to_ang(hyp,adj) =
	assert(is_num(hyp)&&hyp>0)
	assert(is_num(adj)&&adj>=0)
	acos(adj/hyp);


// Function: hyp_opp_to_ang()
// Usage:
//   ang = hyp_opp_to_ang(hyp,opp);
// Description:
//   For a right triangle, given the lengths of the hypotenuse and the opposite sides, returns the angle of the corner.
// Arguments:
//   hyp = The length of the hypotenuse of the right triangle.
//   opp = The length of the side of the right triangle that is opposite from the primary angle.
// Example:
//   ang = hyp_opp_to_ang(8,4);  // Returns: 30 degrees
function hyp_opp_to_ang(hyp,opp) =
	assert(is_num(hyp)&&hyp>0)
	assert(is_num(opp)&&opp>=0)
	asin(opp/hyp);


// Function: adj_opp_to_ang()
// Usage:
//   ang = adj_opp_to_ang(adj,opp);
// Description:
//   For a right triangle, given the lengths of the adjacent and opposite sides, returns the angle of the corner.
// Arguments:
//   adj = The length of the side of the right triangle that is adjacent to the primary angle.
//   opp = The length of the side of the right triangle that is opposite from the primary angle.
// Example:
//   ang = adj_opp_to_ang(sqrt(3)/2,0.5);  // Returns: 30 degrees
function adj_opp_to_ang(adj,opp) =
	assert(is_num(adj)&&adj>=0)
	assert(is_num(opp)&&opp>=0)
	atan2(opp,adj);


// Function: triangle_area()
// Usage:
//   triangle_area(a,b,c);
// Description:
//   Returns the area of a triangle formed between three 2D or 3D vertices.
//   Result will be negative if the points are 2D and in in clockwise order.
// Examples:
//   triangle_area([0,0], [5,10], [10,0]);  // Returns -50
//   triangle_area([10,0], [5,10], [0,0]);  // Returns 50
function triangle_area(a,b,c) =
	len(a)==3? 0.5*norm(cross(c-a,c-b)) : (
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
//   Given a list of points, and the indices of three of those points,
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


// Function: plane_from_pointslist()
// Usage:
//   plane_from_pointslist(points);
// Description:
//   Given a list of 3 or more coplanar points, returns the cartesian equation of a plane.
//   Returns [A,B,C,D] where Ax+By+Cz+D=0 is the equation of the plane.
function plane_from_pointslist(points) =
	let(
		points = deduplicate(points),
		indices = sort(find_noncollinear_points(points)),
		p1 = points[indices[0]],
		p2 = points[indices[1]],
		p3 = points[indices[2]],
		plane = plane3pt(p1,p2,p3)
	) plane;


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
	[plane.x, plane.y, plane.z] * point3d(point) - plane[3];


// Function: closest_point_on_plane()
// Usage:
//   pt = closest_point_on_plane(plane, point);
// Description:
//   Takes a point, and a plane [A,B,C,D] where the equation of that plane is `Ax+By+Cz+D=0`.
//   Returns the coordinates of the closest point on that plane to the given `point`.
// Arguments:
//   plane = The [A,B,C,D] values for the equation of the plane.
//   point = The 3D point to find the closest point to.
function closest_point_on_plane(plane, point) =
	let(
		n = normalize(plane_normal(plane)),
		d = distance_from_plane(plane, point)
	) point - n*d;


function _general_plane_line_intersection(plane, line, eps=EPSILON) =
	let(
		p0 = line[0],
		p1 = line[1],
		n = plane_normal(plane),
		u = p1 - p0,
		d = n * u
	) abs(d)<eps? (
		undef  // Line parallel to plane
	) : let(
		v0 = closest_point_on_plane(plane, [0,0,0]),
		w = p0 - v0,
		s1 = (-n * w) / d,
		pt = s1 * u + p0
	) [pt, s1];


// Function: plane_line_intersection()
// Usage:
//   pt = plane_line_intersection(plane, line, [eps]);
// Description:
//   Takes a line, and a plane [A,B,C,D] where the equation of that plane is `Ax+By+Cz+D=0`.
//   Returns the coordinates of the where the given `line` intersects the given `plane`.
//   Returns `undef` if the line is parallel to the plane.
// Arguments:
//   plane = The [A,B,C,D] values for the equation of the plane.
//   line = A list of two 3D points that are on the line.
//   bounded = If false, the line is considered unbounded.  If true, it is treated as a bounded line segment.  If given as `[true, false]` or `[false, true]`, the boundedness of the points are specified individually, allowing the line to be treated as a half-bounded ray.  Default: false (unbounded)
//   eps = The epsilon error value to determine whether the line is too close to parallel to the plane.  Default: `EPSILON` (1e-9)
function plane_line_intersection(plane, line, bounded=false, eps=EPSILON) =
	assert(is_vector(plane)&&len(plane)==4)
	assert(is_path(line)&&len(line)==2)
	let(
		bounded = is_list(bounded)? bounded : [bounded, bounded],
		res = _general_plane_line_intersection(plane, line, eps=eps)
	)
	bounded[0]&&res[1]<0? undef :
	bounded[1]&&res[1]>1? undef :
	res[0];


// Function: polygon_line_intersection()
// Usage:
//   pt = polygon_line_intersection(poly, line, [bounded], [eps]);
// Description:
//   Takes a possibly bounded line, and a 3D planar polygon, and finds their intersection point.
//   Returns the 3D coordinates of the intersection point, or `undef` if they do not intersect.
// Arguments:
//   poly = The 3D planar polygon to find the intersection with.
//   line = A list of two 3D points that are on the line.
//   bounded = If false, the line is considered unbounded.  If true, it is treated as a bounded line segment.  If given as `[true, false]` or `[false, true]`, the boundedness of the points are specified individually, allowing the line to be treated as a half-bounded ray.  Default: false (unbounded)
//   eps = The epsilon error value to determine whether the line is too close to parallel to the plane.  Default: `EPSILON` (1e-9)
function polygon_line_intersection(poly, line, bounded=false, eps=EPSILON) =
	assert(is_path(poly))
	assert(is_path(line)&&len(line)==2)
	let(
		bounded = is_list(bounded)? bounded : [bounded, bounded],
		poly = deduplicate(poly),
		indices = sort(find_noncollinear_points(poly)),
		p1 = poly[indices[0]],
		p2 = poly[indices[1]],
		p3 = poly[indices[2]],
		plane = plane3pt(p1,p2,p3),
		res = _general_plane_line_intersection(plane, line, eps=eps)
	)
	bounded[0]&&res[1]<0? undef :
	bounded[1]&&res[1]>1? undef :
	let(
		proj = clockwise_polygon(project_plane(poly, p1, p2, p3)),
		pt = project_plane(res[0], p1, p2, p3)
	) point_in_polygon(pt, proj) < 0? undef :
	res[0];


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



// Section: Circle Calculations

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
// Example(2D):
//   pts = [[60,40], [10,10], [65,5]];
//   rad = 10;
//   stroke([pts[1],pts[0]], endcap2="arrow2");
//   stroke([pts[1],pts[2]], endcap2="arrow2");
//   circ = find_circle_2tangents(pt1=pts[0], pt2=pts[1], pt3=pts[2], r=rad);
//   translate(circ[0]) {
//       color("green") {
//           stroke(circle(r=rad),closed=true);
//           stroke([[0,0],rad*[cos(315),sin(315)]]);
//       }
//   }
//   place_copies(pts) color("blue") circle(d=2, $fn=12);
//   translate(circ[0]) color("red") circle(d=2, $fn=12);
//   labels = [[pts[0], "pt1"], [pts[1],"pt2"], [pts[2],"pt3"], [circ[0], "CP"], [circ[0]+[cos(315),sin(315)]*rad*0.7, "r"]];
//   for(l=labels) translate(l[0]+[0,2]) color("black") text(text=l[1], size=2.5, halign="center");
function find_circle_2tangents(pt1, pt2, pt3, r=undef, d=undef) =
	let(r = get_radius(r=r, d=d, dflt=undef))
	assert(r!=undef, "Must specify either r or d.")
	(is_undef(pt2) && is_undef(pt3) && is_list(pt1))? find_circle_2tangents(pt1[0], pt1[1], pt1[2], r=r) :
	let(
		v1 = normalize(pt1 - pt2),
		v2 = normalize(pt3 - pt2)
	) approx(norm(v1+v2))? undef :
	let(
		a = vector_angle(v1,v2),
		n = vector_axis(v1,v2),
		v = normalize(mean([v1,v2])),
		s = r/sin(a/2),
		cp = pt2 + s*v/norm(v)
	) [cp, n];


// Function: find_circle_3points()
// Usage:
//   find_circle_3points(pt1, pt2, pt3);
// Description:
//   Returns the [CENTERPOINT, RADIUS, NORMAL] of the circle that passes through three non-collinear
//   points.  The centerpoint will be a 2D or 3D vector, depending on the points input.  If all three
//   points are 2D, then the resulting centerpoint will be 2D, and the normal will be UP ([0,0,1]).
//   If any of the points are 3D, then the resulting centerpoint will be 3D.  If the three points are
//   collinear, then `[undef,undef,undef]` will be returned.  The normal will be a normalized 3D
//   vector with a non-negative Z axis.
// Arguments:
//   pt1 = The first point.
//   pt2 = The second point.
//   pt3 = The third point.
// Example(2D):
//   pts = [[60,40], [10,10], [65,5]];
//   circ = find_circle_3points(pts[0], pts[1], pts[2]);
//   translate(circ[0]) color("green") stroke(circle(r=circ[1]),closed=true,$fn=72);
//   translate(circ[0]) color("red") circle(d=3, $fn=12);
//   place_copies(pts) color("blue") circle(d=3, $fn=12);
function find_circle_3points(pt1, pt2, pt3) =
	(is_undef(pt2) && is_undef(pt3) && is_list(pt1))? find_circle_3points(pt1[0], pt1[1], pt1[2]) :
	collinear(pt1,pt2,pt3)? [undef,undef,undef] :
	let(
		v1 = pt1-pt2,
		v2 = pt3-pt2,
		n = vector_axis(v1,v2),
		n2 = n.z<0? -n : n
	) len(pt1)+len(pt2)+len(pt3)>6? (
		let(
			a = project_plane(pt1, pt1, pt2, pt3),
			b = project_plane(pt2, pt1, pt2, pt3),
			c = project_plane(pt3, pt1, pt2, pt3),
			res = find_circle_3points(a, b, c)
		) res[0]==undef? [undef,undef,undef] : let(
			cp = lift_plane(res[0], pt1, pt2, pt3),
			r = norm(pt2-cp)
		) [cp, r, n2]
	) : let(
		mp1 = pt2 + v1/2,
		mp2 = pt2 + v2/2,
		mpv1 = rot(90, v=n, p=v1),
		mpv2 = rot(90, v=n, p=v2),
		l1 = [mp1, mp1+mpv1],
		l2 = [mp2, mp2+mpv2],
		isect = line_intersection(l1,l2)
	) is_undef(isect)? [undef,undef,undef] : let(
		r = norm(pt2-isect)
	) [isect, r, n2];



// Function: find_circle_tangents()
// Usage:
//   tangents = find_circle_tangents(r|d, cp, pt);
// Description:
//   Given a circle and a point outside that circle, finds the tangent point(s) on the circle for a
//   line passing through the point.  Returns list of zero or more sublists of [ANG, TANGPT]
// Arguments:
//   r = Radius of the circle.
//   d = Diameter of the circle.
//   cp = The coordinates of the circle centerpoint.
//   pt = The coordinates of the external point.
// Example(2D):
//   cp = [-10,-10];  r = 30;  pt = [30,10];
//   tanpts = subindex(find_circle_tangents(r=r, cp=cp, pt=pt),1);
//   color("yellow") translate(cp) circle(r=r);
//   color("cyan") for(tp=tanpts) {stroke([tp,pt]); stroke([tp,cp]);}
//   color("red") place_copies(tanpts) circle(d=3,$fn=12);
//   color("blue") place_copies([cp,pt]) circle(d=3,$fn=12);
function find_circle_tangents(r, d, cp, pt) =
	assert(is_num(r) || is_num(d))
	assert(is_vector(cp))
	assert(is_vector(pt))
	let(
		r = get_radius(r=r, d=d, dflt=1),
		delta = pt - cp,
		dist = norm(delta),
		baseang = atan2(delta.y,delta.x)
	) dist < r? [] :
	approx(dist,r)? [[baseang, pt]] :
	let(
		relang = acos(r/dist),
		angs = [baseang + relang, baseang - relang]
	) [for (ang=angs) [ang, cp + r*[cos(ang),sin(ang)]]];




// Section: Paths and Polygons


// Function: is_path()
// Usage:
//   is_path(x);
// Description:
//   Returns true if the given item looks like a path.  A path is defined as a list of two or more points.
function is_path(x) = is_list(x) && is_vector(x.x) && len(x)>1;


// Function: is_closed_path()
// Usage:
//   is_closed_path(path, [eps]);
// Description:
//   Returns true if the first and last points in the given path are coincident.
function is_closed_path(path, eps=EPSILON) = approx(path[0], path[len(path)-1], eps=eps);


// Function: close_path()
// Usage:
//   close_path(path);
// Description:
//   If a path's last point does not coincide with its first point, closes the path so it does.
function close_path(path, eps=EPSILON) = is_closed_path(path,eps=eps)? path : concat(path,[path[0]]);


// Function: cleanup_path()
// Usage:
//   cleanup_path(path);
// Description:
//   If a path's last point coincides with its first point, deletes the last point in the path.
function cleanup_path(path, eps=EPSILON) = is_closed_path(path,eps=eps)? select(path,0,-2) : path;


// Function: path_subselect()
// Usage:
//   path_subselect(path,s1,u1,s2,u2,[closed]):
// Description:
//   Returns a portion of a path, from between the `u1` part of segment `s1`, to the `u2` part of
//   segment `s2`.  Both `u1` and `u2` are values between 0.0 and 1.0, inclusive, where 0 is the start
//   of the segment, and 1 is the end.  Both `s1` and `s2` are integers, where 0 is the first segment.
// Arguments:
//   path = The path to get a section of.
//   s1 = The number of the starting segment.
//   u1 = The proportion along the starting segment, between 0.0 and 1.0, inclusive.
//   s2 = The number of the ending segment.
//   u2 = The proportion along the ending segment, between 0.0 and 1.0, inclusive.
//   closed = If true, treat path as a closed polygon.
function path_subselect(path, s1, u1, s2, u2, closed=false) =
	let(
		lp = len(path),
		l = lp-(closed?0:1),
		u1 = s1<0? 0 : s1>l? 1 : u1,
		u2 = s2<0? 0 : s2>l? 1 : u2,
		s1 = constrain(s1,0,l),
		s2 = constrain(s2,0,l),
		pathout = concat(
			(s1<l && u1<1)? [lerp(path[s1],path[(s1+1)%lp],u1)] : [],
			[for (i=[s1+1:1:s2]) path[i]],
			(s2<l && u2>0)? [lerp(path[s2],path[(s2+1)%lp],u2)] : []
		)
	) pathout;


// Function: polygon_area()
// Usage:
//   area = polygon_area(vertices);
// Description:
//   Given a polygon, returns the area of that polygon.  If the polygon is self-crossing, the results are undefined.
function polygon_area(vertices) =
	0.5*sum([for(i=[0:len(vertices)-1]) det2(select(vertices,i,i+1))]);


// Function: polygon_shift()
// Usage:
//   polygon_shift(poly, i);
// Description:
//   Given a polygon `poly`, rotates the point ordering so that the first point in the polygon path is the one at index `i`.
// Arguments:
//   poly = The list of points in the polygon path.
//   i = The index of the point to shift to the front of the path.
// Example:
//   polygon_shift([[3,4], [8,2], [0,2], [-4,0]], 2);   // Returns [[0,2], [-4,0], [3,4], [8,2]]
function polygon_shift(poly, i) =
	list_rotate(cleanup_path(poly), i);


// Function: polygon_shift_to_closest_point()
// Usage:
//   polygon_shift_to_closest_point(path, pt);
// Description:
//   Given a polygon `path`, rotates the point ordering so that the first point in the path is the one closest to the given point `pt`.
function polygon_shift_to_closest_point(path, pt) =
	let(
		path = cleanup_path(path),
		dists = [for (p=path) norm(p-pt)],
		closest = min_index(dists)
	) select(path,closest,closest+len(path)-1);


// Function: reindex_polygon()
// Usage:
//   newpoly = reindex_polygon(reference, poly);
// Description:
//   Rotates and possibly reverses the point order of a polygon path to optimize its pairwise point
//   association with a reference polygon.  The two polygons must have the same number of vertices.
//   The optimization is done by computing the distance, norm(reference[i]-poly[i]), between
//   corresponding pairs of vertices of the two polygons and choosing the polygon point order that
//   makes the total sum over all pairs as small as possible.  Returns the reindexed polygon.  Note
//   that the geometry of the polygon is not changed by this operation, just the labeling of its
//   vertices.  If the input polygon is oriented opposite the reference then its point order is
//   flipped.
// Arguments:
//   reference = reference polygon path
//   poly = input polygon to reindex
// Example(2D):  The red dots show the 0th entry in the two input path lists.  Note that the red dots are not near each other.  The blue dot shows the 0th entry in the output polygon
//   pent = subdivide_path([for(i=[0:4])[sin(72*i),cos(72*i)]],30);
//   circ = circle($fn=30,r=2.2);
//   reindexed = reindex_polygon(circ,pent);
//   place_copies(concat(circ,pent)) circle(r=.1,$fn=32);
//   color("red") place_copies([pent[0],circ[0]]) circle(r=.1,$fn=32);
//   color("blue") translate(reindexed[0])circle(r=.1,$fn=32);
// Example(2D): The indexing that minimizes the total distance will not necessarily associate the nearest point of `poly` with the reference, as in this example where again the blue dot indicates the 0th entry in the reindexed result.
//   pent = move([3.5,-1],p=subdivide_path([for(i=[0:4])[sin(72*i),cos(72*i)]],30));
//   circ = circle($fn=30,r=2.2);
//   reindexed = reindex_polygon(circ,pent);
//   place_copies(concat(circ,pent)) circle(r=.1,$fn=32);
//   color("red") place_copies([pent[0],circ[0]]) circle(r=.1,$fn=32);
//   color("blue") translate(reindexed[0])circle(r=.1,$fn=32);
function reindex_polygon(reference, poly, return_error=false) = 
   assert(is_path(reference) && is_path(poly))
   assert(len(reference)==len(poly), "Polygons must be the same length in reindex_polygon")
   let(
     N = len(reference),
     fixpoly = polygon_is_clockwise(reference) ? clockwise_polygon(poly) : ccw_polygon(poly),
     dist = [for (p1=reference) [for (p2=fixpoly) norm(p1-p2)]],  // Matrix of all pairwise distances
     // Compute the sum of all distance pairs for a each shift
     sums = [for(shift=[0:N-1])
               sum([for(i=[0:N-1]) dist[i][(i+shift)%N]])],
     optimal_poly = polygon_shift(fixpoly,min_index(sums))
   )
   return_error ? [optimal_poly, min(sums)] : optimal_poly;


// Function: align_polygon()
// Usage:
//   newpoly = align_polygon(reference, poly, angles, [cp]);
// Description:
//   Tries the list or range of angles to find a rotation of the specified polygon that best aligns
//   with the reference polygon.  For each angle, the polygon is reindexed, which is a costly operation
//   so if run time is a problem, use a smaller sampling of angles.  Returns the rotated and reindexed
//   polygon.
// Arguments:
//   reference = reference polygon 
//   poly = polygon to rotate into alignment with the reference
//   angles = list or range of angles to test
//   cp = centerpoint for rotations
// Example(2D): The original hexagon in yellow is not well aligned with the pentagon.  Turning it so the faces line up gives an optimal alignment, shown in red.  
//   $fn=32;
//   pentagon = subdivide_path(pentagon(side=2),60);
//   hexagon = subdivide_path(hexagon(side=2.7),60);
//   color("red") place_copies(scale(1.4,p=align_polygon(pentagon,hexagon,[0:10:359]))) circle(r=.1);
//   place_copies(concat(pentagon,hexagon))circle(r=.1);
function align_polygon(reference, poly, angles, cp) =
   assert(is_path(reference) && is_path(poly))
   assert(len(reference)==len(poly), "Polygons must be the same length to be aligned in align_polygon")
   assert(is_num(angles[0]), "The `angle` parameter to align_polygon must be a range or vector")
   let(     // alignments is a vector of entries of the form: [polygon, error]
     alignments = [for(angle=angles) reindex_polygon(reference, zrot(angle,p=poly,cp=cp),return_error=true)],
     best = min_index(subindex(alignments,1))
   )
   alignments[best][0];


// Function: first_noncollinear()
// Usage:
//   first_noncollinear(i1, i2, points);
// Description:
//   Returns index of the first point in `points` that is not collinear with the points indexed by `i1` and `i2`.
// Arguments:
//   i1 = The first point.
//   i2 = The second point.
//   points = The list of points to find a non-collinear point from.
function first_noncollinear(i1, i2, points) =
	[for (j = idx(points)) if (j!=i1 && j!=i2 && !collinear_indexed(points,i1,i2,j)) j][0];


// Function: find_noncollinear_points()
// Usage:
//   find_noncollinear_points(points);
// Description:
//   Finds the indices of three good non-collinear points from the points list `points`.
function find_noncollinear_points(points) =
	let(
		a = 0,
		b = furthest_point(points[a], points),
		c = max_index([
			for (p=points)
				sin(vector_angle(points[a]-p,points[b]-p)) *
					norm(p-points[a]) * norm(p-points[b])
		])
	) [a, b, c];


// Function: centroid()
// Usage:
//   cp = centroid(poly);
// Description:
//   Given a simple 2D polygon, returns the 2D coordinates of the polygon's centroid.
//   Given a simple 3D planar polygon, returns the 3D coordinates of the polygon's centroid.
//   If the polygon is self-intersecting, the results are undefined.
function centroid(poly) =
	len(poly[0])==2? (
		sum([
			for(i=[0:len(poly)-1])
			let(segment=select(poly,i,i+1))
			det2(segment)*sum(segment)
		]) / 6 / polygon_area(poly)
	) : (
		let(
			n = plane_normal(plane_from_pointslist(poly)),
			p1 = vector_angle(n,UP)>15? vector_axis(n,UP) : vector_axis(n,RIGHT),
			p2 = vector_axis(n,p1),
			cp = mean(poly),
			proj = project_plane(poly,cp,cp+p1,cp+p2),
			cxy = centroid(proj)
		) lift_plane(cxy,cp,cp+p1,cp+p2)
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
//   Takes a list of points, and a path as a list of indices into `points`,
//   and removes all path points that are unecessarily collinear.
// Usage:
//   simplify_path_indexed(path, eps)
// Arguments:
//   points = A list of points.
//   path = A list of indices into `points` that forms a path.
//   eps = Largest angle variance allowed.  Default: EPSILON (1-e9) degrees.
function simplify_path_indexed(points, path, eps=EPSILON) =
	len(path)<=2? path : let(
		indices = concat([0], [for (i=[1:1:len(path)-2]) if (!collinear_indexed(points, path[i-1], path[i], path[i+1], eps=eps)) i], [len(path)-1])
	) [for (i = indices) path[i]];



// Function: point_in_polygon()
// Usage:
//   point_in_polygon(point, path, [eps])
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
	// Original algorithm from http://geomalgorithms.com/a03-_inclusion.html
	// Does the point lie on any edges?  If so return 0.
	sum([for(i=[0:1:len(path)-1]) let(seg=select(path,i,i+1)) if(!approx(seg[0],seg[1],eps=eps)) point_on_segment2d(point, seg, eps=eps)?1:0]) > 0? 0 :
	// Otherwise compute winding number and return 1 for interior, -1 for exterior
	sum([for(i=[0:1:len(path)-1]) let(seg=select(path,i,i+1)) if(!approx(seg[0],seg[1],eps=eps)) _point_above_below_segment(point, seg)]) != 0? 1 : -1;


// Function: pointlist_bounds()
// Usage:
//   pointlist_bounds(pts);
// Description:
//   Finds the bounds containing all the 2D or 3D points in `pts`.
//   Returns `[[MINX, MINY, MINZ], [MAXX, MAXY, MAXZ]]`
// Arguments:
//   pts = List of points.
function pointlist_bounds(pts) = [
	[for (a=[0:2]) min([ for (x=pts) point3d(x)[a] ]) ],
	[for (a=[0:2]) max([ for (x=pts) point3d(x)[a] ]) ]
];


// Function: closest_point()
// Usage:
//   closest_point(pt, points);
// Description:
//   Given a list of `points`, finds the index of the closest point to `pt`.
// Arguments:
//   pt = The point to find the closest point to.
//   points = The list of points to search.
function closest_point(pt, points) =
	min_index([for (p=points) norm(p-pt)]);


// Function: furthest_point()
// Usage:
//   furthest_point(pt, points);
// Description:
//   Given a list of `points`, finds the index of the furthest point from `pt`.
// Arguments:
//   pt = The point to find the farthest point from.
//   points = The list of points to search.
// Example:
function furthest_point(pt, points) =
	max_index([for (p=points) norm(p-pt)]);


// Function: polygon_is_clockwise()
// Usage:
//   polygon_is_clockwise(path);
// Description:
//   Return true if the given 2D simple polygon is in clockwise order, false otherwise.
//   Results for complex (self-intersecting) polygon are indeterminate.
// Arguments:
//   path = The list of 2D path points for the perimeter of the polygon.
function polygon_is_clockwise(path) =
	let(
		minx = min(subindex(path,0)),
		lowind = search(minx, path, 0, 0),
		lowpts = select(path, lowind),
		miny = min(subindex(lowpts, 1)),
		extreme_sub = search(miny, lowpts, 1, 1)[0],
		extreme = select(lowind,extreme_sub)
	) det2([select(path,extreme+1)-path[extreme], select(path, extreme-1)-path[extreme]])<0;


// Function: clockwise_polygon()
// Usage:
//   clockwise_polygon(path);
// Description:
//   Given a polygon path, returns the clockwise winding version of that path.
function clockwise_polygon(path) =
	polygon_is_clockwise(path)? path : reverse_polygon(path);


// Function: ccw_polygon()
// Usage:
//   ccw_polygon(path);
// Description:
//   Given a polygon path, returns the counter-clockwise winding version of that path.
function ccw_polygon(path) =
	polygon_is_clockwise(path)? reverse_polygon(path) : path;


// Function: reverse_polygon()
// Usage:
//   reverse_polygon(poly)
// Description:
//   Reverses a polygon's winding direction, while still using the same start point.
function reverse_polygon(poly) =
	let(lp=len(poly)) [for (i=idx(poly)) poly[(lp-i)%lp]];


// Function: path_self_intersections()
// Usage:
//   isects = path_self_intersections(path, [eps]);
// Description:
//   Locates all self intersections of the given path.  Returns a list of intersections, where
//   each intersection is a list like [POINT, SEGNUM1, PROPORTION1, SEGNUM2, PROPORTION2] where
//   POINT is the coordinates of the intersection point, SEGNUMs are the integer indices of the
//   intersecting segments along the path, and the PROPORTIONS are the 0.0 to 1.0 proportions
//   of how far along those segments they intersect at.  A proportion of 0.0 indicates the start
//   of the segment, and a proportion of 1.0 indicates the end of the segment.
// Arguments:
//   path = The path to find self intersections of.
//   closed = If true, treat path like a closed polygon.  Default: true
//   eps = The epsilon error value to determine whether two points coincide.  Default: `EPSILON` (1e-9)
// Example(2D):
//   path = [
//       [-100,100], [0,-50], [100,100], [100,-100], [0,50], [-100,-100]
//   ];
//   isects = path_self_intersections(path, closed=true);
//   // isects == [[[-33.3333, 0], 0, 0.666667, 4, 0.333333], [[33.3333, 0], 1, 0.333333, 3, 0.666667]]
//   stroke(path, closed=true, width=1);
//   for (isect=isects) translate(isect[0]) color("blue") sphere(d=10);
function path_self_intersections(path, closed=true, eps=EPSILON) =
	let(
		path = cleanup_path(path, eps=eps),
		plen = len(path)
	) [
		for (i = [0:1:plen-(closed?2:3)], j=[i+1:1:plen-(closed?1:2)]) let(
			a1 = path[i],
			a2 = path[(i+1)%plen],
			b1 = path[j],
			b2 = path[(j+1)%plen],
			isect =
				(max(a1.x, a2.x) < min(b1.x, b2.x))? undef :
				(min(a1.x, a2.x) > max(b1.x, b2.x))? undef :
				(max(a1.y, a2.y) < min(b1.y, b2.y))? undef :
				(min(a1.y, a2.y) > max(b1.y, b2.y))? undef :
				let(
					c = a1-a2,
					d = b1-b2,
					denom = (c.x*d.y)-(c.y*d.x)
				) abs(denom)<eps? undef : let(
					e = a1-b1,
					t = ((e.x*d.y)-(e.y*d.x)) / denom,
					u = ((e.x*c.y)-(e.y*c.x)) / denom
				) [a1+t*(a2-a1), t, u]
		) if (
			isect != undef &&
			isect[1]>eps && isect[1]<=1+eps &&
			isect[2]>eps && isect[2]<=1+eps
		) [isect[0], i, isect[1], j, isect[2]]
	];


function _tag_self_crossing_subpaths(path, closed=true, eps=EPSILON) =
	let(
		subpaths = split_path_at_self_crossings(
			path, closed=closed, eps=eps
		)
	) [
		for (subpath = subpaths) let(
			seg = select(subpath,0,1),
			mp = mean(seg),
			n = line_normal(seg) / 2048,
			p1 = mp + n,
			p2 = mp - n,
			p1in = point_in_polygon(p1, path) >= 0,
			p2in = point_in_polygon(p2, path) >= 0,
			tag = (p1in && p2in)? "I" : "O"
		) [tag, subpath]
	];


// Function: decompose_path()
// Usage:
//   splitpaths = decompose_path(path, [closed], [eps]);
// Description:
//   Given a possibly self-crossing path, decompose it into non-crossing paths that are on the perimeter
//   of the areas bounded by that path.
// Arguments:
//   path = The path to split up.
//   closed = If true, treat path like a closed polygon.  Default: true
//   eps = The epsilon error value to determine whether two points coincide.  Default: `EPSILON` (1e-9)
// Example(2D):
//   path = [
//       [-100,100], [0,-50], [100,100], [100,-100], [0,50], [-100,-100]
//   ];
//   splitpaths = decompose_path(path, closed=true);
//   rainbow(splitpaths) stroke($item, closed=true, width=3);
function decompose_path(path, closed=true, eps=EPSILON) =
	let(
		path = cleanup_path(path, eps=eps),
		tagged = _tag_self_crossing_subpaths(path, closed=closed, eps=eps),
		kept = [for (sub = tagged) if(sub[0] == "O") sub[1]],
		outregion = assemble_path_fragments(kept, eps=eps)
	) outregion;


function _extreme_angle_fragment(seg, fragments, rightmost=true, eps=EPSILON) =
	!fragments? [undef, []] :
	let(
		delta = seg[1] - seg[0],
		segang = atan2(delta.y,delta.x),
		frags = [
			for (i = idx(fragments)) let(
				fragment = fragments[i],
				fwdmatch = approx(seg[1], fragment[0], eps=eps),
				bakmatch =  approx(seg[1], select(fragment,-1), eps=eps)
			) [
				fwdmatch,
				bakmatch,
				bakmatch? reverse(fragment) : fragment
			]
		],
		angs = [
			for (frag = frags)
				(frag[0] || frag[1])? let(
					delta2 = frag[2][1] - frag[2][0],
					segang2 = atan2(delta2.y, delta2.x)
				) modang(segang2 - segang) : (
					rightmost? 999 : -999
				)
		],
		fi = rightmost? min_index(angs) : max_index(angs)
	) abs(angs[fi]) > 360? [undef, fragments] : let(
		remainder = [for (i=idx(fragments)) if (i!=fi) fragments[i]],
		frag = frags[fi],
		foundfrag = frag[2]
	) [foundfrag, remainder];


// Function: assemble_a_path_from_fragments()
// Usage:
//   assemble_a_path_from_fragments(subpaths);
// Description:
//   Given a list of incomplete paths, assembles them together into one complete closed path, and
//   remainder fragments.  Returns [PATH, FRAGMENTS] where FRAGMENTS is the list of remaining
//   polyline path fragments.
// Arguments:
//   fragments = List of polylines to be assembled into complete polygons.
//   rightmost = If true, assemble paths using rightmost turns. Leftmost if false.
//   eps = The epsilon error value to determine whether two points coincide.  Default: `EPSILON` (1e-9)
function assemble_a_path_from_fragments(fragments, rightmost=true, eps=EPSILON) =
	len(fragments)==0? _finished :
	let(
		path = fragments[0],
		newfrags = slice(fragments, 1, -1)
	) is_closed_path(path, eps=eps)? (
		// starting fragment is already closed
		[path, newfrags]
	) : let(
		// Find rightmost/leftmost continuation fragment
		seg = select(path,-2,-1),
		frags = slice(fragments,1,-1),
		extrema = _extreme_angle_fragment(seg=seg, fragments=frags, rightmost=rightmost, eps=eps),
		foundfrag = extrema[0],
		remainder = extrema[1],
		newfrags = remainder
	) is_undef(foundfrag)? (
		// No remaining fragments connect!  INCOMPLETE PATH!
		// Treat it as complete.
		[path, newfrags]
	) : is_closed_path(foundfrag, eps=eps)? (
		let(
			newfrags = concat([path], remainder)
		)
		// Found fragment is already closed
		[foundfrag, newfrags]
	) : let(
		fragend = select(foundfrag,-1),
		hits = [for (i = idx(path,end=-2)) if(approx(path[i],fragend,eps=eps)) i]
	) hits? (
		let(
			// Found fragment intersects with initial path
			hitidx = select(hits,-1),
			newpath = slice(path,0,hitidx+1),
			newfrags = concat(len(newpath)>1? [newpath] : [], remainder),
			outpath = concat(slice(path,hitidx,-2), foundfrag)
		)
		[outpath, newfrags]
	) : let(
		// Path still incomplete.  Continue building it.
		newpath = concat(path, slice(foundfrag, 1, -1)),
		newfrags = concat([newpath], remainder)
	)
	assemble_a_path_from_fragments(
		fragments=newfrags,
		rightmost=rightmost,
		eps=eps
	);


// Function: assemble_path_fragments()
// Usage:
//   assemble_path_fragments(subpaths);
// Description:
//   Given a list of incomplete paths, assembles them together into complete closed paths if it can.
// Arguments:
//   fragments = List of polylines to be assembled into complete polygons.
//   rightmost = If true, assemble paths using rightmost turns. Leftmost if false.
//   eps = The epsilon error value to determine whether two points coincide.  Default: `EPSILON` (1e-9)
function assemble_path_fragments(fragments, rightmost=true, eps=EPSILON, _finished=[]) =
	len(fragments)==0? _finished :
	let(
		result = assemble_a_path_from_fragments(
			fragments=fragments,
			rightmost=rightmost,
			eps=eps
		),
		newpath = result[0],
		remainder = result[1],
		finished = concat(_finished, [newpath])
	) assemble_path_fragments(
		fragments=remainder,
		rightmost=rightmost, eps=eps,
		_finished=finished
	);


// Function: split_path_at_self_crossings()
// Usage:
//   polylines = split_path_at_self_crossings(path, [closed], [eps]);
// Description:
//   Splits a path into polyline sections wherever the path crosses itself.
//   Splits may occur mid-segment, so new vertices will be created at the intersection points.
// Arguments:
//   path = The path to split up.
//   closed = If true, treat path as a closed polygon.  Default: true
//   eps = Acceptable variance.  Default: `EPSILON` (1e-9)
// Example(2D):
//   path = [ [-100,100], [0,-50], [100,100], [100,-100], [0,50], [-100,-100] ];
//   polylines = split_path_at_self_crossings(path);
//   rainbow(polylines) stroke($item, closed=false, width=2);
function split_path_at_self_crossings(path, closed=true, eps=EPSILON) =
	let(
		path = cleanup_path(path, eps=eps),
		isects = deduplicate(
			eps=eps,
			concat(
				[[0, 0]],
				sort([
					for (
						a = path_self_intersections(path, closed=closed, eps=eps),
						ss = [ [a[1],a[2]], [a[3],a[4]] ]
					) if (ss[0] != undef) ss
				]),
				[[len(path)-(closed?1:2), 1]]
			)
		)
	) [
		for (p = pair(isects))
			let(
				s1 = p[0][0],
				u1 = p[0][1],
				s2 = p[1][0],
				u2 = p[1][1],
				section = path_subselect(path, s1, u1, s2, u2, closed=closed),
				outpath = deduplicate(eps=eps, section)
			)
			outpath
	];



// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
