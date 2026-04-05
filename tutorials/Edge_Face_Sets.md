# Edge Sets and Face Sets

## Overview

When working with BOSL2 shapes like `cuboid()`, you often want to round or chamfer
only specific edges, or apply masks to certain faces. BOSL2 provides a flexible system
for selecting edges and faces using direction vectors and string constants.

This tutorial explains how to specify which edges and faces you want to operate on.


## Faces

A face on a cube-like shape is identified by a single direction vector pointing
toward that face. The six faces and their vector names are:

| Vector       | Aliases           | Description       |
|--------------|-------------------|-------------------|
| `TOP` / `UP`    | `[0,0,1]`     | Top face (+Z)     |
| `BOT` / `DOWN`  | `[0,0,-1]`    | Bottom face (-Z)  |
| `FRONT` / `FWD` | `[0,-1,0]`    | Front face (-Y)   |
| `BACK`           | `[0,1,0]`     | Back face (+Y)    |
| `LEFT`           | `[-1,0,0]`    | Left face (-X)    |
| `RIGHT`          | `[1,0,0]`     | Right face (+X)   |

Face vectors are used with modules like `face_profile()` to apply a 2D mask
profile to all edges and corners of a given face:

```openscad-3D
include <BOSL2/std.scad>
diff()
cube([50,60,70], center=true)
    face_profile(TOP, r=10)
        mask2d_roundover(10);
```

You can also pass a list of faces:

```openscad-3D
include <BOSL2/std.scad>
diff()
cube([50,60,70], center=true) {
    face_profile(TOP, r=10)
        mask2d_roundover(10);
    face_profile(FRONT, r=10)
        mask2d_roundover(10);
}
```


## Edges

A cube has 12 edges. BOSL2 identifies each edge by combining two face direction
vectors. For example, the edge where the TOP and FRONT faces meet is `TOP+FRONT`.

### Single Edge Selection

You select a single edge by summing two adjacent face vectors:

```openscad-3D
include <BOSL2/std.scad>
cuboid([50,60,70], rounding=10, edges=[TOP+FRONT]);
```

The 12 edges of a cube, grouped by level:

**Top edges:**
- `TOP+FRONT`
- `TOP+BACK`
- `TOP+LEFT`
- `TOP+RIGHT`

**Bottom edges:**
- `BOT+FRONT`
- `BOT+BACK`
- `BOT+LEFT`
- `BOT+RIGHT`

**Vertical edges:**
- `FRONT+LEFT`
- `FRONT+RIGHT`
- `BACK+LEFT`
- `BACK+RIGHT`

### Selecting All Edges Around a Face

A single face vector selects all four edges surrounding that face:

```openscad-3D
include <BOSL2/std.scad>
cuboid([50,60,70], rounding=10, edges=TOP);
```

This rounds all four edges around the top face. Similarly, `edges=FRONT` selects
the four edges around the front face.

### Selecting Edges Around a Corner

A corner vector (sum of three face vectors) selects the three edges meeting at
that corner:

```openscad-3D
include <BOSL2/std.scad>
cuboid([50,60,70], rounding=5, edges=FRONT+RIGHT+TOP);
```

### Axis-Aligned Edge Sets

You can use string shortcuts to select all edges aligned with a given axis:

| String  | Selects                                       |
|---------|-----------------------------------------------|
| `"X"`   | All 4 edges parallel to the X axis            |
| `"Y"`   | All 4 edges parallel to the Y axis            |
| `"Z"`   | All 4 edges parallel to the Z axis (vertical) |
| `"ALL"` | All 12 edges                                  |
| `"NONE"`| No edges                                      |

```openscad-3D
include <BOSL2/std.scad>
cuboid([50,60,70], rounding=10, edges="Z");
```

This rounds only the four vertical edges.


## Combining Edge Selections

The `edges` parameter accepts a list of edge descriptors. BOSL2 combines them
into a union:

```openscad-3D
include <BOSL2/std.scad>
cuboid([50,60,70], rounding=5, edges=[TOP, FRONT+RIGHT]);
```

This rounds all edges around the top face, plus the single vertical edge
at the front-right.


## The `except` Parameter

Use `except` to remove specific edges from the selection. This is often simpler
than listing every edge you want to keep:

```openscad-3D
include <BOSL2/std.scad>
cuboid([50,60,70], rounding=10, edges="ALL", except=[BOT, FRONT+LEFT]);
```

This rounds all edges except those around the bottom face and the front-left
vertical edge.

The `except` parameter accepts the same descriptors as `edges`: single edges,
face vectors, corner vectors, and axis strings.

```openscad-3D
include <BOSL2/std.scad>
cuboid([50,60,70], rounding=10, edges=TOP, except=TOP+BACK);
```

This rounds the top face edges, except for the top-back edge.


## Edge Sets with Chamfers

The same edge selection system works with the `chamfer` parameter on `cuboid()`:

```openscad-3D
include <BOSL2/std.scad>
cuboid([50,60,70], chamfer=5, edges=[TOP+FRONT, TOP+RIGHT, FRONT+RIGHT]);
```


## Edge Sets with Masking Modules

The `edge_mask()` and `edge_profile()` modules also use edge set descriptors
to control which edges receive a mask.

### `edge_profile()`

Extrudes a 2D profile along selected edges:

```openscad-3D
include <BOSL2/std.scad>
diff()
cube([50,60,70], center=true)
    edge_profile([TOP, "Z"], except=[BACK, TOP+LEFT])
        mask2d_roundover(10);
```

### `edge_mask()`

Positions a 3D mask shape along selected edges:

```openscad-3D
include <BOSL2/std.scad>
module round_edge(l, r) difference() {
    translate([-1,-1,-l/2])
        cube([r+1, r+1, l]);
    translate([r, r])
        cylinder(h=l+1, r=r, center=true, $fn=quantup(segs(r),4));
}
diff()
cube([50,60,70], center=true)
    edge_mask([TOP, "Z"], except=[BACK, TOP+LEFT])
        round_edge(l=71, r=10);
```


## Practical Examples

### Rounded Top, Sharp Bottom

A common pattern for enclosures: round only the top edges.

```openscad-3D
include <BOSL2/std.scad>
cuboid([60,40,30], rounding=5, edges=TOP);
```

### Chamfer Only Vertical Edges

Useful for grip surfaces or decorative columns:

```openscad-3D
include <BOSL2/std.scad>
cuboid([30,30,60], chamfer=3, edges="Z");
```

### Round Everything Except Bottom

A box that sits flat on the build plate:

```openscad-3D
include <BOSL2/std.scad>
cuboid([50,40,25], rounding=4, edges="ALL", except=BOT);
```


## Summary

| Descriptor          | What it selects                      |
|---------------------|--------------------------------------|
| `TOP+FRONT`         | A single edge                        |
| `TOP`               | All 4 edges around the top face      |
| `FRONT+LEFT+TOP`    | All 3 edges at a corner              |
| `"X"`, `"Y"`, `"Z"`| All 4 edges along an axis            |
| `"ALL"`             | All 12 edges                         |
| `"NONE"`            | No edges                             |
| `except=BOT`        | Remove bottom edges from selection   |

These selectors work consistently across `cuboid()`, `edge_mask()`,
`edge_profile()`, `corner_mask()`, `corner_profile()`, and `face_profile()`.
