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


function _trpzd_thread_pt(thread, threads, start, starts, astep, asteps, part, parts) =
	astep + asteps * (thread + threads * (part + parts * start));


// Constructs a generic trapezoidal threaded screw rod.  This method makes
// much smoother threads than the naive linear_extrude method.
// For metric trapezoidal threads, use thread_angle=15 and thread_depth=pitch/2.
// For ACME threads, use thread_angle=14.5 and thread_depth=pitch/2.
// For square threads, use thread_angle=0 and thread_depth=pitch/2.
// For normal screw threads, use thread_angle=30 and thread_depth=pitch*3*sqrt(3)/8.
//   d = Outer diameter of threaded rod.
//   l = Length of threaded rod.
//   pitch = Length between threads.
//   thread_depth = Depth of the threads.  Default=pitch/2
//   thread_angle = The pressure angle profile angle of the threads.  Default = 14.5 degree ACME profile.
//   left_handed = If true, create left-handed threads.  Default = false
//   starts = The number of lead starts.  Default = 1
// Examples:
//   trapezoidal_threaded_rod(d=10, l=100, pitch=2, thread_angle=15, $fn=32);
//   trapezoidal_threaded_rod(d=3/8*25.4, l=20, pitch=1/8*25.4, thread_angle=29, $fn=32);
//   trapezoidal_threaded_rod(d=60, l=16, pitch=8, thread_depth=3, thread_angle=45, left_handed=true, $fa=2, $fs=2);
//   trapezoidal_threaded_rod(d=60, l=16, pitch=8, thread_depth=3, thread_angle=45, left_handed=true, starts=4, $fa=2, $fs=2);
//   trapezoidal_threaded_rod(d=16, l=40, pitch=2, thread_angle=30);
//   trapezoidal_threaded_rod(d=10, l=40, pitch=3, thread_angle=15, left_handed=true, starts=3, $fn=36);
//   trapezoidal_threaded_rod(d=50, l=50, pitch=8, thread_angle=30, starts=4, $fa=2, $fs=2);
//   trapezoidal_threaded_rod(d=25, l=100, pitch=10, thread_depth=8/3, thread_angle=50, starts=4, center=false, $fa=2, $fs=2);
module trapezoidal_threaded_rod(
	d=10,
	l=100,
	pitch=2,
	thread_angle=15,
	thread_depth=undef,
	left_handed=false,
	center=true,
	starts=1
) {
	astep = 360 / quantup(segs(d/2), starts);
	asteps = ceil(360/astep);
	threads = ceil(l/pitch/starts)+(starts<4?4-starts:1);
	depth = min((thread_depth==undef? pitch/2 : thread_depth), pitch/2/tan(thread_angle));
	pa_delta = min(pitch/4-0.01,depth*tan(thread_angle)/2);
	dir = left_handed? -1 : 1;
	r1 = max(0, d/2-depth);
	r2 = d/2;
	rads = [r1, r2, r2, r1];
	delta_zs = [
		-pitch/4-pa_delta,
		-pitch/4+pa_delta,
		pitch/4-pa_delta,
		pitch/4+pa_delta
	];
	parts = len(delta_zs);
	poly_points = concat(
		[
			for (
				start = [0 : starts-1],
				part = [0 : parts-1],
				thread = [0 : threads-1],
				astep = [0 : asteps-1]
			) let (
				r = rads[part],
				dz = delta_zs[part],
				a = astep / asteps,
				c = cos(360 * (a * dir + start/starts)),
				s = sin(360 * (a * dir + start/starts)),
				z = (thread + a - threads/2) * starts * pitch
			) [r*c, r*s, z+dz]
		],
		[[0, 0, -threads*pitch*starts/2-pitch/4], [0, 0, threads*pitch*starts/2+pitch/4]]
	);
	point_count = len(poly_points);
	poly_faces = concat(
		// Thread surfaces
		[
			for (
				start = [0 : starts-1],
				part = [0 : parts-2],
				thread = [0 : threads-1],
				astep = [0 : asteps-1],
				trinum = [0 : 1]
			) let (
				n = ((thread * asteps + astep) * starts + start) * parts,
				p0 = _trpzd_thread_pt(thread, threads, start, starts, astep, asteps, part, parts),
				p1 = _trpzd_thread_pt(thread, threads, start, starts, astep, asteps, part+1, parts),
				p2 = _trpzd_thread_pt(thread, threads, start, starts, astep+1, asteps, part, parts),
				p3 = _trpzd_thread_pt(thread, threads, start, starts, astep+1, asteps, part+1, parts),
				tri = trinum==0? [p0, p1, p3] : [p0, p3, p2],
				otri = left_handed? [tri[0], tri[2], tri[1]] : tri
			)
			if (!(thread == threads-1 && astep == asteps-1)) otri
		],
		// Thread trough bottom
		[
			for (
				start = [0 : starts-1],
				thread = [0 : threads-1],
				astep = [0 : asteps-1],
				trinum = [0 : 1]
			) let (
				p0 = _trpzd_thread_pt(thread, threads, start, starts, astep, asteps, parts-1, parts),
				p1 = _trpzd_thread_pt(thread, threads, (start+(left_handed?1:starts-1))%starts, starts, astep+asteps/starts, asteps, 0, parts),
				p2 = p0 + 1,
				p3 = p1 + 1,
				tri = trinum==0? [p0, p1, p3] : [p0, p3, p2],
				otri = left_handed? [tri[0], tri[2], tri[1]] : tri
			)
			if (
				!(thread >= threads-1 && astep > asteps-asteps/starts-2) &&
				!(thread >= threads-2 && starts == 1 && astep >= asteps-1)
			) otri
		],
		// top and bottom thread endcap
		[
			for (
				start=[0:starts-1],
				part=[1:parts-2],
				is_top=[0:1]
			) let (
				astep = is_top? asteps-1 : 0,
				thread = is_top? threads-1 : 0,
				p0 = _trpzd_thread_pt(thread, threads, start, starts, astep, asteps, 0, parts),
				p1 = _trpzd_thread_pt(thread, threads, start, starts, astep, asteps, part, parts),
				p2 = _trpzd_thread_pt(thread, threads, start, starts, astep, asteps, part+1, parts),
				tri = is_top? [p0, p1, p2] : [p0, p2, p1],
				otri = left_handed? [tri[0], tri[2], tri[1]] : tri
			) otri
		],
		// body side triangles
		[
			for (
				start=[0:starts-1],
				is_top=[false,true],
				trinum=[0,1]
			) let (
				astep = is_top? asteps-1 : 0,
				thread = is_top? threads-1 : 0,
				ostart = (is_top != left_handed? (start+1) : (start+starts-1))%starts,
				ostep = is_top? astep-asteps/starts : astep+asteps/starts,
				oparts = is_top? parts-1 : 0,
				p0 = is_top? point_count-1 : point_count-2,
				p1 = _trpzd_thread_pt(thread, threads, start, starts, astep, asteps, 0, parts),
				p2 = _trpzd_thread_pt(thread, threads, start, starts, astep, asteps, parts-1, parts),
				p3 = _trpzd_thread_pt(thread, threads, ostart, starts, ostep, asteps, oparts, parts),
				tri = trinum==0?
					(is_top? [p0, p1, p2] : [p0, p2, p1]) :
					(is_top? [p0, p3, p1] : [p0, p3, p2]),
				otri = left_handed? [tri[0], tri[2], tri[1]] : tri
			) otri
		],
		// Caps
		[
			for (
				start = [0 : starts-1],
				astep = [0 : asteps/starts-1],
				is_top = [0:1]
			) let (
				thread = is_top? threads-1 : 0,
				part = is_top? parts-1 : 0,
				ostep = is_top? asteps-astep-2 : astep,
				p0 = is_top? point_count-1 : point_count-2,
				p1 = _trpzd_thread_pt(thread, threads, start, starts, ostep, asteps, part, parts),
				p2 = _trpzd_thread_pt(thread, threads, start, starts, ostep+1, asteps, part, parts),
				tri = is_top? [p0, p2, p1] : [p0, p1, p2],
				otri = left_handed? [tri[0], tri[2], tri[1]] : tri
			) otri
		]
	);
	up(center? 0 : l/2) {
		intersection() {
			polyhedron(points=poly_points, faces=poly_faces, convexity=threads*starts*2);
			cube([d+1, d+1, l], center=true);
		}
	}
}


// Constructs a hex nut for a threaded screw rod.  This method makes
// much smoother threads than the naive linear_extrude method.
// For metric screw threads, use thread_angle=30 and leave out thread_depth argument.
// For SAE screw threads, use thread_angle=30 and leave out thread_depth argument.
// For metric trapezoidal threads, use thread_angle=15 and thread_depth=pitch/2.
// For ACME threads, use thread_angle=14.5 and thread_depth=pitch/2.
// For square threads, use thread_angle=0 and thread_depth=pitch/2.
//   od = diameter of the nut.
//   id = diameter of threaded rod to screw onto.
//   h = height/thickness of nut.
//   pitch = Length between threads.
//   thread_depth = Depth of the threads.  Default=pitch/2.
//   thread_angle = The pressure angle profile angle of the threads.  Default = 14.5 degree ACME profile.
//   left_handed = if true, create left-handed threads.  Default = false
//   starts = The number of lead starts.  Default = 1
//   slop = printer slop calibration to allow for tight fitting of parts.  default=0.2
// Examples:
//   trapezoidal_threaded_nut(od=16, id=8, h=8, pitch=2, slop=0.2);
//   trapezoidal_threaded_nut(od=17.4, id=10, h=10, pitch=2, slop=0.2, left_handed=true);
module trapezoidal_threaded_nut(
	od=17.4,
	id=10,
	h=10,
	pitch=2,
	thread_depth=undef,
	thread_angle=15,
	left_handed=false,
	starts=1,
	slop=0.2
) {
	difference() {
		cylinder(r=od/2/cos(30), h=h, center=true, $fn=6);
		zspread(slop, n=slop>0?2:1) {
			trapezoidal_threaded_rod(
				d=id+2*slop,
				l=h+0.1,
				pitch=pitch,
				thread_depth=thread_depth,
				thread_angle=thread_angle,
				left_handed=left_handed,
				starts=starts
			);
		}
	}
}



// Constructs a standard metric or UTS threaded screw rod.  This method
// makes much smoother threads than the naive linear_extrude method.
//   d = Outer diameter of threaded rod.
//   l = length of threaded rod.
//   pitch = Length between threads.
//   left_handed = if true, create left-handed threads.  Default = false
// Examples:
//   threaded_rod(d=16, l=40, pitch=2, thread_angle=30);
module threaded_rod(d=10, l=100, pitch=2, left_handed=false) {
	trapezoidal_threaded_rod(d=d, l=l, pitch=pitch, thread_depth=pitch*3*sqrt(3)/8, thread_angle=30, left_handed=left_handed);
}



// Constructs a hex nut for a metric or UTS threaded screw rod.  This method
// makes much smoother threads than the naive linear_extrude method.
//   od = diameter of the nut.
//   id = diameter of threaded rod to screw onto.
//   h = height/thickness of nut.
//   pitch = Length between threads.
//   left_handed = if true, create left-handed threads.  Default = false
//   slop = printer slop calibration to allow for tight fitting of parts.  default=0.2
// Examples:
//   threaded_nut(od=16, id=8, h=8, pitch=2, slop=0.2);
module threaded_nut(od=17.4, id=10.5, h=10, pitch=3.175, left_handed=false, slop=0.2) {
	trapezoidal_threaded_nut(od=od, id=id, h=h, pitch=pitch, thread_angle=30, thread_depth=pitch*3*sqrt(3)/8, left_handed=left_handed, slop=slop);
}



// Constructs a metric trapezoidal threaded screw rod.  This method makes much
// smoother threads than the naive linear_extrude method.
//   d = Outer diameter of threaded rod.
//   l = length of threaded rod.
//   pitch = Length between threads.
//   left_handed = if true, create left-handed threads.  Default = false
//   starts = The number of lead starts.  Default = 1
// Examples:
//   metric_trapezoidal_threaded_rod(d=16, l=40, pitch=2);
//   metric_trapezoidal_threaded_rod(d=10, l=40, pitch=2, left_handed=true, $fn=32);
module metric_trapezoidal_threaded_rod(d=10, l=100, pitch=2, left_handed=false, starts=1) {
	trapezoidal_threaded_rod(d=d, l=l, pitch=pitch, thread_angle=15, left_handed=left_handed, starts=starts);
}



// Constructs a hex nut for a metric trapezoidal threaded screw rod.  This method
// makes much smoother threads than the naive linear_extrude method.
//   od = diameter of the nut.
//   id = diameter of threaded rod to screw onto.
//   h = height/thickness of nut.
//   pitch = Length between threads.
//   left_handed = if true, create left-handed threads.  Default = false
//   starts = The number of lead starts.  Default = 1
//   slop = printer slop calibration to allow for tight fitting of parts.  default=0.2
// Examples:
//   metric_trapezoidal_threaded_nut(od=16, id=8, h=8, pitch=2, slop=0.2);
module metric_trapezoidal_threaded_nut(od=17.4, id=10.5, h=10, pitch=3.175, left_handed=false, starts=1, slop=0.2) {
	trapezoidal_threaded_nut(od=od, id=id, h=h, pitch=pitch, thread_angle=15, left_handed=left_handed, starts=starts, slop=slop);
}



// Constructs an ACME trapezoidal threaded screw rod.  This method makes
// much smoother threads than the naive linear_extrude method.
//   d = Outer diameter of threaded rod.
//   l = length of threaded rod.
//   pitch = Length between threads.
//   thread_depth = Depth of the threads.  Default = pitch/2
//   thread_angle = The pressure angle profile angle of the threads.  Default = 14.5 degrees
//   starts = The number of lead starts.  Default = 1
//   left_handed = if true, create left-handed threads.  Default = false
// Examples:
//   acme_threaded_rod(d=3/8*25.4, l=20, pitch=1/8*25.4, $fn=32);
module acme_threaded_rod(d=10, l=100, pitch=2, thread_angle=14.5, thread_depth=undef, starts=1, left_handed=false) {
	trapezoidal_threaded_rod(
		d=d, l=l, pitch=pitch,
		thread_angle=thread_angle,
		thread_depth=thread_depth,
		starts=starts,
		left_handed=left_handed
	);
}



// Constructs a hex nut for an ACME threaded screw rod.  This method makes
// much smoother threads than the naive linear_extrude method.
//   od = diameter of the nut.
//   id = diameter of threaded rod to screw onto.
//   h = height/thickness of nut.
//   pitch = Length between threads.
//   thread_depth = Depth of the threads.  Default=pitch/2
//   thread_angle = The pressure angle profile angle of the threads.  Default = 14.5 degree ACME profile.
//   left_handed = if true, create left-handed threads.  Default = false
//   slop = printer slop calibration to allow for tight fitting of parts.  default=0.2
// Examples:
//   acme_threaded_nut(od=16, id=3/8*25.4, h=8, pitch=1/8*25.4, slop=0.2);
module acme_threaded_nut(od, id, h, pitch, thread_angle=14.5, thread_depth=undef, left_handed=false, slop=0.2) {
	trapezoidal_threaded_nut(
		od=od, id=id, h=h, pitch=pitch,
		thread_depth=thread_depth,
		thread_angle=thread_angle,
		left_handed=left_handed,
		slop=slop
	);
}



// Constructs a square profile threaded screw rod.  This method makes
// much smoother threads than the naive linear_extrude method.
//   d = Outer diameter of threaded rod.
//   l = length of threaded rod.
//   pitch = Length between threads.
//   left_handed = if true, create left-handed threads.  Default = false
//   starts = The number of lead starts.  Default = 1
// Examples:
//   square_threaded_rod(d=16, l=40, pitch=2, thread_angle=30);
module square_threaded_rod(d=10, l=100, pitch=2, left_handed=false, starts=1) {
	trapezoidal_threaded_rod(d=d, l=l, pitch=pitch, thread_angle=0, left_handed=left_handed, starts=starts);
}



// Constructs a hex nut for a square profile threaded screw rod.  This method
// makes much smoother threads than the naive linear_extrude method.
//   od = diameter of the nut.
//   id = diameter of threaded rod to screw onto.
//   h = height/thickness of nut.
//   pitch = Length between threads.
//   left_handed = if true, create left-handed threads.  Default = false
//   starts = The number of lead starts.  Default = 1
//   slop = printer slop calibration to allow for tight fitting of parts.  default=0.2
// Examples:
//   square_threaded_nut(od=16, id=8, h=8, pitch=2, slop=0.2);
module square_threaded_nut(od=17.4, id=10.5, h=10, pitch=3.175, left_handed=false, starts=1, slop=0.2) {
	trapezoidal_threaded_nut(
		od=od, id=id, h=h, pitch=pitch,
		thread_angle=0,
		left_handed=left_handed,
		starts=starts,
		slop=slop
	);
}



// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
