//////////////////////////////////////////////////////////////////////
// LibFile: mutators.scad
//   Functions and modules to mutate children in various ways.
// Includes:
//   include <BOSL2/std.scad>
//////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////
// Section: Volume Division Mutators
//////////////////////////////////////////////////////////////////////

// Module: bounding_box()
// Usage:
//   bounding_box() ...
// Description:
//   Returns the smallest axis-aligned square (or cube) shape that contains all the 2D (or 3D)
//   children given.  The module children() is supposed to be a 3d shape when planar=false and
//   a 2d shape when planar=true otherwise the system will issue a warning of mixing dimension
//   or scaling by 0.
// Arguments:
//   excess = The amount that the bounding box should be larger than needed to bound the children, in each axis.
//   planar = If true, creates a 2D bounding rectangle.  Is false, creates a 3D bounding cube.  Default: false
// Example(3D):
//   module shapes() {
//       translate([10,8,4]) cube(5);
//       translate([3,0,12]) cube(2);
//   }
//   #bounding_box() shapes();
//   shapes();
// Example(2D):
//   module shapes() {
//       translate([10,8]) square(5);
//       translate([3,0]) square(2);
//   }
//   #bounding_box(planar=true) shapes();
//   shapes();
module bounding_box(excess=0, planar=false) {
    // a 3d (or 2d when planar=true) approx. of the children projection on X axis
    module _xProjection() {
        if (planar) {
            projection()
                rotate([90,0,0])
                    linear_extrude(1, center=true)
                        hull()
                            children();
        } else {
            xs = excess<.1? 1: excess;
            linear_extrude(xs, center=true)
                projection()
                    rotate([90,0,0])
                        linear_extrude(xs, center=true)
                            projection()
                                hull()
                                    children();
        }
    }

    // a bounding box with an offset of 1 in all axis
    module _oversize_bbox() {
        if (planar) {
            minkowski() {
                _xProjection() children(); // x axis
                rotate(-90) _xProjection() rotate(90) children(); // y axis
            }
        } else {
            minkowski() {
                _xProjection() children(); // x axis
                rotate(-90) _xProjection() rotate(90) children(); // y axis
                rotate([0,-90,0]) _xProjection() rotate([0,90,0]) children(); // z axis
            }
        }
    }

    // offsets a cube by `excess`
    module _shrink_cube() {
        intersection() {
            translate((1-excess)*[ 1, 1, 1]) children();
            translate((1-excess)*[-1,-1,-1]) children();
        }
    }

    if(planar) {
        offset(excess-1/2) _oversize_bbox() children();
    } else {
        render(convexity=2)
        if (excess>.1) {
            _oversize_bbox() children();
        } else {
            _shrink_cube() _oversize_bbox() children();
        }
    }
}


// Function&Module: half_of()
//
// Usage: as module
//   half_of(v, <cp>, <s>) ...
// Usage: as function
//   half_of(v, <cp>, p, <s>)...
//
// Description:
//   Slices an object at a cut plane, and masks away everything that is on one side.
//   * Called as a function with a path in the `p` argument, returns the
//       intersection of path `p` and given half-space.
//   * Called as a function with a 2D path in the `p` argument
//       and a 2D vector `p`, returns the intersection of path `p` and given
//       half-plane.
//
// Arguments:
//   v = Normal of plane to slice at.  Keeps everything on the side the normal points to.  Default: [0,0,1] (UP)
//   cp = If given as a scalar, moves the cut plane along the normal by the given amount.  If given as a point, specifies a point on the cut plane.  This can be used to shift where it slices the object at.  Default: [0,0,0]
//   s = Mask size to use.  Use a number larger than twice your object's largest axis.  If you make this too large, it messes with centering your view.  Default: 100
//   planar = If true, this becomes a 2D operation.  When planar, a `v` of `UP` or `DOWN` becomes equivalent of `BACK` and `FWD` respectively.
//
// Examples:
//   half_of(DOWN+BACK, cp=[0,-10,0]) cylinder(h=40, r1=10, r2=0, center=false);
//   half_of(DOWN+LEFT, s=200) sphere(d=150);
// Example(2D):
//   half_of([1,1], planar=true) circle(d=50);
module half_of(v=UP, cp, s=1000, planar=false)
{
    cp = is_vector(v,4)? assert(cp==undef, "Don't use cp with plane definition.") plane_normal(v) * v[3] :
        is_vector(cp)? cp :
        is_num(cp)? cp*unit(v) :
        [0,0,0];
    v = is_vector(v,4)? plane_normal(v) : v;
    if (cp != [0,0,0]) {
        translate(cp) half_of(v=v, s=s, planar=planar) translate(-cp) children();
    } else if (planar) {
        v = (v==UP)? BACK : (v==DOWN)? FWD : v;
        ang = atan2(v.y, v.x);
        difference() {
            children();
            rotate(ang+90) {
                back(s/2) square(s, center=true);
            }
        }
    } else {
        difference() {
            children();
            rot(from=UP, to=-v) {
                up(s/2) cube(s, center=true);
            }
        }
    }
}

function half_of(_arg1=_undef, _arg2=_undef, _arg3=_undef, _arg4=_undef,
    v=_undef, cp=_undef, p=_undef, s=_undef) =
    let(args=get_named_args([_arg1, _arg2, _arg3, _arg4],
        [[v,undef,0], [cp,0,2], [p,undef,1], [s, 1e4]]),
        v=args[0], cp0=args[1], p=args[2], s=args[3],
        cp = is_num(cp0) ? cp0*unit(v) : cp0)
    assert(is_vector(v,2)||is_vector(v,3),
      "must provide a half-plane or half-space")
    let(d=len(v))
    assert(len(cp) == d, str("cp must have dimension ", d))
    is_vector(p) ?
        assert(len(p) == d, str("vector must have dimension ", d))
        let(z=(p-cp)*v) (z >= 0 ? p : p - (z*v)/(v*v))
        :
    p == [] ? [] : // special case: empty path remains empty
    is_path(p) ?
        assert(len(p[0]) == d, str("path must have dimension ", d))
        let(z = [for(x=p) (x-cp)*v])
        [ for(i=[0:len(p)-1]) each concat(z[i] >= 0 ? [p[i]] : [],
            // we assume a closed path here;
            // to make this correct for an open path,
            // just replace this by [] when i==len(p)-1:
            let(j=(i+1)%len(p))
            // the remaining path may have flattened sections, but this cannot
            // create self-intersection or whiskers:
            z[i]*z[j] >= 0 ? [] : [(z[j]*p[i]-z[i]*p[j])/(z[j]-z[i])]) ]
        :
    is_vnf(p) ?
    // we must put is_vnf() before is_region(), because most triangulated
    // VNFs will pass is_region() test
    vnf_halfspace(halfspace=concat(v,[-v*cp]), vnf=p) :
    is_region(p) ?
        assert(len(v) == 2, str("3D vector not compatible with region"))
        let(u=unit(v), w=[-u[1], u[0]],
            R=[[cp+s*w, cp+s*(v+v), cp+s*(v-w), cp-s*w]]) // half-plane
        intersection(R, p)
        :
    assert(false, "must pass either a point, a path, a region, or a VNF");

// Function&Module: left_half()
//
// Usage: as module
//   left_half(<s>, <x>) ...
//   left_half(planar=true, <s>, <x>) ...
// Usage: as function
//   left_half(<s>, <x>, path)
//   left_half(<s>, <x>, region)
//   left_half(<s>, <x>, vnf)
//
// Description:
//   Slices an object at a vertical Y-Z cut plane, and masks away everything that is right of it.
//
// Arguments:
//   s = Mask size to use.  Use a number larger than twice your object's largest axis.  If you make this too large, OpenSCAD's preview rendering may be incorrect.  Default: 10000
//   x = The X coordinate of the cut-plane.  Default: 0
//   planar = If true, this becomes a 2D operation.
//
// Examples:
//   left_half() sphere(r=20);
//   left_half(x=-8) sphere(r=20);
// Example(2D):
//   left_half(planar=true) circle(r=20);
module left_half(s=1000, x=0, planar=false)
{
    dir = LEFT;
    difference() {
        children();
        translate([x,0,0]-dir*s/2) {
            if (planar) {
                square(s, center=true);
            } else {
                cube(s, center=true);
            }
        }
    }
}
function left_half(_arg1=_undef, _arg2=_undef, _arg3=_undef,
    x=_undef, p=_undef, s=_undef) =
    let(args=get_named_args([_arg1, _arg2, _arg3],
    [[x, 0,1], [p,undef,0], [s, 1e4]]),
        x=args[0], p=args[1], s=args[2])
    half_of(v=[1,0,0], cp=x, p=p);



// Function&Module: right_half()
//
// Usage:
//   right_half([s], [x]) ...
//   right_half(planar=true, [s], [x]) ...
//
// Description:
//   Slices an object at a vertical Y-Z cut plane, and masks away everything that is left of it.
//
// Arguments:
//   s = Mask size to use.  Use a number larger than twice your object's largest axis.  If you make this too large, OpenSCAD's preview rendering may be incorrect.  Default: 10000
//   x = The X coordinate of the cut-plane.  Default: 0
//   planar = If true, this becomes a 2D operation.
//
// Examples(FlatSpin):
//   right_half() sphere(r=20);
//   right_half(x=-5) sphere(r=20);
// Example(2D):
//   right_half(planar=true) circle(r=20);
module right_half(s=1000, x=0, planar=false)
{
    dir = RIGHT;
    difference() {
        children();
        translate([x,0,0]-dir*s/2) {
            if (planar) {
                square(s, center=true);
            } else {
                cube(s, center=true);
            }
        }
    }
}
function right_half(_arg1=_undef, _arg2=_undef, _arg3=_undef,
    x=_undef, p=_undef, s=_undef) =
    let(args=get_named_args([_arg1, _arg2, _arg3],
    [[x, 0,1], [p,undef,0], [s, 1e4]]),
        x=args[0], p=args[1], s=args[2])
    half_of(v=[-1,0,0], cp=x, p=p);



// Function&Module: front_half()
//
// Usage:
//   front_half([s], [y]) ...
//   front_half(planar=true, [s], [y]) ...
//
// Description:
//   Slices an object at a vertical X-Z cut plane, and masks away everything that is behind it.
//
// Arguments:
//   s = Mask size to use.  Use a number larger than twice your object's largest axis.  If you make this too large, OpenSCAD's preview rendering may be incorrect.  Default: 10000
//   y = The Y coordinate of the cut-plane.  Default: 0
//   planar = If true, this becomes a 2D operation.
//
// Examples(FlatSpin):
//   front_half() sphere(r=20);
//   front_half(y=5) sphere(r=20);
// Example(2D):
//   front_half(planar=true) circle(r=20);
module front_half(s=1000, y=0, planar=false)
{
    dir = FWD;
    difference() {
        children();
        translate([0,y,0]-dir*s/2) {
            if (planar) {
                square(s, center=true);
            } else {
                cube(s, center=true);
            }
        }
    }
}
function front_half(_arg1=_undef, _arg2=_undef, _arg3=_undef,
    x=_undef, p=_undef, s=_undef) =
    let(args=get_named_args([_arg1, _arg2, _arg3],
    [[x, 0,1], [p,undef,0], [s, 1e4]]),
        x=args[0], p=args[1], s=args[2])
    half_of(v=[0,1,0], cp=x, p=p);



// Function&Module: back_half()
//
// Usage:
//   back_half([s], [y]) ...
//   back_half(planar=true, [s], [y]) ...
//
// Description:
//   Slices an object at a vertical X-Z cut plane, and masks away everything that is in front of it.
//
// Arguments:
//   s = Mask size to use.  Use a number larger than twice your object's largest axis.  If you make this too large, OpenSCAD's preview rendering may be incorrect.  Default: 10000
//   y = The Y coordinate of the cut-plane.  Default: 0
//   planar = If true, this becomes a 2D operation.
//
// Examples:
//   back_half() sphere(r=20);
//   back_half(y=8) sphere(r=20);
// Example(2D):
//   back_half(planar=true) circle(r=20);
module back_half(s=1000, y=0, planar=false)
{
    dir = BACK;
    difference() {
        children();
        translate([0,y,0]-dir*s/2) {
            if (planar) {
                square(s, center=true);
            } else {
                cube(s, center=true);
            }
        }
    }
}
function back_half(_arg1=_undef, _arg2=_undef, _arg3=_undef,
    x=_undef, p=_undef, s=_undef) =
    let(args=get_named_args([_arg1, _arg2, _arg3],
    [[x, 0,1], [p,undef,0], [s, 1e4]]),
        x=args[0], p=args[1], s=args[2])
    half_of(v=[0,-1,0], cp=x, p=p);



// Function&Module: bottom_half()
//
// Usage:
//   bottom_half([s], [z]) ...
//
// Description:
//   Slices an object at a horizontal X-Y cut plane, and masks away everything that is above it.
//
// Arguments:
//   s = Mask size to use.  Use a number larger than twice your object's largest axis.  If you make this too large, OpenSCAD's preview rendering may be incorrect.  Default: 10000
//   z = The Z coordinate of the cut-plane.  Default: 0
//
// Examples:
//   bottom_half() sphere(r=20);
//   bottom_half(z=-10) sphere(r=20);
module bottom_half(s=1000, z=0)
{
    dir = DOWN;
    difference() {
        children();
        translate([0,0,z]-dir*s/2) {
            cube(s, center=true);
        }
    }
}
function right_half(_arg1=_undef, _arg2=_undef, _arg3=_undef,
    x=_undef, p=_undef, s=_undef) =
    let(args=get_named_args([_arg1, _arg2, _arg3],
    [[x, 0,1], [p,undef,0], [s, 1e4]]),
        x=args[0], p=args[1], s=args[2])
    half_of(v=[0,0,-1], cp=x, p=p);



// Function&Module: top_half()
//
// Usage:
//   top_half([s], [z]) ...
//
// Description:
//   Slices an object at a horizontal X-Y cut plane, and masks away everything that is below it.
//
// Arguments:
//   s = Mask size to use.  Use a number larger than twice your object's largest axis.  If you make this too large, OpenSCAD's preview rendering may be incorrect.  Default: 10000
//   z = The Z coordinate of the cut-plane.  Default: 0
//
// Examples(Spin):
//   top_half() sphere(r=20);
//   top_half(z=5) sphere(r=20);
module top_half(s=1000, z=0)
{
    dir = UP;
    difference() {
        children();
        translate([0,0,z]-dir*s/2) {
            cube(s, center=true);
        }
    }
}
function right_half(_arg1=_undef, _arg2=_undef, _arg3=_undef,
    x=_undef, p=_undef, s=_undef) =
    let(args=get_named_args([_arg1, _arg2, _arg3],
    [[x, 0,1], [p,undef,0], [s, 1e4]]),
        x=args[0], p=args[1], s=args[2])
    half_of(v=[0,0,1], cp=x, p=p);



//////////////////////////////////////////////////////////////////////
// Section: Chain Mutators
//////////////////////////////////////////////////////////////////////

// Module: chain_hull()
//
// Usage:
//   chain_hull() ...
//
// Description:
//   Performs hull operations between consecutive pairs of children,
//   then unions all of the hull results.  This can be a very slow
//   operation, but it can provide results that are hard to get
//   otherwise.
//
// Side Effects:
//   `$idx` is set to the index value of the first child of each hulling pair, and can be used to modify each child pair individually.
//   `$primary` is set to true when the child is the first in a chain pair.
//
// Example:
//   chain_hull() {
//       cube(5, center=true);
//       translate([30, 0, 0]) sphere(d=15);
//       translate([60, 30, 0]) cylinder(d=10, h=20);
//       translate([60, 60, 0]) cube([10,1,20], center=false);
//   }
// Example: Using `$idx` and `$primary`
//   chain_hull() {
//       zrot(  0) right(100) if ($primary) cube(5+3*$idx,center=true); else sphere(r=10+3*$idx);
//       zrot( 45) right(100) if ($primary) cube(5+3*$idx,center=true); else sphere(r=10+3*$idx);
//       zrot( 90) right(100) if ($primary) cube(5+3*$idx,center=true); else sphere(r=10+3*$idx);
//       zrot(135) right(100) if ($primary) cube(5+3*$idx,center=true); else sphere(r=10+3*$idx);
//       zrot(180) right(100) if ($primary) cube(5+3*$idx,center=true); else sphere(r=10+3*$idx);
//   }
module chain_hull()
{
    union() {
        if ($children == 1) {
            children();
        } else if ($children > 1) {
            for (i =[1:1:$children-1]) {
                $idx = i;
                hull() {
                    let($primary=true) children(i-1);
                    let($primary=false) children(i);
                }
            }
        }
    }
}



//////////////////////////////////////////////////////////////////////
// Section: Warp Mutators
//////////////////////////////////////////////////////////////////////

// Module: cylindrical_extrude()
// Usage:
//   cylindrical_extrude(size, ir|id, or|od, [convexity]) ...
// Description:
//   Extrudes all 2D children outwards, curved around a cylindrical shape.
// Arguments:
//   or = The outer radius to extrude to.
//   od = The outer diameter to extrude to.
//   ir = The inner radius to extrude from.
//   id = The inner diameter to extrude from.
//   size = The [X,Y] size of the 2D children to extrude.  Default: [1000,1000]
//   convexity = The max number of times a line could pass though a wall.  Default: 10
//   spin = Amount in degrees to spin around cylindrical axis.  Default: 0
//   orient = The orientation of the cylinder to wrap around, given as a vector.  Default: UP
// Example:
//   cylindrical_extrude(or=50, ir=45)
//       text(text="Hello World!", size=10, halign="center", valign="center");
// Example: Spin Around the Cylindrical Axis
//   cylindrical_extrude(or=50, ir=45, spin=90)
//       text(text="Hello World!", size=10, halign="center", valign="center");
// Example: Orient to the Y Axis.
//   cylindrical_extrude(or=40, ir=35, orient=BACK)
//       text(text="Hello World!", size=10, halign="center", valign="center");
module cylindrical_extrude(or, ir, od, id, size=1000, convexity=10, spin=0, orient=UP) {
    assert(is_num(size) || is_vector(size,2));
    size = is_num(size)? [size,size] : size;
    ir = get_radius(r=ir,d=id);
    or = get_radius(r=or,d=od);
    index_r = or;
    circumf = 2 * PI * index_r;
    width = min(size.x, circumf);
    assert(width <= circumf, "Shape would more than completely wrap around.");
    sides = segs(or);
    step = circumf / sides;
    steps = ceil(width / step);
    rot(from=UP, to=orient) rot(spin) {
        for (i=[0:1:steps-2]) {
            x = (i+0.5-steps/2) * step;
            zrot(360 * x / circumf) {
                fwd(or*cos(180/sides)) {
                    xrot(-90) {
                        linear_extrude(height=or-ir, scale=[ir/or,1], center=false, convexity=convexity) {
                            yflip()
                            intersection() {
                                left(x) children();
                                rect([quantup(step,pow(2,-15)),size.y],center=true);
                            }
                        }
                    }
                }
            }
        }
    }
}



//////////////////////////////////////////////////////////////////////
// Section: Offset Mutators
//////////////////////////////////////////////////////////////////////

// Module: minkowski_difference()
// Usage:
//   minkowski_difference() { base_shape(); diff_shape(); ... }
// Description:
//   Takes a 3D base shape and one or more 3D diff shapes, carves out the diff shapes from the
//   surface of the base shape, in a way complementary to how `minkowski()` unions shapes to the
//   surface of its base shape.
// Arguments:
//   planar = If true, performs minkowski difference in 2D.  Default: false (3D)
// Example:
//   minkowski_difference() {
//       union() {
//           cube([120,70,70], center=true);
//           cube([70,120,70], center=true);
//           cube([70,70,120], center=true);
//       }
//       sphere(r=10);
//   }
module minkowski_difference(planar=false) {
    difference() {
        bounding_box(excess=0, planar=planar) children(0);
        render(convexity=20) {
            minkowski() {
                difference() {
                    bounding_box(excess=1, planar=planar) children(0);
                    children(0);
                }
                for (i=[1:1:$children-1]) children(i);
            }
        }
    }
}


// Module: round2d()
// Usage:
//   round2d(r) ...
//   round2d(or) ...
//   round2d(ir) ...
//   round2d(or, ir) ...
// Description:
//   Rounds arbitrary 2D objects.  Giving `r` rounds all concave and convex corners.  Giving just `ir`
//   rounds just concave corners.  Giving just `or` rounds convex corners.  Giving both `ir` and `or`
//   can let you round to different radii for concave and convex corners.  The 2D object must not have
//   any parts narrower than twice the `or` radius.  Such parts will disappear.
// Arguments:
//   r = Radius to round all concave and convex corners to.
//   or = Radius to round only outside (convex) corners to.  Use instead of `r`.
//   ir = Radius to round only inside (concave) corners to.  Use instead of `r`.
// Examples(2D):
//   round2d(r=10) {square([40,100], center=true); square([100,40], center=true);}
//   round2d(or=10) {square([40,100], center=true); square([100,40], center=true);}
//   round2d(ir=10) {square([40,100], center=true); square([100,40], center=true);}
//   round2d(or=16,ir=8) {square([40,100], center=true); square([100,40], center=true);}
module round2d(r, or, ir)
{
    or = get_radius(r1=or, r=r, dflt=0);
    ir = get_radius(r1=ir, r=r, dflt=0);
    offset(or) offset(-ir-or) offset(delta=ir,chamfer=true) children();
}


// Module: shell2d()
// Usage:
//   shell2d(thickness, [or], [ir], [fill], [round])
// Description:
//   Creates a hollow shell from 2D children, with optional rounding.
// Arguments:
//   thickness = Thickness of the shell.  Positive to expand outward, negative to shrink inward, or a two-element list to do both.
//   or = Radius to round corners on the outside of the shell.  If given a list of 2 radii, [CONVEX,CONCAVE], specifies the radii for convex and concave corners separately.  Default: 0 (no outside rounding)
//   ir = Radius to round corners on the inside of the shell.  If given a list of 2 radii, [CONVEX,CONCAVE], specifies the radii for convex and concave corners separately.  Default: 0 (no inside rounding)
// Examples(2D):
//   shell2d(10) {square([40,100], center=true); square([100,40], center=true);}
//   shell2d(-10) {square([40,100], center=true); square([100,40], center=true);}
//   shell2d([-10,10]) {square([40,100], center=true); square([100,40], center=true);}
//   shell2d(10,or=10) {square([40,100], center=true); square([100,40], center=true);}
//   shell2d(10,ir=10) {square([40,100], center=true); square([100,40], center=true);}
//   shell2d(10,or=[10,0]) {square([40,100], center=true); square([100,40], center=true);}
//   shell2d(10,or=[0,10]) {square([40,100], center=true); square([100,40], center=true);}
//   shell2d(10,ir=[10,0]) {square([40,100], center=true); square([100,40], center=true);}
//   shell2d(10,ir=[0,10]) {square([40,100], center=true); square([100,40], center=true);}
//   shell2d(8,or=[16,8],ir=[16,8]) {square([40,100], center=true); square([100,40], center=true);}
module shell2d(thickness, or=0, ir=0)
{
    thickness = is_num(thickness)? (
        thickness<0? [thickness,0] : [0,thickness]
    ) : (thickness[0]>thickness[1])? (
        [thickness[1],thickness[0]]
    ) : thickness;
    orad = is_finite(or)? [or,or] : or;
    irad = is_finite(ir)? [ir,ir] : ir;
    difference() {
        round2d(or=orad[0],ir=orad[1])
            offset(delta=thickness[1])
                children();
        round2d(or=irad[1],ir=irad[0])
            offset(delta=thickness[0])
                children();
    }
}


// Module: offset3d()
// Usage:
//   offset3d(r, [size], [convexity]);
// Description:
//   Expands or contracts the surface of a 3D object by a given amount.  This is very, very slow.
//   No really, this is unbearably slow.  It uses `minkowski()`.  Use this as a last resort.
//   This is so slow that no example images will be rendered.
// Arguments:
//   r = Radius to expand object by.  Negative numbers contract the object.
//   size = Maximum size of object to be contracted, given as a scalar.  Default: 100
//   convexity = Max number of times a line could intersect the walls of the object.  Default: 10
module offset3d(r=1, size=100, convexity=10) {
    n = quant(max(8,segs(abs(r))),4);
    if (r==0) {
        children();
    } else if (r>0) {
        render(convexity=convexity)
        minkowski() {
            children();
            sphere(r, $fn=n);
        }
    } else {
        size2 = size * [1,1,1];
        size1 = size2 * 1.02;
        render(convexity=convexity)
        difference() {
            cube(size2, center=true);
            minkowski() {
                difference() {
                    cube(size1, center=true);
                    children();
                }
                sphere(-r, $fn=n);
            }
        }
    }
}


// Module: round3d()
// Usage:
//   round3d(r) ...
//   round3d(or) ...
//   round3d(ir) ...
//   round3d(or, ir) ...
// Description:
//   Rounds arbitrary 3D objects.  Giving `r` rounds all concave and convex corners.  Giving just `ir`
//   rounds just concave corners.  Giving just `or` rounds convex corners.  Giving both `ir` and `or`
//   can let you round to different radii for concave and convex corners.  The 3D object must not have
//   any parts narrower than twice the `or` radius.  Such parts will disappear.  This is an *extremely*
//   slow operation.  I cannot emphasize enough just how slow it is.  It uses `minkowski()` multiple times.
//   Use this as a last resort.  This is so slow that no example images will be rendered.
// Arguments:
//   r = Radius to round all concave and convex corners to.
//   or = Radius to round only outside (convex) corners to.  Use instead of `r`.
//   ir = Radius to round only inside (concave) corners to.  Use instead of `r`.
module round3d(r, or, ir, size=100)
{
    or = get_radius(r1=or, r=r, dflt=0);
    ir = get_radius(r1=ir, r=r, dflt=0);
    offset3d(or, size=size)
        offset3d(-ir-or, size=size)
            offset3d(ir, size=size)
                children();
}



//////////////////////////////////////////////////////////////////////
// Section: Colors
//////////////////////////////////////////////////////////////////////

// Function&Module: HSL()
// Usage:
//   HSL(h,[s],[l],[a]) ...
//   rgb = HSL(h,[s],[l]);
// Description:
//   When called as a function, returns the [R,G,B] color for the given hue `h`, saturation `s`, and lightness `l` from the HSL colorspace.
//   When called as a module, sets the color to the given hue `h`, saturation `s`, and lightness `l` from the HSL colorspace.
// Arguments:
//   h = The hue, given as a value between 0 and 360.  0=red, 60=yellow, 120=green, 180=cyan, 240=blue, 300=magenta.
//   s = The saturation, given as a value between 0 and 1.  0 = grayscale, 1 = vivid colors.  Default: 1
//   l = The lightness, between 0 and 1.  0 = black, 0.5 = bright colors, 1 = white.  Default: 0.5
//   a = When called as a module, specifies the alpha channel as a value between 0 and 1.  0 = fully transparent, 1=opaque.  Default: 1
// Example:
//   HSL(h=120,s=1,l=0.5) sphere(d=60);
// Example:
//   rgb = HSL(h=270,s=0.75,l=0.6);
//   color(rgb) cube(60, center=true);
function HSL(h,s=1,l=0.5) =
    let(
        h=posmod(h,360)
    ) [
        for (n=[0,8,4]) let(
            k=(n+h/30)%12
        ) l - s*min(l,1-l)*max(min(k-3,9-k,1),-1)
    ];

module HSL(h,s=1,l=0.5,a=1) color(HSL(h,s,l),a) children();


// Function&Module: HSV()
// Usage:
//   HSV(h,[s],[v],[a]) ...
//   rgb = HSV(h,[s],[v]);
// Description:
//   When called as a function, returns the [R,G,B] color for the given hue `h`, saturation `s`, and value `v` from the HSV colorspace.
//   When called as a module, sets the color to the given hue `h`, saturation `s`, and value `v` from the HSV colorspace.
// Arguments:
//   h = The hue, given as a value between 0 and 360.  0=red, 60=yellow, 120=green, 180=cyan, 240=blue, 300=magenta.
//   s = The saturation, given as a value between 0 and 1.  0 = grayscale, 1 = vivid colors.  Default: 1
//   v = The value, between 0 and 1.  0 = darkest black, 1 = bright.  Default: 1
//   a = When called as a module, specifies the alpha channel as a value between 0 and 1.  0 = fully transparent, 1=opaque.  Default: 1
// Example:
//   HSV(h=120,s=1,v=1) sphere(d=60);
// Example:
//   rgb = HSV(h=270,s=0.75,v=0.9);
//   color(rgb) cube(60, center=true);
function HSV(h,s=1,v=1) =
    let(
        h=posmod(h,360),
        v2=v*(1-s),
        r=lookup(h,[[0,v], [60,v], [120,v2], [240,v2], [300,v], [360,v]]),
        g=lookup(h,[[0,v2], [60,v], [180,v], [240,v2], [360,v2]]),
        b=lookup(h,[[0,v2], [120,v2], [180,v], [300,v], [360,v2]])
    ) [r,g,b];

module HSV(h,s=1,v=1,a=1) color(HSV(h,s,v),a) children();


// Module: rainbow()
// Usage:
//   rainbow(list) ...
// Description:
//   Iterates the list, displaying children in different colors for each list item.
//   This is useful for debugging lists of paths and such.
// Arguments:
//   list = The list of items to iterate through.
//   stride = Consecutive colors stride around the color wheel divided into this many parts.
// Side Effects:
//   Sets the color to progressive values along the ROYGBIV spectrum for each item.
//   Sets `$idx` to the index of the current item in `list` that we want to show.
//   Sets `$item` to the current item in `list` that we want to show.
// Example(2D):
//   rainbow(["Foo","Bar","Baz"]) fwd($idx*10) text(text=$item,size=8,halign="center",valign="center");
// Example(2D):
//   rgn = [circle(d=45,$fn=3), circle(d=75,$fn=4), circle(d=50)];
//   rainbow(rgn) stroke($item, closed=true);
module rainbow(list, stride=1)
{
    ll = len(list);
    huestep = 360 / ll;
    hues = [for (i=[0:1:ll-1]) posmod(i*huestep+i*360/stride,360)];
    for($idx=idx(list)) {
        $item = list[$idx];
        HSV(h=hues[$idx]) children();
    }
}


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
