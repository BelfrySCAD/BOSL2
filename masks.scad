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


use <transforms.scad>
use <shapes.scad>
use <math.scad>
include <constants.scad>


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


// Creates a shape that can be used to chamfer a 90 degree edge.
// Difference it from the object to be chamfered.  The center of
// the mask object should align exactly with the edge to be chamfered.
//   l = Height of mask
//   chamfer = Size of chamfer
//   orient = Orientation of the cylinder.  Use the ORIENT_ constants from constants.h.  Default: vertical.
//   align = Alignment of the cylinder.  Use the V_ constants from constants.h.  Default: centered.
// Example:
//   difference() {
//       cube(50);
//       #chamfer_mask(l=50.1, chamfer=10.0, orient=ORIENT_X, align=V_RIGHT);
//   }
module chamfer_mask(l=1.0, chamfer=1.0, orient=ORIENT_Z, align=V_ZERO) {
	cyl(d=chamfer*2, l=l, align=align, orient=orient, $fn=4);
}


// Creates a shape that can be used to chamfer a 90 degree edge along the Z axis.
// Difference it from the object to be chamfered.  The center of the mask
// object should align exactly with the edge to be chamfered.
//   l = Height of mask
//   chamfer = size of chamfer
//   align = Alignment of the cylinder.  Use the V_ constants from constants.h.  Default: centered.
// Example:
//   difference() {
//       down(5) cube(10);
//       chamfer_mask_z(l=10.1, chamfer=2.0);
//   }
module chamfer_mask_z(l=1.0, chamfer=1.0, align=V_ZERO) {
	chamfer_mask(l=l, chamfer=chamfer, orient=ORIENT_Z, align=align);
}


// Creates a shape that can be used to chamfer a 90 degree edge along the Y axis.
// Difference it from the object to be chamfered.  The center of the mask
// object should align exactly with the edge to be chamfered.
//   l = Height of mask
//   chamfer = size of chamfer
//   align = Alignment of the cylinder.  Use the V_ constants from constants.h.  Default: centered.
// Example:
//   difference() {
//       fwd(5) cube(10);
//       chamfer_mask_y(l=10.1, chamfer=2.0);
//   }
module chamfer_mask_y(l=1.0, chamfer=1.0, align=V_ZERO) {
	chamfer_mask(l=l, chamfer=chamfer, orient=ORIENT_Y, align=align);
}


// Creates a shape that can be used to chamfer a 90 degree edge along the X axis.
// Difference it from the object to be chamfered.  The center of the mask
// object should align exactly with the edge to be chamfered.
//   l = Height of mask
//   chamfer = size of chamfer
//   align = Alignment of the cylinder.  Use the V_ constants from constants.h.  Default: centered.
// Example:
//   difference() {
//       left(5) cube(10);
//       chamfer_mask_x(l=10.1, chamfer=2.0);
//   }
module chamfer_mask_x(l=1.0, chamfer=1.0, align=V_ZERO) {
	chamfer_mask(l=l, chamfer=chamfer, orient=ORIENT_X, align=align);
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


// Create a mask that can be used to bevel/chamfer the end of a cylindrical region.
// Difference it from the end of the region to be chamferred.  The center of the mask
// object should align exactly with the center of the end of the cylindrical region
// to be chamferred.
//   r = Radius of cylinder to chamfer.
//   d = Diameter of cylinder to chamfer. Use instead of r.
//   chamfer = Size of the edge chamferred, inset from edge. (Default: 0.25)
//   ang = Angle of chamfer in degrees from vertical.  (Default: 45)
//   from_end = If true, chamfer size is measured from end of cylinder.  If false, chamfer is measured outset from the radius of the cylinder.  (Default: false)
//   orient = Orientation of the mask.  Use the `ORIENT_` constants from `constants.h`.  Default: ORIENT_Z.
// Example:
//   $fa=2; $fs=2;
//   difference() {
//       cylinder(r=50, h=100, center=true);
//       up(50) !chamfer_cylinder_mask(r=50, chamfer=10);
//   }
module chamfer_cylinder_mask(r=1.0, d=undef, chamfer=0.25, ang=45, from_end=false, orient=ORIENT_Z)
{
	r = get_radius(r=r, d=d, dflt=1);
	rot(orient) cylinder_mask(l=chamfer*3, r=r, chamfer2=chamfer, chamfang2=ang, from_end=from_end, ends_only=true, align=V_DOWN);
}


// If passed children, bevels/chamfers and/or rounds/fillets the ends of the
// cylindrical/conical region specified.  If passed no children, creates
// a mask to bevel/chamfer and/or fillet the ends of the cylindrical
// region specified.  Difference the mask from the region.  The center
// of the mask object should align exactly with the center of the
// cylindrical region to be chamferred.
//   l = Length of the cylindrical/conical region.
//   r = Radius of cylindrical region to chamfer.
//   r1 = Radius of axis-negative end of the region to chamfer.
//   r2 = Radius of axis-positive end of the region to chamfer.
//   d = Diameter of cylindrical region to chamfer.
//   d1 = Diameter of axis-negative end of the region to chamfer.
//   d1 = Diameter of axis-positive end of the region to chamfer.
//   chamfer = Size of the chamfers/bevels. (Default: 0.25)
//   chamfer1 = Size of the chamfers/bevels for the axis-negative end of the region.
//   chamfer2 = Size of the chamfers/bevels for the axis-positive end of the region.
//   chamfang = Angle of chamfers/bevels in degrees from the length axis of the region.  (Default: 45)
//   chamfang1 = Angle of chamfer/bevel of the axis-negative end of the region, in degrees from the length axis.
//   chamfang2 = Angle of chamfer/bevel of the axis-positive end of the region, in degrees from the length axis.
//   fillet = The radius of the fillets on the ends of the region.  Default: none.
//   fillet1 = The radius of the fillet on the axis-negative end of the region.
//   fillet2 = The radius of the fillet on the axis-positive end of the region.
//   circum = If true, region will circumscribe the circle of the given radius/diameter.
//   from_end = If true, chamfer/bevel size is measured from end of region.  If false, chamfer/bevel is measured outset from the radius of the region.  (Default: false)
//   overage = The extra thickness of the mask.  Default: `10`.
//   ends_only = If true, only mask the ends and not around the middle of the cylinder.
//   orient = Orientation.  Use the `ORIENT_` constants from `constants.scad`.  Default: `ORIENT_Z`.
//   align = Alignment of the region.  Use the `V_` constants from `constants.scad`.  Default: `V_ZERO`.
// Example:
//   $fa=2; $fs=2;
//   difference() {
//       cylinder(h=100, r1=60, r2=30, center=true);
//       cylinder_mask(l=100, r1=60, r2=30, chamfer=10, from_end=true);
//   }
//   cylinder_mask(l=100, r=50, chamfer1=10, fillet2=10) {
//       cube([100,50,100], center=true);
//   }
module cylinder_mask(
	l,
	r=undef, r1=undef, r2=undef,
	d=undef, d1=undef, d2=undef,
	chamfer=undef, chamfer1=undef, chamfer2=undef,
	chamfang=undef, chamfang1=undef, chamfang2=undef,
	fillet=undef, fillet1=undef, fillet2=undef,
	circum=false, from_end=false,
	overage=10, ends_only=false,
	orient=ORIENT_Z, align=V_ZERO
) {
	r1 = get_radius(r=r, d=d, r1=r1, d1=d1, dflt=1);
	r2 = get_radius(r=r, d=d, r1=r2, d1=d2, dflt=1);
	sides = segs(max(r1,r2));
	sc = circum? 1/cos(180/sides) : 1;
	vang = atan2(l, r1-r2)/2;
	ang1 = first_defined([chamfang1, chamfang, vang]);
	ang2 = first_defined([chamfang2, chamfang, 90-vang]);
	cham1 = first_defined([chamfer1, chamfer, 0]);
	cham2 = first_defined([chamfer2, chamfer, 0]);
	fil1 = first_defined([fillet1, fillet, 0]);
	fil2 = first_defined([fillet2, fillet, 0]);
	maxd = max(r1,r2);
	if ($children > 0) {
		difference() {
			children();
			cylinder_mask(l=l, r1=sc*r1, r2=sc*r2, chamfer1=cham1, chamfer2=cham2, chamfang1=ang1, chamfang2=ang2, fillet1=fil1, fillet2=fil2, orient=orient, from_end=from_end);
		}
	} else {
		orient_and_align([2*r1, 2*r1, l], orient, align) {
			difference() {
				union() {
					chlen1 = cham1 / (from_end? 1 : tan(ang1));
					chlen2 = cham2 / (from_end? 1 : tan(ang2));
					if (!ends_only) {
						cylinder(r=maxd+overage, h=l+2*overage, center=true);
					} else {
						if (cham2>0) up(l/2-chlen2) cylinder(r=maxd+overage, h=chlen2+overage, center=false);
						if (cham1>0) down(l/2+overage) cylinder(r=maxd+overage, h=chlen1+overage, center=false);
						if (fil2>0) up(l/2-fil2) cylinder(r=maxd+overage, h=fil2+overage, center=false);
						if (fil1>0) down(l/2+overage) cylinder(r=maxd+overage, h=fil1+overage, center=false);
					}
				}
				cyl(r1=sc*r1, r2=sc*r2, l=l, chamfer1=cham1, chamfer2=cham2, chamfang1=ang1, chamfang2=ang2, from_end=from_end, fillet1=fil1, fillet2=fil2);
			}
		}
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
	majrots = [[0,90,0], [90,0,0], [0,0,0]];
	sides = quantup(segs(fillet),4);
	sc = 1/cos(180/sides);
	difference() {
		children();

		// Round edges.
		for (axis=[0:2], i=[0:3]) {
			if (edges[axis][i]>0) {
				difference() {
					translate(vmul(EDGE_OFFSETS[axis][i], [lx,ly,lz]/2))  {
						rotate(majrots[axis]) {
							cube([fillet*2, fillet*2, size[axis]+eps], center=true);
						}
					}
					translate(vmul(EDGE_OFFSETS[axis][i], [rx,ry,rz]/2))  {
						rotate(majrots[axis]) {
							zrot(180/sides) cylinder(h=size[axis]+eps*2, r=fillet*sc, center=true, $fn=sides);
						}
					}
				}
			}
		}

		// Round corners.
		for (za=[-1,1], ya=[-1,1], xa=[-1,1]) {
			if (corner_edge_count(edges, [xa,ya,za]) > 2) {
				difference() {
					translate(vmul([xa,ya,za]/2, [lx,ly,lz])) {
						cube(fillet*2, center=true);
					}
					translate(vmul([xa,ya,za]/2, [rx,ry,rz])) {
						zrot(180/sides) {
							rotate_extrude(convexity=2) {
								difference() {
									zrot(180/sides) circle(r=fillet*sc*sc, $fn=sides);
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
//     up(50) fillet_cylinder_mask(r=50, fillet=10, xtilt=30);
//   }
module fillet_cylinder_mask(r=1.0, fillet=0.25, xtilt=0, ytilt=0)
{
	skew_xz(za=xtilt) {
		skew_yz(za=ytilt) {
			cylinder_mask(l=fillet*3, r=r, fillet2=fillet, ends_only=true, align=V_DOWN);
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
