//////////////////////////////////////////////////////////////////////
// LibFile: vectors.scad
//   Vector math functions.
//   To use, add the following lines to the beginning of your file:
//   ```
//   use <BOSL2/std.scad>
//   ```
//////////////////////////////////////////////////////////////////////


// Section: Vector Manipulation


// Function: is_vector()
// Usage:
//   is_vector(v)
// Description:
//   Returns true if the given value is a list, and at least the first item is a number.
// Example:
//   is_vector([1,2,3]);    // Returns: true
//   is_vector([[1,2,3]]);  // Returns: false
//   is_vector(["foo"]);    // Returns: false
//   is_vector([]);         // Returns: false
//   is_vector(1);          // Returns: false
//   is_vector("foo");      // Returns: false
//   is_vector(true);       // Returns: false
function is_vector(v) = is_list(v) && is_num(v[0]);


// Function: add_scalar()
// Usage:
//   add_scalar(v,s);
// Description:
//   Given a vector and a scalar, returns the vector with the scalar added to each item in it.
//   If given a list of vectors, recursively adds the scalar to the each vector.
// Arguments:
//   v = The initial list of values.
//   s = A scalar value to add to every item in the vector.
// Example:
//   add_scalar([1,2,3],3);            // Returns: [4,5,6]
//   add_scalar([[1,2,3],[3,4,5]],3);  // Returns: [[4,5,6],[6,7,8]]
function add_scalar(v,s) = [for (x=v) is_list(x)? add_scalar(x,s) : x+s];


// Function: vang()
// Usage:
//   theta = vang([X,Y]);
//   theta_phi = vang([X,Y,Z]);
// Description:
//   Given a 2D vector, returns the angle in degrees counter-clockwise from X+ on the XY plane.
//   Given a 3D vector, returns [THETA,PHI] where THETA is the number of degrees counter-clockwise from X+ on the XY plane, and PHI is the number of degrees up from the X+ axis along the XZ plane.
function vang(v) =
	len(v)==2? atan2(v.y,v.x) :
	let(res=xyz_to_spherical(v)) [res[1], 90-res[2]];


// Function: vmul()
// Description:
//   Element-wise vector multiplication.  Multiplies each element of vector `v1` by
//   the corresponding element of vector `v2`.  Returns a vector of the products.
// Arguments:
//   v1 = The first vector.
//   v2 = The second vector.
// Example:
//   vmul([3,4,5], [8,7,6]);  // Returns [24, 28, 30]
function vmul(v1, v2) = [for (i = [0:1:len(v1)-1]) v1[i]*v2[i]];


// Function: vdiv()
// Description:
//   Element-wise vector division.  Divides each element of vector `v1` by
//   the corresponding element of vector `v2`.  Returns a vector of the quotients.
// Arguments:
//   v1 = The first vector.
//   v2 = The second vector.
// Example:
//   vdiv([24,28,30], [8,7,6]);  // Returns [3, 4, 5]
function vdiv(v1, v2) = [for (i = [0:1:len(v1)-1]) v1[i]/v2[i]];


// Function: vabs()
// Description: Returns a vector of the absolute value of each element of vector `v`.
// Arguments:
//   v = The vector to get the absolute values of.
// Example:
//   vabs([-1,3,-9]);  // Returns: [1,3,9]
function vabs(v) = [for (x=v) abs(x)];


// Function: normalize()
// Description:
//   Returns unit length normalized version of vector v.
//   If passed a zero-length vector, returns the unchanged vector.
// Arguments:
//   v = The vector to normalize.
// Examples:
//   normalize([10,0,0]);   // Returns: [1,0,0]
//   normalize([0,10,0]);   // Returns: [0,1,0]
//   normalize([0,0,10]);   // Returns: [0,0,1]
//   normalize([0,-10,0]);  // Returns: [0,-1,0]
//   normalize([0,0,0]);    // Returns: [0,0,0]
function normalize(v) = norm(v)<=EPSILON? v : v/norm(v);


// Function: vector_angle()
// Usage:
//   vector_angle(v1,v2);
//   vector_angle(PT1,PT2,PT3);
//   vector_angle([PT1,PT2,PT3]);
// Description:
//   If given a single list of two vectors, like `vector_angle([V1,V2])`, returns the angle between the two vectors V1 and V2.
//   If given a single list of three points, like `vector_angle([A,B,C])`, returns the angle between the line segments AB and BC.
//   If given two vectors, like `vector_angle(V1,V2)`, returns the angle between the two vectors V1 and V2.
//   If given three points, like `vector_angle(A,B,C)`, returns the angle between the line segments AB and BC.
// Arguments:
//   v1 = First vector or point.
//   v2 = Second vector or point.
//   v3 = Third point in three point mode.
// Examples:
//   vector_angle(UP,LEFT);     // Returns: 90
//   vector_angle(RIGHT,LEFT);  // Returns: 180
//   vector_angle(UP+RIGHT,RIGHT);  // Returns: 45
//   vector_angle([10,10], [0,0], [10,-10]);  // Returns: 90
//   vector_angle([10,0,10], [0,0,0], [-10,10,0]);  // Returns: 120
//   vector_angle([[10,0,10], [0,0,0], [-10,10,0]]);  // Returns: 120
function vector_angle(v1,v2=undef,v3=undef) =
	(is_list(v1) && is_list(v1[0]) && is_undef(v2) && is_undef(v3))? (
		assert(is_vector(v1.x))
		assert(is_vector(v1.y))
		len(v1)==3? assert(is_vector(v1.z)) vector_angle(v1.x, v1.y, v1.z) :
		len(v1)==2? vector_angle(v1.x, v1.y) :
		assert(false, "Bad arguments.")
	) :
	(is_vector(v1) && is_vector(v2) && is_vector(v3))? vector_angle(v1-v2, v3-v2) :
	// NOTE: constrain() corrects crazy FP rounding errors that exceed acos()'s domain.
	(is_vector(v1) && is_vector(v2) && is_undef(v3))? acos(constrain((v1*v2)/(norm(v1)*norm(v2)), -1, 1)) :
	assert(false, "Bad arguments.");


// Function: vector_axis()
// Usage:
//   vector_axis(v1,v2);
//   vector_axis(PT1,PT2,PT3);
//   vector_axis([PT1,PT2,PT3]);
// Description:
//   If given a single list of two vectors, like `vector_axis([V1,V2])`, returns the vector perpendicular the two vectors V1 and V2.
//   If given a single list of three points, like `vector_axis([A,B,C])`, returns the vector perpendicular the line segments AB and BC.
//   If given two vectors, like `vector_axis(V1,V1)`, returns the vector perpendicular the two vectors V1 and V2.
//   If given three points, like `vector_axis(A,B,C)`, returns the vector perpendicular the line segments AB and BC.
// Arguments:
//   v1 = First vector or point.
//   v2 = Second vector or point.
//   v3 = Third point in three point mode.
// Examples:
//   vector_axis(UP,LEFT);     // Returns: [0,-1,0] (FWD)
//   vector_axis(RIGHT,LEFT);  // Returns: [0,-1,0] (FWD)
//   vector_axis(UP+RIGHT,RIGHT);  // Returns: [0,1,0] (BACK)
//   vector_axis([10,10], [0,0], [10,-10]);  // Returns: [0,0,-1] (DOWN)
//   vector_axis([10,0,10], [0,0,0], [-10,10,0]);  // Returns: [-0.57735, -0.57735, 0.57735]
//   vector_axis([[10,0,10], [0,0,0], [-10,10,0]]);  // Returns: [-0.57735, -0.57735, 0.57735]
function vector_axis(v1,v2=undef,v3=undef) =
	(is_list(v1) && is_list(v1[0]) && is_undef(v2) && is_undef(v3))? (
		assert(is_vector(v1.x))
		assert(is_vector(v1.y))
		len(v1)==3? assert(is_vector(v1.z)) vector_axis(v1.x, v1.y, v1.z) :
		len(v1)==2? vector_axis(v1.x, v1.y) :
		assert(false, "Bad arguments.")
	) :
	(is_vector(v1) && is_vector(v2) && is_vector(v3))? vector_axis(v1-v2, v3-v2) :
	(is_vector(v1) && is_vector(v2) && is_undef(v3))? let(
		eps = 1e-6,
		v1 = point3d(v1/norm(v1)),
		v2 = point3d(v2/norm(v2)),
		v3 = (norm(v1-v2) > eps && norm(v1+v2) > eps)? v2 :
			(norm(vabs(v2)-UP) > eps)? UP :
			RIGHT
	) normalize(cross(v1,v3)) : assert(false, "Bad arguments.");


// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
