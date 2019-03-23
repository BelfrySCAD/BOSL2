//////////////////////////////////////////////////////////////////////
// LibFile: math.scad
//   Math helper functions.
//   To use, add the following lines to the beginning of your file:
//   ```
//   use <BOSL/math.scad>
//   ```
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

include <compat.scad>

// Function: Cpi()
// Status: DEPRECATED, use `PI` instead.
// Description:
//   Returns the value of pi.
function Cpi() = PI;  // Deprecated!  Use the variable PI instead.


// Section: Simple Calculations

// Function: quant()
// Description:
//   Quantize a value `x` to an integer multiple of `y`, rounding to the nearest multiple.
// Arguments:
//   x = The value to quantize.
//   y = The multiple to quantize to.
function quant(x,y) = floor(x/y+0.5)*y;


// Function: quantdn()
// Description:
//   Quantize a value `x` to an integer multiple of `y`, rounding down to the previous multiple.
// Arguments:
//   x = The value to quantize.
//   y = The multiple to quantize to.
function quantdn(x,y) = floor(x/y)*y;


// Function: quantup()
// Description:
//   Quantize a value `x` to an integer multiple of `y`, rounding up to the next multiple.
// Arguments:
//   x = The value to quantize.
//   y = The multiple to quantize to.
function quantup(x,y) = ceil(x/y)*y;


// Function: constrain()
// Usage:
//   constrain(v, minval, maxval);
// Description:
//   Constrains value to a range of values between minval and maxval, inclusive.
// Arguments:
//   v = value to constrain.
//   minval = minimum value to return, if out of range.
//   maxval = maximum value to return, if out of range.
function constrain(v, minval, maxval) = min(maxval, max(minval, v));


// Function: posmod()
// Usage:
//   posmod(x,m)
// Description:
//   Returns the positive modulo `m` of `x`.  Value returned will be in the range 0 ... `m`-1.
//   This if useful for normalizing angles to 0 ... 360.
// Arguments:
//   x = The value to constrain.
//   m = Modulo value.
function posmod(x,m) = (x % m + m) % m;


// Function: modrange()
// Usage:
//   modrange(x, y, m, [step])
// Description:
//   Returns a normalized list of values from `x` to `y`, by `step`, modulo `m`.  Wraps if `x` > `y`.
// Arguments:
//   x = The start value to constrain.
//   y = The end value to constrain.
//   m = Modulo value.
//   step = Step by this amount.
// Examples:
//   echo(modrange(90,270,360, step=45));  // Outputs [90,135,180,225,270]
//   echo(modrange(270,90,360, step=45));  // Outputs [270,315,0,45,90]
//   echo(modrange(90,270,360, step=-45));  // Outputs [90,45,0,315,270]
//   echo(modrange(270,90,360, step=-45));  // Outputs [270,225,180,135,90]
function modrange(x, y, m, step=1) =
	let(
		a = posmod(x, m),
		b = posmod(y, m),
		c = step>0? (a>b? b+m : b) : (a<b? b-m : b)
	) [for (i=[a:step:c]) posmod(i,m)];


// Function: segs()
// Description:
//   Calculate the standard number of sides OpenSCAD would give a circle based on `$fn`, `$fa`, and `$fs`.
// Arguments:
//   r = Radius of circle to get the number of segments for.
function segs(r) = $fn>0?($fn>3?$fn:3):(ceil(max(min(360.0/$fa,abs(r)*2*PI/$fs),5)));


// Function: lerp()
// Description: Interpolate between two values or vectors.
// Arguments:
//   a = First value.
//   b = Second value.
//   u = The proportion from `a` to `b` to calculate.  Valid range is 0.0 to 1.0, inclusive.
function lerp(a,b,u) = (1-u)*a + u*b;


// Function: hypot()
// Description: Calculate hypotenuse length of a 2D or 3D triangle.
// Arguments:
//   x = Length on the X axis.
//   y = Length on the Y axis.
//   z = Length on the Z axis.
function hypot(x,y,z=0) = norm([x,y,z]);


// Function: hypot3()
// Status: DEPRECATED, use `norm([x,y,z])` instead.
// Description: Calculate hypotenuse length of 3D triangle.
// Arguments:
//   x = Length on the X axis.
//   y = Length on the Y axis.
//   z = Length on the Z axis.
function hypot3(x,y,z) = norm([x,y,z]);


// Function: distance()
// Status: DEPRECATED, use `norm(p2-p1)` instead.  It's shorter.
// Description: Returns the distance between a pair of 2D or 3D points.
function distance(p1, p2) = norm(point3d(p2)-point3d(p1));


// Function: sinh()
// Description: Takes a radians value `x`, and returns the hyperbolic sine of it.
function sinh(x) = (exp(x)-exp(-x))/2;


// Function: cosh()
// Description: Takes a radians value `x`, and returns the hyperbolic cosine of it.
function cosh(x) = (exp(x)+exp(-x))/2;


// Function: tanh()
// Description: Takes a radians value `x`, and returns the hyperbolic tangent of it.
function tanh(x) = sinh(x)/cosh(x);


// Function: asinh()
// Description: Takes a value `x`, and returns the inverse hyperbolic sine of it in radians.
function asinh(x) = ln(x+sqrt(x*x+1));


// Function: acosh()
// Description: Takes a value `x`, and returns the inverse hyperbolic cosine of it in radians.
function acosh(x) = ln(x+sqrt(x*x-1));


// Function: atanh()
// Description: Takes a value `x`, and returns the inverse hyperbolic tangent of it in radians.
function atanh(x) = ln((1+x)/(1-x))/2;


// Function: sum()
// Description:
//   Returns the sum of all entries in the given array.
//   If passed an array of vectors, returns a vector of sums of each part.
// Arguments:
//   v = The vector to get the sum of.
// Example:
//   sum([1,2,3]);  // returns 6.
//   sum([[1,2,3], [3,4,5], [5,6,7]]);  // returns [9, 12, 15]
function sum(v, i=0, tot=undef) = i>=len(v)? tot : sum(v, i+1, ((tot==undef)? v[i] : tot+v[i]));


// Function: sum_of_squares()
// Description:
//   Returns the sum of the square of each element of a vector.
// Arguments:
//   v = The vector to get the sum of.
// Example:
//   sum_of_squares([1,2,3]);  // returns 14.
function sum_of_squares(v, i=0, tot=0) = sum(vmul(v,v));


// Function: sum_of_sines()
// Usage:
//   sum_of_sines(a,sines)
// Description:
//   Gives the sum of a series of sines, at a given angle.
// Arguments:
//   a = Angle to get the value for.
//   sines = List of [amplitude, frequency, offset] items, where the frequency is the number of times the cycle repeats around the circle.
function sum_of_sines(a, sines) =
	sum([
		for (s = sines) let(
			ss=point3d(s),
			v=ss.x*sin(a*ss.y+ss.z)
		) v
	]);


// Function: mean()
// Description:
//   Returns the mean of all entries in the given array.
//   If passed an array of vectors, returns a vector of mean of each part.
// Arguments:
//   v = The list of values to get the mean of.
// Example:
//   mean([2,3,4]);  // returns 4.5.
//   mean([[1,2,3], [3,4,5], [5,6,7]]);  // returns [4.5, 6, 7.5]
function mean(v) = sum(v)/len(v);


// Section: List/Array Operations

// Function: cdr()
// Status: DEPRECATED, use `slice(list,1,-1)` instead.
// Description: Returns all but the first item of a given array.
// Arguments:
//   list = The list to get the tail of.
function cdr(list) = len(list)<=1? [] : [for (i=[1:len(list)-1]) list[i]];


// Function: any()
// Description: Returns true if any item in list `l` evaluates as true.
// Arguments:
//   l = The list to test for true items.
// Example:
//   any([0,false,undef]);  // Returns false.
//   any([1,false,undef]);  // Returns true.
//   any([1,5,true]);       // Returns true.
function any(l) = sum([for (x=l) x?1:0]) > 0;


// Function: all()
// Description: Returns true if all items in list `l` evaluate as true.
// Arguments:
//   l = The list to test for true items.
// Example:
//   all([0,false,undef]);  // Returns false.
//   all([1,false,undef]);  // Returns false.
//   all([1,5,true]);       // Returns true.
function all(l) = sum([for (x=l) x?1:0]) == len(l);


// Function: in_list()
// Description: Returns true if value `x` is in list `l`.
// Arguments:
//   x = The value to search for.
//   l = The list to search.
//   idx = If given, searches the given subindexes for matches for `x`.
// Example:
//   in_list("bar", ["foo", "bar", "baz"]);  // Returns true.
//   in_list("bee", ["foo", "bar", "baz"]);  // Returns false.
//   in_list("bar", [[2,"foo"], [4,"bar"], [3,"baz"]], idx=1);  // Returns true.
function in_list(x,l,idx=undef) = search([x], l, num_returns_per_match=1, index_col_num=idx) != [[]];


// Function: slice()
// Description:
//   Returns a slice of a list.  The first item is index 0.
//   Negative indexes are counted back from the end.  The last item is -1.
// Arguments:
//   arr = The array/list to get the slice of.
//   st = The index of the first item to return.
//   end = The index after the last item to return, unless negative, in which case the last item to return.
// Example:
//   slice([3,4,5,6,7,8,9], 3, 5);   // Returns [6,7]
//   slice([3,4,5,6,7,8,9], 2, -1);  // Returns [5,6,7,8,9]
//   slice([3,4,5,6,7,8,9], 1, 1);   // Returns []
//   slice([3,4,5,6,7,8,9], 6, -1);  // Returns [9]
//   slice([3,4,5,6,7,8,9], 2, -2);  // Returns [5,6,7,8]
function slice(arr,st,end) = let(
		s=st<0?(len(arr)+st):st,
		e=end<0?(len(arr)+end+1):end
	) (s==e)? [] : [for (i=[s:e-1]) if (e>s) arr[i]];


// Function: wrap_range()
// Description:
//   Returns a portion of a list, wrapping around past the beginning, if end<start. 
//   The first item is index 0. Negative indexes are counted back from the end.
//   The last item is -1.  If only the `start` index is given, returns just the value
//   at that position.
// Usage:
//   wrap_range(list,start)
//   wrap_range(list,start,end)
// Arguments:
//   list = The list to get the portion of.
//   start = The index of the first item.
//   end = The index of the last item.
// Example:
//   l = [3,4,5,6,7,8,9];
//   wrap_range(l, 5, 6);   // Returns [8,9]
//   wrap_range(l, 5, 8);   // Returns [8,9,3,4]
//   wrap_range(l, 5, 2);   // Returns [8,9,3,4,5]
//   wrap_range(l, -3, -1); // Returns [7,8,9]
//   wrap_range(l, 3, 3);   // Returns [6]
//   wrap_range(l, 4);      // Returns 7
//   wrap_range(l, -2);     // Returns 8
//   wrap_range(l, [1:3]);  // Returns [4,5,6]
//   wrap_range(l, [1,3]);  // Returns [4,6]
function wrap_range(list, start, end=undef) =
	let(l = len(list))
	!is_def(end)? (
		is_scalar(start)?
			list[posmod(start, l)] :
			[for (i=start) list[posmod(i, l)]]
	) : [for (i = modrange(start, end, l)) list[i]];


// Function: reverse()
// Description: Reverses a list/array.
// Arguments:
//   list = The list to reverse.
// Example:
//   reverse([3,4,5,6]);  // Returns [6,5,4,3]
function reverse(list) = [ for (i = [len(list)-1 : -1 : 0]) list[i] ];


// Function: array_subindex()
// Description:
//   For each array item, return the indexed subitem.
//   Returns a list of the values of each vector at the specfied
//   index list or range.  If the index list or range has
//   only one entry the output list is flattened.  
// Arguments:
//   v = The given list of lists.
//   idx = The index, list of indices, or range of indices to fetch.
// Example:
//   v = [[[1,2,3,4],[5,6,7,8],[9,10,11,12],[13,14,15,16]];
//   array_subindex(v,2);      // Returns [3, 7, 11, 15]
//   array_subindex(v,[2,1]);  // Returns [[3, 2], [7, 6], [11, 10], [15, 14]]
//   array_subindex(v,[1:3]);  // Returns [[2, 3, 4], [6, 7, 8], [10, 11, 12], [14, 15, 16]]
function array_subindex(v, idx) = [
	for(val=v) let(value=[for(i=idx) val[i]])
		len(value)==1 ? value[0] : value
];


// Function: array_zip()
// Description:
//   Zips together corresponding items from two or more lists.
//   Returns a list of grouped values.
// Arguments:
//   vecs = A list of two or more lists to zipper together.
//   dflt = The default value to fill in with if one or more lists if short.
// Example:
//   v1 = [1,2,3,4];
//   v2 = [5,6,7];
//   v3 = [8,9,10,11];
//   array_zip([v1,v2]);      // returns [[1,5], [2,6], [3,7], [4,undef]]
//   array_zip([v1,v2], 20);  // returns [[1,5], [2,6], [3,7], [4,20]]
//   array_zip([v1,v2,v3]);   // returns [[1,5,8], [2,6,9], [3,7,10], [4,undef,11]]
function array_zip(vecs, dflt=undef) = [
	for (i = [0:max([for (v=vecs) len(v)])-1])
		[for (v = vecs) default(v[i], dflt)]
];


// Function: array_group()
// Description:
//   Takes a flat array of values, and groups items in sets of `cnt` length.
//   The opposite of this is `flatten()`.
// Arguments:
//   v = The list of items to group.
//   cnt = The number of items to put in each grouping.
//   dflt = The default value to fill in with is the list is not a multiple of `cnt` items long.
// Example:
//   v = [1,2,3,4,5,6];
//   array_group(v,2) returns [[1,2], [3,4], [5,6]]
//   array_group(v,3) returns [[1,2,3], [4,5,6]]
//   array_group(v,4,0) returns [[1,2,3,4], [5,6,0,0]]
function array_group(v, cnt=2, dflt=0) = [for (i = [0:cnt:len(v)-1]) [for (j = [0:cnt-1]) default(v[i+j], dflt)]];


// Function: flatten()
// Description: Takes a list of list and flattens it by one level.
// Arguments:
//   l = List to flatten.
// Example:
//   flatten([[1,2,3], [4,5,[6,7,8]]]) returns [1,2,3,4,5,[6,7,8]]
function flatten(l) = [for (a = l) for (b = a) b];


// Section: Vector Manipulation

// Function: vmul()
// Description:
//   Element-wise vector multiplication.  Multiplies each element of vector `v1` by
//   the corresponding element of vector `v2`.  Returns a vector of the products.
// Arguments:
//   v1 = The first vector.
//   v2 = The second vector.
// Example:
//   vmul([3,4,5], [8,7,6]);  // Returns [24, 28, 30]
function vmul(v1, v2) = [for (i = [0:len(v1)-1]) v1[i]*v2[i]];


// Function: vdiv()
// Description:
//   Element-wise vector division.  Divides each element of vector `v1` by
//   the corresponding element of vector `v2`.  Returns a vector of the quotients.
// Arguments:
//   v1 = The first vector.
//   v2 = The second vector.
// Example:
//   vdiv([24,28,30], [8,7,6]);  // Returns [3, 4, 5]
function vdiv(v1, v2) = [for (i = [0:len(v1)-1]) v1[i]/v2[i]];


// Function: vabs()
// Description: Returns a vector of the absolute value of each element of vector `v`.
// Arguments:
//   v = The vector to get the absolute values of.
function vabs(v) = [for (x=v) abs(x)];


// Function: normalize()
// Description:
//   Returns unit length normalized version of vector v.
// Arguments:
//   v = The vector to normalize.
function normalize(v) = v/norm(v);


// Function: vector2d_angle()
// Usage:
//   vector2d_angle(v1,v2);
// Description:
//   Returns angle in degrees between two 2D vectors.
// Arguments:
//   v1 = First 2D vector.
//   v2 = Second 2D vector.
function vector2d_angle(v1,v2) = atan2(v1[1],v1[0]) - atan2(v2[1],v2[0]);

// Function: vector3d_angle()
// Usage:
//   vector3d_angle(v1,v2);
// Description:
//   Returns angle in degrees between two 3D vectors.
// Arguments:
//   v1 = First 3D vector.
//   v2 = Second 3D vector.
// NOTE: constrain() corrects crazy FP rounding errors that exceed acos()'s domain.
function vector3d_angle(v1,v2) = acos(constrain((v1*v2)/(norm(v1)*norm(v2)), -1, 1));


// Section: Coordinates Manipulation

// Function: point2d()
// Description:
//   Returns a 2D vector/point from a 2D or 3D vector.
//   If given a 3D point, removes the Z coordinate.
// Arguments:
//   p = The coordinates to force into a 2D vector/point.
function point2d(p) = [for (i=[0:1]) (p[i]==undef)? 0 : p[i]];


// Function: path2d()
// Description:
//   Returns a list of 2D vectors/points from a list of 2D or 3D vectors/points.
//   If given a 3D point list, removes the Z coordinates from each point.
// Arguments:
//   points = A list of 2D or 3D points/vectors.
function path2d(points) = [for (point = points) point2d(point)];


// Function: point3d()
// Description:
//   Returns a 3D vector/point from a 2D or 3D vector.
// Arguments:
//   p = The coordinates to force into a 3D vector/point.
function point3d(p) = [for (i=[0:2]) (p[i]==undef)? 0 : p[i]];


// Function: path3d()
// Description:
//   Returns a list of 3D vectors/points from a list of 2D or 3D vectors/points.
// Arguments:
//   points = A list of 2D or 3D points/vectors.
function path3d(points) = [for (point = points) point3d(point)];


// Function: translate_points()
// Usage:
//   translate_points(pts, v);
// Description:
//   Moves each point in an array by a given amount.
// Arguments:
//   pts = List of points to translate.
//   v = Amount to translate points by.
function translate_points(pts, v=[0,0,0]) = [for (pt = pts) pt+v];


// Function: scale_points()
// Usage:
//   scale_points(pts, v, [cp]);
// Description:
//   Scales each point in an array by a given amount, around a given centerpoint.
// Arguments:
//   pts = List of points to scale.
//   v = A vector with a scaling factor for each axis.
//   cp = Centerpoint to scale around.
function scale_points(pts, v=[0,0,0], cp=[0,0,0]) = [for (pt = pts) [for (i = [0:len(pt)-1]) (pt[i]-cp[i])*v[i]+cp[i]]];


// Function: rotate_points2d()
// Usage:
//   rotate_points2d(pts, ang, [cp]);
// Description:
//   Rotates each 2D point in an array by a given amount, around an optional centerpoint.
// Arguments:
//   pts = List of 3D points to rotate.
//   ang = Angle to rotate by.
//   cp = 2D Centerpoint to rotate around.  Default: `[0,0]`
function rotate_points2d(pts, ang, cp=[0,0]) = let(
		m = matrix3_zrot(ang)
	) [for (pt = pts) m*point3d(pt-cp)+cp];


// Function: rotate_points3d()
// Usage:
//   rotate_points3d(pts, v, [cp], [reverse]);
// Description:
//   Rotates each 3D point in an array by a given amount, around a given centerpoint.
// Arguments:
//   pts = List of 3D points to rotate.
//   v = Vector of rotation angles for each axis, [X,Y,Z]
//   cp = 3D Centerpoint to rotate around.
//   reverse = If true, performs an exactly reversed rotation.
function rotate_points3d(pts, v=[0,0,0], cp=[0,0,0], reverse=false) = let(
		m = reverse?
			matrix4_xrot(-v[0]) * matrix4_yrot(-v[1]) * matrix4_zrot(-v[2]) :
			matrix4_zrot(v[2]) * matrix4_yrot(v[1]) * matrix4_xrot(v[0])
	) [for (pt = pts) m*concat(point3d(pt)-cp, 0)+cp];


// Function: rotate_points3d_around_axis()
// Usage:
//   rotate_points3d_around_axis(pts, ang, u, [cp])
// Description:
//   Rotates each 3D point in an array by a given amount, around a given centerpoint and axis.
// Arguments:
//   pts = List of 3D points to rotate.
//   ang = Angle to rotate by.
//   u = Vector of the axis to rotate around.
//   cp = 3D Centerpoint to rotate around.
function rotate_points3d_around_axis(pts, ang, u=[0,0,0], cp=[0,0,0]) = let(
		m = matrix4_rot_by_axis(u, ang)
	) [for (pt = pts) m*concat(point3d(pt)-cp, 0)+cp];


// Section: Coordinate Systems

// Function: polar_to_xy()
// Usage:
//   polar_to_xy(r, theta);
//   polar_to_xy([r, theta]);
// Description:
//   Convert polar coordinates to 2D cartesian coordinates.
//   Returns [X,Y] cartesian coordinates.
// Arguments:
//   r = distance from the origin.
//   theta = angle in degrees, counter-clockwise of X+.
// Examples:
//   xy = polar_to_xy(20,30);
//   xy = polar_to_xy([40,60]);
function polar_to_xy(r,theta=undef) = let(
		rad = theta==undef? r[0] : r,
		t = theta==undef? r[1] : theta
	) rad*[cos(t), sin(t)];


// Function: xy_to_polar()
// Usage:
//   xy_to_polar(x,y);
//   xy_to_polar([X,Y]);
// Description:
//   Convert 2D cartesian coordinates to polar coordinates.
//   Returns [radius, theta] where theta is the angle counter-clockwise of X+.
// Arguments:
//   x = X coordinate.
//   y = Y coordinate.
// Examples:
//   plr = xy_to_polar(20,30);
//   plr = xy_to_polar([40,60]);
function xy_to_polar(x,y=undef) = let(
		xx = y==undef? x[0] : x,
		yy = y==undef? x[1] : y
	) [norm([xx,yy]), atan2(yy,xx)];


// Function: cylindrical_to_xyz()
// Usage:
//   cylindrical_to_xyz(r, theta, z)
//   cylindrical_to_xyz([r, theta, z])
// Description:
//   Convert cylindrical coordinates to 3D cartesian coordinates.  Returns [X,Y,Z] cartesian coordinates.
// Arguments:
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


// Function: xyz_to_cylindrical()
// Usage:
//   xyz_to_cylindrical(x,y,z)
//   xyz_to_cylindrical([X,Y,Z])
// Description:
//   Convert 3D cartesian coordinates to cylindrical coordinates.
//   Returns [radius,theta,Z]. Theta is the angle counter-clockwise
//   of X+ on the XY plane.  Z is height above the XY plane.
// Arguments:
//   x = X coordinate.
//   y = Y coordinate.
//   z = Z coordinate.
// Examples:
//   cyl = xyz_to_cylindrical(20,30,40);
//   cyl = xyz_to_cylindrical([40,50,70]);
function xyz_to_cylindrical(x,y=undef,z=undef) = let(
		p = is_scalar(x)? [x, default(y,0), default(z,0)] : point3d(x)
	) [norm([p.x,p.y]), atan2(p.y,p.x), p.z];


// Function: spherical_to_xyz()
// Usage:
//   spherical_to_xyz(r, theta, phi);
//   spherical_to_xyz([r, theta, phi]);
// Description:
//   Convert spherical coordinates to 3D cartesian coordinates.
//   Returns [X,Y,Z] cartesian coordinates.
// Arguments:
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


// Function: xyz_to_spherical()
// Usage:
//   xyz_to_spherical(x,y,z)
//   xyz_to_spherical([X,Y,Z])
// Description:
//   Convert 3D cartesian coordinates to spherical coordinates.
//   Returns [r,theta,phi], where phi is the angle from the Z+ pole,
//   and theta is degrees counter-clockwise of X+ on the XY plane.
// Arguments:
//   x = X coordinate.
//   y = Y coordinate.
//   z = Z coordinate.
// Examples:
//   sph = xyz_to_spherical(20,30,40);
//   sph = xyz_to_spherical([40,50,70]);
function xyz_to_spherical(x,y=undef,z=undef) = let(
		p = is_scalar(x)? [x, default(y,0), default(z,0)] : point3d(x)
	) [norm(p), atan2(p.y,p.x), atan2(norm([p.x,p.y]),p.z)];


// Function: altaz_to_xyz()
// Usage:
//   altaz_to_xyz(alt, az, r);
//   altaz_to_xyz([alt, az, r]);
// Description:
//   Convert altitude/azimuth/range coordinates to 3D cartesian coordinates.
//   Returns [X,Y,Z] cartesian coordinates.
// Arguments:
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


// Function: xyz_to_altaz()
// Usage:
//   xyz_to_altaz(x,y,z);
//   xyz_to_altaz([X,Y,Z]);
// Description:
//   Convert 3D cartesian coordinates to altitude/azimuth/range coordinates.
//   Returns [altitude,azimuth,range], where altitude is angle above the
//   XY plane, azimuth is degrees clockwise of Y+ on the XY plane, and
//   range is the distance from the origin.
// Arguments:
//   x = X coordinate.
//   y = Y coordinate.
//   z = Z coordinate.
// Examples:
//   aa = xyz_to_altaz(20,30,40);
//   aa = xyz_to_altaz([40,50,70]);
function xyz_to_altaz(x,y=undef,z=undef) = let(
		p = is_scalar(x)? [x, default(y,0), default(z,0)] : point3d(x)
	) [atan2(p.z,norm([p.x,p.y])), atan2(p.x,p.y), norm(p)];


// Section: Matrix Manipulation

// Function: ident()
// Description: Create an `n` by `n` identity matrix.
// Arguments:
//   n = The size of the identity matrix square, `n` by `n`.
function ident(n) = [for (i = [0:n-1]) [for (j = [0:n-1]) (i==j)?1:0]];


// Create an identity matrix, for 3 axes.
ident3 = ident(3);
ident4 = ident(4);


// Function: mat3_to_mat4()
// Description: Takes a 3x3 matrix and returns its 4x4 equivalent.
function mat3_to_mat4(m) = concat(
	[for (r = [0:2])
		concat(
			[for (c = [0:2]) m[r][c]],
			[0]
		)
	],
	[[0, 0, 0, 1]]
);


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
	c2 = 1-c, s = sin(ang)
) [
	[u[0]*u[0]*c2+c     , u[0]*u[1]*c2-u[2]*s, u[0]*u[2]*c2+u[1]*s, 0],
	[u[1]*u[0]*c2+u[2]*s, u[1]*u[1]*c2+c     , u[1]*u[2]*c2-u[0]*s, 0],
	[u[2]*u[0]*c2-u[1]*s, u[2]*u[1]*c2+u[0]*s, u[2]*u[2]*c2+c     , 0],
	[                  0,                   0,                   0, 1]
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


// Function: matrix3_mult()
// Usage:
//   matrix3_mult(matrices)
// Description:
//   Returns a 3x3 transformation matrix which results from applying each matrix in `matrices` in order.
// Arguments:
//   matrices = A list of 3x3 matrices.
//   m = Optional starting matrix to apply everything to.
function matrix3_mult(matrices, m=ident(3), i=0) =
	(i>=len(matrices))? m :
	let (newmat = is_def(m)? matrices[i] * m : matrices[i])
		matrix3_mult(matrices, m=newmat, i=i+1);


// Function: matrix4_mult()
// Usage:
//   matrix4_mult(matrices)
// Description:
//   Returns a 4x4 transformation matrix which results from applying each matrix in `matrices` in order.
// Arguments:
//   matrices = A list of 4x4 matrices.
//   m = Optional starting matrix to apply everything to.
function matrix4_mult(matrices, m=ident(4), i=0) =
	(i>=len(matrices))? m :
	let (newmat = is_def(m)? matrices[i] * m : matrices[i])
		matrix4_mult(matrices, m=newmat, i=i+1);


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
function matrix3_apply(pts, matrices) = let(m = matrix3_mult(matrices)) [for (p = pts) point2d(m * concat(point2d(p),[1]))];


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

function matrix4_apply(pts, matrices) = let(m = matrix4_mult(matrices)) [for (p = pts) point3d(m * concat(point3d(p),[1]))];


// Section: Geometry

// Function: point_on_segment()
// Usage:
//   point_on_segment(point, edge);
// Description:
//   Determine if the point is on the line segment between two points.
//   Returns true if yes, and false if not.  
// Arguments:
//   point = The point to check colinearity of.
//   edge = Array of two points forming the line segment to test against.
function point_on_segment(point, edge) =
	point==edge[0] || point==edge[1] ||  // The point is an endpoint
	sign(edge[0].x-point.x)==sign(point.x-edge[1].x)  // point is in between the
		&& sign(edge[0].y-point.y)==sign(point.y-edge[1].y)  // edge endpoints 
		&& point_left_of_segment(point, edge)==0;  // and on the line defined by edge


// Function: point_left_of_segment()
// Usage:
//   point_left_of_segment(point, edge);
// Description:
//   Return >0 if point is left of the line defined by edge.
//   Return =0 if point is on the line.
//   Return <0 if point is right of the line.
// Arguments:
//   point = The point to check position of.
//   edge = Array of two points forming the line segment to test against.
function point_left_of_segment(point, edge) =
	(edge[1].x-edge[0].x) * (point.y-edge[0].y) - (point.x-edge[0].x) * (edge[1].y-edge[0].y);
  

// Internal non-exposed function.
function _point_above_below_segment(point, edge) =
	edge[0].y <= point.y? (
		(edge[1].y > point.y && point_left_of_segment(point, edge) > 0)? 1 : 0
	) : (
		(edge[1].y <= point.y && point_left_of_segment(point, edge) < 0)? -1 : 0
	);


// Function: point_in_polygon()
// Usage:
//   point_in_polygon(point, path)
// Description:
//   This function tests whether the given point is inside, outside or on the boundary of
//   the specified polygon using the Winding Number method.  (http://geomalgorithms.com/a03-_inclusion.html)
//   The polygon is given as a list of points, not including the repeated end point.
//   Returns -1 if the point is outside the polyon.
//   Returns 0 if the point is on the boundary.
//   Returns 1 if the point lies in the interior.
//   The polygon does not need to be simple: it can have self-intersections.
//   But the polygon cannot have holes (it must be simply connected).
//   Rounding error may give mixed results for points on or near the boundary.
// Arguments:
//   point = The point to check position of.
//   path = The list of 2D path points forming the perimeter of the polygon.
function point_in_polygon(point, path) =
	// Does the point lie on any edges?  If so return 0. 
	sum([for(i=[0:len(path)-1]) point_on_segment(point, wrap_range(path, i, i+1))?1:0])>0 ? 0 : 
	// Otherwise compute winding number and return 1 for interior, -1 for exterior
	sum([for(i=[0:len(path)-1]) _point_above_below_segment(point, wrap_range(path, i, i+1))]) != 0 ? 1 : -1;


// Function: pointlist_bounds()
// Usage:
//   pointlist_bounds(pts);
// Description:
//   Finds the bounds containing all the points in pts.
//   Returns [[minx, miny, minz], [maxx, maxy, maxz]]
// Arguments:
//   pts = List of points.
function pointlist_bounds(pts) = [
	[for (a=[0:2]) min([ for (x=pts) point3d(x)[a] ]) ],
	[for (a=[0:2]) max([ for (x=pts) point3d(x)[a] ]) ]
];


// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
