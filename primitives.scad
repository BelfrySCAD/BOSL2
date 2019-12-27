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


// Function&Module: square()
// Usage:
//   square(size, [center], [anchor])
// Description:
//   When called as a module, creates a 2D square of the given size.
//   When called as a function, returns a 2D path/list of points for a square/rectangle of the given size.
// Arguments:
//   size = The size of the square to create.  If given as a scalar, both X and Y will be the same size.
//   rounding = The rounding radius for the corners.  Default: 0 (no rounding)
//   chamfer = The chamfer size for the corners.  Default: 0 (no chamfer)
//   center = If given and true, overrides `anchor` to be `CENTER`.  If given and false, overrides `anchor` to be `FRONT+LEFT`.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
// Example(2D):
//   square(40);
// Example(2D): Centered
//   square([40,30], center=true);
// Example(2D): Anchored
//   square([40,30], anchor=FRONT);
// Example(2D): Spun
//   square([40,30], anchor=FRONT, spin=30);
// Example(2D): Chamferred Rect
//   square([40,30], chamfer=5, center=true);
// Example(2D): Rounded Rect
//   square([40,30], rounding=5, center=true);
// Example(2D): Called as Function
//   path = square([40,30], chamfer=5, anchor=FRONT, spin=30);
//   stroke(path, closed=true);
//   place_copies(path) color("blue") circle(d=2,$fn=8);
module square(size=1, rounding=0, chamfer=0, center, anchor=FRONT+LEFT, spin=0) {
	size = is_num(size)? [size,size] : point2d(size);
	pts = square(size=size, rounding=rounding, center=false, chamfer=chamfer);
	orient_and_anchor(point3d(size), UP, anchor, spin=spin, center=center, noncentered=FRONT+LEFT, two_d=true, chain=true) {
		translate(-size/2) polygon(pts);
		children();
	}
}


function square(size=1, rounding=0, chamfer=0, center, anchor=FRONT+LEFT, spin=0) =
	let(
		anchor = center==true? CENTER : center==false? FRONT+LEFT : anchor,
		size = is_num(size)? [size,size] : point2d(size),
		s = size/2,
		cverts = max(0,floor((segs(rounding)-4)/4)),
		step = 90/(cverts+1),
		inset =
			chamfer>0?
				assert(size.x>=2*chamfer)
				assert(size.y>=2*chamfer)
				[2,2]*chamfer :
			rounding>0?
				assert(size.x>=2*rounding)
				assert(size.y>=2*rounding)
				[2,2]*rounding :
			[0,0],
		is = (size-inset)/2,
		path =
			chamfer>0? concat(
				[[ is.x,- s.y], [-is.x,- s.y]],
				[[- s.x,-is.y], [- s.x, is.y]],
				[[-is.x,  s.y], [ is.x,  s.y]],
				[[  s.x, is.y], [  s.x,-is.y]]
			) :
			rounding>0? concat(
				[for (i=[0:1:cverts-1]) let(ang=360-step*(i+1)) [ is.x,-is.y] + polar_to_xy(rounding,ang)],
				[[ is.x,- s.y], [-is.x,- s.y]],
				[for (i=[0:1:cverts-1]) let(ang=270-step*(i+1)) [-is.x,-is.y] + polar_to_xy(rounding,ang)],
				[[- s.x,-is.y], [- s.x, is.y]],
				[for (i=[0:1:cverts-1]) let(ang=180-step*(i+1)) [-is.x, is.y] + polar_to_xy(rounding,ang)],
				[[-is.x,  s.y], [ is.x,  s.y]],
				[for (i=[0:1:cverts-1]) let(ang= 90-step*(i+1)) [ is.x, is.y] + polar_to_xy(rounding,ang)],
				[[  s.x, is.y], [  s.x,-is.y]]
			) :
			[[s.x,-s.y], [-s.x,-s.y], [-s.x,s.y], [s.x,s.y]]
	) rot(spin, p=move(-vmul(anchor,s), p=path));


// Function&Module: circle()
// Usage:
//   circle(r|d, [anchor])
// Description:
//   When called as a module, creates a 2D polygon that approximates a circle of the given size.
//   When called as a function, returns a 2D list of points (path) for a polygon that approximates a circle of the given size.
// Arguments:
//   r = The radius of the circle to create.
//   d = The diameter of the circle to create.
//   realign = If true, rotates the polygon that approximates the circle by half of one size.
//   circum = If true, the polygon that approximates the circle will be upsized slightly to circumscribe the theoretical circle.  If false, it inscribes the theoretical circle.  Default: false
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
// Example(2D): By Radius
//   circle(r=25);
// Example(2D): By Diameter
//   circle(d=50);
// Example(2D): Anchoring
//   circle(d=50, anchor=FRONT);
// Example(2D): Spin
//   circle(d=50, anchor=FRONT, spin=45);
// Example(NORENDER): Called as Function
//   path = circle(d=50, anchor=FRONT, spin=45);
module circle(r, d, realign=false, circum=false, anchor=CENTER, spin=0) {
	r = get_radius(r=r, d=d, dflt=1);
	sides = segs(r);
	rr = circum? r/cos(180/sides) : r;
	pts = circle(r=rr, realign=realign, $fn=sides);
	orient_and_anchor([2*rr,2*rr,0], UP, anchor, spin=spin, geometry="cylinder", two_d=true, chain=true) {
		polygon(pts);
		children();
	}
}


function circle(r, d, realign=false, circum=false, anchor=CENTER, spin=0) =
	let(
		r = get_radius(r=r, d=d, dflt=1),
		sides = segs(r),
		offset = realign? 180/sides : 0,
		rr = r / (circum? cos(180/sides) : 1),
		pts = [for (i=[0:1:sides-1]) let(a=360-offset-i*360/sides) rr*[cos(a),sin(a)]]
	) rot(spin, p=move(-normalize(anchor)*rr, p=pts));



// Section: Primitive Shapes


// Module: cube()
//
// Description:
//   Creates a cube object, with support for anchoring and attachments.
//   This is a drop-in replacement for the built-in `cube()` module.
//
// Arguments:
//   size = The size of the cube.
//   center = If given, overrides `anchor`.  A true value sets `anchor=CENTER`, false sets `anchor=ALLNEG`.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
//
// Example: Simple cube.
//   cube(40);
// Example: Rectangular cube.
//   cube([20,40,50]);
// Example: Anchoring.
//   cube([20,40,50], anchor=BOTTOM+FRONT);
// Example: Spin.
//   cube([20,40,50], anchor=BOTTOM+FRONT, spin=30);
// Example: Orientation.
//   cube([20,40,50], anchor=BOTTOM+FRONT, spin=30, orient=FWD);
// Example: Standard Connectors.
//   cube(40, center=true) show_anchors();
module cube(size=1, center, anchor=ALLNEG, spin=0, orient=UP)
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
//   cylinder(h, r|d, [center]);
//   cylinder(h, r1/d1, r2/d2, [center]);
// Description:
//   Creates a cylinder object, with support for anchoring and attachments.
//   This is a drop-in replacement for the built-in `cylinder()` module.
// Arguments:
//   l / h = The height of the cylinder.
//   r1 = The bottom radius of the cylinder.  (Before orientation.)
//   r2 = The top radius of the cylinder.  (Before orientation.)
//   center = If given, overrides `anchor`.  A true value sets `anchor=CENTER`, false sets `anchor=BOTTOM`.
//   d1 = The bottom diameter of the cylinder.  (Before orientation.)
//   d2 = The top diameter of the cylinder.  (Before orientation.)
//   r = The radius of the cylinder.
//   d = The diameter of the cylinder.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
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
// Example(Med): Anchoring
//   cylinder(h=40, r1=10, r2=5, anchor=BOTTOM+FRONT);
// Example(Med): Spin
//   cylinder(h=40, r1=10, r2=5, anchor=BOTTOM+FRONT, spin=45);
// Example(Med): Orient
//   cylinder(h=40, r1=10, r2=5, anchor=BOTTOM+FRONT, spin=45, orient=FWD);
// Example(Big): Standard Connectors
//   xdistribute(40) {
//       cylinder(h=30, d=25) show_anchors();
//       cylinder(h=30, d1=25, d2=10) show_anchors();
//   }
module cylinder(h, r1, r2, center, l, r, d, d1, d2, anchor=BOTTOM, spin=0, orient=UP)
{
	r1 = get_radius(r1=r1, r=r, d1=d1, d=d, dflt=1);
	r2 = get_radius(r1=r2, r=r, d1=d2, d=d, dflt=1);
	l = first_defined([h, l, 1]);
	hh = l/2;
	sides = segs(max(r1,r2));
	size = [r1*2, r1*2, l];
	path = [[0,hh],[r2,hh],[r1,-hh],[0,-hh]];
	orient_and_anchor(size, orient, anchor, center, spin=spin, size2=[r2*2,r2*2], noncentered=BOTTOM, geometry="cylinder", chain=true) {
		rotate_extrude(convexity=2, $fn=sides) {
			polygon(path);
		}
		children();
	}
}



// Module: sphere()
// Usage:
//   sphere(r|d)
// Description:
//   Creates a sphere object, with support for anchoring and attachments.
//   This is a drop-in replacement for the built-in `sphere()` module.
// Arguments:
//   r = Radius of the sphere.
//   d = Diameter of the sphere.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
// Example: By Radius
//   sphere(r=50);
// Example: By Diameter
//   sphere(d=100);
// Example: Anchoring
//   sphere(d=100, anchor=FRONT);
// Example: Spin
//   sphere(d=100, anchor=FRONT, spin=45);
// Example: Orientation
//   sphere(d=100, anchor=FRONT, spin=45, orient=FWD);
// Example: Standard Connectors
//   sphere(d=50) show_anchors();
module sphere(r, d, anchor=CENTER, spin=0, orient=UP)
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
