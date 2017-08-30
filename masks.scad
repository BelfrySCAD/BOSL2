//////////////////////////////////////////////////////////////////////
// Masking shapes.
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


module angle_half_pie_mask(
	ang=45, h=1,
	r=undef, r1=undef, r2=undef,
	d=1.0, d1=undef, d2=undef,
) {
	r  = (r  != undef)? r  : (d/2);
	r1 = (r1 != undef)? r1 : ((d1 != undef)? (d1/2) : r);
	r2 = (r2 != undef)? r2 : ((d2 != undef)? (d2/2) : r);
	rm = max(r1,r2);
	difference() {
		cylinder(h=h, r1=r1, r2=r2, center=true);
		translate([0, -rm/2, 0])
			cube(size=[rm*2+1, rm, h+1], center=true);
		zrot(ang) {
			translate([0, rm/2, 0]) {
				cube(size=[rm*2.1, rm, h+1], center=true);
			}
		}
	}
}


// Creates a pie wedge shape that can be used to mask other shapes.
// You must specify either r or d, or their r1/r2, d1/d2 variants.
//   ang = angle of wedge in degrees.
//   h = height of wedge.
//   r = Radius of circle wedge is created from. (optional)
//   r1 = Bottom radius of cone that wedge is created from.  (optional)
//   r2 = Upper radius of cone that wedge is created from.  (optional)
//   d = Diameter of circle wedge is created from. (optional)
//   d1 = Bottom diameter of cone that wedge is created from.  (optional)
//   d2 = Upper diameter of cone that wedge is created from. (optional)
// Example:
//   angle_pie_mask(ang=30, d=100, h=20);
module angle_pie_mask(
	ang=45, h=1,
	r=undef, r1=undef, r2=undef,
	d=1.0, d1=undef, d2=undef,
) {
	a1 = min(ang, 180.0);
	a2 = max(0.0, ang-180.0);
	r  = (r  != undef)? r  : (d/2);
	r1 = (r1 != undef)? r1 : ((d1 != undef)? (d1/2) : r);
	r2 = (r2 != undef)? r2 : ((d2 != undef)? (d2/2) : r);
	union() {
		angle_half_pie_mask(h=h, r1=r1, r2=r2, ang=a1);
		if (a2 > 0.0) {
			zrot(180) angle_half_pie_mask(h=h, r1=r1, r2=r2, ang=a2);
		}
	}
}


// Creates a shape that can be used to chamfer a 90 degree edge along the Z axis.
// Difference it from the object to be chamfered.  The center of the mask
// object should align exactly with the edge to be chamfered.
//   l = Height of mask
//   chamfer = size of chamfer
// Example:
//   chamfer_mask_z(l=10.0, chamfer=2.0);
module chamfer_mask_z(l=1.0, chamfer=1.0) {
	zrot(45) cube(size=[chamfer*sqrt(2.0), chamfer*sqrt(2.0), l], center=true);
}


// Creates a shape that can be used to chamfer a 90 degree edge along the Y axis.
// Difference it from the object to be chamfered.  The center of the mask
// object should align exactly with the edge to be chamfered.
//   l = Height of mask
//   chamfer = size of chamfer
// Example:
//   chamfer_mask_y(l=10.0, chamfer=2.0);
module chamfer_mask_y(l=1.0, chamfer=1.0) {xrot(90) chamfer_mask(h=l, r=chamfer);}


// Creates a shape that can be used to chamfer a 90 degree edge along the X axis.
// Difference it from the object to be chamfered.  The center of the mask
// object should align exactly with the edge to be chamfered.
//   l = Height of mask
//   chamfer = size of chamfer
// Example:
//   chamfer_mask_x(l=10.0, chamfer=2.0);
module chamfer_mask_x(l=1.0, chamfer=1.0) {yrot(90) chamfer_mask(h=l, r=chamfer);}


// Chamfers the edges of a cuboid region containing the given children.
//   chamfer = inset of the chamfer from the edge. (Default: 1)
//   size = The size of the rectangular cuboid we want to chamfer.
//   edges = which edges do we want to chamfer.
//           [
//               [Y+Z+, Y-Z+, Y-Z-, Y+Z-],
//               [X+Z+, X-Z+, X-Z-, X+Z-],
//               [X+Y+, X-Y+, X-Y-, X+Y-]
//           ]
// Example:
//   chamfer(chamfer=2, size=[10,40,90], edges=[[0,0,0,0], [1,1,0,0], [0,0,0,0]]) {
//     cube(size=[10,40,90], center=true);
//   }
module chamfer(chamfer=1, size=[1,1,1], edges=[[0,0,0,0], [1,1,0,0], [0,0,0,0]])
{
	eps = 0.1;
	x = size[0];
	y = size[1];
	z = size[2];
	lx = x + eps;
	ly = y + eps;
	lz = z + eps;
	difference() {
		union() {
			children();
		}
		union() {
			if (edges[0][0] != 0)
				up(z/2) back(y/2) chamfer_mask_x(l=lx, chamfer=chamfer);
			if (edges[0][1] != 0)
				up(z/2) fwd(y/2) chamfer_mask_x(l=lx, chamfer=chamfer);
			if (edges[0][2] != 0)
				down(z/2) back(y/2) chamfer_mask_x(l=lx, chamfer=chamfer);
			if (edges[0][3] != 0)
				down(z/2) fwd(y/2) chamfer_mask_x(l=lx, chamfer=chamfer);

			if (edges[1][0] != 0)
				up(z/2) right(x/2) chamfer_mask_y(l=ly, chamfer=chamfer);
			if (edges[1][1] != 0)
				up(z/2) left(x/2) chamfer_mask_y(l=ly, chamfer=chamfer);
			if (edges[1][2] != 0)
				down(z/2) right(x/2) chamfer_mask_y(l=ly, chamfer=chamfer);
			if (edges[1][3] != 0)
				down(z/2) left(x/2) chamfer_mask_y(l=ly, chamfer=chamfer);

			if (edges[2][0] != 0)
				back(y/2) right(x/2) chamfer_mask_z(l=lz, chamfer=chamfer);
			if (edges[2][1] != 0)
				back(y/2) left(x/2) chamfer_mask_z(l=lz, chamfer=chamfer);
			if (edges[2][2] != 0)
				fwd(y/2) right(x/2) chamfer_mask_z(l=lz, chamfer=chamfer);
			if (edges[2][3] != 0)
				fwd(y/2) left(x/2) chamfer_mask_z(l=lz, chamfer=chamfer);
		}
	}
}


// Creates a shape that can be used to fillet a vertical 90 degree edge.
// Difference it from the object to be filletted.  The center of the mask
// object should align exactly with the edge to be filletted.
//   h = height of vertical mask.
//   r = radius of the fillet.
//   center = If true, vertically center mask.
// Example:
//   difference() {
//       cube(size=100, center=false);
//       up(50) fillet_mask(h=100.1, r=10.0);
//   }
module fillet_mask(h=1.0, r=1.0, center=true)
{
	n = ceil(segs(r)/4)*4;
	linear_extrude(height=h, convexity=4, center=center) {
		polygon(
			points=concat(
				[for (a = [  0:360/n: 90]) [r*cos(a)-r, r*sin(a)-r]],
				[for (a = [270:360/n:360]) [r*cos(a)-r, r*sin(a)+r]],
				[for (a = [180:360/n:270]) [r*cos(a)+r, r*sin(a)+r]],
				[for (a = [ 90:360/n:180]) [r*cos(a)+r, r*sin(a)-r]]
			)
		);
	}
}
module fillet_mask_z(l=1.0, r=1.0) fillet_mask(h=l, r=r, center=true);
module fillet_mask_y(l=1.0, r=1.0) xrot(90) fillet_mask(h=l, r=r, center=true);
module fillet_mask_x(l=1.0, r=1.0) yrot(90) fillet_mask(h=l, r=r, center=true);


// Creates a vertical mask that can be used to fillet the edge where two
// face meet, at any arbitrary angle.  Difference it from the object to
// be filletted.  The center of the mask should align exactly with the
// edge to be filletted.
//   h = height of vertical mask.
//   r = radius of the fillet.
//   ang = angle that the planes meet at.
//   center = If true, vertically center mask.
// Example:
//   fillet_angled_edge_mask(h=50.0, r=10.0, ang=120, $fn=32);
//   fillet_angled_edge_mask(h=50.0, r=10.0, ang=30, $fn=32);
module fillet_angled_edge_mask(h=1.0, r=1.0, ang=90, center=true)
{
	sweep = 180-ang;
	n = ceil(segs(r)*sweep/360);
	x = r*sin(90-(ang/2))/sin(ang/2);
	linear_extrude(height=h, convexity=4, center=center) {
		polygon(
			points=concat(
				[for (i = [0:n]) let (a=90+ang+i*sweep/n) [r*cos(a)+x, r*sin(a)+r]],
				[for (i = [0:n]) let (a=90+i*sweep/n) [r*cos(a)+x, r*sin(a)-r]],
				[
					[min(-1, r*cos(270-ang)+x-1), r*sin(270-ang)-r],
					[min(-1, r*cos(90+ang)+x-1), r*sin(90+ang)+r],
				]
			)
		);
	}
}


// Creates a shape that can be used to fillet the corner of an angle.
// Difference it from the object to be filletted.  The center of the mask
// object should align exactly with the point of the corner to be filletted.
//   fillet = radius of the fillet.
//   ang = angle between planes that you need to fillet the corner of.
// Example:
//   fillet_angled_corner_mask(fillet=100, ang=90);
module fillet_angled_corner_mask(fillet=1.0, ang=90)
{
	dy = fillet * tan(ang/2);
	th = max(dy, fillet*2);
	difference() {
		down(dy) {
			up(th/2) {
				forward(fillet) {
					cube(size=[fillet*2, fillet*4, th], center=true);
				}
			}
		}
		down(dy) {
			forward(fillet) {
				grid_of(count=2, spacing=fillet*2) {
					sphere(r=fillet);
				}
				xrot(ang) {
					up(fillet*2) {
						cube(size=[fillet*8, fillet*8, fillet*4], center=true);
					}
				}
			}
		}
	}
}


// Creates a shape that you can use to round 90 degree corners on a fillet.
// Difference it from the object to be filletted.  The center of the mask
// object should align exactly with the corner to be filletted.
//   r = radius of corner fillet.
// Example:
//   $fa=1; $fs=1;
//   difference() {
//     cube(size=[6,10,16], center=true);
//     translate([0, 5, 8]) yrot(90) fillet_mask(h=7, r=3);
//     translate([3, 0, 8]) xrot(90) fillet_mask(h=11, r=3);
//     translate([3, 5, 0]) fillet_mask(h=17, r=3);
//     translate([3, 5, 8]) fillet_corner_mask(r=3);
//   }
module fillet_corner_mask(r=1.0)
{
	difference() {
		cube(size=r*2, center=true);
		grid_of(count=[2,2,2], spacing=r*2-0.05) {
			sphere(r=r, center=true);
		}
	}
}
//!fillet_corner_mask(r=10.0);


// Create a mask that can be used to round the end of a cylinder.
// Difference it from the cylinder to be filletted.  The center of the
// mask object should align exactly with the center of the end of the
// cylinder to be filletted.
//   r = radius of cylinder to fillet. (Default: 1.0)
//   fillet = radius of the edge filleting. (Default: 0.25)
//   xtilt = angle of tilt of end of cylinder in the X direction. (Default: 0)
//   ytilt = angle of tilt of end of cylinder in the Y direction. (Default: 0)
// Example:
//   $fa=2; $fs=2;
//   difference() {
//     cylinder(r=50, h=100, center=true);
//     translate([0, 0, 50])
//       fillet_cylinder_mask(r=50, fillet=10, xtilt=30, ytilt=30);
//   }
module fillet_cylinder_mask(r=1.0, fillet=0.25, xtilt=0, ytilt=0)
{
	dhx = 2*r*sin(xtilt);
	dhy = 2*r*sin(ytilt);
	dh = hypot(dhy, dhx);
	down(dh/2) {
		skew_xz(zang=xtilt) {
			skew_yz(zang=ytilt) {
				down(fillet) {
					difference() {
						up((dh+2*fillet)/2) {
							cube(size=[r*2+10, r*2+10, dh+2*fillet], center=true);
						}
						torus(or=r, ir=r-2*fillet);
						cylinder(r=r-fillet, h=2*fillet, center=true);
					}
				}
			}
		}
	}
}



// Create a mask that can be used to round the edge of a circular hole.
// Difference it from the hole to be filletted.  The center of the
// mask object should align exactly with the center of the end of the
// hole to be filletted.
//   r = radius of hole to fillet. (Default: 1.0)
//   fillet = radius of the edge filleting. (Default: 0.25)
//   xtilt = angle of tilt of end of cylinder in the X direction. (Default: 0)
//   ytilt = angle of tilt of end of cylinder in the Y direction. (Default: 0)
// Example:
//   $fa=2; $fs=2;
//   difference() {
//     cube([150,150,100], center=true);
//     cylinder(r=50, h=100.1, center=true);
//     up(50) fillet_hole_mask(r=50, fillet=10, xtilt=0, ytilt=0);
//   }
module fillet_hole_mask(r=1.0, fillet=0.25, xtilt=0, ytilt=0)
{
	skew_xz(zang=xtilt) {
		skew_yz(zang=ytilt) {
			difference() {
				cylinder(r=r+fillet, h=2*fillet, center=true);
				down(fillet) torus(ir=r, or=r+2*fillet);
			}
		}
	}
}


// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
