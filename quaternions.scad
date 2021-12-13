///////////////////////////////////////////
// LibFile: quaternions.scad
//   Support for Quaternions.
// Includes:
//   include <BOSL2/std.scad>
// FileGroup: Math
// FileSummary: Quaternion based rotations that avoid gimbal lock issues.
// FileFootnotes: STD=Included in std.scad
///////////////////////////////////////////


// Section: Quaternions
//   Quaternions are fast methods of storing and calculating arbitrary rotations.
//   Quaternions contain information on both axis of rotation, and rotation angle.
//   You can chain multiple rotation together by multiplying quaternions together.
//   They don't suffer from the gimbal-lock issues that `[X,Y,Z]` rotation angles do.
//   Quaternions are stored internally as a 4-value vector:
//   `[X,Y,Z,W]`, where the quaternion formula is `W+Xi+Yj+Zk`


// Internal
function _quat(a,s,w) = [a[0]*s, a[1]*s, a[2]*s, w];

function _qvec(q) = [q.x,q.y,q.z];

function _qreal(q) = q[3];

function _qset(v,r) = concat( v, r );

// normalizes without checking
function _qnorm(q) = q/norm(q);


// Function: is_quaternion()
// Usage:
//   if(is_quaternion(q)) a=0;
// Description: Return true if q is a valid non-zero quaternion.
// Arguments:
//   q = object to check.
function is_quaternion(q) = is_vector(q,4) && ! approx(norm(q),0) ;


// Function: quat()
// Usage:
//   quat(ax, ang);
// Description: Create a normalized Quaternion from axis and angle of rotation.
// Arguments:
//   ax = Vector of axis of rotation.
//   ang = Number of degrees to rotate around the axis counter-clockwise, when facing the origin.
function quat(ax=[0,0,1], ang=0) = 
    assert( is_vector(ax,3) && is_finite(ang), "Invalid input")
    let( n = norm(ax) )
    approx(n,0) 
    ? _quat([0,0,0], sin(ang/2), cos(ang/2))
    : _quat(ax/n, sin(ang/2), cos(ang/2));


// Function: quat_x()
// Usage:
//   quat_x(a);
// Description: Create a normalized Quaternion for rotating around the X axis [1,0,0].
// Arguments:
//   a = Number of degrees to rotate around the axis counter-clockwise, when facing the origin.
function quat_x(a=0) = 
    assert( is_finite(a), "Invalid angle" )
    quat([1,0,0],a);


// Function: quat_y()
// Usage:
//   quat_y(a);
// Description: Create a normalized Quaternion for rotating around the Y axis [0,1,0].
// Arguments:
//   a = Number of degrees to rotate around the axis counter-clockwise, when facing the origin.
function quat_y(a=0) =  
    assert( is_finite(a), "Invalid angle" )
    quat([0,1,0],a);


// Function: quat_z()
// Usage:
//   quat_z(a);
// Description: Create a normalized Quaternion for rotating around the Z axis [0,0,1].
// Arguments:
//   a = Number of degrees to rotate around the axis counter-clockwise, when facing the origin.
function quat_z(a=0) =  
    assert( is_finite(a), "Invalid angle" )
    quat([0,0,1],a);


// Function: quat_xyz()
// Usage:
//   quat_xyz([X,Y,Z])
// Description:
//   Creates a normalized quaternion from standard [X,Y,Z] rotation angles in degrees.
// Arguments:
//   a = The triplet of rotation angles, [X,Y,Z]
function quat_xyz(a=[0,0,0]) =
    assert( is_vector(a,3), "Invalid angles")
    let(
      qx = quat_x(a[0]),
      qy = quat_y(a[1]),
      qz = quat_z(a[2])
    )
    q_mul(qz, q_mul(qy, qx));


// Function: q_from_to()
// Usage:
//    q = q_from_to(v1, v2);
// Description: 
//   Returns the normalized quaternion that rotates the non zero 3D vector v1 
//   to the non zero 3D vector v2.
function q_from_to(v1, v2) =
    assert( is_vector(v1,3) && is_vector(v2,3) 
            && ! approx(norm(v1),0) && ! approx(norm(v2),0)
            , "Invalid vector(s)")
    let( ax = cross(v1,v2),
         n  = norm(ax) )
    approx(n, 0)
    ? v1*v2>0 ? q_ident() : quat([ v1.y, -v1.x, 0], 180)  
    : quat(ax, atan2( n , v1*v2 ));


// Function: q_ident()
// Description: Returns the "Identity" zero-rotation Quaternion.
function q_ident() = [0, 0, 0, 1];


// Function: q_add_s()
// Usage:
//   q_add_s(q, s)
// Description: 
//   Adds a scalar value `s` to the W part of a quaternion `q`.
//   The returned quaternion is usually not normalized.
function q_add_s(q, s) =  
    assert( is_finite(s), "Invalid scalar" )
    q+[0,0,0,s];


// Function: q_sub_s()
// Usage:
//   q_sub_s(q, s)
// Description: 
//   Subtracts a scalar value `s` from the W part of a quaternion `q`.
//   The returned quaternion is usually not normalized.
function q_sub_s(q, s) =  
    assert( is_finite(s), "Invalid scalar" )
    q-[0,0,0,s];


// Function: q_mul_s()
// Usage:
//   q_mul_s(q, s)
// Description: 
//   Multiplies each part of a quaternion `q` by a scalar value `s`.
//   The returned quaternion is usually not normalized.
function q_mul_s(q, s) =  
    assert( is_finite(s), "Invalid scalar" )
    q*s;


// Function: q_div_s()
// Usage:
//   q_div_s(q, s)
// Description: 
//   Divides each part of a quaternion `q` by a scalar value `s`.
//   The returned quaternion is usually not normalized.
function q_div_s(q, s) =   
    assert( is_finite(s) && ! approx(s,0) , "Invalid scalar" )
    q/s;


// Function: q_add()
// Usage:
//   q_add(a, b)
// Description: 
//   Adds each part of two quaternions together.
//   The returned quaternion is usually not normalized.
function q_add(a, b) = 
    assert( is_quaternion(a) && is_quaternion(a), "Invalid quaternion(s)") 
    assert( ! approx(norm(a+b),0), "Quaternions cannot be opposed" )
    a+b;


// Function: q_sub()
// Usage:
//   q_sub(a, b)
// Description: 
//   Subtracts each part of quaternion `b` from quaternion `a`.
//   The returned quaternion is usually not normalized.
function q_sub(a, b) = 
    assert( is_quaternion(a) && is_quaternion(a), "Invalid quaternion(s)") 
    assert( ! approx(a,b), "Quaternions cannot be equal" )
    a-b;


// Function: q_mul()
// Usage:
//   q_mul(a, b)
// Description: 
//   Multiplies quaternion `a` by quaternion `b`.
//   The returned quaternion is normalized if both `a` and `b` are normalized
function q_mul(a, b) = 
    assert( is_quaternion(a) && is_quaternion(b), "Invalid quaternion(s)")
    [
      a[3]*b.x  + a.x*b[3] + a.y*b.z  - a.z*b.y,
      a[3]*b.y  - a.x*b.z  + a.y*b[3] + a.z*b.x,
      a[3]*b.z  + a.x*b.y  - a.y*b.x  + a.z*b[3],
      a[3]*b[3] - a.x*b.x  - a.y*b.y  - a.z*b.z,
    ];


// Function: q_cumulative()
// Usage:
//   q_cumulative(v);
// Description:
//   Given a list of Quaternions, cumulatively multiplies them, returning a list
//   of each cumulative Quaternion product.  It starts with the first quaternion
//   given in the list, and applies successive quaternion rotations in list order.
//   The quaternion in the returned list are normalized if each quaternion in v
//   is normalized.
function q_cumulative(v, _i=0, _acc=[]) = 
    _i==len(v) ? _acc :
    q_cumulative(
        v, _i+1,
        concat(
            _acc,
            [_i==0 ? v[_i] : q_mul(v[_i], last(_acc))]
        )
    );


// Function: q_dot()
// Usage:
//   q_dot(a, b)
// Description: Calculates the dot product between quaternions `a` and `b`.
function q_dot(a, b) = 
    assert( is_quaternion(a) && is_quaternion(b), "Invalid quaternion(s)" )
    a*b;

// Function: q_neg()
// Usage:
//   q_neg(q)
// Description: Returns the negative of quaternion `q`.
function q_neg(q) = 
    assert( is_quaternion(q), "Invalid quaternion" )
    -q;


// Function: q_conj()
// Usage:
//   q_conj(q)
// Description: Returns the conjugate of quaternion `q`.
function q_conj(q) = 
    assert( is_quaternion(q), "Invalid quaternion" )
    [-q.x, -q.y, -q.z, q[3]];


// Function: q_inverse()
// Usage:
//   qc = q_inverse(q)
// Description: Returns the multiplication inverse of quaternion `q`  that is normalized only if `q` is normalized.
function q_inverse(q) = 
    assert( is_quaternion(q), "Invalid quaternion" )
    let(q = _qnorm(q) )
    [-q.x, -q.y, -q.z, q[3]];


// Function: q_norm()
// Usage:
//   q_norm(q)
// Description: 
//   Returns the `norm()` "length" of quaternion `q`.
//   Normalized quaternions have unitary norm. 
function q_norm(q) = 
    assert( is_quaternion(q), "Invalid quaternion" )
    norm(q);


// Function: q_normalize()
// Usage:
//   q_normalize(q)
// Description: Normalizes quaternion `q`, so that norm([W,X,Y,Z]) == 1.
function q_normalize(q) = 
    assert( is_quaternion(q) , "Invalid quaternion" )
    q/norm(q);


// Function: q_dist()
// Usage:
//   q_dist(q1, q2)
// Description: Returns the "distance" between two quaternions.
function q_dist(q1, q2) =   
    assert( is_quaternion(q1) && is_quaternion(q2), "Invalid quaternion(s)" )
    norm(q2-q1);


// Function: q_slerp()
// Usage:
//   q_slerp(q1, q2, u);
// Description:
//   Returns a quaternion that is a spherical interpolation between two quaternions.
// Arguments:
//   q1 = The first quaternion. (u=0)
//   q2 = The second quaternion. (u=1)
//   u = The proportional value, from 0 to 1, of what part of the interpolation to return.
// Example(3D): Giving `u` as a Scalar
//   a = quat_y(-135);
//   b = quat_xyz([0,-30,30]);
//   for (u=[0:0.1:1])
//       q_rot(q_slerp(a, b, u))
//           right(80) cube([10,10,1]);
//   #sphere(r=80);
// Example(3D): Giving `u` as a Range
//   a = quat_z(-135);
//   b = quat_xyz([90,0,-45]);
//   for (q = q_slerp(a, b, [0:0.1:1]))
//       q_rot(q) right(80) cube([10,10,1]);
//   #sphere(r=80);
function q_slerp(q1, q2, u, _dot) =
    is_undef(_dot) 
    ?   assert(is_finite(u) || is_range(u) || is_vector(u), "Invalid interpolation coefficient(s)")
        assert(is_quaternion(q1) && is_quaternion(q2), "Invalid quaternion(s)" )
        let(
          _dot = q1*q2,
          q1   = q1/norm(q1),
          q2   = _dot<0 ? -q2/norm(q2) : q2/norm(q2),
          dot  = abs(_dot)
        )
        ! is_finite(u) ? [for (uu=u) q_slerp(q1, q2, uu, dot)] :
        q_slerp(q1, q2, u, dot)  
    :   _dot>0.9995 
        ?   _qnorm(q1 + u*(q2-q1))
        :   let( theta = u*acos(_dot),
                 q3    = _qnorm(q2 - _dot*q1)
               ) 
            _qnorm(q1*cos(theta) + q3*sin(theta));


// Function: q_matrix3()
// Usage:
//   q_matrix3(q);
// Description:
//   Returns the 3x3 rotation matrix for the given normalized quaternion q.
function q_matrix3(q) =   
    let( q = q_normalize(q) )
    [
      [1-2*q[1]*q[1]-2*q[2]*q[2],   2*q[0]*q[1]-2*q[2]*q[3],   2*q[0]*q[2]+2*q[1]*q[3]],
      [  2*q[0]*q[1]+2*q[2]*q[3], 1-2*q[0]*q[0]-2*q[2]*q[2],   2*q[1]*q[2]-2*q[0]*q[3]],
      [  2*q[0]*q[2]-2*q[1]*q[3],   2*q[1]*q[2]+2*q[0]*q[3], 1-2*q[0]*q[0]-2*q[1]*q[1]]
    ];


// Function: q_matrix4()
// Usage:
//   q_matrix4(q);
// Description:
//   Returns the 4x4 rotation matrix for the given normalized quaternion q.
function q_matrix4(q) =    
    let( q = q_normalize(q) )
    [
      [1-2*q[1]*q[1]-2*q[2]*q[2],   2*q[0]*q[1]-2*q[2]*q[3],   2*q[0]*q[2]+2*q[1]*q[3], 0],
      [  2*q[0]*q[1]+2*q[2]*q[3], 1-2*q[0]*q[0]-2*q[2]*q[2],   2*q[1]*q[2]-2*q[0]*q[3], 0],
      [  2*q[0]*q[2]-2*q[1]*q[3],   2*q[1]*q[2]+2*q[0]*q[3], 1-2*q[0]*q[0]-2*q[1]*q[1], 0],
      [                        0,                         0,                         0, 1]
    ];


// Function: q_axis()
// Usage:
//   q_axis(q)
// Description:
//   Returns the axis of rotation of a normalized quaternion `q`.
//   The input doesn't need to be normalized.
function q_axis(q) =   
    assert( is_quaternion(q) , "Invalid quaternion" )
    let( d = norm(_qvec(q)) )
    approx(d,0)? [0,0,1] : _qvec(q)/d;

// Function: q_angle()
// Usage:
//   a = q_angle(q)
//   a12 = q_angle(q1,q2);
// Description:
//   If only q1 is given, returns the angle of rotation (in degrees) of that quaternion.
//   If both q1 and q2 are given, returns the angle (in degrees) between them.
//   The input quaternions don't need to be normalized.
function q_angle(q1,q2) =
    assert(is_quaternion(q1) && (is_undef(q2) || is_quaternion(q2)), "Invalid quaternion(s)" )
    let( n1 = is_undef(q2)? norm(_qvec(q1)): norm(q1) )
    is_undef(q2) 
    ?   2 * atan2(n1,_qreal(q1))
    :   let( q1 = q1/norm(q1),
             q2 = q2/norm(q2) )
        4 * atan2(norm(q1 - q2), norm(q1 + q2));

// Function&Module: q_rot()
// Usage: As Module
//   q_rot(q) ...
// Usage: As Function
//   pts = q_rot(q,p);
// Description:
//   When called as a module, rotates all children by the rotation stored in quaternion `q`.
//   When called as a function with a `p` argument, rotates the point or list of points in `p` by the rotation stored in quaternion `q`.
//   When called as a function without a `p` argument, returns the affine3d rotation matrix for the rotation stored in quaternion `q`.
// Example(FlatSpin,VPD=225,VPT=[71,-26,16]):
//   module shape() translate([80,0,0]) cube([10,10,1]);
//   q = quat_xyz([90,-15,-45]);
//   q_rot(q) shape();
//   #shape();
// Example(NORENDER):
//   q = quat_xyz([45,35,10]);
//   mat4x4 = q_rot(q);
// Example(NORENDER):
//   q = quat_xyz([45,35,10]);
//   pt = q_rot(q, p=[4,5,6]);
// Example(NORENDER):
//   q = quat_xyz([45,35,10]);
//   pts = q_rot(q, p=[[2,3,4], [4,5,6], [9,2,3]]);
module q_rot(q) {
    multmatrix(q_matrix4(q)) {
        children();
    }
}

function q_rot(q,p) =
      is_undef(p)? q_matrix4(q) :
      is_vector(p)? q_rot(q,[p])[0] :
      apply(q_matrix4(q), p);


// Module: q_rot_copies()
// Usage:
//   q_rot_copies(quats) ...
// Description:
//   For each quaternion given in the list `quats`, rotates to that orientation and creates a copy
//   of all children.  This is equivalent to `for (q=quats) q_rot(q) ...`.
// Arguments:
//   quats = A list containing all quaternions to rotate to and create copies of all children for.
// Example:
//   a = quat_z(-135);
//   b = quat_xyz([0,-30,30]);
//   q_rot_copies(q_slerp(a, b, [0:0.1:1]))
//       right(80) cube([10,10,1]);
//   #sphere(r=80);
module q_rot_copies(quats) for (q=quats) q_rot(q) children();


// Function: q_rotation()
// Usage:
//   q_rotation(R)
// Description:
//   Returns a normalized quaternion corresponding to the rotation matrix R.
//   R may be a 3x3 rotation matrix or a homogeneous 4x4 rotation matrix.
//   The last row and last column of R are ignored for 4x4 matrices.
//   It doesn't check whether R is in fact a rotation matrix.
//   If R is not a rotation, the returned quaternion is an unpredictable quaternion .
function q_rotation(R) =
    assert( is_matrix(R,3,3) || is_matrix(R,4,4) , 
                      "Matrix is neither 3x3 nor 4x4")
    let( tr = R[0][0]+R[1][1]+R[2][2] ) // R trace
    tr>0 
    ?   let( r = 1+tr  )
        _qnorm( _qset([ R[1][2]-R[2][1], R[2][0]-R[0][2], R[0][1]-R[1][0] ], -r ) )
    :   let( i = max_index([ R[0][0], R[1][1], R[2][2] ]),
             r = 1 + 2*R[i][i] -R[0][0] -R[1][1] -R[2][2] )
        i==0 ? _qnorm( _qset( [ 4*r, (R[1][0]+R[0][1]), (R[0][2]+R[2][0]) ], (R[2][1]-R[1][2])) ):
        i==1 ? _qnorm( _qset( [ (R[1][0]+R[0][1]), 4*r, (R[2][1]+R[1][2]) ], (R[0][2]-R[2][0])) ):
            _qnorm( _qset( [ (R[2][0]+R[0][2]), (R[1][2]+R[2][1]), 4*r ], (R[1][0]-R[0][1])) ) ;


// Function&Module: q_rotation_path()
// Usage: As a function
//   path = q_rotation_path(q1, n, q2);
//   path = q_rotation_path(q1, n);
// Usage: As a module
//   q_rotation_path(q1, n, q2) ...
// Description:
//   If q2 is undef and it is called as a function, the path, with length n+1 (n>=1), will be the 
//   cumulative multiplications of the matrix rotation of q1 by itself.
//   If q2 is defined and it is called as a function, returns a rotation matrix path of length n+1 (n>=1) 
//   that interpolates two given rotation quaternions. The first matrix of the sequence is the 
//   matrix rotation of q1 and the last one, the matrix rotation of q2. The intermediary matrix 
//   rotations are an uniform interpolation of the path extreme matrices. 
//   When called as a module, applies to its children() each rotation of the sequence computed 
//   by the function.
//   The input quaternions don't need to be normalized.
// Arguments:
//   q1 = The quaternion of the first rotation. 
//   q2 = The quaternion of the last rotation.
//   n  = An integer defining the path length ( path length = n+1). 
// Example(3D): as a function
//   a = quat_y(-135);
//   b = quat_xyz([0,-30,30]);
//   for (M=q_rotation_path(a, 10, b))
//       multmatrix(M)
//           right(80) cube([10,10,1]);
//   #sphere(r=80);
// Example(3D): as a module
//   a = quat_y(-135);
//   b = quat_xyz([0,-30,30]);
//   q_rotation_path(a, 10, b)
//      right(80) cube([10,10,1]);
//   #sphere(r=80);
// Example(3D): as a function
//   a = quat_y(5);
//   for (M=q_rotation_path(a, 10))
//       multmatrix(M)
//           right(80) cube([10,10,1]);
//   #sphere(r=80);
// Example(3D): as a module
//   a = quat_y(5);
//   q_rotation_path(a, 10)
//      right(80) cube([10,10,1]);
//   #sphere(r=80);
function q_rotation_path(q1, n=1, q2) =
    assert( is_quaternion(q1) && (is_undef(q2) || is_quaternion(q2) ), "Invalid quaternion(s)" )
    assert( is_finite(n) && n>=1 && n==floor(n), "Invalid integer" )
    assert( is_undef(q2) || ! approx(norm(q1+q2),0), "Quaternions cannot be opposed" )
    is_undef(q2) 
    ?   [for( i=0, dR=q_matrix4(q1), R=dR; i<=n; i=i+1, R=dR*R ) R] 
    :   let( q2 = q_normalize( q1*q2<0 ? -q2: q2 ),
             dq = q_pow( q_mul( q2, q_inverse(q1) ), 1/n ),
             dR = q_matrix4(dq) )
        [for( i=0, R=q_matrix4(q1); i<=n; i=i+1, R=dR*R ) R];

module q_rotation_path(q1, n=1, q2) {
    for(Mi=q_rotation_path(q1, n, q2))
        multmatrix(Mi)
            children();
}


// Function: q_nlerp()
// Usage:
//   q = q_nlerp(q1, q2, u);
// Description:
//   Returns a quaternion that is a normalized linear interpolation between two quaternions
//   when u is a number.
//   If u is a list of numbers, computes the interpolations for each value in the
//   list and returns the interpolated quaternions in a list.
//   The input quaternions don't need to be normalized.
// Arguments:
//   q1 = The first quaternion. (u=0)
//   q2 = The second quaternion. (u=1)
//   u  = A value (or a list of values), between 0 and 1, of the proportion(s) of each quaternion in the interpolation. 
// Example(3D): Giving `u` as a Scalar
//   a = quat_y(-135);
//   b = quat_xyz([0,-30,30]);
//   for (u=[0:0.1:1])
//       q_rot(q_nlerp(a, b, u))
//           right(80) cube([10,10,1]);
//   #sphere(r=80);
// Example(3D): Giving `u` as a Range
//   a = quat_z(-135);
//   b = quat_xyz([90,0,-45]);
//   for (q = q_nlerp(a, b, [0:0.1:1]))
//       q_rot(q) right(80) cube([10,10,1]);
//   #sphere(r=80);
function q_nlerp(q1,q2,u) =
    assert(is_finite(u) || is_range(u) || is_vector(u) ,
           "Invalid interpolation coefficient(s)" )
    assert(is_quaternion(q1) && is_quaternion(q2), "Invalid quaternion(s)" )
    assert( ! approx(norm(q1+q2),0), "Quaternions cannot be opposed" )
    let( q1  = q_normalize(q1),
         q2  = q_normalize(q2) )
    is_num(u) 
    ? _qnorm((1-u)*q1 + u*q2 )
    : [for (ui=u) _qnorm((1-ui)*q1 + ui*q2 ) ];


// Function: q_squad()
// Usage:
//   qn = q_squad(q1,q2,q3,q4,u);
// Description:
//   Returns a quaternion that is a cubic spherical interpolation of the quaternions  
//   q1 and q4 taking the other two quaternions, q2 and q3, as parameter of a cubic 
//   on the sphere similar to the control points of a Bezier curve.
//   If u is a number, usually between 0 and 1, returns the quaternion that results
//   from the interpolation. 
//   If u is a list of numbers, computes the interpolations for each value in the
//   list and returns the interpolated quaternions in a list.
//   The input quaternions don't need to be normalized.
// Arguments:
//   q1 = The start quaternion. (u=0)
//   q1 = The first intermediate quaternion.
//   q2 = The second intermediate quaternion.
//   q4 = The end quaternion. (u=1)
//   u  = A value (or a list of values), of the proportion(s) of each quaternion in the cubic interpolation. 
// Example(3D): Giving `u` as a Scalar
//   a = quat_y(-135);
//   b = quat_xyz([-50,-50,120]);
//   c = quat_xyz([-50,-40,30]);
//   d = quat_y(-45);
//   color("red"){
//     q_rot(b) right(80) cube([10,10,1]);
//     q_rot(c) right(80) cube([10,10,1]);
//   }
//   for (u=[0:0.05:1])
//       q_rot(q_squad(a, b, c, d, u))
//           right(80) cube([10,10,1]);
//   #sphere(r=80);
// Example(3D): Giving `u` as a Range
//   a = quat_y(-135);
//   b = quat_xyz([-50,-50,120]);
//   c = quat_xyz([-50,-40,30]);
//   d = quat_y(-45);
//   for (q = q_squad(a, b, c, d, [0:0.05:1]))
//       q_rot(q) right(80) cube([10,10,1]);
//   #sphere(r=80);
function q_squad(q1,q2,q3,q4,u) =
    assert(is_finite(u) || is_range(u) || is_vector(u) ,
           "Invalid interpolation coefficient(s)" )
    is_num(u) 
    ? q_slerp( q_slerp(q1,q4,u), q_slerp(q2,q3,u), 2*u*(1-u))
    : [for(ui=u) q_slerp( q_slerp(q1,q4,ui), q_slerp(q2,q3,ui), 2*ui*(1-ui) ) ];


// Function: q_exp()
// Usage:
//   q2 = q_exp(q);
// Description:
//   Returns the quaternion that is the exponential of the quaternion q in base e
//   The returned quaternion is usually not normalized.
function q_exp(q) =
    assert( is_vector(q,4), "Input is not a valid quaternion")
    let( nv = norm(_qvec(q)) ) // q may be equal to zero here!
    exp(_qreal(q))*quat(_qvec(q),2*nv);


// Function: q_ln()
// Usage:
//   q2 = q_ln(q);
// Description:
//   Returns the quaternion that is the natural logarithm of the quaternion q.
//   The returned quaternion is usually not normalized and may be zero.
function q_ln(q) =
    assert(is_quaternion(q), "Input is not a valid quaternion")
    let(
        nq = norm(q),
        nv = norm(_qvec(q))
    )
    approx(nv,0) ? _qset([0,0,0] , ln(nq) ) :
    _qset(_qvec(q)*atan2(nv,_qreal(q))/nv, ln(nq));


// Function: q_pow()
// Usage:
//   q2 = q_pow(q, r);
// Description:
//   Returns the quaternion that is the power of the quaternion q to the real exponent r.
//   The returned quaternion is normalized if `q` is normalized.
function q_pow(q,r=1) =
    assert( is_quaternion(q) && is_finite(r), "Invalid inputs")
    let( theta = 2*atan2(norm(_qvec(q)),_qreal(q)) )
    quat(_qvec(q), r*theta); //  q_exp(r*q_ln(q)); 



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
