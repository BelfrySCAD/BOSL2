//////////////////////////////////////////////////////////////////////
// LibFile: attachments.scad
//   This is the file that handles attachments and orientation of children.
//   To use, add the following lines to the beginning of your file:
//   ```
//   include <BOSL2/std.scad>
//   ```
//////////////////////////////////////////////////////////////////////


// Default values for attachment code.
$slop = 0.20;
$tags = "";
$overlap = 0.01;
$color = undef;

$attach_to = undef;
$attach_anchor = [CENTER, CENTER, UP, 0];
$attach_norot = false;

$parent_size = undef;
$parent_size2 = undef;
$parent_shift = [0,0];
$parent_anchors = [];
$parent_anchor = BOTTOM;
$parent_orient = UP;

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



// Function: find_anchor()
// Usage:
//   find_anchor(anchor, h, size, [size2], [shift], [edges], [corners]);
// Description:
//   Returns anchor data for the given vector or anchor name.
// Arguments:
//   anchor = Vector or named anchor string.
//   h = Height of the region.
//   size = The [X,Y] size of the bottom of the cubical region.
//   size2 = The [X,Y] size of the top of the cubical region.
//   shift = The [X,Y] amount to shift the center of the top with respect to the center of the bottom.
//   offset = The offset of the center of the object from the CENTER anchor.
//   geometry = One of "cube", "cylinder", or "sphere" to denote the overall geometry of the shape.  Cones are "cylinder", and prismoids are "cube" for this purpose.  Default: "cube"
//   anchors = A list of extra non-standard named anchors.
//   two_d = If true, object will be treated as 2D.
function find_anchor(anchor, h, size, size2=undef, shift=[0,0], offset=[0,0,0], anchors=[], geometry="cube", two_d=false) =
	is_string(anchor)? (
		let(found = search([anchor], anchors, num_returns_per_match=1)[0])
		assert(found!=[], str("Unknown anchor: ",anchor))
		anchors[found]
	) : (
		assert(is_vector(anchor),str("anchor=",anchor))
		let(
			size = point2d(size),
			size2 = (size2!=undef)? point2d(size2) : size,
			shift = point2d(shift),
			oang = (
				two_d? 0 :
				anchor == UP? 0 :
				anchor == DOWN? 0 :
				(norm([anchor.x,anchor.y]) < EPSILON)? 0 :
				atan2(anchor.y, anchor.x)+90
			)
		)
		geometry=="sphere"? let(
			phi = (anchor==UP||anchor==CENTER)? 0 : anchor==DOWN? 180 : 90 + (45 * anchor.z),
			theta = anchor==CENTER? 90 : atan2(anchor.y, anchor.x),
			vec = spherical_to_xyz(1, theta, phi),
			offset = vmul(offset,vabs(anchor)),
			pos = anchor==CENTER? CENTER : vmul(vec, (point3d(size)+h*UP)/2) + offset
		) [anchor, pos, vec, oang] : let (
			xyal = (
				geometry=="cylinder"? (
					let(xy = point2d(anchor))
					norm(xy)>0? xy/norm(xy) : [0,0]
				) : point2d(anchor)
			),
			botpt = point3d(vmul(size/2,xyal))+DOWN*h/2,
			toppt = point3d(vmul(size2/2,xyal)+shift)+UP*h/2,
			offset = vmul(offset,vabs(anchor)),
			pos = lerp(botpt, toppt, (anchor.z+1)/2) + offset,
			sidevec = two_d? point3d(xyal) :
				approx(norm(xyal),0)? [0,0,0] :
				rotate_points3d([point3d(xyal)], from=UP, to=toppt-botpt)[0],
			vec = (
				two_d? sidevec :
				anchor==CENTER? UP :
				norm([anchor.x,anchor.y]) < EPSILON? anchor :
				norm(size)+norm(size2) < EPSILON? anchor :
				abs(anchor.z) < EPSILON? sidevec :
				anchor.z>0? (UP+sidevec)/2 :
				(DOWN+sidevec)/2
			)
		) [anchor, pos, vec, oang]
	);



function _str_char_split(s,delim,n=0,acc=[],word="") =
	(n>=len(s))? concat(acc, [word]) :
	(s[n]==delim)?
		_str_char_split(s,delim,n+1,concat(acc,[word]),"") :
		_str_char_split(s,delim,n+1,acc,str(word,s[n]));



// Section: Modules


// Module: orient_and_anchor()
//
// Description:
//   Takes a vertically oriented part and anchors, spins and orients it.
//   This is useful for making a custom shape available in various
//   orientations and anchorings without extra translate()s and rotate()s.
//   Children should be vertically (Z-axis) oriented, and centered.
//   Non-vector anchor points should be named via the `anchors` arg.
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
// Usage:
//   orient_and_anchor(size, [anchor], [spin], [orient], [center], [noncentered], [anchors], [chain]) ...
//
// Arguments:
//   size = The [X,Y,Z] size of the part.
//   size2 = The [X,Y] size of the top of the part.
//   shift = The [X,Y] offset of the top of the part, compared to the bottom of the part.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
//   center = If given, overrides `anchor`.  If true, centers vertically.  If false, `anchor` will be set to the value in `noncentered`.
//   noncentered = The value to set `anchor` to if `center` == `false`.  Default: `BOTTOM`.
//   offset = The offset of the center of the object from the CENTER anchor.
//   geometry = One of "cube", "cylinder", or "sphere" to denote the overall geometry of the shape.  Cones are "cylinder", and prismoids are "cube" for this purpose.  Default: "cube"
//   anchors = A list of extra, non-standard optional anchors.
//   chain = If true, allow attachable children.
//   two_d = If true, object will be treated as 2D.
//
// Side Effects:
//   `$parent_size` is set to the parent object's cubical region size.
//   `$parent_size2` is set to the parent object's top [X,Y] size.
//   `$parent_shift` is set to the parent object's `shift` value, if any.
//   `$parent_geom` is set to the parent object's `geometry` value.
//   `$parent_orient` is set to the parent object's `orient` value.
//   `$parent_anchor` is set to the parent object's `anchor` value.
//   `$parent_anchors` is set to the parent object's list of non-standard extra anchors.
//   `$parent_2d` is set to the parent object's `two_d` value.
//
// Example(Med):
//   #cylinder(d1=50, d2=30, h=60);
//   orient_and_anchor(size=[50,50,60], size2=[30,30], anchor=RIGHT, orient=FWD)
//       cylinder(d1=50, d2=30, h=60);
module orient_and_anchor(
	size=undef,
	orient=UP,
	anchor=CENTER,
	center=undef,
	noncentered=BOTTOM,
	spin=0,
	size2=undef,
	shift=[0,0],
	offset=[0,0,0],
	geometry="cube",
	anchors=[],
	chain=false,
	two_d=false
) {
	size2 = point2d(default(size2, size));
	shift = point2d(shift);
	anchr = is_undef(center)? anchor : (center? CENTER : noncentered);
	pos = find_anchor(anchr, size.z, size, size2=size2, shift=shift, offset=offset, anchors=anchors, geometry=geometry, two_d=two_d)[1];

	$parent_size   = size;
	$parent_size2  = size2;
	$parent_shift  = shift;
	$parent_geom   = geometry;
	$parent_orient = orient;
	$parent_offset = offset;
	$parent_2d     = two_d;
	$parent_anchor = anchr;
	$parent_anchors = anchors;

	tags = _str_char_split($tags, " ");
	s_tags = $tags_shown;
	h_tags = $tags_hidden;
	shown  = !s_tags || any([for (tag=tags) in_list(tag, s_tags)]);
	hidden = any([for (tag=tags) in_list(tag, h_tags)]);
	if ($attach_to != undef) {
		anch = find_anchor($attach_to, size.z, size, size2=size2, shift=shift, offset=offset, anchors=anchors, geometry=geometry, two_d=two_d);
		ang = vector_angle(anch[2], DOWN);
		axis = vector_axis(anch[2], DOWN);
		ang2 = (anch[2]==UP || anch[2]==DOWN)? 0 : 180-anch[3];
		axis2 = rotate_points3d([axis],[0,0,ang2])[0];
		$attach_to = undef;

		rot(ang, v=axis2)
		rotate(ang2+spin)
		translate(-anch[1])
		{
			if ($children>1 && chain) {
				if(shown && !hidden) {
					color($color) for (i=[0:1:$children-2]) children(i);
				}
				children($children-1);
			} else {
				if(shown && !hidden) color($color) children();
			}
		}
	} else {
		rot(from=UP,to=orient)
		rotate(spin)
		translate(-pos)
		{
			if ($children>1 && chain) {
				if(shown && !hidden) {
					color($color) for (i=[0:1:$children-2]) children(i);
				}
				children($children-1);
			} else {
				if(shown && !hidden) color($color) children();
			}
		}
	}
}



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
module position(from, overlap=undef, norot=false)
{
	assert($parent_size != undef, "No object to attach to!");
	anchors = (is_vector(from)||is_string(from))? [from] : from;
	for (anchr = anchors) {
		anch = find_anchor(anchr, $parent_size.z, point2d($parent_size), size2=$parent_size2, shift=$parent_shift, offset=$parent_offset, anchors=$parent_anchors, geometry=$parent_geom, two_d=$parent_2d);
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
// Arguments:
//   from = The vector, or name of the parent anchor point to attach to.
//   to = Optional name of the child anchor point.  If given, orients the child such that the named anchors align together rotationally.
//   overlap = Amount to sink child into the parent.  Equivalent to `down(X)` after the attach.
//   norot = If true, don't rotate children when attaching to the anchor point.  Only translate to the anchor point.
// Example:
//   spheroid(d=20) {
//       attach(TOP) down(1.5) cyl(l=11.5, d1=10, d2=5, anchor=BOTTOM);
//       attach(RIGHT, BOTTOM) down(1.5) cyl(l=11.5, d1=10, d2=5);
//       attach(FRONT, BOTTOM, overlap=1.5) cyl(l=11.5, d1=10, d2=5);
//   }
module attach(from, to=undef, overlap=undef, norot=false)
{
	assert($parent_size != undef, "No object to attach to!");
	overlap = (overlap!=undef)? overlap : $overlap;
	anchors = (is_vector(from)||is_string(from))? [from] : from;
	for (anchr = anchors) {
		anch = find_anchor(anchr, $parent_size.z, point2d($parent_size), size2=$parent_size2, shift=$parent_shift, offset=$parent_offset, anchors=$parent_anchors, geometry=$parent_geom, two_d=$parent_2d);
		$attach_to = to;
		$attach_anchor = anch;
		$attach_norot = norot;
		if (norot || (norm(anch[2]-UP)<1e-9 && anch[3]==0)) {
			translate(anch[1]) translate([0,0,-overlap]) children();
		} else {
			fromvec = $parent_2d? BACK : UP;
			translate(anch[1]) rot(anch[3],from=fromvec,to=anch[2]) translate([0,0,-overlap]) children();
		}
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
	$tags_hidden = tags==""? [] : _str_char_split(tags, " ");
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
// Example:
//   diff("neg", "pos", keep="axle")
//   sphere(d=100, $tags="pos") {
//       attach(CENTER) xcyl(d=40, h=120, $tags="axle");
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
//       attach(CENTER) xcyl(d=40, h=100, $tags="axle");
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
//       attach(CENTER) xcyl(d=40, h=120, $tags="other");
//   }
module hulling(a)
{
	hull() show(a) children();
	children();
}



// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
