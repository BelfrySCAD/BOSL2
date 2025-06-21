[Prev: Edge Profiling with Attachment](Tutorial-Attachment-Edge-Profiling)

# Making Attachables

To make a shape attachable, you just need to wrap it with an `attachable()` module with a
basic description of the shape's geometry.  By default, the shape is expected to be centered
at the origin.  This fact is important, as this is how the
`attachable()` module knows the dimensions of your part: it assumes it
is symetric around the origin.  The `attachable()` module expects
exactly two children.  The first will bethe shape to make attachable,
and the second will be `children()`, literally.

### Pass-through Attachables
The simplest way to make your own attachable module is to simply pass
through to a pre-existing attachable submodule.  This could be
appropriate if you want to rename a module, or if the anchors of an
existing module are suited to (or good enough for) your object.  In
order for your attachable module to work properly you need to accept
the `anchor`, `spin` and `orient` parameters, give them suitable
defaults, and pass them to the attachable submodule.  Don't forget to
pass the children to the attachable submodule as well, or your new
module will ignore its children.  

```openscad-3D
include <BOSL2/std.scad>
$fn=32;
module cutcube(anchor=CENTER,spin=0,orient=UP)
{
   tag_scope(){
     diff()
       cuboid(15, rounding=2, anchor=anchor,spin=spin,orient=orient){
         tag("remove")attach(TOP)cuboid(5);
         children();
       }
   }
}
diff()
cutcube()
  tag("remove")attach(RIGHT) cyl(d=2,h=8);
```

### Prismoidal/Cuboidal Attachables
To make a cuboidal or prismoidal shape attachable, you use the `size`, `size2`, and `offset`
arguments of `attachable()`.

In the most basic form, where the shape is fully cuboid, with top and bottom of the same size,
and directly over one another, you can just use `size=`.

```openscad-3D;Big
include <BOSL2/std.scad>
module cubic_barbell(s=100, anchor=CENTER, spin=0, orient=UP) {
    attachable(anchor,spin,orient, size=[s*3,s,s]) {
        union() {
            xcopies(2*s) cube(s, center=true);
            xcyl(h=2*s, d=s/4);
        }
        children();
    }
}
cubic_barbell(100) show_anchors(60);
```

When the shape is prismoidal, where the top is a different size from the bottom, you can use
the `size2=` argument as well. While `size=` takes all three axes sizes, the `size2=` argument
only takes the [X,Y] sizes of the top of the shape.

```openscad-3D;Big
include <BOSL2/std.scad>
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

```openscad-3D;Big
include <BOSL2/std.scad>
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

```openscad-3D;Big
include <BOSL2/std.scad>
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

```openscad-3D;Big
include <BOSL2/std.scad>
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

If the cylinder is elipsoidal in shape, you can pass the unequal X/Y sizes as a 2-item vector
to the `r=` or `d=` argument.

```openscad-3D
include <BOSL2/std.scad>
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

For cylindrical shapes that aren't oriented vertically, use the `axis=` argument.

```openscad-3D
include <BOSL2/std.scad>
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

```openscad-3D;Big
include <BOSL2/std.scad>
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

If the cone is ellipsoidal in shape, you can pass the unequal X/Y sizes as a 2-item vectors
to the `r1=`/`r2=` or `d1=`/`d2=` arguments.

```openscad-3D;Big
include <BOSL2/std.scad>
module ovalish(l,rx1,ry1,rx2,ry2, anchor=CENTER, spin=0, orient=UP) {
    attachable(anchor,spin,orient, r1=[rx1,ry1], r2=[rx2,ry2], l=l) {
        hull() {
            up(l/2-0.005)
                linear_extrude(height=0.01, center=true)
                    ellipse([rx2,ry2]);
            down(l/2-0.005)
                linear_extrude(height=0.01, center=true)
                    ellipse([rx1,ry1]);
        }
        children();
    }
}
ovalish(l=100, rx1=50, ry1=30, rx2=30, ry2=50) show_anchors(20);
```

For conical shapes that are not oriented vertically, use the `axis=` argument to indicate the
direction of the primary shape axis:

```openscad-3D;Big
include <BOSL2/std.scad>
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

```openscad-3D;Big
include <BOSL2/std.scad>
module spikeball(r, d, anchor=CENTER, spin=0, orient=UP) {
    r = get_radius(r=r,d=d,dflt=1);
    attachable(anchor,spin,orient, r=r*1.1) {
        union() {
            sphere_copies(r=r, n=512, cone_ang=180) cylinder(r1=r/10, r2=0, h=r/10);
            sphere(r=r);
        }
        children();
    }
}
spikeball(r=50) show_anchors(20);
```

If the shape is an ellipsoid, you can pass a 3-item vector of sizes to `r=` or `d=`.

```openscad-3D
include <BOSL2/std.scad>
module spikeball(r, d, scale, anchor=CENTER, spin=0, orient=UP) {
    r = get_radius(r=r,d=d,dflt=1);
    attachable(anchor,spin,orient, r=r*1.1*scale) {
        union() {
            sphere_copies(r=r, n=512, scale=scale, cone_ang=180) cylinder(r1=r/10, r2=0, h=r/10);
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
to the furthest distance that intersects with the VNF shape.  The anchor point is then the
center of the points that still intersect that plane.

```openscad-FlatSpin,VPD=500
include <BOSL2/std.scad>
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

When `extent=false`, then the anchor point will be the furthest intersection of the VNF with
the anchor ray from the origin. The orientation of the anchor point will be the normal of the
face at the intersection.  If the intersection is at an edge or corner, then the orientation
will bisect the angles between the faces.

```openscad-VPD=1250
include <BOSL2/std.scad>
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

```openscad-3D
include <BOSL2/std.scad>
$fn=32;
R = difference(circle(10), right(2, circle(9)));
linear_sweep(R,height=10,atype="hull")
    attach(RIGHT) anchor_arrow();
```


## Making Named Anchors
While vector anchors are often useful, sometimes there are logically extra attachment points that
aren't on the perimeter of the shape.  This is what named string anchors are for.  For example,
the `teardrop()` shape uses a cylindrical geometry for it's vector anchors, but it also provides
a named anchor "cap" that is at the tip of the hat of the teardrop shape.

Named anchors are passed as an array of `named_anchor()`s to the `anchors=` argument of `attachable()`.
The `named_anchor()` call takes a name string, a positional point, an orientation vector, and a spin.
The name is the name of the anchor.  The positional point is where the anchor point is at.  The
orientation vector is the direction that a child attached at that anchor point should be oriented.
The spin is the number of degrees that an attached child should be rotated counter-clockwise around
the orientation vector.  Spin is optional, and defaults to 0.

To make a simple attachable shape similar to a `teardrop()` that provides a "cap" anchor, you may
define it like this:

```openscad-3D
include <BOSL2/std.scad>
module raindrop(r, thick, anchor=CENTER, spin=0, orient=UP) {
    anchors = [
        named_anchor("cap", [0,r/sin(45),0], BACK, 0)
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
include <BOSL2/std.scad>
module raindrop(r, thick, anchor=CENTER, spin=0, orient=UP) {
    anchors = [
        named_anchor("captop", [0,r/sin(45), thick/2], BACK+UP,   0),
        named_anchor("cap",    [0,r/sin(45), 0      ], BACK,      0),
        named_anchor("capbot", [0,r/sin(45),-thick/2], BACK+DOWN, 0)
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

and you want to calculate the center point of the sphere, you can do it like:

```
sphere_pt = apply(
    scale([1.1, 1.2, 1.3]) * xrot(15) * zrot(25) * right(20),
    [0,0,0]
);
```


## Overriding Standard Anchors

Sometimes you may want to use the standard anchors but override some
of them.  Returning to the square barebell example above, the anchors
at the right and left sides are on the cubes at each end, but the
anchors at x=0 are in floating in space.  For prismoidal/cubic anchors
in 3D and trapezoidal/rectangular anchors in 2D we can override a single anchor by
specifying the override option and giving the anchor that is being
overridden, and then the replacement in the form
`[position, direction, spin]`.  Most often you will only want to
override the position.  If you omit the other list items then the
value drived from the standard anchor will be used. Below we override
position of the FWD anchor:

```openscad-3D;Big
include<BOSL2/std.scad>
module cubic_barbell(s=100, anchor=CENTER, spin=0, orient=UP) {
    override = [
                 [FWD,  [[0,-s/8,0]]]
               ];
    attachable(anchor,spin,orient, size=[s*3,s,s],override=override) {
        union() {
            xcopies(2*s) cube(s, center=true);
            xcyl(h=2*s, d=s/4);
        }
        children();
    }
}
cubic_barbell(100) show_anchors(60);
```

Note how the FWD anchor is now rooted on the cylindrical portion.  If
you wanted to also change its direction and spin you could do it like
this:

```openscad-3D;Big
include<BOSL2/std.scad>
module cubic_barbell(s=100, anchor=CENTER, spin=0, orient=UP) {
    override = [
                 [FWD,  [[0,-s/8,0], FWD+LEFT, 225]]
               ];
    attachable(anchor,spin,orient, size=[s*3,s,s],override=override) {
        union() {
            xcopies(2*s) cube(s, center=true);
            xcyl(h=2*s, d=s/4);
        }
        children();
    }
}
cubic_barbell(100) show_anchors(60);
```

In the above example we give three values for the override.  As
before, the first one places the anchor on the cylinder.  We have
added the second entry which points the anchor off to the left.
The third entry gives a spin override, whose effect is shown by the
position of the red flag on the arrow.  If you want to override all of
the x=0 anchors to be on the cylinder, with their standard directions,
you can do that by supplying a list: 

```openscad-3D;Big
include<BOSL2/std.scad>
module cubic_barbell(s=100, anchor=CENTER, spin=0, orient=UP) {
    override = [
                 for(j=[-1:1:1], k=[-1:1:1])
                   if ([j,k]!=[0,0]) [[0,j,k], [s/8*unit([0,j,k])]]
               ];
    attachable(anchor,spin,orient, size=[s*3,s,s],override=override) {
        union() {
            xcopies(2*s) cube(s, center=true);
            xcyl(h=2*s, d=s/4);
        }
        children();
    }
}
cubic_barbell(100) show_anchors(30);
```

Now all of the anchors in the middle are all rooted to the cylinder.  Another
way to do the same thing is to use a function literal for override.
It will be called with the anchor as its argument and needs to return undef to just use
the default, or a `[position, direction, spin]` triple to override the
default.  As before, you can omit values to keep their default.
Here is the same example using a function literal for the override:

```openscad-3D;Big
include<BOSL2/std.scad>
module cubic_barbell(s=100, anchor=CENTER, spin=0, orient=UP) {
    override = function (anchor) 
          anchor.x!=0 || anchor==CTR ? undef  // Keep these
        : [s/8*unit(anchor)];
    attachable(anchor,spin,orient, size=[s*3,s,s],override=override) {
        union() {
            xcopies(2*s) cube(s, center=true);
            xcyl(h=2*s, d=s/4);
        }
        children();
    }
}
cubic_barbell(100) show_anchors(30);
```

## Making Gometry With attach_geom()

Sometimes it may be advantageous to create the attachable geometry as
a data structure.  This can be particularly useful if you want to
implement anchor types with an object, because it allows for an easy
way to create different anchor options without having to repeat code.

Suppose we create a simple tetrahedron object:

```openscad-3D
include<BOSL2/std.scad>
module tetrahedron(base, height, spin=0, anchor=FWD+LEFT+BOT, orient=UP)
{
   base_poly = path3d([[0,0],[0,base],[base,0]]);
   top = [0,0,height];
   vnf = vnf_vertex_array([base_poly, repeat(top,3)],col_wrap=true,cap1=true);
   attachable(anchor=anchor,orient=orient,spin=spin,vnf=vnf,cp="centroid"){
     vnf_polyhedron(vnf);
     children();
   }
}   
tetrahedron(20,18) show_anchors();
```

For this module we have used VNF anchors, but this tetrahedron is the
corner of a cuboid, so maybe sometimes you prefer to use anchors
based on the corresponding cuboid (its bounding box).  You can create a module with bounding
box anchors like this, where we have explicitly centered the VNF
to make it work with the prismoid type anchoring:

```openscad-3D
include<BOSL2/std.scad>
module tetrahedron(base, height, spin=0, anchor=FWD+LEFT+BOT, orient=UP)
{
   base_poly = path3d([[0,0],[0,base],[base,0]]);
   top = [0,0,height];
   vnf = move([-base/2,-base/2,-height/2],
              vnf_vertex_array([base_poly, repeat(top,3)],col_wrap=true,cap1=true));
   attachable(anchor=anchor,orient=orient,spin=spin,size=[base,base,height]){
     vnf_polyhedron(vnf);
     children();
   }
}   
tetrahedron(20,18) show_anchors();
```

The arguments needed to attachable are different in this case.  If you
want to conditionally switch between these two modes of operation,
this presents a complication.  While it is possible to work around
this by conditionally setting parameters to `undef`, the resulting
code will be more complex and harder to read.  A better solution is to
compute the geometry conditionally.  Then the geometry can be passed
to `attachable()`.

```openscad-3D;Big
include<BOSL2/std.scad>
module tetrahedron(base, height, atype="vnf", spin=0, anchor=FWD+LEFT+BOT, orient=UP)
{
   assert(atype=="vnf" || atype=="box");
   base_poly = path3d([[0,0],[0,base],[base,0]]);
   top = [0,0,height];
   vnf = move([-base/2,-base/2,-height/2],
              vnf_vertex_array([base_poly, repeat(top,3)],col_wrap=true,cap1=true));
   geom = atype=="vnf" ? attach_geom(vnf=vnf,cp="centroid")
                       : attach_geom(size=[base,base,height]);
   attachable(anchor=anchor,orient=orient,spin=spin,geom=geom){
     vnf_polyhedron(vnf);
     children();
   }
}   
tetrahedron(20,18,atype="vnf")
  color("green")attach(TOP,BOT) cuboid(4);
right(25)
  tetrahedron(20,18,atype="box")
    color("lightblue")attach(TOP,BOT) cuboid(4);
```

Here we have created an `atype` argument that accepts two attachment
types and we compute the geometry conditionally based on the atype
setting.  We can then invoke `attachable()` once with the `geom`
parameter to specify the geometry.  


## Creating Attachable Parts

If your object has multiple distinct parts you may wish to create
attachble parts for your object.  In the library, `tube()` create
an attachable part called "inside" that lets you attach to the inside
of the tube.

Below we create an example where an object is made from two
cylindrical parts, and we want to be able to attach to either
one.  In order to create attchable parts you must pass a list of the parts
to `attachable()`.  You create a part using the `define_part()`
function which requires the part's name and its geometry.  You can
optionally provide a transformation using the `T=` parameter and give
a flat with the `inside=` parameter.  

```openscad-3D;Big
include<BOSL2/std.scad>
module twocyl(d1, d2, sep, h, ang=20) 
{
   parts = [
             define_part("left", attach_geom(r=d1/2,h=h),
                                 T=left(sep/2)*yrot(-ang)),
             define_part("right", attach_geom(r=d2/2,h=h),
                                  T=right(sep/2)*yrot(ang)),
           ];
   attachable(size=[sep+d1/2+d2/2,max(d1,d2),h], parts=parts){
     union(){
         left(sep/2) yrot(-ang) cyl(d=d1,h=h);
         right(sep/2) yrot(ang) cyl(d=d2,h=h);
     }
     children();
   }  
}
twocyl(d1=10,d2=13,sep=20,h=10){
  attach_part("left") attach(FWD,BOT)
     color("lightblue") cuboid(3);
  attach_part("right") attach(RIGHT,BOT)
     color("green") cuboid(3);
}  
```

In the above example we create a parts list containing two parts named
"left" and "right".  Each part has its own geometry corresponding to
the size of the cylinder, and it has a transformation specifying where
the cylinder is located relative to the part's overall geometry.

If you create an "inside" part for a tube, the inside object will
naturally have its anchors on the inner cylinder **pointing
outward**.  You can anchor on the inside by setting `inside=true` when
invoking `attach()` or `align()`, but another option is to set `inside=true`
with `define_part()`.  This marks the geometry as an inside geometry, which cause `align()` and
`attach()` to invert the meaning of the `inside` parameter so that
objects will attach on the inside by default.
