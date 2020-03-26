# BOSL2 Distributors Tutorial

## Distributors

Distributors are modules that are useful for placing multiple copies of a child
across a line, area, volume, or ring.  Many transforms also have one or more
distributive variation.

Transforms              | Related Distributors
----------------------- | ---------------------
`left()`, `right()`     | `xcopies()`
`fwd()`, `back()`       | `ycopies()`
`down()`, `up()`        | `zcopies()`
`move()`, `translate()` | `move_copies()`, `line_of()`, `grid2d()`, `grid3d()`
`xrot()`                | `xrot_copies()`
`yrot()`                | `yrot_copies()`
`zrot()`                | `zrot_copies()`
`rot()`, `rotate()`     | `rot_copies()`, `arc_of()`
`xflip()`               | `xflip_copy()`
`yflip()`               | `yflip_copy()`
`zflip()`               | `zflip_copy()`
`mirror()`              | `mirror_copy()`


### Transform Distributors
Using `xcopies()`, you can make a line of evenly spaced copies of a shape
centered along the X axis.  To make a line of 5 spheres, spaced every 20
units along the X axis, do:
```openscad
xcopies(20, n=5) sphere(d=10);
```
Note that the first expected argument to `xcopies()` is the spacing argument,
so you do not need to supply the `spacing=` argument name.

Similarly, `ycopies()` makes a line of evenly spaced copies centered along the
Y axis. To make a line of 5 spheres, spaced every 20 units along the Y
axis, do:
```openscad
ycopies(20, n=5) sphere(d=10);
```

And, `zcopies()` makes a line of evenly spaced copies centered along the Z axis.
To make a line of 5 spheres, spaced every 20 units along the Z axis, do:
```openscad
zcopies(20, n=5) sphere(d=10);
```

If you don't give the `n=` argument to `xcopies()`, `ycopies()` or `zcopies()`,
then it defaults to 2 (two) copies:
```openscad
xcopies(20) sphere(d=10);
```

```openscad
ycopies(20) sphere(d=10);
```

```openscad
zcopies(20) sphere(d=10);
```

If you don't know the spacing you want, but instead know how long a line you want
the copies distributed over, you can use the `l=` argument instead of the `spacing=`
argument:
```openscad
xcopies(l=100, n=5) sphere(d=10);
```

```openscad
ycopies(l=100, n=5) sphere(d=10);
```

```openscad
zcopies(l=100, n=5) sphere(d=10);
```

If you don't want the line of copies centered on the origin, you can give a starting
point, `sp=`, and the line of copies will start there.  For `xcopies()`, the line of
copies will extend to the right of the starting point.
```openscad
xcopies(20, n=5, sp=[0,0,0]) sphere(d=10);
```

For `ycopies()`, the line of copies will extend to the back of the starting point.
```openscad
ycopies(20, n=5, sp=[0,0,0]) sphere(d=10);
```

For `zcopies()`, the line of copies will extend upwards from the starting point.
```openscad
zcopies(20, n=5, sp=[0,0,0]) sphere(d=10);
```

If you need to distribute copies along an arbitrary line, you can use the
`line_of()` command.  You can give both the direction vector and the spacing
of the line of copies with the `spacing=` argument:
```openscad
line_of(spacing=(BACK+RIGHT)*20, n=5) sphere(d=10);
```

With the `p1=` argument, you can specify the starting point of the line:
```openscad
line_of(spacing=(BACK+RIGHT)*20, n=5, p1=[0,0,0]) sphere(d=10);
```

IF you give both `p1=` and `p2=`, you can nail down both the start and endpoints
of the line of copies:
```openscad
line_of(p1=[0,100,0], p2=[100,0,0], n=4)
    sphere(d=10);
```

You can also spread copies across a 2D area using the `grid2d()`


### Rotational Distributors
You can make six copies of a cone, rotated around a center:
```openscad
zrot_copies(n=6) yrot(90) cylinder(h=50,d1=0,d2=20);
```

To Be Completed


