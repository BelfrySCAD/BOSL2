//////////////////////////////////////////////////////////////////////
// LibFile: transforms.scad
//   Functions and modules that provide shortcuts for translation,
//   rotation and mirror operations.  Also provided are skew and frame_map
//   which remaps the coordinate axes.  The shortcuts can act on
//   geometry, like the usual OpenSCAD rotate() and translate(). They
//   also work as functions that operate on lists of points in various
//   forms: paths, VNFS and bezier patches. Lastly, the function form
//   of the shortcuts can return a matrix representing the operation
//   the shortcut performs. The rotation and scaling shortcuts accept
//   an optional centerpoint for the rotation or scaling operation.
//   .
//   Almost all of the transformation functions take a point, a point
//   list, bezier patch, or VNF as a second positional argument to
//   operate on.  The exceptions are rot(), frame_map() and skew().
// Includes:
//   include <BOSL2/std.scad>
// FileGroup: Basic Modeling
// FileSummary: Shortcuts for translation, rotation, etc.  Can act on geometry, paths, or can return a matrix.
// FileFootnotes: STD=Included in std.scad
//////////////////////////////////////////////////////////////////////

// Section: Affine Transformations
//   OpenSCAD provides various built-in modules to transform geometry by
//   translation, scaling, rotation, and mirroring.  All of these operations
//   are affine transformations.  A three-dimensional affine transformation
//   can be represented by a 4x4 matrix.  The transformation shortcuts in this
//   file generally have three modes of operation.  They can operate
//   directly on geometry like their OpenSCAD built-in equivalents.  For example,
//   `left(10) cube()`.  They can operate on a list of points (or various other
//   types of geometric data).  For example, operating on a list of points: `points = left(10, [[1,2,3],[4,5,6]])`.
//   The third option is that the shortcut can return the transformation matrix
//   corresponding to its action.  For example, `M=left(10)`.
//   .
//   This capability allows you to store and manipulate transformations, and can
//   be useful in more advanced modeling.  You can multiply these matrices
//   together, analogously to applying a sequence of operations with the
//   built-in transformations.  So you can write `zrot(37)left(5)cube()`
//   to perform two operations on a cube.  You can also store
//   that same transformation by multiplying the matrices together: `M = zrot(37) * left(5)`.
//   Note that the order is exactly the same as the order used to apply the transformation.
//   .
//   Suppose you have constructed `M` as above.  What now?  You can use
//   the OpensCAD built-in `multmatrix` to apply it to some geometry:  `multmatrix(M) cube()`.
//   Alternative you can use the BOSL2 function `apply` to apply `M` to a point, a list
//   of points, a bezier patch, or a VNF.  For example, `points = apply(M, [[3,4,5],[5,6,7]])`.
//   Note that the `apply` function can work on both 2D and 3D data, but if you want to
//   operate on 2D data, you must choose transformations that don't modify z
//   .
//   You can use matrices as described above without understanding the details, just
//   treating a matrix as a box that stores a transformation.  The OpenSCAD manual section for multmatrix
//   gives some details of how this works.  We'll elaborate a bit more below.  An affine transformation
//   matrix for three dimensional data is a 4x4 matrix.  The top left 3x3 portion gives the linear
//   transformation to apply to the data.  For example, it could be a rotation or scaling, or combination of both.
//   The 3x1 column at the top right gives the translation to apply.  The bottom row should be `[0,0,0,1]`.  That
//   bottom row is only present to enable
//   the matrices to be multiplied together.  OpenSCAD ignores it and in fact `multmatrix` will
//   accept a 3x4 matrix, where that row is missing.  In order for a matrix to act on a point you have to
//   augment the point with an extra 1, making it a length 4 vector.  In OpenSCAD you can then compute the
//   the affine transformed point as `tran_point = M * point`.  However, this syntax hides a complication that
//   arises if you have a list of points.  A list of points like `[[1,2,3,1],[4,5,6,1],[7,8,9,1]]` has the augmented points
//   as row vectors on the list.  In order to transform such a list, it needs to be muliplied on the right
//   side, not the left side.



_NO_ARG = [true,[123232345],false];


//////////////////////////////////////////////////////////////////////
// Section: Translations
//////////////////////////////////////////////////////////////////////

// Function&Module: move()
// Aliases: translate()
//
// Synopsis: Translates children in an arbitrary direction.
// SynTags: Trans, Path, VNF, Mat
// Topics: Affine, Matrices, Transforms, Translation
// See Also: left(), right(), fwd(), back(), down(), up(), spherical_to_xyz(), altaz_to_xyz(), cylindrical_to_xyz(), polar_to_xy()
//
// Usage: As Module
//   move(v) CHILDREN;
// Usage: As a function to translate points, VNF, or Bezier patches
//   pts = move(v, p);
//   pts = move(STRING, p);
// Usage: Get Translation Matrix
//   mat = move(v);
//
// Description:
//   Translates position by the given amount.
//   * Called as a module, moves/translates all children.
//   * Called as a function with the `p` argument, returns the translated point or list of points.
//   * Called as a function with a [bezier patch](beziers.scad) in the `p` argument, returns the translated patch.
//   * Called as a function with a [VNF structure](vnf.scad) in the `p` argument, returns the translated VNF.
//   * Called as a function with the `p` argument set to a VNF or a polygon and `v` set to "centroid", "mean" or "box", translates the argument to the centroid, mean, or bounding box center respectively.
//   * Called as a function without a `p` argument, returns a 4x4 translation matrix for operating on 3D data.  
//
// Arguments:
//   v = An [X,Y,Z] vector to translate by.  For function form with `p` a point list or VNF, can be "centroid", "mean" or "box".  
//   p = Either a point, or a list of points to be translated when used as a function.
//
// Example:
//   #sphere(d=10);
//   move([0,20,30]) sphere(d=10);
//
// Example: You can move a 3D object with a 2D vector.  The Z component is treated as zero.  
//   #sphere(d=10);
//   move([-10,-5]) sphere(d=10);
//
// Example(2D): Move to centroid
//   polygon(move("centroid", right_triangle([10,4])));
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
//   pt2 = move([0,3,1], p=[[1,2,3],[4,5,6]]);  // Returns: [[1,5,4], [4,8,7]]
//   mat2d = move([2,3]);    // Returns: [[1,0,2],[0,1,3],[0,0,1]]
//   mat3d = move([2,3,4]);  // Returns: [[1,0,0,2],[0,1,0,3],[0,0,1,4],[0,0,0,1]]
module move(v=[0,0,0], p) {
    req_children($children);  
    assert(!is_string(v),"Module form of `move()` does not accept string `v` arguments");
    assert(is_undef(p), "Module form `move()` does not accept p= argument.");
    assert(is_vector(v) && (len(v)==3 || len(v)==2), "Invalid value for `v`")
    translate(point3d(v)) children();
}

function move(v=[0,0,0], p=_NO_ARG) =
    is_string(v) ? (
        assert(is_vnf(p) || is_path(p),"String movements only work with point lists and VNFs")
        let(
             center = v=="centroid" ? centroid(p)
                    : v=="mean" ? mean(p)
                    : v=="box" ? mean(pointlist_bounds(p))
                    : assert(false,str("Unknown string movement ",v))
        )
        move(-center,p=p)
      )
    :
    assert(is_vector(v) && (len(v)==3 || len(v)==2), "Invalid value for `v`")
    let(
        m = affine3d_translate(point3d(v))
    )
    p==_NO_ARG ? m : apply(m, p);

function translate(v=[0,0,0], p=_NO_ARG) = move(v=v, p=p);


// Function&Module: left()
//
// Synopsis: Translates children leftwards (X-).
// SynTags: Trans, Path, VNF, Mat
// Topics: Affine, Matrices, Transforms, Translation
// See Also: move(), right(), fwd(), back(), down(), up()
//
// Usage: As Module
//   left(x) CHILDREN;
// Usage: Translate Points
//   pts = left(x, p);
// Usage: Get Translation Matrix
//   mat = left(x);
//
// Description:
//   If called as a module, moves/translates all children left (in the X- direction) by the given amount.
//   If called as a function with the `p` argument, returns the translated VNF, point or list of points.
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
    req_children($children);    
    assert(is_undef(p), "Module form `left()` does not accept p= argument.");
    assert(is_finite(x), "Invalid number")
    translate([-x,0,0]) children();
}

function left(x=0, p=_NO_ARG) =
    assert(is_finite(x), "Invalid number")
    move([-x,0,0],p=p);


// Function&Module: right()
// Aliases: xmove()
//
// Synopsis: Translates children rightwards (X+).
// SynTags: Trans, Path, VNF, Mat
// Topics: Affine, Matrices, Transforms, Translation
// See Also: move(), left(), fwd(), back(), down(), up()
//
// Usage: As Module
//   right(x) CHILDREN;
// Usage: Translate Points
//   pts = right(x, p);
// Usage: Get Translation Matrix
//   mat = right(x);
//
// Description:
//   If called as a module, moves/translates all children right (in the X+ direction) by the given amount.
//   If called as a function with the `p` argument, returns the translated VNF point or list of points.
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
    req_children($children);    
    assert(is_undef(p), "Module form `right()` does not accept p= argument.");
    assert(is_finite(x), "Invalid number")
    translate([x,0,0]) children();
}

function right(x=0, p=_NO_ARG) =
    assert(is_finite(x), "Invalid number")
    move([x,0,0],p=p);

module xmove(x=0, p) {
    req_children($children);    
    assert(is_undef(p), "Module form `xmove()` does not accept p= argument.");
    assert(is_finite(x), "Invalid number")
    translate([x,0,0]) children();
}

function xmove(x=0, p=_NO_ARG) =
    assert(is_finite(x), "Invalid number")
    move([x,0,0],p=p);


// Function&Module: fwd()
//
// Synopsis: Translates children forwards (Y-).
// SynTags: Trans, Path, VNF, Mat
// Topics: Affine, Matrices, Transforms, Translation
// See Also: move(), left(), right(), back(), down(), up()
//
// Usage: As Module
//   fwd(y) CHILDREN;
// Usage: Translate Points
//   pts = fwd(y, p);
// Usage: Get Translation Matrix
//   mat = fwd(y);
//
// Description:
//   If called as a module, moves/translates all children forward (in the Y- direction) by the given amount.
//   If called as a function with the `p` argument, returns the translated VNF, point or list of points.
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
    req_children($children);    
    assert(is_undef(p), "Module form `fwd()` does not accept p= argument.");
    assert(is_finite(y), "Invalid number")
    translate([0,-y,0]) children();
}

function fwd(y=0, p=_NO_ARG) =
    assert(is_finite(y), "Invalid number")
    move([0,-y,0],p=p);


// Function&Module: back()
// Aliases: ymove()
//
// Synopsis: Translates children backwards (Y+).
// SynTags: Trans, Path, VNF, Mat
// Topics: Affine, Matrices, Transforms, Translation
// See Also: move(), left(), right(), fwd(), down(), up()
//
// Usage: As Module
//   back(y) CHILDREN;
// Usage: Translate Points
//   pts = back(y, p);
// Usage: Get Translation Matrix
//   mat = back(y);
//
// Description:
//   If called as a module, moves/translates all children back (in the Y+ direction) by the given amount.
//   If called as a function with the `p` argument, returns the translated VNF, point or list of points.
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
    req_children($children);    
    assert(is_undef(p), "Module form `back()` does not accept p= argument.");
    assert(is_finite(y), "Invalid number")
    translate([0,y,0]) children();
}

function back(y=0,p=_NO_ARG) =
    assert(is_finite(y), "Invalid number")
    move([0,y,0],p=p);

module ymove(y=0, p) {
    req_children($children);    
    assert(is_undef(p), "Module form `ymove()` does not accept p= argument.");
    assert(is_finite(y), "Invalid number")
    translate([0,y,0]) children();
}

function ymove(y=0,p=_NO_ARG) =
    assert(is_finite(y), "Invalid number")
    move([0,y,0],p=p);


// Function&Module: down()
//
// Synopsis: Translates children downwards (Z-).
// SynTags: Trans, Path, VNF, Mat
// Topics: Affine, Matrices, Transforms, Translation
// See Also: move(), left(), right(), fwd(), back(), up()
//
// Usage: As Module
//   down(z) CHILDREN;
// Usage: Translate Points
//   pts = down(z, p);
// Usage: Get Translation Matrix
//   mat = down(z);
//
// Description:
//   If called as a module, moves/translates all children down (in the Z- direction) by the given amount.
//   If called as a function with the `p` argument, returns the translated VNF, point or list of points.
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
    req_children($children);    
    assert(is_undef(p), "Module form `down()` does not accept p= argument.");
    translate([0,0,-z]) children();
}

function down(z=0, p=_NO_ARG) =
    assert(is_finite(z), "Invalid number")
    move([0,0,-z],p=p);


// Function&Module: up()
// Aliases: zmove()
//
// Synopsis: Translates children upwards (Z+).
// SynTags: Trans, Path, VNF, Mat
// Topics: Affine, Matrices, Transforms, Translation
// See Also: move(), left(), right(), fwd(), back(), down()
//
// Usage: As Module
//   up(z) CHILDREN;
// Usage: Translate Points
//   pts = up(z, p);
// Usage: Get Translation Matrix
//   mat = up(z);
//
// Description:
//   If called as a module, moves/translates all children up (in the Z+ direction) by the given amount.
//   If called as a function with the `p` argument, returns the translated VNF, point or list of points.
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
    req_children($children);      
    assert(is_undef(p), "Module form `up()` does not accept p= argument.");
    assert(is_finite(z), "Invalid number");
    translate([0,0,z]) children();
}

function up(z=0, p=_NO_ARG) =
    assert(is_finite(z), "Invalid number")
    move([0,0,z],p=p);

module zmove(z=0, p) {
    req_children($children);      
    assert(is_undef(p), "Module form `zmove()` does not accept p= argument.");
    assert(is_finite(z), "Invalid number");
    translate([0,0,z]) children();
}

function zmove(z=0, p=_NO_ARG) =
    assert(is_finite(z), "Invalid number")
    move([0,0,z],p=p);



//////////////////////////////////////////////////////////////////////
// Section: Rotations
//////////////////////////////////////////////////////////////////////


// Function&Module: rot()
//
// Synopsis: Rotates children in various ways.
// SynTags: Trans, Path, VNF, Mat
// Topics: Affine, Matrices, Transforms, Rotation
// See Also: xrot(), yrot(), zrot(), tilt()
//
// Usage: As a Module
//   rot(a, [cp=], [reverse=]) CHILDREN;
//   rot([X,Y,Z], [cp=], [reverse=]) CHILDREN;
//   rot(a, v, [cp=], [reverse=]) CHILDREN;
//   rot(from=, to=, [a=], [reverse=]) CHILDREN;
// Usage: As a Function to transform data in `p`
//   pts = rot(a, p=, [cp=], [reverse=]);
//   pts = rot([X,Y,Z], p=, [cp=], [reverse=]);
//   pts = rot(a, v, p=, [cp=], [reverse=]);
//   pts = rot([a], from=, to=, p=, [reverse=]);
// Usage: As a Function to return a transform matrix
//   M = rot(a, [cp=], [reverse=]);
//   M = rot([X,Y,Z], [cp=], [reverse=]);
//   M = rot(a, v, [cp=], [reverse=]);
//   M = rot(from=, to=, [a=], [reverse=]);
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
//   * Called as a function without a `p` argument, returns the affine3d rotational matrix.
//   Note that unlike almost all the other transformations, the `p` argument must be given as a named argument.
//
// Arguments:
//   a = Scalar angle or vector of XYZ rotation angles to rotate by, in degrees.  If you use the `from` and `to` arguments then `a` must be a scalar.  Default: `0`
//   v = vector for the axis of rotation.  Default: [0,0,1] or UP
//   ---
//   cp = centerpoint to rotate around. Default: [0,0,0]
//   from = Starting vector for vector-based rotations.
//   to = Target vector for vector-based rotations.
//   reverse = If true, exactly reverses the rotation, including axis rotation ordering.  Default: false
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
    req_children($children);        
    m = rot(a=a, v=v, cp=cp, from=from, to=to, reverse=reverse);
    multmatrix(m) children();
}

function rot(a=0, v, cp, from, to, reverse=false, p=_NO_ARG) =
    assert(is_undef(from)==is_undef(to), "from and to must be specified together.")
    assert(is_undef(from) || is_vector(from, zero=false), "'from' must be a non-zero vector.")
    assert(is_undef(to) || is_vector(to, zero=false), "'to' must be a non-zero vector.")
    assert(is_undef(v) || is_vector(v, zero=false), "'v' must be a non-zero vector.")
    assert(is_undef(cp) || is_vector(cp), "'cp' must be a vector.")
    assert(is_finite(a) || is_vector(a), "'a' must be a finite scalar or a vector.")
    assert(is_bool(reverse))
    let(
        m = let(
                from = is_undef(from)? undef : point3d(from),
                to = is_undef(to)? undef : point3d(to),
                cp = is_undef(cp)? undef : point3d(cp),
                m1 = !is_undef(from) ?
                        assert(is_num(a)) 
                        affine3d_rot_from_to(from,to) * affine3d_rot_by_axis(from,a)
                   : !is_undef(v)?
                        assert(is_num(a))
                        affine3d_rot_by_axis(v,a)
                   : is_num(a) ? affine3d_zrot(a)
                   : affine3d_zrot(a.z) * affine3d_yrot(a.y) * affine3d_xrot(a.x),
                m2 = is_undef(cp)? m1 : (move(cp) * m1 * move(-cp)),
                m3 = reverse? rot_inverse(m2) : m2
            ) m3
    )
    p==_NO_ARG ? m : apply(m, p);




// Function&Module: xrot()
//
// Synopsis: Rotates children around the X axis using the right-hand rule.
// SynTags: Trans, Path, VNF, Mat
// Topics: Affine, Matrices, Transforms, Rotation
// See Also: rot(), yrot(), zrot(), tilt()
//
// Usage: As Module
//   xrot(a, [cp=]) CHILDREN;
// Usage: As a function to rotate points
//   rotated = xrot(a, p, [cp=]);
// Usage: As a function to return rotation matrix
//   mat = xrot(a, [cp=]);
//
// Description:
//   Rotates around the X axis by the given number of degrees.  If `cp` is given, rotations are performed around that centerpoint.
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
//   xrot(90) cylinder(h=50, r=10, center=true);
module xrot(a=0, p, cp)
{
    req_children($children);          
    assert(is_undef(p), "Module form `xrot()` does not accept p= argument.");
    if (a==0) {
        children();  // May be slightly faster?
    } else if (!is_undef(cp)) {
        translate(cp) rotate([a, 0, 0]) translate(-cp) children();
    } else {
        rotate([a, 0, 0]) children();
    }
}

function xrot(a=0, p=_NO_ARG, cp) = rot([a,0,0], cp=cp, p=p);


// Function&Module: yrot()
//
// Synopsis: Rotates children around the Y axis using the right-hand rule.
// SynTags: Trans, Path, VNF, Mat
// Topics: Affine, Matrices, Transforms, Rotation
// See Also: rot(), xrot(), zrot(), tilt()
//
// Usage: As Module
//   yrot(a, [cp=]) CHILDREN;
// Usage: Rotate Points
//   rotated = yrot(a, p, [cp=]);
// Usage: Get Rotation Matrix
//   mat = yrot(a, [cp=]);
//
// Description:
//   Rotates around the Y axis by the given number of degrees.  If `cp` is given, rotations are performed around that centerpoint.
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
//   yrot(90) cylinder(h=50, r=10, center=true);
module yrot(a=0, p, cp)
{
    req_children($children);  
    assert(is_undef(p), "Module form `yrot()` does not accept p= argument.");
    if (a==0) {
        children();  // May be slightly faster?
    } else if (!is_undef(cp)) {
        translate(cp) rotate([0, a, 0]) translate(-cp) children();
    } else {
        rotate([0, a, 0]) children();
    }
}

function yrot(a=0, p=_NO_ARG, cp) = rot([0,a,0], cp=cp, p=p);


// Function&Module: zrot()
//
// Synopsis: Rotates children around the Z axis using the right-hand rule.
// Topics: Affine, Matrices, Transforms, Rotation
// SynTags: Trans, Path, VNF, Mat
// See Also: rot(), xrot(), yrot(), tilt()
//
// Usage: As Module
//   zrot(a, [cp=]) CHILDREN;
// Usage: As Function to rotate points
//   rotated = zrot(a, p, [cp=]);
// Usage: As Function to return rotation matrix
//   mat = zrot(a, [cp=]);
//
// Description:
//   Rotates around the Z axis by the given number of degrees.  If `cp` is given, rotations are performed around that centerpoint.
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
//   #cube(size=[60,20,40], center=true);
//   zrot(90) cube(size=[60,20,40], center=true);
module zrot(a=0, p, cp)
{
    req_children($children);    
    assert(is_undef(p), "Module form `zrot()` does not accept p= argument.");
    if (a==0) {
        children();  // May be slightly faster?
    } else if (!is_undef(cp)) {
        translate(cp) rotate(a) translate(-cp) children();
    } else {
        rotate(a) children();
    }
}

function zrot(a=0, p=_NO_ARG, cp) = rot(a, cp=cp, p=p);


// Function&Module: tilt()
//
// Synopsis: Tilts children towards a direction
// SynTags: Trans, Path, VNF, Mat
// Topics: Affine, Matrices, Transforms, Rotation
// See Also: rot(), xrot(), yrot(), zrot()
//
// Usage: As a Module
//   tilt(to=, [reverse=], [cp=]) CHILDREN;
// Usage: As a Function to transform data in `p`
//   pts = tilt(to=, p=, [reverse=], [cp=]);
// Usage: As a Function to return a transform matrix
//   M = tilt(to=, [reverse=], [cp=]);
//
// Description:
//   This is shorthand for `rot(from=UP,to=x)` and operates similarly.  It tilts that which is pointing UP until it is pointing at the given direction vector.
//   * If the `cp` centerpoint argument is given, then the tilt/rotation is performed around that centerpoint.  So `tilt(...,cp=[1,2,3])` is equivalent to `move([1,2,3]) tilt(...) move([-1,-2,-3])`.
//   * If the `reverse` argument is true, then the tilt/rotation performed will be exactly reversed.
//   .
//   The behavior and return value varies depending on how `tilt()` is called:
//   * Called as a module, tilts all children.
//   * Called as a function with a `p` argument containing a point, returns the tilted/rotated point.
//   * Called as a function with a `p` argument containing a list of points, returns the list of tilted/rotated points.
//   * Called as a function with a [bezier patch](beziers.scad) in the `p` argument, returns the tilted/rotated patch.
//   * Called as a function with a [VNF structure](vnf.scad) in the `p` argument, returns the tilted/rotated VNF.
//   * Called as a function without a `p` argument, returns the affine3d rotational matrix.
//   Note that unlike almost all the other transformations, the `p` argument must be given as a named argument.
//
// Arguments:
//   to = Target vector for vector-based rotations.
//   ---
//   cp = centerpoint to tilt/rotate around. Default: [0,0,0]
//   reverse = If true, exactly reverses the rotation.  Default: false
//   p = If called as a function, this contains data to rotate: a point, list of points, bezier patch or a VNF.
//
// Example:
//   #cube([2,4,9]);
//   tilt(LEFT+BACK) cube([2,4,9]);
//
// Example(2D):
//   path = square([50,30], center=true);
//   #stroke(path, closed=true);
//   stroke(tilt(RIGHT+FWD,p=path3d(path)), closed=true);
module tilt(to, cp, reverse=false)
{
    req_children($children);
    m = rot(from=UP, to=to, cp=cp, reverse=reverse);
    multmatrix(m) children();
}


function tilt(to, cp, reverse=false, p=_NO_ARG) =
    assert(is_vector(to, zero=false), "'to' must be a non-zero vector.")
    assert(is_undef(cp) || is_vector(cp), "'cp' must be a vector.")
    assert(is_bool(reverse))
    let( m = rot(from=UP, to=to, cp=cp, reverse=reverse) )
    p==_NO_ARG ? m : apply(m, p);



//////////////////////////////////////////////////////////////////////
// Section: Scaling
//////////////////////////////////////////////////////////////////////


// Function&Module: scale()
//
// Synopsis: Scales children arbitrarily.
// SynTags: Trans, Path, VNF, Mat, Ext
// Topics: Affine, Matrices, Transforms, Scaling
// See Also: xscale(), yscale(), zscale()
//
// Usage: As Module
//   scale(SCALAR) CHILDREN;
//   scale([X,Y,Z]) CHILDREN;
// Usage: Scale Points
//   pts = scale(v, p, [cp=]);
// Usage: Get Scaling Matrix
//   mat = scale(v, [cp=]);
//
// Description:
//   Scales by the [X,Y,Z] scaling factors given in `v`.  If `v` is given as a scalar number, all axes are scaled uniformly by that amount.
//   * Called as the built-in module, scales all children.
//   * Called as a function with a point in the `p` argument, returns the scaled point.
//   * Called as a function with a list of points in the `p` argument, returns the list of scaled points.
//   * Called as a function with a [bezier patch](beziers.scad) in the `p` argument, returns the scaled patch.
//   * Called as a function with a [VNF structure](vnf.scad) in the `p` argument, returns the scaled VNF.
//   * Called as a function without a `p` argument, and a 2D list of scaling factors in `v`, returns an affine2d scaling matrix.
//   * Called as a function without a `p` argument, and a 3D list of scaling factors in `v`, returns an affine3d scaling matrix.
//
// Arguments:
//   v = Either a numeric uniform scaling factor, or a list of [X,Y,Z] scaling factors.  Default: 1
//   p = If called as a function, the point or list of points to scale.
//   ---
//   cp = If given, centers the scaling on the point `cp`.
//
// Example(NORENDER):
//   pt1 = scale(3, p=[3,1,4]);        // Returns: [9,3,12]
//   pt2 = scale([2,3,4], p=[3,1,4]);  // Returns: [6,3,16]
//   pt3 = scale([2,3,4], p=[[1,2,3],[4,5,6]]);  // Returns: [[2,6,12], [8,15,24]]
//   mat2d = scale([2,3]);    // Returns: [[2,0,0],[0,3,0],[0,0,1]]
//   mat3d = scale([2,3,4]);  // Returns: [[2,0,0,0],[0,3,0,0],[0,0,4,0],[0,0,0,1]]
//
// Example(2D):
//   path = circle(d=50,$fn=12);
//   #stroke(path,closed=true);
//   stroke(scale([1.5,3],p=path),closed=true);
function scale(v=1, p=_NO_ARG, cp=[0,0,0]) =
    assert(is_num(v) || is_vector(v),"Invalid scale")
    assert(p==_NO_ARG || is_list(p),"Invalid point list")
    assert(is_vector(cp))
    let(
        v = is_num(v)? [v,v,v] : v,
        m = cp==[0,0,0]
          ? affine3d_scale(v)
          : affine3d_translate(point3d(cp))
            * affine3d_scale(v)
            * affine3d_translate(point3d(-cp))
    )
    p==_NO_ARG? m : apply(m, p) ;


// Function&Module: xscale()
//
// Synopsis: Scales children along the X axis.
// SynTags: Trans, Path, VNF, Mat
// Topics: Affine, Matrices, Transforms, Scaling
// See Also: scale(), yscale(), zscale()
//
// Usage: As Module
//   xscale(x, [cp=]) CHILDREN;
// Usage: Scale Points
//   scaled = xscale(x, p, [cp=]);
// Usage: Get Affine Matrix
//   mat = xscale(x, [cp=]);
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
//
// Example: As Module
//   xscale(3) sphere(r=10);
//
// Example(2D): Scaling Points
//   path = circle(d=50,$fn=12);
//   #stroke(path,closed=true);
//   stroke(xscale(2,p=path),closed=true);
module xscale(x=1, p, cp=0) {
    req_children($children);      
    assert(is_undef(p), "Module form `xscale()` does not accept p= argument.");
    cp = is_num(cp)? [cp,0,0] : cp;
    if (cp == [0,0,0]) {
        scale([x,1,1]) children();
    } else {
        translate(cp) scale([x,1,1]) translate(-cp) children();
    }
}

function xscale(x=1, p=_NO_ARG, cp=0) =
    assert(is_finite(x))
    assert(p==_NO_ARG || is_list(p))
    assert(is_finite(cp) || is_vector(cp))
    let( cp = is_num(cp)? [cp,0,0] : cp )
    scale([x,1,1], cp=cp, p=p);


// Function&Module: yscale()
//
// Synopsis: Scales children along the Y axis.
// SynTags: Trans, Path, VNF, Mat
// Topics: Affine, Matrices, Transforms, Scaling
// See Also: scale(), xscale(), zscale()
//
// Usage: As Module
//   yscale(y, [cp=]) CHILDREN;
// Usage: Scale Points
//   scaled = yscale(y, p, [cp=]);
// Usage: Get Affine Matrix
//   mat = yscale(y, [cp=]);
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
//
// Example: As Module
//   yscale(3) sphere(r=10);
//
// Example(2D): Scaling Points
//   path = circle(d=50,$fn=12);
//   #stroke(path,closed=true);
//   stroke(yscale(2,p=path),closed=true);
module yscale(y=1, p, cp=0) {
    req_children($children);      
    assert(is_undef(p), "Module form `yscale()` does not accept p= argument.");
    cp = is_num(cp)? [0,cp,0] : cp;
    if (cp == [0,0,0]) {
        scale([1,y,1]) children();
    } else {
        translate(cp) scale([1,y,1]) translate(-cp) children();
    }
}

function yscale(y=1, p=_NO_ARG, cp=0) =
    assert(is_finite(y))
    assert(p==_NO_ARG || is_list(p))
    assert(is_finite(cp) || is_vector(cp))
    let( cp = is_num(cp)? [0,cp,0] : cp )
    scale([1,y,1], cp=cp, p=p);


// Function&Module: zscale()
//
// Synopsis: Scales children along the Z axis.
// SynTags: Trans, Path, VNF, Mat
// Topics: Affine, Matrices, Transforms, Scaling
// See Also: scale(), xscale(), yscale()
//
// Usage: As Module
//   zscale(z, [cp=]) CHILDREN;
// Usage: Scale Points
//   scaled = zscale(z, p, [cp=]);
// Usage: Get Affine Matrix
//   mat = zscale(z, [cp=]);
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
//   #stroke(path,closed=true);
//   stroke(zscale(2,path),closed=true);
module zscale(z=1, p, cp=0) {
    req_children($children);      
    assert(is_undef(p), "Module form `zscale()` does not accept p= argument.");
    cp = is_num(cp)? [0,0,cp] : cp;
    if (cp == [0,0,0]) {
        scale([1,1,z]) children();
    } else {
        translate(cp) scale([1,1,z]) translate(-cp) children();
    }
}

function zscale(z=1, p=_NO_ARG, cp=0) =
    assert(is_finite(z))
    assert(is_undef(p) || is_list(p))
    assert(is_finite(cp) || is_vector(cp))
    let( cp = is_num(cp)? [0,0,cp] : cp )
    scale([1,1,z], cp=cp, p=p);


//////////////////////////////////////////////////////////////////////
// Section: Reflection (Mirroring)
//////////////////////////////////////////////////////////////////////

// Function&Module: mirror()
//
// Synopsis: Reflects children across an arbitrary plane.
// SynTags: Trans, Path, VNF, Mat, Ext
// Topics: Affine, Matrices, Transforms, Reflection, Mirroring
// See Also: xflip(), yflip(), zflip()
//
// Usage: As Module
//   mirror(v) CHILDREN;
// Usage: As Function
//   pt = mirror(v, p);
// Usage: Get Reflection/Mirror Matrix
//   mat = mirror(v);
//
// Description:
//   Mirrors/reflects across the plane or line whose normal vector is given in `v`.
//   * Called as the built-in module, mirrors all children across the line/plane.
//   * Called as a function with a point in the `p` argument, returns the point mirrored across the line/plane.
//   * Called as a function with a list of points in the `p` argument, returns the list of points, with each one mirrored across the line/plane.
//   * Called as a function with a [bezier patch](beziers.scad) in the `p` argument, returns the mirrored patch.
//   * Called as a function with a [VNF structure](vnf.scad) in the `p` argument, returns the mirrored VNF.
//   * Called as a function without a `p` argument, and with a 2D normal vector `v`, returns the affine2d 3x3 mirror matrix.
//   * Called as a function without a `p` argument, and with a 3D normal vector `v`, returns the affine3d 4x4 mirror matrix.
//
// Arguments:
//   v = The normal vector of the line or plane to mirror across.
//   p = If called as a function, the point or list of points to scale.
//
// Example:
//   n = [1,0,0];
//   module obj() right(20) rotate([0,15,-15]) cube([40,30,20]);
//   obj();
//   mirror(n) obj();
//   rot(a=atan2(n.y,n.x),from=UP,to=n) {
//       color("red") anchor_arrow(s=20, flag=false);
//       color("#7777") cube([75,75,0.1], center=true);
//   }
//
// Example:
//   n = [1,1,0];
//   module obj() right(20) rotate([0,15,-15]) cube([40,30,20]);
//   obj();
//   mirror(n) obj();
//   rot(a=atan2(n.y,n.x),from=UP,to=n) {
//       color("red") anchor_arrow(s=20, flag=false);
//       color("#7777") cube([75,75,0.1], center=true);
//   }
//
// Example:
//   n = [1,1,1];
//   module obj() right(20) rotate([0,15,-15]) cube([40,30,20]);
//   obj();
//   mirror(n) obj();
//   rot(a=atan2(n.y,n.x),from=UP,to=n) {
//       color("red") anchor_arrow(s=20, flag=false);
//       color("#7777") cube([75,75,0.1], center=true);
//   }
//
// Example(2D):
//   n = [0,1];
//   path = rot(30, p=square([50,30]));
//   color("gray") rot(from=[0,1],to=n) stroke([[-60,0],[60,0]]);
//   color("red") stroke([[0,0],10*n],endcap2="arrow2");
//   #stroke(path,closed=true);
//   stroke(mirror(n, p=path),closed=true);
//
// Example(2D):
//   n = [1,1];
//   path = rot(30, p=square([50,30]));
//   color("gray") rot(from=[0,1],to=n) stroke([[-60,0],[60,0]]);
//   color("red") stroke([[0,0],10*n],endcap2="arrow2");
//   #stroke(path,closed=true);
//   stroke(mirror(n, p=path),closed=true);
//
function mirror(v, p=_NO_ARG) =
    assert(is_vector(v))
    assert(p==_NO_ARG || is_list(p),"Invalid pointlist")
    let(m = affine3d_mirror(v))
    p==_NO_ARG? m : apply(m,p);


// Function&Module: xflip()
//
// Synopsis: Reflects children across the YZ plane.
// SynTags: Trans, Path, VNF, Mat
// Topics: Affine, Matrices, Transforms, Reflection, Mirroring
// See Also: mirror(), yflip(), zflip()
//
// Usage: As Module
//   xflip([x=]) CHILDREN;
// Usage: As Function
//   pt = xflip(p, [x]);
// Usage: Get Affine Matrix
//   mat = xflip([x=]);
//
// Description:
//   Mirrors/reflects across the origin [0,0,0], along the X axis.  If `x` is given, reflects across [x,0,0] instead.
//   * Called as the built-in module, mirrors all children across the line/plane.
//   * Called as a function with a point in the `p` argument, returns the point mirrored across the line/plane.
//   * Called as a function with a list of points in the `p` argument, returns the list of points, with each one mirrored across the line/plane.
//   * Called as a function with a [bezier patch](beziers.scad) in the `p` argument, returns the mirrored patch.
//   * Called as a function with a [VNF structure](vnf.scad) in the `p` argument, returns the mirrored VNF.
//   * Called as a function without a `p` argument, returns the affine3d 4x4 mirror matrix.
//
// Arguments:
//   p = If given, the point, path, patch, or VNF to mirror.  Function use only.
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
module xflip(p, x=0) {
    req_children($children);        
    assert(is_undef(p), "Module form `zflip()` does not accept p= argument.");
    translate([x,0,0])
        mirror([1,0,0])
            translate([-x,0,0]) children();
}

function xflip(p=_NO_ARG, x=0) =
    assert(is_finite(x))
    assert(p==_NO_ARG || is_list(p),"Invalid point list")
    let( v = RIGHT )
    x == 0 ? mirror(v,p=p) :
    let(
        cp = x * v,
        m = move(cp) * mirror(v) * move(-cp)
    )
    p==_NO_ARG? m : apply(m, p);


// Function&Module: yflip()
//
// Synopsis: Reflects children across the XZ plane.
// SynTags: Trans, Path, VNF, Mat
// Topics: Affine, Matrices, Transforms, Reflection, Mirroring
// See Also: mirror(), xflip(), zflip()
//
// Usage: As Module
//   yflip([y=]) CHILDREN;
// Usage: As Function
//   pt = yflip(p, [y]);
// Usage: Get Affine Matrix
//   mat = yflip([y=]);
//
// Description:
//   Mirrors/reflects across the origin [0,0,0], along the Y axis.  If `y` is given, reflects across [0,y,0] instead.
//   * Called as the built-in module, mirrors all children across the line/plane.
//   * Called as a function with a point in the `p` argument, returns the point mirrored across the line/plane.
//   * Called as a function with a list of points in the `p` argument, returns the list of points, with each one mirrored across the line/plane.
//   * Called as a function with a [bezier patch](beziers.scad) in the `p` argument, returns the mirrored patch.
//   * Called as a function with a [VNF structure](vnf.scad) in the `p` argument, returns the mirrored VNF.
//   * Called as a function without a `p` argument, returns the affine3d 4x4 mirror matrix.
//
// Arguments:
//   p = If given, the point, path, patch, or VNF to mirror.  Function use only.
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
module yflip(p, y=0) {
    req_children($children);          
    assert(is_undef(p), "Module form `yflip()` does not accept p= argument.");
    translate([0,y,0])
        mirror([0,1,0])
            translate([0,-y,0]) children();
}

function yflip(p=_NO_ARG, y=0) =
    assert(is_finite(y))
    assert(p==_NO_ARG || is_list(p),"Invalid point list")
    let( v = BACK )
    y == 0 ? mirror(v,p=p) :
    let(
        cp = y * v,
        m = move(cp) * mirror(v) * move(-cp)
    )
    p==_NO_ARG? m : apply(m, p);


// Function&Module: zflip()
//
// Synopsis: Reflects children across the XY plane.
// SynTags: Trans, Path, VNF, Mat
// Topics: Affine, Matrices, Transforms, Reflection, Mirroring
// See Also: mirror(), xflip(), yflip()
//
// Usage: As Module
//   zflip([z=]) CHILDREN;
// Usage: As Function
//   pt = zflip(p, [z]);
// Usage: Get Affine Matrix
//   mat = zflip([z=]);
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
    req_children($children);          
    assert(is_undef(p), "Module form `zflip()` does not accept p= argument.");
    translate([0,0,z])
        mirror([0,0,1])
            translate([0,0,-z]) children();
}

function zflip(p=_NO_ARG, z=0) =
    assert(is_finite(z))
    assert(p==_NO_ARG || is_list(p),"Invalid point list")
    z==0? mirror([0,0,1],p=p) :
    let(m = up(z) * mirror(UP) * down(z))
    p==_NO_ARG? m : apply(m, p);


//////////////////////////////////////////////////////////////////////
// Section: Other Transformations
//////////////////////////////////////////////////////////////////////

// Function&Module: frame_map()
//
// Synopsis: Rotates and possibly skews children from one frame of reference to another.
// SynTags: Trans, Path, VNF, Mat
// Topics: Affine, Matrices, Transforms, Rotation
// See Also: rot(), xrot(), yrot(), zrot()
//
// Usage: As module
//   frame_map(v1, v2, v3, [reverse=]) CHILDREN;
// Usage: As function to remap points
//   transformed = frame_map(v1, v2, v3, p=points, [reverse=]);
// Usage: As function to return a transformation matrix:
//   map = frame_map(v1, v2, v3, [reverse=]);
//   map = frame_map(x=VECTOR1, y=VECTOR2, [reverse=]);
//   map = frame_map(x=VECTOR1, z=VECTOR2, [reverse=]);
//   map = frame_map(y=VECTOR1, z=VECTOR2, [reverse=]);
//
// Description:
//   Maps one coordinate frame to another.  You must specify two or
//   three of `x`, `y`, and `z`.  The specified axes are mapped to the vectors you supplied, so if you
//   specify x=[1,1] then the x axis will be mapped to the line y=x.  If you
//   give two inputs, the third vector is mapped to the appropriate normal to maintain a right hand
//   coordinate system.  If the vectors you give are orthogonal the result will be a rotation and the
//   `reverse` parameter will supply the inverse map, which enables you to map two arbitrary
//   coordinate systems to each other by using the canonical coordinate system as an intermediary.
//   You cannot use the `reverse` option with non-orthogonal inputs.  Note that only the direction
//   of the specified vectors matters: the transformation will not apply scaling, though it can
//   skew if your provide non-orthogonal axes.
//
// Arguments:
//   x = Destination 3D vector for x axis.
//   y = Destination 3D vector for y axis.
//   z = Destination 3D vector for z axis.
//   p = If given, the point, path, patch, or VNF to operate on.  Function use only.
//   reverse = reverse direction of the map for orthogonal inputs.  Default: false
//
// Example:  Remap axes after linear extrusion
//   frame_map(x=[0,1,0], y=[0,0,1]) linear_extrude(height=10) square(3);
//
// Example: This map is just a rotation around the z axis
//   mat = frame_map(x=[1,1,0], y=[-1,1,0]);
//   multmatrix(mat) frame_ref();
//
// Example:  This map is not a rotation because x and y aren't orthogonal
//   frame_map(x=[1,0,0], y=[1,1,0]) cube(10);
//
// Example:  This sends [1,1,0] to [0,1,1] and [-1,1,0] to [0,-1,1].  (Original directions shown in light shade, final directions shown dark.)
//   mat = frame_map(x=[0,1,1], y=[0,-1,1]) * frame_map(x=[1,1,0], y=[-1,1,0],reverse=true);
//   color("purple",alpha=.2) stroke([[0,0,0],10*[1,1,0]]);
//   color("green",alpha=.2)  stroke([[0,0,0],10*[-1,1,0]]);
//   multmatrix(mat) {
//      color("purple") stroke([[0,0,0],10*[1,1,0]]);
//      color("green") stroke([[0,0,0],10*[-1,1,0]]);
//   }
//
function frame_map(x,y,z, p=_NO_ARG, reverse=false) =
    p != _NO_ARG
    ? apply(frame_map(x,y,z,reverse=reverse), p)
    :
    assert(num_defined([x,y,z])>=2, "Must define at least two inputs")
    let(
        xvalid = is_undef(x) || (is_vector(x) && len(x)==3),
        yvalid = is_undef(y) || (is_vector(y) && len(y)==3),
        zvalid = is_undef(z) || (is_vector(z) && len(z)==3)
    )
    assert(xvalid,"Input x must be a length 3 vector")
    assert(yvalid,"Input y must be a length 3 vector")
    assert(zvalid,"Input z must be a length 3 vector")
    let(
        x = is_undef(x)? undef : unit(x,RIGHT),
        y = is_undef(y)? undef : unit(y,BACK),
        z = is_undef(z)? undef : unit(z,UP),
        map = is_undef(x)? [cross(y,z), y, z] :
            is_undef(y)? [x, cross(z,x), z] :
            is_undef(z)? [x, y, cross(x,y)] :
            [x, y, z]
    )
    reverse? (
        let(
            ocheck = (
                approx(map[0]*map[1],0) &&
                approx(map[0]*map[2],0) &&
                approx(map[1]*map[2],0)
            )
        )
        assert(ocheck, "Inputs must be orthogonal when reverse==true")
        [for (r=map) [for (c=r) c, 0], [0,0,0,1]]
    ) : [for (r=transpose(map)) [for (c=r) c, 0], [0,0,0,1]];


module frame_map(x,y,z,p,reverse=false)
{
   req_children($children);        
   assert(is_undef(p), "Module form `frame_map()` does not accept p= argument.");
   multmatrix(frame_map(x,y,z,reverse=reverse))
       children();
}


// Function&Module: skew()
//
// Synopsis: Skews (or shears) children along various axes.
// SynTags: Trans, Path, VNF, Mat
// Topics: Affine, Matrices, Transforms, Skewing, Shearing
// See Also: move(), rot(), scale()
//
// Usage: As Module
//   skew([sxy=]|[axy=], [sxz=]|[axz=], [syx=]|[ayx=], [syz=]|[ayz=], [szx=]|[azx=], [szy=]|[azy=]) CHILDREN;
// Usage: As Function
//   pts = skew(p, [sxy=]|[axy=], [sxz=]|[axz=], [syx=]|[ayx=], [syz=]|[ayz=], [szx=]|[azx=], [szy=]|[azy=]);
// Usage: Get Affine Matrix
//   mat = skew([sxy=]|[axy=], [sxz=]|[axz=], [syx=]|[ayx=], [syz=]|[ayz=], [szx=]|[azx=], [szy=]|[azy=]);
//
// Description:
//   Skews geometry by the given skew factors.  Skewing is also referred to as shearing.  
//   * Called as the built-in module, skews all children.
//   * Called as a function with a point in the `p` argument, returns the skewed point.
//   * Called as a function with a list of points in the `p` argument, returns the list of skewed points.
//   * Called as a function with a [bezier patch](beziers.scad) in the `p` argument, returns the skewed patch.
//   * Called as a function with a [VNF structure](vnf.scad) in the `p` argument, returns the skewed VNF.
//   * Called as a function without a `p` argument, returns the affine3d 4x4 skew matrix.
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
//   axy = Angle to skew along the X axis as you get farther from the Y axis.
//   axz = Angle to skew along the X axis as you get farther from the Z axis.
//   ayx = Angle to skew along the Y axis as you get farther from the X axis.
//   ayz = Angle to skew along the Y axis as you get farther from the Z axis.
//   azx = Angle to skew along the Z axis as you get farther from the X axis.
//   azy = Angle to skew along the Z axis as you get farther from the Y axis.
// Example(2D): Skew along the X axis in 2D.
//   skew(sxy=0.5) square(40, center=true);
// Example(2D): Skew along the X axis by 30º in 2D.
//   skew(axy=30) square(40, center=true);
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
// Example(3D,VPR=[71.80,0.00,338.10],VPD=155.56,VPT=[9.03,9.43,-7.03]): Skew by 30º along the Z axis.  
//   skew(azx=30) cube([40,40,5],center=true);
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
//   stroke(pts,closed=true,dots=true,dots_color="blue");
module skew(p, sxy, sxz, syx, syz, szx, szy, axy, axz, ayx, ayz, azx, azy)
{
    req_children($children);          
    assert(is_undef(p), "Module form `skew()` does not accept p= argument.");
    mat = skew(
        sxy=sxy, sxz=sxz, syx=syx, syz=syz, szx=szx, szy=szy,
        axy=axy, axz=axz, ayx=ayx, ayz=ayz, azx=azx, azy=azy
    );
    multmatrix(mat) children();
}

function skew(p=_NO_ARG, sxy, sxz, syx, syz, szx, szy, axy, axz, ayx, ayz, azx, azy) =
    assert(num_defined([sxy,axy]) < 2)
    assert(num_defined([sxz,axz]) < 2)
    assert(num_defined([syx,ayx]) < 2)
    assert(num_defined([syz,ayz]) < 2)
    assert(num_defined([szx,azx]) < 2)
    assert(num_defined([szy,azy]) < 2)
    assert(sxy==undef || is_finite(sxy))
    assert(sxz==undef || is_finite(sxz))
    assert(syx==undef || is_finite(syx))
    assert(syz==undef || is_finite(syz))
    assert(szx==undef || is_finite(szx))
    assert(szy==undef || is_finite(szy))
    assert(axy==undef || is_finite(axy))
    assert(axz==undef || is_finite(axz))
    assert(ayx==undef || is_finite(ayx))
    assert(ayz==undef || is_finite(ayz))
    assert(azx==undef || is_finite(azx))
    assert(azy==undef || is_finite(azy))
    let(
        sxy = is_num(sxy)? sxy : is_num(axy)? tan(axy) : 0,
        sxz = is_num(sxz)? sxz : is_num(axz)? tan(axz) : 0,
        syx = is_num(syx)? syx : is_num(ayx)? tan(ayx) : 0,
        syz = is_num(syz)? syz : is_num(ayz)? tan(ayz) : 0,
        szx = is_num(szx)? szx : is_num(azx)? tan(azx) : 0,
        szy = is_num(szy)? szy : is_num(azy)? tan(azy) : 0,
        m = affine3d_skew(sxy=sxy, sxz=sxz, syx=syx, syz=syz, szx=szx, szy=szy)
    )
    p==_NO_ARG? m : apply(m, p);


// Section: Applying transformation matrices to data

/// Internal Function: is_2d_transform()
/// Usage:
///   bool = is_2d_transform(t);
/// Topics: Affine, Matrices, Transforms, Type Checking
/// See Also: is_affine(), is_matrix()
/// Description:
///   Checks if the input is a 3D transform that does not act on the z coordinate, except possibly
///   for a simple scaling of z.  Note that an input which is only a zscale returns false.
/// Arguments:
///   t = The transformation matrix to check.
/// Example:
///   b = is_2d_transform(zrot(45));  // Returns: true
///   b = is_2d_transform(yrot(45));  // Returns: false
///   b = is_2d_transform(xrot(45));  // Returns: false
///   b = is_2d_transform(move([10,20,0]));  // Returns: true
///   b = is_2d_transform(move([10,20,30]));  // Returns: false
///   b = is_2d_transform(scale([2,3,4]));  // Returns: true
function is_2d_transform(t) =    // z-parameters are zero, except we allow t[2][2]!=1 so scale() works
  t[2][0]==0 && t[2][1]==0 && t[2][3]==0 && t[0][2] == 0 && t[1][2]==0 &&
  (t[2][2]==1 || !(t[0][0]==1 && t[0][1]==0 && t[1][0]==0 && t[1][1]==1));   // But rule out zscale()



// Function: apply()
//
// Synopsis: Applies a transformation matrix to a point, list of points, array of points, or a VNF.
// SynTags: Path, VNF, Mat
// Topics: Affine, Matrices, Transforms
// See Also: move(), rot(), scale(), skew()
//
// Usage:
//   pts = apply(transform, points);
//
// Description:
//   Applies the specified transformation matrix `transform` to a point, point list, bezier patch or VNF.
//   When `points` contains 2D or 3D points the transform matrix may be a 4x4 affine matrix or a 3x4 
//   matrix&mdash;the 4x4 matrix with its final row removed.  When the data is 2D the matrix must not operate on the Z axis,
//   except possibly by scaling it.  When points contains 2D data you can also supply the transform as
//   a 3x3 affine transformation matrix or the corresponding 2x3 matrix with the last row deleted.
//   .
//   Any other combination of matrices will produce an error, including acting with a 2D matrix (3x3) on 3D data.
//   The output of apply is always the same dimension as the input&mdash;projections are not supported.
//   .
//   Note that a matrix with a negative determinant such as any mirror reflection flips the orientation of faces.
//   If the transform matrix is square then apply() checks the determinant and if it is negative, apply() reverses the face order so that
//   the transformed VNF has faces with the same winding direction as the original VNF.  This adjustment applies
//   only to VNFs, not to beziers or point lists.  
//
// Arguments:
//   transform = The 2D (3x3 or 2x3) or 3D (4x4 or 3x4) transformation matrix to apply.
//   points = The point, point list, bezier patch, or VNF to apply the transformation to.
//
// Example(3D):
//   path1 = path3d(circle(r=40));
//   tmat = xrot(45);
//   path2 = apply(tmat, path1);
//   #stroke(path1,closed=true);
//   stroke(path2,closed=true);
//
// Example(2D):
//   path1 = circle(r=40);
//   tmat = translate([10,5]);
//   path2 = apply(tmat, path1);
//   #stroke(path1,closed=true);
//   stroke(path2,closed=true);
//
// Example(2D):
//   path1 = circle(r=40);
//   tmat = rot(30) * back(15) * scale([1.5,0.5,1]);
//   path2 = apply(tmat, path1);
//   #stroke(path1,closed=true);
//   stroke(path2,closed=true);
//
function apply(transform,points) =
    points==[] ? []
  : is_vector(points) ? _apply(transform, [points])[0]    // point
  : is_vnf(points) ?                                      // vnf
        let(
            newvnf = [_apply(transform, points[0]), points[1]],
            reverse = (len(transform)==len(transform[0])) && determinant(transform)<0
        )
        reverse ? vnf_reverse_faces(newvnf) : newvnf
  : is_list(points) && is_list(points[0]) && is_vector(points[0][0])    // bezier patch
        ? [for (x=points) _apply(transform,x)]
  : _apply(transform,points);




function _apply(transform,points) =
    assert(is_matrix(transform),"Invalid transformation matrix")
    assert(is_matrix(points),"Invalid points list")
    let(
        tdim = len(transform[0])-1,
        datadim = len(points[0])
    )
    assert(len(transform)==tdim || len(transform)-1==tdim, "transform matrix height not compatible with width")
    assert(datadim==2 || datadim==3,"Data must be 2D or 3D")
    let(
        scale = len(transform)==tdim ? 1 : transform[tdim][tdim],
        matrix = [for(i=[0:1:tdim]) [for(j=[0:1:datadim-1]) transform[j][i]]] / scale
    )
    tdim==datadim ? [for(p=points) concat(p,1)] * matrix
  : tdim == 3 && datadim == 2 ?
            assert(is_2d_transform(transform), str("Transforms is 3D and acts on Z, but points are 2D"))
            [for(p=points) concat(p,[0,1])]*matrix
  : assert(false, str("Unsupported combination: ",len(transform),"x",len(transform[0])," transform (dimension ",tdim,
                          "), data of dimension ",datadim));


// Section: Saving and restoring 


$transform = IDENT;

module translate(v)
{
  $transform = $transform * (is_vector(v) && (len(v)==2 || len(v)==3) ? affine3d_translate(point3d(v)) : IDENT);
  _translate(v) children();                   
}  


module rotate(a,v)
{
  rot3 = is_finite(a) && is_vector(v) && (len(v)==2 || len(v)==3) ? affine3d_rot_by_axis(v,a)
       : is_finite(a) ? affine3d_zrot(a)
       : same_shape(a,[0]) ? affine3d_xrot(a.x)
       : same_shape(a,[0,0]) ? affine3d_yrot(a.y)*affine3d_xrot(a.x)
       : same_shape(a,[0,0,0])? affine3d_zrot(a.z)*affine3d_yrot(a.y)*affine3d_xrot(a.x)
       : IDENT;
  $transform = $transform * rot3;
  _rotate(a=a,v=v) children();
}  

module scale(v)
{
  s3 = is_finite(v) ? affine3d_scale([v,v,v])
     : is_vector(v) ? affine3d_scale(v)
     : IDENT;
  $transform = $transform * s3;
  _scale(v) children();
}


module multmatrix(m)
{
   m3 = !is_matrix(m) ? IDENT
      : len(m)>0 && len(m)<=4 && len(m[0])>0 && len(m[0])<=4 ? submatrix_set(IDENT, m)
      : IDENT;
   $transform = $transform * m3;
   _multmatrix(m) children();
}


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
