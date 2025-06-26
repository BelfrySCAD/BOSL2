//////////////////////////////////////////////////////////////////////
// LibFile: vnf.scad
//   The Vertices'N'Faces structure (VNF) holds the data used by polyhedron() to construct objects: a vertex
//   list and a list of faces.  This library makes it easier to construct polyhedra by providing
//   functions to construct, merge, and modify VNF data, while avoiding common pitfalls such as
//   reversed faces.  It can find faults in your polyhedrons.  This file is for low level manipulation
//   of lists of vertices and faces: it can perform some simple transformations on VNF structures
//   but *cannot* perform boolean operations on the polyhedrons represented by VNFs.
// Includes:
//   include <BOSL2/std.scad>
// FileGroup: Advanced Modeling
// FileSummary: Vertices 'n' Faces structure.  Makes polyhedron() easier to use.
// FileFootnotes: STD=Included in std.scad
//////////////////////////////////////////////////////////////////////


// Section: Creating Polyhedrons with VNF Structures
//   VNF stands for "Vertices'N'Faces".  VNF structures are 2-item lists, `[VERTICES,FACES]` where the
//   first item is a list of vertex points, and the second is a list of face indices into the vertex
//   list.  Each VNF is self contained, with face indices referring only to its own vertex list.
//   You can construct a `polyhedron()` in parts by describing each part in a self-contained VNF, then
//   merge the various VNFs to get the completed polyhedron vertex list and faces.

/// Constant: EMPTY_VNF
/// Description:
///   The empty VNF data structure.  Equal to `[[],[]]`.
EMPTY_VNF = [[],[]];  // The standard empty VNF with no vertices or faces.


// Function&Module: vnf_vertex_array()
// Synopsis: Returns a VNF structure from a rectangular vertex list.
// SynTags: VNF, Geom
// Topics: VNF Generators, Lists, Textures
// See Also: vnf_tri_array(), vnf_join(), vnf_from_polygons(), vnf_from_region()
// Usage:
//   vnf = vnf_vertex_array(points, [caps=], [cap1=], [cap2=], [style=], [reverse=], [col_wrap=], [row_wrap=], [triangulate=]);
//   vnf_vertex_array(points, [caps=], [cap1=], [cap2=], [style=], [reverse=], [col_wrap=], [row_wrap=], [triangulate=],...) [ATTACHMENTS];
// Description:
//   Creates a VNF structure from a rectangular vertex list, creating edges that connect the adjacent vertices in the vertex list
//   and creating the faces defined by those edges.  You can optionally create the edges and faces to wrap the last column
//   back to the first column, or wrap the last row to the first.  Endcaps can be added to either
//   the first and/or last rows.  The style parameter determines how the quadrilaterals are divided into
//   triangles.  The styles are:
//   * "default" &mdash; arbitrary, systematic subdivision in the same direction
//   * "alt" &mdash; uniform subdivision in the other (alternate) direction
//   * "flip1" &mdash; arbitrary division that alternates the direction adjacent pairs of quadrilaterals.
//   * "flip2" &mdash; the alternating division that is the opposite of "flip1". 
//   * "min_edge" &mdash; subdivide each quadrilateral on its shorter edge, so the division may not be uniform across the shape
//   * "min_area" &mdash; creates the triangulation with the minimal area.
//   * "quincunx" &mdash; adds a vertex in the center of each quadrilateral and creates four triangles
//   * "convex" &mdash; choose the locally convex division
//   * "concave" &mdash; choose the locally concave division
//   * "quad" &mdash; makes quadrilateral edges, which may not be coplanar, relying on OpensCAD to decide how to handle them.
// Degenerate faces are not included in the output, but if this results in unused vertices, those unused vertices do still appear in the output.
//   .
//   You can apply a texture to the vertex array VNF using the usual texture parameters.
//   See [Texturing](skin.scad#section-texturing) for more details on how textures work.  
//   The top left corner of the texture tile is aligned with `points[0][0]`, and the the X and Y directions correspond to `points[y][x]`.
//   In practice, it is probably easiest to observe the result and apply a suitable texture tile rotation by setting `tex_rot` if the result
//   is not what you wanted.  The reference scale of your point data is also taken from the square at the [0][0] corner.  This determines
//   the meaning of `tex_size` and it also affects the vertical texture scale.  The size of the texture tiles is proportional to the point
//   spacing of the location where they are placed, so if the points are closer together, you get small texture elements.  The specified `tex_depth`
//   is correct at the `points[0][0]` but would be different at places in the point array where the scale is different.  This
//   differs from {{rotate_sweep()}}, which uses a uniform resampling of the curve you specify.
//   .
//   The vertical scale of texture elements adjusts based on the size of the grid square where it is placed.  By default, the height is scaled by the average
//   of the width and height of the texture element.  You can disable this scaling by setting `tex_scaling="const"`, which results
//   in a constant height that does not vary with the grid spacing.  
//   .
//   The point data for `vnf_vertex_array()` is resampled using bilinear interpolation to match the required point density of the tile count, but the
//   sampling is based on the grid, not on the distance between points.  If you want to
//   avoid resampling, match the point data to the required point number for your tile count.  For height field textures this means
//   the number of data points must equal the tile count times the number of entries in the tile minus `tex_skip` plus `tex_extra`.
//   Note that `tex_extra` defaults to 1 along dimensions that are not wrapped.  For a VNF tile you need to have the the point
//   count equal to the tile count times tex_samples, plus one if wrapping is disabled.  
//   .
//   For creating the texture, `vnf_vertex_array()` uses normals to the surface that it estimates from the surface data itself.
//   If you have more accurate normals or need the normals to take particular values, you can pass an array of normals
//   using the `normals` parameter.
//   .
//   You can set `return_edges=true` to return the paths of the four edges of the output.  In this case the return value
//   is `[vnf,edgelist]` where edgelist is [left (column 0 of points), right (last column of points), top (points[0]), bottom (last(points)]. If a given
//   edge does not exist then it will be the empty list in the output.  An edge only exists it is not capped and not wrapped.  The main
//   need for this feature is when you have added a texture and need a way to interface the shape with something else.  In this case you cannot
//   easily determine the edges yourself from the input point list. edges are not easily 
// Arguments:
//   points = A list of vertices to divide into columns and rows.
//   ---
//   caps = If true, add endcap faces to the first **and** last rows.
//   cap1 = If true, add an endcap face to the first row.
//   cap2 = If true, add an endcap face to the last row.
//   col_wrap = If true, add faces to connect the last column to the first.
//   row_wrap = If true, add faces to connect the last row to the first.
//   reverse = If true, reverse all face normals.
//   style = The style of subdividing the quads into faces.  Valid options are "default", "alt", "flip1", "flip2",  "min_edge", "min_area", "quincunx", "convex" and "concave".
//   triangulate = If true, triangulates endcaps to resolve possible CGAL issues.  This can be an expensive operation if the endcaps are complex.  Default: false
//   convexity = (module) Max number of times a line could intersect a wall of the shape.
//   texture = A texture name string, or a rectangular array of scalar height values (0.0 to 1.0), or a VNF tile that defines the texture to apply to vertical surfaces.  See {{texture()}} for what named textures are supported.
//   tex_size = An optional 2D target size for the textures at `points[0][0]`.  Actual texture sizes are scaled somewhat to evenly fit the available surface.
//   tex_reps = If given instead of tex_size, a 2-vector giving the number of texture tile repetitions in the horizontal and vertical directions.
//   tex_inset = If numeric, lowers the texture into the surface by the specified proportion, e.g. 0.5 would lower it half way into the surface.  If `true`, insets by exactly its full depth.  Default: `false`
//   tex_rot = Rotate texture by specified angle, which must be a multiple of 90 degrees.  Default: 0
//   tex_depth = Specify texture depth; if negative, invert the texture.  Default: 1.  
//   tex_samples = Minimum number of "bend points" to have in VNF texture tiles.  Default: 8
//   tex_extra = number of extra lines of a hightfield texture to add at the end.  Can be a scalar or 2-vector to give x and y values.  Default: 1
//   tex_skip = number of lines of a heightfield texture to skip when starting.  Can be a scalar or two vector to give x and y values.  Default: 0
//   sidecaps = if `col_wrap==false` this controls whether to cap any floating ends of a VNF tile on the texture.  Does not affect the main texture surface.  Ignored it doesn't apply.  Default: false
//   sidecap1 = set sidecap only for the `points[][0]` edge of the output
//   sidecap2 = set sidecap only for the `points[][max]` edge of the output
//   tex_scaling = set to "const" to disable grid size vertical scaling of the texture.  Default: "default"
//   normals = array of normal vectors to each point in the point array for more accurate texture height calculation
//   return_edges = if true return [vnf,edgelist] where edgelist is the paths of four edges, [left (column 0 of points), right (last column of points), top (points[0]), bottom (last(points)].  Default: false
//   cp = (module) Centerpoint for determining intersection anchors or centering the shape.  Determines the base of the anchor vector.  Can be "centroid", "mean", "box" or a 3D point.  Default: "centroid"
//   anchor = (module) Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `"origin"`
//   spin = (module) Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = (module) Vector to rotate top toward, after spin. See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   atype = (module) Select "hull" or "intersect" anchor type.  Default: "hull"
// Anchor Types:
//   "hull" = Anchors to the virtual convex hull of the shape.
//   "intersect" = Anchors to the surface of the shape.
// Named Anchors:
//   "origin" = Anchor at the origin, oriented UP.
// Example(3D):
//   vnf = vnf_vertex_array(
//       points=[
//           for (h = [0:5:180-EPSILON]) [
//               for (t = [0:5:360-EPSILON])
//                   cylindrical_to_xyz(100 + 12 * cos((h/2 + t)*6), t, h)
//           ]
//       ],
//       col_wrap=true, caps=true, reverse=true, style="alt"
//   );
//   vnf_polyhedron(vnf);
// Example(3D,NoAxes,ThrownTogether,VPD=183): Open shape made from a three arcs.
//   rows = [
//       for(h=[-20:20:20])
//           path3d(arc(r=40-abs(h), angle=280, 10), h)
//   ];
//   vnf = vnf_vertex_array(rows, reverse=true);
//   vnf_polyhedron(vnf);
//   color("green") vnf_wireframe(vnf);
// Example(3D,NoAxes,ThrownTogether,VPD=183): Open shape made from a three arcs, with `row_wrap=true`.
//   rows = [
//       for(h=[-20:20:20])
//           path3d(arc(r=40-abs(h), angle=280, 10), h)
//   ];
//   vnf = vnf_vertex_array(rows, reverse=true, row_wrap=true);
//   vnf_polyhedron(vnf);
//   color("green") vnf_wireframe(vnf);
// Example(3D,NoAxes,ThrownTogether,VPD=183): Open shape made from a three arcs, with `col_wrap=true`.
//   rows = [
//       for(h=[-20:20:20])
//           path3d(arc(r=40-abs(h), angle=280, 10), h)
//   ];
//   vnf = vnf_vertex_array(rows, reverse=true, col_wrap=true);
//   vnf_polyhedron(vnf);
//   color("green") vnf_wireframe(vnf);
// Example(3D,NoAxes,ThrownTogether,VPD=183): Open shape made from a three arcs, with `caps=true` and `col_wrap=true`.
//   rows = [
//       for(h=[-20:20:20])
//           path3d(arc(r=40-abs(h), angle=280, 10), h)
//   ];
//   vnf = vnf_vertex_array(rows, reverse=true, caps=true, col_wrap=true);
//   vnf_polyhedron(vnf);
//   color("green") vnf_wireframe(vnf);
// Example(3D): Both `col_wrap` and `row_wrap` are true to make a torus.
//   vnf = vnf_vertex_array(
//       points=[
//           for (a=[0:5:360-EPSILON])
//               apply(
//                   zrot(a) * right(30) * xrot(90),
//                   path3d(circle(d=20))
//               )
//       ],
//       col_wrap=true, row_wrap=true, reverse=true
//   );
//   vnf_polyhedron(vnf);
// Example(3D): Möbius Strip.  Note that `row_wrap` is not used, and the first and last profile copies are the same.
//   vnf = vnf_vertex_array(
//       points=[
//           for (a=[0:5:360]) apply(
//               zrot(a) * right(30) * xrot(90) * zrot(a/2+60),
//               path3d(square([1,10], center=true))
//           )
//       ],
//       col_wrap=true, reverse=true
//   );
//   vnf_polyhedron(vnf);
// Example(3D): Assembling a Polyhedron from Multiple Parts
//   wall_points = [
//       for (a = [-90:2:90]) apply(
//           up(a) * scale([1-0.1*cos(a*6),1-0.1*cos((a+90)*6),1]),
//           path3d(circle(d=100))
//       )
//   ];
//   cap = [
//       for (a = [0:0.01:1+EPSILON]) apply(
//           up(90-5*sin(a*360*2)) * scale([a,a,1]),
//           wall_points[0]
//       )
//   ];
//   cap1 = [for (p=cap) down(90, p=zscale(-1, p=p))];
//   cap2 = [for (p=cap) up(90, p=p)];
//   vnf1 = vnf_vertex_array(points=wall_points, col_wrap=true);
//   vnf2 = vnf_vertex_array(points=cap1, col_wrap=true);
//   vnf3 = vnf_vertex_array(points=cap2, col_wrap=true, reverse=true);
//   vnf_polyhedron([vnf1, vnf2, vnf3]);
// Example(3D): Building a Multi-Stage Cylindrical Ramp
//   include <BOSL2/rounding.scad>
//   major_r = 50;
//   groove_profile = [
//       [-10,0], each arc(points=[[-7,0],[0,-3],[7,0]]), [10,0]
//   ];
//   ramp_profile = [ [-10,25], [90,25], [180,5], [190,5] ];
//   rgroove = apply(right(major_r) * xrot(90), path3d(groove_profile));
//   rprofile = round_corners(ramp_profile, radius=20, closed=false, $fn=72);
//   vnf = vnf_vertex_array([
//       for (a = [ramp_profile[0].x : 1 : last(ramp_profile).x]) let(
//           z = lookup(a,rprofile),
//           m = zrot(a) * up(z)
//       )
//       apply(m, [ [rgroove[0].x,0,-z], each rgroove, [last(rgroove).x,0,-z] ])
//   ], caps=true, col_wrap=true, reverse=true);
//   vnf_polyhedron(vnf, convexity=8);
// Example(3D,NoAxes,VPR=[73,0,27],VPD=260,VPT=[0,0,42]): This vase shape cannot be constructed with rotational or linear sweeps. Using a vertex array to create a stack of polygons is the most practical way to make this and many other shapes. The cross-section is a rounded 9-pointed star that changes size and rotates back and forth as it rises in the z direction.
//   include <BOSL2/rounding.scad>
//   
//   vprofile = 
//       smooth_path([[25,0], [35,8], [45,20], [40,40], [25,50], [30,65], [32,70], [37,80]],
//                   relsize=1, method="corners");
//   ridgepd = 20; // z period of star point wiggle
//   ridgeamp = 5; // amplitude of star point wiggle
//   polystack = [
//       for(p=vprofile) let(r=p.x, z=p.y)
//           path3d(
//               smooth_path(
//                   zrot(ridgeamp*sin(360*z/ridgepd), p=star(11, or=r+ridgeamp, ir=r-ridgeamp)),
//                   relsize=0.6, splinesteps=5, method="corners", closed=true),
//               z)
//   ];
//   vnf_polyhedron(vnf_vertex_array(polystack, col_wrap=true, caps=true));
// Example(3D,NoAxes,VPR=[73,0,27],VPD=260,VPT=[0,0,42]): The previous vase shape with a pebbly texture, simply by adding `texture="dots"` to the `vnf_vertex_array()` call. Because textures are spread over grid units and not measurement units, the data points in the polygon stack should be uniformly spaced. 
//   include <BOSL2/rounding.scad>
//   
//   vprofile = resample_path(
//       smooth_path([[25,0], [35,8], [45,20], [40,40], [25,50], [30,65], [32,70], [37,80]],
//                   relsize=1, method="corners"),
//       81, closed=false);
//   ridgepd = 20; // z period of star point wiggle
//   ridgeamp = 5; // amplitude of star point wiggle
//   polystack = [
//       for(p=vprofile) let(r=p.x, z=p.y)
//           path3d(
//               smooth_path(
//                   zrot(ridgeamp*sin(360*z/ridgepd), p=star(11, or=r+ridgeamp, ir=r-ridgeamp)),
//                   relsize=0.6, splinesteps=5, method="corners", closed=true),
//               z)
//   ];
//   vnf_polyhedron(vnf_vertex_array(polystack, col_wrap=true, caps=true,
//       texture="dots", tex_samples=1, tex_size=5));
// Example(3D,Med,NoAxes,VPR=[0,0,0],VPD=126.00,VPT=[-0.35,-0.54,4.09]): This point array defines a simple square, but with a non-uniform grid. 
//   pts = [for(x=[-1:.1:1])
//             [for(y=[-1:.1:1])
//                 zrot(45*min([abs(x-1),abs(x+1),abs(y-1),abs(y+1)]),
//                      20*[x,y,0])]];
//   vnf=vnf_vertex_array(pts);
//   color("blue") vnf_wireframe(vnf,width=.2);
// Example(3D,Med,NoAxes,VPR=[0,0,0],VPD=126.00,VPT=[-0.35,-0.54,4.09]): The non-uniform grid gives rise to a non-uniform texturing, showing the effect of the uniformity and distribution of the points when creating a texture. 
//   pts = [for(x=[-1:.1:1])
//             [for(y=[-1:.1:1])
//                 zrot(45*min([abs(x-1),abs(x+1),abs(y-1),abs(y+1)]),
//                      20*[x,y,0])]];
//   vnf_vertex_array(pts,texture="dots",tex_reps=15);
// Example(3D,Med,NoAxes,VPD=300,VPT=[48,48,0]): Here is another example showing the effect of nonuniform sampling. Here is a surface with a wrinkle in both x and y directions, using location data generated by {{smooth_path()}}, which uses beziers. Bezier curves have non-uniformly distributed points, indicated by the red dots along each edge, which results in a non-uniform texture tiling.
//   include <BOSL2/rounding.scad>
//   
//   xprofile = smooth_path([[0,0,0], [25,0,0], [49,0,-10], [51,0,10], [75,0,0], [100,0,0]],
//                   relsize=1, method="corners", splinesteps=4);
//   yprofile = smooth_path([[0,0,0], [0,25,0], [0,49,-10], [0,51,10], [0,75,0], [0,100,0]],
//                   relsize=1, method="corners", splinesteps=4);
//   polystack = [
//       for(xp=xprofile) [
//           for(yp=yprofile) [xp.x, yp.y, xp.z+yp.z]
//       ]
//   ];
//   vnf_vertex_array(polystack, texture="checkers", tex_depth=2, tex_reps=[8,8]);
//   color("red") {
//       for(p=xprofile) translate(p-[0,4,0]) sphere(1.5);
//       for(p=yprofile) translate(p-[4,0,0]) sphere(1.5);
//   }
// Example(3D,Med,NoAxes,VPD=300,VPT=[48,48,0]): By passing the spline curves into {{resample_path()}}, we can get a uniform distribution of the x and y profile points, as shown by the red dots, which results in a uniform texture tiling. 
//   include <BOSL2/rounding.scad>
//   
//   xprof = smooth_path([[0,0,0], [25,0,0], [49,0,-10], [51,0,10], [75,0,0], [100,0,0]],
//                   relsize=1, method="corners", splinesteps=4);
//   yprof = smooth_path([[0,0,0], [0,25,0], [0,49,-10], [0,51,10], [0,75,0], [0,100,0]],
//                   relsize=1, method="corners", splinesteps=4);
//   xprofile = resample_path(xprof, len(xprof), closed=false);
//   yprofile = resample_path(yprof, len(yprof), closed=false);
//   polystack = [
//       for(xp=xprofile) [
//           for(yp=yprofile) [xp.x, yp.y, xp.z+yp.z]
//       ]
//   ];
//   vnf_vertex_array(polystack, texture="checkers", tex_depth=2, tex_reps=[8,8]);
//   color("red") {
//       for(p=xprofile) translate(p-[0,4,0]) sphere(1.5);
//       for(p=yprofile) translate(p-[4,0,0]) sphere(1.5);
//   }


module vnf_vertex_array(
    points,
    caps, cap1, cap2,
    col_wrap=false,
    row_wrap=false,
    reverse=false,
    style="default",
    triangulate = false,
    texture, tex_reps, tex_size, tex_samples, tex_inset=false, tex_rot=0, 
    tex_depth=1, tex_extra, tex_skip, sidecaps,sidecap1,sidecap2, tex_scaling="default",
    convexity=2, cp="centroid", anchor="origin", spin=0, orient=UP, atype="hull") 
{
    vnf = vnf_vertex_array(points=points, caps=caps, cap1=cap1, cap2=cap2,
                           col_wrap=col_wrap, row_wrap=row_wrap, reverse=reverse, style=style,triangulate=triangulate, tex_scaling=tex_scaling, 
                           texture=texture, tex_reps=tex_reps, tex_size=tex_size, tex_samples=tex_samples, tex_inset=tex_inset, tex_rot=tex_rot, 
                           tex_depth=tex_depth, tex_extra=tex_extra, tex_skip=tex_skip, sidecaps=sidecaps,sidecap1=sidecap1,sidecap2=sidecap2
      );
    vnf_polyhedron(vnf, convexity=convexity, cp=cp, anchor=anchor, spin=spin, orient=orient, atype=atype) children();
}    


function vnf_vertex_array(
    points,
    caps, cap1, cap2,
    col_wrap=false,
    row_wrap=false,
    reverse=false,
    style="default",
    triangulate = false, return_edges=false, 
    texture, tex_reps, tex_size, tex_samples, tex_inset=false, tex_rot=0, tex_scaling="default",
    tex_depth=1, tex_extra, tex_skip, sidecaps,sidecap1,sidecap2, normals
) =
    assert(in_list(style,["default","alt","quincunx", "convex","concave", "min_edge","min_area","flip1","flip2","quad"]))
    assert(is_matrix(points[0], n=3),"\nPoint array has the wrong shape or points are not 3d.")
    assert(is_consistent(points), "\nNon-rectangular or invalid point array.")
    assert(is_bool(triangulate))
    is_def(texture) ?
          _textured_point_array(points=points, texture=texture, tex_reps=tex_reps, tex_size=tex_size,
                               tex_inset=tex_inset, tex_samples=tex_samples, tex_rot=tex_rot, tex_scaling=tex_scaling, return_edges=return_edges, 
                               col_wrap=col_wrap, row_wrap=row_wrap, tex_depth=tex_depth, caps=caps, cap1=cap1, cap2=cap2, reverse=reverse,
                               style=style, tex_extra=tex_extra, tex_skip=tex_skip, sidecaps=sidecaps, sidecap1=sidecap1, sidecap2=sidecap2,normals=normals,triangulate=triangulate)
  :
    assert(!(any([caps,cap1,cap2]) && !col_wrap), "\ncol_wrap must be true if caps are requested (without texture).")
    assert(!(any([caps,cap1,cap2]) && row_wrap), "\nCannot combine caps with row_wrap (without texture).")
    let(
        pts = flatten(points),
        pcnt = len(pts),
        rows = len(points),
        cols = len(points[0])
    )
    rows<=1 || cols<=1 ? EMPTY_VNF :
    let(
        cap1 = first_defined([cap1,caps,false]),
        cap2 = first_defined([cap2,caps,false]),
        colcnt = cols - (col_wrap?0:1),
        rowcnt = rows - (row_wrap?0:1),
        verts = [
            each pts,
            if (style=="quincunx")
                for (r = [0:1:rowcnt-1], c = [0:1:colcnt-1])
                   let(
                       i1 = ((r+0)%rows)*cols + ((c+0)%cols),
                       i2 = ((r+1)%rows)*cols + ((c+0)%cols),
                       i3 = ((r+1)%rows)*cols + ((c+1)%cols),
                       i4 = ((r+0)%rows)*cols + ((c+1)%cols)
                   )
                   mean([pts[i1], pts[i2], pts[i3], pts[i4]])
        ],
        allfaces = [
            if (cap1) count(cols,reverse=!reverse),
            if (cap2) count(cols,(rows-1)*cols, reverse=reverse),
            for (r = [0:1:rowcnt-1], c=[0:1:colcnt-1])
               each
               let(
                   i1 = ((r+0)%rows)*cols + ((c+0)%cols),
                   i2 = ((r+1)%rows)*cols + ((c+0)%cols),
                   i3 = ((r+1)%rows)*cols + ((c+1)%cols),
                   i4 = ((r+0)%rows)*cols + ((c+1)%cols),
                   faces =
                        style=="quincunx"?
                          let(i5 = pcnt + r*colcnt + c)
                          [[i1,i5,i2],[i2,i5,i3],[i3,i5,i4],[i4,i5,i1]]
                      : style=="min_area"?
                          let(
                               area42 = norm(cross(pts[i2]-pts[i1], pts[i4]-pts[i1]))+norm(cross(pts[i4]-pts[i3], pts[i2]-pts[i3])),
                               area13 = norm(cross(pts[i1]-pts[i4], pts[i3]-pts[i4]))+norm(cross(pts[i3]-pts[i2], pts[i1]-pts[i2])),
                               minarea_edge = area42 < area13 + EPSILON
                                 ? [[i1,i4,i2],[i2,i4,i3]]
                                 : [[i1,i3,i2],[i1,i4,i3]]
                          )
                          minarea_edge
                      : style=="min_edge"?
                          let(
                               d42=norm(pts[i4]-pts[i2]),
                               d13=norm(pts[i1]-pts[i3]),
                               shortedge = d42<d13+EPSILON
                                 ? [[i1,i4,i2],[i2,i4,i3]]
                                 : [[i1,i3,i2],[i1,i4,i3]]
                          )
                          shortedge
                      : style=="convex"?
                          let(   // Find normal for 3 of the points.  Is the other point above or below?
                              n = (reverse?-1:1)*cross(pts[i2]-pts[i1],pts[i3]-pts[i1]),
                              convexfaces = n==0
                                ? [[i1,i4,i3]]
                                : n*pts[i4] > n*pts[i1]
                                    ? [[i1,i4,i2],[i2,i4,i3]]
                                    : [[i1,i3,i2],[i1,i4,i3]]
                          )
                          convexfaces
                      : style=="concave"?
                          let(   // Find normal for 3 of the points.  Is the other point above or below?
                              n = (reverse?-1:1)*cross(pts[i2]-pts[i1],pts[i3]-pts[i1]),
                              concavefaces = n==0
                                ? [[i1,i4,i3]]
                                : n*pts[i4] <= n*pts[i1]
                                    ? [[i1,i4,i2],[i2,i4,i3]]
                                    : [[i1,i3,i2],[i1,i4,i3]]
                          )
                          concavefaces
                      : style=="quad" ? [[i1,i2,i3,i4]]
                      : style=="alt" || (style=="flip1" && ((r+c)%2==0)) || (style=="flip2" && ((r+c)%2==1)) || (style=="random" && rands(0,1,1)[0]<.5)?
                          [[i1,i4,i2],[i2,i4,i3]]
                      : [[i1,i3,i2],[i1,i4,i3]],
                   // remove degenerate faces
                   culled_faces= [for(face=faces)
                       if (norm(cross(verts[face[1]]-verts[face[0]],
                                      verts[face[2]]-verts[face[0]]))>EPSILON)
                           face
                   ],
                   rfaces = reverse? [for (face=culled_faces) reverse(face)] : culled_faces
               )
               rfaces,
        ],
        vnf = [verts, allfaces],
        tvnf = triangulate? vnf_triangulate(vnf) : vnf
    )
    !return_edges ? tvnf
                  : [tvnf, [
                              if (!col_wrap) deduplicate(column(points,0)) else [],
                              if (!col_wrap) deduplicate(column(points, len(points[0])-1)) else [],
                              if (!cap1 && !row_wrap) deduplicate(points[0]) else [],
                              if (!cap2 && !row_wrap) deduplicate(last(points)) else []
                           ]
                    ];

// Function&Module: vnf_tri_array()
// Synopsis: Returns a VNF from an array of points. The array need not be rectangular.
// SynTags: VNF
// Topics: VNF Generators, Lists
// See Also: vnf_vertex_array(), vnf_join(), vnf_from_polygons(), vnf_merge_points()
// Usage:
//   vnf = vnf_tri_array(points, [caps=], [cap1=], [cap2=], [reverse=], [col_wrap=], [row_wrap=], [limit_bunching=])
//   vnf_tri_array(points, [caps=], [cap1=], [cap2=], [reverse=], [col_wrap=], [row_wrap=], [limit_bunching=],...) [ATTACHMENTS];
// Description:
//   Produces a VNF from an array of points where each row length can differ from the adjacent rows by
//   any amount. This enables the construction of triangular or even irregular VNF patches. The
//   resulting VNF can be wrapped along the rows by setting `row_wrap` to true, and wrapped along
//   columns by setting `col_wrap` to true. It is possible to do both at once.
//   If `row_wrap` is false or not provided, end caps can be generated across the top and/or bottom rows.
//   .
//   The algorithm starts with the first point on each row and recursively walks around finding the
//   minimum-length edge to make each new triangle face. This may result in several triangles being
//   connected to one vertex. When triangulating two rows that happen to be equal length, the result is
//   equivalent to {{vnf_vertex_array()}} using the "min_edge" style. If you already have a rectangular
//   vertex list (equal length rows), you should use `vnf_vertex_array()` if you need a different
//   triangulation style.
//   .
//   Because the algorithm seeks the minimum-length new edge to generate triangles between two
//   unequal-lengthy rows of vertices, there are cases where this can causing bunching of several
//   triangles sharing a single vertex, if several successive points of one row are closest to a single
//   point on the other row. Example 6 demonstrates this. If the two rows are equal in length, this
//   doesn't happen. The `limit_bunching` parameter, by default, limits the number of *additional*
//   triangles that would normally be generated to the difference between the row lengths. Example 6
//   demonstrates the effect of disabling this limit.
//   .
//   If you need to merge two VNF arrays that share edges using `vnf_join()` you can remove the
//   duplicated vertices using `vnf_merge_points()`.
// Arguments:
//   points = List of point lists for each row.
//   ---
//   caps = If true, add endcap faces to the first **and** last rows.
//   cap1 = If true, add an endcap face to the first row.
//   cap2 = If true, add an endcap face to the last row.
//   col_wrap = If true, add faces to connect the last column to the first.
//   row_wrap = If true, add faces to connect the last row to the first.
//   reverse = If true, reverse all face normals.
//   limit_buncthing = If true, when triangulating between two rows of unequal length, then limit the number of additional triangles that would normally share a vertex. Ignored when the two row lengths are equal. If false, a vertex can be shared by unlimited triangles. Default: true
//   convexity = (module) Max number of times a line could intersect a wall of the shape.
//   cp = (module) Centerpoint for determining intersection anchors or centering the shape.  Determines the base of the anchor vector.  Can be "centroid", "mean", "box" or a 3D point.  Default: "centroid"
//   anchor = (module) Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `"origin"`
//   spin = (module) Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = (module) Vector to rotate top toward, after spin. See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   atype = (module) Select "hull" or "intersect" anchor type.  Default: "hull"
// Anchor Types:
//   "hull" = Anchors to the virtual convex hull of the shape.
//   "intersect" = Anchors to the surface of the shape.
// Named Anchors:
//   "origin" = Anchor at the origin, oriented UP.
// Example(3D,NoAxes): Each row has one more point than the preceeding one.
//   pts = [for(y=[1:1:10]) [for(x=[0:y-1]) [x,y,y]]];
//   vnf = vnf_tri_array(pts);
//   vnf_wireframe(vnf,width=0.1);
//   color("red")move_copies(flatten(pts)) sphere(r=.15,$fn=9);
// Example(3D,NoAxes): Each row has two more points than the preceeding one.
//   pts = [for(y=[0:2:10]) [for(x=[-y/2:y/2]) [x,y,y]]];
//   vnf = vnf_tri_array(pts);
//   vnf_wireframe(vnf,width=0.1);
//   color("red")move_copies(flatten(pts)) sphere(r=.15,$fn=9);
// Example(3D): Merging two VNFs to construct a cone with one point length change between rows.
//   pts1 = [for(z=[0:10]) path3d(arc(3+z,r=z/2+1, angle=[0,180]),10-z)];
//   pts2 = [for(z=[0:10]) path3d(arc(3+z,r=z/2+1, angle=[180,360]),10-z)];
//   vnf = vnf_join([vnf_tri_array(pts1),
//                     vnf_tri_array(pts2)]);
//   color("green")vnf_wireframe(vnf,width=0.1);
//   vnf_polyhedron(vnf);
// Example(3D): Cone with length change two between rows
//   pts1 = [for(z=[0:1:10]) path3d(arc(3+2*z,r=z/2+1, angle=[0,180]),10-z)];
//   pts2 = [for(z=[0:1:10]) path3d(arc(3+2*z,r=z/2+1, angle=[180,360]),10-z)];
//   vnf = vnf_join([vnf_tri_array(pts1),
//                    vnf_tri_array(pts2)]);
//   color("green")vnf_wireframe(vnf,width=0.1);
//   vnf_polyhedron(vnf);
// Example(3D,NoAxes): The number of points per row can change irregularly by any amount.
//   lens = [10,9,8,6,4,8,2,5,3,10,4];
//   pts = [for(y=idx(lens)) lerpn([-lens[y],y,y],[lens[y],y,y],lens[y])];
//   vnf = vnf_tri_array(pts);
//   vnf_wireframe(vnf,width=0.1);
//   color("red")move_copies(flatten(pts)) sphere(r=.15,$fn=9);
// Example(3D,Med,NoAxes,Edges,VPR=[29,0,341],VPD=45,VPT=[11,5,2]): The default parameter `limit_bunching=true` prevents too many triangles from sharing a single vertex in one row, if several points of one row happen to be closest to a single point on another row. In the left figure, `limit_bunching=false`, causing an endpoint on each row to get many triangles from the other row, because the algorithm seeks the shortest triangle leg distance once the first two points of each row are connected. This doesn't happen if both rows are the same length. The figure on the right uses the default `limit_bunching=true`, forcing the triangulation to stop adding too many triangles to the same vertex.
//   pts = [
//       [[5,0,0], [4,0,1.4], [3,0,2], [2,0,1.4], [1,0,0]],
//       [[14,10,0], [12,9,5], [9,8,7], [6,7,7], [3,6,5], [0,5,0]]
//   ];
//   vnf_tri_array(pts, limit_bunching=false);
//   right(10) vnf_tri_array(pts);
// Example(3D,NoAxes,Edges,VPR=[65,0,25],VPD=380,Med): Model of a cymbal with roughly same-size facets, using a different number of points for each concentric ring of vertices.
//   bez = [
//       [[0,26], [35,26], [29,0], [80,16], [102,0]], //top
//       [[99,-1], [79,15], [28,-1], [34,25], [-1,25]] // bottom
//   ];
//   points = [
//       for(b=bez)
//           for(u=[0.01:0.04:1]) let(
//               bzp = bezier_points(b,u),
//               r = bzp[0],
//               n = max(3, round(360 / (6/r * 180/PI)))
//           ) path3d(regular_ngon(n, r=r), bzp[1])
//   ];
//   vnf = vnf_tri_array(points, reverse=true, col_wrap=true, caps=true);
//   color("brown") difference() {
//       vnf_polyhedron(vnf);
//       cylinder(30, d=8);
//   }

module vnf_tri_array(
    points,
    caps, cap1, cap2,
    col_wrap=false,
    row_wrap=false,
    reverse=false,
    limit_bunching=true,
    convexity=2, cp="centroid", anchor="origin", spin=0, orient=UP, atype="hull") 
{
    vnf = vnf_tri_array(points=points, caps=caps, cap1=cap1, cap2=cap2,
        col_wrap=col_wrap, row_wrap=row_wrap, reverse=reverse,
        limit_bunching = limit_bunching);
    vnf_polyhedron(vnf, convexity=convexity, cp=cp, anchor=anchor, spin=spin, orient=orient, atype=atype) children();
}    

function vnf_tri_array(
    points,
    caps, cap1, cap2,
    col_wrap=false,
    row_wrap=false,
    reverse=false,
    limit_bunching=true
) =
    assert(!(any([caps,cap1,cap2]) && row_wrap), "\nCannot combine caps with row_wrap.")
    let(
        plen = len(points),
        // append first vertex of each polygon to its end if wrapping columns
        st = col_wrap ? [
            for(i=[0:plen-1])
            points[i][0] != points[i][len(points[i])-1]
                ? concat(points[i], [points[i][0]])
                : points[i]
        ] : points,
        addcol = col_wrap ? len(st[0])-len(points[0]) : 0,
        rowstarts = [ for(i=[0:plen-1]) len(st[i]) ],
        capfirst = first_defined([cap1,caps,false]),
        caplast = first_defined([cap2,caps,false]),
        pcumlen = [0, each cumsum(rowstarts)],
        faces = flatten([
            // close first end
            if (capfirst)
                if (reverse) [[ for(i=[0:rowstarts[0]-1-addcol]) i ]]
                else [[ for(i=[rowstarts[0]-1-addcol:-1:0]) i ]],
            // triangulate between the two polygons
            for(i = [0:plen-2+(row_wrap?1:0)])
                let(
                    j = (i+1)%plen,
                    max_extra_edges = limit_bunching ? max(1, abs(len(st[i])-len(st[j]))) : INF
                ) _lofttri(st[i], st[j], pcumlen[i], pcumlen[j], rowstarts[i], rowstarts[j], reverse, trimax=max_extra_edges),
            // close up the last end
            if (caplast)
                if (reverse) [[ for(i=[pcumlen[plen]-1-addcol:-1:pcumlen[plen-1]]) i ]]
                else [[ for(i=[pcumlen[plen-1]:pcumlen[plen]-1-addcol]) i ]]
        ]),
        vnf = [flatten(st), faces]
    ) col_wrap ? vnf_merge_points(vnf) : vnf;

/*
Recursively triangulate between two 3D paths (which can be different
in length by any amount), starting at index 0 and generate a list of
triangles with minimum new-side length.
The first side of the first triangle always connects the two first
vertices of each path.
To triangulate between two closed paths, the first and last vertices
must be the same.
Parameters:
    p1 = first path, an array of [x,y,z] vertices
    p2 = second path, an array of [x,y,z] vertices
    i1offset = index offset of first vertex in the first path
        (sum of any prior path lengths)
    i2offset = index offset of first vertex in the second path
        (sum of any prior path lengths)
    n1 = number of vertices in first path
    n2 = number of vertices in second path
    reverse = if true, assume a polygon path goes around
        counterclockwise with respect to the direction from
        p1 to p2 (right hand rule), clockwise if false
Other parameters are for internal use:
    trilist[] = array of triangles to return
    i1 = vertex index on p1 of the next triangle
    i2 = vertex index on p2 of the next triangle
    tricount1 = number extra triangles generated on vertex i2 to row p1
    tricount2 = number extra triangles generated on vertex i1 to row p2
    trimax = max number of extra triangles that can be created on any point in a row
(next triangle vertex found can be on either p1 or p2, depending
on which triangle is smaller.)

Returns an array of triangles using vertex indices offset by
i1offset and i2offset
*/
function _lofttri(p1, p2, i1offset, i2offset, n1, n2, reverse=false, trilist=[], i1=0, i2=0, tricount1=0, tricount2=0, trimax=INF) = n1!=n2 ?
    // unequal row lengths
    let(
    t1 = i1 < n1 ? i1+1 : n1,   // test point 1
    t2 = i2 < n2 ? i2+1 : n2,   // test point 2
//dum=echo(str("i1=",i1,"  i2=",i2,"  t1=",t1,"  t2=",t2,"  n1=",n1,"  n2=",n2, "  p1[t1]=",p1[t1],"  p2[i2]=",p2[i2])),
    d12 = t2>=n2 ? 9e+9 : norm(p2[t2]-p1[i1]), // distance from i1 to t2
    d21 = t1>=n1 ? 9e+9 : norm(p1[t1]-p2[i2]), // distance from i2 to t1
//dum2=echo(str("  d12=",d12,"  d21=",d21,"  tricounts=",tricount1,",",tricount2)),
    userow = d12<d21 ? (tricount1<trimax ? 2 : 1) : (tricount2<trimax ? 1 : 2),
    newt = userow==1 ? (t1<n1?t1:i1) : (t2<n2?t2:i2),
    newofft = userow==2 ? i2offset+newt : i1offset+newt,
    tc1 = d12<d21 && tricount1<trimax ? tricount1+1 : 0,
    tc2 = d21<d12 && tricount2<trimax ? tricount2+1 : 0,
    triangle = reverse ?
        [i1offset+i1, i2offset+i2, newofft] :
        [i2offset+i2, i1offset+i1, newofft]
) t1>=n1 && t2>=n2 ? trilist :
    _lofttri(p1, p2, i1offset, i2offset, n1, n2, reverse, concat(trilist, [triangle]),
        userow==1 ? (t1>=n1?i1:t1) : i1, userow==2 ? (t2>=n2?i2:t2) : i2, tc1, tc2, trimax)

    : // equal row lengths
    let(n=n1, i=i1,
    t = i < n ? i+1 : n,   // test point
    d12 = t>=n ? 9e+9 : norm(p2[t]-p1[i]), // distance from p1 to new p2
    d21 = t>=n ? 9e+9 : norm(p1[t]-p2[i]), // distance from p2 to new p1
    triangle1 = reverse ?
        [i1offset+i, i2offset+i, d12<d21 ? i2offset+t : i1offset+t] :
        [i2offset+i, i1offset+i, d12<d21 ? i2offset+t : i1offset+t],
    triangle2 = reverse ?
        [i2offset+t, i1offset+t, d12<d21 ? i1offset+i : i2offset+i] :
        [i1offset+t, i2offset+t, d12<d21 ? i1offset+i : i2offset+i]
) t>=n ? trilist :
    _lofttri(p1, p2, i1offset, i2offset, n, n, reverse, concat(trilist, [triangle1, triangle2]), t, t, 0,0,trimax);



// Function: vnf_join()
// Synopsis: Returns a single VNF structure from a list of VNF structures.
// SynTags: VNF
// Topics: VNF Generators, Lists
// See Also: vnf_tri_array(), vnf_vertex_array(), vnf_from_polygons(), vnf_from_region()
// Usage:
//   vnf = vnf_join([VNF, VNF, VNF, ...]);
// Description:
//   Given a list of VNF structures, merges them all into a single VNF structure.
//   Combines all the points of the input VNFs and labels the faces appropriately.
//   All the points in the input VNFs appear in the output, even if they are
//   duplicated. It is valid to repeat points in a VNF, but if you
//   with to remove the duplicates that occur along joined edges, use {{vnf_merge_points()}}.
//   .
//   This is a tool for manipulating polyhedron data. It is for
//   building up a full polyhedron from partial polyhedra.
//   It is *not* a union operator for VNFs. The VNFs to be joined must not intersect each other,
//   except at edges, otherwise the result is an invalid polyhedron. Also, the
//   result must not have any other illegal polyhedron characteristics, such as creating
//   more than two faces sharing the same edge.
//   If you want a valid result it is your responsibility to ensure that the polyhedron
//   has no holes, no intersecting faces or edges, and obeys all the requirements
//   that CGAL expects.
//   .
//   For example, if you combine two pyramids to try to make an octahedron, the result is
//   invalid because of the two internal faces created by the pyramid bases.  A valid
//   use would be to build a cube missing one face and a pyramid missing its base and
//   then join them into a cube with a point.
// Arguments:
//   vnfs = a list of the VNFs to joint into one VNF.
// Example(3D,VPR=[60,0,26],VPD=55,VPT=[5.6,-5.3,9.8]): Here is a VNF where the top face is missing.  It is not a valid polyhedron like this, but we can use it as a building block to make a polyhedron.
//   bottom = vnf_vertex_array([path3d(rect(8)), path3d(rect(5),4)],col_wrap=true,cap1=true);
//   vnf_polyhedron(bottom);
// Example(3D,VPR=[60,0,26],VPD=55,VPT=[5.6,-5.3,9.8]): Here is a VNF that also has a missing face.
//   triangle = yrot(-90,path3d(regular_ngon(n=3,side=5,anchor=LEFT)));
//   top = up(4,vnf_vertex_array([list_set(right(2.5,triangle),0,[0,0,7]),
//                               right(6,triangle)
//                               ], col_wrap=true, cap2=true));
//   vnf_polyhedron(zrot(90,top));
// Example(3D,VPR=[60,0,26],VPD=55,VPT=[5.6,-5.3,9.8]): Using vnf_join combines the two VNFs into a single VNF.  Note that they share an edge.  But the result still isn't closed, so it is not yet a valid polyhedron.
//   bottom = vnf_vertex_array([path3d(rect(8)), path3d(rect(5),4)],col_wrap=true,cap1=true);
//   triangle = yrot(-90,path3d(regular_ngon(n=3,side=5,anchor=LEFT)));
//   top = up(4,vnf_vertex_array([list_set(right(2.5,triangle),0,[0,0,7]),
//                                right(6,triangle)
//                               ], col_wrap=true, cap2=true));
//   full = vnf_join([bottom,zrot(90,top)]);
//   vnf_polyhedron(full);
// Example(3D,VPR=[60,0,26],VPD=55,VPT=[5.6,-5.3,9.8]): If we add enough pieces, and the pieces are all consistent with each other, then we can arrive at a valid polyhedron like this one.  To be valid you need to meet all the CGAL requirements: every edge has exactly two faces, all faces are in clockwise order, no intersections of edges.
//   bottom = vnf_vertex_array([path3d(rect(8)), path3d(rect(5),4)],col_wrap=true,cap1=true);
//   triangle = yrot(-90,path3d(regular_ngon(n=3,side=5,anchor=LEFT)));
//   top = up(4,vnf_vertex_array([list_set(right(2.5,triangle),0,[0,0,7]),
//                                right(6,triangle)
//                               ], col_wrap=true, cap2=true));
//   full = vnf_join([bottom,
//                     for(theta=[0:90:359]) zrot(theta,top)
//                    ]);
//   vnf_polyhedron(full);
// Example(3D): The vnf_join function is not a union operator for polyhedra.  If any faces intersect, like they do in this example where we combine the faces of two cubes, the result is invalid and results in CGAL errors when you add more objects into the model.
//   cube1 = cube(5);
//   cube2 = move([2,2,2],cube1);
//   badvnf = vnf_join([cube1,cube2]);
//   vnf_polyhedron(badvnf);
//   right(2.5)up(3)color("red")
//         text3d("Invalid",size=1,anchor=CENTER,
//         orient=FRONT,h=.1);
function vnf_join(vnfs) =
    assert(is_vnf_list(vnfs) , "\nInput must be a list of VNFs.")
    len(vnfs)==1 ? vnfs[0]
    :
    let (
        offs  = cumsum([ 0, for (vnf = vnfs) len(vnf[0]) ]),
        verts = [for (vnf=vnfs) each vnf[0]],
        faces =
            [ for (i = idx(vnfs))
                let( faces = vnfs[i][1] )
                for (face = faces)
                    if ( len(face) >= 3 )
                        [ for (j = face)
                            assert( j>=0 && j<len(vnfs[i][0]),
                                    str("\nVNF number ", i, " has a face indexing an nonexistent vertex.") )
                            offs[i] + j ]
            ]
    )
    [verts,faces];



// Function: vnf_from_polygons()
// Synopsis: Returns a VNF from a list of 3D polygons.
// SynTags: VNF
// Topics: VNF Generators, Lists
// See Also: vnf_tri_array(), vnf_join(), vnf_vertex_array(), vnf_from_region()
// Usage:
//   vnf = vnf_from_polygons(polygons, [eps]);
// Description:
//   Given a list of 3D polygons, produces a VNF containing those polygons.
//   It is up to the caller to make sure that the points are in the correct order to make the face
//   normals point outward.  No checking for duplicate vertices is done.  If you want to
//   remove duplicate vertices use {{vnf_merge_points()}}.  Polygons with zero area are discarded from the face list by default.
//   If you give non-coplanar faces an error is displayed.  These checks increase run time by about 2x for triangular polygons, but
//   about 10x for pentagons; the checks can be disabled by setting fast=true.  
// Arguments:
//   polygons = The list of 3D polygons to turn into a VNF
//   fast = Set to true to skip area and coplanarity checks for increased speed.  Default: false
//   eps = Polygons with area smaller than this are discarded.  Default: EPSILON
// Example(3D,VPR=[60,0,40]): Construction of a dodecahedron from pentagon faces.
//   dihedral = 2*atan(PHI);   // dodecahedron face dihedral
//   rpenta = 10;              // pentagon face radius
//   edge = 2*rpenta*sin(36);  // edge length
//   inrad = 0.5*edge * PHI*PHI/sqrt(3-PHI);   // inner radius
//   face3d = path3d(pentagon(rpenta), inrad); // single face
//   facepoints = [
//       face3d,
//       for(a=[36:72:360]) zrot(a, yrot(180-dihedral, face3d)),
//       for(a=[36:72:360]) zrot(a, yrot(360-dihedral, face3d)),
//       yrot(180, face3d)
//   ];
//   vnf = vnf_from_polygons(facepoints, fast=true);
//   vnf_polyhedron(vnf);

function vnf_from_polygons(polygons,fast=false,eps=EPSILON) =
   assert(is_list(polygons) && is_path(polygons[0]),"\nInput should be a list of polygons.")
   let(
       offs = cumsum([0, for(p=polygons) len(p)]),
       faces = [for(i=idx(polygons))
                  let(
                      area=fast ? 1 : polygon_area(polygons[i]),
                      dummy=assert(is_def(area) || is_collinear(polygons[i],eps=eps),str("\nPolygon ", i, " is not coplanar."))
                  )
                  if (is_def(area) && area > eps)
                    [for (j=idx(polygons[i])) offs[i]+j]
               ]
   )
   [flatten(polygons), faces];




function _path_path_closest_vertices(path1,path2) =
    let(
        dists = [for (i=idx(path1)) let(j=closest_point(path1[i],path2)) [j,norm(path2[j]-path1[i])]],
        i1 = min_index(column(dists,1)),
        i2 = dists[i1][0]
    ) [dists[i1][1], i1, i2];


function _join_paths_at_vertices(path1,path2,v1,v2) =
    let(
        repeat_start = !approx(path1[v1],path2[v2]),
        path1 = clockwise_polygon(list_rotate(path1,v1)),
        path2 = ccw_polygon(list_rotate(path2,v2))
    )
    [
        each path1,
        if (repeat_start) path1[0],
        each path2,
        if (repeat_start) path2[0],
    ];


/// Internal Function: _cleave_connected_region(region, eps)
/// Description:
///   Given a region that is connected and has its outer border in region[0],
///   produces a overlapping connected path to join internal holes to
///   the outer border without adding points. Output is a single non-simple polygon.
/// Requirements:
///   It expects that all region paths be simple closed paths, with region[0] CW and
///   the other paths CCW and encircled by region[0]. The input region paths are also
///   supposed to be disjoint except for common vertices and common edges but with
///   no crossings. It may return `undef` if these conditions are not met.
///   This function implements an extension of the algorithm discussed in:
///   https://www.geometrictools.com/Documentation/TriangulationByEarClipping.pdf
function _cleave_connected_region(region, eps=EPSILON) =
    len(region)==1 ? region[0] :
    let(
        outer   = deduplicate(region[0]),             //
        holes   = [for(i=[1:1:len(region)-1])         // deduplication possibly unneeded
                      deduplicate( region[i] ) ],     //
        extridx = [for(li=holes) max_index(column(li,0)) ],
        // the right extreme vertex for each hole sorted by decreasing x values
        extremes = sort( [for(i=idx(holes)) [ i, extridx[i], -holes[i][extridx[i]].x] ], idx=2 )
    )
    _polyHoles(outer, holes, extremes, eps, 0);


// connect the hole paths one at a time to the outer path.
// 'extremes' is the list of the right extreme vertex of each hole sorted by decreasing abscissas
// see: _cleave_connected_region(region, eps)
function _polyHoles(outer, holes, extremes, eps=EPSILON, n=0) =
    let(
        extr = extremes[n],    //
        hole = holes[extr[0]], // hole path to bridge to the outer path
        ipt  = extr[1],        // index of the hole point with maximum abscissa
        brdg = _bridge(hole[ipt], outer, eps)  // the index of a point in outer to bridge hole[ipt] to
    )
    brdg == undef ? undef :
    let(
        l  = len(outer),
        lh = len(hole),
        // the new outer polygon bridging the hole to the old outer
        npoly =
            approx(outer[brdg], hole[ipt], eps)
            ?   [ for(i=[brdg:  1: brdg+l])   outer[i%l] ,
                  for(i=[ipt+1: 1: ipt+lh-1]) hole[i%lh] ]
            :   [ for(i=[brdg:  1: brdg+l])   outer[i%l] ,
                  for(i=[ipt:   1: ipt+lh])   hole[i%lh] ]
    )
    n==len(holes)-1 ?  npoly :
    _polyHoles(npoly, holes, extremes, eps, n+1);

// find a point in outer to be connected to pt in the interior of outer
// by a segment that not cross or touch any non adjacente edge of outer.
// return the index of a vertex in the outer path where the bridge should end
// see _polyHoles(outer, holes, extremes, eps)
function _bridge(pt, outer,eps) =
    // find the intersection of a ray from pt to the right
    // with the boundary of the outer cycle
    let(
        l    = len(outer),
        crxs =
            let( edges = pair(outer,wrap=true) )
            [for( i = idx(edges) )
                let( edge = edges[i] )
                // consider just descending outer edges at right of pt crossing ordinate pt.y
                if(    (edge[0].y >  pt.y) //+eps)
                    && (edge[1].y <= pt.y)
                    && _is_at_left(pt, [edge[1], edge[0]], eps) )
                    [ i,
                      // the point of edge with ordinate pt.y
                      abs(pt.y-edge[1].y)<eps ? edge[1] :
                      let( u = (pt-edge[1]).y / (edge[0]-edge[1]).y )
                      (1-u)*edge[1] + u*edge[0]
                    ]
             ]
    )
    crxs == [] ? undef :
    let(
        // the intersection point of the nearest edge to pt with minimum slope
        minX    = min([for(p=crxs) p[1].x]),
        crxcand = [for(crx=crxs) if(crx[1].x < minX+eps) crx ], // nearest edges
        nearest = min_index([for(crx=crxcand)
                                (outer[crx[0]].x - pt.x) / (outer[crx[0]].y - pt.y) ]), // minimum slope
        proj    = crxcand[nearest],
        vert0   = outer[proj[0]],    // the two vertices of the nearest crossing edge
        vert1   = outer[(proj[0]+1)%l],
        isect   = proj[1]            // the intersection point
    )
    norm(pt-vert1) < eps ? (proj[0]+1)%l : // if pt touches an outer vertex, return its index
    // as vert0.y > pt.y then pt!=vert0
    norm(pt-isect) < eps ? undef :         // if pt touches the middle of an outer edge -> error
    let(
        // the edge [vert0, vert1] necessarily satisfies vert0.y > vert1.y
        // indices of candidates to an outer bridge point
        cand  =
            (vert0.x > pt.x)
            ?   [ proj[0],
                  // select reflex vertices inside of the triangle [pt, vert0, isect]
                  for(i=idx(outer))
                      if( _tri_class(select(outer,i-1,i+1),eps) <= 0
                          && _pt_in_tri(outer[i], [pt, vert0, isect], eps)>=0 )
                        i
                ]
            :   [ (proj[0]+1)%l,
                  // select reflex vertices inside of the triangle [pt, isect, vert1]
                  for(i=idx(outer))
                      if( _tri_class(select(outer,i-1,i+1),eps) <= 0
                          &&  _pt_in_tri(outer[i], [pt, isect, vert1], eps)>=0 )
                        i
                ],
        // choose the candidate outer[i] such that the line [pt, outer[i]] has minimum slope
        // among those with minimum slope choose the nearest to pt
        slopes  = [for(i=cand) 1-abs(outer[i].x-pt.x)/norm(outer[i]-pt) ],
        min_slp = min(slopes),
        cand2   = [for(i=idx(cand)) if(slopes[i]<=min_slp+eps) cand[i] ],
        nearest = min_index([for(i=cand2) norm(pt-outer[i]) ])
    )
    cand2[nearest];


// Function: vnf_from_region()
// Synopsis: Returns a 3D VNF given a 2D region.
// SynTags: VNF
// Topics: VNF Generators, Lists
// See Also: vnf_vertex_array(), vnf_tri_array(), vnf_join(), vnf_from_polygons()
// Usage:
//   vnf = vnf_from_region(region, [transform], [reverse]);
// Description:
//   Given a (two-dimensional) region, applies the given transformation matrix to it and makes a (three-dimensional) triangulated VNF of
//   faces for that region, reversed if desired.
// Arguments:
//   region = The region to convert to a VNF.
//   transform = If given, a transformation matrix to apply to the faces generated from the region. Default: No transformation applied.
//   reverse = If true, reverse the normals of the faces generated from the region. An untransformed region has face normals pointing `UP`. Default: false
// Example(3D):
//   region = [square([20,10],center=true),
//             right(5,square(4,center=true)),
//             left(5,square(6,center=true))];
//   vnf = vnf_from_region(region);
//   color("gray")down(.125)
//        linear_extrude(height=.125)region(region);
//   vnf_wireframe(vnf,width=.25);
function vnf_from_region(region, transform, reverse=false, triangulate=true) =
    let (
        region = [for (path = region) deduplicate(path, closed=true)],
        regions = region_parts(force_region(region)),
        vnfs =
            [
                for (rgn = regions)
                let(
                    cleaved = path3d(_cleave_connected_region(rgn))
                )
                assert( cleaved, "\nThe region is invalid.")
                let(
                    face = is_undef(transform)? cleaved : apply(transform,cleaved),
                    faceidxs = reverse? [for (i=[len(face)-1:-1:0]) i] : [for (i=[0:1:len(face)-1]) i]
                ) [face, [faceidxs]]
            ],
        outvnf = vnf_join(vnfs)
    )
    triangulate ? vnf_triangulate(outvnf) : outvnf;



// Section: VNF Testing and Access


// Function: is_vnf()
// Synopsis: Returns true given a VNF-like structure.
// Topics: VNF Manipulation
// See Also: is_vnf_list(), vnf_vertices(), vnf_faces()
// Usage:
//   bool = is_vnf(x);
// Description:
//   Returns true if the given value looks like a VNF structure.
function is_vnf(x) =
    is_list(x) &&
    len(x)==2 &&
    is_list(x[0]) &&
    is_list(x[1]) &&
    (x[0]==[] || (len(x[0])>=3 && is_vector(x[0][0],3))) &&
    (x[1]==[] || is_vector(x[1][0]));


// Function: is_vnf_list()
// Synopsis: Returns true given a list of VNF-like structures.
// Topics: VNF Manipulation
// See Also: is_vnf(), vnf_vertices(), vnf_faces()
//
// Description: Returns true if the given value looks passingly like a list of VNF structures.
function is_vnf_list(x) = is_list(x) && all([for (v=x) is_vnf(v)]);


// Function: vnf_vertices()
// Synopsis: Returns the list of vertex points from a VNF.
// Topics: VNF Manipulation
// See Also: is_vnf(), is_vnf_list(), vnf_faces()
// Description: Given a VNF structure, returns the list of vertex points.
function vnf_vertices(vnf) = vnf[0];


// Function: vnf_faces()
// Synopsis: Returns the list of faces from a VNF.
// Topics: VNF Manipulation
// See Also: is_vnf(), is_vnf_list(), vnf_vertices()
// Description: Given a VNF structure, returns the list of faces, where each face is a list of indices into the VNF vertex list.
function vnf_faces(vnf) = vnf[1];



// Section: Altering the VNF Internals


// Function: vnf_reverse_faces()
// Synopsis: Reverses the faces of a VNF.
// SynTags: VNF
// Topics: VNF Manipulation
// See Also: vnf_quantize(), vnf_merge_points(), vnf_drop_unused_points(), vnf_triangulate(), vnf_slice(), vnf_unify_faces() 
// Usage:
//   rvnf = vnf_reverse_faces(vnf);
// Description:
//   Reverses the orientation of all the faces in the given VNF.
function vnf_reverse_faces(vnf) =
    [vnf[0], [for (face=vnf[1]) reverse(face)]];


// Function: vnf_quantize()
// Synopsis: Quantizes the vertex coordinates of a VNF.
// SynTags: VNF
// Topics: VNF Manipulation
// See Also: vnf_reverse_faces(), vnf_merge_points(), vnf_drop_unused_points(), vnf_triangulate(), vnf_slice() 
// Usage:
//   vnf2 = vnf_quantize(vnf,[q]);
// Description:
//   Quantizes the vertex coordinates of the VNF to the given quanta `q`.
// Arguments:
//   vnf = The VNF to quantize.
//   q = The quanta to quantize the VNF coordinates to.
function vnf_quantize(vnf,q=pow(2,-12)) =
    [[for (pt = vnf[0]) quant(pt,q)], vnf[1]];



// Function: vnf_merge_points()
// Synopsis: Consolidates duplicate vertices of a VNF.
// SynTags: VNF
// Topics: VNF Manipulation
// See Also: vnf_reverse_faces(), vnf_quantize(), vnf_drop_unused_points(), vnf_triangulate(), vnf_slice(), vnf_unify_faces() 
// Usage:
//   new_vnf = vnf_merge_points(vnf, [eps]);
// Description:
//   Given a VNF, consolidates all duplicate vertices with a tolerance `eps`, relabeling the faces as necessary,
//   and eliminating any face with fewer than 3 vertices.  Unreferenced vertices of the input VNF are not dropped.
//   To remove such vertices uses {{vnf_drop_unused_points()}}.
// Arguments:
//   vnf = a VNF to consolidate
//   eps = the tolerance in finding duplicates. Default: EPSILON
function vnf_merge_points(vnf,eps=EPSILON) =
    let(
        verts = vnf[0],
        dedup  = vector_search(verts,eps,verts),                 // collect vertex duplicates
        map    = [for(i=idx(verts)) min(dedup[i]) ],             // remap duplic vertices
        offset = cumsum([for(i=idx(verts)) map[i]==i ? 0 : 1 ]), // remaping face vertex offsets
        map2   = list(idx(verts))-offset,                        // map old vertex indices to new indices
        nverts = [for(i=idx(verts)) if(map[i]==i) verts[i] ],    // this doesn't eliminate unreferenced vertices
        nfaces =
            [ for(face=vnf[1])
                let(
                    nface = [ for(vi=face) map2[map[vi]] ],
                    dface = [for (i=idx(nface))
                                if( nface[i]!=nface[(i+1)%len(nface)])
                                    nface[i] ]
                )
                if(len(dface) >= 3) dface
            ]
    )
    [nverts, nfaces];


// Function: vnf_drop_unused_points()
// Synopsis: Removes unreferenced vertices from a VNF.
// SynTags: VNF
// Topics: VNF Manipulation
// See Also: vnf_reverse_faces(), vnf_quantize(), vnf_merge_points(), vnf_triangulate(), vnf_slice(), vnf_unify_faces() 
// Usage:
//   clean_vnf = vnf_drop_unused_points(vnf);
// Description:
//   Remove all unreferenced vertices from a VNF.  In most cases, unreferenced vertices cause no harm,
//   and this function may be slow on large VNFs.
function vnf_drop_unused_points(vnf) =
    let(
        flat = flatten(vnf[1]),
        ind  = _link_indicator(flat,0,len(vnf[0])-1),
        verts = [for(i=idx(vnf[0])) if(ind[i]==1) vnf[0][i] ],
        map   = cumsum(ind)
    )
    [ verts, [for(face=vnf[1]) [for(v=face) map[v]-1 ] ] ];

function _link_indicator(l,imin,imax) =
    len(l) == 0  ? repeat(imax-imin+1,0) :
    imax-imin<100 || len(l)<400 ? [for(si=search(list([imin:1:imax]),l,1)) si!=[] ? 1: 0 ] :
    let(
        pivot   = floor((imax+imin)/2),
        lesser  = [ for(li=l) if( li< pivot) li ],
        greater = [ for(li=l) if( li> pivot) li ]
    )
    concat( _link_indicator(lesser ,imin,pivot-1),
            search(pivot,l,1) ? 1 : 0 ,
            _link_indicator(greater,pivot+1,imax) ) ;

// Function: vnf_triangulate()
// Synopsis: Triangulates the faces of a VNF.
// SynTags: VNF
// Topics: VNF Manipulation
// See Also: vnf_reverse_faces(), vnf_quantize(), vnf_merge_points(), vnf_drop_unused_points(), vnf_slice(), vnf_unify_faces() 
// Usage:
//   vnf2 = vnf_triangulate(vnf);
// Description:
//   Triangulates faces in the VNF that have more than 3 vertices.
// Arguments:
//   vnf = VNF to triangulate
// Example(3D):
//   include <BOSL2/polyhedra.scad>
//   vnf = zrot(33,regular_polyhedron_info("vnf", "dodecahedron", side=12));
//   vnf_polyhedron(vnf);
//   triangulated = vnf_triangulate(vnf);
//   color("red")vnf_wireframe(triangulated,width=.3);
function vnf_triangulate(vnf) =
    let(
        verts = vnf[0],
        faces = [for (face=vnf[1])
                    each (len(face)==3 ? [face] :
                    let( tris = polygon_triangulate(verts, face) )
                    assert( tris!=undef, "\nSome VNF face cannot be triangulated.")
                    tris ) ]
    )
    [verts, faces];



// Function: vnf_unify_faces()
// Synopsis: Remove triangulation from VNF, returning a copy with full faces
// SynTags: VNF
// Topics: VNF Manipulation
// See Also: vnf_reverse_faces(), vnf_quantize(), vnf_merge_points(), vnf_triangulate(), vnf_slice() 
// Usage:
//   newvnf = vnf_unify_faces(vnf);
// Description:
//   When a VNF has been triangulated, the polygons that form the true faces have been chopped up into
//   triangles.  This can create problems for algorithms that operate on the VNF itself, where you might
//   want to be able to identify the true faces.  This function merges together the triangles that
//   form those true faces, turning a VNF where each true face is represented by a single entry
//   in the faces list of the VNF.  This function requires that the true faces have no internal vertices.
//   This is always true for a triangulated VNF, but might fail for a VNF with some other
//   face partition. If internal vertices are present, the output includes backtracking paths from
//   the boundary to all of those vertices.
// Arguments:
//   vnf = vnf whose faces you want to unify
// Example(3D,Med,NoAxes): Original prism on the left is triangulated.  On the right, the result of unifying the faces.
//   $fn=16;
//   poly = linear_sweep(hexagon(side=10),h=35);
//   vnf = vnf_unify_faces(poly);
//   vnf_wireframe(poly);
//   color([0,1,1,.70])vnf_polyhedron(poly);
//   right(25){
//     vnf_wireframe(vnf);
//     color([0,1,1,.70])vnf_polyhedron(vnf);
//   }

function vnf_unify_faces(vnf) =
   let(
       faces = vnf[1],
       edges =  [for(i=idx(faces), edge=pair(faces[i],wrap=true))
                   [[min(edge),max(edge)],i]],
       normals = [for(face=faces) polygon_normal(select(vnf[0],face))],
       facelist = count(faces), //[for(i=[1:1:len(faces)-1]) i],
       newfaces = _detri_combine_faces(edges,faces,normals,facelist,0)
   )
   [vnf[0],newfaces];


function _detri_combine_faces(edgelist,faces,normals,facelist,curface) =
    curface==len(faces)? select(faces,facelist)
  : !in_list(curface,facelist) ? _detri_combine_faces(edgelist,faces,normals,facelist,curface+1)
  :
    let(
        thisface=faces[curface],
        neighbors = [for(i=idx(thisface))
                       let(
                           edgepair = search([sort(select(thisface,i,i+1))],edgelist,0)[0],
                           choices = select(edgelist,edgepair),
                           good_choice=[for(choice=choices)
                              if (choice[1]!=curface && in_list(choice[1],facelist) && normals[choice[1]]*normals[curface]>1-EPSILON)
                                choice],
                           d=assert(len(good_choice)<=1)
                       )
                       len(good_choice)==1 ? good_choice[0][1] : -1
                    ],
        // Check for duplicates in the neighbor list so we don't add them twice
        dups = search([for(n=neighbors) if (n>=0) n], neighbors,0),
        goodind = column(dups,0),
        newface = [for(i=idx(thisface))
                    each
                     !in_list(i,goodind) ? [thisface[i]]
                    :
                     let(
                         ind = search(select(thisface,i,i+1), faces[neighbors[i]])
                     )
                     select(faces[neighbors[i]],ind[0],ind[1]-1)
                   ],
        usedfaces = [for(n=neighbors) if (n>=0) n],
        faces = list_set(faces,curface,newface),
        facelist = list_remove_values(facelist,usedfaces)
     )
     _detri_combine_faces(edgelist,faces,normals,facelist,len(usedfaces)==0?curface+1:curface);




// Function: vnf_slice()
// Synopsis: Slice the faces of a VNF along an axis.
// SynTags: VNF
// Topics: VNF Manipulation
// See Also: vnf_reverse_faces(), vnf_quantize(), vnf_merge_points(), vnf_drop_unused_points(), vnf_triangulate()
// Usage:
//   sliced = vnf_slice(vnf, dir, cuts);
// Description:
//   Slice the faces of a VNF along a specified axis direction at a given list of cut points.
//   The cut points can appear in any order.  You can use this to refine the faces of a VNF before
//   applying a nonlinear transformation to its vertex set.
// Arguments:
//   vnf = VNF to slice
//   dir = normal direction to the slices, either "X", "Y" or "Z"
//   cuts = X, Y or Z values where cuts occur
// Example(3D):
//   include <BOSL2/polyhedra.scad>
//   vnf = regular_polyhedron_info("vnf", "dodecahedron", side=12);
//   vnf_polyhedron(vnf);
//   sliced = vnf_slice(vnf, "X", [-6,-1,10]);
//   color("red")vnf_wireframe(sliced,width=.3);
function vnf_slice(vnf,dir,cuts) =
    let(
        //  Code below seems to be unnecessary
        //cuts = [for (cut=cuts) _shift_cut_plane(vnf,dir,cut)],
        vert = vnf[0],
        faces = [for(face=vnf[1]) select(vert,face)],
        poly_list = _slice_3dpolygons(faces, dir, cuts)
    )
    vnf_merge_points(vnf_from_polygons(poly_list));


function _shift_cut_plane(vnf,dir,cut,off=0.001) =
    let(
        I = ident(3),
        dir_ind = ord(dir)-ord("X"),
        verts = vnf[0],
        on_cut = [for (x = verts * I[dir_ind]) if(approx(x,cut,eps=1e-4)) 1] != []
    ) !on_cut? cut :
    _shift_cut_plane(vnf,dir,cut+off);


function _split_polygon_at_x(poly, x) =
    let(
        xs = column(poly,0)
    ) (min(xs) >= x || max(xs) <= x)? [poly] :
    let(
        poly2 = [
            for (p = pair(poly,true)) each [
                p[0],
                if(
                    (p[0].x < x && p[1].x > x) ||
                    (p[1].x < x && p[0].x > x)
                ) let(
                    u = (x - p[0].x) / (p[1].x - p[0].x)
                ) [
                    x,  // Important for later exact match tests
                    u*(p[1].y-p[0].y)+p[0].y
                ]
            ]
        ],
        out1 = [for (p = poly2) if(p.x <= x) p],
        out2 = [for (p = poly2) if(p.x >= x) p],
        out3 = [
            if (len(out1)>=3 && polygon_area(out1)>EPSILON) each split_path_at_self_crossings(out1),
            if (len(out2)>=3 && polygon_area(out2)>EPSILON) each split_path_at_self_crossings(out2),
        ],
        out = [for (p=out3) if (len(p) > 2) list_unwrap(p)]
    ) out;


function _split_2dpolygons_at_each_x(polys, xs, _i=0) =
    _i>=len(xs)? polys :
    _split_2dpolygons_at_each_x(
        [
            for (poly = polys)
            each _split_polygon_at_x(poly, xs[_i])
        ], xs, _i=_i+1
    );

/// Internal Function: _slice_3dpolygons()
/// Usage:
///   splitpolys = _slice_3dpolygons(polys, dir, cuts);
/// Topics: Geometry, Polygons, Intersections
/// Description:
///   Given a list of 3D polygons, a choice of X, Y, or Z, and a cut list, `cuts`, splits all of the polygons where they cross
///   X/Y/Z at any value given in cuts.
/// Arguments:
///   polys = A list of 3D polygons to split.
///   dir_ind = slice direction, 0=X, 1=Y, or 2=Z
///   cuts = A list of scalar values for locating the cuts
function _slice_3dpolygons(polys, dir, cuts) =
    assert( [for (poly=polys) if (!is_path(poly,3)) 1] == [], "\nExpected list of 3D paths.")
    assert( is_vector(cuts), "\nThe split list must be a vector.")
    assert( in_list(dir, ["X", "Y", "Z"]))
    let(
        I = ident(3),
        dir_ind = ord(dir)-ord("X")
    )
    flatten([
        for (poly = polys)
            if (polygon_area(poly)>EPSILON)   // Discard zero area polygons
            let( 
                 plane = plane_from_polygon(poly,1e-4))
            assert(plane,"\nFound non-coplanar face.")
            let(
                normal = point3d(plane),
                pnormal = normal - (normal*I[dir_ind])*I[dir_ind]
            )
            approx(pnormal,[0,0,0]) ? [poly]     // Polygons parallel to cut plane just pass through
          : let(
                pind = max_index(v_abs(pnormal)),  // project along this direction
                otherind = 3-pind-dir_ind,         // keep dir_ind and this direction
                keep = [I[dir_ind], I[otherind]],  // dir ind becomes the x dir
                poly2d = poly*transpose(keep),     // project to 2d, putting selected direction in the X position
                poly_list = [for(p=_split_2dpolygons_at_each_x([poly2d], cuts))
                                let(
                                    a = p*keep,    // unproject, but pind dimension data is missing
                                    ofs = outer_product((repeat(plane[3], len(a))-a*normal)/plane[pind],I[pind])
                                 )
                                 a+ofs]    // ofs computes the missing pind dimension data and adds it back in
            )
            poly_list
    ]);





// Section: Turning a VNF into geometry


// Module: vnf_polyhedron()
// Synopsis: Returns a polyhedron from a VNF or list of VNFs.
// SynTags: Geom
// Topics: VNF Manipulation
// See Also: vnf_wireframe()
// Usage:
//   vnf_polyhedron(vnf) [ATTACHMENTS];
//   vnf_polyhedron([VNF, VNF, VNF, ...]) [ATTACHMENTS];
// Description:
//   Given a VNF structure, or a list of VNF structures, creates a polyhedron from them.
// Arguments:
//   vnf = A VNF structure, or list of VNF structures.
//   convexity = Max number of times a line could intersect a wall of the shape.
//   cp = Centerpoint for determining intersection anchors or centering the shape.  Determines the base of the anchor vector.  Can be "centroid", "mean", "box" or a 3D point.  Default: "centroid"
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `"origin"`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top toward, after spin. See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   atype = Select "hull" or "intersect" anchor type.  Default: "hull"
// Anchor Types:
//   "hull" = Anchors to the virtual convex hull of the shape.
//   "intersect" = Anchors to the surface of the shape.
// Named Anchors:
//   "origin" = Anchor at the origin, oriented UP.
module vnf_polyhedron(vnf, convexity=2, cp="centroid", anchor="origin", spin=0, orient=UP, atype="hull") {
    vnf = is_vnf_list(vnf)? vnf_join(vnf) : vnf;
    assert(in_list(atype, _ANCHOR_TYPES), "\nAnchor type must be \"hull\" or \"intersect\".");
    attachable(anchor,spin,orient, vnf=vnf, extent=atype=="hull", cp=cp) {
        polyhedron(vnf[0], vnf[1], convexity=convexity);
        children();
    }
}


// Module: vnf_wireframe()
// Synopsis: Creates a wireframe model from a VNF.
// SynTags: VNF
// Topics: VNF Manipulation
// See Also: vnf_polyhedron()
// Usage:
//   vnf_wireframe(vnf, [width]);
// Description:
//   Given a VNF, creates a wire frame ball-and-stick model of the polyhedron with a cylinder for
//   each edge and a sphere at each vertex.  The width parameter specifies the width of the sticks
//   that form the wire frame and the diameter of the balls.
// Arguments:
//   vnf = A VNF structure
//   width = width of the cylinders forming the wire frame.  Default: 1
// Example(3D):
//   $fn=32;
//   ball = sphere(r=20, $fn=6);
//   vnf_wireframe(ball,width=1);
// Example(3D):
//   include <BOSL2/polyhedra.scad>
//   $fn=32;
//   cube_oct = regular_polyhedron_info("vnf",
//                      name="cuboctahedron", or=20);
//   vnf_wireframe(cube_oct);
// Example(3D): The spheres at the vertex are imperfect at aligning with the cylinders, so especially at low $fn things look prety ugly.  This is normal.
//   include <BOSL2/polyhedra.scad>
//   $fn=8;
//   octahedron = regular_polyhedron_info("vnf",
//                         name="octahedron", or=20);
//   vnf_wireframe(octahedron,width=5);
module vnf_wireframe(vnf, width=1)
{
  no_children($children);
  vertex = vnf[0];
  edges = unique([for (face=vnf[1], i=idx(face))
                    sort([face[i], select(face,i+1)])
                 ]);
  attachable()
  {
    union(){
      for (e=edges) extrude_from_to(vertex[e[0]],vertex[e[1]]) circle(d=width);
      // Identify vertices actually used and draw them
      vertused = search(count(len(vertex)), flatten(edges), 1);
      for(i=idx(vertex)) if(vertused[i]!=[]) move(vertex[i]) sphere(d=width);
    }
    union();
  }
}


// Section: Operations on VNFs

       

// Function: vnf_volume()
// Synopsis: Returns the volume of a VNF.
// Topics: VNF Manipulation
// See Also: vnf_area(), vnf_halfspace(), vnf_bend() 
// Usage:
//   vol = vnf_volume(vnf);
// Description:
//   Returns the volume enclosed by the given manifold VNF.   The VNF must describe a valid polyhedron with consistent face direction and
//   no holes; otherwise the results are undefined.  Returns a positive volume if face direction is clockwise and a negative volume
//   if face direction is counter-clockwise.

// Divide the polyhedron into tetrahedra with the origin as one vertex and sum up the signed volume.
function vnf_volume(vnf) =
    let(verts = vnf[0])
    sum([
         for(face=vnf[1], j=[1:1:len(face)-2])
             cross(verts[face[j+1]], verts[face[j]]) * verts[face[0]]
    ])/6;


// Function: vnf_area()
// Synopsis: Returns the surface area of a VNF.
// Topics: VNF Manipulation
// See Also: vnf_volume(), vnf_halfspace(), vnf_bend() 
// Usage:
//   area = vnf_area(vnf);
// Description:
//   Returns the surface area in any VNF by adding up the area of all its faces.  The VNF need not be a manifold.
function vnf_area(vnf) =
    let(verts=vnf[0])
    sum([for(face=vnf[1]) polygon_area(select(verts,face))]);


/// Internal Function: _vnf_centroid()
/// Usage:
///   vol = _vnf_centroid(vnf);
/// Description:
///   Returns the centroid of the given manifold VNF.  The VNF must describe a valid polyhedron with consistent face direction and
///   no holes; otherwise the results are undefined.

/// Divide the solid up into tetrahedra with the origin as one vertex.
/// The centroid of a tetrahedron is the average of its vertices.
/// The centroid of the total is the volume weighted average.
function _vnf_centroid(vnf,eps=EPSILON) =
    assert(is_vnf(vnf) && len(vnf[0])!=0 && len(vnf[1])!=0,"\nInvalid or empty VNF given to centroid.")
    let(
        verts = vnf[0],
        pos = sum([
            for(face=vnf[1], j=[1:1:len(face)-2]) let(
                v0  = verts[face[0]],
                v1  = verts[face[j]],
                v2  = verts[face[j+1]],
                vol = cross(v2,v1)*v0
            )
            [ vol, (v0+v1+v2)*vol ]
        ])
    )
    assert(!approx(pos[0],0, eps), "\nThe vnf has self-intersections.")
    pos[1]/pos[0]/4;

// Function: vnf_bounds()
// Synopsis: Returns the min and max bounding coordinates for the VNF.
// Topics: VNF Manipulation, Bounding Boxes, Bounds
// See Also: pointlist_bounds()
// Usage:
//   min_max = vnf_bounds(vnf, [fast]);
// Description:
//   Finds the bounds of the VNF.  By default the calculation skips any points listed in the VNF vertex list
//   that are not used by the VNF.  However, this calculation may be slow on large VNFS.  If you set `fast=true`
//   then the calculation uses all the points listed in the VNF, regardless of whether they appear in the
//   actual object.  The returned list has the form `[[MINX, MINY, MINZ], [MAXX, MAXY, MAXZ]]`.
// Arguments:
//   vnf = vnf to get the bounds of
//   fast = if true then ignore face data and process all vertices; if false, look only at vertices actually used in the geometry.  Default: false
// Example:
//   echo(vnf_bounds(cube([2,3,4],center=true)));   // Displays [[-1, -1.5, -2], [1, 1.5, 2]]
function vnf_bounds(vnf,fast=false) =
  assert(is_vnf(vnf), "\nInvalid VNF.")
  fast ? pointlist_bounds(vnf[0])
       : let(
             vert = vnf[0]
         )
         pointlist_bounds([for(face=vnf[1]) each select(vert,face)]);

// Function: projection()
// Synopsis: Returns projection or intersection of vnf with XY plane
// SynTags: VNF
// Topics: VNF Manipulation
// See Also: vnf_halfspace()
// Usage:
//   region = projection(vnf, [cut], [z]);
// Description:
//   Project a VNF object onto the xy plane at position `z`, returning a region.
//   .
//   The default action (`cut=false`) is to projects the input VNF
//   onto the XY plane, returning a region.  As currently implemented, this operation
//   involves the 2D union of all the projected faces and can be
//   slow if the VNF has many faces.  Minimize the face count of the VNF for best performance. 
//   .
//   When `cut=true`, returns the intersection of the VNF with the
//   XY plane at the position given by `z` (default `z=0`), which is again a region.
//   If the VNF does not intersect the plane, then returns the empty set.  This operation is
//   much faster than `cut=false`.
// Arguments:
//   vnf = The VNF object to project to a plane.
//   cut = When true, returns a region containing intersection of the VNF with the plane. When false, projects the entire VNF onto the plane. Default: false
//   z = Optional z position of the XY plane, useful when `cut=true` to get a specific slice position. Ignored if `cut=false`. Default: 0
// Example(3D): Here's a VNF with two linked toruses and a small cube
//   vnf = vnf_join([
//            xrot(90,torus(id=15,od=24,$fn=5)),
//            right(12,torus(id=15,od=24,$fn=4)),
//            up(13,right(15,cube(3,center=true)))
//         ]);
//   vnf_polyhedron(vnf);
// Example(2D): Projection of above VNF with default behavior, `cut=false`
//   vnf = vnf_join([
//            xrot(90,torus(id=15,od=24,$fn=5)),
//            right(12,torus(id=15,od=24,$fn=4)),
//            up(13,right(15,cube(3,center=true)))
//         ]);
//   reg = projection(vnf);
//   region(reg);
// Example(3D): Tilted torus
//   vnf = xrot(35,torus(id=4,od=12,$fn=32));
//   vnf_polyhedron(vnf);
// Example(2D): Projection of tilted torus using `cut=true`
//   vnf = xrot(35,torus(id=4,od=12,$fn=32));
//   reg = projection(vnf,cut=true);
//   region(reg);
// Example(2D): Projection of tilted torus using `cut=true` at a different z position for the XY plane.
//   vnf = xrot(35,torus(id=4,od=12,$fn=32));
//   reg = projection(vnf,cut=true,z=0.3);
//   region(reg);

function projection(vnf,cut=false,z=0,eps=EPSILON) =
   assert(is_vnf(vnf))
   cut ?
         let(
              vnf_bdy = vnf_halfspace([0,0,1,cut?z:0],vnf, boundary=true),
              ind = vnf_bdy[1],
              pts = path2d(vnf_bdy[0][0])
         )
         ind==[] ? []
                 : [for (path=ind) select(pts, path)]
  :
   let(
        pts = vnf[0],
        faces = vnf[1], 
        facets = [for(face=faces)
                     let(projface = path2d(select(pts,face)))
                     if (!approx(polygon_area(projface),0,eps=eps))
                        projface
                 ]
   )
   union(facets);



// Function: vnf_halfspace()
// Synopsis: Returns the intersection of the vnf with a half space.
// SynTags: VNF
// Topics: VNF Manipulation
// See Also: vnf_volume(), vnf_area(), vnf_bend() 
// Usage:
//   newvnf = vnf_halfspace(plane, vnf, [closed], [boundary]);
// Description:
//   Returns the intersection of the vnf with a half space.  The half space is defined by
//   plane = [A,B,C,D], taking the side where the normal [A,B,C] points: Ax+By+Cz≥D.
//   If closed is set to false then the cut face is not included in the vnf.  This could
//   allow further extension of the vnf by join with other vnfs using {{vnf_join()}}.
//   If your given VNF has holes (missing faces) or is not a complete polyhedron
//   then closed=true is may produce invalid results when it tries to construct closing faces
//   on the cut plane.  Set closed=false for such inputs.
//   .
//   If you set `boundary=true` then the return is the pair `[vnf,boundary]`, where `vnf` is the
//   VNF as usual (with `closed=false`) and boundary is a list giving each connected component of the cut
//   boundary surface.  Each entry in boundary is a list of index values that index into the vnf vertex list (vnf[0]).
//   This makes it possible to construct mating shapes, e.g. with {{skin()}} or {{vnf_vertex_array()}} that
//   can be combined using {{vnf_join()}} to make a valid polyhedron.
//   .
//   The input to vnf_halfspace() does not need to be a closed, manifold polyhedron.
//   Because it adds the faces on the cut surface, you can use vnf_halfspace() to cap off an open shape if you
//   slice through a region that excludes all of the gaps in the input VNF.  
// Arguments:
//   plane = plane defining the boundary of the half space
//   vnf = VNF to cut
//   closed = if false do not return the cut face(s) in the returned VNF.  Default: true
//   boundary = if true return a pair [vnf,boundary] where boundary is a list of paths on the cut boundary indexed into the VNF vertex list.  If boundary is true, then closed is set to false.  Default: false
// Example(3D):
//   vnf = cube(10,center=true);
//   cutvnf = vnf_halfspace([-1,1,-1,0], vnf);
//   vnf_polyhedron(cutvnf);
// Example(3D):  Cut face has 2 components
//   vnf = path_sweep(circle(r=4, $fn=16),
//                    circle(r=20, $fn=64),closed=true);
//   cutvnf = vnf_halfspace([-1,1,-4,0], vnf);
//   vnf_polyhedron(cutvnf);
// Example(3D): Cut face is not simply connected
//   vnf = path_sweep(circle(r=4, $fn=16),
//                    circle(r=20, $fn=64),closed=true);
//   cutvnf = vnf_halfspace([0,0.7,-4,0], vnf);
//   vnf_polyhedron(cutvnf);
// Example(3D): Cut object has multiple components
//   function knot(a,b,t) =   // rolling knot
//        [ a * cos (3 * t) / (1 - b* sin (2 *t)),
//          a * sin( 3 * t) / (1 - b* sin (2 *t)),
//        1.8 * b * cos (2 * t) /(1 - b* sin (2 *t))];
//   a = 0.8; b = sqrt (1 - a * a);
//   ksteps = 400;
//   knot_path = [for (i=[0:ksteps-1]) 50 * knot(a,b,(i/ksteps)*360)];
//   ushape = [[-10, 0],[-10, 10],[ -7, 10],[ -7, 2],[  7, 2],[  7, 7],[ 10, 7],[ 10, 0]];
//   knot=path_sweep(ushape, knot_path, closed=true, method="incremental");
//   cut_knot = vnf_halfspace([1,0,0,0], knot);
//   vnf_polyhedron(cut_knot);
// Example(3D,VPR=[80,0,15]): Cut a sphere with an arbitrary plane
//   vnf1=spheroid(r=50, style="icosa", $fn=16);
//   vnf2=vnf_halfspace([.8,1,-1.5,0], vnf1);
//   vnf_polyhedron(vnf2);
// Example(3D,VPR=[80,0,15]): Cut it again, but with closed=false to leave an open boundary. 
//   vnf1=spheroid(r=50, style="icosa", $fn=16);
//   vnf2=vnf_halfspace([.8,1,-1.5,0], vnf1);
//   vnf3=vnf_halfspace([0,0,-1,0], vnf2, closed=false);
//   vnf_polyhedron(vnf3);
// Example(3D,VPR=[80,0,15]): Use {vnf_join()} to combine with a mating vnf, in this case a reflection of the part we made. 
//   vnf1=spheroid(r=50, style="icosa", $fn=16);
//   vnf2=vnf_halfspace([.8,1,-1.5,0], vnf1);
//   vnf3=vnf_halfspace([0,0,-1,0], vnf2, closed=false);
//   vnf4=vnf_join([vnf3, zflip(vnf3,1)]);
//   vnf_polyhedron(vnf4);
// Example(3D): When the input VNF is a surface with a boundary, if you use the default setting closed=true, then vnf_halfspace() tries to construct closing faces from the edges created by the cut.  These faces may be invalid, for example if the cut points are collinear.  In this example the constructed face is a valid face.
//   patch=[
//          [[10,-10,0],[1,-1,0],[-1,-1,0],[-10,-10,0]],
//          [[10,-10,20],[1,-1,20],[-1,-1,20],[-10,-10,20]]
//         ];
//   vnf=bezier_vnf(patch);
//   vnfcut = vnf_halfspace([-.8,0,-1,-14],vnf);
//   vnf_polyhedron(vnfcut);
// Example(3D): Setting closed to false eliminates this (possibly invalid) face:
//   patch=[
//          [[10,-10,0],[1,-1,0],[-1,-1,0],[-10,-10,0]],
//          [[10,-10,20],[1,-1,20],[-1,-1,20],[-10,-10,20]]
//         ];
//   vnf=bezier_vnf(patch);
//   vnfcut = vnf_halfspace([-.8,0,-1,-14],vnf,closed=false);
//   vnf_polyhedron(vnfcut);
// Example(3D): Here is a VNF that has holes, so it is not a valid manifold. 
//   outside = linear_sweep(circle(r=30), h=100, caps=false);
//   inside = yrot(7,linear_sweep(circle(r=10), h=120, caps=false));
//   open_vnf=vnf_join([outside, vnf_reverse_faces(inside)]);
//   vnf_polyhedron(open_vnf);
// Example(3D): By cutting it at each end we can create closing faces, resulting in a valid manifold without holes.
//   outside = linear_sweep(circle(r=30), h=100, caps=false);
//   inside = yrot(11,linear_sweep(circle(r=10), h=120, caps=false));
//   open_vnf=vnf_join([outside, vnf_reverse_faces(inside)]);
//   vnf = vnf_halfspace([0,0,1,5], vnf_halfspace([0,.7,-1,-75], open_vnf));
//   vnf_polyhedron(vnf);
// Example(3D): If boundary=true then the return is a list with the VNF and boundary data.  
//   vnf = path_sweep(circle(r=4, $fn=16),
//                    circle(r=20, $fn=64),closed=true);
//   cut_bnd = vnf_halfspace([-1,1,-4,0], vnf, boundary=true);
//   cutvnf = cut_bnd[0];
//   boundary = [for(b=cut_bnd[1]) select(cutvnf[0],b)];
//   vnf_polyhedron(cutvnf);
//   stroke(boundary,color="red");
function vnf_halfspace(plane, vnf, closed=true, boundary=false) =
    assert(_valid_plane(plane), "\nInvalid plane.")
    assert(is_vnf(vnf), "\nInvalid VNF.")
    let(
         inside = [for(x=vnf[0]) plane*[each x,-1] >= -EPSILON ? 1 : 0],
         vertexmap = [0,each cumsum(inside)],
         faces_edges_vertices = _vnfcut(plane, vnf[0],vertexmap,inside, vnf[1], last(vertexmap)),
         newvert = concat(bselect(vnf[0],inside), faces_edges_vertices[2])
    )
    closed==false && !boundary ? [newvert, faces_edges_vertices[0]]
  : let(
        allpaths = _assemble_paths(newvert, faces_edges_vertices[1]),
        newpaths = [for(p=allpaths) if (len(p)>=3) p
                                    else assert(approx(p[0],p[1]),"\nOrphan edge found when assembling cut edges.")
           ]
    )
    boundary ? [[newvert, faces_edges_vertices[0]], newpaths]
  : len(newpaths)<=1 ? [newvert, concat(faces_edges_vertices[0], newpaths)]
  : let(
           M = project_plane(plane),
           faceregion = [for(path=newpaths) path2d(apply(M,select(newvert,path)))],
           facevnf = vnf_from_region(faceregion,transform=rot_inverse(M),reverse=true)
      )
      vnf_join([[newvert, faces_edges_vertices[0]], facevnf]);

function _assemble_paths(vertices, edges, paths=[],i=0) =
     i==len(edges) ? paths :
     norm(vertices[edges[i][0]]-vertices[edges[i][1]])<EPSILON ? _assemble_paths(vertices,edges,paths,i+1) :
     let(    // Find paths that connects on left side and right side of the edges (if one exists)
         left = [for(j=idx(paths)) if (approx(vertices[last(paths[j])],vertices[edges[i][0]])) j],
         right = [for(j=idx(paths)) if (approx(vertices[edges[i][1]],vertices[paths[j][0]])) j]
     )
     assert(len(left)<=1 && len(right)<=1)
     let(
          keep_path = list_remove(paths,concat(left,right)),
          update_path = left==[] && right==[] ? edges[i]
                      : left==[] ? concat([edges[i][0]],paths[right[0]])
                      : right==[] ?  concat(paths[left[0]],[edges[i][1]])
                      : left != right ? concat(paths[left[0]], paths[right[0]])
                      : paths[left[0]]
     )
     _assemble_paths(vertices, edges, concat(keep_path, [update_path]), i+1);


function _vnfcut(plane, vertices, vertexmap, inside, faces, vertcount, newfaces=[], newedges=[], newvertices=[], i=0) =
   i==len(faces) ? [newfaces, newedges, newvertices] :
   let(
        pts_inside = select(inside,faces[i])
   )
   all(pts_inside) ? _vnfcut(plane, vertices, vertexmap, inside, faces, vertcount,
                             concat(newfaces, [select(vertexmap,faces[i])]), newedges, newvertices, i+1):
   !any(pts_inside) ? _vnfcut(plane, vertices, vertexmap,inside, faces, vertcount, newfaces, newedges, newvertices, i+1):
   let(
        first = search([[1,0]],pair(pts_inside,wrap=true),0)[0],
        second = search([[0,1]],pair(pts_inside,wrap=true),0)[0]
   )
   assert(len(first)==1 && len(second)==1, "\nFound concave face in VNF. Run vnf_triangulate first to ensure convex faces.")
   let(
        newface = [each select(vertexmap,select(faces[i],second[0]+1,first[0])),vertcount, vertcount+1],
        newvert = [plane_line_intersection(plane, select(vertices,select(faces[i],first[0],first[0]+1)),eps=0),
                   plane_line_intersection(plane, select(vertices,select(faces[i],second[0],second[0]+1)),eps=0)]
   )
   true //!approx(newvert[0],newvert[1])
       ? _vnfcut(plane, vertices, vertexmap, inside, faces, vertcount+2,
                 concat(newfaces, [newface]), concat(newedges,[[vertcount+1,vertcount]]),concat(newvertices,newvert),i+1)
   :len(newface)>3
       ? _vnfcut(plane, vertices, vertexmap, inside, faces, vertcount+1,
                 concat(newfaces, [list_head(newface)]), newedges,concat(newvertices,[newvert[0]]),i+1)
   :
   _vnfcut(plane, vertices, vertexmap, inside, faces, vertcount,newfaces, newedges, newvert, i+1);




function _triangulate_planar_convex_polygons(polys) =
    polys==[]? [] :
    let(
        tris = [for (poly=polys) if (len(poly)==3) poly],
        bigs = [for (poly=polys) if (len(poly)>3) poly],
        newtris = [for (poly=bigs) select(poly,-2,0)],
        newbigs = [for (poly=bigs) select(poly,0,-2)],
        newtris2 = _triangulate_planar_convex_polygons(newbigs),
        outtris = concat(tris, newtris, newtris2)
    ) outtris;

//**
// this function may produce degenerate triangles:
//    _triangulate_planar_convex_polygons([ [for(i=[0:1]) [i,i],
//                                           [1,-1], [-1,-1],
//                                           for(i=[-1:0]) [i,i] ] ] )
//    == [[[-1, -1], [ 0,  0], [0,  0]]
//        [[-1, -1], [-1, -1], [0,  0]]
//        [[ 1, -1], [-1, -1], [0,  0]]
//        [[ 0,  0], [ 1,  1], [1, -1]] ]
//

// Function: vnf_bend()
// Synopsis: Bends a VNF around an axis.
// SynTags: VNF
// Topics: VNF Manipulation
// See Also: vnf_volume(), vnf_area(), vnf_halfspace() 
// Usage:
//   bentvnf = vnf_bend(vnf,r|d=,[axis=]);
// Description:
//   Bend a VNF around the X, Y or Z axis, splitting up faces as necessary.  Returns the bent
//   VNF.  For bending around the Z axis the input VNF must not cross the Y=0 plane.  For bending
//   around the X or Y axes the VNF must not cross the Z=0 plane.  If you wrap a VNF all the way around
//   it may intersect itself, which produces an invalid polyhedron.  It is your responsibility to
//   avoid this situation.  The 1:1
//   radius is where the curved length of the bent VNF matches the length of the original VNF.  If the
//   `r` or `d` arguments are given, then they specify the 1:1 radius or diameter.  If they are
//   not given, then the 1:1 radius is defined by the distance of the furthest vertex in the
//   original VNF from the Z=0 plane.  You can adjust the granularity of the bend using the standard
//   `$fa`, `$fs`, and `$fn` variables.
// Arguments:
//   vnf = The original VNF to bend.
//   r = If given, the radius where the size of the original shape is the same as in the original.
//   ---
//   d = If given, the diameter where the size of the original shape is the same as in the original.
//   axis = The axis to wrap around.  "X", "Y", or "Z".  Default: "Z"
// Example(3D):
//   vnf0 = cube([100,40,10], center=true);
//   vnf1 = up(50, p=vnf0);
//   vnf2 = down(50, p=vnf0);
//   bent1 = vnf_bend(vnf1, axis="Y");
//   bent2 = vnf_bend(vnf2, axis="Y");
//   vnf_polyhedron([bent1,bent2]);
// Example(3D):
//   vnf0 = linear_sweep(star(n=5,step=2,d=100), height=10);
//   vnf1 = up(50, p=vnf0);
//   vnf2 = down(50, p=vnf0);
//   bent1 = vnf_bend(vnf1, axis="Y");
//   bent2 = vnf_bend(vnf2, axis="Y");
//   vnf_polyhedron([bent1,bent2]);
// Example(3D):
//   rgn = union(rect([100,20]),
//               rect([20,100]));
//   vnf0 = linear_sweep(zrot(45,p=rgn), height=10);
//   vnf1 = up(50, p=vnf0);
//   vnf2 = down(50, p=vnf0);
//   bent1 = vnf_bend(vnf1, axis="Y");
//   bent2 = vnf_bend(vnf2, axis="Y");
//   vnf_polyhedron([bent1,bent2]);
// Example(3D): Bending Around X Axis.
//   rgnr = union(
//       rect([20,100]),
//       back(50, p=trapezoid(w1=40, w2=0, h=20, anchor=FRONT))
//   );
//   vnf0 = xrot(00,p=linear_sweep(rgnr, height=10));
//   vnf1 = up(50, p=vnf0);
//   #vnf_polyhedron(vnf1);
//   bent1 = vnf_bend(vnf1, axis="X");
//   vnf_polyhedron([bent1]);
// Example(3D): Bending Around Y Axis.
//   rgn = union(
//       rect([20,100]),
//       back(50, p=trapezoid(w1=40, w2=0, h=20, anchor=FRONT))
//   );
//   rgnr = zrot(-90, p=rgn);
//   vnf0 = xrot(00,p=linear_sweep(rgnr, height=10));
//   vnf1 = up(50, p=vnf0);
//   #vnf_polyhedron(vnf1);
//   bent1 = vnf_bend(vnf1, axis="Y");
//   vnf_polyhedron([bent1]);
// Example(3D): Bending Around Z Axis.
//   rgn = union(
//       rect([20,100]),
//       back(50, p=trapezoid(w1=40, w2=0, h=20, anchor=FRONT))
//   );
//   rgnr = zrot(90, p=rgn);
//   vnf0 = xrot(90,p=linear_sweep(rgnr, height=10));
//   vnf1 = fwd(50, p=vnf0);
//   #vnf_polyhedron(vnf1);
//   bent1 = vnf_bend(vnf1, axis="Z");
//   vnf_polyhedron([bent1]);
// Example(3D): Bending more than once around the cylinder
//   $fn=32;
//   vnf = apply(fwd(5)*yrot(30),cube([100,2,5],center=true));
//   bent = vnf_bend(vnf, axis="Z");
//   vnf_polyhedron(bent);
function vnf_bend(vnf,r,d,axis="Z") =
    let(
        chk_axis = assert(in_list(axis,["X","Y","Z"])),
        verts = vnf[0],
        bounds = pointlist_bounds(verts),
        bmin = bounds[0],
        bmax = bounds[1],
        dflt = axis=="Z"?
            max(abs(bmax.y), abs(bmin.y)) :
            max(abs(bmax.z), abs(bmin.z)),
        r = get_radius(r=r,d=d,dflt=dflt),
        extent = axis=="X" ? [bmin.y, bmax.y] : [bmin.x, bmax.x]
    )
    let(
        span_chk = axis=="Z"?
            assert(bmin.y > 0 || bmax.y < 0, "\nEntire shape MUST be completely in front of or behind y=0.") :
            assert(bmin.z > 0 || bmax.z < 0, "\nEntire shape MUST be completely above or below z=0."),
        steps = 1+ceil(segs(r) * (extent[1]-extent[0])/(2*PI*r)),
        step = (extent[1]-extent[0]) / steps,
        bend_at = [for(i = [1:1:steps-1]) i*step+extent[0]],
        slicedir = axis=="X"? "Y" : "X",   // slice in y dir for X axis case, and x dir otherwise
        sliced = vnf_triangulate(vnf_slice(vnf, slicedir, bend_at)),
        coord = axis=="X" ? [0,sign(bmax.z),0] : axis=="Y" ? [sign(bmax.z),0,0] : [sign(bmax.y),0,0],
        new_vert = [for(p=sliced[0])
                       let(a=coord*p*180/(PI*r))
                       axis=="X"? [p.x, p.z*sin(a), p.z*cos(a)] :
                       axis=="Y"? [p.z*sin(a), p.y, p.z*cos(a)] :
                       [p.y*sin(a), p.y*cos(a), p.z]]
   ) [new_vert,sliced[1]];



// Function&Module: vnf_hull()
// Synopsis: Compute convex hull of VNF or 3d path
// Usage: (as a function)
//    vnf_hull = hull_vnf(vnf);
// Usage: (as a module)
//    vnf_hull(vnf,[fast]);
// Description:
//   Given a VNF or a list of 3d points, compute the convex hull
//   and return it as a VNF.  This differs from {{hull()}} and {{hull3d_faces()}}, which
//   return just the face list referenced to the input point list.  The returned
//   point list contains all the points that are actually used in the input
//   VNF, which may be many more points than are needed to represent the convex hull.
//   This is not usually a problem, but you can run the somewhat slow {{vnf_drop_unused_points()}}
//   function to fix this if necessary.
//   .
//   If you call this as a module with a VNF it invokes hull() on the polyhedron described by the VNF.
//   The `fast` argument is ignored in this case.  If you call this as a module on a list of points then
//   it calls {{hull_points()}} and passes the `fast` argument.  
// Arguments:
//   region = region or path listing points to compute the hull from.
//   fast = (module only) if input is a point list (not a VNF) use a fasterer cheat that may handle more points, but could emit warnings.  Ignored if input is a VNF.  Default: false.  
// Example(3D,Big,NoAxes,VPR=[55,0,25],VPT=[9.47096,-4.50217,8.45727],VPD=60.2654): Input is a VNF
//   ellipse = xscale(2, p=circle($fn=48, r=3));
//   pentagon = subdivide_path(pentagon(r=1), 20);
//   vnf=path_sweep(pentagon, path3d(ellipse),
//                  closed=true, twist=360*2);
//   vnfhull = vnf_hull(vnf);
//   vnf_polyhedron(vnf);
//   move([10,10])
//     vnf_polyhedron(vnfhull);
// Example(3D,Med,NoAxes,VPR=[70.4,0,110.4],VPT=[5.97456,1.26459,18.0317],VPD=126): Input is a point list
//   h=helix(l=40, turns=1, r=8);
//   color("red")move_copies(h)
//     sphere(r=0.5,$fn=12);
//   vnf_polyhedron(vnf_hull(h));
// Example(3D): As a module with a VNF as input
//   vnf = torus(d_maj=4, d_min=4);
//   vnf_hull(vnf);
function vnf_hull(vnf) =
  assert(is_vnf(vnf) || is_path(vnf,3),"\nInput must be a VNF or a 3d path.")
  let(
      pts = is_vnf(vnf) ? select(vnf[0],unique(flatten(vnf[1])))
                        : vnf,
      faces = hull3d_faces(pts)
  )
  [pts, faces];

module vnf_hull(vnf, fast=false)
{
  if (is_vnf(vnf)) hull()vnf_polyhedron(vnf);
  else hull_points(vnf, fast);
}  



function _sort_pairs0(arr) =
    len(arr)<=1 ? arr : 
    let(
        pivot   = arr[floor(len(arr)/2)][0],
        lesser  = [ for (y = arr) if (y[0].x  < pivot.x || (y[0].x==pivot.x && y[0].y<pivot.y)) y ],
        equal   = [ for (y = arr) if (y[0] == pivot) y ],
        greater = [ for (y = arr) if (y[0].x > pivot.x || (y[0].x==pivot.x && y[0].y>pivot.y)) y ]
    ) 
    concat( _sort_pairs0(lesser), equal, _sort_pairs0(greater) );


// Function: vnf_boundary()
// Synopsis: Returns the boundary of a VNF as a list of paths
// SynTags: VNF
// Topics: VNF Manipulation
// See Also: vnf_halfspace(), vnf_merge_points()
// Usage:
//   boundary = vnf_boundary(vnf, [merge=], [idx=]);
// Description:
//   Returns the boundary of a VNF as a list of paths.  **The input VNF must not contain duplicate points.**  By default, vnf_boundary() calls {{vnf_merge_points()}}
//   to remove duplicate points.  Note, however, that this operation can be slow.  If you are **certain** there are no duplicate points you can
//   set `merge=false` to disable the automatic point merge and save time.  The result of running on a VNF with duplicate points is likely to
//   be incorrect or invalid; it may produce obscure errors.   
//   .
//   The output is a list of closed 3D paths.  If the VNF has no boundary then the output is `[]`.  The boundary path(s) are
//   traversed in the same direction as the edges in the original VNF.  
//   .
//   It is sometimes desirable to have the boundary available as an index list into the VNF vertex list.  However, merging the points in the VNF changes the 
//   VNF vertex point list.  If you set `merge=false` you can also set `idx=true` to get an index list.  As noted above, you must be certain
//   that your in put VNF has no duplicate vertices, perhaps by running {{vnf_merge_points()}} yourself on it.  With `idx=true`
//   the output consists of indices into the VNF vertex list, which enables you to associate the vertices on the boundary path with the original VNF.
// Arguments:
//   vnf = input vnf
//   ---
//   merge = set to false to suppress the automatic invocation of {{vnf_merge_points()}}.  Default: true
//   idx = if true, return indices into VNF vertices instead of actual 3D points.  Must set `merge=false` to enable this.  Default: false
// Example(3D,NoAxes,VPT=[7.06325,-20.8414,20.1803],VPD=292.705,VPR=[55,0,25.7]):  In this example we know that the bezier patch VNF has no duplicate vertices, so we do not need to run {{vnf_merge_points()}}.
//   patch = [
//        // u=0,v=0                                         u=1,v=0
//        [[-50,-50,  0], [-16,-50,  20], [ 16,-50, -20], [50,-50,  0]],
//        [[-50,-16, 20], [-16,-16,  20], [ 16,-16, -20], [50,-16, 20]],
//        [[-50, 16, 20], [-16, 16, -20], [ 16, 16,  20], [50, 16, 20]],
//        [[-50, 50,  0], [-16, 50, -20], [ 16, 50,  20], [50, 50,  0]],
//        // u=0,v=1                                         u=1,v=1
//   ];                
//   bezvnf = bezier_vnf(patch);
//   boundary = vnf_boundary(bezvnf);
//   vnf_polyhedron(bezvnf);
//   stroke(boundary,color="green");
// Example(3D,NoAxes,VPT=[-11.1252,-19.7333,8.39927],VPD=82.6686,VPR=[71.8,0,335.3]): An example with two path components on the boundary.  The output from {{vnf_halfspace()}} can contain duplicate vertices, so we must invoke {{vnf_merge_points()}}.  
//   vnf = torus(id=20,od=40,$fn=28);
//   cutvnf=vnf_halfspace([0,1,0,0],
//            vnf_halfspace([-1,.5,-2.5,-12], vnf, closed=false),
//            closed=false);
//   vnf_polyhedron(cutvnf);
//   boundary = vnf_boundary(vnf_merge_points(cutvnf));
//   stroke(boundary,color="green");
function vnf_boundary(vnf,merge=true,idx=false) =
   assert(!idx || !merge, "\nCannot request indices unless marge=false and VNF contains no duplicate vertices.")
   let(
       vnf = merge ? vnf_merge_points(vnf) : vnf,
       edgelist= [ for(face=vnf[1], edge=pair(face,wrap=true))
                      [edge.x<edge.y ? edge : [edge.y,edge.x],edge]
                 ],
       sortedge = _sort_pairs0(edgelist),  
       edges=  [
                if (sortedge[0][0]!=sortedge[1][0]) sortedge[0][1],
                for(i=[1:1:len(sortedge)-2])
                     if (sortedge[i][0]!=sortedge[i-1][0] && sortedge[i][0]!=sortedge[i+1][0]) sortedge[i][1],
                if (last(sortedge)[0] != sortedge[len(sortedge)-2][0]) last(sortedge)[1]
               ],
       paths = _assemble_paths(vnf[0], edges)    // could be made cleaner and maybe more robust with an _assemble_path version that 
   )                                             // uses edge vertex indices instead of actual point values
   idx ? paths : [for(path=paths) select(vnf[0],path)];


// Function: vnf_small_offset()
// Synopsis: Computes an offset surface to a VNF for small offset distances
// SynTags: VNF
// Topics: VNF Manipulation
// See Also: vnf_sheet(), vnf_merge_points()
// Usage:
//   newvnf = vnf(vnf, delta, [merge=]);
// Description:
//   Computes a simple offset of a VNF by estimating the normal at every point based on the weighted average of surrounding polygons
//   in the mesh.  The offset distance, `delta`, must be small enough so that no self-intersection occurs, which is no issue when the
//   curvature is positive (like the outside of a sphere) but for negative curvature it means the offset distance must be smaller
//   than the smallest radius of curvature of the VNF. Any self-intersection that occurs
//   invalidates the resulting geometry, giving you an error when you introduce a second object into the model.
//   **It is your responsibility to avoid invalid geometry!**  It cannot be detected automatically.  
//   The positive offset direction is toward the outside of the VNF, the faces that are colored yellow in the "thrown together" view.  
//   .
//   **The input VNF must not contain duplicate points.**  By default, vnf_small_offset() calls {{vnf_merge_points()}}
//   to remove duplicate points.  Note, however, that this operation can be slow.  If you are **certain** there are no duplicate points you can
//   set `merge=false` to disable the automatic point merge and save time.  The result of running on a VNF with duplicate points is likely to
//   be incorrect or invalid.
// Arguments:
//   vnf = vnf to offset
//   delta = distance of offset, positive to offset out, negative to offset in
//   ---
//   merge = set to false to suppress the automatic invocation of {{vnf_merge_points()}}.  Default: true
// Example(3D):  The original sphere is on the left and an offset sphere on the right.  
//   vnf = sphere(d=100);
//   xdistribute(spacing=125){
//     vnf_polyhedron(vnf);
//     vnf_polyhedron(vnf_small_offset(vnf,18));
//   }
// Example(3D): The polyhedron on the left is enlarged to match the size of the offset polyhedron on the right.  The offset does **not** preserve coplanarity of faces.  This is because the vertices all move independently, so nothing constrains faces to remain coplanar.  
//   include <BOSL2/polyhedra.scad>
//   vnf = regular_polyhedron_info("vnf","pentagonal icositetrahedron",d=25);
//   xdistribute(spacing=300){
//     scale(11)vnf_polyhedron(vnf);
//     vnf_polyhedron(vnf_small_offset(vnf,125));
//   }
function vnf_small_offset(vnf, delta, merge=true) =
   let(
        vnf = merge ? vnf_merge_points(vnf) : vnf, 
        vertices = vnf[0],
        faces = vnf[1],
        vert_faces = group_data(
            [for (i = idx(faces), vert = faces[i]) vert],
            [for (i = idx(faces), vert = faces[i]) i]
        ),
        normals = [for(face=faces) polygon_normal(select(vertices,face))],   // Normals for each face
        offset = [for(vertex=idx(vertices))
                    let(
                        vfaces = vert_faces[vertex], // Faces that surround this vertex
                        adjacent_normals = select(normals,vfaces),
                        angles = [for(faceind=vfaces)
                                    let(
                                        thisface = faces[faceind],
                                        vind = search(vertex,thisface)[0]
                                    )
                                    vector_angle(select(vertices, select(thisface,vind-1,vind+1)))
                                 ]
                    )
                    vertices[vertex] +unit(angles*adjacent_normals)*delta
                 ]
    )
    [offset,faces];

// Function: vnf_sheet()
// Synopsis: Extends a VNF into a thin sheet by extruding normal to the VNF
// SynTags: VNF
// Topics: VNF Manipulation
// See Also: vnf_small_offset(), vnf_boundary(), vnf_merge_points()
// Usage:
//   newvnf = vnf_sheet(vnf, delta, [style=], [merge=]);
// Description:
//   Constructs a thin sheet from a vnf by offsetting the vnf along the normal vectors estimated at
//   each vertex by averaging the normals of the adjacent faces.  This is done using {{vnf_small_offset()}.
//   The `delta` parameter is a 2-vector specifying the offset distances for both surfaces that form the
//   final sheet. The values for each offset must be small enough so that no points cross each other
//   when the offset is computed, because that results in invalid geometry and rendering errors.
//   Rendering errors may not manifest until you add other objects to your model.  
//   **It is your responsibility to avoid invalid geometry!**
//   .
//   Once the offsets to the original VNFs are computed, they are connected by filling
//   in the boundary strips between them.
//   .
//   A negative offset value extends the surface toward its "inside", which is the side that appears purple
//   in the "thrown together" view. Extending only toward the inside with a delta of `[0,-value]` or
//   `[-value,0]` (the order doesn't matter) means that your original VNF remains unchanged in the output.
//   Both offset surfaces may be extended in the same direction as long as the offset values are different.
//   .
//   **The input VNF must not contain duplicate points.**  By default, vnf_sheet() calls {{vnf_merge_points()}}
//   to remove duplicate points, although this operation can be slow. If you are **certain** there are no
//   duplicate points, you can set `merge=false` to disable the automatic point merge and save time. The
//   result of running on a VNF with duplicate points is likely to be incorrect or invalid, or it may result in cryptic errors.
// Arguments:
//   vnf = vnf to process
//   delta = a 2-vector specifying two different offsets from the original VNF, in any order. Positive values offset the VNF from its "exterior" side, and negative values offset from the "interior" side.
//   ---
//   style = {{vnf_vertex_array()}} style to use.  Default: "default"
//   merge = If false, then do not run {{vnf_merge_points()}}.  Default: true
// Example(3D,VPD=350,VPR=[60,0,40],VPT=[0,107,15]): In this example, the top of the surface is "interior", so a negative thickness extends that side upward, preserving the "exterior" side of the surface at the bottom.
//   pts = [
//       for(x=[30:5:180]) [
//           for(y=[-6:0.5:6])
//               [7*y,x, sin(x)*y^2]
//       ]
//   ];
//   vnf=vnf_vertex_array(pts);
//   vnf_polyhedron(vnf_sheet(vnf,[-10,0]));
// Example(3D,ThrownTogether=true,VPD=350,VPR=[60,0,40],VPT=[0,107,15]): Same as previous example, but with both sides offset equally. The offset order doesn't matter. The output is shown transparent with the original surface inside. We can also set `merge=false` if we know our original VNF has no duplicate points.
//   pts = [
//       for(x=[30:5:180]) [
//           for(y=[-6:0.5:6])
//               [7*y,x, sin(x)*y^2]
//       ]
//   ];
//   vnf=vnf_vertex_array(pts, reverse=true);
//   vnf_polyhedron(vnf);
//   %vnf_polyhedron(vnf_sheet(vnf, [-6,6],
//       merge=false));
// Example(3D): This example has multiple holes.
//   pts = [
//       for(x=[-10:2:10]) [
//           for(y=[-10:2:10])
//               [x,1.4*y,(-abs(x)^3+y^3)/250]
//       ]
//   ];
//   vnf = vnf_vertex_array(pts);
//   newface = list_remove(vnf[1],
//       [43,42,63,88,108,109,135,
//       134,129,155,156,164,165]);
//   newvnf = [vnf[0],newface];
//   vnf_polyhedron(vnf_sheet(newvnf,[2,0]));
// Example(3D,VPD=320): When only a negative offset is applied to a sphere, the sheet is constructed inward, so the object appears unchanged, but cutting it in half reveals that we have changed the sphere into a shell.  
//   vnf = sphere(d=100, $fn=28);
//   left_half()
//     vnf_polyhedron(vnf_sheet(vnf,[0,-15]));

function vnf_sheet(vnf, delta, style="default", merge=true, thickness=undef) =
  assert(is_num(delta) || is_vector(delta,2,zero=false), "\ndelta must be a 2-vector designating two different offset distances.")
  let(
       dumwarn = is_def(thickness) || is_num(delta) ? echo("\nThe 'thickness' parameter is deprecated and has been replaced by 'delta'. Use the range [0,-thickness] or [-thickness,0] to reproduce the former behavior.") : 0,
       del = is_def(thickness) ? [0,-thickness] : is_num(delta) ? [0,-delta] : delta,
       vnf = merge ? vnf_merge_points(vnf) : vnf,
       offset0 = vnf_small_offset(vnf, del[0], merge=false),
       offset1 = vnf_small_offset(vnf, del[1], merge=false),
       boundary = vnf_boundary(offset0,merge=false,idx=true),
       newvnf = vnf_join([
            offset0,
            vnf_reverse_faces(offset1),
            for(p=boundary)
                vnf_vertex_array([select(offset1[0],p),select(offset0[0],p)],col_wrap=true,style=style)
        ])
  )
  del[0]<del[1] ? vnf_reverse_faces(newvnf) : newvnf;



// Section: Debugging Polyhedrons

/// Internal Module: _show_vertices()
/// Usage:
///   _show_vertices(vertices, [size], [filter=])
/// Description:
///   Draws all the vertices in an array, at their 3D position, numbered by their
///   position in the vertex array.  Also draws any children of this module with
///   transparency.
/// Arguments:
///   vertices = Array of point vertices.
///   size = The size of the text used to label the vertices.  Default: 1
/// Example:
///   verts = [for (z=[-10,10], y=[-10,10], x=[-10,10]) [x,y,z]];
///   faces = [[0,1,2], [1,3,2], [0,4,5], [0,5,1], [1,5,7], [1,7,3], [3,7,6], [3,6,2], [2,6,4], [2,4,0], [4,6,7], [4,7,5]];
///   _show_vertices(vertices=verts, size=2) {
///       polyhedron(points=verts, faces=faces);
///   }
module _show_vertices(vertices, size=1, filter) {
    color("blue") {
        dups = vector_search(vertices, EPSILON, vertices);
        for (ind = dups) {
            if (is_undef(filter) || any(ind, filter)) {
                numstr = str_join([for(i=ind) str(i)],",");
                v = vertices[ind[0]];
                translate(v) {
                    rot($vpr) back(size/8){
                       linear_extrude(height=size/10, center=true, convexity=10) {
                          text(text=numstr, size=size, halign="center");
                       }
                    }
                    sphere(size/10);
                }
            }
        }
    }
}


/// Internal Module: _show_faces()
/// Usage:
///   _show_faces(vertices, faces, [size=], [filter=]);
/// Description:
///   Draws all the vertices at their 3D position, numbered in blue by their
///   position in the vertex array. Each face has its face number drawn
///   in red, aligned with the center of the face.  All children of this module are drawn
///   with transparency.
/// Arguments:
///   vertices = Array of point vertices.
///   faces = Array of faces by vertex numbers.
///   size = The size of the text used to label the faces and vertices.  Default: 1
/// Example(EdgesMed):
///   verts = [for (z=[-10,10], y=[-10,10], x=[-10,10]) [x,y,z]];
///   faces = [[0,1,2], [1,3,2], [0,4,5], [0,5,1], [1,5,7], [1,7,3], [3,7,6], [3,6,2], [2,6,4], [2,4,0], [4,6,7], [4,7,5]];
///   _show_faces(vertices=verts, faces=faces, size=2) {
///       polyhedron(points=verts, faces=faces);
///   }
module _show_faces(vertices, faces, size=1, filter) {
    vlen = len(vertices);
    color("red") {
        for (i = [0:1:len(faces)-1]) {
            face = faces[i];
            if (face[0] < 0 || face[1] < 0 || face[2] < 0 || face[0] >= vlen || face[1] >= vlen || face[2] >= vlen) {
                echo(str("INVALID FACE: indices of face ",i," are out of bounds [0,",vlen-1,"]: face=",face));
            }
            else if (is_undef(filter) || any(face,filter)) {
                verts = select(vertices,face);
                normal = polygon_normal(verts);
                if (is_undef(normal))
                    echo(str("DEGENERATE FACE: face ",i," has no normal vector, face=", face));
                else {
                    axis = vector_axis(normal, DOWN);
                    ang = vector_angle(normal, DOWN);
                    theta = atan2(normal[1], normal[0]);
                    translate(mean(verts)) 
                      rotate(a=(180-ang), v=axis)
                      zrot(theta+90)
                      linear_extrude(height=size/10, center=true, convexity=10) {
                                text(text=str(i), size=size, halign="center");
                                text(text=str("_"), size=size, halign="center");
                      }
                }
            }
        }
    }        
}



// Module: debug_vnf()
// Synopsis: A replacement for `vnf_polyhedron()` to help with debugging.
// SynTags: VNF
// Topics: VNF Manipulation, Debugging
// See Also: vnf_validate()
// Usage:
//   debug_vnf(vnfs, [faces=], [vertices=], [opacity=], [size=], [convexity=], [filter=]);
// Description:
//   A drop-in module to replace `vnf_polyhedron()` to help debug vertices and faces.
//   Draws all the vertices at their 3D position, numbered in blue by their
//   position in the vertex array. Each face has its face number drawn
//   in red, aligned with the center of the face. All given faces are drawn with
//   transparency. All children of this module are drawn with transparency.
//   Works best with Thrown-Together preview mode, to see reversed faces.
//   You can set opacity to 0 if you want to supress the display of the polyhedron faces.
//   .
//   The vertex numbers are shown rotated to face you.  As you rotate your polyhedron you
//   can rerun the preview to display them oriented for viewing from a different viewpoint.
// Topics: Polyhedra, Debugging
// Arguments:
//   vnf = VNF to display
//   ---
//   faces = if true display face numbers.  Default: true
//   vertices = if true display vertex numbers.  Default: true
//   opacity = Opacity of the polyhedron faces.  Default: 0.5
//   convexity = The max number of walls a ray can pass through the given polygon paths.
//   size = The size of the text used to label the faces and vertices.  Default: 1
//   filter = If given a function literal of signature `function(i)`, shows only labels for vertices and faces that have a vertex index that gets a true result from that function.  Default: no filter.
// Example(EdgesMed):
//   verts = [for (z=[-10,10], a=[0:120:359.9]) [10*cos(a),10*sin(a),z]];
//   faces = [[0,1,2], [5,4,3], [0,3,4], [0,4,1], [1,4,5], [1,5,2], [2,5,3], [2,3,0]];
//   debug_vnf([verts,faces], size=2);
module debug_vnf(vnf, faces=true, vertices=true, opacity=0.5, size=1, convexity=6, filter ) {
    no_children($children);
    if (faces)
      _show_faces(vertices=vnf[0], faces=vnf[1], size=size, filter=filter);
    if (vertices)
      _show_vertices(vertices=vnf[0], size=size, filter=filter);
    if (opacity > 0)
      color([0.2, 1.0, 0, opacity])
        vnf_polyhedron(vnf,convexity=convexity);
}


// Module: vnf_validate()
// Synopsis: Echos non-manifold VNF errors to the console.
// SynTags: VNF
// Topics: VNF Manipulation, Debugging
// See Also: debug_vnf()
// 
// Usage: 
//   vnf_validate(vnf, [size], [show_warns=], [check_isects=], [opacity=], [adjacent=], [label_verts=], [label_faces=], [wireframe=]);
// Description:
//   When called as a module, echoes the non-manifold errors to the console, and color hilites the
//   bad edges and vertices, overlaid on a transparent gray polyhedron of the VNF.
//   .
//   Currently checks for these problems:
//   .
//   Type    | Color    | Code         | Message
//   ------- | -------- | ------------ | ---------------------------------
//   WARNING | Yellow   | BIG_FACE     | Face has more than 3 vertices, and may confuse CGAL.
//   WARNING | Blue     | NULL_FACE    | Face has zero area.
//   ERROR   | Cyan     | NONPLANAR    | Face vertices are not coplanar.
//   ERROR   | Brown    | DUP_FACE     | Multiple instances of the same face.
//   ERROR   | Orange   | MULTCONN     | Multiply Connected Geometry. Too many faces attached at Edge.
//   ERROR   | Violet   | REVERSAL     | Faces reverse across edge.
//   ERROR   | Red      | T_JUNCTION   | Vertex is mid-edge on another Face.
//   ERROR   | Brown    | FACE_ISECT   | Faces intersect.
//   ERROR   | Magenta  | HOLE_EDGE    | Edge bounds Hole.
//   .
//   Still to implement:
//   - Overlapping coplanar faces.
// Arguments:
//   vnf = The VNF to validate.
//   size = The width of the lines and diameter of points used to highlight edges and vertices.  Module only.  Default: 1
//   ---
//   show_warns = If true show warnings for non-triangular faces.  Default: true
//   check_isects = If true, performs slow checks for intersecting faces.  Default: false
//   opacity = The opacity level to show the polyhedron itself with.    Default: 0.67
//   label_verts = If true, shows labels at each vertex that show the vertex number.    Default: false
//   label_faces = If true, shows labels at the center of each face that show the face number.    Default: false
//   wireframe = If true, shows edges more clearly so you can see them in Thrown Together mode.    Default: false
//   adjacent = If true, display only faces that are adjacent to a vertex listed in the errors.    Default: false
// Example(3D,Edges): BIG_FACE Warnings; Faces with More Than 3 Vertices. CGAL often fails to accept that a face is planar after a rotation, if it has more than 3 vertices.
//   vnf = skin([
//       path3d(regular_ngon(n=3, d=100),0),
//       path3d(regular_ngon(n=5, d=100),100)
//   ], slices=0, caps=true, method="tangent");
//   vnf_validate(vnf);
// Example(3D,Edges): NONPLANAR Errors; Face Vertices are Not Coplanar
//   a = [  0,  0,-50];
//   b = [-50,-50, 50];
//   c = [-50, 50, 50];
//   d = [ 50, 50, 60];
//   e = [ 50,-50, 50];
//   vnf = vnf_from_polygons([
//       [a, b, e], [a, c, b], [a, d, c], [a, e, d], [b, c, d, e]
//   ],fast=true);
//   vnf_validate(vnf);
// Example(3D,Edges): MULTCONN Errors; More Than Two Faces Attached to the Same Edge.  This confuses CGAL, and can lead to failed renders.
//   vnf = vnf_triangulate(linear_sweep(union(square(50), square(50,anchor=BACK+RIGHT)), height=50));
//   vnf_validate(vnf);
// Example(3D,Edges): REVERSAL Errors; Faces Reversed Across Edge
//   vnf1 = skin([
//       path3d(square(100,center=true),0),
//       path3d(square(100,center=true),100),
//   ], slices=0, caps=false);
//   vnf = vnf_join([vnf1, vnf_from_polygons([
//       [[-50,-50,  0], [ 50, 50,  0], [-50, 50,  0]],
//       [[-50,-50,  0], [ 50,-50,  0], [ 50, 50,  0]],
//       [[-50,-50,100], [-50, 50,100], [ 50, 50,100]],
//       [[-50,-50,100], [ 50,-50,100], [ 50, 50,100]],
//   ])]);
//   vnf_validate(vnf);
// Example(3D,Edges): T_JUNCTION Errors; Vertex is Mid-Edge on Another Face.
//   vnf = [
//       [
//           each path3d(square(100,center=true),0),
//           each path3d(square(100,center=true),100),
//           [0,-50,100],
//       ], [
//          [0,2,1], [0,3,2], [0,8,4], [0,1,8], [1,5,8],
//          [0,4,3], [4,7,3], [1,2,5], [2,6,5], [3,7,6],
//          [3,6,2], [4,5,6], [4,6,7],
//       ]
//   ];
//   vnf_validate(vnf);
// Example(3D,Edges): FACE_ISECT Errors; Faces Intersect
//   vnf = vnf_join([
//       linear_sweep(square(100,center=true), height=100),
//       move([75,35,30],p=linear_sweep(square(100,center=true), height=100))
//   ]);
//   vnf_validate(vnf,size=2,check_isects=true);
// Example(3D,Edges): HOLE_EDGE Errors; Edges Adjacent to Holes.
//   vnf = skin([
//       path3d(regular_ngon(n=4, d=100),0),
//       path3d(regular_ngon(n=5, d=100),100)
//   ], slices=0, caps=false);
//   vnf_validate(vnf,size=2);


//   Returns a list of non-manifold errors with the given VNF.
//   Each error has the format `[ERR_OR_WARN,CODE,MESG,POINTS,COLOR]`.
function _vnf_validate(vnf, show_warns=true, check_isects=false) =
    assert(is_vnf(vnf), "\nInvalid VNF.")
    let(
        varr = vnf[0],
        faces = vnf[1],
        lvarr = len(varr),
        edges = sort([
            for (face=faces, edge=pair(face,true))
            edge[0]<edge[1]? edge : [edge[1],edge[0]]
        ]),
        dfaces = [
            for (face=faces) let(
                face=deduplicate_indexed(varr,face,closed=true)
            ) if(len(face)>=3)
            face
        ],
        face_areas = [
            for (face = faces)
            len(face) < 3? 0 :
            polygon_area([for (k=face) varr[k]])
        ],
        edgecnts = unique_count(edges),
        uniq_edges = edgecnts[0],
        issues = []
    )
    let(
        big_faces = !show_warns? [] : [
            for (face = faces)
            if (len(face) > 3)
            _vnf_validate_err("BIG_FACE", face)
        ],
        null_faces = !show_warns? [] : [
            for (i = idx(faces)) let(
                face = faces[i],
                area = face_areas[i]
            )
            if (is_num(area) && abs(area) < EPSILON)
            _vnf_validate_err("NULL_FACE", face)
        ],
        issues = concat(big_faces, null_faces)
    )
    let(
        bad_indices = [
            for (face = faces, idx = face)
            if (idx < 0 || idx >= lvarr)
            _vnf_validate_err("BAD_INDEX", [idx])
        ],
        issues = concat(issues, bad_indices)
    ) bad_indices? issues :
    let(
        repeated_faces = [
            for (i=idx(dfaces), j=idx(dfaces))
            if (i!=j) let(
                face1 = dfaces[i],
                face2 = dfaces[j]
            ) if (min(face1) == min(face2)) let(
                min1 = min_index(face1),
                min2 = min_index(face2)
            ) if (min1 == min2) let(
                sface1 = list_rotate(face1,min1),
                sface2 = list_rotate(face2,min2)
            ) if (sface1 == sface2)
            _vnf_validate_err("DUP_FACE", sface1)
        ],
        issues = concat(issues, repeated_faces)
    ) repeated_faces? issues :
    let(
        multconn_edges = unique([
            for (i = idx(uniq_edges))
            if (edgecnts[1][i]>2)
            _vnf_validate_err("MULTCONN", uniq_edges[i])
        ]),
        issues = concat(issues, multconn_edges)
    ) multconn_edges? issues :
    let(
        reversals = unique([
            for(i = idx(dfaces), j = idx(dfaces)) if(i != j)
            for(edge1 = pair(faces[i],true))
            for(edge2 = pair(faces[j],true))
            if(edge1 == edge2)  // Valid adjacent faces must never have the same vertex ordering.
            if(_edge_not_reported(edge1, varr, multconn_edges))
            _vnf_validate_err("REVERSAL", edge1)
        ]),
        issues = concat(issues, reversals)
    ) reversals? issues :
    let(
        t_juncts = unique([
            for (v=idx(varr), edge=uniq_edges) let(
                ia = edge[0],
                ib = v,
                ic = edge[1]
            )
            if (ia!=ib && ib!=ic && ia!=ic) let(
                a = varr[ia],
                b = varr[ib],
                c = varr[ic]
            )
            if (!approx(a,b) && !approx(b,c) && !approx(a,c)) let(
                pt = line_closest_point([a,c],b,SEGMENT)
            )
            if (approx(pt,b))
            _vnf_validate_err("T_JUNCTION", [ib])
        ]),
        issues = concat(issues, t_juncts)
    ) t_juncts? issues :
    let(
        isect_faces = !check_isects? [] : unique([
            for (i = [0:1:len(faces)-2])
              let(
                  f1 = faces[i],
                  poly1   = select(varr, faces[i]),
                  plane1  = plane3pt(poly1[0], poly1[1], poly1[2]),
                  normal1 = [plane1[0], plane1[1], plane1[2]]
              )
              for (j = [i+1:1:len(faces)-1])
                let(
                  f2 = faces[j],
                  poly2 = select(varr, f2),
                  val = poly2 * normal1
                )
                // The next test skips f2 if it lies entirely on one side of the plane of poly1
                if( min(val)<=plane1[3] && max(val)>=plane1[3] )
                  let(
                      plane2  = plane_from_polygon(poly2),
                      normal2 = [plane2[0], plane2[1], plane2[2]],
                      val = poly1 * normal2
                  )
                  // Skip if f1 lies entirely on one side of the plane defined by poly2
                  if( min(val)<=plane2[3] && max(val)>=plane2[3] )
                    let(
                        shared_edges = [
                                        for (edge1 = pair(f1, true), edge2 = pair(f2, true))
                                           if (edge1 == [edge2[1], edge2[0]]) 1
                                       ]
                    )
                    if (shared_edges==[])
                       let(
                           line = plane_intersection(plane1, plane2)
                       )
                       if (is_def(line))
                          let(
                              isects = polygon_line_intersection(poly1, line)
                          )
                          if (is_def(isects))
                            for (isect = isects)
                              if (len(isect) > 1)
                                let(
                                    isects2 = polygon_line_intersection(poly2, isect, bounded=true)
                                )
                                if (is_def(isects2))
                                  for (seg = isects2) 
                                    if (len(seg)>1 && seg[0] != seg[1]) _vnf_validate_err("FACE_ISECT", seg)
        ]),
        issues = concat(issues, isect_faces)
    ) isect_faces? issues :
    let(
        hole_edges = unique([
            for (i=idx(uniq_edges))
            if (edgecnts[1][i]<2)
            if (_pts_not_reported(uniq_edges[i], varr, t_juncts))
            if (_pts_not_reported(uniq_edges[i], varr, isect_faces))
            _vnf_validate_err("HOLE_EDGE", uniq_edges[i])
        ]),
        issues = concat(issues, hole_edges)
    ) hole_edges? issues :
    let(
        nonplanars = unique([
            for (i = idx(faces))
               if (is_undef(face_areas[i])) 
                  _vnf_validate_err("NONPLANAR", faces[i])
        ]),
        issues = concat(issues, nonplanars)
    ) issues;


_vnf_validate_errs = [
    ["BIG_FACE",    "WARNING", "cyan",    "Face has more than 3 vertices, and may confuse CGAL"],
    ["NULL_FACE",   "WARNING", "blue",    "Face has zero area."],
    ["BAD_INDEX",   "ERROR",   "cyan",    "Invalid face vertex index."],
    ["NONPLANAR",   "ERROR",   "yellow",  "Face vertices are not coplanar"],
    ["DUP_FACE",    "ERROR",   "brown",   "Multiple instances of the same face."],
    ["MULTCONN",    "ERROR",   "orange",  "Multiply Connected Geometry. Too many faces attached at Edge"],
    ["REVERSAL",    "ERROR",   "violet",  "Faces Reverse Across Edge"],
    ["T_JUNCTION",  "ERROR",   "magenta", "Vertex is mid-edge on another Face"],
    ["FACE_ISECT",  "ERROR",   "brown",   "Faces intersect"],
    ["HOLE_EDGE",   "ERROR",   "red",     "Edge bounds Hole"]
];


function _vnf_validate_err(name, extra) =
    let(
        info = [for (x = _vnf_validate_errs) if (x[0] == name) x][0]
    ) concat(info, [extra]);


function _pts_not_reported(pts, varr, reports) =
    [
        for (i = pts, report = reports, pt = report[3])
        if (varr[i] == pt) 1
    ] == [];


function _edge_not_reported(edge, varr, reports) =
    let(
        edge = sort([for (i=edge) varr[i]])
    ) [
        for (report = reports) let(
            pts = sort(report[3])
        ) if (len(pts)==2 && edge == pts) 1
    ] == [];


module vnf_validate(vnf, size=1, show_warns=true, check_isects=false, opacity=0.67, adjacent=false, label_verts=false, label_faces=false, wireframe=false) {
    no_children($children);
    vcount = len(vnf[0]);
    fcount = len(vnf[1]);
    vnf = vnf_merge_points(vnf);
    faults = _vnf_validate(
        vnf, show_warns=show_warns,
        check_isects=check_isects
    );
    verts = vnf[0];
    vnf_changed = len(verts)!=vcount || len(vnf[1])!=fcount;
    if (!faults) {
        echo("VNF appears valid.");
    }
    if (vnf_changed) echo("VNF changed when merging points; unable to display indices");
    for (fault = faults) {
        err = fault[0];
        typ = fault[1];
        clr = fault[2];
        msg = fault[3];
        idxs = fault[4];
        pts = err=="FACE_ISECT" ? idxs : [for (i=idxs) if(is_finite(i) && i>=0 && i<len(verts)) verts[i]];
        if (vnf_changed || err=="FACE_ISECT")
          echo(str(typ, " ", err, " (", clr ,"): ", msg, " at ", pts));
        else
          echo(str(typ, " ", err, " (", clr ,"): ", msg, " at ", pts, " indices: ", idxs));
        color(clr) {
            if (is_vector(pts[0])) {
                if (len(pts)==2) {
                    stroke(pts, width=size, endcaps="butt", $fn=8);
                } else if (len(pts)>2) {
                    stroke(pts, width=size, closed=true, $fn=8);
                    polyhedron(pts,[[for (i=idx(pts)) i]]);
                } else {
                    move_copies(pts) sphere(d=size*3, $fn=18);
                }
            }
        }
    }
    badverts = unique([for (fault=faults) each fault[4]]);
    badverts2 = unique([for (j=idx(verts), i=badverts) if (i!=j && verts[i]==verts[j]) j]);
    all_badverts = unique(concat(badverts, badverts2));
    adjacent = !faults? false : adjacent;
    filter_fn = !adjacent? undef : function(i) in_list(i,all_badverts);
    adj_vnf = !adjacent? vnf : [
        verts, [for (face=vnf[1]) if (any(face,filter_fn)) face]
    ];
    if (wireframe) {
        vnf_wireframe(adj_vnf, width=size*0.25);
    }
    if (label_verts) {
        debug_vnf(adj_vnf, size=size*3, opacity=0, faces=false, vertices=true, filter=filter_fn);
    }
    if (label_faces) {
        debug_vnf(vnf, size=size*3, opacity=0, faces=true, vertices=false, filter=filter_fn);
    }
    if (opacity > 0) {
        color([0.5,1,0.5,opacity]) vnf_polyhedron(adj_vnf);
    }
}


// Given a single edge (pair of vertex indices) or list of them, find faces
// that contain that edge.  You must not supply two edges that could appear in
// the same face.  The use-case for more than one edge is when a single geometric edge
// has multiple representations in the VNF.  Return is a pair of face indices.

function _vnf_find_edge_faces(vnf,edge) =
  let(
      edge = unique(flatten(edge)),
      faces = vnf[1],
      goodind = [for(i=idx(faces))
                    let(result=flatten(search(edge,faces[i])))
                    if (result*0==[0,0] && 
                          (abs(result[0]-result[1])==1
                           || (min(result)==0 && max(result)==len(faces[i])-1)))
                       i
                ]
  )
  unique(goodind);



// Given a VNF and an index list of vertices, return all the
// faces (as indices into the face array) which include an item
// from the corner list.  The idea is that corner will hold all
// the indices that correspond to a single geometric point in
// the VNF and return just the faces for that single corner.  

function _vnf_find_corner_faces(vnf,corner) =
  let(
      faces = vnf[1],
      corner = force_list(corner),
      nomatch = repeat([],len(corner))
  )
  unique([for(i=idx(faces))
     if (search(corner,faces[i])!=nomatch) i]);



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
