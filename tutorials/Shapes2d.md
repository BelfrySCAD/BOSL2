# 2D Shapes Tutorial

<!-- TOC -->

## Primitives
There are two built-in 2D primitive shapes that OpenSCAD provides: `square()`, and `circle()`.
The BOSL2 library provides alternative to these shapes so that they support more features,
and more ways to simply reorient them.


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

You can even specify *which* corners get rounded or chamfered.  If you pass a
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
`LEFT`   | X-        | `[-1, 0, 0]`
`RIGHT`  | X+        | `[ 1, 0, 0]`
`FRONT`/`FORWARD`/`FWD` | Y- | `[ 0,-1, 0]`
`BACK`   | Y+        | `[ 0, 1, 0]`
`BOTTOM`/`BOT`/`BTM`/`DOWN` | Z- | `[ 0, 0,-1]` (3D only.)
`TOP`/`UP` | Z+      | `[ 0, 0, 1]` (3D only.)
`CENTER`/`CTR` | Centered | `[ 0, 0, 0]`

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

Anchor points double as attachment points, so that you can attach other shapes:

```openscad-2D
rect([60,40],center=true)
    show_anchors();
```

### 2D Circles and Ovals
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

The BOSL2 library also provides an enhanced equivalent of `circle()` called `oval()`.
You can use it in the same way you use `circle()`, but it also provides extended
functionality. For example, it allows more control over its size and orientation.

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


### Trapezoids

OpenSCAD doesn't provide a simple way to make 2D triangles, trapezoids, or parallelograms.
The BOSL2 library can provide all of these shapes with the `trapezoid()` module.

To make a simple triangle, just make one of the widths zero:

```openscad-2D
trapezoid(w1=50, w2=0, h=50);
```

To make a right triangle, you need to use the `shift=` argument, to shift the back of the trapezoid along the X axis:

```openscad-2D
trapezoid(w1=50, w2=0, h=50, shift=-25);
```

```openscad-2D
trapezoid(w1=50, w2=0, h=50, shift=25);
```

```openscad-2D
trapezoid(w1=0, w2=50, h=50, shift=-25);
```

```openscad-2D
trapezoid(w1=0, w2=50, h=50, shift=25);
```

You can make a trapezoid by specifying non-zero widths for both the front (`w1=`) and back (`w2=`):

```openscad-2D
trapezoid(w1=30, w2=50, h=50);
```

A parallelogram is just a matter of using the same width for front and back, with a shift along the X axis:

```openscad-2D
trapezoid(w1=50, w2=50, shift=20, h=50);
```

A quadrilateral can be made by having unequal, non-zero front (`w1=`) and back (`w2=`) widths, with the back shifted along the X axis:

```openscad-2D
trapezoid(w1=50, w2=30, shift=20, h=50);
```

You can use `anchor=` and `spin=`, just like with other attachable shapes.  However, the anchor
points are based on the side angles of the faces, and may not be where you expect them:

```openscad-2D
trapezoid(w1=30, w2=50, h=50)
    show_anchors();
```

### Regular N-Gons

OpenSCAD lets you make regular N-gons (pentagon, hexagon, etc) by using `circle()` with `$fn`.
While this is concise, it may be less than obvious at first glance:

```openscad-2D
circle(d=50, $fn=5);
```

The BOSL2 library has modules that are named more clearly:

```openscad-2D
pentagon(d=50);
```

```openscad-2D
hexagon(d=50);
```

```openscad-2D
octagon(d=50);
```

```openscad-2D
regular_ngon(n=7, d=50);
```

These modules also provide you with extra functionality.

They can be sized by side length:

```openscad-2D
pentagon(side=20);
```

They can be sized by circumscribed circle radius/diameter:

```openscad-2D
pentagon(ir=25);
pentagon(id=50);
```

They can be realigned by half a side's angle:

```openscad-2D
left(30)  pentagon(d=50, realign=true);
right(30) pentagon(d=50, realign=false);
```

They can be rounded:

```openscad-2D
pentagon(d=50, rounding=10);
```

```openscad-2D
hexagon(d=50, rounding=10);
```

They also have somewhat different attachment behavior:

```openscad-2D
color("green") stroke(circle(d=50), closed=true);
oval(d=50,$fn=5)
    attach(LEFT) color("blue") anchor_arrow2d();
```

```openscad-2D
pentagon(d=50)
    attach(LEFT) color("blue") anchor_arrow2d();
```

You can use `anchor=` and `spin=`, just like with other attachable shapes.  However, the anchor
points are based on where the anchor vector would intersect the side of the N-gon, and may not
be where you expect them:

```openscad-2D
pentagon(d=50)
    show_anchors(custom=false);
```

N-gons also have named anchor points for their sides and tips:

```openscad-2D
pentagon(d=30)
    show_anchors(std=false);
```


### Stars

The BOSL2 library has stars as a basic supported shape.  They can have any number of points.
You can specify a star's shape by point count, inner and outer vertex radius/diameters:

```openscad-2D
star(n=3, id=10, d=50);
```

```openscad-2D
star(n=5, id=15, r=25);
```

```openscad-2D
star(n=10, id=30, d=50);
```

Or you can specify the star shape by point count and number of points to step:

```openscad-2D
star(n=7, step=2, d=50);
```

```openscad-2D
star(n=7, step=3, d=50);
```

If the `realign=` argument is given a true value, then the star will be rotated by half a point angle:

```openscad-2D
left(30) star(n=5, step=2, d=50);
right(30) star(n=5, step=2, d=50, realign=true);
```

The `align_tip=` argument can be given a vector so that you can align the first point in a specific direction:

```openscad-2D
star(n=5, ir=15, or=30, align_tip=BACK+LEFT)
    attach("tip0") color("blue") anchor_arrow2d();
```

```openscad-2D
star(n=5, ir=15, or=30, align_tip=BACK+RIGHT)
    attach("tip0") color("blue") anchor_arrow2d();
```

Similarly, the first indentation or pit can be oriented towards a specific vector with `align_pit=`:


```openscad-2D
star(n=5, ir=15, or=30, align_pit=BACK+LEFT)
    attach("pit0") color("blue") anchor_arrow2d();
```

```openscad-2D
star(n=5, ir=15, or=30, align_pit=BACK+RIGHT)
    attach("pit0") color("blue") anchor_arrow2d();
```

You can use `anchor=` and `spin=`, just like with other attachable shapes.  However, the anchor
points are based on the furthest extents of the shape, and may not be where you expect them:

```openscad-2D
star(n=5, step=2, d=50)
    show_anchors(custom=false);
```

Stars also have named anchor points for their pits, tips, and midpoints between tips:

```openscad-2D
star(n=5, step=2, d=40)
    show_anchors(std=false);
```



### Teardrop2D

Often when 3D printing, you may want to make a circular hole in a vertical wall.  If the hole is
too big, however, the overhang at the top of the hole can cause problems with printing on an
FDM/FFF printer.  If you don't want to use support material, you can just use the teardrop shape.
The `teardrop2d()` module will let you make a 2D version of the teardrop shape, so that you can
extrude it later:

```openscad-2D
teardrop2d(r=20);
```

```openscad-2D
teardrop2d(d=50);
```

The default overhang angle is 45 degrees, but you can adjust that with the `ang=` argument:

```openscad-2D
teardrop2d(d=50, ang=30);
```

If you prefer to flatten the top of the teardrop, to encourage bridging, you can use the `cap_h=`
argument:

```openscad-2D
teardrop2d(d=50, cap_h=25);
```

```openscad-2D
teardrop2d(d=50, ang=30, cap_h=30);
```

You can use `anchor=` and `spin=`, just like with other attachable shapes.  However, the anchor
points are based on the furthest extents of the shape, and may not be where you expect them:

```openscad-2D
teardrop2d(d=50, ang=30, cap_h=30)
    show_anchors();
```


### Glued Circles

A more unusal shape that BOSL2 provides is Glued Circles.  It's basically a pair of circles,
connected by what looks like a gloopy glued miniscus:

```openscad-2D
glued_circles(d=30, spread=40);
```

The `r=`/`d=` arguments can specify the radius or diameter of the two circles:

```openscad-2D
glued_circles(r=20, spread=45);
```

```openscad-2D
glued_circles(d=40, spread=45);
```

The `spread=` argument specifies the distance between the centers of the two circles:

```openscad-2D
glued_circles(d=30, spread=30);
```

```openscad-2D
glued_circles(d=30, spread=40);
```

The `tangent=` argument gives the angle of the tangent of the meniscus on the two circles:

```openscad-2D
glued_circles(d=30, spread=30, tangent=45);
```

```openscad-2D
glued_circles(d=30, spread=30, tangent=20);
```

```openscad-2D
glued_circles(d=30, spread=30, tangent=-20);
```

One useful thing you can do is to string a few `glued_circle()`s in a line then extrude them to make a ribbed wall:

```openscad-3D
$fn=36;  s=10;
linear_extrude(height=50,convexity=16,center=true)
    xcopies(s*sqrt(2),n=3)
        glued_circles(d=s, spread=s*sqrt(2), tangent=45);
```

You can use `anchor=` and `spin=`, just like with other attachable shapes.  However, the anchor
points are based on the furthest extents of the shape, and may not be where you expect them:

```openscad-2D
glued_circles(d=40, spread=40, tangent=45)
    show_anchors();
```

