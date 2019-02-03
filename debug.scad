//////////////////////////////////////////////////////////////////////
// Helpers to make debugging OpenScad code easier.
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
include <paths.scad>
include <beziers.scad>


// Renders lines between each point of a polyline path.
// Can also optionally show the individual vertex points.
//   pline = the array of points in the polyline.
//   showpts = If true, draw vertices and control points.
//   N = Mark the first and every Nth vertex after in a different color and shape.
//   size = diameter of the lines drawn.
//   color = Color to draw the lines (but not vertices) in.
// Example:
//   bez = [
//       [-10, 0, 0], [-15, -5, 9], [0, -3, 5], [5, -10, 0],
//       [15, 0, -5], [5, 12, -8], [0, 10, -5]
//   ];
//   trace_polyline(bez, N=3, showpts=true, size=0.5, color="lightgreen");
module trace_polyline(pline, N=1, showpts=false, size=1, color="yellow") {
	if (showpts) {
		for (i = [0:len(pline)-1]) {
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
	for (i = [0:len(pline)-2]) {
		if (N!=3 || (i%N) != 1) {
			color(color) extrude_from_to(pline[i], pline[i+1]) circle(d=size/2);
		}
	}
}


// Renders lines between each point of a polyline path.
// Can also optionally show the individual vertex points.
//   bez = the array of points in the bezier.
//   N = Mark the first and every Nth vertex after in a different color and shape.
//   size = diameter of the lines drawn.
// Example:
//   bez = [
//       [-10,   0],  [-15,  -5],
//       [ -5, -10],  [  0, -10],  [ 5, -10],
//       [ 14,  -5],  [ 15,   0],  [16,   5],
//       [  5,  10],  [  0,  10]
//   ];
//   trace_bezier(bez, N=3, size=0.5);
module trace_bezier(bez, N=3, size=1) {
	trace_polyline(bez, N=N, showpts=true, size=size/2, color="green");
	trace_polyline(bezier_polyline(bez, N=N), size=size);
}


// Draws all the vertices in an array, at their 3D position, numbered by their
// position in the vertex array.  Also draws any children of this module with
// transparency.
//   vertices = Array of point vertices.
//   size     = The size of the text used to label the vertices.
//   disabled = If true, don't draw numbers, and draw children without transparency.  Default = false.
// Example:
//   verts = [
//       [-10, 0, -10], [10, 0, -10],
//       [0, -10, 10], [0, 10, 10]
//   ];
//   faces = [
//       [0,2,1], [1,2,3], [0,3,2], [1,3,0]
//   ];
//   debug_vertices(vertices=verts, size=2) {
//       polyhedron(points=verts, faces=faces);
//   }
module debug_vertices(vertices, size=1, disabled=false) {
	if (!disabled) {
		echo(vertices=vertices);
		color("blue") {
			for (i = [0:len(vertices)-1]) {
				v = vertices[i];
				translate(v) {
					up(size/8) zrot($vpr[2]) xrot(90) {
						linear_extrude(height=size/10, center=true, convexity=10) {
							text(text=str(i), size=size, halign="center");
						}
					}
					sphere(size/10);
				}
			}
		}
	}
	if ($children > 0) {
		if (!disabled) {
			color([0.5, 0.5, 0, 0.25]) children();
		} else {
			children();
		}
	}
}



// Draws all the vertices at their 3D position, numbered in blue by their
// position in the vertex array.  Each face will have their face number drawn
// in red, aligned with the center of face.  All children of this module are drawn
// with transparency.
//   vertices = Array of point vertices.
//   faces    = Array of faces by vertex numbers.
//   size     = The size of the text used to label the faces and vertices.
//   disabled = If true, don't draw numbers, and draw children without transparency.  Default = false.
// Example:
//   verts = [
//       [-10, 0, -10], [10, 0, -10],
//       [0, -10, 10], [0, 10, 10]
//   ];
//   faces = [
//       [0,2,1], [1,2,3], [0,3,2], [1,3,0]
//   ];
//   debug_faces(vertices=verts, faces=faces, size=2) {
//       polyhedron(points=verts, faces=faces);
//   }
module debug_faces(vertices, faces, size=1, disabled=false) {
	if (!disabled) {
		vlen = len(vertices);
		color("red") {
			for (i = [0:len(faces)-1]) {
				face = faces[i];
				if (face[0] < 0 || face[1] < 0 || face[2] < 0 || face[0] >= vlen || face[1] >= vlen || face[2] >= vlen) {
					echo("BAD FACE: ", vlen=vlen, face=face);
				} else {
					v0 = vertices[face[0]];
					v1 = vertices[face[1]];
					v2 = vertices[face[2]];
					c = (v0 + v1 + v2) / 3;
					dv0 = normalize(v1 - v0);
					dv1 = normalize(v2 - v0);
					nrm0 = normalize(cross(dv0, dv1));
					nrm1 = [0, 0, 1];
					axis = normalize(cross(nrm0, nrm1));
					ang = vector3d_angle(nrm0,  nrm1);
					theta = atan2(nrm0[1], nrm0[0]);
					translate(c) {
						rotate(a=180-ang, v=axis) {
							zrot(theta-90)
							linear_extrude(height=size/10, center=true, convexity=10) {
								union() {
									text(text=str(i), size=size, halign="center");
									text(text=str("_"), size=size, halign="center");
								}
							}
						}
					}
				}
			}
		}
	}
	debug_vertices(vertices, size=size, disabled=disabled) {
		children();
	}
	if (!disabled) {
		echo(faces=faces);
	}
}



// A drop-in module to replace `polyhedron()` and help debug vertices and faces.
// Draws all the vertices at their 3D position, numbered in blue by their
// position in the vertex array.  Each face will have their face number drawn
// in red, aligned with the center of face.  All given faces are drawn with
// transparency. All children of this module are drawn with transparency.
// Works best with Thrown-Together preview mode, to see reversed faces.
//   vertices = Array of point vertices.
//   faces = Array of faces by vertex numbers.
//   txtsize = The size of the text used to label the faces and vertices.
//   disabled = If true, act exactly like `polyhedron()`.  Default = false.
// Example:
//   pts = [[-5,0,-5], [5,0,-5], [0,-5,5], [0,5,5]];
//   fcs = [[0,2,1], [1,2,3], [1,3,0], [0,2,3]];  // Last face reversed
//   debug_polyhedron(points=pts, faces=fcs, txtsize=1);
module debug_polyhedron(points, faces, convexity=10, txtsize=1, disabled=false) {
	debug_faces(vertices=points, faces=faces, size=txtsize, disabled=disabled) {
		polyhedron(points=points, faces=faces, convexity=convexity);
	}
}



// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
