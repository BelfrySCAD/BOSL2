include <BOSL2/std.scad>
include <BOSL2/paths.scad>
include <BOSL2/beziers.scad>

rounding_factor = 0.667;

function CR_corner(size, spin=0, orient=UP, trans=[0,0,0]) =
	let (
		r = rounding_factor,
		k = r/2,
		// I know this patch is not yet correct for continuous
		// rounding, but it's a first approximation proof of concept.
		// Currently this is a degree 4 triangular patch.
		patch = [
			[[0,1,1], [0,r,1], [0,0,1], [r,0,1], [1,0,1]],
			[[0,1,r], [0,k,k], [k,0,k], [1,0,r]],
			[[0,1,0], [k,k,0], [1,0,0]],
			[[r,1,0], [1,r,0]],
			[[1,1,0]]
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
		r = rounding_factor,
		a = -1/2,
		b = -1/4,
		c =  1/4,
		d =  1/2,
		// I know this patch is not yet correct for continuous
		// rounding, but it's a first approximation proof of concept.
		// Currently this is a degree 4 rectangular patch.
		patch = [
			[[1,0,a], [1,0,b], [1,0,0], [1,0,c], [1,0,d]],
			[[r,0,a], [r,0,b], [r,0,0], [r,0,c], [r,0,d]],
			[[0,0,a], [0,0,b], [0,0,0], [0,0,c], [0,0,d]],
			[[0,r,a], [0,r,b], [0,r,0], [0,r,c], [0,r,d]],
			[[0,1,a], [0,1,b], [0,1,0], [0,1,c], [0,1,d]]
		]
	) [for (row=patch)
		translate_points(v=trans,
			rotate_points3d(a=spin, from=UP, to=orient,
				scale_points(v=size, row)
			)
		)
	];


module CR_cube(size=[100,100,100], r=10, splinesteps=8, cheat=false)
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
		CR_corner([r,r,r], spin=270, orient=DOWN, trans=[ size.x/2,  size.y/2,  size.z/2])
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
	// Generating all the patches above took about 0.05 secs.

	if (cheat) {
		// Hulling just the corners takes less than a second.
		hull() bezier_polyhedron(tris=corners, splinesteps=splinesteps);
	} else {
		// Generating the polyhedron fully from bezier patches takes 3 seconds on my laptop.
		bezier_polyhedron(patches=concat(edges, faces), tris=corners, splinesteps=splinesteps);
	}
}


CR_cube(size=[100,100,100], r=20, splinesteps=15, cheat=false);
cube(1);



// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
