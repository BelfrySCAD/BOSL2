//////////////////////////////////////////////////////////////////////
// LibFile: affine.scad
//   Matrix math and affine transformation matrices.
// Includes:
//   include <BOSL2/std.scad>
//////////////////////////////////////////////////////////////////////


// Section: Matrix Manipulation

// Function: ident()
// Usage:
//   mat = ident(n);
// Description: Create an `n` by `n` identity matrix.
// Arguments:
//   n = The size of the identity matrix square, `n` by `n`.
function ident(n) = [for (i = [0:1:n-1]) [for (j = [0:1:n-1]) (i==j)?1:0]];


// Function: affine2d_to_3d()
// Usage:
//   mat = affine2d_to_3d(m);
// Description: Takes a 3x3 affine2d matrix and returns its 4x4 affine3d equivalent.
function affine2d_to_3d(m) = concat(
    [for (r = [0:2])
        concat(
            [for (c = [0:2]) m[r][c]],
            [0]
        )
    ],
    [[0, 0, 0, 1]]
);



// Section: Affine2d 3x3 Transformation Matrices


// Function: affine2d_identity()
// Usage:
//   mat = affine2d_identify();
// Description: Create a 3x3 affine2d identity matrix.
function affine2d_identity() = ident(3);


// Function: affine2d_translate()
// Usage:
//   mat = affine2d_translate(v);
// Description:
//   Returns the 3x3 affine2d matrix to perform a 2D translation.
// Arguments:
//   v = 2D Offset to translate by.  [X,Y]
function affine2d_translate(v) = [
    [1, 0, v.x],
    [0, 1, v.y],
    [0 ,0,   1]
];


// Function: affine2d_scale()
// Usage:
//   mat = affine2d_scale(v);
// Description:
//   Returns the 3x3 affine2d matrix to perform a 2D scaling transformation.
// Arguments:
//   v = 2D vector of scaling factors.  [X,Y]
function affine2d_scale(v) = [
    [v.x,   0, 0],
    [  0, v.y, 0],
    [  0,   0, 1]
];


// Function: affine2d_zrot()
// Usage:
//   mat = affine2d_zrot(ang);
// Description:
//   Returns the 3x3 affine2d matrix to perform a rotation of a 2D vector around the Z axis.
// Arguments:
//   ang = Number of degrees to rotate.
function affine2d_zrot(ang) = [
    [cos(ang), -sin(ang), 0],
    [sin(ang),  cos(ang), 0],
    [       0,         0, 1]
];


// Function: affine2d_mirror()
// Usage:
//   mat = affine2d_mirror(v);
// Description:
//   Returns the 3x3 affine2d matrix to perform a reflection of a 2D vector across the line given by its normal vector.
// Arguments:
//   v = The normal vector of the line to reflect across.
function affine2d_mirror(v) =
    let(v=unit(point2d(v)), a=v.x, b=v.y)
    [
        [1-2*a*a, 0-2*a*b, 0],
        [0-2*a*b, 1-2*b*b, 0],
        [      0,       0, 1]
    ];


// Function: affine2d_skew()
// Usage:
//   mat = affine2d_skew(xa, ya);
// Description:
//   Returns the 3x3 affine2d matrix to skew a 2D vector along the XY plane.
// Arguments:
//   xa = Skew angle, in degrees, in the direction of the X axis.
//   ya = Skew angle, in degrees, in the direction of the Y axis.
function affine2d_skew(xa, ya) = [
    [1,       tan(xa), 0],
    [tan(ya), 1,       0],
    [0,       0,       1]
];


// Function: affine2d_chain()
// Usage:
//   mat = affine2d_chain(affines);
// Description:
//   Returns a 3x3 affine2d transformation matrix which results from applying each matrix in `affines` in order.
// Arguments:
//   affines = A list of 3x3 affine2d matrices.
function affine2d_chain(affines, _m=undef, _i=0) =
    (_i>=len(affines))? (is_undef(_m)? ident(3) : _m) :
    affine2d_chain(affines, _m=(is_undef(_m)? affines[_i] : affines[_i] * _m), _i=_i+1);



// Section: Affine3d 4x4 Transformation Matrices


// Function: affine3d_identity()
// Usage:
//   mat = affine3d_identity();
// Description: Create a 4x4 affine3d identity matrix.
function affine3d_identity() = ident(4);


// Function: affine3d_translate()
// Usage:
//   mat = affine3d_translate(v);
// Description:
//   Returns the 4x4 affine3d matrix to perform a 3D translation.
// Arguments:
//   v = 3D offset to translate by.  [X,Y,Z]
function affine3d_translate(v) = [
    [1, 0, 0, v.x],
    [0, 1, 0, v.y],
    [0, 0, 1, v.z],
    [0 ,0, 0,   1]
];


// Function: affine3d_scale()
// Usage:
//   mat = affine3d_scale(v);
// Description:
//   Returns the 4x4 affine3d matrix to perform a 3D scaling transformation.
// Arguments:
//   v = 3D vector of scaling factors.  [X,Y,Z]
function affine3d_scale(v) = [
    [v.x,   0,   0, 0],
    [  0, v.y,   0, 0],
    [  0,   0, v.z, 0],
    [  0,   0,   0, 1]
];


// Function: affine3d_xrot()
// Usage:
//   mat = affine3d_xrot(ang);
// Description:
//   Returns the 4x4 affine3d matrix to perform a rotation of a 3D vector around the X axis.
// Arguments:
//   ang = number of degrees to rotate.
function affine3d_xrot(ang) = [
    [1,        0,         0,   0],
    [0, cos(ang), -sin(ang),   0],
    [0, sin(ang),  cos(ang),   0],
    [0,        0,         0,   1]
];


// Function: affine3d_yrot()
// Usage:
//   mat = affine3d_yrot(ang);
// Description:
//   Returns the 4x4 affine3d matrix to perform a rotation of a 3D vector around the Y axis.
// Arguments:
//   ang = Number of degrees to rotate.
function affine3d_yrot(ang) = [
    [ cos(ang), 0, sin(ang),   0],
    [        0, 1,        0,   0],
    [-sin(ang), 0, cos(ang),   0],
    [        0, 0,        0,   1]
];


// Function: affine3d_zrot()
// Usage:
//   mat = affine3d_zrot(ang);
// Description:
//   Returns the 4x4 affine3d matrix to perform a rotation of a 3D vector around the Z axis.
// Arguments:
//   ang = number of degrees to rotate.
function affine3d_zrot(ang) = [
    [cos(ang), -sin(ang), 0, 0],
    [sin(ang),  cos(ang), 0, 0],
    [       0,         0, 1, 0],
    [       0,         0, 0, 1]
];


// Function: affine3d_rot_by_axis()
// Usage:
//   mat = affine3d_rot_by_axis(u, ang);
// Description:
//   Returns the 4x4 affine3d matrix to perform a rotation of a 3D vector around an axis.
// Arguments:
//   u = 3D axis vector to rotate around.
//   ang = number of degrees to rotate.
function affine3d_rot_by_axis(u, ang) =
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
// Usage:
//   mat = affine3d_rot_from_to(from, to);
// Description:
//   Returns the 4x4 affine3d matrix to perform a rotation of a 3D vector from one vector direction to another.
// Arguments:
//   from = 3D axis vector to rotate from.
//   to = 3D axis vector to rotate to.
function affine3d_rot_from_to(from, to) =
    let(
        from = unit(point3d(from)),
        to = unit(point3d(to))
    ) approx(from,to)? affine3d_identity() :
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


// Function: affine_frame_map()
// Usage:
//   map = affine_frame_map(v1, v2, v3);
//   map = affine_frame_map(x=VECTOR1, y=VECTOR2, <reverse>);
//   map = affine_frame_map(x=VECTOR1, z=VECTOR2, <reverse>);
//   map = affine_frame_map(y=VECTOR1, y=VECTOR2, <reverse>);
// Description:
//   Returns a transformation that maps one coordinate frame to another.  You must specify two or three of `x`, `y`, and `z`.  The specified
//   axes are mapped to the vectors you supplied.  If you give two inputs, the third vector is mapped to the appropriate normal to maintain a right hand coordinate system.
//   If the vectors you give are orthogonal the result will be a rotation and the `reverse` parameter will supply the inverse map, which enables you
//   to map two arbitrary coordinate systems to each other by using the canonical coordinate system as an intermediary.  You cannot use the `reverse` option 
//   with non-orthogonal inputs.
// Arguments:
//   x = Destination vector for x axis
//   y = Destination vector for y axis
//   z = Destination vector for z axis
//   reverse = reverse direction of the map for orthogonal inputs.  Default: false
// Examples:
//   T = affine_frame_map(x=[1,1,0], y=[-1,1,0]);   // This map is just a rotation around the z axis
//   T = affine_frame_map(x=[1,0,0], y=[1,1,0]);    // This map is not a rotation because x and y aren't orthogonal
//                  // The next map sends [1,1,0] to [0,1,1] and [-1,1,0] to [0,-1,1]
//   T = affine_frame_map(x=[0,1,1], y=[0,-1,1]) * affine_frame_map(x=[1,1,0], y=[-1,1,0],reverse=true);
function affine_frame_map(x,y,z, reverse=false) =
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
        affine2d_to_3d(map)
    ) : affine2d_to_3d(transpose(map));



// Function: affine3d_mirror()
// Usage:
//   mat = affine3d_mirror(v);
// Description:
//   Returns the 4x4 affine3d matrix to perform a reflection of a 3D vector across the plane given by its normal vector.
// Arguments:
//   v = The normal vector of the plane to reflect across.
function affine3d_mirror(v) =
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
// Usage:
//   mat = affine3d_skew(<sxy>, <sxz>, <syx>, <syz>, <szx>, <szy>);
// Description:
//   Returns the 4x4 affine3d matrix to perform a skew transformation.
// Arguments:
//   sxy = Skew factor multiplier for skewing along the X axis as you get farther from the Y axis.  Default: 0
//   sxz = Skew factor multiplier for skewing along the X axis as you get farther from the Z axis.  Default: 0
//   syx = Skew factor multiplier for skewing along the Y axis as you get farther from the X axis.  Default: 0
//   syz = Skew factor multiplier for skewing along the Y axis as you get farther from the Z axis.  Default: 0
//   szx = Skew factor multiplier for skewing along the Z axis as you get farther from the X axis.  Default: 0
//   szy = Skew factor multiplier for skewing along the Z axis as you get farther from the Y axis.  Default: 0
function affine3d_skew(sxy=0, sxz=0, syx=0, syz=0, szx=0, szy=0) = [
    [  1, sxy, sxz, 0],
    [syx,   1, syz, 0],
    [szx, szy,   1, 0],
    [  0,   0,   0, 1]
];


// Function: affine3d_skew_xy()
// Usage:
//   mat = affine3d_skew_xy(xa, ya);
// Description:
//   Returns the 4x4 affine3d matrix to perform a skew transformation along the XY plane.
// Arguments:
//   xa = Skew angle, in degrees, in the direction of the X axis.
//   ya = Skew angle, in degrees, in the direction of the Y axis.
function affine3d_skew_xy(xa, ya) = [
    [1, 0, tan(xa), 0],
    [0, 1, tan(ya), 0],
    [0, 0,       1, 0],
    [0, 0,       0, 1]
];


// Function: affine3d_skew_xz()
// Usage:
//   mat = affine3d_skew_xz(xa, za);
// Description:
//   Returns the 4x4 affine3d matrix to perform a skew transformation along the XZ plane.
// Arguments:
//   xa = Skew angle, in degrees, in the direction of the X axis.
//   za = Skew angle, in degrees, in the direction of the Z axis.
function affine3d_skew_xz(xa, za) = [
    [1, tan(xa), 0, 0],
    [0,       1, 0, 0],
    [0, tan(za), 1, 0],
    [0,       0, 0, 1]
];


// Function: affine3d_skew_yz()
// Usage:
//   mat = affine3d_skew_yz(ya, za);
// Description:
//   Returns the 4x4 affine3d matrix to perform a skew transformation along the YZ plane.
// Arguments:
//   ya = Skew angle, in degrees, in the direction of the Y axis.
//   za = Skew angle, in degrees, in the direction of the Z axis.
function affine3d_skew_yz(ya, za) = [
    [      1, 0, 0, 0],
    [tan(ya), 1, 0, 0],
    [tan(za), 0, 1, 0],
    [      0, 0, 0, 1]
];


// Function: affine3d_chain()
// Usage:
//   mat = affine3d_chain(affines);
// Description:
//   Returns a 4x4 affine3d transformation matrix which results from applying each matrix in `affines` in order.
// Arguments:
//   affines = A list of 4x4 affine3d matrices.
function affine3d_chain(affines, _m=undef, _i=0) =
    (_i>=len(affines))? (is_undef(_m)? ident(4) : _m) :
    affine3d_chain(affines, _m=(is_undef(_m)? affines[_i] : affines[_i] * _m), _i=_i+1);


// Function: apply()
// Usage:
//   pts = apply(transform, points);
// Description:
//   Applies the specified transformation matrix to a point list (or single point).  Both inputs can be 2d or 3d, and it is also allowed
//   to supply 3d transformations with 2d data as long as the the only action on the z coordinate is a simple scaling.  
// Examples:
//   transformed = apply(xrot(45), path3d(circle(r=3)));  // Rotates 3d circle data around x axis
//   transformed = apply(rot(45), circle(r=3));           // Rotates 2d circle data by 45 deg
//   transformed = apply(rot(45)*right(4)*scale(3), circle(r=3));  // Scales, translates and rotates 2d circle data
function apply(transform,points) =
  points==[] ? [] : 
  is_vector(points) ? apply(transform, [points])[0] :
  let(
    tdim = len(transform[0])-1,
    datadim = len(points[0])
  )
  tdim == 3 && datadim == 3 ? [for(p=points) point3d(transform*concat(p,[1]))] :
  tdim == 2 && datadim == 2 ? [for(p=points) point2d(transform*concat(p,[1]))] :  
  tdim == 3 && datadim == 2 ? 
    assert(is_2d_transform(transform),str("Transforms is 3d but points are 2d"))
    [for(p=points) point2d(transform*concat(p,[0,1]))] :
  assert(false,str("Unsupported combination: transform with dimension ",tdim,", data of dimension ",datadim));


// Function: apply_list()
// Usage:
//   pts = apply_list(points, transform_list);
// Description:
//   Transforms the specified point list (or single point) using a list of transformation matrices.  Transformations on
//   the list are applied in the order they appear in the list (as in right multiplication of matrices).  Both inputs can be
//   2d or 3d, and it is also allowed to supply 3d transformations with 2d data as long as the the only action on the z coordinate
//   is a simple scaling.  All transformations on `transform_list` must have the same dimension: you cannot mix 2d and 3d transformations
//   even when acting on 2d data.  
// Examples:
//   transformed = apply_list(path3d(circle(r=3)),[xrot(45)]);        // Rotates 3d circle data around x axis
//   transformed = apply_list(circle(r=3), [scale(3), right(4), rot(45)]); // Scales, then translates, and then rotates 2d circle data
function apply_list(points,transform_list) =
  transform_list == []? points :
  is_vector(points) ? apply_list([points],transform_list)[0] :
  let(
      tdims = array_dim(transform_list),
      datadim = len(points[0])
  )
  assert(len(tdims)==3 || tdims[1]!=tdims[2], "Invalid transformation list")
  let( tdim = tdims[1]-1 )
  tdim==2 && datadim == 2 ? apply(affine2d_chain(transform_list), points) :
  tdim==3 && datadim == 3 ? apply(affine3d_chain(transform_list), points) :
  tdim==3 && datadim == 2 ? 
    let(
        badlist = [for(i=idx(transform_list)) if (!is_2d_transform(transform_list[i])) i]
    )
    assert(badlist==[],str("Transforms with indices ",badlist," are 3d but points are 2d"))
    apply(affine3d_chain(transform_list), points) :
  assert(false,str("Unsupported combination: transform with dimension ",tdim,", data of dimension ",datadim));    
    

// Function: is_2d_transform()
// Usage:
//   x = is_2d_transform(t);
// Description:
//   Checks if the input is a 3d transform that does not act on the z coordinate, except
//   possibly for a simple scaling of z.  Note that an input which is only a zscale returns false.  
function is_2d_transform(t) =    // z-parameters are zero, except we allow t[2][2]!=1 so scale() works
  t[2][0]==0 && t[2][1]==0 && t[2][3]==0 && t[0][2] == 0 && t[1][2]==0 &&
  (t[2][2]==1 || !(t[0][0]==1 && t[0][1]==0 && t[1][0]==0 && t[1][1]==1));   // But rule out zscale()



// Function: rot_decode()
// Usage:
//   info = rot_decode(rotation); // Returns: [angle,axis,cp,translation]
// Description:
//   Given an input 3d rigid transformation operator (one composed of just rotations and translations)
//   represented as a 4x4 matrix, compute the rotation and translation parameters of the operator.
//   Returns a list of the four parameters, the angle, in the interval [0,180], the rotation axis
//   as a unit vector, a centerpoint for the rotation, and a translation.  If you set `parms=rot_decode(rotation)`
//   then the transformation can be reconstructed from parms as `move(parms[3])*rot(a=parms[0],v=parms[1],cp=parms[2])`.
//   This decomposition makes it possible to perform interpolation.  If you construct a transformation using `rot`
//   the decoding may flip the axis (if you gave an angle outside of [0,180]).  The returned axis will be a unit vector,
//   and the centerpoint lies on the plane through the origin that is perpendicular to the axis.  It may be different
//   than the centerpoint you used to construct the transformation.  
// Example:
//   rot_decode(rot(45));                // Returns [45,[0,0,1], [0,0,0], [0,0,0]]
//   rot_decode(rot(a=37, v=[1,2,3], cp=[4,3,-7])));  // Returns [37, [0.26, 0.53, 0.80], [4.8, 4.6, -4.6], [0,0,0]]
//   rot_decode(left(12)*xrot(-33));     // Returns [33, [-1,0,0], [0,0,0], [-12,0,0]]
//   rot_decode(translate([3,4,5]));     // Returns [0, [0,0,1], [0,0,0], [3,4,5]]
function rot_decode(M) =
    assert(is_matrix(M,4,4) && approx(M[3],[0,0,0,1]), "Input matrix must be a 4x4 matrix representing a 3d transformation")
    let(R = submatrix(M,[0:2],[0:2]))
    assert(approx(det3(R),1) && approx(norm_fro(R * transpose(R)-ident(3)),0),"Input matrix is not a rotation")
    let(
       translation = [for(row=[0:2]) M[row][3]],   // translation vector
       largest  = max_index([R[0][0], R[1][1], R[2][2]]),
       axis_matrix = R + transpose(R) - (matrix_trace(R)-1)*ident(3),   // Each row is on the rotational axis
         // Construct quaternion q = c * [x sin(theta/2), y sin(theta/2), z sin(theta/2), cos(theta/2)]
       q_im = axis_matrix[largest],
       q_re = R[(largest+2)%3][(largest+1)%3] - R[(largest+1)%3][(largest+2)%3],
       c_sin = norm(q_im),              // c * sin(theta/2) for some c
       c_cos = abs(q_re)                // c * cos(theta/2)
    )
    approx(c_sin,0) ? [0,[0,0,1],[0,0,0],translation] :
    let(
       angle = 2*atan2(c_sin, c_cos),    // This is supposed to be more accurate than acos or asin
       axis  = (q_re>=0 ? 1:-1)*q_im/c_sin,
       tproj = translation - (translation*axis)*axis,    // Translation perpendicular to axis determines centerpoint
       cp    = (tproj + cross(axis,tproj)*c_cos/c_sin)/2
    )
    [angle, axis, cp, (translation*axis)*axis];




// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
