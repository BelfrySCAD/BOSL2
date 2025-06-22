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
// Synopsis: Creates a cube with anchors for attaching children.
// SynTags: Geom, VNF, Ext
// Topics: Shapes (3D), Attachable, VNF Generators, Textures
// See Also: cuboid(), prismoid()
// Usage: As Module (as in native OpenSCAD)
//   cube(size, [center]);
// Usage: With BOSL2 Attachment extensions
//   cube(size, [center], [anchor=], [spin=], [orient=]) [ATTACHMENTS];
// Usage: As Function (BOSL2 extension)
//   vnf = cube(size, ...);
// Description:
//   Creates a 3D cubic object.
//   This module extends the built-in cube()` module by providing support for attachments and a function form.  
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
    size = force_list(size,3);      // Native cube prints a warning and gives a unit cube when parameters are bogus
    attachable(anchor,spin,orient, size=is_vector(size,3)?size:[1,1,1]) {
        _cube(size, center=true);
        children();
    }
}

function cube(size=1, center, anchor, spin=0, orient=UP) =
    let(
        size = force_list(size,3)
    )
    assert(is_vector(size,3), "\nSize parameter cannot be converted to a 3-vector")
    assert(all_positive(size), "\nAll size components must be positive.")
    let(
        anchor = get_anchor(anchor, center, -[1,1,1], -[1,1,1]),
        unscaled = [
            [-1,-1,-1],[1,-1,-1],[1,1,-1],[-1,1,-1],
            [-1,-1, 1],[1,-1, 1],[1,1, 1],[-1,1, 1],
        ]/2,
        verts = [for (p=unscaled) v_mul(p,size)],
        faces = [
            [0,1,2], [0,2,3],  //BOTTOM
            [0,4,5], [0,5,1],  //FRONT
            [1,5,6], [1,6,2],  //RIGHT
            [2,6,7], [2,7,3],  //BACK
            [3,7,4], [3,4,0],  //LEFT
            [6,4,7], [6,5,4]   //TOP
        ]
    ) [reorient(anchor,spin,orient, size=size, p=verts), faces];



// Module: cuboid()
// Synopsis: Creates a cube with chamfering and roundovers.
// SynTags: Geom
// Topics: Shapes (3D), Attachable
// See Also: prismoid(), rounded_prism()
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
//   teardrop = If given as a number, rounding around the bottom edge of the cuboid won't exceed this many degrees from vertical, altering to a chamfer at that angle.  If true, the limit angle is 45 degrees.  Default: `false`
//   clip_angle = If given as a number, rounding around the bottom edge of the cuboid won't exceed this many degrees from vertical, with the rounding stopping at the bottom of the cuboid.  Default: (no clipping)
//   p1 = Align the cuboid's corner at `p1`, if given.  Forces `anchor=FRONT+LEFT+BOTTOM`.
//   p2 = If given with `p1`, defines the cornerpoints of the cuboid.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Example: Simple regular cube.
//   cuboid(40);
// Example: Cuboid with a corner at the origin
//   cuboid(40, anchor=FRONT+LEFT+BOT);
// Example: Cuboid anchored on its right face
//   cuboid(40, anchor=RIGHT);
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
// Example(VPR=[100,0,25],VPD=180): Rounded Edges and Corners with Clipped Bottoms
//   cuboid([30,40,50], rounding=10, clip_angle=40);
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
//   cuboid([40,20,10], rounding=20, edges=[FWD+RIGHT,BACK+LEFT]);
// Example: Standard anchors
//   cuboid(40) show_anchors();

module cuboid(
    size,
    p1, p2,
    chamfer,
    rounding,
    edges=EDGES_ALL,
    except=[],
    except_edges,
    trimcorners=true,
    teardrop=false,
    clip_angle,
    anchor=CENTER,
    spin=0,
    orient=UP
) {
    module trunc_cube(s,corner) {
        multmatrix(
            (corner.x<0? xflip() : ident(4)) *
            (corner.y<0? yflip() : ident(4)) *
            (corner.z<0? zflip() : ident(4)) *
            scale(s+[1,1,1]*0.001) *
            move(-[1,1,1]/2)
        ) polyhedron(
            [[1,1,1],[1,1,0],[1,0,0],[0,1,1],[0,1,0],[1,0,1],[0,0,1]],
            [[0,1,2],[2,5,0],[0,5,6],[0,6,3],[0,3,4],[0,4,1],[1,4,2],[3,6,4],[5,2,6],[2,4,6]]
        );
    }
    module xtcyl(l,r) {
        if (teardrop) {
            teardrop(r=r, l=l, cap_h=r, ang=teardrop, spin=90, orient=DOWN);
        } else if (is_finite(clip_angle)) {
            cap_h = r * sin(clip_angle);
            down(r-cap_h) teardrop(r=r, l=l, cap_h=cap_h, ang=clip_angle, spin=90, orient=DOWN);
        } else {
            yrot(90) cyl(l=l, r=r);
        }
    }
    module ytcyl(l,r) {
        if (teardrop) {
            teardrop(r=r, l=l, cap_h=r, ang=teardrop, spin=0, orient=DOWN);
        } else if (is_finite(clip_angle)) {
            cap_h = r * sin(clip_angle);
            down(r-cap_h) teardrop(r=r, l=l, cap_h=cap_h, ang=clip_angle, spin=0, orient=DOWN);
        } else {
            zrot(90) yrot(90) cyl(l=l, r=r);
        }
    }
    module tsphere(r) {
        if (teardrop) {
            onion(r=r, cap_h=r, ang=teardrop, orient=DOWN);
        } else if (is_finite(clip_angle)) {
            cap_h = r * sin(clip_angle);
            down(r-cap_h) onion(r=r, cap_h=cap_h, ang=clip_angle, orient=DOWN);
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
                    right(c3.x) {
                        intersection() {
                            xtcyl(l=m, r=r);
                            multmatrix(
                                (corner.y<0? yflip() : ident(4)) *
                                (corner.z<0? zflip() : ident(4))
                            ) {
                                yrot(-90) linear_extrude(height=m+0.1, center=true) {
                                    polygon([[r,0],[0.999*r,0],[0,0.999*r],[0,r],[r,r]]);
                                }
                            }
                        }
                    }
                } else if (e.y) {
                    back(c3.y) {
                        intersection() {
                            ytcyl(l=m, r=r);
                            multmatrix(
                                (corner.x<0? xflip() : ident(4)) *
                                (corner.z<0? zflip() : ident(4))
                            ) {
                                xrot(90) linear_extrude(height=m+0.1, center=true) {
                                    polygon([[r,0],[0.999*r,0],[0,0.999*r],[0,r],[r,r]]);
                                }
                            }
                        }
                    }
                } else if (e.z) {
                    up(c3.z) {
                        intersection() {
                            zcyl(l=m, r=r);
                            multmatrix(
                                (corner.x<0? xflip() : ident(4)) *
                                (corner.y<0? yflip() : ident(4))
                            ) {
                                linear_extrude(height=m+0.1, center=true) {
                                    polygon([[r,0],[0.999*r,0],[0,0.999*r],[0,r],[r,r]]);
                                }
                            }
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
    sizecheck = assert(num_defined([size,p1,p2])!=3, "\nCannot give size if p2 is given (did you forget brackets on the size argument?)")
                assert(is_def(p1) || is_undef(p2), "If p2 is given you must also give p1");
    size = force_list(default(size,1),3);
    edges = _edges(edges, except=first_defined([except_edges,except]));
    teardrop = is_bool(teardrop)&&teardrop? 45 : teardrop;
    chamfer = approx(chamfer,0) ? undef : chamfer;
    rounding = approx(rounding,0) ? undef : rounding;
    checks =
        assert(is_vector(size,3),"Size must be a scalar or 3-vector")
        assert(all_nonnegative(size), "All components of size= must be >=0")
        assert(is_undef(chamfer) || is_finite(chamfer),"chamfer must be a finite value")
        assert(is_undef(rounding) || is_finite(rounding),"rounding must be a finite value")
        assert(is_undef(rounding) || is_undef(chamfer), "Cannot specify nonzero value for both chamfer and rounding")
        assert(teardrop==false || (is_finite(teardrop) && teardrop>0 && teardrop<=90), "teardrop must be either false or an angle number between 0 and 90")
        assert(clip_angle==undef || (is_finite(clip_angle) && clip_angle>0 && clip_angle<=90), "clip_angle must be either false or an angle number between 0 and 90")
        assert(!teardrop || clip_angle==undef, "teardrop= and clip_angle= are mutually exclusive features.")
        assert(is_undef(p1) || is_vector(p1,3), "p1 must be a 3-vector")
        assert(is_undef(p2) || is_vector(p2,3), "p2 must be a 3-vector")
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
// Synopsis: Creates a rectangular prismoid shape with optional roundovers and chamfering.
// SynTags: Geom, VNF
// Topics: Shapes (3D), Attachable, VNF Generators
// See Also: cuboid(), rounded_prism(), trapezoid(), edge_profile()
// Usage: 
//   prismoid(size1, size2, [h|l|height|length], [shift], [xang=], [yang=], ...) [ATTACHMENTS];
// Usage: Chamfered and/or Rounded Prismoids
//   prismoid(size1, size2, h|l|height|length, [chamfer=], [rounding=]...) [ATTACHMENTS];
//   prismoid(size1, size2, h|l|height|length, [chamfer1=], [chamfer2=], [rounding1=], [rounding2=], ...) [ATTACHMENTS];
// Usage: As Function
//   vnf = prismoid(...);
// Description:
//   Creates a rectangular prismoid shape with optional roundovers and chamfering.
//   You can only round or chamfer the vertical(ish) edges.  For those edges, you can
//   specify rounding and/or chamferring per-edge, and for top and bottom separately.
//   If you want to round the bottom or top edges see {{rounded_prism()}} or {{edge_profile()}}
//   .
//   Specification of the prismoid is similar to specification for {{trapezoid()}}.  You can specify the dimensions of the
//   bottom and top and its height to get a symmetric prismoid.  You can use the shift argument to shift the top face around.
//   You can also specify base angles either in the X direction, Y direction or both.  In order to avoid overspecification,
//   you may need to specify a parameter such as size2 as a list of two values, one of which is undef.  For example,
//   specifying `size2=[100,undef]` sets the size in the X direction but allows the size in the Y direction to be computed based on yang.
//   .
//   The anchors on the top and bottom faces have spin pointing back.  The anchors on the side faces have spin point UP.
//   The anchors on the top and bottom edges also have anchors that point clockwise as viewed from outside the shapep.
//   The anchors on the side edges and the corners have spin with positive Z component, pointing along the edge where the anchor is located.
//   A degenerate prismoid with a line segment for the top or bottom has its top or bottom edge anchors set to provide an anchor for that top
//   or bottom edge.  So for example, if the top is `[0,10]` then the top edge is parallel to the Y axis and you can anchor to that
//   edge using the `TOP+RIGHT` or `TOP+LEFT` anchors; these anchors point in the direction that divides the edge in half and provide
//   the `$edge_angle` and `$edge_length` values generally provided by edge anchors.  The UP or DOWN anchor is in the same location but always points
//   in the Z direction and provides no edge data. 
// Arguments:
//   size1 = [width, length] of the bottom end of the prism.
//   size2 = [width, length] of the top end of the prism.
//   h/l/height/length = Height of the prism.
//   shift = [X,Y] amount to shift the center of the top end with respect to the center of the bottom end.
//   ---
//   xang = base angle in the X direction.  Can be a scalar or list of two values, one of which may be undef
//   yang = base angle in the Y direction.  Can be a scalar or list of two values, one of which may be undef
//   rounding = The roundover radius for the vertical-ish edges of the prismoid.  If given as a list of four numbers, gives individual radii for each corner, in the order [X+Y+,X-Y+,X-Y-,X+Y-]. Default: 0 (no rounding)
//   rounding1 = The roundover radius for the bottom of the vertical-ish edges of the prismoid.  If given as a list of four numbers, gives individual radii for each corner, in the order [X+Y+,X-Y+,X-Y-,X+Y-].
//   rounding2 = The roundover radius for the top of the vertical-ish edges of the prismoid.  If given as a list of four numbers, gives individual radii for each corner, in the order [X+Y+,X-Y+,X-Y-,X+Y-].
//   chamfer = The chamfer size for the vertical-ish edges of the prismoid.  If given as a list of four numbers, gives individual chamfers for each corner, in the order [X+Y+,X-Y+,X-Y-,X+Y-].  Default: 0 (no chamfer)
//   chamfer1 = The chamfer size for the bottom of the vertical-ish edges of the prismoid.  If given as a list of four numbers, gives individual chamfers for each corner, in the order [X+Y+,X-Y+,X-Y-,X+Y-].
//   chamfer2 = The chamfer size for the top of the vertical-ish edges of the prismoid.  If given as a list of four numbers, gives individual chamfers for each corner, in the order [X+Y+,X-Y+,X-Y-,X+Y-].
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `BOTTOM`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//
// Example: Truncated Pyramid
//   prismoid(size1=[35,50], size2=[20,30], h=20);
// Example: Rectangular Pyramid
//   prismoid([40,40], [0,0], h=20);
// Example: Prism
//   prismoid(size1=[40,40], size2=[0,40], h=20);
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
// Example: Specifying bottom, height and angle
//   prismoid(size1=[100,75], h=30, xang=50, yang=70);
// Example: Specifying top, height and angle, with asymmetric angles
//   prismoid(size2=[100,75], h=30, xang=[50,60], yang=[70,40]);
// Example: Specifying top, bottom and angle for X and using that to define height.  Note that giving yang here would likely give a conflicting height calculation, which is not allowed.  
//   prismoid(size1=[100,75], size2=[75,35], xang=50);
// Example: The same as the previous example but we give a shift in Y.  Note that shift.x must be undef because you cannot give combine an angle with a shift, so a shift.x value would conflict with xang being defined.  
//   prismoid(size1=[100,75], size2=[75,35], xang=50, shift=[undef,20]);
// Example:  The X dimensions defined by the base length, angle and height; the Y dimensions defined by the top length, angle, and height. 
//   prismoid(size1=[100,undef], size2=[undef,75], h=30, xang=[20,90], yang=30);
// Example: Rounding
//   prismoid(100, 80, rounding=10, h=30);
// Example: Chamfers
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
// Example: How to Round a Top or Bottom Edge
//   diff()
//   prismoid([50,30], [30,20], shift=[3,6], h=15, rounding=[5,0,5,0]) {
//       edge_profile([TOP+RIGHT, BOT+FRONT], excess=10, convexity=20) {
//           mask2d_roundover(h=5,mask_angle=$edge_angle);
//       }
//   }
// Example(Spin,VPD=160,VPT=[0,0,10]): Standard anchors
//   prismoid(size1=[50,30], size2=[20,20], h=20, shift=[15,5])
//       show_anchors();
// Example(3D): When the top or bottom is degenerate, you can anchor to and round the degenerate edge by using either one of the edge anchors that correspond to that edge.  But note that {{edge_profile()}} does not work for this degenerate case.  We used `TOP+RIGHT` below as the anchor point, but `TOP+LEFT` will produce an identical result.   
//   diff()
//   prismoid([10,14],[0,8], shift=[4,3], h=7)
//     attach(TOP+RIGHT, FWD+LEFT, inside=true)
//       rounding_edge_mask(r=2,l=$edge_length+6);

module prismoid(
    size1=undef, size2=undef, h, shift=[undef,undef],
    xang, yang,
    rounding=0, rounding1, rounding2,
    chamfer=0, chamfer1, chamfer2,
    l, height, length, center,
    anchor, spin=0, orient=UP
)
{
    vnf_s1_s2_shift = prismoid(
        size1=size1, size2=size2, h=h, shift=shift,
        xang=xang, yang=yang, 
        rounding=rounding, chamfer=chamfer, 
        rounding1=rounding1, rounding2=rounding2,
        chamfer1=chamfer1, chamfer2=chamfer2,
        l=l, height=height, length=length, anchor=BOT, _return_dim=true
    );
    anchor = get_anchor(anchor, center, BOT, BOT);
    attachable(anchor,spin,orient, size=vnf_s1_s2_shift[1], size2=vnf_s1_s2_shift[2], shift=vnf_s1_s2_shift[3]) {
        down(vnf_s1_s2_shift[1].z/2)
            vnf_polyhedron(vnf_s1_s2_shift[0], convexity=4);
        children();
    }
}

function prismoid(
    size1, size2, h, shift=[0,0],
    rounding=0, rounding1, rounding2,
    chamfer=0, chamfer1, chamfer2,
    l, height, length, center,
    anchor=DOWN, spin=0, orient=UP, xang, yang,
    _return_dim=false
    
) =
    assert(is_undef(shift) || is_num(shift) || len(shift)==2, "shift must be a number or list of length 2")
    assert(is_undef(size1) || is_num(size1) || len(size1)==2, "size1 must be a number or list of length 2")
    assert(is_undef(size2) || is_num(size2) || len(size2)==2, "size2 must be a number or list of length 2")  
    let(
        xang = force_list(xang,2),
        yang = force_list(yang,2),
        yangOK = len(yang)==2 && (yang==[undef,undef] || (all_positive(yang) && yang[0]<180 && yang[1]<180)),
        xangOK = len(xang)==2 && (xang==[undef,undef] || (all_positive(xang) && xang[0]<180 && xang[1]<180)),
        size1=force_list(size1,2),
        size2=force_list(size2,2),
        h=first_defined([l,h,length,height]),
        shift = force_list(shift,2)
    )
    assert(xangOK, "prismoid angles must be scalar or 2-vector, strictly between 0 and 180")
    assert(yangOK, "prismoid angles must be scalar or 2-vector, strictly between 0 and 180")
    assert(xang==[undef,undef] || shift.x==undef, "Cannot specify xang and a shift.x value together")
    assert(yang==[undef,undef] || shift.y==undef, "Cannot specify yang and a shift.y value together")
    assert(all_positive([h]) || is_undef(h), "h must be a positive value")
    let(
        hx = _trapezoid_dims(h,size1.x,size2.x,shift.x,xang)[0],
        hy = _trapezoid_dims(h,size1.y,size2.y,shift.y,yang)[0]
    )
    assert(num_defined([hx,hy])>0, "Height not given and specification does not determine prismoid height")
    assert(hx==undef || hy==undef || approx(hx,hy),
           str("X and Y angle specifications give rise to conflicting height values ",hx," and ",hy))
    let(
        h = first_defined([hx,hy]),
        x_h_w1_w2_shift = _trapezoid_dims(h,size1.x,size2.x,shift.x,xang),
        y_h_w1_w2_shift = _trapezoid_dims(h,size1.y,size2.y,shift.y,yang)
    )
    let(
        s1 = [x_h_w1_w2_shift[1], y_h_w1_w2_shift[1]],
        s2 = [x_h_w1_w2_shift[2], y_h_w1_w2_shift[2]],
        shift = [x_h_w1_w2_shift[3], y_h_w1_w2_shift[3]]
    )
    assert(is_vector(s1,2), "Insufficient information to define prismoid")
    assert(is_vector(s2,2), "Insufficient information to define prismoid")
    assert(all_nonnegative(concat(s1,s2)),"Degenerate prismoid geometry")
    assert(s1.x+s2.x>0 && s1.y+s2.y>0, "Degenerate prismoid geometry")
    assert(is_num(rounding) || is_vector(rounding,4), "rounding must be a number or 4-vector")
    assert(is_undef(rounding1) || is_num(rounding1) || is_vector(rounding1,4), "rounding1 must be a number or 4-vector")
    assert(is_undef(rounding2) || is_num(rounding2) || is_vector(rounding2,4), "rounding2 must be a number or 4-vector")
    assert(is_num(chamfer) || is_vector(chamfer,4), "chamfer must be a number or 4-vector")
    assert(is_undef(chamfer1) || is_num(chamfer1) || is_vector(chamfer1,4), "chamfer1 must be a number or 4-vector")
    assert(is_undef(chamfer2) || is_num(chamfer2) || is_vector(chamfer2,4), "chamfer2 must be a number or 4-vector")
    let(
        chamfer1=force_list(default(chamfer1,chamfer),4),
        chamfer2=force_list(default(chamfer2,chamfer),4),
        rounding1=force_list(default(rounding1,rounding),4),
        rounding2=force_list(default(rounding2,rounding),4)
    )
    assert(all_nonnegative(chamfer1), "chamfer/chamfer1 must be non-negative")
    assert(all_nonnegative(chamfer2), "chamfer/chamfer2 must be non-negative")
    assert(all_nonnegative(rounding1), "rounding/rounding1 must be non-negative")
    assert(all_nonnegative(rounding2), "rounding/rounding2 must be non-negative")        
    assert(all_zero(v_mul(rounding1,chamfer1),0),
           "rounding1 and chamfer1 (possibly inherited from rounding and chamfer) cannot both be nonzero at the same corner")
    assert(all_zero(v_mul(rounding2,chamfer2),0),
           "rounding2 and chamfer2 (possibly inherited from rounding and chamfer) cannot both be nonzero at the same corner")
    let(
        rounding1 = default(rounding1, rounding),
        rounding2 = default(rounding2, rounding),
        chamfer1 = default(chamfer1, chamfer),
        chamfer2 = default(chamfer2, chamfer),
        anchor = get_anchor(anchor, center, BOT, BOT),
        path1 = rect(s1, rounding=rounding1, chamfer=chamfer1, anchor=CTR),
        path2 = rect(s2, rounding=rounding2, chamfer=chamfer2, anchor=CTR),
        points = [
                    each path3d(path1, -h/2),
                    each path3d(move(shift, path2), +h/2),
                 ],
        faces = hull(points),
        vnf = [points, faces]
    )
    _return_dim ? [reorient(anchor,spin,orient, size=[s1.x,s1.y,h], size2=s2, shift=shift, p=vnf),point3d(s1,h),s2,shift]
                : reorient(anchor,spin,orient, size=[s1.x,s1.y,h], size2=s2, shift=shift, p=vnf);



// Function&Module: regular_prism()
// Synopsis: Creates a regular prism with roundovers and chamfering
// SynTags: Geom, VNF
// Topics: Textures, Rounding, Chamfers, Shapes (3D), Attachable 
// See Also: cyl(), rounded_prism(), texture(), linear_sweep(), EDGE(), FACE()
// Usage: Normal prisms
//   regular_prism(n, h|l=|height=|length=, r, [center=], [realign=]) [ATTACHMENTS];
//   regular_prism(n, h|l=|height=|length=, d=|id=|od=|ir=|or=|side=, ...) [ATTACHMENTS];
//   regular_prism(n, h|l=|height=|length=, r1=|d1=|id1=|od1=|ir1=|or1=|side1=,r2=|d2=|id2=|od2=|ir2=|or2=|side2=, ...) [ATTACHMENTS];
// Usage: Chamferred end prisms
//   regular_prism(n, h, r, chamfer=, [chamfang=], [from_end=], ...);
//   regular_prism(n, h, r, chamfer1=, [chamfang1=], [from_end=], ...);
//   regular_prism(n, h, r, chamfer2=, [chamfang2=], [from_end=], ...);
//   regular_prism(n, h, r, chamfer1=, chamfer2=, [chamfang1=], [chamfang2=], [from_end=], ...);
// Usage: Rounded end prisms
//   regular_prism(n, h, r, rounding=, ...);
//   regular_prism(n, h, r, rounding1=, ...);
//   regular_prism(n, h, r, rounding2=, ...);
//   regular_prism(n, h, r, rounding1=, rounding2=, ...);
// Usage: Textured prisms
//   regular_prism(n, h, r, texture=, [tex_size=]|[tex_reps=], [tex_depth=], [tex_rot=], [tex_samples=], [style=], [tex_inset=], ...);
// Usage: Called as a function to get a VNF
//   vnf = rounded_prism(...);
// Description:
//   Creates a prism whose ends are similar `n`-sided regular polygons, with optional rounding, chamfers or textures.
//   You can specify the size of the ends using diameter or radius measured either inside or outside.  Alternatively
//   you can give the length of the side of the polygon.  You can specify chamfers and roundings for the ends, but not
//   the vertical edges.  See {{rounded_prism()}} for prisms with rounded vertical edges.  You can also specify texture for the side
//   faces, but note that texture is not compatible with any roundings or chamfers.
//   See [Texturing](skin.scad#section-texturing) for more details on how textures work.  
//   .
//   Anchors are based on the VNF of the prism.  Especially for tapered or shifted prisms, this may give unexpected anchor positions, such as top side anchors
//   being located at the bottom of the shape, so confirm anchor positions before use.  
//   Additional named face and edge anchors are located on the side faces and vertical edges of the prism.
//   You can use `EDGE(i)`, `EDGE(TOP,i)` and `EDGE(BOT,i)` as a shorthand for accessing the named edge anchors, and `FACE(i)` for the face anchors.
//   The "edge0" anchor identifies an edge located along the X+ axis, and then edges
//   are labeled counting up in the clockwise direction.  Similarly "face0" is the face immediately clockwise from "edge0", and face
//   labeling proceeds clockwise.  The top and bottom edge anchors label edges directly above and below the face with the same label.
//   If you set `realign=true` then "face0" is oriented in the X+ direction.  
//   .
//   This module is very similar to {{cyl()}}.  It differs in the following ways:  you can specify side length or inner radius/diameter, you can apply roundings with
//   different `$fn` than the number of prism faces, you can apply texture to the flat faces without forcing a high facet count,
//   anchors are located on the true object instead of the ideal cylinder and you can anchor to the edges and faces.  Chamfers and roundings
//   for this module are **always** evaluated relative to the faces of the prism and never at corners as is done by default in {{cyl()}}.  
// Named Anchors:
//   "edge0", "edge1", etc. = Center of each side edge, spin pointing up along the edge.  Can access with EDGE(i)
//   "face0", "face1", etc. = Center of each side face, spin pointing up.  Can access with FACE(i)
//   "top_edge0", "top_edge1", etc = Center of each top edge, spin pointing clockwise (from top). Can access with EDGE(TOP,i)
//   "bot_edge0", "bot_edge1", etc = Center of each bottom edge, spin pointing clockwise (from bottom).  Can access with EDGE(BOT,i)
//   "top_corner0", "top_corner1", etc = Top corner, pointing in direction of associated edge anchor, spin up along associated edge
//   "bot_corner0", "bot_corner1", etc = Bottom corner, pointing in direction of associated edge anchor, spin up along associated edge
// Arguments:
//   l / h / length / height = Length of prism
//   r = Outer radius of prism.  
//   center = If given, overrides `anchor`.  A true value sets `anchor=CENTER`, false sets `anchor=DOWN`.
//   ---
//   r1/or1 = Outer radius of the bottom of prism
//   r2/or2 = Outer radius of the top end of prism
//   d = Outer Diameter of prism
//   d1 / od1 = Outer diameter of bottom of prism
//   d2 / od2 = Outer diameter of top end of prism
//   ir = Inner radius of prism
//   ir1 = Inner radius of bottom of prism
//   ir2 = Inner radius of top of prism
//   id = Inner diameter of prism
//   id1 = Inner diameter of bottom of prism
//   id2 = Inner diameter of top of prism
//   side = Side length of prism faces
//   side1 = Side length of prism faces at the bottom
//   side2 = Side length of prism faces at the top
//   shift = [X,Y] amount to shift the center of the top end with respect to the center of the bottom end.
//   chamfer = The size of the chamfers on the ends of the prism.  (Also see: `from_end=`)  Default: none.
//   chamfer1 = The size of the chamfer on the bottom end of the prism.  (Also see: `from_end1=`)  Default: none.
//   chamfer2 = The size of the chamfer on the top end of the prism.  (Also see: `from_end2=`)  Default: none.
//   chamfang = The angle in degrees of the chamfers away from the ends of the prismr.  Default: Chamfer angle is halfway between the endcap and side face.
//   chamfang1 = The angle in degrees of the bottom chamfer away from the bottom end of the prism.  Default: Chamfer angle is halfway between the endcap and side face.
//   chamfang2 = The angle in degrees of the top chamfer away from the top end of the prism.  Default: Chamfer angle is halfway between the endcap and side face.
//   from_end = If true, chamfer is measured along the side face from the ends of the prism, instead of inset from the edge.  Default: `false`.
//   from_end1 = If true, chamfer on the bottom end of the prism is measured along the side face from the end of the prism, instead of inset from the edge.  Default: `false`.
//   from_end2 = If true, chamfer on the top end of the prism is measured along the side face from the end of the prism, instead of inset from the edge.  Default: `false`.
//   rounding = The radius of the rounding on the ends of the prism.  Default: none.
//   rounding1 = The radius of the rounding on the bottom end of the prism.
//   rounding2 = The radius of the rounding on the top end of the prism.
//   realign = If true, rotate the prism by half the angle of one face so that a face points in the X+ direction.  Default: false
//   teardrop = If given as a number, rounding around the bottom edge of the prism won't exceed this many degrees from vertical.  If true, the limit angle is 45 degrees.  Default: `false`
//   clip_angle = If given as a number, rounding around the bottom edge of the prism won't exceed this many degrees from vertical, with the rounding stopping at the bottom of the prism.  Default: (no clipping)
//   texture = A texture name string, or a rectangular array of scalar height values (0.0 to 1.0), or a VNF tile that defines the texture to apply to vertical surfaces.  See {{texture()}} for what named textures are supported.
//   tex_size = An optional 2D target size (2-vector or scalar) for the textures.  Actual texture sizes will be scaled somewhat to evenly fit the available surface. Default: `[5,5]`
//   tex_reps = If given instead of tex_size, a scalar or 2-vector giving the number of texture tile repetitions in the horizontal and vertical directions.
//   tex_inset = If numeric, lowers the texture into the surface by the specified proportion, e.g. 0.5 would lower it half way into the surface.  If `true`, insets by exactly its full depth.  Default: `false`
//   tex_rot = Rotate texture by specified angle, which must be a multiple of 90 degrees.  Default: 0
//   tex_depth = Specify texture depth; if negative, invert the texture.  Default: 1.  
//   tex_samples = Minimum number of "bend points" to have in VNF texture tiles.  Default: 8
//   style = {{vnf_vertex_array()}} style used to triangulate heightfield textures.  Default: "min_edge"
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Example:  Simple prism
//   regular_prism(5,r=10,h=25);
// Example:  With end rounding
//   regular_prism(5,r=10,h=25,rounding=3,$fn=32);
// Example:  With teardrop end rounding
//   regular_prism(5,r=10,h=25,rounding=3,teardrop=40,$fn=32);
// Example:  With clipped end rounding
//   regular_prism(5,r=10,h=25,rounding=3,clip_angle=40,$fn=32);
// Example:  By side length at bottom, inner radius at top, shallow chamfer
//   regular_prism(7, side1=10, ir2=7, height=20,chamfer2=2,chamfang2=20);
// Example: With shift
//   regular_prism(4, d=12, h=10, shift=[12,7]);
// Example: Attaching child to face
//   regular_prism(5, d1=15, d2=10, h=20)
//     recolor("lightblue")
//       attach("face1",BOT) regular_prism(n=4,r1=3,r2=1,h=3);
// Example: Attaching child to edge
//   regular_prism(5, d1=15, d2=10, h=20)
//     recolor("lightblue")
//       attach("edge2",RIGHT) cuboid([4,4,20]);
// Example: Placing child on top along an edge of a regular prism is possible with the top_edge anchors, but you cannot use {{align()}} or {{attach()}}, so you must manually anchor and spin the child by half of the polygon angle (180/n) to get to face0 and then 360/n more for each subsequent face.  If you set `realign=true` then you don't need the initial angle for face0.  
//    regular_prism(5, d1=25, d2=20, h=15, realign=false) color("lightblue"){
//       position("top_edge1") prismoid([5,5],[2,2],h=3,spin=-360/5*1.5,anchor=RIGHT+BOT);
//       position("top_edge3") prismoid([5,5],[2,2],h=3,spin=-360/5*3.5,anchor=RIGHT+BOT);
//    }
// Example: Textured prism
//   regular_prism(5, side=25, h=50, texture="diamonds", tex_size=[5,5], style="concave");
module regular_prism(n, 
    h, r, center,
    l, length, height,
    r1,r2,ir,ir1,ir2,or,or1,or2,side,side1,side2, 
    d, d1, d2,id,id1,id2,od,od1,od2,
    chamfer, chamfer1, chamfer2,
    chamfang, chamfang1, chamfang2,
    rounding, rounding1, rounding2,
    realign=false, shift=[0,0],
    teardrop=false, clip_angle,
    from_end, from_end1, from_end2,
    texture, tex_size=[5,5], tex_reps,
    tex_inset=false, tex_rot=0,
    tex_depth, tex_samples, 
    tex_taper, style,
    anchor, spin=0, orient=UP
)
{ 
    vnf_anchors_ovr = regular_prism(n=n,h=h,r=r,center=center, l=l,length=length,height=height,
                                  r1=r1,r2=r2,ir=ir,ir1=ir1,ir2=ir2,or=or,or1=or1,or2=or2,side=side,side1=side1,side2=side2,
                                  d=d,d1=d1,d2=d2,id=id,id1=id1,id2=id2,od=od,od1=od1,od2=od2,
                                  chamfer=chamfer, chamfer1=chamfer1, chamfer2=chamfer2,
                                  chamfang=chamfang,chamfang1=chamfang1,chamfang2=chamfang2,
                                  rounding=rounding,rounding1=rounding1, rounding2=rounding2,
                                  realign=realign, shift=shift,
                                  teardrop=teardrop, clip_angle=clip_angle,
                                  from_end=from_end, from_end1=from_end1, from_end2=from_end2,
                                  texture=texture, tex_size=tex_size, tex_reps=tex_reps,
                                  tex_inset=tex_inset, tex_rot=tex_rot,
                                  tex_depth=tex_depth, tex_samples=tex_samples,
                                  tex_taper=tex_taper, style=style,
                                  _return_anchors=true);
    attachable(anchor=anchor, orient=orient, spin=spin, vnf=vnf_anchors_ovr[0], anchors=vnf_anchors_ovr[1],override=vnf_anchors_ovr[2]){
       vnf_polyhedron(vnf_anchors_ovr[0],convexity=is_def(texture)?10:2);
       children();
    }   
}                        
                        

function regular_prism(n, 
    h, r, center,
    l, length, height,
    r1,r2,ir,ir1,ir2,or,or1,or2,side,side1,side2, 
    d, d1, d2,id,id1,id2,od,od1,od2,
    chamfer, chamfer1, chamfer2,
    chamfang, chamfang1, chamfang2,
    rounding, rounding1, rounding2,
    circum=false, realign=false, shift=[0,0],
    teardrop=false, clip_angle,
    from_end, from_end1, from_end2,
    texture, tex_size=[5,5], tex_reps,
    tex_inset=false, tex_rot=0,
    tex_depth, tex_samples, length, height, 
    tex_taper, style,
    anchor, spin=0, orient=UP,_return_anchors=false
) = 
    assert(is_integer(n) && n>2, "n must be an integer 3 or greater")
    let(
        style = default(style,"min_edge"),
        tex_depth = default(tex_depth,1),
        height = one_defined([l, h, length, height],"l,h,length,height"),
        sc = 1/cos(180/n),
        ir1 = u_mul(default(ir1,ir), sc),
        ir2 = u_mul(default(ir2,ir), sc),
        id1 = u_mul(default(id1,id), sc),
        id2 = u_mul(default(id2,id), sc),
        od1 = default(od1,od),
        od2 = default(od2,od),
        or1 = default(or1,or),
        or2 = default(or2,or),
        d1 = default(d1,d),
        d2 = default(d2,d),
        side = is_finite(side)? side/2/sin(180/n) : undef,
        side1 = is_finite(side1)? side1/2/sin(180/n) : side,
        side2 = is_finite(side2)? side2/2/sin(180/n) : side,
        r1 = get_radius(r1=ir1,r2=or1,r=default(r1,r),d=d1,d1=id1,d2=od1,dflt=side1),
        r2 = get_radius(r1=ir2,r2=or2,r=default(r2,r),d=d2,d1=id2,d2=od2,dflt=side2),
        anchor = get_anchor(anchor,center,BOT,CENTER)
    )
    assert(num_defined([side,od,id,or,ir])<=1, "Can only define one of side, id, od, ir, and or")
    assert(is_finite(r1), "Must specify finite number for prism bottom radius / diameter / side length")
    assert(is_finite(r2), "Must specify finite number for prism top radius / diameter / side length")
    assert(is_finite(height), "l/h/length/height must be a finite number.")
    assert(is_vector(shift,2), "shift must be a 2D vector.")
    let(
        vnf = any_defined([chamfer, chamfer1, chamfer2, rounding, rounding1, rounding2])
            ? assert(is_undef(texture), "Cannot combine roundings or chamfers with texturing")
              let(
                  path = [
                           [0,-height/2],
                           each _cyl_path(r1, r2, height, 
                                          chamfer, chamfer1, chamfer2,
                                          chamfang, chamfang1, chamfang2,
                                          rounding, rounding1, rounding2,
                                          from_end, from_end1, from_end2,
                                          teardrop, clip_angle,n),
                           [0,height/2]
                         ]
              )
              rotate_sweep(path,caps=true,$fn=n)
            : is_undef(texture) ? cylinder(h=height, r1=r1, r2=r2, center=true, $fn=n)
            : linear_sweep(regular_ngon(n=n,r=r1),scale=r2/r1,height=height,center=true,
                           texture=texture, tex_reps=tex_reps, tex_size=tex_size,
                           tex_inset=tex_inset, tex_rot=tex_rot,
                           tex_depth=tex_depth, tex_samples=tex_samples,
                           style=style),
        skmat = down(height/2) *
            skew(sxz=shift.x/height, syz=shift.y/height) *
            up(height/2) *
            zrot(realign? 180/n : 0),
        ovnf = apply(skmat, vnf),
        edge_face = [ [r2-r1,0,height],[(r2-r1)/sc,0,height]],  // regular edge, then face edge, in xz plane
        names = ["edge","face"],
        anchors = let(
                      faces = [
                               for(i=[0:n-1])
                                  let(
                                      M1 = skmat*zrot(-i*360/n),      // map to point i
                                      M2 = skmat*zrot(-(i+1)*360/n),  // map to point i+1
                                      edge1 = apply(M1,[[r2,0,height/2], [r1,0,-height/2]]),  // "vertical" edge at i
                                      edge2 = apply(M2,[[r2,0,height/2], [r1,0,-height/2]]),  // "vertical" edge at i+1
                                      face_edge = (edge1+edge2)/2,         // "vertical" edge across side face between i and i+1
                                      facenormal = unit(cross(edge1[0]-edge1[1], edge2[1]-edge1[0]))
                                  )   // [normal to face, edge through face center vector, actual edge vector, top edge vector]
                                  [facenormal,face_edge[0]-face_edge[1],edge1[0]-edge1[1],edge2[0]-edge1[0]]  
                              ]
                  )
                  [for(i=[0:n-1])
                      let(
                           Mface = skmat*zrot(-(i+1/2)*360/n),
                           faceedge = faces[i][1],
                           facenormal = faces[i][0], 
                           //facespin = _compute_spin(facenormal, faceedge), // spin along centerline of face instead of pointing up---seems to be wrong choice
                           facespin = _compute_spin(facenormal, UP), 
                           edgenormal = unit(vector_bisect(facenormal,select(faces,i-1)[0])),
                           Medge = skmat*zrot(-i*360/n),
                           edge = faces[i][2], 
                           edgespin = _compute_spin(edgenormal, edge),
                           topedge = unit(faces[i][3]),
                           topnormal = unit(facenormal+UP),
                           botnormal = unit(facenormal+DOWN),
                           topedgespin = _compute_spin(topnormal, topedge),
                           botedgespin = _compute_spin(botnormal, -topedge),
                           topedgeangle = 180-vector_angle(UP,facenormal),
                           sideedgeangle = 180-vector_angle(facenormal, select(faces,i-1)[0]),
                           edgelen = norm(select(faces,i)[2])
                      )
                      each [
                          named_anchor(str("face",i), apply(Mface,[(r1+r2)/2/sc,0,0]), facenormal, facespin),
                          named_anchor(str("edge",i), apply(Medge,[(r1+r2)/2,0,0]), edgenormal, edgespin,
                                       info=[["edge_angle",sideedgeangle], ["edge_length",edgelen]]),
                          named_anchor(str("top_edge",i), apply(Mface,[r2/sc,0,height/2]), topnormal, topedgespin,
                                       info=[["edge_angle",topedgeangle],["edge_length",2*sin(180/n)*r2]]),
                          named_anchor(str("bot_edge",i), apply(Mface,[r1/sc,0,-height/2]), botnormal, botedgespin,
                                       info=[["edge_angle",180-topedgeangle],["edge_length",2*sin(180/n)*r1]]),
                          named_anchor(str("top_corner",i), apply(Medge,[r2,0,height/2]), unit(edgenormal+UP),
                                       _compute_spin(unit(edgenormal+UP),edge)),
                          named_anchor(str("bot_corner",i), apply(Medge,[r1,0,-height/2]), unit(edgenormal+DOWN),
                                       _compute_spin(unit(edgenormal+DOWN),edge))
                          
                      ]
                  ],
        override = approx(shift,[0,0]) ? undef : [[UP, [point3d(shift,height/2), UP]]],
        final_vnf = reorient(anchor,spin,orient, vnf=ovnf,  p=ovnf,anchors=anchors, override=override)
    )
    _return_anchors ? [final_vnf,anchors,override]
                    : final_vnf;


// Function&Module: textured_tile()
// Synopsis: Creates a cube or trapezoidal prism with a textured top face for attaching to objects.
// SynTags: Geom, VNF
// Topics: Shapes (3D), Attachable, VNF Generators, Textures
// See Also: cuboid(), prismoid(), texture(), cyl(), rotate_sweep(), linear_sweep(), plot3d()
// Usage:
//   textured_tile(texture, [size], [w1=], [w2=], [ang=], [shift=], [h=/height=/thickness=], [atype=], [diff=], [tex_extra=], [tex_skip=], ...) [ATTACHMENTS];
//   vnf = textured_tile(texture, [size], [w1=], [w2=], [ang=], [shift=], [h=/height=/thickness=], [atype=], [tex_extra=], [tex_skip=], ...);
// Description:
//   Creates a cuboid or trapezoidal prism and places a texture on the top face.
//   See [Texturing](skin.scad#section-texturing) for more details on how textures work.  
//   You can specify the size of the object by giving a `size` scalar or vector as is
//   usual for a cube.  If you give a scalar, however, it applies only to the X and Y dimensions: the default is to create a thin tile, not a cube.  
//   The Z size specifies the size of the shape **not** including the applied texture (in the same way that other textured objects work).
//   If you omit the Z value then for regular textures, the default thickness will be 0.1 which provides a thin backing layer.  A zero thickness
//   base layer can produce invalid geometry when the texture contacts the bottom layer, so some non-zero base is necessary.  If you use a positive `inset`
//   then the texture actually sinks into its base, so the default is set to the 0.1 more than the inset depth.  To ensure a valid geometry, with a positive
//   `inset` or a texture that has negative values you must select a thickness strictly **larger** than the depth the texture extends below zero.
//   .
//   Textures are meant to be between 0 and 1 so that `tex_depth` and `tex_inset` behave as expected.  If you have a custom textures that
//   has a different range you can still use it directly, but you may find it more convenient to rescale a height map texture using {{fit_to_range()}]
//   or a VNF texture using {{fit_to_box()}}.  
//   .
//   You can also specify a trapzoidal prism using parameters equivalent to those accepted by {{trapezoid()}}, with one change:  
//   `ysize` specifies the width of the prism in the Y direction, and `h`, `height` or `thickness` are used to specify the height
//   in the Z direction.  When you texture a trapezoid the texture will be scaled to the `w1` length if you specify it by size using `tex_size`.  The
//   scaling transformation that maps the texture onto the trapezoid is not linear and will result in curvature of your texture.
//   .
//   Two anchor types are available.  The default atype is "tex" which assumes you want to place the texture on another object using
//   {{attach()}}.  It provides anchors that ignore the base object and place the BOTTOM anchor at the bottom of the texture.  The TOP anchor
//   will be at the top face of the texture.  Note that if your texture doesn't span the range from [0,1] these anchors won't be correctly located. 
//   For an inset texture, the "tex" anchors are all at the top of the texture.  This anchor type works with `attach(face,BOT)` where `face` is some
//   face on a parent object that needs a texture. If you want to use the textured object directly the "std" anchors are probably more useful.
//   These anchors are the usual anchors for the base object, ignoring the applied texture.  If you want the anchors to be on top of the texture,
//   set `tex_inset=true`.
//   .
//   To aid in the application of inset anchors into parent objects with the module form, you can set `diff=true`, which causes the module
//   to create a "remove" tagged cuboid or prism to carve out space for the texture so that inset textures are cut into the parent object.
//   The texture itself is given a "keep" tag.  For this to work you must specify {{diff()}} above the parent; if you don't do that, the
//   tags will be ignored and the tile will appear as a solid object with no texture visible.  The cutout object extends 0.1 units above the surface
//   of the texture to prevent problems with exactly aligned faces.  The cutout does not extend out beyond the sides, so if the parent shape
//   has the exact same dimensions as the texture tile, you will have exactly aligned faces along the edges.
//   .
//   Most of the heightfield textures are designed to repeat in a way that requires one extra line of the texture to complete the pattern.
//   The `tex_extra` parameter specifies the number of extra lines to repeat at the end of the texture and it defaults to 1 because most textures
//   do requires this extra line.  There is one exception: if you specify only a single tile, then you are probably using an image for your texture and do not want a repeated line, so in
//   this case, `tex_extra` defaults to zero.  If you need to adjust the number of extra lines you can set the `tex_extra` parameter to 0, or you can set it to a list of two
//   integers to control the extra line of texture in the X and Y directions independently.  The `tex_extra` parameter
//   is ignored for VNF textures.  A heightfield texture may also have extra margin along a starting side that makes the texture unbalanced.  You can 
//   removed this using the `tex_skip` parameter, which defaults to zero and similarly specifies the number of lines to skip in the X and Y directions at
//   the starting edges of the tile.  You must have enough tile repetitions to accomodate the specified skip.
// Anchor Types:
//   "tex" = Anchors around the texture, ignoring the base object.  (default)
//   "std" = Standard object anchors that ignore any applied texture.  
// Arguments:
//   texture = A texture name string, or a rectangular array of scalar height values (0.0 to 1.0), or a VNF tile that defines the texture to apply to vertical surfaces.  See {{texture()}} for what named textures are supported.
//   size = The size the object when a cube is desired, a scalar, 2-vector or 3-vector.  If you give a scalar or 2-vector the default height is 0.1 or 0.1 more than the inset depth
//   ---
//   ysize = The Y axis length of the trapezoidal prism
//   w1 = The X axis width of the front end of the trapezoidal prism.
//   w2 = The X axis width of the back end of the trapezoidal prism
//   ang = Specify the front angle(s) of the trapezoidal prism.  Can give a scalar for an isosceles trapezoidal prism or a list of two angles, the left angle and right angle.  You must omit one of `h`, `w1`, or `w2` to allow the freedom to control the angles. 
//   shift = Scalar value to shift the back of the trapezoidal prism along the X axis by.  Cannot be combined with ang.  Default: 0
//   h / height / thickness = The thickness in the Z direction of the base that the texture sits on.  Default: 0.1 or for inset textures 0.1 more than the inset depth
//   tex_size = An optional 2D target size (2-vector or scalar) for the textures.  Actual texture sizes will be scaled somewhat to evenly fit the available surface. Default: `[5,5]`
//   tex_reps = If given instead of tex_size, a scalar or 2-vector giving the integer number of texture tile repetitions in the horizontal and vertical directions.
//   tex_inset = If numeric, lowers the texture into the surface by the specified proportion, e.g. 0.5 would lower it half way into the surface.  If `true`, insets by exactly its full depth.  Default: `false`
//   tex_rot = Rotate texture by specified angle, which must be a multiple of 90 degrees.  Default: 0
//   tex_depth = Specify texture depth; if negative, invert the texture.  Default: 1.
//   diff = if set to true then "remove" and "keep" tags are set to cut out a space for the texture so that inset textures can be attached.  Default: false
//   tex_extra = number of extra lines of a hightfield texture to add at the end.  Can be a scalar or 2-vector to give x and y values.  Default: 0 if `tex_reps=[1,1]`, 1 otherwise
//   tex_skip = number of lines of a heightfield texture to skip when starting.  Can be a scalar or two vector to give x and y values.  Default: 0
//   style = {{vnf_vertex_array()}} style used to triangulate heightfield textures.  Default: "min_edge"
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `BOTTOM` if `astyle` is "tex", `CENTER` otherwise
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Example(3D,NoScales,VPT=[-0.257402,0.467403,-0.648606],VPR=[46.6,0,16.6],VPD=29.2405): Basic textured tile
//   textured_tile("trunc_diamonds", 10, tex_reps=[5,5]);
// Example(3D,NoAxes,VPT=[-0.0852782,0.259593,0.139667],VPR=[58.5,0,345.1],VPD=36.0994): Attaching a tile to a cube
//   cuboid([12,12,4]) attach(TOP,BOT)
//     textured_tile("trunc_pyramids", 10, tex_reps=[5,5],
//                   style="convex");
// Example(3D,NoScales,VPT = [-0.0788193, 0.10015, -0.0938629], VPR = [57.8, 0, 34.1], VPD = 29.2405): This inset texture doesn't look obviously different, but you can see that the object is below the XY plane.
//     textured_tile("trunc_pyramids_vnf", 10, tex_reps=[5,5],
//                   tex_inset=true);
// Example(3D,NoAxes,VPT=[0.242444,0.170054,-0.0714754],VPR=[67.6,0,33.4],VPD=36.0994): Here we use the `diff` option combined with {{diff()}} to attach the inset texture to the front of a parent cuboid.  
//   diff()
//     cuboid([12,5,10]) attach(FRONT, BOT)
//       textured_tile("trunc_pyramids_vnf", [10,8],
//                     tex_reps=[5,5], tex_inset=true, diff=true);
// Example(3D,NoAxes,VPT=[5.86588,-0.107082,-0.311155],VPR=[17.2,0,9.6],VPD=32.4895): Tile shaped like a rhombic prism
//   textured_tile("ribs", w1=10, w2=10, shift=4, ysize=7,
//                 tex_reps=[5,1]);
// Example(3D,NoAxes,VPT=[-0.487417,-0.398897,-0.143258],VPR=[10.2,0,12.4],VPD=26.3165): A tile shaped like a trapezoidal prism.  Note that trapezoidal tiles will always distort the texture, resulting in curves
//   textured_tile("diamonds", w1=10, w2=7, ysize=7, tex_reps=5);
// Example(3D,NoAxes,VPT=[-0.0889877,-0.31974,0.554444],VPR=[22.1,0,22.2],VPD=32.4895): An inset trapezoidal tile placed into a cube
//   diff()cuboid([10,10,2])
//     attach(TOP,BOT)
//       textured_tile("trunc_diamonds", tex_reps=[5,5],
//                     tex_inset=true, diff=true,
//                     w1=8, w2=4, ysize=8);
// Example(3D,NoAxes,VPT=[-0.0889877,-0.31974,0.554444],VPR=[58.5,0,21.5],VPD=32.4895): This example shows what happens if you set `tex_extra` to zero for the "pyramids" texture.  Note that the texture doesn't finish.  The default of `tex_extra=1` produces the correct result.  
//     textured_tile("pyramids", 10, tex_reps=[5,5], tex_extra=0);
// Example(3D,NoAxes,VPT=[-0.212176,-0.651766,0.124004],VPR=[58.5,0,21.5],VPD=29.2405): This texture has an asymmetry with the default `tex_extra=1`. 
//     textured_tile("trunc_ribs", 10, tex_reps=[5,1]);
// Example(3D,NoAxes,VPT=[-0.212176,-0.651766,0.124004],VPR=[58.5,0,21.5],VPD=29.2405): It could be fixed by setting `tex_extra=2`, which would place an extra flat strip on the right.  But another option is to use the `tex_skip` parameter to trim the flat part from the left.  Note that we are also skipping in the y direction, but it doesn't make a difference for this texture, except that you need to have enough texture tiles to accommodate the skip, so we increased the Y reps value to 2.  You can also set `tex_skip` to a vector.
//     textured_tile("trunc_ribs", 10, tex_reps=[5,2], tex_skip=1);
// Example(3D,NoAxes): Textures can be used to place images onto objects.  Here we place a very simple image into a cube, leaving a border around the image.  
//     textured_tile("trunc_ribs", 10, tex_reps=[5,2], tex_skip=1);
//      img = [
//         [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
//         [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0],
//         [0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0],
//         [0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0],
//         [0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0],
//         [0, 1, 0, 0, 0,.5,.5, 0, 0, 0, 1, 0],
//         [0, 1, 0, 0, 0,.5,.5, 0, 0, 0, 1, 0],
//         [0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0],
//         [0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0],
//         [0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0],
//         [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0],
//         [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
//      ];
//      cuboid(25) attach([TOP,FWD,RIGHT],BOT)
//        textured_tile(img, [20,20], tex_reps=1);  

module textured_tile(
    texture,
    size,
    ysize, height, w1, w2, ang, h, shift,
    tex_size,
    tex_reps,       
    tex_inset=false,
    tex_rot=0,      
    tex_depth=1,
    diff=false,
    tex_extra,
    tex_skip=0,
    style="min_edge",
    atype="tex",
    anchor, spin=0, orient=UP
)
{
    anchor = default(anchor, atype=="tex" ? BOTTOM : CENTER);
    vnf_data = textured_tile(size=size,
                        ysize=ysize, height=height, w1=w1, w2=w2, ang=ang, h=h, shift=shift, 
                        texture=texture, tex_size=tex_size, tex_reps=tex_reps,tex_extra=tex_extra, 
                        tex_inset=tex_inset, tex_rot=tex_rot, tex_depth=tex_depth,tex_skip=tex_skip,
                        style=style, atype="std",_return_anchor=true);
    h_w1_w2_shift = vnf_data[2];
    is_trap = is_def(h_w1_w2_shift);
    ysize=h_w1_w2_shift[0];
    w1=h_w1_w2_shift[1];
    w2=h_w1_w2_shift[2];
    shift=h_w1_w2_shift[3];
    size = vnf_data[1];
    inset = is_num(tex_inset)? tex_inset : tex_inset? 1 : 0;
    extra_ht = max(0,abs(tex_depth)*(1-inset));
    anch_ht = atype=="tex" ? extra_ht : size.z;
    geom = is_def(h_w1_w2_shift) ? atype=="std" ? attach_geom(axis=BACK, size=[w1,anch_ht,ysize],size2=[w2,anch_ht],shift=[-shift,0])
                                                : attach_geom(axis=BACK, size=[w1,anch_ht,ysize],size2=[w2,anch_ht],shift=[-shift,0])
                                 : attach_geom(size=[size.x,size.y,anch_ht]);
    attachable(anchor=anchor,orient=orient, spin=spin, geom=geom, expose_tags=true){
      down(atype=="tex" ? size.z/2+extra_ht/2 : 0)
        if (diff) {
          tag("keep") vnf_polyhedron(vnf_data[0]);
          tag("remove")up(.05)
              if (!is_trap) cuboid([size.x,size.y,size.z+0.1]);
              else linear_sweep(trapezoid(w1=w1,w2=w2,h=ysize,shift=shift), h=size.z+0.1,center=true);
        }
        else vnf_polyhedron(vnf_data[0]);

      children();
    }
}



function textured_tile(
    texture, 
    size,
    ysize, height, w1, w2, ang, h, shift, thickness,
    tex_size,
    tex_reps,       
    tex_inset=false,
    tex_rot=0,      
    tex_depth=1,    
    style="min_edge",
    atype="tex",
    tex_extra,
    tex_skip=0,
    anchor, spin=0, orient=UP,
    _return_anchor=false
) =
    assert(in_list(atype,["tex","std"]), "atype must be \"tex\" or \"std\"")
    assert(is_undef(tex_reps) || is_int(tex_reps) || (all_integer(tex_reps) && len(tex_reps)==2), "tex_reps must be an integer or list of two integers")
    assert(is_undef(tex_size) || is_vector(tex_size,2) || is_finite(tex_size))
    assert(num_defined([tex_size, tex_reps])==1, "Must give exactly one of tex_size and tex_reps")
    assert(is_undef(size) || is_num(size) || is_vector(size,2) || is_vector(size,3), "size must be a 2-vector or 3-vector")
    assert(is_undef(size) || num_defined([ysize,h, height, thickness, w1,w2,ang])==0, "Cannot combine size with any other dimensional specifications")
    let(
        anchor = default(anchor, atype=="tex" ? BOTTOM : CENTER), 
        inset = is_num(tex_inset)? tex_inset : tex_inset? 1 : 0,
        default_thick = inset>0 ? 0.1+abs(tex_depth)*inset : 0.1,
        extra_ht = max(0,abs(tex_depth)*(1-inset)),
        h_w1_w2_shift = is_def(size) ? undef
                      : assert(is_undef(ysize) || is_finite(ysize))
                        assert(is_undef(w1) || is_finite(w1))
                        assert(is_undef(w2) || is_finite(w2))
                        assert(is_undef(ang) || is_finite(ang) || is_vector(ang,2))
                        assert(num_defined([ysize, w1, w2, ang]) == 3, "Must give exactly 3 of the arguments ysize, w1, w2, and angle.")
                        assert(is_undef(shift) || is_finite(shift))
                        assert(num_defined([shift,ang])<2, "Cannot specify shift and ang together")
                        _trapezoid_dims(ysize,w1,w2,shift,ang),
        ysize=h_w1_w2_shift[0],
        w1=h_w1_w2_shift[1],
        w2=h_w1_w2_shift[2],
        shift=h_w1_w2_shift[3],
        height = is_def(size) ? default(size.z,default_thick) : one_defined([h,height,thickness],"h,height,thickness",dflt=default_thick),
        size = is_def(size) ? is_num(size) ? [size,size,1] : point3d(size,1)        // We only use the x and y components of size
             : [w1,ysize],

        texture = _get_texture(texture, tex_rot),
        
        tex_reps = is_def(tex_reps) ? force_list(tex_reps,2)
                 : let(tex_size=force_list(tex_size,2))
                   [round(size.x/tex_size.x), round(size.y/tex_size.y)],
        extra = is_undef(tex_extra)? tex_reps == [1,1] ? [0,0] : [1,1]
                                   : force_list(tex_extra,2), 
        skip = force_list(tex_skip,2), 
        scale = [size.x/tex_reps.x, size.y/tex_reps.y],
        setz=function (v,z)  [v.x,v.y,z], 
        vnf = !is_vnf(texture) ?
                    let(         
                        texsteps = [len(texture[0]), len(texture)], 
                        xn=tex_reps.x*texsteps.x+extra.x-skip.x,
                        yn=tex_reps.y*texsteps.y+extra.y-skip.y,
                        checks = assert(yn>=2, "Skipped too many points in the y direction: decrease skip.y")
                                 assert(xn>=2, "Skipped too many points in the x direction: decrease skip.x"),
                        xpts=lerpn(-size.x/2,size.x/2,xn),
                        ypts=lerpn(size.y/2,-size.y/2,yn),
                        scaled_tex = tex_depth < 0 ? [for(row=texture) [for(p=row) -(1-p-inset)*tex_depth]]
                                                   : [for(row=texture) [for(p=row)  (p-inset)*tex_depth]],
                        check = [for(row=scaled_tex, p=row) if (p<=-height) p],
                        dummy=assert(check==[], str("texture extends too far below zero (",min([each check,0]),") to fit entirely within height ",height)),
                        pts=[for(y=idx(ypts))
                               [ [xpts[0],ypts[y],-height/2],
                                 for(x=idx(xpts))
                                   [xpts[x],ypts[y], height/2 + scaled_tex[(y+skip.y)%texsteps.y][(x+skip.x)%texsteps.x]],
                                 [last(xpts), ypts[y], -height/2]
                               ]
                             ]
                    )
                    vnf_vertex_array(pts,col_wrap=true,caps=true,style=style)
            :
                let(
                    zadj_vnf = [
                                  [for(p=texture[0]) [p.x, p.y, height/2 + _tex_height(tex_depth,inset,p.z)]],
                                  texture[1]
                               ],
                    minz = min(column(zadj_vnf[0],2)),
                    dummy=assert(minz>-height/2, str("texture extends too far below zero (",minz-height/2,") to fit entirely within height ",height)),
                    
                    scaled_vnf = scale(scale, zadj_vnf), 
                    tiled_vnf = [for(i=[0:1:tex_reps.x-1], j=[0:1:tex_reps.y-1]) move([scale.x*i,scale.y*j], scaled_vnf)],

                    yedge_list = _tile_edge_path_list(zadj_vnf, 0),
                    xedge_list = _tile_edge_path_list(zadj_vnf, 1),

                    front_back_closed = [for(i=[0:1:tex_reps.x-1], cpath=xedge_list[1])
                                                                  each [[xscale(scale.x,xmove(i,cpath)), [count(cpath)]],
                                                                        [xscale(scale.x,move([i,size.y],cpath)),[count(cpath,reverse=true)]]]],
                    sides_closed = [for(j=[0:1:tex_reps.y-1], cpath=yedge_list[1])
                                                                  each [[yscale(scale.y,ymove(j,cpath)), [count(cpath)]],
                                                                        [yscale(scale.y,move([size.x, j], cpath)),[count(cpath,reverse=true)]]]],

                    leftpath = yedge_list[0]==[] ? []
                              : deduplicate([for(j=[0:1:tex_reps.y-1]) each reverse(yscale(scale.y,ymove(j,yedge_list[0][0])))]), 
                    frontpath = xedge_list[0]==[] ? []
                              : deduplicate([for(i=[0:1:tex_reps.x-1]) each xscale(scale.x,xmove(i,xedge_list[0][0]))]),

                    base = frontpath==[] || leftpath==[] ? [] 
                         : [
                            [
                             [setz(frontpath[0],-height/2),
                              each frontpath,
                              setz(last(frontpath), -height/2)
                             ],
                             [count(len(frontpath)+2)]
                           ],
                            [
                             [setz(last(leftpath),-height/2),
                              each reverse(leftpath),
                              setz(leftpath[0], -height/2)
                             ],
                             [count(len(leftpath)+2)]
                           ],
                            [
                             back(size.y,
                             [setz(last(frontpath),-height/2),
                              each reverse(frontpath),
                              setz(frontpath[0],-height/2)
                             ]),
                             [count(len(frontpath)+2)]
                           ],
                            [right(size.x,
                             [setz(leftpath[0],-height/2),
                              each leftpath,
                              setz(last(leftpath),-height/2)
                             ]),
                             [count(len(leftpath)+2)]
                           ]
                            ],

                    bottom = [path3d(rect(point2d(size),anchor=FWD+LEFT),-height/2), [[3,2,1,0]]],
                    result = vnf_join(concat(tiled_vnf,front_back_closed, sides_closed,base,[bottom])) 
                )
                move([-size.x/2,-size.y/2],result),
        trans_vnf = is_undef(h_w1_w2_shift) ? vnf
                  : let(
                        newpts = [for(p=vnf[0])
                                    let(factor=p.y/ysize+1/2)
                                    [lerp(1,w2/w1,factor)*p.x+factor*shift, p.y, p.z]]
                    )
                    [newpts, vnf[1]],
        anch_ht = atype=="tex" ? extra_ht : height,
        shifted_vnf = down(atype=="tex" ? height/2+extra_ht/2 : 0, trans_vnf),
        geom = is_def(h_w1_w2_shift) ? atype=="std" ? attach_geom(axis=BACK, size=[w1,anch_ht,ysize],size2=[w2,anch_ht],shift=[-shift,0])
                                                    : attach_geom(axis=BACK, size=[w1,anch_ht,ysize],size2=[w2,anch_ht],shift=[-shift,0])
                                     : attach_geom(size=[size.x,size.y,anch_ht])
    )
    _return_anchor ? [reorient(anchor,spin,orient,geom=geom,p=shifted_vnf), [size.x,size.y,height],h_w1_w2_shift]
                   : reorient(anchor,spin,orient,geom=geom,p=shifted_vnf);



// Module: rect_tube()
// Synopsis: Creates a rectangular tube.
// SynTags: Geom
// Topics: Shapes (3D), Attachable, VNF Generators
// See Also: tube()
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
//   .
//   By default if you specify a chamfer or rounding then it applies as specified to the
//   outside, and an inside rounding is calculated that will maintain constant width
//   if your wall thickness is uniform.  If the wall thickness is not uniform, the default
//   inside rounding is calculated based on the smaller of the two wall thicknesses.
//   Note that the values of the more specific chamfers and roundings inherit from the
//   more general ones, so `rounding2` is determined from `rounding`.  The constant
//   width default will apply when the inner rounding and chamfer are both undef.
//   You can give an inner chamfer or rounding as a list with undef entries if you want to specify
//   some corner roundings and allow others to be computed.
//   .
//   Attachment to the rectangular tube will place objects on the **outside** of the tube.
//   If you need to anchor to the inside of a tube, use {{attach_part()}} with the part name "inside"
//   to switch goeomtry to the inside.  
// Arguments:
//   h/l/height/length = The height or length of the rectangular tube.  Default: 1
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
//   irounding = The roundover radius for the inside edges of the rectangular tube. Default: Computed for uniform wall thickness (see above)
//   irounding1 = The roundover radius for the inside bottom corner of the rectangular tube.
//   irounding2 = The roundover radius for the inside top corner of the rectangular tube.
//   ichamfer = The chamfer size for the inside edges of the rectangular tube.  Default: Computed for uniform wall thickness (see above)
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
// Example: With rounding
//   rect_tube(size=100, wall=5, rounding=10, h=30);
// Example: With rounding
//   rect_tube(size=100, wall=5, chamfer=10, h=30);
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
//       chamfer=[0,10,0,20], 
//       rounding=[10,0,20,0]
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
// Example: Some interiors chamfered, others with default rounding
//   rect_tube(
//       size=100, wall=10, h=30,
//       rounding=[0,10,20,30], ichamfer=[8,8,undef,undef]
//   );
// Example: An example from above with a cube attached to the inside using {{attach_part()}}.  
//   rect_tube(
//          size=100, wall=10, h=30,
//          chamfer=[0,10,0,20], 
//          rounding=[10,0,20,0]
//      )
//      attach_part("inside")
//      attach(BACK,BOT) cuboid(20);


function _rect_tube_rounding(factor,ir,r,alternative,size,isize) =
    let(wall = min(size-isize)/2*factor)
    [for(i=[0:3])
      is_def(ir[i]) ? ir[i]
    : is_undef(alternative[i]) ? max(0,r[i]-wall)
    : 0
    ];
    
module rect_tube(
    h, size, isize, center, shift=[0,0],
    wall, size1, size2, isize1, isize2,
    rounding=0, rounding1, rounding2,
    irounding=undef, irounding1=undef, irounding2=undef,
    chamfer=0, chamfer1, chamfer2,
    ichamfer=undef, ichamfer1=undef, ichamfer2=undef,
    anchor, spin=0, orient=UP,
    l, length, height
) {
    h = one_defined([h,l,length,height],"h,l,length,height");
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
        assert(isize2.y < size2.y, "Inner size is larger than outer size.")
        assert(is_num(rounding) || is_vector(rounding,4), "rounding must be a number or 4-vector")
        assert(is_undef(rounding1) || is_num(rounding1) || is_vector(rounding1,4), "rounding1 must be a number or 4-vector")
        assert(is_undef(rounding2) || is_num(rounding2) || is_vector(rounding2,4), "rounding2 must be a number or 4-vector")
        assert(is_num(chamfer) || is_vector(chamfer,4), "chamfer must be a number or 4-vector")
        assert(is_undef(chamfer1) || is_num(chamfer1) || is_vector(chamfer1,4), "chamfer1 must be a number or 4-vector")
        assert(is_undef(chamfer2) || is_num(chamfer2) || is_vector(chamfer2,4), "chamfer2 must be a number or 4-vector")
        assert(is_undef(irounding) || is_num(irounding) || (is_list(irounding) && len(irounding)==4), "irounding must be a number or 4-vector")
        assert(is_undef(irounding1) || is_num(irounding1) || (is_list(irounding1) && len(irounding1)==4), "irounding1 must be a number or 4-vector")
        assert(is_undef(irounding2) || is_num(irounding2) || (is_list(irounding2) && len(irounding2)==4), "irounding2 must be a number or 4-vector")      
        assert(is_undef(ichamfer) || is_num(ichamfer) || (is_list(ichamfer) && len(ichamfer)==4), "ichamfer must be a number or 4-vector")
        assert(is_undef(ichamfer1) || is_num(ichamfer1) || (is_list(ichamfer1) && len(ichamfer1)==4), "ichamfer1 must be a number or 4-vector")
        assert(is_undef(ichamfer2) || is_num(ichamfer2) || (is_list(ichamfer2) && len(ichamfer2)==4), "ichamfer2 must be a number or 4-vector");
    chamfer1=force_list(default(chamfer1,chamfer),4);
    chamfer2=force_list(default(chamfer2,chamfer),4);
    rounding1=force_list(default(rounding1,rounding),4);
    rounding2=force_list(default(rounding2,rounding),4);
    checks3 =
        assert(all_nonnegative(chamfer1), "chamfer/chamfer1 must be non-negative")
        assert(all_nonnegative(chamfer2), "chamfer/chamfer2 must be non-negative")
        assert(all_nonnegative(rounding1), "rounding/rounding1 must be non-negative")
        assert(all_nonnegative(rounding2), "rounding/rounding2 must be non-negative")        
        assert(all_zero(v_mul(rounding1,chamfer1),0), "rounding1 and chamfer1 (possibly inherited from rounding and chamfer) cannot both be nonzero at the same corner")
        assert(all_zero(v_mul(rounding2,chamfer2),0), "rounding2 and chamfer2 (possibly inherited from rounding and chamfer) cannot both be nonzero at the same corner");
    irounding1_temp = force_list(default(irounding1,irounding),4);
    irounding2_temp = force_list(default(irounding2,irounding),4);    
    ichamfer1_temp = force_list(default(ichamfer1,ichamfer),4);
    ichamfer2_temp = force_list(default(ichamfer2,ichamfer),4);
    checksignr1 = [for(entry=irounding1_temp) if (is_def(entry) && entry<0) 1]==[];
    checksignr2 = [for(entry=irounding2_temp) if (is_def(entry) && entry<0) 1]==[];    
    checksignc1 = [for(entry=ichamfer1_temp) if (is_def(entry) && entry<0) 1]==[];
    checksignc2 = [for(entry=ichamfer2_temp) if (is_def(entry) && entry<0) 1]==[];
    checkconflict1 = [for(i=[0:3]) if (is_def(irounding1_temp[i]) && is_def(ichamfer1_temp[i]) && irounding1_temp[i]!=0 && ichamfer1_temp[i]!=0) 1]==[];
    checkconflict2 = [for(i=[0:3]) if (is_def(irounding2_temp[i]) && is_def(ichamfer2_temp[i]) && irounding2_temp[i]!=0 && ichamfer2_temp[i]!=0) 1]==[];
    checks4 =
        assert(checksignr1, "irounding/irounding1 must be non-negative")
        assert(checksignr2, "irounding/irounding2 must be non-negative")
        assert(checksignc1, "ichamfer/ichamfer1 must be non-negative")
        assert(checksignc2, "ichamfer/ichamfer2 must be non-negative")
        assert(checkconflict1, "irounding1 and ichamfer1 (possibly inherited from irounding and ichamfer) cannot both be nonzero at the same corner")
        assert(checkconflict2, "irounding2 and ichamfer2 (possibly inherited from irounding and ichamfer) cannot both be nonzero at the same corner");
    irounding1 = _rect_tube_rounding(1,irounding1_temp, rounding1, ichamfer1_temp, size1, isize1);
    irounding2 = _rect_tube_rounding(1,irounding2_temp, rounding2, ichamfer2_temp, size2, isize2);
    ichamfer1 = _rect_tube_rounding(1/sqrt(2),ichamfer1_temp, chamfer1, irounding1_temp, size1, isize1);
    ichamfer2 = _rect_tube_rounding(1/sqrt(2),ichamfer2_temp, chamfer2, irounding2_temp, size2, isize2);
    anchor = get_anchor(anchor, center, BOT, BOT);
    parts = [
              define_part("inside", attach_geom(size=[each isize1, h], size2=isize2, shift=shift), inside=true)
            ];
    attachable(anchor,spin,orient, size=[each size1, h], size2=size2, shift=shift, parts=parts) {
        down(h/2) {
            difference() {
                prismoid(
                    size1, size2, h=h, shift=shift,
                    rounding1=rounding1, rounding2=rounding2,
                    chamfer1=chamfer1, chamfer2=chamfer2,
                    anchor=BOT
                );
                down(0.01) prismoid(
                    isize1, isize2, h=h+0.02, shift=shift,
                    rounding1=irounding1, rounding2=irounding2,
                    chamfer1=ichamfer1, chamfer2=ichamfer2,
                    anchor=BOT
                );
            }
        }
        children();
    }
}

function rect_tube(
    h, size, isize, center, shift=[0,0],
    wall, size1, size2, isize1, isize2,
    rounding=0, rounding1, rounding2,
    irounding, irounding1, irounding2,
    chamfer=0, chamfer1, chamfer2,
    ichamfer, ichamfer1, ichamfer2,
    anchor, spin=0, orient=UP,
    l, length, height
) = no_function("rect_tube");


// Function&Module: wedge()
// Synopsis: Creates a 3d triangular wedge.
// SynTags: Geom, VNF
// Topics: Shapes (3D), Attachable, VNF Generators
// See also: prismoid(), rounded_prism(), pie_slice()
// Usage: As Module
//   wedge(size, [center], ...) [ATTACHMENTS];
// Usage: As Function
//   vnf = wedge(size, [center], ...);
//
// Description:
//   When called as a module, creates a 3D triangular wedge with the hypotenuse in the X+Z+ quadrant.
//   When called as a function, creates a VNF for a 3D triangular wedge with the hypotenuse in the X+Z+ quadrant.
//   The anchors for the wedge are the anchors of the wedge's bounding box.  The named enchors listed below
//   give the sloped face and edges, and those edge anchors have spin oriented with positive Z value in the
//   direction of the sloped edge.  
//
// Arguments:
//   size = [width, thickness, height].  Default: [1,1,1]
//   center = If given, overrides `anchor`.  A true value sets `anchor=CENTER`, false sets `anchor=UP`.
//   ---
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `FRONT+LEFT+BOTTOM`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//
// Named Anchors:
//   "hypot" = Center of angled wedge face, perpendicular to that face.
//   "hypot_left" = Left side of angled wedge face, bisecting the angle between the left side and angled faces.
//   "hypot_right" = Right side of angled wedge face, bisecting the angle between the right side and angled faces.
//   "top_edge" = Top edge anchor which, unlike the UP anchor, points in direction that bisects the edge, and provides `$edge_length` and `$edge_angle`.
//   "bot_edge" = The bottom tip edge with an anchor direction that properly bisects the edge and the `$edge_length` and `$edge_angle` parameters set. 
// Example: Centered
//   wedge([20, 40, 15], center=true);
// Example: *Non*-Centered
//   wedge([20, 40, 15]);
// Example(3D,Med,VPR=[59.50,0.00,36.90],VPD=257.38,VPT=[5.60,-1.98,3.65]): Standard Anchors
//   wedge([40, 80, 30], center=true)
//       show_anchors(custom=false);
//   color([0.5,0.5,0.5,0.1])
//       cube([40, 80, 30], center=true);
// Example(3D,Med,VPR=[55.00,0.00,25.00],VPD=151.98,VPT=[2.30,-11.81,-5.66]): Named Anchors
//   wedge([40, 80, 30], center=true)
//       show_anchors(std=false);
// Example(3D): Rounding the top of the wedge using the "top_edge" anchor
//   diff()
//     wedge([10,15,7])
//       attach("top_edge", FWD+LEFT, inside=true)
//       rounding_edge_mask(r=2, l=$edge_length+1);

module wedge(size=[1, 1, 1], center, anchor, spin=0, orient=UP)
{
    size = force_list(size,3);
    check=assert(is_vector(size,3) && all_positive(size), "\nsize must be a positive scalar or 3-vector");
    anchor = get_anchor(anchor, center, -[1,1,1], -[1,1,1]);
    vnf = wedge(size, anchor="origin");
    spindir = unit([0,-size.y,size.z]);
    hypot_dir = unit([0,size.z,size.y],UP);
    left_dir = unit(hypot_dir+LEFT);
    right_dir = unit(hypot_dir+RIGHT);
    hedge_spin=vector_angle(spindir,rot(from=UP,to=left_dir, p=BACK));
    topedge_dir = [0, each unit(unit([size.z,size.y])+[-1,0])];
    botedge_dir = [0, each unit(unit([size.z,size.y])+[0,-1])];    
    anchors = [
        named_anchor("hypot", CTR, hypot_dir, 180),
        named_anchor("hypot_left", [-size.x/2,0,0], left_dir,-hedge_spin),
        named_anchor("hypot_right", [size.x/2,0,0], right_dir,hedge_spin),
        named_anchor("top_edge", [0,-size.y/2,size.z/2], topedge_dir, _compute_spin(topedge_dir,RIGHT),
                     info=[["edge_angle",atan2(size.y,size.z)],["edge_length",size.x]]),
        named_anchor("bot_edge", [0,size.y/2, -size.z/2], botedge_dir, _compute_spin(botedge_dir,RIGHT),
                     info=[["edge_angle",atan2(size.z,size.y)],["edge_length",size.x]]), 
                     
    ];
    attachable(anchor,spin,orient, size=size, anchors=anchors) {
        if (size.z > 0) {
            vnf_polyhedron(vnf);
        }
        children();
    }
}


function wedge(size=[1,1,1], center, anchor, spin=0, orient=UP) =
    let(
        size = force_list(size,3),
        check=assert(is_vector(size,3) && all_positive(size), "\nsize must be a positive scalar or 3-vector"),
        anchor = get_anchor(anchor, center, -[1,1,1], -[1,1,1]),
        pts = [
            [ 1,1,-1], [ 1,-1,-1], [ 1,-1,1],
            [-1,1,-1], [-1,-1,-1], [-1,-1,1],
        ],
        faces = [
            [0,1,2], [3,5,4], [0,3,1], [1,3,4],
            [1,4,2], [2,4,5], [2,5,3], [0,2,3],
        ],
        vnf = [scale(size/2,p=pts), faces],
        spindir = unit([0,-size.y,size.z]),
        hypot_dir = unit([0,size.z,size.y],UP),
        left_dir = unit(hypot_dir+LEFT),
        right_dir = unit(hypot_dir+RIGHT),
        hedge_spin=vector_angle(spindir,rot(from=UP,to=left_dir, p=BACK)),
        topedge_dir = [0, each unit(unit([size.z,size.y])+[-1,0])],
        anchors = [
            named_anchor("hypot", CTR, hypot_dir, 180),
            named_anchor("hypot_left", [-size.x/2,0,0], left_dir,-hedge_spin),
            named_anchor("hypot_right", [size.x/2,0,0], right_dir,hedge_spin),
            named_anchor("top_edge", [0,-size.y/2,size.z/2], topedge_dir, _compute_spin(topedge_dir,RIGHT),
                         info=[["edge_angle",atan2(size.y,size.z)],["edge_length",size.x]])
        ]
    )
    reorient(anchor,spin,orient, size=size, anchors=anchors, p=vnf);


// Function&Module: octahedron()
// Synopsis: Creates an octahedron with axis-aligned points.
// SynTags: Geom, VNF
// Topics: Shapes (3D), Attachable, VNF Generators
// See Also: prismoid()
// Usage: As Module
//   octahedron(size, ...) [ATTACHMENTS];
// Usage: As Function
//   vnf = octahedron(size, ...);
// Description:
//   When called as a module, creates an octahedron with axis-aligned points.
//   When called as a function, creates a [VNF](vnf.scad) of an octahedron with axis-aligned points.
// Arguments:
//   size = Width of the octahedron, tip to tip.  Can be a 3-vector.  Default: [1,1,1]
//   ---
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Example:
//   octahedron(size=40);
// Example: Anchors
//   octahedron(size=40) show_anchors();
// Example:
//   octahedron([10,15,25]);

module octahedron(size=1, anchor=CENTER, spin=0, orient=UP) {
    vnf = octahedron(size=size);
    attachable(anchor,spin,orient, vnf=vnf, extent=true) {
        vnf_polyhedron(vnf, convexity=2);
        children();
    }
}


function octahedron(size=1, anchor=CENTER, spin=0, orient=UP) =
    let(
        s = force_list(size,3)/2,
        dummy=assert(is_vector(s,3) && all_positive(s), "\nsize must be a positive scalar or 3-vector"),
        vnf = [
            [ [0,0,s.z], [s.x,0,0], [0,s.y,0], [-s.x,0,0], [0,-s.y,0], [0,0,-s.z] ],
            [ [0,2,1], [0,3,2], [0,4,3], [0,1,4], [5,1,2], [5,2,3], [5,3,4], [5,4,1] ]
        ]
    ) reorient(anchor,spin,orient, vnf=vnf, extent=true, p=vnf);



// Section: Cylinders


// Function&Module: cylinder()
// Synopsis: Creates an attachable cylinder.
// SynTags: Geom, VNF, Ext
// Topics: Shapes (3D), Attachable, VNF Generators
// See Also: cyl()
// Usage: As Module (as in native OpenSCAD)
//   cylinder(h, r=/d=, [center=]);
//   cylinder(h, r1/d1=, r2/d2=, [center=]);
// Usage: With BOSL2 anchoring and attachment extensions
//   cylinder(h, r=/d=, [center=], [anchor=], [spin=], [orient=]) [ATTACHMENTS];
//   cylinder(h, r1/d1=, r2/d2=, [center=], [anchor=], [spin=], [orient=]) [ATTACHMENTS];
// Usage: As Function (BOSL2 extension)
//   vnf = cylinder(h, r=/d=, ...);
//   vnf = cylinder(h, r1/d1=, r2/d2=, ...);
// Description:
//   Creates a 3D cylinder or conic object.
//   This modules extends the built-in `cylinder()` module by adding support for attachment and by adding a function version.   
//   When called as a function, returns a [VNF](vnf.scad) for a cylinder.  
// Arguments:
//   h = The height of the cylinder.
//   r1 = The bottom radius of the cylinder.  (Before orientation.)
//   r2 = The top radius of the cylinder.  (Before orientation.)
//   center = If given, overrides `anchor`.  A true value sets `anchor=CENTER`, false sets `anchor=BOTTOM`.  Default: false
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

module cylinder(h, r1, r2, center, r, d, d1, d2, anchor, spin=0, orient=UP)
{
    anchor = get_anchor(anchor, center, BOTTOM, BOTTOM);
    r1 = get_radius(r1=r1, r=r, d1=d1, d=d, dflt=1);
    r2 = get_radius(r1=r2, r=r, d1=d2, d=d, dflt=1);
    h = default(h,1);
    attachable(anchor,spin,orient, r1=r1, r2=r2, l=h) {
        _cylinder(h=h, r1=r1, r2=r2, center=true);
        children();
    }
}

function cylinder(h, r1, r2, center, r, d, d1, d2, anchor, spin=0, orient=UP) =
    let(
        anchor = get_anchor(anchor, center, BOTTOM, BOTTOM),
        r1 = get_radius(r1=r1, r=r, d1=d1, d=d, dflt=1),
        r2 = get_radius(r1=r2, r=r, d1=d2, d=d, dflt=1),
        l = default(h,1),
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
// Synopsis: Creates an attachable cylinder with roundovers and chamfering.
// SynTags: Geom, VNF
// Topics: Cylinders, Textures, Rounding, Chamfers
// See Also: regular_prism(), texture(), rotate_sweep(), cylinder()
// Usage: Normal Cylinders
//   cyl(l|h|length|height, r, [center], [circum=], [realign=]) [ATTACHMENTS];
//   cyl(l|h|length|height, d=, ...) [ATTACHMENTS];
//   cyl(l|h|length|height, r1=, r2=, ...) [ATTACHMENTS];
//   cyl(l|h|length|height, d1=, d2=, ...) [ATTACHMENTS];
//
// Usage: Chamferred Cylinders
//   cyl(l|h|length|height, r|d, chamfer=, [chamfang=], [from_end=], ...);
//   cyl(l|h|length|height, r|d, chamfer1=, [chamfang1=], [from_end=], ...);
//   cyl(l|h|length|height, r|d, chamfer2=, [chamfang2=], [from_end=], ...);
//   cyl(l|h|length|height, r|d, chamfer1=, chamfer2=, [chamfang1=], [chamfang2=], [from_end=], ...);
//
// Usage: Rounded End Cylinders
//   cyl(l|h|length|height, r|d, rounding=, [teardrop=], [clip_angle=], ...);
//   cyl(l|h|length|height, r|d, rounding1=, [teardrop=], [clip_angle=], ...);
//   cyl(l|h|length|height, r|d, rounding2=, [teardrop=], [clip_angle=], ...);
//   cyl(l|h|length|height, r|d, rounding1=, rounding2=, [teardrop=], [clip_angle=], ...);
//
// Usage: Textured Cylinders
//   cyl(l|h|length|height, r|d, texture=, [tex_size=]|[tex_reps=], [tex_depth=], [tex_rot=], [tex_samples=], [style=], [tex_taper=], [tex_inset=], ...);
//   cyl(l|h|length|height, r1=, r2=, texture=, [tex_size=]|[tex_reps=], [tex_depth=], [tex_rot=], [tex_samples=], [style=], [tex_taper=], [tex_inset=], ...);
//   cyl(l|h|length|height, d1=, d2=, texture=, [tex_size=]|[tex_reps=], [tex_depth=], [tex_rot=], [tex_samples=], [style=], [tex_taper=], [tex_inset=], ...);
//
// Usage: Called as a function to get a VNF
//   vnf = cyl(...);
//
// Description:
//   Creates cylinders in various anchorings and orientations, with optional rounding, chamfers, or textures.
//   You can use `h` and `l` interchangably, and all variants allow specifying size by either `r`|`d`,
//   or `r1`|`d1` and `r2`|`d2`.  Note: the chamfers and rounding cannot be cumulatively longer than
//   the cylinder or cone's sloped side.  The more specific parameters like chamfer1 or rounding2 override the more
//   general ones like chamfer or rounding, so if you specify `rounding=3, chamfer2=3` you will get a chamfer at the top and
//   rounding at the bottom.  You can specify extra height at either end for use with difference(); the extra height is ignored by
//   anchoring.
//   .
//   You can apply a texture to the cylinder using the usual texture parameters.   
//   See [Texturing](skin.scad#section-texturing) for more details on how textures work.  
//   When creating a textured cylinder, the number of facets is determined by the sampling of the texture.  Any `$fn`, `$fa` or `$fs` values in
//   effect are ignored.  To create a textured prism with a specified number of flat facets use {{regular_prism()}}.  Anchors for cylinders
//   appear on the ideal cylinder, not on actual discretized shape the module produces. For anchors on the shape surface, use {{regular_prism()}}.  
//   .
//   Note that when chamfering or rounding, the angle of chamfers is done at the face of the facets of the shape.
//   If `circum=false` (the default) then the radius or chamfer length is measured at the corner of the shape.  If `circum=true`
//   then the radius or chamfer length applies in the more usual way in the center of a facet.  For cylinders with a large `$fn`
//   the difference between these two things is negligible, but it can be quite sigificant when `$fn` is small.  
// Figure(2D,Big,NoAxes,VPR = [0, 0, 0], VPT = [0,0,0], VPD = 82): Chamfers on cones can be tricky.  This figure shows chamfers of the same size and same angle, A=30 degrees.  Note that the angle is measured on the inside, and produces a quite different looking chamfer at the top and bottom of the cone.  Straight black arrows mark the size of the chamfers, which may not even appear the same size visually.  When you do not give an angle, the triangle that is cut off will be isoceles, like the triangle at the top, with two equal angles.
//  color("lightgray")
//  projection()
//      cyl(r2=10, r1=20, l=20,chamfang=30, chamfer=0,orient=BACK);
//  projection()
//      cyl(r2=10, r1=20, l=20,chamfang=30, chamfer=8,orient=BACK);
//  color("black"){
//      fwd(9.6)right(20-4.8)text("A",size=1.3);
//      fwd(-8.4)right(10-4.9)text("A",size=1.3);
//      right(20-8)fwd(10.5)stroke([[0,0],[8,0]], endcaps="arrow2",width=.15);
//      right(10-8)fwd(-10.5)stroke([[0,0],[8,0]], endcaps="arrow2",width=.15);
//      stroke(arc(cp=[2,10], angle=[0,-30], n=20, r=5), width=.18, endcaps="arrow2");
//      stroke(arc(cp=[12,-10], angle=[0,30], n=20, r=5), width=.18, endcaps="arrow2");
//  }
// Figure(2D,Big,NoAxes,VPR = [0, 0, 0], VPT = [0,0,0], VPD = 82): The cone in this example is narrow but has the same slope.  With negative chamfers, the angle A=30 degrees is on the outside.  The chamfers are again quite different looking.  As before, the default will feature two congruent angles, and in this case it happens at the bottom of the cone but not the top.  The straight arrows again show the size of the chamfer.
//  r1=10-7.5;r2=20-7.5;
//  color("lightgray")
//  projection()
//      cyl(r2=r1, r1=r2, l=20,chamfang=30, chamfer=-8,orient=BACK);
//  projection()
//      cyl(r2=r1, r1=r2, l=20,chamfang=30, chamfer=0,orient=BACK);
//  color("black"){
//      fwd(9.7)right(r2+3.8)text("A",size=1.3);
//      fwd(-8.5)right(r1+3.7)text("A",size=1.3);
//      right(r2)fwd(10.5)stroke([[0,0],[8,0]], endcaps="arrow2",width=.15);
//      right(r1)fwd(-10.5)stroke([[0,0],[8,0]], endcaps="arrow2",width=.15);
//      stroke(arc(cp=[r1+8,10], angle=[180,180+30], n=20, r=5), width=.18, endcaps="arrow2");
//      stroke(arc(cp=[r2+8,-10], angle=[180-30,180], n=20, r=5), width=.18, endcaps="arrow2");
//  }
// Arguments:
//   l / h / length / height = Length of cylinder along oriented axis.  Default: 1
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
//   chamfer = The size of the chamfers on the ends of the cylinder.  (Also see: `from_end=`)  Default: none.
//   chamfer1 = The size of the chamfer on the bottom end of the cylinder.  (Also see: `from_end1=`)  Default: none.
//   chamfer2 = The size of the chamfer on the top end of the cylinder.  (Also see: `from_end2=`)  Default: none.
//   chamfang = The angle in degrees of the chamfers away from the ends of the cylinder.  Default: Chamfer angle is halfway between the endcap and cone face.
//   chamfang1 = The angle in degrees of the bottom chamfer away from the bottom end of the cylinder.  Default: Chamfer angle is halfway between the endcap and cone face.
//   chamfang2 = The angle in degrees of the top chamfer away from the top end of the cylinder.  Default: Chamfer angle is halfway between the endcap and cone face.
//   from_end = If true, chamfer is measured along the conic face from the ends of the cylinder, instead of inset from the edge.  Default: `false`.
//   from_end1 = If true, chamfer on the bottom end of the cylinder is measured along the conic face from the end of the cylinder, instead of inset from the edge.  Default: `false`.
//   from_end2 = If true, chamfer on the top end of the cylinder is measured along the conic face from the end of the cylinder, instead of inset from the edge.  Default: `false`.
//   rounding = The radius of the rounding on the ends of the cylinder.  Default: none.
//   rounding1 = The radius of the rounding on the bottom end of the cylinder.
//   rounding2 = The radius of the rounding on the top end of the cylinder.
//   extra = Add extra height at both ends that is invisible to anchoring for use with differencing.  Default: 0
//   extra1 = Add extra height to the bottom end
//   extra2 = Add extra height to the top end.  
//   realign = If true, rotate the cylinder by half the angle of one face.
//   teardrop = If given as a number, rounding around the bottom edge of the cylinder won't exceed this many degrees from horizontal.  If true, the limit angle is 45 degrees.  Default: `false`
//   clip_angle = If given as a number, rounding around the bottom edge of the cylinder won't exceed this many degrees from horizontal, with the rounding stopping at the bottom of the cylinder.  Default: (no clipping)
//   texture = A texture name string, or a rectangular array of scalar height values (0.0 to 1.0), or a VNF tile that defines the texture to apply to vertical surfaces.  See {{texture()}} for what named textures are supported.
//   tex_size = An optional 2D target size (2-vector or scalar) for the textures.  Actual texture sizes will be scaled somewhat to evenly fit the available surface. Default: `[5,5]`
//   tex_reps = If given instead of tex_size, a scalar or 2-vector giving the integer number of texture tile repetitions in the horizontal and vertical directions.
//   tex_inset = If numeric, lowers the texture into the surface by the specified proportion, e.g. 0.5 would lower it half way into the surface.  If `true`, insets by exactly its full depth.  Default: `false`
//   tex_rot = Rotate texture by specified angle, which must be a multiple of 90 degrees.  Default: 0
//   tex_depth = Specify texture depth; if negative, invert the texture.  Default: 1.  
//   tex_samples = Minimum number of "bend points" to have in VNF texture tiles.  Default: 8
//   tex_taper = The `tex_taper` parameter to {{rotate_sweep()}}.  If given as a number, tapers the texture depth to zero at the ends over the specified fraction of the height.  You can also give a lookup table or function to create custom depth taperings across the height of the cylinder.  The lookup table or function should be defined on the interval [0,1] where 0 gives the depth multiplier at the bottom and 1 the depth multiplier at the top.  Default: no taper
//   style = {{vnf_vertex_array()}} style used to triangulate heightfield textures.  Default: "min_edge"
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//
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
// Example(VPD=175;VPR=[90,0,0]): Teardrop Bottom Rounding
//   cyl(l=40, d=40, rounding=10, teardrop=true);
//
// Example(VPD=175;VPR=[90,0,0]): Clipped Bottom Rounding
//   cyl(l=40, d=40, rounding=10, clip_angle=40);
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
//       l=20, d1=25, d2=15,
//       chamfer1=5, chamfang1=60,
//       from_end=true, rounding2=5
//   );
//
// Example: External Chamfers
//   cyl(l=50, r=30, chamfer=-5, chamfang=30, $fa=1, $fs=1);
//
// Example: External Roundings
//   cyl(l=50, r=30, rounding1=-5, rounding2=5, $fa=1, $fs=1);
//
// Example(Med): Standard Connectors
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
//       style="convex");
//
// Example: Texturing with heightfield truncated pyramids
//   cyl(h=40, r1=20, r2=15, chamfer=5,
//       texture="trunc_pyramids",
//       tex_size=[5,5], style="convex");
//
// Example: Texturing with VNF tile "dots"
//   cyl(h=40, r1=20, r2=15, rounding=9,
//       texture="dots", tex_size=[5,5],
//       tex_samples=6);
//
// Example: Texturing with VNF tile "bricks_vnf"
//   cyl(h=50, r1=25, r2=20, shift=[0,10], rounding1=-10,
//       texture="bricks_vnf", tex_size=[10,10],
//       tex_depth=0.5, style="concave");
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
//       texture="trunc_ribs", tex_taper=0.1,
//       tex_size=[5,1]);
//
// Example(3D,Med,NoAxes): Making a Clay Pattern Roller
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
//       texture=tex, tex_reps=[20,1], tex_depth=-1,
//       style="concave") {
//           attach([TOP,BOT]) {
//               cyl(d1=20*10/PI, d2=30, h=5, anchor=BOT)
//                   attach(TOP) {
//                       tag("remove") zscale(0.5) up(3) sphere(d=15);
//                   }
//           }
//   }


// This function produces a path to rotate_extrude to make a "cylinder".  The extrusion
// produces the extreme points, and so the path is the path of a "corner" of the resulting
// object.  But things like chamfer angle and roundings should be relative to FACES.  So
// the code corrects the path to account for this, which is why it needs n, the number of
// sides.  If n is omitted, no correction occurs.  If you give n and set noscale=true then
// it corrects for the angle but still makes the chamfer lengths or rounding lengths along
// the corner edge.  This makes cylinders stack as expected (e.g. if you make a cyl with
// radius 5 and chamfer 1 then a radius 4 cyl fits on top.)  

function _cyl_path(
    r1, r2, l, 
    chamfer, chamfer1, chamfer2,
    chamfang, chamfang1, chamfang2,
    rounding, rounding1, rounding2,
    from_end, from_end1, from_end2,
    teardrop=false, clip_angle, n, noscale=false
) =
    let(
        scale= is_def(n) ? cos(180/n) : 1, 
        vang = atan2(scale*(r1-r2),l),
        _chamf1 = first_defined([chamfer1, if (is_undef(rounding1)) chamfer, 0]),
        _chamf2 = first_defined([chamfer2, if (is_undef(rounding2)) chamfer, 0]),
        _fromend1 = first_defined([from_end1, from_end, false]),
        _fromend2 = first_defined([from_end2, from_end, false]),
        chang1 = first_defined([chamfang1, chamfang, 45+sign(_chamf1)*vang/2]),
        chang2 = first_defined([chamfang2, chamfang, 45-sign(_chamf2)*vang/2]),
        round1 = first_defined([rounding1, if (is_undef(chamfer1)) rounding, 0]),
        round2 = first_defined([rounding2, if (is_undef(chamfer2)) rounding, 0]),
        checks1 =
            assert(is_finite(_chamf1), "chamfer1 must be a finite number if given.")
            assert(is_finite(_chamf2), "chamfer2 must be a finite number if given.")
            assert(is_finite(chang1) && chang1>0, "chamfang1 must be a positive number if given.")
            assert(is_finite(chang2) && chang2>0, "chamfang2 must be a positive number if given.")
            assert(chang1<90+sign(_chamf1)*vang, "chamfang1 must be smaller than the cone face angle")
            assert(chang2<90-sign(_chamf2)*vang, "chamfang2 must be smaller than the cone face angle")
            assert(num_defined([chamfer1,rounding1])<2, "cannot define both chamfer1 and rounding1")
            assert(num_defined([chamfer2,rounding2])<2, "cannot define both chamfer2 and rounding2")
            assert(num_defined([chamfer,rounding])<2, "cannot define both chamfer and rounding")                                
            undef,
        unscale = noscale ? scale : 1, 
        chamf1r = !_chamf1? 0
                : !_fromend1? unscale * _chamf1
                : unscale * law_of_sines(a=_chamf1, A=chang1, B=180-chang1-(90-sign(_chamf2)*vang)),
        chamf2r = !_chamf2? 0
                : !_fromend2? unscale * _chamf2
                : unscale * law_of_sines(a=_chamf2, A=chang2, B=180-chang2-(90+sign(_chamf2)*vang)),
        chamf1l = !_chamf1? 0
                : _fromend1? abs(_chamf1)
                : abs(law_of_sines(a=_chamf1, A=180-chang1-(90-sign(_chamf1)*vang), B=chang1)),
        chamf2l = !_chamf2? 0
                : _fromend2? abs(_chamf2)
                : abs(law_of_sines(a=_chamf2, A=180-chang2-(90+sign(_chamf2)*vang), B=chang2)),
        facelen = adj_ang_to_hyp(l, abs(vang)),

        roundlen1 = round1 >= 0 ? round1/tan(45-vang/2)
                                : round1/tan(45+vang/2),
        roundlen2 = round2 >=0 ? round2/tan(45+vang/2)
                               : round2/tan(45-vang/2),
        dy1 = abs(_chamf1 ? chamf1l : round1 ? roundlen1 : 0), 
        dy2 = abs(_chamf2 ? chamf2l : round2 ? roundlen2 : 0),

        td_ang = teardrop == true? 45
               : teardrop == false? 90
               : assert(is_finite(teardrop))
                 assert(teardrop>=0 && teardrop<=90)
                 teardrop,
        clip_ang = clip_angle == undef? 90
                 : assert(is_finite(clip_angle))
                   assert(clip_angle>=0 && clip_angle<=90)
                   clip_angle
    ) 
    assert(is_finite(round1), "rounding1 must be a number if given.")
    assert(is_finite(round2), "rounding2 must be a number if given.")
    assert(chamf1r/scale <= r1, "chamfer1 is larger than the r1 radius of the cylinder.")
    assert(chamf2r/scale <= r2, "chamfer2 is larger than the r2 radius of the cylinder.")
    assert(roundlen1*unscale/scale <= r1, "size of rounding1 is larger than the r1 radius of the cylinder.")
    assert(roundlen2*unscale/scale <= r2, "size of rounding2 is larger than the r2 radius of the cylinder.")
    assert(dy1+dy2 <= facelen, "Chamfers/roundings don't fit on the cylinder/cone.  They exceed the length of the cylinder/cone face.")
    assert(td_ang==90 || clip_ang==90, "teardrop= and clip_angle= are mutually exclusive options.")
    [
       if (!approx(chamf1r,0))
           each [
               [r1-chamf1r/scale, -l/2], // + [-chamf1r/scale,0],//polar_to_xy(chamf1r,180)),
               [r1, -l/2] + xscale(1/scale,polar_to_xy(chamf1l,90+vang)),
           ]
       else if (!approx(round1,0) && td_ang < 90)
           each xscale(1/scale,_teardrop_corner(r=round1*unscale, corner=[[r1*scale-2*roundlen1,-l/2],[r1*scale,-l/2],[r2*scale,l/2]], ang=td_ang))
       else if (!approx(round1,0) && clip_ang < 90)
           each xscale(1/scale,_clipped_corner(r=round1*unscale, corner=[[r1*scale-2*roundlen1,-l/2],[r1*scale,-l/2],[r2*scale,l/2]], ang=clip_ang))
       else if (!approx(round1,0) && td_ang >= 90)
           each xscale(1/scale,arc(r=abs(round1*unscale), corner=[[r1*scale-2*roundlen1,-l/2],[r1*scale,-l/2],[r2*scale,l/2]]))
       else [r1,-l/2],

       if (is_finite(chamf2r) && !approx(chamf2r,0))
           each [
               [r2, l/2] + xscale(1/scale,polar_to_xy(chamf2l,270+vang)),
               [r2-chamf2r/scale, l/2]
           ]
       else if (is_finite(round2) && !approx(round2,0))
           each xscale(1/scale,arc(r=abs(round2*unscale), corner=[[r1*scale,-l/2],[r2*scale,l/2],[r2*scale-2*roundlen2,l/2]]))
       else [r2,l/2],
    ];



function cyl(
    h, r, center,
    l, r1, r2,
    d, d1, d2,
    length, height,
    chamfer, chamfer1, chamfer2,
    chamfang, chamfang1, chamfang2,
    rounding, rounding1, rounding2,
    circum=false, realign=false, shift=[0,0],
    teardrop=false, clip_angle,
    from_end, from_end1, from_end2,
    texture, tex_size=[5,5], tex_reps, tex_counts,
    tex_inset=false, tex_rot=0,
    tex_scale, tex_depth, tex_samples, length, height, 
    tex_taper, style, tex_style,
    extra, extra1, extra2, 
    anchor, spin=0, orient=UP
) =
    assert(num_defined([style,tex_style])<2, "In cyl() the 'tex_style' parameter has been replaced by 'style'.  You cannot give both.")
    assert(num_defined([tex_reps,tex_counts])<2, "In cyl() the 'tex_counts' parameter has been replaced by 'tex_reps'.  You cannot give both.")    
    assert(num_defined([tex_scale,tex_depth])<2, "In cyl() the 'tex_scale' parameter has been replaced by 'tex_depth'.  You cannot give both.")
    let(
        style = is_def(tex_style)? echo("In cyl() the 'tex_style' parameter is deprecated and has been replaced by 'style'")tex_style
              : default(style,"min_edge"),
        tex_reps = is_def(tex_counts)? echo("In cyl() the 'tex_counts' parameter is deprecated and has been replaced by 'tex_reps'")tex_counts
                 : tex_reps,
        tex_depth = is_def(tex_scale)? echo("In cyl() the 'tex_scale' parameter is deprecated and has been replaced by 'tex_depth'")tex_scale
                  : default(tex_depth,1),
        l = one_defined([l, h, length, height],"l,h,length,height",dflt=1),
        _r1 = get_radius(r1=r1, r=r, d1=d1, d=d, dflt=1),
        _r2 = get_radius(r1=r2, r=r, d1=d2, d=d, dflt=1),
        sides = segs(max(_r1,_r2)),
        sc = circum? 1/cos(180/sides) : 1,
        r1 = _r1 * sc,
        r2 = _r2 * sc,
        anchor = get_anchor(anchor,center,BOT,CENTER),
        extra1 = first_defined([extra1,extra,0]),
        extra2 = first_defined([extra2,extra,0])
    )
    assert(all_nonnegative([extra1,extra2]), "extra/extra1/extra2 must be positive")
    assert(is_finite(l), "l/h/length/height must be a finite number.")
    assert(is_finite(r1) && r1>=0, "r/r1/d/d1 must be a non-negative number.")
    assert(is_finite(r2) && r2>=0, "r2 or d2 must be a non-negative number.")
    assert(is_vector(shift,2), "shift must be a 2D vector.")
    let(
        vnf = !any_defined([chamfer, chamfer1, chamfer2, rounding, rounding1, rounding2, texture, extra1, extra2])
          ? cylinder(h=l+extra1+extra2, r1=r1, r2=r2, center=true, $fn=sides)
          : let(
                 cpath = _cyl_path(r1, r2, l, 
                                   chamfer, chamfer1, chamfer2,
                                   chamfang, chamfang1, chamfang2,
                                   rounding, rounding1, rounding2,
                                   from_end, from_end1, from_end2,
                                   teardrop, clip_angle, sides, !circum),
                 path = [
                          if (texture==undef) [0,-l/2-extra1],
                          if (extra1>0) cpath[0]-[0,extra1],
                          each cpath,
                          if (extra2>0) last(cpath)+[0,extra2],
                          if (texture==undef) [0,l/2+extra2]
                        ]
            ) rotate_sweep(path,
                texture=texture, tex_reps=tex_reps, tex_size=tex_size,
                tex_inset=tex_inset, tex_rot=tex_rot,
                tex_depth=tex_depth, tex_samples=tex_samples,
                tex_taper=tex_taper, style=style, caps=true, 
                _tex_inhibit_y_slicing=true
            ),
        skmat = down(l/2) *
            skew(sxz=shift.x/l, syz=shift.y/l) *
            up(l/2) *
            zrot(realign? 180/sides : 0),
        ovnf = apply(skmat, vnf)
    )
    reorient(anchor,spin,orient, r1=r1, r2=r2, l=l, shift=shift, p=ovnf);



function _teardrop_corner(r, corner, ang=45) =
    let(
        check = assert(len(corner)==3)
            assert(is_finite(r))
            assert(is_finite(ang)),
        cp = circle_2tangents(abs(r), corner)[0],
        pvec = rot(sign(r)*90,p=corner[0]-corner[1]),
        path1 = arc(r=abs(r), corner=corner),
        path2 = [
            for (p = select(path1,0,-2))
                if (vector_angle(p-cp, pvec) > ang) p,
            last(path1)
        ],
        path = [
            line_intersection([corner[0],corner[1]],[path2[0],path2[0]+polar_to_xy(1,270-(90-ang)*sign(r))]),
            each path2
        ]
    ) path;


function _clipped_corner(r, corner, ang=45) =
    let(
        check = assert(len(corner)==3)
            assert(is_finite(r))
            assert(is_finite(ang)),
        vec1 = unit(corner[0] - corner[1]),
        vec2 = unit(corner[2] - corner[1]),
        off = r * (1-cos(ang)) * rot(90, p=vec1),
        line1 = [corner[0], corner[1]] + [off, off],
        line2 = [corner[1], corner[2]],
        corn_pt = line_intersection(line1,line2),
        cp = circle_2tangents(abs(r), [line1[0],corn_pt,line2[1]])[0],
        vec3 = rot(sign(r)*(90+ang), p=vec1),
        vec4 = rot(-sign(r)*90, p=vec2),
        dang = vector_angle(vec3,vec4),
        path = arc(r=abs(r), cp=cp, start=v_theta(vec3), angle=sign(r)*dang)
    ) path;


module cyl(
    h, r, center,
    l, r1, r2,
    d, d1, d2,
    chamfer, chamfer1, chamfer2,
    chamfang, chamfang1, chamfang2,
    rounding, rounding1, rounding2,
    circum=false, realign=false, shift=[0,0],
    teardrop=false, clip_angle,
    from_end, from_end1, from_end2,
    texture, tex_size=[5,5], tex_reps, tex_counts,
    tex_inset=false, tex_rot=0,
    tex_scale, tex_depth, tex_samples, length, height, 
    tex_taper, style, tex_style,
    extra, extra1, extra2, 
    anchor, spin=0, orient=UP
) {
    dummy=
      assert(num_defined([style,tex_style])<2, "In cyl() the 'tex_style' parameters has been replaced by 'style'.  You cannot give both.")
      assert(num_defined([tex_reps,tex_counts])<2, "In cyl() the 'tex_counts' parameters has been replaced by 'tex_reps'.  You cannot give both.")
      assert(num_defined([tex_scale,tex_depth])<2, "In cyl() the 'tex_scale' parameter has been replaced by 'tex_depth'.  You cannot give both.");
    style = is_def(tex_style)? echo("In cyl() the 'tex_style' parameter is deprecated and has been replaced by 'style'")tex_style
          : default(style,"min_edge");
    tex_reps = is_def(tex_counts)? echo("In cyl() the 'tex_counts' parameter is deprecated and has been replaced by 'tex_reps'")tex_counts
             : tex_reps;
    tex_depth = is_def(tex_scale)? echo("In rotate_sweep() the 'tex_scale' parameter is deprecated and has been replaced by 'tex_depth'")tex_scale
              : default(tex_depth,1);
    l = one_defined([l, h, length, height],"l,h,length,height",dflt=1);
    _r1 = get_radius(r1=r1, r=r, d1=d1, d=d, dflt=1);
    _r2 = get_radius(r1=r2, r=r, d1=d2, d=d, dflt=1);
    sides = segs(max(_r1,_r2));
    sc = circum? 1/cos(180/sides) : 1;
    r1 = _r1 * sc;
    r2 = _r2 * sc;
    anchor = get_anchor(anchor,center,BOT,CENTER);
    skmat = down(l/2) * skew(sxz=shift.x/l, syz=shift.y/l) * up(l/2);
    attachable(anchor,spin,orient, r1=r1, r2=r2, l=l, shift=shift) {
        multmatrix(skmat)
        zrot(realign? 180/sides : 0) {
            if (!any_defined([chamfer, chamfer1, chamfer2, rounding, rounding1, rounding2, texture, extra1, extra2, extra])) {
                cylinder(h=l, r1=r1, r2=r2, center=true, $fn=sides);
            } else {
                vnf = cyl(
                    l=l, r1=_r1, r2=_r2, center=true,  circum=circum,
                    chamfer=chamfer, chamfer1=chamfer1, chamfer2=chamfer2,
                    chamfang=chamfang, chamfang1=chamfang1, chamfang2=chamfang2,
                    rounding=rounding, rounding1=rounding1, rounding2=rounding2,
                    from_end=from_end, from_end1=from_end1, from_end2=from_end2,
                    teardrop=teardrop, clip_angle=clip_angle,
                    texture=texture, tex_size=tex_size,
                    tex_reps=tex_reps, tex_depth=tex_depth,
                    tex_inset=tex_inset, tex_rot=tex_rot,
                    style=style, tex_taper=tex_taper,
                    tex_samples=tex_samples,
                    extra1=extra1,extra2=extra2,extra=extra 
                );
                vnf_polyhedron(vnf, convexity=texture!=undef? 2 : 10);
            }
        }
        children();
    }
}



// Module: xcyl()
// Synopsis: creates a cylinder oriented along the X axis.
// SynTags: Geom
// Topics: Cylinders, Textures, Rounding, Chamfers
// See Also: texture(), rotate_sweep(), cyl()
// Description:
//   Creates an attachable cylinder with roundovers and chamfering oriented along the X axis.
//
// Usage: Typical
//   xcyl(l|h|length|height, r|d=, [anchor=], ...) [ATTACHMENTS];
//   xcyl(l|h|length|height, r1=|d1=, r2=|d2=, [anchor=], ...) [ATTACHMENTS];
//
// Arguments:
//   l / h / length / height = Length of cylinder along oriented axis. Default: 1
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

function xcyl(
    h, r, d, r1, r2, d1, d2, l, 
    chamfer, chamfer1, chamfer2,
    chamfang, chamfang1, chamfang2,
    rounding, rounding1, rounding2,
    circum=false, realign=false, from_end=false, length, height,
    anchor=CENTER, spin=0, orient=UP
) = no_function("xcyl");

module xcyl(
    h, r, d, r1, r2, d1, d2, l, 
    chamfer, chamfer1, chamfer2,
    chamfang, chamfang1, chamfang2,
    rounding, rounding1, rounding2,
    circum=false, realign=false, from_end=false, length, height,
    anchor=CENTER, spin=0, orient=UP
) {
    r1 = get_radius(r1=r1, r=r, d1=d1, d=d, dflt=1);
    r2 = get_radius(r1=r2, r=r, d1=d2, d=d, dflt=1);
    l = one_defined([l,h,length,height],"l,h,length,height",1);
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
// Synopsis: Creates a cylinder oriented along the y axis.
// SynTags: Geom
// Topics: Cylinders, Textures, Rounding, Chamfers
// See Also: texture(), rotate_sweep(), cyl()
// Description:
//   Creates an attachable cylinder with roundovers and chamfering oriented along the y axis.
//
// Usage: Typical
//   ycyl(l|h|length|height, r|d=, [anchor=], ...) [ATTACHMENTS];
//   ycyl(l|h|length|height, r1=|d1=, r2=|d2=, [anchor=], ...) [ATTACHMENTS];
//
// Arguments:
//   l / h / length / height = Length of cylinder along oriented axis. (Default: `1.0`)
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

function ycyl(
    h, r, d, r1, r2, d1, d2, l,
    chamfer, chamfer1, chamfer2,
    chamfang, chamfang1, chamfang2,
    rounding, rounding1, rounding2,
    circum=false, realign=false, from_end=false,height,length,
    anchor=CENTER, spin=0, orient=UP
) = no_function("ycyl");


module ycyl(
    h, r, d, r1, r2, d1, d2, l,
    chamfer, chamfer1, chamfer2,
    chamfang, chamfang1, chamfang2,
    rounding, rounding1, rounding2,
    circum=false, realign=false, from_end=false,height,length,
    anchor=CENTER, spin=0, orient=UP
) {
    r1 = get_radius(r1=r1, r=r, d1=d1, d=d, dflt=1);
    r2 = get_radius(r1=r2, r=r, d1=d2, d=d, dflt=1);
    l = one_defined([l,h,length,height],"l,h,length,height",1);
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
// Synopsis: Creates a cylinder oriented along the Z axis.
// SynTags: Geom
// Topics: Cylinders, Textures, Rounding, Chamfers
// See Also: texture(), rotate_sweep(), cyl()
// Description:
//   Creates an attachable cylinder with roundovers and chamfering oriented along the Z axis.
//
// Usage: Typical
//   zcyl(l|h|length|height, r|d=, [anchor=],...) [ATTACHMENTS];
//   zcyl(l|h|length|height, r1=|d1=, r2=|d2=, [anchor=],...);
//
// Arguments:
//   l / h / length / height = Length of cylinder along oriented axis. (Default: 1.0)
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

function zcyl(
    h, r, d, r1, r2, d1, d2, l,
    chamfer, chamfer1, chamfer2,
    chamfang, chamfang1, chamfang2,
    rounding, rounding1, rounding2,
    circum=false, realign=false, from_end=false, length, height,
    anchor=CENTER, spin=0, orient=UP
) = no_function("zcyl");

module zcyl(
    h, r, d, r1, r2, d1, d2, l,
    chamfer, chamfer1, chamfer2,
    chamfang, chamfang1, chamfang2,
    rounding, rounding1, rounding2,
    circum=false, realign=false, from_end=false, length, height,
    anchor=CENTER, spin=0, orient=UP
) {
    r1 = get_radius(r1=r1, r=r, d1=d1, d=d, dflt=1);
    r2 = get_radius(r1=r2, r=r, d1=d2, d=d, dflt=1);
    l = one_defined([l,h,length,height],"l,h,length,height",1);
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
// Synopsis: Creates a cylindrical or conical tube.
// SynTags: Geom
// Topics: Shapes (3D), Attachable, VNF Generators
// See Also: rect_tube()
// Description:
//   Makes a hollow tube that can be cylindrical or conical by specifying inner and outer dimensions or by giving one dimension and
//   wall thickness.
//   .
//   Chamfering and rounding lengths are measured based on the corners of the object except for the inner diameter when `circum=true`, in
//   which case chamfers and roundings are measured from the facets.  This only matters when `$fn` is small.  
//   .
//   Attachment to the tube will place objects on the **outside** of the tube.
//   If you need to anchor to the inside of a tube, use {{attach_part()}} with the part name "inside"
//   to switch goeomtry to the inside.  
// Usage: Basic cylindrical tube, specifying inner and outer radius or diameter
//   tube(h|l, or, ir, [center], [realign=], [anchor=], [spin=],[orient=]) [ATTACHMENTS];
//   tube(h|l, od=, id=, ...)  [ATTACHMENTS];
// Usage: Specify wall thickness
//   tube(h|l, or|od=|ir=|id=, wall=, ...) [ATTACHMENTS];
// Usage: Conical tubes
//   tube(h|l, ir1=|id1=, ir2=|id2=, or1=|od1=, or2=|od2=, ...) [ATTACHMENTS];
//   tube(h|l, or1=|od1=, or2=|od2=, wall=, ...) [ATTACHMENTS];
// Usage: Rounded and chamfered tubes
//   tube(..., [rounding=], [irounding=], [orounding=], [rounding1=], [rounding2=], [irounding1=], [irounding2=], [orounding1=], [orounding2=], [teardrop=], [clip_angle=]);
//   tube(..., [chamfer=], [ichamfer=], [ochamfer=], [chamfer1=], [chamfer2=], [ichamfer1=], [ichamfer2=], [ochamfer1=], [ochamfer2=]);
// Arguments:
//   h / l / height / length = height of tube. Default: 1
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
//   ifn = Set the number of facets on the inside of the tube.
//   circum = If true, the tube hole will circumscribe the circle of the given size.  Otherwise inscribes.  Default: `false`
//   shift = [X,Y] amount to shift the center of the top end with respect to the center of the bottom end.
//   rounding = The radius of the rounding on the ends of the tube.  Default: none.
//   rounding1 = The radius of the rounding on the bottom end of the tube.
//   rounding2 = The radius of the rounding on the top end of the tube.
//   irounding = The radius of the rounding on the inside of the ends of the tube.  
//   irounding1 = The radius of the rounding on the bottom inside end of the tube.
//   irounding2 = The radius of the rounding on the top inside end of the tube.
//   orounding = The radius of the rounding on the outside of the ends of the tube.
//   orounding1 = The radius of the rounding on the bottom outside end of the tube.
//   orounding2 = The radius of the rounding on the top outside end of the tube.
//   rounding_fn = Set `$fn` for roundings.  
//   chamfer = The size of the chamfer on the ends of the tube.  Default: none.
//   chamfer1 = The size of the chamfer on the bottom end of the tube.
//   chamfer2 = The size of the chamfer on the top end of the tube.
//   ichamfer = The size of the chamfer on the inside of the ends of the tube.  
//   ichamfer1 = The size of the chamfer on the bottom inside end of the tube.
//   ichamfer2 = The size of the chamfer on the top inside end of the tube.
//   ochamfer = The size of the chamfer on the outside of the ends of the tube. 
//   ochamfer1 = The size of the chamfer on the bottom outside end of the tube.
//   ochamfer2 = The size of the chamfer on the top outside end of the tube.
//   teardrop = If given as a number, rounding around the bottom edges won't exceed this many degrees from the endcap, altering to a chamfer at that angle.  If true, the limit angle is 45 degrees.  Default: `false`
//   clip_angle = If given as a number, rounding around the bottom edges won't exceed this many degrees from the endcap, with the rounding stopping at the bottom of the shape.  Default: (no clipping)
//   realign = If true, rotate the inner and outer parts tube by half the angle of one face so that a face is aligned at the X+ axis.  Default: False
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
//   tube(h=30, ir1=35, ir2=20, wall=5);
//   tube(h=30, or1=40, or2=25, ir1=35, ir2=20);
// Example: Circular Wedge
//   tube(h=30, or1=40, or2=30, ir1=20, ir2=30);
// Example: Standard Connectors
//   tube(h=30, or=40, wall=5) show_anchors();
// Example: Chamfered tube
//   back_half()
//     tube(ir=10,or=20, h=30, chamfer=2);
// Example: Rounded tube
//   back_half()
//     tube(ir=10,or=20,or2=5,ir2=2, h=30,
//         rounding1=5, rounding2=1.5);
// Example: Rounded conical tube, with negative rounding at base
//   back_half()
//     tube(ir=10,or=20,or2=5,ir2=2, h=30, rounding1=-5,rounding2=1.5);
// Example: Teardrop bottom rounding
//   back_half()
//     tube(ir=10,or=20,or2=5,ir2=2, h=30,
//         rounding1=5, rounding2=1.5, teardrop=true);
// Example: Clipped bottom rounding
//   back_half()
//     tube(ir=10,or=20,or2=5,ir2=2, h=30,
//         rounding1=5, rounding2=1.5, clip_angle=40);
// Example: Mixing chamfers and roundings
//   back_half()
//     tube(ir=10,or=20,h=30, ochamfer1=-5,irounding1=-3, orounding2=6, ichamfer2=2);
// Example: Tube with a square hole circumscribing its diameter
//   tube(od=22, id=9, h=10, $fn=48, ifn=4, circum=true);
//   half_of(v=[-1,1]) color("lightblue") cyl(d=9, h=12, $fn=32);
// Example: Round ended hexagonal tube using `rounding_fn` to get sufficient facets on the roundings
//   tube(or=10, ir=7, h=10, $fn=6, rounding_fn=64, rounding=1.3, teardrop=true);
// Example: This example shows a regular attachment to the outside of the tube in light blue and then using {{attach_part()}} to attach the pink cube to the inside of the tube.  
//   tube(ir1=10,ir2=20,h=20, wall=3){
//     color("lightblue")attach(RIGHT,BOT) cuboid(4);
//     color("pink")
//        attach_part("inside")
//        attach(BACK,BOT) cuboid(4);
//   }  

function tube(
    h, or, ir, center,
    od, id, wall,
    or1, or2, od1, od2,
    ir1, ir2, id1, id2,
    realign=false, l, length, height,
    anchor, spin=0, orient=UP, orounding1,irounding1,orounding2,irounding2,rounding1,rounding2,rounding,
    ochamfer1,ichamfer1,ochamfer2,ichamfer2,chamfer1,chamfer2,chamfer,irounding,ichamfer,orounding,ochamfer,
    teardrop=false, clip_angle, shift=[0,0],
    ifn, rounding_fn, circum=false
) = no_function("tube");



module tube(
    h, or, ir, center,
    od, id, wall,
    or1, or2, od1, od2,
    ir1, ir2, id1, id2,
    realign=false, l, length, height,
    anchor, spin=0, orient=UP, orounding1,irounding1,orounding2,irounding2,rounding1,rounding2,rounding,
    ochamfer1,ichamfer1,ochamfer2,ichamfer2,chamfer1,chamfer2,chamfer,irounding,ichamfer,orounding,ochamfer,
    teardrop=false, clip_angle, shift=[0,0],
    ifn, rounding_fn, circum=false
) {
    h = one_defined([h,l,height,length],"h,l,height,length",dflt=1);
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
        assert(is_vector(shift,2), "shift must be a 2D vector.")
        assert(all_defined([r1, r2, ir1, ir2]), "Must specify two of inner radius/diam, outer radius/diam, and wall width.")
        assert(num_defined([rounding,chamfer])<2, "Cannot give both rounding and chamfer")
        assert(num_defined([irounding,ichamfer])<2, "Cannot give both irounding and ichamfer")
        assert(num_defined([orounding,ochamfer])<2, "Cannot give both orounding and ochamfer")
        assert(num_defined([rounding1,chamfer1])<2, "Cannot give both rounding1 and chamfer1")
        assert(num_defined([irounding1,ichamfer1])<2, "Cannot give both irounding1 and ichamfern")
        assert(num_defined([orounding1,ochamfer1])<2, "Cannot give both orounding1 and ochamfer1")
        assert(num_defined([rounding2,chamfer2])<2, "Cannot give both rounding2 and chamfer2")
        assert(num_defined([irounding2,ichamfer2])<2, "Cannot give both irounding2 and ichamfern")
        assert(num_defined([orounding2,ochamfer2])<2, "Cannot give both orounding2 and ochamfer2");
    names = ["irounding","orounding","rounding","irounding1","irounding2","orounding1","orounding2",
             "ichamfer","ochamfer","chamfer","ichamfer1","ichamfer2","ochamfer1","ochamfer2"];
    vals =  [irounding,orounding,rounding,irounding1,irounding2,orounding1,orounding2,
             ichamfer,ochamfer,chamfer,ichamfer1,ichamfer2,ochamfer1,ochamfer2];
    bad = [for(i=idx(names)) if (is_def(vals[i]) && !is_finite(vals[i])) i];
    checks2 = assert(bad==[],str("Rounding/chamfer parameters must be numbers.  The following are invalid: ",
                                 select(names,bad)));
    findval = function (factor,vlist,i=0)
         i>=len(vlist) || is_def(vlist[i][1]) ? undef
                      : is_def(vlist[i][0]) ? factor*vlist[i][0]
                      : findval(factor,vlist,i+1);
    irounding1 = findval(-1,[[irounding1,ichamfer1],[rounding1,chamfer1],[irounding,ichamfer],[rounding,chamfer]]);
    irounding2 = findval(-1,[[irounding2,ichamfer2],[rounding2,chamfer2],[irounding,ichamfer],[rounding,chamfer]]);
    orounding1 = findval(1,[[orounding1,ochamfer1],[rounding1,chamfer1],[orounding,ochamfer],[rounding,chamfer]]);
    orounding2 = findval(1,[[orounding2,ochamfer2],[rounding2,chamfer2],[orounding,ochamfer],[rounding,chamfer]]);
    ichamfer1 = findval(-1,[[ichamfer1,irounding1],[chamfer1,rounding1],[ichamfer,irounding],[chamfer,rounding]]);
    ichamfer2 = findval(-1,[[ichamfer2,irounding2],[chamfer2,rounding2],[ichamfer,irounding],[chamfer,rounding]]);
    ochamfer1 = findval(1,[[ochamfer1,orounding1],[chamfer1,rounding1],[ochamfer,orounding],[chamfer,rounding]]);
    ochamfer2 = findval(1,[[ochamfer2,orounding2],[chamfer2,rounding2],[ochamfer,orounding],[chamfer,rounding]]);

    /*  This is too restrictive, at least on cones 
    dummy = 
      assert( first_defined([irounding1,ichamfer1,0])+first_defined([orounding1,ochamfer1,0]) <= r1-ir1, "Chamfer/rounding doesn't fit at bottom")
      assert( first_defined([irounding2,ichamfer2,0])+first_defined([orounding2,ochamfer2,0]) <= r2-ir2, "Chamfer/rounding doesn't fit at top")
      assert( -first_defined([irounding1,ichamfer1,0])<ir1, "Negative inside chamfer/rounding doesn't fit at bottom")
      assert( -first_defined([irounding2,ichamfer2,0])<ir1, "Negative inside chamfer/rounding doesn't fit at top");
    */

    anchor = get_anchor(anchor, center, BOT, CENTER);

    osides = segs(max(r1,r2));
    isides = default(ifn, segs(max(ir1,ir2)));

    adj_ir1 = circum ? ir1/cos(180/isides) : ir1;
    adj_ir2 = circum ? ir2/cos(180/isides) : ir2;

    
    morecheck=
        assert(adj_ir1 <= r1, "Inner radius is larger than outer radius.")
        assert(adj_ir2 <= r2, "Inner radius is larger than outer radius.");


    $fn = default(rounding_fn,$fn);

    outside= [
               [0,-h/2],
               each _cyl_path(r1,r2,h, 
                              chamfer1=ochamfer1, chamfer2=ochamfer2,
                              rounding1=orounding1, rounding2=orounding2,
                              teardrop=teardrop, clip_angle=clip_angle,n=osides, noscale=true),
               [0,h/2]
             ];
    ipath = _cyl_path(adj_ir1,adj_ir2,h, 
                      chamfer1=ichamfer1, chamfer2=ichamfer2,
                      rounding1=irounding1,rounding2=irounding2,n=isides, noscale=!circum);
    inside = [
               [0,-h/2-1],
               ipath[0]-[0,1],
               each ipath, 
               last(ipath)+[0,1],
               [0,h/2+1]
             ];
    parts = [
               define_part("inside", attach_geom(r1=ir1, r2=ir2, l=h), inside=true)
            ];
    attachable(anchor,spin,orient, r1=r1, r2=r2, l=h, parts=parts) {
        down(h/2) skew(sxz=shift.x/h, syz=shift.y/h) up(h/2) 
          difference(){
            zrot(realign? 180/osides : 0)rotate_extrude($fn=osides,angle=360) polygon(outside);
            zrot(realign? 180/isides : 0)rotate_extrude($fn=isides,angle=360) polygon(inside);
          }
        children();
    }
}    



// Function&Module: pie_slice()
// Synopsis: Creates a pie slice shape.
// SynTags: Geom, VNF
// Topics: Shapes (3D), Attachable, VNF Generators
// See Also: wedge()
// Description:
//   Creates a pie slice shape.
//
// Usage: As Module
//   pie_slice(l|h=|height=|length=, r, ang, [center]);
//   pie_slice(l|h=|height=|length=, d=, ang=, ...);
//   pie_slice(l|h=|height=|length=, r1=|d1=, r2=|d2=, ang=, ...);
// Usage: As Function
//   vnf = pie_slice(l|h=|height=|length=, r, ang, [center]);
//   vnf = pie_slice(l|h=|height=|length=, d=, ang=, ...);
//   vnf = pie_slice(l|h=|height=|length=, r1=|d1=, r2=|d2=, ang=, ...);
// Usage: Attaching Children
//   pie_slice(l|h, r, ang, ...) ATTACHMENTS;
//
// Arguments:
//   h / l / height / length = height of pie slice.
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
    r1, r2, d, d1, d2, l, length, height,
    anchor, spin=0, orient=UP
) {
    l = one_defined([l, h,height,length],"l,h,height,length",dflt=1);
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
    r1, r2, d, d1, d2, l, length, height,
    anchor, spin=0, orient=UP
) = let(
        anchor = get_anchor(anchor, center, BOT, BOT),
        l = one_defined([l, h,height,length],"l,h,height,length",dflt=1),
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
// Synopsis: Creates an attachable spherical object.
// SynTags: Geom, VNF, Ext
// Topics: Shapes (3D), Attachable, VNF Generators
// See Also: spheroid()
// Usage: As Module (native OpenSCAD)
//   sphere(r|d=);
// Usage: Using BOSL2 attachments extensions
//   sphere(r|d=, [anchor=], [spin=], [orient=]) [ATTACHMENTS];
// Usage: As Function (BOSL2 extension)
//   vnf = sphere(r|d=, [anchor=], [spin=], [orient=]) [ATTACHMENTS];
// Description:
//   Creates a sphere object.
//   This module extends the built-in `sphere()` module by providing support for BOSL2 anchoring and attachments, and a function form. 
//   When called as a function, returns a [VNF](vnf.scad) for a sphere.
// Arguments:
//   r = Radius of the sphere.
//   ---
//   d = Diameter of the sphere.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Example: By Radius
//   sphere(r=50);
// Example: By Diameter
//   sphere(d=100);
// Example: Anchoring
//   sphere(d=100, anchor=FRONT);
// Example: Spin
//   sphere(d=100, anchor=FRONT, spin=45);
// Example: Orientation
//   sphere(d=100, anchor=FRONT, spin=45, orient=FWD);
// Example: Standard Connectors
//   sphere(d=50) show_anchors();

module sphere(r, d, anchor=CENTER, spin=0, orient=UP) {
    r = get_radius(r=r, d=d, dflt=1);
    attachable(anchor,spin,orient, r=r) {
            _sphere(r=r);
            children();
    }
}

function sphere(r, d, anchor=CENTER, spin=0, orient=UP) =
    spheroid(r=r, d=d, style="orig", anchor=anchor, spin=spin, orient=orient);


// Function&Module: spheroid()
// Synopsis: Creates an attachable spherical object with controllable triangulation.
// SynTags: Geom, VNF
// Topics: Shapes (3D), Attachable, VNF Generators
// See Also: sphere()
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
// Synopsis: Creates an attachable torus.
// SynTags: Geom, VNF
// Topics: Shapes (3D), Attachable, VNF Generators
// See Also: spheroid(), cyl()
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
//   Creates an attachable toroidal shape.
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
// Synopsis: Creates a teardrop shape.
// SynTags: Geom, VNF
// Topics: Shapes (3D), Attachable, VNF Generators, FDM Optimized
// See Also: onion(), teardrop2d()
// Description:
//   Makes a teardrop extrusion along the Y axis, which is useful for 3D printable holes.
//   Optional chamfers can be added with positive or negative distances.  A positive distance
//   specifies the amount to inset the chamfer along the front/back faces of the shape.
//   The chamfer will extend the same y distance into the shape.  If the radii are the same
//   then the chamfer will be a 45 degree chamfer, but in other cases it will not.
//   With caps, the chamfer must not be so big that it makes the cap height illegal.
//   Similarly the chamfer cannot be larger than `bot_corner` if it is set, and if you do
//   set chamfer exactly equal to bottom corner, then `$fn` must be even if `realign` is false
//   and odd otherwise.  
// Usage: Typical
//   teardrop(h|l=|length=|height=, r, [ang], [cap_h], [chamfer=], [bot_corner=], ...) [ATTACHMENTS];
//   teardrop(h|l=|length=|height=, d=, [ang=], [cap_h=], [chamfer=], [bot_corner=], ...) [ATTACHMENTS];
// Usage: Psuedo-Conical
//   teardrop(h|l=|height=|length=, r1=, r2=, [ang=], [cap_h1=], [cap_h2=], [bot_corner1=], [bot_corner2=], ...)  [ATTACHMENTS];
//   teardrop(h|l=|height=|length=, d1=, d2=, [ang=], [cap_h1=], [cap_h2=], [bot_corner1=], [bot_corner2=], ...)  [ATTACHMENTS];
// Usage: As Function
//   vnf = teardrop(h|l=|height=|length=, r|d=, [ang=], [cap_h=], ...);
//   vnf = teardrop(h|l=|height=|length=, r1=|d1=, r2=|d2=, [ang=], [cap_h=], ...);
//   vnf = teardrop(h|l=|height=|length=, r1=|d1=, r2=|d2=, [ang=], [cap_h1=], [cap_h2=], ...);
//
// Arguments:
//   h / l / height / length = Thickness of teardrop. Default: 1
//   r = Radius of circular part of teardrop.  Default: 1
//   ang = Angle of hat walls from the Z axis.  Default: 45 degrees
//   cap_h = If given, height above center where the shape will be truncated. Default: `undef` (no truncation)
//   ---
//   circum = produce a circumscribing teardrop shape.  Default: false
//   r1 = Radius of circular portion of the front end of the teardrop shape.
//   r2 = Radius of circular portion of the back end of the teardrop shape.
//   d = Diameter of circular portion of the teardrop shape.
//   d1 = Diameter of circular portion of the front end of the teardrop shape.
//   d2 = Diameter of circular portion of the back end of the teardrop shape.
//   cap_h1 = If given, height above center where the shape will be truncated, on the front side. Default: `undef` (no truncation)
//   cap_h2 = If given, height above center where the shape will be truncated, on the back side. Default: `undef` (no truncation)
//   chamfer = Specifies size of chamfer as distance along the bottom and top faces.  Default: 0
//   chamfer1 = Specifies size of chamfer on bottom as distance along bottom face.  Default: 0
//   chamfer2 = Specifies size of chamfer on top as distance along top face.  Default: 0
//   realign = Passes realign option to teardrop2d, which shifts face alignment.  Default: false
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//
// Named Anchors:
//   "cap" = The center of the top of the cap, oriented with the cap face normal.
//   "cap_fwd" = The front edge of the cap.
//   "cap_back" = The back edge of the cap.
//
// Example: Typical Shape
//   teardrop(r=30, h=10, ang=30);
// Example: Crop Cap
//   teardrop(r=30, h=10, ang=30, cap_h=40);
// Example: Close Crop
//   teardrop(r=30, h=10, ang=30, cap_h=20);
// Example: Psuedo-Conical
//   teardrop(r1=20, r2=30, h=40, cap_h1=25, cap_h2=35);
// Example: Adding chamfers can be useful for a teardrop hole mask
//   teardrop(r=10, l=50, chamfer1=2, chamfer2=-1.5);
// Example: This teardrop has a 1 unit clearance at the top and bottom using the cap and the bottom corner:
//   teardrop(r=10, l=50, cap_h=11, bot_corner=1);
// Example: Getting a VNF
//   vnf = teardrop(r1=25, r2=30, l=20, cap_h1=25, cap_h2=35);
//   vnf_polyhedron(vnf);
// Example: Standard Conical Connectors
//   teardrop(d1=20, d2=30, h=20, cap_h1=11, cap_h2=16)
//       show_anchors(custom=false);
// Example(Spin,VPD=150,Med): Named Conical Connectors
//   teardrop(d1=20, d2=30, h=20, cap_h1=11, cap_h2=16)
//       show_anchors(std=false);
// Example: Creating holes using attachment
//   $fn=32;
//   diff()
//     cuboid(15)
//     attach([FWD,RIGHT],FWD,inside=true, shiftout=.1)
//       tag("remove")teardrop(d=4, l=10);
// Example: You can rotate the point using the `spin` option to {{attach()}}.  Don't use the `spin` parameter to `teardrop()`.  
//   $fn=32;
//   diff()
//     cuboid(15)
//     attach(FWD,FWD,align=[TOP,BOT], inset=2,
//            inside=true, shiftout=.1, spin=90)
//       tag("remove")teardrop(d=4, l=10);

module teardrop(h, r, ang=45, cap_h, r1, r2, d, d1, d2, cap_h1, cap_h2, l, length, height, circum=false, realign=false,
                chamfer, chamfer1, chamfer2,anchor=CENTER, spin=0, orient=UP, bot_corner1, bot_corner2, bot_corner=0)
{
    length = one_defined([l, h, length, height],"l,h,length,height");
    dummy=assert(is_finite(length) && length>0, "length must be positive");
    r1 = get_radius(r=r, r1=r1, d=d, d1=d1);
    r2 = get_radius(r=r, r1=r2, d=d, d1=d2);
    tip_y1 = r1/cos(90-ang);
    tip_y2 = r2/cos(90-ang);
    _cap_h1 = min(default(cap_h1, tip_y1), tip_y1);
    _cap_h2 = min(default(cap_h2, tip_y2), tip_y2);
    capvec = unit([0, _cap_h1-_cap_h2, length]);
    anchors = [
        named_anchor("cap",      [0,0,(_cap_h1+_cap_h2)/2], capvec),
        named_anchor("cap_fwd",  [0,-length/2,_cap_h1],         unit((capvec+FWD)/2)),
        named_anchor("cap_back", [0,+length/2,_cap_h2],         unit((capvec+BACK)/2), 180),
    ];
    attachable(anchor,spin,orient, r1=r1, r2=r2, l=length, axis=BACK, anchors=anchors)
    {
        vnf_polyhedron(teardrop(ang=ang,cap_h=cap_h,r1=r1,r2=r2,cap_h1=cap_h1,cap_h2=cap_h2,circum=circum,realign=realign,
                                length=length, chamfer1=chamfer1,chamfer2=chamfer2,chamfer=chamfer,bot_corner1=bot_corner1, bot_corner2=bot_corner2,bot_corner=bot_corner));
        children();
    }
}


function teardrop(h, r, ang=45, cap_h, r1, r2, d, d1, d2, cap_h1, cap_h2,  chamfer, chamfer1, chamfer2, circum=false, realign=false, bot_corner1, bot_corner2, bot_corner=0,
                  l, length, height, anchor=CENTER, spin=0, orient=UP) =
    let(
        r1 = get_radius(r=r, r1=r1, d=d, d1=d1, dflt=1),
        r2 = get_radius(r=r, r1=r2, d=d, d1=d2, dflt=1),
        length = one_defined([l, h, length, height],"l,h,length,height"),
        dummy0=assert(is_finite(length) && length>0, "length must be positive"),
        cap_h1 = first_defined([cap_h1, cap_h]),
        cap_h2 = first_defined([cap_h2, cap_h]),
        bot_corner1 = first_defined([bot_corner1, bot_corner]),
        bot_corner2 = first_defined([bot_corner2, bot_corner]),         
        chamfer1 = first_defined([chamfer1,chamfer,0]),
        chamfer2 = first_defined([chamfer2,chamfer,0]),    
        sides = segs(max(r1,r2)),
        profile1 = teardrop2d(r=r1, ang=ang, cap_h=cap_h1, $fn=sides, circum=circum, realign=realign,_extrapt=true, bot_corner=bot_corner1),
        profile2 = teardrop2d(r=r2, ang=ang, cap_h=cap_h2, $fn=sides, circum=circum, realign=realign,_extrapt=true, bot_corner=bot_corner2),
        tip_y1 = r1/cos(90-ang),
        tip_y2 = r2/cos(90-ang),
        _cap_h1 = min(default(cap_h1, tip_y1), tip_y1),
        _cap_h2 = min(default(cap_h2, tip_y2), tip_y2),
        capvec = unit([0, _cap_h1-_cap_h2, length]),
        dummy=
          assert(abs(chamfer1)+abs(chamfer2) <= length,"chamfers are too big to fit in the length")
          assert(chamfer1<=r1 && chamfer2<=r2, "Chamfers cannot be larger than raduis")
          assert(bot_corner1==0 || bot_corner1>=chamfer1, "\nchamfer1 doesn't work with bottom corner: must have chamfer1 <= bot_corner1")
          assert(bot_corner2==0 || bot_corner2>=chamfer2, "\nchamfer2 doesn't work with bottom corner: must have chamfer2 <= bot_corner2")
          assert(bot_corner1==0 || bot_corner1>chamfer1 || sides%2==(realign?1:0), 
                 str("\nWith chamfer1==bot_corner1 and realign=",realign," must have ",realign?"odd":"even"," number of sides, but sides=",sides))
          assert(is_undef(cap_h1) || cap_h1-chamfer1 > r1*sin(ang), "chamfer1 is too big to work with the specified cap_h1")
          assert(is_undef(cap_h2) || cap_h2-chamfer2 > r2*sin(ang), "chamfer2 is too big to work with the specified cap_h2"),
        cprof1 = r1==chamfer1 ? repeat([0,0],len(profile1))
                              : teardrop2d(r=r1-chamfer1, ang=ang, cap_h=u_add(cap_h1,-chamfer1), bot_corner=bot_corner1==0?0:bot_corner1-chamfer1,
                                           $fn=sides, circum=circum, realign=realign,_extrapt=true),
        cprof2 = r2==chamfer2 ? repeat([0,0],len(profile2))
                              : teardrop2d(r=r2-chamfer2, ang=ang, cap_h=u_add(cap_h2,-chamfer2), bot_corner=bot_corner2==0?0:bot_corner2-chamfer2,
                                           $fn=sides, circum=circum, realign=realign,_extrapt=true),
        anchors = [
            named_anchor("cap",      [0,0,(_cap_h1+_cap_h2)/2], capvec),
            named_anchor("cap_fwd",  [0,-length/2,_cap_h1],         unit((capvec+FWD)/2)),
            named_anchor("cap_back", [0,+length/2,_cap_h2],         unit((capvec+BACK)/2), 180),
        ],
        vnf = vnf_vertex_array(
            points = [
                if (chamfer1!=0) fwd(length/2, xrot(90, path3d(cprof1))),
                fwd(length/2-abs(chamfer1), xrot(90, path3d(profile1))),
                back(length/2-abs(chamfer2), xrot(90, path3d(profile2))),
                if (chamfer2!=0) back(length/2, xrot(90, path3d(cprof2))),
            ],
            caps=true, col_wrap=true, reverse=true
        )
    ) reorient(anchor,spin,orient, r1=r1, r2=r2, l=l, axis=BACK, anchors=anchors, p=vnf);


// Function&Module: onion()
// Synopsis: Creates an attachable onion-like shape.
// SynTags: Geom, VNF
// Topics: Shapes (3D), Attachable, VNF Generators, FDM Optimized
// See Also: teardrop(), teardrop2d()
// Description:
//   Creates a sphere with a conical hat, to make a 3D teardrop.
//
// Usage: As Module
//   onion(r|d=, [ang=], [cap_h=], [circum=], [realign=], ...) [ATTACHMENTS];
// Usage: As Function
//   vnf = onion(r|d=, [ang=], [cap_h=], [circum=], [realign=], ...);
//
// Arguments:
//   r = radius of spherical portion of the bottom. Default: 1
//   ang = Angle of cone on top from vertical. Default: 45 degrees
//   cap_h = If given, height above sphere center to truncate teardrop shape.  Default: `undef` (no truncation)
//   ---
//   circum = set to true to circumscribe the specified radius/diameter.  Default: False
//   realign = adjust point alignment to determine if bottom is flat or pointy.  Default: False
//   d = diameter of spherical portion of bottom.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//
// Named Anchors:
//   "cap" = The center of the top of the cap, oriented with the cap face normal.
//   "tip" = The position where an un-capped onion would come to a point, oriented in the direction the point is from the center.
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

module onion(r, ang=45, cap_h, d, circum=false, realign=false, anchor=CENTER, spin=0, orient=UP)
{
    r = get_radius(r=r, d=d, dflt=1);
    xyprofile = teardrop2d(r=r, ang=ang, cap_h=cap_h, circum=circum, realign=realign);
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
// Synopsis: Creates an attachable 3d text block.
// SynTags: Geom
// Topics: Attachments, Text
// See Also: path_text(), text() 
// Usage:
//   text3d(text, [h], [size], [font], [language=], [script=], [direction=], [atype=], [anchor=], [spin=], [orient=]);
// Description:
//   Creates a 3D text block that supports anchoring and single-parameter attachment to attachable objects.  You cannot attach children to text.
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
//   h / height / thickness = Extrusion height for the text.  Default: 1
//   size = The font will be created at this size divided by 0.72.   Default: 10
//   font = Font to use.  Default: "Liberation Sans" (standard OpenSCAD default)
//   ---
//   spacing = The relative spacing multiplier between characters.  Default: `1.0`
//   direction = The text direction.  `"ltr"` for left to right.  `"rtl"` for right to left. `"ttb"` for top to bottom. `"btt"` for bottom to top.  Default: `"ltr"`
//   language = The language the text is in.  Default: `"en"`
//   script = The script the text is in.  Default: `"latin"`
//   atype = Change vertical center between "baseline" and "ycenter".  Default: "baseline"
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `"baseline"`
//   center = Center the text.  Equivalent to `atype="center", anchor=CENTER`.  Default: false
//   spin = Rotate this many degrees around the Z axis.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Anchor Types:
//   baseline = Anchor center is relative to text baseline
//   ycenter = Anchor center is relative to the actual y direction center of the text
// Examples:
//   text3d("Fogmobar", h=3, size=10);
//   text3d("Fogmobar", h=2, size=12, font=":style=bold");
//   text3d("Fogmobar", h=2, anchor=CENTER);
//   text3d("Fogmobar", h=2, anchor=CENTER, atype="ycenter");
//   text3d("Fogmobar", h=2, anchor=RIGHT);
//   text3d("Fogmobar", h=2, anchor=RIGHT+BOT, atype="ycenter");
module text3d(text, h, size=10, font, spacing=1.0, direction="ltr", language="en", script="latin",
              height, thickness, atype, center=false,
              anchor, spin=0, orient=UP) {
    no_children($children);
    h = one_defined([h,height,thickness],"h,height,thickness",dflt=1);
    assert(is_undef(atype) || in_list(atype,["ycenter","baseline"]), "atype must be \"ycenter\" or \"baseline\"");
    assert(is_bool(center));
    assert(is_undef($attach_to),"text3d() does not support parent-child anchor attachment with two parameters");
    atype = default(atype, center?"ycenter":"baseline");
    anchor = default(anchor, center?CENTER:LEFT);
    geom = attach_geom(size=[size,size,h]);
    ha = anchor.x<0? "left" 
       : anchor.x>0? "right" 
       : "center";
    va = anchor.y<0? "bottom" 
       : anchor.y>0? "top" 
       : atype=="baseline"? "baseline"
       : "center";
    m = _attach_transform([0,0,anchor.z],spin,orient,geom);
    multmatrix(m) {
        $parent_anchor = anchor;
        $parent_spin   = spin;
        $parent_orient = orient;
        $parent_geom   = geom;
        $parent_size   = _attach_geom_size(geom);
        $attach_to   = undef;
        if (_is_shown()) {
            _color($color) _show_ghost() {
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
// Synopsis: Creates 2d or 3d text placed along a path.
// SynTags: Geom
// Topics: Text, Paths, Paths (2D), Paths (3D), Path Generators, Path Generators (2D)
// See Also, text(), text2d()
// Usage:
//   path_text(path, text, [size], [thickness], [font], [lettersize=], [offset=], [reverse=], [normal=], [top=], [textmetrics=], [kern=])
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
//   a monospace font such as "Liberation Mono".  Note that even with text metrics, spacing may be different because path_text()
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
//   size = The font will be created at this size divided by 0.72.   
//   thickness / h / height = thickness of letters (not allowed for 2D path)
//   font = Font to use.  Default: "Liberation Sans" (standard OpenSCAD default)
//   ---
//   lettersize = scalar or array giving size of letters
//   center = center text on the path instead of starting at the first point.  Default: false
//   offset = distance to shift letters "up" (towards the reader).  Not allowed for 2D path.  Default: 0
//   normal = direction or list of directions pointing towards the reader of the text.  Not allowed for 2D path.
//   top = direction or list of directions pointing toward the top of the text
//   reverse = reverse the letters if true.  Not allowed for 2D path.  Default: false
//   textmetrics = if set to true and lettersize is not given then use the experimental textmetrics feature.  You must be running a dev snapshot that includes this feature and have the feature turned on in your preferences.  Default: false
//   valign = align text to the path using "top", "bottom", "center" or "baseline".  You can also adjust position with a numerical offset as in "top-5" or "bottom+2".  This only works with textmetrics enabled.  You can give a simple numerical offset, which will be relative to the baseline and works even without textmetrics.  Default: "baseline"
//   kern = scalar or array giving spacing adjusments between each letter.  If it's an array it should have one less entry than the text string.  Default: 0
//   language = text language, passed to OpenSCAD `text()`.  Default: "en"
//   script = text script, passed to OpenSCAD `text()`.  Default: "latin" 
// Example(3D,NoScales):  The examples use Liberation Mono, a monospaced font.  The width is 1/1.2 times the specified size for this font.  This text could wrap around a cylinder.
//   path = path3d(arc(100, r=25, angle=[245, 370]));
//   color("red")stroke(path, width=.3);
//   path_text(path, "Example text", font="Liberation Mono", size=5, lettersize = 5/1.2);
// Example(3D,NoScales): By setting the normal to UP we can get text that lies flat, for writing around the edge of a disk:
//   path = path3d(arc(100, r=25, angle=[245, 370]));
//   color("red")stroke(path, width=.3);
//   path_text(path, "Example text", font="Liberation Mono", size=5, lettersize = 5/1.2, normal=UP);
// Example(3D,NoScales):  If we want text that reads from the other side we can use reverse.  Note we have to reverse the direction of the path and also set the reverse option.
//   path = reverse(path3d(arc(100, r=25, angle=[65, 190])));
//   color("red")stroke(path, width=.3);
//   path_text(path, "Example text", font="Liberation Mono", size=5, lettersize = 5/1.2, reverse=true);
// Example(3D,Med,NoScales): text debossed onto a cylinder in a spiral.  The text is 1 unit deep because it is half in, half out.
//   text = ("A long text example to wrap around a cylinder, possibly for a few times.");
//   L = 5*len(text);
//   maxang = 360*L/(PI*50);
//   spiral = [for(a=[0:1:maxang]) [25*cos(a), 25*sin(a), 10-30/maxang*a]];
//   difference(){
//     cyl(d=50, l=50, $fn=120);
//     path_text(spiral, text, size=5, lettersize=5/1.2, font="Liberation Mono", thickness=2);
//   }
// Example(3D,Med,NoScales): Same example but text embossed.  Make sure you have enough depth for the letters to fully overlap the object.
//   text = ("A long text example to wrap around a cylinder, possibly for a few times.");
//   L = 5*len(text);
//   maxang = 360*L/(PI*50);
//   spiral = [for(a=[0:1:maxang]) [25*cos(a), 25*sin(a), 10-30/maxang*a]];
//   cyl(d=50, l=50, $fn=120);
//   path_text(spiral, text, size=5, lettersize=5/1.2, font="Liberation Mono", thickness=2);
// Example(3D,NoScales): Here the text baseline sits on the path.  (Note the default orientation makes text readable from below, so we specify the normal.)
//   path = arc(100, points = [[-20, 0, 20], [0,0,5], [20,0,20]]);
//   color("red")stroke(path,width=.2);
//   path_text(path, "Example Text", size=5, lettersize=5/1.2, font="Liberation Mono", normal=FRONT);
// Example(3D,NoScales): If we use top to orient the text upward, the text baseline is no longer aligned with the path.
//   path = arc(100, points = [[-20, 0, 20], [0,0,5], [20,0,20]]);
//   color("red")stroke(path,width=.2);
//   path_text(path, "Example Text", size=5, lettersize=5/1.2, font="Liberation Mono", top=UP);
// Example(3D,Med,NoScales): This sine wave wrapped around the cylinder has a twisting normal that produces wild letter layout.  We fix it with a custom normal which is different at every path point.
//   path = [for(theta = [0:360]) [25*cos(theta), 25*sin(theta), 4*cos(theta*4)]];
//   normal = [for(theta = [0:360]) [cos(theta), sin(theta),0]];
//   zrot(-120)
//   difference(){
//     cyl(r=25, h=20, $fn=120);
//     path_text(path, "A sine wave wiggles", font="Liberation Mono", lettersize=5/1.2, size=5, normal=normal);
//   }
// Example(3D,Med,NoScales): The path center of curvature changes, and the text flips.
//   path =  zrot(-120,p=path3d( concat(arc(100, r=25, angle=[0,90]), back(50,p=arc(100, r=25, angle=[268, 180])))));
//   color("red")stroke(path,width=.2);
//   path_text(path, "A shorter example",  size=5, lettersize=5/1.2, font="Liberation Mono", thickness=2);
// Example(3D,Med,NoScales): We can fix it with top:
//   path =  zrot(-120,p=path3d( concat(arc(100, r=25, angle=[0,90]), back(50,p=arc(100, r=25, angle=[268, 180])))));
//   color("red")stroke(path,width=.2);
//   path_text(path, "A shorter example",  size=5, lettersize=5/1.2, font="Liberation Mono", thickness=2, top=UP);
// Example(2D,NoScales): With a 2D path instead of 3D there's no ambiguity about direction and it works by default:
//   path =  zrot(-120,p=concat(arc(100, r=25, angle=[0,90]), back(50,p=arc(100, r=25, angle=[268, 180]))));
//   color("red")stroke(path,width=.2);
//   path_text(path, "A shorter example",  size=5, lettersize=5/1.2, font="Liberation Mono");
// Example(3D,NoScales): The kern parameter lets you adjust the letter spacing either with a uniform value for each letter, or with an array to make adjustments throughout the text.  Here we show a case where adding some extra space gives a better look in a tight circle.  When textmetrics are off, `lettersize` can do this job, but with textmetrics, you'll need to use `kern` to make adjustments relative to the text metric sizes.
//   path = path3d(arc(100, r=12, angle=[150, 450]));
//   color("red")stroke(path, width=.3);
//   kern = [1,1.2,1,1,.3,-.2,1,0,.8,1,1.1];
//   path_text(path, "Example text", font="Liberation Mono", size=5, lettersize = 5/1.2, kern=kern, normal=UP);

module path_text(path, text, font, size, thickness, lettersize, offset=0, reverse=false, normal, top, center=false,
                 textmetrics=false, kern=0, height,h, valign="baseline", language, script)
{
  no_children($children);
  dummy2=assert(is_path(path,[2,3]),"Must supply a 2d or 3d path")
         assert(num_defined([normal,top])<=1, "Cannot define both \"normal\" and \"top\"")
         assert(all_positive([size]), "Must give positive text size");
  dim = len(path[0]);
  normalok = is_undef(normal) || is_vector(normal,3) || (is_path(normal,3) && len(normal)==len(path));
  topok = is_undef(top) || is_vector(top,dim) || (dim==2 && is_vector(top,3) && top[2]==0)
                        || (is_path(top,dim) && len(top)==len(path));
  dummy4 = assert(dim==3 || !any_defined([thickness,h,height]), "Cannot give a thickness or height with 2d path")
           assert(dim==3 || !reverse, "Reverse not allowed with 2d path")
           assert(dim==3 || offset==0, "Cannot give offset with 2d path")
           assert(dim==3 || is_undef(normal), "Cannot define \"normal\" for a 2d path, only \"top\"")
           assert(normalok,"\"normal\" must be a vector or path compatible with the given path")
           assert(topok,"\"top\" must be a vector or path compatible with the given path");
  thickness = one_defined([thickness,h,height],"thickness,h,height",dflt=1);
  normal = is_vector(normal) ? repeat(normal, len(path))
         : is_def(normal) ? normal
         : undef;

  top = is_vector(top) ? repeat(dim==2?point2d(top):top, len(path))
         : is_def(top) ? top
         : undef;

  kern = force_list(kern, len(text)-1);
  dummy3 = assert(is_list(kern) && len(kern)==len(text)-1, "kern must be a scalar or list whose length is len(text)-1");

  lsize = is_def(lettersize) ? force_list(lettersize, len(text))
        : textmetrics ? [for(letter=text) let(t=textmetrics(letter, font=font, size=size)) t.advance[0]]
        : assert(false, "textmetrics disabled: Must specify letter size");
  lcenter = convolve(lsize,[1,1]/2)+[0,each kern,0] ;
  textlength = sum(lsize)+sum(kern);

  ascent = !textmetrics ? undef
         : textmetrics(text, font=font, size=size).ascent;
  descent = !textmetrics ? undef
          : textmetrics(text, font=font, size=size).descent;

  vadjustment = is_num(valign) ? -valign
              : !textmetrics ? assert(valign=="baseline","valign requires textmetrics support") 0
              : let(
                     table = [
                              ["baseline", 0],
                              ["top", -ascent],
                              ["bottom", descent],
                              ["center", (descent-ascent)/2]
                             ],
                     match = [for(i=idx(table)) if (starts_with(valign,table[i][0])) i]
                )
                assert(len(match)==1, "Invalid valign value")
                table[match[0]][1] - parse_num(substr(valign,len(table[match[0]][0])));

  dummy1 = assert(textlength<=path_length(path),"Path is too short for the text");

  start = center ? (path_length(path) - textlength)/2 : 0;
   
  pts = path_cut_points(path, add_scalar(cumsum(lcenter),start), direction=true);

  usernorm = is_def(normal);
  usetop = is_def(top);
  normpts = is_undef(normal) ? (reverse?1:-1)*column(pts,3) : _cut_interp(pts,path, normal);
  toppts = is_undef(top) ? undef : _cut_interp(pts,path,top);
  attachable(){
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
              back(vadjustment)
              {
              left(lsize[i]/2)
                text(text[i], font=font, size=size, language=language, script=script);
              }
          }
        } else {
            frame_map(
              x=point3d(tangent-adjustment),
              y=point3d(usetop ? toppts[i] : -normpts[i])
            ) left(lsize[i]/2) {
                text(text[i], font=font, size=size, language=language, script=script);
            }
        }
      }
    }
    union();
  }
}



// Section: Miscellaneous


// Module: fillet()
// Synopsis: Creates a smooth fillet between two faces.
// SynTags: Geom, VNF
// Topics: Shapes (3D), Attachable
// See Also: mask2d_roundover()
// Description:
//   Creates a shape that can be unioned into a concave joint between two faces, to fillet them.
//   Note that this module is the same as {{rounding_edge_mask()}}, except that it does not
//   apply the default "remove" tag and has a different default angle.
//   It can be convenient to {{attach()}} the fillet to the edge of a parent object.
//   Many objects propagate the $edge_angle and $edge_length which are used as defaults for the fillet.
//   If you attach the fillet to the edge, it will be hovering in space and you need to apply {{yrot()}}
//   to place it on the parent object, generally either 90 degrees or -90 degrees dependong on which
//   face you want the fillet.  
// Usage: 
//   fillet(l|h=|length=|height=, r|d=, [ang=], [excess=], [rounding=|chamfer=]) [ATTACHMENTS];
//   fillet(l|h=|length=|height=, r1=|d1=, r2=|d2=, [ang=], [excess=], [rounding=|chamfer=]) [ATTACHMENTS];
//
// Arguments:
//   l/h/length/height = Length of mask.  Default: $edge_length if defined
//   r = Radius of the rounding.
//   ang = Angle between faces for rounding.  Default: 180-$edge_angle if defined, otherwise 90
//   ---
//   r1 = Bottom radius of fillet.
//   r2 = Top radius of fillet.
//   d = Diameter of the fillet.
//   d1 = Bottom diameter of fillet.
//   d2 = Top diameter of fillet.
//   excess = Extra size for the fillet.  Defaults: .1
//   rounding = Radius of roundong along ends.  Default: 0
//   rounding1 = Radius of rounding along bottom end
//   rounding2 = Radius of rounding along top end
//   chamfer = Chamfer size of end chamfers.  Default: 0
//   chamfer1 = Chamfer size of chamfer at bottom end
//   chamfer2 = Chamfer size of chamfer at top end
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
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
//       fillet(
//         l=20, r=10,
//         spin=180, orient=RIGHT
//       );
//   }
//
// Examples:
//   fillet(l=10, r=20, ang=60);
//   fillet(l=10, r=20, ang=90);
//   fillet(l=10, r=20, ang=120);
//
// Example: Using with Attachments
//   cube(50,center=true) {
//     position(FRONT+LEFT)
//       fillet(l=50, r=10, spin=-90);
//     position(BOT+FRONT)
//       fillet(l=50, r=10, spin=180, orient=RIGHT);
//   }
// Example: 
//   cuboid(50){
//     align(TOP,RIGHT,inset=10) fillet(l=50,r=10,orient=FWD);
//     align(TOP,RIGHT,inset=20) cuboid([4,50,20],anchor=BOT);
//   }
// Example(3D,VPT=[3.03052,-2.34905,8.07573],VPR=[70.4,0,326.2],VPD=82.6686): Automatic positioning of the fillet at the odd angle of this shifted prismoid is simple using {{attach()}} with the inherited $edge_angle.  
//  $fn=64;
//  prismoid([20,15],[12,17], h=10, shift=[3,5]){
//    attach(TOP+RIGHT,FWD+LEFT,inside=false)  
//      yrot(90)fillet(r=4);
//    attach(RIGHT,BOT)
//      cuboid([22,22,2]);
//  }

module interior_fillet(l=1.0, r, ang=90, overlap=0.01, d, length, h, height, anchor=CENTER, spin=0, orient=UP)
{
    deprecate("fillet");
    fillet(l,r,ang,overlap,d,length,h,height,anchor,spin,orient);
}


function fillet(l, r, ang, r1, r2, d, d1, d2, excess=0.1, anchor=CENTER, spin=0, orient=UP, h,height,length) = no_function("fillet");
module fillet(l, r, ang, r1, r2, excess=0.01, d1, d2,d,length, h, height, anchor=CENTER, spin=0, orient=UP,
                                        rounding,rounding1,rounding2,chamfer,chamfer1,chamfer2)
{
  ang = first_defined([ang, u_add(u_mul($edge_angle,-1),180), 90]);
  //echo(ang,180-$edge_angle);
  rounding_edge_mask(l=l, r1=r1, r2=r2, ang=ang, excess=excess, d1=d1, d2=d2,d=d,r=r,length=length, h=h, height=height,
                     chamfer1=chamfer1, chamfer2=chamfer2, chamfer=chamfer, rounding1=rounding1, rounding2=rounding2, rounding=rounding,
                     anchor=anchor, spin=spin, orient=orient, _remove_tag=false)
    children();
}  




// Function&Module: plot3d()
// Synopsis: Generates a surface by evaluating a function on a 2D grid
// SynTags: Geom, VNF
// Topics: Function Plotting
// See Also: plot_revolution(), textured_tile()
// Usage: As Module
//   plot3d(f, x, y, [zclip=], [zspan=], [base=], [convexity=], [style=]) [ATTACHMENTS];
// Usage: As Function
//   vnf = plot3d(f, x, y, [zclip=], [zspan=], [base=], [style=]);
// Description:
//   Given a function literal taking 2 parameters and a 2d grid, generate a surface where the height at any point is
//   the value of the function.  You can specify the grid using a range or using a list of points that
//   need not be uniformly spaced.  To create a valid polyhedron, the graph is closed at the sides and
//   a base is added below the smallest value.  By default this base has unit thickness, but you can
//   adjust it by setting the `base` parameter.  If you set `base=0` then you will get a a zero thickness
//   sheet that is not a manifold without sides or a bottom.
//   .
//   Your function may have have excessively large values at some points, or you may not know exactly 
//   what its extreme values are.  To manage these situations you can use either the `zclip` or `zspan`
//   parameter (but not both).  The `zclip` parameter is a 2-vector giving a minimum and maximum
//   value, either of which can be infinite.  If the function falls below the minimum it is set
//   equal to the minimum, and if it rises above the maximum it is set equal to the maximum.  The
//   `zspan` parameter is a 2-vector giving a minum and maximum value which must both be finite.
//   The function's values will be scaled and shifted to exactly cover the range you specifiy
//   in `zspan`.  
// Arguments:
//   f = function literal accepting two arguments (x and y) that defines the function to compute
//   x = A list or range of values for x
//   y = A list or range of values for y
//   ---
//   zclip = A vector `[zmin,zmax]' that constrains the output of function to these bounds. Cannot be used with `zspan`.
//   zspan = Rescale and shift the function values so the minimum value of f appears at zspan[0] and the maximum at zspan[1].  Cannot be used with `zclip`.
//   base = Amount of extra thickness to add at the bottom of the model.  If set to zero, produce a non-manifold zero-thickness VNF.  Default: 1
//   style = {{vnf_vertex_array()}} style used to triangulate heightfield textures.  Default: "default"
//   convexity = Max number of times a line could intersect a wall of the surface being formed. Module only.  Default: 10
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top toward, after spin. See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   atype = Select "hull" or "intersect" anchor type.  Default: "hull"
//   cp = Centerpoint for determining intersection anchors or centering the shape.  Determines the base of the anchor vector.  Can be "centroid", "mean", "box" or a 3D point.  Default: "centroid"
// Anchor Types:
//   "hull" = Anchors to the virtual convex hull of the shape.
//   "intersect" = Anchors to the surface of the shape.
// Named Anchors:
//   "origin" = Anchor at the origin, oriented UP.
// Example(NoScales):  A basic function calculation
//    func = function (x,y) 35*cos(3*norm([x,y]));
//    plot3d(func, [-180:4:180], [-180:4:180]);
// Example(NoScales):  Here we give the function inline and since it blows up we add clipping
//    plot3d(function (x,y) 1/norm([x,y]), [-2:.1:2], [-2:.1:2], zclip=[0,2],style="default");
// Example(NoScales):  Clipped edges often don't look very good and may be improved somewhat with more points.  Here we give lists with varying point spacing to improve the point density around the clipped top of the shape.
//    range = concat( 
//             lerpn(-2,-1,10,endpoint=false),
//             lerpn(-1,1,75,endpoint=false),
//             lerpn(1,2,10)
//            );
//    plot3d(function (x,y) 1/norm([x,y]), range, range, zclip=[0,2],style="default");
// Example(3D,NoAxes,VPR=[76.70,0.00,18.70],VPD=325.23,VPT=[-8.47,27.30,50.84]): Making a zero thickness VNF
//   fn = function (x,y) (x^2+y^2)/50;
//   plot3d(fn, [-50:5:50], [-50:5:50], base=0);
// Example(3D,NoScales): Use `zspan` to fit the plot vertically to a range and use anchoring to center it on the origin.  
//   f = function(x,y) 10*(sin(20*x)^2+cos(20*y)^2)/norm([2*x,y]);
//   plot3d(f, [10:.3:40], [4:.3:37],zspan=[0,25],anchor=BOT);

module plot3d(f,x,y,zclip, zspan, base=1, anchor="origin", orient=UP, spin=0, atype="hull", cp="box", convexity=4, style="default")
   vnf_polyhedron(plot3d(f,x,y,zclip, zspan,base, style=style), atype=atype, orient=orient, anchor=anchor, cp=cp, convexity=convexity) children();
   
function plot3d(f,x,y,zclip, zspan, base=1, anchor="origin", orient=UP, spin=0, atype="hull", cp="box", style="default") =
   assert(is_finite(base) && base>=0, "base must be a nonnegative number")
   assert(is_vector(x) || valid_range(x), "x must be a vector or nonempty range")
   assert(is_vector(y) || valid_range(y), "y must be a vector or nonempty range")
   assert(is_range(x) || is_increasing(x, strict=true), "x must be strictly increasing")
   assert(is_range(y) || is_increasing(y, strict=true), "y must be strictly increasing")
   assert(num_defined([zclip,zspan])<2, "Cannot give both zclip and zspan")
   assert(is_undef(zclip) || (is_list(zclip) && len(zclip)==2 && is_num(zclip[0]) && is_num(zclip[1])), "zclip must be a list of two values (which may be infinite)")
   assert(is_undef(zspan) || (is_vector(zspan,2) && zspan[0]<zspan[1]) ,"zspan must be a 2-vector whose first entry is smaller than the second")
   let(
       zclip = default(zclip, [-INF,INF]), 
       data = [for(x=x) [for(y=y) [x,y,min(max(f(x,y),zclip[0]),zclip[1])]]],
       dummy=assert(len(data[0])>1 && len(data)>1, "x and y must both provide at least 2 points"),
       minval = min(column(flatten(data),2)),
       maxval = max(column(flatten(data),2)),
       sdata = is_undef(zspan) ? data
             : let(
                    scale = (zspan[1]-zspan[0])/(maxval-minval)
               )
               [for(row=data) [for (entry=row) [entry.x,entry.y,scale*(entry.z-minval)+zspan[0]]]]
   )
   base==0 ? vnf_vertex_array(sdata,style=style)
 : 
   let(
       minval = min(column(flatten(sdata),2)),
       maxval = max(column(flatten(sdata),2)),
       bottom = is_def(zspan) ? zspan[0]-base : minval-base,
       data = [ [for(p=sdata[0]) [p.x,p.y,bottom]],
                each sdata,
                [for(p=last(sdata)) [p.x,p.y,bottom]]
              ],
       vnf = vnf_vertex_array(transpose(data), col_wrap=true, caps=true, style=style)
   )
   reorient(anchor,spin,orient, vnf=vnf, p=vnf);



// Function&Module: plot_revolution()
// Synopsis: Generates a surface by evaluating a of z and theta and putting the result on a surface of revolution
// SynTags: Geom, VNF
// Topics: Function Plotting
// See Also: plot3d()
// Usage: To create a cylinder or cone (by angle)
//   plot_revolution(f, angle, z, [r=/d=] [r1=/d1], [r2=/d2=], [rclip=], [rspan=], [horiz=], [style=], [convexity=], ...) [ATTACHMENTS];
// Usage: To create a cylinder or cone (by arclength)
//   plot_revolution(f, arclength=, z=, [r=/d=] [r1=/d1], [r2=/d2=], [rclip=], [rspan=], [horiz=], [style=], [convexity=], ...) [ATTACHMENTS];
// Usage: To create a surface of revolution
//   plot_revolution(f, [angle], [arclength=], path=, [rclip=], [rspan=], [horiz=], [style=], [convexity=], ...) [ATTACHMENTS];
// Usage: As Function
//   vnf = plot_revolution(...);
// Description:
//   Given a function literal, `f`, sets `r=f(theta,z)` over a range of theta and z values, and uses the
//   computed r values to define the offset from a cylinder or surface of revolution.  You can specify
//   the theta range as a `angle` to give an angle range in degrees or with `arclength` to give an arc length
//   range in distance units.  Your function will receive its parameters in
//   the form you specify, as angle or as arclength.  If you use `angle` then as the radius decreases, the
//   function shrinks in the horizontal direction to fit.  If you use `arclength` distance is preserved for
//   the function and as you move toward the top of a cone, the function will occupy a larger amount
//   of total angle so that the arc length stays the same.  
//   .
//   If the computed value produces a radius smaller than zero it will be rounded up to 0.01.  You can
//   specify a cylinder using the usual length and
//   radius or diameter parameters, or you can give `path`, a path which whose x values are strictly positive
//   to define the textured surface of revolution.  
//   .
//   Your function may have have excessively large values at some points, or you may not know exactly 
//   what its extreme values are.  To manage these situations you can use either the `rclip` or `rspan`
//   parameter (but not both).  The `rclip` parameter is a 2-vector giving a minimum and maximum
//   value, either of which can be infinite.  If the function falls below the minimum it is set
//   equal to the minimum, and if it rises above the maximum it is set equal to the maximum.  The
//   `rspan` parameter is a 2-vector giving a minum and maximum value which must both be finite.
//   The function's values will be scaled and shifted to exactly cover the range you specifiy
//   in `rspan`.
//   .
//   The default is to erect the function normal to the surface.  You can also set `horiz=true` to
//   erect the function perpendicular to the rotation axis.  In the former case, the caps of the
//   model are likely to be irregularly shaped and not exactly the requested size, unless the function
//   evaluates to zero at the top and bottom of the path.  When `horiz=true` the top and bottom will
//   be flat.  
// Arguments:
//   f = function literal accepting two arguments (angle and z) that defines the function to compute
//   angle = a list or range of angle values where the function is calculated
//   z = a list or range of z values to where the function is calculated, used only with cylinders and cones, not allowed with `path`.
//   ---
//   r / d = radius or diameter of cylinder (not allowed with `path`)
//   r1 / d1 = radius or diameter of bottom end (not allowed with `path`)
//   r2 / d2 = radius or diameter of top end (not allowed with `path`)
//   arclength = list or range of arc length values where the function is calculated 
//   path = path to revolve to produce the shape.  (If omitted you must supply cylinder parameters.)
//   rclip = A vector `[rmin,rmax]' that constrains the output of function to these bounds, which may be infinite. Cannot be used with `rspan`.
//   rspan = Rescale and shift the function values so the minimum value of f appears at rspan[0] and the maximum at rspan[1].  Cannot be used with `rclip`.
//   style = {{vnf_vertex_array()}} style used to triangulate heightfield textures.  Default: "default"
//   convexity = Max number of times a line could intersect a wall of the surface being formed. Module only.  Default: 10
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top toward, after spin. See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   atype = Select "hull" or "intersect" anchor type.  Default: "hull"
//   cp = Centerpoint for determining intersection anchors or centering the shape.  Determines the base of the anchor vector.  Can be "centroid", "mean", "box" or a 3D point.  Default: "centroid"
// Anchor Types:
//   "hull" = Anchors to the virtual convex hull of the shape.
//   "intersect" = Anchors to the surface of the shape.
// Named Anchors:
//   "origin" = Anchor at the origin, oriented UP.
// Example(3D,NoScale,VPR=[85.10,0.00,127.90],VPD=292.71,VPT=[21.15,13.27,0.90): 
//   f = function (x,y) 5*cos(5*norm([x*180/50,y*180/50]))+5;
//   plot_revolution(f, arclength=[-50:1:50], z=[-50:1:50], r=30); 
// Example(3D,NoScale,VPR=[69.00,0.00,96.40],VPD=361.36,VPT=[14.10,5.03,4.53]): When specifying angle, the pattern shrinks at the top of the cone. 
//   g = function (x,y) 5*sin(4*x)*cos(6*y)+5;
//   plot_revolution(g, z=[-60:2:60], angle=[-180:4:180], r1=30, r2=16);
// Example(3D,NoScale,VPR=[69.00,0.00,96.40],VPD=361.36,VPT=[14.10,5.03,4.53]): When specifying arc length, the shape wraps around more cone at the top
//   g = function (x,y) 5*sin(8*x)*cos(6*y)+5;
//   plot_revolution(g, z=[-60:.5:60], arclength=[-45:.5:45],r1=30,r2=16);
// Example(3D,VPR=[60.60,0.00,100.60],VPD=100.87,VPT=[-1.84,-1.70,5.63]): Here we place a simple ridge function onto a cone using angle.  Note how the ribs narrow with the radius.  
//   f = function(x,y) cos(20*x)+1;
//   plot_revolution(f,z=[0:.1:20], angle=[-45:.1:45], r1=20,r2=10, horiz=true);
//   cyl(h=20, r1=20,r2=10,anchor=BOT,$fn=64);
// Example(3D,VPR=[60.60,0.00,100.60],VPD=100.87,VPT=[-1.84,-1.70,5.63]): Here using arc length to put the function on the cone results in relatively straight ridges that do not narrow at the top of the cone.  Note that we had to adjust the function to be properly scaled for the arc length parameter instead of angle.  
//   f = function(x,y) cos(60*x)+1;
//   plot_revolution(f,z=[0:.1:20], arclength=[-15:.1:15], r1=20,r2=10, horiz=true);
//   cyl(h=20, r1=20,r2=10,anchor=BOT,$fn=64);
// Example(3D,VPR=[57.10,0.00,148.90],VPD=100.87,VPT=[-1.40,-0.72,4.63]): Changing the arc length range position changes how the function maps onto the surface.  
//   f = function(x,y) cos(60*x)+1;
//   plot_revolution(f,z=[0:.1:20], arclength=[0:.1:30], r1=20,r2=10, horiz=true);
//   cyl(h=20, r1=20,r2=10,anchor=BOT,$fn=64);
// Example(3D,Med,NoAxes,VPR=[73.90,0.00,17.30],VPD=124.53,VPT=[-10.15,31.37,-9.82]): Here we construct a model using a circular arc for the path, resulting in a spherical shape.  The left model has `horiz=false` and the right hand one has `horiz=true`.  
//   hcount=4;        // Number of ribs to create
//   vcount=2;        // How periods of oscillation for each rib
//   stretch_ang=200; // Angle extent of oscillations
//   g = function(x,y) sin(hcount * x + stretch_ang * sin(18 * vcount * y));
//   xcopies(spacing=30)
//     plot_revolution(g, [0:3:360], path=arc(200, r=10, angle=[-89,89]),style="min_edge", horiz=$idx==1);

module plot_revolution(f,angle,z,arclength, path, rclip, rspan, horiz=false,r1,r2,r,d1,d2,d,convexity=4,
                         anchor="origin", orient=UP, spin=0, atype="hull", cp="centroid", style="min_edge", reverse=false)
  vnf_polyhedron(plot_revolution(f=f,angle=angle,z=z,arclength=arclength,path=path, rclip=rclip, rspan=rspan, horiz=horiz, style=style, reverse=reverse,
                                 r=r,d=d,r1=r1,d1=d1,r2=r2,d2=d2), anchor=anchor, orient=orient, spin=spin, atype=atype, cp=cp);
 
function plot_revolution(f,angle,z,arclength, path, rclip, rspan, horiz=false,r1,r2,r,d1,d2,d,
                         anchor="origin", orient=UP, spin=0, atype="hull", cp="centroid", style="min_edge", reverse=false) =
   assert(num_defined([angle,arclength])==1, "must define exactly one of angle and arclength")
   assert(is_undef(z) || is_vector(z) || valid_range(z), "z must be a vector or nonempty range")
   assert(is_undef(path) || num_defined([r1,r2,d1,d2,r,d,z])==0, "Cannot define the z parameter or any radius or diameter parameters in combination with path")
   assert(num_defined([rclip,rspan])<2, "Cannot give both rclip and rspan")
   assert(is_undef(rclip) || (is_list(rclip) && len(rclip)==2 && is_finite(rclip[0]) && rclip[0]>0 && is_num(rclip[1])),
          "rclip must be a list of two values (r[1] may be infinite)")
   assert(is_undef(rspan) || (is_vector(rspan,2) && rspan[0]>0 && rspan[0]<rspan[1]) ,"rspan must be a 2-vector whose first entry is smaller than the second")
   let(
       r1 = get_radius(r1=r1, r=r, d1=d1, d=d),
       r2 = get_radius(r1=r2, r=r, d1=d2, d=d),
       dummy3=assert(is_def(path) || all_defined([r1,r2,z]), "\nMust give either path or both the 'z' and radius parameters."),
       rmin=0.01,
       z = list(z),
       thetarange = list(first_defined([angle,arclength])),
       dummy = assert(is_vector(thetarange) && len(thetarange)>1 && is_increasing(thetarange,strict=true),
                      "angle/arclength must be a strictly increasing array or range with at least 2 elements")
               assert(is_def(path)|| (len(z)>1 && is_increasing(z, strict=true)),"z must be a strictly increasing array or range with at least 2 elements")
               assert(is_def(arclength) || (last(thetarange)-thetarange[0])<=360, "angle span exceeds 360 degrees"),
       path = is_def(path) ? path
            : let(
                   rvals = add_scalar(add_scalar(z,-z[0]) / (last(z)-z[0]) * (r2-r1) ,r1)
              )
              hstack([rvals,z]),
       normals = horiz ? repeat([1,0], len(path))
               : path_normals(path),
       rclip = default(rclip, [-INF,INF]),
       rdata = [for(pt=path)
                  [for(theta=thetarange) min(max(f(theta,pt.y),rclip[0]),rclip[1])]],
       dummy2=assert(len(rdata[0])>1 && len(rdata)>1, "xrange and yrange must both provide at least 2 points"),
       minval = min(flatten(rdata)),
       maxval = max(flatten(rdata)),
       sdata = is_undef(rspan) ? rdata
             : let(
                    scale = (rspan[1]-rspan[0])/(maxval-minval)
               )
               [for(row=rdata) [for (entry=row) scale*(entry.z-minval)+rspan[0]]],
       closed = is_def(angle) && last(thetarange)-thetarange[0]==360,
       final = [for(i=idx(path))
                  let(
                      angscale = is_def(angle) ? 1
                               : 360/2/PI/path[i].x
                  )
                  assert(angscale*(last(thetarange)-thetarange[0])<=360, str("arclength span is more than 360 degrees at profile index ",i," with radius ",path[i].x))
                  [
                   if (!closed) [0,0,path[i].y],
                   for(j=idx(sdata[0]))
                       cylindrical_to_xyz(max(rmin,path[i].x+sdata[i][j]*normals[i].x), angscale*thetarange[j], path[i].y+sdata[i][j]*normals[i].y)
                   ]
               ]
   )
   vnf_vertex_array(final, col_wrap=true, caps=true,reverse=!reverse, style=style);




/// Function&Module: heightfield()
/// Synopsis: Generates a 3D surface from a 2D grid of values.
/// SynTags: Geom, VNF
/// Topics: Textures, Heightfield
/// See Also: cylindrical_heightfield()
/// Usage: As Module
///   heightfield(data, [size], [bottom], [maxz], [xrange], [yrange], [style], [convexity], ...) [ATTACHMENTS];
/// Usage: As Function
///   vnf = heightfield(data, [size], [bottom], [maxz], [xrange], [yrange], [style], ...);
/// Description:
///   Given a regular rectangular 2D grid of scalar values, or a function literal, generates a 3D
///   surface where the height at any given point is the scalar value for that position.
///   One script to convert a grayscale image to a heightfield array in a .scad file can be found at:
///   https://raw.githubusercontent.com/BelfrySCAD/BOSL2/master/scripts/img2scad.py
///   The bottom value defines a planar base for the resulting shape and it must be strictly less than
///   the model data to produce valid geometry, so data which is too small is set to 0.1 units above the bottom value. 
/// Arguments:
///   data = This is either the 2D rectangular array of heights, or a function literal that takes X and Y arguments.
///   size = The [X,Y] size of the surface to create.  If given as a scalar, use it for both X and Y sizes. Default: `[100,100]`
///   bottom = The Z coordinate for the bottom of the heightfield object to create.  Any heights lower than this will be truncated to very slightly (0.1) above this height.  Default: -20
///   maxz = The maximum height to model.  Truncates anything taller to this height.  Set to INF for no truncation.  Default: 100
///   xrange = A range of values to iterate X over when calculating a surface from a function literal.  Default: [-1 : 0.01 : 1]
///   yrange = A range of values to iterate Y over when calculating a surface from a function literal.  Default: [-1 : 0.01 : 1]
///   style = The style of subdividing the quads into faces.  Valid options are "default", "alt", and "quincunx".  Default: "default"
///   ---
///   convexity = Max number of times a line could intersect a wall of the surface being formed. Module only.  Default: 10
///   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
///   spin = Rotate this many degrees around the Z axis.  See [spin](attachments.scad#subsection-spin).  Default: `0`
///   orient = Vector to rotate top towards.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
/// Example:
///   heightfield(size=[100,100], bottom=-20, data=[
///       for (y=[-180:4:180]) [
///           for(x=[-180:4:180])
///           10*cos(3*norm([x,y]))
///       ]
///   ]);
/// Example:
///   intersection() {
///       heightfield(size=[100,100], data=[
///           for (y=[-180:5:180]) [
///               for(x=[-180:5:180])
///               10+5*cos(3*x)*sin(3*y)
///           ]
///       ]);
///       cylinder(h=50,d=100);
///   }
/// Example: Heightfield by Function
///   fn = function (x,y) 10*sin(x*360)*cos(y*360);
///   heightfield(size=[100,100], data=fn);
/// Example: Heightfield by Function, with Specific Ranges
///   fn = function (x,y) 2*cos(5*norm([x,y]));
///   heightfield(
///       size=[100,100], bottom=-20, data=fn,
///       xrange=[-180:2:180], yrange=[-180:2:180]
///   );

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
    let(
        dummy=is_function(data) ? echo("***** heightfield() is deprecated and will be removed in a future version.  For displaying functions use plot3d().  *****")
                                : echo("***** heightfield() is deprecated and will be removed in a future version.  For displaying arrays use textured_tile() *****")
    )
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
                        min(max(data[y][x],bottom+0.1),maxz)
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


/// Function&Module: cylindrical_heightfield()
/// Synopsis: Generates a cylindrical 3d surface from a 2D grid of values.
/// SynTags: Geom, VNF
/// Topics: Extrusion, Textures, Knurling, Heightfield
/// Usage: As Function
///   vnf = cylindrical_heightfield(data, l|length=|h=|height=, r|d=, [base=], [transpose=], [aspect=]);
/// Usage: As Module
///   cylindrical_heightfield(data, l|length=|h=|height=, r|d=, [base=], [transpose=], [aspect=]) [ATTACHMENTS];
/// Description:
///   Given a regular rectangular 2D grid of scalar values, or a function literal of signature (x,y), generates
///   a cylindrical 3D surface where the height at any given point above the radius `r=`, is the scalar value
///   for that position.
///   One script to convert a grayscale image to a heightfield array in a .scad file can be found at:
///   https://raw.githubusercontent.com/BelfrySCAD/BOSL2/master/scripts/img2scad.py
/// Arguments:
///   data = This is either the 2D rectangular array of heights, or a function literal of signature `(x, y)`.
///   l / length / h / height = The length of the cylinder to wrap around.
///   r = The radius of the cylinder to wrap around.
///   ---
///   r1 = The radius of the bottom of the cylinder to wrap around.
///   r2 = The radius of the top of the cylinder to wrap around.
///   d = The diameter of the cylinder to wrap around.
///   d1 = The diameter of the bottom of the cylinder to wrap around.
///   d2 = The diameter of the top of the cylinder to wrap around.
///   base = The radius for the bottom of the heightfield object to create.  Any heights smaller than this will be truncated to very slightly above this height.  Default: -20
///   transpose = If true, swaps the radial and length axes of the data.  Default: false
///   aspect = The aspect ratio of the generated heightfield at the surface of the cylinder.  Default: 1
///   xrange = A range of values to iterate X over when calculating a surface from a function literal.  Default: [-1 : 0.01 : 1]
///   yrange = A range of values to iterate Y over when calculating a surface from a function literal.  Default: [-1 : 0.01 : 1]
///   maxh = The maximum height above the radius to model.  Truncates anything taller to this height.  Default: 99
///   style = The style of subdividing the quads into faces.  Valid options are "default", "alt", and "quincunx".  Default: "default"
///   convexity = Max number of times a line could intersect a wall of the surface being formed. Module only.  Default: 10
///   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
///   spin = Rotate this many degrees around the Z axis.  See [spin](attachments.scad#subsection-spin).  Default: `0`
///   orient = Vector to rotate top towards.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
/// Example(VPD=400;VPR=[55,0,150]):
///   cylindrical_heightfield(l=100, r=30, base=5, data=[
///       for (y=[-180:4:180]) [
///           for(x=[-180:4:180])
///           5*cos(5*norm([x,y]))+5
///       ]
///   ]);
/// Example(VPD=400;VPR=[55,0,150]):
///   cylindrical_heightfield(l=100, r1=60, r2=30, base=5, data=[
///       for (y=[-180:4:180]) [
///           for(x=[-180:4:180])
///           5*cos(5*norm([x,y]))+5
///       ]
///   ]);
/// Example(VPD=400;VPR=[55,0,150]): Heightfield by Function
///   fn = function (x,y) 5*sin(x*360)*cos(y*360)+5;
///   cylindrical_heightfield(l=100, r=30, data=fn);
/// Example(VPD=400;VPR=[55,0,150]): Heightfield by Function, with Specific Ranges
///   fn = function (x,y) 2*cos(5*norm([x,y]));
///   cylindrical_heightfield(
///       l=100, r=30, base=5, data=fn,
///       xrange=[-180:2:180], yrange=[-180:2:180]
///   );


function cylindrical_heightfield(
    data, l, r, base=1,
    transpose=false, aspect=1,
    style="min_edge", maxh=99,
    xrange=[-1:0.01:1],
    yrange=[-1:0.01:1],
    r1, r2, d, d1, d2, h, height, length, 
    anchor=CTR, spin=0, orient=UP
) =
    let(
        dummy=is_function(data)
           ? echo("***** cylindrical_heightfield() is deprecated and will be removed in a future version.  For creating functions on cylinders use plot_revolution(). *****")
           : echo("***** cylindrical_heightfield() is deprecated and will be removed in a future version.  For displaying arrays on a cylinder use rotate_sweep() *****"),
        l = one_defined([l, h, height, length], "l,h,height,l"),
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
    maxh=99, r1, r2, d, d1, d2, h, height, length,
    anchor=CTR, spin=0, orient=UP
) {
    l = one_defined([l, h, height, length], "l,h,height,length");
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
// Synopsis: Creates a ruler.
// SynTags: Geom
// Topics: Distance
// Usage:
//   ruler(length, width, [thickness=], [depth=], [labels=], [pipscale=], [maxscale=], [colors=], [alpha=], [unit=], [inch=]) [ATTACHMENTS];
// Description:
//   Creates an attachable ruler for checking dimensions of the model.  The rule appears only in preview mode (F5) and is not displayed
//   when the model is rendered (F6).  
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
    if ($preview){
        checks =
            assert(depth<=5, "Cannot render scales smaller than depth=5")
            assert(len(colors)==2, "colors must contain a list of exactly two colors.");
        length = inch ? INCH * length : length;
        unit = inch ? INCH*unit : unit;
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
}




// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap


