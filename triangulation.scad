use <math.scad>


function winding_dir(points, face) =
	let(count=len(face))
	sum(
		[
			for(i=[0:count-1]) cross(
				points[face[(i+1)%count]]-points[face[0]],
				points[face[(i+2)%count]]-points[face[(i+1)%count]]
			)
		],
		0
	)
;


function find_convex_vertex(dir, points, face, i=0) =
	let(count=len(face),
		p0=points[face[i]],
		p1=points[face[(i+1)%count]],
		p2=points[face[(i+2)%count]]
	)
	(len(face)>i)?
		(cross(p1-p0, p2-p1)*dir>0)? (i+1)%count : find_convex_vertex(dir, points, face, i+1)
	: //This should never happen since there is at least 1 convex vertex.
		undef
;


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


function normalize_vertex_perimeter(v) =
	(len(v) < 2)? v :
		(v[len(v)-1] != v[0])? v :
			[for (i=[0:len(v)-2]) v[i]]
;


function triangulate_faces(points, faces) =
	[
		for (i=[0 : len(faces)-1])
			let(facet = normalize_vertex_perimeter(faces[i]))
			for (face = triangulate_face(points, facet))
				if (face[0]!=face[1] && face[1]!=face[2] && face[2]!=face[0]) face
	]
;


function is_last_off_a_line(points, facelist, vertex) =
	let(
		face=wrap_range(facelist, vertex+1, vertex-1),
		count=len(face),
		dir=winding_dir(points, face)
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


function triangulate_face(points, face) =
	let(count=len(face))
	(3==count)?
		[face]
	:
		let(
			dir=winding_dir(points, face),
			cv=find_convex_vertex(dir, points, face),
			pv=(count+cv-1)%count,
			nv=(cv+1)%count,
			p0=points[face[pv]],
			p1=points[face[cv]],
			p2=points[face[nv]],
			tests=[
				[cross(dir, p0-p2), cross(dir, p0-p2)*p0],
				[cross(dir, p1-p0), cross(dir, p1-p0)*p1],
				[cross(dir, p2-p1), cross(dir, p2-p1)*p2]
			],
			ear_test=point_in_ear(points, face, tests),
			clipable_ear=(ear_test[0]<0),
			diagonal_point=ear_test[1]
		)
		(clipable_ear)? // There is no point inside the ear.
			is_last_off_a_line(points, face, cv)?
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


// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
