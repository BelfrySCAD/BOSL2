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


module test_line_normal() {
	assert(line_normal([0,0],[10,0]) == [0,1]);
	assert(line_normal([0,0],[0,10]) == [-1,0]);
	assert(line_normal([0,0],[-10,0]) == [0,-1]);
	assert(line_normal([0,0],[0,-10]) == [1,0]);
	assert(approx(line_normal([0,0],[10,10]), [-sqrt(2)/2,sqrt(2)/2]));
	assert(line_normal([[0,0],[10,0]]) == [0,1]);
	assert(line_normal([[0,0],[0,10]]) == [-1,0]);
	assert(line_normal([[0,0],[-10,0]]) == [0,-1]);
	assert(line_normal([[0,0],[0,-10]]) == [1,0]);
	assert(approx(line_normal([[0,0],[10,10]]), [-sqrt(2)/2,sqrt(2)/2]));
	pts = [for (i=list_range(1000)) rands(-100,100,2,seed_value=4312)];
	for (p = pair_wrap(pts)) {
		p1 = p.x;
		p2 = p.y;
		n = normalize(p2-p1);
		n1 = [-n.y, n.x];
		n2 = line_normal(p1,p2);
		assert(approx(n2, n1));
	}
}
test_line_normal();


module test_line_intersection() {
	assert(line_intersection([[-10,-10], [ -1,-10]], [[ 10,-10], [  1,-10]]) == undef);
	assert(line_intersection([[-10,  0], [ -1,  0]], [[ 10,  0], [  1,  0]]) == undef);
	assert(line_intersection([[-10,  0], [ -1,  0]], [[  1,  0], [ 10,  0]]) == undef);
	assert(line_intersection([[-10,  0], [ 10,  0]], [[-10,  0], [ 10,  0]]) == undef);
	assert(line_intersection([[-10, 10], [ 10, 10]], [[-10,-10], [ 10,-10]]) == undef);
	assert(line_intersection([[-10,-10], [ -1, -1]], [[ 10,-10], [  1, -1]]) == [0,0]);
	assert(line_intersection([[-10,-10], [ 10, 10]], [[ 10,-10], [-10, 10]]) == [0,0]);
	assert(line_intersection([[ -8,  0], [ 12,  4]], [[ 12,  0], [ -8,  4]]) == [2,2]);
}
test_line_intersection();


module test_segment_intersection() {
	assert(segment_intersection([[-10,-10], [ -1, -1]], [[ 10,-10], [  1, -1]]) == undef);
	assert(segment_intersection([[-10,-10], [ -1,-10]], [[ 10,-10], [  1,-10]]) == undef);
	assert(segment_intersection([[-10,  0], [ -1,  0]], [[ 10,  0], [  1,  0]]) == undef);
	assert(segment_intersection([[-10,  0], [ -1,  0]], [[  1,  0], [ 10,  0]]) == undef);
	assert(segment_intersection([[-10, 10], [ -1,  1]], [[ 10, 10], [  1,  1]]) == undef);
	assert(segment_intersection([[-10,  0], [ 10,  0]], [[-10,  0], [ 10,  0]]) == undef);
	assert(segment_intersection([[-10, 10], [ 10, 10]], [[-10,-10], [ 10,-10]]) == undef);
	assert(segment_intersection([[-10,  0], [  0, 10]], [[  0, 10], [ 10,  0]]) == [0,10]);
	assert(segment_intersection([[-10,  0], [  0, 10]], [[-10, 20], [ 10,  0]]) == [0,10]);
	assert(segment_intersection([[-10,-10], [ 10, 10]], [[ 10,-10], [-10, 10]]) == [0,0]);
	assert(segment_intersection([[ -8,  0], [ 12,  4]], [[ 12,  0], [ -8,  4]]) == [2,2]);
}
test_segment_intersection();


module test_line_segment_intersection() {
	assert(line_segment_intersection([[-10,-10], [ -1,-10]], [[ 10,-10], [  1,-10]]) == undef);
	assert(line_segment_intersection([[-10,  0], [ -1,  0]], [[ 10,  0], [  1,  0]]) == undef);
	assert(line_segment_intersection([[-10,  0], [ -1,  0]], [[  1,  0], [ 10,  0]]) == undef);
	assert(line_segment_intersection([[-10,  0], [ 10,  0]], [[-10,  0], [ 10,  0]]) == undef);
	assert(line_segment_intersection([[-10, 10], [ 10, 10]], [[-10,-10], [ 10,-10]]) == undef);
	assert(line_segment_intersection([[-10,-10], [ -1, -1]], [[ 10,-10], [  1, -1]]) == undef);
	assert(line_segment_intersection([[-10,-10], [ 10, 10]], [[ 10,-10], [-10, 10]]) == [0,0]);
	assert(line_segment_intersection([[ -8,  0], [ 12,  4]], [[ 12,  0], [ -8,  4]]) == [2,2]);
	assert(line_segment_intersection([[-10,-10], [ 10, 10]], [[ 10,-10], [  1, -1]]) == undef);
	assert(line_segment_intersection([[-10,-10], [ 10, 10]], [[ 10,-10], [ -1,  1]]) == [0,0]);
}
test_line_segment_intersection();


module test_line_closest_point() {
	assert(approx(line_closest_point([[-10,-10], [10,10]], [1,-1]), [0,0]));
	assert(approx(line_closest_point([[-10,-10], [10,10]], [-1,1]), [0,0]));
	assert(approx(line_closest_point([[-10,-20], [10,20]], [1,2]+[-2,1]), [1,2]));
	assert(approx(line_closest_point([[-10,-20], [10,20]], [1,2]+[2,-1]), [1,2]));
	assert(approx(line_closest_point([[-10,-20], [10,20]], [13,31]), [15,30]));
}
test_line_closest_point();


module test_segment_closest_point() {
	assert(approx(segment_closest_point([[-10,-10], [10,10]], [1,-1]), [0,0]));
	assert(approx(segment_closest_point([[-10,-10], [10,10]], [-1,1]), [0,0]));
	assert(approx(segment_closest_point([[-10,-20], [10,20]], [1,2]+[-2,1]), [1,2]));
	assert(approx(segment_closest_point([[-10,-20], [10,20]], [1,2]+[2,-1]), [1,2]));
	assert(approx(segment_closest_point([[-10,-20], [10,20]], [13,31]), [10,20]));
	assert(approx(segment_closest_point([[-10,-20], [10,20]], [15,25]), [10,20]));
}
test_segment_closest_point();


module test_find_circle_2tangents() {
	assert(approx(find_circle_2tangents([10,10],[0,0],[10,-10],r=10/sqrt(2))[0],[10,0]));
	assert(approx(find_circle_2tangents([-10,10],[0,0],[-10,-10],r=10/sqrt(2))[0],[-10,0]));
	assert(approx(find_circle_2tangents([-10,10],[0,0],[10,10],r=10/sqrt(2))[0],[0,10]));
	assert(approx(find_circle_2tangents([-10,-10],[0,0],[10,-10],r=10/sqrt(2))[0],[0,-10]));
	assert(approx(find_circle_2tangents([0,10],[0,0],[10,0],r=10)[0],[10,10]));
	assert(approx(find_circle_2tangents([10,0],[0,0],[0,-10],r=10)[0],[10,-10]));
	assert(approx(find_circle_2tangents([0,-10],[0,0],[-10,0],r=10)[0],[-10,-10]));
	assert(approx(find_circle_2tangents([-10,0],[0,0],[0,10],r=10)[0],[-10,10]));
	assert(approx(find_circle_2tangents(polar_to_xy(10,60),[0,0],[10,0],r=10)[0],polar_to_xy(20,30)));
}
test_find_circle_2tangents();


module test_find_circle_3points() {
	count = 200;
	coords = rands(-100,100,count,seed_value=888);
	radii = rands(10,100,count,seed_value=390);
	angles = rands(0,360,count,seed_value=699);
	// 2D tests.
	for(i = list_range(count)) {
		cp = select(coords,i,i+1);
		r = radii[i];
		angs = sort(select(angles,i,i+2));
		pts = [for (a=angs) cp+polar_to_xy(r,a)];
		res = find_circle_3points(pts);
		if (!approx(res[0], cp)) {
			echo(cp=cp, r=r, angs=angs);
			echo(pts=pts);
			echo(got=res[0], expected=cp, delta=res[0]-cp);
			assert(approx(res[0], cp));
		}
		if (!approx(res[1], r)) {
			echo(cp=cp, r=r, angs=angs);
			echo(pts=pts);
			echo(got=res[1], expected=r, delta=res[1]-r);
			assert(approx(res[1], r));
		}
		if (!approx(res[2], UP)) {
			echo(cp=cp, r=r, angs=angs);
			echo(pts=pts);
			echo(got=res[2], expected=UP, delta=res[2]-UP);
			assert(approx(res[2], UP));
		}
	}
	for(i = list_range(count)) {
		cp = select(coords,i,i+1);
		r = radii[i];
		angs = sort(select(angles,i,i+2));
		pts = [for (a=angs) cp+polar_to_xy(r,a)];
		res = find_circle_3points(pts[0], pts[1], pts[2]);
		if (!approx(res[0], cp)) {
			echo(cp=cp, r=r, angs=angs);
			echo(pts=pts);
			echo(got=res[0], expected=cp, delta=res[0]-cp);
			assert(approx(res[0], cp));
		}
		if (!approx(res[1], r)) {
			echo(cp=cp, r=r, angs=angs);
			echo(pts=pts);
			echo(got=res[1], expected=r, delta=res[1]-r);
			assert(approx(res[1], r));
		}
		if (!approx(res[2], UP)) {
			echo(cp=cp, r=r, angs=angs);
			echo(pts=pts);
			echo(got=res[2], expected=UP, delta=res[2]-UP);
			assert(approx(res[2], UP));
		}
	}
	// 3D tests.
	for(i = list_range(count)) {
		cp = select(coords,i,i+2);
		r = radii[i];
		nrm = normalize(select(coords,i+10,i+12));
		n = nrm.z<0? -nrm : nrm;
		angs = sort(select(angles,i,i+2));
		pts = translate(cp,p=rot(from=UP,to=n,p=[for (a=angs) point3d(polar_to_xy(r,a))]));
		res = find_circle_3points(pts);
		if (!approx(res[0], cp)) {
			echo(cp=cp, r=r, angs=angs, n=n);
			echo(pts=pts);
			echo("CP:", got=res[0], expected=cp, delta=res[0]-cp);
			assert(approx(res[0], cp));
		}
		if (!approx(res[1], r)) {
			echo(cp=cp, r=r, angs=angs, n=n);
			echo(pts=pts);
			echo("R:", got=res[1], expected=r, delta=res[1]-r);
			assert(approx(res[1], r));
		}
		if (!approx(res[2], n)) {
			echo(cp=cp, r=r, angs=angs, n=n);
			echo(pts=pts);
			echo("NORMAL:", got=res[2], expected=n, delta=res[2]-n);
			assert(approx(res[2], n));
		}
	}
	for(i = list_range(count)) {
		cp = select(coords,i,i+2);
		r = radii[i];
		nrm = normalize(select(coords,i+10,i+12));
		n = nrm.z<0? -nrm : nrm;
		angs = sort(select(angles,i,i+2));
		pts = translate(cp,p=rot(from=UP,to=n,p=[for (a=angs) point3d(polar_to_xy(r,a))]));
		res = find_circle_3points(pts[0], pts[1], pts[2]);
		if (!approx(res[0], cp)) {
			echo(cp=cp, r=r, angs=angs, n=n);
			echo(pts=pts);
			echo("CENTER:", got=res[0], expected=cp, delta=res[0]-cp);
			assert(approx(res[0], cp));
		}
		if (!approx(res[1], r)) {
			echo(cp=cp, r=r, angs=angs, n=n);
			echo(pts=pts);
			echo("RADIUS:", got=res[1], expected=r, delta=res[1]-r);
			assert(approx(res[1], r));
		}
		if (!approx(res[2], n)) {
			echo(cp=cp, r=r, angs=angs, n=n);
			echo(pts=pts);
			echo("NORMAL:", got=res[2], expected=n, delta=res[2]-n);
			assert(approx(res[2], n));
		}
	}
}
test_find_circle_3points();


module test_find_circle_tangents() {
	tangs = find_circle_tangents(r=50,cp=[0,0],pt=[50*sqrt(2),0]);
	assert(approx(subindex(tangs,0), [45,-45]));
	expected = [for (ang=subindex(tangs,0)) polar_to_xy(50,ang)];
	got = subindex(tangs,1);
	if (!approx(flatten(got), flatten(expected))) {
		echo("TAN_PTS:", got=got, expected=expected, delta=got-expected);
		assert(approx(flatten(got), flatten(expected)));
	}
}
test_find_circle_tangents();


module test_tri_calc() {
	sides = rands(1,100,100,seed_value=8888);
	for (p=pair_wrap(sides)) {
		opp = p[0];
		adj = p[1];
		hyp = norm([opp,adj]);
		ang = acos(adj/hyp);
		ang2 = 90-ang;
		expected = [adj, opp, hyp, ang, ang2];
		assert(approx(tri_calc(adj=adj, hyp=hyp), expected));
		assert(approx(tri_calc(opp=opp, hyp=hyp), expected));
		assert(approx(tri_calc(adj=adj, opp=opp), expected));
		assert(approx(tri_calc(adj=adj, ang=ang), expected));
		assert(approx(tri_calc(opp=opp, ang=ang), expected, eps=1e-8));
		assert(approx(tri_calc(hyp=hyp, ang=ang), expected));
		assert(approx(tri_calc(adj=adj, ang2=ang2), expected));
		assert(approx(tri_calc(opp=opp, ang2=ang2), expected, eps=1e-8));
		assert(approx(tri_calc(hyp=hyp, ang2=ang2), expected));
	}
}
test_tri_calc();


// Dummy modules to show up in coverage check script.
module test_hyp_opp_to_adj();
module test_hyp_ang_to_adj();
module test_opp_ang_to_adj();
module test_hyp_adj_to_opp();
module test_hyp_ang_to_opp();
module test_adj_ang_to_opp();
module test_adj_opp_to_hyp();
module test_adj_ang_to_hyp();
module test_opp_ang_to_hyp();
module test_hyp_adj_to_ang();
module test_hyp_opp_to_ang();
module test_adj_opp_to_ang();

module test_tri_functions() {
	sides = rands(1,100,100,seed_value=8181);
	for (p = pair_wrap(sides)) {
		adj = p.x;
		opp = p.y;
		hyp = norm([opp,adj]);
		ang = atan2(opp,adj);
		assert(approx(hyp_opp_to_adj(hyp,opp),adj));
		assert(approx(hyp_ang_to_adj(hyp,ang),adj));
		assert(approx(opp_ang_to_adj(opp,ang),adj));
		assert(approx(hyp_adj_to_opp(hyp,adj),opp));
		assert(approx(hyp_ang_to_opp(hyp,ang),opp));
		assert(approx(adj_ang_to_opp(adj,ang),opp));
		assert(approx(adj_opp_to_hyp(adj,opp),hyp));
		assert(approx(adj_ang_to_hyp(adj,ang),hyp));
		assert(approx(opp_ang_to_hyp(opp,ang),hyp));
		assert(approx(hyp_adj_to_ang(hyp,adj),ang));
		assert(approx(hyp_opp_to_ang(hyp,opp),ang));
		assert(approx(adj_opp_to_ang(adj,opp),ang));
	}
}
test_tri_functions();


module test_triangle_area() {
	assert(abs(triangle_area([0,0], [0,10], [10,0]) + 50) < EPSILON);
	assert(abs(triangle_area([0,0], [0,10], [0,15])) < EPSILON);
	assert(abs(triangle_area([0,0], [10,0], [0,10]) - 50) < EPSILON);
}
test_triangle_area();


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
	pts = [ [0,0,0], [10,0,0], [0,10,0], [0,0,10] ];
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


module test_plane_from_pointslist() {
	assert(plane_from_pointslist([[0,0,20], [0,10,10], [0,0,0], [0,5,3]]) == [1,0,0,0]);
	assert(plane_from_pointslist([[2,0,20], [2,10,10], [2,0,0], [2,3,4]]) == [1,0,0,2]);
	assert(plane_from_pointslist([[0,0,0], [10,0,10], [0,0,20], [5,0,7]]) == [0,1,0,0]);
	assert(plane_from_pointslist([[0,2,0], [10,2,10], [0,2,20], [4,2,3]]) == [0,1,0,2]);
	assert(plane_from_pointslist([[0,0,0], [10,10,0], [20,0,0], [8,3,0]]) == [0,0,1,0]);
	assert(plane_from_pointslist([[0,0,2], [10,10,2], [20,0,2], [3,4,2]]) == [0,0,1,2]);
}
test_plane_from_pointslist();


module test_plane_normal() {
	assert(plane_normal(plane3pt([0,0,20], [0,10,10], [0,0,0])) == [1,0,0]);
	assert(plane_normal(plane3pt([2,0,20], [2,10,10], [2,0,0])) == [1,0,0]);
	assert(plane_normal(plane3pt([0,0,0], [10,0,10], [0,0,20])) == [0,1,0]);
	assert(plane_normal(plane3pt([0,2,0], [10,2,10], [0,2,20])) == [0,1,0]);
	assert(plane_normal(plane3pt([0,0,0], [10,10,0], [20,0,0])) == [0,0,1]);
	assert(plane_normal(plane3pt([0,0,2], [10,10,2], [20,0,2])) == [0,0,1]);
}
test_plane_normal();


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


module test_is_path() {
	assert(!is_path(123));
	assert(!is_path("foo"));
	assert(!is_path(true));
	assert(!is_path([]));
	assert(!is_path([[]]));
	assert(!is_path([["foo","bar","baz"]]));
	assert(!is_path([[1,2,3]]));
	assert(!is_path([["foo","bar","baz"],["qux","quux","quuux"]]));
	assert(is_path([[1,2,3],[4,5,6]]));
	assert(is_path([[1,2,3],[4,5,6],[7,8,9]]));
}
test_is_path();


module test_is_closed_path() {
	assert(!is_closed_path([[1,2,3],[4,5,6],[1,8,9]]));
	assert(is_closed_path([[1,2,3],[4,5,6],[1,8,9],[1,2,3]]));
}
test_is_closed_path();


module test_close_path() {
	assert(close_path([[1,2,3],[4,5,6],[1,8,9]]) == [[1,2,3],[4,5,6],[1,8,9],[1,2,3]]);
	assert(close_path([[1,2,3],[4,5,6],[1,8,9],[1,2,3]]) == [[1,2,3],[4,5,6],[1,8,9],[1,2,3]]);
}
test_close_path();


module test_cleanup_path() {
	assert(cleanup_path([[1,2,3],[4,5,6],[1,8,9]]) == [[1,2,3],[4,5,6],[1,8,9]]);
	assert(cleanup_path([[1,2,3],[4,5,6],[1,8,9],[1,2,3]]) == [[1,2,3],[4,5,6],[1,8,9]]);
}
test_cleanup_path();


// TODO: test path_self_intersections()
// TODO: test decompose_path()
// TODO: test path_subselect()


module test_polygon_area() {
	assert(approx(polygon_area([[1,1],[-1,1],[-1,-1],[1,-1]]), 4));
	assert(approx(polygon_area(circle(r=50,$fn=1000)), -PI*50*50, eps=0.1));
}
test_polygon_area();


module test_polygon_shift() {
	path = [[1,1],[-1,1],[-1,-1],[1,-1]];
	assert(polygon_shift(path,1) == [[-1,1],[-1,-1],[1,-1],[1,1]]);
	assert(polygon_shift(path,2) == [[-1,-1],[1,-1],[1,1],[-1,1]]);
}
test_polygon_shift();


module test_polygon_shift_to_closest_point() {
	path = [[1,1],[-1,1],[-1,-1],[1,-1]];
	assert(polygon_shift_to_closest_point(path,[1.1,1.1]) == [[1,1],[-1,1],[-1,-1],[1,-1]]);
	assert(polygon_shift_to_closest_point(path,[-1.1,1.1]) == [[-1,1],[-1,-1],[1,-1],[1,1]]);
	assert(polygon_shift_to_closest_point(path,[-1.1,-1.1]) == [[-1,-1],[1,-1],[1,1],[-1,1]]);
	assert(polygon_shift_to_closest_point(path,[1.1,-1.1]) == [[1,-1],[1,1],[-1,1],[-1,-1]]);
}
test_polygon_shift_to_closest_point();


module test_first_noncollinear(){
	pts = [
		[1,1], [2,2], [3,3], [4,4], [4,5], [5,6]
	];
	assert(first_noncollinear(0,1,pts) == 4);
	assert(first_noncollinear(1,0,pts) == 4);
	assert(first_noncollinear(0,2,pts) == 4);
	assert(first_noncollinear(2,0,pts) == 4);
	assert(first_noncollinear(1,2,pts) == 4);
	assert(first_noncollinear(2,1,pts) == 4);
	assert(first_noncollinear(0,3,pts) == 4);
	assert(first_noncollinear(3,0,pts) == 4);
	assert(first_noncollinear(1,3,pts) == 4);
	assert(first_noncollinear(3,1,pts) == 4);
	assert(first_noncollinear(2,3,pts) == 4);
	assert(first_noncollinear(3,2,pts) == 4);
	assert(first_noncollinear(0,4,pts) == 1);
	assert(first_noncollinear(4,0,pts) == 1);
	assert(first_noncollinear(1,4,pts) == 0);
	assert(first_noncollinear(4,1,pts) == 0);
	assert(first_noncollinear(2,4,pts) == 0);
	assert(first_noncollinear(4,2,pts) == 0);
	assert(first_noncollinear(3,4,pts) == 0);
	assert(first_noncollinear(4,3,pts) == 0);
	assert(first_noncollinear(0,5,pts) == 1);
	assert(first_noncollinear(5,0,pts) == 1);
	assert(first_noncollinear(1,5,pts) == 0);
	assert(first_noncollinear(5,1,pts) == 0);
	assert(first_noncollinear(2,5,pts) == 0);
	assert(first_noncollinear(5,2,pts) == 0);
	assert(first_noncollinear(3,5,pts) == 0);
	assert(first_noncollinear(5,3,pts) == 0);
	assert(first_noncollinear(4,5,pts) == 0);
	assert(first_noncollinear(5,4,pts) == 0);
}
test_first_noncollinear();


module test_find_noncollinear_points() {
	assert(find_noncollinear_points([[1,1],[2,2],[3,3],[4,4],[4,5],[5,6]]) == [0,5,3]);
	assert(find_noncollinear_points([[1,1],[2,2],[8,3],[4,4],[4,5],[5,6]]) == [0,2,5]);
}
test_find_noncollinear_points();


// TODO: test centroid()
// TODO: test assemble_a_path_from_fragments()
// TODO: test assemble_path_fragments()


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


module test_closest_point() {
	ptlist = [for (i=list_range(100)) rands(-100,100,2,seed_value=8463)];
	testpts = [for (i=list_range(100)) rands(-100,100,2,seed_value=6834)];
	for (pt = testpts) {
		pidx = closest_point(pt,ptlist);
		dists = [for (p=ptlist) norm(pt-p)];
		mindist = min(dists);
		assert(mindist == dists[pidx]);
	}
}
test_closest_point();


module test_furthest_point() {
	ptlist = [for (i=list_range(100)) rands(-100,100,2,seed_value=8463)];
	testpts = [for (i=list_range(100)) rands(-100,100,2,seed_value=6834)];
	for (pt = testpts) {
		pidx = furthest_point(pt,ptlist);
		dists = [for (p=ptlist) norm(pt-p)];
		mindist = max(dists);
		assert(mindist == dists[pidx]);
	}
}
test_furthest_point();


module test_polygon_is_clockwise() {
	assert(polygon_is_clockwise([[-1,1],[1,1],[1,-1],[-1,-1]]));
	assert(!polygon_is_clockwise([[1,1],[-1,1],[-1,-1],[1,-1]]));
	assert(polygon_is_clockwise(circle(d=100)));
	assert(polygon_is_clockwise(square(100)));
}
test_polygon_is_clockwise();


module test_clockwise_polygon() {
	path = circle(d=100);
	rpath = concat([path[0]], reverse(select(path,1,-1)));
	assert(clockwise_polygon(path) == path);
	assert(clockwise_polygon(rpath) == path);
}
test_clockwise_polygon();


module test_ccw_polygon() {
	path = circle(d=100);
	rpath = concat([path[0]], reverse(select(path,1,-1)));
	assert(ccw_polygon(path) == rpath);
	assert(ccw_polygon(rpath) == rpath);
}
test_ccw_polygon();


module test_reverse_polygon() {
	path = circle(d=100);
	rpath = concat([path[0]], reverse(select(path,1,-1)));
	assert(reverse_polygon(path) == rpath);
	assert(reverse_polygon(rpath) == path);
}
test_reverse_polygon();


module test_is_region() {
	assert(is_region([circle(d=10),square(10)]));
	assert(is_region([circle(d=10),square(10),circle(d=50)]));
	assert(is_region([square(10)]));
	assert(!is_region([]));
	assert(!is_region(23));
	assert(!is_region(true));
	assert(!is_region("foo"));
}
test_is_region();


// TODO: test check_and_fix_path()
// TODO: test cleanup_region()
// TODO: test point_in_region()
// TODO: test region_path_crossings()
// TODO: test offset()
// TODO: test split_path_at_self_crossings()
// TODO: test split_path_at_region_crossings()
// TODO: test union()
// TODO: test difference()
// TODO: test intersection()
// TODO: test exclusive_or()


cube();  // Prevents warning about no top-level geometry.


// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
