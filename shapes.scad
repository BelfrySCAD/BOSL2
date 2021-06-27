//////////////////////////////////////////////////////////////////////
// LibFile: shapes.scad
//   Common useful shapes and structured objects.
// Includes:
//   include <BOSL2/std.scad>
//////////////////////////////////////////////////////////////////////


// Section: Cuboids

// Module: cuboid()
//
// Usage: Standard Cubes
//   cuboid(size, [anchor=], [spin=], [orient=]);
//   cuboid(size, p1=, ...);
//   cuboid(p1=, p2=, ...);
// Usage: Chamfered Cubes
//   cuboid(size, [chamfer=], [edges=], [except_edges=], [trimcorners=], ...);
// Usage: Rounded Cubes
//   cuboid(size, [rounding=], [edges=], [except_edges=], [trimcorners=], ...);
// Usage: Attaching children
//   cuboid(size, [anchor=], ...) [attachments];
//
// Description:
//   Creates a cube or cuboid object, with optional chamfering or rounding.
//   Negative chamfers and roundings can be applied to create external masks,
//   but only apply to edges around the top or bottom faces.
//
// Arguments:
//   size = The size of the cube.
//   ---
//   chamfer = Size of chamfer, inset from sides.  Default: No chamfering.
//   rounding = Radius of the edge rounding.  Default: No rounding.
//   edges = Edges to chamfer/round.  See the docs for [`edges()`](edges.scad#edges) to see acceptable values.  Default: All edges.
//   except_edges = Edges to explicitly NOT chamfer/round.  See the docs for [`edges()`](edges.scad#edges) to see acceptable values.  Default: No edges.
//   trimcorners = If true, rounds or chamfers corners where three chamfered/rounded edges meet.  Default: `true`
//   p1 = Align the cuboid's corner at `p1`, if given.  Forces `anchor=ALLNEG`.
//   p2 = If given with `p1`, defines the cornerpoints of the cuboid.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards.  See [orient](attachments.scad#orient).  Default: `UP`
//
// Example: Simple regular cube.
//   cuboid(40);
// Example: Cube with minimum cornerpoint given.
//   cuboid(20, p1=[10,0,0]);
// Example: Rectangular cube, with given X, Y, and Z sizes.
//   cuboid([20,40,50]);
// Example: Cube by Opposing Corners.
//   cuboid(p1=[0,10,0], p2=[20,30,30]);
// Example: Chamferred Edges and Corners.
//   cuboid([30,40,50], chamfer=5);
// Example: Chamferred Edges, Untrimmed Corners.
//   cuboid([30,40,50], chamfer=5, trimcorners=false);
// Example: Rounded Edges and Corners
//   cuboid([30,40,50], rounding=10);
// Example: Rounded Edges, Untrimmed Corners
//   cuboid([30,40,50], rounding=10, trimcorners=false);
// Example: Chamferring Selected Edges
//   cuboid(
//       [30,40,50], chamfer=5,
//       edges=[TOP+FRONT,TOP+RIGHT,FRONT+RIGHT],
//       $fn=24
//   );
// Example: Rounding Selected Edges
//   cuboid(
//       [30,40,50], rounding=5,
//       edges=[TOP+FRONT,TOP+RIGHT,FRONT+RIGHT],
//       $fn=24
//   );
// Example: Negative Chamferring
//   cuboid(
//       [30,40,50], chamfer=-5,
//       edges=[TOP,BOT], except_edges=RIGHT,
//       $fn=24
//   );
// Example: Negative Chamferring, Untrimmed Corners
//   cuboid(
//       [30,40,50], chamfer=-5,
//       edges=[TOP,BOT], except_edges=RIGHT,
//       trimcorners=false, $fn=24
//   );
// Example: Negative Rounding
//   cuboid(
//       [30,40,50], rounding=-5,
//       edges=[TOP,BOT], except_edges=RIGHT,
//       $fn=24
//   );
// Example: Negative Rounding, Untrimmed Corners
//   cuboid(
//       [30,40,50], rounding=-5,
//       edges=[TOP,BOT], except_edges=RIGHT,
//       trimcorners=false, $fn=24
//   );
// Example: Standard Connectors
//   cuboid(40) show_anchors();
module cuboid(
    size=[1,1,1],
    p1, p2,
    chamfer,
    rounding,
    edges=EDGES_ALL,
    except_edges=[],
    trimcorners=true,
    anchor=CENTER,
    spin=0,
    orient=UP
) {
    module corner_shape(corner) {
        e = corner_edges(edges, corner);
        cnt = sum(e);
        r = first_defined([chamfer, rounding, 0]);
        c = [min(r,size.x/2), min(r,size.y/2), min(r,size.z/2)];
        c2 = v_mul(corner,c/2);
        $fn = is_finite(chamfer)? 4 : segs(r);
        translate(v_mul(corner, size/2-c)) {
            if (cnt == 0 || approx(r,0)) {
                translate(c2) cube(c, center=true);
            } else if (cnt == 1) {
                if (e.x) right(c2.x) xcyl(l=c.x, r=r);
                if (e.y) back (c2.y) ycyl(l=c.y, r=r);
                if (e.z) up   (c2.z) zcyl(l=c.z, r=r);
            } else if (cnt == 2) {
                if (!e.x) {
                    intersection() {
                        ycyl(l=c.y*2, r=r);
                        zcyl(l=c.z*2, r=r);
                    }
                } else if (!e.y) {
                    intersection() {
                        xcyl(l=c.x*2, r=r);
                        zcyl(l=c.z*2, r=r);
                    }
                } else {
                    intersection() {
                        xcyl(l=c.x*2, r=r);
                        ycyl(l=c.y*2, r=r);
                    }
                }
            } else {
                if (trimcorners) {
                    spheroid(r=r, style="octa");
                } else {
                    intersection() {
                        xcyl(l=c.x*2, r=r);
                        ycyl(l=c.y*2, r=r);
                        zcyl(l=c.z*2, r=r);
                    }
                }
            }
        }
    }

    size = scalar_vec3(size);
    edges = edges(edges, except=except_edges);
    assert(is_vector(size,3));
    assert(all_positive(size));
    assert(is_undef(chamfer) || is_finite(chamfer));
    assert(is_undef(rounding) || is_finite(rounding));
    assert(is_undef(p1) || is_vector(p1));
    assert(is_undef(p2) || is_vector(p2));
    assert(is_bool(trimcorners));
    if (!is_undef(p1)) {
        if (!is_undef(p2)) {
            translate(pointlist_bounds([p1,p2])[0]) {
                cuboid(size=v_abs(p2-p1), chamfer=chamfer, rounding=rounding, edges=edges, trimcorners=trimcorners, anchor=ALLNEG) children();
            }
        } else {
            translate(p1) {
                cuboid(size=size, chamfer=chamfer, rounding=rounding, edges=edges, trimcorners=trimcorners, anchor=ALLNEG) children();
            }
        }
    } else {
        if (is_finite(chamfer)) {
            if (any(edges[0])) assert(chamfer <= size.y/2 && chamfer <=size.z/2, "chamfer must be smaller than half the cube length or height.");
            if (any(edges[1])) assert(chamfer <= size.x/2 && chamfer <=size.z/2, "chamfer must be smaller than half the cube width or height.");
            if (any(edges[2])) assert(chamfer <= size.x/2 && chamfer <=size.y/2, "chamfer must be smaller than half the cube width or length.");
        }
        if (is_finite(rounding)) {
            if (any(edges[0])) assert(rounding <= size.y/2 && rounding<=size.z/2, "rounding radius must be smaller than half the cube length or height.");
            if (any(edges[1])) assert(rounding <= size.x/2 && rounding<=size.z/2, "rounding radius must be smaller than half the cube width or height.");
            if (any(edges[2])) assert(rounding <= size.x/2 && rounding<=size.y/2, "rounding radius must be smaller than half the cube width or length.");
        }
        majrots = [[0,90,0], [90,0,0], [0,0,0]];
        attachable(anchor,spin,orient, size=size) {
            if (is_finite(chamfer) && !approx(chamfer,0)) {
                if (edges == EDGES_ALL && trimcorners) {
                    if (chamfer<0) {
                        cube(size, center=true) {
                            attach(TOP,overlap=0) prismoid([size.x,size.y], [size.x-2*chamfer,size.y-2*chamfer], h=-chamfer, anchor=TOP);
                            attach(BOT,overlap=0) prismoid([size.x,size.y], [size.x-2*chamfer,size.y-2*chamfer], h=-chamfer, anchor=TOP);
                        }
                    } else {
                        isize = [for (v = size) max(0.001, v-2*chamfer)];
                        hull() {
                            cube([ size.x, isize.y, isize.z], center=true);
                            cube([isize.x,  size.y, isize.z], center=true);
                            cube([isize.x, isize.y,  size.z], center=true);
                        }
                    }
                } else if (chamfer<0) {
                    assert(edges == EDGES_ALL || edges[2] == [0,0,0,0], "Cannot use negative chamfer with Z aligned edges.");
                    ach = abs(chamfer);
                    cube(size, center=true);

                    // External-Chamfer mask edges
                    difference() {
                        union() {
                            for (i = [0:3], axis=[0:1]) {
                                if (edges[axis][i]>0) {
                                    vec = EDGE_OFFSETS[axis][i];
                                    translate(v_mul(vec/2, size+[ach,ach,-ach])) {
                                        rotate(majrots[axis]) {
                                            cube([ach, ach, size[axis]], center=true);
                                        }
                                    }
                                }
                            }

                            // Add multi-edge corners.
                            if (trimcorners) {
                                for (za=[-1,1], ya=[-1,1], xa=[-1,1]) {
                                    ce = corner_edges(edges, [xa,ya,za]);
                                    if (ce.x + ce.y > 1) {
                                        translate(v_mul([xa,ya,za]/2, size+[ach-0.01,ach-0.01,-ach])) {
                                            cube([ach+0.01,ach+0.01,ach], center=true);
                                        }
                                    }
                                }
                            }
                        }

                        // Remove bevels from overhangs.
                        for (i = [0:3], axis=[0:1]) {
                            if (edges[axis][i]>0) {
                                vec = EDGE_OFFSETS[axis][i];
                                translate(v_mul(vec/2, size+[2*ach,2*ach,-2*ach])) {
                                    rotate(majrots[axis]) {
                                        zrot(45) cube([ach*sqrt(2), ach*sqrt(2), size[axis]+2.1*ach], center=true);
                                    }
                                }
                            }
                        }
                    }
                } else {
                    hull() {
                        corner_shape([-1,-1,-1]);
                        corner_shape([ 1,-1,-1]);
                        corner_shape([-1, 1,-1]);
                        corner_shape([ 1, 1,-1]);
                        corner_shape([-1,-1, 1]);
                        corner_shape([ 1,-1, 1]);
                        corner_shape([-1, 1, 1]);
                        corner_shape([ 1, 1, 1]);
                    }
                }
            } else if (is_finite(rounding) && !approx(rounding,0)) {
                sides = quantup(segs(rounding),4);
                if (edges == EDGES_ALL) {
                    if(rounding<0) {
                        cube(size, center=true);
                        zflip_copy() {
                            up(size.z/2) {
                                difference() {
                                    down(-rounding/2) cube([size.x-2*rounding, size.y-2*rounding, -rounding], center=true);
                                    down(-rounding) {
                                        ycopies(size.y-2*rounding) xcyl(l=size.x-3*rounding, r=-rounding);
                                        xcopies(size.x-2*rounding) ycyl(l=size.y-3*rounding, r=-rounding);
                                    }
                                }
                            }
                        }
                    } else {
                        isize = [for (v = size) max(0.001, v-2*rounding)];
                        minkowski() {
                            cube(isize, center=true);
                            if (trimcorners) {
                                spheroid(r=rounding, style="octa", $fn=sides);
                            } else {
                                intersection() {
                                    cyl(r=rounding, h=rounding*2, $fn=sides);
                                    rotate([90,0,0]) cyl(r=rounding, h=rounding*2, $fn=sides);
                                    rotate([0,90,0]) cyl(r=rounding, h=rounding*2, $fn=sides);
                                }
                            }
                        }
                    }
                } else if (rounding<0) {
                    assert(edges == EDGES_ALL || edges[2] == [0,0,0,0], "Cannot use negative rounding with Z aligned edges.");
                    ard = abs(rounding);
                    cube(size, center=true);

                    // External-Rounding mask edges
                    difference() {
                        union() {
                            for (i = [0:3], axis=[0:1]) {
                                if (edges[axis][i]>0) {
                                    vec = EDGE_OFFSETS[axis][i];
                                    translate(v_mul(vec/2, size+[ard,ard,-ard])) {
                                        rotate(majrots[axis]) {
                                            cube([ard, ard, size[axis]], center=true);
                                        }
                                    }
                                }
                            }

                            // Add multi-edge corners.
                            if (trimcorners) {
                                for (za=[-1,1], ya=[-1,1], xa=[-1,1]) {
                                    ce = corner_edges(edges, [xa,ya,za]);
                                    if (ce.x + ce.y > 1) {
                                        translate(v_mul([xa,ya,za]/2, size+[ard-0.01,ard-0.01,-ard])) {
                                            cube([ard+0.01,ard+0.01,ard], center=true);
                                        }
                                    }
                                }
                            }
                        }

                        // Remove roundings from overhangs.
                        for (i = [0:3], axis=[0:1]) {
                            if (edges[axis][i]>0) {
                                vec = EDGE_OFFSETS[axis][i];
                                translate(v_mul(vec/2, size+[2*ard,2*ard,-2*ard])) {
                                    rotate(majrots[axis]) {
                                        cyl(l=size[axis]+2.1*ard, r=ard);
                                    }
                                }
                            }
                        }
                    }
                } else {
                    hull() {
                        corner_shape([-1,-1,-1]);
                        corner_shape([ 1,-1,-1]);
                        corner_shape([-1, 1,-1]);
                        corner_shape([ 1, 1,-1]);
                        corner_shape([-1,-1, 1]);
                        corner_shape([ 1,-1, 1]);
                        corner_shape([-1, 1, 1]);
                        corner_shape([ 1, 1, 1]);
                    }
                }
            } else {
                cube(size=size, center=true);
            }
            children();
        }
    }
}


function cuboid(
    size=[1,1,1],
    p1, p2,
    chamfer,
    rounding,
    edges=EDGES_ALL,
    except_edges=[],
    trimcorners=true,
    anchor=CENTER,
    spin=0,
    orient=UP
) = no_function("cuboid");



// Section: Prismoids


// Function&Module: prismoid()
//
// Usage: Typical Prismoids
//   prismoid(size1, size2, h|l, [shift], ...);
// Usage: Attaching Children
//   prismoid(size1, size2, h|l, [shift], ...) [attachments];
// Usage: Chamfered Prismoids
//   prismoid(size1, size2, h|l, [chamfer=], ...);
//   prismoid(size1, size2, h|l, [chamfer1=], [chamfer2=], ...);
// Usage: Rounded Prismoids
//   prismoid(size1, size2, h|l, [rounding=], ...);
//   prismoid(size1, size2, h|l, [rounding1=], [rounding2=], ...);
// Usage: As Function
//   vnf = prismoid(size1, size2, h|l, [shift], [rounding], [chamfer]);
//   vnf = prismoid(size1, size2, h|l, [shift], [rounding1], [rounding2], [chamfer1], [chamfer2]);
//
// Description:
//   Creates a rectangular prismoid shape with optional roundovers and chamfering.
//   You can only round or chamfer the vertical(ish) edges.  For those edges, you can
//   specify rounding and/or chamferring per-edge, and for top and bottom separately.
//
// Arguments:
//   size1 = [width, length] of the bottom end of the prism.
//   size2 = [width, length] of the top end of the prism.
//   h|l = Height of the prism.
//   shift = [X,Y] amount to shift the center of the top end with respect to the center of the bottom end.
//   ---
//   rounding = The roundover radius for the vertical-ish edges of the prismoid.  If given as a list of four numbers, gives individual radii for each corner, in the order [X+Y+,X-Y+,X-Y-,X+Y-]. Default: 0 (no rounding)
//   rounding1 = The roundover radius for the bottom of the vertical-ish edges of the prismoid.  If given as a list of four numbers, gives individual radii for each corner, in the order [X+Y+,X-Y+,X-Y-,X+Y-].
//   rounding2 = The roundover radius for the top of the vertical-ish edges of the prismoid.  If given as a list of four numbers, gives individual radii for each corner, in the order [X+Y+,X-Y+,X-Y-,X+Y-].
//   chamfer = The chamfer size for the vertical-ish edges of the prismoid.  If given as a list of four numbers, gives individual chamfers for each corner, in the order [X+Y+,X-Y+,X-Y-,X+Y-].  Default: 0 (no chamfer)
//   chamfer1 = The chamfer size for the bottom of the vertical-ish edges of the prismoid.  If given as a list of four numbers, gives individual chamfers for each corner, in the order [X+Y+,X-Y+,X-Y-,X+Y-].
//   chamfer2 = The chamfer size for the top of the vertical-ish edges of the prismoid.  If given as a list of four numbers, gives individual chamfers for each corner, in the order [X+Y+,X-Y+,X-Y-,X+Y-].
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
//
// See Also: rounded_prism()
//
// Example: Rectangular Pyramid
//   prismoid([40,40], [0,0], h=20);
// Example: Prism
//   prismoid(size1=[40,40], size2=[0,40], h=20);
// Example: Truncated Pyramid
//   prismoid(size1=[35,50], size2=[20,30], h=20);
// Example: Wedge
//   prismoid(size1=[60,35], size2=[30,0], h=30);
// Example: Truncated Tetrahedron
//   prismoid(size1=[10,40], size2=[40,10], h=40);
// Example: Inverted Truncated Pyramid
//   prismoid(size1=[15,5], size2=[30,20], h=20);
// Example: Right Prism
//   prismoid(size1=[30,60], size2=[0,60], shift=[-15,0], h=30);
// Example(FlatSpin,VPD=160,VPT=[0,0,10]): Shifting/Skewing
//   prismoid(size1=[50,30], size2=[20,20], h=20, shift=[15,5]);
// Example: Rounding
//   prismoid(100, 80, rounding=10, h=30);
// Example: Outer Chamfer Only
//   prismoid(100, 80, chamfer=5, h=30);
// Example: Gradiant Rounding
//   prismoid(100, 80, rounding1=10, rounding2=0, h=30);
// Example: Per Corner Rounding
//   prismoid(100, 80, rounding=[0,5,10,15], h=30);
// Example: Per Corner Chamfer
//   prismoid(100, 80, chamfer=[0,5,10,15], h=30);
// Example: Mixing Chamfer and Rounding
//   prismoid(
//       100, 80, h=30,
//       chamfer=[0,5,0,10],
//       rounding=[5,0,10,0]
//   );
// Example: Really Mixing It Up
//   prismoid(
//       size1=[100,80], size2=[80,60], h=20,
//       chamfer1=[0,5,0,10], chamfer2=[5,0,10,0],
//       rounding1=[5,0,10,0], rounding2=[0,5,0,10]
//   );
// Example(Spin,VPD=160,VPT=[0,0,10]): Standard Connectors
//   prismoid(size1=[50,30], size2=[20,20], h=20, shift=[15,5])
//       show_anchors();
module prismoid(
    size1, size2, h, shift=[0,0],
    rounding=0, rounding1, rounding2,
    chamfer=0, chamfer1, chamfer2,
    l, center,
    anchor, spin=0, orient=UP
) {
    assert(is_num(size1) || is_vector(size1,2));
    assert(is_num(size2) || is_vector(size2,2));
    assert(is_num(h) || is_num(l));
    assert(is_vector(shift,2));
    assert(is_num(rounding) || is_vector(rounding,4), "Bad rounding argument.");
    assert(is_undef(rounding1) || is_num(rounding1) || is_vector(rounding1,4), "Bad rounding1 argument.");
    assert(is_undef(rounding2) || is_num(rounding2) || is_vector(rounding2,4), "Bad rounding2 argument.");
    assert(is_num(chamfer) || is_vector(chamfer,4), "Bad chamfer argument.");
    assert(is_undef(chamfer1) || is_num(chamfer1) || is_vector(chamfer1,4), "Bad chamfer1 argument.");
    assert(is_undef(chamfer2) || is_num(chamfer2) || is_vector(chamfer2,4), "Bad chamfer2 argument.");
    eps = pow(2,-14);
    size1 = is_num(size1)? [size1,size1] : size1;
    size2 = is_num(size2)? [size2,size2] : size2;
    assert(all_nonnegative(size1));
    assert(all_nonnegative(size2));
    assert(size1.x + size2.x > 0);
    assert(size1.y + size2.y > 0);
    s1 = [max(size1.x, eps), max(size1.y, eps)];
    s2 = [max(size2.x, eps), max(size2.y, eps)];
    rounding1 = default(rounding1, rounding);
    rounding2 = default(rounding2, rounding);
    chamfer1 = default(chamfer1, chamfer);
    chamfer2 = default(chamfer2, chamfer);
    anchor = get_anchor(anchor, center, BOT, BOT);
    vnf = prismoid(
        size1=size1, size2=size2, h=h, shift=shift,
        rounding1=rounding1, rounding2=rounding2,
        chamfer1=chamfer1, chamfer2=chamfer2,
        l=l, center=CENTER
    );
    attachable(anchor,spin,orient, size=[s1.x,s1.y,h], size2=s2, shift=shift) {
        vnf_polyhedron(vnf, convexity=4);
        children();
    }
}

function prismoid(
    size1, size2, h, shift=[0,0],
    rounding=0, rounding1, rounding2,
    chamfer=0, chamfer1, chamfer2,
    l, center,
    anchor=DOWN, spin=0, orient=UP
) =
    assert(is_vector(size1,2))
    assert(is_vector(size2,2))
    assert(is_num(h) || is_num(l))
    assert(is_vector(shift,2))
    assert(
        (is_num(rounding) && rounding>=0) ||
        (is_vector(rounding,4) && all_nonnegative(rounding)),
        "Bad rounding argument."
    )
    assert(
        is_undef(rounding1) || (is_num(rounding1) && rounding1>=0) ||
        (is_vector(rounding1,4) && all_nonnegative(rounding1)),
        "Bad rounding1 argument."
    )
    assert(
        is_undef(rounding2) || (is_num(rounding2) && rounding2>=0) ||
        (is_vector(rounding2,4) && all_nonnegative(rounding2)),
        "Bad rounding2 argument."
    )
    assert(
        (is_num(chamfer) && chamfer>=0) ||
        (is_vector(chamfer,4) && all_nonnegative(chamfer)),
        "Bad chamfer argument."
    )
    assert(
        is_undef(chamfer1) || (is_num(chamfer1) && chamfer1>=0) ||
        (is_vector(chamfer1,4) && all_nonnegative(chamfer1)),
        "Bad chamfer1 argument."
    )
    assert(
        is_undef(chamfer2) || (is_num(chamfer2) && chamfer2>=0) ||
        (is_vector(chamfer2,4) && all_nonnegative(chamfer2)),
        "Bad chamfer2 argument."
    )
    let(
        eps = pow(2,-14),
        h = first_defined([h,l,1]),
        shiftby = point3d(point2d(shift)),
        s1 = [max(size1.x, eps), max(size1.y, eps)],
        s2 = [max(size2.x, eps), max(size2.y, eps)],
        rounding1 = default(rounding1, rounding),
        rounding2 = default(rounding2, rounding),
        chamfer1 = default(chamfer1, chamfer),
        chamfer2 = default(chamfer2, chamfer),
        anchor = get_anchor(anchor, center, BOT, BOT),
        vnf = (rounding1==0 && rounding2==0 && chamfer1==0 && chamfer2==0)? (
            let(
                corners = [[1,1],[1,-1],[-1,-1],[-1,1]] * 0.5,
                points = [
                    for (p=corners) point3d(v_mul(s2,p), +h/2) + shiftby,
                    for (p=corners) point3d(v_mul(s1,p), -h/2)
                ],
                faces=[
                    [0,1,2], [0,2,3], [0,4,5], [0,5,1],
                    [1,5,6], [1,6,2], [2,6,7], [2,7,3],
                    [3,7,4], [3,4,0], [4,7,6], [4,6,5],
                ]
            ) [points, faces]
        ) : (
            let(
                path1 = rect(size1, rounding=rounding1, chamfer=chamfer1, anchor=CTR),
                path2 = rect(size2, rounding=rounding2, chamfer=chamfer2, anchor=CTR),
                points = [
                    each path3d(path1, -h/2),
                    each path3d(move(shiftby, p=path2), +h/2),
                ],
                faces = hull(points)
            ) [points, faces]
        )
    ) reorient(anchor,spin,orient, size=[s1.x,s1.y,h], size2=s2, shift=shift, p=vnf);


// Module: rect_tube()
// Usage: Typical Rectangular Tubes
//   rect_tube(h, size, isize, [center], [shift]);
//   rect_tube(h, size, wall=, [center=]);
//   rect_tube(h, isize=, wall=, [center=]);
// Usage: Tapering Rectangular Tubes
//   rect_tube(h, size1=, size2=, wall=, ...);
//   rect_tube(h, isize1=, isize2=, wall=, ...);
//   rect_tube(h, size1=, size2=, isize1=, isize2=, ...);
// Usage: Chamfered
//   rect_tube(h, size, isize, chamfer=, ...);
//   rect_tube(h, size, isize, chamfer1=, chamfer2= ...);
//   rect_tube(h, size, isize, ichamfer=, ...);
//   rect_tube(h, size, isize, ichamfer1=, ichamfer2= ...);
//   rect_tube(h, size, isize, chamfer=, ichamfer=, ...);
// Usage: Rounded
//   rect_tube(h, size, isize, rounding=, ...);
//   rect_tube(h, size, isize, rounding1=, rounding2= ...);
//   rect_tube(h, size, isize, irounding=, ...);
//   rect_tube(h, size, isize, irounding1=, irounding2= ...);
//   rect_tube(h, size, isize, rounding=, irounding=, ...);
// Usage: Attaching Children
//   rect_tube(h, size, isize, ...) [attachments];
//
// Description:
//   Creates a rectangular or prismoid tube with optional roundovers and/or chamfers.
//   You can only round or chamfer the vertical(ish) edges.  For those edges, you can
//   specify rounding and/or chamferring per-edge, and for top and bottom, inside and
//   outside  separately.
// Arguments:
//   h|l = The height or length of the rectangular tube.  Default: 1
//   size = The outer [X,Y] size of the rectangular tube.
//   isize = The inner [X,Y] size of the rectangular tube.
//   center = If given, overrides `anchor`.  A true value sets `anchor=CENTER`, false sets `anchor=UP`.
//   shift = [X,Y] amount to shift the center of the top end with respect to the center of the bottom end.
//   ---
//   wall = The thickness of the rectangular tube wall.
//   size1 = The [X,Y] size of the outside of the bottom of the rectangular tube.
//   size2 = The [X,Y] size of the outside of the top of the rectangular tube.
//   isize1 = The [X,Y] size of the inside of the bottom of the rectangular tube.
//   isize2 = The [X,Y] size of the inside of the top of the rectangular tube.
//   rounding = The roundover radius for the outside edges of the rectangular tube.
//   rounding1 = The roundover radius for the outside bottom corner of the rectangular tube.
//   rounding2 = The roundover radius for the outside top corner of the rectangular tube.
//   chamfer = The chamfer size for the outside edges of the rectangular tube.
//   chamfer1 = The chamfer size for the outside bottom corner of the rectangular tube.
//   chamfer2 = The chamfer size for the outside top corner of the rectangular tube.
//   irounding = The roundover radius for the inside edges of the rectangular tube. Default: Same as `rounding`
//   irounding1 = The roundover radius for the inside bottom corner of the rectangular tube.
//   irounding2 = The roundover radius for the inside top corner of the rectangular tube.
//   ichamfer = The chamfer size for the inside edges of the rectangular tube.  Default: Same as `chamfer`
//   ichamfer1 = The chamfer size for the inside bottom corner of the rectangular tube.
//   ichamfer2 = The chamfer size for the inside top corner of the rectangular tube.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `BOTTOM`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
// Examples:
//   rect_tube(size=50, wall=5, h=30);
//   rect_tube(size=[100,60], wall=5, h=30);
//   rect_tube(isize=[60,80], wall=5, h=30);
//   rect_tube(size=[100,60], isize=[90,50], h=30);
//   rect_tube(size1=[100,60], size2=[70,40], wall=5, h=30);
// Example:
//   rect_tube(
//       size1=[100,60], size2=[70,40],
//       isize1=[40,20], isize2=[65,35], h=15
//   );
// Example: Outer Rounding Only
//   rect_tube(size=100, wall=5, rounding=10, irounding=0, h=30);
// Example: Outer Chamfer Only
//   rect_tube(size=100, wall=5, chamfer=5, ichamfer=0, h=30);
// Example: Outer Rounding, Inner Chamfer
//   rect_tube(size=100, wall=5, rounding=10, ichamfer=8, h=30);
// Example: Inner Rounding, Outer Chamfer
//   rect_tube(size=100, wall=5, chamfer=10, irounding=8, h=30);
// Example: Gradiant Rounding
//   rect_tube(
//       size1=100, size2=80, wall=5, h=30,
//       rounding1=10, rounding2=0,
//       irounding1=8, irounding2=0
//   );
// Example: Per Corner Rounding
//   rect_tube(
//       size=100, wall=10, h=30,
//       rounding=[0,5,10,15], irounding=0
//   );
// Example: Per Corner Chamfer
//   rect_tube(
//       size=100, wall=10, h=30,
//       chamfer=[0,5,10,15], ichamfer=0
//   );
// Example: Mixing Chamfer and Rounding
//   rect_tube(
//       size=100, wall=10, h=30,
//       chamfer=[0,5,0,10], ichamfer=0,
//       rounding=[5,0,10,0], irounding=0
//   );
// Example: Really Mixing It Up
//   rect_tube(
//       size1=[100,80], size2=[80,60],
//       isize1=[50,30], isize2=[70,50], h=20,
//       chamfer1=[0,5,0,10], ichamfer1=[0,3,0,8],
//       chamfer2=[5,0,10,0], ichamfer2=[3,0,8,0],
//       rounding1=[5,0,10,0], irounding1=[3,0,8,0],
//       rounding2=[0,5,0,10], irounding2=[0,3,0,8]
//   );
module rect_tube(
    h, size, isize, center, shift=[0,0],
    wall, size1, size2, isize1, isize2,
    rounding=0, rounding1, rounding2,
    irounding=0, irounding1, irounding2,
    chamfer=0, chamfer1, chamfer2,
    ichamfer=0, ichamfer1, ichamfer2,
    anchor, spin=0, orient=UP,
    l
) {
    h = one_defined([h,l],"h,l");
    assert(is_num(h), "l or h argument required.");
    assert(is_vector(shift,2));
    s1 = is_num(size1)? [size1, size1] :
        is_vector(size1,2)? size1 :
        is_num(size)? [size, size] :
        is_vector(size,2)? size :
        undef;
    s2 = is_num(size2)? [size2, size2] :
        is_vector(size2,2)? size2 :
        is_num(size)? [size, size] :
        is_vector(size,2)? size :
        undef;
    is1 = is_num(isize1)? [isize1, isize1] :
        is_vector(isize1,2)? isize1 :
        is_num(isize)? [isize, isize] :
        is_vector(isize,2)? isize :
        undef;
    is2 = is_num(isize2)? [isize2, isize2] :
        is_vector(isize2,2)? isize2 :
        is_num(isize)? [isize, isize] :
        is_vector(isize,2)? isize :
        undef;
    size1 = is_def(s1)? s1 :
        (is_def(wall) && is_def(is1))? (is1+2*[wall,wall]) :
        undef;
    size2 = is_def(s2)? s2 :
        (is_def(wall) && is_def(is2))? (is2+2*[wall,wall]) :
        undef;
    isize1 = is_def(is1)? is1 :
        (is_def(wall) && is_def(s1))? (s1-2*[wall,wall]) :
        undef;
    isize2 = is_def(is2)? is2 :
        (is_def(wall) && is_def(s2))? (s2-2*[wall,wall]) :
        undef;
    assert(wall==undef || is_num(wall));
    assert(size1!=undef, "Bad size/size1 argument.");
    assert(size2!=undef, "Bad size/size2 argument.");
    assert(isize1!=undef, "Bad isize/isize1 argument.");
    assert(isize2!=undef, "Bad isize/isize2 argument.");
    assert(isize1.x < size1.x, "Inner size is larger than outer size.");
    assert(isize1.y < size1.y, "Inner size is larger than outer size.");
    assert(isize2.x < size2.x, "Inner size is larger than outer size.");
    assert(isize2.y < size2.y, "Inner size is larger than outer size.");
    anchor = get_anchor(anchor, center, BOT, BOT);
    attachable(anchor,spin,orient, size=[each size1, h], size2=size2, shift=shift) {
        diff("_H_o_L_e_")
        prismoid(
            size1, size2, h=h, shift=shift,
            rounding=rounding, rounding1=rounding1, rounding2=rounding2,
            chamfer=chamfer, chamfer1=chamfer1, chamfer2=chamfer2,
            anchor=CTR
        ) {
            children();
            tags("_H_o_L_e_") prismoid(
                isize1, isize2, h=h+0.05, shift=shift,
                rounding=irounding, rounding1=irounding1, rounding2=irounding2,
                chamfer=ichamfer, chamfer1=ichamfer1, chamfer2=ichamfer2,
                anchor=CTR
            );
        }
        children();
    }
}

function rect_tube(
    h, size, isize, center, shift=[0,0],
    wall, size1, size2, isize1, isize2,
    rounding=0, rounding1, rounding2,
    irounding=0, irounding1, irounding2,
    chamfer=0, chamfer1, chamfer2,
    ichamfer=0, ichamfer1, ichamfer2,
    anchor, spin=0, orient=UP,
    l
) = no_function("rect_tube");


// Module: right_triangle()
//
// Usage:
//   right_triangle(size, [center]);
//
// Description:
//   Creates a 3D right triangular prism with the hypotenuse in the X+Y+ quadrant.
//
// Arguments:
//   size = [width, thickness, height]
//   center = If given, overrides `anchor`.  A true value sets `anchor=CENTER`, false sets `anchor=UP`.
//   ---
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `ALLNEG`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
//
// Example: Centered
//   right_triangle([60, 40, 10], center=true);
// Example: *Non*-Centered
//   right_triangle([60, 40, 10]);
// Example: Standard Connectors
//   right_triangle([60, 40, 15]) show_anchors();
module right_triangle(size=[1, 1, 1], center, anchor, spin=0, orient=UP)
{
    size = scalar_vec3(size);
    anchor = get_anchor(anchor, center, ALLNEG, ALLNEG);
    attachable(anchor,spin,orient, size=size) {
        if (size.z > 0) {
            linear_extrude(height=size.z, convexity=2, center=true) {
                polygon([[-size.x/2,-size.y/2], [-size.x/2,size.y/2], [size.x/2,-size.y/2]]);
            }
        }
        children();
    }
}


function right_triangle(size=[1,1,1], center, anchor, spin=0, orient=UP) =
    no_function("right_triangle");


// Section: Cylindroids


// Module: cyl()
//
// Description:
//   Creates cylinders in various anchorings and orientations, with optional rounding and chamfers.
//   You can use `h` and `l` interchangably, and all variants allow specifying size by either `r`|`d`,
//   or `r1`|`d1` and `r2`|`d2`.  Note: the chamfers and rounding cannot be cumulatively longer than
//   the cylinder's length.
//
// Usage: Normal Cylinders
//   cyl(l|h, r, [center], [circum=], [realign=]);
//   cyl(l|h, d=, ...);
//   cyl(l|h, r1=, r2=, ...);
//   cyl(l|h, d1=, d2=, ...);
//
// Usage: Chamferred Cylinders
//   cyl(l|h, r|d, chamfer=, [chamfang=], [from_end=], ...);
//   cyl(l|h, r|d, chamfer1=, [chamfang1=], [from_end=], ...);
//   cyl(l|h, r|d, chamfer2=, [chamfang2=], [from_end=], ...);
//   cyl(l|h, r|d, chamfer1=, chamfer2=, [chamfang1=], [chamfang2=], [from_end=], ...);
//
// Usage: Rounded End Cylinders
//   cyl(l|h, r|d, rounding=, ...);
//   cyl(l|h, r|d, rounding1=, ...);
//   cyl(l|h, r|d, rounding2=, ...);
//   cyl(l|h, r|d, rounding1=, rounding2=, ...);
//
// Arguments:
//   l / h = Length of cylinder along oriented axis.  Default: 1
//   r = Radius of cylinder.  Default: 1
//   center = If given, overrides `anchor`.  A true value sets `anchor=CENTER`, false sets `anchor=DOWN`.
//   ---
//   r1 = Radius of the negative (X-, Y-, Z-) end of cylinder.
//   r2 = Radius of the positive (X+, Y+, Z+) end of cylinder.
//   d = Diameter of cylinder.
//   d1 = Diameter of the negative (X-, Y-, Z-) end of cylinder.
//   d2 = Diameter of the positive (X+, Y+, Z+) end of cylinder.
//   circum = If true, cylinder should circumscribe the circle of the given size.  Otherwise inscribes.  Default: `false`
//   chamfer = The size of the chamfers on the ends of the cylinder.  Default: none.
//   chamfer1 = The size of the chamfer on the bottom end of the cylinder.  Default: none.
//   chamfer2 = The size of the chamfer on the top end of the cylinder.  Default: none.
//   chamfang = The angle in degrees of the chamfers on the ends of the cylinder.
//   chamfang1 = The angle in degrees of the chamfer on the bottom end of the cylinder.
//   chamfang2 = The angle in degrees of the chamfer on the top end of the cylinder.
//   from_end = If true, chamfer is measured from the end of the cylinder, instead of inset from the edge.  Default: `false`.
//   rounding = The radius of the rounding on the ends of the cylinder.  Default: none.
//   rounding1 = The radius of the rounding on the bottom end of the cylinder.
//   rounding2 = The radius of the rounding on the top end of the cylinder.
//   realign = If true, rotate the cylinder by half the angle of one face.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
//
// Example: By Radius
//   xdistribute(30) {
//       cyl(l=40, r=10);
//       cyl(l=40, r1=10, r2=5);
//   }
//
// Example: By Diameter
//   xdistribute(30) {
//       cyl(l=40, d=25);
//       cyl(l=40, d1=25, d2=10);
//   }
//
// Example: Chamferring
//   xdistribute(60) {
//       // Shown Left to right.
//       cyl(l=40, d=40, chamfer=7);  // Default chamfang=45
//       cyl(l=40, d=40, chamfer=7, chamfang=30, from_end=false);
//       cyl(l=40, d=40, chamfer=7, chamfang=30, from_end=true);
//   }
//
// Example: Rounding
//   cyl(l=40, d=40, rounding=10);
//
// Example: Heterogenous Chamfers and Rounding
//   ydistribute(80) {
//       // Shown Front to Back.
//       cyl(l=40, d=40, rounding1=15, orient=UP);
//       cyl(l=40, d=40, chamfer2=5, orient=UP);
//       cyl(l=40, d=40, chamfer1=12, rounding2=10, orient=UP);
//   }
//
// Example: Putting it all together
//   cyl(
//       l=40, d1=25, d2=15,
//       chamfer1=10, chamfang1=30,
//       from_end=true, rounding2=5
//   );
//
// Example: External Chamfers
//   cyl(l=50, r=30, chamfer=-5, chamfang=30, $fa=1, $fs=1);
//
// Example: External Roundings
//   cyl(l=50, r=30, rounding1=-5, rounding2=5, $fa=1, $fs=1);
//
// Example: Standard Connectors
//   xdistribute(40) {
//       cyl(l=30, d=25) show_anchors();
//       cyl(l=30, d1=25, d2=10) show_anchors();
//   }
//
module cyl(
    h, r, center,
    l, r1, r2,
    d, d1, d2,
    chamfer, chamfer1, chamfer2,
    chamfang, chamfang1, chamfang2,
    rounding, rounding1, rounding2,
    circum=false, realign=false, from_end=false,
    anchor, spin=0, orient=UP
) {
    l = first_defined([l, h, 1]);
    _r1 = get_radius(r1=r1, r=r, d1=d1, d=d, dflt=1);
    _r2 = get_radius(r1=r2, r=r, d1=d2, d=d, dflt=1);
    sides = segs(max(_r1,_r2));
    sc = circum? 1/cos(180/sides) : 1;
    r1=_r1*sc;
    r2=_r2*sc;
    phi = atan2(l, r2-r1);
    anchor = get_anchor(anchor,center,BOT,CENTER);
    attachable(anchor,spin,orient, r1=r1, r2=r2, l=l) {
        zrot(realign? 180/sides : 0) {
            if (!any_defined([chamfer, chamfer1, chamfer2, rounding, rounding1, rounding2])) {
                cylinder(h=l, r1=r1, r2=r2, center=true, $fn=sides);
            } else {
                vang = atan2(l, r1-r2)/2;
                chang1 = 90-first_defined([chamfang1, chamfang, vang]);
                chang2 = 90-first_defined([chamfang2, chamfang, 90-vang]);
                cham1 = u_mul(first_defined([chamfer1, chamfer]) , (from_end? 1 : tan(chang1)));
                cham2 = u_mul(first_defined([chamfer2, chamfer]) , (from_end? 1 : tan(chang2)));
                fil1 = first_defined([rounding1, rounding]);
                fil2 = first_defined([rounding2, rounding]);
                if (chamfer != undef) {
                    assert(chamfer <= r1,  "chamfer is larger than the r1 radius of the cylinder.");
                    assert(chamfer <= r2,  "chamfer is larger than the r2 radius of the cylinder.");
                }
                if (cham1 != undef) {
                    assert(cham1 <= r1,  "chamfer1 is larger than the r1 radius of the cylinder.");
                }
                if (cham2 != undef) {
                    assert(cham2 <= r2,  "chamfer2 is larger than the r2 radius of the cylinder.");
                }
                if (rounding != undef) {
                    assert(rounding <= r1,  "rounding is larger than the r1 radius of the cylinder.");
                    assert(rounding <= r2,  "rounding is larger than the r2 radius of the cylinder.");
                }
                if (fil1 != undef) {
                    assert(fil1 <= r1,  "rounding1 is larger than the r1 radius of the cylinder.");
                }
                if (fil2 != undef) {
                    assert(fil2 <= r2,  "rounding2 is larger than the r1 radius of the cylinder.");
                }
                dy1 = abs(first_defined([cham1, fil1, 0]));
                dy2 = abs(first_defined([cham2, fil2, 0]));
                assert(dy1+dy2 <= l, "Sum of fillets and chamfer sizes must be less than the length of the cylinder.");

                path = concat(
                    [[0,l/2]],

                    !is_undef(cham2)? (
                        let(
                            p1 = [r2-cham2/tan(chang2),l/2],
                            p2 = lerp([r2,l/2],[r1,-l/2],abs(cham2)/l)
                        ) [p1,p2]
                    ) : !is_undef(fil2)? (
                        let(
                            cn = circle_2tangents([r2-fil2,l/2], [r2,l/2], [r1,-l/2], r=abs(fil2)),
                            ang = fil2<0? phi : phi-180,
                            steps = ceil(abs(ang)/360*segs(abs(fil2))),
                            step = ang/steps,
                            pts = [for (i=[0:1:steps]) let(a=90+i*step) cn[0]+abs(fil2)*[cos(a),sin(a)]]
                        ) pts
                    ) : [[r2,l/2]],

                    !is_undef(cham1)? (
                        let(
                            p1 = lerp([r1,-l/2],[r2,l/2],abs(cham1)/l),
                            p2 = [r1-cham1/tan(chang1),-l/2]
                        ) [p1,p2]
                    ) : !is_undef(fil1)? (
                        let(
                            cn = circle_2tangents([r1-fil1,-l/2], [r1,-l/2], [r2,l/2], r=abs(fil1)),
                            ang = fil1<0? 180-phi : -phi,
                            steps = ceil(abs(ang)/360*segs(abs(fil1))),
                            step = ang/steps,
                            pts = [for (i=[0:1:steps]) let(a=(fil1<0?180:0)+(phi-90)+i*step) cn[0]+abs(fil1)*[cos(a),sin(a)]]
                        ) pts
                    ) : [[r1,-l/2]],

                    [[0,-l/2]]
                );
                rotate_extrude(convexity=2) {
                    polygon(path);
                }
            }
        }
        children();
    }
}



// Module: xcyl()
//
// Description:
//   Creates a cylinder oriented along the X axis.
//
// Usage: Typical
//   xcyl(l|h, r, [anchor=]);
//   xcyl(l|h, d=, [anchor=]);
//   xcyl(l|h, r1=|d1=, r2=|d2=, [anchor=]);
// Usage: Attaching Children
//   xcyl(l|h, r, [anchor=]) [attachments];
//
// Arguments:
//   l / h = Length of cylinder along oriented axis. Default: 1
//   r = Radius of cylinder.  Default: 1
//   ---
//   r1 = Optional radius of left (X-) end of cylinder.
//   r2 = Optional radius of right (X+) end of cylinder.
//   d = Optional diameter of cylinder. (use instead of `r`)
//   d1 = Optional diameter of left (X-) end of cylinder.
//   d2 = Optional diameter of right (X+) end of cylinder.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//
// Example: By Radius
//   ydistribute(50) {
//       xcyl(l=35, r=10);
//       xcyl(l=35, r1=15, r2=5);
//   }
//
// Example: By Diameter
//   ydistribute(50) {
//       xcyl(l=35, d=20);
//       xcyl(l=35, d1=30, d2=10);
//   }
module xcyl(h, r, d, r1, r2, d1, d2, l, anchor=CENTER)
{
    r1 = get_radius(r1=r1, r=r, d1=d1, d=d, dflt=1);
    r2 = get_radius(r1=r2, r=r, d1=d2, d=d, dflt=1);
    l = first_defined([l, h, 1]);
    attachable(anchor,0,UP, r1=r1, r2=r2, l=l, axis=RIGHT) {
        cyl(l=l, r1=r1, r2=r2, orient=RIGHT, anchor=CENTER);
        children();
    }
}



// Module: ycyl()
//
// Description:
//   Creates a cylinder oriented along the Y axis.
//
// Usage: Typical
//   ycyl(l|h, r, [anchor=]);
//   ycyl(l|h, d=, [anchor=]);
//   ycyl(l|h, r1=|d1=, r2=|d2=, [anchor=]);
// Usage: Attaching Children
//   ycyl(l|h, r, [anchor=]) [attachments];
//
// Arguments:
//   l / h = Length of cylinder along oriented axis. (Default: `1.0`)
//   r = Radius of cylinder.
//   ---
//   r1 = Radius of front (Y-) end of cone.
//   r2 = Radius of back (Y+) end of one.
//   d = Diameter of cylinder.
//   d1 = Diameter of front (Y-) end of one.
//   d2 = Diameter of back (Y+) end of one.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//
// Example: By Radius
//   xdistribute(50) {
//       ycyl(l=35, r=10);
//       ycyl(l=35, r1=15, r2=5);
//   }
//
// Example: By Diameter
//   xdistribute(50) {
//       ycyl(l=35, d=20);
//       ycyl(l=35, d1=30, d2=10);
//   }
module ycyl(h, r, d, r1, r2, d1, d2, l, anchor=CENTER)
{
    r1 = get_radius(r1=r1, r=r, d1=d1, d=d, dflt=1);
    r2 = get_radius(r1=r2, r=r, d1=d2, d=d, dflt=1);
    l = first_defined([l, h, 1]);
    attachable(anchor,0,UP, r1=r1, r2=r2, l=l, axis=BACK) {
        cyl(l=l, h=h, r1=r1, r2=r2, orient=BACK, anchor=CENTER);
        children();
    }
}



// Module: zcyl()
//
// Description:
//   Creates a cylinder oriented along the Z axis.
//
// Usage: Typical
//   zcyl(l|h, r, [anchor=]);
//   zcyl(l|h, d=, [anchor=]);
//   zcyl(l|h, r1=|d1=, r2=|d2=, [anchor=]);
// Usage: Attaching Children
//   zcyl(l|h, r, [anchor=]) [attachments];
//
// Arguments:
//   l / h = Length of cylinder along oriented axis. (Default: 1.0)
//   r = Radius of cylinder.
//   ---
//   r1 = Radius of front (Y-) end of cone.
//   r2 = Radius of back (Y+) end of one.
//   d = Diameter of cylinder.
//   d1 = Diameter of front (Y-) end of one.
//   d2 = Diameter of back (Y+) end of one.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//
// Example: By Radius
//   xdistribute(50) {
//       zcyl(l=35, r=10);
//       zcyl(l=35, r1=15, r2=5);
//   }
//
// Example: By Diameter
//   xdistribute(50) {
//       zcyl(l=35, d=20);
//       zcyl(l=35, d1=30, d2=10);
//   }
module zcyl(h, r, d, r1, r2, d1, d2, l, anchor=CENTER)
{
    cyl(l=l, h=h, r=r, r1=r1, r2=r2, d=d, d1=d1, d2=d2, orient=UP, anchor=anchor) children();
}



// Module: tube()
//
// Description:
//   Makes a hollow tube with the given outer size and wall thickness.
//
// Usage: Typical
//   tube(h|l, or, ir, [center], [realign=]);
//   tube(h|l, or=|od=, ir=|id=, ...);
//   tube(h|l, ir|id, wall, ...);
//   tube(h|l, or|od, wall, ...);
//   tube(h|l, ir1|id1, ir2|id2, wall, ...);
//   tube(h|l, or1|od1, or2|od2, wall, ...);
//   tube(h|l, ir1|id1, ir2|id2, or1|od1, or2|od2, [realign]);
// Usage: Attaching Children
//   tube(h|l, or, ir, [center]) [attachments];
//
// Arguments:
//   h / l = height of tube. Default: 1
//   or = Outer radius of tube. Default: 1
//   ir = Inner radius of tube.
//   center = If given, overrides `anchor`.  A true value sets `anchor=CENTER`, false sets `anchor=DOWN`.
//   ---
//   od = Outer diameter of tube.
//   id = Inner diameter of tube.
//   wall = horizontal thickness of tube wall. Default 0.5
//   or1 = Outer radius of bottom of tube.  Default: value of r)
//   or2 = Outer radius of top of tube.  Default: value of r)
//   od1 = Outer diameter of bottom of tube.
//   od2 = Outer diameter of top of tube.
//   ir1 = Inner radius of bottom of tube.
//   ir2 = Inner radius of top of tube.
//   id1 = Inner diameter of bottom of tube.
//   id2 = Inner diameter of top of tube.
//   realign = If true, rotate the tube by half the angle of one face.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
//
// Example: These all Produce the Same Tube
//   tube(h=30, or=40, wall=5);
//   tube(h=30, ir=35, wall=5);
//   tube(h=30, or=40, ir=35);
//   tube(h=30, od=80, id=70);
// Example: These all Produce the Same Conical Tube
//   tube(h=30, or1=40, or2=25, wall=5);
//   tube(h=30, ir1=35, or2=20, wall=5);
//   tube(h=30, or1=40, or2=25, ir1=35, ir2=20);
// Example: Circular Wedge
//   tube(h=30, or1=40, or2=30, ir1=20, ir2=30);
// Example: Standard Connectors
//   tube(h=30, or=40, wall=5) show_anchors();
module tube(
    h, or, ir, center,
    od, id, wall,
    or1, or2, od1, od2,
    ir1, ir2, id1, id2,
    realign=false, l,
    anchor, spin=0, orient=UP
) {
    h = first_defined([h,l,1]);
    orr1 = get_radius(r1=or1, r=or, d1=od1, d=od, dflt=undef);
    orr2 = get_radius(r1=or2, r=or, d1=od2, d=od, dflt=undef);
    irr1 = get_radius(r1=ir1, r=ir, d1=id1, d=id, dflt=undef);
    irr2 = get_radius(r1=ir2, r=ir, d1=id2, d=id, dflt=undef);
    r1 = default(orr1, u_add(irr1,wall));
    r2 = default(orr2, u_add(irr2,wall));
    ir1 = default(irr1, u_sub(orr1,wall));
    ir2 = default(irr2, u_sub(orr2,wall));
    assert(ir1 <= r1, "Inner radius is larger than outer radius.");
    assert(ir2 <= r2, "Inner radius is larger than outer radius.");
    sides = segs(max(r1,r2));
    anchor = get_anchor(anchor, center, BOT, BOT);
    attachable(anchor,spin,orient, r1=r1, r2=r2, l=h) {
        zrot(realign? 180/sides : 0) {
            difference() {
                cyl(h=h, r1=r1, r2=r2, $fn=sides) children();
                cyl(h=h+0.05, r1=ir1, r2=ir2);
            }
        }
        children();
    }
}


// Module: torus()
//
// Usage: Typical
//   torus(r_maj|d_maj, r_min|d_min, [center], ...);
//   torus(or|od, ir|id, ...);
//   torus(r_maj|d_maj, or|od, ...);
//   torus(r_maj|d_maj, ir|id, ...);
//   torus(r_min|d_min, or|od, ...);
//   torus(r_min|d_min, ir|id, ...);
// Usage: Attaching Children
//   torus(or|od, ir|id, ...) [attachments];
//
// Description:
//   Creates a torus shape.
//
// Figure(2D,Med):
//   module text3d(t,size=8) text(text=t,size=size,font="Helvetica", halign="center",valign="center");
//   module dashcirc(r,start=0,angle=359.9,dashlen=5) let(step=360*dashlen/(2*r*PI)) for(a=[start:step:start+angle]) stroke(arc(r=r,start=a,angle=step/2));
//   r = 75; r2 = 30;
//   down(r2+0.1) #torus(r_maj=r, r_min=r2, $fn=72);
//   color("blue") linear_extrude(height=0.01) {
//       dashcirc(r=r,start=15,angle=45);
//       dashcirc(r=r-r2, start=90+15, angle=60);
//       dashcirc(r=r+r2, start=180+45, angle=30);
//       dashcirc(r=r+r2, start=15, angle=30);
//   }
//   rot(240) color("blue") linear_extrude(height=0.01) {
//       stroke([[0,0],[r+r2,0]], endcaps="arrow2",width=2);
//       right(r) fwd(9) rot(-240) text3d("or",size=10);
//   }
//   rot(135) color("blue") linear_extrude(height=0.01) {
//       stroke([[0,0],[r-r2,0]], endcaps="arrow2",width=2);
//       right((r-r2)/2) back(8) rot(-135) text3d("ir",size=10);
//   }
//   rot(45) color("blue") linear_extrude(height=0.01) {
//       stroke([[0,0],[r,0]], endcaps="arrow2",width=2);
//       right(r/2) back(8) text3d("r_maj",size=9);
//   }
//   rot(30) color("blue") linear_extrude(height=0.01) {
//       stroke([[r,0],[r+r2,0]], endcaps="arrow2",width=2);
//       right(r+r2/2) fwd(8) text3d("r_min",size=7);
//   }
//
// Arguments:
//   r_maj = major radius of torus ring. (use with 'r_min', or 'd_min')
//   r_min = minor radius of torus ring. (use with 'r_maj', or 'd_maj')
//   center = If given, overrides `anchor`.  A true value sets `anchor=CENTER`, false sets `anchor=DOWN`.
//   ---
//   d_maj  = major diameter of torus ring. (use with 'r_min', or 'd_min')
//   d_min = minor diameter of torus ring. (use with 'r_maj', or 'd_maj')
//   or = outer radius of the torus. (use with 'ir', or 'id')
//   ir = inside radius of the torus. (use with 'or', or 'od')
//   od = outer diameter of the torus. (use with 'ir' or 'id')
//   id = inside diameter of the torus. (use with 'or' or 'od')
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
//
// Example:
//   // These all produce the same torus.
//   torus(r_maj=22.5, r_min=7.5);
//   torus(d_maj=45, d_min=15);
//   torus(or=30, ir=15);
//   torus(od=60, id=30);
//   torus(d_maj=45, id=30);
//   torus(d_maj=45, od=60);
//   torus(d_min=15, id=30);
//   torus(d_min=15, od=60);
// Example: Standard Connectors
//   torus(od=60, id=30) show_anchors();
module torus(
    r_maj, r_min, center,
    d_maj, d_min,
    or, od, ir, id,
    anchor, spin=0, orient=UP
) {
    _or = get_radius(r=or, d=od, dflt=undef);
    _ir = get_radius(r=ir, d=id, dflt=undef);
    _r_maj = get_radius(r=r_maj, d=d_maj, dflt=undef);
    _r_min = get_radius(r=r_min, d=d_min, dflt=undef);
    majrad = is_finite(_r_maj)? _r_maj :
        is_finite(_ir) && is_finite(_or)? (_or + _ir)/2 :
        is_finite(_ir) && is_finite(_r_min)? (_ir + _r_min) :
        is_finite(_or) && is_finite(_r_min)? (_or - _r_min) :
        assert(false, "Bad Parameters");
    minrad = is_finite(_r_min)? _r_min :
        is_finite(_ir)? (majrad - _ir) :
        is_finite(_or)? (_or - majrad) :
        assert(false, "Bad Parameters");
    anchor = get_anchor(anchor, center, BOT, CENTER);
    attachable(anchor,spin,orient, r=(majrad+minrad), l=minrad*2) {
        rotate_extrude(convexity=4) {
            right(majrad) circle(r=minrad);
        }
        children();
    }
}



// Section: Spheroid


// Function&Module: spheroid()
// Usage: Typical
//   spheroid(r|d, [circum], [style]);
// Usage: Attaching Children
//   spheroid(r|d, [circum], [style]) [attachments];
// Usage: As Function
//   vnf = spheroid(r|d, [circum], [style]);
// Description:
//   Creates a spheroid object, with support for anchoring and attachments.
//   This is a drop-in replacement for the built-in `sphere()` module.
//   When called as a function, returns a [VNF](vnf.scad) for a spheroid.
//   The exact triangulation of this spheroid can be controlled via the `style=`
//   argument, where the value can be one of `"orig"`, `"aligned"`, `"stagger"`,
//   `"octa"`, or `"icosa"`:
//   - `style="orig"` constructs a sphere the same way that the OpenSCAD `sphere()` built-in does.
//   - `style="aligned"` constructs a sphere where, if `$fn` is a multiple of 4, it has vertices at all axis maxima and minima.  ie: its bounding box is exactly the sphere diameter in length on all three axes.  This is the default.
//   - `style="stagger"` forms a sphere where all faces are triangular, but the top and bottom poles have thinner triangles.
//   - `style="octa"` forms a sphere by subdividing an octahedron (8-sided platonic solid).  This makes more uniform faces over the entirety of the sphere, and guarantees the bounding box is the sphere diameter in size on all axes.  The effective `$fn` value is quantized to a multiple of 4, though.  This is used in constructing rounded corners for various other shapes.
//   - `style="icosa"` forms a sphere by subdividing an icosahedron (20-sided platonic solid).  This makes even more uniform faces over the entirety of the sphere.  The effective `$fn` value is quantized to a multiple of 5, though.
// Arguments:
//   r = Radius of the spheroid.
//   style = The style of the spheroid's construction. One of "orig", "aligned", "stagger", "octa", or "icosa".  Default: "aligned"
//   ---
//   d = Diameter of the spheroid.
//   circum = If true, the spheroid is made large enough to circumscribe the sphere of the ideal side.  Otherwise inscribes.  Default: false (inscribes)
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
// Example: By Radius
//   spheroid(r=50);
// Example: By Diameter
//   spheroid(d=100);
// Example: style="orig"
//   spheroid(d=100, style="orig", $fn=10);
// Example: style="aligned"
//   spheroid(d=100, style="aligned", $fn=10);
// Example: style="stagger"
//   spheroid(d=100, style="stagger", $fn=10);
// Example: style="octa", octahedral based tesselation.
//   spheroid(d=100, style="octa", $fn=10);
//   // In "octa" style, $fn is quantized
//   //   to the nearest multiple of 4.
// Example: style="icosa", icosahedral based tesselation.
//   spheroid(d=100, style="icosa", $fn=10);
//   // In "icosa" style, $fn is quantized
//   //   to the nearest multiple of 5.
// Example: Anchoring
//   spheroid(d=100, anchor=FRONT);
// Example: Spin
//   spheroid(d=100, anchor=FRONT, spin=45);
// Example: Orientation
//   spheroid(d=100, anchor=FRONT, spin=45, orient=FWD);
// Example: Standard Connectors
//   spheroid(d=50) show_anchors();
// Example: Called as Function
//   vnf = spheroid(d=100, style="icosa");
//   vnf_polyhedron(vnf);
module spheroid(r, style="aligned", d, circum=false, anchor=CENTER, spin=0, orient=UP)
{
    r = get_radius(r=r, d=d, dflt=1);
    sides = segs(r);
    vsides = ceil(sides/2);
    attachable(anchor,spin,orient, r=r) {
        if (style=="orig") {
            merids = [ for (i=[0:1:vsides-1]) 90-(i+0.5)*180/vsides ];
            path = [
                let(a = merids[0]) [0, sin(a)],
                for (a=merids) [cos(a), sin(a)],
                let(a = last(merids)) [0, sin(a)]
            ];
            scale(r) rotate(180) rotate_extrude(convexity=2,$fn=sides) polygon(path);
        } else {
            vnf = spheroid(r=r, circum=circum, style=style);
            vnf_polyhedron(vnf, convexity=2);
        }
        children();
    }
}


function spheroid(r, style="aligned", d, circum=false, anchor=CENTER, spin=0, orient=UP) =
    let(
        r = get_radius(r=r, d=d, dflt=1),
        hsides = segs(r),
        vsides = max(2,ceil(hsides/2)),
        octa_steps = round(max(4,hsides)/4),
        icosa_steps = round(max(5,hsides)/5),
        rr = circum? (r / cos(90/vsides) / cos(180/hsides)) : r,
        stagger = style=="stagger",
        verts = style=="orig"? [
            for (i=[0:1:vsides-1]) let(phi = (i+0.5)*180/(vsides))
            for (j=[0:1:hsides-1]) let(theta = j*360/hsides)
            spherical_to_xyz(rr, theta, phi),
        ] : style=="aligned" || style=="stagger"? [
            spherical_to_xyz(rr, 0, 0),
            for (i=[1:1:vsides-1]) let(phi = i*180/vsides)
                for (j=[0:1:hsides-1]) let(theta = (j+((stagger && i%2!=0)?0.5:0))*360/hsides)
                    spherical_to_xyz(rr, theta, phi),
            spherical_to_xyz(rr, 0, 180)
        ] : style=="octa"? let(
            meridians = [
                1,
                for (i = [1:1:octa_steps]) i*4,
                for (i = [octa_steps-1:-1:1]) i*4,
                1,
            ]
        ) [
            for (i=idx(meridians), j=[0:1:meridians[i]-1])
            spherical_to_xyz(rr, j*360/meridians[i], i*180/(len(meridians)-1))
        ] : style=="icosa"? [
            for (tb=[0,1], j=[0,2], i = [0:1:4]) let(
                theta0 = i*360/5,
                theta1 = (i-0.5)*360/5,
                theta2 = (i+0.5)*360/5,
                phi0 = 180/3 * j,
                phi1 = 180/3,
                v0 = spherical_to_xyz(1,theta0,phi0),
                v1 = spherical_to_xyz(1,theta1,phi1),
                v2 = spherical_to_xyz(1,theta2,phi1),
                ax0 = vector_axis(v0, v1),
                ang0 = vector_angle(v0, v1),
                ax1 = vector_axis(v0, v2),
                ang1 = vector_angle(v0, v2)
            )
            for (k = [0:1:icosa_steps]) let(
                u = k/icosa_steps,
                vv0 = rot(ang0*u, ax0, p=v0),
                vv1 = rot(ang1*u, ax1, p=v0),
                ax2 = vector_axis(vv0, vv1),
                ang2 = vector_angle(vv0, vv1)
            )
            for (l = [0:1:k]) let(
                v = k? l/k : 0,
                pt = rot(ang2*v, v=ax2, p=vv0) * rr * (tb? -1 : 1)
            ) pt
        ] : assert(in_list(style,["orig","aligned","stagger","octa","icosa"])),
        lv = len(verts),
        faces = style=="orig"? [
            [for (i=[0:1:hsides-1]) hsides-i-1],
            [for (i=[0:1:hsides-1]) lv-hsides+i],
            for (i=[0:1:vsides-2], j=[0:1:hsides-1]) each [
                [(i+1)*hsides+j, i*hsides+j, i*hsides+(j+1)%hsides],
                [(i+1)*hsides+j, i*hsides+(j+1)%hsides, (i+1)*hsides+(j+1)%hsides],
            ]
        ] : style=="aligned" || style=="stagger"? [
            for (i=[0:1:hsides-1]) let(
                b2 = lv-2-hsides
            ) each [
                [i+1, 0, ((i+1)%hsides)+1],
                [lv-1, b2+i+1, b2+((i+1)%hsides)+1],
            ],
            for (i=[0:1:vsides-3], j=[0:1:hsides-1]) let(
                base = 1 + hsides*i
            ) each (
                (stagger && i%2!=0)? [
                    [base+j, base+hsides+j%hsides, base+hsides+(j+hsides-1)%hsides],
                    [base+j, base+(j+1)%hsides, base+hsides+j],
                ] : [
                    [base+j, base+(j+1)%hsides, base+hsides+(j+1)%hsides],
                    [base+j, base+hsides+(j+1)%hsides, base+hsides+j],
                ]
            )
        ] : style=="octa"? let(
            meridians = [
                0, 1,
                for (i = [1:1:octa_steps]) i*4,
                for (i = [octa_steps-1:-1:1]) i*4,
                1,
            ],
            offs = cumsum(meridians),
            pc = last(offs)-1,
            os = octa_steps * 2
        ) [
            for (i=[0:1:3]) [0, 1+(i+1)%4, 1+i],
            for (i=[0:1:3]) [pc-0, pc-(1+(i+1)%4), pc-(1+i)],
            for (i=[1:1:octa_steps-1]) let(
                m = meridians[i+2]/4
            )
            for (j=[0:1:3], k=[0:1:m-1]) let(
                m1 = meridians[i+1],
                m2 = meridians[i+2],
                p1 = offs[i+0] + (j*m1/4 + k+0) % m1,
                p2 = offs[i+0] + (j*m1/4 + k+1) % m1,
                p3 = offs[i+1] + (j*m2/4 + k+0) % m2,
                p4 = offs[i+1] + (j*m2/4 + k+1) % m2,
                p5 = offs[os-i+0] + (j*m1/4 + k+0) % m1,
                p6 = offs[os-i+0] + (j*m1/4 + k+1) % m1,
                p7 = offs[os-i-1] + (j*m2/4 + k+0) % m2,
                p8 = offs[os-i-1] + (j*m2/4 + k+1) % m2
            ) each [
                [p1, p4, p3],
                if (k<m-1) [p1, p2, p4],
                [p5, p7, p8],
                if (k<m-1) [p5, p8, p6],
            ],
        ] : style=="icosa"? let(
            pyr = [for (x=[0:1:icosa_steps+1]) x],
            tri = sum(pyr),
            soff = cumsum(pyr)
        ) [
            for (tb=[0,1], j=[0,1], i = [0:1:4]) let(
                base = ((((tb*2) + j) * 5) + i) * tri
            )
            for (k = [0:1:icosa_steps-1])
            for (l = [0:1:k]) let(
                v1 = base + soff[k] + l,
                v2 = base + soff[k+1] + l,
                v3 = base + soff[k+1] + (l + 1),
                faces = [
                    if(l>0) [v1-1,v1,v2],
                    [v1,v3,v2],
                ],
                faces2 = (tb+j)%2? [for (f=faces) reverse(f)] : faces
            ) each faces2
        ] : []
    ) [reorient(anchor,spin,orient, r=r, p=verts), faces];



// Section: 3D Printing Shapes


// Module: teardrop()
//
// Description:
//   Makes a teardrop shape in the XZ plane. Useful for 3D printable holes.
//
// Usage: Typical
//   teardrop(h|l, r, [ang], [cap_h], ...);
//   teardrop(h|l, d=, [ang=], [cap_h=], ...);
// Usage: Psuedo-Conical
//   teardrop(h|l, r1=, r2=, [ang=], [cap_h1=], [cap_h2=], ...);
//   teardrop(h|l, d1=, d2=, [ang=], [cap_h1=], [cap_h2=], ...);
// Usage: Attaching Children
//   teardrop(h|l, r, ...) [attachments];
//
// Arguments:
//   h / l = Thickness of teardrop. Default: 1
//   r = Radius of circular part of teardrop.  Default: 1
//   ang = Angle of hat walls from the Z axis.  Default: 45 degrees
//   cap_h = If given, height above center where the shape will be truncated. Default: `undef` (no truncation)
//   ---
//   r1 = Radius of circular portion of the front end of the teardrop shape.
//   r2 = Radius of circular portion of the back end of the teardrop shape.
//   d = Diameter of circular portion of the teardrop shape.
//   d1 = Diameter of circular portion of the front end of the teardrop shape.
//   d2 = Diameter of circular portion of the back end of the teardrop shape.
//   cap_h1 = If given, height above center where the shape will be truncated, on the front side. Default: `undef` (no truncation)
//   cap_h2 = If given, height above center where the shape will be truncated, on the back side. Default: `undef` (no truncation)
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
//
// Extra Anchors:
//   cap = The center of the top of the cap, oriented with the cap face normal.
//   cap_fwd = The front edge of the cap.
//   cap_back = The back edge of the cap.
//
// Example: Typical Shape
//   teardrop(r=30, h=10, ang=30);
// Example: Crop Cap
//   teardrop(r=30, h=10, ang=30, cap_h=40);
// Example: Close Crop
//   teardrop(r=30, h=10, ang=30, cap_h=20);
// Example: Psuedo-Conical
//   teardrop(r1=20, r2=30, h=40, cap_h1=25, cap_h2=35);
// Example: Standard Conical Connectors
//   teardrop(d1=20, d2=30, h=20, cap_h1=11, cap_h2=16)
//       show_anchors(custom=false);
// Example(Spin,VPD=275): Named Conical Connectors
//   teardrop(d1=20, d2=30, h=20, cap_h1=11, cap_h2=16)
//       show_anchors(std=false);
module teardrop(h, r, ang=45, cap_h, r1, r2, d, d1, d2, cap_h1, cap_h2, l, anchor=CENTER, spin=0, orient=UP)
{
    r1 = get_radius(r=r, r1=r1, d=d, d1=d1, dflt=1);
    r2 = get_radius(r=r, r1=r2, d=d, d1=d2, dflt=1);
    l = first_defined([l, h, 1]);
    tip_y1 = adj_ang_to_hyp(r1, 90-ang);
    tip_y2 = adj_ang_to_hyp(r2, 90-ang);
    cap_h1 = min(first_defined([cap_h1, cap_h, tip_y1]), tip_y1);
    cap_h2 = min(first_defined([cap_h2, cap_h, tip_y2]), tip_y2);
    capvec = unit([0, cap_h1-cap_h2, l]);
    anchors = [
        anchorpt("cap",      [0,0,(cap_h1+cap_h2)/2], capvec),
        anchorpt("cap_fwd",  [0,-l/2,cap_h1],         unit((capvec+FWD)/2)),
        anchorpt("cap_back", [0,+l/2,cap_h2],         unit((capvec+BACK)/2), 180),
    ];
    attachable(anchor,spin,orient, r1=r1, r2=r2, l=l, axis=BACK, anchors=anchors) {
        rot(from=UP,to=FWD) {
            if (l > 0) {
                if (r1 == r2) {
                    linear_extrude(height=l, center=true, slices=2) {
                        teardrop2d(r=r1, ang=ang, cap_h=cap_h);
                    }
                } else {
                    hull() {
                        up(l/2-0.001) {
                            linear_extrude(height=0.001, center=false) {
                                teardrop2d(r=r1, ang=ang, cap_h=cap_h1);
                            }
                        }
                        down(l/2) {
                            linear_extrude(height=0.001, center=false) {
                                teardrop2d(r=r2, ang=ang, cap_h=cap_h2);
                            }
                        }
                    }
                }
            }
        }
        children();
    }
}


// Module: onion()
//
// Description:
//   Creates a sphere with a conical hat, to make a 3D teardrop.
//
// Usage:
//   onion(r|d, [ang], [cap_h]);
// Usage: Typical
//   onion(r, [ang], [cap_h], ...);
//   onion(d=, [ang=], [cap_h=], ...);
// Usage: Attaching Children
//   onion(r, ...) [attachments];
//
// Arguments:
//   r = radius of spherical portion of the bottom. Default: 1
//   ang = Angle of cone on top from vertical. Default: 45 degrees
//   cap_h = If given, height above sphere center to truncate teardrop shape.  Default: `undef` (no truncation)
//   ---
//   d = diameter of spherical portion of bottom.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
//
// Example: Typical Shape
//   onion(r=30, ang=30);
// Example: Crop Cap
//   onion(r=30, ang=30, cap_h=40);
// Example: Close Crop
//   onion(r=30, ang=30, cap_h=20);
// Example: Standard Connectors
//   onion(r=30, ang=30, cap_h=40) show_anchors();
module onion(r, ang=45, cap_h, d, anchor=CENTER, spin=0, orient=UP)
{
    r = get_radius(r=r, d=d, dflt=1);
    tip_y = adj_ang_to_hyp(r, 90-ang);
    cap_h = min(default(cap_h,tip_y), tip_y);
    anchors = [
        ["cap", [0,0,cap_h], UP, 0]
    ];
    attachable(anchor,spin,orient, r=r, anchors=anchors) {
        rotate_extrude(convexity=2) {
            difference() {
                teardrop2d(r=r, ang=ang, cap_h=cap_h);
                left(r) square(size=[2*r,2*max(cap_h,r)+1], center=true);
            }
        }
        children();
    }
}



// Section: Miscellaneous


// Module: nil()
//
// Description:
//   Useful when you MUST pass a child to a module, but you want it to be nothing.
module nil() union(){}


// Module: noop()
//
// Description:
//   Passes through the children passed to it, with no action at all.  Useful while debugging when
//   you want to replace a command.  This is an attachable non-object.
//
// Arguments:
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
module noop(spin=0, orient=UP) attachable(CENTER,spin,orient, d=0.01) {nil(); children();}


// Module: pie_slice()
//
// Description:
//   Creates a pie slice shape.
//
// Usage: Typical
//   pie_slice(l|h, r, ang, [center]);
//   pie_slice(l|h, d=, ang=, ...);
//   pie_slice(l|h, r1=|d1=, r2=|d2=, ang=, ...);
// Usage: Attaching Children
//   pie_slice(l|h, r, ang, ...) [attachments];
//
// Arguments:
//   h / l = height of pie slice.
//   r = radius of pie slice.
//   ang = pie slice angle in degrees.
//   center = If given, overrides `anchor`.  A true value sets `anchor=CENTER`, false sets `anchor=UP`.
//   ---
//   r1 = bottom radius of pie slice.
//   r2 = top radius of pie slice.
//   d = diameter of pie slice.
//   d1 = bottom diameter of pie slice.
//   d2 = top diameter of pie slice.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
//
// Example: Cylindrical Pie Slice
//   pie_slice(ang=45, l=20, r=30);
// Example: Conical Pie Slice
//   pie_slice(ang=60, l=20, d1=50, d2=70);
module pie_slice(
    h, r, ang=30, center,
    r1, r2, d, d1, d2, l,
    anchor, spin=0, orient=UP
) {
    l = first_defined([l, h, 1]);
    r1 = get_radius(r1=r1, r=r, d1=d1, d=d, dflt=10);
    r2 = get_radius(r1=r2, r=r, d1=d2, d=d, dflt=10);
    maxd = max(r1,r2)+0.1;
    anchor = get_anchor(anchor, center, BOT, BOT);
    attachable(anchor,spin,orient, r1=r1, r2=r2, l=l) {
        difference() {
            cyl(r1=r1, r2=r2, h=l);
            if (ang<180) rotate(ang) back(maxd/2) cube([2*maxd, maxd, l+0.1], center=true);
            difference() {
                fwd(maxd/2) cube([2*maxd, maxd, l+0.2], center=true);
                if (ang>180) rotate(ang-180) back(maxd/2) cube([2*maxd, maxd, l+0.1], center=true);
            }
        }
        children();
    }
}


// Module: interior_fillet()
//
// Description:
//   Creates a shape that can be unioned into a concave joint between two faces, to fillet them.
//   Center this part along the concave edge to be chamfered and union it in.
//
// Usage: Typical
//   interior_fillet(l, r, [ang], [overlap], ...);
//   interior_fillet(l, d=, [ang=], [overlap=], ...);
// Usage: Attaching Children
//   interior_fillet(l, r, [ang], [overlap], ...) [attachments];
//
// Arguments:
//   l = Length of edge to fillet.
//   r = Radius of fillet.
//   ang = Angle between faces to fillet.
//   overlap = Overlap size for unioning with faces.
//   ---
//   d = Diameter of fillet.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `FRONT+LEFT`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
//
// Example:
//   union() {
//       translate([0,2,-4])
//           cube([20, 4, 24], anchor=BOTTOM);
//       translate([0,-10,-4])
//           cube([20, 20, 4], anchor=BOTTOM);
//       color("green")
//           interior_fillet(
//               l=20, r=10,
//               spin=180, orient=RIGHT
//           );
//   }
//
// Example:
//   interior_fillet(l=40, r=10, spin=-90);
//
// Example: Using with Attachments
//   cube(50,center=true) {
//     position(FRONT+LEFT)
//       interior_fillet(l=50, r=10, spin=-90);
//     position(BOT+FRONT)
//       interior_fillet(l=50, r=10, spin=180, orient=RIGHT);
//   }
module interior_fillet(l=1.0, r, ang=90, overlap=0.01, d, anchor=FRONT+LEFT, spin=0, orient=UP) {
    r = get_radius(r=r, d=d, dflt=1);
    dy = r/tan(ang/2);
    steps = ceil(segs(r)*ang/360);
    step = ang/steps;
    attachable(anchor,spin,orient, size=[r,r,l]) {
        if (l > 0) {
            linear_extrude(height=l, convexity=4, center=true) {
                path = concat(
                    [[0,0]],
                    [for (i=[0:1:steps]) let(a=270-i*step) r*[cos(a),sin(a)]+[dy,r]]
                );
                translate(-[r,r]/2) polygon(path);
            }
        }
        children();
    }
}


// Function&Module: heightfield()
// Usage: As Module
//   heightfield(data, [size], [bottom], [maxz], [xrange], [yrange], [style], [convexity], ...);
// Usage: Attaching Children
//   heightfield(data, [size], ...) [attachments];
// Usage: As Function
//   vnf = heightfield(data, [size], [bottom], [maxz], [xrange], [yrange], [style], ...);
// Description:
//   Given a regular rectangular 2D grid of scalar values, or a function literal, generates a 3D
//   surface where the height at any given point is the scalar value for that position.
// Arguments:
//   data = This is either the 2D rectangular array of heights, or a function literal that takes X and Y arguments.
//   size = The [X,Y] size of the surface to create.  If given as a scalar, use it for both X and Y sizes. Default: `[100,100]`
//   bottom = The Z coordinate for the bottom of the heightfield object to create.  Any heights lower than this will be truncated to very slightly above this height.  Default: -20
//   maxz = The maximum height to model.  Truncates anything taller to this height.  Default: 99
//   xrange = A range of values to iterate X over when calculating a surface from a function literal.  Default: [-1 : 0.01 : 1]
//   yrange = A range of values to iterate Y over when calculating a surface from a function literal.  Default: [-1 : 0.01 : 1]
//   style = The style of subdividing the quads into faces.  Valid options are "default", "alt", and "quincunx".  Default: "default"
//   ---
//   convexity = Max number of times a line could intersect a wall of the surface being formed. Module only.  Default: 10
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards.  See [orient](attachments.scad#orient).  Default: `UP`
// Example:
//   heightfield(size=[100,100], bottom=-20, data=[
//       for (y=[-180:4:180]) [
//           for(x=[-180:4:180])
//           10*cos(3*norm([x,y]))
//       ]
//   ]);
// Example:
//   intersection() {
//       heightfield(size=[100,100], data=[
//           for (y=[-180:5:180]) [
//               for(x=[-180:5:180])
//               10+5*cos(3*x)*sin(3*y)
//           ]
//       ]);
//       cylinder(h=50,d=100);
//   }
// Example: Heightfield by Function
//   fn = function (x,y) 10*sin(x*360)*cos(y*360);
//   heightfield(size=[100,100], data=fn);
// Example: Heightfield by Function, with Specific Ranges
//   fn = function (x,y) 2*cos(5*norm([x,y]));
//   heightfield(
//       size=[100,100], bottom=-20, data=fn,
//       xrange=[-180:2:180], yrange=[-180:2:180]
//   );
module heightfield(data, size=[100,100], bottom=-20, maxz=100, xrange=[-1:0.04:1], yrange=[-1:0.04:1], style="default", convexity=10, anchor=CENTER, spin=0, orient=UP)
{
    size = is_num(size)? [size,size] : point2d(size);
    vnf = heightfield(data=data, size=size, xrange=xrange, yrange=yrange, bottom=bottom, maxz=maxz, style=style);
    attachable(anchor,spin,orient, vnf=vnf) {
        vnf_polyhedron(vnf, convexity=convexity);
        children();
    }
}


function heightfield(data, size=[100,100], bottom=-20, maxz=100, xrange=[-1:0.04:1], yrange=[-1:0.04:1], style="default", anchor=CENTER, spin=0, orient=UP) =
    assert(is_list(data) || is_function(data))
    let(
        size = is_num(size)? [size,size] : point2d(size),
        xvals = is_list(data)
          ? [for (i=idx(data[0])) i]
          : assert(is_list(xrange)||is_range(xrange)) [for (x=xrange) x],
        yvals = is_list(data)
          ? [for (i=idx(data)) i]
          : assert(is_list(yrange)||is_range(yrange)) [for (y=yrange) y],
        xcnt = len(xvals),
        minx = min(xvals),
        maxx = max(xvals),
        ycnt = len(yvals),
        miny = min(yvals),
        maxy = max(yvals),
        verts = is_list(data) ? [
                for (y = [0:1:ycnt-1]) [
                    for (x = [0:1:xcnt-1]) [
                        size.x * (x/(xcnt-1)-0.5),
                        size.y * (y/(ycnt-1)-0.5),
                        data[y][x]
                    ]
                ]
            ] : [
                for (y = yrange) [
                    for (x = xrange) let(
                        z = data(x,y)
                    ) [
                        size.x * ((x-minx)/(maxx-minx)-0.5),
                        size.y * ((y-miny)/(maxy-miny)-0.5),
                        min(maxz, max(bottom+0.1, default(z,0)))
                    ]
                ]
            ],
        vnf = vnf_merge([
            vnf_vertex_array(verts, style=style, reverse=true),
            vnf_vertex_array([
                verts[0],
                [for (v=verts[0]) [v.x, v.y, bottom]],
            ]),
            vnf_vertex_array([
                [for (v=verts[ycnt-1]) [v.x, v.y, bottom]],
                verts[ycnt-1],
            ]),
            vnf_vertex_array([
                [for (r=verts) let(v=r[0]) [v.x, v.y, bottom]],
                [for (r=verts) let(v=r[0]) v],
            ]),
            vnf_vertex_array([
                [for (r=verts) let(v=r[xcnt-1]) v],
                [for (r=verts) let(v=r[xcnt-1]) [v.x, v.y, bottom]],
            ]),
            vnf_vertex_array([
                [
                    for (v=verts[0]) [v.x, v.y, bottom],
                    for (r=verts) let(v=r[xcnt-1]) [v.x, v.y, bottom],
                ], [
                    for (r=verts) let(v=r[0]) [v.x, v.y, bottom],
                    for (v=verts[ycnt-1]) [v.x, v.y, bottom],
                ]
            ])
        ])
    ) reorient(anchor,spin,orient, vnf=vnf, p=vnf);


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
