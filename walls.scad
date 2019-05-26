//////////////////////////////////////////////////////////////////////
// LibFile: walls.scad
//   Various wall constructions.
//   To use, add the following lines to the beginning of your file:
//   ```
//   include <BOSL2/std.scad>
//   include <BOSL2/walls.scad>
//   ```
//////////////////////////////////////////////////////////////////////


// Section: Walls


// Module: narrowing_strut()
//
// Description:
//   Makes a rectangular strut with the top side narrowing in a triangle.
//   The shape created may be likened to an extruded home plate from baseball.
//   This is useful for constructing parts that minimize the need to support
//   overhangs.
//
// Usage:
//   narrowing_strut(w, l, wall, [ang], [orient], [anchor]);
//
// Arguments:
//   w = Width (thickness) of the strut.
//   l = Length of the strut.
//   wall = height of rectangular portion of the strut.
//   ang = angle that the trianglar side will converge at.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments#orient).  Default: `UP`
//
// Example:
//   narrowing_strut(w=10, l=100, wall=5, ang=30);
module narrowing_strut(w=10, l=100, wall=5, ang=30, anchor=BOTTOM, spin=0, orient=UP)
{
	h = wall + w/2/tan(ang);
	size = [w, h, l];
	orient_and_anchor(size, orient, anchor, spin=spin, chain=true) {
		fwd(h/2) {
			linear_extrude(height=l, center=true, slices=2) {
				back(wall/2) square([w, wall], center=true);
				back(wall-0.001) {
					yscale(1/tan(ang)) {
						difference() {
							zrot(45) square(w/sqrt(2), center=true);
							fwd(w/2) square(w, center=true);
						}
					}
				}
			}
		}
		children();
	}
}


// Module: thinning_wall()
//
// Description:
//   Makes a rectangular wall which thins to a smaller width in the center,
//   with angled supports to prevent critical overhangs.
//
// Usage:
//   thinning_wall(h, l, thick, [ang], [strut], [wall], [orient], [anchor]);
//
// Arguments:
//   h = height of wall.
//   l = length of wall.  If given as a vector of two numbers, specifies bottom and top lengths, respectively.
//   thick = thickness of wall.
//   ang = maximum overhang angle of diagonal brace.
//   strut = the width of the diagonal brace.
//   wall = the thickness of the thinned portion of the wall.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments#orient).  Default: `UP`
//
// Example: Typical Shape
//   thinning_wall(h=50, l=80, thick=4);
// Example: Trapezoidal
//   thinning_wall(h=50, l=[80,50], thick=4);
module thinning_wall(h=50, l=100, thick=5, ang=30, strut=5, wall=2, anchor=CENTER, spin=0, orient=UP)
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

	size = [l1, thick, h];
	orient_and_anchor(size, orient, anchor, spin=spin, size2=[l2,thick], chain=true) {
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
		children();
	}
}


// Module: braced_thinning_wall()
//
// Description:
//   Makes a rectangular wall with cross-bracing, which thins to a smaller width in the center,
//   with angled supports to prevent critical overhangs.
//
// Usage:
//   braced_thinning_wall(h, l, thick, [ang], [strut], [wall], [orient], [anchor]);
//
// Arguments:
//   h = height of wall.
//   l = length of wall.
//   thick = thickness of wall.
//   ang = maximum overhang angle of diagonal brace.
//   strut = the width of the diagonal brace.
//   wall = the thickness of the thinned portion of the wall.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments#orient).  Default: `UP`
//
// Example:
//   braced_thinning_wall(h=50, l=100, thick=5);
module braced_thinning_wall(h=50, l=100, thick=5, ang=30, strut=5, wall=2, anchor=CENTER, spin=0, orient=UP)
{
	dang = atan((h-2*strut)/(l-2*strut));
	dlen = (h-2*strut)/sin(dang);
	size = [l, thick, h];
	orient_and_anchor(size, orient, anchor, spin=spin, chain=true) {
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
		children();
	}
}



// Module: thinning_triangle()
//
// Description:
//   Makes a triangular wall with thick edges, which thins to a smaller width in
//   the center, with angled supports to prevent critical overhangs.
//
// Usage:
//   thinning_triangle(h, l, thick, [ang], [strut], [wall], [diagonly], [orient], [anchor|center]);
//
// Arguments:
//   h = height of wall.
//   l = length of wall.
//   thick = thickness of wall.
//   ang = maximum overhang angle of diagonal brace.
//   strut = the width of the diagonal brace.
//   wall = the thickness of the thinned portion of the wall.
//   diagonly = boolean, which denotes only the diagonal side (hypotenuse) should be thick.
//   center = If true, centers shape.  If false, overrides `anchor` with `UP+BACK`.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments#orient).  Default: `UP`
//
// Example: Centered
//   thinning_triangle(h=50, l=80, thick=4, ang=30, strut=5, wall=2, center=true);
// Example: All Braces
//   thinning_triangle(h=50, l=80, thick=4, ang=30, strut=5, wall=2, center=false);
// Example: Diagonal Brace Only
//   thinning_triangle(h=50, l=80, thick=4, ang=30, strut=5, wall=2, diagonly=true, center=false);
module thinning_triangle(h=50, l=100, thick=5, ang=30, strut=5, wall=3, diagonly=false, center=undef, anchor=CENTER, spin=0, orient=UP)
{
	dang = atan(h/l);
	dlen = h/sin(dang);
	size = [thick, h, l];
	orient_and_anchor(size, orient, anchor, spin=spin, center=center, noncentered=BOTTOM+FRONT, chain=true) {
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
		children();
	}
}


// Module: sparse_strut()
//
// Description:
//   Makes an open rectangular strut with X-shaped cross-bracing, designed to reduce
//   the need for support material in 3D printing.
//
// Usage:
//   sparse_strut(h, l, thick, [strut], [maxang], [max_bridge], [orient], [anchor])
//
// Arguments:
//   h = height of strut wall.
//   l = length of strut wall.
//   thick = thickness of strut wall.
//   maxang = maximum overhang angle of cross-braces.
//   max_bridge = maximum bridging distance between cross-braces.
//   strut = the width of the cross-braces.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments#orient).  Default: `UP`
//
// Example: Typical Shape
//   sparse_strut(h=40, l=100, thick=3);
// Example: Thinner Strut
//   sparse_strut(h=40, l=100, thick=3, strut=2);
// Example: Larger maxang
//   sparse_strut(h=40, l=100, thick=3, strut=2, maxang=45);
// Example: Longer max_bridge
//   sparse_strut(h=40, l=100, thick=3, strut=2, maxang=45, max_bridge=30);
module sparse_strut(h=50, l=100, thick=4, maxang=30, strut=5, max_bridge=20, anchor=CENTER, spin=0, orient=UP)
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

	size = [thick, l, h];
	orient_and_anchor(size, orient, anchor, spin=spin, chain=true) {
		yrot(90)
		linear_extrude(height=thick, convexity=4*yreps, center=true) {
			difference() {
				square([h, l], center=true);
				square([h-2*strut, l-2*strut], center=true);
			}
			yspread(ystep, n=yreps) {
				xspread(zstep, n=zreps) {
					skew_xy(planar=true, ya=-ang) square([(h-strut)/zreps, strut], center=true);
					skew_xy(planar=true, ya= ang) square([(h-strut)/zreps, strut], center=true);
				}
			}
		}
		children();
	}
}


// Module: sparse_strut3d()
//
// Usage:
//   sparse_strut3d(h, w, l, [thick], [maxang], [max_bridge], [strut], [orient], [anchor]);
//
// Description:
//   Makes an open rectangular strut with X-shaped cross-bracing, designed to reduce the
//   need for support material in 3D printing.
//
// Arguments:
//   h = Z size of strut.
//   w = X size of strut.
//   l = Y size of strut.
//   thick = thickness of strut walls.
//   maxang = maximum overhang angle of cross-braces.
//   max_bridge = maximum bridging distance between cross-braces.
//   strut = the width of the cross-braces.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments#orient).  Default: `UP`
//
// Example(Med): Typical Shape
//   sparse_strut3d(h=30, w=30, l=100);
// Example(Med): Thinner strut
//   sparse_strut3d(h=30, w=30, l=100, strut=2);
// Example(Med): Larger maxang
//   sparse_strut3d(h=30, w=30, l=100, strut=2, maxang=50);
// Example(Med): Smaller max_bridge
//   sparse_strut3d(h=30, w=30, l=100, strut=2, maxang=50, max_bridge=20);
module sparse_strut3d(h=50, l=100, w=50, thick=3, maxang=40, strut=3, max_bridge=30, anchor=CENTER, spin=0, orient=UP)
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

	size = [w, l, h];
	orient_and_anchor(size, orient, anchor, spin=spin, chain=true) {
		intersection() {
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
														down(strut) cube([strut, strut, zstep+strut], anchor=BOTTOM);
													}
												}
											}
											for (soff = [0 : supp_reps-1] ) {
												yflip_copy() {
													back(soff*supp_step) {
														skew_xy(ya=supp_ang) {
															cube([strut, strut, zstep], anchor=BOTTOM);
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
			cube([w,l,h], center=true);
		}
		children();
	}
}


// Module: corrugated_wall()
//
// Description:
//   Makes a corrugated wall which relieves contraction stress while still
//   providing support strength.  Designed with 3D printing in mind.
//
// Usage:
//   corrugated_wall(h, l, thick, [strut], [wall], [orient], [anchor]);
//
// Arguments:
//   h = height of strut wall.
//   l = length of strut wall.
//   thick = thickness of strut wall.
//   strut = the width of the cross-braces.
//   wall = thickness of corrugations.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments#orient).  Default: `UP`
//
// Example: Typical Shape
//   corrugated_wall(h=50, l=100);
// Example: Wider Strut
//   corrugated_wall(h=50, l=100, strut=8);
// Example: Thicker Wall
//   corrugated_wall(h=50, l=100, strut=8, wall=3);
module corrugated_wall(h=50, l=100, thick=5, strut=5, wall=2, anchor=CENTER, spin=0, orient=UP)
{
	amplitude = (thick - wall) / 2;
	period = min(15, thick * 2);
	steps = quantup(segs(thick/2),4);
	step = period/steps;
	il = l - 2*strut + 2*step;
	size = [thick, l, h];
	orient_and_anchor(size, orient, anchor, spin=spin, chain=true) {
		union() {
			linear_extrude(height=h-2*strut+0.1, slices=2, convexity=ceil(2*il/period), center=true) {
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
		children();
	}
}



// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
