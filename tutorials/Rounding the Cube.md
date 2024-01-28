# Rounding the Cube

One of the shape primitives you'll use most often in your OpenSCAD designs is the cube.  Rounding the edges of cube-like objects impacts both the visual appeal and functional aspects of the final design. The BOSL2 library provides a variety of methods for rounding edges and corners.

There are four different 3d shape primitives that you can use to make cube-like objects:

* [**cuboid()**](https://github.com/BelfrySCAD/BOSL2/wiki/shapes3d.scad#module-cuboid) - Creates a cube with chamfering and roundovers. 

* [**cube()**](https://github.com/BelfrySCAD/BOSL2/wiki/shapes3d.scad#functionmodule-cube) -  An extended version of OpenSCAD's [cube()](https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/Primitive_Solids#cube) with anchors for attaching children. (See the [Attachments Tutorial](https://github.com/BelfrySCAD/BOSL2/wiki/Tutorial-Attachments)).

* [**prismoid()**](https://github.com/BelfrySCAD/BOSL2/wiki/shapes3d.scad#functionmodule-prismoid) - Creates a rectangular prismoid shape with optional roundovers and chamfering. 
 
* [**rounded_prism()**](https://github.com/BelfrySCAD/BOSL2/wiki/shapes3d.scad#functionmodule-prismoid) - Makes a rounded 3d object by connecting two polygons with the same vertex count. Rounded_prism supports continuous curvature rounding. (See [Types of Roundovers](https://github.com/BelfrySCAD/BOSL2/wiki/rounding.scad#section-types-of-roundovers)).


BOSL2 provides two different methods for rounding the edges of the cube-like primitives above.

* **Built-in Rounding** - [Cuboid()](https://github.com/BelfrySCAD/BOSL2/wiki/shapes3d.scad#module-cuboid), [prismoid()](https://github.com/BelfrySCAD/BOSL2/wiki/shapes3d.scad#functionmodule-prismoid), and [rounded_prism()](https://github.com/BelfrySCAD/BOSL2/wiki/rounding.scad#functionmodule-rounded_prism) all have built-in arguments for rounding some or all of their edges.

* **Masking** -  BOSL2 includes a number of options for masking the edges and corners of objects. Masking can accomplish rounding tasks that are not possible with the built-in rounding arguments. For example with masking you can have a cube with a different rounding radius on the top edges than the rounding radius on the bottom edges.


## Cuboid Rounding

You can round the edges of a [cuboid()](https://github.com/BelfrySCAD/BOSL2/wiki/shapes3d.scad#module-cuboid) with the `rounding` argument by specifying the radius of curvature:

```openscad-3D
include <BOSL2/std.scad>
cuboid(100, rounding=20);
```


Cube-like objects have six named faces.

![](https://github.com/BelfrySCAD/BOSL2/wiki/images/attachments/subsection-specifying-edges_fig2.png)

You can round just the edges on one of the faces. Here we're rounding only the top edges:

```openscad-3D
include <BOSL2/std.scad>
cuboid([100,80,60], rounding=20, edges = TOP);
```

...or just the bottom edges.  Here we're using the `teardrop` parameter to limit the overhang angle to enable 3d printing on FDM printers without requiring supports:

```openscad-3D
include <BOSL2/std.scad>
cuboid([100,80,60], rounding=20, teardrop = 45, edges = BOTTOM);
```

We can round only the edges aligned with one of the axes, X, Y, or Z:

```openscad-3D
include <BOSL2/std.scad>
cuboid([100,80,60], rounding=20, edges = "Z");
```

If you want to round selected edges you can specify which edges using combinations of the named directions **LEFT, RIGHT, TOP, BOT, FWD, BACK**. See [Specifying Edges](https://github.com/BelfrySCAD/BOSL2/wiki/attachments.scad#subsection-specifying-edges) for more details.

![](https://github.com/BelfrySCAD/BOSL2/wiki/images/attachments/subsection-specifying-edges_fig1.png)


It is possible to round one or more of the edges while leaving others unrounded:

```openscad-3D
include <BOSL2/std.scad>
cuboid([100,80,60], rounding=20, edges = TOP+FRONT);
```

...or exclude the rounding of one or more edges while rounding all the others:

```openscad-3D
include <BOSL2/std.scad>
cuboid([100,80,60], rounding=20, except = TOP+FRONT);
```

You can fillet top or bottom edges by using negative rounding values. Note that you cannot use negative rounding values on Z-aligned (side) edges.  

```openscad-3D
include <BOSL2/std.scad>
cuboid([100,80,60], rounding=-20, edges = BOTTOM);
```

If you do need to add a fillet on a Z-aligned edge, use [fillet()](https://github.com/BelfrySCAD/BOSL2/wiki/shapes3d.scad#module-fillet):

```openscad-3d
include <BOSL2/std.scad>
cuboid([100,80,60], rounding = -10, edges = BOT+FRONT) 
  position(FRONT+RIGHT)
    fillet(l=60, r=10, spin=180);
```

Chamfering the edges of the cuboid() can be done in a manner similar to rounding:

```openscad-3D
include <BOSL2/std.scad>
cuboid([100,80,60], chamfer=20);
```

You can specify edges as with rounding:

```openscad-3D
include <BOSL2/std.scad>
cuboid([100,80,60], chamfer=20, edges = "Z", except = FWD+RIGHT);
```

##Prismoid Rounding

The [prismoid()](https://github.com/BelfrySCAD/BOSL2/wiki/shapes3d.scad#functionmodule-prismoid) differs from the cuboid and cube in that you can only round or chamfer the vertical(ish) edges using the built-in parameters. For those edges, you can specify rounding and/or chamferring for top and bottom separately:

```openscad-3D
include <BOSL2/std.scad>
prismoid(size1=[35,50], size2=[20,30], h=20, rounding1 = 8, rounding2 = 1);
```

You can also specify rounding of the individual vertical(ish) edges on an edge by edge basis by listing the edges in counter-clockwise order starting with the BACK+RIGHT (X+Y+) edge:

```openscad-3D
include <BOSL2/std.scad>
prismoid(100, 80, rounding1=[0,50,0,50], rounding2=[40,0,40,0], h=50);
```


##Masking Edges of the Cuboid, Cube and Prismoid
###2D Edge Masking with [edge_profile()](https://github.com/BelfrySCAD/BOSL2/wiki/attachments.scad#module-edge_profile)

One limitation of using rounding arguments in [cuboid()](https://github.com/BelfrySCAD/BOSL2/wiki/shapes3d.scad#module-cuboid) is that all the rounded edges must have the same rounding radius.  Using masking we have the flexibility to apply different edge treatments to the same cube.  Masking can also be used on the [cube()](https://github.com/BelfrySCAD/BOSL2/wiki/shapes3d.scad#functionmodule-cube) and [prismoid()](https://github.com/BelfrySCAD/BOSL2/wiki/shapes3d.scad#functionmodule-prismoid) shapes.

2D edge masks are attached to edges using [edge_profile()](https://github.com/BelfrySCAD/BOSL2/wiki/attachments.scad#module-edge_profile). They have a default tag of "remove" to enable differencing them away from your cube using [diff()](https://github.com/BelfrySCAD/BOSL2/wiki/attachments.scad#module-diff).

We can use a negative rounding value to fillet the bottom of a cuboid and [edge_profile()](https://github.com/BelfrySCAD/BOSL2/wiki/attachments.scad#module-edge_profile) to round the top.  Here edge_profile() applies a 2d roundover mask to the top edges of the cuboid.

```openscad-3D
include <BOSL2/std.scad>
diff()
    cuboid([50,60,70], rounding = -10, edges = BOT)
        edge_profile(TOP)
            mask2d_roundover(r=10);
```

See [mask2d_roundover()](https://github.com/BelfrySCAD/BOSL2/wiki/masks2d.scad#functionmodule-mask2d_roundover) for additional mask parameters.  Here we use the *inset* parameter in mask2d_roundover:

```openscad-3D
include <BOSL2/std.scad>
diff()
	cube([50,60,70],center=true)
   		edge_profile(TOP, except=[BACK,TOP+LEFT])
       	mask2d_roundover(h=12, inset=4);
```

In addition to the simple roundover mask, there are masks for [cove](https://github.com/BelfrySCAD/BOSL2/wiki/masks2d.scad#functionmodule-mask2d_cove), [chamfer](https://github.com/BelfrySCAD/BOSL2/wiki/masks2d.scad#functionmodule-mask2d_chamfer), [rabbet](https://github.com/BelfrySCAD/BOSL2/wiki/masks2d.scad#functionmodule-mask2d_rabbet), [dovetail](https://github.com/BelfrySCAD/BOSL2/wiki/masks2d.scad#functionmodule-mask2d_dovetail), [teardrop](https://github.com/BelfrySCAD/BOSL2/wiki/masks2d.scad#functionmodule-mask2d_teardrop) and [ogee](https://github.com/BelfrySCAD/BOSL2/wiki/masks2d.scad#functionmodule-mask2d_ogee) edges.  

The mask2d_ogee() only works on [cube()](https://github.com/BelfrySCAD/BOSL2/wiki/shapes3d.scad#functionmodule-cube) and [cuboid()](https://github.com/BelfrySCAD/BOSL2/wiki/shapes3d.scad#module-cuboid) shapes, or a [prismoid()](https://github.com/BelfrySCAD/BOSL2/wiki/shapes3d.scad#functionmodule-prismoid) where size2 >= size1 in both the X and Y dimensions.

```openscad-3d
include <BOSL2/std.scad>
diff()
	prismoid(size1 = [50,50],size2 = [80,80], rounding1 = 25, height = 80)
		edge_profile(TOP)
			mask2d_ogee([
            "xstep",8,  "ystep",5,  // Starting shoulder.
            "fillet",5, "round",5,  // S-curve.
            "ystep",3,  "xstep",3   // Ending shoulder.
        ]);
```

You can use [edge-profile()](https://github.com/BelfrySCAD/BOSL2/wiki/attachments.scad#module-edge_profile) to round the top or bottom of a [prismoid()](https://github.com/BelfrySCAD/BOSL2/wiki/shapes3d.scad#functionmodule-prismoid).  Because the side faces of a [prismoid()](https://github.com/BelfrySCAD/BOSL2/wiki/shapes3d.scad#functionmodule-prismoid) are not strictly vertical, it's is necessary to increase the length of the masks using the *excess* parameter in [edge_profile()](https://github.com/BelfrySCAD/BOSL2/wiki/attachments.scad#module-edge_profile), and to set the mask\_angle to $edge\_angle in [mask2d\_roundover()](https://github.com/BelfrySCAD/BOSL2/wiki/masks2d.scad#functionmodule-mask2d_roundover).

```openscad-3D
include<BOSL2/std.scad>
diff()
	prismoid(size1=[35,50], size2=[30,30], h=20, rounding1 = 8, rounding2 = 0)
   		edge_profile([TOP+LEFT, TOP+RIGHT], excess = 5)
       	mask2d_roundover(r = 15, mask_angle = $edge_angle);
```

###3D Edge and Corner Masking

BOSL2 contains a number of 3d edge and corner masks in addition to the 2d edge profiles shown above.

The 3d edge masks have the advantage of being able to vary the rounding radius along the edge.  3d edge masks, such as[ rounding\_edge_mask()](https://github.com/BelfrySCAD/BOSL2/wiki/masks3d.scad#module-rounding_edge_mask), can be attached using [edge_mask()](https://github.com/BelfrySCAD/BOSL2/wiki/attachments.scad#module-edge_mask). The 3D edge masks have a default tag of "remove" to enable differencing them away from your cube using [diff()](https://github.com/BelfrySCAD/BOSL2/wiki/attachments.scad#module-diff).


```openscad-3D
include <BOSL2/std.scad>
diff()
	cuboid(80)
		edge_mask(TOP+FWD)
			rounding_edge_mask(r1 = 40, r2 = 0, l = 80);
```

While you can specify the length of the mask with the l argument, [edge_mask()](https://github.com/BelfrySCAD/BOSL2/wiki/attachments.scad#module-edge_mask) sets a special variable, `$parent_size`, to the size of the parent object.  In either case the parent is not a perfect cube, you need to mask each edge individually:

```openscad-3D
include <BOSL2/std.scad>
diff()
	cuboid([60,80,40])  {
		edge_mask(TOP+FWD)
			rounding_edge_mask(r = 10, l = $parent_size.x + 0.1);
		edge_mask(TOP+RIGHT)
			rounding_edge_mask(r = 10, l = $parent_size.y + 0.1);
		edge_mask(RIGHT+FWD)
			rounding_edge_mask(r = 10, l = $parent_size.z + 0.1);
	}	
```

As you can see above, using only [rounding\_edge_mask()](https://github.com/BelfrySCAD/BOSL2/wiki/masks3d.scad#module-rounding_edge_mask) to round the top of the cube leaves the corners unrounded.  Use [corner_mask()](https://github.com/BelfrySCAD/BOSL2/wiki/attachments.scad#module-corner_mask) and [rounding\_corner_mask()](https://github.com/BelfrySCAD/BOSL2/wiki/masks3d.scad#module-rounding_corner_mask) for a smoother corner.

```openscad-3D
include <BOSL2/std.scad>
diff()
	cuboid([60,80,40]) {
		edge_mask(TOP+FWD)
			rounding_edge_mask(r = 10, l = $parent_size.x + 0.1);
		edge_mask(TOP+RIGHT)
			rounding_edge_mask(r = 10, l = $parent_size.y + 0.1);
		edge_mask(RIGHT+FWD)
			rounding_edge_mask(r = 10, l = $parent_size.z + 0.1);
        corner_mask(TOP+RIGHT+FWD)
            rounding_corner_mask(r = 10);
	}
	
```

As with the built-in rounding arguments, you can use [edge\_mask()](https://github.com/BelfrySCAD/BOSL2/wiki/attachments.scad#module-edge_mask) and [corner\_mask()](https://github.com/BelfrySCAD/BOSL2/wiki/attachments.scad#module-corner_mask) to apply teardrop roundings using [teardrop\_edge_mask()](https://github.com/BelfrySCAD/BOSL2/wiki/masks3d.scad#module-teardrop_edge_mask) and [teardrop\_corner_mask()](https://github.com/BelfrySCAD/BOSL2/wiki/masks3d.scad#module-teardrop_corner_mask) to limit the overhang angle for better printing on FDM printers. Note that the vertical mask on the RIGHT_FWD edge is a rounding\_edge\_mask().

```openscad-3D
include <BOSL2/std.scad>
diff()
	cuboid([60,80,40]) {
		edge_mask(BOT+FWD)
			teardrop_edge_mask(r = 10, l = $parent_size.x + 0.1, angle = 40);
		edge_mask(BOT+RIGHT)
			teardrop_edge_mask(r = 10, l = $parent_size.y + 0.1, angle = 40);
		edge_mask(RIGHT+FWD)
			rounding_edge_mask(r = 10, l = $parent_size.z + 0.1);
        corner_mask(BOT+RIGHT+FWD)
            teardrop_corner_mask(r = 10, angle = 40);
	}
	
```
##Rounded Prism
You can construct cube-like objects, as well as a variety of other prisms using [rounded_prism()](https://github.com/BelfrySCAD/BOSL2/wiki/rounding.scad#functionmodule-rounded_prism).  The unique feature of [rounded_prism()](https://github.com/BelfrySCAD/BOSL2/wiki/rounding.scad#functionmodule-rounded_prism) is the ability to use continuous curvature rounding. Rather than using constant radius arcs, continuous curvature rounding uses 4th order Bezier curves. For complete details on how this works see [Types of Roundovers](https://github.com/BelfrySCAD/BOSL2/wiki/rounding.scad#section-types-of-roundovers).

Two parameters control the roundover k and joint.  The joint parameter is specified separately for the top, bottom and side edges; joint\_top, joint\_bot, and joint_sides.

The k parameter ranges from 0 to 1 with a default of 0.5. Larger values give a more abrupt transition and smaller ones a more gradual transition. A k value of .93 approximates the circular roundover of other rounding methods.

 If you want a very smooth roundover, set the joint parameter as large as possible and then adjust the k value down as low as gives a sufficiently large roundover.


```openscad-3D
include <BOSL2/std.scad>
include <BOSL2/rounding.scad>
rounded_prism(rect(20), height=20, 
    joint_top=10, joint_bot=10, joint_sides=9.99, k = 0.5);
```

A large joint value and a very small k value:

```openscad-3D
include <BOSL2/std.scad>
include <BOSL2/rounding.scad>
rounded_prism(rect(20), height=20, 
    joint_top=10, joint_bot=10, joint_sides=9.99, k = 0.01);
```

A k value of 0.3

```openscad-3D
include <BOSL2/std.scad>
include <BOSL2/rounding.scad>
rounded_prism(rect(20), height=20, 
    joint_top=10, joint_bot=10, joint_sides=9.99, k = 0.3);  
```

A k value of 1:

```openscad-3d
include <BOSL2/std.scad>
include <BOSL2/rounding.scad>
rounded_prism(rect(20), height=20, 
    joint_top=10, joint_bot=10, joint_sides=9.99, k = 1);
```

A k value of 0.93 approximates the circular roundover of other rounding methods:

```openscad-3D
include <BOSL2/std.scad>
include <BOSL2/rounding.scad>
rounded_prism(rect(20), height=20, 
    joint_top=4, joint_bot=4, joint_sides=4, k = 0.93);
right(30)  
cuboid(20, rounding = 4, $fn = 72);
```
