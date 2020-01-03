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
// Usage: As Module
//   move([x], [y], [z]) ...
//   move(v) ...
// Usage: Translate Points
//   pts = move(v, p);
//   pts = move([x], [y], [z], p);
// Usage: Get Translation Matrix
//   mat = move(v);
//
// Description:
//   Translates position by the given amount.
//   * Called as a module, moves/translates all children.
//   * Called as a function with a point in the `p` argument, returns the translated point.
//   * Called as a function with a list of points in the `p` argument, returns the translated list of points.
//   * Called as a function with a [bezier patch](beziers.scad) in the `p` argument, returns the translated patch.
//   * Called as a function with a [VNF structure](vnf.scad) in the `p` argument, returns the translated VNF.
//   * Called as a function with the `p` argument, returns the translated point or list of points.
//   * Called as a function without a `p` argument, with a 2D offset vector `v`, returns an affine2d translation matrix.
//   * Called as a function without a `p` argument, with a 3D offset vector `v`, returns an affine3d translation matrix.
//
// Arguments:
//   v = An [X,Y,Z] vector to translate by.
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
// Example(2D):
//   path = square([50,30], center=true);
//   #stroke(path, closed=true);
//   stroke(move([10,20],p=path), closed=true);
//
// Example(NORENDER):
//   pt1 = move([0,20,30], p=[15,23,42]);       // Returns: [15, 43, 72]
//   pt2 = move(y=10, p=[15,23,42]);            // Returns: [15, 33, 42]
//   pt3 = move([0,3,1], p=[[1,2,3],[4,5,6]]);  // Returns: [[1,5,4], [4,8,7]]
//   pt4 = move(y=11, p=[[1,2,3],[4,5,6]]);     // Returns: [[1,13,3], [4,16,6]]
//   mat2d = move([2,3]);    // Returns: [[1,0,2],[0,1,3],[0,0,1]]
//   mat3d = move([2,3,4]);  // Returns: [[1,0,0,2],[0,1,0,3],[0,0,1,4],[0,0,0,1]]
module move(v=[0,0,0], x=0, y=0, z=0)
{
	translate(v+[x,y,z]) children();
}

function move(v=[0,0,0], p=undef, x=0, y=0, z=0) =
	is_undef(p)? (
		len(v)==2? affine2d_translate(v+[x,y]) :
		affine3d_translate(point3d(v)+[x,y,z])
	) : (
		assert(is_list(p))
		let(v=v+[x,y,z])
		is_num(p.x)? p+v :
		is_vnf(p)? [move(v=v,p=p.x), p.y] :
		[for (l=p) is_vector(l)? l+v : move(v=v, p=l)]
	);

function translate(v=[0,0,0], p=undef) = move(v=v, p=p);


// Function&Module: left()
//
// Usage: As Module
//   left(x) ...
// Usage: Translate Points
//   pts = left(x, p);
// Usage: Get Translation Matrix
//   mat = left(x);
//
// Description:
//   If called as a module, moves/translates all children left (in the X- direction) by the given amount.
//   If called as a function with the `p` argument, returns the translated point or list of points.
//   If called as a function without the `p` argument, returns an affine3d translation matrix.
//
// Arguments:
//   x = Scalar amount to move left.
//   p = Either a point, or a list of points to be translated when used as a function.
//
// Example:
//   #sphere(d=10);
//   left(20) sphere(d=10);
//
// Example(NORENDER):
//   pt1 = left(20, p=[23,42]);           // Returns: [3,42]
//   pt2 = left(20, p=[15,23,42]);        // Returns: [-5,23,42]
//   pt3 = left(3, p=[[1,2,3],[4,5,6]]);  // Returns: [[-2,2,3], [1,5,6]]
//   mat3d = left(4);  // Returns: [[1,0,0,-4],[0,1,0,0],[0,0,1,0],[0,0,0,1]]
module left(x=0) translate([-x,0,0]) children();

function left(x=0,p=undef) = move([-x,0,0],p=p);


// Function&Module: right()
//
// Usage: As Module
//   right(x) ...
// Usage: Translate Points
//   pts = right(x, p);
// Usage: Get Translation Matrix
//   mat = right(x);
//
// Description:
//   If called as a module, moves/translates all children right (in the X+ direction) by the given amount.
//   If called as a function with the `p` argument, returns the translated point or list of points.
//   If called as a function without the `p` argument, returns an affine3d translation matrix.
//
// Arguments:
//   x = Scalar amount to move right.
//   p = Either a point, or a list of points to be translated when used as a function.
//
// Example:
//   #sphere(d=10);
//   right(20) sphere(d=10);
//
// Example(NORENDER):
//   pt1 = right(20, p=[23,42]);           // Returns: [43,42]
//   pt2 = right(20, p=[15,23,42]);        // Returns: [35,23,42]
//   pt3 = right(3, p=[[1,2,3],[4,5,6]]);  // Returns: [[4,2,3], [7,5,6]]
//   mat3d = right(4);  // Returns: [[1,0,0,4],[0,1,0,0],[0,0,1,0],[0,0,0,1]]
module right(x=0) translate([x,0,0]) children();

function right(x=0,p=undef) = move([x,0,0],p=p);


// Function&Module: fwd()
//
// Usage: As Module
//   fwd(y) ...
// Usage: Translate Points
//   pts = fwd(y, p);
// Usage: Get Translation Matrix
//   mat = fwd(y);
//
// Description:
//   If called as a module, moves/translates all children forward (in the Y- direction) by the given amount.
//   If called as a function with the `p` argument, returns the translated point or list of points.
//   If called as a function without the `p` argument, returns an affine3d translation matrix.
//
// Arguments:
//   y = Scalar amount to move forward.
//   p = Either a point, or a list of points to be translated when used as a function.
//
// Example:
//   #sphere(d=10);
//   fwd(20) sphere(d=10);
//
// Example(NORENDER):
//   pt1 = fwd(20, p=[23,42]);           // Returns: [23,22]
//   pt2 = fwd(20, p=[15,23,42]);        // Returns: [15,3,42]
//   pt3 = fwd(3, p=[[1,2,3],[4,5,6]]);  // Returns: [[1,-1,3], [4,2,6]]
//   mat3d = fwd(4);  // Returns: [[1,0,0,0],[0,1,0,-4],[0,0,1,0],[0,0,0,1]]
module fwd(y=0) translate([0,-y,0]) children();

function fwd(y=0,p=undef) = move([0,-y,0],p=p);


// Function&Module: back()
//
// Usage: As Module
//   back(y) ...
// Usage: Translate Points
//   pts = back(y, p);
// Usage: Get Translation Matrix
//   mat = back(y);
//
// Description:
//   If called as a module, moves/translates all children back (in the Y+ direction) by the given amount.
//   If called as a function with the `p` argument, returns the translated point or list of points.
//   If called as a function without the `p` argument, returns an affine3d translation matrix.
//
// Arguments:
//   y = Scalar amount to move back.
//   p = Either a point, or a list of points to be translated when used as a function.
//
// Example:
//   #sphere(d=10);
//   back(20) sphere(d=10);
//
// Example(NORENDER):
//   pt1 = back(20, p=[23,42]);           // Returns: [23,62]
//   pt2 = back(20, p=[15,23,42]);        // Returns: [15,43,42]
//   pt3 = back(3, p=[[1,2,3],[4,5,6]]);  // Returns: [[1,5,3], [4,8,6]]
//   mat3d = back(4);  // Returns: [[1,0,0,0],[0,1,0,4],[0,0,1,0],[0,0,0,1]]
module back(y=0) translate([0,y,0]) children();

function back(y=0,p=undef) = move([0,y,0],p=p);


// Function&Module: down()
//
// Usage: As Module
//   down(z) ...
// Usage: Translate Points
//   pts = down(z, p);
// Usage: Get Translation Matrix
//   mat = down(z);
//
// Description:
//   If called as a module, moves/translates all children down (in the Z- direction) by the given amount.
//   If called as a function with the `p` argument, returns the translated point or list of points.
//   If called as a function without the `p` argument, returns an affine3d translation matrix.
//
// Arguments:
//   z = Scalar amount to move down.
//   p = Either a point, or a list of points to be translated when used as a function.
//
// Example:
//   #sphere(d=10);
//   down(20) sphere(d=10);
//
// Example(NORENDER):
//   pt1 = down(20, p=[15,23,42]);        // Returns: [15,23,22]
//   pt2 = down(3, p=[[1,2,3],[4,5,6]]);  // Returns: [[1,2,0], [4,5,3]]
//   mat3d = down(4);  // Returns: [[1,0,0,0],[0,1,0,0],[0,0,1,-4],[0,0,0,1]]
module down(z=0) translate([0,0,-z]) children();

function down(z=0,p=undef) = move([0,0,-z],p=p);


// Function&Module: up()
//
// Usage: As Module
//   up(z) ...
// Usage: Translate Points
//   pts = up(z, p);
// Usage: Get Translation Matrix
//   mat = up(z);
//
// Description:
//   If called as a module, moves/translates all children up (in the Z+ direction) by the given amount.
//   If called as a function with the `p` argument, returns the translated point or list of points.
//   If called as a function without the `p` argument, returns an affine3d translation matrix.
//
// Arguments:
//   z = Scalar amount to move up.
//   p = Either a point, or a list of points to be translated when used as a function.
//
// Example:
//   #sphere(d=10);
//   up(20) sphere(d=10);
//
// Example(NORENDER):
//   pt1 = up(20, p=[15,23,42]);        // Returns: [15,23,62]
//   pt2 = up(3, p=[[1,2,3],[4,5,6]]);  // Returns: [[1,2,6], [4,5,9]]
//   mat3d = up(4);  // Returns: [[1,0,0,0],[0,1,0,0],[0,0,1,4],[0,0,0,1]]
module up(z=0) translate([0,0,z]) children();

function up(z=0,p=undef) = move([0,0,z],p=p);



//////////////////////////////////////////////////////////////////////
// Section: Rotations
//////////////////////////////////////////////////////////////////////


// Function&Module: rot()
//
// Usage:
//   rot(a, [cp], [reverse]) ...
//   rot([X,Y,Z], [cp], [reverse]) ...
//   rot(a, v, [cp], [reverse]) ...
//   rot(from, to, [a], [reverse]) ...
//
// Description:
//   This is a shorthand version of the built-in `rotate()`, and operates similarly, with a few additional capabilities.
//   You can specify the rotation to perform in one of several ways:
//   * `rot(30)` or `rot(a=30)` rotates 30 degrees around the Z axis.
//   * `rot([20,30,40])` or `rot(a=[20,30,40])` rotates 20 degrees around the X axis, then 30 degrees around the Y axis, then 40 degrees around the Z axis.
//   * `rot(30, [1,1,0])` or `rot(a=30, v=[1,1,0])` rotates 30 degrees around the axis vector `[1,1,0]`.
//   * `rot(from=[0,0,1], to=[1,0,0])` rotates the top towards the right, similar to `rot(a=90,v=[0,1,0]`.
//   * `rot(from=[0,0,1], to=[1,1,0], a=45)` rotates 45 degrees around the Z axis, then rotates the top towards the back-right.  Similar to `rot(a=90,v=[-1,1,0])`
//   If the `cp` centerpoint argument is given, then rotations are performed around that centerpoint.
//   If the `reverse` argument is true, then the rotations performed will be exactly reversed.
//   The behavior and return value varies depending on how `rot()` is called:
//   * Called as a module, rotates all children.
//   * Called as a function with a `p` argument containing a point, returns the rotated point.
//   * Called as a function with a `p` argument containing a list of points, returns the list of rotated points.
//   * Called as a function with a [bezier patch](beziers.scad) in the `p` argument, returns the rotated patch.
//   * Called as a function with a [VNF structure](vnf.scad) in the `p` argument, returns the rotated VNF.
//   * Called as a function without a `p` argument, and `planar` is true, returns the affine2d rotational matrix.
//   * Called as a function without a `p` argument, and `planar` is false, returns the affine3d rotational matrix.
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
//
// Example(2D):
//   path = square([50,30], center=true);
//   #stroke(path, closed=true);
//   stroke(rot(30,p=path), closed=true);
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
		assert(is_list(p))
		is_num(p.x)? (
			rot(a=a, v=v, cp=cp, from=from, to=to, reverse=reverse, p=[p], planar=planar)[0]
		) : is_vnf(p)? (
			[rot(a=a, v=v, cp=cp, from=from, to=to, reverse=reverse, p=p.x, planar=planar), p.y]
		) : is_list(p.x) && is_list(p.x.x)? (
			[for (l=p) rot(a=a, v=v, cp=cp, from=from, to=to, reverse=reverse, p=l, planar=planar)]
		) : (
			(
				(planar || (p!=[] && len(p[0])==2)) && !(
					(is_vector(a) && norm(point2d(a))>0) ||
					(!is_undef(v) && norm(point2d(v))>0 && !approx(a,0)) ||
					(!is_undef(from) && !approx(from,to) && !(abs(from.z)>0 || abs(to.z))) ||
					(!is_undef(from) && approx(from,to) && norm(point2d(from))>0 && a!=0)
				)
			)? (
				is_undef(from)? rotate_points2d(p, a=a*rev, cp=cp) : (
					approx(from,to)&&approx(a,0)? p :
					rotate_points2d(p, a=vector_angle(from,to)*sign(vector_axis(from,to)[2])*rev, cp=cp)
				)
			) : (
				rotate_points3d(p, a=a, v=v, cp=(is_undef(cp)? [0,0,0] : cp), from=from, to=to, reverse=reverse)
			)
		)
	);




// Function&Module: xrot()
//
// Usage: As Module
//   xrot(a, [cp]) ...
// Usage: Rotate Points
//   rotated = xrot(a, p, [cp]);
// Usage: Get Rotation Matrix
//   mat = xrot(a, [cp]);
//
// Description:
//   Rotates around the X axis by the given number of degrees.  If `cp` is given, rotations are performed around that centerpoint.
//   * Called as a module, rotates all children.
//   * Called as a function with a `p` argument containing a point, returns the rotated point.
//   * Called as a function with a `p` argument containing a list of points, returns the list of rotated points.
//   * Called as a function with a [bezier patch](beziers.scad) in the `p` argument, returns the rotated patch.
//   * Called as a function with a [VNF structure](vnf.scad) in the `p` argument, returns the rotated VNF.
//   * Called as a function without a `p` argument, and `planar` is true, returns the affine2d rotational matrix.
//   * Called as a function without a `p` argument, and `planar` is false, returns the affine3d rotational matrix.
//
// Arguments:
//   a = angle to rotate by in degrees.
//   cp = centerpoint to rotate around. Default: [0,0,0]
//   p = If called as a function, this contains a point or list of points to rotate.
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

function xrot(a=0, cp=undef, p=undef) = rot([a,0,0], cp=cp, p=p);


// Function&Module: yrot()
//
// Usage: As Module
//   yrot(a, [cp]) ...
// Usage: Rotate Points
//   rotated = yrot(a, p, [cp]);
// Usage: Get Rotation Matrix
//   mat = yrot(a, [cp]);
//
// Description:
//   Rotates around the Y axis by the given number of degrees.  If `cp` is given, rotations are performed around that centerpoint.
//   * Called as a module, rotates all children.
//   * Called as a function with a `p` argument containing a point, returns the rotated point.
//   * Called as a function with a `p` argument containing a list of points, returns the list of rotated points.
//   * Called as a function with a [bezier patch](beziers.scad) in the `p` argument, returns the rotated patch.
//   * Called as a function with a [VNF structure](vnf.scad) in the `p` argument, returns the rotated VNF.
//   * Called as a function without a `p` argument, and `planar` is true, returns the affine2d rotational matrix.
//   * Called as a function without a `p` argument, and `planar` is false, returns the affine3d rotational matrix.
//
// Arguments:
//   a = angle to rotate by in degrees.
//   cp = centerpoint to rotate around. Default: [0,0,0]
//   p = If called as a function, this contains a point or list of points to rotate.
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

function yrot(a=0, cp=undef, p=undef) = rot([0,a,0], cp=cp, p=p);


// Function&Module: zrot()
//
// Usage: As Module
//   zrot(a, [cp]) ...
// Usage: Rotate Points
//   rotated = zrot(a, p, [cp]);
// Usage: Get Rotation Matrix
//   mat = zrot(a, [cp]);
//
// Description:
//   Rotates around the Z axis by the given number of degrees.  If `cp` is given, rotations are performed around that centerpoint.
//   * Called as a module, rotates all children.
//   * Called as a function with a `p` argument containing a point, returns the rotated point.
//   * Called as a function with a `p` argument containing a list of points, returns the list of rotated points.
//   * Called as a function with a [bezier patch](beziers.scad) in the `p` argument, returns the rotated patch.
//   * Called as a function with a [VNF structure](vnf.scad) in the `p` argument, returns the rotated VNF.
//   * Called as a function without a `p` argument, and `planar` is true, returns the affine2d rotational matrix.
//   * Called as a function without a `p` argument, and `planar` is false, returns the affine3d rotational matrix.
//
// Arguments:
//   a = angle to rotate by in degrees.
//   cp = centerpoint to rotate around. Default: [0,0,0]
//   p = If called as a function, this contains a point or list of points to rotate.
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

function zrot(a=0, cp=undef, p=undef) = rot(a, cp=cp, p=p);


//////////////////////////////////////////////////////////////////////
// Section: Scaling and Mirroring
//////////////////////////////////////////////////////////////////////


// Function&Module: scale()
// Usage: As Module
//   scale(SCALAR) ...
//   scale([X,Y,Z]) ...
// Usage: Scale Points
//   pts = scale(v, p);
// Usage: Get Scaling Matrix
//   mat = scale(v);
// Description:
//   Scales by the [X,Y,Z] scaling factors given in `v`.  If `v` is given as a scalar number, all axes are scaled uniformly by that amount.
//   * Called as the built-in module, scales all children.
//   * Called as a function with a point in the `p` argument, returns the scaled point.
//   * Called as a function with a list of points in the `p` argument, returns the list of scaled points.
//   * Called as a function with a [bezier patch](beziers.scad) in the `p` argument, returns the scaled patch.
//   * Called as a function with a [VNF structure](vnf.scad) in the `p` argument, returns the scaled VNF.
//   * Called as a function without a `p` argument, and a 2D list of scaling factors in `v`, returns an affine2d scaling matrix.
//   * Called as a function without a `p` argument, and a 3D list of scaling factors in `v`, returns an affine3d scaling matrix.
// Arguments:
//   v = Either a numeric uniform scaling factor, or a list of [X,Y,Z] scaling factors.  Default: 1
//   p = If called as a function, the point or list of points to scale.
// Example(NORENDER):
//   pt1 = scale(3, p=[3,1,4]);        // Returns: [9,3,12]
//   pt2 = scale([2,3,4], p=[3,1,4]);  // Returns: [6,3,16]
//   pt3 = scale([2,3,4], p=[[1,2,3],[4,5,6]]);  // Returns: [[2,6,12], [8,15,24]]
//   mat2d = scale([2,3]);    // Returns: [[2,0,0],[0,3,0],[0,0,1]]
//   mat3d = scale([2,3,4]);  // Returns: [[2,0,0,0],[0,3,0,0],[0,0,4,0],[0,0,0,1]]
// Example(2D):
//   path = circle(d=50,$fn=12);
//   #stroke(path,closed=true);
//   stroke(scale([1.5,3],p=path),closed=true);
function scale(v=1, p=undef) =
	let(v = is_num(v)? [v,v,v] : v)
	is_undef(p)? (
		len(v)==2? affine2d_scale(v) : affine3d_scale(point3d(v))
	) : (
		assert(is_list(p))
		is_num(p.x)? vmul(p,v) :
		is_vnf(p)? let(inv=product([for (x=v) x<0? -1 : 1])) [
			scale(v=v,p=p.x),
			inv>=0? p.y : [for (l=p.y) reverse(l)]
		] :
		[for (l=p) is_vector(l)? vmul(l,v) : scale(v=v, p=l)]
	);


// Function&Module: xscale()
//
//
// Usage: As Module
//   xscale(x) ...
// Usage: Scale Points
//   scaled = xscale(x, p);
// Usage: Get Affine Matrix
//   mat = xscale(x);
//
// Description:
//   Scales along the X axis by the scaling factor `x`.
//   * Called as the built-in module, scales all children.
//   * Called as a function with a point in the `p` argument, returns the scaled point.
//   * Called as a function with a list of points in the `p` argument, returns the list of scaled points.
//   * Called as a function with a [bezier patch](beziers.scad) in the `p` argument, returns the scaled patch.
//   * Called as a function with a [VNF structure](vnf.scad) in the `p` argument, returns the scaled VNF.
//   * Called as a function without a `p` argument, and a 2D list of scaling factors in `v`, returns an affine2d scaling matrix.
//   * Called as a function without a `p` argument, and a 3D list of scaling factors in `v`, returns an affine3d scaling matrix.
//
// Arguments:
//   x = Factor to scale by, along the X axis.
//   p = A point or path to scale, when called as a function.
//   planar = If true, and `p` is not given, then the matrix returned is an affine2d matrix instead of an affine3d matrix.
//
// Example: As Module
//   xscale(3) sphere(r=10);
//
// Example(2D): Scaling Points
//   path = circle(d=50,$fn=12);
//   #stroke(path,closed=true);
//   stroke(xscale(2,p=path),closed=true);
module xscale(x=1) scale([x,1,1]) children();

function xscale(x=1, p=undef, planar=false) = (planar || (!is_undef(p) && len(p)==2))? scale([x,1],p=p) : scale([x,1,1],p=p);


// Function&Module: yscale()
//
// Usage: As Module
//   yscale(y) ...
// Usage: Scale Points
//   scaled = yscale(y, p);
// Usage: Get Affine Matrix
//   mat = yscale(y);
//
// Description:
//   Scales along the Y axis by the scaling factor `y`.
//   * Called as the built-in module, scales all children.
//   * Called as a function with a point in the `p` argument, returns the scaled point.
//   * Called as a function with a list of points in the `p` argument, returns the list of scaled points.
//   * Called as a function with a [bezier patch](beziers.scad) in the `p` argument, returns the scaled patch.
//   * Called as a function with a [VNF structure](vnf.scad) in the `p` argument, returns the scaled VNF.
//   * Called as a function without a `p` argument, and a 2D list of scaling factors in `v`, returns an affine2d scaling matrix.
//   * Called as a function without a `p` argument, and a 3D list of scaling factors in `v`, returns an affine3d scaling matrix.
//
// Arguments:
//   y = Factor to scale by, along the Y axis.
//   p = A point or path to scale, when called as a function.
//   planar = If true, and `p` is not given, then the matrix returned is an affine2d matrix instead of an affine3d matrix.
//
// Example: As Module
//   yscale(3) sphere(r=10);
//
// Example(2D): Scaling Points
//   path = circle(d=50,$fn=12);
//   #stroke(path,closed=true);
//   stroke(yscale(2,p=path),closed=true);
module yscale(y=1) scale([1,y,1]) children();

function yscale(y=1, p=undef, planar=false) = (planar || (!is_undef(p) && len(p)==2))? scale([1,y],p=p) : scale([1,y,1],p=p);


// Function&Module: zscale()
//
// Usage: As Module
//   zscale(z) ...
// Usage: Scale Points
//   scaled = zscale(z, p);
// Usage: Get Affine Matrix
//   mat = zscale(z);
//
// Description:
//   Scales along the Z axis by the scaling factor `z`.
//   * Called as the built-in module, scales all children.
//   * Called as a function with a point in the `p` argument, returns the scaled point.
//   * Called as a function with a list of points in the `p` argument, returns the list of scaled points.
//   * Called as a function with a [bezier patch](beziers.scad) in the `p` argument, returns the scaled patch.
//   * Called as a function with a [VNF structure](vnf.scad) in the `p` argument, returns the scaled VNF.
//   * Called as a function without a `p` argument, and a 2D list of scaling factors in `v`, returns an affine2d scaling matrix.
//   * Called as a function without a `p` argument, and a 3D list of scaling factors in `v`, returns an affine3d scaling matrix.
//
// Arguments:
//   z = Factor to scale by, along the Z axis.
//   p = A point or path to scale, when called as a function.
//   planar = If true, and `p` is not given, then the matrix returned is an affine2d matrix instead of an affine3d matrix.
//
// Example: As Module
//   zscale(3) sphere(r=10);
//
// Example: Scaling Points
//   path = xrot(90,p=circle(d=50,$fn=12));
//   #trace_polyline(path);
//   trace_polyline(zscale(2,p=path));
module zscale(z=1) scale([1,1,z]) children();

function zscale(z=1, p=undef) = scale([1,1,z],p=p);


// Function&Module: mirror()
// Usage: As Module
//   mirror(v) ...
// Usage: As Function
//   pt = mirror(v, p);
// Usage: Get Reflection/Mirror Matrix
//   mat = mirror(v);
// Description:
//   Mirrors/reflects across the plane or line whose normal vector is given in `v`.
//   * Called as the built-in module, mirrors all children across the line/plane.
//   * Called as a function with a point in the `p` argument, returns the point mirrored across the line/plane.
//   * Called as a function with a list of points in the `p` argument, returns the list of points, with each one mirrored across the line/plane.
//   * Called as a function with a [bezier patch](beziers.scad) in the `p` argument, returns the mirrored patch.
//   * Called as a function with a [VNF structure](vnf.scad) in the `p` argument, returns the mirrored VNF.
//   * Called as a function without a `p` argument, and with a 2D normal vector `v`, returns the affine2d 3x3 mirror matrix.
//   * Called as a function without a `p` argument, and with a 3D normal vector `v`, returns the affine3d 4x4 mirror matrix.
// Arguments:
//   v = The normal vector of the line or plane to mirror across.
//   p = If called as a function, the point or list of points to scale.
// Example:
//   n = [1,0,0];
//   module obj() right(20) rotate([0,15,-15]) cube([40,30,20]);
//   obj();
//   mirror(n) obj();
//   rot(a=atan2(n.y,n.x),from=UP,to=n) {
//       color("red") anchor_arrow(s=20, flag=false);
//       color("#7777") cube([75,75,0.1], center=true);
//   }
// Example:
//   n = [1,1,0];
//   module obj() right(20) rotate([0,15,-15]) cube([40,30,20]);
//   obj();
//   mirror(n) obj();
//   rot(a=atan2(n.y,n.x),from=UP,to=n) {
//       color("red") anchor_arrow(s=20, flag=false);
//       color("#7777") cube([75,75,0.1], center=true);
//   }
// Example:
//   n = [1,1,1];
//   module obj() right(20) rotate([0,15,-15]) cube([40,30,20]);
//   obj();
//   mirror(n) obj();
//   rot(a=atan2(n.y,n.x),from=UP,to=n) {
//       color("red") anchor_arrow(s=20, flag=false);
//       color("#7777") cube([75,75,0.1], center=true);
//   }
// Example(2D):
//   n = [0,1];
//   path = rot(30, p=square([50,30]));
//   color("gray") rot(from=[0,1],to=n) stroke([[-60,0],[60,0]]);
//   color("red") stroke([[0,0],10*n],endcap2="arrow2");
//   #stroke(path,closed=true);
//   stroke(mirror(n, p=path),closed=true);
// Example(2D):
//   n = [1,1];
//   path = rot(30, p=square([50,30]));
//   color("gray") rot(from=[0,1],to=n) stroke([[-60,0],[60,0]]);
//   color("red") stroke([[0,0],10*n],endcap2="arrow2");
//   #stroke(path,closed=true);
//   stroke(mirror(n, p=path),closed=true);
function mirror(v, p) =
	is_undef(p)? (
		len(v)==2? affine2d_mirror(v) : affine3d_mirror(v)
	) : (
		assert(is_list(p))
		is_num(p.x)? p - (2*(p*v)/(v*v))*v :
		is_vnf(p)? [mirror(v=v,p=p.x), [for (l=p.y) reverse(l)]] :
		[for (l=p) mirror(v=v, p=l)]
	);


// Function&Module: xflip()
//
// Usage: As Module
//   xflip([x]) ...
// Usage: As Function
//   pt = xflip([x], p);
// Usage: Get Affine Matrix
//   pt = xflip([x]);
//
// Description:
//   Mirrors/reflects across the origin [0,0,0], along the X axis.  If `x` is given, reflects across [x,0,0] instead.
//   * Called as the built-in module, mirrors all children across the line/plane.
//   * Called as a function with a point in the `p` argument, returns the point mirrored across the line/plane.
//   * Called as a function with a list of points in the `p` argument, returns the list of points, with each one mirrored across the line/plane.
//   * Called as a function with a [bezier patch](beziers.scad) in the `p` argument, returns the mirrored patch.
//   * Called as a function with a [VNF structure](vnf.scad) in the `p` argument, returns the mirrored VNF.
//   * Called as a function without a `p` argument, and with a 2D normal vector `v`, returns the affine2d 3x3 mirror matrix.
//   * Called as a function without a `p` argument, and with a 3D normal vector `v`, returns the affine3d 4x4 mirror matrix.
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

function xflip(x=0,p) =
	x==0? mirror([1,0,0],p=p) :
	move([x,0,0],p=mirror([1,0,0],p=move([-x,0,0],p=p)));


// Module: Function&yflip()
//
// Usage: As Module
//   yflip([y]) ...
// Usage: As Function
//   pt = yflip([y], p);
// Usage: Get Affine Matrix
//   pt = yflip([y]);
//
// Description:
//   Mirrors/reflects across the origin [0,0,0], along the Y axis.  If `y` is given, reflects across [0,y,0] instead.
//   * Called as the built-in module, mirrors all children across the line/plane.
//   * Called as a function with a point in the `p` argument, returns the point mirrored across the line/plane.
//   * Called as a function with a list of points in the `p` argument, returns the list of points, with each one mirrored across the line/plane.
//   * Called as a function with a [bezier patch](beziers.scad) in the `p` argument, returns the mirrored patch.
//   * Called as a function with a [VNF structure](vnf.scad) in the `p` argument, returns the mirrored VNF.
//   * Called as a function without a `p` argument, and with a 2D normal vector `v`, returns the affine2d 3x3 mirror matrix.
//   * Called as a function without a `p` argument, and with a 3D normal vector `v`, returns the affine3d 4x4 mirror matrix.
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

function yflip(y=0,p) =
	y==0? mirror([0,1,0],p=p) :
	move([0,y,0],p=mirror([0,1,0],p=move([0,-y,0],p=p)));



// Function&Module: zflip()
//
// Usage: As Module
//   zflip([z]) ...
// Usage: As Function
//   pt = zflip([z], p);
// Usage: Get Affine Matrix
//   pt = zflip([z]);
//
// Description:
//   Mirrors/reflects across the origin [0,0,0], along the Z axis.  If `z` is given, reflects across [0,0,z] instead.
//   * Called as the built-in module, mirrors all children across the line/plane.
//   * Called as a function with a point in the `p` argument, returns the point mirrored across the line/plane.
//   * Called as a function with a list of points in the `p` argument, returns the list of points, with each one mirrored across the line/plane.
//   * Called as a function with a [bezier patch](beziers.scad) in the `p` argument, returns the mirrored patch.
//   * Called as a function with a [VNF structure](vnf.scad) in the `p` argument, returns the mirrored VNF.
//   * Called as a function without a `p` argument, and with a 2D normal vector `v`, returns the affine2d 3x3 mirror matrix.
//   * Called as a function without a `p` argument, and with a 3D normal vector `v`, returns the affine3d 4x4 mirror matrix.
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

function zflip(z=0,p) =
	z==0? mirror([0,0,1],p=p) :
	move([0,0,z],p=mirror([0,0,1],p=move([0,0,-z],p=p)));



//////////////////////////////////////////////////////////////////////
// Section: Skewing
//////////////////////////////////////////////////////////////////////


// Function&Module: skew()
// Usage: As Module
//   skew(sxy=0, sxz=0, syx=0, syz=0, szx=0, szy=0) ...
// Usage: As Function
//   pts = skew(p, [sxy], [sxz], [syx], [syz], [szx], [szy]);
// Usage: Get Affine Matrix
//   mat = skew([sxy], [sxz], [syx], [syz], [szx], [szy], [planar]);
// Description:
//   Skews geometry by the given skew factors.
//   * Called as the built-in module, skews all children.
//   * Called as a function with a point in the `p` argument, returns the skewed point.
//   * Called as a function with a list of points in the `p` argument, returns the list of skewed points.
//   * Called as a function with a [bezier patch](beziers.scad) in the `p` argument, returns the skewed patch.
//   * Called as a function with a [VNF structure](vnf.scad) in the `p` argument, returns the skewed VNF.
//   * Called as a function without a `p` argument, and with `planar` true, returns the affine2d 3x3 skew matrix.
//   * Called as a function without a `p` argument, and with `planar` false, returns the affine3d 4x4 skew matrix.
//   Each skew factor is a multiplier.  For example, if `sxy=2`, then it will skew along the X axis by 2x the value of the Y axis.
// Arguments:
//   sxy = Skew factor multiplier for skewing along the X axis as you get farther from the Y axis.  Default: 0
//   sxz = Skew factor multiplier for skewing along the X axis as you get farther from the Z axis.  Default: 0
//   syx = Skew factor multiplier for skewing along the Y axis as you get farther from the X axis.  Default: 0
//   syz = Skew factor multiplier for skewing along the Y axis as you get farther from the Z axis.  Default: 0
//   szx = Skew factor multiplier for skewing along the Z axis as you get farther from the X axis.  Default: 0
//   szy = Skew factor multiplier for skewing along the Z axis as you get farther from the Y axis.  Default: 0
// Example(2D): Skew along the X axis in 2D.
//   skew(sxy=0.5) square(40, center=true);
// Example(2D): Skew along the Y axis in 2D.
//   skew(syx=0.5) square(40, center=true);
// Example: Skew along the X axis in 3D as a factor of Y coordinate.
//   skew(sxy=0.5) cube(40, center=true);
// Example: Skew along the X axis in 3D as a factor of Z coordinate.
//   skew(sxz=0.5) cube(40, center=true);
// Example: Skew along the Y axis in 3D as a factor of X coordinate.
//   skew(syx=0.5) cube(40, center=true);
// Example: Skew along the Y axis in 3D as a factor of Z coordinate.
//   skew(syz=0.5) cube(40, center=true);
// Example: Skew along the Z axis in 3D as a factor of X coordinate.
//   skew(szx=0.5) cube(40, center=true);
// Example: Skew along the Z axis in 3D as a factor of Y coordinate.
//   skew(szy=0.75) cube(40, center=true);
// Example(FlatSpin): Skew Along Multiple Axes.
//   skew(sxy=0.5, syx=0.3, szy=0.75) cube(40, center=true);
// Example(2D): Calling as a 2D Function
//   pts = skew(p=square(40,center=true), sxy=0.5);
//   color("yellow") stroke(pts, closed=true);
//   color("blue") place_copies(pts) circle(d=3, $fn=8);
// Example(FlatSpin): Calling as a 3D Function
//   pts = skew(p=path3d(square(40,center=true)), szx=0.5, szy=0.3);
//   trace_polyline(close_path(pts), showpts=true);
module skew(sxy=0, sxz=0, syx=0, syz=0, szx=0, szy=0)
{
	multmatrix(
		affine3d_skew(sxy=sxy, sxz=sxz, syx=syx, syz=syz, szx=szx, szy=szy)
	) children();
}

function skew(p, sxy=0, sxz=0, syx=0, syz=0, szx=0, szy=0, planar=false) =
	let(
		planar = planar || (is_list(p) && is_num(p.x) && len(p)==2),
		m = planar? [
			[  1, sxy, 0],
			[syx,   1, 0],
			[  0,   0, 1]
		] : affine3d_skew(sxy=sxy, sxz=sxz, syx=syx, syz=syz, szx=szx, szy=szy)
	)
	is_undef(p)? m :
	assert(is_list(p))
	is_num(p.x)? (
		planar?
			point2d(m*concat(point2d(p),[1])) :
			point3d(m*concat(point3d(p),[1]))
	) :
	is_vnf(p)? [skew(sxy=sxy, sxz=sxz, syx=syx, syz=syz, szx=szx, szy=szy, planar=planar, p=p.x), p.y] :
	[for (l=p) skew(sxy=sxy, sxz=sxz, syx=syx, syz=syz, szx=szx, szy=szy, planar=planar, p=l)];



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
//   `$idx` is set to the index number of each child being copied.
//
// Example:
//   #sphere(r=10);
//   place_copies([[-25,-25,0], [25,-25,0], [0,0,50], [0,25,0]]) sphere(r=10);
module place_copies(a=[[0,0,0]])
{
	assert(is_list(a));
	for ($idx = idx(a)) {
		$pos = a[$idx];
		assert(is_vector($pos));
		translate($pos) children();
	}
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
// Example: Using `$row` and `$col`
//   grid2d(spacing=[8,8], cols=8, rows=8, anchor=LEFT+FRONT)
//       color(($row+$col)%2?"black":"red")
//           cube([8,8,0.01], center=false);
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
	assert(in_list(stagger, [false, true, "alt"]));
	scl = vmul(scalar_vec3(scale, 1), (stagger!=false? [0.5, sin(60), 1] : [1,1,1]));
	if (!is_undef(size)) {
		siz = scalar_vec3(size);
		if (!is_undef(spacing)) {
			spc = vmul(scalar_vec3(spacing), scl);
			maxcols = ceil(siz.x/spc.x);
			maxrows = ceil(siz.y/spc.y);
			grid2d(spacing=spacing, cols=maxcols, rows=maxrows, stagger=stagger, scale=scale, in_poly=in_poly, anchor=anchor, spin=spin, orient=orient) children();
		} else {
			spc = [siz.x/cols, siz.y/rows];
			grid2d(spacing=spc, cols=cols, rows=rows, stagger=stagger, scale=scale, in_poly=in_poly, anchor=anchor, spin=spin, orient=orient) children();
		}
	} else {
		spc = is_list(spacing)? point3d(spacing) : vmul(scalar_vec3(spacing), scl);
		bounds = !is_undef(in_poly)? pointlist_bounds(in_poly) : undef;
		bnds = !is_undef(bounds)? [for (a=[0,1]) 2*max(vabs([ for (i=[0,1]) bounds[i][a] ]))+1 ] : undef;
		mcols = !is_undef(cols)? cols : (!is_undef(spc) && !is_undef(bnds))? quantup(ceil(bnds[0]/spc[0])-1, 4)+1 : undef;
		mrows = !is_undef(rows)? rows : (!is_undef(spc) && !is_undef(bnds))? quantup(ceil(bnds[1]/spc[1])-1, 4)+1 : undef;
		siz = vmul(spc, [mcols-1, mrows-1, 0])+[0,0,0.01];
		staggermod = (stagger == "alt")? 1 : 0;
		if (stagger == false) {
			orient_and_anchor(siz, orient, anchor, spin=spin) {
				for (row = [0:1:mrows-1]) {
					for (col = [0:1:mcols-1]) {
						pos = [col*spc.x, row*spc.y] - point2d(siz/2);
						if (is_undef(in_poly) || point_in_polygon(pos, in_poly)>=0) {
							$col = col;
							$row = row;
							$pos = pos;
							translate(pos) children();
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
								translate(pos) children();
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
//   Given a list of [X,Y,Z] rotation angles in `rots`, rotates copies of the children to each of those angles, regardless of axis of rotation.
//   Given a list of scalar angles in `rots`, rotates copies of the children to each of those angles around the axis of rotation.
//   If given a vector `v`, that becomes the axis of rotation.  Default axis of rotation is UP.
//   If given a count `n`, makes that many copies, rotated evenly around the axis.
//   If given an offset `delta`, translates each child by that amount before rotating them into place.  This makes rings.
//   If given a centerpoint `cp`, centers the ring around that centerpoint.
//   If `subrot` is true, each child will be rotated in place to keep the same size towards the center.
//   The first (unrotated) copy will be placed at the relative starting angle `sa`.
//
// Usage:
//   rot_copies(rots, [cp], [sa], [delta], [subrot]) ...
//   rot_copies(rots, v, [cp], [sa], [delta], [subrot]) ...
//   rot_copies(n, [v], [cp], [sa], [delta], [subrot]) ...
//
// Arguments:
//   rots = A list of [X,Y,Z] rotation angles in degrees.  If `v` is given, this will be a list of scalar angles in degrees to rotate around `v`.
//   v = If given, this is the vector of the axis to rotate around.
//   cp = Centerpoint to rotate around.
//   n = Optional number of evenly distributed copies, rotated around the axis.
//   sa = Starting angle, in degrees.  For use with `n`.  Angle is in degrees counter-clockwise.
//   delta = [X,Y,Z] amount to move away from cp before rotating.  Makes rings of copies.
//   subrot = If false, don't sub-rotate children as they are copied around the ring.
//
// Side Effects:
//   `$ang` is set to the rotation angle (or XYZ rotation triplet) of each child copy, and can be used to modify each child individually.
//   `$idx` is set to the index value of each child copy.
//   `$axis` is set to the axis to rotate around, if `rots` was given as a list of angles instead of a list of [X,Y,Z] rotation angles.
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
module rot_copies(rots=[], v=undef, cp=[0,0,0], n=undef, sa=0, offset=0, delta=[0,0,0], subrot=true)
{
	sang = sa + offset;
	angs = !is_undef(n)?
		(n<=0? [] : [for (i=[0:1:n-1]) i/n*360+sang]) :
		assert(is_list(rots))
		rots;
	for ($idx = idx(angs)) {
		$ang = angs[$idx];
		$axis = v;
		translate(cp) {
			rotate(a=$ang, v=v) {
				translate(delta) {
					rot(a=(subrot? sang : $ang), v=v, reverse=true) {
						children();
					}
				}
			}
		}
	}
}


// Module: xrot_copies()
//
// Usage:
//   xrot_copies(rots, [r], [cp], [sa], [subrot]) ...
//   xrot_copies(n, [r], [cp], [sa], [subrot]) ...
//
// Description:
//   Given an array of angles, rotates copies of the children to each of those angles around the X axis.
//   If given a count `n`, makes that many copies, rotated evenly around the X axis.
//   If given an offset radius `r`, distributes children around a ring of that radius.
//   If given a centerpoint `cp`, centers the ring around that centerpoint.
//   If `subrot` is true, each child will be rotated in place to keep the same size towards the center.
//   The first (unrotated) copy will be placed at the relative starting angle `sa`.
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
//   `$idx` is set to the index value of each child copy.
//   `$ang` is set to the rotation angle of each child copy, and can be used to modify each child individually.
//   `$axis` is set to the axis vector rotated around.
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
module xrot_copies(rots=[], cp=[0,0,0], n=undef, sa=0, r=0, subrot=true)
{
	rot_copies(rots=rots, v=RIGHT, cp=cp, n=n, sa=sa, delta=[0, r, 0], subrot=subrot) children();
}


// Module: yrot_copies()
//
// Usage:
//   yrot_copies(rots, [r], [cp], [sa], [subrot]) ...
//   yrot_copies(n, [r], [cp], [sa], [subrot]) ...
//
// Description:
//   Given an array of angles, rotates copies of the children to each of those angles around the Y axis.
//   If given a count `n`, makes that many copies, rotated evenly around the Y axis.
//   If given an offset radius `r`, distributes children around a ring of that radius.
//   If given a centerpoint `cp`, centers the ring around that centerpoint.
//   If `subrot` is true, each child will be rotated in place to keep the same size towards the center.
//   The first (unrotated) copy will be placed at the relative starting angle `sa`.
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
//   `$idx` is set to the index value of each child copy.
//   `$ang` is set to the rotation angle of each child copy, and can be used to modify each child individually.
//   `$axis` is set to the axis vector rotated around.
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
module yrot_copies(rots=[], cp=[0,0,0], n=undef, sa=0, r=0, subrot=true)
{
	rot_copies(rots=rots, v=BACK, cp=cp, n=n, sa=sa, delta=[-r, 0, 0], subrot=subrot) children();
}


// Module: zrot_copies()
//
// Usage:
//   zrot_copies(rots, [r], [cp], [sa], [subrot]) ...
//   zrot_copies(n, [r], [cp], [sa], [subrot]) ...
//
// Description:
//   Given an array of angles, rotates copies of the children to each of those angles around the Z axis.
//   If given a count `n`, makes that many copies, rotated evenly around the Z axis.
//   If given an offset radius `r`, distributes children around a ring of that radius.
//   If given a centerpoint `cp`, centers the ring around that centerpoint.
//   If `subrot` is true, each child will be rotated in place to keep the same size towards the center.
//   The first (unrotated) copy will be placed at the relative starting angle `sa`.
//
// Arguments:
//   rots = Optional array of rotation angles, in degrees, to make copies at.
//   cp = Centerpoint to rotate around.  Default: [0,0,0]
//   n = Optional number of evenly distributed copies to be rotated around the ring.
//   sa = Starting angle, in degrees.  For use with `n`.  Angle is in degrees counter-clockwise from X+, when facing the origin from Z+.  Default: 0
//   r = Radius to move children right, away from cp, before rotating.  Makes rings of copies.  Default: 0
//   subrot = If false, don't sub-rotate children as they are copied around the ring.  Default: true
//
// Side Effects:
//   `$idx` is set to the index value of each child copy.
//   `$ang` is set to the rotation angle of each child copy, and can be used to modify each child individually.
//   `$axis` is set to the axis vector rotated around.
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
module zrot_copies(rots=[], cp=[0,0,0], n=undef, sa=0, r=0, subrot=true)
{
	rot_copies(rots=rots, v=UP, cp=cp, n=n, sa=sa, delta=[r, 0, 0], subrot=subrot) children();
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
	rx = get_radius(r1=rx, r=r, d1=dx, d=d, dflt=1);
	ry = get_radius(r1=ry, r=r, d1=dy, d=d, dflt=1);
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

	for ($idx = idx(theta_phis)) {
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
//   s = Mask size to use.  Use a number larger than twice your object's largest axis.  If you make this too large, OpenSCAD's preview rendering may be incorrect.  Default: 10000
//   x = The X coordinate of the cut-plane.  Default: 0
//   planar = If true, this becomes a 2D operation.
//
// Examples:
//   left_half() sphere(r=20);
//   left_half(x=-8) sphere(r=20);
// Example(2D):
//   left_half(planar=true) circle(r=20);
module left_half(s=10000, x=0, planar=false)
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
//   s = Mask size to use.  Use a number larger than twice your object's largest axis.  If you make this too large, OpenSCAD's preview rendering may be incorrect.  Default: 10000
//   x = The X coordinate of the cut-plane.  Default: 0
//   planar = If true, this becomes a 2D operation.
//
// Examples(FlatSpin):
//   right_half() sphere(r=20);
//   right_half(x=-5) sphere(r=20);
// Example(2D):
//   right_half(planar=true) circle(r=20);
module right_half(s=10000, x=0, planar=false)
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
//   s = Mask size to use.  Use a number larger than twice your object's largest axis.  If you make this too large, OpenSCAD's preview rendering may be incorrect.  Default: 10000
//   y = The Y coordinate of the cut-plane.  Default: 0
//   planar = If true, this becomes a 2D operation.
//
// Examples(FlatSpin):
//   front_half() sphere(r=20);
//   front_half(y=5) sphere(r=20);
// Example(2D):
//   front_half(planar=true) circle(r=20);
module front_half(s=10000, y=0, planar=false)
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
//   s = Mask size to use.  Use a number larger than twice your object's largest axis.  If you make this too large, OpenSCAD's preview rendering may be incorrect.  Default: 10000
//   y = The Y coordinate of the cut-plane.  Default: 0
//   planar = If true, this becomes a 2D operation.
//
// Examples:
//   back_half() sphere(r=20);
//   back_half(y=8) sphere(r=20);
// Example(2D):
//   back_half(planar=true) circle(r=20);
module back_half(s=10000, y=0, planar=false)
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
//   s = Mask size to use.  Use a number larger than twice your object's largest axis.  If you make this too large, OpenSCAD's preview rendering may be incorrect.  Default: 10000
//   z = The Z coordinate of the cut-plane.  Default: 0
//
// Examples:
//   bottom_half() sphere(r=20);
//   bottom_half(z=-10) sphere(r=20);
module bottom_half(s=10000, z=0)
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
//   s = Mask size to use.  Use a number larger than twice your object's largest axis.  If you make this too large, OpenSCAD's preview rendering may be incorrect.  Default: 10000
//   z = The Z coordinate of the cut-plane.  Default: 0
//
// Examples(Spin):
//   top_half() sphere(r=20);
//   top_half(z=5) sphere(r=20);
module top_half(s=10000, z=0)
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
// Side Effects:
//   `$idx` is set to the index value of the first child of each hulling pair, and can be used to modify each child pair individually.
//   `$primary` is set to true when the child is the first in a chain pair.
//
// Example:
//   chain_hull() {
//       cube(5, center=true);
//       translate([30, 0, 0]) sphere(d=15);
//       translate([60, 30, 0]) cylinder(d=10, h=20);
//       translate([60, 60, 0]) cube([10,1,20], center=false);
//   }
// Example: Using `$idx` and `$primary`
//   chain_hull() {
//       zrot(  0) right(100) if ($primary) cube(5+3*$idx,center=true); else sphere(r=10+3*$idx);
//       zrot( 45) right(100) if ($primary) cube(5+3*$idx,center=true); else sphere(r=10+3*$idx);
//       zrot( 90) right(100) if ($primary) cube(5+3*$idx,center=true); else sphere(r=10+3*$idx);
//       zrot(135) right(100) if ($primary) cube(5+3*$idx,center=true); else sphere(r=10+3*$idx);
//       zrot(180) right(100) if ($primary) cube(5+3*$idx,center=true); else sphere(r=10+3*$idx);
//   }
module chain_hull()
{
	union() {
		if ($children == 1) {
			children();
		} else if ($children > 1) {
			for (i =[1:1:$children-1]) {
				$idx = i;
				hull() {
					let($primary=true) children(i-1);
					let($primary=false) children(i);
				}
			}
		}
	}
}



// Module: round3d()
// Usage:
//   round3d(r) ...
//   round3d(or) ...
//   round3d(ir) ...
//   round3d(or, ir) ...
// Description:
//   Rounds arbitrary 3D objects.  Giving `r` rounds all concave and convex corners.  Giving just `ir`
//   rounds just concave corners.  Giving just `or` rounds convex corners.  Giving both `ir` and `or`
//   can let you round to different radii for concave and convex corners.  The 3D object must not have
//   any parts narrower than twice the `or` radius.  Such parts will disappear.  This is an *extremely*
//   slow operation.  I cannot emphasize enough just how slow it is.  It uses `minkowski()` multiple times.
//   Use this as a last resort.  This is so slow that no example images will be rendered.
// Arguments:
//   r = Radius to round all concave and convex corners to.
//   or = Radius to round only outside (convex) corners to.  Use instead of `r`.
//   ir = Radius to round only inside (concave) corners to.  Use instead of `r`.
module round3d(r, or, ir, size=100)
{
	or = get_radius(r1=or, r=r, dflt=0);
	ir = get_radius(r1=ir, r=r, dflt=0);
	offset3d(or, size=size)
		offset3d(-ir-or, size=size)
			offset3d(ir, size=size)
				children();
}


// Module: offset3d()
// Usage:
//   offset3d(r, [size], [convexity]);
// Description:
//   Expands or contracts the surface of a 3D object by a given amount.  This is very, very slow.
//   No really, this is unbearably slow.  It uses `minkowski()`.  Use this as a last resort.
//   This is so slow that no example images will be rendered.
// Arguments:
//   r = Radius to expand object by.  Negative numbers contract the object.
//   size = Maximum size of object to be contracted, given as a scalar.  Default: 100
//   convexity = Max number of times a line could intersect the walls of the object.  Default: 10
module offset3d(r=1, size=100, convexity=10) {
	n = quant(max(8,segs(abs(r))),4);
	if (r==0) {
		children();
	} else if (r>0) {
		render(convexity=convexity)
		minkowski() {
			children();
			sphere(r, $fn=n);
		}
	} else {
		size2 = size * [1,1,1];
		size1 = size2 * 1.02;
		render(convexity=convexity)
		difference() {
			cube(size2, center=true);
			minkowski() {
				difference() {
					cube(size1, center=true);
					children();
				}
				sphere(-r, $fn=n);
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
//   Rounds arbitrary 2D objects.  Giving `r` rounds all concave and convex corners.  Giving just `ir`
//   rounds just concave corners.  Giving just `or` rounds convex corners.  Giving both `ir` and `or`
//   can let you round to different radii for concave and convex corners.  The 2D object must not have
//   any parts narrower than twice the `or` radius.  Such parts will disappear.
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
//   Creates a hollow shell from 2D children, with optional rounding.
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


//////////////////////////////////////////////////////////////////////
// Section: Colors
//////////////////////////////////////////////////////////////////////

// Function&Module: HSL()
// Usage:
//   HSL(h,[s],[l],[a]) ...
//   rgb = HSL(h,[s],[l]);
// Description:
//   When called as a function, returns the [R,G,B] color for the given hue `h`, saturation `s`, and lightness `l` from the HSL colorspace.
//   When called as a module, sets the color to the given hue `h`, saturation `s`, and lightness `l` from the HSL colorspace.
// Arguments:
//   h = The hue, given as a value between 0 and 360.  0=red, 60=yellow, 120=green, 180=cyan, 240=blue, 300=magenta.
//   s = The saturation, given as a value between 0 and 1.  0 = grayscale, 1 = vivid colors.  Default: 1
//   l = The lightness, between 0 and 1.  0 = black, 0.5 = bright colors, 1 = white.  Default: 0.5
//   a = When called as a module, specifies the alpha channel as a value between 0 and 1.  0 = fully transparent, 1=opaque.  Default: 1
// Example:
//   HSL(h=120,s=1,l=0.5) sphere(d=60);
// Example:
//   rgb = HSL(h=270,s=0.75,l=0.6);
//   color(rgb) cube(60, center=true);
function HSL(h,s=1,l=0.5) =
	let(
		h=posmod(h,360)
	) [
		for (n=[0,8,4]) let(
			k=(n+h/30)%12
		) l - s*min(l,1-l)*max(min(k-3,9-k,1),-1)
	];

module HSL(h,s=1,l=0.5,a=1) color(HSL(h,s,l),a) children();


// Function&Module: HSV()
// Usage:
//   HSV(h,[s],[v],[a]) ...
//   rgb = HSV(h,[s],[v]);
// Description:
//   When called as a function, returns the [R,G,B] color for the given hue `h`, saturation `s`, and value `v` from the HSV colorspace.
//   When called as a module, sets the color to the given hue `h`, saturation `s`, and value `v` from the HSV colorspace.
// Arguments:
//   h = The hue, given as a value between 0 and 360.  0=red, 60=yellow, 120=green, 180=cyan, 240=blue, 300=magenta.
//   s = The saturation, given as a value between 0 and 1.  0 = grayscale, 1 = vivid colors.  Default: 1
//   v = The value, between 0 and 1.  0 = darkest black, 1 = bright.  Default: 1
//   a = When called as a module, specifies the alpha channel as a value between 0 and 1.  0 = fully transparent, 1=opaque.  Default: 1
// Example:
//   HSV(h=120,s=1,v=1) sphere(d=60);
// Example:
//   rgb = HSV(h=270,s=0.75,v=0.9);
//   color(rgb) cube(60, center=true);
function HSV(h,s=1,v=1) =
	let(
		h=posmod(h,360),
		v2=v*(1-s),
		r=lookup(h,[[0,v], [60,v], [120,v2], [240,v2], [300,v], [360,v]]),
		g=lookup(h,[[0,v2], [60,v], [180,v], [240,v2], [360,v2]]),
		b=lookup(h,[[0,v2], [120,v2], [180,v], [300,v], [360,v2]])
	) [r,g,b];

module HSV(h,s=1,v=1,a=1) color(HSV(h,s,v),a) children();


// Module: rainbow()
// Usage:
//   rainbow(list) ...
// Description:
//   Iterates the list, displaying children in different colors for each list item.
//   This is useful for debugging lists of paths and such.
// Arguments:
//   list = The list of items to iterate through.
//   stride = Consecutive colors stride around the color wheel divided into this many parts.
// Side Effects:
//   Sets the color to progressive values along the ROYGBIV spectrum for each item.
//   Sets `$idx` to the index of the current item in `list` that we want to show.
//   Sets `$item` to the current item in `list` that we want to show.
// Example(2D):
//   rainbow(["Foo","Bar","Baz"]) fwd($idx*10) text(text=$item,size=8,halign="center",valign="center");
// Example(2D):
//   rgn = [circle(d=45,$fn=3), circle(d=75,$fn=4), circle(d=50)];
//   rainbow(rgn) stroke($item, closed=true);
module rainbow(list, stride=1)
{
	ll = len(list);
	huestep = 360 / ll;
	hues = [for (i=[0:1:ll-1]) posmod(i*huestep+i*360/stride,360)];
	for($idx=idx(list)) {
		$item = list[$idx];
		HSV(h=hues[$idx]) children();
	}
}


// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
