[Prev: Tagged Operations with Attachments](Tutorial-Attachment-Tags)

# Using Attachment for Edge Profiling

You can use attachment in various ways to create edge profiles on
objects.  One method is to simply attach an edge mask to the edge of a
parent object while using `diff()` so that the mask creates the
desired edge profile.  Most objects set the `$edge_angle` and
`$edge_length` variables so make this easier to do.

Another way to apply edge treatments is to use some specialized
modules for applying masks.  Modules such as `edge_mask()` can for working with 3D masks,
which may potentially change across their length.  Modules like
`edge_profile()` can extrude a 2D profile along specified edges.  

## 3D Masking Attachments
To make it easier to mask away shapes from various edges of an attachable parent shape, there
are a few specialized alternatives to the `attach()` and `position()` modules.

### `edge_mask()`
If you have a 3D mask shape that you want to difference away from various edges, you can use
the `edge_mask()` module.  This module will take a vertically oriented shape, and will rotate
and move it such that the BACK, RIGHT (X+,Y+) side of the shape will be aligned with the given
edges.  The shape will be tagged as a "remove" so that you can use
`diff()` with its default "remove" tag.  For example,
here's a shape for rounding an edge:

```openscad-3D
include <BOSL2/std.scad>
module round_edge(l,r) difference() {
    translate([-1,-1,-l/2])
        cube([r+1,r+1,l]);
    translate([r,r])
        cylinder(h=l+1,r=r,center=true, $fn=quantup(segs(r),4));
}
round_edge(l=30, r=19);
```

You can use that mask to round various edges of a cube:

```openscad-3D
include <BOSL2/std.scad>
module round_edge(l,r) difference() {
    translate([-1,-1,-l/2])
        cube([r+1,r+1,l]);
    translate([r,r])
        cylinder(h=l+1,r=r,center=true, $fn=quantup(segs(r),4));
}
diff()
cube([50,60,70],center=true)
    edge_mask([TOP,"Z"],except=[BACK,TOP+LEFT])
        round_edge(l=71,r=10);
```

### `corner_mask()`
If you have a 3D mask shape that you want to difference away from various corners, you can use
the `corner_mask()` module.  This module will take a shape and rotate and move it such that the
BACK RIGHT TOP (X+,Y+,Z+) side of the shape will be aligned with the given corner.  The shape
will be tagged as a "remove" so that you can use `diff()` with its
default "remove" tag.  For example, here's a shape for
rounding a corner:

```openscad-3D
include <BOSL2/std.scad>
module round_corner(r) difference() {
    translate(-[1,1,1])
        cube(r+1);
    translate([r,r,r])
        spheroid(r=r, style="aligned", $fn=quantup(segs(r),4));
}
round_corner(r=10);
```

You can use that mask to round various corners of a cube:

```openscad-3D
include <BOSL2/std.scad>
module round_corner(r) difference() {
    translate(-[1,1,1])
        cube(r+1);
    translate([r,r,r])
        spheroid(r=r, style="aligned", $fn=quantup(segs(r),4));
}
diff()
cube([50,60,70],center=true)
    corner_mask([TOP,FRONT],LEFT+FRONT+TOP)
        round_corner(r=10);
```

### Mix and Match Masks
You can use `edge_mask()` and `corner_mask()` together as well:

```openscad-3D
include <BOSL2/std.scad>
module round_corner(r) difference() {
    translate(-[1,1,1])
        cube(r+1);
    translate([r,r,r])
        spheroid(r=r, style="aligned", $fn=quantup(segs(r),4));
}
module round_edge(l,r) difference() {
    translate([-1,-1,-l/2])
        cube([r+1,r+1,l]);
    translate([r,r])
        cylinder(h=l+1,r=r,center=true, $fn=quantup(segs(r),4));
}
diff()
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
extruded to a mask of the appropriate length for each given edge.  The resultant mask will be
tagged with "remove" so that you can difference it away with `diff()`
with the default "remove" tag.  The 2D profile is
assumed to be oriented with the BACK, RIGHT (X+,Y+) quadrant as the "cutter edge" that gets
re-oriented towards the edges of the parent shape.  A typical mask profile for chamfering an
edge may look like:

```openscad-2D
include <BOSL2/std.scad>
mask2d_roundover(10);
```

Using that mask profile, you can mask the edges of a cube like:

```openscad-3D
include <BOSL2/std.scad>
diff()
cube([50,60,70],center=true)
   edge_profile("ALL")
       mask2d_roundover(10);
```

### `corner_profile()`
You can use the same profile to make a rounded corner mask as well:

```openscad-3D
include <BOSL2/std.scad>
diff()
cube([50,60,70],center=true)
   corner_profile("ALL", r=10)
       mask2d_roundover(10);
```

### `face_profile()`
As a simple shortcut to apply a profile mask to all edges and corners of a face, you can use the
`face_profile()` module:

```openscad-3D
include <BOSL2/std.scad>
diff()
cube([50,60,70],center=true)
   face_profile(TOP, r=10)
       mask2d_roundover(10);
```

[Next: Making Attachable Objects](Tutorial-Attachment-Making)
