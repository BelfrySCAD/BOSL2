# Basic Shapes Tutorial

## Primitives
There are 5 built-in primitive shapes that OpenSCAD provides.
`square()`, `circle()`, `cube()`, `cylinder()`, and `sphere()`.
The BOSL2 library extends or provides alternative to these shapes so
that they support more features, and more ways to simply reorient them.


### 2D Squares
You can still use the built-in `square()` in the familiar ways that OpenSCAD provides:

```openscad-2D
    square(100, center=false);
```

```openscad-2D
    square(100, center=true);
```

```openscad-2D
    square([60,40], center=true);
```

The BOSL2 library provides an enhanced equivalent to `square()` called `rect()`.
You can use it in the same way you use `square()`, but it also provides
extended functionality. For example, it allows you to round the corners:

```openscad-2D
    rect([60,40], center=true, rounding=10);
```

Or chamfer them:

```openscad-2D
    rect([60,40], center=true, chamfer=10);
```

You can even specify *which* corners get rounded or chamferred.  If you pass a
list of four size numbers to the `rounding=` or `chamfer=` arguments, it will
give each corner its own size.  In order, it goes from the back-right (quadrant I)
corner, counter-clockwise around to the back-left (quadrant II) corner, to the
forward-left (quadrant III) corner, to the forward-right (quadrant IV) corner:

```openscad-2DImgOnly
    module text3d(text) color("black") text(
        text=text, font="Times", size=10,
        halign="center", valign="center"
    );
    translate([ 50, 50]) text3d("I");
    translate([-50, 50]) text3d("II");
    translate([-50,-50]) text3d("III");
    translate([ 50,-50]) text3d("IV");
    rect([90,80], center=true);
```

If a size is given as `0`, then there is no rounding and/or chamfering for
that quadrant's corner:

```openscad-2D
    rect([60,40], center=true, rounding=[0,5,10,15]);
```

```openscad-2D
    rect([60,40], center=true, chamfer=[0,5,10,15]);
```

You can give both `rounding=` and `chamfer=` arguments to mix rounding and
chamfering, but only if you specify per corner.  If you want a rounding in
a corner, specify a 0 chamfer for that corner, and vice versa:

```openscad-2D
    rect([60,40], center=true, rounding=[5,0,10,0], chamfer=[0,5,0,15]);
```

#### Anchors and Spin
Another way that `rect()` is enhanced over `square()`, is that you can anchor,
spin and attach it.

The `anchor=` argument is an alternative to `center=`, which allows more
alignment options.  It takes a vector as a value, pointing roughly towards
the side or corner you want to align to the origin.  For example, to align
the center of the back edge to the origin, set the anchor to `[0,1]`:

```openscad-2D
    rect([60,40], anchor=[0,1]);
```

To align the front right corner to the origin:

```openscad-2D
    rect([60,40], anchor=[1,-1]);
```

To center:

```openscad-2D
    rect([60,40], anchor=[0,0]);
```

To make it clearer when giving vectors, there are several standard vector
constants defined:

Constant | Direction | Value
-------- | --------- | -----------
`LEFT`   | X-        | `[-1,0,0]`
`RIGHT`  | X+        | `[1,0,0]`
`FRONT`/`FORWARD`/`FWD` | Y- | `[0,-1,0]`
`BACK`   | Y+        | `[0,1,0]`
`BOTTOM`/`BOT`/`BTM`/`DOWN` | Z- | `[0,0,-1]` (3D only.)
`TOP`/`UP` | Z+      | `[0,0,1]` (3D only.)
`CENTER`/`CTR` | Centered | `[0,0,0]`

Note that even though these are 3D vectors, you can use most of them,
(except `UP`/`DOWN`, of course) for anchors in 2D shapes:

```openscad-2D
    rect([60,40], anchor=BACK);
```

```openscad-2D
    rect([60,40], anchor=CENTER);
```

You can add vectors together to point to corners:

```openscad-2D
    rect([60,40], anchor=FRONT+RIGHT);
```

Finally, the `spin` argument can rotate the shape by a given number of degrees
clockwise:

```openscad-2D
    rect([60,40], anchor=CENTER, spin=30);
```

Anchoring or centering is performed before the spin:

```openscad-2D
    rect([60,40], anchor=BACK, spin=30);
```


### 2D Circles
The built-in `circle()` primitive can be used as expected:

```openscad-2D
    circle(r=50);
```

```openscad-2D
    circle(d=100);
```

```openscad-2D
    circle(d=100, $fn=8);
```

The BOSL2 library provides an enhanced equivalent of `circle()` called `oval()`.
You can use it in the same way you use `circle()`, but it also provides
extended functionality. For example, it allows more control over its size and
orientation.

Since a circle in OpenSCAD can only be approximated by a regular polygon with
a number of straight sides, this can lead to size and shape inaccuracies.
To counter this, the `realign=` and `circum=` arguments are also provided.

The `realign=` argument, if set `true`, rotates the `oval()` by half the angle
between the sides:

```openscad-2D
    oval(d=100, $fn=8, realign=true);
```

The `circum=` argument, if true, makes it so that the polygon forming the
`oval()` circumscribes the ideal circle instead of inscribing it.

Inscribing the ideal circle:

```openscad-2D
    difference() {
        circle(d=100, $fn=360);
        oval(d=100, $fn=8);
    }
```

Circumscribing the ideal circle:

```openscad-2D
    difference() {
        oval(d=100, $fn=8, circum=true);
        circle(d=100, $fn=360);
    }
```

The `oval()` module, as its name suggests, can be given separate X and Y radii
or diameters.  To do this, just give `r=` or `d=` with a list of two radii or
diameters:

```openscad-2D
    oval(r=[30,20]);
```

```openscad-2D
    oval(d=[60,40]);
```

Another way that `oval()` is enhanced over `circle()`, is that you can anchor,
spin and attach it.

```openscad-2D
    oval(r=50, anchor=BACK);
```

```openscad-2D
    oval(r=50, anchor=FRONT+RIGHT);
```

Using spin on a circle may not make initial sense, until you remember that
anchoring is performed before spin:

```openscad-2D
    oval(r=50, anchor=FRONT, spin=-30);
```


### 3D Cubes
BOSL2 overrides the built-in `cube()` module.  It still can be used as you
expect from the built-in:

```openscad-3D
    cube(100);
```

```openscad-3D
    cube(100, center=true);
```

```openscad-3D
    cube([50,40,20], center=true);
```

It is also enhanced to allow you to anchor, spin, orient, and attach it.

You can use `anchor=` similarly to how you use it with `square()` or `rect()`,
except you can also anchor vertically in 3D, allowing anchoring to faces, edges,
and corners:

```openscad-3D
    cube([50,40,20], anchor=BOTTOM);
```

```openscad-3D
    cube([50,40,20], anchor=TOP+BACK);
```

```openscad-3D
    cube([50,40,20], anchor=TOP+FRONT+LEFT);
```

You can use `spin=` to rotate around the Z axis:

```openscad-3D
    cube([50,40,20], anchor=FRONT, spin=30);
```

3D objects also gain the ability to use an extra trick with `spin=`;
if you pass a list of `[X,Y,Z]` rotation angles to `spin=`, it will
rotate by the three given axis angles, similar to using `rotate()`:

```openscad-3D
    cube([50,40,20], anchor=FRONT, spin=[15,0,30]);
```

3D objects also can be given an `orient=` argument as a vector, pointing
to where the top of the shape should be rotated towards.

```openscad-3D
    cube([50,40,20], orient=UP+BACK+RIGHT);
```

If you use `anchor=`, `spin=`, and `orient=` together, the anchor is performed
first, then the spin, then the orient:

```openscad-3D
    cube([50,40,20], anchor=FRONT);
```

```openscad-3D
    cube([50,40,20], anchor=FRONT, spin=45);
```

```openscad-3D
    cube([50,40,20], anchor=FRONT, spin=45, orient=UP+FWD+RIGHT);
```

BOSL2 provides a `cuboid()` module that expands on `cube()`, by providing
rounding and chamfering of edges.  You can use it similarly to `cube()`,
except that `cuboid()` centers by default.

You can round the edges with the `rounding=` argument:

```openscad-3D
    cuboid([100,80,60], rounding=20);
```

Similarly, you can chamfer the edges with the `chamfer=` argument:

```openscad-3D
    cuboid([100,80,60], chamfer=10);
```

You can round only some edges, by using the `edges=` arguments.  It can be
given a few types of arguments. If you gave it a vector pointed at a face,
it will only round the edges surrounding that face:

```openscad-3D
    cuboid([100,80,60], rounding=20, edges=TOP);
```

```openscad-3D
    cuboid([100,80,60], rounding=20, edges=RIGHT);
```

If you give `edges=` a vector pointing at a corner, it will round all edges
that meet at that corner:

```openscad-3D
    cuboid([100,80,60], rounding=20, edges=RIGHT+FRONT+TOP);
```

```openscad-3D
    cuboid([100,80,60], rounding=20, edges=LEFT+FRONT+TOP);
```

If you give `edges=` a vector pointing at an edge, it will round only that edge:

```openscad-3D
    cuboid([100,80,60], rounding=10, edges=FRONT+TOP);
```

```openscad-3D
    cuboid([100,80,60], rounding=10, edges=RIGHT+FRONT);
```

If you give the string "X", "Y", or "Z", then all edges aligned with the specified
axis will be rounded:

```openscad-3D
    cuboid([100,80,60], rounding=10, edges="X");
```

```openscad-3D
    cuboid([100,80,60], rounding=10, edges="Y");
```

```openscad-3D
    cuboid([100,80,60], rounding=10, edges="Z");
```

If you give a list of edge specs, then all edges referenced in the list will
be rounded:

```openscad-3D
    cuboid([100,80,60], rounding=10, edges=[TOP,"Z",BOTTOM+RIGHT]);
```

The default value for `edges=` is `EDGES_ALL`, which is all edges.  You can also
give an `except_edges=` argument that specifies edges to NOT round:

```openscad-3D
    cuboid([100,80,60], rounding=10, except_edges=BOTTOM+RIGHT);
```

You can give the `except_edges=` argument any type of argument that you can
give to `edges=`:

```openscad-3D
    cuboid([100,80,60], rounding=10, except_edges=[BOTTOM,"Z",TOP+RIGHT]);
```

You can give both `edges=` and `except_edges=`, to simplify edge specs:

```openscad-3D
    cuboid([100,80,60], rounding=10, edges=[TOP,FRONT], except_edges=TOP+FRONT);
```

You can specify what edges to chamfer similarly:

```openscad-3D
    cuboid([100,80,60], chamfer=10, edges=[TOP,FRONT], except_edges=TOP+FRONT);
```


### 3D Cylinder
BOSL2 overrides the built-in `cylinder()` module.  It still can be used as you
expect from the built-in:

```openscad-3D
    cylinder(r=50,h=50);
```

```openscad-3D
    cylinder(r=50,h=50,center=true);
```

```openscad-3D
    cylinder(d=100,h=50,center=true);
```

```openscad-3D
    cylinder(d1=100,d2=80,h=50,center=true);
```

You can also anchor, spin, orient, and attach like the `cuboid()` module:

```openscad-3D
    cylinder(r=50, h=50, anchor=TOP+FRONT);
```

```openscad-3D
    cylinder(r=50, h=50, anchor=BOTTOM+LEFT);
```

```openscad-3D
    cylinder(r=50, h=50, anchor=BOTTOM+LEFT, spin=30);
```

```openscad-3D
    cylinder(r=50, h=50, anchor=BOTTOM, orient=UP+BACK+RIGHT);
```


BOSL2 provides a `cyl()` module that expands on `cylinder()`, by providing
rounding and chamfering of edges.  You can use it similarly to `cylinder()`,
except that `cyl()` centers the cylinder by default.

```openscad-3D
    cyl(r=60, l=100);
```

```openscad-3D
    cyl(d=100, l=100);
```

```openscad-3D
    cyl(d=100, l=100, anchor=TOP);
```

You can round the edges with the `rounding=` argument:

```openscad-3D
    cyl(d=100, l=100, rounding=20);
```

Similarly, you can chamfer the edges with the `chamfer=` argument:

```openscad-3D
    cyl(d=100, l=100, chamfer=10);
```

You can specify rounding and chamfering for each end individually:

```openscad-3D
    cyl(d=100, l=100, rounding1=20);
```

```openscad-3D
    cyl(d=100, l=100, rounding2=20);
```

```openscad-3D
    cyl(d=100, l=100, chamfer1=10);
```

```openscad-3D
    cyl(d=100, l=100, chamfer2=10);
```

You can even mix and match rounding and chamfering:

```openscad-3D
    cyl(d=100, l=100, rounding1=20, chamfer2=10);
```

```openscad-3D
    cyl(d=100, l=100, rounding2=20, chamfer1=10);
```


### 3D Spheres
BOSL2 overrides the built-in `sphere()` module.  It still can be used as you
expect from the built-in:

```openscad-3D
    cylinder(r=50);
```

```openscad-3D
    cylinder(d=100);
```

You can anchor, spin, and orient `sphere()`s, much like you can with `cylinder()`
and `cube()`:

```openscad-3D
    sphere(d=100, anchor=FRONT);
```

```openscad-3D
    sphere(d=100, anchor=FRONT, spin=30);
```

```openscad-3D
    sphere(d=100, anchor=BOTTOM, orient=RIGHT+TOP);
```

BOSL2 also provides `spheroid()`, which enhances `sphere()` with a few features
like the `circum=` and `style=` arguments:

You can use the `circum=true` argument to force the sphere to circumscribe the
ideal sphere, as opposed to the default inscribing:

```openscad-3D
    spheroid(d=100, circum=true);
```

The `style=` argument can choose the way that the sphere will be constructed:
The "orig" style matches the `sphere()` built-in's construction. 

```openscad-3D
    spheroid(d=100, style="orig");
```

The "aligned" style will ensure that there is a vertex at each axis extrama,
so long as `$fn` is a multiple of 4.

```openscad-3D
    spheroid(d=100, style="aligned");
```

The "stagger" style will stagger the triangulation of the vertical rows:

```openscad-3D
    spheroid(d=100, style="stagger");
```

The "icosa"` style will make for roughly equal-sized triangles for the entire
sphere surface:

```openscad-3D
    spheroid(d=100, style="icosa");
```


