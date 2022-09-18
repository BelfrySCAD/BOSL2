//////////////////////////////////////////////////////////////////////
// LibFile: shapes3d.scad
//   Some standard modules for making 3d shapes with attachment support, and function forms
//   that produce a VNF.  Also included are shortcuts cylinders in each orientation and extended versions of
//   the standard modules that provide roundovers and chamfers.  The spheroid() module provides
//   several different ways to make a sphere, and the text modules let you write text on a path
//   so you can place it on a curved object.  A ruler lets you measure objects.  
// Includes:
//   include <BOSL2/std.scad>
// FileGroup: Basic Modeling
// FileSummary: Attachable cubes, cylinders, spheres, ruler, and text.  Many can produce a VNF.
// FileFootnotes: STD=Included in std.scad
//////////////////////////////////////////////////////////////////////

use <builtins.scad>


// Section: Cuboids, Prismoids and Pyramids

// Function&Module: cube()
// Topics: Shapes (3D), Attachable, VNF Generators
// Usage: As Module
//   cube(size, [center], ...);
// Usage: With Attachments
//   cube(size, [center], ...) [ATTACHMENTS];
// Usage: As Function
//   vnf = cube(size, [center], ...);
// See Also: cuboid(), prismoid()
// Description:
//   Creates a 3D cubic object with support for anchoring and attachments.
//   This can be used as a drop-in replacement for the built-in `cube()` module.
//   When called as a function, returns a [VNF](vnf.scad) for a cube.
// Arguments:
//   size = The size of the cube.
//   center = If given, overrides `anchor`.  A true value sets `anchor=CENTER`, false sets `anchor=FRONT+LEFT+BOTTOM`.
//   ---
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Example: Simple cube.
//   cube(40);
// Example: Rectangular cube.
//   cube([20,40,50]);
// Example: Anchoring.
//   cube([20,40,50], anchor=BOTTOM+FRONT);
// Example: Spin.
//   cube([20,40,50], anchor=BOTTOM+FRONT, spin=30);
// Example: Orientation.
//   cube([20,40,50], anchor=BOTTOM+FRONT, spin=30, orient=FWD);
// Example: Standard Connectors.
//   cube(40, center=true) show_anchors();
// Example: Called as Function
//   vnf = cube([20,40,50]);
//   vnf_polyhedron(vnf);

module cube(size=1, center, anchor, spin=0, orient=UP)
{
    anchor = get_anchor(anchor, center, -[1,1,1], -[1,1,1]);
    size = scalar_vec3(size);
    attachable(anchor,spin,orient, size=size) {
        _cube(size, center=true);
        children();
    }
}

function cube(size=1, center, anchor, spin=0, orient=UP) =
    let(
        siz = scalar_vec3(size),
        anchor = get_anchor(anchor, center, -[1,1,1], -[1,1,1]),
        unscaled = [
            [-1,-1,-1],[1,-1,-1],[1,1,-1],[-1,1,-1],
            [-1,-1, 1],[1,-1, 1],[1,1, 1],[-1,1, 1],
        ]/2,
        verts = is_num(size)? unscaled * size :
            is_vector(size,3)? [for (p=unscaled) v_mul(p,size)] :
            assert(is_num(size) || is_vector(size,3)),
        faces = [
            [0,1,2], [0,2,3],  //BOTTOM
            [0,4,5], [0,5,1],  //FRONT
            [1,5,6], [1,6,2],  //RIGHT
            [2,6,7], [2,7,3],  //BACK
            [3,7,4], [3,4,0],  //LEFT
            [6,4,7], [6,5,4]   //TOP
        ]
    ) [reorient(anchor,spin,orient, size=siz, p=verts), faces];



// Module: cuboid()
//
// Usage: Standard Cubes
//   cuboid(size, [anchor=], [spin=], [orient=]);
//   cuboid(size, p1=, ...);
//   cuboid(p1=, p2=, ...);
// Usage: Chamfered Cubes
//   cuboid(size, [chamfer=], [edges=], [except=], [trimcorners=], ...);
// Usage: Rounded Cubes
//   cuboid(size, [rounding=], [teardrop=], [edges=], [except=], [trimcorners=], ...);
// Usage: Attaching children
//   cuboid(...) ATTACHMENTS;
//
// Description:
//   Creates a cube or cuboid object, with optional chamfering or rounding of edges and corners.
//   You cannot mix chamfering and rounding: just one edge treatment with the same size applies to all selected edges.
//   Negative chamfers and roundings can be applied to create external fillets, but they
//   only apply to edges around the top or bottom faces.  If you specify an edge set other than "ALL"
//   with negative roundings or chamfers then you will get an error.  See [Specifying Edges](attachments.scad#section-specifying-edges)
//   for information on how to specify edge sets.
// Arguments:
//   size = The size of the cube, a number or length 3 vector.
//   ---
//   chamfer = Size of chamfer, inset from sides.  Default: No chamfering.
//   rounding = Radius of the edge rounding.  Default: No rounding.
//   edges = Edges to mask.  See [Specifying Edges](attachments.scad#section-specifying-edges).  Default: all edges.
//   except = Edges to explicitly NOT mask.  See [Specifying Edges](attachments.scad#section-specifying-edges).  Default: No edges.
//   trimcorners = If true, rounds or chamfers corners where three chamfered/rounded edges meet.  Default: `true`
//   teardrop = If given as a number, rounding around the bottom edge of the cuboid won't exceed this many degrees from vertical.  If true, the limit angle is 45 degrees.  Default: `false`
//   p1 = Align the cuboid's corner at `p1`, if given.  Forces `anchor=FRONT+LEFT+BOTTOM`.
//   p2 = If given with `p1`, defines the cornerpoints of the cuboid.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
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
// Example(VPR=[100,0,25],VPD=180): Rounded Edges and Corners with Teardrop Bottoms
//   cuboid([30,40,50], rounding=10, teardrop=true);
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
//       edges=[TOP,BOT], except=RIGHT,
//       $fn=24
//   );
// Example: Negative Chamferring, Untrimmed Corners
//   cuboid(
//       [30,40,50], chamfer=-5,
//       edges=[TOP,BOT], except=RIGHT,
//       trimcorners=false, $fn=24
//   );
// Example: Negative Rounding
//   cuboid(
//       [30,40,50], rounding=-5,
//       edges=[TOP,BOT], except=RIGHT,
//       $fn=24
//   );
// Example: Negative Rounding, Untrimmed Corners
//   cuboid(
//       [30,40,50], rounding=-5,
//       edges=[TOP,BOT], except=RIGHT,
//       trimcorners=false, $fn=24
//   );
// Example: Roundings and Chamfers can be as large as the full size of the cuboid, so long as the edges would not interfere.
//   cuboid([4,2,1], rounding=2, edges=[FWD+RIGHT,BACK+LEFT]);
// Example: Standard Connectors
//   cuboid(40) show_anchors();

module cuboid(
    size=[1,1,1],
    p1, p2,
    chamfer,
    rounding,
    edges=EDGES_ALL,
    except=[],
    except_edges,
    trimcorners=true,
    teardrop=false,
    anchor=CENTER,
    spin=0,
    orient=UP
) {
    module trunc_cube(s,corner) {
        multmatrix(
            (corner.x<0? xflip() : ident(4)) *
            (corner.y<0? yflip() : ident(4)) *
            (corner.z<0? zflip() : ident(4)) *
            scale(s+[1,1,1]*0.01) *
            move(-[1,1,1]/2)
        ) polyhedron(
            [[1,1,1],[1,1,0],[1,0,0],[0,1,1],[0,1,0],[1,0,1],[0,0,1]],
            [[0,1,2],[2,5,0],[0,5,6],[0,6,3],[0,3,4],[0,4,1],[1,4,2],[3,6,4],[5,2,6],[2,4,6]]
        );
    }
    module xtcyl(l,r) {
        if (teardrop) {
            teardrop(r=r, l=l, cap_h=r, ang=teardrop, spin=90, orient=DOWN);
        } else {
            yrot(90) cyl(l=l, r=r);
        }
    }
    module ytcyl(l,r) {
        if (teardrop) {
            teardrop(r=r, l=l, cap_h=r, ang=teardrop, spin=0, orient=DOWN);
        } else {
            zrot(90) yrot(90) cyl(l=l, r=r);
        }
    }
    module tsphere(r) {
        if (teardrop) {
            onion(r=r, cap_h=r, ang=teardrop, orient=DOWN);
        } else {
            spheroid(r=r, style="octa", orient=DOWN);
        }
    }
    module corner_shape(corner) {
        e = _corner_edges(edges, corner);
        cnt = sum(e);
        r = first_defined([chamfer, rounding]);
        dummy = assert(is_finite(r) && !approx(r,0));
        c = [r,r,r];
        m = 0.01;
        c2 = v_mul(corner,c/2);
        c3 = v_mul(corner,c-[1,1,1]*m/2);
        $fn = is_finite(chamfer)? 4 : quantup(segs(r),4);
        translate(v_mul(corner, size/2-c)) {
            if (cnt == 0 || approx(r,0)) {
                translate(c3) cube(m, center=true);
            } else if (cnt == 1) {
                if (e.x) {
                    mat = (corner.y<0? yflip() : ident(4)) *
                        (corner.z<0? zflip() : ident(4)) *
                        yrot(-90) * move(-[1,1]*0.01);
                    right(c3.x) {
                        intersection() {
                            xtcyl(l=m, r=r);
                            multmatrix(mat)
                                linear_extrude(height=m+0.1, center=true)
                                    polygon([[r,0],[0.99*r,0],[0,0.99*r],[0,r],[r,r]]);
                        }
                    }
                } else if (e.y) {
                    mat = (corner.x<0? xflip() : ident(4)) *
                        (corner.z<0? zflip() : ident(4)) *
                        xrot(90) * move(-[1,1]*0.01);
                    back(c3.y) {
                        intersection() {
                            ytcyl(l=m, r=r);
                            multmatrix(mat)
                                linear_extrude(height=m+0.1, center=true)
                                    polygon([[r,0],[0.99*r,0],[0,0.99*r],[0,r],[r,r]]);
                        }
                    }
                } else if (e.z) {
                    mat = (corner.x<0? xflip() : ident(4)) *
                        (corner.y<0? yflip() : ident(4)) *
                        move(-[1,1]*0.01);
                    up(c3.z) {
                        intersection() {
                            zcyl(l=m, r=r);
                            multmatrix(mat)
                                linear_extrude(height=m+0.1, center=true)
                                    polygon([[r,0],[0.99*r,0],[0,0.99*r],[0,r],[r,r]]);
                        }
                    }
                }
            } else if (cnt == 2) {
                intersection() {
                    if (!e.x) {
                        intersection() {
                            ytcyl(l=c.y*2, r=r);
                            zcyl(l=c.z*2, r=r);
                        }
                    } else if (!e.y) {
                        intersection() {
                            xtcyl(l=c.x*2, r=r);
                            zcyl(l=c.z*2, r=r);
                        }
                    } else {
                        intersection() {
                            xtcyl(l=c.x*2, r=r);
                            ytcyl(l=c.y*2, r=r);
                        }
                    }
                    translate(c2) trunc_cube(c,corner); // Trim to just the octant.
                }
            } else {
                intersection() {
                    if (trimcorners) {
                        tsphere(r=r);
                    } else {
                        intersection() {
                            xtcyl(l=c.x*2, r=r);
                            ytcyl(l=c.y*2, r=r);
                            zcyl(l=c.z*2, r=r);
                        }
                    }
                    translate(c2) trunc_cube(c,corner); // Trim to just the octant.
                }
            }
        }
    }

    size = scalar_vec3(size);
    edges = _edges(edges, except=first_defined([except_edges,except]));
    teardrop = is_bool(teardrop)&&teardrop? 45 : teardrop;
    chamfer = approx(chamfer,0) ? undef : chamfer;
    rounding = approx(rounding,0) ? undef : rounding;
    checks = 
        assert(is_vector(size,3))
        assert(all_positive(size))
        assert(is_undef(chamfer) || is_finite(chamfer),"chamfer must be a finite value")
        assert(is_undef(rounding) || is_finite(rounding),"rounding must be a finite value")
        assert(is_undef(rounding) || is_undef(chamfer), "Cannot specify nonzero value for both chamfer and rounding")
        assert(teardrop==false || (is_finite(teardrop) && teardrop>0 && teardrop<90), "teardrop must be either false or an angle number between 0 and 90")
        assert(is_undef(p1) || is_vector(p1))
        assert(is_undef(p2) || is_vector(p2))
        assert(is_bool(trimcorners));
    if (!is_undef(p1)) {
        if (!is_undef(p2)) {
            translate(pointlist_bounds([p1,p2])[0]) {
                cuboid(size=v_abs(p2-p1), chamfer=chamfer, rounding=rounding, edges=edges, trimcorners=trimcorners, anchor=-[1,1,1]) children();
            }
        } else {
            translate(p1) {
                cuboid(size=size, chamfer=chamfer, rounding=rounding, edges=edges, trimcorners=trimcorners, anchor=-[1,1,1]) children();
            }
        }
    } else {
        rr = max(default(chamfer,0), default(rounding,0));
        if (rr>0) {
            minx = max(
                edges.y[0] + edges.y[1], edges.y[2] + edges.y[3],
                edges.z[0] + edges.z[1], edges.z[2] + edges.z[3],
                edges.y[0] + edges.z[1], edges.y[0] + edges.z[3],
                edges.y[1] + edges.z[0], edges.y[1] + edges.z[2],
                edges.y[2] + edges.z[1], edges.y[2] + edges.z[3],
                edges.y[3] + edges.z[0], edges.y[3] + edges.z[2]
            ) * rr;
            miny = max(
                edges.x[0] + edges.x[1], edges.x[2] + edges.x[3],
                edges.z[0] + edges.z[2], edges.z[1] + edges.z[3],
                edges.x[0] + edges.z[2], edges.x[0] + edges.z[3],
                edges.x[1] + edges.z[0], edges.x[1] + edges.z[1],
                edges.x[2] + edges.z[2], edges.x[2] + edges.z[3],
                edges.x[3] + edges.z[0], edges.x[3] + edges.z[1]
            ) * rr;
            minz = max(
                edges.x[0] + edges.x[2], edges.x[1] + edges.x[3],
                edges.y[0] + edges.y[2], edges.y[1] + edges.y[3],
                edges.x[0] + edges.y[2], edges.x[0] + edges.y[3],
                edges.x[1] + edges.y[2], edges.x[1] + edges.y[3],
                edges.x[2] + edges.y[0], edges.x[2] + edges.y[1],
                edges.x[3] + edges.y[0], edges.x[3] + edges.y[1]
            ) * rr;
            check =
                assert(minx <= size.x, "Rounding or chamfering too large for cuboid size in the X axis.")
                assert(miny <= size.y, "Rounding or chamfering too large for cuboid size in the Y axis.")
                assert(minz <= size.z, "Rounding or chamfering too large for cuboid size in the Z axis.")
            ;
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
                    checks = assert(edges == EDGES_ALL || edges[2] == [0,0,0,0], "Cannot use negative chamfer with Z aligned edges.");
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
                                    ce = _corner_edges(edges, [xa,ya,za]);
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
                                tsphere(r=rounding, $fn=sides);
                            } else {
                                intersection() {
                                    xtcyl(r=rounding, l=rounding*2, $fn=sides);
                                    ytcyl(r=rounding, l=rounding*2, $fn=sides);
                                    cyl(r=rounding, h=rounding*2, $fn=sides);
                                }
                            }
                        }
                    }
                } else if (rounding<0) {
                    checks = assert(edges == EDGES_ALL || edges[2] == [0,0,0,0], "Cannot use negative rounding with Z aligned edges.");
                    ard = abs(rounding);
                    cube(size, center=true);

                    // External-Rounding mask edges
                    difference() {
                        union() {
                            for (i = [0:3], axis=[0:1]) {
                                if (edges[axis][i]>0) {
                                    vec = EDGE_OFFSETS[axis][i];
                                    translate(v_mul(vec/2, size+[ard,ard,-ard]-[0.01,0.01,0])) {
                                        rotate(majrots[axis]) {
                                            cube([ard, ard, size[axis]], center=true);
                                        }
                                    }
                                }
                            }

                            // Add multi-edge corners.
                            if (trimcorners) {
                                for (za=[-1,1], ya=[-1,1], xa=[-1,1]) {
                                    ce = _corner_edges(edges, [xa,ya,za]);
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



// Function&Module: prismoid()
//
// Usage: Typical Prismoids
//   prismoid(size1, size2, h|l, [shift], ...) [ATTACHMENTS];
// Usage: Chamfered Prismoids
//   prismoid(size1, size2, h|l, [chamfer=], ...) [ATTACHMENTS];
//   prismoid(size1, size2, h|l, [chamfer1=], [chamfer2=], ...) [ATTACHMENTS];
// Usage: Rounded Prismoids
//   prismoid(size1, size2, h|l, [rounding=], ...) [ATTACHMENTS];
//   prismoid(size1, size2, h|l, [rounding1=], [rounding2=], ...) [ATTACHMENTS];
// Usage: As Function
//   vnf = prismoid(size1, size2, h|l, [shift], [rounding], [chamfer]);
//   vnf = prismoid(size1, size2, h|l, [shift], [rounding1], [rounding2], [chamfer1], [chamfer2]);
//
// Description:
//   Creates a rectangular prismoid shape with optional roundovers and chamfering.
//   You can only round or chamfer the vertical(ish) edges.  For those edges, you can
//   specify rounding and/or chamferring per-edge, and for top and bottom separately.
//   If you want to round the bottom or top edges see {{rounded_prism()}}.  
//
// Arguments:
//   size1 = [width, length] of the bottom end of the prism.
//   size2 = [width, length] of the top end of the prism.
//   h/l = Height of the prism.
//   shift = [X,Y] amount to shift the center of the top end with respect to the center of the bottom end.
//   ---
//   rounding = The roundover radius for the vertical-ish edges of the prismoid.  If given as a list of four numbers, gives individual radii for each corner, in the order [X+Y+,X-Y+,X-Y-,X+Y-]. Default: 0 (no rounding)
//   rounding1 = The roundover radius for the bottom of the vertical-ish edges of the prismoid.  If given as a list of four numbers, gives individual radii for each corner, in the order [X+Y+,X-Y+,X-Y-,X+Y-].
//   rounding2 = The roundover radius for the top of the vertical-ish edges of the prismoid.  If given as a list of four numbers, gives individual radii for each corner, in the order [X+Y+,X-Y+,X-Y-,X+Y-].
//   chamfer = The chamfer size for the vertical-ish edges of the prismoid.  If given as a list of four numbers, gives individual chamfers for each corner, in the order [X+Y+,X-Y+,X-Y-,X+Y-].  Default: 0 (no chamfer)
//   chamfer1 = The chamfer size for the bottom of the vertical-ish edges of the prismoid.  If given as a list of four numbers, gives individual chamfers for each corner, in the order [X+Y+,X-Y+,X-Y-,X+Y-].
//   chamfer2 = The chamfer size for the top of the vertical-ish edges of the prismoid.  If given as a list of four numbers, gives individual chamfers for each corner, in the order [X+Y+,X-Y+,X-Y-,X+Y-].
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
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
    checks =
        assert(is_num(size1) || is_vector(size1,2))
        assert(is_num(size2) || is_vector(size2,2))
        assert(is_num(h) || is_num(l))
        assert(is_vector(shift,2))
        assert(is_num(rounding) || is_vector(rounding,4), "Bad rounding argument.")
        assert(is_undef(rounding1) || is_num(rounding1) || is_vector(rounding1,4), "Bad rounding1 argument.")
        assert(is_undef(rounding2) || is_num(rounding2) || is_vector(rounding2,4), "Bad rounding2 argument.")
        assert(is_num(chamfer) || is_vector(chamfer,4), "Bad chamfer argument.")
        assert(is_undef(chamfer1) || is_num(chamfer1) || is_vector(chamfer1,4), "Bad chamfer1 argument.")
        assert(is_undef(chamfer2) || is_num(chamfer2) || is_vector(chamfer2,4), "Bad chamfer2 argument.");
    eps = pow(2,-14);
    size1 = is_num(size1)? [size1,size1] : size1;
    size2 = is_num(size2)? [size2,size2] : size2;
    checks2 = 
        assert(all_nonnegative(size1))
        assert(all_nonnegative(size2))
        assert(size1.x + size2.x > 0)
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


// Function&Module: octahedron()
// Usage: As Module
//   octahedron(size, ...) [ATTACHMENTS];
// Usage: As Function
//   vnf = octahedron(size, ...);
// Description:
//   When called as a module, creates an octahedron with axis-aligned points.
//   When called as a function, creates a [[VNF|vnf.scad]] of an octahedron with axis-aligned points.
// Arguments:
//   size = Width of the octahedron, tip to tip.
//   ---
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Example:
//   octahedron(size=40);
// Example: Anchors
//   octahedron(size=40) show_anchors();

module octahedron(size=1, anchor=CENTER, spin=0, orient=UP) {
    vnf = octahedron(size=size);
    attachable(anchor,spin,orient, vnf=vnf, extent=true) {
        vnf_polyhedron(vnf, convexity=2);
        children();
    }
}

function octahedron(size=1, anchor=CENTER, spin=0, orient=UP) =
    let(
        size = scalar_vec3(size),
        s = size/2,
        vnf = [
            [ [0,0,s.z], [s.x,0,0], [0,s.y,0], [-s.x,0,0], [0,-s.y,0], [0,0,-s.z] ],
            [ [0,2,1], [0,3,2], [0,4,3], [0,1,4], [5,1,2], [5,2,3], [5,3,4], [5,4,1] ]
        ]
    ) reorient(anchor,spin,orient, vnf=vnf, extent=true, p=vnf);


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
//   rect_tube(...) ATTACHMENTS;
//
// Description:
//   Creates a rectangular or prismoid tube with optional roundovers and/or chamfers.
//   You can only round or chamfer the vertical(ish) edges.  For those edges, you can
//   specify rounding and/or chamferring per-edge, and for top and bottom, inside and
//   outside  separately.
// Arguments:
//   h/l = The height or length of the rectangular tube.  Default: 1
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
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `BOTTOM`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
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
    checks =
        assert(is_num(h), "l or h argument required.")
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
    checks2 = 
        assert(wall==undef || is_num(wall))
        assert(size1!=undef, "Bad size/size1 argument.")
        assert(size2!=undef, "Bad size/size2 argument.")
        assert(isize1!=undef, "Bad isize/isize1 argument.")
        assert(isize2!=undef, "Bad isize/isize2 argument.")
        assert(isize1.x < size1.x, "Inner size is larger than outer size.")
        assert(isize1.y < size1.y, "Inner size is larger than outer size.")
        assert(isize2.x < size2.x, "Inner size is larger than outer size.")
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
            tag("_H_o_L_e_") prismoid(
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


// Function&Module: wedge()
//
// Usage: As Module
//   wedge(size, [center], ...) [ATTACHMENTS];
// Usage: As Function
//   vnf = wedge(size, [center], ...);
//
// Description:
//   When called as a module, creates a 3D triangular wedge with the hypotenuse in the X+Z+ quadrant.
//   When called as a function, creates a VNF for a 3D triangular wedge with the hypotenuse in the X+Z+ quadrant.
//
// Arguments:
//   size = [width, thickness, height]
//   center = If given, overrides `anchor`.  A true value sets `anchor=CENTER`, false sets `anchor=UP`.
//   ---
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `FRONT+LEFT+BOTTOM`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//
// Example: Centered
//   wedge([20, 40, 15], center=true);
// Example: *Non*-Centered
//   wedge([20, 40, 15]);
// Example: Standard Connectors
//   wedge([20, 40, 15]) show_anchors();

module wedge(size=[1, 1, 1], center, anchor, spin=0, orient=UP)
{
    size = scalar_vec3(size);
    anchor = get_anchor(anchor, center, -[1,1,1], -[1,1,1]);
    vnf = wedge(size, center=true);
    attachable(anchor,spin,orient, size=size, size2=[size.x,0], shift=[0,-size.y/2]) {
        if (size.z > 0) {
            vnf_polyhedron(vnf);
        }
        children();
    }
}


function wedge(size=[1,1,1], center, anchor, spin=0, orient=UP) =
    let(
        size = scalar_vec3(size),
        anchor = get_anchor(anchor, center, -[1,1,1], -[1,1,1]),
        pts = [
            [ 1,1,-1], [ 1,-1,-1], [ 1,-1,1],
            [-1,1,-1], [-1,-1,-1], [-1,-1,1],
        ],
        faces = [
            [0,1,2], [3,5,4], [0,3,1], [1,3,4],
            [1,4,2], [2,4,5], [2,5,3], [0,2,3],
        ],
        vnf = [scale(size/2,p=pts), faces]
    )
    reorient(anchor,spin,orient, size=size, size2=[size.x,0], shift=[0,-size.y/2], p=vnf);


// Section: Cylinders


// Function&Module: cylinder()
// Topics: Shapes (3D), Attachable, VNF Generators
// Usage: As Module
//   cylinder(h, r=/d=, [center=], ...) [ATTACHMENTS];
//   cylinder(h, r1/d1=, r2/d2=, [center=], ...) [ATTACHMENTS];
// Usage: As Function
//   vnf = cylinder(h, r=/d=, [center=], ...);
//   vnf = cylinder(h, r1/d1=, r2/d2=, [center=], ...);
// See Also: cyl()
// Description:
//   Creates a 3D cylinder or conic object with support for anchoring and attachments.
//   This can be used as a drop-in replacement for the built-in `cylinder()` module.
//   When called as a function, returns a [VNF](vnf.scad) for a cylinder.
// Arguments:
//   l / h = The height of the cylinder.
//   r1 = The bottom radius of the cylinder.  (Before orientation.)
//   r2 = The top radius of the cylinder.  (Before orientation.)
//   center = If given, overrides `anchor`.  A true value sets `anchor=CENTER`, false sets `anchor=BOTTOM`.
//   ---
//   d1 = The bottom diameter of the cylinder.  (Before orientation.)
//   d2 = The top diameter of the cylinder.  (Before orientation.)
//   r = The radius of the cylinder.
//   d = The diameter of the cylinder.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Example: By Radius
//   xdistribute(30) {
//       cylinder(h=40, r=10);
//       cylinder(h=40, r1=10, r2=5);
//   }
// Example: By Diameter
//   xdistribute(30) {
//       cylinder(h=40, d=25);
//       cylinder(h=40, d1=25, d2=10);
//   }
// Example(Med): Anchoring
//   cylinder(h=40, r1=10, r2=5, anchor=BOTTOM+FRONT);
// Example(Med): Spin
//   cylinder(h=40, r1=10, r2=5, anchor=BOTTOM+FRONT, spin=45);
// Example(Med): Orient
//   cylinder(h=40, r1=10, r2=5, anchor=BOTTOM+FRONT, spin=45, orient=FWD);
// Example(Big): Standard Connectors
//   xdistribute(40) {
//       cylinder(h=30, d=25) show_anchors();
//       cylinder(h=30, d1=25, d2=10) show_anchors();
//   }

module cylinder(h, r1, r2, center, l, r, d, d1, d2, anchor, spin=0, orient=UP)
{
    anchor = get_anchor(anchor, center, BOTTOM, BOTTOM);
    r1 = get_radius(r1=r1, r=r, d1=d1, d=d, dflt=1);
    r2 = get_radius(r1=r2, r=r, d1=d2, d=d, dflt=1);
    l = first_defined([h, l, 1]);
    attachable(anchor,spin,orient, r1=r1, r2=r2, l=l) {
        _cylinder(h=l, r1=r1, r2=r2, center=true);
        children();
    }
}

function cylinder(h, r1, r2, center, l, r, d, d1, d2, anchor, spin=0, orient=UP) =
    let(
        anchor = get_anchor(anchor, center, BOTTOM, BOTTOM),
        r1 = get_radius(r1=r1, r=r, d1=d1, d=d, dflt=1),
        r2 = get_radius(r1=r2, r=r, d1=d2, d=d, dflt=1),
        l = first_defined([h, l, 1]),
        sides = segs(max(r1,r2)),
        verts = [
            for (i=[0:1:sides-1]) let(a=360*(1-i/sides)) [r1*cos(a),r1*sin(a),-l/2],
            for (i=[0:1:sides-1]) let(a=360*(1-i/sides)) [r2*cos(a),r2*sin(a), l/2],
        ],
        faces = [
            [for (i=[0:1:sides-1]) sides-1-i],
            for (i=[0:1:sides-1]) [i, ((i+1)%sides)+sides, i+sides],
            for (i=[0:1:sides-1]) [i, (i+1)%sides, ((i+1)%sides)+sides],
            [for (i=[0:1:sides-1]) sides+i]
        ]
    ) [reorient(anchor,spin,orient, l=l, r1=r1, r2=r2, p=verts), faces];



// Function&Module: cyl()
//
// Usage: Normal Cylinders
//   cyl(l|h, r, [center], [circum=], [realign=]) [ATTACHMENTS];
//   cyl(l|h, d=, ...) [ATTACHMENTS];
//   cyl(l|h, r1=, r2=, ...) [ATTACHMENTS];
//   cyl(l|h, d1=, d2=, ...) [ATTACHMENTS];
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
// Topics: Cylinders, Textures, Rounding, Chamfers
//
// Description:
//   Creates cylinders in various anchorings and orientations, with optional rounding and chamfers.
//   You can use `h` and `l` interchangably, and all variants allow specifying size by either `r`|`d`,
//   or `r1`|`d1` and `r2`|`d2`.  Note: the chamfers and rounding cannot be cumulatively longer than
//   the cylinder's length.
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
//   shift = [X,Y] amount to shift the center of the top end with respect to the center of the bottom end.
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
//   texture = A texture name string, or a rectangular array of scalar height values (0.0 to 1.0), or a VNF tile that defines the texture to apply to vertical surfaces.  See {{texture()}} for what named textures are supported.
//   tex_size = An optional 2D target size for the textures.  Actual texture sizes will be scaled somewhat to evenly fit the available surface. Default: `[5,5]`
//   tex_counts = If given instead of tex_size, gives the tile repetition counts for textures over the surface length and height.
//   tex_inset = If numeric, lowers the texture into the surface by that amount, before the tex_scale multiplier is applied.  If `true`, insets by exactly `1`.  Default: `false`
//   tex_rot = If true, rotates the texture 90º.
//   tex_scale = Scaling multiplier for the texture depth.
//   tex_samples = Minimum number of "bend points" to have in VNF texture tiles.  Default: 8
//   tex_style = {{vnf_vertex_array()}} style used to triangulate heightfield textures.  Default: "min_edge"
//   tex_taper = If given as a number, tapers the texture height to zero over the first and last given percentage of the path.  If given as a lookup table with indices between 0 and 100, uses the percentage lookup table to ramp the texture heights.  Default: `undef` (no taper)
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//
// See Also: texture(), rotate_sweep()
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
// Example: Texturing with heightfield diamonds
//   cyl(h=40, r=20, texture="diamonds", tex_size=[5,5]);
//
// Example: Texturing with heightfield pyramids
//   cyl(h=40, r1=20, r2=15,
//       texture="pyramids", tex_size=[5,5],
//       tex_style="convex");
//
// Example: Texturing with heightfield truncated pyramids
//   cyl(h=40, r1=20, r2=15, chamfer=5,
//       texture="trunc_pyramids",
//       tex_size=[5,5], tex_style="convex");
//
// Example: Texturing with VNF tile "vnf_dots"
//   cyl(h=40, r1=20, r2=15, rounding=9,
//       texture="vnf_dots", tex_size=[5,5],
//       tex_samples=6);
//
// Example: Texturing with VNF tile "vnf_bricks"
//   cyl(h=50, r1=25, r2=20, shift=[0,10], rounding1=-10,
//       texture="vnf_bricks", tex_size=[10,10],
//       tex_scale=0.5, tex_style="concave");
//
// Example: No Texture Taper
//   cyl(d1=25, d2=20, h=30, rounding=5,
//       texture="trunc_ribs", tex_size=[5,1]);
//
// Example: Taper Texure at Extreme Ends
//   cyl(d1=25, d2=20, h=30, rounding=5,
//       texture="trunc_ribs", tex_taper=0,
//       tex_size=[5,1]);
//
// Example: Taper Texture over First and Last 10%
//   cyl(d1=25, d2=20, h=30, rounding=5,
//       texture="trunc_ribs", tex_taper=10,
//       tex_size=[5,1]);
//
// Example: Making a Clay Pattern Roller
//   tex = [
//       [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,],
//       [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,],
//       [1,1,1,0,0,1,1,1,1,1,1,1,1,1,1,1,],
//       [1,1,1,0,0,1,1,1,1,1,1,1,1,1,1,1,],
//       [0,1,1,0,0,1,1,0,0,0,0,0,0,0,0,0,],
//       [0,1,1,0,0,1,1,0,0,0,0,0,0,0,0,0,],
//       [0,1,1,0,0,1,1,0,0,1,1,1,1,1,1,0,],
//       [0,1,1,0,0,1,1,0,0,1,1,1,1,1,1,0,],
//       [0,1,1,0,0,1,1,0,0,1,1,0,0,1,1,0,],
//       [0,1,1,0,0,1,1,0,0,1,1,0,0,1,1,0,],
//       [0,1,1,0,0,1,1,1,1,1,1,0,0,1,1,0,],
//       [0,1,1,0,0,1,1,1,1,1,1,0,0,1,1,0,],
//       [0,1,1,0,0,0,0,0,0,0,0,0,0,1,1,0,],
//       [0,1,1,0,0,0,0,0,0,0,0,0,0,1,1,0,],
//       [0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,],
//       [0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,],
//       [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,],
//   ];
//   diff()
//   cyl(d=20*10/PI, h=10, chamfer=0,
//       texture=tex, tex_counts=[20,1], tex_scale=-1,
//       tex_taper=undef, tex_style="concave") {
//           attach([TOP,BOT]) {
//               cyl(d1=20*10/PI, d2=30, h=5, anchor=BOT)
//                   attach(TOP) {
//                       tag("remove") zscale(0.5) up(3) sphere(d=15);
//                   }
//           }
//   }

function cyl(
    h, r, center,
    l, r1, r2,
    d, d1, d2,
    length, height,
    chamfer, chamfer1, chamfer2,
    chamfang, chamfang1, chamfang2,
    rounding, rounding1, rounding2,
    circum=false, realign=false,
    from_end=false, shift=[0,0],
    texture, tex_size=[5,5], tex_counts,
    tex_inset=false, tex_rot=false,
    tex_scale=1, tex_samples,
    tex_taper, tex_style="min_edge",
    anchor, spin=0, orient=UP
) =
    let(
        l = first_defined([l, h, length, height, 1]),
        _r1 = get_radius(r1=r1, r=r, d1=d1, d=d, dflt=1),
        _r2 = get_radius(r1=r2, r=r, d1=d2, d=d, dflt=1),
        sides = segs(max(_r1,_r2)),
        sc = circum? 1/cos(180/sides) : 1,
        r1 = _r1 * sc,
        r2 = _r2 * sc,
        phi = atan2(l, r2-r1),
        anchor = get_anchor(anchor,center,BOT,CENTER)
    )
    assert(is_finite(l), "l/h/length/height must be a finite number.")
    assert(is_finite(r1), "r/r1/d/d1 must be a finite number.")
    assert(is_finite(r2), "r2 or d2 must be a finite number.")
    assert(is_vector(shift,2), "shift must be a 2D vector.")
    let(
        vnf = texture != undef? _textured_cylinder(
                l=l, r1=r1, r2=r2,
                texture=texture, tex_size=tex_size,
                counts=tex_counts, tex_scale=tex_scale,
                inset=tex_inset, rot=tex_rot,
                style=tex_style, taper=tex_taper,
                chamfer=chamfer,
                chamfer1=chamfer1,
                chamfer2=chamfer2,
                rounding=rounding,
                rounding1=rounding1,
                rounding2=rounding2,
                samples=tex_samples
            ) :
            !any_defined([chamfer, chamfer1, chamfer2, rounding, rounding1, rounding2])?
                cylinder(h=l, r1=r1, r2=r2, center=true, $fn=sides) :
            let(
                vang = atan2(l, r1-r2)/2,
                chang  = default(chamfang, 45),
                chang1 = 90-first_defined([chamfang1, chamfang, vang]),
                chang2 = 90-first_defined([chamfang2, chamfang, 90-vang]),
                checks1 =
                    assert(is_finite(chang) && chang>0 && chang<90, "chamfang must be a number between 0 and 90 (exclusive) if given.")
                    assert(is_finite(chang1) && chang1>0 && chang1<90, "chamfang1 must be a number between 0 and 90 (exclusive) if given.")
                    assert(is_finite(chang2) && chang2>0 && chang2<90, "chamfang2 must be a number between 0 and 90 (exclusive) if given.")
                    undef,
                chamf = default(chamfer, 0) * (from_end? 1 : tan(chang1)),
                chamf1 = first_defined([chamfer1, chamfer, 0]) * (from_end? 1 : tan(chang1)),
                chamf2 = first_defined([chamfer2, chamfer, 0]) * (from_end? 1 : tan(chang2)),
                round  = default(rounding, 0),
                round1 = first_defined([rounding1, rounding, 0]),
                round2 = first_defined([rounding2, rounding, 0]),
                dy1 = abs(first_defined([chamf1, round1, 0])),
                dy2 = abs(first_defined([chamf2, round2, 0])),
                checks2 =
                    assert(is_finite(chamf), "chamfer must be a finite number if given.")
                    assert(is_finite(chamf1), "chamfer1 must be a finite number if given.")
                    assert(is_finite(chamf2), "chamfer2 must be a finite number if given.")
                    assert(is_finite(round), "rounding must be a finite number if given.")
                    assert(is_finite(round1), "rounding1 must be a finite number if given.")
                    assert(is_finite(round2), "rounding2 must be a finite number if given.")
                    assert(chamf <= r1,  "chamfer is larger than the r1 radius of the cylinder.")
                    assert(chamf <= r2,  "chamfer is larger than the r2 radius of the cylinder.")
                    assert(chamf1 <= r1, "chamfer1 is larger than the r1 radius of the cylinder.")
                    assert(chamf2 <= r2, "chamfer2 is larger than the r2 radius of the cylinder.")
                    assert(round <= r1,  "rounding is larger than the r1 radius of the cylinder.")
                    assert(round <= r2,  "rounding is larger than the r2 radius of the cylinder.")
                    assert(round1 <= r1, "rounding1 is larger than the r1 radius of the cylinder.")
                    assert(round2 <= r2, "rounding2 is larger than the r1 radius of the cylinder.")
                    assert(dy1+dy2 <= l, "Sum of fillets and chamfer sizes must be less than the length of the cylinder.")
                    undef,
                path = [
                    [0,-l/2],
                    if (is_finite(chamf1) && !approx(chamf1,0))
                        let(
                            p1 = [r1-chamf1/tan(chang1),-l/2],
                            p2 = lerp([r1,-l/2],[r2,l/2],abs(chamf1)/l)
                        ) each [p1,p2]
                    else if (is_finite(round1) && !approx(round1,0))
                        each arc(r=abs(round1), corner=[[(round1>0?0:1e6),-l/2],[r1,-l/2],[r2,l/2]])
                    else [r1,-l/2],
                    if (is_finite(chamf2) && !approx(chamf2,0))
                        let(
                            p1 = lerp([r2,l/2],[r1,-l/2],abs(chamf2)/l),
                            p2 = [r2-chamf2/tan(chang2),l/2]
                        ) each [p1,p2]
                    else if (is_finite(round2) && !approx(round2,0))
                        each arc(r=abs(round2), corner=[[r1,-l/2],[r2,l/2],[(round2>0?0:1e6),l/2]])
                    else [r2,l/2],
                    [0,l/2]
                ]
            ) rotate_sweep(path),
        skmat = down(l/2) *
            skew(sxz=shift.x/l, syz=shift.y/l) *
            up(l/2) *
            zrot(realign? 180/sides : 0),
        ovnf = apply(skmat, vnf)
    )
    reorient(anchor,spin,orient, r1=r1, r2=r2, l=l, shift=shift, p=ovnf);


module cyl(
    h, r, center,
    l, r1, r2,
    d, d1, d2,
    chamfer, chamfer1, chamfer2,
    chamfang, chamfang1, chamfang2,
    rounding, rounding1, rounding2,
    circum=false, realign=false,
    from_end=false, shift=[0,0],
    texture, tex_size=[5,5], tex_counts,
    tex_inset=false, tex_rot=false,
    tex_scale=1, tex_samples,
    tex_taper, tex_style="min_edge",
    anchor, spin=0, orient=UP
) {
    l = first_defined([l, h, 1]);
    _r1 = get_radius(r1=r1, r=r, d1=d1, d=d, dflt=1);
    _r2 = get_radius(r1=r2, r=r, d1=d2, d=d, dflt=1);
    sides = segs(max(_r1,_r2));
    sc = circum? 1/cos(180/sides) : 1;
    r1 = _r1 * sc;
    r2 = _r2 * sc;
    phi = atan2(l, r2-r1);
    anchor = get_anchor(anchor,center,BOT,CENTER);
    skmat = down(l/2) * skew(sxz=shift.x/l, syz=shift.y/l) * up(l/2);
    attachable(anchor,spin,orient, r1=r1, r2=r2, l=l, shift=shift) {
        multmatrix(skmat)
        zrot(realign? 180/sides : 0) {
            if (texture != undef) {
                _textured_cylinder(
                    l=l, r1=r1, r2=r2,
                    texture=texture, tex_size=tex_size,
                    counts=tex_counts, tex_scale=tex_scale,
                    inset=tex_inset, rot=tex_rot,
                    style=tex_style, taper=tex_taper,
                    chamfer=chamfer,
                    chamfer1=chamfer1,
                    chamfer2=chamfer2,
                    rounding=rounding,
                    rounding1=rounding1,
                    rounding2=rounding2,
                    convexity=10, samples=tex_samples
                );
            } else if (!any_defined([chamfer, chamfer1, chamfer2, rounding, rounding1, rounding2])) {
                cylinder(h=l, r1=r1, r2=r2, center=true, $fn=sides);
            } else {
                vang = atan2(l, r1-r2)/2;
                chang1 = 90-first_defined([chamfang1, chamfang, vang,]);
                chang2 = 90-first_defined([chamfang2, chamfang, 90-vang]);
                chamf = default(chamfer, 0) * (from_end? 1 : tan(chang1));
                chamf1 = first_defined([chamfer1, chamfer, 0]) * (from_end? 1 : tan(chang1));
                chamf2 = first_defined([chamfer2, chamfer, 0]) * (from_end? 1 : tan(chang2));
                round = default(rounding, 0);
                round1 = first_defined([rounding1, rounding, 0]);
                round2 = first_defined([rounding2, rounding, 0]);
                dy1 = abs(first_defined([chamf1, round1, 0]));
                dy2 = abs(first_defined([chamf2, round2, 0]));
                checks =
                    assert(chamf <= r1,  "chamfer is larger than the r1 radius of the cylinder.")
                    assert(chamf <= r2,  "chamfer is larger than the r2 radius of the cylinder.")
                    assert(chamf1 <= r1, "chamfer1 is larger than the r1 radius of the cylinder.")
                    assert(chamf2 <= r2, "chamfer2 is larger than the r2 radius of the cylinder.")
                    assert(round <= r1,  "rounding is larger than the r1 radius of the cylinder.")
                    assert(round <= r2,  "rounding is larger than the r2 radius of the cylinder.")
                    assert(round1 <= r1, "rounding1 is larger than the r1 radius of the cylinder.")
                    assert(round2 <= r2, "rounding2 is larger than the r1 radius of the cylinder.")
                    assert(dy1+dy2 <= l, "Sum of fillets and chamfer sizes must be less than the length of the cylinder.")
                    undef;
                path = [
                    [0,-l/2],
                    if (is_finite(chamf1) && !approx(chamf1,0))
                        let(
                            p1 = [r1-chamf1/tan(chang1),-l/2],
                            p2 = lerp([r1,-l/2],[r2,l/2],abs(chamf1)/l)
                        ) each [p1,p2]
                    else if (is_finite(round1) && !approx(round1,0))
                        each arc(r=abs(round1), corner=[[(round1>0?0:1e6),-l/2],[r1,-l/2],[r2,l/2]])
                    else [r1,-l/2],
                    if (is_finite(chamf2) && !approx(chamf2,0))
                        let(
                            p1 = lerp([r2,l/2],[r1,-l/2],abs(chamf2)/l),
                            p2 = [r2-chamf2/tan(chang2),l/2]
                        ) each [p1,p2]
                    else if (is_finite(round2) && !approx(round2,0))
                        each arc(r=abs(round2), corner=[[r1,-l/2],[r2,l/2],[(round2>0?0:1e6),l/2]])
                    else [r2,l/2],
                    [0,l/2]
                ];

                rotate_extrude(convexity=2) polygon(path);
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
//   xcyl(l|h, r|d=, [anchor=], ...) [ATTACHMENTS];
//   xcyl(l|h, r1=|d1=, r2=|d2=, [anchor=], ...) [ATTACHMENTS];
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
//   circum = If true, cylinder should circumscribe the circle of the given size.  Otherwise inscribes.  Default: `false`
//   chamfer = The size of the chamfers on the ends of the cylinder.  Default: none.
//   chamfer1 = The size of the chamfer on the left end of the cylinder.  Default: none.
//   chamfer2 = The size of the chamfer on the right end of the cylinder.  Default: none.
//   chamfang = The angle in degrees of the chamfers on the ends of the cylinder.
//   chamfang1 = The angle in degrees of the chamfer on the left end of the cylinder.
//   chamfang2 = The angle in degrees of the chamfer on the right end of the cylinder.
//   from_end = If true, chamfer is measured from the end of the cylinder, instead of inset from the edge.  Default: `false`.
//   rounding = The radius of the rounding on the ends of the cylinder.  Default: none.
//   rounding1 = The radius of the rounding on the left end of the cylinder.
//   rounding2 = The radius of the rounding on the right end of the cylinder.
//   realign = If true, rotate the cylinder by half the angle of one face.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
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

module xcyl(
    h, r, d, r1, r2, d1, d2, l,
    chamfer, chamfer1, chamfer2,
    chamfang, chamfang1, chamfang2,
    rounding, rounding1, rounding2,
    circum=false, realign=false, from_end=false,
    anchor=CENTER, spin=0, orient=UP
) {
    r1 = get_radius(r1=r1, r=r, d1=d1, d=d, dflt=1);
    r2 = get_radius(r1=r2, r=r, d1=d2, d=d, dflt=1);
    l = first_defined([l, h, 1]);
    attachable(anchor,spin,orient, r1=r1, r2=r2, l=l, axis=RIGHT) {
        cyl(
            l=l, r1=r1, r2=r2,
            chamfer=chamfer, chamfer1=chamfer1, chamfer2=chamfer2,
            chamfang=chamfang, chamfang1=chamfang1, chamfang2=chamfang2,
            rounding=rounding, rounding1=rounding1, rounding2=rounding2,
            circum=circum, realign=realign, from_end=from_end,
            anchor=CENTER, orient=RIGHT
        );
        children();
    }
}


// Module: ycyl()
//
// Description:
//   Creates a cylinder oriented along the Y axis.
//
// Usage: Typical
//   ycyl(l|h, r|d=, [anchor=], ...) [ATTACHMENTS];
//   ycyl(l|h, r1=|d1=, r2=|d2=, [anchor=], ...) [ATTACHMENTS];
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
//   circum = If true, cylinder should circumscribe the circle of the given size.  Otherwise inscribes.  Default: `false`
//   chamfer = The size of the chamfers on the ends of the cylinder.  Default: none.
//   chamfer1 = The size of the chamfer on the front end of the cylinder.  Default: none.
//   chamfer2 = The size of the chamfer on the back end of the cylinder.  Default: none.
//   chamfang = The angle in degrees of the chamfers on the ends of the cylinder.
//   chamfang1 = The angle in degrees of the chamfer on the front end of the cylinder.
//   chamfang2 = The angle in degrees of the chamfer on the back end of the cylinder.
//   from_end = If true, chamfer is measured from the end of the cylinder, instead of inset from the edge.  Default: `false`.
//   rounding = The radius of the rounding on the ends of the cylinder.  Default: none.
//   rounding1 = The radius of the rounding on the front end of the cylinder.
//   rounding2 = The radius of the rounding on the back end of the cylinder.
//   realign = If true, rotate the cylinder by half the angle of one face.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
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

module ycyl(
    h, r, d, r1, r2, d1, d2, l,
    chamfer, chamfer1, chamfer2,
    chamfang, chamfang1, chamfang2,
    rounding, rounding1, rounding2,
    circum=false, realign=false, from_end=false,
    anchor=CENTER, spin=0, orient=UP
) {
    r1 = get_radius(r1=r1, r=r, d1=d1, d=d, dflt=1);
    r2 = get_radius(r1=r2, r=r, d1=d2, d=d, dflt=1);
    l = first_defined([l, h, 1]);
    attachable(anchor,spin,orient, r1=r1, r2=r2, l=l, axis=BACK) {
        cyl(
            l=l, r1=r1, r2=r2,
            chamfer=chamfer, chamfer1=chamfer1, chamfer2=chamfer2,
            chamfang=chamfang, chamfang1=chamfang1, chamfang2=chamfang2,
            rounding=rounding, rounding1=rounding1, rounding2=rounding2,
            circum=circum, realign=realign, from_end=from_end,
            anchor=CENTER, orient=BACK
        );
        children();
    }
}



// Module: zcyl()
//
// Description:
//   Creates a cylinder oriented along the Z axis.
//
// Usage: Typical
//   zcyl(l|h, r|d=, [anchor=],...) [ATTACHMENTS];
//   zcyl(l|h, r1=|d1=, r2=|d2=, [anchor=],...);
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
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
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

module zcyl(
    h, r, d, r1, r2, d1, d2, l,
    chamfer, chamfer1, chamfer2,
    chamfang, chamfang1, chamfang2,
    rounding, rounding1, rounding2,
    circum=false, realign=false, from_end=false,
    anchor=CENTER, spin=0, orient=UP
) {
    r1 = get_radius(r1=r1, r=r, d1=d1, d=d, dflt=1);
    r2 = get_radius(r1=r2, r=r, d1=d2, d=d, dflt=1);
    l = first_defined([l, h, 1]);
    attachable(anchor,spin,orient, r1=r1, r2=r2, l=l) {
        cyl(
            l=l, r1=r1, r2=r2,
            chamfer=chamfer, chamfer1=chamfer1, chamfer2=chamfer2,
            chamfang=chamfang, chamfang1=chamfang1, chamfang2=chamfang2,
            rounding=rounding, rounding1=rounding1, rounding2=rounding2,
            circum=circum, realign=realign, from_end=from_end,
            anchor=CENTER
        );
        children();
    }
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
//   tube(...) ATTACHMENTS;
//
// Arguments:
//   h / l = height of tube. Default: 1
//   or = Outer radius of tube. Default: 1
//   ir = Inner radius of tube.
//   center = If given, overrides `anchor`.  A true value sets `anchor=CENTER`, false sets `anchor=DOWN`.
//   ---
//   od = Outer diameter of tube.
//   id = Inner diameter of tube.
//   wall = horizontal thickness of tube wall. Default 1
//   or1 = Outer radius of bottom of tube.  Default: value of r)
//   or2 = Outer radius of top of tube.  Default: value of r)
//   od1 = Outer diameter of bottom of tube.
//   od2 = Outer diameter of top of tube.
//   ir1 = Inner radius of bottom of tube.
//   ir2 = Inner radius of top of tube.
//   id1 = Inner diameter of bottom of tube.
//   id2 = Inner diameter of top of tube.
//   realign = If true, rotate the tube by half the angle of one face.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
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
    wall = default(wall, 1);
    r1 = default(orr1, u_add(irr1,wall));
    r2 = default(orr2, u_add(irr2,wall));
    ir1 = default(irr1, u_sub(orr1,wall));
    ir2 = default(irr2, u_sub(orr2,wall));
    checks =
        assert(all_defined([r1, r2, ir1, ir2]), "Must specify two of inner radius/diam, outer radius/diam, and wall width.")
        assert(ir1 <= r1, "Inner radius is larger than outer radius.")
        assert(ir2 <= r2, "Inner radius is larger than outer radius.");
    sides = segs(max(r1,r2));
    anchor = get_anchor(anchor, center, BOT, CENTER);
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



// Function&Module: pie_slice()
//
// Description:
//   Creates a pie slice shape.
//
// Usage: As Module
//   pie_slice(l|h, r, ang, [center]);
//   pie_slice(l|h, d=, ang=, ...);
//   pie_slice(l|h, r1=|d1=, r2=|d2=, ang=, ...);
// Usage: As Function
//   vnf = pie_slice(l|h, r, ang, [center]);
//   vnf = pie_slice(l|h, d=, ang=, ...);
//   vnf = pie_slice(l|h, r1=|d1=, r2=|d2=, ang=, ...);
// Usage: Attaching Children
//   pie_slice(l|h, r, ang, ...) ATTACHMENTS;
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
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//
// Example: Cylindrical Pie Slice
//   pie_slice(ang=45, l=20, r=30);
// Example: Conical Pie Slice
//   pie_slice(ang=60, l=20, d1=50, d2=70);
// Example: Big Slice
//   pie_slice(ang=300, l=20, d1=50, d2=70);
// Example: Generating a VNF
//   vnf = pie_slice(ang=150, l=20, r1=30, r2=50);
//   vnf_polyhedron(vnf);

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

function pie_slice(
    h, r, ang=30, center,
    r1, r2, d, d1, d2, l,
    anchor, spin=0, orient=UP
) = let(
        anchor = get_anchor(anchor, center, BOT, BOT),
        l = first_defined([l, h, 1]),
        r1 = get_radius(r1=r1, r=r, d1=d1, d=d, dflt=10),
        r2 = get_radius(r1=r2, r=r, d1=d2, d=d, dflt=10),
        maxd = max(r1,r2)+0.1,
        sides = ceil(segs(max(r1,r2))*ang/360),
        step = ang/sides,
        vnf = vnf_vertex_array(
            points=[
                for (u = [0,1]) let(
                    h = lerp(-l/2,l/2,u),
                    r = lerp(r1,r2,u)
                ) [
                    for (theta = [0:step:ang+EPSILON])
                        cylindrical_to_xyz(r,theta,h),
                    [0,0,h]
                ]
            ],
            col_wrap=true, caps=true, reverse=true
        )
    ) reorient(anchor,spin,orient, r1=r1, r2=r2, l=l, p=vnf);



// Section: Other Round Objects


// Function&Module: sphere()
// Topics: Shapes (3D), Attachable, VNF Generators
// Usage: As Module
//   sphere(r|d=, [circum=], [style=], ...) [ATTACHMENTS];
// Usage: As Function
//   vnf = sphere(r|d=, [circum=], [style=], ...);
// See Also: spheroid()
// Description:
//   Creates a sphere object, with support for anchoring and attachments.
//   This is a drop-in replacement for the built-in `sphere()` module.
//   When called as a function, returns a [VNF](vnf.scad) for a sphere.
// Arguments:
//   r = Radius of the sphere.
//   ---
//   d = Diameter of the sphere.
//   circum = If true, the sphere is made large enough to circumscribe the sphere of the ideal side.  Otherwise inscribes.  Default: false (inscribes)
//   style = The style of the sphere's construction. One of "orig", "aligned", "stagger", "octa", or "icosa".  Default: "orig"
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Example: By Radius
//   sphere(r=50);
// Example: By Diameter
//   sphere(d=100);
// Example: style="orig"
//   sphere(d=100, style="orig", $fn=10);
// Example: style="aligned"
//   sphere(d=100, style="aligned", $fn=10);
// Example: style="stagger"
//   sphere(d=100, style="stagger", $fn=10);
// Example: style="icosa"
//   sphere(d=100, style="icosa", $fn=10);
//   // In "icosa" style, $fn is quantized
//   //   to the nearest multiple of 5.
// Example: Anchoring
//   sphere(d=100, anchor=FRONT);
// Example: Spin
//   sphere(d=100, anchor=FRONT, spin=45);
// Example: Orientation
//   sphere(d=100, anchor=FRONT, spin=45, orient=FWD);
// Example: Standard Connectors
//   sphere(d=50) show_anchors();
// Example: Called as Function
//   vnf = sphere(d=100, style="icosa");
//   vnf_polyhedron(vnf);

module sphere(r, d, circum=false, style="orig", anchor=CENTER, spin=0, orient=UP) {
    r = get_radius(r=r, d=d, dflt=1);
    if (!circum && style=="orig" && is_num(r)) {
        attachable(anchor,spin,orient, r=r) {
            _sphere(r=r);
            children();
        }
    } else {
        spheroid(
            r=r, circum=circum, style=style,
            anchor=anchor, spin=spin, orient=orient
        ) children();
    }
}

function sphere(r, d, circum=false, style="orig", anchor=CENTER, spin=0, orient=UP) =
    spheroid(r=r, d=d, circum=circum, style=style, anchor=anchor, spin=spin, orient=orient);


// Function&Module: spheroid()
// Usage: Typical
//   spheroid(r|d, [circum], [style]) [ATTACHMENTS];
// Usage: As Function
//   vnf = spheroid(r|d, [circum], [style]);
// Description:
//   Creates a spheroid object, with support for anchoring and attachments.
//   This is a drop-in replacement for the built-in `sphere()` module.
//   When called as a function, returns a [VNF](vnf.scad) for a spheroid.
//   The exact triangulation of this spheroid can be controlled via the `style=`
//   argument, where the value can be one of `"orig"`, `"aligned"`, `"stagger"`,
//   `"octa"`, or `"icosa"`.  
//   - `style="orig"` constructs a sphere the same way that the OpenSCAD `sphere()` built-in does.
//   - `style="aligned"` constructs a sphere where, if `$fn` is a multiple of 4, it has vertices at all axis maxima and minima.  ie: its bounding box is exactly the sphere diameter in length on all three axes.  This is the default.
//   - `style="stagger"` forms a sphere where all faces are triangular, but the top and bottom poles have thinner triangles.
//   - `style="octa"` forms a sphere by subdividing an octahedron.  This makes more uniform faces over the entirety of the sphere, and guarantees the bounding box is the sphere diameter in size on all axes.  The effective `$fn` value is quantized to a multiple of 4.  This is used in constructing rounded corners for various other shapes.
//   - `style="icosa"` forms a sphere by subdividing an icosahedron.  This makes even more uniform faces over the whole sphere.  The effective `$fn` value is quantized to a multiple of 5.  This sphere has a guaranteed bounding box when `$fn` is a multiple of 10.  
//   .
//   By default the object spheroid() produces is a polyhedron whose vertices all lie on the requested sphere.  This means
//   the approximating polyhedron is inscribed in the sphere.
//   The `circum` argument requests a circumscribing sphere, where the true sphere is
//   inside and tangent to all the faces of the approximating polyhedron.  To produce
//   a circumscribing polyhedron, we use the dual polyhedron of the basic form.  The dual of a polyhedron is
//   a new polyhedron whose vertices are obtained from the faces of the parent polyhedron.  
//   The "orig" and "align" forms are duals of each other.  If you request a circumscribing polyhedron in
//   these styles then the polyhedron will look the same as the default inscribing form.  But for the other
//   styles, the duals are completely different from their parents, and from each other.  Generation of the circumscribed versions (duals)
//   for "octa" and "icosa" is fast if you use the module form but can be very slow (several minutes) if you use the functional
//   form and choose a large $fn value.
//   .
//   With style="align", the circumscribed sphere has its maximum radius on the X and Y axes
//   but is undersized on the Z axis.  With style="octa" the circumscribed sphere has faces at each axis, so
//   the radius on the axes is equal to the specified radius, which is the *minimum* radius of the circumscribed sphere.
//   The same thing is true for style="icosa" when $fn is a multiple of 10.  This would enable you to create spherical
//   holes with guaranteed on-axis dimensions.  
// Arguments:
//   r = Radius of the spheroid.
//   style = The style of the spheroid's construction. One of "orig", "aligned", "stagger", "octa", or "icosa".  Default: "aligned"
//   ---
//   d = Diameter of the spheroid.
//   circum = If true, the approximate sphere circumscribes the true sphere of the requested size.  Otherwise inscribes.  Note that for some styles, the circumscribed sphere looks different than the inscribed sphere.  Default: false (inscribes)
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
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
// Example: style="stagger" with circum=true
//   spheroid(d=100, style="stagger", circum=true, $fn=10);
// Example: style="octa", octahedral based tesselation.  In this style, $fn is quantized to a multiple of 4. 
//   spheroid(d=100, style="octa", $fn=10);
// Example: style="octa", with circum=true, produces mostly very irregular hexagonal faces
//   spheroid(d=100, style="octa", circum=true, $fn=16);
// Example: style="icosa", icosahedral based tesselation.  In this style, $fn is quantized to a multiple of 5.
//   spheroid(d=100, style="icosa", $fn=10);  
// Example: style="icosa", circum=true.  This style has hexagons and 12 pentagons, similar to (but not the same as) a soccer ball.
//   spheroid(d=100, style="icosa", circum=true, $fn=10);  
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
// Example: With "orig" the circumscribing sphere has the same form.  The green sphere is a tiny bit oversized so it pokes through the low points in the circumscribed sphere with low $fn.  This demonstrates that these spheres are in fact circumscribing.  
//   color("green")spheroid(r=10.01, $fn=256);
//   spheroid(r=10, style="orig", circum=true, $fn=16);
// Example: With "aligned" the same is true: the circumscribing sphere is also aligned, if $fn is divisible by 4. 
//   color("green")spheroid(r=10.01, $fn=256);
//   spheroid(r=10, style="aligned", circum=true, $fn=16);
// Example: For the other styles, the circumscribing sphere is different, as shown here with "stagger"
//   color("green")spheroid(r=10.01, $fn=256);
//   spheroid(r=10, style="stagger", circum=true, $fn=16);
// Example: The dual of "octa" that provides the circumscribing sphere has weird asymmetric hexagonal faces:
//   color("green")spheroid(r=10.01, $fn=256);
//   spheroid(r=10, style="octa", circum=true, $fn=16);
// Example: The dual of "icosa" features hexagons and always 12 pentagons:
//   color("green")spheroid(r=10.01, $fn=256);
//   spheroid(r=10, style="icosa", circum=true, $fn=16);

module spheroid(r, style="aligned", d, circum=false, dual=false, anchor=CENTER, spin=0, orient=UP)
{
    r = get_radius(r=r, d=d, dflt=1);
    sides = segs(r);
    vsides = ceil(sides/2);
    attachable(anchor,spin,orient, r=r) {
        if (style=="orig" && !circum) {
            merids = [ for (i=[0:1:vsides-1]) 90-(i+0.5)*180/vsides ];
            path = [
                let(a = merids[0]) [0, sin(a)],
                for (a=merids) [cos(a), sin(a)],
                let(a = last(merids)) [0, sin(a)]
            ];
            scale(r) rotate(180) rotate_extrude(convexity=2,$fn=sides) polygon(path);
        }
        // Don't now how to construct faces for these efficiently, so use hull_points, which
        // is very much faster than using hull() as happens in the spheroid() function
        else if (circum && (style=="octa" || style=="icosa")) {
            orig_sphere = spheroid(r,style,circum=false);
            dualvert = _dual_vertices(orig_sphere);
            hull_points(dualvert,fast=true);
        } else {
            vnf = spheroid(r=r, circum=circum, style=style);
            vnf_polyhedron(vnf, convexity=2);
        }
        children();
    }
}


// p is a list of 3 points defining a triangle in any dimension.  N is the number of extra points
// to add, so output triangle has N+2 points on each side.  
function _subsample_triangle(p,N) = 
    [for(i=[0:N+1]) [for (j=[0:N+1-i]) unit(lerp(p[0],p[1],i/(N+1)) + (p[2]-p[0])*j/(N+1))]];


// Input should have only triangular faces
function _dual_vertices(vnf) =
  let(vert=vnf[0])
  [for(face=vnf[1])
      let(planes = select(vert,face))
      //linear_solve3(planes, [for(p=planes) p*p])
      linear_solve3(select(planes,0,2), [for(i=[0:2]) planes[i]*planes[i]]) // Handle larger faces, maybe?
  ];


function spheroid(r, style="aligned", d, circum=false, anchor=CENTER, spin=0, orient=UP) =
    let(
        r = get_radius(r=r, d=d, dflt=1),
        hsides = segs(r),
        vsides = max(2,ceil(hsides/2)),
        octa_steps = round(max(4,hsides)/4),
        icosa_steps = round(max(5,hsides)/5),
        stagger = style=="stagger"
     )
     circum && style=="orig" ?
         let(
              orig_sphere = spheroid(r,"aligned",circum=false),
              dualvert = zrot(360/hsides/2,_dual_vertices(orig_sphere)),
              culledvert = [
                              [for(i=[0:2:2*hsides-1]) dualvert[i]],
                              for(j=[1:vsides-2])
                                 [for(i=[0:2:2*hsides-1]) dualvert[j*2*hsides+i]],
                              [for(i=[1:2:2*hsides-1]) dualvert[i]]
                           ],
              vnf = vnf_vertex_array(culledvert,col_wrap=true,caps=true)
          )
          [reorient(anchor,spin,orient, r=r, p=vnf[0]), vnf[1]]
     :
     circum && (style=="octa" || style=="icosa") ?
         let(
              orig_sphere = spheroid(r,style,circum=false),
              dualvert = _dual_vertices(orig_sphere),
              faces = hull(dualvert)
         )
         [reorient(anchor,spin,orient, r=r, p=dualvert), faces]
     :
     style=="icosa" ?    // subdivide faces of an icosahedron and project them onto a sphere
         let(  
             N = icosa_steps-1,
             // construct an icosahedron
             icovert=[ for(i=[-1,1], j=[-1,1]) each [[0,i,j*PHI], [i,j*PHI,0], [j*PHI,0,i]]],
             icoface = hull(icovert),
             // Subsample face 0 of the icosahedron
             face0 = select(icovert,icoface[0]),
             sampled = r * _subsample_triangle(face0,N),
             dir0 = mean(face0),
             point0 = face0[0]-dir0,
             // Make a rotated copy of the subsampled triangle on each icosahedral face
             tri_list = [sampled,
                         for(i=[1:1:len(icoface)-1])
                 let(face = select(icovert,icoface[i]))
                 apply(frame_map(z=mean(face),x=face[0]-mean(face))
                        *frame_map(z=dir0,x=point0,reverse=true),
                       sampled)],
             // faces for the first triangle group
             faces = vnf_tri_array(tri_list[0],reverse=true)[1],
             size = repeat((N+2)*(N+3)/2,3),
             // Expand to full face list
             fullfaces = [for(i=idx(tri_list)) each [for(f=faces) f+i*size]],
             fullvert = flatten(flatten(tri_list))    // eliminate triangle structure
         ) 
         [reorient(anchor,spin,orient, r=r, p=fullvert), fullfaces]
     :
     let(
        verts = circum && style=="stagger" ? _dual_vertices(spheroid(r,style,circum=false))
              : circum && style=="aligned" ?
                     let(
                         orig_sphere = spheroid(r,"orig",circum=false),
                         dualvert = _dual_vertices(orig_sphere),
                         culledvert = zrot(360/hsides/2,
                                           [dualvert[0],
                                            for(i=[2:2:len(dualvert)-1]) dualvert[i],
                                            dualvert[1]])
                      )
                      culledvert
              : style=="orig"? [
                                 for (i=[0:1:vsides-1])
                                     let(phi = (i+0.5)*180/(vsides))
                                     for (j=[0:1:hsides-1])
                                         let(theta = j*360/hsides)
                                         spherical_to_xyz(r, theta, phi),
                               ]
              : style=="aligned" || style=="stagger"?
                         [ spherical_to_xyz(r, 0, 0),
                           for (i=[1:1:vsides-1])
                               let(phi = i*180/vsides)
                               for (j=[0:1:hsides-1])
                                   let(theta = (j+((stagger && i%2!=0)?0.5:0))*360/hsides)
                                   spherical_to_xyz(r, theta, phi),
                           spherical_to_xyz(r, 0, 180)
                         ]
              : style=="octa"?
                      let(
                           meridians = [
                                        1,
                                        for (i = [1:1:octa_steps]) i*4,
                                        for (i = [octa_steps-1:-1:1]) i*4,
                                        1,
                                       ]
                      )
                      [
                       for (i=idx(meridians), j=[0:1:meridians[i]-1])
                           spherical_to_xyz(r, j*360/meridians[i], i*180/(len(meridians)-1))
                      ]       
              : assert(in_list(style,["orig","aligned","stagger","octa","icosa"])),
        lv = len(verts),
        faces = circum && style=="stagger" ?  
                     let(ptcount=2*hsides)
                     [
                       [for(i=[ptcount-2:-2:0]) i],
                       for(j=[0:hsides-1])
                           [j*2, (j*2+2)%ptcount,ptcount+(j*2+2)%ptcount,ptcount+(j*2+3)%ptcount,ptcount+j*2],
                       for(i=[1:vsides-3])
                           let(base=ptcount*i)
                           for(j=[0:hsides-1])
                               i%2==0 ? [base+2*j, base+(2*j+1)%ptcount, base+(2*j+2)%ptcount,
                                        base+ptcount+(2*j)%ptcount, base+ptcount+(2*j+1)%ptcount, base+ptcount+(2*j-2+ptcount)%ptcount]
                                      : [base+(1+2*j)%ptcount, base+(2*j)%ptcount, base+(2*j+3)%ptcount,
                                         base+ptcount+(3+2*j)%ptcount, base+ptcount+(2*j+2)%ptcount,base+ptcount+(2*j+1)%ptcount],
                       for(j=[0:hsides-1])
                          vsides%2==0
                            ? [(j*2+3)%ptcount, j*2+1, lv-ptcount+(2+j*2)%ptcount, lv-ptcount+(3+j*2)%ptcount, lv-ptcount+(4+j*2)%ptcount]
                            : [(j*2+3)%ptcount, j*2+1, lv-ptcount+(1+j*2)%ptcount, lv-ptcount+(j*2)%ptcount, lv-ptcount+(3+j*2)%ptcount],
                       [for(i=[1:2:ptcount-1]) i],
                     ]       
              : style=="aligned" || style=="stagger" ?  // includes case of aligned with circum == true
                     [
                       for (i=[0:1:hsides-1])
                           let(b2 = lv-2-hsides)
                           each [
                                 [i+1, 0, ((i+1)%hsides)+1],
                                 [lv-1, b2+i+1, b2+((i+1)%hsides)+1],
                                ],
                       for (i=[0:1:vsides-3], j=[0:1:hsides-1])
                           let(base = 1 + hsides*i)
                           each (
                                 (stagger && i%2!=0)? [
                                     [base+j, base+hsides+j%hsides, base+hsides+(j+hsides-1)%hsides],
                                     [base+j, base+(j+1)%hsides, base+hsides+j],
                                 ] : [
                                     [base+j, base+(j+1)%hsides, base+hsides+(j+1)%hsides],
                                     [base+j, base+hsides+(j+1)%hsides, base+hsides+j],
                                 ]  
                           )
                     ]
              : style=="orig"? [
                                [for (i=[0:1:hsides-1]) hsides-i-1],
                                [for (i=[0:1:hsides-1]) lv-hsides+i],
                                for (i=[0:1:vsides-2], j=[0:1:hsides-1])
                                    each [
                                          [(i+1)*hsides+j, i*hsides+j, i*hsides+(j+1)%hsides],
                                          [(i+1)*hsides+j, i*hsides+(j+1)%hsides, (i+1)*hsides+(j+1)%hsides],
                                    ]                   
                               ]
              : /*style=="octa"?*/
                     let(
                         meridians = [
                                      0, 1,
                                      for (i = [1:1:octa_steps]) i*4,
                                      for (i = [octa_steps-1:-1:1]) i*4,
                                      1,       
                                     ],
                         offs = cumsum(meridians),
                         pc = last(offs)-1,
                         os = octa_steps * 2
                     )
                     [
                      for (i=[0:1:3]) [0, 1+(i+1)%4, 1+i],
                      for (i=[0:1:3]) [pc-0, pc-(1+(i+1)%4), pc-(1+i)],
                      for (i=[1:1:octa_steps-1])
                          let(m = meridians[i+2]/4)
                          for (j=[0:1:3], k=[0:1:m-1])
                              let(
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
                              )
                              each [
                                    [p1, p4, p3],
                                    if (k<m-1) [p1, p2, p4],
                                    [p5, p7, p8],
                                    if (k<m-1) [p5, p8, p6],
                                   ],
                     ] 
    ) [reorient(anchor,spin,orient, r=r, p=verts), faces];



// Function&Module: torus()
//
// Usage: As Module
//   torus(r_maj|d_maj, r_min|d_min, [center], ...) [ATTACHMENTS];
//   torus(or|od, ir|id, ...) [ATTACHMENTS];
//   torus(r_maj|d_maj, or|od, ...) [ATTACHMENTS];
//   torus(r_maj|d_maj, ir|id, ...) [ATTACHMENTS];
//   torus(r_min|d_min, or|od, ...) [ATTACHMENTS];
//   torus(r_min|d_min, ir|id, ...) [ATTACHMENTS];
// Usage: As Function
//   vnf = torus(r_maj|d_maj, r_min|d_min, [center], ...);
//   vnf = torus(or|od, ir|id, ...);
//   vnf = torus(r_maj|d_maj, or|od, ...);
//   vnf = torus(r_maj|d_maj, ir|id, ...);
//   vnf = torus(r_min|d_min, or|od, ...);
//   vnf = torus(r_min|d_min, ir|id, ...);
//
// Description:
//   Creates a torus shape.
//
// Figure(2D,Med):
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
//       right(r) fwd(9) rot(-240) text("or",size=10,anchor=CENTER);
//   }
//   rot(135) color("blue") linear_extrude(height=0.01) {
//       stroke([[0,0],[r-r2,0]], endcaps="arrow2",width=2);
//       right((r-r2)/2) back(8) rot(-135) text("ir",size=10,anchor=CENTER);
//   }
//   rot(45) color("blue") linear_extrude(height=0.01) {
//       stroke([[0,0],[r,0]], endcaps="arrow2",width=2);
//       right(r/2) back(8) text("r_maj",size=9,anchor=CENTER);
//   }
//   rot(30) color("blue") linear_extrude(height=0.01) {
//       stroke([[r,0],[r+r2,0]], endcaps="arrow2",width=2);
//       right(r+r2/2) fwd(8) text("r_min",size=7,anchor=CENTER);
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
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
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
//   vnf_polyhedron(torus(d_min=15, od=60), convexity=4);
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
    maj_rad = is_finite(_r_maj)? _r_maj :
        is_finite(_ir) && is_finite(_or)? (_or + _ir)/2 :
        is_finite(_ir) && is_finite(_r_min)? (_ir + _r_min) :
        is_finite(_or) && is_finite(_r_min)? (_or - _r_min) :
        assert(false, "Bad Parameters");
    min_rad = is_finite(_r_min)? _r_min :
        is_finite(_ir)? (maj_rad - _ir) :
        is_finite(_or)? (_or - maj_rad) :
        assert(false, "Bad Parameters");
    anchor = get_anchor(anchor, center, BOT, CENTER);
    attachable(anchor,spin,orient, r=(maj_rad+min_rad), l=min_rad*2) {
        rotate_extrude(convexity=4) {
            right_half(s=min_rad*2, planar=true)
                right(maj_rad)
                    circle(r=min_rad);
        }
        children();
    }
}


function torus(
    r_maj, r_min, center,
    d_maj, d_min,
    or, od, ir, id,
    anchor, spin=0, orient=UP
) = let(
    _or = get_radius(r=or, d=od, dflt=undef),
    _ir = get_radius(r=ir, d=id, dflt=undef),
    _r_maj = get_radius(r=r_maj, d=d_maj, dflt=undef),
    _r_min = get_radius(r=r_min, d=d_min, dflt=undef),
    maj_rad = is_finite(_r_maj)? _r_maj :
        is_finite(_ir) && is_finite(_or)? (_or + _ir)/2 :
        is_finite(_ir) && is_finite(_r_min)? (_ir + _r_min) :
        is_finite(_or) && is_finite(_r_min)? (_or - _r_min) :
        assert(false, "Bad Parameters"),
    min_rad = is_finite(_r_min)? _r_min :
        is_finite(_ir)? (maj_rad - _ir) :
        is_finite(_or)? (_or - maj_rad) :
        assert(false, "Bad Parameters"),
    anchor = get_anchor(anchor, center, BOT, CENTER),
    maj_sides = segs(maj_rad+min_rad),
    maj_step = 360 / maj_sides,
    min_sides = segs(min_rad),
    min_step = 360 / min_sides,
    xyprofile = min_rad <= maj_rad? right(maj_rad, p=circle(r=min_rad)) :
        right_half(p=right(maj_rad, p=circle(r=min_rad)))[0],
    profile = xrot(90, p=path3d(xyprofile)),
    vnf = vnf_vertex_array(
        points=[for (a=[0:maj_step:360-EPSILON]) zrot(a, p=profile)],
        caps=false, col_wrap=true, row_wrap=true, reverse=true
    )
) reorient(anchor,spin,orient, r=(maj_rad+min_rad), l=min_rad*2, p=vnf);


// Function&Module: teardrop()
//
// Description:
//   Makes a teardrop shape in the XZ plane. Useful for 3D printable holes.
//
// Usage: Typical
//   teardrop(h|l, r, [ang], [cap_h], ...) [ATTACHMENTS];
//   teardrop(h|l, d=, [ang=], [cap_h=], ...) [ATTACHMENTS];
// Usage: Psuedo-Conical
//   teardrop(h|l, r1=, r2=, [ang=], [cap_h1=], [cap_h2=], ...)  [ATTACHMENTS];
//   teardrop(h|l, d1=, d2=, [ang=], [cap_h1=], [cap_h2=], ...)  [ATTACHMENTS];
// Usage: As Function
//   vnf = teardrop(h|l=, r|d=, [ang=], [cap_h=], ...);
//   vnf = teardrop(h|l=, r1=|d1=, r2=|d2=, [ang=], [cap_h=], ...);
//   vnf = teardrop(h|l=, r1=|d1=, r2=|d2=, [ang=], [cap_h1=], [cap_h2=], ...);
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
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
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
// Example: Getting a VNF
//   vnf = teardrop(r1=25, r2=30, l=20, cap_h1=25, cap_h2=35);
//   vnf_polyhedron(vnf);
// Example: Standard Conical Connectors
//   teardrop(d1=20, d2=30, h=20, cap_h1=11, cap_h2=16)
//       show_anchors(custom=false);
// Example(Spin,VPD=150,Med): Named Conical Connectors
//   teardrop(d1=20, d2=30, h=20, cap_h1=11, cap_h2=16)
//       show_anchors(std=false);

module teardrop(h, r, ang=45, cap_h, r1, r2, d, d1, d2, cap_h1, cap_h2, l, anchor=CENTER, spin=0, orient=UP)
{
    r1 = get_radius(r=r, r1=r1, d=d, d1=d1, dflt=1);
    r2 = get_radius(r=r, r1=r2, d=d, d1=d2, dflt=1);
    l = first_defined([l, h, 1]);
    cap_h1 = first_defined([cap_h1, cap_h]);
    cap_h2 = first_defined([cap_h2, cap_h]);
    sides = segs(max(r1,r2));
    profile1 = teardrop2d(r=r1, ang=ang, cap_h=cap_h1, $fn=sides);
    profile2 = teardrop2d(r=r2, ang=ang, cap_h=cap_h2, $fn=sides);
    tip_y1 = max(column(profile1,1));
    tip_y2 = max(column(profile2,1));
    _cap_h1 = min(default(cap_h1, tip_y1), tip_y1);
    _cap_h2 = min(default(cap_h2, tip_y2), tip_y2);
    capvec = unit([0, _cap_h1-_cap_h2, l]);
    anchors = [
        named_anchor("cap",      [0,0,(_cap_h1+_cap_h2)/2], capvec),
        named_anchor("cap_fwd",  [0,-l/2,_cap_h1],         unit((capvec+FWD)/2)),
        named_anchor("cap_back", [0,+l/2,_cap_h2],         unit((capvec+BACK)/2), 180),
    ];
    attachable(anchor,spin,orient, r1=r1, r2=r2, l=l, axis=BACK, anchors=anchors) {
        rot(from=UP,to=FWD) {
            if (l > 0) {
                if (r1 == r2) {
                    linear_extrude(height=l, center=true, slices=2) {
                        polygon(profile1);
                    }
                } else {
                    hull() {
                        up(l/2-0.001) {
                            linear_extrude(height=0.001, center=false) {
                                polygon(profile1);
                            }
                        }
                        down(l/2) {
                            linear_extrude(height=0.001, center=false) {
                                polygon(profile2);
                            }
                        }
                    }
                }
            }
        }
        children();
    }
}


function teardrop(h, r, ang=45, cap_h, r1, r2, d, d1, d2, cap_h1, cap_h2, l, anchor=CENTER, spin=0, orient=UP) =
    let(
        r1 = get_radius(r=r, r1=r1, d=d, d1=d1, dflt=1),
        r2 = get_radius(r=r, r1=r2, d=d, d1=d2, dflt=1),
        l = first_defined([l, h, 1]),
        cap_h1 = first_defined([cap_h1, cap_h]),
        cap_h2 = first_defined([cap_h2, cap_h]),
        sides = segs(max(r1,r2)),
        profile1 = teardrop2d(r=r1, ang=ang, cap_h=cap_h1, $fn=sides),
        profile2 = teardrop2d(r=r2, ang=ang, cap_h=cap_h2, $fn=sides),
        tip_y1 = max(column(profile1,1)),
        tip_y2 = max(column(profile2,1)),
        _cap_h1 = min(default(cap_h1, tip_y1), tip_y1),
        _cap_h2 = min(default(cap_h2, tip_y2), tip_y2),
        capvec = unit([0, _cap_h1-_cap_h2, l]),
        anchors = [
            named_anchor("cap",      [0,0,(_cap_h1+_cap_h2)/2], capvec),
            named_anchor("cap_fwd",  [0,-l/2,_cap_h1],         unit((capvec+FWD)/2)),
            named_anchor("cap_back", [0,+l/2,_cap_h2],         unit((capvec+BACK)/2), 180),
        ],
        vnf = vnf_vertex_array(
            points = [
                fwd(l/2, p=xrot(90, p=path3d(profile1))),
                back(l/2, p=xrot(90, p=path3d(profile2))),
            ],
            caps=true, col_wrap=true, reverse=true
        )
    ) reorient(anchor,spin,orient, r1=r1, r2=r2, l=l, axis=BACK, anchors=anchors, p=vnf);


// Function&Module: onion()
//
// Description:
//   Creates a sphere with a conical hat, to make a 3D teardrop.
//
// Usage: As Module
//   onion(r|d=, [ang=], [cap_h=], ...) [ATTACHMENTS];
// Usage: As Function
//   vnf = onion(r|d=, [ang=], [cap_h=], ...);
//
// Arguments:
//   r = radius of spherical portion of the bottom. Default: 1
//   ang = Angle of cone on top from vertical. Default: 45 degrees
//   cap_h = If given, height above sphere center to truncate teardrop shape.  Default: `undef` (no truncation)
//   ---
//   d = diameter of spherical portion of bottom.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//
// Extra Anchors:
//   cap = The center of the top of the cap, oriented with the cap face normal.
//   tip = The position where an un-capped onion would come to a point, oriented in the direction the point is from the center.
//
// Example: Typical Shape
//   onion(r=30, ang=30);
// Example: Crop Cap
//   onion(r=30, ang=30, cap_h=40);
// Example: Close Crop
//   onion(r=30, ang=30, cap_h=20);
// Example: Onions are useful for making the tops of large cylindrical voids.
//   difference() {
//       cuboid([100,50,100], anchor=FWD+BOT);
//       down(0.1)
//           cylinder(h=50,d=50,anchor=BOT)
//               attach(TOP)
//                   onion(d=50, cap_h=30);
//   }
// Example: Standard Connectors
//   onion(d=30, ang=30, cap_h=20) show_anchors();

module onion(r, ang=45, cap_h, d, anchor=CENTER, spin=0, orient=UP)
{
    r = get_radius(r=r, d=d, dflt=1);
    xyprofile = teardrop2d(r=r, ang=ang, cap_h=cap_h);
    tip_h = max(column(xyprofile,1));
    _cap_h = min(default(cap_h,tip_h), tip_h);
    anchors = [
        ["cap", [0,0,_cap_h], UP, 0],
        ["tip", [0,0,tip_h], UP, 0]
    ];
    attachable(anchor,spin,orient, r=r, anchors=anchors) {
        rotate_extrude(convexity=2) {
            difference() {
                polygon(xyprofile);
                square([2*r,2*max(_cap_h,r)+1], anchor=RIGHT);
            }
        }
        children();
    }
}


function onion(r, ang=45, cap_h, d, anchor=CENTER, spin=0, orient=UP) =
    let(
        r = get_radius(r=r, d=d, dflt=1),
        xyprofile = right_half(p=teardrop2d(r=r, ang=ang, cap_h=cap_h))[0],
        profile = xrot(90, p=path3d(xyprofile)),
        tip_h = max(column(xyprofile,1)),
        _cap_h = min(default(cap_h,tip_h), tip_h),
        anchors = [
            ["cap", [0,0,_cap_h], UP, 0],
            ["tip", [0,0,tip_h], UP, 0]
        ],
        sides = segs(r),
        step = 360 / sides,
        vnf = vnf_vertex_array(
            points=[for (a = [0:step:360-EPSILON]) zrot(a, p=profile)],
            caps=false, col_wrap=true, row_wrap=true, reverse=true
        )
    ) reorient(anchor,spin,orient, r=r, anchors=anchors, p=vnf);


// Section: Text

// Module: text3d()
// Topics: Attachments, Text
// Usage:
//   text3d(text, [h], [size], [font], ...);
// Description:
//   Creates a 3D text block that supports anchoring and attachment to attachable objects.  You cannot attach children to text. 
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
//   h = Extrusion height for the text.  Default: 1
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
//   orient = Vector to rotate top towards.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// See Also: path_text()
// Extra Anchors:
//   "baseline" = Anchors at the baseline of the text, at the start of the string.
//   str("baseline",VECTOR) = Anchors at the baseline of the text, modified by the X and Z components of the appended vector.
// Examples:
//   text3d("Foobar", h=3, size=10);
//   text3d("Foobar", h=2, size=12, font="Helvetica");
//   text3d("Foobar", h=2, anchor=CENTER);
//   text3d("Foobar", h=2, anchor=str("baseline",CENTER));
//   text3d("Foobar", h=2, anchor=str("baseline",BOTTOM+RIGHT));

module text3d(text, h=1, size=10, font="Helvetica", halign, valign, spacing=1.0, direction="ltr", language="em", script="latin", anchor="baseline[-1,0,-1]", spin=0, orient=UP) {
    no_children($children);
    dummy1 =
        assert(is_undef(anchor) || is_vector(anchor) || is_string(anchor), str("Got: ",anchor))
        assert(is_undef(spin)   || is_vector(spin,3) || is_num(spin), str("Got: ",spin))
        assert(is_undef(orient) || is_vector(orient,3), str("Got: ",orient));
    anchor = default(anchor, CENTER);
    spin =   default(spin,   0);
    orient = default(orient, UP);
    geom = attach_geom(size=[size,size,h]);
    anch = !any([for (c=anchor) c=="["])? anchor :
        let(
            parts = str_split(str_split(str_split(anchor,"]")[0],"[")[1],","),
            vec = [for (p=parts) parse_float(str_strip(p," ",start=true))]
        ) vec;
    ha = anchor=="baseline"? "left" :
        anchor==anch && is_string(anchor)? "center" :
        anch.x<0? "left" :
        anch.x>0? "right" :
        "center";
    va = starts_with(anchor,"baseline")? "baseline" :
        anchor==anch && is_string(anchor)? "center" :
        anch.y<0? "bottom" :
        anch.y>0? "top" :
        "center";
    base = anchor=="baseline"? CENTER :
        anchor==anch && is_string(anchor)? CENTER :
        anch.z<0? BOTTOM :
        anch.z>0? TOP :
        CENTER;
    m = _attach_transform(base,spin,orient,geom);
    multmatrix(m) {
        $parent_anchor = anchor;
        $parent_spin   = spin;
        $parent_orient = orient;
        $parent_geom   = geom;
        $parent_size   = _attach_geom_size(geom);
        $attach_to   = undef;
        if (_is_shown()) {
            _color($color) {
                linear_extrude(height=h, center=true)
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


// This could be replaced with _cut_to_seg_u_form
function _cut_interp(pathcut, path, data) =
  [for(entry=pathcut)
    let(
       a = path[entry[1]-1],
        b = path[entry[1]],
        c = entry[0],
        i = max_index(v_abs(b-a)),
        factor = (c[i]-a[i])/(b[i]-a[i])
    )
    (1-factor)*data[entry[1]-1]+ factor * data[entry[1]]
  ];


// Module: path_text()
// Usage:
//   path_text(path, text, [size], [thickness], [font], [lettersize], [offset], [reverse], [normal], [top], [textmetrics], [kern])
// Description:
//   Place the text letter by letter onto the specified path using textmetrics (if available and requested)
//   or user specified letter spacing.  The path can be 2D or 3D.  In 2D the text appears along the path with letters upright
//   as determined by the path direction.  In 3D by default letters are positioned on the tangent line to the path with the path normal
//   pointing toward the reader.  The path normal points away from the center of curvature (the opposite of the normal produced
//   by path_normals()).  Note that this means that if the center of curvature switches sides the text will flip upside down.
//   If you want text on such a path you must supply your own normal or top vector. 
//   . 
//   Text appears starting at the beginning of the path, so if the 3D path moves right to left
//   then a left-to-right reading language will display in the wrong order. (For a 2D path text will appear upside down.)
//   The text for a 3D path appears positioned to be read from "outside" of the curve (from a point on the other side of the
//   curve from the center of curvature).  If you need the text to read properly from the inside, you can set reverse to
//   true to flip the text, or supply your own normal.  
//   .
//   If you do not have the experimental textmetrics feature enabled then you must specify the space for the letters
//   using lettersize, which can be a scalar or array.  You will have the easiest time getting good results by using
//   a monospace font such as Courier.  Note that even with text metrics, spacing may be different because path_text()
//   doesn't do kerning to adjust positions of individual glyphs.  Also if your font has ligatures they won't be used.  
//   .
//   By default letters appear centered on the path.  The offset can be specified to shift letters toward the reader (in
//   the direction of the normal).  
//   .
//   You can specify your own normal by setting `normal` to a direction or a list of directions.  Your normal vector should
//   point toward the reader.  You can also specify
//   top, which directs the top of the letters in a desired direction.  If you specify your own directions and they
//   are not perpendicular to the path then the direction you specify will take priority and the
//   letters will not rest on the tangent line of the path.  Note that the normal or top directions that you
//   specify must not be parallel to the path.
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
//   path = path to place the text on
//   text = text to create
//   size = The font will be created at this size divided by 0.72.   Default: 10
//   thickness = thickness of letters (not allowed for 2D path)
//   font = font to use.  Default: "Liberation Sans"
//   ---
//   lettersize = scalar or array giving size of letters
//   center = center text on the path instead of starting at the first point.  Default: false
//   offset = distance to shift letters "up" (towards the reader).  Not allowed for 2D path.  Default: 0
//   normal = direction or list of directions pointing towards the reader of the text.  Not allowed for 2D path.
//   top = direction or list of directions pointing toward the top of the text
//   reverse = reverse the letters if true.  Not allowed for 2D path.  Default: false
//   textmetrics = if set to true and lettersize is not given then use the experimental textmetrics feature.  You must be running a dev snapshot that includes this feature and have the feature turned on in your preferences.  Default: false
//   kern = scalar or array giving size adjustments for each letter.  Default: 0
// Example(3D,NoScales):  The examples use Courier, a monospaced font.  The width is 1/1.2 times the specified size for this font.  This text could wrap around a cylinder. 
//   path = path3d(arc(100, r=25, angle=[245, 370]));
//   color("red")stroke(path, width=.3);
//   path_text(path, "Example text", font="Courier", size=5, lettersize = 5/1.2);
// Example(3D,NoScales): By setting the normal to UP we can get text that lies flat, for writing around the edge of a disk:
//   path = path3d(arc(100, r=25, angle=[245, 370]));
//   color("red")stroke(path, width=.3);
//   path_text(path, "Example text", font="Courier", size=5, lettersize = 5/1.2, normal=UP);
// Example(3D,NoScales):  If we want text that reads from the other side we can use reverse.  Note we have to reverse the direction of the path and also set the reverse option.  
//   path = reverse(path3d(arc(100, r=25, angle=[65, 190])));
//   color("red")stroke(path, width=.3);
//   path_text(path, "Example text", font="Courier", size=5, lettersize = 5/1.2, reverse=true);
// Example(3D,Med,NoScales): text debossed onto a cylinder in a spiral.  The text is 1 unit deep because it is half in, half out. 
//   text = ("A long text example to wrap around a cylinder, possibly for a few times.");
//   L = 5*len(text);
//   maxang = 360*L/(PI*50);
//   spiral = [for(a=[0:1:maxang]) [25*cos(a), 25*sin(a), 10-30/maxang*a]];
//   difference(){
//     cyl(d=50, l=50, $fn=120);
//     path_text(spiral, text, size=5, lettersize=5/1.2, font="Courier", thickness=2);
//   }
// Example(3D,Med,NoScales): Same example but text embossed.  Make sure you have enough depth for the letters to fully overlap the object. 
//   text = ("A long text example to wrap around a cylinder, possibly for a few times.");
//   L = 5*len(text);
//   maxang = 360*L/(PI*50);
//   spiral = [for(a=[0:1:maxang]) [25*cos(a), 25*sin(a), 10-30/maxang*a]];
//   cyl(d=50, l=50, $fn=120);
//   path_text(spiral, text, size=5, lettersize=5/1.2, font="Courier", thickness=2);
// Example(3D,NoScales): Here the text baseline sits on the path.  (Note the default orientation makes text readable from below, so we specify the normal.)
//   path = arc(100, points = [[-20, 0, 20], [0,0,5], [20,0,20]]);
//   color("red")stroke(path,width=.2);
//   path_text(path, "Example Text", size=5, lettersize=5/1.2, font="Courier", normal=FRONT);
// Example(3D,NoScales): If we use top to orient the text upward, the text baseline is no longer aligned with the path. 
//   path = arc(100, points = [[-20, 0, 20], [0,0,5], [20,0,20]]);
//   color("red")stroke(path,width=.2);
//   path_text(path, "Example Text", size=5, lettersize=5/1.2, font="Courier", top=UP);
// Example(3D,Med,NoScales): This sine wave wrapped around the cylinder has a twisting normal that produces wild letter layout.  We fix it with a custom normal which is different at every path point. 
//   path = [for(theta = [0:360]) [25*cos(theta), 25*sin(theta), 4*cos(theta*4)]];
//   normal = [for(theta = [0:360]) [cos(theta), sin(theta),0]];
//   zrot(-120)
//   difference(){
//     cyl(r=25, h=20, $fn=120);
//     path_text(path, "A sine wave wiggles", font="Courier", lettersize=5/1.2, size=5, normal=normal);
//   }
// Example(3D,Med,NoScales): The path center of curvature changes, and the text flips.  
//   path =  zrot(-120,p=path3d( concat(arc(100, r=25, angle=[0,90]), back(50,p=arc(100, r=25, angle=[268, 180])))));
//   color("red")stroke(path,width=.2);
//   path_text(path, "A shorter example",  size=5, lettersize=5/1.2, font="Courier", thickness=2);
// Example(3D,Med,NoScales): We can fix it with top:
//   path =  zrot(-120,p=path3d( concat(arc(100, r=25, angle=[0,90]), back(50,p=arc(100, r=25, angle=[268, 180])))));
//   color("red")stroke(path,width=.2);
//   path_text(path, "A shorter example",  size=5, lettersize=5/1.2, font="Courier", thickness=2, top=UP);
// Example(2D,NoScales): With a 2D path instead of 3D there's no ambiguity about direction and it works by default:
//   path =  zrot(-120,p=concat(arc(100, r=25, angle=[0,90]), back(50,p=arc(100, r=25, angle=[268, 180]))));
//   color("red")stroke(path,width=.2);
//   path_text(path, "A shorter example",  size=5, lettersize=5/1.2, font="Courier");
// Example(3D,NoScales): The kern parameter lets you adjust the letter spacing either with a uniform value for each letter, or with an array to make adjustments throughout the text.  Here we show a case where adding some extra space gives a better look in a tight circle.  When textmetrics are off, `lettersize` can do this job, but with textmetrics, you'll need to use `kern` to make adjustments relative to the text metric sizes.
//   path = path3d(arc(100, r=12, angle=[150, 450]));
//   color("red")stroke(path, width=.3);
//   kern = [1,1.2,1,1,.3,-.2,1,0,.8,1,1.1,1];
//   path_text(path, "Example text", font="Courier", size=5, lettersize = 5/1.2, kern=kern, normal=UP);

module path_text(path, text, font, size, thickness, lettersize, offset=0, reverse=false, normal, top, center=false, textmetrics=false, kern=0)
{
  no_children($children);
  dummy2=assert(is_path(path,[2,3]),"Must supply a 2d or 3d path")
         assert(num_defined([normal,top])<=1, "Cannot define both \"normal\" and \"top\"");
  dim = len(path[0]);
  normalok = is_undef(normal) || is_vector(normal,3) || (is_path(normal,3) && len(normal)==len(path));
  topok = is_undef(top) || is_vector(top,dim) || (dim==2 && is_vector(top,3) && top[2]==0)
                        || (is_path(top,dim) && len(top)==len(path));
  dummy4 = assert(dim==3 || is_undef(thickness), "Cannot give a thickness with 2d path")
           assert(dim==3 || !reverse, "Reverse not allowed with 2d path")
           assert(dim==3 || offset==0, "Cannot give offset with 2d path")
           assert(dim==3 || is_undef(normal), "Cannot define \"normal\" for a 2d path, only \"top\"")
           assert(normalok,"\"normal\" must be a vector or path compatible with the given path")
           assert(topok,"\"top\" must be a vector or path compatible with the given path");
  thickness = first_defined([thickness,1]);
  normal = is_vector(normal) ? repeat(normal, len(path))
         : is_def(normal) ? normal
         : undef;

  top = is_vector(top) ? repeat(dim==2?point2d(top):top, len(path))
         : is_def(top) ? top
         : undef;

  kern = force_list(kern, len(text));
  dummy3 = assert(is_list(kern) && len(kern)==len(text), "kern must be a scalar or list whose length is len(text)");
  
  lsize = kern + (
          is_def(lettersize) ? force_list(lettersize, len(text))
        : textmetrics ? [for(letter=text) let(t=textmetrics(letter, font=font, size=size)) t.advance[0]]
        : assert(false, "textmetrics disabled: Must specify letter size")
  );
  textlength = sum(lsize);
  dummy1 = assert(textlength<=path_length(path),"Path is too short for the text");

  start = center ? (path_length(path) - textlength)/2 : 0;
   
  pts = _path_cut_points(path, add_scalar([0, each cumsum(lsize)],start+lsize[0]/2), direction=true);

  usernorm = is_def(normal);
  usetop = is_def(top);
  
  normpts = is_undef(normal) ? (reverse?1:-1)*column(pts,3) : _cut_interp(pts,path, normal);
  toppts = is_undef(top) ? undef : _cut_interp(pts,path,top);
  for (i = idx(text)) {
    tangent = pts[i][2];
    checks =
        assert(!usetop || !approx(tangent*toppts[i],norm(top[i])*norm(tangent)),
               str("Specified top direction parallel to path at character ",i))
        assert(usetop || !approx(tangent*normpts[i],norm(normpts[i])*norm(tangent)),
               str("Specified normal direction parallel to path at character ",i));
    adjustment = usetop ?  (tangent*toppts[i])*toppts[i]/(toppts[i]*toppts[i])
               : usernorm ?  (tangent*normpts[i])*normpts[i]/(normpts[i]*normpts[i])
               : [0,0,0];
    move(pts[i][0]) {
      if (dim==3) {
        frame_map(
          x=tangent-adjustment,
          z=usetop ? undef : normpts[i],
          y=usetop ? toppts[i] : undef
        ) up(offset-thickness/2) {
          linear_extrude(height=thickness)
            left(lsize[0]/2)
              text(text[i], font=font, size=size);
        }
      } else {
          frame_map(
            x=point3d(tangent-adjustment),
            y=point3d(usetop ? toppts[i] : -normpts[i])
          ) left(lsize[0]/2) {
              text(text[i], font=font, size=size);
          }
      }
    }
  }
}



// Section: Miscellaneous


// Module: interior_fillet()
//
// Description:
//   Creates a shape that can be unioned into a concave joint between two faces, to fillet them.
//   Center this part along the concave edge to be chamfered and union it in.
//
// Usage: Typical
//   interior_fillet(l, r, [ang], [overlap], ...) [ATTACHMENTS];
//   interior_fillet(l, d=, [ang=], [overlap=], ...) [ATTACHMENTS];
//
// Arguments:
//   l = Length of edge to fillet.
//   r = Radius of fillet.
//   ang = Angle between faces to fillet.
//   overlap = Overlap size for unioning with faces.
//   ---
//   d = Diameter of fillet.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `FRONT+LEFT`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//
// Example:
//   union() {
//     translate([0,2,-4])
//       cube([20, 4, 24], anchor=BOTTOM);
//     translate([0,-10,-4])
//       cube([20, 20, 4], anchor=BOTTOM);
//     color("green")
//       interior_fillet(
//         l=20, r=10,
//         spin=180, orient=RIGHT
//       );
//   }
//
// Examples:
//   interior_fillet(l=10, r=20, ang=60);
//   interior_fillet(l=10, r=20, ang=90);
//   interior_fillet(l=10, r=20, ang=120);
//
// Example: Using with Attachments
//   cube(50,center=true) {
//     position(FRONT+LEFT)
//       interior_fillet(l=50, r=10, spin=-90);
//     position(BOT+FRONT)
//       interior_fillet(l=50, r=10, spin=180, orient=RIGHT);
//   }

module interior_fillet(l=1.0, r, ang=90, overlap=0.01, d, anchor=CENTER, spin=0, orient=UP) {
    r = get_radius(r=r, d=d, dflt=1);
    steps = ceil(segs(r)*(180-ang)/360);
    arc = arc(n=steps+1, r=r, corner=[polar_to_xy(r,ang),[0,0],[r,0]]);
    maxx = last(arc).x;
    maxy = arc[0].y;
    path = [
        [maxx, -overlap],
        polar_to_xy(overlap, 180+ang/2),
        arc[0] + polar_to_xy(overlap, 90+ang),
        each arc
    ];
    attachable(anchor,spin,orient, size=[2*maxx,2*maxy,l]) {
        if (l > 0) {
            linear_extrude(height=l, convexity=4, center=true) {
                polygon(path);
            }
        }
        children();
    }
}


// Function&Module: heightfield()
// Usage: As Module
//   heightfield(data, [size], [bottom], [maxz], [xrange], [yrange], [style], [convexity], ...) [ATTACHMENTS];
// Usage: As Function
//   vnf = heightfield(data, [size], [bottom], [maxz], [xrange], [yrange], [style], ...);
// Topics: Textures, Heightfield
// Description:
//   Given a regular rectangular 2D grid of scalar values, or a function literal, generates a 3D
//   surface where the height at any given point is the scalar value for that position.
//   One script to convert a grayscale image to a heightfield array in a .scad file can be found at:
//   https://raw.githubusercontent.com/revarbat/BOSL2/master/scripts/img2scad.py
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
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// See Also: heightfield(), cylindrical_heightfield()
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
        vnf = vnf_join([
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


// Function&Module: cylindrical_heightfield()
// Usage: As Function
//   vnf = cylindrical_heightfield(data, l, r|d=, [base=], [transpose=], [aspect=]);
// Usage: As Module
//   cylindrical_heightfield(data, l, r|d=, [base=], [transpose=], [aspect=]) [ATTACHMENTS];
// Topics: Extrusion, Textures, Knurling, Heightfield
// Description:
//   Given a regular rectangular 2D grid of scalar values, or a function literal of signature (x,y), generates
//   a cylindrical 3D surface where the height at any given point above the radius `r=`, is the scalar value
//   for that position.
//   One script to convert a grayscale image to a heightfield array in a .scad file can be found at:
//   https://raw.githubusercontent.com/revarbat/BOSL2/master/scripts/img2scad.py
// Arguments:
//   data = This is either the 2D rectangular array of heights, or a function literal of signature `(x, y)`.
//   l = The length of the cylinder to wrap around.
//   r = The radius of the cylinder to wrap around.
//   ---
//   r1 = The radius of the bottom of the cylinder to wrap around.
//   r2 = The radius of the top of the cylinder to wrap around.
//   d = The diameter of the cylinder to wrap around.
//   d1 = The diameter of the bottom of the cylinder to wrap around.
//   d2 = The diameter of the top of the cylinder to wrap around.
//   base = The radius for the bottom of the heightfield object to create.  Any heights smaller than this will be truncated to very slightly above this height.  Default: -20
//   transpose = If true, swaps the radial and length axes of the data.  Default: false
//   aspect = The aspect ratio of the generated heightfield at the surface of the cylinder.  Default: 1
//   xrange = A range of values to iterate X over when calculating a surface from a function literal.  Default: [-1 : 0.01 : 1]
//   yrange = A range of values to iterate Y over when calculating a surface from a function literal.  Default: [-1 : 0.01 : 1]
//   maxh = The maximum height above the radius to model.  Truncates anything taller to this height.  Default: 99
//   style = The style of subdividing the quads into faces.  Valid options are "default", "alt", and "quincunx".  Default: "default"
//   convexity = Max number of times a line could intersect a wall of the surface being formed. Module only.  Default: 10
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// See Also: heightfield(), cylindrical_heightfield()
// Example(VPD=400;VPR=[55,0,150]):
//   cylindrical_heightfield(l=100, r=30, base=5, data=[
//       for (y=[-180:4:180]) [
//           for(x=[-180:4:180])
//           5*cos(5*norm([x,y]))+5
//       ]
//   ]);
// Example(VPD=400;VPR=[55,0,150]):
//   cylindrical_heightfield(l=100, r1=60, r2=30, base=5, data=[
//       for (y=[-180:4:180]) [
//           for(x=[-180:4:180])
//           5*cos(5*norm([x,y]))+5
//       ]
//   ]);
// Example(VPD=400;VPR=[55,0,150]): Heightfield by Function
//   fn = function (x,y) 5*sin(x*360)*cos(y*360)+5;
//   cylindrical_heightfield(l=100, r=30, data=fn);
// Example(VPD=400;VPR=[55,0,150]): Heightfield by Function, with Specific Ranges
//   fn = function (x,y) 2*cos(5*norm([x,y]));
//   cylindrical_heightfield(
//       l=100, r=30, base=5, data=fn,
//       xrange=[-180:2:180], yrange=[-180:2:180]
//   );

function cylindrical_heightfield(
    data, l, r, base=1,
    transpose=false, aspect=1,
    style="min_edge", maxh=99,
    xrange=[-1:0.01:1],
    yrange=[-1:0.01:1],
    r1, r2, d, d1, d2, h, height,
    anchor=CTR, spin=0, orient=UP
) =
    let(
        l = first_defined([l, h, height]),
        r1 = get_radius(r1=r1, r=r, d1=d1, d=d),
        r2 = get_radius(r1=r2, r=r, d1=d2, d=d)
    )
    assert(is_finite(l) && l>0, "Must supply one of l=, h=, or height= as a finite positive number.")
    assert(is_finite(r1) && r1>0, "Must supply one of r=, r1=, d=, or d1= as a finite positive number.")
    assert(is_finite(r2) && r2>0, "Must supply one of r=, r2=, d=, or d2= as a finite positive number.")
    assert(is_finite(base) && base>0, "Must supply base= as a finite positive number.")
    assert(is_matrix(data)||is_function(data), "data= must be a function literal, or contain a 2D array of numbers.")
    let(
        xvals = is_list(data)? [for (x = idx(data[0])) x] :
            is_range(xrange)? [for (x = xrange) x] :
            assert(false, "xrange= must be given as a range if data= is a function literal."),
        yvals = is_list(data)? [for (y = idx(data)) y] :
            is_range(yrange)? [for (y = yrange) y] :
            assert(false, "yrange= must be given as a range if data= is a function literal."),
        xlen = len(xvals),
        ylen = len(yvals),
        stepy = l / (ylen-1),
        stepx = stepy * aspect,
        maxr = max(r1,r2),
        circ = 2 * PI * maxr,
        astep = 360 / circ * stepx,
        arc = astep * (xlen-1),
        bsteps = round(segs(maxr-base) * arc / 360),
        bstep = arc / bsteps
    )
    assert(stepx*xlen <= circ, str("heightfield (",xlen," x ",ylen,") needs a radius of at least ",maxr*stepx*xlen/circ))
    let(
        verts = [
            for (yi = idx(yvals)) let(
                z = yi * stepy - l/2,
                rr = lerp(r1, r2, yi/(ylen-1))
            ) [
                cylindrical_to_xyz(rr-base, -arc/2, z),
                for (xi = idx(xvals)) let( a = xi*astep )
                    let(
                        rad = transpose? (
                                is_list(data)? data[xi][yi] : data(yvals[yi],xvals[xi])
                            ) : (
                                is_list(data)? data[yi][xi] : data(xvals[xi],yvals[yi])
                            ),
                        rad2 = constrain(rad, 0.01-base, maxh)
                    )
                    cylindrical_to_xyz(rr+rad2, a-arc/2, z),
                cylindrical_to_xyz(rr-base, arc/2, z),
                for (b = [1:1:bsteps-1]) let( a = arc/2-b*bstep )
                    cylindrical_to_xyz((z>0?r2:r1)-base, a, l/2*(z>0?1:-1)),
            ]
        ],
        vnf = vnf_vertex_array(verts, caps=true, col_wrap=true, reverse=true, style=style)
    ) reorient(anchor,spin,orient, r1=r1, r2=r2, l=l, p=vnf);


module cylindrical_heightfield(
    data, l, r, base=1,
    transpose=false, aspect=1,
    style="min_edge", convexity=10,
    xrange=[-1:0.01:1], yrange=[-1:0.01:1],
    maxh=99, r1, r2, d, d1, d2, h, height,
    anchor=CTR, spin=0, orient=UP
) {
    l = first_defined([l, h, height]);
    r1 = get_radius(r1=r1, r=r, d1=d1, d=d);
    r2 = get_radius(r1=r2, r=r, d1=d2, d=d);
    vnf = cylindrical_heightfield(
        data, l=l, r1=r1, r2=r2, base=base,
        xrange=xrange, yrange=yrange,
        maxh=maxh, transpose=transpose,
        aspect=aspect, style=style
    );
    attachable(anchor,spin,orient, r1=r1, r2=r2, l=l) {
        vnf_polyhedron(vnf, convexity=convexity);
        children();
    }
}


// Module: ruler()
// Usage:
//   ruler(length, width, [thickness=], [depth=], [labels=], [pipscale=], [maxscale=], [colors=], [alpha=], [unit=], [inch=]) [ATTACHMENTS];
// Description:
//   Creates a ruler for checking dimensions of the model
// Arguments:
//   length = length of the ruler.  Default 100
//   width = width of the ruler.  Default: size of the largest unit division
//   ---
//   thickness = thickness of the ruler. Default: 1
//   depth = the depth of mark subdivisions. Default: 3
//   labels = draw numeric labels for depths where labels are larger than 1.  Default: false
//   pipscale = width scale of the pips relative to the next size up.  Default: 1/3
//   maxscale = log10 of the maximum width divisions to display.  Default: based on input length
//   colors = colors to use for the ruler, a list of two values.  Default: `["black","white"]`
//   alpha = transparency value.  Default: 1.0
//   unit = unit to mark.  Scales the ruler marks to a different length.  Default: 1
//   inch = set to true for a ruler scaled to inches (assuming base dimension is mm).  Default: false
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `LEFT+BACK+TOP`
//   spin = Rotate this many degrees around the Z axis.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Examples(2D,Big):
//   ruler(100,depth=3);
//   ruler(100,depth=3,labels=true);
//   ruler(27);
//   ruler(27,maxscale=0);
//   ruler(100,pipscale=3/4,depth=2);
//   ruler(100,width=2,depth=2);
// Example(2D,Big):  Metric vs Imperial
//   ruler(12,width=50,inch=true,labels=true,maxscale=0);
//   fwd(50)ruler(300,width=50,labels=true);

module ruler(length=100, width, thickness=1, depth=3, labels=false, pipscale=1/3, maxscale,
             colors=["black","white"], alpha=1.0, unit=1, inch=false, anchor=LEFT+BACK+TOP, spin=0, orient=UP)
{
    inchfactor = 25.4;
    checks =
        assert(depth<=5, "Cannot render scales smaller than depth=5")
        assert(len(colors)==2, "colors must contain a list of exactly two colors.");
    length = inch ? inchfactor * length : length;
    unit = inch ? inchfactor*unit : unit;
    maxscale = is_def(maxscale)? maxscale : floor(log(length/unit-EPSILON));
    scales = unit * [for(logsize = [maxscale:-1:maxscale-depth+1]) pow(10,logsize)];
    widthfactor = (1-pipscale) / (1-pow(pipscale,depth));
    width = default(width, scales[0]);
    widths = width * widthfactor * [for(logsize = [0:-1:-depth+1]) pow(pipscale,-logsize)];
    offsets = concat([0],cumsum(widths));
    attachable(anchor,spin,orient, size=[length,width,thickness]) {
        translate([-length/2, -width/2, 0]) 
        for(i=[0:1:len(scales)-1]) {
            count = ceil(length/scales[i]);
            fontsize = 0.5*min(widths[i], scales[i]/ceil(log(count*scales[i]/unit)));
            back(offsets[i]) {
                xcopies(scales[i], n=count, sp=[0,0,0]) union() {
                    actlen = ($idx<count-1) || approx(length%scales[i],0) ? scales[i] : length % scales[i];
                    color(colors[$idx%2], alpha=alpha) {
                        w = i>0 ? quantup(widths[i],1/1024) : widths[i];    // What is the i>0 test supposed to do here? 
                        cube([quantup(actlen,1/1024),quantup(w,1/1024),thickness], anchor=FRONT+LEFT);
                    }
                    mark =
                        i == 0 && $idx % 10 == 0 && $idx != 0 ? 0 :
                        i == 0 && $idx % 10 == 9 && $idx != count-1 ? 1 :
                        $idx % 10 == 4 ? 1 :
                        $idx % 10 == 5 ? 0 : -1;
                    flip = 1-mark*2;
                    if (mark >= 0) {
                        marklength = min(widths[i]/2, scales[i]*2);
                        markwidth = marklength*0.4;
                        translate([mark*scales[i], widths[i], 0]) {
                            color(colors[1-$idx%2], alpha=alpha) {
                                linear_extrude(height=thickness+scales[i]/100, convexity=2, center=true) {
                                    polygon(scale([flip*markwidth, marklength],p=[[0,0], [1, -1], [0,-0.9]]));
                                }
                            }
                        }
                    }
                    if (labels && scales[i]/unit+EPSILON >= 1) {
                        color(colors[($idx+1)%2], alpha=alpha) {
                            linear_extrude(height=thickness+scales[i]/100, convexity=2, center=true) {
                                back(scales[i]*.02) {
                                    text(text=str( $idx * scales[i] / unit), size=fontsize, halign="left", valign="baseline");
                                }
                            }
                        }
                    }

                }
            }
        }
        children();
    }
}





// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
