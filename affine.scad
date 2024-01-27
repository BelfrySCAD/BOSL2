//////////////////////////////////////////////////////////////////////
// LibFile: affine.scad
//   Matrix math and affine transformation matrices.
// Includes:
//   include <BOSL2/std.scad>
//////////////////////////////////////////////////////////////////////


// Section: Affine2d 3x3 Transformation Matrices


// Function: affine2d_identity()
// Synopsis: Returns a 2D (3x3) identity transformation matrix.
// SynTags: Mat
// Topics: Affine, Matrices, Transforms
// See Also: affine3d_identity(), ident(), IDENT
// Usage:
//   mat = affine2d_identify();
// Description:
//   Create a 3x3 affine2d identity matrix.
// Example:
//   mat = affine2d_identity();
//   // Returns:
//   //   [
//   //     [1, 0, 0],
//   //     [0, 1, 0],
//   //     [0, 0, 1]
//   //   ]
function affine2d_identity() = ident(3);


// Function: affine2d_translate()
// Synopsis: Returns a 2D (3x3) translation transformation matrix.
// SynTags: Mat
// Topics: Affine, Matrices, Transforms, Translation
// See Also: affine3d_translate(), move(), translate(), left(), right(), fwd(), back(), down(), up()
// Usage:
//   mat = affine2d_translate(v);
// Description:
//   Returns the 3x3 affine2d matrix to perform a 2D translation.
// Arguments:
//   v = 2D Offset to translate by.  [X,Y]
// Example:
//   mat = affine2d_translate([30,40]);
//   // Returns:
//   //   [
//   //     [1, 0, 30],
//   //     [0, 1, 40],
//   //     [0, 0,  1]
//   //   ]
function affine2d_translate(v=[0,0]) =
    assert(is_vector(v),2)
    [
        [1, 0, v.x],
        [0, 1, v.y],
        [0 ,0,   1]
    ];


// Function: affine2d_scale()
// Synopsis: Returns a 2D (3x3) scaling transformation matrix.
// SynTags: Mat
// Topics: Affine, Matrices, Transforms, Scaling
// See Also: affine3d_scale(), scale(), xscale(), yscale(), zscale(), affine3d_scale()
// Usage:
//   mat = affine2d_scale(v);
// Description:
//   Returns the 3x3 affine2d matrix to perform a 2D scaling transformation.
// Arguments:
//   v = 2D vector of scaling factors.  [X,Y]
// Example:
//   mat = affine2d_scale([3,4]);
//   // Returns:
//   //   [
//   //     [3, 0, 0],
//   //     [0, 4, 0],
//   //     [0, 0, 1]
//   //   ]
function affine2d_scale(v=[1,1]) =
    assert(is_vector(v,2))
    [
        [v.x,   0, 0],
        [  0, v.y, 0],
        [  0,   0, 1]
    ];


// Function: affine2d_zrot()
// Synopsis: Returns a 2D (3x3) rotation transformation matrix.
// SynTags: Mat
// Topics: Affine, Matrices, Transforms, Rotation
// See Also: rot(), xrot(), yrot(), zrot(), affine3d_zrot()
// Usage:
//   mat = affine2d_zrot(ang);
// Description:
//   Returns the 3x3 affine2d matrix to perform a rotation of a 2D vector around the Z axis.
// Arguments:
//   ang = Number of degrees to rotate.
// Example:
//   mat = affine2d_zrot(90);
//   // Returns:
//   //   [
//   //     [0,-1, 0],
//   //     [1, 0, 0],
//   //     [0, 0, 1]
//   //   ]
function affine2d_zrot(ang=0) =
    assert(is_finite(ang))
    [
        [cos(ang), -sin(ang), 0],
        [sin(ang),  cos(ang), 0],
        [       0,         0, 1]
    ];


// Function: affine2d_mirror()
// Synopsis: Returns a 2D (3x3) reflection transformation matrix.
// SynTags: Mat
// Topics: Affine, Matrices, Transforms, Reflection, Mirroring
// See Also: mirror(), xflip(), yflip(), zflip(), affine3d_mirror()
// Usage:
//   mat = affine2d_mirror(v);
// Description:
//   Returns the 3x3 affine2d matrix to perform a reflection of a 2D vector across the line given by its normal vector.
// Arguments:
//   v = The normal vector of the line to reflect across.
// Example:
//   mat = affine2d_mirror([0,1]);
//   // Returns:
//   //   [
//   //     [ 1, 0, 0],
//   //     [ 0,-1, 0],
//   //     [ 0, 0, 1]
//   //   ]
// Example:
//   mat = affine2d_mirror([1,0]);
//   // Returns:
//   //   [
//   //     [-1, 0, 0],
//   //     [ 0, 1, 0],
//   //     [ 0, 0, 1]
//   //   ]
// Example:
//   mat = affine2d_mirror([1,1]);
//   // Returns approximately:
//   //   [
//   //     [ 0,-1, 0],
//   //     [-1, 0, 0],
//   //     [ 0, 0, 1]
//   //   ]
function affine2d_mirror(v) =
    assert(is_vector(v,2))
    let(v=unit(point2d(v)), a=v.x, b=v.y)
    [
        [1-2*a*a, 0-2*a*b, 0],
        [0-2*a*b, 1-2*b*b, 0],
        [      0,       0, 1]
    ];


// Function: affine2d_skew()
// Synopsis: Returns a 2D (3x3) skewing transformation matrix.
// SynTags: Mat
// Topics: Affine, Matrices, Transforms, Skewing
// See Also: skew(), affine3d_skew()
// Usage:
//   mat = affine2d_skew(xa);
//   mat = affine2d_skew(ya=);
//   mat = affine2d_skew(xa, ya);
// Description:
//   Returns the 3x3 affine2d matrix to skew a 2D vector along the XY plane.
// Arguments:
//   xa = Skew angle, in degrees, in the direction of the X axis. Default: 0
//   ya = Skew angle, in degrees, in the direction of the Y axis. Default: 0
// Example:
//   mat = affine2d_skew(xa=45,ya=-45);
//   // Returns approximately:
//   //   [
//   //     [ 1, 1, 0],
//   //     [-1, 1, 0],
//   //     [ 0, 0, 1]
//   //   ]
function affine2d_skew(xa=0, ya=0) =
    assert(is_finite(xa))
    assert(is_finite(ya))
    [
        [1,       tan(xa), 0],
        [tan(ya), 1,       0],
        [0,       0,       1]
    ];



// Section: Affine3d 4x4 Transformation Matrices


// Function: affine3d_identity()
// Synopsis: Returns a 3D (4x4) identity transformation matrix.
// SynTags: Mat
// Topics: Affine, Matrices, Transforms
// See Also: affine2d_identity(), ident(), IDENT
// Usage:
//   mat = affine3d_identity();
// Description:
//   Create a 4x4 affine3d identity matrix.
// Example:
//   mat = affine2d_identity();
//   // Returns:
//   //   [
//   //     [1, 0, 0, 0],
//   //     [0, 1, 0, 0],
//   //     [0, 0, 1, 0],
//   //     [0, 0, 0, 1]
//   //   ]
function affine3d_identity() = ident(4);


// Function: affine3d_translate()
// Synopsis: Returns a 3D (4x4) translation transformation matrix.
// SynTags: Mat
// Topics: Affine, Matrices, Transforms, Translation
// See Also: move(), translate(), left(), right(), fwd(), back(), down(), up(), affine2d_translate()
// Usage:
//   mat = affine3d_translate(v);
// Description:
//   Returns the 4x4 affine3d matrix to perform a 3D translation.
// Arguments:
//   v = 3D offset to translate by.  [X,Y,Z]
// Example:
//   mat = affine2d_translate([30,40,50]);
//   // Returns:
//   //   [
//   //     [1, 0, 0, 30],
//   //     [0, 1, 0, 40],
//   //     [0, 0, 1, 50]
//   //     [0, 0, 0,  1]
//   //   ]
function affine3d_translate(v=[0,0,0]) =
    assert(is_list(v))
    let( v = [for (i=[0:2]) default(v[i],0)] )
    [
        [1, 0, 0, v.x],
        [0, 1, 0, v.y],
        [0, 0, 1, v.z],
        [0 ,0, 0,   1]
    ];


// Function: affine3d_scale()
// Synopsis: Returns a 3D (4x4) scaling transformation matrix.
// SynTags: Mat
// Topics: Affine, Matrices, Transforms, Scaling
// See Also: scale(), affine2d_scale()
// Usage:
//   mat = affine3d_scale(v);
// Description:
//   Returns the 4x4 affine3d matrix to perform a 3D scaling transformation.
// Arguments:
//   v = 3D vector of scaling factors.  [X,Y,Z]
// Example:
//   mat = affine3d_scale([3,4,5]);
//   // Returns:
//   //   [
//   //     [3, 0, 0, 0],
//   //     [0, 4, 0, 0],
//   //     [0, 0, 5, 0],
//   //     [0, 0, 0, 1]
//   //   ]
function affine3d_scale(v=[1,1,1]) =
    assert(is_list(v))
    let( v = [for (i=[0:2]) default(v[i],1)] )
    [
        [v.x,   0,   0, 0],
        [  0, v.y,   0, 0],
        [  0,   0, v.z, 0],
        [  0,   0,   0, 1]
    ];


// Function: affine3d_xrot()
// Synopsis: Returns a 3D (4x4) X-axis rotation transformation matrix.
// SynTags: Mat
// Topics: Affine, Matrices, Transforms, Rotation
// See Also: rot(), xrot(), yrot(), zrot(), affine2d_zrot()
// Usage:
//   mat = affine3d_xrot(ang);
// Description:
//   Returns the 4x4 affine3d matrix to perform a rotation of a 3D vector around the X axis.
// Arguments:
//   ang = number of degrees to rotate.
// Example:
//   mat = affine3d_xrot(90);
//   // Returns:
//   //   [
//   //     [1, 0, 0, 0],
//   //     [0, 0,-1, 0],
//   //     [0, 1, 0, 0],
//   //     [0, 0, 0, 1]
//   //   ]
function affine3d_xrot(ang=0) =
    assert(is_finite(ang))
    [
        [1,        0,         0,   0],
        [0, cos(ang), -sin(ang),   0],
        [0, sin(ang),  cos(ang),   0],
        [0,        0,         0,   1]
    ];


// Function: affine3d_yrot()
// Synopsis: Returns a 3D (4x4) Y-axis rotation transformation matrix.
// SynTags: Mat
// Topics: Affine, Matrices, Transforms, Rotation
// See Also: rot(), xrot(), yrot(), zrot(), affine2d_zrot()
// Usage:
//   mat = affine3d_yrot(ang);
// Description:
//   Returns the 4x4 affine3d matrix to perform a rotation of a 3D vector around the Y axis.
// Arguments:
//   ang = Number of degrees to rotate.
// Example:
//   mat = affine3d_yrot(90);
//   // Returns:
//   //   [
//   //     [ 0, 0, 1, 0],
//   //     [ 0, 1, 0, 0],
//   //     [-1, 0, 0, 0],
//   //     [ 0, 0, 0, 1]
//   //   ]
function affine3d_yrot(ang=0) =
    assert(is_finite(ang))
    [
        [ cos(ang), 0, sin(ang),   0],
        [        0, 1,        0,   0],
        [-sin(ang), 0, cos(ang),   0],
        [        0, 0,        0,   1]
    ];


// Function: affine3d_zrot()
// Synopsis: Returns a 3D (4x4) Z-axis rotation transformation matrix.
// SynTags: Mat
// Topics: Affine, Matrices, Transforms, Rotation
// See Also: rot(), xrot(), yrot(), zrot(), affine2d_zrot()
// Usage:
//   mat = affine3d_zrot(ang);
// Description:
//   Returns the 4x4 affine3d matrix to perform a rotation of a 3D vector around the Z axis.
// Arguments:
//   ang = number of degrees to rotate.
// Example:
//   mat = affine3d_zrot(90);
//   // Returns:
//   //   [
//   //     [ 0,-1, 0, 0],
//   //     [ 1, 0, 0, 0],
//   //     [ 0, 0, 1, 0],
//   //     [ 0, 0, 0, 1]
//   //   ]
function affine3d_zrot(ang=0) =
    assert(is_finite(ang))
    [
        [cos(ang), -sin(ang), 0, 0],
        [sin(ang),  cos(ang), 0, 0],
        [       0,         0, 1, 0],
        [       0,         0, 0, 1]
    ];


// Function: affine3d_rot_by_axis()
// Synopsis: Returns a 3D (4x4) arbitrary-axis rotation transformation matrix.
// SynTags: Mat
// Topics: Affine, Matrices, Transforms, Rotation
// See Also: rot(), xrot(), yrot(), zrot(), affine2d_zrot()
// Usage:
//   mat = affine3d_rot_by_axis(u, ang);
// Description:
//   Returns the 4x4 affine3d matrix to perform a rotation of a 3D vector around an axis.
// Arguments:
//   u = 3D axis vector to rotate around.
//   ang = number of degrees to rotate.
// Example:
//   mat = affine3d_rot_by_axis([1,1,1], 120);
//   // Returns approx:
//   //   [
//   //     [ 0, 0, 1, 0],
//   //     [ 1, 0, 0, 0],
//   //     [ 0, 1, 0, 0],
//   //     [ 0, 0, 0, 1]
//   //   ]
function affine3d_rot_by_axis(u=UP, ang=0) =
    assert(is_finite(ang))
    assert(is_vector(u,3))
    approx(ang,0)? affine3d_identity() :
    let(
        u = unit(u),
        c = cos(ang),
        c2 = 1-c,
        s = sin(ang)
    ) [
        [u.x*u.x*c2+c    , u.x*u.y*c2-u.z*s, u.x*u.z*c2+u.y*s, 0],
        [u.y*u.x*c2+u.z*s, u.y*u.y*c2+c    , u.y*u.z*c2-u.x*s, 0],
        [u.z*u.x*c2-u.y*s, u.z*u.y*c2+u.x*s, u.z*u.z*c2+c    , 0],
        [               0,                0,                0, 1]
    ];


// Function: affine3d_rot_from_to()
// Synopsis: Returns a 3D (4x4) tilt rotation transformation matrix.
// SynTags: Mat
// Topics: Affine, Matrices, Transforms, Rotation
// See Also: rot(), xrot(), yrot(), zrot(), affine2d_zrot()
// Usage:
//   mat = affine3d_rot_from_to(from, to);
// Description:
//   Returns the 4x4 affine3d matrix to perform a rotation of a 3D vector from one vector direction to another.
// Arguments:
//   from = 3D axis vector to rotate from.
//   to = 3D axis vector to rotate to.
// Example:
//   mat = affine3d_rot_from_to(UP, RIGHT);
//   // Returns:
//   //   [
//   //     [ 0, 0, 1, 0],
//   //     [ 0, 1, 0, 0],
//   //     [-1, 0, 0, 0],
//   //     [ 0, 0, 0, 1]
//   //   ]
function affine3d_rot_from_to(from, to) =
    assert(is_vector(from))
    assert(is_vector(to))
    assert(len(from)==len(to))
    let(
        from = unit(point3d(from)),
        to = unit(point3d(to))
    ) approx(from,to)? affine3d_identity() :
    from.z==0 && to.z==0 ?  affine3d_zrot(v_theta(point2d(to)) - v_theta(point2d(from)))
    :
    let(
        u = vector_axis(from,to),
        ang = vector_angle(from,to),
        c = cos(ang),
        c2 = 1-c,
        s = sin(ang)
    ) [
        [u.x*u.x*c2+c    , u.x*u.y*c2-u.z*s, u.x*u.z*c2+u.y*s, 0],
        [u.y*u.x*c2+u.z*s, u.y*u.y*c2+c    , u.y*u.z*c2-u.x*s, 0],
        [u.z*u.x*c2-u.y*s, u.z*u.y*c2+u.x*s, u.z*u.z*c2+c    , 0],
        [               0,                0,                0, 1]
    ];


// Function: affine3d_mirror()
// Synopsis: Returns a 3D (4x4) reflection transformation matrix.
// SynTags: Mat
// Topics: Affine, Matrices, Transforms, Reflection, Mirroring
// See Also: mirror(), xflip(), yflip(), zflip(), affine2d_mirror()
// Usage:
//   mat = affine3d_mirror(v);
// Description:
//   Returns the 4x4 affine3d matrix to perform a reflection of a 3D vector across the plane given by its normal vector.
// Arguments:
//   v = The normal vector of the plane to reflect across.
// Example:
//   mat = affine3d_mirror([1,0,0]);
//   // Returns:
//   //   [
//   //     [-1, 0, 0, 0],
//   //     [ 0, 1, 0, 0],
//   //     [ 0, 0, 1, 0],
//   //     [ 0, 0, 0, 1]
//   //   ]
// Example:
//   mat = affine3d_mirror([0,1,0]);
//   // Returns:
//   //   [
//   //     [ 1, 0, 0, 0],
//   //     [ 0,-1, 0, 0],
//   //     [ 0, 0, 1, 0],
//   //     [ 0, 0, 0, 1]
//   //   ]
function affine3d_mirror(v) =
    assert(is_vector(v))
    let(
        v=unit(point3d(v)),
        a=v.x, b=v.y, c=v.z
    ) [
        [1-2*a*a,  -2*a*b,  -2*a*c, 0],
        [ -2*b*a, 1-2*b*b,  -2*b*c, 0],
        [ -2*c*a,  -2*c*b, 1-2*c*c, 0],
        [      0,       0,       0, 1]
    ];


// Function: affine3d_skew()
// Synopsis: Returns a 3D (4x4) skewing transformation matrix.
// SynTags: Mat
// Topics: Affine, Matrices, Transforms, Skewing
// See Also: skew(), affine3d_skew_xy(), affine3d_skew_xz(), affine3d_skew_yz(), affine2d_skew()
// Usage:
//   mat = affine3d_skew([sxy=], [sxz=], [syx=], [syz=], [szx=], [szy=]);
// Description:
//   Returns the 4x4 affine3d matrix to perform a skew transformation.
// Arguments:
//   sxy = Skew factor multiplier for skewing along the X axis as you get farther from the Y axis.  Default: 0
//   sxz = Skew factor multiplier for skewing along the X axis as you get farther from the Z axis.  Default: 0
//   syx = Skew factor multiplier for skewing along the Y axis as you get farther from the X axis.  Default: 0
//   syz = Skew factor multiplier for skewing along the Y axis as you get farther from the Z axis.  Default: 0
//   szx = Skew factor multiplier for skewing along the Z axis as you get farther from the X axis.  Default: 0
//   szy = Skew factor multiplier for skewing along the Z axis as you get farther from the Y axis.  Default: 0
// Example:
//   mat = affine3d_skew(sxy=2,szx=3);
//   // Returns:
//   //   [
//   //     [ 1, 2, 0, 0],
//   //     [ 0, 1, 0, 0],
//   //     [ 0, 0, 1, 0],
//   //     [ 3, 0, 0, 1]
//   //   ]
function affine3d_skew(sxy=0, sxz=0, syx=0, syz=0, szx=0, szy=0) = [
    [  1, sxy, sxz, 0],
    [syx,   1, syz, 0],
    [szx, szy,   1, 0],
    [  0,   0,   0, 1]
];


// Function: affine3d_skew_xy()
// Synopsis: Returns a 3D (4x4) XY-plane skewing transformation matrix.
// SynTags: Mat
// Topics: Affine, Matrices, Transforms, Skewing
// See Also: skew(), affine3d_skew(), affine3d_skew_xz(), affine3d_skew_yz(), affine2d_skew()
// Usage:
//   mat = affine3d_skew_xy(xa);
//   mat = affine3d_skew_xy(ya=);
//   mat = affine3d_skew_xy(xa, ya);
// Description:
//   Returns the 4x4 affine3d matrix to perform a skew transformation along the XY plane.
// Arguments:
//   xa = Skew angle, in degrees, in the direction of the X axis.  Default: 0
//   ya = Skew angle, in degrees, in the direction of the Y axis.  Default: 0
// Example:
//   mat = affine3d_skew_xy(xa=45,ya=-45);
//   // Returns:
//   //   [
//   //     [ 1, 0, 1, 0],
//   //     [ 0, 1,-1, 0],
//   //     [ 0, 0, 1, 0],
//   //     [ 0, 0, 0, 1]
//   //   ]
function affine3d_skew_xy(xa=0, ya=0) =
    assert(is_finite(xa))
    assert(is_finite(ya))
    [
        [      1, tan(xa), 0, 0],
        [tan(ya),       1, 0, 0],
        [      0,       0, 1, 0],
        [      0,       0, 0, 1]
    ];


// Function: affine3d_skew_xz()
// Synopsis: Returns a 3D (4x4) XZ-plane skewing transformation matrix.
// SynTags: Mat
// Topics: Affine, Matrices, Transforms, Skewing
// See Also: skew(), affine3d_skew(), affine3d_skew_xy(), affine3d_skew_yz(), affine2d_skew()
// Usage:
//   mat = affine3d_skew_xz(xa);
//   mat = affine3d_skew_xz(za=);
//   mat = affine3d_skew_xz(xa, za);
// Description:
//   Returns the 4x4 affine3d matrix to perform a skew transformation along the XZ plane.
// Arguments:
//   xa = Skew angle, in degrees, in the direction of the X axis.  Default: 0
//   za = Skew angle, in degrees, in the direction of the Z axis.  Default: 0
// Example:
//   mat = affine3d_skew_xz(xa=45,za=-45);
//   // Returns:
//   //   [
//   //     [ 1, 1, 0, 0],
//   //     [ 0, 1, 0, 0],
//   //     [ 0,-1, 1, 0],
//   //     [ 0, 0, 0, 1]
//   //   ]
function affine3d_skew_xz(xa=0, za=0) =
    assert(is_finite(xa))
    assert(is_finite(za))
    [
        [      1, 0, tan(xa), 0],
        [      0, 1,       0, 0],
        [tan(za), 0,       1, 0],
        [      0, 0,       0, 1]
    ];


// Function: affine3d_skew_yz()
// Synopsis: Returns a 3D (4x4) YZ-plane skewing transformation matrix.
// SynTags: Mat
// Topics: Affine, Matrices, Transforms, Skewing
// See Also: skew(), affine3d_skew(), affine3d_skew_xy(), affine3d_skew_xz(), affine2d_skew()
// Usage:
//   mat = affine3d_skew_yz(ya);
//   mat = affine3d_skew_yz(za=);
//   mat = affine3d_skew_yz(ya, za);
// Description:
//   Returns the 4x4 affine3d matrix to perform a skew transformation along the YZ plane.
// Arguments:
//   ya = Skew angle, in degrees, in the direction of the Y axis.  Default: 0
//   za = Skew angle, in degrees, in the direction of the Z axis.  Default: 0
// Example:
//   mat = affine3d_skew_yz(ya=45,za=-45);
//   // Returns:
//   //   [
//   //     [ 1, 0, 0, 0],
//   //     [ 1, 1, 0, 0],
//   //     [-1, 0, 1, 0],
//   //     [ 0, 0, 0, 1]
//   //   ]
function affine3d_skew_yz(ya=0, za=0) =
    assert(is_finite(ya))
    assert(is_finite(za))
    [
        [1,       0,       0, 0],
        [0,       1, tan(ya), 0],
        [0, tan(za),       1, 0],
        [0,       0,       0, 1]
    ];



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
