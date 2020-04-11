//////////////////////////////////////////////////////////////////////
// LibFile: attachments.scad
//   This is the file that handles attachments and orientation of children.
//   To use, add the following lines to the beginning of your file:
//   ```
//   include <BOSL2/std.scad>
//   ```
//////////////////////////////////////////////////////////////////////


// Default values for attachment code.
$tags = "";
$overlap = 0.01;
$color = undef;

$attach_to = undef;
$attach_anchor = [CENTER, CENTER, UP, 0];
$attach_norot = false;

$parent_anchor = BOTTOM;
$parent_spin = 0;
$parent_orient = UP;

$parent_size = undef;
$parent_geom = undef;

$tags_shown = [];
$tags_hidden = [];


// Section: Anchors, Spin, and Orientation
//   This library adds the concept of anchoring, spin and orientation to the `cube()`, `cylinder()`
//   and `sphere()` builtins, as well as to most of the shapes provided by this library itself.
//   * An anchor is a place on an object which you can align the object to, or attach other objects
//     to using `attach()` or `position()`.  An anchor has a position, a direction, and a spin.
//     The direction and spin are used to orient other objects to match when using `attach()`.
//   * Spin is a simple rotation around the Z axis.
//   * Orientation is rotating an object so that its top is pointed towards a given vector.
//   An object will first be translated to its anchor position, then spun, then oriented.
//   
//   ## Anchor
//   Anchoring is specified with the `anchor` argument in most shape modules.
//   Specifying `anchor` when creating an object will translate the object so
//   that the anchor point is at the origin (0,0,0).  Anchoring always occurs
//   before spin and orientation are applied.
//   
//   An anchor can be referred to in one of two ways; as a directional vector,
//   or as a named anchor string.
//   
//   When given as a vector, it points, in a general way, towards the face, edge, or
//   corner of the object that you want the anchor for, relative to the center of
//   the object.  There are directional constants named `TOP`, `BOTTOM`, `FRONT`, `BACK`,
//   `LEFT`, and `RIGHT` that you can add together to specify an anchor point.
//   For example:
//    - `[0,0,1]` is the same as `TOP` and refers to the center of the top face.
//    - `[-1,0,1]` is the same as `TOP+LEFT`, and refers to the center of the top-left edge.
//    - `[1,1,-1]` is the same as `BOTTOM+BACK+RIGHT`, and refers to the bottom-back-right corner.
//   
//   The components of the directional vector should all be `1`, `0`, or `-1`.
//   When the object is cylindrical, conical, or spherical in nature, the anchors will be
//   located around the surface of the cylinder, cone, or sphere, relative to the center.
//   The direction of a face anchor will be perpendicular to the face, pointing outward.
//   The direction of a edge anchor will be the average of the anchor directions of the
//   two faces the edge is between.  The direction of a corner anchor will be the average
//   of the anchor directions of the three faces the corner is on.  The spin of all standard
//   anchors is 0.
//   
//   Some more complex objects, like screws and stepper motors, have named anchors
//   to refer to places on the object that are not at one of the standard faces, edges
//   or corners.  For example, stepper motors have anchors for `"screw1"`, `"screw2"`,
//   etc. to refer to the various screwholes on the stepper motor shape.  The names,
//   positions, directions, and spins of these anchors will be specific to the object,
//   and will be documented when they exist.
//   
//   ## Spin
//   Spin is specified with the `spin` argument in most shape modules.  Specifying `spin`
//   when creating an object will rotate the object counter-clockwise around the Z axis
//   by the given number of degrees.  Spin is always applied after anchoring, and before
//   orientation.
//   
//   ## Orient
//   Orientation is specified with the `orient` argument in most shape modules.  Specifying
//   `orient` when creating an object will rotate the object such that the top of the
//   object will be pointed at the vector direction given in the `orient` argument.
//   Orientation is always applied after anchoring and spin.  The constants `UP`, `DOWN`,
//   `FRONT`, `BACK`, `LEFT`, and `RIGHT` can be added together to form the directional
//   vector for this.  ie: `LEFT+BACK`


// Section: Functions

// Function: anchorpt()
// Usage:
//   anchor(name, pos, [dir], [rot])
// Description:
//   Creates a anchor data structure.
// Arguments:
//   name = The string name of the anchor.  Lowercase.  Words separated by single dashes.  No spaces.
//   pos = The [X,Y,Z] position of the anchor.
//   orient = A vector pointing in the direction parts should project from the anchor position.
//   spin = If needed, the angle to rotate the part around the direction vector.
function anchorpt(name, pos=[0,0,0], orient=UP, spin=0) = [name, pos, orient, spin];


// Function: attach_geom()
//
// Usage:
//   geom = attach_geom(anchor, spin, [orient], two_d, size, [size2], [shift], [offset], [anchors]);
//   geom = attach_geom(anchor, spin, [orient], two_d, r|d, [offset], [anchors]);
//   geom = attach_geom(anchor, spin, [orient], two_d, path, [extent], [offset], [anchors]);
//   geom = attach_geom(anchor, spin, [orient], size, [size2], [shift], [offset], [anchors]);
//   geom = attach_geom(anchor, spin, [orient], r|d, l, [offset], [anchors]);
//   geom = attach_geom(anchor, spin, [orient], r1|d1, r2|d2, l, [offset], [anchors]);
//   geom = attach_geom(anchor, spin, [orient], r|d, [offset], [anchors]);
//   geom = attach_geom(anchor, spin, [orient], vnf, [extent], [offset], [anchors]);
//
// Description:
//   Given arguments that describe the geometry of an attachable object, returns the internal geometry description.
//
// Arguments:
//   size = If given as a 3D vector, contains the XY size of the bottom of the cuboidal/prismoidal volume, and the Z height.  If given as a 2D vector, contains the front X width of the rectangular/trapezoidal shape, and the Y length.
//   size2 = If given as a 2D vector, contains the XY size of the top of the prismoidal volume.  If given as a number, contains the back width of the trapezoidal shape.
//   shift = If given as a 2D vector, shifts the top of the prismoidal or conical shape by the given amount.  If given as a number, shifts the back of the trapezoidal shape right by that amount.  Default: No shift.
//   r = Radius of the cylindrical/conical volume.
//   d = Diameter of the cylindrical/conical volume.
//   r1 = Radius of the bottom of the conical volume.
//   r2 = Radius of the top of the conical volume.
//   d1 = Diameter of the bottom of the conical volume.
//   d2 = Diameter of the top of the conical volume.
//   l = Length of the cylindrical/conical volume along axis.
//   vnf = The [VNF](vnf.scad) of the volume.
//   path = The path to generate a polygon from.
//   extent = If true, calculate anchors by extents, rather than intersection.  Default: false.
//   offset = If given, offsets the center of the volume.
//   anchors = If given as a list of anchor points, allows named anchor points.
//   two_d = If true, the attachable shape is 2D.  If false, 3D.  Default: false (3D)
//
// Example(NORENDER): Cubical Shape
//   geom = attach_geom(anchor, spin, orient, size=size);
//
// Example(NORENDER): Prismoidal Shape
//   geom = attach_geom(
//       anchor, spin, orient,
//       size=point3d(botsize,h),
//       size2=topsize, shift=shift
//   );
//
// Example(NORENDER): Cylindrical Shape
//   geom = attach_geom(anchor, spin, orient, r=r, h=h);
//
// Example(NORENDER): Conical Shape
//   geom = attach_geom(anchor, spin, orient, r1=r1, r2=r2, h=h);
//
// Example(NORENDER): Spherical Shape
//   geom = attach_geom(anchor, spin, orient, r=r);
//
// Example(NORENDER): Arbitrary VNF Shape
//   geom = attach_geom(anchor, spin, orient, vnf=vnf);
//
// Example(NORENDER): 2D Rectangular Shape
//   geom = attach_geom(anchor, spin, orient, size=size);
//
// Example(NORENDER): 2D Trapezoidal Shape
//   geom = attach_geom(
//       anchor, spin, orient,
//       size=[x1,y], size2=x2, shift=shift
//   );
//
// Example(NORENDER): 2D Circular Shape
//   geom = attach_geom(anchor, spin, orient, two_d=true, r=r);
//
// Example(NORENDER): Arbitrary 2D Polygon Shape
//   geom = attach_geom(anchor, spin, orient, path=path);
//
function attach_geom(
	size, size2, shift,
	r,r1,r2, d,d1,d2, l,h,
	vnf, path,
	extent=true,
	offset=[0,0,0],
	anchors=[],
	two_d=false
) =
	assert(is_bool(extent))
	assert(is_vector(offset))
	assert(is_list(anchors))
	assert(is_bool(two_d))
	!is_undef(size)? (
		two_d? (
			let(
				size2 = default(size2, size.x),
				shift = default(shift, 0)
			)
			assert(is_vector(size,2))
			assert(is_num(size2))
			assert(is_num(shift))
			["rect", point2d(size), size2, shift, offset, anchors]
		) : (
			let(
				size2 = default(size2, point2d(size)),
				shift = default(shift, [0,0])
			)
			assert(is_vector(size,3))
			assert(is_vector(size2,2))
			assert(is_vector(shift,2))
			["cuboid", size, size2, shift, offset, anchors]
		)
	) : !is_undef(vnf)? (
		assert(is_vnf(vnf))
		assert(two_d == false)
		extent? ["vnf_extent", vnf, offset, anchors] :
		["vnf_isect", vnf, offset, anchors]
	) : !is_undef(path)? (
		assert(is_path(path),2)
		assert(two_d == true)
		extent? ["path_extent", path, offset, anchors] :
		["path_isect", path, offset, anchors]
	) :
	let(
		r1 = get_radius(r1=r1,d1=d1,r=r,d=d,dflt=undef)
	)
	!is_undef(r1)? (
		assert(is_num(r1))
		let( l = default(l, h) )
		!is_undef(l)? (
			let(
				shift = default(shift, [0,0]),
				r2 = get_radius(r1=r2,d1=d2,r=r,d=d,dflt=undef)
			)
			assert(is_num(l))
			assert(is_num(r2))
			assert(is_vector(shift,2))
			["cyl", r1, r2, l, shift, offset, anchors]
		) : (
			two_d? ["circle", r1, offset, anchors] :
			["spheroid", r1, offset, anchors]
		)
	) :
	assert(false, "Unrecognizable geometry description.");



// Function: attach_geom_2d()
// Usage:
//   attach_geom_2d(geom);
// Description:
//   Returns true if the given attachment geometry description is for a 2D shape.
function attach_geom_2d(geom) =
	let( type = geom[0] )
	type == "rect" || type == "circle" ||
	type == "path_isect" || type == "path_extent";


// Function: attach_geom_size()
// Usage:
//   attach_geom_size(geom);
// Description:
//   Returns the `[X,Y,Z]` bounding size for the given attachment geometry description.
function attach_geom_size(geom) =
	let( type = geom[0] )
	type == "cuboid"? ( //size, size2, shift
		let(
			size=geom[1], size2=geom[2], shift=point2d(geom[3]),
			maxx = max(size.x,size2.x),
			maxy = max(size.y,size2.y),
			z = size.z
		) [maxx, maxy, z]
	) : type == "cyl"? ( //r1, r2, l, shift
		let(
			r1=geom[1], r2=geom[2], l=geom[3], shift=point2d(geom[4]),
			maxr = max(r1,r2)
		) [2*maxr,2*maxr,l]
	) : type == "spheroid"? ( //r
		let( r=geom[1] ) [2,2,2]*r
	) : type == "vnf_extent" || type=="vnf_isect"? ( //vnf
		let(
			mm = pointlist_bounds(geom[1][0]),
			delt = mm[1]-mm[0]
		) delt
	) : type == "rect"? ( //size, size2
		let(
			size=geom[1], size2=geom[2],
			maxx = max(size.x,size2)
		) [maxx, size.y]
	) : type == "circle"? ( //r
		let( r=geom[1] ) [2,2]*r
	) : type == "path_isect" || type == "path_extent"? ( //path
		let(
			mm = pointlist_bounds(geom[1]),
			delt = mm[1]-mm[0]
		) [delt.x, delt.y]
	) :
	assert(false, "Unknown attachment geometry type.");


// Function: attach_transform()
// Usage:
//   mat = attach_transform(anchor=CENTER, spin=0, orient=UP, geom);
// Description:
//   Returns the affine3d transformation matrix needed to `anchor`, `spin`, and `orient`
//   the given geometry `geom` shape into position.
// Arguments:
//   anchor = Anchor point to translate to the origin `[0,0,0]`.  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
//   geom = The geometry description of the shape.
//   p = If given as a VNF, path, or point, applies the affine3d transformation matrix to it and returns the result.
function attach_transform(anchor=CENTER, spin=0, orient=UP, geom, p) =
	assert(is_string(anchor) || is_vector(anchor))
	assert(is_vector(orient))
	let(
		two_d = attach_geom_2d(geom),
		m = ($attach_to != undef)? (
			let(
				anch = find_anchor($attach_to, geom),
				pos = anch[1]
			) two_d? (
				assert(two_d && is_num(spin))
				let(
					ang = vector_angle(anch[2], BACK)
				)
				affine3d_zrot(ang+spin) *
				affine3d_translate(point3d(-pos))
			) : (
				assert(is_num(spin) || is_vector(spin,3))
				let(
					ang = vector_angle(anch[2], DOWN),
					axis = vector_axis(anch[2], DOWN),
					ang2 = (anch[2]==UP || anch[2]==DOWN)? 0 : 180-anch[3],
					axis2 = rot(p=axis,[0,0,ang2])
				)
				affine3d_rot_by_axis(axis2,ang) * (
					is_num(spin)? affine3d_zrot(ang2+spin) : (
						affine3d_zrot(spin.z) *
						affine3d_yrot(spin.y) *
						affine3d_xrot(spin.x) *
						affine3d_zrot(ang2)
					)
				) * affine3d_translate(point3d(-pos))
			)
		) : (
			let(
				pos = find_anchor(anchor, geom)[1]
			) two_d? (
				assert(two_d && is_num(spin))
				affine3d_zrot(spin) *
				affine3d_translate(point3d(-pos))
			) : (
				assert(is_num(spin) || is_vector(spin,3))
				let(
					axis = vector_axis(UP,orient),
					ang = vector_angle(UP,orient)
				)
				affine3d_rot_by_axis(axis,ang) * (
					is_num(spin)? affine3d_zrot(spin) : (
						affine3d_zrot(spin.z) *
						affine3d_yrot(spin.y) *
						affine3d_xrot(spin.x)
					)
				) * affine3d_translate(point3d(-pos))
			)
		)
	) is_undef(p)? m :
	is_vnf(p)? [apply(m, p[0]), p[1]] :
	apply(m, p);


// Function: find_anchor()
// Usage:
//   find_anchor(anchor, geom);
// Description:
//   Calculates the anchor data for the given `anchor` vector or name, in the given attachment
//   geometry.  Returns `[ANCHOR, POS, VEC, ANG]` where `ANCHOR` is the requested anchorname
//   or vector, `POS` is the anchor position, `VEC` is the direction vector of the anchor, and
//   `ANG` is the angle to align with around the rotation axis of th anchor direction vector.
// Arguments:
//   anchor = Vector or named anchor string.
//   geom = The geometry description of the shape.
function find_anchor(anchor, geom) =
	let(
		offset = anchor==CENTER? CENTER : select(geom,-2),
		anchors = select(geom,-1),
		type = geom[0]
	)
	is_string(anchor)? (
		let(found = search([anchor], anchors, num_returns_per_match=1)[0])
		assert(found!=[], str("Unknown anchor: ",anchor))
		anchors[found]
	) :
	assert(is_vector(anchor),str("anchor=",anchor))
	let(anchor = point3d(anchor))
	anchor==CENTER? [anchor, CENTER, UP, 0] :
	let(
		oang = (
			approx(point2d(anchor), [0,0])? 0 :
			atan2(anchor.y, anchor.x)+90
		)
	)
	type == "cuboid"? ( //size, size2, shift
		let(
			size=geom[1], size2=geom[2], shift=point2d(geom[3]),
			h = size.z,
			u = (anchor.z+1)/2,
			axy = point2d(anchor),
			bot = point3d(vmul(point2d(size)/2,axy),-h/2),
			top = point3d(vmul(point2d(size2)/2,axy)+shift,h/2),
			pos = lerp(bot,top,u)+offset,
			sidevec = unit(rot(from=UP, to=top-bot, p=point3d(axy))),
			vvec = unit([0,0,anchor.z]),
			vec = anchor==CENTER? UP :
				approx(axy,[0,0])? unit(anchor) :
				approx(anchor.z,0)? sidevec :
				unit((sidevec+vvec)/2)
		) [anchor, pos, vec, oang]
	) : type == "cyl"? ( //r1, r2, l, shift
		let(
			r1=geom[1], r2=geom[2], l=geom[3], shift=point2d(geom[4]),
			u = (anchor.z+1)/2,
			axy = unit(point2d(anchor)),
			bot = point3d(r1*axy,-l/2),
			top = point3d(r2*axy+shift, l/2),
			pos = lerp(bot,top,u)+offset,
			sidevec = rot(from=UP, to=top-bot, p=point3d(axy)),
			vvec = unit([0,0,anchor.z]),
			vec = anchor==CENTER? UP :
				approx(axy,[0,0])? unit(anchor) :
				approx(anchor.z,0)? sidevec :
				unit((sidevec+vvec)/2)
		) [anchor, pos, vec, oang]
	) : type == "spheroid"? ( //r
		let(
			r=geom[1]
		) [anchor, r*unit(anchor)+offset, unit(anchor), oang]
	) : type == "vnf_isect"? ( //vnf
		let(
			vnf=geom[1],
			eps = 1/2048,
			rpts = rot(from=anchor, to=RIGHT, p=vnf[0]),
			hits = [
				for (i = idx(vnf[1])) let(
					face = vnf[1][i],
					verts = select(rpts, face)
				) if (
					max(subindex(verts,0)) >= -eps &&
					max(subindex(verts,1)) >= -eps &&
					max(subindex(verts,2)) >= -eps &&
					min(subindex(verts,1)) <=  eps &&
					min(subindex(verts,2)) <=  eps
				) let(
					pt = polygon_line_intersection(
						select(vnf[0], face),
						[CENTER,anchor], eps=eps
					)
				) if (!is_undef(pt)) [norm(pt),i,pt]
			]
		)
		assert(len(hits)>0, "Anchor vector does not intersect with the shape.  Attachment failed.")
		let(
			furthest = max_index(subindex(hits,0)),
			pos = hits[furthest][2],
			dist = hits[furthest][0],
			nfaces = [for (hit = hits) if(approx(hit[0],dist,eps=eps)) hit[1]],
			n = unit(
				sum([
					for (i = nfaces) let(
						faceverts = select(vnf[0],vnf[1][i]),
						faceplane = plane_from_points(faceverts),
						nrm = plane_normal(faceplane)
					) nrm
				]) / len(nfaces)
			)
		)
		[anchor, pos, n, oang]
	) : type == "vnf_extent"? ( //vnf
		let(
			vnf=geom[1],
			rpts = rot(from=anchor, to=RIGHT, p=vnf[0]),
			maxx = max(subindex(rpts,0)),
			idxs = [for (i = idx(rpts)) if (approx(rpts[i].x, maxx)) i],
			mm = pointlist_bounds(select(rpts,idxs)),
			avgy = (mm[0].y+mm[1].y)/2,
			avgz = (mm[0].z+mm[1].z)/2,
			mpt = approx(point2d(anchor),[0,0])? [maxx,0,0] : [maxx, avgy, avgz],
			pos = rot(from=RIGHT, to=anchor, p=mpt)
		) [anchor, pos, anchor, oang]
	) : type == "rect"? ( //size, size2
		let(
			size=geom[1], size2=geom[2],
			u = (anchor.y+1)/2,
			frpt = [size.x/2*anchor.x, -size.y/2],
			bkpt = [size2/2*anchor.x,  size.y/2],
			pos = lerp(frpt, bkpt, u),
			vec = unit(rot(from=BACK, to=bkpt-frpt, p=anchor))
		) [anchor, pos, vec, 0]
	) : type == "circle"? ( //r
		let(
			r=geom[1],
			anchor = unit(point2d(anchor))
		) [anchor, r*anchor+offset, anchor, 0]
	) : type == "path_isect"? ( //path
		let(
			path=geom[1],
			anchor = point2d(anchor),
			isects = [
				for (t=triplet_wrap(path)) let(
					seg1 = [t[0],t[1]],
					seg2 = [t[1],t[2]],
					isect = ray_segment_intersection([[0,0],anchor], seg1),
					n = is_undef(isect)? [0,1] :
						!approx(isect, t[1])? line_normal(seg1) :
						unit((line_normal(seg1)+line_normal(seg2))/2),
					n2 = vector_angle(anchor,n)>90? -n : n
				)
				if(!is_undef(isect) && !approx(isect,t[0])) [norm(isect), isect, n2]
			],
			maxidx = max_index(subindex(isects,0)),
			isect = isects[maxidx],
			pos = isect[1],
			vec = unit(isect[2])
		) [anchor, pos, vec, 0]
	) : type == "path_extent"? ( //path
		let(
			path=geom[1],
			anchor = point2d(anchor),
			rpath = rot(from=anchor, to=RIGHT, p=path),
			maxx = max(subindex(rpath,0)),
			idxs = [for (i = idx(rpath)) if (approx(rpath[i].x, maxx)) i],
			miny = min([for (i=idxs) rpath[i].y]),
			maxy = max([for (i=idxs) rpath[i].y]),
			avgy = (miny+maxy)/2,
			pos = rot(from=RIGHT, to=anchor, p=[maxx,avgy])
		) [anchor, pos, anchor, 0]
	) :
	assert(false, "Unknown attachment geometry type.");


// Function: attachment_is_shown()
// Usage:
//   attachment_is_shown(tags);
// Description:
//   Returns true if the given space-delimited string of tag names should currently be shown.
function attachment_is_shown(tags) =
	assert(!is_undef($tags_shown))
	assert(!is_undef($tags_hidden))
	let(
		tags = str_split(tags, " "),
		shown  = !$tags_shown || any([for (tag=tags) in_list(tag, $tags_shown)]),
		hidden = any([for (tag=tags) in_list(tag, $tags_hidden)])
	) shown && !hidden;


// Function: reorient()
//
// Usage:
//   reorient(anchor, spin, [orient], two_d, size, [size2], [shift], [offset], [anchors], [p]);
//   reorient(anchor, spin, [orient], two_d, r|d, [offset], [anchors], [p]);
//   reorient(anchor, spin, [orient], two_d, path, [extent], [offset], [anchors], [p]);
//   reorient(anchor, spin, [orient], size, [size2], [shift], [offset], [anchors], [p]);
//   reorient(anchor, spin, [orient], r|d, l, [offset], [anchors], [p]);
//   reorient(anchor, spin, [orient], r1|d1, r2|d2, l, [offset], [anchors], [p]);
//   reorient(anchor, spin, [orient], r|d, [offset], [anchors], [p]);
//   reorient(anchor, spin, [orient], vnf, [extent], [offset], [anchors], [p]);
//
// Description:
//   Given anchor, spin, orient, and general geometry info for a managed volume, this calculates
//   the transformation matrix needed to be applied to the contents of that volume.  A managed 3D
//   volume is assumed to be vertically (Z-axis) oriented, and centered.  A managed 2D area is just
//   assumed to be centered.
//   
//   If `p` is not given, then the transformation matrix will be returned.
//   If `p` contains a VNF, a new VNF will be returned with the vertices transformed by the matrix.
//   If `p` contains a path, a new path will be returned with the vertices transformed by the matrix.
//   If `p` contains a point, a new point will be returned, transformed by the matrix.
//   
//   If `$attach_to` is not defined, then the following transformations are performed in order:
//   * Translates so the `anchor` point is at the origin (0,0,0).
//   * Rotates around the Z axis by `spin` degrees counter-clockwise.
//   * Rotates so the top of the part points towards the vector `orient`.
//   
//   If `$attach_to` is defined, as a consequence of `attach(from,to)`, then
//   the following transformations are performed in order:
//   * Translates this part so it's anchor position matches the parent's anchor position.
//   * Rotates this part so it's anchor direction vector exactly opposes the parent's anchor direction vector.
//   * Rotates this part so it's anchor spin matches the parent's anchor spin.
//
// Arguments:
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
//   size = If given as a 3D vector, contains the XY size of the bottom of the cuboidal/prismoidal volume, and the Z height.  If given as a 2D vector, contains the front X width of the rectangular/trapezoidal shape, and the Y length.
//   size2 = If given as a 2D vector, contains the XY size of the top of the prismoidal volume.  If given as a number, contains the back width of the trapezoidal shape.
//   shift = If given as a 2D vector, shifts the top of the prismoidal or conical shape by the given amount.  If given as a number, shifts the back of the trapezoidal shape right by that amount.  Default: No shift.
//   r = Radius of the cylindrical/conical volume.
//   d = Diameter of the cylindrical/conical volume.
//   r1 = Radius of the bottom of the conical volume.
//   r2 = Radius of the top of the conical volume.
//   d1 = Diameter of the bottom of the conical volume.
//   d2 = Diameter of the top of the conical volume.
//   l = Length of the cylindrical/conical volume along axis.
//   vnf = The [VNF](vnf.scad) of the volume.
//   path = The path to generate a polygon from.
//   extent = If true, calculate anchors by extents, rather than intersection.  Default: false.
//   offset = If given, offsets the center of the volume.
//   anchors = If given as a list of anchor points, allows named anchor points.
//   two_d = If true, the attachable shape is 2D.  If false, 3D.  Default: false (3D)
//   p = The VNF, path, or point to transform.
function reorient(
	anchor=CENTER,
	spin=0,
	orient=UP,
	size, size2, shift,
	r,r1,r2, d,d1,d2, l,h,
	vnf, path,
	extent=true,
	offset=[0,0,0],
	anchors=[],
	two_d=false,
	p=undef
) = let(
	geom = attach_geom(
		size=size, size2=size2, shift=shift,
		r=r, r1=r1, r2=r2, h=h,
		d=d, d1=d1, d2=d2, l=l,
		vnf=vnf, path=path, extent=extent,
		offset=offset, anchors=anchors,
		two_d=two_d
	)
) attach_transform(anchor,spin,orient,geom,p);



// Section: Attachability Modules

// Module: attachable()
//
// Usage:
//   attachable(anchor, spin, [orient], two_d, size, [size2], [shift], [offset], [anchors] ...
//   attachable(anchor, spin, [orient], two_d, r|d, [offset], [anchors]) ...
//   attachable(anchor, spin, [orient], two_d, path, [extent], [offset], [anchors] ...
//   attachable(anchor, spin, [orient], size, [size2], [shift], [offset], [anchors] ...
//   attachable(anchor, spin, [orient], r|d, l, [offset], [anchors]) ...
//   attachable(anchor, spin, [orient], r1|d1, r2|d2, l, [offset], [anchors]) ...
//   attachable(anchor, spin, [orient], r|d, [offset], [anchors]) ...
//   attachable(anchor, spin, [orient], vnf, [extent], [offset], [anchors]) ...
//
// Description:
//   Manages the anchoring, spin, orientation, and attachments for a 3D volume or 2D area.
//   A managed 3D volume is assumed to be vertically (Z-axis) oriented, and centered.
//   A managed 2D area is just assumed to be centered.  The shape to be managed is given
//   as the first child to this module, and the second child should be given as `children()`.
//   For example, to manage a conical shape:
//   ```openscad
//   attachable(anchor, spin, orient, r1=r1, r2=r2, l=h) {
//       cyl(r1=r1, r2=r2, l=h);
//       children();
//   }
//   ```
//   
//   If this is *not* run as a child of `attach()` with the `to` argument
//   given, then the following transformations are performed in order:
//   * Translates so the `anchor` point is at the origin (0,0,0).
//   * Rotates around the Z axis by `spin` degrees counter-clockwise.
//   * Rotates so the top of the part points towards the vector `orient`.
//   
//   If this is called as a child of `attach(from,to)`, then the info
//   for the anchor points referred to by `from` and `to` are fetched,
//   which will include position, direction, and spin.  With that info,
//   the following transformations are performed:
//   * Translates this part so it's anchor position matches the parent's anchor position.
//   * Rotates this part so it's anchor direction vector exactly opposes the parent's anchor direction vector.
//   * Rotates this part so it's anchor spin matches the parent's anchor spin.
//
// Arguments:
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
//   size = If given as a 3D vector, contains the XY size of the bottom of the cuboidal/prismoidal volume, and the Z height.  If given as a 2D vector, contains the front X width of the rectangular/trapezoidal shape, and the Y length.
//   size2 = If given as a 2D vector, contains the XY size of the top of the prismoidal volume.  If given as a number, contains the back width of the trapezoidal shape.
//   shift = If given as a 2D vector, shifts the top of the prismoidal or conical shape by the given amount.  If given as a number, shifts the back of the trapezoidal shape right by that amount.  Default: No shift.
//   r = Radius of the cylindrical/conical volume.
//   d = Diameter of the cylindrical/conical volume.
//   r1 = Radius of the bottom of the conical volume.
//   r2 = Radius of the top of the conical volume.
//   d1 = Diameter of the bottom of the conical volume.
//   d2 = Diameter of the top of the conical volume.
//   l = Length of the cylindrical/conical volume along axis.
//   vnf = The [VNF](vnf.scad) of the volume.
//   path = The path to generate a polygon from.
//   extent = If true, calculate anchors by extents, rather than intersection.  Default: false.
//   offset = If given, offsets the center of the volume.
//   anchors = If given as a list of anchor points, allows named anchor points.
//   two_d = If true, the attachable shape is 2D.  If false, 3D.  Default: false (3D)
//
// Side Effects:
//   `$parent_anchor` is set to the parent object's `anchor` value.
//   `$parent_spin` is set to the parent object's `spin` value.
//   `$parent_orient` is set to the parent object's `orient` value.
//   `$parent_geom` is set to the parent object's `geom` value.
//   `$parent_size` is set to the parent object's cubical `[X,Y,Z]` volume size.
//
// Example(NORENDER): Cubical Shape
//   attachable(anchor, spin, orient, size=size) {
//       cube(size, center=true);
//       children();
//   }
//
// Example(NORENDER): Prismoidal Shape
//   attachable(
//       anchor, spin, orient,
//       size=point3d(botsize,h),
//       size2=topsize,
//       shift=shift
//   ) {
//       prismoid(botsize, topsize, h=h, shift=shift);
//       children();
//   }
//
// Example(NORENDER): Cylindrical Shape
//   attachable(anchor, spin, orient, r=r, l=h) {
//       cyl(r=r, l=h);
//       children();
//   }
//
// Example(NORENDER): Conical Shape
//   attachable(anchor, spin, orient, r1=r1, r2=r2, l=h) {
//       cyl(r1=r1, r2=r2, l=h);
//       children();
//   }
//
// Example(NORENDER): Spherical Shape
//   attachable(anchor, spin, orient, r=r) {
//       staggered_sphere(r=r);
//       children();
//   }
//
// Example(NORENDER): Arbitrary VNF Shape
//   attachable(anchor, spin, orient, vnf=vnf) {
//       vnf_polyhedron(vnf);
//       children();
//   }
//
// Example(NORENDER): 2D Rectangular Shape
//   attachable(anchor, spin, orient, size=size) {
//       square(size, center=true);
//       children();
//   }
//
// Example(NORENDER): 2D Trapezoidal Shape
//   attachable(
//       anchor, spin, orient,
//       size=[x1,y],
//       size2=x2,
//       shift=shift
//   ) {
//       trapezoid(w1=x1, w2=x2, h=y, shift=shift);
//       children();
//   }
//
// Example(NORENDER): 2D Circular Shape
//   attachable(anchor, spin, orient, two_d=true, r=r) {
//       circle(r=r);
//       children();
//   }
//
// Example(NORENDER): Arbitrary 2D Polygon Shape
//   attachable(anchor, spin, orient, path=path) {
//       polygon(path);
//       children();
//   }
module attachable(
	anchor=CENTER,
	spin=0,
	orient=UP,
	size, size2, shift,
	r,r1,r2, d,d1,d2, l,h,
	vnf, path,
	extent=true,
	offset=[0,0,0],
	anchors=[],
	two_d=false
) {
	assert($children==2, "attachable() expects exactly two children; the shape to manage, and the union of all attachment candidates.");
	assert(!is_undef(anchor), str("anchor undefined in attachable().  Did you forget to set a default value for anchor in ", parent_module(1)));
	assert(!is_undef(spin), str("spin undefined in attachable().  Did you forget to set a default value for spin in ", parent_module(1)));
	assert(!is_undef(orient), str("orient undefined in attachable().  Did you forget to set a default value for orient in ", parent_module(1)));
	geom = attach_geom(
		size=size, size2=size2, shift=shift,
		r=r, r1=r1, r2=r2, h=h,
		d=d, d1=d1, d2=d2, l=l,
		vnf=vnf, path=path, extent=extent,
		offset=offset, anchors=anchors,
		two_d=two_d
	);
	m = attach_transform(anchor,spin,orient,geom);
	multmatrix(m) {
		$parent_anchor = anchor;
		$parent_spin   = spin;
		$parent_orient = orient;
		$parent_geom   = geom;
		$parent_size   = attach_geom_size(geom);
		$attach_to   = undef;
		if (attachment_is_shown($tags)) {
			if (is_undef($color)) {
				children(0);
			} else color($color) {
				$color = undef;
				children(0);
			}
		}
		children(1);
	}
}



// Section: Attachment Positioning

// Module: position()
// Usage:
//   position(from, [overlap]) ...
// Description:
//   Attaches children to a parent object at an anchor point.
// Arguments:
//   from = The vector, or name of the parent anchor point to attach to.
// Example:
//   spheroid(d=20) {
//       position(TOP) cyl(l=10, d1=10, d2=5, anchor=BOTTOM);
//       position(RIGHT) cyl(l=10, d1=10, d2=5, anchor=BOTTOM);
//       position(FRONT) cyl(l=10, d1=10, d2=5, anchor=BOTTOM);
//   }
module position(from)
{
	assert($parent_geom != undef, "No object to attach to!");
	anchors = (is_vector(from)||is_string(from))? [from] : from;
	for (anchr = anchors) {
		anch = find_anchor(anchr, $parent_geom);
		$attach_to = undef;
		$attach_anchor = anch;
		$attach_norot = true;
		translate(anch[1]) children();
	}
}


// Module: attach()
// Usage:
//   attach(from, [overlap]) ...
//   attach(from, to, [overlap]) ...
// Description:
//   Attaches children to a parent object at an anchor point and orientation.
//   Attached objects will be overlapped into the parent object by a little bit,
//   as specified by the default `$overlap` value (0.01 by default), or by the
//   overriding `overlap=` argument.  This is to prevent OpenSCAD from making
//   non-manifold objects.  You can also define `$overlap=` as an argument in a
//   parent module to set the default for all attachments to it.
// Arguments:
//   from = The vector, or name of the parent anchor point to attach to.
//   to = Optional name of the child anchor point.  If given, orients the child such that the named anchors align together rotationally.
//   overlap = Amount to sink child into the parent.  Equivalent to `down(X)` after the attach.  This defaults to the value in `$overlap`, which is `0.01` by default.
//   norot = If true, don't rotate children when attaching to the anchor point.  Only translate to the anchor point.
// Example:
//   spheroid(d=20) {
//       attach(TOP) down(1.5) cyl(l=11.5, d1=10, d2=5, anchor=BOTTOM);
//       attach(RIGHT, BOTTOM) down(1.5) cyl(l=11.5, d1=10, d2=5);
//       attach(FRONT, BOTTOM, overlap=1.5) cyl(l=11.5, d1=10, d2=5);
//   }
module attach(from, to=undef, overlap=undef, norot=false)
{
	assert($parent_geom != undef, "No object to attach to!");
	overlap = (overlap!=undef)? overlap : $overlap;
	anchors = (is_vector(from)||is_string(from))? [from] : from;
	for (anchr = anchors) {
		anch = find_anchor(anchr, $parent_geom);
		two_d = attach_geom_2d($parent_geom);
		$attach_to = to;
		$attach_anchor = anch;
		$attach_norot = norot;
		if (norot || (norm(anch[2]-UP)<1e-9 && anch[3]==0)) {
			translate(anch[1]) translate([0,0,-overlap]) children();
		} else {
			fromvec = two_d? BACK : UP;
			translate(anch[1]) rot(anch[3],from=fromvec,to=anch[2]) translate([0,0,-overlap]) children();
		}
	}
}


// Module: edge_profile()
// Usage:
//   edge_profile([edges], [except], [convexity]) ...
// Description:
//   Takes a 2D mask shape and attaches it to the selected edges, with the appropriate orientation
//   and extruded length to be `diff()`ed away, to give the edge a matching profile.
// Arguments:
//   edges = Edges to mask.  See the docs for [`edges()`](edges.scad#edges) to see acceptable values.  Default: All edges.
//   except = Edges to explicitly NOT mask.  See the docs for [`edges()`](edges.scad#edges) to see acceptable values.  Default: No edges.
//   convexity = Max number of times a line could intersect the perimeter of the mask shape.  Default: 10
// Side Effects:
//   Sets `$tags = "mask"` for all children.
// Example:
//   diff("mask")
//   cube([50,60,70],center=true)
//       edge_profile([TOP,"Z"],except=[BACK,TOP+LEFT])
//           mask2d_roundover(r=10, inset=2);
module edge_profile(edges=EDGES_ALL, except=[], convexity=10) {
	assert($parent_geom != undef, "No object to attach to!");
	edges = edges(edges, except=except);
	vecs = [
		for (i = [0:3], axis=[0:2])
		if (edges[axis][i]>0)
		EDGE_OFFSETS[axis][i]
	];
	for (vec = vecs) {
		vcount = (vec.x?1:0) + (vec.y?1:0) + (vec.z?1:0);
		assert(vcount == 2, "Not an edge vector!");
		anch = find_anchor(vec, $parent_geom);
		$attach_to = undef;
		$attach_anchor = anch;
		$attach_norot = true;
		$tags = "mask";
		length = sum(vmul($parent_size, [for (x=vec) x?0:1]))+0.1;
		rotang =
			vec.z<0? [90,0,180+vang(point2d(vec))] :
			vec.z==0 && sign(vec.x)==sign(vec.y)? 135+vang(point2d(vec)) :
			vec.z==0 && sign(vec.x)!=sign(vec.y)? [0,180,45+vang(point2d(vec))] :
			[-90,0,180+vang(point2d(vec))];
		translate(anch[1]) {
			rot(rotang) {
				linear_extrude(height=length, center=true, convexity=convexity) {
					children();
				}
			}
		}
	}
}

// Module: corner_profile()
// Usage:
//   corner_profile([corners], [except], [convexity]) ...
// Description:
//   Takes a 2D mask shape, rotationally extrudes and converts it into a corner mask, and attaches it
//   to the selected corners with the appropriate orientation.  Tags it as a "mask" to allow it to be
//   `diff()`ed away, to give the corner a matching profile.
// Arguments:
//   corners = Edges to mask.  See the docs for [`corners()`](edges.scad#corners) to see acceptable values.  Default: All corners.
//   except = Edges to explicitly NOT mask.  See the docs for [`corners()`](edges.scad#corners) to see acceptable values.  Default: No corners.
//   r = Radius of corner mask.
//   d = Diameter of corner mask.
//   convexity = Max number of times a line could intersect the perimeter of the mask shape.  Default: 10
// Side Effects:
//   Sets `$tags = "mask"` for all children.
// Example:
//   diff("mask")
//   cuboid([50,60,70],rounding=10,edges="Z",anchor=CENTER) {
//   	corner_profile(BOT,r=10)
//   		mask2d_teardrop(r=10, angle=40);
//   }
module corner_profile(corners=CORNERS_ALL, except=[], r, d, convexity=10) {
	assert($parent_geom != undef, "No object to attach to!");
	r = get_radius(r=r, d=d, dflt=undef);
	assert(is_num(r));
	corners = corners(corners, except=except);
	vecs = [for (i = [0:7]) if (corners[i]>0) CORNER_OFFSETS[i]];
	for (vec = vecs) {
		vcount = (vec.x?1:0) + (vec.y?1:0) + (vec.z?1:0);
		assert(vcount == 3, "Not an edge vector!");
		anch = find_anchor(vec, $parent_geom);
		$attach_to = undef;
		$attach_anchor = anch;
		$attach_norot = true;
		$tags = "mask";
		rotang = vec.z<0?
			[  0,0,180+vang(point2d(vec))-45] :
			[180,0,-90+vang(point2d(vec))-45];
		translate(anch[1]) {
			rot(rotang) {
				render(convexity=convexity)
				difference() {
					translate(-0.1*[1,1,1]) cube(r+0.1, center=false);
					right(r) back(r) zrot(180) {
						rotate_extrude(angle=90, convexity=convexity) {
							xflip() left(r) {
								difference() {
									square(r,center=false);
									children();
								}
							}
						}
					}
				}
			}
		}
	}
}




// Module: edge_mask()
// Usage:
//   edge_mask([edges], [except]) ...
// Description:
//   Takes a 3D mask shape, and attaches it to the given edges, with the
//   appropriate orientation to be `diff()`ed away.
// Arguments:
//   edges = Edges to mask.  See the docs for [`edges()`](edges.scad#edges) to see acceptable values.  Default: All edges.
//   except = Edges to explicitly NOT mask.  See the docs for [`edges()`](edges.scad#edges) to see acceptable values.  Default: No edges.
// Side Effects:
//   Sets `$tags = "mask"` for all children.
// Example:
//   diff("mask")
//   cube([50,60,70],center=true)
//       edge_mask([TOP,"Z"],except=[BACK,TOP+LEFT])
//           rounding_mask_z(l=71,r=10);
module edge_mask(edges=EDGES_ALL, except=[]) {
	assert($parent_geom != undef, "No object to attach to!");
	edges = edges(edges, except=except);
	vecs = [
		for (i = [0:3], axis=[0:2])
		if (edges[axis][i]>0)
		EDGE_OFFSETS[axis][i]
	];
	for (vec = vecs) {
		vcount = (vec.x?1:0) + (vec.y?1:0) + (vec.z?1:0);
		assert(vcount == 2, "Not an edge vector!");
		anch = find_anchor(vec, $parent_geom);
		$attach_to = undef;
		$attach_anchor = anch;
		$attach_norot = true;
		$tags = "mask";
		rotang =
			vec.z<0? [90,0,180+vang(point2d(vec))] :
			vec.z==0 && sign(vec.x)==sign(vec.y)? 135+vang(point2d(vec)) :
			vec.z==0 && sign(vec.x)!=sign(vec.y)? [0,180,45+vang(point2d(vec))] :
			[-90,0,180+vang(point2d(vec))];
		translate(anch[1]) rot(rotang) children();
	}
}


// Module: corner_mask()
// Usage:
//   corner_mask([corners], [except]) ...
// Description:
//   Takes a 3D mask shape, and attaches it to the given corners, with the appropriate
//   orientation to be `diff()`ed away.  The 3D corner mask shape should be designed to
//   mask away the X+Y+Z+ octant.
// Arguments:
//   corners = Edges to mask.  See the docs for [`corners()`](edges.scad#corners) to see acceptable values.  Default: All corners.
//   except = Edges to explicitly NOT mask.  See the docs for [`corners()`](edges.scad#corners) to see acceptable values.  Default: No corners.
// Side Effects:
//   Sets `$tags = "mask"` for all children.
// Example:
//   diff("mask")
//   cube(100, center=true)
//       corner_mask([TOP,FRONT],LEFT+FRONT+TOP)
//           difference() {
//               translate(-0.01*[1,1,1]) cube(20);
//               translate([20,20,20]) sphere(r=20);
//           }
module corner_mask(corners=CORNERS_ALL, except=[]) {
	assert($parent_geom != undef, "No object to attach to!");
	corners = corners(corners, except=except);
	vecs = [for (i = [0:7]) if (corners[i]>0) CORNER_OFFSETS[i]];
	for (vec = vecs) {
		vcount = (vec.x?1:0) + (vec.y?1:0) + (vec.z?1:0);
		assert(vcount == 3, "Not an edge vector!");
		anch = find_anchor(vec, $parent_geom);
		$attach_to = undef;
		$attach_anchor = anch;
		$attach_norot = true;
		$tags = "mask";
		rotang = vec.z<0?
			[  0,0,180+vang(point2d(vec))-45] :
			[180,0,-90+vang(point2d(vec))-45];
		translate(anch[1]) rot(rotang) children();
	}
}


// Module: tags()
// Usage:
//   tags(tags) ...
// Description:
//   Marks all children with the given tags.
// Arguments:
//   tags = String containing space delimited set of tags to apply.
module tags(tags)
{
	$tags = tags;
	children();
}


// Module: recolor()
// Usage:
//   recolor(c) ...
// Description:
//   Sets the color for children that can use the $color special variable.
// Arguments:
//   c = Color name or RGBA vector.
// Example:
//   recolor("red") cyl(l=20, d=10);
module recolor(c)
{
	$color = c;
	children();
}


// Module: hide()
// Usage:
//   hide(tags) ...
// Description:
//   Hides all children with the given tags.
// Example:
//   hide("A") cube(50, anchor=CENTER, $tags="Main") {
//       attach(LEFT, BOTTOM) cylinder(d=30, l=30, $tags="A");
//       attach(RIGHT, BOTTOM) cylinder(d=30, l=30, $tags="B");
//   }
module hide(tags="")
{
	$tags_hidden = tags==""? [] : str_split(tags, " ");
	children();
}


// Module: show()
// Usage:
//   show(tags) ...
// Description:
//   Shows only children with the given tags.
// Example:
//   show("A B") cube(50, anchor=CENTER, $tags="Main") {
//       attach(LEFT, BOTTOM) cylinder(d=30, l=30, $tags="A");
//       attach(RIGHT, BOTTOM) cylinder(d=30, l=30, $tags="B");
//   }
module show(tags="")
{
	$tags_shown = tags==""? [] : str_split(tags, " ");
	children();
}


// Module: diff()
// Usage:
//   diff(neg, [keep]) ...
//   diff(neg, pos, [keep]) ...
// Description:
//   If `neg` is given, takes the union of all children with tags
//   that are in `neg`, and differences them from the union of all
//   children with tags in `pos`.  If `pos` is not given, then all
//   items in `neg` are differenced from all items not in `neg`.  If
//   `keep` is given, all children with tags in `keep` are then unioned
//   with the result.  If `keep` is not given, all children without
//   tags in `pos` or `neg` are then unioned with the result.
// Arguments:
//   neg = String containing space delimited set of tag names of children to difference away.
//   pos = String containing space delimited set of tag names of children to be differenced away from.
//   keep = String containing space delimited set of tag names of children to keep whole.
// Example:
//   diff("neg", "pos", keep="axle")
//   sphere(d=100, $tags="pos") {
//       attach(CENTER) xcyl(d=40, l=120, $tags="axle");
//       attach(CENTER) cube([40,120,100], anchor=CENTER, $tags="neg");
//   }
// Example: Masking
//   diff("mask")
//   cube([80,90,100], center=true) {
//       let(p = $parent_size*1.01, $tags="mask") {
//           position([for (y=[-1,1],z=[-1,1]) [0,y,z]])
//               rounding_mask_x(l=p.x, r=25);
//           position([for (x=[-1,1],z=[-1,1]) [x,0,z]])
//               rounding_mask_y(l=p.y, r=20);
//           position([for (x=[-1,1],y=[-1,1]) [x,y,0]])
//               rounding_mask_z(l=p.z, r=25);
//       }
//   }
module diff(neg, pos=undef, keep=undef)
{
	difference() {
		if (pos != undef) {
			show(pos) children();
		} else {
			if (keep == undef) {
				hide(neg) children();
			} else {
				hide(str(neg," ",keep)) children();
			}
		}
		show(neg) children();
	}
	if (keep!=undef) {
		show(keep) children();
	} else if (pos!=undef) {
		hide(str(pos," ",neg)) children();
	}
}


// Module: intersect()
// Usage:
//   intersect(a, [keep]) ...
//   intersect(a, b, [keep]) ...
// Description:
//   If `a` is given, takes the union of all children with tags that
//   are in `a`, and intersection()s them with the union of all
//   children with tags in `b`.  If `b` is not given, then the union
//   of all items with tags in `a` are intersection()ed with the union
//   of all items without tags in `a`.  If `keep` is given, then the
//   result is unioned with all the children with tags in `keep`.  If
//   `keep` is not given, all children without tags in `a` or `b` are
//   unioned with the result.
// Arguments:
//   a = String containing space delimited set of tag names of children.
//   b = String containing space delimited set of tag names of children.
//   keep = String containing space delimited set of tag names of children to keep whole.
// Example:
//   intersect("wheel", "mask", keep="axle")
//   sphere(d=100, $tags="wheel") {
//       attach(CENTER) cube([40,100,100], anchor=CENTER, $tags="mask");
//       attach(CENTER) xcyl(d=40, l=100, $tags="axle");
//   }
module intersect(a, b=undef, keep=undef)
{
	intersection() {
		if (b != undef) {
			show(b) children();
		} else {
			if (keep == undef) {
				hide(a) children();
			} else {
				hide(str(a," ",keep)) children();
			}
		}
		show(a) children();
	}
	if (keep!=undef) {
		show(keep) children();
	} else if (b!=undef) {
		hide(str(a," ",b)) children();
	}
}



// Module: hulling()
// Usage:
//   hulling(a, [keep]) ...
// Description:
//   Takes the union of all children with tags that are in `a`, and hull()s them.
//   If `keep` is given, then the result is unioned with all the children with
//   tags in `keep`.  If `keep` is not given, all children without tags in `a` are
//   unioned with the result.
// Arguments:
//   a = String containing space delimited set of tag names of children.
//   keep = String containing space delimited set of tag names of children to keep whole.
// Example:
//   hulling("body")
//   sphere(d=100, $tags="body") {
//       attach(CENTER) cube([40,90,90], anchor=CENTER, $tags="body");
//       attach(CENTER) xcyl(d=40, l=120, $tags="other");
//   }
module hulling(a)
{
	hull() show(a) children();
	children();
}



// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
