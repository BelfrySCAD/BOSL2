//////////////////////////////////////////////////////////////////////
// LibFile: shapes2d.scad
//   This file includes redefinitions of the core modules to
//   work with attachment, and functional forms of those modules
//   that produce paths.  You can create regular polygons
//   with optional rounded corners and alignment features not
//   available with circle().  The file also provides teardrop2d,
//   which is useful for 3D printable holes.  
//   Many of the commands have module forms that produce geometry and
//   function forms that produce a path. 
// Includes:
//   include <BOSL2/std.scad>
// FileGroup: Basic Modeling
// FileSummary: Attachable circles, squares, polygons, teardrop.  Can make geometry or paths.
// FileFootnotes: STD=Included in std.scad
//////////////////////////////////////////////////////////////////////

use <builtins.scad>


// Section: 2D Primitives

// Function&Module: square()
// Synopsis: Creates a 2D square or rectangle.
// SynTags: Geom, Path, Ext
// Topics: Shapes (2D), Path Generators (2D)
// See Also: rect()
// Usage: As a Module
//   square(size, [center], ...);
// Usage: With Attachments
//   square(size, [center], ...) [ATTACHMENTS];
// Usage: As a Function
//   path = square(size, [center], ...);
// Description:
//   When called as the built-in module, creates a 2D square or rectangle of the given size.
//   When called as a function, returns a 2D path/list of points for a square/rectangle of the given size.
// Arguments:
//   size = The size of the square to create.  If given as a scalar, both X and Y will be the same size.
//   center = If given and true, overrides `anchor` to be `CENTER`.  If given and false, overrides `anchor` to be `FRONT+LEFT`.
//   ---
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
// Example(2D):
//   square(40);
// Example(2D): Centered
//   square([40,30], center=true);
// Example(2D): Called as Function
//   path = square([40,30], anchor=FRONT, spin=30);
//   stroke(path, closed=true);
//   move_copies(path) color("blue") circle(d=2,$fn=8);
function square(size=1, center, anchor, spin=0) =
    let(
        anchor = get_anchor(anchor, center, [-1,-1], [-1,-1]),
        size = is_num(size)? [size,size] : point2d(size)
    )
    assert(all_positive(size), "All components of size must be positive.")
    let(
        path = [
            [ size.x,-size.y],
            [-size.x,-size.y],
            [-size.x, size.y],
            [ size.x, size.y],
        ] / 2
    ) reorient(anchor,spin, two_d=true, size=size, p=path);


module square(size=1, center, anchor, spin) {
    anchor = get_anchor(anchor, center, [-1,-1], [-1,-1]);
    rsize = is_num(size)? [size,size] : point2d(size);
    size = [for (c = rsize) max(0,c)];
    attachable(anchor,spin, two_d=true, size=size) {
        if (all_positive(size))
            _square(size, center=true);
        children();
    }
}



// Function&Module: rect()
// Synopsis: Creates a 2d rectangle with optional corner rounding.
// SynTags: Geom, Path
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable
// See Also: square()
// Usage: As Module
//   rect(size, [rounding], [chamfer], ...) [ATTACHMENTS];
// Usage: As Function
//   path = rect(size, [rounding], [chamfer], ...);
// Description:
//   When called as a module, creates a 2D rectangle of the given size, with optional rounding or chamfering.
//   When called as a function, returns a 2D path/list of points for a square/rectangle of the given size.
// Arguments:
//   size = The size of the rectangle to create.  If given as a scalar, both X and Y will be the same size.
//   ---
//   rounding = The rounding radius for the corners.  If negative, produces external roundover spikes on the X axis. If given as a list of four numbers, gives individual radii for each corner, in the order [X+Y+,X-Y+,X-Y-,X+Y-]. Default: 0 (no rounding)
//   chamfer = The chamfer size for the corners.  If negative, produces external chamfer spikes on the X axis. If given as a list of four numbers, gives individual chamfers for each corner, in the order [X+Y+,X-Y+,X-Y-,X+Y-].  Default: 0 (no chamfer)
//   atype = The type of anchoring to use with `anchor=`.  Valid opptions are "box" and "perim".  This lets you choose between putting anchors on the rounded or chamfered perimeter, or on the square bounding box of the shape. Default: "box"
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
// Anchor Types:
//   box = Anchor is with respect to the rectangular bounding box of the shape.
//   perim = Anchors are placed along the rounded or chamfered perimeter of the shape.
// Example(2D):
//   rect(40);
// Example(2D): Anchored
//   rect([40,30], anchor=FRONT);
// Example(2D): Spun
//   rect([40,30], anchor=FRONT, spin=30);
// Example(2D): Chamferred Rect
//   rect([40,30], chamfer=5);
// Example(2D): Rounded Rect
//   rect([40,30], rounding=5);
// Example(2D): Negative-Chamferred Rect
//   rect([40,30], chamfer=-5);
// Example(2D): Negative-Rounded Rect
//   rect([40,30], rounding=-5);
// Example(2D): Default "box" Anchors
//   color("red") rect([40,30]);
//   rect([40,30], rounding=10)
//       show_anchors();
// Example(2D): "perim" Anchors
//   rect([40,30], rounding=10, atype="perim")
//       show_anchors();
// Example(2D): "perim" Anchors
//   rect([40,30], rounding=[-10,-8,-3,-7], atype="perim")
//       show_anchors();
// Example(2D): Mixed Chamferring and Rounding
//   rect([40,30],rounding=[5,0,10,0],chamfer=[0,8,0,15],$fa=1,$fs=1);
// Example(2D): Called as Function
//   path = rect([40,30], chamfer=5, anchor=FRONT, spin=30);
//   stroke(path, closed=true);
//   move_copies(path) color("blue") circle(d=2,$fn=8);
module rect(size=1, rounding=0, atype="box", chamfer=0, anchor=CENTER, spin=0) {
    errchk = assert(in_list(atype, ["box", "perim"]));
    size = [for (c = force_list(size,2)) max(0,c)];
    if (!all_positive(size)) {
        attachable(anchor,spin, two_d=true, size=size) {
            union();
            children();
        }
    } else if (rounding==0 && chamfer==0) {
        attachable(anchor, spin, two_d=true, size=size) {
            square(size, center=true);
            children();
        }
    } else {
        pts_over = rect(size=size, rounding=rounding, chamfer=chamfer, atype=atype, _return_override=true);
        pts = pts_over[0];
        override = pts_over[1];
        attachable(anchor, spin, two_d=true, size=size,override=override) {
            polygon(pts);
            children();
        }
    }
}



function rect(size=1, rounding=0, chamfer=0, atype="box", anchor=CENTER, spin=0, _return_override) =
    assert(is_num(size)     || is_vector(size,2))
    assert(is_num(chamfer)  || is_vector(chamfer,4))
    assert(is_num(rounding) || is_vector(rounding,4))
    assert(in_list(atype, ["box", "perim"]))
    let(
        anchor=_force_anchor_2d(anchor),
        size = [for (c = force_list(size,2)) max(0,c)],
        chamfer = force_list(chamfer,4), 
        rounding = force_list(rounding,4)
    )
    assert(all_nonnegative(size), "All components of size must be >=0")
    all_zero(concat(chamfer,rounding),0) ?
        let(
             path = [
                 [ size.x/2, -size.y/2],
                 [-size.x/2, -size.y/2],
                 [-size.x/2,  size.y/2],
                 [ size.x/2,  size.y/2],
             ]
        )
        rot(spin, p=move(-v_mul(anchor,size/2), p=path))
    :
    assert(all_zero(v_mul(chamfer,rounding),0), "Cannot specify chamfer and rounding at the same corner")
    let(
        quadorder = [3,2,1,0],
        quadpos = [[1,1],[-1,1],[-1,-1],[1,-1]],
        eps = 1e-9,
        insets = [for (i=[0:3]) abs(chamfer[i])>=eps? chamfer[i] : abs(rounding[i])>=eps? rounding[i] : 0],
        insets_x = max(insets[0]+insets[1],insets[2]+insets[3]),
        insets_y = max(insets[0]+insets[3],insets[1]+insets[2])
    )
    assert(insets_x <= size.x, "Requested roundings and/or chamfers exceed the rect width.")
    assert(insets_y <= size.y, "Requested roundings and/or chamfers exceed the rect height.")
    let(
        corners = [
            for(i = [0:3])
            let(
                quad = quadorder[i],
                qinset = insets[quad],
                qpos = quadpos[quad],
                qchamf = chamfer[quad],
                qround = rounding[quad],
                cverts = quant(segs(abs(qinset)),4)/4,
                step = 90/cverts,
                cp = v_mul(size/2-[qinset,abs(qinset)], qpos),
                qpts = abs(qchamf) >= eps? [[0,abs(qinset)], [qinset,0]] :
                    abs(qround) >= eps? [for (j=[0:1:cverts]) let(a=90-j*step) v_mul(polar_to_xy(abs(qinset),a),[sign(qinset),1])] :
                    [[0,0]],
                qfpts = [for (p=qpts) v_mul(p,qpos)],
                qrpts = qpos.x*qpos.y < 0? reverse(qfpts) : qfpts,
                cornerpt = atype=="box" || (qround==0 && qchamf==0) ? undef
                         : qround<0 || qchamf<0 ? [[0,-qpos.y*min(qround,qchamf)]]
                         : [for(seg=pair(qrpts)) let(isect=line_intersection(seg, [[0,0],qpos],SEGMENT,LINE)) if (is_def(isect) && isect!=seg[0]) isect]
              )
            assert(is_undef(cornerpt) || len(cornerpt)==1,"Cannot find corner point to anchor")
            [move(cp, p=qrpts), is_undef(cornerpt)? undef : move(cp,p=cornerpt[0])]
        ],
        path = flatten(column(corners,0)),
        override = [for(i=[0:3])
                      let(quad=quadorder[i])
                      if (is_def(corners[i][1])) [quadpos[quad], [corners[i][1], min(chamfer[quad],rounding[quad])<0 ? [quadpos[quad].x,0] : undef]]]
      ) _return_override ? [reorient(anchor,spin, two_d=true, size=size, p=path, override=override), override]
                       : reorient(anchor,spin, two_d=true, size=size, p=path, override=override);


// Function&Module: circle()
// Synopsis: Creates the approximation of a circle.
// SynTags: Geom, Path, Ext
// Topics: Shapes (2D), Path Generators (2D)
// See Also: ellipse(), circle_2tangents(), circle_3points()
// Usage: As a Module
//   circle(r|d=, ...) [ATTACHMENTS];
//   circle(points=) [ATTACHMENTS];
//   circle(r|d=, corner=) [ATTACHMENTS];
// Usage: As a Function
//   path = circle(r|d=, ...);
//   path = circle(points=);
//   path = circle(r|d=, corner=);
// Description:
//   When called as the built-in module, creates a 2D polygon that approximates a circle of the given size.
//   When called as a function, returns a 2D list of points (path) for a polygon that approximates a circle of the given size.
//   If `corner=` is given three 2D points, centers the circle so that it will be tangent to both segments of the path, on the inside corner.
//   If `points=` is given three 2D points, centers and sizes the circle so that it passes through all three points.
// Arguments:
//   r = The radius of the circle to create.
//   d = The diameter of the circle to create.
//   ---
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
// Example(2D): By Radius
//   circle(r=25);
// Example(2D): By Diameter
//   circle(d=50);
// Example(2D): Fit to Three Points
//   pts = [[50,25], [25,-25], [-10,0]];
//   circle(points=pts);
//   color("red") move_copies(pts) circle();
// Example(2D): Fit Tangent to Inside Corner of Two Segments
//   path = [[50,25], [-10,0], [25,-25]];
//   circle(corner=path, r=15);
//   color("red") stroke(path);
// Example(2D): Called as Function
//   path = circle(d=50, anchor=FRONT, spin=45);
//   stroke(path);
function circle(r, d, points, corner, anchor=CENTER, spin=0) =
    assert(is_undef(corner) || (is_path(corner,[2]) && len(corner) == 3))
    assert(is_undef(points) || is_undef(corner), "Cannot specify both points and corner.")
    let(
        data = is_def(points)?
                assert(is_path(points,[2]) && len(points) == 3)
                assert(is_undef(corner), "Cannot specify corner= when points= is given.")
                assert(is_undef(r) && is_undef(d), "Cannot specify r= or d= when points= is given.")
                let( c = circle_3points(points) )
                assert(!is_undef(c[0]), "Points cannot be collinear.")
                let( cp = c[0], r = c[1]  )
                [cp, r] :
            is_def(corner)?
                assert(is_path(corner,[2]) && len(corner) == 3)
                assert(is_undef(points), "Cannot specify points= when corner= is given.")
                let(
                    r = get_radius(r=r, d=d, dflt=1),
                    c = circle_2tangents(r=r, pt1=corner[0], pt2=corner[1], pt3=corner[2])
                )
                assert(c!=undef, "Corner path cannot be collinear.")
                let( cp = c[0] )
                [cp, r] :
            let(
                cp = [0, 0],
                r = get_radius(r=r, d=d, dflt=1)
            ) [cp, r],
        cp = data[0],
        r = data[1]
    )
    assert(r>0, "Radius/diameter must be positive")
    let(
        sides = segs(r),
        path = [for (i=[0:1:sides-1]) let(a=360-i*360/sides) r*[cos(a),sin(a)]+cp]
    ) reorient(anchor,spin, two_d=true, r=r, p=path);

module circle(r, d, points, corner, anchor=CENTER, spin=0) {
    if (is_path(points)) {
        c = circle_3points(points);
        check = assert(c!=undef && c[0] != undef, "Points must not be collinear.");
        cp = c[0];
        r = c[1];
        translate(cp) {
            attachable(anchor,spin, two_d=true, r=r) {
                if (r>0) _circle(r=r);
                children();
            }
        }
    } else if (is_path(corner)) {
        r = get_radius(r=r, d=d, dflt=1);
        c = circle_2tangents(r=r, pt1=corner[0], pt2=corner[1], pt3=corner[2]);
        check = assert(c != undef && c[0] != undef, "Points must not be collinear.");
        cp = c[0];
        translate(cp) {
            attachable(anchor,spin, two_d=true, r=r) {
                if (r>0) _circle(r=r);
                children();
            }
        }
    } else {
        r = get_radius(r=r, d=d, dflt=1);
        attachable(anchor,spin, two_d=true, r=r) {
            if (r>0) _circle(r=r);
            children();
        }
    }
}



// Function&Module: ellipse()
// Synopsis: Creates the approximation of an ellipse or a circle.
// SynTags: Geom, Path
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable
// See Also: circle(), circle_2tangents(), circle_3points()
// Usage: As a Module
//   ellipse(r|d=, [realign=], [circum=], [uniform=], ...) [ATTACHMENTS];
// Usage: As a Function
//   path = ellipse(r|d=, [realign=], [circum=], [uniform=], ...);
// Description:
//   When called as a module, creates a 2D polygon that approximates a circle or ellipse of the given size.
//   When called as a function, returns a 2D list of points (path) for a polygon that approximates a circle or ellipse of the given size.
//   By default the point list or shape is the same as the one you would get by scaling the output of {{circle()}}, but with this module your
//   attachments to the ellipse will retain their dimensions, whereas scaling a circle with attachments will also scale the attachments.
//   If you set `uniform` to true then you will get a polygon with congruent sides whose vertices lie on the ellipse.  The `circum` option
//   requests a polygon that circumscribes the requested ellipse (so the specified ellipse will fit into the resulting polygon).  Note that
//   you cannot gives `circum=true` and `uniform=true`.  
// Arguments:
//   r = Radius of the circle or pair of semiaxes of ellipse 
//   ---
//   d = Diameter of the circle or a pair giving the full X and Y axis lengths.  
//   realign = If false starts the approximate ellipse with a point on the X+ axis.  If true the midpoint of a side is on the X+ axis and the first point of the polygon is below the X+ axis.  This can result in a very different polygon when $fn is small.  Default: false
//   uniform = If true, the polygon that approximates the circle will have segments of equal length.  Only works if `circum=false`.  Default: false
//   circum = If true, the polygon that approximates the circle will be upsized slightly to circumscribe the theoretical circle.  If false, it inscribes the theoretical circle.  If this is true then `uniform` must be false.  Default: false
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
// Example(2D): By Radius
//   ellipse(r=25);
// Example(2D): By Diameter
//   ellipse(d=50);
// Example(2D): Anchoring
//   ellipse(d=50, anchor=FRONT);
// Example(2D): Spin
//   ellipse(d=50, anchor=FRONT, spin=45);
// Example(NORENDER): Called as Function
//   path = ellipse(d=50, anchor=FRONT, spin=45);
// Example(2D,NoAxes): Uniformly sampled hexagon at the top, regular non-uniform one at the bottom
//   r=[10,3];
//   ydistribute(7){
//     union(){
//       stroke([ellipse(r=r, $fn=100)],width=0.05,color="blue");
//       stroke([ellipse(r=r, $fn=6)],width=0.1,color="red");
//     }
//     union(){
//       stroke([ellipse(r=r, $fn=100)],width=0.05,color="blue");
//       stroke([ellipse(r=r, $fn=6,uniform=true)],width=0.1,color="red");
//     }
//   }
// Example(2D): The realigned hexagons are even more different
//   r=[10,3];
//   ydistribute(7){
//     union(){
//       stroke([ellipse(r=r, $fn=100)],width=0.05,color="blue");
//       stroke([ellipse(r=r, $fn=6,realign=true)],width=0.1,color="red");
//     }
//     union(){
//       stroke([ellipse(r=r, $fn=100)],width=0.05,color="blue");
//       stroke([ellipse(r=r, $fn=6,realign=true,uniform=true)],width=0.1,color="red");
//     }
//   }
// Example(2D): For odd $fn the result may not look very elliptical:
//    r=[10,3];
//    ydistribute(7){
//      union(){
//        stroke([ellipse(r=r, $fn=100)],width=0.05,color="blue");
//        stroke([ellipse(r=r, $fn=5,realign=false)],width=0.1,color="red");
//      }
//      union(){
//        stroke([ellipse(r=r, $fn=100)],width=0.05,color="blue");
//        stroke([ellipse(r=r, $fn=5,realign=false,uniform=true)],width=0.1,color="red");
//      }
//    }
// Example(2D): The same ellipse, turned 90 deg, gives a very different result:
//   r=[3,10];
//   xdistribute(7){
//     union(){
//       stroke([ellipse(r=r, $fn=100)],width=0.1,color="blue");
//       stroke([ellipse(r=r, $fn=5,realign=false)],width=0.2,color="red");
//     }
//     union(){
//       stroke([ellipse(r=r, $fn=100)],width=0.1,color="blue");
//       stroke([ellipse(r=r, $fn=5,realign=false,uniform=true)],width=0.2,color="red");
//     }
//   }
module ellipse(r, d, realign=false, circum=false, uniform=false, anchor=CENTER, spin=0)
{
    r = force_list(get_radius(r=r, d=d, dflt=1),2);
    dummy = assert(is_vector(r,2) && all_positive(r), "Invalid radius or diameter for ellipse");
    sides = segs(max(r));
    sc = circum? (1 / cos(180/sides)) : 1;
    rx = r.x * sc;
    ry = r.y * sc;
    attachable(anchor,spin, two_d=true, r=[rx,ry]) {
        if (uniform) {
            check = assert(!circum, "Circum option not allowed when \"uniform\" is true");
            polygon(ellipse(r,realign=realign, circum=circum, uniform=true));
        }
        else if (rx < ry) {
            xscale(rx/ry) {
                zrot(realign? 180/sides : 0) {
                    circle(r=ry, $fn=sides);
                }
            }
        } else {
            yscale(ry/rx) {
                zrot(realign? 180/sides : 0) {
                    circle(r=rx, $fn=sides);
                }
            }
        }
        children();
    }
}


// Iterative refinement to produce an inscribed polygon
// in an ellipse whose side lengths are all equal
function _ellipse_refine(a,b,N, _theta=[]) =
   len(_theta)==0? _ellipse_refine(a,b,N,lerpn(0,360,N,endpoint=false))
   :
   let(
       pts = [for(t=_theta) [a*cos(t),b*sin(t)]],
       lenlist= path_segment_lengths(pts,closed=true),
       meanlen = mean(lenlist),
       error = lenlist/meanlen
   )
   all_equal(error,EPSILON) ? pts
   :
   let(
        dtheta = [each deltas(_theta),
                  360-last(_theta)],
        newdtheta = [for(i=idx(dtheta)) dtheta[i]/error[i]],
        adjusted = [0,each cumsum(list_head(newdtheta / sum(newdtheta) * 360))]
   )
   _ellipse_refine(a,b,N,adjusted);




function _ellipse_refine_realign(a,b,N, _theta=[],i=0) =
   len(_theta)==0?
         _ellipse_refine_realign(a,b,N, count(N-1,180/N,360/N))
   :
   let(
       pts = [for(t=_theta) [a*cos(t),b*sin(t)],
              [a*cos(_theta[0]), -b*sin(_theta[0])]],
       lenlist= path_segment_lengths(pts,closed=true),
       meanlen = mean(lenlist),
       error = lenlist/meanlen
   )
   all_equal(error,EPSILON) ? pts
   :
   let(
        dtheta = [each deltas(_theta),
                  360-last(_theta)-_theta[0],
                  2*_theta[0]],
        newdtheta = [for(i=idx(dtheta)) dtheta[i]/error[i]],
        normdtheta = newdtheta / sum(newdtheta) * 360,
        adjusted = cumsum([last(normdtheta)/2, each list_head(normdtheta, -3)])
   )
   _ellipse_refine_realign(a,b,N,adjusted, i+1);



function ellipse(r, d, realign=false, circum=false, uniform=false, anchor=CENTER, spin=0) =
    let(
        r = force_list(get_radius(r=r, d=d, dflt=1),2),
        sides = segs(max(r))
    )
    assert(all_positive(r), "All components of the radius must be positive.")
    uniform
      ? assert(!circum, "Circum option not allowed when \"uniform\" is true")
        reorient(anchor,spin,
            two_d=true, r=[r.x,r.y],
            p=realign
              ? reverse(_ellipse_refine_realign(r.x,r.y,sides))
              : reverse_polygon(_ellipse_refine(r.x,r.y,sides))
        )
      : let(
            offset = realign? 180/sides : 0,
            sc = circum? (1 / cos(180/sides)) : 1,
            rx = r.x * sc,
            ry = r.y * sc,
            pts = [
                for (i=[0:1:sides-1])
                let (a = 360-offset-i*360/sides)
                [rx*cos(a), ry*sin(a)]
            ]
        ) reorient(anchor,spin, two_d=true, r=[rx,ry], p=pts);


// Section: Polygons

// Function&Module: regular_ngon()
// Synopsis: Creates a regular N-sided polygon.
// SynTags: Geom, Path
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable
// See Also: debug_polygon(), circle(), pentagon(), hexagon(), octagon(), ellipse(), star()
// Usage:
//   regular_ngon(n, r|d=|or=|od=, [realign=]) [ATTACHMENTS];
//   regular_ngon(n, ir=|id=, [realign=]) [ATTACHMENTS];
//   regular_ngon(n, side=, [realign=]) [ATTACHMENTS];
// Description:
//   When called as a function, returns a 2D path for a regular N-sided polygon.
//   When called as a module, creates a 2D regular N-sided polygon.
// Arguments:
//   n = The number of sides.
//   r/or = Outside radius, at points.
//   ---
//   d/od = Outside diameter, at points.
//   ir = Inside radius, at center of sides.
//   id = Inside diameter, at center of sides.
//   side = Length of each side.
//   rounding = Radius of rounding for the tips of the polygon.  Default: 0 (no rounding)
//   realign = If false, vertex 0 will lie on the X+ axis.  If true then the midpoint of the last edge will lie on the X+ axis, and vertex 0 will be below the X axis.    Default: false
//   align_tip = If given as a 2D vector, rotates the whole shape so that the first vertex points in that direction.  This occurs before spin.
//   align_side = If given as a 2D vector, rotates the whole shape so that the normal of side0 points in that direction.  This occurs before spin.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
// Extra Anchors:
//   "tip0", "tip1", etc. = Each tip has an anchor, pointing outwards.
//   "side0", "side1", etc. = The center of each side has an anchor, pointing outwards.
// Example(2D): by Outer Size
//   regular_ngon(n=5, or=30);
//   regular_ngon(n=5, od=60);
// Example(2D): by Inner Size
//   regular_ngon(n=5, ir=30);
//   regular_ngon(n=5, id=60);
// Example(2D): by Side Length
//   regular_ngon(n=8, side=20);
// Example(2D): Realigned
//   regular_ngon(n=8, side=20, realign=true);
// Example(2D): Alignment by Tip
//   regular_ngon(n=5, r=30, align_tip=BACK+RIGHT)
//       attach("tip0", FWD) color("blue")
//           stroke([[0,0],[0,7]], endcap2="arrow2");
// Example(2D): Alignment by Side
//   regular_ngon(n=5, r=30, align_side=BACK+RIGHT)
//       attach("side0", FWD) color("blue")
//           stroke([[0,0],[0,7]], endcap2="arrow2");
// Example(2D): Rounded
//   regular_ngon(n=5, od=100, rounding=20, $fn=20);
// Example(2D): Called as Function
//   stroke(closed=true, regular_ngon(n=6, or=30));
function regular_ngon(n=6, r, d, or, od, ir, id, side, rounding=0, realign=false, align_tip, align_side, anchor=CENTER, spin=0, _mat, _anchs) =
    assert(is_int(n) && n>=3)
    assert(is_undef(align_tip) || is_vector(align_tip))
    assert(is_undef(align_side) || is_vector(align_side))
    assert(is_undef(align_tip) || is_undef(align_side), "Can only specify one of align_tip and align-side")
    let(
        sc = 1/cos(180/n),
        ir = is_finite(ir)? ir*sc : undef,
        id = is_finite(id)? id*sc : undef,
        side = is_finite(side)? side/2/sin(180/n) : undef,
        r = get_radius(r1=ir, r2=or, r=r, d1=id, d2=od, d=d, dflt=side)
    )
    assert(!is_undef(r), "regular_ngon(): need to specify one of r, d, or, od, ir, id, side.")
    assert(all_positive([r]), "polygon size must be a positive value")
    let(
        inset = opp_ang_to_hyp(rounding, (180-360/n)/2),
        mat = !is_undef(_mat) ? _mat :
            ( realign? zrot(-180/n) : ident(4)) * (
                !is_undef(align_tip)? rot(from=RIGHT, to=point2d(align_tip)) :
                !is_undef(align_side)? rot(from=RIGHT, to=point2d(align_side)) * zrot(180/n) :
                1
            ),
        path4 = rounding==0? ellipse(r=r, $fn=n) : (
            let(
                steps = floor(segs(r)/n),
                step = 360/n/steps,
                path2 = [
                    for (i = [0:1:n-1]) let(
                        a = 360 - i*360/n,
                        p = polar_to_xy(r-inset, a)
                    )
                    each arc(n=steps, cp=p, r=rounding, start=a+180/n, angle=-360/n)
                ],
                maxx_idx = max_index(column(path2,0)),
                path3 = list_rotate(path2,maxx_idx)
            ) path3
        ),
        path = apply(mat, path4),
        anchors = !is_undef(_anchs) ? _anchs :
            !is_string(anchor)? [] : [
            for (i = [0:1:n-1]) let(
                a1 = 360 - i*360/n,
                a2 = a1 - 360/n,
                p1 = apply(mat, polar_to_xy(r,a1)),
                p2 = apply(mat, polar_to_xy(r,a2)),
                tipp = apply(mat, polar_to_xy(r-inset+rounding,a1)),
                pos = (p1+p2)/2
            ) each [
                named_anchor(str("tip",i), tipp, unit(tipp,BACK), 0),
                named_anchor(str("side",i), pos, unit(pos,BACK), 0),
            ]
        ]
    ) reorient(anchor,spin, two_d=true, path=path, extent=false, p=path, anchors=anchors);


module regular_ngon(n=6, r, d, or, od, ir, id, side, rounding=0, realign=false, align_tip, align_side, anchor=CENTER, spin=0) {
    sc = 1/cos(180/n);
    ir = is_finite(ir)? ir*sc : undef;
    id = is_finite(id)? id*sc : undef;
    side = is_finite(side)? side/2/sin(180/n) : undef;
    r = get_radius(r1=ir, r2=or, r=r, d1=id, d2=od, d=d, dflt=side);
    check = assert(!is_undef(r), "regular_ngon(): need to specify one of r, d, or, od, ir, id, side.")
            assert(all_positive([r]), "polygon size must be a positive value");
    mat = ( realign? zrot(-180/n) : ident(4) ) * (
            !is_undef(align_tip)? rot(from=RIGHT, to=point2d(align_tip)) :
            !is_undef(align_side)? rot(from=RIGHT, to=point2d(align_side)) * zrot(180/n) :
            1
        );
    inset = opp_ang_to_hyp(rounding, (180-360/n)/2);
    anchors = [
        for (i = [0:1:n-1]) let(
            a1 = 360 - i*360/n,
            a2 = a1 - 360/n,
            p1 = apply(mat, polar_to_xy(r,a1)),
            p2 = apply(mat, polar_to_xy(r,a2)),
            tipp = apply(mat, polar_to_xy(r-inset+rounding,a1)),
            pos = (p1+p2)/2
        ) each [
            named_anchor(str("tip",i), tipp, unit(tipp,BACK), 0),
            named_anchor(str("side",i), pos, unit(pos,BACK), 0),
        ]
    ];
    path = regular_ngon(n=n, r=r, rounding=rounding, _mat=mat, _anchs=anchors);
    attachable(anchor,spin, two_d=true, path=path, extent=false, anchors=anchors) {
        polygon(path);
        children();
    }
}


// Function&Module: pentagon()
// Synopsis: Creates a regular pentagon.
// SynTags: Geom, Path
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable
// See Also: circle(), regular_ngon(), hexagon(), octagon(), ellipse(), star()
// Usage:
//   pentagon(or|od=, [realign=], [align_tip=|align_side=]) [ATTACHMENTS];
//   pentagon(ir=|id=, [realign=], [align_tip=|align_side=]) [ATTACHMENTS];
//   pentagon(side=, [realign=], [align_tip=|align_side=]) [ATTACHMENTS];
// Usage: as function
//   path = pentagon(...);
// Description:
//   When called as a function, returns a 2D path for a regular pentagon.
//   When called as a module, creates a 2D regular pentagon.
// Arguments:
//   r/or = Outside radius, at points.
//   ---
//   d/od = Outside diameter, at points.
//   ir = Inside radius, at center of sides.
//   id = Inside diameter, at center of sides.
//   side = Length of each side.
//   rounding = Radius of rounding for the tips of the polygon.  Default: 0 (no rounding)
//   realign = If false, vertex 0 will lie on the X+ axis.  If true then the midpoint of the last edge will lie on the X+ axis, and vertex 0 will be below the X axis.    Default: false
//   align_tip = If given as a 2D vector, rotates the whole shape so that the first vertex points in that direction.  This occurs before spin.
//   align_side = If given as a 2D vector, rotates the whole shape so that the normal of side0 points in that direction.  This occurs before spin.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
// Extra Anchors:
//   "tip0" ... "tip4" = Each tip has an anchor, pointing outwards.
//   "side0" ... "side4" = The center of each side has an anchor, pointing outwards.
// Example(2D): by Outer Size
//   pentagon(or=30);
//   pentagon(od=60);
// Example(2D): by Inner Size
//   pentagon(ir=30);
//   pentagon(id=60);
// Example(2D): by Side Length
//   pentagon(side=20);
// Example(2D): Realigned
//   pentagon(side=20, realign=true);
// Example(2D): Alignment by Tip
//   pentagon(r=30, align_tip=BACK+RIGHT)
//       attach("tip0", FWD) color("blue")
//           stroke([[0,0],[0,7]], endcap2="arrow2");
// Example(2D): Alignment by Side
//   pentagon(r=30, align_side=BACK+RIGHT)
//       attach("side0", FWD) color("blue")
//           stroke([[0,0],[0,7]], endcap2="arrow2");
// Example(2D): Rounded
//   pentagon(od=100, rounding=20, $fn=20);
// Example(2D): Called as Function
//   stroke(closed=true, pentagon(or=30));
function pentagon(r, d, or, od, ir, id, side, rounding=0, realign=false, align_tip, align_side, anchor=CENTER, spin=0) =
    regular_ngon(n=5, r=r, d=d, or=or, od=od, ir=ir, id=id, side=side, rounding=rounding, realign=realign, align_tip=align_tip, align_side=align_side, anchor=anchor, spin=spin);


module pentagon(r, d, or, od, ir, id, side, rounding=0, realign=false, align_tip, align_side, anchor=CENTER, spin=0)
    regular_ngon(n=5, r=r, d=d, or=or, od=od, ir=ir, id=id, side=side, rounding=rounding, realign=realign, align_tip=align_tip, align_side=align_side, anchor=anchor, spin=spin) children();


// Function&Module: hexagon()
// Synopsis: Creates a regular hexagon.
// SynTags: Geom, Path
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable
// See Also: circle(), regular_ngon(), pentagon(), octagon(), ellipse(), star()
// Usage: As Module
//   hexagon(r/or, [realign=], <align_tip=|align_side=>, [rounding=], ...) [ATTACHMENTS];
//   hexagon(d=/od=, ...) [ATTACHMENTS];
//   hexagon(ir=/id=, ...) [ATTACHMENTS];
//   hexagon(side=, ...) [ATTACHMENTS];
// Usage: As Function
//   path = hexagon(...);
// Description:
//   When called as a function, returns a 2D path for a regular hexagon.
//   When called as a module, creates a 2D regular hexagon.
// Arguments:
//   r/or = Outside radius, at points.
//   ---
//   d/od = Outside diameter, at points.
//   ir = Inside radius, at center of sides.
//   id = Inside diameter, at center of sides.
//   side = Length of each side.
//   rounding = Radius of rounding for the tips of the polygon.  Default: 0 (no rounding)
//   realign = If false, vertex 0 will lie on the X+ axis.  If true then the midpoint of the last edge will lie on the X+ axis, and vertex 0 will be below the X axis.    Default: false
//   align_tip = If given as a 2D vector, rotates the whole shape so that the first vertex points in that direction.  This occurs before spin.
//   align_side = If given as a 2D vector, rotates the whole shape so that the normal of side0 points in that direction.  This occurs before spin.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
// Extra Anchors:
//   "tip0" ... "tip5" = Each tip has an anchor, pointing outwards.
//   "side0" ... "side5" = The center of each side has an anchor, pointing outwards.
// Example(2D): by Outer Size
//   hexagon(or=30);
//   hexagon(od=60);
// Example(2D): by Inner Size
//   hexagon(ir=30);
//   hexagon(id=60);
// Example(2D): by Side Length
//   hexagon(side=20);
// Example(2D): Realigned
//   hexagon(side=20, realign=true);
// Example(2D): Alignment by Tip
//   hexagon(r=30, align_tip=BACK+RIGHT)
//       attach("tip0", FWD) color("blue")
//           stroke([[0,0],[0,7]], endcap2="arrow2");
// Example(2D): Alignment by Side
//   hexagon(r=30, align_side=BACK+RIGHT)
//       attach("side0", FWD) color("blue")
//           stroke([[0,0],[0,7]], endcap2="arrow2");
// Example(2D): Rounded
//   hexagon(od=100, rounding=20, $fn=20);
// Example(2D): Called as Function
//   stroke(closed=true, hexagon(or=30));
function hexagon(r, d, or, od, ir, id, side, rounding=0, realign=false, align_tip, align_side, anchor=CENTER, spin=0) =
    regular_ngon(n=6, r=r, d=d, or=or, od=od, ir=ir, id=id, side=side, rounding=rounding, realign=realign, align_tip=align_tip, align_side=align_side, anchor=anchor, spin=spin);


module hexagon(r, d, or, od, ir, id, side, rounding=0, realign=false, align_tip, align_side, anchor=CENTER, spin=0)
    regular_ngon(n=6, r=r, d=d, or=or, od=od, ir=ir, id=id, side=side, rounding=rounding, realign=realign, align_tip=align_tip, align_side=align_side, anchor=anchor, spin=spin) children();


// Function&Module: octagon()
// Synopsis: Creates a regular octagon.
// SynTags: Geom, Path
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable
// See Also: circle(), regular_ngon(), pentagon(), hexagon(), ellipse(), star()
// Usage: As Module
//   octagon(r/or, [realign=], [align_tip=|align_side=], [rounding=], ...) [ATTACHMENTS];
//   octagon(d=/od=, ...) [ATTACHMENTS];
//   octagon(ir=/id=, ...) [ATTACHMENTS];
//   octagon(side=, ...) [ATTACHMENTS];
// Usage: As Function
//   path = octagon(...);
// Description:
//   When called as a function, returns a 2D path for a regular octagon.
//   When called as a module, creates a 2D regular octagon.
// Arguments:
//   r/or = Outside radius, at points.
//   d/od = Outside diameter, at points.
//   ir = Inside radius, at center of sides.
//   id = Inside diameter, at center of sides.
//   side = Length of each side.
//   rounding = Radius of rounding for the tips of the polygon.  Default: 0 (no rounding)
//   realign = If false, vertex 0 will lie on the X+ axis.  If true then the midpoint of the last edge will lie on the X+ axis, and vertex 0 will be below the X axis.    Default: false
//   align_tip = If given as a 2D vector, rotates the whole shape so that the first vertex points in that direction.  This occurs before spin.
//   align_side = If given as a 2D vector, rotates the whole shape so that the normal of side0 points in that direction.  This occurs before spin.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
// Extra Anchors:
//   "tip0" ... "tip7" = Each tip has an anchor, pointing outwards.
//   "side0" ... "side7" = The center of each side has an anchor, pointing outwards.
// Example(2D): by Outer Size
//   octagon(or=30);
//   octagon(od=60);
// Example(2D): by Inner Size
//   octagon(ir=30);
//   octagon(id=60);
// Example(2D): by Side Length
//   octagon(side=20);
// Example(2D): Realigned
//   octagon(side=20, realign=true);
// Example(2D): Alignment by Tip
//   octagon(r=30, align_tip=BACK+RIGHT)
//       attach("tip0", FWD) color("blue")
//           stroke([[0,0],[0,7]], endcap2="arrow2");
// Example(2D): Alignment by Side
//   octagon(r=30, align_side=BACK+RIGHT)
//       attach("side0", FWD) color("blue")
//           stroke([[0,0],[0,7]], endcap2="arrow2");
// Example(2D): Rounded
//   octagon(od=100, rounding=20, $fn=20);
// Example(2D): Called as Function
//   stroke(closed=true, octagon(or=30));
function octagon(r, d, or, od, ir, id, side, rounding=0, realign=false, align_tip, align_side, anchor=CENTER, spin=0) =
    regular_ngon(n=8, r=r, d=d, or=or, od=od, ir=ir, id=id, side=side, rounding=rounding, realign=realign, align_tip=align_tip, align_side=align_side, anchor=anchor, spin=spin);


module octagon(r, d, or, od, ir, id, side, rounding=0, realign=false, align_tip, align_side, anchor=CENTER, spin=0)
    regular_ngon(n=8, r=r, d=d, or=or, od=od, ir=ir, id=id, side=side, rounding=rounding, realign=realign, align_tip=align_tip, align_side=align_side, anchor=anchor, spin=spin) children();


// Function&Module: right_triangle()
// Synopsis: Creates a right triangle.
// SynTags: Geom, Path
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable
// See Also: square(), rect(), regular_ngon(), pentagon(), hexagon(), octagon(), star()
// Usage: As Module
//   right_triangle(size, [center], ...) [ATTACHMENTS];
// Usage: As Function
//   path = right_triangle(size, [center], ...);
// Description:
//   When called as a module, creates a right triangle with the Hypotenuse in the X+Y+ quadrant.
//   When called as a function, returns a 2D path for a right triangle with the Hypotenuse in the X+Y+ quadrant.
// Arguments:
//   size = The width and length of the right triangle, given as a scalar or an XY vector.
//   center = If true, forces `anchor=CENTER`.  If false, forces `anchor=[-1,-1]`.  Default: undef (use `anchor=`)
//   ---
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
// Extra Anchors:
//   hypot = Center of angled side, perpendicular to that side.
// Example(2D):
//   right_triangle([40,30]);
// Example(2D): With `center=true`
//   right_triangle([40,30], center=true);
// Example(2D): Standard Anchors
//   right_triangle([80,30], center=true)
//       show_anchors(custom=false);
//   color([0.5,0.5,0.5,0.1])
//       square([80,30], center=true);
// Example(2D): Named Anchors
//   right_triangle([80,30], center=true)
//       show_anchors(std=false);
function right_triangle(size=[1,1], center, anchor, spin=0) =
    let(
        size = is_num(size)? [size,size] : size,
        anchor = get_anchor(anchor, center, [-1,-1], [-1,-1])
    )
    assert(is_vector(size,2))
    assert(min(size)>0, "Must give positive size")
    let(
        path = [ [size.x/2,-size.y/2], [-size.x/2,-size.y/2], [-size.x/2,size.y/2] ],
        anchors = [
            named_anchor("hypot", CTR, unit([size.y,size.x])),
        ]
    ) reorient(anchor,spin, two_d=true, size=[size.x,size.y], anchors=anchors, p=path);

module right_triangle(size=[1,1], center, anchor, spin=0) {
    size = is_num(size)? [size,size] : size;
    anchor = get_anchor(anchor, center, [-1,-1], [-1,-1]);
    check = assert(is_vector(size,2));
    path = right_triangle(size, anchor="origin");
    anchors = [
        named_anchor("hypot", CTR, unit([size.y,size.x])),
    ];
    attachable(anchor,spin, two_d=true, size=[size.x,size.y], anchors=anchors) {
        polygon(path);
        children();
    }
}


// Function&Module: trapezoid()
// Synopsis: Creates a trapezoid with parallel top and bottom sides.
// SynTags: Geom, Path
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable
// See Also: rect(), square()
// Usage: As Module
//   trapezoid(h, w1, w2, [shift=], [rounding=], [chamfer=], [flip=], ...) [ATTACHMENTS];
//   trapezoid(h, w1, ang=, [rounding=], [chamfer=], [flip=], ...) [ATTACHMENTS];
//   trapezoid(h, w2=, ang=, [rounding=], [chamfer=], [flip=], ...) [ATTACHMENTS];
//   trapezoid(w1=, w2=, ang=, [rounding=], [chamfer=], [flip=], ...) [ATTACHMENTS];
// Usage: As Function
//   path = trapezoid(...);
// Description:
//   When called as a function, returns a 2D path for a trapezoid with parallel front and back (top and bottom) sides. 
//   When called as a module, creates a 2D trapezoid.  You can specify the trapezoid by giving its height and the lengths
//   of its two bases.  Alternatively, you can omit one of those parameters and specify the lower angle(s).
//   The shift parameter, which cannot be combined with ang, shifts the back (top) of the trapezoid to the right.  
// Arguments:
//   h = The Y axis height of the trapezoid.
//   w1 = The X axis width of the front end of the trapezoid.
//   w2 = The X axis width of the back end of the trapezoid.
//   ---
//   ang = Specify the bottom angle(s) of the trapezoid.  Can give a scalar for an isosceles trapezoid or a list of two angles, the left angle and right angle.  You must omit one of `h`, `w1`, or `w2` to allow the freedom to control the angles. 
//   shift = Scalar value to shift the back of the trapezoid along the X axis by.  Cannot be combined with ang.  Default: 0
//   rounding = The rounding radius for the corners.  If given as a list of four numbers, gives individual radii for each corner, in the order [X+Y+,X-Y+,X-Y-,X+Y-]. Default: 0 (no rounding)
//   chamfer = The Length of the chamfer faces at the corners.  If given as a list of four numbers, gives individual chamfers for each corner, in the order [X+Y+,X-Y+,X-Y-,X+Y-].  Default: 0 (no chamfer)
//   flip = If true, negative roundings and chamfers will point forward and back instead of left and right.  Default: `false`.
//   atype = The type of anchoring to use with `anchor=`.  Valid opptions are "box" and "perim".  This lets you choose between putting anchors on the rounded or chamfered perimeter, or on the square bounding box of the shape. Default: "box"
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
// Anchor Types:
//   box = Anchor is with respect to the rectangular bounding box of the shape.
//   perim = Anchors are placed along the rounded or chamfered perimeter of the shape.
// Examples(2D):
//   trapezoid(h=30, w1=40, w2=20);
//   trapezoid(h=25, w1=20, w2=35);
//   trapezoid(h=20, w1=40, w2=0);
//   trapezoid(h=20, w1=30, ang=60);
//   trapezoid(h=20, w1=20, ang=120);
//   trapezoid(h=20, w2=10, ang=60);
//   trapezoid(h=20, w1=50, ang=[40,60]);
//   trapezoid(w1=30, w2=10, ang=[30,90]);
// Example(2D): Chamfered Trapezoid
//   trapezoid(h=30, w1=60, w2=40, chamfer=5);
// Example(2D): Negative Chamfered Trapezoid
//   trapezoid(h=30, w1=60, w2=40, chamfer=-5);
// Example(2D): Flipped Negative Chamfered Trapezoid
//   trapezoid(h=30, w1=60, w2=40, chamfer=-5, flip=true);
// Example(2D): Rounded Trapezoid
//   trapezoid(h=30, w1=60, w2=40, rounding=5);
// Example(2D): Negative Rounded Trapezoid
//   trapezoid(h=30, w1=60, w2=40, rounding=-5);
// Example(2D): Flipped Negative Rounded Trapezoid
//   trapezoid(h=30, w1=60, w2=40, rounding=-5, flip=true);
// Example(2D): Mixed Chamfering and Rounding
//   trapezoid(h=30, w1=60, w2=40, rounding=[5,0,-10,0],chamfer=[0,8,0,-15],$fa=1,$fs=1);
// Example(2D): default anchors for roundings
//   trapezoid(h=30, w1=100, ang=[66,44],rounding=5) show_anchors();
// Example(2D): default anchors for negative roundings are still at the trapezoid corners
//   trapezoid(h=30, w1=100, ang=[66,44],rounding=-5) show_anchors();
// Example(2D): "perim" anchors are at the tips of negative roundings
//   trapezoid(h=30, w1=100, ang=[66,44],rounding=-5, atype="perim") show_anchors();
// Example(2D): They point the other direction if you flip them
//   trapezoid(h=30, w1=100, ang=[66,44],rounding=-5, atype="perim",flip=true) show_anchors();
// Example(2D): Called as Function
//   stroke(closed=true, trapezoid(h=30, w1=40, w2=20));

function _trapezoid_dims(h,w1,w2,shift,ang) = 
    let(  
        h = is_def(h)? h
          : num_defined([w1,w2,each ang])==4 ? (w1-w2) * sin(ang[0]) * sin(ang[1]) / sin(ang[0]+ang[1])
          : undef
    )
    is_undef(h) ? [h]
  :
    let(
        x1 = is_undef(ang[0]) || ang[0]==90 ? 0 : h/tan(ang[0]),
        x2 = is_undef(ang[1]) || ang[1]==90 ? 0 : h/tan(ang[1]),
        w1 = is_def(w1)? w1
           : is_def(w2) && is_def(ang[0]) ? w2 + x1 + x2
           : undef,
        w2 = is_def(w2)? w2
           : is_def(w1) && is_def(ang[0]) ? w1 - x1 - x2
           : undef,
        shift = first_defined([shift,(x1-x2)/2])
    )
    [h,w1,w2,shift];



function trapezoid(h, w1, w2, ang, shift, chamfer=0, rounding=0, flip=false, anchor=CENTER, spin=0,atype="box", _return_override, angle) =
    assert(is_undef(angle), "The angle parameter has been replaced by ang, which specifies trapezoid interior angle")
    assert(is_undef(h) || is_finite(h))
    assert(is_undef(w1) || is_finite(w1))
    assert(is_undef(w2) || is_finite(w2))
    assert(is_undef(ang) || is_finite(ang) || is_vector(ang,2))
    assert(num_defined([h, w1, w2, ang]) == 3, "Must give exactly 3 of the arguments h, w1, w2, and angle.")
    assert(is_undef(shift) || is_finite(shift))
    assert(num_defined([shift,ang])<2, "Cannot specify shift and ang together")
    assert(is_finite(chamfer)  || is_vector(chamfer,4))
    assert(is_finite(rounding) || is_vector(rounding,4))
    let(
        ang = force_list(ang,2),
        angOK = len(ang)==2 && (ang==[undef,undef] || (all_positive(ang) && ang[0]<180 && ang[1]<180))
    )
    assert(angOK, "trapezoid angles must be scalar or 2-vector, strictly between 0 and 180")
    let(
        h_w1_w2_shift = _trapezoid_dims(h,w1,w2,shift,ang),
        h = h_w1_w2_shift[0],
        w1 = h_w1_w2_shift[1],
        w2 = h_w1_w2_shift[2],
        shift = h_w1_w2_shift[3],
        chamfer = force_list(chamfer,4),
        rounding = force_list(rounding,4)
    )
    assert(all_zero(v_mul(chamfer,rounding),0), "Cannot specify chamfer and rounding at the same corner")
    let(
        srads = chamfer+rounding, 
        rads = v_abs(srads)
    )
    assert(w1>=0 && w2>=0 && h>0, "Degenerate trapezoid geometry.")
    assert(w1+w2>0, "Degenerate trapezoid geometry.")
    let(
        base = [
            [ w2/2+shift, h/2],
            [-w2/2+shift, h/2],
            [-w1/2,-h/2],
            [ w1/2,-h/2],
        ],
        ang1 = v_theta(base[0]-base[3])-90,
        ang2 = v_theta(base[1]-base[2])-90,
        angs = [ang1, ang2, ang2, ang1],
        qdirs = [[1,1], [-1,1], [-1,-1], [1,-1]],
        hyps = [for (i=[0:3]) adj_ang_to_hyp(rads[i],angs[i])],
        offs = [
            for (i=[0:3]) let(
                xoff = adj_ang_to_opp(rads[i],angs[i]),
                a = [xoff, -rads[i]] * qdirs[i].y * (srads[i]<0 && flip? -1 : 1),
                b = a + [hyps[i] * qdirs[i].x * (srads[i]<0 && !flip? 1 : -1), 0]
            ) b
        ],
        corners = [
             (
                let(i = 0)
                rads[i] == 0? [base[i]]
              : srads[i] > 0? arc(n=rounding[i]?undef:2, cp=base[i]+offs[i], angle=[angs[i], 90], r=rads[i])
              : flip? arc(n=rounding[i]?undef:2, cp=base[i]+offs[i], angle=[angs[i],-90], r=rads[i])
              : arc(n=rounding[i]?undef:2, cp=base[i]+offs[i], angle=[180+angs[i],90], r=rads[i])
            ),
             (
                let(i = 1)
                rads[i] == 0? [base[i]] 
              : srads[i] > 0? arc(n=rounding[i]?undef:2, cp=base[i]+offs[i], angle=[90,180+angs[i]], r=rads[i]) 
              : flip? arc(n=rounding[i]?undef:2, cp=base[i]+offs[i], angle=[270,180+angs[i]], r=rads[i]) 
              : arc(n=rounding[i]?undef:2, cp=base[i]+offs[i], angle=[90,angs[i]], r=rads[i])
            ),
             (
                let(i = 2)
                rads[i] == 0? [base[i]] 
              : srads[i] > 0? arc(n=rounding[i]?undef:2, cp=base[i]+offs[i], angle=[180+angs[i],270], r=rads[i]) 
              : flip? arc(n=rounding[i]?undef:2, cp=base[i]+offs[i], angle=[180+angs[i],90], r=rads[i]) 
              : arc(n=rounding[i]?undef:2, cp=base[i]+offs[i], angle=[angs[i],-90], r=rads[i])
            ),
             (
                let(i = 3)
                rads[i] == 0? [base[i]] 
              : srads[i] > 0? arc(n=rounding[i]?undef:2, cp=base[i]+offs[i], angle=[-90,angs[i]], r=rads[i]) 
              : flip? arc(n=rounding[i]?undef:2, cp=base[i]+offs[i], angle=[90,angs[i]], r=rads[i]) 
              : arc(n=rounding[i]?undef:2, cp=base[i]+offs[i], angle=[270,180+angs[i]], r=rads[i])
            ),
        ],
        path = reverse(flatten(corners)),
        override = [for(i=[0:3])
                      if (atype!="box" && srads[i]!=0)
                         srads[i]>0?
                             let(dir = unit(base[i]-select(base,i-1)) + unit(base[i]-select(base,i+1)),
                                pt=[for(seg=pair(corners[i])) let(isect=line_intersection(seg, [base[i],base[i]+dir],SEGMENT,LINE))
                                                             if (is_def(isect) && isect!=seg[0]) isect]
                             )
                             [qdirs[i], [pt[0], undef]]
                        : flip?
                            let(  dir=unit(base[i] - select(base,i+(i%2==0?-1:1))))
                            [qdirs[i], [select(corners[i],i%2==0?0:-1), dir]]
                        : let( dir = [qdirs[i].x,0])
                            [qdirs[i], [select(corners[i],i%2==0?-1:0), dir]]]
    ) _return_override ? [reorient(anchor,spin, two_d=true, size=[w1,h], size2=w2, shift=shift, p=path, override=override),override]
                       : reorient(anchor,spin, two_d=true, size=[w1,h], size2=w2, shift=shift, p=path, override=override);




module trapezoid(h, w1, w2, ang, shift, chamfer=0, rounding=0, flip=false, anchor=CENTER, spin=0, atype="box", angle) {
    path_over = trapezoid(h=h, w1=w1, w2=w2, ang=ang, shift=shift, chamfer=chamfer, rounding=rounding,
                          flip=flip, angle=angle,atype=atype,anchor="origin",_return_override=true);
    path=path_over[0];
    override = path_over[1];
    ang = force_list(ang,2);
    h_w1_w2_shift = _trapezoid_dims(h,w1,w2,shift,ang);
    h = h_w1_w2_shift[0];
    w1 = h_w1_w2_shift[1];
    w2 = h_w1_w2_shift[2];
    shift = h_w1_w2_shift[3];
    attachable(anchor,spin, two_d=true, size=[w1,h], size2=w2, shift=shift, override=override) {
        polygon(path);
        children();
    }
}



// Function&Module: star()
// Synopsis: Creates a star-shaped polygon or returns a star-shaped region.
// SynTags: Geom, Path
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable
// See Also: circle(), ellipse(), regular_ngon()
// Usage: As Module
//   star(n, r/or, ir, [realign=], [align_tip=], [align_pit=], ...) [ATTACHMENTS];
//   star(n, r/or, step=, ...) [ATTACHMENTS];
// Usage: As Function
//   path = star(n, r/or, ir, [realign=], [align_tip=], [align_pit=], ...);
//   path = star(n, r/or, step=, ...);
// Description:
//   When called as a function, returns the path needed to create a star polygon with N points.
//   When called as a module, creates a star polygon with N points.
// Arguments:
//   n = The number of stellate tips on the star.
//   r/or = The radius to the tips of the star.
//   ir = The radius to the inner corners of the star.
//   ---
//   d/od = The diameter to the tips of the star.
//   id = The diameter to the inner corners of the star.
//   step = Calculates the radius of the inner star corners by virtually drawing a straight line `step` tips around the star.  2 <= step < n/2
//   realign = If false, vertex 0 will lie on the X+ axis.  If true then the midpoint of the last edge will lie on the X+ axis, and vertex 0 will be below the X axis.    Default: false
//   align_tip = If given as a 2D vector, rotates the whole shape so that the first star tip points in that direction.  This occurs before spin.
//   align_pit = If given as a 2D vector, rotates the whole shape so that the first inner corner is pointed towards that direction.  This occurs before spin.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   atype = Choose "hull" or "intersect" anchor methods.  Default: "hull"
// Extra Anchors:
//   "tip0" ... "tip4" = Each tip has an anchor, pointing outwards.
//   "pit0" ... "pit4" = The inside corner between each tip has an anchor, pointing outwards.
//   "midpt0" ... "midpt4" = The center-point between each pair of tips has an anchor, pointing outwards.
// Examples(2D):
//   star(n=5, r=50, ir=25);
//   star(n=5, r=50, step=2);
//   star(n=7, r=50, step=2);
//   star(n=7, r=50, step=3);
// Example(2D): Realigned
//   star(n=7, r=50, step=3, realign=true);
// Example(2D): Alignment by Tip
//   star(n=5, ir=15, or=30, align_tip=BACK+RIGHT)
//       attach("tip0", FWD) color("blue")
//           stroke([[0,0],[0,7]], endcap2="arrow2");
// Example(2D): Alignment by Pit
//   star(n=5, ir=15, or=30, align_pit=BACK+RIGHT)
//       attach("pit0", FWD) color("blue")
//           stroke([[0,0],[0,7]], endcap2="arrow2");
// Example(2D): Called as Function
//   stroke(closed=true, star(n=5, r=50, ir=25));
function star(n, r, ir, d, or, od, id, step, realign=false, align_tip, align_pit, anchor=CENTER, spin=0, atype="hull", _mat, _anchs) =
    assert(in_list(atype, _ANCHOR_TYPES), "Anchor type must be \"hull\" or \"intersect\"")  
    assert(is_undef(align_tip) || is_vector(align_tip))
    assert(is_undef(align_pit) || is_vector(align_pit))
    assert(is_undef(align_tip) || is_undef(align_pit), "Can only specify one of align_tip and align_pit")
    assert(is_def(n), "Must specify number of points, n")
    let(
        r = get_radius(r1=or, d1=od, r=r, d=d),
        count = num_defined([ir,id,step]),
        stepOK = is_undef(step) || (step>1 && step<n/2)
    )
    assert(count==1, "Must specify exactly one of ir, id, step")
    assert(stepOK,  n==4 ? "Parameter 'step' not allowed for 4 point stars"
                  : n==5 || n==6 ? str("Parameter 'step' must be 2 for ",n," point stars")
                  : str("Parameter 'step' must be between 2 and ",floor(n/2-1/2)," for ",n," point stars"))
    let(
        mat = !is_undef(_mat) ? _mat :
            ( realign? zrot(-180/n) : ident(4) ) * (
                !is_undef(align_tip)? rot(from=RIGHT, to=point2d(align_tip)) :
                !is_undef(align_pit)? rot(from=RIGHT, to=point2d(align_pit)) * zrot(180/n) :
                1
            ),
        stepr = is_undef(step)? r : r*cos(180*step/n)/cos(180*(step-1)/n),
        ir = get_radius(r=ir, d=id, dflt=stepr),
        offset = realign? 180/n : 0,
        path1 = [for(i=[2*n:-1:1]) let(theta=180*i/n, radius=(i%2)?ir:r) radius*[cos(theta), sin(theta)]],
        path = apply(mat, path1),
        anchors = !is_undef(_anchs) ? _anchs :
            !is_string(anchor)? [] : [
            for (i = [0:1:n-1]) let(
                a1 = 360 - i*360/n,
                a2 = a1 - 180/n,
                a3 = a1 - 360/n,
                p1 = apply(mat, polar_to_xy(r,a1)),
                p2 = apply(mat, polar_to_xy(ir,a2)),
                p3 = apply(mat, polar_to_xy(r,a3)),
                pos = (p1+p3)/2
            ) each [
                named_anchor(str("tip",i), p1, unit(p1,BACK), 0),
                named_anchor(str("pit",i), p2, unit(p2,BACK), 0),
                named_anchor(str("midpt",i), pos, unit(pos,BACK), 0),
            ]
        ]
    ) reorient(anchor,spin, two_d=true, path=path, p=path, extent=atype=="hull", anchors=anchors);


module star(n, r, ir, d, or, od, id, step, realign=false, align_tip, align_pit, anchor=CENTER, spin=0, atype="hull") {
    checks =
        assert(in_list(atype, _ANCHOR_TYPES), "Anchor type must be \"hull\" or \"intersect\"")
        assert(is_undef(align_tip) || is_vector(align_tip))
        assert(is_undef(align_pit) || is_vector(align_pit))
        assert(is_undef(align_tip) || is_undef(align_pit), "Can only specify one of align_tip and align_pit");
    r = get_radius(r1=or, d1=od, r=r, d=d, dflt=undef);
    stepr = is_undef(step)? r : r*cos(180*step/n)/cos(180*(step-1)/n);
    ir = get_radius(r=ir, d=id, dflt=stepr);
    mat = ( realign? zrot(-180/n) : ident(4) ) * (
            !is_undef(align_tip)? rot(from=RIGHT, to=point2d(align_tip)) :
            !is_undef(align_pit)? rot(from=RIGHT, to=point2d(align_pit)) * zrot(180/n) :
            1
        );
    anchors = [
        for (i = [0:1:n-1]) let(
            a1 = 360 - i*360/n - (realign? 180/n : 0),
            a2 = a1 - 180/n,
            a3 = a1 - 360/n,
            p1 = apply(mat, polar_to_xy(r,a1)),
            p2 = apply(mat, polar_to_xy(ir,a2)),
            p3 = apply(mat, polar_to_xy(r,a3)),
            pos = (p1+p3)/2
        ) each [
            named_anchor(str("tip",i), p1, unit(p1,BACK), 0),
            named_anchor(str("pit",i), p2, unit(p2,BACK), 0),
            named_anchor(str("midpt",i), pos, unit(pos,BACK), 0),
        ]
    ];
    path = star(n=n, r=r, ir=ir, realign=realign, _mat=mat, _anchs=anchors);
    attachable(anchor,spin, two_d=true, path=path, extent=atype=="hull", anchors=anchors) {
        polygon(path);
        children();
    }
}



/// Internal Function: _path_add_jitter()
/// Topics: Paths
/// See Also: jittered_poly()
/// Usage:
///   jpath = _path_add_jitter(path, [dist], [closed=]);
/// Description:
///   Adds tiny jitter offsets to collinear points in the given path so that they
///   are no longer collinear.  This is useful for preserving subdivision on long
///   straight segments, when making geometry with `polygon()`, for use with
///   `linear_exrtrude()` with a `twist()`.
/// Arguments:
///   path = The path to add jitter to.
///   dist = The amount to jitter points by.  Default: 1/512 (0.00195)
///   ---
///   closed = If true, treat path like a closed polygon.  Default: true
/// Example(3D):
///   d = 100; h = 75; quadsize = 5;
///   path = pentagon(d=d);
///   spath = subdivide_path(path, maxlen=quadsize, closed=true);
///   jpath = _path_add_jitter(spath, closed=true);
///   linear_extrude(height=h, twist=72, slices=h/quadsize)
///      polygon(jpath);
function _path_add_jitter(path, dist=1/512, closed=true) =
    assert(is_path(path))
    assert(is_finite(dist))
    assert(is_bool(closed))
    [
        path[0],
        for (i=idx(path,s=1,e=closed?-1:-2)) let(
            n = line_normal([path[i-1],path[i]])
        ) path[i] + n * (is_collinear(select(path,i-1,i+1))? (dist * ((i%2)*2-1)) : 0),
        if (!closed) last(path)
    ];



// Module: jittered_poly()
// Synopsis: Creates a polygon with extra points for smoother twisted extrusions.
// SynTags: Geom
// Topics: Extrusions
// See Also: subdivide_path()
// Usage:
//   jittered_poly(path, [dist]);
// Description:
//   Creates a 2D polygon shape from the given path in such a way that any extra
//   collinear points are not stripped out in the way that `polygon()` normally does.
//   This is useful for refining the mesh of a `linear_extrude()` with twist.
// Arguments:
//   path = The path to add jitter to.
//   dist = The amount to jitter points by.  Default: 1/512 (0.00195)
// Example:
//   d = 100; h = 75; quadsize = 5;
//   path = pentagon(d=d);
//   spath = subdivide_path(path, maxlen=quadsize, closed=true);
//   linear_extrude(height=h, twist=72, slices=h/quadsize)
//      jittered_poly(spath);
module jittered_poly(path, dist=1/512) {
    no_children($children);
    polygon(_path_add_jitter(path, dist, closed=true));
}


// Section: Curved 2D Shapes


// Function&Module: teardrop2d()
// Synopsis: Creates a 2D teardrop shape.
// SynTags: Geom, Path
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable
// See Also: teardrop(), onion()
// Description:
//   When called as a module, makes a 2D teardrop shape. Useful for extruding into 3D printable holes as it limits overhang to 45 degrees.  Uses "intersect" style anchoring.  
//   The cap_h parameter truncates the top of the teardrop.  If cap_h is taller than the untruncated form then
//   the result will be the full, untruncated shape.  The segments of the bottom section of the teardrop are
//   calculated to be the same as a circle or cylinder when rotated 90 degrees.  (Note that this agreement is poor when `$fn=6` or `$fn=7`.  
//   If `$fn` is a multiple of four then the teardrop will reach its extremes on all four axes.  The circum option
//   produces a teardrop that circumscribes the circle; in this case set `realign=true` to get a teardrop that meets its internal extremes
//   on the axes.  
//   When called as a function, returns a 2D path to for a teardrop shape.
//
// Usage: As Module
//   teardrop2d(r/d=, [ang], [cap_h]) [ATTACHMENTS];
// Usage: As Function
//   path = teardrop2d(r|d=, [ang], [cap_h]);
//
// Arguments:
//   r = radius of circular part of teardrop.  (Default: 1)
//   ang = angle of hat walls from the Y axis (half the angle of the peak).  (Default: 45 degrees)
//   cap_h = if given, height above center where the shape will be truncated.
//   ---
//   d = diameter of circular portion of bottom. (Use instead of r)
//   circum = if true, create a circumscribing teardrop.  Default: false
//   realign = if true, change whether bottom of teardrop is a point or a flat.  Default: false
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//
// Example(2D): Typical Shape
//   teardrop2d(r=30, ang=30);
// Example(2D): Crop Cap
//   teardrop2d(r=30, ang=30, cap_h=40);
// Example(2D): Close Crop
//   teardrop2d(r=30, ang=30, cap_h=20);
module teardrop2d(r, ang=45, cap_h, d, circum=false, realign=false, anchor=CENTER, spin=0)
{
    path = teardrop2d(r=r, d=d, ang=ang, circum=circum, realign=realign, cap_h=cap_h);
    attachable(anchor,spin, two_d=true, path=path, extent=false) {
        polygon(path);
        children();
    }
}

// _extrapt = true causes the point to be duplicated so a teardrop with no cap
// has the same point count as one with a cap.  

function teardrop2d(r, ang=45, cap_h, d, circum=false, realign=false, anchor=CENTER, spin=0, _extrapt=false) =
    let(
        r = get_radius(r=r, d=d, dflt=1),
        minheight = r*sin(ang),
        maxheight = r/sin(ang), //cos(90-ang),
        pointycap = is_undef(cap_h) || cap_h>=maxheight
    )
    assert(is_undef(cap_h) || cap_h>=minheight, str("cap_h cannot be less than ",minheight," but it is ",cap_h))
    let(
        cap = [
                pointycap? [0,maxheight] : [(maxheight-cap_h)*tan(ang), cap_h],
                r*[cos(ang),sin(ang)]
              ],
        fullcircle = ellipse(r=r, realign=realign, circum=circum,spin=90),        
        
        // Chose the point on the circle that is lower than the cap but also creates a segment bigger than
        // seglen/skipfactor so we don't have a teeny tiny segment at the end of the cap, except for the hexagoin
        // case which is treated specially
        skipfactor = len(fullcircle)==6 ? 15 : 3,
        path = !circum ?
                  let(seglen = norm(fullcircle[0]-fullcircle[1]))
                  [
                   each cap,
                   for (p=fullcircle)
                          if (
                               p.y<last(cap).y-EPSILON
                                 && norm([abs(p.x)-last(cap).x,p.y-last(cap.y)])>seglen/skipfactor
                             ) p,
                   xflip(cap[1]),
                   if (_extrapt || !pointycap) xflip(cap[0])
                  ]
             : let(
                   isect = [for(i=[0:1:len(fullcircle)/4])
                               let(p = line_intersection(cap, select(fullcircle,[i,i+1]), bounded1=RAY, bounded2=SEGMENT))
                               if (p) [i,p]
                           ],
                   i = last(isect)[0],
                   p = last(isect)[1]
               )
               [
                 cap[0],
                 p,
                 each select(fullcircle,i+1,-i-1-(realign?1:0)),
                 xflip(p),
                 if(_extrapt || !pointycap) xflip(cap[0])
               ]
    )
    reorient(anchor,spin, two_d=true, path=path, p=path, extent=false);



// Function&Module: egg()
// Synopsis: Creates an egg-shaped 2d object.
// SynTags: Geom, Path
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable
// See Also: circle(), ellipse(), glued_circles()
// Usage: As Module
//   egg(length, r1|d1=, r2|d2=, R|D=) [ATTACHMENTS];
// Usage: As Function
//   path = egg(length, r1|d1=, r2|d2=, R|D=);
// Description:
//   When called as a module, constructs an egg-shaped object by connecting two circles with convex arcs that are tangent to the circles.
//   You specify the length of the egg, the radii of the two circles, and the desired arc radius.
//   Note that because the side radius, R, is often much larger than the end radii, you may get better
//   results using `$fs` and `$fa` to control the number of semgments rather than using `$fn`.
//   This shape may be useful for creating a cam. 
//   When called as a function, returns a 2D path for an egg-shaped object. 
// Arguments:
//   length = length of the egg
//   r1 = radius of the left-hand circle
//   r2 = radius of the right-hand circle
//   R = radius of the joining arcs
//   ---
//   d1 = diameter of the left-hand circle
//   d2 = diameter of the right-hand circle
//   D = diameter of the joining arcs
// Extra Anchors:
//   "left" = center of the left circle
//   "right" = center of the right circle
// Example(2D,NoAxes): This first example shows how the egg is constructed from two circles and two joining arcs.
//   $fn=100;
//   color("red") stroke(egg(78,25,12, 60),closed=true);
//   stroke([left(14,circle(25)),
//           right(27,circle(12))]);
// Example(2D,Anim,VPD=250,VPR=[0,0,0]): Varying length between circles
//   r1 = 25; r2 = 12; R = 65;
//   length = floor(lookup($t, [[0,55], [0.5,90], [1,55]]));
//   egg(length,r1,r2,R,$fn=180);
//   color("black") text(str("length=",length), size=8, halign="center", valign="center");
// Example(2D,Anim,VPD=250,VPR=[0,0,0]): Varying tangent arc radius R
//   length = 78; r1 = 25; r2 = 12;
//   R = floor(lookup($t, [[0,45], [0.5,150], [1,45]]));
//   egg(length,r1,r2,R,$fn=180);
//   color("black") text(str("R=",R), size=8, halign="center", valign="center");
// Example(2D,Anim,VPD=250,VPR=[0,0,0]): Varying circle radius r2
//   length = 78; r1 = 25; R = 65;
//   r2 = floor(lookup($t, [[0,5], [0.5,30], [1,5]]));
//   egg(length,r1,r2,R,$fn=180);
//   color("black") text(str("r2=",r2), size=8, halign="center", valign="center");
function egg(length, r1, r2, R, d1, d2, D, anchor=CENTER, spin=0) =
    let(
        r1 = get_radius(r1=r1,d1=d1),
        r2 = get_radius(r1=r2,d1=d2),
        D = get_radius(r1=R, d1=D)
    )
    assert(length>0)
    assert(R>length/2, "Side radius R must be larger than length/2")
    assert(length>r1+r2, "Length must be longer than 2*(r1+r2)")
    assert(length>2*r2, "Length must be longer than 2*r2")
    assert(length>2*r1, "Length must be longer than 2*r1")  
    let(
        c1 = [-length/2+r1,0],
        c2 = [length/2-r2,0],
        Rmin = (r1+r2+norm(c1-c2))/2,
        Mlist = circle_circle_intersection(R-r1, c1, R-r2, c2),
        arcparms = reverse([for(M=Mlist) [M, c1+r1*unit(c1-M), c2+r2*unit(c2-M)]]),
        path = concat(
                      arc(r=r2, cp=c2, points=[[length/2,0],arcparms[0][2]],endpoint=false),
                      arc(r=R, cp=arcparms[0][0], points=select(arcparms[0],[2,1]),endpoint=false),
                      arc(r=r1, points=[arcparms[0][1], [-length/2,0], arcparms[1][1]],endpoint=false),
                      arc(r=R, cp=arcparms[1][0], points=select(arcparms[1],[1,2]),endpoint=false),
                      arc(r=r2, cp=c2, points=[arcparms[1][2], [length/2,0]],endpoint=false)
        ),
        anchors = [named_anchor("left", c1, BACK, 0),
                   named_anchor("right", c2, BACK, 0)]
    )
    reorient(anchor, spin, two_d=true, path=path, extent=true, p=path, anchors=anchors);

module egg(length,r1,r2,R,d1,d2,D,anchor=CENTER, spin=0)
{
  path = egg(length,r1,r2,R,d1,d2,D);
  anchors = [named_anchor("left", [-length/2+r1,0], BACK, 0),
             named_anchor("right", [length/2-r2,0], BACK, 0)];
  attachable(anchor, spin, two_d=true, path=path, extent=true, anchors=anchors){
    polygon(path);
    children();
  }
}



// Function&Module: glued_circles()
// Synopsis: Creates a shape of two circles joined by a curved waist.
// SynTags: Geom, Path
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable
// See Also: circle(), ellipse(), egg()
// Usage: As Module
//   glued_circles(r/d=, [spread], [tangent], ...) [ATTACHMENTS];
// Usage: As Function
//   path = glued_circles(r/d=, [spread], [tangent], ...);
// Description:
//   When called as a function, returns a 2D path forming a shape of two circles joined by curved waist.
//   When called as a module, creates a 2D shape of two circles joined by curved waist.  Uses "hull" style anchoring.  
// Arguments:
//   r = The radius of the end circles.
//   spread = The distance between the centers of the end circles.  Default: 10
//   tangent = The angle in degrees of the tangent point for the joining arcs, measured away from the Y axis.  Default: 30
//   ---
//   d = The diameter of the end circles.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
// Examples(2D):
//   glued_circles(r=15, spread=40, tangent=45);
//   glued_circles(d=30, spread=30, tangent=30);
//   glued_circles(d=30, spread=30, tangent=15);
//   glued_circles(d=30, spread=30, tangent=-30);
// Example(2D): Called as Function
//   stroke(closed=true, glued_circles(r=15, spread=40, tangent=45));
function glued_circles(r, spread=10, tangent=30, d, anchor=CENTER, spin=0) =
    let(
        r = get_radius(r=r, d=d, dflt=10),
        r2 = (spread/2 / sin(tangent)) - r,
        cp1 = [spread/2, 0],
        cp2 = [0, (r+r2)*cos(tangent)],
        sa1 = 90-tangent,
        ea1 = 270+tangent,
        lobearc = ea1-sa1,
        lobesegs = ceil(segs(r)*lobearc/360),
        sa2 = 270-tangent,
        ea2 = 270+tangent,
        subarc = ea2-sa2,
        arcsegs = ceil(segs(r2)*abs(subarc)/360),
        // In the tangent zero case the inner curves are missing so we need to complete the two
        // outer curves.  In the other case the inner curves are present and endpoint=false
        // prevents point duplication.  
        path = tangent==0 ?
                    concat(arc(n=lobesegs+1, r=r, cp=-cp1, angle=[sa1,ea1]),
                           arc(n=lobesegs+1, r=r, cp=cp1, angle=[sa1+180,ea1+180]))
                :
                    concat(arc(n=lobesegs, r=r, cp=-cp1, angle=[sa1,ea1], endpoint=false),
                           [for(theta=lerpn(ea2+180,ea2-subarc+180,arcsegs,endpoint=false))  r2*[cos(theta),sin(theta)] - cp2],
                           arc(n=lobesegs, r=r, cp=cp1, angle=[sa1+180,ea1+180], endpoint=false),
                           [for(theta=lerpn(ea2,ea2-subarc,arcsegs,endpoint=false))  r2*[cos(theta),sin(theta)] + cp2]),
        maxx_idx = max_index(column(path,0)),
        path2 = reverse_polygon(list_rotate(path,maxx_idx))
    ) reorient(anchor,spin, two_d=true, path=path2, extent=true, p=path2);


module glued_circles(r, spread=10, tangent=30, d, anchor=CENTER, spin=0) {
    path = glued_circles(r=r, d=d, spread=spread, tangent=tangent);
    attachable(anchor,spin, two_d=true, path=path, extent=true) {
        polygon(path);
        children();
    }
}



function _superformula(theta,m1,m2,n1,n2=1,n3=1,a=1,b=1) =
    pow(pow(abs(cos(m1*theta/4)/a),n2)+pow(abs(sin(m2*theta/4)/b),n3),-1/n1);

// Function&Module: supershape()
// Synopsis: Creates a 2D [Superformula](https://en.wikipedia.org/wiki/Superformula) shape.
// SynTags: Geom, Path
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable
// See Also: circle(), ellipse()
// Usage: As Module
//   supershape([step],[n=], [m1=], [m2=], [n1=], [n2=], [n3=], [a=], [b=], [r=/d=]) [ATTACHMENTS];
// Usage: As Function
//   path = supershape([step], [n=], [m1=], [m2=], [n1=], [n2=], [n3=], [a=], [b=], [r=/d=]);
// Description:
//   When called as a function, returns a 2D path for the outline of the [Superformula](https://en.wikipedia.org/wiki/Superformula) shape.
//   When called as a module, creates a 2D [Superformula](https://en.wikipedia.org/wiki/Superformula) shape.
//   Note that the "hull" type anchoring (the default) is more intuitive for concave star-like shapes, but the anchor points do not
//   necesarily lie on the line of the anchor vector, which can be confusing, especially for simpler, ellipse-like shapes.
//   Note that the default step angle of 0.5 is very fine and can be slow, but due to the complex curves of the supershape,
//   many points are often required to give a good result.  
// Arguments:
//   step = The angle step size for sampling the superformula shape.  Smaller steps are slower but more accurate.  Default: 0.5
//   ---
//   n = Produce n points as output.  Alternative to step.  Not to be confused with shape parameters n1 and n2.  
//   m1 = The m1 argument for the superformula. Default: 4.
//   m2 = The m2 argument for the superformula. Default: m1.
//   n1 = The n1 argument for the superformula. Default: 1.
//   n2 = The n2 argument for the superformula. Default: n1.
//   n3 = The n3 argument for the superformula. Default: n2.
//   a = The a argument for the superformula.  Default: 1.
//   b = The b argument for the superformula.  Default: a.
//   r = Radius of the shape.  Scale shape to fit in a circle of radius r.
//   d = Diameter of the shape.  Scale shape to fit in a circle of diameter d.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   atype = Select "hull" or "intersect" style anchoring.  Default: "hull". 
// Example(2D):
//   supershape(step=0.5,m1=16,m2=16,n1=0.5,n2=0.5,n3=16,r=50);
// Example(2D): Called as Function
//   stroke(closed=true, supershape(step=0.5,m1=16,m2=16,n1=0.5,n2=0.5,n3=16,d=100));
// Examples(2D,Med):
//   for(n=[2:5]) right(2.5*(n-2)) supershape(m1=4,m2=4,n1=n,a=1,b=2);  // Superellipses
//   m=[2,3,5,7]; for(i=[0:3]) right(2.5*i) supershape(.5,m1=m[i],n1=1);
//   m=[6,8,10,12]; for(i=[0:3]) right(2.7*i) supershape(.5,m1=m[i],n1=1,b=1.5);  // m should be even
//   m=[1,2,3,5]; for(i=[0:3]) fwd(1.5*i) supershape(m1=m[i],n1=0.4);
//   supershape(m1=5, n1=4, n2=1); right(2.5) supershape(m1=5, n1=40, n2=10);
//   m=[2,3,5,7]; for(i=[0:3]) right(2.5*i) supershape(m1=m[i], n1=60, n2=55, n3=30);
//   n=[0.5,0.2,0.1,0.02]; for(i=[0:3]) right(2.5*i) supershape(m1=5,n1=n[i], n2=1.7);
//   supershape(m1=2, n1=1, n2=4, n3=8);
//   supershape(m1=7, n1=2, n2=8, n3=4);
//   supershape(m1=7, n1=3, n2=4, n3=17);
//   supershape(m1=4, n1=1/2, n2=1/2, n3=4);
//   supershape(m1=4, n1=4.0,n2=16, n3=1.5, a=0.9, b=9);
//   for(i=[1:4]) right(3*i) supershape(m1=i, m2=3*i, n1=2);
//   m=[4,6,10]; for(i=[0:2]) right(i*5) supershape(m1=m[i], n1=12, n2=8, n3=5, a=2.7);
//   for(i=[-1.5:3:1.5]) right(i*1.5) supershape(m1=2,m2=10,n1=i,n2=1);
//   for(i=[1:3],j=[-1,1]) translate([3.5*i,1.5*j])supershape(m1=4,m2=6,n1=i*j,n2=1);
//   for(i=[1:3]) right(2.5*i)supershape(step=.5,m1=88, m2=64, n1=-i*i,n2=1,r=1);
// Examples:
//   linear_extrude(height=0.3, scale=0) supershape(step=1, m1=6, n1=0.4, n2=0, n3=6);
//   linear_extrude(height=5, scale=0) supershape(step=1, b=3, m1=6, n1=3.8, n2=16, n3=10);
function supershape(step=0.5, n, m1=4, m2, n1=1, n2, n3, a=1, b, r, d,anchor=CENTER, spin=0, atype="hull") =
    assert(in_list(atype, _ANCHOR_TYPES), "Anchor type must be \"hull\" or \"intersect\"")
    let(
        n = first_defined([n, ceil(360/step)]),
        angs = lerpn(360,0,n,endpoint=false),  
        r = get_radius(r=r, d=d, dflt=undef),
        m2 = is_def(m2) ? m2 : m1,
        n2 = is_def(n2) ? n2 : n1,
        n3 = is_def(n3) ? n3 : n2,
        b = is_def(b) ? b : a,
        // superformula returns r(theta), the point in polar coordinates
        rvals = [for (theta = angs) _superformula(theta=theta,m1=m1,m2=m2,n1=n1,n2=n2,n3=n3,a=a,b=b)],
        scale = is_def(r) ? r/max(rvals) : 1,
        path = [for (i=idx(angs)) scale*rvals[i]*[cos(angs[i]), sin(angs[i])]]
    ) reorient(anchor,spin, two_d=true, path=path, p=path, extent=atype=="hull");

module supershape(step=0.5,n,m1=4,m2=undef,n1,n2=undef,n3=undef,a=1,b=undef, r=undef, d=undef, anchor=CENTER, spin=0, atype="hull") {
    check = assert(in_list(atype, _ANCHOR_TYPES), "Anchor type must be \"hull\" or \"intersect\"");
    path = supershape(step=step,n=n,m1=m1,m2=m2,n1=n1,n2=n2,n3=n3,a=a,b=b,r=r,d=d);
    attachable(anchor,spin,extent=atype=="hull", two_d=true, path=path) {
        polygon(path);
        children();
    }
}


// Function&Module: reuleaux_polygon()
// Synopsis: Creates a constant-width shape that is not circular.
// SynTags: Geom, Path
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable
// See Also: regular_ngon(), pentagon(), hexagon(), octagon()
// Usage: As Module
//   reuleaux_polygon(n, r|d=, ...) [ATTACHMENTS];
// Usage: As Function
//   path = reuleaux_polygon(n, r|d=, ...);
// Description:
//   When called as a module, reates a 2D Reuleaux Polygon; a constant width shape that is not circular.  Uses "intersect" type anchoring.  
//   When called as a function, returns a 2D path for a Reulaux Polygon.
// Arguments:
//   n = Number of "sides" to the Reuleaux Polygon.  Must be an odd positive number.  Default: 3
//   r = Radius of the shape.  Scale shape to fit in a circle of radius r.
//   ---
//   d = Diameter of the shape.  Scale shape to fit in a circle of diameter d.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
// Extra Anchors:
//   "tip0", "tip1", etc. = Each tip has an anchor, pointing outwards.
// Examples(2D):
//   reuleaux_polygon(n=3, r=50);
//   reuleaux_polygon(n=5, d=100);
// Examples(2D): Standard vector anchors are based on extents
//   reuleaux_polygon(n=3, d=50) show_anchors(custom=false);
// Examples(2D): Named anchors exist for the tips
//   reuleaux_polygon(n=3, d=50) show_anchors(std=false);
module reuleaux_polygon(n=3, r, d, anchor=CENTER, spin=0) {
    check = assert(n>=3 && (n%2)==1);
    r = get_radius(r=r, d=d, dflt=1);
    path = reuleaux_polygon(n=n, r=r);
    anchors = [
        for (i = [0:1:n-1]) let(
            ca = 360 - i * 360/n,
            cp = polar_to_xy(r, ca)
        ) named_anchor(str("tip",i), cp, unit(cp,BACK), 0),
    ];
    attachable(anchor,spin, two_d=true, path=path, extent=false, anchors=anchors) {
        polygon(path);
        children();
    }
}


function reuleaux_polygon(n=3, r, d, anchor=CENTER, spin=0) =
    assert(n>=3 && (n%2)==1)
    let(
        r = get_radius(r=r, d=d, dflt=1),
        ssegs = max(3,ceil(segs(r)/n)),
        slen = norm(polar_to_xy(r,0)-polar_to_xy(r,180-180/n)),
        path = [
            for (i = [0:1:n-1]) let(
                ca = 180 - (i+0.5) * 360/n,
                sa = ca + 180 + (90/n),
                ea = ca + 180 - (90/n),
                cp = polar_to_xy(r, ca)
            ) each arc(n=ssegs-1, r=slen, cp=cp, angle=[sa,ea], endpoint=false)
        ],
        anchors = [
            for (i = [0:1:n-1]) let(
                ca = 360 - i * 360/n,
                cp = polar_to_xy(r, ca)
            ) named_anchor(str("tip",i), cp, unit(cp,BACK), 0),
        ]
    ) reorient(anchor,spin, two_d=true, path=path, extent=false, anchors=anchors, p=path);



// Section: Text

// Module: text()
// Synopsis: Creates an attachable block of text.
// SynTags: Geom
// Topics: Attachments, Text
// See Also: text3d(), attachable()
// Usage:
//   text(text, [size], [font], ...);
// Description:
//   Creates a 3D text block that can be attached to other attachable objects.
//   You cannot attach children to text.
//   .
//   Historically fonts were specified by their "body size", the height of the metal body
//   on which the glyphs were cast.  This means the size was an upper bound on the size
//   of the font glyphs, not a direct measurement of their size.  In digital typesetting,
//   the metal body is replaced by an invisible box, the em square, whose side length is
//   defined to be the font's size.  The glyphs can be contained in that square, or they
//   can extend beyond it, depending on the choices made by the font designer.  As a
//   result, the meaning of font size varies between fonts: two fonts at the "same" size
//   can differ significantly in the actual size of their characters.  Typographers
//   customarily specify the size in the units of "points".  A point is 1/72 inch.  In
//   OpenSCAD, you specify the size in OpenSCAD units (often treated as millimeters for 3d
//   printing), so if you want points you will need to perform a suitable unit conversion.
//   In addition, the OpenSCAD font system has a bug: if you specify size=s you will
//   instead get a font whose size is s/0.72.  For many fonts this means the size of
//   capital letters will be approximately equal to s, because it is common for fonts to
//   use about 70% of their height for the ascenders in the font.  To get the customary
//   font size, you should multiply your desired size by 0.72.
//   .
//   To find the fonts that you have available in your OpenSCAD installation,
//   go to the Help menu and select "Font List".  
// Arguments:
//   text = Text to create.
//   size = The font will be created at this size divided by 0.72.   Default: 10
//   font = Font to use.  Default: "Liberation Sans"
//   ---
//   halign = If given, specifies the horizontal alignment of the text.  `"left"`, `"center"`, or `"right"`.  Overrides `anchor=`.
//   valign = If given, specifies the vertical alignment of the text.  `"top"`, `"center"`, `"baseline"` or `"bottom"`.  Overrides `anchor=`.
//   spacing = The relative spacing multiplier between characters.  Default: `1.0`
//   direction = The text direction.  `"ltr"` for left to right.  `"rtl"` for right to left. `"ttb"` for top to bottom. `"btt"` for bottom to top.  Default: `"ltr"`
//   language = The language the text is in.  Default: `"en"`
//   script = The script the text is in.  Default: `"latin"`
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `"baseline"`
//   spin = Rotate this many degrees around the Z axis.  See [spin](attachments.scad#subsection-spin).  Default: `0`
// Extra Anchors:
//   "baseline" = Anchors at the baseline of the text, at the start of the string.
//   str("baseline",VECTOR) = Anchors at the baseline of the text, modified by the X and Z components of the appended vector.
// Examples(2D):
//   text("Foobar", size=10);
//   text("Foobar", size=12, font="Helvetica");
//   text("Foobar", anchor=CENTER);
//   text("Foobar", anchor=str("baseline",CENTER));
// Example: Using line_copies() distributor
//   txt = "This is the string.";
//   line_copies(spacing=[10,-5],n=len(txt))
//       text(txt[$idx], size=10, anchor=CENTER);
// Example: Using arc_copies() distributor
//   txt = "This is the string";
//   arc_copies(r=50, n=len(txt), sa=0, ea=180)
//       text(select(txt,-1-$idx), size=10, anchor=str("baseline",CENTER), spin=-90);
module text(text, size=10, font="Helvetica", halign, valign, spacing=1.0, direction="ltr", language="en", script="latin", anchor="baseline", spin=0) {
    no_children($children);
    dummy1 =
        assert(is_undef(anchor) || is_vector(anchor) || is_string(anchor), str("Got: ",anchor))
        assert(is_undef(spin)   || is_vector(spin,3) || is_num(spin), str("Got: ",spin));
    anchor = default(anchor, CENTER);
    spin =   default(spin,   0);
    geom = attach_geom(size=[size,size],two_d=true);
    anch = !any([for (c=anchor) c=="["])? anchor :
        let(
            parts = str_split(str_split(str_split(anchor,"]")[0],"[")[1],","),
            vec = [for (p=parts) parse_float(str_strip(p," ",start=true))]
        ) vec;
    ha = halign!=undef? halign :
        anchor=="baseline"? "left" :
        anchor==anch && is_string(anchor)? "center" :
        anch.x<0? "left" :
        anch.x>0? "right" :
        "center";
    va = valign != undef? valign :
        starts_with(anchor,"baseline")? "baseline" :
        anchor==anch && is_string(anchor)? "center" :
        anch.y<0? "bottom" :
        anch.y>0? "top" :
        "center";
    base = anchor=="baseline"? CENTER :
        anchor==anch && is_string(anchor)? CENTER :
        anch.z<0? BOTTOM :
        anch.z>0? TOP :
        CENTER;
    m = _attach_transform(base,spin,undef,geom);
    multmatrix(m) {
        $parent_anchor = anchor;
        $parent_spin   = spin;
        $parent_orient = undef;
        $parent_geom   = geom;
        $parent_size   = _attach_geom_size(geom);
        $attach_to   = undef;
        if (_is_shown()){
            _color($color) {
                _text(
                    text=text, size=size, font=font,
                    halign=ha, valign=va, spacing=spacing,
                    direction=direction, language=language,
                    script=script
                );
            }
        }
    }
}


// Section: Rounding 2D shapes

// Module: round2d()
// Synopsis: Rounds the corners of 2d objects.
// SynTags: Geom
// Topics: Rounding
// See Also: shell2d(), round3d(), minkowski_difference()
// Usage:
//   round2d(r) [ATTACHMENTS];
//   round2d(or=) [ATTACHMENTS];
//   round2d(ir=) [ATTACHMENTS];
//   round2d(or=, ir=) [ATTACHMENTS];
// Description:
//   Rounds arbitrary 2D objects.  Giving `r` rounds all concave and convex corners.  Giving just `ir`
//   rounds just concave corners.  Giving just `or` rounds convex corners.  Giving both `ir` and `or`
//   can let you round to different radii for concave and convex corners.  The 2D object must not have
//   any parts narrower than twice the `or` radius.  Such parts will disappear.
// Arguments:
//   r = Radius to round all concave and convex corners to.
//   ---
//   or = Radius to round only outside (convex) corners to.  Use instead of `r`.
//   ir = Radius to round only inside (concave) corners to.  Use instead of `r`.
// Examples(2D):
//   round2d(r=10) {square([40,100], center=true); square([100,40], center=true);}
//   round2d(or=10) {square([40,100], center=true); square([100,40], center=true);}
//   round2d(ir=10) {square([40,100], center=true); square([100,40], center=true);}
//   round2d(or=16,ir=8) {square([40,100], center=true); square([100,40], center=true);}
module round2d(r, or, ir)
{
    or = get_radius(r1=or, r=r, dflt=0);
    ir = get_radius(r1=ir, r=r, dflt=0);
    offset(or) offset(-ir-or) offset(delta=ir,chamfer=true) children();
}


// Module: shell2d()
// Synopsis: Creates a shell from 2D children.
// SynTags: Geom
// Topics: Shell
// See Also: round2d(), round3d(), minkowski_difference()
// Usage:
//   shell2d(thickness, [or], [ir])
// Description:
//   Creates a hollow shell from 2D children, with optional rounding.
// Arguments:
//   thickness = Thickness of the shell.  Positive to expand outward, negative to shrink inward, or a two-element list to do both.
//   or = Radius to round corners on the outside of the shell.  If given a list of 2 radii, [CONVEX,CONCAVE], specifies the radii for convex and concave corners separately.  Default: 0 (no outside rounding)
//   ir = Radius to round corners on the inside of the shell.  If given a list of 2 radii, [CONVEX,CONCAVE], specifies the radii for convex and concave corners separately.  Default: 0 (no inside rounding)
// Examples(2D):
//   shell2d(10) {square([40,100], center=true); square([100,40], center=true);}
//   shell2d(-10) {square([40,100], center=true); square([100,40], center=true);}
//   shell2d([-10,10]) {square([40,100], center=true); square([100,40], center=true);}
//   shell2d(10,or=10) {square([40,100], center=true); square([100,40], center=true);}
//   shell2d(10,ir=10) {square([40,100], center=true); square([100,40], center=true);}
//   shell2d(10,or=[10,0]) {square([40,100], center=true); square([100,40], center=true);}
//   shell2d(10,or=[0,10]) {square([40,100], center=true); square([100,40], center=true);}
//   shell2d(10,ir=[10,0]) {square([40,100], center=true); square([100,40], center=true);}
//   shell2d(10,ir=[0,10]) {square([40,100], center=true); square([100,40], center=true);}
//   shell2d(8,or=[16,8],ir=[16,8]) {square([40,100], center=true); square([100,40], center=true);}
module shell2d(thickness, or=0, ir=0)
{
    thickness = is_num(thickness)? (
        thickness<0? [thickness,0] : [0,thickness]
    ) : (thickness[0]>thickness[1])? (
        [thickness[1],thickness[0]]
    ) : thickness;
    orad = is_finite(or)? [or,or] : or;
    irad = is_finite(ir)? [ir,ir] : ir;
    difference() {
        round2d(or=orad[0],ir=orad[1])
            offset(delta=thickness[1])
                children();
        round2d(or=irad[1],ir=irad[0])
            offset(delta=thickness[0])
                children();
    }
}


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
