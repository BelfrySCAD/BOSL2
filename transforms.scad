//////////////////////////////////////////////////////////////////////
// LibFile: transforms.scad
//   This is the file that the most commonly used transformations, distributors, and mutator are in.
//   To use, add the following lines to the beginning of your file:
//   ```
//   include <BOSL2/std.scad>
//   ```
//////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////
// Section: Translations
//////////////////////////////////////////////////////////////////////


// Function&Module: move()
//
// Description:
//   If called as a module, moves/translates all children.  If called as a function with the `pts`
//   argument, returns the translated point or list of points.  If called as a function without the
//   `pts` argument, returns an affine translation matrix, either 2D or 3D depending on the length
//   of the offset vector `a`.
//
// Usage: As Module
//   move([x], [y], [z]) ...
//   move(a) ...
// Usage: Translate Points
//   pts = move(a, p);
//   pts = move([x], [y], [z], p);
// Usage: Get Translation Matrix
//   mat = move(a);
//
// Arguments:
//   a = An [X,Y,Z] vector to translate by.
//   x = X axis translation.
//   y = Y axis translation.
//   z = Z axis translation.
//   p = Either a point, or a list of points to be translated when used as a function.
//
// Example:
//   #sphere(d=10);
//   move([0,20,30]) sphere(d=10);
//
// Example:
//   #sphere(d=10);
//   move(y=20) sphere(d=10);
//
// Example:
//   #sphere(d=10);
//   move(x=-10, y=-5) sphere(d=10);
//
// Example(NORENDER):
//   pt1 = move([0,20,30], p=[15,23,42]);       // Returns: [15, 43, 72]
//   pt2 = move(y=10, p=[15,23,42]);            // Returns: [15, 33, 42]
//   pt3 = move([0,3,1], p=[[1,2,3],[4,5,6]]);  // Returns: [[1,5,4], [4,8,7]]
//   pt4 = move(y=11, p=[[1,2,3],[4,5,6]]);     // Returns: [[1,13,3], [4,16,6]]
//   mat2d = move([2,3]);    // Returns: [[1,0,2],[0,1,3],[0,0,1]]
//   mat3d = move([2,3,4]);  // Returns: [[1,0,0,2],[0,1,0,3],[0,0,1,4],[0,0,0,1]]
module move(a=[0,0,0], x=0, y=0, z=0)
{
	translate(a+[x,y,z]) children();
}

function translate(a=[0,0,0], p=undef) = move(a=a, p=p);

function move(a=[0,0,0], p=undef, x=0, y=0, z=0) =
	is_undef(p)? (
		len(a)==2? affine2d_translate(a+[x,y]) :
		affine3d_translate(point3d(a)+[x,y,z])
	) : (
		is_vector(p)? p+a+[x,y,z] :
		[for (pt = p) pt+a+[x,y,z]]
	);


// Module: left()
//
// Description:
//   Moves children left (in the X- direction) by the given amount.
//
// Usage:
//   left(x) ...
//
// Arguments:
//   x = Scalar amount to move left.
//
// Example:
//   #sphere(d=10);
//   left(20) sphere(d=10);
module left(x=0) translate([-x,0,0]) children();


// Module: right()
//
// Description:
//   Moves children right (in the X+ direction) by the given amount.
//
// Usage:
//   right(x) ...
//
// Arguments:
//   x = Scalar amount to move right.
//
// Example:
//   #sphere(d=10);
//   right(20) sphere(d=10);
module right(x=0) translate([x,0,0]) children();


// Module: fwd()
//
// Description:
//   Moves children forward (in the Y- direction) by the given amount.
//
// Usage:
//   fwd(y) ...
//
// Arguments:
//   y = Scalar amount to move forward.
//
// Example:
//   #sphere(d=10);
//   fwd(20) sphere(d=10);
module fwd(y=0) translate([0,-y,0]) children();


// Module: back()
//
// Description:
//   Moves children back (in the Y+ direction) by the given amount.
//
// Usage:
//   back(y) ...
//
// Arguments:
//   y = Scalar amount to move back.
//
// Example:
//   #sphere(d=10);
//   back(20) sphere(d=10);
module back(y=0) translate([0,y,0]) children();


// Module: down()
//
// Description:
//   Moves children down (in the Z- direction) by the given amount.
//
// Usage:
//   down(z) ...
//
// Arguments:
//   z = Scalar amount to move down.
//
// Example:
//   #sphere(d=10);
//   down(20) sphere(d=10);
module down(z=0) translate([0,0,-z]) children();


// Module: up()
//
// Description:
//   Moves children up (in the Z+ direction) by the given amount.
//
// Usage:
//   up(z) ...
//
// Arguments:
//   z = Scalar amount to move up.
//
// Example:
//   #sphere(d=10);
//   up(20) sphere(d=10);
module up(z=0) translate([0,0,z]) children();



//////////////////////////////////////////////////////////////////////
// Section: Rotations
//////////////////////////////////////////////////////////////////////


// Function&Module: rot()
//
// Description:
//   When called as a module, rotates all children around an arbitrary axis by the given number of degrees.
//   Can be used as a drop-in replacement for `rotate()`, with extra features.
//   When called as a function with a `p` argument containing a point, returns the rotated point.
//   When called as a function with a `p` argument containing a list of points, returns the list of rotated points.
//   When called as a function without a `p` argument, returns the rotational matrix.  2D if planar is true, 3D otherwise.
//
// Usage:
//   rot(a, [cp], [reverse]) ...
//   rot([X,Y,Z], [cp], [reverse]) ...
//   rot(a, v, [cp], [reverse]) ...
//   rot(from, to, [a], [reverse]) ...
//
// Arguments:
//   a = Scalar angle or vector of XYZ rotation angles to rotate by, in degrees.
//   v = vector for the axis of rotation.  Default: [0,0,1] or UP
//   cp = centerpoint to rotate around. Default: [0,0,0]
//   from = Starting vector for vector-based rotations.
//   to = Target vector for vector-based rotations.
//   reverse = If true, exactly reverses the rotation, including axis rotation ordering.  Default: false
//   planar = If called as a function, this specifies if you want to work with 2D points.
//   p = If called as a function, this contains a point or list of points to rotate.
//
// Example:
//   #cube([2,4,9]);
//   rot([30,60,0], cp=[0,0,9]) cube([2,4,9]);
//
// Example:
//   #cube([2,4,9]);
//   rot(30, v=[1,1,0], cp=[0,0,9]) cube([2,4,9]);
//
// Example:
//   #cube([2,4,9]);
//   rot(from=UP, to=LEFT+BACK) cube([2,4,9]);
module rot(a=0, v=undef, cp=undef, from=undef, to=undef, reverse=false)
{
	if (!is_undef(cp)) {
		translate(cp) rot(a=a, v=v, from=from, to=to, reverse=reverse) translate(-cp) children();
	} else if (!is_undef(from)) {
		assert(!is_undef(to), "`from` and `to` should be used together.");
		from = point3d(from);
		to = point3d(to);
		axis = vector_axis(from, to);
		ang = vector_angle(from, to);
		if (ang < 0.0001 && a == 0) {
			children();  // May be slightly faster?
		} else if (reverse) {
			rotate(a=-ang, v=axis) rotate(a=-a, v=from) children();
		} else {
			rotate(a=ang, v=axis) rotate(a=a, v=from) children();
		}
	} else if (a == 0) {
		children();  // May be slightly faster?
	} else if (reverse) {
		if (!is_undef(v)) {
			rotate(a=-a, v=v) children();
		} else if (is_num(a)) {
			rotate(-a) children();
		} else {
			rotate([-a[0],0,0]) rotate([0,-a[1],0]) rotate([0,0,-a[2]]) children();
		}
	} else {
		rotate(a=a, v=v) children();
	}
}

function rot(a=0, v=undef, cp=undef, from=undef, to=undef, reverse=false, p=undef, planar=false) =
	assert(is_undef(from)==is_undef(to), "from and to must be specified together.")
	let(rev = reverse? -1 : 1)
	is_undef(p)? (
		is_undef(cp)? (
			planar? (
				is_undef(from)? affine2d_zrot(a*rev) :
				affine2d_zrot(vector_angle(from,to)*sign(vector_axis(from,to)[2])*rev)
			) : (
				!is_undef(from)? affine3d_rot_by_axis(vector_axis(from,to),vector_angle(from,to)*rev) :
				!is_undef(v)? affine3d_rot_by_axis(v,a*rev) :
				is_num(a)? affine3d_zrot(a*rev) :
				reverse? affine3d_chain([affine3d_zrot(-a.z),affine3d_yrot(-a.y),affine3d_xrot(-a.x)]) :
				affine3d_chain([affine3d_xrot(a.x),affine3d_yrot(a.y),affine3d_zrot(a.z)])
			)
		) : (
			planar? (
				affine2d_chain([
					move(-cp),
					rot(a=a, v=v, from=from, to=to, reverse=reverse, planar=true),
					move(cp)
				])
			) : (
				affine3d_chain([
					move(-cp),
					rot(a=a, v=v, from=from, to=to, reverse=reverse),
					move(cp)
				])
			)
		)
	) : (
		is_vector(p)? (
			rot(a=a, v=v, cp=cp, from=from, to=to, reverse=reverse, p=[p], planar=planar)[0]
		) : (
			planar? (
				is_undef(from)? rotate_points2d(p, a=a*rev, cp=cp) : (
					approx(from,to)? p :
					rotate_points2d(p, a=vector_angle(from,to)*sign(vector_axis(from,to)[2])*rev, cp=cp)
				)
			) : (
				rotate_points3d(p, a=a, v=v, cp=(is_undef(cp)? [0,0,0] : cp), from=from, to=to, reverse=reverse)
			)
		)
	);




// Module: xrot()
//
// Description:
//   Rotates children around the X axis by the given number of degrees.
//
// Usage:
//   xrot(a, [cp]) ...
//
// Arguments:
//   a = angle to rotate by in degrees.
//   cp = centerpoint to rotate around. Default: [0,0,0]
//
// Example:
//   #cylinder(h=50, r=10, center=true);
//   xrot(90) cylinder(h=50, r=10, center=true);
module xrot(a=0, cp=undef)
{
	if (a==0) {
		children();  // May be slightly faster?
	} else if (!is_undef(cp)) {
		translate(cp) rotate([a, 0, 0]) translate(-cp) children();
	} else {
		rotate([a, 0, 0]) children();
	}
}


// Module: yrot()
//
// Description:
//   Rotates children around the Y axis by the given number of degrees.
//
// Usage:
//   yrot(a, [cp]) ...
//
// Arguments:
//   a = angle to rotate by in degrees.
//   cp = centerpoint to rotate around. Default: [0,0,0]
//
// Example:
//   #cylinder(h=50, r=10, center=true);
//   yrot(90) cylinder(h=50, r=10, center=true);
module yrot(a=0, cp=undef)
{
	if (a==0) {
		children();  // May be slightly faster?
	} else if (!is_undef(cp)) {
		translate(cp) rotate([0, a, 0]) translate(-cp) children();
	} else {
		rotate([0, a, 0]) children();
	}
}


// Module: zrot()
//
// Description:
//   Rotates children around the Z axis by the given number of degrees.
//
// Usage:
//   zrot(a, [cp]) ...
//
// Arguments:
//   a = angle to rotate by in degrees.
//   cp = centerpoint to rotate around. Default: [0,0,0]
//
// Example:
//   #cube(size=[60,20,40], center=true);
//   zrot(90) cube(size=[60,20,40], center=true);
module zrot(a=0, cp=undef)
{
	if (a==0) {
		children();  // May be slightly faster?
	} else if (!is_undef(cp)) {
		translate(cp) rotate(a) translate(-cp) children();
	} else {
		rotate(a) children();
	}
}



//////////////////////////////////////////////////////////////////////
// Section: Scaling and Mirroring
//////////////////////////////////////////////////////////////////////


// Function&Module: scale()
// Usage: As Module
//   scale(SCALAR) ...
//   scale([X,Y,Z]) ...
// Usage: Scale Points
//   pts = scale(a, p);
// Usage: Get Scaling Matrix
//   mat = scale(a);
// Description:
//   When called as the built-in module, scales all children by the [X,Y,Z] scaling factors.  When
//   called as a function with a point in the `p` argument, returns the point scaled by the [X,Y,Z]
//   scaling factors in `a`.  When called as a function with a list of points in the `p` argument,
//   returns the list of points, with each one scaled by the [X,Y,Z] scaling factors in `a`.
// Arguments:
//   a = The [X,Y,Z] scaling factors, or a scalar value for uniform scaling across all axes.  Default: 1
//   p = If called as a function, the point or list of points to scale.
// Example(NORENDER):
//   pt1 = scale(3, p=[3,1,4]);        // Returns: [9,3,12]
//   pt2 = scale([2,3,4], p=[3,1,4]);  // Returns: [6,3,16]
//   pt3 = scale([2,3,4], p=[[1,2,3],[4,5,6]]);  // Returns: [[2,6,12], [8,15,24]]
//   mat2d = scale([2,3]);    // Returns: [[2,0,0],[0,3,0],[0,0,1]]
//   mat3d = scale([2,3,4]);  // Returns: [[2,0,0,0],[0,3,0,0],[0,0,4,0],[0,0,0,1]]
function scale(a=1, p=undef) =
	let(a = is_num(a)? [a,a,a] : a)
	is_undef(p)? (
		len(a)==2? affine2d_scale(a) : affine3d_scale(point3d(a))
	) : (
		is_vector(p)? vmul(p,a) : [for (pt = p) vmul(pt,a)]
	);


// Module: xscale()
//
// Description:
//   Scales children by the given factor on the X axis.
//
// Usage:
//   xscale(x) ...
//
// Arguments:
//   x = Factor to scale by along the X axis.
//
// Example:
//   xscale(3) sphere(r=10);
module xscale(x) scale([x,1,1]) children();


// Module: yscale()
//
// Description:
//   Scales children by the given factor on the Y axis.
//
// Usage:
//   yscale(y) ...
//
// Arguments:
//   y = Factor to scale by along the Y axis.
//
// Example:
//   yscale(3) sphere(r=10);
module yscale(y) scale([1,y,1]) children();


// Module: zscale()
//
// Description:
//   Scales children by the given factor on the Z axis.
//
// Usage:
//   zscale(z) ...
//
// Arguments:
//   z = Factor to scale by along the Z axis.
//
// Example:
//   zscale(3) sphere(r=10);
module zscale(z) scale([1,1,z]) children();


// Module: xflip()
//
// Description:
//   Mirrors the children along the X axis, like `mirror([1,0,0])` or `xscale(-1)`
//
// Usage:
//   xflip([x]) ...
//
// Arguments:
//   x = The X coordinate of the plane of reflection.  Default: 0
//
// Example:
//   xflip() yrot(90) cylinder(d1=10, d2=0, h=20);
//   color("blue", 0.25) cube([0.01,15,15], center=true);
//   color("red", 0.333) yrot(90) cylinder(d1=10, d2=0, h=20);
//
// Example:
//   xflip(x=-5) yrot(90) cylinder(d1=10, d2=0, h=20);
//   color("blue", 0.25) left(5) cube([0.01,15,15], center=true);
//   color("red", 0.333) yrot(90) cylinder(d1=10, d2=0, h=20);
module xflip(x=0) translate([x,0,0]) mirror([1,0,0]) translate([-x,0,0]) children();


// Module: yflip()
//
// Description:
//   Mirrors the children along the Y axis, like `mirror([0,1,0])` or `yscale(-1)`
//
// Usage:
//   yflip([y]) ...
//
// Arguments:
//   y = The Y coordinate of the plane of reflection.  Default: 0
//
// Example:
//   yflip() xrot(90) cylinder(d1=10, d2=0, h=20);
//   color("blue", 0.25) cube([15,0.01,15], center=true);
//   color("red", 0.333) xrot(90) cylinder(d1=10, d2=0, h=20);
//
// Example:
//   yflip(y=5) xrot(90) cylinder(d1=10, d2=0, h=20);
//   color("blue", 0.25) back(5) cube([15,0.01,15], center=true);
//   color("red", 0.333) xrot(90) cylinder(d1=10, d2=0, h=20);
module yflip(y=0) translate([0,y,0]) mirror([0,1,0]) translate([0,-y,0]) children();


// Module: zflip()
//
// Description:
//   Mirrors the children along the Z axis, like `mirror([0,0,1])` or `zscale(-1)`
//
// Usage:
//   zflip([z]) ...
//
// Arguments:
//   z = The Z coordinate of the plane of reflection.  Default: 0
//
// Example:
//   zflip() cylinder(d1=10, d2=0, h=20);
//   color("blue", 0.25) cube([15,15,0.01], center=true);
//   color("red", 0.333) cylinder(d1=10, d2=0, h=20);
//
// Example:
//   zflip(z=-5) cylinder(d1=10, d2=0, h=20);
//   color("blue", 0.25) down(5) cube([15,15,0.01], center=true);
//   color("red", 0.333) cylinder(d1=10, d2=0, h=20);
module zflip(z=0) translate([0,0,z]) mirror([0,0,1]) translate([0,0,-z]) children();



//////////////////////////////////////////////////////////////////////
// Section: Skewing
//////////////////////////////////////////////////////////////////////


// Module: skew_xy()
//
// Description:
//   Skews children on the X-Y plane, keeping constant in Z.
//
// Usage:
//   skew_xy([xa], [ya], [planar]) ...
//
// Arguments:
//   xa = skew angle towards the X direction.
//   ya = skew angle towards the Y direction.
//   planar = If true, this becomes a 2D operation.
//
// Example(FlatSpin):
//   #cube(size=10);
//   skew_xy(xa=30, ya=15) cube(size=10);
// Example(2D):
//   skew_xy(xa=15,ya=30,planar=true) square(30);
module skew_xy(xa=0, ya=0, planar=false) multmatrix(m = planar? affine2d_skew(xa, ya) : affine3d_skew_xy(xa, ya)) children();


// Module: skew_yz()
//
// Description:
//   Skews children on the Y-Z plane, keeping constant in X.
//
// Usage:
//   skew_yz([ya], [za]) ...
//
// Arguments:
//   ya = skew angle towards the Y direction.
//   za = skew angle towards the Z direction.
//
// Example(FlatSpin):
//   #cube(size=10);
//   skew_yz(ya=30, za=15) cube(size=10);
module skew_yz(ya=0, za=0) multmatrix(m = affine3d_skew_yz(ya, za)) children();


// Module: skew_xz()
//
// Description:
//   Skews children on the X-Z plane, keeping constant in Y.
//
// Usage:
//   skew_xz([xa], [za]) ...
//
// Arguments:
//   xa = skew angle towards the X direction.
//   za = skew angle towards the Z direction.
//
// Example(FlatSpin):
//   #cube(size=10);
//   skew_xz(xa=15, za=-10) cube(size=10);
module skew_xz(xa=0, za=0) multmatrix(m = affine3d_skew_xz(xa, za)) children();



//////////////////////////////////////////////////////////////////////
// Section: Translational Distributors
//////////////////////////////////////////////////////////////////////


// Module: place_copies()
//
// Description:
//   Makes copies of the given children at each of the given offsets.
//
// Usage:
//   place_copies(a) ...
//
// Arguments:
//   a = array of XYZ offset vectors. Default [[0,0,0]]
//
// Side Effects:
//   `$pos` is set to the relative centerpoint of each child copy, and can be used to modify each child individually.
//
// Example:
//   #sphere(r=10);
//   place_copies([[-25,-25,0], [25,-25,0], [0,0,50], [0,25,0]]) sphere(r=10);
module place_copies(a=[[0,0,0]])
{
	for (off = a) translate(off) children();
}


// Module: spread()
//
// Description:
//   Evenly distributes `n` copies of all children along a line.
//   Copies every child at each position.
//
// Usage:
//   spread(l, [n], [p1]) ...
//   spread(l, spacing, [p1]) ...
//   spread(spacing, [n], [p1]) ...
//   spread(p1, p2, [n]) ...
//   spread(p1, p2, spacing) ...
//
// Arguments:
//   p1 = Starting point of line.
//   p2 = Ending point of line.
//   l = Length to spread copies over.
//   spacing = A 3D vector indicating which direction and distance to place each subsequent copy at.
//   n = Number of copies to distribute along the line. (Default: 2)
//
// Side Effects:
//   `$pos` is set to the relative centerpoint of each child copy, and can be used to modify each child individually.
//   `$idx` is set to the index number of each child being copied.
//
// Example(FlatSpin):
//   spread([0,0,0], [5,5,20], n=6) cube(size=[3,2,1],center=true);
// Examples:
//   spread(l=40, n=6) cube(size=[3,2,1],center=true);
//   spread(l=[15,30], n=6) cube(size=[3,2,1],center=true);
//   spread(l=40, spacing=10) cube(size=[3,2,1],center=true);
//   spread(spacing=[5,5,0], n=5) cube(size=[3,2,1],center=true);
// Example:
//   spread(l=20, n=3) {
//       cube(size=[1,3,1],center=true);
//       cube(size=[3,1,1],center=true);
//   }
module spread(p1=undef, p2=undef, spacing=undef, l=undef, n=undef)
{
	ll = (
		!is_undef(l)? scalar_vec3(l, 0) :
		(!is_undef(spacing) && !is_undef(n))? (n * scalar_vec3(spacing, 0)) :
		(!is_undef(p1) && !is_undef(p2))? point3d(p2-p1) :
		undef
	);
	cnt = (
		!is_undef(n)? n :
		(!is_undef(spacing) && !is_undef(ll))? floor(norm(ll) / norm(scalar_vec3(spacing, 0)) + 1.000001) :
		2
	);
	spc = (
		is_undef(spacing)? (ll/(cnt-1)) :
		is_num(spacing) && !is_undef(ll)? (ll/(cnt-1)) :
		scalar_vec3(spacing, 0)
	);
	assert(!is_undef(cnt), "Need two of `spacing`, 'l', 'n', or `p1`/`p2` arguments in `spread()`.");
	spos = !is_undef(p1)? point3d(p1) : -(cnt-1)/2 * spc;
	for (i=[0:1:cnt-1]) {
		pos = i * spc + spos;
		$pos = pos;
		$idx = i;
		translate(pos) children();
	}
}


// Module: xspread()
//
// Description:
//   Spreads out `n` copies of the children along a line on the X axis.
//
// Usage:
//   xspread(spacing, [n], [sp]) ...
//   xspread(l, [n], [sp]) ...
//
// Arguments:
//   spacing = spacing between copies. (Default: 1.0)
//   n = Number of copies to spread out. (Default: 2)
//   l = Length to spread copies over.
//   sp = If given, copies will be spread on a line to the right of starting position `sp`.  If not given, copies will be spread along a line that is centered at [0,0,0].
//
// Side Effects:
//   `$pos` is set to the relative centerpoint of each child copy, and can be used to modify each child individually.
//   `$idx` is set to the index number of each child being copied.
//
// Examples:
//   xspread(20) sphere(3);
//   xspread(20, n=3) sphere(3);
//   xspread(spacing=15, l=50) sphere(3);
//   xspread(n=4, l=30, sp=[0,10,0]) sphere(3);
// Example:
//   xspread(10, n=3) {
//       cube(size=[1,3,1],center=true);
//       cube(size=[3,1,1],center=true);
//   }
module xspread(spacing=undef, n=undef, l=undef, sp=undef)
{
	spread(l=l*RIGHT, spacing=spacing*RIGHT, n=n, p1=sp) children();
}


// Module: yspread()
//
// Description:
//   Spreads out `n` copies of the children along a line on the Y axis.
//
// Usage:
//   yspread(spacing, [n], [sp]) ...
//   yspread(l, [n], [sp]) ...
//
// Arguments:
//   spacing = spacing between copies. (Default: 1.0)
//   n = Number of copies to spread out. (Default: 2)
//   l = Length to spread copies over.
//   sp = If given, copies will be spread on a line back from starting position `sp`.  If not given, copies will be spread along a line that is centered at [0,0,0].
//
// Side Effects:
//   `$pos` is set to the relative centerpoint of each child copy, and can be used to modify each child individually.
//   `$idx` is set to the index number of each child being copied.
//
// Examples:
//   yspread(20) sphere(3);
//   yspread(20, n=3) sphere(3);
//   yspread(spacing=15, l=50) sphere(3);
//   yspread(n=4, l=30, sp=[10,0,0]) sphere(3);
// Example:
//   yspread(10, n=3) {
//       cube(size=[1,3,1],center=true);
//       cube(size=[3,1,1],center=true);
//   }
module yspread(spacing=undef, n=undef, l=undef, sp=undef)
{
	spread(l=l*BACK, spacing=spacing*BACK, n=n, p1=sp) children();
}


// Module: zspread()
//
// Description:
//   Spreads out `n` copies of the children along a line on the Z axis.
//
// Usage:
//   zspread(spacing, [n], [sp]) ...
//   zspread(l, [n], [sp]) ...
//
// Arguments:
//   spacing = spacing between copies. (Default: 1.0)
//   n = Number of copies to spread out. (Default: 2)
//   l = Length to spread copies over.
//   sp = If given, copies will be spread on a line up from starting position `sp`.  If not given, copies will be spread along a line that is centered at [0,0,0].
//
// Side Effects:
//   `$pos` is set to the relative centerpoint of each child copy, and can be used to modify each child individually.
//   `$idx` is set to the index number of each child being copied.
//
// Examples:
//   zspread(20) sphere(3);
//   zspread(20, n=3) sphere(3);
//   zspread(spacing=15, l=50) sphere(3);
//   zspread(n=4, l=30, sp=[10,0,0]) sphere(3);
// Example:
//   zspread(10, n=3) {
//       cube(size=[1,3,1],center=true);
//       cube(size=[3,1,1],center=true);
//   }
module zspread(spacing=undef, n=undef, l=undef, sp=undef)
{
	spread(l=l*UP, spacing=spacing*UP, n=n, p1=sp) children();
}



// Module: distribute()
//
// Description:
//   Spreads out each individual child along the direction `dir`.
//   Every child is placed at a different position, in order.
//   This is useful for laying out groups of disparate objects
//   where you only really care about the spacing between them.
//
// Usage:
//   distribute(spacing, dir, [sizes]) ...
//   distribute(l, dir, [sizes]) ...
//
// Arguments:
//   spacing = Spacing to add between each child. (Default: 10.0)
//   sizes = Array containing how much space each child will need.
//   dir = Vector direction to distribute copies along.
//   l = Length to distribute copies along.
//
// Side Effect:
//   `$pos` is set to the relative centerpoint of each child copy, and can be used to modify each child individually.
//   `$idx` is set to the index number of each child being copied.
//
// Example:
//   distribute(sizes=[100, 30, 50], dir=UP) {
//       sphere(r=50);
//       cube([10,20,30], center=true);
//       cylinder(d=30, h=50, center=true);
//   }
module distribute(spacing=undef, sizes=undef, dir=RIGHT, l=undef)
{
	gaps = ($children < 2)? [0] :
		!is_undef(sizes)? [for (i=[0:1:$children-2]) sizes[i]/2 + sizes[i+1]/2] :
		[for (i=[0:1:$children-2]) 0];
	spc = !is_undef(l)? ((l - sum(gaps)) / ($children-1)) : default(spacing, 10);
	gaps2 = [for (gap = gaps) gap+spc];
	spos = dir * -sum(gaps2)/2;
	for (i=[0:1:$children-1]) {
		totspc = sum(concat([0], slice(gaps2, 0, i)));
		$pos = spos + totspc * dir;
		$idx = i;
		translate($pos) children(i);
	}
}


// Module: xdistribute()
//
// Description:
//   Spreads out each individual child along the X axis.
//   Every child is placed at a different position, in order.
//   This is useful for laying out groups of disparate objects
//   where you only really care about the spacing between them.
//
// Usage:
//   xdistribute(spacing, [sizes]) ...
//   xdistribute(l, [sizes]) ...
//
// Arguments:
//   spacing = spacing between each child. (Default: 10.0)
//   sizes = Array containing how much space each child will need.
//   l = Length to distribute copies along.
//
// Side Effect:
//   `$pos` is set to the relative centerpoint of each child copy, and can be used to modify each child individually.
//   `$idx` is set to the index number of each child being copied.
//
// Example:
//   xdistribute(sizes=[100, 10, 30], spacing=40) {
//       sphere(r=50);
//       cube([10,20,30], center=true);
//       cylinder(d=30, h=50, center=true);
//   }
module xdistribute(spacing=10, sizes=undef, l=undef)
{
	dir = RIGHT;
	gaps = ($children < 2)? [0] :
		!is_undef(sizes)? [for (i=[0:1:$children-2]) sizes[i]/2 + sizes[i+1]/2] :
		[for (i=[0:1:$children-2]) 0];
	spc = !is_undef(l)? ((l - sum(gaps)) / ($children-1)) : default(spacing, 10);
	gaps2 = [for (gap = gaps) gap+spc];
	spos = dir * -sum(gaps2)/2;
	for (i=[0:1:$children-1]) {
		totspc = sum(concat([0], slice(gaps2, 0, i)));
		$pos = spos + totspc * dir;
		$idx = i;
		translate($pos) children(i);
	}
}


// Module: ydistribute()
//
// Description:
//   Spreads out each individual child along the Y axis.
//   Every child is placed at a different position, in order.
//   This is useful for laying out groups of disparate objects
//   where you only really care about the spacing between them.
//
// Usage:
//   ydistribute(spacing, [sizes])
//   ydistribute(l, [sizes])
//
// Arguments:
//   spacing = spacing between each child. (Default: 10.0)
//   sizes = Array containing how much space each child will need.
//   l = Length to distribute copies along.
//
// Side Effect:
//   `$pos` is set to the relative centerpoint of each child copy, and can be used to modify each child individually.
//   `$idx` is set to the index number of each child being copied.
//
// Example:
//   ydistribute(sizes=[30, 20, 100], spacing=40) {
//       cylinder(d=30, h=50, center=true);
//       cube([10,20,30], center=true);
//       sphere(r=50);
//   }
module ydistribute(spacing=10, sizes=undef, l=undef)
{
	dir = BACK;
	gaps = ($children < 2)? [0] :
		!is_undef(sizes)? [for (i=[0:1:$children-2]) sizes[i]/2 + sizes[i+1]/2] :
		[for (i=[0:1:$children-2]) 0];
	spc = !is_undef(l)? ((l - sum(gaps)) / ($children-1)) : default(spacing, 10);
	gaps2 = [for (gap = gaps) gap+spc];
	spos = dir * -sum(gaps2)/2;
	for (i=[0:1:$children-1]) {
		totspc = sum(concat([0], slice(gaps2, 0, i)));
		$pos = spos + totspc * dir;
		$idx = i;
		translate($pos) children(i);
	}
}


// Module: zdistribute()
//
// Description:
//   Spreads out each individual child along the Z axis.
//   Every child is placed at a different position, in order.
//   This is useful for laying out groups of disparate objects
//   where you only really care about the spacing between them.
//
// Usage:
//   zdistribute(spacing, [sizes])
//   zdistribute(l, [sizes])
//
// Arguments:
//   spacing = spacing between each child. (Default: 10.0)
//   sizes = Array containing how much space each child will need.
//   l = Length to distribute copies along.
//
// Side Effect:
//   `$pos` is set to the relative centerpoint of each child copy, and can be used to modify each child individually.
//   `$idx` is set to the index number of each child being copied.
//
// Example:
//   zdistribute(sizes=[30, 20, 100], spacing=40) {
//       cylinder(d=30, h=50, center=true);
//       cube([10,20,30], center=true);
//       sphere(r=50);
//   }
module zdistribute(spacing=10, sizes=undef, l=undef)
{
	dir = UP;
	gaps = ($children < 2)? [0] :
		!is_undef(sizes)? [for (i=[0:1:$children-2]) sizes[i]/2 + sizes[i+1]/2] :
		[for (i=[0:1:$children-2]) 0];
	spc = !is_undef(l)? ((l - sum(gaps)) / ($children-1)) : default(spacing, 10);
	gaps2 = [for (gap = gaps) gap+spc];
	spos = dir * -sum(gaps2)/2;
	for (i=[0:1:$children-1]) {
		totspc = sum(concat([0], slice(gaps2, 0, i)));
		$pos = spos + totspc * dir;
		$idx = i;
		translate($pos) children(i);
	}
}



// Module: grid2d()
//
// Description:
//   Makes a square or hexagonal grid of copies of children.
//
// Usage:
//   grid2d(size, spacing, [stagger], [scale], [in_poly]) ...
//   grid2d(size, cols, rows, [stagger], [scale], [in_poly]) ...
//   grid2d(spacing, cols, rows, [stagger], [scale], [in_poly]) ...
//   grid2d(spacing, in_poly, [stagger], [scale]) ...
//   grid2d(cols, rows, in_poly, [stagger], [scale]) ...
//
// Arguments:
//   size = The [X,Y] size to spread the copies over.
//   spacing = Distance between copies in [X,Y] or scalar distance.
//   cols = How many columns of copies to make.  If staggered, count both staggered and unstaggered columns.
//   rows = How many rows of copies to make.  If staggered, count both staggered and unstaggered rows.
//   stagger = If true, make a staggered (hexagonal) grid.  If false, make square grid.  If `"alt"`, makes alternate staggered pattern.  Default: false
//   scale = [X,Y] scaling factors to reshape grid.
//   in_poly = If given a list of polygon points, only creates copies whose center would be inside the polygon.  Polygon can be concave and/or self crossing.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
//
// Side Effects:
//   `$pos` is set to the relative centerpoint of each child copy, and can be used to modify each child individually.
//   `$col` is set to the integer column number for each child.
//   `$row` is set to the integer row number for each child.
//
// Examples:
//   grid2d(size=50, spacing=10, stagger=false) cylinder(d=10, h=1);
//   grid2d(spacing=10, rows=7, cols=13, stagger=true) cylinder(d=6, h=5);
//   grid2d(spacing=10, rows=7, cols=13, stagger="alt") cylinder(d=6, h=5);
//   grid2d(size=50, rows=11, cols=11, stagger=true) cylinder(d=5, h=1);
//
// Example:
//   poly = [[-25,-25], [25,25], [-25,25], [25,-25]];
//   grid2d(spacing=5, stagger=true, in_poly=poly)
//      zrot(180/6) cylinder(d=5, h=1, $fn=6);
//   %polygon(poly);
//
// Example:
//   // Makes a grid of hexagon pillars whose tops are all
//   // angled to reflect light at [0,0,50], if they were shiny.
//   hexregion = [for (a = [0:60:359.9]) 50.01*[cos(a), sin(a)]];
//   grid2d(spacing=10, stagger=true, in_poly=hexregion) {
//       // Note: You must use for(var=[val]) or let(var=val)
//       // to set vars from $pos or other special vars in this scope.
//       let (ref_v = (normalize([0,0,50]-point3d($pos)) + UP)/2)
//           half_of(v=-ref_v, cp=[0,0,5])
//               zrot(180/6)
//                   cylinder(h=20, d=10/cos(180/6)+0.01, $fn=6);
//   }
module grid2d(size=undef, spacing=undef, cols=undef, rows=undef, stagger=false, scale=[1,1,1], in_poly=undef, anchor=CENTER, spin=0, orient=UP)
{
	assert_in_list("stagger", stagger, [false, true, "alt"]);
	scl = vmul(scalar_vec3(scale, 1), (stagger!=false? [0.5, sin(60), 0] : [1,1,0]));
	if (!is_undef(size)) {
		siz = scalar_vec3(size);
		if (!is_undef(spacing)) {
			spc = vmul(scalar_vec3(spacing), scl);
			maxcols = ceil(siz[0]/spc[0]);
			maxrows = ceil(siz[1]/spc[1]);
			grid2d(spacing=spacing, cols=maxcols, rows=maxrows, stagger=stagger, scale=scale, in_poly=in_poly, anchor=anchor, spin=spin, orient=orient) children();
		} else {
			spc = [siz[0]/cols, siz[1]/rows, 0];
			grid2d(spacing=spc, cols=cols, rows=rows, stagger=stagger, scale=scale, in_poly=in_poly, anchor=anchor, spin=spin, orient=orient) children();
		}
	} else {
		spc = is_list(spacing)? spacing : vmul(scalar_vec3(spacing), scl);
		bounds = !is_undef(in_poly)? pointlist_bounds(in_poly) : undef;
		bnds = !is_undef(bounds)? [for (a=[0,1]) 2*max(vabs([ for (i=[0,1]) bounds[i][a] ]))+1 ] : undef;
		mcols = !is_undef(cols)? cols : (!is_undef(spc) && !is_undef(bnds))? quantup(ceil(bnds[0]/spc[0])-1, 4)+1 : undef;
		mrows = !is_undef(rows)? rows : (!is_undef(spc) && !is_undef(bnds))? quantup(ceil(bnds[1]/spc[1])-1, 4)+1 : undef;
		siz = vmul(spc, [mcols-1, mrows-1, 0]);
		staggermod = (stagger == "alt")? 1 : 0;
		if (stagger == false) {
			orient_and_anchor(siz, orient, anchor, spin=spin) {
				for (row = [0:1:mrows-1]) {
					for (col = [0:1:mcols-1]) {
						pos = [col*spc[0], row*spc[1]] - point2d(siz/2);
						if (is_undef(in_poly) || point_in_polygon(pos, in_poly)>=0) {
							$col = col;
							$row = row;
							$pos = pos;
							translate(pos) rot(orient,reverse=true) children();
						}
					}
				}
			}
		} else {
			// stagger == true or stagger == "alt"
			orient_and_anchor(siz, orient, anchor, spin=spin) {
				cols1 = ceil(mcols/2);
				cols2 = mcols - cols1;
				for (row = [0:1:mrows-1]) {
					rowcols = ((row%2) == staggermod)? cols1 : cols2;
					if (rowcols > 0) {
						for (col = [0:1:rowcols-1]) {
							rowdx = (row%2 != staggermod)? spc[0] : 0;
							pos = [2*col*spc[0]+rowdx, row*spc[1]] - point2d(siz/2);
							if (is_undef(in_poly) || point_in_polygon(pos, in_poly)>=0) {
								$col = col * 2 + ((row%2!=staggermod)? 1 : 0);
								$row = row;
								$pos = pos;
								translate(pos) rot(orient,reverse=true) children();
							}
						}
					}
				}
			}
		}
	}
}



// Module: grid3d()
//
// Description:
//   Makes a 3D grid of duplicate children.
//
// Usage:
//   grid3d(n, spacing) ...
//   grid3d(n=[Xn,Yn,Zn], spacing=[dX,dY,dZ]) ...
//   grid3d([xa], [ya], [za]) ...
//
// Arguments:
//   xa = array or range of X-axis values to offset by. (Default: [0])
//   ya = array or range of Y-axis values to offset by. (Default: [0])
//   za = array or range of Z-axis values to offset by. (Default: [0])
//   n = Optional number of copies to have per axis.
//   spacing = spacing of copies per axis. Use with `n`.
//
// Side Effect:
//   `$pos` is set to the relative centerpoint of each child copy, and can be used to modify each child individually.
//   `$idx` is set to the [Xidx,Yidx,Zidx] index values of each child copy, when using `count` and `n`.
//
// Examples(FlatSpin):
//   grid3d(xa=[0:25:50],ya=[0,40],za=[-20:40:20]) sphere(r=5);
//   grid3d(n=[3, 4, 2], spacing=[60, 50, 40]) sphere(r=10);
// Examples:
//   grid3d(ya=[-60:40:60],za=[0,70]) sphere(r=10);
//   grid3d(n=3, spacing=30) sphere(r=10);
//   grid3d(n=[3, 1, 2], spacing=30) sphere(r=10);
//   grid3d(n=[3, 4], spacing=[80, 60]) sphere(r=10);
// Examples:
//   grid3d(n=[10, 10, 10], spacing=50) color($idx/9) cube(50, center=true);
module grid3d(xa=[0], ya=[0], za=[0], n=undef, spacing=undef)
{
	n = scalar_vec3(n, 1);
	spacing = scalar_vec3(spacing, undef);
	if (!is_undef(n) && !is_undef(spacing)) {
		for (xi = [0:1:n.x-1]) {
			for (yi = [0:1:n.y-1]) {
				for (zi = [0:1:n.z-1]) {
					$idx = [xi,yi,zi];
					$pos = vmul(spacing, $idx - (n-[1,1,1])/2);
					translate($pos) children();
				}
			}
		}
	} else {
		for (xoff = xa, yoff = ya, zoff = za) {
			$pos = [xoff, yoff, zoff];
			translate($pos) children();
		}
	}
}



//////////////////////////////////////////////////////////////////////
// Section: Rotational Distributors
//////////////////////////////////////////////////////////////////////


// Module: rot_copies()
//
// Description:
//   Given a number of XYZ rotation angles, or a list of angles and an axis `v`,
//   rotates copies of the children to each of those angles.
//
// Usage:
//   rot_copies(rots, [cp], [sa], [delta], [subrot]) ...
//   rot_copies(rots, v, [cp], [sa], [delta], [subrot]) ...
//   rot_copies(n, [v], [cp], [sa], [delta], [subrot]) ...
//
// Arguments:
//   rots = A list of [X,Y,Z] rotation angles in degrees.  If `v` is given, this will be a list of scalar angles in degrees to rotate around `v`.
//   v = If given, this is the vector to rotate around.
//   cp = Centerpoint to rotate around.
//   n = Optional number of evenly distributed copies, rotated around the ring.
//   sa = Starting angle, in degrees.  For use with `n`.  Angle is in degrees counter-clockwise.
//   delta = [X,Y,Z] amount to move away from cp before rotating.  Makes rings of copies.
//   subrot = If false, don't sub-rotate children as they are copied around the ring.
//
// Side Effects:
//   `$ang` is set to the rotation angle (or XYZ rotation triplet) of each child copy, and can be used to modify each child individually.
//   `$idx` is set to the index value of each child copy.
//
// Example:
//   #cylinder(h=20, r1=5, r2=0);
//   rot_copies([[45,0,0],[0,45,90],[90,-45,270]]) cylinder(h=20, r1=5, r2=0);
//
// Example:
//   rot_copies([45, 90, 135], v=DOWN+BACK)
//       yrot(90) cylinder(h=20, r1=5, r2=0);
//   color("red",0.333) yrot(90) cylinder(h=20, r1=5, r2=0);
//
// Example:
//   rot_copies(n=6, v=DOWN+BACK)
//       yrot(90) cylinder(h=20, r1=5, r2=0);
//   color("red",0.333) yrot(90) cylinder(h=20, r1=5, r2=0);
//
// Example:
//   rot_copies(n=6, v=DOWN+BACK, delta=[10,0,0])
//       yrot(90) cylinder(h=20, r1=5, r2=0);
//   color("red",0.333) yrot(90) cylinder(h=20, r1=5, r2=0);
//
// Example:
//   rot_copies(n=6, v=UP+FWD, delta=[10,0,0], sa=45)
//       yrot(90) cylinder(h=20, r1=5, r2=0);
//   color("red",0.333) yrot(90) cylinder(h=20, r1=5, r2=0);
//
// Example:
//   rot_copies(n=6, v=DOWN+BACK, delta=[20,0,0], subrot=false)
//       yrot(90) cylinder(h=20, r1=5, r2=0);
//   color("red",0.333) yrot(90) cylinder(h=20, r1=5, r2=0);
module rot_copies(rots=[], v=undef, cp=[0,0,0], count=undef, n=undef, sa=0, offset=0, delta=[0,0,0], subrot=true)
{
	cnt = first_defined([count, n]);
	sang = sa + offset;
	angs = !is_undef(cnt)? (cnt<=0? [] : [for (i=[0:1:cnt-1]) i/cnt*360+sang]) : rots;
	if (cp != [0,0,0]) {
		translate(cp) rot_copies(rots=rots, v=v, n=cnt, sa=sang, delta=delta, subrot=subrot) children();
	} else if (subrot) {
		for ($idx = [0:1:len(angs)-1]) {
			$ang = angs[$idx];
			rotate(a=$ang,v=v) translate(delta) rot(a=sang,v=v,reverse=true) children();
		}
	} else {
		for ($idx = [0:1:len(angs)-1]) {
			$ang = angs[$idx];
			rotate(a=$ang,v=v) translate(delta) rot(a=$ang,v=v,reverse=true) children();
		}
	}
}


// Module: xrot_copies()
//
// Description:
//   Given an array of angles, rotates copies of the children
//   to each of those angles around the X axis.
//
// Usage:
//   xrot_copies(rots, [r], [cp], [sa], [subrot]) ...
//   xrot_copies(n, [r], [cp], [sa], [subrot]) ...
//
// Arguments:
//   rots = Optional array of rotation angles, in degrees, to make copies at.
//   cp = Centerpoint to rotate around.
//   n = Optional number of evenly distributed copies to be rotated around the ring.
//   sa = Starting angle, in degrees.  For use with `n`.  Angle is in degrees counter-clockwise from Y+, when facing the origin from X+.  First unrotated copy is placed at that angle.
//   r = Radius to move children back, away from cp, before rotating.  Makes rings of copies.
//   subrot = If false, don't sub-rotate children as they are copied around the ring.
//
// Side Effects:
//   `$ang` is set to the rotation angle of each child copy, and can be used to modify each child individually.
//
// Example:
//   xrot_copies([180, 270, 315])
//       cylinder(h=20, r1=5, r2=0);
//   color("red",0.333) cylinder(h=20, r1=5, r2=0);
//
// Example:
//   xrot_copies(n=6)
//       cylinder(h=20, r1=5, r2=0);
//   color("red",0.333) cylinder(h=20, r1=5, r2=0);
//
// Example:
//   xrot_copies(n=6, r=10)
//       xrot(-90) cylinder(h=20, r1=5, r2=0);
//   color("red",0.333) xrot(-90) cylinder(h=20, r1=5, r2=0);
//
// Example:
//   xrot_copies(n=6, r=10, sa=45)
//       xrot(-90) cylinder(h=20, r1=5, r2=0);
//   color("red",0.333) xrot(-90) cylinder(h=20, r1=5, r2=0);
//
// Example:
//   xrot_copies(n=6, r=20, subrot=false)
//       xrot(-90) cylinder(h=20, r1=5, r2=0, center=true);
//   color("red",0.333) xrot(-90) cylinder(h=20, r1=5, r2=0, center=true);
module xrot_copies(rots=[], cp=[0,0,0], n=undef, count=undef, sa=0, offset=0, r=0, subrot=true)
{
	cnt = first_defined([count, n]);
	sang = sa + offset;
	rot_copies(rots=rots, v=RIGHT, cp=cp, n=cnt, sa=sang, delta=[0, r, 0], subrot=subrot) children();
}


// Module: yrot_copies()
//
// Description:
//   Given an array of angles, rotates copies of the children
//   to each of those angles around the Y axis.
//
// Usage:
//   yrot_copies(rots, [r], [cp], [sa], [subrot]) ...
//   yrot_copies(n, [r], [cp], [sa], [subrot]) ...
//
// Arguments:
//   rots = Optional array of rotation angles, in degrees, to make copies at.
//   cp = Centerpoint to rotate around.
//   n = Optional number of evenly distributed copies to be rotated around the ring.
//   sa = Starting angle, in degrees.  For use with `n`.  Angle is in degrees counter-clockwise from X-, when facing the origin from Y+.
//   r = Radius to move children left, away from cp, before rotating.  Makes rings of copies.
//   subrot = If false, don't sub-rotate children as they are copied around the ring.
//
// Side Effects:
//   `$ang` is set to the rotation angle of each child copy, and can be used to modify each child individually.
//
// Example:
//   yrot_copies([180, 270, 315])
//       cylinder(h=20, r1=5, r2=0);
//   color("red",0.333) cylinder(h=20, r1=5, r2=0);
//
// Example:
//   yrot_copies(n=6)
//       cylinder(h=20, r1=5, r2=0);
//   color("red",0.333) cylinder(h=20, r1=5, r2=0);
//
// Example:
//   yrot_copies(n=6, r=10)
//       yrot(-90) cylinder(h=20, r1=5, r2=0);
//   color("red",0.333) yrot(-90) cylinder(h=20, r1=5, r2=0);
//
// Example:
//   yrot_copies(n=6, r=10, sa=45)
//       yrot(-90) cylinder(h=20, r1=5, r2=0);
//   color("red",0.333) yrot(-90) cylinder(h=20, r1=5, r2=0);
//
// Example:
//   yrot_copies(n=6, r=20, subrot=false)
//       yrot(-90) cylinder(h=20, r1=5, r2=0, center=true);
//   color("red",0.333) yrot(-90) cylinder(h=20, r1=5, r2=0, center=true);
module yrot_copies(rots=[], cp=[0,0,0], n=undef, count=undef, sa=0, offset=0, r=0, subrot=true)
{
	cnt = first_defined([count, n]);
	sang = sa + offset;
	rot_copies(rots=rots, v=BACK, cp=cp, n=cnt, sa=sang, delta=[-r, 0, 0], subrot=subrot) children();
}


// Module: zrot_copies()
//
// Description:
//   Given an array of angles, rotates copies of the children
//   to each of those angles around the Z axis.
//
// Usage:
//   zrot_copies(rots, [r], [cp], [sa], [subrot]) ...
//   zrot_copies(n, [r], [cp], [sa], [subrot]) ...
//
// Arguments:
//   rots = Optional array of rotation angles, in degrees, to make copies at.
//   cp = Centerpoint to rotate around.
//   n = Optional number of evenly distributed copies to be rotated around the ring.
//   sa = Starting angle, in degrees.  For use with `n`.  Angle is in degrees counter-clockwise from X+, when facing the origin from Z+.
//   r = Radius to move children right, away from cp, before rotating.  Makes rings of copies.
//   subrot = If false, don't sub-rotate children as they are copied around the ring.
//
// Side Effects:
//   `$ang` is set to the rotation angle of each child copy, and can be used to modify each child individually.
//
// Example:
//   zrot_copies([180, 270, 315])
//       yrot(90) cylinder(h=20, r1=5, r2=0);
//   color("red",0.333) yrot(90) cylinder(h=20, r1=5, r2=0);
//
// Example:
//   zrot_copies(n=6)
//       yrot(90) cylinder(h=20, r1=5, r2=0);
//   color("red",0.333) yrot(90) cylinder(h=20, r1=5, r2=0);
//
// Example:
//   zrot_copies(n=6, r=10)
//       yrot(90) cylinder(h=20, r1=5, r2=0);
//   color("red",0.333) yrot(90) cylinder(h=20, r1=5, r2=0);
//
// Example:
//   zrot_copies(n=6, r=20, sa=45)
//       yrot(90) cylinder(h=20, r1=5, r2=0, center=true);
//   color("red",0.333) yrot(90) cylinder(h=20, r1=5, r2=0, center=true);
//
// Example:
//   zrot_copies(n=6, r=20, subrot=false)
//       yrot(-90) cylinder(h=20, r1=5, r2=0, center=true);
//   color("red",0.333) yrot(-90) cylinder(h=20, r1=5, r2=0, center=true);
module zrot_copies(rots=[], cp=[0,0,0], n=undef, count=undef, sa=0, offset=0, r=0, subrot=true)
{
	cnt = first_defined([count, n]);
	sang = sa + offset;
	rot_copies(rots=rots, v=UP, cp=cp, n=cnt, sa=sang, delta=[r, 0, 0], subrot=subrot) children();
}


// Module: xring()
// Description:
//   Distributes `n` copies of the given children on a circle of radius `r`
//   around the X axis.  If `rot` is true, each copy is rotated in place to keep
//   the same side towards the center.  The first, unrotated copy will be at the
//   starting angle `sa`.
// Usage:
//   xring(n, r, [sa], [cp], [rot]) ...
// Arguments:
//   n = Number of copies of children to distribute around the circle. (Default: 2)
//   r = Radius of ring to distribute children around. (Default: 0)
//   sa = Start angle for first (unrotated) copy.  (Default: 0)
//   cp = Centerpoint of ring.  Default: [0,0,0]
//   rot = If true, rotate each copy to keep the same side towards the center of the ring.  Default: true.
// Side Effects:
//   `$ang` is set to the rotation angle of each child copy, and can be used to modify each child individually.
//   `$idx` is set to the index value of each child copy.
// Examples:
//   xring(n=6, r=10) xrot(-90) cylinder(h=20, r1=5, r2=0);
//   xring(n=6, r=10, sa=45) xrot(-90) cylinder(h=20, r1=5, r2=0);
//   xring(n=6, r=20, rot=false) cylinder(h=20, r1=6, r2=0, center=true);
module xring(n=2, r=0, sa=0, cp=[0,0,0], rot=true)
{
	xrot_copies(count=n, r=r, sa=sa, cp=cp, subrot=rot) children();
}


// Module: yring()
// 
// Description:
//   Distributes `n` copies of the given children on a circle of radius `r`
//   around the Y axis.  If `rot` is true, each copy is rotated in place to keep
//   the same side towards the center.  The first, unrotated copy will be at the
//   starting angle `sa`.
//
// Usage:
//   yring(n, r, [sa], [cp], [rot]) ...
//
// Arguments:
//   n = Number of copies of children to distribute around the circle. (Default: 2)
//   r = Radius of ring to distribute children around. (Default: 0)
//   sa = Start angle for first (unrotated) copy.  (Default: 0)
//   cp = Centerpoint of ring.  Default: [0,0,0]
//   rot = If true, rotate each copy to keep the same side towards the center of the ring.  Default: true.
//
// Side Effects:
//   `$ang` is set to the rotation angle of each child copy, and can be used to modify each child individually.
//   `$idx` is set to the index value of each child copy.
//
// Examples:
//   yring(n=6, r=10) yrot(-90) cylinder(h=20, r1=5, r2=0);
//   yring(n=6, r=10, sa=45) yrot(-90) cylinder(h=20, r1=5, r2=0);
//   yring(n=6, r=20, rot=false) cylinder(h=20, r1=6, r2=0, center=true);
module yring(n=2, r=0, sa=0, cp=[0,0,0], rot=true)
{
	yrot_copies(count=n, r=r, sa=sa, cp=cp, subrot=rot) children();
}


// Module: zring()
//
// Description:
//   Distributes `n` copies of the given children on a circle of radius `r`
//   around the Z axis.  If `rot` is true, each copy is rotated in place to keep
//   the same side towards the center.  The first, unrotated copy will be at the
//   starting angle `sa`.
//
// Usage:
//   zring(r, n, [sa], [cp], [rot]) ...
//
// Arguments:
//   n = Number of copies of children to distribute around the circle. (Default: 2)
//   r = Radius of ring to distribute children around. (Default: 0)
//   sa = Start angle for first (unrotated) copy.  (Default: 0)
//   cp = Centerpoint of ring.  Default: [0,0,0]
//   rot = If true, rotate each copy to keep the same side towards the center of the ring.  Default: true.
//
// Side Effects:
//   `$ang` is set to the relative angle from `cp` of each child copy, and can be used to modify each child individually.
//   `$idx` is set to the index value of each child copy.
//
// Examples:
//   zring(n=6, r=10) yrot(90) cylinder(h=20, r1=5, r2=0);
//   zring(n=6, r=10, sa=45) yrot(90) cylinder(h=20, r1=5, r2=0);
//   zring(n=6, r=20, rot=false) yrot(90) cylinder(h=20, r1=6, r2=0, center=true);
module zring(n=2, r=0, sa=0, cp=[0,0,0], rot=true)
{
	zrot_copies(count=n, r=r, sa=sa, cp=cp, subrot=rot) children();
}


// Module: arc_of()
//
// Description:
//   Evenly distributes n duplicate children around an ovoid arc on the XY plane.
//
// Usage:
//   arc_of(r|d, n, [sa], [ea], [rot]
//   arc_of(rx|dx, ry|dy, n, [sa], [ea], [rot]
//
// Arguments:
//   n = number of copies to distribute around the circle. (Default: 6)
//   r = radius of circle (Default: 1)
//   rx = radius of ellipse on X axis. Used instead of r.
//   ry = radius of ellipse on Y axis. Used instead of r.
//   d = diameter of circle. (Default: 2)
//   dx = diameter of ellipse on X axis. Used instead of d.
//   dy = diameter of ellipse on Y axis. Used instead of d.
//   rot = whether to rotate the copied children.  (Default: false)
//   sa = starting angle. (Default: 0.0)
//   ea = ending angle. Will distribute copies CCW from sa to ea. (Default: 360.0)
//
// Side Effects:
//   `$ang` is set to the rotation angle of each child copy, and can be used to modify each child individually.
//   `$pos` is set to the relative centerpoint of each child copy, and can be used to modify each child individually.
//   `$idx` is set to the index value of each child copy.
//
// Example:
//   #cube(size=[10,3,3],center=true);
//   arc_of(d=40, n=5) cube(size=[10,3,3],center=true);
//
// Example:
//   #cube(size=[10,3,3],center=true);
//   arc_of(d=40, n=5, sa=45, ea=225) cube(size=[10,3,3],center=true);
//
// Example:
//   #cube(size=[10,3,3],center=true);
//   arc_of(r=15, n=8, rot=false) cube(size=[10,3,3],center=true);
//
// Example:
//   #cube(size=[10,3,3],center=true);
//   arc_of(rx=20, ry=10, n=8) cube(size=[10,3,3],center=true);
module arc_of(
	n=6,
	r=undef, rx=undef, ry=undef,
	d=undef, dx=undef, dy=undef,
	sa=0, ea=360,
	rot=true
) {
	rx = get_radius(rx, r, dx, d, 1);
	ry = get_radius(ry, r, dy, d, 1);
	sa = posmod(sa, 360);
	ea = posmod(ea, 360);
	n = (abs(ea-sa)<0.01)?(n+1):n;
	delt = (((ea<=sa)?360.0:0)+ea-sa)/(n-1);
	for ($idx = [0:1:n-1]) {
		$ang = sa + ($idx * delt);
		$pos =[rx*cos($ang), ry*sin($ang), 0];
		translate($pos) {
			zrot(rot? atan2(ry*sin($ang), rx*cos($ang)) : 0) {
				children();
			}
		}
	}
}



// Module: ovoid_spread()
//
// Description:
//   Spreads children semi-evenly over the surface of a sphere.
//
// Usage:
//   ovoid_spread(r|d, n, [cone_ang], [scale], [perp]) ...
//
// Arguments:
//   r = Radius of the sphere to distribute over
//   d = Diameter of the sphere to distribute over
//   n = How many copies to evenly spread over the surface.
//   cone_ang = Angle of the cone, in degrees, to limit how much of the sphere gets covered.  For full sphere coverage, use 180.  Measured pre-scaling.  Default: 180
//   scale = The [X,Y,Z] scaling factors to reshape the sphere being covered.
//   perp = If true, rotate children to be perpendicular to the sphere surface.  Default: true
//
// Side Effects:
//   `$pos` is set to the relative post-scaled centerpoint of each child copy, and can be used to modify each child individually.
//   `$theta` is set to the theta angle of the child from the center of the sphere.
//   `$phi` is set to the pre-scaled phi angle of the child from the center of the sphere.
//   `$rad` is set to the pre-scaled radial distance of the child from the center of the sphere.
//   `$idx` is set to the index number of each child being copied.
//
// Example:
//   ovoid_spread(n=250, d=100, cone_ang=45, scale=[3,3,1])
//       cylinder(d=10, h=10, center=false);
//
// Example:
//   ovoid_spread(n=500, d=100, cone_ang=180)
//       color(normalize(point3d(vabs($pos))))
//           cylinder(d=8, h=10, center=false);
module ovoid_spread(r=undef, d=undef, n=100, cone_ang=90, scale=[1,1,1], perp=true)
{
	r = get_radius(r=r, d=d, dflt=50);
	cnt = ceil(n / (cone_ang/180));

	// Calculate an array of [theta,phi] angles for `n` number of
	// points, almost evenly spaced across the surface of a sphere.
	// This approximation is based on the golden spiral method.
	theta_phis = [for (x=[0:1:n-1]) [180*(1+sqrt(5))*(x+0.5)%360, acos(1-2*(x+0.5)/cnt)]];

	for ($idx = [0:1:len(theta_phis)-1]) {
		tp = theta_phis[$idx];
		xyz = spherical_to_xyz(r, tp[0], tp[1]);
		$pos = vmul(xyz,scale);
		$theta = tp[0];
		$phi = tp[1];
		$rad = r;
		translate($pos) {
			if (perp) {
				rot(from=UP, to=xyz) children();
			} else {
				children();
			}
		}
	}
}



//////////////////////////////////////////////////////////////////////
// Section: Reflectional Distributors
//////////////////////////////////////////////////////////////////////


// Module: mirror_copy()
//
// Description:
//   Makes a copy of the children, mirrored across the given plane.
//
// Usage:
//   mirror_copy(v, [cp], [offset]) ...
//
// Arguments:
//   v = The normal vector of the plane to mirror across.
//   offset = distance to offset away from the plane.
//   cp = A point that lies on the mirroring plane.
//
// Side Effects:
//   `$orig` is true for the original instance of children.  False for the copy.
//   `$idx` is set to the index value of each copy.
//
// Example:
//   mirror_copy([1,-1,0]) zrot(-45) yrot(90) cylinder(d1=10, d2=0, h=20);
//   color("blue",0.25) zrot(-45) cube([0.01,15,15], center=true);
//
// Example:
//   mirror_copy([1,1,0], offset=5) rot(a=90,v=[-1,1,0]) cylinder(d1=10, d2=0, h=20);
//   color("blue",0.25) zrot(45) cube([0.01,15,15], center=true);
//
// Example:
//   mirror_copy(UP+BACK, cp=[0,-5,-5]) rot(from=UP, to=BACK+UP) cylinder(d1=10, d2=0, h=20);
//   color("blue",0.25) translate([0,-5,-5]) rot(from=UP, to=BACK+UP) cube([15,15,0.01], center=true);
module mirror_copy(v=[0,0,1], offset=0, cp=[0,0,0])
{
	nv = v/norm(v);
	off = nv*offset;
	if (cp == [0,0,0]) {
		translate(off) {
			$orig = true;
			$idx = 0;
			children();
		}
		mirror(nv) translate(off) {
			$orig = false;
			$idx = 1;
			children();
		}
	} else {
		translate(off) children();
		translate(cp) mirror(nv) translate(-cp) translate(off) children();
	}
}


// Module: xflip_copy()
//
// Description:
//   Makes a copy of the children, mirrored across the X axis.
//
// Usage:
//   xflip_copy([x], [offset]) ...
//
// Arguments:
//   offset = Distance to offset children right, before copying.
//   x = The X coordinate of the mirroring plane.  Default: 0
//
// Side Effects:
//   `$orig` is true for the original instance of children.  False for the copy.
//   `$idx` is set to the index value of each copy.
//
// Example:
//   xflip_copy() yrot(90) cylinder(h=20, r1=4, r2=0);
//   color("blue",0.25) cube([0.01,15,15], center=true);
//
// Example:
//   xflip_copy(offset=5) yrot(90) cylinder(h=20, r1=4, r2=0);
//   color("blue",0.25) cube([0.01,15,15], center=true);
//
// Example:
//   xflip_copy(x=-5) yrot(90) cylinder(h=20, r1=4, r2=0);
//   color("blue",0.25) left(5) cube([0.01,15,15], center=true);
module xflip_copy(offset=0, x=0)
{
	mirror_copy(v=[1,0,0], offset=offset, cp=[x,0,0]) children();
}


// Module: yflip_copy()
//
// Description:
//   Makes a copy of the children, mirrored across the Y axis.
//
// Usage:
//   yflip_copy([y], [offset]) ...
//
// Arguments:
//   offset = Distance to offset children back, before copying.
//   y = The Y coordinate of the mirroring plane.  Default: 0
//
// Side Effects:
//   `$orig` is true for the original instance of children.  False for the copy.
//   `$idx` is set to the index value of each copy.
//
// Example:
//   yflip_copy() xrot(-90) cylinder(h=20, r1=4, r2=0);
//   color("blue",0.25) cube([15,0.01,15], center=true);
//
// Example:
//   yflip_copy(offset=5) xrot(-90) cylinder(h=20, r1=4, r2=0);
//   color("blue",0.25) cube([15,0.01,15], center=true);
//
// Example:
//   yflip_copy(y=-5) xrot(-90) cylinder(h=20, r1=4, r2=0);
//   color("blue",0.25) fwd(5) cube([15,0.01,15], center=true);
module yflip_copy(offset=0, y=0)
{
	mirror_copy(v=[0,1,0], offset=offset, cp=[0,y,0]) children();
}


// Module: zflip_copy()
//
// Description:
//   Makes a copy of the children, mirrored across the Z axis.
//
// Usage:
//   zflip_copy([z], [offset]) ...
//
// Arguments:
//   offset = Distance to offset children up, before copying.
//   z = The Z coordinate of the mirroring plane.  Default: 0
//
// Side Effects:
//   `$orig` is true for the original instance of children.  False for the copy.
//   `$idx` is set to the index value of each copy.
//
// Example:
//   zflip_copy() cylinder(h=20, r1=4, r2=0);
//   color("blue",0.25) cube([15,15,0.01], center=true);
//
// Example:
//   zflip_copy(offset=5) cylinder(h=20, r1=4, r2=0);
//   color("blue",0.25) cube([15,15,0.01], center=true);
//
// Example:
//   zflip_copy(z=-5) cylinder(h=20, r1=4, r2=0);
//   color("blue",0.25) down(5) cube([15,15,0.01], center=true);
module zflip_copy(offset=0, z=0)
{
	mirror_copy(v=[0,0,1], offset=offset, cp=[0,0,z]) children();
}


//////////////////////////////////////////////////////////////////////
// Section: Mutators
//////////////////////////////////////////////////////////////////////


// Module: half_of()
//
// Usage:
//   half_of(v, [cp], [s]) ...
//
// Description:
//   Slices an object at a cut plane, and masks away everything that is on one side.
//
// Arguments:
//   v = Normal of plane to slice at.  Keeps everything on the side the normal points to.  Default: [0,0,1] (UP)
//   cp = If given as a scalar, moves the cut plane along the normal by the given amount.  If given as a point, specifies a point on the cut plane.  This can be used to shift where it slices the object at.  Default: [0,0,0]
//   s = Mask size to use.  Use a number larger than twice your object's largest axis.  If you make this too large, it messes with centering your view.  Default: 100
//   planar = If true, this becomes a 2D operation.  When planar, a `v` of `UP` or `DOWN` becomes equivalent of `BACK` and `FWD` respectively.
//
// Examples:
//   half_of(DOWN+BACK, cp=[0,-10,0]) cylinder(h=40, r1=10, r2=0, center=false);
//   half_of(DOWN+LEFT, s=200) sphere(d=150);
// Example(2D):
//   half_of([1,1], planar=true) circle(d=50);
module half_of(v=UP, cp=[0,0,0], s=100, planar=false)
{
	cp = is_num(cp)? cp*normalize(v) : cp;
	if (cp != [0,0,0]) {
		translate(cp) half_of(v=v, s=s, planar=planar) translate(-cp) children();
	} else if (planar) {
		v = (v==UP)? BACK : (v==DOWN)? FWD : v;
		ang = atan2(v.y, v.x);
		difference() {
			children();
			rotate(ang+90) {
				back(s/2) square(s, center=true);
			}
		}
	} else {
		difference() {
			children();
			rot(from=UP, to=-v) {
				up(s/2) cube(s, center=true);
			}
		}
	}
}


// Module: left_half()
//
// Usage:
//   left_half([s], [x]) ...
//   left_half(planar=true, [s], [x]) ...
//
// Description:
//   Slices an object at a vertical Y-Z cut plane, and masks away everything that is right of it.
//
// Arguments:
//   s = Mask size to use.  Use a number larger than twice your object's largest axis.  If you make this too large, it messes with centering your view.  Default: 100
//   x = The X coordinate of the cut-plane.  Default: 0
//   planar = If true, this becomes a 2D operation.
//
// Examples:
//   left_half() sphere(r=20);
//   left_half(x=-8) sphere(r=20);
// Example(2D):
//   left_half(planar=true) circle(r=20);
module left_half(s=100, x=0, planar=false)
{
	dir = LEFT;
	difference() {
		children();
		translate([x,0,0]-dir*s/2) {
			if (planar) {
				square(s, center=true);
			} else {
				cube(s, center=true);
			}
		}
	}
}



// Module: right_half()
//
// Usage:
//   right_half([s], [x]) ...
//   right_half(planar=true, [s], [x]) ...
//
// Description:
//   Slices an object at a vertical Y-Z cut plane, and masks away everything that is left of it.
//
// Arguments:
//   s = Mask size to use.  Use a number larger than twice your object's largest axis.  If you make this too large, it messes with centering your view.  Default: 100
//   x = The X coordinate of the cut-plane.  Default: 0
//   planar = If true, this becomes a 2D operation.
//
// Examples(FlatSpin):
//   right_half() sphere(r=20);
//   right_half(x=-5) sphere(r=20);
// Example(2D):
//   right_half(planar=true) circle(r=20);
module right_half(s=100, x=0, planar=false)
{
	dir = RIGHT;
	difference() {
		children();
		translate([x,0,0]-dir*s/2) {
			if (planar) {
				square(s, center=true);
			} else {
				cube(s, center=true);
			}
		}
	}
}



// Module: front_half()
//
// Usage:
//   front_half([s], [y]) ...
//   front_half(planar=true, [s], [y]) ...
//
// Description:
//   Slices an object at a vertical X-Z cut plane, and masks away everything that is behind it.
//
// Arguments:
//   s = Mask size to use.  Use a number larger than twice your object's largest axis.  If you make this too large, it messes with centering your view.  Default: 100
//   y = The Y coordinate of the cut-plane.  Default: 0
//   planar = If true, this becomes a 2D operation.
//
// Examples(FlatSpin):
//   front_half() sphere(r=20);
//   front_half(y=5) sphere(r=20);
// Example(2D):
//   front_half(planar=true) circle(r=20);
module front_half(s=100, y=0, planar=false)
{
	dir = FWD;
	difference() {
		children();
		translate([0,y,0]-dir*s/2) {
			if (planar) {
				square(s, center=true);
			} else {
				cube(s, center=true);
			}
		}
	}
}



// Module: back_half()
//
// Usage:
//   back_half([s], [y]) ...
//   back_half(planar=true, [s], [y]) ...
//
// Description:
//   Slices an object at a vertical X-Z cut plane, and masks away everything that is in front of it.
//
// Arguments:
//   s = Mask size to use.  Use a number larger than twice your object's largest axis.  If you make this too large, it messes with centering your view.  Default: 100
//   y = The Y coordinate of the cut-plane.  Default: 0
//   planar = If true, this becomes a 2D operation.
//
// Examples:
//   back_half() sphere(r=20);
//   back_half(y=8) sphere(r=20);
// Example(2D):
//   back_half(planar=true) circle(r=20);
module back_half(s=100, y=0, planar=false)
{
	dir = BACK;
	difference() {
		children();
		translate([0,y,0]-dir*s/2) {
			if (planar) {
				square(s, center=true);
			} else {
				cube(s, center=true);
			}
		}
	}
}



// Module: bottom_half()
//
// Usage:
//   bottom_half([s], [z]) ...
//
// Description:
//   Slices an object at a horizontal X-Y cut plane, and masks away everything that is above it.
//
// Arguments:
//   s = Mask size to use.  Use a number larger than twice your object's largest axis.  If you make this too large, it messes with centering your view.  Default: 100
//   z = The Z coordinate of the cut-plane.  Default: 0
//
// Examples:
//   bottom_half() sphere(r=20);
//   bottom_half(z=-10) sphere(r=20);
module bottom_half(s=100, z=0)
{
	dir = DOWN;
	difference() {
		children();
		translate([0,0,z]-dir*s/2) {
			cube(s, center=true);
		}
	}
}



// Module: top_half()
//
// Usage:
//   top_half([s], [z]) ...
//
// Description:
//   Slices an object at a horizontal X-Y cut plane, and masks away everything that is below it.
//
// Arguments:
//   s = Mask size to use.  Use a number larger than twice your object's largest axis.  If you make this too large, it messes with centering your view.  Default: 100
//   z = The Z coordinate of the cut-plane.  Default: 0
//
// Examples(Spin):
//   top_half() sphere(r=20);
//   top_half(z=5) sphere(r=20);
module top_half(s=100, z=0)
{
	dir = UP;
	difference() {
		children();
		translate([0,0,z]-dir*s/2) {
			cube(s, center=true);
		}
	}
}



// Module: chain_hull()
//
// Usage:
//   chain_hull() ...
//
// Description:
//   Performs hull operations between consecutive pairs of children,
//   then unions all of the hull results.  This can be a very slow
//   operation, but it can provide results that are hard to get
//   otherwise.
//
// Example:
//   chain_hull() {
//       cube(5, center=true);
//       translate([30, 0, 0]) sphere(d=15);
//       translate([60, 30, 0]) cylinder(d=10, h=20);
//       translate([60, 60, 0]) cube([10,1,20], center=false);
//   }
module chain_hull()
{
	union() {
		if ($children == 1) {
			children();
		} else if ($children > 1) {
			for (i =[1:1:$children-1]) {
				hull() {
					children(i-1);
					children(i);
				}
			}
		}
	}
}



//////////////////////////////////////////////////////////////////////
// Section: 2D Mutators
//////////////////////////////////////////////////////////////////////


// Module: round2d()
// Usage:
//   round2d(r) ...
//   round2d(or) ...
//   round2d(ir) ...
//   round2d(or, ir) ...
// Description:
//   Rounds an arbitrary 2d objects.  Giving `r` rounds all concave and
//   convex corners.  Giving just `ir` rounds just concave corners.
//   Giving just `or` rounds convex corners.  Giving both `ir` and `or`
//   can let you round to different radii for concave and convex corners.
//   The 2d object must not have any parts narrower than twice the `or`
//   radius.  Such parts will disappear.
// Arguments:
//   r = Radius to round all concave and convex corners to.
//   or = Radius to round only outside (convex) corners to.  Use instead of `r`.
//   ir = Radius to round only inside (concave) corners to.  Use instead of `r`.
// Examples(2D):
//   round2d(r=10) {square([40,100], center=true); square([100,40], center=true);}
//   round2d(or=10) {square([40,100], center=true); square([100,40], center=true);}
//   round2d(ir=10) {square([40,100], center=true); square([100,40], center=true);}
//   round2d(or=16,ir=8) {square([40,100], center=true); square([100,40], center=true);}
module round2d(r, or, ir)
{
	or = get_radius(r1=or, r=r, dflt=0);
	ir = get_radius(r1=ir, r=r, dflt=0);
	offset(or) offset(-ir-or) offset(delta=ir) children();
}


// Module: shell2d()
// Usage:
//   shell2d(thickness, [or], [ir], [fill], [round])
// Description:
//   Creates a hollow shell from 2d children, with optional rounding.
// Arguments:
//   thickness = Thickness of the shell.  Positive to expand outward, negative to shrink inward, or a two-element list to do both.
//   or = Radius to round convex corners/pointy bits on the outside of the shell.
//   ir = Radius to round concave corners on the outside of the shell.
//   round = Radius to round convex corners/pointy bits on the inside of the shell.
//   fill = Radius to round concave corners on the inside of the shell.
// Examples(2D):
//   shell2d(10) {square([40,100], center=true); square([100,40], center=true);}
//   shell2d(-10) {square([40,100], center=true); square([100,40], center=true);}
//   shell2d([-10,10]) {square([40,100], center=true); square([100,40], center=true);}
//   shell2d(10,or=10) {square([40,100], center=true); square([100,40], center=true);}
//   shell2d(10,ir=10) {square([40,100], center=true); square([100,40], center=true);}
//   shell2d(10,round=10) {square([40,100], center=true); square([100,40], center=true);}
//   shell2d(10,fill=10) {square([40,100], center=true); square([100,40], center=true);}
//   shell2d(8,or=16,ir=8,round=16,fill=8) {square([40,100], center=true); square([100,40], center=true);}
module shell2d(thickness, or=0, ir=0, fill=0, round=0)
{
	thickness = is_num(thickness)? (
		thickness<0? [thickness,0] : [0,thickness]
	) : (thickness[0]>thickness[1])? (
		[thickness[1],thickness[0]]
	) : thickness;
	difference() {
		round2d(or=or,ir=ir)
			offset(delta=thickness[1])
				children();
		round2d(or=fill,ir=round)
			offset(delta=thickness[0])
				children();
	}
}



// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
