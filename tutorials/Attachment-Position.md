[Previous: Relative Positioning of Children](Tutorial-Attachment-Relative-Positioning)

# Placing Children using position()

If you make an object a child of another object then the child object
is positioned relative to the parent.  By default, the child's anchor
point will be positioned at the center of the parent.  This tutorial
describes the `postion()` module, which places the child so its anchor
point is positioned at a chosen anchor point on the parent.  

## An Object as a Child of Another Object

When you make an object the child of another object the anchor point
of the child object is positioned at the center of the parent object.  
The default anchor for `cyl()` is CENTER, so in this case, the cylinder is centered on the cube's center

```openscad-3D
include <BOSL2/std.scad>
up(13) cube(50)
    cyl(d=25,l=95);
```

With `cylinder()` the default anchor is BOTTOM.  It's hard to tell,
but the cylinder's bottom is placed at the center of the cube.  

```openscad-3D
include <BOSL2/std.scad>
cube(50)
    cylinder(d=25,h=75);
```

If you explicitly anchor the child object then the anchor you choose will be aligned
with the center point of the parent object.  In this example the right
side of the cylinder is aligned with the center of the cube.  


```openscad-3D
include <BOSL2/std.scad>
cube(50,anchor=FRONT)     
    cylinder(d=25,h=95,anchor=RIGHT);
```

## Using position() 

The `position()` module enables you to specify where on the parent to
position the child object.  You give `position()` an anchor point on
the parent, and the child's anchor point is aligned with the specified
parent anchor point.  In this example the LEFT anchor of the cylinder is positioned on the
RIGHT anchor of the cube.  

```openscad-3D
include <BOSL2/std.scad>
cube(50,anchor=FRONT)     
    position(RIGHT) cylinder(d=25,h=75,anchor=LEFT);
```

Using this mechanism you can position objects relative to other
objects which are in turn positioned relative to other objects without
having to keep track of the transformation math.

```openscad-3D
include <BOSL2/std.scad>
cube([50,50,30],center=true)
    position(TOP+RIGHT) cube([25,40,10], anchor=RIGHT+BOT)
       position(LEFT+FRONT+TOP) cube([12,12,8], anchor=LEFT+FRONT+BOT)
         cylinder(h=10,r=3);
```

The positioning mechanism is not magical: it simply applies a
`translate()` operation to the child.  You can still apply your own
additional translations or other transformations if you wish.  For
example, you can position an object 5 units from the right edge:

```openscad-3D
include<BOSL2/std.scad>
cube([50,50,20],center=true)
    position(TOP+RIGHT) left(5) cube([4,50,10], anchor=RIGHT+BOT);
```

If you want to position two objects on a single parent you can
provide them as two children.  The two children area created
separately from each other according to whatever `position()`
parameters you specify:

```openscad-3D
include<BOSL2/std.scad>
cuboid([50,50,20]){
    position(RIGHT) cube([12,12,5], anchor=LEFT);
    position(BACK+TOP) cyl(r=12,h=5, anchor=BOT);
}
```

If for some reason you want to create multiple objects at the same position you can
list them under a single position statement:

```openscad-3D
include<BOSL2/std.scad>
cuboid([25,25,20])
  color("lightblue")
    position(RIGHT+FWD+TOP) {
       cube([5,10,5],anchor=TOP+LEFT+FWD);
       cube([10,5,5],anchor=TOP+BACK+RIGHT);
    }
```

If you want multiple **identical** children located at different
positions you can pass a list of anchor locations to `position()`:

```openscad-3D
include<BOSL2/std.scad>
cuboid([50,50,20])
  color("lightblue")
    position([RIGHT+TOP,LEFT+TOP])
       cube(12,anchor=BOT);
```

Note that for this to work, the anchors need to be the same for each
child.  It would not be possible, for example, to change the above
example so that the blue cubes are aligned flush with the sides of the
parent cube, because that requires a different anchor for each blue
cube.  

Positioning objects works the same way in 2D.

```openscad-2D
include<BOSL2/std.scad>
square(10)
    position(RIGHT) square(3,anchor=LEFT);
```

## Using position() with orient()

When positioning an object near an edge or corner you may wish to
orient the object relative to some face other than the TOP face that
meets at that edge or corner.  You can always apply `rot()` to 
change the orientation of the child object, but in order to do this,
you need to figure out the correct rotation.  The `orient()` module provides a
mechanism for re-orienting the child() that eases this burden: 
it can orient the child relative to the parent anchor directions.  This is different
than giving an `orient=` argument to the child, because that orients
relative to the parent's global coordinate system by just using the vector
directly, instead of orienting to the parent's anchor, which takes
account of face orientation.  A series of three
examples shows the different results.  In the first example, we use
only `position()`.  The child cube is erected pointing upwards, in the
Z direction.  In the second example we use `orient=RIGHT` in the child
and the result is that the child object points in the X+ direction,
without regard for the shape of the parent object.  In the final
example we apply `orient(RIGHT)` and the child is oriented
relative to the slanted right face of the parent using the parent
RIGHT anchor.   

```openscad-3D
include<BOSL2/std.scad>
prismoid([50,50],[30,30],h=40)
  position(RIGHT+TOP)
     cube([15,15,25],anchor=RIGHT+BOT);
```


```openscad-3D
include<BOSL2/std.scad>
prismoid([50,50],[30,30],h=40)
  position(RIGHT+TOP)
     cube([15,15,25],orient=RIGHT,anchor=LEFT+BOT);
```


```openscad-3D
include<BOSL2/std.scad>
prismoid([50,50],[30,30],h=40)
  position(RIGHT+TOP)
     orient(RIGHT)
        cube([15,15,25],anchor=BACK+BOT);
```

You may have noticed that the children in the above three examples
have different anchors.  Why is that?  The first and second examples
differ because anchoring up and anchoring to the right require
anchoring on opposite sides of the child.  But the third case differs
because the spin has changed.  The examples below show the same models
but with arrows replacing the child cube.  The red flags on the arrows
mark the zero spin direction.  Examine the red flags to see how the spin
changes.  The Y+ direction of the child will point towards that red
flag.  

```openscad-3D
include<BOSL2/std.scad>
prismoid([50,50],[30,30],h=40)
  position(RIGHT+TOP)
     anchor_arrow(40);
```

```openscad-3D
include<BOSL2/std.scad>
prismoid([50,50],[30,30],h=40)
  position(RIGHT+TOP)
     anchor_arrow(40, orient=RIGHT);
```

```openscad-3D
include<BOSL2/std.scad>
prismoid([50,50],[30,30],h=40)
  position(RIGHT+TOP)
     orient(RIGHT)
        anchor_arrow(40);
```

[Next: Using align()](Tutorial-Attachment-Align)
