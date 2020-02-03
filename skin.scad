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
//   - `"distance"`: Chooses face configurations with shorter edge lengths.
//   - `"angle"`: Chooses face configurations with edge angles closest to vertical.
//   - `"convex"`: Chooses the more convex of possible face configurations.
//   - `"uniform"`: Vertices are uniformly matched between profiles, such that a point 30% of the way through one profile, will be matched to a vertex 30% of the way through the other profile, based on vertex count.
// Arguments:
//   profiles = A list of 2D paths that have been moved and/or rotated into 3D-space.
//   closed = If true, the last profile is skinned to the first profile, to allow for making a closed loop.  Assumes `caps=false`.  Default: false
//   caps = If true, endcap faces are created.  Assumes `closed=false`.  Default: true
//   method = Specifies the method used to match up vertices between profiles, to create faces.  Given as a string, one of `"distance"`, `"angle"`, or `"uniform"`.  If given as a list of strings, equal in number to the number of profile transitions, lets you specify the method used for each transition.  Default: "uniform"
//   convexity = Max number of times a line could intersect a wall of the shape.  (Module use only.)  Default: 2.
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
// Example(FlatSpin): Method "convex" maximizes convexity.
//   method = "convex";
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
module skin(profiles, closed=false, caps=true, method="uniform", convexity=2) {
	vnf_polyhedron(skin(profiles, caps=caps, closed=closed, method=method), convexity=convexity);
}


function skin(profiles, closed=false, caps=true, method="uniform") =
	assert(is_list(profiles))
	assert(all([for (profile=profiles) is_list(profile) && len(profile[0])==3]), "All profiles must be 3D paths.")
	assert(is_bool(closed))
	assert(is_bool(caps))
	assert(!closed||!caps)
	assert(is_string(method)||is_list(method))
	let(
		method = is_list(method)? method : [for (pidx=idx(profiles,end=closed?-1:-2)) method],
		vertices = [for (prof=profiles) each prof],
		plens = [for (prof=profiles) len(prof)]
	)
	assert(len(method) == len(profiles)-closed?0:1)
	let(
		sidefaces = [
			for(pidx=idx(profiles,end=closed? -1 : -2))
			let(
				prof1 = profiles[pidx%len(profiles)],
				prof2 = profiles[(pidx+1)%len(profiles)],
				cp1 = centroid(prof1),
				cp2 = centroid(prof2),
				midpt = (cp1+cp2)/2,
				n1 = plane_normal(plane_from_pointslist(prof1)),
				n2 = plane_normal(plane_from_pointslist(prof2)),
				midn = normalize((n1+n2)/2),
				match = method[pidx],
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
							i>=plen1*2? 0 :
							j>=plen2*2? 1 :
							let(
								p1a = prof1[(i+0)%plen1],
								p1b = prof1[(i+1)%plen1],
								p2a = prof2[(j+0)%plen2],
								p2b = prof2[(j+1)%plen2]
							)
							match=="distance"? let(
								dist1 = norm(p1a-p2b),
								dist2 = norm(p1b-p2a)
							) (dist1>dist2? 1 : 0) :
							match=="angle"? let(
								delta1 = rot(from=midn, to=UP, p=p2b - p1a),
								delta2 = rot(from=midn, to=UP, p=p2a - p1b),
								dist1 = atan2(norm([delta1.x, delta1.y]), abs(delta1.z)),
								dist2 = atan2(norm([delta2.x, delta2.y]), abs(delta2.z))
							) (dist1>dist2? 1 : 0) :
							match=="convex"? let(
								mid1 = (p2b + p1a)/2,
								mid2 = (p2a + p1b)/2,
								dist1 = norm(mid1-midpt),
								dist2 = norm(mid2-midpt)
							) (dist1<dist2? 1 : 0) :
							match=="uniform"? let(
								pct1 = i/plen1,
								pct2 = j/plen2,
								dist1 = norm(p1a-p2b),
								dist2 = norm(p1b-p2a)
							) (approx(pct1,pct2)? (dist1>dist2? 1 : 0) : (pct1<=pct2? 1 : 0)) :
							assert(in_list(match,["distance","angle","convex","uniform"]),str("Got `",method,"'")),
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
		capfaces = closed||!caps? [] : let(
			prof1 = profiles[0],
			prof2 = select(profiles,-1),
			eoff = sum(select(plens,0,-2))
		) [
			[for (i=idx(prof1)) plens[0]-1-i],
			[for (i=idx(prof2)) eoff+i]
		],
		vnfout = [vertices, concat(sidefaces,capfaces)]
	) vnfout;



/////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////
//
// Developmental skin wrapper, called superskin() for now, but this
// is not meant to be the final name.

// Function&Module: superskin()
// Usage: As module:
//   skin(profiles, [slices], [samples|refine], [method], [smethod], [caps], [closed], [z]);
// Usage: As function:
//   vnf = skin(profiles, [slices], [samples|refine], [method], [smethod], [caps], [closed], [z]);
// Description:
//   Given a list of two ore more path `profiles` in 3d space, produces faces to skin a surface between
//   the profiles.  Optionally the first and last profiles can have endcaps, or the first and last profiles
//   can be connected together.  Each profile should be roughly planar, but some variation is allowed.
//   Each profile must rotate in the same clockwise direction.  If called as a function, returns a
//   [VNF structure](vnf.scad) like `[VERTICES, FACES]`.  If called as a module, creates a polyhedron
//    of the skined profiles.
//   
//   The profiles can be specified either as a list of 3d curves or they can be specified as
//   2d curves with heights given in the `z` parameter.  
//   
//   For this operation to be well-defined, we the profiles must all have the same vertex count and
//   we must assume that profiles are aligned so that vertex `i` links to vertex `i` on all polygons.  
//   Many interesting cases do not comply with this restriction.  To handle these cases, you can
//   specify various matching methods (listed below).  You can also adjust non-matching profiles
//   by either resampling them using `subdivide_path` or by duplicating vertices using
//   `repeat_entries`.  It is OK to pass a profile that has the same vertex repeated, such as
//   a square with 5 points (two of which are identical), so that it can match up to a pentagon.
//   Such a combination would create a triangular face at the location of the duplicated vertex.
//   
//   In order for skinned surfaces to look good it is usually necessary to use a fine sampling of
//   points on all of the profiles, and a large number of extra interpolated slices between the
//   profiles that you specify.  The `slices` parameter specifies the number of slices to insert
//   between each pair of profiles, either a scalar to insert the same number everywhere, or a vector
//   to insert a different number between each pair.  To resample the profiles you can specify the
//   number of samples at each profiles with the `samples` argument or you can use `refine`.  The
//   `refine` parameter specifies a multiplication factor relative to the largest profile, so
//   if refine is 10 and the largest profile has length 6 then you will get a total of 60 points,
//   or 10 points per side of the longest profile.  The default is `samples` equal to the size
//   of the largest profile, which will do nothing if all profiles are the same size.  
//   
//   Two methods are available for resampling, `"length"` and `"segment"`.  Specify them using
//   the `smethod` argument.  The length resampling method resamples proportional to length.
//   The segment method divides each segment of a profile into the same number of points.
//   A uniform division may be impossible, in which case the code computes an approximation.
//   See `subdivide_path` for more details.  
//   
//   You can choose from four methods for specifying alignment for incomensurate profiles.
//   The available methods are `"distance"`, `"tangent"`, `"uniform"` and `"align"`.
//   The "distance" method finds the global minimum distance method for connecting two
//   profiles.  This algorithm generally produces a good result when both profiles have
//   a small number of vertices.  It is computationally intensive (O(N^3)) and may be
//   slow on large inputs.  The `"tangent"` method generally produces good results when
//   connecting a discrete polygon to a convex, finely sampled curve.  It works by finding
//   a plane that passed through each edge of the polygon that is tangent to
//   the curve.  The `"uniform"` method simply connects the vertices, after resampling
//   if it is required.  The `"align"` method resamples the vertices and then reindexes
//   to find the shortest distance alignment.  This will result in the faces with the
//   smallest amount of twist.  The align algorithm has quadratic run time and can be slow
//   with large profiles.  
//   
// Arguments:
//   profiles = list of 2d or 3d profiles to be skinned.  (If 2d must also give `z`.)
//   slices = scalar or vector number of slices to insert between each pair of profiles.  Default: 8.
//   samples = resample each profile to this many points.  If `method` is distance default is undef, otherwise default is the length of longest profile.
//   refine = resample profiles to this number of points per side.  If `method` is "distance" default is 10, otherwise undef. 
//   smethod = sampling method, either "length" or "segment".  If `method` is "distance" or tangent default is "segment", otherwise "length".
//   caps = true to create endcap faces.  Default is true if closed is false.
//   method = method for aligning and connecting profiles
//   closed = set to true to connect first and last profile.  Default: false
//   z = array of height values for each profile if the profiles are 2d
module superskin(profiles, slices=8, samples, refine, method="uniform", smethod, caps, closed=false, z)
{
  	vnf_polyhedron(superskin(profiles, slices, samples, refine, method, smethod, caps, closed, z));
}        

function superskin(profiles, slices=8, samples, refine, method="uniform", smethod, caps, closed=false, z) = 
  let(
    legal_methods = ["uniform","align","distance","tangent"],
    caps = is_def(caps) ? caps :
           closed ? false : true,
    default_refine = 10,  
    maxsize = list_longest(profiles),
    samples = echo(at_sample_method=method)is_def(samples) && is_def(refine) ? undef :
              is_def(samples) ? samples :
              is_def(refine)  ? maxsize*refine :
              method=="distance" ? maxsize*default_refine :
                                   maxsize,
    
    methodok = is_list(method) || in_list(method, legal_methods),
    methodlistok = is_list(method) ? [for(i=[0:len(method)-1]) if (!in_list(method[i], legal_methods)) i] : [],
    method = is_string(method) ? replist(method, len(profiles)+ (closed?1:0)) : method,
    smethod = is_def(smethod)? smethod :
              all([for(m=method) m=="distance" || m=="tangent"]) ? "segment" : "length"
    )

  assert(methodok,str("method must be one of ",legal_methods,". Got ",method))
  assert(methodlistok==[], str("method list contains invalid method at ",methodlistok))
  assert(!closed || !caps, "Cannot make closed shape with caps")
  assert(is_def(samples),"Specify only one of `refine` and `samples`")
  assert(samples>=maxsize,str("Requested number of samples ",samples," is smaller than size of largest profile, ",maxsize))
  let(
    profile_dim=array_dim(profiles,2),
    profiles_ok = (profile_dim==2 && is_list(z) && len(z)==len(profiles)) || profile_dim==3
  )
  assert(profiles_ok,"Profiles must all be 3d or must all be 2d, with matching length z parameter.")
  assert(is_undef(z) || profile_dim==2, "Do not specify z with 3d profiles")
  assert(profile_dim==3 || len(z)==len(profiles),"Length of z does not match length of profiles.")
  let(
    profiles = profile_dim==3 ? profiles :
               [for(i=[0:len(profiles)-1]) path3d(profiles[i], z[i])],
    full_list =
      [for(i=[0:len(profiles)-(closed?1:2)])
        let(
          pair = 
            method[i]=="distance" ? minimum_distance_match(profiles[i],select(profiles,i+1)) :
            method[i]=="tangent" ? tangent_align(profiles[i],select(profiles,i+1)) :
            /*method[i]=="align" || method[i]=="uniform" ?*/
               let( p1 = subdivide_path(profiles[i],samples, method=smethod),
                    p2 = subdivide_path(select(profiles,i+1),samples, method=smethod)
               ) (method[i]=="uniform" ? [p1,p2] : [p1, reindex_polygon(p1, p2)])
          )
          each interp_and_slice(pair,slices, samples, submethod=smethod)]
  )
  skin(full_list, method="uniform");




// plist is list of polygons, N is list or value for number of slices to insert
// numpoints can be "max", "lcm" or a number
function interp_and_slice(plist, N, numpoints="max", align=false,submethod="length") =
  let(
    maxsize = list_longest(plist),
    numpoints = numpoints == "max" ? maxsize :
                numpoints == "lcm" ? lcmlist([for(p=plist) len(p)]) :
                is_num(numpoints) ? round(numpoints) : undef
  )
  assert(is_def(numpoints), "Parameter numpoints must be \"max\", \"lcm\" or a positive number")
  assert(numpoints>=maxsize, "Number of points requested is smaller than largest profile")
  let(fixpoly = [for(poly=plist) subdivide_path(poly, numpoints,method=submethod)])
  add_slices(fixpoly, N);
  



function add_slices(plist,N) =
  assert(is_num(N) || is_list(N))
  let(listok = !is_list(N) || len(N)==len(plist)-1)
  assert(listok, "Input N to add_slices is a list with the wrong length")
  let(
    count = is_num(N) ? replist(N,len(plist)-1) : N,
    slicelist = [for (i=[0:len(plist)-2])
      each [for(j = [0:count[i]]) lerp(plist[i],plist[i+1],j/(count[i]+1))]
    ]
  )
  concat(slicelist, [plist[len(plist)-1]]);



// Function: unique_count()
// Usage:
//   unique_count(arr);
// Description:
//   Returns `[sorted,counts]` where `sorted` is a sorted list of the unique items in `arr` and `counts` is a list such 
//   that `count[i]` gives the number of times that `sorted[i]` appears in `arr`.  
// Arguments:
//   arr = The list to analyze. 
function unique_count(arr) =
	assert(is_list(arr)||is_string(list))
	len(arr)==0 ? [[],[]] :
        len(arr)==1 ? [arr,[1]] :
        _unique_count(sort(arr), ulist=[], counts=[], ind=1, curtot=1);

function _unique_count(arr, ulist, counts, ind, curtot) = 
     ind == len(arr)+1 ? [ulist, counts] :
     ind==len(arr) || arr[ind] != arr[ind-1] ? _unique_count(arr,concat(ulist,[arr[ind-1]]), concat(counts,[curtot]),ind+1,1) :
     _unique_count(arr,ulist,counts,ind+1,curtot+1);

///////////////////////////////////////////////////////
//
// Given inputs of a small polygon (`small`) and a larger polygon (`big`), computes an onto mapping of
// the the vertices of `big` onto `small` that minimizes the sum of the distances between every matched
// pair of vertices.  The algorithm uses quadratic programming to calculate the optimal mapping under
// the assumption that big[0]->small[0] and big[len(big)-1] does NOT map to small[0].  We then
// rotate through all the possible indexings of `big`.  The theoretical run time is quadratic
// in len(big) and linear in len(small).  
//
// The top level function, nbest_dmatch() cycles through all the of the indexings of `big`, computes
// all of the optimal values, and chooses the overall best result.  It then interprets the result to
// produce the index mapping.  The function _qp_extract_map() threads back through the quadratic programming
// array to identify the actual mapping.
// 
// The function _qp_distance_array builds up the rows of the quadratic programming matrix with reference
// to the previous rows, where `tdist` holds the total distance for a given mapping, and `map`
// holds the information about which path was optimal for each position.
//
// The function _qp_distance_row constructs each row of the quadratic programming matrix.  Note that
// in this problem we can delete entries from `big` but we cannot insert.  This means we can only
// move to the right, or diagonally, and not down.  This in turn means that only a portion of the
// quadratic programming matrix is reachable, so we fill in the unreachable lefthand triangular portion
// with zeros and we just don't compute the righthand portion (meaning that each row of the output
// has a different length).

// This function builds up the quadratic programming distance array where each entry in the
// array gives the optimal distance for aligning the corresponding subparts of the two inputs.
// When the array is fully populated, the bottom right corner gives the minimum distance
// for matching the full input lists.  The `map` array contains a 0 when the optimal value came from
// the left (a "deletion") which means you match the next vertex in `big` with the previous, already
// used vertex of `small`, or a 1 when the optimal value came from the diagonal, which means you
// match the next vertex of `big` with the next vertex of `small`.
//
// Return value is [min_distance, map], where map is the array that is used to extract the actual
// vertex map.  
function _qp_distance_array(small, big, small_ind=0, tdist=[], map=[]) =
   let(
       N = len(small),
       M = len(big)
   )  
   small_ind == N ? [tdist[N-1][M-1], map] :
   let(
     row_results = small_ind == 0 ? [cumsum([for(i=[0:M-N+1]) norm(big[i]-small[0])]), replist(0,M-N+1)] :
                   _qp_distance_row(small, big, small_ind, small_ind, tdist, replist(0,small_ind), replist(0, small_ind))
   )
   _qp_distance_array(small, big, small_ind+1, concat(tdist, [row_results[0]]), concat(map, [row_results[1]]));


function _qp_distance_row(small,big,small_ind, big_ind, tdist, newrow, maprow) =
    big_ind == len(big)-len(small) + small_ind + 1 ? [newrow,maprow] :
    _qp_distance_row(small,big, small_ind, big_ind+1, tdist,
                concat(newrow, [norm(small[small_ind]-big[big_ind]) +
                                (small_ind==big_ind ? tdist[small_ind-1][big_ind-1] : min(tdist[small_ind-1][big_ind-1],newrow[big_ind-1]))]), 
                concat(maprow, [small_ind!=big_ind && newrow[big_ind-1] < tdist[small_ind-1][big_ind-1] ? 0 : 1]));


function _qp_extract_map(map,i,j,result) =
  is_undef(i) ? _qp_extract_map(map,len(map)-1,len(select(map,-1))-1,[]) :
  i==0 && j==0 ? concat([0], result) :
  _qp_extract_map(map,i-map[i][j],j-1,concat([i],result));


function minimum_distance_match(poly1,poly2) =
   let(
      swap = len(poly1)>len(poly2),
      big = swap ? poly1 : poly2,
      small = swap ? poly2 : poly1,
      matchres = [for(i=[0:len(big)-1]) _qp_distance_array(small,polygon_shift(big,i))],
      best = min_index(subindex(matchres,0)),
      newbig = polygon_shift(big,best),
      newsmall = repeat_entries(small,unique_count(_qp_extract_map(matchres[best][1]))[1])
      )
      swap ? [newbig, newsmall] : [newsmall,newbig];


function tangent_align(poly1, poly2) =
    let(
        swap = len(poly1)>len(poly2),
        big = swap ? poly1 : poly2,
        small = swap ? poly2 : poly1,
        curve_offset = centroid(small)-centroid(big),
        cutpts = [for(i=[0:len(small)-1]) find_one_tangent(big, select(small,i,i+1),curve_offset=curve_offset)],
        d=echo(cutpts = cutpts),
        shift = select(cutpts,-1)+1, 
        newbig = polygon_shift(big, shift),
        repeat_counts = [for(i=[0:len(small)-1]) posmod(cutpts[i]-select(cutpts,i-1),len(big))],
        newsmall = repeat_entries(small,repeat_counts)
      )
      assert(len(newsmall)==len(newbig), "Tangent alignment failed, probably because of insufficient points or a concave curve")
      swap ? [newbig, newsmall] : [newsmall, newbig];


function find_one_tangent(curve, edge, curve_offset=[0,0,0], closed=true) =
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
   zero_cross[min_index(d)];//zcross;



function plane_line_angle(plane, line) =
   let(
        vect = line[1]-line[0],
        zplane = select(plane,0,2),
        sin_angle = vect*zplane/norm(zplane)/norm(vect)
        )
   asin(constrain(sin_angle,-1,1));



// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap



