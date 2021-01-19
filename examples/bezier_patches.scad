include <BOSL2/std.scad>
include <BOSL2/beziers.scad>


function CR_corner(size, spin=0, orient=UP, trans=[0,0,0]) =
    let (
        // This patch might not yet correct for continuous rounding,
        // but it's a first approximation proof of concept.
        a = 0.68,
        b = 0.60,
        c = 0.24,
        patch = [
            [[0,1,1], [0,a,1], [0,c,1], [c,0,1], [a,0,1], [1,0,1]],
            [[0,1,a], [0,b,b], [0,0,b], [b,0,b], [1,0,a]],
            [[0,1,c], [0,b,0], [b,0,0], [1,0,c]],
            [[c,1,0], [b,b,0], [1,c,0]],
            [[a,1,0], [1,a,0]],
            [[1,1,0]],
        ]
    )
    translate(trans,
        p=rot(a=spin, from=UP, to=orient,
            p=scale(size, p=patch)
        )
    );


function CR_edge(size, spin=0, orient=UP, trans=[0,0,0]) =
    let (
        // This patch might not be correct for continuous rounding,
        // but it's a first approximation proof of concept.
        vvals = [1.00, 0.68, 0.24],
        xyvals = [
            for (x=vvals) [x,0],
            for (y=reverse(vvals)) [0,y]
        ],
        zvals = [-0.5:0.2:0.5],
        patch = [for (xy=xyvals) [for (z=zvals) [each xy, z]]]
    ) 
    translate(trans,
        p=rot(a=spin, from=UP, to=orient,
            p=scale(size, p=patch)
        )
    );


module CR_cube(size=[100,100,100], r=10, splinesteps=8, debug=false)
{
    s = size-2*[r,r,r];
    h = size/2;
    corner_pat = CR_corner([r,r,r], trans=[-size.x/2, -size.y/2, -size.z/2]);
    edge_pat = CR_edge([r, r, s.z], trans=[-h.x, -h.y, 0]);
    face_pat = bezier_patch_flat([s.x, s.z], N=1, orient=FRONT, trans=[0, -h.y, 0]);
    corners = bezier_surface([
        for (yr=[0,180], zr=[0:90:270]) let(
            m = yrot(yr) * zrot(zr)
        ) [for (row=corner_pat) apply(m, row)]
    ], splinesteps=splinesteps);
    edges = bezier_surface([
        for (axr=[[0,0,0],[90,0,0],[0,90,0]],zr=[0:90:270]) let(
            m = rot(axr) * zrot(zr)
        ) [for (row=edge_pat) apply(m, row)]
    ], splinesteps=[splinesteps,1]);
    faces = bezier_surface([
        for (axr=[0,90,180,270,[-90,0,0],[90,0,0]]) let(
            m = rot(axr)
        ) [for (row=face_pat) apply(m, row)]
    ], splinesteps=1);

    if (debug) {
        vnf_validate([edges, faces, corners], convexity=4);
    } else {
        vnf_polyhedron([edges, faces, corners], convexity=4);
    }
}


CR_cube(size=[100,100,100], r=20, splinesteps=16, debug=false);
cube(1);



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
