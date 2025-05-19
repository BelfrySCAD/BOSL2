//////////////////////////////////////////////////////////////////////
// LibFile: paths.scad
//   A `path` is a list of points of the same dimensions, usually 2D or 3D, that can
//   be connected together to form a sequence of line segments or a polygon.
//   A `region` is a list of paths that represent polygons, and the functions
//   in this file work on paths and also 1-regions, which are regions
//   that include exactly one path.  When you pass a 1-region to a function, the default
//   value for `closed` is always `true` because regions represent polygons.  
//   Capabilities include computing length of paths, computing
//   path tangents and normals, resampling of paths, and cutting paths up into smaller paths.  
// Includes:
//   include <BOSL2/std.scad>
// FileGroup: Advanced Modeling
// FileSummary: Operations on paths: length, resampling, tangents, splitting into subpaths
// FileFootnotes: STD=Included in std.scad
//////////////////////////////////////////////////////////////////////

// Section: Utility Functions
// Definitions:
//   Point|Points = A list of numbers, also called a vector.  Usually has length 2 or 3 to represent points in the place on points in space.  
//   Pointlist|Pointlists|Point List|Point Lists = An unordered list of {{points}}.
//   Path|Paths = An ordered list of two or more {{points}} specifying a path through space.  Usually points are 2D.  
//   Polygon|Polygons = A {{path}}, usually 2D, that describes a polygon by asuming that the first and last point are connected.

// Function: is_path()
// Synopsis: Returns True if 'list' is a {{path}}.
// Topics: Paths
// See Also: is_region(), is_vnf()
// Usage:
//   is_path(list, [dim], [fast])
// Description:
//   Returns true if `list` is a {{path}}.  A path is a list of two or more numeric vectors (AKA {{points}}).
//   All vectors must of the same size, and may only contain numbers that are not inf or nan.
//   By default the vectors in a path must be 2D or 3D.  Set the `dim` parameter to specify a list
//   of allowed dimensions, or set it to `undef` to allow any dimension.  (Note that this function
//   returns `false` on 1-regions.)  
// Example:
//   bool1 = is_path([[3,4],[5,6]]);    // Returns true
//   bool2 = is_path([[3,4]]);          // Returns false
//   bool3 = is_path([[3,4],[4,5]],2);  // Returns true
//   bool4 = is_path([[3,4,3],[5,4,5]],2);  // Returns false
//   bool5 = is_path([[3,4,3],[5,4,5]],2);  // Returns false
//   bool6 = is_path([[3,4,5],undef,[4,5,6]]);  // Returns false
//   bool7 = is_path([[3,5],[undef,undef],[4,5]]);  // Returns false
//   bool8 = is_path([[3,4],[5,6],[5,3]]);     // Returns true
//   bool9 = is_path([3,4,5,6,7,8]);           // Returns false
//   bool10 = is_path([[3,4],[5,6]], dim=[2,3]);// Returns true
//   bool11 = is_path([[3,4],[5,6]], dim=[1,3]);// Returns false
//   bool12 = is_path([[3,4],"hello"], fast=true); // Returns true
//   bool13 = is_path([[3,4],[3,4,5]]);            // Returns false
//   bool14 = is_path([[1,2,3,4],[2,3,4,5]]);      // Returns false
//   bool15 = is_path([[1,2,3,4],[2,3,4,5]],undef);// Returns true
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

// Function: is_1region()
// Synopsis: Returns true if {{path}} is a {{region}} with one component.
// Topics: Paths, Regions
// See Also: force_path()
// Usage:
//   bool = is_1region(path, [name])
// Description:
//   If `path` is a {{region}} with one component (a single-{{path}} region, or 1-region) then returns true.  If path is a region with more components
//   then display an error message about the parameter `name` requiring a path or a single component region.  If the input
//   is not a region then return false.  This function helps path functions accept 1-regions.
// Arguments:
//   path = input to process
//   name = name of parameter to use in error message.  Default: "path"
function is_1region(path, name="path") = 
     !is_region(path)? false
    :assert(len(path)==1,str("Parameter \"",name,"\" must be a path or singleton region, but is a multicomponent region"))
     true;


// Function: force_path()
// Synopsis: Checks that path is a region with one component.
// SynTags: Path
// Topics: Paths, Regions
// See Also: is_1region()
// Usage:
//   outpath = force_path(path, [name])
// Description:
//   If `path` is a {{region}} with one component (a single-{{path}} region, or 1-region) then returns that component as a path.
//   If `path` is a region with more components then displays an error message about the parameter
//   `name` requiring a path or a single component region.  If the input is not a region then
//   returns the input without any checks.  This function helps path functions accept 1-regions.
// Arguments:
//   path = input to process
//   name = name of parameter to use in error message.  Default: "path"
function force_path(path, name="path") =
   is_region(path) ?
       assert(len(path)==1, str("Parameter \"",name,"\" must be a path or singleton region, but is a multicomponent region"))
       path[0]
   : path;


/// Internal Function: _path_select()
/// Usage:
///   _path_select(path,s1,u1,s2,u2,[closed]):
/// Description:
///   Returns a portion of a path, from between the `u1` part of segment `s1`, to the `u2` part of
///   segment `s2`.  Both `u1` and `u2` are values between 0.0 and 1.0, inclusive, where 0 is the start
///   of the segment, and 1 is the end.  Both `s1` and `s2` are integers, where 0 is the first segment.
/// Arguments:
///   path = The path to get a section of.
///   s1 = The number of the starting segment.
///   u1 = The proportion along the starting segment, between 0.0 and 1.0, inclusive.
///   s2 = The number of the ending segment.
///   u2 = The proportion along the ending segment, between 0.0 and 1.0, inclusive.
///   closed = If true, treat path as a closed polygon.
function _path_select(path, s1, u1, s2, u2, closed=false) =
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



// Function: path_merge_collinear()
// Synopsis: Removes unnecessary points from a path.
// SynTags: Path
// Topics: Paths, Regions
// Description:
//   Takes a {{path}} and removes unnecessary sequential collinear {{points}}.  Note that when `closed=true` either of the path
//   endpoints may be removed.  
// Usage:
//   path_merge_collinear(path, [eps])
// Arguments:
//   path = A path of any dimension or a 1-region
//   closed = treat as closed polygon.  Default: false
//   eps = Largest positional variance allowed.  Default: `EPSILON` (1-e9)
function path_merge_collinear(path, closed, eps=EPSILON) =
    is_1region(path) ? path_merge_collinear(path[0], default(closed,true), eps) :
    let(closed=default(closed,false))
    assert(is_bool(closed))
    assert( is_path(path), "Invalid path in path_merge_collinear." )
    assert( is_undef(eps) || (is_finite(eps) && (eps>=0) ), "Invalid tolerance." )
    len(path)<=2 ? path :
    let(path = deduplicate(path, closed=closed))
    [
      if(!closed) path[0],
      for(triple=triplet(path,wrap=closed))
        if (!is_collinear(triple,eps=eps)) triple[1],
      if(!closed) last(path)
    ];


// Section: Path length calculation


// Function: path_length()
// Synopsis: Returns the path length.
// Topics: Paths
// See Also: path_segment_lengths(), path_length_fractions()
// Usage:
//   path_length(path,[closed])
// Description:
//   Returns the length of the given {{path}}.
// Arguments:
//   path = Path of any dimension or 1-region. 
//   closed = true if the path is closed.  Default: false
// Example:
//   path = [[0,0], [5,35], [60,-25], [80,0]];
//   echo(path_length(path));
function path_length(path,closed) =
    is_1region(path) ? path_length(path[0], default(closed,true)) :
    assert(is_path(path), "Invalid path in path_length")
    let(closed=default(closed,false))
    assert(is_bool(closed))
    len(path)<2? 0 :
    sum([for (i = [0:1:len(path)-2]) norm(path[i+1]-path[i])])+(closed?norm(path[len(path)-1]-path[0]):0);


// Function: path_segment_lengths()
// Synopsis: Returns a list of the lengths of segments in a {{path}}.
// Topics: Paths
// See Also: path_length(), path_length_fractions()
// Usage:
//   path_segment_lengths(path,[closed])
// Description:
//   Returns list of the length of each segment in a path
// Arguments:
//   path = path in any dimension or 1-region
//   closed = true if the path is closed.  Default: false
function path_segment_lengths(path, closed) =
    is_1region(path) ? path_segment_lengths(path[0], default(closed,true)) :
    let(closed=default(closed,false))
    assert(is_path(path),"Invalid path in path_segment_lengths.")
    assert(is_bool(closed))
    [
        for (i=[0:1:len(path)-2]) norm(path[i+1]-path[i]),
        if (closed) norm(path[0]-last(path))
    ]; 


// Function: path_length_fractions()
// Synopsis: Returns the fractional distance of each point along the length of a path.
// Topics: Paths
// See Also: path_length(), path_segment_lengths()
// Usage:
//   fracs = path_length_fractions(path, [closed]);
// Description:
//    Returns the distance fraction of each point in the {{path}} along the path, so the first
//    point is zero and the final point is 1.  If the path is closed the length of the output
//    will have one extra point because of the final connecting segment that connects the last
//    point of the path to the first point.
// Arguments:
//    path = path in any dimension or a 1-region
//    closed = set to true if path is closed.  Default: false
function path_length_fractions(path, closed) =
    is_1region(path) ? path_length_fractions(path[0], default(closed,true)):
    let(closed=default(closed, false))
    assert(is_path(path))
    assert(is_bool(closed))
    let(
        lengths = [
            0,
            each path_segment_lengths(path,closed)
        ],
        partial_len = cumsum(lengths),
        total_len = last(partial_len)
    )
    partial_len / total_len;



/// Internal Function: _path_self_intersections()
/// Usage:
///   isects = _path_self_intersections(path, [closed], [eps]);
/// Description:
///   Locates all self intersection {{points}} of the given {{path}}.  Returns a list of intersections, where
///   each intersection is a list like [POINT, SEGNUM1, PROPORTION1, SEGNUM2, PROPORTION2] where
///   POINT is the coordinates of the intersection point, SEGNUMs are the integer indices of the
///   intersecting segments along the path, and the PROPORTIONS are the 0.0 to 1.0 proportions
///   of how far along those segments they intersect at.  A proportion of 0.0 indicates the start
///   of the segment, and a proportion of 1.0 indicates the end of the segment.
///   .
///   Note that this function does not return self-intersecting segments, only the points
///   where non-parallel segments intersect.  
/// Arguments:
///   path = The path to find self intersections of.
///   closed = If true, treat path like a closed polygon.  Default: true
///   eps = The epsilon error value to determine whether two points coincide.  Default: `EPSILON` (1e-9)
/// Example(2D):
///   path = [
///       [-100,100], [0,-50], [100,100], [100,-100], [0,50], [-100,-100]
///   ];
///   isects = _path_self_intersections(path, closed=true);
///   // isects == [[[-33.3333, 0], 0, 0.666667, 4, 0.333333], [[33.3333, 0], 1, 0.333333, 3, 0.666667]]
///   stroke(path, closed=true, width=1);
///   for (isect=isects) translate(isect[0]) color("blue") sphere(d=10);
function _path_self_intersections(path, closed=true, eps=EPSILON) =
    let(
        path = closed ? list_wrap(path,eps=eps) : path,
        plen = len(path)
    )
    [ for (i = [0:1:plen-3]) let(
          a1 = path[i],
          a2 = path[i+1], 
          seg_normal = unit([-(a2-a1).y, (a2-a1).x],[0,0]),
          vals = path*seg_normal,
          ref  = a1*seg_normal,
            // The value of vals[j]-ref is positive if vertex j is one one side of the
            // line [a1,a2] and negative on the other side. Only a segment with opposite
            // signs at its two vertices can have an intersection with segment
            // [a1,a2]. The variable signals is zero when abs(vals[j]-ref) is less than
            // eps and the sign of vals[j]-ref otherwise.  
          signals = [for(j=[i+2:1:plen-(i==0 && closed? 2: 1)]) 
                        abs(vals[j]-ref) <  eps ? 0 : sign(vals[j]-ref) ]
        )
        if(max(signals)>=0 && min(signals)<=0 ) // some remaining edge intersects line [a1,a2]
        for(j=[i+2:1:plen-(i==0 && closed? 3: 2)])
            if( signals[j-i-2]*signals[j-i-1]<=0 ) let( // segm [b1,b2] intersects line [a1,a2]
                b1 = path[j],
                b2 = path[j+1],
                isect = _general_line_intersection([a1,a2],[b1,b2],eps=eps) 
            )
            if (isect 
                && isect[1]>=-eps
                && isect[1]<= 1+eps
                && isect[2]>= -eps 
                && isect[2]<= 1+eps)
                [isect[0], i, isect[1], j, isect[2]]
    ];

// Section: Resampling - changing the number of points in a path


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
// Synopsis: Subdivides a path to produce a more finely sampled path.
// SynTags: Path
// Topics: Paths, Path Subdivision
// See Also: subdivide_and_slice(), resample_path(), jittered_poly()
// Usage:
//   newpath = subdivide_path(path, n|refine=|maxlen=, [method=], [closed=], [exact=]);
// Description:
//   Takes a {{path}} as input (closed or open) and subdivides the path to produce a more
//   finely sampled path.  You control the subdivision process by using the `maxlen` arg
//   to specify a maximum segment length, or by specifying `n` or `refine`, which request
//   a certain {{point}} count in the output.
//   .
//   You can specify the point count using the `n` option, where
//   you give the number of points you want in the output, or you can use
//   the `refine` option, where you specify a resampling factor.  If `refine=3` then
//   the number of points would increase by a factor of three, so a four point square would
//   have 12 points after subdivision.  With point-count subdivision, the new points can be distributed
//   proportional to length (`method="length"`), which is the default, or they can be divided up evenly among all the path segments
//   (`method="segment"`).  If the extra points don't fit evenly on the path then the
//   algorithm attempts to distribute them as uniformly as possible, but the result may be uneven.
//   The `exact` option, which is true by default, requires that the final point count is
//   exactly as requested.  For example, if you subdivide a four point square and request `n=13` then one edge will have
//   an extra point compared to the others.  
//   If you set `exact=false` then the
//   algorithm will favor uniformity and the output path may have a different number of
//   points than you requested, but the sampling will be uniform.   In our example of the
//   square with `n=13`, you will get only 12 points output, with the same number of points on each edge.
//   .
//   The points are always distributed uniformly on each segment.  The `method="length"` option does
//   means that the number of points on a segment is based on its length, but the points are still
//   distributed uniformly on each segment, independent of the other segments.  
//   With the `"segment"` method you can also give `n` as a vector of counts.  This 
//   specifies the desired point count on each segment: with vector valued `n` the `subdivide_path`
//   function places `n[i]-1` points on segment `i`.  The reason for the -1 is to avoid
//   double counting the endpoints, which are shared by pairs of segments, so that for
//   a closed polygon the total number of points will be sum(n).  Note that with an open
//   path there is an extra point at the end, so the number of points will be sum(n)+1.
//   .
//   If you use the `maxlen` option then you specify the maximum length segment allowed in the output.
//   Each segment is subdivided into the largest number of segments meeting your requirement.  As above,
//   the sampling is uniform on each segment, independent of the other segments.  With the `maxlen` option
//   you cannot specify `method` or `exact`.    
// Arguments:
//   path = path in any dimension or a 1-region
//   n = scalar total number of points desired or with `method="segment"` can be a vector requesting `n[i]-1` new points added to segment i.
//   ---
//   refine = increase total number of points by this factor (Specify only one of n, refine and maxlen)
//   maxlen = maximum length segment in the output (Specify only one of n, refine and maxlen)
//   closed = set to false if the path is open.  Default: True
//   exact = if true return exactly the requested number of points, possibly sacrificing uniformity.  If false, return uniform point sample that may not match the number of points requested.  (Not allowed with maxlen.) Default: true
//   method = One of `"length"` or `"segment"`.  If `"length"`, adds vertices in proportion to segment length, so short segments get fewer points.  If `"segment"`, add points evenly among the segments, so all segments get the same number of points.  (Not allowed with maxlen.) Default: `"length"`
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
// Example(2D): Using refine in this example multiplies the point count by 3 by adding 2 points to each edge
//   mypath = subdivide_path(pentagon(side=2), refine=3);
//   move_copies(mypath)circle(r=.1,$fn=32);
// Example(2D): But note that refine doesn't distribute evenly by segment unless you change the method.  with the default method set to `"length"`, the points are distributed with more on the long segments in this example using refine.  
//   mypath = subdivide_path(square([8,2],center=true), refine=3);
//   move_copies(mypath)circle(r=.2,$fn=32);
// Example(2D): In this example with maxlen, every side gets a different number of new points
//   path = [[0,0],[0,4],[10,6],[10,0]];
//   spath = subdivide_path(path, maxlen=2, closed=true);
//   move_copies(spath) circle(r=.25,$fn=12);
// Example(FlatSpin,VPD=15,VPT=[0,0,1.5]): Three-dimensional paths also work
//   mypath = subdivide_path([[0,0,0],[2,0,1],[2,3,2]], 12);
//   move_copies(mypath)sphere(r=.1,$fn=32);
function subdivide_path(path, n, refine, maxlen, closed=true, exact, method) =
    let(path = force_path(path))
    assert(is_path(path))
    assert(num_defined([n,refine,maxlen]),"Must give exactly one of n, refine, and maxlen")
    refine==1 || n==len(path) ? path :
    is_def(maxlen) ?
        assert(is_undef(method), "Cannot give method with maxlen")
        assert(is_undef(exact), "Cannot give exact with maxlen")
        [
         for (p=pair(path,closed))
           let(steps = ceil(norm(p[1]-p[0])/maxlen))
           each lerpn(p[0], p[1], steps, false),
         if (!closed) last(path)
        ]               
    :
    let(
        exact = default(exact, true),
        method = default(method, "length")
    )
    assert(method=="length" || method=="segment")
    let(
        n = !is_undef(n)? n :
            !is_undef(refine)? len(path) * refine :
            undef
    )
    assert((is_num(n) && n>0) || is_vector(n),"Parameter n to subdivide_path must be postive number or vector")
    let(
        count = len(path) - (closed?0:1), 
        add_guess = method=="segment"?
                       (
                          is_list(n)
                          ? assert(len(n)==count,"Vector parameter n to subdivide_path has the wrong length")
                            add_scalar(n,-1)
                          : repeat((n-len(path)) / count, count)
                       )
                  : // method=="length"
                    assert(is_num(n),"Parameter n to subdivide path must be a number when method=\"length\"")
                    let(
                        path_lens = path_segment_lengths(path,closed),
                        add_density = (n - len(path)) / sum(path_lens)
                    )
                    path_lens * add_density,
        add = exact? _sum_preserving_round(add_guess)
                   : [for (val=add_guess) round(val)]
    )
    [
        for (i=[0:1:count-1]) 
           each lerpn(path[i],select(path,i+1), 1+add[i],endpoint=false),
        if (!closed) last(path)
    ];




// Function: resample_path()
// Synopsis: Returns an equidistant set of points along a path.
// SynTags: Path
// Topics: Paths
// See Also: subdivide_path()
// Usage:
//   newpath = resample_path(path, n|spacing=, [closed=]);
// Description:
//   Compute a uniform resampling of the input {{path}}.  If you specify `n` then the output path will have n
//   {{points}} spaced uniformly (by linear interpolation along the input path segments).  The only points of the
//   input path that are guaranteed to appear in the output path are the starting and ending points, and any
//   points that have an angular deflection of at least the number of degrees given in `keep_corners`.
//   If you specify `spacing` then the length you give will be rounded to the nearest spacing that gives
//   a uniform sampling of the path and the resulting uniformly sampled path is returned.
//   Note that because this function operates on a discrete input path the quality of the output depends on
//   the sampling of the input.  If you want very accurate output, use a lot of points for the input.
// Arguments:
//   path = path in any dimension or a 1-region
//   n = Number of points in output
//   ---
//   spacing = Approximate spacing desired
//   keep_corners = If given a scalar, path vertices with deflection angle greater than this are preserved in the output.
//   closed = set to true if path is closed.  Default: true
// Example(2D):  Subsampling lots of points from a smooth curve
//   path = xscale(2,circle($fn=250, r=10));
//   sampled = resample_path(path, 16);
//   stroke(path);
//   color("red")move_copies(sampled) circle($fn=16);
// Example(2D): Specified spacing is rounded to make a uniform sampling
//   path = xscale(2,circle($fn=250, r=10));
//   sampled = resample_path(path, spacing=17);
//   stroke(path);
//   color("red")move_copies(sampled) circle($fn=16);
// Example(2D): Notice that the corners are excluded.
//   path = square(20);
//   sampled = resample_path(path, spacing=6);
//   stroke(path,closed=true);
//   color("red")move_copies(sampled) circle($fn=16);
// Example(2D): Forcing preservation of corners.
//   path = square(20);
//   sampled = resample_path(path, spacing=6, keep_corners=90);
//   stroke(path,closed=true);
//   color("red")move_copies(sampled) circle($fn=16);
// Example(2D): Closed set to false
//   path = square(20);
//   sampled = resample_path(path, spacing=6,closed=false);
//   stroke(path);
//   color("red")move_copies(sampled) circle($fn=16);

function resample_path(path, n, spacing, keep_corners, closed=true) =
    let(path = force_path(path))
    assert(is_path(path))
    assert(num_defined([n,spacing])==1,"Must define exactly one of n and spacing")
    assert(n==undef || (is_integer(n) && n>0))
    assert(spacing==undef || (is_finite(spacing) && spacing>0))
    assert(is_bool(closed))
    let(
        corners = is_undef(keep_corners)
          ? [0, len(path)-(closed?0:1)]
          : [
                0,
                for (i = [1:1:len(path)-(closed?1:2)])
                    let( ang = abs(modang(vector_angle(select(path,i-1,i+1))-180)) )
                    if (ang >= keep_corners) i,
                len(path)-(closed?0:1),
            ],
        pcnt = len(path),
        plen = path_length(path, closed=closed),
        subpaths = [ for (p = pair(corners)) [for(i = [p.x:1:p.y]) path[i%pcnt]] ],
        n = is_undef(n)? undef : closed? n+1 : n
    )
    assert(n==undef || n >= len(corners), "There are nore than `n=` corners whose angle is greater than `keep_corners=`.")
    let(
        lens = [for (subpath = subpaths) path_length(subpath)],
        part_ns = is_undef(n)
          ? [for (i=idx(subpaths)) max(1,round(lens[i]/spacing)-1)]
          : let(
                ccnt = len(corners),
                parts = [for (l=lens) (n-ccnt) * l/plen]
            )
            _sum_preserving_round(parts),
        out = [
            for (i = idx(subpaths))
                let(
                    subpath = subpaths[i],
                    splen = lens[i],
                    pn = part_ns[i] + 1,
                    distlist = lerpn(0, splen, pn, false),
                    cuts = path_cut_points(subpath, distlist, closed=false)
                )
                each column(cuts,0),
            if (!closed) last(path)
        ]
    ) out;


// Section: Path Geometry

// Function: is_path_simple()
// Synopsis: Returns true if a {{path}} has no self intersections.
// Topics: Paths
// See Also: is_path()
// Usage:
//   bool = is_path_simple(path, [closed], [eps]);
// Description:
//   Returns true if the given 2D {{path}} is simple, meaning that it has no self-intersections.
//   Repeated {{points}} are not considered self-intersections: a path with such points can
//   still be simple.  
//   If closed is set to true then treat the path as a polygon.
// Arguments:
//   path = 2D path or 1-region
//   closed = set to true to treat path as a polygon.  Default: false
//   eps = Epsilon error value used for determine if points coincide.  Default: `EPSILON` (1e-9)
function is_path_simple(path, closed, eps=EPSILON) =
    is_1region(path) ? is_path_simple(path[0], default(closed,true), eps) :
    let(closed=default(closed,false))
    assert(is_path(path, 2),"Must give a 2D path")
    assert(is_bool(closed))
    let(
        path = deduplicate(path,closed=closed,eps=eps)
    )
    // check for path reversals
    [for(i=[0:1:len(path)-(closed?2:3)])
         let(v1=path[i+1]-path[i],
             v2=select(path,i+2)-path[i+1],
             normv1 = norm(v1),
             normv2 = norm(v2)
             )
         if (approx(v1*v2/normv1/normv2,-1)) 1
    ]  == [] 
    &&
    _path_self_intersections(path,closed=closed,eps=eps) == [];


// Function: path_closest_point()
// Synopsis: Returns the closest place on a {{path}} to a given {{point}}.
// Topics: Paths
// See Also: point_line_distance(), line_closest_point()
// Usage:
//   index_pt = path_closest_point(path, pt);
// Description:
//   Finds the closest {{path}} segment, and {{point}} on that segment to the given point.
//   Returns `[SEGNUM, POINT]`
// Arguments:
//   path = Path of any dimension or a 1-region.
//   pt = The point to find the closest point to.
//   closed = If true, the path is considered closed.
// Example(2D):
//   path = circle(d=100,$fn=6);
//   pt = [20,10];
//   closest = path_closest_point(path, pt);
//   stroke(path, closed=true);
//   color("blue") translate(pt) circle(d=3, $fn=12);
//   color("red") translate(closest[1]) circle(d=3, $fn=12);
function path_closest_point(path, pt, closed=true) =
    let(path = force_path(path))
    assert(is_path(path), "Input must be a path")
    assert(is_vector(pt, len(path[0])), "Input pt must be a compatible vector")
    assert(is_bool(closed))
    let(
        pts = [for (seg=pair(path,closed)) line_closest_point(seg,pt,SEGMENT)],
        dists = [for (p=pts) norm(p-pt)],
        min_seg = min_index(dists)
    ) [min_seg, pts[min_seg]];


// Function: path_tangents()
// Synopsis: Returns tangent vectors for each point along a path.
// Topics: Paths
// See Also: path_normals()
// Usage:
//   tangs = path_tangents(path, [closed], [uniform]);
// Description:
//   Compute the tangent vector to the input {{path}}.  The derivative approximation is described in deriv().
//   The returns vectors will be normalized to length 1.  If any derivatives are zero then
//   the function fails with an error.  If you set `uniform` to false then the sampling is
//   assumed to be non-uniform and the derivative is computed with adjustments to produce corrected
//   values.
// Arguments:
//   path = path of any dimension or a 1-region
//   closed = set to true of the path is closed.  Default: false
//   uniform = set to false to correct for non-uniform sampling.  Default: true
// Example(2D): A shape with non-uniform sampling gives distorted derivatives that may be undesirable.  Note that derivatives tilt towards the long edges of the rectangle.  
//   rect = square([10,3]);
//   tangents = path_tangents(rect,closed=true);
//   stroke(rect,closed=true, width=0.25);
//   color("purple")
//       for(i=[0:len(tangents)-1])
//           stroke([rect[i]-tangents[i], rect[i]+tangents[i]],width=.25, endcap2="arrow2");
// Example(2D): Setting uniform to false corrects the distorted derivatives for this example:
//   rect = square([10,3]);
//   tangents = path_tangents(rect,closed=true,uniform=false);
//   stroke(rect,closed=true, width=0.25);
//   color("purple")
//       for(i=[0:len(tangents)-1])
//           stroke([rect[i]-tangents[i], rect[i]+tangents[i]],width=.25, endcap2="arrow2");
function path_tangents(path, closed, uniform=true) =
    is_1region(path) ? path_tangents(path[0], default(closed,true), uniform) :
    let(closed=default(closed,false))
    assert(is_bool(closed))
    assert(is_path(path))
    !uniform ? [for(t=deriv(path,closed=closed, h=path_segment_lengths(path,closed))) unit(t)]
             : [for(t=deriv(path,closed=closed)) unit(t)];


// Function: path_normals()
// Synopsis: Returns normal vectors for each point along a path.
// Topics: Paths
// See Also: path_tangents()
// Usage:
//   norms = path_normals(path, [tangents], [closed]);
// Description:
//   Compute the normal vector to the input {{path}}.  This vector is perpendicular to the
//   path tangent and lies in the plane of the curve.  For 3d paths we define the plane of the curve
//   at path {{point}} i to be the plane defined by point i and its two neighbors.  At the endpoints of open paths
//   we use the three end points.  For 3d paths the computed normal is the one lying in this plane that points
//   towards the center of curvature at that path point.  For 2D paths, which lie in the xy plane, the normal
//   is the path pointing to the right of the direction the path is traveling.  If points are collinear then
//   a 3d path has no center of curvature, and hence the 
//   normal is not uniquely defined.  In this case the function issues an error.
//   For 2D paths the plane is always defined so the normal fails to exist only
//   when the derivative is zero (in the case of repeated points).
// Arguments:
//   path = 2D or 3D path or a 1-region
//   tangents = path tangents optionally supplied
//   closed = if true path is treated as a polygon.  Default: false
function path_normals(path, tangents, closed) =
    is_1region(path) ? path_normals(path[0], tangents, default(closed,true)) :
    let(closed=default(closed,false))
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
                 : let( v=cross(cross(pts[1]-pts[0], pts[2]-pts[0]),tangents[i]))
                   assert(norm(v)>EPSILON, "3D path contains collinear points")
                   unit(v)
    ];


// Function: path_curvature()
// Synopsis: Returns the estimated numerical curvature of the {{path}}.
// Topics: Paths
// See Also: path_tangents(), path_normals(), path_torsion()
// Usage:
//   curvs = path_curvature(path, [closed]);
// Description:
//   Numerically estimate the curvature of the {{path}} (in any dimension).
// Arguments:
//   path = path in any dimension or a 1-region
//   closed = if true then treat the path as a polygon.  Default: false
function path_curvature(path, closed) =
    is_1region(path) ? path_curvature(path[0], default(closed,true)) :
    let(closed=default(closed,false))
    assert(is_bool(closed))
    assert(is_path(path))
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
// Synopsis: Returns the estimated numerical torsion of the {{path}}.
// Topics: Paths
// See Also: path_tangents(), path_normals(), path_curvature()
// Usage:
//   torsions = path_torsion(path, [closed]);
// Description:
//   Numerically estimate the torsion of a 3d {{path}}.
// Arguments:
//   path = 3D path
//   closed = if true then treat path as a polygon.  Default: false
function path_torsion(path, closed=false) =
    assert(is_path(path,3), "Input path must be a 3d path")
    assert(is_bool(closed))
    let(
        d1 = deriv(path,closed=closed),
        d2 = deriv2(path,closed=closed),
        d3 = deriv3(path,closed=closed)
    ) [
        for (i=idx(path)) let(
            crossterm = cross(d1[i],d2[i])
        ) crossterm * d3[i] / sqr(norm(crossterm))
    ];


// Function: surface_normals()
// Synopsis: Estimates the normals to a surface defined by a {{point}} array
// Topics: Math, Geometry
// See Also: path_tangents(), path_normals()
// Usage:
//   normals = surface_normals(surf, [col_wrap=], [row_wrap=]);
// Description:
//   Numerically estimate the normals to a surface defined by a 2D array of 3d {{points}}, which can
//   also be regarded as an array of {{paths}} (all of the same length).  
// Arguments:
//   surf = surface in 3d defined by a 2D array of points
//   ---
//   row_wrap = if true then wrap path in the row direction (first index)
//   col_wrap = if true then wrap path in the column direction (second index)

function surface_normals(surf, col_wrap=false, row_wrap=false) =
  let(
      rowderivs = [for(y=[0:1:len(surf)-1])  path_tangents(surf[y],closed=col_wrap)],
      colderivs = [for(x=[0:1:len(surf[0])-1]) path_tangents(column(surf,x), closed=row_wrap)]
  )
  [for(y=[0:1:len(surf)-1])
     [for(x=[0:1:len(surf[0])-1])
         cross(colderivs[x][y],rowderivs[y][x])]];



// Section: Breaking paths up into subpaths



// Function: path_cut()
// Synopsis: Cuts a {{path}} into subpaths at various {{points}}.
// SynTags: PathList
// Topics: Paths, Path Subdivision
// See Also: split_path_at_self_crossings(), path_cut_points()
// Usage:
//   path_list = path_cut(path, cutdist, [closed]);
// Description:
//   Given a list of distances in `cutdist`, cut the {{path}} into
//   subpaths at those lengths, returning a list of paths.
//   If the input path is closed then the final path will include the
//   original starting {{point}}.  The list of cut distances must be
//   in ascending order and should not include the endpoints: 0 
//   or `len(path)`.  If you repeat a distance you will get an
//   empty list in that position in the output.  If you give an
//   empty cutdist array you will get the input path as output
//   (without the final vertex doubled in the case of a closed path).
// Arguments:
//   path = path of any dimension or a 1-region
//   cutdist = Distance or list of distances where path is cut
//   closed = If true, treat the path as a closed polygon.  Default: false
// Example(2D,NoAxes):
//   path = circle(d=100);
//   segs = path_cut(path, [50, 200], closed=true);
//   rainbow(segs) stroke($item, endcaps="butt", width=3);
function path_cut(path,cutdist,closed) =
  is_num(cutdist) ? path_cut(path,[cutdist],closed) :
  is_1region(path) ? path_cut(path[0], cutdist, default(closed,true)):
  let(closed=default(closed,false))
  assert(is_bool(closed))
  assert(is_vector(cutdist))
  assert(last(cutdist)<path_length(path,closed=closed)-EPSILON,"Cut distances must be smaller than the path length")
  assert(cutdist[0]>EPSILON, "Cut distances must be strictly positive")
  let(
      cutlist = path_cut_points(path,cutdist,closed=closed)
  )
  _path_cut_getpaths(path, cutlist, closed);


function _path_cut_getpaths(path, cutlist, closed) =
  let(
      cuts = len(cutlist)
  )
  [
      [ each list_head(path,cutlist[0][1]-1),
        if (!approx(cutlist[0][0], path[cutlist[0][1]-1])) cutlist[0][0]
      ],
      for(i=[0:1:cuts-2])
          cutlist[i][0]==cutlist[i+1][0] && cutlist[i][1]==cutlist[i+1][1] ? []
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



// Function: path_cut_points()
// Synopsis: Returns a list of cut {{points}} at a list of distances from the first point in a {{path}}.
// Topics: Paths, Path Subdivision
// See Also: path_cut(), split_path_at_self_crossings()
// Usage:
//   cuts = path_cut_points(path, cutdist, [closed=], [direction=]);
//
// Description:
//   Cuts a {{path}} at a list of distances from the first {{point}} in the path.  Returns a list of the cut
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
//   cutdist = distances where the path should be cut (a list) or a scalar single distance
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
function path_cut_points(path, cutdist, closed=false, direction=false) =
    let(long_enough = len(path) >= (closed ? 3 : 2))
    assert(long_enough,len(path)<2 ? "Two points needed to define a path" : "Closed path must include three points")
    is_num(cutdist) ? path_cut_points(path, [cutdist],closed, direction)[0] :
    assert(is_vector(cutdist))
    assert(is_increasing(cutdist), "Cut distances must be an increasing list")
    let(cuts = path_cut_points_recurse(path,cutdist,closed))
    !direction
       ? cuts
       : let(
             dir = _path_cuts_dir(path, cuts, closed),
             normals = _path_cuts_normals(path, cuts, dir, closed)
         )
         hstack(cuts, list_to_matrix(dir,1), list_to_matrix(normals,1));

// Main recursive path cut function
function path_cut_points_recurse(path, dists, closed=false, pind=0, dtotal=0, dind=0, result=[]) =
    dind == len(dists) ? result :
    let(
        lastpt = len(result)==0? [] : last(result)[0],       // location of last cut point
        dpartial = len(result)==0? 0 : norm(lastpt-select(path,pind)),  // remaining length in segment
        nextpoint = dists[dind] < dpartial+dtotal  // Do we have enough length left on the current segment?
           ? [lerp(lastpt,select(path,pind),(dists[dind]-dtotal)/dpartial),pind] 
           : _path_cut_single(path, dists[dind]-dtotal-dpartial, closed, pind)
    ) 
    path_cut_points_recurse(path, dists, closed, nextpoint[1], dists[dind],dind+1, concat(result, [nextpoint]));


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
        len(path[0])==2? [-dirs[i].y, dirs[i].x]
          : 
            let(
                plane = len(path)<3 ? undef :
                let(start = max(min(cuts[i][1],len(path)-1),2)) _path_plane(path, start, start-2)
            )
            plane==undef?
                ( dirs[i].x==0 && dirs[i].y==0 ? [1,0,0]  // If it's z direction return x vector
                                               : unit([-dirs[i].y, dirs[i].x,0])) // otherwise perpendicular to projection
                : unit(cross(dirs[i],cross(plane[0],plane[1])))
    ];

// Scan from the specified point (ind) to find a noncoplanar triple to use
// to define the plane of the path.
function _path_plane(path, ind, i,closed) =
    i<(closed?-1:0) ? undef :
    !is_collinear(path[ind],path[ind-1], select(path,i))?
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


// internal function
// converts pathcut output form to a [segment, u]
// form list that works withi path_select
function _cut_to_seg_u_form(pathcut, path, closed) =
  let(lastind = len(path) - (closed?0:1))
  [for(entry=pathcut)
    entry[1] > lastind ? [lastind,0] :
    let(
        a = path[entry[1]-1],
        b = path[entry[1]],
        c = entry[0],
        i = max_index(v_abs(b-a)),
        factor = (c[i]-a[i])/(b[i]-a[i])
    )
    [entry[1]-1,factor]
  ];



// Function: split_path_at_self_crossings()
// Synopsis: Split a 2D {{path}} wherever it crosses itself.
// SynTags: PathList
// Topics: Paths, Path Subdivision
// See Also: path_cut(), path_cut_points()
// Usage:
//   paths = split_path_at_self_crossings(path, [closed], [eps]);
// Description:
//   Splits a 2D {{path}} into sub-paths wherever the original path crosses itself.
//   Splits may occur mid-segment, so new vertices will be created at the intersection points.
//   Returns a list of the resulting subpaths.  
// Arguments:
//   path = A 2D path or a 1-region.
//   closed = If true, treat path as a closed polygon.  Default: true
//   eps = Acceptable variance.  Default: `EPSILON` (1e-9)
// Example(2D,NoAxes):
//   path = [ [-100,100], [0,-50], [100,100], [100,-100], [0,50], [-100,-100] ];
//   paths = split_path_at_self_crossings(path);
//   rainbow(paths) stroke($item, closed=false, width=3);
function split_path_at_self_crossings(path, closed=true, eps=EPSILON) =
    let(path = force_path(path))
    assert(is_path(path,2), "Must give a 2D path")
    assert(is_bool(closed))
    let(
        path = list_unwrap(path, eps=eps),
        isects = deduplicate(
            eps=eps,
            concat(
                [[0, 0]],
                sort([
                    for (
                        a = _path_self_intersections(path, closed=closed, eps=eps),
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
                section = _path_select(path, s1, u1, s2, u2, closed=closed),
                outpath = deduplicate(eps=eps, section)
            )
            if (len(outpath)>1) outpath
    ];


function _tag_self_crossing_subpaths(path, nonzero, closed=true, eps=EPSILON) =
    let(
        subpaths = split_path_at_self_crossings(
            path, closed=true, eps=eps
        )
    ) [
        for (subpath = subpaths) let(
            seg = select(subpath,0,1),
            mp = mean(seg),
            n = line_normal(seg) / 2048,
            p1 = mp + n,
            p2 = mp - n,
            p1in = point_in_polygon(p1, path, nonzero=nonzero) >= 0,
            p2in = point_in_polygon(p2, path, nonzero=nonzero) >= 0,
            tag = (p1in && p2in)? "I" : "O"
        ) [tag, subpath]
    ];


// Function: polygon_parts()
// Synopsis: Parses a self-intersecting polygon into a list of non-intersecting {{polygons}}.
// SynTags: PathList
// Topics: Paths, Polygons
// See Also: split_path_at_self_crossings(), path_cut(), path_cut_points()
// Usage:
//   splitpolys = polygon_parts(poly, [nonzero], [eps]);
// Description:
//   Given a possibly self-intersecting 2D {{polygon}}, constructs a representation of the original polygon as a list of
//   non-intersecting simple polygons.  If nonzero is set to true then it uses the nonzero method for defining polygon membership.
//   For simple cases, such as the pentagram, this will produce the outer perimeter of a self-intersecting polygon.  
// Arguments:
//   poly = a 2D polygon or 1-region
//   nonzero = If true use the nonzero method for checking if a point is in a polygon.  Otherwise use the even-odd method.  Default: false
//   eps = The epsilon error value to determine whether two points coincide.  Default: `EPSILON` (1e-9)
// Example(2D,NoAxes):  This cross-crossing polygon breaks up into its 3 components (regardless of the value of nonzero).
//   poly = [
//       [-100,100], [0,-50], [100,100],
//       [100,-100], [0,50], [-100,-100]
//   ];
//   splitpolys = polygon_parts(poly);
//   rainbow(splitpolys) stroke($item, closed=true, width=3);
// Example(2D,NoAxes): With nonzero=false you get even-odd mode which matches OpenSCAD, so the pentagram breaks apart into its five points.
//   pentagram = turtle(["move",100,"left",144], repeat=4);
//   left(100)polygon(pentagram);
//   rainbow(polygon_parts(pentagram,nonzero=false))
//     stroke($item,closed=true,width=2.5);
// Example(2D,NoAxes): With nonzero=true you get only the outer perimeter.  You can use this to create the polygon using the nonzero method, which is not supported by OpenSCAD.
//   pentagram = turtle(["move",100,"left",144], repeat=4);
//   outside = polygon_parts(pentagram,nonzero=true);
//   left(100)region(outside);
//   rainbow(outside)
//     stroke($item,closed=true,width=2.5);
// Example(2D,NoAxes): 
//   N=12;
//   ang=360/N;
//   sr=10;
//   poly = turtle(["angle", 90+ang/2,
//                  "move", sr, "left",
//                  "move", 2*sr*sin(ang/2), "left",
//                  "repeat", 4,
//                     ["move", 2*sr, "left",
//                      "move", 2*sr*sin(ang/2), "left"],
//                  "move", sr]);
//   stroke(poly, width=.3);
//   right(20)rainbow(polygon_parts(poly)) polygon($item);
// Example(2D,NoAxes): overlapping poly segments disappear
//   poly = [[0,0], [10,0], [10,10], [0,10],[0,20], [20,10],[10,10], [0,10],[0,0]];
//   stroke(poly,width=0.3);
//   right(22)stroke(polygon_parts(poly)[0], width=0.3, closed=true);
// Example(2D,NoAxes): Poly segments disappear outside as well
//   poly = turtle(["repeat", 3, ["move", 17, "left", "move", 10, "left", "move", 7, "left", "move", 10, "left"]]);
//   back(2)stroke(poly,width=.5);
//   fwd(12)rainbow(polygon_parts(poly)) stroke($item, closed=true, width=0.5);
// Example(2D,NoAxes):  This shape has six components
//   poly = turtle(["repeat", 3, ["move", 15, "left", "move", 7, "left", "move", 10, "left", "move", 17, "left"]]);
//   polygon(poly);
//   right(22)rainbow(polygon_parts(poly)) polygon($item);
// Example(2D,NoAxes): When the loops of the shape overlap then nonzero gives a different result than the even-odd method.
//   poly = turtle(["repeat", 3, ["move", 15, "left", "move", 7, "left", "move", 10, "left", "move", 10, "left"]]);
//   polygon(poly);
//   right(27)rainbow(polygon_parts(poly)) polygon($item);
//   move([16,-14])rainbow(polygon_parts(poly,nonzero=true)) polygon($item);
function polygon_parts(poly, nonzero=false, eps=EPSILON) =
    let(poly = force_path(poly))
    assert(is_path(poly,2), "Must give 2D polygon")
    assert(is_bool(nonzero))    
    let(
        poly = list_unwrap(poly, eps=eps),
        tagged = _tag_self_crossing_subpaths(poly, nonzero=nonzero, closed=true, eps=eps),
        kept = [for (sub = tagged) if(sub[0] == "O") sub[1]],
        outregion = _assemble_path_fragments(kept, eps=eps)
    ) outregion;


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


/// Internal Function: _assemble_a_path_from_fragments()
/// Usage:
///   _assemble_a_path_from_fragments(subpaths);
/// Description:
///   Given a list of paths, assembles them together into one complete closed polygon path, and
///   remainder fragments.  Returns [PATH, FRAGMENTS] where FRAGMENTS is the list of remaining
///   unused path fragments.
/// Arguments:
///   fragments = List of paths to be assembled into complete polygons.
///   rightmost = If true, assemble paths using rightmost turns. Leftmost if false.
///   startfrag = The fragment to start with.  Default: 0
///   eps = The epsilon error value to determine whether two points coincide.  Default: `EPSILON` (1e-9)
function _assemble_a_path_from_fragments(fragments, rightmost=true, startfrag=0, eps=EPSILON) =
    len(fragments)==0? [[],[]] :
    len(fragments)==1? [fragments[0],[]] :
    let(
        path = fragments[startfrag],
        newfrags = [for (i=idx(fragments)) if (i!=startfrag) fragments[i]]
    ) are_ends_equal(path, eps=eps)? (
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
    ) : are_ends_equal(foundfrag, eps=eps)? (
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
    _assemble_a_path_from_fragments(
        fragments=newfrags,
        rightmost=rightmost,
        eps=eps
    );


/// Internal Function: _assemble_path_fragments()
/// Usage:
///   _assemble_path_fragments(subpaths);
/// Description:
///   Given a list of paths, assembles them together into complete closed polygon paths if it can.
///   Polygons with area < eps will be discarded and not returned.  
/// Arguments:
///   fragments = List of paths to be assembled into complete polygons.
///   eps = The epsilon error value to determine whether two points coincide.  Default: `EPSILON` (1e-9)
function _assemble_path_fragments(fragments, eps=EPSILON, _finished=[]) =
    len(fragments)==0? _finished :
    let(
        minxidx = min_index([
            for (frag=fragments) min(column(frag,0))
        ]),
        result_l = _assemble_a_path_from_fragments(
            fragments=fragments,
            startfrag=minxidx,
            rightmost=false,
            eps=eps
        ),
        result_r = _assemble_a_path_from_fragments(
            fragments=fragments,
            startfrag=minxidx,
            rightmost=true,
            eps=eps
        ),
        l_area = abs(polygon_area(result_l[0])),
        r_area = abs(polygon_area(result_r[0])),
        result = l_area < r_area? result_l : result_r,
        newpath = list_unwrap(result[0]),
        remainder = result[1],
        finished = min(l_area,r_area)<eps ? _finished : concat(_finished, [newpath])
    ) _assemble_path_fragments(
        fragments=remainder,
        eps=eps,
        _finished=finished
    );


/// Different but similar path assembly function that is much faster than
/// _assemble_path_fragments and can work in 3d, but cannot handle loops.
///
/// Takes a list of paths that are in the correct direction and assembles
/// them into a list of paths.  Returns a list of assembled paths.
/// If closed is false then any paths that are closed will have duplicate
/// endpoints, and open paths will not have duplicate endpoints.
/// If closed=true then all paths are assumed closed and none of the returned
/// paths will have duplicate endpoints.
///
/// It is assumed that the paths do not intersect each other.
/// Paths can be in any dimension

function _assemble_partial_paths(paths, closed=false, eps=1e-7) =
    let(
        pathlist = _assemble_partial_paths_recur(paths, eps)
        //// this eliminates crossing paths that cross only at vertices in the input paths lists
        // splitpaths =
        //     [for(path=pathlist) each
        //        let(
        //            searchlist = vector_search(path,eps,path),
        //            duplist = [for(i=idx(searchlist)) if (len(searchlist[i])>1) i]
        //        )
        //        duplist==[] ? [path]
        //       :               
        //        let(
        //            fragments = [for(i=idx(duplist)) select(path, duplist[i], select(duplist,i+1))]
        //        )
        //        len(fragments)==1 ? fragments
        //                          : _assemble_path_fragments(fragments)
        //     ]
    )
    closed ? [for(path=pathlist) list_unwrap(path)] : pathlist;


function _assemble_partial_paths_recur(edges, eps, paths=[], i=0) =
    i==len(edges) ? paths :
    norm(edges[i][0]-last(edges[i]))<eps ? _assemble_partial_paths_recur(edges, eps, paths,i+1) :
    let(    // Find paths that connects on left side and right side of the edges (if one exists)
        
        left = [for(j=idx(paths)) if (approx(last(paths[j]),edges[i][0],eps)) j],
        right = [for(j=idx(paths)) if (approx(last(edges[i]),paths[j][0],eps)) j]
    )
    let(
        keep_path = list_remove(paths,[if (len(left)>0) left[0],if (len(right)>0) right[0]]),
        update_path =  left==[] && right==[] ? edges[i]
                    : left==[] ? concat(list_head(edges[i]),paths[right[0]])
                    : right==[] ?  concat(paths[left[0]],slice(edges[i],1,-1))
                    : left[0] != right[0] ? concat(paths[left[0]],slice(edges[i],1,-2), paths[right[0]])
                    : concat(paths[left[0]], slice(edges[i],1,-1)) // last arg -2 removes duplicate endpoints but this is handled in passthrough function
    )
    _assemble_partial_paths_recur(edges, eps, concat(keep_path, [update_path]), i+1);



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
