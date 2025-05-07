//////////////////////////////////////////////////////////////////////
// LibFile: coords.scad
//   Coordinate transformations and coordinate system conversions.
// Includes:
//   include <BOSL2/std.scad>
// FileGroup: Math
// FileSummary: Conversions between coordinate systems.
// FileFootnotes: STD=Included in std.scad
//////////////////////////////////////////////////////////////////////


// Section: Coordinate Manipulation

// Function: point2d()
// Synopsis: Convert a vector to 2D. 
// Topics: Coordinates, Points
// See Also: path2d(), point3d(), path3d()
// Usage:
//   pt = point2d(p, [fill]);
// Description:
//   Returns a 2D vector/point from a 2D or 3D vector.  If given a 3D point, removes the Z coordinate.
// Arguments:
//   p = The coordinates to force into a 2D vector/point.
//   fill = Value to fill missing values in vector with.  Default: 0
function point2d(p, fill=0) = assert(is_list(p)) [for (i=[0:1]) (p[i]==undef)? fill : p[i]];


// Function: path2d()
// Synopsis: Convert a path to 2D. 
// SynTags: Path
// Topics: Coordinates, Points, Paths
// See Also: point2d(), point3d(), path3d()
// Usage:
//   pts = path2d(points);
// Description:
//   Returns a list of 2D vectors/points from a list of 2D, 3D or higher dimensional vectors/points.
//   Removes the extra coordinates from higher dimensional points.  The input must be a path, where
//   every vector has the same length.
// Arguments:
//   points = A list of 2D or 3D points/vectors.
function path2d(points) =
    assert(is_path(points,dim=undef,fast=true),"\nInput to path2d is not a path.")
    let (result = points * concat(ident(2), repeat([0,0], len(points[0])-2)))
    assert(is_def(result), "\nInvalid input to path2d.")
    result;


// Function: point3d()
// Synopsis: Convert a vector to 3D. 
// Topics: Coordinates, Points
// See Also: path2d(), point2d(), path3d()
// Usage:
//   pt = point3d(p, [fill]);
// Description:
//   Returns a 3D vector/point from a 2D or 3D vector.
// Arguments:
//   p = The coordinates to force into a 3D vector/point.
//   fill = Value to fill missing values in vector with.  Default: 0
function point3d(p, fill=0) =
    assert(is_list(p)) 
    [for (i=[0:2]) (p[i]==undef)? fill : p[i]];


// Function: path3d()
// Synopsis: Convert a path to 3D. 
// SynTags: Path
// Topics: Coordinates, Points, Paths
// See Also: point2d(), path2d(), point3d(), point4d(), path4d(), hstack()
// Usage:
//   pts = path3d(points, [fill]);
// Description:
//   Returns a list of 3D vectors/points from a list of 2D or higher dimensional vectors/points
//   by removing extra coordinates or adding the z coordinate.  
// Arguments:
//   points = A list of 2D, 3D or higher dimensional points/vectors.
//   fill = Scalar value to fill missing values in vectors with (in the 2D case).  Default: 0
function path3d(points, fill=0) =
    assert(is_num(fill))
    assert(is_path(points, dim=undef, fast=true), "\nInput to path3d is not a path.")
    let (
        change = len(points[0])-3,
        M = change < 0? [[1,0,0],[0,1,0]] : 
            concat(ident(3), repeat([0,0,0],change)),
        result = points*M
    )
    assert(is_def(result), "\nInput to path3d is invalid.")
    fill == 0 || change>=0 ? result : result + repeat([0,0,fill], len(result));


// Function: point4d()
// Synopsis: Convert a vector to 4d. 
// Topics: Coordinates, Points
// See Also: point2d(), path2d(), point3d(), path3d(), path4d()
// Usage:
//   pt = point4d(p, [fill]);
// Description:
//   Returns a 4D vector/point from a 2D or 3D vector.
// Arguments:
//   p = The coordinates to force into a 4D vector/point.
//   fill = Scalar value to fill missing values in vector with.  Default: 0
function point4d(p, fill=0) = assert(is_list(p))
                              [for (i=[0:3]) (p[i]==undef)? fill : p[i]];


// Function: path4d()
// Synopsis: Convert a path to 4d.  
// SynTags: Path
// Topics: Coordinates, Points, Paths
// See Also: point2d(), path2d(), point3d(), path3d(), point4d(), hstack()
// Usage:
//   pt = path4d(points, [fill]);
// Description:
//   Returns a list of 4D vectors/points from a list of 2D or 3D vectors/points.
// Arguments:
//   points = A list of 2D or 3D points/vectors.
//   fill = Scalar value to fill missing values in vectors with.  Default: 0 
function path4d(points, fill=0) = 
   assert(is_num(fill) || is_vector(fill))
   assert(is_path(points, dim=undef, fast=true), "\nInput to path4d is not a path.")
   let (
      change = len(points[0])-4,
      M = change < 0 ? select(ident(4), 0, len(points[0])-1) :
                       concat(ident(4), repeat([0,0,0,0],change)),
      result = points*M
   ) 
   assert(is_def(result), "\nInput to path4d is invalid.")
   fill == 0 || change >= 0 ? result :
    let(
      addition = is_list(fill) ? concat(0*points[0],fill) :
                                 concat(0*points[0],repeat(fill,-change))
    )
    assert(len(addition) == 4, "\nFill is the wrong length.")
    result + repeat(addition, len(result));



// Section: Coordinate Systems

// Function: polar_to_xy()
// Synopsis: Convert 2D polar coordinates to cartesian coordinates. 
// SynTags: Path
// Topics: Coordinates, Points, Paths
// See Also: xy_to_polar(), xyz_to_cylindrical(), cylindrical_to_xyz(), xyz_to_spherical(), spherical_to_xyz()
// Usage:
//   pt = polar_to_xy(r, theta);
//   pt = polar_to_xy([R, THETA]);
//   pts = polar_to_xy([[R,THETA], [R,THETA], ...]);
// Description:
//   Called with two arguments, converts the `r` and `theta` 2D polar coordinate into an `[X,Y]` cartesian coordinate.
//   Called with one `[R,THETA]` vector argument, converts the 2D polar coordinate into an `[X,Y]` cartesian coordinate.
//   Called with a list of `[R,THETA]` vector arguments, converts each 2D polar coordinate into `[X,Y]` cartesian coordinates.
//   Theta is the angle counter-clockwise of X+ on the XY plane.
// Arguments:
//   r = distance from the origin.
//   theta = angle in degrees, counter-clockwise of X+.
// Example:
//   xy = polar_to_xy(20,45);    // Returns: ~[14.1421365, 14.1421365]
//   xy = polar_to_xy(40,30);    // Returns: ~[34.6410162, 15]
//   xy = polar_to_xy([40,30]);  // Returns: ~[34.6410162, 15]
//   xy = polar_to_xy([[40,30],[20,120]]);  // Returns: ~[[34.6410162, 15], [-10, 17.3205]]
// Example(2D):
//   r=40; ang=30; $fn=36;
//   pt = polar_to_xy(r,ang);
//   stroke(circle(r=r), closed=true, width=0.5);
//   color("black") stroke([[r,0], [0,0], pt], width=0.5);
//   color("black") stroke(arc(r=15, angle=ang), width=0.5);
//   color("red") move(pt) circle(d=3);
function polar_to_xy(r,theta) =
    theta != undef
      ? assert(is_num(r) && is_num(theta), "\nBad arguments.")
        [r*cos(theta), r*sin(theta)]
      : assert(is_list(r), "\nBad arguments.")
        is_num(r.x)
          ? polar_to_xy(r.x, r.y)
          : [for(p = r) polar_to_xy(p.x, p.y)];


// Function: xy_to_polar()
// Synopsis: Convert 2D cartesian coordinates to polar coordinates (radius and angle)
// Topics: Coordinates, Points, Paths
// See Also: polar_to_xy(), xyz_to_cylindrical(), cylindrical_to_xyz(), xyz_to_spherical(), spherical_to_xyz()
// Usage:
//   r_theta = xy_to_polar(x,y);
//   r_theta = xy_to_polar([X,Y]);
//   r_thetas = xy_to_polar([[X,Y], [X,Y], ...]);
// Description:
//   Called with two arguments, converts the `x` and `y` 2D cartesian coordinate into a `[RADIUS,THETA]` polar coordinate.
//   Called with one `[X,Y]` vector argument, converts the 2D cartesian coordinate into a `[RADIUS,THETA]` polar coordinate.
//   Called with a list of `[X,Y]` vector arguments, converts each 2D cartesian coordinate into `[RADIUS,THETA]` polar coordinates.
//   Theta is the angle counter-clockwise of X+ on the XY plane.
// Arguments:
//   x = X coordinate.
//   y = Y coordinate.
// Example:
//   plr = xy_to_polar(20,30);
//   plr = xy_to_polar([40,60]);
//   plrs = xy_to_polar([[40,60],[-10,20]]);
// Example(2D):
//   pt = [-20,30]; $fn = 36;
//   rt = xy_to_polar(pt);
//   r = rt[0]; ang = rt[1];
//   stroke(circle(r=r), closed=true, width=0.5);
//   zrot(ang) stroke([[0,0],[r,0]],width=0.5);
//   color("red") move(pt) circle(d=3);
function xy_to_polar(x, y) =
    y != undef
      ? assert(is_num(x) && is_num(y), "\nBad arguments.")
        [norm([x, y]), atan2(y, x)]
      : assert(is_list(x), "\nBad arguments.")
        is_num(x.x)
          ? xy_to_polar(x.x, x.y)
          : [for(p = x) xy_to_polar(p.x, p.y)];


// Function: project_plane()
// Synopsis: Project a set of points onto a specified plane, returning 2D points.  
// SynTags: Path
// Topics: Coordinates, Points, Paths
// See Also: lift_plane()
// Usage: 
//   xy = project_plane(plane, p);
// Usage: To get a transform matrix
//   M = project_plane(plane)
// Description:
//   Maps the provided 3D point(s) from 3D coordinates to a 2D coordinate system defined by `plane`.  Points that are not
//   on the specified plane are projected orthogonally onto the plane.  This coordinate system is useful if you need
//   to perform 2D operations on a coplanar set of data.  After those operations are done you can return the data
//   to 3D with `lift_plane()`.  You could also use this to force approximately coplanar data to be exactly coplanar.
//   The parameter p can be a point, path, region, bezier patch or VNF.
//   The plane can be specified as
//   - A list of three points.  The planar coordinate system should have [0,0] at plane[0], with plane[1] lying on the Y+ axis.
//   - A list of non-collinear, coplanar points that define a plane.
//   - A plane definition `[A,B,C,D]` where `Ax+By+CZ=D`.  The closest point on that plane to the origin maps to the origin in the new coordinate system.
//   .
//   If you omit the point specification then `project_plane()` returns a rotation matrix that maps the specified plane to the XY plane.
//   Note that if you apply this transformation to data lying on the plane, it produces 3D points with the Z coordinate of zero.
// Arguments:
//   plane = plane specification or point list defining the plane
//   p = 3D point, path, region, VNF or bezier patch to project
// Example:
//   pt = [5,-5,5];
//   a=[0,0,0];  b=[10,-10,0];  c=[10,0,10];
//   xy = project_plane([a,b,c],pt);
// Example(3D): The yellow points in 3D project onto the red points in 2D
//   M = [[-1, 2, -1, -2], [-1, -3, 2, -1], [2, 3, 4, 53], [0, 0, 0, 1]];
//   data = apply(M,path3d(circle(r=10, $fn=20)));
//   move_copies(data) sphere(r=1);
//   color("red") move_copies(project_plane(data, data)) sphere(r=1);
// Example:
//   xyzpath = move([10,20,30], p=yrot(25, p=path3d(circle(d=100))));
//   mat = project_plane(xyzpath);
//   xypath = path2d(apply(mat, xyzpath));
//   #stroke(xyzpath,closed=true);
//   stroke(xypath,closed=true);
function project_plane(plane,p) =
      is_matrix(plane,3,3) && is_undef(p) ? // no data, 3 points given
          assert(!is_collinear(plane),"\nPoints defining the plane must not be collinear.")
          let(
              v = plane[2]-plane[0],
              y = unit(plane[1]-plane[0]),        // y axis goes to point b
              x = unit(v-(v*y)*y)   // x axis 
          )            
          frame_map(x,y) * move(-plane[0])
    : is_vector(plane,4) && is_undef(p) ?            // no data, plane given in "plane"
          assert(_valid_plane(plane), "\nPlane is not valid.")
          let(
               n = point3d(plane),
               cp = n * plane[3] / (n*n)
          )
          rot(from=n, to=UP) * move(-cp)
    : is_path(plane,3) && is_undef(p) ?               // no data, generic point list plane
          assert(len(plane)>=3, "\nNeed three points to define a plane.")
          let(plane = plane_from_points(plane, check_coplanar=true))
          assert(is_def(plane), "\nPoint list is not coplanar.")
          project_plane(plane)
    : assert(is_def(p), str("Invalid plane specification: ",plane))
      is_vnf(p) ? [project_plane(plane,p[0]), p[1]] 
    : is_list(p) && is_list(p[0]) && is_vector(p[0][0],3) ?  // bezier patch or region
           [for(plist=p) project_plane(plane,plist)]
    : assert(is_vector(p,3) || is_path(p,3), str("\nData must be a 3D point, path, region, vnf, or bezier patch."))
      is_matrix(plane,3,3) ?
          assert(!is_collinear(plane),"\nPoints defining the plane must not be collinear.")
          let(
              v = plane[2]-plane[0],
              y = unit(plane[1]-plane[0]),        // y axis goes to point b
              x = unit(v-(v*y)*y)  // x axis 
          ) move(-plane[0],p) * transpose([x,y])
    : is_vector(p) ? point2d(apply(project_plane(plane),p))
    : path2d(apply(project_plane(plane),p));



// Function: lift_plane()
// Synopsis: Map a list of 2D points onto a plane in 3D. 
// SynTags: Path
// Topics: Coordinates, Points, Paths
// See Also: project_plane()
// Usage: 
//   xyz = lift_plane(plane, p);
// Usage: to get transform matrix
//   M =  lift_plane(plane);
// Description:
//   Converts the given 2D point on the plane to 3D coordinates of the specified plane.
//   The parameter p can be a point, path, region, bezier patch or VNF.
//   The plane can be specified as
//   - A list of three points.  The planar coordinate system will have [0,0] at plane[0], with plane[1] lying on the Y+ axis.
//   - A list of non-collinear, coplanar points that define a plane.
//   - A plane definition `[A,B,C,D]` where `Ax+By+CZ=D`.  The closest point on that plane to the origin maps to the origin in the new coordinate system.
//   .
//   If you do not supply `p` then you get a transformation matrix that operates in 3D, assuming that the Z coordinate of the points is zero.
//   This matrix is a rotation, the inverse of the one produced by project_plane.
// Arguments:
//   plane = Plane specification or list of points to define a plane
//   p = points, path, region, VNF, or bezier patch to transform. 
function lift_plane(plane, p) =
      is_matrix(plane,3,3) && is_undef(p) ? // no data, 3 p given
          let(
              v = plane[2]-plane[0],
              y = unit(plane[1]-plane[0]),        // y axis goes to point b
              x = unit(v-(v*y)*y)   // x axis 
          )            
          move(plane[0]) * frame_map(x,y,reverse=true)
    : is_vector(plane,4) && is_undef(p) ?            // no data, plane given in "plane"
          assert(_valid_plane(plane), "\nPlane is not valid.")
          let(
               n = point3d(plane),
               cp = n * plane[3] / (n*n)
          )
          move(cp) * rot(from=UP, to=n)
    : is_path(plane,3) && is_undef(p) ?               // no data, generic point list plane
          assert(len(plane)>=3, "\nNeed three points to define a plane.")
          let(plane = plane_from_points(plane, check_coplanar=true))
          assert(is_def(plane), "Point list is not coplanar")
          lift_plane(plane)
    : is_vnf(p) ? [lift_plane(plane,p[0]), p[1]] 
    : is_list(p) && is_list(p[0]) && is_vector(p[0][0],3) ?  // bezier patch or region
           [for(plist=p) lift_plane(plane,plist)]
    : assert(is_vector(p,2) || is_path(p,2),"\nData must be a 2D point, path, region, vnf, or bezier patch.")
      is_matrix(plane,3,3) ?
          let(
              v = plane[2]-plane[0],
              y = unit(plane[1]-plane[0]),        // y axis goes to point b
              x = unit(v-(v*y)*y)  // x axis 
          ) move(plane[0],p * [x,y])
    : apply(lift_plane(plane),is_vector(p) ? point3d(p) : path3d(p));


// Function: cylindrical_to_xyz()
// Synopsis: Convert cylindrical coordinates to cartesian coordinates. 
// SynTags: Path
// Topics: Coordinates, Points, Paths
// See Also: xyz_to_cylindrical(), xy_to_polar(), polar_to_xy(), xyz_to_spherical(), spherical_to_xyz()
// Usage:
//   pt = cylindrical_to_xyz(r, theta, z);
//   pt = cylindrical_to_xyz([RADIUS,THETA,Z]);
//   pts = cylindrical_to_xyz([[RADIUS,THETA,Z], [RADIUS,THETA,Z], ...]);
// Description:
//   Called with three arguments, converts the `r`, `theta`, and 'z' 3D cylindrical coordinate into an `[X,Y,Z]` cartesian coordinate.
//   Called with one `[RADIUS,THETA,Z]` vector argument, converts the 3D cylindrical coordinate into an `[X,Y,Z]` cartesian coordinate.
//   Called with a list of `[RADIUS,THETA,Z]` vector arguments, converts each 3D cylindrical coordinate into `[X,Y,Z]` cartesian coordinates.
//   Theta is the angle counter-clockwise of X+ on the XY plane.  Z is height above the XY plane.
// Arguments:
//   r = distance from the Z axis.
//   theta = angle in degrees, counter-clockwise of X+ on the XY plane.
//   z = Height above XY plane.
// Example:
//   xyz = cylindrical_to_xyz(20,30,40);
//   xyz = cylindrical_to_xyz([40,60,50]);
function cylindrical_to_xyz(r,theta,z) =
    theta != undef
      ? assert(is_num(r) && is_num(theta) && is_num(z), "\nBad arguments.")
        [r*cos(theta), r*sin(theta), z]
      : assert(is_list(r), "\nBad arguments.")
        is_num(r.x)
          ? cylindrical_to_xyz(r.x, r.y, r.z)
          : [for(p = r) cylindrical_to_xyz(p.x, p.y, p.z)];


// Function: xyz_to_cylindrical()
// Synopsis: Convert 3D cartesian coordinates to cylindrical coordinates. 
// Topics: Coordinates, Points, Paths
// See Also: cylindrical_to_xyz(), xy_to_polar(), polar_to_xy(), xyz_to_spherical(), spherical_to_xyz()
// Usage:
//   rtz = xyz_to_cylindrical(x,y,z);
//   rtz = xyz_to_cylindrical([X,Y,Z]);
//   rtzs = xyz_to_cylindrical([[X,Y,Z], [X,Y,Z], ...]);
// Description:
//   Called with three arguments, converts the `x`, `y`, and `z` 3D cartesian coordinate into a `[RADIUS,THETA,Z]` cylindrical coordinate.
//   Called with one `[X,Y,Z]` vector argument, converts the 3D cartesian coordinate into a `[RADIUS,THETA,Z]` cylindrical coordinate.
//   Called with a list of `[X,Y,Z]` vector arguments, converts each 3D cartesian coordinate into `[RADIUS,THETA,Z]` cylindrical coordinates.
//   Theta is the angle counter-clockwise of X+ on the XY plane.  Z is height above the XY plane.
// Arguments:
//   x = X coordinate.
//   y = Y coordinate.
//   z = Z coordinate.
// Example:
//   cyl = xyz_to_cylindrical(20,30,40);
//   cyl = xyz_to_cylindrical([40,50,70]);
//   cyls = xyz_to_cylindrical([[40,50,70], [-10,15,-30]]);
function xyz_to_cylindrical(x,y,z) =
    y != undef
      ? assert(is_num(x) && is_num(y) && is_num(z), "\nBad arguments.")
        [norm([x,y]), atan2(y,x), z]
      : assert(is_list(x), "\nBad arguments.")
        is_num(x.x)
          ? xyz_to_cylindrical(x.x, x.y, x.z)
          : [for(p = x) xyz_to_cylindrical(p.x, p.y, p.z)];


// Function: spherical_to_xyz()
// Synopsis: Convert spherical coordinates to 3D cartesian coordinates. 
// SynTags: Path
// Topics: Coordinates, Points, Paths
// See Also: cylindrical_to_xyz(), xyz_to_spherical(), xyz_to_cylindrical(), altaz_to_xyz(), xyz_to_altaz()
// Usage:
//   pt = spherical_to_xyz(r, theta, phi);
//   pt = spherical_to_xyz([RADIUS,THETA,PHI]);
//   pts = spherical_to_xyz([[RADIUS,THETA,PHI], [RADIUS,THETA,PHI], ...]);
// Description:
//   Called with three arguments, converts the `r`, `theta`, and 'phi' 3D spherical coordinate into an `[X,Y,Z]` cartesian coordinate.
//   Called with one `[RADIUS,THETA,PHI]` vector argument, converts the 3D spherical coordinate into an `[X,Y,Z]` cartesian coordinate.
//   Called with a list of `[RADIUS,THETA,PHI]` vector arguments, converts each 3D spherical coordinate into `[X,Y,Z]` cartesian coordinates.
//   Theta is the angle counter-clockwise of X+ on the XY plane.  Phi is the angle down from the Z+ pole.
// Arguments:
//   r = distance from origin.
//   theta = angle in degrees, counter-clockwise of X+ on the XY plane.
//   phi = angle in degrees from the vertical Z+ axis.
// Example:
//   xyz = spherical_to_xyz(20,30,40);
//   xyz = spherical_to_xyz([40,60,50]);
//   xyzs = spherical_to_xyz([[40,60,50], [50,120,100]]);
function spherical_to_xyz(r,theta,phi) =
    theta != undef
      ? assert(is_num(r) && is_num(theta) && is_num(phi), "\nBad arguments.")
        r*[cos(theta)*sin(phi), sin(theta)*sin(phi), cos(phi)]
      : assert(is_list(r), "\nBad arguments.")
        is_num(r.x)
          ? spherical_to_xyz(r.x, r.y, r.z)
          : [for(p = r) spherical_to_xyz(p.x, p.y, p.z)];


// Function: xyz_to_spherical()
// Usage:
//   r_theta_phi = xyz_to_spherical(x,y,z)
//   r_theta_phi = xyz_to_spherical([X,Y,Z])
//   r_theta_phis = xyz_to_spherical([[X,Y,Z], [X,Y,Z], ...])
// Topics: Coordinates, Points, Paths
// Synopsis: Convert 3D cartesian coordinates to spherical coordinates. 
// See Also: cylindrical_to_xyz(), spherical_to_xyz(), xyz_to_cylindrical(), altaz_to_xyz(), xyz_to_altaz()
// Description:
//   Called with three arguments, converts the `x`, `y`, and `z` 3D cartesian coordinate into a `[RADIUS,THETA,PHI]` spherical coordinate.
//   Called with one `[X,Y,Z]` vector argument, converts the 3D cartesian coordinate into a `[RADIUS,THETA,PHI]` spherical coordinate.
//   Called with a list of `[X,Y,Z]` vector arguments, converts each 3D cartesian coordinate into `[RADIUS,THETA,PHI]` spherical coordinates.
//   Theta is the angle counter-clockwise of X+ on the XY plane.  Phi is the angle down from the Z+ pole.
// Arguments:
//   x = X coordinate.
//   y = Y coordinate.
//   z = Z coordinate.
// Example:
//   sph = xyz_to_spherical(20,30,40);
//   sph = xyz_to_spherical([40,50,70]);
//   sphs = xyz_to_spherical([[40,50,70], [25,-14,27]]);
function xyz_to_spherical(x,y,z) =
    y != undef
      ? assert(is_num(x) && is_num(y) && is_num(z), "\nBad arguments.")
        [norm([x,y,z]), atan2(y,x), atan2(norm([x,y]),z)]
      : assert(is_list(x), "\nBad arguments.")
        is_num(x.x)
          ? xyz_to_spherical(x.x, x.y, x.z)
          : [for(p = x) xyz_to_spherical(p.x, p.y, p.z)];


// Function: altaz_to_xyz()
// Synopsis: Convert altitude/azimuth/range to 3D cartesian coordinates. 
// SynTags: Path
// Topics: Coordinates, Points, Paths
// See Also: cylindrical_to_xyz(), xyz_to_spherical(), spherical_to_xyz(), xyz_to_cylindrical(), xyz_to_altaz()
// Usage:
//   pt = altaz_to_xyz(alt, az, r);
//   pt = altaz_to_xyz([ALT,AZ,R]);
//   pts = altaz_to_xyz([[ALT,AZ,R], [ALT,AZ,R], ...]);
// Description:
//   Convert altitude/azimuth/range coordinates to 3D cartesian coordinates.
//   Called with three arguments, converts the `alt`, `az`, and 'r' 3D altitude-azimuth coordinate into an `[X,Y,Z]` cartesian coordinate.
//   Called with one `[ALTITUDE,AZIMUTH,RANGE]` vector argument, converts the 3D alt-az coordinate into an `[X,Y,Z]` cartesian coordinate.
//   Called with a list of `[ALTITUDE,AZIMUTH,RANGE]` vector arguments, converts each 3D alt-az coordinate into `[X,Y,Z]` cartesian coordinates.
//   Altitude is the angle above the XY plane, Azimuth is degrees clockwise of Y+ on the XY plane, and Range is the distance from the origin.
// Arguments:
//   alt = altitude angle in degrees above the XY plane.
//   az = azimuth angle in degrees clockwise of Y+ on the XY plane.
//   r = distance from origin.
// Example:
//   xyz = altaz_to_xyz(20,30,40);
//   xyz = altaz_to_xyz([40,60,50]);
function altaz_to_xyz(alt,az,r) =
    az != undef
      ? assert(is_num(alt) && is_num(az) && is_num(r), "\nBad arguments.")
        r*[cos(90-az)*cos(alt), sin(90-az)*cos(alt), sin(alt)]
      : assert(is_list(alt), "\nBad arguments.")
        is_num(alt.x)
          ? altaz_to_xyz(alt.x, alt.y, alt.z)
          : [for(p = alt) altaz_to_xyz(p.x, p.y, p.z)];



// Function: xyz_to_altaz()
// Synopsis: Convert 3D cartesian coordinates to [altitude,azimuth,range]. 
// Topics: Coordinates, Points, Paths
// See Also: cylindrical_to_xyz(), xyz_to_spherical(), spherical_to_xyz(), xyz_to_cylindrical(), altaz_to_xyz()
// Usage:
//   alt_az_r = xyz_to_altaz(x,y,z);
//   alt_az_r = xyz_to_altaz([X,Y,Z]);
//   alt_az_rs = xyz_to_altaz([[X,Y,Z], [X,Y,Z], ...]);
// Description:
//   Converts 3D cartesian coordinates to altitude/azimuth/range coordinates.
//   Called with three arguments, converts the `x`, `y`, and `z` 3D cartesian coordinate into an `[ALTITUDE,AZIMUTH,RANGE]` coordinate.
//   Called with one `[X,Y,Z]` vector argument, converts the 3D cartesian coordinate into a `[ALTITUDE,AZIMUTH,RANGE]` coordinate.
//   Called with a list of `[X,Y,Z]` vector arguments, converts each 3D cartesian coordinate into `[ALTITUDE,AZIMUTH,RANGE]` coordinates.
//   Altitude is the angle above the XY plane, Azimuth is degrees clockwise of Y+ on the XY plane, and Range is the distance from the origin.
// Arguments:
//   x = X coordinate.
//   y = Y coordinate.
//   z = Z coordinate.
// Example:
//   aa = xyz_to_altaz(20,30,40);
//   aa = xyz_to_altaz([40,50,70]);
function xyz_to_altaz(x,y,z) =
    y != undef
      ? assert(is_num(x) && is_num(y) && is_num(z), "\nBad arguments.")
        [atan2(z,norm([x,y])), atan2(x,y), norm([x,y,z])]
      : assert(is_list(x), "Bad arguments.")
        is_num(x.x)
          ? xyz_to_altaz(x.x, x.y, x.z)
          : [for(p = x) xyz_to_altaz(p.x, p.y, p.z)];



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
