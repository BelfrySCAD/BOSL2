//////////////////////////////////////////////////////////////////////
// Transformations, distributors, duplicators, and manipulators.
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


printer_slop = 0.20;  // mm


//////////////////////////////////////////////////////////////////////
// Transformations.
//////////////////////////////////////////////////////////////////////


// Moves/translates children.
//   x = X axis translation.
//   y = Y axis translation.
//   z = Z axis translation.
// Example:
//   move([10,20,30]) sphere(r=1);
//   move(y=10) sphere(r=1);
//   move(x=10, z=20) sphere(r=1);
module move(a=[0,0,0], x=0, y=0, z=0) {
	translate(a) translate([x,y,z]) children();
}


// Moves/translates children the given amount along the X axis.
// Example:
//   xmove(10) sphere(r=1);
module xmove(x=0) { translate([x,0,0]) children(); }


// Moves/translates children the given amount along the Y axis.
// Example:
//   ymove(10) sphere(r=1);
module ymove(y=0) { translate([0,y,0]) children(); }


// Moves/translates children the given amount along the Z axis.
// Example:
//   zmove(10) sphere(r=1);
module zmove(z=0) { translate([0,0,z]) children(); }


// Moves children left by the given amount in the -X direction.
// Example:
//   left(10) sphere(r=1);
module left(x=0) { translate([-x,0,0]) children(); }


// Moves children right by the given amount in the +X direction.
// Example:
//   right(10) sphere(r=1);
module right(x=0) { translate([x,0,0]) children(); }


// Moves children forward by x amount in the -Y direction.
// Example:
//   forward(10) sphere(r=1);
module forward(y=0) { translate([0,-y,0]) children(); }
module fwd(y=0) { translate([0,-y,0]) children(); }


// Moves children back by the given amount in the +Y direction.
// Example:
//   back(10) sphere(r=1);
module back(y=0) { translate([0,y,0]) children(); }


// Moves children down by the given amount in the -Z direction.
// Example:
//   down(10) sphere(r=1);
module down(z=0) { translate([0,0,-z]) children(); }


// Moves children up by the given amount in the +Z direction.
// Example:
//   up(10) sphere(r=1);
module up(z=0) { translate([0,0,z]) children(); }


// Rotates children around the Z axis by the given number of degrees.
// Example:
//   xrot(90) cylinder(h=10, r=2, center=true);
module xrot(a=0) { rotate([a, 0, 0]) children(); }


// Rotates children around the Y axis by the given number of degrees.
// Example:
//   yrot(90) cylinder(h=10, r=2, center=true);
module yrot(a=0) { rotate([0, a, 0]) children(); }


// Rotates children around the Z axis by the given number of degrees.
// Example:
//   zrot(90) cube(size=[9,1,4], center=true);
module zrot(a=0) { rotate([0, 0, a]) children(); }


// Scales children by the given factor in the X axis.
// Example:
//   xscale(3) sphere(r=100, center=true);
module xscale(x) {scale([x,1,1]) children();}


// Scales children by the given factor in the Y axis.
// Example:
//   yscale(3) sphere(r=100, center=true);
module yscale(y) {scale([1,y,1]) children();}


// Scales children by the given factor in the Z axis.
// Example:
//   zscale(3) sphere(r=100, center=true);
module zscale(z) {scale([1,1,z]) children();}


// Mirrors the children along the X axis, kind of like xscale(-1)
module xflip() mirror([1,0,0]) children();


// Mirrors the children along the Y axis, kind of like yscale(-1)
module yflip() mirror([0,1,0]) children();


// Mirrors the children along the Z axis, kind of like zscale(-1)
module zflip() mirror([0,0,1]) children();


// Skews children on the X-Y plane, keeping constant in Z.
//   xa = skew angle towards the X direction.
//   ya = skew angle towards the Y direction.
// Examples:
//   skew_xy(xa=15) cube(size=10);
//   skew_xy(xa=15, ya=30) cube(size=10);
module skew_xy(xa=0, ya=0)
{
	multmatrix(m = [
		[1,       0,  tan(xa),        0],
		[0,       1,  tan(ya),        0],
		[0,       0,        1,        0],
		[0,       0,        0,        1]
	]) {
		children();
	}
}
module zskew(xa=0,ya=0) skew_xy(xa=xa,ya=ya) children();


// Skews children on the Y-Z plane, keeping constant in X.
//   ya = skew angle towards the Y direction.
//   za = skew angle towards the Z direction.
// Examples:
//   skew_yz(ya=15) cube(size=10);
//   skew_yz(ya=15, za=30) cube(size=10);
module skew_yz(ya=0, za=0)
{
	multmatrix(m = [
		[1,       0,        0,        0],
		[tan(ya), 1,        0,        0],
		[tan(za), 0,        1,        0],
		[0,       0,        0,        1]
	]) {
		children();
	}
}
module xskew(ya=0,za=0) skew_yz(ya=ya,za=za) children();


// Skews children on the X-Z plane, keeping constant in Y.
//   xa = skew angle towards the X direction.
//   za = skew angle towards the Z direction.
// Examples:
//   skew_xz(xa=15) cube(size=10);
//   skew_xz(xa=15, za=30) cube(size=10);
module skew_xz(xa=0, za=0)
{
	multmatrix(m = [
		[1, tan(xa),        0,        0],
		[0,       1,        0,        0],
		[0, tan(za),        1,        0],
		[0,       0,        0,        1]
	]) {
		children();
	}
}
module yskew(xa=0,za=0) skew_xz(xa=xa,za=za) children();



//////////////////////////////////////////////////////////////////////
// Mutators.
//////////////////////////////////////////////////////////////////////


// Performs hull operations between consecutive pairs of children,
// then unions all of the hull results.
module chain_hull() {
	union() {
		if ($children == 1) {
			children();
		} else if ($children > 1) {
			for (i =[1:$children-1]) {
				hull() {
					children(i-1);
					children(i);
				}
			}
		}
	}
}



//////////////////////////////////////////////////////////////////////
// Duplicators and Distributers.
//////////////////////////////////////////////////////////////////////


// Makes a copy of the children, mirrored across the given plane.
//   v = The normal vector of the plane to mirror across.
//   offset = distance to offset away from the plane.
// Example:
//   mirror_copy([1,-1,0]) yrot(30) cylinder(h=10, r=1, center=true);
//   mirror_copy([1,1,1], offset=17.32) cylinder(h=10, r=1, center=false);
module mirror_copy(v=[0,0,1], offset=0)
{
	l = sqrt(v[0]*v[0]+v[1]*v[1]+v[2]*v[2]);
	nv = v/l;
	off = nv*offset;
	union() {
		translate(off) children();
		mirror(nv) translate(off) children();
	}
}


// Makes a copy of the children, mirrored across the X axis.
//   offset = distance to offset children away from the X axis.
// Example:
//   xflip_copy() yrot(30) cylinder(h=10, r=1, center=true);
//   xflip_copy(offset=10) yrot(30) cylinder(h=10, r=1, center=false);
module xflip_copy(offset=0) {right(offset) children(); mirror([1,0,0]) right(offset) children();}


// Makes a copy of the children, mirrored across the Y axis.
//   offset = distance to offset children away from the Y axis.
// Example:
//   yflip_copy() yrot(30) cylinder(h=10, r=1, center=true);
//   yflip_copy(offset=10) yrot(30) cylinder(h=10, r=1, center=false);
module yflip_copy(offset=0) {back(offset) children(); mirror([0,1,0]) back(offset) children();}


// Makes a copy of the children, mirrored across the Z axis.
//   offset = distance to offset children away from the Z axis.
// Example:
//   zflip_copy() yrot(30) cylinder(h=10, r=1, center=true);
//   zflip_copy(offset=10) yrot(30) cylinder(h=10, r=1, center=false);
module zflip_copy(offset=0) {up(offset) children(); mirror([0,0,1]) up(offset) children();}


// Given a number of euller angles, rotates copies of the given children to each of those angles.
// Example:
//   rot_copies(rots=[[0,0,0],[45,0,0],[0,45,120],[90,-45,270]])
//     translate([6,0,0]) cube(size=[9,1,4], center=true);
module rot_copies(rots=[[0,0,0]])
{
	for (rot = rots) rotate(rot) children();
}


// Given an array of angles, rotates copies of the children to each of those angles around the X axis.
//   rots = Optional array of angles, in degrees, to make copies at.
//   count = Optional number of evenly distributed copies, rotated around a circle.
//   offset = Angle offset in degrees, for use with count.
// Example:
//   xrot_copies(rots=[0,15,30,60,120,240]) translate([0,6,0]) cube(size=[4,9,1], center=true);
//   xrot_copies(count=6, offset=15) translate([0,6,0]) cube(size=[4,9,1], center=true);
module xrot_copies(rots=[0], offset=0, count=undef)
{
	if (count != undef) {
		for (i = [0 : count-1]) {
			a = (i / count) * 360.0;
			rotate([a+offset, 0, 0]) {
				children();
			}
		}
	} else {
		for (a = rots) {
			rotate([a+offset, 0, 0]) {
				children();
			}
		}
	}
}


// Given an array of angles, rotates copies of the children to each of those angles around the Y axis.
//   rots = Optional array of angles, in degrees, to make copies at.
//   count = Optional number of evenly distributed copies, rotated around a circle.
//   offset = Angle offset in degrees, for use with count.
// Example:
//   yrot_copies(rots=[0,15,30,60,120,240]) translate([6,0,0]) cube(size=[9,4,1], center=true);
//   yrot_copies(count=6, offset=15) translate([6,0,0]) cube(size=[9,4,1], center=true);
module yrot_copies(rots=[0], offset=0, count=undef)
{
	if (count != undef) {
		for (i = [0 : count-1]) {
			a = (i / count) * 360.0;
			rotate([0, a+offset, 0]) {
				children();
			}
		}
	} else {
		for (a = rots) {
			rotate([0, a+offset, 0]) {
				children();
			}
		}
	}
}


// Given an array of angles, rotates copies of the children to each of those angles around the Z axis.
//   rots = Optional array of angles, in degrees, to make copies at.
//   count = Optional number of evenly distributed copies, rotated around a circle.
//   offset = Angle offset in degrees for first copy.
// Example:
//   zrot_copies(rots=[0,15,30,60,120,240]) translate([6,0,0]) cube(size=[9,1,4], center=true);
//   zrot_copies(count=6, offset=15) translate([6,0,0]) cube(size=[9,1,4], center=true);
module zrot_copies(rots=[0], offset=0, count=undef)
{
	if (count != undef) {
		for (i = [0 : count-1]) {
			a = (i / count) * 360.0;
			rotate([0, 0, a+offset]) {
				children();
			}
		}
	} else {
		for (a = rots) {
			rotate([0, 0, a+offset]) {
				children();
			}
		}
	}
}


// Makes copies of the given children at each of the given offsets.
//   a = array of XYZ offset vectors. Default [[0,0,0]]
// Example:
//   translate_copies([[-5,-5,0], [5,-5,0], [0,-5,7], [0,5,0]])
//     sphere(r=3,center=true);
module translate_copies(a=[[0,0,0]])
{
	for (off = a) translate(off) children();
}
module place_copies(a=[[0,0,0]]) {translate_copies(a) children();}


// Evenly distributes n duplicate children along an XYZ line.
//   p1 = starting point of line.  (Default: [0,0,0])
//   p2 = ending point of line.  (Default: [10,0,0])
//   n = number of copies to distribute along the line. (Default: 2)
// Examples:
//   line_of(p1=[0,0,0], p2=[-10,15,20], n=5) cube(size=[3,1,1],center=true);
//
module line_of(p1=[0,0,0], p2=[10,0,0], n=2)
{
	delta = (p2 - p1) / (n-1);
	for (i = [0:n-1]) translate(p1+delta*i) children();
}
module spread(p1,p2,n=3) {line_of(p1,p2,n) children();}


// Evenly distributes n duplicate children around an ovoid arc on the XY plane.
//   n = number of copies to distribute around the circle. (Default: 6)
//   r = radius of circle (Default: 1)
//   rx = radius of ellipse on X axis. Used instead of r.
//   ry = radius of ellipse on Y axis. Used instead of r.
//   d = diameter of circle. (Default: 2)
//   dx = diameter of ellipse on X axis. Used instead of d.
//   dy = diameter of ellipse on Y axis. Used instead of d.
//   rot = whether to rotate the copied children.  (Default: false)
//   sa = starting angle. (Default: 0.0)
//   ea = ending angle. Will distribute copies CCW from sa to ea. (Default: 360.0)
// Examples:
//   arc_of(d=8,n=5)
//     cube(size=[3,1,1],center=true);
//   arc_of(r=10,n=12,rot=true)
//     cube(size=[3,1,1],center=true);
//   arc_of(rx=15,ry=10,n=12,rot=true)
//     cube(size=[3,1,1],center=true);
//   arc_of(r=10,n=5,rot=true,sa=30.0,ea=150.0)
//     cube(size=[3,1,1],center=true);
//
module arc_of(
		n=6,
		r=1, rx=undef, ry=undef,
		d=undef, dx=undef, dy=undef,
		sa=0.0, ea=360.0,
		rot=false
) {
	r = (d == undef)?r:(d/2.0);
	rx = (dx == undef)?rx:(dx/2.0);
	ry = (dy == undef)?rx:(dy/2.0);
	rx = (rx == undef)?r:rx;
	ry = (ry == undef)?r:ry;
	sa = ((sa % 360.0) + 360.0) % 360.0; // make 0 < ang < 360
	ea = ((ea % 360.0) + 360.0) % 360.0; // make 0 < ang < 360
	n = (abs(ea-sa)<0.01)?(n+1):n;
	delt = (((ea<=sa)?360.0:0)+ea-sa)/(n-1);
	for (i = [0:n-1]) {
		ang = sa + (i * delt);
		translate([cos(ang)*rx, sin(ang)*ry, 0]) {
			zrot(rot? atan2(sin(ang)*ry,cos(ang)*rx) : 0) {
				children();
			}
		}
	}
}


// Evenly distributes n duplicate children around a circle on the YZ plane, around the
// X axis.  First moves children away from the X axis by r distance, in direction sa.
// Then copies them around the axis of rotation, for a total of n copies.  If rot is
// true, each copy is rotated in place to orient to the center of rotation.
//   n = number of copies of children to distribute around the circle. (Default: 2)
//   r = radius of ring to distribute children around. (Default: 0)
//   sa = start angle for first (unrotated) copy.  (Default: 0)
//   rot = if true, rotate each copy of children with respect to the center of the ring.
// Example:
//   xring(n=3, r=10, sa=270) yspread(10) yrot(120) cylinder(h=10, d=1, center=false);
module xring(n=2,r=0,sa=0,rot=true) {if (n>0) for (i=[0:n-1]) {a=i*360/n; xrot(a+sa) back(r) xrot((rot?0:-a)-sa) children();}}


// Evenly distributes n duplicate children around a circle on the XZ plane, around the
// Y axis.  First moves children away from the Y axis by r distance, in direction sa.
// Then copies them around the axis of rotation, for a total of n copies.  If rot is
// true, each copy is rotated in place to orient to the center of rotation.
//   n = number of copies of children to distribute around the circle. (Default: 2)
//   r = radius of ring to distribute children around. (Default: 0)
//   sa = start angle for first (unrotated) copy.  (Default: 0)
//   rot = if true, rotate each copy of children with respect to the center of the ring.
// Example:
//   yring(n=3, r=10, sa=270) xspread(10) xrot(-120) cylinder(h=10, d=1, center=false);
module yring(n=2,r=0,sa=0,rot=true) {if (n>0) for (i=[0:n-1]) {a=i*360/n; yrot(a-sa) right(r) yrot((rot?0:-a)+sa) children();}}


// Evenly distributes n duplicate children around a circle on the XY plane, around the
// Z axis.  First moves children away from the Z axis by r distance, in direction sa.
// Then copies them around the axis of rotation, for a total of n copies.  If rot is
// true, each copy is rotated in place to orient to the center of rotation.
//   n = number of copies of children to distribute around the circle. (Default: 2)
//   r = radius of ring to distribute children around. (Default: 0)
//   sa = start angle for first (unrotated) copy.  (Default: 0)
//   rot = if true, rotate each copy of children with respect to the center of the ring.
// Example:
//   zring(n=3, r=10, sa=90) xspread(10) xrot(30) cylinder(h=10, d=1, center=false);
module zring(n=2,r=0,sa=0,rot=true) {if (n>0) for (i=[0:n-1]) {a=i*360/n; zrot(a+sa) right(r) zrot((rot?0:-a)-sa) children();}}


// Spreads out n copies of the given children along the X axis.
//   spacing = spacing between copies. (Default: 1.0)
//   n = Number of copies to spread out. (Default: 2)
// Examples:
//   xspread(25) sphere(1);
//   xspread(25,3) sphere(1)
//   xspread(25, n=3) sphere(1)
//   xspread(spacing=20, n=4) sphere(1)
module xspread(spacing=1,n=2) for (i=[0:n-1]) right((i-(n-1)/2.0)*spacing) children();


// Spreads out n copies of the given children along the Y axis.
//   spacing = spacing between copies. (Default: 1.0)
//   n = Number of copies to spread out. (Default: 2)
// Examples:
//   yspread(25) sphere(1);
//   yspread(25,3) sphere(1)
//   yspread(25, n=3) sphere(1)
//   yspread(spacing=20, n=4) sphere(1)
module yspread(spacing=1,n=2) for (i=[0:n-1]) back((i-(n-1)/2)*spacing) children();


// Spreads out n copies of the given children along the Z axis.
//   spacing = spacing between copies. (Default: 1.0)
//   n = Number of copies to spread out. (Default: 2)
// Examples:
//   zspread(25) sphere(1);
//   zspread(25,3) sphere(1)
//   zspread(25, n=3) sphere(1)
//   zspread(spacing=20, n=4) sphere(1)
module zspread(spacing=1,n=2) for (i=[0:n-1]) up((i-(n-1)/2.0)*spacing) children();


// Makes a 3D grid of duplicate children.
//   xa = array or range of X-axis values to offset by. (Default: [0])
//   ya = array or range of Y-axis values to offset by. (Default: [0])
//   za = array or range of Z-axis values to offset by. (Default: [0])
//   count = Optional number of copies to have per axis. (Default: none)
//   spacing = spacing of copies per axis. Use with count. (Default: 0)
// Examples:
//   grid_of(xa=[0,2,3,5],ya=[3:5],za=[-4:2:6]) sphere(r=0.5,center=true);
//   grid_of(ya=[-6:3:6],za=[4,7]) sphere(r=1,center=true);
//   grid_of(count=3, spacing=10) sphere(r=1,center=true);
//   grid_of(count=[3, 1, 2], spacing=10) sphere(r=1,center=true);
//   grid_of(count=[3, 4], spacing=[10, 8]) sphere(r=1,center=true);
//   grid_of(count=[3, 4, 2], spacing=[10, 8, 5]) sphere(r=1,center=true, $fn=24);
module grid_of(xa=[0], ya=[0], za=[0], count=[], spacing=[])
{
	count = (len(count) == undef)? [count,1,1] :
			((len(count) == 1)? [count[0], 1, 1] :
			((len(count) == 2)? [count[0], count[1], 1] :
			((len(count) == 3)? count : undef)));

	spacing = (len(spacing) == undef)? [spacing,spacing,spacing] :
			((len(spacing) == 1)? [spacing[0], 0, 0] :
			((len(spacing) == 2)? [spacing[0], spacing[1], 0] :
			((len(spacing) == 3)? spacing : undef)));

	if (count != undef && spacing != undef) {
		for (x = [-(count[0]-1)/2 : (count[0]-1)/2 + 0.1]) {
			for (y = [-(count[1]-1)/2 : (count[1]-1)/2 + 0.1]) {
				for (z = [-(count[2]-1)/2 : (count[2]-1)/2 + 0.1]) {
					translate([x*spacing[0], y*spacing[1], z*spacing[2]]) {
						children();
					}
				}
			}
		}
	} else {
		for (xoff = xa) {
			for (yoff = ya) {
				for (zoff = za) {
					translate([xoff,yoff,zoff]) {
						children();
					}
				}
			}
		}
	}
}


module top_half   (s=100) difference() {children();  down(s/2) cube(s, center=true);}
module bottom_half(s=100) difference() {children();    up(s/2) cube(s, center=true);}
module left_half  (s=100) difference() {children(); right(s/2) cube(s, center=true);}
module right_half (s=100) difference() {children();  left(s/2) cube(s, center=true);}
module front_half (s=100) difference() {children();  back(s/2) cube(s, center=true);}
module back_half  (s=100) difference() {children();   fwd(s/2) cube(s, center=true);}



// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
