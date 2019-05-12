//////////////////////////////////////////////////////////////////////
// LibFile: matrices.scad
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
function ident(n) = [for (i = [0:n-1]) [for (j = [0:n-1]) (i==j)?1:0]];


// Function: matrix_transpose()
// Description: Returns the transposition of the given matrix.
// Example:
//   m = [
//       [11,12,13,14],
//       [21,22,23,24],
//       [31,32,33,34],
//       [41,42,43,44]
//   ];
//   tm = matrix_transpose(m);
//   // Returns:
//   // [
//   //     [11,21,31,41],
//   //     [12,22,32,42],
//   //     [13,23,33,43],
//   //     [14,24,34,44]
//   // ]
function matrix_transpose(m) = [for (i=[0:len(m[0])-1]) [for (j=[0:len(m)-1]) m[j][i]]];



// Function: mat3_to_mat4()
// Description: Takes a 3x3 matrix and returns its 4x4 affine equivalent.
function mat3_to_mat4(m) = concat(
	[for (r = [0:2])
		concat(
			[for (c = [0:2]) m[r][c]],
			[0]
		)
	],
	[[0, 0, 0, 1]]
);



// Section: Affine Transformation 3x3 Matrices


// Function: matrix3_translate()
// Description:
//   Returns the 3x3 matrix to perform a 2D translation.
// Arguments:
//   v = 2D Offset to translate by.  [X,Y]
function matrix3_translate(v) = [
	[1, 0, v.x],
	[0, 1, v.y],
	[0 ,0,   1]
];


// Function: matrix3_scale()
// Description:
//   Returns the 3x3 matrix to perform a 2D scaling transformation.
// Arguments:
//   v = 2D vector of scaling factors.  [X,Y]
function matrix3_scale(v) = [
	[v.x,   0, 0],
	[  0, v.y, 0],
	[  0,   0, 1]
];


// Function: matrix3_zrot()
// Description:
//   Returns the 3x3 matrix to perform a rotation of a 2D vector around the Z axis.
// Arguments:
//   ang = Number of degrees to rotate.
function matrix3_zrot(ang) = [
	[cos(ang), -sin(ang), 0],
	[sin(ang),  cos(ang), 0],
	[       0,         0, 1]
];


// Function: matrix3_skew()
// Usage:
//   matrix3_skew(xa, ya)
// Description:
//   Returns the 3x3 matrix to skew a 2D vector along the XY plane.
// Arguments:
//   xa = Skew angle, in degrees, in the direction of the X axis.
//   ya = Skew angle, in degrees, in the direction of the Y axis.
function matrix3_skew(xa, ya) = [
	[1,       tan(xa), 0],
	[tan(ya), 1,       0],
	[0,       0,       1]
];


// Function: matrix3_mult()
// Usage:
//   matrix3_mult(matrices)
// Description:
//   Returns a 3x3 transformation matrix which results from applying each matrix in `matrices` in order.
// Arguments:
//   matrices = A list of 3x3 matrices.
function matrix3_mult(matrices, _m=undef, _i=0) =
	(_i>=len(matrices))? (is_undef(_m)? ident(3) : _m) :
	matrix3_mult(matrices, _m=(is_undef(_m)? matrices[_i] : matrices[_i] * _m), _i=_i+1);


// Function: matrix3_apply()
// Usage:
//   matrix3_apply(pts, matrices)
// Description:
//   Given a list of transformation matrices, applies them in order to the points in the point list.
// Arguments:
//   pts = A list of 2D points to transform.
//   matrices = A list of 3x3 matrices to apply, in order.
// Example:
//   npts = matrix3_apply(
//       pts = [for (x=[0:3]) [5*x,0]],
//       matrices =[
//           matrix3_scale([3,1]),
//           matrix3_rot(90),
//           matrix3_translate([5,5])
//       ]
//   );  // Returns [[5,5], [5,20], [5,35], [5,50]]
function matrix3_apply(pts, matrices) =
	let(m = matrix3_mult(matrices))
	[for (p = pts) point2d(m * concat(point2d(p),[1]))];



// Section: Affine Transformation 4x4 Matrices


// Function: matrix4_translate()
// Description:
//   Returns the 4x4 matrix to perform a 3D translation.
// Arguments:
//   v = 3D offset to translate by.  [X,Y,Z]
function matrix4_translate(v) = [
	[1, 0, 0, v.x],
	[0, 1, 0, v.y],
	[0, 0, 1, v.z],
	[0 ,0, 0,   1]
];


// Function: matrix4_scale()
// Description:
//   Returns the 4x4 matrix to perform a 3D scaling transformation.
// Arguments:
//   v = 3D vector of scaling factors.  [X,Y,Z]
function matrix4_scale(v) = [
	[v.x,   0,   0, 0],
	[  0, v.y,   0, 0],
	[  0,   0, v.z, 0],
	[  0,   0,   0, 1]
];


// Function: matrix4_xrot()
// Description:
//   Returns the 4x4 matrix to perform a rotation of a 3D vector around the X axis.
// Arguments:
//   ang = number of degrees to rotate.
function matrix4_xrot(ang) = [
	[1,        0,         0,   0],
	[0, cos(ang), -sin(ang),   0],
	[0, sin(ang),  cos(ang),   0],
	[0,        0,         0,   1]
];


// Function: matrix4_yrot()
// Description:
//   Returns the 4x4 matrix to perform a rotation of a 3D vector around the Y axis.
// Arguments:
//   ang = Number of degrees to rotate.
function matrix4_yrot(ang) = [
	[ cos(ang), 0, sin(ang),   0],
	[        0, 1,        0,   0],
	[-sin(ang), 0, cos(ang),   0],
	[        0, 0,        0,   1]
];


// Function: matrix4_zrot()
// Usage:
//   matrix4_zrot(ang)
// Description:
//   Returns the 4x4 matrix to perform a rotation of a 3D vector around the Z axis.
// Arguments:
//   ang = number of degrees to rotate.
function matrix4_zrot(ang) = [
	[cos(ang), -sin(ang), 0, 0],
	[sin(ang),  cos(ang), 0, 0],
	[       0,         0, 1, 0],
	[       0,         0, 0, 1]
];


// Function: matrix4_rot_by_axis()
// Usage:
//   matrix4_rot_by_axis(u, ang);
// Description:
//   Returns the 4x4 matrix to perform a rotation of a 3D vector around an axis.
// Arguments:
//   u = 3D axis vector to rotate around.
//   ang = number of degrees to rotate.
function matrix4_rot_by_axis(u, ang) = let(
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


// Function: matrix4_skew_xy()
// Usage:
//   matrix4_skew_xy(xa, ya)
// Description:
//   Returns the 4x4 matrix to perform a skew transformation along the XY plane..
// Arguments:
//   xa = Skew angle, in degrees, in the direction of the X axis.
//   ya = Skew angle, in degrees, in the direction of the Y axis.
function matrix4_skew_xy(xa, ya) = [
	[1, 0, tan(xa), 0],
	[0, 1, tan(ya), 0],
	[0, 0,       1, 0],
	[0, 0,       0, 1]
];


// Function: matrix4_skew_xz()
// Usage:
//   matrix4_skew_xz(xa, za)
// Description:
//   Returns the 4x4 matrix to perform a skew transformation along the XZ plane.
// Arguments:
//   xa = Skew angle, in degrees, in the direction of the X axis.
//   za = Skew angle, in degrees, in the direction of the Z axis.
function matrix4_skew_xz(xa, za) = [
	[1, tan(xa), 0, 0],
	[0,       1, 0, 0],
	[0, tan(za), 1, 0],
	[0,       0, 0, 1]
];


// Function: matrix4_skew_yz()
// Usage:
//   matrix4_skew_yz(ya, za)
// Description:
//   Returns the 4x4 matrix to perform a skew transformation along the YZ plane.
// Arguments:
//   ya = Skew angle, in degrees, in the direction of the Y axis.
//   za = Skew angle, in degrees, in the direction of the Z axis.
function matrix4_skew_yz(ya, za) = [
	[      1, 0, 0, 0],
	[tan(ya), 1, 0, 0],
	[tan(za), 0, 1, 0],
	[      0, 0, 0, 1]
];


// Function: matrix4_mult()
// Usage:
//   matrix4_mult(matrices)
// Description:
//   Returns a 4x4 transformation matrix which results from applying each matrix in `matrices` in order.
// Arguments:
//   matrices = A list of 4x4 matrices.
function matrix4_mult(matrices, _m=undef, _i=0) =
	(_i>=len(matrices))? (is_undef(_m)? ident(4) : _m) :
	matrix4_mult(matrices, _m=(is_undef(_m)? matrices[_i] : matrices[_i] * _m), _i=_i+1);


// Function: matrix4_apply()
// Usage:
//   matrix4_apply(pts, matrices)
// Description:
//   Given a list of transformation matrices, applies them in order to the points in the point list.
// Arguments:
//   pts = A list of 3D points to transform.
//   matrices = A list of 4x4 matrices to apply, in order.
// Example:
//   npts = matrix4_apply(
//     pts = [for (x=[0:3]) [5*x,0,0]],
//     matrices =[
//       matrix4_scale([2,1,1]),
//       matrix4_zrot(90),
//       matrix4_translate([5,5,10])
//     ]
//   );  // Returns [[5,5,10], [5,15,10], [5,25,10], [5,35,10]]

function matrix4_apply(pts, matrices) =
	let(m = matrix4_mult(matrices))
	[for (p = pts) point3d(m * concat(point3d(p),[1]))];



// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
