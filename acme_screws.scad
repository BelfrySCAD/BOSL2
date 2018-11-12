//////////////////////////////////////////////////////////////////////
// ACME Trapezoidal-threaded Screw Rods and Nuts
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

include <threading.scad>



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



// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
