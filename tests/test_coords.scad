include <BOSL2/std.scad>


module test_point2d() {
	assert(point2d([1,2,3])==[1,2]);
	assert(point2d([2,3])==[2,3]);
	assert(point2d([1])==[1,0]);
}
test_point2d();


module test_path2d() {
	assert(path2d([[1], [1,2], [1,2,3], [1,2,3,4], [1,2,3,4,5]])==[[1,0],[1,2],[1,2],[1,2],[1,2]]);
}
test_path2d();


module test_point3d() {
	assert(point3d([1,2,3,4,5])==[1,2,3]);
	assert(point3d([1,2,3,4])==[1,2,3]);
	assert(point3d([1,2,3])==[1,2,3]);
	assert(point3d([2,3])==[2,3,0]);
	assert(point3d([1])==[1,0,0]);
}
test_point3d();


module test_path3d() {
	assert(path3d([[1], [1,2], [1,2,3], [1,2,3,4], [1,2,3,4,5]])==[[1,0,0],[1,2,0],[1,2,3],[1,2,3],[1,2,3]]);
}
test_path3d();


module test_point4d() {
	assert(point4d([1,2,3,4,5])==[1,2,3,4]);
	assert(point4d([1,2,3,4])==[1,2,3,4]);
	assert(point4d([1,2,3])==[1,2,3,0]);
	assert(point4d([2,3])==[2,3,0,0]);
	assert(point4d([1])==[1,0,0,0]);
}
test_point4d();


module test_path4d() {
	assert(path4d([[1], [1,2], [1,2,3], [1,2,3,4], [1,2,3,4,5]])==[[1,0,0,0],[1,2,0,0],[1,2,3,0],[1,2,3,4],[1,2,3,4]]);
}
test_path4d();


module test_translate_points() {
	pts = [[0,0,1], [0,1,0], [1,0,0], [0,0,-1], [0,-1,0], [-1,0,0]];
	assert(translate_points(pts, v=[1,2,3]) == [[1,2,4], [1,3,3], [2,2,3], [1,2,2], [1,1,3], [0,2,3]]);
	assert(translate_points(pts, v=[-1,-2,-3]) == [[-1,-2,-2], [-1,-1,-3], [0,-2,-3], [-1,-2,-4], [-1,-3,-3], [-2,-2,-3]]);
	assert(translate_points(pts, v=[1,2]) == [[1,2,1], [1,3,0], [2,2,0], [1,2,-1], [1,1,0], [0,2,0]]);
	pts2 = [[0,1], [1,0], [0,-1], [-1,0]];
	assert(translate_points(pts2, v=[1,2]) == [[1,3], [2,2], [1,1], [0,2]]);
}
test_translate_points();


module test_scale_points() {
	pts = [[0,0,1], [0,1,0], [1,0,0], [0,0,-1], [0,-1,0], [-1,0,0]];
	assert(scale_points(pts, v=[2,3,4]) == [[0,0,4], [0,3,0], [2,0,0], [0,0,-4], [0,-3,0], [-2,0,0]]);
	assert(scale_points(pts, v=[-2,-3,-4]) == [[0,0,-4], [0,-3,0], [-2,0,0], [0,0,4], [0,3,0], [2,0,0]]);
	assert(scale_points(pts, v=[1,1,1]) == [[0,0,1], [0,1,0], [1,0,0], [0,0,-1], [0,-1,0], [-1,0,0]]);
	assert(scale_points(pts, v=[-1,-1,-1]) == [[0,0,-1], [0,-1,0], [-1,0,0], [0,0,1], [0,1,0], [1,0,0]]);
	pts2 = [[0,1], [1,0], [0,-1], [-1,0]];
	assert(scale_points(pts2, v=[2,3]) == [[0,3], [2,0], [0,-3], [-2,0]]);
}
test_scale_points();


module test_rotate_points2d() {
	pts = [[0,1], [1,0], [0,-1], [-1,0]];
	s = sin(45);
	assert(rotate_points2d(pts,45) == [[-s,s],[s,s],[s,-s],[-s,-s]]);
	assert(rotate_points2d(pts,90) == [[-1,0],[0,1],[1,0],[0,-1]]);
	assert(rotate_points2d(pts,90,cp=[1,0]) == [[0,-1],[1,0],[2,-1],[1,-2]]);
}
test_rotate_points2d();


module test_rotate_points3d() {
	pts = [[0,0,1], [0,1,0], [1,0,0], [0,0,-1], [0,-1,0], [-1,0,0]];
	assert(rotate_points3d(pts, [90,0,0]) == [[0,-1,0], [0,0,1], [1,0,0], [0,1,0], [0,0,-1], [-1,0,0]]);
	assert(rotate_points3d(pts, [0,90,0]) == [[1,0,0], [0,1,0], [0,0,-1], [-1,0,0], [0,-1,0], [0,0,1]]);
	assert(rotate_points3d(pts, [0,0,90]) == [[0,0,1], [-1,0,0], [0,1,0], [0,0,-1], [1,0,0], [0,-1,0]]);
	assert(rotate_points3d(pts, [0,0,90],cp=[2,0,0]) == [[2,-2,1], [1,-2,0], [2,-1,0], [2,-2,-1], [3,-2,0], [2,-3,0]]);
	assert(rotate_points3d(pts, 90, v=UP) == [[0,0,1], [-1,0,0], [0,1,0], [0,0,-1], [1,0,0], [0,-1,0]]);
	assert(rotate_points3d(pts, 90, v=DOWN) == [[0,0,1], [1,0,0], [0,-1,0], [0,0,-1], [-1,0,0], [0,1,0]]);
	assert(rotate_points3d(pts, 90, v=RIGHT)  == [[0,-1,0], [0,0,1], [1,0,0], [0,1,0], [0,0,-1], [-1,0,0]]);
	assert(rotate_points3d(pts, from=UP, to=BACK) == [[0,1,0], [0,0,-1], [1,0,0], [0,-1,0], [0,0,1], [-1,0,0]]);
	assert(rotate_points3d(pts, 90, from=UP, to=BACK), [[0,1,0], [-1,0,0], [0,0,-1], [0,-1,0], [1,0,0], [0,0,1]]);
	assert(rotate_points3d(pts, from=UP, to=UP*2) == [[0,0,1], [0,1,0], [1,0,0], [0,0,-1], [0,-1,0], [-1,0,0]]);
	assert(rotate_points3d(pts, from=UP, to=DOWN*2) == [[0,0,-1], [0,1,0], [-1,0,0], [0,0,1], [0,-1,0], [1,0,0]]);
}
test_rotate_points3d();


module test_polar_to_xy() {
	assert(approx(polar_to_xy(20,45), [20/sqrt(2), 20/sqrt(2)]));
	assert(approx(polar_to_xy(20,135), [-20/sqrt(2), 20/sqrt(2)]));
	assert(approx(polar_to_xy(20,-135), [-20/sqrt(2), -20/sqrt(2)]));
	assert(approx(polar_to_xy(20,-45), [20/sqrt(2), -20/sqrt(2)]));
	assert(approx(polar_to_xy(40,30), [40*sqrt(3)/2, 40/2]));
	assert(approx(polar_to_xy([40,30]), [40*sqrt(3)/2, 40/2]));
}
test_polar_to_xy();


module test_xy_to_polar() {
	assert(approx(xy_to_polar([20/sqrt(2), 20/sqrt(2)]),[20,45]));
	assert(approx(xy_to_polar([-20/sqrt(2), 20/sqrt(2)]),[20,135]));
	assert(approx(xy_to_polar([-20/sqrt(2), -20/sqrt(2)]),[20,-135]));
	assert(approx(xy_to_polar([20/sqrt(2), -20/sqrt(2)]),[20,-45]));
	assert(approx(xy_to_polar([40*sqrt(3)/2, 40/2]),[40,30]));
	assert(approx(xy_to_polar([-40*sqrt(3)/2, 40/2]),[40,150]));
	assert(approx(xy_to_polar([-40*sqrt(3)/2, -40/2]),[40,-150]));
	assert(approx(xy_to_polar([40*sqrt(3)/2, -40/2]),[40,-30]));
}
test_xy_to_polar();


cube();


// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
