//////////////////////////////////////////////////////////////////////
// Math helper functions.
//////////////////////////////////////////////////////////////////////

/*
BSD 2-Clause License

Copyright (c) 2017, Revar Desmera
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/


function Cpi() = PI;  // Deprecated!  Use the variable PI instead.


// Quantize a value x to an integer multiple of y, rounding to the nearest multiple.
function quant(x,y) = floor(x/y+0.5)*y;


// Quantize a value x to an integer multiple of y, rounding down to the previous multiple.
function quantdn(x,y) = floor(x/y)*y;


// Quantize a value x to an integer multiple of y, rounding up to the next multiple.
function quantup(x,y) = ceil(x/y)*y;


// Calculate OpenSCAD standard number of segments in a circle based on $fn, $fa, and $fs.
//   r = radius of circle to get the number of segments for.
function segs(r) = $fn>0?($fn>3?$fn:3):(ceil(max(min(360.0/$fa,abs(r)*2*PI/$fs),5)));


// Interpolate between two values or vectors.  0.0 <= u <= 1.0
function lerp(a,b,u) = (1-u)*a + u*b;


// Calculate hypotenuse length of 2D triangle.
function hypot(x,y) = sqrt(x*x+y*y);


// Calculate hypotenuse length of 3D triangle.
function hypot3(x,y,z) = sqrt(x*x+y*y+z*z);


// Returns all but the first item of a given array.
function cdr(list) = len(list)>1?[for (i=[1:len(list)-1]) list[i]]:[];


// Reverses a list/array.
function reverse(list) = [ for (i = [len(list)-1 : -1 : 0]) list[i] ];


// Returns a slice of the given array, wrapping around past the beginning, if end < start
function wrap_range(list, start, end) =
	let(
		l = len(list),
		st = start<0? (start%l)+l : (start%l),
		en = end<0? (end%l)+l : (end%l)
	)
	(en<st)?
		concat(
			[for (i=[st:l-1]) list[i]],
			[for (i=[0:en]) list[i]]
		)
	:
		[for (i=[st:en]) list[i]]
;


// Takes an array of arrays and flattens it by one level.
// flatten([[1,2,3], [4,5,[6,7,8]]]) returns [1,2,3,4,5,[6,7,8]]
function flatten(l) = [ for (a = l) for (b = a) b ];


// Returns the sum of all entries in the given array.
// If passed an array of vectors, returns a vector of sums of each part.
// sum([1,2,3]) returns 6.
// sum([[1,2,3], [3,4,5], [5,6,7]]) returns [9, 12, 15]
function sum(v, i=0) = i<len(v)-1 ? v[i] + sum(v, i+1) : v[i];


// Returns the sum of the square of each element of a vector.
function sum_of_squares(v,n=0) = (n>=len(v))? 0 : ((v[n]*v[n]) + sum_of_squares(v,n+1));


// Returns a 3D vector/point from a 2D or 3D vector.
function point3d(p) = [p[0], p[1], ((len(p) < 3)? 0 : p[2])];


// Returns an array of 3D vectors/points from a 2D or 3D vector array.
function path3d(points) = [for (point = points) point3d(point)];


// Returns the distance between a pair of 2D or 3D points.
function distance(p1, p2) = let(d = point3d(p2) - point3d(p1)) hypot3(d[0], d[1], d[2]);


// Multiplies corresponding elements in two vectors.
function vmul(v1, v2) = [for (i = [0:len(v1)-1]) v1[i]*v2[i]];


// Create an identity matrix, for a given number of axes.
function ident(n) = [for (i = [0:n-1]) [for (j = [0:n-1]) (i==j)?1:0]];


// Create an identity matrix, for 3 axes.
ident3 = ident(3);
ident4 = ident(4);


// Takes a 3x3 matrix and returns its 4x4 equivalent.
function mat3_to_mat4(m) = concat(
	[for (r = [0:2])
		concat(
			[for (c = [0:2]) m[r][c]],
			[0]
		)
	],
	[[0, 0, 0, 1]]
);


// Returns the 3x3 matrix to perform a rotation of a vector around the X axis.
//   ang = number of degrees to rotate.
function matrix3_xrot(ang) = [
	[1,        0,         0],
	[0, cos(ang), -sin(ang)],
	[0, sin(ang),  cos(ang)]
];


// Returns the 4x4 matrix to perform a rotation of a vector around the X axis.
//   ang = number of degrees to rotate.
function matrix4_xrot(ang) = mat3_to_mat4(matrix3_xrot(ang));


// Returns the 3x3 matrix to perform a rotation of a vector around the Y axis.
//   ang = number of degrees to rotate.
function matrix3_yrot(ang) = [
	[ cos(ang), 0, sin(ang)],
	[        0, 1,        0],
	[-sin(ang), 0, cos(ang)],
];


// Returns the 4x4 matrix to perform a rotation of a vector around the Y axis.
//   ang = number of degrees to rotate.
function matrix4_yrot(ang) = mat3_to_mat4(matrix3_yrot(ang));


// Returns the 3x3 matrix to perform a rotation of a vector around the Z axis.
//   ang = number of degrees to rotate.
function matrix3_zrot(ang) = [
	[cos(ang), -sin(ang), 0],
	[sin(ang),  cos(ang), 0],
	[       0,         0, 1]
];

// Returns the 4x4 matrix to perform a rotation of a vector around the Z axis.
//   ang = number of degrees to rotate.
function matrix4_zrot(ang) = mat3_to_mat4(matrix3_zrot(ang));


// Returns the 3x3 matrix to perform a rotation of a vector around an axis.
//   u = axis vector to rotate around.
//   ang = number of degrees to rotate.
function matrix3_rot_by_axis(u, ang) = let(
	u = normalize(u),
	c = cos(ang),
	c2 = 1-c, s = sin(ang)
) [
	[u[0]*u[0]*c2+c,      u[0]*u[1]*c2-u[2]*s, u[0]*u[2]*c2+u[1]*s],
	[u[1]*u[0]*c2+u[2]*s, u[1]*u[1]*c2+c,      u[1]*u[2]*c2-u[0]*s],
	[u[2]*u[0]*c2-u[1]*s, u[2]*u[1]*c2+u[0]*s, u[2]*u[2]*c2+c     ]
];


// Returns the 4x4 matrix to perform a rotation of a vector around an axis.
//   u = axis vector to rotate around.
//   ang = number of degrees to rotate.
function matrix4_rot_by_axis(u, ang) = mat3_to_mat4(matrix3_rot_by_axis(u, ang));


// moves each point in an array by a given amount.
function translate_points(pts, v=[0,0,0]) = [for (pt = pts) pt+v];


// Scales each point in an array by a given amount, around a given centerpoint.
function scale_points(pts, v=[0,0,0], cp=[0,0,0]) = [for (pt = pts) [for (i = [0:len(pt)-1]) (pt[i]-cp[i])*v[i]+cp[i]]];


// Rotates each 2D point in an array by a given amount, around a given centerpoint.
function rotate_points2d(pts, ang, cp=[0,0]) = let(
		m = matrix3_zrot(ang)
	) [for (pt = pts) m*point3d(pt-cp)+cp];


// Rotates each 3D point in an array by a given amount, around a given centerpoint.
function rotate_points3d(pts, v=[0,0,0], cp=[0,0,0]) = let(
		m = matrix4_zrot(v[2]) * matrix4_yrot(v[1]) * matrix4_xrot(v[0])
	) [for (pt = pts) m*concat(point3d(pt)-cp, 0)+cp];


// Rotates each 3D point in an array by a given amount, around a given centerpoint and axis.
function rotate_points3d_around_axis(pts, ang, u=[0,0,0], cp=[0,0,0]) = let(
		m = matrix4_rot_by_axis(u, ang)
	) [for (pt = pts) m*concat(point3d(pt)-cp, 0)+cp];


// Gives the sum of a series of sines, at a given angle.
//   a = angle to get the value for.
//   sines = array of [amplitude, frequency] pairs, where the frequency is the
//           number of times the cycle repeats around the circle.
function sum_of_sines(a,sines) = len(sines)==0? 0 :
	len(sines)==1?sines[0][0]*sin(a*sines[0][1]+(len(sines[0])>2?sines[0][2]:0)):
	sum_of_sines(a,[sines[0]])+sum_of_sines(a,cdr(sines));


// Constrains value to a range of values between minval and maxval, inclusive.
//   v = value to constrain.
//   minval = minimum value to return, if out of range.
//   maxval = maximum value to return, if out of range.
function constrain(v, minval, maxval) = min(maxval, max(minval, v));

// Returns unit length normalized version of vector v.
function normalize(v) = v/norm(v);

// Returns angle in degrees between two 2D vectors.
function vector2d_angle(v1,v2) = atan2(v1[1],v1[0]) - atan2(v2[1],v2[0]);

// Returns angle in degrees between two 3D vectors.
// NOTE: constrain() corrects crazy FP rounding errors that exceed acos()'s domain.
function vector3d_angle(v1,v2) = acos(constrain((v1*v2)/(norm(v1)*norm(v2)), -1, 1));


// Convert polar coordinates to cartesian coordinates.
// Returns [X,Y] cartesian coordinates.
//   r = distance from the origin.
//   theta = angle in degrees, counter-clockwise of X+.
// Examples:
//   xy = polar_to_xy(20,30);
//   xy = polar_to_xy([40,60]);
function polar_to_xy(r,theta=undef) = let(
		rad = theta==undef? r[0] : r,
		t = theta==undef? r[1] : theta
	) rad*[cos(t), sin(t)];


// Convert cartesian coordinates to polar coordinates.
// Returns [radius, theta] where theta is the angle counter-clockwise of X+.
//   x = X coordinate.
//   y = Y coordinate.
// Examples:
//   plr = xy_to_polar(20,30);
//   plr = xy_to_polar([40,60]);
function xy_to_polar(x,y=undef) = let(
		xx = y==undef? x[0] : x,
		yy = y==undef? x[1] : y
	) [norm([xx,yy]), atan2(yy,xx)];


// Convert cylindrical coordinates to cartesian coordinates.
// Returns [X,Y,Z] cartesian coordinates.
//   r = distance from the Z axis.
//   theta = angle in degrees, counter-clockwise of X+ on the XY plane.
//   z = Height above XY plane.
// Examples:
//   xyz = cylindrical_to_xyz(20,30,40);
//   xyz = cylindrical_to_xyz([40,60,50]);
function cylindrical_to_xyz(r,theta=undef,z=undef) = let(
		rad = theta==undef? r[0] : r,
		t = theta==undef? r[1] : theta,
		zed = theta==undef? r[2] : z
	) [rad*cos(t), rad*sin(t), zed];


// Convert cartesian coordinates to cylindrical coordinates.
// Returns [radius,theta,Z]. Theta is the angle counter-clockwise
// of X+ on the XY plane.  Z is height above the XY plane.
//   x = X coordinate.
//   y = Y coordinate.
//   z = Z coordinate.
// Examples:
//   cyl = xyz_to_cylindrical(20,30,40);
//   cyl = xyz_to_cylindrical([40,50,70]);
function xyz_to_cylindrical(x,y=undef,z=undef) = let(
		xx = y==undef? x[0] : x,
		yy = y==undef? x[1] : y,
		zz = y==undef? x[2] : z
	) [norm([xx,yy]), atan2(yy,xx), zz];


// Convert spherical coordinates to cartesian coordinates.
// Returns [X,Y,Z] cartesian coordinates.
//   r = distance from origin.
//   theta = angle in degrees, counter-clockwise of X+ on the XY plane.
//   phi = angle in degrees from the vertical Z+ axis.
// Examples:
//   xyz = spherical_to_xyz(20,30,40);
//   xyz = spherical_to_xyz([40,60,50]);
function spherical_to_xyz(r,theta=undef,phi=undef) = let(
		rad = theta==undef? r[0] : r,
		t = theta==undef? r[1] : theta,
		p = theta==undef? r[2] : phi
	) rad*[sin(p)*cos(t), sin(p)*sin(t), cos(p)];


// Convert cartesian coordinates to spherical coordinates.
// Returns [r,theta,phi], where phi is the angle from the Z+ pole,
// and theta is degrees counter-clockwise of X+ on the XY plane.
//   x = X coordinate.
//   y = Y coordinate.
//   z = Z coordinate.
// Examples:
//   sph = xyz_to_spherical(20,30,40);
//   sph = xyz_to_spherical([40,50,70]);
function xyz_to_spherical(x,y=undef,z=undef) = let(
		xx = y==undef? x[0] : x,
		yy = y==undef? x[1] : y,
		zz = y==undef? x[2] : z
	) [norm([xx,yy,zz]), atan2(yy,xx), atan2(norm([xx,yy]),zz)];


// Convert altitude/azimuth/range coordinates to cartesian coordinates.
// Returns [X,Y,Z] cartesian coordinates.
//   alt = altitude angle in degrees above the XY plane.
//   az = azimuth angle in degrees clockwise of Y+ on the XY plane.
//   r = distance from origin.
// Examples:
//   xyz = altaz_to_xyz(20,30,40);
//   xyz = altaz_to_xyz([40,60,50]);
function altaz_to_xyz(alt,az=undef,r=undef) = let(
		p = az==undef? alt[0] : alt,
		t = 90 - (az==undef? alt[1] : az),
		rad = az==undef? alt[2] : r
	) rad*[cos(p)*cos(t), cos(p)*sin(t), sin(p)];

// Convert cartesian coordinates to altitude/azimuth/range coordinates.
// Returns [altitude,azimuth,range], where altitude is angle above the
// XY plane, azimuth is degrees clockwise of Y+ on the XY plane, and
// range is the distance from the origin.
//   x = X coordinate.
//   y = Y coordinate.
//   z = Z coordinate.
// Examples:
//   aa = xyz_to_altaz(20,30,40);
//   aa = xyz_to_altaz([40,50,70]);
function xyz_to_altaz(x,y=undef,z=undef) = let(
		xx = y==undef? x[0] : x,
		yy = y==undef? x[1] : y,
		zz = y==undef? x[2] : z
	) [atan2(zz,norm([xx,yy])), atan2(xx,yy), norm([xx,yy,zz])];


// Returns a slice of an array.  An index of 0 is the array start, -1 is array end
function slice(arr,st,end) = let(
		s=st<0?(len(arr)+st):st,
		e=end<0?(len(arr)+end+1):end
	) [for (i=[s:e-1]) if (e>s) arr[i]];


function first_defined(v) = [for (x = v) if (x!=undef) x][0];



// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
