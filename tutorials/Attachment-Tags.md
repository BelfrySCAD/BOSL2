[Prev: Using Color with Attachments](Tutorial-Attachment-Color)

# Tagged Operations

BOSL2 introduces the concept of tags.  Tags are names that can be given to attachables, so that
you can refer to them when performing `diff()`, `intersect()`, and `conv_hull()` operations.
Each object can have no more than one tag at a time.  The reason that
tagged operations are important is that they allow you to perform
operations on objects that are at different levels in the parent-child
hierarchy.  The most common example is to use `attach()` to create a
child but subtract it from the parent.

To tag an object preceed the object with the `tag()` module and give
it a name: `tag("my_cube") cube(10)`.  The tag will apply to the
object and all of its children until another tag module.  If you need
to remove a tag you can use `tag("")`.  If you need to tag just one
object and do not want to tag any of its descendents you can do this
using `tag_this(name) object();`


### `diff([remove], [keep])`
The `diff()` operator is used to difference away all shapes marked with the tag(s) given to
`remove`, from the other shapes.  

For example, to difference away a child cylinder from the middle of a parent cube, you can
do this:

```openscad-3D
include <BOSL2/std.scad>
diff("hole")
cube(100, center=true)
    tag("hole")cylinder(h=101, d=50, center=true);
```

The `keep=` argument takes tags for shapes that you want to keep in the output.

```openscad-3D
include <BOSL2/std.scad>
diff("dish", keep="antenna")
cube(100, center=true)
    attach([FRONT,TOP], overlap=33) {
        tag("dish") cylinder(h=33.1, d1=0, d2=95);
        tag("antenna") cylinder(h=33.1, d=10);
    }
```

Remember that tags applied with `tag()` are inherited by children.  In this case, we need to explicitly
untag the first cylinder (or change its tag to something else), or it
will inherit the "keep" tag and get kept.  

```openscad-3D
include <BOSL2/std.scad>
diff("hole", "keep")
tag("keep")cube(100, center=true)
    attach([RIGHT,TOP]) {
        tag("") cylinder(d=95, h=5);
        tag("hole") cylinder(d=50, h=11, anchor=CTR);
    }
```

You can apply a tag that is not propagated to the children using
`tag_this()`.  The above example could then be redone:

diff("hole", "keep")
tag_this("keep")cube(100, center=true)
    attach([RIGHT,TOP]) {
        cylinder(d=95, h=5);
        tag("hole") cylinder(d=50, h=11, anchor=CTR);
    }


You can of course apply `tag()` to several children.

```openscad-3D
include <BOSL2/std.scad>
diff("hole")
cube(100, center=true)
    attach([FRONT,TOP], overlap=20)
        tag("hole") {
            cylinder(h=20.1, d1=0, d2=95);
            down(10) cylinder(h=30, d=30);
        }
```

Many of the modules that use tags have default values for their tags.  For diff the default
remove tag is "remove" and the default keep tag is "keep".  In this example we rely on the
default values:

```openscad-3D
include <BOSL2/std.scad>
diff()
sphere(d=100) {
    tag("keep")xcyl(d=40, l=120);
    tag("remove")cuboid([40,120,100]);
}
```


The parent object can be differenced away from other shapes.  Tags are inherited by children,
though, so you will need to set the tags of the children as well as the parent.

```openscad-3D
include <BOSL2/std.scad>
diff("hole")
tag("hole")cube([20,11,45], center=true)
    tag("body")cube([40,10,90], center=true);
```

Tags (and therefore tag-based operations like `diff()`) only work correctly with attachable
children.  However, a number of built-in modules for making shapes are *not* attachable.
Some notable non-attachable modules are `text()`, `linear_extrude()`, `rotate_extrude()`,
`polygon()`, `polyhedron()`, `import()`, `surface()`, `union()`, `difference()`,
`intersection()`, `offset()`, `hull()`, and `minkowski()`.

To allow you to use tags-based operations with non-attachable shapes, you can wrap them with the
`force_tag()` module to specify their tags.  For example:

```openscad-3D
include <BOSL2/std.scad>
diff("hole")
cuboid(50)
  attach(TOP)
    force_tag("hole")
      rotate_extrude()
        right(15)
          square(10,center=true);
```

### `intersect([intersect], [keep])`

To perform an intersection of attachables, you can use the `intersect()` module.  This is
specifically intended to address the situation where you want intersections involving a parent
and a child, something that is impossible with the native `intersection()` module.  This module
treats the children in three groups: objects matching the `intersect` tags, objects matching
the tags listed in `keep` and the remaining objects that don't match any listed tags.  The
intersection is computed between the union of the `intersect` tagged objects and the union of
the objects that don't match any listed tags.  Finally the objects listed in `keep` are union
ed with the result.  

In this example the parent (untagged) is intersected with a conical
bounding shape, which is tagged with the intersect tag.

```openscad-3D
include <BOSL2/std.scad>
intersect("bounds")
cube(100, center=true)
    tag("bounds") cylinder(h=100, d1=120, d2=95, center=true, $fn=72);
```

In this example the child objects are intersected with the bounding box parent.  

```openscad-3D
include <BOSL2/std.scad>
intersect("pole cap")
cube(100, center=true)
    attach([TOP,RIGHT]) {
        tag("pole")cube([40,40,80],center=true);
        tag("cap")sphere(d=40*sqrt(2));
    }
```

The default `intersect` tag is "intersect" and the default `keep` tag is "keep".  Here is an
example where "keep" is used to keep the pole from being removed by the intersection. 

```openscad-3D
include <BOSL2/std.scad>
intersect()
cube(100, center=true) {
    tag("intersect")cylinder(h=100, d1=120, d2=95, center=true, $fn=72);
    tag("keep")zrot(45) xcyl(h=140, d=20, $fn=36);
}
```

### `conv_hull([keep])`
You can use the `conv_hull()` module to hull shapes together.  Objects
marked with the keep tags are excluded from the hull and unioned into the final result.
The default keep tag is "keep".  


```openscad-3D
include <BOSL2/std.scad>
conv_hull()
cube(50, center=true) {
    cyl(h=100, d=20);
    tag("keep")xcyl(h=100, d=20);
}
```

[Next: Edge Profiling with Attachment](Tutorial-Attachment-Edge-Profiling)
