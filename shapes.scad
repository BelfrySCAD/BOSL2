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


use <transforms.scad>
use <math.scad>
include <constants.scad>


// For when you MUST pass a child to a module, but you want it to be nothing.
module nil() union() {}


// Creates a cube or cuboid object.
//   size = The size of the cube.
//   align = The side of the origin to align to.  Use V_ constants from constants.scad.
//   chamfer = Size of chamfer, inset from sides.  Default: No chamferring.
//   fillet = Radius of fillet for edge rounding.  Default: No filleting.
//   edges = Edges to chamfer/fillet.  Use EDGE constants from constants.scad. Default: EDGES_ALL
//   trimcorners = If true, rounds or chamfers corners where three chamferred/filleted edges meet.  Default: true
// Examples:
//   cuboid(40);
//   cuboid(40, align=V_UP+V_BACK);
//   cuboid([20,40,60]);
//   cuboid([30,40,60], chamfer=5);
//   cuboid([30,40,60], fillet=10);
//   cuboid([30,40,60], chamfer=5, edges=EDGE_TOP_FR+EDGE_TOP_RT+EDGE_FR_RT, $fn=24);
//   cuboid([30,40,60], fillet=5, edges=EDGE_TOP_FR+EDGE_TOP_RT+EDGE_FR_RT, $fn=24);
module cuboid(
	size=[1,1,1],
	align=[0,0,0],
	chamfer=undef,
	fillet=undef,
	edges=EDGES_ALL,
	trimcorners=true
) {
	size = scalar_vec(size);
	majrots = [[0,90,0], [90,0,0], [0,0,0]];
	if (chamfer != undef) {
		if (version_num()>20190000) {
			assert(chamfer <= min(size)/2, "chamfer must be smaller than half the cube width, length, or height.");
		} else {
			if(chamfer > min(size)/2) {
				echo("WARNING: chamfer must be smaller than half the cube width, length, or height.");
			}
		}
	}
	if (fillet != undef) {
		if (version_num()>20190000) {
			assert(fillet <= min(size)/2, "fillet must be smaller than half the cube width, length, or height.");
		} else {
			if(fillet > min(size)/2) {
				echo("WARNING: fillet must be smaller than half the cube width, length, or height.");
			}
		}
	}
	translate(vmul(size/2, align)) {
		if (chamfer != undef) {
			isize = [for (v = size) max(0.001, v-2*chamfer)];
			if (edges == EDGES_ALL && trimcorners) {
				hull() {
					cube([size[0], isize[1], isize[2]], center=true);
					cube([isize[0], size[1], isize[2]], center=true);
					cube([isize[0], isize[1], size[2]], center=true);
				}
			} else {
				difference() {
					cube(size, center=true);

					// Chamfer edges
					for (i = [0:3], axis=[0:2]) {
						if (edges[axis][i]>0) {
							translate(vmul(EDGE_OFFSETS[axis][i], size/2)) {
								rotate(majrots[axis]) {
									zrot(45) cube([chamfer*sqrt(2), chamfer*sqrt(2), size[axis]+0.01], center=true);
								}
							}
						}
					}

					// Chamfer triple-edge corners.
					if (trimcorners) {
						for (za=[-1,1], ya=[-1,1], xa=[-1,1]) {
							if (corner_edge_count(edges, [xa,ya,za]) > 2) {
								translate(vmul([xa,ya,za]/2, size-[1,1,1]*chamfer*4/3)) {
									rotate_from_to(V_UP, [xa,ya,za]) {
										upcube(chamfer*3);
									}
								}
							}
						}
					}
				}
			}
		} else if (fillet != undef) {
			sides = quantup(segs(fillet),4);
			sc = 1/cos(180/sides);
			isize = [for (v = size) max(0.001, v-2*fillet)];
			if (edges == EDGES_ALL) {
				minkowski() {
					cube(isize, center=true);
					if (trimcorners) {
						sphere(r=fillet*sc, $fn=sides);
					} else {
						intersection() {
							zrot(180/sides) cylinder(r=fillet*sc, h=fillet*2, center=true, $fn=sides);
							rotate([90,0,0]) zrot(180/sides) cylinder(r=fillet*sc, h=fillet*2, center=true, $fn=sides);
							rotate([0,90,0]) zrot(180/sides) cylinder(r=fillet*sc, h=fillet*2, center=true, $fn=sides);
						}
					}
				}
			} else {
				difference() {
					cube(size, center=true);

					// Round edges.
					for (i = [0:3], axis=[0:2]) {
						if (edges[axis][i]>0) {
							difference() {
								translate(vmul(EDGE_OFFSETS[axis][i], size/2)) {
									rotate(majrots[axis]) cube([fillet*2, fillet*2, size[axis]+0.1], center=true);
								}
								translate(vmul(EDGE_OFFSETS[axis][i], size/2 - [1,1,1]*fillet)) {
									rotate(majrots[axis]) zrot(180/sides) cylinder(h=size[axis]+0.2, r=fillet*sc, center=true, $fn=sides);
								}
							}
						}
					}

					// Round triple-edge corners.
					if (trimcorners) {
						for (za=[-1,1], ya=[-1,1], xa=[-1,1]) {
							if (corner_edge_count(edges, [xa,ya,za]) > 2) {
								difference() {
									translate(vmul([xa,ya,za], size/2)) {
										cube(fillet*2, center=true);
									}
									translate(vmul([xa,ya,za], size/2-[1,1,1]*fillet)) {
										zrot(180/sides) sphere(r=fillet*sc*sc, $fn=sides);
									}
								}
							}
						}
					}
				}
			}
		} else {
			cube(size=size, center=true);
		}
	}
}



// Creates a cube between two points.
//   p1 = Coordinate point of one cube corner.
//   p2 = Coordinate point of opposite cube corner.
// Example:
//   cube2pt([10,20,30], [40,-10,10]);
module cube2pt(p1,p2) {
	translate([min(p1[0],p2[0]), min(p1[1],p2[1]), min(p1[2],p2[2])]) {
		cube([abs(p2[0]-p1[0]), abs(p2[1]-p1[1]), abs(p2[2]-p1[2])], center=false);
	}
}


// Creates a cube that spans the X, Y, and Z ranges given.
//   xspan = [min, max] X axis range.
//   yspan = [min, max] Y axis range.
//   zspan = [min, max] Z axis range.
// Example:
//   span_cube([10,40], [-10, 20], [10,30]);
module span_cube(xspan, yspan, zspan) {
	cube2pt([xspan[0], yspan[0], zspan[0]], [xspan[1], yspan[1], zspan[1]]);
}




// Makes a cube that is offset along the given vector by half the cube's size.
// For example, if v=[-1,1,0], the cube's front right edge will be centered at the origin.
//   size = size of cube.
//   v = vector to offset along.
// Example:
//   offsetcube([3,4,5], [-1,1,0]);
module offsetcube(size=[1,1,1], v=[0,0,0]) {
	echo("DEPRECATED: You should use cuboid() instead of offsetcube()");
	cuboid(size=size, align=v);
}


// Makes a cube that has its right face centered at the origin.
module leftcube(size=[1,1,1]) cuboid(size=size, align=V_LEFT);


// Makes a cube that has its left face centered at the origin.
module rightcube(size=[1,1,1]) cuboid(size=size, align=V_RIGHT);


// Makes a cube that has its back face centered at the origin.
module fwdcube(size=[1,1,1]) cuboid(size=size, align=V_FWD);


// Makes a cube that has its front face centered at the origin.
module backcube(size=[1,1,1]) cuboid(size=size, align=V_BACK);


// Makes a cube that has its top face centered at the origin.
module downcube(size=[1,1,1]) cuboid(size=size, align=V_DOWN);


// Makes a cube that has its bottom face centered at the origin.
module upcube(size=[1,1,1]) cuboid(size=size, align=V_UP);


// Makes a cube with chamfered edges.
//   size = size of cube [X,Y,Z].  (Default: [1,1,1])
//   chamfer = chamfer inset along axis.  (Default: 0.25)
//   chamfaxes = Array [X, Y, Z] of boolean values to specify which axis edges should be chamfered.
//   chamfcorners = boolean to specify if corners should be flat chamferred.
// Example:
//   chamfcube(size=[10,30,50], chamfer=1, chamfaxes=[1,1,1], chamfcorners=true);
module chamfcube(size=[1,1,1], chamfer=0.25, chamfaxes=[1,1,1], chamfcorners=false) {
	echo("DEPRECATED: Use cuboid() instead of chamfcube()");
	cuboid(
		size=size,
		chamfer=chamfer,
		trimcorners=chamfcorners,
		edges = (
			(chamfaxes[0]? EDGES_X_ALL : EDGES_NONE) +
			(chamfaxes[1]? EDGES_Y_ALL : EDGES_NONE) +
			(chamfaxes[2]? EDGES_Z_ALL : EDGES_NONE)
		)
	);
}


// Makes a cube with rounded (filletted) vertical edges. The r size will be
// limited to a maximum of half the length of the shortest XY side.
//   size = size of cube [X,Y,Z].  (Default: [1,1,1])
//   r = radius of edge/corner rounding.  (Default: 0.25)
//   center = if true, object will be centered.  If false, sits on top of XY plane.
// Examples:
//   rrect(size=[9,4,1], r=1, center=true);
//   rrect(size=[5,7,3], r=1, $fn=24);
module rrect(size=[1,1,1], r=0.25, center=false) {
	echo("DEPRECATED: Use cuboid() instead of rrect()");
	cuboid(size=size, filler=r, edges=EDGES_Z_ALL, align=center? V_ZERO : V_UP);
}


// Makes a cube with rounded (filletted) edges and corners.  The r size will be
// limited to a maximum of half the length of the shortest side.
//   size = size of cube [X,Y,Z].  (Default: [1,1,1])
//   r = radius of edge/corner rounding.  (Default: 0.25)
//   center = if true, object will be centered.  If false, sits on top of XY plane.
// Examples:
//   rcube(size=[9,4,1], r=0.333, center=true, $fn=24);
//   rcube(size=[5,7,3], r=1);
module rcube(size=[1,1,1], r=0.25, center=false) {
	echo("DEPRECATED: Use cuboid() instead of rcube()");
	cuboid(size=size, fillet=r, align=center? V_ZERO : V_UP);
}



// Creates cylinders in various alignments and orientations,
// with optional fillets and chamfers.
//   l = Length of cylinder along axis.
//   r = Radius of cylinder.
//   r1 = Radius of the negative (X-, Y-, Z-) end of cylinder.
//   r2 = Radius of the positive (X+, Y+, Z+) end of cylinder.
//   d = Diameter of cylinder.
//   d1 = Diameter of the negative (X-, Y-, Z-) end of cylinder.
//   d2 = Diameter of the positive (X+, Y+, Z+) end of cylinder.
//   chamfer = The size of the chamfers on the ends of the cylinder.  Default: none.
//   chamfer1 = The size of the chamfer on the axis-negative end of the cylinder.  Default: none.
//   chamfer2 = The size of the chamfer on the axis-positive end of the cylinder.  Default: none.
//   chamfang = The angle in degrees of the chamfers on the ends of the cylinder.
//   chamfang1 = The angle in degrees of the chamfer on the axis-negative end of the cylinder.
//   chamfang2 = The angle in degrees of the chamfer on the axis-positive end of the cylinder.
//   from_end = If true, chamfer is measured from the end of the cylinder, instead of inset from the edge.  Default: false.
//   fillet = The radius of the fillets on the ends of the cylinder.  Default: none.
//   fillet1 = The radius of the fillet on the axis-negative end of the cylinder.
//   fillet2 = The radius of the fillet on the axis-positive end of the cylinder.
//   circum = If true, cylinder should circumscribe the circle of the given size.  Otherwise inscribes.  Default: false
//   realign = If true, rotate the cylinder by half the angle of one face.
//   orient = Orientation of the cylinder.  Use the ORIENT_ constants from constants.h.  Default: vertical.
//   align = Alignment of the cylinder.  Use the V_ constants from constants.h.  Default: centered.
// Examples:
//   cyl(l=100, r=25);
//   cyl(l=100, r=25, orient=ORIENT_Y);
//   cyl(l=100, d1=50, d2=20);
//   cyl(l=100, r=25, chamfer=10);
//   cyl(l=100, r=25, fillet=10);
//   cyl(l=100, d1=50, d2=30, chamfer1=10, fillet2=8, from_end=true);
module cyl(
	l=1,
	r=undef, r1=undef, r2=undef,
	d=undef, d1=undef, d2=undef,
	chamfer=undef, chamfer1=undef, chamfer2=undef,
	chamfang=undef, chamfang1=undef, chamfang2=undef,
	fillet=undef, fillet1=undef, fillet2=undef,
	circum=false, realign=false, from_end=false,
	orient=ORIENT_Z, align=V_ZERO
) {
	r1 = get_radius(r1, r, d1, d, 1);
	r2 = get_radius(r2, r, d2, d, 1);
	sides = segs(max(r1,r2));
	sc = circum? 1/cos(180/sides) : 1;
	orient_and_align([r1*2,r1*2,l], orient, align) {
		zrot(realign? 180/sides : 0) {
			if (!any_defined([chamfer, chamfer1, chamfer2, fillet, fillet1, fillet2])) {
				cylinder(h=l, r1=r1*sc, r2=r2*sc, center=true, $fn=sides);
			} else {
				vang = atan2(l, r1-r2)/2;
				chang1 = 90-first_defined([chamfang1, chamfang, vang]);
				chang2 = 90-first_defined([chamfang2, chamfang, 90-vang]);
				cham1 = first_defined([chamfer1, chamfer]) * (from_end? 1 : tan(chang1));
				cham2 = first_defined([chamfer2, chamfer]) * (from_end? 1 : tan(chang2));
				fil1 = first_defined([fillet1, fillet]);
				fil2 = first_defined([fillet2, fillet]);
				if (version_num()>20190000) {
					if (cham1 != undef) {
						assert(cham1 <= r1, "chamfer1 is larger than the r1 radius of the cylinder.");
						assert(cham1 <= l/2, "chamfer1 is larger than half the length of the cylinder.");
					}
					if (cham2 != undef) {
						assert(cham2 <= r2, "chamfer2 is larger than the r2 radius of the cylinder.");
						assert(cham2 <= l/2, "chamfer2 is larger than half the length of the cylinder.");
					}
					if (fil1 != undef) {
						assert(fil1 <= r1, "fillet1 is larger than the r1 radius of the cylinder.");
						assert(fil1 <= l/2, "fillet1 is larger than half the length of the cylinder.");
					}
					if (fil2 != undef) {
						assert(fil2 <= r2, "fillet2 is larger than the r1 radius of the cylinder.");
						assert(fil2 <= l/2, "fillet2 is larger than half the length of the cylinder.");
					}
				}

				dy1 = first_defined([cham1, fil1, 0]);
				dy2 = first_defined([cham2, fil2, 0]);
				maxd = max(r1,r2,l);

				rotate_extrude(convexity=2) {
					hull() {
						difference() {
							union() {
								difference() {
									back(l/2) {
										if (cham2!=undef && cham2>0) {
											rr2 = sc * (r2 + (r1-r2)*dy2/l);
											chlen2 = min(rr2, cham2/sin(chang2));
											translate([rr2,-cham2]) {
												rotate(-chang2) {
													translate([-chlen2,-chlen2]) {
														square(chlen2, center=false);
													}
												}
											}
										} else if (fil2!=undef && fil2>0) {
											translate([r2-fil2*tan(vang),-fil2]) {
												circle(r=fil2);
											}
										} else {
											translate([r2-0.005,-0.005]) {
												square(0.01, center=true);
											}
										}
									}

									// Make sure the corner fiddly bits never cross the X axis.
									fwd(maxd) square(maxd, center=false);
								}
								difference() {
									fwd(l/2) {
										if (cham1!=undef && cham1>0) {
											rr1 = sc * (r1 + (r2-r1)*dy1/l);
											chlen1 = min(rr1, cham1/sin(chang1));
											echo(vang=vang,chang1=chang2, chang2=chang2);
											translate([rr1,cham1]) {
												rotate(chang1) {
													left(chlen1) {
														square(chlen1, center=false);
													}
												}
											}
										} else if (fil1!=undef && fil1>0) {
											right(r1) {
												translate([-fil1/tan(vang),fil1]) {
													fsegs1 = quantup(segs(fil1),4);
													circle(r=fil1,$fn=fsegs1);
												}
											}
										} else {
											right(r1-0.01) {
												square(0.01, center=false);
											}
										}
									}

									// Make sure the corner fiddly bits never cross the X axis.
									square(maxd, center=false);
								}

								// Force the hull to extend to the axis
								right(0.01/2) square([0.01, l], center=true);
							}

							// Clear anything left of the Y axis.
							left(maxd/2) square(maxd, center=true);

							// Clear anything right of face
							right((r1+r2)/2) {
								rotate(90-vang*2) {
									fwd(maxd/2) square(maxd, center=false);
								}
							}
						}
					}
				}
			}
		}
	}
}



// Creates a cylinder with its top face centered at the origin.
//   h = height of cylinder. (Default: 1.0)
//   r = radius of cylinder. (Default: 1.0)
//   r1 = optional bottom radius of cylinder.
//   r2 = optional top radius of cylinder.
//   d = optional diameter of cylinder. (use instead of r)
//   d1 = optional bottom diameter of cylinder.
//   d2 = optional top diameter of cylinder.
// Example:
//   downcyl(r=10, h=50);
//   downcyl(r1=15, r2=5, h=45);
//   downcyl(d=15, h=40);
module downcyl(r=undef, h=1, d=undef, d1=undef, d2=undef, r1=undef, r2=undef)
{
	down(h/2) {
		cylinder(r=r, r1=r1, r2=r2, d=d, d1=d1, d2=d2, h=h, center=true);
	}
}



// Creates a cylinder oriented along the X axis.
// Use like the built-in cylinder(), except use `l` instead of `h`.
//   l = length of cylinder. (Default: 1.0)
//   r = radius of cylinder.
//   r1 = optional radius of left (X-) end of cylinder.
//   r2 = optional radius of right (X+) end of cylinder.
//   d = optional diameter of cylinder. (use instead of r)
//   d1 = optional diameter of left (X-) end of cylinder.
//   d2 = optional diameter of right (X+) end of cylinder.
//   align = 0 for centered, +1 for left, -1 for right.
// Examples:
//   xcyl(d1=5, d2=15, l=20, align=-1);
//   xcyl(d=10, l=25);
module xcyl(l=undef, r=undef, d=undef, r1=undef, r2=undef, d1=undef, d2=undef, align=0)
{
	right(align*l/2) {
		yrot(90) cylinder(h=l, r=r, d=d, r1=r1, r2=r2, d1=d1, d2=d2, center=true);
	}
}



// Creates a cylinder oriented along the Y axis.
// Use like the built-in cylinder(), except use `l` instead of `h`.
//   l = length of cylinder. (Default: 1.0)
//   r = radius of cylinder.
//   r1 = optional radius of front (Y-) end of cylinder.
//   r2 = optional radius of back (Y+) end of cylinder.
//   d = optional diameter of cylinder. (use instead of r)
//   d1 = optional diameter of front (Y-) end of cylinder.
//   d2 = optional diameter of back (Y+) end of cylinder.
//   align = 0 for centered, +1 for back, -1 for forward.
// Examples:
//   ycyl(d1=5, d2=15, l=20, align=-1);
//   ycyl(d=10, l=25);
module ycyl(l=undef, r=undef, d=undef, r1=undef, r2=undef, d1=undef, d2=undef, align=0)
{
	back(align*l/2) {
		xrot(-90) cylinder(h=l, r=r, d=d, r1=r1, r2=r2, d1=d1, d2=d2, center=true);
	}
}



// Creates a cylinder oriented along the Z axis.  Use like the built-in
// cylinder(), except use `l` instead of `h`.  This module exists
// mostly for symmetry with xcyl() and ycyl().
//   l = length of cylinder. (Default: 1.0)
//   r = radius of cylinder.
//   r1 = optional radius of bottom (Z-) end of cylinder.
//   r2 = optional radius of top (Z+) end of cylinder.
//   d = optional diameter of cylinder. (use instead of r)
//   d1 = optional diameter of bottom (Z-) end of cylinder.
//   d2 = optional diameter of top (Z+) end of cylinder.
//   align = 0 for centered, +1 for top, -1 for bottom.
// Examples:
//   zcyl(d1=5, d2=15, l=20, align=-1);
//   zcyl(d=10, l=25);
module zcyl(l=undef, r=undef, d=undef, r1=undef, r2=undef, d1=undef, d2=undef, align=0)
{
	up(align*l/2) {
		cylinder(h=l, r=r, d=d, r1=r1, r2=r2, d1=d1, d2=d2, center=true);
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
module chamferred_cylinder(h=1, r=undef, d=undef, chamfer=0.25, chamfedge=undef, angle=45, center=false, top=true, bottom=true)
{
	echo("DEPRECATED: You should use cyl() instead of chamf_cyl() or chamferred_cylinder().");
	r = get_radius(r=r, d=d, dflt=1);
	chamf = (chamfedge == undef)? chamfer : chamfedge * cos(angle);
	cyl(l=h, r=r, chamfer1=bottom? chamf : 0, chamfer2=top? chamf : 0, chamfang=angle, align=center? V_ZERO : V_UP);
}

module chamf_cyl(h=1, r=undef, d=undef, chamfer=0.25, chamfedge=undef, angle=45, center=false, top=true, bottom=true)
	chamferred_cylinder(h=h, r=r, d=d, chamfer=chamfer, chamfedge=chamfedge, angle=angle, center=center, top=top, bottom=bottom);
//!chamf_cyl(h=20, d=20, chamfedge=10, angle=60, center=true, $fn=36);


// Creates a cylinder with filletted (rounded) ends.
//   h = height of cylinder. (Default: 1.0)
//   r = radius of cylinder. (Default: 1.0)
//   d = diameter of cylinder. (Use instead of r)
//   fillet = radius of the edge filleting. (Default: 0.25)
//   center = boolean.  If true, cylinder is centered. (Default: false)
// Example:
//   rcylinder(h=50, r1=20, r2=30, fillet=5, center=true);
//   rcylinder(h=50, r=20, fillet=5, center=true);
module rcylinder(h=1, r=1, r1=undef, r2=undef, d=undef, d1=undef, d2=undef, fillet=0.25, center=false) {
	echo("DEPRECATED: use cyl() instead of rcylinder()");
	cyl(l=h, r=r, d=d, r1=r1, r2=r2, d1=d1, d2=d2, fillet=fillet, orient=V_UP, align=center? V_ZERO : V_UP);
}



module filleted_cylinder(h=1, r=undef, d=undef, r1=undef, r2=undef, d1=undef, d2=undef, fillet=0.25, center=false) {
	echo("DEPRECATED: use cyl() instead of filleted_cylinder()");
	cyl(l=h, r=r, d=d, r1=r1, r2=r2, d1=d1, d2=d2, fillet=fillet, orient=ORIENT_Z, align=center? V_ZERO : V_UP);
}



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
	echo("DEPRECATED: use cyl() instead of pyramid()");
	radius = get_radius(r=r, d=d, dflt=l/2/sin(180/n));
	cyl(r1=radius, r2=0, l=h, circum=circum, $fn=n, realign=true, align=V_UP);
}


// Creates a vertical prism with a given number of sides.
//   n = number of sides.
//   h = height of the prism.
//   l = length of one side of the prism. (optional)
//   r = radius of the prism. (optional)
//   d = diameter of the prism. (optional)
//   circum = prism circumscribes the circle of the given radius or diam.
// Example:
//   prism(n=8, h=3, d=4, circum=true);
module prism(n=3, h=1, l=1, r=undef, d=undef, circum=false, center=false)
{
	echo("DEPRECATED: use cyl() instead of prism()");
	radius = get_radius(r=r, d=d, dflt=l/2/sin(180/n));
	cyl(r=radius, l=h, circum=circum, $fn=n, realign=true, align=center? V_ZERO : V_UP);
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


// Creates a shape that can be unioned into a concave joint between two faces, to fillet them.
// Center this part along the edge to be chamferred and union it in.
//   l = length of edge to fillet.
//   r = radius of fillet.
//   ang = angle between faces to fillet.
//   overlap = overlap size for unioning with faces.
// Example:
//   union() {
//   	translate([0,-2,-4]) upcube([20, 4, 24]);
//   	translate([0,10,-4]) upcube([20, 20, 4]);
//   	color("green") interior_fillet(l=20, r=10);
//   }
module interior_fillet(l=1.0, r=1.0, ang=90, overlap=0.01) {
	dy = r/tan(ang/2);
	difference() {
		translate([0,-overlap/tan(ang/2),-overlap]) {
			if (ang == 90) {
				translate([0,r/2,r/2]) cube([l,r,r], center=true);
			} else {
				rotate([90,0,90]) pie_slice(ang=ang, r=dy+overlap, h=l, center=true);
			}
		}
		translate([0,dy,r]) xcyl(l=l+0.1, r=r);
	}
}



// Deprecated.  Renamed to prismoid.
module trapezoid(size1=[1,1], size2=[1,1], h=1, center=false) {
	echo("DEPRECATED: trapezoid() has been renamed to prismoid().");
	prismoid(size=size, size2=size2, h=h, align=center? V_ZERO : V_UP);
}


// Creates a rectangular prismoid shape.
//   size1 = [width, length] of the axis-negative end of the prism.
//   size2 = [width, length] of the axis-positive end of the prism.
//   h = Height of the prism.
//   orient = Orientation of the prismoid.  Use the ORIENT_ constants from constants.h.  Default: ORIENT_Z.
//   align = Alignment of the prismoid by the axis-negative (size1) end.  Use the V_ constants from constants.h.  Default: V_UP.
//   center = vertically center the prism.  DEPRECATED ARGUMENT.  Use align instead.
// Example:
//   prismoid(size1=[2,6], size2=[4,0], h=4, center=false);
//   prismoid(size1=[1,4], size2=[4,1], h=4, orient=ORIENT_X, align=V_UP+V_RIGHT+V_FWD);
//   prismoid(size1=[1,4], size2=[4,1], h=4);
module prismoid(
	size1=[1,1], size2=[1,1], h=1,
	align=V_UP, orient=ORIENT_Z, center=undef)
{
	if (center != undef) {
		echo("DEPRECATED ARGUMENT: in prismoid, use align instead of center");
	}
	algn = (center == undef)? align : (center? V_ZERO : V_UP);
	s1 = [max(size1[0], 0.001), max(size1[1], 0.001)];
	s2 = [max(size2[0], 0.001), max(size2[1], 0.001)];
	orient_and_align([s1[0], s1[1], h], orient, algn) {
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


// Creates a rectangular prismoid shape
// with rounded vertical edges.
//   size1 = [width, length] of the bottom of the prism.
//   size2 = [width, length] of the top of the prism.
//   h = Height of the prism.
//   r = radius of vertical edge fillets.
//   r1 = radius of vertical edge fillets at bottom.
//   r2 = radius of vertical edge fillets at top.
//   orient = Orientation of the prismoid.  Use the ORIENT_ constants from constants.h.  Default: ORIENT_Z.
//   align = Alignment of the prismoid by the axis-negative (size1) end.  Use the V_ constants from constants.h.  Default: V_UP.
//   center = vertically center the prism.  DEPRECATED ARGUMENT.  Use align instead.
// Example:
//   rounded_prismoid(size1=[40,40], size2=[0,0], h=40, r=5, center=false);
//   rounded_prismoid(size1=[20,60], size2=[40,30], h=40, r1=5, r2=10, center=false);
//   rounded_prismoid(size1=[40,60], size2=[35,55], h=40, r1=0, r2=10, center=true);
module rounded_prismoid(
	size1, size2, h,
	r=undef, r1=undef, r2=undef,
	align=V_UP, orient=ORIENT_Z, center=undef
) {
	eps = 0.001;
	maxrad1 = min(size1[0]/2, size1[1]/2);
	maxrad2 = min(size2[0]/2, size2[1]/2);
	rr1 = min(maxrad1, (r1!=undef)? r1 : r);
	rr2 = min(maxrad2, (r2!=undef)? r2 : r);
	orient_and_align([size1[0], size1[1], h], orient, align) {
		hull() {
			linear_extrude(height=eps, center=false, convexity=2) {
				offset(r=rr1) {
					square([max(eps, size1[0]-2*rr1), max(eps, size1[1]-2*rr1)], center=true);
				}
			}
			up(h-0.01) {
				linear_extrude(height=eps, center=false, convexity=2) {
					offset(r=rr2) {
						square([max(eps, size2[0]-2*rr2), max(eps, size2[1]-2*rr2)], center=true);
					}
				}
			}
		}
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
	r = get_radius(r=r, d=d, dflt=1);
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
module teardrop(r=undef, d=undef, h=1, ang=45, cap_h=undef)
{
	r = get_radius(r=r, d=d, dflt=1);
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
//   r = Outer radius of tube.
//   r1 = Outer radius of bottom of tube.  (Default: value of r)
//   r2 = Outer radius of top of tube.  (Default: value of r)
//   d = Outer diameter of tube.
//   d1 = Outer diameter of bottom of tube.
//   d2 = Outer diameter of top of tube.
//   wall = horizontal thickness of tube wall. (Default 0.5)
//   ir = Inner radius of tube.
//   ir1 = Inner radius of bottom of tube.
//   ir2 = Inner radius of top of tube.
//   id = Inner diameter of tube.
//   id1 = Inner diameter of bottom of tube.
//   id2 = Inner diameter of top of tube.
//   orient = Orientation of the tube.  Use the ORIENT_ constants from constants.h.  Default: vertical.
//   align = Alignment of the tube.  Use the V_ constants from constants.h.  Default: centered.
// Example:
//   tube(h=3, r=4, wall=1, center=true);
//   tube(h=6, r=4, wall=2, $fn=6);
//   tube(h=3, r1=5, r2=7, wall=2, center=true);
//   tube(h=30, r1=50, r2=70, ir1=50, ir2=50, center=true);
//   tube(h=30, wall=5, r1=40, r2=50, center=false);
module tube(
	h=1, wall=undef,
	r=undef, r1=undef, r2=undef,
	d=undef, d1=undef, d2=undef,
	ir=undef, id=undef, ir1=undef,
	ir2=undef, id1=undef, id2=undef,
	center=undef, orient=ORIENT_Z, align=V_UP
) {
	r1 = first_defined([r1, d1/2, r, d/2, ir1+wall, id1/2+wall, ir+wall, id/2+wall]);
	r2 = first_defined([r2, d2/2, r, d/2, ir2+wall, id2/2+wall, ir+wall, id/2+wall]);
	ir1 = first_defined([ir1, id1/2, ir, id/2, r1-wall, d1/2-wall, r-wall, d/2-wall]);
	ir2 = first_defined([ir2, id2/2, ir, id/2, r2-wall, d2/2-wall, r-wall, d/2-wall]);
	if (version_num()>20190000) {
		assert(ir1 <= r1, "Inner radius is larger than outer radius.");
		assert(ir2 <= r2, "Inner radius is larger than outer radius.");
	} else {
		if (ir1 > r1) echo("WARNING: r1 is smaller than ir1.");
		if (ir2 > r2) echo("WARNING: r2 is smaller than ir2.");
	}
	algn = (center == undef)? align : (center? V_ZERO : V_UP);
	orient_and_align([r1*2,r1*2,h], orient, algn) {
		difference() {
			cylinder(h=h, r1=r1, r2=r2, center=true);
			cylinder(h=h+0.05, r1=ir1, r2=ir2, center=true);
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
module torus(
	r=undef,  d=undef,
	r2=undef, d2=undef,
	or=undef, od=undef,
	ir=undef, id=undef
) {
	orr = get_radius(r=or, d=od, dflt=1.0);
	irr = get_radius(r=ir, d=id, dflt=0.5);
	majrad = get_radius(r=r, d=d, dflt=(orr+irr)/2);
	minrad = get_radius(r=r2, d=d2, dflt=(orr-irr)/2);
	rotate_extrude(convexity = 4) {
		right(majrad) circle(minrad);
	}
}


// Creates a pie slice shape.
//   ang = pie slice angle in degrees.
//   h = height of pie slice.
//   r = radius of pie slice.
//   r1 = bottom radius of pie slice.
//   r2 = top radius of pie slice.
//   d = diameter of pie slice.
//   d1 = bottom diameter of pie slice.
//   d2 = top diameter of pie slice.
//   center = if true, centers pie slice vertically. Default: false
// Example:
//   pie_slice(ang=45, h=30, r1=100, r2=80);
module pie_slice(ang=30, h=1, r=10, r1=undef, r2=undef, d=undef, d1=undef, d2=undef, center=false)
{
	r1 = get_radius(r1, r, d1, d, 10);
	r2 = get_radius(r2, r, d2, d, 10);
	steps = ceil(segs(max(r1,r2))*ang/360);
	step = ang/steps;
	pts = concat(
		[[0,0]],
		[for (i=[0:steps]) let(a = i*step) [r1*cos(a), r1*sin(a)]]
	);
	linear_extrude(height=h, scale=r2/r1, center=center, convexity=2) {
		polygon(pts);
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
	steps = segs(r+max(sr1,sr2));
	zrot(sa) {
		right(r) cylinder(h=h, r1=sr1, r2=sr2, center=true);
		difference() {
			linear_extrude(height=h, scale=(r+sr2)/(r+sr1), center=true, convexity=4) {
				polygon(
					points=concat(
						[[0,0]],
						[
							for (i = [0:steps]) [
								(r+sr1)*cos(da*i/steps),
								(r+sr1)*sin(da*i/steps)
							]
						]
					)
				);
			}
			cylinder(h=h+0.01, r1=(r-sr1), r2=(r-sr2), center=true);
		}
		zrot(da) right(r) cylinder(h=h, r1=sr1, r2=sr2, center=true);
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
			convexity=6
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
//   sparse_strut3d(h=30, w=30, l=180, thick=2.5, strut=2.5, maxang=30, max_bridge=20);
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
