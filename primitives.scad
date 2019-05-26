//////////////////////////////////////////////////////////////////////
// LibFile: primitives.scad
//   The basic built-in shapes, reworked to integrate better with
//   other BOSL2 library shapes and utilities.
//   To use, add the following lines to the beginning of your file:
//   ```
//   include <BOSL2/std.scad>
//   ```
//////////////////////////////////////////////////////////////////////


// Section: 2D Primitives


// Module: square()
// Usage:
//   square(size, [center], [anchor])
// Description:
//   Creates a 2D square of the given size.
// Arguments:
//   size = The size of the square to create.  If given as a scalar, both X and Y will be the same size.
//   center = If given and true, overrides `anchor` to be `CENTER`.  If given and false, overrides `anchor` to be `FRONT+LEFT`.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments#spin).  Default: `0`
// Example(2D):
//   square(40);
// Example(2D): Centered
//   square([40,30], center=true);
// Example(2D): Anchoring
//   square([40,30], anchor=FRONT);
module square(size, center=undef, anchor=FRONT+LEFT, spin=0) {
	size = is_num(size)? [size,size] : point2d(size);
	s = size/2;
	pts = [[-s.x,-s.y], [-s.x,s.y], [s.x,s.y], [s.x,-s.y]];
	orient_and_anchor(point3d(size), UP, anchor, spin=spin, center=center, noncentered=FRONT+LEFT, two_d=true, chain=true) {
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
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments#spin).  Default: `0`
// Example(2D): By Radius
//   circle(r=25);
// Example(2D): By Diameter
//   circle(d=50);
// Example(2D): Anchoring
//   circle(d=50, anchor=FRONT);
module circle(r=undef, d=undef, anchor=CENTER, spin=0) {
	r = get_radius(r=r, d=d, dflt=1);
	sides = segs(r);
	pts = [for (a=[0:360/sides:360-EPSILON]) r*[cos(a),sin(a)]];
	orient_and_anchor([2*r,2*r,0], UP, anchor, spin=spin, geometry="cylinder", two_d=true, chain=true) {
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
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments#orient).  Default: `UP`
//   center = If given, overrides `anchor`.  A true value sets `anchor=CENTER`, false sets `anchor=ALLNEG`.
//
// Example: Simple cube.
//   cube(40);
// Example: Rectangular cube.
//   cuboid([20,40,50]);
// Example: Standard Connectors.
//   cube(40, center=true) show_anchors();
module cube(size, center=undef, anchor=ALLNEG, spin=0, orient=UP)
{
	size = scalar_vec3(size);
	orient_and_anchor(size, orient, anchor, center, spin=spin, noncentered=ALLNEG, chain=true) {
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
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments#orient).  Default: `UP`
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
module cylinder(r=undef, d=undef, r1=undef, r2=undef, d1=undef, d2=undef, h=undef, l=undef, center=undef, anchor=BOTTOM, spin=0, orient=UP)
{
	r1 = get_radius(r1=r1, r=r, d1=d1, d=d, dflt=1);
	r2 = get_radius(r1=r2, r=r, d1=d2, d=d, dflt=1);
	l = first_defined([h, l]);
	sides = segs(max(r1,r2));
	size = [r1*2, r1*2, l];
	orient_and_anchor(size, orient, anchor, center, spin=spin, size2=[r2*2,r2*2], noncentered=BOTTOM, geometry="cylinder", chain=true) {
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
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments#orient).  Default: `UP`
// Example: By Radius
//   sphere(r=50);
// Example: By Diameter
//   sphere(d=100);
// Example: Standard Connectors
//   sphere(d=50) show_anchors();
module sphere(r=undef, d=undef, anchor=CENTER, spin=0, orient=UP)
{
	r = get_radius(r=r, d=d, dflt=1);
	sides = segs(r);
	size = [r*2, r*2, r*2];
	orient_and_anchor(size, orient, anchor, spin=spin, geometry="sphere", chain=true) {
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
