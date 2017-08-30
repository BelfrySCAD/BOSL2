//////////////////////////////////////////////////////////////////////
// Rendering for wiring bundles
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


include <math.scad>
include <paths.scad>
include <beziers.scad>


// Returns an array of 1 or 6 points that form a ring, based on wire diam and ring level.
// Level 0 returns a single point at 0,0.  All greater levels return 6 points.
function hex_offset_ring(wirediam, lev=0) =
	(lev == 0)? [[0,0]] : [
		for (
			sideang = [0:60:359.999],
			sidewire = [1:lev]
		) [
			lev*wirediam*cos(sideang)+sidewire*wirediam*cos(sideang+120),
			lev*wirediam*sin(sideang)+sidewire*wirediam*sin(sideang+120)
		]
	];


// Returns an array of 2D centerpoints for each of a bundle of wires of given diameter.
// The lev and arr variables are used for internal recursion.
function hex_offsets(wires, wirediam, lev=0, arr=[]) =
	(len(arr) >= wires)? arr :
		hex_offsets(
			wires=wires,
			wirediam=wirediam,
			lev=lev+1,
			arr=concat(arr, hex_offset_ring(wirediam, lev=lev))
		);


// Returns a 3D object representing a bundle of wires that follow a given path,
// with the corners filleted to a given radius.  There are 17 base wire colors.
// If you have more than 17 wires, colors will get re-used.
// Arguments:
//   path:     The 3D polyline path that the wire bundle should follow.
//   wires:    The number of wires in the wiring bundle.
//   wirediam: The diameter of each wire in the bundle.
//   fillet:   The radius that the path corners will be filleted to.
//   wirenum:  The first wire's offset into the color table.
//   bezsteps: The corner fillets in the path will be converted into this number of segments.
// Usage:
//   wiring([[50,0,-50], [50,50,-50], [0,50,-50], [0,0,-50], [0,0,0]], fillet=10, wires=13);
module wiring(path, wires, wirediam=2, fillet=10, wirenum=0, bezsteps=12) {
	vect = path[1]-path[0];
	theta = atan2(vect[1], vect[0]);
	xydist = hypot(vect[1], vect[0]);
	phi = atan2(vect[2],xydist);
	colors = [
		[0.2, 0.2, 0.2], [1.0, 0.2, 0.2], [0.0, 0.8, 0.0], [1.0, 1.0, 0.2],
		[0.3, 0.3, 1.0], [1.0, 1.0, 1.0], [0.7, 0.5, 0.0], [0.5, 0.5, 0.5],
		[0.2, 0.9, 0.9], [0.8, 0.0, 0.8], [0.0, 0.6, 0.6], [1.0, 0.7, 0.7],
		[1.0, 0.5, 1.0], [0.5, 0.6, 0.0], [1.0, 0.7, 0.0], [0.7, 1.0, 0.5],
		[0.6, 0.6, 1.0],
	];
	offsets = hex_offsets(wires, wirediam);
	bezpath = fillet_path(path, fillet);
	poly = simplify3d_path(path3d(bezier_polyline(bezpath, bezsteps)));
	n = max(segs(wirediam), 8);
	r = wirediam/2;
	for (i = [0:wires-1]) {
		extpath = [for (a = [0:(360.0/n):360]) [r*cos(a), r*sin(a)] + offsets[i]];
		roty = matrix3_yrot(90-phi);
		rotz = matrix3_zrot(theta);
		color(colors[(i+wirenum)%len(colors)]) {
			extrude_2dpath_along_3dpath(extpath, poly);
		}
	}
}



// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
