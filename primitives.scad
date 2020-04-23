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
//   square(size, [center], [rounding], [chamfer], [anchor], [spin])
// Description:
//   When called as a module, creates a 2D square of the given size, with optional rounding or chamfering.
//   When called as a function, returns a 2D path/list of points for a square/rectangle of the given size.
// Arguments:
//   size = The size of the square to create.  If given as a scalar, both X and Y will be the same size.
//   rounding = The rounding radius for the corners.  If given as a list of four numbers, gives individual radii for each corner, in the order [X+Y+,X-Y+,X-Y-,X+Y-]. Default: 0 (no rounding)
//   chamfer = The chamfer size for the corners.  If given as a list of four numbers, gives individual chamfers for each corner, in the order [X+Y+,X-Y+,X-Y-,X+Y-].  Default: 0 (no chamfer)
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
// Example(2D): Mixed Chamferring and Rounding
//   square([40,30],center=true,rounding=[5,0,10,0],chamfer=[0,8,0,15],$fa=1,$fs=1);
// Example(2D): Called as Function
//   path = square([40,30], chamfer=5, anchor=FRONT, spin=30);
//   stroke(path, closed=true);
//   move_copies(path) color("blue") circle(d=2,$fn=8);
module square(size=1, center, rounding=0, chamfer=0, anchor, spin=0) {
	size = is_num(size)? [size,size] : point2d(size);
	anchor = get_anchor(anchor, center, FRONT+LEFT, FRONT+LEFT);
	pts = square(size=size, rounding=rounding, chamfer=chamfer, center=true);
	attachable(anchor,spin, two_d=true, size=size) {
		translate(-size/2) polygon(move(size/2,p=pts));  // Extraneous translation works around fine grid quantizing.
		children();
	}
}


function square(size=1, center, rounding=0, chamfer=0, anchor, spin=0) =
	assert(is_num(size)     || is_vector(size))
	assert(is_num(chamfer)  || len(chamfer)==4)
	assert(is_num(rounding) || len(rounding)==4)
	let(
		size = is_num(size)? [size,size] : point2d(size),
		anchor = get_anchor(anchor, center, FRONT+LEFT, FRONT+LEFT),
		complex = rounding!=0 || chamfer!=0
	)
	(rounding==0 && chamfer==0)? let(
		path = [
			[ size.x/2, -size.y/2],
			[-size.x/2, -size.y/2],
			[-size.x/2,  size.y/2],
			[ size.x/2,  size.y/2] 
		]
	) rot(spin, p=move(-vmul(anchor,size/2), p=path)) :
	let(
		chamfer = is_list(chamfer)? chamfer : [for (i=[0:3]) chamfer],
		rounding = is_list(rounding)? rounding : [for (i=[0:3]) rounding],
		quadorder = [3,2,1,0],
		quadpos = [[1,1],[-1,1],[-1,-1],[1,-1]],
		insets = [for (i=[0:3]) chamfer[i]>0? chamfer[i] : rounding[i]>0? rounding[i] : 0],
		insets_x = max(insets[0]+insets[1],insets[2]+insets[3]),
		insets_y = max(insets[0]+insets[3],insets[1]+insets[2])
	)
	assert(insets_x <= size.x, "Requested roundings and/or chamfers exceed the square width.")
	assert(insets_y <= size.y, "Requested roundings and/or chamfers exceed the square height.")
	let(
		path = [
			for(i = [0:3])
			let(
				quad = quadorder[i],
				inset = insets[quad],
				cverts = quant(segs(inset),4)/4,
				cp = vmul(size/2-[inset,inset], quadpos[quad]),
				step = 90/cverts,
				angs =
					chamfer[quad] > 0?  [0,-90]-90*[i,i] :
					rounding[quad] > 0? [for (j=[0:1:cverts]) 360-j*step-i*90] :
					[0]
			)
			each [for (a = angs) cp + inset*[cos(a),sin(a)]]
		]
	) complex?
		reorient(anchor,spin, two_d=true, path=path, p=path) :
		reorient(anchor,spin, two_d=true, size=size, p=path);


// Function&Module: circle()
// Usage:
//   circle(r|d, [realign], [circum])
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
	attachable(anchor,spin, two_d=true, r=rr) {
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
	) reorient(anchor,spin, two_d=true, r=rr, p=pts);



// Section: Primitive 3D Shapes


// Function&Module: cube()
// Usage: As Module
//   cube(size, [center]);
// Usage: As Function
//   vnf = cube(size, [center]);
// Description:
//   Creates a 3D cubic object with support for anchoring and attachments.
//   This can be used as a drop-in replacement for the built-in `cube()` module.
//   When called as a function, returns a [VNF](vnf.scad) for a cube.
// Arguments:
//   size = The size of the cube.
//   center = If given, overrides `anchor`.  A true value sets `anchor=CENTER`, false sets `anchor=ALLNEG`.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
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
// Example: Called as Function
//   vnf = cube([20,40,50]);
//   vnf_polyhedron(vnf);
module cube(size=1, center, anchor, spin=0, orient=UP)
{
	anchor = get_anchor(anchor, center, ALLNEG, ALLNEG);
	vnf = cube(size, center=true);
	siz = scalar_vec3(size);
	attachable(anchor,spin,orient, size=siz) {
		vnf_polyhedron(vnf, convexity=2);
		children();
	}
}

function cube(size=1, center, anchor, spin=0, orient=UP) =
	let(
		siz = scalar_vec3(size),
		anchor = get_anchor(anchor, center, ALLNEG, ALLNEG),
		unscaled = [
			[-1,-1,-1],[1,-1,-1],[1,1,-1],[-1,1,-1],
			[-1,-1, 1],[1,-1, 1],[1,1, 1],[-1,1, 1],
		]/2,
		verts = is_num(size)? unscaled * size :
			is_vector(size,3)? [for (p=unscaled) vmul(p,size)] :
			assert(is_num(size) || is_vector(size,3)),
		faces = [
			[0,1,2], [0,2,3],  //BOTTOM
			[0,4,5], [0,5,1],  //FRONT
			[1,5,6], [1,6,2],  //RIGHT
			[2,6,7], [2,7,3],  //BACK
			[3,7,4], [3,4,0],  //LEFT
			[6,4,7], [6,5,4]   //TOP
		]
	) [reorient(anchor,spin,orient, size=siz, p=verts), faces];


// Function&Module: cylinder()
// Usage: As Module
//   cylinder(h, r|d, [center]);
//   cylinder(h, r1/d1, r2/d2, [center]);
// Usage: As Function
//   vnf = cylinder(h, r|d, [center]);
//   vnf = cylinder(h, r1/d1, r2/d2, [center]);
// Description:
//   Creates a 3D cylinder or conic object with support for anchoring and attachments.
//   This can be used as a drop-in replacement for the built-in `cylinder()` module.
//   When called as a function, returns a [VNF](vnf.scad) for a cylinder.
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
module cylinder(h, r1, r2, center, l, r, d, d1, d2, anchor, spin=0, orient=UP)
{
	anchor = get_anchor(anchor, center, BOTTOM, BOTTOM);
	r1 = get_radius(r1=r1, r=r, d1=d1, d=d, dflt=1);
	r2 = get_radius(r1=r2, r=r, d1=d2, d=d, dflt=1);
	l = first_defined([h, l, 1]);
	sides = segs(max(r1,r2));
	vnf = cylinder(l=l, r1=r1, r2=r2, center=true);
	attachable(anchor,spin,orient, r1=r1, r2=r2, l=l) {
		vnf_polyhedron(vnf, convexity=2);
		children();
	}
}

function cylinder(h, r1, r2, center, l, r, d, d1, d2, anchor, spin=0, orient=UP) =
	let(
		anchor = get_anchor(anchor, center, BOTTOM, BOTTOM),
		r1 = get_radius(r1=r1, r=r, d1=d1, d=d, dflt=1),
		r2 = get_radius(r1=r2, r=r, d1=d2, d=d, dflt=1),
		l = first_defined([h, l, 1]),
		sides = segs(max(r1,r2)),
		verts = [
			for (i=[0:1:sides-1]) let(a=i*360/sides) [r1*cos(a),r1*sin(a),-l/2],
			for (i=[0:1:sides-1]) let(a=i*360/sides) [r2*cos(a),r2*sin(a), l/2],
		],
		faces = [
			[for (i=[0:1:sides-1]) sides-1-i],
			for (i=[0:1:sides-1]) [i, ((i+1)%sides)+sides, i+sides],
			for (i=[0:1:sides-1]) [i, (i+1)%sides, ((i+1)%sides)+sides],
			[for (i=[0:1:sides-1]) sides+i]
		]
	) [reorient(anchor,spin,orient, l=l, r1=r1, r2=r2, p=verts), faces];



// Function&Module: sphere()
// Usage: As Module
//   sphere(r|d, [circum], [style])
// Usage: As Function
//   vnf = sphere(r|d, [circum], [style])
// Description:
//   Creates a sphere object, with support for anchoring and attachments.
//   This is a drop-in replacement for the built-in `sphere()` module.
//   When called as a function, returns a [VNF](vnf.scad) for a sphere.
// Arguments:
//   r = Radius of the sphere.
//   d = Diameter of the sphere.
//   circum = If true, the sphere is made large enough to circumscribe the sphere of the ideal side.  Otherwise inscribes.  Default: false (inscribes)
//   style = The style of the sphere's construction. One of "orig", "alt", "stagger", or "icosa".  Default: "orig"
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
// Example: By Radius
//   sphere(r=50);
// Example: By Diameter
//   sphere(d=100);
// Figure(3D): style="orig"
//   sphere(d=100, style="orig", $fn=10);
// Figure(3D): style="alt"
//   sphere(d=100, style="alt", $fn=10);
// Figure(3D): style="stagger"
//   sphere(d=100, style="stagger", $fn=10);
// Figure(3D): style="icosa"
//   sphere(d=100, style="icosa", $fn=10);
//   // In "icosa" style, $fn is quantized
//   //   to the nearest multiple of 5.
// Example: Anchoring
//   sphere(d=100, anchor=FRONT);
// Example: Spin
//   sphere(d=100, anchor=FRONT, spin=45);
// Example: Orientation
//   sphere(d=100, anchor=FRONT, spin=45, orient=FWD);
// Example: Standard Connectors
//   sphere(d=50) show_anchors();
// Example: Called as Function
//   vnf = sphere(d=100, style="icosa");
//   vnf_polyhedron(vnf);
module sphere(r, d, circum=false, style="orig", anchor=CENTER, spin=0, orient=UP)
{
	r = get_radius(r=r, d=d, dflt=1);
	sides = segs(r);
	vnf = sphere(r=r, circum=circum, style=style);
	attachable(anchor,spin,orient, r=r) {
		vnf_polyhedron(vnf, convexity=2);
		children();
	}
}


function sphere(r, d, circum=false, style="orig", anchor=CENTER, spin=0, orient=UP) =
	let(
		r = get_radius(r=r, d=d, dflt=1),
		hsides = segs(r),
		vsides = max(2,ceil(hsides/2)),
		icosa_steps = round(max(5,hsides)/5),
		rr = circum? (r / cos(90/vsides) / cos(180/hsides)) : r,
		stagger = style=="stagger",
		verts = style=="orig"? [
			for (i=[0:1:vsides-1]) let(phi = (i+0.5)*180/(vsides))
			for (j=[0:1:hsides-1]) let(theta = j*360/hsides)
			spherical_to_xyz(rr, theta, phi),
		] : style=="alt" || style=="stagger"? [
			spherical_to_xyz(rr, 0, 0),
			for (i=[1:1:vsides-1]) let(phi = i*180/vsides)
				for (j=[0:1:hsides-1]) let(theta = (j+((stagger && i%2!=0)?0.5:0))*360/hsides)
					spherical_to_xyz(rr, theta, phi),
			spherical_to_xyz(rr, 0, 180)
		] : style=="icosa"? [
			for (tb=[0,1], j=[0,2], i = [0:1:4]) let(
				theta0 = i*360/5,
				theta1 = (i-0.5)*360/5,
				theta2 = (i+0.5)*360/5,
				phi0 = 180/3 * j,
				phi1 = 180/3,
				v0 = spherical_to_xyz(1,theta0,phi0),
				v1 = spherical_to_xyz(1,theta1,phi1),
				v2 = spherical_to_xyz(1,theta2,phi1),
				ax0 = vector_axis(v0, v1),
				ang0 = vector_angle(v0, v1),
				ax1 = vector_axis(v0, v2),
				ang1 = vector_angle(v0, v2)
			)
			for (k = [0:1:icosa_steps]) let(
				u = k/icosa_steps,
				vv0 = rot(ang0*u, ax0, p=v0),
				vv1 = rot(ang1*u, ax1, p=v0),
				ax2 = vector_axis(vv0, vv1),
				ang2 = vector_angle(vv0, vv1)
			)
			for (l = [0:1:k]) let(
				v = k? l/k : 0,
				pt = rot(ang2*v, v=ax2, p=vv0) * rr * (tb? -1 : 1)
			) pt
		] : assert(in_list(style,["orig","alt","stagger","icosa"])),
		lv = len(verts),
		faces = style=="orig"? [
			[for (i=[0:1:hsides-1]) hsides-i-1],
			[for (i=[0:1:hsides-1]) lv-hsides+i],
			for (i=[0:1:vsides-1], j=[0:1:hsides-1]) each [
				[(i+1)*hsides+j, i*hsides+j, i*hsides+(j+1)%hsides],
				[(i+1)*hsides+j, i*hsides+(j+1)%hsides, (i+1)*hsides+(j+1)%hsides],
			]
		] : style=="alt" || style=="stagger"? [
			for (i=[0:1:hsides-1]) let(
				b2 = lv-2-hsides
			) each [
				[i+1, 0, ((i+1)%hsides)+1],
				[lv-1, b2+i+1, b2+((i+1)%hsides)+1],
			],
			for (i=[0:1:vsides-3], j=[0:1:hsides-1]) let(
				base = 1 + hsides*i
			) each (
				(stagger && i%2!=0)? [
					[base+j, base+hsides+j%hsides, base+hsides+(j+hsides-1)%hsides],
					[base+j, base+(j+1)%hsides, base+hsides+j],
				] : [
					[base+j, base+(j+1)%hsides, base+hsides+(j+1)%hsides],
					[base+j, base+hsides+(j+1)%hsides, base+hsides+j],
				]
			)
		] : style=="icosa"? let(
			pyr = [for (x=[0:1:icosa_steps+1]) x],
			tri = sum(pyr),
			soff = cumsum(pyr)
		) [
			for (tb=[0,1], j=[0,1], i = [0:1:4]) let(
				base = ((((tb*2) + j) * 5) + i) * tri
			)
			for (k = [0:1:icosa_steps-1])
			for (l = [0:1:k]) let(
				v1 = base + soff[k] + l,
				v2 = base + soff[k+1] + l,
				v3 = base + soff[k+1] + (l + 1),
				faces = [
					if(l>0) [v1-1,v1,v2],
					[v1,v3,v2],
				],
				faces2 = (tb+j)%2? [for (f=faces) reverse(f)] : faces
			) each faces2
		] : []
	) [reorient(anchor,spin,orient, r=r, p=verts), faces];


// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
