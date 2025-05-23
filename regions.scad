//////////////////////////////////////////////////////////////////////
// LibFile: regions.scad
//   This file provides 2D Boolean set operations on polygons, where you can
//   compute, for example, the intersection or union of the shape defined by point lists, producing
//   a new point list.  Of course, such operations may produce shapes with multiple
//   components.  To handle that, we use "regions", which are lists of paths representing the polygons.
//   In addition to set operations, you can calculate offsets, determine whether a point is in a
//   region and you can decompose a region into parts.  
// Includes:
//   include <BOSL2/std.scad>
// FileGroup: Advanced Modeling
// FileSummary: Offsets and Boolean geometry of 2D paths and regions.
// FileFootnotes: STD=Included in std.scad
//////////////////////////////////////////////////////////////////////


// CommonCode:
//   include <BOSL2/rounding.scad>


// Section: Regions
//   A {{region}} is a list of polygons meeting these conditions:
//   .
//   - Every polygon on the list is simple, meaning it does not intersect itself
//   - Two polygons on the list do not cross each other
//   - A vertex of one polygon never meets the edge of another one except at a vertex
//   .
//   This means vertex-vertex touching between two polygons is acceptable
//   to define a region.  Note, however, that regions with vertex-vertex contact usually
//   cannot be rendered with CGAL.  See {{is_valid_region()}} for examples of valid regions and
//   lists of polygons that are not regions. Note that {{is_region_simple()}} identifies
//   regions with no polygon intersections at all, which should render successfully witih CGAL.  
//   .
//   The actual geometry of the region is defined by XORing together
//   all of the polygons in the list.  This may sound obscure, but it simply means that nested
//   boundaries make rings in the obvious fashion, and non-nested shapes simply union together.
//   Checking that a list of polygons is a valid region, meaning that it satisfies all of the conditions
//   above, can be a time consuming test, so it is not done automatically.  It is your responsibility to ensure that your regions are
//   compliant.  You can construct regions by making a suitable list of polygons, or by using
//   set operation function such as {{union()}} or {{difference()}}, which all acccept polygons, as
//   well as regions, as their inputs. If you must, you can clean up an ill-formed region using
//   {{make_region()}}, which breaks up self-intersecting polygons and polygons that cross each other.
//
// Figure(2D): An Sample {{Region}}
//   path1 = union([
//       circle(d=100),
//       translate([50,20], p=circle(d=40))
//   ])[0];
//   rgn = [
//       // Main shape
//       select(path1, hull(path1)),
//       translate([50,20], p=circle(d=20)),
//       rot(-8, p=hexagon(d=60, rounding=10)),
//       // Inner disjointed shape
//       circle(d=25),
//       rot(30-8, p=rect(10)),
//       // External disjoined shape
//       each translate([60,-25], p=rot(55, p=[
//           rect([20,15], rounding=5),
//           ellipse([6,3])
//       ])),
//   ];
//   region(rgn);
//

// Definitions:
//   Region|Regions = A list of one or more non-intersecting {{polygons}} representing a union of one or more disconnected polygons that may have internal holes.

// Function: is_region()
// Synopsis: Returns true if the input appears to be a {{region}}.
// Topics: Regions, Paths, Polygons, List Handling
// See Also: is_valid_region(), is_1region(), is_region_simple()
// Usage:
//   bool = is_region(x);
// Description:
//   Returns true if the given item looks like a {{region}}.  A region is a list of non-crossing simple {{polygons}}.  This test just checks
//   that the argument is a list whose first entry is a path.  
function is_region(x) = is_list(x) && is_path(x.x);


// Function: is_valid_region()
// Synopsis: Returns true if the input is a valid {{region}}.
// Topics: Regions, Paths, Polygons, List Handling
// See Also: is_region(), is_1region(), is_region_simple()
// Usage:
//   bool = is_valid_region(region, [eps]);
// Description:
//   Returns true if the input is a valid {{region}}, meaning that it is a list of simple {{polygons}} whose segments do not cross each other.
//   This test can be time consuming with regions that contain many {{points}}.
//   It differs from `is_region()`, which simply checks that the object is a list whose first entry is a path
//   because it searches all the list polygons for any self-intersections or intersections with each other.  
//   Also returns true if given a single simple polygon.  Use {{make_region()}} to convert sets of self-intersecting polygons into
//   a region.  
// Arguments:
//   region = region to check
//   eps = tolerance for geometric comparisons.  Default: `EPSILON` = 1e-9
// Example(2D,NoAxes):  In all of the examples each polygon in the region appears in a different color.  Two non-intersecting squares make a valid region.
//   region = [square(10), right(11,square(8))];
//   rainbow(region)stroke($item, width=.2,closed=true);
//   back(11)text(is_valid_region(region) ? "region" : "non-region", size=2);
// Example(2D,NoAxes):  Nested squares form a region
//   region = [for(i=[3:2:10]) square(i,center=true)];
//   rainbow(region)stroke($item, width=.2,closed=true);
//   back(6)text(is_valid_region(region) ? "region" : "non-region", size=2,halign="center");
// Example(2D,NoAxes):  Also a region:
//   region= [square(10,center=true), square(5,center=true), right(10,square(7))];
//   rainbow(region)stroke($item, width=.2,closed=true);
//   back(8)text(is_valid_region(region) ? "region" : "non-region", size=2);
// Example(2D,NoAxes):  The squares cross each other, so not a region
//   object = [square(10), move([8,8], square(8))];
//   rainbow(object)stroke($item, width=.2,closed=true);
//   back(17)text(is_valid_region(object) ? "region" : "non-region", size=2);
// Example(2D,NoAxes): A union is one way to fix the above example and get a region. Union is run here on two simple polygons, which are valid regions themselves and hence acceptable inputs to union.
//   region = union([square(10), move([8,8], square(8))]);
//   rainbow(region)stroke($item, width=.25,closed=true);
//   back(12)text(is_valid_region(region) ? "region" : "non-region", size=2);
// Example(2D,NoAxes):  Not a region due to a self-intersecting (non-simple) hourglass polygon
//   object = [move([-2,-2],square(14)), [[0,0],[10,0],[0,10],[10,10]]];
//   rainbow(object)stroke($item, width=.2,closed=true);
//   move([-1.5,13])text(is_valid_region(object) ? "region" : "non-region", size=2);
// Example(2D,NoAxes):  Breaking hourglass in half fixes it.  Now it's a region:
//   region = [move([-2,-2],square(14)), [[0,0],[10,0],[5,5]], [[5,5],[0,10],[10,10]]];
//   rainbow(region)stroke($item, width=.2,closed=true);
// Example(2D,NoAxes):  A single polygon corner touches an edge, so not a region:
//   object = [[[-10,0], [-10,10], [20,10], [20,-20], [-10,-20],
//              [-10,-10], [0,0], [10,-10], [10,0]]];
//   rainbow(object)stroke($item, width=.3,closed=true);
//   move([-4,12])text(is_valid_region(object) ? "region" : "non-region", size=3);
// Example(2D,NoAxes):  Corners touch in the same polygon, so the polygon is not simple and the object is not a region.
//   object = [[[0,0],[10,0],[10,10],[-10,10],[-10,0],[0,0],[-5,5],[5,5]]];
//   rainbow(object)stroke($item, width=.3,closed=true);
//   move([-10,12])text(is_valid_region(object) ? "region" : "non-region", size=3);
// Example(2D,NoAxes):  The shape above as a valid region with two polygons:
//   region = [  [[0,0],[10,0],[10,10],[-10,10],[-10,0]],
//               [[0,0],[5,5],[-5,5]]  ];
//   rainbow(region)stroke($item, width=.3,closed=true);
//   move([-5.5,12])text(is_valid_region(region) ? "region" : "non-region", size=3);
// Example(2D,NoAxes):  As with the "broken" hourglass, Touching at corners is OK.  This is a region.
//   region = [square(10), move([10,10], square(8))];
//   rainbow(region)stroke($item, width=.25,closed=true);
//   back(12)text(is_valid_region(region) ? "region" : "non-region", size=2);
// Example(2D,NoAxes): These two squares share part of an edge, hence not a region
//   object = [square(10), move([10,2], square(7))];
//   stroke(object[0], width=0.2,closed=true);
//   color("red")dashed_stroke(object[1], width=0.25,closed=true);
//   back(12)text(is_valid_region(object) ? "region" : "non-region", size=2);
// Example(2D,NoAxes): These two squares share a full edge, hence not a region
//   object = [square(10), right(10, square(10))];
//   stroke(object[0], width=0.2,closed=true);
//   color("red")dashed_stroke(object[1], width=0.25,closed=true);
//   back(12)text(is_valid_region(object) ? "region" : "non-region", size=2);
// Example(2D,NoAxes): Sharing on edge on the inside, also not a regionn
//   object = [square(10), [[0,0], [2,2],[2,8],[0,10]]];
//   stroke(object[0], width=0.2,closed=true);
//   color("red")dashed_stroke(object[1], width=0.25,closed=true);
//   back(12)text(is_valid_region(object) ? "region" : "non-region", size=2);
// Example(2D,NoAxes): Crossing at vertices is also bad
//   object = [square(10), [[10,0],[0,10],[8,13],[13,8]]];
//   rainbow(object)stroke($item, width=.2,closed=true);
//   back(14)text(is_valid_region(object) ? "region" : "non-region", size=2);
// Example(2D,NoAxes): One polygon touches another in the middle of an edge
//   object = [square(10), [[10,5],[15,0],[15,10]]];
//   rainbow(object)stroke($item, width=.2,closed=true);
//   back(11)text(is_valid_region(object) ? "region" : "non-region", size=2);
// Example(2D,NoAxes): The polygon touches the side, but the side has a vertex at the contact point so this is a region
//   poly1 = [ each square(30,center=true), [15,0]];
//   poly2 = right(10,circle(5,$fn=4));
//   poly3 = left(0,circle(5,$fn=4));
//   poly4 = move([0,-8],square([10,3]));
//   region = [poly1,poly2,poly3,poly4];
//   rainbow(region)stroke($item, width=.25,closed=true);
//   move([-5,16.5])text(is_valid_region(region) ? "region" : "non-region", size=3);
//   color("black")move_copies(region[0]) circle(r=.4);
// Example(2D,NoAxes): The polygon touches the side, but not at a vertex so this is not a region
//   poly1 = fwd(4,[ each square(30,center=true), [15,0]]);
//   poly2 = right(10,circle(5,$fn=4));
//   poly3 = left(0,circle(5,$fn=4));
//   poly4 = move([0,-8],square([10,3]));
//   object = [poly1,poly2,poly3,poly4];
//   rainbow(object)stroke($item, width=.25,closed=true);
//   move([-9,12.5])text(is_valid_region(object) ? "region" : "non-region", size=3);
//   color("black")move_copies(object[0]) circle(r=.4);
// Example(2D,NoAxes): The inner polygon touches the middle of the edges, so not a region
//   poly1 = square(20,center=true);
//   poly2 = circle(10,$fn=8);
//   object=[poly1,poly2];
//   rainbow(object)stroke($item, width=.25,closed=true);
//   move([-10,11.4])text(is_valid_region(object) ? "region" : "non-region", size=3);
// Example(2D,NoAxes): The above shape made into a region using {{difference()}} now has four components that touch at corners
//   poly1 = square(20,center=true);
//   poly2 = circle(10,$fn=8);
//   region = difference(poly1,poly2);
//   rainbow(region)stroke($item, width=.25,closed=true);
//   move([-5,11.4])text(is_valid_region(region) ? "region" : "non-region", size=3);
function is_valid_region(region, eps=EPSILON) =
   let(region=force_region(region))
   assert(is_region(region), "\nInput is not a region.")
   // no short paths
   [for(p=region) if (len(p)<3) 1] == []
   &&
   // all paths are simple
   [for(p=region) if (!is_path_simple(p,closed=true,eps=eps)) 1] == []
   &&
   // paths do not cross each other
   [for(i=[0:1:len(region)-2])
            if (_polygon_crosses_region(list_tail(region,i+1),region[i], eps=eps)) 1] == []
   &&
   // one path doesn't touch another in the middle of an edge
   [for(i=idx(region), j=idx(region))
       if (i!=j) for(v=region[i], edge=pair(region[j],wrap=true))
           let(
               v1 = edge[1]-edge[0],
               v0 = v - edge[0],
               t = v0*v1/(v1*v1)
           )
           if (abs(cross(v0,v1))<eps*norm(v1) && t>eps && t<1-eps) 1
   ]==[];



// internal function:
// returns true if the polygon crosses the region so that part of the 
// polygon is inside the region and part is outside.  
function _polygon_crosses_region(region, poly, eps=EPSILON) =
    let(  
        subpaths = flatten(split_region_at_region_crossings(region,[poly],eps=eps)[1])
    )
    [for(path=subpaths)
      let(isect=
         [for (subpath = subpaths)
          let(
                midpt = mean([subpath[0], subpath[1]]),
                rel = point_in_region(midpt,region,eps=eps)
          )
          rel
         ])
       if (!all_equal(isect) || isect[0]==0) 1 ] != [];


// Function: is_region_simple()
// Synopsis: Returns true if the input is a region with no corner contact.
// Topics: Regions, Paths, Polygons, List Handling
// See Also: is_region(), is_valid_region(), is_1region()
// Usage:
//   bool = is_region_simple(region, [eps]);
// Description:
//   We extend the notion of the simple {{path}} to {{regions}}: a simple region is entirely
//   non-self-intersecting, meaning that it is formed from a list of simple polygons that
//   don't intersect each other at all&mdash;not even with corner contact points.
//   Regions with corner contact are valid but may fail CGAL.  Simple regions
//   should not create problems with CGAL.  
// Arguments:
//   region = region to check
//   eps = tolerance for geometric comparisons.  Default: `EPSILON` = 1e-9
// Example(2D,NoAxes):  Corner contact means it's not simple
//   region = [move([-2,-2],square(14)), [[0,0],[10,0],[5,5]], [[5,5],[0,10],[10,10]]];
//   rainbow(region)stroke($item, width=.2,closed=true);
//   move([-1,13])text(is_region_simple(region) ? "simple" : "not-simple", size=2);
// Example(2D,NoAxes):  Moving apart the triangles makes it simple:
//   region = [move([-2,-2],square(14)), [[0,0],[10,0],[5,4.5]], [[5,5.5],[0,10],[10,10]]];
//   rainbow(region)stroke($item, width=.2,closed=true);
//   move([1,13])text(is_region_simple(region) ? "simple" : "not-simple", size=2);
function is_region_simple(region, eps=EPSILON) =
   let(region=force_region(region))
   assert(is_region(region), "\nInput is not a region.")
   [for(p=region) if (!is_path_simple(p,closed=true,eps=eps)) 1] == []
   &&
   [for(i=[0:1:len(region)-2])
       if (_region_region_intersections([region[i]], list_tail(region,i+1), eps=eps)[0][0] != []) 1
   ] ==[];
  
  
// Function: make_region()
// Synopsis: Converts lists of intersecting {{polygons}} into valid {{regions}}.
// SynTags: Region
// Topics: Regions, Paths, Polygons, List Handling
// See Also: force_region(), region()
// 
// Usage:
//   region = make_region(polys, [nonzero], [eps]);
// Description:
//   Takes a list of {{polygons}} that may intersect themselves or cross each other 
//   and converts it into a properly defined {{region}} without these defects.
// Arguments:
//   polys = list of polygons to use
//   nonzero = set to true to use nonzero rule for polygon membership.  Default: false
//   eps = Epsilon for geometric comparisons.  Default: `EPSILON` (1e-9)
// Example(2D,NoAxes):  The pentagram is self-intersecting, so it is not a region.  Here it becomes five triangles:
//   pentagram = turtle(["move",100,"left",144], repeat=4);
//   region = make_region(pentagram);
//   rainbow(region)stroke($item, width=1,closed=true);
// Example(2D,NoAxes):  Alternatively with the nonzero option you can get the perimeter:
//   pentagram = turtle(["move",100,"left",144], repeat=4);
//   region = make_region(pentagram,nonzero=true);
//   rainbow(region)stroke($item, width=1,closed=true);
// Example(2D,NoAxes):  Two crossing squares become two L-shaped components
//   region = make_region([square(10), move([5,5],square(8))]);
//   rainbow(region)stroke($item, width=.3,closed=true);

function make_region(polys,nonzero=false,eps=EPSILON) =
     let(polys=force_region(polys))
     assert(is_region(polys), "\nInput is not a region.")
     exclusive_or(
                  [for(poly=polys) each polygon_parts(poly,nonzero,eps)],
                  eps=eps);

// Function: force_region()
// Synopsis: Given a polygon returns a region.
// SynTags: Region
// Topics: Regions, Paths, Polygons, List Handling
// See Also: make_region(), region()
// Usage:
//   region = force_region(poly)
// Description:
//   If the input is a polygon then return it as a region.  Otherwise return it unaltered.
// Arguments:
//   poly = polygon to turn into a region
function force_region(poly) = is_path(poly) ? [poly] : poly;


// Section: Turning a region into geometry

// Module: region()
// Synopsis: Creates the 2D {{polygons}} described by the given {{region}} or list of polygons.
// SynTags: Geom
// Topics: Regions, Paths, Polygons, List Handling
// See Also: make_region(), debug_region()
// Usage:
//   region(r, [anchor], [spin=], [cp=], [atype=]) [ATTACHMENTS];
// Description:
//   Creates the 2D {{polygons}} described by the given {{region}} or list of polygons.  This module works on
//   arbitrary lists of polygons that cross each other and hence do not define a valid region.  The
//   displayed result is the exclusive-or of the polygons listed in the input. 
// Arguments:
//   r = region to create as geometry
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `"origin"`
//   ---
//   spin = Rotate this many degrees after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   cp = Centerpoint for determining intersection anchors or centering the shape.  Determintes the base of the anchor vector.  Can be "centroid", "mean", "box" or a 2D point.  Default: "centroid"
//   atype = Set to "hull" or "intersect" to select anchor type.  Default: "hull"
// Named Anchors:
//   "origin" = The native position of the region.
// Anchor Types:
//   "hull" = Anchors to the virtual convex hull of the region.
//   "intersect" = Anchors to the outer edge of the region.
// Example(2D): Displaying a region
//   region([circle(d=50), square(25,center=true)]);
// Example(2D): Displaying a list of polygons that intersect each other, which is not a region.
//   rgn = concat(
//       [for (d=[50:-10:10]) circle(d=d-5)],
//       [square([60,10], center=true)]
//   );
//   region(rgn);
module region(r, anchor="origin", spin=0, cp="centroid", atype="hull")
{
    assert(in_list(atype, _ANCHOR_TYPES), "\nAnchor type must be \"hull\" or \"intersect\".");
    r = force_region(r);
    dummy=assert(is_region(r), "\nInput is not a region.");
    points = flatten(r);
    lengths = [for(path=r) len(path)];
    starts = [0,each cumsum(lengths)];
    paths = [for(i=idx(r)) count(s=starts[i], n=lengths[i])];
    attachable(anchor, spin, two_d=true, region=r, extent=atype=="hull", cp=cp){
      polygon(points=points, paths=paths);
      children();
    }
}



// Module: debug_region()
// Synopsis: Draws an annotated {{region}}.
// SynTags: Geom
// Topics: Shapes (2D)
// See Also: region(), debug_polygon(), debug_vnf(), debug_bezier()
//
// Usage:
//   debug_region(region, [vertices=], [edges=], [convexity=], [size=]);
// Description:
//   A replacement for {{region()}} that displays the {{region}} and labels the vertices and
//   edges.  The region vertices and edges are labeled with letters to identify the path
//   component in the region, starting with A.  
//   The start of each path is marked with a blue circle and the end with a pink diamond.
//   You can suppress the display of vertex or edge labeling using the `vertices` and `edges` arguments.
// Arguments:
//   region = region to display
//   ---
//   vertices = if true display vertex labels and start/end markers.  Default: true
//   edges = if true display edge labels.  Default: true
//   convexity = The max number of walls a ray can pass through the given polygon paths.
//   size = The base size of the line and labels.
// Example(2D,Big):
//   region = make_region([square(15), move([5,5],square(15))]);
//   debug_region(region,size=1);
module debug_region(region, vertices=true, edges=true, convexity=2, size=1)
{
  
  if (is_path(region) || (is_region(region) && len(region)==1))
    debug_polygon(force_path(region), vertices=vertices, edges=edges, convexity=convexity, size=size);
  else {
    for(i=idx(region))
      echo(str("points_",chr(97+i)," = ",region[i]))
    linear_extrude(height=0.01, convexity=convexity, center=true) 
      region(region);
    if(vertices)
        _debug_poly_verts(region,size);
    for(j=idx(region)){
      if(edges)
        _debug_poly_edges(j,region[j],vertices=vertices,size=size);
    }      
  }      
}



// Section: Geometrical calculations with regions

// Function: point_in_region()
// Synopsis: Tests if a point is inside, outside, or on the border of a {{region}}. 
// Topics: Regions, Points, Comparison
// See Also: region_area(), are_regions_equal()
// Usage:
//   check = point_in_region(point, region, [eps]);
// Description:
//   Tests if a point is inside, outside, or on the border of a {{region}}.  
//   Returns -1 if the point is outside the region.
//   Returns 0 if the point is on the boundary.
//   Returns 1 if the point lies inside the region.
// Arguments:
//   point = The point to test.
//   region = The region to test against, as a list of polygon paths.
//   eps = Acceptable variance.  Default: `EPSILON` (1e-9)
// Example(2D,Med):  Red points are in the region.
//   region = [for(i=[2:4:10]) hexagon(r=i)];
//   color("#ff7") region(region);
//   for(x=[-10:10], y=[-10:10])
//     if (point_in_region([x,y], region)>=0)
//       move([x,y]) color("red") circle(0.15, $fn=12);
//     else
//       move([x,y]) color("#ddf") circle(0.1, $fn=12);
function point_in_region(point, region, eps=EPSILON) =
    let(region=force_region(region))
    assert(is_region(region), "\nRegion given to point_in_region is not a region.")
    assert(is_vector(point,2), "\nPoint must be a 2D point in point_in_region.")
    _point_in_region(point, region, eps);

function _point_in_region(point, region, eps=EPSILON, i=0, cnt=0) =
      i >= len(region) ? ((cnt%2==1)? 1 : -1)
    : let(
          pip = point_in_polygon(point, region[i], eps=eps)
      )
      pip == 0 ? 0
   : _point_in_region(point, region, eps=eps, i=i+1, cnt = cnt + (pip>0? 1 : 0));


// Function: region_area()
// Synopsis: Computes the area of the specified valid {{region}}.
// Topics: Regions, Area
// Usage:
//   area = region_area(region);
// Description:
//   Computes the area of the specified valid {{region}}. (If the region is invalid and has self intersections
//   the result is meaningless.)
// Arguments:
//   region = region whose area to compute
// Examples:
//   area = region_area([square(10), right(20,square(8))]);  // Returns 164
function region_area(region) =
  assert(is_region(region), "\nInput must be a region.")
  let(
      parts = region_parts(region)
  )
  -sum([for(R=parts, poly=R) polygon_area(poly,signed=true)]);



function _clockwise_region(r) = [for(p=r) clockwise_polygon(p)];

// Function: are_regions_equal()
// Synopsis: Returns true if given regions are the same polygons.
// Topics: Regions, Polygons, Comparison
// Usage:
//    b = are_regions_equal(region1, region2, [either_winding])
// Description:
//    Returns true if the components of region1 and region2 are the same polygons (in any order). 
// Arguments:
//    region1 = first region
//    region2 = second region
//    either_winding = if true then two shapes test equal if they wind in opposite directions.  Default: false
function are_regions_equal(region1, region2, either_winding=false) =
    let(
        region1=force_region(region1),
        region2=force_region(region2)
    )
    assert(is_region(region1) && is_region(region2), "\nOne of the inputs is not a region.")
    len(region1) != len(region2)? false :
    __are_regions_equal(either_winding?_clockwise_region(region1):region1,
                        either_winding?_clockwise_region(region2):region2,
                        0);

function __are_regions_equal(region1, region2, i) =
    i >= len(region1)? true :
    !_is_polygon_in_list(region1[i], region2)? false :
    __are_regions_equal(region1, region2, i+1);


/// Internal Function: _region_region_intersections()
/// Usage:
///    risect = _region_region_intersections(region1, region2, [closed1], [closed2], [eps]
/// Description:
///    Returns a pair of sorted lists such that risect[0] is a list of intersection
///    points for every path in region1, and similarly risect[1] is a list of intersection
///    points for the paths in region2.  For each path the intersection list is
///    a sorted list of the form [PATHIND, SEGMENT, U].  You can specify that the paths in either
///    region be regarded as open paths if desired.  Default is to treat them as
///    regions and hence the paths as closed polygons.
///    .
///    Included as intersection points are points where region1 touches itself at a vertex or
///    region2 touches itself at a vertex.  (The paths are assumed to have no self crossings.
///    Self crossings of the paths in the regions are not returned.)
function _region_region_intersections(region1, region2, closed1=true,closed2=true, eps=EPSILON) =
   let(
       intersections =   [
           for(p1=idx(region1))
              let(
                  path = closed1?list_wrap(region1[p1]):region1[p1]
              )
              for(i = [0:1:len(path)-2])
                  let(
                      a1 = path[i],
                      a2 = path[i+1],
                      nrm = norm(a1-a2)
                  )
                  if( nrm>eps )  // ignore zero-length path edges
                       let( 
                           seg_normal = [-(a2-a1).y, (a2-a1).x]/nrm,
                           ref = a1*seg_normal
                       )
                           // `signs[j]` is the sign of the signed distance from
                           // poly vertex j to the line [a1,a2] where near zero
                           // distances are snapped to zero;  poly edges 
                           //  with equal signs at its vertices cannot intersect
                           // the path edge [a1,a2] or they are collinear and 
                           // further tests can be discarded.
                       for(p2=idx(region2))
                           let(
                               poly  = closed2?list_wrap(region2[p2]):region2[p2],
                               signs = [for(v=poly*seg_normal) abs(v-ref) < eps ? 0 : sign(v-ref) ]
                           ) 
                           if(max(signs)>=0 && min(signs)<=0) // some edge intersects line [a1,a2]
                               for(j=[0:1:len(poly)-2]) 
                                   if(signs[j]!=signs[j+1])
                                        let( // exclude non-crossing and collinear segments
                                            b1 = poly[j],
                                            b2 = poly[j+1],
                                            isect = _general_line_intersection([a1,a2],[b1,b2],eps=eps) 
                                        )
                                        if (isect 
                                            && isect[1]>= -eps 
                                            && isect[1]<= 1+eps 
                                            && isect[2]>= -eps
                                            && isect[2]<= 1+eps)       
                                         [[p1,i,isect[1]], [p2,j,isect[2]]]
         ],
         regions=[region1,region2],
         // Create a flattened index list corresponding to the points in region1 and region2
         // that gives each point as an intersection point
         ptind = [for(i=[0:1])   
                    [for(p=idx(regions[i]))
                       for(j=idx(regions[i][p])) [p,j,0]]],
         points = [for(i=[0:1]) flatten(regions[i])],
         // Corner points are those points where the region touches itself, hence duplicate
         // points in the region's point set
         cornerpts = [for(i=[0:1])
                         [for(k=vector_search(points[i],eps,points[i]))
                             each if (len(k)>1) select(ptind[i],k)]],
         risect = [for(i=[0:1]) concat(column(intersections,i), cornerpts[i])],
         counts = [count(len(region1)), count(len(region2))],
         pathind = [for(i=[0:1]) search(counts[i], risect[i], 0)]
       )
       [for(i=[0:1]) [for(j=counts[i]) _sort_vectors(select(risect[i],pathind[i][j]))]];
         

// Section: Breaking up regions into subregions


// Function: split_region_at_region_crossings()
// Synopsis: Splits {{regions}} where {{polygons}} touch and at intersections.
// Topics: Regions, Polygons, List Handling
// See Also: region_parts()
// 
// Usage:
//   split_region = split_region_at_region_crossings(region1, region2, [closed1], [closed2], [eps])
// Description:
//   Splits the {{region} `region1` at the places where its {{polygons}} touches each other at corners and at locations
//   where `region1` intersects `region2`.  Split `region2` similarly with respect to `region1`.
//   The return is a pair of results of the form [split1, split2] where split1=[frags1,frags2,...]
//   and frags1 is a list of paths that when placed end to end (in the given order), give the first polygon of region1.
//   Each path in the list is either entirely inside or entirely outside region2.  
//   Then frags2 is the decomposition of the second polygon into path pieces, and so on.  Finally split2 is
//   the same list, but for the polygons in region2.  
//   You can pass a single polygon in for either region, but the output will be a singleton list, as if
//   you passed in a singleton region.  If you set the closed parameters to false then the region components
//   are treated as open paths instead of polygons.  
// Arguments:
//   region1 = first region
//   region2 = second region
//   closed1 = if false then treat region1 as list of open paths.  Default: true
//   closed2 = if false then treat region2 as list of open paths.  Default: true
//   eps = Acceptable variance.  Default: `EPSILON` (1e-9)
// Example(2D): 
//   path = square(50,center=false);
//   region = [circle(d=80), circle(d=40)];
//   paths = split_region_at_region_crossings(path, region);
//   color("#aaa") region(region);
//   rainbow(paths[0][0]) stroke($item, width=2);
//   right(110){
//     color("#aaa") region([path]);
//     rainbow(flatten(paths[1])) stroke($item, width=2);
//   }
function split_region_at_region_crossings(region1, region2, closed1=true, closed2=true, eps=EPSILON) = 
    let(
        region1=force_region(region1),
        region2=force_region(region2)
    )
    assert(is_region(region1) && is_region(region2),"\nOne of the inputs is not a region.")
    let(
        xings = _region_region_intersections(region1, region2, closed1, closed2, eps),
        regions = [region1,region2],
        closed = [closed1,closed2]
    )
    [for(i=[0:1])
      [for(p=idx(xings[i]))
        let(
            crossings = deduplicate([
                                     [p,0,0],
                                     each xings[i][p],
                                     [p,len(regions[i][p])-(closed[i]?1:2), 1],
                                    ],eps=eps),
            subpaths = [
                for (frag = pair(crossings)) 
                    deduplicate(
                        _path_select(regions[i][p], frag[0][1], frag[0][2], frag[1][1], frag[1][2], closed=closed[i]),
                        eps=eps
                    )
            ]
        )
        [for(s=subpaths) if (len(s)>1) s]
       ]
    ];
                
                

// Function: region_parts()
// Synopsis: Splits a {{region}} into a list of connected regions.
// SynTags: RegList
// Topics: Regions, List Handling
// See Also: split_region_at_region_crossings()
// Usage:
//   rgns = region_parts(region);
// Description:
//   Divides a {{region}} into a list of connected regions.  Each connected region has exactly one clockwise outside boundary
//   and zero or more counter-clockwise outlines defining internal holes. Behavior is undefined on invalid regions whose
//   components cross each other.
// Example(2D,NoAxes):
//   R = [for(i=[1:7]) square(i,center=true)];
//   region_list = region_parts(R);
//   rainbow(region_list) region($item);
// Example(2D,NoAxes):
//   R = [back(7,square(3,center=true)),
//        square([20,10],center=true),
//        left(5,square(8,center=true)),
//        for(i=[4:2:8])
//          right(5,square(i,center=true))];
//   region_list = region_parts(R);
//   rainbow(region_list) region($item);
function region_parts(region) =
   let(
       region = force_region(region)
   )
   assert(is_region(region), "\nInput is not a region.")
   let(
       inside = [for(i=idx(region))
                    let(pt = mean([region[i][0], region[i][1]]))
                    [for(j=idx(region))  i==j ? 0
                                       : point_in_polygon(pt,region[j]) >=0 ? 1 : 0]
                ],
       level = inside*repeat(1,len(region))
   )
   [ for(i=idx(region))
      if(level[i]%2==0)
         let(
             possible_children = search([level[i]+1],level,0)[0],
             keep=search([1], select(inside,possible_children), 0, i)[0]
         )
         [
           clockwise_polygon(region[i]),
           for(good=keep)
              ccw_polygon(region[possible_children[good]])
         ]
    ];




// Section: Offset and 2D Boolean Set Operations


function _offset_chamfer(center, points, delta) =
    is_undef(points[1])?
        let( points = select(points,[0,2]),
             center = mean(points),
             dir = sign(delta)*line_normal(points),
             halfside = tan(22.5)*abs(delta)
        )
        [ points[0]+dir*halfside,
          center + dir*abs(delta) + unit(points[0]-center)*halfside,
          center + dir*abs(delta) + unit(points[1]-center)*halfside, 
          points[1]+dir*halfside
        ]
    :
    let(
        dist = sign(delta)*norm(center-line_intersection(select(points,[0,2]), [center, points[1]])),
        endline = _shift_segment(select(points,[0,2]), delta-dist)
    ) [
        line_intersection(endline, select(points,[0,1])),
        line_intersection(endline, select(points,[1,2]))
    ];


function _shift_segment(segment, d) =
    assert(!approx(segment[0],segment[1]),"\nPath has repeated points.")
    move(d*line_normal(segment),segment);


// Extend to segments to their intersection point.  First check if the segments already have a point in common,
// which can happen if two colinear segments are input to the path variant of `offset()`
function _segment_extension(s1,s2) =
    norm(s1[1]-s2[0])<1e-6 ? s1[1] : line_intersection(s1,s2,LINE,LINE);


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
// makes the test more accurate, but slower.
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


// Function: offset()
// Synopsis: Takes a 2D {{path}}, {{polygon}} or {{region}} and returns a path offset by an amount.
// SynTags: Path, Region, Ext
// Topics: Paths, Polygons, Regions
// Usage:
//   offsetpath = offset(path, [r=|delta=], [chamfer=], [closed=], [check_valid=], [quality=], [error=], [same_length=])
//   path_faces = offset(path, return_faces=true, [r=|delta=], [chamfer=], [closed=], [check_valid=], [quality=], [error=], [firstface_index=], [flip_faces=])
// Description:
//   Takes a 2D input {{path}}, {{polygon}} or {{region}} and returns a path offset by the specified amount.  As with the built-in
//   offset() module, you can use `r` to specify rounded offset and `delta` to specify offset with
//   corners.  If you used `delta` you can set `chamfer` to true to get chamfers.
//   When `closed=true` (the default), the input is treated as a polygon.  If the input is a region it is treated as a collection
//   of polygons.  In this case, positive offset values make the shape larger.  If you set `closed=false` then the input is treated as a path
//   with distinct start and end points.  For paths, positive offsets shifts the path to the left, relative to the direction of the path.
//   Note that a path that happens to end at its starting point is not the same as a polygon, and the offset result may differ at the ends.  
//   .
//   If you use `delta` without chamfers, the path must not include any 180 degree turns, where the path
//   reverses direction.  Such reversals result in an offset with two parallel segments, so they cannot be
//   extended to an intersection point.  If you select chamfering, the reversals are permitted and result
//   in a single segment connecting the parallel segments. With rounding, a semi-circle connects the two offset segments.
//   Note also that repeated points are always illegal in the input; remove them first with {{deduplicate()}}.  
//   .
//   When offsets shrink the path, segments cross and become invalid.  By default `offset()` checks
//   for this situation.  To test validity the code checks that segments have distance larger than (r
//   or delta) from the input path.  This check takes O(N^2) time and may mistakenly eliminate
//   segments you wanted included in various situations, so you can disable it if you wish by setting
//   check_valid=false.  When segments are mistakenly removed, you may get the wrong offset output, or you may
//   get an error, depending on the effect of removing the segment.  
//   The erroneous removal of segments is more common when your input
//   contains very small segments and in this case can result in an invalid situation where the remaining
//   valid segments are parallel and cannot be connected to form an offset curve.  If this happens, you
//   get an error message to this effect.  The only solutions are either to remove the small segments with {{deduplicate()}},
//   or if your path permits it, to set check_valid to false.  
//   .
//   Another situation that can arise with validity testing is that the test is not sufficiently thorough and some
//   segments persist that should be eliminated.  In this case, increase `quality` from its default of 1 to a value of 2 or 3.
//   This increases the number of samples on the segment that are checked, so it also increase run time.  In
//   some situations you may be able to decrease run time by setting quality to 0, which causes only
//   segment ends to be checked.  
//   .
//   When invalid segments are eliminated, the path length decreases, and multiple points on the input path map to the same point
//   on the offset path.  If you use chamfering or rounding, then
//   the chamfers and roundings can increase the length of the output path.  Hence points in the output may be 
//   difficult to associate with the input.  If you want to maintain alignment between the points you
//   can use the `same_length` option.  This option requires that you use `delta=` with `chamfer=false` to ensure
//   that no points are added.  with `same_length`, when points collapse to a single point in the offset, the output includes
//   that point repeated to preserve the correct length.  Generally, repeated points do not appear in the offset output
//   unless you set `same_length=true`, but in some rare circumstances involving short segments, it is possible for the
//   repeated points to occur in the output, even when `same_length=false`.  
//   .
//   Another way to obtain alignment information is to use the return_faces option, which can
//   provide alignment information for all offset parameters: it returns a face list that lists faces between
//   the original path and the offset path where the vertices are ordered with the original path
//   first, starting at `firstface_index` and the offset path vertices appearing afterwords.  The
//   direction of the faces can be flipped using `flip_faces`.  When you request faces the return
//   value is a list: [offset_path, face_list].
// Arguments:
//   path = the path to process.  A list of 2d points.
//   ---
//   r = offset radius.  Distance to offset, rounds over corners.
//   delta = Distance to offset with pointed corners.
//   chamfer = Chamfer corners when you specify `delta`.  Default: false
//   closed = If true, path is treated as a polygon. Default: true
//   check_valid = Perform segment validity check.  Default: true
//   quality = Validity check quality parameter, a small integer.  Default: 1
//   error = If true, assert an error if offset path is degenerate. If false, return an empty list `[]` for a degenerate path. You must check the result yourself before passing it into another function. Default: true
//   same_length = Return a path with the same length as the input.  Only compatible with `delta=`.  Default: false
//   return_faces = Return face list.  Default: false
//   firstface_index = Starting index for face list.  Default: 0
//   flip_faces = Flip face direction.  Default: false
// Example(2D,NoAxes): Offset the red star out by 10 units.
//   star = star(5, r=100, ir=30);
//   stroke(closed=true, star, width=3, color="red");
//   stroke(closed=true, width=3,
//       offset(star, delta=10, closed=true));
// Example(2D,NoAxes):  Offset the star with chamfering
//   star = star(5, r=100, ir=30);
//   stroke(closed=true, star, width=3, color="red");
//   stroke(closed=true, width=3,
//          offset(star, delta=10, chamfer=true, closed=true));
// Example(2D,NoAxes):  Offset the star with rounding
//   star = star(5, r=100, ir=30);
//   stroke(closed=true, star, width=3, color="red");
//   stroke(closed=true, width=3,
//          offset(star, r=10, closed=true));
// Example(2D,NoAxes): Offset inward 
//   star = star(7, r=120, ir=50);
//   stroke(closed=true, width=3, star, color="red");
//   stroke(closed=true, width=3,
//          offset(star, delta=-15, closed=true));
// Example(2D,NoAxes): Inward offset with chamfers
//   star = star(7, r=120, ir=50);
//   stroke(closed=true, width=3, star, color="red");
//   stroke(closed=true, width=3,
//          offset(star, delta=-15, chamfer=true, closed=true));
// Example(2D,NoAxes):  Inward offset with rounding
//   star = star(7, r=120, ir=50);
//   stroke(closed=true, width=3, star, color="red");
//   stroke(closed=true, width=3,
//          offset(star, r=-15, closed=true, $fn=20));
// Example(2D): Open path.  The red path moves from left to right as shown by the arrow and the positive offset shifts to the left of the initial red path.
//   sinpath = 2*[for(theta=[-180:5:180]) [theta/4,45*sin(theta)]];
//   stroke(sinpath, width=2, color="red", endcap2="arrow2");
//   stroke(offset(sinpath, r=17.5,closed=false),width=2);
// Example(2D,NoAxes): An open path in red with with its positive offset in yellow and its negative offset in blue. 
//   seg = [[0,0],[0,50]];
//   stroke(seg,color="red",endcap2="arrow2"); 
//   stroke(offset(seg,r=15,closed=false));
//   stroke(offset(seg,r=-15,closed=false),color="blue");
// Example(2D,NoAxes): Offsetting the same line segment closed=true.  On the left, we use delta with chamfer=false, in the middle, chamfer=true, and on the right, rounding with r=.  A "closed" path here means that the path backtracks over itself.  When this happens, a flat end occurs in the first case, an end with chamfered corners if chamfering is on, or a semicircular rounding in the rounded case.  
//   seg = [[0,0],[0,50]];
//   stroke(seg,color="red"); 
//   stroke([offset(seg,delta=15,closed=true)]);
//   right(45){
//     stroke(seg,color="red");
//     stroke([offset(seg,delta=15,chamfer=true,closed=true)]);
//   }
//   right(90){
//     stroke(seg,color="red");
//     stroke([offset(seg,r=15,closed=true)]);
//   }
// Example(2D,NoAxes): Cutting a notch out of a square with a path reversal
//   path = [[-10,-10],[-10,10],[0,10],[0,0],[0,10],[10,10],[10,-10]];
//   stroke([path],width=.25,color="red");
//   stroke([offset(path, r=-2,$fn=32,closed=true)],width=.25);
// Example(2D,NoAxes): A more complex example where the path turns back on itself several times.  
//   $fn=32;
//   path = [
//           [0,0], [5,5],
//           [10,0],[5,5],
//           [11,8],[5,5],
//           [5,10],[5,5],
//           [-1,4],[5,5]
//           ];
//   op=offset(path, r=1.5,closed=true);
//   stroke([path],width=.1,color="red");
//   stroke([op],width=.1);
// Example(2D,NoAxes):  With the default quality value, this case produces the wrong answer.  This happens because the offset edge corresponding to the long left edge (shown in green) is erroneously flagged as invalid.  If you use `r=` instead of `delta=` then this fails with an error.  
//   test = [[0,0],[10,0],[10,7],[0,7], [-1,-3]];
//   polygon(offset(test,delta=-1.9, closed=true)); 
//   stroke([test],width=.1,color="red");
//   stroke(select(test,-2,-1), width=.1, color="green");
// Example(2D,NoAxes):  Using `quality=2` produces the correct result
//   test = [[0,0],[10,0],[10,7],[0,7], [-1,-3]];
//   polygon(offset(test,r=-1.9, closed=true, quality=2));   
//   stroke([test],width=.1,color="red");
// Example(2D,NoAxes): This case fails if `check_valid=true` when delta is large enough because segments are too close to the opposite side of the curve so they all get flagged as invalid and deleted from the output.  
//   star = star(5, r=22, ir=13);
//   stroke(star,width=.3,closed=true);                                                           
//   color("green")
//     stroke(offset(star, delta=-9, closed=true),width=.3,closed=true); // Works with check_valid=true (the default)
//   color("red")
//     stroke(offset(star, delta=-10, closed=true, check_valid=false),   // Fails if check_valid=true 
//            width=.3,closed=true); 
// Example(2D): But if you use rounding with offset then you need `check_valid=true` when `r` is big enough.  It works without the validity check as long as the offset shape retains a some of the straight edges at the star tip, but once the shape shrinks smaller than that, it fails.  There is no simple way to get a correct result for the case with `r=10`, because as in the previous example, it fails if you turn on validity checks.  
//   star = star(5, r=22, ir=13);
//   color("green")
//     stroke(offset(star, r=-8, closed=true,check_valid=false), width=.1, closed=true);
//   color("red")
//     stroke(offset(star, r=-10, closed=true,check_valid=false), width=.1, closed=true);
// Example(2D,NoAxes): The extra triangles in this example show that the validity check cannot be skipped
//   ellipse = scale([20,4], p=circle(r=1,$fn=64));
//   stroke(ellipse, closed=true, width=0.3);
//   stroke(offset(ellipse, r=-3, check_valid=false, closed=true),
//          width=0.3, closed=true);
// Example(2D,NoAxes): The triangles are removed by the validity check
//   ellipse = scale([20,4], p=circle(r=1,$fn=64));
//   stroke(ellipse, closed=true, width=0.3);
//   stroke(offset(ellipse, r=-3, check_valid=true, closed=true),
//          width=0.3, closed=true);
// Example(2D,NoAxes): The region shown in red has the yellow offset region. 
//   rgn = difference(circle(d=100),
//                    union(square([20,40], center=true),
//                          square([40,20], center=true)));
//   stroke(rgn, width=1, color="red");
//   region(offset(rgn, r=-5));
// Example(2D,NoAxes): Using `same_length=true` to align the original curve to the offset. Many points map to the corner at the top.
//   closed=false;
//   path = [for(angle=[0:5:180]) 10*[angle/100,2*sin(angle)]];
//   opath = offset(path,delta=-3,same_length=true,closed=closed);
//   stroke(path,closed=closed,width=.3);
//   stroke(opath,closed=closed,width=.3);
//   for(i=idx(path))
//       stroke([path[i],opath[i]],width=.3,color="red");

function offset(
    path, r=undef, delta=undef, chamfer=false,
    closed=true, check_valid=true,
    quality=1, error=true, return_faces=false, firstface_index=0,
    flip_faces=false, same_length=false
) =
    assert(!(same_length && return_faces), "\nCannot combine return_faces with same_length.")
    is_region(path)?
        assert(closed, "\nCannot set closed=false for a region.")
        assert(!return_faces, "\nParameter return_faces is not supported for regions.")
        let(
            ofsregs = [for(R=region_parts(path))
                difference([for(i=idx(R)) offset(R[i], r=u_mul(i>0?-1:1,r), delta=u_mul(i>0?-1:1,delta),
                                      chamfer=chamfer, check_valid=check_valid, quality=quality,same_length=same_length,closed=true)])]
        )
        union(ofsregs)
    :
    let(rcount = num_defined([r,delta]))
    assert(rcount==1,"\nMust define exactly one of 'delta' and 'r'.")
    assert(!same_length || (is_def(delta) && !chamfer), "\nMust specify delta with chamfer=false, when same_length=true.")
    assert(is_path(path), "\nInput must be a path or region.")
    let(
        chamfer = is_def(r) ? false : chamfer,
        quality = max(0,round(quality)),
        flip_dir = closed && !is_polygon_clockwise(path)? -1 : 1,
        d = flip_dir * (is_def(r) ? r : delta)
    )
    d==0 && !return_faces ? path :
    let(
        shiftsegs = [for(i=[0:len(path)-2]) _shift_segment([path[i],path[i+1]], d),
                     if (closed) _shift_segment([last(path),path[0]],d)
                     else [path[0],path[1]]  // dummy segment, not used
                    ],
        // good segments are ones where no point on the segment is less than distance d from any point on the path
        good = check_valid ? _good_segments(path, abs(d), shiftsegs, closed, quality)
                           : repeat(true,len(shiftsegs)),
        goodsegs = bselect(shiftsegs, good),
        goodpath = bselect(path,good),
        degenerate = (len(goodsegs)-(!closed && select(good,-1)?1:0) <= 0)
    )
    assert(!(degenerate && error), "\nOffset of path is degenerate.")
    degenerate ? [] // return empty path
    : let(
        // Extend the shifted segments to their intersection points.  For open curves the endpoints
        // are simply the endpoints of the shifted segments.  If segments are parallel then the intersection
        // points will be undef
        sharpcorners = [for(i=[0:len(goodsegs)-1])
                             !closed && i==0 ? goodsegs[0][0]
                           : !closed && i==len(goodsegs)-1 ? goodsegs[len(goodsegs)-2][1]
                           : _segment_extension(select(goodsegs,i-1), select(goodsegs,i))],

        // true if sharpcorner has two parallel segments that go in the same direction 
        cornercheck = [for(i=idx(goodsegs)) (!closed && (i==0 || i==len(goodsegs)-1))
                                          || is_def(sharpcorners[i])
                                          || approx(unit(deltas(select(goodsegs,i-1))[0]) * unit(deltas(goodsegs[i])[0]),-1)],
        dummyA = assert(len(sharpcorners)==2 || all(cornercheck),"\nTwo consecutive valid offset segments are parallel but do not meet at their ends, maybe because path contains very short segments that were mistakenly flagged as invalid; unable to compute offset. If you get this error from offset_sweep() try setting ofset=\"delta\"."),
        reversecheck = 
            !same_length 
              || !(is_def(delta) && !chamfer)            // Reversals only a problem in delta mode without chamfers
              || all_defined(sharpcorners),
        dummyB = assert(reversecheck, "\nEither validity check failed and removed a valid segment or the input 'path' contains a segment that reverses direction (180 deg turn). Path reversals are not allowed when same_length is true because they increase path length."),
        // This is a Boolean array that indicates whether a corner is an outside or inside corner
        // For outside corners, the new corner is an extension (angle 0), for inside corners, it turns backward (angle 180)
        // If either side turns back it is an inside corner---must check both.
        // Outside corners can get rounded (if r is specified and there is space to round them)
        // We flag endpoints of open paths as inside corners so that we don't try to round
        outsidecorner =
            len(sharpcorners)==2 ? [closed,closed]
          : [for(i=idx(goodsegs))
                !closed && (i==0 || i==len(goodsegs)-1) ? false  // endpoints of open path never get rounded
              : is_undef(sharpcorners[i]) ? true
              : let(prevseg=select(goodsegs,i-1))
                (goodsegs[i][1]-goodsegs[i][0]) * (goodsegs[i][0]-sharpcorners[i]) > 0
                  && (prevseg[1]-prevseg[0]) * (sharpcorners[i]-prevseg[1]) > 0
            ],
        steps = is_def(delta) ? undef
              : [
                 for(i=[0:len(goodsegs)-1])  
                    r==0 ? 0
                  : !closed && (i==0 || i==len(goodsegs)-1) ? 0    // We don't round ends of open paths
                     // floor is important here to ensure we don't generate extra segments when nearly straight paths expand outward
                  : let(vang = vector_angle(select(goodsegs,i-1)[1]-goodpath[i],
                                            goodsegs[i][0]-goodpath[i]))
                    assert(!outsidecorner[i] || vang!=0,    // If outsidecorner[i] is true then vang>0 needed to give valid step count
                           "\nOffset computation failed, probably because validity check mistakenly removed a valid segment.  Increasing quality might fix this.")
                    1+floor(segs(r)*vang/360)
                ],
        // newcorners is a list where each entry is a list of the points that correspond to a single point in the sharpcorners 
        // list: newcorners[i] is the point list that replaces goodpath[i].  Without rounding or chamfering (or reversals),
        // this means each entry of newcorners is a singleton list.  But in the other cases, multiple points may appear at
        // a given position; newcorners later gets flattened to produce the final list, but the structure is needed to
        // establish point alignment for creating faces, or for duplicating points if same_length is true.  
        newcorners =
            [for(i=idx(goodsegs))
                 let(
                     basepts = [ select(goodsegs,i-1)[1], goodsegs[i][0] ]
                 )
                 is_def(sharpcorners[i]) &&
                   ((is_def(steps) && steps[i] <=1)  // Don't round if steps is smaller than 2
                     || !outsidecorner[i])           // Don't round inside corners
                ? [sharpcorners[i]]
                : chamfer ? _offset_chamfer(
                                  goodpath[i], [
                                      select(goodsegs,i-1)[1],
                                      sharpcorners[i],
                                      goodsegs[i][0]
                                  ], d
                              )
                : is_def(delta) ?
                      (
                         is_def(sharpcorners[i]) ? [sharpcorners[i]]
                       : let(normal = d*line_normal(basepts))
                         basepts + [normal,normal]
                      )
                : // rounded case
                  let(
                      class =_tri_class( [ each select(goodsegs,i-1), goodsegs[i][0]]),
                      cw = class==1,
                      ccw = class==-1
                  )
                  arc(cp=goodpath[i], cw=cw, ccw=ccw,
                      points=basepts,
                      n=steps[i]+3)
              ],
        pointcount = [for(entry=newcorners) len(entry)],
        edges = flatten(newcorners),
        faces = !return_faces? []
              : _makefaces(
                           flip_faces, firstface_index, good,
                           pointcount, closed
                          ),
        final_edges = same_length ? select(edges,
                                           [0,
                                            each list_head(cumsum([for(g=good) g?1:0]))
                                           ]
                                    )
                                  : edges
    ) return_faces? [edges,faces] : final_edges;



/// Internal Function: _filter_region_parts()
///
/// splits region1 into subpaths where either it touches itself or crosses region2.  Classifies all of the
/// subpaths as described below and keeps the ones listed in keep1.  A similar process is performed for region2.
/// All of the kept subpaths are assembled into polygons and returned as a lst.
/// .
/// The four types of subpath from the region are defined relative to the second region:
///    "O" - the subpath is outside the second region
///    "I" - the subpath is in the second region's interior
///    "S" - the subpath is on the 2nd region's border and the two regions interiors are on the same side of the subpath
///    "U" - the subpath is on the 2nd region's border and the two regions meet at the subpath from opposite sides
/// You specify which type of subpaths to keep with a string of the desired types such as "OS".  
function _filter_region_parts(region1, region2, keep, eps=EPSILON) = 
    // We have to compute common vertices between paths in the region because
    // they can be places where the path must be cut, even though they aren't
    // found my the split_path function.  
    let(
        subpaths = split_region_at_region_crossings(region1,region2,eps=eps),
        regions=[force_region(region1),
                 force_region(region2)]
    )        
    _assemble_path_fragments(
        [for(i=[0:1])
           let(
               keepS = search("S",keep[i])!=[],
               keepU = search("U",keep[i])!=[],        
               keepoutside = search("O",keep[i]) !=[],
               keepinside = search("I",keep[i]) !=[],
               all_subpaths = flatten(subpaths[i])
           )
           for (subpath = all_subpaths)
               let(
                   midpt = mean([subpath[0], subpath[1]]),
                   rel = point_in_region(midpt,regions[1-i],eps=eps),
                   keepthis = rel<0 ? keepoutside
                            : rel>0 ? keepinside
                            : !(keepS || keepU) ? false
                            : let(
                                  sidept = midpt + 0.01*line_normal(subpath[0],subpath[1]),
                                  rel1 = point_in_region(sidept,regions[0],eps=eps)>0,
                                  rel2 = point_in_region(sidept,regions[1],eps=eps)>0
                              )
                              rel1==rel2 ? keepS : keepU
               )
               if (keepthis) subpath
        ]
    );



function _list_three(a,b,c) =
   is_undef(b) ? a : 
   [
     a,
     if (is_def(b)) b,
     if (is_def(c)) c
   ];



// Function&Module: union()
// Synopsis: Performs a Boolean union operation.
// SynTags: Geom, Region
// Topics: Boolean Operations, Regions, Polygons, Shapes2D, Shapes3D
// See Also: difference(), intersection(), diff(), intersect(), exclusive_or()
// Usage:
//   union() CHILDREN;
//   region = union(regions);
//   region = union(REGION1,REGION2);
//   region = union(REGION1,REGION2,REGION3);
// Description:
//   When called as a function and given a list of {{regions}} or 2D {{polygons}},
//   returns the union of all given regions and polygons.  Result is a single region.
//   When called as the built-in module, makes the union of the given children.
//   This function is **much** slower than the native union module acting on geometry,
//   so you should only use it when you need a point list for further processing.  
// Arguments:
//   regions = List of regions to union.
// Example(2D):
//   shape1 = move([-8,-8,0], p=circle(d=50));
//   shape2 = move([ 8, 8,0], p=circle(d=50));
//   color("green") region(union(shape1,shape2));
//   for (shape = [shape1,shape2])
//       stroke(shape, width=0.5, closed=true, color="red");
function union(regions=[],b=undef,c=undef,eps=EPSILON) =
    let(regions=_list_three(regions,b,c))
    len(regions)==0? [] :
    len(regions)==1? regions[0] :
    let(regions=[for (r=regions) is_path(r)? [r] : r])
    union([
           _filter_region_parts(regions[0],regions[1],["OS", "O"], eps=eps),           
           for (i=[2:1:len(regions)-1]) regions[i]
          ],
          eps=eps
    );


// Function&Module: difference()
// Synopsis: Performs a Boolean difference operation.
// SynTags: Geom, Region
// Topics: Boolean Operations, Regions, Polygons, Shapes2D, Shapes3D
// See Also: union(), intersection(), diff(), intersect(), exclusive_or()
// Usage:
//   difference() CHILDREN;
//   region = difference(regions);
//   region = difference(REGION1,REGION2);
//   region = difference(REGION1,REGION2,REGION3);
// Description:
//   When called as a function, and given a list of {{regions}} or 2D {{polygons}}, 
//   takes the first region or polygon and differences away all other regions/polygons from it.  The resulting
//   region is returned.
//   When called as the built-in module, makes the set difference of the given children.
//   This function is **much** slower than the native difference module acting on geometry,
//   so you should only use it when you need a point list for further processing.  
// Arguments:
//   regions = List of regions or polygons to difference.
// Example(2D):
//   shape1 = move([-8,-8,0], p=circle(d=50));
//   shape2 = move([ 8, 8,0], p=circle(d=50));
//   for (shape = [shape1,shape2])
//       stroke(shape, width=0.5, color="red", closed=true);
//   color("green") region(difference(shape1,shape2));
function difference(regions=[],b=undef,c=undef,eps=EPSILON) =
     let(regions = _list_three(regions,b,c))
     len(regions)==0? []
   : len(regions)==1? regions[0]
   : regions[0]==[] ? []
   : let(regions=[for (r=regions) is_path(r)? [r] : r])
     difference([
                 _filter_region_parts(regions[0],regions[1],["OU", "I"], eps=eps),                
                 for (i=[2:1:len(regions)-1]) regions[i]
                ],
                eps=eps
     );


// Function&Module: intersection()
// Synopsis: Performs a Boolean intersection operation.
// SynTags: Geom, Region
// Topics: Boolean Operations, Regions, Polygons, Shapes2D, Shapes3D
// See Also: difference(), union(), diff(), intersect(), exclusive_or()
// Usage:
//   intersection() CHILDREN;
//   region = intersection(regions);
//   region = intersection(REGION1,REGION2);
//   region = intersection(REGION1,REGION2,REGION3);
// Description:
//   When called as a function, and given a list of {{regions}} or {{polygons}} returns the
//   intersection of all given regions.  Result is a single region.
//   When called as the built-in module, makes the intersection of all the given children.
// Arguments:
//   regions = List of regions to intersect.
// Example(2D):
//   shape1 = move([-8,-8,0], p=circle(d=50));
//   shape2 = move([ 8, 8,0], p=circle(d=50));
//   for (shape = [shape1,shape2])
//       stroke(shape,width=0.5, color="red", closed=true);
//   color("green") region(intersection(shape1,shape2));
function intersection(regions=[],b=undef,c=undef,eps=EPSILON) =
     let(regions = _list_three(regions,b,c))
     len(regions)==0 ? []
   : len(regions)==1? regions[0]
   : regions[0]==[] || regions[1]==[] ? []   
   : intersection([
                   _filter_region_parts(regions[0],regions[1],["IS","I"],eps=eps),                       
                   for (i=[2:1:len(regions)-1]) regions[i]
                  ],
                  eps=eps
     );



// Function&Module: exclusive_or()
// Synopsis: Performs a Boolean exclusive-or operation.
// SynTags: Geom, Region
// Topics: Boolean Operations, Regions, Polygons, Shapes2D, Shapes3D
// See Also: union(), difference(), intersection(), diff(), intersect()
// Usage:
//   exclusive_or() CHILDREN;
//   region = exclusive_or(regions);
//   region = exclusive_or(REGION1,REGION2);
//   region = exclusive_or(REGION1,REGION2,REGION3);
// Description:
//   When called as a function and given a list of {{regions}} or 2D {{polygons}}, 
//   returns the exclusive_or of all given regions.  Result is a single region.
//   When called as a module, performs a Boolean exclusive-or of up to 10 children. Note that when
//   the input regions cross each other, the exclusive-or operator produces shapes that
//   meet at corners (non-simple regions), which do not render in CGAL.  
//   This function is **much** slower than the native intersection module acting on geometry,
//   so you should only use it when you need a point list for further processing.  
// Arguments:
//   regions = List of regions or polygons to exclusive_or
// Example(2D): As Function.  A linear_sweep of this shape fails to render in CGAL.  
//   shape1 = move([-8,-8,0], p=circle(d=50));
//   shape2 = move([ 8, 8,0], p=circle(d=50));
//   for (shape = [shape1,shape2])
//       color("red") stroke(shape, width=0.5, closed=true);
//   color("green") region(exclusive_or(shape1,shape2));
// Example(2D): As Module.  A linear_extrude() of the resulting geometry fails to render in CGAL.  
//   exclusive_or() {
//       square(40,center=false);
//       circle(d=40);
//   }
function exclusive_or(regions=[],b=undef,c=undef,eps=EPSILON) =
     let(regions = _list_three(regions,b,c))
     len(regions)==0? []
   : len(regions)==1? force_region(regions[0])
   : regions[0]==[] ? exclusive_or(list_tail(regions))
   : regions[1]==[] ? exclusive_or(list_remove(regions,1))
   : exclusive_or([
                   _filter_region_parts(regions[0],regions[1],["IO","IO"],eps=eps),                  
                   for (i=[2:1:len(regions)-1]) regions[i]
                  ],
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
        assert($children<=10, "\nexclusive_or() can handle up to 10 children.");
    }
}



// Function&Module: hull_region()
// Synopsis: Compute convex hull of {{region}} or 2D {{path}}
// SynTags: Geom, Path
// Topics: Regions, Polygons, Shapes2D
// Usage:
//    path = hull_region(region);
//    hull_region(region);
// Description:
//   Given a {{path}}, or a {{region}}, compute the convex hull
//   and return it as a path.  This differs from {{hull()}} and {{hull2d_path()}}, which
//   return an index list into the point list.  As a module invokes the native hull() on
//   the specified region.  
// Arguments:
//   region = region or path listing points to compute the hull from.  
// Example(2D, NoAxes):
//   data = [star(id=10,od=20,n=9),
//           right(30, star(id=12,od=25, n=7))];
//   stroke(data);
//   stroke([hull_region(data)],color="red");
function hull_region(region) =
  assert(is_path(region) || is_region(region))
  let(
      pts = is_region(region) ? flatten(region)
                              : region,
      order = hull2d_path(pts)
  )
  select(pts,order);

module hull_region(region)
{
  hull()region(region);
}


// Function: fill()
// Synopsis: Remove holes from a {{region}}
// SynTags: Geom, Path
// Topics: Regions, Polygons, Shapes2D
// Usage:
//    filled = fill(region);
// Description:
//   Given a {{region}}, fill in any internal holes in the components of the region.  This returns the outside border of each region component, and
//   is equivalent to {{hull()}} for region components whose outside boundary is convex.  
// Arguments:
//   region = region to fill
// Example(2D, NoAxes):  The original region in green has internal holes and subparts that are all filled in on the yellow filled region.  
//   $fs=.5;$fa=1;
//   reg=[circle(r=10),right(5.5,circle(r=1)),
//        circle(r=8), circle(r=3),
//        right(5.5,rect([3,4]))];
//   color("green")region(reg);
//   right(25)region(fill(reg));
// Example(2D, NoAxes): Here the input region in green has two components:
//   reg = [circle(8), circle(6)];
//   reg2 = union([reg, fwd(18,reg)]);
//   color("green")region(reg2);
//   right(18) region(fill(reg2));

function fill(region) =
   let(
       region = force_region(region)
   )
   assert(is_region(region), "\nInput is not a region.")
   let(
       inside = [for(i=idx(region))
                    let(pt = mean([region[i][0], region[i][1]]))
                    [for(j=idx(region))  i==j ? 0
                                       : point_in_polygon(pt,region[j]) >=0 ? 1 : 0]
                ],
       level = inside*repeat(1,len(region))
   )
   [ for(i=idx(region))
      if(level[i]==0) clockwise_polygon(region[i])];





// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
