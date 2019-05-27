//////////////////////////////////////////////////////////////////////
// LibFile: affine.scad
//   Matrix math and affine transformation matrices.
//   To use, add the following lines to the beginning of your file:
//   ```
//   use <BOSL2/std.scad>
//   ```
//////////////////////////////////////////////////////////////////////


// Section: Matrix Manipulation

// Function: ident()
// Description: Create an `n` by `n` identity matrix.
// Arguments:
//   n = The size of the identity matrix square, `n` by `n`.
function ident(n) = [for (i = [0:1:n-1]) [for (j = [0:1:n-1]) (i==j)?1:0]];


// Function: affine2d_to_affine3d()
// Description: Takes a 3x3 affine2d matrix and returns its 4x4 affine3d equivalent.
function mat3_to_mat4(m) = concat(
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
// Description: Create a 3x3 affine2d identity matrix.
function affine2d_identity() = ident(3);


// Function: affine2d_translate()
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
// Description:
//   Returns the 3x3 affine2d matrix to perform a rotation of a 2D vector around the Z axis.
// Arguments:
//   ang = Number of degrees to rotate.
function affine2d_zrot(ang) = [
	[cos(ang), -sin(ang), 0],
	[sin(ang),  cos(ang), 0],
	[       0,         0, 1]
];


// Function: affine2d_skew()
// Usage:
//   affine2d_skew(xa, ya)
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
//   affine2d_chain(affines)
// Description:
//   Returns a 3x3 affine2d transformation matrix which results from applying each matrix in `affines` in order.
// Arguments:
//   affines = A list of 3x3 affine2d matrices.
function affine2d_chain(affines, _m=undef, _i=0) =
	(_i>=len(affines))? (is_undef(_m)? ident(3) : _m) :
	affine2d_chain(affines, _m=(is_undef(_m)? affines[_i] : affines[_i] * _m), _i=_i+1);


// Function: affine2d_apply()
// Usage:
//   affine2d_apply(pts, affines)
// Description:
//   Given a list of 3x3 affine2d transformation matrices, applies them in order to the points in the point list.
// Arguments:
//   pts = A list of 2D points to transform.
//   affines = A list of 3x3 affine2d matrices to apply, in order.
// Example:
//   npts = affine2d_apply(
//       pts = [for (x=[0:3]) [5*x,0]],
//       affines =[
//           affine2d_scale([3,1]),
//           affine2d_rot(90),
//           affine2d_translate([5,5])
//       ]
//   );  // Returns [[5,5], [5,20], [5,35], [5,50]]
function affine2d_apply(pts, affines) =
	let(m = affine2d_chain(affines))
	[for (p = pts) point2d(m * concat(point2d(p),[1]))];



// Section: Affine3d 4x4 Transformation Matrices


// Function: affine3d_identity()
// Description: Create a 4x4 affine3d identity matrix.
function affine3d_identity() = ident(4);


// Function: affine3d_translate()
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
//   affine3d_zrot(ang)
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
//   affine3d_rot_by_axis(u, ang);
// Description:
//   Returns the 4x4 affine3d matrix to perform a rotation of a 3D vector around an axis.
// Arguments:
//   u = 3D axis vector to rotate around.
//   ang = number of degrees to rotate.
function affine3d_rot_by_axis(u, ang) = let(
	u = normalize(u),
	c = cos(ang),
	c2 = 1-c,
	s = sin(ang)
) [
	[u[0]*u[0]*c2+c     , u[0]*u[1]*c2-u[2]*s, u[0]*u[2]*c2+u[1]*s, 0],
	[u[1]*u[0]*c2+u[2]*s, u[1]*u[1]*c2+c     , u[1]*u[2]*c2-u[0]*s, 0],
	[u[2]*u[0]*c2-u[1]*s, u[2]*u[1]*c2+u[0]*s, u[2]*u[2]*c2+c     , 0],
	[                  0,                   0,                   0, 1]
];


// Function: affine3d_rot_from_to()
// Usage:
//   affine3d_rot_from_to(from, to);
// Description:
//   Returns the 4x4 affine3d matrix to perform a rotation of a 3D vector from one vector direction to another.
// Arguments:
//   from = 3D axis vector to rotate from.
//   to = 3D axis vector to rotate to.
function affine3d_rot_from_to(from, to) = let(
	u = vector_axis(from,to),
	ang = vector_angle(from,to),
	c = cos(ang),
	c2 = 1-c,
	s = sin(ang)
) [
	[u[0]*u[0]*c2+c     , u[0]*u[1]*c2-u[2]*s, u[0]*u[2]*c2+u[1]*s, 0],
	[u[1]*u[0]*c2+u[2]*s, u[1]*u[1]*c2+c     , u[1]*u[2]*c2-u[0]*s, 0],
	[u[2]*u[0]*c2-u[1]*s, u[2]*u[1]*c2+u[0]*s, u[2]*u[2]*c2+c     , 0],
	[                  0,                   0,                   0, 1]
];


// Function: affine3d_skew_xy()
// Usage:
//   affine3d_skew_xy(xa, ya)
// Description:
//   Returns the 4x4 affine3d matrix to perform a skew transformation along the XY plane..
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
//   affine3d_skew_xz(xa, za)
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
//   affine3d_skew_yz(ya, za)
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
//   affine3d_chain(affines)
// Description:
//   Returns a 4x4 affine3d transformation matrix which results from applying each matrix in `affines` in order.
// Arguments:
//   affines = A list of 4x4 affine3d matrices.
function affine3d_chain(affines, _m=undef, _i=0) =
	(_i>=len(affines))? (is_undef(_m)? ident(4) : _m) :
	affine3d_chain(affines, _m=(is_undef(_m)? affines[_i] : affines[_i] * _m), _i=_i+1);


// Function: affine3d_apply()
// Usage:
//   affine3d_apply(pts, affines)
// Description:
//   Given a list of affine3d transformation matrices, applies them in order to the points in the point list.
// Arguments:
//   pts = A list of 3D points to transform.
//   affines = A list of 4x4 matrices to apply, in order.
// Example:
//   npts = affine3d_apply(
//     pts = [for (x=[0:3]) [5*x,0,0]],
//     affines =[
//       affine3d_scale([2,1,1]),
//       affine3d_zrot(90),
//       affine3d_translate([5,5,10])
//     ]
//   );  // Returns [[5,5,10], [5,15,10], [5,25,10], [5,35,10]]
function affine3d_apply(pts, affines) =
	let(m = affine3d_chain(affines))
	[for (p = pts) point3d(m * concat(point3d(p),[1]))];



// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
