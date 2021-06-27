//////////////////////////////////////////////////////////////////////
// LibFile: skin.scad
//   Functions to skin arbitrary 2D profiles/paths in 3-space.
//   Inspired by list-comprehension-demos skin():
//   - https://github.com/openscad/list-comprehension-demos/blob/master/skin.scad
// Includes:
//   include <BOSL2/std.scad>
//////////////////////////////////////////////////////////////////////


// Section: Skinning

// Function&Module: skin()
// Usage: As module:
//   skin(profiles, slices, [z=], [refine=], [method=], [sampling=], [caps=], [closed=], [style=], [convexity=], [anchor=],[cp=],[spin=],[orient=],[extent=]) [attachments];
// Usage: As function:
//   vnf = skin(profiles, slices, [z=], [refine=], [method=], [sampling=], [caps=], [closed=], [style=]);
// Description:
//   Given a list of two or more path `profiles` in 3d space, produces faces to skin a surface between
//   the profiles.  Optionally the first and last profiles can have endcaps, or the first and last profiles
//   can be connected together.  Each profile should be roughly planar, but some variation is allowed.
//   Each profile must rotate in the same clockwise direction.  If called as a function, returns a
//   [VNF structure](vnf.scad) `[VERTICES, FACES]`.  If called as a module, creates a polyhedron
//    of the skinned profiles.
//   .
//   The profiles can be specified either as a list of 3d curves or they can be specified as
//   2d curves with heights given in the `z` parameter.  It is your responsibility to ensure
//   that the resulting polyhedron is free from self-intersections, which would make it invalid
//   and can result in cryptic CGAL errors upon rendering, even though the polyhedron appears
//   OK during preview.
//   .
//   For this operation to be well-defined, the profiles must all have the same vertex count and
//   we must assume that profiles are aligned so that vertex `i` links to vertex `i` on all polygons.
//   Many interesting cases do not comply with this restriction.  Two basic methods can handle
//   these cases: either subdivide edges (insert additional points along edges)
//   or duplicate vertcies (insert edges of length 0) so that both polygons have
//   the same number of points. 
//   Duplicating vertices allows two distinct points in one polygon to connect to a single point
//   in the other one, creating
//   triangular faces.  You can adjust non-matching polygons yourself
//   either by resampling them using `subdivide_path` or by duplicating vertices using
//   `repeat_entries`.  It is OK to pass a polygon that has the same vertex repeated, such as
//   a square with 5 points (two of which are identical), so that it can match up to a pentagon.
//   Such a combination would create a triangular face at the location of the duplicated vertex.
//   Alternatively, `skin` provides methods (described below) for inserting additional vertices
//   automatically to make incompatible paths match.
//   .
//   In order for skinned surfaces to look good it is usually necessary to use a fine sampling of
//   points on all of the profiles, and a large number of extra interpolated slices between the
//   profiles that you specify.  It is generally best if the triangles forming your polyhedron
//   are approximately equilateral.  The `slices` parameter specifies the number of slices to insert
//   between each pair of profiles, either a scalar to insert the same number everywhere, or a vector
//   to insert a different number between each pair.
//   .
//   Resampling may occur, depending on the `method` parameter, to make profiles compatible.  
//   To force (possibly additional) resampling of the profiles to increase the point density you can set `refine=N`, which
//   will multiply the number of points on your profile by `N`.  You can choose between two resampling
//   schemes using the `sampling` option, which you can set to `"length"` or `"segment"`.
//   The length resampling method resamples proportional to length.
//   The segment method divides each segment of a profile into the same number of points.
//   This means that if you refine a profile with the "segment" method you will get N points
//   on each edge, but if you refine a profile with the "length" method you will get new points
//   distributed around the profile based on length, so small segments will get fewer new points than longer ones.  
//   A uniform division may be impossible, in which case the code computes an approximation, which may result
//   in arbitrary distribution of extra points.  See `subdivide_path` for more details.
//   Note that when dealing with continuous curves it is always better to adjust the
//   sampling in your code to generate the desired sampling rather than using the `refine` argument.
//   .
//   You can choose from five methods for specifying alignment for incommensurate profiles.
//   The available methods are `"distance"`, `"fast_distance"`, `"tangent"`, `"direct"` and `"reindex"`.
//   It is useful to distinguish between continuous curves like a circle and discrete profiles
//   like a hexagon or star, because the algorithms' suitability depend on this distinction.
//   .
//   The default method for aligning profiles is `method="direct"`.
//   If you simply supply a list of compatible profiles it will link them up
//   exactly as you have provided them.  You may find that profiles you want to connect define the
//   right shapes but the point lists don't start from points that you want aligned in your skinned
//   polyhedron.  You can correct this yourself using `reindex_polygon`, or you can use the "reindex"
//   method which will look for the index choice that will minimize the length of all of the edges
//   in the polyhedron---in will produce the least twisted possible result.  This algorithm has quadratic
//   run time so it can be slow with very large profiles.
//   .
//   When the profiles are incommensurate, the "direct" and "reindex" resample them to match.  As noted above,
//   for continuous input curves, it is better to generate your curves directly at the desired sample size,
//   but for mapping between a discrete profile like a hexagon and a circle, the hexagon must be resampled
//   to match the circle.  When you use "direct" or "reindex" the default `sampling` value is 
//   of `sampling="length"` to approximate a uniform length sampling of the profile.  This will generally
//   produce the natural result for connecting two continuously sampled profiles or a continuous
//   profile and a polygonal one.  However depending on your particular case, 
//   `sampling="segment"` may produce a more pleasing result.  These two approaches differ only when
//   the segments of your input profiles have unequal length.
//   .
//   The "distance", "fast_distance" and "tangent" methods work by duplicating vertices to create
//   triangular faces.  In the skined object created by two polygons, every vertex of a polygon must
//   have an edge that connects to some vertex on the other one.  If you connect two squares this can be
//   accomplished with four edges, but if you want to connect a square to a pentagon you must add a
//   fifth edge for the "extra" vertex on the pentagon.  You must now decide which vertex on the square to
//   connect the "extra" edge to.  How do you decide where to put that fifth edge?  The "distance" method answers this
//   question by using an optimization: it minimizes the total length of all the edges connecting
//   the two polygons.   This algorithm generally produces a good result when both profiles are discrete ones with
//   a small number of vertices.  It is computationally intensive (O(N^3)) and may be
//   slow on large inputs.  The resulting surfaces generally have curved faces, so be
//   sure to select a sufficiently large value for `slices` and `refine`.  Note that for
//   this method, `sampling` must be set to `"segment"`, and hence this is the default setting.
//   Using sampling by length would ignore the repeated vertices and ruin the alignment.
//   The "fast_distance" method restricts the optimization by assuming that an edge should connect
//   vertex 0 of the two polygons.  This reduces the run time to O(N^2) and makes
//   the method usable on profiles with more points if you take care to index the inputs to match.  
//   .
//   The `"tangent"` method generally produces good results when
//   connecting a discrete polygon to a convex, finely sampled curve.  Given a polygon and a curve, consider one edge
//   on the polygon.  Find a plane passing through the edge that is tangent to the curve.  The endpoints of the edge and
//   the point of tangency define a triangular face in the output polyhedron.  If you work your way around the polygon
//   edges, you can establish a series of triangular faces in this way, with edges linking the polygon to the curve.
//   You can then complete the edge assignment by connecting all the edges in between the triangular faces together,
//   with many edges meeting at each polygon vertex.  The result is an alternation of flat triangular faces with conical
//   curves joining them.  Another way to think about it is that it splits the points on the curve up into groups and
//   connects all the points in one group to the same vertex on the polygon.
//   .
//   The "tangent" method may fail if the curved profile is non-convex, or doesn't have enough points to distinguish
//   all of the tangent points from each other.    The algorithm treats whichever input profile has fewer points as the polygon
//   and the other one as the curve.  Using `refine` with this method will have little effect on the model, so
//   you should do it only for agreement with other profiles, and these models are linear, so extra slices also
//   have no effect.  For best efficiency set `refine=1` and `slices=0`.  As with the "distance" method, refinement
//   must be done using the "segment" sampling scheme to preserve alignment across duplicated points.
//   Note that the "tangent" method produces similar results to the "distance" method on curved inputs.  If this
//   method fails due to concavity, "fast_distance" may be a good option.  
//   .
//   It is possible to specify `method` and `refine` as arrays, but it is important to observe
//   matching rules when you do this.  If a pair of profiles is connected using "tangent" or "distance"
//   then the `refine` values for those two profiles must be equal.  If a profile is connected by
//   a vertex duplicating method on one side and a resampling method on the other side, then
//   `refine` must be set so that the resulting number of vertices matches the number that is
//   used for the resampled profiles.  The best way to avoid confusion is to ensure that the
//   profiles connected by "direct" or "realign" all have the same number of points and at the
//   transition, the refined number of points matches.
//   .
// Arguments:
//   profiles = list of 2d or 3d profiles to be skinned.  (If 2d must also give `z`.)
//   slices = scalar or vector number of slices to insert between each pair of profiles.  Set to zero to use only the profiles you provided.  Recommend starting with a value around 10.
//   ---
//   refine = resample profiles to this number of points per edge.  Can be a list to give a refinement for each profile.  Recommend using a value above 10 when using the "distance" or "fast_distance" methods.  Default: 1.
//   sampling = sampling method to use with "direct" and "reindex" methods.  Can be "length" or "segment".  Ignored if any profile pair uses either the "distance", "fast_distance", or "tangent" methods.  Default: "length".
//   closed = set to true to connect first and last profile (to make a torus).  Default: false
//   caps = true to create endcap faces when closed is false.  Can be a length 2 boolean array.  Default is true if closed is false.
//   method = method for connecting profiles, one of "distance", "fast_distance", "tangent", "direct" or "reindex".  Default: "direct".
//   z = array of height values for each profile if the profiles are 2d
//   convexity = convexity setting for use with polyhedron.  (module only) Default: 10
//   anchor = Translate so anchor point is at the origin.  (module only) Default: "origin"
//   spin = Rotate this many degrees around Z axis after anchor.  (module only) Default: 0
//   orient = Vector to rotate top towards after spin  (module only)
//   extent = use extent method for computing anchors. (module only)  Default: false
//   cp = set centerpoint for anchor computation.  (module only) Default: object centroid
//   style = vnf_vertex_array style.  Default: "min_edge"
// Example:
//   skin([octagon(4), circle($fn=70,r=2)], z=[0,3], slices=10);
// Example: Rotating the pentagon place the zero index at different locations, giving a twist
//   skin([rot(90,p=pentagon(4)), circle($fn=80,r=2)], z=[0,3], slices=10);
// Example: You can untwist it with the "reindex" method
//   skin([rot(90,p=pentagon(4)), circle($fn=80,r=2)], z=[0,3], slices=10, method="reindex");
// Example: Offsetting the starting edge connects to circles in an interesting way:
//   circ = circle($fn=80, r=3);
//   skin([circ, rot(110,p=circ)], z=[0,5], slices=20);
// Example(FlatSpin,VPD=20): 
//   skin([ yrot(37,p=path3d(circle($fn=128, r=4))), path3d(square(3),3)], method="reindex",slices=10);
// Example(FlatSpin,VPD=16): Ellipses connected with twist
//   ellipse = xscale(2.5,p=circle($fn=80));
//   skin([ellipse, rot(45,p=ellipse)], z=[0,1.5], slices=10);
// Example(FlatSpin,VPD=16): Ellipses connected without a twist.  (Note ellipses stay in the same position: just the connecting edges are different.)
//   ellipse = xscale(2.5,p=circle($fn=80));
//   skin([ellipse, rot(45,p=ellipse)], z=[0,1.5], slices=10, method="reindex");
// Example(FlatSpin,VPD=500):
//   $fn=24;
//   skin([
//         yrot(0, p=yscale(2,p=path3d(circle(d=75)))),
//         [[40,0,100], [35,-15,100], [20,-30,100],[0,-40,100],[-40,0,100],[0,40,100],[20,30,100], [35,15,100]]
//   ],slices=10);
// Example(FlatSpin,VPD=600):
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
//   base = round_corners(square([2,4],center=true), radius=0.5);
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
//       skin(
//           [square([2,.2],center=true),
//            circle($fn=64,r=0.5)], z=[0,3],
//           slices=40,sampling="length",method="reindex");
//       skin(
//           [square([1.9,.1],center=true),
//            circle($fn=64,r=0.45)], z=[-.01,3.01],
//           slices=40,sampling="length",method="reindex");
//   }
// Example: Same thing with "segment" sampling
//   xrot(90)down(1.5)
//   difference() {
//       skin(
//           [square([2,.2],center=true),
//            circle($fn=64,r=0.5)], z=[0,3],
//           slices=40,sampling="segment",method="reindex");
//       skin(
//           [square([1.9,.1],center=true),
//            circle($fn=64,r=0.45)], z=[-.01,3.01],
//           slices=40,sampling="segment",method="reindex");
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
// Example(FlatSpin,VPD=300): A box that is octagonal on the outside and circular on the inside
//   height = 45;
//   sub_base = octagon(d=71, rounding=2, $fn=128);
//   base = octagon(d=75, rounding=2, $fn=128);
//   interior = regular_ngon(n=len(base), d=60);
//   right_half()
//     skin([ sub_base, base, base, sub_base, interior], z=[0,2,height, height, 2], slices=0, refine=1, method="reindex");
// Example: Connecting a pentagon and circle with the "tangent" method produces large triangular faces and cone shaped corners.
//   skin([pentagon(4), circle($fn=80,r=2)], z=[0,3], slices=10, method="tangent");
// Example: rounding corners of a square.  Note that `$fn` makes the number of points constant, and avoiding the `rounding=0` case keeps everything simple.  In this case, the connections between profiles are linear, so there is no benefit to setting `slices` bigger than zero.
//   shapes = [for(i=[.01:.045:2])zrot(-i*180/2,cp=[-8,0,0],p=xrot(90,p=path3d(regular_ngon(n=4, side=4, rounding=i, $fn=64))))];
//   rotate(180) skin( shapes, slices=0);
// Example: Here's a simplified version of the above, with `i=0` included.  That first layer doesn't look good.
//   shapes = [for(i=[0:.2:1]) path3d(regular_ngon(n=4, side=4, rounding=i, $fn=32),i*5)];
//   skin(shapes, slices=0);
// Example: You can fix it by specifying "tangent" for the first method, but you still need "direct" for the rest.
//   shapes = [for(i=[0:.2:1]) path3d(regular_ngon(n=4, side=4, rounding=i, $fn=32),i*5)];
//   skin(shapes, slices=0, method=concat(["tangent"],repeat("direct",len(shapes)-2)));
// Example(FlatSpin,VPD=35): Connecting square to pentagon using "direct" method.
//   skin([regular_ngon(n=4, r=4), regular_ngon(n=5,r=5)], z=[0,4], refine=10, slices=10);
// Example(FlatSpin,VPD=35): Connecting square to shifted pentagon using "direct" method.
//   skin([regular_ngon(n=4, r=4), right(4,p=regular_ngon(n=5,r=5))], z=[0,4], refine=10, slices=10);
// Example(FlatSpin,VPD=35): To improve the look, you can actually rotate the polygons for a more symmetric pattern of lines.   You have to resample yourself before calling `align_polygon` and you should choose a length that is a multiple of both polygon lengths.
//   sq = subdivide_path(regular_ngon(n=4, r=4),40);
//   pent = subdivide_path(regular_ngon(n=5,r=5),40);
//   skin([sq, align_polygon(sq,pent,[0:1:360/5])], z=[0,4], slices=10);
// Example(FlatSpin,VPD=35): For the shifted pentagon we can also align, making sure to pass an appropriate centerpoint to `align_polygon`.
//   sq = subdivide_path(regular_ngon(n=4, r=4),40);
//   pent = right(4,p=subdivide_path(regular_ngon(n=5,r=5),40));
//   skin([sq, align_polygon(sq,pent,[0:1:360/5],cp=[4,0])], z=[0,4], refine=10, slices=10);
// Example(FlatSpin,VPD=35): The "distance" method is a completely different approach.
//   skin([regular_ngon(n=4, r=4), regular_ngon(n=5,r=5)], z=[0,4], refine=10, slices=10, method="distance");
// Example(FlatSpin,VPD=35,VPT=[0,0,4]): Connecting pentagon to heptagon inserts two triangular faces on each side
//   small = path3d(circle(r=3, $fn=5));
//   big = up(2,p=yrot( 0,p=path3d(circle(r=3, $fn=7), 6)));
//   skin([small,big],method="distance", slices=10, refine=10);
// Example(FlatSpin,VPD=35,VPT=[0,0,4]): But just a slight rotation of the top profile moves the two triangles to one end
//   small = path3d(circle(r=3, $fn=5));
//   big = up(2,p=yrot(14,p=path3d(circle(r=3, $fn=7), 6)));
//   skin([small,big],method="distance", slices=10, refine=10);
// Example(FlatSpin,VPD=32,VPT=[1.2,4.3,2]): Another "distance" example:
//   off = [0,2]; 
//   shape = turtle(["right",45,"move", "left",45,"move", "left",45, "move", "jump", [.5+sqrt(2)/2,8]]);
//   rshape = rot(180,cp=centroid(shape)+off, p=shape);
//   skin([shape,rshape],z=[0,4], method="distance",slices=10,refine=15);
// Example(FlatSpin,VPD=32,VPT=[1.2,4.3,2]): Slightly shifting the profile changes the optimal linkage
//   off = [0,1]; 
//   shape = turtle(["right",45,"move", "left",45,"move", "left",45, "move", "jump", [.5+sqrt(2)/2,8]]);
//   rshape = rot(180,cp=centroid(shape)+off, p=shape);
//   skin([shape,rshape],z=[0,4], method="distance",slices=10,refine=15);
// Example(FlatSpin,VPD=444,VPT=[0,0,50]): This optimal solution doesn't look terrible:
//   prof1 = path3d([[-50,-50], [-50,50], [50,50], [25,25], [50,0], [25,-25], [50,-50]]);
//   prof2 = path3d(regular_ngon(n=7, r=50),100);
//   skin([prof1, prof2], method="distance", slices=10, refine=10);
// Example(FlatSpin,VPD=444,VPT=[0,0,50]): But this one looks better.  The "distance" method doesn't find it because it uses two more edges, so it clearly has a higher total edge distance.  We force it by doubling the first two vertices of one of the profiles.
//   prof1 = path3d([[-50,-50], [-50,50], [50,50], [25,25], [50,0], [25,-25], [50,-50]]);
//   prof2 = path3d(regular_ngon(n=7, r=50),100);
//   skin([repeat_entries(prof1,[2,2,1,1,1,1,1]),
//         prof2],
//        method="distance", slices=10, refine=10);
// Example(FlatSpin,VPD=80,VPT=[0,0,7]): The "distance" method will often produces results similar to the "tangent" method if you use it with a polygon and a curve, but the results can also look like this:
//   skin([path3d(circle($fn=128, r=10)), xrot(39, p=path3d(square([8,10]),10))],  method="distance", slices=0);
// Example(FlatSpin,VPD=80,VPT=[0,0,7]): Using the "tangent" method produces:
//   skin([path3d(circle($fn=128, r=10)), xrot(39, p=path3d(square([8,10]),10))],  method="tangent", slices=0);
// Example(FlatSpin,VPD=74): Torus using hexagons and pentagons, where `closed=true`
//   hex = right(7,p=path3d(hexagon(r=3)));
//   pent = right(7,p=path3d(pentagon(r=3)));
//   N=5;
//   skin(
//        [for(i=[0:2*N-1]) yrot(360*i/2/N, p=(i%2==0 ? hex : pent))],
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
// Example(FlatSpin,VPD=935,VPT=[75,0,123]): Vertex count of the polygon changes at every profile
//   skin([
//       for (ang = [0:10:90])
//       rot([0,ang,0], cp=[200,0,0], p=path3d(circle(d=100,$fn=12-(ang/10))))
//   ],method="distance",slices=10,refine=10);
// Example: Möbius Strip.  This is a tricky model because when you work your way around to the connection, the direction of the profiles is flipped, so how can the proper geometry be created?  The trick is to duplicate the first profile and turn the caps off.  The model closes up and forms a valid polyhedron.
//   skin([
//     for (ang = [0:5:360])
//     rot([0,ang,0], cp=[100,0,0], p=rot(ang/2, p=path3d(square([1,30],center=true))))
//   ], caps=false, slices=0, refine=20);
// Example: This model of two scutoids packed together is based on https://www.thingiverse.com/thing:3024272 by mathgrrl
//   sidelen = 10;  // Side length of scutoid
//   height = 25;   // Height of scutoid
//   angle = -15;   // Angle (twists the entire form)
//   push = -5;     // Push (translates the base away from the top)
//   flare = 1;     // Flare (the two pieces will be different unless this is 1)
//   midpoint = .5; // Height of the extra vertex (as a fraction of total height); the two pieces will be different unless this is .5)
//   pushvec = rot(angle/2,p=push*RIGHT);  // Push direction is the the average of the top and bottom mating edges
//   pent = path3d(apply(move(pushvec)*rot(angle),pentagon(side=sidelen,align_side=RIGHT,anchor="side0")));
//   hex = path3d(hexagon(side=flare*sidelen, align_side=RIGHT, anchor="side0"),height);
//   pentmate = path3d(pentagon(side=flare*sidelen,align_side=LEFT,anchor="side0"),height);
//             // Native index would require mapping first and last vertices together, which is not allowed, so shift
//   hexmate = polygon_shift(  
//                           path3d(apply(move(pushvec)*rot(angle),hexagon(side=sidelen,align_side=LEFT,anchor="side0"))),
//                           -1);
//   join_vertex = lerp(
//                       mean(select(hex,1,2)),     // midpoint of "extra" hex edge
//                       mean(select(hexmate,0,1)), // midpoint of "extra" hexmate edge
//                       midpoint);
//   augpent = repeat_entries(pent, [1,2,1,1,1]);         // Vertex 1 will split at the top forming a triangular face with the hexagon
//   augpent_mate = repeat_entries(pentmate,[2,1,1,1,1]); // For mating pentagon it is vertex 0 that splits
//              // Middle is the interpolation between top and bottom except for the join vertex, which is doubled because it splits
//   middle = list_set(lerp(augpent,hex,midpoint),[1,2],[join_vertex,join_vertex]);  
//   middle_mate = list_set(lerp(hexmate,augpent_mate,midpoint), [0,1], [join_vertex,join_vertex]);
//   skin([augpent,middle,hex],  slices=10, refine=10, sampling="segment");
//   color("green")skin([augpent_mate,middle_mate,hexmate],  slices=10,refine=10, sampling="segment");
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
module skin(profiles, slices, refine=1, method="direct", sampling, caps, closed=false, z, style="min_edge", convexity=10,
            anchor="origin",cp,spin=0, orient=UP, extent=false)
{   
    vnf = skin(profiles, slices, refine, method, sampling, caps, closed, z, style=style);
    attachable(anchor=anchor, spin=spin, orient=orient, vnf=vnf, extent=extent, cp=is_def(cp) ? cp : vnf_centroid(vnf))
    {      
        vnf_polyhedron(vnf,convexity=convexity);
        children();
    }
}        


function skin(profiles, slices, refine=1, method="direct", sampling, caps, closed=false, z, style="min_edge") =
  assert(is_def(slices),"The slices argument must be specified.")
  assert(is_list(profiles) && len(profiles)>1, "Must provide at least two profiles")
  let( bad = [for(i=idx(profiles)) if (!(is_path(profiles[i]) && len(profiles[i])>2)) i])
  assert(len(bad)==0, str("Profiles ",bad," are not a paths or have length less than 3"))
  let(
    profcount = len(profiles) - (closed?0:1),
    legal_methods = ["direct","reindex","distance","fast_distance","tangent"],
    caps = is_def(caps) ? caps :
           closed ? false : true,
    capsOK = is_bool(caps) || (is_list(caps) && len(caps)==2 && is_bool(caps[0]) && is_bool(caps[1])),
    fullcaps = is_bool(caps) ? [caps,caps] : caps,
    refine = is_list(refine) ? refine : repeat(refine, len(profiles)),
    slices = is_list(slices) ? slices : repeat(slices, profcount),
    refineOK = [for(i=idx(refine)) if (refine[i]<=0 || !is_integer(refine[i])) i],
    slicesOK = [for(i=idx(slices)) if (!is_integer(slices[i]) || slices[i]<0) i],
    maxsize = list_longest(profiles),
    methodok = is_list(method) || in_list(method, legal_methods),
    methodlistok = is_list(method) ? [for(i=idx(method)) if (!in_list(method[i], legal_methods)) i] : [],
    method = is_string(method) ? repeat(method, profcount) : method,
    // Define to be zero where a resampling method is used and 1 where a vertex duplicator is used
    RESAMPLING = 0,
    DUPLICATOR = 1,
    method_type = [for(m = method) m=="direct" || m=="reindex" ? 0 : 1],
    sampling = is_def(sampling) ? sampling :
               in_list(DUPLICATOR,method_type) ? "segment" : "length" 
  )
  assert(len(refine)==len(profiles), "refine list is the wrong length")
  assert(len(slices)==profcount, str("slices list must have length ",profcount))
  assert(slicesOK==[],str("slices must be nonnegative integers"))
  assert(refineOK==[],str("refine must be postive integer"))
  assert(methodok,str("method must be one of ",legal_methods,". Got ",method))
  assert(methodlistok==[], str("method list contains invalid method at ",methodlistok))
  assert(len(method) == profcount,"Method list is the wrong length")
  assert(in_list(sampling,["length","segment"]), "sampling must be set to \"length\" or \"segment\"")
  assert(sampling=="segment" || (!in_list("distance",method) && !in_list("fast_distance",method) && !in_list("tangent",method)), "sampling is set to \"length\" which is only allowed with methods \"direct\" and \"reindex\"")
  assert(capsOK, "caps must be boolean or a list of two booleans")
  assert(!closed || !caps, "Cannot make closed shape with caps")
  let(
    profile_dim=array_dim(profiles,2),
    profiles_zcheck = (profile_dim != 2) || (profile_dim==2 && is_list(z) && len(z)==len(profiles)), 
    profiles_ok = (profile_dim==2 && is_list(z) && len(z)==len(profiles)) || profile_dim==3
  )
  assert(profiles_zcheck, "z parameter is invalid or has the wrong length.")
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
           i==0 ?  method_type[0] * (closed? last(method_type) : 1) :
           i==len(profiles)-1 ? last(method_type) * (closed ? select(method_type,-2) : 1) :
         method_type[i] * method_type[i-1])],
    parts = search(1,[1,for(i=[0:1:len(profile_resampled)-2]) profile_resampled[i]!=profile_resampled[i+1] ? 1 : 0],0),
    plen = [for(i=idx(parts)) (i== len(parts)-1? len(refined_len) : parts[i+1]) - parts[i]],
    max_list = [for(i=idx(parts)) each repeat(max(select(refined_len, parts[i], parts[i]+plen[i]-1)), plen[i])],
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
                                                         : reindex_polygon(resampled[i-1],resampled[i])],
             sliced = slice_profiles(fixedprof, slices, closed)            
            )
            [!closed ? sliced : concat(sliced,[sliced[0]])]
      :  // There are duplicators, so use approach where each pair is treated separately
      [for(i=[0:profcount-1])
        let(
          pair = 
            method[i]=="distance" ? _skin_distance_match(profiles[i],select(profiles,i+1)) :
            method[i]=="fast_distance" ? _skin_aligned_distance_match(profiles[i], select(profiles,i+1)) :
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
          subdivide_and_slice(pair,slices[i], nsamples, method=sampling)]
  )
  vnf_merge(cleanup=false,
      [for(i=idx(full_list))
          vnf_vertex_array(full_list[i], cap1=i==0 && fullcaps[0], cap2=i==len(full_list)-1 && fullcaps[1],
                           col_wrap=true, style=style)]);

function _skin_core(profiles, caps) =
    let(
        vertices = flatten(profiles),
        plen = len(profiles[0]),
        faces = [
            for(pidx=idx(profiles,e=-2))
            let(
                prof1 = profiles[pidx],
                prof2 = profiles[pidx+1],
                voff = pidx*plen,
                faces = [
                    for(
                        first = true,
                        finishing = false,
                        finished = false,
                        i=0, j=0, side=false;

                        !finished;

                        side =
                            let(
                                p1a = prof1[i%plen],
                                p1b = prof1[(i+1)%plen],
                                p2a = prof2[j%plen],
                                p2b = prof2[(j+1)%plen],
                                dist1 = norm(p1a-p2b),
                                dist2 = norm(p1b-p2a)
                            ) (i==j) ? dist1>dist2 : i<j,
                        p1 = voff + (i%plen),
                        p2 = voff + (j%plen) + plen,
                        p3 = voff + (side? (i+1)%plen : (j+1)%plen + plen),
                        face = [p1, p3, p2],
                        i = i + (side? 1 : 0),
                        j = j + (side? 0 : 1),
                        first = false,
                        finished = finishing,
                        finishing = i>=plen && j>=plen
                    ) if (!first) face
                ]
            ) each faces,
            if (caps[0]) count(plen,reverse=true),
            if (caps[1]) count(plen,plen*(len(profiles)-1))
        ]
    ) [vertices, faces];





// Function: subdivide_and_slice()
// Topics: Paths, Path Subdivision
// Usage:
//   newprof = subdivide_and_slice(profiles, slices, [numpoints], [method], [closed]);
// Description:
//   Subdivides the input profiles to have length `numpoints` where `numpoints` must be at least as
//   big as the largest input profile.  By default `numpoints` is set equal to the length of the
//   largest profile.  You can set `numpoints="lcm"` to sample to the least common multiple of all
//   curves, which will avoid sampling artifacts but may produce a huge output.  After subdivision,
//   profiles are sliced.
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
  

// Function: subdivide_long_segments()
// Topics: Paths, Path Subdivision
// See Also: subdivide_path(), subdivide_and_slice(), path_add_jitter(), jittered_poly()
// Usage:
//   spath = subdivide_long_segments(path, maxlen, [closed=]);
// Description:
//   Evenly subdivides long `path` segments until they are all shorter than `maxlen`.
// Arguments:
//   path = The path to subdivide.
//   maxlen = The maximum allowed path segment length.
//   ---
//   closed = If true, treat path like a closed polygon.  Default: true
// Example:
//   path = pentagon(d=100);
//   spath = subdivide_long_segments(path, 10, closed=true);
//   stroke(path);
//   color("lightgreen") move_copies(path) circle(d=5,$fn=12);
//   color("blue") move_copies(spath) circle(d=3,$fn=12);
function subdivide_long_segments(path, maxlen, closed=false) =
    assert(is_path(path))
    assert(is_finite(maxlen))
    assert(is_bool(closed))
    [
        for (p=pair(path,closed)) let(
            steps = ceil(norm(p[1]-p[0])/maxlen)
        ) each lerpn(p[0], p[1], steps, false),
        if (!closed) last(path)
    ];



// Function: slice_profiles()
// Topics: Paths, Path Subdivision
// Usage:
//   profs = slice_profiles(profiles, slices, [closed]);
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
    count = is_num(slices) ? repeat(slices,len(profiles)-(closed?0:1)) : slices,
    slicelist = [for (i=[0:len(profiles)-(closed?1:2)])
      each lerpn(profiles[i], select(profiles,i+1), count[i]+1, false)
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
   small_ind == 0 ? [cumsum([0,for(i=[1:len(big)]) norm(big[i%len(big)]-small[0])]), repeat(_MAP_LEFT,len(big)+1)] :
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
     

/// Internal Function: _skin_distance_match(poly1,poly2)
/// Usage:
///   polys = _skin_distance_match(poly1,poly2);
/// Description:
///   Find a way of associating the vertices of poly1 and vertices of poly2
///   that minimizes the sum of the length of the edges that connect the two polygons.
///   Polygons can be in 2d or 3d.  The algorithm has cubic run time, so it can be
///   slow if you pass large polygons.  The output is a pair of polygons with vertices
///   duplicated as appropriate to be used as input to `skin()`.
/// Arguments:
///   poly1 = first polygon to match
///   poly2 = second polygon to match
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


// This function associates vertices but with the assumption that index 0 is associated between the
// two inputs.  This gives only quadratic run time.  As above, output is pair of polygons with
// vertices duplicated as suited to use as input to skin(). 

function _skin_aligned_distance_match(poly1, poly2) =
    let(
      result = _dp_distance_array(poly1, poly2, abort_thresh=1/0),
      map = _dp_extract_map(result[1]),
      shift0 = len(map[0]) - max(max_index(map[0],all=true))-1,
      shift1 = len(map[1]) - max(max_index(map[1],all=true))-1,
      new0 = polygon_shift(repeat_entries(poly1,unique_count(map[0])[1]),shift0),
      new1 = polygon_shift(repeat_entries(poly2,unique_count(map[1])[1]),shift1)
  )
  [new0,new1];


//////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// Internal Function: _skin_tangent_match()
/// Usage:
///   x = _skin_tangent_match(poly1, poly2)
/// Description:
///   Finds a mapping of the vertices of the larger polygon onto the smaller one.  Whichever input is the
///   shorter path is the polygon, and the longer input is the curve.  For every edge of the polygon, the algorithm seeks a plane that contains that
///   edge and is tangent to the curve.  There will be more than one such point.  To choose one, the algorithm centers the polygon and curve on their centroids
///   and chooses the closer tangent point.  The algorithm works its way around the polygon, computing a series of tangent points and then maps all of the
///   points on the curve between two tangent points into one vertex of the polygon.  This algorithm can fail if the curve has too few points or if it is concave.
/// Arguments:
///   poly1 = input polygon
///   poly2 = input polygon
function _skin_tangent_match(poly1, poly2) =
    let(
        swap = len(poly1)>len(poly2),
        big = swap ? poly1 : poly2,
        small = swap ? poly2 : poly1,
        curve_offset = centroid(small)-centroid(big),
        cutpts = [for(i=[0:len(small)-1]) _find_one_tangent(big, select(small,i,i+1),curve_offset=curve_offset)],
        shift = last(cutpts)+1,
        newbig = polygon_shift(big, shift),
        repeat_counts = [for(i=[0:len(small)-1]) posmod(cutpts[i]-select(cutpts,i-1),len(big))],
        newsmall = repeat_entries(small,repeat_counts)
    )
    assert(len(newsmall)==len(newbig), "Tangent alignment failed, probably because of insufficient points or a concave curve")
    swap ? [newbig, newsmall] : [newsmall, newbig];


function _find_one_tangent(curve, edge, curve_offset=[0,0,0], closed=true) =
    let(
        angles = [
            for (i = [0:len(curve)-(closed?1:2)])
            let( 
                plane = plane3pt( edge[0], edge[1], curve[i]),
                tangent = [curve[i], select(curve,i+1)]
            ) plane_line_angle(plane,tangent)
        ],
        zero_cross = [
            for (i = [0:len(curve)-(closed?1:2)])
            if (sign(angles[i]) != sign(select(angles,i+1)))
            i
        ],
        d = [
            for (i = zero_cross)
            point_line_distance(curve[i]+curve_offset, edge)
        ]
    ) zero_cross[min_index(d)];


// Function: associate_vertices()
// Usage:
//   newpoly = associate_vertices(polygons, split);
// Description:
//   Takes as input a list of polygons and duplicates specified vertices in each polygon in the list through the series so
//   that the input can be passed to `skin()`.  This allows you to decide how the vertices are linked up rather than accepting
//   the automatically computed minimal distance linkage.  However, the number of vertices in the polygons must not decrease in the list.
//   The output is a list of polygons that all have the same number of vertices with some duplicates.  You specify the vertex splitting
//   using the `split` which is a list where each entry corresponds to a polygon: split[i] is a value or list specifying which vertices in polygon i to split.
//   Give the empty list if you don't want a split for a particular polygon.  If you list a vertex once then it will be split and mapped to
//   two vertices in the next polygon.  If you list it N times then N copies will be created to map to N+1 vertices in the next polygon.
//   You must ensure that each mapping produces the correct number of vertices to exactly map onto every vertex of the next polygon.
//   Note that if you split (only) vertex i of a polygon that means it will map to vertices i and i+1 of the next polygon.  Vertex 0 will always
//   map to vertex 0 and the last vertices will always map to each other, so if you want something different than that you'll need to reindex
//   your polygons.  
// Arguments:
//   polygons = list of polygons to split
//   split = list of lists of split vertices
// Example(FlatSpin,VPD=17,VPT=[0,0,2]):  If you skin together a square and hexagon using the optimal distance method you get two triangular faces on opposite sides:
//   sq = regular_ngon(4,side=2);
//   hex = apply(rot(15),hexagon(side=2));
//   skin([sq,hex], slices=10, refine=10, method="distance", z=[0,4]);
// Example(FlatSpin,VPD=17,VPT=[0,0,2]):  Using associate_vertices you can change the location of the triangular faces.  Here they are connect to two adjacent vertices of the square:
//   sq = regular_ngon(4,side=2);
//   hex = apply(rot(15),hexagon(side=2));
//   skin(associate_vertices([sq,hex],[[1,2]]), slices=10, refine=10, sampling="segment", z=[0,4]);
// Example(FlatSpin,VPD=17,VPT=[0,0,2]): Here the two triangular faces connect to a single vertex on the square.  Note that we had to rotate the hexagon to line them up because the vertices match counting forward, so in this case vertex 0 of the square matches to vertices 0, 1, and 2 of the hexagon.  
//   sq = regular_ngon(4,side=2);
//   hex = apply(rot(60),hexagon(side=2));
//   skin(associate_vertices([sq,hex],[[0,0]]), slices=10, refine=10, sampling="segment", z=[0,4]);
// Example(3D): This example shows several polygons, with only a single vertex split at each step:
//   sq = regular_ngon(4,side=2);
//   pent = pentagon(side=2);
//   hex = hexagon(side=2);
//   sep = regular_ngon(7,side=2);
//   profiles = associate_vertices([sq,pent,hex,sep], [1,3,4]);
//   skin(profiles ,slices=10, refine=10, method="distance", z=[0,2,4,6]);
// Example(3D): The polygons cannot shrink, so if you want to have decreasing polygons you'll need to concatenate multiple results.  Note that it is perfectly ok to duplicate a profile as shown here, where the pentagon is duplicated:
//   sq = regular_ngon(4,side=2);
//   pent = pentagon(side=2);
//   grow = associate_vertices([sq,pent], [1]);
//   shrink = associate_vertices([sq,pent], [2]);
//   skin(concat(grow, reverse(shrink)), slices=10, refine=10, method="distance", z=[0,2,2,4]);
function associate_vertices(polygons, split, curpoly=0) =
   curpoly==len(polygons)-1 ? polygons :
   let(
      polylen = len(polygons[curpoly]),
      cursplit = force_list(split[curpoly])
   )
    assert(len(split)==len(polygons)-1,str(split,"Split list length mismatch: it has length ", len(split)," but must have length ",len(polygons)-1))
    assert(polylen<=len(polygons[curpoly+1]),str("Polygon ",curpoly," has more vertices than the next one."))
    assert(len(cursplit)+polylen == len(polygons[curpoly+1]),
           str("Polygon ", curpoly, " has ", polylen, " vertices.  Next polygon has ", len(polygons[curpoly+1]),
                  " vertices.  Split list has length ", len(cursplit), " but must have length ", len(polygons[curpoly+1])-polylen))
    assert(max(cursplit)<polylen && min(curpoly)>=0,
           str("Split ",cursplit," at polygon ",curpoly," has invalid vertices.  Must be in [0:",polylen-1,"]"))
    len(cursplit)==0 ? associate_vertices(polygons,split,curpoly+1) :
    let(
      splitindex = sort(concat(count(polylen), cursplit)),
      newpoly = [for(i=[0:len(polygons)-1]) i<=curpoly ? select(polygons[i],splitindex) : polygons[i]]
    )
   associate_vertices(newpoly, split, curpoly+1);



// Function&Module: sweep()
// Usage: As Module
//   sweep(shape, transforms, [closed], [caps], [style], [convexity=], [anchor=], [spin=], [orient=], [extent=]) [attachments];
// Usage: As Function
//   vnf = sweep(shape, transforms, [closed], [caps], [style]);
// Description:
//   The input `shape` must be a non-self-intersecting 2D polygon or region, and `transforms`
//   is a list of 4x4 transformation matrices.  The sweep algorithm applies each transformation in sequence
//   to the shape input and links the resulting polygons together to form a polyhedron.
//   If `closed=true` then the first and last transformation are linked together.
//   The `caps` parameter controls whether the ends of the shape are closed.
//   As a function, returns the VNF for the polyhedron.  As a module, computes the polyhedron.
//   .
//   Note that this is a very powerful, general framework for producing polyhedra.  It is important
//   to ensure that your resulting polyhedron does not include any self-intersections, or it will
//   be invalid and will generate CGAL errors.  If you get such errors, most likely you have an
//   overlooked self-intersection.  Note also that the errors will not occur when your shape is alone
//   in your model, but will arise if you add a second object to the model.  This may mislead you into
//   thinking the second object caused a problem.  Even adding a simple cube to the model will reveal the problem.  
// Arguments:
//   shape = 2d path or region, describing the shape to be swept.
//   transforms = list of 4x4 matrices to apply
//   closed = set to true to form a closed (torus) model.  Default: false
//   caps = true to create endcap faces when closed is false.  Can be a singe boolean to specify endcaps at both ends, or a length 2 boolean array.  Default is true if closed is false.
//   style = vnf_vertex_array style.  Default: "min_edge"
//   ---
//   convexity = convexity setting for use with polyhedron.  (module only) Default: 10
//   anchor = Translate so anchor point is at the origin.  (module only) Default: "origin"
//   spin = Rotate this many degrees around Z axis after anchor.  (module only) Default: 0
//   orient = Vector to rotate top towards after spin  (module only)
//   extent = use extent method for computing anchors. (module only)  Default: false
//   cp = set centerpoint for anchor computation.  (module only) Default: object centroid
// Example: This is the "sweep-drop" example from list-comprehension-demos.
//   function drop(t) = 100 * 0.5 * (1 - cos(180 * t)) * sin(180 * t) + 1;
//   function path(t) = [0, 0, 80 + 80 * cos(180 * t)];
//   function rotate(t) = 180 * pow((1 - t), 3);
//   step = 0.01;
//   path_transforms = [for (t=[0:step:1-step]) translate(path(t)) * zrot(rotate(t)) * scale([drop(t), drop(t), 1])];
//   sweep(circle(1, $fn=12), path_transforms);
// Example: Another example from list-comprehension-demos
//   function f(x) = 3 - 2.5 * x;
//   function r(x) = 2 * 180 * x * x * x;
//   pathstep = 1;
//   height = 100;
//   shape_points = subdivide_path(square(10),40,closed=true);
//   path_transforms = [for (i=[0:pathstep:height]) let(t=i/height) up(i) * scale([f(t),f(t),i]) * zrot(r(t))];
//   sweep(shape_points, path_transforms);
// Example: Twisted container.  Note that this technique doesn't create a fixed container wall thickness.  
//   shape = subdivide_path(square(30,center=true), 40, closed=true);
//   outside = [for(i=[0:24]) up(i)*rot(i)*scale(1.25*i/24+1)];
//   inside = [for(i=[24:-1:2]) up(i)*rot(i)*scale(1.2*i/24+1)];
//   sweep(shape, concat(outside,inside));

function sweep(shape, transforms, closed=false, caps, style="min_edge") =
    assert(is_consistent(transforms, ident(4)), "Input transforms must be a list of numeric 4x4 matrices in sweep")
    assert(is_path(shape,2) || is_region(shape), "Input shape must be a 2d path or a region.")
    let(
        caps = is_def(caps) ? caps :
            closed ? false : true,
        capsOK = is_bool(caps) || (is_list(caps) && len(caps)==2 && is_bool(caps[0]) && is_bool(caps[1])),
        fullcaps = is_bool(caps) ? [caps,caps] : caps
    )
    assert(len(transforms), "transformation must be length 2 or more")
    assert(capsOK, "caps must be boolean or a list of two booleans")
    assert(!closed || !caps, "Cannot make closed shape with caps")
    is_region(shape)? let(
        regions = split_nested_region(shape),
        rtrans = reverse(transforms),
        vnfs = [
            for (rgn=regions) each [
                for (path=rgn)
                    sweep(path, transforms, closed=closed, caps=false),
                if (fullcaps[0]) region_faces(rgn, transform=transforms[0], reverse=true),
                if (fullcaps[1]) region_faces(rgn, transform=last(transforms)),
            ],
        ],
        vnf = vnf_merge(vnfs)
    ) vnf :
    assert(len(shape)>=3, "shape must be a path of at least 3 non-colinear points")
    vnf_vertex_array([for(i=[0:len(transforms)-(closed?0:1)]) apply(transforms[i%len(transforms)],path3d(shape))],
                     cap1=fullcaps[0],cap2=fullcaps[1],col_wrap=true,style=style);


module sweep(shape, transforms, closed=false, caps, style="min_edge", convexity=10,
             anchor="origin",cp,spin=0, orient=UP, extent=false)
{
    vnf = sweep(shape, transforms, closed, caps, style);
    attachable(anchor=anchor, spin=spin, orient=orient, vnf=vnf, extent=extent, cp=is_def(cp) ? cp : vnf_centroid(vnf))
    {      
        vnf_polyhedron(vnf,convexity=convexity);
        children();
    }
}        


// Function&Module: path_sweep()
// Usage: As module
//   path_sweep(shape, path, [method], [normal=], [closed=], [twist=], [twist_by_length=], [symmetry=], [last_normal=], [tangent=], [relaxed=], [caps=], [style=], [convexity=], [transforms=], [anchor=], [cp=], [spin=], [orient=], [extent=]) [attachments];
// Usage: As function   
//   vnf = path_sweep(shape, path, [method], [normal=], [closed=], [twist=], [twist_by_length=], [symmetry=], [last_normal=], [tangent=], [relaxed=], [caps=], [style=], [convexity=], [transforms=]);
// Description:
//   Takes as input a 2D polygon path, and a 2d or 3d path and constructs a polyhedron by sweeping the shape along the path.
//   When run as a module returns the polyhedron geometry.  When run as a function returns a VNF by default or if you set `transforms=true`
//   then it returns a list of transformations suitable as input to `sweep`.
//   .
//   The sweep operation has an ambiguity: the shape can rotate around the axis defined by the path.  Several options provide
//   methods for controlling this rotation.  You can choose from three different methods for selecting the rotation of your shape.
//   None of these methods will produce good, or even valid, results on all inputs, so it is important to select a suitable method. 
//   You can also add (or remove) twist to the model.  This twist adjustment is done uniformly in arc length by default, or you
//   can set `twist_by_length=false` to distribute the twist uniformly over the path point list.
//   .
//   The method is set using the parameter with that name to one of the following:
//   .
//   The "incremental" method (the default) works by adjusting the shape at each step by the minimal rotation that makes the shape normal to the tangent
//   at the next point.  This method is robust in that it always produces a valid result for well-behaved paths with sufficiently high
//   sampling.  Unfortunately, it can produce a large amount of undesirable twist.  When constructing a closed shape this algorithm in
//   its basic form provides no guarantee that the start and end shapes match up.  To prevent a sudden twist at the last segment,
//   the method calculates the required twist for a good match and distributes it over the whole model (as if you had specified a
//   twist amount).  By default the end shape is required to match the starting shape exactly, but if your shape as rotational
//   symmetry you can specify this using the `symmetry` argument, and then a smaller amount of twist is needed to make this adjustment.
//   The symmetry argument gives the number of rotations that map the shape exactly onto itself, so a pentagon has 5-fold symmetry.
//   This argument is only valid for closed sweeps.  To start the algorithm, we need an initial condition.  This is supplied by
//   using the `normal` argument to give a direction to align the Y axis of your shape.  By default the normal points UP if the path
//   makes an angle of 45 deg or less with the xy plane and it points BACK if the path makes a higher angle with the XY plane.  You
//   can also supply `last_normal` which provides an ending orientation constraint.  Be aware that the curve may still exhibit
//   twisting in the middle.  This method is the default because it is the most robust, not because it generally produces the best result.  
//   .
//   The "natural" method works by computing the Frenet frame at each point on the path.  This is defined by the tangent to the curve and
//   the normal which lies in the plane defined by the curve at each point.  This normal points in the direction of curvature of the curve.
//   The result is a very well behaved set of sections without any unexpected twisting---as long as the curvature never falls to zero.  At a
//   point of zero curvature (a flat point), the curve does not define a plane and the natural normal is not defined.  Furthermore, even if
//   you skip over this troublesome point so the normal is defined, it can change direction abruptly when the curvature is zero, leading to
//   a nasty twist and an invalid model.  A simple example is a circular arc joined to another arc that curves the other direction.  Note
//   that the X axis of the shape is aligned with the normal from the Frenet frame.
//   .
//   The "manual" method allows you to specify your desired normal either globally with a single vector, or locally with
//   a list of normal vectors for every path point.  The normal you supply is projected to be orthogonal to the tangent to the
//   path and the Y direction of your shape will be aligned with the projected normal.  (Note this is different from the "natural" method.)  
//   Careless choice of a normal may result in a twist in the shape, or an error if your normal is parallel to the path tangent.
//   If you set `relax=true` then the condition that the cross sections are orthogonal to the path is relaxed and the swept object
//   uses the actual specified normal.  In this case, the tangent is projected to be orthogonal to your supplied normal to define
//   the cross section orientation.  Specifying a list of normal vectors gives you complete control over the orientation of your
//   cross sections and can be useful if you want to position your model to be on the surface of some solid.
//   .
//   For any method you can use the `twist` argument to add the specified number of degrees of twist into the model.  
//   If the model is closed then the twist must be a multiple of 360/symmetry.  The twist is normally spread uniformly along your shape
//   based on the path length.  If you set `twist_by_length` to false then the twist will be uniform based on the point count of your path.
// Arguments:
//   shape = A 2D polygon path or region describing the shape to be swept.
//   path = 2D or 3D path giving the path to sweep over
//   method = one of "incremental", "natural" or "manual".  Default: "incremental"
//   ---
//   normal = normal vector for initializing the incremental method, or for setting normals with method="manual".  Default: UP if the path makes an angle lower than 45 degrees to the xy plane, BACK otherwise.
//   closed = path is a closed loop.  Default: false
//   twist = amount of twist to add in degrees.  For closed sweeps must be a multiple of 360/symmetry.  Default: 0
//   symmetry = symmetry of the shape when closed=true.  Allows the shape to join with a 360/symmetry rotation instead of a full 360 rotation.  Default: 1
//   last_normal = normal to last point in the path for the "incremental" method.  Constrains the orientation of the last cross section if you supply it.
//   tangent = a list of tangent vectors in case you need more accuracy (particularly at the end points of your curve)
//   relaxed = set to true with the "manual" method to relax the orthogonality requirement of cross sections to the path tangent.  Default: false
//   caps = Can be a boolean or vector of two booleans.  Set to false to disable caps at the two ends.  Default: true
//   style = vnf_vertex_array style.  Default: "min_edge"
//   transforms = set to true to return transforms instead of a VNF.  These transforms can be manipulated and passed to sweep().  Default: false.
//   convexity = convexity parameter for polyhedron().  Only accepted by the module version.  Default: 10
//   anchor = Translate so anchor point is at the origin.  (module only) Default: "origin"
//   spin = Rotate this many degrees around Z axis after anchor.  (module only) Default: 0
//   orient = Vector to rotate top towards after spin  (module only)
//   extent = use extent method for computing anchors. (module only)  Default: false
//   cp = set centerpoint for anchor computation.  (module only) Default: object centroid
//
// Example(2D): We'll use this shape in several examples
//   ushape = [[-10, 0],[-10, 10],[ -7, 10],[ -7, 2],[  7, 2],[  7, 7],[ 10, 7],[ 10, 0]];
//   polygon(ushape);
// Example: Sweep along a clockwise elliptical arc, using default "incremental" method.
//   ushape = [[-10, 0],[-10, 10],[ -7, 10],[ -7, 2],[  7, 2],[  7, 7],[ 10, 7],[ 10, 0]];
//   elliptic_arc = xscale(2, p=arc($fn=64,angle=[180,00], r=30));  // Clockwise 
//   path_sweep(ushape, path3d(elliptic_arc));
// Example: Sweep along a counter-clockwise elliptical arc.  Note that the orientation of the shape flips.  
//   ushape = [[-10, 0],[-10, 10],[ -7, 10],[ -7, 2],[  7, 2],[  7, 7],[ 10, 7],[ 10, 0]];
//   elliptic_arc = xscale(2, p=arc($fn=64,angle=[0,180], r=30));   // Counter-clockwise 
//   path_sweep(ushape, path3d(elliptic_arc));
// Example: Sweep along a clockwise elliptical arc, using "natural" method, which lines up the X axis of the shape with the direction of curvature.  This means the X axis will point inward, so a counterclockwise arc gives:
//   ushape = [[-10, 0],[-10, 10],[ -7, 10],[ -7, 2],[  7, 2],[  7, 7],[ 10, 7],[ 10, 0]];
//   elliptic_arc = xscale(2, p=arc($fn=64,angle=[0,180], r=30));  // Counter-clockwise 
//   path_sweep(ushape, elliptic_arc, method="natural");
// Example: Sweep along a clockwise elliptical arc, using "natural" method.  If the curve is clockwise than the shape flips upside-down to align the X axis.  
//   ushape = [[-10, 0],[-10, 10],[ -7, 10],[ -7, 2],[  7, 2],[  7, 7],[ 10, 7],[ 10, 0]];
//   elliptic_arc = xscale(2, p=arc($fn=64,angle=[180,0], r=30));  // Clockwise 
//   path_sweep(ushape, path3d(elliptic_arc), method="natural");
// Example: Sweep along a clockwise elliptical arc, using "manual" method.  You can orient the shape in a direction you choose (subject to the constraint that the profiles remain normal to the path):
//   ushape = [[-10, 0],[-10, 10],[ -7, 10],[ -7, 2],[  7, 2],[  7, 7],[ 10, 7],[ 10, 0]];
//   elliptic_arc = xscale(2, p=arc($fn=64,angle=[180,0], r=30));  // Clockwise 
//   path_sweep(ushape, path3d(elliptic_arc), method="manual", normal=UP+RIGHT);
// Example: Sweep along a clockwise elliptical arc, using "manual" method.  You can orient the shape in a direction you choose (subject to the constraint that the profiles remain normal to the path):
//   ushape = [[-10, 0],[-10, 10],[ -7, 10],[ -7, 2],[  7, 2],[  7, 7],[ 10, 7],[ 10, 0]];
//   elliptic_arc = yscale(2, p=arc($fn=64,angle=[180,0], r=30));  // Clockwise 
//   path_sweep(ushape, path3d(elliptic_arc), method="manual", normal=UP+RIGHT, relaxed=false);
// Example: It is easy to produce an invalid shape when your path has a smaller radius of curvature than the width of your shape.  The exact threshold where the shape becomes invalid depends on the density of points on your path.  The error may not be immediately obvious, as the swept shape appears fine when alone in your model, but adding a cube to the model reveals the problem.  In this case the pentagon is turned so its longest direction points inward to create the singularity.  
//   qpath = [for(x=[-3:.01:3]) [x,x*x/1.8,0]];
//   echo(radius_of_curvature = 1/max(path_curvature(qpath)));   // Prints 0.9, but we use pentagon with radius of 1.0 > 0.9
//   path_sweep(apply(rot(90),pentagon(r=1)), qpath, normal=BACK, method="manual", relaxed=false);
//   cube(0.5);    // Adding a small cube forces a CGAL computation which reveals the error by displaying nothing or giving a cryptic message
// Example: Using the `relax` option we allow the profiles to deviate from orthogonality to the path.  This eliminates the crease that broke the previous example because the sections are all parallel to each other.  
//   qpath = [for(x=[-3:.01:3]) [x,x*x/1.8,0]];
//   path_sweep(apply(rot(90),pentagon(r=1)), qpath, normal=BACK, method="manual", relaxed=true);
//   cube(0.5);    // Adding a small cube is not a problem with this valid model
// Example:  This 3d arc produces a result that twists to an undefined angle.  By default the incremental method sets the starting normal to UP, but the ending normal is unconstrained.  
//   ushape = [[-10, 0],[-10, 10],[ -7, 10],[ -7, 2],[  7, 2],[  7, 7],[ 10, 7],[ 10, 0]];
//   arc = yrot(37, p=path3d(arc($fn=64, r=30, angle=[0,180])));
//   path_sweep(ushape, arc, method="incremental");
// Example: You can constrain the last normal as well.  Here we point it right, which produces a nice result.  
//   ushape = [[-10, 0],[-10, 10],[ -7, 10],[ -7, 2],[  7, 2],[  7, 7],[ 10, 7],[ 10, 0]];
//   arc = yrot(37, p=path3d(arc($fn=64, r=30, angle=[0,180])));
//   path_sweep(ushape, arc, method="incremental", last_normal=RIGHT);
// Example: Here we constrain the last normal to UP.  Be aware that the behavior in the middle is unconstrained.  
//   ushape = [[-10, 0],[-10, 10],[ -7, 10],[ -7, 2],[  7, 2],[  7, 7],[ 10, 7],[ 10, 0]];
//   arc = yrot(37, p=path3d(arc($fn=64, r=30, angle=[0,180])));
//   path_sweep(ushape, arc, method="incremental", last_normal=UP);
// Example: The "natural" method produces a very different result
//   ushape = [[-10, 0],[-10, 10],[ -7, 10],[ -7, 2],[  7, 2],[  7, 7],[ 10, 7],[ 10, 0]];
//   arc = yrot(37, p=path3d(arc($fn=64, r=30, angle=[0,180])));
//   path_sweep(ushape, arc, method="natural");
// Example: When the path starts at an angle of more that 45 deg to the xy plane the initial normal for "incremental" is BACK.  This produces the effect of the shape rising up out of the xy plane.  (Using UP for a vertical path is invalid, hence the need for a split in the defaults.)  
//   ushape = [[-10, 0],[-10, 10],[ -7, 10],[ -7, 2],[  7, 2],[  7, 7],[ 10, 7],[ 10, 0]];
//   arc = xrot(75, p=path3d(arc($fn=64, r=30, angle=[0,180])));
//   path_sweep(ushape, arc, method="incremental");
// Example: Adding twist
//   elliptic_arc = xscale(2, p=arc($fn=64,angle=[0,180], r=3));   // Counter-clockwise 
//   path_sweep(pentagon(r=1), path3d(elliptic_arc), twist=72);
// Example: Closed shape
//   ellipse = xscale(2, p=circle($fn=64, r=3));  
//   path_sweep(pentagon(r=1), path3d(ellipse), closed=true);
// Example: Closed shape with added twist
//   ellipse = xscale(2, p=circle($fn=64, r=3));
//   pentagon = subdivide_path(pentagon(r=1), 30);  // Looks better with finer sampling
//   path_sweep(pentagon, path3d(ellipse), closed=true, twist=360);
// Example: The last example was a lot of twist.  In order to use less twist you have to tell `path_sweep` that your shape has symmetry, in this case 5-fold.  Mobius strip with pentagon cross section:
//   ellipse = xscale(2, p=circle($fn=64, r=3));
//   pentagon = subdivide_path(pentagon(r=1), 30);  // Looks better with finer sampling
//   path_sweep(pentagon, path3d(ellipse), closed=true, symmetry = 5, twist=2*360/5);
// Example: A helical path reveals the big problem with the "incremental" method: it can introduce unexpected and extreme twisting.  (Note helix example came from list-comprehension-demos)
//   function helix(t) = [(t / 1.5 + 0.5) * 30 * cos(6 * 360 * t),
//                        (t / 1.5 + 0.5) * 30 * sin(6 * 360 * t),
//                         200 * (1 - t)];
//   helix_steps = 200;
//   helix = [for (i=[0:helix_steps]) helix(i/helix_steps)];
//   ushape = [[-10, 0],[-10, 10],[ -7, 10],[ -7, 2],[  7, 2],[  7, 7],[ 10, 7],[ 10, 0]];
//   path_sweep(ushape, helix);
// Example: You can constrain both ends, but still the twist remains:
//   function helix(t) = [(t / 1.5 + 0.5) * 30 * cos(6 * 360 * t),
//                        (t / 1.5 + 0.5) * 30 * sin(6 * 360 * t),
//                         200 * (1 - t)];
//   helix_steps = 200;
//   helix = [for (i=[0:helix_steps]) helix(i/helix_steps)];
//   ushape = [[-10, 0],[-10, 10],[ -7, 10],[ -7, 2],[  7, 2],[  7, 7],[ 10, 7],[ 10, 0]];
//   path_sweep(ushape, helix, normal=UP, last_normal=UP);
// Example: Even if you manually guess the amount of twist and remove it, the result twists one way and then the other:
//   function helix(t) = [(t / 1.5 + 0.5) * 30 * cos(6 * 360 * t),
//                        (t / 1.5 + 0.5) * 30 * sin(6 * 360 * t),
//                         200 * (1 - t)];
//   helix_steps = 200;
//   helix = [for (i=[0:helix_steps]) helix(i/helix_steps)];
//   ushape = [[-10, 0],[-10, 10],[ -7, 10],[ -7, 2],[  7, 2],[  7, 7],[ 10, 7],[ 10, 0]];
//   path_sweep(ushape, helix, normal=UP, last_normal=UP, twist=360);
// Example: To get a good result you must use a different method.  
//   function helix(t) = [(t / 1.5 + 0.5) * 30 * cos(6 * 360 * t),
//                        (t / 1.5 + 0.5) * 30 * sin(6 * 360 * t),
//                         200 * (1 - t)];
//   helix_steps = 200;
//   helix = [for (i=[0:helix_steps]) helix(i/helix_steps)];
//   ushape = [[-10, 0],[-10, 10],[ -7, 10],[ -7, 2],[  7, 2],[  7, 7],[ 10, 7],[ 10, 0]];
//   path_sweep(ushape, helix, method="natural");
// Example: Note that it may look like the shape above is flat, but the profiles are very slightly tilted due to the nonzero torsion of the curve.  If you want as flat as possible, specify it so with the "manual" method:
//   function helix(t) = [(t / 1.5 + 0.5) * 30 * cos(6 * 360 * t),
//                        (t / 1.5 + 0.5) * 30 * sin(6 * 360 * t),
//                         200 * (1 - t)];
//   helix_steps = 200;
//   helix = [for (i=[0:helix_steps]) helix(i/helix_steps)];
//   ushape = [[-10, 0],[-10, 10],[ -7, 10],[ -7, 2],[  7, 2],[  7, 7],[ 10, 7],[ 10, 0]];
//   path_sweep(ushape, helix, method="manual", normal=UP);
// Example: What if you want to angle the shape inward?  This requires a different normal at every point in the path:
//   function helix(t) = [(t / 1.5 + 0.5) * 30 * cos(6 * 360 * t),
//                        (t / 1.5 + 0.5) * 30 * sin(6 * 360 * t),
//                         200 * (1 - t)];
//   helix_steps = 200;
//   helix = [for (i=[0:helix_steps]) helix(i/helix_steps)];
//   normals = [for(i=[0:helix_steps]) [-cos(6*360*i/helix_steps), -sin(6*360*i/helix_steps), 2.5]];
//   ushape = [[-10, 0],[-10, 10],[ -7, 10],[ -7, 2],[  7, 2],[  7, 7],[ 10, 7],[ 10, 0]];
//   path_sweep(ushape, helix, method="manual", normal=normals);
// Example: When using "manual" it is important to choose a normal that works for the whole path, producing a consistent result.  Here we have specified an upward normal, and indeed the shape is pointed up everywhere, but two abrupt transitional twists render the model invalid.  
//   yzcircle = yrot(90,p=path3d(circle($fn=64, r=30)));
//   ushape = [[-10, 0],[-10, 10],[ -7, 10],[ -7, 2],[  7, 2],[  7, 7],[ 10, 7],[ 10, 0]];
//   path_sweep(ushape, yzcircle, method="manual", normal=UP, closed=true);
// Example: The "natural" method will introduce twists when the curvature changes direction.  A warning is displayed.  
//   arc1 = path3d(arc(angle=90, r=30));
//   arc2 = xrot(-90, cp=[0,30],p=path3d(arc(angle=[90,180], r=30)));
//   two_arcs = simplify_path(concat(arc1,arc2));
//   ushape = [[-10, 0],[-10, 10],[ -7, 10],[ -7, 2],[  7, 2],[  7, 7],[ 10, 7],[ 10, 0]];
//   path_sweep(ushape, two_arcs, method="natural");
// Example: The only simple way to get a good result is the "incremental" method:
//   arc1 = path3d(arc(angle=90, r=30));
//   arc2 = xrot(-90, cp=[0,30],p=path3d(arc(angle=[90,180], r=30)));
//   arc3 = apply( translate([-30,60,30])*yrot(90), path3d(arc(angle=[270,180], r=30)));
//   three_arcs = simplify_path(concat(arc1,arc2,arc3));
//   ushape = [[-10, 0],[-10, 10],[ -7, 10],[ -7, 2],[  7, 2],[  7, 7],[ 10, 7],[ 10, 0]];
//   path_sweep(ushape, three_arcs, method="incremental");
// Example: knot example from list-comprehension-demos, "incremental" method
//   function knot(a,b,t) =   // rolling knot 
//        [ a * cos (3 * t) / (1 - b* sin (2 *t)), 
//          a * sin( 3 * t) / (1 - b* sin (2 *t)), 
//        1.8 * b * cos (2 * t) /(1 - b* sin (2 *t))]; 
//   a = 0.8; b = sqrt (1 - a * a); 
//   ksteps = 400;
//   knot_path = [for (i=[0:ksteps-1]) 50 * knot(a,b,(i/ksteps)*360)];
//   ushape = [[-10, 0],[-10, 10],[ -7, 10],[ -7, 2],[  7, 2],[  7, 7],[ 10, 7],[ 10, 0]];
//   path_sweep(ushape, knot_path, closed=true, method="incremental");
// Example: knot example from list-comprehension-demos, "natural" method.  Which one do you like better? 
//   function knot(a,b,t) =   // rolling knot 
//        [ a * cos (3 * t) / (1 - b* sin (2 *t)), 
//          a * sin( 3 * t) / (1 - b* sin (2 *t)), 
//        1.8 * b * cos (2 * t) /(1 - b* sin (2 *t))]; 
//   a = 0.8; b = sqrt (1 - a * a); 
//   ksteps = 400;
//   knot_path = [for (i=[0:ksteps-1]) 50 * knot(a,b,(i/ksteps)*360)];
//   ushape = [[-10, 0],[-10, 10],[ -7, 10],[ -7, 2],[  7, 2],[  7, 7],[ 10, 7],[ 10, 0]];
//   path_sweep(ushape, knot_path, closed=true, method="natural");
// Example: knot with twist.  Note if you twist it the other direction the center section untwists because of the natural twist there.  Also compare to the "incremental" method which has less twist in the center.  
//   function knot(a,b,t) =   // rolling knot 
//        [ a * cos (3 * t) / (1 - b* sin (2 *t)), 
//          a * sin( 3 * t) / (1 - b* sin (2 *t)), 
//        1.8 * b * cos (2 * t) /(1 - b* sin (2 *t))]; 
//   a = 0.8; b = sqrt (1 - a * a); 
//   ksteps = 400;
//   knot_path = [for (i=[0:ksteps-1]) 50 * knot(a,b,(i/ksteps)*360)];
//   path_sweep(subdivide_path(pentagon(r=12),30), knot_path, closed=true, twist=-360*8, symmetry=5, method="natural");
// Example: twisted knot with twist distributed by path sample points instead of by length using `twist_by_length=false`
//   function knot(a,b,t) =   // rolling knot 
//           [ a * cos (3 * t) / (1 - b* sin (2 *t)), 
//             a * sin( 3 * t) / (1 - b* sin (2 *t)), 
//           1.8 * b * cos (2 * t) /(1 - b* sin (2 *t))]; 
//   a = 0.8; b = sqrt (1 - a * a); 
//   ksteps = 400;
//   knot_path = [for (i=[0:ksteps-1]) 50 * knot(a,b,(i/ksteps)*360)];
//   path_sweep(subdivide_path(pentagon(r=12),30), knot_path, closed=true, twist=-360*8, symmetry=5, method="natural", twist_by_length=false);
// Example: This torus knot example comes from list-comprehension-demos.  The knot lies on the surface of a torus.  When we use the "natural" method the swept figure is angled compared to the surface of the torus because the curve doesn't follow geodesics of the torus.  
//   function knot(phi,R,r,p,q) = 
//       [ (r * cos(q * phi) + R) * cos(p * phi),
//         (r * cos(q * phi) + R) * sin(p * phi),
//          r * sin(q * phi) ];
//   ushape = 3*[[-10, 0],[-10, 10],[ -7, 10],[ -7, 2],[  7, 2],[  7, 7],[ 10, 7],[ 10, 0]];
//   points = 50;       // points per loop
//   R = 400; r = 150;  // Torus size
//   p = 2;  q = 5;     // Knot parameters
//   %torus(r_maj=R,r_min=r);
//   k = max(p,q) / gcd(p,q) * points; 
//   knot_path   = [ for (i=[0:k-1]) knot(360*i/k/gcd(p,q),R,r,p,q) ];
//   path_sweep(rot(90,p=ushape),knot_path,  method="natural", closed=true);
// Example: By computing the normal to the torus at the path we can orient the path to lie on the surface of the torus:
//   function knot(phi,R,r,p,q) = 
//       [ (r * cos(q * phi) + R) * cos(p * phi),
//         (r * cos(q * phi) + R) * sin(p * phi),
//          r * sin(q * phi) ];
//   function knot_normal(phi,R,r,p,q) =  
//       knot(phi,R,r,p,q) 
//           - R*unit(knot(phi,R,r,p,q)
//               - [0,0, knot(phi,R,r,p,q)[2]]) ;
//   ushape = 3*[[-10, 0],[-10, 10],[ -7, 10],[ -7, 2],[  7, 2],[  7, 7],[ 10, 7],[ 10, 0]];
//   points = 50;       // points per loop
//   R = 400; r = 150;  // Torus size
//   p = 2;  q = 5;     // Knot parameters
//   %torus(r_maj=R,r_min=r);
//   k = max(p,q) / gcd(p,q) * points; 
//   knot_path   = [ for (i=[0:k-1]) knot(360*i/k/gcd(p,q),R,r,p,q) ];
//   normals = [ for (i=[0:k-1]) knot_normal(360*i/k/gcd(p,q),R,r,p,q) ];
//   path_sweep(ushape,knot_path,normal=normals, method="manual", closed=true);
// Example: You can request the transformations and manipulate them before passing them on to sweep.  Here we construct a tube that changes scale by first generating the transforms and then applying the scale factor and connecting the inside and outside.  Note that the wall thickness varies because it is produced by scaling.  
//   shape = star(n=5, r=10, ir=5);
//   rpath = arc(25, points=[[29,6,-4], [3,4,6], [1,1,7]]);
//   trans = path_sweep(shape, rpath, transforms=true);
//   outside = [for(i=[0:len(trans)-1]) trans[i]*scale(lerp(1,1.5,i/(len(trans)-1)))];
//   inside = [for(i=[len(trans)-1:-1:0]) trans[i]*scale(lerp(1.1,1.4,i/(len(trans)-1)))];
//   sweep(shape, concat(outside,inside),closed=true);
// Example: Using path_sweep on a region
//   rgn1 = [for (d=[10:10:60]) circle(d=d,$fn=8)];
//   rgn2 = [square(30,center=false)];
//   rgn3 = [for (size=[10:10:20]) move([15,15],p=square(size=size, center=true))];
//   mrgn = union(rgn1,rgn2);
//   orgn = difference(mrgn,rgn3);
//   path_sweep(orgn,arc(r=40,angle=180));
// Example: A region with a twist
//   region = [for(i=pentagon(5)) move(i,p=circle(r=2,$fn=25))];
//   path_sweep(region,
//              circle(r=16,$fn=75),closed=true,
//              twist=360/5*2,symmetry=5);
// Example: Cutting a cylinder with a curved path.  Note that in this case, the incremental method produces just a slight twist but the natural method produces an extreme twist.  But manual specification produces no twist, as desired:
//   $fn=90;
//   r=8;
//   thickness=1;
//   len=21;
//   curve = [for(theta=[0:4:359])
//              [r*cos(theta), r*sin(theta), 10+sin(6*theta)]];
//   difference(){
//     cylinder(r=r, l=len);
//     down(.5)cylinder(r=r-thickness, l=len+1);
//     path_sweep(left(.05,square([1.1,1])), curve, closed=true,
//                method="manual", normal=UP);
//   }
module path_sweep(shape, path, method="incremental", normal, closed=false, twist=0, twist_by_length=true,
                    symmetry=1, last_normal, tangent, relaxed=false, caps, style="min_edge", convexity=10,
                    anchor="origin",cp,spin=0, orient=UP, extent=false)
{
    vnf = path_sweep(shape, path, method, normal, closed, twist, twist_by_length,
                    symmetry, last_normal, tangent, relaxed, caps, style);
    attachable(anchor=anchor, spin=spin, orient=orient, vnf=vnf, extent=extent, cp=is_def(cp) ? cp : vnf_centroid(vnf))
    {      
        vnf_polyhedron(vnf,convexity=convexity);
        children();
    }
}        


function path_sweep(shape, path, method="incremental", normal, closed=false, twist=0, twist_by_length=true,
                    symmetry=1, last_normal, tangent, relaxed=false, caps, style="min_edge", transforms=false) = 
  assert(!closed || twist % (360/symmetry)==0, str("For a closed sweep, twist must be a multiple of 360/symmetry = ",360/symmetry))
  assert(closed || symmetry==1, "symmetry must be 1 when closed is false")
  assert(is_integer(symmetry) && symmetry>0, "symmetry must be a positive integer")
//  let(shape = check_and_fix_path(shape,valid_dim=2,closed=true,name="shape"))
  assert(is_path(path), "input path is not a path")
  assert(!closed || !approx(path[0],last(path)), "Closed path includes start point at the end")
  let(
    path = path3d(path),
    caps = is_def(caps) ? caps :
           closed ? false : true,
    capsOK = is_bool(caps) || (is_list(caps) && len(caps)==2 && is_bool(caps[0]) && is_bool(caps[1])),
    fullcaps = is_bool(caps) ? [caps,caps] : caps
  )
  assert(capsOK, "caps must be boolean or a list of two booleans")
  assert(!closed || !caps, "Cannot make closed shape with caps")
  assert(is_undef(normal) || (is_vector(normal) && len(normal)==3) || (is_path(normal) && len(normal)==len(path) && len(normal[0])==3), "Invalid normal specified")
  assert(is_undef(tangent) || (is_path(tangent) && len(tangent)==len(path) && len(tangent[0])==3), "Invalid tangent specified")
  let(
    tangents = is_undef(tangent) ? path_tangents(path,closed=closed) : [for(t=tangent) unit(t)],
    normal = is_path(normal) ? [for(n=normal) unit(n)] :
             is_def(normal) ? unit(normal) :
             method =="incremental" && abs(tangents[0].z) > 1/sqrt(2) ? BACK : UP,
    normals = is_path(normal) ? normal : repeat(normal,len(path)),
    pathfrac = twist_by_length ? path_length_fractions(path, closed) : [for(i=[0:1:len(path)]) i / (len(path)-(closed?0:1))],
    L = len(path),
    transform_list = 
      method=="incremental" ?
        let(rotations =
               [for( i  = 0,
                     ynormal = normal - (normal * tangents[0])*tangents[0],
                     rotation = affine3d_frame_map(y=ynormal, z=tangents[0]) 
                       ;
                     i < len(tangents) + (closed?1:0) ;
                     rotation = i<len(tangents)-1+(closed?1:0)? rot(from=tangents[i],to=tangents[(i+1)%L])*rotation : undef,
                     i=i+1
                    )
                 rotation],
            // The mismatch is the inverse of the last transform times the first one for the closed case, or the inverse of the
            // desired final transform times the realized final transform in the open case.  Note that when closed==true the last transform
            // is a actually looped around and applies to the first point position, so if we got back exactly where we started
            // then it will be the identity, but we might have accumulated some twist which will show up as a rotation around the
            // X axis.  Similarly, in the closed==false case the desired and actual transformations can only differ in the twist,
            // so we can need to calculate the twist angle so we can apply a correction, which we distribute uniformly over the whole path.
            reference_rot = closed ? rotations[0] :   
                         is_undef(last_normal) ? last(rotations) : 
                           let(
                               last_tangent = last(tangents),
                               lastynormal = last_normal - (last_normal * last_tangent) * last_tangent
                           )
                         affine3d_frame_map(y=lastynormal, z=last_tangent),
            mismatch = transpose(last(rotations)) * reference_rot, 
            correction_twist = atan2(mismatch[1][0], mismatch[0][0]),
            // Spread out this extra twist over the whole sweep so that it doesn't occur
            // abruptly as an artifact at the last step.  
            twistfix = correction_twist%(360/symmetry),
            adjusted_final = !closed ? undef :
                          translate(path[0]) * rotations[0] * zrot(-correction_twist+correction_twist%(360/symmetry)-twist)
        )  [for(i=idx(path)) translate(path[i]) * rotations[i] * zrot((twistfix-twist)*pathfrac[i]), if(closed) adjusted_final] :
      method=="manual" ?
            [for(i=[0:L-(closed?0:1)]) let(    
                     ynormal = relaxed ? normals[i%L] : normals[i%L] - (normals[i%L] * tangents[i%L])*tangents[i%L],
                     znormal = relaxed ? tangents[i%L] - (normals[i%L] * tangents[i%L])*normals[i%L] : tangents[i%L],
                     rotation = affine3d_frame_map(y=ynormal, z=znormal)
                 )
                 assert(approx(ynormal*znormal,0),str("Supplied normal is parallel to the path tangent at point ",i))
                 translate(path[i%L])*rotation*zrot(-twist*pathfrac[i]),
            ] :
      method=="natural" ?   // map x axis of shape to the path normal, which points in direction of curvature
            let (pathnormal = path_normals(path, tangents, closed))
            assert(all_defined(pathnormal),"Natural normal vanishes on your curve, select a different method")
            let( testnormals = [for(i=[0:len(pathnormal)-1-(closed?1:2)]) pathnormal[i]*select(pathnormal,i+2)],
                 a=[for(i=idx(testnormals)) testnormals[i]<.5 ? echo(str("Big change at index ",i," pn=",pathnormal[i]," pn2= ",select(pathnormal,i+2))):0],
                 dummy = min(testnormals) < .5 ? echo("WARNING: ***** Abrupt change in normal direction.  Consider a different method *****") :0
               )
            [for(i=[0:L-(closed?0:1)]) let(
                     rotation = affine3d_frame_map(x=pathnormal[i%L], z=tangents[i%L])
                 )
                 translate(path[i%L])*rotation*zrot(-twist*pathfrac[i])
               ] :
      assert(false,"Unknown method or no method given")[], // unknown method
      ends_match = !closed ? true
                 : let( rshape = is_path(shape) ? [path3d(shape)]
                                                : [for(s=shape) path3d(s)]
                   )
                   regions_equal(apply(transform_list[0], rshape),
                                 apply(transform_list[L], rshape)),
      dummy = ends_match ? 0 : echo("WARNING: ***** The points do not match when closing the model *****")
    )
    transforms ? transform_list : sweep(is_path(shape)?clockwise_polygon(shape):shape, transform_list, closed=false, caps=fullcaps,style=style);


// Function&Module: path_sweep2d()
// Usage: as module
//   path_sweep2d(shape, path, [closed], [caps], [quality], [style], [convexity=], [anchor=], [spin=], [orient=], [extent=], [cp=]) [attachments];
// Usage: as function
//   vnf = path_sweep2d(shape, path, [closed], [caps], [quality], [style]);
// Description:
//   Takes an input 2D polygon (the shape) and a 2d path and constructs a polyhedron by sweeping the shape along the path.
//   When run as a module returns the polyhedron geometry.  When run as a function returns a VNF.
//   .
//   Unlike path_sweep(), local self-intersections (creases in the output) are allowed and do not produce CGAL errors.
//   This is accomplished by using offset() calculations, which are more expensive than simply copying the shape along
//   the path, so if you do not have local self-intersections, use path_sweep() instead.  Note that global self-intersections
//   will still give rise to CGAL errors.  You should be able to handle these by partitioning your model.  The y axis of the
//   shape is mapped to the z axis in the swept polyhedron.
//   The quality parameter is passed to offset to determine the offset quality.
// Arguments:
//   shape = a 2D polygon describing the shape to be swept
//   path = a 2D path giving the path to sweep over
//   closed = path is a closed loop.  Default: false
//   caps = true to create endcap faces when closed is false.  Can be a length 2 boolean array.  Default is true if closed is false.
//   quality = quality of offset used in calculation.  Default: 1
//   style = vnf_vertex_array style.  Default: "min_edge"
//   ---
//   convexity = convexity parameter for polyhedron (module only)  Default: 10
//   anchor = Translate so anchor point is at the origin.  (module only)  Default: "origin"
//   spin = Rotate this many degrees around Z axis after anchor.  (module only) Default: 0
//   orient = Vector to rotate top towards after spin  (module only)
//   extent = use extent method for computing anchors. (module only)  Default: false
//   cp = set centerpoint for anchor computation.  (module only) Default: object centroid
// Example: Sine wave example with self-intersections at each peak.  This would fail with path_sweep(). 
//   sinewave = [for(i=[-30:10:360*2+30]) [i/40,3*sin(i)]];
//   path_sweep2d(circle(r=3,$fn=15), sinewave);
// Example: The ends can look weird if they are in a place where self intersection occurs.  This is a natural result of how offset behaves at ends of a path.  
//   coswave = [for(i=[0:10:360*1.5]) [i/40,3*cos(i)]];
//   zrot(-20)
//     path_sweep2d( circle(r=3,$fn=15), coswave);
// Example: This closed path example works ok as long as the hole in the center remains open.
//   ellipse = yscale(3,p=circle(r=3,$fn=120));
//   path_sweep2d(circle(r=2.5,$fn=32), reverse(ellipse), closed=true);
// Example: When the hole is closed a global intersection renders the model invalid.  You can fix this by taking the union of the two (valid) halves.
//   ellipse = yscale(3,p=circle(r=3,$fn=120));
//   L = len(ellipse);
//   path_sweep2d(circle(r=3.25, $fn=32), select(ellipse,floor(L*.2),ceil(L*.8)),closed=false);
//   path_sweep2d(circle(r=3.25, $fn=32), select(ellipse,floor(L*.7),ceil(L*.3)),closed=false);

function path_sweep2d(shape, path, closed=false, caps, quality=1, style="min_edge") =
   let(
        caps = is_def(caps) ? caps
             : closed ? false : true,
        capsOK = is_bool(caps) || (is_list(caps) && len(caps)==2 && is_bool(caps[0]) && is_bool(caps[1])),
        fullcaps = is_bool(caps) ? [caps,caps] : caps,
        shape = check_and_fix_path(shape,valid_dim=2,closed=true,name="shape")
   )
   assert(capsOK, "caps must be boolean or a list of two booleans")
   assert(!closed || !caps, "Cannot make closed shape with caps")
   let(
        profile = ccw_polygon(shape),
        flip = closed && polygon_is_clockwise(path) ? -1 : 1,
        path = flip ? reverse(path) : path,
        proflist= transpose(
                     [for(pt = profile)
                        let( 
                            ofs = offset(path, delta=-flip*pt.x, return_faces=true,closed=closed, quality=quality),
                            map = subindex(_ofs_vmap(ofs,closed=closed),1)
                        ) 
                        select(path3d(ofs[0],pt.y),map)
                      ]
                  )
   )
   vnf_vertex_array([
                     each proflist,
                     if (closed) proflist[0]
                    ],cap1=fullcaps[0],cap2=fullcaps[1],col_wrap=true,style=style);


module path_sweep2d(profile, path, closed=false, caps, quality=1, style="min_edge", convexity=10,
                    anchor="origin", cp, spin=0, orient=UP, extent=false)
{
   vnf = path_sweep2d(profile, path, closed, caps, quality, style);
   attachable(anchor=anchor, spin=spin, orient=orient, vnf=vnf, extent=extent, cp=is_def(cp) ? cp : vnf_centroid(vnf))
    {      
        vnf_polyhedron(vnf,convexity=convexity);
        children();
    }
}

// Extract vertex mapping from offset face list.  The output of this function
// is a list of pairs [i,j] where i is an index into the parent curve and j is
// an index into the offset curve.  It would probably make sense to rewrite
// offset() to return this instead of the face list and have offset_sweep
// use this input to assemble the faces it needs.

function _ofs_vmap(ofs,closed=false) =
    let(   // Caclulate length of the first (parent) curve
        firstlen = max(flatten(ofs[1]))+1-len(ofs[0])
    )
    [
     for(entry=ofs[1]) _ofs_face_edge(entry,firstlen),
     if (!closed) _ofs_face_edge(last(ofs[1]),firstlen,second=true)
    ];


// Extract first (default) or second edge that connects the parent curve to its offset.  The first input
// face is a list of 3 or 4 vertices as indices into the two curves where the parent curve vertices are
// numbered from 0 to firstlen-1 and the offset from firstlen and up.  The firstlen pararameter is used
// to determine which curve the vertices belong to and to remove the offset so that the return gives
// the index into each curve with a 0 base.  
function _ofs_face_edge(face,firstlen,second=false) =
   let(
       itry = min_index(face),
       i = select(face,itry-1)<firstlen ? itry-1:itry,
       edge1 = select(face,[i,i-1]),
       edge2 = select(face,i+1)<firstlen ? select(face,[i+1,i+2])
                                         : select(face,[i,i+1])
   )
   (second ? edge2 : edge1)-[0,firstlen];

// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
