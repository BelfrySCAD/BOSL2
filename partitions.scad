//////////////////////////////////////////////////////////////////////
// LibFile: partitions.scad
//   Cut objects with a plane, or partition them into interlocking pieces for easy printing of large objects. 
// Includes:
//   include <BOSL2/std.scad>
// FileGroup: Basic Modeling
// FileSummary: Cut objects with a plane or partition them into interlocking pieces.
// FileFootnotes: STD=Included in std.scad
//////////////////////////////////////////////////////////////////////


// Section: Planar Cutting

// Function&Module: half_of()
// Synopsis: Masks half of an object at a cut plane.
// SynTags: Geom, VNF, Path, Region
// Topics: Partitions, Masking
// See Also: back_half(), front_half(), left_half(), right_half(), top_half(), bottom_half(), intersection()
//
// Usage: as module
//   half_of(v, [cp], [s], [planar]) CHILDREN;
// Usage: as function
//   result = half_of(p,v,[cp]);
//
// Description:
//   Slices an object at a cut plane, and masks away everything that is on one side.  The v parameter
//   is either a plane specification or a normal vector.  The `s` parameter is needed for the module
//   version to control the size of the masking cube.  If `s` is too large then the preview display
//   will flip around and display the wrong half, but if it is too small it won't fully mask your
//   model.  When called as a function, you must supply a vnf, path or region in p.  If planar is set
//   to true for the module version the operation is performed in 2D and UP and DOWN are treated as
//   equivalent to BACK and FWD respectively.
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
    req_children($children);
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
          v=unit(v), 
          bounds = pointlist_bounds(is_region(p)?flatten(p):p),
          L = 2*max(norm(bounds[0]-cp), norm(bounds[1]-cp)),
          u = [-v.y,v.x],
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
// Synopsis: Masks the right half of an object along the Y-Z plane, leaving the left half.
// SynTags: Geom, VNF, Path, Region
// Topics: Partitions, Masking
// See Also: back_half(), front_half(), right_half(), top_half(), bottom_half(), half_of(), intersection()
//
// Usage: as module
//   left_half([s], [x]) CHILDREN;
//   left_half(planar=true, [s], [x]) CHILDREN;
// Usage: as function
//   result = left_half(p, [x]);
//
// Description:
//   Slices an object at a vertical Y-Z cut plane, and masks away everything that is right of it.
//   The `s` parameter is needed for the module version to control the size of the masking cube.
//   If `s` is too large then the preview display will flip around and display the wrong half,
//   but if it is too small it won't fully mask your model.  
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
    req_children($children);
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
// SynTags: Geom, VNF, Path, Region
// Synopsis: Masks the left half of an object along the Y-Z plane, leaving the right half.
// Topics: Partitions, Masking
// See Also: back_half(), front_half(), left_half(), top_half(), bottom_half(), half_of(), intersection()
//
// Usage: as module
//   right_half([s=], [x=]) CHILDREN;
//   right_half(planar=true, [s=], [x=]) CHILDREN;
// Usage: as function
//   result = right_half(p, [x=]);
//
// Description:
//   Slices an object at a vertical Y-Z cut plane, and masks away everything that is left of it.
//   The `s` parameter is needed for the module version to control the size of the masking cube.
//   If `s` is too large then the preview display will flip around and display the wrong half,
//   but if it is too small it won't fully mask your model.  
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
// Synopsis: Masks the back half of an object along the X-Z plane, leaving the front half.
// SynTags: Geom, VNF, Path, Region
// Topics: Partitions, Masking
// See Also: back_half(), left_half(), right_half(), top_half(), bottom_half(), half_of(), intersection()
//
// Usage:
//   front_half([s], [y]) CHILDREN;
//   front_half(planar=true, [s], [y]) CHILDREN;
// Usage: as function
//   result = front_half(p, [y]);
//
// Description:
//   Slices an object at a vertical X-Z cut plane, and masks away everything that is behind it.
//   The `s` parameter is needed for the module version to control the size of the masking cube.
//   If `s` is too large then the preview display will flip around and display the wrong half,
//   but if it is too small it won't fully mask your model.  
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
    req_children($children);
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
// Synopsis: Masks the front half of an object along the X-Z plane, leaving the back half.
// SynTags: Geom, VNF, Path, Region
// Topics: Partitions, Masking
// See Also: front_half(), left_half(), right_half(), top_half(), bottom_half(), half_of(), intersection()
//
// Usage:
//   back_half([s], [y]) CHILDREN;
//   back_half(planar=true, [s], [y]) CHILDREN;
// Usage: as function
//   result = back_half(p, [y]);
//
// Description:
//   Slices an object at a vertical X-Z cut plane, and masks away everything that is in front of it.
//   The `s` parameter is needed for the module version to control the size of the masking cube.
//   If `s` is too large then the preview display will flip around and display the wrong half,
//   but if it is too small it won't fully mask your model.  
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
    req_children($children);
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
// Synopsis: Masks the top half of an object along the X-Y plane, leaving the bottom half.
// SynTags: Geom, VNF, Path, Region
// Topics: Partitions, Masking
// See Also: back_half(), front_half(), left_half(), right_half(), top_half(), half_of(), intersection()
//
// Usage:
//   bottom_half([s], [z]) CHILDREN;
// Usage: as function
//   result = bottom_half(p, [z]);
//
// Description:
//   Slices an object at a horizontal X-Y cut plane, and masks away everything that is above it.
//   The `s` parameter is needed for the module version to control the size of the masking cube.
//   If `s` is too large then the preview display will flip around and display the wrong half,
//   but if it is too small it won't fully mask your model. 
// Arguments:
//   p = VNF, region or path to slice (function version)
//   s = Mask size to use.  Use a number larger than twice your object's largest axis.  If you make this too large, OpenSCAD's preview rendering may display the wrong half.  (Module version)  Default: 100
//   z = The Z coordinate of the cut-plane.  Default: 0
// Examples:
//   bottom_half() sphere(r=20);
//   bottom_half(z=-10) sphere(r=20);
module bottom_half(s=100, z=0)
{
    req_children($children);
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
// Synopsis: Masks the bottom half of an object along the X-Y plane, leaving the top half.
// SynTags: Geom, VNF, Path, Region
// Topics: Partitions, Masking
// See Also: back_half(), front_half(), left_half(), right_half(), bottom_half(), half_of(), intersection()
//
// Usage: as module
//   top_half([s], [z]) CHILDREN;
// Usage: as function
//   result = top_half(p, [z]);
//
// Description:
//   Slices an object at a horizontal X-Y cut plane, and masks away everything that is below it.
//   The `s` parameter is needed for the module version to control the size of the masking cube.
//   If `s` is too large then the preview display will flip around and display the wrong half,
//   but if it is too small it won't fully mask your model.  
// Arguments:
//   p = VNF, region or path to slice (function version)
//   s = Mask size to use.  Use a number larger than twice your object's largest axis.  If you make this too large, OpenSCAD's preview rendering may display the wrong half.  (Module version)  Default: 100
//   z = The Z coordinate of the cut-plane.  Default: 0
// Examples(Spin,VPD=175):
//   top_half() sphere(r=20);
//   top_half(z=5) sphere(r=20);
module top_half(s=100, z=0)
{
    req_children($children);
    dir = UP;
    difference() {
        children();
        translate([0,0,z]-dir*s/2) {
            cube(s, center=true);
        }
    }
}
function top_half(p,z=0) = half_of(p,UP,[0,0,z]);



// Section: Partioning into Interlocking Pieces


function _partition_subpath(type) =
    type=="flat"?  [[0,0],[1,0]] :
    type=="sawtooth"? [[0,-0.5], [0.5,0.5], [1,-0.5]] :
    type=="sinewave"? [for (a=[0:5:360]) [a/360,sin(a)/2]] :
    type=="comb"?   let(dx=0.5*sin(2))  [[0,0],[0+dx,0.5],[0.5-dx,0.5],[0.5+dx,-0.5],[1-dx,-0.5],[1,0]] :
    type=="finger"? let(dx=0.5*sin(20)) [[0,0],[0+dx,0.5],[0.5-dx,0.5],[0.5+dx,-0.5],[1-dx,-0.5],[1,0]] :
    type=="dovetail"? [[0,-0.5], [0.3,-0.5], [0.2,0.5], [0.8,0.5], [0.7,-0.5], [1,-0.5]] :
    type=="hammerhead"? [[0,-0.5], [0.35,-0.5], [0.35,0], [0.15,0], [0.15,0.5], [0.85,0.5], [0.85,0], [0.65,0], [0.65,-0.5],[1,-0.5]] :
    type=="jigsaw"? concat(
                        arc(r=5/16, cp=[0,-3/16],  start=270, angle=125),
                        arc(r=5/16, cp=[1/2,3/16], start=215, angle=-250),
                        arc(r=5/16, cp=[1,-3/16],  start=145, angle=125)
                    ) :
    assert(false, str("Unsupported cutpath type: ", type));


function _partition_cutpath(l, h, cutsize, cutpath, gap, cutpath_centered) =
    let(
        check = assert(is_finite(l))
            assert(is_finite(h))
            assert(is_finite(gap))
            assert(is_finite(cutsize) || is_vector(cutsize,2))
            assert(is_string(cutpath) || is_path(cutpath,2)),
        cutsize = is_vector(cutsize)? cutsize : [cutsize*2, cutsize],
        cutpath = is_path(cutpath)? cutpath :
            _partition_subpath(cutpath),
        reps_raw = ceil(l/(cutsize.x+gap)),
        reps = reps_raw%2==0 && cutpath_centered ? reps_raw+1 : reps_raw,
        cplen = (cutsize.x+gap) * reps,
        path = deduplicate(concat(
            [[-l/2, cutpath[0].y*cutsize.y]],
            [for (i=[0:1:reps-1], pt=cutpath) v_mul(pt,cutsize)+[i*(cutsize.x+gap)+gap/2-cplen/2,0]],
            [[ l/2, cutpath[len(cutpath)-1].y*cutsize.y]]
        )),
        stidxs = [for (i = idx(path)) if (path[i].x < -l/2) i],
        enidxs = [for (i = idx(path)) if (path[i].x > +l/2) i],
        stidx = stidxs? last(stidxs) : 0,
        enidx = enidxs? enidxs[0] : -1,
        trunc = select(path, stidx, enidx)
    ) trunc;


// Module: partition_mask()
// Synopsis: Creates a mask to remove half an object with the remaining half suitable for reassembly.
// SynTags: Geom
// Topics: Partitions, Masking, Paths
// See Also: partition_cut_mask(), partition(), dovetail()
// Usage:
//   partition_mask(l, w, h, [cutsize], [cutpath], [gap], [inverse], [$slop=], [anchor=], [spin=], [orient=]) [ATTACHMENTS];
// Description:
//   Creates a mask that you can use to difference or intersect with an object to remove half of it,
//   leaving behind a side designed to allow assembly of the sub-parts.
// Arguments:
//   l = The length of the cut axis.  
//   w = The width of the part to be masked, back from the cut plane.
//   h = The height of the part to be masked.
//   cutsize = The width of the cut pattern to be used.
//   cutpath = The cutpath to use.  Standard named paths are "flat", "sawtooth", "sinewave", "comb", "finger", "dovetail", "hammerhead", and "jigsaw".  Alternatively, you can give a cutpath as a 2D path, where X is between 0 and 1, and Y is between -0.5 and 0.5.
//   gap = Empty gaps between cutpath iterations.  Default: 0
//   cutpath_centered = Ensures the cutpath is always centered.  Default: true
//   inverse = If true, create a cutpath that is meant to mate to a non-inverted cutpath.
//   spin = Rotate this many degrees around the Z axis.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   $slop = The amount to shrink the mask by, to correct for printer-specific fitting.
// Examples:
//   partition_mask(w=50, gap=0, cutpath="jigsaw");
//   partition_mask(w=50, gap=10, cutpath="jigsaw");
//   partition_mask(w=50, gap=10, cutpath="jigsaw", inverse=true);
//   partition_mask(w=50, gap=10, cutsize=4, cutpath="jigsaw");
//   partition_mask(w=50, gap=10, cutsize=4, cutpath="jigsaw", cutpath_centered=false);
//   partition_mask(w=50, gap=10, cutsize=[4,20], cutpath="jigsaw");
// Examples(2D):
//   partition_mask(w=20, cutpath="sawtooth");
//   partition_mask(w=20, cutpath="sinewave");
//   partition_mask(w=20, cutpath="comb");
//   partition_mask(w=20, cutpath="finger");
//   partition_mask(w=20, cutpath="dovetail");
//   partition_mask(w=20, cutpath="hammerhead");
//   partition_mask(w=20, cutpath="jigsaw");
module partition_mask(l=100, w=100, h=100, cutsize=10, cutpath="jigsaw", gap=0, cutpath_centered=true, inverse=false, anchor=CENTER, spin=0, orient=UP)
{
    cutsize = is_vector(cutsize)? point2d(cutsize) : [cutsize*2, cutsize];
    path = _partition_cutpath(l, h, cutsize, cutpath, gap, cutpath_centered);
    midpath = select(path,1,-2);
    sizepath = concat([path[0]+[-get_slop(),0]], midpath, [last(path)+[get_slop(),0]], [[+(l/2+get_slop()), (w+get_slop())*(inverse?-1:1)], [-(l/2+get_slop()), (w+get_slop())*(inverse?-1:1)]]);
    bnds = pointlist_bounds(sizepath);
    fullpath = concat(path, [[last(path).x, w*(inverse?-1:1)], [path[0].x, w*(inverse?-1:1)]]);
    attachable(anchor,spin,orient, size=point3d(bnds[1]-bnds[0],h)) {
        linear_extrude(height=h, center=true, convexity=10) {
            intersection() {
                offset(delta=-get_slop()) polygon(fullpath);
                square([l, w*2], center=true);
            }
        }
        children();
    }
}


// Module: partition_cut_mask()
// Synopsis: Creates a mask to cut an object into two subparts that can be reassembled.
// SynTags: Geom
// Topics: Partitions, Masking, Paths
// See Also: partition_mask(), partition(), dovetail()
// Usage:
//   partition_cut_mask(l, [cutsize], [cutpath], [gap], [inverse], [$slop=], [anchor=], [spin=], [orient=]) [ATTACHMENTS];
// Description:
//   Creates a mask that you can use to difference with an object to cut it into two sub-parts that can be assembled.
//   The `$slop` value is important to get the proper fit and should probably be smaller than 0.2.  The examples below
//   use larger values to make the mask easier to see.  
// Arguments:
//   l = The length of the cut axis.
//   h = The height of the part to be masked.
//   cutsize = The width of the cut pattern to be used.  Default: 10
//   cutpath = The cutpath to use.  Standard named paths are "flat", "sawtooth", "sinewave", "comb", "finger", "dovetail", "hammerhead", and "jigsaw".  Alternatively, you can give a cutpath as a 2D path, where X is between 0 and 1, and Y is between -0.5 and 0.5.  Default: "jigsaw"
//   gap = Empty gaps between cutpath iterations.  Default: 0
//   cutpath_centered = Ensures the cutpath is always centered.  Default: true
//   spin = Rotate this many degrees around the Z axis.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   $slop = The width of the cut mask, to correct for printer-specific fitting. 
// Examples:
//   partition_cut_mask(gap=0, cutpath="dovetail");
//   partition_cut_mask(gap=10, cutpath="dovetail");
//   partition_cut_mask(gap=10, cutsize=15, cutpath="dovetail");
//   partition_cut_mask(gap=10, cutsize=[15,15], cutpath="dovetail");
//   partition_cut_mask(gap=10, cutsize=[15,15], cutpath="dovetail", cutpath_centered=false);
// Examples(2DMed):
//   partition_cut_mask(cutpath="sawtooth",$slop=0.5);
//   partition_cut_mask(cutpath="sinewave",$slop=0.5);
//   partition_cut_mask(cutpath="comb",$slop=0.5);
//   partition_cut_mask(cutpath="finger",$slop=0.5);
//   partition_cut_mask(cutpath="dovetail",$slop=1);
//   partition_cut_mask(cutpath="hammerhead",$slop=1);
//   partition_cut_mask(cutpath="jigsaw",$slop=0.5);
module partition_cut_mask(l=100, h=100, cutsize=10, cutpath="jigsaw", gap=0, cutpath_centered=true, anchor=CENTER, spin=0, orient=UP)
{
    cutsize = is_vector(cutsize)? cutsize : [cutsize*2, cutsize];
    path = _partition_cutpath(l, h, cutsize, cutpath, gap, cutpath_centered);
    attachable(anchor,spin,orient, size=[l,cutsize.y,h]) {
        linear_extrude(height=h, center=true, convexity=10) {
            stroke(path, width=max(0.1, get_slop()*2));
        }
        children();
    }
}


// Module: partition()
// Synopsis: Cuts an object in two with matched joining edges, then separates the parts.
// SynTags: Geom, VNF, Path, Region
// Topics: Partitions, Masking, Paths
// See Also: partition_cut_mask(), partition_mask(), dovetail()
// Usage:
//   partition(size, [spread], [cutsize], [cutpath], [gap], [spin], [$slop=]) CHILDREN;
// Description:
//   Partitions an object into two parts, spread apart a small distance, with matched joining edges.
// Arguments:
//   size = The [X,Y,Z] size of the object to partition.
//   spread = The distance to spread the two parts by.
//   cutsize = The width of the cut pattern to be used.
//   cutpath = The cutpath to use.  Standard named paths are "flat", "sawtooth", "sinewave", "comb", "finger", "dovetail", "hammerhead", and "jigsaw".  Alternatively, you can give a cutpath as a 2D path, where X is between 0 and 1, and Y is between -0.5 and 0.5.
//   gap = Empty gaps between cutpath iterations.  Default: 0
//   cutpath_centered = Ensures the cutpath is always centered.  Default: true
//   spin = Rotate this many degrees around the Z axis.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   ---
//   $slop = Extra gap to leave to correct for printer-specific fitting. 
// Examples(Med):
//   partition(spread=12, cutpath="dovetail") cylinder(h=50, d=80, center=false);
//   partition(spread=12, gap=10, cutpath="dovetail") cylinder(h=50, d=80, center=false);
//   partition(spread=12, gap=10, cutpath="dovetail", cutpath_centered=false) cylinder(h=50, d=80, center=false);
//   partition(spread=20, gap=10, cutsize=15, cutpath="dovetail") cylinder(h=50, d=80, center=false);
//   partition(spread=25, gap=10, cutsize=[20,20], cutpath="dovetail") cylinder(h=50, d=80, center=false);
// Side Effects:
//   `$idx` is set to 0 on the back part and 1 on the front part.
// Examples(2DMed):
//   partition(cutpath="sawtooth") cylinder(h=50, d=80, center=false);
//   partition(cutpath="sinewave") cylinder(h=50, d=80, center=false);
//   partition(cutpath="comb") cylinder(h=50, d=80, center=false);
//   partition(cutpath="finger") cylinder(h=50, d=80, center=false);
//   partition(spread=12, cutpath="dovetail") cylinder(h=50, d=80, center=false);
//   partition(spread=12, cutpath="hammerhead") cylinder(h=50, d=80, center=false);
//   partition(cutpath="jigsaw") cylinder(h=50, d=80, center=false);
module partition(size=100, spread=10, cutsize=10, cutpath="jigsaw", gap=0, cutpath_centered=true, spin=0)
{
    req_children($children);
    size = is_vector(size)? size : [size,size,size];
    cutsize = is_vector(cutsize)? cutsize : [cutsize*2, cutsize];
    rsize = v_abs(rot(spin,p=size));
    vec = rot(spin,p=BACK)*spread/2;
    move(vec) {
        $idx = 0;
        intersection() {
            if ($children>0) children();
            partition_mask(l=rsize.x, w=rsize.y, h=rsize.z, cutsize=cutsize, cutpath=cutpath, gap=gap, cutpath_centered=cutpath_centered, spin=spin);
        }
    }
    move(-vec) {
        $idx = 1;
        intersection() {
            if ($children>0) children();
            partition_mask(l=rsize.x, w=rsize.y, h=rsize.z, cutsize=cutsize, cutpath=cutpath, gap=gap, cutpath_centered=cutpath_centered, inverse=true, spin=spin);
        }
    }
}



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
