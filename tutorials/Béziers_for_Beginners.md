# Béziers for Beginners

Bézier curves are parametric curves defined by a set of control points. These points’ positions in relation to one another define the shape of the curve. In OpenSCAD these points are contained in a list. The simplest cubic Bézier curve has 4 control points. The first and last control points are the endpoints of the curve, but the other two control points do not lie on the curve itself.

To work with Béziers in OpenSCAD we need to load the Bézier extension BOSL2/beziers.scad in addition to BOSL2/std.scad.
 
To visualize a Bézier curve we can use the module debug_bezier().

```openscad2d
include<BOSL2/std.scad>
include<BOSL2/beziers.scad>

bez = [[20,0], [40,10], [0,40], [20,60]];
debug_bezier(bez);
```

