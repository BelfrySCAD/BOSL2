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
		zrot(gaussian_rand(90,20))
		zring(n=floor(log_rand(2,5,4)))
		zrot(gaussian_rand(0,5))
		yrot(gaussian_rand(30,10))
		let(
			sc = gaussian_rand(0.7,0.05),
			s1 = $parent_size.z*sc,
			s2 = $parent_size2.x
		)
		cylinder(d1=s2, d2=s2*sc, l=s1)
		branches(minsize);
	} else {
		recolor("springgreen")
		attach(TOP) zrot(90)
		leaf(gaussian_rand(100,5));
	}
}
recolor("lightgray") cylinder(d1=300, d2=250, l=1500) branches(10);


// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
