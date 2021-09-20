# Attachments Tutorial

<!-- TOC -->

## Attachables
BOSL2 introduces the concept of attachables.  Attachables are shapes that can be anchored,
spun, oriented, and attached to other attachables.  The most basic attachable shapes are the
`cube()`, `cylinder()`, and `sphere()`.  BOSL2 overrides the built-in definitions for these
shapes, and makes them attachables.


## Anchoring
Anchoring allows you to align a side, edge, or corner of an object with the origin as it is
created.  This is done by passing a vector into the `anchor=` argument.  For roughly cubical
or prismoidal shapes, that vector points in the general direction of the side, edge, or
corner that will be aligned to.  Each vector component should be -1, 0, or 1:

```openscad
cube([40,30,50], anchor=[-1,-1,1]);
```

```openscad
cube([40,30,50], anchor=[1,0,1]);
```

```openscad
cube([40,30,50], anchor=[0,0,-1]);
```

Since manually written vectors are not very intuitive, BOSL2 defines some standard directional
vector constants that can be added together:

Constant | Direction | Value
-------- | --------- | -----------
`LEFT`   | X-        | `[-1, 0, 0]`
`RIGHT`  | X+        | `[ 1, 0, 0]`
`FRONT`/`FORWARD`/`FWD` | Y- | `[ 0,-1, 0]`
`BACK`   | Y+        | `[ 0, 1, 0]`
`BOTTOM`/`BOT`/`BTM`/`DOWN` | Z- | `[ 0, 0,-1]` (3D only.)
`TOP`/`UP` | Z+      | `[ 0, 0, 1]` (3D only.)
`CENTER`/`CTR` | Centered | `[ 0, 0, 0]`

```openscad
cube([40,30,50], anchor=BACK+TOP);
```

```openscad
cube([40,30,50], anchor=FRONT);
```

Cylindrical attachables can be anchored similarly, except that only the Z vector component is
required to be -1, 0, or 1.  This allows anchoring to arbitrary edges around the cylinder or
cone:

```openscad
cylinder(r1=25, r2=15, h=60, anchor=TOP+LEFT);
```

```openscad
cylinder(r1=25, r2=15, h=60, anchor=BOTTOM+FRONT);
```

```openscad
cylinder(r1=25, r2=15, h=60, anchor=UP+spherical_to_xyz(1,30,90));
```

Spherical shapes can use fully proportional anchoring vectors, letting you anchor to any point
on the surface of the sphere, just by pointing a vector at it:

```openscad
sphere(r=50, anchor=TOP);
```

```openscad
sphere(r=50, anchor=TOP+FRONT);
```

```openscad
sphere(r=50, anchor=spherical_to_xyz(1,-30,60));
```

Some attachable shapes may provide specific named anchors for shape-specific anchoring.  These
will be given as strings and will be specific to that type of attachable:

```openscad
teardrop(d=100, l=20, anchor="cap");
```

Some shapes, for backwards compatability reasons, can take a `center=` argument.  This just
overrides the `anchor=` argument.  A `center=true` argument is the same as `anchor=CENTER`.
A `center=false` argument can mean `anchor=[-1,-1,-1]` for a cube, or `anchor=BOTTOM` for a
cylinder.

Many 2D shapes provided by BOSL2 are also anchorable.  Due to technical limitations of OpenSCAD,
however, `square()` and `circle()` are *not*.  BOSL2 provides `rect()` and `oval()` as attachable
and anchorable equivalents.  You can only anchor on the XY plane, of course, but you can use the
same `FRONT`, `BACK`, `LEFT`, `RIGHT`, and `CENTER` anchor constants.

```openscad-2D
rect([40,30], anchor=BACK+LEFT);
```

```openscad-2D
oval(d=50, anchor=FRONT);
```

```openscad-2D
hexagon(d=50, anchor=BACK);
```


## Spin
Attachable shapes also can be spun in place as you create them.  You can do this by passing in
the angle to spin by into the `spin=` argument:

```openscad
cube([20,20,40], center=true, spin=45);
```

You can even spin around each of the three axes in one pass, by giving 3 angles to `spin=` as a
vector, like [Xang,Yang,Zang]:

```openscad
cube([20,20,40], center=true, spin=[10,20,30]);
```

You can also apply spin to 2D shapes from BOSL2.  Again, you should use `rect()` and `oval()`
instead of `square()` and `circle()`:

```openscad-2D
rect([40,30], spin=30);
```

```openscad-2D
oval(d=[40,30], spin=30);
```


## Orientation
Another way to specify a rotation for an attachable shape, is to pass a 3D vector via the
`orient=` argument.  This lets you specify what direction to tilt the top of the shape towards.
For example, you can make a cone that is tilted up and to the right like this:

```openscad
cylinder(h=100, r1=50, r2=20, orient=UP+RIGHT);
```

You can *not* use `orient=` with 2D shapes.


## Mixing Anchoring, Spin, and Orientation
When giving `anchor=`, `spin=`, and `orient=`, they are applied anchoring first, spin second,
then orient last.  For example, here's a cube:

```openscad
cube([20,20,50]);
```

You can center it with an `anchor=CENTER` argument:

```openscad
cube([20,20,50], anchor=CENTER);
```

Add a 45 degree spin:

```openscad
cube([20,20,50], anchor=CENTER, spin=45);
```

Now tilt the top up and forward:

```openscad
cube([20,20,50], anchor=CENTER, spin=45, orient=UP+FWD);
```

Something that may confuse new users is that adding spin to a cylinder may seem nonsensical.
However, since spin is applied *after* anchoring, it can actually have a significant effect:

```openscad
cylinder(d=50, l=40, anchor=FWD, spin=-30);
```

For 2D shapes, you can mix `anchor=` with `spin=`, but not with `orient=`.

```openscad-2D
rect([40,30], anchor=BACK+LEFT, spin=30);
```


## Attaching 3D Children
The reason attachables are called that, is because they can be attached to each other.
You can do that by making one attachable shape be a child of another attachable shape.
By default, the child of an attachable is attached to the center of the parent shape.

```openscad
cube(50,center=true)
    cylinder(d1=50,d2=20,l=50);
```

To attach to a different place on the parent, you can use the `attach()` module.  By default,
this will attach the bottom of the child to the given position on the parent.  The orientation
of the child will be overridden to point outwards from the center of the parent, more or less:

```openscad
cube(50,center=true)
    attach(TOP) cylinder(d1=50,d2=20,l=20);
```

If you give `attach()` a second anchor argument, it attaches that anchor on the child to the
first anchor on the parent:

```openscad
cube(50,center=true)
    attach(TOP,TOP) cylinder(d1=50,d2=20,l=20);
```

By default, `attach()` places the child exactly flush with the surface of the parent.  Sometimes
it's useful to have the child overlap the parent by insetting a bit.  You can do this with the
`overlap=` argument to `attach()`.  A positive value will inset the child into the parent, and
a negative value will outset out from the parent:

```openscad
cube(50,center=true)
    attach(TOP,overlap=10)
        cylinder(d=20,l=20);
```

```openscad
cube(50,center=true)
    attach(TOP,overlap=-20)
        cylinder(d=20,l=20);
```

If you want to position the child at the parent's anchorpoint, without re-orienting, you can
use the `position()` module:

```openscad
cube(50,center=true)
    position(RIGHT) cylinder(d1=50,d2=20,l=20);
```

You can attach or position more than one child at a time by enclosing them all in braces:

```openscad
cube(50, center=true) {
    attach(TOP) cylinder(d1=50,d2=20,l=20);
    position(RIGHT) cylinder(d1=50,d2=20,l=20);
}
```

If you want to attach the same shape to multiple places on the same parent, you can pass the
desired anchors as a list to the `attach()` or `position()` modules:

```openscad
cube(50, center=true)
    attach([RIGHT,FRONT],TOP) cylinder(d1=50,d2=20,l=20);
```

```openscad
cube(50, center=true)
    position([TOP,RIGHT,FRONT]) cylinder(d1=50,d2=20,l=20);
```

## Attaching 2D Children
You can use attachments in 2D as well, but only in the XY plane.  Also, the built-in `square()`
and `circle()` 2D modules do not support attachments.  Instead, you should use the `rect()` and
`oval()` modules:

```openscad-2D
rect(50,center=true)
    attach(RIGHT,FRONT)
        trapezoid(w1=30,w2=0,h=30);
```

```openscad-2D
oval(d=50)
    attach(BACK,FRONT,overlap=5)
        trapezoid(w1=30,w2=0,h=30);
```

## Anchor Arrows
One way that is useful to show the position and orientation of an anchorpoint is by attaching
an anchor arrow to that anchor.

```openscad
cube(40, center=true)
    attach(LEFT+TOP)
        anchor_arrow();
```

For large objects, you can change the size of the arrow with the `s=` argument.

```openscad
sphere(d=100)
    attach(LEFT+TOP)
        anchor_arrow(s=30);
```

To show all the standard cardinal anchorpoints, you can use the `show_anchors()` module.

```openscad
cube(40, center=true)
    show_anchors();
```

```openscad
cylinder(h=40, d=40, center=true)
    show_anchors();
```

```openscad
sphere(d=40)
    show_anchors();
```

For large objects, you can again change the size of the arrows with the `s=` argument.

```openscad
cylinder(h=100, d=100, center=true)
    show_anchors(s=30);
```


## Tagged Operations
BOSL2 introduces the concept of tags.  Tags are names that can be given to attachables, so that
you can refer to them when performing `diff()`, `intersect()`, and `hulling()` operations.

### `diff(neg, <pos>, <keep>)`
The `diff()` operator is used to difference away all shapes marked with the tag(s) given to
`neg=`, from shapes marked with the tag(s)  given to `pos=`.  Anything marked with a tag given
to `keep=` will be unioned onto the result.  If no `pos=` argument is given, then everything
marked with a tag given to `neg=` will be differenced from all shapes *not* marked with that
tag.

For example, to difference away a child cylinder from the middle of a parent cube, you can
do this:

```openscad
diff("hole")
cube(100, center=true)
    cylinder(h=101, d=50, center=true, $tags="hole");
```

If you give both the `neg=` and `pos=` arguments to `diff()`, then the shapes marked by tags
given to `neg=` will be differenced away from the shapes marked with tags given to `pos=`.
Everything else will be unioned to the result.

```openscad
diff("hole", "post")
cube(100, center=true)
    attach([RIGHT,TOP]) {
        cylinder(d=95, h=5, $tags="post");
        cylinder(d=50, h=11, anchor=CTR, $tags="hole");
    }
```

The `keep=` argument takes tags for shapes that you want to keep in the output.

```openscad
diff("dish", keep="antenna")
cube(100, center=true)
    attach([FRONT,TOP], overlap=33) {
        cylinder(h=33.1, d1=0, d2=95, $tags="dish");
        cylinder(h=33.1, d=10, $tags="antenna");
    }
```

If you need to mark multiple children with a tag, you can use the `tags()` module.

```openscad
diff("hole")
cube(100, center=true)
    attach([FRONT,TOP], overlap=20)
        tags("hole") {
            cylinder(h=20.1, d1=0, d2=95);
            down(10) cylinder(h=30, d=30);
        }
```

The parent object can be differenced away from other shapes.  Tags are inherited by children,
though, so you will need to set the tags of the children as well as the parent.

```openscad
diff("hole")
cube([20,11,45], center=true, $tags="hole")
    cube([40,10,90], center=true, $tags="body");
```

Tags (and therefore tag-based operations like `diff()`) only work correctly with attachable children.
However, a number of built-in modules for making shapes are *not* attachable.  Some notable
non-attachable modules are `circle()`, `square()`, `text()`, `linear_extrude()`, `rotate_extrude()`,
`polygon()`, `polyhedron()`, `import()`, `surface()`, `union()`, `difference()`, `intersection()`,
`offset()`, `hull()`, and `minkowski()`.

To allow you to use tags-based operations with non-attachable shapes, you can wrap them with the
`tags()` module to specify their tags.  For example:

```openscad
diff("hole")
cuboid(50)
  attach(TOP)
    tags("hole")
      rotate_extrude()
        right(15)
          square(10,center=true);
```

### `intersect(a, <b>, <keep>)`

To perform an intersection of attachables, you can use the `intersect()` module.  If given one
argument to `a=`, the parent and all children *not* tagged with that will be intersected by
everything that *is* tagged with it.

```openscad
intersect("bounds")
cube(100, center=true)
    cylinder(h=100, d1=120, d2=95, center=true, $fn=72, $tags="bounds");
```

If given both the `a=` and `b=` arguments, then shapes marked with tags given to `a=` will be
intersected with shapes marked with tags given to `b=`, then unioned with all other shapes.

```openscad
intersect("pole", "cap")
cube(100, center=true)
    attach([TOP,RIGHT]) {
        cube([40,40,80],center=true, $tags="pole");
        sphere(d=40*sqrt(2), $tags="cap");
    }
```

If the `keep=` argument is given, anything marked with tags passed to it will be unioned with
the result of the union:

```openscad
intersect("bounds", keep="pole")
cube(100, center=true) {
    cylinder(h=100, d1=120, d2=95, center=true, $fn=72, $tags="bounds");
    zrot(45) xcyl(h=140, d=20, $fn=36, $tags="pole");
}
```

### `hulling(a)`
You can use the `hulling()` module to hull shapes marked with a given tag together, before
unioning the result with every other shape.

```openscad
hulling("hull")
cube(50, center=true, $tags="hull") {
    cyl(h=100, d=20);
    xcyl(h=100, d=20, $tags="pole");
}
```


## 3D Masking Attachments
To make it easier to mask away shapes from various edges of an attachable parent shape, there
are a few specialized alternatives to the `attach()` and `position()` modules.

### `edge_mask()`
If you have a 3D mask shape that you want to difference away from various edges, you can use
the `edge_mask()` module.  This module will take a vertically oriented shape, and will rotate
and move it such that the BACK, RIGHT (X+,Y+) side of the shape will be aligned with the given
edges.  The shape will be tagged as a "mask" so that you can use `diff("mask")`.  For example,
here's a shape for rounding an edge:

```openscad
module round_edge(l,r) difference() {
    translate([-1,-1,-l/2])
        cube([r+1,r+1,l]);
    translate([r,r])
        cylinder(h=l+1,r=r,center=true, $fn=quantup(segs(r),4));
}
round_edge(l=30, r=19);
```

You can use that mask to round various edges of a cube:

```openscad
module round_edge(l,r) difference() {
    translate([-1,-1,-l/2])
        cube([r+1,r+1,l]);
    translate([r,r])
        cylinder(h=l+1,r=r,center=true, $fn=quantup(segs(r),4));
}
diff("mask")
cube([50,60,70],center=true)
    edge_mask([TOP,"Z"],except=[BACK,TOP+LEFT])
        round_edge(l=71,r=10);
```

### `corner_mask()`
If you have a 3D mask shape that you want to difference away from various corners, you can use
the `corner_mask()` module.  This module will take a shape and rotate and move it such that the
BACK RIGHT TOP (X+,Y+,Z+) side of the shape will be aligned with the given corner.  The shape
will be tagged as a "mask" so that you can use `diff("mask")`.  For example, here's a shape for
rounding a corner:

```openscad
module round_corner(r) difference() {
    translate(-[1,1,1])
        cube(r+1);
    translate([r,r,r])
        sphere(r=r, style="aligned", $fn=quantup(segs(r),4));
}
round_corner(r=10);
```

You can use that mask to round various corners of a cube:

```openscad
module round_corner(r) difference() {
    translate(-[1,1,1])
        cube(r+1);
    translate([r,r,r])
        sphere(r=r, style="aligned", $fn=quantup(segs(r),4));
}
diff("mask")
cube([50,60,70],center=true)
    corner_mask([TOP,FRONT],LEFT+FRONT+TOP)
        round_corner(r=10);
```

### Mix and Match Masks
You can use `edge_mask()` and `corner_mask()` together as well:

```openscad
module round_corner(r) difference() {
    translate(-[1,1,1])
        cube(r+1);
    translate([r,r,r])
        sphere(r=r, style="aligned", $fn=quantup(segs(r),4));
}
module round_edge(l,r) difference() {
    translate([-1,-1,-l/2])
        cube([r+1,r+1,l]);
    translate([r,r])
        cylinder(h=l+1,r=r,center=true, $fn=quantup(segs(r),4));
}
diff("mask")
cube([50,60,70],center=true) {
    edge_mask("ALL") round_edge(l=71,r=10);
    corner_mask("ALL") round_corner(r=10);
}
```

## 2D Profile Mask Attachments
While 3D mask shapes give you a great deal of control, you need to make sure they are correctly
sized, and you need to provide separate mask shapes for corners and edges.  Often, a single 2D
profile could be used to describe the edge mask shape (via `linear_extrude()`), and the corner
mask shape (via `rotate_extrude()`).  This is where `edge_profile()`, `corner_profile()`, and
`face_profile()` come in.

### `edge_profile()`
Using the `edge_profile()` module, you can provide a 2D profile shape and it will be linearly
extruded to a mask of the apropriate length for each given edge.  The resultant mask will be
tagged with "mask" so that you can difference it away with `diff("mask")`.  The 2D profile is
assumed to be oriented with the BACK, RIGHT (X+,Y+) quadrant as the "cutter edge" that gets
re-oriented towards the edges of the parent shape.  A typical mask profile for chamfering an
edge may look like:

```openscad-2D
mask2d_roundover(10);
```

Using that mask profile, you can mask the edges of a cube like:

```openscad
diff("mask")
cube([50,60,70],center=true)
   edge_profile("ALL")
       mask2d_roundover(10);
```

### `corner_profile()`
You can use the same profile to make a rounded corner mask as well:

```openscad
diff("mask")
cube([50,60,70],center=true)
   corner_profile("ALL", r=10)
       mask2d_roundover(10);
```

### `face_profile()`
As a simple shortcut to apply a profile mask to all edges and corners of a face, you can use the
`face_profile()` module:

```openscad
diff("mask")
cube([50,60,70],center=true)
   face_profile(TOP, r=10)
       mask2d_roundover(10);
```


## Coloring Attachables
Usually, when coloring a shape with the `color()` module, the parent color overrides the colors of
all children.  This is often not what you want:

```openscad
$fn = 24;
color("red") spheroid(d=3) {
    attach(CENTER,BOT) color("white") cyl(h=10, d=1) {
        attach(TOP,BOT) color("green") cyl(h=5, d1=3, d2=0);
    }
}
```

If you use the `recolor()` module, however, the child's color overrides the color of the parent.
This is probably easier to understand by example:

```openscad
$fn = 24;
recolor("red") spheroid(d=3) {
    attach(CENTER,BOT) recolor("white") cyl(h=10, d=1) {
        attach(TOP,BOT) recolor("green") cyl(h=5, d1=3, d2=0);
    }
}
```


## Making Attachables
To make a shape attachable, you just need to wrap it with an `attachable()` module with a
basic description of the shape's geometry.  By default, the shape is expected to be centered
at the origin.  The `attachable()` module expects exactly two children.  The first will be
the shape to make attachable, and the second will be `children()`, literally.

### Prismoidal/Cuboidal Attachables
To make a cuboidal or prismoidal shape attachable, you use the `size`, `size2`, and `offset`
arguments of `attachable()`.

In the most basic form, where the shape is fully cuboid, with top and bottom of the same size,
and directly over one another, you can just use `size=`.

```openscad
module cubic_barbell(s=100, anchor=CENTER, spin=0, orient=UP) {
    attachable(anchor,spin,orient, size=[s*3,s,s]) {
        union() {
            xcopies(2*s) cube(s, center=true);
            xcyl(h=2*s, d=s/4);
        }
        children();
    }
}
cubic_barbell(100) show_anchors(30);
```

When the shape is prismoidal, where the top is a different size from the bottom, you can use
the `size2=` argument as well. While `size=` takes all three axes sizes, the `size2=` argument
only takes the [X,Y] sizes of the top of the shape.

```openscad
module prismoidal(size=[100,100,100], scale=0.5, anchor=CENTER, spin=0, orient=UP) {
    attachable(anchor,spin,orient, size=size, size2=[size.x, size.y]*scale) {
        hull() {
            up(size.z/2-0.005)
                linear_extrude(height=0.01, center=true)
                    square([size.x,size.y]*scale, center=true);
            down(size.z/2-0.005)
                linear_extrude(height=0.01, center=true)
                    square([size.x,size.y], center=true);
        }
        children();
    }
}
prismoidal([100,60,30], scale=0.5) show_anchors(20);
```

When the top of the prismoid can be shifted away from directly above the bottom, you can use
the `shift=` argument.  The `shift=` argument takes an [X,Y] vector of the offset of the center
of the top from the XY center of the bottom of the shape.

```openscad
module prismoidal(size=[100,100,100], scale=0.5, shift=[0,0], anchor=CENTER, spin=0, orient=UP) {
    attachable(anchor,spin,orient, size=size, size2=[size.x, size.y]*scale, shift=shift) {
        hull() {
            translate([shift.x, shift.y, size.z/2-0.005])
                linear_extrude(height=0.01, center=true)
                    square([size.x,size.y]*scale, center=true);
            down(size.z/2-0.005)
                linear_extrude(height=0.01, center=true)
                    square([size.x,size.y], center=true);
        }
        children();
    }
}
prismoidal([100,60,30], scale=0.5, shift=[-30,20]) show_anchors(20);
```

In the case that the prismoid is not oriented vertically, (ie, where the `shift=` or `size2=`
arguments should refer to a plane other than XY) you can use the `axis=` argument.  This lets
you make prismoids naturally oriented forwards/backwards or sideways.

```openscad
module yprismoidal(
    size=[100,100,100], scale=0.5, shift=[0,0],
    anchor=CENTER, spin=0, orient=UP
) {
    attachable(
        anchor, spin, orient,
        size=size, size2=point2d(size)*scale,
        shift=shift, axis=BACK
    ) {
        xrot(-90) hull() {
            translate([shift.x, shift.y, size.z/2-0.005])
                linear_extrude(height=0.01, center=true)
                    square([size.x,size.y]*scale, center=true);
            down(size.z/2-0.005)
                linear_extrude(height=0.01, center=true)
                    square([size.x,size.y], center=true);
        }
        children();
    }
}
yprismoidal([100,60,30], scale=1.5, shift=[20,20]) show_anchors(20);
```


### Cylindrical Attachables
To make a cylindrical shape attachable, you use the `l`, and `r`/`d`, args of `attachable()`.

```openscad
module twistar(l,r,d, anchor=CENTER, spin=0, orient=UP) {
    r = get_radius(r=r,d=d,dflt=1);
    attachable(anchor,spin,orient, r=r, l=l) {
        linear_extrude(height=l, twist=90, slices=20, center=true, convexity=4)
            star(n=20, r=r, ir=r*0.9);
        children();
    }
}
twistar(l=100, r=40) show_anchors(20);
```

If the cylinder is elipsoidal in shape, you can pass the inequal X/Y sizes as a 2-item vector
to the `r=` or `d=` argument.

```openscad
module ovalstar(l,rx,ry, anchor=CENTER, spin=0, orient=UP) {
    attachable(anchor,spin,orient, r=[rx,ry], l=l) {
        linear_extrude(height=l, center=true, convexity=4)
            scale([1,ry/rx,1])
                star(n=20, r=rx, ir=rx*0.9);
        children();
    }
}
ovalstar(l=100, rx=50, ry=30) show_anchors(20);
```

For cylindrical shapes that arent oriented vertically, use the `axis=` argument.

```openscad
module ytwistar(l,r,d, anchor=CENTER, spin=0, orient=UP) {
    r = get_radius(r=r,d=d,dflt=1);
    attachable(anchor,spin,orient, r=r, l=l, axis=BACK) {
        xrot(-90)
            linear_extrude(height=l, twist=90, slices=20, center=true, convexity=4)
                star(n=20, r=r, ir=r*0.9);
        children();
    }
}
ytwistar(l=100, r=40) show_anchors(20);
```

### Conical Attachables
To make a conical shape attachable, you use the `l`, `r1`/`d1`, and `r2`/`d2`, args of
`attachable()`.

```openscad
module twistar(l, r,r1,r2, d,d1,d2, anchor=CENTER, spin=0, orient=UP) {
    r1 = get_radius(r1=r1,r=r,d1=d1,d=d,dflt=1);
    r2 = get_radius(r1=r2,r=r,d1=d2,d=d,dflt=1);
    attachable(anchor,spin,orient, r1=r1, r2=r2, l=l) {
        linear_extrude(height=l, twist=90, scale=r2/r1, slices=20, center=true, convexity=4)
            star(n=20, r=r1, ir=r1*0.9);
        children();
    }
}
twistar(l=100, r1=40, r2=20) show_anchors(20);
```

If the cone is elipsoidal in shape, you can pass the inequal X/Y sizes as a 2-item vectors
to the `r1=`/`r2=` or `d1=`/`d2=` arguments.

```openscad
module ovalish(l,rx1,ry1,rx2,ry2, anchor=CENTER, spin=0, orient=UP) {
    attachable(anchor,spin,orient, r1=[rx1,ry1], r2=[rx2,ry2], l=l) {
        hull() {
            up(l/2-0.005)
                linear_extrude(height=0.01, center=true)
                    oval([rx2,ry2]);
            down(l/2-0.005)
                linear_extrude(height=0.01, center=true)
                    oval([rx1,ry1]);
        }
        children();
    }
}
ovalish(l=100, rx1=50, ry1=30, rx2=30, ry2=50) show_anchors(20);
```

For conical shapes that are not oriented vertically, use the `axis=` argument.

```openscad
module ytwistar(l, r,r1,r2, d,d1,d2, anchor=CENTER, spin=0, orient=UP) {
    r1 = get_radius(r1=r1,r=r,d1=d1,d=d,dflt=1);
    r2 = get_radius(r1=r2,r=r,d1=d2,d=d,dflt=1);
    attachable(anchor,spin,orient, r1=r1, r2=r2, l=l, axis=BACK) {
        xrot(-90)
            linear_extrude(height=l, twist=90, scale=r2/r1, slices=20, center=true, convexity=4)
                star(n=20, r=r1, ir=r1*0.9);
        children();
    }
}
ytwistar(l=100, r1=40, r2=20) show_anchors(20);
```

### Spherical Attachables
To make a spherical shape attachable, you use the `r`/`d` args of `attachable()`.

```openscad
module spikeball(r, d, anchor=CENTER, spin=0, orient=UP) {
    r = get_radius(r=r,d=d,dflt=1);
    attachable(anchor,spin,orient, r=r*1.1) {
        union() {
            ovoid_spread(r=r, n=512, cone_ang=180) cylinder(r1=r/10, r2=0, h=r/10);
            sphere(r=r);
        }
        children();
    }
}
spikeball(r=50) show_anchors(20);
```

If the shape is more of an ovoid, you can pass a 3-item vector of sizes to `r=` or `d=`.

```openscad
module spikeball(r, d, scale, anchor=CENTER, spin=0, orient=UP) {
    r = get_radius(r=r,d=d,dflt=1);
    attachable(anchor,spin,orient, r=r*1.1*scale) {
        union() {
            ovoid_spread(r=r, n=512, scale=scale, cone_ang=180) cylinder(r1=r/10, r2=0, h=r/10);
            scale(scale) sphere(r=r);
        }
        children();
    }
}
spikeball(r=50, scale=[0.75,1,1.5]) show_anchors(20);
```

### VNF Attachables
If the shape just doesn't fit into any of the above categories, and you constructed it as a
[VNF](vnf.scad), you can use the VNF itself to describe the geometry with the `vnf=` argument.

There are two variations to how anchoring can work for VNFs. When `extent=true`, (the default)
then a plane is projected out from the origin, perpendicularly in the direction of the anchor,
to the furthest distance that intersects with the VNF shape.  The anchorpoint is then the
center of the points that still intersect that plane.

```openscad-FlatSpin,VPD=500
module stellate_cube(s=100, anchor=CENTER, spin=0, orient=UP) {
    s2 = 3 * s;
    verts = [
        [0,0,-s2*sqrt(2)/2],
        each down(s/2, p=path3d(square(s,center=true))),
        each zrot(45, p=path3d(square(s2,center=true))),
        each up(s/2, p=path3d(square(s,center=true))),
        [0,0,s2*sqrt(2)/2]
    ];
    faces = [
        [0,2,1], [0,3,2], [0,4,3], [0,1,4],
        [1,2,6], [1,6,9], [6,10,9], [2,10,6],
        [1,5,4], [1,9,5], [9,12,5], [5,12,4],
        [4,8,3], [4,12,8], [12,11,8], [11,3,8],
        [2,3,7], [3,11,7], [7,11,10], [2,7,10],
        [9,10,13], [10,11,13], [11,12,13], [12,9,13]
    ];
    vnf = [verts, faces];
    attachable(anchor,spin,orient, vnf=vnf) {
        vnf_polyhedron(vnf);
        children();
    }
}
stellate_cube(25) {
    attach(UP+RIGHT) {
        anchor_arrow(20);
        %cube([100,100,0.1],center=true);
    }
}
```

When `extent=false`, then the anchorpoint will be the furthest intersection of the VNF with
the anchor ray from the origin. The orientation of the anchorpoint will be the normal of the
face at the intersection.  If the intersection is at an edge or corner, then the orientation
will bisect the angles between the faces.

```openscad-VPD=1250
module stellate_cube(s=100, anchor=CENTER, spin=0, orient=UP) {
    s2 = 3 * s;
    verts = [
        [0,0,-s2*sqrt(2)/2],
        each down(s/2, p=path3d(square(s,center=true))),
        each zrot(45, p=path3d(square(s2,center=true))),
        each up(s/2, p=path3d(square(s,center=true))),
        [0,0,s2*sqrt(2)/2]
    ];
    faces = [
        [0,2,1], [0,3,2], [0,4,3], [0,1,4],
        [1,2,6], [1,6,9], [6,10,9], [2,10,6],
        [1,5,4], [1,9,5], [9,12,5], [5,12,4],
        [4,8,3], [4,12,8], [12,11,8], [11,3,8],
        [2,3,7], [3,11,7], [7,11,10], [2,7,10],
        [9,10,13], [10,11,13], [11,12,13], [12,9,13]
    ];
    vnf = [verts, faces];
    attachable(anchor,spin,orient, vnf=vnf, extent=false) {
        vnf_polyhedron(vnf);
        children();
    }
}
stellate_cube() show_anchors(50);
```


## Making Named Anchors
While vector anchors are often useful, sometimes there are logically extra attachment points that
aren't on the perimeter of the shape.  This is what named string anchors are for.  For example,
the `teardrop()` shape uses a cylindrical geometry for it's vector anchors, but it also provides
a named anchor "cap" that is at the tip of the hat of the teardrop shape.

Named anchors are passed as an array of `anchorpt()`s to the `anchors=` argument of `attachable()`.
The `anchorpt()` call takes a name string, a positional point, an orientation vector, and a spin.
The name is the name of the anchor.  The positional point is where the anchorpoint is at.  The
orientation vector is the direction that a child attached at that anchorpoint should be oriented.
The spin is the number of degrees that an attached child should be rotated counter-clockwise around
the orientation vector.  Spin is optional, and defaults to 0.

To make a simple attachable shape similar to a `teardrop()` that provides a "cap" anchor, you may
define it like this:

```openscad
module raindrop(r, thick, anchor=CENTER, spin=0, orient=UP) {
    anchors = [
        anchorpt("cap", [0,r/sin(45),0], BACK, 0)
    ];
    attachable(anchor,spin,orient, r=r, l=thick, anchors=anchors) {
        linear_extrude(height=thick, center=true) {
            circle(r=r);
            back(r*sin(45)) zrot(45) square(r, center=true);
        }
        children();
    }
}
raindrop(r=25, thick=20, anchor="cap");
```

If you want multiple named anchors, just add them to the list of anchors:

```openscad-FlatSpin,VPD=150
module raindrop(r, thick, anchor=CENTER, spin=0, orient=UP) {
    anchors = [
        anchorpt("captop", [0,r/sin(45), thick/2], BACK+UP,   0),
        anchorpt("cap",    [0,r/sin(45), 0      ], BACK,      0),
        anchorpt("capbot", [0,r/sin(45),-thick/2], BACK+DOWN, 0)
    ];
    attachable(anchor,spin,orient, r=r, l=thick, anchors=anchors) {
        linear_extrude(height=thick, center=true) {
            circle(r=r);
            back(r*sin(45)) zrot(45) square(r, center=true);
        }
        children();
    }
}
raindrop(r=15, thick=10) show_anchors();
```

Sometimes the named anchor you want to add may be at a point that is reached through a complicated
set of translations and rotations.  One quick way to calculate that point is to reproduce those
transformations in a transformation matrix chain.  This is simplified by how you can use the
function forms of almost all the transformation modules to get the transformation matrices, and
chain them together with matrix multiplication.  For example, if you have:

```
scale([1.1, 1.2, 1.3]) xrot(15) zrot(25) right(20) sphere(d=1);
```

and you want to calculate the centerpoint of the sphere, you can do it like:

```
sphere_pt = apply(
    scale([1.1, 1.2, 1.3]) * xrot(15) * zrot(25) * right(20),
    [0,0,0]
);
```


