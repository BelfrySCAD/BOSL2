//////////////////////////////////////////////////////////////////////
// 2D and Bezier Stuff.
//////////////////////////////////////////////////////////////////////

/*
BSD 2-Clause License

Copyright (c) 2017, Revar Desmera
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/


include <transforms.scad>
include <math.scad>
include <quaternions.scad>
include <triangulation.scad>


// Creates a 2D polygon circle, modulated by one or more superimposed
// sine waves.
//   r = radius of the base circle.
//   sines = array of [amplitude, frequency] pairs, where the frequency is the
//           number of times the cycle repeats around the circle.
// Example:
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


// Similar to linear_extrude(), except the result is a hollow shell.
//   wall = thickness of shell wall.
//   height = height of extrusion.
//   twist = degrees of twist, from bottom to top.
//   slices = how many slices to use when making extrusion.
// Example:
//   extrude_2d_hollow(wall=2, height=100, twist=90, slices=50)
//     circle(r=40, center=true, $fn=6);
module extrude_2d_hollow(wall=2, height=50, twist=90, slices=60)
{
	linear_extrude(height=height, twist=twist, slices=slices) {
		difference() {
			children();
			offset(r=-wall) {
				children();
			}
		}
	}
}


// Takes a 2D polyline and removes uneccessary collinear points.
function simplify2d_path(path) = concat(
	[path[0]],
	[
		for (
			i = [1:len(path)-2]
		) let (
			v1 = path[i] - path[i-1],
			v2 = path[i+1] - path[i-1]
		) if (abs(cross(v1,v2)) > 1e-6) path[i]
	],
	[path[len(path)-1]]
);


// Takes a 3D polyline and removes uneccessary collinear points.
function simplify3d_path(path) = concat(
	[path[0]],
	[
		for (
			i = [1:len(path)-2]
		) let (
			v1 = path[i] - path[i-1],
			v2 = path[i+1] - path[i-1]
		) if (vector3d_angle(v1,v2) > 1e-6) path[i]
	],
	[path[len(path)-1]]
);



// Takes a closed 2D polyline path, centered on the XY plane, and
// extrudes it along a 3D spiral path of a given radius, height and twist.
//   polyline = Array of points of a polyline path, to be extruded.
//   h = height of the spiral to extrude along.
//   r = radius of the spiral to extrude along.
//   twist = number of degrees of rotation to spiral up along height.
// Example:
//   poly = [[-10,0], [-3,-5], [3,-5], [10,0], [0,-30]];
//   extrude_2dpath_along_spiral(poly, h=200, r=50, twist=1000, $fn=36);
module extrude_2dpath_along_spiral(polyline, h, r, twist=360) {
	pline_count = len(polyline);
	steps = ceil(segs(r)*(twist/360));

	poly_points = [
		for (
			p = [0:steps]
		) let (
			a = twist * (p/steps),
			dx = r*cos(a),
			dy = r*sin(a),
			dz = h * (p/steps),
			cp = [dx, dy, dz],
			rotx = matrix3_xrot(90),
			rotz = matrix3_zrot(a),
			rotm = rotz * rotx
		) for (
			b = [0:pline_count-1]
		) rotm*point3d(polyline[b])+cp
	];

	poly_faces = concat(
		[[for (b = [0:pline_count-1]) b]],
		[
			for (
				p = [0:steps-1],
				b = [0:pline_count-1],
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
	polyhedron(points=poly_points, faces=tri_faces, convexity=10);
}


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
	ang = vector3d_angle(v1, v2),
	hang = ang * (n==0? 1.0 : 0.5),
	hrot = Quat(axis, hang),
	arot = Quat(axis, ang),
	roth = Q_Mul(hrot, q),
	rotm = Q_Mul(arot, q)
) concat(
	[for (i = [0:len(polyline)-1]) Q_Rot_Vector(point3d(polyline[i]),roth) + path[n]],
	(n == end)? [] : points_along_path3d(polyline, path, rotm, n+1)
);


// Takes a closed 2D polyline path, centered on the XY plane, and
// extrudes it perpendicularly along a 3D polyline path, forming a solid.
//   polyline = Array of points of a polyline path, to be extruded.
//   path = Array of points of a polyline path, to extrude along.
//   convexity = max number of surfaces any single ray could pass through.
// Example:
//   shape = [ [-15, 0], [0, 0], [-5, 10], [0, 10], [5, 10], [10, 5], [15, 0], [10, -5], [5, -10], [0, -10], [-5, -10], [-10, -5], [-15, 0] ];
//   path = [ [0, 0, 0], [100, 33, 33], [200, -33, -33], [300, 0, 0] ];
//   extrude_2dpath_along_3dpath(shape, path);
module extrude_2dpath_along_3dpath(polyline, path, convexity=10) {
	pline_count = len(polyline);
	path_count = len(path);

	poly_points = points_along_path3d(polyline, path);

	poly_faces = concat(
		[[for (b = [0:pline_count-1]) b]],
		[
			for (
				p = [0:path_count-2],
				b = [0:pline_count-1],
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



// Extrudes 2D children along a 3D polyline path.
//   path = array of points for the bezier path to extrude along.
//   convexity = maximum number of walls a ran can pass through.
//   clipsize = increase if artifacts are left.  Default: 1000
// Example:
//   path = [ [0, 0, 0], [33, 33, 33], [66, 33, 40], [100, 0, 0] ];
//   extrude_2d_shapes_along_3dpath(path) circle(r=10, center=true);
module extrude_2d_shapes_along_3dpath(path, convexity=10, clipsize=1000) {
	ptcount = len(path);
	for (i = [0 : ptcount-2]) {
		pt1 = path[i];
		pt2 = path[i+1];
		pt0 = i==0? pt1 : path[i-1];
		pt3 = (i>=ptcount-2)? pt2 : path[i+2];
		dist = distance(pt1,pt2);
		v1 = pt2-pt1;
		v0 = (i==0)? v1 : (pt1-pt0);
		v2 = (i==ptcount-2)? v1 : (pt3-pt2);
		az1 = atan2(v1[1], v1[0]);
		alt1 = (len(pt1)<3)? 0 : atan2(v1[2], hypot(v1[1], v1[0]));
		az0 = atan2(v0[1], v0[0]);
		alt0 = (len(pt0)<3)? 0 : atan2(v0[2], hypot(v0[1], v0[0]));
		az2 = atan2(v2[1], v2[0]);
		alt2 = (len(pt2)<3)? 0 : atan2(v2[2], hypot(v2[1], v2[0]));
		translate(pt1) {
			difference() {
				rotate([0, 90-alt1, az1]) {
					down(dist) {
						linear_extrude(height=dist*3, convexity=10) {
							children();
						}
					}
				}
				rotate([0, 90-(alt0+alt1)/2, (az0+az1)/2]) {
					down(dist+0.05) {
						cube(size=[clipsize,clipsize,dist*2], center=true);
					}
				}
				translate(v1) {
					rotate([0, 90-(alt1+alt2)/2, (az1+az2)/2]) {
						up(dist) {
							cube(size=[clipsize,clipsize,dist*2], center=true);
						}
					}
				}
			}
		}
	}
}



// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
