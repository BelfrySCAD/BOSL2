//////////////////////////////////////////////////////////////////////
// LibFile: shapes.scad
//   Common useful shapes and structured objects.
//   To use, add the following lines to the beginning of your file:
//   ```
//   include <BOSL2/std.scad>
//   ```
//////////////////////////////////////////////////////////////////////

/*
BSD 2-Clause License

Copyright (c) 2017-2019, Revar Desmera
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



// Section: Cuboids


// Module: cuboid()
//
// Description:
//   Creates a cube or cuboid object, with optional chamfering or rounding.
//
// Arguments:
//   size = The size of the cube.
//   chamfer = Size of chamfer, inset from sides.  Default: No chamferring.
//   rounding = Radius of the edge rounding.  Default: No rounding.
//   edges = Edges to chamfer/rounding.  Use `EDGE` constants from constants.scad. Default: `EDGES_ALL`
//   trimcorners = If true, rounds or chamfers corners where three chamferred/rounded edges meet.  Default: `true`
//   p1 = Align the cuboid's corner at `p1`, if given.  Forces `anchor=ALLNEG`.
//   p2 = If given with `p1`, defines the cornerpoints of the cuboid.
//   anchor = The side of the part to anchor to.  Use constants from `constants.scad`.  Default: `CENTER`
//   center = If given, overrides `anchor`.  A true value sets `anchor=CENTER`, false sets `anchor=ALLNEG`.
//
// Example: Simple regular cube.
//   cuboid(40);
// Example: Cube with minimum cornerpoint given.
//   cuboid(20, p1=[10,0,0]);
// Example: Rectangular cube, with given X, Y, and Z sizes.
//   cuboid([20,40,50]);
// Example: Rectangular cube defined by opposing cornerpoints.
//   cuboid(p1=[0,10,0], p2=[20,30,30]);
// Example: Rectangular cube with chamferred edges and corners.
//   cuboid([30,40,50], chamfer=5);
// Example: Rectangular cube with chamferred edges, without trimmed corners.
//   cuboid([30,40,50], chamfer=5, trimcorners=false);
// Example: Rectangular cube with rounded edges and corners.
//   cuboid([30,40,50], rounding=10);
// Example: Rectangular cube with rounded edges, without trimmed corners.
//   cuboid([30,40,50], rounding=10, trimcorners=false);
// Example: Rectangular cube with only some edges chamferred.
//   cuboid([30,40,50], chamfer=5, edges=EDGE_TOP_FR+EDGE_TOP_RT+EDGE_FR_RT, $fn=24);
// Example: Rectangular cube with only some edges rounded.
//   cuboid([30,40,50], rounding=5, edges=EDGE_TOP_FR+EDGE_TOP_RT+EDGE_FR_RT, $fn=24);
// Example: Standard Connectors
//   cuboid(40, chamfer=5) show_anchors();
module cuboid(
	size=[1,1,1],
	p1=undef, p2=undef,
	chamfer=undef,
	rounding=undef,
	edges=EDGES_ALL,
	trimcorners=true,
	anchor=CENTER,
	center=undef
) {
	size = scalar_vec3(size);
	if (!is_undef(p1)) {
		if (!is_undef(p2)) {
			translate(pointlist_bounds([p1,p2])[0]) {
				cuboid(size=vabs(p2-p1), chamfer=chamfer, rounding=rounding, edges=edges, trimcorners=trimcorners, anchor=ALLNEG) children();
			}
		} else {
			translate(p1) {
				cuboid(size=size, chamfer=chamfer, rounding=rounding, edges=edges, trimcorners=trimcorners, anchor=ALLNEG) children();
			}
		}
	} else {
		if (chamfer != undef) assert(chamfer <= min(size)/2, "chamfer must be smaller than half the cube width, length, or height.");
		if (rounding != undef)  assert(rounding <= min(size)/2, "rounding radius must be smaller than half the cube width, length, or height.");
		majrots = [[0,90,0], [90,0,0], [0,0,0]];
		orient_and_anchor(size, ORIENT_Z, anchor, center=center, noncentered=ALLPOS, chain=true) {
			if (chamfer != undef) {
				isize = [for (v = size) max(0.001, v-2*chamfer)];
				if (edges == EDGES_ALL && trimcorners) {
					hull() {
						cube([size.x, isize.y, isize.z], center=true);
						cube([isize.x, size.y, isize.z], center=true);
						cube([isize.x, isize.y, size.z], center=true);
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
										rot(from=UP, to=[xa,ya,za]) {
											cube(chamfer*3, anchor=BOTTOM);
										}
									}
								}
							}
						}
					}
				}
			} else if (rounding != undef) {
				sides = quantup(segs(rounding),4);
				sc = 1/cos(180/sides);
				isize = [for (v = size) max(0.001, v-2*rounding)];
				if (edges == EDGES_ALL) {
					minkowski() {
						cube(isize, center=true);
						if (trimcorners) {
							sphere(r=rounding*sc, $fn=sides);
						} else {
							intersection() {
								zrot(180/sides) cylinder(r=rounding*sc, h=rounding*2, center=true, $fn=sides);
								rotate([90,0,0]) zrot(180/sides) cylinder(r=rounding*sc, h=rounding*2, center=true, $fn=sides);
								rotate([0,90,0]) zrot(180/sides) cylinder(r=rounding*sc, h=rounding*2, center=true, $fn=sides);
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
										rotate(majrots[axis]) cube([rounding*2, rounding*2, size[axis]+0.1], center=true);
									}
									translate(vmul(EDGE_OFFSETS[axis][i], size/2 - [1,1,1]*rounding)) {
										rotate(majrots[axis]) zrot(180/sides) cylinder(h=size[axis]+0.2, r=rounding*sc, center=true, $fn=sides);
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
											cube(rounding*2, center=true);
										}
										translate(vmul([xa,ya,za], size/2-[1,1,1]*rounding)) {
											zrot(180/sides) sphere(r=rounding*sc*sc, $fn=sides);
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
			children();
		}
	}
}



// Section: Prismoids


// Module: prismoid()
//
// Description:
//   Creates a rectangular prismoid shape.
//
// Usage:
//   prismoid(size1, size2, h, [shift], [orient], [anchor|center]);
//
// Arguments:
//   size1 = [width, length] of the axis-negative end of the prism.
//   size2 = [width, length] of the axis-positive end of the prism.
//   h = Height of the prism.
//   shift = [x, y] amount to shift the center of the top with respect to the center of the bottom.
//   orient = Orientation of the prismoid.  Use the `ORIENT_` constants from `constants.scad`.  Default: `ORIENT_Z`.
//   anchor = Alignment of the prismoid by the axis-negative (size1) end.  Use the constants from `constants.scad`.  Default: `BOTTOM`.
//   center = If given, overrides `anchor`.  A true value sets `anchor=CENTER`, false sets `anchor=BOTTOM`.
//
// Example: Rectangular Pyramid
//   prismoid(size1=[40,40], size2=[0,0], h=20);
// Example: Prism
//   prismoid(size1=[40,40], size2=[0,40], h=20);
// Example: Truncated Pyramid
//   prismoid(size1=[35,50], size2=[20,30], h=20);
// Example: Wedge
//   prismoid(size1=[60,35], size2=[30,0], h=30);
// Example: Truncated Tetrahedron
//   prismoid(size1=[10,40], size2=[40,10], h=40);
// Example: Inverted Truncated Pyramid
//   prismoid(size1=[15,5], size2=[30,20], h=20);
// Example: Right Prism
//   prismoid(size1=[30,60], size2=[0,60], shift=[-15,0], h=30);
// Example(FlatSpin): Shifting/Skewing
//   prismoid(size1=[50,30], size2=[20,20], h=20, shift=[15,5]);
// Example(Spin): Standard Connectors
//   prismoid(size1=[50,30], size2=[20,20], h=20, shift=[15,5]) show_anchors();
module prismoid(
	size1=[1,1], size2=[1,1], h=1, shift=[0,0],
	orient=ORIENT_Z, anchor=DOWN, center=undef
) {
	eps = 0.001;
	shiftby = point3d(point2d(shift));
	s1 = [max(size1.x, eps), max(size1.y, eps)];
	s2 = [max(size2.x, eps), max(size2.y, eps)];
	orient_and_anchor([s1.x,s1.y,h], orient, anchor, center, size2=s2, shift=shift, noncentered=DOWN, chain=true) {
		polyhedron(
			points=[
				[+s2.x/2, +s2.y/2, +h/2] + shiftby,
				[+s2.x/2, -s2.y/2, +h/2] + shiftby,
				[-s2.x/2, -s2.y/2, +h/2] + shiftby,
				[-s2.x/2, +s2.y/2, +h/2] + shiftby,
				[+s1.x/2, +s1.y/2, -h/2],
				[+s1.x/2, -s1.y/2, -h/2],
				[-s1.x/2, -s1.y/2, -h/2],
				[-s1.x/2, +s1.y/2, -h/2],
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
		children();
	}
}


// Module: rounded_prismoid()
//
// Description:
//   Creates a rectangular prismoid shape with rounded vertical edges.
//
// Arguments:
//   size1 = [width, length] of the bottom of the prism.
//   size2 = [width, length] of the top of the prism.
//   h = Height of the prism.
//   r = radius of vertical edge rounding.
//   r1 = radius of vertical edge rounding at bottom.
//   r2 = radius of vertical edge rounding at top.
//   shift = [x, y] amount to shift the center of the top with respect to the center of the bottom.
//   orient = Orientation of the prismoid.  Use the `ORIENT_` constants from `constants.scad`.  Default: `ORIENT_Z`.
//   anchor = Alignment of the prismoid by the axis-negative (`size1`) end.  Use the constants from `constants.scad`.  Default: `BOTTOM`.
//   center = vertically center the prism.  Overrides `anchor`.
//
// Example: Rounded Pyramid
//   rounded_prismoid(size1=[40,40], size2=[0,0], h=25, r=5);
// Example: Centered Rounded Pyramid
//   rounded_prismoid(size1=[40,40], size2=[0,0], h=25, r=5, center=true);
// Example: Disparate Top and Bottom Radii
//   rounded_prismoid(size1=[40,60], size2=[40,60], h=20, r1=3, r2=10, $fn=24);
// Example(FlatSpin): Shifting/Skewing
//   rounded_prismoid(size1=[50,30], size2=[20,20], h=20, shift=[15,5], r=5);
// Example(Spin): Standard Connectors
//   rounded_prismoid(size1=[40,60], size2=[40,60], h=20, r1=3, r2=10, $fn=24) show_anchors();
module rounded_prismoid(
	size1, size2, h, shift=[0,0],
	r=undef, r1=undef, r2=undef,
	anchor=BOTTOM, orient=ORIENT_Z, center=undef
) {
	eps = 0.001;
	maxrad1 = min(size1.x/2, size1.y/2);
	maxrad2 = min(size2.x/2, size2.y/2);
	rr1 = min(maxrad1, (r1!=undef)? r1 : r);
	rr2 = min(maxrad2, (r2!=undef)? r2 : r);
	shiftby = point3d(shift);
	orient_and_anchor([size1.x, size1.y, h], orient, anchor, center, size2=size2, shift=shift, noncentered=UP, chain=true) {
		down(h/2) {
			hull() {
				linear_extrude(height=eps, center=false, convexity=2) {
					offset(r=rr1) {
						square([max(eps, size1[0]-2*rr1), max(eps, size1[1]-2*rr1)], center=true);
					}
				}
				up(h-0.01) {
					translate(shiftby) {
						linear_extrude(height=eps, center=false, convexity=2) {
							offset(r=rr2) {
								square([max(eps, size2[0]-2*rr2), max(eps, size2[1]-2*rr2)], center=true);
							}
						}
					}
				}
			}
		}
		children();
	}
}



// Module: right_triangle()
//
// Description:
//   Creates a 3D right triangular prism.
//
// Usage:
//   right_triangle(size, [orient], [anchor|center]);
//
// Arguments:
//   size = [width, thickness, height]
//   orient = The axis to place the hypotenuse along.  Only accepts `ORIENT_X`, `ORIENT_Y`, or `ORIENT_Z` from `constants.scad`.  Default: `ORIENT_Y`.
//   anchor = The side of the origin to anchor to.  Use constants from `constants.scad`.  Default: `ALLNEG`.
//   center = If given, overrides `anchor`.  A true value sets `anchor=CENTER`, false sets `anchor=ALLNEG`.
//
// Example: Centered
//   right_triangle([60, 10, 40], center=true);
// Example: *Non*-Centered
//   right_triangle([60, 10, 40]);
// Example: Standard Connectors
//   right_triangle([60, 15, 40]) show_anchors();
module right_triangle(size=[1, 1, 1], orient=ORIENT_Y, anchor=ALLNEG, center=undef)
{
	size = scalar_vec3(size);
	orient_and_anchor(size, anchor=anchor, center=center, chain=true) {
		if (orient == ORIENT_X) {
			ang = atan2(size.y, size.z);
			masksize = [size.x, size.y, norm([size.y,size.z])] + [1,1,1];
			xrot(ang) {
				difference() {
					xrot(-ang) cube(size, center=true);
					back(masksize.y/2) cube(masksize, center=true);
				}
			}
		} else if (orient == ORIENT_Y) {
			ang = atan2(size.x, size.z);
			masksize = [size.x, size.y, norm([size.x,size.z])] + [1,1,1];
			yrot(-ang) {
				difference() {
					yrot(ang) cube(size, center=true);
					right(masksize.x/2) cube(masksize, center=true);
				}
			}
		} else if (orient == ORIENT_Z) {
			ang = atan2(size.x, size.y);
			masksize = [norm([size.x,size.y]), size.y, size.z] + [1,1,1];
			zrot(-ang) {
				difference() {
					zrot(ang) cube(size, center=true);
					back(masksize.y/2) cube(masksize, center=true);
				}
			}
		}
		children();
	}
}



// Section: Cylindroids


// Module: cyl()
//
// Description:
//   Creates cylinders in various anchors and orientations,
//   with optional rounding and chamfers. You can use `r` and `l`
//   interchangably, and all variants allow specifying size
//   by either `r`|`d`, or `r1`|`d1` and `r2`|`d2`.
//   Note that that chamfers and rounding cannot cross the
//   midpoint of the cylinder's length.
//
// Usage: Normal Cylinders
//   cyl(l|h, r|d, [circum], [realign], [orient], [anchor], [center]);
//   cyl(l|h, r1|d1, r2/d2, [circum], [realign], [orient], [anchor], [center]);
//
// Usage: Chamferred Cylinders
//   cyl(l|h, r|d, chamfer, [chamfang], [from_end], [circum], [realign], [orient], [anchor], [center]);
//   cyl(l|h, r|d, chamfer1, [chamfang1], [from_end], [circum], [realign], [orient], [anchor], [center]);
//   cyl(l|h, r|d, chamfer2, [chamfang2], [from_end], [circum], [realign], [orient], [anchor], [center]);
//   cyl(l|h, r|d, chamfer1, chamfer2, [chamfang1], [chamfang2], [from_end], [circum], [realign], [orient], [anchor], [center]);
//
// Usage: Rounded End Cylinders
//   cyl(l|h, r|d, rounding, [circum], [realign], [orient], [anchor], [center]);
//   cyl(l|h, r|d, rounding1, [circum], [realign], [orient], [anchor], [center]);
//   cyl(l|h, r|d, rounding2, [circum], [realign], [orient], [anchor], [center]);
//   cyl(l|h, r|d, rounding1, rounding2, [circum], [realign], [orient], [anchor], [center]);
//
// Arguments:
//   l / h = Length of cylinder along oriented axis. (Default: 1.0)
//   r = Radius of cylinder.
//   r1 = Radius of the negative (X-, Y-, Z-) end of cylinder.
//   r2 = Radius of the positive (X+, Y+, Z+) end of cylinder.
//   d = Diameter of cylinder.
//   d1 = Diameter of the negative (X-, Y-, Z-) end of cylinder.
//   d2 = Diameter of the positive (X+, Y+, Z+) end of cylinder.
//   circum = If true, cylinder should circumscribe the circle of the given size.  Otherwise inscribes.  Default: `false`
//   chamfer = The size of the chamfers on the ends of the cylinder.  Default: none.
//   chamfer1 = The size of the chamfer on the axis-negative end of the cylinder.  Default: none.
//   chamfer2 = The size of the chamfer on the axis-positive end of the cylinder.  Default: none.
//   chamfang = The angle in degrees of the chamfers on the ends of the cylinder.
//   chamfang1 = The angle in degrees of the chamfer on the axis-negative end of the cylinder.
//   chamfang2 = The angle in degrees of the chamfer on the axis-positive end of the cylinder.
//   from_end = If true, chamfer is measured from the end of the cylinder, instead of inset from the edge.  Default: `false`.
//   rounding = The radius of the rounding on the ends of the cylinder.  Default: none.
//   rounding1 = The radius of the rounding on the axis-negative end of the cylinder.
//   rounding2 = The radius of the rounding on the axis-positive end of the cylinder.
//   realign = If true, rotate the cylinder by half the angle of one face.
//   orient = Orientation of the cylinder.  Use the `ORIENT_` constants from `constants.scad`.  Default: vertical.
//   anchor = Alignment of the cylinder.  Use the constants from `constants.scad`.  Default: centered.
//   center = If given, overrides `anchor`.  A true value sets `anchor=CENTER`, false sets `anchor=DOWN`.
//
// Example: By Radius
//   xdistribute(30) {
//       cyl(l=40, r=10);
//       cyl(l=40, r1=10, r2=5);
//   }
//
// Example: By Diameter
//   xdistribute(30) {
//       cyl(l=40, d=25);
//       cyl(l=40, d1=25, d2=10);
//   }
//
// Example: Chamferring
//   xdistribute(60) {
//       // Shown Left to right.
//       cyl(l=40, d=40, chamfer=7);  // Default chamfang=45
//       cyl(l=40, d=40, chamfer=7, chamfang=30, from_end=false);
//       cyl(l=40, d=40, chamfer=7, chamfang=30, from_end=true);
//   }
//
// Example: Rounding
//   cyl(l=40, d=40, rounding=10);
//
// Example: Heterogenous Chamfers and Rounding
//   ydistribute(80) {
//       // Shown Front to Back.
//       cyl(l=40, d=40, rounding1=15, orient=ORIENT_X);
//       cyl(l=40, d=40, chamfer2=5, orient=ORIENT_X);
//       cyl(l=40, d=40, chamfer1=12, rounding2=10, orient=ORIENT_X);
//   }
//
// Example: Putting it all together
//   cyl(l=40, d1=25, d2=15, chamfer1=10, chamfang1=30, from_end=true, rounding2=5);
//
// Example: Standard Connectors
//   xdistribute(40) {
//       cyl(l=30, d=25) show_anchors();
//       cyl(l=30, d1=25, d2=10) show_anchors();
//   }
//
module cyl(
	l=undef, h=undef,
	r=undef, r1=undef, r2=undef,
	d=undef, d1=undef, d2=undef,
	chamfer=undef, chamfer1=undef, chamfer2=undef,
	chamfang=undef, chamfang1=undef, chamfang2=undef,
	rounding=undef, rounding1=undef, rounding2=undef,
	circum=false, realign=false, from_end=false,
	orient=ORIENT_Z, anchor=CENTER, center=undef
) {
	r1 = get_radius(r1, r, d1, d, 1);
	r2 = get_radius(r2, r, d2, d, 1);
	l = first_defined([l, h, 1]);
	size1 = [r1*2,r1*2,l];
	size2 = [r2*2,r2*2,l];
	sides = segs(max(r1,r2));
	sc = circum? 1/cos(180/sides) : 1;
	phi = atan2(l, r1-r2);
	orient_and_anchor(size1, orient, anchor, center=center, size2=size2, geometry="cylinder", chain=true) {
		zrot(realign? 180/sides : 0) {
			if (!any_defined([chamfer, chamfer1, chamfer2, rounding, rounding1, rounding2])) {
				cylinder(h=l, r1=r1*sc, r2=r2*sc, center=true, $fn=sides);
			} else {
				vang = atan2(l, r1-r2)/2;
				chang1 = 90-first_defined([chamfang1, chamfang, vang]);
				chang2 = 90-first_defined([chamfang2, chamfang, 90-vang]);
				cham1 = first_defined([chamfer1, chamfer]) * (from_end? 1 : tan(chang1));
				cham2 = first_defined([chamfer2, chamfer]) * (from_end? 1 : tan(chang2));
				fil1 = first_defined([rounding1, rounding]);
				fil2 = first_defined([rounding2, rounding]);
				if (chamfer != undef) {
					assert(chamfer <= r1,  "chamfer is larger than the r1 radius of the cylinder.");
					assert(chamfer <= r2,  "chamfer is larger than the r2 radius of the cylinder.");
					assert(chamfer <= l/2, "chamfer is larger than half the length of the cylinder.");
				}
				if (cham1 != undef) {
					assert(cham1 <= r1,  "chamfer1 is larger than the r1 radius of the cylinder.");
					assert(cham1 <= l/2, "chamfer1 is larger than half the length of the cylinder.");
				}
				if (cham2 != undef) {
					assert(cham2 <= r2,  "chamfer2 is larger than the r2 radius of the cylinder.");
					assert(cham2 <= l/2, "chamfer2 is larger than half the length of the cylinder.");
				}
				if (rounding != undef) {
					assert(rounding <= r1,  "rounding is larger than the r1 radius of the cylinder.");
					assert(rounding <= r2,  "rounding is larger than the r2 radius of the cylinder.");
					assert(rounding <= l/2, "rounding is larger than half the length of the cylinder.");
				}
				if (fil1 != undef) {
					assert(fil1 <= r1,  "rounding1 is larger than the r1 radius of the cylinder.");
					assert(fil1 <= l/2, "rounding1 is larger than half the length of the cylinder.");
				}
				if (fil2 != undef) {
					assert(fil2 <= r2,  "rounding2 is larger than the r1 radius of the cylinder.");
					assert(fil2 <= l/2, "rounding2 is larger than half the length of the cylinder.");
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
		children();
	}
}



// Module: xcyl()
//
// Description:
//   Creates a cylinder oriented along the X axis.
//
// Usage:
//   xcyl(l|h, r|d, [anchor|center]);
//   xcyl(l|h, r1|d1, r2|d2, [anchor|center]);
//
// Arguments:
//   l / h = Length of cylinder along oriented axis. (Default: `1.0`)
//   r = Radius of cylinder.
//   r1 = Optional radius of left (X-) end of cylinder.
//   r2 = Optional radius of right (X+) end of cylinder.
//   d = Optional diameter of cylinder. (use instead of `r`)
//   d1 = Optional diameter of left (X-) end of cylinder.
//   d2 = Optional diameter of right (X+) end of cylinder.
//   anchor = The side of the origin to anchor to.  Use constants from `constants.scad`. Default: `CENTER`
//   center = If given, overrides `anchor`.  A `true` value sets `anchor=CENTER`, `false` sets `anchor=BOTTOM`.
//
// Example: By Radius
//   ydistribute(50) {
//       xcyl(l=35, r=10);
//       xcyl(l=35, r1=15, r2=5);
//   }
//
// Example: By Diameter
//   ydistribute(50) {
//       xcyl(l=35, d=20);
//       xcyl(l=35, d1=30, d2=10);
//   }
module xcyl(l=undef, r=undef, d=undef, r1=undef, r2=undef, d1=undef, d2=undef, h=undef, anchor=CENTER, center=undef)
{
	cyl(l=l, h=h, r=r, r1=r1, r2=r2, d=d, d1=d1, d2=d2, orient=ORIENT_X, anchor=anchor, center=center) children();
}



// Module: ycyl()
//
// Description:
//   Creates a cylinder oriented along the Y axis.
//
// Usage:
//   ycyl(l|h, r|d, [anchor|center]);
//   ycyl(l|h, r1|d1, r2|d2, [anchor|center]);
//
// Arguments:
//   l / h = Length of cylinder along oriented axis. (Default: `1.0`)
//   r = Radius of cylinder.
//   r1 = Radius of front (Y-) end of cone.
//   r2 = Radius of back (Y+) end of one.
//   d = Diameter of cylinder.
//   d1 = Diameter of front (Y-) end of one.
//   d2 = Diameter of back (Y+) end of one.
//   anchor = The side of the origin to anchor to.  Use constants from `constants.scad`. Default: `CENTER`
//   center = Overrides `anchor` if given.  If true, `anchor=CENTER`, if false, `anchor=UP`.
//
// Example: By Radius
//   xdistribute(50) {
//       ycyl(l=35, r=10);
//       ycyl(l=35, r1=15, r2=5);
//   }
//
// Example: By Diameter
//   xdistribute(50) {
//       ycyl(l=35, d=20);
//       ycyl(l=35, d1=30, d2=10);
//   }
module ycyl(l=undef, r=undef, d=undef, r1=undef, r2=undef, d1=undef, d2=undef, h=undef, anchor=CENTER, center=undef)
{
	cyl(l=l, h=h, r=r, r1=r1, r2=r2, d=d, d1=d1, d2=d2, orient=ORIENT_Y, anchor=anchor, center=center) children();
}



// Module: zcyl()
//
// Description:
//   Creates a cylinder oriented along the Z axis.
//
// Usage:
//   zcyl(l|h, r|d, [anchor|center]);
//   zcyl(l|h, r1|d1, r2|d2, [anchor|center]);
//
// Arguments:
//   l / h = Length of cylinder along oriented axis. (Default: 1.0)
//   r = Radius of cylinder.
//   r1 = Radius of front (Y-) end of cone.
//   r2 = Radius of back (Y+) end of one.
//   d = Diameter of cylinder.
//   d1 = Diameter of front (Y-) end of one.
//   d2 = Diameter of back (Y+) end of one.
//   anchor = The side of the origin to anchor to.  Use constants from `constants.scad`. Default: `CENTER`
//   center = Overrides `anchor` if given.  If true, `anchor=CENTER`, if false, `anchor=UP`.
//
// Example: By Radius
//   xdistribute(50) {
//       zcyl(l=35, r=10);
//       zcyl(l=35, r1=15, r2=5);
//   }
//
// Example: By Diameter
//   xdistribute(50) {
//       zcyl(l=35, d=20);
//       zcyl(l=35, d1=30, d2=10);
//   }
module zcyl(l=undef, r=undef, d=undef, r1=undef, r2=undef, d1=undef, d2=undef, h=undef, anchor=CENTER, center=undef)
{
	cyl(l=l, h=h, r=r, r1=r1, r2=r2, d=d, d1=d1, d2=d2, orient=ORIENT_Z, anchor=anchor, center=center) children();
}



// Module: tube()
//
// Description:
//   Makes a hollow tube with the given outer size and wall thickness.
//
// Usage:
//   tube(h, ir|id, wall, [realign], [orient], [anchor]);
//   tube(h, or|od, wall, [realign], [orient], [anchor]);
//   tube(h, ir|id, or|od, [realign], [orient], [anchor]);
//   tube(h, ir1|id1, ir2|id2, wall, [realign], [orient], [anchor]);
//   tube(h, or1|od1, or2|od2, wall, [realign], [orient], [anchor]);
//   tube(h, ir1|id1, ir2|id2, or1|od1, or2|od2, [realign], [orient], [anchor]);
//
// Arguments:
//   h = height of tube. (Default: 1)
//   or = Outer radius of tube.
//   or1 = Outer radius of bottom of tube.  (Default: value of r)
//   or2 = Outer radius of top of tube.  (Default: value of r)
//   od = Outer diameter of tube.
//   od1 = Outer diameter of bottom of tube.
//   od2 = Outer diameter of top of tube.
//   wall = horizontal thickness of tube wall. (Default 0.5)
//   ir = Inner radius of tube.
//   ir1 = Inner radius of bottom of tube.
//   ir2 = Inner radius of top of tube.
//   id = Inner diameter of tube.
//   id1 = Inner diameter of bottom of tube.
//   id2 = Inner diameter of top of tube.
//   realign = If true, rotate the tube by half the angle of one face.
//   orient = Orientation of the tube.  Use the `ORIENT_` constants from `constants.scad`.  Default: vertical.
//   anchor = Alignment of the tube.  Use the constants from `constants.scad`.  Default: centered.
//
// Example: These all Produce the Same Tube
//   tube(h=30, or=40, wall=5);
//   tube(h=30, ir=35, wall=5);
//   tube(h=30, or=40, ir=35);
//   tube(h=30, od=80, id=70);
// Example: These all Produce the Same Conical Tube
//   tube(h=30, or1=40, or2=25, wall=5);
//   tube(h=30, ir1=35, or2=20, wall=5);
//   tube(h=30, or1=40, or2=25, ir1=35, ir2=20);
// Example: Circular Wedge
//   tube(h=30, or1=40, or2=30, ir1=20, ir2=30);
// Example: Standard Connectors
//   tube(h=30, or=40, wall=5) show_anchors();
module tube(
	h=1, wall=undef,
	r=undef, r1=undef, r2=undef,
	d=undef, d1=undef, d2=undef,
	or=undef, or1=undef, or2=undef,
	od=undef, od1=undef, od2=undef,
	ir=undef, id=undef, ir1=undef,
	ir2=undef, id1=undef, id2=undef,
	center=undef, orient=ORIENT_Z, anchor=UP,
	realign=false
) {
	r1 = first_defined([or1, od1/2, r1, d1/2, or, od/2, r, d/2, ir1+wall, id1/2+wall, ir+wall, id/2+wall]);
	r2 = first_defined([or2, od2/2, r2, d2/2, or, od/2, r, d/2, ir2+wall, id2/2+wall, ir+wall, id/2+wall]);
	ir1 = first_defined([ir1, id1/2, ir, id/2, r1-wall, d1/2-wall, r-wall, d/2-wall]);
	ir2 = first_defined([ir2, id2/2, ir, id/2, r2-wall, d2/2-wall, r-wall, d/2-wall]);
	assert(ir1 <= r1, "Inner radius is larger than outer radius.");
	assert(ir2 <= r2, "Inner radius is larger than outer radius.");
	sides = segs(max(r1,r2));
	size = [r1*2,r1*2,h];
	size2 = [r2*2,r2*2,h];
	orient_and_anchor(size, orient, anchor, center=center, size2=size2, geometry="cylinder", chain=true) {
		zrot(realign? 180/sides : 0) {
			difference() {
				cyl(h=h, r1=r1, r2=r2, $fn=sides) children();
				cyl(h=h+0.05, r1=ir1, r2=ir2);
			}
		}
		children();
	}
}


// Module: torus()
//
// Descriptiom:
//   Creates a torus shape.
//
// Usage:
//   torus(r|d, r2|d2, [orient], [anchor]);
//   torus(or|od, ir|id, [orient], [anchor]);
//
// Arguments:
//   r  = major radius of torus ring. (use with of 'r2', or 'd2')
//   r2 = minor radius of torus ring. (use with of 'r', or 'd')
//   d  = major diameter of torus ring. (use with of 'r2', or 'd2')
//   d2 = minor diameter of torus ring. (use with of 'r', or 'd')
//   or = outer radius of the torus. (use with 'ir', or 'id')
//   ir = inside radius of the torus. (use with 'or', or 'od')
//   od = outer diameter of the torus. (use with 'ir' or 'id')
//   id = inside diameter of the torus. (use with 'or' or 'od')
//   orient = Orientation of the torus.  Use the `ORIENT_` constants from `constants.scad`.  Default: `ORIENT_Z`.
//   anchor = Alignment of the torus.  Use the constants from `constants.scad`.  Default: `CENTER`.
//
// Example:
//   // These all produce the same torus.
//   torus(r=22.5, r2=7.5);
//   torus(d=45, d2=15);
//   torus(or=30, ir=15);
//   torus(od=60, id=30);
// Example: Standard Connectors
//   torus(od=60, id=30) show_anchors();
module torus(
	r=undef,  d=undef,
	r2=undef, d2=undef,
	or=undef, od=undef,
	ir=undef, id=undef,
	orient=ORIENT_Z, anchor=CENTER, center=undef
) {
	orr = get_radius(r=or, d=od, dflt=1.0);
	irr = get_radius(r=ir, d=id, dflt=0.5);
	majrad = get_radius(r=r, d=d, dflt=(orr+irr)/2);
	minrad = get_radius(r=r2, d=d2, dflt=(orr-irr)/2);
	size = [(majrad+minrad)*2, (majrad+minrad)*2, minrad*2];
	orient_and_anchor(size, orient, anchor, center=center, geometry="cylinder", chain=true) {
		rotate_extrude(convexity=4) {
			right(majrad) circle(minrad);
		}
		children();
	}
}



// Section: Spheroids


// Module: spheroid()
// Description:
//   An version of `sphere()` with anchors points and orientation.
// Usage:
//   spheroid(r|d, [circum])
// Arguments:
//   r = Radius of the sphere.
//   d = Diameter of the sphere.
//   circum = If true, circumscribes the perfect sphere of the given radius/diameter.
//   orient = Orientation of the sphere, if you don't like where the vertices lay.  Use the `ORIENT_` constants from `constants.scad`.  Default: `ORIENT_Z`.
//   anchor = Alignment of the sphere.  Use the constants from `constants.scad`.  Default: `CENTER`.
// Example: By Radius
//   spheroid(r=50, circum=true);
// Example: By Diameter
//   spheroid(d=100, circum=true);
// Example: Standard Connectors
//   spheroid(d=40, circum=true) show_anchors();
module spheroid(r=undef, d=undef, circum=false, orient=UP, anchor=CENTER)
{
	r = get_radius(r=r, d=d, dflt=1);
	hsides = segs(r);
	vsides = ceil(hsides/2);
	rr = circum? (r / cos(90/vsides) / cos(180/hsides)) : r;
	size = [2*rr, 2*rr, 2*rr];
	orient_and_anchor(size, orient, anchor, geometry="sphere", chain=true) {
		sphere(r=rr);
		children();
	}
}



// Module: staggered_sphere()
//
// Description:
//   An alternate construction to the standard `sphere()` built-in, with different triangulation.
//
// Usage:
//   staggered_sphere(r|d, [circum])
//
// Arguments:
//   r = Radius of the sphere.
//   d = Diameter of the sphere.
//   circum = If true, circumscribes the perfect sphere of the given size.
//   orient = Orientation of the sphere, if you don't like where the vertices lay.  Use the `ORIENT_` constants from `constants.scad`.  Default: `ORIENT_Z`.
//   anchor = Alignment of the sphere.  Use the constants from `constants.scad`.  Default: `CENTER`.
//
// Example: By Radius
//   staggered_sphere(r=50, circum=true);
// Example: By Diameter
//   staggered_sphere(d=100, circum=true);
// Example: Standard Connectors
//   staggered_sphere(d=40, circum=true) show_anchors();
module staggered_sphere(r=undef, d=undef, circum=false, orient=UP, anchor=CENTER) {
	r = get_radius(r=r, d=d, dflt=1);
	sides = segs(r);
	vsides = max(3, ceil(sides/2))+1;
	step = 360/sides;
	vstep = 180/(vsides-1);
	rr = circum? (r / cos(180/sides) / cos(90/vsides)) : r;
	pts = concat(
		[[0,0,rr]],
		[
			for (p = [1:vsides-2], t = [0:sides-1]) let(
				ta = (t+(p%2/2))*step,
				pa = p*vstep
			) spherical_to_xyz(rr, ta, pa)
		],
		[[0,0,-rr]]
	);
	pcnt = len(pts);
	faces = concat(
		[
			for (i = [1:sides]) each [
				[0, i%sides+1, i],
				[pcnt-1, pcnt-1-(i%sides+1), pcnt-1-i]
			]
		],
		[
			for (p = [0:vsides-4], i = [0:sides-1]) let(
				b1 = 1+p*sides,
				b2 = 1+(p+1)*sides,
				v1 = b1+i,
				v2 = b1+(i+1)%sides,
				v3 = b2+((i+((p%2)?(sides-1):0))%sides),
				v4 = b2+((i+1+((p%2)?(sides-1):0))%sides)
			) each [[v1,v4,v3], [v1,v2,v4]]
		]
	);
	size = [2*rr, 2*rr, 2*rr];
	orient_and_anchor(size, orient, anchor, geometry="sphere", chain=true) {
		polyhedron(points=pts, faces=faces);
		children();
	}
}



// Section: 3D Printing Shapes


// Module: teardrop2d()
//
// Description:
//   Makes a 2D teardrop shape. Useful for extruding into 3D printable holes.
//
// Usage:
//   teardrop2d(r|d, [ang], [cap_h]);
//
// Arguments:
//   r = radius of circular part of teardrop.  (Default: 1)
//   d = diameter of spherical portion of bottom. (Use instead of r)
//   ang = angle of hat walls from the Y axis.  (Default: 45 degrees)
//   cap_h = if given, height above center where the shape will be truncated.
//
// Example(2D): Typical Shape
//   teardrop2d(r=30, ang=30);
// Example(2D): Crop Cap
//   teardrop2d(r=30, ang=30, cap_h=40);
// Example(2D): Close Crop
//   teardrop2d(r=30, ang=30, cap_h=20);
module teardrop2d(r=1, d=undef, ang=45, cap_h=undef)
{
	eps = 0.01;
	r = get_radius(r=r, d=d, dflt=1);
	cord = 2 * r * cos(ang);
	cord_h = r * sin(ang);
	tip_y = (cord/2)/tan(ang);
	cap_h = min((!is_undef(cap_h)? cap_h : tip_y+cord_h), tip_y+cord_h);
	cap_w = cord * (1 - (cap_h - cord_h)/tip_y);
	difference() {
		hull() {
			zrot(90) circle(r=r);
			back(cap_h-eps/2) square([max(eps,cap_w), eps], center=true);
		}
		back(r+cap_h) square(2*r, center=true);
	}
}


// Module: teardrop()
//
// Description:
//   Makes a teardrop shape in the XZ plane. Useful for 3D printable holes.
//
// Usage:
//   teardrop(r|d, l|h, [ang], [cap_h], [orient], [anchor])
//
// Arguments:
//   r = Radius of circular part of teardrop.  (Default: 1)
//   d = Diameter of circular portion of bottom. (Use instead of r)
//   l = Thickness of teardrop. (Default: 1)
//   ang = Angle of hat walls from the Z axis.  (Default: 45 degrees)
//   cap_h = If given, height above center where the shape will be truncated.
//   orient = Orientation of the shape.  Use the `ORIENT_` constants from `constants.scad`.  Default: `ORIENT_Y`.
//   anchor = Alignment of the shape.  Use the constants from `constants.scad`.  Default: `CENTER`.
//
// Example: Typical Shape
//   teardrop(r=30, h=10, ang=30);
// Example: Crop Cap
//   teardrop(r=30, h=10, ang=30, cap_h=40);
// Example: Close Crop
//   teardrop(r=30, h=10, ang=30, cap_h=20);
module teardrop(r=undef, d=undef, l=undef, h=undef, ang=45, cap_h=undef, orient=ORIENT_Y, anchor=CENTER)
{
	r = get_radius(r=r, d=d, dflt=1);
	l = first_defined([l, h, 1]);
	size = [r*2,r*2,l];
	orient_and_anchor(size, orient, anchor, geometry="cylinder", chain=true) {
		linear_extrude(height=l, center=true, slices=2) {
			teardrop2d(r=r, ang=ang, cap_h=cap_h);
		}
		children();
	}
}


// Module: onion()
//
// Description:
//   Creates a sphere with a conical hat, to make a 3D teardrop.
//
// Usage:
//   onion(r|d, [maxang], [cap_h], [orient], [anchor]);
//
// Arguments:
//   r = radius of spherical portion of the bottom. (Default: 1)
//   d = diameter of spherical portion of bottom.
//   cap_h = height above sphere center to truncate teardrop shape.
//   maxang = angle of cone on top from vertical.
//   orient = Orientation of the shape.  Use the `ORIENT_` constants from `constants.scad`.  Default: `ORIENT_Y`.
//   anchor = Alignment of the shape.  Use the constants from `constants.scad`.  Default: `CENTER`.
//
// Example: Typical Shape
//   onion(r=30, maxang=30);
// Example: Crop Cap
//   onion(r=30, maxang=30, cap_h=40);
// Example: Close Crop
//   onion(r=30, maxang=30, cap_h=20);
// Example: Standard Connectors
//   onion(r=30, maxang=30, cap_h=40) show_anchors();
module onion(cap_h=undef, r=undef, d=undef, maxang=45, h=undef, orient=ORIENT_Z, anchor=CENTER)
{
	r = get_radius(r=r, d=d, dflt=1);
	h = first_defined([cap_h, h]);
	maxd = 3*r/tan(maxang);
	size = [r*2,r*2,r*2];
	anchors = [
		["cap", [0,0,h], UP, 0]
	];
	orient_and_anchor(size, orient, anchor, geometry="sphere", anchors=anchors, chain=true) {
		rotate_extrude(convexity=2) {
			difference() {
				teardrop2d(r=r, ang=maxang, cap_h=h);
				left(r) square(size=[2*r,maxd], center=true);
			}
		}
		children();
	}
}



// Section: Miscellaneous


// Module: nil()
//
// Description:
//   Useful when you MUST pass a child to a module, but you want it to be nothing.
module nil() union(){}


// Module: noop()
//
// Description:
//   Passes through the children passed to it, with no action at all.
//   Useful while debugging when you want to replace a command.
module noop(orient=ORIENT_Z) orient_and_anchor([0.01,0.01,0.01], orient, CENTER, chain=true) {nil(); children();}


// Module: pie_slice()
//
// Description:
//   Creates a pie slice shape.
//
// Usage:
//   pie_slice(ang, l|h, r|d, [orient], [anchor|center]);
//   pie_slice(ang, l|h, r1|d1, r2|d2, [orient], [anchor|center]);
//
// Arguments:
//   ang = pie slice angle in degrees.
//   h = height of pie slice.
//   r = radius of pie slice.
//   r1 = bottom radius of pie slice.
//   r2 = top radius of pie slice.
//   d = diameter of pie slice.
//   d1 = bottom diameter of pie slice.
//   d2 = top diameter of pie slice.
//   orient = Orientation of the pie slice.  Use the `ORIENT_` constants from `constants.scad`.  Default: `ORIENT_Z`.
//   anchor = Alignment of the pie slice.  Use the constants from `constants.scad`.  Default: `CENTER`.
//   center = If given, overrides `anchor`.  A true value sets `anchor=CENTER`, false sets `anchor=UP`.
//
// Example: Cylindrical Pie Slice
//   pie_slice(ang=45, l=20, r=30);
// Example: Conical Pie Slice
//   pie_slice(ang=60, l=20, d1=50, d2=70);
module pie_slice(
	ang=30, l=undef,
	r=10, r1=undef, r2=undef,
	d=undef, d1=undef, d2=undef,
	orient=ORIENT_Z, anchor=UP,
	center=undef, h=undef
) {
	l = first_defined([l, h, 1]);
	r1 = get_radius(r1, r, d1, d, 10);
	r2 = get_radius(r2, r, d2, d, 10);
	maxd = max(r1,r2)+0.1;
	size = [2*r1, 2*r1, l];
	orient_and_anchor(size, orient, anchor, center=center, geometry="cylinder", chain=true) {
		difference() {
			cylinder(r1=r1, r2=r2, h=l, center=true);
			if (ang<180) rotate(ang) back(maxd/2) cube([2*maxd, maxd, l+0.1], center=true);
			difference() {
				fwd(maxd/2) cube([2*maxd, maxd, l+0.2], center=true);
				if (ang>180) rotate(ang-180) back(maxd/2) cube([2*maxd, maxd, l+0.1], center=true);
			}
		}
		children();
	}
}


// Module: interior_fillet()
//
// Description:
//   Creates a shape that can be unioned into a concave joint between two faces, to fillet them.
//   Center this part along the concave edge to be chamferred and union it in.
//
// Usage:
//   interior_fillet(l, r, [ang], [overlap], [orient], [anchor]);
//
// Arguments:
//   l = length of edge to fillet.
//   r = radius of fillet.
//   ang = angle between faces to fillet.
//   overlap = overlap size for unioning with faces.
//   orient = Orientation of the fillet.  Use the `ORIENT_` constants from `constants.scad`.  Default: `ORIENT_X`.
//   anchor = Alignment of the fillet.  Use the constants from `constants.scad`.  Default: `CENTER`.
//
// Example:
//   union() {
//       translate([0,2,-4]) cube([20, 4, 24], anchor=BOTTOM);
//       translate([0,-10,-4]) cube([20, 20, 4], anchor=BOTTOM);
//       color("green") interior_fillet(l=20, r=10, orient=ORIENT_XNEG);
//   }
//
// Example:
//   interior_fillet(l=40, r=10, orient=ORIENT_Y_90);
module interior_fillet(l=1.0, r=1.0, ang=90, overlap=0.01, orient=ORIENT_X, anchor=CENTER) {
	dy = r/tan(ang/2);
	size = [l,r,r];
	orient_and_anchor(size, orient, anchor, orig_orient=ORIENT_X, chain=true) {
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
		children();
	}
}



// Module: slot()
//
// Description:
//   Makes a linear slot with rounded ends, appropriate for bolts to slide along.
//
// Usage:
//   slot(h, l, r|d, [orient], [anchor|center]);
//   slot(h, p1, p2, r|d, [orient], [anchor|center]);
//   slot(h, l, r1|d1, r2|d2, [orient], [anchor|center]);
//   slot(h, p1, p2, r1|d1, r2|d2, [orient], [anchor|center]);
//
// Arguments:
//   p1 = center of starting circle of slot.
//   p2 = center of ending circle of slot.
//   l = length of slot along the X axis.
//   h = height of slot shape. (default: 10)
//   r = radius of slot circle. (default: 5)
//   r1 = bottom radius of slot cone.
//   r2 = top radius of slot cone.
//   d = diameter of slot circle.
//   d1 = bottom diameter of slot cone.
//   d2 = top diameter of slot cone.
//
// Example: Between Two Points
//   slot([0,0,0], [50,50,0], r1=5, r2=10, h=5);
// Example: By Length
//   slot(l=50, r1=5, r2=10, h=5);
module slot(
	p1=undef, p2=undef, h=10, l=undef,
	r=undef, r1=undef, r2=undef,
	d=undef, d1=undef, d2=undef
) {
	r1 = get_radius(r1=r1, r=r, d1=d1, d=d, dflt=5);
	r2 = get_radius(r1=r2, r=r, d1=d2, d=d, dflt=5);
	sides = quantup(segs(max(r1, r2)), 4);
	// TODO: implement orient and anchor.
	// TODO: implement anchors.
	hull() spread(p1=p1, p2=p2, l=l, n=2) cyl(l=h, r1=r1, r2=r2, center=true, $fn=sides);
}


// Module: arced_slot()
//
// Description:
//   Makes an arced slot, appropriate for bolts to slide along.
//
// Usage:
//   arced_slot(h, r|d, sr|sd, [sa], [ea], [orient], [anchor|center], [$fn2]);
//   arced_slot(h, r|d, sr1|sd1, sr2|sd2, [sa], [ea], [orient], [anchor|center], [$fn2]);
//
// Arguments:
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
//   orient = Orientation of the arced slot.  Use the `ORIENT_` constants from `constants.scad`.  Default: `ORIENT_Z`.
//   anchor = Alignment of the arced slot.  Use the constants from `constants.scad`.  Default: `CENTER`.
//   center = If true, centers vertically.  If false, drops flush with XY plane.  Overrides `anchor`.
//   $fn2 = The $fn value to use on the small round endcaps.  The major arcs are still based on $fn.  Default: $fn
//
// Example: Typical Arced Slot
//   arced_slot(d=60, h=5, sd=10, sa=60, ea=280);
// Example: Conical Arced Slot
//   arced_slot(r=60, h=5, sd1=10, sd2=15, sa=45, ea=180);
module arced_slot(
	r=undef, d=undef, h=1.0,
	sr=undef, sr1=undef, sr2=undef,
	sd=undef, sd1=undef, sd2=undef,
	sa=0, ea=90, cp=[0,0,0],
	orient=ORIENT_Z, anchor=CENTER,
	$fn2 = undef
) {
	r = get_radius(r=r, d=d, dflt=2);
	sr1 = get_radius(sr1, sr, sd1, sd, 2);
	sr2 = get_radius(sr2, sr, sd2, sd, 2);
	fn_minor = first_defined([$fn2, $fn]);
	da = ea - sa;
	size = [r+sr1, r+sr1, h];
	orient_and_anchor(size, orient, anchor, geometry="cylinder", chain=true) {
		translate(cp) {
			zrot(sa) {
				difference() {
					pie_slice(ang=da, l=h, r1=r+sr1, r2=r+sr2, orient=ORIENT_Z, anchor=CENTER);
					cylinder(h=h+0.1, r1=r-sr1, r2=r-sr2, center=true);
				}
				right(r) cylinder(h=h, r1=sr1, r2=sr2, center=true, $fn=fn_minor);
				zrot(da) right(r) cylinder(h=h, r1=sr1, r2=sr2, center=true, $fn=fn_minor);
			}
		}
		children();
	}
}



// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
