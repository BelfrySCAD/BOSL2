# BOSL
The Belfry OpenScad Library - A library of tools, shapes, and helpers to make OpenScad easier to use.

This library is a set of useful tools, shapes and manipulators that I developed while working on various
projects, including large ones like the Snappy-Reprap printed 3D printer.

# Overview

The most commonly useful of the library files is ```transforms.scad```.  It provides features such as:
  - ```up()```, ```down()```, ```left()```, ```right()```, ```fwd()```, ```back()``` as more readable alternatives to ```translate()```.
  - ```xrot()```, ```yrot()```, ```zrot()``` as single-axis alternatives to ```rotate```.
  - ```xspread()```, ```yspread()```, and ```zspread()``` to evenly space copies of an item along an axis.
  - ```xring()```, ```yring()```, ```zring()``` to evenly space copies of an item around a circle.
  - ```skewxy()``` that let you skew objects without using a ```multmatrix()```.
  - Easy mirroring with ```xflip()```, ```xflip_copy()```, etc.
  - Slice items in half with ```top_half()```, ```left_half()```, ```back_half()```, etc.

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
