//////////////////////////////////////////////////////////////////////
// LibFile: primitives.scad
//   The basic built-in shapes, reworked to integrate better with
//   other BOSL2 library shapes and utilities.
// Includes:
//   include <BOSL2/std.scad>
//////////////////////////////////////////////////////////////////////


// Section: 2D Primitives


// Function&Module: square()
// Topics: Shapes (2D), Path Generators (2D)
// Usage: As a Built-in Module
//   square(size, [center]);
// Usage: As a Function
//   path = square(size, [center]);
// See Also: rect()
// Description:
//   When called as the builtin module, creates a 2D square or rectangle of the given size.
//   When called as a function, returns a 2D path/list of points for a square/rectangle of the given size.
// Arguments:
//   size = The size of the square to create.  If given as a scalar, both X and Y will be the same size.
//   center = If given and true, overrides `anchor` to be `CENTER`.  If given and false, overrides `anchor` to be `FRONT+LEFT`.
//   ---
//   anchor = (Function only) Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = (Function only) Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
// Example(2D):
//   square(40);
// Example(2D): Centered
//   square([40,30], center=true);
// Example(2D): Called as Function
//   path = square([40,30], anchor=FRONT, spin=30);
//   stroke(path, closed=true);
//   move_copies(path) color("blue") circle(d=2,$fn=8);
function square(size=1, center, anchor, spin=0) =
    let(
        anchor = get_anchor(anchor, center, [-1,-1], [-1,-1]),
        size = is_num(size)? [size,size] : point2d(size),
        path = [
            [ size.x,-size.y],
            [-size.x,-size.y],
            [-size.x, size.y],
            [ size.x, size.y]
        ] / 2
    ) reorient(anchor,spin, two_d=true, size=size, p=path);


// Function&Module: circle()
// Topics: Shapes (2D), Path Generators (2D)
// Usage: As a Built-in Module
//   circle(r|d=, ...);
// Usage: As a Function
//   path = circle(r|d=, ...);
// See Also: oval()
// Description:
//   When called as the builtin module, creates a 2D polygon that approximates a circle of the given size.
//   When called as a function, returns a 2D list of points (path) for a polygon that approximates a circle of the given size.
// Arguments:
//   r = The radius of the circle to create.
//   d = The diameter of the circle to create.
//   ---
//   anchor = (Function only) Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = (Function only) Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
// Example(2D): By Radius
//   circle(r=25);
// Example(2D): By Diameter
//   circle(d=50);
// Example(NORENDER): Called as Function
//   path = circle(d=50, anchor=FRONT, spin=45);
function circle(r, d, anchor=CENTER, spin=0) =
    let(
        r = get_radius(r=r, d=d, dflt=1),
        sides = segs(r),
        path = [for (i=[0:1:sides-1]) let(a=360-i*360/sides) r*[cos(a),sin(a)]]
    ) reorient(anchor,spin, two_d=true, r=r, p=path);



// Section: Primitive 3D Shapes


// Function&Module: cube()
// Topics: Shapes (3D), Attachable, VNF Generators
// Usage: As Module
//   cube(size, [center], ...);
// Usage: With Attachments
//   cube(size, [center], ...) { attachments }
// Usage: As Function
//   vnf = cube(size, [center], ...);
// See Also: cuboid(), prismoid()
// Description:
//   Creates a 3D cubic object with support for anchoring and attachments.
//   This can be used as a drop-in replacement for the built-in `cube()` module.
//   When called as a function, returns a [VNF](vnf.scad) for a cube.
// Arguments:
//   size = The size of the cube.
//   center = If given, overrides `anchor`.  A true value sets `anchor=CENTER`, false sets `anchor=ALLNEG`.
//   ---
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
    size = scalar_vec3(size);
    attachable(anchor,spin,orient, size=size) {
        if (size.z > 0) {
            linear_extrude(height=size.z, center=true, convexity=2) {
                square([size.x,size.y], center=true);
            }
        }
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
            is_vector(size,3)? [for (p=unscaled) v_mul(p,size)] :
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
// Topics: Shapes (3D), Attachable, VNF Generators
// Usage: As Module
//   cylinder(h, r=/d=, [center=], ...);
//   cylinder(h, r1/d1=, r2/d2=, [center=], ...);
// Usage: With Attachments
//   cylinder(h, r=/d=, [center=]) {attachments}
// Usage: As Function
//   vnf = cylinder(h, r=/d=, [center=], ...);
//   vnf = cylinder(h, r1/d1=, r2/d2=, [center=], ...);
// See Also: cyl()
// Description:
//   Creates a 3D cylinder or conic object with support for anchoring and attachments.
//   This can be used as a drop-in replacement for the built-in `cylinder()` module.
//   When called as a function, returns a [VNF](vnf.scad) for a cylinder.
// Arguments:
//   l / h = The height of the cylinder.
//   r1 = The bottom radius of the cylinder.  (Before orientation.)
//   r2 = The top radius of the cylinder.  (Before orientation.)
//   center = If given, overrides `anchor`.  A true value sets `anchor=CENTER`, false sets `anchor=BOTTOM`.
//   ---
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
    attachable(anchor,spin,orient, r1=r1, r2=r2, l=l) {
        if (r1 > r2) {
            if (l > 0) {
                linear_extrude(height=l, center=true, convexity=2, scale=r2/r1) {
                    circle(r=r1);
                }
            }
        } else {
            zflip() {
                if (l > 0) {
                    linear_extrude(height=l, center=true, convexity=2, scale=r1/r2) {
                        circle(r=r2);
                    }
                }
            }
        }
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
            for (i=[0:1:sides-1]) let(a=360*(1-i/sides)) [r1*cos(a),r1*sin(a),-l/2],
            for (i=[0:1:sides-1]) let(a=360*(1-i/sides)) [r2*cos(a),r2*sin(a), l/2],
        ],
        faces = [
            [for (i=[0:1:sides-1]) sides-1-i],
            for (i=[0:1:sides-1]) [i, ((i+1)%sides)+sides, i+sides],
            for (i=[0:1:sides-1]) [i, (i+1)%sides, ((i+1)%sides)+sides],
            [for (i=[0:1:sides-1]) sides+i]
        ]
    ) [reorient(anchor,spin,orient, l=l, r1=r1, r2=r2, p=verts), faces];



// Function&Module: sphere()
// Topics: Shapes (3D), Attachable, VNF Generators
// Usage: As Module
//   sphere(r|d=, [circum=], [style=], ...);
// Usage: With Attachments
//   sphere(r|d=, ...) { attachments }
// Usage: As Function
//   vnf = sphere(r|d=, [circum=], [style=], ...);
// See Also: spheroid()
// Description:
//   Creates a sphere object, with support for anchoring and attachments.
//   This is a drop-in replacement for the built-in `sphere()` module.
//   When called as a function, returns a [VNF](vnf.scad) for a sphere.
// Arguments:
//   r = Radius of the sphere.
//   ---
//   d = Diameter of the sphere.
//   circum = If true, the sphere is made large enough to circumscribe the sphere of the ideal side.  Otherwise inscribes.  Default: false (inscribes)
//   style = The style of the sphere's construction. One of "orig", "aligned", "stagger", "octa", or "icosa".  Default: "orig"
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
// Example: By Radius
//   sphere(r=50);
// Example: By Diameter
//   sphere(d=100);
// Example: style="orig"
//   sphere(d=100, style="orig", $fn=10);
// Example: style="aligned"
//   sphere(d=100, style="aligned", $fn=10);
// Example: style="stagger"
//   sphere(d=100, style="stagger", $fn=10);
// Example: style="icosa"
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
    spheroid(r=r, d=d, circum=circum, style=style, anchor=anchor, spin=spin, orient=orient) children();


function sphere(r, d, circum=false, style="orig", anchor=CENTER, spin=0, orient=UP) =
    spheroid(r=r, d=d, circum=circum, style=style, anchor=anchor, spin=spin, orient=orient);


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
