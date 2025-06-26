[Prev: Using attach()](Tutorial-Attachment-Attach)

# Attachable Parts

Some objects provide named attachable parts that you can select
instead of using the main geometry for the object.  One important kind
of attachable part is the inside of a tube.

Here is a tube with its anchors shown:

```openscad-3D
include<BOSL2/std.scad>
tube(id=20,h=15,wall=3)
  show_anchors();
```

The anchors are all on the outside wall of the tube and give you no
method for placing a child **inside** the tube.  In order to attach
inside the tube, we select the "inside" part using the `attach_part()`
module.

```openscad-3D
include<BOSL2/std.scad>
tube(id=20,h=15,wall=3)
  attach_part("inside")
    align(BACK,TOP)
      color("lightblue") cuboid(4);
```

Now when we align the cube to the BACK wall of the tube it appears on
the inside of the tube.  If you need to attach to both the inside and
outside you can place some attachments using `attach_part()` and some
with the standard attachment geometry on the outside like this:

```openscad-3D
include<BOSL2/std.scad>
diff()
tube(id=20,h=15,wall=3){
  attach([1,-1/2],BOT)
    color("green")cyl(d=4,h=3,$fn=12);
  attach_part("inside"){
    attach(LEFT,BOT,align=TOP)
      color("lightblue")cuboid(4);
    attach(BACK,CTR,align=TOP,inside=true, inset=-0.1)
      cuboid(4);
  }
}
```

[Next: Using Color with Attachments](Tutorial-Attachment-Color)
