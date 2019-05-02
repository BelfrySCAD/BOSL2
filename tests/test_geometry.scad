include <BOSL2/std.scad>


module test_point_on_segment2d() {
	assert(point_on_segment2d([-15,0], [[-10,0], [10,0]]) == false);
	assert(point_on_segment2d([-10,0], [[-10,0], [10,0]]) == true);
	assert(point_on_segment2d([-5,0], [[-10,0], [10,0]]) == true);
	assert(point_on_segment2d([0,0], [[-10,0], [10,0]]) == true);
	assert(point_on_segment2d([3,3], [[-10,0], [10,0]]) == false);
	assert(point_on_segment2d([5,0], [[-10,0], [10,0]]) == true);
	assert(point_on_segment2d([10,0], [[-10,0], [10,0]]) == true);
	assert(point_on_segment2d([15,0], [[-10,0], [10,0]]) == false);

	assert(point_on_segment2d([0,-15], [[0,-10], [0,10]]) == false);
	assert(point_on_segment2d([0,-10], [[0,-10], [0,10]]) == true);
	assert(point_on_segment2d([0, -5], [[0,-10], [0,10]]) == true);
	assert(point_on_segment2d([0,  0], [[0,-10], [0,10]]) == true);
	assert(point_on_segment2d([3,  3], [[0,-10], [0,10]]) == false);
	assert(point_on_segment2d([0,  5], [[0,-10], [0,10]]) == true);
	assert(point_on_segment2d([0, 10], [[0,-10], [0,10]]) == true);
	assert(point_on_segment2d([0, 15], [[0,-10], [0,10]]) == false);

	assert(point_on_segment2d([-15,-15], [[-10,-10], [10,10]]) == false);
	assert(point_on_segment2d([-10,-10], [[-10,-10], [10,10]]) == true);
	assert(point_on_segment2d([ -5, -5], [[-10,-10], [10,10]]) == true);
	assert(point_on_segment2d([  0,  0], [[-10,-10], [10,10]]) == true);
	assert(point_on_segment2d([  0,  3], [[-10,-10], [10,10]]) == false);
	assert(point_on_segment2d([  5,  5], [[-10,-10], [10,10]]) == true);
	assert(point_on_segment2d([ 10, 10], [[-10,-10], [10,10]]) == true);
	assert(point_on_segment2d([ 15, 15], [[-10,-10], [10,10]]) == false);
}
test_point_on_segment2d();


module test_point_left_of_segment() {
	assert(point_left_of_segment2d([ -3,  0], [[-10,-10], [10,10]]) > 0);
	assert(point_left_of_segment2d([  0,  0], [[-10,-10], [10,10]]) == 0);
	assert(point_left_of_segment2d([  3,  0], [[-10,-10], [10,10]]) < 0);
}
test_point_left_of_segment();


module test_right_of_line2d() {
	assert(right_of_line2d([[-10,-10], [10,10]], [ -3,  0]) == false);
	assert(right_of_line2d([[-10,-10], [10,10]], [  0,  0]) == false);
	assert(right_of_line2d([[-10,-10], [10,10]], [  3,  0]) == true);
}
test_right_of_line2d();


module test_collinear() {
	assert(collinear([-10,-10], [-15, -16], [10,10]) == false);
	assert(collinear([-10,-10], [-15, -15], [10,10]) == true);
	assert(collinear([-10,-10], [ -3,   0], [10,10]) == false);
	assert(collinear([-10,-10], [  0,   0], [10,10]) == true);
	assert(collinear([-10,-10], [  3,   0], [10,10]) == false);
	assert(collinear([-10,-10], [ 15,  15], [10,10]) == true);
	assert(collinear([-10,-10], [ 15,  16], [10,10]) == false);
}
test_collinear();


module test_collinear_indexed() {
	pts = [
		[-20,-20], [-10,-20], [0,-10], [10,0], [20,10], [20,20], [15,30]
	];
	assert(collinear_indexed(pts, 0,1,2) == false);
	assert(collinear_indexed(pts, 1,2,3) == true);
	assert(collinear_indexed(pts, 2,3,4) == true);
	assert(collinear_indexed(pts, 3,4,5) == false);
	assert(collinear_indexed(pts, 4,5,6) == false);
	assert(collinear_indexed(pts, 4,3,2) == true);
	assert(collinear_indexed(pts, 0,5,6) == false);
}
test_collinear_indexed();


module test_distance_from_line() {
	assert(abs(distance_from_line([[-10,-10,-10], [10,10,10]], [1,1,1])) < EPSILON);
	assert(abs(distance_from_line([[-10,-10,-10], [10,10,10]], [-1,-1,-1])) < EPSILON);
	assert(abs(distance_from_line([[-10,-10,-10], [10,10,10]], [1,-1,0]) - sqrt(2)) < EPSILON);
	assert(abs(distance_from_line([[-10,-10,-10], [10,10,10]], [8,-8,0]) - 8*sqrt(2)) < EPSILON);
}
test_distance_from_line();


module test_triangle_area2d() {
	assert(abs(triangle_area2d([0,0], [0,10], [10,0]) + 50) < EPSILON);
	assert(abs(triangle_area2d([0,0], [0,10], [0,15])) < EPSILON);
	assert(abs(triangle_area2d([0,0], [10,0], [0,10]) - 50) < EPSILON);
}
test_triangle_area2d();


module test_plane3pt() {
	assert(plane3pt([0,0,20], [0,10,10], [0,0,0]) == [1,0,0,0]);
	assert(plane3pt([2,0,20], [2,10,10], [2,0,0]) == [1,0,0,2]);
	assert(plane3pt([0,0,0], [10,0,10], [0,0,20]) == [0,1,0,0]);
	assert(plane3pt([0,2,0], [10,2,10], [0,2,20]) == [0,1,0,2]);
	assert(plane3pt([0,0,0], [10,10,0], [20,0,0]) == [0,0,1,0]);
	assert(plane3pt([0,0,2], [10,10,2], [20,0,2]) == [0,0,1,2]);
}
test_plane3pt();


module test_plane3pt_indexed() {
	pts = [
		[0,0,0], [10,0,0], [0,10,0], [0,0,10]
	];
	s13 = sqrt(1/3);
	assert(plane3pt_indexed(pts, 0,3,2) == [1,0,0,0]);
	assert(plane3pt_indexed(pts, 0,2,3) == [-1,0,0,0]);
	assert(plane3pt_indexed(pts, 0,1,3) == [0,1,0,0]);
	assert(plane3pt_indexed(pts, 0,3,1) == [0,-1,0,0]);
	assert(plane3pt_indexed(pts, 0,2,1) == [0,0,1,0]);
	assert(plane3pt_indexed(pts, 0,1,2) == [0,0,-1,0]);
	assert(plane3pt_indexed(pts, 3,2,1) == [s13,s13,s13,10*s13]);
	assert(plane3pt_indexed(pts, 1,2,3) == [-s13,-s13,-s13,-10*s13]);
}
test_plane3pt_indexed();


module test_distance_from_plane() {
	plane1 = plane3pt([-10,0,0], [0,10,0], [10,0,0]);
	assert(distance_from_plane(plane1, [0,0,5]) == 5);
	assert(distance_from_plane(plane1, [5,5,8]) == 8);
}
test_distance_from_plane();


module test_coplanar() {
	plane = plane3pt([0,0,0], [0,10,10], [10,0,10]);
	assert(coplanar(plane, [5,5,10]) == true);
	assert(coplanar(plane, [10/3,10/3,20/3]) == true);
	assert(coplanar(plane, [0,0,0]) == true);
	assert(coplanar(plane, [1,1,0]) == false);
	assert(coplanar(plane, [-1,1,0]) == true);
	assert(coplanar(plane, [1,-1,0]) == true);
	assert(coplanar(plane, [5,5,5]) == false);
}
test_coplanar();


module test_in_front_of_plane() {
	plane = plane3pt([0,0,0], [0,10,10], [10,0,10]);
	assert(in_front_of_plane(plane, [5,5,10]) == false);
	assert(in_front_of_plane(plane, [-5,0,0]) == true);
	assert(in_front_of_plane(plane, [5,0,0]) == false);
	assert(in_front_of_plane(plane, [0,-5,0]) == true);
	assert(in_front_of_plane(plane, [0,5,0]) == false);
	assert(in_front_of_plane(plane, [0,0,5]) == true);
	assert(in_front_of_plane(plane, [0,0,-5]) == false);
}
test_in_front_of_plane();


module test_simplify_path() {
    path = [[-20,-20], [-10,-20], [0,-10], [10,0], [20,10], [20,20], [15,30]];
	assert(simplify_path(path) == [[-20,-20], [-10,-20], [20,10], [20,20], [15,30]]);
}
test_simplify_path();


module test_simplify_path_indexed() {
    pts = [[10,0], [0,-10], [20,20], [20,10], [-20,-20], [15,30], [-10,-20]];
    path = [4,6,1,0,3,2,5];
	assert(simplify_path_indexed(pts, path) == [4,6,3,2,5]);
}
test_simplify_path_indexed();


module test_point_in_polygon() {
	poly = [for (a=[0:30:359]) 10*[cos(a),sin(a)]];
	assert(point_in_polygon([0,0], poly) == 1);
	assert(point_in_polygon([20,0], poly) == -1);
	assert(point_in_polygon([5,5], poly) == 1);
	assert(point_in_polygon([-5,5], poly) == 1);
	assert(point_in_polygon([-5,-5], poly) == 1);
	assert(point_in_polygon([5,-5], poly) == 1);
	assert(point_in_polygon([-10,-10], poly) == -1);
	assert(point_in_polygon([10,0], poly) == 0);
	assert(point_in_polygon([0,10], poly) == 0);
	assert(point_in_polygon([0,-10], poly) == 0);
}
test_point_in_polygon();


module test_pointlist_bounds() {
	pts = [
		[-53,27,12],
		[-63,97,36],
		[84,-32,-5],
		[63,-24,42],
		[23,57,-42]
	];
	assert(pointlist_bounds(pts) == [[-63,-32,-42], [84,97,42]]);
}
test_pointlist_bounds();



// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
