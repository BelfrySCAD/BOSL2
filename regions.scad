//////////////////////////////////////////////////////////////////////
// LibFile: regions.scad
//   Regions and 2D boolean geometry
// Includes:
//   include <BOSL2/std.scad>
//////////////////////////////////////////////////////////////////////


// CommonCode:
//   include <BOSL2/rounding.scad>


// Section: Regions


// Function: is_region()
// Usage:
//   is_region(x);
// Description:
//   Returns true if the given item looks like a region.  A region is defined as a list of zero or more paths.
function is_region(x) = is_list(x) && is_path(x.x);


// Function: close_region()
// Usage:
//   close_region(region);
// Description:
//   Closes all paths within a given region.
function close_region(region, eps=EPSILON) = [for (path=region) close_path(path, eps=eps)];


// Module: region()
// Usage:
//   region(r);
// Description:
//   Creates 2D polygons for the given region.  The region given is a list of closed 2D paths.
//   Each path will be effectively exclusive-ORed from all other paths in the region, so if a
//   path is inside another path, it will be effectively subtracted from it.
// Example(2D):
//   region([circle(d=50), square(25,center=true)]);
// Example(2D):
//   rgn = concat(
//       [for (d=[50:-10:10]) circle(d=d-5)],
//       [square([60,10], center=true)]
//   );
//   region(rgn);
module region(r)
{
    points = flatten(r);
    paths = [
        for (i=[0:1:len(r)-1]) let(
            start = default(sum([for (j=[0:1:i-1]) len(r[j])]),0)
        ) [for (k=[0:1:len(r[i])-1]) start+k]
    ];
    polygon(points=points, paths=paths);
}


// Function: check_and_fix_path()
// Usage:
//   check_and_fix_path(path, [valid_dim], [closed], [name])
// Description:
//   Checks that the input is a path.  If it is a region with one component, converts it to a path.
//   Note that arbitrary paths must have at least two points, but closed paths need at least 3 points.  
//   valid_dim specfies the allowed dimension of the points in the path.
//   If the path is closed, removes duplicate endpoint if present.
// Arguments:
//   path = path to process
//   valid_dim = list of allowed dimensions for the points in the path, e.g. [2,3] to require 2 or 3 dimensional input.  If left undefined do not perform this check.  Default: undef
//   closed = set to true if the path is closed, which enables a check for endpoint duplication
//   name = parameter name to use for reporting errors.  Default: "path"
function check_and_fix_path(path, valid_dim=undef, closed=false, name="path") =
    let(
        path =
          is_region(path)? 
               assert(len(path)==1,str("Region ",name," supplied as path does not have exactly one component"))
               path[0]
          :
               assert(is_path(path), str("Input ",name," is not a path"))
               path
    )
    assert(len(path)>(closed?2:1),closed?str("Closed path ",name," must have at least 3 points")
                                        :str("Path ",name," must have at least 2 points"))
    let(valid=is_undef(valid_dim) || in_list(len(path[0]),force_list(valid_dim)))
    assert(
        valid, str(
            "Input ",name," must has dimension ", len(path[0])," but dimension must be ",
            is_list(valid_dim) ? str("one of ",valid_dim) : valid_dim
        )
    )
    closed && approx(path[0], last(path))? list_head(path) : path;


// Function: cleanup_region()
// Usage:
//   cleanup_region(region);
// Description:
//   For all paths in the given region, if the last point coincides with the first point, removes the last point.
// Arguments:
//   region = The region to clean up.  Given as a list of polygon paths.
//   eps = Acceptable variance.  Default: `EPSILON` (1e-9)
function cleanup_region(region, eps=EPSILON) =
    [for (path=region) cleanup_path(path, eps=eps)];


// Function: point_in_region()
// Usage:
//   point_in_region(point, region);
// Description:
//   Tests if a point is inside, outside, or on the border of a region.
//   Returns -1 if the point is outside the region.
//   Returns 0 if the point is on the boundary.
//   Returns 1 if the point lies inside the region.
// Arguments:
//   point = The point to test.
//   region = The region to test against.  Given as a list of polygon paths.
//   eps = Acceptable variance.  Default: `EPSILON` (1e-9)
function point_in_region(point, region, eps=EPSILON, _i=0, _cnt=0) =
    (_i >= len(region))? ((_cnt%2==1)? 1 : -1) : let(
        pip = point_in_polygon(point, region[_i], eps=eps)
    ) pip==0? 0 : point_in_region(point, region, eps=eps, _i=_i+1, _cnt = _cnt + (pip>0? 1 : 0));


// Function: polygons_equal()
// Usage:
//    b = polygons_equal(poly1, poly2, [eps])
// Description:
//    Returns true if the components of region1 and region2 are the same polygons
//    within given epsilon tolerance.
// Arguments:
//    poly1 = first polygon
//    poly2 = second polygon
//    eps = tolerance for comparison
// Example(NORENDER):
//    polygons_equal(pentagon(r=4),
//                   rot(360/5, p=pentagon(r=4))); // returns true
//    polygons_equal(pentagon(r=4),
//                   rot(90, p=pentagon(r=4)));    // returns false
function polygons_equal(poly1, poly2, eps=EPSILON) =
    let(
        poly1 = cleanup_path(poly1),
        poly2 = cleanup_path(poly2),
        l1 = len(poly1),
        l2 = len(poly2)
    ) l1 != l2 ? false :
    let( maybes = find_first_match(poly1[0], poly2, eps=eps, all=true) )
    maybes == []? false :
    [for (i=maybes) if (__polygons_equal(poly1, poly2, eps, i)) 1] != [];

function __polygons_equal(poly1, poly2, eps, st) =
    max([for(d=poly1-select(poly2,st,st-1)) d*d])<eps*eps;


// Function: poly_in_polygons()
// Topics: Polygons, Comparators
// See Also: polygons_equal(), regions_equal()
// Usage:
//   bool = poly_in_polygons(poly, polys);
// Description:
//   Returns true if one of the polygons in `polys` is equivalent to the polygon `poly`.
// Arguments:
//   poly = The polygon to search for.
//   polys = The list of polygons to look for the polygon in.
function poly_in_polygons(poly, polys) =
    __poly_in_polygons(poly, polys, 0);

function __poly_in_polygons(poly, polys, i) =
    i >= len(polys)? false :
    polygons_equal(poly, polys[i])? true :
    __poly_in_polygons(poly, polys, i+1);


// Function: regions_equal()
// Usage:
//    b = regions_equal(region1, region2, [eps])
// Description:
//    Returns true if the components of region1 and region2 are the same polygons
//    within given epsilon tolerance.
// Arguments:
//    poly1 = first polygon
//    poly2 = second polygon
//    eps = tolerance for comparison
function regions_equal(region1, region2) =
    assert(is_region(region1) && is_region(region2))
    len(region1) != len(region2)? false :
    __regions_equal(region1, region2, 0);

function __regions_equal(region1, region2, i) =
    i >= len(region1)? true :
    !poly_in_polygons(region1[i], region2)? false :
    __regions_equal(region1, region2, i+1);


// Function: region_path_crossings()
// Usage:
//   region_path_crossings(path, region);
// Description:
//   Returns a sorted list of [SEGMENT, U] that describe where a given path is crossed by a second path.
// Arguments:
//   path = The path to find crossings on.
//   region = Region to test for crossings of.
//   closed = If true, treat path as a closed polygon.  Default: true
//   eps = Acceptable variance.  Default: `EPSILON` (1e-9)
function region_path_crossings(path, region, closed=true, eps=EPSILON) = sort([
    let(
        segs = pair(closed? close_path(path) : cleanup_path(path))
    ) for (
        si = idx(segs),
        p = close_region(region),
        s2 = pair(p)
    ) let (
        isect = _general_line_intersection(segs[si], s2, eps=eps)
    ) if (
        !is_undef(isect[0]) &&
        isect[1] >= 0-eps && isect[1] < 1+eps &&
        isect[2] >= 0-eps && isect[2] < 1+eps
    )
    [si, isect[1]]
]);


// Function: split_path_at_region_crossings()
// Usage:
//   paths = split_path_at_region_crossings(path, region, [eps]);
// Description:
//   Splits a path into sub-paths wherever the path crosses the perimeter of a region.
//   Splits may occur mid-segment, so new vertices will be created at the intersection points.
// Arguments:
//   path = The path to split up.
//   region = The region to check for perimeter crossings of.
//   closed = If true, treat path as a closed polygon.  Default: true
//   eps = Acceptable variance.  Default: `EPSILON` (1e-9)
// Example(2D):
//   path = square(50,center=false);
//   region = [circle(d=80), circle(d=40)];
//   paths = split_path_at_region_crossings(path, region);
//   color("#aaa") region(region);
//   rainbow(paths) stroke($item, closed=false, width=2);
function split_path_at_region_crossings(path, region, closed=true, eps=EPSILON) =
    let(
        path = deduplicate(path, eps=eps),
        region = [for (path=region) deduplicate(path, eps=eps)],
        xings = region_path_crossings(path, region, closed=closed, eps=eps),
        crossings = deduplicate(
            concat([[0,0]], xings, [[len(path)-1,1]]),
            eps=eps
        ),
        subpaths = [
            for (p = pair(crossings))
                deduplicate(
                    path_subselect(path, p[0][0], p[0][1], p[1][0], p[1][1], closed=closed),
                    eps=eps
                )
        ]
    )
    subpaths;


// Function: split_nested_region()
// Usage:
//   rgns = split_nested_region(region);
// Description:
//   Separates the distinct (possibly nested) positive subregions of a larger compound region.
//   Returns a list of regions, such that each returned region has exactly one positive outline
//   and zero or more void outlines.
function split_nested_region(region) =
    let(
        paths = sort(idx=0, [
            for(i = idx(region)) let(
                cnt = sum([
                    for (j = idx(region)) if (i!=j)
                    let(pt = lerp(region[i][0],region[i][1],0.5))
                    point_in_polygon(pt, region[j]) >=0 ? 1 : 0
                ])
            ) [cnt, region[i]]
        ]),
        outs = [
            for (candout = paths) let(
                lev = candout[0],
                parent = candout[1]
            ) if (lev % 2 == 0) [
                clockwise_polygon(parent),
                for (path = paths) if (
                    path[0] == lev+1 &&
                    point_in_polygon(
                        lerp(path[1][0], path[1][1], 0.5),
                        parent
                    ) >= 0
                ) ccw_polygon(path[1])
            ]
        ]
    ) outs;



// Section: Region Extrusion and VNFs

function _path_path_closest_vertices(path1,path2) =
    let(
        dists = [for (i=idx(path1)) let(j=closest_point(path1[i],path2)) [j,norm(path2[j]-path1[i])]],
        i1 = min_index(subindex(dists,1)),
        i2 = dists[i1][0]
    ) [dists[i1][1], i1, i2];

function _join_paths_at_vertices(path1,path2,seg1,seg2) =
    let(
        path1 = close_path(clockwise_polygon(polygon_shift(path1, seg1))),
        path2 = close_path(ccw_polygon(polygon_shift(path2, seg2)))
    ) cleanup_path(deduplicate([each path1, each path2]));


function _cleave_simple_region(region) =
    len(region)==0? [] :
    len(region)<=1? clockwise_polygon(region[0]) :
    let(
        dists = [
            for (i=[1:1:len(region)-1])
            _path_path_closest_vertices(region[0],region[i])
        ],
        idxi = min_index(subindex(dists,0)),
        newoline = _join_paths_at_vertices(
            region[0], region[idxi+1],
            dists[idxi][1], dists[idxi][2]
        )
    ) len(region)==2? clockwise_polygon(newoline) :
    let(
        orgn = [
            newoline,
            for (i=idx(region))
                if (i>0 && i!=idxi+1)
                    region[i]
        ]
    )
    assert(len(orgn)<len(region))
    _cleave_simple_region(orgn);


// Function: region_faces()
// Usage:
//   vnf = region_faces(region, [transform], [reverse], [vnf]);
// Description:
//   Given a region, applies the given transformation matrix to it and makes a VNF of
//   faces for that region, reversed if necessary.
// Arguments:
//   region = The region to make faces for.
//   transform = If given, a transformation matrix to apply to the faces generated from the region.  Default: No transformation applied.
//   reverse = If true, reverse the normals of the faces generated from the region.  An untransformed region will have face normals pointing `UP`.  Default: false
//   vnf = If given, the faces are added to this VNF.  Default: `EMPTY_VNF`
function region_faces(region, transform, reverse=false, vnf=EMPTY_VNF) =
    let (
        regions = split_nested_region(region),
        vnfs = [
            if (vnf != EMPTY_VNF) vnf,
            for (rgn = regions) let(
                cleaved = path3d(_cleave_simple_region(rgn)),
                face = is_undef(transform)? cleaved : apply(transform,cleaved),
                faceidxs = reverse? [for (i=[len(face)-1:-1:0]) i] : [for (i=[0:1:len(face)-1]) i]
            ) [face, [faceidxs]]
        ],
        outvnf = vnf_merge(vnfs)
    ) outvnf;


// Function&Module: linear_sweep()
// Usage:
//   linear_sweep(region, height, [center], [slices], [twist], [scale], [style], [convexity]);
// Description:
//   If called as a module, creates a polyhedron that is the linear extrusion of the given 2D region or path.
//   If called as a function, returns a VNF that can be used to generate a polyhedron of the linear extrusion
//   of the given 2D region or path.  The benefit of using this, over using `linear_extrude region(rgn)` is
//   that you can use `anchor`, `spin`, `orient` and attachments with it.  Also, you can make more refined
//   twisted extrusions by using `maxseg` to subsample flat faces.
// Arguments:
//   region = The 2D [Region](regions.scad) or path that is to be extruded.
//   height = The height to extrude the region.  Default: 1
//   center = If true, the created polyhedron will be vertically centered.  If false, it will be extruded upwards from the origin.  Default: `false`
//   slices = The number of slices to divide the shape into along the Z axis, to allow refinement of detail, especially when working with a twist.  Default: `twist/5`
//   maxseg = If given, then any long segments of the region will be subdivided to be shorter than this length.  This can refine twisting flat faces a lot.  Default: `undef` (no subsampling)
//   twist = The number of degrees to rotate the shape clockwise around the Z axis, as it rises from bottom to top.  Default: 0
//   scale = The amount to scale the shape, from bottom to top.  Default: 1
//   style = The style to use when triangulating the surface of the object.  Valid values are `"default"`, `"alt"`, or `"quincunx"`.
//   convexity = Max number of surfaces any single ray could pass through.  Module use only.
//   anchor_isect = If true, anchoring it performed by finding where the anchor vector intersects the swept shape.  Default: false
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
// Example: Extruding a Compound Region.
//   rgn1 = [for (d=[10:10:60]) circle(d=d,$fn=8)];
//   rgn2 = [square(30,center=false)];
//   rgn3 = [for (size=[10:10:20]) move([15,15],p=square(size=size, center=true))];
//   mrgn = union(rgn1,rgn2);
//   orgn = difference(mrgn,rgn3);
//   linear_sweep(orgn,height=20,convexity=16);
// Example: With Twist, Scale, Slices and Maxseg.
//   rgn1 = [for (d=[10:10:60]) circle(d=d,$fn=8)];
//   rgn2 = [square(30,center=false)];
//   rgn3 = [for (size=[10:10:20]) move([15,15],p=square(size=size, center=true))];
//   mrgn = union(rgn1,rgn2);
//   orgn = difference(mrgn,rgn3);
//   linear_sweep(orgn,height=50,maxseg=2,slices=40,twist=180,scale=0.5,convexity=16);
// Example: Anchors on an Extruded Region
//   rgn1 = [for (d=[10:10:60]) circle(d=d,$fn=8)];
//   rgn2 = [square(30,center=false)];
//   rgn3 = [for (size=[10:10:20]) move([15,15],p=square(size=size, center=true))];
//   mrgn = union(rgn1,rgn2);
//   orgn = difference(mrgn,rgn3);
//   linear_sweep(orgn,height=20,convexity=16) show_anchors();
module linear_sweep(region, height=1, center, twist=0, scale=1, slices, maxseg, style="default", convexity, anchor_isect=false, anchor, spin=0, orient=UP) {
    region = is_path(region)? [region] : region;
    cp = mean(pointlist_bounds(flatten(region)));
    anchor = get_anchor(anchor, center, "origin", "origin");
    vnf = linear_sweep(
        region, height=height,
        twist=twist, scale=scale,
        slices=slices, maxseg=maxseg,
        style=style
    );
    attachable(anchor,spin,orient, cp=cp, vnf=vnf, extent=!anchor_isect) {
        vnf_polyhedron(vnf, convexity=convexity);
        children();
    }
}


function linear_sweep(region, height=1, center, twist=0, scale=1, slices, maxseg, style="default", anchor_isect=false, anchor, spin=0, orient=UP) =
    let(
        anchor = get_anchor(anchor,center,BOT,BOT),
        region = is_path(region)? [region] : region,
        cp = mean(pointlist_bounds(flatten(region))),
        regions = split_nested_region(region),
        slices = default(slices, floor(twist/5+1)),
        step = twist/slices,
        hstep = height/slices,
        trgns = [
            for (rgn=regions) [
                for (path=rgn) let(
                    p = cleanup_path(path),
                    path = is_undef(maxseg)? p : [
                        for (seg=pair(p,true)) each
                        let(steps=ceil(norm(seg.y-seg.x)/maxseg))
                        lerpn(seg.x, seg.y, steps, false)
                    ]
                )
                rot(twist, p=scale([scale,scale],p=path))
            ]
        ],
        vnf = vnf_merge([
            for (rgn = regions)
            for (pathnum = idx(rgn)) let(
                p = cleanup_path(rgn[pathnum]),
                path = is_undef(maxseg)? p : [
                    for (seg=pair(p,true)) each
                    let(steps=ceil(norm(seg.y-seg.x)/maxseg))
                    lerpn(seg.x, seg.y, steps, false)
                ],
                verts = [
                    for (i=[0:1:slices]) let(
                        sc = lerp(1, scale, i/slices),
                        ang = i * step,
                        h = i * hstep - height/2
                    ) scale([sc,sc,1], p=rot(ang, p=path3d(path,h)))
                ]
            ) vnf_vertex_array(verts, caps=false, col_wrap=true, style=style),
            for (rgn = regions) region_faces(rgn, move([0,0,-height/2]), reverse=true),
            for (rgn = trgns) region_faces(rgn, move([0,0, height/2]), reverse=false)
        ])
    ) reorient(anchor,spin,orient, cp=cp, vnf=vnf, extent=!anchor_isect, p=vnf);



// Section: Offsets and Boolean 2D Geometry


function _offset_chamfer(center, points, delta) =
    let(
        dist = sign(delta)*norm(center-line_intersection(select(points,[0,2]), [center, points[1]])),
        endline = _shift_segment(select(points,[0,2]), delta-dist)
    ) [
        line_intersection(endline, select(points,[0,1])),
        line_intersection(endline, select(points,[1,2]))
    ];


function _shift_segment(segment, d) =
    move(d*line_normal(segment),segment);


// Extend to segments to their intersection point.  First check if the segments already have a point in common,
// which can happen if two colinear segments are input to the path variant of `offset()`
function _segment_extension(s1,s2) =
    norm(s1[1]-s2[0])<1e-6 ? s1[1] : line_intersection(s1,s2);


function _makefaces(direction, startind, good, pointcount, closed) =
    let(
        lenlist = list_bset(good, pointcount),
        numfirst = len(lenlist),
        numsecond = sum(lenlist),
        prelim_faces = _makefaces_recurse(startind, startind+len(lenlist), numfirst, numsecond, lenlist, closed)
    )
    direction? [for(entry=prelim_faces) reverse(entry)] : prelim_faces;


function _makefaces_recurse(startind1, startind2, numfirst, numsecond, lenlist, closed, firstind=0, secondind=0, faces=[]) =
    // We are done if *both* firstind and secondind reach their max value, which is the last point if !closed or one past
    // the last point if closed (wrapping around).  If you don't check both you can leave a triangular gap in the output.
    ((firstind == numfirst - (closed?0:1)) && (secondind == numsecond - (closed?0:1)))? faces :
    _makefaces_recurse(
        startind1, startind2, numfirst, numsecond, lenlist, closed, firstind+1, secondind+lenlist[firstind],
        lenlist[firstind]==0? (
            // point in original path has been deleted in offset path, so it has no match.  We therefore
            // make a triangular face using the current point from the offset (second) path
            // (The current point in the second path can be equal to numsecond if firstind is the last point)
            concat(faces,[[secondind%numsecond+startind2, firstind+startind1, (firstind+1)%numfirst+startind1]])
            // in this case a point or points exist in the offset path corresponding to the original path
        ) : (
            concat(faces,
                // First generate triangular faces for all of the extra points (if there are any---loop may be empty)
                [for(i=[0:1:lenlist[firstind]-2]) [firstind+startind1, secondind+i+1+startind2, secondind+i+startind2]],
                // Finish (unconditionally) with a quadrilateral face
                [
                    [
                        firstind+startind1,
                        (firstind+1)%numfirst+startind1,
                        (secondind+lenlist[firstind])%numsecond+startind2,
                        (secondind+lenlist[firstind]-1)%numsecond+startind2
                    ]
                ]
            )
        )
    );


// Determine which of the shifted segments are good
function _good_segments(path, d, shiftsegs, closed, quality) =
    let(
        maxind = len(path)-(closed ? 1 : 2),
        pathseg = [for(i=[0:maxind]) select(path,i+1)-path[i]],
        pathseg_len =  [for(seg=pathseg) norm(seg)],
        pathseg_unit = [for(i=[0:maxind]) pathseg[i]/pathseg_len[i]],
        // Order matters because as soon as a valid point is found, the test stops
        // This order works better for circular paths because they succeed in the center
        alpha = concat([for(i=[1:1:quality]) i/(quality+1)],[0,1])
    ) [
        for (i=[0:len(shiftsegs)-1])
            (i>maxind)? true :
            _segment_good(path,pathseg_unit,pathseg_len, d - 1e-7, shiftsegs[i], alpha)
    ];


// Determine if a segment is good (approximately)
// Input is the path, the path segments normalized to unit length, the length of each path segment
// the distance threshold, the segment to test, and the locations on the segment to test (normalized to [0,1])
// The last parameter, index, gives the current alpha index.
//
// A segment is good if any part of it is farther than distance d from the path.  The test is expensive, so
// we want to quit as soon as we find a point with distance > d, hence the recursive code structure.
//
// This test is approximate because it only samples the points listed in alpha.  Listing more points
// will make the test more accurate, but slower.
function _segment_good(path,pathseg_unit,pathseg_len, d, seg,alpha ,index=0) =
    index == len(alpha) ? false :
    _point_dist(path,pathseg_unit,pathseg_len, alpha[index]*seg[0]+(1-alpha[index])*seg[1]) > d ? true :
    _segment_good(path,pathseg_unit,pathseg_len,d,seg,alpha,index+1);


// Input is the path, the path segments normalized to unit length, the length of each path segment
// and a test point.  Computes the (minimum) distance from the path to the point, taking into
// account that the minimal distance may be anywhere along a path segment, not just at the ends.
function _point_dist(path,pathseg_unit,pathseg_len,pt) =
    min([
        for(i=[0:len(pathseg_unit)-1]) let(
            v = pt-path[i],
            projection = v*pathseg_unit[i],
            segdist = projection < 0? norm(pt-path[i]) :
                projection > pathseg_len[i]? norm(pt-select(path,i+1)) :
                norm(v-projection*pathseg_unit[i])
        ) segdist
    ]);


function _offset_region(
    paths, r, delta, chamfer, closed,
    maxstep, check_valid, quality,
    return_faces, firstface_index,
    flip_faces, _acc=[], _i=0
) =
    _i>=len(paths)? _acc :
    _offset_region(
        paths, _i=_i+1,
        _acc = (paths[_i].x % 2 == 0)? (
            union(_acc, [
                offset(
                    paths[_i].y,
                    r=r, delta=delta, chamfer=chamfer, closed=closed,
                    maxstep=maxstep, check_valid=check_valid, quality=quality,
                    return_faces=return_faces, firstface_index=firstface_index,
                    flip_faces=flip_faces
                )
            ])
        ) : (
            difference(_acc, [
                offset(
                    paths[_i].y,
                    r=u_mul(-1,r), delta=u_mul(-1,delta), chamfer=chamfer, closed=closed,
                    maxstep=maxstep, check_valid=check_valid, quality=quality,
                    return_faces=return_faces, firstface_index=firstface_index,
                    flip_faces=flip_faces
                )
            ])
        ),
        r=r, delta=delta, chamfer=chamfer, closed=closed,
        maxstep=maxstep, check_valid=check_valid, quality=quality,
        return_faces=return_faces, firstface_index=firstface_index, flip_faces=flip_faces
    );


// Function: offset()
// Usage:
//   offsetpath = offset(path, [r|delta], [chamfer], [closed], [check_valid], [quality])
//   path_faces = offset(path, return_faces=true, [r|delta], [chamfer], [closed], [check_valid], [quality], [firstface_index], [flip_faces])
// Description:
//   Takes an input path and returns a path offset by the specified amount.  As with the built-in
//   offset() module, you can use `r` to specify rounded offset and `delta` to specify offset with
//   corners.  If you used `delta` you can set `chamfer` to true to get chamfers.
//   Positive offsets shift the path to the left (relative to the direction of the path).
//   .
//   When offsets shrink the path, segments cross and become invalid.  By default `offset()` checks
//   for this situation.  To test validity the code checks that segments have distance larger than (r
//   or delta) from the input path.  This check takes O(N^2) time and may mistakenly eliminate
//   segments you wanted included in various situations, so you can disable it if you wish by setting
//   check_valid=false.  Another situation is that the test is not sufficiently thorough and some
//   segments persist that should be eliminated.  In this case, increase `quality` to 2 or 3.  (This
//   increases the number of samples on the segment that are checked.)  Run time will increase.  In
//   some situations you may be able to decrease run time by setting quality to 0, which causes only
//   segment ends to be checked.
//   .
//   For construction of polyhedra `offset()` can also return face lists.  These list faces between
//   the original path and the offset path where the vertices are ordered with the original path
//   first, starting at `firstface_index` and the offset path vertices appearing afterwords.  The
//   direction of the faces can be flipped using `flip_faces`.  When you request faces the return
//   value is a list: [offset_path, face_list].
// Arguments:
//   path = the path to process.  A list of 2d points.
//   ---
//   r = offset radius.  Distance to offset.  Will round over corners.
//   delta = offset distance.  Distance to offset with pointed corners.
//   chamfer = chamfer corners when you specify `delta`.  Default: false
//   closed = path is a closed curve. Default: False.
//   check_valid = perform segment validity check.  Default: True.
//   quality = validity check quality parameter, a small integer.  Default: 1.
//   return_faces = return face list.  Default: False.
//   firstface_index = starting index for face list.  Default: 0.
//   flip_faces = flip face direction.  Default: false
// Example(2D):
//   star = star(5, r=100, ir=30);
//   #stroke(closed=true, star);
//   stroke(closed=true, offset(star, delta=10, closed=true));
// Example(2D):
//   star = star(5, r=100, ir=30);
//   #stroke(closed=true, star);
//   stroke(closed=true, offset(star, delta=10, chamfer=true, closed=true));
// Example(2D):
//   star = star(5, r=100, ir=30);
//   #stroke(closed=true, star);
//   stroke(closed=true, offset(star, r=10, closed=true));
// Example(2D):
//   star = star(5, r=100, ir=30);
//   #stroke(closed=true, star);
//   stroke(closed=true, offset(star, delta=-10, closed=true));
// Example(2D):
//   star = star(5, r=100, ir=30);
//   #stroke(closed=true, star);
//   stroke(closed=true, offset(star, delta=-10, chamfer=true, closed=true));
// Example(2D):
//   star = star(5, r=100, ir=30);
//   #stroke(closed=true, star);
//   stroke(closed=true, offset(star, r=-10, closed=true));
// Example(2D):  This case needs `quality=2` for success
//   test = [[0,0],[10,0],[10,7],[0,7], [-1,-3]];
//   polygon(offset(test,r=-1.9, closed=true, quality=2));
//   //polygon(offset(test,r=-1.9, closed=true, quality=1));  // Fails with erroneous 180 deg path error
//   %down(.1)polygon(test);
// Example(2D): This case fails if `check_valid=true` when delta is large enough because segments are too close to the opposite side of the curve.  
//   star = star(5, r=22, ir=13);
//   stroke(star,width=.2,closed=true);                                                           
//   color("green")
//     stroke(offset(star, delta=-9, closed=true),width=.2,closed=true); // Works with check_valid=true (the default)
//   color("red")
//     stroke(offset(star, delta=-10, closed=true, check_valid=false),   // Fails if check_valid=true 
//            width=.2,closed=true); 
// Example(2D): But if you use rounding with offset then you need `check_valid=true` when `r` is big enough.  It works without the validity check as long as the offset shape retains a some of the straight edges at the star tip, but once the shape shrinks smaller than that, it fails.  There is no simple way to get a correct result for the case with `r=10`, because as in the previous example, it will fail if you turn on validity checks.  
//   star = star(5, r=22, ir=13);
//   color("green")
//     stroke(offset(star, r=-8, closed=true,check_valid=false), width=.1, closed=true);
//   color("red")
//     stroke(offset(star, r=-10, closed=true,check_valid=false), width=.1, closed=true);
// Example(2D): The extra triangles in this example show that the validity check cannot be skipped
//   ellipse = scale([20,4], p=circle(r=1,$fn=64));
//   stroke(ellipse, closed=true, width=0.3);
//   stroke(offset(ellipse, r=-3, check_valid=false, closed=true), width=0.3, closed=true);
// Example(2D): The triangles are removed by the validity check
//   ellipse = scale([20,4], p=circle(r=1,$fn=64));
//   stroke(ellipse, closed=true, width=0.3);
//   stroke(offset(ellipse, r=-3, check_valid=true, closed=true), width=0.3, closed=true);
// Example(2D): Open path.  The path moves from left to right and the positive offset shifts to the left of the initial red path.
//   sinpath = 2*[for(theta=[-180:5:180]) [theta/4,45*sin(theta)]];
//   #stroke(sinpath);
//   stroke(offset(sinpath, r=17.5));
// Example(2D): Region
//   rgn = difference(circle(d=100), union(square([20,40], center=true), square([40,20], center=true)));
//   #linear_extrude(height=1.1) for (p=rgn) stroke(closed=true, width=0.5, p);
//   region(offset(rgn, r=-5));
function offset(
    path, r=undef, delta=undef, chamfer=false,
    maxstep=0.1, closed=false, check_valid=true,
    quality=1, return_faces=false, firstface_index=0,
    flip_faces=false
) = 
    is_region(path)? (
        assert(!return_faces, "return_faces not supported for regions.")
        let(
            path = [for (p=path) polygon_is_clockwise(p)? p : reverse(p)],
            rgn = exclusive_or([for (p = path) [p]]),
            pathlist = sort(idx=0,[
                for (i=[0:1:len(rgn)-1]) [
                    sum(concat([0],[
                        for (j=[0:1:len(rgn)-1]) if (i!=j)
                            point_in_polygon(rgn[i][0],rgn[j])>=0? 1 : 0
                    ])),
                    rgn[i]
                ]
            ])
        ) _offset_region(
            pathlist, r=r, delta=delta, chamfer=chamfer, closed=true,
            maxstep=maxstep, check_valid=check_valid, quality=quality,
            return_faces=return_faces, firstface_index=firstface_index,
            flip_faces=flip_faces
        )
    ) : let(rcount = num_defined([r,delta]))
    assert(rcount==1,"Must define exactly one of 'delta' and 'r'")
    let(
        chamfer = is_def(r) ? false : chamfer,
        quality = max(0,round(quality)),
        flip_dir = closed && !polygon_is_clockwise(path)? -1 : 1,
        d = flip_dir * (is_def(r) ? r : delta),
        shiftsegs = [for(i=[0:len(path)-1]) _shift_segment(select(path,i,i+1), d)],
        // good segments are ones where no point on the segment is less than distance d from any point on the path
        good = check_valid ? _good_segments(path, abs(d), shiftsegs, closed, quality) : repeat(true,len(shiftsegs)),
        goodsegs = bselect(shiftsegs, good),
        goodpath = bselect(path,good)
    )
    assert(len(goodsegs)>0,"Offset of path is degenerate")
    let(
        // Extend the shifted segments to their intersection points
        sharpcorners = [for(i=[0:len(goodsegs)-1]) _segment_extension(select(goodsegs,i-1), select(goodsegs,i))],
        // If some segments are parallel then the extended segments are undefined.  This case is not handled
        // Note if !closed the last corner doesn't matter, so exclude it
        parallelcheck =
            (len(sharpcorners)==2 && !closed) ||
            all_defined(closed? sharpcorners : list_tail(sharpcorners))
    )
    assert(parallelcheck, "Path contains sequential parallel segments (either 180 deg turn or 0 deg turn")
    let(
        // This is a boolean array that indicates whether a corner is an outside or inside corner
        // For outside corners, the newcorner is an extension (angle 0), for inside corners, it turns backward
        // If either side turns back it is an inside corner---must check both.
        // Outside corners can get rounded (if r is specified and there is space to round them)
        outsidecorner = len(sharpcorners)==2 ? [false,false]
           :
            [for(i=[0:len(goodsegs)-1])
                let(prevseg=select(goodsegs,i-1))
                i==0 && !closed ? false  // In open case first entry is bogus
               :  
                (goodsegs[i][1]-goodsegs[i][0]) * (goodsegs[i][0]-sharpcorners[i]) > 0
                 && (prevseg[1]-prevseg[0]) * (sharpcorners[i]-prevseg[1]) > 0
            ],
        steps = is_def(delta) ? [] : [
            for(i=[0:len(goodsegs)-1])
                        r==0 ? 0 :
            ceil(
                abs(r)*vector_angle(
                    select(goodsegs,i-1)[1]-goodpath[i],
                    goodsegs[i][0]-goodpath[i]
                )*PI/180/maxstep
            )
        ],
        // If rounding is true then newcorners replaces sharpcorners with rounded arcs where needed
        // Otherwise it's the same as sharpcorners
        // If rounding is on then newcorners[i] will be the point list that replaces goodpath[i] and newcorners later
        // gets flattened.  If rounding is off then we set it to [sharpcorners] so we can later flatten it and get
        // plain sharpcorners back.
        newcorners = is_def(delta) && !chamfer ? [sharpcorners] : [
            for(i=[0:len(goodsegs)-1]) (
                (!chamfer && steps[i] <=2)  //Chamfer all points but only round if steps is 3 or more
                || !outsidecorner[i]        // Don't round inside corners
                || (!closed && (i==0 || i==len(goodsegs)-1))  // Don't round ends of an open path
            )? [sharpcorners[i]] : (
                chamfer?
                    _offset_chamfer(
                        goodpath[i], [
                            select(goodsegs,i-1)[1],
                            sharpcorners[i],
                            goodsegs[i][0]
                        ], d
                    ) :
                arc(
                    cp=goodpath[i],
                    points=[
                        select(goodsegs,i-1)[1],
                        goodsegs[i][0]
                    ],
                    N=steps[i]
                )
            )
        ],
        pointcount = (is_def(delta) && !chamfer)?
            repeat(1,len(sharpcorners)) :
            [for(i=[0:len(goodsegs)-1]) len(newcorners[i])],
        start = [goodsegs[0][0]],
        end = [goodsegs[len(goodsegs)-2][1]],
        edges =  closed?
            flatten(newcorners) :
            concat(start,slice(flatten(newcorners),1,-2),end),
        faces = !return_faces? [] :
            _makefaces(
                flip_faces, firstface_index, good,
                pointcount, closed
            )
    ) return_faces? [edges,faces] : edges;


function _tag_subpaths(path, region, eps=EPSILON) =
    let(
        subpaths = split_path_at_region_crossings(path, region, eps=eps),
        tagged = [
            for (sub = subpaths) let(
                subpath = deduplicate(sub)
            ) if (len(sub)>1) let(
                midpt = lerp(subpath[0], subpath[1], 0.5),
                rel = point_in_region(midpt,region,eps=eps)
            ) rel<0? ["O", subpath] : rel>0? ["I", subpath] : let(
                vec = unit(subpath[1]-subpath[0]),
                perp = rot(90, planar=true, p=vec),
                sidept = midpt + perp*0.01,
                rel1 = point_in_polygon(sidept,path,eps=eps)>0,
                rel2 = point_in_region(sidept,region,eps=eps)>0
            ) rel1==rel2? ["S", subpath] : ["U", subpath]
        ]
    ) tagged;


function _tag_region_subpaths(region1, region2, eps=EPSILON) =
    [for (path=region1) each _tag_subpaths(path, region2, eps=eps)];


function _tagged_region(region1,region2,keep1,keep2,eps=EPSILON) =
    let(
        region1 = close_region(region1, eps=eps),
        region2 = close_region(region2, eps=eps),
        tagged1 = _tag_region_subpaths(region1, region2, eps=eps),
        tagged2 = _tag_region_subpaths(region2, region1, eps=eps),
        tagged = concat(
            [for (tagpath = tagged1) if (in_list(tagpath[0], keep1)) tagpath[1]],
            [for (tagpath = tagged2) if (in_list(tagpath[0], keep2)) tagpath[1]]
        ),
        outregion = assemble_path_fragments(tagged, eps=eps)
    ) outregion;



// Function&Module: union()
// Usage:
//   union() {...}
//   region = union(regions);
//   region = union(REGION1,REGION2);
//   region = union(REGION1,REGION2,REGION3);
// Description:
//   When called as a function and given a list of regions, where each region is a list of closed
//   2D paths, returns the boolean union of all given regions.  Result is a single region.
//   When called as the built-in module, makes the boolean union of the given children.
// Arguments:
//   regions = List of regions to union.  Each region is a list of closed paths.
// Example(2D):
//   shape1 = move([-8,-8,0], p=circle(d=50));
//   shape2 = move([ 8, 8,0], p=circle(d=50));
//   for (shape = [shape1,shape2]) color("red") stroke(shape, width=0.5, closed=true);
//   color("green") region(union(shape1,shape2));
function union(regions=[],b=undef,c=undef,eps=EPSILON) =
    b!=undef? union(concat([regions],[b],c==undef?[]:[c]), eps=eps) :
    len(regions)<=1? regions[0] :
    union(
        let(regions=[for (r=regions) quant(is_path(r)? [r] : r, 1/65536)])
        concat(
            [_tagged_region(regions[0],regions[1],["O","S"],["O"], eps=eps)],
            [for (i=[2:1:len(regions)-1]) regions[i]]
        ),
        eps=eps
    );


// Function&Module: difference()
// Usage:
//   difference() {...}
//   region = difference(regions);
//   region = difference(REGION1,REGION2);
//   region = difference(REGION1,REGION2,REGION3);
// Description:
//   When called as a function, and given a list of regions, where each region is a list of closed
//   2D paths, takes the first region and differences away all other regions from it.  The resulting
//   region is returned.
//   When called as the built-in module, makes the boolean difference of the given children.
// Arguments:
//   regions = List of regions to difference.  Each region is a list of closed paths.
// Example(2D):
//   shape1 = move([-8,-8,0], p=circle(d=50));
//   shape2 = move([ 8, 8,0], p=circle(d=50));
//   for (shape = [shape1,shape2]) color("red") stroke(shape, width=0.5, closed=true);
//   color("green") region(difference(shape1,shape2));
function difference(regions=[],b=undef,c=undef,eps=EPSILON) =
    b!=undef? difference(concat([regions],[b],c==undef?[]:[c]), eps=eps) :
    len(regions)<=1? regions[0] :
    difference(
        let(regions=[for (r=regions) quant(is_path(r)? [r] : r, 1/65536)])
        concat(
            [_tagged_region(regions[0],regions[1],["O","U"],["I"], eps=eps)],
            [for (i=[2:1:len(regions)-1]) regions[i]]
        ),
        eps=eps
    );


// Function&Module: intersection()
// Usage:
//   intersection() {...}
//   region = intersection(regions);
//   region = intersection(REGION1,REGION2);
//   region = intersection(REGION1,REGION2,REGION3);
// Description:
//   When called as a function, and given a list of regions, where each region is a list of closed
//   2D paths, returns the boolean intersection of all given regions.  Result is a single region.
//   When called as the built-in module, makes the boolean intersection of all the given children.
// Arguments:
//   regions = List of regions to intersection.  Each region is a list of closed paths.
// Example(2D):
//   shape1 = move([-8,-8,0], p=circle(d=50));
//   shape2 = move([ 8, 8,0], p=circle(d=50));
//   for (shape = [shape1,shape2]) color("red") stroke(shape, width=0.5, closed=true);
//   color("green") region(intersection(shape1,shape2));
function intersection(regions=[],b=undef,c=undef,eps=EPSILON) =
    b!=undef? intersection(concat([regions],[b],c==undef?[]:[c]),eps=eps) :
    len(regions)<=1? regions[0] :
    intersection(
        let(regions=[for (r=regions) quant(is_path(r)? [r] : r, 1/65536)])
        concat(
            [_tagged_region(regions[0],regions[1],["I","S"],["I"],eps=eps)],
            [for (i=[2:1:len(regions)-1]) regions[i]]
        ),
        eps=eps
    );


// Function&Module: exclusive_or()
// Usage:
//   exclusive_or() {...}
//   region = exclusive_or(regions);
//   region = exclusive_or(REGION1,REGION2);
//   region = exclusive_or(REGION1,REGION2,REGION3);
// Description:
//   When called as a function and given a list of regions, where each region is a list of closed
//   2D paths, returns the boolean exclusive_or of all given regions.  Result is a single region.
//   When called as a module, performs a boolean exclusive-or of up to 10 children.
// Arguments:
//   regions = List of regions to exclusive_or.  Each region is a list of closed paths.
// Example(2D): As Function
//   shape1 = move([-8,-8,0], p=circle(d=50));
//   shape2 = move([ 8, 8,0], p=circle(d=50));
//   for (shape = [shape1,shape2])
//       color("red") stroke(shape, width=0.5, closed=true);
//   color("green") region(exclusive_or(shape1,shape2));
// Example(2D): As Module
//   exclusive_or() {
//       square(40,center=false);
//       circle(d=40);
//   }
function exclusive_or(regions=[],b=undef,c=undef,eps=EPSILON) =
    b!=undef? exclusive_or(concat([regions],[b],c==undef?[]:[c]),eps=eps) :
    len(regions)<=1? regions[0] :
    exclusive_or(
        let(regions=[for (r=regions) is_path(r)? [r] : r])
        concat(
            [union([
                difference([regions[0],regions[1]], eps=eps),
                difference([regions[1],regions[0]], eps=eps)
            ], eps=eps)],
            [for (i=[2:1:len(regions)-1]) regions[i]]
        ),
        eps=eps
    );


module exclusive_or() {
    if ($children==1) {
        children();
    } else if ($children==2) {
        difference() {
            children(0);
            children(1);
        }
        difference() {
            children(1);
            children(0);
        }
    } else if ($children==3) {
        exclusive_or() {
            exclusive_or() {
                children(0);
                children(1);
            }
            children(2);
        }
    } else if ($children==4) {
        exclusive_or() {
            exclusive_or() {
                children(0);
                children(1);
            }
            exclusive_or() {
                children(2);
                children(3);
            }
        }
    } else if ($children==5) {
        exclusive_or() {
            exclusive_or() {
                children(0);
                children(1);
                children(2);
                children(3);
            }
            children(4);
        }
    } else if ($children==6) {
        exclusive_or() {
            exclusive_or() {
                children(0);
                children(1);
                children(2);
                children(3);
            }
            children(4);
            children(5);
        }
    } else if ($children==7) {
        exclusive_or() {
            exclusive_or() {
                children(0);
                children(1);
                children(2);
                children(3);
            }
            children(4);
            children(5);
            children(6);
        }
    } else if ($children==8) {
        exclusive_or() {
            exclusive_or() {
                children(0);
                children(1);
                children(2);
                children(3);
            }
            exclusive_or() {
                children(4);
                children(5);
                children(6);
                children(7);
            }
        }
    } else if ($children==9) {
        exclusive_or() {
            exclusive_or() {
                children(0);
                children(1);
                children(2);
                children(3);
            }
            exclusive_or() {
                children(4);
                children(5);
                children(6);
                children(7);
            }
            children(8);
        }
    } else if ($children==10) {
        exclusive_or() {
            exclusive_or() {
                children(0);
                children(1);
                children(2);
                children(3);
            }
            exclusive_or() {
                children(4);
                children(5);
                children(6);
                children(7);
            }
            children(8);
            children(9);
        }
    } else {
        assert($children<=10, "exclusive_or() can only handle up to 10 children.");
    }
}


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
