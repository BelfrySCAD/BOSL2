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
include <shapes.scad>
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
//   difference() {
//       down(5) cube(10);
//       chamfer_mask_z(l=10.1, chamfer=2.0);
//   }
module chamfer_mask_z(l=1.0, chamfer=1.0) {
	zrot(45) cube(size=[chamfer*sqrt(2.0), chamfer*sqrt(2.0), l], center=true);
}


// Creates a shape that can be used to chamfer a 90 degree edge along the Y axis.
// Difference it from the object to be chamfered.  The center of the mask
// object should align exactly with the edge to be chamfered.
//   l = Height of mask
//   chamfer = size of chamfer
// Example:
//   difference() {
//       fwd(5) cube(10);
//       chamfer_mask_y(l=10.1, chamfer=2.0);
//   }
module chamfer_mask_y(l=1.0, chamfer=1.0) {
	xrot(90) chamfer_mask_z(l=l, chamfer=chamfer);
}


// Creates a shape that can be used to chamfer a 90 degree edge along the X axis.
// Difference it from the object to be chamfered.  The center of the mask
// object should align exactly with the edge to be chamfered.
//   l = Height of mask
//   chamfer = size of chamfer
// Example:
//   difference() {
//       left(5) cube(10);
//       chamfer_mask_x(l=10.1, chamfer=2.0);
//   }
module chamfer_mask_x(l=1.0, chamfer=1.0) {
	yrot(90) chamfer_mask_z(l=l, chamfer=chamfer);
}


// Chamfers the edges of a cuboid region containing the given children.
//   chamfer = Inset of the chamfer from the edge. (Default: 1)
//   size = The size of the rectangular cuboid we want to chamfer.
//   edges = Which edges do we want to chamfer.  Recommend to use EDGE constants from constants.scad.
//           [
//               [Y+Z+, Y-Z+, Y-Z-, Y+Z-],
//               [X+Z+, X-Z+, X-Z-, X+Z-],
//               [X+Y+, X-Y+, X-Y-, X+Y-]
//           ]
// Example:
//   include <BOSL/constants.scad>
//   chamfer(chamfer=2, size=[10,40,30], edges=EDGE_BOT_BK + EDGE_TOP_RT + EDGE_TOP_LF) {
//     cube(size=[10,40,30], center=true);
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
			if (edges[0][0] > 0)
				up(z/2) back(y/2) chamfer_mask_x(l=lx, chamfer=chamfer);
			if (edges[0][1] > 0)
				up(z/2) fwd(y/2) chamfer_mask_x(l=lx, chamfer=chamfer);
			if (edges[0][2] > 0)
				down(z/2) back(y/2) chamfer_mask_x(l=lx, chamfer=chamfer);
			if (edges[0][3] > 0)
				down(z/2) fwd(y/2) chamfer_mask_x(l=lx, chamfer=chamfer);

			if (edges[1][0] > 0)
				up(z/2) right(x/2) chamfer_mask_y(l=ly, chamfer=chamfer);
			if (edges[1][1] > 0)
				up(z/2) left(x/2) chamfer_mask_y(l=ly, chamfer=chamfer);
			if (edges[1][2] > 0)
				down(z/2) right(x/2) chamfer_mask_y(l=ly, chamfer=chamfer);
			if (edges[1][3] > 0)
				down(z/2) left(x/2) chamfer_mask_y(l=ly, chamfer=chamfer);

			if (edges[2][0] > 0)
				back(y/2) right(x/2) chamfer_mask_z(l=lz, chamfer=chamfer);
			if (edges[2][1] > 0)
				back(y/2) left(x/2) chamfer_mask_z(l=lz, chamfer=chamfer);
			if (edges[2][2] > 0)
				fwd(y/2) right(x/2) chamfer_mask_z(l=lz, chamfer=chamfer);
			if (edges[2][3] > 0)
				fwd(y/2) left(x/2) chamfer_mask_z(l=lz, chamfer=chamfer);
		}
	}
}


// Create a mask that can be used to bevel/chamfer the end of a cylinder.
// Difference it from the cylinder to be chamferred.  The center of the mask object
// should align exactly with the center of the end of the cylinder to be chamferred.
//   r = Radius of cylinder to chamfer.
//   d = Diameter of cylinder to chamfer. Use instead of r.
//   chamfer = Size of the edge chamferred, inset from edge. (Default: 0.25)
//   ang = Angle of chamfer in degrees from vertical.  (Default: 45)
//   from_end = If true, chamfer size is measured from end of cylinder.  If false, chamfer is measured outset from the radius of the cylinder.  (Default: false)
// Example:
//   $fa=2; $fs=2;
//   difference() {
//       cylinder(r=50, h=100, center=true);
//       up(50) chamfer_cylinder_mask(r=50, chamfer=10);
//   }
module chamfer_cylinder_mask(r=1.0, d=undef, chamfer=0.25, ang=45, from_end=false)
{
	h = chamfer * (from_end? 1 : tan(90-ang));
	r = d==undef? r : d/2;
	r2 = r - chamfer * (from_end? tan(ang) : 1);
	difference() {
		cube([2*r+1, 2*r+1, 2*h], center=true);
		down(h+0.01) cylinder(r1=r, r2=r2, h=h+0.01, center=false);
	}
}



// Create a mask that can be used to bevel/chamfer the end of a cylindrical hole.
// Difference it from the hole to be chamferred.  The center of the mask object
// should align exactly with the center of the end of the hole to be chamferred.
//   r = Radius of hole to chamfer.
//   d = Diameter of hole to chamfer. Use instead of r.
//   chamfer = Size of the chamfer. (Default: 0.25)
//   ang = Angle of chamfer in degrees from vertical.  (Default: 45)
//   from_end = If true, chamfer size is measured from end of hole.  If false, chamfer is measured outset from the radius of the hole.  (Default: false)
// Example:
//   $fa=2; $fs=2;
//   difference() {
//       cube(100, center=true);
//       cylinder(d=50, h=100.1, center=true);
//       up(50) chamfer_hole_mask(d=50, chamfer=10);
//   }
module chamfer_hole_mask(r=1.0, d=undef, chamfer=0.25, ang=45, from_end=false)
{
	h = chamfer * (from_end? 1 : tan(90-ang));
	r = d==undef? r : d/2;
	r2 = r + chamfer * (from_end? tan(ang) : 1);
	down(h-0.01) cylinder(r1=r, r2=r2, h=h, center=false);
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
//       up(50) fillet_mask(h=100.1, r=25.0);
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


// Fillets the edges of a cuboid region containing the given children.
//   fillet = Radius of the fillet. (Default: 1)
//   size = The size of the rectangular cuboid we want to chamfer.
//   edges = Which edges do we want to chamfer.  Recommend to use EDGE constants from constants.scad.
//           [
//               [Y+Z+, Y-Z+, Y-Z-, Y+Z-],
//               [X+Z+, X-Z+, X-Z-, X+Z-],
//               [X+Y+, X-Y+, X-Y-, X+Y-]
//           ]
// Example:
//   include <BOSL/constants.scad>
//   fillet(fillet=10, size=[50,100,150], edges=EDGES_TOP + EDGES_RIGHT - EDGE_BOT_RT, $fn=24) {
//     cube(size=[50,100,150], center=true);
//   }
module fillet(fillet=1, size=[1,1,1], edges=[[0,0,0,0], [1,1,0,0], [0,0,0,0]])
{
	eps = 0.1;
	x = size[0];
	y = size[1];
	z = size[2];
	lx = x + eps;
	ly = y + eps;
	lz = z + eps;
	rx = x - 2*fillet;
	ry = y - 2*fillet;
	rz = z - 2*fillet;
	offsets = [
		[[0, 1, 1], [ 0,-1, 1], [ 0,-1,-1], [0, 1,-1]],
		[[1, 0, 1], [-1, 0, 1], [-1, 0,-1], [1, 0,-1]],
		[[1, 1, 0], [-1, 1, 0], [-1,-1, 0], [1,-1, 0]]
	];
	corners = [
		edges[0][2] + edges[1][2] + edges[2][2],
		edges[0][2] + edges[1][3] + edges[2][3],
		edges[0][3] + edges[1][2] + edges[2][1],
		edges[0][3] + edges[1][3] + edges[2][0],
		edges[0][1] + edges[1][1] + edges[2][2],
		edges[0][1] + edges[1][0] + edges[2][3],
		edges[0][0] + edges[1][1] + edges[2][1],
		edges[0][0] + edges[1][0] + edges[2][0]
	];
	majrots = [[0,90,0], [90,0,0], [0,0,0]];
	sides = quantup(segs(fillet),4);
	sc = 1/cos(180/sides);
	$fn = sides;
	difference() {
		children();
		for (axis=[0:2], i=[0:3]) {
			if (edges[axis][i]>0) {
				difference() {
					translate(vmul(offsets[axis][i], [lx,ly,lz]/2))  {
						rotate(majrots[axis]) {
							cube([fillet*2, fillet*2, size[axis]+eps], center=true);
						}
					}
					translate(vmul(offsets[axis][i], [rx,ry,rz]/2))  {
						rotate(majrots[axis]) {
							zrot(180/sides) cylinder(h=size[axis]+eps*2, r=fillet*sc, center=true);
						}
					}
				}
			}
		}
		for (za=[0,1], ya=[0,1], xa=[0,1]) {
			idx = xa + 2*ya + 4*za;
			if (corners[idx] > 2) {
				difference() {
					translate([(xa-0.5)*lx, (ya-0.5)*ly, (za-0.5)*lz]) {
						cube(fillet*2, center=true);
					}
					translate([(xa-0.5)*rx, (ya-0.5)*ry, (za-0.5)*rz]) {
						zrot(180/sides) {
							rotate_extrude(convexity=2) {
								difference() {
									zrot(180/sides) circle(r=fillet*sc*sc);
									left(fillet*2) square(fillet*2*2, center=true);
								}
							}
						}
					}
				}
			}
		}
	}
}


// Creates a vertical mask that can be used to fillet the edge where two
// face meet, at any arbitrary angle.  Difference it from the object to
// be filletted.  The center of the mask should align exactly with the
// edge to be filletted.
//   h = height of vertical mask.
//   r = radius of the fillet.
//   ang = angle that the planes meet at.
//   center = If true, vertically center mask.
// Example:
//   difference() {
//       angle_pie_mask(ang=70, h=50, d=100);
//       fillet_angled_edge_mask(h=51, r=20.0, ang=70, $fn=32);
//   }
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
//   ang=60;
//   difference() {
//       angle_pie_mask(ang=ang, h=50, r=200);
//       up(50/2) {
//           fillet_angled_corner_mask(fillet=20, ang=ang);
//           zrot_copies([0, ang]) right(200/2) fillet_mask_x(l=200, r=20);
//       }
//       fillet_angled_edge_mask(h=51, r=20, ang=ang);
//   }
module fillet_angled_corner_mask(fillet=1.0, ang=90)
{
	dx = fillet / tan(ang/2);
	fn = quantup(segs(fillet), 4);
	difference() {
		down(fillet) cylinder(r=dx/cos(ang/2)+1, h=fillet+1, center=false);
		yflip_copy() {
			translate([dx, fillet, -fillet]) {
				hull() {
					sphere(r=fillet, $fn=fn);
					down(fillet*3) sphere(r=fillet, $fn=fn);
					zrot_copies([0,ang]) {
						right(fillet*3) sphere(r=fillet, $fn=fn);
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
//     up(50) !fillet_cylinder_mask(r=50, fillet=10, xtilt=30);
//   }
module fillet_cylinder_mask(r=1.0, fillet=0.25, xtilt=0, ytilt=0)
{
	dhx = 2*r*sin(xtilt);
	dhy = 2*r*sin(ytilt);
	dh = hypot(dhy, dhx);
	down(dh/2) {
		skew_xz(za=xtilt) {
			skew_yz(za=ytilt) {
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
	skew_xz(za=xtilt) {
		skew_yz(za=ytilt) {
			difference() {
				cylinder(r=r+fillet, h=2*fillet, center=true);
				down(fillet) torus(ir=r, or=r+2*fillet);
			}
		}
	}
}


// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
