# Attachments Overview

BOSL2 introduces the concept of "attachables."  You can do the following
things with attachable shapes:

* Control where the shape appears and how it is oriented by anchoring and specifying orientation and spin
* Position or attach shapes relative to parent objects
* Tag objects and then control boolean operations based on their tags.
* Change the color of objects so that child objects are different colors than their parents

The various attachment features may seem complex at first, but 
attachability is one of the most important features of the BOSL2
library.  It enables you to position objects relative to other objects
in your model instead of having to keep track of absolute positions.
It makes models simpler, more intuitive, and easier to maintain.

Almost all objects defined by BOSL2 are attachable.  In addition,
BOSL2 overrides the built-in definitions for `cube()`, `cylinder()`,
`sphere()`, `square()`, `circle()` and `text()` and makes them attachable as
well.  However, some basic OpenSCAD built-in definitions are not
attachable and will not work with the features described in this
tutorial.  The non-attachables are `polyhedron()`, `linear_extrude()`,
`rotate_extrude()`, `surface()`, `projection()` and `polygon()`.
Some of these have attachable alternatives: `vnf_polyhedron()`,
`linear_sweep()`, `rotate_sweep()`, and `region()`.  

[Next: Basic Positioning](Tutorial-Attachment-Basic-Positioning)


