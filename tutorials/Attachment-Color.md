[Prev: Attachable Parts](Tutorial-Attachment-Parts)

## Coloring Attachables
Usually, when coloring a shape with the `color()` module, the parent color overrides the colors of
all children.  This is often not what you want:

```openscad-3D
include <BOSL2/std.scad>
$fn = 24;
color("red") spheroid(d=3) {
    attach(CENTER,BOT) color("white") cyl(h=10, d=1) {
        attach(TOP,BOT) color("green") cyl(h=5, d1=3, d2=0);
    }
}
```

If you use the `recolor()` module, however, the child's color
overrides the color of the parent.  This is probably easier to understand by example:

```openscad-3D
include <BOSL2/std.scad>
$fn = 24;
recolor("red") spheroid(d=3) {
    attach(CENTER,BOT) recolor("white") cyl(h=10, d=1) {
        attach(TOP,BOT) recolor("green") cyl(h=5, d1=3, d2=0);
    }
}
```

Be aware that `recolor()` will only work if you avoid using the native
`color()` module.  Also note that `recolor()` still affects all its
children.  If you want to color an object without affecting the
children you can use `color_this()`.  See the difference below:

```openscad-3D
include <BOSL2/std.scad>
$fn = 24;
recolor("red") spheroid(d=3) {
    attach(CENTER,BOT) recolor("white") cyl(h=10, d=1) {
        attach(TOP,BOT)  cyl(h=5, d1=3, d2=0);
    }
}
right(5)
recolor("red") spheroid(d=3) {
    attach(CENTER,BOT) color_this("white") cyl(h=10, d=1) {
        attach(TOP,BOT)  cyl(h=5, d1=3, d2=0);
    }
}
```

Similar modules exist to provide access to the highlight and
background modifiers.   You can specify `highlight()` and then later
`highlight(false)` to control the use of the `#` modifier.  Similarly
you can use `ghost()` and `ghost(false)` to provide more control of
the `%` modifier.  And as with color, you can also use
`highlight_this()` and `ghost_this()` to affect just one child without
affecting its descendents.  

As with all of the attachable features, these color, highlight and ghost modules only work
on attachable objects, so they will have no effect on objects you
create using `linear_extrude()` or `rotate_extrude()`.  

[Next: Tagged Operations with Attachments](Tutorial-Attachment-Tags)
