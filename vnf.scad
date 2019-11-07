//////////////////////////////////////////////////////////////////////
// LibFile: vnf.scad
//   VNF structures, holding Vertices 'N' Faces for use with `polyhedron().`
//   To use, add the following lines to the beginning of your file:
//   ```
//   use <BOSL2/std.scad>
//   use <BOSL2/vnf.scad>
//   ```
//////////////////////////////////////////////////////////////////////


include <triangulation.scad>


// Section: Creating Polyhedrons with VNF Structures
//   VNF stands for "Vertices'N'Faces".  VNF structures are 2-item lists, `[VERTICES,FACES]` where the
//   first item is a list of vertex points, and the second is a list of face indices into the vertex
//   list.  Each VNF is self contained, with face indices referring only to its own vertex list.
//   You can construct a `polyhedron()` in parts by describing each part in a self-contained VNF, then
//   merge the various VNFs to get the completed polyhedron vertex list and faces.


// Function: is_vnf()
// Description: Returns true if the given value looks passingly like a VNF structure.
function is_vnf(x) = is_list(x) && len(x)==2 && is_list(x[0]) && is_list(x[1]) && (x[0]==[] || is_vector(x[0][0])) && (x[1]==[] || is_vector(x[1][0]));


// Function: is_vnf_list()
// Description: Returns true if the given value looks passingly like a list of VNF structures.
function is_vnf_list(x) = is_list(x) && all([for (v=x) is_vnf(v)]);


// Function: vnf_vertices()
// Description: Given a VNF structure, returns the list of vertex points.
function vnf_vertices(vnf) = vnf[0];


// Function: vnf_faces()
// Description: Given a VNF structure, returns the list of faces, where each face is a list of indices into the VNF vertex list.
function vnf_faces(vnf) = vnf[1];


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
function vnf_get_vertex(vnf=[[],[]], p) =
	is_path(p)? _vnf_get_vertices(vnf, p) :
	assert(is_vnf(vnf))
	assert(is_vector(p))
	let(
		p = quant(p,1/1024),  // OpenSCAD internally quantizes objects to 1/1024.
		v = search([p], vnf[0])[0]
	) [
		v != []? v : len(vnf[0]),
		[
			concat(vnf[0], v != []? [] : [p]),
			vnf[1]
		]
	];


// Internal use only
function _vnf_get_vertices(vnf=[[],[]], pts, _i=0, _idxs=[]) =
	_i>=len(pts)? [_idxs, vnf] :
	let(
		vvnf = vnf_get_vertex(vnf, pts[_i])
	) _vnf_get_vertices(vvnf[1], pts, _i=_i+1, _idxs=concat(_idxs,[vvnf[0]]));


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
function vnf_add_face(vnf=[[],[]], pts) =
	assert(is_vnf(vnf))
	assert(is_path(pts))
	let(
		vvnf = vnf_get_vertex(vnf, pts),
		face = deduplicate(vvnf[0], closed=true),
		vnf2 = vvnf[1]
	) [
		vnf_vertices(vnf2),
		concat(vnf_faces(vnf2), len(face)>2? [face] : [])
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
function vnf_add_faces(vnf=[[],[]], faces, _i=0) =
	(assert(is_vnf(vnf)) assert(is_list(faces)) _i>=len(faces))? vnf :
	vnf_add_faces(vnf_add_face(vnf, faces[_i]), faces, _i=_i+1);


// Function: vnf_merge()
// Usage:
//   vnf = vnf_merge([VNF, VNF, VNF, ...]);
// Description:
//   Given a list of VNF structures, merges them all into a single VNF structure.
function vnf_merge(vnfs=[],_i=0,_acc=[[],[]]) =
	(assert(is_vnf_list(vnfs)) _i>=len(vnfs))? _acc :
	vnf_merge(
		vnfs, _i=_i+1,
		_acc = let(base=len(_acc[0])) [
			concat(_acc[0], vnfs[_i][0]),
			concat(_acc[1], [for (f=vnfs[_i][1]) [for (i=f) i+base]]),
		]
	);


// Function: vnf_triangulate()
// Usage:
//   vnf2 = vnf_triangulate(vnf);
// Description:
//   Forces triangulation of faces in the VNF that have more than 3 vertices.
function vnf_triangulate(vnf) =
	let(
		vnf = is_vnf_list(vnf)? vnf_merge(vnf) : vnf
	) [vnf[0], triangulate_faces(vnf[0], vnf[1])];


// Function: vnf_vertex_array()
// Usage:
//   vnf = vnf_vertex_array(points, cols, [caps], [cap1], [cap2], [reverse], [col_wrap], [row_wrap], [vnf]);
// Description:
//   Creates a VNF structure from a vertex list, by dividing the vertices into columns and rows,
//   adding faces to tile the surface.  You can optionally have faces added to wrap the last column
//   back to the first column, or wrap the last row to the first.  Endcaps can be added to either
//   the first and/or last rows.
// Arguments:
//   points = A list of vertices to divide into columns and rows.
//   cols = The number of points in a column.
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
//               affine3d_apply(
//                   circle(d=20),
//                   [xrot(90), right(30), zrot(a)]
//               )
//       ],
//       col_wrap=true, row_wrap=true, reverse=true
//   );
//   vnf_polyhedron(vnf);
// Example(3D): Möbius Strip.  Note that `row_wrap` is not used, and the first and last profile copies are the same.
//   vnf = vnf_vertex_array(
//       points=[
//           for (a=[0:5:360]) affine3d_apply(
//               square([1,10], center=true),
//               [zrot(a/2+60), xrot(90), right(30), zrot(a)]
//           )
//       ],
//       col_wrap=true, reverse=true
//   );
//   vnf_polyhedron(vnf);
// Example(3D): Assembling a Polyhedron from Multiple Parts
//   wall_points = [
//       for (a = [-90:2:90]) affine3d_apply(
//           circle(d=100),
//           [scale([1-0.1*cos(a*6), 1-0.1*cos((a+90)*6), 1]), up(a)]
//       )
//   ];
//   cap = [
//       for (a = [0:0.01:1+EPSILON]) affine3d_apply(
//           wall_points[0],
//           [scale([a,a,1]), up(90-5*sin(a*360*2))]
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
	vnf=[[],[]]
) =
	assert((!caps)||(caps&&col_wrap))
	assert(in_list(style,["default","alt","quincunx"]))
	let(
		pts = flatten(points),
		pcnt = len(pts),
		rows = len(points),
		cols = len(points[0]),
		errchk = [for (row=points) assert(len(row)==cols, "All rows much have the same number of columns.") 0],
		cap1 = first_defined([cap1,caps,false]),
		cap2 = first_defined([cap2,caps,false]),
		colcnt = cols - (col_wrap?0:1),
		rowcnt = rows - (row_wrap?0:1)
	)
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
module vnf_polyhedron(vnf) {
	vnf = is_vnf_list(vnf)? vnf_merge(vnf) : vnf;
	polyhedron(vnf[0], vnf[1]);
}


// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
