//////////////////////////////////////////////////////////////////////
// LibFile: walls.scad
//   Walls and structural elements that 3D print without support.
// Includes:
//   include <BOSL2/std.scad>
//   include <BOSL2/walls.scad>
// FileGroup: Parts
// FileSummary: Walls and structural elements that 3D print without support.
//////////////////////////////////////////////////////////////////////


include<rounding.scad>

// Section: Walls


// Module: sparse_wall()
// Synopsis: Makes an open cross-braced rectangular wall.
// SynTags: Geom
// Topics: FDM Optimized, Walls
// See Also: hex_panel(), corrugated_wall(), thinning_wall(), thinning_triangle(), narrowing_strut()
//
// Usage:
//   sparse_wall(h, l, thick, [maxang=], [strut=], [max_bridge=]) [ATTACHMENTS];
//
// Description:
//   Makes an open rectangular strut with X-shaped cross-bracing, designed to reduce
//   the need for support material in 3D printing.
//
// Arguments:
//   h = height of strut wall.
//   l = length of strut wall.
//   thick = thickness of strut wall.
//   ---
//   maxang = maximum overhang angle of cross-braces, measured down from vertical.  Default: 30 
//   strut = the width of the cross-braces. Default: 5
//   max_bridge = maximum bridging distance between cross-braces.  Default: 20
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//
// See Also: corrugated_wall(), thinning_wall()
//
// Example: Typical Shape
//   sparse_wall(h=40, l=100, thick=3);
// Example: Thinner Strut
//   sparse_wall(h=40, l=100, thick=3, strut=2);
// Example: Larger maxang
//   sparse_wall(h=40, l=100, thick=3, strut=2, maxang=45);
// Example: Longer max_bridge
//   sparse_wall(h=40, l=100, thick=3, strut=2, maxang=45, max_bridge=30);
module sparse_wall(h=50, l=100, thick=4, maxang=30, strut=5, max_bridge=20, anchor=CENTER, spin=0, orient=UP)
{
    zoff = h/2 - strut/2;
    yoff = l/2 - strut/2;

    maxhyp = 1.5 * (max_bridge+strut)/2 / sin(maxang);
    maxz = 2 * maxhyp * cos(maxang);

    zreps = ceil(2*zoff/maxz);
    zstep = 2*zoff / zreps;

    hyp = zstep/2 / cos(maxang);
    maxy = min(2 * hyp * sin(maxang), max_bridge+strut);

    yreps = ceil(2*yoff/maxy);

    size = [thick, l, h];
    attachable(anchor,spin,orient, size=size) {
        yrot(90) {
            linear_extrude(height=thick, convexity=4*yreps, center=true) {
                sparse_wall2d([h,l], maxang=maxang, strut=strut, max_bridge=max_bridge);
            }
        }
        children();
    }
}


// Module: sparse_wall2d()
// Synopsis: Makes an open cross-braced rectangular wall.
// SynTags: Geom
// Topics: FDM Optimized, Walls
// See Also: sparse_wall(), hex_panel(), corrugated_wall(), thinning_wall(), thinning_triangle(), narrowing_strut()
//
// Usage:
//   sparse_wall2d(size, [maxang=], [strut=], [max_bridge=]) [ATTACHMENTS];
//
// Description:
//   Makes a 2D open rectangular square with X-shaped cross-bracing, designed to be extruded, to make a strut that reduces
//   the need for support material in 3D printing.
//
// Arguments:
//   size = The `[X,Y]` size of the outer rectangle.
//   ---
//   maxang = maximum overhang angle of cross-braces.
//   strut = the width of the cross-braces.
//   max_bridge = maximum bridging distance between cross-braces.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//
// See Also: corrugated_wall(), thinning_wall()
//
// Example: Typical Shape
//   sparse_wall2d(size=[40,100]);
// Example: Thinner Strut
//   sparse_wall2d(size=[40,100], strut=2);
// Example: Larger maxang
//   sparse_wall2d(size=[40,100], strut=2, maxang=45);
// Example: Longer max_bridge
//   sparse_wall2d(size=[40,100], strut=2, maxang=45, max_bridge=30);
module sparse_wall2d(size=[50,100], maxang=30, strut=5, max_bridge=20, anchor=CENTER, spin=0)
{
    h = size.x;
    l = size.y;

    zoff = h/2 - strut/2;
    yoff = l/2 - strut/2;

    maxhyp = 1.5 * (max_bridge+strut)/2 / sin(maxang);
    maxz = 2 * maxhyp * cos(maxang);

    zreps = ceil(2*zoff/maxz);
    zstep = 2*zoff / zreps;

    hyp = zstep/2 / cos(maxang);
    maxy = min(2 * hyp * sin(maxang), max_bridge+strut);

    yreps = ceil(2*yoff/maxy);
    ystep = 2*yoff / yreps;

    ang = atan(ystep/zstep);
    len = zstep / cos(ang);
    attachable(anchor,spin, two_d=true, size=size) {
        union() {
            difference() {
                square([h, l], center=true);
                square([h-2*strut, l-2*strut], center=true);
            }
            ycopies(ystep, n=yreps) {
                xcopies(zstep, n=zreps) {
                    skew(syx=tan(-ang)) square([(h-strut)/zreps, strut/cos(ang)], center=true);
                    skew(syx=tan( ang)) square([(h-strut)/zreps, strut/cos(ang)], center=true);
                }
            }
        }
        children();
    }
}


// Module: sparse_cuboid()
// Synopsis: Makes an open cross-braced cuboid
// SynTags: Geom
// Topics: FDM Optimized, Walls
// See Also: sparse_wall(), hex_panel(), corrugated_wall(), thinning_wall(), thinning_triangle(), narrowing_strut(), cuboid()
// Usage:
//   sparse_cuboid(size, [dir], [maxang=], [struct=]
// Description:
//   Makes an open rectangular cuboid with X-shaped cross-bracing to reduce the need for material in 3d printing.
//   The direction of the cross bracing can be aligned with the X, Y or Z axis.  This module can be
//   used as a drop-in replacement for {{cuboid()}} if you belatedly decide that your model would benefit from
//   the sparse construction.  Note that for Z aligned bracing the max_bridge parameter contrains the gaps that are parallel
//   to the Y axis, and the angle is measured relative to the X direction.  
// Arguments:
//   size = The size of sparse wall, a number or length 3 vector.
//   dir = direction of holes through the cuboid, must be a vector parallel to the X, Y or Z axes, or one of "X", "Y" or "Z".  Default: "Y"
//   ---
//   maxang = maximum overhang angle of cross-braces, measured down from vertical.  Default: 30 
//   strut = the width of the cross-braces. Default: 5
//   max_bridge = maximum bridging distance between cross-braces.  Default: 20
//   chamfer = Size of chamfer, inset from sides.  Default: No chamfering.
//   rounding = Radius of the edge rounding.  Default: No rounding.
//   edges = Edges to mask.  See [Specifying Edges](attachments.scad#section-specifying-edges).  Default: all edges.
//   except = Edges to explicitly NOT mask.  See [Specifying Edges](attachments.scad#section-specifying-edges).  Default: No edges.
//   trimcorners = If true, rounds or chamfers corners where three chamfered/rounded edges meet.  Default: `true`
//   teardrop = If given as a number, rounding around the bottom edge of the cuboid won't exceed this many degrees from vertical.  If true, the limit angle is 45 degrees.  Default: `false`
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Examples:
//   sparse_cuboid([10,20,30], strut=1);
//   sparse_cuboid([10,20,30], "Y", strut=1);
//   sparse_cuboid([10,20,30], UP, strut=1);
//   sparse_cuboid(30, FWD, strut=2, rounding=2, $fn=24);
module sparse_cuboid(size, dir=RIGHT, strut=5, maxang=30, max_bridge=20,
    chamfer,
    rounding,
    edges=EDGES_ALL,
    except=[],
    except_edges,
    trimcorners=true,
    teardrop=false,
    anchor=CENTER, spin=0, orient=UP)
{
  size = force_list(size,3);
  dummy1= assert(is_vector(size,3) && all_positive(size), "size must be a positive number or 3-vector")
          assert(in_list(dir,["X","Y","Z"]) || is_vector(dir,3), "dir must be a 3-vector or one of \"X\", \"Y\", or \"Z\"");
  count = len([for(d=dir) if (d!=0) d]);
  dummy2=assert(is_string(dir) || (count==1 && len(dir)<=3), "vector valued dir must have exactly one non-zero component");
  dir = is_string(dir) ? dir
      : dir.x ? "X"
      : dir.y ? "Y"
      : "Z";
  attachable(anchor,spin,orient,size=size){
    intersection(){
      if (dir=="X")
         sparse_wall(size.z,size.y,size.x,strut=strut,maxang=maxang, max_bridge=max_bridge);
      else if (dir=="Y")
         zrot(90)
           sparse_wall(size.z,size.x,size.y,strut=strut,maxang=maxang, max_bridge=max_bridge);
      else
         yrot(90)
           sparse_wall(size.x,size.y,size.z,strut=strut,maxang=maxang, max_bridge=max_bridge);
      cuboid(size=size, chamfer=chamfer, rounding=rounding,edges=edges, except=except, except_edges=except_edges,
           trimcorners=trimcorners, teardrop=teardrop);
    }
    children();
  }    
}


// Module: hex_panel()
// Synopsis: Create a hexagon braced panel of any shape
// SynTags: Geom
// Topics: FDM Optimized, Walls
// See Also: sparse_wall(), hex_panel(), corrugated_wall(), thinning_wall(), thinning_triangle(), narrowing_strut()
// Usage:
//   hex_panel(shape, wall, spacing, [frame=], [bevel=], [bevel_frame=], [h=|height=|l=|length=], [anchor=], [orient=], [spin=])
// Description:
//   Produces a panel with a honeycomb interior that can be rectangular with optional beveling, or
//   an arbitrary polygon shape without beveling. The panel consists of a frame containing
//   a honeycob interior. The frame is laid out in the XY plane with the honeycob interior 
//   and then extruded to the height h. The shape argument defines the outer bounderies of
//   the frame.
//   .
//   The simplest way to define the frame shape is to give a cuboid size as a 3d vector for
//   the shape argument.  The h argument is not allowed in this case.  With rectangular frames you can supply the
//   bevel argument which applies a 45 deg bevel on the specified list of edges.  These edges
//   can be LEFT, RIGHT, FRONT, or BACK to place a bevel the edge facing upward.  You can add
//   BOTTOM, as in LEFT+BOT, to get a bevel that faces down.  When beveling a separate beveled frame
//   is added to the model.  You can independently control its thickness by setting `bevel_frame`, which
//   defaults to the frame thickness.  Note also that `frame` and `bevel_frame` can be set to zero
//   to produce just the honeycomb.  
//   . 
//   The other option is to provide a 2D path as the shape argument. The path must not intersect
//   itself.  You must give the height argument in this case and you cannot give the bevel argument.
//   The panel is made from a linear extrusion of the specified shape.  In this case, anchoring
//   is done as usual for linear sweeps.  The shape appears by default on its base and you can
//   choose "hull" or "intersect" anchor types.  
// Arguments:
//   shape = 3D size vector or a 2D path
//   strut = thickness of hexagonal bracing
//   spacing = center-to-center spacing of hex cells in the honeycomb.
//   ---
//   frame = width of the frame around the honeycomb.  Default: same as strut
//   bevel = list of edges to bevel on rectangular case when shape is a size vector; allowed options are RIGHT, LEFT, BACK, or FRONT, or those directions with BOTTOM added.  Default: []
//   bevel_frame = width of the frame applied at bevels.  Default: same as frame
//   h / height / l / length = thickness of the panel when shape is a path 
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER` for rectangular panels, `"zcenter"` for extrusions.  
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   atype = Select "hull", "intersect" anchor types.  Default: "hull"
//   cp = Centerpoint for determining "intersect" anchors or centering the shape.  Determintes the base of the anchor vector.  Can be "centroid", "mean", "box" or a 3D point.  Default: "centroid"
// Named Anchors:
//   "base" = Anchor to the base of the shape in its native position
//   "top" = Anchor to the top of the shape in its native position
//   "zcenter" = Center shape in the Z direction in the native XY position (default)
// Anchor Types:
//   hull = Anchors to the convex hull of the linear sweep of the path, ignoring any end roundings. 
//   intersect = Anchors to the surface of the linear sweep of the path, ignoring any end roundings.
// Examples:
//     hex_panel([50, 100, 5], strut=1.5, spacing=10);
//     hex_panel([50, 100, 5], 1.5, 10, frame = 5);
//     hex_panel([50, 100, 5], 5, 10.05);
//     hex_panel([50, 100, 5], 1.5, 20, frame = 5);
//     hex_panel([50, 100, 5], 1.5, 12, frame = 0);
//     hex_panel([50, 100, 5], frame = 10, spacing = 20, strut = 4);
//     hex_panel([50, 100, 10], 1.5, 10, frame = 5, bevel = [LEFT, RIGHT]);
//     hex_panel([50, 100, 10], 1.5, 10, frame = 5, bevel = [FWD,  BACK]);
//     hex_panel([50, 100, 10], 1.5, 10, frame = 3, bevel = [LEFT, RIGHT, FWD, BACK]);
//     hex_panel([50, 100, 10], 1.5, 10, frame = 1, bevel = [LEFT, RIGHT, FWD+BOTTOM, BACK+BOTTOM]);
//     hex_panel([50, 100, 10], 1.5, 10, frame=2, bevel_frame=0, bevel = [FWD, BACK+BOT, RIGHT, LEFT]);
// Example: Triangle
//     s = [[0, -40], [0, 40], [60, 0]];
//     hex_panel(s, strut=1.5, spacing=10, h = 10, frame = 5); 
// Example: Concave polygon
//     s = [[0, -40], [0, 70], [60, 0], [80, 20], [70, -20]];
//     hex_panel(s, 1.5, 10, h = 10, frame = 5); 
// Example: Another concave example
//     s = [[0, -40], [0, 40], [30, 20], [60, 40], [60, -40], [30, -20]];
//     hex_panel(s, 1.5, 10, h = 10, frame = 5); 
// Example: Circular panel
//     hex_panel(circle(30), 1.5, 10, h = 10, frame = 5);
// Example: More complicated shape
//     s = glued_circles(d=50, spread=50, tangent=30);
//     hex_panel(s, 1.5, 10, h = 10, frame = 5);
// Example: Care is required when arranging panels vertically for 3d printability.  Setting `orient=RIGHT` produces the correct result. 
//     hex_panel([50, 100, 10], 1.5, 10, frame = 5, bevel = [FWD, BACK], anchor = BACK + RIGHT + BOTTOM, orient = RIGHT);
//     zrot(-90)hex_panel([50, 100, 10], 1.5, 10, frame = 5,  bevel = [FWD, BACK], anchor = FWD + RIGHT + BOTTOM, orient = RIGHT);
// Example: In this example panels one of the panels is positioned with `orient=FWD` which produces hexagons with 60 deg overhang edges that may not be 3d printable.  This example alsu uses `bevel_frame` to thin the material at the corner.  
//     hex_panel([50, 100, 10], 1.5, 10, frame = 5, bevel_frame=1, bevel = [FWD,  BACK], anchor = BACK + RIGHT + BOTTOM, orient = RIGHT);
//     hex_panel([100, 50, 10], 1.5, 10, frame = 5, bevel_frame=1, bevel = [LEFT, RIGHT], anchor = FWD + LEFT + BOTTOM, orient = FWD);
// Example: Joining panels with {{attach()}}.  In this case panels were joined front beveled edge to back beveled edge, which means the hex structure doesn't align at the joint
//     hex_panel([50, 100, 10], 1.5, 10, frame = 5, bevel_frame=0, bevel = [FWD, BACK], anchor = BACK + RIGHT + BOTTOM, orient = RIGHT)
//       attach(BACK,FRONT) 
//          hex_panel([50, 100, 10], 1.5, 10, frame = 5, bevel_frame=0, bevel = [FWD, BACK]);
// Example: Joining panels with {{attach()}}.  Attaching BACK to BACK aligns the hex structure which looks better.  
//     hex_panel([50, 100, 10], 1.5, 10, frame = 1, bevel = [FWD, BACK], anchor = BACK + RIGHT + BOTTOM, orient = RIGHT)
//       attach(BACK,BACK) 
//          hex_panel([50, 100, 10], 1.5, 10, frame = 1, bevel = [FWD, BACK]);
module hex_panel(
    shape,
    strut,
    spacing,
    frame,
    bevel_frame,
    h, height, l, length, 
    bevel = [],
    anchor, 
    orient = UP, cp="centroid", atype="hull",
    spin = 0) 
{
    frame = first_defined([frame,strut]);
    bevel_frame = first_defined([bevel_frame, frame]);
    shape = force_path(shape,"shape");
    bevel = is_vector(bevel) ? [bevel] : bevel;
    bevOK = len([for(bev=bevel) if (norm([bev.x,bev.y])==1 && (bev.x==0 || bev.y==0) && (bev.z==0 || bev.z==-1)) 1]) == len(bevel);
    dummy=
      assert(is_finite(strut) && strut > 0, "strut must be positive")
      assert(is_finite(frame) && frame >= 0, "frame must be nonnegative")
      assert(is_finite(bevel_frame) && bevel_frame >= 0, "bevel_frame must be nonnegative")
      assert(is_finite(spacing) && spacing>0, "spacing must be positive")
      assert(is_path(shape,2) || is_vector(shape, 3), "shape must be a path or a 3D vector")
      assert(len(bevel) == 0 || is_vector(shape, 3), "bevel must be used only on rectangular panels")
      assert(is_path(shape) || all_positive(shape), "when shape is a size vector all components must be positive")
      assert(bevOK, "bevel list contains an invalid entry")
      assert(!(in_list(FRONT, bevel) && in_list(FRONT+BOTTOM, bevel)), "conflicting FRONT bevels")
      assert(!(in_list(BACK,  bevel) && in_list(BACK+BOTTOM,  bevel)), "conflicting BACK bevels")
      assert(!(in_list(RIGHT, bevel) && in_list(RIGHT+BOTTOM, bevel)), "conflicting RIGHT bevels")
      assert(!(in_list(LEFT,  bevel) && in_list(LEFT+BOTTOM,  bevel)), "conflicting LEFT bevels")
      assert(is_undef(h) || is_path(shape), "cannot give h with a size vector");
    shp = is_path(shape) ? shape : square([shape.x, shape.y], center = true);
    ht = is_path(shape) ? one_defined([h,l,height,length],"height,length,l,h")
       : shape.z;
    
    bounds = pointlist_bounds(shp);
    sizes = bounds[1] - bounds[0]; // [xsize, ysize]
    assert(frame*2 + spacing < sizes[0], "There must be room for at least 1 cell in the honeycomb");
    assert(frame*2 + spacing < sizes[1], "There must be room for at least 1 cell in the honeycomb");

    bevpaths = len(bevel)==0 ? []
             : _bevelSolid(shape,bevel);
    if (len(bevel) > 0) {
         size1 = [bevpaths[0][0].x-bevpaths[0][1].x, bevpaths[0][2].y-bevpaths[0][1].y,ht];
         size2 = [bevpaths[1][0].x-bevpaths[1][1].x, bevpaths[1][2].y-bevpaths[1][1].y];
         shift = point2d(centroid(bevpaths[1])-centroid(bevpaths[0]));
         offset = (centroid(bevpaths[0]));
         attachable(anchor,spin,orient,size=size1,size2=size2,shift=shift,offset=offset){
             down(ht/2)
                 intersection() {
                     union() {
                         linear_extrude(height = ht, convexity=8) {
                             _honeycomb(shp, spacing = spacing, hex_wall = strut);
                             offset_stroke(shp, width=[-frame, 0], closed=true);
                         }
                         for (b = bevel) _bevelWall(shape, b, bevel_frame);
                     }
                     vnf_polyhedron(vnf_vertex_array(bevpaths, col_wrap=true, caps=true));
                 }
             children();
         }
     }
     else if (is_vector(shape)){
         attachable(anchor = anchor, spin = spin, orient = orient, size = shape) {        
             down(ht/2) 
                 linear_extrude(height = ht, convexity=8) {
                     _honeycomb(shp, spacing = spacing, hex_wall = strut);
                     offset_stroke(shp, width=[-frame, 0], closed=true);
                 }
             children();
         }
    }
    else {
         anchors = [
           named_anchor("zcenter", [0,0,0], UP),
           named_anchor("base", [0,0,-ht/2], UP),
           named_anchor("top", [0,0,ht/2], UP)          
         ];
         attachable(anchor = default(anchor,"zcenter"), spin = spin, orient = orient, path=shp, h=ht, cp=cp, extent=atype=="hull",anchors=anchors) {        
              down(ht/2) 
                 linear_extrude(height = ht, convexity=8) {
                     _honeycomb(shp, spacing = spacing, hex_wall = strut);
                     offset_stroke(shp, width=[-frame, 0], closed=true);
                 }
             children();
         }

    } 
}


module _honeycomb(shape, spacing=10, hex_wall=1) 
{
        hex = hexagon(id=spacing-hex_wall, spin=180/6);
        bounds = pointlist_bounds(shape);
        size = bounds[1] - bounds[0];
        hex_rgn2 = grid_copies(spacing=spacing, size=size, stagger=true, p=hex);
        center = (bounds[0] + bounds[1]) / 2;
        hex_rgn = move(center, p=hex_rgn2);
        difference(){
            polygon(shape);
            region(hex_rgn);
        }
}


function _bevelSolid(shape, bevel) =
  let(
    tX = in_list(RIGHT,          bevel) ? -shape.z : 0,
    tx = in_list(LEFT,           bevel) ?  shape.z : 0,
    tY = in_list(BACK,           bevel) ? -shape.z : 0,
    ty = in_list(FRONT,          bevel) ?  shape.z : 0,
    bX = in_list(RIGHT + BOTTOM, bevel) ? -shape.z : 0,
    bx = in_list(LEFT  + BOTTOM, bevel) ?  shape.z : 0,
    bY = in_list(BACK  + BOTTOM, bevel) ? -shape.z : 0,
    by = in_list(FRONT + BOTTOM, bevel) ?  shape.z : 0,
    pathB = path3d(rect(select(shape,0,1)) + [[bX,by],[bx,by],[bx,bY],[bX,bY]]),
    pathT = path3d(rect(select(shape,0,1)) + [[tX,ty],[tx,ty],[tx,tY],[tX,tY]],shape.z)
  )
  [pathB,pathT];

module _bevelWall(shape, bevel, thickness) {

    l = bevel.y != 0 ? shape.x : shape.y;
    d = bevel.y != 0 ? shape.y : shape.x;
    zr = bevel.y == -1 ? 180 
       : bevel.y ==  1 ? 0 
       : bevel.x == -1 ? 90 
       : bevel.x ==  1 ? 270 
       : undef;
    xr = bevel.x != 0 && bevel.z < 0 ? 180 : 0;
    yr = bevel.y != 0 && bevel.z < 0 ? 180 : 0;
    
    path = [[-thickness, 0], [0, 0], [-shape.z, -shape.z], [-shape.z-thickness, -shape.z]];

    up(shape.z/2)
    xrot(xr) yrot(yr) zrot(zr) down(shape.z/2)
      back(d/2) right(l/2) 
      zrot(90) xrot(-90)
        linear_extrude(l) polygon(path);
}


// Module: corrugated_wall()
// Synopsis: Makes a corrugated rectangular wall.
// SynTags: Geom
// Topics: FDM Optimized, Walls
// See Also: sparse_wall(), corrugated_wall(), thinning_wall(), thinning_triangle(), narrowing_strut()
//
// Usage:
//   corrugated_wall(h, l, thick, [strut=], [wall=]) [ATTACHMENTS];
//
// Description:
//   Makes a corrugated wall which relieves contraction stress while still
//   providing support strength.  Designed with 3D printing in mind.
//
// Arguments:
//   h = height of strut wall.
//   l = length of strut wall.
//   thick = thickness of strut wall.
//   ---
//   strut = the width of the frame.
//   wall = thickness of corrugations.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//
// See Also: sparse_wall(), thinning_wall()
//
// Example: Typical Shape
//   corrugated_wall(h=50, l=100);
// Example: Wider Strut
//   corrugated_wall(h=50, l=100, strut=8);
// Example: Thicker Wall
//   corrugated_wall(h=50, l=100, strut=8, wall=3);
module corrugated_wall(h=50, l=100, thick=5, strut=5, wall=2, anchor=CENTER, spin=0, orient=UP)
{
    amplitude = (thick - wall) / 2;
    period = min(15, thick * 2);
    steps = quantup(segs(thick/2),4);
    step = period/steps;
    il = l - 2*strut + 2*step;
    size = [thick, l, h];
    attachable(anchor,spin,orient, size=size) {
        union() {
            linear_extrude(height=h-2*strut+0.1, slices=2, convexity=ceil(2*il/period), center=true) {
                polygon(
                    points=concat(
                        [for (y=[-il/2:step:il/2]) [amplitude*sin(y/period*360)-wall/2, y] ],
                        [for (y=[il/2:-step:-il/2]) [amplitude*sin(y/period*360)+wall/2, y] ]
                    )
                );
            }
            difference() {
                cube([thick, l, h], center=true);
                cube([thick+0.5, l-2*strut, h-2*strut], center=true);
            }
        }
        children();
    }
}


// Module: thinning_wall()
// Synopsis: Makes a rectangular wall with a thin middle.
// SynTags: Geom
// Topics: FDM Optimized, Walls
// See Also: sparse_wall(), corrugated_wall(), thinning_wall(), thinning_triangle(), narrowing_strut()
//
// Usage:
//   thinning_wall(h, l, thick, [ang=], [braces=], [strut=], [wall=]) [ATTACHMENTS];
//
// Description:
//   Makes a rectangular wall which thins to a smaller width in the center,
//   with angled supports to prevent critical overhangs.
//
// Arguments:
//   h = Height of wall.
//   l = Length of wall.  If given as a vector of two numbers, specifies bottom and top lengths, respectively.
//   thick = Thickness of wall.
//   ---
//   ang = Maximum overhang angle of diagonal brace.
//   braces = If true, adds diagonal crossbraces for strength.
//   strut = The width of the borders and diagonal braces.  Default: `thick/2`
//   wall = The thickness of the thinned portion of the wall.  Default: `thick/2`
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//
// See Also: sparse_wall(), corrugated_wall(), thinning_triangle()
//
// Example: Typical Shape
//   thinning_wall(h=50, l=80, thick=4);
// Example: Trapezoidal
//   thinning_wall(h=50, l=[80,50], thick=4);
// Example: Trapezoidal with Braces
//   thinning_wall(h=50, l=[80,50], thick=4, strut=4, wall=2, braces=true);
module thinning_wall(h=50, l=100, thick=5, ang=30, braces=false, strut, wall, anchor=CENTER, spin=0, orient=UP)
{
    l1 = (l[0] == undef)? l : l[0];
    l2 = (l[1] == undef)? l : l[1];
    strut = is_num(strut)? strut : min(h,l1,l2,thick)/2;
    wall = is_num(wall)? wall : thick/2;

    bevel_h = strut + (thick-wall)/2/tan(ang);
    cp1 = circle_2tangents(strut, [0,0,+h/2], [l2/2,0,+h/2], [l1/2,0,-h/2])[0];
    cp2 = circle_2tangents(bevel_h, [0,0,+h/2], [l2/2,0,+h/2], [l1/2,0,-h/2])[0];
    cp3 = circle_2tangents(bevel_h, [0,0,-h/2], [l1/2,0,-h/2], [l2/2,0,+h/2])[0];
    cp4 = circle_2tangents(strut, [0,0,-h/2], [l1/2,0,-h/2], [l2/2,0,+h/2])[0];

    z1 = h/2;
    z2 = cp1.z;
    z3 = cp2.z;

    x1 = l2/2;
    x2 = cp1.x;
    x3 = cp2.x;
    x4 = l1/2;
    x5 = cp4.x;
    x6 = cp3.x;

    y1 = thick/2;
    y2 = wall/2;

    corner1 = [ x2, 0,  z2];
    corner2 = [-x5, 0, -z2];
    brace_len = norm(corner1-corner2);

    size = [l1, thick, h];
    attachable(anchor,spin,orient, size=size, size2=[l2,thick]) {
        zrot(90) {
            polyhedron(
                points=[
                    [-x4, -y1, -z1],
                    [ x4, -y1, -z1],
                    [ x1, -y1,  z1],
                    [-x1, -y1,  z1],

                    [-x5, -y1, -z2],
                    [ x5, -y1, -z2],
                    [ x2, -y1,  z2],
                    [-x2, -y1,  z2],

                    [-x6, -y2, -z3],
                    [ x6, -y2, -z3],
                    [ x3, -y2,  z3],
                    [-x3, -y2,  z3],

                    [-x4,  y1, -z1],
                    [ x4,  y1, -z1],
                    [ x1,  y1,  z1],
                    [-x1,  y1,  z1],

                    [-x5,  y1, -z2],
                    [ x5,  y1, -z2],
                    [ x2,  y1,  z2],
                    [-x2,  y1,  z2],

                    [-x6,  y2, -z3],
                    [ x6,  y2, -z3],
                    [ x3,  y2,  z3],
                    [-x3,  y2,  z3],
                ],
                faces=[
                    [ 4,  5,  1],
                    [ 5,  6,  2],
                    [ 6,  7,  3],
                    [ 7,  4,  0],

                    [ 4,  1,  0],
                    [ 5,  2,  1],
                    [ 6,  3,  2],
                    [ 7,  0,  3],

                    [ 8,  9,  5],
                    [ 9, 10,  6],
                    [10, 11,  7],
                    [11,  8,  4],

                    [ 8,  5,  4],
                    [ 9,  6,  5],
                    [10,  7,  6],
                    [11,  4,  7],

                    [11, 10,  9],
                    [20, 21, 22],

                    [11,  9,  8],
                    [20, 22, 23],

                    [16, 17, 21],
                    [17, 18, 22],
                    [18, 19, 23],
                    [19, 16, 20],

                    [16, 21, 20],
                    [17, 22, 21],
                    [18, 23, 22],
                    [19, 20, 23],

                    [12, 13, 17],
                    [13, 14, 18],
                    [14, 15, 19],
                    [15, 12, 16],

                    [12, 17, 16],
                    [13, 18, 17],
                    [14, 19, 18],
                    [15, 16, 19],

                    [ 0,  1, 13],
                    [ 1,  2, 14],
                    [ 2,  3, 15],
                    [ 3,  0, 12],

                    [ 0, 13, 12],
                    [ 1, 14, 13],
                    [ 2, 15, 14],
                    [ 3, 12, 15],
                ],
                convexity=6
            );
            if(braces) {
                bracepath = [
                    [-strut*0.33,thick/2],
                    [ strut*0.33,thick/2],
                    [ strut*0.33+(thick-wall)/2/tan(ang), wall/2],
                    [ strut*0.33+(thick-wall)/2/tan(ang),-wall/2],
                    [ strut*0.33,-thick/2],
                    [-strut*0.33,-thick/2],
                    [-strut*0.33-(thick-wall)/2/tan(ang),-wall/2],
                    [-strut*0.33-(thick-wall)/2/tan(ang), wall/2]
                ];
                xflip_copy() {
                    intersection() {
                        extrude_from_to(corner1,corner2) {
                            polygon(bracepath);
                        }
                        prismoid([l1,thick],[l2,thick],h=h,anchor=CENTER);
                    }
                }
            }
        }
        children();
    }
}


// Module: thinning_triangle()
// Synopsis: Makes a triangular wall with a thin middle.
// SynTags: Geom
// Topics: FDM Optimized, Walls
// See Also: sparse_wall(), corrugated_wall(), thinning_wall(), thinning_triangle(), narrowing_strut()
//
// Usage:
//   thinning_triangle(h, l, thick, [ang=], [strut=], [wall=], [diagonly=], [center=]) [ATTACHMENTS];
//
// Description:
//   Makes a triangular wall with thick edges, which thins to a smaller width in
//   the center, with angled supports to prevent critical overhangs.
//
// Arguments:
//   h = height of wall.
//   l = length of wall.
//   thick = thickness of wall.
//   ---
//   ang = maximum overhang angle of diagonal brace.
//   strut = the width of the diagonal brace.
//   wall = the thickness of the thinned portion of the wall.
//   diagonly = boolean, which denotes only the diagonal side (hypotenuse) should be thick.
//   center = If true, centers shape.  If false, overrides `anchor` with `UP+BACK`.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//
// See Also: thinning_wall()
//
// Example: Centered
//   thinning_triangle(h=50, l=80, thick=4, ang=30, strut=5, wall=2, center=true);
// Example: All Braces
//   thinning_triangle(h=50, l=80, thick=4, ang=30, strut=5, wall=2, center=false);
// Example: Diagonal Brace Only
//   thinning_triangle(h=50, l=80, thick=4, ang=30, strut=5, wall=2, diagonly=true, center=false);
module thinning_triangle(h=50, l=100, thick=5, ang=30, strut=5, wall=3, diagonly=false, center, anchor, spin=0, orient=UP)
{
    dang = atan(h/l);
    dlen = h/sin(dang);
    size = [thick, l, h];
    anchor = get_anchor(anchor, center, BOT+FRONT, CENTER);
    attachable(anchor,spin,orient, size=size) {
        difference() {
            union() {
                if (!diagonly) {
                    translate([0, 0, -h/2])
                        narrowing_strut(w=thick, l=l, wall=strut, ang=ang);
                    translate([0, -l/2, 0])
                        xrot(-90) narrowing_strut(w=thick, l=h-0.1, wall=strut, ang=ang);
                }
                intersection() {
                    cube(size=[thick, l, h], center=true);
                    xrot(-dang) yrot(180) {
                        narrowing_strut(w=thick, l=dlen*1.2, wall=strut, ang=ang);
                    }
                }
                cube(size=[wall, l-0.1, h-0.1], center=true);
            }
            xrot(-dang) {
                translate([0, 0, h/2]) {
                    cube(size=[thick+0.1, l*2, h], center=true);
                }
            }
        }
        children();
    }
}


// Module: narrowing_strut()
// Synopsis: Makes a strut like an extruded baseball home plate.
// SynTags: Geom
// Topics: FDM Optimized
// See Also: sparse_wall(), corrugated_wall(), thinning_wall(), thinning_triangle(), narrowing_strut()
//
// Usage:
//   narrowing_strut(w, l, wall, [ang=]) [ATTACHMENTS];
//
// Description:
//   Makes a rectangular strut with the top side narrowing in a triangle.
//   The shape created may be likened to an extruded home plate from baseball.
//   This is useful for constructing parts that minimize the need to support
//   overhangs.
//
// Arguments:
//   w = Width (thickness) of the strut.
//   l = Length of the strut.
//   wall = height of rectangular portion of the strut.
//   ---
//   ang = angle that the trianglar side will converge at.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//
// Example:
//   narrowing_strut(w=10, l=100, wall=5, ang=30);
module narrowing_strut(w=10, l=100, wall=5, ang=30, anchor=BOTTOM, spin=0, orient=UP)
{
    h = wall + w/2/tan(ang);
    size = [w, l, h];
    attachable(anchor,spin,orient, size=size) {
        xrot(90)
        fwd(h/2) {
            linear_extrude(height=l, center=true, slices=2) {
                back(wall/2) square([w, wall], center=true);
                back(wall-0.001) {
                    yscale(1/tan(ang)) {
                        difference() {
                            zrot(45) square(w/sqrt(2), center=true);
                            fwd(w/2) square(w, center=true);
                        }
                    }
                }
            }
        }
        children();
    }
}



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
