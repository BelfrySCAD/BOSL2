include <BOSL2/std.scad>

module test(got,expect,extra_info) {
	if (
		is_undef(expect) != is_undef(got) ||
		expect*0 != got*0 ||
		(is_vnf(expect) && !all([for (i=idx(expect[0])) approx(got[0][i],expect[0][i])]) && got[1]!=expect[1]) ||
		(is_matrix(expect) && !all([for (i=idx(expect)) approx(got[i],expect[i])])) ||
		(got!=expect && !approx(got, expect))
	) {
		fmt = is_int(expect)? "{:.14i}" :
			is_num(expect)? "{:.14g}" :
			is_vector(expect)? "{:.14g}" :
			"{}";
		echofmt(str("Expected: ",fmt),[expect]);
		echofmt(str("But Got : ",fmt),[got]);
		if (expect*0 == got*0) {
			echofmt(str("Delta is: ",fmt),[expect-got]);
		}
		if (!is_undef(extra_info)) {
			echo(str("Extra Info: ",extra_info));
		}
		assert(false, "TEST FAILED!");
	}
}


module test_rot() {
	pts2d = 50 * [for (x=[-1,0,1],y=[-1,0,1]) [x,y]];
	pts3d = 50 * [for (x=[-1,0,1],y=[-1,0,1],z=[-1,0,1]) [x,y,z]];
	vecs2d = [
		for (x=[-1,0,1], y=[-1,0,1]) if(x!=0||y!=0) [x,y],
		polar_to_xy(1, -75),
		polar_to_xy(1,  75)
	];
	vecs3d = [
		LEFT, RIGHT, FRONT, BACK, DOWN, UP,
		spherical_to_xyz(1, -30,  45),
		spherical_to_xyz(1,   0,  45),
		spherical_to_xyz(1,  30,  45),
		spherical_to_xyz(2,  30,  45),
		spherical_to_xyz(1, -30, 135),
		spherical_to_xyz(2, -30, 135),
		spherical_to_xyz(1,   0, 135),
		spherical_to_xyz(1,  30, 135),
		spherical_to_xyz(1, -30,  75),
		spherical_to_xyz(1,  45,  45),
	];
	angs = [-180, -90, -45, 0, 30, 45, 90];
	for (a = [-360*3:360:360*3]) {
		test(rot(a), affine3d_identity(), extra_info=str("rot(",a,") != identity"));
		test(rot(a,p=pts2d), pts2d, extra_info=str("rot(",a,",p=...), 2D"));
		test(rot(a,p=pts3d), pts3d, extra_info=str("rot(",a,",p=...), 3D"));
	}
	test(rot(90), [[0,-1,0,0],[1,0,0,0],[0,0,1,0],[0,0,0,1]])
	for (a=angs) {
		test(rot(a), affine3d_zrot(a), extra_info=str("Z angle (only) = ",a));
		test(rot([a,0,0]), affine3d_xrot(a), extra_info=str("X angle = ",a));
		test(rot([0,a,0]), affine3d_yrot(a), extra_info=str("Y angle = ",a));
		test(rot([0,0,a]), affine3d_zrot(a), extra_info=str("Z angle = ",a));

		test(rot(a,p=pts2d), apply(affine3d_zrot(a),pts2d), extra_info=str("Z angle (only) = ",a, ", p=..., 2D"));
		test(rot([0,0,a],p=pts2d), apply(affine3d_zrot(a),pts2d), extra_info=str("Z angle = ",a, ", p=..., 2D"));

		test(rot(a,p=pts3d), apply(affine3d_zrot(a),pts3d), extra_info=str("Z angle (only) = ",a, ", p=..., 3D"));
		test(rot([a,0,0],p=pts3d), apply(affine3d_xrot(a),pts3d), extra_info=str("X angle = ",a, ", p=..., 3D"));
		test(rot([0,a,0],p=pts3d), apply(affine3d_yrot(a),pts3d), extra_info=str("Y angle = ",a, ", p=..., 3D"));
		test(rot([0,0,a],p=pts3d), apply(affine3d_zrot(a),pts3d), extra_info=str("Z angle = ",a, ", p=..., 3D"));
	}
	for (xa=angs, ya=angs, za=angs) {
		test(
			rot([xa,ya,za]),
			affine3d_chain([
				affine3d_xrot(xa),
				affine3d_yrot(ya),
				affine3d_zrot(za)
			]),
			extra_info=str("[X,Y,Z] = ",[xa,ya,za])
		);
		test(
			rot([xa,ya,za],p=pts3d),
			apply(
				affine3d_chain([
					affine3d_xrot(xa),
					affine3d_yrot(ya),
					affine3d_zrot(za)
				]),
				pts3d
			),
			extra_info=str("[X,Y,Z] = ",[xa,ya,za], ", p=...")
		);
	}
	for (vec1 = vecs3d) {
		for (ang = angs) {
			test(
				rot(a=ang, v=vec1),
				affine3d_rot_by_axis(vec1,ang),
				extra_info=str("a = ",ang,", v = ", vec1)
			);
			test(
				rot(a=ang, v=vec1, p=pts3d),
				apply(affine3d_rot_by_axis(vec1,ang), pts3d),
				extra_info=str("a = ",ang,", v = ", vec1, ", p=...")
			);
		}
	}
	for (vec1 = vecs2d) {
		for (vec2 = vecs2d) {
			test(
				rot(from=vec1, to=vec2, p=pts2d, planar=true),
				apply(affine2d_zrot(vang(vec2)-vang(vec1)), pts2d),
				extra_info=str(
					"from = ", vec1, ", ",
					"to = ", vec2, ", ",
					"planar = ", true, ", ",
					"p=..., 2D"
				)
			);
		}
	}
	for (vec1 = vecs3d) {
		for (vec2 = vecs3d) {
			for (a = angs) {
				test(
					rot(from=vec1, to=vec2, a=a),
					affine3d_chain([
						affine3d_zrot(a),
						affine3d_rot_from_to(vec1,vec2)
					]),
					extra_info=str(
						"from = ", vec1, ", ",
						"to = ", vec2, ", ",
						"a = ", a
					)
				);
				test(
					rot(from=vec1, to=vec2, a=a, p=pts3d),
					apply(
						affine3d_chain([
							affine3d_zrot(a),
							affine3d_rot_from_to(vec1,vec2)
						]),
						pts3d
					),
					extra_info=str(
						"from = ", vec1, ", ",
						"to = ", vec2, ", ",
						"a = ", a, ", ",
						"p=..., 3D"
					)
				);
			}
		}
	}
}
test_rot();


// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
