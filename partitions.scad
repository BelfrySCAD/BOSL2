//////////////////////////////////////////////////////////////////////
// LibFile: partitions.scad
//   Cut objects with planes or jigsaw-style patterned cuts.  Construct a cutting mask, or pattern cut paths built from
//   pattern elements including jigsaw, dovetail, and hammerhead. 
// Includes:
//   include <BOSL2/std.scad>
// FileGroup: Basic Modeling
// FileSummary: Plane cuts, mating patterned cuts, and partition paths and masks.
// FileFootnotes: STD=Included in std.scad
//////////////////////////////////////////////////////////////////////

_BOSL2_PARTITIONS = is_undef(_BOSL2_STD) && (is_undef(BOSL2_NO_STD_WARNING) || !BOSL2_NO_STD_WARNING) ?
       echo("Warning: partitions.scad included without std.scad; dependencies may be missing\nSet BOSL2_NO_STD_WARNING = true to mute this warning.") true : true;


// Section: Cutting Objects at Planes or with Jigsaw-style Cuts

// Function&Module: half_of()
// Synopsis: Cuts an object at an arbitrary plane, keeping the half on one side, optionally with a jigsaw-style cut.
// SynTags: Geom, VNF, Path, Region
// Topics: Partitions, Masking
// See Also: left_half(), right_half(), front_half(), back_half(), bottom_half(), top_half(), half_mask(), partition_path() 
// Usage: Flat 3D cut
//   half_of([v], [cp], [s], [flip=], [spread=], [offset=]) CHILDREN;
// Usage: Patterned 3D cut
//   half_of([v], [cp], [s], pattern=, [pattern_size=|pattern_width=], [repeat=], [cut_width=], [cut_angle=], [flip=], [spread=], [offset=], [show_frameref=], [convexity=]) CHILDREN;
// Usage: 2D module
//   half_of([v], [cp], [s], planar=true, [pattern=], [pattern_size=|pattern_width=], [repeat=], [cut_width=], [flip=], [spread=], [offset=]) CHILDREN;
// Usage: Function on a 2D polygon or region
//   result = half_of(p, [v], [cp], [pattern=], [pattern_size=|pattern_width=], [repeat=], [cut_width=], [flip=], [spread=], [offset=]);
// Usage: Function on a VNF (flat cuts only)
//   result = half_of(p, [v], [cp], [flip=], [spread=], [offset=]);
// Description:
//   Cuts the children at a plane or patterned interface. By default, keeps the side
//   pointed to by `v`. The function accepts a 2D polygon/region or a VNF and returns a region or
//   VNF, respectively. When you give a VNF you cannot give a pattern.
//   The module performs a 2D operation if you give `planar=true`; the function infers dimensionality from its input.
//   .
//   The basic cut plane will be normal to the vector `v`.  A scalar `cp` places its origin that distance
//   along the unit normal; a point `cp` sets the complete origin, including placement along the
//   interface. A four-vector `v=[A,B,C,D]` instead specifies the plane A*x+B*y+C*z=D and cannot be
//   combined with `cp`. Plane specifications are not supported by the function on 2D data.
//   .
//   The mask is finite: `s` controls its along-cut coverage, retained-side depth and, in 3D,
//   extrusion height. Choose it large enough to cover the object;
//   a value larger than twice the object extent is a useful starting point.  
//   A mask that is too small clips unintended parts, while a very large mask can confuse preview.
//   The function does not require or make use of a mask size.  
//   .
//   The `pattern` parameter is a pattern descriptor or list of descriptors as accepted by 
//   {{partition_path()}}.  The basic descriptor strings are
//   `"sawtooth"`, `"square"`, `"triangle"`, `"halfsine"`,
//   `"semicircle"`, `"sinewave"`, `"comb"`, `"finger"`, `"dovetail"`,
//   `"hammerhead"`, and `"jigsaw"`.  These can be combined with each other or
//   with modifiers to change their size and shape or build up more complex
//   compound patterns.  A simple example is "jigsaw 6x" creates six copies of
//   the jigsaw pattern.  See {{partition_path()}} for details on the pattern specification. 
//   .
//   Pattern width means the X separation between the first and last points, not its bounding box.
//   When patterns are joined they are connected end to end from their first and last points;
//   no space is added for overhangs.  
//   A scalar `pattern_size` scales X and Y uniformly so the pattern is the specified width; `pattern_size=[w,h]` scales
//   X and Y independently to the specified size.  If you set `pattern_width` then the pattern is stretched in X to the specified
//   width, while Y values remain unchanged and do not scale.  The `pattern_size` and `pattern_width` options are
//   mutually exclusive and operate before repetition. Scaling in X is
//   about the middle point between the endpoints; scaling in Y is about Y=0.
//   You will generally want your entire cut to be a little bit shorter than your object so that
//   the cut geometry doesn't produce detached pieces near the boundary.  By setting one of these
//   parameters you can stretch or shrink a pattern so it fits on your object.  
//   .
//   The other way to expand a pattern to fit your object is by repetition.  You can repeat
//   a single unit as described above by adding a multiplier to its string.  If you give
//   `cut_width` then your entire (possibly compound) pattern is repeated as many times
//   as possible in the specified width.  You can use `repeat="odd"`, `"even"`
//   to require that the number of copies be odd or even, which controls how the copies
//   will center on your shape: in the odd case one copy will be centered and in the even case
//   the two copies will meet at the center.  As usual, the size of the pattern is determined
//   by its endpoint span, not its bounding box.  If you set `repeat="any"` then either case
//   is permitted.  You can also give `repeat=n` to produce exactly `n` copies, in which
//   case you cannot give `cut_width`.  
//   .
//   In order to produce the mating part give `flip=true`.  Giving 
//   `flip="both"` produces both sides from
//   the same cut pattern. At zero offset and zero spread they reconstruct the original object
//   (within mask coverage).  The module does not preserve separately addressable solids in that case.
//   With `flip="both"` the `spread` parameter gives the space between the two halves: both are moved by half the spread
//   away from the cut surface.  The spread defaults to `H+2*max(offset,0)+max(1,0.1*H)`, where `H`
//   is the actual Y span of the cut pattern.  The module sets `$idx` to 0 for the normal side and 1 for the opposite side.
//   .
//   The `offset` parameter provides fitting clearance: A negative value shrinks the retained side
//   away from the cut plane; a positive value expands the shape, making the fit tighter.
//   The offset is calculated using a rounded 2D offset() call.
//   .
//   The Y=0 point of the pattern lies on the cut plane at `cp`.  Positive Y points along the cut normal.
//   The `cut_angle` parameter rotates the cutting surface around that cut normal.  If you need help
//   understanding the orientation of your cut, enable `show_frameref` which displays a coordinate frame
//   where Y (green) is the normal pointing into the retained side and X (red) shows the cut path direction.  
// Arguments:
//   p = Polygon, region, or VNF to cut. Function only.
//   v = Cut normal or plane specification. Default: UP
//   cp = Cut-frame origin as a point or normal distance. Default: origin
//   s = Finite mask size. Module only. Default: 100
//   ---
//   planar = (module) Perform a 2D operation. Default: false
//   pattern = Descriptor or list of descriptors suitable for {{partition_path()}}. Default: flat cut
//   pattern_size = If a scalar then uniformly scale the pattern to specified width; if [width, height] then scale the pattern to that size.
//   pattern_width = stretch the pattern width to specified dimension while leaving Y unchanged.
//   repeat = If `cut_width` is given then "odd", "even" or "any" to require an odd number, even number or any number of repeats respectively.   If `cut_width` is not given, then the exact number of pattern copies to generate.  Default: "odd" with `cut_width`, 1 without
//   cut_width = Available width for automatic repetition. Default: undef
//   cut_angle = Rotation about the normal. 3D module only. Default: 0
//   flip = If false keep the normal side; if true keep the opposite side; if "both" keep both sides with optional spread.  Default: false
//   spread = Separation between the two halves when `flip="both"`.  Default: see above
//   offset = Expansion of each retained side; negative shrinks to provide fit clearance. Default: 0
//   show_frameref = Ghost the results and show the cut frame. 3D module only. Default: false
//   convexity = Preview convexity. Module only. Default: 10
// Side Effects:
//   `$idx` is set to 0 on the normal side and 1 on the opposite side
// Examples:
//   half_of(DOWN+BACK,cp=[0,-10,0]) cylinder(h=40,r1=10,r2=0);
//   half_of(LEFT,s=200,flip=true) sphere(d=50);
// Example(2D,NoScales): Patterned 2D cut with automatic odd repetition.
//   half_of(BACK,planar=true,pattern="jigsaw",pattern_size=[20,8],cut_width=95,s=200)
//       rect([100,60]);
// Example(2D,NoScales): Patterned 2D cut with unconstrained repetition allows one more to fit.  A margin on the sides remains. 
//   half_of(BACK,planar=true,pattern="jigsaw",pattern_size=[20,8],cut_width=95,s=200,repeat="any")
//       rect([100,60]);
// Example(2D,NoScales,Med): Specifying 7 repeats in this case creates a thin edge at the ends, with no margin
//   half_of(BACK,planar=true,pattern="jigsaw",pattern_size=[15,8],s=200,repeat=7)
//       rect([100,60]);
// Example(2D,NoScales,Med): You can avoid the thin edge and fit 7 repeats in by specifying the repeats within the pattern and giving a pattern size smaller than your object to leave a margin
//   half_of(BACK,planar=true,pattern="jigsaw 7x",pattern_size=[90,8],s=200)
//       rect([100,60]);
// Example(2D,NoScales): A scalar `pattern_size` scales X and Y together, so the shapes get shorter as well as narrower from their original 25x25 size, preserving the aspect ratio.
//   half_of(BACK,planar=true,pattern="jigsaw",pattern_size=15,cut_width=95,s=200)
//       rect([100,60]);
// Example(2D,NoScales): `pattern_width` with the same width shrinks only X, so the shapes keep their original height of 25 and their aspect ratio changes.  
//   half_of(BACK,planar=true,pattern="jigsaw",pattern_width=15,cut_width=95,s=200)
//       rect([100,60]);
// Example(3D): Two mating parts, offset for clearance and automatically spread.
//   half_of(BACK,pattern="jigsaw",pattern_size=[20,8],cut_width=95,
//           flip="both",offset=-0.15,s=200)
//       cuboid([100,60,20]);
// Example(3D): Here a compound pattern is replicated in full to fill the space and we use an explicit `spread` to set the gap between the two halves.  Splitting the flat section in half and putting it on both sides of the square keeps the pattern balanced.  
//   half_of(BACK,pattern=["flat 5","square 20x20 pinch:70","flat 5"],pattern_size=[20,8],cut_width=95,
//           flip="both",spread=2,s=200)
//       cuboid([100,60,20]);
// Example(3D): Place a centered pattern on a positive-octant object using `cp`.
//   half_of(BACK,cp=[60,30,10],pattern="dovetail",pattern_size=[20,8],
//           cut_width=100,flip="both",s=300)
//       cube([120,60,20]);
// Example(2D,NoAxes): Use the function to get two regions in their original positions
//   parts=half_of(rect([80,40]),BACK,pattern="triangle 20x8",repeat=3,
//                 flip="both",spread=0,offset=-0.5);
//   region(parts[0]);
//   region(parts[1]);
// Example(2D,NoAxes): Create a cut path that follows a curve.  The length parameter controls how much of the curve is used before the horizontal flat ends appear
//   cut=partition_path("jigsaw 17x7 5x", length=110,
//                      path=arc(n=100,cp=[0,100],r=100, angle=[-120, -60]));
//   half_of(BACK,pattern=cut,flip="both",s=250,spread=0,offset=-0.5,planar=true) rect([120,70]);
// Example(3D): Identify the two child evaluations.
//   half_of(BACK,pattern="jigsaw 20x8",repeat=3,flip="both",s=200)
//       color($idx==0 ? "orange" : "lightblue") cuboid([80,50,15]);
// Example(3D): Using `cut_angle` to rotate the cutting mask
//   half_of(BACK,pattern="jigsaw 3x 60x12",cut_angle=45,s=300)
//       cuboid([140,60,40]);
// Example(3D): Use `show_frameref` to see the cut frame.  The result is ghosted, Y (green) is the normal pointing into the retained side, and X (red) is the direction the cut path runs.
//   half_of(BACK,pattern="jigsaw 20x8",repeat=3,show_frameref=true,s=200)
//       cuboid([80,50,15]);

module half_of(v=UP, cp, s=100, planar=false, pattern, pattern_size, pattern_width,
               repeat, cut_width, cut_angle=0, flip=false, spread, offset=0,
               show_frameref=false, convexity=10)
{
    req_children($children);
    assert(is_bool(planar) && is_bool(show_frameref));
    assert(is_finite(s) && s>0, "\ns must be positive.");
    assert(is_int(convexity) && convexity>0, "\nconvexity must be a positive integer.");
    assert(_half_validate(flip,spread,offset,cut_angle));
    assert(!planar || cut_angle==0, "\ncut_angle is only supported for 3D modules.");
    frame=_half_frame(v,cp,planar);
    n=frame[0];
    c=frame[1];
    seam=_ptn_prepare(default(pattern,[]),pattern_size,pattern_width,repeat,cut_width);
    separation=_half_spread(seam,flip,spread,offset);
    module ghost_if(cond) {
        if(cond) %children();
        else children();
    }
    ghost_if(show_frameref && !planar) {
        if(flip=="both") {
            for(i=[0:1]) {
                $idx=i;
                translate(point3d(n)*(i==0 ? separation/2 : -separation/2))
                    _half_piece(n,c,seam,s,planar,cut_angle,i==1,offset,convexity)
                        children();
            }
        } else {
            // Do not shadow a caller's $idx during a single-side operation.
            _half_piece(n,c,seam,s,planar,cut_angle,flip,offset,convexity)
                children();
        }
    }
    if(show_frameref && !planar)
        multmatrix(_half_matrix(n,c,false,cut_angle))
          frame_ref(s/10);
}

function half_of(p, v=UP, cp, pattern, pattern_size, pattern_width, repeat,
                 cut_width, cut_angle=0, flip=false, spread, offset=0) =
    assert(_half_validate(flip,spread,offset,cut_angle))
    assert(cut_angle==0, "\ncut_angle is only supported for 3D modules.")
    let(seam=_ptn_prepare(default(pattern,[]),pattern_size,pattern_width,repeat,cut_width))
    assert(is_list(seam))
    p==[] ? (flip=="both" ? [[],[]] : []) :
    let(vnf=is_vnf(p))
    assert(vnf || is_path(p,2) || is_region(p),
        "\nInput must be a 2D polygon, region or VNF.")
    assert(!vnf || seam==[], "\nNonempty patterns are not supported for VNFs.")
    assert(!vnf || is_vector(v,3) || is_vector(v,4),
        "\nA VNF requires a 3D normal or a plane specification.")
    assert(vnf || !is_vector(v,4), "\nPlane specifications are not supported for 2D data.")
    let(
        frame=_half_frame(v,cp,!vnf),
        n=frame[0],
        c=frame[1],
        separation=_half_spread(seam,flip,spread,offset)
    )
    flip=="both" ? [for(i=[0:1])
        _half_translate(_half_result(p,vnf,n,c,seam,i==1,offset),
                        n*(i==0 ? separation/2 : -separation/2),vnf)] :
    _half_result(p,vnf,n,c,seam,flip,offset);

function _half_validate(flip, spread, offset, cut_angle) =
    assert(is_bool(flip) || flip=="both", "\nflip must be false, true, or \"both\".")
    assert(is_undef(spread) || is_finite(spread), "\nspread must be finite.")
    assert(is_finite(offset) && is_finite(cut_angle), "\noffset and cut_angle must be finite.")
    true;

function _half_frame(v, cp, planar) =
    assert(is_vector(v,2) || is_vector(v,3) || is_vector(v,4),
        "\nv must be a normal vector or a plane specification.")
    assert(norm(point3d(v))>0, "\nThe cut normal must be nonzero.")
    assert(!is_vector(v,4) || is_undef(cp), "\nDo not combine cp with a plane specification.")
    assert(is_undef(cp) || is_finite(cp) || is_vector(cp,2) || is_vector(cp,3),
        "\ncp must be a finite distance or point.")
    let(
        normal=unit(point3d(v)),
        n=!planar ? normal : normal==UP ? BACK : normal==DOWN ? FWD : normal
    )
    assert(!planar || n.z==0, "\nA planar normal must lie in XY, or be UP/DOWN.")
    assert(!planar || !is_vector(cp,3) || cp.z==0, "\nA planar cp must lie in XY.")
    let(c=is_vector(v,4) ? n*(v[3]/norm(point3d(v))) :
          is_undef(cp) ? [0,0,0] : is_num(cp) ? cp*n : point3d(cp))
    [n,c];

function _half_spread(seam, flip, spread, offset) =
    flip!="both" ? 0 : !is_undef(spread) ? spread :
    let(h=_ptn_yheight(seam)) h+2*max(offset,0)+max(1,0.1*h);

function _half_matrix(n, c, planar, cut_angle=0) =
    planar ? move(c)*zrot(atan2(n.y,n.x)-90) :
    let(xyv=n==UP ? FWD : n==DOWN ? BACK : [n.x,n.y,0],
        angle=atan2(xyv.y,xyv.x)-90)
    move(c)*rot(cut_angle,v=n)*rot(from=xyv,to=n)*zrot(angle);

function _half_mask(seam, s, flip) =
    let(
        p=seam==[] ? [[-s/2,0],[s/2,0]] : seam,
        // Closure must lie outside the seam, even when its excursions exceed s.
        ys=column(p,1),
        y=flip ? min(-s,min(ys)-1) : max(s,max(ys)+1),
        leftx=min(-s/2,p[0].x),
        rightx=max(s/2,last(p).x),
        out=deduplicate(concat([[leftx,y],[leftx,p[0].y]],p,
                               [[rightx,last(p).y],[rightx,y]]),closed=true)
    ) flip ? reverse(out) : out;

module _half_piece(n, c, seam, s, planar, cut_angle, flip, amount, convexity)
{
    module mask2d(side) {
        if(amount==0) polygon(_half_mask(seam,s,side));
        else offset(r=amount) polygon(_half_mask(seam,s,side));
    }
    module mask(side) {
        multmatrix(_half_matrix(n,c,planar,cut_angle)) {
            if(planar) mask2d(side);
            else linear_extrude(height=s,center=true,convexity=convexity) mask2d(side);
        }
    }
    if(flip && amount==0) {
        // Reuse the SAME transformed seam mesh. Independently extruding the opposite
        // outline can triangulate rounded-off oblique quads differently in CGAL.
        // With sufficient mask coverage, subtraction is the exact complementary half.
        difference() {
            union() children();
            mask(false);
        }
    } else {
        intersection() {
            union() children();
            mask(flip);
        }
    }
}

function _half_result(p, vnf, n, c, seam, flip, amount) =
    vnf ? let(sign=flip ? -1 : 1)
        vnf_halfspace([each sign*n,sign*(c*n)-amount],p) :
    let(
        c2=point2d(c),
        bounds=pointlist_bounds(is_region(p) ? flatten(p) : p),
        s=max(1,2*(abs(amount)+max([
            for(x=[bounds[0].x,bounds[1].x],y=[bounds[0].y,bounds[1].y])
                norm([x,y]-c2)]))),
        raw=_half_mask(seam,s,flip),
        mask=amount==0 ? raw : offset(raw,r=amount),
        placed=apply(move(c2)*zrot(atan2(n.y,n.x)-90),mask)
    ) mask==[] ? [] : intersection(placed,p);

function _half_translate(p, v, vnf) =
    p==[] ? [] :
    vnf ? [[for(pt=p[0]) pt+v],p[1]] :
          [for(poly=p) [for(pt=poly) pt+point2d(v)]];


// Function&Module: left_half()
// Synopsis: Cuts an object at the YZ plane, keeping the left half, optionally with a jigsaw-style cut.
// SynTags: Geom, VNF, Path, Region
// Topics: Partitions, Masking
// See Also: half_of(), right_half(), front_half(), back_half(), bottom_half(), top_half(), half_mask(), partition_path()
// Usage: Flat 3D cut
//   left_half([s], [x], [flip=], [spread=], [offset=]) CHILDREN;
// Usage: Patterned 3D cut
//   left_half([s], [x], pattern=, [pattern_size=|pattern_width=], [repeat=], [cut_width=], [cut_angle=], [flip=], [spread=], [offset=], [show_frameref=], [convexity=]) CHILDREN;
// Usage: 2D module
//   left_half([s], [x], planar=true, [pattern=], [pattern_size=|pattern_width=], [repeat=], [cut_width=], [flip=], [spread=], [offset=]) CHILDREN;
// Usage: Function on a 2D polygon or region
//   result = left_half(p, [x], [pattern=], [pattern_size=|pattern_width=], [repeat=], [cut_width=], [flip=], [spread=], [offset=]);
// Usage: Function on a VNF (flat cuts only)
//   result = left_half(p, [x], [flip=], [spread=], [offset=]);
// Description:
//   Cuts the children at the YZ plane at X=`x`, or at a patterned interface lying in that plane,
//   keeping the left (-X) side by default.  This is a wrapper for {{half_of()}} with `v=LEFT`.  
//   The function accepts a 2D polygon/region or a
//   VNF and returns a region or VNF, respectively.  When you give a VNF you cannot give a pattern.
//   The module performs a 2D operation if you give `planar=true`; the function infers dimensionality from its input.
//   .
//   The mask is finite: `s` controls its along-cut coverage, retained-side depth and, in 3D,
//   extrusion height.  The mask is centered on the frame origin `[x,0,0]`: it spans Y and Z from -s/2 to s/2 (only Y if `planar=true`) and reaches `s` from the plane into the retained side, toward -X (toward +X when `flip=true`).  An object that lies far from Y=0 or Z=0 therefore needs a larger `s`.
//   Choose `s` large enough to cover the object; a value larger than twice the object extent is a useful
//   starting point.  A mask that is too small clips unintended parts, while a very large mask can confuse preview.
//   The function calculates its own mask coverage from the 2D input.
//   .
//   The `pattern` parameter is a pattern descriptor or list of descriptors as accepted by
//   {{partition_path()}}.  The basic descriptor strings are
//   `"sawtooth"`, `"square"`, `"triangle"`, `"halfsine"`,
//   `"semicircle"`, `"sinewave"`, `"comb"`, `"finger"`, `"dovetail"`,
//   `"hammerhead"`, and `"jigsaw"`.  These can be combined with each other or
//   with modifiers to change their size and shape or build up more complex
//   compound patterns.  A simple example is "jigsaw 6x" creates six copies of
//   the jigsaw pattern.  See {{partition_path()}} for details on the pattern specification.
//   .
//   Pattern width means the X separation between the first and last points, not its bounding box.
//   When patterns are joined they are connected end to end from their first and last points;
//   no space is added for overhangs.
//   A scalar `pattern_size` scales X and Y uniformly so the pattern is the specified width; `pattern_size=[w,h]` scales
//   X and Y independently to the specified size.  If you set `pattern_width` then the pattern is stretched in X to the specified
//   width, while Y values remain unchanged and do not scale.  The `pattern_size` and `pattern_width` options are
//   mutually exclusive and operate before repetition. Scaling in X is
//   about the middle point between the endpoints; scaling in Y is about Y=0.
//   You will generally want your entire cut to be a little bit shorter than your object so that
//   the cut geometry doesn't produce detached pieces near the boundary.  By setting one of these
//   parameters you can stretch or shrink a pattern so it fits on your object.
//   .
//   The other way to expand a pattern to fit your object is by repetition.  You can repeat
//   a single unit as described above by adding a multiplier to its string.  If you give
//   `cut_width` then your entire (possibly compound) pattern is repeated as many times
//   as possible in the specified width.  You can use `repeat="odd"`, `"even"`
//   to require that the number of copies be odd or even, which controls how the copies
//   will center on your shape: in the odd case one copy will be centered and in the even case
//   the two copies will meet at the center.  As usual, the size of the pattern is determined
//   by its endpoint span, not its bounding box.  If you set `repeat="any"` then either case
//   is permitted.  You can also give `repeat=n` to produce exactly `n` copies, in which
//   case you cannot give `cut_width`.
//   .
//   In order to produce the mating part give `flip=true`, which keeps the right (+X) side of the SAME interface.
//   Flipping does not rotate or reflect the pattern or move the cut: pattern Y=0 stays on the cut plane and
//   positive pattern Y still points LEFT (-X).  Giving `flip="both"` produces both sides from
//   the same cut pattern. At zero offset and zero spread they reconstruct the original object
//   (within mask coverage).  The module does not preserve separately addressable solids in that case.
//   With `flip="both"` the `spread` parameter gives the space between the two halves: both are moved by half the spread
//   away from the cut surface, so the left piece moves toward -X and the right piece toward +X.  The spread defaults to `H+2*max(offset,0)+max(1,0.1*H)`, where `H`
//   is the actual Y span of the cut pattern.  The module sets `$idx` to 0 for the normal side and 1 for the opposite side;
//   the function returns `[normal_side,opposite_side]`.  Without `flip="both"`, `$idx` is not set and the function returns a single region or VNF.
//   .
//   The `offset` parameter provides fitting clearance: A negative value shrinks the retained side
//   away from the cut plane; a positive value expands the shape, making the fit tighter.
//   The offset is calculated using a rounded 2D offset() call.
//   .
//   The Y=0 point of the pattern lies on the cut plane at `x`.  Positive Y points along the cut normal.
//   The `cut_angle` parameter rotates the cutting surface around that cut normal. Here that rotation is about the line through `[x,0,0]` parallel to X; `cut_angle=90` makes the seam run along Z and extrudes it along Y.
//   If you need help understanding the orientation of your cut, enable `show_frameref` which displays a coordinate frame
//   where Y (green) is the normal pointing into the retained side and X (red) shows the cut path direction.
// Arguments:
//   p = Polygon, region, or VNF to cut. Function only.
//   s = Finite mask size. Module only. Default: 100
//   x = X coordinate of the cut plane. The pattern is centered at Y=0 on that plane. Default: 0
//   ---
//   planar = (module) Perform a 2D operation. Default: false
//   pattern = Descriptor or list of descriptors suitable for {{partition_path()}}. Default: flat cut
//   pattern_size = If a scalar then uniformly scale the pattern to specified width; if [width, height] then scale the pattern to that size.
//   pattern_width = stretch the pattern width to specified dimension while leaving Y unchanged.
//   repeat = If `cut_width` is given then "odd", "even" or "any" to require an odd number, even number or any number of repeats respectively.   If `cut_width` is not given, then the exact number of pattern copies to generate.  Default: "odd" with `cut_width`, 1 without
//   cut_width = Available width for automatic repetition. Default: undef
//   cut_angle = Rotation about the normal. 3D module only. Default: 0
//   flip = If false keep the normal side; if true keep the opposite side; if "both" keep both sides with optional spread.  Default: false
//   spread = Separation between the two halves when `flip="both"`.  Default: see above
//   offset = Expansion of each retained side; negative shrinks to provide fit clearance. Default: 0
//   show_frameref = Ghost the results and show the cut frame. 3D module only. Default: false
//   convexity = Preview convexity. Module only. Default: 10
// Side Effects:
//   `$idx` is set to 0 on the normal side and 1 on the opposite side when `flip="both"`.
// Examples:
//   left_half() sphere(r=20);
//   left_half(x=5,flip=true) sphere(r=20);
// Example(2D,NoScales): Patterned 2D cut with automatic odd repetition.
//   left_half(planar=true,pattern="jigsaw",pattern_size=[20,8],cut_width=95,s=200)
//       rect([60,100]);
// Example(2D,NoScales): Patterned 2D cut with unconstrained repetition allows one more to fit.  A margin on the sides remains
//   left_half(planar=true,pattern="jigsaw",pattern_size=[20,8],cut_width=95,s=200,repeat="any")
//       rect([60,100]);
// Example(2D,NoScales): Specifying 7 repeats in this case creates a thin edge at the ends
//   left_half(planar=true,pattern="jigsaw",pattern_size=[15,8],s=200,repeat=7)
//       rect([60,100]);
// Example(2D,NoScales): You can avoid the thin edge and fit 7 repeats in by specifying the repeats within the pattern and giving a pattern size smaller than your object to leave a margin
//   left_half(planar=true,pattern="jigsaw 7x",pattern_size=[90,8],s=200)
//       rect([60,100]);
// Example(2D,NoScales): A scalar `pattern_size` scales X and Y together, so the shapes get shorter as well as narrower from their original 25x25 size, preserving the aspect ratio.
//   left_half(planar=true,pattern="jigsaw",pattern_size=15,cut_width=95,s=200)
//       rect([60,100]);
// Example(2D,NoScales): `pattern_width` with the same width shrinks only X, so the shapes keep their original height of 25 and their aspect ratio changes.  
//   left_half(planar=true,pattern="jigsaw",pattern_width=15,cut_width=95,s=200)
//       rect([60,100]);
// Example(3D): Two mating parts, offset for clearance and automatically spread.
//   left_half(pattern="jigsaw",pattern_size=[20,8],cut_width=95,
//       flip="both",offset=-0.15,s=200)
//       cuboid([60,100,20]);
// Example(3D): Here a compound pattern is replicated in full to fill the space and we use an explicit `spread` to set the gap between the two halves.  
//   left_half(pattern=["flat 5","square 20x20 pinch:70","flat 5"],pattern_size=[20,8],cut_width=95,
//           flip="both",spread=2,s=200)
//       cuboid([60,100,20]);
// Example(3D): Place the cut through the middle of an object that is not centered on the origin by giving `x`.
//   left_half(x=30,pattern="dovetail",pattern_size=[20,8],
//       cut_width=95,flip="both",s=300)
//       translate([0,-50,0]) cube([60,100,20]);
// Example(2D,NoAxes): Use the function to get two regions in their original positions
//   parts=left_half(rect([40,80]),pattern="triangle 20x8",repeat=3,
//             flip="both",spread=0,offset=-0.5);
//   region(parts[0]);
//   region(parts[1]);
// Example(2D,NoAxes): Create a cut path that follows a curve.  The length parameter controls how much of the curve is used before the horizontal flat ends appear
//   cut=partition_path("jigsaw 17x7 5x", length=110,
//                      path=arc(n=100,cp=[0,100],r=100, angle=[-120, -60]));
//   left_half(pattern=cut,flip="both",s=250,spread=0,offset=-0.5,planar=true) rect([70,120]);
// Example(3D): Identify the two child evaluations.
//   left_half(pattern="jigsaw 20x8",repeat=3,flip="both",s=200)
//       color($idx==0 ? "orange" : "lightblue") cuboid([50,80,15]);
// Example(3D): Using `cut_angle` to rotate the cutting mask about the cut normal.
//   left_half(pattern="jigsaw 3x 60x12",cut_angle=45,s=300)
//       cuboid([60,140,40]);
module left_half(s=100, x=0, planar=false, pattern, pattern_size, pattern_width,
                   repeat, cut_width, cut_angle=0, flip=false, spread, offset=0,
                   show_frameref=false, convexity=10)
{
    req_children($children);
    half_of(v=LEFT,cp=[x,0,0],s=s,planar=planar,
            pattern=pattern, pattern_size=pattern_size, pattern_width=pattern_width,
            repeat=repeat, cut_width=cut_width, cut_angle=cut_angle,
            flip=flip, spread=spread, offset=offset,
            show_frameref=show_frameref,convexity=convexity) children();
}

function left_half(p, x=0, pattern, pattern_size, pattern_width,
                     repeat, cut_width, cut_angle=0, flip=false, spread, offset=0) =
    half_of(p,v=LEFT,cp=[x,0,0],
            pattern=pattern, pattern_size=pattern_size, pattern_width=pattern_width,
            repeat=repeat, cut_width=cut_width, cut_angle=cut_angle,
            flip=flip, spread=spread, offset=offset);


// Function&Module: right_half()
// Synopsis: Cuts an object at the YZ plane, keeping the right half, optionally with a jigsaw-style cut.
// SynTags: Geom, VNF, Path, Region
// Topics: Partitions, Masking
// See Also: half_of(), left_half(), front_half(), back_half(), bottom_half(), top_half(), half_mask(), partition_path()
// Usage: Flat 3D cut
//   right_half([s], [x], [flip=], [spread=], [offset=]) CHILDREN;
// Usage: Patterned 3D cut
//   right_half([s], [x], pattern=, [pattern_size=|pattern_width=], [repeat=], [cut_width=], [cut_angle=], [flip=], [spread=], [offset=], [show_frameref=], [convexity=]) CHILDREN;
// Usage: 2D module
//   right_half([s], [x], planar=true, [pattern=], [pattern_size=|pattern_width=], [repeat=], [cut_width=], [flip=], [spread=], [offset=]) CHILDREN;
// Usage: Function on a 2D polygon or region
//   result = right_half(p, [x], [pattern=], [pattern_size=|pattern_width=], [repeat=], [cut_width=], [flip=], [spread=], [offset=]);
// Usage: Function on a VNF (flat cuts only)
//   result = right_half(p, [x], [flip=], [spread=], [offset=]);
// Description:
//   Cuts the children at the YZ plane at X=`x`, or at a patterned interface lying in that plane,
//   keeping the right (+X) side by default.  This is a directional wrapper for {{half_of()}} with
//   normal RIGHT (+X) and cut-frame origin `[x,0,0]`.  The function accepts a 2D polygon/region or a
//   VNF and returns a region or VNF, respectively.  When you give a VNF you cannot give a pattern.
//   The module performs a 2D operation if you give `planar=true`; the function infers dimensionality from its input.
//   .
//   The mask is finite: `s` controls its along-cut coverage, retained-side depth and, in 3D,
//   extrusion height.  The mask is centered on the frame origin `[x,0,0]`: it spans Y and Z from -s/2 to s/2 (only Y if `planar=true`) and reaches `s` from the plane into the retained side, toward +X (toward -X when `flip=true`).  An object that lies far from Y=0 or Z=0 therefore needs a larger `s`.
//   Choose `s` large enough to cover the object; a value larger than twice the object extent is a useful
//   starting point.  A mask that is too small clips unintended parts, while a very large mask can confuse preview.
//   The function calculates its own mask coverage from the 2D input.
//   .
//   The `pattern` parameter is a pattern descriptor or list of descriptors as accepted by
//   {{partition_path()}}.  The basic descriptor strings are
//   `"sawtooth"`, `"square"`, `"triangle"`, `"halfsine"`,
//   `"semicircle"`, `"sinewave"`, `"comb"`, `"finger"`, `"dovetail"`,
//   `"hammerhead"`, and `"jigsaw"`.  These can be combined with each other or
//   with modifiers to change their size and shape or build up more complex
//   compound patterns.  A simple example is "jigsaw 6x" creates six copies of
//   the jigsaw pattern.  See {{partition_path()}} for details on the pattern specification.
//   .
//   Pattern width means the X separation between the first and last points, not its bounding box.
//   When patterns are joined they are connected end to end from their first and last points;
//   no space is added for overhangs.
//   A scalar `pattern_size` scales X and Y uniformly so the pattern is the specified width; `pattern_size=[w,h]` scales
//   X and Y independently to the specified size.  If you set `pattern_width` then the pattern is stretched in X to the specified
//   width, while Y values remain unchanged and do not scale.  The `pattern_size` and `pattern_width` options are
//   mutually exclusive and operate before repetition. Scaling in X is
//   about the middle point between the endpoints; scaling in Y is about Y=0.
//   You will generally want your entire cut to be a little bit shorter than your object so that
//   the cut geometry doesn't produce detached pieces near the boundary.  By setting one of these
//   parameters you can stretch or shrink a pattern so it fits on your object.
//   .
//   The other way to expand a pattern to fit your object is by repetition.  You can repeat
//   a single unit as described above by adding a multiplier to its string.  If you give
//   `cut_width` then your entire (possibly compound) pattern is repeated as many times
//   as possible in the specified width.  You can use `repeat="odd"`, `"even"`
//   to require that the number of copies be odd or even, which controls how the copies
//   will center on your shape: in the odd case one copy will be centered and in the even case
//   the two copies will meet at the center.  As usual, the size of the pattern is determined
//   by its endpoint span, not its bounding box.  If you set `repeat="any"` then either case
//   is permitted.  You can also give `repeat=n` to produce exactly `n` copies, in which
//   case you cannot give `cut_width`.
//   .
//   In order to produce the mating part give `flip=true`, which keeps the left (-X) side of the SAME interface.
//   Flipping does not rotate or reflect the pattern or move the cut: pattern Y=0 stays on the cut plane and
//   positive pattern Y still points RIGHT (+X).  Giving `flip="both"` produces both sides from
//   the same cut pattern. At zero offset and zero spread they reconstruct the original object
//   (within mask coverage).  The module does not preserve separately addressable solids in that case.
//   With `flip="both"` the `spread` parameter gives the space between the two halves: both are moved by half the spread
//   away from the cut surface, so the right piece moves toward +X and the left piece toward -X.  The spread defaults to `H+2*max(offset,0)+max(1,0.1*H)`, where `H`
//   is the actual Y span of the cut pattern.  The module sets `$idx` to 0 for the normal side and 1 for the opposite side;
//   the function returns `[normal_side,opposite_side]`.  Without `flip="both"`, `$idx` is not set and the function returns a single region or VNF.
//   .
//   The `offset` parameter provides fitting clearance: A negative value shrinks the retained side
//   away from the cut plane; a positive value expands the shape, making the fit tighter.
//   The offset is calculated using a rounded 2D offset() call.
//   .
//   The Y=0 point of the pattern lies on the cut plane at `x`.  Positive Y points along the cut normal.
//   The `cut_angle` parameter rotates the cutting surface around that cut normal. Here that rotation is about the line through `[x,0,0]` parallel to X; `cut_angle=90` makes the seam run along Z and extrudes it along Y.
//   If you need help understanding the orientation of your cut, enable `show_frameref` which displays a coordinate frame
//   where Y (green) is the normal pointing into the retained side and X (red) shows the cut path direction.
// Arguments:
//   p = Polygon, region, or VNF to cut. Function only.
//   s = Finite mask size. Module only. Default: 100
//   x = X coordinate of the cut plane. The pattern is centered at Y=0 on that plane. Default: 0
//   ---
//   planar = (module) Perform a 2D operation. Default: false
//   pattern = Descriptor or list of descriptors suitable for {{partition_path()}}. Default: flat cut
//   pattern_size = If a scalar then uniformly scale the pattern to specified width; if [width, height] then scale the pattern to that size.
//   pattern_width = stretch the pattern width to specified dimension while leaving Y unchanged.
//   repeat = If `cut_width` is given then "odd", "even" or "any" to require an odd number, even number or any number of repeats respectively.   If `cut_width` is not given, then the exact number of pattern copies to generate.  Default: "odd" with `cut_width`, 1 without
//   cut_width = Available width for automatic repetition. Default: undef
//   cut_angle = Rotation about the normal. 3D module only. Default: 0
//   flip = If false keep the normal side; if true keep the opposite side; if "both" keep both sides with optional spread.  Default: false
//   spread = Separation between the two halves when `flip="both"`.  Default: see above
//   offset = Expansion of each retained side; negative shrinks to provide fit clearance. Default: 0
//   show_frameref = Ghost the results and show the cut frame. 3D module only. Default: false
//   convexity = Preview convexity. Module only. Default: 10
// Side Effects:
//   `$idx` is set to 0 on the normal side and 1 on the opposite side when `flip="both"`.
// Examples:
//   right_half() sphere(r=20);
//   right_half(x=5,flip=true) sphere(r=20);
// Example(2D,NoScales): Patterned 2D cut with automatic odd repetition.
//   right_half(planar=true,pattern="jigsaw",pattern_size=[20,8],cut_width=95,s=200)
//       rect([60,100]);
// Example(2D,NoScales): Patterned 2D cut with unconstrained repetition allows one more to fit.  A margin on the sides remains. 
//   right_half(planar=true,pattern="jigsaw",pattern_size=[20,8],cut_width=95,s=200,repeat="any")
//       rect([60,100]);
// Example(2D,NoScales,Med): Specifying 7 repeats in this case creates a thin edge at the ends
//   right_half(planar=true,pattern="jigsaw",pattern_size=[15,8],s=200,repeat=7)
//       rect([60,100]);
// Example(2D,NoScales,Med): You can avoid the thin edge and fit 7 repeats in by specifying the repeats within the pattern and giving a pattern size smaller than your object to leave a margin
//   right_half(planar=true,pattern="jigsaw 7x",pattern_size=[90,8],s=200)
//       rect([60,100]);
// Example(2D,NoScales): A scalar `pattern_size` scales X and Y together, so the shapes get shorter as well as narrower from their original 25x25 size, preserving the aspect ratio.
//   right_half(planar=true,pattern="jigsaw",pattern_size=15,cut_width=95,s=200)
//       rect([60,100]);
// Example(2D,NoScales): `pattern_width` with the same width shrinks only X, so the shapes keep their original height of 25 and their aspect ratio changes.  
//   right_half(planar=true,pattern="jigsaw",pattern_width=15,cut_width=95,s=200)
//       rect([60,100]);
// Example(3D): Two mating parts, offset for clearance and automatically spread.
//   right_half(pattern="dovetail",pattern_size=[20,8],cut_width=95,
//       flip="both",offset=-0.15,s=200)
//       cuboid([60,100,20]);
// Example(3D): Here a compound pattern is replicated in full to fill the space and we use an explicit `spread` to set the gap between the two halves.  
//   right_half(pattern=["flat 5","triangle 20x15","flat 5"],pattern_size=[20,8],cut_width=95,
//           flip="both",spread=3,s=200)
//       cuboid([60,100,20]);
// Example(3D): Place the cut through the middle of an object that is not centered on the origin by giving `x`.
//   right_half(x=30,pattern="jigsaw",pattern_size=[20,8],
//       cut_width=95,flip="both",s=300)
//       translate([0,-50,0]) cube([60,100,20]);
// Example(2D,NoAxes): Use the function to get two regions in their original positions
//   parts=right_half(rect([40,80]),pattern="triangle 20x8",repeat=3,
//             flip="both",spread=0,offset=-0.5);
//   region(parts[0]);
//   region(parts[1]);
// Example(2D,NoAxes): Create a cut path that follows a curve.  The length parameter controls how much of the curve is used before the horizontal flat ends appear
//   cut=partition_path("jigsaw 17x7 5x", length=110,
//                      path=arc(n=100,cp=[0,100],r=100, angle=[-120, -60]));
//   right_half(pattern=cut,flip="both",s=250,spread=0,offset=-0.5,planar=true) rect([70,120]);
// Example(3D): Identify the two child evaluations.
//   right_half(pattern="jigsaw 20x8",repeat=3,flip="both",s=200)
//       color($idx==0 ? "lightgreen" : "gold") cuboid([50,80,15]);
// Example(3D): Using `cut_angle` to rotate the cutting mask about the cut normal.
//   right_half(pattern="jigsaw 3x 60x12",cut_angle=30,s=300)
//       cuboid([60,140,40]);
module right_half(s=100, x=0, planar=false, pattern, pattern_size, pattern_width,
                   repeat, cut_width, cut_angle=0, flip=false, spread, offset=0,
                   show_frameref=false, convexity=10)
{
    req_children($children);
    half_of(v=RIGHT,cp=[x,0,0],s=s,planar=planar,
            pattern=pattern, pattern_size=pattern_size, pattern_width=pattern_width,
            repeat=repeat, cut_width=cut_width, cut_angle=cut_angle,
            flip=flip, spread=spread, offset=offset,
            show_frameref=show_frameref,convexity=convexity) children();
}

function right_half(p, x=0, pattern, pattern_size, pattern_width,
                     repeat, cut_width, cut_angle=0, flip=false, spread, offset=0) =
    half_of(p,v=RIGHT,cp=[x,0,0],
            pattern=pattern, pattern_size=pattern_size, pattern_width=pattern_width,
            repeat=repeat, cut_width=cut_width, cut_angle=cut_angle,
            flip=flip, spread=spread, offset=offset);


// Function&Module: front_half()
// Synopsis: Cuts an object at the XZ plane, keeping the front half, optionally with a jigsaw-style cut.
// SynTags: Geom, VNF, Path, Region
// Topics: Partitions, Masking
// See Also: half_of(), left_half(), right_half(), back_half(), bottom_half(), top_half(), half_mask(), partition_path()
// Usage: Flat 3D cut
//   front_half([s], [y], [flip=], [spread=], [offset=]) CHILDREN;
// Usage: Patterned 3D cut
//   front_half([s], [y], pattern=, [pattern_size=|pattern_width=], [repeat=], [cut_width=], [cut_angle=], [flip=], [spread=], [offset=], [show_frameref=], [convexity=]) CHILDREN;
// Usage: 2D module
//   front_half([s], [y], planar=true, [pattern=], [pattern_size=|pattern_width=], [repeat=], [cut_width=], [flip=], [spread=], [offset=]) CHILDREN;
// Usage: Function on a 2D polygon or region
//   result = front_half(p, [y], [pattern=], [pattern_size=|pattern_width=], [repeat=], [cut_width=], [flip=], [spread=], [offset=]);
// Usage: Function on a VNF (flat cuts only)
//   result = front_half(p, [y], [flip=], [spread=], [offset=]);
// Description:
//   Cuts the children at the XZ plane at Y=`y`, or at a patterned interface lying in that plane,
//   keeping the front (-Y) side by default.  This is a directional wrapper for {{half_of()}} with
//   normal FWD (-Y) and cut-frame origin `[0,y,0]`.  The function accepts a 2D polygon/region or a
//   VNF and returns a region or VNF, respectively.  When you give a VNF you cannot give a pattern.
//   The module performs a 2D operation if you give `planar=true`; the function infers dimensionality from its input.
//   .
//   The mask is finite: `s` controls its along-cut coverage, retained-side depth and, in 3D,
//   extrusion height.  The mask is centered on the frame origin `[0,y,0]`: it spans X and Z from -s/2 to s/2 (only X if `planar=true`) and reaches `s` from the plane into the retained side, toward -Y (toward +Y when `flip=true`).  An object that lies far from X=0 or Z=0 therefore needs a larger `s`.
//   Choose `s` large enough to cover the object; a value larger than twice the object extent is a useful
//   starting point.  A mask that is too small clips unintended parts, while a very large mask can confuse preview.
//   The function calculates its own mask coverage from the 2D input.
//   .
//   The `pattern` parameter is a pattern descriptor or list of descriptors as accepted by
//   {{partition_path()}}.  The basic descriptor strings are
//   `"sawtooth"`, `"square"`, `"triangle"`, `"halfsine"`,
//   `"semicircle"`, `"sinewave"`, `"comb"`, `"finger"`, `"dovetail"`,
//   `"hammerhead"`, and `"jigsaw"`.  These can be combined with each other or
//   with modifiers to change their size and shape or build up more complex
//   compound patterns.  A simple example is "jigsaw 6x" creates six copies of
//   the jigsaw pattern.  See {{partition_path()}} for details on the pattern specification.
//   .
//   Pattern width means the X separation between the first and last points, not its bounding box.
//   When patterns are joined they are connected end to end from their first and last points;
//   no space is added for overhangs.
//   A scalar `pattern_size` scales X and Y uniformly so the pattern is the specified width; `pattern_size=[w,h]` scales
//   X and Y independently to the specified size.  If you set `pattern_width` then the pattern is stretched in X to the specified
//   width, while Y values remain unchanged and do not scale.  The `pattern_size` and `pattern_width` options are
//   mutually exclusive and operate before repetition. Scaling in X is
//   about the middle point between the endpoints; scaling in Y is about Y=0.
//   You will generally want your entire cut to be a little bit shorter than your object so that
//   the cut geometry doesn't produce detached pieces near the boundary.  By setting one of these
//   parameters you can stretch or shrink a pattern so it fits on your object.
//   .
//   The other way to expand a pattern to fit your object is by repetition.  You can repeat
//   a single unit as described above by adding a multiplier to its string.  If you give
//   `cut_width` then your entire (possibly compound) pattern is repeated as many times
//   as possible in the specified width.  You can use `repeat="odd"`, `"even"`
//   to require that the number of copies be odd or even, which controls how the copies
//   will center on your shape: in the odd case one copy will be centered and in the even case
//   the two copies will meet at the center.  As usual, the size of the pattern is determined
//   by its endpoint span, not its bounding box.  If you set `repeat="any"` then either case
//   is permitted.  You can also give `repeat=n` to produce exactly `n` copies, in which
//   case you cannot give `cut_width`.
//   .
//   In order to produce the mating part give `flip=true`, which keeps the back (+Y) side of the SAME interface.
//   Flipping does not rotate or reflect the pattern or move the cut: pattern Y=0 stays on the cut plane and
//   positive pattern Y still points FWD (-Y).  Giving `flip="both"` produces both sides from
//   the same cut pattern. At zero offset and zero spread they reconstruct the original object
//   (within mask coverage).  The module does not preserve separately addressable solids in that case.
//   With `flip="both"` the `spread` parameter gives the space between the two halves: both are moved by half the spread
//   away from the cut surface, so the front piece moves toward -Y and the back piece toward +Y.  The spread defaults to `H+2*max(offset,0)+max(1,0.1*H)`, where `H`
//   is the actual Y span of the cut pattern.  The module sets `$idx` to 0 for the normal side and 1 for the opposite side;
//   the function returns `[normal_side,opposite_side]`.  Without `flip="both"`, `$idx` is not set and the function returns a single region or VNF.
//   .
//   The `offset` parameter provides fitting clearance: A negative value shrinks the retained side
//   away from the cut plane; a positive value expands the shape, making the fit tighter.
//   The offset is calculated using a rounded 2D offset() call.
//   .
//   The Y=0 point of the pattern lies on the cut plane at `y`.  Positive Y points along the cut normal.
//   The `cut_angle` parameter rotates the cutting surface around that cut normal. Here that rotation is about the line through `[0,y,0]` parallel to Y; `cut_angle=90` makes the seam run along Z and extrudes it along X.
//   If you need help understanding the orientation of your cut, enable `show_frameref` which displays a coordinate frame
//   where Y (green) is the normal pointing into the retained side and X (red) shows the cut path direction.
// Arguments:
//   p = Polygon, region, or VNF to cut. Function only.
//   s = Finite mask size. Module only. Default: 100
//   y = Y coordinate of the cut plane. The pattern is centered at X=0 on that plane. Default: 0
//   ---
//   planar = (module) Perform a 2D operation. Default: false
//   pattern = Descriptor or list of descriptors suitable for {{partition_path()}}. Default: flat cut
//   pattern_size = If a scalar then uniformly scale the pattern to specified width; if [width, height] then scale the pattern to that size.
//   pattern_width = stretch the pattern width to specified dimension while leaving Y unchanged.
//   repeat = If `cut_width` is given then "odd", "even" or "any" to require an odd number, even number or any number of repeats respectively.   If `cut_width` is not given, then the exact number of pattern copies to generate.  Default: "odd" with `cut_width`, 1 without
//   cut_width = Available width for automatic repetition. Default: undef
//   cut_angle = Rotation about the normal. 3D module only. Default: 0
//   flip = If false keep the normal side; if true keep the opposite side; if "both" keep both sides with optional spread.  Default: false
//   spread = Separation between the two halves when `flip="both"`.  Default: see above
//   offset = Expansion of each retained side; negative shrinks to provide fit clearance. Default: 0
//   show_frameref = Ghost the results and show the cut frame. 3D module only. Default: false
//   convexity = Preview convexity. Module only. Default: 10
// Side Effects:
//   `$idx` is set to 0 on the normal side and 1 on the opposite side when `flip="both"`.
// Examples:
//   front_half() sphere(r=20);
//   front_half(y=5,flip=true) sphere(r=20);
// Example(2D,NoScales): Patterned 2D cut with automatic odd repetition.
//   front_half(planar=true,pattern="jigsaw",pattern_size=[20,8],cut_width=95,s=200)
//       rect([100,60]);
// Example(2D,NoScales): Patterned 2D cut with unconstrained repetition allows one more to fit.  A margin on the sides remains. 
//   front_half(planar=true,pattern="jigsaw",pattern_size=[20,8],cut_width=95,s=200,repeat="any")
//       rect([100,60]);
// Example(2D,NoScales,Med): Specifying 7 repeats in this case creates a thin edge at the ends
//   front_half(planar=true,pattern="jigsaw",pattern_size=[15,8],s=200,repeat=7)
//       rect([100,60]);
// Example(2D,NoScales,Med): You can avoid the thin edge and fit 7 repeats in by specifying the repeats within the pattern and giving a pattern size smaller than your object to leave a margin
//   front_half(planar=true,pattern="jigsaw 7x",pattern_size=[90,8],s=200)
//       rect([100,60]);
// Example(2D,NoScales): A scalar `pattern_size` scales X and Y together, so the shapes get shorter as well as narrower from their original 25x25 size, preserving the aspect ratio.
//   front_half(planar=true,pattern="jigsaw",pattern_size=15,cut_width=95,s=200)
//       rect([100,60]);
// Example(2D,NoScales): `pattern_width` with the same width shrinks only X, so the shapes keep their original height of 25 and their aspect ratio changes.  
//   front_half(planar=true,pattern="jigsaw",pattern_width=15,cut_width=95,s=200)
//       rect([100,60]);
// Example(3D): Two mating parts, offset for clearance and automatically spread.
//   front_half(pattern="jigsaw",pattern_size=[20,8],cut_width=95,
//       flip="both",offset=-0.15,s=200)
//       cuboid([100,60,20]);
// Example(3D): Here a compound pattern is replicated in full to fill the space and we use an explicit `spread` to set the gap between the two halves.  
//   front_half(pattern=["flat 5","square 20x20 pinch:60","flat 5"],pattern_size=[20,8],cut_width=95,
//           flip="both",spread=4,s=200)
//       cuboid([100,60,20]);
// Example(3D): Place the cut through the middle of an object that is not centered on the origin by giving `y`.
//   front_half(y=30,pattern="dovetail",pattern_size=[20,8],
//       cut_width=95,flip="both",s=300)
//       translate([-50,0,0]) cube([100,60,20]);
// Example(2D): Use the function to get two regions in their original positions
//   parts=front_half(rect([80,40]),pattern="triangle 20x8",repeat=3,
//             flip="both",spread=0,offset=-0.5);
//   region(parts[0]);
//   region(parts[1]);
// Example(2D,NoAxes): Create a cut path that follows a curve.  The length parameter controls how much of the curve is used before the horizontal flat ends appear
//   cut=partition_path("jigsaw 17x7 5x", length=110,
//                      path=arc(n=100,cp=[0,100],r=100, angle=[-120, -60]));
//   front_half(pattern=cut,flip="both",s=250,spread=0,offset=-0.5,planar=true) rect([120,70]);
// Example(3D): Identify the two child evaluations.
//   front_half(pattern="jigsaw 20x8",repeat=3,flip="both",s=200)
//       color($idx==0 ? "salmon" : "lightblue") cuboid([80,50,15]);
// Example(3D): Using `cut_angle` to rotate the cutting mask about the cut normal.
//   front_half(pattern="jigsaw 3x 60x12",cut_angle=45,s=300)
//       cuboid([140,60,40]);
module front_half(s=100, y=0, planar=false, pattern, pattern_size, pattern_width,
                   repeat, cut_width, cut_angle=0, flip=false, spread, offset=0,
                   show_frameref=false, convexity=10)
{
    req_children($children);
    half_of(v=FWD,cp=[0,y,0],s=s,planar=planar,
            pattern=pattern, pattern_size=pattern_size, pattern_width=pattern_width,
            repeat=repeat, cut_width=cut_width, cut_angle=cut_angle,
            flip=flip, spread=spread, offset=offset,
            show_frameref=show_frameref,convexity=convexity) children();
}

function front_half(p, y=0, pattern, pattern_size, pattern_width,
                     repeat, cut_width, cut_angle=0, flip=false, spread, offset=0) =
    half_of(p,v=FWD,cp=[0,y,0],
            pattern=pattern, pattern_size=pattern_size, pattern_width=pattern_width,
            repeat=repeat, cut_width=cut_width, cut_angle=cut_angle,
            flip=flip, spread=spread, offset=offset);


// Function&Module: back_half()
// Synopsis: Cuts an object at the XZ plane, keeping the back half, optionally with a jigsaw-style cut.
// SynTags: Geom, VNF, Path, Region
// Topics: Partitions, Masking
// See Also: half_of(), left_half(), right_half(), front_half(), bottom_half(), top_half(), half_mask(), partition_path()
// Usage: Flat 3D cut
//   back_half([s], [y], [flip=], [spread=], [offset=]) CHILDREN;
// Usage: Patterned 3D cut
//   back_half([s], [y], pattern=, [pattern_size=|pattern_width=], [repeat=], [cut_width=], [cut_angle=], [flip=], [spread=], [offset=], [show_frameref=], [convexity=]) CHILDREN;
// Usage: 2D module
//   back_half([s], [y], planar=true, [pattern=], [pattern_size=|pattern_width=], [repeat=], [cut_width=], [flip=], [spread=], [offset=]) CHILDREN;
// Usage: Function on a 2D polygon or region
//   result = back_half(p, [y], [pattern=], [pattern_size=|pattern_width=], [repeat=], [cut_width=], [flip=], [spread=], [offset=]);
// Usage: Function on a VNF (flat cuts only)
//   result = back_half(p, [y], [flip=], [spread=], [offset=]);
// Description:
//   Cuts the children at the XZ plane at Y=`y`, or at a patterned interface lying in that plane,
//   keeping the back (+Y) side by default.  This is a directional wrapper for {{half_of()}} with
//   normal BACK (+Y) and cut-frame origin `[0,y,0]`.  The function accepts a 2D polygon/region or a
//   VNF and returns a region or VNF, respectively.  When you give a VNF you cannot give a pattern.
//   The module performs a 2D operation if you give `planar=true`; the function infers dimensionality from its input.
//   .
//   The mask is finite: `s` controls its along-cut coverage, retained-side depth and, in 3D,
//   extrusion height.  The mask is centered on the frame origin `[0,y,0]`: it spans X and Z from -s/2 to s/2 (only X if `planar=true`) and reaches `s` from the plane into the retained side, toward +Y (toward -Y when `flip=true`).  An object that lies far from X=0 or Z=0 therefore needs a larger `s`.
//   Choose `s` large enough to cover the object; a value larger than twice the object extent is a useful
//   starting point.  A mask that is too small clips unintended parts, while a very large mask can confuse preview.
//   The function calculates its own mask coverage from the 2D input.
//   .
//   The `pattern` parameter is a pattern descriptor or list of descriptors as accepted by
//   {{partition_path()}}.  The basic descriptor strings are
//   `"sawtooth"`, `"square"`, `"triangle"`, `"halfsine"`,
//   `"semicircle"`, `"sinewave"`, `"comb"`, `"finger"`, `"dovetail"`,
//   `"hammerhead"`, and `"jigsaw"`.  These can be combined with each other or
//   with modifiers to change their size and shape or build up more complex
//   compound patterns.  A simple example is "jigsaw 6x" creates six copies of
//   the jigsaw pattern.  See {{partition_path()}} for details on the pattern specification.
//   .
//   Pattern width means the X separation between the first and last points, not its bounding box.
//   When patterns are joined they are connected end to end from their first and last points;
//   no space is added for overhangs.
//   A scalar `pattern_size` scales X and Y uniformly so the pattern is the specified width; `pattern_size=[w,h]` scales
//   X and Y independently to the specified size.  If you set `pattern_width` then the pattern is stretched in X to the specified
//   width, while Y values remain unchanged and do not scale.  The `pattern_size` and `pattern_width` options are
//   mutually exclusive and operate before repetition. Scaling in X is
//   about the middle point between the endpoints; scaling in Y is about Y=0.
//   You will generally want your entire cut to be a little bit shorter than your object so that
//   the cut geometry doesn't produce detached pieces near the boundary.  By setting one of these
//   parameters you can stretch or shrink a pattern so it fits on your object.
//   .
//   The other way to expand a pattern to fit your object is by repetition.  You can repeat
//   a single unit as described above by adding a multiplier to its string.  If you give
//   `cut_width` then your entire (possibly compound) pattern is repeated as many times
//   as possible in the specified width.  You can use `repeat="odd"`, `"even"`
//   to require that the number of copies be odd or even, which controls how the copies
//   will center on your shape: in the odd case one copy will be centered and in the even case
//   the two copies will meet at the center.  As usual, the size of the pattern is determined
//   by its endpoint span, not its bounding box.  If you set `repeat="any"` then either case
//   is permitted.  You can also give `repeat=n` to produce exactly `n` copies, in which
//   case you cannot give `cut_width`.
//   .
//   In order to produce the mating part give `flip=true`, which keeps the front (-Y) side of the SAME interface.
//   Flipping does not rotate or reflect the pattern or move the cut: pattern Y=0 stays on the cut plane and
//   positive pattern Y still points BACK (+Y).  Giving `flip="both"` produces both sides from
//   the same cut pattern. At zero offset and zero spread they reconstruct the original object
//   (within mask coverage).  The module does not preserve separately addressable solids in that case.
//   With `flip="both"` the `spread` parameter gives the space between the two halves: both are moved by half the spread
//   away from the cut surface, so the back piece moves toward +Y and the front piece toward -Y.  The spread defaults to `H+2*max(offset,0)+max(1,0.1*H)`, where `H`
//   is the actual Y span of the cut pattern.  The module sets `$idx` to 0 for the normal side and 1 for the opposite side;
//   the function returns `[normal_side,opposite_side]`.  Without `flip="both"`, `$idx` is not set and the function returns a single region or VNF.
//   .
//   The `offset` parameter provides fitting clearance: A negative value shrinks the retained side
//   away from the cut plane; a positive value expands the shape, making the fit tighter.
//   The offset is calculated using a rounded 2D offset() call.
//   .
//   The Y=0 point of the pattern lies on the cut plane at `y`.  Positive Y points along the cut normal.
//   The `cut_angle` parameter rotates the cutting surface around that cut normal. Here that rotation is about the line through `[0,y,0]` parallel to Y; `cut_angle=90` makes the seam run along Z and extrudes it along X.
//   If you need help understanding the orientation of your cut, enable `show_frameref` which displays a coordinate frame
//   where Y (green) is the normal pointing into the retained side and X (red) shows the cut path direction.
// Arguments:
//   p = Polygon, region, or VNF to cut. Function only.
//   s = Finite mask size. Module only. Default: 100
//   y = Y coordinate of the cut plane. The pattern is centered at X=0 on that plane. Default: 0
//   ---
//   planar = (module) Perform a 2D operation. Default: false
//   pattern = Descriptor or list of descriptors suitable for {{partition_path()}}. Default: flat cut
//   pattern_size = If a scalar then uniformly scale the pattern to specified width; if [width, height] then scale the pattern to that size.
//   pattern_width = stretch the pattern width to specified dimension while leaving Y unchanged.
//   repeat = If `cut_width` is given then "odd", "even" or "any" to require an odd number, even number or any number of repeats respectively.   If `cut_width` is not given, then the exact number of pattern copies to generate.  Default: "odd" with `cut_width`, 1 without
//   cut_width = Available width for automatic repetition. Default: undef
//   cut_angle = Rotation about the normal. 3D module only. Default: 0
//   flip = If false keep the normal side; if true keep the opposite side; if "both" keep both sides with optional spread.  Default: false
//   spread = Separation between the two halves when `flip="both"`.  Default: see above
//   offset = Expansion of each retained side; negative shrinks to provide fit clearance. Default: 0
//   show_frameref = Ghost the results and show the cut frame. 3D module only. Default: false
//   convexity = Preview convexity. Module only. Default: 10
// Side Effects:
//   `$idx` is set to 0 on the normal side and 1 on the opposite side when `flip="both"`.
// Examples:
//   back_half() sphere(r=20);
//   back_half(y=5,flip=true) sphere(r=20);
// Example(2D,NoScales): Patterned 2D cut with automatic odd repetition.
//   back_half(planar=true,pattern="jigsaw",pattern_size=[20,8],cut_width=95,s=200)
//       rect([100,60]);
// Example(2D,NoScales): Patterned 2D cut with unconstrained repetition allows one more to fit.  A margin on the sides remains. 
//   back_half(planar=true,pattern="jigsaw",pattern_size=[20,8],cut_width=95,s=200,repeat="any")
//       rect([100,60]);
// Example(2D,NoScales,Med): Specifying 7 repeats in this case creates a thin edge at the ends
//   back_half(planar=true,pattern="jigsaw",pattern_size=[15,8],s=200,repeat=7)
//       rect([100,60]);
// Example(2D,NoScales,Med): You can avoid the thin edge and fit 7 repeats in by specifying the repeats within the pattern and giving a pattern size smaller than your object to leave a margin
//   back_half(planar=true,pattern="jigsaw 7x",pattern_size=[90,8],s=200)
//       rect([100,60]);
// Example(2D,NoScales): A scalar `pattern_size` scales X and Y together, so the shapes get shorter as well as narrower from their original 25x25 size, preserving the aspect ratio.
//   back_half(planar=true,pattern="jigsaw",pattern_size=15,cut_width=95,s=200)
//       rect([100,60]);
// Example(2D,NoScales): `pattern_width` with the same width shrinks only X, so the shapes keep their original height of 25 and their aspect ratio changes.  
//   back_half(planar=true,pattern="jigsaw",pattern_width=15,cut_width=95,s=200)
//       rect([100,60]);
// Example(3D): Two mating parts, offset for clearance and automatically spread.
//   back_half(pattern="triangle",pattern_size=[20,8],cut_width=95,
//       flip="both",offset=-0.15,s=200)
//       cuboid([100,60,20]);
// Example(3D): Here a compound pattern is replicated in full to fill the space and we use an explicit `spread` to set the gap between the two halves.  
//   back_half(pattern=["flat 5","semicircle 20x10","flat 5"],pattern_size=[20,8],cut_width=95,
//           flip="both",spread=2,s=200)
//       cuboid([100,60,20]);
// Example(3D): Place the cut through the middle of an object that is not centered on the origin by giving `y`.
//   back_half(y=30,pattern="dovetail",pattern_size=[20,8],
//       cut_width=95,flip="both",s=300)
//       translate([-50,0,0]) cube([100,60,20]);
// Example(2D,NoAxes): Use the function to get two regions in their original positions
//   parts=back_half(rect([80,40]),pattern="triangle 20x8",repeat=3,
//             flip="both",spread=0,offset=-0.5);
//   region(parts[0]);
//   region(parts[1]);
// Example(2D,NoAxes): Create a cut path that follows a curve.  The length parameter controls how much of the curve is used before the horizontal flat ends appear
//   cut=partition_path("jigsaw 17x7 5x", length=110,
//                      path=arc(n=100,cp=[0,100],r=100, angle=[-120, -60]));
//   back_half(pattern=cut,flip="both",s=250,spread=0,offset=-0.5,planar=true) rect([120,70]);
// Example(3D): Identify the two child evaluations.
//   back_half(pattern="jigsaw 20x8",repeat=3,flip="both",s=200)
//       color($idx==0 ? "orange" : "lightblue") cuboid([80,50,15]);
// Example(3D): Using `cut_angle` to rotate the cutting mask about the cut normal.
//   back_half(pattern="jigsaw 3x 60x12",cut_angle=60,s=300)
//       cuboid([140,60,40]);
module back_half(s=100, y=0, planar=false, pattern, pattern_size, pattern_width,
                   repeat, cut_width, cut_angle=0, flip=false, spread, offset=0,
                   show_frameref=false, convexity=10)
{
    req_children($children);
    half_of(v=BACK,cp=[0,y,0],s=s,planar=planar,
            pattern=pattern, pattern_size=pattern_size, pattern_width=pattern_width,
            repeat=repeat, cut_width=cut_width, cut_angle=cut_angle,
            flip=flip, spread=spread, offset=offset,
            show_frameref=show_frameref,convexity=convexity) children();
}

function back_half(p, y=0, pattern, pattern_size, pattern_width,
                     repeat, cut_width, cut_angle=0, flip=false, spread, offset=0) =
    half_of(p,v=BACK,cp=[0,y,0],
            pattern=pattern, pattern_size=pattern_size, pattern_width=pattern_width,
            repeat=repeat, cut_width=cut_width, cut_angle=cut_angle,
            flip=flip, spread=spread, offset=offset);


// Function&Module: bottom_half()
// Synopsis: Cuts an object at the XY plane, keeping the bottom half, optionally with a jigsaw-style cut.
// SynTags: Geom, VNF, Path, Region
// Topics: Partitions, Masking
// See Also: half_of(), left_half(), right_half(), front_half(), back_half(), top_half(), half_mask(), partition_path()
// Usage: Flat 3D cut
//   bottom_half([s], [z], [flip=], [spread=], [offset=]) CHILDREN;
// Usage: Patterned 3D cut
//   bottom_half([s], [z], pattern=, [pattern_size=|pattern_width=], [repeat=], [cut_width=], [cut_angle=], [flip=], [spread=], [offset=], [show_frameref=], [convexity=]) CHILDREN;
// Usage: 2D module
//   bottom_half([s], [z], planar=true, [pattern=], [pattern_size=|pattern_width=], [repeat=], [cut_width=], [flip=], [spread=], [offset=]) CHILDREN;
// Usage: Function on a 2D polygon or region
//   result = bottom_half(p, [z], planar=true, [pattern=], [pattern_size=|pattern_width=], [repeat=], [cut_width=], [flip=], [spread=], [offset=]);
// Usage: Function on a VNF (flat cuts only)
//   result = bottom_half(p, [z], [flip=], [spread=], [offset=]);
// Description:
//   Cuts the children at the XY plane at Z=`z`, or at a patterned interface lying in that plane,
//   keeping the bottom (-Z; the front, -Y, side if `planar=true`) side by default.  This is a directional wrapper for {{half_of()}} with
//   normal DOWN (-Z) and cut-frame origin `[0,0,z]`.  The function accepts a 2D polygon/region or a
//   VNF and returns a region or VNF, respectively.  When you give a VNF you cannot give a pattern.
//   The module performs a 2D operation if you give `planar=true`.  The function on 2D data also requires `planar=true`;
//   in 2D, `z` is a Y coordinate, as described below.
//   .
//   The mask is finite: `s` controls its along-cut coverage, retained-side depth and, in 3D,
//   extrusion height.  The mask is centered on the frame origin `[0,0,z]`: in 3D it spans X and Y from -s/2 to s/2 and reaches `s` from the plane into the retained side, toward -Z (toward +Z when `flip=true`).  With `planar=true` it spans only X and reaches `s` from the line `Y=z`.  An object that lies far from X=0 or Y=0 therefore needs a larger `s`.
//   Choose `s` large enough to cover the object; a value larger than twice the object extent is a useful
//   starting point.  A mask that is too small clips unintended parts, while a very large mask can confuse preview.
//   The function calculates its own mask coverage from the 2D input.
//   .
//   The `pattern` parameter is a pattern descriptor or list of descriptors as accepted by
//   {{partition_path()}}.  The basic descriptor strings are
//   `"sawtooth"`, `"square"`, `"triangle"`, `"halfsine"`,
//   `"semicircle"`, `"sinewave"`, `"comb"`, `"finger"`, `"dovetail"`,
//   `"hammerhead"`, and `"jigsaw"`.  These can be combined with each other or
//   with modifiers to change their size and shape or build up more complex
//   compound patterns.  A simple example is "jigsaw 6x" creates six copies of
//   the jigsaw pattern.  See {{partition_path()}} for details on the pattern specification.
//   .
//   Pattern width means the X separation between the first and last points, not its bounding box.
//   When patterns are joined they are connected end to end from their first and last points;
//   no space is added for overhangs.
//   A scalar `pattern_size` scales X and Y uniformly so the pattern is the specified width; `pattern_size=[w,h]` scales
//   X and Y independently to the specified size.  If you set `pattern_width` then the pattern is stretched in X to the specified
//   width, while Y values remain unchanged and do not scale.  The `pattern_size` and `pattern_width` options are
//   mutually exclusive and operate before repetition. Scaling in X is
//   about the middle point between the endpoints; scaling in Y is about Y=0.
//   You will generally want your entire cut to be a little bit shorter than your object so that
//   the cut geometry doesn't produce detached pieces near the boundary.  By setting one of these
//   parameters you can stretch or shrink a pattern so it fits on your object.
//   .
//   The other way to expand a pattern to fit your object is by repetition.  You can repeat
//   a single unit as described above by adding a multiplier to its string.  If you give
//   `cut_width` then your entire (possibly compound) pattern is repeated as many times
//   as possible in the specified width.  You can use `repeat="odd"`, `"even"`
//   to require that the number of copies be odd or even, which controls how the copies
//   will center on your shape: in the odd case one copy will be centered and in the even case
//   the two copies will meet at the center.  As usual, the size of the pattern is determined
//   by its endpoint span, not its bounding box.  If you set `repeat="any"` then either case
//   is permitted.  You can also give `repeat=n` to produce exactly `n` copies, in which
//   case you cannot give `cut_width`.
//   .
//   In order to produce the mating part give `flip=true`, which keeps the top (+Z) side of the SAME interface.
//   Flipping does not rotate or reflect the pattern or move the cut: pattern Y=0 stays on the cut plane and
//   positive pattern Y still points DOWN (-Z).  Giving `flip="both"` produces both sides from
//   the same cut pattern. At zero offset and zero spread they reconstruct the original object
//   (within mask coverage).  The module does not preserve separately addressable solids in that case.
//   With `flip="both"` the `spread` parameter gives the space between the two halves: both are moved by half the spread
//   away from the cut surface, so the bottom piece moves down (-Z) and the top piece up (+Z).  With `planar=true`, the front piece moves toward -Y and the back piece toward +Y.  The spread defaults to `H+2*max(offset,0)+max(1,0.1*H)`, where `H`
//   is the actual Y span of the cut pattern.  The module sets `$idx` to 0 for the normal side and 1 for the opposite side;
//   the function returns `[normal_side,opposite_side]`.  Without `flip="both"`, `$idx` is not set and the function returns a single region or VNF.
//   .
//   The `offset` parameter provides fitting clearance: A negative value shrinks the retained side
//   away from the cut plane; a positive value expands the shape, making the fit tighter.
//   The offset is calculated using a rounded 2D offset() call.
//   .
//   The Y=0 point of the pattern lies on the cut plane at `z`.  Positive Y points along the cut normal.
//   The `cut_angle` parameter rotates the cutting surface around that cut normal. Here that rotation is about the vertical line through `[0,0,z]`; `cut_angle=90` makes the seam run along Y and extrudes it along X.
//   If you need help understanding the orientation of your cut, enable `show_frameref` which displays a coordinate frame
//   where Y (green) is the normal pointing into the retained side and X (red) shows the cut path direction.
// Arguments:
//   p = Polygon, region, or VNF to cut. Function only.
//   s = Finite mask size. Module only. Default: 100
//   z = Z coordinate of the cut plane, centered at X=0; with `planar=true` it is the Y coordinate of the cut line. Default: 0
//   ---
//   planar = Perform a 2D operation, treating `z` as a Y coordinate as {{front_half()}} does.  Required for the function on 2D data. Default: false
//   pattern = Descriptor or list of descriptors suitable for {{partition_path()}}. Default: flat cut
//   pattern_size = If a scalar then uniformly scale the pattern to specified width; if [width, height] then scale the pattern to that size.
//   pattern_width = stretch the pattern width to specified dimension while leaving Y unchanged.
//   repeat = If `cut_width` is given then "odd", "even" or "any" to require an odd number, even number or any number of repeats respectively.   If `cut_width` is not given, then the exact number of pattern copies to generate.  Default: "odd" with `cut_width`, 1 without
//   cut_width = Available width for automatic repetition. Default: undef
//   cut_angle = Rotation about the normal. 3D module only. Default: 0
//   flip = If false keep the normal side; if true keep the opposite side; if "both" keep both sides with optional spread.  Default: false
//   spread = Separation between the two halves when `flip="both"`.  Default: see above
//   offset = Expansion of each retained side; negative shrinks to provide fit clearance. Default: 0
//   show_frameref = Ghost the results and show the cut frame. 3D module only. Default: false
//   convexity = Preview convexity. Module only. Default: 10
// Side Effects:
//   `$idx` is set to 0 on the normal side and 1 on the opposite side when `flip="both"`.
// Examples:
//   bottom_half() sphere(r=20);
//   bottom_half(z=5,flip=true) sphere(r=20);
// Example(2D,NoScales): Patterned 2D cut with automatic odd repetition.
//   bottom_half(planar=true,pattern="jigsaw",pattern_size=[20,8],cut_width=95,s=200)
//       rect([100,60]);
// Example(2D,NoScales): Patterned 2D cut with unconstrained repetition allows one more to fit.  A margin on the sides remains. 
//   bottom_half(planar=true,pattern="jigsaw",pattern_size=[20,8],cut_width=95,s=200,repeat="any")
//       rect([100,60]);
// Example(2D,NoScales,Med): Specifying 7 repeats in this case creates a thin edge at the ends
//   bottom_half(planar=true,pattern="jigsaw",pattern_size=[15,8],s=200,repeat=7)
//       rect([100,60]);
// Example(2D,NoScales,Med): You can avoid the thin edge and fit 7 repeats in by specifying the repeats within the pattern and giving a pattern size smaller than your object to leave a margin
//   bottom_half(planar=true,pattern="jigsaw 7x",pattern_size=[90,8],s=200)
//       rect([100,60]);
// Example(2D,NoScales): A scalar `pattern_size` scales X and Y together, so the shapes get shorter as well as narrower from their original 25x25 size, preserving the aspect ratio.
//   bottom_half(planar=true,pattern="jigsaw",pattern_size=15,cut_width=95,s=200)
//       rect([100,60]);
// Example(2D,NoScales): `pattern_width` with the same width shrinks only X, so the shapes keep their original height of 25 and their aspect ratio changes.  
//   bottom_half(planar=true,pattern="jigsaw",pattern_width=15,cut_width=95,s=200)
//       rect([100,60]);
// Example(3D): Two mating parts, offset for clearance and automatically spread.
//   bottom_half(pattern="dovetail",pattern_size=[20,8],cut_width=95,
//       flip="both",offset=-0.15,s=200)
//       cuboid([100,60,40]);
// Example(3D): Here a compound pattern is replicated in full to fill the space and we use an explicit `spread` to set the gap between the two halves.  
//   bottom_half(pattern=["flat 5","square 20x20 pinch:70","flat 5"],pattern_size=[20,8],cut_width=95,
//           flip="both",spread=3,s=200)
//       cuboid([100,60,40]);
// Example(3D): Place the cut through the middle of an object that is not centered on the origin by giving `z`.
//   bottom_half(z=20,pattern="jigsaw",pattern_size=[20,8],
//       cut_width=95,flip="both",s=300)
//       translate([-50,-30,0]) cube([100,60,40]);
// Example(2D,NoAxes): Use the function to get two regions in their original positions
//   parts=bottom_half(rect([80,40]),planar=true,pattern="triangle 20x8",repeat=3,
//             flip="both",spread=0,offset=-0.5);
//   region(parts[0]);
//   region(parts[1]);
// Example(2D,NoAxes): Create a cut path that follows a curve.  The length parameter controls how much of the curve is used before the horizontal flat ends appear
//   cut=partition_path("jigsaw 17x7 5x", length=110,
//                      path=arc(n=100,cp=[0,100],r=100, angle=[-120, -60]));
//   bottom_half(pattern=cut,flip="both",s=250,spread=0,offset=-0.5,planar=true) rect([120,70]);
// Example(3D): Identify the two child evaluations.
//   bottom_half(pattern="jigsaw 20x8",repeat=3,flip="both",s=200)
//       color($idx==0 ? "lightgreen" : "gold") cuboid([80,50,30]);
// Example(3D): Using `cut_angle` to rotate the cutting mask about the cut normal.
//   bottom_half(pattern="jigsaw 3x 60x12",cut_angle=30,s=300)
//       cuboid([140,60,40]);
module bottom_half(s=100, z=0, planar=false, pattern, pattern_size, pattern_width,
                   repeat, cut_width, cut_angle=0, flip=false, spread, offset=0,
                   show_frameref=false, convexity=10)
{
    req_children($children);
    half_of(v=(planar ? FWD : DOWN),cp=(planar ? [0,z,0] : [0,0,z]),s=s,planar=planar,
            pattern=pattern, pattern_size=pattern_size, pattern_width=pattern_width,
            repeat=repeat, cut_width=cut_width, cut_angle=cut_angle,
            flip=flip, spread=spread, offset=offset,
            show_frameref=show_frameref,convexity=convexity) children();
}

function bottom_half(p, z=0, planar=false, pattern, pattern_size, pattern_width,
                     repeat, cut_width, cut_angle=0, flip=false, spread, offset=0) =
    assert(is_bool(planar))
    half_of(p,v=(planar ? FWD : DOWN),cp=(planar ? [0,z,0] : [0,0,z]),
            pattern=pattern, pattern_size=pattern_size, pattern_width=pattern_width,
            repeat=repeat, cut_width=cut_width, cut_angle=cut_angle,
            flip=flip, spread=spread, offset=offset);


// Function&Module: top_half()
// Synopsis: Cuts an object at the XY plane, keeping the top half, optionally with a jigsaw-style cut.
// SynTags: Geom, VNF, Path, Region
// Topics: Partitions, Masking
// See Also: half_of(), left_half(), right_half(), front_half(), back_half(), bottom_half(), half_mask(), partition_path()
// Usage: Flat 3D cut
//   top_half([s], [z], [flip=], [spread=], [offset=]) CHILDREN;
// Usage: Patterned 3D cut
//   top_half([s], [z], pattern=, [pattern_size=|pattern_width=], [repeat=], [cut_width=], [cut_angle=], [flip=], [spread=], [offset=], [show_frameref=], [convexity=]) CHILDREN;
// Usage: 2D module
//   top_half([s], [z], planar=true, [pattern=], [pattern_size=|pattern_width=], [repeat=], [cut_width=], [flip=], [spread=], [offset=]) CHILDREN;
// Usage: Function on a 2D polygon or region
//   result = top_half(p, [z], planar=true, [pattern=], [pattern_size=|pattern_width=], [repeat=], [cut_width=], [flip=], [spread=], [offset=]);
// Usage: Function on a VNF (flat cuts only)
//   result = top_half(p, [z], [flip=], [spread=], [offset=]);
// Description:
//   Cuts the children at the XY plane at Z=`z`, or at a patterned interface lying in that plane,
//   keeping the top (+Z; the back, +Y, side if `planar=true`) side by default.  This is a directional wrapper for {{half_of()}} with
//   normal UP (+Z) and cut-frame origin `[0,0,z]`.  The function accepts a 2D polygon/region or a
//   VNF and returns a region or VNF, respectively.  When you give a VNF you cannot give a pattern.
//   The module performs a 2D operation if you give `planar=true`.  The function on 2D data also requires `planar=true`;
//   in 2D, `z` is a Y coordinate, as described below.
//   .
//   The mask is finite: `s` controls its along-cut coverage, retained-side depth and, in 3D,
//   extrusion height.  The mask is centered on the frame origin `[0,0,z]`: in 3D it spans X and Y from -s/2 to s/2 and reaches `s` from the plane into the retained side, toward +Z (toward -Z when `flip=true`).  With `planar=true` it spans only X and reaches `s` from the line `Y=z`.  An object that lies far from X=0 or Y=0 therefore needs a larger `s`.
//   Choose `s` large enough to cover the object; a value larger than twice the object extent is a useful
//   starting point.  A mask that is too small clips unintended parts, while a very large mask can confuse preview.
//   The function calculates its own mask coverage from the 2D input.
//   .
//   The `pattern` parameter is a pattern descriptor or list of descriptors as accepted by
//   {{partition_path()}}.  The basic descriptor strings are
//   `"sawtooth"`, `"square"`, `"triangle"`, `"halfsine"`,
//   `"semicircle"`, `"sinewave"`, `"comb"`, `"finger"`, `"dovetail"`,
//   `"hammerhead"`, and `"jigsaw"`.  These can be combined with each other or
//   with modifiers to change their size and shape or build up more complex
//   compound patterns.  A simple example is "jigsaw 6x" creates six copies of
//   the jigsaw pattern.  See {{partition_path()}} for details on the pattern specification.
//   .
//   Pattern width means the X separation between the first and last points, not its bounding box.
//   When patterns are joined they are connected end to end from their first and last points;
//   no space is added for overhangs.
//   A scalar `pattern_size` scales X and Y uniformly so the pattern is the specified width; `pattern_size=[w,h]` scales
//   X and Y independently to the specified size.  If you set `pattern_width` then the pattern is stretched in X to the specified
//   width, while Y values remain unchanged and do not scale.  The `pattern_size` and `pattern_width` options are
//   mutually exclusive and operate before repetition. Scaling in X is
//   about the middle point between the endpoints; scaling in Y is about Y=0.
//   You will generally want your entire cut to be a little bit shorter than your object so that
//   the cut geometry doesn't produce detached pieces near the boundary.  By setting one of these
//   parameters you can stretch or shrink a pattern so it fits on your object.
//   .
//   The other way to expand a pattern to fit your object is by repetition.  You can repeat
//   a single unit as described above by adding a multiplier to its string.  If you give
//   `cut_width` then your entire (possibly compound) pattern is repeated as many times
//   as possible in the specified width.  You can use `repeat="odd"`, `"even"`
//   to require that the number of copies be odd or even, which controls how the copies
//   will center on your shape: in the odd case one copy will be centered and in the even case
//   the two copies will meet at the center.  As usual, the size of the pattern is determined
//   by its endpoint span, not its bounding box.  If you set `repeat="any"` then either case
//   is permitted.  You can also give `repeat=n` to produce exactly `n` copies, in which
//   case you cannot give `cut_width`.
//   .
//   In order to produce the mating part give `flip=true`, which keeps the bottom (-Z) side of the SAME interface.
//   Flipping does not rotate or reflect the pattern or move the cut: pattern Y=0 stays on the cut plane and
//   positive pattern Y still points UP (+Z).  Giving `flip="both"` produces both sides from
//   the same cut pattern. At zero offset and zero spread they reconstruct the original object
//   (within mask coverage).  The module does not preserve separately addressable solids in that case.
//   With `flip="both"` the `spread` parameter gives the space between the two halves: both are moved by half the spread
//   away from the cut surface, so the top piece moves up (+Z) and the bottom piece down (-Z).  With `planar=true`, the back piece moves toward +Y and the front piece toward -Y.  The spread defaults to `H+2*max(offset,0)+max(1,0.1*H)`, where `H`
//   is the actual Y span of the cut pattern.  The module sets `$idx` to 0 for the normal side and 1 for the opposite side;
//   the function returns `[normal_side,opposite_side]`.  Without `flip="both"`, `$idx` is not set and the function returns a single region or VNF.
//   .
//   The `offset` parameter provides fitting clearance: A negative value shrinks the retained side
//   away from the cut plane; a positive value expands the shape, making the fit tighter.
//   The offset is calculated using a rounded 2D offset() call.
//   .
//   The Y=0 point of the pattern lies on the cut plane at `z`.  Positive Y points along the cut normal.
//   The `cut_angle` parameter rotates the cutting surface around that cut normal. Here that rotation is about the vertical line through `[0,0,z]`; `cut_angle=90` makes the seam run along Y and extrudes it along X.
//   If you need help understanding the orientation of your cut, enable `show_frameref` which displays a coordinate frame
//   where Y (green) is the normal pointing into the retained side and X (red) shows the cut path direction.
// Arguments:
//   p = Polygon, region, or VNF to cut. Function only.
//   s = Finite mask size. Module only. Default: 100
//   z = Z coordinate of the cut plane, centered at X=0; with `planar=true` it is the Y coordinate of the cut line. Default: 0
//   ---
//   planar = Perform a 2D operation, treating `z` as a Y coordinate as {{back_half()}} does.  Required for the function on 2D data. Default: false
//   pattern = Descriptor or list of descriptors suitable for {{partition_path()}}. Default: flat cut
//   pattern_size = If a scalar then uniformly scale the pattern to specified width; if [width, height] then scale the pattern to that size.
//   pattern_width = stretch the pattern width to specified dimension while leaving Y unchanged.
//   repeat = If `cut_width` is given then "odd", "even" or "any" to require an odd number, even number or any number of repeats respectively.   If `cut_width` is not given, then the exact number of pattern copies to generate.  Default: "odd" with `cut_width`, 1 without
//   cut_width = Available width for automatic repetition. Default: undef
//   cut_angle = Rotation about the normal. 3D module only. Default: 0
//   flip = If false keep the normal side; if true keep the opposite side; if "both" keep both sides with optional spread.  Default: false
//   spread = Separation between the two halves when `flip="both"`.  Default: see above
//   offset = Expansion of each retained side; negative shrinks to provide fit clearance. Default: 0
//   show_frameref = Ghost the results and show the cut frame. 3D module only. Default: false
//   convexity = Preview convexity. Module only. Default: 10
// Side Effects:
//   `$idx` is set to 0 on the normal side and 1 on the opposite side when `flip="both"`.
// Examples:
//   top_half() sphere(r=20);
//   top_half(z=5,flip=true) sphere(r=20);
// Example(2D,NoScales): Patterned 2D cut with automatic odd repetition.
//   top_half(planar=true,pattern="jigsaw",pattern_size=[20,8],cut_width=95,s=200)
//       rect([100,60]);
// Example(2D,NoScales): Patterned 2D cut with unconstrained repetition allows one more to fit.  A margin on the sides remains. 
//   top_half(planar=true,pattern="jigsaw",pattern_size=[20,8],cut_width=95,s=200,repeat="any")
//       rect([100,60]);
// Example(2D,NoScales,Med): Specifying 7 repeats in this case creates a thin edge at the ends
//   top_half(planar=true,pattern="jigsaw",pattern_size=[15,8],s=200,repeat=7)
//       rect([100,60]);
// Example(2D,NoScales,Med): You can avoid the thin edge and fit 7 repeats in by specifying the repeats within the pattern and giving a pattern size smaller than your object to leave a margin
//   top_half(planar=true,pattern="jigsaw 7x",pattern_size=[90,8],s=200)
//       rect([100,60]);
// Example(2D,NoScales): A scalar `pattern_size` scales X and Y together, so the shapes get shorter as well as narrower from their original 25x25 size, preserving the aspect ratio.
//   top_half(planar=true,pattern="jigsaw",pattern_size=15,cut_width=95,s=200)
//       rect([100,60]);
// Example(2D,NoScales): `pattern_width` with the same width shrinks only X, so the shapes keep their original height of 25 and their aspect ratio changes.  
//   top_half(planar=true,pattern="jigsaw",pattern_width=15,cut_width=95,s=200)
//       rect([100,60]);
// Example(3D): Two mating parts, offset for clearance and automatically spread.
//   top_half(pattern="jigsaw",pattern_size=[20,8],cut_width=95,
//       flip="both",offset=-0.15,s=200)
//       cuboid([100,60,40]);
// Example(3D): Here a compound pattern is replicated in full to fill the space and we use an explicit `spread` to set the gap between the two halves.  
//   top_half(pattern=["flat 5","triangle 20x15","flat 5"],pattern_size=[20,8],cut_width=95,
//           flip="both",spread=2,s=200)
//       cuboid([100,60,40]);
// Example(3D): Place the cut through the middle of an object that is not centered on the origin by giving `z`.
//   top_half(z=20,pattern="dovetail",pattern_size=[20,8],
//       cut_width=95,flip="both",s=300)
//       translate([-50,-30,0]) cube([100,60,40]);
// Example(2D,NoAxes): Use the function to get two regions in their original positions
//   parts=top_half(rect([80,40]),planar=true,pattern="triangle 20x8",repeat=3,
//             flip="both",spread=0,offset=-0.5);
//   region(parts[0]);
//   region(parts[1]);
// Example(2D,NoAxes): Create a cut path that follows a curve.  The length parameter controls how much of the curve is used before the horizontal flat ends appear
//   cut=partition_path("jigsaw 17x7 5x", length=110,
//                      path=arc(n=100,cp=[0,100],r=100, angle=[-120, -60]));
//   top_half(pattern=cut,flip="both",s=250,spread=0,offset=-0.5,planar=true) rect([120,70]);
// Example(3D): Identify the two child evaluations.
//   top_half(pattern="jigsaw 20x8",repeat=3,flip="both",s=200)
//       color($idx==0 ? "orange" : "lightblue") cuboid([80,50,30]);
// Example(3D): Using `cut_angle` to rotate the cutting mask about the cut normal.
//   top_half(pattern="jigsaw 3x 60x12",cut_angle=45,s=300)
//       cuboid([140,60,40]);
module top_half(s=100, z=0, planar=false, pattern, pattern_size, pattern_width,
                   repeat, cut_width, cut_angle=0, flip=false, spread, offset=0,
                   show_frameref=false, convexity=10)
{
    req_children($children);
    half_of(v=(planar ? BACK : UP),cp=(planar ? [0,z,0] : [0,0,z]),s=s,planar=planar,
            pattern=pattern, pattern_size=pattern_size, pattern_width=pattern_width,
            repeat=repeat, cut_width=cut_width, cut_angle=cut_angle,
            flip=flip, spread=spread, offset=offset,
            show_frameref=show_frameref,convexity=convexity) children();
}

function top_half(p, z=0, planar=false, pattern, pattern_size, pattern_width,
                     repeat, cut_width, cut_angle=0, flip=false, spread, offset=0) =
    assert(is_bool(planar))
    half_of(p,v=(planar ? BACK : UP),cp=(planar ? [0,z,0] : [0,0,z]),
            pattern=pattern, pattern_size=pattern_size, pattern_width=pattern_width,
            repeat=repeat, cut_width=cut_width, cut_angle=cut_angle,
            flip=flip, spread=spread, offset=offset);


// Module: half_mask()
// Synopsis: Mask that when subtracted, cuts the object at the XY plane, removing the bottom half, optionally with a jigsaw-style cut.
// SynTags: Geom
// Topics: Partitions, Masking, Attachments
// See Also: half_of(), left_half(), right_half(), front_half(), back_half(), bottom_half(), top_half(), partition_path()
// Usage: 3D mask
//   half_mask([size], [pattern=], [pattern_size=|pattern_width=], [repeat=], [cut_width=], [flip=], [offset=], [anchor=], [spin=], [orient=], [convexity=]) [ATTACHMENTS];
// Usage: 2D mask
//   half_mask([size], planar=true, [pattern=], [pattern_size=|pattern_width=], [repeat=], [cut_width=], [flip=], [offset=], [anchor=], [spin=]) [ATTACHMENTS];
// Description:
//   Creates an attachable difference mask. Subtract it to retain the side above the
//   XY cut plane. The mask itself occupies the side below the patterned interface, and is extruded
//   along Y.  If you use {{orient()}} to position the mask along a horizontal parent anchor direction then the slice direction will be vertical;
//   if you position it along a vertical direction the slice direction will be front to back (along Y).  If you use `orient=` you may need
//   to apply spin to get the desired position.  The mask CENTER will be the center of the cut plane, so normal use would
//   be to center the mask on a parent object.  The `size` parameter defines a centered region that defines the extent of the mask, so it
//   should be larger than your object; you can give a scalar to produce a cube whose sides are equal.  The actual mask object will occupy
//   approximately half the volume.  
//   .
//   The `pattern` parameter is a pattern descriptor or list of descriptors as accepted by 
//   {{partition_path()}}.  The basic descriptor strings are
//   `"sawtooth"`, `"square"`, `"triangle"`, `"halfsine"`,
//   `"semicircle"`, `"sinewave"`, `"comb"`, `"finger"`, `"dovetail"`,
//   `"hammerhead"`, and `"jigsaw"`.  These can be combined with each other or
//   with modifiers to change their size and shape or build up more complex
//   compound patterns.  A simple example is "jigsaw 6x" creates six copies of
//   the jigsaw pattern.  See {{partition_path()}} for details on the pattern specification. 
//   .
//   Pattern width means the X separation between the first and last points, not its bounding box.
//   When patterns are joined they are connected end to end from their first and last points;
//   no space is added for overhangs.  
//   A scalar `pattern_size` scales X and Y uniformly so the pattern is the specified width; `pattern_size=[w,h]` scales
//   X and Y independently to the specified size.  If you set `pattern_width` then the pattern is stretched in X to the specified
//   width, while Y values remain unchanged and do not scale.  The `pattern_size` and `pattern_width` options are
//   mutually exclusive and operate before repetition. Scaling in X is
//   about the middle point between the endpoints; scaling in Y is about Y=0.
//   You will generally want your entire cut to be a little bit shorter than your object so that
//   the cut geometry doesn't produce detached pieces near the boundary.  By setting one of these
//   parameters you can stretch or shrink a pattern so it fits on your object.  
//   .
//   The other way to expand a pattern to fit your object is by repetition.  You can repeat
//   a single unit as described above by adding a multiplier to its string.  If you give
//   `cut_width` then your entire (possibly compound) pattern is repeated as many times
//   as possible in the specified width.  You can use `repeat="odd"`, `"even"`
//   to require that the number of copies be odd or even, which controls how the copies
//   will center on your shape: in the odd case one copy will be centered and in the even case
//   the two copies will meet at the center.  As usual, the size of the pattern is determined
//   by its endpoint span, not its bounding box.  If you set `repeat="any"` then either case
//   is permitted.  You can also give `repeat=n` to produce exactly `n` copies, in which
//   case you cannot give `cut_width`.  
//   .
//   The `offset` parameter provides fitting clearance: A negative value shrinks the retained side
//   away from the cut plane; a positive value expands the shape, making the fit tighter.
//   The offset is calculated using a rounded 2D offset() call.
//   In order to produce a mask for the mating part give `flip=true`.  Giving 
//   `flip="both"` produces a mask that removes the border between two cut parts assuming that offset<0.
// Arguments:
//   size = Scalar, 3D [X,Y,Z] coverage, or planar [X,Y] coverage. Default: 100
//   ---
//   planar = Create a 2D difference mask keeping Y+ by default. Default: false
//   pattern = String, descriptor list, or open 2D pattern. Default: undef (flat cut)
//   pattern_size = Target endpoint width, or [endpoint width, Y span]. Default: unchanged
//   pattern_width = Target endpoint width without Y scaling; exclusive with pattern_size.
//   repeat = Exact count, or "odd", "even", "any" with cut_width. Default: 1, or "odd" with cut_width
//   cut_width = Available endpoint span for automatic repetition. Default: undef
//   flip = Keep the normal side, opposite side, or both: false, true, "both". Default: false
//   offset = Expansion of the retained side; negative provides clearance. Default: 0
//   anchor = Anchor on the centered nominal size box/rectangle. Default: CENTER
//   spin = Rotation about local Z before orientation. Default: 0
//   orient = Orient local Z+ toward this direction. Ignored in 2D. Default: UP
//   convexity = Preview convexity. Default: 10
// Example(3D):  In its native orientation, the basic mask keeps the part where Z>0 and removes the part where Z<0.
//    half_mask([100,70,60],pattern="jigsaw 16x6",cut_width=75,$fn=32);
// Example(3D): Apply the above mask to keep the upper half of a cuboid
//   diff()
//   cuboid([80,50,40])
//       half_mask([100,70,60],pattern="jigsaw 16x6",cut_width=75,$fn=32);
// Example(3D): The mask is centered relative to the parent regardless of the parent location
//   diff()
//   cube([80,50,40])
//     orient(RIGHT)
//       half_mask(100,pattern="dovetail 14x6",cut_width=45);
// Example(3D): If you use `orient=` instead of {{orient()}} then the mask appears with a different spin.  
//   diff()
//   cube([80,50,40])
//       half_mask(100,pattern="dovetail 14x6",cut_width=45,orient=RIGHT);
// Example(3D,VPR=[68.00,0.00,19.00]): Adjusting the spin
//   diff()
//   cube([80,50,40])
//       half_mask(100,pattern="dovetail 14x6",cut_width=45,orient=LEFT,spin=35);
// Example(3D,VPR=[23.50,0.00,10.00]): Orienting the mask diagonally
//   diff()
//   cube([80,50,40])
//     orient(LEFT+BACK)
//       half_mask(100,pattern="dovetail 14x6",cut_width=45);
// Example(3D): An angle mask on a cylinder
//   diff()
//   cyl(h=50,d=80,anchor=BOT,$fn=64)
//      orient(BACK+DOWN)
//         half_mask(100,pattern="triangle 16x6",cut_width=70);
// Example(3D): Constructing both parts using `flip`.
//   ycopies(n=2, spacing=30)
//   diff()
//     cuboid([80,50,40])
//       orient(BACK)
//         half_mask(100,pattern="dovetail 20x8",cut_width=75,
//                   flip=$idx==0,offset=-0.15);
// Example(3D): Using `flip="both"` with `offset` to remove only a clearance band, leaving both pieces in their original positions.
//   diff()
//     cuboid([40,50,30])
//        orient(RIGHT)
//          half_mask(60,pattern="jigsaw 12x4",cut_width=45,
//                    flip="both",offset=-0.5,$fn=32);
// Example(2D): Masking in 2D
//   diff()
//     rect([80,50])
//        half_mask(100,planar=true,pattern="sinewave 20x6",cut_width=75,
//                  offset=-0.15,$fn=32);
module half_mask(size=100, planar=false, pattern, pattern_size, pattern_width,
                 repeat, cut_width, flip=false, offset=0,
                 anchor=CENTER, spin=0, orient=UP, convexity=10)
{
    dims = assert(is_bool(planar), "\nplanar must be a boolean.")
        let(d = is_num(size) ? (planar ? [size,size] : [size,size,size]) : size)
        assert(is_vector(d,planar ? 2 : 3) && min(d)>0,
            "\nsize must be positive: a scalar, a planar 2-vector, or a 3D 3-vector.")
        d;
    assert(is_bool(flip) || flip=="both", "\nflip must be false, true, or \"both\".");
    assert(is_finite(spin), "\nspin must be finite.");
    assert(planar || (is_vector(orient,3) && norm(orient)>0),
        "\norient must be a nonzero 3-vector.");
    assert(is_int(convexity) && convexity>0, "\nconvexity must be a positive integer.");

    // Reuse the same validation, sizing, and repetition as half_of().
    prepared = _ptn_prepare(default(pattern,[]),pattern_size,pattern_width,repeat,cut_width);
    seam = prepared==[] ? [[0,0]] : prepared;
    assert(is_list(prepared));

    // Offset expands the removal mask when the retained object is to shrink.
    r = assert(is_finite(offset), "\noffset must be finite.") -offset;
    normal_size = planar ? dims.y : dims.z;
    ys = [for(pt=seam) pt.y];

    // Compensate artificial outer faces, extending further when the seam needs room.
    margin = abs(r) + 1e-6*max([1,each dims]);
    left_x = min(-dims.x/2+r, seam[0].x-margin);
    right_x = max(dims.x/2-r, last(seam).x+margin);
    lower_y = min(-normal_size/2+r, min(ys)-margin);
    upper_y = max(normal_size/2-r, max(ys)+margin);

    module removal_side(opposite)
    {
        far_y = opposite ? upper_y : lower_y;
        outline = deduplicate(concat(
            [[left_x,seam[0].y]], seam,
            [[right_x,last(seam).y],[right_x,far_y],[left_x,far_y]]
        ),closed=true);

        if(r==0)
            polygon(outline,convexity=convexity);
        else
            offset(r=r)
                polygon(outline,convexity=convexity);
    }

    module removal_profile()
    {
        if(flip=="both") {
            // Nonnegative retained-side offset leaves no volume to subtract.
            if(offset<0)
                intersection() {
                    removal_side(false);
                    removal_side(true);
                }
        } else
            removal_side(flip);
    }

    default_tag("remove")
        attachable(anchor,spin,planar ? UP : orient,size=dims,two_d=planar) {
            if(planar)
                removal_profile();
            else
                // Pattern X -> -X, pattern Y -> Z, extrusion -> Y, matching half_of(UP).
                multmatrix([[-1,0,0,0],[0,0,1,0],[0,1,0,0],[0,0,0,1]])
                    linear_extrude(height=dims.y,center=true,convexity=convexity)
                        removal_profile();
            children();
        }
}



// Section: Partition Paths

// Function&Module: partition_path()
// Synopsis: Compute a jigsaw style cut path from a descriptor list
// SynTags: Path, Geom
// Topics: Partitions, Masking, Paths
// See Also: stroke(), half_of(), left_half(), right_half(), front_half(), back_half(), bottom_half(), top_half(), half_mask()
// Usage: Function returning an open seam or a closed polygon boundary
//   p = partition_path(pattern, [pattern_size=|pattern_width=], [repeat=], [cut_width=], [length=|l=], [path=], [y=], [seglen=], [segwidth=]);
// Usage: Module producing an open 2D stroke
//   partition_path(pattern, [width=], [pattern_size=|pattern_width=], [repeat=], [cut_width=], [length=|l=], [path=], [seglen=], [segwidth=]);
// Usage: Module producing a filled 2D polygon
//   partition_path(pattern, y=, [pattern_size=|pattern_width=], [repeat=], [cut_width=], [length=|l=], [path=], [seglen=], [segwidth=]);
// Description:
//   Constructs a cutting path for partitioning an object. The function returns a point list. The
//   module produces a stroke or, if `y` is given, a polygon. 
//   This module does not accept children.
//   .
//   **Describing one pattern**
//   The `pattern` parameter may be a single descriptor or a list of descriptors.
//   Each descriptor describes a pattern section, and all of the sections combine to
//   form the full pattern path returned by `partition_path()`.  The output path
//   is centered in X except in the special case when `pattern=path` noted below.  
//   .
//   Most descriptors are strings.  The two exceptions are
//   * A numeric descriptor makes a flat section of that positive length at Y=0.
//   * A 2D-path descriptor is inserted directly into the path, shifted in X to align it with neighboring elements.  If you give
//     a path alone with `pattern=p` then the path is not shifted, but left in its native position.  If you give `pattern=[p]`
//     then it is centered.  
//   .
//   Width of a pattern is X distance between the first and last points, NOT the bounding-box width.
//   Sections join end-to-start in X without being translated in Y; unequal endpoint heights are connected
//   by straight segments.  Intermediate points may backtrack or overhang.  
//   Use explicit flat sections when you need extra spacing. 
//   .
//   The string descriptors are formed from a shape name followed by a sequence of optional modifiers.
//   Pattern shapes appear by default with a size of `seglen` x `segwidth`, which defaults to 25 x 25.  
//   The pattern shape names are:
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
//   The modifier suffixes are:
//   - `"<SHAPE> 3x"`: make 3 copies of the preceding shape
//   - `"<SHAPE> 20x30"`: Resize the preceding result to width 20 and Y span 30. 
//   - `"<SHAPE> xflip"`: Reflect the shape in X.
//   - `"<SHAPE> yflip"`: flip the shape in Y across Y=0.
//   - `"<SHAPE> addflip"`: Concatenate "<SHAPE>" and "<SHAPE> xflip yflip", scaling each copy by 1/2 in both dimensions.
//   - `"<SHAPE> wave"`: Same as "<SHAPE> addflip".
//   - `"<SHAPE> skew:15"`: Skews the shape by 15 degrees.
//   - `"<SHAPE> pinch:33"` or `"<SHAPE> pinch:33%"`: Pinches the top of the shape to 33% the width of the bottom.  Valid range is 0–200.  At 0 the top collapses to a point; at 100 the shape is unchanged; at 200 the top flares to double the width.
//   - `"<SHAPE> pinch:20deg"`: Pinches the top of the shape by angling each wall inward by 20°.  Negative angles flare the walls outward.  Errors if the angle would cause the walls to cross.
//   - `"flat 40"`: A flat section of explicit length 40 (equivalent to placing the scalar `40` in a descriptor list).
//   Modifiers are processed left to right in order.
//   .
//   **Global sizing and repetition**
//   Global sizing operations act on the complete pattern after it is assembled.  
//   A scalar `pattern_size` scales X and Y uniformly so the pattern is the specified width; `pattern_size=[w,h]` scales
//   X and Y independently to the specified size.  If you set `pattern_width` then the pattern is stretched in X to the specified
//   width, while Y values remain unchanged and do not scale.  The `pattern_size` and `pattern_width` options are
//   mutually exclusive and operate before repetition. Scaling in X is
//   about the middle point between the endpoints; scaling in Y is about Y=0.
//   .
//   If you give `cut_width` then your entire pattern is repeated as many times
//   as possible in the specified width.  You can use `repeat="odd"`, `"even"`
//   to require that the number of copies be odd or even, which controls how the copies
//   will center on your shape: in the odd case one copy will be centered and in the even case
//   the two copies will meet at the center.  As usual, the size of the pattern is determined
//   by its endpoint span, not its bounding box.  If you set `repeat="any"` then either case
//   is permitted.  You can also give `repeat=n` to produce exactly `n` copies, in which
//   case you cannot give `cut_width`.  
//   .
//   **End extensions, mapping, and closure**
//   The `length` (`l`) parameter supplies a minimum total endpoint span AFTER repetition. It extends each
//   end by the same amount horizontally at its own Y height.  
//   .
//   The `path` parameter specifies a path for the pattern to follow instead of a simple straight line path.
//   The X coordinate of the pattern maps along your path and Y is the normal distance left of the path.
//   The pattern's Y=0 line follows the path.  The mapping bends the pattern point by point rather than placing
//   rigid copies.  If the path is too long for the pattern only its center is used; if the path is too short
//   it is extrapolated linearly from its end segments.  
//   .
//   Sizing, `cut_width`, and `length` apply BEFORE mapping, and do not measure the final output's
//   X extent or patterned arc length. The unpatterned end sections follow the route and need not
//   remain straight.  Sharp bends or large excursions can distort or self-intersect.
//   .
//   Finally, `y` closes the path that Y coordinate. It must lie strictly outside
//   the final pattern's Y extent. The function returns the closed boundary (without a repeated final
//   vertex); the module fills it with polygon(). 
//   Explicit `repeat=0` or `pattern=[]` returns an empty path and no module geometry unless
//   `length` is supplied. In that case, create a Y=0 line of that span.  
// Arguments:
//   pattern = Descriptor or list of descriptors
//   ---
//   pattern_size = If a scalar then uniformly scale the pattern to specified width; if [width, height] then scale the pattern to that size.
//   pattern_width = stretch the pattern width to specified dimension while leaving Y unchanged.
//   repeat = If `cut_width` is given then "odd", "even" or "any" to require an odd number, even number or any number of repeats respectively.   If `cut_width` is not given, then the exact number of pattern copies to generate.  Default: "odd" with `cut_width`, 1 without
//   cut_width = Available width for automatic repetition. Default: undef
//   length / l = Minimum output path width after repetition. Default: undef (no extension)
//   path = The pattern follows this path instead of a straight line. Default: straight line
//   y = Final polygon closure coordinate. Default: do not close
//   width = (module) Stroke thickness.  Default: 1
//   seglen = Default width of named sections. Default: 25
//   segwidth = Default transverse dimension of named sections. Default: 25
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
// Example(2D): You can pass a 2D path directly as a segment; it is used as-is (no scaling).
//   cust_path = scale([40,30], p=yscale(2, p=arc(n=15, r=0.5, cp=[0.5,0], start=180, angle=-180)));
//   stroke(partition_path([cust_path]), width=3);
// Example(3D): The module returns a stroke which you can extrude into a mask for dividing parts
//   linear_extrude(height=100)
//      partition_path([
//              20,
//              "jigsaw",
//              5,
//              "jigsaw yflip",
//              20,
//              "hammerhead 30x20",
//              20,
//              "jigsaw yflip",
//              5,
//              "jigsaw", 20,
//          ],
//          width=3,
//          $fn=24
//      );
// Example(2D): Use `repeat=` to repeat a the entire pattern.
//      partition_path(
//          ["jigsaw", "jigsaw yflip"],
//           repeat=3,
//          $fn=24,
//          width=3);
// Example(3D): To make a mask that you can intersect with or difference from a part, you can close the path with the `y` option, offset by a clearance, and then extrude the shape  
//   $slop = 0.2;
//   linear_extrude(height=100)
//     offset(r=-$slop)
//     partition_path(
//         [
//          "flat 40",
//          "dovetail 40x25",
//          "flat 10",
//          "jigsaw yflip",
//          "flat 40",
//          "hammerhead 30x20",
//          "flat 40",
//          "jigsaw yflip",
//          "flat 10",
//          "jigsaw",
//          "flat 40"
//           ],
//         y=150,
//         $fn=24
//       );
// Example(2D,NoAxes,Med): You can use list comprehensions in constructing partition path descriptions.
//   partition_path([
//           50,
//           "jigsaw",
//           30,
//           for (i=[1:4])
//             each ["sawtooth", "triangle"],
//           30,
//           "jigsaw yflip",
//           50,
//       ],
//       y=150,
//       $fn=24
//   );
// Example(2D,NoScales): Resize the whole pattern and repeat the largest odd number that fit in `cut_width`. 
//   partition_path(["jigsaw","dovetail"],pattern_size=[30,8],cut_width=95,length=120,width=1.5,$fn=24);
// Example(2D,NoScales): Assemble a composite unit and repeat it twice.
//   partition_path(["jigsaw 15x6",5,"dovetail 15x6 yflip"],repeat=2,width=1.5,$fn=24);
// Example(2D,NoScales): When you give a path the pattern is centered on it and uses only the part it needs
//   partition_path("dovetail 12x8",repeat=15,
//                  path=circle(d=100, $fn=200),width=1,$fn=24);
// Example(2D,NoScales): If the path is too short it's end segments are extended as required to either fit all the requested repeats or to reach the specified length.  In this example both the repeats and extended length appear on the extrapolated straight ends.  
//   partition_path("dovetail 12x8",repeat=18, length=280,
//                  path=arc(d=100, angle=[105, 255],n=64),width=1);
// Example(2D,NoScales): In this example, `pattern_width` is set to the exact length of a path whose first and last points are the same
//   partition_path("jigsaw 12x8 25x",pattern_width=PI*100, 
//                  path=list_wrap(circle(d=100, $fn=200),$fn=24));
// Example(2D,NoScales): Add space asymmetrically to shift the pattern away from the center
//   middle=partition_path("jigsaw 20x8",repeat=3);
//   partition_path([20,middle,5],width=1.5);

function partition_path(pattern, pattern_size, pattern_width, repeat, cut_width,
                        length, l, path, y, seglen=25, segwidth=25) =
    assert(is_undef(length) || is_undef(l), "\nDo not combine length and l.")
    let(total=default(length,l))
    assert(is_undef(total) || (is_finite(total) && total>0), "\nlength/l must be positive.")
    assert(is_undef(y) || is_finite(y), "\ny must be finite.")
    assert(is_undef(path) || is_path(path,2), "\npath must be a finite 2D route.")
    let(
        seam=_ptn_prepare(pattern,pattern_size,pattern_width,repeat,cut_width,seglen,segwidth),
        empty_center=is_path(pattern,2) ? _ptn_xcenter(pattern) : 0,
        extended=_ptn_extend(seam,total,empty_center),
        mapped=is_undef(path) || extended==[] ? extended : _ptn_path_redirect(path,extended)
    ) _ptn_close(mapped,y);

module partition_path(pattern, pattern_size, pattern_width, repeat, cut_width,
                      length, l, path, y, width=1, seglen=25, segwidth=25)
{
    assert($children==0, "\npartition_path() does not accept children.");
    assert(!is_undef(y) || (is_finite(width) && width>0), "\nStroke width must be positive.");
    seam=partition_path(pattern,pattern_size=pattern_size,pattern_width=pattern_width,
                        repeat=repeat,cut_width=cut_width,length=length,l=l,
                        path=path,y=y,seglen=seglen,segwidth=segwidth);
    if(seam!=[]) {
        if(is_undef(y)) stroke(seam,width=width,closed=false);
        else polygon(seam);
    }
}


// Internal implementation

// Internal pattern geometry.  X dimensions are ENDPOINT spans, not bounds.
function _ptn_xwidth(p) = abs(last(p).x-p[0].x);
function _ptn_xcenter(p) = (p[0].x+last(p).x)/2;
function _ptn_yheight(p) = p==[] ? 0 : let(ys=column(p,1)) max(ys)-min(ys);

function _ptn_clean(p) =
    len(p)<2 ? p :
    let(q=deduplicate(p,closed=false))
    len(q)<3 ? q : path_merge_collinear(q,closed=false);

function _ptn_forward(p) =
    assert(is_path(p,2), "\nA pattern section must be a finite 2D path.")
    assert(p[0].x!=last(p).x, "\nA nonempty pattern must have nonzero endpoint width.")
    _ptn_clean(p[0].x<last(p).x ? p : reverse(p));

// Join sections by their endpoint X coordinates, without moving them in Y.
// A connector between unequal endpoint heights is implicit in concatenation.
function _ptn_join(parts, center=true) =
    parts==[] ? [] :
    let(
        paths=[for(p=parts) _ptn_forward(p)],
        positions=cumsum([0,for(p=paths) _ptn_xwidth(p)]),
        xoff=center ? last(positions)/2 : 0
    )
    _ptn_clean([for(i=idx(paths)) each
        [for(pt=paths[i]) [pt.x-paths[i][0].x+positions[i]-xoff,pt.y]]]);

// Preserve endpoint midpoint in X and the Y=0 datum.
function _ptn_resize(p, size, width) =
    p==[] || (is_undef(size) && is_undef(width)) ? p :
    let(
        target=is_undef(size) ? width : is_num(size) ? size : size.x,
        sx=target/_ptn_xwidth(p),
        h=_ptn_yheight(p),
        sy=is_undef(size) ? 1 : is_num(size) ? sx : h==0 ? 1 : size.y/h,
        cx=_ptn_xcenter(p)
    ) [for(pt=p) [cx+sx*(pt.x-cx),sy*pt.y]];

function _ptn_replicate(p, n) =
    n==0 || p==[] ? [] :
    let(w=_ptn_xwidth(p))
    _ptn_clean([for(i=[0:1:n-1]) each
        [for(pt=p) pt+[(i-(n-1)/2)*w,0]]]);

function _ptn_validate(pattern_size, pattern_width, repeat, cut_width) =
    assert(is_undef(pattern_size) ||
        (is_finite(pattern_size) && pattern_size>0) ||
        (is_vector(pattern_size,2) && min(pattern_size)>0),
        "\npattern_size must be a positive number or positive 2-vector.")
    assert(is_undef(pattern_width) || (is_finite(pattern_width) && pattern_width>0),
        "\npattern_width must be positive.")
    assert(is_undef(pattern_size) || is_undef(pattern_width),
        "\nDo not combine pattern_size and pattern_width.")
    assert(is_undef(cut_width) || (is_finite(cut_width) && cut_width>0),
        "\ncut_width must be positive.")
    assert(is_undef(repeat) || (is_int(repeat) && repeat>=0) ||
        repeat=="odd" || repeat=="even" || repeat=="any",
        "\nrepeat must be a nonnegative integer, \"odd\", \"even\", or \"any\".")
    assert(is_undef(cut_width) || is_undef(repeat) || is_string(repeat),
        "\nA numeric repeat cannot be combined with cut_width.")
    assert(!is_string(repeat) || !is_undef(cut_width),
        "\nA repeat policy requires cut_width.")
    true;

function _ptn_count(p, repeat, cut_width) =
    is_undef(cut_width) ? default(repeat,1) :
    let(
        // Permit only roundoff at an integral number of periods.
        fit=floor(cut_width/_ptn_xwidth(p)+1e-9),
        policy=default(repeat,"odd"),
        n=policy=="any" ? fit : policy=="even" ? 2*floor(fit/2) :
          fit%2==0 ? fit-1 : fit
    )
    assert(n>0, str("\nNo positive ",policy," repeat count fits within cut_width.")) n;

function _ptn_build(pattern, seglen, segwidth) =
    is_path(pattern,2) ? _ptn_forward(pattern) :
    let(desc=is_string(pattern) ? [pattern] : pattern)
    _ptn_join([for(pd=desc)
        is_path(pd,2) ? pd :
        is_num(pd) || is_string(pd) ? _ptn_sect(pd,seglen,segwidth) :
        assert(false,str("\nInvalid pattern descriptor: ",pd))]);

function _ptn_prepare(pattern, pattern_size, pattern_width, repeat, cut_width,
                      seglen=25, segwidth=25) =
    assert(is_string(pattern) || is_list(pattern),
        "\npattern must be a string, a descriptor list, or a 2D path.")
    assert(_ptn_validate(pattern_size,pattern_width,repeat,cut_width))
    assert(is_finite(seglen) && seglen>0 && is_finite(segwidth) && segwidth>0,
        "\nseglen and segwidth must be positive.")
    pattern==[] || repeat==0 ? [] :
    let(p=_ptn_resize(_ptn_build(pattern,seglen,segwidth),pattern_size,pattern_width))
    _ptn_replicate(p,_ptn_count(p,repeat,cut_width));

function _ptn_extend(p, length, empty_center=0) =
    is_undef(length) ? p :
    p==[] ? [[empty_center-length/2,0],[empty_center+length/2,0]] :
    _ptn_xwidth(p)>=length ? p :
    let(cx=_ptn_xcenter(p))
    _ptn_clean(concat([[cx-length/2,p[0].y]],p,[[cx+length/2,last(p).y]]));

function _ptn_close(p, y) =
    p==[] || is_undef(y) ? p :
    let(ys=column(p,1))
    assert(y<min(ys) || y>max(ys),
        "\nClosure y must lie outside the final seam's Y extent.")
    let(closed=concat([[last(p).x,y],[p[0].x,y]],p))
    // The mapping route may run in either direction; determine winding geometrically.
    let(area2=sum([for(i=idx(closed)) let(j=(i+1)%len(closed))
                       closed[i].x*closed[j].y-closed[j].x*closed[i].y]))
    area2>0 ? reverse(closed) : closed;

// Include EVERY pattern corner; subdivide straight segments for redirection.
function _ptn_resample(p) = [
    for(i=[0:1:len(p)-2]) each
        let(a=p[i],b=p[i+1],n=max(1,ceil(norm(b-a))))
        [for(j=[0:1:n-1]) lerp(a,b,j/n)],
    last(p)
];

function _ptn_map_point(route, route_length, pt) =
    pt.x<0 ?
        let(t=unit(route[1]-route[0]))
        route[0]+pt.x*t+pt.y*[-t.y,t.x] :
    pt.x>route_length ?
        let(t=unit(last(route)-route[len(route)-2]))
        last(route)+(pt.x-route_length)*t+pt.y*[-t.y,t.x] :
    let(info=path_cut_points(route,pt.x,closed=false,direction=true))
    info[0]+unit(info[3],BACK)*pt.y;

function _ptn_path_redirect(route, p) =
    assert(is_path(route,2), "\npath must be a finite 2D route.")
    let(base=_ptn_clean(route))
    assert(len(base)>=2 && path_length(base)>0, "\npath must have positive length.")
    p==[] ? [] :
    let(
        L=path_length(base),
        start=(L-_ptn_xwidth(p))/2,
        sampled=[for(pt=_ptn_resample(p)) [pt.x-p[0].x+start,pt.y]],
        corners=cumsum([0,for(i=[1:1:len(base)-1]) norm(base[i]-base[i-1])]),
        refined=_ptn_insert_x(sampled,corners)
    ) _ptn_clean([for(pt=refined) _ptn_map_point(base,L,pt)]);

// Insert crossed route-corner distances in traversal order, including backtracking.
function _ptn_insert_x(path, xs) = [
    for(i=[0:1:len(path)-2]) each
        let(a=path[i],b=path[i+1],dx=b.x-a.x)
        [a, if(dx!=0)
            for(x=dx>0 ? xs : reverse(xs))
                let(t=(x-a.x)/dx)
                if(t>0 && t<1) lerp(a,b,t)],
    last(path)
];


// Build one named section, processing string modifiers left-to-right.
function _ptn_sect(type, length=25, width=25, invert=false) =
    assert(is_finite(length) && length>0 && is_finite(width) && width>0, "\nSection length and width must be positive.")
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
                xpos = _ptn_xcenter(sect),
                rsect = reverse(xflip(x=xpos, p=sect))
            ) rsect :
        opt == "addflip" || opt == "wave"? let(
                sect1 = _ptn_sect(type, length, width),
                sect2 = _ptn_sect(str(type, " yflip xflip"), length, width),
                osect = _ptn_join([scale(0.5,p=sect1),scale(0.5,p=sect2)],center=false)
            ) osect :
        is_digit(opt[0]) && ends_with(opt, "x")? let(  // 4x  (repetition)
                repstr = substr(opt, 0, len(opt)-1),
                reps = parse_int(repstr),
                checks =
                    assert(is_finite(reps) && reps>0, "Repetition option expected to be in the form COUNTx.  ie: \"3x\""),
                sect = _ptn_sect(type, length, width),
                osect = _ptn_replicate(_ptn_forward(sect),reps)
            ) osect :
        is_digit(opt[0]) && str_find(opt, "x") != undef? let(  // 30x20  (size)
                parts = str_split(opt, "x"),
                newlength = parse_float(parts[0]),
                newwidth = parse_float(parts[1]),
                checks =
                    assert(len(parts) == 2, "Size option expected to be in the form LENGTHxWIDTH.  ie: \"30x25\"")
                    assert(is_finite(newlength) && is_finite(newwidth) && newlength>0 && newwidth>0, "Size option must give two positive dimensions."),
                raw_sect = _ptn_sect(type, length, width),
                sect = _ptn_resize(_ptn_forward(raw_sect),[newlength,newwidth])
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
                w_half = _ptn_xwidth(raw_sect)/2,
                midx = _ptn_xcenter(raw_sect),
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

// Section: Legacy Partitioning
//   These legacy partitioning functions will eventually go away.  Use
//   {{half_mask()}}, {{back_half()}} and {{partition_path()}} instead.  


// Module: partition_mask()
// Synopsis: Creates a mask to remove half an object with the remaining half suitable for reassembly.
// SynTags: Geom
// Topics: Partitions, Masking, Paths
// See Also: partition_cut_mask(), partition(), dovetail(), half_of(), left_half(), right_half(), front_half(), back_half(), bottom_half(), top_half(), partition_path()
// Usage:
//   partition_mask(l, w, h, [cutsize], [cutpath], [gap], [inverse], [$slop=], [anchor=], [spin=], [orient=]) [ATTACHMENTS];
// Description:
//   This module is deprecated and will be removed in the future.  Use {{half_mask()}} instead.  
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
    echo("Module partition_mask() is deprecated and will be removed; use half_mask() instead");
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
// See Also: partition_mask(), partition(), dovetail(), half_of(), left_half(), right_half(), front_half(), back_half(), bottom_half(), top_half(), partition_path()
// Usage:
//   partition_cut_mask(l, [cutsize], [cutpath], [gap], [inverse], [$slop=], [anchor=], [spin=], [orient=]) [ATTACHMENTS];
// Description:
//   This function is deprecated and will be removed in the future.  Use {{partition_path()}} instead.
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
    echo("Module partition_cut_mask() is deprecated and will be removed; use partition_path() instead");
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
// See Also: partition_cut_mask(), partition_mask(), dovetail(), half_of(), left_half(), right_half(), front_half(), back_half(), bottom_half(), top_half(), partition_path()
// Usage:
//   partition(size, [spread], [cutsize], [cutpath], [gap], [spin], [$slop=]) CHILDREN;
// Description:
//   This module is deprecated and will be removed in the future.  Use {{back_half()}} instead.  
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
//   partition(cutpath="jigsaw", $fn=12) cylinder(h=50, d=80, center=false);
// Example(2D,Med): Using `$idx` to display only the back piece of the partition
//   partition(cutpath="jigsaw", $fn=12)
//     if ($idx==0) cylinder(h=50, d=80, center=false);

module partition(size=100, spread=10, cutsize=10, cutpath="jigsaw", gap=0, cutpath_centered=true, convexity=10, spin=0)
{
    echo("Module partition() is deprecated and will be removed in the future.  Use back_half() instead.");   
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
        reps_raw = 1 + floor((l - cutsize.x) / (cutsize.x + gap)),
        _reps = reps_raw%2==0 && cutpath_centered ? reps_raw-1 : reps_raw,
        reps = max(1, _reps),
        cplen = reps*cutsize.x + max(0, reps-1)*gap,
        path = deduplicate(concat(
            [[-l/2, cutpath[0].y*cutsize.y]],
            [for (i=[0:1:reps-1], pt=cutpath) v_mul(pt,cutsize)+[i*(cutsize.x+gap) - cplen/2, 0]],
            [[ cplen/2, cutpath[len(cutpath)-1].y*cutsize.y]]
        ))
    ) path;



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
