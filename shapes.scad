//////////////////////////////////////////////////////////////////////
// Compound Shapes.
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
include <masks.scad>


// For when you MUST pass a child to a module, but you want it to be nothing.
module nil() union() {}


// Makes a cube that is centered in X and Y axes, and has its bottom aligned with Z=0.
module upcube(size=[1,1,1]) {up(size[2]/2) cube(size, center=true);}



// Makes a cube with chamfered edges.
//   size = size of cube [X,Y,Z].  (Default: [1,1,1])
//   chamfer = chamfer inset along axis.  (Default: 0.25)
//   chamfaxes = Array [X, Y, Z] of boolean values to specify which axis edges should be chamfered.
//   chamfcorners = boolean to specify if corners should be flat chamferred.
// Example:
//   chamfcube(size=[10,30,50], chamfer=1, chamfaxes=[1,1,1], chamfcorners=true);
module chamfcube(
	size=[1,1,1],
	chamfer=0.25,
	chamfaxes=[1,1,1],
	chamfcorners=false
) {
	ch_width = sqrt(2)*chamfer;
	ch_offset = 1;
	difference() {
		cube(size=size, center=true);
		for (xs = [-1,1]) {
			for (ys = [-1,1]) {
				if (chamfaxes[0] == 1) {
					translate([0,xs*size[1]/2,ys*size[2]/2]) {
						rotate(a=[45,0,0]) cube(size=[size[0]+0.1,ch_width,ch_width], center=true);
					}
				}
				if (chamfaxes[1] == 1) {
					translate([xs*size[0]/2,0,ys*size[2]/2]) {
						rotate(a=[0,45,0]) cube(size=[ch_width,size[1]+0.1,ch_width], center=true);
					}
				}
				if (chamfaxes[2] == 1) {
					translate([xs*size[0]/2,ys*size[1]/2],0) {
						rotate(a=[0,0,45]) cube(size=[ch_width,ch_width,size[2]+0.1], center=true);
					}
				}
				if (chamfcorners) {
					for (zs = [-1,1]) {
						translate([xs*size[0]/2,ys*size[1]/2,zs*size[2]/2]) {
							scale([chamfer,chamfer,chamfer]) {
								polyhedron(
									points=[
										[0,-1,-1], [0,-1,1], [0,1,1], [0,1,-1],
										[-1,0,-1], [-1,0,1], [1,0,1], [1,0,-1],
										[-1,-1,0], [-1,1,0], [1,1,0], [1,-1,0]
									],
									faces=[
										[ 8,  4,  9],
										[ 8,  9,  5],
										[ 9,  3, 10],
										[ 9, 10,  2],
										[10,  7, 11],
										[10, 11,  6],
										[11,  0,  8],
										[11,  8,  1],
										[ 0,  7,  3],
										[ 0,  3,  4],
										[ 1,  5,  2],
										[ 1,  2,  6],

										[ 1,  8,  5],
										[ 5,  9,  2],
										[ 2, 10,  6],
										[ 6, 11,  1],

										[ 0,  4,  8],
										[ 4,  3,  9],
										[ 3,  7, 10],
										[ 7,  0, 11],
									]
								);
							}
						}
					}
				}
			}
		}
	}
}


// Makes a cube with rounded (filletted) vertical edges. The r size will be
// limited to a maximum of half the length of the shortest XY side.
//   size = size of cube [X,Y,Z].  (Default: [1,1,1])
//   r = radius of edge/corner rounding.  (Default: 0.25)
//   center = if true, object will be centered.  If false, sits on top of XY plane.
// Examples:
//   rrect(size=[9,4,1], r=1, center=true);
//   rrect(size=[5,7,3], r=1, $fn=24);
module rrect(size=[1,1,1], r=0.25, center=false)
{
	w = size[0];
	l = size[1];
	h = size[2];
	rr = min(r, min(w/2-0.01, l/2-0.01));
	up(center? 0 : h/2) {
		linear_extrude(height=h, convexity=2, center=true) {
			offset(r=rr) {
				square([w-2*rr, l-2*rr], center=true);
			}
		}
	}
}


// Makes a cube with rounded (filletted) edges and corners.  The r size will be
// limited to a maximum of half the length of the shortest side.
//   size = size of cube [X,Y,Z].  (Default: [1,1,1])
//   r = radius of edge/corner rounding.  (Default: 0.25)
//   center = if true, object will be centered.  If false, sits on top of XY plane.
// Examples:
//   rcube(size=[9,4,1], r=0.333, center=true, $fn=24);
//   rcube(size=[5,7,3], r=1);
module rcube(size=[1,1,1], r=0.25, center=false)
{
	dd = min(2*r, min(size));
	$fn=quantup(segs(dd/2), 4);
	translate(center? [0,0,0] : size/2) {
		minkowski() {
			cube([max(0.01,size[0]-dd), max(0.01,size[1]-dd), max(0.01,size[2]-dd)], center=true);

			// Synthesize a sphere with vertices at the axis extremes.
			// This makes the result of the minkowski have the proper dimensions.
			rotate_extrude() {
				difference() {
					circle(dd/2);
					left(dd/2) square(dd, center=true);
				}
			}
		}
	}
}


// Creates a cylinder with chamferred (bevelled) edges.
//   h = height of cylinder. (Default: 1.0)
//   r = radius of cylinder. (Default: 1.0)
//   d = diameter of cylinder. (use instead of r)
//   chamfer = radial inset of the edge chamfer. (Default: 0.25)
//   chamfedge = length of the chamfer edge. (Use instead of chamfer)
//   center = boolean.  If true, cylinder is centered. (Default: false)
//   top = boolean.  If true, chamfer the top edges. (Default: True)
//   bottom = boolean.  If true, chamfer the bottom edges. (Default: True)
// Example:
//   chamferred_cylinder(h=50, r=20, chamfer=5, angle=45, bottom=false, center=true);
//   chamferred_cylinder(h=50, r=20, chamfedge=10, angle=30, center=true);
module chamferred_cylinder(h=1, r=1, d=undef, chamfer=0.25, chamfedge=undef, angle=45, center=false, top=true, bottom=true)
{
	chamf = (chamfedge == undef)? chamfer * sqrt(2) : chamfedge;
	x = (chamfedge == undef)? chamfer : (chamfedge * sin(angle));
	y = (chamfedge == undef)? chamfer*sin(90-angle)/sin(angle) : (chamfedge * sin(90-angle));
	rad = (d == undef)? r : (d / 2.0);
	up(center? 0 : h/2) {
		rotate_extrude(angle=360, convexity=2) {
			polygon(
				points=[
					[0, h/2],
					[rad-x*(top?1:0), h/2],
					[rad, h/2-y*(top?1:0)],
					[rad, -h/2+y*(bottom?1:0)],
					[rad-x*(bottom?1:0), -h/2],
					[0, -h/2],
					[0, h/2],
				]
			);
		}
	}
}

module chamf_cyl(h=1, r=1, d=undef, chamfer=0.25, chamfedge=undef, angle=45, center=false, top=true, bottom=true)
	chamferred_cylinder(h=h, r=r, d=d, chamfer=chamfer, chamfedge=chamfedge, angle=angle, center=center, top=top, bottom=bottom);
//!chamf_cyl(h=20, d=20, chamfedge=10, angle=30, center=true, $fn=36);


// Creates a cylinder with filletted (rounded) ends.
//   h = height of cylinder. (Default: 1.0)
//   r = radius of cylinder. (Default: 1.0)
//   d = diameter of cylinder. (Use instead of r)
//   fillet = radius of the edge filleting. (Default: 0.25)
//   center = boolean.  If true, cylinder is centered. (Default: false)
// Example:
//   rcylinder(h=50, r=20, fillet=5, center=true, $fa=1, $fs=1);
module rcylinder(h=1, r=1, d=undef, fillet=0.25, center=false)
{
	d = (d == undef)? r * 2.0 : d;
	dh = d - 2*fillet;
	hh = h - 2*fillet;
	up(center? 0 : h/2) {
		rotate_extrude(angle=360, convexity=2) {
			hull() {
				right(d/2-fillet) {
					yspread(h-2*fillet) {
						circle(r=fillet, $fn=quantup(segs(fillet), 4));
					}
				}
				right(d/2/2) square(size=[d/2, h-fillet*2], center=true);
				right((d/2-fillet)/2) square(size=[d/2-fillet, h], center=true);
			}
		}
	}
}

module filleted_cylinder(h=1, r=1, d=undef, fillet=0.25, center=false)
	rcylinder(h=h, r=r, d=d, fillet=fillet, center=center);



// Creates a pyramidal prism with a given number of sides.
//   n = number of pyramid sides.
//   h = height of the pyramid.
//   l = length of one side of the pyramid. (optional)
//   r = radius of the base of the pyramid. (optional)
//   d = diameter of the base of the pyramid. (optional)
//   circum = base circumscribes the circle of the given radius or diam.
// Example:
//   pyramid(h=3, d=4, n=6, circum=true);
module pyramid(n=4, h=1, l=1, r=undef, d=undef, circum=false)
{
	cm = circum? 1/cos(180/n) : 1.0;
	radius = (r!=undef)? r*cm : ((d!=undef)? d*cm/2 : (l/(2*sin(180/n))));
	zrot(180/n) cylinder(r1=radius, r2=0, h=h, $fn=n, center=false);
}


// Creates a vertical prism with a given number of sides.
//   n = number of sides.
//   h = height of the prism.
//   l = length of one side of the prism. (optional)
//   r = radius of the prism. (optional)
//   d = diameter of the prism. (optional)
//   circum = prism circumscribes the circle of the given radius or diam.
// Example:
//   prism(n=6, h=3, d=4, circum=true);
module prism(n=3, h=1, l=1, r=undef, d=undef, circum=false, center=false)
{
	cm = circum? 1/cos(180/n) : 1.0;
	radius = (r!=undef)? r*cm : ((d!=undef)? d*cm/2 : (l/(2*sin(180/n))));
	zrot(180/n) cylinder(r=radius, h=h, center=center, $fn=n);
}


// Creates a right triangle, with the hypotenuse on the right (X+) side.
//   size = [width, thickness, height]
//   center = true if triangle will be centered.
// Examples:
//   right_triangle([4, 1, 6], center=true);
//   right_triangle([4, 1, 9]);
module right_triangle(size=[1, 1, 1], center=false)
{
	w = size[0];
	thick = size[1];
	h = size[2];
	translate(center? [-w/2, -thick/2, -h/2] : [0, 0, 0]) {
		polyhedron(
			points=[
				[0, 0, 0],
				[0, 0, h],
				[w, 0, 0],
				[0, thick, 0],
				[0, thick, h],
				[w, thick, 0]
			],
			faces=[
				[0, 1, 2],
				[0, 2, 5],
				[0, 5, 3],
				[0, 3, 4],
				[0, 4, 1],
				[1, 4, 5],
				[1, 5, 2],
				[3, 5, 4]
			],
			convexity=2
		);
	}
}


// Creates a trapezoidal prism.
//   size1 = [width, length] of the bottom of the prism.
//   size2 = [width, length] of the top of the prism.
//   h = Height of the prism.
//   center = vertically center the prism.
// Example:
//   trapezoid(size1=[1,4], size2=[4,1], h=4, center=false);
//   trapezoid(size1=[2,6], size2=[4,0], h=4, center=false);
module trapezoid(size1=[1,1], size2=[1,1], h=1, center=false)
{
	s1 = [max(size1[0], 0.001), max(size1[1], 0.001)];
	s2 = [max(size2[0], 0.001), max(size2[1], 0.001)];
	up(center? 0 : h/2) {
		polyhedron(
			points=[
				[+s2[0]/2, +s2[1]/2, +h/2],
				[+s2[0]/2, -s2[1]/2, +h/2],
				[-s2[0]/2, -s2[1]/2, +h/2],
				[-s2[0]/2, +s2[1]/2, +h/2],
				[+s1[0]/2, +s1[1]/2, -h/2],
				[+s1[0]/2, -s1[1]/2, -h/2],
				[-s1[0]/2, -s1[1]/2, -h/2],
				[-s1[0]/2, +s1[1]/2, -h/2],
			],
			faces=[
				[0, 1, 2],
				[0, 2, 3],
				[0, 4, 5],
				[0, 5, 1],
				[1, 5, 6],
				[1, 6, 2],
				[2, 6, 7],
				[2, 7, 3],
				[3, 7, 4],
				[3, 4, 0],
				[4, 7, 6],
				[4, 6, 5],
			],
			convexity=2
		);
	}
}


// Makes a 2D teardrop shape. Useful for extruding into 3D printable holes.
//   r = radius of circular part of teardrop.  (Default: 1)
//   d = diameter of spherical portion of bottom. (Use instead of r)
//   ang = angle of hat walls from the Y axis.  (Default: 45 degrees)
//   cap_h = if given, height above center where the shape will be truncated.
// Examples:
//   teardrop2d(r=30, ang=30);
//   teardrop2d(r=35, ang=45, cap_h=40);
module teardrop2d(r=1, d=undef, ang=45, cap_h=undef)
{
	r = (d!=undef)? (d/2.0) : r;
	difference() {
		hull() {
			back(r*sin(ang)) {
				yscale(1/tan(ang)) {
					difference() {
						zrot(45) square([2*r*cos(ang)/sqrt(2), 2*r*cos(ang)/sqrt(2)], center=true);
						fwd(r/2) square([2*r, r], center=true);
					}
				}
			}
			zrot(90) circle(r=r, center=true);
		}
		if (cap_h != undef) {
			back(r*3/2+cap_h) square([r*3, r*3], center=true);
		}
	}
}


// Makes a teardrop shape in the XZ plane. Useful for 3D printable holes.
//   r = radius of circular part of teardrop.  (Default: 1)
//   d = diameter of spherical portion of bottom. (Use instead of r)
//   h = thickness of teardrop. (Default: 1)
//   ang = angle of hat walls from the Z axis.  (Default: 45 degrees)
//   cap_h = if given, height above center where the shape will be truncated.
// Example:
//   teardrop(r=30, h=10, ang=30);
module teardrop(r=1, d=undef, h=1, ang=45, cap_h=undef)
{
	r = (d!=undef)? (d/2.0) : r;
	xrot(90) {
		linear_extrude(height=h, center=true, steps=2) {
			teardrop2d(r=r, ang=ang, cap_h=cap_h);
		}
	}
}


// Created a sphere with a conical hat, to make a 3D teardrop.
//   r = radius of spherical portion of the bottom. (Default: 1)
//   d = diameter of spherical portion of bottom. (Use instead of r)
//   h = height above sphere center to truncate teardrop shape. (Default: 1)
//   maxang = angle of cone on top from vertical.
// Example:
//   onion(h=15, r=10, maxang=30);
module onion(h=1, r=1, d=undef, maxang=45)
{
	r = (d!=undef)? (d/2.0) : r;
	rotate_extrude(angle=360, convexity=2) {
		difference() {
			teardrop2d(r=r, ang=maxang, cap_h=h);
			left(r+h/2) square(size=r*2+h, center=true);
		}
	}
}


// Makes a hollow tube with the given outer size and wall thickness.
//   h = height of tube. (Default: 1)
//   r = Outer radius of tube.  (Default: 1)
//   r1 = Outer radius of bottom of tube.  (Default: value of r)
//   r2 = Outer radius of top of tube.  (Default: value of r)
//   wall = horizontal thickness of tube wall. (Default 0.5)
// Example:
//   tube(h=3, r=4, wall=1, center=true);
//   tube(h=6, r=4, wall=2, $fn=6);
//   tube(h=3, r1=5, r2=7, wall=2, center=true);
module tube(h=1, r=1, r1=undef, r2=undef, d=undef, d1=undef, d2=undef, wall=0.1, center=false)
{
	r1 = (d1!=undef)? d1/2 : (d!=undef)? d/2 : (r1!=undef)? r1 : r;
	r2 = (d2!=undef)? d2/2 : (d!=undef)? d/2 : (r2!=undef)? r2 : r;
	up(center? 0 : h/2) {
		difference() {
			cylinder(h=h, r1=r1, r2=r2, center=true);
			cylinder(h=h+0.05, r1=r1-wall, r2=r2-wall, center=true);
		}
	}
}


// Creates a torus shape.
//   r  = major radius of torus ring. (use with of 'r2', or 'd2')
//   r2 = minor radius of torus ring. (use with of 'r', or 'd')
//   d  = major diameter of torus ring. (use with of 'r2', or 'd2')
//   d2 = minor diameter of torus ring. (use with of 'r', or 'd')
//   or = outer radius of the torus. (use with 'ir', or 'id')
//   ir = inside radius of the torus. (use with 'or', or 'od')
//   od = outer diameter of the torus. (use with 'ir' or 'id')
//   id = inside diameter of the torus. (use with 'or' or 'od')
// Example:
//   torus(r=30, r2=5);
//   torus(d=50, r2=5);
//   torus(d=60, d2=15);
//   torus(od=60, ir=15);
//   torus(or=30, ir=20, $fa=1, $fs=1);
module torus(or=1, ir=0.5, od=undef, id=undef, r=undef, r2=undef, d=undef, d2=undef)
{
	ir = id!=undef? id/2 : ir;
	or = od!=undef? od/2 : or;
	r = d!=undef? d/2 : r!=undef? r : (ir+or)/2;
	r2 = d2!=undef? d2/2 : r2!=undef? r2 : (or-ir)/2;
	rotate_extrude(convexity = 4) {
		right(r) circle(r2);
	}
}


// Makes a linear slot with rounded ends, appropriate for bolts to slide along.
//   p1 = center of starting circle of slot.  (Default: [0,0,0])
//   p2 = center of ending circle of slot.  (Default: [1,0,0])
//   l = length of slot along the X axis.  Use instead of p1 and p2.
//   h = height of slot shape. (default: 1.0)
//   r = radius of slot circle. (default: 0.5)
//   r1 = bottom radius of slot cone. (use instead of r)
//   r2 = top radius of slot cone. (use instead of r)
//   d = diameter of slot circle. (default: 1.0)
//   d1 = bottom diameter of slot cone. (use instead of d)
//   d2 = top diameter of slot cone. (use instead of d)
//   center = If true (default) centers vertically.  Else, drops flush with XY plane.
// Examples:
//   slot(l=50, h=5, d1=8, d2=10, center=false);
//   slot([0,0,0], [50,50,0], h=5, d=10);
module slot(
	p1=[0,0,0], p2=[1,0,0], h=1.0,
	l=undef, center=true,
	r=undef, r1=undef, r2=undef,
	d=1.0, d1=undef, d2=undef
) {
	r  = (r  != undef)? r  : (d/2);
	r1 = (r1 != undef)? r1 : ((d1 != undef)? (d1/2) : r);
	r2 = (r2 != undef)? r2 : ((d2 != undef)? (d2/2) : r);
	pt1 = l==undef? p1 : [-l/2, 0, 0];
	pt2 = l==undef? p2 : [ l/2, 0, 0];
	$fn = quantup(segs(max(r1,r2)),4);
	down(center? 0 : h/2) {
		hull() {
			translate(pt1) cylinder(h=h, r1=r1, r2=r2, center=true);
			translate(pt2) cylinder(h=h, r1=r1, r2=r2, center=true);
		}
	}
}


// Makes an arced slot, appropriate for bolts to slide along.
//   cp = centerpoint of slot arc. (default: [0, 0, 0])
//   h = height of slot arc shape. (default: 1.0)
//   r = radius of slot arc. (default: 0.5)
//   d = diameter of slot arc. (default: 1.0)
//   sr = radius of slot channel. (default: 0.5)
//   sd = diameter of slot channel. (default: 0.5)
//   sr1 = bottom radius of slot channel cone. (use instead of sr)
//   sr2 = top radius of slot channel cone. (use instead of sr)
//   sd1 = bottom diameter of slot channel cone. (use instead of sd)
//   sd2 = top diameter of slot channel cone. (use instead of sd)
//   sa = starting angle. (Default: 0.0)
//   ea = ending angle. (Default: 90.0)
// Examples:
//   arced_slot(d=100, h=15, sd=10, sa=60, ea=280);
//   arced_slot(r=100, h=10, sd1=30, sd2=10, sa=45, ea=180, $fa=5, $fs=2);
module arced_slot(
	cp=[0,0,0],
	r=undef, d=1.0, h=1.0,
	sr=undef, sr1=undef, sr2=undef,
	sd=1.0, sd1=undef, sd2=undef,
	sa=0, ea=90
) {
	r  = (r  != undef)? r  : (d/2);
	sr  = (sr  != undef)? sr  : (sd/2);
	sr1 = (sr1 != undef)? sr1 : ((sd1 != undef)? (sd1/2) : sr);
	sr2 = (sr2 != undef)? sr2 : ((sd2 != undef)? (sd2/2) : sr);
	da = ea - sa;
	zrot(sa) {
		translate([r, 0, 0]) cylinder(h=h, r1=sr1, r2=sr2, center=true);
		difference() {
			angle_pie_mask(h=h, r1=(r+sr1), r2=(r+sr2), ang=da);
			cylinder(h=h+0.05, r1=(r-sr1), r2=(r-sr2), center=true);
		}
		zrot(da) {
			translate([r, 0, 0]) cylinder(h=h, r1=sr1, r2=sr2, center=true);
		}
	}
}


// Makes a rectangular strut with the top side narrowing in a triangle.
// The shape created may be likened to an extruded home plate from baseball.
// This is useful for constructing parts that minimize the need to support
// overhangs.
//   w = Width (thickness) of the strut.
//   l = Length of the strut.
//   wall = height of rectangular portion of the strut.
//   ang = angle that the trianglar side will converge at.
// Example:
//   narrowing_strut(w=10, l=100, wall=5, ang=30);
module narrowing_strut(w=10, l=100, wall=5, ang=30)
{
	tipy = wall + (w/2)*sin(90-ang)/sin(ang);
	xrot(90) linear_extrude(height=l, center=true, steps=2) {
		polygon(
			points=[
				[-w/2, 0],
				[-w/2, wall],
				[0, tipy],
				[w/2, wall],
				[w/2, 0]
			]
		);
	}
}


// Makes a rectangular wall which thins to a smaller width in the center,
// with angled supports to prevent critical overhangs.
//   h = height of wall.
//   l = length of wall.
//   thick = thickness of wall.
//   ang = maximum overhang angle of diagonal brace.
//   strut = the width of the diagonal brace.
//   wall = the thickness of the thinned portion of the wall.
// Example:
//   thinning_wall(h=50, l=100, thick=4, ang=30, strut=5, wall=2);
module thinning_wall(h=50, l=100, thick=5, ang=30, strut=5, wall=2)
{
	l1 = (l[0] == undef)? l : l[0];
	l2 = (l[1] == undef)? l : l[1];

	trap_ang = atan2((l2-l1)/2, h);
	corr1 = 1 + sin(trap_ang);
	corr2 = 1 - sin(trap_ang);

	z1 = h/2;
	z2 = max(0.1, z1 - strut);
	z3 = max(0.05, z2 - (thick-wall)/2*sin(90-ang)/sin(ang));

	x1 = l2/2;
	x2 = max(0.1, x1 - strut*corr1);
	x3 = max(0.05, x2 - (thick-wall)/2*sin(90-ang)/sin(ang)*corr1);
	x4 = l1/2;
	x5 = max(0.1, x4 - strut*corr2);
	x6 = max(0.05, x5 - (thick-wall)/2*sin(90-ang)/sin(ang)*corr2);

	y1 = thick/2;
	y2 = y1 - min(z2-z3, x2-x3) * sin(ang);

	zrot(90) {
		polyhedron(
			points=[
				[-x4, -y1, -z1],
				[ x4, -y1, -z1],
				[ x1, -y1,  z1],
				[-x1, -y1,  z1],

				[-x5, -y1, -z2],
				[ x5, -y1, -z2],
				[ x2, -y1,  z2],
				[-x2, -y1,  z2],

				[-x6, -y2, -z3],
				[ x6, -y2, -z3],
				[ x3, -y2,  z3],
				[-x3, -y2,  z3],

				[-x4,  y1, -z1],
				[ x4,  y1, -z1],
				[ x1,  y1,  z1],
				[-x1,  y1,  z1],

				[-x5,  y1, -z2],
				[ x5,  y1, -z2],
				[ x2,  y1,  z2],
				[-x2,  y1,  z2],

				[-x6,  y2, -z3],
				[ x6,  y2, -z3],
				[ x3,  y2,  z3],
				[-x3,  y2,  z3],
			],
			faces=[
				[ 4,  5,  1],
				[ 5,  6,  2],
				[ 6,  7,  3],
				[ 7,  4,  0],

				[ 4,  1,  0],
				[ 5,  2,  1],
				[ 6,  3,  2],
				[ 7,  0,  3],

				[ 8,  9,  5],
				[ 9, 10,  6],
				[10, 11,  7],
				[11,  8,  4],

				[ 8,  5,  4],
				[ 9,  6,  5],
				[10,  7,  6],
				[11,  4,  7],

				[11, 10,  9],
				[20, 21, 22],

				[11,  9,  8],
				[20, 22, 23],

				[16, 17, 21],
				[17, 18, 22],
				[18, 19, 23],
				[19, 16, 20],

				[16, 21, 20],
				[17, 22, 21],
				[18, 23, 22],
				[19, 20, 23],

				[12, 13, 17],
				[13, 14, 18],
				[14, 15, 19],
				[15, 12, 16],

				[12, 17, 16],
				[13, 18, 17],
				[14, 19, 18],
				[15, 16, 19],

				[ 0,  1, 13],
				[ 1,  2, 14],
				[ 2,  3, 15],
				[ 3,  0, 12],

				[ 0, 13, 12],
				[ 1, 14, 13],
				[ 2, 15, 14],
				[ 3, 12, 15],
			],
			convexity=2
		);
	}
}
//!thinning_wall(h=50, l=[100, 80], thick=4, ang=30, strut=5, wall=2);


module braced_thinning_wall(h=50, l=100, thick=5, ang=30, strut=5, wall=2)
{
	dang = atan((h-2*strut)/(l-2*strut));
	dlen = (h-2*strut)/sin(dang);
	union() {
		xrot_copies([0, 180]) {
			down(h/2) narrowing_strut(w=thick, l=l, wall=strut, ang=ang);
			fwd(l/2) xrot(-90) narrowing_strut(w=thick, l=h-0.1, wall=strut, ang=ang);
			intersection() {
				cube(size=[thick, l, h], center=true);
				xrot_copies([-dang,dang]) {
					zspread(strut/2) {
						scale([1,1,1.5]) yrot(45) {
							cube(size=[thick/sqrt(2), dlen, thick/sqrt(2)], center=true);
						}
					}
					cube(size=[thick, dlen, strut/2], center=true);
				}
			}
		}
		cube(size=[wall, l-0.1, h-0.1], center=true);
	}
}


// Makes a triangular wall with thick edges, which thins to a smaller width in
// the center, with angled supports to prevent critical overhangs.
//   h = height of wall.
//   l = length of wall.
//   thick = thickness of wall.
//   ang = maximum overhang angle of diagonal brace.
//   strut = the width of the diagonal brace.
//   wall = the thickness of the thinned portion of the wall.
//   diagonly = boolean, which denotes only the diagonal side (hypotenuse) should be thick.
//   center = if true (default) centers triangle at the origin.
// Example:
//   thinning_triangle(h=50, l=100, thick=4, ang=30, strut=5, wall=2, diagonly=true);
module thinning_triangle(h=50, l=100, thick=5, ang=30, strut=5, wall=3, diagonly=false, center=true)
{
	dang = atan(h/l);
	dlen = h/sin(dang);
	translate(center? [0, 0, 0] : [0, l/2, h/2]) {
		difference() {
			union() {
				if (!diagonly) {
					translate([0, 0, -h/2])
						narrowing_strut(w=thick, l=l, wall=strut, ang=ang);
					translate([0, -l/2, 0])
						xrot(-90) narrowing_strut(w=thick, l=h-0.1, wall=strut, ang=ang);
				}
				intersection() {
					cube(size=[thick, l, h], center=true);
					xrot(-dang) yrot(180) {
						narrowing_strut(w=thick, l=dlen*1.2, wall=strut, ang=ang);
					}
				}
				cube(size=[wall, l-0.1, h-0.1], center=true);
			}
			xrot(-dang) {
				translate([0, 0, h/2]) {
					cube(size=[thick+0.1, l*2, h], center=true);
				}
			}
		}
	}
}


// Makes a triangular wall which thins to a smaller width in the center,
// with angled supports to prevent critical overhangs.  Basically an alias
// of thinning_triangle(), with diagonly=true.
//   h = height of wall.
//   l = length of wall.
//   thick = thickness of wall.
//   ang = maximum overhang angle of diagonal brace.
//   strut = the width of the diagonal brace.
//   wall = the thickness of the thinned portion of the wall.
// Example:
//   thinning_brace(h=50, l=100, thick=4, ang=30, strut=5, wall=2);
module thinning_brace(h=50, l=100, thick=5, ang=30, strut=5, wall=3, center=true)
{
	thinning_triangle(h=h, l=l, thick=thick, ang=ang, strut=strut, wall=wall, diagonly=true, center=center);
}


// Makes an open rectangular strut with X-shaped cross-bracing, designed to reduce the
// need for support material in 3D printing.
//   h = Z size of strut.
//   w = X size of strut.
//   l = Y size of strut.
//   thick = thickness of strut walls.
//   maxang = maximum overhang angle of cross-braces.
//   max_bridge = maximum bridging distance between cross-braces.
//   strut = the width of the cross-braces.
// Example:
//   sparse_strut3d(h=100, w=33, l=33, thick=3, strut=3, maxang=30, max_bridge=20);
//   sparse_strut3d(h=40, w=40, l=120, thick=3, maxang=30, strut=3, max_bridge=20);
module sparse_strut3d(h=50, l=100, w=50, thick=3, maxang=40, strut=3, max_bridge = 20)
{

	xoff = w - thick;
	yoff = l - thick;
	zoff = h - thick;

	xreps = ceil(xoff/yoff);
	yreps = ceil(yoff/xoff);
	zreps = ceil(zoff/min(xoff, yoff));

	xstep = xoff / xreps;
	ystep = yoff / yreps;
	zstep = zoff / zreps;

	cross_ang = atan2(xstep, ystep);
	cross_len = hypot(xstep, ystep);

	supp_ang = min(maxang, min(atan2(max_bridge, zstep), atan2(cross_len/2, zstep)));
	supp_reps = floor(cross_len/2/(zstep*sin(supp_ang)));
	supp_step = cross_len/2/supp_reps;

	union() {
		ybridge = (l - (yreps+1) * strut) / yreps;
		xspread(xoff) sparse_strut(h=h, l=l, thick=thick, maxang=maxang, strut=strut, max_bridge=ybridge/ceil(ybridge/max_bridge));
		yspread(yoff) zrot(90) sparse_strut(h=h, l=w, thick=thick, maxang=maxang, strut=strut, max_bridge=max_bridge);
		for(zs = [0:zreps-1]) {
			for(xs = [0:xreps-1]) {
				for(ys = [0:yreps-1]) {
					translate([(xs+0.5)*xstep-xoff/2, (ys+0.5)*ystep-yoff/2, (zs+0.5)*zstep-zoff/2]) {
						zflip_copy(offset=-(zstep-strut)/2) {
							xflip_copy() {
								zrot(cross_ang) {
									down(strut/2) {
										cube([strut, cross_len, strut], center=true);
									}
									if (zreps>1) {
										back(cross_len/2) {
											zrot(-cross_ang) {
												down(strut) upcube([strut, strut, zstep+strut], center=true);
											}
										}
									}
									for (soff = [0 : supp_reps-1] ) {
										yflip_copy() {
											back(soff*supp_step) {
												skew_xy(ya=supp_ang) {
													upcube([strut, strut, zstep]);
												}
											}
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}
}


// Makes an open rectangular strut with X-shaped cross-bracing, designed to reduce
// the need for support material in 3D printing.
//   h = height of strut wall.
//   l = length of strut wall.
//   thick = thickness of strut wall.
//   maxang = maximum overhang angle of cross-braces.
//   max_bridge = maximum bridging distance between cross-braces.
//   strut = the width of the cross-braces.
// Example:
//   sparse_strut(h=40, l=120, thick=4, maxang=30, strut=5, max_bridge=20);
module sparse_strut(h=50, l=100, thick=4, maxang=30, strut=5, max_bridge = 20)
{

	zoff = h/2 - strut/2;
	yoff = l/2 - strut/2;

	maxhyp = 1.5 * (max_bridge+strut)/2 / sin(maxang);
	maxz = 2 * maxhyp * cos(maxang);

	zreps = ceil(2*zoff/maxz);
	zstep = 2*zoff / zreps;

	hyp = zstep/2 / cos(maxang);
	maxy = min(2 * hyp * sin(maxang), max_bridge+strut);

	yreps = ceil(2*yoff/maxy);
	ystep = 2*yoff / yreps;

	ang = atan(ystep/zstep);
	len = zstep / cos(ang);

	union() {
		zspread(zoff*2)
			cube(size=[thick, l, strut], center=true);
		yspread(yoff*2)
			cube(size=[thick, strut, h], center=true);
		grid_of(ya=[-yoff+ystep/2:ystep:yoff], za=[-zoff+zstep/2:zstep:zoff]) {
			xrot( ang) cube(size=[thick, strut, len], center=true);
			xrot(-ang) cube(size=[thick, strut, len], center=true);
		}
	}
}


// Makes a corrugated wall which relieves contraction stress while still
// providing support strength.  Designed with 3D printing in mind.
//   h = height of strut wall.
//   l = length of strut wall.
//   thick = thickness of strut wall.
//   strut = the width of the cross-braces.
//   wall = thickness of corrugations.
// Example:
//   corrugated_wall(h=50, l=100, thick=4, strut=5, wall=2, $fn=12);
module corrugated_wall(h=50, l=100, thick=5, strut=5, wall=2)
{
	amplitude = (thick - wall) / 2;
	period = min(15, thick * 2);
	steps = quantup(segs(thick/2),4);
	step = period/steps;
	il = l - 2*strut + 2*step;
	linear_extrude(height=h-2*strut+0.1, steps=2, convexity=ceil(2*il/period), center=true) {
		polygon(
			points=concat(
				[for (y=[-il/2:step:il/2]) [amplitude*sin(y/period*360)-wall/2, y] ],
				[for (y=[il/2:-step:-il/2]) [amplitude*sin(y/period*360)+wall/2, y] ]
			)
		);
	}

	difference() {
		cube([thick, l, h], center=true);
		cube([thick+0.5, l-2*strut, h-2*strut], center=true);
	}
}



// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
