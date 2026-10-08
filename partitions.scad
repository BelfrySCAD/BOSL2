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
/// half_of()
// Usage: As a 3D module
//   half_of([v], [cp], [s], [cut_path=], [cut_angle=], [offset=], [show_frameref=], [convexity=]) CHILDREN;
// Usage: As a 2D module
//   half_of(planar=true, [v], [cp], [s], [cut_path=], [offset=], [convexity=]) CHILDREN;
// Usage: As a function with a 2D polygon or region
//   result = half_of(p, [v], [cp], [cut_path=], [offset=]);
// Usage: As a function with a VNF
//   result = half_of(p, [v], [cp], [offset=]);
//
// Description:
//   Slices an object at a cut plane or a a cut path, and masks away everything that is on one side.  The `v` parameter
//   is either a plane specification or a normal vector.  The `s` parameter is needed for the module
//   version to control the size of the masking cube.  If `s` is too large then the preview display
//   will flip around and display the wrong half, but if it is too small it won't fully mask your
//   model.
//   .
//   The function accepts a VNF or a 2D polygon/region in `p`, returning a VNF or region,
//   respectively; an empty input returns `[]`. You cannot use a cut path with a VNF, nor can you
//   give a plane specification with 2D data. In planar module mode, UP and DOWN are treated as BACK and FWD respectively.
//
// Arguments:
//   p = 2D polygon, region or VNF to slice. Returns a region for 2D input and a VNF for VNF input. (Function version)
//   v = Normal of plane to slice at.  Keeps everything on the side the normal points to.  Default: [0,0,1] (UP)
//   cp = If given as a scalar, moves the cut plane along the normal by the given amount.  If given as a point, specifies a point on the cut plane.  Default: [0,0,0]
//   s = Mask size to use.  Use a number larger than twice your object's largest axis.  If you make this too large, OpenSCAD's preview rendering may display the wrong half.  (Module version)  Default: 100
//   planar = If true, perform a 2D operation.  When planar, a `v` of `UP` or `DOWN` becomes equivalent of `BACK` and `FWD` respectively.  (Module version).  Default: false.  
//   cut_path = A 2D path forming the cut face (not supported for VNFs).  Negative X values in the path will be interpreted as being to the left of the cut plane, when looking at it from the cut-away side, with Z+ up, (or back, if v is UP or DOWN).  Positive X values will be interpreted as being to the right side.  Path Y values equal to 0 are interpreted as being on the cut plane.  Positive Y values are interpreted as being in the direction of the cut plane normal (into the kept side).  Default: undef (cut using a flat plane)
//   cut_angle = The angle in degrees to rotate the cut mask around the plane normal vector, before partitioning.  Only makes sense when using with cut_path= and planar=false. Module only. Default: 0
//   offset = Amount to expand the retained side. With a flat cut this moves the plane opposite its normal; with a cut path it uses a rounded 2D offset. Default: 0
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
        if (r==0) children();
        else offset(r=r) children();
    }
    module ghost_if(cond) {
        if (cond) %children();
        else children();
    }
    req_children($children);
    check = assert(is_vector(v,2) || is_vector(v,3) || is_vector(v,4), "\nv must be a normal vector or plane specification.")
        assert(norm(point3d(v))>0, "\nNormal vector must be nonzero.")
        assert(is_bool(planar))
        assert(is_finite(s) && s>0, "\ns must be positive.")
        assert(is_finite(cut_angle) && is_finite(offset));
    normal = unit(point3d(v));
    cut_normal = !planar ? normal : normal==UP ? BACK : normal==DOWN ? FWD : normal;
    check2 = assert(!planar || cut_normal.z==0, "\nPlanar normal must lie in XY, or be UP/DOWN.")
        assert(!is_vector(v,4) || is_undef(cp), "\nDon't use cp with plane definition.")
        assert(is_undef(cp) || is_finite(cp) || is_vector(cp,2) || is_vector(cp,3), "\ncp must be a distance or point.");
    cut_cp = is_vector(v,4) ? cut_normal * (v[3]/norm(point3d(v))) :
             is_undef(cp) ? [0,0,0] : is_num(cp) ? cp*cut_normal : point3d(cp);
    ppath = is_undef(cut_path)
      ? [[-s/2,0], [+s/2,0]]
      : assert(is_path(cut_path,2), "\ncut_path must be a 2D path.")
        cut_path[0].x < last(cut_path).x ? cut_path : reverse(cut_path);
    mask_path = [
            [min(-s/2, ppath[0].x), +s],
            [min(-s/2, ppath[0].x), ppath[0].y],
            each ppath,
            [max(+s/2, last(ppath).x), last(ppath).y],
            [max(+s/2, last(ppath).x), +s],
        ];
    if (planar) {
        ang = atan2(cut_normal.y,cut_normal.x)-90;
        intersection() {
            children();
            translate(point2d(cut_cp)) rot(ang)
                maybe_offset(r=offset) polygon(mask_path);
        }
    } else {
        xyv = cut_normal==UP ? FWD : cut_normal==DOWN ? BACK : [cut_normal.x,cut_normal.y,0];
        ang = atan2(xyv.y,xyv.x)-90;
        ghost_if(show_frameref) {
            intersection() {
                children();
                translate(cut_cp) rot(cut_angle,v=cut_normal) rot(from=xyv,to=cut_normal)
                    zrot(ang)
                        linear_extrude(height=s,center=true,convexity=convexity)
                            maybe_offset(r=offset) polygon(mask_path);
            }
        }
        if (show_frameref)
            translate(cut_cp) rot(cut_angle,v=cut_normal) rot(from=xyv,to=cut_normal)
                zrot(ang) rot(-120,v=[1,1,1]) frame_ref(s/10);
    }
}


function half_of(p, v=UP, cp, cut_path, cut_angle=0, offset=0) =
    assert(is_finite(offset) && is_finite(cut_angle))
    p==[] ? [] :
    is_vnf(p) ?
        assert(is_vector(v,3) || is_vector(v,4), "\nMust give a 3-vector or plane specification.")
        assert(norm(point3d(v))>0, "\nVector v must be nonzero.")
        assert(is_undef(cut_path), "\nThe cut_path argument is not supported for VNFs.")
        assert(cut_angle==0, "\nThe cut_angle argument is not supported for VNFs.")
        let(
            plane = is_vector(v,4) ? assert(is_undef(cp), "\nDon't use cp with plane definition.") v
                  : is_undef(cp) ? [each v,0]
                  : is_num(cp) ? assert(is_finite(cp)) [each v,cp*norm(v)]
                  : assert(is_vector(cp,3), "\nCenterpoint must be a 3-vector.") [each v,cp*v],
            n = point3d(plane)
        )
        vnf_halfspace([each n,plane[3]-offset*norm(n)],p)
    : is_path(p,2) || is_region(p) ?
        assert(is_vector(v,2) || is_vector(v,3), "\nMust give a 2D normal, or UP/DOWN.")
        assert(norm(v)>0, "\nVector v must be nonzero.")
        let(
            normal = unit(point3d(v)),
            v2 = normal==UP ? [0,1] : normal==DOWN ? [0,-1] :
                 assert(normal.z==0, "\nNormal must lie in XY, or be UP/DOWN.") point2d(normal),
            cp2 = is_undef(cp) ? [0,0] :
                  is_num(cp) ? assert(is_finite(cp)) v2*cp :
                  assert(is_vector(cp,2) || (is_vector(cp,3) && cp.z==0), "\nCenterpoint must be a 2D point.") point2d(cp)
        )
        assert(cut_angle==0, "\nThe cut_angle argument is not supported for paths or regions.")
        let(
            bounds = pointlist_bounds(is_region(p) ? flatten(p) : p),
            s = 2*(abs(offset)+max([for(x=[bounds[0].x,bounds[1].x],y=[bounds[0].y,bounds[1].y]) norm([x,y]-cp2)])),
            ppath = is_undef(cut_path) ? [[-s/2,0],[s/2,0]] :
                assert(is_path(cut_path,2), "\ncut_path must be a 2D path.")
                cut_path[0].x<last(cut_path).x ? cut_path : reverse(cut_path),
            M = move(cp2)*zrot(atan2(v2.y,v2.x)-90),
            raw_path = [
                [min(-s/2,ppath[0].x),s],
                [min(-s/2,ppath[0].x),ppath[0].y],
                each ppath,
                [max(s/2,last(ppath).x),last(ppath).y],
                [max(s/2,last(ppath).x),s]
            ],
            mask = apply(M,offset==0 ? raw_path : offset(deduplicate(raw_path,closed=true),r=offset))
        )
        intersection(mask,p)
    : assert(false, "\nInput must be a 2D polygon, region or VNF.");


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
/// left_half()
// Usage: As a 3D module
//   left_half([s], [x], [cut_path=], [cut_angle=], [offset=], [show_frameref=], [convexity=]) CHILDREN;
// Usage: As a 2D module
//   left_half(planar=true, [s], [x], [cut_path=], [offset=], [convexity=]) CHILDREN;
// Usage: As a function with a 2D polygon or region
//   result = left_half(p, [x], [cut_path=], [offset=]);
// Usage: As a function with a VNF
//   result = left_half(p, [x], [offset=]);
//
// Description:
//   Slices an object at a vertical Y-Z cut plane, and masks away everything that is right of it.
//   The `s` parameter is needed for the module version to control the size of the masking cube.
//   If `s` is too large then the preview display will flip around and display the wrong half,
//   but if it is too small it won't fully mask your model.  
//
// Arguments:
//   p = VNF, 2D polygon or region to slice. Returns a region for 2D input. (Function version)
//   s = Mask size to use.  Use a number larger than twice your object's largest axis.  If you make this too large, OpenSCAD's preview rendering may display the wrong half.  (Module version)  Default: 100
//   x = The X coordinate of the cut-plane.  Default: 0
//   planar = If true, perform a 2D operation.  (Module version)  Default: false. 
//   cut_path = A 2D path forming the cut face (not supported for VNFs).  Negative X values in the path will be interpreted as being to the left of the cut plane, when looking at it from the cut-away side, with Z+ up, (or back, if v is UP or DOWN).  Positive X values will be interpreted as being to the right side.  Path Y values equal to 0 are interpreted as being on the cut plane.  Positive Y values are interpreted as being in the direction of the cut plane normal (into the kept side).  Default: undef (cut using a flat plane)
//   cut_angle = The angle in degrees to rotate the cut mask around the plane normal vector, before partitioning.  Only makes sense when using with cut_path= and planar=false. Module only. Default: 0
//   offset = Amount to expand the retained side. With a flat cut this moves the plane opposite its normal; with a cut path it uses a rounded 2D offset. Default: 0
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
// Usage: As a 3D module
//   right_half([s], [x], [cut_path=], [cut_angle=], [offset=], [show_frameref=], [convexity=]) CHILDREN;
// Usage: As a 2D module
//   right_half(planar=true, [s], [x], [cut_path=], [offset=], [convexity=]) CHILDREN;
// Usage: As a function with a 2D polygon or region
//   result = right_half(p, [x], [cut_path=], [offset=]);
// Usage: As a function with a VNF
//   result = right_half(p, [x], [offset=]);
//
// Description:
//   Slices an object at a vertical Y-Z cut plane, and masks away everything that is left of it.
//   The `s` parameter is needed for the module version to control the size of the masking cube.
//   If `s` is too large then the preview display will flip around and display the wrong half,
//   but if it is too small it won't fully mask your model.  
// Arguments:
//   p = VNF, 2D polygon or region to slice. Returns a region for 2D input. (Function version)
//   s = Mask size to use.  Use a number larger than twice your object's largest axis.  If you make this too large, OpenSCAD's preview rendering may display the wrong half.  (Module version)  Default: 100
//   x = The X coordinate of the cut-plane.  Default: 0
//   planar = If true, perform a 2D operation.  (Module version)  Default: false. 
//   cut_path = A 2D path forming the cut face (not supported for VNFs).  Negative X values in the path will be interpreted as being to the left of the cut plane, when looking at it from the cut-away side, with Z+ up, (or back, if v is UP or DOWN).  Positive X values will be interpreted as being to the right side.  Path Y values equal to 0 are interpreted as being on the cut plane.  Positive Y values are interpreted as being in the direction of the cut plane normal (into the kept side).  Default: undef (cut using a flat plane)
//   cut_angle = The angle in degrees to rotate the cut mask around the plane normal vector, before partitioning.  Only makes sense when using with cut_path= and planar=false. Module only. Default: 0
//   offset = Amount to expand the retained side. With a flat cut this moves the plane opposite its normal; with a cut path it uses a rounded 2D offset. Default: 0
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
// Usage: As a 3D module
//   front_half([s], [y], [cut_path=], [cut_angle=], [offset=], [show_frameref=], [convexity=]) CHILDREN;
// Usage: As a 2D module
//   front_half(planar=true, [s], [y], [cut_path=], [offset=], [convexity=]) CHILDREN;
// Usage: As a function with a 2D polygon or region
//   result = front_half(p, [y], [cut_path=], [offset=]);
// Usage: As a function with a VNF
//   result = front_half(p, [y], [offset=]);
//
// Description:
//   Slices an object at a vertical X-Z cut plane, and masks away everything that is behind it.
//   The `s` parameter is needed for the module version to control the size of the masking cube.
//   If `s` is too large then the preview display will flip around and display the wrong half,
//   but if it is too small it won't fully mask your model.  
// Arguments:
//   p = VNF, 2D polygon or region to slice. Returns a region for 2D input. (Function version)
//   s = Mask size to use.  Use a number larger than twice your object's largest axis.  If you make this too large, OpenSCAD's preview rendering may display the wrong half.  (Module version)  Default: 100
//   y = The Y coordinate of the cut-plane.  Default: 0
//   planar = If true, perform a 2D operation.  (Module version)  Default: false. 
//   cut_path = A 2D path forming the cut face (not supported for VNFs).  Negative X values in the path will be interpreted as being to the left of the cut plane, when looking at it from the cut-away side, with Z+ up, (or back, if v is UP or DOWN).  Positive X values will be interpreted as being to the right side.  Path Y values equal to 0 are interpreted as being on the cut plane.  Positive Y values are interpreted as being in the direction of the cut plane normal (into the kept side).  Default: undef (cut using a flat plane)
//   cut_angle = The angle in degrees to rotate the cut mask around the plane normal vector, before partitioning.  Only makes sense when using with cut_path= and planar=false. Module only. Default: 0
//   offset = Amount to expand the retained side. With a flat cut this moves the plane opposite its normal; with a cut path it uses a rounded 2D offset. Default: 0
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
// Usage: As a 3D module
//   back_half([s], [y], [cut_path=], [cut_angle=], [offset=], [show_frameref=], [convexity=]) CHILDREN;
// Usage: As a 2D module
//   back_half(planar=true, [s], [y], [cut_path=], [offset=], [convexity=]) CHILDREN;
// Usage: As a function with a 2D polygon or region
//   result = back_half(p, [y], [cut_path=], [offset=]);
// Usage: As a function with a VNF
//   result = back_half(p, [y], [offset=]);
//
// Description:
//   Slices an object at a vertical X-Z cut plane, and masks away everything that is in front of it.
//   The `s` parameter is needed for the module version to control the size of the masking cube.
//   If `s` is too large then the preview display will flip around and display the wrong half,
//   but if it is too small it won't fully mask your model.  
// Arguments:
//   p = VNF, 2D polygon or region to slice. Returns a region for 2D input. (Function version)
//   s = Mask size to use.  Use a number larger than twice your object's largest axis.  If you make this too large, OpenSCAD's preview rendering may display the wrong half.  (Module version)  Default: 100
//   y = The Y coordinate of the cut-plane.  Default: 0
//   planar = If true, perform a 2D operation.  (Module version)  Default: false.
//   cut_path = A 2D path forming the cut face (not supported for VNFs).  Negative X values in the path will be interpreted as being to the left of the cut plane, when looking at it from the cut-away side, with Z+ up, (or back, if v is UP or DOWN).  Positive X values will be interpreted as being to the right side.  Path Y values equal to 0 are interpreted as being on the cut plane.  Positive Y values are interpreted as being in the direction of the cut plane normal (into the kept side).  Default: undef (cut using a flat plane)
//   cut_angle = The angle in degrees to rotate the cut mask around the plane normal vector, before partitioning.  Only makes sense when using with cut_path= and planar=false. Module only. Default: 0
//   offset = Amount to expand the retained side. With a flat cut this moves the plane opposite its normal; with a cut path it uses a rounded 2D offset. Default: 0
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
// Usage: As a 3D module
//   bottom_half([s], [z], [cut_path=], [cut_angle=], [offset=], [show_frameref=], [convexity=]) CHILDREN;
// Usage: As a 2D module
//   bottom_half([s], [z], planar=true, [cut_path=], [offset=], [convexity=]) CHILDREN;
// Usage: As a function with a 2D polygon or region
//   result = bottom_half(p, [z], planar=true, [cut_path=], [offset=]);
// Usage: As a function with a VNF
//   result = bottom_half(p, [z], [offset=]);
//
// Description:
//   Slices an object at a horizontal X-Y cut plane, and masks away everything that is above it.
//   The `s` parameter is needed for the module version to control the size of the masking cube.
//   If `s` is too large then the preview display will flip around and display the wrong half,
//   but if it is too small it won't fully mask your model. 
// Arguments:
//   p = VNF, 2D polygon or region to slice. Returns a region for 2D input. (Function version)
//   s = Mask size to use.  Use a number larger than twice your object's largest axis.  If you make this too large, OpenSCAD's preview rendering may display the wrong half.  (Module version)  Default: 100
//   z = The Z coordinate of the cut-plane.  Default: 0
//   planar = If true, use the 2D interpretation of {{front_half()}}, with z specifying the Y cut coordinate. Applies to both module and function. Default: false.
//   cut_path = A 2D path forming the cut face (not supported for VNFs).  Negative X values in the path will be interpreted as being to the left of the cut plane, when looking at it from the cut-away side, with Z+ up, (or back, if v is UP or DOWN).  Positive X values will be interpreted as being to the right side.  Path Y values equal to 0 are interpreted as being on the cut plane.  Positive Y values are interpreted as being in the direction of the cut plane normal (into the kept side).  Default: undef (cut using a flat plane)
//   cut_angle = The angle in degrees to rotate the cut mask around the plane normal vector, before partitioning.  Only makes sense when using with cut_path= and planar=false. Module only. Default: 0
//   offset = Amount to expand the retained side. With a flat cut this moves the plane opposite its normal; with a cut path it uses a rounded 2D offset. Default: 0
//   show_frameref = If true, draws a frame reference arrow set in the center of the cut plane, to give you a clear idea on how the cut_path slice will be oriented.  Module only.  Default: false
//   convexity = Max number of times a line could intersect a wall of the surface being formed. Module only.  Default: 10
// Examples:
//   bottom_half() sphere(r=20);
//   bottom_half(z=-10) sphere(r=20);
// Example(2D): Working in 2D
//   bottom_half(z=5,planar=true) circle(r=20);
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
// Usage: As a 3D module
//   top_half([s], [z], [cut_path=], [cut_angle=], [offset=], [show_frameref=], [convexity=]) CHILDREN;
// Usage: As a 2D module
//   top_half(planar=true, [s], [z], [cut_path=], [offset=], [convexity=]) CHILDREN;
// Usage: As a function with a 2D polygon or region
//   result = top_half(p, [z], planar=true, [cut_path=], [offset=]);
// Usage: As a function with a VNF
//   result = top_half(p, [z], [offset=]);
//
// Description:
//   Slices an object at a horizontal X-Y cut plane, and masks away everything that is below it.
//   The `s` parameter is needed for the module version to control the size of the masking cube.
//   If `s` is too large then the preview display will flip around and display the wrong half,
//   but if it is too small it won't fully mask your model.  
// Arguments:
//   p = VNF, 2D polygon or region to slice. Returns a region for 2D input. (Function version)
//   s = Mask size to use.  Use a number larger than twice your object's largest axis.  If you make this too large, OpenSCAD's preview rendering may display the wrong half.  (Module version)  Default: 100
//   z = The Z coordinate of the cut-plane.  Default: 0
//   planar = If true, use the 2D interpretation of {{back_half()}}, with z specifying the Y cut coordinate. Applies to both module and function. Default: false.
//   cut_path = A 2D path forming the cut face (not supported for VNFs).  Negative X values in the path will be interpreted as being to the left of the cut plane, when looking at it from the cut-away side, with Z+ up, (or back, if v is UP or DOWN).  Positive X values will be interpreted as being to the right side.  Path Y values equal to 0 are interpreted as being on the cut plane.  Positive Y values are interpreted as being in the direction of the cut plane normal (into the kept side).  Default: undef (cut using a flat plane)
//   cut_angle = The angle in degrees to rotate the cut mask around the plane normal vector, before partitioning.  Only makes sense when using with cut_path= and planar=false. Module only. Default: 0
//   offset = Amount to expand the retained side. With a flat cut this moves the plane opposite its normal; with a cut path it uses a rounded 2D offset. Default: 0
//   show_frameref = If true, draws a frame reference arrow set in the center of the cut plane, to give you a clear idea on how the cut_path slice will be oriented.  Module only.  Default: false
//   convexity = Max number of times a line could intersect a wall of the surface being formed. Module only.  Default: 10
// Examples(Spin,VPD=175):
//   top_half() sphere(r=20);
//   top_half(z=5) sphere(r=20);
// Example(2D): Working in 2D
//   top_half(z=5,planar=true) circle(r=20);
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



// Section: Partitioning into Interlocking Pieces


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
        check = assert(is_finite(l) && l>0, "\nl must be positive.")
            assert(is_finite(h) && h>0, "\nh must be positive.")
            assert(is_finite(gap) && gap>=0, "\ngap must be nonnegative.")
            assert(is_bool(cutpath_centered))
            assert((is_finite(cutsize) && cutsize>0) || (is_vector(cutsize,2) && min(cutsize)>0), "\ncutsize must be a positive number or positive 2-vector.")
            assert(is_string(cutpath) || is_path(cutpath,2)),
        cutsize = is_vector(cutsize)? cutsize : [cutsize*2, cutsize],
        cutpath = is_path(cutpath)? cutpath :
            _partition_subpath(cutpath),
        reps_raw = 1 + floor((l - cutsize.x) / (cutsize.x + gap)),
        _reps = reps_raw%2==0 && cutpath_centered ? reps_raw-1 : reps_raw,
        reps = max(1, _reps),
        cplen = reps*cutsize.x + max(0, reps-1)*gap,
        path = deduplicate(concat(
            [[min(-l/2,-cplen/2), cutpath[0].y*cutsize.y]],
            [for (i=[0:1:reps-1], pt=cutpath) v_mul(pt,cutsize)+[i*(cutsize.x+gap) - cplen/2, 0]],
            [[max(l/2,cplen/2), last(cutpath).y*cutsize.y]]
        ))
    ) path;


// Module: partition_mask()
// Synopsis: Creates a mask to remove half an object with the remaining half suitable for reassembly.
// SynTags: Geom
// Topics: Partitions, Masking, Paths
// See Also: partition_cut_mask(), partition(), dovetail()
// Usage:
//   partition_mask([l], [w], [h], [cutsize=], [cutpath=], [gap=], [cutpath_centered=], [inverse=], [$slop=], [anchor=], [spin=], [orient=], [convexity=]) [ATTACHMENTS];
// Description:
//   Creates a mask that you can use to difference or intersect with an object to remove half of it,
//   leaving behind a side designed to allow assembly of the sub-parts.
//   Anchors describe the nominal centered box [l,w,h], with CENTER at the cut datum, not the
//   physical mask bounds. Pattern excursions, inverse, and slop do not change these anchors.
// Arguments:
//   l = Nominal length of the cut axis. Default: 100
//   w = Nominal object width; the mask extends this far back from the cut datum. Default: 100
//   h = Height of the part to be masked. Default: 100
//   ---
//   cutsize = [along-cut length, transverse size] of each pattern; scalar c means [2*c,c]. Default: 10
//   cutpath = The cutpath to use.  Standard named paths are "flat", "sawtooth", "sinewave", "comb", "finger", "dovetail", "hammerhead", and "jigsaw".  Alternatively, you can give a cutpath as a 2D path, where X is between 0 and 1, and Y is between -0.5 and 0.5. Default: "jigsaw"
//   gap = Empty gaps between cutpath iterations.  Default: 0
//   cutpath_centered = Ensures the cutpath is always centered.  Default: true
//   inverse = If true, create the complementary mask. Default: false
//   convexity = Max number of times a line could intersect a wall of the surface being formed. Module only.  Default: 10
//   anchor = Translate so anchor point is at origin (0,0,0). See [anchor](attachments.scad#subsection-anchor). Default: `CENTER`
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
    check = assert(is_finite(w) && w>0, "\nw must be positive.")
            assert(is_bool(inverse));
    cutsize = is_vector(cutsize)? cutsize : [cutsize*2, cutsize];
    path = _partition_cutpath(l, h, cutsize, cutpath, gap, cutpath_centered);
    fullpath = concat(path, [[last(path).x, w*(inverse?-1:1)], [path[0].x, w*(inverse?-1:1)]]);
    attachable(anchor,spin,orient, size=[l,w,h]) {
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
//   partition_cut_mask([l], [h], [cutsize=], [cutpath=], [gap=], [cutpath_centered=], [$slop=], [anchor=], [spin=], [orient=], [convexity=]) [ATTACHMENTS];
// Description:
//   Creates a mask that you can use to difference with an object to cut it into two sub-parts that can be assembled.
//   The `$slop` value is important to get the proper fit and should probably be smaller than 0.2.  The examples below
//   use larger values to make the mask easier to see.
//   Anchors describe the nominal pattern envelope [l,cutsize.y,h], centered at the cut datum,
//   not the actual bounds of the thin stroke.
// Arguments:
//   l = Length of the cut axis. Default: 100
//   h = Height of the part to be masked. Default: 100
//   ---
//   cutsize = 2-vector giving size of each pattern: [along-cut length, transverse width], or a scalar, where c means `[2*c,c]`. Default: 10
//   cutpath = The cutpath to use.  Standard named paths are "flat", "sawtooth", "sinewave", "comb", "finger", "dovetail", "hammerhead", and "jigsaw".  Alternatively, you can give a cutpath as a 2D path, where X is between 0 and 1, and Y is between -0.5 and 0.5.  Default: "jigsaw"
//   gap = Empty gaps between cutpath iterations.  Default: 0
//   cutpath_centered = Ensures the cutpath is always centered.  Default: true
//   anchor = Translate so anchor point is at origin (0,0,0). See [anchor](attachments.scad#subsection-anchor). Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   convexity = Max number of times a line could intersect a wall of the surface being formed. Module only.  Default: 10
//   $slop = Half the requested cut width. The actual cut width is max(0.1,2*$slop).
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
//   partition([size], [spread], [cutsize=], [cutpath=], [gap=], [cutpath_centered=], [spin=], [$slop=], [convexity=]) CHILDREN;
// Description:
//   Partitions an object into two parts, spread apart a small distance, with matched joining edges.
//   If you only need one side of the partition you can use `$idx` in the children.  
// Arguments:
//   size = Positive [X,Y,Z] object dimensions, or a scalar for equal dimensions. Default: 100
//   spread = The distance to spread the two parts by. Default: 10
//   ---
//   cutsize = [along-cut length, transverse size] of each pattern; scalar c means [2*c,c]. Default: 10
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
//   partition(cutpath="jigsaw", $fn=12) cylinder(h=50, d=80, center=false);
// Example(2D,Med): Using `$idx` to display only the back piece of the partition
//   partition(cutpath="jigsaw", $fn=12)
//     if ($idx==0) cylinder(h=50, d=80, center=false);

module partition(size=100, spread=10, cutsize=10, cutpath="jigsaw", gap=0, cutpath_centered=true, convexity=10, spin=0)
{
    req_children($children);
    size = is_vector(size)? size : [size,size,size];
    cutsize = is_vector(cutsize)? cutsize : [cutsize*2, cutsize];
    check = assert(is_vector(size,3) && min(size)>0, "\nsize must be a positive number or positive 3-vector.")
            assert(is_finite(spin) && is_finite(spread));
    rsize = [abs(cos(spin))*size.x+abs(sin(spin))*size.y,
             abs(sin(spin))*size.x+abs(cos(spin))*size.y, size.z];
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


/// Internal helper: builds one segment of a partition path.

function _ptn_sect(type, length=25, width=25, invert=false) =
    assert(is_finite(length) && length>0 && is_finite(width) && width>0, "\nSection length and width must be positive.")
    // NOTE: these patterns are NOT quite the same as those in _partition_subpath().
    // They are positioned and sometimes formed differently for better alignment, though
    // the overall shapes are nearly the same.
    is_num(type)? assert(is_finite(type) && type>0) [[0,0], [type,0]] :
    invert? yscale(-1, p=_ptn_sect(type, length, width)) :
    is_string(type) && str_find(type, " ") != undef
      ? let(
            pos = str_find(type, " ", last=true),
            opt = substr(type, pos+1),
            type = substr(type, 0, pos)
        )
        opt == "yflip"? yscale(-1, p=_ptn_sect(type, length, width)) :
        opt == "xflip"? let(
                sect = _ptn_sect(type, length, width),
                bounds = pointlist_bounds(sect),
                xpos = (bounds[1].x + bounds[0].x) / 2,
                rsect = reverse(xflip(x=xpos, p=sect))
            ) rsect :
        opt == "addflip" || opt == "wave"? let(
                sect1 = _ptn_sect(type, length, width),
                sect2 = _ptn_sect(str(type, " yflip xflip"), length, width),
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
                sect = _ptn_sect(type, length, width),
                w = last(sect).x,
                osect = path_merge_collinear([
                    for (i = [0:1:reps-1])
                    each right(i*w, sect)
                ])
            ) osect :
        is_digit(opt[0]) && str_find(opt, "x") != undef? let(  // 30x20  (size)
                parts = str_split(opt, "x"),
                newlength = parse_float(parts[0]),
                newwidth = parse_float(parts[1]),
                checks =
                    assert(len(parts) == 2, "Size option expected to be in the form LENGTHxWIDTH.  ie: \"30x25\"")
                    assert(is_finite(newlength) && is_finite(newwidth) && newlength>0 && newwidth>0, "Size option must give two positive dimensions."),
                raw_sect = _ptn_sect(type, length, width),
                bounds = pointlist_bounds(raw_sect),
                extent = bounds[1]-bounds[0],
                sect = assert(extent.x>0, "Cannot resize a section with zero X extent.")
                       scale([newlength/extent.x, extent.y==0 ? 1 : newwidth/extent.y],p=raw_sect)
            ) sect :
        len(opt)>5 && starts_with(opt, "skew:") && (is_digit(opt[5]) || (opt[5]=="-" && is_digit(opt[6])))? let(  // skew:15 (Skewing)
                parts = str_split(opt, ":"),
                angle = parse_float(parts[1]),
                checks =
                    assert(len(parts) == 2, "Skew option expected to be in the form skew:DEGREES.  ie: \"skew:15\"")
                    assert(is_finite(angle) && angle>=-45 && angle<=45, "Bad skew option."),
                raw_sect = _ptn_sect(type, length, width),
                sect = skew(axy=angle, p=raw_sect)
            ) sect :
        len(opt)>6 && starts_with(opt, "pinch:") && (is_digit(opt[6]) || (opt[6]=="-" && len(opt)>7 && is_digit(opt[7])))? let(  // pinch:50 / pinch:50% (percent) / pinch:20deg (angle)
                val_str = substr(opt, 6),
                is_deg = ends_with(val_str, "deg"),
                is_pct = ends_with(val_str, "%"),
                num_str = is_deg? substr(val_str, 0, len(val_str)-3) :
                          is_pct? substr(val_str, 0, len(val_str)-1) :
                          val_str,
                val = parse_float(num_str),
                raw_sect = _ptn_sect(type, length, width),
                minx = min([for (p = raw_sect) p.x]),
                maxx = max([for (p = raw_sect) p.x]),
                w_half = (maxx - minx) / 2,
                midx = (minx + maxx) / 2,
                maxy = max([for (p = raw_sect) abs(p.y)]),
                dx = is_deg && maxy != 0 && w_half != 0 ? maxy * tan(val) / w_half : 0,
                pcnt = is_deg ? (1 - dx) * 100 : val,
                checks =
                    assert(is_finite(val), "Pinch option expected a number.  ie: \"pinch:50\", \"pinch:50%\", or \"pinch:20deg\"")
                    assert(!is_deg || (val > -90 && val < 90), "Pinch angle must be between -90 and 90 degrees.")
                    assert(is_deg || (val >= 0 && val <= 200), "Pinch percent must be 0-200.")
                    assert(!is_deg || pcnt >= 0, "Pinch angle is too large: the pattern would cross itself."),
                sect = maxy == 0
                    ? raw_sect
                    : [for (p = raw_sect) let(u = abs(p.y)/maxy) [(p.x-midx)*lerp(1,pcnt/100,u)+midx, p.y]]
            ) sect :
        type == "flat" && is_digit(opt[0]) && str_find(opt, "x") == undef && str_find(opt, ":") == undef? let(  // "flat 40" explicit length
                flat_len = parse_float(opt),
                checks = assert(is_finite(flat_len) && flat_len > 0, "Flat length option expected to be a positive number.")
            ) [[0,0], [flat_len, 0]] :
        assert(false, str("Bad section option: '",opt,"'"))
      : type == "sinewave"? _ptn_sect("halfsine addflip", length, width)
      : let(
            steps = segs(length/2),
            path =
                type == "flat"?     [[0,0], [1,0]] :
                type == "sawtooth"? [[0,0], [0,1], [1,0]] :
                type == "square"?   [[0,0], [0,1], [1,1], [1,0]] :
                type == "triangle"? [[0,0], [0.5,1], [1,0]] :
                type == "halfsine"? [for (a=lerpn(0,180,max(2,ceil(steps/2)+1))) [a/180,sin(a)]] :
                type == "semicircle"? yscale(2, p=arc(n=max(2,ceil(steps/2)), r=1/2, cp=[1/2, 0], start=180, angle=-180)) :
                type == "comb"?     let(dx=ang_adj_to_opp(2,1)*width/length) assert(dx<=0.5, "width-to-length ratio too large for comb form.") [[0,0],[dx,1],[1-dx,1],[1,0]] :
                type == "finger"?   let(dx=ang_adj_to_opp(20,1)*width/length) assert(dx<=0.5, "width-to-length ratio too large for finger form.") [[0,0],[dx,1],[1-dx,1],[1,0]] :
                type == "dovetail"? let(dx=ang_adj_to_opp(9,1)*width/length/2) assert(dx<0.25, "width-to-length ratio too large for dovetail form.") [[0,0], [0.25+dx,0], [0.25-dx,1], [0.75+dx,1], [0.75-dx,0], [1,0]] :
                type == "hammerhead"? [[0,0], [0.35,0], [0.35,0.5], [0.15,0.5], [0.15,1], [0.85,1], [0.85,0.5], [0.65,0.5], [0.65,0],[1,0]] :
                type == "jigsaw"? [
                    each arc(n=max(2,ceil(steps/4)), r=5/16, cp=[   0, 5/16], start=270, angle= 125),
                    each arc(n=max(2,ceil(steps/2)), r=5/16, cp=[ 1/2,11/16], start=215, angle=-250),
                    each arc(n=max(2,ceil(steps/4)), r=5/16, cp=[   1, 5/16], start=145, angle= 125)
                ] :
                is_path(type)? type :
                assert(false, str("Unsupported partition section type: ", type))
        ) scale([length,width], p=path);


// Function: partition_path()
// Synopsis: Creates a partition path from a path description.
// SynTags: Path
// Topics: Partitions, Masking, Paths
// See Also: partition_cut_mask(), partition()
// Usage:
//   path = partition_path(pathdesc, [repeat=], [y=], [altpath=], [seglen=], [segwidth=]);
// Description:
//   Creates a partition path from a list of segment descriptors.  Each item in `pathdesc` can be:
//   - A numeric scalar: a flat section of that length.
//   - A 2D path: retains its size and Y coordinates and is translated horizontally when assembled.
//   - A string: the name of a standard section pattern, optionally followed by space-separated modifiers.
//   .
//   Standard section pattern names are:
//   - `"flat"`: A flat section.
//   - `"sawtooth"`: A sawtooth halfwave, with the peak to the left.
//   - `"square"`: A square halfwave.
//   - `"triangle"`: A triangular halfwave, with the peak in the center.
//   - `"halfsine"`: Half of a sine-wave.
//   - `"semicircle"`: The top half of a circle.
//   - `"sinewave"`: A full sine wave.
//   - `"comb"`: A modified square halfwave, with walls at a 2° angle.
//   - `"finger"`: A modified square halfwave with walls at a 20° angle.
//   - `"dovetail"`: A modified square halfwave with walls dovetailed out by 9°.
//   - `"hammerhead"`: A shape useful for making T-slots.
//   - `"jigsaw"`: The classic interlocking jigsaw puzzle tab shape.
//   .
//   Section pattern names can be suffixed by one or more modifiers, separated by spaces.  Accepted modifier forms are:
//   - `"<SHAPE> 3x"`: repeats the shape 3 times.
//   - `"<SHAPE> 20x30"`: Fit the preceding result, including earlier modifiers, to a 20x30 bounding box by scaling. The Y=0 baseline is preserved. Flat sections remain flat. By default a section is 25 by 25.
//   - `"<SHAPE> xflip"`: Mirrors the shape along the X axis.
//   - `"<SHAPE> yflip"`: Mirrors the shape along the Y axis.
//   - `"<SHAPE> addflip"`: Concatenate "<SHAPE>" and "<SHAPE> xflip yflip", scaling each copy by 1/2 in both dimensions.
//   - `"<SHAPE> wave"`: Same as "<SHAPE> addflip".
//   - `"<SHAPE> skew:15"`: Skews the shape by 15 degrees.
//   - `"<SHAPE> pinch:33"` or `"<SHAPE> pinch:33%"`: Pinches the top of the shape to 33% the width of the bottom.  Valid range is 0–200.  At 0 the top collapses to a point; at 100 the shape is unchanged; at 200 the top flares to double the width.
//   - `"<SHAPE> pinch:20deg"`: Pinches the top of the shape by angling each wall inward by 20°.  Negative angles flare the walls outward.  Errors if the angle would cause the walls to cross.
//   - `"flat 40"`: A flat section of explicit length 40 (equivalent to placing the scalar `40` in a `pathdesc` list).
//   Modifiers are processed left to right in order.
//   .
//   With `altpath`, X represents distance along the alternate path and Y is displaced along its
//   local normal. Alternate-path corners are included in the sampling. Sharp bends or large
//   pattern excursions can still distort or self-intersect; no miter or round joins are constructed.
// Arguments:
//   pathdesc = A list of segment descriptors: a positive length, a 2D path, or a string pattern with optional modifiers (see Description). Custom paths are translated horizontally, not scaled.
//   ---
//   repeat = Nonnegative integer number of repetitions of `pathdesc`. Zero or an empty `pathdesc` returns []. Default: 1
//   y = If given, closes the generated path by connecting its ends at this Y coordinate, and orients the closed path based on the sign of `y`.
//   altpath = Alternate 2D base path to align the pattern to. Default: undef (no redirection).
//   seglen = Default length for named string segments that do not specify their own size.  Default: 25
//   segwidth = Default width for named string segments that do not specify their own size.  Default: 25
// Examples(2D): Standard section shapes.
//   stroke(partition_path(["flat"]), width=3);
//   stroke(partition_path(["sawtooth"]), width=3);
//   stroke(partition_path(["square"]), width=3);
//   stroke(partition_path(["triangle"]), width=3);
//   stroke(partition_path(["halfsine"], $fn=24), width=3);
//   stroke(partition_path(["semicircle"], $fn=24), width=3);
//   stroke(partition_path(["comb"]), width=3);
//   stroke(partition_path(["finger"]), width=3);
//   stroke(partition_path(["dovetail"]), width=3);
//   stroke(partition_path(["hammerhead"]), width=3);
//   stroke(partition_path(["jigsaw"], $fn=24), width=3);
// Example(2D): Sizing a shape with a `WxH` modifier.
//   stroke(partition_path(["jigsaw 40x20"], $fn=36), width=3);
// Example(2D): Flipping a shape front-to-back with `yflip`.
//   stroke(partition_path(["hammerhead yflip"]), width=3);
// Example(2D): Reversing a shape left-to-right with `xflip`.
//   stroke(partition_path(["sawtooth xflip"]), width=3);
// Example(2D): Building a full wave with `addflip`.
//   stroke(partition_path(["sawtooth addflip"]), width=3);
// Example(2D): Repeating a shape with `Nx`.
//   stroke(partition_path(["sawtooth 5x"]), width=3);
// Example(2D): Combining multiple modifiers.
//   stroke(partition_path(["halfsine addflip yflip 40x30 3x"]), width=3);
// Example(2D): A numeric entry is a flat section of that length.
//   stroke(partition_path([30]), width=3);
// Example(2D): `"flat N"` is equivalent and more readable in mixed lists.
//   stroke(partition_path(["flat 30"]), width=3);
// Example(2D): Skewing a shape.
//   stroke(partition_path(["square skew:15"]), width=3);
// Example(2D): Pinching a shape by percentage.
//   stroke(partition_path(["square pinch:30"]), width=3);
// Example(2D): Pinching a shape by wall angle — positive angles narrow the top.
//   stroke(partition_path(["square pinch:20deg"]), width=3);
// Example(2D): Negative `deg` angles flare the top wider.
//   stroke(partition_path(["square pinch:-9deg"]), width=3);
// Example(2D): A custom 2D segment retains its size and Y coordinates; assembly translates it horizontally.
//   cust_path = scale([40,30], p=yscale(2, p=arc(n=15, r=0.5, cp=[0.5,0], start=180, angle=-180)));
//   stroke(partition_path([cust_path]), width=3);
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
//           width=3
//       );
// Example(2D): Use repeat= to repeat a pattern.
//   linear_extrude(height=100)
//       stroke(
//           partition_path(
//               ["jigsaw", "jigsaw yflip"],
//               repeat=3, $fn=24
//           ),
//           width=3
//       );
// Example(3D): To make a mask that you can intersect with or difference from a part, you can extrude a polygon made from a closed path, offset by a slop width.
//   $slop = 0.2;
//   linear_extrude(height=100)
//       offset(r=-$slop)
//           polygon(
//               partition_path([
//                       40, "jigsaw", 10, "jigsaw yflip", 40,
//                       "hammerhead 30x20",
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

function partition_path(pathdesc, repeat=1, y, altpath, seglen, segwidth) =
    assert(is_list(pathdesc), "\npathdesc must be a list of segment descriptors.")
    assert(is_int(repeat) && repeat>=0, "\nrepeat must be a nonnegative integer.")
    assert(is_undef(seglen) || (is_finite(seglen) && seglen>0), "\nseglen must be positive.")
    assert(is_undef(segwidth) || (is_finite(segwidth) && segwidth>0), "\nsegwidth must be positive.")
    assert(is_undef(y) || is_finite(y), "\ny must be finite.")
    repeat==0 || pathdesc==[] ? [] :
    let(
        paths = [
            for (n = [0:1:repeat-1])
            for (pd = pathdesc)
            is_path(pd,2)? pd :
            is_num(pd)? _ptn_sect(pd) :
            is_string(pd)? _ptn_sect(pd, length=default(seglen,25), width=default(segwidth,25)) :
            assert(false, str("Path descriptor '",pd,"' is invalid."))
        ],
        xes = [for (path = paths) column(path,0)],
        min_xs = [for (xvals = xes) min(xvals)],
        max_xs = [for (xvals = xes) max(xvals)],
        allpos = cumsum([0,for (i=idx(paths)) max_xs[i]-min_xs[i]]),
        totlen = last(allpos),
        fullpath = [for (i = idx(paths)) each
                       assert(max_xs[i]>min_xs[i], "\nPartition sections must have nonzero X extent.")
                       left(totlen/2-allpos[i]+min_xs[i], p=paths[i])],
        cleanpath1 = path_merge_collinear(deduplicate(fullpath)),
        redirpath = altpath == undef? cleanpath1 :
            _ptn_path_redirect(altpath, cleanpath1),
        bounds = pointlist_bounds(redirpath),
        check = y == undef ? 0 :
            assert(y < bounds[0].y || y > bounds[1].y, "\nClosure y must lie outside the final path's Y extent."),
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
    assert(is_path(major_path,2), "\naltpath must be a 2D path.")
    let(
        major_path2 = path_merge_collinear(major_path, closed=false),
        minor_path2 = resample_path(minor_path, spacing=1, keep_corners=10, closed=false),
        major_length = path_length(major_path2),
        minor_length = abs(last(minor_path).x - minor_path[0].x),
        extend_by = max(0, -(major_length - minor_length)),
        extend_by1 = extend_by * (center? 1/2 : 0),
        extend_by2 = extend_by * (center? 1/2 : 1),
        vec1 = unit(major_path2[0] - major_path2[1], LEFT),
        vec2 = unit(last(major_path2) - major_path2[len(major_path2)-2], RIGHT),
        major_path3 = [
            major_path2[0] + vec1 * extend_by1,
            each slice(major_path2, 1, -2),
            last(major_path2) + vec2 * extend_by2,
        ],
        major_length2 = path_length(major_path3),
        xoff = (center? (major_length2 - minor_length)/2 : 0),
        minor_path3 = left(minor_path2[0].x-xoff, p=minor_path2),
        corner_dists = slice(cumsum([0, for(i=[1:1:len(major_path3)-1]) norm(major_path3[i]-major_path3[i-1])]),1,-2),
        sampled_path = _ptn_insert_x(minor_path3,corner_dists),
        opath = path_merge_collinear(deduplicate([
            for (pt = sampled_path)
                let(
                    pinfo = path_cut_points(major_path3, max(0,pt.x), closed=false, direction=true)
                )
                pinfo[0] + unit(pinfo[3],BACK) * pt.y,
        ]))
    ) opath;



/// Insert each crossed base-path corner distance in traversal order, including
/// when the pattern doubles back in X. Do not change its interpolation or normals.
function _ptn_insert_x(path, xs) = [
    for(i=[0:1:len(path)-2]) each
        let(a=path[i],b=path[i+1], dx=b.x-a.x)
        [a, if(dx!=0)
            for(x=dx>0 ? xs : reverse(xs))
                let(t=(x-a.x)/dx)
                if(t>0 && t<1) lerp(a,b,t)],
    last(path)
];


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
