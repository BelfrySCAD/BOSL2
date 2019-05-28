include <BOSL2/std.scad>
include <BOSL2/paths.scad>
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
	) [for (row=patch)
		translate_points(v=trans,
			rotate_points3d(a=spin, from=UP, to=orient,
				scale_points(v=size, row)
			)
		)
	];


function CR_edge(size, spin=0, orient=UP, trans=[0,0,0]) =
	let (
		// This patch might not yet correct for continuous rounding,
		// but it's a first approximation proof of concept.
		a = 0.68,
		c = 0.24,
		m = -1/2,
		n = -3/10,
		o = -1/10,
		p =  1/10,
		q =  3/10,
		r =  1/2,
		patch = [
			[[1,0,m], [1,0,n], [1,0,o], [1,0,p], [1,0,q], [1,0,r]],
			[[a,0,m], [a,0,n], [a,0,o], [a,0,p], [a,0,q], [a,0,r]],
			[[c,0,m], [c,0,n], [c,0,o], [c,0,p], [c,0,q], [c,0,r]],
			[[0,c,m], [0,c,n], [0,c,o], [0,c,p], [0,c,q], [0,c,r]],
			[[0,a,m], [0,a,n], [0,a,o], [0,a,p], [0,a,q], [0,a,r]],
			[[0,1,m], [0,1,n], [0,1,o], [0,1,p], [0,1,q], [0,1,r]],
		]
	) [for (row=patch)
		translate_points(v=trans,
			rotate_points3d(a=spin, from=UP, to=orient,
				scale_points(v=size, row)
			)
		)
	];


module CR_cube(size=[100,100,100], r=10, splinesteps=8, cheat=false, debug=false)
{
	s = size-2*[r,r,r];
	h = size/2;
	corners = [
		CR_corner([r,r,r], spin=0,   orient=UP, trans=[-size.x/2, -size.y/2, -size.z/2]),
		CR_corner([r,r,r], spin=90,  orient=UP, trans=[ size.x/2, -size.y/2, -size.z/2]),
		CR_corner([r,r,r], spin=180, orient=UP, trans=[ size.x/2,  size.y/2, -size.z/2]),
		CR_corner([r,r,r], spin=270, orient=UP, trans=[-size.x/2,  size.y/2, -size.z/2]),

		CR_corner([r,r,r], spin=0,   orient=DOWN, trans=[ size.x/2, -size.y/2,  size.z/2]),
		CR_corner([r,r,r], spin=90,  orient=DOWN, trans=[-size.x/2, -size.y/2,  size.z/2]),
		CR_corner([r,r,r], spin=180, orient=DOWN, trans=[-size.x/2,  size.y/2,  size.z/2]),
		CR_corner([r,r,r], spin=270, orient=DOWN, trans=[ size.x/2,  size.y/2,  size.z/2]),
	];
	edges = [
		CR_edge([r, r, s.x], spin=0,   orient=RIGHT, trans=[   0, -h.y,  h.z]),
		CR_edge([r, r, s.x], spin=90,  orient=RIGHT, trans=[   0, -h.y, -h.z]),
		CR_edge([r, r, s.x], spin=180, orient=RIGHT, trans=[   0,  h.y, -h.z]),
		CR_edge([r, r, s.x], spin=270, orient=RIGHT, trans=[   0,  h.y,  h.z]),

		CR_edge([r, r, s.y], spin=0,   orient=BACK,  trans=[-h.x,    0,  h.z]),
		CR_edge([r, r, s.y], spin=90,  orient=BACK,  trans=[ h.x,    0,  h.z]),
		CR_edge([r, r, s.y], spin=180, orient=BACK,  trans=[ h.x,    0, -h.z]),
		CR_edge([r, r, s.y], spin=270, orient=BACK,  trans=[-h.x,    0, -h.z]),

		CR_edge([r, r, s.z], spin=0,   orient=UP,    trans=[-h.x, -h.y,    0]),
		CR_edge([r, r, s.z], spin=90,  orient=UP,    trans=[ h.x, -h.y,    0]),
		CR_edge([r, r, s.z], spin=180, orient=UP,    trans=[ h.x,  h.y,    0]),
		CR_edge([r, r, s.z], spin=270, orient=UP,    trans=[-h.x,  h.y,    0])
	];
	faces = [
		// Yes, these are degree 1 bezier patches.  That means just the four corner points.
		// Since these are flat, it doesn't matter what degree they are, and this will reduce calculation overhead.
		bezier_patch_flat([s.y, s.z], N=1, orient=RIGHT, trans=[ h.x,    0,    0]),
		bezier_patch_flat([s.y, s.z], N=1, orient=LEFT,  trans=[-h.x,    0,    0]),

		bezier_patch_flat([s.x, s.z], N=1, orient=BACK,  trans=[   0,  h.y,    0]),
		bezier_patch_flat([s.x, s.z], N=1, orient=FRONT, trans=[   0, -h.y,    0]),

		bezier_patch_flat([s.x, s.y], N=1, orient=UP,    trans=[   0,    0,  h.z]),
		bezier_patch_flat([s.x, s.y], N=1, orient=DOWN,  trans=[   0,    0, -h.z])
	];

	if (cheat) {
		hull() bezier_polyhedron(patches=corners, splinesteps=splinesteps);
	} else {
		if (debug) {
			trace_bezier_patches(patches=concat(edges, faces, corners), showcps=true, splinesteps=splinesteps);
		} else {
			bezier_polyhedron(patches=concat(edges, faces, corners), splinesteps=splinesteps);
		}
	}
}


CR_cube(size=[100,100,100], r=20, splinesteps=16, cheat=false, debug=false);
cube(1);



// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
