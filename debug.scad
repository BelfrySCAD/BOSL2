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


module debug_vertices(vertices, size=1, disabled=false) {
	if (!disabled) {
		echo(vertices=vertices);
		color("blue") {
			for (i = [0:len(vertices)-1]) {
				v = vertices[i];
				translate(v) {
					zrot(atan2(v[1],v[0])+90) xrot(90) {
						linear_extrude(height=size/10, center=true, convexity=10) {
							text(text=str(i), size=size, halign="center", valign="bottom");
						}
					}
					sphere(0.02);
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



module debug_polyhedron(points, faces, convexity=10, txtsize=1, disabled=false) {
	debug_faces(vertices=points, faces=faces, size=txtsize, disabled=disabled) {
		polyhedron(points=points, faces=faces, convexity=convexity);
	}
}



// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
