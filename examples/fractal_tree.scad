include <BOSL2/std.scad>
include <BOSL2/paths.scad>
include <BOSL2/beziers.scad>

module leaf(s) {
	path = [
		[0,0], [1.5,-1],
		[2,1], [0,3], [-2,1],
		[-1.5,-1], [0,0]
	];
	xrot(90)
	linear_sweep_bezier(
		scale_points(path, [s,s]/2),
		height=0.02
	);
}

module branches(minsize){
    if($parent_size2.x>minsize) {
		attach(TOP)
		zrot(gaussian_rands(90,20)[0])
		zrot_copies(n=floor(log_rands(2,5,4)[0]))
		zrot(gaussian_rands(0,5)[0])
		yrot(gaussian_rands(30,10)[0])
		let(
			sc = gaussian_rands(0.7,0.05)[0],
			s1 = $parent_size.z*sc,
			s2 = $parent_size2.x
		)
		cylinder(d1=s2, d2=s2*sc, l=s1)
		branches(minsize);
	} else {
		recolor("springgreen")
		attach(TOP) zrot(90)
		leaf(gaussian_rands(100,5)[0]);
	}
}
recolor("lightgray") cylinder(d1=300, d2=250, l=1500) branches(10);


// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
