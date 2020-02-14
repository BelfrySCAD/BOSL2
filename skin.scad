//////////////////////////////////////////////////////////////////////
// LibFile: skin.scad
//   Functions to skin arbitrary 2D profiles/paths in 3-space.
//   To use, add the following line to the beginning of your file:
//   ```
//   include <BOSL2/std.scad>
//   include <BOSL2/skin.scad>
//   ```
//   Inspired by list-comprehension-demos skin():
//   - https://github.com/openscad/list-comprehension-demos/blob/master/skin.scad
//////////////////////////////////////////////////////////////////////

include <vnf.scad>

// Section: Skinning

// Function&Module: skin()
// Usage: As module:
//   skin(profiles, [slices], [refine], [method], [sampling], [caps], [closed], [z]);
// Usage: As function:
//   vnf = skin(profiles, [slices], [refine], [method], [sampling], [caps], [closed], [z]);
// Description:
//   Given a list of two ore more path `profiles` in 3d space, produces faces to skin a surface between
//   the profiles.  Optionally the first and last profiles can have endcaps, or the first and last profiles
//   can be connected together.  Each profile should be roughly planar, but some variation is allowed.
//   Each profile must rotate in the same clockwise direction.  If called as a function, returns a
//   [VNF structure](vnf.scad) like `[VERTICES, FACES]`.  If called as a module, creates a polyhedron
//    of the skined profiles.
//   
//   The profiles can be specified either as a list of 3d curves or they can be specified as
//   2d curves with heights given in the `z` parameter.  It is your responsibility to ensure
//   that the resulting polyhedron is free from self-intersections, which would make it invalid
//   and can result in cryptic CGAL errors upon rendering, even though the polyhedron appears
//   OK during preview.
//   
//   For this operation to be well-defined, the profiles must all have the same vertex count and
//   we must assume that profiles are aligned so that vertex `i` links to vertex `i` on all polygons.
//   Many interesting cases do not comply with this restriction.  Two basic methods can handle
//   these cases: either add points to edges (resample) so that the profiles are compatible,
//   or repeat vertices.  Repeating vertices allows two edges to terminate at the same point, creating
//   triangular faces.  You can adjust non-matchines profiles yourself
//   either by resampling them using `subdivide_path` or by duplicating vertices using
//   `repeat_entries`.  It is OK to pass a profile that has the same vertex repeated, such as
//   a square with 5 points (two of which are identical), so that it can match up to a pentagon.
//   Such a combination would create a triangular face at the location of the duplicated vertex.
//   Alternatively, `skin` provides methods (described below) for matching up incompatible paths.
//   
//   In order for skinned surfaces to look good it is usually necessary to use a fine sampling of
//   points on all of the profiles, and a large number of extra interpolated slices between the
//   profiles that you specify.  It is generally best if the triangules forming your polyhedron
//   are approximately equilateral.  The `slices` parameter specifies the number of slices to insert
//   between each pair of profiles, either a scalar to insert the same number everywhere, or a vector
//   to insert a different number between each pair.  To resample the profiles you can use set
//   `refine=N` which will place `N` points on each edge of your profile.  This has the effect of
//   muliplying the number of points by N, so a profile with 8 points will have 8*N points afer
//   refinement.  Note that when dealing with continuous curves it is always better to adjust the
//   sampling in your code to generate the desired sampling rather than using the `refine` argument.
//   
//   Two methods are available for resampling, `"length"` and `"segment"`.  Specify them using
//   the `sampling` argument.  The length resampling method resamples proportional to length.
//   The segment method divides each segment of a profile into the same number of points.
//   A uniform division may be impossible, in which case the code computes an approximation.
//   See `subdivide_path` for more details.
//    
//   You can choose from four methods for specifying alignment for incomensurate profiles.
//   The available methods are `"distance"`, `"tangent"`, `"direct"` and `"reindex"`.
//   It is useful to distinguish between continuous curves like a circle and discrete profiles
//   like a hexagon or star, because the algorithms' suitability depend on this distinction.
//   
//   The "direct" and "reindex" methods work by resampling the profiles if necessary.  As noted above,
//   for continuous input curves, it is better to generate your curves directly at the desired sample size,
//   but for mapping between a discrete profile like a hexagon and a circle, the hexagon must be resampled
//   to match the circle.  You can do this in two different ways using the `sampling` parameter.  The default
//   of `sampling="length"` approximates a uniform length sampling of the profile.  The other option
//   is `sampling="segment"` which attempts to place the same number of new points on each segment.
//   If the segments are of varying length, this will produce a different result.  Note that "direct" is
//   the default method.  If you simply supply a list of compatible profiles it will link them up
//   exactly as you have provided them.  You may find that profiles you want to connect define the
//   right shapes but the point lists don't start from points that you want aligned in your skinned
//   polyhedron.  You can correct this yourself using `reindex_polygon`, or you can use the "reindex"
//   method which will look for the index choice that will minimize the length of all of the edges
//   in the polyhedron---in will produce the least twisted possible result.  This algorithm has quadratic
//   run time so it can be slow with very large profiles.
//   
//   The "distance" and "tangent" methods are work by duplicating vertices to create
//   triangular faces.  The "distance" method finds the global minimum distance method for connecting two
//   profiles.  This algorithm generally produces a good result when both profiles are discrete ones with
//   a small number of vertices.  It is computationally intensive (O(N^3)) and may be
//   slow on large inputs.  The resulting surfaces generally have curves faces, so be
//   sure to select a sufficiently large value for `slices` and `refine`.
//   The `"tangent"` method generally produces good results when
//   connecting a discrete polygon to a convex, finely sampled curve.  It works by finding
//   a plane that passed through each edge of the polygon that is tangent to
//   the curve.  It may fail if the curved profile is non-convex, or doesn't have enough points to distinguish
//   all of the tangent points from each other.  It connects all of the points of the curve to the corners of the discrete
//   polygon using triangular faces.  Using `refine` with this method will have little effect on the model, so
//   you should do it only for agreement with other profiles, and these models are linear, so extra slices also
//   have no effect.  For best efficiency set `refine=1` and `slices=0`.  When you use refinement with either
//   of these methods, it is always the "segment" based resampling described above.  This is necessary because
//   sampling by length will ignore the repeated vertices and break the alignment.
//   
//   It is possible to specify `method` and `refine` as arrays, but it is important to observe
//   matching rules when you do this.  If a pair of profiles is connected using "tangent" or "distance"
//   then the `refine` values for those two profiles must be equal.  If a profile is connected by
//   a vertex duplicating method on one side and a resampling method on the other side, then
//   `refine` must be set so that the resulting number of vertices matches the number that is
//   used for the resampled profiles.  The best way to avoid confusion is to ensure that the
//   profiles connected by "direct" or "realign" all have the same number of points and at the
//   transition, the refined number of points matches.
//   
// Arguments:
//   profiles = list of 2d or 3d profiles to be skinned.  (If 2d must also give `z`.)
//   slices = scalar or vector number of slices to insert between each pair of profiles.  Set to zero to use only the profiles you provided.  Recommend starting with a value around 10.
//   refine = resample profiles to this number of points per edge.  Can be a list to give a refinement for each profile.  Recommend using a value above 10 when using the "distance" method.  Default: 1.
//   sampling = sampling method to use with "direct" and "reindex" methods.  Can be "length" or "segment".  Ignored if any profile pair uses either the "distance" or "tangent" methods.  Default: "length".
//   closed = set to true to connect first and last profile (to make a torus).  Default: false
//   caps = true to create endcap faces when closed is false.  Can be a length 2 boolean array.  Default is true if closed is false.
//   method = method for connecting profiles, one of "distance", "tangent", "direct" or "reindex".  Default: "direct".
//   z = array of height values for each profile if the profiles are 2d
// Example:
//   skin([octagon(4), regular_ngon(n=70,r=2)], z=[0,3], slices=10);
// Example: The circle() and pentagon() modules place the zero index at different locations, giving a twist
//   skin([pentagon(4), circle($fn=80,r=2)], z=[0,3], slices=10);
// Example: You can untwist it with the "reindex" method
//   skin([pentagon(4), circle($fn=80,r=2)], z=[0,3], slices=10, method="reindex");
// Example: Offsetting the starting edge connects to circles in an interesting way:
//   circ = circle($fn=80, r=3);
//   skin([circ, rot(110,p=circ)], z=[0,5], slices=20);
// Example(FlatSpin): 
//   skin([ yrot(37,p=path3d(circle($fn=128, r=4))), path3d(square(3),3)], method="reindex",slices=10);
// Example(FlatSpin): Ellipses connected with twist
//   ellipse = xscale(2.5,p=circle($fn=80));
//   skin([ellipse, rot(45,p=ellipse)], z=[0,1.5], slices=10);
// Example(FlatSpin): Ellipses connected without a twist.  (Note ellipses stay in the same position: just the connecting edges are different.)
//   ellipse = xscale(2.5,p=circle($fn=80));
//   skin([ellipse, rot(45,p=ellipse)], z=[0,1.5], slices=10, method="reindex");
// Example(FlatSpin):
//   $fn=24;
//   skin([
//         yrot(0, p=yscale(2,p=path3d(circle(d=75)))),
//         [[40,0,100], [35,-15,100], [20,-30,100],[0,-40,100],[-40,0,100],[0,40,100],[20,30,100], [35,15,100]]
//   ],slices=10);
// Example(FlatSpin):
//   $fn=48;
//   skin([
//       for (b=[0,90]) [
//           for (a=[360:-360/$fn:0.01])
//               point3d(polar_to_xy((100+50*cos((a+b)*2))/2,a),b/90*100)
//       ]
//   ], slices=20);
// Example: Vaccum connector example from list-comprehension-demos
//   include <BOSL2/rounding.scad>
//   $fn=32;
//   base = round_corners(square([2,4],center=true), measure="radius", size=0.5);
//   skin([
//       path3d(base,0),
//       path3d(base,2),
//       path3d(circle(r=0.5),3),
//       path3d(circle(r=0.5),4),
//       for(i=[0:2]) each [path3d(circle(r=0.6), i+4),
//                          path3d(circle(r=0.5), i+5)]
//   ],slices=0);
// Example: Vaccum nozzle example from list-comprehension-demos, using "length" sampling (the default)
//   xrot(90)down(1.5)
//   difference() {
//   	skin(
//   		[square([2,.2],center=true),
//   		 circle($fn=64,r=0.5)], z=[0,3],
//   		slices=40,sampling="length",method="reindex");
//   	skin(
//   		[square([1.9,.1],center=true),
//   		 circle($fn=64,r=0.45)], z=[-.01,3.01],
//   		slices=40,sampling="length",method="reindex");
//   }
// Example: Same thing with "segment" sampling
//   xrot(90)down(1.5)
//   difference() {
//   	skin(
//   		[square([2,.2],center=true),
//   		 circle($fn=64,r=0.5)], z=[0,3],
//   		slices=40,sampling="segment",method="reindex");
//   	skin(
//   		[square([1.9,.1],center=true),
//   		 circle($fn=64,r=0.45)], z=[-.01,3.01],
//   		slices=40,sampling="segment",method="reindex");
//   }
// Example: Forma Candle Holder (from list-comprehension-demos)
//   r = 50;
//   height = 140;
//   layers = 10;
//   wallthickness = 5;
//   holeradius = r - wallthickness;
//   difference() {
//       skin([for (i=[0:layers-1]) zrot(-30*i,p=path3d(hexagon(ir=r),i*height/layers))],slices=0);
//       up(height/layers) cylinder(r=holeradius, h=height);
//   }
// Example(FlatSpin): A box that is octagonal on the outside and circular on the inside
//   height = 45;
//   sub_base = octagon(d=71, rounding=2, $fn=128);
//   base = octagon(d=75, rounding=2, $fn=128);
//   interior = regular_ngon(n=len(base), d=60);
//   right_half()
//     skin([ sub_base, base, base, sub_base, interior], z=[0,2,height, height, 2], slices=0, refine=1, method="reindex");
// Example: Connecting a pentagon and circle with the "tangent" method produces triangular faces.
//   skin([pentagon(4), circle($fn=80,r=2)], z=[0,3], slices=10, method="tangent");
// Example: Another "tangent" example with non-parallel profiles
//   skin([path3d(pentagon(4)),
//         yrot(35,p=path3d(right(4,p=circle($fn=80,r=2)),5))], slices=10, method="tangent");
// Example: rounding corners of a square.  Note that `$fn` makes the number of points constant, and avoiding the `rounding=0` case keeps everything simple.  In this case, the connections between profiles are linear, so there is no benefit to setting `slices` bigger than zero.
//   shapes = [for(i=[.01:.045:2])zrot(-i*180/2,cp=[-8,0,0],p=xrot(90,p=path3d(regular_ngon(n=4, side=4, rounding=i, $fn=64))))];
//   skin( shapes, slices=0);
// Example: Here's a simplified version of the above, with `i=0` included.  That first layer doesn't look good.
//   shapes = [for(i=[0:.2:1]) path3d(regular_ngon(n=4, side=4, rounding=i, $fn=32),i*5)];
//   skin( shapes, slices=0);
// Example: You can fix it by specifying "tangent" for the first method, but you still need "direct" for the rest.
//   shapes = [for(i=[0:.2:1]) path3d(regular_ngon(n=4, side=4, rounding=i, $fn=32),i*5)];
//   skin( shapes, slices=0, method=concat(["tangent"],replist("direct",len(shapes)-2)));
// Example(FlatSpin): Connecting square to pentagon using "direct" method.
//   skin([regular_ngon(n=4, r=4), regular_ngon(n=5,r=5)], z=[0,4], refine=10, slices=10);
// Example(FlatSpin): Connecting square to shifted pentagon using "direct" method.
//   skin([regular_ngon(n=4, r=4), right(4,p=regular_ngon(n=5,r=5))], z=[0,4], refine=10, slices=10);
// Example(FlatSpin): To improve the look, you can actually rotate the polygons for a more symmetric pattern of lines.   You have to resample yourself before calling `align_polygon` and you should choose a length that is a multiple of both polygon lengths.
//   sq = subdivide_path(regular_ngon(n=4, r=4),40);
//   pent = subdivide_path(regular_ngon(n=5,r=5),40);
//   skin([sq, align_polygon(sq,pent,[0:1:360/5])], z=[0,4], slices=10);
// Example(FlatSpin): For the shifted pentagon we can also align, making sure to pass an appropriate centerpoint to `align_polygon`.
//   sq = subdivide_path(regular_ngon(n=4, r=4),40);
//   pent = right(4,p=subdivide_path(regular_ngon(n=5,r=5),40));
//   skin([sq, align_polygon(sq,pent,[0:1:360/5],cp=[4,0])], z=[0,4], refine=10, slices=10);
// Example(FlatSpin): The "distance" method is a completely different approach.
//   skin([regular_ngon(n=4, r=4), regular_ngon(n=5,r=5)], z=[0,4], refine=10, slices=10, method="distance");
// Example(FlatSpin): Connecting pentagon to heptagon inserts two triangular faces on each side
//   small = path3d(circle(r=3, $fn=5));
//   big = up(2,p=yrot( 0,p=path3d(circle(r=3, $fn=7), 6)));
//   skin([small,big],method="distance", slices=10, refine=10);
// Example(FlatSpin): But just a slight rotation of the top profile moves the two triangles to one end
//   small = path3d(circle(r=3, $fn=5));
//   big = up(2,p=yrot(14,p=path3d(circle(r=3, $fn=7), 6)));
//   skin([small,big],method="distance", slices=10, refine=10);
// Example(FlatSpin): Another "distance" example:
//   off = [0,2]; 
//   shape = turtle(["right",45,"move", "left",45,"move", "left",45, "move", "jump", [.5+sqrt(2)/2,8]]);
//   rshape = rot(180,cp=centroid(shape)+off, p=shape);
//   skin([shape,rshape],z=[0,4], method="distance",slices=10,refine=15);
// Example(FlatSpin): Slightly shifting the profile changes the optimal linkage
//   off = [0,1]; 
//   shape = turtle(["right",45,"move", "left",45,"move", "left",45, "move", "jump", [.5+sqrt(2)/2,8]]);
//   rshape = rot(180,cp=centroid(shape)+off, p=shape);
//   skin([shape,rshape],z=[0,4], method="distance",slices=10,refine=15);
// Example(FlatSpin): This optimal solution doesn't look terrible:
//   prof1 = path3d([[50,-50], [-50,-50], [-50,50], [-25,25], [0,50], [25,25], [50,50]]);
//   prof2 = path3d(regular_ngon(n=7, r=50),100);
//   skin([prof1, prof2], method="distance", slices=10, refine=10);
// Example(FlatSpin): But this one looks better.  The "distance" method doesn't find it because it uses two more edges, so it clearly has a higher total edge distance.  We force it by doubling the first two vertices of one of the profiles.
//   prof1 = path3d([[50,-50], [-50,-50], [-50,50], [-25,25], [0,50], [25,25], [50,50]]);
//   prof2 = path3d(regular_ngon(n=7, r=50),100);
//   skin([repeat_entries(prof1,[2,2,1,1,1,1,1]),
//         prof2],
//        method="distance", slices=10, refine=10);
// Example(FlatSpin): The "distance" method will often produces results similar to the "tangent" method if you use it with a polygon and a curve, but the results can also look like this:
//   skin([path3d(circle($fn=128, r=10)), xrot(39, p=path3d(square([8,10]),10))],  method="distance", slices=0);
// Example(FlatSpin): Using the "tangent" method produces:
//   skin([path3d(circle($fn=128, r=10)), xrot(39, p=path3d(square([8,10]),10))],  method="tangent", slices=0);
// Example(FlatSpin): Torus using hexagons and pentagons, where `closed=true`
//   hex = back(7,p=path3d(hexagon(r=3)));
//   pent = back(7,p=path3d(pentagon(r=3)));
//   N=5;
//   skin(
//        [for(i=[0:2*N-1]) xrot(360*i/2/N, p=(i%2==0 ? hex : pent))],
//        refine=1,slices=0,method="distance",closed=true);
// Example: A smooth morph is achieved when you can calculate all the slices yourself.  Since you provide all the slices, set `slices=0`.
//   skin([for(n=[.1:.02:.5])
//            yrot(n*60-.5*60,p=path3d(supershape(step=360/128,m1=5,n1=n, n2=1.7),5-10*n))],
//        slices=0);
// Example: Another smooth supershape morph:
//   skin([for(alpha=[-.2:.05:1.5])
//            path3d(supershape(step=360/256,m1=7, n1=lerp(2,3,alpha),
//                              n2=lerp(8,4,alpha), n3=lerp(4,17,alpha)),alpha*5)],
//        slices=0);
// Example: Several polygons connected using "distance"
//   skin([regular_ngon(n=4, r=3),
//         regular_ngon(n=6, r=3),
//         regular_ngon(n=9, r=4),
//         rot(17,p=regular_ngon(n=6, r=3)),
//         rot(37,p=regular_ngon(n=4, r=3))],
//        z=[0,2,4,6,9], method="distance", slices=10, refine=10);
// Example(FlatSpin): Vertex count of the polygon changes at every profile
//   skin([
//       for (ang = [0:10:90])
//       rot([0,ang,0], cp=[200,0,0], p=path3d(circle(d=100,$fn=12-(ang/10))))
//   ],method="distance",slices=10,refine=10);
// Example: Möbius Strip.  This is a tricky model because when you work your way around to the connection, the direction of the profiles is flipped, so how can the proper geometry be created?  The trick is to duplicate the first profile and turn the caps off.  The model closes up and forms a valid polyhedron.
//   skin([
//     for (ang = [0:5:360])
//     rot([0,ang,0], cp=[100,0,0], p=rot(ang/2, p=path3d(square([1,30],center=true))))
//   ], caps=false, slices=0, refine=20);
// Example: If you create a self-intersecting polyhedron the result is invalid.  In some cases self-intersection may be obvous.  Here is a more subtle example.
//   skin([
//          for (a = [0:30:180]) let(
//              pos  = [-60*sin(a),     0, a    ],
//              pos2 = [-60*sin(a+0.1), 0, a+0.1]
//          ) move(pos,
//              p=rot(from=UP, to=pos2-pos,
//                  p=path3d(circle(d=150))
//              )
//          )
//      ],refine=1,slices=0);
//      color("red") {
//          zrot(25) fwd(130) xrot(75) {
//              linear_extrude(height=0.1) {
//                  ydistribute(25) {
//                      text(text="BAD POLYHEDRONS!", size=20, halign="center", valign="center");
//                      text(text="CREASES MAKE", size=20, halign="center", valign="center");
//                  }
//              }
//          }
//          up(160) zrot(25) fwd(130) xrot(75) {
//              stroke(zrot(30, p=yscale(0.5, p=circle(d=120))),width=10,closed=true);
//          }
//      }


module skin(profiles, slices, refine=1, method="direct", sampling, caps, closed=false, z, convexity=10)
{
  	vnf_polyhedron(skin(profiles, slices, refine, method, sampling, caps, closed, z), convexity=convexity);
}        


function skin(profiles, slices, refine=1, method="direct", sampling, caps, closed=false, z) =
  assert(is_list(profiles) && len(profiles)>1, "Must provide at least two profiles")
  let( bad = [for(i=idx(profiles)) if (!(is_path(profiles[i]) && len(profiles[i])>2)) i])
  assert(len(bad)==0, str("Profiles ",bad," are not a paths or have length less than 3"))
  let(
    profcount = len(profiles) - (closed?0:1),
    legal_methods = ["direct","reindex","distance","tangent"],
    caps = is_def(caps) ? caps :
           closed ? false : true,
    capsOK = is_bool(caps) || (is_list(caps) && len(caps)==2 && is_bool(caps[0]) && is_bool(caps[1])),
    fullcaps = is_bool(caps) ? [caps,caps] : caps,
    refine = is_list(refine) ? refine : replist(refine, len(profiles)),
    slices = is_list(slices) ? slices : replist(slices, profcount),
    refineOK = [for(i=idx(refine)) if (refine[i]<=0 || !is_integer(refine[i])) i],
    slicesOK = [for(i=idx(slices)) if (!is_integer(slices[i]) || slices[i]<0) i],
    maxsize = list_longest(profiles),
    methodok = is_list(method) || in_list(method, legal_methods),
    methodlistok = is_list(method) ? [for(i=idx(method)) if (!in_list(method[i], legal_methods)) i] : [],
    method = is_string(method) ? replist(method, profcount) : method,
    // Define to be zero where a resampling method is used and 1 where a vertex duplicator is used
    RESAMPLING = 0,
    DUPLICATOR = 1,
    method_type = [for(m = method) m=="direct" || m=="reindex" ? 0 : 1],
    sampling = is_def(sampling) ? sampling :
               in_list(DUPLICATOR,method_type) ? "segment" : "length" 
  )
  assert(len(refine)==len(profiles), "refine list is the wrong length")
  assert(len(slices)==profcount, "slices list is the wrong length")
  assert(slicesOK==[],str("slices must be nonnegative integers"))
  assert(refineOK==[],str("refine must be postive integer"))
  assert(methodok,str("method must be one of ",legal_methods,". Got ",method))
  assert(methodlistok==[], str("method list contains invalid method at ",methodlistok))
  assert(len(method) == profcount,"Method list is the wrong length")
  assert(in_list(sampling,["length","segment"]), "sampling must be set to \"length\" or \"segment\"")
  assert(sampling=="segment" || (!in_list("distance",method) && !in_list("tangent",method)), "sampling is set to \"length\" which is only allowed iwith methods \"direct\" and \"reindex\"")
  assert(capsOK, "caps must be boolean or a list of two booleans")
  assert(!closed || !caps, "Cannot make closed shape with caps")
  let(
    profile_dim=array_dim(profiles,2),
    profiles_ok = (profile_dim==2 && is_list(z) && len(z)==len(profiles)) || profile_dim==3
  )
  assert(profiles_ok,"Profiles must all be 3d or must all be 2d, with matching length z parameter.")
  assert(is_undef(z) || profile_dim==2, "Do not specify z with 3d profiles")
  assert(profile_dim==3 || len(z)==len(profiles),"Length of z does not match length of profiles.")
  let(
    // Adjoin Z coordinates to 2d profiles
    profiles = profile_dim==3 ? profiles :
               [for(i=idx(profiles)) path3d(profiles[i], z[i])],
    // True length (not counting repeated vertices) of profiles after refinement
    refined_len = [for(i=idx(profiles)) refine[i]*len(profiles[i])],
    // Define this to be 1 if a profile is used on either side by a resampling method, zero otherwise.
    profile_resampled = [for(i=idx(profiles)) 
      1-(
           i==0 ?  method_type[0] * (closed? select(method_type,-1) : 1) :
           i==len(profiles)-1 ? select(method_type,-1) * (closed ? select(method_type,-2) : 1) :
         method_type[i] * method_type[i-1])],
    parts = search(1,[1,for(i=[0:1:len(profile_resampled)-2]) profile_resampled[i]!=profile_resampled[i+1] ? 1 : 0],0),
    plen = [for(i=idx(parts)) (i== len(parts)-1? len(refined_len) : parts[i+1]) - parts[i]],
    max_list = [for(i=idx(parts)) each replist(max(select(refined_len, parts[i], parts[i]+plen[i]-1)), plen[i])],
    transition_profiles = [for(i=[(closed?0:1):1:profcount-1]) if (select(method_type,i-1) != method_type[i]) i],
    badind = [for(tranprof=transition_profiles) if (refined_len[tranprof] != max_list[tranprof]) tranprof]
  )
  assert(badind==[],str("Profile length mismatch at method transition at indices ",badind," in skin()"))
  let(
    full_list =    // If there are no duplicators then use more efficient where the whole input is treated together
      !in_list(DUPLICATOR,method_type) ?
         let(
             resampled = [for(i=idx(profiles)) subdivide_path(profiles[i], max_list[i], method=sampling)],
             fixedprof = [for(i=idx(profiles)) 
                             i==0 || method[i-1]=="direct" ? resampled[i]
                                                         :echo("reindexing") reindex_polygon(resampled[i-1],resampled[i])],
             sliced = slice_profiles(fixedprof, slices, closed)            
            )
            !closed ? sliced : concat(sliced,[sliced[0]])
      :  // There are duplicators, so use approach where each pair is treated separately
      [for(i=[0:profcount-1])
        let(
          pair = 
            method[i]=="distance" ? _skin_distance_match(profiles[i],select(profiles,i+1)) :
            method[i]=="tangent" ? _skin_tangent_match(profiles[i],select(profiles,i+1)) :
            /*method[i]=="reindex" || method[i]=="direct" ?*/ 
               let( p1 = subdivide_path(profiles[i],max_list[i], method=sampling),
                    p2 = subdivide_path(select(profiles,i+1),max_list[i], method=sampling)
               ) (method[i]=="direct" ? [p1,p2] : [p1, reindex_polygon(p1, p2)]),
            nsamples =  method_type[i]==RESAMPLING ? len(pair[0]) :
               assert(refine[i]==select(refine,i+1),str("Refine value mismatch at indices ",[i,(i+1)%len(refine)],
                                                        ".  Method ",method[i]," requires equal values"))
               refine[i] * len(pair[0])
          )
          each subdivide_and_slice(pair,slices[i], nsamples, method=sampling)]
  )
  _skin_core(full_list,caps=fullcaps);



function _skin_core(profiles, caps) =
	let(
                vertices = [for (prof=profiles) each prof],
		plens = [for (prof=profiles) len(prof)],
		sidefaces = [
			for(pidx=idx(profiles,end=-2))
			let(
				prof1 = profiles[pidx%len(profiles)],
				prof2 = profiles[(pidx+1)%len(profiles)],
				voff = default(sum([for (i=[0:1:pidx-1]) plens[i]]),0),
				faces = [
					for(
						first = true,
						finishing = false,
						finished = false,
						plen1 = len(prof1),
						plen2 = len(prof2),
						i=0, j=0, side=0;

						!finished;

						side =
							let(
								p1a = prof1[(i+0)%plen1],
								p1b = prof1[(i+1)%plen1],
								p2a = prof2[(j+0)%plen2],
								p2b = prof2[(j+1)%plen2],
								dist1 = norm(p1a-p2b),
								dist2 = norm(p1b-p2a)
							) (i==j) ? (dist1>dist2? 1 : 0) : (i<j ? 1 : 0) ,
						p1 = voff + (i%plen1),
						p2 = voff + (j%plen2) + plen1,
						p3 = voff + (side? ((i+1)%plen1) : (((j+1)%plen2) + plen1)),
						face = [p1, p3, p2],
						i = i + (side? 1 : 0),
						j = j + (side? 0 : 1),
						first = false,
						finished = finishing,
						finishing = i>=plen1 && j>=plen2
					) if (!first) face
				]
			) each faces
		],
                firstcap = !caps[0] ? [] : let(
                        prof1 = profiles[0]
                ) [[for (i=idx(prof1)) plens[0]-1-i]],
                secondcap = !caps[1] ? [] : let(
			prof2 = select(profiles,-1),
			eoff = sum(select(plens,0,-2))
		) [[for (i=idx(prof2)) eoff+i]]
	) [vertices, concat(sidefaces,firstcap,secondcap)];



// Function: subdivide_and_slice()
// Usage: subdivide_and_slice(profiles, slices, [numpoints], [method], [closed])
// Description: Subdivides the input profiles to have length `numpoints` where
//   `numpoints` must be at least as big as the largest input profile.
//   By default `numpoints` is set equal to the length of the largest profile.
//   You can set `numpoints="lcm"` to sample to the least common multiple of
//   all curves, which will avoid sampling artifacts but may produce a huge output.
//   After subdivision, profiles are sliced.
// Arguments:
//   profiles = profiles to operate on
//   slices = number of slices to insert between each pair of profiles.  May be a vector
//   numpoints = number of points after sampling.
//   method = method used for calling `subdivide_path`, either `"length"` or `"segment"`.  Default: `"length"`
//   closed = the first and last profile are connected.  Default: false
function subdivide_and_slice(profiles, slices, numpoints, method="length", closed=false) =
  let(
    maxsize = list_longest(profiles),
    numpoints = is_undef(numpoints) ? maxsize :
                numpoints == "lcm" ? lcmlist([for(p=profiles) len(p)]) :
                is_num(numpoints) ? round(numpoints) : undef
  )
  assert(is_def(numpoints), "Parameter numpoints must be \"max\", \"lcm\" or a positive number")
  assert(numpoints>=maxsize, "Number of points requested is smaller than largest profile")
  let(fixpoly = [for(poly=profiles) subdivide_path(poly, numpoints,method=method)])
  slice_profiles(fixpoly, slices, closed);
  

// Function slice_profiles()
// Usage: slice_profiles(profiles,slices,[closed])
// Description:
//   Given an input list of profiles, linearly interpolate between each pair to produce a
//   more finely sampled list.  The parameters `slices` specifies the number of slices to
//   be inserted between each pair of profiles and can be a number or a list.
// Arguments:
//   profiles = list of paths to operate on.  They must be lists of the same shape and length.
//   slices = number of slices to insert between each pair, or a list to vary the number inserted.
//   closed = set to true if last profile connects to first one.  Default: false
function slice_profiles(profiles,slices,closed=false) =
  assert(is_num(slices) || is_list(slices))
  let(listok = !is_list(slices) || len(slices)==len(profiles)-(closed?0:1))
  assert(listok, "Input slices to slice_profiles is a list with the wrong length")
  let(
    count = is_num(slices) ? replist(slices,len(profiles)-(closed?0:1)) : slices,
    slicelist = [for (i=[0:len(profiles)-(closed?1:2)])
      each [for(j = [0:count[i]]) lerp(profiles[i],select(profiles,i+1),j/(count[i]+1))]
    ]
  )
  concat(slicelist, closed?[]:[profiles[len(profiles)-1]]);


//////////////////////////////////////////////////////////////////
//
// Minimum Distance Mapping using Dynamic Programming
//
// Given inputs of a two polygons, computes a mapping between their vertices that minimizes the sum the sum of
// the distances between every matched pair of vertices.  The algorithm uses dynamic programming to calculate
// the optimal mapping under the assumption that poly1[0] <-> poly2[0].  We then rotate through all the
// possible indexings of the longer polygon.  The theoretical run time is quadratic in the longer polygon and
// linear in the shorter one.
//
// The top level function, _skin_distance_match(), cycles through all the of the indexings of the larger
// polygon, computes the optimal value for each indexing, and chooses the overall best result.  It uses
// _dp_extract_map() to thread back through the dynamic programming array to determine the actual mapping, and
// then converts the result to an index repetition count list, which is passed to repeat_entries().
// 
// The function _dp_distance_array builds up the rows of the dynamic programming matrix with reference
// to the previous rows, where `tdist` holds the total distance for a given mapping, and `map`
// holds the information about which path was optimal for each position.
//
// The function _dp_distance_row constructs each row of the dynamic programming matrix in the usual
// way where entries fill in based on the three entries above and to the left.  Note that we duplicate
// entry zero so account for wrap-around at the ends, and we initialize the distance to zero to avoid
// double counting the length of the 0-0 pair.
//
// This function builds up the dynamic programming distance array where each entry in the
// array gives the optimal distance for aligning the corresponding subparts of the two inputs.
// When the array is fully populated, the bottom right corner gives the minimum distance
// for matching the full input lists.  The `map` array contains a the three key values for the three
// directions, where _MAP_DIAG means you map the next vertex of `big` to the next vertex of `small`,
// _MAP_LEFT means you map the next vertex of `big` to the current vertex of `small`, and _MAP_UP
// means you map the next vertex of `small` to the current vertex of `big`.
//
// Return value is [min_distance, map], where map is the array that is used to extract the actual
// vertex map.

_MAP_DIAG = 0;
_MAP_LEFT = 1;
_MAP_UP = 2;

/*
function _dp_distance_array(small, big, abort_thresh=1/0, small_ind=0, tdist=[], map=[]) =
   small_ind == len(small)+1 ? [tdist[len(tdist)-1][len(big)-1], map] :
   let( newrow = _dp_distance_row(small, big, small_ind, tdist) )
   min(newrow[0]) > abort_thresh ? [tdist[len(tdist)-1][len(big)-1],map] :
   _dp_distance_array(small, big, abort_thresh, small_ind+1, concat(tdist, [newrow[0]]), concat(map, [newrow[1]]));
*/


function _dp_distance_array(small, big, abort_thresh=1/0) =
   [for(
        small_ind = 0,
        tdist = [],
        map = []
           ;
        small_ind<=len(small)+1
           ;
        newrow =small_ind==len(small)+1 ? [0,0,0] :  // dummy end case
                           _dp_distance_row(small,big,small_ind,tdist),
        tdist = concat(tdist, [newrow[0]]),
        map = concat(map, [newrow[1]]),
        small_ind = min(newrow[0])>abort_thresh ? len(small)+1 : small_ind+1
       )
     if (small_ind==len(small)+1) each [tdist[len(tdist)-1][len(big)], map]];
                                     //[tdist,map]];


function _dp_distance_row(small, big, small_ind, tdist) =
                    // Top left corner is zero because it gets counted at the end in bottom right corner
   small_ind == 0 ? [cumsum([0,for(i=[1:len(big)]) norm(big[i%len(big)]-small[0])]), replist(_MAP_LEFT,len(big)+1)] :
   [for(big_ind=1,
       newrow=[ norm(big[0] - small[small_ind%len(small)]) + tdist[small_ind-1][0] ],
       newmap = [_MAP_UP]
         ;
       big_ind<=len(big)+1
         ;
       costs = big_ind == len(big)+1 ? [0] :    // handle extra iteration
                             [tdist[small_ind-1][big_ind-1],  // diag
                              newrow[big_ind-1],              // left
                              tdist[small_ind-1][big_ind]],   // up
       newrow = concat(newrow, [min(costs)+norm(big[big_ind%len(big)]-small[small_ind%len(small)])]),
       newmap = concat(newmap, [min_index(costs)]),
       big_ind = big_ind+1
   ) if (big_ind==len(big)+1) each [newrow,newmap]];


function _dp_extract_map(map) =  
      [for(
           i=len(map)-1,
           j=len(map[0])-1,
           smallmap=[],
           bigmap = []
              ;
           j >= 0
              ;
           advance_i = map[i][j]==_MAP_UP || map[i][j]==_MAP_DIAG,
           advance_j = map[i][j]==_MAP_LEFT || map[i][j]==_MAP_DIAG,
           i = i - (advance_i ? 1 : 0),
           j = j - (advance_j ? 1 : 0),
           bigmap = concat( [j%(len(map[0])-1)] ,  bigmap),
           smallmap = concat( [i%(len(map)-1)]  , smallmap)
          )
        if (i==0 && j==0) each [smallmap,bigmap]];
     

// Internal Function: _skin_distance_match(poly1,poly2)
// Usage: _skin_distance_match(poly1,poly2)
// Description:
//   Find a way of associating the vertices of poly1 and vertices of poly2
//   that minimizes the sum of the length of the edges that connect the two polygons.
//   Polygons can be in 2d or 3d.  The algorithm has cubic run time, so it can be
//   slow if you pass large polygons.  The output is a pair of polygons with vertices
//   duplicated as appropriate to be used as input to `skin()`.
// Arguments:
//   poly1 = first polygon to match
//   poly2 = second polygon to match
function _skin_distance_match(poly1,poly2) =
   let(
      swap = len(poly1)>len(poly2),
      big = swap ? poly1 : poly2,
      small = swap ? poly2 : poly1,
      map_poly = [ for(
              i=0,
              bestcost = 1/0,
              bestmap = -1,
              bestpoly = -1
              ;
              i<=len(big)
              ;
              shifted = polygon_shift(big,i),
              result =_dp_distance_array(small, shifted, abort_thresh = bestcost),
              bestmap = result[0]<bestcost ? result[1] : bestmap,
              bestpoly = result[0]<bestcost ? shifted : bestpoly,
              best_i = result[0]<bestcost ? i : best_i,
              bestcost = min(result[0], bestcost),
              i=i+1
              )
              if (i==len(big)) each [bestmap,bestpoly,best_i]],
      map = _dp_extract_map(map_poly[0]),
      smallmap = map[0],
      bigmap = map[1],
      // These shifts are needed to handle the case when points from both ends of one curve map to a single point on the other
      bigshift =  len(bigmap) - max(max_index(bigmap,all=true))-1,
      smallshift = len(smallmap) - max(max_index(smallmap,all=true))-1,
      newsmall = polygon_shift(repeat_entries(small,unique_count(smallmap)[1]),smallshift),
      newbig = polygon_shift(repeat_entries(map_poly[1],unique_count(bigmap)[1]),bigshift)
      )
      swap ? [newbig, newsmall] : [newsmall,newbig];
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Internal Function: _skin_tangent_match()
// Usage: _skin_tangent_match(poly1, poly2)
// Description:
//    Finds a mapping of the vertices of the larger polygon onto the smaller one.  Whichever input is the
//    shorter path is the polygon, and the longer input is the curve.  For every edge of the polygon, the algorithm seeks a plane that contains that
//    edge and is tangent to the curve.  There will be more than one such point.  To choose one, the algorithm centers the polygon and curve on their centroids
//    and chooses the closer tangent point.  The algorithm works its way around the polygon, computing a series of tangent points and then maps all of the
//    points on the curve between two tangent points into one vertex of the polygon.  This algorithm can fail if the curve has too few points or if it is concave.
// Arguments:
//    poly1 = input polygon
//    poly2 = input polygon
function _skin_tangent_match(poly1, poly2) =
    let(
        swap = len(poly1)>len(poly2),
        big = swap ? poly1 : poly2,
        small = swap ? poly2 : poly1,
        curve_offset = centroid(small)-centroid(big),
        cutpts = [for(i=[0:len(small)-1]) _find_one_tangent(big, select(small,i,i+1),curve_offset=curve_offset)],
        d=echo(cutpts = cutpts),
        shift = select(cutpts,-1)+1,
        newbig = polygon_shift(big, shift),
        repeat_counts = [for(i=[0:len(small)-1]) posmod(cutpts[i]-select(cutpts,i-1),len(big))],
        newsmall = repeat_entries(small,repeat_counts)
      )
      assert(len(newsmall)==len(newbig), "Tangent alignment failed, probably because of insufficient points or a concave curve")
      swap ? [newbig, newsmall] : [newsmall, newbig];


function _find_one_tangent(curve, edge, curve_offset=[0,0,0], closed=true) =
  let(
   angles = 
     [for(i=[0:len(curve)-(closed?1:2)])
       let( 
         plane = plane3pt( edge[0], edge[1], curve[i]),
         tangent = [curve[i], select(curve,i+1)]
       )
     plane_line_angle(plane,tangent)],
   zero_cross = [for(i=[0:len(curve)-(closed?1:2)]) if (sign(angles[i]) != sign(select(angles,i+1))) i],
   d = [for(i=zero_cross) distance_from_line(edge, curve[i]+curve_offset)]
  )
  zero_cross[min_index(d)];


// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
