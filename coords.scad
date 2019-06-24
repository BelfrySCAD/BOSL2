//////////////////////////////////////////////////////////////////////
// LibFile: coords.scad
//   Coordinate transformations and coordinate system conversions.
//   To use, add the following lines to the beginning of your file:
//   ```
//   use <BOSL2/std.scad>
//   ```
//////////////////////////////////////////////////////////////////////


// Section: Coordinate Manipulation

// Function: point2d()
// Description:
//   Returns a 2D vector/point from a 2D or 3D vector.
//   If given a 3D point, removes the Z coordinate.
// Arguments:
//   p = The coordinates to force into a 2D vector/point.
//   fill = Value to fill missing values in vector with.
function point2d(p, fill=0) = [for (i=[0:1]) (p[i]==undef)? fill : p[i]];


// Function: path2d()
// Description:
//   Returns a list of 2D vectors/points from a list of 2D or 3D vectors/points.
//   If given a 3D point list, removes the Z coordinates from each point.
// Arguments:
//   points = A list of 2D or 3D points/vectors.
//   fill = Value to fill missing values in vectors with.
function path2d(points, fill=0) = [for (point = points) point2d(point, fill=fill)];


// Function: point3d()
// Description:
//   Returns a 3D vector/point from a 2D or 3D vector.
// Arguments:
//   p = The coordinates to force into a 3D vector/point.
//   fill = Value to fill missing values in vector with.
function point3d(p, fill=0) = [for (i=[0:2]) (p[i]==undef)? fill : p[i]];


// Function: path3d()
// Description:
//   Returns a list of 3D vectors/points from a list of 2D or 3D vectors/points.
// Arguments:
//   points = A list of 2D or 3D points/vectors.
//   fill = Value to fill missing values in vectors with.
function path3d(points, fill=0) = [for (point = points) point3d(point, fill=fill)];


// Function: point4d()
// Description:
//   Returns a 4D vector/point from a 2D or 3D vector.
// Arguments:
//   p = The coordinates to force into a 4D vector/point.
//   fill = Value to fill missing values in vector with.
function point4d(p, fill=0) = [for (i=[0:3]) (p[i]==undef)? fill : p[i]];


// Function: path4d()
// Description:
//   Returns a list of 4D vectors/points from a list of 2D or 3D vectors/points.
// Arguments:
//   points = A list of 2D or 3D points/vectors.
//   fill = Value to fill missing values in vectors with.
function path4d(points, fill=0) = [for (point = points) point4d(point, fill=fill)];


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
function scale_points(pts, v=[0,0,0], cp=[0,0,0]) = [for (pt = pts) [for (i = [0:1:len(pt)-1]) (pt[i]-cp[i])*v[i]+cp[i]]];


// Function: rotate_points2d()
// Usage:
//   rotate_points2d(pts, a, [cp]);
// Description:
//   Rotates each 2D point in an array by a given amount, around an optional centerpoint.
// Arguments:
//   pts = List of 3D points to rotate.
//   a = Angle to rotate by.
//   cp = 2D Centerpoint to rotate around.  Default: `[0,0]`
function rotate_points2d(pts, a, cp=[0,0]) =
	approx(a,0)? pts :
	let(
		cp = point2d(cp),
		pts = path2d(pts),
		m = affine2d_zrot(a)
	) [for (pt = pts) point2d(m*concat(pt-cp, [1])+cp)];


// Function: rotate_points3d()
// Usage:
//   rotate_points3d(pts, a, [cp], [reverse]);
//   rotate_points3d(pts, a, v, [cp], [reverse]);
//   rotate_points3d(pts, from, to, [a], [cp], [reverse]);
// Description:
//   Rotates each 3D point in an array by a given amount, around a given centerpoint.
// Arguments:
//   pts = List of points to rotate.
//   a = Rotation angle(s) in degrees.
//   v = If given, axis vector to rotate around.
//   cp = Centerpoint to rotate around.
//   from = If given, the vector to rotate something from.  Used with `to`.
//   to = If given, the vector to rotate something to.  Used with `from`.
//   reverse = If true, performs an exactly reversed rotation.
function rotate_points3d(pts, a=0, v=undef, cp=[0,0,0], from=undef, to=undef, reverse=false) =
	assert(is_undef(from)==is_undef(to), "`from` and `to` must be given together.")
	(is_undef(from) && (a==0 || a==[0,0,0]))? pts :
	let (
		from = is_undef(from)? undef : (from / norm(from)),
		to = is_undef(to)? undef : (to / norm(to)),
		cp = point3d(cp),
		pts2 = path3d(pts)
	)
	(!is_undef(from) && approx(from,to) && (a==0 || a == [0,0,0]))? pts2 :
	let (
		mrot = reverse? (
			!is_undef(from)? (
				assert(norm(from)>0, "The from argument cannot equal [0,0] or [0,0,0]")
				assert(norm(to)>0, "The to argument cannot equal [0,0] or [0,0,0]")
				let (
					ang = vector_angle(from, to),
					v = vector_axis(from, to)
				)
				affine3d_rot_by_axis(from, -a) * affine3d_rot_by_axis(v, -ang)
			) : !is_undef(v)? (
				affine3d_rot_by_axis(v, -a)
			) : is_num(a)? (
				affine3d_zrot(-a)
			) : (
				affine3d_xrot(-a.x) * affine3d_yrot(-a.y) * affine3d_zrot(-a.z)
			)
		) : (
			!is_undef(from)? (
				assert(norm(from)>0, "The from argument cannot equal [0,0] or [0,0,0]")
				assert(norm(to)>0, "The to argument cannot equal [0,0] or [0,0,0]")
				let (
					from = from / norm(from),
					to = to / norm(from),
					ang = vector_angle(from, to),
					v = vector_axis(from, to)
				)
				affine3d_rot_by_axis(v, ang) * affine3d_rot_by_axis(from, a)
			) : !is_undef(v)? (
				affine3d_rot_by_axis(v, a)
			) : is_num(a)? (
				affine3d_zrot(a)
			) : (
				affine3d_zrot(a.z) * affine3d_yrot(a.y) * affine3d_xrot(a.x)
			)
		),
		m = affine3d_translate(cp) * mrot * affine3d_translate(-cp)
	)
	[for (pt = pts2) point3d(m*concat(pt, fill=1))];



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


// Function: project_plane()
// Usage:
//   project_plane(point, a, b, c);
// Description:
//   Given three points defining a plane, returns the projected planar [X,Y] coordinates of the
//   closest point to a 3D `point`.  The origin of the planar coordinate system [0,0] will be at point
//   `a`, and the Y+ axis direction will be towards point `b`.  This coordinate system can be useful
//   in taking a set of nearly coplanar points, and converting them to a pure XY set of coordinates
//   for manipulation, before convering them back to the original 3D plane.
function project_plane(point, a, b, c) =
	let(
		u = normalize(b-a),
		v = normalize(c-a),
		n = normalize(cross(u,v)),
		w = normalize(cross(n,u)),
		relpoint = is_vector(point)? (point-a) : translate_points(point,-a)
	) relpoint * transpose([w,u]);


// Function: lift_plane()
// Usage:
//   lift_plane(point, a, b, c);
// Description:
//   Given three points defining a plane, converts a planar [X,Y] coordinate to the actual
//   corresponding 3D point on the plane.  The origin of the planar coordinate system [0,0]
//   will be at point `a`, and the Y+ axis direction will be towards point `b`.
function lift_plane(point, a, b, c) =
	let(
		u = normalize(b-a),
		v = normalize(c-a),
		n = normalize(cross(u,v)),
		w = normalize(cross(n,u)),
		remapped = point*[w,u]
	) is_vector(remapped)? (a+remapped) : translate_points(remapped,a);


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
		p = is_num(x)? [x, default(y,0), default(z,0)] : point3d(x)
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
		p = is_num(x)? [x, default(y,0), default(z,0)] : point3d(x)
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
		p = is_num(x)? [x, default(y,0), default(z,0)] : point3d(x)
	) [atan2(p.z,norm([p.x,p.y])), atan2(p.x,p.y), norm(p)];



// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
