//////////////////////////////////////////////////////////////////////
// LibFile: skin.scad
//   Functions to skin arbitrary 2D profiles/paths in 3-space.
//   To use, add the following line to the beginning of your file:
//   ```
//   include <BOSL2/std.scad>
//   include <BOSL2/skin.scad>
//   ```
//   Derived from list-comprehension-demos skin():
//   - https://github.com/openscad/list-comprehension-demos/blob/master/skin.scad
//////////////////////////////////////////////////////////////////////


include <vnf.scad>


// Section: Skinning


// Function&Module: skin()
// Usage: As Module
//   skin(profiles, [closed], [method]);
// Usage: As Function
//   vnf = skin(profiles, [closed], [caps], [method]);
// Description
//   Given a list of two or more path `profiles` in 3D-space, produces faces to skin a surface between
//   consecutive profiles.  Optionally, the first and last profiles can have endcaps, or the last and
//   first profiles can be skinned together.  Each profile should be roughly planar, but some variance
//   is allowed.  The orientation of the first vertex of each profile should be relatively aligned with
//   that of the next profile.  Each profile should rotate the same clockwise direction.
//   If called as a function, returns a [VNF structure](vnf.scad) like `[VERTICES, FACES]`.
//   If called as a module, creates a polyhedron of the skinned profiles.
//   The vertex matching methods are as follows:
//   - `"distance"`: Vertices between profiles are matched based on closest next position, relative to the center of each profile.
//   - `"angle"`: Vertices between profiles are matched based on closest next polar angle, relative to the center of each profile.
//   - `"uniform"`: Vertices are uniformly matched between profiles, such that a point 30% of the way through one profile, will be matched to a vertex 30% of the way through the other profile, based on vertex count.
// Arguments:
//   profiles = A list of 2D paths that have been moved and/or rotated into 3D-space.
//   closed = If true, the last profile is skinned to the first profile, to allow for making a closed loop.  Assumes `caps=false`.  Default: false
//   caps = If true, endcap faces are created.  Assumes `closed=false`.  Default: true
//   method = Specifies the method used to match up vertices between profiles, to create faces.  Given as a string, one of `"distance"`, `"angle"`, or `"uniform"`.  If given as a list of strings, equal in number to the number of profile transitions, lets you specify the method used for each transition.  Default: "uniform"
// Example(FlatSpin):
//   skin([
//      scale([2,1,1], p=path3d(circle(d=100,$fn=48))),
//      path3d(circle(d=100,$fn=4),100),
//      path3d(circle(d=100,$fn=12),200),
//   ], method="distance");
// Example(FlatSpin):
//   skin([
//       for (ang = [0:10:90])
//       rot([0,ang,0], cp=[200,0,0], p=path3d(circle(d=100,$fn=3+(ang/10))))
//   ]);
// Example(FlatSpin): Möbius Strip
//   skin([
//       for (ang = [0:10:360])
//       rot([0,ang,0], cp=[100,0,0], p=rot(ang/2, p=path3d(square([1,30],center=true))))
//   ], caps=false);
// Example(FlatSpin): Closed Loop
//   skin([
//       for (i = [0:5])
//       rot([0,i*60,0], cp=[100,0,0], p=path3d(circle(d=30,$fn=3+i%3)))
//   ], closed=true, caps=false);
// Example(FlatSpin): Method "distance" is a good general purpose vertex matching method.
//   method = "distance";
//   xdistribute(150) {
//       $fn=24;
//       skin([
//           yscale(2, p=path3d(circle(d=75))),
//           [[40,0,100], [35,-15,100], [20,-30,100],[0,-40,100],[-40,0,100],[0,40,100],[20,30,100], [35,15,100]]
//       ], method=method);
//       skin([
//           for (b=[0,90]) [
//               for (a=[360:-360/$fn:0.01])
//                   point3d(polar_to_xy((100+50*cos((a+b)*2))/2,a),b/90*100)
//           ]
//       ], method=method);
//       skin([
//           scale([1,2,1],p=path3d(circle(d=50))),
//           scale([2,1,1],p=path3d(circle(d=50),100))
//       ], method=method);
//   }
// Example(FlatSpin): Method "angle" works subtly better with profiles created from a polar function.
//   method = "angle";
//   xdistribute(150) {
//       $fn=24;
//       skin([
//           yscale(2, p=path3d(circle(d=75))),
//           [[40,0,100], [35,-15,100], [20,-30,100],[0,-40,100],[-40,0,100],[0,40,100],[20,30,100], [35,15,100]]
//       ], method=method);
//       skin([
//           for (b=[0,90]) [
//               for (a=[360:-360/$fn:0.01])
//                   point3d(polar_to_xy((100+50*cos((a+b)*2))/2,a),b/90*100)
//           ]
//       ], method=method);
//       skin([
//           scale([1,2,1],p=path3d(circle(d=50))),
//           scale([2,1,1],p=path3d(circle(d=50),100))
//       ], method=method);
//   }
// Example(FlatSpin): Method "uniform" works well with symmetrical profiles that are regularly spaced.
//   method = "uniform";
//   xdistribute(150) {
//       $fn=24;
//       skin([
//           yscale(2, p=path3d(circle(d=75))),
//           [[40,0,100], [35,-15,100], [20,-30,100],[0,-40,100],[-40,0,100],[0,40,100],[20,30,100], [35,15,100]]
//       ], method=method);
//       skin([
//           for (b=[0,90]) [
//               for (a=[360:-360/$fn:0.01])
//                   point3d(polar_to_xy((100+50*cos((a+b)*2))/2,a),b/90*100)
//           ]
//       ], method=method);
//       skin([
//           scale([1,2,1],p=path3d(circle(d=50))),
//           scale([2,1,1],p=path3d(circle(d=50),100))
//       ], method=method);
//   }
// Example:
//   include <BOSL2/rounding.scad>
//   fn=32;
//   base = round_corners(square([2,4],center=true), measure="radius", size=0.5, $fn=fn);
//   skin([
//       path3d(base,0),
//       path3d(base,2),
//       path3d(circle($fn=fn,r=0.5),3),
//       path3d(circle($fn=fn,r=0.5),4),
//       path3d(circle($fn=fn,r=0.6),4),
//       path3d(circle($fn=fn,r=0.5),5),
//       path3d(circle($fn=fn,r=0.6),5),
//       path3d(circle($fn=fn,r=0.5),6),
//       path3d(circle($fn=fn,r=0.6),6),
//       path3d(circle($fn=fn,r=0.5),7),
//   ],method="uniform");
// Example: Forma Candle Holder
//   r = 50;
//   height = 140;
//   layers = 10;
//   wallthickness = 5;
//   holeradius = r - wallthickness;
//   difference() {
//       skin([for (i=[0:layers-1]) zrot(-30*i,p=path3d(hexagon(ir=r),i*height/layers))]);
//       up(height/layers) cylinder(r=holeradius, h=height);
//   }
// Example: Beware Self-intersecting Creases!
//   skin([
//       for (a = [0:30:180]) let(
//           pos  = [-60*sin(a),     0, a    ],
//           pos2 = [-60*sin(a+0.1), 0, a+0.1]
//       ) move(pos,
//           p=rot(from=UP, to=pos2-pos,
//               p=path3d(circle(d=150))
//           )
//       )
//   ]);
//   color("red") {
//       zrot(25) fwd(130) xrot(75) {
//           linear_extrude(height=0.1) {
//               ydistribute(25) {
//                   text(text="BAD POLYHEDRONS!", size=20, halign="center", valign="center");
//                   text(text="CREASES MAKE", size=20, halign="center", valign="center");
//               }
//           }
//       }
//       up(160) zrot(25) fwd(130) xrot(75) {
//           stroke(zrot(30, p=yscale(0.5, p=circle(d=120))),width=10,closed=true);
//       }
//   }
// Example: Beware Making Incomplete Polyhedrons!
//   skin([
//       move([0,0, 0], p=path3d(circle(d=100,$fn=36))),
//       move([0,0,50], p=path3d(circle(d=100,$fn=6)))
//   ], caps=false);
module skin(profiles, closed=false, caps=true, method="uniform") {
	vnf_polyhedron(skin(profiles, caps=caps, closed=closed, method=method));
}


function skin(profiles, closed=false, caps=true, method="uniform") =
	assert(is_list(profiles))
	assert(is_bool(closed))
	assert(is_bool(caps))
	assert(!closed||!caps)
	assert(is_string(method)||is_list(method))
	let( method = is_list(method)? method : [for (pidx=idx(profiles,end=closed?-1:-2)) method] )
	assert(len(method) == len(profiles)-closed?0:1)
	vnf_triangulate(
		concat([
			for(pidx=idx(profiles,end=closed? -1 : -2))
			let(
				prof1 = profiles[pidx%len(profiles)],
				prof2 = profiles[(pidx+1)%len(profiles)],
				cp1 = mean(prof1),
				cp2 = mean(prof2),
				midpt = (cp1+cp2)/2,
				n1 = plane_normal(plane_from_pointslist(prof1)),
				n2 = plane_normal(plane_from_pointslist(prof2)),
				vang = vector_angle(n1,n2),
				perp = vang>0.01 && vang<179.99? vector_axis(n1,n2) :
					vector_angle(n1,RIGHT)>44? vector_axis(n1,RIGHT) :
					vector_axis(n1,UP),
				perp1 = vector_axis(perp,n1),
				perp2 = vector_axis(perp,n2),
				poly1 = project_plane(prof1, cp1, cp1+perp, cp1+perp1),
				poly2 = project_plane(prof2, cp2, cp2+perp, cp2+perp2),
				match = method[pidx],
				faces = [
					for(
						first = true,
						finishing = false,
						finished = false,
						plen1 = len(poly1),
						plen2 = len(poly2),
						i=0, j=0, side=0;

						!finished;

						dang1 = abs(modang(xy_to_polar(poly1[i%plen1]).y - xy_to_polar(poly2[(j+1)%plen2]).y)),
						dang2 = abs(modang(xy_to_polar(poly2[j%plen2]).y - xy_to_polar(poly1[(i+1)%plen1]).y)),
						dist1 = norm(poly1[i%plen1] - poly2[(j+1)%plen2]),
						dist2 = norm(poly2[j%plen2] - poly1[(i+1)%plen1]),
						pctdist1 = abs((i/plen1) - ((j+1)/plen2)),
						pctdist2 = abs((j/plen2) - ((i+1)/plen1)),
						side = i>=plen1? 0 :
							j>=plen2? 1 :
							match=="angle"? (dang1>dang2? 1 : 0) :
							match=="distance"? (dist1>dist2? 1 : 0) :
							match=="uniform"? (pctdist1>pctdist2? 1 : 0) :
							assert(in_list(method[i],["angle","distance","uniform"]),str("Got `",method,"'")),
						p1 = prof1[i%plen1],
						p2 = prof2[j%plen2],
						p3 = side? prof1[(i+1)%plen1] : prof2[(j+1)%plen2],
						face = [p1, p3, p2],
						i = i + (side? 1 : 0),
						j = j + (side? 0 : 1),
						first = false,
						finished = finishing,
						finishing = i>=plen1 && j>=plen2
					) if (!first) face
				]
			) vnf_add_faces(faces=faces)
		], closed||!caps? [] : let(
			prof1 = profiles[0],
			prof2 = select(profiles,-1)
		) [
			vnf_add_face(pts=reverse(prof1)),
			vnf_add_face(pts=prof2)
		])
	);


// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
