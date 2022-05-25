//////////////////////////////////////////////////////////////////////
// LibFile: vnf.scad
//   The Vertices'N'Faces structure (VNF) holds the data used by polyhedron() to construct objects: a vertex
//   list and a list of faces.  This library makes it easier to construct polyhedra by providing
//   functions to construct, merge, and modify VNF data, while avoiding common pitfalls such as
//   reversed faces.  It can find faults in your polyhedrons.  Note that this file is for low level manipulation
//   of lists of vertices and faces: it can perform some simple transformations on VNF structures
//   but cannot perform boolean operations on the polyhedrons represented by VNFs.
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


// Function: vnf_vertex_array()
// Usage:
//   vnf = vnf_vertex_array(points, [caps=], [cap1=], [cap2=], [style=], [reverse=], [col_wrap=], [row_wrap=]);
// Description:
//   Creates a VNF structure from a rectangular vertex list, by dividing the vertices into columns and rows,
//   adding faces to tile the surface.  You can optionally have faces added to wrap the last column
//   back to the first column, or wrap the last row to the first.  Endcaps can be added to either
//   the first and/or last rows.  The style parameter determines how the quadrilaterals are divided into
//   triangles.  The default style is an arbitrary, systematic subdivision in the same direction.  The "alt" style
//   is the uniform subdivision in the other (alternate) direction.  The "min_edge" style picks the shorter edge to
//   subdivide for each quadrilateral, so the division may not be uniform across the shape.  The "quincunx" style
//   adds a vertex in the center of each quadrilateral and creates four triangles, and the "convex" and "concave" styles
//   chooses the locally convex/concave subdivision.  Degenerate faces
//   are not included in the output, but if this results in unused vertices they will still appear in the output.  
// Arguments:
//   points = A list of vertices to divide into columns and rows.
//   ---
//   caps = If true, add endcap faces to the first AND last rows.
//   cap1 = If true, add an endcap face to the first row.
//   cap2 = If true, add an endcap face to the last row.
//   col_wrap = If true, add faces to connect the last column to the first.
//   row_wrap = If true, add faces to connect the last row to the first.
//   reverse = If true, reverse all face normals.
//   style = The style of subdividing the quads into faces.  Valid options are "default", "alt", "min_edge", "quincunx", "convex" and "concave".
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
function vnf_vertex_array(
    points,
    caps, cap1, cap2,
    col_wrap=false,
    row_wrap=false,
    reverse=false,
    style="default"
) = 
    assert(!(any([caps,cap1,cap2]) && !col_wrap), "col_wrap must be true if caps are requested")
    assert(!(any([caps,cap1,cap2]) && row_wrap), "Cannot combine caps with row_wrap")
    assert(in_list(style,["default","alt","quincunx", "convex","concave", "min_edge"]))
    assert(is_matrix(points[0], n=3),"Point array has the wrong shape or points are not 3d")
    assert(is_consistent(points), "Non-rectangular or invalid point array")
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
                      : style=="alt"? 
                          [[i1,i4,i2],[i2,i4,i3]]
                      : style=="min_edge"?
                          let(
                               d42=norm(pts[i4]-pts[i2]),
                               d13=norm(pts[i1]-pts[i3]),
                               shortedge = d42<d13+EPSILON ? [[i1,i4,i2],[i2,i4,i3]]
                                                    : [[i1,i3,i2],[i1,i4,i3]]
                          )
                          shortedge
                      : style=="convex"?  
                          let(   // Find normal for 3 of the points.  Is the other point above or below?
                              n = (reverse?-1:1)*cross(pts[i2]-pts[i1],pts[i3]-pts[i1]),
                              convexfaces = n==0 ? [[i1,i4,i3]]
                                          : n*pts[i4] > n*pts[i1] ? [[i1,i4,i2],[i2,i4,i3]]
                                                                  : [[i1,i3,i2],[i1,i4,i3]]
                          )
                          convexfaces
                      : style=="concave"?  
                          let(   // Find normal for 3 of the points.  Is the other point above or below?
                              n = (reverse?-1:1)*cross(pts[i2]-pts[i1],pts[i3]-pts[i1]),
                              concavefaces = n==0 ? [[i1,i4,i3]]
                                          : n*pts[i4] <= n*pts[i1] ? [[i1,i4,i2],[i2,i4,i3]]
                                                                  : [[i1,i3,i2],[i1,i4,i3]]
                          )
                          concavefaces
                      : [[i1,i3,i2],[i1,i4,i3]],
                   // remove degenerate faces 
                   culled_faces= [for(face=faces)
                       if (norm(verts[face[0]]-verts[face[1]])>EPSILON &&
                           norm(verts[face[1]]-verts[face[2]])>EPSILON && 
                           norm(verts[face[2]]-verts[face[0]])>EPSILON) 
                           face
                   ],
                   rfaces = reverse? [for (face=culled_faces) reverse(face)] : culled_faces
               )
               rfaces,
        ]
    )
    [verts,allfaces];


// Function: vnf_tri_array()
// Usage:
//   vnf = vnf_tri_array(points, [row_wrap], [reverse])
// Description:
//   Produces a vnf from an array of points where each row length can differ from the adjacent rows by up to 2 in length.  This enables
//   the construction of triangular VNF patches.  The resulting VNF can be wrapped along the rows by setting `row_wrap` to true.
//   You cannot wrap columns: if you need to do that you'll need to merge two VNF arrays that share edges.  Degenerate faces
//   are not included in the output, but if this results in unused vertices they will still appear in the output.  
// Arguments:
//   points = List of point lists for each row
//   row_wrap = If true then add faces connecting the first row and last row.  These rows must differ by at most 2 in length.
//   reverse = Set this to reverse the direction of the faces
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
// Example(3D,NoAxes): Point count can change irregularly
//   lens = [10,9,7,5,6,8,8,10];
//   pts = [for(y=idx(lens)) lerpn([-lens[y],y,y],[lens[y],y,y],lens[y])];
//   vnf = vnf_tri_array(pts);
//   vnf_wireframe(vnf,width=0.1);
//   color("red")move_copies(flatten(pts)) sphere(r=.15,$fn=9);
function vnf_tri_array(points, row_wrap=false, reverse=false) = 
    let(
       lens = [for(row=points) len(row)],
       rowstarts = [0,each cumsum(lens)],
       faces =
          [for(i=[0:1:len(points) - 1 - (row_wrap ? 0 : 1)]) each
            let(
                rowstart = rowstarts[i],
                nextrow = select(rowstarts,i+1),
                delta = select(lens,i+1)-lens[i]
            )
            delta == 0 ?
              [for(j=[0:1:lens[i]-2]) reverse ? [j+rowstart+1, j+rowstart, j+nextrow] : [j+rowstart, j+rowstart+1, j+nextrow],
               for(j=[0:1:lens[i]-2]) reverse ? [j+rowstart+1, j+nextrow, j+nextrow+1] : [j+rowstart+1, j+nextrow+1, j+nextrow]] :
            delta == 1 ?
              [for(j=[0:1:lens[i]-2]) reverse ? [j+rowstart+1, j+rowstart, j+nextrow+1] : [j+rowstart, j+rowstart+1, j+nextrow+1],
               for(j=[0:1:lens[i]-1]) reverse ? [j+rowstart, j+nextrow, j+nextrow+1] : [j+rowstart, j+nextrow+1, j+nextrow]] :
            delta == -1 ?
              [for(j=[0:1:lens[i]-3]) reverse ? [j+rowstart+1, j+nextrow, j+nextrow+1]: [j+rowstart+1, j+nextrow+1, j+nextrow],
               for(j=[0:1:lens[i]-2]) reverse ? [j+rowstart+1, j+rowstart, j+nextrow] : [j+rowstart, j+rowstart+1, j+nextrow]] :
            let(count = floor((lens[i]-1)/2))
            delta == 2 ?
              [
               for(j=[0:1:count-1]) reverse ? [j+rowstart+1, j+rowstart, j+nextrow+1] : [j+rowstart, j+rowstart+1, j+nextrow+1],       // top triangles left
               for(j=[count:1:lens[i]-2]) reverse ? [j+rowstart+1, j+rowstart, j+nextrow+2] : [j+rowstart, j+rowstart+1, j+nextrow+2], // top triangles right
               for(j=[0:1:count]) reverse ? [j+rowstart, j+nextrow, j+nextrow+1] : [j+rowstart, j+nextrow+1, j+nextrow],                        // bot triangles left
               for(j=[count+1:1:select(lens,i+1)-2]) reverse ? [j+rowstart-1, j+nextrow, j+nextrow+1] : [j+rowstart-1, j+nextrow+1, j+nextrow], // bot triangles right
              ] :
            delta == -2 ?
              [
               for(j=[0:1:count-2]) reverse ? [j+nextrow, j+nextrow+1, j+rowstart+1] : [j+nextrow, j+rowstart+1, j+nextrow+1],
               for(j=[count-1:1:lens[i]-4]) reverse ? [j+nextrow,j+nextrow+1,j+rowstart+2] : [j+nextrow,j+rowstart+2, j+nextrow+1],
               for(j=[0:1:count-1]) reverse ? [j+nextrow, j+rowstart+1, j+rowstart] : [j+nextrow, j+rowstart, j+rowstart+1],
               for(j=[count:1:select(lens,i+1)]) reverse ? [ j+nextrow-1, j+rowstart+1, j+rowstart]: [ j+nextrow-1, j+rowstart, j+rowstart+1],
              ] :
            assert(false,str("Unsupported row length difference of ",delta, " between row ",i," and ",(i+1)%len(points)))
          ],
       verts = flatten(points),
       culled_faces=
           [for(face=faces)
               if (norm(verts[face[0]]-verts[face[1]])>EPSILON &&
                   norm(verts[face[1]]-verts[face[2]])>EPSILON && 
                   norm(verts[face[2]]-verts[face[0]])>EPSILON) 
                   face
           ]
    )
    [flatten(points), culled_faces];



// Function: vnf_join()
// Usage:
//   vnf = vnf_join([VNF, VNF, VNF, ...]);
// Description:
//   Given a list of VNF structures, merges them all into a single VNF structure.
//   Combines all the points of the input VNFs and labels the faces appropriately.
//   All the points in the input VNFs will appear in the output, even if they are
//   duplicates of each other.  It is valid to repeat points in a VNF, but if you
//   with to remove the duplicates that will occur along joined edges, use {{vnf_merge_points()}}.
//   .
//   Note that this is a tool for manipulating polyhedron data.  It is for
//   building up a full polyhedron from partial polyhedra.
//   It is *not* a union operator for VNFs.  The VNFs to be joined must not intersect each other, 
//   except at edges, or the result will be an invalid polyhedron.  Similarly the
//   result must not have any other illegal polyhedron characteristics, such as creating
//   more than two faces sharing the same edge.  
//   If you want a valid result it is your responsibility to ensure that the polyhedron
//   has no holes, no intersecting faces or edges, and obeys all the requirements
//   that CGAL expects. 
//   .
//   For example, if you combine two pyramids to try to make an octahedron, the result will
//   be invalid because of the two internal faces created by the pyramid bases.  A valid
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
// Example(3D): The vnf_join function is not a union operator for polyhedra.  If any faces intersect, like they do in this example where we combine the faces of two cubes, the result is invalid and will give rise to CGAL errors when you add more objects into the model.  
//   cube1 = cube(5);
//   cube2 = move([2,2,2],cube1);
//   badvnf = vnf_join([cube1,cube2]);
//   vnf_polyhedron(badvnf);
//   right(2.5)up(3)color("red")
//         text3d("Invalid",size=1,anchor=CENTER,
//         orient=FRONT,h=.1);
function vnf_join(vnfs) = 
    assert(is_vnf_list(vnfs) , "Input must be a list of VNFs")
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
                                    str("VNF number ", i, " has a face indexing an nonexistent vertex") )
                            offs[i] + j ]
            ]
    )
    [verts,faces];



// Function: vnf_from_polygons()
// Usage:
//   vnf = vnf_from_polygons(polygons);
// Description:
//   Given a list of 3d polygons, produces a VNF containing those polygons.  
//   It is up to the caller to make sure that the points are in the correct order to make the face
//   normals point outwards.  No checking for duplicate vertices is done.  If you want to
//   remove duplicate vertices use {{vnf_merge_points()}}.
// Arguments:
//   polygons = The list of 3d polygons to turn into a VNF
function vnf_from_polygons(polygons) =
   assert(is_list(polygons) && is_path(polygons[0]),"Input should be a list of polygons")
   let(
       offs = cumsum([0, for(p=polygons) len(p)]),
       faces = [for(i=idx(polygons))
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
// Usage:
//   vnf = vnf_from_region(region, [transform], [reverse]);
// Description:
//   Given a (two-dimensional) region, applies the given transformation matrix to it and makes a (three-dimensional) triangulated VNF of
//   faces for that region, reversed if desired. 
// Arguments:
//   region = The region to conver to a vnf.
//   transform = If given, a transformation matrix to apply to the faces generated from the region.  Default: No transformation applied.
//   reverse = If true, reverse the normals of the faces generated from the region.  An untransformed region will have face normals pointing `UP`.  Default: false
// Example(3D):
//   region = [square([20,10],center=true),
//             right(5,square(4,center=true)),
//             left(5,square(6,center=true))];
//   vnf = vnf_from_region(region);
//   color("gray")down(.125)
//        linear_extrude(height=.125)region(region);
//   vnf_wireframe(vnf,width=.25);
function vnf_from_region(region, transform, reverse=false) =
    let (
        regions = region_parts(force_region(region)),
        vnfs =
            [ for (rgn = regions) 
                let( cleaved = path3d(_cleave_connected_region(rgn)) ) 
                assert( cleaved, "The region is invalid")
                let(
                    face = is_undef(transform)? cleaved : apply(transform,cleaved),
                    faceidxs = reverse? [for (i=[len(face)-1:-1:0]) i] : [for (i=[0:1:len(face)-1]) i]
                ) [face, [faceidxs]]
            ],
        outvnf = vnf_join(vnfs)
    )
    vnf_triangulate(outvnf);



// Section: VNF Testing and Access


// Function: is_vnf()
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
// Description: Returns true if the given value looks passingly like a list of VNF structures.
function is_vnf_list(x) = is_list(x) && all([for (v=x) is_vnf(v)]);


// Function: vnf_vertices()
// Description: Given a VNF structure, returns the list of vertex points.
function vnf_vertices(vnf) = vnf[0];


// Function: vnf_faces()
// Description: Given a VNF structure, returns the list of faces, where each face is a list of indices into the VNF vertex list.
function vnf_faces(vnf) = vnf[1];



// Section: Altering the VNF Internals


// Function: vnf_reverse_faces()
// Usage:
//   rvnf = vnf_reverse_faces(vnf);
// Description:
//   Reverses the orientation of all the faces in the given VNF.
function vnf_reverse_faces(vnf) =
    [vnf[0], [for (face=vnf[1]) reverse(face)]];


// Function: vnf_quantize()
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
// Usage:
//   clean_vnf = vnf_drop_unused_points(vnf);
// Description:
//   Remove all unreferenced vertices from a VNF.  Note that in most
//   cases unreferenced vertices cause no harm, and this function may
//   be slow on large VNFs.
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
// Usage:
//   vnf2 = vnf_triangulate(vnf);
// Description:
//   Triangulates faces in the VNF that have more than 3 vertices.
// Arguments:
//   vnf = vnf to triangulate
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
                    assert( tris!=undef, "Some `vnf` face cannot be triangulated.")
                    tris ) ]
    ) 
    [verts, faces]; 



// Function: vnf_slice()
// Usage:
//   sliced = vnf_slice(vnf, dir, cuts);
// Description:
//   Slice the faces of a VNF along a specified axis direction at a given list
//   of cut points.  The cut points can appear in any order.  You can use this to refine the faces of a VNF before applying
//   a nonlinear transformation to its vertex set.
// Arguments:
//   vnf = vnf to slice
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
       vert = vnf[0],
       faces = [for(face=vnf[1]) select(vert,face)],
       poly_list = _slice_3dpolygons(faces, dir, cuts)
  )
  vnf_merge_points(vnf_from_polygons(poly_list));


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
            if (len(out1)>=3) each split_path_at_self_crossings(out1),
            if (len(out2)>=3) each split_path_at_self_crossings(out2),
        ],
        out = [for (p=out3) if (len(p) > 2) cleanup_path(p)]
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
    assert( [for (poly=polys) if (!is_path(poly,3)) 1] == [], "Expects list of 3D paths.")
    assert( is_vector(cuts), "The split list must be a vector.")
    assert( in_list(dir, ["X", "Y", "Z"]))
    let(
        I = ident(3),
        dir_ind = ord(dir)-ord("X")
    )
    flatten([for (poly = polys)
        let(
            plane = plane_from_polygon(poly)
        )
        assert(plane,"Found non-coplanar face.")
        let(
            normal = point3d(plane),
            pnormal = normal - (normal*I[dir_ind])*I[dir_ind]
        )
        approx(pnormal,[0,0,0]) ? [poly] :
        let (
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
// Usage:
//   vnf_polyhedron(vnf) [ATTACHMENTS];
//   vnf_polyhedron([VNF, VNF, VNF, ...]) [ATTACHMENTS];
// Description:
//   Given a VNF structure, or a list of VNF structures, creates a polyhedron from them.
// Arguments:
//   vnf = A VNF structure, or list of VNF structures.
//   convexity = Max number of times a line could intersect a wall of the shape.
//   extent = If true, calculate anchors by extents, rather than intersection.  Default: true.
//   cp = Centerpoint for determining intersection anchors or centering the shape.  Determintes the base of the anchor vector.  Can be "centroid", "mean", "box" or a 3D point.  Default: "centroid"
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `"origin"`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   atype = Select "hull" or "intersect" anchor type.  Default: "hull"
module vnf_polyhedron(vnf, convexity=2, extent=true, cp="centroid", anchor="origin", spin=0, orient=UP, atype="hull") {
    vnf = is_vnf_list(vnf)? vnf_join(vnf) : vnf;
    assert(in_list(atype, _ANCHOR_TYPES), "Anchor type must be \"hull\" or \"intersect\"");
    attachable(anchor,spin,orient, vnf=vnf, extent=atype=="hull", cp=cp) {
        polyhedron(vnf[0], vnf[1], convexity=convexity);
        children();
    }
}


// Module: vnf_wireframe()
// Usage:
//   vnf_wireframe(vnf, [width]);
// Description:
//   Given a VNF, creates a wire frame ball-and-stick model of the polyhedron with a cylinder for
//   each edge and a sphere at each vertex.  The width parameter specifies the width of the sticks
//   that form the wire frame and the diameter of the balls.  
// Arguments:
//   vnf = A vnf structure
//   width = width of the cylinders forming the wire frame.  Default: 1
// Example:
//   $fn=32;
//   ball = sphere(r=20, $fn=6);
//   vnf_wireframe(ball,width=1);
// Example:
//   include <BOSL2/polyhedra.scad>
//   $fn=32;
//   cube_oct = regular_polyhedron_info("vnf",
//                      name="cuboctahedron", or=20);
//   vnf_wireframe(cube_oct);
// Example: The spheres at the vertex are imperfect at aligning with the cylinders, so especially at low $fn things look prety ugly.  This is normal.
//   include <BOSL2/polyhedra.scad>
//   $fn=8;
//   octahedron = regular_polyhedron_info("vnf",
//                         name="octahedron", or=20);
//   vnf_wireframe(octahedron,width=5);
module vnf_wireframe(vnf, width=1)
{
  vertex = vnf[0];
  edges = unique([for (face=vnf[1], i=idx(face))
                    sort([face[i], select(face,i+1)])
                 ]);
  for (e=edges) extrude_from_to(vertex[e[0]],vertex[e[1]]) circle(d=width);
  // Identify vertices actually used and draw them
  vertused = search(count(len(vertex)), flatten(edges), 1);
  for(i=idx(vertex)) if(vertused[i]!=[]) move(vertex[i]) sphere(d=width); 
}


// Section: Operations on VNFs

// Function: vnf_volume()
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
    assert(is_vnf(vnf) && len(vnf[0])!=0 && len(vnf[1])!=0,"Invalid or empty VNF given to centroid") 
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
    assert(!approx(pos[0],0, eps), "The vnf has self-intersections.")
    pos[1]/pos[0]/4;


// Function: vnf_halfspace()
// Usage:
//   newvnf = vnf_halfspace(plane, vnf, [closed]);
// Description:
//   Returns the intersection of the vnf with a half space.  The half space is defined by
//   plane = [A,B,C,D], taking the side where the normal [A,B,C] points: Ax+By+Cz≥D.
//   If closed is set to false then the cut face is not included in the vnf.  This could
//   allow further extension of the vnf by merging with other vnfs.  
// Arguments:
//   plane = plane defining the boundary of the half space
//   vnf = vnf to cut
//   closed = if false do not return include cut face(s).  Default: true
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
function vnf_halfspace(plane, vnf, closed=true) =
    assert(_valid_plane(plane), "Invalid plane")
    assert(is_vnf(vnf), "Invalid vnf")
    let(
         inside = [for(x=vnf[0]) plane*[each x,-1] >= 0 ? 1 : 0],
         vertexmap = [0,each cumsum(inside)],
         faces_edges_vertices = _vnfcut(plane, vnf[0],vertexmap,inside, vnf[1], last(vertexmap)),
         newvert = concat(bselect(vnf[0],inside), faces_edges_vertices[2])
    )
    closed==false ? [newvert, faces_edges_vertices[0]] :
    let(
        allpaths = _assemble_paths(newvert, faces_edges_vertices[1]),
        newpaths = [for(p=allpaths) if (len(p)>=3) p
                                    else assert(approx(p[0],p[1]),"Orphan edge found when assembling cut edges.")
           ]
    )
    len(newpaths)<=1 ? [newvert, concat(faces_edges_vertices[0], newpaths)] 
    :
      let(
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
   assert(len(first)==1 && len(second)==1, "Found concave face in VNF.  Run vnf_triangulate first to ensure convex faces.")
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
// Usage:
//   bentvnf = vnf_bend(vnf,r|d=,[axis=]);
// Description:
//   Bend a VNF around the X, Y or Z axis, splitting up faces as necessary.  Returns the bent
//   VNF.  For bending around the Z axis the input VNF must not cross the Y=0 plane.  For bending
//   around the X or Y axes the VNF must not cross the Z=0 plane.  Note that if you wrap a VNF all the way around
//   it may intersect itself, which produces an invalid polyhedron.  It is your responsibility to
//   avoid this situation.  The 1:1
//   radius is where the curved length of the bent VNF matches the length of the original VNF.  If the
//   `r` or `d` arguments are given, then they will specify the 1:1 radius or diameter.  If they are
//   not given, then the 1:1 radius will be defined by the distance of the furthest vertex in the
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
            assert(bmin.y > 0 || bmax.y < 0, "Entire shape MUST be completely in front of or behind y=0.") :
            assert(bmin.z > 0 || bmax.z < 0, "Entire shape MUST be completely above or below z=0."),
        steps = 1+ceil(segs(r) * (extent[1]-extent[0])/(2*PI*r)),
        step = (extent[1]-extent[0]) / steps,
        bend_at = [for(i = [1:1:steps-1]) i*step+extent[0]],
        slicedir = axis=="X"? "Y" : "X",   // slice in y dir for X axis case, and x dir otherwise
        sliced = vnf_slice(vnf, slicedir, bend_at),
        coord = axis=="X" ? [0,sign(bmax.z),0] : axis=="Y" ? [sign(bmax.z),0,0] : [sign(bmax.y),0,0],
        new_vert = [for(p=sliced[0])
                       let(a=coord*p*180/(PI*r))
                       axis=="X"? [p.x, p.z*sin(a), p.z*cos(a)] :
                       axis=="Y"? [p.z*sin(a), p.y, p.z*cos(a)] :
                       [p.y*sin(a), p.y*cos(a), p.z]]
                         
   ) [new_vert,sliced[1]];


// Section: Debugging Polyhedrons

/// Internal Module: _show_vertices()
/// Usage:
///   _show_vertices(vertices, [size])
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
module _show_vertices(vertices, size=1) {
    color("blue") {
        dups = vector_search(vertices, EPSILON, vertices);
        for (ind = dups){
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


/// Internal Module: _show_faces()
/// Usage:
///   _show_faces(vertices, faces, [size=]);
/// Description:
///   Draws all the vertices at their 3D position, numbered in blue by their
///   position in the vertex array.  Each face will have their face number drawn
///   in red, aligned with the center of face.  All children of this module are drawn
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
module _show_faces(vertices, faces, size=1) {
    vlen = len(vertices);
    color("red") {
        for (i = [0:1:len(faces)-1]) {
            face = faces[i];
            if (face[0] < 0 || face[1] < 0 || face[2] < 0 || face[0] >= vlen || face[1] >= vlen || face[2] >= vlen) {
                echo("BAD FACE: ", vlen=vlen, face=face);
            } else {
                verts = select(vertices,face);
                c = mean(verts);
                v0 = verts[0];
                v1 = verts[1];
                v2 = verts[2];
                dv0 = unit(v1 - v0);
                dv1 = unit(v2 - v0);
                nrm0 = cross(dv0, dv1);
                nrm1 = UP;
                axis = vector_axis(nrm0, nrm1);
                ang = vector_angle(nrm0, nrm1);
                theta = atan2(nrm0[1], nrm0[0]);
                translate(c) {
                    rotate(a=180-ang, v=axis) {
                        zrot(theta-90)
                        linear_extrude(height=size/10, center=true, convexity=10) {
                            union() {
                                text(text=str(i), size=size, halign="center");
                                text(text=str("_"), size=size, halign="center");
                            }
                        }
                    }
                }
            }
        }
    }
}



// Module: debug_vnf()
// Usage:
//   debug_vnf(vnfs, [faces=], [vertices=], [opacity=], [size=], [convexity=]);
// Description:
//   A drop-in module to replace `vnf_polyhedron()` to help debug vertices and faces.
//   Draws all the vertices at their 3D position, numbered in blue by their
//   position in the vertex array.  Each face will have its face number drawn
//   in red, aligned with the center of face.  All given faces are drawn with
//   transparency. All children of this module are drawn with transparency.
//   Works best with Thrown-Together preview mode, to see reversed faces.
//   You can set opacity to 0 if you want to supress the display of the polyhedron faces.  
//   .
//   The vertex numbers are shown rotated to face you.  As you rotate your polyhedron you
//   can rerun the preview to display them oriented for viewing from a different viewpoint.
// Topics: Polyhedra, Debugging
// Arguments:
//   vnf = vnf to display
//   ---
//   faces = if true display face numbers.  Default: true
//   vertices = if true display vertex numbers.  Default: true
//   opacity = Opacity of the polyhedron faces.  Default: 0.5
//   convexity = The max number of walls a ray can pass through the given polygon paths.
//   size = The size of the text used to label the faces and vertices.  Default: 1
// Example(EdgesMed):
//   verts = [for (z=[-10,10], a=[0:120:359.9]) [10*cos(a),10*sin(a),z]];
//   faces = [[0,1,2], [5,4,3], [0,3,4], [0,4,1], [1,4,5], [1,5,2], [2,5,3], [2,3,0]];
//   debug_vnf([verts,faces], size=2);
module debug_vnf(vnf, faces=true, vertices=true, opacity=0.5, size=1, convexity=6 ) {
    no_children($children);
    if (faces)
      _show_faces(vertices=vnf[0], faces=vnf[1], size=size);
    if (vertices)
      _show_vertices(vertices=vnf[0], size=size);
    color([0.2, 1.0, 0, opacity])
       vnf_polyhedron(vnf,convexity=convexity);
}


// Function&Module: vnf_validate()
// Usage: As Function
//   fails = vnf_validate(vnf);
// Usage: As Module
//   vnf_validate(vnf, [size], [check_isects]);
// Description:
//   When called as a function, returns a list of non-manifold errors with the given VNF.
//   Each error has the format `[ERR_OR_WARN,CODE,MESG,POINTS,COLOR]`.
//   When called as a module, echoes the non-manifold errors to the console, and color hilites the
//   bad edges and vertices, overlaid on a transparent gray polyhedron of the VNF.
//   .
//   Currently checks for these problems:
//   .
//   Type    | Color    | Code         | Message
//   ------- | -------- | ------------ | ---------------------------------
//   WARNING | Yellow   | BIG_FACE     | Face has more than 3 vertices, and may confuse CGAL.
//   WARNING | Brown    | NULL_FACE    | Face has zero area.
//   ERROR   | Cyan     | NONPLANAR    | Face vertices are not coplanar.
//   ERROR   | Brown    | DUP_FACE     | Multiple instances of the same face.
//   ERROR   | Orange   | MULTCONN     | Multiply Connected Geometry. Too many faces attached at Edge.
//   ERROR   | Violet   | REVERSAL     | Faces reverse across edge.
//   ERROR   | Red      | T_JUNCTION   | Vertex is mid-edge on another Face.
//   ERROR   | Blue     | FACE_ISECT   | Faces intersect.
//   ERROR   | Magenta  | HOLE_EDGE    | Edge bounds Hole.
//   .
//   Still to implement:
//   - Overlapping coplanar faces.
// Arguments:
//   vnf = The VNF to validate.
//   size = The width of the lines and diameter of points used to highlight edges and vertices.  Module only.  Default: 1
//   --
//   show_warns = If true show warnings for non-triangular faces.  Default: true
//   check_isects = If true, performs slow checks for intersecting faces.  Default: false
// Example: BIG_FACE Warnings; Faces with More Than 3 Vertices.  CGAL often will fail to accept that a face is planar after a rotation, if it has more than 3 vertices.
//   vnf = skin([
//       path3d(regular_ngon(n=3, d=100),0),
//       path3d(regular_ngon(n=5, d=100),100)
//   ], slices=0, caps=true, method="tangent");
//   vnf_validate(vnf);
// Example: NONPLANAR Errors; Face Vertices are Not Coplanar
//   a = [  0,  0,-50];
//   b = [-50,-50, 50];
//   c = [-50, 50, 50];
//   d = [ 50, 50, 60];
//   e = [ 50,-50, 50];
//   vnf = vnf_from_polygons([
//       [a, b, e], [a, c, b], [a, d, c], [a, e, d], [b, c, d, e]
//   ]);
//   vnf_validate(vnf);
// Example: MULTCONN Errors; More Than Two Faces Attached to the Same Edge.  This confuses CGAL, and can lead to failed renders.
//   vnf = vnf_triangulate(linear_sweep(union(square(50), square(50,anchor=BACK+RIGHT)), height=50));
//   vnf_validate(vnf);
// Example: REVERSAL Errors; Faces Reversed Across Edge
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
// Example: T_JUNCTION Errors; Vertex is Mid-Edge on Another Face.
//   vnf1 = skin([
//       path3d(square(100,center=true),0),
//       path3d(square(100,center=true),100),
//   ], slices=0, caps=false);
//   vnf = vnf_join([vnf1, vnf_from_polygons([
//       [[-50,-50,0], [50,50,0], [-50,50,0]],
//       [[-50,-50,0], [50,-50,0], [50,50,0]],
//       [[-50,-50,100], [-50,50,100], [0,50,100]],
//       [[-50,-50,100], [0,50,100], [0,-50,100]],
//       [[0,-50,100], [0,50,100], [50,50,100]],
//       [[0,-50,100], [50,50,100], [50,-50,100]],
//   ])]);
//   vnf_validate(vnf);
// Example: FACE_ISECT Errors; Faces Intersect
//   vnf = vnf_join([
//       vnf_triangulate(linear_sweep(square(100,center=true), height=100)),
//       move([75,35,30],p=vnf_triangulate(linear_sweep(square(100,center=true), height=100)))
//   ]);
//   vnf_validate(vnf,size=2,check_isects=true);
// Example: HOLE_EDGE Errors; Edges Adjacent to Holes.
//   vnf = skin([
//       path3d(regular_ngon(n=4, d=100),0),
//       path3d(regular_ngon(n=5, d=100),100)
//   ], slices=0, caps=false);
//   vnf_validate(vnf,size=2);
function vnf_validate(vnf, show_warns=true, check_isects=false) =
    assert(is_vnf(vnf), "Invalid VNF")
    let(
        vnf = vnf_merge_points(vnf),
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
            _vnf_validate_err("BIG_FACE", [for (i=face) varr[i]])
        ],
        null_faces = !show_warns? [] : [
            for (i = idx(faces)) let(
                face = faces[i],
                area = face_areas[i],
                faceverts = [for (k=face) varr[k]]
            )
            if (is_num(area) && abs(area) < EPSILON)
            _vnf_validate_err("NULL_FACE", faceverts)
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
            _vnf_validate_err("DUP_FACE", [for (i=sface1) varr[i]])
        ],
        issues = concat(issues, repeated_faces)
    ) repeated_faces? issues :
    let(
        multconn_edges = unique([
            for (i = idx(uniq_edges))
            if (edgecnts[1][i]>2)
            _vnf_validate_err("MULTCONN", [for (i=uniq_edges[i]) varr[i]])
        ]),
        issues = concat(issues, multconn_edges)
    ) multconn_edges? issues :
    let(
        reversals = unique([
            for(i = idx(dfaces), j = idx(dfaces)) if(i != j)
            for(edge1 = pair(faces[i],true))
            for(edge2 = pair(faces[j],true))
            if(edge1 == edge2)  // Valid adjacent faces will never have the same vertex ordering.
            if(_edge_not_reported(edge1, varr, multconn_edges))
            _vnf_validate_err("REVERSAL", [for (i=edge1) varr[i]])
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
            _vnf_validate_err("T_JUNCTION", [b])
        ]),
        issues = concat(issues, t_juncts)
    ) t_juncts? issues :
    let(
        isect_faces = !check_isects? [] : unique([
            for (i = [0:1:len(faces)-2]) let(
                f1 = faces[i],
                poly1   = select(varr, faces[i]),
                plane1  = plane3pt(poly1[0], poly1[1], poly1[2]),
                normal1 = [plane1[0], plane1[1], plane1[2]]
            )
            for (j = [i+1:1:len(faces)-1]) let(
                f2 = faces[j],
                poly2 = select(varr, f2),
                val = poly2 * normal1
            )
            if( min(val)<=plane1[3] && max(val)>=plane1[3] ) let(
                plane2  = plane_from_polygon(poly2),
                normal2 = [plane2[0], plane2[1], plane2[2]],
                val = poly1 * normal2
            )
            if( min(val)<=plane2[3] && max(val)>=plane2[3] ) let(
                shared_edges = [
                    for (edge1 = pair(f1, true), edge2 = pair(f2, true))
                    if (edge1 == [edge2[1], edge2[0]]) 1
                ]
            )
            if (!shared_edges) let(
                line = plane_intersection(plane1, plane2)
            )
            if (!is_undef(line)) let(
                isects = polygon_line_intersection(poly1, line)
            )
            if (!is_undef(isects))
            for (isect = isects)
            if (len(isect) > 1) let(
                isects2 = polygon_line_intersection(poly2, isect, bounded=true)
            )
            if (!is_undef(isects2))
            for (seg = isects2)
            if (seg[0] != seg[1])
            _vnf_validate_err("FACE_ISECT", seg)
        ]),
        issues = concat(issues, isect_faces)
    ) isect_faces? issues :
    let(
        hole_edges = unique([
            for (i=idx(uniq_edges))
            if (edgecnts[1][i]<2)
            if (_pts_not_reported(uniq_edges[i], varr, t_juncts))
            if (_pts_not_reported(uniq_edges[i], varr, isect_faces))
            _vnf_validate_err("HOLE_EDGE", [for (i=uniq_edges[i]) varr[i]])
        ]),
        issues = concat(issues, hole_edges)
    ) hole_edges? issues :
    let(
        nonplanars = unique([
            for (i = idx(faces)) let(
                face = faces[i],
                area = face_areas[i],
                faceverts = [for (k=face) varr[k]]
            )
            if (is_num(area) && abs(area) > EPSILON)
            if (!is_coplanar(faceverts))
            _vnf_validate_err("NONPLANAR", faceverts)
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


module vnf_validate(vnf, size=1, show_warns=true, check_isects=false) {
    no_children($children);
    faults = vnf_validate(
        vnf, show_warns=show_warns,
        check_isects=check_isects
    );
    for (fault = faults) {
        err = fault[0];
        typ = fault[1];
        clr = fault[2];
        msg = fault[3];
        pts = fault[4];
        echo(str(typ, " ", err, " (", clr ,"): ", msg, " at ", pts));
        color(clr) {
            if (is_vector(pts[0])) {
                if (len(pts)==2) {
                    stroke(pts, width=size, closed=true, endcaps="butt", hull=false, $fn=8);
                } else if (len(pts)>2) {
                    stroke(pts, width=size, closed=true, hull=false, $fn=8);
                    polyhedron(pts,[[for (i=idx(pts)) i]]);
                } else {
                    move_copies(pts) sphere(d=size*3, $fn=18);
                }
            }
        }
    }
    color([0.5,0.5,0.5,0.67]) vnf_polyhedron(vnf);
}



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
