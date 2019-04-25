## Belfry OpenScad Library Documentation

The library files are as follows:

### Commonly Used
  - [`transforms.scad`](transforms.scad): The most commonly used transformations, manipulations, and shortcuts are in this file.
  - [`attachments.scad`](attachments.scad): Modules and functions to enable attachments.
  - [`primitives.scad`](primitives.scad): Attachment aware replacements for square, circle, cube, cylinder, and sphere.
  - [`shapes.scad`](shapes.scad): Common useful shapes and structured objects.
  - [`masks.scad`](masks.scad): Shapes that are useful for masking with `difference()` and `intersect()`.
  - [`threading.scad`](threading.scad): Modules to make triangular and trapezoidal threaded rods and nuts.
  - [`paths.scad`](paths.scad): Functions and modules to work with arbitrary 3D paths.
  - [`beziers.scad`](beziers.scad): Functions and modules to work with bezier curves.

### Standard Parts
  - [`involute_gears.scad`](involute_gears.scad): Modules and functions to make involute gears and racks.
  - [`joiners.scad`](joiners.scad): Modules to make joiner shapes for connecting separately printed objects.
  - [`sliders.scad`](sliders.scad): Modules for creating simple sliders and rails.
  - [`metric_screws.scad`](metric_screws.scad): Functions and modules to make metric screws, nuts, and screwholes.
  - [`linear_bearings.scad`](linear_bearings.scad): Modules to make mounts for LMxUU style linear bearings.
  - [`nema_steppers.scad`](nema_steppers.scad): Modules to make mounting holes for NEMA motors.
  - [`phillips_drive.scad`](phillips_drive.scad): Modules to create Phillips screwdriver tips.
  - [`torx_drive.scad`](torx_drive.scad): Functions and Modules to create Torx bit drive holes.
  - [`wiring.scad`](wiring.scad): Modules to render routed bundles of wires.

### Miscellaneous
  - [`constants.scad`](constants.scad): Useful constants for vectors, edges, etc.
  - [`math.scad`](math.scad): Useful math helper functions.
  - [`arrays.scad`](arrays.scad): Functions to manipulate lists and arrays.
  - [`vectors.scad`](vectors.scad): Functions for vector math.
  - [`matrices.scad`](matrices.scad): Functions for matrix math.
  - [`quaternions.scad`](quaternions.scad): Functions to work with quaternion rotations.
  - [`geometry.scad`](geometry.scad): Functions to help calculate geometry.
  - [`triangulation.scad`](triangulation.scad): Functions to triangulate `polyhedron()` faces that have more than 3 vertices.
  - [`hull.scad`](hull.scad): Functions to create 2D and 3D convex hulls.
  - [`debug.scad`](debug.scad): Modules to help debug creation of beziers, `polygons()`s and `polyhedron()`s

## Terminology
For purposes of these library files, the following terms apply:
- **Left**: Towards X-
- **Right**: Towards X+
- **Front**/**Forward**: Towards Y-
- **Back**/**Behind**: Towards Y+
- **Bottom**/**Down**/**Below**: Towards Z-
- **Top**/**Up**/**Above**: Towards Z+

- **Axis-Positive**: Towards the negative end of the axis the object is oriented on.  IE: X-, Y-, or Z-.
- **Axis-Negative**: Towards the negative end of the axis the object is oriented on.  IE: X-, Y-, or Z-.

## Common Arguments:

Args     | What it is
-------- | ----------------------------------------
rounding | Radius of rounding for interior or exterior edges.
chamfer  | Size of chamfers/bevels for interior or exterior edges.
orient   | Axis a part should be oriented along.  Given as an XYZ triplet of rotation angles.  It is recommended that you use the `ORIENT_` constants from `constants.scad`.  Default is usually `ORIENT_Z` for vertical orientation.
anchor   | Side of the part that is aligned with the origin.  Given as a vector away from the origin.  It is recommended that you use the directional constants from `constants.scad`.  Default is usually `CENTER`.



