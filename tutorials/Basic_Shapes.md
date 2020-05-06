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
    oval(r=50, anchor=FRONT, spin=30);
```

### Enhanced 3D Cube
You can use enhanced `cube()` like the normal OpenSCAD built-in:

```openscad-3D
    cube(100);
```

```openscad-3D
    cube(100, center=true);
```

```openscad-3D
    cube([50,40,20], center=true);
```

You can use `anchor` similarly to `square()`, except you can anchor vertically
too, in 3D, allowing anchoring to faces, edges, and corners:

```openscad-3D
    cube([50,40,20], anchor=BOTTOM);
```

```openscad-3D
    cube([50,40,20], anchor=TOP+BACK);
```

```openscad-3D
    cube([50,40,20], anchor=TOP+FRONT+LEFT);
```

You can use `spin` as well, to rotate around the Z axis:

```openscad-3D
    cube([50,40,20], anchor=FRONT, spin=30);
```

3D objects also gain the ability to use an extra trick with `spin`;
if you pass a list of `[X,Y,Z]` rotation angles to `spin`, it will
rotate by the three given axis angles, similar to using `rotate()`:

```openscad-3D
    cube([50,40,20], anchor=FRONT, spin=[15,0,30]);
```

3D objects also can be given an `orient` argument that is given as a vector,
pointing towards where the top of the shape should be rotated towards.

```openscad-3D
    cube([50,40,20], orient=UP+BACK+RIGHT);
```

If you use `anchor`, `spin`, and `orient` together, the anchor is performed
first, then the spin, then the orient:

```openscad-3D
    cube([50,40,20], anchor=FRONT, spin=45, orient=UP+FWD+RIGHT);
```

### Enhanced 3D Cylinder
You can use the enhanced `cylinder()` as normal for OpenSCAD:

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

