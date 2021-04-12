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


## Masking Children
edge_mask()
corner_mask()

face_profile()
edge_profile()
corner_profile()


## Coloring Attachables


## Making Attachables


## Making Named Anchors


