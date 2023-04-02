//////////////////////////////////////////////////////////////////////
// LibFile: mutators.scad
//   Functions and modules to mutate children in various ways.
// Includes:
//   include <BOSL2/std.scad>
// FileGroup: Basic Modeling
// FileSummary: Modules and Functions to mutate items.
// FileFootnotes: STD=Included in std.scad
//////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////
// Section: Bounding Box
//////////////////////////////////////////////////////////////////////

// Module: bounding_box()
// Synopsis: Creates the smallest bounding box that contains all the children.
// Topics: Mutators, Bounds, Bounding Boxes
// See Also: pointlist_bounds()
// Usage:
//   bounding_box([excess],[planar]) CHILDREN;
// Description:
//   Returns the smallest axis-aligned square (or cube) shape that contains all the 2D (or 3D)
//   children given.  The module children() must 3d when planar=false and
//   2d when planar=true, or you will get a warning of mixing dimension
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


//////////////////////////////////////////////////////////////////////
// Section: Warp Mutators
//////////////////////////////////////////////////////////////////////


// Module: chain_hull()
// Synopsis: Performs the union of hull operations between consecutive pairs of children.
// Topics: Mutators
// See Also: hull()
// Usage:
//   chain_hull() CHILDREN;
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


// Module: path_extrude2d()
// Synopsis: Extrudes 2D children along a 2D path.
// Topics: Mutators, Extrusion 
// See Also: path_sweep(), path_extrude()
// Usage:
//   path_extrude2d(path, [caps=], [closed=], [s=], [convexity=]) 2D-CHILDREN;
// Description:
//   Extrudes 2D children along the given 2D path, with optional rounded endcaps.
//   It works by constructing straight sections corresponding to each segment of the path and inserting rounded joints at each corner.
//   If the children are symmetric across the Y axis line then you can set caps=true to produce rounded caps on the ends of the profile.
//   If you set caps to true for asymmetric children then incorrect caps will be generated.
// Arguments:
//   path = The 2D path to extrude the geometry along.
//   ---
//   caps = If true, caps each end of the path with a rounded copy of the children.  Children must by symmetric across the Y axis, or results are wrong.  Default: false
//   closed = If true, connect the starting point of the path to the ending point.  Default: false
//   convexity = The max number of times a line could pass though a wall.  Default: 10
//   s = Mask size to use.  Use a number larger than twice your object's largest axis.  If you make this too large, it messes with centering your view.  Default: The length of the diagonal of the path's bounding box.
// Example:
//   path = [
//       each right(50, p=arc(d=100,angle=[90,180])),
//       each left(50, p=arc(d=100,angle=[0,-90])),
//   ];
//   path_extrude2d(path,caps=false) {
//       fwd(2.5) square([5,6],center=true);
//       fwd(6) square([10,5],center=true);
//   }
// Example:
//   path_extrude2d(arc(d=100,angle=[180,270]),caps=true)
//       trapezoid(w1=10, w2=5, h=10, anchor=BACK);
// Example:
//   include <BOSL2/beziers.scad>
//   path = bezpath_curve([
//       [-50,0], [-25,50], [0,0], [50,0]
//   ]);
//   path_extrude2d(path, caps=false)
//       trapezoid(w1=10, w2=3, h=5, anchor=BACK);
// Example: Un-Closed Path
//   $fn=16;
//   spath = star(id=15,od=35,n=5);
//   path_extrude2d(spath, caps=false, closed=false)
//       move_copies([[-3.5,1.5],[0.0,3.0],[3.5,1.5]])
//           circle(r=1.5);
// Example: Complex Endcaps
//   $fn=16;
//   spath = star(id=15,od=35,n=5);
//   path_extrude2d(spath, caps=true, closed=false)
//       move_copies([[-3.5,1.5],[0.0,3.0],[3.5,1.5]])
//           circle(r=1.5);
module path_extrude2d(path, caps=false, closed=false, s, convexity=10) {
    extra_ang = 0.1; // Extra angle for overlap of joints
    check =
       assert(caps==false || closed==false, "Cannot have caps on a closed extrusion")
       assert(is_path(path,2));
    path = deduplicate(path);
    s = s!=undef? s :
        let(b = pointlist_bounds(path))
        norm(b[1]-b[0]);
    check2 = assert(is_finite(s));
    L = len(path);
    for (i = [0:1:L-(closed?1:2)]) {
        seg = select(path, i, i+1);
        segv = seg[1] - seg[0];
        seglen = norm(segv);
        translate((seg[0]+seg[1])/2) {
            rot(from=BACK, to=segv) {
                difference() {
                    xrot(90) {
                        linear_extrude(height=seglen, center=true, convexity=convexity) {
                            children();
                        }
                    }
                    if (closed || i>0) {
                        pt = select(path, i-1);
                        pang = v_theta(rot(from=-segv, to=RIGHT, p=pt - seg[0]));
                        fwd(seglen/2+0.01) zrot(pang/2) cube(s, anchor=BACK);
                    }
                    if (closed || i<L-2) {
                        pt = select(path, i+2);
                        pang = v_theta(rot(from=segv, to=RIGHT, p=pt - seg[1]));
                        back(seglen/2+0.01) zrot(pang/2) cube(s, anchor=FWD);
                    }
                }
            }
        }
    }
    for (t=triplet(path,wrap=closed)) {
        ang = -(180-vector_angle(t)) * sign(_point_left_of_line2d(t[2],[t[0],t[1]]));
        delt = point3d(t[2] - t[1]);
        if (ang!=0)
            translate(t[1]) {
                frame_map(y=delt, z=UP)
                    rotate(-sign(ang)*extra_ang/2)
                        rotate_extrude(angle=ang+sign(ang)*extra_ang)
                            if (ang<0)
                                right_half(planar=true) children();
                            else
                                left_half(planar=true) children();                          
            }
                
    }
    if (caps) {
        bseg = select(path,0,1);
        move(bseg[0])
            rot(from=BACK, to=bseg[0]-bseg[1])
                rotate_extrude(angle=180)
                    right_half(planar=true) children();
        eseg = select(path,-2,-1);
        move(eseg[1])
            rot(from=BACK, to=eseg[1]-eseg[0])
                rotate_extrude(angle=180)
                    right_half(planar=true) children();
    }
}


// Module: cylindrical_extrude()
// Synopsis: Extrudes 2D children outwards around a cylinder.
// Topics: Mutators, Extrusion, Rotation
// See Also: heightfield(), cylindrical_heightfield(), cyl()
// Usage:
//   cylindrical_extrude(ir|id=, or|od=, [size=], [convexity=], [spin=], [orient=]) 2D-CHILDREN;
// Description:
//   Extrudes its 2D children outwards, curved around a cylindrical shape.  Uses $fn/$fa/$fs to
//   control the faceting of the extrusion.  
// Arguments:
//   ir = The inner radius to extrude from.
//   or = The outer radius to extrude to.
//   ---
//   od = The outer diameter to extrude to.
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
module cylindrical_extrude(ir, or, od, id, size=1000, convexity=10, spin=0, orient=UP) {
    check1 = assert(is_num(size) || is_vector(size,2));
    size = is_num(size)? [size,size] : size;
    ir = get_radius(r=ir,d=id);
    or = get_radius(r=or,d=od);
    check2 = assert(all_positive([ir,or]), "Must supply positive inner and outer radius or diameter");
    index_r = or;
    circumf = 2 * PI * index_r;
    width = min(size.x, circumf);
    check3 = assert(width <= circumf, "Shape would more than completely wrap around.");
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
                                rect([quantup(step,pow(2,-15)),size.y]);
                            }
                        }
                    }
                }
            }
        }
    }
}


// Module: extrude_from_to()
// Extrudes 2D children between two points in 3D space.
// Topics: Extrusion, Mutators
// See Also: path_sweep(), path_extrude2d()
// Usage:
//   extrude_from_to(pt1, pt2, [convexity=], [twist=], [scale=], [slices=]) 2D-CHILDREN;
// Description:
//   Extrudes the 2D children linearly between the 3d points pt1 and pt2.  The origin of the 2D children are placed on
//   pt1 and pt2, and oriented perpendicular to the line between the points.  
// Arguments:
//   pt1 = starting point of extrusion.
//   pt2 = ending point of extrusion.
//   ---
//   convexity = max number of times a line could intersect a wall of the 2D shape being extruded.
//   twist = number of degrees to twist the 2D shape over the entire extrusion length.
//   scale = scale multiplier for end of extrusion compared the start.
//   slices = Number of slices along the extrusion to break the extrusion into.  Useful for refining `twist` extrusions.
// Example(FlatSpin,VPD=200,VPT=[0,0,15]):
//   extrude_from_to([0,0,0], [10,20,30], convexity=4, twist=360, scale=3.0, slices=40) {
//       xcopies(3) circle(3, $fn=32);
//   }
module extrude_from_to(pt1, pt2, convexity, twist, scale, slices) {
    check =
      assert(is_vector(pt1),"First point must be a vector")
      assert(is_vector(pt2),"Second point must be a vector");
    pt1 = point3d(pt1);
    pt2 = point3d(pt2);
    rtp = xyz_to_spherical(pt2-pt1);
    translate(pt1) {
        rotate([0, rtp[2], rtp[1]]) {
            if (rtp[0] > 0) {
                linear_extrude(height=rtp[0], convexity=convexity, center=false, slices=slices, twist=twist, scale=scale) {
                    children();
                }
            }
        }
    }
}



// Module: path_extrude()
// Synopsis: Extrudes 2D children along a 3D path.
// Topics: Paths, Extrusion, Mutators
// See Also: path_sweep(), path_extrude2d()
// Usage: path_extrude(path, [convexity], [clipsize]) 2D-CHILDREN;
// Description:
//   Extrudes 2D children along a 3D path.  This may be slow and can have problems with twisting.  
// Arguments:
//   path = Array of points for the bezier path to extrude along.
//   convexity = Maximum number of walls a ray can pass through.
//   clipsize = Increase if artifacts are left.  Default: 100
// Example(FlatSpin,VPD=600,VPT=[75,16,20]):
//   path = [ [0, 0, 0], [33, 33, 33], [66, 33, 40], [100, 0, 0], [150,0,0] ];
//   path_extrude(path) circle(r=10, $fn=6);
module path_extrude(path, convexity=10, clipsize=100) {
    rotmats = cumprod([
       for (i = idx(path,e=-2)) let(
           vec1 = i==0? UP : unit(path[i]-path[i-1], UP),
           vec2 = unit(path[i+1]-path[i], UP)
       ) rot(from=vec1,to=vec2)
    ]);
    // This adds a rotation midway between each item on the list
    interp = rot_resample(rotmats,n=2,method="count");
    epsilon = 0.0001;  // Make segments ever so slightly too long so they overlap.
    ptcount = len(path);
    for (i = [0:1:ptcount-2]) {
        pt1 = path[i];
        pt2 = path[i+1];
        dist = norm(pt2-pt1);
        T = rotmats[i];
        difference() {
            translate(pt1) {
                multmatrix(T) {
                    down(clipsize/2/2) {
                        if ((dist+clipsize/2) > 0) {
                            linear_extrude(height=dist+clipsize/2, convexity=convexity) {
                                children();
                            }
                        }
                    }
                }
            }
            translate(pt1) {
                hq = (i > 0)? interp[2*i-1] : T;
                multmatrix(hq) down(clipsize/2+epsilon) cube(clipsize, center=true);
            }
            translate(pt2) {
                hq = (i < ptcount-2)? interp[2*i+1] : T;
                multmatrix(hq) up(clipsize/2+epsilon) cube(clipsize, center=true);
            }
        }
    }
}




//////////////////////////////////////////////////////////////////////
// Section: Offset Mutators
//////////////////////////////////////////////////////////////////////

// Module: minkowski_difference()
// Synopsis: Removes diff shapes from base shape surface.
// Topics: Mutators
// See Also: offset3d()
// Usage:
//   minkowski_difference() { BASE; DIFF1; DIFF2; ... }
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




// Module: offset3d()
// Synopsis: Expands or contracts the surface of a 3D object.
// Topics: Mutators
// See Also: minkowski_difference(), round3d()
// Usage:
//   offset3d(r, [size], [convexity]) CHILDREN;
// Description:
//   Expands or contracts the surface of a 3D object by a given amount.  This is very, very slow.
//   No really, this is unbearably slow.  It uses `minkowski()`.  Use this as a last resort.
//   This is so slow that no example images will be rendered.
// Arguments:
//   r = Radius to expand object by.  Negative numbers contract the object. 
//   size = Maximum size of object to be contracted, given as a scalar.  Default: 100
//   convexity = Max number of times a line could intersect the walls of the object.  Default: 10
module offset3d(r, size=100, convexity=10) {
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
// Synopsis: Rounds arbitrary 3d objects.
// Topics: Rounding, Mutators
// See Also: offset3d(), minkowski_difference()
// Usage:
//   round3d(r) CHILDREN;
//   round3d(or) CHILDREN;
//   round3d(ir) CHILDREN;
//   round3d(or, ir) CHILDREN;
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



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
