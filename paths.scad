//////////////////////////////////////////////////////////////////////
// LibFile: paths.scad
//   Polylines, polygons and paths.
//   To use, add the following lines to the beginning of your file:
//   ```
//   include <BOSL2/std.scad>
//   ```
//////////////////////////////////////////////////////////////////////


include <BOSL2/triangulation.scad>


// Section: Functions


// Function: simplify2d_path()
// Description:
//   Takes a 2D polyline and removes unnecessary collinear points.
// Usage:
//   simplify2d_path(path, [eps])
// Arguments:
//   path = A list of 2D path points.
//   eps = Largest angle delta between segments to count as colinear.  Default: 1e-6
function simplify2d_path(path, eps=1e-6) = simplify_path(path, eps=eps);


// Function: simplify3d_path()
// Description:
//   Takes a 3D polyline and removes unnecessary collinear points.
// Usage:
//   simplify3d_path(path, [eps])
// Arguments:
//   path = A list of 3D path points.
//   eps = Largest angle delta between segments to count as colinear.  Default: 1e-6
function simplify3d_path(path, eps=1e-6) = simplify_path(path, eps=eps);


// Function: path_length()
// Usage:
//   path_length(path,[closed])
// Description:
//   Returns the length of the path.
// Arguments:
//   path = The list of points of the path to measure.
//   closed = true if the path is closed.  Default: false
// Example:
//   path = [[0,0], [5,35], [60,-25], [80,0]];
//   echo(path_length(path));
function path_length(path,closed=false) =
	len(path)<2? 0 :
	sum([for (i = [0:1:len(path)-2]) norm(path[i+1]-path[i])])+(closed?norm(path[len(path)-1]-path[0]):0);


// Function: path_closest_point()
// Usage:
//   path_closest_point(path, pt);
// Description:
//   Finds the closest path segment, and point on that segment to the given point.
//   Returns `[SEGNUM, POINT]`
// Arguments:
//   path = The path to find the closest point on.
//   pt = the point to find the closest point to.
// Example(2D):
//   path = circle(d=100,$fn=6);
//   pt = [20,10];
//   closest = path_closest_point(path, pt);
//   stroke(path, closed=true);
//   color("blue") translate(pt) circle(d=3, $fn=12);
//   color("red") translate(closest[1]) circle(d=3, $fn=12);
function path_closest_point(path, pt) =
	let(
		pts = [for (seg=idx(path)) segment_closest_point(select(path,seg,seg+1),pt)],
		dists = [for (p=pts) norm(p-pt)],
		min_seg = min_index(dists)
	) [min_seg, pts[min_seg]];



// Function: path3d_spiral()
// Description:
//   Returns a 3D spiral path.
// Usage:
//   path3d_spiral(turns, h, n, r|d, [cp], [scale]);
// Arguments:
//   h = Height of spiral.
//   turns = Number of turns in spiral.
//   n = Number of spiral sides.
//   r = Radius of spiral.
//   d = Radius of spiral.
//   cp = Centerpoint of spiral. Default: `[0,0]`
//   scale = [X,Y] scaling factors for each axis.  Default: `[1,1]`
// Example(3D):
//   trace_polyline(path3d_spiral(turns=2.5, h=100, n=24, r=50), N=1, showpts=true);
function path3d_spiral(turns=3, h=100, n=12, r=undef, d=undef, cp=[0,0], scale=[1,1]) = let(
		rr=get_radius(r=r, d=d, dflt=100),
		cnt=floor(turns*n),
		dz=h/cnt
	) [
		for (i=[0:1:cnt]) [
			rr * cos(i*360/n) * scale.x + cp.x,
			rr * sin(i*360/n) * scale.y + cp.y,
			i*dz
		]
	];


// Function: points_along_path3d()
// Usage:
//   points_along_path3d(polyline, path);
// Description:
//   Calculates the vertices needed to create a `polyhedron()` of the
//   extrusion of `polyline` along `path`.  The closed 2D path shold be
//   centered on the XY plane. The 2D path is extruded perpendicularly
//   along the 3D path.  Produces a list of 3D vertices.  Vertex count
//   is `len(polyline)*len(path)`.  Gives all the reoriented vertices
//   for `polyline` at the first point in `path`, then for the second,
//   and so on.
// Arguments:
//   polyline = A closed list of 2D path points.
//   path = A list of 3D path points.
function points_along_path3d(
	polyline,  // The 2D polyline to drag along the 3D path.
	path,  // The 3D polyline path to follow.
	q=Q_Ident(),  // Used in recursion
	n=0  // Used in recursion
) = let(
	end = len(path)-1,
	v1 = (n == 0)?  [0, 0, 1] : normalize(path[n]-path[n-1]),
	v2 = (n == end)? normalize(path[n]-path[n-1]) : normalize(path[n+1]-path[n]),
	crs = cross(v1, v2),
	axis = norm(crs) <= 0.001? [0, 0, 1] : crs,
	ang = vector_angle(v1, v2),
	hang = ang * (n==0? 1.0 : 0.5),
	hrot = Quat(axis, hang),
	arot = Quat(axis, ang),
	roth = Q_Mul(hrot, q),
	rotm = Q_Mul(arot, q)
) concat(
	[for (i = [0:1:len(polyline)-1]) Qrot(roth,p=point3d(polyline[i])) + path[n]],
	(n == end)? [] : points_along_path3d(polyline, path, rotm, n+1)
);



// Section: 2D Modules


// Module: modulated_circle()
// Description:
//   Creates a 2D polygon circle, modulated by one or more superimposed sine waves.
// Arguments:
//   r = radius of the base circle.
//   sines = array of [amplitude, frequency] pairs, where the frequency is the number of times the cycle repeats around the circle.
// Example(2D):
//   modulated_circle(r=40, sines=[[3, 11], [1, 31]], $fn=6);
module modulated_circle(r=40, sines=[10])
{
	freqs = len(sines)>0? [for (i=sines) i[1]] : [5];
	points = [
		for (a = [0 : (360/segs(r)/max(freqs)) : 360])
			let(nr=r+sum_of_sines(a,sines)) [nr*cos(a), nr*sin(a)]
	];
	polygon(points);
}


// Section: 3D Modules


// Module: extrude_from_to()
// Description:
//   Extrudes a 2D shape between the points pt1 and pt2.  Takes as children a set of 2D shapes to extrude.
// Arguments:
//   pt1 = starting point of extrusion.
//   pt2 = ending point of extrusion.
//   convexity = max number of times a line could intersect a wall of the 2D shape being extruded.
//   twist = number of degrees to twist the 2D shape over the entire extrusion length.
//   scale = scale multiplier for end of extrusion compared the start.
//   slices = Number of slices along the extrusion to break the extrusion into.  Useful for refining `twist` extrusions.
// Example(FlatSpin):
//   extrude_from_to([0,0,0], [10,20,30], convexity=4, twist=360, scale=3.0, slices=40) {
//       xspread(3) circle(3, $fn=32);
//   }
module extrude_from_to(pt1, pt2, convexity=undef, twist=undef, scale=undef, slices=undef) {
	rtp = xyz_to_spherical(pt2-pt1);
	translate(pt1) {
		rotate([0, rtp[2], rtp[1]]) {
			linear_extrude(height=rtp[0], convexity=convexity, center=false, slices=slices, twist=twist, scale=scale) {
				children();
			}
		}
	}
}



// Module: spiral_sweep()
// Description:
//   Takes a closed 2D polyline path, centered on the XY plane, and
//   extrudes it along a 3D spiral path of a given radius, height and twist.
// Arguments:
//   polyline = Array of points of a polyline path, to be extruded.
//   h = height of the spiral to extrude along.
//   r = radius of the spiral to extrude along.
//   twist = number of degrees of rotation to spiral up along height.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
//   center = If given, overrides `anchor`.  A true value sets `anchor=CENTER`, false sets `anchor=BOTTOM`.
// Example:
//   poly = [[-10,0], [-3,-5], [3,-5], [10,0], [0,-30]];
//   spiral_sweep(poly, h=200, r=50, twist=1080, $fn=36);
module spiral_sweep(polyline, h, r, twist=360, center=undef, anchor=BOTTOM, spin=0, orient=UP) {
	pline_count = len(polyline);
	steps = ceil(segs(r)*(twist/360));

	poly_points = [
		for (
			p = [0:1:steps]
		) let (
			a = twist * (p/steps),
			dx = r*cos(a),
			dy = r*sin(a),
			dz = h * (p/steps),
			pts = affine3d_apply(
				polyline, [
					affine3d_xrot(90),
					affine3d_zrot(a),
					affine3d_translate([dx, dy, dz-h/2])
				]
			)
		) for (pt = pts) pt
	];

	poly_faces = concat(
		[[for (b = [0:1:pline_count-1]) b]],
		[
			for (
				p = [0:1:steps-1],
				b = [0:1:pline_count-1],
				i = [0:1]
			) let (
				b2 = (b == pline_count-1)? 0 : b+1,
				p0 = p * pline_count + b,
				p1 = p * pline_count + b2,
				p2 = (p+1) * pline_count + b2,
				p3 = (p+1) * pline_count + b,
				pt = (i==0)? [p0, p2, p1] : [p0, p3, p2]
			) pt
		],
		[[for (b = [pline_count-1:-1:0]) b+(steps)*pline_count]]
	);

	tri_faces = triangulate_faces(poly_points, poly_faces);
	orient_and_anchor([r,r,h], orient, anchor, spin=spin, center=center, geometry="cylinder", chain=true) {
		polyhedron(points=poly_points, faces=tri_faces, convexity=10);
		children();
	}
}


// Module: path_sweep()
// Description:
//   Takes a closed 2D path `polyline`, centered on the XY plane, and extrudes it perpendicularly along a 3D path `path`, forming a solid.
// Arguments:
//   polyline = Array of points of a polyline path, to be extruded.
//   path = Array of points of a polyline path, to extrude along.
//   ang = Angle in degrees to rotate 2D polyline before extrusion.
//   convexity = max number of surfaces any single ray could pass through.
// Example(FlatSpin):
//   shape = [[0,-10], [5,-3], [5,3], [0,10], [30,0]];
//   path = concat(
//       [for (a=[30:30:180]) [50*cos(a)+50, 50*sin(a), 20*sin(a)]],
//       [for (a=[330:-30:180]) [50*cos(a)-50, 50*sin(a), 20*sin(a)]]
//   );
//   path_sweep(shape, path, ang=140);
module path_sweep(polyline, path, ang=0, convexity=10) {
	pline_count = len(polyline);
	path_count = len(path);

	polyline = rotate_points2d(ccw_polygon(path2d(polyline)), ang);
	poly_points = points_along_path3d(polyline, path);

	poly_faces = concat(
		[[for (b = [0:1:pline_count-1]) b]],
		[
			for (
				p = [0:1:path_count-2],
				b = [0:1:pline_count-1],
				i = [0:1]
			) let (
				b2 = (b == pline_count-1)? 0 : b+1,
				p0 = p * pline_count + b,
				p1 = p * pline_count + b2,
				p2 = (p+1) * pline_count + b2,
				p3 = (p+1) * pline_count + b,
				pt = (i==0)? [p0, p2, p1] : [p0, p3, p2]
			) pt
		],
		[[for (b = [pline_count-1:-1:0]) b+(path_count-1)*pline_count]]
	);

	tri_faces = triangulate_faces(poly_points, poly_faces);
	polyhedron(points=poly_points, faces=tri_faces, convexity=convexity);
}



// Module: path_extrude()
// Description:
//   Extrudes 2D children along a 3D polyline path.  This may be slow.
// Arguments:
//   path = array of points for the bezier path to extrude along.
//   convexity = maximum number of walls a ran can pass through.
//   clipsize = increase if artifacts are left.  Default: 1000
// Example(FlatSpin):
//   path = [ [0, 0, 0], [33, 33, 33], [66, 33, 40], [100, 0, 0], [150,0,0] ];
//   path_extrude(path) circle(r=10, $fn=6);
module path_extrude(path, convexity=10, clipsize=100) {
	function polyquats(path, q=Q_Ident(), v=[0,0,1], i=0) = let(
			v2 = path[i+1] - path[i],
			ang = vector_angle(v,v2),
			axis = ang>0.001? normalize(cross(v,v2)) : [0,0,1],
			newq = Q_Mul(Quat(axis, ang), q),
			dist = norm(v2)
		) i < (len(path)-2)?
			concat([[dist, newq, ang]], polyquats(path, newq, v2, i+1)) :
			[[dist, newq, ang]];

	epsilon = 0.0001;  // Make segments ever so slightly too long so they overlap.
	ptcount = len(path);
	pquats = polyquats(path);
	for (i = [0:1:ptcount-2]) {
		pt1 = path[i];
		pt2 = path[i+1];
		dist = pquats[i][0];
		q = pquats[i][1];
		difference() {
			translate(pt1) {
				Qrot(q) {
					down(clipsize/2/2) {
						linear_extrude(height=dist+clipsize/2, convexity=convexity) {
							children();
						}
					}
				}
			}
			translate(pt1) {
				hq = (i > 0)? Q_Slerp(q, pquats[i-1][1], 0.5) : q;
				Qrot(hq) down(clipsize/2+epsilon) cube(clipsize, center=true);
			}
			translate(pt2) {
				hq = (i < ptcount-2)? Q_Slerp(q, pquats[i+1][1], 0.5) : q;
				Qrot(hq) up(clipsize/2+epsilon) cube(clipsize, center=true);
			}
		}
	}
}


// Module: trace_polyline()
// Description:
//   Renders lines between each point of a polyline path.
//   Can also optionally show the individual vertex points.
// Arguments:
//   pline = The array of points in the polyline.
//   closed = If true, draw the segment from the last vertex to the first.  Default: false
//   showpts = If true, draw vertices and control points.
//   N = Mark the first and every Nth vertex after in a different color and shape.
//   size = Diameter of the lines drawn.
//   color = Color to draw the lines (but not vertices) in.
// Example(FlatSpin):
//   polyline = [for (a=[0:30:210]) 10*[cos(a), sin(a), sin(a)]];
//   trace_polyline(polyline, showpts=true, size=0.5, color="lightgreen");
module trace_polyline(pline, closed=false, showpts=false, N=1, size=1, color="yellow") {
	sides = segs(size/2);
	pline = closed? close_path(pline) : pline;
	if (showpts) {
		for (i = [0:1:len(pline)-1]) {
			translate(pline[i]) {
				if (i%N == 0) {
					color("blue") sphere(d=size*2.5, $fn=8);
				} else {
					color("red") {
						cylinder(d=size/2, h=size*3, center=true, $fn=8);
						xrot(90) cylinder(d=size/2, h=size*3, center=true, $fn=8);
						yrot(90) cylinder(d=size/2, h=size*3, center=true, $fn=8);
					}
				}
			}
		}
	}
	if (N!=3) {
		color(color) path_sweep(circle(d=size,$fn=sides), path3d(pline));
	} else {
		for (i = [0:1:len(pline)-2]) {
			if (N!=3 || (i%N) != 1) {
				color(color) extrude_from_to(pline[i], pline[i+1]) circle(d=size, $fn=sides);
			}
		}
	}
}


// Module: debug_polygon()
// Description: A drop-in replacement for `polygon()` that renders and labels the path points.
// Arguments:
//   points = The array of 2D polygon vertices.
//   paths = The path connections between the vertices.
//   convexity = The max number of walls a ray can pass through the given polygon paths.
// Example(Big2D):
//   debug_polygon(
//       points=concat(
//           regular_ngon(or=10, n=8),
//           regular_ngon(or=8, n=8)
//       ),
//       paths=[
//           [for (i=[0:7]) i],
//           [for (i=[15:-1:8]) i]
//       ]
//   );
module debug_polygon(points, paths=undef, convexity=2, size=1)
{
	pths = is_undef(paths)? [for (i=[0:1:len(points)-1]) i] : is_num(paths[0])? [paths] : paths;
	echo(points=points);
	echo(paths=paths);
	linear_extrude(height=0.01, convexity=convexity, center=true) {
		polygon(points=points, paths=paths, convexity=convexity);
	}
	for (i = [0:1:len(points)-1]) {
		color("red") {
			up(0.2) {
				translate(points[i]) {
					linear_extrude(height=0.1, convexity=10, center=true) {
						text(text=str(i), size=size, halign="center", valign="center");
					}
				}
			}
		}
	}
	for (j = [0:1:len(paths)-1]) {
		path = paths[j];
		translate(points[path[0]]) {
			color("cyan") up(0.1) cylinder(d=size*1.5, h=0.01, center=false, $fn=12);
		}
		translate(points[path[len(path)-1]]) {
			color("pink") up(0.11) cylinder(d=size*1.5, h=0.01, center=false, $fn=4);
		}
		for (i = [0:1:len(path)-1]) {
			midpt = (points[path[i]] + points[path[(i+1)%len(path)]])/2;
			color("blue") {
				up(0.2) {
					translate(midpt) {
						linear_extrude(height=0.1, convexity=10, center=true) {
							text(text=str(chr(65+j),i), size=size/2, halign="center", valign="center");
						}
					}
				}
			}
		}
	}
}

// Module: path_spread()
//
// Description:
//   Uniformly spreads out copies of children along a path.  Copies are located based on path length.  If you specify `n` but not spacing then `n` copies will be placed
//   with one at path[0] of `closed` is true, or spanning the entire path from start to end if `closed` is false.
//   If you specify `spacing` but not `n` then copies will spread out starting from one at path[0] for `closed=true` or at the path center for open paths.
//   If you specify `sp` then the copies will start at `sp`.
//
// Usage:
//   path_spread(path), [n], [spacing], [sp], [rotate_children], [closed]) ...
//
// Arguments:
//   path = the path where children are placed
//   n = number of copies
//   spacing = space between copies
//   sp = if given, copies will start distance sp from the path start and spread beyond that point
//
// Side Effects:
//   `$pos` is set to the center of each copy
//   `$idx` is set to the index number of each copy.  In the case of closed paths the first copy is at `path[0]` unless you give `sp`.
//   `$dir` is set to the direction vector of the path at the point where the copy is placed.
//   `$normal` is set to the direction of the normal vector to the path direction that is coplanar with the path at this point
//
// Example(2D):
//   spiral = [for(theta=[0:360*8]) theta * [cos(theta), sin(theta)]]/100;
//   stroke(spiral,width=.25);
//   color("red") path_spread(spiral, n=100) circle(r=1);
// Example(2D):
//   circle = regular_ngon(n=64, or=10);
//   stroke(circle,width=1,closed=true);
//   color("green")path_spread(circle, n=7, closed=true) circle(r=1+$idx/3);
// Example(2D):
//   heptagon = regular_ngon(n=7, or=10);
//   stroke(heptagon, width=1, closed=true);
//   color("purple") path_spread(heptagon, n=9, closed=true) square([0.5,3],anchor=FRONT);
// Example(2D): Direction at the corners is the average of the two adjacent edges
//   heptagon = regular_ngon(n=7, or=10);
//   stroke(heptagon, width=1, closed=true);
//   color("purple") path_spread(heptagon, n=7, closed=true) square([0.5,3],anchor=FRONT);
// Example(2D):  Don't rotate the children
//   heptagon = regular_ngon(n=7, or=10);
//   stroke(heptagon, width=1, closed=true);
//   color("red") path_spread(heptagon, n=9, closed=true, rotate_children=false) square([0.5,3],anchor=FRONT);
// Example(2D): Open path, specify `n`
//   sinwav = [for(theta=[0:360]) 5*[theta/180, sin(theta)]];
//   stroke(sinwav,width=.1);
//   color("red")path_spread(sinwav, n=5) square([.2,1.5],anchor=FRONT);
// Example(2D)): Open path, specify `n` and `spacing`
//   sinwav = [for(theta=[0:360]) 5*[theta/180, sin(theta)]];
//   stroke(sinwav,width=.1);
//   color("red")path_spread(sinwav, n=5, spacing=1) square([.2,1.5],anchor=FRONT);
// Example(2D)): Closed path, specify `n` and `spacing`, copies centered around circle[0]
//   circle = regular_ngon(n=64,or=10);
//   stroke(circle,width=.1,closed=true);
//   color("red")path_spread(circle, n=10, spacing=1, closed=true) square([.2,1.5],anchor=FRONT);
// Example(2D): Open path, specify `spacing`
//   sinwav = [for(theta=[0:360]) 5*[theta/180, sin(theta)]];
//   stroke(sinwav,width=.1);
//   color("red")path_spread(sinwav, spacing=5) square([.2,1.5],anchor=FRONT);
// Example(2D): Open path, specify `sp`
//   sinwav = [for(theta=[0:360]) 5*[theta/180, sin(theta)]];
//   stroke(sinwav,width=.1);
//   color("red")path_spread(sinwav, n=5, sp=18) square([.2,1.5],anchor=FRONT);
// Example(2D):
//   wedge = arc(angle=[0,100], r=10, $fn=64);
//   difference(){
//     polygon(concat([[0,0]],wedge));
//     path_spread(wedge,n=5,spacing=3) fwd(.1)square([1,4],anchor=FRONT);
//   }
// Example(Spin): 3d example, with children rotated into the plane of the path
//   tilted_circle = lift_plane(regular_ngon(n=64, or=12), [0,0,0], [5,0,5], [0,2,3]);
//   path_sweep(regular_ngon(n=16,or=.1),tilted_circle);
//   path_spread(tilted_circle, n=15,closed=true) {
//      color("blue")cyl(h=3,r=.2, anchor=BOTTOM);      // z-aligned cylinder
//      color("red")xcyl(h=10,r=.2, anchor=FRONT+LEFT); // x-aligned cylinder
//   }
// Example(Spin): 3d example, with rotate_children set to false
//   tilted_circle = lift_plane(regular_ngon(n=64, or=12), [0,0,0], [5,0,5], [0,2,3]);
//   path_sweep(regular_ngon(n=16,or=.1),tilted_circle);
//   path_spread(tilted_circle, n=25,rotate_children=false,closed=true) {
//      color("blue")cyl(h=3,r=.2, anchor=BOTTOM);       // z-aligned cylinder
//      color("red")xcyl(h=10,r=.2, anchor=FRONT+LEFT);  // x-aligned cylinder
//   }
module path_spread(path, n, spacing, sp=undef, rotate_children=true, closed=false)
{
	length = path_length(path,closed);
	distances = is_def(sp)? (
		is_def(n) && is_def(spacing)? list_range(s=sp, step=spacing, n=n) :
		is_def(n)? list_range(s=sp, e=length, n=n) :
		list_range(s=sp, step=spacing, e=length)
	) : is_def(n) && is_undef(spacing)? (
		closed?
			let(range=list_range(s=0,e=length, n=n+1)) slice(range,0,-2) :
			list_range(s=0, e=length, n=n)
	) : (
		let(
			n = is_def(n)? n : floor(length/spacing)+(closed?0:1),
			ptlist = list_range(s=0,step=spacing,n=n),
			listcenter = mean(ptlist)
		) closed?
			sort([for(entry=ptlist) posmod(entry-listcenter,length)]) :
			[for(entry=ptlist) entry + length/2-listcenter ]
	);
	distOK = min(distances)>=0 && max(distances)<=length;
	assert(distOK,"Cannot fit all of the copies");
	cutlist = path_cut(path, distances, closed, direction=true);
	planar = len(path[0])==2;
	if (true) for(i=[0:1:len(cutlist)-1]) {
		$pos = cutlist[i][0];
		$idx = i;
		$dir = rotate_children ? (planar?[1,0]:[1,0,0]) : cutlist[i][2];
		$normal = rotate_children? (planar?[0,1]:[0,0,1]) : cutlist[i][3];
		translate($pos) {
			if (rotate_children) {
				if(planar) {
					rot(from=[0,1],to=cutlist[i][3]) children();
				} else {
					multmatrix(affine2d_to_3d(transpose([cutlist[i][2],cross(cutlist[i][3],cutlist[i][2]), cutlist[i][3]])))
						children();
				}
			} else {
				children();
			}
		}
	}
}


// Function: path_cut()
//
// Usage
//   path_cut(path, dists, [closed], [direction])
//
// Description:
//   Cuts a path at a list of distances from the first point in the path.  Returns a list of the cut
//   points and indices of the next point in the path after that point.  So for example, a return
//   value entry of [[2,3], 5] means that the cut point was [2,3] and the next point on the path after
//   this point is path[5].  If the path is too short then path_cut returns undef.  If you set
//   `direction` to true then `path_cut` will also return the tangent vector to the path and a normal
//   vector to the path.  It tries to find a normal vector that is coplanar to the path near the cut
//   point.  If this fails it will return a normal vector parallel to the xy plane.  The output with
//   direction vectors will be `[point, next_index, tangent, normal]`.
//
// Arguments:
//   path = path to cut
//   dists = distances where the path should be cut (a list) or a scalar single distance
//   closed = set to true if the curve is closed.  Default: false
//   direction = set to true to return direction vectors.  Default: false
//
// Example(NORENDER):
//   square=[[0,0],[1,0],[1,1],[0,1]];
//   path_cut(square, [.5,1.5,2.5]);   // Returns [[[0.5, 0], 1], [[1, 0.5], 2], [[0.5, 1], 3]]
//   path_cut(square, [0,1,2,3]);      // Returns [[[0, 0], 1], [[1, 0], 2], [[1, 1], 3], [[0, 1], 4]]
//   path_cut(square, [0,0.8,1.6,2.4,3.2], closed=true);  // Returns [[[0, 0], 1], [[0.8, 0], 1], [[1, 0.6], 2], [[0.6, 1], 3], [[0, 0.8], 4]]
//   path_cut(square, [0,0.8,1.6,2.4,3.2]);               // Returns [[[0, 0], 1], [[0.8, 0], 1], [[1, 0.6], 2], [[0.6, 1], 3], undef]
function path_cut(path, dists, closed=false, direction=false) =
	let(long_enough = len(path) >= (closed ? 3 : 2))
	assert(long_enough,len(path)<2 ? "Two points needed to define a path" : "Closed path must include three points")
	!is_list(dists)? path_cut(path, [dists],closed, direction)[0] :
	let(cuts = _path_cut(path,dists,closed))
	!direction ? cuts : let(
		dir = _path_cuts_dir(path, cuts, closed),
		normals = _path_cuts_normals(path, cuts, dir, closed)
	) zip(cuts, array_group(dir,1), array_group(normals,1));

// Main recursive path cut function
function _path_cut(path, dists, closed=false, pind=0, dtotal=0, dind=0, result=[]) =
	dind == len(dists) ? result :
	let(
		lastpt = len(result)>0? select(result,-1)[0] : [],
		dpartial = len(result)==0? 0 : norm(lastpt-path[pind]),
		nextpoint = dpartial > dists[dind]-dtotal?
			[lerp(lastpt,path[pind], (dists[dind]-dtotal)/dpartial),pind] :
			_path_cut_single(path, dists[dind]-dtotal-dpartial, closed, pind)
	) is_undef(nextpoint)?
		concat(result, replist(undef,len(dists)-dind)) :
		_path_cut(path, dists, closed, nextpoint[1], dists[dind],dind+1, concat(result, [nextpoint]));

// Search for a single cut point in the path
function _path_cut_single(path, dist, closed=false, ind=0, eps=1e-7) =
	ind>=len(path)? undef :
	ind==len(path)-1 && !closed? (dist<eps? [path[ind],ind+1] : undef) :
	let(d = norm(path[ind]-select(path,ind+1))) d > dist ?
		[lerp(path[ind],select(path,ind+1),dist/d), ind+1] :
		_path_cut_single(path, dist-d,closed, ind+1, eps);

// Find normal directions to the path, coplanar to local part of the path
// Or return a vector parallel to the x-y plane if the above fails
function _path_cuts_normals(path, cuts, dirs, closed=false) =
	[for(i=[0:len(cuts)-1])
		len(path[0])==2? [-dirs[i].y, dirs[i].x] : (
			let(
				plane = len(path)<3 ? undef :
				let(start = max(min(cuts[i][1],len(path)-1),2)) _path_plane(path, start, start-2)
			)
			plane==undef?
				normalize([-dirs[i].y, dirs[i].x,0]) :
				normalize(cross(dirs[i],cross(plane[0],plane[1])))
		)
	];

// Scan from the specified point (ind) to find a noncoplanar triple to use
// to define the plane of the path.
function _path_plane(path, ind, i,closed) =
	i<(closed?-1:0) ? undef :
	!collinear(path[ind],path[ind-1], select(path,i))?
		[select(path,i)-path[ind-1],path[ind]-path[ind-1]] :
		_path_plane(path, ind, i-1);

// Find the direction of the path at the cut points
function _path_cuts_dir(path, cuts, closed=false, eps=1e-2) =
	[for(ind=[0:len(cuts)-1])
		let(
			nextind = cuts[ind][1],
			nextpath = normalize(select(path, nextind+1)-select(path, nextind)),
			thispath = normalize(select(path, nextind) - path[nextind-1]),
			lastpath = normalize(path[nextind-1] - select(path, nextind-2)),
			nextdir =
				nextind==len(path) && !closed? lastpath :
				(nextind<=len(path)-2 || closed) && approx(cuts[ind][0], path[nextind],eps)?
					normalize(nextpath+thispath) :
					(nextind>1 || closed) && approx(cuts[ind][0],path[nextind-1],eps)?
						normalize(thispath+lastpath) :
						thispath
		) nextdir
	];

// Input `data` is a list that sums to an integer. 
// Returns rounded version of input data so that every 
// entry is rounded to an integer and the sum is the same as
// that of the input.  Works by rounding an entry in the list
// and passing the rounding error forward to the next entry.
// This will generally distribute the error in a uniform manner. 
function _sum_preserving_round(data, index=0) =
     index == len(data)-1 ? list_set(data, len(data)-1, round(data[len(data)-1])) :
     let(
       newval = round(data[index]),
       error = newval - data[index]
     )
     _sum_preserving_round(list_set(data, [index,index+1], [newval, data[index+1]-error]), index+1);


// Function: subdivide_path()
// Usage:
//   newpath = subdivide_path(path, N, method);
// Description:
//   Takes a path as input (closed or open) and subdivides the path to produce a more
//   finely sampled path.  The new points can be distributed proportional to length
//   (`method="length"`) or they can be divided up evenly among all the path segments
//   (`method="segment"`).  If the extra points don't fit evenly on the path then the
//   algorithm attempts to distribute them uniformly.  The `exact` option requires that
//   the final length is exactly as requested.  If you set it to `false` then the
//   algorithm will favor uniformity and the output path may have a different number of
//   points due to rounding error.
//   
//   With the `"segment"` method you can also specify a vector of lengths.  This vector, 
//   `N` specfies the desired point count on each segment: with vector input, `subdivide_path`
//   attempts to place `N[i]-1` points on segment `i`.  The reason for the -1 is to avoid
//   double counting the endpoints, which are shared by pairs of segments, so that for
//   a closed polygon the total number of points will be sum(N).  Note that with an open
//   path there is an extra point at the end, so the number of points will be sum(N)+1. 
// Arguments:
//   path = path to subdivide
//   N = scalar total number of points desired or with `method="segment"` can be a vector requesting `N[i]-1` points on segment i.
//   closed = set to false if the path is open.  Default: True
//   exact = if true return exactly the requested number of points, possibly sacrificing uniformity.  If false, return uniform point sample that may not match the number of points requested.  Default: True
//   method = One of `"length"` or `"segment"`.  If `"length"`, adds vertices evenly along the total path length.  If `"segment"`, adds points evenly among the segments.  Default: `"length"`
// Example(2D):
//   mypath = subdivide_path(square([2,2],center=true), 12);
//   place_copies(mypath)circle(r=.1,$fn=32);
// Example(2D):
//   mypath = subdivide_path(square([8,2],center=true), 12);
//   place_copies(mypath)circle(r=.2,$fn=32);
// Example(2D):
//   mypath = subdivide_path(square([8,2],center=true), 12, method="segment");
//   place_copies(mypath)circle(r=.2,$fn=32);
// Example(2D):
//   mypath = subdivide_path(square([2,2],center=true), 17, closed=false);
//   place_copies(mypath)circle(r=.1,$fn=32);
// Example(2D): Specifying different numbers of points on each segment
//   mypath = subdivide_path(hexagon(side=2), [2,3,4,5,6,7], method="segment");
//   place_copies(mypath)circle(r=.1,$fn=32);
// Example(2D): Requested point total is 14 but 15 points output due to extra end point
//   mypath = subdivide_path(pentagon(side=2), [3,4,3,4], method="segment", closed=false);
//   place_copies(mypath)circle(r=.1,$fn=32);
// Example(2D): Since 17 is not divisible by 5, a completely uniform distribution is not possible. 
//   mypath = subdivide_path(pentagon(side=2), 17);
//   place_copies(mypath)circle(r=.1,$fn=32);
// Example(2D): With `exact=false` a uniform distribution, but only 15 points
//   mypath = subdivide_path(pentagon(side=2), 17, exact=false);
//   place_copies(mypath)circle(r=.1,$fn=32);
// Example(2D): With `exact=false` you can also get extra points, here 20 instead of requested 18
//   mypath = subdivide_path(pentagon(side=2), 18, exact=false);
//   place_copies(mypath)circle(r=.1,$fn=32);
// Example(FlatSpin): Three-dimensional paths also work
//   mypath = subdivide_path([[0,0,0],[2,0,1],[2,3,2]], 12);
//   place_copies(mypath)sphere(r=.1,$fn=32);
function subdivide_path(path, N, closed=true, exact=true, method="length") =
    assert(is_path(path))
    assert(method=="length" || method=="segment")
    assert((is_num(N) && N>0) || is_vector(N),"Parameter N to subdivide_path must be postive number or vector")
    let(
      count = len(path) - (closed?0:1), 
      add_guess = 
        method=="segment" ? 
            (is_list(N) ? assert(len(N)==count,"Vector parameter N to subdivide_path has the wrong length")
                          add_scalar(N,-1)
                        : replist((N-len(path)) / count, count))
        : // method=="length"
            assert(is_num(N),"Parameter N to subdivide path must be a number when method=\"length\"")
            let(
               path_lens = concat([for (i = [0:1:len(path)-2]) norm(path[i+1]-path[i])],
                                  closed?[norm(path[len(path)-1]-path[0])]:[]),
               add_density = (N - len(path)) / sum(path_lens)
               )
            path_lens * add_density,
        add = exact ? _sum_preserving_round(add_guess) : [for (val=add_guess) round(val)]
      )
      concat(
        [for (i=[0:1:count])
          each [for(j=[0:1:add[i]]) lerp(path[i],select(path,i+1), j/(add[i]+1))]],
        closed ? [] : [select(path,-1)]
      );



// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
