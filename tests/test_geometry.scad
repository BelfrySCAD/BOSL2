include <../std.scad>


//the commented lines are for tests to be written
//the tests are ordered as they appear in geometry.scad



test_is_point_on_line();
test_is_collinear();
test_point_line_distance();
test_segment_distance();
test_line_normal();
test_line_intersection();
//test_line_ray_intersection();   // should add this type of case
//test_ray_intersection();    // should add this type of case
//test_ray_segment_intersection();  // should add this type of case
test_line_closest_point();
//test_ray_closest_point();   // should add this type of case
test_line_from_points();
test_plane3pt();
test_plane3pt_indexed();
test_plane_from_normal();
test_plane_from_points();
test_plane_from_polygon();
test_plane_normal();
test_plane_offset();
test_plane_closest_point();
test_point_plane_distance();

test__general_plane_line_intersection();
test_plane_line_angle();
test_plane_line_intersection();
test_polygon_line_intersection();
test_plane_intersection();
test_is_coplanar();
test_are_points_on_plane();
test__is_point_above_plane();
test_circle_2tangents();
test_circle_3points();
test_circle_point_tangents();

test__noncollinear_triple();
test_polygon_area();
test_is_polygon_convex();
test_reindex_polygon();
test_align_polygon();
test_centroid();
test_point_in_polygon();
test_polygon_triangulate();
test_is_polygon_clockwise();
test_clockwise_polygon();
test_ccw_polygon();
test_reverse_polygon();

test_polygon_normal();
test_rot_decode();

//tests to migrate to other files
test_convex_distance();
test_convex_collision();

// to be used when there are two alternative symmetrical outcomes 
// from a function like a plane output; v must be a vector
function standardize(v) = 
    v==[]? [] :
    let( i = max_index([for(vi=v) abs(vi) ]),
         s = sign(v[i]) )
    v*s;


module assert_std(vc,ve,info) { assert_approx(standardize(vc),standardize(ve),info); }


function info_str(list,i=0,string=chr(10)) =
    assert(i>=len(list) || (is_list(list[i])&&len(list[i])>=2), "Invalid list for info_str." )
    i>=len(list)
    ? str(string)
    : info_str(list,i+1,str(string,str(list[i][0],_valstr(list[i][1]),chr(10))));


module test_polygon_triangulate() {
		poly0 = [ [0,0,1], [10,0,2], [10,10,0] ];
		poly1 = [ [-10,0,-10], [10,0,10], [0,10,0], [-10,0,-10], [-4,4,-4], [4,4,4], [0,2,0], [-4,4,-4] ];
		poly2 = [ [0,0], [5,5], [-5,5], [0,0], [-5,-5], [5,-5] ];
		poly3 = [ [0,0], [10,0], [10,10], [10,13], [10,10], [0,10], [0,0], [3,3], [7,3], [7,7], [7,3], [3,3] ];
		tris0 = (polygon_triangulate(poly0));
		assert(approx(tris0, [[0, 1, 2]]));
		tris1 = (polygon_triangulate(poly1));
		assert(approx(tris1,(  [[2, 3, 4], [6, 7, 0], [2, 4, 5], [6, 0, 1], [1, 2, 5], [5, 6, 1]])));
		tris2 = (polygon_triangulate(poly2));
		assert(approx(tris2,( [[3, 4, 5], [1, 2, 3]])));
		tris3 = (polygon_triangulate(poly3));
		assert(approx(tris3,( [[5, 6, 7], [11, 0, 1], [5, 7, 8], [10, 11, 1], [5, 8, 9], [10, 1, 2], [4, 5, 9], [9, 10, 2]])));
}

module test__normalize_plane(){
    plane = rands(-5,5,4,seed=333)+[10,0,0,0];
    plane2 = _normalize_plane(plane);
    assert_approx(norm(point3d(plane2)),1);
    assert_approx(plane*plane2[3],plane2*plane[3]);
}
test__normalize_plane();

module test_plane_line_intersection(){
    line = [rands(-1,1,3,seed=74),rands(-1,1,3,seed=99)+[2,0,0]];
    plane1 = plane_from_normal(line[1]-line[0],2*line[0]-line[1]); // plane disjoint from segment
    plane2 = plane_from_normal(line[1]-line[0],(line[0]+line[1])/2); // through middle point of line
    plane3 = plane3pt(line[1],line[0], rands(-1,1,3)+[0,3,0]); // containing line
    plane4 = plane3pt(line[1],line[0], rands(-1,1,3)+[0,3,0])+[0,0,0,1]; // parallel to line
    info1 = info_str([ ["line = ",line],["plane = ",plane1]]);
    assert_approx(plane_line_intersection(plane1, line),2*line[0]-line[1],info1);
    assert_approx(plane_line_intersection(plane1, line,[true,false]),undef,info1);
    assert_approx(plane_line_intersection(plane1, line,[false,true]),2*line[0]-line[1],info1);
    assert_approx(plane_line_intersection(plane1, line,[true, true]),undef,info1);
    info2 = info_str([ ["line = ",line],["plane = ",plane2]]);
    assert_approx(plane_line_intersection(plane2, line),(line[0]+line[1])/2,info2);
    assert_approx(plane_line_intersection(plane2, line,[true,false]),(line[0]+line[1])/2,info2);
    assert_approx(plane_line_intersection(plane2, line,[false,true]),(line[0]+line[1])/2,info2);
    assert_approx(plane_line_intersection(plane2, line,[true, true]),(line[0]+line[1])/2,info2);
    info3 = info_str([ ["line = ",line],["plane = ",plane3]]);
    assert_approx(plane_line_intersection(plane3, line),line,info3);
    assert_approx(plane_line_intersection(plane3, line,[true,false]),line,info3);
    assert_approx(plane_line_intersection(plane3, line,[false,true]),line,info3);
    assert_approx(plane_line_intersection(plane3, line,[true, true]),line,info3);
    info4 = info_str([ ["line = ",line],["plane = ",plane4]]);
    assert_approx(plane_line_intersection(plane4, line),undef,info4);
    assert_approx(plane_line_intersection(plane4, line,[true,false]),undef,info4);
    assert_approx(plane_line_intersection(plane4, line,[false,true]),undef,info4);
    assert_approx(plane_line_intersection(plane4, line,[true, true]),undef,info4);
}
*test_plane_line_intersection();


module test_plane_intersection(){
    line = [ rands(-1,1,3), rands(-1,1,3)+[2,0,0] ]; // a valid line
    pt0  = line[0]-[2,0,0];  // 2 points not on the line
    pt1  = line[1]-[0,2,0]; 
    plane01 = plane3pt(line[0],line[1],pt0);
    plane02 = plane3pt(line[0],line[1],pt1);
    plane03 = plane3pt(line[0],pt0,pt1);
    info = info_str([["plane1 = ",plane01],["plane2 = ",plane02],["plane3 = ",plane03]]);
    assert_approx(plane_intersection(plane01,plane02,plane03),line[0],info);
    assert_approx(plane_intersection(plane01,2*plane01),undef,info);
    lineInters = plane_intersection(plane01,plane02);
    assert_approx(line_closest_point(lineInters,line[0]), line[0], info);
    assert_approx(line_closest_point(lineInters,line[1]), line[1], info);
}
*test_plane_intersection();


module test_plane_offset(){
    plane = rands(-1,1,4)+[2,0,0,0]; // a valid plane
    info = info_str([["plane = ",plane]]);
    assert_approx(plane_offset(plane), _normalize_plane(plane)[3],info);
    assert_approx(plane_offset([1,1,1,1]), 1/sqrt(3),info);
}
*test_plane_offset();

module test_plane_from_polygon(){
    poly1 = [ rands(-1,1,3), rands(-1,1,3)+[2,0,0], rands(-1,1,3)+[0,2,2] ];
    poly2 = concat(poly1, [sum(poly1)/3] );
    info = info_str([["poly1 = ",poly1],["poly2 = ",poly2]]);
    assert_approx(plane_from_polygon(poly1),plane3pt(poly1[0],poly1[1],poly1[2]),info);
    assert_approx(plane_from_polygon(poly2),plane3pt(poly1[0],poly1[1],poly1[2]),info);
}
*test_plane_from_polygon();

module test_plane_from_normal(){
    normal = rands(-1,1,3)+[2,0,0];
    point = rands(-1,1,3);
    displ = normal*point;
    info = info_str([["normal = ",normal],["point = ",point],["displ = ",displ]]);
    assert_approx(plane_from_normal(normal,point)*[each point,-1],0,info);
    assert_approx(plane_from_normal([1,1,1],[1,2,3]),[0.57735026919,0.57735026919,0.57735026919,3.46410161514]);
}
*test_plane_from_normal();

module test_plane_line_angle() {
    angs = rands(0,360,3);
    displ = rands(-1,1,1)[0];
    info = info_str([["angs = ",angs],["displ = ",displ]]);
    assert_approx(plane_line_angle([each rot(angs,p=[0,0,1]),displ],[[0,0,0],rot(angs,p=[0,0,1])]),90,info);
    assert_approx(plane_line_angle([each rot(angs,p=[0,0,1]),displ],[[0,0,0],rot(angs,p=[0,1,1])]),45,info);
    assert_approx(plane_line_angle([each rot(angs,p=[0,0,1]),0],[[0,0,0],rot(angs,p=[1,1,1])]),35.2643896828);
}
*test_plane_line_angle();

module test__general_plane_line_intersection() {
    CRLF = chr(10);
    // general line
    plane1 = rands(-1,1,4)+[2,0,0,0]; // a random valid plane (normal!=0)
    line1  = [ rands(-1,1,3), rands(-1,1,3)+[2,0,0] ]; // a random valid line (line1[0]!=line1[1])
    inters1 = _general_plane_line_intersection(plane1, line1);
    info1 = info_str([["line = ",line1],["plane = ",plane1]]);
    if(inters1==undef) { // parallel to the plane ?
        assert_approx( point3d(plane1)*(line1[1]-line1[0]), 0, info1);
        assert( point3d(plane1)*line1[0]== plane1[3], info1); // not on the plane
    }
    if( inters1[1]==undef) { // on the plane ?
        assert_approx( point3d(plane1)*(line1[1]-line1[0]), 0, info1);
        assert_approx(point3d(plane1)*line1[0],plane1[3], info1) ;  // on the plane
    }
    else { 
        interspoint = line1[0]+inters1[1]*(line1[1]-line1[0]);
        assert_approx(inters1[0],interspoint, info1); 
        assert_approx(point3d(plane1)*inters1[0], plane1[3], info1); // interspoint on the plane
        assert_approx(point_plane_distance(plane1, inters1[0]), 0, info1); // inters1[0] on the plane
    }

    // line parallel to the plane
    line2  = [ rands(-1,1,3)+[0,2,0], rands(-1,1,3)+[2,0,0] ]; // a random valid line2
                                                                // not containing the origin
    plane0 = plane_from_points([line2[0], line2[1], [0,0,0]]);  // plane cointaining the line
    plane2  = plane_from_normal(plane_normal(plane0), [5,5,5]);
    inters2 = _general_plane_line_intersection(plane2, line2);
    info2 = info_str([["line = ",line2],["plane = ",plane2]]);
    assert(inters2==undef, info2);
 
    // line on the plane
    line3  = [ rands(-1,1,3), rands(-1,1,3)+[2,0,0] ]; // a random valid line
    imax  = max_index(line3[1]-line3[0]);
    w     = [for(j=[0:2]) imax==j? 0: 3 ];
    p3    = line3[0] + cross(line3[1]-line3[0],w); // a point not on the line
    plane3 = plane_from_points([line3[0], line3[1], p3]); // plane containing line
    inters3 = _general_plane_line_intersection(plane3, line3);
    info3 = info_str([["line = ",line3],["plane = ",plane3]]);
    assert(!is_undef(inters3) && inters3[1]==undef, info3);
    assert_approx(inters3[0], line3, info3);
}
*test__general_plane_line_intersection();


module test_are_points_on_plane() {
    pts     = [for(i=[0:40]) rands(-1,1,3) ];
    dir     = rands(-10,10,3);
    normal0 = [1,2,3];
    ang     = rands(0,360,1)[0];
    normal  = rot(a=ang,p=normal0);
    plane   = [each normal, normal*dir];
    prj_pts = plane_closest_point(plane,pts);
    info = info_str([["pts = ",pts],["dir = ",dir],["ang = ",ang]]);
    assert(are_points_on_plane(prj_pts,plane),info);
    assert(!are_points_on_plane(concat(pts,[normal-dir]),plane),info);
}
*test_are_points_on_plane();

module test_plane_closest_point(){
    ang     = rands(0,360,1)[0];
    dir     = rands(-10,10,3);
    normal0 = unit([1,2,3]);
    normal  = rot(a=ang,p=normal0);
    plane0  = [each normal0, 0];
    plane   = [each normal,  0];
    planem  = [each normal, normal*dir];
    pts     = [for(i=[1:10]) rands(-1,1,3)];
    info = info_str([["ang = ",ang],["dir = ",dir]]);
    assert_approx( plane_closest_point(plane,pts),
                   plane_closest_point(plane,plane_closest_point(plane,pts)),info);
    assert_approx( plane_closest_point(plane,pts),
                   rot(a=ang,p=plane_closest_point(plane0,rot(a=-ang,p=pts))),info);    
    assert_approx( move((-normal*dir)*normal,p=plane_closest_point(planem,pts)),
                   plane_closest_point(plane,pts),info);
    assert_approx( move((normal*dir)*normal,p=plane_closest_point(plane,pts)),
                   plane_closest_point(planem,pts),info);
}
*test_plane_closest_point();

module test_line_from_points() {
    assert_approx(line_from_points([[1,0],[0,0],[-1,0]]),[[-1,0],[1,0]]);
    assert_approx(line_from_points([[1,1],[0,1],[-1,1]]),[[-1,1],[1,1]]);
    assert(line_from_points([[1,1],[0,1],[-1,0]])==undef);
    assert(line_from_points([[1,1],[0,1],[-1,0]],fast=true)== [[-1,0],[1,1]]);
}
*test_line_from_points();

module test_is_point_on_line() { 
    assert(is_point_on_line([-15,0], [[-10,0], [10,0]],SEGMENT) == false);
    assert(is_point_on_line([-10,0], [[-10,0], [10,0]],SEGMENT) == true);
    assert(is_point_on_line([-5,0], [[-10,0], [10,0]],SEGMENT) == true);
    assert(is_point_on_line([0,0], [[-10,0], [10,0]],SEGMENT) == true);
    assert(is_point_on_line([3,3], [[-10,0], [10,0]],SEGMENT) == false);
    assert(is_point_on_line([5,0], [[-10,0], [10,0]],SEGMENT) == true);
    assert(is_point_on_line([10,0], [[-10,0], [10,0]],SEGMENT) == true);
    assert(is_point_on_line([15,0], [[-10,0], [10,0]],SEGMENT) == false);

    assert(is_point_on_line([0,-15], [[0,-10], [0,10]],SEGMENT) == false);
    assert(is_point_on_line([0,-10], [[0,-10], [0,10]],SEGMENT) == true);
    assert(is_point_on_line([0, -5], [[0,-10], [0,10]],SEGMENT) == true);
    assert(is_point_on_line([0,  0], [[0,-10], [0,10]],SEGMENT) == true);
    assert(is_point_on_line([3,  3], [[0,-10], [0,10]],SEGMENT) == false);
    assert(is_point_on_line([0,  5], [[0,-10], [0,10]],SEGMENT) == true);
    assert(is_point_on_line([0, 10], [[0,-10], [0,10]],SEGMENT) == true);
    assert(is_point_on_line([0, 15], [[0,-10], [0,10]],SEGMENT) == false);

    assert(is_point_on_line([-15,-15], [[-10,-10], [10,10]],SEGMENT) == false);
    assert(is_point_on_line([-10,-10], [[-10,-10], [10,10]],SEGMENT) == true);
    assert(is_point_on_line([ -5, -5], [[-10,-10], [10,10]],SEGMENT) == true);
    assert(is_point_on_line([  0,  0], [[-10,-10], [10,10]],SEGMENT) == true);
    assert(is_point_on_line([  0,  3], [[-10,-10], [10,10]],SEGMENT) == false);
    assert(is_point_on_line([  5,  5], [[-10,-10], [10,10]],SEGMENT) == true);
    assert(is_point_on_line([ 10, 10], [[-10,-10], [10,10]],SEGMENT) == true);
    assert(is_point_on_line([ 15, 15], [[-10,-10], [10,10]],SEGMENT) == false);

    assert(is_point_on_line([10,10], [[0,0],[5,5]]) == true);
    assert(is_point_on_line([4,4], [[0,0],[5,5]]) == true);
    assert(is_point_on_line([-2,-2], [[0,0],[5,5]]) == true);
    assert(is_point_on_line([5,5], [[0,0],[5,5]]) == true);
    assert(is_point_on_line([10,10], [[0,0],[5,5]],RAY) == true);
    assert(is_point_on_line([0,0], [[0,0],[5,5]],RAY) == true);
    assert(is_point_on_line([3,3], [[0,0],[5,5]],RAY) == true);
}
*test_is_point_on_line();


module test__point_left_of_line2d() {
    assert(_point_left_of_line2d([ -3,  0], [[-10,-10], [10,10]]) > 0);
    assert(_point_left_of_line2d([  0,  0], [[-10,-10], [10,10]]) == 0);
    assert(_point_left_of_line2d([  3,  0], [[-10,-10], [10,10]]) < 0);
}
test__point_left_of_line2d();

module test_is_collinear() {
    assert(is_collinear([-10,-10], [-15, -16], [10,10]) == false);
    assert(is_collinear([[-10,-10], [-15, -16], [10,10]]) == false);
    assert(is_collinear([-10,-10], [-15, -15], [10,10]) == true);
    assert(is_collinear([[-10,-10], [-15, -15], [10,10]]) == true);
    assert(is_collinear([-10,-10], [ -3,   0], [10,10]) == false);
    assert(is_collinear([-10,-10], [  0,   0], [10,10]) == true);
    assert(is_collinear([-10,-10], [  3,   0], [10,10]) == false);
    assert(is_collinear([-10,-10], [ 15,  15], [10,10]) == true);
    assert(is_collinear([-10,-10], [ 15,  16], [10,10]) == false);
}
*test_is_collinear();


module test_point_line_distance() {
    assert_approx(point_line_distance([1,1,1], [[-10,-10,-10], [10,10,10]]), 0);
    assert_approx(point_line_distance([-1,-1,-1], [[-10,-10,-10], [10,10,10]]), 0);
    assert_approx(point_line_distance([1,-1,0], [[-10,-10,-10], [10,10,10]]), sqrt(2));
    assert_approx(point_line_distance([8,-8,0], [[-10,-10,-10], [10,10,10]]), 8*sqrt(2));
    assert_approx(point_line_distance([3,8], [[-10,0], [10,0]],SEGMENT), 8);
    assert_approx(point_line_distance([14,3], [[-10,0], [10,0]],SEGMENT), 5);
}
*test_point_line_distance();


module test_segment_distance() {
    assert_approx(segment_distance([[-14,3], [-14,9]], [[-10,0], [10,0]]), 5);
    assert_approx(segment_distance([[-14,3], [-15,9]], [[-10,0], [10,0]]), 5);
    assert_approx(segment_distance([[14,3], [14,9]], [[-10,0], [10,0]]), 5);
    assert_approx(segment_distance([[-14,-3], [-14,-9]], [[-10,0], [10,0]]), 5);
    assert_approx(segment_distance([[-14,-3], [-15,-9]], [[-10,0], [10,0]]), 5);
    assert_approx(segment_distance([[14,-3], [14,-9]], [[-10,0], [10,0]]), 5);
    assert_approx(segment_distance([[14,3], [14,-3]], [[-10,0], [10,0]]), 4);
    assert_approx(segment_distance([[-14,3], [-14,-3]], [[-10,0], [10,0]]), 4);
    assert_approx(segment_distance([[-6,5], [4,-5]], [[-10,0], [10,0]]), 0);
    assert_approx(segment_distance([[-5,5], [5,-5]], [[-10,3], [10,-3]]), 0);
}
*test_segment_distance();


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
    pts = [for (p=pair(rands(-100,100,1000,seed_value=4312))) p];
    for (p = pair(pts,true)) {
        p1 = p.x;
        p2 = p.y;
        n = unit(p2-p1);
        n1 = [-n.y, n.x];
        n2 = line_normal(p1,p2);
        assert(approx(n2, n1));
    }
}
*test_line_normal();


module test_line_intersection() {
    assert(line_intersection([[-10,-10], [ -1,-10]], [[ 10,-10], [  1,-10]]) == undef);
    assert(line_intersection([[-10,  0], [ -1,  0]], [[ 10,  0], [  1,  0]]) == undef);
    assert(line_intersection([[-10,  0], [ -1,  0]], [[  1,  0], [ 10,  0]]) == undef);
    assert(line_intersection([[-10,  0], [ 10,  0]], [[-10,  0], [ 10,  0]]) == undef);
    assert(line_intersection([[-10, 10], [ 10, 10]], [[-10,-10], [ 10,-10]]) == undef);
    assert(line_intersection([[-10,-10], [ -1, -1]], [[ 10,-10], [  1, -1]]) == [0,0]);
    assert(line_intersection([[-10,-10], [ 10, 10]], [[ 10,-10], [-10, 10]]) == [0,0]);
    assert(line_intersection([[ -8,  0], [ 12,  4]], [[ 12,  0], [ -8,  4]]) == [2,2]);
    assert(line_intersection([[-10,-10], [ -1,-10]], [[ 10,-10], [  1,-10]],LINE,SEGMENT) == undef);
    assert(line_intersection([[-10,  0], [ -1,  0]], [[ 10,  0], [  1,  0]],LINE,SEGMENT) == undef);
    assert(line_intersection([[-10,  0], [ -1,  0]], [[  1,  0], [ 10,  0]],LINE,SEGMENT) == undef);
    assert(line_intersection([[-10,  0], [ 10,  0]], [[-10,  0], [ 10,  0]],LINE,SEGMENT) == undef);
    assert(line_intersection([[-10, 10], [ 10, 10]], [[-10,-10], [ 10,-10]],LINE,SEGMENT) == undef);
    assert(line_intersection([[-10,-10], [ -1, -1]], [[ 10,-10], [  1, -1]],LINE,SEGMENT) == undef);
    assert(line_intersection([[-10,-10], [ 10, 10]], [[ 10,-10], [-10, 10]],LINE,SEGMENT) == [0,0]);
    assert(line_intersection([[ -8,  0], [ 12,  4]], [[ 12,  0], [ -8,  4]],LINE,SEGMENT) == [2,2]);
    assert(line_intersection([[-10,-10], [ 10, 10]], [[ 10,-10], [  1, -1]],LINE,SEGMENT) == undef);
    assert(line_intersection([[-10,-10], [ 10, 10]], [[ 10,-10], [ -1,  1]],LINE,SEGMENT) == [0,0]);
}
*test_line_intersection();


module test_line_closest_point() {
    assert(approx(line_closest_point([[-10,-10], [10,10]], [1,-1]), [0,0]));
    assert(approx(line_closest_point([[-10,-10], [10,10]], [-1,1]), [0,0]));
    assert(approx(line_closest_point([[-10,-20], [10,20]], [1,2]+[-2,1]), [1,2]));
    assert(approx(line_closest_point([[-10,-20], [10,20]], [1,2]+[2,-1]), [1,2]));
    assert(approx(line_closest_point([[-10,-20], [10,20]], [13,31]), [15,30]));
    assert(approx(line_closest_point([[-10,-10], [10,10]], [1,-1],SEGMENT), [0,0]));
    assert(approx(line_closest_point([[-10,-10], [10,10]], [-1,1],SEGMENT), [0,0]));
    assert(approx(line_closest_point([[-10,-20], [10,20]], [1,2]+[-2,1],SEGMENT), [1,2]));
    assert(approx(line_closest_point([[-10,-20], [10,20]], [1,2]+[2,-1],SEGMENT), [1,2]));
    assert(approx(line_closest_point([[-10,-20], [10,20]], [13,31],SEGMENT), [10,20]));
    assert(approx(line_closest_point([[-10,-20], [10,20]], [15,25],SEGMENT), [10,20]));
}
*test_line_closest_point();

module test_circle_2tangents() {
//** missing tests with arg tangent=true
    assert(approx(circle_2tangents([10,10],[0,0],[10,-10],r=10/sqrt(2))[0],[10,0]));
    assert(approx(circle_2tangents([-10,10],[0,0],[-10,-10],r=10/sqrt(2))[0],[-10,0]));
    assert(approx(circle_2tangents([-10,10],[0,0],[10,10],r=10/sqrt(2))[0],[0,10]));
    assert(approx(circle_2tangents([-10,-10],[0,0],[10,-10],r=10/sqrt(2))[0],[0,-10]));
    assert(approx(circle_2tangents([0,10],[0,0],[10,0],r=10)[0],[10,10]));
    assert(approx(circle_2tangents([10,0],[0,0],[0,-10],r=10)[0],[10,-10]));
    assert(approx(circle_2tangents([0,-10],[0,0],[-10,0],r=10)[0],[-10,-10]));
    assert(approx(circle_2tangents([-10,0],[0,0],[0,10],r=10)[0],[-10,10]));
    assert_approx(circle_2tangents(polar_to_xy(10,60),[0,0],[10,0],r=10)[0],polar_to_xy(20,30));
}
*test_circle_2tangents();


module test_circle_3points() {
    count = 200;
    coords = rands(-100,100,count,seed_value=888);
    radii = rands(10,100,count,seed_value=390);
    angles = rands(0,360,count,seed_value=699);
    // 2D tests.
    for(i = count(count)) {
        cp = select(coords,i,i+1);
        r = radii[i];
        angs = sort(select(angles,i,i+2));
        pts = [for (a=angs) cp+polar_to_xy(r,a)];
        res = circle_3points(pts);
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
    for(i = count(count)) {
        cp = select(coords,i,i+1);
        r = radii[i];
        angs = sort(select(angles,i,i+2));
        pts = [for (a=angs) cp+polar_to_xy(r,a)];
        res = circle_3points(pts[0], pts[1], pts[2]);
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
    for(i = count(count)) {
        cp = select(coords,i,i+2);
        r = radii[i];
        nrm = unit(select(coords,i+10,i+12));
        n = nrm.z<0? -nrm : nrm;
        angs = sort(select(angles,i,i+2));
        pts = translate(cp,p=rot(from=UP,to=n,p=[for (a=angs) point3d(polar_to_xy(r,a))]));
        res = circle_3points(pts);
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
    for(i = count(count)) {
        cp = select(coords,i,i+2);
        r = radii[i];
        nrm = unit(select(coords,i+10,i+12));
        n = nrm.z<0? -nrm : nrm;
        angs = sort(select(angles,i,i+2));
        pts = translate(cp,p=rot(from=UP,to=n,p=[for (a=angs) point3d(polar_to_xy(r,a))]));
        res = circle_3points(pts[0], pts[1], pts[2]);
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
*test_circle_3points();


module test_circle_point_tangents() {
    testvals = [
        // cp    r   pt                 expect
        [[0,0],  50, [50*sqrt(2),0],    [polar_to_xy(50,45), polar_to_xy(50,-45)]],
        [[5,10], 50, [5+50*sqrt(2),10], [[5,10]+polar_to_xy(50,45), [5,10]+polar_to_xy(50,-45)]],
        [[0,0],  50, [0,50*sqrt(2)],    [polar_to_xy(50,135), polar_to_xy(50,45)]],
        [[5,10], 50, [5,10+50*sqrt(2)], [[5,10]+polar_to_xy(50,135), [5,10]+polar_to_xy(50,45)]],
        [[5,10], 50, [5,10+50*sqrt(2)], [[5,10]+polar_to_xy(50,135), [5,10]+polar_to_xy(50,45)]],
        [[5,10], 50, [5, 60],           [[5, 60]]],
        [[5,10], 50, [5, 59],           []],
    ];
    for (v = testvals) {
        cp = v[0]; r  = v[1]; pt = v[2]; expect = v[3];
        info = str("cp=",cp, ", r=",r, ", pt=",pt);
        assert_approx(circle_point_tangents(r=r,cp=cp,pt=pt), expect, info);
    }
}
*test_circle_point_tangents();


module test_plane3pt() {
    assert_approx(plane3pt([0,0,20], [0,10,10], [0,0,0]), [1,0,0,0]);
    assert_approx(plane3pt([2,0,20], [2,10,10], [2,0,0]), [1,0,0,2]);
    assert_approx(plane3pt([0,0,0], [10,0,10], [0,0,20]), [0,1,0,0]);
    assert_approx(plane3pt([0,2,0], [10,2,10], [0,2,20]), [0,1,0,2]);
    assert_approx(plane3pt([0,0,0], [10,10,0], [20,0,0]), [0,0,1,0]);
    assert_approx(plane3pt([0,0,2], [10,10,2], [20,0,2]), [0,0,1,2]);
}
*test_plane3pt();

module test_plane3pt_indexed() {
    pts = [ [0,0,0], [10,0,0], [0,10,0], [0,0,10] ];
    s13 = sqrt(1/3);
    assert_approx(plane3pt_indexed(pts, 0,3,2), [1,0,0,0]);
    assert_approx(plane3pt_indexed(pts, 0,2,3), [-1,0,0,0]);
    assert_approx(plane3pt_indexed(pts, 0,1,3), [0,1,0,0]);
    assert_approx(plane3pt_indexed(pts, 0,3,1), [0,-1,0,0]);
    assert_approx(plane3pt_indexed(pts, 0,2,1), [0,0,1,0]);
    assert_approx(plane3pt_indexed(pts, 0,1,2), [0,0,-1,0]);
    assert_approx(plane3pt_indexed(pts, 3,2,1), [s13,s13,s13,10*s13]);
    assert_approx(plane3pt_indexed(pts, 1,2,3), [-s13,-s13,-s13,-10*s13]);
}
*test_plane3pt_indexed();

module test_plane_from_points() {
    assert_std(plane_from_points([[0,0,20], [0,10,10], [0,0,0], [0,5,3]]), [1,0,0,0]);
    assert_std(plane_from_points([[2,0,20], [2,10,10], [2,0,0], [2,3,4]]), [1,0,0,2]);
    assert_std(plane_from_points([[0,0,0], [10,0,10], [0,0,20], [5,0,7]]), [0,1,0,0]);
    assert_std(plane_from_points([[0,2,0], [10,2,10], [0,2,20], [4,2,3]]), [0,1,0,2]);
    assert_std(plane_from_points([[0,0,0], [10,10,0], [20,0,0], [8,3,0]]), [0,0,1,0]);
    assert_std(plane_from_points([[0,0,2], [10,10,2], [20,0,2], [3,4,2]]), [0,0,1,2]);  
}
*test_plane_from_points();


module test_polygon_normal() {
   circ = path3d(circle($fn=37, r=3));

   assert_approx(polygon_normal(circ), UP);
   assert_approx(polygon_normal(rot(from=UP,to=[1,2,3],p=circ)), unit([1,2,3]));
   assert_approx(polygon_normal(rot(from=UP,to=[4,-2,3],p=reverse(circ))), -unit([4,-2,3]));
   assert_approx(polygon_normal(path3d([[0,0], [10,10], [11,10], [0,-1], [-1,1]])), UP);
}
*test_polygon_normal();

module test_plane_normal() {
    assert_approx(plane_normal(plane3pt([0,0,20], [0,10,10], [0,0,0])), [1,0,0]);
    assert_approx(plane_normal(plane3pt([2,0,20], [2,10,10], [2,0,0])), [1,0,0]);
    assert_approx(plane_normal(plane3pt([0,0,0], [10,0,10], [0,0,20])), [0,1,0]);
    assert_approx(plane_normal(plane3pt([0,2,0], [10,2,10], [0,2,20])), [0,1,0]);
    assert_approx(plane_normal(plane3pt([0,0,0], [10,10,0], [20,0,0])), [0,0,1]);
    assert_approx(plane_normal(plane3pt([0,0,2], [10,10,2], [20,0,2])), [0,0,1]);
}
*test_plane_normal();


module test_point_plane_distance() {
    plane1 = plane3pt([-10,0,0], [0,10,0], [10,0,0]);
    assert(point_plane_distance(plane1, [0,0,5]) == 5);
    assert(point_plane_distance(plane1, [5,5,8]) == 8);
}
*test_point_plane_distance();


module test_polygon_line_intersection() {
    poly0 = [ [-10,-10, 0],[10,-10, 0],[10,10,0],[0,5,0],[-10,10,0] ];
    line0 = [ [-3,7.5,0],[3,7.5,0] ]; // a segment on poly0 plane, out of poly0
    angs  = rands(0,360,3); 
    poly   = rot(angs,p=poly0);
    lineon = rot(angs,p=line0);
    info   = info_str([["angs = ",angs],["line = ",lineon],["poly = ",poly]]);
    // line on polygon plane
    assert_approx(polygon_line_intersection(poly,lineon,bounded=[true,true]),
                  undef, info);
    assert_approx(polygon_line_intersection(poly,lineon,bounded=[true,false]),
                  [rot(angs,p=[[5,7.5,0],[10,7.5,0]])], info);
    assert_approx(polygon_line_intersection(poly,lineon,bounded=[false,true]),
                  [rot(angs,p=[[-10,7.5,0],[-5,7.5,0]])], info);
    assert_approx(polygon_line_intersection(poly,lineon,bounded=[false,false]),
                  rot(angs,p=[[[-10,7.5,0],[-5,7.5,0]],[[5,7.5,0],[10,7.5,0]]]), info);
    // line parallel to polygon plane
    linepll = move([0,0,1],lineon);
    assert_approx(polygon_line_intersection(poly,linepll,bounded=[true,true]),
                  undef, info);
    assert_approx(polygon_line_intersection(poly,linepll,bounded=[true,false]),
                  undef, info);
    assert_approx(polygon_line_intersection(poly,linepll,bounded=[false,true]),
                  undef, info);
    assert_approx(polygon_line_intersection(poly,linepll,bounded=[false,false]),
                  undef, info);
    // general case
    trnsl   = [0,0,1];
    linegnr = move(trnsl,rot(angs,p=[[5,5,5],[3,3,3]]));
    polygnr = move(trnsl,rot(angs,p=poly0));
    assert_approx(polygon_line_intersection(polygnr,linegnr,bounded=[true,true]),
                  undef, info);
    assert_approx(polygon_line_intersection(polygnr,linegnr,bounded=[true,false]),
                  trnsl, info);
    assert_approx(polygon_line_intersection(polygnr,linegnr,bounded=[false,true]),
                  undef, info);
    assert_approx(polygon_line_intersection(polygnr,linegnr,bounded=[false,false]),
                  trnsl, info);

    sq = path3d(square(10));
    pentagram = 10*path3d(turtle(["move",10,"left",144], repeat=4));
    for (tran = [ident(4), skew(sxy=1.2)*scale([.9,1,1.2])*yrot(14)*zrot(37)*xrot(9)])
    {
        assert_approx(polygon_line_intersection(apply(tran,sq),apply(tran,[[5,5,-1], [5,5,10]])), apply(tran, [5,5,0]));
        assert_approx(polygon_line_intersection(apply(tran,sq),apply(tran,[[5,5,1], [5,5,10]])), apply(tran, [5,5,0]));
        assert(undef==polygon_line_intersection(apply(tran,sq),apply(tran,[[5,5,1], [5,5,10]]),RAY));
        assert(undef==polygon_line_intersection(apply(tran,sq),apply(tran,[[11,11,-1],[11,11,1]])));
        assert_approx(polygon_line_intersection(apply(tran,sq),apply(tran,[[5,0,-10], [5,0,10]])), apply(tran, [5,0,0]));
        assert_equal(polygon_line_intersection(apply(tran,sq),apply(tran,[[5,0,1], [5,0,10]]),RAY), undef);
        assert_approx(polygon_line_intersection(apply(tran,sq),apply(tran,[[10,0,1],[10,0,10]])), apply(tran, [10,0,0]));
        assert_approx(polygon_line_intersection(apply(tran,sq),apply(tran,[[1,5,0],[9,6,0]])), apply(tran, [[[0,4.875,0],[10,6.125,0]]]));
        assert_approx(polygon_line_intersection(apply(tran,sq),apply(tran,[[1,5,0],[9,6,0]]),SEGMENT), apply(tran, [[[1,5,0],[9,6,0]]]));
        assert_approx(polygon_line_intersection(apply(tran,sq),apply(tran,[[-1,-1,0],[8,8,0]])), apply(tran, [[[0,0,0],[10,10,0]]]));
        assert_approx(polygon_line_intersection(apply(tran,sq),apply(tran,[[-1,-1,0],[8,8,0]]),SEGMENT), apply(tran, [[[0,0,0],[8,8,0]]]));
        assert_approx(polygon_line_intersection(apply(tran,sq),apply(tran,[[-1,-1,0],[8,8,0]]),RAY), apply(tran, [[[0,0,0],[10,10,0]]]));
        assert_approx(polygon_line_intersection(apply(tran,sq),apply(tran,[[-2,4,0], [12,11,0]]),RAY), apply(tran, [[[0,5,0],[10,10,0]]]));
        assert_equal(polygon_line_intersection(apply(tran,sq),apply(tran,[[-20,0,0],[20,40,0]]),RAY), undef);
        assert_approx(polygon_line_intersection(apply(tran,sq),apply(tran,[[-1,0,0],[11,0,0]])), apply(tran, [[[0,0,0],[10,0,0]]]));
    }
    assert_approx(polygon_line_intersection(path2d(sq),[[1,5],[9,6]],SEGMENT), [[[1,5],[9,6]]]);
    assert_approx(polygon_line_intersection(path2d(sq),[[1,5],[9,6]],LINE), [[[0,4.875],[10,6.125]]]);
    assert_approx(polygon_line_intersection(pentagram,[[50,10,-4],[54,12,4]], nonzero=true), [52,11,0]);
    assert_equal(polygon_line_intersection(pentagram,[[50,10,-4],[54,12,4]], nonzero=false), undef);
    assert_approx(polygon_line_intersection(pentagram,[[50,-10,-4],[54,-12,4]], nonzero=true), [52,-11,0]);
    assert_approx(polygon_line_intersection(pentagram,[[50,-10,-4],[54,-12,4]], nonzero=false), [52,-11,0]);
    assert_approx(polygon_line_intersection(star(8,step=3,od=10), [[-5,3], [5,3]]),
                                [[[-3.31370849898, 3], [-2.24264068712, 3]],
                                [[-0.828427124746, 3], [0.828427124746, 3]],
                                 [[2.24264068712, 3], [3.31370849898, 3]]]);

    tran = skew(sxy=1.2)*scale([.9,1,1.2])*yrot(14)*zrot(37)*xrot(9);

    // assemble multiple edges into one edge
    assert_approx(polygon_line_intersection(star(r=15,n=8,step=2), [[20,-5],[-5,20]]), [[[15,0],[0,15]]]);
    assert_approx(polygon_line_intersection(apply(tran,path3d(star(r=15,n=8,step=2))), apply(tran,[[20,-5,0],[-5,20,0]])), apply(tran,[[[15,0,0],[0,15,0]]]));
    // line going the other direction
    assert_approx(polygon_line_intersection(star(r=15,n=8,step=2), [[-5,20],[20,-5]]), [[[0,15],[15,0]]]);
    assert_approx(polygon_line_intersection(apply(tran,path3d(star(r=15,n=8,step=2))), apply(tran,[[-5,20,0],[20,-5,0]])),apply(tran, [[[0,15,0],[15,0,0]]]));
    // single point
    assert_approx(polygon_line_intersection(hexagon(r=15), [[15,-10],[15,13]], RAY), [[[15,0]]]);
    assert_approx(polygon_line_intersection(apply(tran,path3d(hexagon(r=15))), apply(tran,[[15,-10,0],[15,13,0]]), RAY),
                  [[apply(tran,[15,0,0])]]);
    // two points
    assert_approx(polygon_line_intersection(star(r=15,n=8,step=3), rot(22.5,p=[[15,-10],[15,20]],cp=[15,0])), 
                    [[[15,0]], [[10.6066017178, 10.6066017178]]]);
    assert_approx(polygon_line_intersection(apply(tran,path3d(star(r=15,n=8,step=3))), apply(tran,rot(22.5,p=[[15,-10,0],[15,20,0]],cp=[15,0,0]))), 
                    [[apply(tran,[15,0,0])], [apply(tran,[10.6066017178, 10.6066017178,0])]]);
    // two segments and one point
    star7 = star(r=25,ir=9,n=7);
    assert_approx(polygon_line_intersection(star7, [left(10,p=star7[8]), right(50,p=star7[8])]),
                  [[[-22.5242216976, 10.8470934779]],
                   [[-5.60077322195, 10.8470934779], [0.997372374838, 10.8470934779]],
                   [[4.61675816681, 10.8470934779], [11.4280421589, 10.8470934779]]]);
    assert_approx(polygon_line_intersection(apply(tran,path3d(star7)),
                        apply(tran, path3d([left(10,p=star7[8]), right(50,p=star7[8])]))),
                  [[apply(tran,[-22.5242216976, 10.8470934779,0])],
                   apply(tran,[[-5.60077322195, 10.8470934779,0], [0.997372374838, 10.8470934779,0]]),
                   apply(tran,[[4.61675816681, 10.8470934779,0], [11.4280421589, 10.8470934779,0]])]);
}
*test_polygon_line_intersection();


module test_is_coplanar() {
    assert(is_coplanar([ [5,5,1],[0,0,1],[-1,-1,1] ]) == false);
    assert(is_coplanar([ [5,5,1],[0,0,0],[-1,-1,1] ]) == true);
    assert(is_coplanar([ [0,0,0],[1,0,1],[1,1,1], [0,1,2] ]) == false);
    assert(is_coplanar([ [0,0,0],[1,0,1],[1,1,2], [0,1,1] ]) == true);
 }
*test_is_coplanar();


module test__is_point_above_plane() {
    plane = plane3pt([0,0,0], [0,10,10], [10,0,10]);
    assert(_is_point_above_plane(plane, [5,5,10]) == false);
    assert(_is_point_above_plane(plane, [-5,0,0]) == true);
    assert(_is_point_above_plane(plane, [5,0,0]) == false);
    assert(_is_point_above_plane(plane, [0,-5,0]) == true);
    assert(_is_point_above_plane(plane, [0,5,0]) == false);
    assert(_is_point_above_plane(plane, [0,0,5]) == true);
    assert(_is_point_above_plane(plane, [0,0,-5]) == false);
}
*test__is_point_above_plane();




module test_polygon_area() {
    assert(approx(polygon_area([[1,1],[-1,1],[-1,-1],[1,-1]]), 4));
    assert(approx(polygon_area(circle(r=50,$fn=1000),signed=true), -PI*50*50, eps=0.1));
    assert(approx(polygon_area(rot([13,27,75],
                               p=path3d(circle(r=50,$fn=1000),fill=23)),
                               signed=true), PI*50*50, eps=0.1));
    assert(abs(triangle_area([0,0], [0,10], [10,0]) + 50) < EPSILON);
    assert(abs(triangle_area([0,0], [0,10], [0,15])) < EPSILON);
    assert(abs(triangle_area([0,0], [10,0], [0,10]) - 50) < EPSILON);
    
}
*test_polygon_area();


module test_is_polygon_convex() {
    assert(is_polygon_convex([[1,1],[-1,1],[-1,-1],[1,-1]]));
    assert(is_polygon_convex(circle(r=50,$fn=1000)));
    assert(is_polygon_convex(rot([50,120,30], p=path3d(circle(1,$fn=50)))));
    assert(!is_polygon_convex([[1,1],[0,0],[-1,1],[-1,-1],[1,-1]]));
    assert(!is_polygon_convex([for (i=[0:36]) let(a=-i*10) (10+i)*[cos(a),sin(a)]])); //   spiral 
}
*test_is_polygon_convex();


module test_reindex_polygon() {
   pent = subdivide_path([for(i=[0:4])[sin(72*i),cos(72*i)]],5);
   circ = circle($fn=5,r=2.2);
   assert_approx(reindex_polygon(circ,pent), [[0.951056516295,0.309016994375],[0.587785252292,-0.809016994375],[-0.587785252292,-0.809016994375],[-0.951056516295,0.309016994375],[0,1]]);
   poly = [[-1,1],[-1,-1],[1,-1],[1,1],[0,0]];
   ref  = [for(i=[0:4])[sin(72*i),cos(72*i)]];
   assert_approx(reindex_polygon(ref,poly),[[0,0],[1,1],[1,-1],[-1,-1],[-1,1]]);
}
*test_reindex_polygon();


module test_align_polygon() {
  /*
   pentagon = subdivide_path(pentagon(side=2),10);
   hexagon  = subdivide_path(hexagon(side=2.7),10);
   aligned =  [[2.7,0],[2.025,-1.16913429511],[1.35,-2.33826859022],
               [-1.35,-2.33826859022],[-2.025,-1.16913429511],[-2.7,0],
               [-2.025,1.16913429511],[-1.35,2.33826859022],[1.35,2.33826859022],
               [2.025,1.16913429511]];
   assert_approx(align_polygon(pentagon,hexagon,[0:10:359]), aligned);
   aligned2 = [[1.37638192047,0],[1.37638192047,-1],[0.425325404176,-1.30901699437],
               [-0.525731112119,-1.61803398875],[-1.11351636441,-0.809016994375],
               [-1.7013016167,0],[-1.11351636441,0.809016994375],
               [-0.525731112119,1.61803398875],[0.425325404176,1.30901699437],
               [1.37638192047,1]];
   assert_approx(align_polygon(hexagon,pentagon,[0:10:359]), aligned2);
   */
}
*test_align_polygon();


module test__noncollinear_triple() {
    assert(_noncollinear_triple([[1,1],[2,2],[3,3],[4,4],[4,5],[5,6]]) == [0,5,3]);
    assert(_noncollinear_triple([[1,1],[2,2],[8,3],[4,4],[4,5],[5,6]]) == [0,2,5]);
    u = unit([5,3]);
    assert_equal(_noncollinear_triple([for(i = [2,3,4,5,7,12,15]) i * u], error=false),[]);
}
*test__noncollinear_triple();


module test_centroid() {
    // polygons
    $fn = 24;
    assert_approx(centroid(circle(d=100)), [0,0]);
    assert_approx(centroid(rect([40,60],rounding=10,anchor=LEFT)), [20,0]);
    assert_approx(centroid(rect([40,60],rounding=10,anchor=FWD)), [0,30]);
    poly = move([1,2.5,3.1],p=rot([12,49,24], p=path3d(circle(10,$fn=33))));
    assert_approx(centroid(poly), [1,2.5,3.1]);

    // regions
    R = [square(10), move([5,4],circle(r=3,$fn=32)),  right(15,square(7)), move([18,3],circle(r=2,$fn=5))];
    assert_approx(centroid(R), [9.82836532809, 4.76313546433]);

    // VNFs
    assert_approx(centroid(cube(100, center=false)), [50,50,50]);
    assert_approx(centroid(cube(100, center=true)), [0,0,0]);
    assert_approx(centroid(cube(100, anchor=[1,1,1])), [-50,-50,-50]);
    assert_approx(centroid(cube(100, anchor=BOT)), [0,0,50]);
    assert_approx(centroid(cube(100, anchor=TOP)), [0,0,-50]);
    assert_approx(centroid(sphere(d=100, anchor=CENTER, $fn=36)), [0,0,0]);
    assert_approx(centroid(sphere(d=100, anchor=BOT, $fn=36)), [0,0,50]);
    ellipse = xscale(2, p=circle($fn=24, r=3));
    assert_approx(centroid(path_sweep(pentagon(r=1), path3d(ellipse), closed=true)),[0,0,0]);
}
*test_centroid();




module test_point_in_polygon() {
    poly = [for (a=[0:30:359]) 10*[cos(a),sin(a)]];
    poly2 = [ [-3,-3],[2,-3],[2,1],[-1,1],[-1,-1],[1,-1],[1,2],[-3,2] ];
    assert(point_in_polygon([0,0], poly) == 1);
    assert(point_in_polygon([20,0], poly) == -1);
    assert(point_in_polygon([20,0], poly,nonzero=false) == -1);
    assert(point_in_polygon([5,5], poly) == 1);
    assert(point_in_polygon([-5,5], poly) == 1);
    assert(point_in_polygon([-5,-5], poly) == 1);
    assert(point_in_polygon([5,-5], poly) == 1);
    assert(point_in_polygon([5,-5], poly,nonzero=false,eps=EPSILON) == 1);
    assert(point_in_polygon([-10,-10], poly) == -1);
    assert(point_in_polygon([10,0], poly) == 0);
    assert(point_in_polygon([0,10], poly) == 0);
    assert(point_in_polygon([0,-10], poly) == 0);
    assert(point_in_polygon([0,-10], poly,nonzero=false) == 0);
    assert(point_in_polygon([0,0], poly2,nonzero=true) == 1);
    assert(point_in_polygon([0,1], poly2,nonzero=true) == 0);
    assert(point_in_polygon([0,1], poly2,nonzero=false) == 0);
    assert(point_in_polygon([1,0], poly2,nonzero=false) == 0);
    assert(point_in_polygon([0,0], poly2,nonzero=false,eps=EPSILON) == -1);
}
*test_point_in_polygon();



module test_is_polygon_clockwise() {
    assert(is_polygon_clockwise([[-1,1],[1,1],[1,-1],[-1,-1]]));
    assert(!is_polygon_clockwise([[1,1],[-1,1],[-1,-1],[1,-1]]));
    assert(is_polygon_clockwise(circle(d=100)));
    assert(is_polygon_clockwise(square(100)));
}
*test_is_polygon_clockwise();


module test_clockwise_polygon() {
    path = circle(d=100);
    rpath = concat([path[0]], reverse(select(path,1,-1)));
    assert(clockwise_polygon(path) == path);
    assert(clockwise_polygon(rpath) == path);
}
*test_clockwise_polygon();


module test_ccw_polygon() {
    path = circle(d=100);
    rpath = concat([path[0]], reverse(select(path,1,-1)));
    assert(ccw_polygon(path) == rpath);
    assert(ccw_polygon(rpath) == rpath);
}
*test_ccw_polygon();


module test_reverse_polygon() {
    path = circle(d=100);
    rpath = concat([path[0]], reverse(select(path,1,-1)));
    assert(reverse_polygon(path) == rpath);
    assert(reverse_polygon(rpath) == path);
}
*test_reverse_polygon();


module test_convex_distance() {
// 2D
    c1 = circle(10,$fn=24);
    c2 = move([15,0], p=c1);
    assert(convex_distance(c1, c2)==0);
    c3 = move([22,0],c1);
    assert_approx(convex_distance(c1, c3),2);
// 3D
    s1 = sphere(10,$fn=4);
    s2 = move([15,0], p=s1);
    assert_approx(convex_distance(s1[0], s2[0]), 0.857864376269);
    s3 = move([25.3,0],s1);
    assert_approx(convex_distance(s1[0], s3[0]), 11.1578643763);
    s4 = move([30,25],s1);    
    assert_approx(convex_distance(s1[0], s4[0]), 28.8908729653);
    s5 = move([10*sqrt(2),0],s1);    
    assert_approx(convex_distance(s1[0], s5[0]), 0);
}
*test_convex_distance();

module test_convex_collision() {
// 2D
    c1 = circle(10,$fn=24);
    c2 = move([15,0], p=c1);
    assert(convex_collision(c1, c2));
    c3 = move([22,0],c1);
    assert(!convex_collision(c1, c3));
// 3D
    s1 = sphere(10,$fn=4);
    s2 = move([15,0], p=s1);
    assert(!convex_collision(s1[0], s2[0]));
    s3 = move([25.3,0],s1);
    assert(!convex_collision(s1[0], s3[0]));
    s4 = move([5,0],s1);    
    assert(convex_collision(s1[0], s4[0]));
    s5 = move([10*sqrt(2),0],s1);    
    assert(convex_collision(s1[0], s5[0]));
}
*test_convex_distance();



module test_rot_decode() {
   Tlist = [
             rot(37),
             xrot(49),
             yrot(88),
             rot(37,v=[1,3,3]),
             rot(41,v=[2,-3,4]),
             rot(180),
             xrot(180),
             yrot(180),
             rot(180, v=[3,2,-5], cp=[3,5,18]),
             rot(0.1, v=[1,2,3]),
             rot(-47,v=[3,4,5],cp=[9,3,4]),
             rot(197,v=[13,4,5],cp=[9,-3,4]),
             move([3,4,5]),
             move([3,4,5]) * rot(a=56, v=[5,3,-3], cp=[2,3,4]),
             ident(4)
           ];
    errlist = [for(T = Tlist)
                  let(
                       parm = rot_decode(T),
                       restore = move(parm[3])*rot(a=parm[0],v=parm[1],cp=parm[2])
                  )
                  norm_fro(restore-T)];
    assert(max(errlist)<1e-13);
}
*test_rot_decode();




// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
