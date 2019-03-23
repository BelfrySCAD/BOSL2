//////////////////////////////////////////////////////////////////////
// LibFile: beziers.scad
//   Bezier functions and modules.
//   To use, add the following lines to the beginning of your file:
//   ```
//   include <BOSL/constants.scad>
//   use <BOSL/beziers.scad>
//   ```
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


include <constants.scad>
use <math.scad>
use <paths.scad>
use <transforms.scad>


// Section: Terminology
//   **Polyline**: A series of points joined by straight line segements.
//   
//   **Bezier Curve**: A mathematical curve that joins two endpoints, following a curve determined by one or more control points.
//   
//   **Endpoint**: A point that is on the end of a bezier segment.  This point lies on the bezier curve.
//   
//   **Control Point**: A point that influences the shape of the curve that connects two endpoints.  This is often *NOT* on the bezier curve.
//   
//   **Degree**: The number of control points, plus one endpoint, needed to specify a bezier segment.  Most beziers are cubic (degree 3).
//   
//   **Bezier Segment**: A list consisting of an endpoint, one or more control points, and a final endpoint.  The number of control points is one less than the degree of the bezier.  A cubic (degree 3) bezier segment looks something like:
//       `[endpt1, cp1, cp2, endpt2]`
//   
//   **Bezier Path**: A list of bezier segments flattened out into a list of points, where each segment shares the endpoint of the previous segment as a start point. A cubic Bezier Path looks something like:
//       `[endpt1, cp1, cp2, endpt2, cp3, cp4, endpt3]`
//   **NOTE**: A bezier path is *NOT* a polyline.  It is only the points and controls used to define the curve.
//   
//   **Spline Steps**: The number of straight-line segments to split a bezier segment into, to approximate the bezier curve.  The more spline steps, the closer the approximation will be to the curve, but the slower it will be to generate.  Usually defaults to 16.


// Section: Functions

// Function: bez_point()
// Usage:
//   bez_point(curve, u)
// Description:
//   Formula to calculate points on a bezier curve.  The degree of
//   the curve, N, is one less than the number of points in `curve`.
// Arguments:
//   curve = The list of endpoints and control points for this bezier segment.
//   u = The proportion of the way along the curve to find the point of.  0<=`u`<=1
// Example(2D): Quadratic (Degree 2) Bezier.
//   bez = [[0,0], [30,30], [80,0]];
//   trace_bezier(bez, N=len(bez)-1);
//   translate(bez_point(bez, 0.3)) color("red") sphere(1);
// Example(2D): Cubic (Degree 3) Bezier
//   bez = [[0,0], [5,35], [60,-25], [80,0]];
//   trace_bezier(bez, N=len(bez)-1);
//   translate(bez_point(bez, 0.4)) color("red") sphere(1);
// Example(2D): Degree 4 Bezier.
//   bez = [[0,0], [5,15], [40,20], [60,-15], [80,0]];
//   trace_bezier(bez, N=len(bez)-1);
//   translate(bez_point(bez, 0.8)) color("red") sphere(1);
function bez_point(curve,u)=
	(len(curve) <= 1) ?
		curve[0] :
		bez_point(
			[for(i=[0:len(curve)-2]) curve[i]*(1-u)+curve[i+1]*u],
			u
		);


// Function: bezier_polyline()
// Usage:
//   bezier_polyline(bezier, [splinesteps], [N])
// Description:
//   Takes a bezier path and converts it into a polyline.
// Arguments:
//   bezier = A bezier path to approximate.
//   splinesteps = Number of straight lines to split each bezier segment into. default=16
//   N = The degree of the bezier curves.  Cubic beziers have N=3.  Default: 3
// Example(2D):
//   bez = [
//       [0,0], [-5,30],
//       [20,60], [50,50], [110,30],
//       [60,25], [70,0], [80,-25],
//       [80,-50], [50,-50]
//   ];
//   trace_polyline(bez, size=1, N=3, showpts=true);
//   trace_polyline(bezier_polyline(bez, N=3), size=3);
function bezier_polyline(bezier, splinesteps=16, N=3) = concat(
	[
		for (
			b = [0 : N : len(bezier)-N-1],
			l = [0 : splinesteps-1]
		) let (
			crv = [for (i=[0 : N]) bezier[b+i]],
			u = l / splinesteps
		) bez_point(crv, u)
	],
	[bez_point([for (i=[-(N+1) : -1]) bezier[len(bezier)+i]], 1.0)]
);


// Function: fillet3pts()
// Usage:
//   fillet3pts(p0, p1, p2, r);
// Description:
//   Takes three points, defining two line segments, and works out the
//   cubic (degree 3) bezier segment (and surrounding control points)
//   needed to approximate a rounding of the corner with radius `r`.
//   If there isn't room for a radius `r` rounding, uses the largest
//   radius that will fit.  Returns [cp1, endpt1, cp2, cp3, endpt2, cp4]
// Arguments:
//   p0 = The starting point.
//   p1 = The middle point.
//   p2 = The ending point.
//   r = The radius of the fillet/rounding.
//   maxerr = Max amount bezier curve should diverge from actual radius curve.  Default: 0.1
// Example(2D):
//   p0 = [40, 0];
//   p1 = [0, 0];
//   p2 = [30, 30];
//   trace_polyline([p0,p1,p2], showpts=true, size=0.5, color="green");
//   fbez = fillet3pts(p0,p1,p2, 10);
//   trace_bezier(slice(fbez, 1, -2), size=1);
function fillet3pts(p0, p1, p2, r, maxerr=0.1, w=0.5, dw=0.25) = let(
		v0 = normalize(p0-p1),
		v1 = normalize(p2-p1),
		midv = normalize((v0+v1)/2),
		a = vector3d_angle(v0,v1),
		tanr = min(r/tan(a/2), norm(p0-p1)*0.99, norm(p2-p1)*0.99),
		tp0 = p1+v0*tanr,
		tp1 = p1+v1*tanr,
		cp = p1 + midv * tanr / cos(a/2),
		cp0 = lerp(tp0, p1, w),
		cp1 = lerp(tp1, p1, w),
		cpr = norm(cp-tp0),
		bp = bez_point([tp0, cp0, cp1, tp1], 0.5),
		tdist = norm(cp-bp)
	) (abs(tdist-cpr) <= maxerr)? [tp0, tp0, cp0, cp1, tp1, tp1] :
		(tdist<cpr)? fillet3pts(p0, p1, p2, r, maxerr=maxerr, w=w+dw, dw=dw/2) :
		fillet3pts(p0, p1, p2, r, maxerr=maxerr, w=w-dw, dw=dw/2);


// Function: fillet_path()
// Usage:
//   fillet_path(pts, fillet, [maxerr]);
// Description:
//   Takes a 3D polyline path and fillets the corners, returning a 3d cubic (degree 3) bezier path.
// Arguments:
//   pts = 3D Polyline path to fillet.
//   fillet = The radius to fillet/round the polyline corners by.
//   maxerr = Max amount bezier curve should diverge from actual radius curve.  Default: 0.1
// Example(2D):
//   pline = [[40,0], [0,0], [35,35], [0,70], [-10,60], [-5,55], [0,60]];
//   bez = fillet_path(pline, 10);
//   trace_polyline(pline, showpts=true, size=0.5, color="green");
//   trace_bezier(bez, size=1);
function fillet_path(pts, fillet, maxerr=0.1) = concat(
	[pts[0], pts[0]],
	(len(pts) < 3)? [] : [
		for (p = [1 : len(pts)-2]) let(
			p1 = pts[p],
			p0 = (pts[p-1]+p1)/2,
			p2 = (pts[p+1]+p1)/2
		) for (pt = fillet3pts(p0, p1, p2, fillet, maxerr=maxerr)) pt
	],
	[pts[len(pts)-1], pts[len(pts)-1]]
);


// Function: bezier_close_to_axis()
// Usage:
//   bezier_close_to_axis(bezier, [N]);
// Description:
//   Takes a 2D bezier path and closes it to the X axis.
// Arguments:
//   bezier = The 2D bezier path to close to the X axis.
//   N = The degree of the bezier curves.  Cubic beziers have N=3.  Default: 3
// Example(2D):
//   bez = [[50,30], [40,10], [10,50], [0,30], [-10, 10], [-30,10], [-50,20]];
//   closed = bezier_close_to_axis(bez);
//   trace_bezier(closed, size=1);
function bezier_close_to_axis(bezier, N=3) =
	let(
		bezend = len(bezier)-1
	) concat(
		[for (i=[0:N-1]) lerp([bezier[0][0], 0], bezier[0], i/N)],
		bezier,
		[for (i=[1:N]) lerp(bezier[bezend], [bezier[bezend][0], 0], i/N)],
		[for (i=[1:N]) lerp([bezier[bezend][0], 0], [bezier[0][0], 0], i/N)]
	);


// Function: bezier_offset()
// Usage:
//   bezier_offset(inset, bezier, [N]);
// Description:
//   Takes a 2D bezier path and closes it with a matching path that is
//   lowered by a given amount towards the X axis.
// Arguments:
//   inset = Amount to lower second path by.
//   bezier = The 2D bezier path to close to the X axis.
//   N = The degree of the bezier curves.  Cubic beziers have N=3.  Default: 3
// Example(2D):
//   bez = [[50,30], [40,10], [10,50], [0,30], [-10, 10], [-30,10], [-50,20]];
//   closed = bezier_offset(5, bez);
//   trace_bezier(closed, size=1);
function bezier_offset(inset, bezier, N=3) =
	let(
		backbez = reverse([ for (pt = bezier) [pt[0], pt[1]-inset] ]),
		bezend = len(bezier)-1
	) concat(
		bezier,
		[for (i=[1:N-1]) lerp(bezier[bezend], backbez[0], i/N)],
		backbez,
		[for (i=[1:N]) lerp(backbez[bezend], bezier[0], i/N)]
	);


// Section: Modules


// Module: bezier_polygon()
// Usage:
//   bezier_polygon(bezier, [splinesteps], [N]) {
// Description:
//   Takes a closed 2D bezier path, and creates a 2D polygon from it.
// Arguments:
//   bezier = The closed bezier path to make into a polygon.
//   splinesteps = Number of straight lines to split each bezier segment into. default=16
//   N = The degree of the bezier curves.  Cubic beziers have N=3.  Default: 3
// Example(2D):
//   bez = [
//       [0,0], [-5,30],
//       [20,60], [50,50], [110,30],
//       [60,25], [70,0], [80,-25],
//       [80,-50], [50,-50], [30,-50],
//       [5,-30], [0,0]
//   ];
//   trace_bezier(bez, N=3, size=3);
//   linear_extrude(height=0.1) bezier_polygon(bez, N=3);
module bezier_polygon(bezier, splinesteps=16, N=3) {
	polypoints=bezier_polyline(bezier, splinesteps, N);
	polygon(points=slice(polypoints, 0, -1));
}


// Module: revolve_bezier()
// Usage:
//   revolve_bezier(bezier, [splinesteps], [N], [convexity], [angle], [orient], [align])
// Description:
//   Takes a closed 2D bezier and rotates it around the X axis, forming a solid.
// Arguments:
//   bezier = array of 2D points for the bezier path to rotate.
//   splinesteps = number of segments to divide each bezier segment into. default=16
//   N = number of points in each bezier segment.  default=3 (cubic)
//   convexity = max number of walls a line could pass through, for preview.  default=10
//   angle = Degrees of sweep to make.  Default: 360
//   orient = Orientation of the extrusion.  Use the `ORIENT_` constants from `constants.scad`.  Default: `ORIENT_X`.
//   align = Alignment of the extrusion.  Use the `V_` constants from `constants.scad`.  Default: `V_CENTER`.
// Example(FlatSpin):
//   path = [
//     [  0, 10], [ 50,  0], [ 50, 40],
//     [ 95, 40], [100, 40], [100, 45],
//     [ 95, 45], [ 66, 45], [  0, 20],
//     [  0, 12], [  0, 12], [  0, 10],
//     [  0, 10]
//   ];
//   revolve_bezier(path, splinesteps=32, $fn=180);
module revolve_bezier(bezier, splinesteps=16, N=3, convexity=10, angle=360, orient=ORIENT_X, align=V_CENTER)
{
	maxx = max([for (pt = bezier) abs(pt[0])]);
	maxy = max([for (pt = bezier) abs(pt[1])]);
	orient_and_align([maxx*2,maxx*2,maxy*2], orient, align) {
		rotate_extrude(convexity=convexity, angle=angle) {
			xrot(180) zrot(-90) bezier_polygon(bezier, splinesteps, N);
		}
	}
}



// Module: rotate_extrude_bezier()
// Usage:
//   rotate_extrude_bezier(bezier, splinesteps=16, N=3, convexity=10, angle=360)
// Description:
//   Takes a closed 2D bezier and rotates it around the Z axis, forming a solid.
//   Behaves like rotate_extrude(), except for beziers instead of shapes.
// Arguments:
//   bezier = array of 2D points for the bezier path to rotate.
//   splinesteps = number of segments to divide each bezier segment into. default=16
//   N = number of points in each bezier segment.  default=3 (cubic)
//   convexity = max number of walls a line could pass through, for preview.  default=10
//   angle = Degrees of sweep to make.  Default: 360
//   orient = Orientation of the extrusion.  Use the `ORIENT_` constants from `constants.scad`.  Default: `ORIENT_Z`.
//   align = Alignment of the extrusion.  Use the `V_` constants from `constants.scad`.  Default: `V_CENTER`.
// Example(Spin):
//   path = [
//     [  0, 10], [ 50,  0], [ 50, 40],
//     [ 95, 40], [100, 40], [100, 45],
//     [ 95, 45], [ 66, 45], [  0, 20],
//     [  0, 12], [  0, 12], [  0, 10],
//     [  0, 10]
//   ];
//   rotate_extrude_bezier(path, splinesteps=32, $fn=180);
module rotate_extrude_bezier(bezier, splinesteps=16, N=3, convexity=10, angle=360, orient=ORIENT_Z, align=V_CENTER)
{
	maxx = max([for (pt = bezier) abs(pt[0])]);
	maxy = max([for (pt = bezier) abs(pt[1])]);
	orient_and_align([maxx*2,maxx*2,0], orient, align) {
		rotate_extrude(convexity=convexity, angle=angle) {
			bezier_polygon(bezier, splinesteps, N);
		}
	}
}



// Module: revolve_bezier_solid_to_axis()
// Usage:
//   revolve_bezier_solid_to_axis(bezier, [splinesteps], [N], [convexity], [angle], [orient], [align]);
// Description:
//   Takes a 2D bezier and rotates it around the X axis, forming a solid.
// Arguments:
//   bezier = array of points for the bezier path to rotate.
//   splinesteps = number of segments to divide each bezier segment into. default=16
//   N = number of points in each bezier segment.  default=3 (cubic)
//   convexity = max number of walls a line could pass through, for preview.  default=10
//   angle = Degrees of sweep to make.  Default: 360
//   orient = Orientation of the extrusion.  Use the `ORIENT_` constants from `constants.scad`.  Default: `ORIENT_X`.
//   align = Alignment of the extrusion.  Use the `V_` constants from `constants.scad`.  Default: `V_CENTER`.
// Example(FlatSpin):
//   path = [ [0, 10], [33, 10], [66, 40], [100, 40] ];
//   revolve_bezier_solid_to_axis(path, splinesteps=32, $fn=72);
module revolve_bezier_solid_to_axis(bezier, splinesteps=16, N=3, convexity=10, angle=360, orient=ORIENT_X, align=V_CENTER) {
	revolve_bezier(bezier=bezier_close_to_axis(bezier), splinesteps=splinesteps, N=N, convexity=convexity, angle=angle, orient=orient, align=align);
}


// Module: revolve_bezier_offset_shell()
// Usage:
//   revolve_bezier_offset_shell(bezier, offset, [splinesteps], [N], [convexity], [angle], [orient], [align]);
// Description:
//   Takes a 2D bezier and rotates it around the X axis, into a hollow shell.
// Arguments:
//   bezier = array of points for the bezier path to rotate.
//   offset = the thickness of the created shell.
//   splinesteps = number of segments to divide each bezier segment into. default=16
//   N = number of points in each bezier segment.  default=3 (cubic)
//   convexity = max number of walls a line could pass through, for preview.  default=10
//   angle = degrees of sweep to make.  Default: 360
//   orient = Orientation of the extrusion.  Use the `ORIENT_` constants from `constants.scad`.  Default: `ORIENT_X`.
//   align = Alignment of the extrusion.  Use the `V_` constants from `constants.scad`.  Default: `V_CENTER`.
// Example(FlatSpin):
//   path = [ [0, 10], [33, 10], [66, 40], [100, 40] ];
//   revolve_bezier_offset_shell(path, offset=1, splinesteps=32, $fn=72);
module revolve_bezier_offset_shell(bezier, offset=1, splinesteps=16, N=3, convexity=10, angle=360, orient=ORIENT_X, align=V_CENTER) {
	revolve_bezier(bezier=bezier_offset(offset, bezier), splinesteps=splinesteps, N=N, orient=orient, align=align);
}


// Module: extrude_2d_shapes_along_bezier()
// Usage:
//   extrude_2d_shapes_along_bezier(bezier, [splinesteps], [N], [convexity], [clipsize]) ...
// Description:
//   Extrudes 2D children along a bezier path.
// Arguments:
//   bezier = array of points for the bezier path to extrude along.
//   splinesteps = number of segments to divide each bezier segment into. default=16
// Example(FR,FlatSpin):
//   path = [ [0, 0, 0], [33, 33, 33], [66, -33, -33], [100, 0, 0] ];
//   extrude_2d_shapes_along_bezier(path) difference(){
//       circle(r=10);
//       fwd(10/2) circle(r=8);
//   }
module extrude_2d_shapes_along_bezier(bezier, splinesteps=16, N=3, convexity=10, clipsize=1000) {
	path = slice(bezier_polyline(bezier, splinesteps, N), 0, -1);
	extrude_2d_shapes_along_3dpath(path, convexity=convexity, clipsize=clipsize) children();
}


// Module: extrude_bezier_along_bezier()
// Usage:
//   extrude_bezier_along_bezier(bezier, path, [pathsteps], [bezsteps], [bezN], [pathN]);
// Description:
//   Takes a closed 2D bezier path, centered on the XY plane, and
//   extrudes it perpendicularly along a 3D bezier path, forming a solid.
// Arguments:
//   bezier = Array of 2D points of a bezier path, to be extruded.
//   path = Array of 3D points of a bezier path, to extrude along.
//   pathsteps = number of steps to divide each path segment into.
//   bezsteps = number of steps to divide each bezier segment into.
//   bezN = number of points in each extruded bezier segment.  default=3 (cubic)
//   pathN = number of points in each path bezier segment.  default=3 (cubic)
// Example(FlatSpin):
//   bez = [
//       [-10,   0],  [-15,  -5],
//       [ -5, -10],  [  0, -10],  [ 5, -10],
//       [ 10,  -5],  [ 15,   0],  [10,   5],
//       [  5,  10],  [  0,  10],  [-5,  10],
//       [ 25, -15],  [-10,   0]
//   ];
//   path = [ [0, 0, 0], [33, 33, 33], [90, 33, -33], [100, 0, 0] ];
//   extrude_bezier_along_bezier(bez, path, pathsteps=32, bezsteps=16);
module extrude_bezier_along_bezier(bezier, path, pathsteps=16, bezsteps=16, bezN=3, pathN=3) {
	bez_points = simplify2d_path(bezier_polyline(bezier, bezsteps, bezN));
	path_points = simplify3d_path(path3d(bezier_polyline(path, pathsteps, pathN)));
	extrude_2dpath_along_3dpath(bez_points, path_points);
}



// Module: linear_extrude_bezier()
// Usage:
//   linear_extrude_bezier(bezier, height, [splinesteps], [N], [center], [convexity], [twist], [slices], [scale], [orient], [align]);
// Description:
//   Takes a closed 2D bezier path, centered on the XY plane, and
//   extrudes it linearly upwards, forming a solid.
// Arguments:
//   bezier = Array of 2D points of a bezier path, to be extruded.
//   splinesteps = Number of steps to divide each bezier segment into. default=16
//   N = The degree of the bezier curves.  Cubic beziers have N=3.  Default: 3
//   convexity = max number of walls a line could pass through, for preview.  default=10
//   twist = Angle in degrees to twist over the length of extrusion.  default=0
//   scale = Relative size of top of extrusion to the bottom.  default=1.0
//   slices = Number of vertical slices to use for twisted extrusion.  default=20
//   center = If true, the extruded solid is centered vertically at z=0.
//   orient = Orientation of the extrusion.  Use the `ORIENT_` constants from `constants.scad`.  Default: `ORIENT_Z`.
//   align = Alignment of the extrusion.  Use the `V_` constants from `constants.scad`.  Default: `ALIGN_POS`.
// Example:
//   bez = [
//       [-10,   0],  [-15,  -5],
//       [ -5, -10],  [  0, -10],  [ 5, -10],
//       [ 10,  -5],  [ 15,   0],  [10,   5],
//       [  5,  10],  [  0,  10],  [-5,  10],
//       [ 25, -15],  [-10,   0]
//   ];
//   linear_extrude_bezier(bez, height=20, splinesteps=32);
module linear_extrude_bezier(bezier, height=100, splinesteps=16, N=3, center=undef, convexity=undef, twist=undef, slices=undef, scale=undef, orient=ORIENT_Z, align=ALIGN_POS) {
	maxx = max([for (pt = bezier) abs(pt[0])]);
	maxy = max([for (pt = bezier) abs(pt[1])]);
	orient_and_align([maxx*2,maxy*2,height], orient, align) {
		linear_extrude(height=height, center=true, convexity=convexity, twist=twist, slices=slices, scale=scale) {
			bezier_polygon(bezier, splinesteps=splinesteps, N=N);
		}
	}
}


// Module: trace_bezier()
// Description:
//   Renders 2D or 3D bezier paths and their associated control points.
//   Useful for debugging bezier paths.
// Arguments:
//   bez = the array of points in the bezier.
//   N = Mark the first and every Nth vertex after in a different color and shape.
//   size = diameter of the lines drawn.
// Example(2D):
//   bez = [
//       [-10,   0],  [-15,  -5],
//       [ -5, -10],  [  0, -10],  [ 5, -10],
//       [ 14,  -5],  [ 15,   0],  [16,   5],
//       [  5,  10],  [  0,  10]
//   ];
//   trace_bezier(bez, N=3, size=0.5);
module trace_bezier(bez, N=3, size=1) {
	trace_polyline(bez, N=N, showpts=true, size=size/2, color="green");
	trace_polyline(bezier_polyline(bez, N=N), size=size, color="cyan");
}


// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
