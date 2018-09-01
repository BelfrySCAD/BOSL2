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


function Cpi() = 3.141592653589793236;


// Quantize a value x to an integer multiple of y, rounding to the nearest multiple.
function quant(x,y) = floor(x/y+0.5)*y;


// Quantize a value x to an integer multiple of y, rounding down to the previous multiple.
function quantdn(x,y) = floor(x/y)*y;


// Quantize a value x to an integer multiple of y, rounding up to the next multiple.
function quantup(x,y) = ceil(x/y)*y;


// Calculate OpenSCAD standard number of segments in a circle based on $fn, $fa, and $fs.
//   r = radius of circle to get the number of segments for.
function segs(r) = $fn>0?($fn>3?$fn:3):(ceil(max(min(360.0/$fa,abs(r)*2*Cpi()/$fs),5)));


// Interpolate between two values or vectors.  0.0 <= u <= 1.0
function lerp(a,b,u) = (b-a)*u + a;


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
	(end<start)?
		concat(
			[for (i=[start:len(list)-1]) list[i]],
			[for (i=[0:end]) list[i]]
		)
	:
		[for (i=[start:end]) list[i]]
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
	c = cos(ang), c2 = 1-c, s = sin(ang)
) [
	[u[0]*u[0]*c2+c,      u[0]*u[1]*c2-u[2]*s, u[0]*u[2]*c2+u[1]*s],
	[u[1]*u[0]*c2+u[2]*s, u[1]*u[1]*c2+c,      u[1]*u[2]*c2-u[0]*s],
	[u[2]*u[0]*c2-u[1]*s, u[2]*u[1]*c2+u[0]*s, u[2]*u[2]*c2+c     ]
];


// Returns the 4x4 matrix to perform a rotation of a vector around an axis.
//   u = axis vector to rotate around.
//   ang = number of degrees to rotate.
function matrix4_rot_by_axis(u, ang) = mat3_to_mat4(matrix3_rot_by_axis(u, ang));


// Gives the sum of a series of sines, at a given angle.
//   a = angle to get the value for.
//   sines = array of [amplitude, frequency] pairs, where the frequency is the
//           number of times the cycle repeats around the circle.
function sum_of_sines(a,sines) = len(sines)==0? 0 :
	len(sines)==1?sines[0][0]*sin(a*sines[0][1]+(len(sines[0])>2?sines[0][2]:0)):
	sum_of_sines(a,[sines[0]])+sum_of_sines(a,cdr(sines));


// Returns unit length normalized version of vector v.
function normalize(v) = v/norm(v);

// Returns angle in degrees between two 2D vectors.
function vector2d_angle(v1,v2) = atan2(v1[1],v1[0]) - atan2(v2[1],v2[0]);

// Returns angle in degrees between two 3D vectors.
function vector3d_angle(v1,v2) = acos((v1*v2)/(norm(v1)*norm(v2)));

// Returns a slice of an array.  An index of 0 is the array start, -1 is array end
function slice(arr,st,end) = let(
		s=st<0?(len(arr)+st):st,
		e=end<0?(len(arr)+end+1):end
	) [for (i=[s:e-1]) if (e>s) arr[i]];



// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
