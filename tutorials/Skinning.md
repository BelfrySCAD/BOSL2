# Skinning and Sweeping

<!-- TOC -->

## What is Skinning?

Skinning is the process of creating a 3D shape by connecting a series of 2D cross-sections (profiles) together.  Imagine stacking slices of bread and connecting them with a smooth surface -- that is essentially what skinning does.  BOSL2 provides several powerful functions and modules for this in `skin.scad`, all included via `std.scad`.

The main tools covered in this tutorial are:

- **`skin()`** -- Connects a list of arbitrary polygon profiles into a 3D shape.
- **`path_sweep()`** -- Sweeps a single 2D profile along a 2D or 3D path.
- **`spiral_sweep()`** -- Sweeps a 2D profile along a helical/spiral path.

All of these can be used as modules (to create geometry directly) or as functions (to return a VNF structure).


## skin()

The `skin()` function/module takes a list of 2D or 3D profiles and connects them into a solid.  The simplest usage provides a list of profiles at different Z heights using the `z` parameter:

```openscad-3D
include <BOSL2/std.scad>
skin(
    [ circle(r=20, $fn=32),
      circle(r=10, $fn=32) ],
    z=[0, 40],
    slices=10
);
```

This creates a cone-like shape by connecting a large circle at the bottom to a smaller circle at the top.

### Connecting Different Shapes

One of the most powerful features of `skin()` is connecting profiles with different shapes.  You can morph a square into a circle:

```openscad-3D
include <BOSL2/std.scad>
skin(
    [ square(30, center=true),
      circle(r=15, $fn=32) ],
    z=[0, 30],
    slices=20,
    method="distance"
);
```

The `method="distance"` parameter tells `skin()` how to match up vertices between profiles that have different numbers of points.  The `"distance"` method minimizes the total edge length across profiles.

### Multiple Cross-Sections

You can provide more than two profiles to create more complex shapes.  Here is a simple vase shape:

```openscad-3D
include <BOSL2/std.scad>
skin(
    [ circle(r=20, $fn=32),
      circle(r=10, $fn=32),
      circle(r=15, $fn=32),
      circle(r=12, $fn=32) ],
    z=[0, 20, 50, 70],
    slices=10
);
```

### Closed Skins

Setting `closed=true` connects the last profile back to the first, creating a toroidal shape with no endcaps:

```openscad-3D
include <BOSL2/std.scad>
skin(
    [ move([20,0, 0], circle(r=5,$fn=32)),
      move([0,20, 5], circle(r=8,$fn=32)),
      move([-20,0,0], circle(r=5,$fn=32)),
      move([0,-20,-5], circle(r=8,$fn=32)) ],
    closed=true,
    slices=20
);
```


## path_sweep()

The `path_sweep()` function/module takes a 2D cross-section shape and sweeps it along a path.  This is one of the most commonly used tools for creating tubes, rails, and complex curved objects.

### Basic Usage

Sweep a circle along a simple arc to create a curved tube:

```openscad-3D
include <BOSL2/std.scad>
mypath = arc(r=30, angle=[0, 180], n=64);
path_sweep(
    circle(r=5, $fn=16),
    path3d(mypath)
);
```

### Sweeping Along a 3D Path

You can sweep along a full 3D path.  Here is a profile swept along a sine-wave curve:

```openscad-3D
include <BOSL2/std.scad>
mypath = [for (t=[0:2:360]) [t/6, 15*sin(t), 15*cos(t)]];
path_sweep(
    circle(r=3, $fn=16),
    mypath
);
```

### Twist and Scale

`path_sweep()` supports twisting and scaling the profile along the path.  This is useful for creating decorative shapes:

```openscad-3D
include <BOSL2/std.scad>
path_sweep(
    square([10,2], center=true),
    path3d(arc(r=30, angle=[0, 180], n=64)),
    twist=180
);
```

You can also scale the profile from start to end:

```openscad-3D
include <BOSL2/std.scad>
path_sweep(
    circle(r=8, $fn=24),
    [[0,0,0],[0,0,50]],
    scale=0.2
);
```

### Pipe Along a Bezier Curve

Combine `path_sweep()` with a Bezier path for smooth flowing shapes:

```openscad-3D
include <BOSL2/std.scad>
bez = bezpath_curve(
    [[0,0,0], [20,30,0], [40,-10,20], [60,0,40]],
    n=64
);
path_sweep(circle(r=3, $fn=16), bez);
```


## spiral_sweep()

The `spiral_sweep()` function/module sweeps a 2D polygon along a helical path.  This is particularly useful for making screw threads, springs, and other spiral shapes.

### Basic Spiral

Create a simple spring by sweeping a circle along a spiral:

```openscad-3D
include <BOSL2/std.scad>
spiral_sweep(
    circle(r=3, $fn=16),
    h=50, r=20, turns=5
);
```

### Varying Radius

You can specify different radii at the top and bottom to create a conical spiral:

```openscad-3D
include <BOSL2/std.scad>
spiral_sweep(
    circle(r=2, $fn=16),
    h=40, r1=25, r2=10, turns=4
);
```


## Practical Examples

### Vase with Wavy Profile

```openscad-3D
include <BOSL2/std.scad>
profiles = [
    for (z=[0:5:60])
    let(r = 15 + 5*sin(z*6))
    move([0,0,z], circle(r=r, $fn=48))
];
skin(profiles, slices=2);
```

### Twisted Ribbon

```openscad-3D
include <BOSL2/std.scad>
path_sweep(
    rect([20, 2]),
    [[0,0,0],[0,0,60]],
    twist=360
);
```

### Pipe Along a 3D Curve

```openscad-3D
include <BOSL2/std.scad>
mypath = [for (a=[0:5:720]) [30*cos(a), 30*sin(a), a/12]];
path_sweep(
    circle(r=3, $fn=16),
    mypath
);
```

This creates a pipe that follows a helical path, similar to a coiled tube.


## Tips

- **Self-intersection**: It is your responsibility to ensure the resulting shape does not self-intersect.  Self-intersecting polyhedra produce cryptic CGAL errors at render time.
- **Point count**: When using `skin()`, profiles with different point counts need a `method` parameter (e.g., `"distance"` or `"reindex"`) to align vertices properly.
- **Slices**: Use the `slices` parameter in `skin()` to add interpolated cross-sections between your profiles for smoother results.
- **Function form**: All these tools can be called as functions to return VNF data, which you can pass to `vnf_polyhedron()` or combine with `vnf_join()`.
