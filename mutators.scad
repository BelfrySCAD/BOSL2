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
//   half_of(v, [cp], [s], [planar]) ...
// Usage: as function
//   result = half_of(p,v,[cp]);
//
// Description:
//   Slices an object at a cut plane, and masks away everything that is on one side.  The v parameter is either a plane specification or
//   a normal vector.  The s parameter is needed for the module
//   version to control the size of the masking cube.  If s is too large then the preview display will flip around and display the
//   wrong half, but if it is too small it won't fully mask your model.  
//   When called as a function, you must supply a vnf, path or region in p.  If planar is set to true for the module version the operation
//   is performed in 2D and UP and DOWN are treated as equivalent to BACK and FWD respectively.
//
// Arguments:
//   p = path, region or VNF to slice.  (Function version)
//   v = Normal of plane to slice at.  Keeps everything on the side the normal points to.  Default: [0,0,1] (UP)
//   cp = If given as a scalar, moves the cut plane along the normal by the given amount.  If given as a point, specifies a point on the cut plane.  Default: [0,0,0]
//   s = Mask size to use.  Use a number larger than twice your object's largest axis.  If you make this too large, OpenSCAD's preview rendering may display the wrong half.  (Module version)  Default: 100
//   planar = If true, perform a 2D operation.  When planar, a `v` of `UP` or `DOWN` becomes equivalent of `BACK` and `FWD` respectively.  (Module version).  Default: false.  
//
// Examples:
//   half_of(DOWN+BACK, cp=[0,-10,0]) cylinder(h=40, r1=10, r2=0, center=false);
//   half_of(DOWN+LEFT, s=200) sphere(d=150);
// Example(2D):
//   half_of([1,1], planar=true) circle(d=50);
module half_of(v=UP, cp, s=100, planar=false)
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

function half_of(p, v=UP, cp) =
    is_vnf(p) ?
       assert(is_vector(v) && (len(v)==3 || len(v)==4),str("Must give 3-vector or plane specification",v))
       assert(select(v,0,2)!=[0,0,0], "vector v must be nonzero")
       let(
            plane = is_vector(v,4) ? assert(cp==undef, "Don't use cp with plane definition.") v
                  : is_undef(cp) ? [each v, 0]
                  : is_num(cp) ? [each v, cp*(v*v)/norm(v)]
                  : assert(is_vector(cp,3),"Centerpoint must be a 3-vector")
                    [each v, cp*v]
       )
       vnf_halfspace(plane, p)
   : is_path(p) || is_region(p) ?
      let(
          v = (v==UP)? BACK : (v==DOWN)? FWD : v,
          cp = is_undef(cp) ? [0,0]
             : is_num(cp) ? v*cp
             : assert(is_vector(cp,2) || (is_vector(cp,3) && cp.z==0),"Centerpoint must be 2-vector")
               cp
      )
      assert(is_vector(v,2) || (is_vector(v,3) && v.z==0),"Must give 2-vector")
      assert(!all_zero(v), "Vector v must be nonzero")
      let(
          bounds = pointlist_bounds(move(-cp,p)),
          L = 2*max(flatten(bounds)),
          n = unit(v),
          u = [-n.y,n.x],
          box = [cp+u*L, cp+(v+u)*L, cp+(v-u)*L, cp-u*L]
      )
      intersection(box,p)
   : assert(false, "Input must be a region, path or VNF");



/*  This code cut 3d paths but leaves behind connecting line segments
    is_path(p) ?
        //assert(len(p[0]) == d, str("path must have dimension ", d))
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
*/


// Function&Module: left_half()
//
// Usage: as module
//   left_half([s], [x]) ...
//   left_half(planar=true, [s], [x]) ...
// Usage: as function
//   result = left_half(p, [x]);
//
// Description:
//   Slices an object at a vertical Y-Z cut plane, and masks away everything that is right of it.
//   The s parameter is needed for the module
//   version to control the size of the masking cube.  If s is too large then the preview display will flip around and display the
//   wrong half, but if it is too small it won't fully mask your model.  
//
// Arguments:
//   p = VNF, region or path to slice (function version)
//   s = Mask size to use.  Use a number larger than twice your object's largest axis.  If you make this too large, OpenSCAD's preview rendering may display the wrong half.  (Module version)  Default: 100
//   x = The X coordinate of the cut-plane.  Default: 0
//   planar = If true, perform a 2D operation.  (Module version)  Default: false. 
// Examples:
//   left_half() sphere(r=20);
//   left_half(x=-8) sphere(r=20);
// Example(2D):
//   left_half(planar=true) circle(r=20);
module left_half(s=100, x=0, planar=false)
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
function left_half(p,x=0) = half_of(p, LEFT, [x,0,0]);



// Function&Module: right_half()
//
// Usage: as module
//   right_half([s], [x]) ...
//   right_half(planar=true, [s], [x]) ...
// Usage: as function
//   result = right_half(p, [x]);
//
// Description:
//   Slices an object at a vertical Y-Z cut plane, and masks away everything that is left of it.
//   The s parameter is needed for the module
//   version to control the size of the masking cube.  If s is too large then the preview display will flip around and display the
//   wrong half, but if it is too small it won't fully mask your model.  
// Arguments:
//   p = VNF, region or path to slice (function version)
//   s = Mask size to use.  Use a number larger than twice your object's largest axis.  If you make this too large, OpenSCAD's preview rendering may display the wrong half.  (Module version)  Default: 100
//   x = The X coordinate of the cut-plane.  Default: 0
//   planar = If true, perform a 2D operation.  (Module version)  Default: false. 
// Examples(FlatSpin,VPD=175):
//   right_half() sphere(r=20);
//   right_half(x=-5) sphere(r=20);
// Example(2D):
//   right_half(planar=true) circle(r=20);
module right_half(s=100, x=0, planar=false)
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
function right_half(p,x=0) = half_of(p, RIGHT, [x,0,0]);



// Function&Module: front_half()
//
// Usage:
//   front_half([s], [y]) ...
//   front_half(planar=true, [s], [y]) ...
// Usage: as function
//   result = front_half(p, [y]);
//
// Description:
//   Slices an object at a vertical X-Z cut plane, and masks away everything that is behind it.
//   The s parameter is needed for the module
//   version to control the size of the masking cube.  If s is too large then the preview display will flip around and display the
//   wrong half, but if it is too small it won't fully mask your model.  
// Arguments:
//   p = VNF, region or path to slice (function version)
//   s = Mask size to use.  Use a number larger than twice your object's largest axis.  If you make this too large, OpenSCAD's preview rendering may display the wrong half.  (Module version)  Default: 100
//   y = The Y coordinate of the cut-plane.  Default: 0
//   planar = If true, perform a 2D operation.  (Module version)  Default: false. 
// Examples(FlatSpin,VPD=175):
//   front_half() sphere(r=20);
//   front_half(y=5) sphere(r=20);
// Example(2D):
//   front_half(planar=true) circle(r=20);
module front_half(s=100, y=0, planar=false)
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
function front_half(p,y=0) = half_of(p, FRONT, [0,y,0]);



// Function&Module: back_half()
//
// Usage:
//   back_half([s], [y]) ...
//   back_half(planar=true, [s], [y]) ...
// Usage: as function
//   result = back_half(p, [y]);
//
// Description:
//   Slices an object at a vertical X-Z cut plane, and masks away everything that is in front of it.
//   The s parameter is needed for the module
//   version to control the size of the masking cube.  If s is too large then the preview display will flip around and display the
//   wrong half, but if it is too small it won't fully mask your model.  
// Arguments:
//   p = VNF, region or path to slice (function version)
//   s = Mask size to use.  Use a number larger than twice your object's largest axis.  If you make this too large, OpenSCAD's preview rendering may display the wrong half.  (Module version)  Default: 100
//   y = The Y coordinate of the cut-plane.  Default: 0
//   planar = If true, perform a 2D operation.  (Module version)  Default: false. 
// Examples:
//   back_half() sphere(r=20);
//   back_half(y=8) sphere(r=20);
// Example(2D):
//   back_half(planar=true) circle(r=20);
module back_half(s=100, y=0, planar=false)
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
function back_half(p,y=0) = half_of(p, BACK, [0,y,0]);



// Function&Module: bottom_half()
//
// Usage:
//   bottom_half([s], [z]) ...
// Usage: as function
//   result = bottom_half(p, [z]);
//
// Description:
//   Slices an object at a horizontal X-Y cut plane, and masks away everything that is above it.
//   The s parameter is needed for the module
//   version to control the size of the masking cube.  If s is too large then the preview display will flip around and display the
//   wrong half, but if it is too small it won't fully mask your model. 
// Arguments:
//   p = VNF, region or path to slice (function version)
//   s = Mask size to use.  Use a number larger than twice your object's largest axis.  If you make this too large, OpenSCAD's preview rendering may display the wrong half.  (Module version)  Default: 100
//   z = The Z coordinate of the cut-plane.  Default: 0
// Examples:
//   bottom_half() sphere(r=20);
//   bottom_half(z=-10) sphere(r=20);
module bottom_half(s=100, z=0)
{
    dir = DOWN;
    difference() {
        children();
        translate([0,0,z]-dir*s/2) {
            cube(s, center=true);
        }
    }
}
function bottom_half(p,z=0) = half_of(p,BOTTOM,[0,0,z]);



// Function&Module: top_half()
//
// Usage:
//   top_half([s], [z]) ...
//   result = top_half(p, [z]);
//
// Description:
//   Slices an object at a horizontal X-Y cut plane, and masks away everything that is below it.
//   The s parameter is needed for the module
//   version to control the size of the masking cube.  If s is too large then the preview display will flip around and display the
//   wrong half, but if it is too small it won't fully mask your model.  
// Arguments:
//   p = VNF, region or path to slice (function version)
//   s = Mask size to use.  Use a number larger than twice your object's largest axis.  If you make this too large, OpenSCAD's preview rendering may display the wrong half.  (Module version)  Default: 100
//   z = The Z coordinate of the cut-plane.  Default: 0
// Examples(Spin,VPD=175):
//   top_half() sphere(r=20);
//   top_half(z=5) sphere(r=20);
module top_half(s=100, z=0)
{
    dir = UP;
    difference() {
        children();
        translate([0,0,z]-dir*s/2) {
            cube(s, center=true);
        }
    }
}
function top_half(p,z=0) = half_of(p,UP,[0,0,z]);



//////////////////////////////////////////////////////////////////////
// Section: Warp Mutators
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


// Module: path_extrude2d()
// Usage:
//   path_extrude2d(path, [caps], [closed]) {...}
// Description:
//   Extrudes 2D children along the given 2D path, with optional rounded endcaps.
//   It works by constructing straight sections corresponding to each segment of the path and inserting rounded joints at each corner.
//   If the children are symmetric across the Y axis line then you can set caps=true to produce rounded caps on the ends of the profile.
//   If you set caps to true for asymmetric children then incorrect caps will be generated.
// Arguments:
//   path = The 2D path to extrude the geometry along.
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
//   path = bezier_path([
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
    assert(caps==false || closed==false, "Cannot have caps on a closed extrusion");
    assert(is_path(path,2));
    path = deduplicate(path);
    s = s!=undef? s :
        let(b = pointlist_bounds(path))
        norm(b[1]-b[0]);
    assert(is_finite(s));
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
// Description:
//   Extrudes a 2D shape between the 3d points pt1 and pt2.  Takes as children a set of 2D shapes to extrude.
// Arguments:
//   pt1 = starting point of extrusion.
//   pt2 = ending point of extrusion.
//   convexity = max number of times a line could intersect a wall of the 2D shape being extruded.
//   twist = number of degrees to twist the 2D shape over the entire extrusion length.
//   scale = scale multiplier for end of extrusion compared the start.
//   slices = Number of slices along the extrusion to break the extrusion into.  Useful for refining `twist` extrusions.
// Example(FlatSpin,VPD=200,VPT=[0,0,15]):
//   extrude_from_to([0,0,0], [10,20,30], convexity=4, twist=360, scale=3.0, slices=40) {
//       xcopies(3) circle(3, $fn=32);
//   }
module extrude_from_to(pt1, pt2, convexity, twist, scale, slices) {
    assert(is_vector(pt1));
    assert(is_vector(pt2));
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



// Module: spiral_sweep()
// Description:
//   Takes a closed 2D polygon path, centered on the XY plane, and sweeps/extrudes it along a 3D spiral path
//   of a given radius, height and twist.  The origin in the profile traces out the helix of the specified radius.
//   If twist is positive the path will be right-handed;  if twist is negative the path will be left-handed.
//   .
//   Higbee specifies tapering applied to the ends of the extrusion and is given as the linear distance
//   over which to taper.  
// Arguments:
//   poly = Array of points of a polygon path, to be extruded.
//   h = height of the spiral to extrude along.
//   r = Radius of the spiral to extrude along. Default: 50
//   twist = number of degrees of rotation to spiral up along height.
//   ---
//   d = Diameter of the spiral to extrude along.
//   higbee = Length to taper thread ends over.
//   higbee1 = Taper length at start
//   higbee2 = Taper length at end
//   internal = direction to taper the threads with higbee.  If true threads taper outward; if false they taper inward.   Default: false
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   center = If given, overrides `anchor`.  A true value sets `anchor=CENTER`, false sets `anchor=BOTTOM`.
// Example:
//   poly = [[-10,0], [-3,-5], [3,-5], [10,0], [0,-30]];
//   spiral_sweep(poly, h=200, r=50, twist=1080, $fn=36);
module spiral_sweep(poly, h, r, twist=360, higbee, center, r1, r2, d, d1, d2, higbee1, higbee2, internal=false, anchor, spin=0, orient=UP) {
    higsample = 10;         // Oversample factor for higbee tapering
    dummy1=assert(is_num(twist) && twist != 0);
    bounds = pointlist_bounds(poly);
    yctr = (bounds[0].y+bounds[1].y)/2;
    xmin = bounds[0].x;
    xmax = bounds[1].x;
    poly = path3d(clockwise_polygon(poly));
    anchor = get_anchor(anchor,center,BOT,BOT);
    r1 = get_radius(r1=r1, r=r, d1=d1, d=d, dflt=50);
    r2 = get_radius(r1=r2, r=r, d1=d2, d=d, dflt=50);
    sides = segs(max(r1,r2));
    dir = sign(twist);
    ang_step = 360/sides*dir;
    anglist = [for(ang = [0:ang_step:twist-EPSILON]) ang,
               twist];
    higbee1 = first_defined([higbee1, higbee, 0]);
    higbee2 = first_defined([higbee2, higbee, 0]);
    higang1 = 360 * higbee1 / (2 * r1 * PI);
    higang2 = 360 * higbee2 / (2 * r2 * PI);
    dummy2=assert(higbee1>=0 && higbee2>=0)
           assert(higang1 < dir*twist/2,"Higbee1 is more than half the threads")
           assert(higang2 < dir*twist/2,"Higbee2 is more than half the threads");
    function polygon_r(N,theta) =
        let( alpha = 360/N )
        cos(alpha/2)/(cos(posmod(theta,alpha)-alpha/2));
    higofs = pow(0.05,2);   // Smallest hig scale is the square root of this value
    function taperfunc(x) = sqrt((1-higofs)*x+higofs);
    interp_ang = [
                  for(i=idx(anglist,e=-2))
                      each lerpn(anglist[i],anglist[i+1],
                                 (higang1>0 && higang1>dir*anglist[i+1]
                                  || (higang2>0 && higang2>dir*(twist-anglist[i]))) ? ceil((anglist[i+1]-anglist[i])/ang_step*higsample)
                                                                                    : 1,
                                 endpoint=false),
                  last(anglist)
                 ];
    skewmat = affine3d_skew_xz(xa=atan2(r2-r1,h));
    points = [
        for (a = interp_ang) let (
            hsc = dir*a<higang1 ? taperfunc(dir*a/higang1)
                : dir*(twist-a)<higang2 ? taperfunc(dir*(twist-a)/higang2)
                : 1,
            u = a/twist,
            r = lerp(r1,r2,u),
            mat = affine3d_zrot(a)
                * affine3d_translate([polygon_r(sides,a)*r, 0, h * (u-0.5)])
                * affine3d_xrot(90)
                * skewmat
                * scale([hsc,lerp(hsc,1,0.25),1], cp=[internal ? xmax : xmin, yctr, 0]),
            pts = apply(mat, poly)
        ) pts
    ];

    vnf = vnf_vertex_array(
        points, col_wrap=true, caps=true, reverse=dir>0?true:false, 
        style=higbee1>0 || higbee2>0 ? "quincunx" : "alt"
    );

    attachable(anchor,spin,orient, r1=r1, r2=r2, l=h) {
        vnf_polyhedron(vnf, convexity=ceil(2*dir*twist/360));
        children();
    }
}



// Module: path_extrude()
// Description:
//   Extrudes 2D children along a 3D path.  This may be slow.
// Arguments:
//   path = Array of points for the bezier path to extrude along.
//   convexity = Maximum number of walls a ray can pass through.
//   clipsize = Increase if artifacts are left.  Default: 100
// Example(FlatSpin,VPD=600,VPT=[75,16,20]):
//   path = [ [0, 0, 0], [33, 33, 33], [66, 33, 40], [100, 0, 0], [150,0,0] ];
//   path_extrude(path) circle(r=10, $fn=6);
module path_extrude(path, convexity=10, clipsize=100) {
    function polyquats(path, q=q_ident(), v=[0,0,1], i=0) = let(
            v2 = path[i+1] - path[i],
            ang = vector_angle(v,v2),
            axis = ang>0.001? unit(cross(v,v2)) : [0,0,1],
            newq = q_mul(quat(axis, ang), q),
            dist = norm(v2)
        ) i < (len(path)-2)?
            concat([[dist, newq, ang]], polyquats(path, newq, v2, i+1)) :
            [[dist, newq, ang]];

    epsilon = 0.0001;  // Make segments ever so slightly too long so they overlap.
    ptcount = len(path);
    pquats = polyquats(path);
    for (i = [0:1:ptcount-2]) {
        pt1 = path[i];
        pt2 = path[i+1];
        dist = pquats[i][0];
        q = pquats[i][1];
        difference() {
            translate(pt1) {
                q_rot(q) {
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
                hq = (i > 0)? q_slerp(q, pquats[i-1][1], 0.5) : q;
                q_rot(hq) down(clipsize/2+epsilon) cube(clipsize, center=true);
            }
            translate(pt2) {
                hq = (i < ptcount-2)? q_slerp(q, pquats[i+1][1], 0.5) : q;
                q_rot(hq) up(clipsize/2+epsilon) cube(clipsize, center=true);
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
    assert(s>=0 && s<=1)
    assert(v>=0 && v<=1)
    let(
        h = posmod(h,360),
        c = v * s,
        hprime = h/60,
        x = c * (1- abs(hprime % 2 - 1)),
        rgbprime = hprime <=1 ? [c,x,0]
                 : hprime <=2 ? [x,c,0]
                 : hprime <=3 ? [0,c,x]
                 : hprime <=4 ? [0,x,c]
                 : hprime <=5 ? [x,0,c]
                 : hprime <=6 ? [c,0,x]
                 : [0,0,0],
        m=v-c
    )
    rgbprime+[m,m,m];

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
//   maxhues = max number of hues to use (to prevent lots of indistinguishable hues)
//   shuffle = if true then shuffle the hues in a random order.  Default: false
//   seed = seed to use for shuffle
// Side Effects:
//   Sets the color to progressive values along the ROYGBIV spectrum for each item.
//   Sets `$idx` to the index of the current item in `list` that we want to show.
//   Sets `$item` to the current item in `list` that we want to show.
// Example(2D):
//   rainbow(["Foo","Bar","Baz"]) fwd($idx*10) text(text=$item,size=8,halign="center",valign="center");
// Example(2D):
//   rgn = [circle(d=45,$fn=3), circle(d=75,$fn=4), circle(d=50)];
//   rainbow(rgn) stroke($item, closed=true);
module rainbow(list, stride=1, maxhues, shuffle=false, seed)
{
    ll = len(list);
    maxhues = first_defined([maxhues,ll]);
    huestep = 360 / maxhues;
    huelist = [for (i=[0:1:ll-1]) posmod(i*huestep+i*360/stride,360)];
    hues = shuffle ? shuffle(huelist, seed=seed) : huelist;
    for($idx=idx(list)) {
        $item = list[$idx];
        HSV(h=hues[$idx]) children();
    }
}


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
