//////////////////////////////////////////////////////////////////////
// Masks and models for NEMA stepper motors.
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
include <shapes.scad>
include <math.scad>


function nema_motor_width(size) = lookup(size, [
		[11.0, 28.2],
		[14.0, 35.2],
		[17.0, 42.3],
		[23.0, 57.0],
		[34.0, 86.0],
	]);

function nema_motor_plinth_height(size) = lookup(size, [
		[11.0, 1.5],
		[14.0, 2.0],
		[17.0, 2.0],
		[23.0, 1.6],
		[34.0, 2.03],
	]);

function nema_motor_plinth_diam(size) = lookup(size, [
		[11.0, 22.0],
		[14.0, 22.0],
		[17.0, 22.0],
		[23.0, 38.1],
		[34.0, 73.0],
	]);

function nema_motor_screw_spacing(size) = lookup(size, [
		[11.0, 23.11],
		[14.0, 26.0],
		[17.0, 30.99],
		[23.0, 47.14],
		[34.0, 69.6],
	]);

function nema_motor_screw_size(size) = lookup(size, [
		[11.0, 2.6],
		[14.0, 3.0],
		[17.0, 3.0],
		[23.0, 5.1],
		[34.0, 5.5],
	]);

function nema_motor_screw_depth(size) = lookup(size, [
		[11.0, 3.0],
		[14.0, 4.5],
		[17.0, 4.5],
		[23.0, 4.8],
		[34.0, 9.0],
	]);


module nema11_stepper(h=24, shaft=5, shaft_len=20)
{
	size = 11;
	motor_width = nema_motor_width(size);
	plinth_height = nema_motor_plinth_height(size);
	plinth_diam = nema_motor_plinth_diam(size);
	screw_spacing = nema_motor_screw_spacing(size);
	screw_size = nema_motor_screw_size(size);
	screw_depth = nema_motor_screw_depth(size);

	difference() {
		color([0.4, 0.4, 0.4]) {
			translate([0, 0, -h/2]) {
				rrect(size=[motor_width, motor_width, h], r=2, center=true);
			}
		}
		xspread(screw_spacing)
			yspread(screw_spacing)
				down(scred_depth/2-0.05)
					cylinder(r=screw_size/2, h=screw_depth, center=true, $fn=max(12,segs(screw_size/2)));
	}
	color([0.4, 0.4, 0.4])
		translate([0, 0, plinth_height/2])
			cylinder(h=plinth_height, r=plinth_diam/2, center=true);
	color("silver")
		translate([0, 0, shaft_len/2])
			cylinder(h=shaft_len, r=shaft/2, center=true, $fn=max(12,segs(shaft/2)));
}
//!nema11_stepper();



module nema14_stepper(h=24, shaft=5, shaft_len=24)
{
	size = 14;
	motor_width = nema_motor_width(size);
	plinth_height = nema_motor_plinth_height(size);
	plinth_diam = nema_motor_plinth_diam(size);
	screw_spacing = nema_motor_screw_spacing(size);
	screw_size = nema_motor_screw_size(size);
	screw_depth = nema_motor_screw_depth(size);

	difference() {
		color([0.4, 0.4, 0.4]) {
			translate([0, 0, -h/2]) {
				rrect(size=[motor_width, motor_width, h], r=2, center=true);
			}
		}
		xspread(screw_spacing)
			yspread(screw_spacing)
				down(screw_depth/2-0.05)
					cylinder(r=screw_size/2, h=screw_depth, center=true, $fn=max(12,segs(screw_size/2)));
	}
	color([0.4, 0.4, 0.4])
		translate([0, 0, plinth_height/2])
			cylinder(h=plinth_height, r=plinth_diam/2, center=true);
	color("silver")
		translate([0, 0, shaft_len/2])
			cylinder(h=shaft_len, r=shaft/2, center=true, $fn=max(12,segs(shaft/2)));
}
//!nema14_stepper();



module nema17_stepper(h=34, shaft=5, shaft_len=20)
{
	size = 17;
	motor_width = nema_motor_width(size);
	plinth_height = nema_motor_plinth_height(size);
	plinth_diam = nema_motor_plinth_diam(size);
	screw_spacing = nema_motor_screw_spacing(size);
	screw_size = nema_motor_screw_size(size);
	screw_depth = nema_motor_screw_depth(size);

	difference() {
		color([0.4, 0.4, 0.4]) {
			down(h/2) {
				rrect(size=[motor_width, motor_width, h], r=2, center=true);
			}
		}
		xspread(screw_spacing)
			yspread(screw_spacing)
				down(screw_depth/2-0.05)
					cylinder(r=screw_size/2, h=screw_depth, center=true, $fn=max(12,segs(screw_size/2)));
	}
	color([0.4, 0.4, 0.4])
		up(plinth_height/2)
			cylinder(h=plinth_height, r=plinth_diam/2, center=true);
	color([0.9, 0.9, 0.9]) {
		down(h-motor_width/12) {
			fwd(motor_width/2+motor_width/24/2-0.1) {
				difference() {
					cube(size=[motor_width/8, motor_width/24, motor_width/8], center=true);
					xrot(90) {
						cylinder(d=motor_width/8-2, h=motor_width/6, center=true, $fn=12);
					}
				}
			}
		}
	}
	color("silver") {
		difference() {
			cylinder(h=shaft_len, r=shaft/2, $fn=max(12,segs(shaft/2)));
			up(shaft_len/2+1) {
				right(shaft_len/2+shaft/2-0.5) {
					cube(shaft_len, center=true);
				}
			}
		}
	}
}
//!nema17_stepper();



module nema23_stepper(h=50, shaft=6.35, shaft_len=25)
{
	size = 23;
	motor_width = nema_motor_width(size);
	plinth_height = nema_motor_plinth_height(size);
	plinth_diam = nema_motor_plinth_diam(size);
	screw_spacing = nema_motor_screw_spacing(size);
	screw_size = nema_motor_screw_size(size);
	screw_depth = nema_motor_screw_depth(size);

	screw_inset = motor_width - screw_spacing + 1;
	difference() {
		union() {
			color([0.4, 0.4, 0.4]) {
				translate([0, 0, -h/2]) {
					rrect(size=[motor_width, motor_width, h], r=2, center=true);
				}
			}
			color([0.4, 0.4, 0.4])
				translate([0, 0, plinth_height/2])
					cylinder(h=plinth_height, r=plinth_diam/2, center=true);
			color("silver")
				translate([0, 0, shaft_len/2])
					cylinder(h=shaft_len, r=shaft/2, center=true, $fn=max(12,segs(shaft/2)));
		}
		xspread(screw_spacing) {
			yspread(screw_spacing) {
				down(screw_depth/2)
					cylinder(r=screw_size/2, h=screw_depth+2, center=true, $fn=max(12,segs(screw_size/2)));
				down(screw_depth+h/2)
					cube(size=[screw_inset, screw_inset, h], center=true);
			}
		}
	}
}
//!nema23_stepper();



module nema34_stepper(h=75, shaft=12.7, shaft_len=32)
{
	size = 34;
	motor_width = nema_motor_width(size);
	plinth_height = nema_motor_plinth_height(size);
	plinth_diam = nema_motor_plinth_diam(size);
	screw_spacing = nema_motor_screw_spacing(size);
	screw_size = nema_motor_screw_size(size);
	screw_depth = nema_motor_screw_depth(size);

	screw_inset = motor_width - screw_spacing + 1;
	difference() {
		union() {
			color([0.4, 0.4, 0.4]) {
				translate([0, 0, -h/2]) {
					rrect(size=[motor_width, motor_width, h], r=2, center=true);
				}
			}
			color([0.4, 0.4, 0.4])
				translate([0, 0, plinth_height/2])
					cylinder(h=plinth_height, r=plinth_diam/2, center=true);
			color("silver")
				translate([0, 0, shaft_len/2])
					cylinder(h=shaft_len, r=shaft/2, center=true, $fn=max(24,segs(shaft/2)));
		}
		xspread(screw_spacing) {
			yspread(screw_spacing) {
				down(screw_depth/2)
					cylinder(r=screw_size/2, h=screw_depth+2, center=true, $fn=max(12,segs(screw_size/2)));
				down(screw_depth+h/2)
					cube(size=[screw_inset, screw_inset, h], center=true);
			}
		}
	}
}
//!nema34_stepper();



module nema17_mount_holes(depth=5, l=5, slop=printer_slop)
{
	size = 17;
	plinth_diam = nema_motor_plinth_diam(size)+slop;
	screw_spacing = nema_motor_screw_spacing(size);
	screw_size = nema_motor_screw_size(size)+slop;

	union() {
		xspread(screw_spacing) {
			yspread(screw_spacing) {
				if (l>0) {
					union() {
						yspread(l) cylinder(h=depth, d=screw_size, center=true, $fn=max(8,segs(screw_size/2)));
						cube([screw_size, l, depth], center=true);
					}
				} else {
					cylinder(h=depth, d=screw_size, center=true, $fn=max(8,segs(screw_size/2)));
				}
			}
		}
	}
	if (l>0) {
		union () {
			yspread(l) cylinder(h=depth, d=plinth_diam, center=true);
			cube([plinth_diam, l, depth], center=true);
		}
	} else {
		cylinder(h=depth, d=plinth_diam, center=true);
	}
}
//!nema17_mount_holes(depth=5, l=5);



// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
