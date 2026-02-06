//////////////////////////////////////////////////////////////////////
// LibFile: partitions.scad
//   Cut objects with a plane, or partition them into interlocking pieces for easy printing of large objects. 
// Includes:
//   include <BOSL2/std.scad>
// FileGroup: Basic Modeling
// FileSummary: Cut objects with a plane or partition them into interlocking pieces.
// FileFootnotes: STD=Included in std.scad
//////////////////////////////////////////////////////////////////////

_BOSL2_PARTITIONS = is_undef(_BOSL2_STD) && (is_undef(BOSL2_NO_STD_WARNING) || !BOSL2_NO_STD_WARNING) ?
       echo("Warning: partitions.scad included without std.scad; dependencies may be missing\nSet BOSL2_NO_STD_WARNING = true to mute this warning.") true : true;


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
//   cut_path = If given a path, uses it to form the partition cut face.  Negative X values in the path will be interpreted as being to the left of the cut plane, when looking at it from the cut-away side, with Z+ up, (or back, if v is UP or DOWN).  Positive X values will be interpreted as being to the right side.  Path Y values equal to 0 are interpreted as being on the cut plane.  Positive Y values are interpreted as being in the direction of the cut plane normal (into the kept side).  Default: undef (cut using a flat plane)
//   cut_angle = The angle in degrees to rotate the cut mask around the plane normal vector, before partitioning.  Only makes sense when using with cut_path= and planar=false. Module only. Default: 0
//   offset = The amount to increase the size of the partitioning mask, using `offset()`.  Note: this might be imperfect in the functional form.  Default: 0
//   show_frameref = If true, draws a frame reference arrow set in the center of the cut plane, to give you a clear idea on how the cut_path slice will be oriented.  Module only.  Default: false
//   convexity = Max number of times a line could intersect a wall of the surface being formed. Module only.  Default: 10
//
// Examples:
//   half_of(DOWN+BACK, cp=[0,-10,0]) cylinder(h=40, r1=10, r2=0, center=false);
//   half_of(DOWN+LEFT, s=200) sphere(d=150);
// Example(2D):
//   half_of([1,1], planar=true) circle(d=50);
// Example(2D): Using a cut path in 2D
//   ppath = partition_path([
//           40,
//           "jigsaw",
//           10,
//           "dovetail yflip",
//           5,
//           "hammerhead 30x20",
//           5,
//           "dovetail yflip",
//           10,
//           "sawtooth",
//           40,
//       ],
//       $fn=24
//   );
//   half_of(LEFT+BACK, cut_path=ppath, s=500, planar=true)
//       square(200, center=true);
// Example(3D): Using a cut path in 3D
//   ppath = partition_path([
//           40,
//           "jigsaw",
//           10,
//           "dovetail yflip",
//           5,
//           "hammerhead 30x20",
//           5,
//           "dovetail yflip",
//           10,
//           "sawtooth",
//           40,
//       ],
//       $fn=24
//   );
//   half_of(LEFT+BACK, cut_path=ppath, s=500)
//       cube(200, center=true);
module half_of(v=UP, cp, s=100, planar=false, cut_path, cut_angle=0, offset=0, show_frameref=false, convexity=10)
{
    module maybe_offset(r) {
        if (r==0) {
            children();
        } else {
            offset(r=r) children();
        }
    }
    module ghost_if(cond) {
        if (cond) {
            %children();
        } else {
            children();
        }
    }
    req_children($children);
    check = assert(is_num(cut_angle))
        assert(is_num(offset));
    cp = is_vector(v,4)? assert(cp==undef, "Don't use cp with plane definition.") plane_normal(v) * v[3] :
        is_vector(cp)? cp :
        is_num(cp)? cp*unit(v) :
        [0,0,0];
    v = is_vector(v,4)? plane_normal(v) : is_vector(v,2)? point3d(v) : v;
    ppath = is_undef(cut_path)
      ? [[-s/2,0], [+s/2,0]]
      : assert(is_path(cut_path), "The cut_path= argument must be either undef or a horizontal path.")
        cut_path[0].x < last(cut_path).x
          ? cut_path
          : reverse(cut_path);
    cut_path = [
            [min(-s/2, ppath[0].x), +s],
            [min(-s/2, ppath[0].x), ppath[0].y],
            each ppath,
            [max(+s/2, last(ppath).x), last(ppath).y],
            [max(+s/2, last(ppath).x), +s],
        ];
    if (cp != [0,0,0]) {
        translate(cp)
            half_of(
                v=v,
                cp=[0,0,0],
                s=s,
                planar=planar,
                cut_path=cut_path,
                cut_angle=cut_angle,
                offset=offset,
                show_frameref=show_frameref,
                convexity=convexity
            )
            translate(-cp) children();
    } else if (planar) {
        v = (v==UP)? BACK : (v==DOWN)? FWD : v;
        ang = atan2(v.y, v.x) - 90;
        intersection() {
            children();
            rot(ang) {
                maybe_offset(r=offset) polygon(cut_path);
            }
        }
    } else {
        xyv = (v==UP)? FWD : (v==DOWN)? BACK : [v.x, v.y, 0];
        ang = atan2(xyv.y, xyv.x) - 90;
        ghost_if(show_frameref) {
            intersection() {
                children();
                rot(cut_angle, v=v) rot(from=xyv, to=v) {
                    zrot(ang) {
                        linear_extrude(height=s, center=true, convexity=convexity) {
                            maybe_offset(r=offset) polygon(cut_path);
                        }
                    }
                }
            }
        }
        if (show_frameref) {
            rot(cut_angle, v=v)
                rot(from=xyv, to=v)
                    zrot(ang)
                        rot(-120,v=[1,1,1])
                            frame_ref(s/10);
        }
    }
}


function half_of(p, v=UP, cp, cut_path, cut_angle=0, offset=0) =
    is_vnf(p) ?
        assert(is_vector(v) && (len(v)==3 || len(v)==4),str("Must give 3-vector or plane specification",v))
        assert(select(v,0,2)!=[0,0,0], "vector v must be nonzero")
        assert(is_undef(cut_path), "The cut_path= argument is not supported for VNFs.")
        assert(cut_angle==0, "The cut_angle= argument is not supported for VNFs.")
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
        assert(cut_angle==0, "The cut_angle= argument is not supported for paths or regions.")
        let(
            v=unit(v),
            bounds = pointlist_bounds(is_region(p)?flatten(p):p),
            s = 2*max(norm(bounds[0]-cp), norm(bounds[1]-cp)),
            ppath = is_undef(cut_path)
              ? [[-s/2,0], [+s/2,0]]
              : assert(is_path(cut_path), "The cut_path= argument must be either undef or a horizontal path.")
                cut_path[0].x < last(cut_path).x
                  ? cut_path
                  : reverse(cut_path),
            M = move(cp) * rot(from=BACK, to=[v.x,v.y,0]),
            raw_path = [
                [min(-s/2, ppath[0].x), +s],
                [min(-s/2, ppath[0].x), ppath[0].y],
                each ppath,
                [max(+s/2, last(ppath).x), last(ppath).y],
                [max(+s/2, last(ppath).x), +s],
            ],
            cut_path = apply(M, offset==0? raw_path : offset(r=offset, p=raw_path))
        )
        intersection(cut_path, p)
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
//   cut_path = If given a path, uses it to form the partition cut face.  Negative X values in the path will be interpreted as being to the left of the cut plane, when looking at it from the cut-away side, with Z+ up, (or back, if v is UP or DOWN).  Positive X values will be interpreted as being to the right side.  Path Y values equal to 0 are interpreted as being on the cut plane.  Positive Y values are interpreted as being in the direction of the cut plane normal (into the kept side).  Default: undef (cut using a flat plane)
//   cut_angle = The angle in degrees to rotate the cut mask around the plane normal vector, before partitioning.  Only makes sense when using with cut_path= and planar=false. Module only. Default: 0
//   offset = The amount to increase the size of the partitioning mask, using `offset()`.  Note: this might be imperfect in the functional form.  Default: 0
//   show_frameref = If true, draws a frame reference arrow set in the center of the cut plane, to give you a clear idea on how the cut_path slice will be oriented.  Module only.  Default: false
//   convexity = Max number of times a line could intersect a wall of the surface being formed. Module only.  Default: 10
// Examples:
//   left_half() sphere(r=20);
//   left_half(x=-8) sphere(r=20);
// Example(2D):
//   left_half(planar=true) circle(r=20);
// Example(2D): Using a cut path in 2D
//   ppath = partition_path([
//           40, "jigsaw", "dovetail yflip", 40,
//           "hammerhead 30x20",
//           40, "dovetail yflip", "sawtooth", 40,
//       ],
//       altpath=[[-200,0],[-40,0],[-20,20],[20,20],[40,0],[200,0]],
//       $fn=24
//   );
//   left_half(cut_path=ppath, s=310, planar=true) square(300, center=true);
// Example(3D): Using a cut path in 3D
//   ppath = partition_path([
//           40, "jigsaw", "dovetail yflip", 40,
//           "hammerhead 30x20",
//           40, "dovetail yflip", "sawtooth", 40,
//       ],
//       altpath=[[-200,0],[-40,0],[-20,20],[20,20],[40,0],[200,0]],
//       $fn=24
//   );
//   left_half(cut_path=ppath, s=310)
//       cube(300, center=true);
module left_half(s=100, x=0, planar=false, cut_path, cut_angle=0, offset=0, show_frameref=false, convexity=10)
{
    req_children($children);
    half_of(
        v=LEFT, cp=[x,0,0], s=s,
        planar=planar,
        cut_path=cut_path,
        cut_angle=cut_angle,
        offset=offset,
        show_frameref=show_frameref,
        convexity=convexity
    ) children();
}
function left_half(p, x=0, cut_path, cut_angle=0, offset=0) =
    half_of(p, LEFT, cp=[x,0,0], cut_path=cut_path, cut_angle=cut_angle, offset=offset);



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
//   cut_path = If given a path, uses it to form the partition cut face.  Negative X values in the path will be interpreted as being to the left of the cut plane, when looking at it from the cut-away side, with Z+ up, (or back, if v is UP or DOWN).  Positive X values will be interpreted as being to the right side.  Path Y values equal to 0 are interpreted as being on the cut plane.  Positive Y values are interpreted as being in the direction of the cut plane normal (into the kept side).  Default: undef (cut using a flat plane)
//   cut_angle = The angle in degrees to rotate the cut mask around the plane normal vector, before partitioning.  Only makes sense when using with cut_path= and planar=false. Module only. Default: 0
//   offset = The amount to increase the size of the partitioning mask, using `offset()`.  Note: this might be imperfect in the functional form.  Default: 0
//   show_frameref = If true, draws a frame reference arrow set in the center of the cut plane, to give you a clear idea on how the cut_path slice will be oriented.  Module only.  Default: false
//   convexity = Max number of times a line could intersect a wall of the surface being formed. Module only.  Default: 10
// Examples(FlatSpin,VPD=175):
//   right_half() sphere(r=20);
//   right_half(x=-5) sphere(r=20);
// Example(2D):
//   right_half(planar=true) circle(r=20);
// Example(2D): Using a cut path in 2D
//   ppath = partition_path([
//           40, "jigsaw", "dovetail yflip", 40,
//           "hammerhead 30x20",
//           40, "dovetail yflip", "sawtooth", 40,
//       ],
//       altpath=[[-200,0],[-40,0],[-20,20],[20,20],[40,0],[200,0]],
//       $fn=24
//   );
//   right_half(cut_path=ppath, s=310, planar=true) square(300, center=true);
// Example(3D): Using a cut path in 3D
//   ppath = partition_path([
//           40, "jigsaw", "dovetail yflip", 40,
//           "hammerhead 30x20",
//           40, "dovetail yflip", "sawtooth", 40,
//       ],
//       altpath=[[-200,0],[-40,0],[-20,20],[20,20],[40,0],[200,0]],
//       $fn=24
//   );
//   right_half(cut_path=ppath, s=310)
//       cube(300, center=true);
module right_half(s=100, x=0, planar=false, cut_path, cut_angle=0, offset=0, show_frameref=false, convexity=10)
{
    half_of(
        v=RIGHT, cp=[x,0,0], s=s,
        planar=planar,
        cut_path=cut_path,
        cut_angle=cut_angle,
        offset=offset,
        show_frameref=show_frameref,
        convexity=convexity
    ) children();
}
function right_half(p, x=0, cut_path, cut_angle=0, offset=0) =
    half_of(p, RIGHT, cp=[x,0,0], cut_path=cut_path, cut_angle=cut_angle, offset=offset);



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
//   cut_path = If given a path, uses it to form the partition cut face.  Negative X values in the path will be interpreted as being to the left of the cut plane, when looking at it from the cut-away side, with Z+ up, (or back, if v is UP or DOWN).  Positive X values will be interpreted as being to the right side.  Path Y values equal to 0 are interpreted as being on the cut plane.  Positive Y values are interpreted as being in the direction of the cut plane normal (into the kept side).  Default: undef (cut using a flat plane)
//   cut_angle = The angle in degrees to rotate the cut mask around the plane normal vector, before partitioning.  Only makes sense when using with cut_path= and planar=false. Module only. Default: 0
//   offset = The amount to increase the size of the partitioning mask, using `offset()`.  Note: this might be imperfect in the functional form.  Default: 0
//   show_frameref = If true, draws a frame reference arrow set in the center of the cut plane, to give you a clear idea on how the cut_path slice will be oriented.  Module only.  Default: false
//   convexity = Max number of times a line could intersect a wall of the surface being formed. Module only.  Default: 10
// Examples(FlatSpin,VPD=175):
//   front_half() sphere(r=20);
//   front_half(y=5) sphere(r=20);
// Example(2D):
//   front_half(planar=true) circle(r=20);
// Example(2D): Using a cut path in 2D
//   ppath = partition_path([
//           40, "jigsaw", "dovetail yflip", 40,
//           "hammerhead 30x20",
//           40, "dovetail yflip", "sawtooth", 40,
//       ],
//       altpath=[[-200,0],[-40,0],[-20,20],[20,20],[40,0],[200,0]],
//       $fn=24
//   );
//   front_half(cut_path=ppath, s=310, planar=true) square(300, center=true);
// Example(3D): Using a cut path in 3D
//   ppath = partition_path([
//           40, "jigsaw", "dovetail yflip", 40,
//           "hammerhead 30x20",
//           40, "dovetail yflip", "sawtooth", 40,
//       ],
//       altpath=[[-200,0],[-40,0],[-20,20],[20,20],[40,0],[200,0]],
//       $fn=24
//   );
//   front_half(cut_path=ppath, s=310)
//       cube(300, center=true);
module front_half(s=100, y=0, planar=false, cut_path, cut_angle=0, offset=0, show_frameref=false, convexity=10)
{
    req_children($children);
    half_of(
        v=FRONT, cp=[0,y,0], s=s,
        planar=planar,
        cut_path=cut_path,
        cut_angle=cut_angle,
        offset=offset,
        show_frameref=show_frameref,
        convexity=convexity
    ) children();
}
function front_half(p,y=0, cut_path, cut_angle=0, offset=0) =
    half_of(p, FRONT, cp=[0,y,0], cut_path=cut_path, cut_angle=cut_angle, offset=offset);



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
//   cut_path = If given a path, uses it to form the partition cut face.  Negative X values in the path will be interpreted as being to the left of the cut plane, when looking at it from the cut-away side, with Z+ up, (or back, if v is UP or DOWN).  Positive X values will be interpreted as being to the right side.  Path Y values equal to 0 are interpreted as being on the cut plane.  Positive Y values are interpreted as being in the direction of the cut plane normal (into the kept side).  Default: undef (cut using a flat plane)
//   cut_angle = The angle in degrees to rotate the cut mask around the plane normal vector, before partitioning.  Only makes sense when using with cut_path= and planar=false. Module only. Default: 0
//   offset = The amount to increase the size of the partitioning mask, using `offset()`.  Note: this might be imperfect in the functional form.  Default: 0
//   show_frameref = If true, draws a frame reference arrow set in the center of the cut plane, to give you a clear idea on how the cut_path slice will be oriented.  Module only.  Default: false
//   convexity = Max number of times a line could intersect a wall of the surface being formed. Module only.  Default: 10
// Examples:
//   back_half() sphere(r=20);
//   back_half(y=8) sphere(r=20);
// Example(2D):
//   back_half(planar=true) circle(r=20);
// Example(2D): Using a cut path in 2D
//   ppath = partition_path([
//           40, "jigsaw", "dovetail yflip", 40,
//           "hammerhead 30x20",
//           40, "dovetail yflip", "sawtooth", 40,
//       ],
//       altpath=[[-200,0],[-40,0],[-20,20],[20,20],[40,0],[200,0]],
//       $fn=24
//   );
//   back_half(cut_path=ppath, s=310, planar=true) square(300, center=true);
// Example(3D): Using a cut path in 3D
//   ppath = partition_path([
//           40, "jigsaw", "dovetail yflip", 40,
//           "hammerhead 30x20",
//           40, "dovetail yflip", "sawtooth", 40,
//       ],
//       altpath=[[-200,0],[-40,0],[-20,20],[20,20],[40,0],[200,0]],
//       $fn=24
//   );
//   back_half(cut_path=ppath, s=310)
//       cube(300, center=true);
module back_half(s=100, y=0, planar=false, cut_path, cut_angle=0, offset=0, show_frameref=false, convexity=10)
{
    req_children($children);
    half_of(
        v=BACK, cp=[0,y,0], s=s,
        planar=planar,
        cut_path=cut_path,
        cut_angle=cut_angle,
        offset=offset,
        show_frameref=show_frameref,
        convexity=convexity
    ) children();
}
function back_half(p,y=0, cut_path, cut_angle=0, offset=0) =
    half_of(p, BACK, cp=[0,y,0], cut_path=cut_path, cut_angle=cut_angle, offset=offset);



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
//   planar = If true, perform a 2D operation.  When planar, becomes equivalent of `front_half()`.  (Module version).  Default: false.
//   cut_path = If given a path, uses it to form the partition cut face.  Negative X values in the path will be interpreted as being to the left of the cut plane, when looking at it from the cut-away side, with Z+ up, (or back, if v is UP or DOWN).  Positive X values will be interpreted as being to the right side.  Path Y values equal to 0 are interpreted as being on the cut plane.  Positive Y values are interpreted as being in the direction of the cut plane normal (into the kept side).  Default: undef (cut using a flat plane)
//   cut_angle = The angle in degrees to rotate the cut mask around the plane normal vector, before partitioning.  Only makes sense when using with cut_path= and planar=false. Module only. Default: 0
//   offset = The amount to increase the size of the partitioning mask, using `offset()`.  Note: this might be imperfect in the functional form.  Default: 0
//   show_frameref = If true, draws a frame reference arrow set in the center of the cut plane, to give you a clear idea on how the cut_path slice will be oriented.  Module only.  Default: false
//   convexity = Max number of times a line could intersect a wall of the surface being formed. Module only.  Default: 10
// Examples:
//   bottom_half() sphere(r=20);
//   bottom_half(z=-10) sphere(r=20);
// Example(2D): Working in 2D
//   bottom_half(z=5) circle(r=20);
// Example(2D): Using a cut path in 2D
//   ppath = partition_path([
//           40, "jigsaw", "dovetail yflip", 40,
//           "hammerhead 30x20",
//           40, "dovetail yflip", "sawtooth", 40,
//       ],
//       altpath=[[-200,0],[-40,0],[-20,20],[20,20],[40,0],[200,0]],
//       $fn=24
//   );
//   bottom_half(cut_path=ppath, s=310, planar=true) square(300, center=true);
// Example(3D): Using a cut path in 3D
//   ppath = partition_path([
//           40, "jigsaw", "dovetail yflip", 40,
//           "hammerhead 30x20",
//           40, "dovetail yflip", "sawtooth", 40,
//       ],
//       altpath=[[-200,0],[-40,0],[-20,20],[20,20],[40,0],[200,0]],
//       $fn=24
//   );
//   bottom_half(cut_path=ppath, s=310)
//       cube(300, center=true);
module bottom_half(s=100, z=0, planar=false, cut_path, cut_angle=0, offset=0, show_frameref=false, convexity=10)
{
    req_children($children);
    dir = planar? FRONT : BOTTOM;
    cp = planar? [0,z,0] : [0,0,z];
    half_of(
        v=dir, cp=cp, s=s,
        planar=planar,
        cut_path=cut_path,
        cut_angle=cut_angle,
        offset=offset,
        show_frameref=show_frameref,
        convexity=convexity
    ) children();
}
function bottom_half(p,z=0, planar=false, cut_path, cut_angle=0, offset=0) =
    let(
        dir = planar? FRONT : BOTTOM,
        cp = planar? [0,z,0] : [0,0,z]
    )
    half_of(p, dir, cp=cp, cut_path=cut_path, cut_angle=cut_angle, offset=offset);



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
//   planar = If true, perform a 2D operation.  When planar, becomes equivalent of `back_half()`.  (Module version).  Default: false.
//   cut_path = If given a path, uses it to form the partition cut face.  Negative X values in the path will be interpreted as being to the left of the cut plane, when looking at it from the cut-away side, with Z+ up, (or back, if v is UP or DOWN).  Positive X values will be interpreted as being to the right side.  Path Y values equal to 0 are interpreted as being on the cut plane.  Positive Y values are interpreted as being in the direction of the cut plane normal (into the kept side).  Default: undef (cut using a flat plane)
//   cut_angle = The angle in degrees to rotate the cut mask around the plane normal vector, before partitioning.  Only makes sense when using with cut_path= and planar=false. Module only. Default: 0
//   offset = The amount to increase the size of the partitioning mask, using `offset()`.  Note: this might be imperfect in the functional form.  Default: 0
//   show_frameref = If true, draws a frame reference arrow set in the center of the cut plane, to give you a clear idea on how the cut_path slice will be oriented.  Module only.  Default: false
//   convexity = Max number of times a line could intersect a wall of the surface being formed. Module only.  Default: 10
// Examples(Spin,VPD=175):
//   top_half() sphere(r=20);
//   top_half(z=5) sphere(r=20);
// Example(2D): Working in 2D
//   top_half(z=5) circle(r=20);
// Example(2D): Using a cut path in 2D
//   ppath = partition_path([
//           40, "jigsaw", "dovetail yflip", 40,
//           "hammerhead 30x20",
//           40, "dovetail yflip", "sawtooth", 40,
//       ],
//       altpath=[[-200,0],[-40,0],[-20,20],[20,20],[40,0],[200,0]],
//       $fn=24
//   );
//   top_half(cut_path=ppath, s=310, planar=true) square(300, center=true);
// Example(3D): Using a cut path in 3D
//   ppath = partition_path([
//           40, "jigsaw", "dovetail yflip", 40,
//           "hammerhead 30x20",
//           40, "dovetail yflip", "sawtooth", 40,
//       ],
//       altpath=[[-200,0],[-40,0],[-20,20],[20,20],[40,0],[200,0]],
//       $fn=24
//   );
//   top_half(cut_path=ppath, s=310)
//       cube(300, center=true);
module top_half(s=100, z=0, planar=false, cut_path, cut_angle=0, offset=0, show_frameref=false, convexity=10)
{
    req_children($children);
    dir = planar? BACK : TOP;
    cp = planar? [0,z,0] : [0,0,z];
    half_of(
        v=dir, cp=cp, s=s,
        planar=planar,
        cut_path=cut_path,
        cut_angle=cut_angle,
        offset=offset,
        show_frameref=show_frameref,
        convexity=convexity
    ) children();
}
function top_half(p, z=0, planar=false, cut_path, cut_angle=0, offset=0) =
    let(
        dir = planar? BACK : TOP,
        cp = planar? [0,z,0] : [0,0,z]
    )
    half_of(p, dir, cp=cp, cut_path=cut_path, cut_angle=cut_angle, offset=offset);



// Section: Partioning into Interlocking Pieces


function _partition_subpath(type) =
    type=="flat"?     [[0,0],[1,0]] :
    type=="sawtooth"? [[0,0], [0.5,1], [1,0]] :
    type=="sinewave"? [for (a=[0:5:360]) [a/360,sin(a)/2]] :
    type=="comb"?     let(dx=0.5*sin(2))  [[0,0],[0+dx,0.5],[0.5-dx,0.5],[0.5+dx,-0.5],[1-dx,-0.5],[1,0]] :
    type=="finger"?   let(dx=0.5*sin(20)) [[0,0],[0+dx,0.5],[0.5-dx,0.5],[0.5+dx,-0.5],[1-dx,-0.5],[1,0]] :
    type=="dovetail"? [[0,-0.5], [0.3,-0.5], [0.2,0.5], [0.8,0.5], [0.7,-0.5], [1,-0.5]] :
    type=="hammerhead"? [[0,-0.5], [0.35,-0.5], [0.35,0], [0.15,0], [0.15,0.5], [0.85,0.5], [0.85,0], [0.65,0], [0.65,-0.5],[1,-0.5]] :
    type=="jigsaw"? concat(
                        arc(r=5/16, cp=[  0,-3/16], start=270, angle= 125),
                        arc(r=5/16, cp=[1/2, 3/16], start=215, angle=-250),
                        arc(r=5/16, cp=[  1,-3/16], start=145, angle= 125)
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
//   convexity = Max number of times a line could intersect a wall of the surface being formed. Module only.  Default: 10
//   spin = Rotate this many degrees around the Z axis.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   $slop = The amount to shrink the mask by, to correct for printer-specific fitting.
// Examples:
//   partition_mask(w=50, gap=0, cutpath="jigsaw", $fn=12);
//   partition_mask(w=50, gap=10, cutpath="jigsaw", $fn=12);
//   partition_mask(w=50, gap=10, cutpath="jigsaw", inverse=true, $fn=12);
//   partition_mask(w=50, gap=10, cutsize=4, cutpath="jigsaw", $fn=12);
//   partition_mask(w=50, gap=10, cutsize=4, cutpath="jigsaw", cutpath_centered=false, $fn=12);
//   partition_mask(w=50, gap=10, cutsize=[4,20], cutpath="jigsaw", $fn=12);
// Examples(2D):
//   partition_mask(w=20, cutpath="sawtooth");
//   partition_mask(w=20, cutpath="sinewave", $fn=12);
//   partition_mask(w=20, cutpath="comb");
//   partition_mask(w=20, cutpath="finger");
//   partition_mask(w=20, cutpath="dovetail");
//   partition_mask(w=20, cutpath="hammerhead");
//   partition_mask(w=20, cutpath="jigsaw", $fn=12);
module partition_mask(
    l=100,
    w=100,
    h=100,
    cutsize=10,
    cutpath="jigsaw",
    gap=0,
    cutpath_centered=true,
    inverse=false,
    convexity=10,
    anchor=CENTER,
    spin=0,
    orient=UP
) {
    cutsize = is_vector(cutsize)? point2d(cutsize) : [cutsize*2, cutsize];
    path = _partition_cutpath(l, h, cutsize, cutpath, gap, cutpath_centered);
    midpath = select(path,1,-2);
    sizepath = concat([path[0]+[-get_slop(),0]], midpath, [last(path)+[get_slop(),0]], [[+(l/2+get_slop()), (w+get_slop())*(inverse?-1:1)], [-(l/2+get_slop()), (w+get_slop())*(inverse?-1:1)]]);
    bnds = pointlist_bounds(sizepath);
    fullpath = concat(path, [[last(path).x, w*(inverse?-1:1)], [path[0].x, w*(inverse?-1:1)]]);
    attachable(anchor,spin,orient, size=point3d(bnds[1]-bnds[0],h)) {
        linear_extrude(height=h, center=true, convexity=convexity) {
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
//   convexity = Max number of times a line could intersect a wall of the surface being formed. Module only.  Default: 10
//   $slop = The width of the cut mask, to correct for printer-specific fitting. 
// Examples:
//   partition_cut_mask(gap=0, cutpath="dovetail");
//   partition_cut_mask(gap=10, cutpath="dovetail");
//   partition_cut_mask(gap=10, cutsize=15, cutpath="dovetail");
//   partition_cut_mask(gap=10, cutsize=[15,15], cutpath="dovetail");
//   partition_cut_mask(gap=10, cutsize=[15,15], cutpath="dovetail", cutpath_centered=false);
// Examples(2DMed):
//   partition_cut_mask(cutpath="sawtooth",$slop=0.5);
//   partition_cut_mask(cutpath="sinewave",$slop=0.5,$fn=12);
//   partition_cut_mask(cutpath="comb",$slop=0.5);
//   partition_cut_mask(cutpath="finger",$slop=0.5);
//   partition_cut_mask(cutpath="dovetail",$slop=1);
//   partition_cut_mask(cutpath="hammerhead",$slop=1);
//   partition_cut_mask(cutpath="jigsaw",h=10,$slop=0.5,$fn=12);
module partition_cut_mask(l=100, h=100, cutsize=10, cutpath="jigsaw", gap=0, cutpath_centered=true, convexity=10, anchor=CENTER, spin=0, orient=UP)
{
    cutsize = is_vector(cutsize)? cutsize : [cutsize*2, cutsize];
    path = _partition_cutpath(l, h, cutsize, cutpath, gap, cutpath_centered);
    attachable(anchor,spin,orient, size=[l,cutsize.y,h]) {
        linear_extrude(height=h, center=true, convexity=convexity) {
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
//   If you only need one side of the partition you can use `$idx` in the children.  
// Arguments:
//   size = The [X,Y,Z] size of the object to partition.
//   spread = The distance to spread the two parts by. Default: 10
//   ---
//   cutsize = The width of the cut pattern to be used.  Default: 10
//   cutpath = The cutpath to use.  Standard named paths are "flat", "sawtooth", "sinewave", "comb", "finger", "dovetail", "hammerhead", and "jigsaw".  Alternatively, you can give a cutpath as a 2D path, where X is between 0 and 1, and Y is between -0.5 and 0.5.  Default: "jigsaw"
//   gap = Empty gaps between cutpath iterations.  Default: 0
//   cutpath_centered = Ensures the cutpath is always centered.  Default: true
//   spin = Rotate this many degrees around the Z axis.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   convexity = Max number of times a line could intersect a wall of the surface being formed. Module only.  Default: 10
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
//   partition(cutpath="jigsaw") cylinder(h=50, d=80, center=false, $fn=12);
// Example(2D,Med): Using `$idx` to display only the back piece of the partition
//   partition(cutpath="jigsaw",$fn=12)
//     if ($idx==0) cylinder(h=50, d=80, center=false);

module partition(size=100, spread=10, cutsize=10, cutpath="jigsaw", gap=0, cutpath_centered=true, convexity=10, spin=0)
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
            partition_mask(l=rsize.x, w=rsize.y, h=rsize.z, cutsize=cutsize, cutpath=cutpath, gap=gap, cutpath_centered=cutpath_centered, convexity=convexity, spin=spin);
        }
    }
    move(-vec) {
        $idx = 1;
        intersection() {
            if ($children>0) children();
            partition_mask(l=rsize.x, w=rsize.y, h=rsize.z, cutsize=cutsize, cutpath=cutpath, gap=gap, cutpath_centered=cutpath_centered, inverse=true, convexity=convexity, spin=spin);
        }
    }
}


// Module: ptn_sect()
// Synopsis: Creates a partition path section from a description.
// SynTags: Path
// Topics: Partitions, Masking, Paths
// See Also: partition_path(), partition_cut_mask(), partition()
// Usage:
//   path = ptn_sect(type, [length], [width], [invert=]);
// Description:
//   Creates a partition path section based on a name or description.  The result is intended to be fed to {{partition_path()}}.
//   If the `type=` argument is given as a scalar, the pattern returned will be for a "flat" section of that given length.
//   If the `type=` argument is given as a string, it it expected to be the name of a standard section pattern to return.
//   Accepted pattern names are: `"flat"`, `"sawtooth"`, `"sinewave"`, `"comb"`, `"finger"`, `"dovetail"`, `"hammerhead"`, or `"jigsaw"`.
//   If the given pattern name string is suffixed by `" yflip"`, then the returned pattern is flipped back-to-front, across the X axis.
//   If both `invert=true`, and the " yflip" suffix is given, the returned section will NOT be flipped front-to-back.
//   If the `type=` argument is given as a 2D path, the pattern returned will be scaled from the input path by length= and width=.
// Arguments:
//   type = The general description of the partition path section.  This can be a string name, a 2D path, or a scalar length for a flat section.  Valid names are "flat", "sawtooth", "sinewave", "comb", "finger", "dovetail", "hammerhead", or "jigsaw".
//   length = The X axis length of the section. Default: 30
//   width = The Y axis length of the section. Default: 20
//   ---
//   invert = If true, the returned section is flipped back-to-front.  Default: false
// Examples(2D):
//   stroke(ptn_sect("flat"));
//   stroke(ptn_sect("sawtooth"));
//   stroke(ptn_sect("square"));
//   stroke(ptn_sect("triangle"));
//   stroke(ptn_sect("halfsine", $fn=24));
//   stroke(ptn_sect("semicircle", $fn=24));
//   stroke(ptn_sect("comb"));
//   stroke(ptn_sect("finger"));
//   stroke(ptn_sect("dovetail"));
//   stroke(ptn_sect("hammerhead"));
//   stroke(ptn_sect("jigsaw", $fn=24));
// Example(2D): Giving length and width arguments scales the shape differently.
//   stroke(ptn_sect("jigsaw", length=40, width=20, $fn=36));
// Example(2D): Giving invert=true will flip the pattern front-to-back
//   stroke(ptn_sect("jigsaw", invert=true, $fn=36));
// Example(2D): Suffixing the name with `" yflip"` will also flip the pattern front-to-back.
//   stroke(ptn_sect("hammerhead yflip"));
// Example(2D): Suffixing the name with `" xflip"` will reverse the pattern left-to-right.
//   stroke(ptn_sect("sawtooth xflip"));
// Example(2D): Suffixing the name with `" addflip"` will construct a full wave pattern from the named halfwave pattern.
//   stroke(ptn_sect("sawtooth addflip"));
// Example(2D): Suffixing the name with a string like `" 5x"` will construct 5 repetitions of the pattern.
//   stroke(ptn_sect("sawtooth 5x"));
// Example(2D): Suffixing the name with a string like `" 40x20"` will scale the pattern to a size of 40 by 20.  By default a pattern will be 20 by 20 in size.
//   stroke(ptn_sect("jigsaw 40x20"));
// Example(2D): You can add multiple space delimited suffixes to apply multiple effects.
//   stroke(ptn_sect("halfsine addflip yflip 40x30 3x"));
// Example(2D): Suffix ordering can matter, since they are applied in order.
//   stroke(ptn_sect("halfsine 3x addflip yflip 40x30"));
// Example(2D): Giving a scalar is a shortcut for a "flat" section of the given length.
//   stroke(ptn_sect(30));
// Example(2D): Using a custom section shape.  Input is expected to start at `[0,0]`, and end at `[1,0]`.  It is scaled by length= and width=.
//   cust_path = yscale(2, p=arc(n=15, r=0.5, cp=[0.5,0], start=180, angle=-180));
//   stroke(ptn_sect(cust_path, length=40, width=30));

function ptn_sect(type, length=25, width=25, invert=false) =
    // NOTE: these patterns are NOT quite the same as those in _partition_subpath().
    // They are positioned and sometimes formed differently for better alignment, though
    // the overall shapes are nearly the same.
    is_num(type)? assert(is_finite(type) && type>0) [[0,0], [type,0]] :
    invert? yscale(-1, p=ptn_sect(type, length, width)) :
    is_string(type) && str_find(type, " ") != undef
      ? let(
            pos = str_find(type, " ", last=true),
            opt = substr(type, pos+1),
            type = substr(type, 0, pos)
        )
        opt == "yflip"? yscale(-1, p=ptn_sect(type, length, width)) :
        opt == "xflip"? let(
                sect = ptn_sect(type, length, width),
                bounds = pointlist_bounds(sect),
                xpos = (bounds[1].x + bounds[0].x) / 2,
                rsect = reverse(xflip(x=xpos, p=sect))
            ) rsect :
        opt == "addflip" || opt == "wave"? let(
                sect1 = ptn_sect(type, length, width),
                sect2 = ptn_sect(str(type, " yflip xflip"), length, width),
                bounds1 = pointlist_bounds(sect1),
                bounds2 = pointlist_bounds(sect2),
                m1 = scale(0.5) * left(bounds1[0].x),
                osect1 = apply(m1, sect1),
                m2 = right(last(osect1).x) * scale(0.5) * left(bounds2[0].x),
                osect2 = apply(m2, sect2),
                osect = path_merge_collinear(concat(osect1, osect2))
            ) osect :
        is_digit(opt[0]) && ends_with(opt, "x")? let(  // 4x  (repetition)
                repstr = substr(opt, 0, len(opt)-1),
                reps = parse_int(repstr),
                checks =
                    assert(is_finite(reps) && reps>0, "Repetition option expected to be in the form COUNTx.  ie: \"3x\""),
                sect = ptn_sect(type, length, width),
                w = last(sect).x,
                osect = path_merge_collinear([
                    for (i = [0:1:reps-1])
                    each right(i*w, sect)
                ])
            ) osect :
        is_digit(opt[0]) && str_find(opt, "x") != undef? let(  // 30x20  (size)
                parts = str_split(opt, "x"),
                length = parse_float(parts[0]),
                width = parse_float(parts[1]),
                checks =
                    assert(len(parts) == 2, "Size option expected to be in the form LENGTHxWIDTH.  ie: \"30x25\"")
                    assert(is_finite(length) && is_finite(width) && length>0 && width>0, "Size option expected to be in the form LENGTHxWIDTH.  ie: \"30x25\""),
                sect = ptn_sect(type, length, width)
            ) sect :
        assert(false, str("Bad section option: '",opt,"'"))
      : type == "sinewave"? ptn_sect("halfsine addflip", length, width)
      : let(
            steps = segs(length/2),
            path =
                type == "flat"?     [[0,0], [1,0]] :
                type == "sawtooth"? [[0,0], [0,1], [1,0]] :
                type == "square"?   [[0,0], [0,1], [1,1], [1,0]] :
                type == "triangle"? [[0,0], [0.5,1], [1,0]] :
                type == "halfsine"? [for (a=[0:360/steps:180]) [a/180,sin(a)]] :
                type == "semicircle"? yscale(2, p=arc(n=ceil(steps/2), r=1/2, cp=[1/2, 0], start=180, angle=-180)) :
                type == "comb"?     let(dx=ang_adj_to_opp(2,1)*width/length) assert(dx<=0.5, "width-to-length ratio too large for comb form.") [[0,0],[dx,1],[1-dx,1],[1,0]] :
                type == "finger"?   let(dx=ang_adj_to_opp(20,1)*width/length) assert(dx<=0.5, "width-to-length ratio too large for finger form.") [[0,0],[dx,1],[1-dx,1],[1,0]] :
                type == "dovetail"? let(dx=ang_adj_to_opp(9,1)*width/length/2) assert(dx<0.25, "width-to-length ratio too large for dovetail form.") [[0,0], [0.25+dx,0], [0.25-dx,1], [0.75+dx,1], [0.75-dx,0], [1,0]] :
                type == "hammerhead"? [[0,0], [0.35,0], [0.35,0.5], [0.15,0.5], [0.15,1], [0.85,1], [0.85,0.5], [0.65,0.5], [0.65,0],[1,0]] :
                type == "jigsaw"? [
                    each arc(n=ceil(steps/4), r=5/16, cp=[   0, 5/16], start=270, angle= 125),
                    each arc(n=ceil(steps/2), r=5/16, cp=[ 1/2,11/16], start=215, angle=-250),
                    each arc(n=ceil(steps/4), r=5/16, cp=[   1, 5/16], start=145, angle= 125)
                ] :
                is_path(type)? type :
                assert(false, str("Unsupported partition section type: ", type))
        ) scale([length,width], p=path);


// Module: partition_path()
// Synopsis: Creates a partition path from a path description.
// SynTags: Path
// Topics: Partitions, Masking, Paths
// See Also: ptn_sect(), partition_cut_mask(), partition()
// Usage:
//   path = partition_path(pathdesc, [repeat=], [y=], [altpath=]);
// Description:
//   Creates a partition path based on a list of section descriptors, as would be passed to {{ptn_sect()}}.
// Arguments:
//   pathdesc = A list describing one or more partition path segments. Each item is either a numeric length, a string naming a segment pattern, or a full explicit path.
//   ---
//   repeat = Number of times to repeat the full `pathdesc` sequence along the path.  Default: 1
//   y = If given, closes the generated path by connecting its ends at this Y coordinate, and orients the closed path based on the sign of `y`.
//   altpath = Optional alternate base path which the generated partition pattern will be aligned to.  Default: `[[-9999,0], [+9999,0]]`
// Example(2D): You can {{stroke()}} an unclosed partition path with a given width= to make a wall that you can use to divide a part into two pieces.
//   linear_extrude(height=100)
//       stroke(
//           partition_path([
//                   40, "jigsaw", 10, "jigsaw yflip", 40,
//                   "hammerhead 30x20",
//                   40, "jigsaw yflip", 10, "jigsaw", 40,
//               ],
//               $fn=24
//           ),
//           width=1
//       );
// Example(2D): Use repeat= to repeat a pattern.
//   linear_extrude(height=100)
//       stroke(
//           partition_path(
//               ["jigsaw", "jigsaw yflip"],
//               repeat=3, $fn=24
//           ),
//           width=1
//       );
// Example(3D): To make a mask that you can intersect with or difference from a part, you can extrude a polygon made from a closed path, offset by a slop width.
//   $slop = 0.2;
//   linear_extrude(height=100)
//       offset(r=-$slop)
//           polygon(
//               partition_path([
//                       40, "jigsaw", 10, "jigsaw yflip", 40,
//                       ptn_sect("hammerhead", length=30, width=20),
//                       40, "jigsaw yflip", 10, "jigsaw", 40,
//                   ],
//                   y=150,
//                   $fn=24
//               )
//           );
// Example(3D): You can use list comprehensions in constructing partition path descriptions.
//   $slop = 0.2;
//   linear_extrude(height=100)
//       offset(r=-$slop)
//           polygon(
//               partition_path([
//                       50,
//                       "jigsaw",
//                       30,
//                       for (i=[1:4]) each ["sawtooth", "triangle"],
//                       30,
//                       "jigsaw yflip",
//                       50,
//                   ],
//                   y=150,
//                   $fn=24
//               )
//           );

function partition_path(pathdesc, repeat=1, y, altpath) =
    let(
        paths = [
            for (n = [0:1:repeat-1])
            for (pd = pathdesc)
            is_path(pd)? pd :
            is_num(pd) || is_string(pd)? ptn_sect(pd) :
            assert(false, str("Path descriptor '",pd,"' is invalid."))
        ],
        xes = [for (path = paths) column(path,0)],
        yes = [for (path = paths) column(path,1)],
        min_xs = [for (xvals = xes) min(xvals)],
        max_xs = [for (xvals = xes) max(xvals)],
        min_y = min(flatten(yes)),
        max_y = max(flatten(yes)),
        allpos = cumsum([0,for (i=idx(paths)) max_xs[i]-min_xs[i]]),
        totlen = last(allpos),
        fullpath = [for (i = idx(paths)) each left(totlen/2-allpos[i], p=paths[i])],
        cleanpath1 = path_merge_collinear(deduplicate(fullpath)),
        redirpath = altpath == undef? cleanpath1 :
            _ptn_path_redirect(altpath, cleanpath1),
        check = y == undef? 0 :
            assert(is_num(y))
            assert(y < min_y || y > max_y, "Path would be self-crossing"),
        closedpath = y == undef? redirpath :
            [
                [last(redirpath).x, y],
                [redirpath[0].x, y],
                each redirpath,
            ],
        outpath = y == undef || y < 0
            ? closedpath
            : reverse(closedpath)
    ) outpath;


function _ptn_path_redirect(major_path, minor_path, center=true) =
    let(
        major_path2 = path_merge_collinear(major_path, closed=false),
        minor_path2 = resample_path(minor_path, spacing=1, keep_corners=10, closed=false),
        major_length = path_length(major_path2),
        minor_length = abs(last(minor_path).x - minor_path[0].x),
        extend_by = max(0, -(major_length - minor_length)),
        extend_by1 = extend_by * (center? 1/2 : 0),
        extend_by2 = extend_by * (center? 1/2 : 1),
        vec1 = unit(major_path2[0] - major_path[1], LEFT),
        vec2 = unit(last(major_path2) - select(major_path,-2), RIGHT),
        major_path3 = [
            major_path2[0] + vec1 * extend_by1,
            each select(major_path2, 1, -2),
            last(major_path2) + vec2 * extend_by2,
        ],
        major_length2 = path_length(major_path3),
        xoff = (center? (major_length2 - minor_length)/2 : 0),
        minor_path3 = left(minor_path2[0].x-xoff, p=minor_path2),
        opath = path_merge_collinear(deduplicate([
            for (pt = minor_path3)
                let(
                    pinfo = path_cut_points(major_path3, pt.x, closed=false, direction=true)
                )
                pinfo[0] + unit(pinfo[3],BACK) * pt.y,
        ]))
    ) opath;



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
