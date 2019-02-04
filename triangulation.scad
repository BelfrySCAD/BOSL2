use <math.scad>


// Given an array of vertices (`points`), and a list of indexes into the
// vertex array (`face`), returns the normal vector of the face.
//   points = Array of vertices for the polyhedron.
//   face = The face, given as a list of indices into the vertex array `points`.
function face_normal(points, face) =
	let(count=len(face))
	normalize(
		sum(
			[
				for(i=[0:count-1]) cross(
					points[face[(i+1)%count]]-points[face[0]],
					points[face[(i+2)%count]]-points[face[(i+1)%count]]
				)
			]
		)
	)
;


// Returns the index of a convex point on the given face.
//   points = Array of vertices for the polyhedron.
//   face = The face, given as a list of indices into the vertex array `points`.
//   facenorm = The normal vector of the face.
function find_convex_vertex(points, face, facenorm, i=0) =
	let(count=len(face),
		p0=points[face[i]],
		p1=points[face[(i+1)%count]],
		p2=points[face[(i+2)%count]]
	)
	(len(face)>i)?
		(cross(p1-p0, p2-p1)*facenorm>0)? (i+1)%count : find_convex_vertex(points, face, facenorm, i+1)
	: //This should never happen since there is at least 1 convex vertex.
		undef
;


//   points = Array of vertices for the polyhedron.
//   face = The face, given as a list of indices into the vertex array `points`.
function point_in_ear(points, face, tests, i=0) =
	(i<len(face)-1)?
		let(
			prev=point_in_ear(points, face, tests, i+1),
			test=check_point_in_ear(points[face[i]], tests)
		)
		(test>prev[0])? [test, i] : prev
	:
		[check_point_in_ear(points[face[i]], tests), i]
;


function check_point_in_ear(point, tests) =
	let(
		result=[
			(point*tests[0][0])-tests[0][1],
			(point*tests[1][0])-tests[1][1],
			(point*tests[2][0])-tests[2][1]
		]
	)
	(result[0]>0 && result[1]>0 && result[2]>0)? result[0] : -1
;


// Removes the last item in an array if it is the same as the first item.
//   v = The array to normalize.
function normalize_vertex_perimeter(v) =
	(len(v) < 2)? v :
		(v[len(v)-1] != v[0])? v :
			[for (i=[0:len(v)-2]) v[i]]
;


// Given a face in a polyhedron, and a vertex in that face, returns true
// if that vertex is the only non-colinear vertex in the face.
//   points = Array of vertices for the polyhedron.
//   facelist = The face, given as a list of indices into the vertex array `points`.
//   vertex = The index into `facelist`, of the vertex to test.
function is_only_noncolinear_vertex(points, facelist, vertex) =
	let(
		face=wrap_range(facelist, vertex+1, vertex-1),
		count=len(face)
	)
	0==sum(
		[
			for(i=[0:count-1]) norm(
				cross(
					points[face[(i+1)%count]]-points[face[0]],
					points[face[(i+2)%count]]-points[face[(i+1)%count]]
				)
			)
		]
	)
;


// Given a face in a polyhedron, subdivides the face into triangular faces.
// Returns an array of faces, where each face is a list of vertex indices.
//   points = Array of vertices for the polyhedron.
//   face = The face, given as a list of indices into the vertex array `points`.
function triangulate_face(points, face) =
	let(count=len(face))
	(3==count)?
		[face]
	:
		let(
			facenorm=face_normal(points, face),
			cv=find_convex_vertex(points, face, facenorm),
			pv=(count+cv-1)%count,
			nv=(cv+1)%count,
			p0=points[face[pv]],
			p1=points[face[cv]],
			p2=points[face[nv]],
			tests=[
				[cross(facenorm, p0-p2), cross(facenorm, p0-p2)*p0],
				[cross(facenorm, p1-p0), cross(facenorm, p1-p0)*p1],
				[cross(facenorm, p2-p1), cross(facenorm, p2-p1)*p2]
			],
			ear_test=point_in_ear(points, face, tests),
			clipable_ear=(ear_test[0]<0),
			diagonal_point=ear_test[1]
		)
		(clipable_ear)? // There is no point inside the ear.
			is_only_noncolinear_vertex(points, face, cv)?
				// In the point&line degeneracy clip to somewhere in the middle of the line.
				flatten([
					triangulate_face(points, wrap_range(face, cv, (cv+2)%count)),
					triangulate_face(points, wrap_range(face, (cv+2)%count, cv))
				])
			:
				// Otherwise the ear is safe to clip.
				flatten([
					[wrap_range(face, pv, nv)],
					triangulate_face(points, wrap_range(face, nv, pv))
				])
		: // If there is a point inside the ear, make a diagonal and clip along that.
			flatten([
				triangulate_face(points, wrap_range(face, cv, diagonal_point)),
				triangulate_face(points, wrap_range(face, diagonal_point, cv))
			])
;


// Subdivides all faces for the given polyhedron that have more than 3 vertices.
// Returns an array of faces where each face is a list of 3 vertex array indices.
//   points = Array of vertices for the polyhedron.
//   faces = Array of faces for the polyhedron. Each face is a list of 3 or more indices into the `points` array.
function triangulate_faces(points, faces) =
	[
		for (i=[0 : len(faces)-1])
			let(facet = normalize_vertex_perimeter(faces[i]))
			for (face = triangulate_face(points, facet))
				if (face[0]!=face[1] && face[1]!=face[2] && face[2]!=face[0]) face
	]
;


// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
