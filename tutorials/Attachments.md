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


## Orientation
Another way to specify a rotation for an attachable shape, is to pass a 3D vector via the
`orient=` argument.  This lets you specify what direction to tilt the top of the shape towards.
For example, you can make a cone that is tilted up and to the right like this:

```openscad
cylinder(h=100, r1=50, r2=20, orient=UP+RIGHT);
```

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


## Attaching Children
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

By default, `attach()` causes the child to overlap the parent by 0.01, to let CGAL correctly
join the parts.  If you need the child to have no overlap, or a different overlap, you can use
the `overlap=` argument:

```openscad
cube(50,center=true)
    attach(TOP,TOP,overlap=0) cylinder(d1=50,d2=20,l=20);
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


## Masking Children
TBW


## Coloring Attachables
TBW


## Making Attachables
To make a shape attachable, you just need to wrap it with an `attachable()` module with a
basic description of the shape's geometry.  By default, the shape is expected to be centered
at the origin.  The `attachable()` module expects exactly two children.  The first will be
the shape to make attachable, and the second will be `children()`, literally.

### Prismoidal/Cuboidal Attachables
To make a cuboidal or prismoidal shape attachable, you use the `size`, `size2`, and `offset`
arguments of `attachable()`.

In the most basic form, where the shape in fully cuboid, with top and bottom of the same size,
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
cubic_barbell(100);
```

When the shape is prismoidal, where the top is a different size from the bottom, you can use
the `size2=` argument as well.

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
prismoidal([100,60,30], scale=0.5);
```

When the top of the prismoid can be shifted away from directly above the bottom, you can use
the `shift=` argument.

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
prismoidal([100,60,30], scale=0.5, shift=[-30,20]);
```

In the case that the prismoid is not oriented vertically, you can use the `axis=` argument.

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
yprismoidal([100,60,30], scale=1.5, shift=[20,20]);
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
twistar(l=100, r=40);
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
ovalstar(l=100, rx=50, ry=30);
```

For cylindrical shapes that arent oriented vertically, use the `axis=` argument.

```openscad
module ytwistar(l,r,d, anchor=CENTER, spin=0, orient=UP) {
    r = get_radius(r=r,d=d,dflt=1);
    attachable(anchor,spin,orient, r=r, l=l) {
        xrot(-90)
            linear_extrude(height=l, twist=90, slices=20, center=true, convexity=4)
                star(n=20, r=r, ir=r*0.9);
        children();
    }
}
ytwistar(l=100, r=40);
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
twistar(l=100, r1=40, r2=20);
```

If the cone is elipsoidal in shape, you can pass the inequal X/Y sizes as a 2-item vectors
to the `r1=`/`r2=` or `d1=`/`d2=` arguments.

```openscad
module ovalish(l,rx1,ry1,rx2,ry2, anchor=CENTER, spin=0, orient=UP) {
    attachable(anchor,spin,orient, r1=[rx1,ry1], r2=[rx2,ry2], l=l) {
        hull() {
            up(l/2-0.005)
                linear_extrude(height=0.01, center=true)
                    scale([1,ry2/rx2,1])
                        oval([rx2,ry2]);
            down(l/2-0.005)
                linear_extrude(height=0.01, center=true)
                    scale([1,ry1/rx1,1])
                        oval([rx1,ry1]);
        }
        children();
    }
}
ovalish(l=100, rx1=40, ry1=30, rx2=30, ry2=40);
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
ytwistar(l=100, r1=40, r2=20);
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
spikeball(r=50);
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
spikeball(r=50, scale=[0.75,1,1.5]);
```

### VNF Attachables
If the shape just doesn't fit into any of the above categories, and you constructed it as a
[VNF](vnf.scad), you can use the VNF itself to describe the geometry.
TBW


## Making Named Anchors
TBW


