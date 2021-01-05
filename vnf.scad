//////////////////////////////////////////////////////////////////////
// LibFile: vnf.scad
//   VNF structures, holding Vertices 'N' Faces for use with `polyhedron().`
// Includes:
//   include <BOSL2/std.scad>
//   include <BOSL2/vnf.scad>
//////////////////////////////////////////////////////////////////////


include <triangulation.scad>


// Section: Creating Polyhedrons with VNF Structures
//   VNF stands for "Vertices'N'Faces".  VNF structures are 2-item lists, `[VERTICES,FACES]` where the
//   first item is a list of vertex points, and the second is a list of face indices into the vertex
//   list.  Each VNF is self contained, with face indices referring only to its own vertex list.
//   You can construct a `polyhedron()` in parts by describing each part in a self-contained VNF, then
//   merge the various VNFs to get the completed polyhedron vertex list and faces.


EMPTY_VNF = [[],[]];  // The standard empty VNF with no vertices or faces.


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
    (x[0]==[] || (len(x[0])>=3 && is_vector(x[0][0]))) &&
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


// Function: vnf_get_vertex()
// Usage:
//   vvnf = vnf_get_vertex(vnf, p);
// Description:
//   Finds the index number of the given vertex point `p` in the given VNF structure `vnf`.  If said
//   point does not already exist in the VNF vertex list, it is added.  Returns: `[INDEX, VNF]` where
//   INDEX if the index of the point, and VNF is the possibly modified new VNF structure.
//   If `p` is given as a list of points, then INDEX will be a list of indices.
// Arguments:
//   vnf = The VNF structue to get the point index from.
//   p = The point, or list of points to get the index of.
// Example:
//   vnf1 = vnf_get_vertex(p=[3,5,8]);  // Returns: [0, [[[3,5,8]],[]]]
//   vnf2 = vnf_get_vertex(vnf1, p=[3,2,1]);  // Returns: [1, [[[3,5,8],[3,2,1]],[]]]
//   vnf3 = vnf_get_vertex(vnf2, p=[3,5,8]);  // Returns: [0, [[[3,5,8],[3,2,1]],[]]]
//   vnf4 = vnf_get_vertex(vnf3, p=[[1,3,2],[3,2,1]]);  // Returns: [[1,2], [[[3,5,8],[3,2,1],[1,3,2]],[]]]
function vnf_get_vertex(vnf=EMPTY_VNF, p) =
    let(
        p = is_vector(p)? [p] : p,
        res = set_union(vnf[0], p, get_indices=true)
    )
    [res[0], [res[1],vnf[1]]];


// Function: vnf_add_face()
// Usage:
//   vnf_add_face(vnf, pts);
// Description:
//   Given a VNF structure and a list of face vertex points, adds the face to the VNF structure.
//   Returns the modified VNF structure `[VERTICES, FACES]`.  It is up to the caller to make
//   sure that the points are in the correct order to make the face normal point outwards.
// Arguments:
//   vnf = The VNF structure to add a face to.
//   pts = The vertex points for the face.
function vnf_add_face(vnf=EMPTY_VNF, pts) =
    assert(is_vnf(vnf))
    assert(is_path(pts))
    let(
        res = set_union(vnf[0], pts, get_indices=true),
        face = deduplicate(res[0], closed=true)
    ) [
        res[1],
        concat(vnf[1], len(face)>2? [face] : [])
    ];


// Function: vnf_add_faces()
// Usage:
//   vnf_add_faces(vnf, faces);
// Description:
//   Given a VNF structure and a list of faces, where each face is given as a list of vertex points,
//   adds the faces to the VNF structure.  Returns the modified VNF structure `[VERTICES, FACES]`.
//   It is up to the caller to make sure that the points are in the correct order to make the face
//   normals point outwards.
// Arguments:
//   vnf = The VNF structure to add a face to.
//   faces = The list of faces, where each face is given as a list of vertex points.
function vnf_add_faces(vnf=EMPTY_VNF, faces) =
    assert(is_vnf(vnf))
    assert(is_list(faces))
    let(
        res = set_union(vnf[0], flatten(faces), get_indices=true),
        idxs = res[0],
        nverts = res[1],
        offs = cumsum([0, for (face=faces) len(face)]),
        ifaces = [
            for (i=idx(faces)) [
                for (j=idx(faces[i]))
                idxs[offs[i]+j]
            ]
        ]
    ) [
        nverts,
        concat(vnf[1],ifaces)
    ];


// Function: vnf_merge()
// Usage:
//   vnf = vnf_merge([VNF, VNF, VNF, ...]);
// Description:
//   Given a list of VNF structures, merges them all into a single VNF structure.
function vnf_merge(vnfs=[],_i=0,_acc=EMPTY_VNF) =
    (assert(is_vnf_list(vnfs)) _i>=len(vnfs))? _acc :
    vnf_merge(
        vnfs, _i=_i+1,
        _acc = let(base=len(_acc[0])) [
            concat(_acc[0], vnfs[_i][0]),
            concat(_acc[1], [for (f=vnfs[_i][1]) [for (i=f) i+base]]),
        ]
    );

// Function: vnf_compact()
// Usage:
//   cvnf = vnf_compact(vnf);
// Description:
//   Takes a VNF and consolidates all duplicate vertices, and drops unreferenced vertices.
function vnf_compact(vnf) =
    let(
        vnf = is_vnf_list(vnf)? vnf_merge(vnf) : vnf,
        verts = vnf[0],
        faces = [
            for (face=vnf[1]) [
                for (i=face) verts[i]
            ]
        ]
    ) vnf_add_faces(faces=faces);


// Function: vnf_triangulate()
// Usage:
//   vnf2 = vnf_triangulate(vnf);
// Description:
//   Forces triangulation of faces in the VNF that have more than 3 vertices.
function vnf_triangulate(vnf) =
    let(
        vnf = is_vnf_list(vnf)? vnf_merge(vnf) : vnf,
        verts = vnf[0]
    ) [verts, triangulate_faces(verts, vnf[1])];


// Function: vnf_vertex_array()
// Usage:
//   vnf = vnf_vertex_array(points, [caps], [cap1], [cap2], [reverse], [col_wrap], [row_wrap], [vnf]);
// Description:
//   Creates a VNF structure from a vertex list, by dividing the vertices into columns and rows,
//   adding faces to tile the surface.  You can optionally have faces added to wrap the last column
//   back to the first column, or wrap the last row to the first.  Endcaps can be added to either
//   the first and/or last rows.
// Arguments:
//   points = A list of vertices to divide into columns and rows.
//   caps = If true, add endcap faces to the first AND last rows.
//   cap1 = If true, add an endcap face to the first row.
//   cap2 = If true, add an endcap face to the last row.
//   col_wrap = If true, add faces to connect the last column to the first.
//   row_wrap = If true, add faces to connect the last row to the first.
//   reverse = If true, reverse all face normals.
//   style = The style of subdividing the quads into faces.  Valid options are "default", "alt", and "quincunx".
//   vnf = If given, add all the vertices and faces to this existing VNF structure.
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
function vnf_vertex_array(
    points,
    caps, cap1, cap2,
    col_wrap=false,
    row_wrap=false,
    reverse=false,
    style="default",
    vnf=EMPTY_VNF
) =
    assert((!caps)||(caps&&col_wrap))
    assert(in_list(style,["default","alt","quincunx"]))
        assert(is_consistent(points), "Non-rectangular or invalid point array")
    let(
        pts = flatten(points),
        pcnt = len(pts),
        rows = len(points),
        cols = len(points[0]),
        cap1 = first_defined([cap1,caps,false]),
        cap2 = first_defined([cap2,caps,false]),
        colcnt = cols - (col_wrap?0:1),
        rowcnt = rows - (row_wrap?0:1)
    )
    rows<=1 || cols<=1 ? vnf : 
    vnf_merge([
        vnf, [
            concat(
                pts,
                style!="quincunx"? [] : [
                    for (r = [0:1:rowcnt-1]) (
                        for (c = [0:1:colcnt-1]) (
                            let(
                                i1 = ((r+0)%rows)*cols + ((c+0)%cols),
                                i2 = ((r+1)%rows)*cols + ((c+0)%cols),
                                i3 = ((r+1)%rows)*cols + ((c+1)%cols),
                                i4 = ((r+0)%rows)*cols + ((c+1)%cols)
                            ) mean([pts[i1], pts[i2], pts[i3], pts[i4]])
                        )
                    )
                ]
            ),
            concat(
                [
                    for (r = [0:1:rowcnt-1]) (
                        for (c = [0:1:colcnt-1]) each (
                            let(
                                i1 = ((r+0)%rows)*cols + ((c+0)%cols),
                                i2 = ((r+1)%rows)*cols + ((c+0)%cols),
                                i3 = ((r+1)%rows)*cols + ((c+1)%cols),
                                i4 = ((r+0)%rows)*cols + ((c+1)%cols)
                            )
                            style=="quincunx"? (
                                let(i5 = pcnt + r*colcnt + c)
                                reverse? [[i1,i2,i5],[i2,i3,i5],[i3,i4,i5],[i4,i1,i5]] : [[i1,i5,i2],[i2,i5,i3],[i3,i5,i4],[i4,i5,i1]]
                            ) : style=="alt"? (
                                reverse? [[i1,i2,i4],[i2,i3,i4]] : [[i1,i4,i2],[i2,i4,i3]]
                            ) : (
                                reverse? [[i1,i2,i3],[i1,i3,i4]] : [[i1,i3,i2],[i1,i4,i3]]
                            )
                        )
                    )
                ],
                !cap1? [] : [
                    reverse?
                        [for (c = [0:1:cols-1]) c] :
                        [for (c = [cols-1:-1:0]) c]
                ],
                !cap2? [] : [
                    reverse?
                        [for (c = [cols-1:-1:0]) (rows-1)*cols + c] :
                        [for (c = [0:1:cols-1]) (rows-1)*cols + c]
                ]
            )
        ]
    ]);


// Module: vnf_polyhedron()
// Usage:
//   vnf_polyhedron(vnf);
//   vnf_polyhedron([VNF, VNF, VNF, ...]);
// Description:
//   Given a VNF structure, or a list of VNF structures, creates a polyhedron from them.
// Arguments:
//   vnf = A VNF structure, or list of VNF structures.
//   convexity = Max number of times a line could intersect a wall of the shape.
//   extent = If true, calculate anchors by extents, rather than intersection.  Default: true.
//   cp = Centerpoint of VNF to use for anchoring when `extent` is false.  Default: `[0, 0, 0]`
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `"origin"`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
module vnf_polyhedron(vnf, convexity=2, extent=true, cp=[0,0,0], anchor="origin", spin=0, orient=UP) {
    vnf = is_vnf_list(vnf)? vnf_merge(vnf) : vnf;
    cp = is_def(cp) ? cp : vnf_centroid(vnf);
    attachable(anchor,spin,orient, vnf=vnf, extent=extent, cp=cp) {
        polyhedron(vnf[0], vnf[1], convexity=convexity);
        children();
    }
}



// Module: vnf_wireframe()
// Usage:
//   vnf_wireframe(vnf, [r|d]);
// Description:
//   Given a VNF, creates a wire frame ball-and-stick model of the polyhedron with a cylinder for each edge and a sphere at each vertex. 
// Arguments:
//   vnf = A vnf structure
//   r|d = radius or diameter of the cylinders forming the wire frame.  Default: r=1
// Example:
//   $fn=32;
//   ball = sphere(r=20, $fn=6);
//   vnf_wireframe(ball,d=1);
// Example: 
//  include<BOSL2/polyhedra.scad>
//  $fn=32;
//  cube_oct = regular_polyhedron_info("vnf", name="cuboctahedron", or=20);
//  vnf_wireframe(cube_oct);
// Example: The spheres at the vertex are imperfect at aligning with the cylinders, so especially at low $fn things look prety ugly.  This is normal.  
//  include<BOSL2/polyhedra.scad>
//  $fn=8;
//  octahedron = regular_polyhedron_info("vnf", name="octahedron", or=20);
//  vnf_wireframe(octahedron,r=5);
module vnf_wireframe(vnf, r, d)
{
  r = get_radius(r=r,d=d,dflt=1);
  vertex = vnf[0];
  edges = unique([for (face=vnf[1], i=idx(face))
                    sort([face[i], select(face,i+1)])
                 ]);
  for (e=edges) extrude_from_to(vertex[e[0]],vertex[e[1]]) circle(r=r);
  move_copies(vertex) sphere(r=r);
}  


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


// Function: vnf_centroid()
// Usage:
//   vol = vnf_centroid(vnf);
// Description:
//   Returns the centroid of the given manifold VNF.  The VNF must describe a valid polyhedron with consistent face direction and
//   no holes; otherwise the results are undefined.

// Divide the solid up into tetrahedra with the origin as one vertex.  The centroid of a tetrahedron is the average of its vertices.
// The centroid of the total is the volume weighted average.  
function vnf_centroid(vnf) =
    let(
        verts = vnf[0],
        vol = sum([
            for(face=vnf[1], j=[1:1:len(face)-2]) let(
                v0  = verts[face[0]],
                v1  = verts[face[j]],
                v2  = verts[face[j+1]]
            ) cross(v2,v1)*v0
        ]),
        pos = sum([
            for(face=vnf[1], j=[1:1:len(face)-2]) let(
                v0  = verts[face[0]],
                v1  = verts[face[j]],
                v2  = verts[face[j+1]],
                vol = cross(v2,v1)*v0
            )
            (v0+v1+v2)*vol
        ])
    )
    pos/vol/4;


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
//   bentvnf = vnf_bend(vnf);
// Description:
//   Given a VNF that is entirely above, or entirely below the Z=0 plane, bends the VNF around the
//   Y axis, splitting up faces as necessary.  Returns the bent VNF.  Will error out if the VNF
//   straddles the Z=0 plane, or if the bent VNF would wrap more than completely around.  The 1:1
//   radius is where the curved length of the bent VNF matches the length of the original VNF.  If the
//   `r` or `d` arguments are given, then they will specify the 1:1 radius or diameter.  If they are
//   not given, then the 1:1 radius will be defined by the distance of the furthest vertex in the
//   original VNF from the Z=0 plane.  You can adjust the granularity of the bend using the standard
//   `$fa`, `$fs`, and `$fn` variables.
// Arguments:
//   vnf = The original VNF to bend.
//   r = If given, the radius where the size of the original shape is the same as in the original.
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
//   rgn = union(rect([100,20],center=true), rect([20,100],center=true));
//   vnf0 = linear_sweep(zrot(45,p=rgn), height=10);
//   vnf1 = up(50, p=vnf0);
//   vnf2 = down(50, p=vnf0);
//   bent1 = vnf_bend(vnf1, axis="Y");
//   bent2 = vnf_bend(vnf2, axis="Y");
//   vnf_polyhedron([bent1,bent2]);
// Example(3D): Bending Around X Axis.
//   rgnr = union(
//       rect([20,100],center=true),
//       back(50, p=trapezoid(w1=40, w2=0, h=20, anchor=FRONT))
//   );
//   vnf0 = xrot(00,p=linear_sweep(rgnr, height=10));
//   vnf1 = up(50, p=vnf0);
//   #vnf_polyhedron(vnf1);
//   bent1 = vnf_bend(vnf1, axis="X");
//   vnf_polyhedron([bent1]);
// Example(3D): Bending Around Y Axis.
//   rgn = union(
//       rect([20,100],center=true),
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
//       rect([20,100],center=true),
//       back(50, p=trapezoid(w1=40, w2=0, h=20, anchor=FRONT))
//   );
//   rgnr = zrot(90, p=rgn);
//   vnf0 = xrot(90,p=linear_sweep(rgnr, height=10));
//   vnf1 = fwd(50, p=vnf0);
//   #vnf_polyhedron(vnf1);
//   bent1 = vnf_bend(vnf1, axis="Z");
//   vnf_polyhedron([bent1]);
function vnf_bend(vnf,r,d,axis="Z") =
    let(
        chk_axis = assert(in_list(axis,["X","Y","Z"])),
        vnf = vnf_triangulate(vnf),
        verts = vnf[0],
        bounds = pointlist_bounds(verts),
        bmin = bounds[0],
        bmax = bounds[1],
        dflt = axis=="Z"?
            max(abs(bmax.y), abs(bmin.y)) :
            max(abs(bmax.z), abs(bmin.z)),
        r = get_radius(r=r,d=d,dflt=dflt),
        width = axis=="X"? (bmax.y-bmin.y) : (bmax.x - bmin.x)
    )
    assert(width <= 2*PI*r, "Shape would wrap more than completely around the cylinder.")
    let(
        span_chk = axis=="Z"?
            assert(bmin.y > 0 || bmax.y < 0, "Entire shape MUST be completely in front of or behind y=0.") :
            assert(bmin.z > 0 || bmax.z < 0, "Entire shape MUST be completely above or below z=0."),
        min_ang = 180 * bmin.x / (PI * r),
        max_ang = 180 * bmax.x / (PI * r),
        ang_span = max_ang-min_ang,
        steps = ceil(segs(r) * ang_span/360),
        step = width / steps,
        bend_at = axis=="X"? [for(i = [1:1:steps-1]) i*step+bmin.y] :
            [for(i = [1:1:steps-1]) i*step+bmin.x],
        facepolys = [for (face=vnf[1]) select(verts,face)],
        splits = axis=="X"?
            split_polygons_at_each_y(facepolys, bend_at) :
            split_polygons_at_each_x(facepolys, bend_at),
        newtris = _triangulate_planar_convex_polygons(splits),
        bent_faces = [
            for (tri = newtris) [
                for (p = tri) let(
                    a = axis=="X"? 180*p.y/(r*PI) * sign(bmax.z) :
                        axis=="Y"? 180*p.x/(r*PI) * sign(bmax.z) :
                        180*p.x/(r*PI) * sign(bmax.y)
                )
                axis=="X"? [p.x, p.z*sin(a), p.z*cos(a)] :
                axis=="Y"? [p.z*sin(a), p.y, p.z*cos(a)] :
                [p.y*sin(a), p.y*cos(a), p.z]
            ]
        ]
    ) vnf_add_faces(faces=bent_faces);


// Function&Module: vnf_validate()
// Usage: As Function
//   fails = vnf_validate(vnf);
// Usage: As Module
//   vnf_validate(vnf);
// Description:
//   When called as a function, returns a list of non-manifold errors with the given VNF.
//   Each error has the format `[ERR_OR_WARN,CODE,MESG,POINTS,COLOR]`.
//   When called as a module, echoes the non-manifold errors to the console, and color hilites the
//   bad edges and vertices, overlaid on a transparent gray polyhedron of the VNF.
//   .
//   Currently checks for these problems:
//   Type    | Color    | Code         | Message 
//   ------- | -------- | ------------ | ---------------------------------
//   WARNING | Yellow   | BIG_FACE     | Face has more than 3 vertices, and may confuse CGAL
//   WARNING | Brown    | NULL_FACE   | Face has zero area
//   ERROR   | Cyan     | NONPLANAR    | Face vertices are not coplanar
//   ERROR   | Orange   | OVRPOP_EDGE  | Too many faces attached at edge
//   ERROR   | Violet   | REVERSAL     | Faces reverse across edge
//   ERROR   | Red      | T_JUNCTION   | Vertex is mid-edge on another Face
//   ERROR   | Blue     | FACE_ISECT   | Faces intersect
//   ERROR   | Magenta  | HOLE_EDGE    | Edge bounds Hole
//   .
//   Still to implement:
//   - Overlapping coplanar faces.
// Arguments:
//   vnf = The VNF to validate.
//   size = The width of the lines and diameter of points used to highlight edges and vertices.  Module only.  Default: 1
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
//   vnf = vnf_add_faces(faces=[
//       [a, b, e], [a, c, b], [a, d, c], [a, e, d], [b, c, d, e]
//   ]);
//   vnf_validate(vnf);
// Example: OVRPOP_EDGE Errors; More Than Two Faces Attached to the Same Edge.  This confuses CGAL, and can lead to failed renders.
//   vnf = vnf_triangulate(linear_sweep(union(square(50), square(50,anchor=BACK+RIGHT)), height=50));
//   vnf_validate(vnf);
// Example: REVERSAL Errors; Faces Reversed Across Edge
//   vnf1 = skin([
//       path3d(square(100,center=true),0),
//       path3d(square(100,center=true),100),
//   ], slices=0, caps=false);
//   vnf = vnf_add_faces(vnf=vnf1, faces=[
//       [[-50,-50,  0], [ 50, 50,  0], [-50, 50,  0]],
//       [[-50,-50,  0], [ 50,-50,  0], [ 50, 50,  0]],
//       [[-50,-50,100], [-50, 50,100], [ 50, 50,100]],
//       [[-50,-50,100], [ 50,-50,100], [ 50, 50,100]],
//   ]);
//   vnf_validate(vnf);
// Example: T_JUNCTION Errors; Vertex is Mid-Edge on Another Face.
//   vnf1 = skin([
//       path3d(square(100,center=true),0),
//       path3d(square(100,center=true),100),
//   ], slices=0, caps=false);
//   vnf = vnf_add_faces(vnf=vnf1, faces=[
//       [[-50,-50,0], [50,50,0], [-50,50,0]],
//       [[-50,-50,0], [50,-50,0], [50,50,0]],
//       [[-50,-50,100], [-50,50,100], [0,50,100]],
//       [[-50,-50,100], [0,50,100], [0,-50,100]],
//       [[0,-50,100], [0,50,100], [50,50,100]],
//       [[0,-50,100], [50,50,100], [50,-50,100]],
//   ]);
//   vnf_validate(vnf);
// Example: FACE_ISECT Errors; Faces Intersect
//   vnf = vnf_merge([
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
    assert(is_path(vnf[0]))
    let(
        vnf = vnf_compact(vnf),
        varr = vnf[0],
        faces = vnf[1],
        edges = sort([
            for (face=faces, edge=pair_wrap(face))
            edge[0]<edge[1]? edge : [edge[1],edge[0]]
        ]),
        edgecnts = unique_count(edges),
        uniq_edges = edgecnts[0],
        big_faces = !show_warns? [] : [
            for (face = faces)
            if (len(face) > 3) [
                "WARNING",
                "BIG_FACE",
                "Face has more than 3 vertices, and may confuse CGAL",
                [for (i=face) varr[i]],
                "yellow"
            ]
        ],
        null_faces = !show_warns? [] : [
            for (face = faces) let(
                face = deduplicate(face,closed=true)
            )
            if (len(face)>=3) let(
                faceverts = [for (k=face) varr[k]],
                area = polygon_area(faceverts)
            ) if (is_num(area) && abs(area) < EPSILON) [
                "WARNING",
                "NULL_FACE",
                str("Face has zero area: ",fmt_float(abs(area),15)),
                faceverts,
                "brown"
            ]
        ],
        nonplanars = unique([
            for (face = faces) let(
                faceverts = [for (k=face) varr[k]],
                area = polygon_area(faceverts)
            )
            if (is_num(area) && abs(area) > EPSILON)
            if (!coplanar(faceverts)) [
                "ERROR",
                "NONPLANAR",
                "Face vertices are not coplanar",
                faceverts,
                "cyan"
            ]
        ]),
        overpop_edges = unique([
            for (i=idx(uniq_edges))
            if (edgecnts[1][i]>2) [
                "ERROR",
                "OVRPOP_EDGE",
                "Too many faces attached at Edge",
                [for (i=uniq_edges[i]) varr[i]],
                "#f70"
            ]
        ]),
        reversals = unique([
            for(i = idx(faces), j = idx(faces)) if(i != j)
            if(len(deduplicate(faces[i],closed=true))>=3)
            if(len(deduplicate(faces[j],closed=true))>=3)
            for(edge1 = pair_wrap(faces[i]))
            for(edge2 = pair_wrap(faces[j]))
            if(edge1 == edge2)  // Valid adjacent faces will never have the same vertex ordering.
            if(_edge_not_reported(edge1, varr, overpop_edges))
            [
                "ERROR",
                "REVERSAL",
                "Faces Reverse Across Edge",
                [for (i=edge1) varr[i]],
                "violet"
            ]
        ]),
        t_juncts = unique([
            for (v=idx(varr), edge=uniq_edges)
            if (v!=edge[0] && v!=edge[1]) let(
                a = varr[edge[0]],
                b = varr[v],
                c = varr[edge[1]]
            )
            if (a != b && b != c && a != c) let(
                pt = segment_closest_point([a,c],b)
            )
            if (pt == b) [
                "ERROR",
                "T_JUNCTION",
                "Vertex is mid-edge on another Face",
                [b],
                "red"
            ]
        ]),
        isect_faces = !check_isects? [] : unique([
            for (i = [0:1:len(faces)-2])
            for (j = [i+1:1:len(faces)-1]) let(
                f1 = faces[i],
                f2 = faces[j],
                shared_edges = [
                    for (edge1 = pair_wrap(f1), edge2 = pair_wrap(f2)) let(
                        e1 = edge1[0]<edge1[1]? edge1 : [edge1[1],edge1[0]],
                        e2 = edge2[0]<edge2[1]? edge2 : [edge2[1],edge2[0]]
                    ) if (e1==e2) 1
                ]
            )
            if (!shared_edges) let(
                plane1 = plane3pt_indexed(varr, f1[0], f1[1], f1[2]),
                plane2 = plane3pt_indexed(varr, f2[0], f2[1], f2[2]),
                line = plane_intersection(plane1, plane2)
            )
            if (!is_undef(line)) let(
                poly1 = select(varr,f1),
                isects = polygon_line_intersection(poly1,line)
            )
            if (!is_undef(isects))
            for (isect=isects)
            if (len(isect)>1) let(
                poly2 = select(varr,f2),
                isects2 = polygon_line_intersection(poly2,isect,bounded=true)
            )
            if (!is_undef(isects2))
            for (seg=isects2)
            if (seg[0] != seg[1]) [
                "ERROR",
                "FACE_ISECT",
                "Faces intersect",
                seg,
                "blue"
            ]
        ]),
        hole_edges = unique([
            for (i=idx(uniq_edges))
            if (edgecnts[1][i]<2)
            if (_pts_not_reported(uniq_edges[i], varr, t_juncts))
            if (_pts_not_reported(uniq_edges[i], varr, isect_faces))
            [
                "ERROR",
                "HOLE_EDGE",
                "Edge bounds Hole",
                [for (i=uniq_edges[i]) varr[i]],
                "magenta"
            ]
        ])
    ) concat(
        big_faces,
        null_faces,
        nonplanars,
        overpop_edges,
        reversals,
        t_juncts,
        isect_faces,
        hole_edges
    );


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
    faults = vnf_validate(
        vnf, show_warns=show_warns,
        check_isects=check_isects
    );
    for (fault = faults) {
        typ = fault[0];
        err = fault[1];
        msg = fault[2];
        pts = fault[3];
        clr = fault[4];
        echo(str(typ, " ", err, ": ", msg, " at ", pts));
        color(clr) {
            if (len(pts)==2) {
                stroke(pts, width=size);
            } else if (len(pts)>2) {
                stroke(pts, width=size, closed=true);
                polyhedron(pts,[[for (i=idx(pts)) i]]);
            } else {
                move_copies(pts) sphere(d=size*3, $fn=18);
            }
        }
    }
    color([0.5,0.5,0.5,0.5]) vnf_polyhedron(vnf);
}

// Section: VNF transformations
//

// Function: vnf_halfspace(halfspace, vnf)
// Usage:
//   vnf_halfspace([a,b,c,d], vnf)
// Description:
//   returns the intersection of the VNF with the given half-space.
// Arguments:
//   halfspace = half-space to intersect with, given as the four coefficients of the affine inequation a\*x+b\*y+c\*z≥ d.

function _vnf_halfspace_pts(halfspace, points, faces,
  inside=undef, coords=[], map=[]) =
/* Recursive function to compute the intersection of points (and edges,
 * but not faces) with with the half-space.
 * Parameters:
 * halfspace  a vector(4)
 * points     a list of points3d
 * faces      a list of indexes in points
 * inside     a vector{bool} determining which points belong to the
 *            half-space; if undef, it is initialized at first loop.
 * coords     the coordinates of the points in the intersection
 * map        the logical map (old point) → (new point(s)):
 *   if point i is kept, then map[i] = new-index-for-i;
 *   if point i is dropped, then map[i] = [[j1, k1], [j2, k2], …],
 *      where points j1,… are kept (old index)
 *      and k1,… are the matching intersections (new index).
 * Returns the triple [coords, map, inside].
 *
 */
    let(i=len(map), n=len(coords)) // we are currently processing point i
    // termination test:
    i >= len(points) ? [ coords, map, inside ] :
    let(inside = !is_undef(inside) ? inside :
        [for(x=points) halfspace*concat(x,[-1]) >= 0],
        pi = points[i])
    // inside half-space: keep the point (and reindex)
    inside[i] ? _vnf_halfspace_pts(halfspace, points, faces, inside,
        concat(coords, [pi]), concat(map, [n]))
    : // else: compute adjacent vertices (adj)
    let(adj = unique([for(f=faces) let(m=len(f), j=search(i, f)[0])
      each if(j!=undef) [f[(j+1)%m], f[(j+m-1)%m]] ]),
    // filter those which lie in half-space:
        adj2 = [for(x=adj) if(inside[x]) x],
        zi = halfspace*concat(pi, [-1]))
    _vnf_halfspace_pts(halfspace, points, faces, inside,
        // new points: we append all these intersection points
        concat(coords, [for(j=adj2) let(zj=halfspace*concat(points[j],[-1]))
            (zi*points[j]-zj*pi)/(zi-zj)]),
        // map: we add the info
        concat(map, [[for(y=enumerate(adj2)) [y[1], n+y[0]]]]));
function _vnf_halfspace_face(face, map, inside, i=0,
    newface=[], newedge=[], exit) =
/* Recursive function to intersect a face of the VNF with the half-plane.
 * Arguments:
 *   face: the list of points of the face (old indices).
 *   map: as produced by _vnf_halfspace_pts
 *   inside: vector{bool} containing half-space info
 *   i: index for iteration
 *   exit: boolean; is first point in newedge an exit or an entrance from
 *     half-space?
 *   newface: list of (new indexes of) points on the face
 *   newedge: list of new points on the plane (even number of points)
 *  Return value: [newface, new-edges], where new-edges is a list of
 *  pairs [entrance-node, exit-node] (new indices).
 */
// termination condition:
    (i >= len(face)) ? [ newface,
    // if exit==true then we return newedge[1,0], newedge[3,2], ...
    // otherwise newedge[0,1], newedge[2,3], ...;
    // all edges are oriented (entrance->exit), so that by following the
    // arrows we obtain a correctly-oriented face:
    let(k = exit ? 0 : 1)
    [for(i=[0:2:len(newedge)-2]) [newedge[i+k], newedge[i+1-k]]] ]
    : // recursion case: p is current point on face, q is next point
    let(p = face[i], q = face[(i+1)%len(face)],
        // if p is inside half-plane, keep it in the new face:
        newface0 = inside[p] ?  concat(newface, [map[p]]) : newface)
        // if the current segment does not intersect, this is all:
        inside[p] == inside[q] ? _vnf_halfspace_face(face, map, inside, i+1,
            newface0, newedge, exit)
        : // otherwise, we must add the intersection point:
        // rename the two points p,q as inner and outer point:
        let(in = inside[p] ? p : q, out = p+q-in,
            inter=[for(a=map[out]) if(a[0]==in) a[1]][0])
        _vnf_halfspace_face(face, map, inside, i+1,
            concat(newface0, [inter]),
            concat(newedge, [inter]),
            is_undef(exit) ? inside[p] : exit);
function _vnf_halfspace_path_search_edge(edge, paths, i=0, ret=[undef,undef]) =
/* given an oriented edge [x,y] and a set of oriented paths,
 * returns the indices [i,j] of paths [before, after] given edge
 */
    // termination condition
    i >= len(paths) ? ret:
    _vnf_halfspace_path_search_edge(edge, paths, i+1,
       [last(paths[i]) == edge[0] ? i : ret[0],
        paths[i][0] == edge[1] ? i : ret[1]]);
function _vnf_halfspace_paths(edges, i=0, paths=[]) =
/* given a set of oriented edges [x,y],
   returns all paths [x,y,z,..] that may be formed from these edges.
   A closed path will be returned with equal first and last point.
   i: index of currently examined edge
 */
    i >= len(edges) ? paths : // termination condition
    let(e=edges[i], s = _vnf_halfspace_path_search_edge(e, paths))
        _vnf_halfspace_paths(edges, i+1,
        // we keep all paths untouched by e[i]
        concat([for(i=[0:1:len(paths)-1]) if(i!= s[0] && i != s[1]) paths[i]],
        is_undef(s[0])? (
            // fresh e: create a new path
            is_undef(s[1]) ? [e] :
            // e attaches to beginning of previous path
            [concat([e[0]], paths[s[1]])]
        ) :// edge attaches to end of previous path
        is_undef(s[1]) ? [concat(paths[s[0]], [e[1]])] :
        // edge merges two paths
        s[0] != s[1] ? [concat(paths[s[0]], paths[s[1]])] :
        // edge closes a loop
        [concat(paths[s[0]], [e[1]])]));
function vnf_halfspace(_arg1=_undef, _arg2=_undef,
    halfspace=_undef, vnf=_undef) =
    // here is where we wish that OpenSCAD had array lvalues...
    let(args=get_named_args([_arg1, _arg2], [[halfspace],[vnf]]),
        halfspace=args[0], vnf=args[1])
    assert(is_vector(halfspace, 4),
        "half-space must be passed as a length 4 affine form")
    assert(is_vnf(vnf), "must pass a vnf")
        // read points
    let(tmp1=_vnf_halfspace_pts(halfspace, vnf[0], vnf[1]),
        coords=tmp1[0], map=tmp1[1], inside=tmp1[2],
        // cut faces and generate edges
        tmp2= [for(f=vnf[1]) _vnf_halfspace_face(f, map, inside)],
        newfaces=[for(x=tmp2) if(x[0]!=[]) x[0]],
        newedges=[for(x=tmp2) each x[1]],
        // generate new faces
        paths=_vnf_halfspace_paths(newedges),
        loops=[for(p=paths) if(p[0] == last(p)) p])
    [coords, concat(newfaces, loops)];

// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
