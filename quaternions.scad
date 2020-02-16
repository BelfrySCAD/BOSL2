///////////////////////////////////////////
// LibFile: quaternions.scad
//   Support for Quaternions.
//   To use, add the following line to the beginning of your file:
//   ```
//   include <BOSL2/std.scad>
//   ```
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


// Function: Quat()
// Usage:
//   Quat(ax, ang);
// Description: Create a new Quaternion from axis and angle of rotation.
// Arguments:
//   ax = Vector of axis of rotation.
//   ang = Number of degrees to rotate around the axis counter-clockwise, when facing the origin.
function Quat(ax=[0,0,1], ang=0) = _Quat(ax/norm(ax), sin(ang/2), cos(ang/2));


// Function: QuatX()
// Usage:
//   QuatX(a);
// Description: Create a new Quaternion for rotating around the X axis [1,0,0].
// Arguments:
//   a = Number of degrees to rotate around the axis counter-clockwise, when facing the origin.
function QuatX(a=0) = Quat([1,0,0],a);


// Function: QuatY()
// Usage:
//   QuatY(a);
// Description: Create a new Quaternion for rotating around the Y axis [0,1,0].
// Arguments:
//   a = Number of degrees to rotate around the axis counter-clockwise, when facing the origin.
function QuatY(a=0) = Quat([0,1,0],a);

// Function: QuatZ()
// Usage:
//   QuatZ(a);
// Description: Create a new Quaternion for rotating around the Z axis [0,0,1].
// Arguments:
//   a = Number of degrees to rotate around the axis counter-clockwise, when facing the origin.
function QuatZ(a=0) = Quat([0,0,1],a);


// Function: QuatXYZ()
// Usage:
//   QuatXYZ([X,Y,Z])
// Description:
//   Creates a quaternion from standard [X,Y,Z] rotation angles in degrees.
// Arguments:
//   a = The triplet of rotation angles, [X,Y,Z]
function QuatXYZ(a=[0,0,0]) =
	let(
		qx = QuatX(a[0]),
		qy = QuatY(a[1]),
		qz = QuatZ(a[2])
	)
	Q_Mul(qz, Q_Mul(qy, qx));


// Function: Q_Ident()
// Description: Returns the "Identity" zero-rotation Quaternion.
function Q_Ident() = [0, 0, 0, 1];


// Function: Q_Add_S()
// Usage:
//   Q_Add_S(q, s)
// Description: Adds a scalar value `s` to the W part of a quaternion `q`.
function Q_Add_S(q, s) = q+[0,0,0,s];


// Function: Q_Sub_S()
// Usage:
//   Q_Sub_S(q, s)
// Description: Subtracts a scalar value `s` from the W part of a quaternion `q`.
function Q_Sub_S(q, s) = q-[0,0,0,s];


// Function: Q_Mul_S()
// Usage:
//   Q_Mul_S(q, s)
// Description: Multiplies each part of a quaternion `q` by a scalar value `s`.
function Q_Mul_S(q, s) = q*s;


// Function: Q_Div_S()
// Usage:
//   Q_Div_S(q, s)
// Description: Divides each part of a quaternion `q` by a scalar value `s`.
function Q_Div_S(q, s) = q/s;


// Function: Q_Add()
// Usage:
//   Q_Add(a, b)
// Description: Adds each part of two quaternions together.
function Q_Add(a, b) = a+b;


// Function: Q_Sub()
// Usage:
//   Q_Sub(a, b)
// Description: Subtracts each part of quaternion `b` from quaternion `a`.
function Q_Sub(a, b) = a-b;


// Function: Q_Mul()
// Usage:
//   Q_Mul(a, b)
// Description: Multiplies quaternion `a` by quaternion `b`.
function Q_Mul(a, b) = [
	a[3]*b.x  + a.x*b[3] + a.y*b.z  - a.z*b.y,
	a[3]*b.y  - a.x*b.z  + a.y*b[3] + a.z*b.x,
	a[3]*b.z  + a.x*b.y  - a.y*b.x  + a.z*b[3],
	a[3]*b[3] - a.x*b.x  - a.y*b.y  - a.z*b.z,
];


// Function: Q_Dot()
// Usage:
//   Q_Dot(a, b)
// Description: Calculates the dot product between quaternions `a` and `b`.
function Q_Dot(a, b) = a[0]*b[0] + a[1]*b[1] + a[2]*b[2] + a[3]*b[3];


// Function: Q_Neg()
// Usage:
//   Q_Neg(q)
// Description: Returns the negative of quaternion `q`.
function Q_Neg(q) = -q;


// Function: Q_Conj()
// Usage:
//   Q_Conj(q)
// Description: Returns the conjugate of quaternion `q`.
function Q_Conj(q) = [-q.x, -q.y, -q.z, q[3]];


// Function: Q_Norm()
// Usage:
//   Q_Norm(q)
// Description: Returns the `norm()` "length" of quaternion `q`.
function Q_Norm(q) = norm(q);


// Function: Q_Normalize()
// Usage:
//   Q_Normalize(q)
// Description: Normalizes quaternion `q`, so that norm([W,X,Y,Z]) == 1.
function Q_Normalize(q) = q/norm(q);


// Function: Q_Dist()
// Usage:
//   Q_Dist(q1, q2)
// Description: Returns the "distance" between two quaternions.
function Q_Dist(q1, q2) = norm(q2-q1);


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
function Q_Slerp(q1, q2, u) =
	assert(is_num(u) || is_num(u[0]))
	!is_num(u)? [for (uu=u) Q_Slerp(q1,q2,uu)] :
    let(
		q1 = Q_Normalize(q1),
		q2 = Q_Normalize(q2),
		dot = Q_Dot(q1, q2)
	) let(
		q2 = dot<0? Q_Neg(q2) : q2,
		dot = dot<0? -dot : dot
	) (dot>0.9995)? Q_Normalize(q1 + (u * (q2-q1))) :
	let(
		dot = constrain(dot,-1,1),
		theta_0 = acos(dot),
		theta = theta_0 * u,
		q3 = Q_Normalize(q2 - q1*dot),
		out = q1*cos(theta) + q3*sin(theta)
	) out;


// Function: Q_Matrix3()
// Usage:
//   Q_Matrix3(q);
// Description:
//   Returns the 3x3 rotation matrix for the given normalized quaternion q.
function Q_Matrix3(q) = [
	[1-2*q[1]*q[1]-2*q[2]*q[2],   2*q[0]*q[1]-2*q[2]*q[3],   2*q[0]*q[2]+2*q[1]*q[3]],
	[  2*q[0]*q[1]+2*q[2]*q[3], 1-2*q[0]*q[0]-2*q[2]*q[2],   2*q[1]*q[2]-2*q[0]*q[3]],
	[  2*q[0]*q[2]-2*q[1]*q[3],   2*q[1]*q[2]+2*q[0]*q[3], 1-2*q[0]*q[0]-2*q[1]*q[1]]
];


// Function: Q_Matrix4()
// Usage:
//   Q_Matrix4(q);
// Description:
//   Returns the 4x4 rotation matrix for the given normalized quaternion q.
function Q_Matrix4(q) = [
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
function Q_Axis(q) = let(d = sqrt(1-(q[3]*q[3]))) (d==0)? [0,0,1] : [q[0]/d, q[1]/d, q[2]/d];


// Function: Q_Angle()
// Usage:
//   Q_Angle(q)
// Description:
// Returns the angle of rotation (in degrees) of a normalized quaternion `q`.
function Q_Angle(q) = 2 * acos(q[3]);


// Function&Module: Qrot()
// Usage: As Module
//   Qrot(q) ...
// Usage: As Function
//   pts = Qrot(q,p);
// Description:
//   When called as a module, rotates all children by the rotation stored in quaternion `q`.
//   When called as a function with a `p` argument, rotates the point or list of points in `p` by the rotation stored in quaternion `q`.
//   When called as a function without a `p` argument, returns the affine3d rotation matrix for the rotation stored in quaternion `q`.
// Example(FlatSpin):
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
	affine3d_apply(p,[Q_Matrix4(q)]);


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


// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
