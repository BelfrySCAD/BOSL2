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

__vnf_no_n_mesg=" texture is a VNF so it does not accept n. Set sample rate for VNF textures using the tex_samples parameter to cyl(), linear_sweep(), or rotate_sweep().";

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
//   OK during preview or when rendered by itself.  The order of points in your profiles must be
//   consistent from slice to slice so that points match up without creating twists.  You can specify
//   profiles in any consistent order: if necessary, skin() reverses the faces to ensure that the final
//   result has clockwise faces as required by CGAL.  The face reversal test may give random results
//   if you use `skin()` to construct self-intersecting (invalid) polyhedra.  
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
//   multiplies the number of points on your profile by `N`.  You can choose between two resampling
//   schemes using the `sampling` option, which you can set to `"length"` or `"segment"`.
//   The length resampling method resamples proportional to length.
//   The segment method divides each segment of a profile into the same number of points.
//   This means that if you refine a profile with the "segment" method, you get N points
//   on each edge, but if you refine a profile with the "length" method, you get new points
//   distributed around the profile based on length, so small segments get fewer new points than longer ones.
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
//   If you simply supply a list of compatible profiles, they link up
//   exactly as you have provided them.  You may find that profiles you want to connect define the
//   right shapes but the point lists don't start from points that you want aligned in your skinned
//   polyhedron.  You can correct this yourself using `reindex_polygon`, or you can use the "reindex"
//   method, which looks for the index choice that minimizes the length of all of the edges
//   in the polyhedron to produce the least twisted possible result.  This algorithm has quadratic
//   run time so it can be slow with large profiles.
//   .
//   When the profiles are incommensurate, the "direct" and "reindex" resample them to match.  As noted above,
//   for continuous input curves, it is better to generate your curves directly at the desired sample size,
//   but for mapping between a discrete profile like a hexagon and a circle, the hexagon must be resampled
//   to match the circle.  When you use "direct" or "reindex" the default `sampling` value is
//   of `sampling="length"` to approximate a uniform length sampling of the profile.  This generally
//   produces the natural result for connecting two continuously sampled profiles or a continuous
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
//   all of the tangent points from each other. The algorithm treats whichever input profile has fewer points as the polygon,
//   and the other one as the curve.  Using `refine` with this method has little effect on the model, so
//   you should do it only for agreement with other profiles, and these models are linear, so extra slices also
//   have no effect.  For best efficiency set `refine=1` and `slices=0`.  As with the "distance" method, refinement
//   must be done using the "segment" sampling scheme to preserve alignment across duplicated points.
//   The "tangent" method produces similar results to the "distance" method on curved inputs.  If this
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
//   orient = Vector to rotate top toward after spin
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
// Example(3D,Med,NoScales,VPR=[66.90,0.00,165.70],VPD=13.79,VPT=[1.43,6.15,4.13]): Here's a simplified version of the above, with `i=0` included.  That first layer has narrow triangles creating a stair step effect at the corners.  
//   shapes = [for(i=[0:.2:1]) path3d(regular_ngon(n=4, side=4, rounding=i, $fn=32),i*5)];
//   skin(shapes, slices=0);
// Example(3D,Med,NoScales,VPR=[66.90,0.00,165.70],VPD=13.79,VPT=[1.43,6.15,4.13]): You can fix it by specifying "tangent" for the first method, but you still need "direct" for the rest.
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
// Example(FlatSpin,VPD=80,VPT=[0,0,7]): The "distance" method often produces results similar to the "tangent" method if you use it with a polygon and a curve, but the results can also look like this:
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
//   augpent = repeat_entries(pent, [1,2,1,1,1]);         // Vertex 1 splits at the top, forming a triangular face with the hexagon
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
  assert(in_list(atype, _ANCHOR_TYPES), "\nAnchor type must be \"hull\" or \"intersect\".")
  assert(is_def(slices),"\nThe slices argument must be specified.")
  assert(is_list(profiles) && len(profiles)>1, "\nMust provide at least two profiles.")
  let(
       profiles = [for(p=profiles) if (is_region(p) && len(p)==1) p[0] else p]
  )
  let( bad = [for(i=idx(profiles)) if (!(is_path(profiles[i]) && len(profiles[i])>2)) i])
  assert(len(bad)==0, str("\nProfiles ",bad," are not a paths or have length less than 3."))
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
  assert(len(refine)==len(profiles), "\nrefine list is the wrong length.")
  assert(len(slices)==profcount, str("\nslices list must have length ",profcount,"."))
  assert(slicesOK==[],"\nslices must be nonnegative integers.")
  assert(refineOK==[],"\nrefine must be a postive integer.")
  assert(methodok,str("\nmethod must be one of ",legal_methods,". Got ",method,"."))
  assert(methodlistok==[], str("\nmethod list contains invalid method at ",methodlistok,"."))
  assert(len(method) == profcount,"\nMethod list is the wrong length.")
  assert(in_list(sampling,["length","segment"]), "\nsampling must be set to \"length\" or \"segment\".")
  assert(sampling=="segment" || (!in_list("distance",method) && !in_list("fast_distance",method) && !in_list("tangent",method)), "\nsampling is set to \"length\", which is allowed only with methods \"direct\" and \"reindex\".")
  assert(capsOK, "\ncaps must be boolean or a list of two booleans.")
  assert(!closed || !caps, "\nCannot make closed shape with caps.")
  let(
    profile_dim=list_shape(profiles,2),
    profiles_zcheck = (profile_dim != 2) || (profile_dim==2 && is_list(z) && len(z)==len(profiles)),
    profiles_ok = (profile_dim==2 && is_list(z) && len(z)==len(profiles)) || profile_dim==3
  )
  assert(profiles_zcheck, "\nz parameter is invalid or has the wrong length.")
  assert(profiles_ok,"\nProfiles must all be 3d or must all be 2d, with matching length z parameter.")
  assert(is_undef(z) || profile_dim==2, "\nDo not specify z with 3d profiles.")
  assert(profile_dim==3 || len(z)==len(profiles),"\nLength of z does not match length of profiles.")
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
  assert(badind==[],str("\nProfile length mismatch at method transition at indices ",badind," in skin()."))
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
               assert(refine[i]==select(refine,i+1),str("\nRefine value mismatch at indices ",[i,(i+1)%len(refine)],
                      ".  Method ",method[i]," requires equal values."))
               refine[i] * len(pair[0])
          )
          subdivide_and_slice(pair,slices[i], nsamples, method=sampling)],
      pvnf=vnf_join(
          [for(i=idx(full_list))
              vnf_vertex_array(full_list[i], cap1=i==0 && fullcaps[0], cap2=i==len(full_list)-1 && fullcaps[1],
                               col_wrap=true, style=style)]),
      vnf = vnf_volume(pvnf)<0 ? vnf_reverse_faces(pvnf) : pvnf
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
//   of the given 2D region or polygon.  One benefit of this, over `linear_extrude region(rgn)` is
//   that it supports `anchor`, `spin`, `orient` and attachments.  It can make more refined
//   twisted extrusions by using `maxseg` to subsample flat faces, and it also supports texturing.  
//   .
//   Anchoring for linear_sweep is based on the anchors for the swept region rather than from the polyhedron that is created.  This can produce more
//   predictable anchors for LEFT, RIGHT, FWD and BACK in many cases, but the anchors may be approximately
//   correct only for twisted objects, and corner anchors may point in unexpected directions in some cases.  These anchors also ignore any applied texture.
//   If you need anchors directly computed from the surface you can pass the vnf from linear_sweep
//   to {{vnf_polyhedron()}}, which computes anchors directly from the full VNF.
//   Additional named face and edge anchors are located on the side faces and vertical edges of the prism.
//   When you sweep a polygon you can use `EDGE(i)`, `EDGE(TOP,i)` and `EDGE(BOT,i)` as a shorthand for
//   accessing the named edge anchors, and `FACE(i)` for the face anchors.
//   The "edge0" anchor identifies an edge located along the X+ axis, and then edges
//   are labeled counting up in the clockwise direction.  Similarly "face0" is the face immediately clockwise from "edge0", and face
//   labeling proceeds clockwise.  The top and bottom edge anchors label edges directly above and below the face with the same label.
//   When you sweep a region, the region is decomposed using {{region_parts()}} and the anchors are generated for the region components
//   in the order produced by the decomposition, working entirely through each component and then on to the next component.  
//   The anchors for twisted shapes may be inaccurate.
// Arguments:
//   region = The 2D [Region](regions.scad) or polygon that is to be extruded.
//   h / height / l / length = The height to extrude the region.  Default: 1
//   center = If true, the created polyhedron is vertically centered.  If false, it is extruded upward from the XY plane.  Default: `false`
//   ---
//   twist = The number of degrees to rotate the top of the shape, clockwise around the Z axis, relative to the bottom.  Default: 0
//   scale = The amount to scale the top of the shape, in the X and Y directions, relative to the size of the bottom.  Default: 1
//   shift = The amount to shift the top of the shape, in the X and Y directions, relative to the position of the bottom.  Default: [0,0]
//   slices = The number of slices to divide the shape into along the Z axis, to allow refinement of detail, especially when working with a twist.  Default: `twist/5`
//   maxseg = If given, then any long segments of the region are subdivided to be shorter than this length.  This can refine twisting flat faces a lot.  Default: `undef` (no subsampling)
//   texture = A texture name string, or a rectangular array of scalar height values (0.0 to 1.0), or a VNF tile that defines the texture to apply to vertical surfaces.  See {{texture()}} for what named textures are supported.
//   tex_size = An optional 2D target size (2-vector or scalar) for the textures.  Actual texture sizes are scaled somewhat to evenly fit the available surface. Default: `[5,5]`
//   tex_reps = If given instead of tex_size, a scalar or 2-vector giving the integer number of texture tile repetitions in the horizontal and vertical directions.
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
//   orient = Vector to rotate top toward, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Anchor Types:
//   "hull" = Anchors to the virtual convex hull of the shape.
//   "intersect" = Anchors to the surface of the shape.
//   "bbox" = Anchors to the bounding box of the extruded shape.
// Named Anchors:
//   "origin" = Centers the extruded shape vertically only, but keeps the original path positions in the X and Y.  Oriented UP.
//   "original_base" = Keeps the original path positions in the X and Y, but at the bottom of the extrusion.  Oriented DOWN.
//   "original_top" = Keeps the original path positions in the X and Y, but at the top of the extrusion.  Oriented UP.
//   "edge0", "edge1", etc. = Center of each side edge, spin pointing up along the edge.  Can access with EDGE(i)
//   "face0", "face1", etc. = Center of each side face, spin pointing up.  Can access with FACE(i)
//   "top_edge0", "top_edge1", etc = Center of each top edge, spin pointing clockwise (from top). Can access with EDGE(TOP,i)
//   "bot_edge0", "bot_edge1", etc = Center of each bottom edge, spin pointing clockwise (from bottom).  Can access with EDGE(BOT,i)
//   "top_corner0", "top_corner1", etc = Top corner, pointing in direction of associated edge anchor, spin up along associated edge
//   "bot_corner0", "bot_corner1", etc = Bottom corner, pointing in direction of associated edge anchor, spin up along associated edge
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
//       texture="rough", h=100, tex_depth=.4,
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
// Example: The same tile from above, turned 90 degrees. Note that it has endcaps on the disconnected components.  These do not appear if `caps=false`.  
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
// Example: This example shows a disconnected component combined with the base component.
//   shape = skin([rect(2/5),
//                 rect(2/3),
//                 rect(2/5)],
//                z=[0,1/2,1],
//                slices=0,
//                caps=false);
//   tile = xscale(.5,move([1/2,1,2/3],xrot(90,shape)));
//   peak = [[[0,0,0],[1,0,0]],
//           [[0,1/2,1/4],[1,1/2,1/4]],
//           [[0,1,0],[1,1,0]]];
//   peakvnf = vnf_vertex_array(peak,reverse=true);
//   doubletile = vnf_join([tile,
//                          right(.5,tile),
//                          peakvnf
//                         ]);
//   linear_sweep(circle(20), texture=doubletile, 
//                tex_size=[40,20],tex_depth=15, h=40);
// Example(3D,NoAxes,VPT=[0.37913,-2.82647,5.92656],VPR=[99.8,0,9.6],VPD=48.815): Here is a simple basket weave pattern created using a texture.  We have removed the back to make the weave easier to see.  
//    diag_weave_vnf = [
//       [[0.2, 0, 0], [0.8, 0, 0], [1, 0.2, 0.5], [1, 0.8, 0.5], [0.7, 0.5, 0.5],
//        [0.5, 0.3, 0], [0.2, 0, 0.5], [0.8, 0, 0.5], [1, 0.2, 1], [1, 0.8, 1],
//        [0.7, 0.5, 1], [0.5, 0.3, 0.5], [1, 0.2, 0], [1, 0.8, 0], [0.8, 1, 0.5],
//         [0.2, 1, 0.5], [0.5, 0.7, 0.5], [0.7, 0.5, 0], [0.8, 1, 1], [0.2, 1, 1],
//         [0.5, 0.7, 1], [0.8, 1, 0], [0.2, 1, 0], [0, 0.8, 0.5], [0, 0.2, 0.5],
//         [0.3, 0.5, 0.5], [0.5, 0.7, 0], [0, 0.8, 1], [0, 0.2, 1], [0.3, 0.5, 1],
//         [0, 0.8, 0], [0, 0.2, 0], [0.3, 0.5, 0], [0.2, 0, 1], [0.8, 0, 1], [0.5, 0.3, 1]],
//        [[0, 1, 5], [1, 2, 4, 5], [7, 11, 10, 8], [8, 10, 9], [7, 8, 2, 1], [9, 10, 4, 3],
//         [10, 11, 5, 4], [0, 5, 11, 6], [12, 13, 17], [13, 14, 16, 17], [3, 4, 20, 18],
//         [18, 20, 19], [3, 18, 14, 13], [19, 20, 16, 15], [20, 4, 17, 16], [12, 17, 4, 2],
//         [21, 22, 26], [22, 23, 25, 26], [15, 16, 29, 27], [27, 29, 28], [15, 27, 23, 22],
//         [28, 29, 25, 24], [29, 16, 26, 25], [21, 26, 16, 14], [30, 31, 32], [31, 6, 11, 32],
//         [24, 25, 35, 33], [33, 35, 34], [24, 33, 6, 31], [34, 35, 11, 7],
//         [35, 25, 32, 11], [30, 32, 25, 23]]
//    ];
//    front_half(y=33){
//      cyl(d=14.5,h=1,anchor=BOT,rounding=1/3,$fa=1,$fs=.5);
//      linear_sweep(circle(d=12), h=12, scale=1.3, texture=diag_weave_vnf,
//                   tex_size=[5,5], convexity=12);
//    }



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
    check = assert(is_region(region),"\nInput is not a region");
    anchor = center==true? "origin" :
        center == false? "original_base" :
        default(anchor, "original_base");
    vnf_geom = linear_sweep(
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
        maxseg=maxseg, atype=atype, 
        anchor="origin", _return_geom=true
    );
    attachable(anchor,spin,orient, geom=vnf_geom[1]) {
        vnf_polyhedron(vnf_geom[0], convexity=convexity);
        children();
    }
}


function _make_all_prism_anchors(bot, top, startind=0) =
  let(
        facenormal= [
                     for(i=idx(bot))
                        let(
                            edge0 = [top[i],bot[i]],                   // vertical edge at i
                            edge1 = [select(top,i+1),select(bot,i+1)], // vertical edge at i+1
                            facenormal = unit(unit(cross(edge1[1]-edge0[0], edge0[1]-edge0[0]))+
                                              unit(cross(edge0[0]-edge1[1], edge1[0]-edge1[1])))
                        )
                        facenormal
                    ],
        anchors = [for(i=idx(bot))
                      let(

                           edge1 = [top[i],bot[i]],                   // vertical edge at i
                           edge2 = [select(top,i+1),select(bot,i+1)], // vertical edge at i+1

                           facecenter = mean(concat(edge1,edge2)),
                           facespin = _compute_spin(facenormal[i], UP),

                           side_edge_center = mean(edge1),
                           side_edge_dir = top[i]-bot[i],
                           side_edge_normal = unit(vector_bisect(facenormal[i],select(facenormal,i-1))),
                           side_edge_spin = _compute_spin(side_edge_normal, side_edge_dir),
                           side_edge_angle = 180-vector_angle(facenormal[i], select(facenormal,i-1)),
                           side_edge_len = norm(side_edge_dir),

                           top_edge_center = (edge2[0]+edge1[0])/2,
                           top_edge_dir = edge2[0]-edge1[0],
                           bot_edge_center = (edge1[1]+edge2[1])/2,
                           bot_edge_dir = edge1[1]-edge2[1],
                           topnormal = unit(facenormal[i]+UP),
                           botnormal = unit(facenormal[i]+DOWN),
                           topedgespin = _compute_spin(topnormal, top_edge_dir),
                           botedgespin = _compute_spin(botnormal, bot_edge_dir),
                           topedgeangle = 180-vector_angle(UP,facenormal[i])
                      )
                      each [
                          named_anchor(str("face",i+startind), facecenter, facenormal[i], facespin),
                          named_anchor(str("edge",i+startind), side_edge_center, side_edge_normal, side_edge_spin,
                                       info=[["edge_angle",side_edge_angle], ["edge_length",side_edge_len]]),
                          named_anchor(str("top_edge",i+startind), top_edge_center, topnormal, topedgespin,
                                       info=[["edge_angle",topedgeangle],["edge_length",norm(top_edge_dir)]]),
                          named_anchor(str("bot_edge",i+startind), bot_edge_center, botnormal, botedgespin,
                                       info=[["edge_angle",180-topedgeangle],["edge_length",norm(bot_edge_dir)]]),
                          named_anchor(str("top_corner",i+startind), top[i], unit(side_edge_normal+UP),
                                       _compute_spin(unit(side_edge_normal+UP),side_edge_dir)),
                          named_anchor(str("bot_corner",i+startind), bot[i], unit(side_edge_normal+DOWN),
                                       _compute_spin(unit(side_edge_normal+DOWN),side_edge_dir))
                      ]
                  ]
  )
  anchors;



function linear_sweep(
    region, height, center,
    twist=0, scale=1, shift=[0,0],
    slices, maxseg, style="default", caps=true, 
    cp, atype="hull", h,
    texture, tex_size=[5,5], tex_reps, tex_counts,
    tex_inset=false, tex_rot=0,
    tex_scale, tex_depth, tex_samples, h, l, length, 
    anchor, spin=0, orient=UP, _return_geom=false
) =
    assert(num_defined([tex_reps,tex_counts])<2, "\nIn linear_sweep() the 'tex_counts' parameter has been replaced by 'tex_reps'.  You cannot give both.")
    assert(num_defined([tex_scale,tex_depth])<2, "\nIn linear_sweep() the 'tex_scale' parameter has been replaced by 'tex_depth'.  You cannot give both.")
    let(
        region = force_region(region),
        tex_reps = is_def(tex_counts)? echo("In linear_sweep() the 'tex_counts' parameter is deprecated and has been replaced by 'tex_reps'.")tex_counts
                 : tex_reps,
        tex_depth = is_def(tex_scale)? echo("In linear_sweep() the 'tex_scale' parameter is deprecated and has been replaced by 'tex_depth'.")tex_scale
                  : default(tex_depth,1)
    )
    assert(is_region(region), "\nInput is not a region or polygon.")
    assert(is_num(scale) || is_vector(scale))
    assert(is_vector(shift, 2), str(shift))
    assert(is_bool(caps) || is_bool_list(caps,2), "\ncaps must be boolean or a list of two booleans.")
    let(
        h = one_defined([h, height,l,length],"h,height,l,length",dflt=1),
        regions = region_parts(region),
        vnf = !is_undef(texture)?
                        _textured_linear_sweep(
                                               region, h=h, caps=caps, 
                                               texture=texture, tex_size=tex_size,
                                               counts=tex_reps, inset=tex_inset,
                                               rot=tex_rot, tex_scale=tex_depth,
                                               twist=twist, scale=scale, shift=shift,
                                               style=style, samples=tex_samples)
            : let(
                  caps = is_bool(caps) ? [caps,caps] : caps, 
                  anchor = center==true? "origin" :
                      center == false? "original_base" :
                      default(anchor, "original_base"),
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
                  ])
              )
              vnf,
        regparts = flatten(regions),
        sizes = [0,each cumsum([for(entry=regparts) len(entry)])],
        ganchors = [
          for(i=idx(regparts))
            let(
                bot = path3d(regparts[i],-h/2),
                top = path3d(move(shift,scale(scale, zrot(-twist, regparts[i]))),h/2)
            )
            each _make_all_prism_anchors(bot,top, startind=sizes[i])
        ],    
        anchors = [
            named_anchor("original_base", [0,0,-h/2], DOWN),
            named_anchor("original_top", [0,0,h/2], UP),
            each ganchors
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
            assert(in_list(atype, ["hull","intersect","bbox"]), "\nAnchor type must be \"hull\", \"intersect\", or \"bbox\".")
    ) _return_geom ? [vnf,geom] : reorient(anchor,spin,orient, geom=geom, p=vnf);


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
//   Takes a path or [region](regions.scad) and sweeps it in a rotation around the Z axis, with optional texturing.
//   When called as a function, returns a [VNF](vnf.scad).
//   When called as a module, creates the sweep as geometry.  By default the sweep starts on the X+ axis.  For 360 degree sweeps this
//   may be inconsistent with the native rotate_extrude(), which historically started on the X- axis.  The `start` parameter changes where
//   the sweep starts; set it to 180 to get the historical rotate_extrude() behavior.  
//   .
//   The region or path that you provide to sweep is defined in the XY plane and cannot have any negative x values.  By default a path is treated as a closed shape.
//   (Regions are always composed of closed polygons.)  When you apply a texture, no path in your region can have more than one edge on the Y axis.  
//   If you give a path whose endpoints are not on the Y axis and specify `caps=true` then the path
//   endpoints are connected to the Y axis by a horizontal segment at each end, and the corresponding top and bottom surfaces in the revolution do not receive texture.
//   You can terminate just one end of the path on the Y axis and in this case, you get a single untextured cap.  If your texture is not zero at the
//   edges, the endcaps may appear textured rather than flat, because the top perimeter follows the texture.  
//   .
//   When `caps=true` you can use `tex_taper` to change the depth of the texture along the length of the path given in `shape`.  This
//   can be useful for forcing flat caps on a textured object by forcing the texture depth to zero at the ends.  
//   The simplest option is to set `tex_taper` to a value between 0 and 0.5.  In this case, the texture depth linearly falls to zero
//   at both ends, starting at the specified fraction from the end.  For example, if `tex_taper=1/3` then the center third of the object
//   will have the normal texture depth, and the texture falls to zero over the top and bottom thirds.  For more control over the texture
//   tapering you can also set `tex_taper` to a lookup table suited to the `lookup()` function.  The lookup table is evaluated at 0 to
//   determine the texture depth multiplier at the bottom and at 1 to determine the texture depth multiplier at the top.  The final option is
//   to set `tex_taper` to a function that takes one parameter and is defined on [0,1].  Using these more sophisticated methods you can actually
//   change the shape of the object.  If you want to ensure flat caps, simply make sure that your lookup table or function maps both zero and one to zero.
//   Texture multipliers can be any number.  If the multiplier is negative it inverts the texture, and if the multiplier exceeds one, the texture
//   scales to larger than your specified `tex_depth` value.  
//   .
//   If you want to place just one or a few copies of a texture onto an object rather than texturing the entire object you can do that by using
//   and angle smaller than 360.  However, if you want to control the aspect ratio of the resulting texture you must carefully calculate the proper
//   angle to use to ensure that the arc length in the horizontal direction is the proper length compared to the arc length in the vertical direction.
//   To simplify this process you can use `pixel_aspect` or `tex_aspect`.  You can set `tex_aspect` for any type of tile and it specifies
//   the desired aspect ratio (width/height) for the tiles.  You must specify `tex_reps` in order to use this feature.  For heightfields you can instead provide
//   a pixel aspect ratio, which is suited to the case where your texture is a non-square image that you want to place on a curved object.  For a simple cylinder
//   it is obvious what the horizontal arc length is; for other objects this is computed based on the average radius of the longest path in `shape`.  
// Arguments:
//   shape = The polygon or [region](regions.scad) to sweep around the Z axis.
//   angle = If given, specifies the number of degrees to sweep the region around the Z axis, counterclockwise from the X+ axis.  Default: 360 (full rotation)
//   ---
//   start = Start extrusion at this angle counterclockwise from the X+ axis.  Default:0
//   texture = A texture name string, or a rectangular array of scalar height values (0.0 to 1.0), or a VNF tile that defines the texture to apply to vertical surfaces.  See {{texture()}} for what named textures are supported.
//   tex_size = An optional 2D target size (2-vector or scalar) for the textures.  Actual texture sizes are scaled somewhat to evenly fit the available surface. Default: `[5,5]`
//   tex_reps = If given instead of tex_size, a scalar or 2-vector giving the integer number of texture tile repetitions in the horizontal and vertical directions.
//   tex_inset = If numeric, lowers the texture into the surface by the specified proportion, e.g. 0.5 would lower it half way into the surface.  If `true`, insets by exactly its full depth.  Default: `false`
//   tex_rot = Rotate texture by specified angle, which must be a multiple of 90 degrees.  Default: 0
//   tex_depth = Specify texture depth; if negative, invert the texture.  Default: 1.
//   tex_samples = Minimum number of "bend points" to have in VNF texture tiles.  Default: 8
//   tex_taper = If `caps=true`, scales the texture depth along the path given in `shape`.  If set to a scalar between 0 and 0.5, adjusts the specfied top and bottom fraction of the path linearly to zero depth.  You can also provide a lookup table or function defining the scala factor over the range [0,1].  Default: no taper
//   tex_aspect = Choose the angle of the revolution to maintain this aspect ratio for the tiles.  You must specify tex_reps.  Overrides any angle specified.  
//   pixel_aspect = Choose the angle of the revolution to maintain this apsect ratio for pixels in a heightfield texture.  You must specify tex_reps.  Overrides any angle specified.
//   style = {{vnf_vertex_array()}} style.  Default: "min_edge"
//   caps = If true and `shape` is a path whose endpoints are to the right of the Y axis, then adds untextured caps to the top and/or bottom of the revolved surface.  Ignored if `shape` is not a path or if its endpoints are on the Y axis.   Default: `false`
//   convexity = (Module only) Convexity setting for use with polyhedron.  Default: 10
//   cp = Centerpoint for determining "intersect" anchors or centering the shape.  Determintes the base of the anchor vector.  Can be "centroid", "mean", "box" or a 3D point.  Default: "centroid"
//   atype = Select "hull" or "intersect" anchor types.  Default: "hull"
//   anchor = Translate so anchor point is at the origin. Default: "origin"
//   spin = Rotate this many degrees around Z axis after anchor. Default: 0
//   orient = Vector to rotate top toward after spin (module only)
// Named Anchors:
//   "origin" = The native position of the shape.  
// Anchor Types:
//   "hull" = Anchors to the virtual convex hull of the shape.
//   "intersect" = Anchors to the surface of the shape.
// Example(3D,NoAxes,VPR=[60.20,0.00,41.80],VPD=151.98,VPT=[0.85,-2.95,3.10]): Sweeping a shape that looks like a plus sign
//   rgn = right(30,
//           union([for (a = [0, 90])
//                    zrot(a, rect([15,5]))]));
//   rotate_sweep(rgn);
// Example(3D,NoAxes,VPR=[50.40,0.00,28.50],VPD=208.48,VPT=[0.23,-1.89,5.20]): Sweeping a region with multiple components
//   rgn = [
//       for (a = [0, 120, 240]) let(
//           cp = polar_to_xy(15, a) + [30,0]
//       ) each [
//           move(cp, p=circle(r=10)),
//           move(cp, p=hexagon(d=15)),
//       ]
//   ];
//   rotate_sweep(rgn, angle=240);
// Example(3D,NoAxes,VPR=[55.00,0.00,25.00],VPD=292.71,VPT=[1.59,1.80,-1.35]): Torus with bricks texture
//   path = right(50, p=circle(d=40));
//   rotate_sweep(path, texture="bricks_vnf",tex_size=10,
//                  tex_depth=0.5, style="concave");
// Example(3D,NoAxes,VPR=[76.30,0.00,44.60],VPD=257.38,VPT=[2.58,-5.21,0.37]): Applying a texture to a region.  Both the inside and outside receive texture.
//   rgn = [
//       right(40, p=circle(d=50)),
//       right(40, p=circle(d=40,$fn=6)),
//   ];
//   rotate_sweep(
//       rgn, texture="diamonds",
//       tex_size=[10,10], tex_depth=1,
//       angle=240, style="concave");
// Example(NoAxes): The simplest way to create a cylinder with just a single line segment and `caps=true`.  With this cylinder, the top and bottom have no texture.  
//   rotate_sweep([[20,-10],[20,10]], texture="dots",
//                tex_reps=[6,2],caps=true);
// Example(NoAxes): If we manually connect the top and bottom then they also receive texture.  
//   rotate_sweep([[0,-10],[20,-10],[20,10],[0,10]], 
//                tex_reps=[6,6],tex_depth=1.5,
//                texture="dots");
// Example(NoAxes,VPR=[95.60,0.00,69.80],VPD=74.40,VPT=[5.81,5.74,1.97]): You can connect just the top or bottom alone instead of both to get texture on one and a flat cap on the other.  Here you can see that the sloped top has texture but the bottom does not.  Also, the texture doesn't fit neatly on the side and top like it did in the previous two examples, but makes a somewhat ugly transition across the corner.  You have to size your object carefully so that the tops and sides each fit an integer number of texture tiles to avoid this type of transition.  
//   rotate_sweep([[15,-10],[15,10],[0,15]],
//                texture="dots", tex_reps=[6,6],
//                angle=90,caps=true,tex_depth=1.5);
// Example(NoAxes,VPR=[55.00,0.00,25.00],VPD=126.00,VPT=[1.37,0.06,-0.75]): Ribbed sphere. 
//   path = arc(r=20, $fn=64, angle=[-90, 90]);
//   rotate_sweep(path, 360, texture = texture("wave_ribs",n=15),
//                tex_size=[8,1.5]);
// Example(3D,NoAxes,VPR=[60.20,0.00,56.50],VPD=231.64,VPT=[4.18,-2.66,1.31]): This model uses `caps=true` to create the untextured caps with a user supplied texture.  They are flat because the texture is zero at its edges.
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
//       path, caps=true, 
//       texture=tex, tex_size=[20,20],
//       tex_depth=1, style="concave");
// Example(3D,NoAxes,VPR=[60.20,0.00,56.50],VPD=187.63,VPT=[2.07,-4.53,2.58]):  An example with a more complicated path.  Here the caps are not flat because the diamonds texture is not zero at the edges.  
//   bezpath = [
//       [15, 30], [10,15],
//       [10,  0], [20, 10], [30,12],
//       [30,-12], [20,-10], [10, 0],
//       [10,-15], [15,-30]
//   ];
//   path = bezpath_curve(bezpath, splinesteps=32);
//   rotate_sweep(
//       path, caps=true, 
//       texture="diamonds", tex_size=[10,10],
//       tex_depth=1, style="concave");
// Example(3D,NoAxes,VPR=[70.00,0.00,58.60],VPD=208.48,VPT=[1.92,-3.81,2.21]): The normal direction at the ends is perpendicular to the Z axis, so even though the texture is not zero, the caps are flat, unlike the previous example.
//   path = [
//       [20, 30], [20, 20],
//       each arc(r=20, corner=[[20,20],[10,0],[20,-20]]),
//       [20,-20], [20,-30],
//   ];
//   rotate_sweep(
//       path, caps=true, 
//       texture="diamonds",
//       tex_size=[5,5], tex_depth=1,
//       style="concave",
//       convexity=10);
// Example(3D,NoAxes,VPR=[59.20,0.00,226.90],VPD=113.40,VPT=[-4.53,3.03,3.84]): The top cap is definitely not flat.  
//   rotate_sweep(
//       arc(r=20,angle=[-45,45],n=45),
//       caps=true, texture="diamonds",
//       tex_size=[5,5], tex_depth=2,
//       convexity=10);
// Example(3D,NoAxes,VPR=[59.20,0.00,226.90],VPD=113.40,VPT=[-4.53,3.03,3.84]): Setting `tex_taper=0` abruptly tapers right at the caps so that the cap is flat:
//   rotate_sweep(
//       arc(r=20,angle=[-45,45],n=45),
//       caps=true, texture="diamonds",
//       tex_size=[5,5], tex_depth=2,
//       tex_taper=0, convexity=10);
// Example(3D,NoAxes,VPR=[59.20,0.00,226.90],VPD=113.40,VPT=[-4.53,3.03,3.84]): Setting `tex_taper=0.5` tapers gradually across the entire shape:
//   rotate_sweep(
//       arc(r=20,angle=[-45,45],n=45),
//       caps=true, texture="diamonds",
//       tex_size=[5,5], tex_depth=2,
//       tex_taper=.5, convexity=10);
// Example(3D,VPR=[59.20,0.00,91.10],VPD=126.00,VPT=[4.29,2.29,2.31],NoAxes): The path given here starts and ends on the Y axis, but you can still request (zero size) caps so that you can use tapering, which is permitted only when caps are enabled.  
//   rotate_sweep(
//      arc(r=20, angle=[-90,90], n=45), texture="dots",
//      caps=true, tex_reps=[15,10], tex_taper=0.5, tex_depth=2);
// Example(3D, NoAxes): Tapering of textures via lookup table to be maximal at the bottom and 0 at the top.  
//   path = [
//       [20, 30], [20, 20],
//       each arc(r=20, corner=[[20,20],[10,0],[20,-20]]),
//       [20,-20], [20,-30],
//   ];
//   rotate_sweep(
//       path, caps=true, 
//       texture="trunc_pyramids",
//       tex_size=[5,5], tex_depth=1,
//       tex_taper=[[0,1], [1,0]],
//       style="convex",
//       convexity=10);
// Example(3D,NoAxes,VPR=[106.10,0.00,158.30],VPD=155.56,VPT=[-2.68,-0.92,1.07]): Here we use a cosine function (lifted so it stays nonnegative) to scale the texture.  Since the taper function rises as high as 2 the effective texture depth is 4 at the peaks.
//   rotate_sweep([[20,-20],[20,20]],texture="trunc_diamonds",
//                caps=true, tex_reps=[20,16], tex_depth=2,
//                tex_taper=function(x) 1-cos(360*3*x));
// Example(3D,NoAxes,VPR=[83.70,0.00,195.40],VPD=82.67,VPT=[-1.69,4.43,0.46]): Here we use a sine function that goes below zero in the top half of the object.  This inverts the texture and the result is that the inverted texture bulges outward with the change in the texture depth that the taper applies.  In the bottom section, the scaling applies directly.  
//   rotate_sweep([[10,-12],[10,12]], caps=true, tex_reps=[16,6],
//                tex_taper=function(x) sin(360*x),tex_depth=2,
//                texture="dots");
// Example(3D,NoAxes,VPR=[83.70,0.00,195.40],VPD=82.67,VPT=[-1.69,4.43,0.46]): We adjust the VNF texture from the previous example so its "zero" level is at 1/2.  This makes the result symmetric between the positive and negative taperings.  
//      tex = up(1/2,zscale(1/2,texture("dots")));
//      rotate_sweep([[10,-12],[10,12]], caps=true, tex_reps=[16,6],
//                   tex_taper=function(x) sin(360*x),tex_depth=2,
//                   texture=tex);
// Example(3D,NoAxes,VPR=[72.50,0.00,119.10],VPD=155.56,VPT=[7.95,8.65,3.01]): Here we create a texture effect entirely with tapering using a constant "texture" of 3/4.  The inverted texture is 1-3/4 = 1/4, so the negative regions of the function create shallower bands.  
//    rotate_sweep([[20,-20],[20,20]], caps=true, tex_reps=[30,45], texture=[[3/4]],
//                 tex_taper=function(x) sin(2.5*360*x),tex_depth=4);
// Example(3D,NoAxes,Med,VPT=[-2.92656,1.26781,0.102897],VPR=[62.7,0,222.4],VPD=216.381): This VNF tile makes a closed shape and the actual main extrusion is not created.  We give `caps=true` to prevent the shape from being closed on the outside, but because the VNF tile has no edges, no actual cap is created.  
//   shape = skin([rect(2/5),
//                 rect(2/3),
//                 rect(2/5)],
//                z=[0,1/2,1],
//                slices=0,
//                caps=false);
//   tile = move([0,1/2,2/3],yrot(90,shape));
//   path = [for(y=[-30:30]) [ 20-3*(1-cos((y+30)/60*360)),y]];
//   rotate_sweep(path, caps=false, texture=tile, 
//                tex_size=[10,10], tex_depth=5);
// Example(3D,Med,VPT=[1.04269,4.35278,-0.716624],VPR=[98.4,0,43.9],VPD=175.268): Adding the angle parameter cuts off the extrusion.  Note how each extruded component is capped.  
//   shape = skin([rect(2/5),
//                 rect(2/3),
//                 rect(2/5)],
//                z=[0,1/2,1],
//                slices=0,
//                caps=false);
//   tile = move([0,1/2,2/3],yrot(90,shape));
//   path = [for(y=[-30:30]) [ 20-3*(1-cos((y+30)/60*360)),y]];
//   rotate_sweep(path, caps=true, texture=tile, 
//                tex_size=[10,15], tex_depth=5, angle=215);
// Example(3D,NoAxes,Med,VPT=[1.00759,3.89216,-1.27032],VPR=[57.1,0,34.8],VPD=240.423): Turning the texture 90 degrees with `tex_rot` produces a texture that ends at the top and bottom.
//   shape = skin([rect(2/5),
//                 rect(2/3),
//                 rect(2/5)],
//                z=[0,1/2,1],
//                slices=0,
//                caps=false);
//   tile = move([0,1/2,2/3],yrot(90,shape));
//   path = [for(y=[-30:30]) [ 20-3*(1-cos((y+30)/60*360)),y]];
//   rotate_sweep(path, caps=true, texture=tile, tex_rot=90,
//                tex_size=[12,8], tex_depth=9, angle=360);
// Example(3D,Med,NoAxes,VPR=[78.1,0,199.3],VPT=[-4.55445,1.37814,-4.39897],VPD=192.044): A basket weave texture, here only halfway around the circle to avoid clutter.  
//     diag_weave_vnf = [
//         [[0.2, 0, 0], [0.8, 0, 0], [1, 0.2, 0.5], [1, 0.8, 0.5], [0.7, 0.5, 0.5],
//          [0.5, 0.3, 0], [0.2, 0, 0.5], [0.8, 0, 0.5], [1, 0.2, 1], [1, 0.8, 1],
//          [0.7, 0.5, 1], [0.5, 0.3, 0.5], [1, 0.2, 0], [1, 0.8, 0], [0.8, 1, 0.5],
//          [0.2, 1, 0.5], [0.5, 0.7, 0.5], [0.7, 0.5, 0], [0.8, 1, 1], [0.2, 1, 1],
//          [0.5, 0.7, 1], [0.8, 1, 0], [0.2, 1, 0], [0, 0.8, 0.5], [0, 0.2, 0.5],
//          [0.3, 0.5, 0.5], [0.5, 0.7, 0], [0, 0.8, 1], [0, 0.2, 1], [0.3, 0.5, 1],
//          [0, 0.8, 0], [0, 0.2, 0], [0.3, 0.5, 0], [0.2, 0, 1], [0.8, 0, 1], [0.5, 0.3, 1]],
//         [[0, 1, 5], [1, 2, 4, 5], [7, 11, 10, 8], [8, 10, 9], [7, 8, 2, 1], [9, 10, 4, 3],
//          [10, 11, 5, 4], [0, 5, 11, 6], [12, 13, 17], [13, 14, 16, 17], [3, 4, 20, 18],
//          [18, 20, 19], [3, 18, 14, 13], [19, 20, 16, 15], [20, 4, 17, 16], [12, 17, 4, 2],
//          [21, 22, 26], [22, 23, 25, 26], [15, 16, 29, 27], [27, 29, 28], [15, 27, 23, 22],
//          [28, 29, 25, 24], [29, 16, 26, 25], [21, 26, 16, 14], [30, 31, 32], [31, 6, 11, 32],
//          [24, 25, 35, 33], [33, 35, 34], [24, 33, 6, 31], [34, 35, 11, 7],
//          [35, 25, 32, 11], [30, 32, 25, 23]]
//     ];
//     path = [for(y=[-30:30]) [ 20-3*(1-cos((y+30)/60*360)),y]];
//     down(31)linear_extrude(height=1)arc(r=23,angle=[0,180], wedge=true);
//     rotate_sweep(path, caps=true, texture=diag_weave_vnf, angle=180,
//                  tex_size=[10,10], convexity=12, tex_depth=2);
// Example(3D,VPR=[59.20,0.00,159.20],VPD=74.40,VPT=[7.45,6.83,1.54],NoAxes): Textures can be used to place images onto objects.  If you want to place an image onto a cylinder you probably don't want it to cover the whole cylinder, or to create many small copies.  To do this you can create a textured cylinder with an angle less than 360 degrees to hold the texture.  In this example we calculate the angle so that the output has the same aspect ratio.  The default `tex_extra` of zero for a single tile ensures that the image appears without an extra border.  
//   img = [
//      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
//      [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0],
//      [0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0],
//      [0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0],
//      [0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0],
//      [0, 1, 0, 0, 0,.5,.5, 0, 0, 0, 1, 0],
//      [0, 1, 0, 0, 0,.5,.5, 0, 0, 0, 1, 0],
//      [0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0],
//      [0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0],
//      [0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0],
//      [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0],
//      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
//   ];
//   h = 20;
//   r = 15;
//   ang = len(img[0])/len(img)*h/(2*PI*r)*360;
//   rotate_sweep([[r,-h/2],[r,h/2]], texture=img,
//                tex_reps=1,angle=ang, caps=true);
// Example(3D,VPR=[80.20,0.00,138.40],VPD=82.67,VPT=[6.88,7.29,1.77],NoAxes): Here we have combined the above model with a suitable cylinder.  With a coarse texture like this you need to either match the `$fn` of the cylinder to the texture, or choose a sufficiently fine cylinder to avoid conflicting facets.  
//   img = [
//      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
//      [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0],
//      [0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0],
//      [0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0],
//      [0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0],
//      [0, 1, 0, 0, 0,.5,.5, 0, 0, 0, 1, 0],
//      [0, 1, 0, 0, 0,.5,.5, 0, 0, 0, 1, 0],
//      [0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0],
//      [0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0],
//      [0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0],
//      [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0],
//      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
//   ];
//   h = 20;
//   r = 15;
//   ang = len(img[0])/len(img)*h/(2*PI*r)*360;
//   rotate_sweep([[r,-h/2],[r,h/2]], texture=img,
//                tex_reps=1,angle=ang, caps=true);
//   cyl(r=r,h=27,$fn=128);
// Example(3D,VPR=[68.30,0.00,148.90],VPD=91.85,VPT=[-0.56,5.78,-0.90],NoAxes): Above we explicitly calculated the required angle to produce the correct aspect ratio.  Here we use `pixel_aspect` which produces an output whose average width has the desired aspect ratio.  
//   img = [
//      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
//      [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0],
//      [0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0],
//      [0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0],
//      [0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0],
//      [0, 1, 0, 0, 0,.5,.5, 0, 0, 0, 1, 0],
//      [0, 1, 0, 0, 0,.5,.5, 0, 0, 0, 1, 0],
//      [0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0],
//      [0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0],
//      [0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0],
//      [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0],
//      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
//   ];
//   rotate_sweep([[15,-10],[5,10]], texture=img,
//                tex_reps=[1,1], caps=true, pixel_aspect=1);
//   cyl(r1=16,r2=4,h=24,$fn=128);
// Example(3D,VPR=[96.30,0.00,133.50],VPD=54.24,VPT=[1.94,2.85,-0.47]): Here we apply the texture to a sphere using the automatic `pixel_aspect` to determine the angle.  Note that using {{spheroid()}} with the circum option eliminates artifacts arising due to mimatched faceting.  
//   img = [
//      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
//      [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0],
//      [0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0],
//      [0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0],
//      [0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0],
//      [0, 1, 0, 0, 0,.5,.5, 0, 0, 0, 1, 0],
//      [0, 1, 0, 0, 0,.5,.5, 0, 0, 0, 1, 0],
//      [0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0],
//      [0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0],
//      [0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0],
//      [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0],
//      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
//   ];
//   arc = arc(r=10, angle=[-44,44],n=100);
//   rotate_sweep(arc, texture=img, tex_reps=[1,1],
//                caps=true, pixel_aspect=1);
//   spheroid(10,$fn=64,circum=true);



function rotate_sweep(
    shape, angle=360,
    texture, tex_size=[5,5], tex_counts, tex_reps, 
    tex_inset=false, tex_rot=0,
    tex_scale, tex_depth, tex_samples, tex_aspect, pixel_aspect, 
    tex_taper, shift=[0,0], caps, closed, 
    style="min_edge", cp="centroid",
    atype="hull", anchor="origin",
    spin=0, orient=UP, start=0, 
    _tex_inhibit_y_slicing
) =
    assert(num_defined([closed,caps])<2, "\nIn rotate_sweep the `closed` paramter has been replaced by `caps` with the opposite meaning. You cannot give both.")
    assert(num_defined([tex_reps,tex_counts])<2, "\nIn rotate_sweep() the 'tex_counts' parameters has been replaced by 'tex_reps'. You cannot give both.")
    assert(num_defined([tex_scale,tex_depth])<2, "\nIn linear_sweep() the 'tex_scale' parameter has been replaced by 'tex_depth'. You cannot give both.")
    assert(!is_path(shape) || caps || len(shape)>=3, "\n'shape' is a path and caps=false, but a closed path requires three points.")
    let(
         caps = is_def(caps) ? caps
              : is_def(closed) ? !closed
              : false,
         tex_reps = is_def(tex_counts)? echo("In rotate_sweep() the 'tex_counts' parameter is deprecated and has been replaced by 'tex_reps'")tex_counts
                  : tex_reps,
         tex_depth = is_def(tex_scale)? echo("In rotate_sweep() the 'tex_scale' parameter is deprecated and has been replaced by 'tex_depth'")tex_scale
                   : default(tex_depth,1),
         region = _force_xplus(force_region(shape))
    )
    assert(is_region(region), "\nshape is not a region or path.")
    let(
        bounds = pointlist_bounds(flatten(region)),
        min_x = bounds[0].x,
        max_x = bounds[1].x,
        min_y = bounds[0].y,
        max_y = bounds[1].y,
        h = max_y - min_y
    )
    assert(min_x>=0, "\nInput region must exist entirely in the X+ half-plane.")
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
        taper=tex_taper, tex_aspect=tex_aspect, pixel_aspect=pixel_aspect, 
        shift=shift,
        closed=!caps,
        angle=angle,
        style=style,
        start=start
    ) :
    let(
        region = is_path(shape) && caps ? [deduplicate([[0,shape[0].y], each shape, [0,last(shape).y]])]
               : region,
        steps = ceil(segs(max_x) * angle / 360) + (angle<360? 1 : 0),
        skmat = down(min_y) * skew(sxz=shift.x/h, syz=shift.y/h) * up(min_y),
        transforms = [
            if (angle==360) for (i=[0:1:steps-1]) skmat * rot([90,0,start+360-i*360/steps]),
            if (angle<360) for (i=[0:1:steps-1]) skmat * rot([90,0,start+angle-i*angle/(steps-1)]),
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


function _force_xplus(data) =
  [for(part=data) [for(pt=part) approx(pt.x,0) ? [0,pt.y] : pt]];

module rotate_sweep(
    shape, angle=360,
    texture, tex_size=[5,5], tex_counts, tex_reps,
    tex_inset=false, tex_rot=0,
    tex_scale, tex_depth, tex_samples,
    tex_taper, shift=[0,0],
    style="min_edge",
    caps, closed, tex_extra, tex_aspect, pixel_aspect,
    cp="centroid",
    convexity=10,
    atype="hull",
    anchor="origin",
    spin=0,
    orient=UP, start=0, 
    _tex_inhibit_y_slicing=false
) {
    dummy =
       assert(num_defined([closed,caps])<2, "\nIn rotate_sweep the `closed` paramter has been replaced by `caps` with the opposite meaning.  You cannot give both.")
       assert(num_defined([tex_reps,tex_counts])<2, "\nIn rotate_sweep() the 'tex_counts' parameters has been replaced by 'tex_reps'.  You cannot give both.")
       assert(num_defined([tex_scale,tex_depth])<2, "\nIn rotate_sweep() the 'tex_scale' parameter has been replaced by 'tex_depth'.  You cannot give both.")
       assert(!is_path(shape) || caps || len(shape)>=3, "\n'shape' is a path and caps=false, but a closed path requires three points.");
    caps = is_def(caps) ? caps
         : is_def(closed) ? !closed
         : false;
    tex_reps = is_def(tex_counts)? echo("In rotate_sweep() the 'tex_counts' parameter is deprecated and has been replaced by 'tex_reps'")tex_counts
             : tex_reps;
    tex_depth = is_def(tex_scale)? echo("In rotate_sweep() the 'tex_scale' parameter is deprecated and has been replaced by 'tex_depth'")tex_scale
              : default(tex_depth,1);
    region = _force_xplus(force_region(shape));
    check = assert(is_region(region), "\nInput is not a region or polygon.");
    bounds = pointlist_bounds(flatten(region));
    min_x = bounds[0].x;
    max_x = bounds[1].x;
    min_y = bounds[0].y;
    max_y = bounds[1].y;
    h = max_y - min_y;
    check2 = assert(min_x>=0, "\nInput region must exist entirely in the X+ half-plane.");
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
            shift=shift,tex_extra=tex_extra,tex_aspect=tex_aspect, pixel_aspect=pixel_aspect, 
            closed=!caps,
            inhibit_y_slicing=_tex_inhibit_y_slicing,
            angle=angle,
            style=style,
            atype=atype, anchor=anchor, 
            spin=spin, orient=orient, start=start
        ) children();
    } else {
        region = is_path(shape) && caps ? [deduplicate([[0,shape[0].y], each shape, [0,last(shape).y]])]
               : region;
        steps = ceil(segs(max_x) * angle / 360) + (angle<360? 1 : 0);
        skmat = down(min_y) * skew(sxz=shift.x/h, syz=shift.y/h) * up(min_y);
        transforms = [
            if (angle==360) for (i=[0:1:steps-1]) skmat * rot([90,0,start+360-i*360/steps]),
            if (angle<360) for (i=[0:1:steps-1]) skmat * rot([90,0,start+angle-i*angle/(steps-1)]),
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
//   of a given radius, height, and degrees of rotation.  The origin in the profile traces out the helix of the specified radius.
//   If turns is positive the path is right-handed;  if turns is negative the path is left-handed.
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
//   toward the outside, like would be needed for internal threading.  If internal is fale then the lead-in sections scale
//   toward the inside, like would be appropriate for external threads.  
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
//   internal = if true make internal threads.  The only effect this has is to change how the extrusion lead-in section are formed. When true, the extrusion scales toward the outside; when false, it scales toward the inside.  Default: false
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top toward, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
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
    assert(is_num(turns) && turns != 0, "\nturns must be a nonzero number.")
    assert(all_positive([h]), "\nSpiral height must be a positive number.")
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
                      assert(is_undef(user_ang) || is_undef(lead_in1), "\nCannot define lead_in/lead_in1 by both length and angle.")
                      is_def(user_ang) ? user_ang : default(lead_in1,0)*360/(2*PI*r1),
        lead_in_ang2 =
                      let(
                           user_ang = first_defined([lead_in_ang2,lead_in_ang])
                      )
                      assert(is_undef(user_ang) || is_undef(lead_in2), "\nCannot define lead_in/lead_in2 by both length and angle.")
                      is_def(user_ang) ? user_ang : default(lead_in2,0)*360/(2*PI*r2),
        minang = -max(0,lead_in_ang1),
        maxang = 360*turns + max(0,lead_in_ang2),
        cut_ang1 = minang+abs(lead_in_ang1),
        cut_ang2 = maxang-abs(lead_in_ang2),        
        lead_in_shape1 = first_defined([lead_in_shape1, lead_in_shape, "default"]),
        lead_in_shape2 = first_defined([lead_in_shape2, lead_in_shape, "default"]),             
        lead_in_func1 = is_func(lead_in_shape1) ? lead_in_shape1
                      : assert(is_string(lead_in_shape1),"\nlead_in_shape/lead_in_shape1 must be a function or string.")
                        let(ind = search([lead_in_shape1], _lead_in_table,0)[0])
                        assert(ind!=[],str("\nUnknown lead_in_shape, \"",lead_in_shape1,"\"."))
                        _lead_in_table[ind[0]][1],
        lead_in_func2 = is_func(lead_in_shape2) ? lead_in_shape2
                      : assert(is_string(lead_in_shape2),"\nlead_in_shape/lead_in_shape2 must be a function or string.")
                        let(ind = search([lead_in_shape2], _lead_in_table,0)[0])
                        assert(ind!=[],str("\nUnknown lead_in_shape, \"",lead_in_shape2,"\"."))
                        _lead_in_table[ind[0]][1]
    )
    assert( cut_ang1<cut_ang2, "\nTapers are too long to fit.")
    assert( all_positive([r1,r2]), "\nDiameter/radius must be positive.")
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
// Topics: Extrusion, Sweep, Paths, Textures
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
// Figure(3D,Big,VPR=[70,0,345],VPD=20,VPT=[5.5,10.8,-2.7],NoScales): This example shows how the shape, in this case the quadrilateral defined by `[[0, 0], [0, 1], [0.25, 1], [1, 0]]`, appears as the cross section of the swept polyhedron.  The blue line shows the path.  The normal vector to the shape is shown in black; it is based at the origin and points upward in the Z direction.  The sweep aligns this normal vector with the blue path tangent, which in this case, flips the shape around.  For a 2D path like this one, the Y direction in the shape is mapped to the Z direction in the sweep.
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
//   that follows the path.  For a 2D path, the Y axis of the shape is mapped to the Z axis and in this case,
//   pointing the quadrilateral's normal vector (in black) along the tangent line of
//   the path, which is going in the direction of the blue arrow, requires that the quadrilateral be "turned around".  If we
//   reverse the order of points in the path we get a different result:
// Figure(3D,Big,VPR=[70,0,20],VPD=20,VPT=[1.25,9.25,-2.65],NoScales): The same sweep operation with the path traveling in the opposite direction.  To line up the normal correctly, the shape is reversed compared to Figure 1, so the resulting sweep looks quite different.
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
//   other.  This results in an invalid polyhedron, which may appear OK when previewed or rendered alone, but can result
//   in cryptic CGAL errors when rendered with a second object in your model.  You may be able to use {{path_sweep2d()}}
//   to produce a valid model in cases like this.  You can debug models like this using the `profiles=true` option, which shows all
//   the cross sections in your polyhedron.  If any of them intersect, the polyhedron will be invalid.
// Figure(3D,Big,VPR=[47,0,325],VPD=23,VPT=[6.8,4,-3.8],NoScales): We have scaled the path to an ellipse and show a large triangle as the shape.  The triangle is sometimes bigger than the local radius of the path, leading to an invalid polyhedron, which you can identify because the red lines cross in the middle.
//   tri= scale([4.5,2.5],[[0, 0], [0, 1], [1, 0]]);
//   path = xscale(1.5,arc(r=5,n=81,angle=[-70,70]));
//   % path_sweep(tri,path);
//   T = path_sweep(tri,path,transforms=true);
//   color("red")for(i=[0:20:80]) stroke(apply(T[i],path3d(tri)),width=.1,closed=true);
//   color("blue")stroke(path3d(xscale(1.5,arc(r=5,n=81,angle=[-70,80]))),width=.1,endcap2="arrow2");
// Continues:
//   During the sweep operation the shape's normal vector aligns with the tangent vector of the path.
//   This leaves an ambiguity about how the shape is rotated as it sweeps along the path.
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
//   rotations that map the shape exactly onto itself, so a pentagon has 5-fold symmetry.  This argument is valid
//   only for closed sweeps.  When you specify symmetry, the twist must be a multiple of 360/symmetry.
//   .
//   The twist is normally spread uniformly along your shape based on the path length.  If you set `twist_by_length` to
//   false, then the twist is uniform based on the point count of your path.  Twisted shapes produce twisted
//   faces, so if you want them to look good, you should use lots of points on your path and also lots of points on the
//   shape.  If your shape is a simple polygon, use {{subdivide_path()}} to increase
//   the number of points.
//   .
//   As noted above, the sweep process has an ambiguity regarding the twist.  For 2D paths it is easy to resolve this
//   ambiguity by aligning the Y axis in the shape to the Z axis in the swept polyhedron.  When the path is
//   three-dimensional, things become more complex.  It is no longer possible to use a simple alignment rule like the
//   one we use in 2D.  You may find that the shape rotates unexpectedly around its axis as it traverses the path.  The
//   `method` parameter allows you to specify how the shapes are aligned, resulting in different twist in the resulting
//   polyhedron.  You can choose from three different methods for selecting the rotation of your shape.  None of these
//   methods produce good, or even valid, results on all inputs, so it is important to select a suitable method.
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
//   can also supply `last_normal` to provide an ending orientation constraint.  Be aware that the curve may still exhibit
//   twisting in the middle.  This method is the default because it is the most robust, not because it generally produces the best result.
//   .
//   The "natural" method works by computing the Frenet frame at each point on the path.  This is defined by the tangent to the curve and
//   the normal that lies in the plane defined by the curve at each point.  This normal points in the direction of curvature of the curve.
//   The result is a well-behaved set of shape positions without any unexpected twisting&mdash;as long as the curvature never falls to zero.  At a
//   point of zero curvature (a flat point), the curve does not define a plane and the natural normal is not defined.  Furthermore, even if
//   you skip over this troublesome point so the normal is defined, it can change direction abruptly when the curvature is zero, leading to
//   a nasty twist and an invalid model.  A simple example is a circular arc joined to another arc that curves the other direction.  Note
//   that the X axis of the shape is aligned with the normal from the Frenet frame.
//   .
//   The "manual" method allows you to specify your desired normal either globally with a single vector, or locally with
//   a list of normal vectors for every path point.  The normal you supply is projected to be orthogonal to the tangent to the
//   path, and the Y direction of your shape is aligned with the projected normal. (This is different from the "natural" method.)
//   Careless choice of a normal may result in a twist in the shape, or an error if your normal is parallel to the path tangent.
//   If you set `relax=true` then the condition that the cross sections are orthogonal to the path is relaxed and the swept object
//   uses the actual specified normal.  In this case, the tangent is projected to be orthogonal to your supplied normal to define
//   the cross section orientation.  Specifying a list of normal vectors gives you complete control over the orientation of your
//   cross sections and can be useful if you want to position your model to be on the surface of some solid.
//   .
//   You can also apply scaling to the profile along the path.  You can give a list of scalar scale factors or a list of 2-vector scale. 
//   In the latter scale the x and y scales of the profile are scaled separately before the profile is placed onto the path.  For non-closed
//   paths you can also give a single scale value or a 2-vector, which is treated as the final scale.  The intermediate sections
//   are then scaled by linear interpolation either relative to length (if scale_by_length is true) or by point count otherwise.
//   .
//   The `caps` parameter controls what happens at the ends of the polyhedron.  If `closed=true` the shape links to itself and has no
//   ends, but when `closed` is false, the two ends are, by default capped with flat faces.  If you set `caps=false` then the ends
//   receive no faces and the resulting non-manifold polyhedron has exposed edges.  You can also set caps to a number, which adds a
//   rounded cap with the specified radius, or you can set caps to an {{offset_sweep()}} end treatment, and the specified sweep
//   is attached as a cap.  Note that you are **adding** a rounded cap, not rounding the specified shape as is common for many other
//   library modules.  The rounded cap is attached to the end face and may not blend neatly with the swept shape unless the sides of
//   the swept shape are perpendicular to the end cap.  
//   .
//   You can use set `transforms` to true to return a list of transformation matrices instead of the swept shape.  In this case, you can
//   often omit shape entirely.  The exception is when `closed=true` and you are using the "incremental" method.  In this case, `path_sweep`
//   uses the shape to correct for twist when the shape closes on itself, so you must include a valid shape.
//   .
//   By default path sweep objects are anchored to the named anchor "origin", which places the swept object right where you created it.
//   Generally you would not want to set an anchor for a swept object, but instead change the path if you want to move it to a different location, 
//   but you can also anchor using VNF anchoring.  Use either `atype="hull"` (the default) or `atype="intersect"` to create anchors based on the
//   the object's VNF data.  The center of the object is determined based on the `cp` argument and can be "centroid" (the default), "mean" to use the mean of the object,
//   or "box" to use the center of the bounding box.  For complicated objects you may find it difficult to get useful results from the anchoring
//   system, which is designed for an object whose center is inside the object.  When using an anchors, confirm that it is in the location you desire.  
//   .
//   You can apply a texture to the path sweep object using the usual texture parameters.
//   See [Texturing](skin.scad#section-texturing) for more details on how textures work.
//   This works by passing through to {{vnf_vertex_array()}}, which also has more details on
//   texturing.  Note that textures work only when the shape is a path; you cannot apply a texture to a region.  
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
//   caps = if closed is false, set caps to false to leave the ends open.  Other values are true to create a flat cap, a number a rounded cap, or an {{offset_sweep()}} end treatment to create the specified offset sweep.  Can be a single value or pair of values to control the caps independently at each end.  Default: true
//   style = vnf_vertex_array style.  Default: "min_edge"
//   profiles = if true then display all the cross section profiles instead of the solid shape.  Can help debug a sweep.  (module only) Default: false
//   width = the width of lines used for profile display.  (module only) Default: 1
//   transforms = set to true to return transforms instead of a VNF.  These transforms can be manipulated and passed to sweep().  (function only)  Default: false.
//   convexity = convexity parameter for polyhedron().  (module only)  Default: 10
//   texture = A texture name string, or a rectangular array of scalar height values (0.0 to 1.0), or a VNF tile that defines the texture to apply to vertical surfaces.  See {{texture()}} for what named textures are supported.
//   tex_size = An optional 2D target size (2-vector or scalar) for the texture at the first point of your shape and first path point.  Actual texture sizes are scaled somewhat to evenly fit the available surface. Default: `[5,5]`
//   tex_reps = If given instead of tex_size, a scalar or 2-vector giving the integer number of texture tile repetitions in the horizontal and vertical directions.
//   tex_inset = If numeric, lowers the texture into the surface by the specified proportion, e.g. 0.5 would lower it half way into the surface.  If `true`, insets by exactly its full depth.  Default: `false`
//   tex_rot = Rotate texture by specified angle, which must be a multiple of 90 degrees.  Default: 0
//   tex_depth = Specify texture depth; if negative, invert the texture.  Default: 1.  
//   tex_samples = Minimum number of "bend points" to have in VNF texture tiles.  Default: 8
//   tex_extra = number of extra lines of a hightfield texture to add at the end.  Can be a scalar or 2-vector to give x and y values.  Default: 1
//   tex_skip = number of lines of a heightfield texture to skip when starting.  Can be a scalar or two vector to give x and y values.  Default: 0
//   anchor = Translate so anchor point is at the origin. Default: "origin"
//   spin = Rotate this many degrees around Z axis after anchor. Default: 0
//   orient = Vector to rotate top toward after spin
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
// Example(Med,VPR=[34,0,8],NoScales): It may not be obvious, but the polyhedron in the previous example is invalid.  It results in CGAL errors when you combine it with other shapes.  To see this, set profiles to true and look at the left side.  The profiles cross each other and intersect.  Any time this happens, your polyhedron is invalid, even if it seems to be working at first.  Another observation from the profile display is that we have more profiles than needed over a lot of the shape, so if the model is slow, using fewer profiles in the flat portion of the curve might speed up the calculation.
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
// Example(NoScales): Sweep along a clockwise elliptical arc, using "natural" method, which lines up the X axis of the shape with the direction of curvature.  This means the X axis points inward, so a counterclockwise arc gives:
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
//   cube(0.5);    // Adding a small cube forces a CGAL computation, which reveals
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
// Example(NoScales): When the path starts at an angle of more than 45 deg to the xy plane the initial normal for "incremental" is BACK.  This produces the effect of the shape rising up out of the xy plane.  (Using UP for a vertical path is invalid, hence the need for a split in the defaults.)
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
// Example(Med,NoScales): It may look like the shape above is flat, but the profiles are slightly tilted due to the nonzero torsion of the curve.  If you want as flat as possible, specify it so with the "manual" method:
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
// Example(NoScales): The "natural" method introduces twists when the curvature changes direction.  A warning is displayed.
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
// Example(Med,NoScales): knot with twist.  Note if you twist it the other direction the center section untwists because of the natural twist there.  Also compare to the "incremental" method, which has less twist in the center.
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
// Example(Med,NoScales,VPR=[0,0.00,0],VPD=30,VPT=[5.26,1.53,0.20]): The left hand example uses the automatically computed derivatives.  The example on the right uses a user-supplied tangent to ensure that the ends are aligned with the coordinate system.  Even with a simple circular arc you may find that the ends are not aligned as expedted by the automatically computed approximate tangent vectors.
//   $fa=1; $fs=0.5;
//   theta_range=[180:2:450];
//   path = [for (theta = theta_range)
//              polar_to_xy(0.5*PHI^(2*theta/180), theta)];
//   tangents = [for (theta = theta_range)
//                  [-sin(theta), cos(theta), 0]];
//   circ = circle(1, $fn=32);
//   path_sweep(circ, path);
//   right(8)
//      path_sweep(circ, path, tangent=tangents);
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
// Example(Med,NoScales): Cutting a cylinder with a curved path. In this case, the incremental method produces just a slight twist but the natural method produces an extreme twist.  But manual specification produces no twist, as desired:
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
// Example(Med,NoScales,VPR=[78.1,0,43.2],VPT=[2.18042,-0.485127,1.90371],VPD=74.4017): The "start-centroid" and "end-centroid" anchors are located at the centroid the swept shape.
//   shape = back_half(right_half(star(n=5,id=5,od=10)),y=-1);
//   path = arc(angle=[0,180],d=30);
//   path_sweep(shape,path,method="natural"){
//     attach(["start-centroid","end-centroid"]) anchor_arrow(s=5);
//   }
// Example(Med,NoScales,VPR=[78.1,0,43.2],VPT=[2.18042,-0.485127,1.90371],VPD=74.4017): Note that the "start" anchors are backward compared to the direction of the sweep, so you have to attach the TOP to align the shape with its ends.  
//   shape = back_half(right_half(star(n=5,id=5,od=10)),y=-1)[0];
//   path = arc(angle=[0,180],d=30);
//   path_sweep(shape,path,method="natural",scale=[1,1.5])
//     recolor("red"){
//       attach("start",TOP) stroke([path3d(shape)],width=.5);
//       attach("end") stroke([path3d(yscale(1.5,shape))],width=.5);       
//     }
// Example(Med,NoScales): Applying a texture to a sweep
//   ellipse = xscale(2, p=circle($fn=64, r=3));
//   pentagon = subdivide_path(pentagon(r=1), 30);
//   path_sweep(pentagon, path3d(ellipse),
//              closed=true, twist=360*2/5,symmetry=5,
//              texture="bricks_vnf",tex_reps=[10,40],
//              tex_depth=.1);
// Example(NoScales): Applying rounded end caps to a sweep
//   $fs=1;$fa=1;
//   path_sweep(circle(r=5), arc(r=15, angle=[0,230]),caps=2.5);
// Example(NoScales): Using a small `$fn` creates a chamfer on the endcap
//   $fs=1;$fa=1;
//   path_sweep(circle(r=5), arc(r=15, angle=[0,230]),caps=1, $fn=4);
// Example(NoScales): One flat endcap and one rounding with a negative radius
//   $fs=1;$fa=1;
//   path_sweep(circle(r=5), arc(r=15, angle=[180,330]),caps=[true, -3]);


module path_sweep(shape, path, method="incremental", normal, closed, twist=0, twist_by_length=true, scale=1, scale_by_length=true,
                  symmetry=1, last_normal, tangent, uniform=true, relaxed=false, caps, style="min_edge", convexity=10,
                  anchor="origin",cp="centroid",spin=0, orient=UP, atype="hull",profiles=false,width=1,
                  texture, tex_reps, tex_size, tex_samples, tex_inset=false, tex_rot=0, 
                  tex_depth=1, tex_extra, tex_skip)
{
    dummy = assert(is_region(shape) || is_path(shape,2), "\nshape must be a 2D path or region.")
            assert(in_list(atype, _ANCHOR_TYPES), "\nAnchor type must be \"hull\" or \"intersect\".");
    trans_scale = path_sweep(shape, path, method, normal, closed, twist, twist_by_length, scale, scale_by_length,
                            symmetry, last_normal, tangent, uniform, relaxed, caps, style, transforms=true,_return_scales=true);
    transforms = trans_scale[0];
    scales = trans_scale[1];
    firstscale = is_num(scales[0]) ? 1/scales[0] : [1/scales[0].x, 1/scales[0].y];
    lastscale = is_num(last(scales)) ? 1/last(scales) : [1/last(scales).x, 1/last(scales).y];
    tex_normals = is_undef(texture) || relaxed ? undef
                : let(
                       shape_normals = -path3d(path_normals(clockwise_polygon(shape), closed=true))
                  )
                  [for(T=transforms) apply(_force_rot(T),shape_normals)];
    vnf = sweep(is_path(shape)?clockwise_polygon(shape):shape, transforms, closed=false, _closed_for_normals=closed, caps=caps,style=style,
                         texture=texture, tex_reps=tex_reps, tex_size=tex_size, tex_samples=tex_samples, normals=tex_normals,
                         tex_inset=tex_inset, tex_rot=tex_rot, tex_depth=tex_depth, tex_extra=tex_extra, tex_skip=tex_skip);
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
                    texture, tex_reps, tex_size, tex_samples, tex_inset=false, tex_rot=0, 
                    tex_depth=1, tex_extra, tex_skip,
                    anchor="origin",cp="centroid",spin=0, orient=UP, atype="hull",_return_scales=false) =
  is_1region(path) ? path_sweep(shape=shape,path=path[0], method=method, normal=normal, closed=default(closed,true), 
                                twist=twist, scale=scale, scale_by_length=scale_by_length, twist_by_length=twist_by_length, symmetry=symmetry, last_normal=last_normal,
                                tangent=tangent, uniform=uniform, relaxed=relaxed, caps=caps, style=style, transforms=transforms,
                                texture, tex_reps, tex_size, tex_samples, tex_inset=false, tex_rot=0, 
                                tex_depth=1, tex_extra, tex_skip,
                                anchor=anchor, cp=cp, spin=spin, orient=orient, atype=atype, _return_scales=_return_scales) :
  let(closed=default(closed,false))
  assert(in_list(atype, _ANCHOR_TYPES), "\nAnchor type must be \"hull\" or \"intersect\".")
  assert(!closed || twist % (360/symmetry)==0, str("\nFor a closed sweep, twist must be a multiple of 360/symmetry = ",360/symmetry,"."))
  assert(closed || symmetry==1, "\nsymmetry must be 1 when closed=false.")
  assert(is_integer(symmetry) && symmetry>0, "\nsymmetry must be a positive integer.")
  let(path = force_path(path))
  assert(is_path(path,[2,3]), "\ninput path is not a 2D or 3D path.")
  assert(!closed || !approx(path[0],last(path)), "\nClosed path includes start point at the end.")
  assert((is_region(shape) || is_path(shape,2)) || (transforms && !(closed && method=="incremental")),"\nshape must be a 2d path or region.")
  let(
    path = path3d(path),
    normalOK = is_undef(normal) || (method!="natural" && is_vector(normal,3))
                                || (method=="manual" && same_shape(normal,path)),
    scaleOK = scale==1 || ((is_num(scale) || is_vector(scale,2)) && !closed) || is_vector(scale,len(path)) || is_matrix(scale,len(path),2)
    
  )
  assert(normalOK,  method=="natural" ? "\nCannot specify normal with the \"natural\" method."
                  : method=="incremental" ? "\nNormal with \"incremental\" method must be a 3-vector."
                  : str("Incompatible normal given.  Must be a 3-vector or a list of ",len(path)," 3-vectors"))
  assert(is_undef(normal) || (is_vector(normal) && len(normal)==3) || (is_path(normal) && len(normal)==len(path) && len(normal[0])==3), "\nInvalid normal specified.")
  assert(is_undef(tangent) || (is_path(tangent) && len(tangent)==len(path) && len(tangent[0])==3), "\nInvalid tangent specified.")
  assert(scaleOK,str("\nIncompatible or invalid scale",closed?" for closed path":"",": must be ", closed?"":"a scalar, a 2-vector, ",
        "a vector of length ",len(path)," or a ",len(path),"x2 matrix of scales."))
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
              // then it will be the identity, but we might have accumulated some twist that appears as a rotation around the
              // X axis. Likewise, in the closed==false case the desired and actual transformations can differ only in the twist,
              // so we must calculate the twist angle so we can apply a correction, which we distribute uniformly over the whole path.
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
              // then it will be the identity, but we might have accumulated some twist that appears as a rotation around the
              // X axis.  Similarly, in the closed==false case the desired and actual transformations can differ only in the twist,
              // so we must calculate the twist angle so we can apply a correction, which we distribute uniformly over the whole path.
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
                   assert(approx(ynormal*znormal,0),str("\nSupplied normal is parallel to the path tangent at point ",i,"."))
                   translate(path[i%L])*rotation*zrot(-twist*tpathfrac[i])
              ]
      : method=="natural" ?   // map x axis of shape to the path normal, which points in direction of curvature
              let (pathnormal = path_normals(path, tangents, closed))
              assert(all_defined(pathnormal),"\nNatural normal vanishes on your curve. Select a different method.")
              let( testnormals = [for(i=[0:len(pathnormal)-1-(closed?1:2)]) pathnormal[i]*select(pathnormal,i+2)],
                   a=[for(i=idx(testnormals)) testnormals[i]<.5 ? echo(str("Big change at index ",i," pn=",pathnormal[i]," pn2= ",select(pathnormal,i+2))):0],
                   dummy = min(testnormals) < .5 ? echo("WARNING: ***** Abrupt change in normal direction.  Consider a different method in path_sweep() *****") :0
                 )
              [for(i=[0:L-(closed?0:1)]) let(
                       rotation = frame_map(x=pathnormal[i%L], z=tangents[i%L])
                   )
                   translate(path[i%L])*rotation*zrot(-twist*tpathfrac[i])
                 ] 
      : assert(false,"\nUnknown method or no method given."), // unknown method
    transform_list = v_mul(unscaled_transform_list, scale_list),
    ends_match = !closed ? true
                 : let( rshape = is_path(shape) ? [path3d(shape)]
                                                : [for(s=shape) path3d(s)]
                   )
                   are_regions_equal(apply(transform_list[0], rshape),
                                     apply(transform_list[L], rshape)),
    dummy = ends_match ? 0 : echo("WARNING: ***** The points do not match when closing the model in path_sweep() *****"),
    tex_normals = is_undef(texture) || relaxed ? undef
                : let(
                       shape_normals = -path3d(path_normals(clockwise_polygon(shape), closed=true))
                  )
                  [for(T=transform_list) apply(_force_rot(T),shape_normals)]

  )
  transforms && _return_scales
             ? [transform_list,scale]
: transforms ? transform_list
             : sweep(is_path(shape)?clockwise_polygon(shape):shape, transform_list, closed=false, caps=caps,style=style,
                       anchor=anchor,cp=cp,spin=spin,orient=orient,atype=atype,
                       texture=texture, tex_reps=tex_reps, tex_size=tex_size, tex_samples=tex_samples,
                       tex_inset=tex_inset, tex_rot=tex_rot, tex_depth=tex_depth, tex_extra=tex_extra, tex_skip=tex_skip,
                       _closed_for_normals=closed, normals=tex_normals 
               );


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
//   of the shape, then path_sweep2d() works as long as the offset of `path` exists at `delta=xmax`.  If the offset vanishes, as in the
//   case of a circle offset by more than its radius, then you get an error about a degenerate offset.
//   Global self-intersections still give rise to CGAL errors.  You can handle these by partitioning your model.  The y axis of the
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
//   orient = Vector to rotate top toward after spin
//   atype = Select "hull" or "intersect" anchor types.  Default: "hull"
//   cp = Centerpoint for determining "intersect" anchors or centering the shape.  Determines the base of the anchor vector.  Can be "centroid", "mean", "box" or a 3D point.  Default: "centroid"
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
   assert(is_path(shape,2), "\nshape must be a 2D path.")
   assert(is_path(path,2), "\npath must be a 2D path.")
   assert(capsOK, "\ncaps must be boolean or a list of two booleans.")
   assert(!closed || !caps, "\nCannot make closed shape with caps.")
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
// Topics: Extrusion, Sweep, Paths, Textures
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
//   As a function, returns the VNF for the polyhedron.  As a module, computes the polyhedron.
//   .
//   The `caps` parameter controls what happens at the ends of the polyhedron.  If `closed=true` the shape links to itself and has no
//   ends, but when `closed` is false, the two ends are, by default capped with flat faces.  If you set `caps=false` then the ends
//   receive no faces and the resulting non-manifold polyhedron has exposed edges.  You can also set caps to a number, which adds a
//   rounded cap with the specified radius, or you can set caps to an {{offset_sweep()}} end treatment, and the specified sweep
//   is attached as a cap.  Note that you are **adding** a rounded cap, not rounding the specified shape as is common for many other
//   library modules.  The rounded cap is attached to the end face and may not blend neatly with the swept shape unless the sides of
//   the swept shape are perpendicular to the end cap.  
//   .
//   This is a powerful, general framework for producing polyhedra.  It is important
//   to ensure that your resulting polyhedron does not include any self-intersections, or it will
//   be invalid and generate CGAL errors.  If you get such errors, most likely you have an
//   overlooked self-intersection.  The errors do not occur when your shape is alone
//   in your model, but errors arise if you add a second object to the model.  This may mislead you into
//   thinking the second object caused a problem.  Even adding a simple cube to the model reveals the problem.
//   .
//   You can apply a texture to the sweep object using the usual texture parameters.
//   See [Texturing](skin.scad#section-texturing) for more details on how textures work.
//   This works by passing through to {{vnf_vertex_array()}}, which also has more details on
//   texturing.  Note that textures work only when the shape is a path; you cannot apply a texture to a region.
//   The texture tiles are oriented on the path sweep so that the Y axis of the tile is aligned with the sweep direction.
//   .
//   
// Arguments:
//   shape = 2d path or region, describing the shape to be swept.
//   transforms = list of 4x4 matrices to apply
//   closed = set to true to form a closed (torus) model.  Default: false
//   caps = if closed is false, set caps to false to leave the ends open.  Other values are true to create a flat cap, a number a rounded cap, or an {{offset_sweep()}} end treatment to create the specified offset sweep.  Can be a single value or pair of values to control the caps independently at each end.  Default: true
//   style = vnf_vertex_array style.  Default: "min_edge"
//   ---
//   convexity = convexity setting for use with polyhedron. (module only) Default: 10
//   texture = A texture name string, or a rectangular array of scalar height values (0.0 to 1.0), or a VNF tile that defines the texture to apply to vertical surfaces.  See {{texture()}} for what named textures are supported.
//   tex_size = An optional 2D target size (2-vector or scalar) for the texture at the first point of your shape and first transformation.  Actual texture sizes are scaled somewhat to evenly fit the available surface. Default: `[5,5]`
//   tex_reps = If given instead of tex_size, a scalar or 2-vector giving the integer number of texture tile repetitions in the horizontal and vertical directions.
//   tex_inset = If numeric, lowers the texture into the surface by the specified proportion, e.g. 0.5 would lower it half way into the surface.  If `true`, insets by exactly its full depth.  Default: `false`
//   tex_rot = Rotate texture by specified angle, which must be a multiple of 90 degrees.  Default: 0
//   tex_depth = Specify texture depth; if negative, invert the texture.  Default: 1.  
//   tex_samples = Minimum number of "bend points" to have in VNF texture tiles.  Default: 8
//   tex_extra = number of extra lines of a hightfield texture to add at the end.  Can be a scalar or 2-vector to give x and y values.  Default: 1
//   tex_skip = number of lines of a heightfield texture to skip when starting.  Can be a scalar or two vector to give x and y values.  Default: 0
//   normals = if provided, used this array of normals for calculating the texture.  Dimension should be len(transforms) x len(shape).  
//   cp = Centerpoint for determining "intersect" anchors or centering the shape.  Determintes the base of the anchor vector.  Can be "centroid", "mean", "box" or a 3D point.  Default: "centroid"
//   atype = Select "hull" or "intersect" anchor types.  Default: "hull"
//   anchor = Translate so anchor point is at the origin. Default: "origin"
//   spin = Rotate this many degrees around Z axis after anchor. Default: 0
//   orient = Vector to rotate top toward after spin (module only)
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
//   sweep(reverse(circle(1, $fn=12)), path_transforms);
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
// Example: "sweet-drop" with a dots texture
//   function drop(t) = 100 * 0.5 * (1 - cos(180 * t)) * sin(180 * t) + 1;
//   function path(t) = [0, 0, 80 + 80 * cos(180 * t)];
//   function rotate(t) = 180 * pow((1 - t), 3);
//   step = 0.01;
//   path_transforms = [for (t=[0:step:1-step]) translate(path(t)) * zrot(rotate(t)) * scale([drop(t), drop(t), 1])];
//   sweep(reverse(circle(1, $fn=12)), path_transforms, texture="dots", tex_reps=[12,12],tex_depth=.1);


function sweep(shape, transforms, closed=false, caps, style="min_edge",
               anchor="origin", cp="centroid", spin=0, orient=UP, atype="hull",
               texture, tex_reps, tex_size, tex_samples, tex_inset=false, tex_rot=0, 
               tex_depth=1, tex_extra, tex_skip, _closed_for_normals=false, normals) =
    assert(is_consistent(transforms, ident(4)), "\nInput transforms must be a list of numeric 4×4 matrices in sweep.")
    assert(is_path(shape,2) || is_region(shape), "\nInput shape must be a 2d path or a region.")
    let(
        caps = is_list(caps) && select(caps,0,1)==["for","offset_sweep"] ? [caps,caps]
             : is_bool(caps) || is_num(caps) ? [caps,caps]
             : is_undef(caps) ? closed ? [false,false] : [true,true]
             : caps, 
        capsOK = is_list(caps) && len(caps)==2
                    &&
                      [] == [for(cap=caps)
                               if (!(is_bool(cap) || is_num(cap) || select(cap,0,1)==["for","offset_sweep"])) 1],
        flatcaps = [for(cap=caps) is_bool(cap) ? cap : false],
        fancycaps = [for(cap=caps) is_bool(cap) ? false
                                 : is_num(cap) ? os_circle(r=cap,steps=ceil(segs(cap)/4))
                                 : cap]
    )
    assert(len(transforms)>=2, "\ntransformation must be length 2 or more.")
    assert(capsOK, "\ncaps must be boolean, number, an offset_sweep specification, or a list of two of those.")
    assert(!closed || caps==[false,false], "\nCannot make closed shape with caps.")
    is_region(shape)?
        assert(fancycaps==[false,false], "\nRounded caps are not supported for regions.")
        assert(is_undef(texture), "\nTextures are not supported for regions, only paths.")
        let(
            regions = region_parts(shape),
            rtrans = reverse(transforms),
            vnfs = [
                for (rgn=regions) each [
                    for (path=rgn)
                        sweep(path, transforms, closed=closed, caps=false, style=style),
                    if (flatcaps[0]) vnf_from_region(rgn, transform=transforms[0], reverse=true),
                    if (flatcaps[1]) vnf_from_region(rgn, transform=last(transforms)),
                ],
            ],
            vnf = vnf_join(vnfs)
        )
        vnf
  :
    assert(len(shape)>=3, "\nshape must be a path of at least 3 non-collinear points.")
    let(
         points = [for(i=[0:len(transforms)-(closed?0:1)]) apply(transforms[i%len(transforms)],path3d(shape))],
         normals = is_def(normals) ? normals
                 : (!(is_def(texture) && (closed || _closed_for_normals))) ? undef
                 : let(
                        n = surface_normals(select(points,0,-2), col_wrap=true, row_wrap=true)
                   )
                   [each n, n[0]],
         vva_result = vnf_vertex_array(points, normals=normals, 
                               cap1=flatcaps[0],cap2=flatcaps[1],col_wrap=true,style=style, return_edges=fancycaps!=[false,false],
                               texture=texture, tex_reps=tex_reps, tex_size=tex_size, tex_samples=tex_samples,
                               tex_inset=tex_inset, tex_rot=tex_rot, tex_depth=tex_depth, tex_extra=tex_extra, tex_skip=tex_skip),
         vnf = fancycaps==[false,false] ? vva_result
             : vnf_join(
                   [ vva_result[0], 
                     for(ind=[0,1]) 
                          if (fancycaps[ind]) let(
                              polygon = vva_result[1][ind+2],
                              plane = plane_from_polygon(ind==0? reverse(polygon) : polygon)
                          )
                          apply(lift_plane(plane),offset_sweep(project_plane(plane, polygon), top=fancycaps[ind], caps=[false,true]))
                    ])
    ) vnf;


module sweep(shape, transforms, closed=false, caps, style="min_edge", convexity=10,
             anchor="origin",cp="centroid",spin=0, orient=UP, atype="hull",
             texture, tex_reps, tex_size, tex_samples, tex_inset=false, tex_rot=0, 
             tex_depth=1, tex_extra, tex_skip, normals)
{
    $sweep_transforms=transforms;
    $sweep_shape=shape;
    $sweep_closed=closed;
    vnf = sweep(shape, transforms, closed, caps, style,
                texture=texture, tex_reps=tex_reps, tex_size=tex_size, tex_samples=tex_samples,
                tex_inset=tex_inset, tex_rot=tex_rot, tex_depth=tex_depth, tex_extra=tex_extra, tex_skip=tex_skip, normals=normals);
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
//   Alternatively, you can use parent anchor mode, giving only the parent anchor and the child appears at its
//   child-specified (default) anchor point.  The spin parameter spins the child around the attachment anchor axis.  
//   .
//   For a path_sweep() with no scaling, if you give a location or index that is exactly at one of the sections, the normal is in the plane
//   of the section.  In the general case if you give a location in between sections the normal is normal to the facet.  If you
//   give a location at a section in the general case the normal is the average of the normals of the two adjacent facets.  
//   For twisted or other complicated sweeps the normals may not be accurate.  If you need accurate normals for such shapes, you must
//   use the anchors for the VNF swept shape directly&mdash;it is a tradeoff between easy specification of the anchor location on the
//   swept object, which may be difficult with direct anchors, and accuracy of the normal.
//   .
//   For closed sweeps the index wraps around and can be positive or negative.  For sweeps that are not closed the index must
//   be positive and no longer than the length of the path.  In some cases for closed path_sweeps the shape can be a Möbius strip
//   and it may take more than one cycle to return to the starting point.  The extra twist is properly handled in this case.
//   If you construct a Möbius strip using the generic {{sweep()}} then information about the amount of twist is not available
//   to `sweep_attach()` so it is not handled automatically.  
//   .
//   The anchor you give acts as a 2D anchor to the path or region used by the sweep, in the XY plane as that shape appears
//   before it is transformed to form the swept object.  As with {{region()}}, you can control the anchor using `cp` and `atype`, 
//   and you can check the anchors by using the same anchors with {{region()}} in a two dimensional test case.
//   .
//   Note that {{path_sweep2d()}} does not support `sweep_attach()` because it doesn't compute the transform list, which is
//   the input used to calculate the attachment transform.  
// Arguments:
//   parent = 2d anchor to the shape used in the path_sweep parent
//   child = optional 3d anchor for anchoring the child to the parent
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
   dummy =  assert(!is_undef($sweep_transforms), "\nsweep_attach() must be used as a child of sweep() or path_sweep().")
            assert(in_list(atype, _ANCHOR_TYPES), "\nAnchor type must be \"hull\" or \"intersect\".")
            assert(num_defined([idx,frac,pathlen])==1, "\nMust define exactly one of idx, frac, and pathlen.")
            assert(is_undef(idx) || is_finite(idx), "\nidx must be a number.")
            assert(is_undef(frac) || is_finite(frac), "\nfrac must be a number.");
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
   nextind = is_int(i) ? i>=length-1 && !$sweep_closed ? assert(i==length-1,str("\n",parmset," is too large for the path.")) undef
                       : i+1
          : $sweep_closed ?  posmod(ceil(i),length)
          : assert(i<length-1,str("\n",parmset," is too large for the path.")) ceil(i);
   prevind = is_int(i) ? i<=0 && !$sweep_closed ? assert(i==0,str("\n",parmset," must be nonnegative.")) undef
                       : i-1 
           : $sweep_closed ? floor(i)
           : assert(i>0,str("\n",parmset, " must be nonnegative.")) floor(i);
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
// is normal to the facet.  Note that frac is needed because
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
//   curves, which avoids sampling artifacts but may produce a huge output.  After subdivision,
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
  assert(is_def(numpoints), "\nParameter numpoints must be \"max\", \"lcm\", or a positive number.")
  assert(numpoints>=maxsize, "\nNumber of points requested is smaller than largest profile.")
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
  assert(listok, "\nInput slices to slice_profiles is a list with the wrong length.")
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
//   You can add turns with the turns parameter, so giving turns=1 add 360s degrees to the
//   rotation so it completes one full turn plus the additional rotation given by the transform.
//   You can give long as a scalar or as a vector.  Finally if closed is true then the
//   resampling connects back to the beginning.
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
    assert(is_int(smoothlen) && smoothlen>0 && smoothlen%2==1, "\nsmoothlen must be a positive odd integer.")
    assert(method=="length" || method=="count")
    let(tcount = len(rotlist) + (closed?0:-1))
    assert(method=="count" || is_int(n), "\nn must be an integer when method is \"length\".")
    assert(is_int(n) || is_vector(n,tcount), str("\nn must be scalar or vector with length ",tcount,"."))
    let(
          count = method=="length" ? (closed ? n+1 : n)
                                   : (is_vector(n) ? sum(n) : tcount*n)+1  //(closed?0:1)
    )
    assert(is_bool(long) || len(long)==tcount,str("\nInput long must be a scalar or have length ",tcount,"."))
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
           "\nRotation list includes a repeated entry or a rotation around the origin, not allowed when method=\"length\".")
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
// way where entries fill in based on the three entries above and to the left.  We duplicate
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
// two inputs.  This has quadratic run time.  As above, output is pair of polygons with
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
///   edge and is tangent to the curve.  There is always more than one such point.  To choose one, the algorithm centers the polygon and curve on their centroids
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
    assert(len(newsmall)==len(newbig), "\nTangent alignment failed, probably because of insufficient points or a concave curve.")
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
//   using the `split`, which is a list where each entry corresponds to a polygon: split[i] is a value or list specifying which vertices in polygon i to split.
//   Give the empty list if you don't want a split for a particular polygon.  If you list a vertex once then it is split and mapped to
//   two vertices in the next polygon.  If you list it N times then N copies are created to map to N+1 vertices in the next polygon.
//   You must ensure that each mapping produces the correct number of vertices to exactly map onto every vertex of the next polygon.
//   If you split only vertex i of a polygon, that means it maps to vertices i and i+1 of the next polygon.  Vertex 0 always
//   maps to vertex 0 and the last vertices always map to each other, so if you want something different than that you need to reindex
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
// Example(3D): The polygons cannot shrink, so if you want to have decreasing polygons you'll need to concatenate multiple results.  It is perfectly OK to duplicate a profile as shown here, where the pentagon is duplicated:
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
    assert(len(split)==len(polygons)-1,str(split,"\nSplit list length mismatch: it has length ", len(split)," but must have length ",len(polygons)-1,"."))
    assert(polylen<=len(polygons[curpoly+1]),str("\nPolygon ",curpoly," has more vertices than the next one."))
    assert(len(cursplit)+polylen == len(polygons[curpoly+1]),
           str("\nPolygon ", curpoly, " has ", polylen, " vertices.  Next polygon has ", len(polygons[curpoly+1]),
                  " vertices.  Split list has length ", len(cursplit), " but must have length ", len(polygons[curpoly+1])-polylen,"."))
    assert(len(cursplit) == 0 || max(cursplit)<polylen && min(curpoly)>=0,
           str("\nSplit ",cursplit," at polygon ",curpoly," has invalid vertices. Must be in [0:",polylen-1,"]."))
    len(cursplit)==0 ? associate_vertices(polygons,split,curpoly+1) :
    let(
      splitindex = sort(concat(count(polylen), cursplit)),
      newpoly = [for(i=[0:len(polygons)-1]) i<=curpoly ? select(polygons[i],splitindex) : polygons[i]]
    )
   associate_vertices(newpoly, split, curpoly+1);

// Section: Introduction to Texturing
//   Some operations are able to add texture to the objects they create.  A texture can be any regularly repeated variation in the height of the surface.
//   To define a texture you need to specify how the height should vary over a rectangular block that is repeated to tile the object.  Because textures
//   are based on rectangular tiling, this means adding textures to curved shapes may result in distortion of the basic texture unit.  For example, if you
//   texture a cone, the scale of the texture is larger at the wide end of the cone and smaller at the narrower end of the cone.
//   .
//   You can specify a texture using two methods: a height field or a VNF.  For each method you also must specify the scale of the texture, which
//   gives the size of the rectangular unit in your object that corresponds to one texture tile.  This scale does not preserve
//   aspect ratio: you can stretch the texture as desired.
// Subsection: Height Field Texture Maps
//   The simplest way to specify a texture map is to give a 2d array of
//   height values that specify the height of the texture on a grid.
//   Values in the height field should generally range from 0 to 1.  A zero height
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
//   is designed to span the range from 0 to 1.  The `tex_depth` parameter can adjust
//   this dimension of a texture without changing anything else, setting `tex_depth` negative
//   inverts a texture, and `tex_inset` lowers a texture into the textured object.
//   Textures that extend beyond the interval [0,1] are accepted, but the behavior of the
//   `tex_depth` and `tex_inset` parameters may be less intuitive.  
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
//   their points don't fall on any grid.  Trying to create such shapes is difficult and requires many points to approximate the
//   true point positions for the desired shape.  This makes the texture slow to compute.  
//   Another serious limitation is more subtle.  In the 2D examples above, it is obvious how to connect the
//   dots together.  But in 3D example we need to triangulate the points on a grid, and this triangulation is not unique.
//   The `style` argument lets you specify how the points are triangulated using the styles supported by {{vnf_vertex_array()}}.
//   In the example below we have expanded the 2D example into 3D:
//   
//   ```openscad
//       [[0,0,0,0],
//        [0,1,1,0],
//        [0,1,1,0],
//        [0,0,0,0]]
//   ```
//
// Continues:
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
//   a simple array of height values, and they are significantly slower to compute for a tile with the same number of points.  However, for
//   textures that don't neatly lie on a grid, a VNF tile is more efficient than a finely sampled height field.  With VNF textures you can create
//   textures that have disconnected components, or concavities that cannot be expressed with a single valued height map.  However, you can also
//   create invalid textures that fail to close at the ends, so care is required to ensure that your resulting shape is valid.  
//   .
//   A VNF texture is defined by providing a VNF whose projection onto the XY plane is contained in the unit square [0,1] x [0,1] so
//   that the VNF can be tiled.  The VNF is tiled without a gap, matching the edges, so the vertices along corresponding edges must match to make a
//   consistent triangulation possible.  The VNF cannot have any X or Y values outside the interval [0,1].  If you want a valid polyhedron
//   that OpenSCAD can render then you need to take care with edges of the tiles that correspond to endcap faces in the textured object.
//   So for example, in a linear sweep, the top and bottom edges of tiles end abruptly to form the end cap of the object.  You can make a valid object
//   in two ways.  One way is to create a tile with a single, complete edge along Y=0, and of course a corresponding edges along Y=1.  The second way
//   to make a valid object is to have no points at all on the Y=0 line, and of course none on Y=1.  In this case, the resulting texture produces
//   a collection of disconnected objects. The Z coordinates of your tile can be anything, but as with height fields, for the dimensional settings on textures
//   to work intuitively, you should construct your tile so that Z ranges from 0 to 1.  You can then use `tex_depth` to control the depth of the tile in use.  
// Figure(3D): This is the "hexgrid" VNF tile, which creates a hexagonal grid texture, something that doesn't work well with a height field because the edges of the hexagon don't align with the grid.  Note how the tile ranges between 0 and 1 in both X, Y and Z.  In fact, to get a proper aspect ratio in your final texture you need to use the `tex_size` parameter to introduct a sqrt(3) scale factor.  
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
//   points given in the VNF follows the surface, resulting in a blocky look and geometrical artifacts.  
// Figure(3D,Med,NoAxes): On the left the `tex_samples` value is small and the texture is blocky.  On the right, the default value of 8 allows a reasonable fit to the cylinder. 
//   xdistribute(spacing=5){
//      cyl(d=10/PI, h=5, chamfer=0,
//         texture=texture("bricks_vnf"), tex_samples=1, tex_reps=[6,3], tex_depth=.2);
//      cyl(d=10/PI, h=5, chamfer=0,
//         texture=texture("bricks_vnf"), tex_samples=8, tex_reps=[6,3], tex_depth=.2);
//   }
// Continues:
//   When the VNF is sliced,
//   extra points can be introduced in the interior of faces leading to unexpected irregularities in the textures, which appear
//   as extra triangles.  These artifacts can be minimized by making the VNF texture's faces as large as possible rather than using
//   a triangulated VNF, but depending on the specific VNF texture, it may be impossible to entirely eliminate them.
// Figure(3D,Med,NoAxes,VPR=[140.9,0,345.7],VPT=[9.48289,-0.88709,5.7837],VPD=39.5401): The left shows a normal bricks_vnf texture.  The right shows a texture that was first passed through {{vnf_triangulate()}}.  Note the extra triangle artifacts visible at the ends on the brick faces.
//   tex = texture("bricks_vnf");
//   cyl(d=10,h=15,texture=tex, tex_reps=[4,2],tex_samples=5,rounding=2);
//   up(7)fwd(-3)right(15)cyl(d=10,h=15,texture=vnf_triangulate(tex), tex_reps=[4,2],tex_samples=5,rounding=2);
//
// Subsection: Textures from Graphic Images
//   .
//   In additional to creating textured surfaces, the texturing feature of BOSL2 can be used to place relief images onto objects
//   using a single repetition of a large heightfield texture array. In order to do this, you'll need a way to import your image into OpenSCAD.
//   .
//   The BOSL2 scripts folder contains three scripts for creating heightfield texture arrays from graphic images.
//   Right-click the links to the python scripts to download them to your local system, then run them from the command line.
//   The html link will open in your browser.
//   .
//      - [**img2scad.html**](https://htmlpreview.github.io/?https://github.com/BelfrySCAD/BOSL2/blob/master/scripts/img2scad.html)
//   can create a texture array from any image your browser can render.  
//   .
//      - [**img2scad.py**](https://raw.githubusercontent.com/BelfrySCAD/BOSL2/master/scripts/img2scad.py)
//   is a python script that creates a texture array from most common raster image formats, including gif, png, jpeg.
//   .
//      - [**geotiff2scad.py**](https://raw.githubusercontent.com/BelfrySCAD/BOSL2/master/scripts/geotiff2scad.py)
//   is a python script creates a texture array from geotiff depth maps.
//   .
//   Each of these scripts places a named array in an .scad file with names specified at run time.   Use include<> to add the array to your model. 
//   .
//   Both **img2scad.py** and **img2scad.html** create texture arrays from graphics, but the html page has a few additional capabilities
//   and it provides a graphical user interface.
//   .
//   On the right is a {{textured_tile()}} with the texture array created by **img2scad.html** from the .png file on the left:
//   .
//   ![Textured Tile](https://raw.githubusercontent.com/BelfrySCAD/BOSL2/master/images/WilburTex01.png)
//   .
//   The image luminance is directly translated into texture depth in the example above.  Better results can be obtained by passing 
//   the original image through an AI image processor to produce a depth map from the image before creating the texture array.
//   .
//   ![Texture Tile](https://raw.githubusercontent.com/BelfrySCAD/BOSL2/master/images/WilburTex02.png)
//   .
//   AI image processing tool and workflows are still evolving rapidly. See the [discussion](https://github.com/BelfrySCAD/BOSL2/discussions/1731) on depth map workflows for current best practices.
//   .
//   Sources of whole planet GeoTIFF Data include:
//      * [USGS Astrogeology Science Center](https://astrogeology.usgs.gov/search)
//      * [NASA PDS (Planetary Data System)](https://pds.nasa.gov)
//      * [OpenPlanetaryMap / OpenPlanetary](https://github.com/OpenPlanetary/opm)
//   .
//   GeoTIFF data for smaller areas comes from the Space Shuttle Radar Topography Mission. Data covering about 80% of the Earth's surface
//   is available from [Earthdata](https://www.earthdata.nasa.gov/data/instruments/srtm/data-access-tools) 
//   .
//   A globe created using the **geotiff2scad.py** script to generate the texture array:
//   .
//   ![Geotiff Example](https://raw.githubusercontent.com/BelfrySCAD/BOSL2/master/images/globe_animation.png)
//   .
// Section: Texturing 
// Function: texture()
// Topics: Textures, Knurling
// Synopsis: Produce a standard texture. 
// Topics: Extrusion, Textures
// See Also: linear_sweep(), rotate_sweep(), cyl(), vnf_vertex_array(), sweep(), path_sweep(), textured_tile()
// Usage:
//   tx = texture(tex, [n=], [inset=], [gap=], [roughness=]);
// Description:
//   Given a texture name, returns a texture.  Textures can come in two varieties:
//   - Heightfield textures, which are 2D arrays of scalars.  These are usually faster to render, but can be less precise and prone to triangulation errors.  The table below gives the recommended style for the best triangulation.  If results are still incorrect, switch to the similar VNF tile by adding the "_vnf" suffix.
//   - VNF Tile textures, which are VNFs that cover the unit square [0,0] x [1,1].  These tend to be slower to render, but allow greater flexibility and precision for shapes that don't align with a grid.
//   .
//   In the descriptions below, imagine the textures positioned on the XY plane, so "horizontal" refers to the "sideways" dimensions of the texture and
//   "up" and "down" refer to the depth dimension, perpendicular to the surface being textured.  If a texture is placed on a cylinder, the "depth" becomes the radial direction and "horizontal"
//   refers to the vertical and tangential directions on the cylindrical surface.  All horizontal dimensions for VNF textures are relative to the unit square
//   on which the textures are defined, so a value of 0.25 for a gap or border refers to 1/4 of the texture's full length and/or width.  All supported textures appear below in the examples.  
// Arguments:
//   tex = The name of the texture to get.
//   ---
//   n = The number of samples to use for defining a heightfield texture.  Depending on the texture, the result is either n×n or 1×n.  Not allowed for VNF textures.  See the `tex_samples` argument to {{cyl()}}, {{linear_sweep()}} and {{rotate_sweep()}} for controlling the sampling of VNF textures.
//   border = The size of a border region on some VNF tile textures.  Generally between 0 and 0.5.
//   gap = The gap between logically distinct parts of some VNF tiles.  (ie: gap between bricks, gap between truncated ribs, etc.)
//   roughness = The amount of roughness used on the surface of some heightfield textures.  Generally between 0 and 0.5.
// Example(3D): **"bricks"** (Heightfield) = A brick-wall pattern.  Giving `n=` sets the number of heightfield samples to `n` by `n`.  Default: 24.  Giving `roughness=` creates a rough surface texture to the top brick faces by randomizing the brick height to a band of the specified height (relative to the tile range of 0 to 1), so with the default of 0.1 it means the top level varies randomly in [0.9,1].  Default: 0.1.  Use `style="convex"`.
//   tex = texture("bricks");
//   linear_sweep(
//       rect(30), texture=tex, h=30,
//       tex_depth=1/2, tex_size=[10,10]
//   );
// Example(3D): **"bricks_vnf"** (VNF) = VNF version of "bricks".  Giving `gap=` sets the "mortar" gap between adjacent bricks, default 0.05.  Giving `border=` specifies that the top face of the brick is smaller than the bottom of the brick by `border` on each of the four sides.  If `gap` is zero then a `border` value close to 0.5 causes the bricks to come to a sharp pointed edge, with just a tiny flat top surface.  Note that `gap+border` must be strictly smaller than 0.5.   Default is `border=0.05`.  
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
// Example(3D): **"cones"** (VNF) = Raised conical spikes.  Specify `$fn` to set the number of segments on the cone (this is rounded to a multiple of 4).  The default is `$fn=16`.  Note that `$fa` and `$fs` are ignored, since the scale of the texture is unknown at the time of definition.  Giving `border=` specifies the horizontal border width between the edge of the tile and the base of the cone.  The `border` value must be nonnegative and smaller than 0.5.  Default: 0.
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
// Example(3D): **"dots"** (VNF) = Raised round bumps.  Specify `$fn` to set the number of segments on the dots (this is rounded to a multiple of 4).  The default is `$fn=16`.  Note that `$fa` and `$fs` are ignored, since the scale of the texture is unknown at the time of definition.  Giving `border=` specifies the horizontal width of the flat border region between the tile edge and the edge of the dots.  Must be nonnegative and strictly less than 0.5.  Default: 0.05.
//   tex = texture("dots", $fn=16);
//   linear_sweep(
//       rect(30), texture=tex, h=30,
//       tex_depth=2, tex_size=[10,10]
//   );
// Example(3D): "dots" (VNF) = You can use the "dots" texture to create dimples (which used to exist as a separate texture) by specifying `tex_inset` and a negative `tex_depth`, which inverts the texture.
//   tex = texture("dots", $fn=16);
//   linear_sweep(
//       rect(30), texture=tex, h=30, tex_depth=-2,
//       tex_inset=1, tex_size=[10,10]
//   );
// Example(3D): **"hex_grid"** (VNF) = A hexagonal grid defined by V-grove borders.  Giving `border=` specifies that the top face of the hexagon is smaller than the bottom by `border` on the left and right sides.  This means the V-groove top width for grooves running parallel to the Y axis are double the border value.  If the texture is scaled in the Y direction by sqrt(3) then the groove is uniform on all six sides of the hexagon.  Border must be strictly between 0 and 0.5, default: 0.1.
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
// Example(3D): **"rough"** (Heightfield) = A pseudo-randomized rough texture.  Giving `n=` sets the number of heightfield samples to `n` by `n`.  Default: 32.  The texture is filled with random values ranging from 0 to 1.  To control the height of the random texture use the `tex_depth` parameter.  
//   tex = texture("rough");
//   linear_sweep(
//       rect(30), texture=tex, h=30, tex_depth=0.2,
//       tex_size=[10,10], style="min_edge"
//   );
// Example(3D): **"tri_grid"** (VNF) = A triangular grid defined by V-groove borders  Giving `border=` specifies that the top face of the triangular surface is smaller than the bottom by `border` along the horizontal edges (parallel to the X axis).  This means the V-groove top width of the grooves parallel to the X axis are double the border value.  (The other grooves are wider.) If the tile is scaled in the Y direction by sqrt(3) then the groove is uniform on the three sides of the triangle.  The border must be strictly between 0 and 1/6, default: 0.05.
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
// Example(3D): **"trunc_diamonds"** (VNF) = Truncated diamonds, four-sided pyramids with the base corners aligned with the axes and the top cut off.  Or you can interpret it as V-groove lines at 45º angles.  Giving `border=` specifies that the width and height of the top surface of the diamond are smaller by `border` at the left, right, top, and bottom.  The border is measured in the **horizontal** direction.  This means the V-groove width is sqrt(2) times the border value.  The border must be strictly between 0 and sqrt(2)/4, which is about 0.35.  Default: 0.1.
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
// Example(3D): **"trunc_pyramids_vnf"** (VNF) = Truncated pyramids, four sided pyramids with the base edges aligned to the axes and the top cut off.  You can also regard this as a grid of V-grooves.  Giving `border=` specifies that the top face is smaller than the top by `border` on all four sides.  This means the V-groove top width is double the border value.  The border must be strictly between 0 and 0.5.  Default: 0.1.
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



function texture(tex, n, border, gap, roughness, inset) =
    assert(num_defined([border,inset])<2, "In texture() the 'inset' parameter has been replaced by 'border'.  You cannot give both parameters.")
    let(
        border = is_def(inset)?echo("In texture() the argument 'inset' has been deprecated and will be removed.  Use 'border' instead")
                               inset
                              :border
    )
    assert(is_undef(n) || all_positive([n]), "\nn must be a positive value if given.")
    assert(is_undef(border) || is_finite(border), "\nborder must be a number if given.")
    assert(is_undef(gap) || is_finite(gap), "\ngap must be a number if given.")
    assert(is_undef(roughness) || all_nonnegative([roughness]), "\nroughness must be a nonnegative value if given.")  
    tex=="ribs"?
        assert(num_defined([gap, border, roughness])==0, "\nribs texture does not accept gap, border, or roughness.")

        let(
            n = quantup(default(n,2),2)
        ) [[
            each lerpn(1,0,n/2,endpoint=false),
            each lerpn(0,1,n/2,endpoint=false),
        ]] :
    tex=="trunc_ribs"?
        assert(num_defined([gap, border, roughness])==0, "\ntrunc_ribs texture does not accept gap, border, or roughness.")
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
            gap = default(gap,1/4)
        )
        assert(all_nonnegative([border,gap]), "\ntrunc_ribs_vnf texture requires gap>=0 and border>=0.")
        assert(gap+border <= 1, "\ntrunc_ribs_vnf texture requires that 2*border+gap <= 1.")
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
        assert(num_defined([gap, border, roughness])==0, "\nwave_ribs texture does not accept gap, border, or roughness.")
        let(
            n = max(6,default(n,8))
        ) [[
            for(a=[0:360/n:360-EPSILON])
            (cos(a)+1)/2
        ]] :
    tex=="diamonds"?
        assert(num_defined([gap, border, roughness])==0, "\ndiamonds texture does not accept gap, border, or roughness.")
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
        assert(num_defined([gap, border, roughness])==0, "\ndiamonds_vnf texture does not accept gap, border, or roughness.")
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
        assert(num_defined([gap, border, roughness])==0, "\npyramids texture does not accept gap, border, or roughness.")
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
        assert(num_defined([gap, border, roughness])==0, "\npyramids_vnf texture does not accept gap, border, or roughness.")
        [
            [ [0,1,0], [1,1,0], [1/2,1/2,1], [0,0,0], [1,0,0] ],
            [ [2,0,1], [2,1,4], [2,4,3], [2,3,0] ]
        ] :
    tex=="trunc_pyramids"?
        assert(num_defined([gap, border, roughness])==0, "\ntrunc_pyramids texture does not accept gap, border, or roughness.")
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
        assert(num_defined([gap, roughness])==0, "\ntrunc_pyramids_vnf texture does not accept gap or roughness.")
        let(
            border = default(border,0.1)
        )
        assert(border>0 && border<.5, "\ntrunc_pyramids_vnf texture requires border in (0,0.5).")
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
        assert(num_defined([gap, border, roughness])==0, "\nhills texture does not accept gap, border, or roughness.")
        let(
            n = default(n,12)
        ) [
            for (a=[0:360/n:359.999]) [
                for (b=[0:360/n:359.999])
                (cos(a)*cos(b)+1)/2
            ]
        ] :
    tex=="bricks"?
        assert(num_defined([gap,border])==0, "\nbricks texture does not accept gap or border.")
        let(
            n = quantup(default(n,24),2),
            rough = default(roughness,0.1)
        ) [
            for (y = [0:1:n-1])
               let(rand = rands(1-rough, 1, n, seed=12345+y*678))
               [
                for (x = [0:1:n-1])
                   (y%(n/2) <= max(1,n/16)) ? 0 :
                      let( even = floor(y/(n/2))%2 ? n/2 : 0 )
                        (x+even) % n <= max(1,n/16)? 0 : rand[x]
            ]
        ] :
    tex=="bricks_vnf"?
        assert(is_undef(n), str(tex,__vnf_no_n_mesg))
        assert(num_defined([roughness])==0, "\nbricks_vnf texture does not accept roughness.")
        let(
            border = default(border,0.05),
            gap = default(gap,0.05)
        )
        assert(border>=0,"\nbricks_vnf texture requires nonnegative border.")
        assert(gap>0, "\nbricks_vnf requires gap greater than 0.")
        assert(gap+border<0.5, "\nbricks_vnf requires gap+border < 0.5.")
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
        assert(num_defined([gap, roughness])==0, "\ncheckers texture does not accept gap or roughness")
        let(
            border = default(border,0.05)
        )
        assert(border>0 && border<.5, "\ncheckers texture requires border in (0,0.5).")
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
        assert(is_undef(n),str("\nTo set number of segments on cones use $fn. ", tex,__vnf_no_n_mesg))
        assert(num_defined([gap,roughness])==0, "\ncones texture does not accept gap or roughness.")  
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
        assert(num_defined([gap, border, roughness])==0, "\ncubes texture does not accept gap, border, or roughness.")  
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
        assert(num_defined([gap, roughness])==0, "\ntrunc_diamonds texture does not accept gap or roughness.")
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
    tex=="dimples" ? assert(false, "\nThe dimples texture has been removed; use \"dots\" with 'tex_inset=1' and negative 'tex_depth' instead.") 0 : 
    tex=="dots" ?
        assert(is_undef(n),str("\nTo set number of segments on ",tex," use $fn. ", tex,__vnf_no_n_mesg))
        assert(num_defined([gap,roughness])==0, str("\n",tex," texture does not accept gap or roughness."))
        let(
            border = default(border,0.05),
            n = $fn > 0 ? quantup($fn,4) : _tex_fn_default()
        )
        assert(border>=0 && border < 0.5)
        let(
            rows=ceil(n/4),
            r=adj_ang_to_hyp(1/2-border,45),
            dots = true,
            cp = [1/2, 1/2, -r*sin(45)],
            sc = 1 / (r - abs(cp.z)),
            uverts = [
                for (p=[0:1:rows-1], t=[0:360/n:359.999])
                    cp + spherical_to_xyz(r, -t, 45-45*p/rows),
                cp + r * UP, 
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
        assert(num_defined([gap, roughness])==0, str("\n",tex," texture does not accept gap or roughness."))  
        let(
            border = default(border,0.05)*sqrt(3)
        )
        assert(border>0 && border<sqrt(3)/6, "\ntri_grid texture requires border in (0,1/6).")
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
        assert(num_defined([gap, roughness])==0, str("\n",tex," texture does not accept gap or roughness."))
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
        assert(num_defined([gap,border])==0, str("\n",tex," texture does not accept gap or border."))
        assert(num_defined([roughness])==0, str("\n",tex," texture no longer accepts 'roughness'. Use tex_depth to control roughness (0.2 was the old default)."))  
        let(
            n = default(n,32)
        ) [
            for (y = [0:1:n-1])
            rands(0, 1, n, seed=123456+29*y)
        ] :
    assert(false, str("\nUnrecognized texture name: ", tex));


/// Function&Module: _textured_linear_sweep()
/// Usage: As Function
///   vnf = _textured_linear_sweep(region, texture, tex_size, h, ...);
///   vnf = _textured_linear_sweep(region, texture, counts=, h=, ...);
/// Usage: As Module
///   _textured_linear_sweep(region, texture, tex_size, h, ...) [ATTACHMENTS];
///   _textured_linear_sweep(region, texture, counts=, h=, ...) [ATTACHMENTS];
/// Topics: Sweep, Extrusion, Textures, Knurling
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
///   tex_size = An optional 2D target size for the textures.  Actual texture sizes are scaled somewhat to evenly fit the available surface. Default: `[5,5]`
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
///   orient = Vector to rotate top toward, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
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
        assert(all_nonnegative(concat(min_xy,[1,1]-max_xy)), "\nVNF tile X and Y components must be between 0 and 1.")
        let(
            verts = texture[0],
            uedges = _get_vnf_tile_edges(texture),
            edge_verts = [for (i = unique(flatten(uedges))) verts[i] ],
            hverts = [for(v = edge_verts) if(v.x==0 || v.x==1) v],
            vverts = [for(v = edge_verts) if(v.y==0 || v.y==1) v],
            allgoodx = all(hverts, function(v) any(hverts, function(w) approx(w,[1-v.x, v.y, v.z]))),
            allgoody = all(vverts, function(v) any(vverts, function(w) approx(w,[v.x, 1-v.y, v.z])))
        )
        assert(allgoodx && allgoody, "\nAll VNF tile edge vertices must line up with a vertex on the opposite side of the tile.")
        true
      : // Validate heightfield texture.
        assert(is_matrix(texture), "\nMalformed texture.")
        let( tex_dim = list_shape(texture) )
        assert(len(tex_dim) == 2, "\nHeightfield texture must be a 2D square array of scalar heights.")
        assert(all_defined(tex_dim), "\nHeightfield texture must be a 2D square array of scalar heights.")
        true;



function _tex_height(scale, inset, z) =  scale<0 ? -(1-z - inset) * scale
                                                 :  (z - inset) * scale;
 
function _get_texture(texture, tex_rot) =
    let(
         tex_rot=!is_bool(tex_rot)? tex_rot
                : echo("boolean value for tex_rot is deprecated.  Use a numerical angle divisible by 90.") tex_rot?90:0
    )
    assert(is_num(tex_rot) && posmod(tex_rot,90)==0, "\ntex_rot must be a multiple of 90 degrees.")
    let(
        tex = is_string(texture)? texture(texture,$fn=_tex_fn_default()) : texture,
        check_tex = _validate_texture(tex),       
        tex_rot = posmod(tex_rot,360)
    )
    tex_rot==0 ? tex
  : is_vnf(tex)? zrot(tex_rot, cp=[1/2,1/2], p=tex)
  : tex_rot==180? reverse([for (row=tex) reverse(row)])
  : tex_rot==270? [for (row=transpose(tex)) reverse(row)]
  : reverse(transpose(tex));



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
    assert(counts==undef || is_int(counts) || (all_integer(counts) && len(counts)==2), "\ntex_reps must be an integer or list of two integers.")
    assert(tex_size==undef || is_vector(tex_size,2) || is_finite(tex_size))
    assert(is_bool(rot) || in_list(rot,[0,90,180,270]))
    assert(is_bool(caps) || is_bool_list(caps,2))
    let(
        counts = is_undef(counts) ? undef : force_list(counts,2),
        tex_size = force_list(tex_size,2),
        transform_pt = function(tileind,tilex,tilez,samples,inset,scale,bases,norms) 
               let(
                   pos = (tileind + tilex) * samples,    // tileind is which tile, tilex is position in a tile
                   ind = floor(pos),
                   frac = pos-ind,
                   texh = scale<0 ? -(1-tilez - inset) * scale
                                  : (tilez - inset) * scale,
                   base = lerp(select(bases,ind), select(bases,ind+1), frac),
                   norm = unit(lerp(select(norms,ind), select(norms,ind+1), frac))
              )
              base + norm * texh,
        
        caps = is_bool(caps) ? [caps,caps] : caps,
        regions = is_path(region,2)? [[region]] : region_parts(region),
        texture = _get_texture(texture, rot),
        dummy = assert(is_undef(samples) || is_vnf(texture), "\nYou gave the tex_samples argument with a heightfield texture, which is not permitted. Use the n= argument to texture() instead."),
        h = first_defined([h, l, height, length, 1]),
        inset = is_num(inset)? inset : inset? 1 : 0,
        twist = default(twist, 0),
        shift = default(shift, [0,0]),
        scale = scale==undef? [1,1,1] :
            is_num(scale)? [scale,scale,1] : scale,
        samples = !is_vnf(texture)? len(texture[0]) :
            is_num(samples)? samples : 8,
        vnf_tile =
            !is_vnf(texture) || samples==1 ? texture
          :
            let(
                s = 1 / max(1, samples),
                slice_us = list([s:s:1-s/2]),
                vnf_x = vnf_slice(texture, "X", slice_us),
                vnf_xy = twist? vnf_slice(vnf_x, "Y", slice_us) : vnf_x
            ) vnf_quantize(vnf_xy,1e-4), 
        edge_paths = is_vnf(texture) ? _tile_edge_path_list(vnf_tile,1) : undef,
        tpath = is_def(edge_paths) 
            ? len(edge_paths[0])==0 ? [] : hstack([column(edge_paths[0][0],0), column(edge_paths[0][0],2)])
            : let(
                  row = texture[0],
                  rlen = len(row)
              ) [for (i = [0:1:rlen]) [i/rlen, row[i%rlen]]],
        edge_closed_paths = is_def(edge_paths) ? edge_paths[1] : [],
        tmat = scale(scale) * zrot(twist) * up(h/2),
        texcnt = is_vnf(texture) ? undef
               : [len(texture[0]), len(texture)],
        pre_skew_vnf = vnf_join([
            for (rgn = regions) let(
                walls_vnf = vnf_join([
                    for (path = rgn) let(
                        path = reverse(path),
                        plen = path_length(path, closed=true),
                        counts = is_def(counts) ? counts : [round(plen/tex_size.x), max(1,round(h/tex_size.y)) ],
                        bases = resample_path(path, n=counts.x * samples, closed=true),
                        norms = path_normals(bases, closed=true),
                        vnf = is_vnf(texture)
                          ? vnf_join( // VNF tile texture
                                let(
                                    row_vnf = vnf_join([
                                        for (i = [0:1:(scale==1?0:counts.y-1)], j = [0:1:counts.x-1]) [
                                            [
                                              for (vert=vnf_tile[0])
                                                   let(
                                                        xy = transform_pt(j,vert.x,vert.z,samples, inset, tex_scale, bases, norms),
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
                                            ],
                                            vnf_tile[1]
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
                                tile_rows = [
                                    for (ti = [0:1:texcnt.y-1])
                                      path3d([
                                          for (j = [0:1:counts.x], tj = [0:1:texcnt.x-1])
                                            if (j != counts.x || tj == 0)
                                              transform_pt(j, tj/texcnt.x, texture[ti][tj], samples, inset, tex_scale, bases, norms)
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
                        counts = is_def(counts) ? counts : [round(plen/tex_size.x), max(1,round(h/tex_size.y)) ],
                        bases = resample_path(path, n=counts.x * samples, closed=true),
                        norms = path_normals(bases, closed=true),
                        nupath = [
                            for (j = [0:1:counts.x-1], vert = tpath)
                                transform_pt(j,vert.x,vert.y,samples,inset,tex_scale,bases,norms)
                        ]
                    ) nupath
                ],
                extra_edge_paths = edge_closed_paths==[] ? []
                 : [
                    for (path=rgn)
                      let(
                          path = reverse(path),
                          plen = path_length(path, closed=true),
                          counts = is_def(counts) ? counts : [round(plen/tex_size.x), max(1,round(h/tex_size.y))],
                          bases = resample_path(path, n=counts.x * samples, closed=true),
                          norms = path_normals(bases, closed=true),
                          modpaths = [for (j = [0:1:counts.x-1], cpath = edge_closed_paths)
                                        [for(vert = cpath)
                                           transform_pt(j,vert.x,vert.z,samples,inset,tex_scale,bases, norms)]
                                     ]
                      )
                      each modpaths
                    ],
                brgn_empty = [for(item=brgn) if(item!=[]) 1]==[],
                bot_vnf = !caps[0] || brgn_empty ? EMPTY_VNF
                    : vnf_from_region(brgn, down(h/2), reverse=true),
                top_vnf = !caps[1] || brgn_empty ? EMPTY_VNF
                    : vnf_from_region(brgn, tmat, reverse=false),
                extra_vnfs = [
                   if (caps[0] && len(extra_edge_paths)>0) for(path=extra_edge_paths) [path3d(path,-h/2),[count(len(path))]], 
                   if (caps[1] && len(extra_edge_paths)>0) for(path=extra_edge_paths) [apply(tmat,path3d(path,0)),[count(len(path), reverse=true)]]
                ]
            ) vnf_join([walls_vnf, bot_vnf, top_vnf,each extra_vnfs])
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



// Given a VNF texture tile finds the paths on either the x=0 (axis=0) or the y=0 (axis=1) cases.
// Would also find the z=0 paths if you gave axis=2.
//
// It returns two lists, a list of open paths and a list of closed paths.  By default a max of
// one open path is permitted; either list can be empty.  The paths go in the direction of the segments
// in the VNF.  

function _tile_edge_path_list(vnf, axis, maxopen=1) =
    let(
        verts = vnf[0],
        faces = vnf[1],
        segs = [for(face=faces, edge=pair(select(verts,face),wrap=true)) if (approx(edge[0][axis],0) && approx(edge[1][axis],0)) [edge[1],edge[0]]],
        paths = _assemble_partial_paths(segs),
        closedlist = [
            for(path=paths)
              if (len(path)>3 && approx(path[0],last(path))) list_unwrap(path)
        ],
        openlist = [
            for(path=paths)
              if (path[0]!=last(path)) path
        ]
    )
    assert(len(openlist)<=1, str("\nVNF has ",len(openlist)," open paths on an edge and at most ",maxopen," is supported."))
    [openlist,closedlist];



/// Function&Module: _textured_revolution()
/// Usage: As Function
///   vnf = _textured_revolution(shape, texture, tex_size, [tex_scale=], ...);
///   vnf = _textured_revolution(shape, texture, counts=, [tex_scale=], ...);
/// Usage: As Module
///   _textured_revolution(shape, texture, tex_size, [tex_scale=], ...) [ATTACHMENTS];
///   _textured_revolution(shape, texture, counts=, [tex_scale=], ...) [ATTACHMENTS];
/// Topics: Sweep, Extrusion, Textures, Knurling
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
///   tex_size = An optional 2D target size for the textures.  Actual texture sizes are scaled somewhat to evenly fit the available surface. 
///   tex_scale = Scaling multiplier for the texture depth.
///   ---
///   inset = If numeric, lowers the texture into the surface by that amount, before the tex_scale multiplier is applied.  If `true`, insets by exactly `1`.  Default: `false`
///   rot = If true, rotates the texture 90º.
///   shift = [X,Y] amount to translate the top, relative to the bottom.  Default: [0,0]
///   closed = if true and the shape is a path then treat it as a closed path and make a torus.  If false then connect the path to the axis of rotation with horizontal caps that do not receive any specified texture.  If the shape is a region this option has no effect.  Default: `true`
///   taper = If given, and `closed=false`, tapers the texture height to zero over the first and last given percentage of the path.  If given as a lookup table with indices between 0 and 100, uses the percentage lookup table to ramp the texture heights.  Default: `undef` (no taper)
///   angle = The number of degrees counter-clockwise from X+ to revolve around the Z axis.  Default: `360`
///   style = The triangulation style used.  See {{vnf_vertex_array()}} for valid styles.  Used only with heightfield type textures. Default: `"min_edge"`
///   counts = If given instead of tex_size, gives the tile repetition counts for textures over the surface length and height.
///   samples = Minimum number of "bend points" to have in VNF texture tiles.  Default: 8
///   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
///   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
///   orient = Vector to rotate top toward, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
/// Anchor Types:
///   "hull" = Anchors to the virtual convex hull of the shape.
///   "intersect" = Anchors to the surface of the shape.


function _textured_revolution(
    shape, texture, tex_size, tex_scale=1,
    inset=false, rot=false, shift=[0,0],
    taper, closed=true, angle=360,
    inhibit_y_slicing,tex_aspect, pixel_aspect, 
    counts, samples, start=0,tex_extra,
    style="min_edge", atype="intersect",
    anchor=CENTER, spin=0, orient=UP
) =
    assert(angle>0 && angle<=360)
    assert(is_path(shape,[2]) || is_region(shape))
    assert(is_undef(samples) || is_int(samples))
    assert(is_bool(closed))
    assert(counts==undef || is_int(counts) || (all_integer(counts) && len(counts)==2), "\ntex_reps must be an integer or list of two integers.")
    assert(tex_size==undef || is_vector(tex_size,2) || is_finite(tex_size))
    assert(is_bool(rot) || in_list(rot,[0,90,180,270]))
    assert(in_list(atype, _ANCHOR_TYPES), "\nAnchor type must be \"hull\" or \"intersect\".")
    assert(is_undef(tex_extra) || is_finite(tex_extra) || is_vector(tex_extra,2), "\ntex_extra must be a number of 2-vector.")
    assert(num_defined([tex_aspect, pixel_aspect])<=1, "\nCannot give both tex_aspect and pixel_aspect.")
    assert(is_undef(taper) || !closed, "\nCannot give tex_taper if caps=false.")
    //assert(num_defined([tex_aspect, pixel_aspect])==0 || is_undef(angle), "\nCannot give tex_aspect or pixel_aspect if you give angle.")
    let(
        inhibit_y_slicing = default(inhibit_y_slicing, is_path(shape) && len(shape)==2 ? true : false), 
        regions = !is_path(shape,2)? region_parts(shape)
                : closed? region_parts([shape]) 
                : let(
                      testpoly = [[0,shape[0].y], each shape, [0,last(shape).y]]
                  )
                  [[is_polygon_clockwise(testpoly) ? shape : reverse(shape)]],
        checks = [
            for (rgn=regions, path=rgn)
                assert(all(path, function(pt) pt.x>=0),"\nAll points in the shape must have non-negative x value."),
            //for(reg=regions, path=reg, edge=pair(path,wrap=closed))
            //              assert(edge[0].x>0 || edge[1].x>0,
            //                     str("\nThe shape cannot have any edges on the axis of rotation",closed?" (including the segment that closes the shape).":"."))
        ]
    )
    assert(closed || is_path(shape,2), "\ncaps=true is allowed only with paths")
    let(
        counts = is_undef(counts) ? undef : force_list(counts,2),
        tex_size = force_list(tex_size,2),
        texture = _get_texture(texture, rot),
        tex_extra_try = is_vnf(texture) ? [1,1]
                      : is_def(tex_extra) ? force_list(tex_extra,2)
                      : counts==[1,1] ? [0,0]
                      : [1,1],
        tex_extra = angle==360 ? [1,tex_extra_try.y] : tex_extra_try,
        dummy = assert(is_def(counts) || num_defined([pixel_aspect,tex_aspect])==0, "\nMust specify tex_counts (not tex_size) when using pixel_aspect or tex_aspect.")
                assert(is_undef(pixel_aspect) || !is_vnf(texture), "\nCannot give pixel_aspect with a VNF texture.")
                assert(is_undef(samples) || is_vnf(texture), "\nYou gave the tex_samples argument with a heightfield texture, which is not permitted.  Use the n= argument to texture() instead."),
        inset = is_num(inset)? inset : inset? 1 : 0,
        samples = !is_vnf(texture)? len(texture)
                : is_num(samples)? samples
                : 8,
        bounds = pointlist_bounds(flatten(flatten(regions))),
        maxx = bounds[1].x,
        miny = bounds[0].y,
        maxy = bounds[1].y,
        h = maxy - miny,
        circumf = 2 * PI * maxx,
        texcnt = is_vnf(texture) ? undef : [len(texture[0]), len(texture)],
        angle = num_defined([tex_aspect,pixel_aspect])==0 ? angle
              : let(
                     paths = flatten(regions),
                     lengths = [for(path=paths) path_length(path,closed=closed)],
                     ind = max_index(lengths),
                     rpath = resample_path(paths[ind], n=counts.y * samples + (closed?0:tex_extra.y), closed=closed),
                     h = path_length(rpath), 
                     r = mean(column(rpath,0)),
                     width = counts.x/counts.y * (is_def(pixel_aspect) ? (texcnt.x+tex_extra.x-1)/(texcnt.y+tex_extra.y-1) : tex_aspect) * h + (is_def(pixel_aspect)?1:0),
                     ang = 360 * width / (2*PI*r)
                )
                assert(ang<=360, str("\nAngle required for requested tile counts and aspect is ",ang, ", which exceeds 360°."))
                360 * width / (2*PI*r),

        tile = !is_vnf(texture) || samples==1 ? texture
             :
              let(
                  s = 1 / samples,
                  slices = list([s : s : 1-s/2]),
                  vnfx = vnf_slice(texture, "X", slices),
                  vnfy = inhibit_y_slicing? vnfx : vnf_slice(vnfx, "Y", slices),
                  zvnf = vnf_triangulate(vnf_quantize(vnfy,1e-4))
              ) zvnf,
        edge_paths = is_vnf(tile) ? _tile_edge_path_list(tile,1) : undef,
        edge_closed_paths = is_def(edge_paths) ? edge_paths[1] : [],
        side_paths = angle==360 || !is_vnf(tile) ? undef
                   : _tile_edge_path_list(tile,0),
        side_open_path = is_undef(side_paths) ? undef : len(side_paths[0])==0 ? [] : side_paths[0][0],
        side_closed_paths = is_undef(side_paths) ? [] : side_paths[1], 
        counts_x = is_def(counts)? counts.x : max(1,round(angle/360*circumf/tex_size.x)),
        adj_angle = is_vnf(texture)?angle
                  : angle*(1-(tex_extra.x-1)/(texcnt.x*counts_x+tex_extra.x-1)),  // adjusted angle for strip positions taking tex_extra into account
        taperfunc = closed || is_undef(taper)? function (x) 1
                  : is_finite(taper)?
                         let(
                              taper = taper<=1 ? taper
                                    : echo("The tex_taper now uses a value from 0-1.  Your entry was larger than 1 and has been scaled by 1/100.")
                                      taper/100
                         )
                         assert(taper>=0 && taper<=0.5, str("\ntex_taper must be between 0 and 0.5 but was ",taper,"."))
                         function (x) lookup(x, [[0,0],
                                                 if (taper==0.5) [taper,1]
                                                 else each [[taper+EPSILON,1],[1-taper-EPSILON,1]],
                                                 [1,0]])
                  : is_path(taper,2) ?
                         let(
                             taper = max(column(taper,0)) <= 1 ? taper
                                   : echo("The tex_taper table now uses values from 0-1. Your entry was larger than 1 and has been scaled by 1/100.")
                                     xscale(1/100,taper)
                         )
                         function(x) lookup(x,taper)
                  : is_function(taper) ? taper
                  : assert(false,"\ntex_taper must be a function, scalar, or list of pairs."),
        // Checks a path to see if it has segments on the Y axis.  More than 1 is an error.  If no segments return
        // path unchanged with closed=true.  If there is 1 segment, delete that segment (by rotating the path so it's
        // at the end) and return closed=false.  This prevents textures from continuing into the inside of a shape.  
        open_axis_paths = function(path,closed)
                            !closed ? [path,closed]
                          : let(
                               axind = [for(i=[0:1:len(path)-1]) if (approx(path[i].x,0) && approx(select(path,i+1).x,0)) i],
                               dummy = assert(len(axind)<=1, "\nFound path with more than 1 segment on the Y axis, which is not supported with texturing.")
                            )
                            len(axind)==0 ? [path,true]
                          :
                            [list_rotate(path, (axind[0]+1)%len(path)), false],
        transform_point = function(tileind, tilez, counts_y, bases, norms)
                             let(
                                 part = tileind * samples,
                                 ind = floor(part),
                                 frac = part - ind,
                                 base = lerp(select(bases,ind), select(bases,ind+1), frac),
                                 norm = unit(lerp(select(norms,ind), select(norms,ind+1), frac)),
                                 scale = tex_scale * taperfunc(1-tileind/counts_y) * base.x/maxx,
                                 texh = scale<0 ? -(1-tilez - inset) * scale
                                                :  (tilez - inset) * scale
                             )
                             base - norm * texh,
        full_vnf = vnf_join([
            for (rgn = regions) let(
                rgn_wall_vnf = vnf_join(
                   [for (path = rgn) let(
                        path_closed = open_axis_paths(path,closed),
                        path = path_closed[0],
                        closed = path_closed[1], 
                        plen = path_length(path, closed=closed),
                        counts_y = is_def(counts) ? counts.y : max(1,round(plen/tex_size.y)),
                        obases = resample_path(path, n=counts_y * samples + (closed?0:tex_extra.y), closed=closed),
                        onorms = path_normals(obases, closed=closed),
                        bases = xrot(90, p=path3d(obases)),
                        norms = xrot(90, p=path3d(onorms)),
                        vnf = is_vnf(texture)
                          ? let(strip=
                                  vnf_join([ // VNF tile texture
                                             for (j = [0:1:counts_y-1])
                                                [
                                                   [
                                                       for (vert = tile[0])
                                                            let(xyz = transform_point(j + (1-vert.y),vert.z,counts_y,bases, norms))
                                                            zrot(vert.x*angle/counts_x, p=xyz)
                                                   ],
                                                tile[1]
                                                ]
                                           ]),
                                full_wall = vnf_join([
                                              for (i = [0:1:counts_x-1])
                                                 zrot(i*angle/counts_x, strip)
                                            ])
                            )
                            full_wall
                          : let( // Heightfield texture
                                tiles = [
                                    for (j = [0,1], tj = [0:1:texcnt.x-1])
                                      if (j == 0 || tj < max(1,tex_extra.x))
                                        let(
                                            v = (j * texcnt.x + tj) / (texcnt.x*counts_x+tex_extra.x-1),
                                            mat = zrot(v*angle)
                                        )
                                        apply(mat, [
                                                    for (i = [0:1:counts_y-(closed?1:0)], ti = [0:1:texcnt.y-1])
                                                      if (i != counts_y || ti < tex_extra.y)
                                                         transform_point(i + (ti/texcnt.y),texture[ti][tj],counts_y, bases, norms)
                                               ])
                                ],
                                strip_pts = transpose(select(tiles,0,texcnt.x)),
                                last_pts = transpose(select(tiles,0,texcnt.x-1+tex_extra.x)),
                                strip_vnf = vnf_vertex_array(strip_pts, caps=false, style=style,col_wrap=false, row_wrap=closed),
                                last_vnf = vnf_vertex_array(last_pts, caps=false, style=style,col_wrap=false, row_wrap=closed),
                                full_wall = vnf_join([
                                                       for (i = [0:1:counts_x-2]) zrot(i*adj_angle/counts_x, strip_vnf),
                                                       zrot((counts_x-1)*adj_angle/counts_x, last_vnf)
                                                     ])
                            )
                            full_wall
                      )
                      vnf
                   ]),
                sidecap_vnf = angle == 360? EMPTY_VNF :
                    let(
                        cap_rgn = side_open_path == [] ? [] 
                           : [ for (path = rgn)
                                 let(
                                   path_closed = open_axis_paths(path,closed),
                                   path = path_closed[0],
                                   closed = path_closed[1], 
                                   plen = path_length(path, closed=closed),
                                   counts_y = is_def(counts) ? counts.y : max(1,round(plen/tex_size.y)),
                                   bases = resample_path(path, n=counts_y * samples + (closed?0:tex_extra.y), closed=closed),
                                   norms = path_normals(bases, closed=closed),
                                   ppath = is_vnf(texture)
                                         ? let( onepath = [ // VNF tile texture
                                                             for (j = [0:1:counts_y-1], vert=side_open_path)
                                                               transform_point(j + (1 - vert.y),vert.z,counts_y,bases, norms)
                                                          ]
                                           )
                                           [onepath,onepath]
                                        :
                                           [for(j=[0,1])    // Heightfield texture
                                              [ 
                                               for (i = [0:1:counts_y-(closed?1:0)], ti = [0:1:texcnt.y-1])
                                                 if (i != counts_y || ti < tex_extra.y)
                                                   transform_point(i + (ti/texcnt.y),texture[ti][(j*(texcnt.x-1+tex_extra.x))%texcnt.x],counts_y, bases, norms)
                                              ]
                                          ], 
                                   paths = [for(p=ppath)
                                              deduplicate([
                                                           if (!closed) [0, p[0].y],
                                                           each p,
                                                           if (!closed) [0, last(p).y]
                                                          ],
                                                          closed=closed)]
                                 )
                                 paths
                             ],
                        cap_vnfs = cap_rgn == [] ? [EMPTY_VNF]
                                 : [for(i=[0,1]) vnf_from_region(column(cap_rgn,i), rot([90,0,i*angle]), reverse=i==1)],
                        extra_paths = side_closed_paths==[] ? [] 
                           : [for (path = rgn) let(
                                path_closed = open_axis_paths(path,closed),
                                path = path_closed[0],
                                closed = path_closed[1], 
                            
                                plen = path_length(path, closed=closed),
                                counts_y = is_def(counts) ? counts.y : max(1,round(plen/tex_size.y)),
                                bases = resample_path(path, n=counts_y * samples + (closed?0:1), closed=closed),
                                norms = path_normals(bases, closed=closed),
                                modpaths = [for (j = [0:1:counts_y-1], cpath=side_closed_paths)
                                              [for(vert=cpath)
                                                 transform_point(j + (1 - vert.y),vert.z,counts_y,bases, norms)]
                                           ]
                             )
                             each modpaths
                            ],
                        extra_vnfs = [
                           if (len(extra_paths)>0) for(path=extra_paths) [xrot(90,path3d(path)), [count(len(path))]],
                           if (len(extra_paths)>0) for(path=extra_paths) [rot([90,0,angle],p=path3d(path)), [count(len(path),reverse=true)]],
                        ]
                    ) vnf_join(concat(cap_vnfs, extra_vnfs)),
                endcaps_vnf = closed? EMPTY_VNF :
                    let(
                        path_closed = open_axis_paths(rgn[0],closed),
                        path = path_closed[0],
                        closed = path_closed[1], 
                        plen = path_length(path, closed=closed),
                        counts_y = is_def(counts) ? counts.y : max(1,round(plen/tex_size.y)),
                        obases = resample_path(path, n=counts_y * samples + (closed?0:tex_extra.y), closed=closed),
                        onorms = path_normals(obases, closed=closed),
                        bases = xrot(90, p=path3d(obases)),
                        norms = xrot(90, p=path3d(onorms)),
                        bpath = is_def(edge_paths)
                                   ? len(edge_paths[0])==0 ? [] : repeat(hstack([column(edge_paths[0][0],0), column(edge_paths[0][0],2)]),2)
                                   :  
                                     [ for(j=[texcnt.y-1+tex_extra.y,0])
                                         [for (i = [0:1:texcnt.x-1+max(1,tex_extra.x)])
                                             [i/texcnt.x, texture[j%texcnt.y][i%texcnt.x]]]],
                        caps_vnf = vnf_join([
                            for (epath=edge_closed_paths, j = [-1,0])
                                    let(
                                        base = select(bases,j),
                                        norm = unit(select(norms,j)),
                                        ppath = [
                                            for (vert = epath) let(
                                                uang = vert.x / counts_x,
                                                tex_scale = tex_scale * taperfunc(j+1),
                                                texh = tex_scale<0 ? -(1-vert.z - inset) * tex_scale * (base.x / maxx)
                                                                   : (vert.z - inset) * tex_scale * (base.x / maxx),
                                                xyz = base - norm * texh
                                            ) zrot(angle*uang, p=xyz)
                                        ],
                                        faces = [count(ppath,reverse=j==0)]
                                    )
                                    for(i=[0:1:counts_x-1])
                                        [zrot(i*angle/counts_x, ppath), faces],
                            if (len(bpath)>0)
                                for (j = [-1,0])
                                    let(
                                         base = select(bases,j),
                                         norm = unit(select(norms,j)),
                                         ppath = [
                                             for (vert = bpath[j+1]) let(
                                                 uang = vert.x / counts_x,
                                                 tex_scale = tex_scale * taperfunc(j+1),
                                                 texh = tex_scale<0 ? -(1-vert.y - inset) * tex_scale * (base.x / maxx)
                                                                    : (vert.y - inset) * tex_scale * (base.x / maxx),
                                                 xyz = base - norm * texh
                                             ) zrot(adj_angle*uang, p=xyz)
                                         ],
                                         pplen = is_def(texcnt) ? texcnt.x+1 : len(ppath), 
                                         last_len = len(ppath)-(tex_extra.x==0?1:0), 
                                         zed = j<0? max(column(ppath,2)): min(column(ppath,2)),
                                         slice_vnf = [
                                             [
                                                 each select(ppath,0,pplen-1),
                                                 [0, 0, zed],
                                             ], [
                                                 for (i = [0:1:pplen-2])
                                                     j<0? [pplen, i, (i+1)%pplen]
                                                        : [pplen, (i+1)%pplen, i]
                                             ]
                                         ],
                                         last_slice = [
                                             [
                                                 each select(ppath,0,last_len-1),
                                                 [0, 0, zed],
                                             ], [
                                                 for (i = [0:1:last_len-2])
                                                     j<0? [last_len, i, (i+1)%last_len]
                                                        : [last_len, (i+1)%last_len, i]
                                             ]
                                         ]
                                    )
                                    for (i = [0:counts_x-1])
                                       i<counts_x-1 ? zrot(i*adj_angle/counts_x, slice_vnf)
                                                    : zrot((counts_x-1)*adj_angle/counts_x, last_slice)
                        ])
                    ) caps_vnf
            ) vnf_join([rgn_wall_vnf, sidecap_vnf, endcaps_vnf])
        ]),
        skmat = zrot(start) * down(-miny) * skew(sxz=shift.x/h, syz=shift.y/h) * up(-miny),
        skvnf = apply(skmat, full_vnf),
        geom = atype=="intersect"
              ? attach_geom(vnf=skvnf, extent=false)
              : attach_geom(vnf=skvnf, extent=true)
    ) reorient(anchor,spin,orient, geom=geom, p=skvnf);



module _textured_revolution(
    shape, texture, tex_size, tex_scale=1,
    inset=false, rot=false, shift=[0,0],
    taper, closed=true, angle=360,
    style="min_edge", atype="intersect",tex_aspect, pixel_aspect, 
    inhibit_y_slicing=false,tex_extra,
    convexity=10, counts, samples, start=0,
    anchor=CENTER, spin=0, orient=UP
) {
    dummy = assert(in_list(atype, _ANCHOR_TYPES), "\nAnchor type must be \"hull\" or \"intersect\".");
    vnf = _textured_revolution(
        shape, texture, tex_size=tex_size,
        tex_scale=tex_scale, inset=inset, rot=rot,
        taper=taper, closed=closed, style=style,tex_aspect=tex_aspect, pixel_aspect=pixel_aspect, 
        shift=shift, angle=angle,tex_extra=tex_extra,
        samples=samples, counts=counts, start=start, 
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


function _textured_point_array(points, texture, tex_reps, tex_size, tex_samples, tex_inset=false, tex_rot=0, triangulate=false, tex_scaling="default",return_edges=false, 
                col_wrap=false, tex_depth=1, row_wrap=false, caps, cap1, cap2, reverse=false, style="min_edge", tex_extra, tex_skip, sidecaps,sidecap1,sidecap2,normals) =
    assert(tex_reps==undef || is_int(tex_reps) || (all_integer(tex_reps) && len(tex_reps)==2), "\ntex_reps must be an integer or list of two integers.")
    assert(tex_size==undef || is_num(tex_size) || is_vector(tex_size,2), "\ntex_size must be a scalar or 2-vector.")
    assert(num_defined([tex_size, tex_reps])==1, "\nMust give exactly one of tex_size and tex_reps.")
    assert(in_list(style,["default","alt","quincunx", "convex","concave", "min_edge","min_area","flip1","flip2"]))
    assert(is_matrix(points[0], n=3),"\nPoint array has the wrong shape or points are not 3D.")
    assert(is_consistent(points), "\nNon-rectangular or invalid point array.")
    let(
        cap1 = first_defined([cap1,caps,false]),
        cap2 = first_defined([cap2,caps,false]),
        sidecap1 = first_defined([sidecap1,sidecaps,false]),
        sidecap2 = first_defined([sidecap2,sidecaps,false]),
        tex_inset = is_num(tex_inset)? tex_inset : tex_inset? 1 : 0,
        texture = _get_texture(texture, tex_rot),
        dummy = assert(is_undef(tex_samples) || is_vnf(texture),
                       "\nYou gave the tex_samples argument with a heightfield texture, which is not permitted. Use the n= argument to texture() instead."),
        ptsize=[len(points[0]), len(points)],
        tex_reps = is_def(tex_reps) ? force_list(tex_reps,2)
                 : let(
                       tex_size = force_list(tex_size,2),
                       xsize = norm(points[0][0]-points[0][1])*(ptsize.x+(col_wrap?1:0)),
                       ysize = norm(points[0][0]-points[1][0])*(ptsize.y+(row_wrap?1:0))
                   )
                   [max(1,round(xsize/tex_size.x)), max(1,round(ysize/tex_size.y))],
        normals = default(normals,surface_normals(points, col_wrap=col_wrap, row_wrap=row_wrap)),
        getscale = tex_scaling=="default" ? function(x,y) (x+y)/2
                 : tex_scaling=="const" ? function(x,y) 1
                 : assert(false, "\nUnknown tex_scaling value. Must be either \"default\" or \"const\".")
    )
    !is_vnf(texture) ?  // heightmap case
        let(
            extra = is_def(tex_extra) ? force_list(tex_extra,2)
                  : [col_wrap?0:1, row_wrap?0:1],
            skip = is_def(tex_skip) ? force_list(tex_skip,2) : [0,0],
            texsize = [len(texture[0]), len(texture)],
            fullsize = [texsize.x*tex_reps.x+extra.x-skip.x, texsize.y*tex_reps.y+extra.y-skip.y],
            res_points = _resample_point_array(points,fullsize, col_wrap=col_wrap, row_wrap=row_wrap),
            res_normals= _resample_point_array(normals,fullsize, col_wrap=col_wrap, row_wrap=row_wrap),
            local_scale = [for(y=[0:1:fullsize.y-1])
                             [for(x=[0:1:fullsize.x-1])
                                let(
                                     xlen = [
                                              if(x>0 || col_wrap) norm(res_points[y][x] - select(res_points[y], x-1)),
                                              if(x<fullsize.x-1 || col_wrap) norm(res_points[y][x] - select(res_points[y], x+1))
                                            ],
                                     ylen = [
                                              if(y>0 || row_wrap) norm(res_points[y][x] - select(res_points,y-1)[x]),
                                              if(y<fullsize.y-1 || row_wrap) norm(res_points[y][x] - select(res_points,y+1)[x])
                                            ]
                                 )
                                 getscale(mean(xlen),mean(ylen))
                              ]
                           ],
            tex_surf =
              [for(y=[0:1:fullsize.y-1])
                 [for(x=[0:1:fullsize.x-1])
                    let(yind = (y+skip.y)%texsize.y,
                        xind = (x+skip.x)%texsize.x
                    )
                    res_points[y][x] + _tex_height(tex_depth,tex_inset,texture[yind][xind]) * res_normals[y][x]*(reverse?-1:1)*local_scale[y][x]/local_scale[0][0]
                  ]
              ]
        )  
        vnf_vertex_array(tex_surf, row_wrap=row_wrap, col_wrap=col_wrap, reverse=reverse,style=style,
                         caps=caps, cap1=cap1, cap2=cap2, triangulate=triangulate, return_edges=return_edges)
   : // VNF case
        let(
            local_scale = [for(y=[-1:1:ptsize.y])
                             [for(x=[-1:1:ptsize.x])
                               ((!col_wrap && (x<0 || x>=ptsize.x-1))
                                   || (!row_wrap && (y<0 || y>=ptsize.y-1))) ? undef
                              : let(
                                     dx = [norm(select(select(points,y),x) - select(select(points,y),x+1)),
                                          norm(select(select(points,y+1),x) - select(select(points,y+1),x+1))],
                                     dy = [norm(select(select(points,y),x) - select(select(points,y+1),x)),
                                          norm(select(select(points,y),x+1) - select(select(points,y+1),x+1))]
                                )
                                getscale(mean(dx),mean(dy))]],
            samples = default(tex_samples,8),
            vnf = samples==1? texture
                :
                  let(
                      s = 1 / samples,
                      slice_us = list([s:s:1-s/2]),
                      vnf_x = vnf_slice(texture, "X", slice_us),
                      vnf_xy = vnf_slice(vnf_x, "Y", slice_us),
                      vnf_q = vnf_quantize(vnf_xy,1e-4)
                  )
                  vnf_triangulate(vnf_q),
            yedge_paths = !row_wrap ? _tile_edge_path_list(vnf,1) : undef,
            xedge_paths = !col_wrap ? _tile_edge_path_list(vnf,0) : undef,
            trans_pt = function(x,y,pt)
               let(
                   tileindx = x+pt.x,
                   tileindy = y+(1-pt.y),

                   refx = tileindx/tex_reps.x*(ptsize.x-(col_wrap?0:1)),
                   refy = tileindy/tex_reps.y*(ptsize.y-(row_wrap?0:1)),
                   xind = floor(refx),
                   yind = floor(refy),
                   xfrac = refx-xind,
                   yfrac = refy-yind, 
                   corners = [points[yind%ptsize.y][xind%ptsize.x],     points[(yind+1)%ptsize.y][xind%ptsize.x],
                              points[yind%ptsize.y][(xind+1)%ptsize.x], points[(yind+1)%ptsize.y][(xind+1)%ptsize.x]],
                   base = bilerp(corners,yfrac, xfrac),
                   scale_list = xfrac==0 && yfrac==0 ? [local_scale[yind][xind], local_scale[yind][xind+1], local_scale[yind+1][xind], local_scale[yind+1][xind+1]]
                              : xfrac==0 ? [local_scale[yind+1][xind], local_scale[yind+1][xind+1]]
                              : yfrac==0 ? [local_scale[yind][xind+1], local_scale[yind+1][xind+1]]
                              :            [ local_scale[yind+1][xind+1]],
                   scale = mean([for(s=scale_list) if (is_def(s)) s])/local_scale[1][1],
                   normal = bilerp([normals[yind%ptsize.y][xind%ptsize.x],     normals[(yind+1)%ptsize.y][xind%ptsize.x],
                                    normals[yind%ptsize.y][(xind+1)%ptsize.x], normals[(yind+1)%ptsize.y][(xind+1)%ptsize.x]],
                                    yfrac, xfrac)
               )
               base + _tex_height(tex_depth,tex_inset,pt.z) * normal*(reverse?-1:1) * scale,
            fullvnf = vnf_join([
                           for(y=[0:1:tex_reps.y-1], x=[0:1:tex_reps.x-1])   // Main body of the textured shape
                             [
                              [for(pt=vnf[0]) trans_pt(x,y,pt)],
                              vnf[1]
                             ],
                           for(y=[if (cap1) 0, if (cap2) tex_reps.y-1])
                             let(
                                 cap_paths = [
                                              if (col_wrap && len(yedge_paths[0])>0)
                                                 [for(x=[0:1:tex_reps.x-1], pt=yedge_paths[0][0])
                                                     trans_pt(x,y,[pt.x,y?0:1,pt.z])],
                                              if (!row_wrap)      
                                                for(closed_path=yedge_paths[1], x=[0:1:tex_reps.x-1])
                                                   [for(pt = closed_path) trans_pt(x,y,[pt.x,y?0:1,pt.z])]
                                             ]
                             )
                             for(path=cap_paths) [path, [count(path,reverse=y==0)]],
                           if (!col_wrap)
                             for(x=[if (sidecap1) 0, if (sidecap2) tex_reps.x-1])
                                let( 
                                   cap_paths = [for(closed_path=xedge_paths[1], y=[0:1:tex_reps.y-1])
                                                   [for(pt = closed_path) trans_pt(x,y,[x?1:0,pt.y,pt.z])]]
                                )
                                for(path=cap_paths) [path, [count(path,reverse=x!=0)]]
                      ]),
            edgepaths = !return_edges ? undef
                      : [
                          if (!col_wrap)
                             for(x=[0, tex_reps.x-1])
                                   [for(y=[0:1:tex_reps.y-1],pt=xedge_paths[0][0])
                                                   trans_pt(x,y,[x?1:0,pt.y,pt.z])]
                          else each [[],[]],
                                 
                          if (!row_wrap && len(yedge_paths[0])>0)
                             for(ind=[0,1])
                               if ([cap1,cap2][ind]) []
                               else let(y=[0,tex_reps.y-1][ind])
                               [for(x=[0:1:tex_reps.x-1], pt=yedge_paths[0][0])
                                                     trans_pt(x,y,[pt.x,y?0:1,pt.z])]
                          else each [[],[]]
                        ],
            revvnf = reverse ? vnf_reverse_faces(fullvnf) : fullvnf
                          
       )
       !return_edges ? revvnf : [revvnf, edgepaths];


// Resamples a point array to the specified size.
// In use above, data is a list of points in R^3 on a grid 
// and size is the desired dimensions of the output array covering the
// same data. 

function _resample_point_array(data, size, col_wrap=false, row_wrap=false) =
  let(
      xL=len(data[0]),
      yL=len(data),
      lastx=xL-(col_wrap?0:1),
      lasty=yL-(row_wrap?0:1),
      lastoutx = size.x - (col_wrap?0:1),
      lastouty = size.y - (row_wrap?0:1),      
      xscale = lastx/lastoutx,
      yscale = lasty/lastouty
  )
  [
    for(y=[0:1:lastouty])
      [
        for(x=[0:1:lastoutx])
           let(
                sx = xscale*x,
                sy = yscale*y,
                xind=floor(sx),
                yind=floor(sy)
           )
           bilerp([data[yind%yL][xind%xL],     data[(yind+1)%yL][xind%xL],
                   data[yind%yL][(xind+1)%xL], data[(yind+1)%yL][(xind+1)%xL]],
                  sy-yind, sx-xind)
      ]
  ];

// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
