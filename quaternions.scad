///////////////////////////////////////////
// LibFile: quaternions.scad
//   Support for Quaternions.
// Includes:
//   include <BOSL2/std.scad>
///////////////////////////////////////////


// Section: Quaternions
//   Quaternions are fast methods of storing and calculating arbitrary rotations.
//   Quaternions contain information on both axis of rotation, and rotation angle.
//   You can chain multiple rotation together by multiplying quaternions together.
//   They don't suffer from the gimbal-lock issues that `[X,Y,Z]` rotation angles do.
//   Quaternions are stored internally as a 4-value vector:
//   `[X,Y,Z,W]`, where the quaternion formula is `W+Xi+Yj+Zk`


// Internal
function _Quat(a,s,w) = [a[0]*s, a[1]*s, a[2]*s, w];

function _Qvec(q) = [q.x,q.y,q.z];

function _Qreal(q) = q[3];

function _Qset(v,r) = concat( v, r );

// normalizes without checking
function _Qnorm(q) = q/norm(q);


// Function: Q_is_quat()
// Usage:
//   if(Q_is_quat(q)) a=0;
// Description: Return true if q is a valid non-zero quaternion.
// Arguments:
//   q = object to check.
function Q_is_quat(q) = is_vector(q,4) && ! approx(norm(q),0) ;


// Function: Quat()
// Usage:
//   Quat(ax, ang);
// Description: Create a normalized Quaternion from axis and angle of rotation.
// Arguments:
//   ax = Vector of axis of rotation.
//   ang = Number of degrees to rotate around the axis counter-clockwise, when facing the origin.
function Quat(ax=[0,0,1], ang=0) = 
    assert( is_vector(ax,3) && is_finite(ang), "Invalid input")
    let( n = norm(ax) )
    approx(n,0) 
    ? _Quat([0,0,0], sin(ang/2), cos(ang/2))
    : _Quat(ax/n, sin(ang/2), cos(ang/2));


// Function: QuatX()
// Usage:
//   QuatX(a);
// Description: Create a normalized Quaternion for rotating around the X axis [1,0,0].
// Arguments:
//   a = Number of degrees to rotate around the axis counter-clockwise, when facing the origin.
function QuatX(a=0) = 
    assert( is_finite(a), "Invalid angle" )
    Quat([1,0,0],a);


// Function: QuatY()
// Usage:
//   QuatY(a);
// Description: Create a normalized Quaternion for rotating around the Y axis [0,1,0].
// Arguments:
//   a = Number of degrees to rotate around the axis counter-clockwise, when facing the origin.
function QuatY(a=0) =  
    assert( is_finite(a), "Invalid angle" )
    Quat([0,1,0],a);


// Function: QuatZ()
// Usage:
//   QuatZ(a);
// Description: Create a normalized Quaternion for rotating around the Z axis [0,0,1].
// Arguments:
//   a = Number of degrees to rotate around the axis counter-clockwise, when facing the origin.
function QuatZ(a=0) =  
    assert( is_finite(a), "Invalid angle" )
    Quat([0,0,1],a);


// Function: QuatXYZ()
// Usage:
//   QuatXYZ([X,Y,Z])
// Description:
//   Creates a normalized quaternion from standard [X,Y,Z] rotation angles in degrees.
// Arguments:
//   a = The triplet of rotation angles, [X,Y,Z]
function QuatXYZ(a=[0,0,0]) =
    assert( is_vector(a,3), "Invalid angles")
    let(
      qx = QuatX(a[0]),
      qy = QuatY(a[1]),
      qz = QuatZ(a[2])
    )
    Q_Mul(qz, Q_Mul(qy, qx));


// Function: Q_From_to()
// Usage:
//    q = Q_From_to(v1, v2);
// Description: 
//   Returns the normalized quaternion that rotates the non zero 3D vector v1 
//   to the non zero 3D vector v2.
function Q_From_to(v1, v2) =
    assert( is_vector(v1,3) && is_vector(v2,3) 
            && ! approx(norm(v1),0) && ! approx(norm(v2),0)
            , "Invalid vector(s)")
    let( ax = cross(v1,v2),
         n  = norm(ax) )
    approx(n, 0)
    ? v1*v2>0 ? Q_Ident() : Quat([ v1.y, -v1.x, 0], 180)  
    : Quat(ax, atan2( n , v1*v2 ));


// Function: Q_Ident()
// Description: Returns the "Identity" zero-rotation Quaternion.
function Q_Ident() = [0, 0, 0, 1];


// Function: Q_Add_S()
// Usage:
//   Q_Add_S(q, s)
// Description: 
//   Adds a scalar value `s` to the W part of a quaternion `q`.
//   The returned quaternion is usually not normalized.
function Q_Add_S(q, s) =  
    assert( is_finite(s), "Invalid scalar" )
    q+[0,0,0,s];


// Function: Q_Sub_S()
// Usage:
//   Q_Sub_S(q, s)
// Description: 
//   Subtracts a scalar value `s` from the W part of a quaternion `q`.
//   The returned quaternion is usually not normalized.
function Q_Sub_S(q, s) =  
    assert( is_finite(s), "Invalid scalar" )
    q-[0,0,0,s];


// Function: Q_Mul_S()
// Usage:
//   Q_Mul_S(q, s)
// Description: 
//   Multiplies each part of a quaternion `q` by a scalar value `s`.
//   The returned quaternion is usually not normalized.
function Q_Mul_S(q, s) =  
    assert( is_finite(s), "Invalid scalar" )
    q*s;


// Function: Q_Div_S()
// Usage:
//   Q_Div_S(q, s)
// Description: 
//   Divides each part of a quaternion `q` by a scalar value `s`.
//   The returned quaternion is usually not normalized.
function Q_Div_S(q, s) =   
    assert( is_finite(s) && ! approx(s,0) , "Invalid scalar" )
    q/s;


// Function: Q_Add()
// Usage:
//   Q_Add(a, b)
// Description: 
//   Adds each part of two quaternions together.
//   The returned quaternion is usually not normalized.
function Q_Add(a, b) = 
    assert( Q_is_quat(a) && Q_is_quat(a), "Invalid quaternion(s)") 
    assert( ! approx(norm(a+b),0), "Quaternions cannot be opposed" )
    a+b;


// Function: Q_Sub()
// Usage:
//   Q_Sub(a, b)
// Description: 
//   Subtracts each part of quaternion `b` from quaternion `a`.
//   The returned quaternion is usually not normalized.
function Q_Sub(a, b) = 
    assert( Q_is_quat(a) && Q_is_quat(a), "Invalid quaternion(s)") 
    assert( ! approx(a,b), "Quaternions cannot be equal" )
    a-b;


// Function: Q_Mul()
// Usage:
//   Q_Mul(a, b)
// Description: 
//   Multiplies quaternion `a` by quaternion `b`.
//   The returned quaternion is normalized if both `a` and `b` are normalized
function Q_Mul(a, b) = 
    assert( Q_is_quat(a) && Q_is_quat(b), "Invalid quaternion(s)")
    [
      a[3]*b.x  + a.x*b[3] + a.y*b.z  - a.z*b.y,
      a[3]*b.y  - a.x*b.z  + a.y*b[3] + a.z*b.x,
      a[3]*b.z  + a.x*b.y  - a.y*b.x  + a.z*b[3],
      a[3]*b[3] - a.x*b.x  - a.y*b.y  - a.z*b.z,
    ];


// Function: Q_Cumulative()
// Usage:
//   Q_Cumulative(v);
// Description:
//   Given a list of Quaternions, cumulatively multiplies them, returning a list
//   of each cumulative Quaternion product.  It starts with the first quaternion
//   given in the list, and applies successive quaternion rotations in list order.
//   The quaternion in the returned list are normalized if each quaternion in v
//   is normalized.
function Q_Cumulative(v, _i=0, _acc=[]) = 
    _i==len(v) ? _acc :
    Q_Cumulative(
        v, _i+1,
        concat(
            _acc,
            [_i==0 ? v[_i] : Q_Mul(v[_i], last(_acc))]
        )
    );


// Function: Q_Dot()
// Usage:
//   Q_Dot(a, b)
// Description: Calculates the dot product between quaternions `a` and `b`.
function Q_Dot(a, b) = 
    assert( Q_is_quat(a) && Q_is_quat(b), "Invalid quaternion(s)" )
    a*b;

// Function: Q_Neg()
// Usage:
//   Q_Neg(q)
// Description: Returns the negative of quaternion `q`.
function Q_Neg(q) = 
    assert( Q_is_quat(q), "Invalid quaternion" )
    -q;


// Function: Q_Conj()
// Usage:
//   Q_Conj(q)
// Description: Returns the conjugate of quaternion `q`.
function Q_Conj(q) = 
    assert( Q_is_quat(q), "Invalid quaternion" )
    [-q.x, -q.y, -q.z, q[3]];


// Function: Q_Inverse()
// Usage:
//   qc = Q_Inverse(q)
// Description: Returns the multiplication inverse of quaternion `q`  that is normalized only if `q` is normalized.
function Q_Inverse(q) = 
    assert( Q_is_quat(q), "Invalid quaternion" )
    let(q = _Qnorm(q) )
    [-q.x, -q.y, -q.z, q[3]];


// Function: Q_Norm()
// Usage:
//   Q_Norm(q)
// Description: 
//   Returns the `norm()` "length" of quaternion `q`.
//   Normalized quaternions have unitary norm. 
function Q_Norm(q) = 
    assert( Q_is_quat(q), "Invalid quaternion" )
    norm(q);


// Function: Q_Normalize()
// Usage:
//   Q_Normalize(q)
// Description: Normalizes quaternion `q`, so that norm([W,X,Y,Z]) == 1.
function Q_Normalize(q) = 
    assert( Q_is_quat(q) , "Invalid quaternion" )
    q/norm(q);


// Function: Q_Dist()
// Usage:
//   Q_Dist(q1, q2)
// Description: Returns the "distance" between two quaternions.
function Q_Dist(q1, q2) =   
    assert( Q_is_quat(q1) && Q_is_quat(q2), "Invalid quaternion(s)" )
    norm(q2-q1);


// Function: Q_Slerp()
// Usage:
//   Q_Slerp(q1, q2, u);
// Description:
//   Returns a quaternion that is a spherical interpolation between two quaternions.
// Arguments:
//   q1 = The first quaternion. (u=0)
//   q2 = The second quaternion. (u=1)
//   u = The proportional value, from 0 to 1, of what part of the interpolation to return.
// Example(3D): Giving `u` as a Scalar
//   a = QuatY(-135);
//   b = QuatXYZ([0,-30,30]);
//   for (u=[0:0.1:1])
//       Qrot(Q_Slerp(a, b, u))
//           right(80) cube([10,10,1]);
//   #sphere(r=80);
// Example(3D): Giving `u` as a Range
//   a = QuatZ(-135);
//   b = QuatXYZ([90,0,-45]);
//   for (q = Q_Slerp(a, b, [0:0.1:1]))
//       Qrot(q) right(80) cube([10,10,1]);
//   #sphere(r=80);
function Q_Slerp(q1, q2, u, _dot) =
    is_undef(_dot) 
    ?   assert(is_finite(u) || is_range(u) || is_vector(u), "Invalid interpolation coefficient(s)")
        assert(Q_is_quat(q1) && Q_is_quat(q2), "Invalid quaternion(s)" )
        let(
          _dot = q1*q2,
          q1   = q1/norm(q1),
          q2   = _dot<0 ? -q2/norm(q2) : q2/norm(q2),
          dot  = abs(_dot)
        )
        ! is_finite(u) ? [for (uu=u) Q_Slerp(q1, q2, uu, dot)] :
        Q_Slerp(q1, q2, u, dot)  
    :   _dot>0.9995 
        ?   _Qnorm(q1 + u*(q2-q1))
        :   let( theta = u*acos(_dot),
                 q3    = _Qnorm(q2 - _dot*q1)
               ) 
            _Qnorm(q1*cos(theta) + q3*sin(theta));


// Function: Q_Matrix3()
// Usage:
//   Q_Matrix3(q);
// Description:
//   Returns the 3x3 rotation matrix for the given normalized quaternion q.
function Q_Matrix3(q) =   
    let( q = Q_Normalize(q) )
    [
      [1-2*q[1]*q[1]-2*q[2]*q[2],   2*q[0]*q[1]-2*q[2]*q[3],   2*q[0]*q[2]+2*q[1]*q[3]],
      [  2*q[0]*q[1]+2*q[2]*q[3], 1-2*q[0]*q[0]-2*q[2]*q[2],   2*q[1]*q[2]-2*q[0]*q[3]],
      [  2*q[0]*q[2]-2*q[1]*q[3],   2*q[1]*q[2]+2*q[0]*q[3], 1-2*q[0]*q[0]-2*q[1]*q[1]]
    ];


// Function: Q_Matrix4()
// Usage:
//   Q_Matrix4(q);
// Description:
//   Returns the 4x4 rotation matrix for the given normalized quaternion q.
function Q_Matrix4(q) =    
    let( q = Q_Normalize(q) )
    [
      [1-2*q[1]*q[1]-2*q[2]*q[2],   2*q[0]*q[1]-2*q[2]*q[3],   2*q[0]*q[2]+2*q[1]*q[3], 0],
      [  2*q[0]*q[1]+2*q[2]*q[3], 1-2*q[0]*q[0]-2*q[2]*q[2],   2*q[1]*q[2]-2*q[0]*q[3], 0],
      [  2*q[0]*q[2]-2*q[1]*q[3],   2*q[1]*q[2]+2*q[0]*q[3], 1-2*q[0]*q[0]-2*q[1]*q[1], 0],
      [                        0,                         0,                         0, 1]
    ];


// Function: Q_Axis()
// Usage:
//   Q_Axis(q)
// Description:
//   Returns the axis of rotation of a normalized quaternion `q`.
//   The input doesn't need to be normalized.
function Q_Axis(q) =   
    assert( Q_is_quat(q) , "Invalid quaternion" )
    let( d = norm(_Qvec(q)) )
    approx(d,0)? [0,0,1] : _Qvec(q)/d;

// Function: Q_Angle()
// Usage:
//   a = Q_Angle(q)
//   a12 = Q_Angle(q1,q2);
// Description:
//   If only q1 is given, returns the angle of rotation (in degrees) of that quaternion.
//   If both q1 and q2 are given, returns the angle (in degrees) between them.
//   The input quaternions don't need to be normalized.
function Q_Angle(q1,q2) =
    assert(Q_is_quat(q1) && (is_undef(q2) || Q_is_quat(q2)), "Invalid quaternion(s)" )
    let( n1 = is_undef(q2)? norm(_Qvec(q1)): norm(q1) )
    is_undef(q2) 
    ?   2 * atan2(n1,_Qreal(q1))
    :   let( q1 = q1/norm(q1),
             q2 = q2/norm(q2) )
        4 * atan2(norm(q1 - q2), norm(q1 + q2));

// Function&Module: Qrot()
// Usage: As Module
//   Qrot(q) ...
// Usage: As Function
//   pts = Qrot(q,p);
// Description:
//   When called as a module, rotates all children by the rotation stored in quaternion `q`.
//   When called as a function with a `p` argument, rotates the point or list of points in `p` by the rotation stored in quaternion `q`.
//   When called as a function without a `p` argument, returns the affine3d rotation matrix for the rotation stored in quaternion `q`.
// Example(FlatSpin,VPD=225,VPT=[71,-26,16]):
//   module shape() translate([80,0,0]) cube([10,10,1]);
//   q = QuatXYZ([90,-15,-45]);
//   Qrot(q) shape();
//   #shape();
// Example(NORENDER):
//   q = QuatXYZ([45,35,10]);
//   mat4x4 = Qrot(q);
// Example(NORENDER):
//   q = QuatXYZ([45,35,10]);
//   pt = Qrot(q, p=[4,5,6]);
// Example(NORENDER):
//   q = QuatXYZ([45,35,10]);
//   pts = Qrot(q, p=[[2,3,4], [4,5,6], [9,2,3]]);
module Qrot(q) {
    multmatrix(Q_Matrix4(q)) {
        children();
    }
}

function Qrot(q,p) =
      is_undef(p)? Q_Matrix4(q) :
      is_vector(p)? Qrot(q,[p])[0] :
      apply(Q_Matrix4(q), p);


// Module: Qrot_copies()
// Usage:
//   Qrot_copies(quats) ...
// Description:
//   For each quaternion given in the list `quats`, rotates to that orientation and creates a copy
//   of all children.  This is equivalent to `for (q=quats) Qrot(q) ...`.
// Arguments:
//   quats = A list containing all quaternions to rotate to and create copies of all children for.
// Example:
//   a = QuatZ(-135);
//   b = QuatXYZ([0,-30,30]);
//   Qrot_copies(Q_Slerp(a, b, [0:0.1:1]))
//       right(80) cube([10,10,1]);
//   #sphere(r=80);
module Qrot_copies(quats) for (q=quats) Qrot(q) children();


// Function: Q_Rotation()
// Usage:
//   Q_Rotation(R)
// Description:
//   Returns a normalized quaternion corresponding to the rotation matrix R.
//   R may be a 3x3 rotation matrix or a homogeneous 4x4 rotation matrix.
//   The last row and last column of R are ignored for 4x4 matrices.
//   It doesn't check whether R is in fact a rotation matrix.
//   If R is not a rotation, the returned quaternion is an unpredictable quaternion .
function Q_Rotation(R) =
    assert( is_matrix(R,3,3) || is_matrix(R,4,4) , 
                      "Matrix is neither 3x3 nor 4x4")
    let( tr = R[0][0]+R[1][1]+R[2][2] ) // R trace
    tr>0 
    ?   let( r = 1+tr  )
        _Qnorm( _Qset([ R[1][2]-R[2][1], R[2][0]-R[0][2], R[0][1]-R[1][0] ], -r ) )
    :   let( i = max_index([ R[0][0], R[1][1], R[2][2] ]),
             r = 1 + 2*R[i][i] -R[0][0] -R[1][1] -R[2][2] )
        i==0 ? _Qnorm( _Qset( [ 4*r, (R[1][0]+R[0][1]), (R[0][2]+R[2][0]) ], (R[2][1]-R[1][2])) ):
        i==1 ? _Qnorm( _Qset( [ (R[1][0]+R[0][1]), 4*r, (R[2][1]+R[1][2]) ], (R[0][2]-R[2][0])) ):
            _Qnorm( _Qset( [ (R[2][0]+R[0][2]), (R[1][2]+R[2][1]), 4*r ], (R[1][0]-R[0][1])) ) ;


// Function&Module: Q_Rotation_path()
// Usage: As a function
//   path = Q_Rotation_path(q1, n, q2);
//   path = Q_Rotation_path(q1, n);
// Usage: As a module
//   Q_Rotation_path(q1, n, q2) ...
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
//   a = QuatY(-135);
//   b = QuatXYZ([0,-30,30]);
//   for (M=Q_Rotation_path(a, 10, b))
//       multmatrix(M)
//           right(80) cube([10,10,1]);
//   #sphere(r=80);
// Example(3D): as a module
//   a = QuatY(-135);
//   b = QuatXYZ([0,-30,30]);
//   Q_Rotation_path(a, 10, b)
//      right(80) cube([10,10,1]);
//   #sphere(r=80);
// Example(3D): as a function
//   a = QuatY(5);
//   for (M=Q_Rotation_path(a, 10))
//       multmatrix(M)
//           right(80) cube([10,10,1]);
//   #sphere(r=80);
// Example(3D): as a module
//   a = QuatY(5);
//   Q_Rotation_path(a, 10)
//      right(80) cube([10,10,1]);
//   #sphere(r=80);
function Q_Rotation_path(q1, n=1, q2) =
    assert( Q_is_quat(q1) && (is_undef(q2) || Q_is_quat(q2) ), "Invalid quaternion(s)" )
    assert( is_finite(n) && n>=1 && n==floor(n), "Invalid integer" )
    assert( is_undef(q2) || ! approx(norm(q1+q2),0), "Quaternions cannot be opposed" )
    is_undef(q2) 
    ?   [for( i=0, dR=Q_Matrix4(q1), R=dR; i<=n; i=i+1, R=dR*R ) R] 
    :   let( q2 = Q_Normalize( q1*q2<0 ? -q2: q2 ),
             dq = Q_pow( Q_Mul( q2, Q_Inverse(q1) ), 1/n ),
             dR = Q_Matrix4(dq) )
        [for( i=0, R=Q_Matrix4(q1); i<=n; i=i+1, R=dR*R ) R];

module Q_Rotation_path(q1, n=1, q2) {
    for(Mi=Q_Rotation_path(q1, n, q2))
        multmatrix(Mi)
            children();
}


// Function: Q_Nlerp()
// Usage:
//   q = Q_Nlerp(q1, q2, u);
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
//   a = QuatY(-135);
//   b = QuatXYZ([0,-30,30]);
//   for (u=[0:0.1:1])
//       Qrot(Q_Nlerp(a, b, u))
//           right(80) cube([10,10,1]);
//   #sphere(r=80);
// Example(3D): Giving `u` as a Range
//   a = QuatZ(-135);
//   b = QuatXYZ([90,0,-45]);
//   for (q = Q_Nlerp(a, b, [0:0.1:1]))
//       Qrot(q) right(80) cube([10,10,1]);
//   #sphere(r=80);
function Q_Nlerp(q1,q2,u) =
    assert(is_finite(u) || is_range(u) || is_vector(u) ,
           "Invalid interpolation coefficient(s)" )
    assert(Q_is_quat(q1) && Q_is_quat(q2), "Invalid quaternion(s)" )
    assert( ! approx(norm(q1+q2),0), "Quaternions cannot be opposed" )
    let( q1  = Q_Normalize(q1),
         q2  = Q_Normalize(q2) )
    is_num(u) 
    ? _Qnorm((1-u)*q1 + u*q2 )
    : [for (ui=u) _Qnorm((1-ui)*q1 + ui*q2 ) ];


// Function: Q_Squad()
// Usage:
//   qn = Q_Squad(q1,q2,q3,q4,u);
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
//   a = QuatY(-135);
//   b = QuatXYZ([-50,-50,120]);
//   c = QuatXYZ([-50,-40,30]);
//   d = QuatY(-45);
//   color("red"){
//     Qrot(b) right(80) cube([10,10,1]);
//     Qrot(c) right(80) cube([10,10,1]);
//   }
//   for (u=[0:0.05:1])
//       Qrot(Q_Squad(a, b, c, d, u))
//           right(80) cube([10,10,1]);
//   #sphere(r=80);
// Example(3D): Giving `u` as a Range
//   a = QuatY(-135);
//   b = QuatXYZ([-50,-50,120]);
//   c = QuatXYZ([-50,-40,30]);
//   d = QuatY(-45);
//   for (q = Q_Squad(a, b, c, d, [0:0.05:1]))
//       Qrot(q) right(80) cube([10,10,1]);
//   #sphere(r=80);
function Q_Squad(q1,q2,q3,q4,u) =
    assert(is_finite(u) || is_range(u) || is_vector(u) ,
           "Invalid interpolation coefficient(s)" )
    is_num(u) 
    ? Q_Slerp( Q_Slerp(q1,q4,u), Q_Slerp(q2,q3,u), 2*u*(1-u))
    : [for(ui=u) Q_Slerp( Q_Slerp(q1,q4,ui), Q_Slerp(q2,q3,ui), 2*ui*(1-ui) ) ];


// Function: Q_exp()
// Usage:
//   q2 = Q_exp(q);
// Description:
//   Returns the quaternion that is the exponential of the quaternion q in base e
//   The returned quaternion is usually not normalized.
function Q_exp(q) =
    assert( is_vector(q,4), "Input is not a valid quaternion")
    let( nv = norm(_Qvec(q)) ) // q may be equal to zero here!
    exp(_Qreal(q))*Quat(_Qvec(q),2*nv);


// Function: Q_ln()
// Usage:
//   q2 = Q_ln(q);
// Description:
//   Returns the quaternion that is the natural logarithm of the quaternion q.
//   The returned quaternion is usually not normalized and may be zero.
function Q_ln(q) =
    assert(Q_is_quat(q), "Input is not a valid quaternion")
    let( nq = norm(q),
         nv = norm(_Qvec(q)) )
    approx(nv,0) ? _Qset([0,0,0] , ln(nq) ) :
    _Qset(_Qvec(q)*atan2(nv,_Qreal(q))/nv, ln(nq));


// Function: Q_pow()
// Usage:
//   q2 = Q_pow(q, r);
// Description:
//   Returns the quaternion that is the power of the quaternion q to the real exponent r.
//   The returned quaternion is normalized if `q` is normalized.
function Q_pow(q,r=1) =
    assert( Q_is_quat(q) && is_finite(r),
             "Invalid inputs")
    let( theta = 2*atan2(norm(_Qvec(q)),_Qreal(q)) )
    Quat(_Qvec(q), r*theta); //  Q_exp(r*Q_ln(q)); 



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
