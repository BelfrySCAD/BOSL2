//////////////////////////////////////////////////////////////////////
// LibFile: coords.scad
//   Coordinate transformations and coordinate system conversions.
// Includes:
//   include <BOSL2/std.scad>
//////////////////////////////////////////////////////////////////////


// Section: Coordinate Manipulation

// Function: point2d()
// Usage:
//   pt = point2d(p, [fill]);
// Topics: Coordinates, Points
// See Also: path2d(), point3d(), path3d()
// Description:
//   Returns a 2D vector/point from a 2D or 3D vector.  If given a 3D point, removes the Z coordinate.
// Arguments:
//   p = The coordinates to force into a 2D vector/point.
//   fill = Value to fill missing values in vector with.
function point2d(p, fill=0) = [for (i=[0:1]) (p[i]==undef)? fill : p[i]];


// Function: path2d()
// Usage:
//   pts = path2d(points);
// Topics: Coordinates, Points, Paths
// See Also: point2d(), point3d(), path3d()
// Description:
//   Returns a list of 2D vectors/points from a list of 2D, 3D or higher dimensional vectors/points.
//   Removes the extra coordinates from higher dimensional points.  The input must be a path, where
//   every vector has the same length.
// Arguments:
//   points = A list of 2D or 3D points/vectors.
function path2d(points) =
    assert(is_path(points,dim=undef,fast=true),"Input to path2d is not a path")
    let (result = points * concat(ident(2), repeat([0,0], len(points[0])-2)))
    assert(is_def(result), "Invalid input to path2d")
    result;


// Function: point3d()
// Usage:
//   pt = point3d(p, [fill]);
// Topics: Coordinates, Points
// See Also: path2d(), point2d(), path3d()
// Description:
//   Returns a 3D vector/point from a 2D or 3D vector.
// Arguments:
//   p = The coordinates to force into a 3D vector/point.
//   fill = Value to fill missing values in vector with.
function point3d(p, fill=0) = [for (i=[0:2]) (p[i]==undef)? fill : p[i]];


// Function: path3d()
// Usage:
//   pts = path3d(points, [fill]);
// Topics: Coordinates, Points, Paths
// See Also: point2d(), path2d(), point3d()
// Description:
//   Returns a list of 3D vectors/points from a list of 2D or higher dimensional vectors/points
//   by removing extra coordinates or adding the z coordinate.  
// Arguments:
//   points = A list of 2D, 3D or higher dimensional points/vectors.
//   fill = Value to fill missing values in vectors with (in the 2D case)
function path3d(points, fill=0) =
    assert(is_num(fill))
    assert(is_path(points, dim=undef, fast=true), "Input to path3d is not a path")
    let (
        change = len(points[0])-3,
        M = change < 0? [[1,0,0],[0,1,0]] : 
            concat(ident(3), repeat([0,0,0],change)),
        result = points*M
    )
    assert(is_def(result), "Input to path3d is invalid")
    fill == 0 || change>=0 ? result : result + repeat([0,0,fill], len(result));


// Function: point4d()
// Usage:
//   pt = point4d(p, [fill]);
// Topics: Coordinates, Points
// See Also: point2d(), path2d(), point3d(), path3d(), path4d()
// Description:
//   Returns a 4D vector/point from a 2D or 3D vector.
// Arguments:
//   p = The coordinates to force into a 4D vector/point.
//   fill = Value to fill missing values in vector with.
function point4d(p, fill=0) = [for (i=[0:3]) (p[i]==undef)? fill : p[i]];


// Function: path4d()
// Usage:
//   pt = path4d(points, [fill]);
// Topics: Coordinates, Points, Paths
// See Also: point2d(), path2d(), point3d(), path3d(), point4d()
// Description:
//   Returns a list of 4D vectors/points from a list of 2D or 3D vectors/points.
// Arguments:
//   points = A list of 2D or 3D points/vectors.
//   fill = Value to fill missing values in vectors with.
function path4d(points, fill=0) = 
   assert(is_num(fill) || is_vector(fill))
   assert(is_path(points, dim=undef, fast=true), "Input to path4d is not a path")
   let (
      change = len(points[0])-4,
      M = change < 0 ? select(ident(4), 0, len(points[0])-1) :
                       concat(ident(4), repeat([0,0,0,0],change)),
      result = points*M
   ) 
   assert(is_def(result), "Input to path4d is invalid")
   fill == 0 || change >= 0 ? result :
    let(
      addition = is_list(fill) ? concat(0*points[0],fill) :
                                 concat(0*points[0],repeat(fill,-change))
    )
    assert(len(addition) == 4, "Fill is the wrong length")
    result + repeat(addition, len(result));



// Section: Coordinate Systems

// Function: polar_to_xy()
// Usage:
//   pt = polar_to_xy(r, theta);
//   pt = polar_to_xy([r, theta]);
// Topics: Coordinates, Points, Paths
// See Also: xy_to_polar(), xyz_to_cylindrical(), cylindrical_to_xyz(), xyz_to_spherical(), spherical_to_xyz()
// Description:
//   Convert polar coordinates to 2D cartesian coordinates.
//   Returns [X,Y] cartesian coordinates.
// Arguments:
//   r = distance from the origin.
//   theta = angle in degrees, counter-clockwise of X+.
// Examples:
//   xy = polar_to_xy(20,45);    // Returns: ~[14.1421365, 14.1421365]
//   xy = polar_to_xy(40,30);    // Returns: ~[34.6410162, 15]
//   xy = polar_to_xy([40,30]);  // Returns: ~[34.6410162, 15]
// Example(2D):
//   r=40; ang=30; $fn=36;
//   pt = polar_to_xy(r,ang);
//   stroke(circle(r=r), closed=true, width=0.5);
//   color("black") stroke([[r,0], [0,0], pt], width=0.5);
//   color("black") stroke(arc(r=15, angle=ang), width=0.5);
//   color("red") move(pt) circle(d=3);
function polar_to_xy(r,theta=undef) = let(
        rad = theta==undef? r[0] : r,
        t = theta==undef? r[1] : theta
    ) rad*[cos(t), sin(t)];


// Function: xy_to_polar()
// Usage:
//   r_theta = xy_to_polar(x,y);
//   r_theta = xy_to_polar([X,Y]);
// Topics: Coordinates, Points, Paths
// See Also: polar_to_xy(), xyz_to_cylindrical(), cylindrical_to_xyz(), xyz_to_spherical(), spherical_to_xyz()
// Description:
//   Convert 2D cartesian coordinates to polar coordinates.
//   Returns [radius, theta] where theta is the angle counter-clockwise of X+.
// Arguments:
//   x = X coordinate.
//   y = Y coordinate.
// Examples:
//   plr = xy_to_polar(20,30);
//   plr = xy_to_polar([40,60]);
// Example(2D):
//   pt = [-20,30]; $fn = 36;
//   rt = xy_to_polar(pt);
//   r = rt[0]; ang = rt[1];
//   stroke(circle(r=r), closed=true, width=0.5);
//   zrot(ang) stroke([[0,0],[r,0]],width=0.5);
//   color("red") move(pt) circle(d=3);
function xy_to_polar(x,y=undef) = let(
        xx = y==undef? x[0] : x,
        yy = y==undef? x[1] : y
    ) [norm([xx,yy]), atan2(yy,xx)];


// Function: project_plane()
// Usage: 
//   xy = project_plane(plane, p);
// Usage: To get a transform matrix
//   M = project_plane(plane)
// Description:
//   Maps the provided 3d point(s) from 3D coordinates to a 2d coordinate system defined by `plane`.  Points that are not
//   on the specified plane will be projected orthogonally onto the plane.  This coordinate system is useful if you need
//   to perform 2d operations on a coplanar set of data.  After those operations are done you can return the data
//   to 3d with `lift_plane()`.  You could also use this to force approximately coplanar data to be exactly coplanar.
//   The parameter p can be a point, path, region, bezier patch or VNF.
//   The plane can be specified as
//   - A list of three points.  The planar coordinate system will have [0,0] at plane[0], and plane[1] will lie on the Y+ axis.
//   - A list of coplanar points that define a plane (not-collinear)
//   - A plane definition `[A,B,C,D]` where `Ax+By+CZ=D`.  The closest point on that plane to the origin will map to the origin in the new coordinate system.
//   .
//   If you omit the point specification then `project_plane()` returns a rotation matrix that maps the specified plane to the XY plane.
//   Note that if you apply this transformation to data lying on the plane it will produce 3D points with the Z coordinate of zero.
// Topics: Coordinates, Points, Paths
// See Also: project_plane(), projection_on_plane()
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
          assert(!collinear(plane),"Points defining the plane must not be collinear")
          let(
              v = plane[2]-plane[0],
              y = unit(plane[1]-plane[0]),        // y axis goes to point b
              x = unit(v-(v*y)*y)   // x axis 
          )            
          affine3d_frame_map(x,y) * move(-plane[0])
    : is_vector(plane,4) && is_undef(p) ?            // no data, plane given in "plane"
          assert(_valid_plane(plane), "Plane is not valid")
          let(
               n = point3d(plane),
               cp = n * plane[3] / (n*n)
          )
          rot(from=n, to=UP) * move(-cp)
    : is_path(plane,3) && is_undef(p) ?               // no data, generic point list plane
          assert(len(plane)>=3, "Need three points to define a plane")
          let(plane = plane_from_points(plane))
          assert(is_def(plane), "Point list is not coplanar")
          project_plane(plane)
    : assert(is_def(p), str("Invalid plane specification: ",plane))
      is_vnf(p) ? [project_plane(plane,p[0]), p[1]] 
    : is_list(p) && is_list(p[0]) && is_vector(p[0][0],3) ?  // bezier patch or region
           [for(plist=p) project_plane(plane,plist)]
    : assert(is_vector(p,3) || is_path(p,3),str("Data must be a 3d point, path, region, vnf or bezier patch",p))
      is_matrix(plane,3,3) ?
          assert(!collinear(plane),"Points defining the plane must not be collinear")
          let(
              v = plane[2]-plane[0],
              y = unit(plane[1]-plane[0]),        // y axis goes to point b
              x = unit(v-(v*y)*y)  // x axis 
          ) move(-plane[0],p) * transpose([x,y])
    : is_vector(p) ? point2d(apply(project_plane(plane),p))
    : path2d(apply(project_plane(plane),p));



// Function: lift_plane()
// Usage: 
//   xyz = lift_plane(plane, p);
// Usage: to get transform matrix
//   M =  lift_plane(plane);
// Topics: Coordinates, Points, Paths
// See Also: project_plane()
// Description:
//   Converts the given 2D point on the plane to 3D coordinates of the specified plane.
//   The parameter p can be a point, path, region, bezier patch or VNF.
//   The plane can be specified as
//   - A list of three points.  The planar coordinate system will have [0,0] at plane[0], and plane[1] will lie on the Y+ axis.
//   - A list of coplanar points that define a plane (not-collinear)
//   - A plane definition `[A,B,C,D]` where `Ax+By+CZ=D`.  The closest point on that plane to the origin will map to the origin in the new coordinate system.
// If you do not supply `p` then you get a transformation matrix which operates in 3D, assuming that the Z coordinate of the points is zero.
// This matrix is a rotation, the inverse of the one produced by project_plane.
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
          move(plane[0]) * affine3d_frame_map(x,y,reverse=true)
    : is_vector(plane,4) && is_undef(p) ?            // no data, plane given in "plane"
          assert(_valid_plane(plane), "Plane is not valid")
          let(
               n = point3d(plane),
               cp = n * plane[3] / (n*n)
          )
          move(cp) * rot(from=UP, to=n)
    : is_path(plane,3) && is_undef(p) ?               // no data, generic point list plane
          assert(len(plane)>=3, "Need three p to define a plane")
          let(plane = plane_from_points(plane))
          assert(is_def(plane), "Point list is not coplanar")
          lift_plane(plane)
    : is_vnf(p) ? [lift_plane(plane,p[0]), p[1]] 
    : is_list(p) && is_list(p[0]) && is_vector(p[0][0],3) ?  // bezier patch or region
           [for(plist=p) lift_plane(plane,plist)]
    : assert(is_vector(p,2) || is_path(p,2),"Data must be a 2d point, path, region, vnf or bezier patch")
      is_matrix(plane,3,3) ?
          let(
              v = plane[2]-plane[0],
              y = unit(plane[1]-plane[0]),        // y axis goes to point b
              x = unit(v-(v*y)*y)  // x axis 
          ) move(plane[0],p * [x,y])
    : apply(lift_plane(plane),is_vector(p) ? point3d(p) : path3d(p));


// Function: cylindrical_to_xyz()
// Usage:
//   pt = cylindrical_to_xyz(r, theta, z);
//   pt = cylindrical_to_xyz([r, theta, z]);
// Topics: Coordinates, Points, Paths
// See Also: xyz_to_cylindrical(), xyz_to_spherical(), spherical_to_xyz()
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
//   rtz = xyz_to_cylindrical(x,y,z);
//   rtz = xyz_to_cylindrical([X,Y,Z]);
// Topics: Coordinates, Points, Paths
// See Also: cylindrical_to_xyz(), xyz_to_spherical(), spherical_to_xyz()
// Description:
//   Convert 3D cartesian coordinates to cylindrical coordinates.  Returns [radius,theta,Z].
//   Theta is the angle counter-clockwise of X+ on the XY plane.  Z is height above the XY plane.
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
//   pt = spherical_to_xyz(r, theta, phi);
//   pt = spherical_to_xyz([r, theta, phi]);
// Description:
//   Convert spherical coordinates to 3D cartesian coordinates.  Returns [X,Y,Z] cartesian coordinates.
// Topics: Coordinates, Points, Paths
// See Also: cylindrical_to_xyz(), xyz_to_spherical(), xyz_to_cylindrical()
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
//   r_theta_phi = xyz_to_spherical(x,y,z)
//   r_theta_phi = xyz_to_spherical([X,Y,Z])
// Topics: Coordinates, Points, Paths
// See Also: cylindrical_to_xyz(), spherical_to_xyz(), xyz_to_cylindrical()
// Description:
//   Convert 3D cartesian coordinates to spherical coordinates.  Returns [r,theta,phi], where phi is
//   the angle from the Z+ pole, and theta is degrees counter-clockwise of X+ on the XY plane.
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
//   pt = altaz_to_xyz(alt, az, r);
//   pt = altaz_to_xyz([alt, az, r]);
// Topics: Coordinates, Points, Paths
// See Also: cylindrical_to_xyz(), xyz_to_spherical(), spherical_to_xyz(), xyz_to_cylindrical(), xyz_to_altaz()
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
//   alt_az_r = xyz_to_altaz(x,y,z);
//   alt_az_r = xyz_to_altaz([X,Y,Z]);
// Topics: Coordinates, Points, Paths
// See Also: cylindrical_to_xyz(), xyz_to_spherical(), spherical_to_xyz(), xyz_to_cylindrical(), altaz_to_xyz()
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



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
