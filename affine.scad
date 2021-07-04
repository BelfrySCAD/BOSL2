//////////////////////////////////////////////////////////////////////
// LibFile: affine.scad
//   Matrix math and affine transformation matrices.
// Includes:
//   include <BOSL2/std.scad>
//////////////////////////////////////////////////////////////////////


// Section: Matrix Manipulation

// Function: ident()
// Usage:
//   mat = ident(n);
// Topics: Affine, Matrices
// Description:
//   Create an `n` by `n` square identity matrix.
// Arguments:
//   n = The size of the identity matrix square, `n` by `n`.
// Example:
//   mat = ident(3);
//   // Returns:
//   //   [
//   //     [1, 0, 0],
//   //     [0, 1, 0],
//   //     [0, 0, 1]
//   //   ]
// Example:
//   mat = ident(4);
//   // Returns:
//   //   [
//   //     [1, 0, 0, 0],
//   //     [0, 1, 0, 0],
//   //     [0, 0, 1, 0],
//   //     [0, 0, 0, 1]
//   //   ]
function ident(n) = [
    for (i = [0:1:n-1]) [
        for (j = [0:1:n-1]) (i==j)? 1 : 0
    ]
];


// Function: is_affine()
// Usage:
//   bool = is_affine(x, [dim]);
// Topics: Affine, Matrices, Transforms, Type Checking
// See Also: is_matrix()
// Description:
//   Tests if the given value is an affine matrix, possibly also checking it's dimenstion.
// Arguments:
//   x = The value to test for being an affine matrix.
//   dim = The number of dimensions the given affine is required to be for.  Generally 2 for 2D or 3 for 3D.  If given as a list of integers, allows any of the given dimensions.  Default: `[2,3]`
// Examples:
//   bool = is_affine(affine2d_scale([2,3]));  // Returns true
//   bool = is_affine(affine3d_scale([2,3,4]));  // Returns true
//   bool = is_affine(affine3d_scale([2,3,4]),2);  // Returns false
//   bool = is_affine(affine3d_scale([2,3]),2);  // Returns true
//   bool = is_affine(affine3d_scale([2,3,4]),3);  // Returns true
//   bool = is_affine(affine3d_scale([2,3]),3);  // Returns false
function is_affine(x,dim=[2,3]) =
    is_finite(dim)? is_affine(x,[dim]) :
    let( ll = len(x) )
    is_list(x) && in_list(ll-1,dim) &&
    [for (r=x) if(!is_list(r) || len(r)!=ll) 1] == [];


// Function: is_2d_transform()
// Usage:
//   x = is_2d_transform(t);
// Topics: Affine, Matrices, Transforms, Type Checking
// See Also: is_affine(), is_matrix()
// Description:
//   Checks if the input is a 3D transform that does not act on the z coordinate, except possibly
//   for a simple scaling of z.  Note that an input which is only a zscale returns false.
// Arguments:
//   t = The transformation matrix to check.
// Examples:
//   b = is_2d_transform(zrot(45));  // Returns: true
//   b = is_2d_transform(yrot(45));  // Returns: false
//   b = is_2d_transform(xrot(45));  // Returns: false
//   b = is_2d_transform(move([10,20,0]));  // Returns: true
//   b = is_2d_transform(move([10,20,30]));  // Returns: false
//   b = is_2d_transform(scale([2,3,4]));  // Returns: true
function is_2d_transform(t) =    // z-parameters are zero, except we allow t[2][2]!=1 so scale() works
  t[2][0]==0 && t[2][1]==0 && t[2][3]==0 && t[0][2] == 0 && t[1][2]==0 &&
  (t[2][2]==1 || !(t[0][0]==1 && t[0][1]==0 && t[1][0]==0 && t[1][1]==1));   // But rule out zscale()


// Function: affine2d_to_3d()
// Usage:
//   mat = affine2d_to_3d(m);
// Topics: Affine, Matrices, Transforms
// See Also: affine3d_to_2d()
// Description:
//   Takes a 3x3 affine2d matrix and returns its 4x4 affine3d equivalent.
// Example:
//   mat = affine2d_to_3d(affine2d_translate([10,20]));
//   // Returns:
//   //   [
//   //     [1, 0, 0, 10],
//   //     [0, 1, 0, 20],
//   //     [0, 0, 1,  0],
//   //     [0, 0, 0,  1],
//   //   ]
function affine2d_to_3d(m) = [
    [ m[0][0], m[0][1], 0, m[0][2] ],
    [ m[1][0], m[1][1], 0, m[1][2] ],
    [       0,       0, 1,       0 ],
    [ m[2][0], m[2][1], 0, m[2][2] ]
];


// Function: affine3d_to_2d()
// Usage:
//   mat = affine3d_to_2d(m);
// Topics: Affine, Matrices
// See Also: affine2d_to_3d()
// Description:
//   Takes a 4x4 affine3d matrix and returns its 3x3 affine2d equivalent.  3D transforms that would alter the Z coordinate are disallowed.
// Example:
//   mat = affine2d_to_3d(affine3d_translate([10,20,0]));
//   // Returns:
//   //   [
//   //     [1, 0, 10],
//   //     [0, 1, 20],
//   //     [0, 0,  1],
//   //   ]
function affine3d_to_2d(m) =
    assert(is_2d_transform(m))
    [
        for (r=[0:3]) if (r!=2) [
            for (c=[0:3]) if (c!=2) m[r][c]
        ]
    ];


// Function: apply()
// Usage:
//   pts = apply(transform, points);
// Topics: Affine, Matrices, Transforms
// Description:
//   Applies the specified transformation matrix to a point, pointlist, bezier patch or VNF.
//   Both inputs can be 2D or 3D, and it is also allowed to supply 3D transformations with 2D
//   data as long as the the only action on the z coordinate is a simple scaling.
// Arguments:
//   transform = The 2D or 3D transformation matrix to apply to the point/points.
//   points = The point, pointlist, bezier patch, or VNF to apply the transformation to.
// Example(3D):
//   path1 = path3d(circle(r=40));
//   tmat = xrot(45);
//   path2 = apply(tmat, path1);
//   #stroke(path1,closed=true);
//   stroke(path2,closed=true);
// Example(2D):
//   path1 = circle(r=40);
//   tmat = translate([10,5]);
//   path2 = apply(tmat, path1);
//   #stroke(path1,closed=true);
//   stroke(path2,closed=true);
// Example(2D):
//   path1 = circle(r=40);
//   tmat = rot(30) * back(15) * scale([1.5,0.5,1]);
//   path2 = apply(tmat, path1);
//   #stroke(path1,closed=true);
//   stroke(path2,closed=true);
function apply(transform,points) =
    points==[] ? [] :
    is_vector(points)
      ? /* Point */ apply(transform, [points])[0] :
    is_list(points) && len(points)==2 && is_path(points[0],3) && is_list(points[1]) && is_vector(points[1][0])
      ? /* VNF */ [apply(transform, points[0]), points[1]] :
    is_list(points) && is_list(points[0]) && is_vector(points[0][0])
      ? /* BezPatch */ [for (x=points) apply(transform,x)] :
    let(
        tdim = len(transform[0])-1,
        datadim = len(points[0])
    )
    tdim == 3 && datadim == 3 ? [for(p=points) point3d(transform*concat(p,[1]))] :
    tdim == 2 && datadim == 2 ? [for(p=points) point2d(transform*concat(p,[1]))] :
    tdim == 3 && datadim == 2 ?
        assert(is_2d_transform(transform), str("Transforms is 3d but points are 2d"))
        [for(p=points) point2d(transform*concat(p,[0,1]))] :
        assert(false, str("Unsupported combination: transform with dimension ",tdim,", data of dimension ",datadim));


// Function: rot_decode()
// Usage:
//   info = rot_decode(rotation,[long]); // Returns: [angle,axis,cp,translation]
// Topics: Affine, Matrices, Transforms
// Description:
//   Given an input 3D rigid transformation operator (one composed of just rotations and translations) represented
//   as a 4x4 matrix, compute the rotation and translation parameters of the operator.  Returns a list of the
//   four parameters, the angle, in the interval [0,180], the rotation axis as a unit vector, a centerpoint for
//   the rotation, and a translation.  If you set `parms = rot_decode(rotation)` then the transformation can be
//   reconstructed from parms as `move(parms[3]) * rot(a=parms[0],v=parms[1],cp=parms[2])`.  This decomposition
//   makes it possible to perform interpolation.  If you construct a transformation using `rot` the decoding
//   may flip the axis (if you gave an angle outside of [0,180]).  The returned axis will be a unit vector, and
//   the centerpoint lies on the plane through the origin that is perpendicular to the axis.  It may be different
//   than the centerpoint you used to construct the transformation.
//   .
//   If you set `long` to true then return the reversed rotation, with the angle in [180,360].
// Arguments:
//   rotation = rigid transformation to decode
//   long = if true return the "long way" around, with the angle in [180,360].  Default: false
// Example:
//   info = rot_decode(rot(45));
//   // Returns: [45, [0,0,1], [0,0,0], [0,0,0]]
// Example:
//   info = rot_decode(rot(a=37, v=[1,2,3], cp=[4,3,-7])));
//   // Returns: [37, [0.26, 0.53, 0.80], [4.8, 4.6, -4.6], [0,0,0]]
// Example:
//   info = rot_decode(left(12)*xrot(-33));
//   // Returns: [33, [-1,0,0], [0,0,0], [-12,0,0]]
// Example:
//   info = rot_decode(translate([3,4,5]));
//   // Returns: [0, [0,0,1], [0,0,0], [3,4,5]]
function rot_decode(M,long=false) =
    assert(is_matrix(M,4,4) && approx(M[3],[0,0,0,1]), "Input matrix must be a 4x4 matrix representing a 3d transformation")
    let(R = submatrix(M,[0:2],[0:2]))
    assert(approx(det3(R),1) && approx(norm_fro(R * transpose(R)-ident(3)),0),"Input matrix is not a rotation")
    let(
        translation = [for(row=[0:2]) M[row][3]],   // translation vector
        largest  = max_index([R[0][0], R[1][1], R[2][2]]),
        axis_matrix = R + transpose(R) - (matrix_trace(R)-1)*ident(3),   // Each row is on the rotational axis
            // Construct quaternion q = c * [x sin(theta/2), y sin(theta/2), z sin(theta/2), cos(theta/2)]
        q_im = axis_matrix[largest],
        q_re = R[(largest+2)%3][(largest+1)%3] - R[(largest+1)%3][(largest+2)%3],
        c_sin = norm(q_im),              // c * sin(theta/2) for some c
        c_cos = abs(q_re)                // c * cos(theta/2)
    )
    approx(c_sin,0) ? [0,[0,0,1],[0,0,0],translation] :
    let(
        angle = 2*atan2(c_sin, c_cos),    // This is supposed to be more accurate than acos or asin
        axis  = (q_re>=0 ? 1:-1)*q_im/c_sin,
        tproj = translation - (translation*axis)*axis,    // Translation perpendicular to axis determines centerpoint
        cp    = (tproj + cross(axis,tproj)*c_cos/c_sin)/2
    )
    [long ? 360-angle:angle,
     long? -axis : axis,
     cp,
     (translation*axis)*axis];


// Function: rot_inverse()
// Usage:
//   B = rot_inverse(A)
// Description:
//   Inverts a 2d or 3d rotation matrix.  The matrix can be a rotation around any center,
//   so it may include a translation.
function rot_inverse(T) =
    assert(is_matrix(T,square=true),"Matrix must be square")
    let( n = len(T))
    assert(n==3 || n==4, "Matrix must be 3x3 or 4x4")
    let(
        rotpart =  [for(i=[0:n-2]) [for(j=[0:n-2]) T[j][i]]],
        transpart = [for(row=[0:n-2]) T[row][n-1]]
    )
    assert(approx(determinant(T),1),"Matrix is not a rotation")
    concat(hstack(rotpart, -rotpart*transpart),[[for(i=[2:n]) 0, 1]]);


function _closest_angle(alpha,beta) =
    is_vector(beta) ? [for(entry=beta) _closest_angle(alpha,entry)]
  : beta-alpha > 180 ? beta - ceil((beta-alpha-180)/360) * 360 
  : beta-alpha < -180 ? beta + ceil((alpha-beta-180)/360) * 360
  : beta;


// Smooth data with N point moving average.  If angle=true handles data as angles.
// If closed=true assumes last point is adjacent to the first one.
// If closed=false pads data with left/right value (probably wrong behavior...should do linear interp)
function _smooth(data,len,closed=false,angle=false) =
  let(  halfwidth = floor(len/2),
        result = closed ? [for(i=idx(data))
                           let(
                             window = angle ? _closest_angle(data[i],select(data,i-halfwidth,i+halfwidth))
                                            : select(data,i-halfwidth,i+halfwidth)
                           )
                           mean(window)]
               : [for(i=idx(data))
                   let(
                       window = select(data,max(i-halfwidth,0),min(i+halfwidth,len(data)-1)),
                       left = i-halfwidth<0,
                       pad = left ? data[0] : last(data)
                   )
                   sum(window)+pad*(len-len(window))] / len
   )
   result;

// Function: rot_resample()
// Usage:
//   rlist = rot_resample(rotlist, N, [method], [twist], [scale], [smoothlen], [long], [turns], [closed])
// Description:
//   Takes as input a list of rotation matrices in 3d.  Produces as output a resampled
//   list of rotation operators (4x4 matrixes) suitable for use with sweep().  You can optionally apply twist to
//   the output with the twist parameter, which is either a scalar to apply a uniform
//   overall twist, or a vector to apply twist non-uniformly.  Similarly you can apply
//   scaling either overall or with a vector.  The smoothlen parameter applies smoothing
//   to the twist and scaling to prevent abrupt changes.  This is done by a moving average
//   of the smoothing or scaling values.  The default of 1 means no smoothing.  The long parameter causes
//   the interpolation to be done the "long" way around the rotation instead of the short way.
//   Note that the rotation matrix cannot distinguish which way you rotate, only the place you
//   end after rotation.  Another ambiguity arises if your rotation is more than 360 degrees.
//   You can add turns with the turns parameter, so giving turns=1 will add 360 degrees to the
//   rotation so it completes one full turn plus the additional rotation given my the transform.
//   You can give long as a scalar or as a vector.  Finally if closed is true then the
//   resampling will connect back to the beginning.
//   .
//   The default is to resample based on the length of the arc defined by each rotation operator.  This produces
//   uniform sampling over all of the transformations.  It requires that each rotation has nonzero length.
//   In this case N specifies the total number of samples.  If you set method to "count" then N you get
//   N samples for each transform.  You can set N to a vector to vary the samples at each step.  
// Arguments:
//   rotlist = list of rotation operators in 3d to resample
//   N = Number of rotations to produce as output when method is "length" or number for each transformation if method is "count".  Can be a vector when method is "count"
//   --
//   method = sampling method, either "length" or "count"
//   twist = scalar or vector giving twist to add overall or at each rotation.  Default: none
//   scale = scalar or vector giving scale factor to add overall or at each rotation.  Default: none
//   smoothlen = amount of smoothing to apply to scaling and twist.  Should be an odd integer.  Default: 1
//   long = resample the "long way" around the rotation, a boolean or list of booleans.  Default: false
//   turns = add extra turns.  If a scalar adds the turns to every rotation, or give a vector.  Default: 0
//   closed = if true then the rotation list is treated as closed.  Default: false
// Example: Resampling the arc from a compound rotation with translations thrown in.  
//   tran = rot_resample([ident(4), back(5)*up(4)*xrot(-10)*zrot(-20)*yrot(117,cp=[10,0,0])], N=25);
//   sweep(circle(r=1,$fn=3), tran);
// Example: Applying a scale factor
//   tran = rot_resample([ident(4), back(5)*up(4)*xrot(-10)*zrot(-20)*yrot(117,cp=[10,0,0])], N=25, scale=2);
//   sweep(circle(r=1,$fn=3), tran);
// Example: Applying twist
//   tran = rot_resample([ident(4), back(5)*up(4)*xrot(-10)*zrot(-20)*yrot(117,cp=[10,0,0])], N=25, twist=60);
//   sweep(circle(r=1,$fn=3), tran);
// Example: Going the long way
//   tran = rot_resample([ident(4), back(5)*up(4)*xrot(-10)*zrot(-20)*yrot(117,cp=[10,0,0])], N=25, long=true);
//   sweep(circle(r=1,$fn=3), tran);
// Example: Getting transformations from turtle3d
//   include<BOSL2/turtle3d.scad>
//   tran=turtle3d(["arcsteps",1,"up", 10, "arczrot", 10,170],transforms=true);
//   sweep(circle(r=1,$fn=3),rot_resample(tran, N=40));
// Example: If you specify a larger angle in turtle you need to use the long argument
//   include<BOSL2/turtle3d.scad>
//   tran=turtle3d(["arcsteps",1,"up", 10, "arczrot", 10,270],transforms=true);
//   sweep(circle(r=1,$fn=3),rot_resample(tran, N=40,long=true));
// Example: And if the angle is over 360 you need to add turns to get the right result.  Note long is false when the remaining angle after subtracting full turns is below 180:
//   include<BOSL2/turtle3d.scad>
//   tran=turtle3d(["arcsteps",1,"up", 10, "arczrot", 10,90+360],transforms=true);
//   sweep(circle(r=1,$fn=3),rot_resample(tran, N=40,long=false,turns=1));
// Example: Here the remaining angle is 270, so long must be set to true
//   include<BOSL2/turtle3d.scad>
//   tran=turtle3d(["arcsteps",1,"up", 10, "arczrot", 10,270+360],transforms=true);
//   sweep(circle(r=1,$fn=3),rot_resample(tran, N=40,long=true,turns=1));
// Example: Note the visible line at the scale transition
//   include<BOSL2/turtle3d.scad>
//   tran = turtle3d(["arcsteps",1,"arcup", 10, 90, "arcdown", 10, 90], transforms=true);
//   rtran = rot_resample(tran,200,scale=[1,6]);
//   sweep(circle(1,$fn=32),rtran);
// Example: Observe how using a large smoothlen value eases that transition
//   include<BOSL2/turtle3d.scad>
//   tran = turtle3d(["arcsteps",1,"arcup", 10, 90, "arcdown", 10, 90], transforms=true);
//   rtran = rot_resample(tran,200,scale=[1,6],smoothlen=17);
//   sweep(circle(1,$fn=32),rtran);
// Example: A similar issues can arise with twist, where a "line" is visible at the transition
//   include<BOSL2/turtle3d.scad>
//   tran = turtle3d(["arcsteps", 1, "arcup", 10, 90, "move", 10], transforms=true,state=[1,-.5,0]);
//   rtran = rot_resample(tran,100,twist=[0,60],smoothlen=1);
//   sweep(subdivide_path(rect([3,3]),40),rtran);
// Example: Here's the smoothed twist transition
//   include<BOSL2/turtle3d.scad>
//   tran = turtle3d(["arcsteps", 1, "arcup", 10, 90, "move", 10], transforms=true,state=[1,-.5,0]);
//   rtran = rot_resample(tran,100,twist=[0,60],smoothlen=17);
//   sweep(subdivide_path(rect([3,3]),40),rtran);
// Example: toothed belt based on list-comprehension-demos example.  This version has a smoothed twist transition.  Try changing smoothlen to 1 to see the more abrupt transition that occurs without smoothing.  
//   include<BOSL2/turtle3d.scad>
//   r_small = 19;       // radius of small curve
//   r_large = 46;       // radius of large curve
//   flat_length = 100;  // length of flat belt section
//   teeth=42;           // number of teeth
//   belt_width = 12;
//   tooth_height = 9;
//   belt_thickness = 3;
//   angle = 180 - 2*atan((r_large-r_small)/flat_length);
//   beltprofile = path3d(subdivide_path(
//                   square([belt_width, belt_thickness],anchor=FWD),
//                   20));
//   beltrots =
//     turtle3d(["arcsteps",1,          
//               "move", flat_length,
//               "arcleft", r_small, angle,
//               "move", flat_length,
//     // Closing path will be interpolated            
//     //        "arcleft", r_large, 360-angle    
//              ],transforms=true);
//   beltpath = rot_resample(beltrots,teeth*4,
//                           twist=[180,0,-180,0],
//                           long=[false,false,false,true],
//                           smoothlen=15,closed=true);
//   belt = [for(i=idx(beltpath))
//             let(tooth = floor((i+$t*4)/2)%2)
//             apply(beltpath[i]*
//                     yscale(tooth
//                            ? tooth_height/belt_thickness
//                            : 1),
//                   beltprofile)
//          ];
//   skin(belt,slices=0,closed=true);
function rot_resample(rotlist,N,twist,scale,smoothlen=1,long=false,turns=0,closed=false,method="length") =
    assert(is_int(smoothlen) && smoothlen>0 && smoothlen%2==1, "smoothlen must be a positive odd integer")
    assert(method=="length" || method=="count")
    let(tcount = len(rotlist) + (closed?0:-1))
    assert(method=="count" || is_int(N), "N must be an integer when method is \"length\"")
    assert(is_int(N) || is_vector(N,tcount), str("N must be scalar or vector with length ",tcount))
    let(
          count = method=="length" ? (closed ? N+1 : N)
                                   : (is_vector(N) ? sum(N) : tcount*N)+1  //(closed?0:1)
    )
    assert(is_bool(long) || len(long)==tcount,str("Input long must be a scalar or have length ",tcount))
    let(      
        long = force_list(long,tcount),
        turns = force_list(turns,tcount),
        T = [for(i=[0:1:tcount-1]) rot_inverse(rotlist[i])*select(rotlist,i+1)],
        parms = [for(i=idx(T))
                    let(tparm = rot_decode(T[i],long[i]))
                    [tparm[0]+turns[i]*360,tparm[1],tparm[2],tparm[3]]
                ],
        radius = [for(i=idx(parms)) norm(parms[i][2])],
        length = [for(i=idx(parms)) norm([norm(parms[i][3]), parms[i][0]/360*2*PI*radius[i]])]
    )
    assert(method=="count" || all_positive(length),
           "Rotation list includes a repeated entry or a rotation around the origin, not allowed when method=\"length\"")
    let(   
        cumlen = [0, each cumsum(length)],
        totlen = last(cumlen),
        stepsize = totlen/(count-1),
        samples = method=="count"
                  ? let( N = force_list(N,tcount))
                    [for(n=N) lerpn(0,1,n,endpoint=false)]
                  :[for(i=idx(parms))
                    let(
                        remainder = cumlen[i] % stepsize,
                        offset = remainder==0 ? 0
                                              : stepsize-remainder,
                        num = ceil((length[i]-offset)/stepsize)
                    )
                    count(num,offset,stepsize)/length[i]],
         twist = first_defined([twist,0]),
         scale = first_defined([scale,1]),
         needlast = !approx(last(last(samples)),1),
         sampletwist = is_num(twist) ? lerpn(0,twist,count)
                     : let(
                          cumtwist = [0,each cumsum(twist)]
                      )
                      [for(i=idx(parms)) each lerp(cumtwist[i],cumtwist[i+1],samples[i]),
                      if (needlast) last(cumtwist)
                      ],
         samplescale = is_num(scale) ? lerp(1,scale,lerpn(0,1,count))
                     : let(
                          cumscale = [1,each cumprod(scale)]
                      )
                      [for(i=idx(parms)) each lerp(cumscale[i],cumscale[i+1],samples[i]),
                       if (needlast) last(cumscale)],
         smoothtwist = _smooth(closed?select(sampletwist,0,-2):sampletwist,smoothlen,closed=closed,angle=true),
         smoothscale = _smooth(samplescale,smoothlen,closed=closed),
         interpolated = [
           for(i=idx(parms))
             each [for(u=samples[i]) rotlist[i] * move(u*parms[i][3]) * rot(a=u*parms[i][0],v=parms[i][1],cp=parms[i][2])],
           if (needlast) last(rotlist)
         ]
     )
     [for(i=idx(interpolated,e=closed?-2:-1)) interpolated[i]*zrot(smoothtwist[i])*scale(smoothscale[i])];



// Section: Affine2d 3x3 Transformation Matrices


// Function: affine2d_identity()
// Usage:
//   mat = affine2d_identify();
// Topics: Affine, Matrices, Transforms
// Description:
//   Create a 3x3 affine2d identity matrix.
// Example:
//   mat = affine2d_identity();
//   // Returns:
//   //   [
//   //     [1, 0, 0],
//   //     [0, 1, 0],
//   //     [0, 0, 1]
//   //   ]
function affine2d_identity() = ident(3);


// Function: affine2d_translate()
// Usage:
//   mat = affine2d_translate(v);
// Topics: Affine, Matrices, Transforms, Translation
// See Also: move(), affine3d_translate()
// Description:
//   Returns the 3x3 affine2d matrix to perform a 2D translation.
// Arguments:
//   v = 2D Offset to translate by.  [X,Y]
// Example:
//   mat = affine2d_translate([30,40]);
//   // Returns:
//   //   [
//   //     [1, 0, 30],
//   //     [0, 1, 40],
//   //     [0, 0,  1]
//   //   ]
function affine2d_translate(v=[0,0]) =
    assert(is_vector(v),2)
    [
        [1, 0, v.x],
        [0, 1, v.y],
        [0 ,0,   1]
    ];


// Function: affine2d_scale()
// Usage:
//   mat = affine2d_scale(v);
// Topics: Affine, Matrices, Transforms, Scaling
// See Also: scale(), xscale(), yscale(), zscale(), affine3d_scale()
// Description:
//   Returns the 3x3 affine2d matrix to perform a 2D scaling transformation.
// Arguments:
//   v = 2D vector of scaling factors.  [X,Y]
// Example:
//   mat = affine2d_scale([3,4]);
//   // Returns:
//   //   [
//   //     [3, 0, 0],
//   //     [0, 4, 0],
//   //     [0, 0, 1]
//   //   ]
function affine2d_scale(v=[1,1]) =
    assert(is_vector(v,2))
    [
        [v.x,   0, 0],
        [  0, v.y, 0],
        [  0,   0, 1]
    ];


// Function: affine2d_zrot()
// Usage:
//   mat = affine2d_zrot(ang);
// Topics: Affine, Matrices, Transforms, Rotation
// See Also: rot(), xrot(), yrot(), zrot(), affine3d_zrot()
// Description:
//   Returns the 3x3 affine2d matrix to perform a rotation of a 2D vector around the Z axis.
// Arguments:
//   ang = Number of degrees to rotate.
// Example:
//   mat = affine2d_zrot(90);
//   // Returns:
//   //   [
//   //     [0,-1, 0],
//   //     [1, 0, 0],
//   //     [0, 0, 1]
//   //   ]
function affine2d_zrot(ang=0) =
    assert(is_finite(ang))
    [
        [cos(ang), -sin(ang), 0],
        [sin(ang),  cos(ang), 0],
        [       0,         0, 1]
    ];


// Function: affine2d_mirror()
// Usage:
//   mat = affine2d_mirror(v);
// Topics: Affine, Matrices, Transforms, Reflection, Mirroring
// See Also: mirror(), xflip(), yflip(), zflip(), affine3d_mirror()
// Description:
//   Returns the 3x3 affine2d matrix to perform a reflection of a 2D vector across the line given by its normal vector.
// Arguments:
//   v = The normal vector of the line to reflect across.
// Example:
//   mat = affine2d_mirror([0,1]);
//   // Returns:
//   //   [
//   //     [ 1, 0, 0],
//   //     [ 0,-1, 0],
//   //     [ 0, 0, 1]
//   //   ]
// Example:
//   mat = affine2d_mirror([1,0]);
//   // Returns:
//   //   [
//   //     [-1, 0, 0],
//   //     [ 0, 1, 0],
//   //     [ 0, 0, 1]
//   //   ]
// Example:
//   mat = affine2d_mirror([1,1]);
//   // Returns approximately:
//   //   [
//   //     [ 0,-1, 0],
//   //     [-1, 0, 0],
//   //     [ 0, 0, 1]
//   //   ]
function affine2d_mirror(v) =
    assert(is_vector(v,2))
    let(v=unit(point2d(v)), a=v.x, b=v.y)
    [
        [1-2*a*a, 0-2*a*b, 0],
        [0-2*a*b, 1-2*b*b, 0],
        [      0,       0, 1]
    ];


// Function: affine2d_skew()
// Usage:
//   mat = affine2d_skew(xa);
//   mat = affine2d_skew(ya=);
//   mat = affine2d_skew(xa, ya);
// Topics: Affine, Matrices, Transforms, Skewing
// See Also: skew(), affine3d_skew()
// Description:
//   Returns the 3x3 affine2d matrix to skew a 2D vector along the XY plane.
// Arguments:
//   xa = Skew angle, in degrees, in the direction of the X axis. Default: 0
//   ya = Skew angle, in degrees, in the direction of the Y axis. Default: 0
// Example:
//   mat = affine2d_skew(xa=45,ya=-45);
//   // Returns approximately:
//   //   [
//   //     [ 1, 1, 0],
//   //     [-1, 1, 0],
//   //     [ 0, 0, 1]
//   //   ]
function affine2d_skew(xa=0, ya=0) =
    assert(is_finite(xa))
    assert(is_finite(ya))
    [
        [1,       tan(xa), 0],
        [tan(ya), 1,       0],
        [0,       0,       1]
    ];



// Section: Affine3d 4x4 Transformation Matrices


// Function: affine3d_identity()
// Usage:
//   mat = affine3d_identity();
// Topics: Affine, Matrices, Transforms
// Description:
//   Create a 4x4 affine3d identity matrix.
// Example:
//   mat = affine2d_identity();
//   // Returns:
//   //   [
//   //     [1, 0, 0, 0],
//   //     [0, 1, 0, 0],
//   //     [0, 0, 1, 0],
//   //     [0, 0, 0, 1]
//   //   ]
function affine3d_identity() = ident(4);


// Function: affine3d_translate()
// Usage:
//   mat = affine3d_translate(v);
// Topics: Affine, Matrices, Transforms, Translation
// See Also: move(), affine2d_translate()
// Description:
//   Returns the 4x4 affine3d matrix to perform a 3D translation.
// Arguments:
//   v = 3D offset to translate by.  [X,Y,Z]
// Example:
//   mat = affine2d_translate([30,40,50]);
//   // Returns:
//   //   [
//   //     [1, 0, 0, 30],
//   //     [0, 1, 0, 40],
//   //     [0, 0, 1, 50]
//   //     [0, 0, 0,  1]
//   //   ]
function affine3d_translate(v=[0,0,0]) =
    assert(is_list(v))
    let( v = [for (i=[0:2]) default(v[i],0)] )
    [
        [1, 0, 0, v.x],
        [0, 1, 0, v.y],
        [0, 0, 1, v.z],
        [0 ,0, 0,   1]
    ];


// Function: affine3d_scale()
// Usage:
//   mat = affine3d_scale(v);
// Topics: Affine, Matrices, Transforms, Scaling
// See Also: scale(), affine2d_scale()
// Description:
//   Returns the 4x4 affine3d matrix to perform a 3D scaling transformation.
// Arguments:
//   v = 3D vector of scaling factors.  [X,Y,Z]
// Example:
//   mat = affine3d_scale([3,4,5]);
//   // Returns:
//   //   [
//   //     [3, 0, 0, 0],
//   //     [0, 4, 0, 0],
//   //     [0, 0, 5, 0],
//   //     [0, 0, 0, 1]
//   //   ]
function affine3d_scale(v=[1,1,1]) =
    assert(is_list(v))
    let( v = [for (i=[0:2]) default(v[i],1)] )
    [
        [v.x,   0,   0, 0],
        [  0, v.y,   0, 0],
        [  0,   0, v.z, 0],
        [  0,   0,   0, 1]
    ];


// Function: affine3d_xrot()
// Usage:
//   mat = affine3d_xrot(ang);
// Topics: Affine, Matrices, Transforms, Rotation
// See Also: rot(), xrot(), yrot(), zrot(), affine2d_zrot()
// Description:
//   Returns the 4x4 affine3d matrix to perform a rotation of a 3D vector around the X axis.
// Arguments:
//   ang = number of degrees to rotate.
// Example:
//   mat = affine3d_xrot(90);
//   // Returns:
//   //   [
//   //     [1, 0, 0, 0],
//   //     [0, 0,-1, 0],
//   //     [0, 1, 0, 0],
//   //     [0, 0, 0, 1]
//   //   ]
function affine3d_xrot(ang=0) =
    assert(is_finite(ang))
    [
        [1,        0,         0,   0],
        [0, cos(ang), -sin(ang),   0],
        [0, sin(ang),  cos(ang),   0],
        [0,        0,         0,   1]
    ];


// Function: affine3d_yrot()
// Usage:
//   mat = affine3d_yrot(ang);
// Topics: Affine, Matrices, Transforms, Rotation
// See Also: rot(), xrot(), yrot(), zrot(), affine2d_zrot()
// Description:
//   Returns the 4x4 affine3d matrix to perform a rotation of a 3D vector around the Y axis.
// Arguments:
//   ang = Number of degrees to rotate.
// Example:
//   mat = affine3d_yrot(90);
//   // Returns:
//   //   [
//   //     [ 0, 0, 1, 0],
//   //     [ 0, 1, 0, 0],
//   //     [-1, 0, 0, 0],
//   //     [ 0, 0, 0, 1]
//   //   ]
function affine3d_yrot(ang=0) =
    assert(is_finite(ang))
    [
        [ cos(ang), 0, sin(ang),   0],
        [        0, 1,        0,   0],
        [-sin(ang), 0, cos(ang),   0],
        [        0, 0,        0,   1]
    ];


// Function: affine3d_zrot()
// Usage:
//   mat = affine3d_zrot(ang);
// Topics: Affine, Matrices, Transforms, Rotation
// See Also: rot(), xrot(), yrot(), zrot(), affine2d_zrot()
// Description:
//   Returns the 4x4 affine3d matrix to perform a rotation of a 3D vector around the Z axis.
// Arguments:
//   ang = number of degrees to rotate.
// Example:
//   mat = affine3d_zrot(90);
//   // Returns:
//   //   [
//   //     [ 0,-1, 0, 0],
//   //     [ 1, 0, 0, 0],
//   //     [ 0, 0, 1, 0],
//   //     [ 0, 0, 0, 1]
//   //   ]
function affine3d_zrot(ang=0) =
    assert(is_finite(ang))
    [
        [cos(ang), -sin(ang), 0, 0],
        [sin(ang),  cos(ang), 0, 0],
        [       0,         0, 1, 0],
        [       0,         0, 0, 1]
    ];


// Function: affine3d_rot_by_axis()
// Usage:
//   mat = affine3d_rot_by_axis(u, ang);
// Topics: Affine, Matrices, Transforms, Rotation
// See Also: rot(), xrot(), yrot(), zrot(), affine2d_zrot()
// Description:
//   Returns the 4x4 affine3d matrix to perform a rotation of a 3D vector around an axis.
// Arguments:
//   u = 3D axis vector to rotate around.
//   ang = number of degrees to rotate.
// Example:
//   mat = affine3d_rot_by_axis([1,1,1], 120);
//   // Returns approx:
//   //   [
//   //     [ 0, 0, 1, 0],
//   //     [ 1, 0, 0, 0],
//   //     [ 0, 1, 0, 0],
//   //     [ 0, 0, 0, 1]
//   //   ]
function affine3d_rot_by_axis(u=UP, ang=0) =
    assert(is_finite(ang))
    assert(is_vector(u,3))
    approx(ang,0)? affine3d_identity() :
    let(
        u = unit(u),
        c = cos(ang),
        c2 = 1-c,
        s = sin(ang)
    ) [
        [u.x*u.x*c2+c    , u.x*u.y*c2-u.z*s, u.x*u.z*c2+u.y*s, 0],
        [u.y*u.x*c2+u.z*s, u.y*u.y*c2+c    , u.y*u.z*c2-u.x*s, 0],
        [u.z*u.x*c2-u.y*s, u.z*u.y*c2+u.x*s, u.z*u.z*c2+c    , 0],
        [               0,                0,                0, 1]
    ];


// Function: affine3d_rot_from_to()
// Usage:
//   mat = affine3d_rot_from_to(from, to);
// Topics: Affine, Matrices, Transforms, Rotation
// See Also: rot(), xrot(), yrot(), zrot(), affine2d_zrot()
// Description:
//   Returns the 4x4 affine3d matrix to perform a rotation of a 3D vector from one vector direction to another.
// Arguments:
//   from = 3D axis vector to rotate from.
//   to = 3D axis vector to rotate to.
// Example:
//   mat = affine3d_rot_from_to(UP, RIGHT);
//   // Returns:
//   //   [
//   //     [ 0, 0, 1, 0],
//   //     [ 0, 1, 0, 0],
//   //     [-1, 0, 0, 0],
//   //     [ 0, 0, 0, 1]
//   //   ]
function affine3d_rot_from_to(from, to) =
    assert(is_vector(from))
    assert(is_vector(to))
    assert(len(from)==len(to))
    let(
        from = unit(point3d(from)),
        to = unit(point3d(to))
    ) approx(from,to)? affine3d_identity() :
    let(
        u = vector_axis(from,to),
        ang = vector_angle(from,to),
        c = cos(ang),
        c2 = 1-c,
        s = sin(ang)
    ) [
        [u.x*u.x*c2+c    , u.x*u.y*c2-u.z*s, u.x*u.z*c2+u.y*s, 0],
        [u.y*u.x*c2+u.z*s, u.y*u.y*c2+c    , u.y*u.z*c2-u.x*s, 0],
        [u.z*u.x*c2-u.y*s, u.z*u.y*c2+u.x*s, u.z*u.z*c2+c    , 0],
        [               0,                0,                0, 1]
    ];


// Function: affine3d_frame_map()
// Usage:
//   map = affine3d_frame_map(v1, v2, v3, [reverse=]);
//   map = affine3d_frame_map(x=VECTOR1, y=VECTOR2, [reverse=]);
//   map = affine3d_frame_map(x=VECTOR1, z=VECTOR2, [reverse=]);
//   map = affine3d_frame_map(y=VECTOR1, z=VECTOR2, [reverse=]);
// Topics: Affine, Matrices, Transforms, Rotation
// See Also: rot(), xrot(), yrot(), zrot(), affine2d_zrot()
// Description:
//   Returns a transformation that maps one coordinate frame to another.  You must specify two or
//   three of `x`, `y`, and `z`.  The specified axes are mapped to the vectors you supplied.  If you
//   give two inputs, the third vector is mapped to the appropriate normal to maintain a right hand
//   coordinate system.  If the vectors you give are orthogonal the result will be a rotation and the
//   `reverse` parameter will supply the inverse map, which enables you to map two arbitrary
//   coordinate systems to each other by using the canonical coordinate system as an intermediary.
//   You cannot use the `reverse` option with non-orthogonal inputs.
// Arguments:
//   x = Destination 3D vector for x axis.
//   y = Destination 3D vector for y axis.
//   z = Destination 3D vector for z axis.
//   reverse = reverse direction of the map for orthogonal inputs.  Default: false
// Example:
//   T = affine3d_frame_map(x=[1,1,0], y=[-1,1,0]);   // This map is just a rotation around the z axis
// Example:
//   T = affine3d_frame_map(x=[1,0,0], y=[1,1,0]);    // This map is not a rotation because x and y aren't orthogonal
// Example:
//   // The next map sends [1,1,0] to [0,1,1] and [-1,1,0] to [0,-1,1]
//   T = affine3d_frame_map(x=[0,1,1], y=[0,-1,1]) * affine3d_frame_map(x=[1,1,0], y=[-1,1,0],reverse=true);
function affine3d_frame_map(x,y,z, reverse=false) =
    assert(num_defined([x,y,z])>=2, "Must define at least two inputs")
    let(
        xvalid = is_undef(x) || (is_vector(x) && len(x)==3),
        yvalid = is_undef(y) || (is_vector(y) && len(y)==3),
        zvalid = is_undef(z) || (is_vector(z) && len(z)==3)
    )
    assert(xvalid,"Input x must be a length 3 vector")
    assert(yvalid,"Input y must be a length 3 vector")
    assert(zvalid,"Input z must be a length 3 vector")
    let(
        x = is_undef(x)? undef : unit(x,RIGHT),
        y = is_undef(y)? undef : unit(y,BACK),
        z = is_undef(z)? undef : unit(z,UP),
        map = is_undef(x)? [cross(y,z), y, z] :
            is_undef(y)? [x, cross(z,x), z] :
            is_undef(z)? [x, y, cross(x,y)] :
            [x, y, z]
    )
    reverse? (
        let(
            ocheck = (
                approx(map[0]*map[1],0) &&
                approx(map[0]*map[2],0) &&
                approx(map[1]*map[2],0)
            )
        )
        assert(ocheck, "Inputs must be orthogonal when reverse==true")
        [for (r=map) [for (c=r) c, 0], [0,0,0,1]]
    ) : [for (r=transpose(map)) [for (c=r) c, 0], [0,0,0,1]];



// Function: affine3d_mirror()
// Usage:
//   mat = affine3d_mirror(v);
// Topics: Affine, Matrices, Transforms, Reflection, Mirroring
// See Also: mirror(), xflip(), yflip(), zflip(), affine2d_mirror()
// Description:
//   Returns the 4x4 affine3d matrix to perform a reflection of a 3D vector across the plane given by its normal vector.
// Arguments:
//   v = The normal vector of the plane to reflect across.
// Example:
//   mat = affine3d_mirror([1,0,0]);
//   // Returns:
//   //   [
//   //     [-1, 0, 0, 0],
//   //     [ 0, 1, 0, 0],
//   //     [ 0, 0, 1, 0],
//   //     [ 0, 0, 0, 1]
//   //   ]
// Example:
//   mat = affine3d_mirror([0,1,0]);
//   // Returns:
//   //   [
//   //     [ 1, 0, 0, 0],
//   //     [ 0,-1, 0, 0],
//   //     [ 0, 0, 1, 0],
//   //     [ 0, 0, 0, 1]
//   //   ]
function affine3d_mirror(v) =
    assert(is_vector(v))
    let(
        v=unit(point3d(v)),
        a=v.x, b=v.y, c=v.z
    ) [
        [1-2*a*a,  -2*a*b,  -2*a*c, 0],
        [ -2*b*a, 1-2*b*b,  -2*b*c, 0],
        [ -2*c*a,  -2*c*b, 1-2*c*c, 0],
        [      0,       0,       0, 1]
    ];


// Function: affine3d_skew()
// Usage:
//   mat = affine3d_skew([sxy=], [sxz=], [syx=], [syz=], [szx=], [szy=]);
// Topics: Affine, Matrices, Transforms, Skewing
// See Also: skew(), affine3d_skew_xy(), affine3d_skew_xz(), affine3d_skew_yz(), affine2d_skew()
// Description:
//   Returns the 4x4 affine3d matrix to perform a skew transformation.
// Arguments:
//   sxy = Skew factor multiplier for skewing along the X axis as you get farther from the Y axis.  Default: 0
//   sxz = Skew factor multiplier for skewing along the X axis as you get farther from the Z axis.  Default: 0
//   syx = Skew factor multiplier for skewing along the Y axis as you get farther from the X axis.  Default: 0
//   syz = Skew factor multiplier for skewing along the Y axis as you get farther from the Z axis.  Default: 0
//   szx = Skew factor multiplier for skewing along the Z axis as you get farther from the X axis.  Default: 0
//   szy = Skew factor multiplier for skewing along the Z axis as you get farther from the Y axis.  Default: 0
// Example:
//   mat = affine3d_skew(sxy=2,szx=3);
//   // Returns:
//   //   [
//   //     [ 1, 2, 0, 0],
//   //     [ 0, 1, 0, 0],
//   //     [ 0, 0, 1, 0],
//   //     [ 3, 0, 0, 1]
//   //   ]
function affine3d_skew(sxy=0, sxz=0, syx=0, syz=0, szx=0, szy=0) = [
    [  1, sxy, sxz, 0],
    [syx,   1, syz, 0],
    [szx, szy,   1, 0],
    [  0,   0,   0, 1]
];


// Function: affine3d_skew_xy()
// Usage:
//   mat = affine3d_skew_xy(xa);
//   mat = affine3d_skew_xy(ya=);
//   mat = affine3d_skew_xy(xa, ya);
// Topics: Affine, Matrices, Transforms, Skewing
// See Also: skew(), affine3d_skew(), affine3d_skew_xz(), affine3d_skew_yz(), affine2d_skew()
// Description:
//   Returns the 4x4 affine3d matrix to perform a skew transformation along the XY plane.
// Arguments:
//   xa = Skew angle, in degrees, in the direction of the X axis.  Default: 0
//   ya = Skew angle, in degrees, in the direction of the Y axis.  Default: 0
// Example:
//   mat = affine3d_skew_xy(xa=45,ya=-45);
//   // Returns:
//   //   [
//   //     [ 1, 0, 1, 0],
//   //     [ 0, 1,-1, 0],
//   //     [ 0, 0, 1, 0],
//   //     [ 0, 0, 0, 1]
//   //   ]
function affine3d_skew_xy(xa=0, ya=0) =
    assert(is_finite(xa))
    assert(is_finite(ya))
    [
        [1, 0, tan(xa), 0],
        [0, 1, tan(ya), 0],
        [0, 0,       1, 0],
        [0, 0,       0, 1]
    ];


// Function: affine3d_skew_xz()
// Usage:
//   mat = affine3d_skew_xz(xa);
//   mat = affine3d_skew_xz(za=);
//   mat = affine3d_skew_xz(xa, za);
// Topics: Affine, Matrices, Transforms, Skewing
// See Also: skew(), affine3d_skew(), affine3d_skew_xy(), affine3d_skew_yz(), affine2d_skew()
// Description:
//   Returns the 4x4 affine3d matrix to perform a skew transformation along the XZ plane.
// Arguments:
//   xa = Skew angle, in degrees, in the direction of the X axis.  Default: 0
//   za = Skew angle, in degrees, in the direction of the Z axis.  Default: 0
// Example:
//   mat = affine3d_skew_xz(xa=45,za=-45);
//   // Returns:
//   //   [
//   //     [ 1, 1, 0, 0],
//   //     [ 0, 1, 0, 0],
//   //     [ 0,-1, 1, 0],
//   //     [ 0, 0, 0, 1]
//   //   ]
function affine3d_skew_xz(xa=0, za=0) =
    assert(is_finite(xa))
    assert(is_finite(za))
    [
        [1, tan(xa), 0, 0],
        [0,       1, 0, 0],
        [0, tan(za), 1, 0],
        [0,       0, 0, 1]
    ];


// Function: affine3d_skew_yz()
// Usage:
//   mat = affine3d_skew_yz(ya);
//   mat = affine3d_skew_yz(za=);
//   mat = affine3d_skew_yz(ya, za);
// Topics: Affine, Matrices, Transforms, Skewing
// See Also: skew(), affine3d_skew(), affine3d_skew_xy(), affine3d_skew_xz(), affine2d_skew()
// Description:
//   Returns the 4x4 affine3d matrix to perform a skew transformation along the YZ plane.
// Arguments:
//   ya = Skew angle, in degrees, in the direction of the Y axis.  Default: 0
//   za = Skew angle, in degrees, in the direction of the Z axis.  Default: 0
// Example:
//   mat = affine3d_skew_yz(ya=45,za=-45);
//   // Returns:
//   //   [
//   //     [ 1, 0, 0, 0],
//   //     [ 1, 1, 0, 0],
//   //     [-1, 0, 1, 0],
//   //     [ 0, 0, 0, 1]
//   //   ]
function affine3d_skew_yz(ya=0, za=0) =
    assert(is_finite(ya))
    assert(is_finite(za))
    [
        [      1, 0, 0, 0],
        [tan(ya), 1, 0, 0],
        [tan(za), 0, 1, 0],
        [      0, 0, 0, 1]
    ];



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
