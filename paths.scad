//////////////////////////////////////////////////////////////////////
// LibFile: paths.scad
//   Support for polygons and paths.
// Includes:
//   include <BOSL2/std.scad>
//////////////////////////////////////////////////////////////////////


include <triangulation.scad>


// Section: Functions


// Function: is_path()
// Usage:
//   is_path(list, [dim], [fast])
// Description:
//   Returns true if `list` is a path.  A path is a list of two or more numeric vectors (AKA points).
//   All vectors must of the same size, and may only contain numbers that are not inf or nan.
//   By default the vectors in a path must be 2d or 3d.  Set the `dim` parameter to specify a list
//   of allowed dimensions, or set it to `undef` to allow any dimension.  
// Examples:
//   is_path([[3,4],[5,6]]);    // Returns true
//   is_path([[3,4]]);          // Returns false
//   is_path([[3,4],[4,5]],2);  // Returns true
//   is_path([[3,4,3],[5,4,5]],2);  // Returns false
//   is_path([[3,4,3],[5,4,5]],2);  // Returns false
//   is_path([[3,4,5],undef,[4,5,6]]);  // Returns false
//   is_path([[3,5],[undef,undef],[4,5]]);  // Returns false
//   is_path([[3,4],[5,6],[5,3]]);     // Returns true
//   is_path([3,4,5,6,7,8]);           // Returns false
//   is_path([[3,4],[5,6]], dim=[2,3]);// Returns true
//   is_path([[3,4],[5,6]], dim=[1,3]);// Returns false
//   is_path([[3,4],"hello"], fast=true); // Returns true
//   is_path([[3,4],[3,4,5]]);            // Returns false
//   is_path([[1,2,3,4],[2,3,4,5]]);      // Returns false
//   is_path([[1,2,3,4],[2,3,4,5]],undef);// Returns true
// Arguments:
//   list = list to check
//   dim = list of allowed dimensions of the vectors in the path.  Default: [2,3]
//   fast = set to true for fast check that only looks at first entry.  Default: false
function is_path(list, dim=[2,3], fast=false) =
    fast
    ?   is_list(list) && is_vector(list[0]) 
    :   is_matrix(list) 
        && len(list)>1 
        && len(list[0])>0
        && (is_undef(dim) || in_list(len(list[0]), force_list(dim)));


// Function: is_closed_path()
// Usage:
//   is_closed_path(path, [eps]);
// Description:
//   Returns true if the first and last points in the given path are coincident.
function is_closed_path(path, eps=EPSILON) = approx(path[0], path[len(path)-1], eps=eps);


// Function: close_path()
// Usage:
//   close_path(path);
// Description:
//   If a path's last point does not coincide with its first point, closes the path so it does.
function close_path(path, eps=EPSILON) =
    is_closed_path(path,eps=eps)? path : concat(path,[path[0]]);


// Function: cleanup_path()
// Usage:
//   cleanup_path(path);
// Description:
//   If a path's last point coincides with its first point, deletes the last point in the path.
function cleanup_path(path, eps=EPSILON) =
    is_closed_path(path,eps=eps)? [for (i=[0:1:len(path)-2]) path[i]] : path;


// Function: path_subselect()
// Usage:
//   path_subselect(path,s1,u1,s2,u2,[closed]):
// Description:
//   Returns a portion of a path, from between the `u1` part of segment `s1`, to the `u2` part of
//   segment `s2`.  Both `u1` and `u2` are values between 0.0 and 1.0, inclusive, where 0 is the start
//   of the segment, and 1 is the end.  Both `s1` and `s2` are integers, where 0 is the first segment.
// Arguments:
//   path = The path to get a section of.
//   s1 = The number of the starting segment.
//   u1 = The proportion along the starting segment, between 0.0 and 1.0, inclusive.
//   s2 = The number of the ending segment.
//   u2 = The proportion along the ending segment, between 0.0 and 1.0, inclusive.
//   closed = If true, treat path as a closed polygon.
function path_subselect(path, s1, u1, s2, u2, closed=false) =
    let(
        lp = len(path),
        l = lp-(closed?0:1),
        u1 = s1<0? 0 : s1>l? 1 : u1,
        u2 = s2<0? 0 : s2>l? 1 : u2,
        s1 = constrain(s1,0,l),
        s2 = constrain(s2,0,l),
        pathout = concat(
            (s1<l && u1<1)? [lerp(path[s1],path[(s1+1)%lp],u1)] : [],
            [for (i=[s1+1:1:s2]) path[i]],
            (s2<l && u2>0)? [lerp(path[s2],path[(s2+1)%lp],u2)] : []
        )
    ) pathout;


// Function: simplify_path()
// Description:
//   Takes a path and removes unnecessary subsequent collinear points.
// Usage:
//   simplify_path(path, [eps])
// Arguments:
//   path = A list of path points of any dimension.
//   eps = Largest positional variance allowed.  Default: `EPSILON` (1-e9)
function simplify_path(path, eps=EPSILON) =
    assert( is_path(path), "Invalid path." )
    assert( is_undef(eps) || (is_finite(eps) && (eps>=0) ), "Invalid tolerance." )    
    len(path)<=2 ? path :
    let(
        indices = [
            0,
            for (i=[1:1:len(path)-2]) 
                if (!collinear(path[i-1], path[i], path[i+1], eps=eps)) i, 
            len(path)-1 
        ]
    ) [for (i=indices) path[i]];


// Function: simplify_path_indexed()
// Description:
//   Takes a list of points, and a list of indices into `points`,
//   and removes from the list all indices of subsequent indexed points that are unecessarily collinear.
//   Returns the list of the remained indices.
// Usage:
//   simplify_path_indexed(points,indices, eps)
// Arguments:
//   points = A list of points.
//   indices = A list of indices into `points` that forms a path.
//   eps = Largest angle variance allowed.  Default: EPSILON (1-e9) degrees.
function simplify_path_indexed(points, indices, eps=EPSILON) =
    len(indices)<=2? indices :
    let(
        indices = concat(
            indices[0],
            [
                for (i=[1:1:len(indices)-2]) let( 
                    i1 = indices[i-1],
                    i2 = indices[i],
                    i3 = indices[i+1]
                ) if (!collinear(points[i1], points[i2], points[i3], eps=eps))
                indices[i]
            ], 
            indices[len(indices)-1]
        )
    ) indices;


// Function: path_length()
// Usage:
//   path_length(path,[closed])
// Description:
//   Returns the length of the path.
// Arguments:
//   path = The list of points of the path to measure.
//   closed = true if the path is closed.  Default: false
// Example:
//   path = [[0,0], [5,35], [60,-25], [80,0]];
//   echo(path_length(path));
function path_length(path,closed=false) =
    len(path)<2? 0 :
    sum([for (i = [0:1:len(path)-2]) norm(path[i+1]-path[i])])+(closed?norm(path[len(path)-1]-path[0]):0);


// Function: path_segment_lengths()
// Usage:
//   path_segment_lengths(path,[closed])
// Description:
//   Returns list of the length of each segment in a path
// Arguments:
//   path = path to measure
//   closed = true if the path is closed.  Default: false
function path_segment_lengths(path, closed=false) =
    [
        for (i=[0:1:len(path)-2]) norm(path[i+1]-path[i]),
        if (closed) norm(path[0]-last(path))
    ]; 


// Function: path_pos_from_start()
// Usage:
//   pos = path_pos_from_start(path,length,[closed]);
// Description:
//   Finds the segment and relative position along that segment that is `length` distance from the
//   front of the given `path`.  Returned as [SEGNUM, U] where SEGNUM is the segment number, and U is
//   the relative distance along that segment, a number from 0 to 1.  If the path is shorter than the
//   asked for length, this returns `undef`.
// Arguments:
//   path = The path to find the position on.
//   length = The length from the start of the path to find the segment and position of.
// Example(2D):
//   path = circle(d=50,$fn=18);
//   pos = path_pos_from_start(path,20,closed=false);
//   stroke(path,width=1,endcaps=false);
//   pt = lerp(path[pos[0]], path[(pos[0]+1)%len(path)], pos[1]);
//   color("red") translate(pt) circle(d=2,$fn=12);
function path_pos_from_start(path,length,closed=false,_d=0,_i=0) =
    let (lp = len(path))
    _i >= lp - (closed?0:1)? undef :
    let (l = norm(path[(_i+1)%lp]-path[_i]))
    _d+l <= length? path_pos_from_start(path,length,closed,_d+l,_i+1) :
    [_i, (length-_d)/l];


// Function: path_pos_from_end()
// Usage:
//   pos = path_pos_from_end(path,length,[closed]);
// Description:
//   Finds the segment and relative position along that segment that is `length` distance from the
//   end of the given `path`.  Returned as [SEGNUM, U] where SEGNUM is the segment number, and U is
//   the relative distance along that segment, a number from 0 to 1.  If the path is shorter than the
//   asked for length, this returns `undef`.
// Arguments:
//   path = The path to find the position on.
//   length = The length from the end of the path to find the segment and position of.
// Example(2D):
//   path = circle(d=50,$fn=18);
//   pos = path_pos_from_end(path,20,closed=false);
//   stroke(path,width=1,endcaps=false);
//   pt = lerp(path[pos[0]], path[(pos[0]+1)%len(path)], pos[1]);
//   color("red") translate(pt) circle(d=2,$fn=12);
function path_pos_from_end(path,length,closed=false,_d=0,_i=undef) =
    let (
        lp = len(path),
        _i = _i!=undef? _i : lp - (closed?1:2)
    )
    _i < 0? undef :
    let (l = norm(path[(_i+1)%lp]-path[_i]))
    _d+l <= length? path_pos_from_end(path,length,closed,_d+l,_i-1) :
    [_i, 1-(length-_d)/l];


// Function: path_trim_start()
// Usage:
//   path_trim_start(path,trim);
// Description:
//   Returns the `path`, with the start shortened by the length `trim`.
// Arguments:
//   path = The path to trim.
//   trim = The length to trim from the start.
// Example(2D):
//   path = circle(d=50,$fn=18);
//   path2 = path_trim_start(path,5);
//   path3 = path_trim_start(path,20);
//   color("blue") stroke(path3,width=5,endcaps=false);
//   color("cyan") stroke(path2,width=3,endcaps=false);
//   color("red") stroke(path,width=1,endcaps=false);
function path_trim_start(path,trim,_d=0,_i=0) =
    _i >= len(path)-1? [] :
    let (l = norm(path[_i+1]-path[_i]))
    _d+l <= trim? path_trim_start(path,trim,_d+l,_i+1) :
    let (v = unit(path[_i+1]-path[_i]))
    concat(
        [path[_i+1]-v*(l-(trim-_d))],
        [for (i=[_i+1:1:len(path)-1]) path[i]]
    );


// Function: path_trim_end()
// Usage:
//   path_trim_end(path,trim);
// Description:
//   Returns the `path`, with the end shortened by the length `trim`.
// Arguments:
//   path = The path to trim.
//   trim = The length to trim from the end.
// Example(2D):
//   path = circle(d=50,$fn=18);
//   path2 = path_trim_end(path,5);
//   path3 = path_trim_end(path,20);
//   color("blue") stroke(path3,width=5,endcaps=false);
//   color("cyan") stroke(path2,width=3,endcaps=false);
//   color("red") stroke(path,width=1,endcaps=false);
function path_trim_end(path,trim,_d=0,_i=undef) =
    let (_i = _i!=undef? _i : len(path)-1)
    _i <= 0? [] :
    let (l = norm(path[_i]-path[_i-1]))
    _d+l <= trim? path_trim_end(path,trim,_d+l,_i-1) :
    let (v = unit(path[_i]-path[_i-1]))
    concat(
        [for (i=[0:1:_i-1]) path[i]],
        [path[_i-1]+v*(l-(trim-_d))]
    );


// Function: path_closest_point()
// Usage:
//   path_closest_point(path, pt);
// Description:
//   Finds the closest path segment, and point on that segment to the given point.
//   Returns `[SEGNUM, POINT]`
// Arguments:
//   path = The path to find the closest point on.
//   pt = the point to find the closest point to.
// Example(2D):
//   path = circle(d=100,$fn=6);
//   pt = [20,10];
//   closest = path_closest_point(path, pt);
//   stroke(path, closed=true);
//   color("blue") translate(pt) circle(d=3, $fn=12);
//   color("red") translate(closest[1]) circle(d=3, $fn=12);
function path_closest_point(path, pt) =
    let(
        pts = [for (seg=idx(path)) segment_closest_point(select(path,seg,seg+1),pt)],
        dists = [for (p=pts) norm(p-pt)],
        min_seg = min_index(dists)
    ) [min_seg, pts[min_seg]];


// Function: path_tangents()
// Usage:
//   tangs = path_tangents(path, [closed], [uniform]);
// Description:
//   Compute the tangent vector to the input path.  The derivative approximation is described in deriv().
//   The returns vectors will be normalized to length 1.  If any derivatives are zero then
//   the function fails with an error.  If you set `uniform` to false then the sampling is
//   assumed to be non-uniform and the derivative is computed with adjustments to produce corrected
//   values.
// Arguments:
//   path = path to find the tagent vectors for
//   closed = set to true of the path is closed.  Default: false
//   uniform = set to false to correct for non-uniform sampling.  Default: true
// Example: A shape with non-uniform sampling gives distorted derivatives that may be undesirable
//   rect = square([10,3]);
//   tangents = path_tangents(rect,closed=true);
//   stroke(rect,closed=true, width=0.1);
//   color("purple")
//       for(i=[0:len(tangents)-1])
//           stroke([rect[i]-tangents[i], rect[i]+tangents[i]],width=.1, endcap2="arrow2");
// Example: A shape with non-uniform sampling gives distorted derivatives that may be undesirable
//   rect = square([10,3]);
//   tangents = path_tangents(rect,closed=true,uniform=false);
//   stroke(rect,closed=true, width=0.1);
//   color("purple")
//       for(i=[0:len(tangents)-1])
//           stroke([rect[i]-tangents[i], rect[i]+tangents[i]],width=.1, endcap2="arrow2");
function path_tangents(path, closed=false, uniform=true) =
    assert(is_path(path))
    !uniform ? [for(t=deriv(path,closed=closed, h=path_segment_lengths(path,closed))) unit(t)]
             : [for(t=deriv(path,closed=closed)) unit(t)];


// Function: path_normals()
// Usage:
//   norms = path_normals(path, [tangents], [closed]);
// Description:
//   Compute the normal vector to the input path.  This vector is perpendicular to the
//   path tangent and lies in the plane of the curve.  For 3d paths we define the plane of the curve
//   at path point i to be the plane defined by point i and its two neighbors.  At the endpoints of open paths
//   we use the three end points.  The computed normal is the one lying in this plane and pointing to the
//   right of the direction of the path.  If points are collinear then the path does not define a unique plane
//   and hence the (right pointing) normal is not uniquely defined.  In this case the function issues an error.
//   For 2d paths the plane is always defined so the normal fails to exist only
//   when the derivative is zero (in the case of repeated points).
function path_normals(path, tangents, closed=false) =
    assert(is_path(path,[2,3]))
    assert(is_bool(closed))
    let(
         tangents = default(tangents, path_tangents(path,closed)),
         dim=len(path[0])
    )
    assert(is_path(tangents) && len(tangents[0])==dim,"Dimensions of path and tangents must match")
    [
     for(i=idx(path))
         let(
             pts = i==0 ? (closed? select(path,-1,1) : select(path,0,2))
                 : i==len(path)-1 ? (closed? select(path,i-1,i+1) : select(path,i-2,i))
                 : select(path,i-1,i+1)
        )
        dim == 2 ? [tangents[i].y,-tangents[i].x]
                 : let(v=cross(cross(pts[1]-pts[0], pts[2]-pts[0]),tangents[i]))
                   assert(norm(v)>EPSILON, "3D path contains collinear points")
                   unit(v)
    ];


// Function: path_curvature()
// Usage:
//   curvs = path_curvature(path, [closed]);
// Description:
//   Numerically estimate the curvature of the path (in any dimension). 
function path_curvature(path, closed=false) =
    let( 
        d1 = deriv(path, closed=closed),
        d2 = deriv2(path, closed=closed)
    ) [
        for(i=idx(path))
        sqrt(
            sqr(norm(d1[i])*norm(d2[i])) -
            sqr(d1[i]*d2[i])
        ) / pow(norm(d1[i]),3)
    ];


// Function: path_torsion()
// Usage:
//   tortions = path_torsion(path, [closed]);
// Description:
//   Numerically estimate the torsion of a 3d path.  
function path_torsion(path, closed=false) =
    let(
        d1 = deriv(path,closed=closed),
        d2 = deriv2(path,closed=closed),
        d3 = deriv3(path,closed=closed)
    ) [
        for (i=idx(path)) let(
            crossterm = cross(d1[i],d2[i])
        ) crossterm * d3[i] / sqr(norm(crossterm))
    ];


// Function: path_chamfer_and_rounding()
// Usage:
//   path2 = path_chamfer_and_rounding(path, [closed], [chamfer], [rounding]);
// Description:
//   Rounds or chamfers corners in the given path.
// Arguments:
//   path = The path to chamfer and/or round.
//   closed = If true, treat path like a closed polygon.  Default: true
//   chamfer = The length of the chamfer faces at the corners.  If given as a list of numbers, gives individual chamfers for each corner, from first to last.  Default: 0 (no chamfer)
//   rounding = The rounding radius for the corners.  If given as a list of numbers, gives individual radii for each corner, from first to last.  Default: 0 (no rounding)
// Example(2D): Chamfering a Path
//   path = star(5, step=2, d=100);
//   path2 = path_chamfer_and_rounding(path, closed=true, chamfer=5);
//   stroke(path2, closed=true);
// Example(2D): Per-Corner Chamfering
//   path = star(5, step=2, d=100);
//   chamfs = [for (i=[0:1:4]) each 3*[i,i]];
//   path2 = path_chamfer_and_rounding(path, closed=true, chamfer=chamfs);
//   stroke(path2, closed=true);
// Example(2D): Rounding a Path
//   path = star(5, step=2, d=100);
//   path2 = path_chamfer_and_rounding(path, closed=true, rounding=5);
//   stroke(path2, closed=true);
// Example(2D): Per-Corner Chamfering
//   path = star(5, step=2, d=100);
//   rs = [for (i=[0:1:4]) each 2*[i,i]];
//   path2 = path_chamfer_and_rounding(path, closed=true, rounding=rs);
//   stroke(path2, closed=true);
// Example(2D): Mixing Chamfers and Roundings
//   path = star(5, step=2, d=100);
//   chamfs = [for (i=[0:4]) each [5,0]];
//   rs = [for (i=[0:4]) each [0,10]];
//   path2 = path_chamfer_and_rounding(path, closed=true, chamfer=chamfs, rounding=rs);
//   stroke(path2, closed=true);
function path_chamfer_and_rounding(path, closed=true, chamfer, rounding) =
  let (
    path = deduplicate(path,closed=true),
    lp = len(path),
    chamfer = is_undef(chamfer)? repeat(0,lp) :
      is_vector(chamfer)? list_pad(chamfer,lp,0) :
      is_num(chamfer)? repeat(chamfer,lp) :
      assert(false, "Bad chamfer value."),
    rounding = is_undef(rounding)? repeat(0,lp) :
      is_vector(rounding)? list_pad(rounding,lp,0) :
      is_num(rounding)? repeat(rounding,lp) :
      assert(false, "Bad rounding value."),
    corner_paths = [
      for (i=(closed? [0:1:lp-1] : [1:1:lp-2])) let(
        p1 = select(path,i-1),
        p2 = select(path,i),
        p3 = select(path,i+1)
      )
      chamfer[i]  > 0? _corner_chamfer_path(p1, p2, p3, side=chamfer[i]) :
      rounding[i] > 0? _corner_roundover_path(p1, p2, p3, r=rounding[i]) :
      [p2]
    ],
    out = [
      if (!closed) path[0],
      for (i=(closed? [0:1:lp-1] : [1:1:lp-2])) let(
        p1 = select(path,i-1),
        p2 = select(path,i),
        crn1 = select(corner_paths,i-1),
        crn2 = corner_paths[i],
        l1 = norm(last(crn1)-p1),
        l2 = norm(crn2[0]-p2),
        needed = l1 + l2,
        seglen = norm(p2-p1),
        check = assert(seglen >= needed, str("Path segment ",i," is too short to fulfill rounding/chamfering for the adjacent corners."))
      ) each crn2,
      if (!closed) last(path)
    ]
  ) deduplicate(out);


function _corner_chamfer_path(p1, p2, p3, dist1, dist2, side, angle) = 
  let(
    v1 = unit(p1 - p2),
    v2 = unit(p3 - p2),
    n = vector_axis(v1,v2),
    ang = vector_angle(v1,v2),
    path = (is_num(dist1) && is_undef(dist2) && is_undef(side))? (
      // dist1 & optional angle
      assert(dist1 > 0)
      let(angle = default(angle,(180-ang)/2))
      assert(is_num(angle))
      assert(angle > 0 && angle < 180)
      let(
        pta = p2 + dist1*v1,
        a3 = 180 - angle - ang
      ) assert(a3>0, "Angle too extreme.")
      let(
        side = sin(angle) * dist1/sin(a3),
        ptb = p2 + side*v2
      ) [pta, ptb]
    ) : (is_undef(dist1) && is_num(dist2) && is_undef(side))? (
      // dist2 & optional angle
      assert(dist2 > 0)
      let(angle = default(angle,(180-ang)/2))
      assert(is_num(angle))
      assert(angle > 0 && angle < 180)
      let(
        ptb = p2 + dist2*v2,
        a3 = 180 - angle - ang
      ) assert(a3>0, "Angle too extreme.")
      let(
        side = sin(angle) * dist2/sin(a3),
        pta = p2 + side*v1
      ) [pta, ptb]
    ) : (is_undef(dist1) && is_undef(dist2) && is_num(side))? (
      // side & optional angle
      assert(side > 0)
      let(angle = default(angle,(180-ang)/2))
      assert(is_num(angle))
      assert(angle > 0 && angle < 180)
      let(
        a3 = 180 - angle - ang
      ) assert(a3>0, "Angle too extreme.")
      let(
        dist1 = sin(a3) * side/sin(ang),
        dist2 = sin(angle) * side/sin(ang),
        pta = p2 + dist1*v1,
        ptb = p2 + dist2*v2
      ) [pta, ptb]
    ) : (is_num(dist1) && is_num(dist2) && is_undef(side) && is_undef(side))? (
      // dist1 & dist2
      assert(dist1 > 0)
      assert(dist2 > 0)
      let(
        pta = p2 + dist1*v1,
        ptb = p2 + dist2*v2
      ) [pta, ptb]
    ) : (
      assert(false,"Bad arguments.")
    )
  ) path;


function _corner_roundover_path(p1, p2, p3, r, d) = 
  let(
    r = get_radius(r=r,d=d,dflt=undef),
    res = circle_2tangents(p1, p2, p3, r=r, tangents=true),
    cp = res[0],
    n = res[1],
    tp1 = res[2],
    ang = res[4]+res[5],
    steps = floor(segs(r)*ang/360+0.5),
    step = ang / steps,
    path = [for (i=[0:1:steps]) move(cp, p=rot(a=-i*step, v=n, p=tp1-cp))]
  ) path;



// Function: path_add_jitter()
// Topics: Paths
// See Also: jittered_poly(), subdivide_long_segments()
// Usage:
//   jpath = path_add_jitter(path, [dist], [closed=]);
// Description:
//   Adds tiny jitter offsets to collinear points in the given path so that they
//   are no longer collinear.  This is useful for preserving subdivision on long
//   straight segments, when making geometry with `polygon()`, for use with
//   `linear_exrtrude()` with a `twist()`.
// Arguments:
//   path = The path to add jitter to.
//   dist = The amount to jitter points by.  Default: 1/512 (0.00195)
//   ---
//   closed = If true, treat path like a closed polygon.  Default: true
// Example:
//   d = 100; h = 75; quadsize = 5;
//   path = pentagon(d=d);
//   spath = subdivide_long_segments(path, quadsize, closed=true);
//   jpath = path_add_jitter(spath, closed=true);
//   linear_extrude(height=h, twist=72, slices=h/quadsize)
//      polygon(jpath);
function path_add_jitter(path, dist=1/512, closed=true) =
    assert(is_path(path))
    assert(is_finite(dist))
    assert(is_bool(closed))
    [
        path[0],
        for (i=idx(path,s=1,e=closed?-1:-2)) let(
            n = line_normal([path[i-1],path[i]])
        ) path[i] + n * (collinear(select(path,i-1,i+1))? (dist * ((i%2)*2-1)) : 0),
        if (!closed) last(path)
    ];


// Function: path3d_spiral()
// Description:
//   Returns a 3D spiral path.
// Usage:
//   path3d_spiral(turns, h, n, r|d, [cp], [scale]);
// Arguments:
//   h = Height of spiral.
//   turns = Number of turns in spiral.
//   n = Number of spiral sides.
//   r = Radius of spiral.
//   d = Radius of spiral.
//   cp = Centerpoint of spiral. Default: `[0,0]`
//   scale = [X,Y] scaling factors for each axis.  Default: `[1,1]`
// Example(3D):
//   trace_path(path3d_spiral(turns=2.5, h=100, n=24, r=50), N=1, showpts=true);
function path3d_spiral(turns=3, h=100, n=12, r, d, cp=[0,0], scale=[1,1]) = let(
        rr=get_radius(r=r, d=d, dflt=100),
        cnt=floor(turns*n),
        dz=h/cnt
    ) [
        for (i=[0:1:cnt]) [
            rr * cos(i*360/n) * scale.x + cp.x,
            rr * sin(i*360/n) * scale.y + cp.y,
            i*dz
        ]
    ];


// Function: path_self_intersections()
// Usage:
//   isects = path_self_intersections(path, [eps]);
// Description:
//   Locates all self intersections of the given path.  Returns a list of intersections, where
//   each intersection is a list like [POINT, SEGNUM1, PROPORTION1, SEGNUM2, PROPORTION2] where
//   POINT is the coordinates of the intersection point, SEGNUMs are the integer indices of the
//   intersecting segments along the path, and the PROPORTIONS are the 0.0 to 1.0 proportions
//   of how far along those segments they intersect at.  A proportion of 0.0 indicates the start
//   of the segment, and a proportion of 1.0 indicates the end of the segment.
// Arguments:
//   path = The path to find self intersections of.
//   closed = If true, treat path like a closed polygon.  Default: true
//   eps = The epsilon error value to determine whether two points coincide.  Default: `EPSILON` (1e-9)
// Example(2D):
//   path = [
//       [-100,100], [0,-50], [100,100], [100,-100], [0,50], [-100,-100]
//   ];
//   isects = path_self_intersections(path, closed=true);
//   // isects == [[[-33.3333, 0], 0, 0.666667, 4, 0.333333], [[33.3333, 0], 1, 0.333333, 3, 0.666667]]
//   stroke(path, closed=true, width=1);
//   for (isect=isects) translate(isect[0]) color("blue") sphere(d=10);
function path_self_intersections(path, closed=true, eps=EPSILON) =
    let(
        path = cleanup_path(path, eps=eps),
        plen = len(path)
    ) [
        for (i = [0:1:plen-(closed?2:3)], j=[i+2:1:plen-(closed?1:2)]) let(
            a1 = path[i],
            a2 = path[(i+1)%plen],
            b1 = path[j],
            b2 = path[(j+1)%plen],
            isect =
                (max(a1.x, a2.x) < min(b1.x, b2.x))? undef :
                (min(a1.x, a2.x) > max(b1.x, b2.x))? undef :
                (max(a1.y, a2.y) < min(b1.y, b2.y))? undef :
                (min(a1.y, a2.y) > max(b1.y, b2.y))? undef :
                let(
                    c = a1-a2,
                    d = b1-b2,
                    denom = (c.x*d.y)-(c.y*d.x)
                ) abs(denom)<eps? undef :
                let(
                    e = a1-b1,
                    t = ((e.x*d.y)-(e.y*d.x)) / denom,
                    u = ((e.x*c.y)-(e.y*c.x)) / denom
                ) [a1+t*(a2-a1), t, u]
        ) if (
            (!closed || i!=0 || j!=plen-1) &&
            isect != undef &&
            isect[1]>=-eps && isect[1]<=1+eps &&
            isect[2]>=-eps && isect[2]<=1+eps
        ) [isect[0], i, isect[1], j, isect[2]]
    ];


// Function: split_path_at_self_crossings()
// Usage:
//   paths = split_path_at_self_crossings(path, [closed], [eps]);
// Description:
//   Splits a path into sub-paths wherever the original path crosses itself.
//   Splits may occur mid-segment, so new vertices will be created at the intersection points.
// Arguments:
//   path = The path to split up.
//   closed = If true, treat path as a closed polygon.  Default: true
//   eps = Acceptable variance.  Default: `EPSILON` (1e-9)
// Example(2D):
//   path = [ [-100,100], [0,-50], [100,100], [100,-100], [0,50], [-100,-100] ];
//   paths = split_path_at_self_crossings(path);
//   rainbow(paths) stroke($item, closed=false, width=2);
function split_path_at_self_crossings(path, closed=true, eps=EPSILON) =
    let(
        path = cleanup_path(path, eps=eps),
        isects = deduplicate(
            eps=eps,
            concat(
                [[0, 0]],
                sort([
                    for (
                        a = path_self_intersections(path, closed=closed, eps=eps),
                        ss = [ [a[1],a[2]], [a[3],a[4]] ]
                    ) if (ss[0] != undef) ss
                ]),
                [[len(path)-(closed?1:2), 1]]
            )
        )
    ) [
        for (p = pair(isects))
            let(
                s1 = p[0][0],
                u1 = p[0][1],
                s2 = p[1][0],
                u2 = p[1][1],
                section = path_subselect(path, s1, u1, s2, u2, closed=closed),
                outpath = deduplicate(eps=eps, section)
            )
            outpath
    ];


function _tag_self_crossing_subpaths(path, closed=true, eps=EPSILON) =
    let(
        subpaths = split_path_at_self_crossings(
            path, closed=closed, eps=eps
        )
    ) [
        for (subpath = subpaths) let(
            seg = select(subpath,0,1),
            mp = mean(seg),
            n = line_normal(seg) / 2048,
            p1 = mp + n,
            p2 = mp - n,
            p1in = point_in_polygon(p1, path) >= 0,
            p2in = point_in_polygon(p2, path) >= 0,
            tag = (p1in && p2in)? "I" : "O"
        ) [tag, subpath]
    ];


// Function: decompose_path()
// Usage:
//   splitpaths = decompose_path(path, [closed], [eps]);
// Description:
//   Given a possibly self-crossing path, decompose it into non-crossing paths that are on the perimeter
//   of the areas bounded by that path.
// Arguments:
//   path = The path to split up.
//   closed = If true, treat path like a closed polygon.  Default: true
//   eps = The epsilon error value to determine whether two points coincide.  Default: `EPSILON` (1e-9)
// Example(2D):
//   path = [
//       [-100,100], [0,-50], [100,100], [100,-100], [0,50], [-100,-100]
//   ];
//   splitpaths = decompose_path(path, closed=true);
//   rainbow(splitpaths) stroke($item, closed=true, width=3);
function decompose_path(path, closed=true, eps=EPSILON) =
    let(
        path = cleanup_path(path, eps=eps),
        tagged = _tag_self_crossing_subpaths(path, closed=closed, eps=eps),
        kept = [for (sub = tagged) if(sub[0] == "O") sub[1]],
        completed = [for (frag=kept) if(is_closed_path(frag)) frag],
        incomplete = [for (frag=kept) if(!is_closed_path(frag)) frag],
        defrag = _path_fast_defragment(incomplete, eps=eps),
        completed2 = assemble_path_fragments(defrag, eps=eps)
    ) concat(completed2,completed);


function _path_fast_defragment(fragments, eps=EPSILON, _done=[]) =
    len(fragments)==0? _done :
    let(
        path = fragments[0],
        endpt = last(path),
        extenders = [
            for (i = [1:1:len(fragments)-1]) let(
                test1 = approx(endpt,fragments[i][0],eps=eps),
                test2 = approx(endpt,last(fragments[i]),eps=eps)
            ) if (test1 || test2) (test1? i : -1)
        ]
    ) len(extenders) == 1 && extenders[0] >= 0? _path_fast_defragment(
        fragments=[
            concat(list_head(path),fragments[extenders[0]]),
            for (i = [1:1:len(fragments)-1])
                if (i != extenders[0]) fragments[i]
        ],
        eps=eps,
        _done=_done
    ) : _path_fast_defragment(
        fragments=[for (i = [1:1:len(fragments)-1]) fragments[i]],
        eps=eps,
        _done=concat(_done,[deduplicate(path,closed=true,eps=eps)])
    );


function _extreme_angle_fragment(seg, fragments, rightmost=true, eps=EPSILON) =
    !fragments? [undef, []] :
    let(
        delta = seg[1] - seg[0],
        segang = atan2(delta.y,delta.x),
        frags = [
            for (i = idx(fragments)) let(
                fragment = fragments[i],
                fwdmatch = approx(seg[1], fragment[0], eps=eps),
                bakmatch =  approx(seg[1], last(fragment), eps=eps)
            ) [
                fwdmatch,
                bakmatch,
                bakmatch? reverse(fragment) : fragment
            ]
        ],
        angs = [
            for (frag = frags)
                (frag[0] || frag[1])? let(
                    delta2 = frag[2][1] - frag[2][0],
                    segang2 = atan2(delta2.y, delta2.x)
                ) modang(segang2 - segang) : (
                    rightmost? 999 : -999
                )
        ],
        fi = rightmost? min_index(angs) : max_index(angs)
    ) abs(angs[fi]) > 360? [undef, fragments] : let(
        remainder = [for (i=idx(fragments)) if (i!=fi) fragments[i]],
        frag = frags[fi],
        foundfrag = frag[2]
    ) [foundfrag, remainder];


// Function: assemble_a_path_from_fragments()
// Usage:
//   assemble_a_path_from_fragments(subpaths);
// Description:
//   Given a list of paths, assembles them together into one complete closed polygon path, and
//   remainder fragments.  Returns [PATH, FRAGMENTS] where FRAGMENTS is the list of remaining
//   unused path fragments.
// Arguments:
//   fragments = List of paths to be assembled into complete polygons.
//   rightmost = If true, assemble paths using rightmost turns. Leftmost if false.
//   startfrag = The fragment to start with.  Default: 0
//   eps = The epsilon error value to determine whether two points coincide.  Default: `EPSILON` (1e-9)
function assemble_a_path_from_fragments(fragments, rightmost=true, startfrag=0, eps=EPSILON) =
    len(fragments)==0? _finished :
    let(
        path = fragments[startfrag],
        newfrags = [for (i=idx(fragments)) if (i!=startfrag) fragments[i]]
    ) is_closed_path(path, eps=eps)? (
        // starting fragment is already closed
        [path, newfrags]
    ) : let(
        // Find rightmost/leftmost continuation fragment
        seg = select(path,-2,-1),
        extrema = _extreme_angle_fragment(seg=seg, fragments=newfrags, rightmost=rightmost, eps=eps),
        foundfrag = extrema[0],
        remainder = extrema[1]
    ) is_undef(foundfrag)? (
        // No remaining fragments connect!  INCOMPLETE PATH!
        // Treat it as complete.
        [path, remainder]
    ) : is_closed_path(foundfrag, eps=eps)? (
        // Found fragment is already closed
        [foundfrag, concat([path], remainder)]
    ) : let(
        fragend = last(foundfrag),
        hits = [for (i = idx(path,e=-2)) if(approx(path[i],fragend,eps=eps)) i]
    ) hits? (
        let(
            // Found fragment intersects with initial path
            hitidx = last(hits),
            newpath = list_head(path,hitidx),
            newfrags = concat(len(newpath)>1? [newpath] : [], remainder),
            outpath = concat(slice(path,hitidx,-2), foundfrag)
        )
        [outpath, newfrags]
    ) : let(
        // Path still incomplete.  Continue building it.
        newpath = concat(path, list_tail(foundfrag)),
        newfrags = concat([newpath], remainder)
    )
    assemble_a_path_from_fragments(
        fragments=newfrags,
        rightmost=rightmost,
        eps=eps
    );


// Function: assemble_path_fragments()
// Usage:
//   assemble_path_fragments(subpaths);
// Description:
//   Given a list of paths, assembles them together into complete closed polygon paths if it can.
// Arguments:
//   fragments = List of paths to be assembled into complete polygons.
//   eps = The epsilon error value to determine whether two points coincide.  Default: `EPSILON` (1e-9)
function assemble_path_fragments(fragments, eps=EPSILON, _finished=[]) =
    len(fragments)==0? _finished :
    let(
        minxidx = min_index([
            for (frag=fragments) min(subindex(frag,0))
        ]),
        result_l = assemble_a_path_from_fragments(
            fragments=fragments,
            startfrag=minxidx,
            rightmost=false,
            eps=eps
        ),
        result_r = assemble_a_path_from_fragments(
            fragments=fragments,
            startfrag=minxidx,
            rightmost=true,
            eps=eps
        ),
        l_area = abs(polygon_area(result_l[0])),
        r_area = abs(polygon_area(result_r[0])),
        result = l_area < r_area? result_l : result_r,
        newpath = cleanup_path(result[0]),
        remainder = result[1],
        finished = concat(_finished, [newpath])
    ) assemble_path_fragments(
        fragments=remainder,
        eps=eps,
        _finished=finished
    );



// Section: 2D Modules


// Module: modulated_circle()
// Usage:
//   modulated_circle(r|d, sines);
// Description:
//   Creates a 2D polygon circle, modulated by one or more superimposed sine waves.
// Arguments:
//   r = Radius of the base circle. Default: 40
//   d = Diameter of the base circle.
//   sines = array of [amplitude, frequency] pairs or [amplitude, frequency, phase] triples, where the frequency is the number of times the cycle repeats around the circle.
// Example(2D):
//   modulated_circle(r=40, sines=[[3, 11], [1, 31]], $fn=6);
module modulated_circle(r, sines=[[1,1]], d)
{
    r = get_radius(r=r, d=d, dflt=40);
    assert(is_list(sines)
        && all([for(s=sines) is_vector(s,2) || is_vector(s,3)]),
        "sines must be given as a list of pairs or triples");
    sines_ = [for(s=sines) [s[0], s[1], len(s)==2 ? 0 : s[2]]];
    freqs = len(sines_)>0? [for (i=sines_) i[1]] : [5];
    points = [
        for (a = [0 : (360/segs(r)/max(freqs)) : 360])
            let(nr=r+sum_of_sines(a,sines_)) [nr*cos(a), nr*sin(a)]
    ];
    polygon(points);
}


// Module: jittered_poly()
// Topics: Extrusions
// See Also: path_add_jitter(), subdivide_long_segments()
// Usage:
//   jittered_poly(path, [dist]);
// Description:
//   Creates a 2D polygon shape from the given path in such a way that any extra
//   collinear points are not stripped out in the way that `polygon()` normally does.
//   This is useful for refining the mesh of a `linear_extrude()` with twist.
// Arguments:
//   path = The path to add jitter to.
//   dist = The amount to jitter points by.  Default: 1/512 (0.00195)
// Example:
//   d = 100; h = 75; quadsize = 5;
//   path = pentagon(d=d);
//   spath = subdivide_long_segments(path, quadsize, closed=true);
//   linear_extrude(height=h, twist=72, slices=h/quadsize)
//      jittered_poly(spath);
module jittered_poly(path, dist=1/512) {
    polygon(path_add_jitter(path, dist, closed=true));
}




// Section: 3D Modules


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
//   Takes a closed 2D polygon path, centered on the XY plane, and sweeps/extrudes it along a 3D spiral path.
//   of a given radius, height and twist.
// Arguments:
//   poly = Array of points of a polygon path, to be extruded.
//   h = height of the spiral to extrude along.
//   r = Radius of the spiral to extrude along. Default: 50
//   twist = number of degrees of rotation to spiral up along height.
//   ---
//   d = Diameter of the spiral to extrude along.
//   higbee = Length to taper thread ends over.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
//   center = If given, overrides `anchor`.  A true value sets `anchor=CENTER`, false sets `anchor=BOTTOM`.
// Example:
//   poly = [[-10,0], [-3,-5], [3,-5], [10,0], [0,-30]];
//   spiral_sweep(poly, h=200, r=50, twist=1080, $fn=36);
module spiral_sweep(poly, h, r, twist=360, higbee, center, r1, r2, d, d1, d2, higbee1, higbee2, anchor, spin=0, orient=UP) {
    poly = path3d(poly);
    anchor = get_anchor(anchor,center,BOT,BOT);
    r1 = get_radius(r1=r1, r=r, d1=d1, d=d, dflt=50);
    r2 = get_radius(r1=r2, r=r, d1=d2, d=d, dflt=50);
    sides = segs(max(r1,r2));
    steps = ceil(sides*(twist/360));
    higbee1 = first_defined([higbee1, higbee, 0]);
    higbee2 = first_defined([higbee2, higbee, 0]);
    higang1 = 360 * higbee1 / (2 * r1 * PI);
    higang2 = 360 * higbee2 / (2 * r2 * PI);
    higsteps1 = ceil(higang1/360*sides);
    higsteps2 = ceil(higang2/360*sides);
    assert(higang1 < twist/2);
    assert(higang2 < twist/2);

    function higsize(a) = lookup(a,[
        [-0.001,        0],
        for (x=[0.125:0.125:1]) [      x*higang1, pow(x,1/2)],
        for (x=[0.125:0.125:1]) [twist-x*higang2, pow(x,1/2)],
        [twist+0.001,   0]
    ]);

    us = [
        for (i=[0:higsteps1/10:higsteps1]) i,
        for (i=[higsteps1+1:1:steps-higsteps2-1]) i,
        for (i=[steps-higsteps2:higsteps2/10:steps]) i,
    ];
    zang = atan2(r2-r1,h);
    points = [
        for (p = us) let (
            u = p / steps,
            a = twist * u,
            hsc = higsize(a),
            r = lerp(r1,r2,u),
            mat = affine3d_zrot(a) *
                affine3d_translate([r, 0, h * (u-0.5)]) *
                affine3d_xrot(90) *
                affine3d_skew_xz(xa=zang) * 
                affine3d_scale([hsc,lerp(hsc,1,0.25),1]),
            pts = apply(mat, poly)
        ) pts
    ];

    vnf = vnf_vertex_array(
        points, col_wrap=true, caps=true, reverse=true,
        style=(abs(higbee1)+abs(higbee2))>0? "quincunx" : "alt"
    );

    attachable(anchor,spin,orient, r1=r1, r2=r2, l=h) {
        vnf_polyhedron(vnf, convexity=2*twist/360);
        children();
    }
}



// Module: path_extrude()
// Description:
//   Extrudes 2D children along a 3D path.  This may be slow.
// Arguments:
//   path = array of points for the bezier path to extrude along.
//   convexity = maximum number of walls a ran can pass through.
//   clipsize = increase if artifacts are left.  Default: 1000
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


// Module: path_spread()
//
// Description:
//   Uniformly spreads out copies of children along a path.  Copies are located based on path length.  If you specify `n` but not spacing then `n` copies will be placed
//   with one at path[0] of `closed` is true, or spanning the entire path from start to end if `closed` is false.
//   If you specify `spacing` but not `n` then copies will spread out starting from one at path[0] for `closed=true` or at the path center for open paths.
//   If you specify `sp` then the copies will start at `sp`.
//
// Usage:
//   path_spread(path), [n], [spacing], [sp], [rotate_children], [closed]) ...
//
// Arguments:
//   path = the path where children are placed
//   n = number of copies
//   spacing = space between copies
//   sp = if given, copies will start distance sp from the path start and spread beyond that point
//
// Side Effects:
//   `$pos` is set to the center of each copy
//   `$idx` is set to the index number of each copy.  In the case of closed paths the first copy is at `path[0]` unless you give `sp`.
//   `$dir` is set to the direction vector of the path at the point where the copy is placed.
//   `$normal` is set to the direction of the normal vector to the path direction that is coplanar with the path at this point
//
// Example(2D):
//   spiral = [for(theta=[0:360*8]) theta * [cos(theta), sin(theta)]]/100;
//   stroke(spiral,width=.25);
//   color("red") path_spread(spiral, n=100) circle(r=1);
// Example(2D):
//   circle = regular_ngon(n=64, or=10);
//   stroke(circle,width=1,closed=true);
//   color("green") path_spread(circle, n=7, closed=true) circle(r=1+$idx/3);
// Example(2D):
//   heptagon = regular_ngon(n=7, or=10);
//   stroke(heptagon, width=1, closed=true);
//   color("purple") path_spread(heptagon, n=9, closed=true) rect([0.5,3],anchor=FRONT);
// Example(2D): Direction at the corners is the average of the two adjacent edges
//   heptagon = regular_ngon(n=7, or=10);
//   stroke(heptagon, width=1, closed=true);
//   color("purple") path_spread(heptagon, n=7, closed=true) rect([0.5,3],anchor=FRONT);
// Example(2D):  Don't rotate the children
//   heptagon = regular_ngon(n=7, or=10);
//   stroke(heptagon, width=1, closed=true);
//   color("red") path_spread(heptagon, n=9, closed=true, rotate_children=false) rect([0.5,3],anchor=FRONT);
// Example(2D): Open path, specify `n`
//   sinwav = [for(theta=[0:360]) 5*[theta/180, sin(theta)]];
//   stroke(sinwav,width=.1);
//   color("red") path_spread(sinwav, n=5) rect([.2,1.5],anchor=FRONT);
// Example(2D): Open path, specify `n` and `spacing`
//   sinwav = [for(theta=[0:360]) 5*[theta/180, sin(theta)]];
//   stroke(sinwav,width=.1);
//   color("red") path_spread(sinwav, n=5, spacing=1) rect([.2,1.5],anchor=FRONT);
// Example(2D): Closed path, specify `n` and `spacing`, copies centered around circle[0]
//   circle = regular_ngon(n=64,or=10);
//   stroke(circle,width=.1,closed=true);
//   color("red") path_spread(circle, n=10, spacing=1, closed=true) rect([.2,1.5],anchor=FRONT);
// Example(2D): Open path, specify `spacing`
//   sinwav = [for(theta=[0:360]) 5*[theta/180, sin(theta)]];
//   stroke(sinwav,width=.1);
//   color("red") path_spread(sinwav, spacing=5) rect([.2,1.5],anchor=FRONT);
// Example(2D): Open path, specify `sp`
//   sinwav = [for(theta=[0:360]) 5*[theta/180, sin(theta)]];
//   stroke(sinwav,width=.1);
//   color("red") path_spread(sinwav, n=5, sp=18) rect([.2,1.5],anchor=FRONT);
// Example(2D):
//   wedge = arc(angle=[0,100], r=10, $fn=64);
//   difference(){
//     polygon(concat([[0,0]],wedge));
//     path_spread(wedge,n=5,spacing=3) fwd(.1) rect([1,4],anchor=FRONT);
//   }
// Example(Spin,VPD=115): 3d example, with children rotated into the plane of the path
//   tilted_circle = lift_plane([[0,0,0], [5,0,5], [0,2,3]],regular_ngon(n=64, or=12));
//   path_sweep(regular_ngon(n=16,or=.1),tilted_circle);
//   path_spread(tilted_circle, n=15,closed=true) {
//      color("blue") cyl(h=3,r=.2, anchor=BOTTOM);      // z-aligned cylinder
//      color("red") xcyl(h=10,r=.2, anchor=FRONT+LEFT); // x-aligned cylinder
//   }
// Example(Spin,VPD=115): 3d example, with rotate_children set to false
//   tilted_circle = lift_plane([[0,0,0], [5,0,5], [0,2,3]], regular_ngon(n=64, or=12));
//   path_sweep(regular_ngon(n=16,or=.1),tilted_circle);
//   path_spread(tilted_circle, n=25,rotate_children=false,closed=true) {
//      color("blue") cyl(h=3,r=.2, anchor=BOTTOM);       // z-aligned cylinder
//      color("red") xcyl(h=10,r=.2, anchor=FRONT+LEFT);  // x-aligned cylinder
//   }
module path_spread(path, n, spacing, sp=undef, rotate_children=true, closed=false)
{
    length = path_length(path,closed);
    distances =
        is_def(sp)? (   // Start point given
            is_def(n) && is_def(spacing)? count(n,sp,spacing) :
            is_def(n)? lerpn(sp, length, n) :
            list([sp:spacing:length])
        )
      : is_def(n) && is_undef(spacing)? lerpn(0,length,n,!closed) // N alone given
      : (      // No start point and spacing is given, N maybe given
        let(
            n = is_def(n)? n : floor(length/spacing)+(closed?0:1),
            ptlist = count(n,0,spacing),
            listcenter = mean(ptlist)
        ) closed?
            sort([for(entry=ptlist) posmod(entry-listcenter,length)]) :
            [for(entry=ptlist) entry + length/2-listcenter ]
    );
    distOK = is_def(n) || (min(distances)>=0 && max(distances)<=length);
    assert(distOK,"Cannot fit all of the copies");
    cutlist = path_cut_points(path, distances, closed, direction=true);
    planar = len(path[0])==2;
    if (true) for(i=[0:1:len(cutlist)-1]) {
        $pos = cutlist[i][0];
        $idx = i;
        $dir = rotate_children ? (planar?[1,0]:[1,0,0]) : cutlist[i][2];
        $normal = rotate_children? (planar?[0,1]:[0,0,1]) : cutlist[i][3];
        translate($pos) {
            if (rotate_children) {
                if(planar) {
                    rot(from=[0,1],to=cutlist[i][3]) children();
                } else {
                    multmatrix(affine3d_frame_map(x=cutlist[i][2], z=cutlist[i][3]))
                        children();
                }
            } else {
                children();
            }
        }
    }
}


// Function: path_cut_points()
//
// Usage:
//   cuts = path_cut_points(path, dists, [closed=], [direction=]);
//
// Description:
//   Cuts a path at a list of distances from the first point in the path.  Returns a list of the cut
//   points and indices of the next point in the path after that point.  So for example, a return
//   value entry of [[2,3], 5] means that the cut point was [2,3] and the next point on the path after
//   this point is path[5].  If the path is too short then path_cut_points returns undef.  If you set
//   `direction` to true then `path_cut_points` will also return the tangent vector to the path and a normal
//   vector to the path.  It tries to find a normal vector that is coplanar to the path near the cut
//   point.  If this fails it will return a normal vector parallel to the xy plane.  The output with
//   direction vectors will be `[point, next_index, tangent, normal]`.
//   .
//   If you give the very last point of the path as a cut point then the returned index will be
//   one larger than the last index (so it will not be a valid index).  If you use the closed
//   option then the returned index will be equal to the path length for cuts along the closing
//   path segment, and if you give a point equal to the path length you will get an
//   index of len(path)+1 for the index.  
//
// Arguments:
//   path = path to cut
//   dists = distances where the path should be cut (a list) or a scalar single distance
//   ---
//   closed = set to true if the curve is closed.  Default: false
//   direction = set to true to return direction vectors.  Default: false
//
// Example(NORENDER):
//   square=[[0,0],[1,0],[1,1],[0,1]];
//   path_cut_points(square, [.5,1.5,2.5]);   // Returns [[[0.5, 0], 1], [[1, 0.5], 2], [[0.5, 1], 3]]
//   path_cut_points(square, [0,1,2,3]);      // Returns [[[0, 0], 1], [[1, 0], 2], [[1, 1], 3], [[0, 1], 4]]
//   path_cut_points(square, [0,0.8,1.6,2.4,3.2], closed=true);  // Returns [[[0, 0], 1], [[0.8, 0], 1], [[1, 0.6], 2], [[0.6, 1], 3], [[0, 0.8], 4]]
//   path_cut_points(square, [0,0.8,1.6,2.4,3.2]);               // Returns [[[0, 0], 1], [[0.8, 0], 1], [[1, 0.6], 2], [[0.6, 1], 3], undef]
function path_cut_points(path, dists, closed=false, direction=false) =
    let(long_enough = len(path) >= (closed ? 3 : 2))
    assert(long_enough,len(path)<2 ? "Two points needed to define a path" : "Closed path must include three points")
    is_num(dists) ? path_cut_points(path, [dists],closed, direction)[0] :
    assert(is_vector(dists))
    assert(list_increasing(dists), "Cut distances must be an increasing list")
    let(cuts = _path_cut_points(path,dists,closed))
    !direction
       ? cuts
       : let(
             dir = _path_cuts_dir(path, cuts, closed),
             normals = _path_cuts_normals(path, cuts, dir, closed)
         )
         hstack(cuts, array_group(dir,1), array_group(normals,1));

// Main recursive path cut function
function _path_cut_points(path, dists, closed=false, pind=0, dtotal=0, dind=0, result=[]) =
    dind == len(dists) ? result :
    let(
        lastpt = len(result)==0? [] : last(result)[0],       // location of last cut point
        dpartial = len(result)==0? 0 : norm(lastpt-select(path,pind)),  // remaining length in segment
        nextpoint = dists[dind] < dpartial+dtotal  // Do we have enough length left on the current segment?
           ? [lerp(lastpt,select(path,pind),(dists[dind]-dtotal)/dpartial),pind] 
           : _path_cut_single(path, dists[dind]-dtotal-dpartial, closed, pind)
    ) 
    _path_cut_points(path, dists, closed, nextpoint[1], dists[dind],dind+1, concat(result, [nextpoint]));


// Search for a single cut point in the path
function _path_cut_single(path, dist, closed=false, ind=0, eps=1e-7) =
    // If we get to the very end of the path (ind is last point or wraparound for closed case) then
    // check if we are within epsilon of the final path point.  If not we're out of path, so we fail
    ind==len(path)-(closed?0:1) ?
       assert(dist<eps,"Path is too short for specified cut distance")
       [select(path,ind),ind+1]
    :let(d = norm(path[ind]-select(path,ind+1))) d > dist ?
        [lerp(path[ind],select(path,ind+1),dist/d), ind+1] :
        _path_cut_single(path, dist-d,closed, ind+1, eps);

// Find normal directions to the path, coplanar to local part of the path
// Or return a vector parallel to the x-y plane if the above fails
function _path_cuts_normals(path, cuts, dirs, closed=false) =
    [for(i=[0:len(cuts)-1])
        len(path[0])==2? [-dirs[i].y, dirs[i].x] : (
            let(
                plane = len(path)<3 ? undef :
                let(start = max(min(cuts[i][1],len(path)-1),2)) _path_plane(path, start, start-2)
            )
            plane==undef?
                unit([-dirs[i].y, dirs[i].x,0]) :
                unit(cross(dirs[i],cross(plane[0],plane[1])))
        )
    ];

// Scan from the specified point (ind) to find a noncoplanar triple to use
// to define the plane of the path.
function _path_plane(path, ind, i,closed) =
    i<(closed?-1:0) ? undef :
    !collinear(path[ind],path[ind-1], select(path,i))?
        [select(path,i)-path[ind-1],path[ind]-path[ind-1]] :
        _path_plane(path, ind, i-1);

// Find the direction of the path at the cut points
function _path_cuts_dir(path, cuts, closed=false, eps=1e-2) =
    [for(ind=[0:len(cuts)-1])
        let(
            zeros = path[0]*0,
            nextind = cuts[ind][1],
            nextpath = unit(select(path, nextind+1)-select(path, nextind),zeros),
            thispath = unit(select(path, nextind) - select(path,nextind-1),zeros),
            lastpath = unit(select(path,nextind-1) - select(path, nextind-2),zeros),
            nextdir =
                nextind==len(path) && !closed? lastpath :
                (nextind<=len(path)-2 || closed) && approx(cuts[ind][0], path[nextind],eps)
                   ? unit(nextpath+thispath)
              : (nextind>1 || closed) && approx(cuts[ind][0],select(path,nextind-1),eps)
                   ? unit(thispath+lastpath)
              :  thispath
        ) nextdir
    ];


// Function: path_cut()
// Topics: Paths
// See Also: path_cut_points()
// Usage:
//    path_list = path_cut(path, cutdist, [closed=]);
// Description:
//    Given a list of distances in `cutdist`, cut the path into
//    subpaths at those lengths, returning a list of paths.
//    If the input path is closed then the final path will include the
//    original starting point.  The list of cut distances must be
//    in ascending order.  If you repeat a distance you will get an
//    empty list in that position in the output.
// Arguments:
//   path = The original path to split.
//   cutdist = Distance or list of distances where path is cut
//   closed = If true, treat the path as a closed polygon.
// Example(2D):
//   path = circle(d=100);
//   segs = path_cut(path, [50, 200], closed=true);
//   rainbow(segs) stroke($item);
function path_cut(path,cutdist,closed) =
  is_num(cutdist) ? path_cut(path,[cutdist],closed) :
  assert(is_vector(cutdist))
  assert(last(cutdist)<path_length(path,closed=closed),"Cut distances must be smaller than the path length")
  assert(cutdist[0]>0, "Cut distances must be strictly positive")
  let(
      cutlist = path_cut_points(path,cutdist,closed=closed),
      cuts = len(cutlist)
  )
  [
      [ each list_head(path,cutlist[0][1]-1),
        if (!approx(cutlist[0][0], path[cutlist[0][1]-1])) cutlist[0][0]
      ],
      for(i=[0:1:cuts-2])
          cutlist[i][0]==cutlist[i+1][0] ? []
          :
          [ if (!approx(cutlist[i][0], select(path,cutlist[i][1]))) cutlist[i][0],
            each slice(path, cutlist[i][1], cutlist[i+1][1]-1),
            if (!approx(cutlist[i+1][0], select(path,cutlist[i+1][1]-1))) cutlist[i+1][0],
          ],
      [
        if (!approx(cutlist[cuts-1][0], select(path,cutlist[cuts-1][1]))) cutlist[cuts-1][0],
        each select(path,cutlist[cuts-1][1],closed ? 0 : -1)
      ]
  ];



// Input `data` is a list that sums to an integer. 
// Returns rounded version of input data so that every 
// entry is rounded to an integer and the sum is the same as
// that of the input.  Works by rounding an entry in the list
// and passing the rounding error forward to the next entry.
// This will generally distribute the error in a uniform manner. 
function _sum_preserving_round(data, index=0) =
    index == len(data)-1 ? list_set(data, len(data)-1, round(data[len(data)-1])) :
    let(
        newval = round(data[index]),
        error = newval - data[index]
    ) _sum_preserving_round(
        list_set(data, [index,index+1], [newval, data[index+1]-error]),
        index+1
    );


// Function: subdivide_path()
// Usage:
//   newpath = subdivide_path(path, [N|refine], method);
// Description:
//   Takes a path as input (closed or open) and subdivides the path to produce a more
//   finely sampled path.  The new points can be distributed proportional to length
//   (`method="length"`) or they can be divided up evenly among all the path segments
//   (`method="segment"`).  If the extra points don't fit evenly on the path then the
//   algorithm attempts to distribute them uniformly.  The `exact` option requires that
//   the final length is exactly as requested.  If you set it to `false` then the
//   algorithm will favor uniformity and the output path may have a different number of
//   points due to rounding error.
//   .
//   With the `"segment"` method you can also specify a vector of lengths.  This vector, 
//   `N` specfies the desired point count on each segment: with vector input, `subdivide_path`
//   attempts to place `N[i]-1` points on segment `i`.  The reason for the -1 is to avoid
//   double counting the endpoints, which are shared by pairs of segments, so that for
//   a closed polygon the total number of points will be sum(N).  Note that with an open
//   path there is an extra point at the end, so the number of points will be sum(N)+1. 
// Arguments:
//   path = path to subdivide
//   N = scalar total number of points desired or with `method="segment"` can be a vector requesting `N[i]-1` points on segment i.
//   refine = number of points to add each segment.
//   closed = set to false if the path is open.  Default: True
//   exact = if true return exactly the requested number of points, possibly sacrificing uniformity.  If false, return uniform point sample that may not match the number of points requested.  Default: True
//   method = One of `"length"` or `"segment"`.  If `"length"`, adds vertices evenly along the total path length.  If `"segment"`, adds points evenly among the segments.  Default: `"length"`
// Example(2D):
//   mypath = subdivide_path(square([2,2],center=true), 12);
//   move_copies(mypath)circle(r=.1,$fn=32);
// Example(2D):
//   mypath = subdivide_path(square([8,2],center=true), 12);
//   move_copies(mypath)circle(r=.2,$fn=32);
// Example(2D):
//   mypath = subdivide_path(square([8,2],center=true), 12, method="segment");
//   move_copies(mypath)circle(r=.2,$fn=32);
// Example(2D):
//   mypath = subdivide_path(square([2,2],center=true), 17, closed=false);
//   move_copies(mypath)circle(r=.1,$fn=32);
// Example(2D): Specifying different numbers of points on each segment
//   mypath = subdivide_path(hexagon(side=2), [2,3,4,5,6,7], method="segment");
//   move_copies(mypath)circle(r=.1,$fn=32);
// Example(2D): Requested point total is 14 but 15 points output due to extra end point
//   mypath = subdivide_path(pentagon(side=2), [3,4,3,4], method="segment", closed=false);
//   move_copies(mypath)circle(r=.1,$fn=32);
// Example(2D): Since 17 is not divisible by 5, a completely uniform distribution is not possible. 
//   mypath = subdivide_path(pentagon(side=2), 17);
//   move_copies(mypath)circle(r=.1,$fn=32);
// Example(2D): With `exact=false` a uniform distribution, but only 15 points
//   mypath = subdivide_path(pentagon(side=2), 17, exact=false);
//   move_copies(mypath)circle(r=.1,$fn=32);
// Example(2D): With `exact=false` you can also get extra points, here 20 instead of requested 18
//   mypath = subdivide_path(pentagon(side=2), 18, exact=false);
//   move_copies(mypath)circle(r=.1,$fn=32);
// Example(FlatSpin,VPD=15,VPT=[0,0,1.5]): Three-dimensional paths also work
//   mypath = subdivide_path([[0,0,0],[2,0,1],[2,3,2]], 12);
//   move_copies(mypath)sphere(r=.1,$fn=32);
function subdivide_path(path, N, refine, closed=true, exact=true, method="length") =
    assert(is_path(path))
    assert(method=="length" || method=="segment")
    assert(num_defined([N,refine]),"Must give exactly one of N and refine")
    let(
        N = !is_undef(N)? N :
            !is_undef(refine)? len(path) * refine :
            undef
    )
    assert((is_num(N) && N>0) || is_vector(N),"Parameter N to subdivide_path must be postive number or vector")
    let(
        count = len(path) - (closed?0:1), 
        add_guess = method=="segment"? (
                is_list(N)? (
                    assert(len(N)==count,"Vector parameter N to subdivide_path has the wrong length")
                    add_scalar(N,-1)
                ) : repeat((N-len(path)) / count, count)
            ) : // method=="length"
            assert(is_num(N),"Parameter N to subdivide path must be a number when method=\"length\"")
            let(
                path_lens = concat(
                    [ for (i = [0:1:len(path)-2]) norm(path[i+1]-path[i]) ],
                    closed? [norm(path[len(path)-1]-path[0])] : []
                ),
                add_density = (N - len(path)) / sum(path_lens)
            )
            path_lens * add_density,
        add = exact? _sum_preserving_round(add_guess) :
            [for (val=add_guess) round(val)]
    ) concat(
        [
            for (i=[0:1:count]) each [
                for(j=[0:1:add[i]])
                lerp(path[i],select(path,i+1), j/(add[i]+1))
            ]
        ],
        closed? [] : [last(path)]
    );


// Function: path_length_fractions()
// Usage:
//   fracs = path_length_fractions(path, [closed]);
// Description:
//    Returns the distance fraction of each point in the path along the path, so the first
//    point is zero and the final point is 1.  If the path is closed the length of the output
//    will have one extra point because of the final connecting segment that connects the last
//    point of the path to the first point.
function path_length_fractions(path, closed=false) =
    assert(is_path(path))
    assert(is_bool(closed))
    let(
        lengths = [
            0,
            for (i=[0:1:len(path)-(closed?1:2)])
                norm(select(path,i+1)-path[i])
        ],
        partial_len = cumsum(lengths),
        total_len = last(partial_len)
    ) partial_len / total_len;


// Function: resample_path()
// Usage:
//   newpath = resample_path(path, N|spacing, [closed]);
// Description:
//   Compute a uniform resampling of the input path.  If you specify `N` then the output path will have N
//   points spaced uniformly (by linear interpolation along the input path segments).  The only points of the
//   input path that are guaranteed to appear in the output path are the starting and ending points.
//   If you specify `spacing` then the length you give will be rounded to the nearest spacing that gives
//   a uniform sampling of the path and the resulting uniformly sampled path is returned.
//   Note that because this function operates on a discrete input path the quality of the output depends on
//   the sampling of the input.  If you want very accurate output, use a lot of points for the input.
// Arguments:
//   path = path to resample
//   N = Number of points in output
//   spacing = Approximate spacing desired
//   closed = set to true if path is closed.  Default: false
function resample_path(path, N, spacing, closed=false) =
   assert(is_path(path))
   assert(num_defined([N,spacing])==1,"Must define exactly one of N and spacing")
   assert(is_bool(closed))
   let(
       length = path_length(path,closed),
       // In the open path case decrease N by 1 so that we don't try to get
       // path_cut to return the endpoint (which might fail due to rounding)
       // Add last point later
       N = is_def(N) ? N-(closed?0:1) : round(length/spacing),
       distlist = lerpn(0,length,N,false), 
       cuts = path_cut_points(path, distlist, closed=closed)
   )
   [ each subindex(cuts,0),
     if (!closed) last(path)     // Then add last point here
   ];



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
