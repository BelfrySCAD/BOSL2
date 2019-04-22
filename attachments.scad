//////////////////////////////////////////////////////////////////////
// LibFile: attachments.scad
//   This is the file that handles attachments and orientation of children.
//   To use, add the following lines to the beginning of your file:
//   ```
//   include <BOSL2/std.scad>
//   ```
//////////////////////////////////////////////////////////////////////

/*
BSD 2-Clause License

Copyright (c) 2017-2019, Revar Desmera
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/



// Section: Functions


// Function: connector()
// Usage:
//   connector(name, pos, dir, [rot])
// Description:
//   Creates a connector data structure.
// Arguments:
//   name = The string name of the connector.  Lowercase.  Words separated by single dashes.  No spaces.
//   pos = The [X,Y,Z] position of the connector.
//   dir = A vector pointing in the direction parts should project from the connector position.
//   rot = If needed, the angle to rotate the part around the direction vector.
function connector(name, pos=[0,0,0], dir=UP, rot=0) = [name, pos, dir, rot];



// Function: find_connector()
// Usage:
//   find_connector(align, h, size, [size2], [shift], [edges], [corners]);
// Description:
//   Generates a list of typical connectors for a cubical region of the given size.
// Arguments:
//   align = Named alignment/connector string.
//   h = Height of the region.
//   size = The [X,Y] size of the bottom of the cubical region.
//   size2 = The [X,Y] size of the top of the cubical region.
//   shift = The [X,Y] amount to shift the center of the top with respect to the center of the bottom.
//   geometry = One of "cube", "cylinder", or "sphere" to denote the overall geometry of the shape.  Cones are "cylinder", and prismoids are "cube" for this purpose.  Default: "cube"
//   extra_conns = A list of extra named connectors.
function find_connector(align, h, size, size2=undef, shift=[0,0], extra_conns=[], geometry="cube") =
	is_string(align)? (
		let(found = search([align], extra_conns, num_returns_per_match=1)[0])
		assert(found!=[], str("Unknown alignment: ",align))
		extra_conns[found]
	) : (
		let(
			size = point2d(size),
			size2 = (size2!=undef)? point2d(size2) : size,
			shift = point2d(shift),
			oang = (
				align == UP? 0 :
				align == DOWN? 0 :
				(norm([align.x,align.y]) < EPSILON)? 0 :
				atan2(align.y, align.x)+90
			)
		)
		geometry=="sphere"? let(
			phi = align==UP? 0 : align==DOWN? 180 : 90 + (45 * align.z),
			theta = atan2(align.y, align.x),
			vec = spherical_to_xyz(1, theta, phi),
			pos = vmul(vec, (point3d(size)+h*UP)/2)
		) [align, pos, vec, oang] : let (
			xyal = (
				geometry=="cylinder"? (
					let(xy = point2d(align))
					norm(xy)>0? xy/norm(xy) : [0,0]
				) : point2d(align)
			),
			botpt = point3d(vmul(size/2,xyal))+DOWN*h/2,
			toppt = point3d(vmul(size2/2,xyal)+shift)+UP*h/2,
			pos = lerp(botpt, toppt, (align.z+1)/2),
			sidevec = rotate_points3d([point3d(xyal)], from=UP, to=toppt-botpt)[0],
			vec = (
				norm([align.x,align.y]) < EPSILON? align :
				abs(align.z) < EPSILON? sidevec :
				align.z>0? (UP+sidevec)/2 :
				(DOWN+sidevec)/2
			)
		) [align, pos, vec, oang]
	);



function _str_char_split(s,delim,n=0,acc=[],word="") =
	(n>=len(s))? concat(acc, [word]) :
	(s[n]==delim)?
		_str_char_split(s,delim,n+1,concat(acc,[word]),"") :
		_str_char_split(s,delim,n+1,acc,str(word,s[n]));



// Section: Modules


// Module: orient_and_align()
//
// Description:
//   Takes a vertically oriented shape, and re-orients and aligns it.
//   This is useful for making a custom shape available in various
//   orientations and alignments without extra translate()s and rotate()s.
//   Children should be vertically (Z-axis) oriented, and centered.
//   Non-extremity alignment points should be named via the `alignments` arg.
//   Named alignments are aligned pre-rotation.
//
// Usage:
//   orient_and_align(size, [orient], [align], [center], [noncentered], [orig_orient], [orig_align], [alignments], [chain]) ...
//
// Arguments:
//   size = The [X,Y,Z] size of the part.
//   size2 = The [X,Y] size of the top of the part.
//   shift = The [X,Y] offset of the top of the part, compared to the bottom of the part.
//   orient = The axis to align to.  Use `ORIENT_` constants from `constants.scad`.
//   align = The side of the origin the part should be aligned with.
//   center = If given, overrides `align`.  If true, centers vertically.  If false, `align` will be set to the value in `noncentered`.
//   noncentered = The value to set `align` to if `center` == `false`.  Default: `BOTTOM`.
//   orig_orient = The original orientation of the part.  Default: `ORIENT_Z`.
//   orig_align = The original alignment of the part.  Default: `CENTER`.
//   geometry = One of "cube", "cylinder", or "sphere" to denote the overall geometry of the shape.  Cones are "cylinder", and prismoids are "cube" for this purpose.  Default: "cube"
//   alignments = A list of extra, non-standard connectors that can be aligned to.
//   chain = If true, allow attachable children.
//
// Side Effects:
//   `$parent_size` is set to the parent object's cubical region size.
//   `$parent_size2` is set to the parent object's top [X,Y] size.
//   `$parent_shift` is set to the parent object's `shift` value, if any.
//   `$parent_orient` is set to the parent object's `orient` value.
//   `$parent_align` is set to the parent object's `align` value.
//   `$parent_geom` is set to the parent object's `geometry` value.
//   `$parent_conns` is set to the parent object's list of non-standard extra connectors.
//
// Example:
//   #cylinder(d=5, h=10);
//   orient_and_align([5,5,10], orient=ORIENT_Y, align=BACK, orig_align=UP) cylinder(d=5, h=10);
module orient_and_align(
	size=undef, orient=ORIENT_Z, align=CENTER,
	center=undef, noncentered=BOTTOM,
	orig_orient=ORIENT_Z, orig_align=CENTER,
	size2=undef, shift=[0,0],
	alignments=[], chain=false,
	geometry="cube"
) {
	size2 = point2d(default(size2, size));
	shift = point2d(shift);
	align = !is_undef(center)? (center? CENTER : noncentered) : align;
	m = matrix4_mult(concat(
		(orig_align==CENTER)? [] : [
			// If original alignment is not centered, center it.
			matrix4_translate(vmul(size/2, -orig_align))
		],
		(orig_orient==ORIENT_Z)? [] : [
			// If original orientation is not upright, rotate it upright.
			matrix4_zrot(-orig_orient.z),
			matrix4_yrot(-orig_orient.y),
			matrix4_xrot(-orig_orient.x)
		],
		($attach_to!=undef)? (
			let(
				conn = find_connector($attach_to, size.z, size, size2=size2, shift=shift, geometry=geometry),
				ang = vector_angle(conn[2], DOWN),
				axis = vector_axis(conn[2], DOWN),
				ang2 = (conn[2]==UP || conn[2]==DOWN)? 0 : 180-conn[3],
				axis2 = rotate_points3d([axis],[0,0,ang2])[0]
			) [
				matrix4_translate(-conn[1]),
				matrix4_zrot(ang2),
				matrix4_rot_by_axis(axis2, ang)
			]
		) : concat(
			(align==CENTER)? [] : [
				let(conn = find_connector(align, size.z, size, size2=size2, shift=shift, extra_conns=alignments, geometry=geometry))
				matrix4_translate(-conn[1])
			],
			(orient==ORIENT_Z)? [] : [
				matrix4_xrot(orient.x),
				matrix4_yrot(orient.y),
				matrix4_zrot(orient.z)
			]
		)
	));
	$attach_to = undef;
	$parent_size   = size;
	$parent_size2  = size2;
	$parent_shift  = shift;
	$parent_orient = orient;
	$parent_align  = align;
	$parent_geom   = geometry;
	$parent_conns  = alignments;
	tags = _str_char_split($tags, " ");
	s_tags = $tags_shown;
	h_tags = $tags_hidden;
	shown  = !s_tags || any([for (tag=tags) in_list(tag, s_tags)]);
	hidden = any([for (tag=tags) in_list(tag, h_tags)]);
	multmatrix(m) {
		if ($children>1 && chain) {
			if(shown && !hidden) color($color) for (i=[0:$children-2]) children(i);
			children($children-1);
		} else {
			if(shown && !hidden) color($color) children();
		}
	}
}



// Module: attach()
// Usage:
//   attach(name, [overlap], [norot]) ...
//   attach(name, to, [overlap]) ...
// Description:
//   Attaches children to a parent object at an attachment point and orientation.
// Arguments:
//   name = The name of the parent attachment point to attach to.
//   to = The name of the child attachment point.
//   overlap = Amount to sink child into the parent.
//   norot = If true, don't rotate children when aligning to the attachment point.
// Example:
//   spheroid(d=20) {
//       attach(TOP)   down(1.5) cyl(l=11.5, d1=10, d2=5, align=BOTTOM);
//       attach(RIGHT, BOTTOM) down(1.5) cyl(l=11.5, d1=10, d2=5);
//       attach(FRONT) down(1.5) cyl(l=11.5, d1=10, d2=5, align=BOTTOM);
//   }
module attach(name, to=undef, overlap=undef, norot=false)
{
	assert($parent_size != undef, "No object to attach to!");
	overlap = (overlap!=undef)? overlap : $overlap;
	conn = find_connector(name, $parent_size.z, point2d($parent_size), size2=$parent_size2, shift=$parent_shift, extra_conns=$parent_conns, geometry=$parent_geom);
	pos = conn[1];
	vec = conn[2];
	ang = conn[3];
	$attach_to = to;
	$attach_conn = conn;
	if (norot || (norm(vec-UP)<1e-9 && ang==0)) {
		translate(pos) translate([0,0,-overlap]) children();
	} else {
		translate(pos) rot(ang,from=UP,to=vec) translate([0,0,-overlap]) children();
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
// Description: Hides all children with the given tags.
module hide(tags="")
{
	$tags_hidden = tags==""? [] : _str_char_split(tags, " ");
	children();
}


// Module: show()
// Usage:
//   show(tags) ...
// Description: Shows only children with the given tags.
module show(tags="")
{
	$tags_shown = tags==""? [] : _str_char_split(tags, " ");
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


// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
