//////////////////////////////////////////////////////////////////////
// LibFile: primitives.scad
//   The basic built-in shapes, reworked to integrate better with
//   other BOSL2 library shapes and utilities.
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



// Section: 2D Primitives


// Module: square()
// Usage:
//   square(size, [center], [anchor])
// Description:
//   Creates a 2D square of the given size.
// Arguments:
//   size = The size of the square to create.  If given as a scalar, both X and Y will be the same size.
//   center = If given and true, overrides `anchor` to be `CENTER`.  If given and false, overrides `anchor` to be `FRONT+LEFT`.
//   anchor = The side of the square to center on the origin.  Default: `FRONT+LEFT`
module square(size, center=undef, anchor=FRONT+LEFT) {
	size = is_num(size)? [size,size] : point2d(size);
	s = size/2;
	pts = [[-s.x,-s.y], [-s.x,s.y], [s.x,s.y], [s.x,-s.y]];
	orient_and_anchor(point3d(size), ORIENT_Z, anchor, center, noncentered=FRONT+LEFT, two_d=true, chain=true) {
		polygon(pts);
		children();
	}
}


// Module: circle()
// Usage:
//   circle(r|d, [anchor])
// Description:
//   Creates a 2D circle of the given size.
// Arguments:
//   r = The radius of the circle to create.
//   d = The diameter of the circle to create.
//   anchor = The side of the circle to center on the origin.  Default: `CENTER`
module circle(r=undef, d=undef, anchor=CENTER) {
	r = get_radius(r=r, d=d, dflt=1);
	sides = segs(r);
	pts = [for (a=[0:360/sides:360-EPSILON]) r*[cos(a),sin(a)]];
	orient_and_anchor([2*r,2*r,0], ORIENT_Z, anchor, geometry="cylinder", two_d=true, chain=true) {
		polygon(pts);
		children();
	}
}



// Section: Primitive Shapes


// Module: cube()
//
// Description:
//   Creates a cube object, with support for anchoring and attachments.
//   This is a drop-in replacement for the built-in `cube()` module.
//
// Arguments:
//   size = The size of the cube.
//   anchor = The side of the origin to anchor to.  Use constants from `constants.scad`.  Default: `ALLNEG`
//   center = If given, overrides `anchor`.  A true value sets `anchor=CENTER`, false sets `anchor=ALLNEG`.
//
// Example: Simple regular cube.
//   cube(40);
// Example: Rectangular cube.
//   cuboid([20,40,50]);
// Example: Standard Connectors.
//   cube(40, center=true) show_anchors();
module cube(size, center=undef, anchor=ALLNEG)
{
	size = scalar_vec3(size);
	orient_and_anchor(size, ORIENT_Z, anchor, center, noncentered=ALLPOS, chain=true) {
		linear_extrude(height=size.z, convexity=2, center=true) {
			square([size.x, size.y], center=true);
		}
		children();
	}
}


// Module: cylinder()
// Usage:
//   cylinder(h, r|d, [center], [orient], [anchor]);
//   cylinder(h, r1/d1, r2/d2, [center], [orient], [anchor]);
// Description:
//   Creates a cylinder object, with support for anchoring and attachments.
//   This is a drop-in replacement for the built-in `cylinder()` module.
// Arguments:
//   l / h = The height of the cylinder.
//   r = The radius of the cylinder.
//   r1 = The bottom radius of the cylinder.  (Before orientation.)
//   r2 = The top radius of the cylinder.  (Before orientation.)
//   d = The diameter of the cylinder.
//   d1 = The bottom diameter of the cylinder.  (Before orientation.)
//   d2 = The top diameter of the cylinder.  (Before orientation.)
//   orient = Orientation of the cylinder.  Use the `ORIENT_` constants from `constants.scad`.  Default: vertical.
//   anchor = The side of the part to anchor to the origin.  Use constants from `constants.scad`.  Default: `UP`
//   center = If given, overrides `anchor`.  A true value sets `anchor=CENTER`, false sets `anchor=BOTTOM`.
// Example: By Radius
//   xdistribute(30) {
//       cylinder(h=40, r=10);
//       cylinder(h=40, r1=10, r2=5);
//   }
// Example: By Diameter
//   xdistribute(30) {
//       cylinder(h=40, d=25);
//       cylinder(h=40, d1=25, d2=10);
//   }
// Example: Standard Connectors
//   xdistribute(40) {
//       cylinder(h=30, d=25) show_anchors();
//       cylinder(h=30, d1=25, d2=10) show_anchors();
//   }
module cylinder(r=undef, d=undef, r1=undef, r2=undef, d1=undef, d2=undef, h=undef, l=undef, center=undef, orient=ORIENT_Z, anchor=BOTTOM)
{
	r1 = get_radius(r1=r1, r=r, d1=d1, d=d, dflt=1);
	r2 = get_radius(r1=r2, r=r, d1=d2, d=d, dflt=1);
	l = first_defined([h, l]);
	sides = segs(max(r1,r2));
	size = [r1*2, r1*2, l];
	orient_and_anchor(size, orient, anchor, center, size2=[r2*2,r2*2], noncentered=BOTTOM, geometry="cylinder", chain=true) {
		linear_extrude(height=l, scale=r2/r1, convexity=2, center=true) {
			circle(r=r1, $fn=sides);
		}
		children();
	}
}



// Module: sphere()
// Usage:
//   sphere(r|d, [orient], [anchor])
// Description:
//   Creates a sphere object, with support for anchoring and attachments.
//   This is a drop-in replacement for the built-in `sphere()` module.
// Arguments:
//   r = Radius of the sphere.
//   d = Diameter of the sphere.
//   orient = Orientation of the sphere, if you don't like where the vertices lay.  Use the `ORIENT_` constants from `constants.scad`.  Default: `ORIENT_Z`.
//   anchor = Alignment of the sphere.  Use the constants from `constants.scad`.  Default: `CENTER`.
// Example: By Radius
//   sphere(r=50);
// Example: By Diameter
//   sphere(d=100);
// Example: Standard Connectors
//   sphere(d=50) show_anchors();
module sphere(r=undef, d=undef, orient=ORIENT_Z, anchor=CENTER)
{
	r = get_radius(r=r, d=d, dflt=1);
	sides = segs(r);
	size = [r*2, r*2, r*2];
	orient_and_anchor(size, orient, anchor, geometry="sphere", chain=true) {
		rotate_extrude(convexity=2) {
			difference() {
				circle(r=r, $fn=sides);
				left(r+0.1) square(r*2+0.2, center=true);
			}
		}
		children();
	}
}



// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
