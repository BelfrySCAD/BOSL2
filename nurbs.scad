/////////////////////////////////////////////////////////////////////
// LibFile: nurbs.scad
//   B-Splines and Non-uniform Rational B-Splines (NURBS) are a way to represent smooth curves and smoothly curving
//   surfaces with a set of control points.  The curve or surface is defined by
//   the control points and a set of "knot" points.  The NURBS can be "clamped" in which case the curve passes through
//   the first and last point, or they can be "closed" in which case the first and last point are coincident.  Also possible
//   are "open" curves which do not necessarily pass through any of their control points.  Unlike Bezier curves, a NURBS
//   can have an unlimited number of control points and changes to the control points only affect the curve locally.
//   
// Includes:
//   include <BOSL2/std.scad>
//   include <BOSL2/nurbs.scad>
// FileGroup: Advanced Modeling
// FileSummary: NURBS and B-spline curves and surfaces.
//////////////////////////////////////////////////////////////////////

include<BOSL2/std.scad>

// Section: NURBS Curves

// Function: nurbs_curve()
// Synopsis: Computes one or more points on a NURBS curve.
// SynTags: Path
// Topics: NURBS Curves
// See Also: debug_nurbs()
// Usage:
//   pts = nurbs_curve(control, degree, splinesteps, [mult=], [weights=], [type=], [knots=]);
//   pts = nurbs_curve(control, degree, u=, [mult=], [weights=], [type=], [knots=]);
// Description:
//   Compute the points specified by a NURBS curve.  You specify the NURBS by supplying the control points, knots and weights.  and knots.
//   Only the control points are required.  The knots and weights default to uniform, in which case you get a uniform B-spline.
//   You can specify endpoint behavior using the `type` parameter.  The default, "clamped", gives a curve which starts and
//   ends at the first and last control points and moves in the tangent direction to the first and last control point segments.
//   If you request an "open" spline you get a curve which starts somewhere in the middle of the control points.
//   Finally, a "closed" curve is a one that starts where it ends.  Note that each of these types of curve require
//   a different number of knots.
//   .
//   The control points are the most important control over the shape
//   of the curve.  You must have at least p+1 control points for clamped and open NURBS.  Unlike a bezier, there is no maximum
//   number of control points.  A single NURBS is more like a bezier **path** than like a single bezier spline.
//   .
//   A NURBS or B-spline is a curve made from a moving average of several Bezier curves.  The knots specify when one Bezier fades
//   away to be replaced by the next one.  At generic points, the curves are differentiable, but by increasing knot multiplicity, you
//   can decrease smoothness, or even produce a sharp corner.  The knots must be an ascending sequence of values, but repeating values
//   is OK and controls the smoothness at the knots.  The easiest way to specify the knots is to take the default of uniform knots,
//   and simply set the multiplicity to create repeated knots as needed.  The total number of knots is then the sum of the multiplicity
//   vector.  Alternatively you can simply list the knots yourself.  Note that regardless of knot values, the domain of evaluation
//   for u is always the interval [0,1], and it will be scaled to give the entire valid portion of the curve you have chosen.
//   If you give both a knot vector and multiplicity then the multiplicity vector is appled to the provided knots.
//   For an open spline the number of knots must be `len(control)+p+1`.  For a clamped spline the number of knots is `len(control)-p+1`,
//   and for a closed spline you need `len(control)+1` knots.  If you are using the default uniform knots then the way to
//   ensure that you have the right number is to check that `sum(mult)` is either not set or equal to the correct value.
//   .
//   You can use this function to evaluate the NURBS at `u`, which can be a single point or a list of points.  You can also
//   use it to evaluate the NURBS over its entire domain by giving a splinesteps value.  This specifies the number of segments
//   to use between each knot and guarantees a point exactly at each knot.  This may be important if you set the knot multiplicity
//   to the degree somewhere in your curve, which creates a corner at the knot, because it guarantees a sharp corner regardless
//   of the number of points.  
// Arguments:
//   control = list of control points in any dimension
//   degree = degree of NURBS
//   splinesteps = evaluate whole spline with this number of segments between each pair of knots
//   ---
//   u = list of values or range in the interval [0,1] where the NURBS should be evaluated
//   mult = list of multiplicities of the knots.  Default: all 1
//   weights = vector whose length is the same as control giving weights at each control point.  Default: all 1
//   type = One of "clamped", "closed" or "open" to define end point handling of the spline.  Default: "clamped"
//   knots = List of knot values.  Default: uniform
// Example(2D,NoAxes): Compute some points and draw a curve and also some specific points:
//   control = [[5,0],[0,20],[33,43],[37,88],[60,62],[44,22],[77,44],[79,22],[44,3],[22,7]];
//   curve = nurbs_curve(control,2,splinesteps=16);
//   pts = nurbs_curve(control,2,u=[0.4,0.8]);
//   stroke(curve);
//   color("red")move_copies(pts) circle(r=1.5,$fn=16);
// Example(2D,NoAxes): Compute NURBS points and make a polygon
//   control = [[5,0],[0,20],[33,43],[37,88],[60,62],[44,22],[77,44],[79,22],[44,3],[22,7]];
//   curve = nurbs_curve(control,2,splinesteps=16,type="closed");
//   polygon(curve);
// Example(2D,NoAxes): Simple quadratic uniform clamped b-spline with some points computed using splinesteps.  
//   pts = [[13,43],[30,52],[49,22],[24,3]];
//   debug_nurbs(pts,2);
//   npts = nurbs_curve(pts, 2, splinesteps=3);
//   color("red")move_copies(npts) circle(r=1);
// Example(2D,NoAxes): Simple quadratic uniform clamped b-spline with some points computed using the u parameter. Note that a uniform u parameter doesn't necessarily sample the curve uniformly.  
//   pts = [[13,43],[30,52],[49,22],[24,3]];
//   debug_nurbs(pts,2);
//   npts = nurbs_curve(pts, 2, u=[0:.2:1]);
//   color("red")move_copies(npts) circle(r=1);
// Example(2D,NoAxes): Same control points, but cubic
//   pts = [[13,43],[30,52],[49,22],[24,3]];
//   debug_nurbs(pts,3);
// Example(2D,NoAxes): Same control points, quadratic and closed
//   pts = [[13,43],[30,52],[49,22],[24,3]];
//   debug_nurbs(pts,2,type="closed");
// Example(2D,NoAxes): Same control points, cubic and closed
//   pts = [[13,43],[30,52],[49,22],[24,3]];
//   debug_nurbs(pts,3,type="closed");
// Example(2D,NoAxes): Ten control points, quadratic, clamped
//   pts = [[5,0],[0,20],[33,43],[37,88],[60,62],[44,22],[77,44],[79,22],[44,3],[22,7]];
//   debug_nurbs(pts,2);
// Example(2D,NoAxes): Same thing, degree 4
//   pts = [[5,0],[0,20],[33,43],[37,88],[60,62],[44,22],[77,44],[79,22],[44,3],[22,7]];
//   debug_nurbs(pts,4);
// Example(2D,NoAxes): Same control points, degree 2, open.  Note it doesn't reach the ends
//   pts = [[5,0],[0,20],[33,43],[37,88],[60,62],[44,22],[77,44],[79,22],[44,3],[22,7]];
//   debug_nurbs(pts,2, type="open");
// Example(2D,NoAxes): Same control points, degree 4, open.  Note it starts farther from the ends
//   pts = [[5,0],[0,20],[33,43],[37,88],[60,62],[44,22],[77,44],[79,22],[44,3],[22,7]];
//   debug_nurbs(pts,4,type="open");
// Example(2D,NoAxes): Same control points, degree 2, closed
//   pts = [[5,0],[0,20],[33,43],[37,88],[60,62],[44,22],[77,44],[79,22],[44,3],[22,7]];
//   debug_nurbs(pts,2,type="closed");
// Example(2D,NoAxes): Same control points, degree 4, closed
//   pts = [[5,0],[0,20],[33,43],[37,88],[60,62],[44,22],[77,44],[79,22],[44,3],[22,7]];
//   debug_nurbs(pts,4,type="closed");
// Example(2D,Med,NoAxes): Adding weights
//   pts = [[5,0],[0,20],[33,43],[37,88],[60,62],[44,22],[77,44],[79,22],[44,3],[22,7]];
//   weights = [1,1,1,3,1,1,3,1,1,1];
//   debug_nurbs(pts,4,type="clamped",weights=weights);
// Example(2D,NoAxes): Using knot multiplicity with quadratic clamped case.  Knot count is len(control)-degree+1 = 9.  The multiplicity 2 knot creates a corner for a quadratic.
//   pts = [[5,0],[0,20],[33,43],[37,88],[60,62],[44,22],[77,44],[79,22],[44,3],[22,7]];
//   mult = [1,1,1,2,1,1,1,1];
//   debug_nurbs(pts,2,mult=mult,show_knots=true);
// Example(2D,NoAxes): Using knot multiplicity with quadratic clamped case.  Two knots of multiplicity 2 gives two corners
//   pts = [[5,0],[0,20],[33,43],[37,88],[60,62],[44,22],[77,44],[79,22],[44,3],[22,7]];
//   mult = [1,1,1,2,2,1,1];
//   debug_nurbs(pts,2,mult=mult,show_knots=true);
// Example(2D,NoAxes): Using knot multiplicity with cubic clamped case.  Knot count is now 8.  We need multiplicity equal to degree (3) to create a corner.  
//   pts = [[5,0],[0,20],[33,43],[37,88],[60,62],[44,22],[77,44],[79,22],[44,3],[22,7]];
//   mult = [1,3,1,1,1,1];
//   debug_nurbs(pts,3,mult=mult,show_knots=true);
// Example(2D,NoAxes): Using knot multiplicity with cubic closed case.  Knot count is now len(control)+1=11.  Here are three corners.  
//   pts = [[5,0],[0,20],[33,43],[37,88],[60,62],[44,22],[77,44],[79,22],[44,3],[22,7]];
//   mult = [1,3,1,3,3];
//   debug_nurbs(pts,3,mult=mult,type="closed",show_knots=true);
// Example(2D,NoAxes): Explicitly specified knots only change the quadratic clamped curve slightly.  Knot count is len(control)-degree+1 = 9.
//   pts = [[5,0],[0,20],[33,43],[37,88],[60,62],[44,22],[77,44],[79,22],[44,3],[22,7]];
//   knots = [0,1,3,5,9,13,14,19,21];
//   debug_nurbs(pts,2,knots=knots);
// Example(2D,NoAxes): Combining explicit knots with mult for the quadratic curve to add a corner
//   pts = [[5,0],[0,20],[33,43],[37,88],[60,62],[44,22],[77,44],[79,22],[44,3],[22,7]];
//   knots = [0,1,3,9,13,14,19,21];
//   mult = [1,1,1,2,1,1,1,1];
//   debug_nurbs(pts,2,knots=knots,mult=mult);
// Example(2D,NoAxes): Directly repeating a knot in the knot list to create a corner for a cubic spline
//   pts = [[5,0],[0,20],[33,43],[37,88],[60,62],[44,22],[77,44],[79,22],[44,3],[22,7]];
//   knots = [0,1,3,13,13,13,19,21];
//   debug_nurbs(pts,3,knots=knots);
// Example(2D,NoAxes): Open cubic spline with explicit knots
//   pts = [[5,0],[0,20],[33,43],[37,88],[60,62],[44,22],[77,44],[79,22],[44,3],[22,7]];
//   knots = [0,1,3,13,13,13,19,21,27,28,29,40,42,44];
//   debug_nurbs(pts,3,knots=knots,type="open");
// Example(2D,NoAxes): Closed quintic spline with explicit knots
//   pts = [[5,0],[0,20],[33,43],[37,88],[60,62],[44,22],[77,44],[79,22],[44,3],[22,7]];
//   knots = [0,1,3,13,13,13,19,21,27,28,33];
//   debug_nurbs(pts,5,knots=knots,type="closed");
// Example(2D,Med,NoAxes): Closed quintic spline with explicit knots and weights
//   pts = [[5,0],[0,20],[33,43],[37,88],[60,62],[44,22],[77,44],[79,22],[44,3],[22,7]];
//   weights = [1,2,3,4,5,6,7,6,5,4];
//   knots = [0,1,3,13,13,13,19,21,27,28,33];
//   debug_nurbs(pts,5,knots=knots,weights=weights,type="closed");
// Example(2D,NoAxes): Circular arcs are possible with NURBS.  This example gives a semi-circle
//   control = [[1,0],[1,2],[-1,2],[-1,0]];
//   w = [1,1/3,1/3,1];
//   debug_nurbs(control, 3, weights=w, width=0.1, size=.2);
// Example(2D,NoAxes): Gluing two semi-circles together gives a whole circle.  Note that this is a clamped not closed NURBS.  The interface uses a knot of multiplicity 3 where the clamped ends of the semi-circles meet. 
//   control = [[1,0],[1,2],[-1,2],[-1,0],[-1,-2],[1,-2],[1,0]];
//   w = [1,1/3,1/3,1,1/3,1/3,1];
//   debug_nurbs(control, 3, splinesteps=16,weights=w,mult=[1,3,1],width=.1,size=.2);
// Example(2D,NoAxes): Circle constructed with type="closed"
//   control = [[1,0],[1,2],[-1,2],[-1,0],[-1,-2],[1,-2]];
//   w = [1,1/3,1/3,1,1/3,1/3];
//   debug_nurbs(control, 3, splinesteps=16,weights=w,mult=[1,3,3],width=.1,size=.2,type="closed",show_knots=true);

function nurbs_curve(control,degree,splinesteps,u,  mult,weights,type="clamped",knots) =
    assert(num_defined([splinesteps,u])==1, "Must define exactly one of u and splinesteps")
    is_finite(u) ? nurbs_curve(control,degree,u=[u],mult,weights,type=type)[0]
  : assert(is_undef(splinesteps) || (is_int(splinesteps) && splinesteps>0), "splinesteps must be a positive integer")
    let(u=is_range(u) ? list(u) : u)                  
    assert(is_undef(u) || (is_vector(u) && min(u)>=0 && max(u)<=1), "u must be a list of points on the interval [0,1] or a range contained in that interval")
    is_def(weights) ? assert(is_vector(weights, len(control)), "Weights should be a vector whose length is the number of control points")
                      let(
                           dim = len(control[0]),
                           control = [for(i=idx(control)) [each control[i]*weights[i],weights[i]]],
                           curve = nurbs_curve(control,degree,u=u,splinesteps=splinesteps, mult=mult,type=type)
                      )
                      [for(pt=curve) select(pt,0,-2)/last(pt)]
  :
    let(
         uniform = is_undef(knots), 
         dum=assert(in_list(type, ["closed","open","clamped"]), str("Unknown nurbs spline type", type))
             assert(type=="closed" || len(control)>=degree+1, str(type," nurbs requires at least degree+1 control points"))
             assert(is_undef(mult) || is_vector(mult), "mult must be a vector"),
         badmult = is_undef(mult) ? []
                 : [for(i=idx(mult)) if (!(
                                            is_int(mult[i])
                                              && mult[i]>0
                                              && (mult[i]<=degree
                                                   || (type!="closed"
                                                       && mult[i]==degree+1
                                                       && (i==0 || i==len(mult)-1)
                                                      )
                                                 )
                                           )) i],
         dummy0 = assert(badmult==[], str("mult vector should contain positive integers no larger than the degree, except at ends of open splines, ",
                                          "where degree+1 is allowed.  The mult vector has bad values at indices: ",badmult))
                  assert(is_undef(knots) || is_undef(mult) || len(mult)==len(knots), "If both mult and knots are given they must be vectors of the same length")
                  assert(is_undef(mult) || type!="clamped" || sum(mult)==len(control)-degree+1,
                         str("For ",type," spline knot count (sum of multiplicity vector) must be ",len(control)-degree+1," but is instead ",mult?sum(mult):0))
                  assert(is_undef(mult) || type!="closed" || sum(mult)==len(control)+1,
                         str("For closed spline knot count (sum of multiplicity vector) must be ",len(control)+1," but is instead ",mult?sum(mult):0))
                  assert(is_undef(mult) || type!="open" || sum(mult)==len(control)+degree+1,
                         str("For closed spline knot count (sum of multiplicity vector) must be ",len(control)+degree+1," but is instead ",mult?sum(mult):0)),
         control = type=="open" ? control
                 : type=="clamped" ? control  //concat(repeat(control[0], degree),control, repeat(last(control),degree))
                 : /*type=="closed"*/ concat(control, select(control,count(degree))),
         mult = !uniform ? mult
              : type=="clamped" ? assert(is_undef(mult) || mult[0]==1 && last(mult)==1,"For clamped b-splines, first and last multiplicity must be 1")
                                  [degree+1,each slice(default(mult, repeat(1,len(control)-degree+1)),1,-2),degree+1]
              : is_undef(mult) ? repeat(1,len(control)+degree+1)
              : type=="open" ? mult
              : /* type=="closed" */
                let(   // Closed spline requires that we identify first and last knots and then step at same
                       // interval spacing periodically through the knot vector.  This means we pick up the first
                       // multiplicity minus 1 and have to add it to the last multiplicity.  
                     lastmult = last(mult)+mult[0]-1,
                     dummy=assert(lastmult<=degree, "For closed spline, first and last knot multiplicity cannot total more than the degree+1"),
                     adjlast = [
                                 each select(mult,0,-2),
                                 lastmult
                               ]
                )
                _extend_knot_mult(adjlast,1,len(control)+degree+1),
         knot = uniform && is_undef(mult) ? lerpn(0,1,len(control)+degree+1)
              : uniform ? [for(i=idx(mult)) each repeat(i/(len(mult)-1),mult[i])]
              : let(
                    xknots = is_undef(mult)? knots
                           : assert(len(mult) == len(knots), "If knot vector and mult vector must be the same length")
                             [for(i=idx(mult)) each repeat(knots[i], mult[i])]
                )
                type=="open" ? assert(len(xknots)==len(control)+degree+1, str("For open spline, knot vector with multiplicity must have length ",
                                                                        len(control)+degree+1," but has length ", len(xknots)))
                               xknots
              : type=="clamped" ? assert(len(xknots) == len(control)+1-degree, str("For clamped spline of degree ",degree,", knot vector with multiplicity must have length ",
                                                                        len(control)+1-degree," but has length ", len(xknots)))
                                  assert(xknots[0]!=xknots[1] && last(xknots)!=select(xknots,-2),
                                         "For clamped splint, first and last knots cannot repeat (must have multiplicity one")
                                  concat(repeat(xknots[0],degree), xknots, repeat(last(xknots),degree))
              : /*type=="closed"*/ assert(len(xknots) == len(control)+1-degree,  str("For closed spline, knot vector (including multiplicity) must have length ",
                                                                        len(control)+1-degree," but has length ", len(xknots),control))
                                 let(gmult=_calc_mult(xknots))
                                 assert(gmult[0]+last(gmult)<=degree+1, "For closed spline, first and last knot multiplicity together cannot total more than the degree+1")
                                 _extend_knot_vector(xknots,0,len(control)+degree+1),
         bound = type=="clamped" ? undef
               : [knot[degree], knot[len(control)]],
         adjusted_u = !is_undef(splinesteps) ?
                         [for(i=[degree:1:len(control)-1])
                           each 
                             if (knot[i]!=knot[i+1])
                               lerpn(knot[i],knot[i+1],splinesteps, endpoint=false),
                          if (type!="closed") knot[len(control)]
                         ]
                    : is_undef(bound) ? u
                    : add_scalar((bound[1]-bound[0])*u,bound[0])
    )
    uniform?
           let(
               msum = cumsum(mult)
           )
           [for(uval=adjusted_u)
              let(
                  mind = floor(uval*(len(mult)-1)),
                  knotidxR=msum[mind]-1,
                  knotidx = knotidxR<len(control) ? knotidxR : knotidxR - mult[mind]
              )
              _nurbs_pt(knot,select(control,knotidx-degree,knotidx),uval,1,degree,knotidx)
           ]
       : let(
           kmult = _calc_mult(knot),
           knotidx =
             [for(
                  kind = kmult[0]-1,
                  uind=0,
                  kmultind=1,
                  output=undef,
                  done=false
                     ;
                  !done
                     ;
                  output = (uind<len(adjusted_u) && approx(adjusted_u[uind],knot[kind]) && kind>kmult[0]-1 && ((kmultind>=len(kmult)-1 || kind+kmult[kmultind]>=len(control))))
                                            ?kind-kmult[kmultind-1]
                         : (uind<len(adjusted_u) && adjusted_u[uind]>=knot[kind] && adjusted_u[uind]>=knot[kind] && adjusted_u[uind]<knot[kind+kmult[kmultind]]) ? kind
                         : undef,
                  done =  uind==len(adjusted_u), 
                  uind = is_def(output) ? uind+1 : uind,
                  inc_k = uind<len(adjusted_u) && adjusted_u[uind]>=knot[kind+kmult[kmultind]],
                  kind = inc_k ? kind+kmult[kmultind] : kind,
                  kmultind = inc_k ? kmultind+1 : kmultind
              )
              if (is_def(output)) output]
         )
         [for(i=idx(adjusted_u))
            _nurbs_pt(knot,slice(control, knotidx[i]-degree,knotidx[i]), adjusted_u[i], 1, degree, knotidx[i])
         ];
       

function _nurbs_pt(knot, control, u, r, p, k) = 
    r>p ? control[0]
  :                          
    let( 
         ctrl_new = [for(i=[k-p+r:1:k])
                       let(
                            alpha = (u-knot[i]) / (knot[i+p-r+1]-knot[i])
                       )
                       (1-alpha) * control[i-1-(k-p)-r+1] + alpha*control[i-(k-p)-r+1]
                    ]
    )
    _nurbs_pt(knot,ctrl_new,u,r+1,p,k);


function _extend_knot_mult(mult, next, len) =
    let(total = sum(mult))
    total == len ? mult
  : total>len ? [ each select(mult,0,-2), last(mult)-(total-len) ]
  : _extend_knot_mult([each mult,mult[next]], next+1, len);

function _extend_knot_vector(knots,next,len) =
    len(knots)==len ? knots
  : _extend_knot_vector([each knots, last(knots)+knots[next+1]-knots[next]], next+1, len);


function _calc_mult(knots) =
  let(
      ind=[ 0,
            for(i=[1:len(knots)-1])
              if (knots[i]!=knots[i-1]) i,
            len(knots)
          ]
  )
  deltas(ind);



// Module: debug_nurbs()
// Synopsis: Shows a NURBS curve and its control points, knots and weights
// SynTags: Geom
// Topics: NURBS, Debugging
// See Also: nurbs_curve()
// Usage:
//   debug_nurbs(control, degree, [width], [splinesteps=], [type=], [mult=], [knots=], [size=], [show_weights=], [show_knots=], [show_idx=]);
// Description:
//   Displays a 2D or 3D NURBS and the associated control points to help debug NURBS curves.  You can display the
//   control point indices and weights, and can also display the knot points.  
// Arguments:
//   control = control points for NURBS
//   degree = degree of NURBS
//   splinesteps = number of segments between each pair of knots.  Default: 16
//   width = width of the line.  Default: 1
//   size = size of text annotations.  Default: 3 times the width
//   mult = multiplicity vector for NURBS
//   weights = weight vector for NURBS
//   type = NURBS type, one of "clamped", "open" or "closed".  Default: "clamped"
//   show_index = if true then display index of each control point vertex.  Default: true
//   show_weights = if true then display any non-unity weights.  Default: true if weights vector is supplied, false otherwise
//   show_knots = If true then show the knots on the spline curve.  Default: false
// Example(2D,Med,NoAxes): The default display includes the control point polygon with its vertices numbered, and the NURBS curve
//   pts = [[5,0],[0,20],[33,43],[37,88],[60,62],[44,22],[77,44],[79,22],[44,3],[22,7]];
//   debug_nurbs(pts,4,type="closed");
// Example(2D,Med,NoAxes): If you want to see the knots set `show_knots=true`:
//   pts = [[5,0],[0,20],[33,43],[37,88],[60,62],[44,22],[77,44],[79,22],[44,3],[22,7]];
//   debug_nurbs(pts,4,type="clamped",show_knots=true);
// Example(2D,Med,NoAxes): Non-unity weights are displayed if you give a weight vector
//   pts = [[5,0],[0,20],[33,43],[37,88],[60,62],[44,22],[77,44],[79,22],[44,3],[22,7]];
//   weights = [1,1,1,7,1,1,7,1,1,1];
//   debug_nurbs(pts,4,type="closed",weights=weights);

module debug_nurbs(control,degree,splinesteps=16,width=1, size, mult,weights,type="clamped",knots, show_weights, show_knots=false, show_index=true)
{  
  $fn=8;
  size = default(size, 3*width);
  show_weights = default(show_weights, is_def(weights));
  N=len(control);
  twodim = len(control[0])==2;
  curve = nurbs_curve(control=control,degree=degree,splinesteps=splinesteps, mult=mult,weights=weights, type=type, knots=knots);
  stroke(curve, width=width, closed=type=="closed");//, color="green");
  stroke(control, width=width/2, color="lightblue", closed=type=="closed");
  if (show_knots){
    knotpts = nurbs_curve(control=control, degree=degree, splinesteps=1, mult=mult, weights=weights, type=type, knots=knots);
    echo(knotpts);
    color([1,.5,1])
      move_copies(knotpts)
        if (twodim)circle(r=width);
        else sphere(r=width);
  }
  color("blue")
    if (show_index)
      move_copies(control){
        let(label = str($idx),
            anch = show_weights && is_def(weights[$idx]) && weights[$idx]!=1 ? FWD : CENTER)
          if (twodim) text(text=label, size=size, anchor=anch);
          else rot($vpr) text3d(text=label, size=size, anchor=anch);
    }
  color("blue")
    if ( show_weights)
      move_copies(control){
        if(is_def(weights[$idx]) && weights[$idx]!=1)
          let(label = str("w=",weights[$idx]), 
              anch = show_index ? BACK : CENTER
              )
          if (twodim) fwd(size/2*0)text(text=label, size=size, anchor=anch);
          else rot($vpr) text3d(text=label, size=size, anchor=anch);
    }
  
}  


// Section: NURBS Surfaces


// Function: is_nurbs_patch()
// Synopsis: Returns true if the given item looks like a NURBS patch.
// Topics: NURBS Patches, Type Checking
// Usage:
//   bool = is_nurbs_patch(x);
// Description:
//   Returns true if the given item looks like a NURBS patch. (a 2D array of 3D points.)
// Arguments:
//   x = The value to check the type of.
function is_nurbs_patch(x) =
    is_list(x) && is_list(x[0]) && is_vector(x[0][0]) && len(x[0]) == len(x[len(x)-1]);  



// Function: nurbs_patch_points()
// Synopsis: Computes specifies point(s) on a NURBS surface patch
// Topics: NURBS Patches
// See Also: nurbs_vnf(), nurbs_curve()
// Usage:
//   pointgrid = nurbs_patch_points(patch, degree, [splinesteps], [u=], [v=], [weights=], [type=], [mult=], [knots=]);
// Description:
//   Sample a NURBS patch on a point set.  If you give splinesteps then it will sampled uniformly in the spline
//   parameter between the knots, ensuring that a sample appears at every knot.  If you instead give u and v then
//   the values at those points in parameter space will be returned.  The various NURBS parameters can all be
//   single values, if the NURBS has the same parameters in both directions, or pairs listing the value for the
//   two directions.  
// Arguments:
//   patch = rectangular list of control points in any dimension
//   degree = a scalar or 2-vector giving the degree of the NURBS in the two directions
//   splinesteps = a scalar or 2-vector giving the number of segments between each knot in the two directions
//   ---
//   u = evaluation points in the u direction of the patch
//   v = evaluation points in the v direction of the patch
//   mult = a single list or pair of lists giving the knot multiplicity in the two directions. Default: all 1
//   knots = a single list of pair of lists giving the knot vector in each of the two directions.  Default: uniform
//   weights = a single list or pair of lists giving the weight at each control point in the patch.  Default: all 1
//   type = a single string or pair of strings giving the NURBS type, where each entry is one of "clamped", "open" or "closed".  Default: "clamped"
// Example(3D,NoScale): Computing points on a patch using ranges
//   patch = [
//       [[-50, 50,  0], [-16, 50,  20], [ 16, 50,  20], [50, 50,  0]],
//       [[-50, 16, 20], [-16, 16,  40], [ 16, 16,  40], [50, 16, 20]],
//       [[-50,-16, 20], [-16,-16,  40], [ 16,-16,  40], [50,-16, 20]],
//       [[-50,-50,  0], [-16,-50,  20], [ 16,-50,  20], [50,-50,  0]],
//   ];
//   pts = nurbs_patch_points(patch, 3, u=[0:.1:1], v=[0:.3:1]);
//   move_copies(flatten(pts)) sphere(r=2,$fn=16);
// Example(3D,NoScale): Computing points using splinesteps
//   patch = [
//       [[-50, 50,  0], [-16, 50,  20], [ 16, 50,  20], [50, 50,  0]],
//       [[-50, 16, 20], [-16, 16,  40], [ 16, 16,  40], [50, 16, 20]],
//       [[-50,-16, 20], [-16,-16,  40], [ 16,-16,  40], [50,-16, 20]],
//       [[-50,-50,  0], [-16,-50,  20], [ 16,-50,  20], [50,-50,  0]],
//   ];
//   pts = nurbs_patch_points(patch, 3, splinesteps=5);
//   move_copies(flatten(pts)) sphere(r=2,$fn=16);

function nurbs_patch_points(patch, degree, splinesteps, u, v, weights, type=["clamped","clamped"], mult=[undef,undef], knots=[undef,undef]) =
    assert(is_undef(splinesteps) || !any_defined([u,v]), "Cannot combine splinesteps with u and v")
    is_def(weights) ?
       assert(is_matrix(weights,len(patch),len(patch[0])), "The weights parameter must be a matrix that matches the size of the patch array")
       let(
            patch = [for(i=idx(patch)) [for (j=idx(patch[0])) [each patch[i][j]*weights[i][j], weights[i][j]]]],
            pts = nurbs_patch_points(patch=patch, degree=degree, splinesteps=splinesteps, u=u, v=v, type=type, mult=mult, knots=knots)
       )
       [for(row=pts) [for (pt=row) select(pt,0,-2)/last(pt)]]
   :
    assert(is_undef(u) || is_range(u) || is_vector(u) || is_finite(u), "Input u is invalid")
    assert(is_undef(v) || is_range(v) || is_vector(v) || is_finite(v), "Input v is invalid")
    assert(num_defined([u,v])!=1, "Must define both u and v (when using)")
    let(
        u=is_range(u) ? list(u) : u,
        v=is_range(v) ? list(v) : v,
        degree = force_list(degree,2), 
        type = force_list(type,2),
        splinesteps = is_undef(splinesteps) ? [undef,undef] : force_list(splinesteps,2),
        mult = is_vector(mult) || is_undef(mult) ? [mult,mult]
             : assert((is_undef(mult[0]) || is_vector(mult[0])) && (is_undef(mult[1]) || is_vector(mult[1])), "mult must be a vector or list of two vectors")
               mult,
        knots = is_vector(knots) || is_undef(knots) ? [knots,knots]
              : assert((is_undef(knots[0]) || is_vector(knots[0])) && (is_undef(knots[1]) || is_vector(knots[1])), "knots must be a vector or list of two vectors")
                knots
    )
    is_num(u) && is_num(v)? nurbs_curve([for (control=patch) nurbs_curve(control, degree[1], u=v, type=type[1], mult=mult[1], knots=knots[1])],
                                        degree[0], u=u, type=type[0], mult=mult[0], knots=knots[0])
  : is_num(u) ? nurbs_patch_points(patch, degree, u=[u], v=v, knots=knots, mult=mult, type=type)[0]
  : is_num(v) ? column(nurbs_patch_points(patch, degree, u=u, v=[v], knots=knots, mult=mult, type=type),0)
  :                                      
    let(
        
        vsplines = [for (i = idx(patch[0])) nurbs_curve(column(patch,i), degree[0], splinesteps=splinesteps[0],u=u, type=type[0],mult=mult[0],knots=knots[0])]
    )
    [for (i = idx(vsplines[0])) nurbs_curve(column(vsplines,i), degree[1], splinesteps=splinesteps[1], u=v, mult=mult[1], knots=knots[1], type=type[1])];

// Function: nurbs_vnf()
// Synopsis: Generates a (possibly non-manifold) VNF for a single NURBS surface patch.
// SynTags: VNF
// Topics: NURBS Patches
// See Also: nurbs_patch_points()
// Usage:
//   vnf = nurbs_vnf(patch, degree, [splinesteps], [mult=], [knots=], [weights=], [type=], [style=]);
// Description:
//   Compute a (possibly non-manifold) VNF for a NURBS.  The input patch must be an array of control points.  If weights is given it
//   must be an array of weights that matches the size of the control points.  The style parameter
//   gives the {{vnf_vertex_array()}} style to use.  The other parameters may specify the NURBS parameters in the two directions
//   by giving a single value, which applies to both directions, or a list of two values to specify different values in each direction.
//   You can specify undef for for a direction to keep the default, such as `mult=[undef,v_multiplicity]`.
// Arguments:
//   patch = rectangular list of control points in any dimension
//   degree = a scalar or 2-vector giving the degree of the NURBS in the two directions
//   splinesteps = a scalar or 2-vector giving the number of segments between each knot in the two directions
//   ---
//   mult = a single list or pair of lists giving the knot multiplicity in the two directions.  Default: all 1
//   knots = a single list of pair of lists giving the knot vector in each of the two directions.  Default: uniform
//   weights = a single list or pair of lists giving the weight at each control point in the.  Default: all 1
//   type = a single string or pair of strings giving the NURBS type, where each entry is one of "clamped", "open" or "closed".  Default: "clamped"
//   style = {{vnf_vertex_array ()}} style to use for triangulating the surface.  Default: "default"
// Example(3D): Quadratic B-spline surface
//   patch = [
//       [[-50, 50,  0], [-16, 50,  20], [ 16, 50,  20], [50, 50,  0]],
//       [[-50, 16, 20], [-16, 16,  40], [ 16, 16,  40], [50, 16, 20]],
//       [[-50,-16, 20], [-16,-16,  40], [ 16,-16,  40], [50,-16, 20]],
//       [[-50,-50,  0], [-16,-50,  20], [ 16,-50,  20], [50,-50,  0]],
//   ];
//   vnf = nurbs_vnf(patch, 2);
//   vnf_polyhedron(vnf);
// Example(3D): Cubic B-spline surface
//   patch = [
//       [[-50, 50,  0], [-16, 50,  20], [ 16, 50,  20], [50, 50,  0]],
//       [[-50, 16, 20], [-16, 16,  40], [ 16, 16,  40], [50, 16, 20]],
//       [[-50,-16, 20], [-16,-16,  40], [ 16,-16,  40], [50,-16, 20]],
//       [[-50,-50,  0], [-16,-50,  20], [ 16,-50,  20], [50,-50,  0]],
//   ];
//   vnf = nurbs_vnf(patch, 3);
//   vnf_polyhedron(vnf); 
// Example(3D): Cubic B-spline surface, closed in one direction
//   patch = [
//       [[-50, 50,  0], [-16, 50,  20], [ 16, 50,  20], [50, 50,  0]],
//       [[-50, 16, 20], [-16, 16,  40], [ 16, 16,  40], [50, 16, 20]],
//       [[-50,-16, 20], [-16,-16,  40], [ 16,-16,  40], [50,-16, 20]],
//       [[-50,-50,  0], [-16,-50,  20], [ 16,-50,  20], [50,-50,  0]],
//   ];
//   vnf = nurbs_vnf(patch, 3, type=["closed","clamped"]);
//   vnf_polyhedron(vnf); 
// Example(3D): B-spline surface cubic in one direction, quadratic in the other
//   patch = [
//       [[-50, 50,  0], [-16, 50,  20], [ 16, 50,  20], [50, 50,  0]],
//       [[-50, 16, 20], [-16, 16,  40], [ 16, 16,  40], [50, 16, 20]],
//       [[-50,-16, 20], [-16,-16,  40], [ 16,-16,  40], [50,-16, 20]],
//       [[-50,-50,  0], [-16,-50,  20], [ 16,-50,  20], [50,-50,  0]],
//   ];
//   vnf = nurbs_vnf(patch, [3,2],type=["closed","clamped"]);
//   vnf_polyhedron(vnf); 
// Example(3D): The sphere can be represented using NURBS
//   patch = [
//             [[0,0,1], [0,0,1], [0,0,1],  [0,0,1],  [0,0,1],    [0,0,1],  [0,0,1]],
//             [[2,0,1], [2,4,1], [-2,4,1], [-2,0,1], [-2,-4,1],  [2,-4,1], [2,0,1]],
//             [[2,0,-1],[2,4,-1],[-2,4,-1],[-2,0,-1],[-2,-4,-1], [2,-4,-1],[2,0,-1]],
//             [[0,0,-1],[0,0,-1],[0,0,-1], [0,0,-1], [0,0,-1],   [0,0,-1], [0,0,-1]]
//           ];
//   weights = [
//              [9,3,3,9,3,3,9],
//              [3,1,1,3,1,1,3],
//              [3,1,1,3,1,1,3],
//              [9,3,3,9,3,3,9],
//             ]/9;
//   vknots = [0, 1/2, 1/2, 1/2, 1];               
//   vnf = nurbs_vnf(patch, 3,weights=weights, knots=[undef,vknots]);
//   vnf_polyhedron(vnf);    
function nurbs_vnf(patch, degree, splinesteps=16, weights, type="clamped", mult, knots, style="default") =
   assert(is_nurbs_patch(patch),"Input patch is not a rectangular aray of points")
   let(
        pts = nurbs_patch_points(patch=patch, degree=degree, splinesteps=splinesteps, type=type, mult=mult, knots=knots, weights=weights)
   )
   vnf_vertex_array(pts, style=style, row_wrap=type[0]=="closed", col_wrap=type[1]=="closed");

