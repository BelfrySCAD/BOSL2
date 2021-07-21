//////////////////////////////////////////////////////////////////////
// LibFile: transforms.scad
//   Functions and modules for translation, rotation, reflection and skewing.
// Includes:
//   include <BOSL2/std.scad>
//////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////
// Section: Translations
//////////////////////////////////////////////////////////////////////


// Function&Module: move()
// Aliases: translate()
//
// Usage: As Module
//   move([x=], [y=], [z=]) ...
//   move(v) ...
// Usage: Translate Points
//   pts = move(v, p);
//   pts = move([x=], [y=], [z=], p=);
// Usage: Get Translation Matrix
//   mat = move(v);
//   mat = move([x=], [y=], [z=]);
//
// Topics: Affine, Matrices, Transforms, Translation
// See Also: left(), right(), fwd(), back(), down(), up(), spherical_to_xyz(), altaz_to_xyz(), cylindrical_to_xyz(), polar_to_xy(), affine2d_translate(), affine3d_translate()
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
//   p = Either a point, or a list of points to be translated when used as a function.
//   ---
//   x = X axis translation.
//   y = Y axis translation.
//   z = Z axis translation.
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
// Example(FlatSpin): Using Altitude-Azimuth Coordinates
//   #sphere(d=10);
//   move(altaz_to_xyz(30,90,20)) sphere(d=10);
//
// Example(FlatSpin): Using Spherical Coordinates
//   #sphere(d=10);
//   move(spherical_to_xyz(20,45,30)) sphere(d=10);
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
module move(v=[0,0,0], p, x=0, y=0, z=0) {
    assert(is_undef(p), "Module form `move()` does not accept p= argument.");
    translate(point3d(v)+[x,y,z]) children();
}

function move(v=[0,0,0], p, x=0, y=0, z=0) =
    is_undef(p)? (
        len(v)==2? affine2d_translate(v+[x,y]) :
        affine3d_translate(point3d(v)+[x,y,z])
    ) : (
        assert(is_list(p))
        let(v=point3d(v)+[x,y,z])
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
// Topics: Affine, Matrices, Transforms, Translation
// See Also: move(), right(), fwd(), back(), down(), up(), affine2d_translate(), affine3d_translate()
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
module left(x=0, p) {
    assert(is_undef(p), "Module form `left()` does not accept p= argument.");
    translate([-x,0,0]) children();
}

function left(x=0, p) = move([-x,0,0],p=p);


// Function&Module: right()
//
// Usage: As Module
//   right(x) ...
// Usage: Translate Points
//   pts = right(x, p);
// Usage: Get Translation Matrix
//   mat = right(x);
//
// Topics: Affine, Matrices, Transforms, Translation
// See Also: move(), left(), fwd(), back(), down(), up(), affine2d_translate(), affine3d_translate()
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
module right(x=0, p) {
    assert(is_undef(p), "Module form `right()` does not accept p= argument.");
    translate([x,0,0]) children();
}

function right(x=0, p) = move([x,0,0],p=p);


// Function&Module: fwd()
//
// Usage: As Module
//   fwd(y) ...
// Usage: Translate Points
//   pts = fwd(y, p);
// Usage: Get Translation Matrix
//   mat = fwd(y);
//
// Topics: Affine, Matrices, Transforms, Translation
// See Also: move(), left(), right(), back(), down(), up(), affine2d_translate(), affine3d_translate()
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
module fwd(y=0, p) {
    assert(is_undef(p), "Module form `fwd()` does not accept p= argument.");
    translate([0,-y,0]) children();
}

function fwd(y=0, p) = move([0,-y,0],p=p);


// Function&Module: back()
//
// Usage: As Module
//   back(y) ...
// Usage: Translate Points
//   pts = back(y, p);
// Usage: Get Translation Matrix
//   mat = back(y);
//
// Topics: Affine, Matrices, Transforms, Translation
// See Also: move(), left(), right(), fwd(), down(), up(), affine2d_translate(), affine3d_translate()
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
module back(y=0, p) {
    assert(is_undef(p), "Module form `back()` does not accept p= argument.");
    translate([0,y,0]) children();
}

function back(y=0,p) = move([0,y,0],p=p);


// Function&Module: down()
//
// Usage: As Module
//   down(z) ...
// Usage: Translate Points
//   pts = down(z, p);
// Usage: Get Translation Matrix
//   mat = down(z);
//
// Topics: Affine, Matrices, Transforms, Translation
// See Also: move(), left(), right(), fwd(), back(), up(), affine2d_translate(), affine3d_translate()
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
module down(z=0, p) {
    assert(is_undef(p), "Module form `down()` does not accept p= argument.");
    translate([0,0,-z]) children();
}

function down(z=0, p) = move([0,0,-z],p=p);


// Function&Module: up()
//
// Usage: As Module
//   up(z) ...
// Usage: Translate Points
//   pts = up(z, p);
// Usage: Get Translation Matrix
//   mat = up(z);
//
// Topics: Affine, Matrices, Transforms, Translation
// See Also: move(), left(), right(), fwd(), back(), down(), affine2d_translate(), affine3d_translate()
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
module up(z=0, p) {
    assert(is_undef(p), "Module form `up()` does not accept p= argument.");
    translate([0,0,z]) children();
}

function up(z=0, p) = move([0,0,z],p=p);



//////////////////////////////////////////////////////////////////////
// Section: Rotations
//////////////////////////////////////////////////////////////////////


// Function&Module: rot()
//
// Usage: As a Module
//   rot(a, [cp], [reverse]) {...}
//   rot([X,Y,Z], [cp], [reverse]) {...}
//   rot(a, v, [cp], [reverse]) {...}
//   rot(from, to, [a], [reverse]) {...}
// Usage: As a Function to transform data in `p`
//   pts = rot(a, p=, [cp=], [reverse=]);
//   pts = rot([X,Y,Z], p=, [cp=], [reverse=]);
//   pts = rot(a, v, p=, [cp=], [reverse=]);
//   pts = rot([a], from=, to=, p=, [reverse=]);
// Usage: As a Function to return a transform matrix
//   M = rot(a, [cp=], [reverse=], [planar=]);
//   M = rot([X,Y,Z], [cp=], [reverse=], [planar=]);
//   M = rot(a, v, [cp=], [reverse=], [planar=]);
//   M = rot(from=, to=, [a=], [reverse=], [planar=]);
//
// Topics: Affine, Matrices, Transforms, Rotation
// See Also: xrot(), yrot(), zrot(), affine2d_zrot(), affine3d_xrot(), affine3d_yrot(), affine3d_zrot(), affine3d_rot_by_axis(), affine3d_rot_from_to()
//
// Description:
//   This is a shorthand version of the built-in `rotate()`, and operates similarly, with a few additional capabilities.
//   You can specify the rotation to perform in one of several ways:
//   * `rot(30)` or `rot(a=30)` rotates 30 degrees around the Z axis.
//   * `rot([20,30,40])` or `rot(a=[20,30,40])` rotates 20 degrees around the X axis, then 30 degrees around the Y axis, then 40 degrees around the Z axis.
//   * `rot(30, [1,1,0])` or `rot(a=30, v=[1,1,0])` rotates 30 degrees around the axis vector `[1,1,0]`.
//   * `rot(from=[0,0,1], to=[1,0,0])` rotates the `from` vector to line up with the `to` vector, in this case the top to the right and hence equivalent to `rot(a=90,v=[0,1,0]`.
//   * `rot(from=[0,1,1], to=[1,1,0], a=45)` rotates 45 degrees around the `from` vector ([0,1,1]) and then rotates the `from` vector to align with the `to` vector.  Equivalent to `rot(from=[0,1,1],to=[1,1,0]) rot(a=45,v=[0,1,1])`.  You can also regard `a` as as post-rotation around the `to` vector.  For this form, `a` must be a scalar.  
//   * If the `cp` centerpoint argument is given, then rotations are performed around that centerpoint.  So `rot(args...,cp=[1,2,3])` is equivalent to `move(-[1,2,3])rot(args...)move([1,2,3])`.
//   * If the `reverse` argument is true, then the rotations performed will be exactly reversed.
//   .
//   The behavior and return value varies depending on how `rot()` is called:
//   * Called as a module, rotates all children.
//   * Called as a function with a `p` argument containing a point, returns the rotated point.
//   * Called as a function with a `p` argument containing a list of points, returns the list of rotated points.
//   * Called as a function with a [bezier patch](beziers.scad) in the `p` argument, returns the rotated patch.
//   * Called as a function with a [VNF structure](vnf.scad) in the `p` argument, returns the rotated VNF.
//   * Called as a function without a `p` argument, and `planar` is true, returns the affine2d rotational matrix.  The angle `a` must be a scalar. 
//   * Called as a function without a `p` argument, and `planar` is false, returns the affine3d rotational matrix.
//
// Arguments:
//   a = Scalar angle or vector of XYZ rotation angles to rotate by, in degrees.  If `planar` is true or if `p` holds 2d data, or if you use the `from` and `to` arguments then `a` must be a scalar.  Default: `0`
//   v = vector for the axis of rotation.  Default: [0,0,1] or UP
//   ---
//   cp = centerpoint to rotate around. Default: [0,0,0]
//   from = Starting vector for vector-based rotations.
//   to = Target vector for vector-based rotations.
//   reverse = If true, exactly reverses the rotation, including axis rotation ordering.  Default: false
//   planar = If called as a function, this specifies if you want to work with 2D points.
//   p = If called as a function, this contains data to rotate: a point, list of points, bezier patch or VNF.
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
module rot(a=0, v, cp, from, to, reverse=false)
{
    m = rot(a=a, v=v, cp=cp, from=from, to=to, reverse=reverse, planar=false);
    multmatrix(m) children();
}

function rot(a=0, v, cp, from, to, reverse=false, planar=false, p, _m) =
    assert(is_undef(from)==is_undef(to), "from and to must be specified together.")
    assert(is_undef(from) || is_vector(from, zero=false), "'from' must be a non-zero vector.")
    assert(is_undef(to) || is_vector(to, zero=false), "'to' must be a non-zero vector.")
    assert(is_undef(v) || is_vector(v, zero=false), "'v' must be a non-zero vector.")
    assert(is_undef(cp) || is_vector(cp), "'cp' must be a vector.")
    assert(is_finite(a) || is_vector(a), "'a' must be a finite scalar or a vector.")
    assert(is_bool(reverse))
    assert(is_bool(planar))
    is_undef(p)? (
        planar? let(
            check = assert(is_num(a)),
            cp = is_undef(cp)? cp : point2d(cp),
            m1 = is_undef(from)? affine2d_zrot(a) :
                assert(a==0, "'from' and 'to' cannot be used with 'a' when 'planar' is true.")
                assert(approx(point3d(from).z, 0), "'from' must be a 2D vector when 'planar' is true.")
                assert(approx(point3d(to).z, 0), "'to' must be a 2D vector when 'planar' is true.")
                affine2d_zrot(
                    v_theta(to) -
                    v_theta(from)
                ),
            m2 = is_undef(cp)? m1 : (move(cp) * m1 * move(-cp)),
            m3 = reverse? matrix_inverse(m2) : m2
        ) m3 : let(
            from = is_undef(from)? undef : point3d(from),
            to = is_undef(to)? undef : point3d(to),
            cp = is_undef(cp)? undef : point3d(cp),
            m1 = !is_undef(from)? (
                    assert(is_num(a))
                    affine3d_rot_from_to(from,to) * affine3d_rot_by_axis(from,a)
                ) :
                !is_undef(v)? assert(is_num(a)) affine3d_rot_by_axis(v,a) :
                is_num(a)? affine3d_zrot(a) :
                affine3d_zrot(a.z) * affine3d_yrot(a.y) * affine3d_xrot(a.x),
            m2 = is_undef(cp)? m1 : (move(cp) * m1 * move(-cp)),
            m3 = reverse? matrix_inverse(m2) : m2
        ) m3
    ) : (
        assert(is_list(p))
        let(
            m = !is_undef(_m)? _m :
                rot(a=a, v=v, cp=cp, from=from, to=to, reverse=reverse, planar=planar),
            res = p==[]? [] :
                is_vector(p)? apply(m, p) :
                is_vnf(p)? [apply(m, p[0]), p[1]] :
                is_list(p[0])? [for (pp=p) rot(p=pp, _m=m)] :
                assert(false, "The p argument for rot() is not a point, path, patch, matrix, or VNF.")
        ) res
    );




// Function&Module: xrot()
//
// Usage: As Module
//   xrot(a, [cp=]) ...
// Usage: As a function to rotate points
//   rotated = xrot(a, p, [cp=]);
// Usage: As a function to return rotation matrix
//   mat = xrot(a, [cp=]);
//
// Topics: Affine, Matrices, Transforms, Rotation
// See Also: rot(), yrot(), zrot(), affine2d_zrot(), affine3d_xrot(), affine3d_yrot(), affine3d_zrot() 
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
//   p = If called as a function, this contains data to rotate: a point, list of points, bezier patch or VNF.
//   ---
//   cp = centerpoint to rotate around. Default: [0,0,0]
//
// Example:
//   #cylinder(h=50, r=10, center=true);
//   xrot(90) cylinder(h=50, r=10, center=true);
module xrot(a=0, p, cp)
{
    assert(is_undef(p), "Module form `xrot()` does not accept p= argument.");
    if (a==0) {
        children();  // May be slightly faster?
    } else if (!is_undef(cp)) {
        translate(cp) rotate([a, 0, 0]) translate(-cp) children();
    } else {
        rotate([a, 0, 0]) children();
    }
}

function xrot(a=0, p, cp) = rot([a,0,0], cp=cp, p=p);


// Function&Module: yrot()
//
// Usage: As Module
//   yrot(a, [cp=]) ...
// Usage: Rotate Points
//   rotated = yrot(a, p, [cp=]);
// Usage: Get Rotation Matrix
//   mat = yrot(a, [cp=]);
//
// Topics: Affine, Matrices, Transforms, Rotation
// See Also: rot(), xrot(), zrot(), affine2d_zrot(), affine3d_xrot(), affine3d_yrot(), affine3d_zrot() 
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
//   p = If called as a function, this contains data to rotate: a point, list of points, bezier patch or VNF.
//   ---
//   cp = centerpoint to rotate around. Default: [0,0,0]
//
// Example:
//   #cylinder(h=50, r=10, center=true);
//   yrot(90) cylinder(h=50, r=10, center=true);
module yrot(a=0, p, cp)
{
    assert(is_undef(p), "Module form `yrot()` does not accept p= argument.");
    if (a==0) {
        children();  // May be slightly faster?
    } else if (!is_undef(cp)) {
        translate(cp) rotate([0, a, 0]) translate(-cp) children();
    } else {
        rotate([0, a, 0]) children();
    }
}

function yrot(a=0, p, cp) = rot([0,a,0], cp=cp, p=p);


// Function&Module: zrot()
//
// Usage: As Module
//   zrot(a, [cp=]) ...
// Usage: As Function to rotate points
//   rotated = zrot(a, p, [cp=]);
// Usage: As Function to return rotation matrix
//   mat = zrot(a, [cp=]);
//
// Topics: Affine, Matrices, Transforms, Rotation
// See Also: rot(), xrot(), yrot(), affine2d_zrot(), affine3d_xrot(), affine3d_yrot(), affine3d_zrot() 
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
//   p = If called as a function, this contains data to rotate: a point, list of points, bezier patch or VNF.
//   ---
//   cp = centerpoint to rotate around. Default: [0,0,0]
//
// Example:
//   #cube(size=[60,20,40], center=true);
//   zrot(90) cube(size=[60,20,40], center=true);
module zrot(a=0, p, cp)
{
    assert(is_undef(p), "Module form `zrot()` does not accept p= argument.");
    if (a==0) {
        children();  // May be slightly faster?
    } else if (!is_undef(cp)) {
        translate(cp) rotate(a) translate(-cp) children();
    } else {
        rotate(a) children();
    }
}

function zrot(a=0, p, cp) = rot(a, cp=cp, p=p);


// Function&Module: xyrot()
//
// Usage: As Module
//   xyrot(a, [cp=]) ...
// Usage: As a Function to rotate points
//   rotated = xyrot(a, p, [cp=]);
// Usage: As a Function to get rotation matrix
//   mat = xyrot(a, [cp=]);
//
// Topics: Affine, Matrices, Transforms, Rotation
// See Also: rot(), xrot(), yrot(), zrot(), xzrot(), yzrot(), xyzrot(), affine3d_rot_by_axis() 
//
// Description:
//   Rotates around the [1,1,0] vector axis by the given number of degrees.  If `cp` is given, rotations are performed around that centerpoint.
//   * Called as a module, rotates all children.
//   * Called as a function with a `p` argument containing a point, returns the rotated point.
//   * Called as a function with a `p` argument containing a list of points, returns the list of rotated points.
//   * Called as a function with a [bezier patch](beziers.scad) in the `p` argument, returns the rotated patch.
//   * Called as a function with a [VNF structure](vnf.scad) in the `p` argument, returns the rotated VNF.
//   * Called as a function without a `p` argument, returns the affine3d rotational matrix.
//
// Arguments:
//   a = angle to rotate by in degrees.
//   p = If called as a function, this contains data to rotate: a point, list of points, bezier patch or VNF.
//   ---
//   cp = centerpoint to rotate around. Default: [0,0,0]
//
// Example:
//   #cylinder(h=50, r=10, center=true);
//   xyrot(90) cylinder(h=50, r=10, center=true);
module xyrot(a=0, p, cp)
{
    assert(is_undef(p), "Module form `xyrot()` does not accept p= argument.");
    if (a==0) {
        children();  // May be slightly faster?
    } else {
        mat = xyrot(a=a, cp=cp);
        multmatrix(mat) children();
    }
}

function xyrot(a=0, p, cp) = rot(a=a, v=[1,1,0], cp=cp, p=p);


// Function&Module: xzrot()
//
// Usage: As Module
//   xzrot(a, [cp=]) ...
// Usage: As Function to rotate points
//   rotated = xzrot(a, p, [cp=]);
// Usage: As Function to return rotation matrix
//   mat = xzrot(a, [cp=]);
//
// Topics: Affine, Matrices, Transforms, Rotation
// See Also: rot(), xrot(), yrot(), zrot(), xyrot(), yzrot(), xyzrot(), affine3d_rot_by_axis() 
//
// Description:
//   Rotates around the [1,0,1] vector axis by the given number of degrees.  If `cp` is given, rotations are performed around that centerpoint.
//   * Called as a module, rotates all children.
//   * Called as a function with a `p` argument containing a point, returns the rotated point.
//   * Called as a function with a `p` argument containing a list of points, returns the list of rotated points.
//   * Called as a function with a [bezier patch](beziers.scad) in the `p` argument, returns the rotated patch.
//   * Called as a function with a [VNF structure](vnf.scad) in the `p` argument, returns the rotated VNF.
//   * Called as a function without a `p` argument, returns the affine3d rotational matrix.
//
// Arguments:
//   a = angle to rotate by in degrees.
//   p = If called as a function, this contains data to rotate: a point, list of points, bezier patch or VNF.
//   ---
//   cp = centerpoint to rotate around. Default: [0,0,0]
//
// Example:
//   #cylinder(h=50, r=10, center=true);
//   xzrot(90) cylinder(h=50, r=10, center=true);
module xzrot(a=0, p, cp)
{
    assert(is_undef(p), "Module form `xzrot()` does not accept p= argument.");
    if (a==0) {
        children();  // May be slightly faster?
    } else {
        mat = xzrot(a=a, cp=cp);
        multmatrix(mat) children();
    }
}

function xzrot(a=0, p, cp) = rot(a=a, v=[1,0,1], cp=cp, p=p);


// Function&Module: yzrot()
//
// Usage: As Module
//   yzrot(a, [cp=]) ...
// Usage: As Function to rotate points
//   rotated = yzrot(a, p, [cp=]);
// Usage: As Function to return rotation matrix
//   mat = yzrot(a, [cp=]);
//
// Topics: Affine, Matrices, Transforms, Rotation
// See Also: rot(), xrot(), yrot(), zrot(), xyrot(), xzrot(), xyzrot(), affine3d_rot_by_axis() 
//
// Description:
//   Rotates around the [0,1,1] vector axis by the given number of degrees.  If `cp` is given, rotations are performed around that centerpoint.
//   * Called as a module, rotates all children.
//   * Called as a function with a `p` argument containing a point, returns the rotated point.
//   * Called as a function with a `p` argument containing a list of points, returns the list of rotated points.
//   * Called as a function with a [bezier patch](beziers.scad) in the `p` argument, returns the rotated patch.
//   * Called as a function with a [VNF structure](vnf.scad) in the `p` argument, returns the rotated VNF.
//   * Called as a function without a `p` argument, returns the affine3d rotational matrix.
//
// Arguments:
//   a = angle to rotate by in degrees.
//   p = If called as a function, this contains data to rotate: a point, list of points, bezier patch or VNF.
//   ---
//   cp = centerpoint to rotate around. Default: [0,0,0]
//
// Example:
//   #cylinder(h=50, r=10, center=true);
//   yzrot(90) cylinder(h=50, r=10, center=true);
module yzrot(a=0, p, cp)
{
    assert(is_undef(p), "Module form `yzrot()` does not accept p= argument.");
    if (a==0) {
        children();  // May be slightly faster?
    } else {
        mat = yzrot(a=a, cp=cp);
        multmatrix(mat) children();
    }
}

function yzrot(a=0, p, cp) = rot(a=a, v=[0,1,1], cp=cp, p=p);


// Function&Module: xyzrot()
//
// Usage: As Module
//   xyzrot(a, [cp=]) ...
// Usage: As Function to rotate points
//   rotated = xyzrot(a, p, [cp=]);
// Usage: As Function to return rotation matrix
//   mat = xyzrot(a, [cp=]);
//
// Topics: Affine, Matrices, Transforms, Rotation
// See Also: rot(), xrot(), yrot(), zrot(), xyrot(), xzrot(), yzrot(), affine3d_rot_by_axis() 
//
// Description:
//   Rotates around the [1,1,1] vector axis by the given number of degrees.  If `cp` is given, rotations are performed around that centerpoint.
//   * Called as a module, rotates all children.
//   * Called as a function with a `p` argument containing a point, returns the rotated point.
//   * Called as a function with a `p` argument containing a list of points, returns the list of rotated points.
//   * Called as a function with a [bezier patch](beziers.scad) in the `p` argument, returns the rotated patch.
//   * Called as a function with a [VNF structure](vnf.scad) in the `p` argument, returns the rotated VNF.
//   * Called as a function without a `p` argument, returns the affine3d rotational matrix.
//
// Arguments:
//   a = angle to rotate by in degrees.
//   p = If called as a function, this contains data to rotate: a point, list of points, bezier patch or VNF.
//   ---
//   cp = centerpoint to rotate around. Default: [0,0,0]
//
// Example:
//   #cylinder(h=50, r=10, center=true);
//   xyzrot(90) cylinder(h=50, r=10, center=true);
module xyzrot(a=0, p, cp)
{
    assert(is_undef(p), "Module form `xyzrot()` does not accept p= argument.");
    if (a==0) {
        children();  // May be slightly faster?
    } else {
        mat = xyzrot(a=a, cp=cp);
        multmatrix(mat) children();
    }
}

function xyzrot(a=0, p, cp) = rot(a=a, v=[1,1,1], cp=cp, p=p);


//////////////////////////////////////////////////////////////////////
// Section: Scaling and Mirroring
//////////////////////////////////////////////////////////////////////


// Function&Module: scale()
// Usage: As Module
//   scale(SCALAR) ...
//   scale([X,Y,Z]) ...
// Usage: Scale Points
//   pts = scale(v, p, [cp=]);
// Usage: Get Scaling Matrix
//   mat = scale(v, [cp=]);
// Topics: Affine, Matrices, Transforms, Scaling
// See Also: xscale(), yscale(), zscale(), affine2d_scale(), affine3d_scale() 
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
//   ---
//   cp = If given, centers the scaling on the point `cp`.
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
function scale(v=1, p, cp=[0,0,0]) =
    assert(is_num(v) || is_vector(v))
    assert(is_undef(p) || is_list(p))
    assert(is_vector(cp))
    let( v = is_num(v)? [v,v,v] : v )
    is_undef(p)? (
        len(v)==2? (
            cp==[0,0,0] || cp == [0,0] ? affine2d_scale(v) : (
                affine2d_translate(point2d(cp)) *
                affine2d_scale(v) *
                affine2d_translate(point2d(-cp))
            )
        ) : (
            cp==[0,0,0] ? affine3d_scale(v) : (
                affine3d_translate(point3d(cp)) *
                affine3d_scale(v) *
                affine3d_translate(point3d(-cp))
            )
        )
    ) : (
        assert(is_list(p))
        let( mat = scale(v=v, cp=cp) )
        is_vector(p)? apply(mat, p) :
        is_vnf(p)? let(inv=product([for (x=v) x<0? -1 : 1])) [
            apply(mat, p[0]),
            inv>=0? p[1] : [for (l=p[1]) reverse(l)]
        ] :
        apply(mat, p)
    );


// Function&Module: xscale()
//
//
// Usage: As Module
//   xscale(x, [cp=]) ...
// Usage: Scale Points
//   scaled = xscale(x, p, [cp=]);
// Usage: Get Affine Matrix
//   mat = xscale(x, [cp=], [planar=]);
//
// Topics: Affine, Matrices, Transforms, Scaling
// See Also: scale(), yscale(), zscale(), affine2d_scale(), affine3d_scale() 
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
//   p = A point, path, bezier patch, or VNF to scale, when called as a function.
//   ---
//   cp = If given as a point, centers the scaling on the point `cp`.  If given as a scalar, centers scaling on the point `[cp,0,0]`
//   planar = If true, and `p` is not given, then the matrix returned is an affine2d matrix instead of an affine3d matrix.
//
// Example: As Module
//   xscale(3) sphere(r=10);
//
// Example(2D): Scaling Points
//   path = circle(d=50,$fn=12);
//   #stroke(path,closed=true);
//   stroke(xscale(2,p=path),closed=true);
module xscale(x=1, p, cp=0, planar) {
    assert(is_undef(p), "Module form `xscale()` does not accept p= argument.");
    assert(is_undef(planar), "Module form `xscale()` does not accept planar= argument.");
    cp = is_num(cp)? [cp,0,0] : cp;
    if (cp == [0,0,0]) {
        scale([x,1,1]) children();
    } else {
        translate(cp) scale([x,1,1]) translate(-cp) children();
    }
}

function xscale(x=1, p, cp=0, planar=false) =
    assert(is_finite(x))
    assert(is_undef(p) || is_list(p))
    assert(is_finite(cp) || is_vector(cp))
    assert(is_bool(planar))
    let( cp = is_num(cp)? [cp,0,0] : cp )
    (planar || (!is_undef(p) && len(p)==2))
      ? scale([x,1], cp=cp, p=p)
      : scale([x,1,1], cp=cp, p=p);


// Function&Module: yscale()
//
// Usage: As Module
//   yscale(y, [cp=]) ...
// Usage: Scale Points
//   scaled = yscale(y, p, [cp=]);
// Usage: Get Affine Matrix
//   mat = yscale(y, [cp=], [planar=]);
//
// Topics: Affine, Matrices, Transforms, Scaling
// See Also: scale(), xscale(), zscale(), affine2d_scale(), affine3d_scale() 
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
//   p = A point, path, bezier patch, or VNF to scale, when called as a function.
//   ---
//   cp = If given as a point, centers the scaling on the point `cp`.  If given as a scalar, centers scaling on the point `[0,cp,0]`
//   planar = If true, and `p` is not given, then the matrix returned is an affine2d matrix instead of an affine3d matrix.
//
// Example: As Module
//   yscale(3) sphere(r=10);
//
// Example(2D): Scaling Points
//   path = circle(d=50,$fn=12);
//   #stroke(path,closed=true);
//   stroke(yscale(2,p=path),closed=true);
module yscale(y=1, p, cp=0, planar) {
    assert(is_undef(p), "Module form `yscale()` does not accept p= argument.");
    assert(is_undef(planar), "Module form `yscale()` does not accept planar= argument.");
    cp = is_num(cp)? [0,cp,0] : cp;
    if (cp == [0,0,0]) {
        scale([1,y,1]) children();
    } else {
        translate(cp) scale([1,y,1]) translate(-cp) children();
    }
}

function yscale(y=1, p, cp=0, planar=false) =
    assert(is_finite(y))
    assert(is_undef(p) || is_list(p))
    assert(is_finite(cp) || is_vector(cp))
    assert(is_bool(planar))
    let( cp = is_num(cp)? [0,cp,0] : cp )
    (planar || (!is_undef(p) && len(p)==2))
      ? scale([1,y], cp=cp, p=p)
      : scale([1,y,1], cp=cp, p=p);


// Function&Module: zscale()
//
// Usage: As Module
//   zscale(z, [cp=]) ...
// Usage: Scale Points
//   scaled = zscale(z, p, [cp=]);
// Usage: Get Affine Matrix
//   mat = zscale(z, [cp=]);
//
// Topics: Affine, Matrices, Transforms, Scaling
// See Also: scale(), xscale(), yscale(), affine2d_scale(), affine3d_scale() 
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
//   p = A point, path, bezier patch, or VNF to scale, when called as a function.
//   ---
//   cp = If given as a point, centers the scaling on the point `cp`.  If given as a scalar, centers scaling on the point `[0,0,cp]`
//
// Example: As Module
//   zscale(3) sphere(r=10);
//
// Example: Scaling Points
//   path = xrot(90,p=path3d(circle(d=50,$fn=12)));
//   #trace_path(path);
//   trace_path(zscale(2,p=path));
module zscale(z=1, p, cp=0) {
    assert(is_undef(p), "Module form `zscale()` does not accept p= argument.");
    cp = is_num(cp)? [0,0,cp] : cp;
    if (cp == [0,0,0]) {
        scale([1,1,z]) children();
    } else {
        translate(cp) scale([1,1,z]) translate(-cp) children();
    }
}

function zscale(z=1, p, cp=0) =
    assert(is_finite(z))
    assert(is_undef(p) || is_list(p))
    assert(is_finite(cp) || is_vector(cp))
    let( cp = is_num(cp)? [0,0,cp] : cp )
    scale([1,1,z], cp=cp, p=p);


// Function&Module: mirror()
// Usage: As Module
//   mirror(v) ...
// Usage: As Function
//   pt = mirror(v, p);
// Usage: Get Reflection/Mirror Matrix
//   mat = mirror(v);
// Topics: Affine, Matrices, Transforms, Reflection, Mirroring
// See Also: xflip(), yflip(), zflip(), affine2d_mirror(), affine3d_mirror() 
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
    assert(is_vector(v))
    assert(is_undef(p) || is_list(p))
    let(m = len(v)==2? affine2d_mirror(v) : affine3d_mirror(v))
    is_undef(p)? m :
    is_num(p.x)? apply(m,p) :
    is_vnf(p)? [mirror(v=v,p=p[0]), [for (face=p[1]) reverse(face)]] :
    [for (l=p) is_vector(l)? apply(m,l) : mirror(v=v, p=l)];


// Function&Module: xflip()
//
// Usage: As Module
//   xflip([x]) ...
// Usage: As Function
//   pt = xflip(p, [x]);
// Usage: Get Affine Matrix
//   pt = xflip([x], [planar=]);
//
// Topics: Affine, Matrices, Transforms, Reflection, Mirroring
// See Also: mirror(), yflip(), zflip(), affine2d_mirror(), affine3d_mirror() 
//
// Description:
//   Mirrors/reflects across the origin [0,0,0], along the X axis.  If `x` is given, reflects across [x,0,0] instead.
//   * Called as the built-in module, mirrors all children across the line/plane.
//   * Called as a function with a point in the `p` argument, returns the point mirrored across the line/plane.
//   * Called as a function with a list of points in the `p` argument, returns the list of points, with each one mirrored across the line/plane.
//   * Called as a function with a [bezier patch](beziers.scad) in the `p` argument, returns the mirrored patch.
//   * Called as a function with a [VNF structure](vnf.scad) in the `p` argument, returns the mirrored VNF.
//   * Called as a function without a `p` argument, and `planar=true`, returns the affine2d 3x3 mirror matrix.
//   * Called as a function without a `p` argument, and `planar=false`, returns the affine3d 4x4 mirror matrix.
//
// Arguments:
//   x = The X coordinate of the plane of reflection.  Default: 0
//   p = If given, the point, path, patch, or VNF to mirror.  Function use only.
//   ---
//   planar = If true, and p is not given, returns a 2D affine transformation matrix.  Function use only.  Default: False
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
module xflip(p, x=0, planar) {
    assert(is_undef(p), "Module form `zflip()` does not accept p= argument.");
    assert(is_undef(planar), "Module form `zflip()` does not accept planar= argument.");
    translate([x,0,0])
        mirror([1,0,0])
            translate([-x,0,0]) children();
}

function xflip(p, x=0, planar=false) =
    assert(is_finite(x))
    assert(is_bool(planar))
    assert(is_undef(p) || is_list(p))
    let(
        v = RIGHT,
        n = planar? point2d(v) : v
    )
    x == 0 ? mirror(n,p=p) :
    let(
        cp = x * n,
        mat = move(cp) * mirror(n) * move(-cp)
    ) is_undef(p)? mat : apply(mat, p);


// Function&Module: yflip()
//
// Usage: As Module
//   yflip([y]) ...
// Usage: As Function
//   pt = yflip(p, [y]);
// Usage: Get Affine Matrix
//   pt = yflip([y], [planar=]);
//
// Topics: Affine, Matrices, Transforms, Reflection, Mirroring
// See Also: mirror(), xflip(), zflip(), affine2d_mirror(), affine3d_mirror() 
//
// Description:
//   Mirrors/reflects across the origin [0,0,0], along the Y axis.  If `y` is given, reflects across [0,y,0] instead.
//   * Called as the built-in module, mirrors all children across the line/plane.
//   * Called as a function with a point in the `p` argument, returns the point mirrored across the line/plane.
//   * Called as a function with a list of points in the `p` argument, returns the list of points, with each one mirrored across the line/plane.
//   * Called as a function with a [bezier patch](beziers.scad) in the `p` argument, returns the mirrored patch.
//   * Called as a function with a [VNF structure](vnf.scad) in the `p` argument, returns the mirrored VNF.
//   * Called as a function without a `p` argument, and `planar=true`, returns the affine2d 3x3 mirror matrix.
//   * Called as a function without a `p` argument, and `planar=false`, returns the affine3d 4x4 mirror matrix.
//
// Arguments:
//   p = If given, the point, path, patch, or VNF to mirror.  Function use only.
//   y = The Y coordinate of the plane of reflection.  Default: 0
//   ---
//   planar = If true, and p is not given, returns a 2D affine transformation matrix.  Function use only.  Default: False
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
module yflip(p, y=0, planar) {
    assert(is_undef(p), "Module form `yflip()` does not accept p= argument.");
    assert(is_undef(planar), "Module form `yflip()` does not accept planar= argument.");
    translate([0,y,0])
        mirror([0,1,0])
            translate([0,-y,0]) children();
}

function yflip(p, y=0, planar=false) =
    assert(is_finite(y))
    assert(is_bool(planar))
    assert(is_undef(p) || is_list(p))
    let(
        v = BACK,
        n = planar? point2d(v) : v
    )
    y == 0 ? mirror(n,p=p) :
    let(
        cp = y * n,
        mat = move(cp) * mirror(n) * move(-cp)
    ) is_undef(p)? mat : apply(mat, p);


// Function&Module: zflip()
//
// Usage: As Module
//   zflip([z]) ...
// Usage: As Function
//   pt = zflip(p, [z]);
// Usage: Get Affine Matrix
//   pt = zflip([z]);
//
// Topics: Affine, Matrices, Transforms, Reflection, Mirroring
// See Also: mirror(), xflip(), yflip(), affine2d_mirror(), affine3d_mirror() 
//
// Description:
//   Mirrors/reflects across the origin [0,0,0], along the Z axis.  If `z` is given, reflects across [0,0,z] instead.
//   * Called as the built-in module, mirrors all children across the line/plane.
//   * Called as a function with a point in the `p` argument, returns the point mirrored across the line/plane.
//   * Called as a function with a list of points in the `p` argument, returns the list of points, with each one mirrored across the line/plane.
//   * Called as a function with a [bezier patch](beziers.scad) in the `p` argument, returns the mirrored patch.
//   * Called as a function with a [VNF structure](vnf.scad) in the `p` argument, returns the mirrored VNF.
//   * Called as a function without a `p` argument, returns the affine3d 4x4 mirror matrix.
//
// Arguments:
//   p = If given, the point, path, patch, or VNF to mirror.  Function use only.
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
module zflip(p, z=0) {
    assert(is_undef(p), "Module form `zflip()` does not accept p= argument.");
    translate([0,0,z])
        mirror([0,0,1])
            translate([0,0,-z]) children();
}

function zflip(p, z=0) =
    assert(is_finite(z))
    assert(is_undef(p) || is_list(p))
    z==0? mirror([0,0,1],p=p) :
    move([0,0,z],p=mirror([0,0,1],p=move([0,0,-z],p=p)));


// Function&Module: xyflip()
//
// Usage: As Module
//   xyflip([cp]) ...
// Usage: As Function
//   pt = xyflip(p, [cp]);
// Usage: Get Affine Matrix
//   pt = xyflip([cp], [planar=]);
//
// Topics: Affine, Matrices, Transforms, Reflection, Mirroring
// See Also: mirror(), xflip(), yflip(), zflip(), xzflip(), yzflip(), affine2d_mirror(), affine3d_mirror() 
//
// Description:
//   Mirrors/reflects across the origin [0,0,0], along the reflection plane where X=Y.  If `cp` is given, the reflection plane passes through that point
//   * Called as the built-in module, mirrors all children across the line/plane.
//   * Called as a function with a point in the `p` argument, returns the point mirrored across the line/plane.
//   * Called as a function with a list of points in the `p` argument, returns the list of points, with each one mirrored across the line/plane.
//   * Called as a function with a [bezier patch](beziers.scad) in the `p` argument, returns the mirrored patch.
//   * Called as a function with a [VNF structure](vnf.scad) in the `p` argument, returns the mirrored VNF.
//   * Called as a function without a `p` argument, and `planer=true`, returns the affine2d 3x3 mirror matrix.
//   * Called as a function without a `p` argument, and `planar=false`, returns the affine3d 4x4 mirror matrix.
//
// Arguments:
//   p = If given, the point, path, patch, or VNF to mirror.  Function use only.
//   cp = The centerpoint of the plane of reflection, given either as a point, or as a scalar distance away from the origin.
//   ---
//   planar = If true, and p is not given, returns a 2D affine transformation matrix.  Function use only.  Default: False
//
// Example(2D):
//   xyflip() text("Foobar", size=20, halign="center");
//
// Example:
//   left(10) frame_ref();
//   right(10) xyflip() frame_ref();
//
// Example:
//   xyflip(cp=-15) frame_ref();
//
// Example:
//   xyflip(cp=[10,10,10]) frame_ref();
//
// Example: Called as Function for a 3D matrix
//   mat = xyflip();
//   multmatrix(mat) frame_ref();
//
// Example(2D): Called as Function for a 2D matrix
//   mat = xyflip(planar=true);
//   multmatrix(mat) text("Foobar", size=20, halign="center");
module xyflip(p, cp=0, planar) {
    assert(is_undef(p), "Module form `xyflip()` does not accept p= argument.");
    assert(is_undef(planar), "Module form `xyflip()` does not accept planar= argument.");
    mat = xyflip(cp=cp);
    multmatrix(mat) children();
}

function xyflip(p, cp=0, planar=false) =
    assert(is_finite(cp) || is_vector(cp))
    let(
        v = unit([-1,1,0]),
        n = planar? point2d(v) : v
    )
    cp == 0 || cp==[0,0,0]? mirror(n, p=p) :
    let(
        cp = is_finite(cp)? n * cp :
            is_vector(cp)? assert(len(cp) == len(n)) cp :
            assert(is_finite(cp) || is_vector(cp)),
        mat = move(cp) * mirror(n) * move(-cp)
    ) is_undef(p)? mat : apply(mat, p);


// Function&Module: xzflip()
//
// Usage: As Module
//   xzflip([cp]) ...
// Usage: As Function
//   pt = xzflip([cp], p);
// Usage: Get Affine Matrix
//   pt = xzflip([cp]);
//
// Topics: Affine, Matrices, Transforms, Reflection, Mirroring
// See Also: mirror(), xflip(), yflip(), zflip(), xyflip(), yzflip(), affine2d_mirror(), affine3d_mirror() 
//
// Description:
//   Mirrors/reflects across the origin [0,0,0], along the reflection plane where X=Y.  If `cp` is given, the reflection plane passes through that point
//   * Called as the built-in module, mirrors all children across the line/plane.
//   * Called as a function with a point in the `p` argument, returns the point mirrored across the line/plane.
//   * Called as a function with a list of points in the `p` argument, returns the list of points, with each one mirrored across the line/plane.
//   * Called as a function with a [bezier patch](beziers.scad) in the `p` argument, returns the mirrored patch.
//   * Called as a function with a [VNF structure](vnf.scad) in the `p` argument, returns the mirrored VNF.
//   * Called as a function without a `p` argument, returns the affine3d 4x4 mirror matrix.
//
// Arguments:
//   p = If given, the point, path, patch, or VNF to mirror.  Function use only.
//   cp = The centerpoint of the plane of reflection, given either as a point, or as a scalar distance away from the origin.
//
// Example:
//   left(10) frame_ref();
//   right(10) xzflip() frame_ref();
//
// Example:
//   xzflip(cp=-15) frame_ref();
//
// Example:
//   xzflip(cp=[10,10,10]) frame_ref();
//
// Example: Called as Function
//   mat = xzflip();
//   multmatrix(mat) frame_ref();
module xzflip(p, cp=0) {
    assert(is_undef(p), "Module form `xzflip()` does not accept p= argument.");
    mat = xzflip(cp=cp);
    multmatrix(mat) children();
}

function xzflip(p, cp=0) =
    assert(is_finite(cp) || is_vector(cp))
    let( n = unit([-1,0,1]) )
    cp == 0 || cp==[0,0,0]? mirror(n, p=p) :
    let(
        cp = is_finite(cp)? n * cp :
            is_vector(cp,3)? cp :
            assert(is_finite(cp) || is_vector(cp,3)),
        mat = move(cp) * mirror(n) * move(-cp)
    ) is_undef(p)? mat : apply(mat, p);


// Function&Module: yzflip()
//
// Usage: As Module
//   yzflip([x=]) ...
// Usage: As Function
//   pt = yzflip(p, [x=]);
// Usage: Get Affine Matrix
//   pt = yzflip([x=]);
//
// Topics: Affine, Matrices, Transforms, Reflection, Mirroring
// See Also: mirror(), xflip(), yflip(), zflip(), xyflip(), xzflip(), affine2d_mirror(), affine3d_mirror() 
//
// Description:
//   Mirrors/reflects across the origin [0,0,0], along the reflection plane where X=Y.  If `cp` is given, the reflection plane passes through that point
//   * Called as the built-in module, mirrors all children across the line/plane.
//   * Called as a function with a point in the `p` argument, returns the point mirrored across the line/plane.
//   * Called as a function with a list of points in the `p` argument, returns the list of points, with each one mirrored across the line/plane.
//   * Called as a function with a [bezier patch](beziers.scad) in the `p` argument, returns the mirrored patch.
//   * Called as a function with a [VNF structure](vnf.scad) in the `p` argument, returns the mirrored VNF.
//   * Called as a function without a `p` argument, returns the affine3d 4x4 mirror matrix.
//
// Arguments:
//   p = If given, the point, path, patch, or VNF to mirror.  Function use only.
//   cp = The centerpoint of the plane of reflection, given either as a point, or as a scalar distance away from the origin.
//
// Example:
//   left(10) frame_ref();
//   right(10) yzflip() frame_ref();
//
// Example:
//   yzflip(cp=-15) frame_ref();
//
// Example:
//   yzflip(cp=[10,10,10]) frame_ref();
//
// Example: Called as Function
//   mat = yzflip();
//   multmatrix(mat) frame_ref();
module yzflip(p, cp=0) {
    assert(is_undef(p), "Module form `yzflip()` does not accept p= argument.");
    mat = yzflip(cp=cp);
    multmatrix(mat) children();
}

function yzflip(p, cp=0) =
    assert(is_finite(cp) || is_vector(cp))
    let( n = unit([0,-1,1]) )
    cp == 0 || cp==[0,0,0]? mirror(n, p=p) :
    let(
        cp = is_finite(cp)? n * cp :
            is_vector(cp,3)? cp :
            assert(is_finite(cp) || is_vector(cp,3)),
        mat = move(cp) * mirror(n) * move(-cp)
    ) is_undef(p)? mat : apply(mat, p);



//////////////////////////////////////////////////////////////////////
// Section: Skewing
//////////////////////////////////////////////////////////////////////


// Function&Module: skew()
// Usage: As Module
//   skew([sxy=], [sxz=], [syx=], [syz=], [szx=], [szy=]) ...
// Usage: As Function
//   pts = skew(p, [sxy=], [sxz=], [syx=], [syz=], [szx=], [szy=]);
// Usage: Get Affine Matrix
//   mat = skew([sxy=], [sxz=], [syx=], [syz=], [szx=], [szy=], [planar=]);
// Topics: Affine, Matrices, Transforms, Skewing
// See Also: affine2d_skew(), affine3d_skew(), affine3d_skew_xy(), affine3d_skew_xz(), affine3d_skew_yz() 
//
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
//   p = If given, the point, path, patch, or VNF to skew.  Function use only.
//   ---
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
// Example(FlatSpin,VPD=275): Skew Along Multiple Axes.
//   skew(sxy=0.5, syx=0.3, szy=0.75) cube(40, center=true);
// Example(2D): Calling as a 2D Function
//   pts = skew(p=square(40,center=true), sxy=0.5);
//   color("yellow") stroke(pts, closed=true);
//   color("blue") move_copies(pts) circle(d=3, $fn=8);
// Example(FlatSpin,VPD=175): Calling as a 3D Function
//   pts = skew(p=path3d(square(40,center=true)), szx=0.5, szy=0.3);
//   trace_path(close_path(pts), showpts=true);
module skew(p, sxy=0, sxz=0, syx=0, syz=0, szx=0, szy=0)
{
    assert(is_undef(p), "Module form `skew()` does not accept p= argument.")
    multmatrix(
        affine3d_skew(sxy=sxy, sxz=sxz, syx=syx, syz=syz, szx=szx, szy=szy)
    ) children();
}

function skew(p, sxy=0, sxz=0, syx=0, syz=0, szx=0, szy=0, planar=false) =
    assert(is_finite(sxy))
    assert(is_finite(sxz))
    assert(is_finite(syx))
    assert(is_finite(syz))
    assert(is_finite(szx))
    assert(is_finite(szy))
    assert(is_bool(planar))
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


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
