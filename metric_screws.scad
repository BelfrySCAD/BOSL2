//////////////////////////////////////////////////////////////////////
// Screws, Bolts, and Nuts.
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


use <transforms.scad>
use <shapes.scad>
use <threading.scad>
use <phillips_drive.scad>
use <math.scad>


function get_metric_bolt_head_size(size) = lookup(size, [
		[ 3.0,  5.5],
		[ 4.0,  7.0],
		[ 5.0,  8.0],
		[ 6.0, 10.0],
		[ 7.0, 11.0],
		[ 8.0, 13.0],
		[10.0, 17.0],
		[12.0, 19.0],
		[14.0, 22.0],
		[16.0, 24.0],
		[18.0, 27.0],
		[20.0, 30.0],
		[24.0, 36.0],
		[30.0, 46.0],
		[36.0, 55.0],
		[42.0, 65.0],
		[48.0, 75.0],
		[56.0, 85.0],
		[64.0, 95.0]
	]);


function get_metric_bolt_head_height(size) = lookup(size, [
		[ 1.6,  1.23],
		[ 2.0,  1.53],
		[ 2.5,  1.83],
		[ 3.0,  2.13],
		[ 4.0,  2.93],
		[ 5.0,  3.65],
		[ 6.0,  4.15],
		[ 8.0,  5.45],
		[10.0,  6.58],
		[12.0,  7.68],
		[14.0,  8.98],
		[16.0, 10.18],
		[20.0, 12.72],
		[24.0, 15.35],
		[30.0, 19.12],
		[36.0, 22.92],
		[42.0, 26.42],
		[48.0, 30.42],
		[56.0, 35.50],
		[64.0, 40.50]
	]);


function get_metric_socket_cap_diam(size) = lookup(size, [
		[ 1.6,  3.0],
		[ 2.0,  3.8],
		[ 2.5,  4.5],
		[ 3.0,  5.5],
		[ 4.0,  7.0],
		[ 5.0,  8.5],
		[ 6.0, 10.0],
		[ 8.0, 13.0],
		[10.0, 16.0],
		[12.0, 18.0],
		[14.0, 21.0],
		[16.0, 24.0],
		[18.0, 27.0],
		[20.0, 30.0],
		[22.0, 33.0],
		[24.0, 36.0],
		[27.0, 40.0],
		[30.0, 45.0],
		[33.0, 50.0],
		[36.0, 54.0],
		[42.0, 63.0],
		[48.0, 72.0],
		[56.0, 84.0],
		[64.0, 96.0]
	]);


function get_metric_socket_cap_height(size) = lookup(size, [
		[ 1.6,  1.7],
		[ 2.0,  2.0],
		[ 2.5,  2.5],
		[ 3.0,  3.0],
		[ 4.0,  4.0],
		[ 5.0,  5.0],
		[ 6.0,  6.0],
		[ 8.0,  8.0],
		[10.0, 10.0],
		[12.0, 12.0],
		[14.0, 14.0],
		[16.0, 16.0],
		[18.0, 18.0],
		[20.0, 20.0],
		[22.0, 22.0],
		[24.0, 24.0],
		[27.0, 27.0],
		[30.0, 30.0],
		[33.0, 33.0],
		[36.0, 36.0],
		[42.0, 42.0],
		[48.0, 48.0],
		[56.0, 56.0],
		[64.0, 64.0]
	]);


function get_metric_socket_cap_socket_size(size) = lookup(size, [
		[ 1.6,  1.5],
		[ 2.0,  1.5],
		[ 2.5,  2.0],
		[ 3.0,  2.5],
		[ 4.0,  3.0],
		[ 5.0,  4.0],
		[ 6.0,  5.0],
		[ 8.0,  6.0],
		[10.0,  8.0],
		[12.0, 10.0],
		[14.0, 12.0],
		[16.0, 14.0],
		[18.0, 14.0],
		[20.0, 17.0],
		[22.0, 17.0],
		[24.0, 19.0],
		[27.0, 19.0],
		[30.0, 22.0],
		[33.0, 24.0],
		[36.0, 27.0],
		[42.0, 32.0],
		[48.0, 36.0],
		[56.0, 41.0],
		[64.0, 46.0]
	]);


function get_metric_socket_cap_socket_depth(size) = lookup(size, [
		[ 1.6,  0.7],
		[ 2.0,  1.0],
		[ 2.5,  1.1],
		[ 3.0,  1.3],
		[ 4.0,  2.0],
		[ 5.0,  2.5],
		[ 6.0,  3.0],
		[ 8.0,  4.0],
		[10.0,  5.0],
		[12.0,  6.0],
		[14.0,  7.0],
		[16.0,  8.0],
		[18.0,  9.0],
		[20.0, 10.0],
		[22.0, 11.0],
		[24.0, 12.0],
		[27.0, 13.5],
		[30.0, 15.5],
		[33.0, 18.0],
		[36.0, 19.0],
		[42.0, 24.0],
		[48.0, 28.0],
		[56.0, 34.0],
		[64.0, 38.0]
	]);


function get_metric_iso_coarse_thread_pitch(size) = lookup(size, [
		[ 1.6, 0.35],
		[ 2.0, 0.40],
		[ 2.5, 0.45],
		[ 3.0, 0.50],
		[ 4.0, 0.70],
		[ 5.0, 0.80],
		[ 6.0, 1.00],
		[ 7.0, 1.00],
		[ 8.0, 1.25],
		[10.0, 1.50],
		[12.0, 1.75],
		[14.0, 2.00],
		[16.0, 2.00],
		[18.0, 2.50],
		[20.0, 2.50],
		[22.0, 2.50],
		[24.0, 3.00],
		[27.0, 3.00],
		[30.0, 3.50],
		[33.0, 3.50],
		[36.0, 4.00],
		[39.0, 4.00],
		[42.0, 4.50],
		[45.0, 4.50],
		[48.0, 5.00],
		[56.0, 5.50],
		[64.0, 6.00]
	]);


function get_metric_iso_fine_thread_pitch(size) = lookup(size, [
		[ 1.6, 0.35],
		[ 2.0, 0.40],
		[ 2.5, 0.45],
		[ 3.0, 0.50],
		[ 4.0, 0.70],
		[ 5.0, 0.80],
		[ 6.0, 1.00],
		[ 7.0, 1.00],
		[ 8.0, 1.00],
		[10.0, 1.25],
		[12.0, 1.50],
		[14.0, 1.50],
		[16.0, 2.00],
		[18.0, 2.50],
		[20.0, 2.50],
		[22.0, 2.50],
		[24.0, 3.00],
		[27.0, 3.00],
		[30.0, 3.50],
		[33.0, 3.50],
		[36.0, 4.00],
		[39.0, 4.00],
		[42.0, 4.50],
		[45.0, 4.50],
		[48.0, 5.00],
		[56.0, 5.50],
		[64.0, 6.00]
	]);


function get_metric_iso_superfine_thread_pitch(size) = lookup(size, [
		[ 1.6, 0.35],
		[ 2.0, 0.40],
		[ 2.5, 0.45],
		[ 3.0, 0.50],
		[ 4.0, 0.70],
		[ 5.0, 0.80],
		[ 6.0, 1.00],
		[ 7.0, 1.00],
		[ 8.0, 1.00],
		[10.0, 1.00],
		[12.0, 1.25],
		[14.0, 1.50],
		[16.0, 2.00],
		[18.0, 2.50],
		[20.0, 2.50],
		[22.0, 2.50],
		[24.0, 3.00],
		[27.0, 3.00],
		[30.0, 3.50],
		[33.0, 3.50],
		[36.0, 4.00],
		[39.0, 4.00],
		[42.0, 4.50],
		[45.0, 4.50],
		[48.0, 5.00],
		[56.0, 5.50],
		[64.0, 6.00]
	]);


function get_metric_jis_thread_pitch(size) = lookup(size, [
		[ 2.0, 0.40],
		[ 2.5, 0.45],
		[ 3.0, 0.50],
		[ 4.0, 0.70],
		[ 5.0, 0.80],
		[ 6.0, 1.00],
		[ 7.0, 1.00],
		[ 8.0, 1.25],
		[10.0, 1.25],
		[12.0, 1.25],
		[14.0, 1.50],
		[16.0, 1.50],
		[18.0, 1.50],
		[20.0, 1.50]
	]);


function get_metric_nut_size(size) = lookup(size, [
		[ 2.0,  4.0],
		[ 2.5,  5.0],
		[ 3.0,  5.5],
		[ 4.0,  7.0],
		[ 5.0,  8.0],
		[ 6.0, 10.0],
		[ 7.0, 11.0],
		[ 8.0, 13.0],
		[10.0, 17.0],
		[12.0, 19.0],
		[14.0, 22.0],
		[16.0, 24.0],
		[18.0, 27.0],
		[20.0, 30.0]
	]);


function get_metric_nut_thickness(size) = lookup(size, [
		[ 1.6,  1.3],
		[ 2.0,  1.6],
		[ 2.5,  2.0],
		[ 3.0,  2.4],
		[ 4.0,  3.2],
		[ 5.0,  4.0],
		[ 6.0,  5.0],
		[ 7.0,  5.5],
		[ 8.0,  6.5],
		[10.0,  8.0],
		[12.0, 10.0],
		[14.0, 11.0],
		[16.0, 13.0],
		[18.0, 15.0],
		[20.0, 16.0],
		[24.0, 21.5],
		[30.0, 25.6],
		[36.0, 31.0],
		[42.0, 34.0],
		[48.0, 38.0],
		[56.0, 45.0],
		[64.0, 51.0]
	]);


// Makes a very simple screw model, useful for making screwholes.
//   screwsize = diameter of threaded part of screw.
//   screwlen = length of threaded part of screw.
//   headsize = diameter of the screw head.
//   headlen = length of the screw head.
//   countersunk = If true, center from cap's top instead of it's bottom.
// Example:
//   screw(screwsize=3,screwlen=10,headsize=6,headlen=3,countersunk=true);
module screw(
	screwsize=3,
	screwlen=10,
	headsize=6,
	headlen=3,
	pitch=undef,
	countersunk=false
) {
	sides = max(12, segs(screwsize/2));
	down(countersunk? headlen-0.01 : 0) {
		down(screwlen/2) {
			if (pitch == undef) {
				cylinder(r=screwsize/2, h=screwlen+0.05, center=true, $fn=sides);
			} else {
				threaded_rod(d=screwsize, l=screwlen+0.05, pitch=pitch, $fn=sides);
			}
		}
		up(headlen/2) cylinder(r=headsize/2, h=headlen, center=true, $fn=sides*2);
	}
}


// Makes a standard metric screw model.
//   size = diameter of threaded part of screw.
//   headtype = One of "hex", "pan", "button", "round", "countersunk", "oval", "socket".  Default: "socket"
//   l = length of screw, except for the head.
//   shank = Length of unthreaded portion of the shaft.
//   pitch = If given, render threads of the given pitch.  If 0, then no threads.  Overrides coarse argument.
//   details = If true model should be rendered with extra details.  (Default: false)
//   coarse = If true, make coarse threads instead of fine threads.  Default = true
//   flange = radius of flange beyond the head.  Default = 0 (no flange)
//   phillips = If given, the size of the phillips drive hole to add.  (ie: "#1", "#2", or "#3")
// Examples:
//   metric_bolt(headtype="pan", size=10, l=15, details=true, phillips="#2");
//   metric_bolt(headtype="countersunk", size=10, l=15, details=true, phillips="#2");
//   metric_bolt(headtype="socket", size=10, l=15, flange=4, coarse=false, shank=5, details=true);
//   metric_bolt(headtype="hex", size=10, l=15, flange=4, coarse=false, shank=5, details=true, phillips="#2");
module metric_bolt(
	headtype="socket",
	size=3,
	l=12,
	shank=0,
	pitch=undef,
	details=false,
	coarse=true,
	phillips=undef,
	flange=0
) {
	D = headtype != "hex"?
		get_metric_socket_cap_diam(size) :
		get_metric_bolt_head_size(size);
	H = headtype == "socket"?
		get_metric_socket_cap_height(size) :
		get_metric_bolt_head_height(size);
	P = coarse?
		(pitch==undef? get_metric_iso_coarse_thread_pitch(size) : pitch) :
		(pitch==undef? get_metric_iso_fine_thread_pitch(size) : pitch);
	tlen = l - min(l, shank);
	sides = max(12, segs(size/2));
	tcirc = D/cos(30);
	bevtop = (tcirc-D)/2;
	bevbot = P/2;

	color("silver")
	down(headtype == "countersunk" || headtype == "oval"? (D-size)/2 : 0) {
		difference() {
			union() {
				// Head
				if (headtype == "hex") {
					difference() {
						cylinder(d=tcirc, h=H, center=false, $fn=6);

						// Bevel hex nut top
						if (details) {
							up(H-bevtop) {
								difference() {
									upcube([tcirc+1, tcirc+1, bevtop+0.5]);
									down(0.01) cylinder(d1=tcirc, d2=tcirc-bevtop*2, h=bevtop+0.02, center=false);
								}
							}
						}
					}
				} else if (headtype == "socket") {
					sockw = get_metric_socket_cap_socket_size(size);
					sockd = get_metric_socket_cap_socket_depth(size);
					difference() {
						cylinder(d=D, h=H, center=false);
						up(H-sockd) cylinder(h=sockd+0.1, d=sockw/cos(30), center=false, $fn=6);
						if (details) {
							kcnt = 36;
							zring(n=kcnt, r=D/2) up(H/3) upcube([PI*D/kcnt/2, PI*D/kcnt/2, H]);
						}
					}
				} else if (headtype == "pan") {
					top_half() rcylinder(h=H*0.75*2, d=D, fillet=H/2, center=true);
				} else if (headtype == "round") {
					top_half() zscale(H*0.75/D*2) sphere(d=D);
				} else if (headtype == "button") {
					up(H*0.75/3) top_half() zscale(H*0.75*2/3/D*2) sphere(d=D);
					cylinder(d=D, h=H*0.75/3+0.01, center=false);
				} else if (headtype == "countersunk") {
					cylinder(h=(D-size)/2, d1=size, d2=D, center=false);
				} else if (headtype == "oval") {
					up((D-size)/2) top_half() zscale(0.333) sphere(d=D);
					cylinder(h=(D-size)/2, d1=size, d2=D, center=false);
				}

				// Flange
				if (flange>0) {
					up(headtype == "countersunk" || headtype == "oval"? (D-size)/2 : 0) {
						cylinder(d=D+flange, h=H/8, center=false);
						up(H/8) cylinder(d1=D+flange, d2=D, h=H/8, center=false);
					}
				}

				// Unthreaded Shank
				if (tlen < l) {
					down(l-tlen) cylinder(d=size, h=l-tlen+0.05, center=false, $fn=sides);
				}

				// Threads
				down(l) {
					difference() {
						up(tlen/2+0.05) {
							if (tlen > 0) {
								if (P > 0) {
									threaded_rod(d=size, l=tlen+0.05, pitch=P, $fn=sides);
								} else {
									cylinder(d=size, h=tlen+0.05, $fn=sides, center=true);
								}
							}
						}

						// Bevel bottom end of threads
						if (details) {
							difference() {
								down(0.5) upcube([size+1, size+1, bevbot+0.5]);
								cylinder(d1=size-bevbot*2, d2=size, h=bevbot+0.01, center=false);
							}
						}
					}
				}
			}

			// Phillips drive hole
			if (headtype != "socket" && phillips != undef) {
				down(headtype != "hex"? H/6 : 0) {
					phillips_drive(size=phillips, shaft=D);
				}
			}
		}
	}
}


// Makes a model of a standard nut for a standard metric screw.
//   size = standard metric screw size in mm. (Default: 3)
//   hole = include the hole in the nut.  (Default: true)
//   pitch = pitch of threads in the hole.  No threads if not given.
//   flange = radius of flange beyond the head.  Default = 0 (no flange)
//   details = true if model should be rendered with extra details.  (Default: false)
//   center = If true, center the nut at the origin, otherwise on top of the XY plane.  Default = false.
// Example:
//   metric_nut(size=6, hole=false);
//   metric_nut(size=8, hole=true);
//   metric_nut(size=6, hole=true, pitch=1, details=true, center=true);
//   metric_nut(size=8, hole=true, pitch=1, details=true, flange=3, center=true);
module metric_nut(
	size=3,
	hole=true,
	pitch=undef,
	details=false,
	flange=0,
	center=false
) {
	H = get_metric_nut_thickness(size);
	D = get_metric_nut_size(size);
	boltfn = max(12, segs(size/2));
	nutfn = max(12, segs(D/2));
	dcirc = D/cos(30);
	bevtop = (dcirc - D)/2;
	offset = (center == true)? 0 : H/2;
	color("silver")
	up(offset) {
		difference() {
			union() {
				difference() {
					cylinder(d=dcirc, h=H, center=true, $fn=6);
					if (details) {
						up(H/2-bevtop) {
							difference() {
								upcube([dcirc+1, dcirc+1, bevtop+0.5]);
								down(0.01) cylinder(d1=dcirc, d2=dcirc-bevtop*2, h=bevtop+0.02, center=false, $fn=nutfn);
							}
						}
						if (flange == 0) {
							down(H/2) {
								difference() {
									down(0.5) upcube([dcirc+1, dcirc+1, bevtop+0.5]);
									down(0.01) cylinder(d1=dcirc-bevtop*2, d2=dcirc, h=bevtop+0.02, center=false, $fn=nutfn);
								}
							}
						}
					}
				}
				if (flange>0) {
					down(H/2) {
						cylinder(d=D+flange, h=H/8, center=false);
						up(H/8) cylinder(d1=D+flange, d2=D, h=H/8, center=false);
					}
				}
			}
			if (hole == true) {
				if (pitch == undef) {
					cylinder(r=size/2, h=H+0.5, center=true, $fn=boltfn);
				} else {
					threaded_rod(d=size, l=H+0.5, pitch=pitch, $fn=boltfn);
				}
			}
		}
	}
}


// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
