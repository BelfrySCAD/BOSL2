//////////////////////////////////////////////////////////////////////
// Trapezoidal-threaded (ACME) Screw Rods and Nuts
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


// Constructs an acme threaded screw rod.  This method makes much
//  smoother threads than the naive linear_extrude method.
module acme_threaded_rod(
	d=10.5,
	l=100,
	pitch=3.175,
	thread_depth=1,
	thread_angle=14.5
) {
	astep = 360/segs(d/2);
	asteps = ceil(360/astep);
	threads = ceil(l/pitch)+2;
	pa_delta = min(pitch/4.1,(thread_depth+0.05)*tan(thread_angle)/2);
	poly_points = [
		for (
			thread = [0 : threads-1],
			astep = [0 : asteps-1],
			i = [0 : 3]
		) let (
			r = max(0, d/2 - ((i==1||i==2)? 0 : (thread_depth+0.05))),
			a = astep / asteps,
			rx = r * cos(360 * a),
			ry = r * sin(360 * a),
			tz = (thread + a - threads/2 + (i<2? -0.25 : 0.25)) * pitch + (i%2==0? -pa_delta : pa_delta)
		) [rx, ry, tz]
	];
	point_count = len(poly_points);
	poly_faces = concat(
		[
			for (
				thread = [0 : threads-1],
				astep = [0 : asteps-1],
				j = [0 : 3],
				i = [0 : 1]
			) let(
				p0 = (thread*asteps + astep)*4 + j,
				p1 = p0 + 4,
				p2 = (thread*asteps + astep)*4 + ((j+1)%4),
				p3 = p2 + 4,
				tri = (i==0? [p0, p3, p1] : [p0, p2, p3])
			)
			if (p0 < point_count-4) tri
		],
		[
			[0, 3, 2],
			[0, 2, 1],
			[point_count-4, point_count-3, point_count-2],
			[point_count-4, point_count-2, point_count-1]
		]
	);
	intersection() {
		union() {
			polyhedron(points=poly_points, faces=poly_faces, convexity=10);
			cylinder(h=(threads+0.5)*pitch, d=d-2*thread_depth, center=true, $fn=asteps);
		}
		cube([d+1, d+1, l], center=true);
	}
}
//!acme_threaded_rod(d=3/8*25.4, l=20, pitch=1/8*25.4, thread_depth=1.3, thread_angle=29, $fn=32);
//!acme_threaded_rod(d=60, l=16, pitch=8, thread_depth=3, thread_angle=45, $fa=2, $fs=2);


module acme_threaded_nut(
	od=17.4,
	id=10.5,
	h=10,
	pitch=3.175,
	thread_depth=1,
	thread_angle=14.5,
	slop=printer_slop
) {
	difference() {
		cylinder(r=od/2/cos(30), h=h, center=true, $fn=6);
		zspread(slop, n=slop>0?2:1) {
			acme_threaded_rod(d=id+2*slop, l=h+1, pitch=pitch, thread_depth=thread_depth, thread_angle=thread_angle);
		}
	}
}

//!acme_threaded_nut(od=17.4, id=10.5, h=10, pitch=3.175, thread_depth=1, slop=printer_slop);


// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
