[Prev: Using align()](Tutorial-Attachment-Align)

# Attachment using attach()

The `attach()` module can stick the child object to the parent object
by matching a designated face on the child to a specified face on the
parent.  Unlike `position()` and `align()`, the `attach()` module may
change the orientation and spin of the child.

## The Parent Coordinate System

When you attach a child object, it appears on the parent relative to
the local coordinate system of the parent at the anchor. 
To understand what this means, imagine the perspective of an ant walking on a
sphere.  The meaning of UP varies depending on where on the sphere the
ant is standing.  If you **attach** a cylinder to the sphere then the cylinder will
be "up" from the ant's perspective.   The first example shows a
cylinder placed with `position()` so it points up in the global parent
coordinate system.  The second example shows how `attach()` points the
cylinder UP from the perspective of an ant standing at the anchor
point on the sphere.  

```openscad-3D
include<BOSL2/std.scad>
sphere(40)
    position(RIGHT+TOP) cylinder(r=8,h=20);
```


```openscad-3D
include<BOSL2/std.scad>
sphere(40)
    attach(RIGHT+TOP) cylinder(r=8,h=20);
```

In the example above, the cylinder's center point is attached to the
sphere, pointing "up" from the perspective of the sphere's surface.
For a sphere, a surface normal is defined everywhere that specifies
what "up" means.  But for other objects, it may not be so obvious.
Usually at edges and corners the direction is the average of the
direction of the faces that meet there.

It's obvious to the ant which direction is UP, and hence corresponds
to the Z axis, on the surface of the sphere she inhabits.  But in
order to define the ant's local coordinate system we also need to
decide where the X and Y directions are.  This is obvious an arbitrary
choice.  In BOSL2 this is called the "spin" direction for the anchor.  

When you specify an anchor for use with attachment you are actually
specifying both an anchor position but also an anchor direction (the Z
axis) and the anchor's spin so that you fully define the parent
coordinate systemer and a spin.  If you want to visualize this
direction you can use anchor arrows.


## Anchor Directions and Anchor Arrows

For the ant on the sphere it is obvious which direction is UP; that
direction corresponds to the Z+ axis.  The location of the X and Y
axes is less clear and in fact it may be arbitrary.  One way that is
useful to show the position and orientation of an anchor point is by
attaching an anchor arrow to that anchor.  As noted before, the small
red flag points in the direction of the anchor's Y+ axis when the spin
is zero.

```openscad-3D
include <BOSL2/std.scad>
cube(18, center=true)
    attach(LEFT+TOP)
        anchor_arrow();
```

For large objects, you can change the size of the arrow with the `s=` argument.

```openscad-3D
include <BOSL2/std.scad>
sphere(d=100)
    attach(LEFT+TOP)
        anchor_arrow(s=50);
```

To show all the standard cardinal anchor points, you can use the [show_anchors()](https://github.com/BelfrySCAD/BOSL2/wiki/attachments.scad#module-show_anchors) module.

```openscad-3D;Big
include <BOSL2/std.scad>
cube(20, center=true)
    show_anchors();
```

```openscad-3D;Big
include <BOSL2/std.scad>
cylinder(h=25, d=25, center=true)
    show_anchors();
```

```openscad-3D;Big
include <BOSL2/std.scad>
sphere(d=40)
    show_anchors();
```

For large objects, you can again change the size of the arrows with the `s=` argument.

```openscad-3D;Big
include <BOSL2/std.scad>
prismoid(150,60,100)
    show_anchors(s=45);
```


## Parent-Child Anchor Attachment (Double Argument Attachment)

The `attach()` module has two different modes of operation,
parent-child anchor attachment and parent anchor attachment.  These
are also called double argument attachment and single argument
attachment.  The parent-child anchor attachment, with two arguments,
is usually easier to use and is more powerful because it supports
alignment.  When just starting out with attachment, we recommend that
you focus on this form of attachment.  

When you use parent-child anchor attachment you give a
parent anchor and a child anchor.  Imagine pointing the anchor arrows
on the two objects directly at each other and pushing them together in
the direction of the arrows until they touch.  In many of the examples
below we show first the two objects with their anchor arrows and then
the result of the attach operation using those anchors.

```openscad-3D
include <BOSL2/std.scad>
cube(50,anchor=BOT) attach(TOP,BOT) anchor_arrow(30);
right(60)cylinder(d1=30,d2=15,h=25) attach(BOT,BOT) anchor_arrow(30);
```

```openscad-3D
include <BOSL2/std.scad>
cube(50,anchor=BOT)
  attach(TOP,BOT) cylinder(d1=30,d2=15,h=25);
```

This example produces the same result as using `align()`, but if the
parent anchor is not horizontal, then the child is reoriented:

```openscad-3D
include <BOSL2/std.scad>
prismoid([50,50],[35,35],h=50,anchor=BOT) attach(RIGHT,BOT) anchor_arrow(30);
right(60)cylinder(d1=30,d2=15,h=25) attach(BOT,BOT) anchor_arrow(30);
```

```openscad-3D
include <BOSL2/std.scad>
prismoid([50,50],[35,35],h=50,anchor=BOT)
  attach(RIGHT,BOT) cylinder(d1=30,d2=15,h=25);
```

In this case we attach the curved side of the cone to a cube by lining
up the anchor arrows:

```openscad-3D
include <BOSL2/std.scad>
cube(50,center=true) attach(RIGHT,BOT) anchor_arrow(30);
right(80)cylinder(d1=30,d2=15,h=25) attach(LEFT,BOT) anchor_arrow(30);
```

```openscad-3D
include <BOSL2/std.scad>
cube(50,center=true)
  attach(RIGHT,LEFT) cylinder(d1=30,d2=15,h=25);
```

Note that this form of attachent overrides any anchor or orientation
specified in the child: **with parent-child anchor attachment the
`anchor=` and `orient=` parameters to the child are ignored.**

When you specify attachment using a pair of anchors, the attached
child can spin around the parent anchor while still being attached at
the designated anchors: specifying the anchors leaves one unspecified
degree of freedom.  As noted earlier, this ambiguity is resolved by anchors having a
defined spin which specifies where the Y+ axis is located.
The way that BOSL2 positions objects can be understood by viewing the
anchor arrows as shown above, or you can remember these rules:
1. When attaching to the TOP or BOTTOM: the FRONT of the child points to the front if possible;  otherwise the TOP of the child points BACK.
2. When attaching to other faces, if possible the child's UP anchor will point UP; otherwise, the BACK of the child points up (so the FRONT is pointed down).  

To show how this works we use this prismoid where the blue arrow is
pointing to the front and the green arrow points up.  Also note that
the front left edge is the only right angle.  

```openscad-3D
include <BOSL2/std.scad>
color_this("orange")
prismoid([8,8],[6,6],shift=-[1,1],h=8) {
     attach(TOP,BOT) anchor_arrow(color=[0,1,0],s=12);
     attach(FWD,BOT) anchor_arrow(s=12);     
}
```

If we attach this to the TOP by the LEFT side then we get the result
below.  Notice how the green UP arrow is pointing back.

```openscad-3D
include <BOSL2/std.scad>
cube(30) attach(TOP,LEFT)
color_this("orange")
  prismoid([8,8],[6,6],shift=-[1,1],h=8) {
    attach(TOP,BOT) anchor_arrow(color=[0,1,0],s=12);
    attach(FWD,BOT) anchor_arrow(s=12);     
  }
```

If we attach to the RIGHT using the same LEFT side anchor on the
prismoid then we get the result below.  Note that the green UP anchor
is pointing UP, in accordance with rule 2 from above.  

```openscad-3D
include <BOSL2/std.scad>
cube(30) attach(RIGHT,LEFT)
color_this("orange")
  prismoid([8,8],[6,6],shift=-[1,1],h=8) {
    attach(TOP,BOT) anchor_arrow(color=[0,1,0],s=12);
    attach(FWD,BOT) anchor_arrow(s=12);     
  }
```

The green UP arrow can always be arranged to point up unless we attach
either the top or bottom to one of the cube's vertical faces.  Here we
attach the bottom so you can still see both arrows.  The blue FRONT
arrow on the object is pointing down, as expected based on rule 2.  

```openscad-3D
include <BOSL2/std.scad>
cube(30) attach(RIGHT,BOT)
color_this("orange")
  prismoid([8,8],[6,6],shift=-[1,1],h=8) {
    attach(TOP,BOT) anchor_arrow(color=[0,1,0],s=12);
    attach(FWD,BOT) anchor_arrow(s=12);     
  }
```

What do you do if the direction the child appears is not the direction
you need?  To address this issue `attach()` provides a `spin=`
parameter which spins the attached child around the axis defined by
the joined anchor vectors.  Here is the last example with a rotation
applied to bring the front anchor back to the front:

```openscad-3D
include <BOSL2/std.scad>
cube(30) attach(RIGHT,BOT,spin=-90)
color_this("orange")
  prismoid([8,8],[6,6],shift=-[1,1],h=8) {
    attach(TOP,BOT) anchor_arrow(color=[0,1,0],s=12);
    attach(FWD,BOT) anchor_arrow(s=12);     
  }
```

Be aware that specifying `spin=` to `attach()` is not equivalent to
using the `spin=` argument to the child.  Unlike `orient=` and
`anchor=`, which are ignored, the child `spin=` argument is still
respected, but it may be difficult to figure out which axis it will
rotate on.  It is more intuitive to ignore the child spin parameter
and only use the spin parameter to `attach()`.  The spin must be
scalar but need not be a multiple of 90 degrees.

```openscad-3D
include <BOSL2/std.scad>
cube(30) attach(RIGHT,BOT,spin=-37)
color_this("orange")
  prismoid([8,8],[6,6],shift=-[1,1],h=8) {
    attach(TOP,BOT) anchor_arrow(color=[0,1,0],s=12);
    attach(FWD,BOT) anchor_arrow(s=12);     
  }
```

By default, `attach()` places the child exactly flush with the surface
of the parent.  Sometimes it's useful to have the child overlap the
parent by translating it into the parent.  You can do this with the
`overlap=` argument to `attach()`.  A positive value will cause the
child to overlap the parent, and a negative value will move the child
away from the parent, leaving a small gap.  In the first example we use a very large value of
overlap so the cube is sunk deeply into the parent.  In the second
example a large negative overlap value raises the child high above the
parent.  

```openscad-3D
include <BOSL2/std.scad>
cuboid(50)
    attach(TOP,BOT,overlap=15)
        color("green")cuboid(20);
```

```openscad-3D
include <BOSL2/std.scad>
cube(50,center=true)
    attach(TOP,BOT,overlap=-20)
        cyl(d=20,h=20);
```

Another feature provided by the double argument form of `attach()` is
alignment, which works in a similar way to `align()`.  You can specify
`align=` to align the attached child to an edge or corner.  The
example below shows five different alignments.  

```openscad-3D;Big
include <BOSL2/std.scad>
module thing(){
  color_this("orange")
    prismoid([8,8],[6,6],shift=-[1,1],h=8) {
      attach(TOP,BOT) anchor_arrow(color=[0,1,0],s=12);
      attach(FWD,BOT) anchor_arrow(s=12);     
    }
}
prismoid([50,50],[35,35],h=25,anchor=BOT){
  attach(TOP,BOT,align=FRONT) thing();
  attach(RIGHT,BOT,align=BOT) thing();    
  attach(RIGHT,BACK,align=FRONT) thing();
  attach(FRONT,BACK,align=BOT,spin=45) thing();
  attach(TOP,RIGHT,align=RIGHT,spin=90) thing();
}
```

As with `align()` if you turn an object 90 degrees it can match up
with parallel edges, but if you turn it an arbitrary angle, a corner
of the child will contact the edge of the parent.  Also like align()
the anchor points of the parent and child are aligned but this does
not necessarily mean that edges line up neatly when the shapes have
varying angles.  This misalignment is visible in the object attached
at the RIGHT and aligned to the FRONT.

You may be wondering why all this fuss with align is necessary.
Couldn't you just attach an object at an anchor on an edge?  When you
do this, the object will be attached using the edge anchor, which is
not perpendicular to the faces of the object.  The example below shows
attachment to an edge anchor and also a corner anchor.  

```openscad-3D
include <BOSL2/std.scad>
cube(30)
   color("orange"){
     attach(RIGHT+FRONT,BOT) 
        prismoid([8,8],[6,6],shift=-[1,1],h=8);
     attach(TOP+LEFT+FWD,BOT)
        prismoid([8,8],[6,6],shift=-[1,1],h=8);
   }
```

When using the `align` option to `attach()` you can also set `inset`,
which works the same way as the `inset` parameter to `align()`.  It
shifts the child away from the edge or edges where it is aligned by
the specified amount.  

```openscad-3D
include <BOSL2/std.scad>
prismoid([50,50],[50,25],25){
  attach(FWD,BOT,align=TOP,inset=3) color("lavender")cuboid(5);
  attach(FWD,BOT,align=BOT+RIGHT,inset=3) color("purple")cuboid(5);
}
```

The last capability provided by `attach()` is to attach the child
**inside** the parent object.  This is useful if you want to subtract
the child from the parent.  Doing this requires using tagged
operations with `diff()` which is explained in more detail below. 
For the examples here, note that the `diff()` and `tag()` operations
that appear cause the child to be subtracted.  We return to the
example that started this section, with anchor arrows shown on the two
objects.  

```openscad-3D
include <BOSL2/std.scad>
cube(50,anchor=BOT) attach(TOP) anchor_arrow(30);
right(60)cylinder(d1=30,d2=15,h=25) attach(TOP) anchor_arrow(30);
```

Inside attachment is activated using `inside=true` and it lines up the
anchor arrows so they point together the **same** direction instead of
opposite directions like regular outside attachment.  The result in
this case is appears below, where we have cut away the front half to
show the interior: 

```openscad-3D
include <BOSL2/std.scad>
back_half(s=200)
diff()
cube(50,anchor=BOT)
  attach(TOP,TOP,inside=true)
    cylinder(d1=30,d2=15,h=25);
```

The top of the cavity has a thin layer on it, which occurs because the
two objects share a face in the difference.  To fix this you can use
the `shiftout` parameter to `attach()`.  In this case you could also
use a negative `overlay` value, but the `shiftout` parameter shifts
out in every direction that is needed, which may be three directions
if you align the child at a corner.  The above example looks like this
with with the shift added:

```openscad-3D
include <BOSL2/std.scad>
back_half(s=200)
diff()
cube(50,anchor=BOT)
  attach(TOP,TOP,inside=true,shiftout=0.01)
    cylinder(d1=30,d2=15,h=25);
```

Here is an example of connecting the same object on the right, but
this time with the BOTTOM anchor.  Note how the BOTTOM anchor is
aligned to the RIGHT so it is parallel and pointing in the same
direction as the RIGHT anchor.  

```openscad-3D
include <BOSL2/std.scad>
back_half(s=200)
diff()
cuboid(50)
  attach(RIGHT,BOT,inside=true,shiftout=0.01)
    cylinder(d1=30,d2=15,h=25);
```

Here is an example where alignment moves the object into the corner,
and we benefit from shiftout providing 3 dimensions of adjustment:

```openscad-3D
include <BOSL2/std.scad>
diff()
cuboid(10)
  attach(TOP,TOP,align=RIGHT+FWD,inside=true,shiftout=.01)
    cuboid([2,5,9]);
```

As with `position()`, with any use of `attach()` you can still apply your own translations and
other transformations even after attaching an object.  However, the
order of operations now matters.  If you apply a translation outside
of the anchor then it acts in the parent's global coordinate system, so the
child moves up in this example, where the light gray shows the
untranslated object.  

```openscad-3D
include <BOSL2/std.scad>
cuboid(50){
  %attach(RIGHT,BOT)
    cyl(d1=30,d2=15,h=25);
  up(13)
    color("green") attach(RIGHT,BOT)
      cyl(d1=30,d2=15,h=25);
}
```

On the other hand, if you put the translation between the attach and
the object in your code, then it will act in the local coordinate system of
the parent at the parent's anchor, so in the example below it moves to the right.  

```openscad-3D
include <BOSL2/std.scad>
cuboid(50){
  %attach(RIGHT,BOT)
    cyl(d1=30,d2=15,h=25);
  color("green") attach(RIGHT,BOT)
    up(13)
      cyl(d1=30,d2=15,h=25);
}
```

Parent-child Anchor attachment with CENTER anchors can be surprising because the anchors
both point upwards, so in the example below, the child's CENTER anchor
points up, so it is inverted when it is attached to the parent cone.
Note that the anchors are CENTER anchors, so the bases of the anchors are
hidden in the middle of the objects.  

```openscad-3D
include <BOSL2/std.scad>
cylinder(d1=30,d2=15,h=25) attach(CENTER) anchor_arrow(40);
right(40)cylinder(d1=30,d2=15,h=25) attach(CENTER) anchor_arrow(40);
```

```openscad-3D
include <BOSL2/std.scad>
cylinder(d1=30,d2=15,h=25)
    attach(CENTER,CENTER)
        cylinder(d1=30,d2=15,h=25);
```

Is is also possible to attach to edges and corners of the parent
object.  The anchors for edges spin the child so its BACK direction is
aligned with the edge.  If the edge belongs to a top or bottom
horizontal face, then the BACK directions will point clockwise around
the face, as seen from outside the shape.  (This is the same direction
required for construction of valid faces in OpenSCAD.)  Otherwise, the
BACK direction will point upwards.

Examine the red flags below, where only edge anchors appear on a
prismoid.  The top face shows the red flags pointing clockwise.
The sloped side edges point along the edges, generally upward, and
the bottom ones appear to point counter-clockwise, but if we viewed
the shape from the bottom they would also appear clockwise.  

```openscad-3D;Big
include <BOSL2/std.scad>
prismoid([100,175],[55,88], h=55)
  for(i=[-1:1], j=[-1:1], k=[-1:1])
    let(anchor=[i,j,k])
       if (sum(v_abs(anchor))==2)
         attach(anchor,BOT)anchor_arrow(40);
```

In this example cylinders sink half-way into the top edges of the
prismoid:

```openscad-3D;Big
include <BOSL2/std.scad>
$fn=16;
r=6;
prismoid([100,175],[55,88], h=55){
   attach([TOP+RIGHT,TOP+LEFT],LEFT,overlap=r/2) cyl(r=r,l=88+2*r,rounding=r);
   attach([TOP+FWD,TOP+BACK],LEFT,overlap=r/2) cyl(r=r,l=55+2*r, rounding=r);   
}
```

This type of edge attachment is useful for attaching 3d edge masks to
edges:

```openscad-3D;Big
include <BOSL2/std.scad>
$fn=32;
diff()
cuboid(75)
   attach([FRONT+LEFT, FRONT+RIGHT, BACK+LEFT, BACK+RIGHT],
          FWD+LEFT,inside=true)
     rounding_edge_mask(l=76, r1=8,r2=28);
```

## Parent Anchor Attachment (Single Argument Attachment)

The second form of attachment is parent anchor attachment, which just
uses a single argument.  This form of attachment is less useful in
general and does not provide alignment.  When you give `attach()` a parent anchor but no child anchor it
orients the child according to the parent anchor direction but then
simply places the child based on its internally defined anchor at the
parent anchor position.  For most objects the default anchor is the
CENTER anchor, so objects will appear sunk half-way into the parent.

```openscad-3D
include <BOSL2/std.scad>
cuboid(30)
    attach(TOP)
        color("green")cuboid(10);
```

Some objects such as `cylinder()`, `prismoid()`, and `anchor_arrow()` have default anchors on the bottom, so they will appear
on the surface.  For objects like this you can save a little bit of
typing by using parent anchor attachment.  But in the case of `cube()`
the anchor is not centered, so the result is:

```openscad-3D
include <BOSL2/std.scad>
cube(30)
    attach(TOP)
        color("green")cube(10);
```

In order to make single argument attachment produce the results you
need you will probably need to change the child anchor.  Note that unlike
parent-child anchor attachment, **with parent anchor attachment the `anchor=` and `orient=` arguments
are respected.**  We could therefore place a cuboid like this:

```openscad-3D
include <BOSL2/std.scad>
cuboid(30)
  attach(RIGHT)
      color("green")cuboid(10,anchor=BOT);
```

If you need to place a cuboid at the anchor point but need it anchored
relative to one of the bottom edge or corner anchors then you can do
that with parent anchor attachment:

```openscad-3D
include <BOSL2/std.scad>
cuboid(30)
  attach(RIGHT)
      color("green")cuboid(10,anchor=BOT+FWD);
```

Another case where single argument attachment is useful is when the
child doesn't have proper attachment support.
If you use double argument attachment in such cases the results will
be incorrect because the child doesn't properly respond to the
internally propagated anchor directives.  With single argument
attachment, this is not a problem: the origin
of the child will be placed at the parent anchor point.  One module
without attachment support is `linear_extrude()`.  

```openscad-3D
include <BOSL2/std.scad>
cuboid(20)
  attach(RIGHT)
     color("red")linear_extrude(height=2) star(n=7,ir=3,or=7);
```

As noted earlier, you can set `orient=` for children with parent
anchor attachment, though the behavior may not be intuitive because
the attachment process transforms the coordinate system and the
orientation is done in the attached coordinate system.  It may be
helpful to start with the object attached to TOP and recall the rules
from the previous section about how orientation works.  The same rules
apply here.  Note that the forward arrow is pointing down after
attaching the object on the RIGHT face.

```openscad-3D
include <BOSL2/std.scad>
cuboid(20){
  attach(RIGHT)
     color_this("red")cuboid([2,4,8],orient=RIGHT,anchor=RIGHT)
        attach(FWD) anchor_arrow();
  attach(TOP)
     color_this("red")cuboid([2,4,8],orient=RIGHT,anchor=RIGHT)
            attach(FWD) anchor_arrow();
}
```



## Positioning and Attaching Multiple Children

You can attach or position more than one child at a time by enclosing them all in braces:

```openscad-3D
include <BOSL2/std.scad>
cube(50, center=true) {
    attach(TOP) cylinder(d1=50,d2=20,h=20);
    position(RIGHT) cylinder(d1=50,d2=20,h=20);
}
```

If you want to attach the same shape to multiple places on the same parent, you can pass the
desired anchors as a list to the `attach()` or `position()` modules:

```openscad-3D
include <BOSL2/std.scad>
cube(50, center=true)
    attach([RIGHT,FRONT],TOP) cylinder(d1=35,d2=20,h=25);
```

```openscad-3D
include <BOSL2/std.scad>
cube(50, center=true)
    position([TOP,RIGHT,FRONT]) cylinder(d1=35,d2=20,h=25);
```


## Attaching 2D Children

You can use attachments in 2D as well.  As usual for the 2D case you
can use TOP and BOTTOM as alternative to BACK and FORWARD.  With
parent-child anchor attachment you cannot use the spin parameter to
`attach()` nor can you specify spin to the child.  Spinning the child
on the Z axis would rotate the anchor arrows out of alignment.  

```openscad-2D
include <BOSL2/std.scad>
rect(50){
    attach(RIGHT,FRONT)
        color("red")trapezoid(w1=30,w2=0,h=30);
    attach(LEFT,FRONT,align=[FRONT,BACK],inset=3)
        color("green") trapezoid(w1=25, w2=0,h=30);
}
```

```openscad-2D
include <BOSL2/std.scad>
diff()
circle(d=50){
    attach(TOP,BOT,overlap=5)
        trapezoid(w1=30,w2=0,h=30);
    attach(BOT,BOT,inside=true)
        tag("remove")
        trapezoid(w1=30,w2=0,h=30);
}        
```

[Next: Attachable Parts](Tutorial-Attachment-Parts)
