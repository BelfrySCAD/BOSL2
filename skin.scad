//////////////////////////////////////////////////////////////////////
// LibFile: skin.scad
//   This file provides functions and modules that construct shapes from a list of cross sections.
//   In the case of skin() you specify each cross sectional shape yourself, and the number of
//   points can vary.  The various forms of sweep use a fixed shape, which may follow a path, or
//   be transformed in other ways to produce the list of cross sections.  In all cases it is the
//   user's responsibility to avoid creating a self-intersecting shape, which will produce
//   cryptic CGAL errors.  This file was inspired by list-comprehension-demos skin():
//   - https://github.com/openscad/list-comprehension-demos/blob/master/skin.scad
// Includes:
//   include <BOSL2/std.scad>
// FileGroup: Advanced Modeling
// FileSummary: Construct 3D shapes from 2D cross sections of the desired shape.
// FileFootnotes: STD=Included in std.scad
//////////////////////////////////////////////////////////////////////


// Section: Skin and sweep

// Function&Module: skin()
// Synopsis: Connect a sequence of arbitrary polygons into a 3D object. 
// SynTags: VNF, Geom
// Topics: Extrusion, Skin
// See Also: vnf_vertex_array(), sweep(), linear_sweep(), rotate_sweep(), spiral_sweep(), path_sweep(), offset_sweep()
// Usage: As module:
//   skin(profiles, slices, [z=], [refine=], [method=], [sampling=], [caps=], [closed=], [style=], [convexity=], [anchor=],[cp=],[spin=],[orient=],[atype=]) [ATTACHMENTS];
// Usage: As function:
//   vnf = skin(profiles, slices, [z=], [refine=], [method=], [sampling=], [caps=], [closed=], [style=], [anchor=],[cp=],[spin=],[orient=],[atype=]);
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
//   and can result in cryptic CGAL errors upon rendering with a second object present, even though the polyhedron appears
//   OK during preview or when rendered by itself.
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
//   either by resampling them using {{subdivide_path()}} or by duplicating vertices using
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
//   in arbitrary distribution of extra points.  See {{subdivide_path()}} for more details.
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
//   in the polyhedron&mdash;it will produce the least twisted possible result.  This algorithm has quadratic
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
//   profiles connected by "direct" or "reindex" all have the same number of points and at the
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
//   anchor = Translate so anchor point is at the origin.  Default: "origin"
//   spin = Rotate this many degrees around Z axis after anchor.  Default: 0
//   orient = Vector to rotate top towards after spin
//   atype = Select "hull" or "intersect" anchor types. Default: "hull"
//   cp = Centerpoint for determining "intersect" anchors or centering the shape.  Determintes the base of the anchor vector.  Can be "centroid", "mean", "box" or a 3D point.  Default: "centroid"
//   style = vnf_vertex_array style.  Default: "min_edge"
// Named Anchors:
//   "origin" = The native position of the shape.  
// Anchor Types:
//   "hull" = Anchors to the virtual convex hull of the shape.
//   "intersect" = Anchors to the surface of the shape.
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
// Example(FlatSpin,VPD=185): In this example reindexing does not fix the orientation of the triangle because it happens in 3d within skin(), so we have to reverse the triangle manually
//   ellipse = yscale(3,circle(r=10, $fn=32));
//   tri = move([-50/3,-9],[[0,0], [50,0], [0,27]]);
//   skin([ellipse, reverse(tri)], z=[0,20], slices=20, method="reindex");
// Example(FlatSpin,VPD=185): You can get a nicer transition by rotating the polygons for better alignment.  You have to resample yourself before calling `align_polygon`. The orientation is fixed so we do not need to reverse.
//   ellipse = yscale(3,circle(r=10, $fn=32));
//   tri = move([-50/3,-9],
//              subdivide_path([[0,0], [50,0], [0,27]], 32));
//   aligned = align_polygon(ellipse,tri, [0:5:180]);
//   skin([ellipse, aligned], z=[0,20], slices=20);
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
//   pushvec = rot(angle/2,p=push*RIGHT);  // Push direction is the average of the top and bottom mating edges
//   pent = path3d(apply(move(pushvec)*rot(angle),pentagon(side=sidelen,align_side=RIGHT,anchor="side0")));
//   hex = path3d(hexagon(side=flare*sidelen, align_side=RIGHT, anchor="side0"),height);
//   pentmate = path3d(pentagon(side=flare*sidelen,align_side=LEFT,anchor="side0"),height);
//             // Native index would require mapping first and last vertices together, which is not allowed, so shift
//   hexmate = list_rotate(
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
            anchor="origin",cp="centroid",spin=0, orient=UP, atype="hull")
{
    vnf = skin(profiles, slices, refine, method, sampling, caps, closed, z, style=style);
    vnf_polyhedron(vnf,convexity=convexity,spin=spin,anchor=anchor,orient=orient,atype=atype,cp=cp)
        children();
}


function skin(profiles, slices, refine=1, method="direct", sampling, caps, closed=false, z, style="min_edge",
              anchor="origin",cp="centroid",spin=0, orient=UP, atype="hull") =
  assert(in_list(atype, _ANCHOR_TYPES), "Anchor type must be \"hull\" or \"intersect\"")
  assert(is_def(slices),"The slices argument must be specified.")
  assert(is_list(profiles) && len(profiles)>1, "Must provide at least two profiles")
  let(
       profiles = [for(p=profiles) if (is_region(p) && len(p)==1) p[0] else p]
  )
  let( bad = [for(i=idx(profiles)) if (!(is_path(profiles[i]) && len(profiles[i])>2)) i])
  assert(len(bad)==0, str("Profiles ",bad," are not a paths or have length less than 3"))
  let(
    profcount = len(profiles) - (closed?0:1),
    legal_methods = ["direct","reindex","distance","fast_distance","tangent"],
    caps = is_def(caps) ? caps :
           closed ? false : true,
    capsOK = is_bool(caps) || is_bool_list(caps,2),
    fullcaps = is_bool(caps) ? [caps,caps] : caps,
    refine = is_list(refine) ? refine : repeat(refine, len(profiles)),
    slices = is_list(slices) ? slices : repeat(slices, profcount),
    refineOK = [for(i=idx(refine)) if (refine[i]<=0 || !is_integer(refine[i])) i],
    slicesOK = [for(i=idx(slices)) if (!is_integer(slices[i]) || slices[i]<0) i],
    maxsize = max_length(profiles),
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
    profile_dim=list_shape(profiles,2),
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
          subdivide_and_slice(pair,slices[i], nsamples, method=sampling)],
      vnf=vnf_join(
          [for(i=idx(full_list))
              vnf_vertex_array(full_list[i], cap1=i==0 && fullcaps[0], cap2=i==len(full_list)-1 && fullcaps[1],
                               col_wrap=true, style=style)])
  )
  reorient(anchor,spin,orient,vnf=vnf,p=vnf,extent=atype=="hull",cp=cp);



// Function&Module: linear_sweep()
// Synopsis: Create a linear extrusion from a path, with optional texturing. 
// SynTags: VNF, Geom
// Topics: Extrusion, Textures, Sweep
// See Also: rotate_sweep(), sweep(), spiral_sweep(), path_sweep(), offset_sweep()
// Usage: As Module
//   linear_sweep(region, [height], [center=], [slices=], [twist=], [scale=], [style=], [caps=], [convexity=]) [ATTACHMENTS];
// Usage: With Texturing
//   linear_sweep(region, [height], [center=], texture=, [tex_size=]|[tex_reps=], [tex_depth=], [style=], [tex_samples=], ...) [ATTACHMENTS];
// Usage: As Function
//   vnf = linear_sweep(region, [height], [center=], [slices=], [twist=], [scale=], [style=], [caps=]);
//   vnf = linear_sweep(region, [height], [center=], texture=, [tex_size=]|[tex_reps=], [tex_depth=], [style=], [tex_samples=], ...);
// Description:
//   If called as a module, creates a polyhedron that is the linear extrusion of the given 2D region or polygon.
//   If called as a function, returns a VNF that can be used to generate a polyhedron of the linear extrusion
//   of the given 2D region or polygon.  The benefit of using this, over using `linear_extrude region(rgn)` is
//   that it supports `anchor`, `spin`, `orient` and attachments.  You can also make more refined
//   twisted extrusions by using `maxseg` to subsample flat faces.
//   .
//   Anchoring for linear_sweep is based on the anchors for the swept region rather than from the polyhedron that is created.  This can produce more
//   predictable anchors for LEFT, RIGHT, FWD and BACK in many cases, but the anchors may only
//   be aproximately correct for twisted objects, and corner anchors may point in unexpected directions in some cases.
//   If you need anchors directly computed from the surface you can pass the vnf from linear_sweep
//   to {{vnf_polyhedron()}}, which will compute anchors directly from the full VNF.  
// Arguments:
//   region = The 2D [Region](regions.scad) or polygon that is to be extruded.
//   h / height / l / length = The height to extrude the region.  Default: 1
//   center = If true, the created polyhedron will be vertically centered.  If false, it will be extruded upwards from the XY plane.  Default: `false`
//   ---
//   twist = The number of degrees to rotate the top of the shape, clockwise around the Z axis, relative to the bottom.  Default: 0
//   scale = The amount to scale the top of the shape, in the X and Y directions, relative to the size of the bottom.  Default: 1
//   shift = The amount to shift the top of the shape, in the X and Y directions, relative to the position of the bottom.  Default: [0,0]
//   slices = The number of slices to divide the shape into along the Z axis, to allow refinement of detail, especially when working with a twist.  Default: `twist/5`
//   maxseg = If given, then any long segments of the region will be subdivided to be shorter than this length.  This can refine twisting flat faces a lot.  Default: `undef` (no subsampling)
//   texture = A texture name string, or a rectangular array of scalar height values (0.0 to 1.0), or a VNF tile that defines the texture to apply to vertical surfaces.  See {{texture()}} for what named textures are supported.
//   tex_size = An optional 2D target size for the textures.  Actual texture sizes will be scaled somewhat to evenly fit the available surface. Default: `[5,5]`
//   tex_reps = If given instead of tex_size, a 2-vector giving the number of texture tile repetitions in the horizontal and vertical directions on the extrusion.
//   tex_inset = If numeric, lowers the texture into the surface by the specified proportion, e.g. 0.5 would lower it half way into the surface.  If `true`, insets by exactly its full depth.  Default: `false`
//   tex_rot = Rotate texture by specified angle, which must be a multiple of 90 degrees.  Default: 0
//   tex_depth = Specify texture depth; if negative, invert the texture.  Default: 1.
//   tex_samples = Minimum number of "bend points" to have in VNF texture tiles.  Default: 8
//   style = The style to use when triangulating the surface of the object.  Valid values are `"default"`, `"alt"`, or `"quincunx"`.
//   caps = If false do not create end caps.  Can be a boolean vector.  Default: true
//   convexity = Max number of surfaces any single ray could pass through.  Module use only.
//   cp = Centerpoint for determining intersection anchors or centering the shape.  Determines the base of the anchor vector.  Can be "centroid", "mean", "box" or a 3D point.  Default: `"centroid"`
//   atype = Set to "hull" or "intersect" to select anchor type.  Default: "hull"
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `"origin"`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Anchor Types:
//   "hull" = Anchors to the virtual convex hull of the shape.
//   "intersect" = Anchors to the surface of the shape.
//   "bbox" = Anchors to the bounding box of the extruded shape.
// Named Anchors:
//   "origin" = Centers the extruded shape vertically only, but keeps the original path positions in the X and Y.  Oriented UP.
//   "original_base" = Keeps the original path positions in the X and Y, but at the bottom of the extrusion.  Oriented UP.
// Example: Extruding a Compound Region.
//   rgn1 = [for (d=[10:10:60]) circle(d=d,$fn=8)];
//   rgn2 = [square(30,center=false)];
//   rgn3 = [for (size=[10:10:20]) move([15,15],p=square(size=size, center=true))];
//   mrgn = union(rgn1,rgn2);
//   orgn = difference(mrgn,rgn3);
//   linear_sweep(orgn,height=20,convexity=16);
// Example: With Twist, Scale, Shift, Slices and Maxseg.
//   rgn1 = [for (d=[10:10:60]) circle(d=d,$fn=8)];
//   rgn2 = [square(30,center=false)];
//   rgn3 = [
//       for (size=[10:10:20])
//       apply(
//          move([15,15]),
//          square(size=size, center=true)
//       )
//   ];
//   mrgn = union(rgn1,rgn2);
//   orgn = difference(mrgn,rgn3);
//   linear_sweep(
//       orgn, height=50, maxseg=2, slices=40,
//       twist=90, scale=0.5, shift=[10,5],
//       convexity=16
//   );
// Example: Anchors on an Extruded Region
//   rgn1 = [for (d=[10:10:60]) circle(d=d,$fn=8)];
//   rgn2 = [square(30,center=false)];
//   rgn3 = [
//       for (size=[10:10:20])
//       apply(
//           move([15,15]),
//           rect(size=size)
//       )
//   ];
//   mrgn = union(rgn1,rgn2);
//   orgn = difference(mrgn,rgn3);
//   linear_sweep(orgn,height=20,convexity=16)
//       show_anchors();
// Example: "diamonds" texture.
//   path = glued_circles(r=15, spread=40, tangent=45);
//   linear_sweep(
//       path, texture="diamonds", tex_size=[5,10],
//       h=40, style="concave");
// Example: "pyramids" texture.
//   linear_sweep(
//       rect(50), texture="pyramids", tex_size=[10,10],
//       h=40, style="convex");
// Example: "bricks_vnf" texture.
//   path = glued_circles(r=15, spread=40, tangent=45);
//   linear_sweep(
//       path, texture="bricks_vnf", tex_size=[10,10],
//       tex_depth=0.25, h=40);
// Example: User defined heightfield texture.
//   path = ellipse(r=[20,10]);
//   texture = [for (i=[0:9])
//       [for (j=[0:9])
//           1/max(0.5,norm([i,j]-[5,5])) ]];
//   linear_sweep(
//       path, texture=texture, tex_size=[5,5],
//       h=40, style="min_edge", anchor=BOT);
// Example: User defined VNF tile texture.
//   path = ellipse(r=[20,10]);
//   tex = let(n=16,m=0.25) [
//        [
//            each resample_path(path3d(square(1)),n),
//            each move([0.5,0.5],
//                p=path3d(circle(d=0.5,$fn=n),m)),
//            [1/2,1/2,0],
//        ], [
//            for (i=[0:1:n-1]) each [
//                [i,(i+1)%n,(i+3)%n+n],
//                [i,(i+3)%n+n,(i+2)%n+n],
//                [2*n,n+i,n+(i+1)%n],
//            ]
//        ]
//   ];
//   linear_sweep(path, texture=tex, tex_size=[5,5], h=40);
// Example: Textured with twist and scale.
//   linear_sweep(regular_ngon(n=3, d=50),
//       texture="rough", h=100, tex_depth=2,
//       tex_size=[20,20], style="min_edge",
//       convexity=10, scale=0.2, twist=120);
// Example: As Function
//   path = glued_circles(r=15, spread=40, tangent=45);
//   vnf = linear_sweep(
//       path, h=40, texture="trunc_pyramids", tex_size=[5,5],
//       tex_depth=1, style="convex");
//   vnf_polyhedron(vnf, convexity=10);
// Example: VNF tile that has no top/bottom edges and produces a disconnected result
//   shape = skin([rect(2/5),
//                 rect(2/3),
//                 rect(2/5)],
//                z=[0,1/2,1],
//                slices=0,
//                caps=false);
//   tile = move([0,1/2,2/3],yrot(90,shape));
//   linear_sweep(circle(20), texture=tile,
//                tex_size=[10,10],tex_depth=5,
//                h=40,convexity=4);
// Example: The same tile from above, turned 90 degrees, creates problems at the ends, because the end cap is not a connected polygon.  When the ends are disconnected you may find that some parts of the end cap are missing and spurious polygons included.  
//  shape = skin([rect(2/5),
//                rect(2/3),
//                rect(2/5)],
//               z=[0,1/2,1],
//               slices=0,
//               caps=false);
//  tile = move([1/2,1,2/3],xrot(90,shape));
//  linear_sweep(circle(20), texture=tile,
//               tex_size=[30,20],tex_depth=15,
//               h=40,convexity=4);
// Example: This example shows some endcap polygons missing and a spurious triangle
//   shape = skin([rect(2/5),
//                 rect(2/3),
//                 rect(2/5)],
//                z=[0,1/2,1],
//                slices=0,
//                caps=false);
//   tile = xscale(.5,move([1/2,1,2/3],xrot(90,shape)));
//   doubletile = vnf_join([tile, right(.5,tile)]);
//   linear_sweep(circle(20), texture=doubletile,
//                tex_size=[45,45],tex_depth=15, h=40);
// Example: You can fix ends for disconnected cases using {{top_half()}} and {{bottom_half()}}
//   shape = skin([rect(2/5),
//                 rect(2/3),
//                 rect(2/5)],
//                z=[0,1/2,1],
//                slices=0,
//                caps=false);
//   tile = move([1/2,1,2/3],xrot(90,shape));
//   vnf_polyhedron(
//     top_half(
//       bottom_half(
//         linear_sweep(circle(20), texture=tile,
//                     tex_size=[30,20],tex_depth=15,
//                     h=40.2,caps=false),
//       z=20),
//     z=-20)); 

module linear_sweep(
    region, height, center,
    twist=0, scale=1, shift=[0,0],
    slices, maxseg, style="default", convexity, caps=true, 
    texture, tex_size=[5,5], tex_reps, tex_counts,
    tex_inset=false, tex_rot=0,
    tex_depth, tex_scale, tex_samples,
    cp, atype="hull", h,l,length,
    anchor, spin=0, orient=UP
) {
    h = one_defined([h, height,l,length],"h,height,l,length",dflt=1);
    region = force_region(region);
    check = assert(is_region(region),"Input is not a region");
    anchor = center==true? "origin" :
        center == false? "original_base" :
        default(anchor, "original_base");
    vnf = linear_sweep(
        region, height=h, style=style, caps=caps, 
        twist=twist, scale=scale, shift=shift,
        texture=texture,
        tex_size=tex_size,
        tex_reps=tex_reps,
        tex_counts=tex_counts,
        tex_inset=tex_inset,
        tex_rot=tex_rot,
        tex_depth=tex_depth,
        tex_samples=tex_samples,
        slices=slices,
        maxseg=maxseg,
        anchor="origin"
    );
    anchors = [
        named_anchor("original_base", [0,0,-h/2], UP)
    ];
    cp = default(cp, "centroid");
    geom = atype=="hull"?  attach_geom(cp=cp, region=region, h=h, extent=true, shift=shift, scale=scale, twist=twist, anchors=anchors) :
        atype=="intersect"?  attach_geom(cp=cp, region=region, h=h, extent=false, shift=shift, scale=scale, twist=twist, anchors=anchors) :
        atype=="bbox"?
            let(
                bounds = pointlist_bounds(flatten(region)),
                size = bounds[1] - bounds[0],
                midpt = (bounds[0] + bounds[1])/2
            )
            attach_geom(cp=[0,0,0], size=point3d(size,h), offset=point3d(midpt), shift=shift, scale=scale, twist=twist, anchors=anchors) :
        assert(in_list(atype, ["hull","intersect","bbox"]), "Anchor type must be \"hull\", \"intersect\", or \"bbox\".");
    attachable(anchor,spin,orient, geom=geom) {
        vnf_polyhedron(vnf, convexity=convexity);
        children();
    }
}


function linear_sweep(
    region, height, center,
    twist=0, scale=1, shift=[0,0],
    slices, maxseg, style="default", caps=true, 
    cp, atype="hull", h,
    texture, tex_size=[5,5], tex_reps, tex_counts,
    tex_inset=false, tex_rot=0,
    tex_scale, tex_depth, tex_samples, h, l, length, 
    anchor, spin=0, orient=UP
) =
    assert(num_defined([tex_reps,tex_counts])<2, "In linear_sweep() the 'tex_counts' parameter has been replaced by 'tex_reps'.  You cannot give both.")
    assert(num_defined([tex_scale,tex_depth])<2, "In linear_sweep() the 'tex_scale' parameter has been replaced by 'tex_depth'.  You cannot give both.")
    let(
        region = force_region(region),
        tex_reps = is_def(tex_counts)? echo("In linear_sweep() the 'tex_counts' parameter is deprecated and has been replaced by 'tex_reps'")tex_counts
                 : tex_reps,
        tex_depth = is_def(tex_scale)? echo("In linear_sweep() the 'tex_scale' parameter is deprecated and has been replaced by 'tex_depth'")tex_scale
                  : default(tex_depth,1)
    )
    assert(is_region(region), "Input is not a region or polygon.")
    assert(is_num(scale) || is_vector(scale))
    assert(is_vector(shift, 2), str(shift))
    assert(is_bool(caps) || is_bool_list(caps,2), "caps must be boolean or a list of two booleans")
    let(
        h = one_defined([h, height,l,length],"h,height,l,length",dflt=1)
    )
    !is_undef(texture)? _textured_linear_sweep(
        region, h=h, caps=caps, 
        texture=texture, tex_size=tex_size,
        counts=tex_reps, inset=tex_inset,
        rot=tex_rot, tex_scale=tex_depth,
        twist=twist, scale=scale, shift=shift,
        style=style, samples=tex_samples,
        anchor=anchor, spin=spin, orient=orient
    ) :
    let(
        caps = is_bool(caps) ? [caps,caps] : caps, 
        anchor = center==true? "origin" :
            center == false? "original_base" :
            default(anchor, "original_base"),
        regions = region_parts(region),
        slices = default(slices, max(1,ceil(abs(twist)/5))),
        scale = is_num(scale)? [scale,scale] : point2d(scale),
        topmat = move(shift) * scale(scale) * rot(-twist),
        trgns = [
            for (rgn = regions) [
                for (path = rgn) let(
                    p = list_unwrap(path),
                    path = is_undef(maxseg)? p : [
                        for (seg = pair(p,true)) each
                        let( steps = ceil(norm(seg.y - seg.x) / maxseg) )
                        lerpn(seg.x, seg.y, steps, false)
                    ]
                ) apply(topmat, path)
            ]
        ],
        vnf = vnf_join([
            for (rgn = regions)
            for (pathnum = idx(rgn)) let(
                p = list_unwrap(rgn[pathnum]),
                path = is_undef(maxseg)? p : [
                    for (seg=pair(p,true)) each
                    let(steps=ceil(norm(seg.y-seg.x)/maxseg))
                    lerpn(seg.x, seg.y, steps, false)
                ],
                verts = [
                    for (i=[0:1:slices]) let(
                        u = i / slices,
                        scl = lerp([1,1], scale, u),
                        ang = lerp(0, -twist, u),
                        off = lerp([0,0,-h/2], point3d(shift,h/2), u),
                        m = move(off) * scale(scl) * rot(ang)
                    ) apply(m, path3d(path))
                ]
            ) vnf_vertex_array(verts, caps=false, col_wrap=true, style=style),
            if (caps[0]) for (rgn = regions) vnf_from_region(rgn, down(h/2), reverse=true),
            if (caps[1]) for (rgn = trgns) vnf_from_region(rgn, up(h/2), reverse=false)
        ]),
        anchors = [
            named_anchor("original_base", [0,0,-h/2], UP)
        ],
        cp = default(cp, "centroid"),
        geom = atype=="hull"?  attach_geom(cp=cp, region=region, h=h, extent=true, shift=shift, scale=scale, twist=twist, anchors=anchors) :
            atype=="intersect"?  attach_geom(cp=cp, region=region, h=h, extent=false, shift=shift, scale=scale, twist=twist, anchors=anchors) :
            atype=="bbox"?
                let(
                    bounds = pointlist_bounds(flatten(region)),
                    size = bounds[1] - bounds[0],
                    midpt = (bounds[0] + bounds[1])/2
                )
                attach_geom(cp=[0,0,0], size=point3d(size,h), offset=point3d(midpt), shift=shift, scale=scale, twist=twist, anchors=anchors) :
            assert(in_list(atype, ["hull","intersect","bbox"]), "Anchor type must be \"hull\", \"intersect\", or \"bbox\".")
    ) reorient(anchor,spin,orient, geom=geom, p=vnf);


// Function&Module: rotate_sweep()
// Synopsis: Create a surface of revolution from a path with optional texturing. 
// SynTags: VNF, Geom
// Topics: Extrusion, Sweep, Revolution, Textures
// See Also: linear_sweep(), sweep(), spiral_sweep(), path_sweep(), offset_sweep()
// Usage: As Function
//   vnf = rotate_sweep(shape, [angle], ...);
// Usage: As Module
//   rotate_sweep(shape, [angle], ...) [ATTACHMENTS];
// Usage: With Texturing
//   rotate_sweep(shape, texture=, [tex_size=]|[tex_reps=], [tex_depth=], [tex_samples=], [tex_rot=], [tex_inset=], ...) [ATTACHMENTS];
// Description:
//   Takes a polygon or [region](regions.scad) and sweeps it in a rotation around the Z axis, with optional texturing.
//   When called as a function, returns a [VNF](vnf.scad).
//   When called as a module, creates the sweep as geometry.
// Arguments:
//   shape = The polygon or [region](regions.scad) to sweep around the Z axis.
//   angle = If given, specifies the number of degrees to sweep the shape around the Z axis, counterclockwise from the X+ axis.  Default: 360 (full rotation)
//   ---
//   texture = A texture name string, or a rectangular array of scalar height values (0.0 to 1.0), or a VNF tile that defines the texture to apply to vertical surfaces.  See {{texture()}} for what named textures are supported.
//   tex_size = An optional 2D target size for the textures.  Actual texture sizes will be scaled somewhat to evenly fit the available surface. Default: `[5,5]`
//   tex_reps = If given instead of tex_size, a 2-vector giving the number of texture tile repetitions in the direction perpendicular to extrusion and in the direction parallel to extrusion.  
//   tex_inset = If numeric, lowers the texture into the surface by the specified proportion, e.g. 0.5 would lower it half way into the surface.  If `true`, insets by exactly its full depth.  Default: `false`
//   tex_rot = Rotate texture by specified angle, which must be a multiple of 90 degrees.  Default: 0
//   tex_depth = Specify texture depth; if negative, invert the texture.  Default: 1.
//   tex_samples = Minimum number of "bend points" to have in VNF texture tiles.  Default: 8
//   tex_taper = If given as a number, tapers the texture height to zero over the first and last given percentage of the path.  If given as a lookup table with indices between 0 and 100, uses the percentage lookup table to ramp the texture heights.  Default: `undef` (no taper)
//   style = {{vnf_vertex_array()}} style.  Default: "min_edge"
//   closed = If false, and shape is given as a path, then the revolved path will be sealed to the axis of rotation with untextured caps.  Default: `true`
//   convexity = (Module only) Convexity setting for use with polyhedron.  Default: 10
//   cp = Centerpoint for determining "intersect" anchors or centering the shape.  Determintes the base of the anchor vector.  Can be "centroid", "mean", "box" or a 3D point.  Default: "centroid"
//   atype = Select "hull" or "intersect" anchor types.  Default: "hull"
//   anchor = Translate so anchor point is at the origin. Default: "origin"
//   spin = Rotate this many degrees around Z axis after anchor. Default: 0
//   orient = Vector to rotate top towards after spin  (module only)
// Named Anchors:
//   "origin" = The native position of the shape.  
// Anchor Types:
//   "hull" = Anchors to the virtual convex hull of the shape.
//   "intersect" = Anchors to the surface of the shape.
// Example:
//   rgn = [
//       for (a = [0, 120, 240]) let(
//           cp = polar_to_xy(15, a) + [30,0]
//       ) each [
//           move(cp, p=circle(r=10)),
//           move(cp, p=hexagon(d=15)),
//       ]
//   ];
//   rotate_sweep(rgn, angle=240);
// Example:
//   rgn = right(30, p=union([for (a = [0, 90]) rot(a, p=rect([15,5]))]));
//   rotate_sweep(rgn);
// Example:
//   path = right(50, p=circle(d=40));
//   rotate_sweep(path, texture="bricks_vnf", tex_size=[10,10], tex_depth=0.5, style="concave");
// Example:
//   tex = [
//       [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
//       [0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1],
//       [0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1],
//       [0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1],
//       [0, 0, 1, 0, 0, 1, 1, 1, 0, 0, 1],
//       [0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1],
//       [0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1],
//       [0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 1],
//       [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
//       [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
//       [0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1],
//       [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
//   ];
//   path = arc(cp=[0,0], r=40, start=60, angle=-120);
//   rotate_sweep(
//       path, closed=false,
//       texture=tex, tex_size=[20,20],
//       tex_depth=1, style="concave");
// Example:
//   include <BOSL2/beziers.scad>
//   bezpath = [
//       [15, 30], [10,15],
//       [10,  0], [20, 10], [30,12],
//       [30,-12], [20,-10], [10, 0],
//       [10,-15], [15,-30]
//   ];
//   path = bezpath_curve(bezpath, splinesteps=32);
//   rotate_sweep(
//       path, closed=false,
//       texture="diamonds", tex_size=[10,10],
//       tex_depth=1, style="concave");
// Example:
//   path = [
//       [20, 30], [20, 20],
//       each arc(r=20, corner=[[20,20],[10,0],[20,-20]]),
//       [20,-20], [20,-30],
//   ];
//   vnf = rotate_sweep(
//       path, closed=false,
//       texture="trunc_pyramids",
//       tex_size=[5,5], tex_depth=1,
//       style="convex");
//   vnf_polyhedron(vnf, convexity=10);
// Example:
//   rgn = [
//       right(40, p=circle(d=50)),
//       right(40, p=circle(d=40,$fn=6)),
//   ];
//   rotate_sweep(
//       rgn, texture="diamonds",
//       tex_size=[10,10], tex_depth=1,
//       angle=240, style="concave");
// Example: Tapering off the ends of the texturing.
//   path = [
//       [20, 30], [20, 20],
//       each arc(r=20, corner=[[20,20],[10,0],[20,-20]]),
//       [20,-20], [20,-30],
//   ];
//   rotate_sweep(
//       path, closed=false,
//       texture="trunc_pyramids",
//       tex_size=[5,5], tex_depth=1,
//       tex_taper=20,
//       style="convex",
//       convexity=10);
// Example: Tapering of textures via lookup table.
//   path = [
//       [20, 30], [20, 20],
//       each arc(r=20, corner=[[20,20],[10,0],[20,-20]]),
//       [20,-20], [20,-30],
//   ];
//   rotate_sweep(
//       path, closed=false,
//       texture="trunc_pyramids",
//       tex_size=[5,5], tex_depth=1,
//       tex_taper=[[0,0], [10,0], [10.1,1], [100,1]],
//       style="convex",
//       convexity=10);

function rotate_sweep(
    shape, angle=360,
    texture, tex_size=[5,5], tex_counts, tex_reps, 
    tex_inset=false, tex_rot=0,
    tex_scale, tex_depth, tex_samples,
    tex_taper, shift=[0,0], closed=true,
    style="min_edge", cp="centroid",
    atype="hull", anchor="origin",
    spin=0, orient=UP,
    _tex_inhibit_y_slicing=false
) =
    assert(num_defined([tex_reps,tex_counts])<2, "In rotate_sweep() the 'tex_counts' parameters has been replaced by 'tex_reps'.  You cannot give both.")
    assert(num_defined([tex_scale,tex_depth])<2, "In linear_sweep() the 'tex_scale' parameter has been replaced by 'tex_depth'.  You cannot give both.")
    let( region = force_region(shape),
         tex_reps = is_def(tex_counts)? echo("In rotate_sweep() the 'tex_counts' parameter is deprecated and has been replaced by 'tex_reps'")tex_counts
                  : tex_reps,
        tex_depth = is_def(tex_scale)? echo("In rotate_sweep() the 'tex_scale' parameter is deprecated and has been replaced by 'tex_depth'")tex_scale
                  : default(tex_depth,1)
    )
    assert(is_region(region), "Input is not a region or polygon.")
    let(
        bounds = pointlist_bounds(flatten(region)),
        min_x = bounds[0].x,
        max_x = bounds[1].x,
        min_y = bounds[0].y,
        max_y = bounds[1].y,
        h = max_y - min_y
    )
    assert(min_x>=0, "Input region must exist entirely in the X+ half-plane.")
    !is_undef(texture)? _textured_revolution(
        shape,
        texture=texture,
        tex_size=tex_size,
        counts=tex_reps,
        tex_scale=tex_depth,
        inset=tex_inset,
        rot=tex_rot,
        samples=tex_samples,
        inhibit_y_slicing=_tex_inhibit_y_slicing,
        taper=tex_taper,
        shift=shift,
        closed=closed,
        angle=angle,
        style=style
    ) :
    let(
        steps = ceil(segs(max_x) * angle / 360) + (angle<360? 1 : 0),
        skmat = down(min_y) * skew(sxz=shift.x/h, syz=shift.y/h) * up(min_y),
        transforms = [
            if (angle==360) for (i=[0:1:steps-1]) skmat * rot([90,0,360-i*360/steps]),
            if (angle<360) for (i=[0:1:steps-1]) skmat * rot([90,0,angle-i*angle/(steps-1)]),
        ],
        vnf = sweep(
            region, transforms,
            closed=angle==360,
            caps=angle!=360,
            style=style, cp=cp,
            atype=atype, anchor=anchor,
            spin=spin, orient=orient
        )
    ) vnf;


module rotate_sweep(
    shape, angle=360,
    texture, tex_size=[5,5], tex_counts, tex_reps,
    tex_inset=false, tex_rot=0,
    tex_scale, tex_depth, tex_samples,
    tex_taper, shift=[0,0],
    style="min_edge",
    closed=true,
    cp="centroid",
    convexity=10,
    atype="hull",
    anchor="origin",
    spin=0,
    orient=UP,
    _tex_inhibit_y_slicing=false
) {
    dummy =
       assert(num_defined([tex_reps,tex_counts])<2, "In rotate_sweep() the 'tex_counts' parameters has been replaced by 'tex_reps'.  You cannot give both.")
       assert(num_defined([tex_scale,tex_depth])<2, "In rotate_sweep() the 'tex_scale' parameter has been replaced by 'tex_depth'.  You cannot give both.");
    tex_reps = is_def(tex_counts)? echo("In rotate_sweep() the 'tex_counts' parameter is deprecated and has been replaced by 'tex_reps'")tex_counts
             : tex_reps;
    tex_depth = is_def(tex_scale)? echo("In rotate_sweep() the 'tex_scale' parameter is deprecated and has been replaced by 'tex_depth'")tex_scale
              : default(tex_depth,1);
    region = force_region(shape);
    check = assert(is_region(region), "Input is not a region or polygon.");
    bounds = pointlist_bounds(flatten(region));
    min_x = bounds[0].x;
    max_x = bounds[1].x;
    min_y = bounds[0].y;
    max_y = bounds[1].y;
    h = max_y - min_y;
    check2 = assert(min_x>=0, "Input region must exist entirely in the X+ half-plane.");
    if (!is_undef(texture)) {
        _textured_revolution(
            shape,
            texture=texture,
            tex_size=tex_size,
            counts=tex_reps,
            tex_scale=tex_depth,
            inset=tex_inset,
            rot=tex_rot,
            samples=tex_samples,
            taper=tex_taper,
            shift=shift,
            closed=closed,
            inhibit_y_slicing=_tex_inhibit_y_slicing,
            angle=angle,
            style=style,
            atype=atype, anchor=anchor,
            spin=spin, orient=orient
        ) children();
    } else {
        steps = ceil(segs(max_x) * angle / 360) + (angle<360? 1 : 0);
        skmat = down(min_y) * skew(sxz=shift.x/h, syz=shift.y/h) * up(min_y);
        transforms = [
            if (angle==360) for (i=[0:1:steps-1]) skmat * rot([90,0,360-i*360/steps]),
            if (angle<360) for (i=[0:1:steps-1]) skmat * rot([90,0,angle-i*angle/(steps-1)]),
        ];
        sweep(
            region, transforms,
            closed=angle==360,
            caps=angle!=360,
            style=style, cp=cp,
            convexity=convexity,
            atype=atype, anchor=anchor,
            spin=spin, orient=orient
        ) children();
    }
}


// Function&Module: spiral_sweep()
// Synopsis: Sweep a path along a helix.
// SynTags: VNF, Geom
// Topics: Extrusion, Sweep, Spiral
// See Also: thread_helix(), linear_sweep(), rotate_sweep(), sweep(), path_sweep(), offset_sweep()
// Usage: As Module
//   spiral_sweep(poly, h, r|d=, turns, [taper=], [center=], [taper1=], [taper2=], [internal=], ...)[ATTACHMENTS];
//   spiral_sweep(poly, h, r1=|d1=, r2=|d2=, turns, [taper=], [center=], [taper1=], [taper2=], [internal=], ...)[ATTACHMENTS];
// Usage: As Function
//   vnf = spiral_sweep(poly, h, r|d=, turns, ...);
//   vnf = spiral_sweep(poly, h, r1=|d1=, r1=|d2=, turns, ...);
// Description:
//   Takes a closed 2D polygon path, centered on the XY plane, and sweeps/extrudes it along a 3D spiral path
//   of a given radius, height and degrees of rotation.  The origin in the profile traces out the helix of the specified radius.
//   If turns is positive the path will be right-handed;  if turns is negative the path will be left-handed.
//   Such an extrusion can be used to make screw threads.  
//   .
//   The lead_in options specify a lead-in section where the ends of the spiral scale down to avoid a sharp cut face at the ends.
//   You can specify the length of this scaling directly with the lead_in parameters or as an angle using the lead_in_ang parameters.
//   If you give a positive value, the extrusion is lengthenend by the specified distance or angle; if you give a negative
//   value then the scaled end is included in the extrusion length specified by `turns`.  If the value is zero then no scaled ends
//   are produced.  The shape of the scaled ends can be controlled with the lead_in_shape parameter.  Supported options are "sqrt", "linear"
//   "smooth" and "cut".  
//   .
//   The inside argument changes how the extrusion lead-in sections are formed.  If it is true then they scale
//   towards the outside, like would be needed for internal threading.  If internal is fale then the lead-in sections scale
//   towards the inside, like would be appropriate for external threads.  
// Arguments:
//   poly = Array of points of a polygon path, to be extruded.
//   h = height of the spiral extrusion path
//   r = Radius of the spiral extrusion path
//   turns = number of revolutions to include in the spiral
//   ---
//   d = Diameter of the spiral extrusion path.
//   d1/r1 = Bottom inside diameter or radius of spiral to extrude along.
//   d2/r2 = Top inside diameter or radius of spiral to extrude along.
//   lead_in = Specify linear length of the lead-in scaled section of the spiral.  Default: 0
//   lead_in1 = Specify linear length of the lead-in scaled section of the spiral at the bottom
//   lead_in2 = Specify linear length of the lead-in scaled section of the spiral at the top
//   lead_in_ang = Specify angular  length of the lead-in scaled section of the spiral
//   lead_in_ang1 = Specify angular length of the lead-in scaled section of the spiral at the bottom
//   lead_in_ang2 = Specify angular length of the lead-in scaled section of the spiral at the top
//   lead_in_shape = Specify the shape of the thread lead in by giving a text string or function.  Default: "sqrt"
//   lead_in_shape1 = Specify the shape of the thread lead-in at the bottom by giving a text string or function.  
//   lead_in_shape2 = Specify the shape of the thread lead-in at the top by giving a text string or function.
//   lead_in_sample = Factor to increase sample rate in the lead-in section.  Default: 10
//   internal = if true make internal threads.  The only effect this has is to change how the extrusion lead-in section are formed. When true, the extrusion scales towards the outside; when false, it scales towards the inside.  Default: false
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Example:
//   poly = [[-10,0], [-3,-5], [3,-5], [10,0], [0,-30]];
//   spiral_sweep(poly, h=200, r=50, turns=3, $fn=36);
_leadin_ogive=function (x,L) 
     let( minscale = .05,
          r=(L^2+(1-minscale^2))/2/(1-minscale),
          scale = sqrt(r^2-(L*(1-x))^2) -(r-1)
     )
     x>1 ? [1,1]
   : x<0 ? [lerp(minscale,1,.25),0] 
   : [lerp(scale,1,.25),scale];     

_leadin_cut = function(x,L) x>0 ? [1,1] : [1,0];

_leadin_sqrt = function(x,L)
     let(end=0.05)   // Smallest scale at the end
     x>1 ? [1,1]
   : x<0 ? [lerp(end,1,.25),0]   
   : let(  
          s = sqrt(x + end^2 * (1-x))
     )
     [lerp(s,1,.25),s];    // thread width scale, thread height scale

_leadin_linear = function(x,L)
     let(minscale=.1)
     x>1 ? [1,1]
   : x<0 ? [lerp(minscale,1,.25),0]
   : let(scale = lerp(minscale,1,x))
     [lerp(scale,1,.25),scale];

_lead_in_table = [
     ["default", _leadin_sqrt],
     ["sqrt", _leadin_sqrt],
     ["cut", _leadin_cut],
     ["smooth", _leadin_ogive],
     ["linear", _leadin_linear]
];

      
function _ss_polygon_r(N,theta) =
        let( alpha = 360/N )
        cos(alpha/2)/(cos(posmod(theta,alpha)-alpha/2));
function spiral_sweep(poly, h, r, turns=1, taper, r1, r2, d, d1, d2, internal=false,
                      lead_in_shape,lead_in_shape1, lead_in_shape2,
                      lead_in, lead_in1, lead_in2,
                      lead_in_ang, lead_in_ang1, lead_in_ang2,
                      height,l,length,
                      lead_in_sample = 10,
                      anchor=CENTER, spin=0, orient=UP) =
    assert(is_num(turns) && turns != 0, "turns must be a nonzero number")
    assert(all_positive([h]), "Spiral height must be a positive number")
    let(
        dir = sign(turns),
        r1 = get_radius(r1=r1, r=r, d1=d1, d=d),
        r2 = get_radius(r1=r2, r=r, d1=d2, d=d),
        bounds = pointlist_bounds(poly),
        yctr = (bounds[0].y+bounds[1].y)/2,
        xmin = bounds[0].x,
        xmax = bounds[1].x,
        poly = path3d(clockwise_polygon(poly)),
        sides = segs(max(r1,r2)),
        ang_step = 360/sides,
        turns = abs(turns),
        lead_in1 = first_defined([lead_in1, lead_in]),
        lead_in2 = first_defined([lead_in2, lead_in]),
        lead_in_ang1 =
                      let(
                           user_ang = first_defined([lead_in_ang1,lead_in_ang])
                      )
                      assert(is_undef(user_ang) || is_undef(lead_in1), "Cannot define lead_in/lead_in1 by both length and angle")
                      is_def(user_ang) ? user_ang : default(lead_in1,0)*360/(2*PI*r1),
        lead_in_ang2 =
                      let(
                           user_ang = first_defined([lead_in_ang2,lead_in_ang])
                      )
                      assert(is_undef(user_ang) || is_undef(lead_in2), "Cannot define lead_in/lead_in2 by both length and angle")
                      is_def(user_ang) ? user_ang : default(lead_in2,0)*360/(2*PI*r2),
        minang = -max(0,lead_in_ang1),
        maxang = 360*turns + max(0,lead_in_ang2),
        cut_ang1 = minang+abs(lead_in_ang1),
        cut_ang2 = maxang-abs(lead_in_ang2),        
        lead_in_shape1 = first_defined([lead_in_shape1, lead_in_shape, "default"]),
        lead_in_shape2 = first_defined([lead_in_shape2, lead_in_shape, "default"]),             
        lead_in_func1 = is_func(lead_in_shape1) ? lead_in_shape1
                      : assert(is_string(lead_in_shape1),"lead_in_shape/lead_in_shape1 must be a function or string")
                        let(ind = search([lead_in_shape1], _lead_in_table,0)[0])
                        assert(ind!=[],str("Unknown lead_in_shape, \"",lead_in_shape1,"\""))
                        _lead_in_table[ind[0]][1],
        lead_in_func2 = is_func(lead_in_shape2) ? lead_in_shape2
                      : assert(is_string(lead_in_shape2),"lead_in_shape/lead_in_shape2 must be a function or string")
                        let(ind = search([lead_in_shape2], _lead_in_table,0)[0])
                        assert(ind!=[],str("Unknown lead_in_shape, \"",lead_in_shape2,"\""))
                        _lead_in_table[ind[0]][1]
    )
    assert( cut_ang1<cut_ang2, "Tapers are too long to fit")
    assert( all_positive([r1,r2]), "Diameter/radius must be positive")
    let(
  
        // This complicated sampling scheme is designed to ensure that faceting always starts at angle zero
        // for alignment with cylinders, and there is always a facet boundary at the $fn specified locations, 
        // regardless of what kind of subsampling occurs for tapers.
        orig_anglist = [
            if (minang<0) minang,
            each reverse([for(ang = [-ang_step:-ang_step:minang+EPSILON]) ang]),
            for(ang = [0:ang_step:maxang-EPSILON]) ang,
            maxang
        ],
        anglist = [
           for(a=orig_anglist) if (a<cut_ang1-EPSILON) a,
           cut_ang1,
           for(a=orig_anglist) if (a>cut_ang1+EPSILON && a<cut_ang2-EPSILON) a,
           cut_ang2,
           for(a=orig_anglist) if (a>cut_ang2+EPSILON) a
        ],
        interp_ang = [
                      for(i=idx(anglist,e=-2)) 
                          each lerpn(anglist[i],anglist[i+1],
                                         (lead_in_ang1!=0 && anglist[i+1]<=cut_ang1) || (lead_in_ang2!=0 && anglist[i]>=cut_ang2)
                                            ? ceil((anglist[i+1]-anglist[i])/ang_step*lead_in_sample)
                                            : 1,
                                     endpoint=false),
                      last(anglist)
                     ],
        skewmat = affine3d_skew_xz(xa=atan2(r2-r1,h)),
        points = [
            for (a = interp_ang) let (
                hsc = a<cut_ang1 ? lead_in_func1((a-minang)/abs(lead_in_ang1),abs(lead_in_ang1)*2*PI*r1/360)
                    : a>cut_ang2 ? lead_in_func2((maxang-a)/abs(lead_in_ang2),abs(lead_in_ang2)*2*PI*r2/360)
                    : [1,1],
                u = a/(360*turns), 
                r = lerp(r1,r2,u),
                mat = affine3d_zrot(dir*a)
                    * affine3d_translate([_ss_polygon_r(sides,dir*a)*r, 0, h * (u-0.5)])
                    * affine3d_xrot(90)
                    * skewmat
                    * scale([hsc.y,hsc.x,1], cp=[internal ? xmax : xmin, yctr, 0]),
                pts = apply(mat, poly)
            ) pts
        ],
        vnf = vnf_vertex_array(
            points, col_wrap=true, caps=true, reverse=dir>0,
        //    style=higbee1>0 || higbee2>0 ? "quincunx" : "alt"
            style="convex"
        ),
        vnf2 = vnf_triangulate(vnf)
    )
    reorient(anchor,spin,orient, vnf=vnf2, r1=r1, r2=r2, l=h, p=vnf2);



module spiral_sweep(poly, h, r, turns=1, taper, r1, r2, d, d1, d2, internal=false,
                    lead_in_shape,lead_in_shape1, lead_in_shape2,
                    lead_in, lead_in1, lead_in2,
                    lead_in_ang, lead_in_ang1, lead_in_ang2,
                    height,l,length,
                    lead_in_sample=10,
                    anchor=CENTER, spin=0, orient=UP)
{
    vnf = spiral_sweep(poly=poly, h=h, r=r, turns=turns, r1=r1, r2=r2, d=d, d1=d1, d2=d2, internal=internal,
                       lead_in_shape=lead_in_shape,lead_in_shape1=lead_in_shape1, lead_in_shape2=lead_in_shape2,
                       lead_in=lead_in, lead_in1=lead_in1, lead_in2=lead_in2,
                       lead_in_ang=lead_in_ang, lead_in_ang1=lead_in_ang1, lead_in_ang2=lead_in_ang2,
                       height=height,l=length,length=length,
                       lead_in_sample=lead_in_sample);
    h = one_defined([h,height,length,l],"h,height,length,l");
    r1 = get_radius(r1=r1, r=r, d1=d1, d=d);
    r2 = get_radius(r1=r2, r=r, d1=d2, d=d);
    lead_in1 = u_mul(first_defined([lead_in1,lead_in]),1/(2*PI*r1));
    lead_in2 = u_mul(first_defined([lead_in2,lead_in]),1/(2*PI*r2));
    lead_in_ang1 = first_defined([lead_in_ang1,lead_in_ang]);
    lead_in_ang2 = first_defined([lead_in_ang2,lead_in_ang]);
    extra_turns = max(0,first_defined([lead_in1,lead_in_ang1,0]))+max(0,first_defined([lead_in2,lead_in_ang2,0]));
    attachable(anchor,spin,orient, r1=r1, r2=r2, l=h) {
        vnf_polyhedron(vnf, convexity=ceil(2*(abs(turns)+extra_turns)));
        children();
    }
}



// Function&Module: path_sweep()
// Synopsis: Sweep a 2d polygon path along a 2d or 3d path. 
// SynTags: VNF, Geom
// Topics: Extrusion, Sweep, Paths
// See Also: sweep_attach(), linear_sweep(), rotate_sweep(), sweep(), spiral_sweep(), path_sweep2d(), offset_sweep()
// Usage: As module
//   path_sweep(shape, path, [method], [normal=], [closed=], [twist=], [twist_by_length=], [symmetry=], [scale=], [scale_by_length=], [last_normal=], [tangent=], [uniform=], [relaxed=], [caps=], [style=], [convexity=], [anchor=], [cp=], [spin=], [orient=], [atype=]) [ATTACHMENTS];
// Usage: As function
//   vnf = path_sweep(shape, path, [method], [normal=], [closed=], [twist=], [twist_by_length=], [symmetry=], [scale=], [scale_by_length=], [last_normal=], [tangent=], [uniform=], [relaxed=], [caps=], [style=], [transforms=], [anchor=], [cp=], [spin=], [orient=], [atype=]);
// Description:
//   Takes as input `shape`, a 2D polygon path (list of points), and `path`, a 2d or 3d path (also a list of points)
//   and constructs a polyhedron by sweeping the shape along the path. When run as a module returns the polyhedron geometry.
//   When run as a function returns a VNF by default or if you set `transforms=true` then it returns a list of transformations suitable as input to `sweep`.
//   .
//   The sweeping process places one copy of the shape for each point in the path.  The origin in `shape` is translated to
//   the point in `path`.  The normal vector of the shape, which points in the Z direction, is aligned with the tangent
//   vector for the path, so this process is constructing a shape whose normal cross sections are equal to your specified shape.
//   If you do not supply a list of tangent vectors then an approximate tangent vector is computed
//   based on the path points you supply using {{path_tangents()}}.
// Figure(3D,Big,VPR=[70,0,345],VPD=20,VPT=[5.5,10.8,-2.7],NoScales): This example shows how the shape, in this case the quadrilateral defined by `[[0, 0], [0, 1], [0.25, 1], [1, 0]]`, appears as the cross section of the swept polyhedron.  The blue line shows the path.  The normal vector to the shape is shown in black; it is based at the origin and points upwards in the Z direction.  The sweep aligns this normal vector with the blue path tangent, which in this case, flips the shape around.  Note that for a 2D path like this one, the Y direction in the shape is mapped to the Z direction in the sweep.
//   tri= [[0, 0], [0, 1], [.25,1], [1, 0]];
//   path = arc(r=5,n=81,angle=[-20,65]);
//   % path_sweep(tri,path);
//   T = path_sweep(tri,path,transforms=true);
//   color("red")for(i=[0:20:80]) stroke(apply(T[i],path3d(tri)),width=.1,closed=true);
//   color("blue")stroke(path3d(arc(r=5,n=101,angle=[-20,80])),width=.1,endcap2="arrow2");
//   color("red")stroke([path3d(tri)],width=.1);
//   stroke([CENTER,UP], width=.07,endcap2="arrow2",color="black");
// Continues:
//   In the figure you can see that the swept polyhedron, shown in transparent gray, has the quadrilateral as its cross
//   section.  The quadrilateral is positioned perpendicular to the path, which is shown in blue, so that the normal
//   vector for the quadrilateral is parallel to the tangent vector for the path.  The origin for the shape is the point
//   which follows the path.  For a 2D path, the Y axis of the shape is mapped to the Z axis and in this case,
//   pointing the quadrilateral's normal vector (in black) along the tangent line of
//   the path, which is going in the direction of the blue arrow, requires that the quadrilateral be "turned around".  If we
//   reverse the order of points in the path we get a different result:
// Figure(3D,Big,VPR=[70,0,20],VPD=20,VPT=[1.25,9.25,-2.65],NoScales): The same sweep operation with the path traveling in the opposite direction.  Note that in order to line up the normal correctly, the shape is reversed compared to Figure 1, so the resulting sweep looks quite different.
//   tri= [[0, 0], [0, 1], [.25,1], [1, 0]];
//   path = reverse(arc(r=5,n=81,angle=[-20,65]));
//   % path_sweep(tri,path);
//   T = path_sweep(tri,path,transforms=true);
//   color("red")for(i=[0:20:80]) stroke(apply(T[i],path3d(tri)),width=.1,closed=true);
//   color("blue")stroke(reverse(path3d(arc(r=5,n=101,angle=[-20-15,65]))),width=.1,endcap2="arrow2");
//   color("red")stroke([path3d(tri)],width=.1);
//   stroke([CENTER,UP], width=.07,endcap2="arrow2",color="black");
// Continues:
//   If your shape is too large for the curves in the path you can create a situation where the shapes cross each
//   other.  This results in an invalid polyhedron, which may appear OK when previewed or rendered alone, but will give rise
//   to cryptic CGAL errors when rendered with a second object in your model.  You may be able to use {{path_sweep2d()}}
//   to produce a valid model in cases like this.  You can debug models like this using the `profiles=true` option which will show all
//   the cross sections in your polyhedron.  If any of them intersect, the polyhedron will be invalid.
// Figure(3D,Big,VPR=[47,0,325],VPD=23,VPT=[6.8,4,-3.8],NoScales): We have scaled the path to an ellipse and show a large triangle as the shape.  The triangle is sometimes bigger than the local radius of the path, leading to an invalid polyhedron, which you can identify because the red lines cross in the middle.
//   tri= scale([4.5,2.5],[[0, 0], [0, 1], [1, 0]]);
//   path = xscale(1.5,arc(r=5,n=81,angle=[-70,70]));
//   % path_sweep(tri,path);
//   T = path_sweep(tri,path,transforms=true);
//   color("red")for(i=[0:20:80]) stroke(apply(T[i],path3d(tri)),width=.1,closed=true);
//   color("blue")stroke(path3d(xscale(1.5,arc(r=5,n=81,angle=[-70,80]))),width=.1,endcap2="arrow2");
// Continues:
//   During the sweep operation the shape's normal vector aligns with the tangent vector of the path.  Note that
//   this leaves an ambiguity about how the shape is rotated as it sweeps along the path.
//   For 2D paths, this ambiguity is resolved by aligning the Y axis of the shape to the Z axis of the swept polyhedron.
//   You can force the  shape to twist as it sweeps along the path using the `twist` parameter, which specifies the total
//   number of degrees to twist along the whole swept polyhedron.  This produces a result like the one shown below.
// Figure(3D,Big,VPR=[66,0,14],VPD=20,VPT=[3.4,4.5,-0.8]): The shape twists as we sweep.  Note that it still aligns the origin in the shape with the path, and still aligns the normal vector with the path tangent vector.
//   tri= [[0, 0], [0, 1], [.25,1],[1, 0]];
//   path = arc(r=5,n=81,angle=[-20,65]);
//   % path_sweep(tri,path,twist=-60);
//   T = path_sweep(tri,path,transforms=true,twist=-60);
//   color("red")for(i=[0:20:80]) stroke(apply(T[i],path3d(tri)),width=.1,closed=true);
//   color("blue")stroke(path3d(arc(r=5,n=101,angle=[-20,80])),width=.1,endcap2="arrow2");
// Continues:
//   The `twist` argument adds the specified number of degrees of twist into the model, and it may be positive or
//   negative.  When `closed=true` the starting shape and ending shape must match to avoid a sudden extreme twist at the
//   joint.  By default `twist` is therefore required to be a multiple of 360.  However, if your shape has rotational
//   symmetry, this requirement is overly strict.  You can specify the symmetry using the `symmetry` argument, and then
//   you can choose smaller twists consistent with the specified symmetry.  The symmetry argument gives the number of
//   rotations that map the shape exactly onto itself, so a pentagon has 5-fold symmetry.  This argument is only valid
//   for closed sweeps.  When you specify symmetry, the twist must be a multiple of 360/symmetry.
//   .
//   The twist is normally spread uniformly along your shape based on the path length.  If you set `twist_by_length` to
//   false then the twist will be uniform based on the point count of your path.  Twisted shapes will produce twisted
//   faces, so if you want them to look good you should use lots of points on your path and also lots of points on the
//   shape.  If your shape is a simple polygon, use {{subdivide_path()}} to increase
//   the number of points.
//   .
//   As noted above, the sweep process has an ambiguity regarding the twist.  For 2D paths it is easy to resolve this
//   ambiguity by aligning the Y axis in the shape to the Z axis in the swept polyhedron.  When the path is
//   three-dimensional, things become more complex.  It is no longer possible to use a simple alignment rule like the
//   one we use in 2D.  You may find that the shape rotates unexpectedly around its axis as it traverses the path.  The
//   `method` parameter allows you to specify how the shapes are aligned, resulting in different twist in the resulting
//   polyhedron.  You can choose from three different methods for selecting the rotation of your shape.  None of these
//   methods will produce good, or even valid, results on all inputs, so it is important to select a suitable method.
//   .
//   The three methods you can choose using the `method` parameter are:
//   .
//   The "incremental" method (the default) works by adjusting the shape at each step by the minimal rotation that makes the shape normal to the tangent
//   at the next point.  This method is robust in that it always produces a valid result for well-behaved paths with sufficiently high
//   sampling.  Unfortunately, it can produce a large amount of undesirable twist.  When constructing a closed shape this algorithm in
//   its basic form provides no guarantee that the start and end shapes match up.  To prevent a sudden twist at the last segment,
//   the method calculates the required twist for a good match and distributes it over the whole model (as if you had specified a
//   twist amount).  If you specify `symmetry` this may allow the algorithm to choose a smaller twist for this alignment.
//   To start the algorithm, we need an initial condition.  This is supplied by
//   using the `normal` argument to give a direction to align the Y axis of your shape.  By default the normal points UP if the path
//   makes an angle of 45 deg or less with the xy plane and it points BACK if the path makes a higher angle with the XY plane.  You
//   can also supply `last_normal` which provides an ending orientation constraint.  Be aware that the curve may still exhibit
//   twisting in the middle.  This method is the default because it is the most robust, not because it generally produces the best result.
//   .
//   The "natural" method works by computing the Frenet frame at each point on the path.  This is defined by the tangent to the curve and
//   the normal which lies in the plane defined by the curve at each point.  This normal points in the direction of curvature of the curve.
//   The result is a very well behaved set of shape positions without any unexpected twisting&mdash;as long as the curvature never falls to zero.  At a
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
//   You can also apply scaling to the profile along the path.  You can give a list of scalar scale factors or a list of 2-vector scale. 
//   In the latter scale the x and y scales of the profile are scaled separately before the profile is placed onto the path.  For non-closed
//   paths you can also give a single scale value or a 2-vector which is treated as the final scale.  The intermediate sections
//   are then scaled by linear interpolation either relative to length (if scale_by_length is true) or by point count otherwise.  
//   .
//   You can use set `transforms` to true to return a list of transformation matrices instead of the swept shape.  In this case, you can
//   often omit shape entirely.  The exception is when `closed=true` and you are using the "incremental" method.  In this case, `path_sweep`
//   uses the shape to correct for twist when the shape closes on itself, so you must include a valid shape.
// Arguments:
//   shape = A 2D polygon path or region describing the shape to be swept.
//   path = 2D or 3D path giving the path to sweep over
//   method = one of "incremental", "natural" or "manual".  Default: "incremental"
//   ---
//   normal = normal vector for initializing the incremental method, or for setting normals with method="manual".  Default: UP if the path makes an angle lower than 45 degrees to the xy plane, BACK otherwise.
//   closed = path is a closed loop.  Default: false
//   twist = amount of twist to add in degrees.  For closed sweeps must be a multiple of 360/symmetry.  Default: 0
//   twist_by_length = if true then interpolate twist based on the path length of the path. If false interoplate based on point count.  Default: true
//   symmetry = symmetry of the shape when closed=true.  Allows the shape to join with a 360/symmetry rotation instead of a full 360 rotation.  Default: 1
//   scale = Amount to scale the profiles.  If you give a scalar the scale starts at 1 and ends at your specified value. The same is true for a 2-vector, but x and y are scaled separately.   You can also give a vector of values, one for each path point, and you can give a list of 2-vectors that give the x and y scales of your profile for every point on the path (a Nx2 matrix for a path of length N.  Default: 1 (no scaling)
//   scale_by_length = if true then interpolate scale based on the path length of the path. If false interoplate based on point count.  Default: true
//   last_normal = normal to last point in the path for the "incremental" method.  Constrains the orientation of the last cross section if you supply it.
//   uniform = if set to false then compute tangents using the uniform=false argument, which may give better results when your path is non-uniformly sampled.  This argument is passed to {{path_tangents()}}.  Default: true
//   tangent = a list of tangent vectors in case you need more accuracy (particularly at the end points of your curve)
//   relaxed = set to true with the "manual" method to relax the orthogonality requirement of cross sections to the path tangent.  Default: false
//   caps = Can be a boolean or vector of two booleans.  Set to false to disable caps at the two ends.  Default: true
//   style = vnf_vertex_array style.  Default: "min_edge"
//   profiles = if true then display all the cross section profiles instead of the solid shape.  Can help debug a sweep.  (module only) Default: false
//   width = the width of lines used for profile display.  (module only) Default: 1
//   transforms = set to true to return transforms instead of a VNF.  These transforms can be manipulated and passed to sweep().  (function only)  Default: false.
//   convexity = convexity parameter for polyhedron().  (module only)  Default: 10
//   anchor = Translate so anchor point is at the origin. Default: "origin"
//   spin = Rotate this many degrees around Z axis after anchor. Default: 0
//   orient = Vector to rotate top towards after spin
//   atype  = Select "hull" or "intersect" anchor types.  Default: "hull"
//   cp = Centerpoint for determining "intersect" anchors or centering the shape.  Determintes the base of the anchor vector.  Can be "centroid", "mean", "box" or a 3D point.  Default: "centroid"
// Side Effects:
//   `$sweep_path` is set to the path thd defining the swept object
//   `$sweep_shape` is set to the shape being swept
//   `$sweep_closed` is true if the sweep is closed and false otherwise
//   `$sweep_transforms` is set to the array of transformation matrices that define the swept object.
//   `$sweep_scales` is set to the array of scales that were applied at each point to create the swept object.
//   `$sweep_twist` set to a scalar value giving the total twist across the path sweep object.
// Anchor Types:
//   "hull" = Anchors to the virtual convex hull of the shape.
//   "intersect" = Anchors to the surface of the shape.
// Named Anchors:
//   "origin" = The native position of the shape
//   "start" = When `closed==false`, the origin point of the shape, on the starting face of the object
//   "end" = When `closed==false`, the origin point of the shape, on the ending face of the object
//   "start-centroid" = When `closed==false`, the centroid of the shape, on the starting face of the object
//   "end-centroid" = When `closed==false`, the centroid of the shape, on the ending face of the object
// Example(NoScales): A simple sweep of a square along a sine wave:
//   path = [for(theta=[-180:5:180]) [theta/10, 10*sin(theta)]];
//   sq = square(6,center=true);
//   path_sweep(sq,path);
// Example(NoScales): If the square is not centered, then we get a different result because the shape is in a different place relative to the origin:
//   path = [for(theta=[-180:5:180]) [theta/10, 10*sin(theta)]];
//   sq = square(6);
//   path_sweep(sq,path);
// Example(Med,VPR=[34,0,8],NoScales): It may not be obvious, but the polyhedron in the previous example is invalid.  It will eventually give CGAL errors when you combine it with other shapes.  To see this, set profiles to true and look at the left side.  The profiles cross each other and intersect.  Any time this happens, your polyhedron is invalid, even if it seems to be working at first.  Another observation from the profile display is that we have more profiles than needed over a lot of the shape, so if the model is slow, using fewer profiles in the flat portion of the curve might speed up the calculation.
//   path = [for(theta=[-180:5:180]) [theta/10, 10*sin(theta)]];
//   sq = square(6);
//   path_sweep(sq,path,profiles=true,width=.1,$fn=8);
// Example(2D): We'll use this shape in several examples
//   ushape = [[-10, 0],[-10, 10],[ -7, 10],[ -7, 2],[  7, 2],[  7, 7],[ 10, 7],[ 10, 0]];
//   polygon(ushape);
// Example(NoScales): Sweep along a clockwise elliptical arc, using default "incremental" method.
//   ushape = [[-10, 0],[-10, 10],[ -7, 10],[ -7, 2],[  7, 2],[  7, 7],[ 10, 7],[ 10, 0]];
//   elliptic_arc = xscale(2, p=arc($fn=64,angle=[180,00], r=30));  // Clockwise
//   path_sweep(ushape, path3d(elliptic_arc));
// Example(NoScales): Sweep along a counter-clockwise elliptical arc.  Note that the orientation of the shape flips.
//   ushape = [[-10, 0],[-10, 10],[ -7, 10],[ -7, 2],[  7, 2],[  7, 7],[ 10, 7],[ 10, 0]];
//   elliptic_arc = xscale(2, p=arc($fn=64,angle=[0,180], r=30));   // Counter-clockwise
//   path_sweep(ushape, path3d(elliptic_arc));
// Example(NoScales): Sweep along a clockwise elliptical arc, using "natural" method, which lines up the X axis of the shape with the direction of curvature.  This means the X axis will point inward, so a counterclockwise arc gives:
//   ushape = [[-10, 0],[-10, 10],[ -7, 10],[ -7, 2],[  7, 2],[  7, 7],[ 10, 7],[ 10, 0]];
//   elliptic_arc = xscale(2, p=arc($fn=64,angle=[0,180], r=30));  // Counter-clockwise
//   path_sweep(ushape, elliptic_arc, method="natural");
// Example(NoScales): Sweep along a clockwise elliptical arc, using "natural" method.  If the curve is clockwise then the shape flips upside-down to align the X axis.
//   ushape = [[-10, 0],[-10, 10],[ -7, 10],[ -7, 2],[  7, 2],[  7, 7],[ 10, 7],[ 10, 0]];
//   elliptic_arc = xscale(2, p=arc($fn=64,angle=[180,0], r=30));  // Clockwise
//   path_sweep(ushape, path3d(elliptic_arc), method="natural");
// Example(NoScales): Sweep along a clockwise elliptical arc, using "manual" method.  You can orient the shape in a direction you choose (subject to the constraint that the profiles remain normal to the path):
//   ushape = [[-10, 0],[-10, 10],[ -7, 10],[ -7, 2],[  7, 2],[  7, 7],[ 10, 7],[ 10, 0]];
//   elliptic_arc = xscale(2, p=arc($fn=64,angle=[180,0], r=30));  // Clockwise
//   path_sweep(ushape, path3d(elliptic_arc), method="manual", normal=UP+RIGHT);
// Example(NoScales): Here we changed the ellipse to be more pointy, and with the same results as above we get a shape with an irregularity in the middle where it maintains the specified direction around the point of the ellipse.  If the ellipse were more pointy, this would result in a bad polyhedron:
//   ushape = [[-10, 0],[-10, 10],[ -7, 10],[ -7, 2],[  7, 2],[  7, 7],[ 10, 7],[ 10, 0]];
//   elliptic_arc = yscale(2, p=arc($fn=64,angle=[180,0], r=30));  // Clockwise
//   path_sweep(ushape, path3d(elliptic_arc), method="manual", normal=UP+RIGHT);
// Example(NoScales): It is easy to produce an invalid shape when your path has a smaller radius of curvature than the width of your shape.  The exact threshold where the shape becomes invalid depends on the density of points on your path.  The error may not be immediately obvious, as the swept shape appears fine when alone in your model, but adding a cube to the model reveals the problem.  In this case the pentagon is turned so its longest direction points inward to create the singularity.
//   qpath = [for(x=[-3:.01:3]) [x,x*x/1.8,0]];
//   // Prints 0.9, but we use pentagon with radius of 1.0 > 0.9
//   echo(radius_of_curvature = 1/max(path_curvature(qpath)));
//   path_sweep(apply(rot(90),pentagon(r=1)), qpath, normal=BACK, method="manual");
//   cube(0.5);    // Adding a small cube forces a CGAL computation which reveals
//                 // the error by displaying nothing or giving a cryptic message
// Example(NoScales): Using the `relax` option we allow the profiles to deviate from orthogonality to the path.  This eliminates the crease that broke the previous example because the sections are all parallel to each other.
//   qpath = [for(x=[-3:.01:3]) [x,x*x/1.8,0]];
//   path_sweep(apply(rot(90),pentagon(r=1)), qpath, normal=BACK, method="manual", relaxed=true);
//   cube(0.5);    // Adding a small cube is not a problem with this valid model
// Example(Med,VPR=[16,0,100],VPT=[0.05,0.6,0.6],VPD=25,NoScales): Using the `profiles=true` option can help debug bad polyhedra such as this one.  If any of the profiles intersect or cross each other, the polyhedron will be invalid.  In this case, you can see these intersections in the middle of the shape, which may give insight into how to fix your shape.   The profiles may also help you identify cases with a valid polyhedron where you have more profiles than needed to adequately define the shape.
//   tri= scale([4.5,2.5],[[0, 0], [0, 1], [1, 0]]);
//   path = left(4,xscale(1.5,arc(r=5,n=25,angle=[-70,70])));
//   path_sweep(tri,path,profiles=true,width=.1);
// Example(NoScales):  This 3d arc produces a result that twists to an undefined angle.  By default the incremental method sets the starting normal to UP, but the ending normal is unconstrained.
//   ushape = [[-10, 0],[-10, 10],[ -7, 10],[ -7, 2],[  7, 2],[  7, 7],[ 10, 7],[ 10, 0]];
//   arc = yrot(37, p=path3d(arc($fn=64, r=30, angle=[0,180])));
//   path_sweep(ushape, arc, method="incremental");
// Example(NoScales): You can constrain the last normal as well.  Here we point it right, which produces a nice result.
//   ushape = [[-10, 0],[-10, 10],[ -7, 10],[ -7, 2],[  7, 2],[  7, 7],[ 10, 7],[ 10, 0]];
//   arc = yrot(37, p=path3d(arc($fn=64, r=30, angle=[0,180])));
//   path_sweep(ushape, arc, method="incremental", last_normal=RIGHT);
// Example(NoScales): Here we constrain the last normal to UP.  Be aware that the behavior in the middle is unconstrained.
//   ushape = [[-10, 0],[-10, 10],[ -7, 10],[ -7, 2],[  7, 2],[  7, 7],[ 10, 7],[ 10, 0]];
//   arc = yrot(37, p=path3d(arc($fn=64, r=30, angle=[0,180])));
//   path_sweep(ushape, arc, method="incremental", last_normal=UP);
// Example(NoScales): The "natural" method produces a very different result
//   ushape = [[-10, 0],[-10, 10],[ -7, 10],[ -7, 2],[  7, 2],[  7, 7],[ 10, 7],[ 10, 0]];
//   arc = yrot(37, p=path3d(arc($fn=64, r=30, angle=[0,180])));
//   path_sweep(ushape, arc, method="natural");
// Example(NoScales): When the path starts at an angle of more that 45 deg to the xy plane the initial normal for "incremental" is BACK.  This produces the effect of the shape rising up out of the xy plane.  (Using UP for a vertical path is invalid, hence the need for a split in the defaults.)
//   ushape = [[-10, 0],[-10, 10],[ -7, 10],[ -7, 2],[  7, 2],[  7, 7],[ 10, 7],[ 10, 0]];
//   arc = xrot(75, p=path3d(arc($fn=64, r=30, angle=[0,180])));
//   path_sweep(ushape, arc, method="incremental");
// Example(NoScales): Adding twist
//   // Counter-clockwise
//   elliptic_arc = xscale(2, p=arc($fn=64,angle=[0,180], r=3));
//   path_sweep(pentagon(r=1), path3d(elliptic_arc), twist=72);
// Example(NoScales): Closed shape
//   ellipse = xscale(2, p=circle($fn=64, r=3));
//   path_sweep(pentagon(r=1), path3d(ellipse), closed=true);
// Example(NoScales): Closed shape with added twist
//   ellipse = xscale(2, p=circle($fn=64, r=3));
//   // Looks better with finer sampling
//   pentagon = subdivide_path(pentagon(r=1), 30);
//   path_sweep(pentagon, path3d(ellipse),
//              closed=true, twist=360);
// Example(NoScales): The last example was a lot of twist.  In order to use less twist you have to tell `path_sweep` that your shape has symmetry, in this case 5-fold.  Mobius strip with pentagon cross section:
//   ellipse = xscale(2, p=circle($fn=64, r=3));
//   // Looks better with finer sampling
//   pentagon = subdivide_path(pentagon(r=1), 30);
//   path_sweep(pentagon, path3d(ellipse), closed=true,
//              symmetry = 5, twist=2*360/5);
// Example(Med,NoScales): A helical path reveals the big problem with the "incremental" method: it can introduce unexpected and extreme twisting.  (Note helix example came from list-comprehension-demos)
//   function helix(t) = [(t / 1.5 + 0.5) * 30 * cos(6 * 360 * t),
//                        (t / 1.5 + 0.5) * 30 * sin(6 * 360 * t),
//                         200 * (1 - t)];
//   helix_steps = 200;
//   helix = [for (i=[0:helix_steps]) helix(i/helix_steps)];
//   ushape = [[-10, 0],[-10, 10],[ -7, 10],[ -7, 2],[  7, 2],[  7, 7],[ 10, 7],[ 10, 0]];
//   path_sweep(ushape, helix);
// Example(Med,NoScales): You can constrain both ends, but still the twist remains:
//   function helix(t) = [(t / 1.5 + 0.5) * 30 * cos(6 * 360 * t),
//                        (t / 1.5 + 0.5) * 30 * sin(6 * 360 * t),
//                         200 * (1 - t)];
//   helix_steps = 200;
//   helix = [for (i=[0:helix_steps]) helix(i/helix_steps)];
//   ushape = [[-10, 0],[-10, 10],[ -7, 10],[ -7, 2],[  7, 2],[  7, 7],[ 10, 7],[ 10, 0]];
//   path_sweep(ushape, helix, normal=UP, last_normal=UP);
// Example(Med,NoScales): Even if you manually guess the amount of twist and remove it, the result twists one way and then the other:
//   function helix(t) = [(t / 1.5 + 0.5) * 30 * cos(6 * 360 * t),
//                        (t / 1.5 + 0.5) * 30 * sin(6 * 360 * t),
//                         200 * (1 - t)];
//   helix_steps = 200;
//   helix = [for (i=[0:helix_steps]) helix(i/helix_steps)];
//   ushape = [[-10, 0],[-10, 10],[ -7, 10],[ -7, 2],[  7, 2],[  7, 7],[ 10, 7],[ 10, 0]];
//   path_sweep(ushape, helix, normal=UP, last_normal=UP, twist=360);
// Example(Med,NoScales): To get a good result you must use a different method.
//   function helix(t) = [(t / 1.5 + 0.5) * 30 * cos(6 * 360 * t),
//                        (t / 1.5 + 0.5) * 30 * sin(6 * 360 * t),
//                         200 * (1 - t)];
//   helix_steps = 200;
//   helix = [for (i=[0:helix_steps]) helix(i/helix_steps)];
//   ushape = [[-10, 0],[-10, 10],[ -7, 10],[ -7, 2],[  7, 2],[  7, 7],[ 10, 7],[ 10, 0]];
//   path_sweep(ushape, helix, method="natural");
// Example(Med,NoScales): Note that it may look like the shape above is flat, but the profiles are very slightly tilted due to the nonzero torsion of the curve.  If you want as flat as possible, specify it so with the "manual" method:
//   function helix(t) = [(t / 1.5 + 0.5) * 30 * cos(6 * 360 * t),
//                        (t / 1.5 + 0.5) * 30 * sin(6 * 360 * t),
//                         200 * (1 - t)];
//   helix_steps = 200;
//   helix = [for (i=[0:helix_steps]) helix(i/helix_steps)];
//   ushape = [[-10, 0],[-10, 10],[ -7, 10],[ -7, 2],[  7, 2],[  7, 7],[ 10, 7],[ 10, 0]];
//   path_sweep(ushape, helix, method="manual", normal=UP);
// Example(Med,NoScales): What if you want to angle the shape inward?  This requires a different normal at every point in the path:
//   function helix(t) = [(t / 1.5 + 0.5) * 30 * cos(6 * 360 * t),
//                        (t / 1.5 + 0.5) * 30 * sin(6 * 360 * t),
//                         200 * (1 - t)];
//   helix_steps = 200;
//   helix = [for (i=[0:helix_steps]) helix(i/helix_steps)];
//   normals = [for(i=[0:helix_steps]) [-cos(6*360*i/helix_steps), -sin(6*360*i/helix_steps), 2.5]];
//   ushape = [[-10, 0],[-10, 10],[ -7, 10],[ -7, 2],[  7, 2],[  7, 7],[ 10, 7],[ 10, 0]];
//   path_sweep(ushape, helix, method="manual", normal=normals);
// Example(NoScales): When using "manual" it is important to choose a normal that works for the whole path, producing a consistent result.  Here we have specified an upward normal, and indeed the shape is pointed up everywhere, but two abrupt transitional twists render the model invalid.
//   yzcircle = yrot(90,p=path3d(circle($fn=64, r=30)));
//   ushape = [[-10, 0],[-10, 10],[ -7, 10],[ -7, 2],[  7, 2],[  7, 7],[ 10, 7],[ 10, 0]];
//   path_sweep(ushape, yzcircle, method="manual", normal=UP, closed=true);
// Example(NoScales): The "natural" method will introduce twists when the curvature changes direction.  A warning is displayed.
//   arc1 = path3d(arc(angle=90, r=30));
//   arc2 = xrot(-90, cp=[0,30],p=path3d(arc(angle=[90,180], r=30)));
//   two_arcs = path_merge_collinear(concat(arc1,arc2));
//   ushape = [[-10, 0],[-10, 10],[ -7, 10],[ -7, 2],[  7, 2],[  7, 7],[ 10, 7],[ 10, 0]];
//   path_sweep(ushape, two_arcs, method="natural");
// Example(NoScales): The only simple way to get a good result is the "incremental" method:
//   arc1 = path3d(arc(angle=90, r=30));
//   arc2 = xrot(-90, cp=[0,30],p=path3d(arc(angle=[90,180], r=30)));
//   arc3 = apply( translate([-30,60,30])*yrot(90), path3d(arc(angle=[270,180], r=30)));
//   three_arcs = path_merge_collinear(concat(arc1,arc2,arc3));
//   ushape = [[-10, 0],[-10, 10],[ -7, 10],[ -7, 2],[  7, 2],[  7, 7],[ 10, 7],[ 10, 0]];
//   path_sweep(ushape, three_arcs, method="incremental");
// Example(Med,NoScales): knot example from list-comprehension-demos, "incremental" method
//   function knot(a,b,t) =   // rolling knot
//        [ a * cos (3 * t) / (1 - b* sin (2 *t)),
//          a * sin( 3 * t) / (1 - b* sin (2 *t)),
//        1.8 * b * cos (2 * t) /(1 - b* sin (2 *t))];
//   a = 0.8; b = sqrt (1 - a * a);
//   ksteps = 400;
//   knot_path = [for (i=[0:ksteps-1]) 50 * knot(a,b,(i/ksteps)*360)];
//   ushape = [[-10, 0],[-10, 10],[ -7, 10],[ -7, 2],[  7, 2],[  7, 7],[ 10, 7],[ 10, 0]];
//   path_sweep(ushape, knot_path, closed=true, method="incremental");
// Example(Med,NoScales): knot example from list-comprehension-demos, "natural" method.  Which one do you like better?
//   function knot(a,b,t) =   // rolling knot
//        [ a * cos (3 * t) / (1 - b* sin (2 *t)),
//          a * sin( 3 * t) / (1 - b* sin (2 *t)),
//        1.8 * b * cos (2 * t) /(1 - b* sin (2 *t))];
//   a = 0.8; b = sqrt (1 - a * a);
//   ksteps = 400;
//   knot_path = [for (i=[0:ksteps-1]) 50 * knot(a,b,(i/ksteps)*360)];
//   ushape = [[-10, 0],[-10, 10],[ -7, 10],[ -7, 2],[  7, 2],[  7, 7],[ 10, 7],[ 10, 0]];
//   path_sweep(ushape, knot_path, closed=true, method="natural");
// Example(Med,NoScales): knot with twist.  Note if you twist it the other direction the center section untwists because of the natural twist there.  Also compare to the "incremental" method which has less twist in the center.
//   function knot(a,b,t) =   // rolling knot
//        [ a * cos (3 * t) / (1 - b* sin (2 *t)),
//          a * sin( 3 * t) / (1 - b* sin (2 *t)),
//        1.8 * b * cos (2 * t) /(1 - b* sin (2 *t))];
//   a = 0.8; b = sqrt (1 - a * a);
//   ksteps = 400;
//   knot_path = [for (i=[0:ksteps-1]) 50 * knot(a,b,(i/ksteps)*360)];
//   path_sweep(subdivide_path(pentagon(r=12),30), knot_path, closed=true,
//              twist=-360*8, symmetry=5, method="natural");
// Example(Med,NoScales): twisted knot with twist distributed by path sample points instead of by length using `twist_by_length=false`
//   function knot(a,b,t) =   // rolling knot
//           [ a * cos (3 * t) / (1 - b* sin (2 *t)),
//             a * sin( 3 * t) / (1 - b* sin (2 *t)),
//           1.8 * b * cos (2 * t) /(1 - b* sin (2 *t))];
//   a = 0.8; b = sqrt (1 - a * a);
//   ksteps = 400;
//   knot_path = [for (i=[0:ksteps-1]) 50 * knot(a,b,(i/ksteps)*360)];
//   path_sweep(subdivide_path(pentagon(r=12),30), knot_path, closed=true,
//              twist=-360*8, symmetry=5, method="natural", twist_by_length=false);
// Example(Big,NoScales): This torus knot example comes from list-comprehension-demos.  The knot lies on the surface of a torus.  When we use the "natural" method the swept figure is angled compared to the surface of the torus because the curve doesn't follow geodesics of the torus.
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
// Example(Big,NoScales): By computing the normal to the torus at the path we can orient the path to lie on the surface of the torus:
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
// Example(NoScales): You can request the transformations and manipulate them before passing them on to sweep.  Here we construct a tube that changes scale by first generating the transforms and then applying the scale factor and connecting the inside and outside.  Note that the wall thickness varies because it is produced by scaling.
//   shape = star(n=5, r=10, ir=5);
//   rpath = arc(25, points=[[29,6,-4], [3,4,6], [1,1,7]]);
//   trans = path_sweep(shape, rpath, transforms=true);
//   outside = [for(i=[0:len(trans)-1]) trans[i]*scale(lerp(1,1.5,i/(len(trans)-1)))];
//   inside = [for(i=[len(trans)-1:-1:0]) trans[i]*scale(lerp(1.1,1.4,i/(len(trans)-1)))];
//   sweep(shape, concat(outside,inside),closed=true);
// Example(NoScales): An easier way to scale your model is to use the scale parameter.
//   elliptic_arc = xscale(2, p=arc($fn=64,angle=[0,180], r=3));
//   path_sweep(pentagon(r=1), path3d(elliptic_arc), scale=2);
// Example(NoScales): Scaling only in the y direction of the profile (z direction in the model in this case)
//   elliptic_arc = xscale(2, p=arc($fn=64,angle=[0,180], r=3));
//   path_sweep(rect(2), path3d(elliptic_arc), scale=[1,2]);
// Example(NoScales): Specifying scale at every point for a closed path
//   N=64;
//   path = circle(r=5, $fn=64);
//   theta = lerpn(0,360,N,endpoint=false);
//   scale = [for(t=theta) sin(6*t)/5+1];
//   path_sweep(rect(2), path3d(path), closed=true, scale=scale);
// Example(Med,NoScales): Using path_sweep on a region
//   rgn1 = [for (d=[10:10:60]) circle(d=d,$fn=8)];
//   rgn2 = [square(30,center=false)];
//   rgn3 = [for (size=[10:10:20]) move([15,15],p=square(size=size, center=true))];
//   mrgn = union(rgn1,rgn2);
//   orgn = difference(mrgn,rgn3);
//   path_sweep(orgn,arc(r=40,angle=180));
// Example(Med,NoScales): A region with a twist
//   region = [for(i=pentagon(5)) move(i,p=circle(r=2,$fn=25))];
//   path_sweep(region,
//              circle(r=16,$fn=75),closed=true,
//              twist=360/5*2,symmetry=5);
// Example(Med,NoScales): Cutting a cylinder with a curved path.  Note that in this case, the incremental method produces just a slight twist but the natural method produces an extreme twist.  But manual specification produces no twist, as desired:
//   $fn=90;
//   r=8;
//   thickness=1;
//   len=21;
//   curve = [for(theta=[0:4:359])
//              [r*cos(theta), r*sin(theta), 10+sin(6*theta)]];
//   difference(){
//     cylinder(r=r, h=len);
//     down(.5)cylinder(r=r-thickness, h=len+1);
//     path_sweep(left(.05,square([1.1,1])), curve, closed=true,
//                method="manual", normal=UP);
//   }
// Example(Med,NoScales,VPR=[78.1,0,43.2],VPT=[2.18042,-0.485127,1.90371],VPD=74.4017): The "start" and "end" anchors are located at the origin point of the swept shape.
//   shape = back_half(right_half(star(n=5,id=5,od=10)),y=-1);
//   path = arc(angle=[0,180],d=30);
//   path_sweep(shape,path,method="natural"){
//     attach(["start","end"]) anchor_arrow(s=5);
//   }
// Example(Med,NoScales,VPR=[78.1,0,43.2],VPT=[2.18042,-0.485127,1.90371],VPD=74.4017): The "start" and "end" anchors are located at the origin point of the swept shape.
//   shape = back_half(right_half(star(n=5,id=5,od=10)),y=-1);
//   path = arc(angle=[0,180],d=30);
//   path_sweep(shape,path,method="natural"){
//     attach(["start-centroid","end-centroid"]) anchor_arrow(s=5);
//   }
// Example(Med,NoScales,VPR=[78.1,0,43.2],VPT=[2.18042,-0.485127,1.90371],VPD=74.4017): Note that the "start" anchors are backwards compared to the direction of the sweep, so you have to attach the TOP to align the shape with its ends.  
//   shape = back_half(right_half(star(n=5,id=5,od=10)),y=-1)[0];
//   path = arc(angle=[0,180],d=30);
//   path_sweep(shape,path,method="natural",scale=[1,1.5])
//     recolor("red"){
//       attach("start",TOP) stroke([path3d(shape)],width=.5);
//       attach("end") stroke([path3d(yscale(1.5,shape))],width=.5);       
//     }

module path_sweep(shape, path, method="incremental", normal, closed, twist=0, twist_by_length=true, scale=1, scale_by_length=true,
                    symmetry=1, last_normal, tangent, uniform=true, relaxed=false, caps, style="min_edge", convexity=10,
                    anchor="origin",cp="centroid",spin=0, orient=UP, atype="hull",profiles=false,width=1)
{
    dummy = assert(is_region(shape) || is_path(shape,2), "shape must be a 2D path or region")
            assert(in_list(atype, _ANCHOR_TYPES), "Anchor type must be \"hull\" or \"intersect\"");
    trans_scale = path_sweep(shape, path, method, normal, closed, twist, twist_by_length, scale, scale_by_length,
                            symmetry, last_normal, tangent, uniform, relaxed, caps, style, transforms=true,_return_scales=true);
    caps = is_def(caps) ? caps :
           closed ? false : true;
    fullcaps = is_bool(caps) ? [caps,caps] : caps;
    transforms = trans_scale[0];
    scales = trans_scale[1];
    firstscale = is_num(scales[0]) ? 1/scales[0] : [1/scales[0].x, 1/scales[0].y];
    lastscale = is_num(last(scales)) ? 1/last(scales) : [1/last(scales).x, 1/last(scales).y];
    vnf = sweep(is_path(shape)?clockwise_polygon(shape):shape, transforms, closed=false, caps=fullcaps,style=style);
    shapecent = point3d(centroid(shape));
    $sweep_transforms = transforms;
    $sweep_scales = scales;
    $sweep_shape = shape;
    $sweep_path = path;
    $sweep_closed = closed;
    $sweep_twist = twist;
    anchors = closed ? []
            :
              [
                named_anchor("start", rot=transforms[0]*scale(firstscale), flip=true), 
                named_anchor("end", rot=last(transforms)*scale(lastscale)),
                named_anchor("start-centroid", rot=transforms[0]*move(shapecent)*scale(firstscale), flip=true),
                named_anchor("end-centroid", rot=last(transforms)*move(shapecent)*scale(lastscale))
    ];
    if (profiles){
        rshape = is_path(shape) ? [path3d(shape)]
                                : [for(s=shape) path3d(s)];
        attachable(anchor,spin,orient, vnf=vnf, extent=atype=="hull", cp=cp, anchors=anchors) {
            for(T=transforms) stroke([for(part=rshape)apply(T,part)],width=width);
            children();
        }
    }
    else
      attachable(anchor,spin,orient,vnf=vnf,extent=atype=="hull", cp=cp,anchors=anchors){
          vnf_polyhedron(vnf,convexity=convexity);
          children();
      }
}


function path_sweep(shape, path, method="incremental", normal, closed, twist=0, twist_by_length=true, scale=1, scale_by_length=true, 
                    symmetry=1, last_normal, tangent, uniform=true, relaxed=false, caps, style="min_edge", transforms=false,
                    anchor="origin",cp="centroid",spin=0, orient=UP, atype="hull",_return_scales=false) =
  is_1region(path) ? path_sweep(shape=shape,path=path[0], method=method, normal=normal, closed=default(closed,true), 
                                twist=twist, scale=scale, scale_by_length=scale_by_length, twist_by_length=twist_by_length, symmetry=symmetry, last_normal=last_normal,
                                tangent=tangent, uniform=uniform, relaxed=relaxed, caps=caps, style=style, transforms=transforms,
                                anchor=anchor, cp=cp, spin=spin, orient=orient, atype=atype, _return_scales=_return_scales) :
  let(closed=default(closed,false))
  assert(in_list(atype, _ANCHOR_TYPES), "Anchor type must be \"hull\" or \"intersect\"")
  assert(!closed || twist % (360/symmetry)==0, str("For a closed sweep, twist must be a multiple of 360/symmetry = ",360/symmetry))
  assert(closed || symmetry==1, "symmetry must be 1 when closed is false")
  assert(is_integer(symmetry) && symmetry>0, "symmetry must be a positive integer")
  let(path = force_path(path))
  assert(is_path(path,[2,3]), "input path is not a 2D or 3D path")
  assert(!closed || !approx(path[0],last(path)), "Closed path includes start point at the end")
  assert((is_region(shape) || is_path(shape,2)) || (transforms && !(closed && method=="incremental")),"shape must be a 2d path or region")
  let(
    path = path3d(path),
    caps = is_def(caps) ? caps :
           closed ? false : true,
    capsOK = is_bool(caps) || is_bool_list(caps,2),
    fullcaps = is_bool(caps) ? [caps,caps] : caps,
    normalOK = is_undef(normal) || (method!="natural" && is_vector(normal,3))
                                || (method=="manual" && same_shape(normal,path)),
    scaleOK = scale==1 || ((is_num(scale) || is_vector(scale,2)) && !closed) || is_vector(scale,len(path)) || is_matrix(scale,len(path),2)
    
  )
  assert(normalOK,  method=="natural" ? "Cannot specify normal with the \"natural\" method"
                  : method=="incremental" ? "Normal with \"incremental\" method must be a 3-vector"
                  : str("Incompatible normal given.  Must be a 3-vector or a list of ",len(path)," 3-vectors"))
  assert(capsOK, "caps must be boolean or a list of two booleans")
  assert(!closed || !caps, "Cannot make closed shape with caps")
  assert(is_undef(normal) || (is_vector(normal) && len(normal)==3) || (is_path(normal) && len(normal)==len(path) && len(normal[0])==3), "Invalid normal specified")
  assert(is_undef(tangent) || (is_path(tangent) && len(tangent)==len(path) && len(tangent[0])==3), "Invalid tangent specified")
  assert(scaleOK,str("Incompatible or invalid scale",closed?" for closed path":"",": must be ", closed?"":"a scalar, a 2-vector, ",
                     "a vector of length ",len(path)," or a ",len(path),"x2 matrix of scales"))
  let(
    scale = !(is_num(scale) || is_vector(scale,2)) ? scale
          : let(s=is_num(scale) ? [scale,scale] : scale)
            !scale_by_length ? lerpn([1,1],s,len(path))
          : lerp([1,1],s, path_length_fractions(path,false)),
    scale_list = [for(s=scale) scale(s),if (closed) scale(scale[0])],
    tangents = is_undef(tangent) ? path_tangents(path,uniform=uniform,closed=closed) : [for(t=tangent) unit(t)],
    normal = is_path(normal) ? [for(n=normal) unit(n)] :
             is_def(normal) ? unit(normal) :
             method =="incremental" && abs(tangents[0].z) > 1/sqrt(2) ? BACK : UP,
    normals = is_path(normal) ? normal : repeat(normal,len(path)),
    tpathfrac = twist_by_length ? path_length_fractions(path, closed) : [for(i=[0:1:len(path)]) i / (len(path)-(closed?0:1))],
    spathfrac = scale_by_length ? path_length_fractions(path, closed) : [for(i=[0:1:len(path)]) i / (len(path)-(closed?0:1))],    
    L = len(path),
    unscaled_transform_list =
        method=="old_incremental" ?
          let(rotations =
                 [for( i  = 0,
                       ynormal = normal - (normal * tangents[0])*tangents[0],
                       rotation = frame_map(y=ynormal, z=tangents[0])
                         ;
                       i < len(tangents) + (closed?1:0)
                         ;
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
                           frame_map(y=lastynormal, z=last_tangent),
              mismatch = transpose(last(rotations)) * reference_rot,
              correction_twist = atan2(mismatch[1][0], mismatch[0][0]),
              // Spread out this extra twist over the whole sweep so that it doesn't occur
              // abruptly as an artifact at the last step.
              twistfix = correction_twist%(360/symmetry),
              adjusted_final = !closed ? undef :
                            translate(path[0]) * rotations[0] * zrot(-correction_twist+correction_twist%(360/symmetry)-twist)
          )  [for(i=idx(path)) translate(path[i]) * rotations[i] * zrot((twistfix-twist)*tpathfrac[i]), if(closed) adjusted_final] 
      : method=="incremental" ?   // Implements Rotation Minimizing Frame from "Computation of Rotation Minimizing Frames"
                                  // by Wenping Yang, Bert Büttler, Dayue Zheng, Yang Liu, 2008
                                  // http://doi.acm.org/10.1145/1330511.1330513
          let(rotations =         // https://www.microsoft.com/en-us/research/wp-content/uploads/2016/12/Computation-of-rotation-minimizing-frames.pdf
                 [for( i  = 0,
                       ynormal = normal - (normal * tangents[0])*tangents[0],
                       rotation = frame_map(y=ynormal, z=tangents[0]),
                       r=ynormal
                         ;
                       i < len(tangents) + (closed?1:0)
                         ;
                       v1 = path[(i+1)%L]-path[i%L],
                       c1 = v1*v1,
                       rL = r - 2*(v1*r)/c1 * v1,
                       tL = tangents[i%L] - 2*(v1*tangents[i%L])/c1 * v1,
                       v2 = tangents[(i+1)%L]-tL,
                       c2 = v2*v2,
                       r = rL - (2/c2)*(v2*rL)*v2,
                       rotation = i<len(tangents)-1+(closed?1:0)? frame_map(y=r,z=tangents[(i+1)%L]) : undef,
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
                           frame_map(y=lastynormal, z=last_tangent),
              mismatch = transpose(last(rotations)) * reference_rot,
              correction_twist = atan2(mismatch[1][0], mismatch[0][0]),
              // Spread out this extra twist over the whole sweep so that it doesn't occur
              // abruptly as an artifact at the last step.
              twistfix = correction_twist%(360/symmetry),
              adjusted_final = !closed ? undef :
                            translate(path[0]) * rotations[0] * zrot(-correction_twist+correction_twist%(360/symmetry)-twist)
          )  [for(i=idx(path)) translate(path[i]) * rotations[i] * zrot((twistfix-twist)*tpathfrac[i]), if(closed) adjusted_final] 
      : method=="manual" ?
              [for(i=[0:L-(closed?0:1)]) let(
                       ynormal = relaxed ? normals[i%L] : normals[i%L] - (normals[i%L] * tangents[i%L])*tangents[i%L],
                       znormal = relaxed ? tangents[i%L] - (normals[i%L] * tangents[i%L])*normals[i%L] : tangents[i%L],
                       rotation = frame_map(y=ynormal, z=znormal)
                   )
                   assert(approx(ynormal*znormal,0),str("Supplied normal is parallel to the path tangent at point ",i))
                   translate(path[i%L])*rotation*zrot(-twist*tpathfrac[i])
              ]
      : method=="natural" ?   // map x axis of shape to the path normal, which points in direction of curvature
              let (pathnormal = path_normals(path, tangents, closed))
              assert(all_defined(pathnormal),"Natural normal vanishes on your curve, select a different method")
              let( testnormals = [for(i=[0:len(pathnormal)-1-(closed?1:2)]) pathnormal[i]*select(pathnormal,i+2)],
                   a=[for(i=idx(testnormals)) testnormals[i]<.5 ? echo(str("Big change at index ",i," pn=",pathnormal[i]," pn2= ",select(pathnormal,i+2))):0],
                   dummy = min(testnormals) < .5 ? echo("WARNING: ***** Abrupt change in normal direction.  Consider a different method in path_sweep() *****") :0
                 )
              [for(i=[0:L-(closed?0:1)]) let(
                       rotation = frame_map(x=pathnormal[i%L], z=tangents[i%L])
                   )
                   translate(path[i%L])*rotation*zrot(-twist*tpathfrac[i])
                 ] 
      : assert(false,"Unknown method or no method given"), // unknown method
    transform_list = v_mul(unscaled_transform_list, scale_list),
    ends_match = !closed ? true
                 : let( rshape = is_path(shape) ? [path3d(shape)]
                                                : [for(s=shape) path3d(s)]
                   )
                   are_regions_equal(apply(transform_list[0], rshape),
                                     apply(transform_list[L], rshape)),
    dummy = ends_match ? 0 : echo("WARNING: ***** The points do not match when closing the model in path_sweep() *****")
  )
  transforms && _return_scales
             ? [transform_list,scale]
: transforms ? transform_list
             : sweep(is_path(shape)?clockwise_polygon(shape):shape, transform_list, closed=false, caps=fullcaps,style=style,
                       anchor=anchor,cp=cp,spin=spin,orient=orient,atype=atype);


// Function&Module: path_sweep2d()
// Synopsis: Sweep a 2d polygon path along a 2d path allowing self-intersection. 
// SynTags: VNF, Geom
// Topics: Extrusion, Sweep, Paths
// See Also: linear_sweep(), rotate_sweep(), sweep(), spiral_sweep(), path_sweep(), offset_sweep()
// Usage: as module
//   path_sweep2d(shape, path, [closed], [caps], [quality], [style], [convexity=], [anchor=], [spin=], [orient=], [atype=], [cp=]) [ATTACHMENTS];
// Usage: as function
//   vnf = path_sweep2d(shape, path, [closed], [caps], [quality], [style], [anchor=], [spin=], [orient=], [atype=], [cp=]);
// Description:
//   Takes an input 2D polygon (the shape) and a 2d path, and constructs a polyhedron by sweeping the shape along the path.
//   When run as a module returns the polyhedron geometry.  When run as a function returns a VNF.
//   .
//   See {{path_sweep()}} for more details on how the sweep operation works and for introductory examples.
//   This 2d version is different because local self-intersections (creases in the output) are allowed and do not produce CGAL errors.
//   This is accomplished by using offset() calculations, which are more expensive than simply copying the shape along
//   the path, so if you do not have local self-intersections, use {{path_sweep()}} instead.  If xmax is the largest x value (in absolute value)
//   of the shape, then path_sweep2d() will work as long as the offset of `path` exists at `delta=xmax`.  If the offset vanishes, as in the
//   case of a circle offset by more than its radius, then you will get an error about a degenerate offset.
//   Note that global self-intersections will still give rise to CGAL errors.  You should be able to handle these by partitioning your model.  The y axis of the
//   shape is mapped to the z axis in the swept polyhedron, and no twisting can occur.
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
//   anchor = Translate so anchor point is at the origin.  Default: "origin"
//   spin = Rotate this many degrees around Z axis after anchor.  Default: 0
//   orient = Vector to rotate top towards after spin
//   atype = Select "hull" or "intersect" anchor types.  Default: "hull"
//   cp = Centerpoint for determining "intersect" anchors or centering the shape.  Determintes the base of the anchor vector.  Can be "centroid", "mean", "box" or a 3D point.  Default: "centroid"
// Named Anchors:
//   "origin" = The native position of the shape.  
// Anchor Types:
//   "hull" = Anchors to the virtual convex hull of the shape.
//   "intersect" = Anchors to the surface of the shape.
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

function path_sweep2d(shape, path, closed=false, caps, quality=1, style="min_edge",
                      anchor="origin",cp="centroid",spin=0, orient=UP, atype="hull") =
   let(
        caps = is_def(caps) ? caps
             : closed ? false : true,
        capsOK = is_bool(caps) || is_bool_list(caps,2),
        fullcaps = is_bool(caps) ? [caps,caps] : caps,
        shape = force_path(shape,"shape"),
        path = force_path(path)
   )
   assert(is_path(shape,2), "shape must be a 2D path")
   assert(is_path(path,2), "path must be a 2D path")
   assert(capsOK, "caps must be boolean or a list of two booleans")
   assert(!closed || !caps, "Cannot make closed shape with caps")
   let(
        profile = ccw_polygon(shape),
        flip = closed && is_polygon_clockwise(path) ? -1 : 1,
        path = flip ? reverse(path) : path,
        proflist= transpose(
                     [for(pt = profile)
                        let(
                            ofs = offset(path, delta=-flip*pt.x, return_faces=true,closed=closed, quality=quality),
                            map = column(_ofs_vmap(ofs,closed=closed),1)
                        )
                        select(path3d(ofs[0],pt.y),map)
                      ]
                  ),
        vnf = vnf_vertex_array([
                         each proflist,
                         if (closed) proflist[0]
                        ],cap1=fullcaps[0],cap2=fullcaps[1],col_wrap=true,style=style)
   )
   reorient(anchor,spin,orient,vnf=vnf,p=vnf,extent=atype=="hull",cp=cp);


module path_sweep2d(profile, path, closed=false, caps, quality=1, style="min_edge", convexity=10,
                    anchor="origin", cp="centroid", spin=0, orient=UP, atype="hull")
{
   vnf = path_sweep2d(profile, path, closed, caps, quality, style);
   vnf_polyhedron(vnf,convexity=convexity,anchor=anchor, spin=spin, orient=orient, atype=atype, cp=cp)
        children();
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



// Function&Module: sweep()
// Synopsis: Construct a 3d object from arbitrary transformations of a 2d polygon path.
// SynTags: VNF, Geom
// Topics: Extrusion, Sweep, Paths
// See Also: sweep_attach(), linear_sweep(), rotate_sweep(), spiral_sweep(), path_sweep(), path_sweep2d(), offset_sweep()
// Usage: As Module
//   sweep(shape, transforms, [closed], [caps], [style], [convexity=], [anchor=], [spin=], [orient=], [atype=]) [ATTACHMENTS];
// Usage: As Function
//   vnf = sweep(shape, transforms, [closed], [caps], [style], [anchor=], [spin=], [orient=], [atype=]);
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
//   cp = Centerpoint for determining "intersect" anchors or centering the shape.  Determintes the base of the anchor vector.  Can be "centroid", "mean", "box" or a 3D point.  Default: "centroid"
//   atype = Select "hull" or "intersect" anchor types.  Default: "hull"
//   anchor = Translate so anchor point is at the origin. Default: "origin"
//   spin = Rotate this many degrees around Z axis after anchor. Default: 0
//   orient = Vector to rotate top towards after spin  (module only)
// Named Anchors:
//   "origin" = The native position of the shape.  
// Anchor Types:
//   "hull" = Anchors to the virtual convex hull of the shape.
//   "intersect" = Anchors to the surface of the shape.
// Example(VPR=[45,0,74],VPD=175,VPT=[-3.8,12.4,19]): A bent object that also changes shape along its length.
//   radius = 75;
//   angle = 40;
//   shape = circle(r=5,$fn=32);
//   T = [for(i=[0:25]) xrot(-angle*i/25,cp=[0,radius,0])*scale([1+i/25, 2-i/25,1])];
//   sweep(shape,T);
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

function sweep(shape, transforms, closed=false, caps, style="min_edge",
               anchor="origin", cp="centroid", spin=0, orient=UP, atype="hull") =
    assert(is_consistent(transforms, ident(4)), "Input transforms must be a list of numeric 4x4 matrices in sweep")
    assert(is_path(shape,2) || is_region(shape), "Input shape must be a 2d path or a region.")
    let(
        caps = is_def(caps) ? caps :
            closed ? false : true,
        capsOK = is_bool(caps) || is_bool_list(caps,2),
        fullcaps = is_bool(caps) ? [caps,caps] : caps
    )
    assert(len(transforms)>=2, "transformation must be length 2 or more")
    assert(capsOK, "caps must be boolean or a list of two booleans")
    assert(!closed || !caps, "Cannot make closed shape with caps")
    is_region(shape)? let(
        regions = region_parts(shape),
        rtrans = reverse(transforms),
        vnfs = [
            for (rgn=regions) each [
                for (path=rgn)
                    sweep(path, transforms, closed=closed, caps=false, style=style),
                if (fullcaps[0]) vnf_from_region(rgn, transform=transforms[0], reverse=true),
                if (fullcaps[1]) vnf_from_region(rgn, transform=last(transforms)),
            ],
        ],
        vnf = vnf_join(vnfs)
    ) vnf :
    assert(len(shape)>=3, "shape must be a path of at least 3 non-colinear points")
    vnf_vertex_array([for(i=[0:len(transforms)-(closed?0:1)]) apply(transforms[i%len(transforms)],path3d(shape))],
                     cap1=fullcaps[0],cap2=fullcaps[1],col_wrap=true,style=style);


module sweep(shape, transforms, closed=false, caps, style="min_edge", convexity=10,
             anchor="origin",cp="centroid",spin=0, orient=UP, atype="hull")
{
    $sweep_transforms=transforms;
    $sweep_shape=shape;
    $sweep_closed=closed;
    vnf = sweep(shape, transforms, closed, caps, style);
    vnf_polyhedron(vnf, convexity=convexity, anchor=anchor, spin=spin, orient=orient, atype=atype, cp=cp)
        children();
}



// Section: Attaching children to sweeps


// Module: sweep_attach()
// Synopsis: Attach children to sides of a path_sweep parent object
// SynTags: Geom
// Topics: Extrusion, Sweep, Paths
// See Also: path_sweep()
// Usage:
//   path_sweep(...) { sweep_attach(parent, [child], [frac], [idx=], [len=], [spin=], [overlap=], [atype=]) CHILDREN; }
//   sweep(...) { sweep_attach(parent, [child], [frac], [idx=], [len=], [spin=], [overlap=], [atype=]) CHILDREN; }
// Description:
//   Attaches children to the sides of a {{path_sweep()}} or {{sweep()}} object.  You supply a position along the path,
//   either by path fraction, length, or index.  In the case of `sweep()` objects the path is defined as the path traced out
//   by the origin of the shape under the transformation list.  Objects are attached with their UP direction aligned with
//   the anchor for the profile and their BACK direction pointing in the direction of the sweep.
//   .
//   Like {{attach()}} this module has a parent-child anchor mode where you specify the child anchor and it is
//   aligned with the anchor on the sweep.  As with {{attach()}}, the child `anchor` and `orient` parameters are ignored.
//   Alternative you can use parent anchor mode where give only the parent anchor and the child appears at its
//   child-specified (default) anchor point.  The spin parameter spins the child around the attachment anchor axis.  
//   .
//   For a path_sweep() with no scaling, if you give a location or index that is exactly at one of the sections the normal will be in the plane
//   of the section.  In the general case if you give a location in between sections the normal will be normal to the facet.  If you
//   give a location at a section in the general case the normal will be the average of the normals of the two adjacent facets.  
//   For twisted or other complicated sweeps the normals may not be accurate.  If you need accurate normals for such shapes, you must
//   use the anchors for the VNF swept shape directly---it is a tradeoff between easy specification of the anchor location on the
//   swept object, which may be very difficult with direct anchors, and accuracy of the normal.
//   .
//   For closed sweeps the index will wrap around and can be positive or negative.  For sweeps that are not closed the index must
//   be positive and no longer than the length of the path.  In some cases for closed path_sweeps the shape can be a mobius strip
//   and it may take more than one cycle to return to the starting point.  The extra twist will be properly handled in this case.
//   If you construct a mobius strip using the generic {{sweep()}} then information about the amount of twist is not available
//   to `sweep_attach()` so it will not be handled automatically.  
//   .
//   The anchor you give acts as a 2D anchor to the path or region used by the sweep, in the XY plane as that shape appears
//   before it is transformed to form the swept object.  As with {{region()}}, you can control the anchor using `cp` and `atype`, 
//   and you can check the anchors by using the same anchors with {{region()}} in a two dimensional test case.
//   .
//   Note that {{path_sweep2d()}} does not support `sweep_attach()` because it doesn't compute the transform list, which is
//   the input used to calculate the attachment transform.  
// Arguments:
//   anchor = 2d anchor to the shape used in the path_sweep parent
//   frac = position along the path_sweep path as a fraction of total length
//   ---
//   idx = index into the path_sweep path (use instead of frac)
//   len = absolute length along the path_sweep path (use instead of frac)
//   spin = spin the child this amount around the anchor axis.  Default: 0
//   overlap = Amount to lower the shape into the parent.  Default: 0
//   cp = Centerpoint for determining intersection anchors or centering the shape.  Determintes the base of the anchor vector.  Can be "centroid", "mean", "box" or a 2D point.  Default: "centroid"
//   atype = Set to "hull" or "intersect" to select anchor type.  Default: "hull"
// Anchor Types:
//   "hull" = Anchors to the virtual convex hull of the region.
//   "intersect" = Anchors to the outer edge of the region.
// Example(Med,NoAxes,VPT=[4.75027,0.805639,-3.50893],VPR=[66.9,0,219.6],VPD=213.382): This example shows several children positioned at different places on the parent.  The blue cone is positioned using its TOP anchor and is sunk into the parent with overlay.  The three orange cubes show how they rotate to follow the local sweep direction.  
//   function a(h) = arc(points=[[-20,0],[0,h],[20,0]],n=24);
//   shape = concat(
//                  a(2), // bottom
//                  back(6,reverse(a(4))) // top
//           );
//   path = xrot(90,path3d(arc(points=[[-40,0],[0,5],[40,-20]],n=36)));
//   path_sweep(shape,path) {
//       sweep_attach(BACK,BOT,0.2) recolor("red") cyl(d1=5,d2=0,h=8,$fn=12);
//       sweep_attach(BACK,TOP,0.5,overlap=3) recolor("blue") cyl(d1=5,d2=0,h=8,$fn=12);
//       sweep_attach(RIGHT,BOT,idx=15) recolor("orange") cuboid([3,3,5]);
//       sweep_attach(RIGHT,BOT,idx=1) recolor("orange") cuboid([3,3,5]);
//       sweep_attach(RIGHT,BOT,idx=32) recolor("orange") cuboid([3,3,5]);        
//   }
// Example(VPT=[20.7561,8.89872,0.901718],VPR=[32.6,0,338.8],VPD=66.9616,NoAxes): In this example with scaling the objects' normals are not in the plane of the path_sweep sections.  
//   shape = hexagon(r=4);
//   path = xscale(2,arc(r=15, angle=[0,75],n=10));
//   path_sweep(shape,path,scale=3)
//   {  
//      sweep_attach(RIGHT,BOT,0)
//         color_this("red")cuboid([1,1,4]);
//      sweep_attach(RIGHT,BOT,0.5)
//         color_this("blue")cuboid([1,1,4]);
//      sweep_attach(BACK,BOT,1/3)
//         color_this("lightblue")prismoid(3,1,3);
//   }
// Example(Med): This pentagonal torus is a mobius strip.  It takes five times around to return to your starting point.  Here the red box has gone 4.4 times around.  
//   ellipse = xscale(2, p=circle($fn=64, r=3));
//   pentagon = subdivide_path(pentagon(r=1), 30);
//   path_sweep(pentagon, path3d(ellipse),
//              closed=true, twist=360*2/5,symmetry=5)
//     sweep_attach(RIGHT,BOT,4.4) color("red") cuboid([.25,.25,3]);
// Example(VPT=[17.1585,9.05454,50.69],VPR=[67.6,0,64.9],VPD=292.705,NoAxes): Example using {{sweep()}}
//   function f(x) = 3 - 2.5 * x;
//   function r(x) = 2 * 180 * x * x * x;
//   pathstep = 1;
//   height = 100;
//   shape_points = subdivide_path(square(10),40,closed=true);
//   path_transforms = [for (i=[0:pathstep:height]) let(t=i/height) up(i) * scale([f(t),f(t),i]) * zrot(r(t))];
//   sweep(shape_points, path_transforms){
//     sweep_attach(RIGHT,BOT,idx=33)
//           color_this("red")cuboid([5,5,5]);
//     sweep_attach(FWD,BOT,idx=65)
//           color_this("red")cuboid([5,5,5]);
//   }

module sweep_attach(parent, child, frac, idx, pathlen, spin=0, overlap=0, atype="hull", cp="centroid")
{
   $attach_to=child;
   req_children($children);
   dummy =  assert(!is_undef($sweep_transforms), "sweep_attach() must be used as a child of sweep() or path_sweep()")
            assert(in_list(atype, _ANCHOR_TYPES), "Anchor type must be \"hull\" or \"intersect\"")
            assert(num_defined([idx,frac,pathlen])==1, "Must define exactly one of idx, frac and pathlen")
            assert(is_undef(idx) || is_finite(idx), "idx must be a number")
            assert(is_undef(frac) || is_finite(frac), "frac must be a number");
   parmset = is_def(frac) ? "frac"
           : is_def(pathlen) ? "pathlen"
           : "idx";
   path = !is_undef($sweep_path) ? $sweep_path
        : [for(T=$sweep_transforms) apply(T,CTR)];
   seglen = path_segment_lengths(path,closed=$sweep_closed);
   pathcum = [0, each cumsum(seglen)];
   totlen = last(pathcum);
   pathtable = [for(i=idx(pathcum)) [pathcum[i],i]];
   i = _force_int(is_def(idx) ? idx
                :let(
                      pathlen = is_def(pathlen) ? pathlen : frac*totlen
                  )
                  lookup(posmod(pathlen,totlen),pathtable)+len($sweep_transforms)*floor(pathlen/totlen) //floor(abs(pathlen)/totlen)*sign(pathlen)
   );
   twist = is_undef($sweep_twist) ? ident(4)
         : let(
                L = len($sweep_transforms),
                absturn = floor(abs(i)/L),
                turns = floor(i/L) //sign(i)*absturn-1
           )
           zrot(-turns*$sweep_twist);
   geom = attach_geom(region=force_region($sweep_shape), two_d=true, extent=atype=="hull", cp=cp);
   anchor_data = _find_anchor(parent, geom);
   anchor_pos = point3d(anchor_data[1]);
   anchor_dir = point3d(anchor_data[2]);
   length = len($sweep_transforms);
   nextind = is_int(i) ? i>=length-1 && !$sweep_closed ? assert(i==length-1,str(parmset," is too large for the path")) undef
                       : i+1
          : $sweep_closed ?  posmod(ceil(i),length)
          : assert(i<length-1,str(parmset," is too large for the path")) ceil(i);
   prevind = is_int(i) ? i<=0 && !$sweep_closed ? assert(i==0,str(parmset," must be nonnegative")) undef
                       : i-1 
           : $sweep_closed ? floor(i)
           : assert(i>0,str(parmset, " must be nonnegative")) floor(i);
   uniform = is_undef($sweep_scales) ? false
           : let( 
                   slist = [if (is_def(prevind)) select($sweep_scales,prevind),
                            select($sweep_scales,i),
                            if (is_def(nextind)) select($sweep_scales,nextind)]
             )
             all_equal(slist);
   if (is_int(i) && uniform){      // Unscaled integer case: just use the profile transformation
       multmatrix(select($sweep_transforms,i)*twist)
         translate(anchor_pos)
         yrot(spin)
           frame_map(z=point3d(anchor_dir),y=UP) down(overlap) children();
   }
   else if (is_int(i) && all_defined([nextind,prevind])) {      // Scaled integer case, must average two adjacent facets
       frac1 = 0.1*min(seglen[i-1],seglen[i])/seglen[i-1];   // But can't average two facets at ends so exclude that case    
       frac2 = 0.1*min(seglen[i-1],seglen[i])/seglen[i];       
       dirsprev = _find_ps_dir(frac1,prevind,i,twist,anchor_pos,anchor_dir); 
       dirsnext = _find_ps_dir(frac2,i,nextind,twist,anchor_pos,anchor_dir);
       pos = apply($sweep_transforms[i]*twist, anchor_pos);
       mixdir = dirsprev[2]+dirsnext[2];   // Normal direction
       ydir=cross(cross(mixdir, dirsprev[1]+dirsnext[1]),mixdir);  // y direction perpendicular to mixdir
       translate(pos)
         rotate(v=mixdir,a=spin)
         frame_map(y=ydir, z=mixdir)
           down(overlap)
           children();
  }
  else {                       // Non-integer case or scaled integer at the ends: compute directions from single facet
    interp = is_undef(prevind)?0
           : is_undef(nextind)?1
           : i-floor(i);
    dirs = _find_ps_dir(interp,first_defined([prevind,i]),first_defined([nextind,i]),twist,anchor_pos,anchor_dir);
    translate(dirs[0])
        rotate(v=dirs[2],a=spin)
        frame_map(y=dirs[1], z=dirs[2])
        down(overlap) children();
  }
}     

function _force_int(x) = approx(round(x),x) ? round(x) : x;

// This function finds the normal to a facet on the path sweep
// prevind and nextind are the indices into the path, frac is the
// interpolation value bewteen them.
// anchor_pos and anchor_dir are the anchor data for the 2d shape
// Return is [position, ydirection, zdirection], where zdirection
// is normal to the facet.  Note that frac is only needed because
// of the possibility of twist.  

function _find_ps_dir(frac,prevind,nextind,twist,anchor_pos,anchor_dir) =
  let(
      length = len($sweep_transforms),
      prevpos = apply(select($sweep_transforms,prevind)*twist,anchor_pos),
      nextpos = apply(select($sweep_transforms,nextind)*twist,anchor_pos),
      curpos = lerp(prevpos,nextpos,frac),

      prevposdir = apply(select($sweep_transforms,prevind)*twist,anchor_pos+anchor_dir),
      nextposdir = apply(select($sweep_transforms,nextind)*twist,anchor_pos+anchor_dir),
      curposdir = lerp(prevposdir, nextposdir, frac),
      dir = curposdir-curpos,
      
      normal_plane = plane_from_normal(nextpos-prevpos,curpos),
      other_plane = plane3pt(nextpos, prevpos, curposdir),
      normal=plane_intersection(normal_plane, other_plane),
      ndir = unit(normal[1]-normal[0]),
      flip = sign(ndir*dir)
  )
  [curpos, nextpos-prevpos, flip*ndir];






// Section: Functions for resampling and slicing profile lists

// Function: subdivide_and_slice()
// Synopsis: Resample list of paths to have the same point count and interpolate additional paths. 
// SynTags: PathList
// Topics: Paths, Path Subdivision
// See Also: slice_profiles()
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
//   method = method used for calling {{subdivide_path()}}, either `"length"` or `"segment"`.  Default: `"length"`
//   closed = the first and last profile are connected.  Default: false
function subdivide_and_slice(profiles, slices, numpoints, method="length", closed=false) =
  let(
    maxsize = max_length(profiles),
    numpoints = is_undef(numpoints) ? maxsize :
                numpoints == "lcm" ? lcmlist([for(p=profiles) len(p)]) :
                is_num(numpoints) ? round(numpoints) : undef
  )
  assert(is_def(numpoints), "Parameter numpoints must be \"max\", \"lcm\" or a positive number")
  assert(numpoints>=maxsize, "Number of points requested is smaller than largest profile")
  let(fixpoly = [for(poly=profiles) subdivide_path(poly, numpoints,method=method)])
  slice_profiles(fixpoly, slices, closed);



// Function: slice_profiles()
// Synopsis: Linearly interpolates between path profiles.
// SynTags: PathList
// Topics: Paths, Path Subdivision
// See Also: subdivide_and_slice()
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
// Synopsis: Resample a list of rotation operators. 
// SynTags: MatList
// Topics: Matrices, Interpolation, Rotation
// See Also: subdivide_and_slice(), slice_profiles()
// Usage:
//   rlist = rot_resample(rotlist, n, [method=], [twist=], [scale=], [smoothlen=], [long=], [turns=], [closed=])
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
//   In this case n specifies the total number of samples.  If you set method to "count" then you get
//   n samples for each transform.  You can set n to a vector to vary the samples at each step.
// Arguments:
//   rotlist = list of rotation operators in 3d to resample
//   n = Number of rotations to produce as output when method is "length" or number for each transformation if method is "count".  Can be a vector when method is "count"
//   ---
//   method = sampling method, either "length" or "count"
//   twist = scalar or vector giving twist to add overall or at each rotation.  Default: none
//   scale = scalar or vector giving scale factor to add overall or at each rotation.  Default: none
//   smoothlen = amount of smoothing to apply to scaling and twist.  Should be an odd integer.  Default: 1
//   long = resample the "long way" around the rotation, a boolean or list of booleans.  Default: false
//   turns = add extra turns.  If a scalar adds the turns to every rotation, or give a vector.  Default: 0
//   closed = if true then the rotation list is treated as closed.  Default: false
// Example(3D): Resampling the arc from a compound rotation with translations thrown in.
//   tran = rot_resample([ident(4), back(5)*up(4)*xrot(-10)*zrot(-20)*yrot(117,cp=[10,0,0])], n=25);
//   sweep(circle(r=1,$fn=3), tran);
// Example(3D): Applying a scale factor
//   tran = rot_resample([ident(4), back(5)*up(4)*xrot(-10)*zrot(-20)*yrot(117,cp=[10,0,0])], n=25, scale=2);
//   sweep(circle(r=1,$fn=3), tran);
// Example(3D): Applying twist
//   tran = rot_resample([ident(4), back(5)*up(4)*xrot(-10)*zrot(-20)*yrot(117,cp=[10,0,0])], n=25, twist=60);
//   sweep(circle(r=1,$fn=3), tran);
// Example(3D): Going the long way
//   tran = rot_resample([ident(4), back(5)*up(4)*xrot(-10)*zrot(-20)*yrot(117,cp=[10,0,0])], n=25, long=true);
//   sweep(circle(r=1,$fn=3), tran);
// Example(3D): Getting transformations from turtle3d
//   include<BOSL2/turtle3d.scad>
//   tran=turtle3d(["arcsteps",1,"up", 10, "arczrot", 10,170],transforms=true);
//   sweep(circle(r=1,$fn=3),rot_resample(tran, n=40));
// Example(3D): If you specify a larger angle in turtle you need to use the long argument
//   include<BOSL2/turtle3d.scad>
//   tran=turtle3d(["arcsteps",1,"up", 10, "arczrot", 10,270],transforms=true);
//   sweep(circle(r=1,$fn=3),rot_resample(tran, n=40,long=true));
// Example(3D): And if the angle is over 360 you need to add turns to get the right result.  Note long is false when the remaining angle after subtracting full turns is below 180:
//   include<BOSL2/turtle3d.scad>
//   tran=turtle3d(["arcsteps",1,"up", 10, "arczrot", 10,90+360],transforms=true);
//   sweep(circle(r=1,$fn=3),rot_resample(tran, n=40,long=false,turns=1));
// Example(3D): Here the remaining angle is 270, so long must be set to true
//   include<BOSL2/turtle3d.scad>
//   tran=turtle3d(["arcsteps",1,"up", 10, "arczrot", 10,270+360],transforms=true);
//   sweep(circle(r=1,$fn=3),rot_resample(tran, n=40,long=true,turns=1));
// Example(3D): Note the visible line at the scale transition
//   include<BOSL2/turtle3d.scad>
//   tran = turtle3d(["arcsteps",1,"arcup", 10, 90, "arcdown", 10, 90], transforms=true);
//   rtran = rot_resample(tran,200,scale=[1,6]);
//   sweep(circle(1,$fn=32),rtran);
// Example(3D): Observe how using a large smoothlen value eases that transition
//   include<BOSL2/turtle3d.scad>
//   tran = turtle3d(["arcsteps",1,"arcup", 10, 90, "arcdown", 10, 90], transforms=true);
//   rtran = rot_resample(tran,200,scale=[1,6],smoothlen=17);
//   sweep(circle(1,$fn=32),rtran);
// Example(3D): A similar issues can arise with twist, where a "line" is visible at the transition
//   include<BOSL2/turtle3d.scad>
//   tran = turtle3d(["arcsteps", 1, "arcup", 10, 90, "move", 10], transforms=true,state=[1,-.5,0]);
//   rtran = rot_resample(tran,100,twist=[0,60],smoothlen=1);
//   sweep(subdivide_path(rect([3,3]),40),rtran);
// Example(3D): Here's the smoothed twist transition
//   include<BOSL2/turtle3d.scad>
//   tran = turtle3d(["arcsteps", 1, "arcup", 10, 90, "move", 10], transforms=true,state=[1,-.5,0]);
//   rtran = rot_resample(tran,100,twist=[0,60],smoothlen=17);
//   sweep(subdivide_path(rect([3,3]),40),rtran);
// Example(3D): Toothed belt based on a list-comprehension-demos example.  This version has a smoothed twist transition.  Try changing smoothlen to 1 to see the more abrupt transition that occurs without smoothing.
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
function rot_resample(rotlist,n,twist,scale,smoothlen=1,long=false,turns=0,closed=false,method="length") =
    assert(is_int(smoothlen) && smoothlen>0 && smoothlen%2==1, "smoothlen must be a positive odd integer")
    assert(method=="length" || method=="count")
    let(tcount = len(rotlist) + (closed?0:-1))
    assert(method=="count" || is_int(n), "n must be an integer when method is \"length\"")
    assert(is_int(n) || is_vector(n,tcount), str("n must be scalar or vector with length ",tcount))
    let(
          count = method=="length" ? (closed ? n+1 : n)
                                   : (is_vector(n) ? sum(n) : tcount*n)+1  //(closed?0:1)
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
                  ? let( n = force_list(n,tcount))
                    [for(N=n) lerpn(0,1,N,endpoint=false)]
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
              shifted = list_rotate(big,i),
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
      newsmall = list_rotate(repeat_entries(small,unique_count(smallmap)[1]),smallshift),
      newbig = list_rotate(repeat_entries(map_poly[1],unique_count(bigmap)[1]),bigshift)
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
      new0 = list_rotate(repeat_entries(poly1,unique_count(map[0])[1]),shift0),
      new1 = list_rotate(repeat_entries(poly2,unique_count(map[1])[1]),shift1)
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
        newbig = list_rotate(big, shift),
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
// Synopsis: Create vertex association to control how {{skin()}} links vertices. 
// SynTags: PathList
// Topics: Extrusion, Skinning, Paths
// See Also: skin()
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
    assert(len(cursplit) == 0 || max(cursplit)<polylen && min(curpoly)>=0,
           str("Split ",cursplit," at polygon ",curpoly," has invalid vertices.  Must be in [0:",polylen-1,"]"))
    len(cursplit)==0 ? associate_vertices(polygons,split,curpoly+1) :
    let(
      splitindex = sort(concat(count(polylen), cursplit)),
      newpoly = [for(i=[0:len(polygons)-1]) i<=curpoly ? select(polygons[i],splitindex) : polygons[i]]
    )
   associate_vertices(newpoly, split, curpoly+1);



// DefineHeader(Table;Headers=Texture Name|Type|Description): Texture Values

// Section: Texturing
//   Some operations are able to add texture to the objects they create.  A texture can be any regularly repeated variation in the height of the surface.
//   To define a texture you need to specify how the height should vary over a rectangular block that will be repeated to tile the object.  Because textures
//   are based on rectangular tiling, this means adding textures to curved shapes may result in distortion of the basic texture unit.  For example, if you
//   texture a cone, the scale of the texture will be larger at the wide end of the cone and smaller at the narrower end of the cone.
//   .
//   You can specify a texture using two methods: a height field or a VNF.  For each method you also must specify the scale of the texture, which
//   gives the size of the rectangular unit in your object that will correspond to one texture tile.  Note that this scale does not preserve
//   aspect ratio: you can stretch the texture as desired.  
// Subsection: Height Field Texture Maps
//   The simplest way to specify a texture map is to give a 2d array of
//   height values which specify the height of the texture on a grid.
//   Values in the height field should range from 0 to 1.  A zero height
//   in the height field corresponds to the height of the surface and 1
//   the highest point in the texture above the surface being textured.
// Figure(2D,Big,NoScales,VPT=[6.21418,0.242814,0],VPD=28.8248,VPR=[0,0,0]): Here is a 2d texture described by a "grid" that just contains a single row.  Such a texture can be used to create ribbing. The texture is `[[0, 1, 1, 0]]`, and the fixture shows three repetitions of the basic texture unit.
//   ftex1 = [0,1,1,0,0];
//   stroke( transpose([count(5),ftex1]), dots=true, dots_width=3,width=.05);
//   right(4)stroke( transpose([count(5),ftex1]), dots=true, width=.05,dots_color="red",color="blue",dots_width=3);
//   right(8)stroke( transpose([count(5),ftex1]), dots=true, dots_width=3,width=.05);
//   stroke([[4,-.3],[8,-.3]],width=.05,endcaps="arrow2",color="black");
//   move([6,-.4])color("black")text("Texture Size", size=0.3,anchor=BACK);
// Continues:
//   Line segments connect the dots within the texture and also the dots between adjacent texture tiles.
//   The size of the texture (specified with `tex_size`) includes the segment that connects the tile to the next one.
//   Note that the grid is always uniformly spaced.
//   By default textures are created with unit depth, meaning that the top surface
//   of the texture is 1 unit above the surface being textured, assuming that the texture
//   is correctly designed to span the range from 0 to 1.  The `tex_depth` parameter can adjust
//   this dimension of a texture without changing anything else, and setting `tex_depth` negative
//   will invert a texture.
// Figure(2D,Big,NoScales,VPR=[0,0,0],VPT=[6.86022,-1.91238,0],VPD=28.8248):
//   ftex1 = [0,1,1,0,0];
//   left(0)color(.6*[1,1,1])rect([12,1],anchor=BACK+LEFT);
//   stroke( transpose([count(5),ftex1]), dots=true, dots_width=3,width=.05);
//   polygon( transpose([count(5),ftex1]));
//   right(4){stroke( transpose([count(5),ftex1]), dots=true, width=.05,dots_width=3);
//        polygon( transpose([count(5),ftex1]));
//        }
//   right(8){stroke( transpose([count(5),ftex1]), dots=true, dots_width=3,width=.05);
//             polygon( transpose([count(5),ftex1]));
//        }
//   stroke([[12.25,0],[12.25,1]],width=.05,endcaps="arrow2",color="black");
//   move([12.35,.5])color("black")text("Depth=1", size=0.3,anchor=LEFT);
//   fwd(4){
//   left(0)color(.6*[1,1,1])rect([12,1],anchor=BACK+LEFT);
//   stroke( transpose([count(5),2*ftex1]), dots=true, dots_width=3,width=.05);
//   polygon( transpose([count(5),2*ftex1]));
//   right(4){stroke( transpose([count(5),2*ftex1]), dots=true, width=.05,dots_width=3);
//        polygon( transpose([count(5),2*ftex1]));
//        }
//   right(8){stroke( transpose([count(5),2*ftex1]), dots=true, dots_width=3,width=.05);
//             polygon( transpose([count(5),2*ftex1]));
//        }
//   stroke([[12.25,0],[12.25,2]],width=.05,endcaps="arrow2",color="black");
//   move([12.35,1])color("black")text("Depth=2", size=0.3,anchor=LEFT);
//   }
// Continues:
//   If you want to keep the texture the same size but make the slope
//   steeper you need to add more points to make the uniform grid fine enough
//   to represent the slope you want.  This means that creating sharp edges
//   can require a large number of points, resulting in longer run times.
//   When using the built-in textures you can control the number of points
//   using the `n=` argument to {{texture()}}.  
// Figure(2D,Big,NoScales,VPT=[6.21418,0.242814,0],VPD=28.8248,VPR=[0,0,0]):  
//   ftex2 = xscale(4/11,transpose([count(12),[0,1,1,1,1,1,1,1,1,1,0,0]]));
//   stroke( ftex2, dots=true, dots_width=3,width=.05);
//   right(4)stroke( ftex2, dots=true, width=.05,dots_color="red",color="blue",dots_width=3);
//   right(8)stroke( ftex2, dots=true, dots_width=3,width=.05);
//   stroke([[4,-.3],[8,-.3]],width=.05,endcaps="arrow2",color="black");
//   move([6,-.4])color("black")text("Texture Size", size=0.3,anchor=BACK);
// Continues:
//   A more serious limitation of height field textures is that some shapes, such as hexagons or circles, cannot be accurately represented because
//   their points don't fall on any grid.  Trying to create such shapes is difficult and will require many points to approximate the
//   true point positions for the desired shape.  This will make the texture slow to compute.  
//   Another serious limitation is more subtle.  In the 2D examples above, it is obvious how to connect the
//   dots together.  But in 3D example we need to triangulate the points on a grid, and this triangulation is not unique.
//   The `style` argument lets you specify how the points are triangulated using the styles supported by {{vnf_vertex_array()}}.
//   In the example below we have expanded the 2D example into 3D:
//   ```openscad
//       [[0,0,0,0],
//        [0,1,1,0],
//        [0,1,1,0],
//        [0,0,0,0]]
//   ```
//   and we show the 3D triangulations produced by the different styles:
// Figure(3D,Big,NoAxes,VPR=[45.5,0,18.2],VPT=[2.3442,-6.25815,3.91529],VPD=35.5861):
//   tex = [
//          [0,0,0,0,0],
//          [0,1,1,0,0],
//          [0,1,1,0,0],
//          [0,0,0,0,0],
//          [0,0,0,0,0]       
//         ];
//   hm = [for(i=[0:4]) [for(j=[0:4]) [i,-j,tex[i][j]]]];      
//   types = ["quincunx", "convex", "concave","min_area", "default","alt","min_edge"]; 
//   grid_copies(spacing=5, n=[4,2]){
//     let(s = types[$row*4+$col]){
//       if (is_def(s)){
//       vnf_polyhedron(vnf_vertex_array(hm,style=s));
//       if ($row==1)
//         back(.8)right(2)rotate($vpr)color("black")text(s,size=.5,anchor=CENTER);
//       else
//         fwd(4.7)right(2)rotate($vpr)color("black")text(s,size=.5,anchor=CENTER);
//       }
//     }
//   }  
// Continues:
//   Note that of the seven available styles, five produce a different result.  There may exist some concave shape where none of the styles
//   produce the right result everywhere on the shape.  If this happens it would be another limitation of height field textures.  (If you have an
//   example of such a texture and shape please let us know!)
// Subsection: VNF Textures
//   VNF textures overcome all of the limitations of height field textures, but with two costs.  They can be more difficult to construct than
//   a simple array of height values, and they are significantly slower to compute for a tile with the same number of points.  Note, however, for
//   textures that don't neatly lie on a grid, a VNF tile will be more efficient than a finely sampled height field.  With VNF textures you can create
//   textures that have disconnected components, or concavities that cannot be expressed with a single valued height map.  However, you can also
//   create invalid textures that fail to close at the ends, so care is required to ensure that your resulting shape is valid.  
//   .
//   A VNF texture is defined by defining the texture tile with a VNF whose projection onto the XY plane is contained in the unit square [0,1] x [0,1] so
//   that the VNF can be tiled.   The VNF is tiled without a gap, matching the edges, so the vertices along corresponding edges must match to make a
//   consistent triangulation possible.  The VNF cannot have any X or Y values outside the interval [0,1].  If you want a valid polyhedron
//   that OpenSCAD will render then you need to take care with edges of the tiles that correspond to endcap faces in the textured object.
//   So for example, in a linear sweep, the top and bottom edges of tiles end abruptly to form the end cap of the object.  You can make a valid object
//   in two ways.  One way is to create a tile with a single, complete edge along Y=0, and of course a corresponding edges along Y=1.  The second way
//   to make a valid object is to have no points at all on the Y=0 line, and of course none on Y=1.  In this case, the resulting texture produces
//   a collection of disconnected objects.  Note that the Z coordinates of your tile can be anything, but for the dimensional settings on textures
//   to work intuitively, you should construct your tile so that Z ranges from 0 to 1.
// Figure(3D): This is the "hexgrid" VNF tile, which creates a hexagonal grid texture, something which doesn't work well with a height field because the edges of the hexagon don't align with the grid.  Note how the tile ranges between 0 and 1 in both X, Y and Z.  In fact, to get a proper aspect ratio in your final texture you need to use the `tex_size` parameter to introduct a sqrt(3) scale factor.  
//   tex = texture("hex_grid");
//   vnf_polyhedron(tex);
// Figure(3D): This is an example of a tile that has no edges at the top or bottom, so it creates disconnected rings.  See {{linear_sweep()}} for examples showing this tile in use.
//   shape = skin([
//                 rect(2/5),
//                 rect(2/3),
//                 rect(2/5)
//                ],
//                z=[0,1/2,1],
//                slices=0,
//                caps=false);
//   tile = move([0,1/2,2/3],yrot(90,shape));
//   vnf_polyhedron(tile);
// Continues:
//   A VNF texture provides a flat structure.  In order to apply this structure to a cylinder or other curved object, the VNF must be sliced
//   and "folded" so it can follow the curve.  This folding is controlled by the `tex_samples` parameter to {{cyl()}}, {{linear_sweep()}},
//   and {{rotate_sweep()}}.  Note that you specify it when you **use** the texture, not when you create it.  This differs from height
//   fields, where the analogous parameter is the `n=` parameter of the {{texture()}} function.  When `tex_samples` is too small, only the
//   points given in the VNF will follow the surface, resulting in a blocky look and geometrical artifacts.  
// Figure(3D,Med,NoAxes): On the left the `tex_samples` value is small and the texture is blocky.  On the right, the default value of 8 allows a reasonable fit to the cylinder. 
//   xdistribute(spacing=5){
//      cyl(d=10/PI, h=5, chamfer=0,
//         texture=texture("bricks_vnf"), tex_samples=1, tex_reps=[6,3], tex_depth=.2);
//      cyl(d=10/PI, h=5, chamfer=0,
//         texture=texture("bricks_vnf"), tex_samples=8, tex_reps=[6,3], tex_depth=.2);
//   }
// Continues:
//   Note that when the VNF is sliced,
//   extra points can be introduced in the interior of faces leading to unexpected irregularities in the textures, which appear
//   as extra triangles.  These artifacts can be minimized by making the VNF texture's faces as large as possible rather than using
//   a triangulated VNF, but depending on the specific VNF texture, it may be impossible to entirely eliminate them.
// Figure(3D,Big,NoAxes,VPR=[140.9,0,345.7],VPT=[9.48289,-0.88709,5.7837],VPD=39.5401): The left shows a normal bricks_vnf texture.  The right shows a texture that was first passed through {{vnf_triangulate()}}.  Note the extra triangle artifacts visible at the ends on the brick faces.
//   tex = texture("bricks_vnf");
//   cyl(d=10,h=15,texture=tex, tex_reps=[4,2],tex_samples=5,rounding=2);
//   up(7)fwd(-3)right(15)cyl(d=10,h=15,texture=vnf_triangulate(tex), tex_reps=[4,2],tex_samples=5,rounding=2);


// Function: texture()
// Topics: Textures, Knurling
// Synopsis: Produce a standard texture. 
// Topics: Extrusion, Textures
// See Also: linear_sweep(), rotate_sweep(), heightfield(), cylindrical_heightfield()
// Usage:
//   tx = texture(tex, [n=], [inset=], [gap=], [roughness=]);
// Description:
//   Given a texture name, returns a texture.  Textures can come in two varieties:
//   - Heightfield textures which are 2D arrays of scalars.  These are usually faster to render, but can be less precise and prone to triangulation errors.  The table below gives the recommended style for the best triangulation.  If results are still incorrect, switch to the similar VNF tile by adding the "_vnf" suffix.
//   - VNF Tile textures, which are VNFs that cover the unit square [0,0] x [1,1].  These tend to be slower to render, but allow greater flexibility and precision for shapes that don't align with a grid.
//   .
//   In the descriptions below, imagine the textures positioned on the XY plane, so "horizontal" refers to the "sideways" dimensions of the texture and
//   "up" and "down" refer to the depth dimension, perpendicular to the surface being textured.  If a texture is placed on a cylinder the "depth" will become the radial direction and the "horizontal"
//   direction will be the vertical and tangential directions on the cylindrical surface.  All horizontal dimensions for VNF textures are relative to the unit square
//   on which the textures are defined, so a value of 0.25 for a gap or border will refer to 1/4 of the texture's full length and/or width.  All supported textures appear below in the examples.  
// Arguments:
//   tex = The name of the texture to get.
//   ---
//   n = The number of samples to use for defining a heightfield texture.  Depending on the texture, result will be either n x n or 1 x n.  Not allowed for VNF textures.  See the `tex_samples` argument to {{cyl()}}, {{linear_sweep()}} and {{rotate_sweep()}} for controlling the sampling of VNF textures.
//   border = The size of a border region on some VNF tile textures.  Generally between 0 and 0.5.
//   gap = The gap between logically distinct parts of some VNF tiles.  (ie: gap between bricks, gap between truncated ribs, etc.)
//   roughness = The amount of roughness used on the surface of some heightfield textures.  Generally between 0 and 0.5.
// Example(3D): **"bricks"** (Heightfield) = A brick-wall pattern.  Giving `n=` sets the number of heightfield samples to `n x n`.  Default: 24.  Giving `roughness=` adds a level of height randomization to add roughness to the texture.  Default: 0.05.  Use `style="convex"`.
//   tex = texture("bricks");
//   linear_sweep(
//       rect(30), texture=tex, h=30,
//       tex_size=[10,10]
//   );
// Example(3D): **"bricks_vnf"** (VNF) = VNF version of "bricks".  Giving `gap=` sets the "mortar" gap between adjacent bricks, default 0.05.  Giving `border=` specifies that the top face of the brick is smaller than the bottom of the brick by `border` on each of the four sides.  If `gap` is zero then a `border` value close to 0.5 will cause bricks to come to a sharp pointed edge, with just a tiny flat top surface.  Note that `gap+border` must be strictly smaller than 0.5.   Default is `border=0.05`.  
//   tex = texture("bricks_vnf");
//   linear_sweep(
//       rect(30), texture=tex, h=30,
//       tex_size=[10,10]
//   );
// Example(3D): "bricks_vnf" texture with large border. 
//   tex = texture("bricks_vnf",border=0.25);
//   linear_sweep(
//       rect(30), texture=tex, h=30,
//       tex_size=[10,10]
//   );
// Example(3D,VPR=[84.4,0,4.7],VPT=[2.44496,6.53317,14.6135],VPD = 126): **"checkers"** (VNF) = A pattern of alternating checkerboard squares.  Giving `border=` specifies that the top face of the checker surface is smaller than the bottom by `border` on each of the four sides.  As `border` approaches 0.5 the tops come to sharp corners.  You must set `border` strictly between 0 and 0.5.  Default: 0.05.
//   tex = texture("checkers");
//   linear_sweep(
//       rect(30), texture=tex, h=30,
//       tex_size=[10,10]
//   );
// Example(3D,VPR=[84.4,0,4.7],VPT=[2.44496,6.53317,14.6135],VPD = 126): "checkers" texture with large border.  
//   tex = texture("checkers",border=0.25);
//   linear_sweep(
//       rect(30), texture=tex, h=30,
//       tex_size=[10,10]
//   );
// Example(3D): **"cones"** (VNF) = Raised conical spikes.  Specify `$fn` to set the number of segments on the cone (will be rounded to a multiple of 4).  The default is `$fn=16`.  Note that `$fa` and `$fs` are ignored, since the scale of the texture is unknown at the time of definition.  Giving `border=` specifies the horizontal border width between the edge of the tile and the base of the cone.  The `border` value must be nonnegative and smaller than 0.5.  Default: 0.
//   tex = texture("cones", $fn=16);
//   linear_sweep(
//       rect(30), texture=tex, h=30, tex_depth=3,
//       tex_size=[10,10]
//   );
// Example(3D): **"cubes"** (VNF) = Corner-cubes texture.  This texture needs to be scaled in vertically by sqrt(3) to have its correct aspect
//   tex = texture("cubes");
//   linear_sweep(
//       rect(30), texture=tex, h=30,
//       tex_size=[10,10]
//   );
// Example(3D): "cubes" texture at the correct scale.  
//   tex = texture("cubes");
//   linear_sweep(
//       rect(30), texture=tex, h=20*sqrt(3), tex_depth=3,
//       tex_size=[10,10*sqrt(3)]
//   );
// Example(3D): **"diamonds"** (Heightfield) = Four-sided pyramid with the corners of the base aligned with the axes.  Compare to "pyramids".  Useful for knurling.  Giving `n=` sets the number of heightfield samples to `n x n`. Default: 2.  Use `style="concave"` for pointed bumps, or `style="default"` or `style="alt"` for a diagonal ribs.  
//   tex = texture("diamonds");
//   linear_sweep(
//       rect(30), texture=tex, h=30,
//       tex_size=[10,10], style="concave"
//   );
// Example(3D): "diamonds" texture can give diagonal ribbing with "default" style. 
//   tex = texture("diamonds");
//   linear_sweep(
//       rect(30), texture=tex, h=30,
//       tex_size=[10,10], style="default"
//   );
// Example(3D): "diamonds" texture gives diagonal ribbing the other direction with "alt" style.  
//   tex = texture("diamonds");
//   linear_sweep(
//       rect(30), texture=tex, h=30,
//       tex_size=[10,10], style="alt"
//   );
// Example(3D): **"diamonds_vnf"** (VNF) = VNF version of "diamonds".
//   tex = texture("diamonds_vnf");
//   linear_sweep(
//       rect(30), texture=tex, h=30,
//       tex_size=[10,10]
//   );
// Example(3D): **"dimples"** (VNF) = Round divots.  Specify `$fn` to set the number of segments on the dimples (will be rounded to a multiple of 4).  The default is `$fn=16`.  Note that `$fa` and `$fs` are ignored, since the scale of the texture is unknown at the time of definition.  Giving `border=` specifies the horizontal width of the flat border region between the tile edges and the edge of the dimple.  Must be nonnegative and strictly less than 0.5.  Default: 0.05.  
//   tex = texture("dimples", $fn=16);
//   linear_sweep(
//       rect(30), texture=tex, h=30, 
//       tex_size=[10,10]
//   );
// Example(3D): **"dots"** (VNF) = Raised round bumps.  Specify `$fn` to set the number of segments on the dots (will be rounded to a multiple of 4).  The default is `$fn=16`.  Note that `$fa` and `$fs` are ignored, since the scale of the texture is unknown at the time of definition.  Giving `border=` specifies the horizontal width of the flat border region between the tile edge and the edge of the dots.  Must be nonnegative and strictly less than 0.5.  Default: 0.05.
//   tex = texture("dots", $fn=16);
//   linear_sweep(
//       rect(30), texture=tex, h=30,
//       tex_size=[10,10]
//   );
// Example(3D): **"hex_grid"** (VNF) = A hexagonal grid defined by V-grove borders.  Giving `border=` specifies that the top face of the hexagon is smaller than the bottom by `border` on the left and right sides.  This means the V-groove top width for grooves running parallel to the Y axis will be double the border value.  If the texture is scaled in the Y direction by sqrt(3) then the groove will be uniform on all six sides of the hexagon.  Border must be strictly between 0 and 0.5, default: 0.1.
//   tex = texture("hex_grid");
//   linear_sweep(
//       rect(30), texture=tex, h=30,
//       tex_size=[10,10]
//   );
// Example(3D): "hex_grid" texture with large border
//   tex = texture("hex_grid", border=0.4);
//   linear_sweep(
//       rect(30), texture=tex, h=30,
//       tex_size=[10,10]
//   );
// Example(3D): "hex_grid" scaled in Y by sqrt(3) so hexagons are regular and grooves are all the same width.  Note height of cube is also scaled so tile fits without being automatically adjusted to fit, ruining our choice of scale.
//   tex = texture("hex_grid",border=.07);
//   linear_sweep(
//       rect(30), texture=tex, h=quantup(30,10*sqrt(3)),
//       tex_size=[10,10*sqrt(3)], tex_depth=3
//   );
// Example(3D): "hex_grid" texture, with approximate scaling because 17 is close to sqrt(3) times 10.
//   tex = texture("hex_grid");
//   linear_sweep(
//       rect(30), texture=tex, h=34,
//       tex_size=[10,17]
//   );
// Example(3D): **"hills"** (Heightfield) = Wavy sine-wave hills and valleys,  Giving `n=` sets the number of heightfield samples to `n` x `n`.  Default: 12.  Set `style="quincunx"`.
//   tex = texture("hills");
//   linear_sweep(
//       rect(30), texture=tex, h=30,
//       tex_size=[10,10], style="quincunx"
//   );
// Example(3D): **"pyramids"** (Heightfield) = Four-sided pyramid with the edges of the base aligned with the axess.  Compare to "diamonds". Useful for knurling.  Giving `n=` sets the number of heightfield samples to `n` by `n`. Default: 2. Set style to "convex".  Note that style="concave" or style="min_edge" produce mini-diamonds with flat squares in between.
//   tex = texture("pyramids");
//   linear_sweep(
//       rect(30), texture=tex, h=30,
//       tex_size=[10,10], style="convex"
//   );
// Example(3D): "pyramids" texture, with "concave" produces a mini-diamond texture.  Note that "min_edge" also gives this result.
//   tex = texture("pyramids");
//   linear_sweep(
//       rect(30), texture=tex, h=30,
//       tex_size=[10,10], style="concave"
//   );
// Example(3D): **"pyramids_vnf"** (VNF) = VNF version of "pyramids".
//   tex = texture("pyramids_vnf");
//   linear_sweep(
//       rect(30), texture=tex, h=30,
//       tex_size=[10,10]
//   );
// Example(3D): **"ribs"** (Heightfield) = Vertically aligned triangular ribs.  Giving `n=` sets the number of heightfield samples to `n` by 1.  Default: 2.  The choice of style does not matter.
//   tex = texture("ribs");
//   linear_sweep(
//       rect(30), texture=tex, h=30, tex_depth=3,
//       tex_size=[10,10], style="concave"
//   );
// Example(3D): **"rough"** (Heightfield) = A pseudo-randomized rough texture.  Giving `n=` sets the number of heightfield samples to `n` by `n`.  Default: 32.  The `roughness=` parameter specifies the height of the random texture.  Default: 0.2.
//   tex = texture("rough");
//   linear_sweep(
//       rect(30), texture=tex, h=30,
//       tex_size=[10,10], style="min_edge"
//   );
// Example(3D): **"tri_grid"** (VNF) = A triangular grid defined by V-groove borders  Giving `border=` specifies that the top face of the triangular surface is smaller than the bottom by `border` along the horizontal edges (parallel to the X axis).  This means the V-groove top width of the grooves parallel to the X axis will be double the border value.  (The other grooves are wider.) If the tile is scaled in the Y direction by sqrt(3) then the groove will be uniform on the three sides of the triangle.  The border must be strictly between 0 and 1/6, default: 0.05.
//   tex = texture("tri_grid");
//   linear_sweep(
//       rect(30), texture=tex, h=30,
//       tex_size=[10,10]
//   );
// Example(3D): "tri_grid" texture with large border.  (Max border for tri_grid is 1/6.)  
//   tex = texture("tri_grid",border=.12);
//   linear_sweep(
//       rect(30), texture=tex, h=30,
//       tex_size=[10,10]
//   );
// Example(3D): "tri_grid" texture scaled in Y by sqrt(3) so triangles are equilateral and grooves are all the same width.  Note we have to ensure the height evenly fits the scaled texture tiles.
//   tex = texture("tri_grid",border=.04);
//   linear_sweep(
//       rect(30), texture=tex, h=quantup(30,10*sqrt(3)),
//       tex_size=[10,10*sqrt(3)], tex_depth=3
//   );
// Example(3D): "tri_grid" texture.  Here scale makes Y approximately sqrt(3) larger than X so triangles are close to equilateral.
//   tex = texture("tri_grid");
//   linear_sweep(
//       rect(30), texture=tex, h=34,
//       tex_size=[10,17]
//   );
// Example(3D): **"trunc_diamonds"** (VNF) = Truncated diamonds, four-sided pyramids with the base corners aligned with the axes and the top cut off.  Or you can interpret it as V-groove lines at 45º angles.  Giving `border=` specifies that the width and height of the top surface of the diamond are smaller by `border` at the left, right, top and bottom.  The border is measured in the **horizontal** direction.  This means the V-groove width will be sqrt(2) times the border value.  The border must be strictly between 0 and sqrt(2)/4, which is about 0.35.  Default: 0.1.
//   tex = texture("trunc_diamonds");
//   linear_sweep(
//       rect(30), texture=tex, h=30,
//       tex_size=[10,10]
//   );
// Example(3D): "trunc_diamonds" texture with large border. 
//   tex = texture("trunc_diamonds",border=.25);
//   linear_sweep(
//       rect(30), texture=tex, h=30,
//       tex_size=[10,10]
//   );
// Example(3D): **"trunc_pyramids"** (Heightfield) = Truncated pyramids, four sided pyramids with the base edges aligned to the axes and the top cut off.  Giving `n=` sets the number of heightfield samples to `n` by `n`.  Default: 6.  Set `style="convex"`.
//   tex = texture("trunc_pyramids");
//   linear_sweep(
//       rect(30), texture=tex, h=30,
//       tex_size=[10,10], style="convex"
//   );
// Example(3D): **"trunc_pyramids_vnf"** (VNF) = Truncated pyramids, four sided pyramids with the base edges aligned to the axes and the top cut off.  You can also regard this as a grid of V-grooves.  Giving `border=` specifies that the top face is smaller than the top by `border` on all four sides.  This means the V-groove top width will be double the border value.  The border must be strictly between 0 and 0.5.  Default: 0.1.
//   tex = texture("trunc_pyramids_vnf");
//   linear_sweep(
//       rect(30), texture=tex, h=30,
//       tex_size=[10,10]
//   );
// Example(3D): "trunc_pyramids_vnf" texture with large border
//   tex = texture("trunc_pyramids_vnf", border=.4);
//   linear_sweep(
//       rect(30), texture=tex, h=30,
//       tex_size=[10,10]
//   );
// Example(3D): **"trunc_ribs"** (Heightfield) = Truncated ribs.  Vertically aligned triangular ribs with the tops cut off, and with rib separation equal to the width of the flat tops.  Giving `n=` sets the number of heightfield samples to `n` by `1`.  Default: 4.  The style does not matter.
//   tex = texture("trunc_ribs");
//   linear_sweep(
//       rect(30), h=30, texture=tex,
//       tex_depth=3, tex_size=[10,10],
//       style="concave"
//   );
// Example(3D): **"trunc_ribs_vnf"** (VNF) = Vertically aligned triangular ribs with the tops cut off.  Giving `gap=` sets the bottom gap between ribs.  Giving `border=` specifies that the top rib face is smaller than its base by `border` on both the left and right sides.  The gap measures the flat part between ribs and the border the width of the sloping portion. In order to fit, gap+2*border must be less than 1.  (This is because the gap is counted once but the border counts on both sides.)  Defaults: gap=1/4, border=1/4.
//   tex = texture("trunc_ribs_vnf", gap=0.25, border=1/6);
//   linear_sweep(
//       rect(30), h=30, texture=tex,
//       tex_depth=3, tex_size=[10,10]
//   );
// Example(3D): **"wave_ribs"** (Heightfield) = Vertically aligned wavy ribs.  Giving `n=` sets the number of heightfield samples to `n` by `1`.  Default: 8.  The style does not matter.  
//   tex = texture("wave_ribs");
//   linear_sweep(
//       rect(30), h=30, texture=tex, 
//       tex_size=[10,10], tex_depth=3, style="concave"
//   );


function _tex_fn_default() = 16;

__vnf_no_n_mesg=" texture is a VNF so it does not accept n.  Set sample rate for VNF textures using the tex_samples parameter to cyl(), linear_sweep() or rotate_sweep().";

function texture(tex, n, border, gap, roughness, inset) =
    assert(num_defined([border,inset])<2, "In texture() the 'inset' parameter has been replaced by 'border'.  You cannot give both parameters.")
    let(
        border = is_def(inset)?echo("In texture() the argument 'inset' has been deprecated and will be removed.  Use 'border' instead")
                               inset
                              :border
    )
    assert(is_undef(n) || all_positive([n]), "n must be a positive value if given")
    assert(is_undef(border) || is_finite(border), "border must be a number if given")
    assert(is_undef(gap) || is_finite(gap), "gap must be a number if given")
    assert(is_undef(roughness) || all_nonnegative([roughness]), "roughness must be a nonnegative value if given")  
    tex=="ribs"?
        assert(num_defined([gap, border, roughness])==0, "ribs texture does not accept gap, border or roughness")

        let(
            n = quantup(default(n,2),2)
        ) [[
            each lerpn(1,0,n/2,endpoint=false),
            each lerpn(0,1,n/2,endpoint=false),
        ]] :
    tex=="trunc_ribs"?
        assert(num_defined([gap, border, roughness])==0, "trunc_ribs texture does not accept gap, border or roughness")
        let(
            n = quantup(default(n,4),4)
        ) [[
            each repeat(0,n/4),
            each lerpn(0,1,n/4,endpoint=false),
            each repeat(1,n/4),
            each lerpn(1,0,n/4,endpoint=false),
        ]] :
    tex=="trunc_ribs_vnf"?
        assert(is_undef(n), str(tex,__vnf_no_n_mesg))
        let(
            border = default(border,1/4)*2,
            gap = default(gap,1/4),
            f=echo(gap, border, gap+border, gap+2*border)
        )
        assert(all_nonnegative([border,gap]), "trunc_ribs_vnf texture requires gap>=0 and border>=0")
        assert(gap+border <= 1, "trunc_ribs_vnf texture requires that gap+2*border<=1")
        [
            [
               each move([0.5,0.5], p=path3d(rect([1-gap,1]),0)),
               each move([0.5,0.5], p=path3d(rect([1-gap-border,1]),1)),
               each path3d(square(1)),
            ], [
                [4,7,3,0], [1,2,6,5],
                if (gap+border < 1-EPSILON) [4,5,6,7],
                if (gap > EPSILON) each [[1,9,10,2], [0,3,11,8]],
            ]
        ] :
    tex=="wave_ribs"?
        assert(num_defined([gap, border, roughness])==0, "wave_ribs texture does not accept gap, border or roughness")  
        let(
            n = max(6,default(n,8))
        ) [[
            for(a=[0:360/n:360-EPSILON])
            (cos(a)+1)/2
        ]] :
    tex=="diamonds"?
        assert(num_defined([gap, border, roughness])==0, "diamonds texture does not accept gap, border or roughness")  
        let(
            n = quantup(default(n,2),2)
        ) [
            let(
                path = [
                    each lerpn(0,1,n/2,endpoint=false),
                    each lerpn(1,0,n/2,endpoint=false),
                ]
            )
            for (i=[0:1:n-1]) [
                for (j=[0:1:n-1]) min(
                    select(path,i+j),
                    select(path,i-j)
                )
            ],
        ] :
    tex=="diamonds_vnf"?
        assert(is_undef(n), str(tex,__vnf_no_n_mesg))
        assert(num_defined([gap, border, roughness])==0, "diamonds_vnf texture does not accept gap, border or roughness")
        [
            [
                [0,   1, 1], [1/2,   1, 0], [1,   1, 1],
                [0, 1/2, 0], [1/2, 1/2, 1], [1, 1/2, 0],
                [0,   0, 1], [1/2,   0, 0], [1,   0, 1],
            ], [
                [0,1,3], [2,5,1], [8,7,5], [6,3,7],
                [1,5,4], [5,7,4], [7,3,4], [4,3,1],
            ]
        ] :
    tex=="pyramids"?
        assert(num_defined([gap, border, roughness])==0, "pyramids texture does not accept gap, border or roughness")
        let(
            n = quantup(default(n,2),2)
        ) [
            for (i = [0:1:n-1]) [
                for (j = [0:1:n-1])
                1 - (max(abs(i-n/2), abs(j-n/2)) / (n/2))
            ]
        ] :
    tex=="pyramids_vnf"?
        assert(is_undef(n), str(tex,__vnf_no_n_mesg))
        assert(num_defined([gap, border, roughness])==0, "pyramids_vnf texture does not accept gap, border or roughness")  
        [
            [ [0,1,0], [1,1,0], [1/2,1/2,1], [0,0,0], [1,0,0] ],
            [ [2,0,1], [2,1,4], [2,4,3], [2,3,0] ]
        ] :
    tex=="trunc_pyramids"?
        assert(num_defined([gap, border, roughness])==0, "trunc_pyramids texture does not accept gap, border or roughness")  
        let(
            n = quantup(default(n,6),3)
        ) [
            for (i = [0:1:n-1]) [
                for (j = [0:1:n-1])
                (1 - (max(n/6, abs(i-n/2), abs(j-n/2)) / (n/2))) * 1.5
            ]
        ] :
    tex=="trunc_pyramids_vnf"?
        assert(is_undef(n), str(tex,__vnf_no_n_mesg))
        assert(num_defined([gap, roughness])==0, "trunc_pyramids_vnf texture does not accept gap, or roughness")
        let(
            border = default(border,0.1)
        )
        assert(border>0 && border<.5, "trunc_pyramids_vnf texture requires border in (0,0.5)")
        [
            [
                each path3d(square(1)),
                each move([1/2,1/2,1], p=path3d(rect(1-2*border))),
            ], [
                for (i=[0:3])
                    [i, (i+1)%4, (i+1)%4+4,i+4],
                [4,5,6,7]
            ]
        ] :
    tex=="hills"?
        assert(num_defined([gap, border, roughness])==0, "hills texture does not accept gap, border or roughness")  
        let(
            n = default(n,12)
        ) [
            for (a=[0:360/n:359.999]) [
                for (b=[0:360/n:359.999])
                (cos(a)*cos(b)+1)/2
            ]
        ] :
    tex=="bricks"?
        assert(num_defined([gap,border])==0, "bricks texture does not accept gap or border")  
        let(
            n = quantup(default(n,24),2),
            rough = default(roughness,0.05)
        ) [
            for (y = [0:1:n-1])
            rands(-rough/2, rough/2, n, seed=12345+y*678) + [
                for (x = [0:1:n-1])
                (y%(n/2) <= max(1,n/16))? 0 :
                let( even = floor(y/(n/2))%2? n/2 : 0 )
                (x+even) % n <= max(1,n/16)? 0 : 0.5
            ]
        ] :
    tex=="bricks_vnf"?
        assert(is_undef(n), str(tex,__vnf_no_n_mesg))
        assert(num_defined([roughness])==0, "bricks_vnf texture does not accept roughness")
        let(
            border = default(border,0.05),
            gap = default(gap,0.05)
        )
        assert(border>=0,"bricks_vnf texture requires nonnegative border")
        assert(gap>0, "bricks_vnf requires gap greater than 0")
        assert(gap+border<0.5, "bricks_vnf requires gap+border<0.5")
          [
            [
                each path3d(square(1)),
                each move([gap/2, gap/2, 0], p=path3d(square([1-gap, 0.5-gap]))),
                each move([gap/2+border/2, gap/2+border/2, 1], p=path3d(square([1-gap-border, 0.5-gap-border]))),
                each move([0, 0.5+gap/2, 0], p=path3d(square([0.5-gap/2, 0.5-gap]))),
                each move([0, 0.5+gap/2+border/2, 1], p=path3d(square([0.5-gap/2-border/2, 0.5-gap-border]))),
                each move([0.5+gap/2, 0.5+gap/2, 0], p=path3d(square([0.5-gap/2, 0.5-gap]))),
                each move([0.5+gap/2+border/2, 0.5+gap/2+border/2, 1], p=path3d(square([0.5-gap/2-border/2, 0.5-gap-border]))),
            ], [
                [0,4,7,20], [4,8,11,7], [9,8,4,5], [4,0,1,5], [10,9,5,6],
                [20,7,6,13,12,21] ,[2,3,23,22,15,14], [15,19,18,14], [22,23,27,26], [16,19,15,12],[13,6,5,1],
                [26,25,21,22], [8,9,10,11],[7,11,10,6],[17,16,12,13],[22,21,12,15],[16,17,18,19],[24,25,26,27],[25,24,20,21]
            ]
        ] :
    tex=="checkers"?
        assert(is_undef(n), str(tex,__vnf_no_n_mesg))
        assert(num_defined([gap, roughness])==0, "checkers texture does not accept gap, or roughness")
        let(
            border = default(border,0.05)
        )
        assert(border>0 && border<.5, "checkers texture requires border in (0,0.5)")
          [
            [
                each move([0,0], p=path3d(square(0.5-border),1)),
                each move([0,0.5], p=path3d(square(0.5-border))),
                each move([0.5,0], p=path3d(square(0.5-border))),
                each move([0.5,0.5], p=path3d(square(0.5-border),1)),
                [1/2-border/2,1/2-border/2,1/2], [0,1,1], [1/2-border,1,1],
                [1/2,1,0], [1-border,1,0], [1,0,1], [1,1/2-border,1],
                [1,1/2,0], [1,1-border,0], [1,1,1], [1/2-border/2,1-border/2,1/2],
                [1-border/2,1-border/2,1/2], [1-border/2,1/2-border/2,1/2],
            ], [
                for (i=[0:4:12]) each [[i,i+1,i+2,i+3]],
                [10,16,13,12,28,11],[9,0,3,16,10], [11,28,22,21,8],
                [4,7,26,14,13,16], [7,6,17,18,26], [5,4,16,3,2],
                [19,20,27,15,14,26], [20,25,27], [19,26,18],
                [23,28,12,15,27,24], [23,22,28], [24,27,25]
            ]
        ] :
    tex=="cones"?
        assert(is_undef(n),str("To set number of segments on cones use $fn. ", tex,__vnf_no_n_mesg))
        assert(num_defined([gap,roughness])==0, "cones texture does not accept gap or roughness")  
        let(
            border = default(border,0),
            n = $fn > 0 ? quantup($fn,4) : _tex_fn_default()
        )
        assert(border>=0 && border<0.5)
        [
            [
                each move([1/2,1/2], p=path3d(circle(d=1-2*border,$fn=n))),
                [1/2,1/2,1],
                each border>0 ? path3d(subdivide_path(square(1),refine=2,closed=true))
                              : path3d(square(1))
            ], [
                for (i=[0:1:n-1]) [i, (i+1)%n, n],
                if (border>0) for (i=[0:3]) [for(j=[(i+1)*n/4:-1:i*n/4]) j%n,
                                            (2*i+7)%8+n+1,(2*i)%8+n+1, (2*i+1)%8+n+1],
                if (border==0) for (i=[0:3]) [for(j=[(i+1)*n/4:-1:i*n/4]) j%n, i+n+1]
            ]
        ] :
    tex=="cubes"?
        assert(is_undef(n), str(tex,__vnf_no_n_mesg))
        assert(num_defined([gap, border, roughness])==0, "cubes texture does not accept gap, border or roughness")  
        [
            [
                [0,1,1/2], [1,1,1/2], [1/2,5/6,1], [0,4/6,0], [1,4/6,0],
                [1/2,3/6,1/2], [0,2/6,1], [1,2/6,1], [1/2,1/6,0], [0,0,1/2],
                [1,0,1/2],
            ], [
                [0,1,2], [0,2,3], [1,4,2], [2,5,3], [2,4,5],
                [6,3,5], [4,7,5], [7,8,5], [6,5,8], [10,8,7],
                [9,6,8], [10,9,8],
            ]
        ] :
    tex=="trunc_diamonds"?
        assert(is_undef(n), str(tex,__vnf_no_n_mesg))  
        assert(num_defined([gap, roughness])==0, "trunc_diamonds texture does not accept gap or roughness")
        let(
            border = default(border,0.1)/sqrt(2)*2
        )
        assert(border>0 && border<0.5)
        [
            [
                each move([1/2,1/2,0], p=path3d(circle(d=1,$fn=4))),
                each move([1/2,1/2,1], p=path3d(circle(d=1-border*2,$fn=4))),
                for (a=[0:90:359]) each move([1/2,1/2], p=zrot(-a, p=[[1/2,border,1], [border,1/2,1], [1/2,1/2,1]]))
            ], [
                for (i=[0:3]) each let(j=i*3+8) [
                    [i,(i+1)%4,(i+1)%4+4,i+4],
                    [j,j+1,j+2], [i, (i+3)%4,j+1, j], 
                ],
                [4,5,6,7],
            ]
        ] :
    tex=="dimples" || tex=="dots" ?
        assert(is_undef(n),str("To set number of segments on ",tex," use $fn. ", tex,__vnf_no_n_mesg))
        assert(num_defined([gap,roughness])==0, str(tex," texture does not accept gap or roughness"))
        let(
            border = default(border,0.05),
            n = $fn > 0 ? quantup($fn,4) : _tex_fn_default()
        )
        assert(border>=0 && border < 0.5)
        let(
            rows=ceil(n/4),
            r=adj_ang_to_hyp(1/2-border,45),
            dots = tex=="dots",
            cp = [1/2, 1/2, r*sin(45)*(dots?-1:1)],
            sc = 1 / (r - abs(cp.z)),
            uverts = [
                for (p=[0:1:rows-1], t=[0:360/n:359.999])
                    cp + (
                        dots? spherical_to_xyz(r, -t, 45-45*p/rows) :
                        spherical_to_xyz(r, -t, 135+45*p/rows)
                    ),
                cp + r * (dots?UP:DOWN),
                each border>0 ? path3d(subdivide_path(square(1),refine=2,closed=true))
                              : path3d(square(1)),
                      
            ],
            verts = zscale(sc, p=uverts),
            faces = [
                for (i=[0:1:rows-2], j=[0:1:n-1]) each [
                    [i*n+j, i*n+(j+1)%n, (i+1)*n+(j+1)%n,(i+1)*n+j],
                ],
                for (i=[0:1:n-1]) [(rows-1)*n+i, (rows-1)*n+(i+1)%n, rows*n],
                if (border>0) for (i=[0:3]) [for(j=[(i+1)*n/4:-1:i*n/4]) j%n,
                                            (2*i+7)%8+rows*n+1,(2*i)%8+rows*n+1, (2*i+1)%8+rows*n+1],
                if (border==0) for (i=[0:3]) [for(j=[(i+1)*n/4:-1:i*n/4]) j%n, i+rows*n+1]
            ]
        ) [verts, faces] :
    tex=="tri_grid"?
        assert(is_undef(n), str(tex,__vnf_no_n_mesg))  
        assert(num_defined([gap, roughness])==0, str(tex," texture does not accept gap or roughness"))  
        let(
            border = default(border,0.05)*sqrt(3)
        )
        assert(border>0 && border<sqrt(3)/6, "tri_grid texture requires border in (0,1/6)")
        let(
            adj = opp_ang_to_adj(border, 30),
            y1 = border / adj_ang_to_opp(1,60),     // i/sqrt(3)
            y2 = 2*y1,            // 2*i/sqrt(3)
            y3 = 0.5 - y1,
            y4 = 0.5 + y1,
            y5 = 1 - y2,
            y6 = 1 - y1
        )
        [
            [
                [0,0,0], [1,0,0],
                [adj,y1,1], [1-adj,y1,1],
                [0,y2,1], [1,y2,1],
                [0.5,0.5-y2,1],
                [0,y3,1], [0.5-adj,y3,1], [0.5+adj,y3,1], [1,y3,1],
                [0,0.5,0], [0.5,0.5,0], [1,0.5,0],
                [0,y4,1], [0.5-adj,y4,1], [0.5+adj,y4,1], [1,y4,1],
                [0.5,0.5+y2,1],
                [0,y5,1], [1,y5,1],
                [adj,y6,1], [1-adj,y6,1],
                [0,1,0], [1,1,0],
            ], [
               [0,2,3,1],
               [21,23,24,22],
               [2,6,3], [0,12,6,2], [1,3,6,12],
               [0,4,8,12], [4,7,8], [8,7,11,12],
               [1,12,9,5], [5,9,10], [10,9,12,13], 
               [11,14,15,12], [19,15,14], [19,23,12,15],
               [16,17,13,12], [16,20,17], [12,24,20,16], 
               [21,22,18], [12,23,21,18],
               [12,18,22,24],
            ]
        ] :
    tex=="hex_grid"?
        assert(is_undef(n), str(tex,__vnf_no_n_mesg))  
        assert(num_defined([gap, roughness])==0, str(tex," texture does not accept gap or roughness"))
        let(
            border=default(border,0.1)
        )
        assert(border>0 && border<0.5)
        let(
            diag=opp_ang_to_hyp(border,60),
            side=adj_ang_to_opp(1,30),
            hyp=adj_ang_to_hyp(0.5,30),
            sc = 1/3/hyp,
            hex=[ [1,2/6,0], [1/2,1/6,0], [0,2/6,0], [0,4/6,0], [1/2,5/6,0], [1,4/6,0] ]
        ) [
            [
                each hex,
                each move([0.5,0.5], p=yscale(sc, p=path3d(ellipse(d=1-2*border, circum=true, spin=-30,$fn=6),1))),
                hex[0]-[0,diag*sc,-1],
                for (ang=[270+60,270-60]) hex[1]+yscale(sc, p=cylindrical_to_xyz(diag,ang,1)),
                hex[2]-[0,diag*sc,-1],
                [0,0,1], [0.5-border,0,1], [0.5,0,0], [0.5+border,0,1], [1,0,1],
                hex[3]+[0,diag*sc,1],
                for (ang=[90+60,90-60]) hex[4]+yscale(sc, p=cylindrical_to_xyz(diag,ang,1)),
                hex[5]+[0,diag*sc,1],
                [0,1,1], [0.5-border,1,1], [0.5,1,0], [0.5+border,1,1], [1,1,1],
            ], [
                count(6,s=6),
                for (i=[0:1:5]) [i,(i+1)%6, (i+1)%6+6, i+6],
                [20,19,13,12], [17,16,15,14],
                [21,25,26,22], [23,28,29,24],
                [0,12,13,1], [1,14,15,2],
                [3,21,22,4], [4,23,24,5],
                [1,13,19,18], [1,18,17,14], 
                [4,22,26,27], [4,27,28,23],
            ]
        ] :
    tex=="rough"?
        assert(num_defined([gap,border])==0, str(tex," texture does not accept gap or border"))
        let(
            n = default(n,32),
            rough = default(roughness, 0.2)
        ) [
            for (y = [0:1:n-1])
            rands(0, rough, n, seed=123456+29*y)
        ] :
    assert(false, str("Unrecognized texture name: ", tex));


/// Function&Module: _textured_linear_sweep()
/// Usage: As Function
///   vnf = _textured_linear_sweep(region, texture, tex_size, h, ...);
///   vnf = _textured_linear_sweep(region, texture, counts=, h=, ...);
/// Usage: As Module
///   _textured_linear_sweep(region, texture, tex_size, h, ...) [ATTACHMENTS];
///   _textured_linear_sweep(region, texture, counts=, h=, ...) [ATTACHMENTS];
/// Topics: Sweep, Extrusion, Textures, Knurling
/// See Also: heightfield(), cylindrical_heightfield(), texture()
/// Description:
///   Given a [[Region|regions.scad]], creates a linear extrusion of it vertically, optionally twisted, scaled, and/or shifted,
///   with a given texture tiled evenly over the side surfaces.  The texture can be given in one of three ways:
///   - As a texture name string. (See {{texture()}} for supported named textures.)
///   - As a 2D array of evenly spread height values. (AKA a heightfield.)
///   - As a VNF texture tile.  A VNF tile exactly defines a surface from `[0,0]` to `[1,1]`, with the Z coordinates
///     being the height of the texture point from the surface.  VNF tiles MUST be able to tile in both X and Y
///     directions with no gaps, with the front and back edges aligned exactly, and the left and right edges as well.
///   . 
///   One script to convert a grayscale image to a texture heightfield array in a .scad file can be found at:
///   https://raw.githubusercontent.com/BelfrySCAD/BOSL2/master/scripts/img2scad.py
/// Arguments:
///   region = The [[Region|regions.scad]] to sweep/extrude.
///   texture = A texture name string, or a rectangular array of scalar height values (0.0 to 1.0), or a VNF tile that defines the texture to apply to vertical surfaces.  See {{texture()}} for what named textures are supported.
///   tex_size = An optional 2D target size for the textures.  Actual texture sizes will be scaled somewhat to evenly fit the available surface. Default: `[5,5]`
///   h / l = The height to extrude/sweep the path.
///   ---
///   counts = If given instead of tex_size, gives the tile repetition counts for textures over the surface length and height.
///   inset = If numeric, lowers the texture into the surface by that amount, before the tex_scale multiplier is applied.  If `true`, insets by exactly `1`.  Default: `false`
///   rot = If true, rotates the texture 90º.
///   tex_scale = Scaling multiplier for the texture depth.
///   twist = Degrees of twist for the top of the extrustion/sweep, compared to the bottom.  Default: 0
///   scale = Scaling multiplier for the top of the extrustion/sweep, compared to the bottom.  Default: 1
///   shift = [X,Y] amount to translate the top, relative to the bottom.  Default: [0,0]
///   style = The triangulation style used.  See {{vnf_vertex_array()}} for valid styles.  Used only with heightfield type textures. Default: `"min_edge"`
///   samples = Minimum number of "bend points" to have in VNF texture tiles.  Default: 8
///   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
///   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
///   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
/// Named Anchors:
///   "centroid_top" = The centroid of the top of the shape, oriented UP.
///   "centroid" = The centroid of the center of the shape, oriented UP.
///   "centroid_bot" = The centroid of the bottom of the shape, oriented DOWN.

function _get_vnf_tile_edges(texture) =
    let(
        verts = texture[0],
        faces = texture[1],
        everts = [for (v = verts) (v.x==0 || v.y==0 || v.x==1 || v.y==1)],
        uc = unique_count([
            for (face = faces, i = idx(face))
            let(edge = select(face,i,i+1), i1 = min(edge), i2 = max(edge))
            if (everts[i1] && everts[i2])
            [i1, i2]
        ]),
        edges = uc[0], counts = uc[1],
        uedges = [for (i = idx(edges)) if (counts[i] == 1) edges[i] ]
    ) uedges;


function _validate_texture(texture) =
    is_vnf(texture)
      ? let( // Validate VNF tile texture
            bounds = pointlist_bounds(texture[0]),
            min_xy = point2d(bounds[0]),
            max_xy = point2d(bounds[1])
        )
        //assert(min_xy==[0,0] && max_xy==[1,1],"VNF tiles must span exactly from [0,0] to [1,1] in the X and Y components."))
        assert(all_nonnegative(concat(min_xy,[1,1]-max_xy)), "VNF tile X and Y components must be between 0 and 1.")
        let(
            verts = texture[0],
            uedges = _get_vnf_tile_edges(texture),
            edge_verts = [for (i = unique(flatten(uedges))) verts[i] ],
            hverts = [for(v = edge_verts) if(v.x==0 || v.x==1) v],
            vverts = [for(v = edge_verts) if(v.y==0 || v.y==1) v],
            allgoodx = all(hverts, function(v) any(hverts, function(w) approx(w,[1-v.x, v.y, v.z]))),
            allgoody = all(vverts, function(v) any(vverts, function(w) approx(w,[v.x, 1-v.y, v.z])))
        )
        assert(allgoodx && allgoody, "All VNF tile edge vertices must line up with a vertex on the opposite side of the tile.")
        true
      : // Validate heightfield texture.
        assert(is_matrix(texture), "Malformed texture.")
        let( tex_dim = list_shape(texture) )
        assert(len(tex_dim) == 2, "Heightfield texture must be a 2D square array of scalar heights.")
        assert(all_defined(tex_dim), "Heightfield texture must be a 2D square array of scalar heights.")
        true;


function _textured_linear_sweep(
    region, texture, tex_size=[5,5],
    h, counts, inset=false, rot=0,
    tex_scale=1, twist, scale, shift,
    style="min_edge", l, caps=true, 
    height, length, samples,
    anchor=CENTER, spin=0, orient=UP
) =
    assert(is_path(region,[2]) || is_region(region))
    assert(is_undef(samples) || is_int(samples))
    assert(counts==undef || is_vector(counts,2))
    assert(tex_size==undef || is_vector(tex_size,2))
    assert(is_bool(rot) || in_list(rot,[0,90,180,270]))
    assert(is_bool(caps) || is_bool_list(caps,2))
    let(
        caps = is_bool(caps) ? [caps,caps] : caps,
        regions = is_path(region,2)? [[region]] : region_parts(region),
        tex = is_string(texture)? texture(texture,$fn=_tex_fn_default()) : texture,
        dummy = assert(is_undef(samples) || is_vnf(tex), "You gave the tex_samples argument with a heightfield texture, which is not permitted.  Use the n= argument to texture() instead"),
        dummy2=is_bool(rot)?echo("boolean value for tex_rot is deprecated.  Use a numerical angle, one of 0, 90, 180, or 270.")0:0,
        texture = !rot? tex :
            is_vnf(tex)? zrot(is_num(rot)?rot:90, cp=[1/2,1/2], p=tex) :
            rot==180? reverse([for (row=tex) reverse(row)]) :
            rot==270? [for (row=transpose(tex)) reverse(row)] :
            reverse(transpose(tex)),
        h = first_defined([h, l, height, length, 1]),
        inset = is_num(inset)? inset : inset? 1 : 0,
        twist = default(twist, 0),
        shift = default(shift, [0,0]),
        scale = scale==undef? [1,1,1] :
            is_num(scale)? [scale,scale,1] : scale,
        samples = !is_vnf(texture)? len(texture[0]) :
            is_num(samples)? samples : 8,
        check_tex = _validate_texture(texture),
        sorted_tile =
            !is_vnf(texture)? texture :
            let(
                s = 1 / max(1, samples),
                vnf = samples<=1? texture :
                    let(
                        slice_us = list([s:s:1-s/2]),
                        vnft1 = vnf_slice(texture, "X", slice_us),
                        vnft = twist? vnf_slice(vnft1, "Y", slice_us) : vnft1,
                        zvnf = [
                            [
                                for (p=vnft[0]) [
                                    approx(p.x,0)? 0 : approx(p.x,1)? 1 : p.x,
                                    approx(p.y,0)? 0 : approx(p.y,1)? 1 : p.y,
                                    p.z
                                ]
                            ],
                            vnft[1]
                        ]
                    ) zvnf
            ) _vnf_sort_vertices(vnf, idx=[1,0]),
        vertzs = !is_vnf(sorted_tile)? undef :
            group_sort(sorted_tile[0], idx=1),
        tpath = is_vnf(sorted_tile)
            ? _find_vnf_tile_edge_path(sorted_tile,0)
            : let(
                  row = sorted_tile[0],
                  rlen = len(row)
              ) [for (i = [0:1:rlen]) [i/rlen, row[i%rlen]]],
        tmat = scale(scale) * zrot(twist) * up(h/2),
        pre_skew_vnf = vnf_join([
            for (rgn = regions) let(
                walls_vnf = vnf_join([
                    for (path = rgn) let(
                        path = reverse(path),
                        plen = path_length(path, closed=true),
                        counts = is_vector(counts,2)? counts :
                            is_vector(tex_size,2)
                              ? [round(plen/tex_size.x), max(1,round(h/tex_size.y)), ]
                              : [ceil(6*plen/h), 6],
                        obases = resample_path(path, n=counts.x * samples, closed=true),
                        onorms = path_normals(obases, closed=true),
                        bases = list_wrap(obases),
                        norms = list_wrap(onorms),
                        vnf = is_vnf(texture)
                          ? vnf_join( // VNF tile texture
                                let(
                                    row_vnf = vnf_join([
                                        for (i = [0:1:(scale==1?0:counts.y-1)], j = [0:1:counts.x-1]) [
                                            [
                                                for (group = vertzs)
                                                each [
                                                    for (vert = group) let(
                                                        u = floor((j + vert.x) * samples),
                                                        uu = ((j + vert.x) * samples) - u,
                                                        texh = tex_scale<0 ? -(1-vert.z - inset) * tex_scale
                                                                           : (vert.z - inset) * tex_scale,
                                                        base = lerp(bases[u], select(bases,u+1), uu),
                                                        norm = unit(lerp(norms[u], select(norms,u+1), uu)),
                                                        xy = base + norm * texh,
                                                        pt = point3d(xy,vert.y),
                                                        v = vert.y / counts.y,
                                                        vv = i / counts.y,
                                                        sc = lerp([1,1,1], scale, vv+v),
                                                        mat =
                                                            up((vv-0.5)*h) *
                                                            scale(sc) *
                                                            zrot(twist*(v+vv)) *
                                                            zscale(h/counts.y)
                                                    ) apply(mat, pt)
                                                ]
                                            ],
                                            sorted_tile[1]
                                        ]
                                    ])
                                ) [
                                    for (i = [0:1:0*(scale!=1?0:counts.y-1)])
                                    let(
                                        v = i / (scale==1?counts.y:1),
                                        sc = lerp([1,1,1], scale, v),
                                        mat =
                                            up((v)*h) *
                                            scale(sc) *
                                            zrot(twist*v)
                                    )
                                    apply(mat, row_vnf)
                                ]
                            )
                          : let( // Heightfield texture
                                texcnt = [len(texture[0]), len(texture)],
                                tile_rows = [
                                    for (ti = [0:1:texcnt.y-1])
                                    path3d([
                                        for (j = [0:1:counts.x])
                                        for (tj = [0:1:texcnt.x-1])
                                        if (j != counts.x || tj == 0)
                                        let(
                                            part = (j + (tj/texcnt.x)) * samples,
                                            u = floor(part),
                                            uu = part - u,
                                            texh = tex_scale<0 ? -(1-texture[ti][tj] - inset) * tex_scale
                                                               : (texture[ti][tj] - inset) * tex_scale,
                                            base = lerp(bases[u], select(bases,u+1), uu),
                                            norm = unit(lerp(norms[u], select(norms,u+1), uu)),
                                            xy = base + norm * texh
                                        ) xy
                                    ])
                                ],
                                tiles = [
                                    for (i = [0:1:counts.y], ti = [0:1:texcnt.y-1])
                                    if (i != counts.y || ti == 0)
                                    let(
                                        v = (i + (ti/texcnt.y)) / counts.y,
                                        sc = lerp([1, 1, 1], scale, v),
                                        mat = up((v-0.5)*h) *
                                              scale(sc) *
                                              zrot(twist*v)
                                    ) apply(mat, tile_rows[(texcnt.y-ti)%texcnt.y])
                                ]
                            ) vnf_vertex_array(
                                tiles, caps=false, style=style,
                                col_wrap=true, row_wrap=false,
                                reverse=true
                            )
                    ) vnf
                ]),
                brgn = [
                    for (path = rgn) let(
                        path = reverse(path),
                        plen = path_length(path, closed=true),
                        counts = is_vector(counts,2)? counts :
                            is_vector(tex_size,2)
                              ? [round(plen/tex_size.x), max(1,round(h/tex_size.y)), ]
                              : [ceil(6*plen/h), 6],
                        obases = resample_path(path, n=counts.x * samples, closed=true),
                        onorms = path_normals(obases, closed=true),
                        bases = list_wrap(obases),
                        norms = list_wrap(onorms),
                        nupath = [
                            for (j = [0:1:counts.x-1], vert = tpath) let(
                                part = (j + vert.x) * samples,
                                u = floor(part),
                                uu = part - u,
                                texh = tex_scale<0 ? -(1-vert.y - inset) * tex_scale
                                                   : (vert.y - inset) * tex_scale,
                                base = lerp(bases[u], select(bases,u+1), uu),
                                norm = unit(lerp(norms[u], select(norms,u+1), uu)),
                                xy = base + norm * texh
                            ) xy
                        ]
                    ) nupath
                ],
                bot_vnf = !caps[0] || brgn==[[]] ? EMPTY_VNF
                    : vnf_from_region(brgn, down(h/2), reverse=true),
                top_vnf = !caps[1] || brgn==[[]] ? EMPTY_VNF
                    : vnf_from_region(brgn, tmat, reverse=false)
            ) vnf_join([walls_vnf, bot_vnf, top_vnf])
        ]),
        skmat = down(h/2) * skew(sxz=shift.x/h, syz=shift.y/h) * up(h/2),
        final_vnf = apply(skmat, pre_skew_vnf),
        cent = centroid(region),
        anchors = [
            named_anchor("centroid_top", point3d(cent, h/2), UP),
            named_anchor("centroid",     point3d(cent),      UP),
            named_anchor("centroid_bot", point3d(cent,-h/2), DOWN)
        ]
    ) reorient(anchor,spin,orient, vnf=final_vnf, extent=true, anchors=anchors, p=final_vnf);



function _find_vnf_tile_edge_path(vnf, val) =
    let(
        verts = vnf[0],
        fragments = [
            for(edge = _get_vnf_tile_edges(vnf))
            let(v0 = verts[edge[0]], v1 = verts[edge[1]])
            if (approx(v0.y, val) && approx(v1.y, val))
            v0.x <= v1.x? [[v0.x,v0.z], [v1.x,v1.z]] :
            [[v1.x,v1.z], [v0.x,v0.z]]
        ],
        sfrags = sort(fragments, idx=[0,1]),
        rpath = _assemble_a_path_from_fragments(sfrags)[0],
        opath = rpath==[]? []
              : rpath[0].x > last(rpath).x ? reverse(rpath)
              : rpath
    ) opath;


/// Function&Module: _textured_revolution()
/// Usage: As Function
///   vnf = _textured_revolution(shape, texture, tex_size, [tex_scale=], ...);
///   vnf = _textured_revolution(shape, texture, counts=, [tex_scale=], ...);
/// Usage: As Module
///   _textured_revolution(shape, texture, tex_size, [tex_scale=], ...) [ATTACHMENTS];
///   _textured_revolution(shape, texture, counts=, [tex_scale=], ...) [ATTACHMENTS];
/// Topics: Sweep, Extrusion, Textures, Knurling
/// See Also: heightfield(), cylindrical_heightfield(), texture()
/// Description:
///   Given a 2D region or path, fully in the X+ half-plane, revolves that shape around the Z axis (after rotating its Y+ to Z+).
///   This creates a solid from that surface of revolution, possibly capped top and bottom, with the sides covered in a given tiled texture.
///   The texture can be given in one of three ways:
///   - As a texture name string. (See {{texture()}} for supported named textures.)
///   - As a 2D array of evenly spread height values. (AKA a heightfield.)
///   - As a VNF texture tile.  A VNF tile exactly defines a surface from `[0,0]` to `[1,1]`, with the Z coordinates
///     being the height of the texture point from the surface.  VNF tiles MUST be able to tile in both X and Y
///     directions with no gaps, with the front and back edges aligned exactly, and the left and right edges as well.
///   .
///   One script to convert a grayscale image to a texture heightfield array in a .scad file can be found at:
///   https://raw.githubusercontent.com/BelfrySCAD/BOSL2/master/scripts/img2scad.py
/// Arguments:
///   shape = The path or region to sweep/extrude.
///   texture = A texture name string, or a rectangular array of scalar height values (0.0 to 1.0), or a VNF tile that defines the texture to apply to the revolution surface.  See {{texture()}} for what named textures are supported.
///   tex_size = An optional 2D target size for the textures.  Actual texture sizes will be scaled somewhat to evenly fit the available surface. Default: `[5,5]`
///   tex_scale = Scaling multiplier for the texture depth.
///   ---
///   inset = If numeric, lowers the texture into the surface by that amount, before the tex_scale multiplier is applied.  If `true`, insets by exactly `1`.  Default: `false`
///   rot = If true, rotates the texture 90º.
///   shift = [X,Y] amount to translate the top, relative to the bottom.  Default: [0,0]
///   closed = If false, and shape is given as a path, then the revolved path will be sealed to the axis of rotation with untextured caps.  Default: `true`
///   taper = If given, and `closed=false`, tapers the texture height to zero over the first and last given percentage of the path.  If given as a lookup table with indices between 0 and 100, uses the percentage lookup table to ramp the texture heights.  Default: `undef` (no taper)
///   angle = The number of degrees counter-clockwise from X+ to revolve around the Z axis.  Default: `360`
///   style = The triangulation style used.  See {{vnf_vertex_array()}} for valid styles.  Used only with heightfield type textures. Default: `"min_edge"`
///   counts = If given instead of tex_size, gives the tile repetition counts for textures over the surface length and height.
///   samples = Minimum number of "bend points" to have in VNF texture tiles.  Default: 8
///   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
///   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
///   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
/// Anchor Types:
///   "hull" = Anchors to the virtual convex hull of the shape.
///   "intersect" = Anchors to the surface of the shape.

function _textured_revolution(
    shape, texture, tex_size, tex_scale=1,
    inset=false, rot=false, shift=[0,0],
    taper, closed=true, angle=360,
    inhibit_y_slicing=false,
    counts, samples,
    style="min_edge", atype="intersect",
    anchor=CENTER, spin=0, orient=UP
) = 
    assert(angle>0 && angle<=360)
    assert(is_path(shape,[2]) || is_region(shape))
    assert(is_undef(samples) || is_int(samples))
    assert(is_bool(closed))
    assert(counts==undef || is_vector(counts,2))
    assert(tex_size==undef || is_vector(tex_size,2))
    assert(is_bool(rot) || in_list(rot,[0,90,180,270]))
    let( taper_is_ok = is_undef(taper) || (is_finite(taper) && taper>=0 && taper<50) || is_path(taper,2) )
    assert(taper_is_ok, "Bad taper= value.")
    assert(in_list(atype, _ANCHOR_TYPES), "Anchor type must be \"hull\" or \"intersect\"")
    let(
        regions = !is_path(shape,2)? region_parts(shape) :
            closed? region_parts([shape]) :
            let(
                clpoly = [[0,shape[0].y], each shape, [0,last(shape).y]],
                dpoly = deduplicate(clpoly),
                cwpoly = is_polygon_clockwise(dpoly) ? dpoly : reverse(dpoly)
            )
            [[ select(cwpoly,1,-2) ]],
        checks = [
            for (rgn=regions, path=rgn)
            assert(all(path, function(pt) pt.x>=0))
        ]
    )
    assert(closed || is_path(shape,2))
    let(
        tex = is_string(texture)? texture(texture,$fn=_tex_fn_default()) : texture,
        dummy = assert(is_undef(samples) || is_vnf(tex), "You gave the tex_samples argument with a heightfield texture, which is not permitted.  Use the n= argument to texture() instead"),
        dummy2=is_bool(rot)?echo("boolean value for tex_rot is deprecated.  Use a numerical angle, one of 0, 90, 180, or 270.")0:0,        
        texture = !rot? tex :
            is_vnf(tex)? zrot(is_num(rot)?rot:90, cp=[1/2,1/2], p=tex) :
            rot==180? reverse([for (row=tex) reverse(row)]) :
            rot==270? [for (row=transpose(tex)) reverse(row)] :
            reverse(transpose(tex)),
        check_tex = _validate_texture(texture),
        inset = is_num(inset)? inset : inset? 1 : 0,
        samples = !is_vnf(texture)? len(texture) :
            is_num(samples)? samples : 8,
        bounds = pointlist_bounds(flatten(flatten(regions))),
        maxx = bounds[1].x,
        miny = bounds[0].y,
        maxy = bounds[1].y,
        h = maxy - miny,
        circumf = 2 * PI * maxx,
        tile = !is_vnf(texture)? texture :
            let(
                utex = samples<=1? texture :
                    let(
                        s = 1 / samples,
                        slices = list([s : s : 1-s/2]),
                        vnfx = vnf_slice(texture, "X", slices),
                        vnfy = inhibit_y_slicing? vnfx : vnf_slice(vnfx, "Y", slices),
                        vnft = vnf_triangulate(vnfy),
                        zvnf = [
                            [
                                for (p=vnft[0]) [
                                    approx(p.x,0)? 0 : approx(p.x,1)? 1 : p.x,
                                    approx(p.y,0)? 0 : approx(p.y,1)? 1 : p.y,
                                    p.z
                                ]
                            ],
                            vnft[1]
                        ]
                    ) zvnf
            ) _vnf_sort_vertices(utex, idx=[0,1]),
        vertzs = is_vnf(texture)? group_sort(tile[0], idx=0) : undef,
        bpath = is_vnf(tile)
            ? _find_vnf_tile_edge_path(tile,1)
            : let(
                  row = tile[0],
                  rlen = len(row)
              ) [for (i = [0:1:rlen]) [i/rlen, row[i%rlen]]],
        counts_x = is_vector(counts,2)? counts.x :
            is_vector(tex_size,2)
              ? max(1,round(angle/360*circumf/tex_size.x))
              : ceil(6*angle/360*circumf/h),
        taper_lup = closed || is_undef(taper)? [[-1,1],[2,1]] :
            is_num(taper)? [[-1,0], [0,0], [taper/100+EPSILON,1], [1-taper/100-EPSILON,1], [1,0], [2,0]] :
            is_path(taper,2)? let(
                retaper = [
                    for (t=taper)
                    assert(t[0]>=0 && t[0]<=100, "taper lookup indices must be between 0 and 100 inclusive.")
                    [t[0]/100, t[1]]
                ],
                taperout = [[-1,retaper[0][1]], each retaper, [2,last(retaper)[1]]]
            ) taperout :
            assert(false, "Bad taper= argument value."),
        full_vnf = vnf_join([
            for (rgn = regions) let(
                rgn_wall_vnf = vnf_join([
                    for (path = rgn) let(
                        plen = path_length(path, closed=closed),
                        counts_y = is_vector(counts,2)? counts.y :
                            is_vector(tex_size,2)? max(1,round(plen/tex_size.y)) : 6,
                        obases = resample_path(path, n=counts_y * samples + (closed?0:1), closed=closed),
                        onorms = path_normals(obases, closed=closed),
                        rbases = closed? list_wrap(obases) : obases,
                        rnorms = closed? list_wrap(onorms) : onorms,
                        bases = xrot(90, p=path3d(rbases)),
                        norms = xrot(90, p=path3d(rnorms)),
                        vnf = is_vnf(texture)
                          ? vnf_join([ // VNF tile texture
                                for (j = [0:1:counts_y-1])
                                [
                                    [
                                        for (group = vertzs) each [
                                            for (vert = group) let(
                                                part = (j + (1-vert.y)) * samples,
                                                u = floor(part),
                                                uu = part - u,
                                                base = lerp(select(bases,u), select(bases,u+1), uu),
                                                norm = unit(lerp(select(norms,u), select(norms,u+1), uu)),
                                                tex_scale = tex_scale * lookup(part/samples/counts_y, taper_lup),
                                                texh = tex_scale<0 ? -(1-vert.z - inset) * tex_scale * (base.x / maxx)
                                                                   : (vert.z - inset) * tex_scale * (base.x / maxx),
                                                xyz = base - norm * texh
                                            ) zrot(vert.x*angle/counts_x, p=xyz)
                                        ]
                                    ],
                                    tile[1]
                                ]
                            ])
                          : let( // Heightfield texture
                                texcnt = [len(texture[0]), len(texture)],
                                tiles = transpose([
                                    for (j = [0,1], tj = [0:1:texcnt.x-1])
                                    if (j == 0 || tj == 0)
                                    let(
                                        v = (j + (tj/texcnt.x)) / counts_x,
                                        mat = zrot(v*angle)
                                    ) apply(mat, [
                                        for (i = [0:1:counts_y-(closed?1:0)], ti = [0:1:texcnt.y-1])
                                        if (i != counts_y || ti == 0)
                                        let(
                                            part = (i + (ti/texcnt.y)) * samples,
                                            u = floor(part),
                                            uu = part - u,
                                            base = lerp(bases[u], select(bases,u+1), uu),
                                            norm = unit(lerp(norms[u], select(norms,u+1), uu)),
                                            tex_scale = tex_scale * lookup(part/samples/counts_y, taper_lup),
                                            texh = tex_scale<0 ? -(1-texture[ti][tj] - inset) * tex_scale * (base.x / maxx)
                                                               : (texture[ti][tj] - inset) * tex_scale * (base.x / maxx),
                                            xyz = base - norm * texh
                                        ) xyz
                                    ])
                                ])
                            ) vnf_vertex_array(
                                tiles, caps=false, style=style,
                                col_wrap=false, row_wrap=closed
                            )
                    ) vnf
                ]),
                walls_vnf = vnf_join([
                    for (i = [0:1:counts_x-1])
                    zrot(i*angle/counts_x, rgn_wall_vnf)
                ]),
                endcap_vnf = angle == 360? EMPTY_VNF :
                    let(
                        cap_rgn = [
                            for (path = rgn) let(
                                plen = path_length(path, closed=closed),
                                counts_y = is_vector(counts,2)? counts.y :
                                    is_vector(tex_size,2)? max(1,round(plen/tex_size.y)) : 6,
                                obases = resample_path(path, n=counts_y * samples + (closed?0:1), closed=closed),
                                onorms = path_normals(obases, closed=closed),
                                bases = closed? list_wrap(obases) : obases,
                                norms = closed? list_wrap(onorms) : onorms,
                                ppath = is_vnf(texture)
                                  ? [ // VNF tile texture
                                        for (j = [0:1:counts_y-1])
                                        for (group = vertzs, vert = reverse(group))
                                        if (approx(vert.x, 0)) let(
                                            part = (j + (1 - vert.y)) * samples,
                                            u = floor(part),
                                            uu = part - u,
                                            base = lerp(select(bases,u), select(bases,u+1), uu),
                                            norm = unit(lerp(select(norms,u), select(norms,u+1), uu)),
                                            tex_scale = tex_scale * lookup(part/samples/counts_y, taper_lup),
                                            texh = tex_scale<0 ? -(1-vert.z - inset) * tex_scale * (base.x / maxx)
                                                               : (vert.z - inset) * tex_scale * (base.x / maxx),
                                            xyz = base - norm * texh
                                        ) xyz
                                    ]
                                  : let( // Heightfield texture
                                        texcnt = [len(texture[0]), len(texture)]
                                    ) [
                                        for (i = [0:1:counts_y-(closed?1:0)], ti = [0:1:texcnt.y-1])
                                        if (i != counts_y || ti == 0)
                                        let(
                                            part = (i + (ti/texcnt.y)) * samples,
                                            u = floor(part),
                                            uu = part - u,
                                            base = lerp(bases[u], select(bases,u+1), uu),
                                            norm = unit(lerp(norms[u], select(norms,u+1), uu)),
                                            tex_scale = tex_scale * lookup(part/samples/counts_y, taper_lup),
                                            texh = tex_scale<0 ? -(1-texture[ti][0] - inset) * tex_scale * (base.x / maxx)
                                                               : (texture[ti][0] - inset) * tex_scale * (base.x / maxx),
                                            xyz = base - norm * texh
                                        ) xyz
                                    ],
                                path = closed? ppath : [
                                    [0, ppath[0].y],
                                    each ppath,
                                    [0, last(ppath).y],
                                ]
                            ) deduplicate(path, closed=closed)
                        ],
                        vnf2 = vnf_from_region(cap_rgn, xrot(90), reverse=false),
                        vnf3 = vnf_from_region(cap_rgn, rot([90,0,angle]), reverse=true)
                    ) vnf_join([vnf2, vnf3]),
                allcaps_vnf = closed? EMPTY_VNF :
                    let(
                        plen = path_length(rgn[0], closed=closed),
                        counts_y = is_vector(counts,2)? counts.y :
                            is_vector(tex_size,2)? max(1,round(plen/tex_size.y)) : 6,
                        obases = resample_path(rgn[0], n=counts_y * samples + (closed?0:1), closed=closed),
                        onorms = path_normals(obases, closed=closed),
                        rbases = closed? list_wrap(obases) : obases,
                        rnorms = closed? list_wrap(onorms) : onorms,
                        bases = xrot(90, p=path3d(rbases)),
                        norms = xrot(90, p=path3d(rnorms)),
                        caps_vnf = vnf_join([
                            for (j = [-1,0]) let(
                                base = select(bases,j),
                                norm = unit(select(norms,j)),
                                ppath = [
                                    for (vert = bpath) let(
                                        uang = vert.x / counts_x,
                                        tex_scale = tex_scale * lookup([0,1][j+1], taper_lup),
                                        texh = tex_scale<0 ? -(1-vert.y - inset) * tex_scale * (base.x / maxx)
                                                           : (vert.y - inset) * tex_scale * (base.x / maxx),
                                        xyz = base - norm * texh
                                    ) zrot(angle*uang, p=xyz)
                                ],
                                pplen = len(ppath),
                                zed = j<0? max(column(ppath,2)) :
                                    min(column(ppath,2)),
                                slice_vnf = [
                                    [
                                        each ppath,
                                        [0, 0, zed],
                                    ], [
                                        for (i = [0:1:pplen-2])
                                            j<0? [pplen, i, (i+1)%pplen] :
                                            [pplen, (i+1)%pplen, i]
                                    ]
                                ],
                                cap_vnf = vnf_join([
                                    for (i = [0:1:counts_x-1])
                                        zrot(i*angle/counts_x, p=slice_vnf)
                                ])
                            ) cap_vnf
                        ])
                    ) caps_vnf
            ) vnf_join([walls_vnf, endcap_vnf, allcaps_vnf])
        ]),
        skmat = down(-miny) * skew(sxz=shift.x/h, syz=shift.y/h) * up(-miny),
        skvnf = apply(skmat, full_vnf),
        geom = atype=="intersect"
              ? attach_geom(vnf=skvnf, extent=false)
              : attach_geom(vnf=skvnf, extent=true)
    ) reorient(anchor,spin,orient, geom=geom, p=skvnf);


module _textured_revolution(
    shape, texture, tex_size, tex_scale=1,
    inset=false, rot=false, shift=[0,0],
    taper, closed=true, angle=360,
    style="min_edge", atype="intersect",
    inhibit_y_slicing=false,
    convexity=10, counts, samples,
    anchor=CENTER, spin=0, orient=UP
) {
    dummy = assert(in_list(atype, _ANCHOR_TYPES), "Anchor type must be \"hull\" or \"intersect\"");
    vnf = _textured_revolution(
        shape, texture, tex_size=tex_size,
        tex_scale=tex_scale, inset=inset, rot=rot,
        taper=taper, closed=closed, style=style,
        shift=shift, angle=angle,
        samples=samples, counts=counts,
        inhibit_y_slicing=inhibit_y_slicing
    );
    geom = atype=="intersect"
          ? attach_geom(vnf=vnf, extent=false)
          : attach_geom(vnf=vnf, extent=true);
    attachable(anchor,spin,orient, geom=geom) {
        vnf_polyhedron(vnf, convexity=convexity);
        children();
    }
}



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
