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


function get_metric_bolt_head_size(size) = lookup(size, [
		[ 4.0,  7.0],
		[ 5.0,  8.0],
		[ 6.0, 10.0],
		[ 7.0, 11.0],
		[ 8.0, 13.0],
		[10.0, 16.0],
		[12.0, 18.0],
		[14.0, 21.0],
		[16.0, 24.0],
		[18.0, 27.0],
		[20.0, 30.0]
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
		[20.0, 30.0],
	]);


function get_metric_nut_thickness(size) = lookup(size, [
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
		[20.0, 16.0]
	]);


// Makes a simple threadless screw, useful for making screwholes.
//   screwsize = diameter of threaded part of screw.
//   screwlen = length of threaded part of screw.
//   headsize = diameter of the screw head.
//   headlen = length of the screw head.
// Example:
//   screw(screwsize=3,screwlen=10,headsize=6,headlen=3);
module screw(screwsize=3,screwlen=10,headsize=6,headlen=3,$fn=undef)
{
	$fn = ($fn==undef)?max(8,floor(180/asin(2/screwsize)/2)*2):$fn;
	translate([0,0,-(screwlen)/2])
		cylinder(r=screwsize/2, h=screwlen+0.05, center=true, $fn=$fn);
	translate([0,0,(headlen)/2])
		cylinder(r=headsize/2, h=headlen, center=true, $fn=$fn*2);
}


// Makes an unthreaded model of a standard nut for a standard metric screw.
//   size = standard metric screw size in mm. (Default: 3)
//   hole = include an unthreaded hole in the nut.  (Default: true)
// Example:
//   metric_nut(size=8, hole=true);
//   metric_nut(size=3, hole=false);
module metric_nut(size=3, hole=true, $fn=undef, center=false)
{
	$fn = ($fn==undef)?max(8,floor(180/asin(2/size)/2)*2):$fn;
	radius = get_metric_nut_size(size)/2/cos(30);
	thick = get_metric_nut_thickness(size);
	offset = (center == true)? 0 : thick/2;
	translate([0,0,offset]) difference() {
		cylinder(r=radius, h=thick, center=true, $fn=6);
		if (hole == true)
			cylinder(r=size/2, h=thick+0.5, center=true, $fn=$fn);
	}
}



// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
