//////////////////////////////////////////////////////////////////////
// LibFile: shapes2d.scad
//   Common useful 2D shapes.
//   To use, add the following lines to the beginning of your file:
//   ```
//   include <BOSL2/std.scad>
//   ```
//////////////////////////////////////////////////////////////////////


// Section: 2D Drawing Helpers

// Module: stroke()
// Usage:
//   stroke(path, width, [endcap], [close]);
// Description:
//   Draws a 2D line path with a given line thickness.
// Arguments:
//   path = The 2D path to draw along.
//   width = The width of the line to draw.
//   endcaps = If true, draw round endcaps at the ends of the line.
//   close = If true, draw an additional line from the end of the path to the start.
// Example(2D):
//   path = [[0,100], [100,100], [200,0], [100,-100], [100,0]];
//   stroke(path, width=10, endcaps=false);
// Example(2D):
//   path = [[0,100], [100,100], [200,0], [100,-100], [100,0]];
//   stroke(path, width=20, endcaps=true);
// Example(2D):
//   path = [[0,100], [100,100], [200,0], [100,-100], [100,0]];
//   stroke(path, width=20, endcaps=true, close=true);
module stroke(path, width=1, endcaps=true, close=false)
{
	$fn = quantup(segs(width/2),4);
	path = close? concat(path,[path[0]]) : path;
	segments = pair(path);
	segpairs = pair(segments);

	// Line segments
	for (seg = segments) {
		delt = seg[1] - seg[0];
		translate(seg[0])
			rot(from=BACK,to=delt)
				left(width/2)
					square([width, norm(delt)], center=false);
	}

	// Joints
	for (segpair = segpairs) {
		seg1 = segpair[0];
		seg2 = segpair[1];
		delt1 = seg1[1] - seg1[0];
		delt2 = seg2[1] - seg2[0];
		hull() {
			translate(seg1[1])
				rot(from=BACK,to=delt1)
					circle(d=width);
			translate(seg2[0])
				rot(from=BACK,to=delt2)
					circle(d=width);
		}
	}

	// Endcaps
	if (endcaps) {
		seg1 = segments[0];
		delt1 = seg1[1] - seg1[0];
		translate(seg1[0])
			rot(from=BACK, to=delt1)
				circle(d=width);
		seg2 = select(segments,-1);
		delt2 = seg2[1] - seg2[0];
		translate(seg2[1])
			rot(from=BACK, to=delt2)
				circle(d=width);
	}
}


// Section: 2D Shapes


// Function&Module: pie_slice2d()
// Usage:
//   pie_slice2d(r|d, ang);
// Description:
//   When called as a function, returns the 2D path for a "pie" slice of a circle.
//   When called as a module, creates a 2D "pie" slice of a circle.
// Arguments:
//   r = The radius of the circle to get a slice of.
//   d = The diameter of the circle to get a slice of.
//   ang = The angle of the arc of the pie slice.
// Examples(2D):
//   pie_slice2d(r=50,ang=30);
//   pie_slice2d(d=100,ang=45);
//   pie_slice2d(d=40,ang=120);
//   pie_slice2d(d=40,ang=240);
// Example(2D): Called as Function
//   stroke(close=true, pie_slice2d(r=50,ang=30));
function pie_slice2d(r=undef, d=undef, ang=30) =
	let(
		r = get_radius(r=r, d=d, dflt=10),
		sides = ceil(segs(r)*ang/360)
	) concat(
		[[0,0]],
		[for (i=[0:1:sides]) let(a=i*ang/sides) r*[cos(a),sin(a)]]
	);


module pie_slice2d(r=undef, d=undef, ang=30) {
	pts = pie_slice2d(r=r, d=d, ang=ang);
	polygon(pts);
}


// Function&Module: trapezoid()
// Usage:
//   trapezoid(h, w1, w2);
// Description:
//   When called as a function, returns a 2D path for a trapezoid with parallel front and back sides.
//   When called as a module, creates a 2D trapezoid with parallel front and back sides.
// Arguments:
//   h = The Y axis height of the trapezoid.
//   w1 = The X axis width of the front end of the trapezoid.
//   w2 = The X axis width of the back end of the trapezoid.
// Examples(2D):
//   trapezoid(h=30, w1=40, w2=20);
//   trapezoid(h=25, w1=20, w2=35);
//   trapezoid(h=20, w1=40, w2=0);
// Example(2D): Called as Function
//   stroke(close=true, trapezoid(h=30, w1=40, w2=20));
function trapezoid(h, w1, w2) =
	[[-w1/2,-h/2], [-w2/2,h/2], [w2/2,h/2], [w1/2,-h/2]];


module trapezoid(h, w1, w2)
	polygon(trapezoid(h=h, w1=w1, w2=w2));


// Function&Module: regular_ngon()
// Usage:
//   regular_ngon(n, or|od, [realign]);
//   regular_ngon(n, ir|id, [realign]);
//   regular_ngon(n, side, [realign]);
// Description:
//   When called as a function, returns a 2D path for a regular N-sided polygon.
//   When called as a module, creates a 2D regular N-sided polygon.
// Arguments:
//   n = The number of sides.
//   or = Outside radius, at points.
//   od = Outside diameter, at points.
//   ir = Inside radius, at center of sides.
//   id = Inside diameter, at center of sides.
//   side = Length of each side.
//   realign = If false, a tip is aligned with the Y+ axis.  If true, the midpoint of a side is aligned with the Y+ axis.  Default: false
// Example(2D): by Outer Size
//   regular_ngon(n=5, or=30);
//   regular_ngon(n=5, od=60);
// Example(2D): by Inner Size
//   regular_ngon(n=5, ir=30);
//   regular_ngon(n=5, id=60);
// Example(2D): by Side Length
//   regular_ngon(n=8, side=20);
// Example(2D): Realigned
//   regular_ngon(n=8, side=20, realign=true);
// Example(2D): Called as Function
//   stroke(close=true, regular_ngon(n=6, or=30));
function regular_ngon(n=6, or=undef, od=undef, ir=undef, id=undef, side=undef, realign=false) =
	let(
		sc = 1/cos(180/n),
		r = get_radius(r1=ir*sc, r=or, d1=id*sc, d=od, dflt=side/2/sin(180/n)),
		offset = 90 + (realign? (180/n) : 0)
	) [for (a=[0:360/n:360-EPSILON]) r*[cos(a+offset),sin(a+offset)]];


module regular_ngon(n=6, or=undef, od=undef, ir=undef, id=undef, side=undef, realign=false)
	polygon(regular_ngon(n=n,or=or,od=od,ir=ir,id=id,side=side,realign=realign));


// Function&Module: pentagon()
// Usage:
//   pentagon(or|od, [realign]);
//   pentagon(ir|id, [realign];
//   pentagon(side, [realign];
// Description:
//   When called as a function, returns a 2D path for a regular pentagon.
//   When called as a module, creates a 2D regular pentagon.
// Arguments:
//   or = Outside radius, at points.
//   od = Outside diameter, at points.
//   ir = Inside radius, at center of sides.
//   id = Inside diameter, at center of sides.
//   side = Length of each side.
//   realign = If false, a tip is aligned with the Y+ axis.  If true, the midpoint of a side is aligned with the Y+ axis.  Default: false
// Example(2D): by Outer Size
//   pentagon(or=30);
//   pentagon(od=60);
// Example(2D): by Inner Size
//   pentagon(ir=30);
//   pentagon(id=60);
// Example(2D): by Side Length
//   pentagon(side=20);
// Example(2D): Realigned
//   pentagon(side=20, realign=true);
// Example(2D): Called as Function
//   stroke(close=true, pentagon(or=30));
function pentagon(or=undef, od=undef, ir=undef, id=undef, side=undef, realign=false) =
	regular_ngon(n=5, or=or, od=od, ir=ir, id=id, side=side, realign=realign);


module pentagon(or=undef, od=undef, ir=undef, id=undef, side=undef, realign=false)
	polygon(pentagon(or=or, od=od, ir=ir, id=id, side=side, realign=realign));


// Function&Module: hexagon()
// Usage:
//   hexagon(or, od, ir, id, side);
// Description:
//   When called as a function, returns a 2D path for a regular hexagon.
//   When called as a module, creates a 2D regular hexagon.
// Arguments:
//   or = Outside radius, at points.
//   od = Outside diameter, at points.
//   ir = Inside radius, at center of sides.
//   id = Inside diameter, at center of sides.
//   side = Length of each side.
//   realign = If false, a tip is aligned with the Y+ axis.  If true, the midpoint of a side is aligned with the Y+ axis.  Default: false
// Example(2D): by Outer Size
//   hexagon(or=30);
//   hexagon(od=60);
// Example(2D): by Inner Size
//   hexagon(ir=30);
//   hexagon(id=60);
// Example(2D): by Side Length
//   hexagon(side=20);
// Example(2D): Realigned
//   hexagon(side=20, realign=true);
// Example(2D): Called as Function
//   stroke(close=true, hexagon(or=30));
function hexagon(or=undef, od=undef, ir=undef, id=undef, side=undef, realign=false) =
	regular_ngon(n=6, or=or, od=od, ir=ir, id=id, side=side, realign=realign);


module hexagon(or=undef, od=undef, ir=undef, id=undef, side=undef, realign=false)
	polygon(hexagon(or=or, od=od, ir=ir, id=id, side=side, realign=realign));


// Function&Module: octagon()
// Usage:
//   octagon(or, od, ir, id, side);
// Description:
//   When called as a function, returns a 2D path for a regular octagon.
//   When called as a module, creates a 2D regular octagon.
// Arguments:
//   or = Outside radius, at points.
//   od = Outside diameter, at points.
//   ir = Inside radius, at center of sides.
//   id = Inside diameter, at center of sides.
//   side = Length of each side.
//   realign = If false, a tip is aligned with the Y+ axis.  If true, the midpoint of a side is aligned with the Y+ axis.  Default: false
// Example(2D): by Outer Size
//   octagon(or=30);
//   octagon(od=60);
// Example(2D): by Inner Size
//   octagon(ir=30);
//   octagon(id=60);
// Example(2D): by Side Length
//   octagon(side=20);
// Example(2D): Realigned
//   octagon(side=20, realign=true);
// Example(2D): Called as Function
//   stroke(close=true, octagon(or=30));
function octagon(or=undef, od=undef, ir=undef, id=undef, side=undef, realign=false) =
	regular_ngon(n=8, or=or, od=od, ir=ir, id=id, side=side, realign=realign);


module octagon(or=undef, od=undef, ir=undef, id=undef, side=undef, realign=false)
	polygon(octagon(or=or, od=od, ir=ir, id=id, side=side, realign=realign));


// Function&Module: glued_circles()
// Usage:
//   glued_circles(r|d, spread, tangent);
// Description:
//   When called as a function, returns a 2D path forming a shape of two circles joined by curved waist.
//   When called as a module, creates a 2D shape of two circles joined by curved waist.
// Arguments:
//   r = The radius of the end circles.
//   d = The diameter of the end circles.
//   spread = The distance between the centers of the end circles.
//   tangent = The angle in degrees of the tangent point for the joining arcs, measured away from the Y axis.
// Examples(2D):
//   glued_circles(r=15, spread=40, tangent=45);
//   glued_circles(d=30, spread=30, tangent=30);
//   glued_circles(d=30, spread=30, tangent=15);
//   glued_circles(d=30, spread=30, tangent=-30);
// Example(2D): Called as Function
//   stroke(close=true, glued_circles(r=15, spread=40, tangent=45));
function glued_circles(r=undef, d=undef, spread=10, tangent=30) =
	let(
		r = get_radius(r=r, d=d, dflt=10),
		r2 = (spread/2 / sin(tangent)) - r,
		cp1 = [spread/2, 0],
		cp2 = [0, (r+r2)*cos(tangent)],
		sa1 = 90-tangent,
		ea1 = 270+tangent,
		lobearc = ea1-sa1,
		lobesegs = floor(segs(r)*lobearc/360),
		lobestep = lobearc / lobesegs,
		sa2 = 270-tangent,
		ea2 = 270+tangent,
		subarc = ea2-sa2,
		arcsegs = ceil(segs(r2)*abs(subarc)/360),
		arcstep = subarc / arcsegs
	) concat(
		[for (i=[0:1:lobesegs]) let(a=sa1+i*lobestep)     r  * [cos(a),sin(a)] - cp1],
		tangent==0? [] : [for (i=[0:1:arcsegs])  let(a=ea2-i*arcstep+180)  r2 * [cos(a),sin(a)] - cp2],
		[for (i=[0:1:lobesegs]) let(a=sa1+i*lobestep+180) r  * [cos(a),sin(a)] + cp1],
		tangent==0? [] : [for (i=[0:1:arcsegs])  let(a=ea2-i*arcstep)      r2 * [cos(a),sin(a)] + cp2]
	);


module glued_circles(r=undef, d=undef, spread=10, tangent=30)
	polygon(glued_circles(r=r, d=d, spread=spread, tangent=tangent));


// Function&Module: star()
// Usage:
//   star(n, r|d, ir|id|step, [realign]);
// Description:
//   When called as a function, returns the path needed to create a star polygon with N points.
//   When called as a module, creates a star polygon with N points.
// Arguments:
//   n = The number of stellate tips on the star.
//   r = The radius to the tips of the star.
//   d = The diameter to the tips of the star.
//   ir = The radius to the inner corners of the star.
//   id = The diameter to the inner corners of the star.
//   step = Calculates the radius of the inner star corners by virtually drawing a straight line `step` tips around the star.  2 <= step < n/2
//   realign = If false, a tip is aligned with the Y+ axis.  If true, an inner corner is aligned with the Y+ axis.  Default: false
// Examples(2D):
//   star(n=5, r=50, ir=25);
//   star(n=5, r=50, step=2);
//   star(n=7, r=50, step=2);
//   star(n=7, r=50, step=3);
// Example(2D): Realigned
//   star(n=7, r=50, step=3, realign=true);
// Example(2D): Called as Function
//   stroke(close=true, star(n=5, r=50, ir=25));
function star(n, r, d, ir, id, step, realign=false) =
	let(
		r = get_radius(r=r, d=d),
		count = num_defined([ir,id,step]),
		stepOK = is_undef(step) || (step>1 && step<n/2)
	)
	assert(count==1, "Must specify exactly one of ir, id, step")
	assert(stepOK, str("Parameter 'step' must be between 2 and ",floor(n/2)," for ",n," point star"))
	let(
		stepr = is_undef(step)? r : r*cos(180*step/n)/cos(180*(step-1)/n),
		ir = get_radius(r=ir, d=id, dflt=stepr),
		offset = 90+(realign? 180/n : 0)
	)
	[for(i=[0:1:2*n-1]) let(theta=180*i/n+offset, radius=(i%2)?ir:r) radius*[cos(theta), sin(theta)]];


module star(n, r, d, ir, id, step, realign=false)
	polygon(star(n=n, r=r, d=d, ir=ir, id=id, step=step, realign=realign));


function _superformula(theta,m1,m2,n1,n2=1,n3=1,a=1,b=1) =
	pow(pow(abs(cos(m1*theta/4)/a),n2)+pow(abs(sin(m2*theta/4)/b),n3),-1/n1);


// Function&Module: superformula_shape()
// Usage:
//   superformula_shape(step,m1,m2,n1,n2,n3,[a],[b]);
// Description:
//   When called as a function, returns a 2D path for the outline of the [Superformula](https://en.wikipedia.org/wiki/Superformula) shape.
//   When called as a module, creates a 2D [Superformula](https://en.wikipedia.org/wiki/Superformula) shape.
// Arguments:
//   step = The angle step size for sampling the superformula shape.  Smaller steps are slower but more accurate.
//   scale = The scaling multiplier for the size of the shape.
//   m1 = The m1 argument for the superformula.
//   m2 = The m2 argument for the superformula.
//   n1 = The n1 argument for the superformula.
//   n2 = The n2 argument for the superformula.
//   n3 = The n3 argument for the superformula.
//   a = The a argument for the superformula.
//   b = The b argument for the superformula.
// Example(2D):
//   superformula_shape(step=0.5,scale=100,m1=16,m2=16,n1=0.5,n2=0.5,n3=16);
// Example(2D): Called as Function
//   stroke(close=true, superformula_shape(step=0.5,scale=100,m1=16,m2=16,n1=0.5,n2=0.5,n3=16));
function superformula_shape(step=0.5,scale=1,m1,m2,n1,n2=1,n3=1,a=1,b=1) =
	[for (a=[0:step:360]) let(r=scale*_superformula(theta=a,m1=m1,m2=m2,n1=n1,n2=n2,n3=n3)) r*[cos(a),sin(a)]];


module superformula_shape(step=0.5,scale=1,m1,m2,n1,n2=1,n3=1,a=1,b=1)
	polygon(superformula_shape(step=step,scale=scale,m1=m1,m2=m2,n1=n1,n2=n2,n3=n3,a=a,b=b));


// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
