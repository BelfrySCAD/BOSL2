# BOSL
The Belfry OpenScad Library - A library of tools, shapes, and helpers to make OpenScad easier to use.

This library is a set of useful tools, shapes and manipulators that I developed while working on various
projects, including large ones like the Snappy-Reprap printed 3D printer.

# Overview
The library files are as follows:
  - ```transforms.scad```: The most commonly used transformations, manipulations, and shortcuts are in this file.
  - ```shapes.scad```: Common useful shapes and structured objects.
  - ```masks.scad```: Shapes that are useful for masking with ```difference()``` and ```intersect()```.
  - ```paths.scad```: Functions and modules to work with arbitrary 3D paths.
  - ```bezier.scad```: Functions and modules to work with bezier curves.
  - ```involute_gears.scad```: Modules and functions to make involute gears and racks.
  - ```metric_screws.scad```: Functions and modules to make holes for metric screws and nuts.
  - ```joiners.scad```: Modules to make joiner shapes for connecting separately printed objects.
  - ```sliders.scad```: Modules for creating simple sliders and rails.
  - ```acme_screws.scad```: Modules to make trapezoidal (ACME) threaded rods and nuts.
  - ```nema_steppers.scad```: Modules to make mounting holes for NEMA motors.
  - ```linear_bearings.scad```: Modules to make mounts for LMxUU style linear bearings.
  - ```wiring.scad```: Modules to render routed bundles of wires.
  - ```math.scad```: Useful helper functions and constants.
  - ```quaternions.scad```: Functions to work with quaternion rotations.

## transforms.scad
The most commonly useful of the library files is ```transforms.scad```.  It provides features such as:
  - ```up()```, ```down()```, ```left()```, ```right()```, ```fwd()```, ```back()``` as more readable alternatives to ```translate()```.
  - ```xrot()```, ```yrot()```, ```zrot()``` as single-axis alternatives to ```rotate```.
  - ```xspread()```, ```yspread()```, and ```zspread()``` to evenly space copies of an item along an axis.
  - ```xring()```, ```yring()```, ```zring()``` to evenly space copies of an item around a circle.
  - ```skewxy()``` that let you skew objects without using a ```multmatrix()```.
  - Easy mirroring with ```xflip()```, ```xflip_copy()```, etc.
  - Slice items in half with ```top_half()```, ```left_half()```, ```back_half()```, etc.

## shapes.scad
The ```shapes.scad``` library file provides useful compound shapes, such as:
  - ```upcube()``` a ridiculously useful version of ```cube()``` that is centered on top of the XY plane.
  - Filleted (rounded) and Chamferred (bevelled) cubes and cylinders.
  - ```pyramid()```, ```prism()```, and ```trapezoid()```
  - ```right_triangle()```
  - ```teardrop()``` and ```onion()``` for making more 3D printable holes.
  - ```tube()``` and ```torus()``` for donut shapes.
  - ```slot()``` and ```arced_slot()``` for making things like screw slots.
  - ```thinning_wall()``` makes a vertical wall which thins in the middle, to reduce print volume.
  - ```thinning_triangle()``` makes a right triangle which thins in the middle, to reduce print volume.
  - ```sparse_strut()``` makes a cross-braced open strut wall, optimized for support-less 3D printing.
  - ```corrugated_wall()``` makes a corrugated wall to reduce print volume while keeping strength.

## masks.scad
The ```masks.scad``` library file provides mask shapes like:
  - ```angle_pie_mask()``` to mask a pie-slice shape.
  - ```chamfer_mask_x()```, ```chamfer_mask_y()```, and ```chamfer_mask_z()``` to chamfer (bevel) an axis aligned 90 degree edge.
  - ```fillet_mask_x()```, ```fillet_mask_y()```, and ```fillet_mask_z()``` to fillet (round) an axis aligned 90 degree edge.
  - ```fillet_corner_mask()``` to fillet a 90 degree corner.
  - ```fillet_angled_edge_mask()``` to fillet an acute or obtuse vertical edge.
  - ```fillet_angled_corner_mask()``` to fillet the corner of two acute or obtuse planes.
  - ```fillet_cylinder_mask()``` to fillet the end of a cylinder.
  - ```fillet_hole_mask()``` to fillet the edge of a cylindrical hole.
  