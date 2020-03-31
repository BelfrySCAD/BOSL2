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
//   convexity = Max number of times a line could intersect a wall of the shape.
module vnf_polyhedron(vnf, convexity=2) {
	vnf = is_vnf_list(vnf)? vnf_merge(vnf) : vnf;
	polyhedron(vnf[0], vnf[1], convexity=convexity);
}





// Function: vnf_volume()
// Usage:
//   vol = vnf_volume(vnf);
// Description:
//   Returns the volume enclosed by the given manifold VNF.   The VNF must describe a valid polyhedron with consistent face direction and
//   no holes; otherwise the results are undefined.  Returns a positive volume if face direction is clockwise and a negative volume
//   if face direction is counter-clockwise.  
function vnf_volume(vnf) =
	let(
		vnf = vnf_triangulate(vnf),
		verts = vnf[0]
	) sum([
		for(face_index=vnf[1]) let(
			face = select(verts, face_index),
			n = cross(face[2]-face[0],face[1]-face[0])
		) face[0] * n
	])/6;


// Function: vnf_centroid()
// Usage:
//   vol = vnf_centroid(vnf);
// Description:
//   Returns the centroid of the given manifold VNF.  The VNF must describe a valid polyhedron with consistent face direction and
//   no holes; otherwise the results are undefined.

// Algorithm from: https://wwwf.imperial.ac.uk/~rn/centroid.pdf
function vnf_centroid(vnf) =
	let(
		vnf = vnf_triangulate(vnf),
		verts = vnf[0],
		val=sum([
			for(face_index=vnf[1])
			let(
				face = select(verts, face_index),
				n = cross(face[2]-face[0],face[1]-face[0])
			) [
				face[0] * n,
				vmul(n,
					sqr(face[0] + face[1]) +
					sqr(face[0] + face[2]) +
					sqr(face[1] + face[2])
				)
			]
		])
	) val[1]/val[0]/8;



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
//   
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
//   
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
				faceverts = [for (k=face) varr[k]],
				area = abs(polygon_area(faceverts))
			) if (area < EPSILON) [
				"WARNING",
				"NULL_FACE",
				str("Face has zero area: ",fmt_float(area,15)),
				faceverts,
				"brown"
			]
		],
		nonplanars = unique([
			for (face = faces) let(
				faceverts = [for (k=face) varr[k]]
			) if (!points_are_coplanar(faceverts)) [
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
				c = varr[edge[1]],
				pt = segment_closest_point([a,c],b)
			) if (pt == b) [
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


// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
