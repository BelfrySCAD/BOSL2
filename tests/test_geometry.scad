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
    assert(line_from_points([[1,1],[0,1],[-1,0]],check_collinear=true)==undef);
    assert(line_from_points([[3,3],[0,3],[0,0]],check_collinear=false)-[[-0.5,0.5],[2.5,3.5]]<[[EPSILON,EPSILON],[EPSILON,EPSILON]]);
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
    assert(approx(circle_2tangents(10/sqrt(2),[10,10],[0,0],[10,-10])[0], [10,0]));
    assert(approx(circle_2tangents(10/sqrt(2),[-10,10],[0,0],[-10,-10])[0], [-10,0]));
    assert(approx(circle_2tangents(10/sqrt(2),[-10,10],[0,0],[10,10])[0], [0,10]));
    assert(approx(circle_2tangents(10/sqrt(2),[-10,-10],[0,0],[10,-10])[0], [0,-10]));
    assert(approx(circle_2tangents(10,[0,10],[0,0],[10,0])[0], [10,10]));
    assert(approx(circle_2tangents(10,[10,0],[0,0],[0,-10])[0], [10,-10]));
    assert(approx(circle_2tangents(10,[0,-10],[0,0],[-10,0])[0], [-10,-10]));
    assert(approx(circle_2tangents(10,[-10,0],[0,0],[0,10])[0], [-10,10]));
    assert_approx(circle_2tangents(10,polar_to_xy(10,60),[0,0],[10,0])[0], polar_to_xy(20,30));
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
    assert(abs(polygon_area([[0,0], [0,10], [10,0]],signed=true) + 50) < EPSILON);
    assert(abs(polygon_area([[0,0], [0,10], [0,15]],signed=true)) < EPSILON);
    assert(abs(polygon_area([[0,0], [10,0], [0,10]],signed=true) - 50) < EPSILON);
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
  // These tests fail because align_polygon displays output
   /*
   ellipse = yscale(3,circle(r=10, $fn=32));
   tri = move([-50/3,-9],
              subdivide_path([[0,0], [50,0], [0,27]], 32));
   aligned = align_polygon(ellipse,tri, [0:5:180]);
   assert_approx(aligned,
              [[8.6933324366, 2.32937140592], [9.77174512453,
              -1.69531953695], [10.8501578125, -5.72001047982],
              [11.9285705004, -9.74470142269], [13.0069831883,
              -13.7693923656], [9.28126928691, -14.7676943967],
              [5.55555538551, -15.7659964278], [1.82984148411,
              -16.7642984589], [-1.89587241729, -17.76260049],
              [-5.62158631869, -18.7609025211], [-9.34730022009,
              -19.7592045522], [-13.0730141215, -20.7575065833],
              [-12.0623183481, -16.5048600039], [-11.0516225746,
              -12.2522134245], [-10.0409268012, -7.99956684512],
              [-9.03023102775, -3.74692026572], [-8.01953525431,
              0.505726313678], [-7.00883948087, 4.75837289308],
              [-5.99814370744, 9.01101947248], [-4.987447934,
              13.2636660519], [-3.97675216056, 17.5163126313],
              [-2.96605638713, 21.7689592107], [-1.95536061369,
              26.0216057901], [-0.944664840253, 30.2742523695],
              [0.0660309331843, 34.5268989489], [1.14444362111,
              30.502208006], [2.22285630904, 26.4775170631],
              [3.30126899697, 22.4528261203], [4.37968168489,
              18.4281351774], [5.45809437282, 14.4034442345],
              [6.53650706075, 10.3787532917], [7.61491974867,
              6.35406234879]]);
   ellipse2 = yscale(2,circle(r=10, $fn=32));
   tri2 = subdivide_path([[0,0], [27,0], [-7,50]], 32);
   T = [for(x=[-10:0], y=[-30:-15]) move([x,y])];
   aligned2 = align_polygon(ellipse2,tri2, trans=T);
   assert_approx(aligned2,
              [[10.5384615385, -3.61538461538], [13.1538461538,
              -7.46153846154], [15.7692307692, -11.3076923077],
              [18.3846153846, -15.1538461538], [21, -19],
              [17.1428571429, -19], [13.2857142857, -19],
              [9.42857142857, -19], [5.57142857143, -19],
              [1.71428571429, -19], [-2.14285714286, -19], [-6, -19],
              [-6.58333333333, -14.8333333333], [-7.16666666667,
              -10.6666666667], [-7.75, -6.5], [-8.33333333333,
              -2.33333333333], [-8.91666666667, 1.83333333333], [-9.5,
              6], [-10.0833333333, 10.1666666667], [-10.6666666667,
              14.3333333333], [-11.25, 18.5], [-11.8333333333,
              22.6666666667], [-12.4166666667, 26.8333333333], [-13,
              31], [-10.3846153846, 27.1538461538], [-7.76923076923,
              23.3076923077], [-5.15384615385, 19.4615384615],
              [-2.53846153846, 15.6153846154], [0.0769230769231,
              11.7692307692], [2.69230769231, 7.92307692308],
              [5.30769230769, 4.07692307692], [7.92307692308,
              0.230769230769]]);
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


function standard_faces(faces) =
    sort([for(face=faces)
            list_rotate(face, min_index(face))]);

module test_hull() {
    assert_equal(hull([[3,4],[5,5]]), [0,1]);
    assert_equal(hull([[3,4,1],[5,5,3]]), [0,1]);

    test_collinear_2d = let(u = unit([5,3]))    [ for(i = [9,2,3,4,5,7,12,15,13]) i * u ];
    assert_equal(sort(hull(test_collinear_2d)), [1,7]);
    test_collinear_3d = let(u = unit([5,3,2]))    [ for(i = [9,2,3,4,5,7,12,15,13]) i * u ];
    assert_equal(sort(hull(test_collinear_3d)), [1,7]);

    /*    // produces some extra points along edges
    test_square_2d = [for(x=[1:5], y=[2:6]) [x,y]];
    echo(test_square_2d);
    move_copies(test_square_2d) circle(r=.1,$fn=16);
    color("red")move_copies(select(test_square_2d,hull(test_square_2d))) circle(r=.1,$fn=16);
    */

    /*  // also produces extra points along edges
    test_square_2d = rot(22,p=[for(x=[1:5], y=[2:6]) [x,y]]);
    echo(test_square_2d);
    move_copies(test_square_2d) circle(r=.1,$fn=16);
    color("red")move_copies(select(test_square_2d,hull(test_square_2d))) circle(r=.1,$fn=16);
    */

    rand10_2d = [[1.55356, -1.98965], [4.23157, -0.947788], [-4.06193, -1.55463],
                 [1.23889, -3.73133], [-1.02637, -4.0155], [4.26806, -4.61909],
                 [3.59556, -3.1574], [-2.77776, -4.21857], [-3.66253,-4.34458], [1.82324, 0.102025]];
    assert_equal(sort(hull(rand10_2d)), [1,2,5,8,9]);

    rand75_2d = [[-3.14743, -3.28139], [0.15343, -0.370249], [0.082565, 3.95939], [-2.56925, -3.16262], [-1.59463, 4.20893],
                 [-4.90744, -1.21374], [-1.0819, -1.93703], [-3.72723, -3.0744], [-3.34339, 1.53535], [3.15803, -0.307388], [4.23289,
                 4.46259], [1.73624, 1.38918], [3.72087, -1.55028], [1.2604, 2.30502], [-0.966431, 1.673], [-3.26866, -0.531443], [1.52605,
                 0.991804], [-1.26305, 1.0737], [-4.31943, 4.11932], [0.488101, 0.0425981], [1.0233, -0.723037], [-4.73406, 2.14568],
                 [-4.75915, 3.83262], [4.90999, -2.76668], [1.91971, -3.8604], [4.38594, -0.761767], [-0.352984, 1.55291], [2.02714,
                 -0.340099], [1.76052, 2.09196], [-1.27485, -4.39477], [4.36364, 3.84964], [0.593612, -4.00028], [3.06833, -3.67117],
                 [4.26834, -4.21213], [4.60226, -0.120432], [-2.45646, 2.60327], [-4.79461, 3.83724], [-3.29755, 0.760159], [0.218423,
                 4.1687], [-0.115829, -2.06242], [-3.96188, 3.21568], [4.3018, -2.5299], [-4.41694, 4.75173], [-3.8393, 2.82212], [-1.14268,
                 1.80751], [2.05805, 1.68593], [-3.0159, -2.91139], [-1.44828, -1.93564], [-0.265887, 0.519893], [-0.457361, -0.610096],
                 [-0.426359, -2.37315], [-3.1018, 2.31141], [0.179141, -3.56242], [-0.491786, 0.813055], [-3.28502, -1.18933], [0.0914813,
                 2.16122], [4.5777, 4.83972], [-1.07096, 2.74992], [-0.698689, 3.9032], [-1.21809, -1.54434], [3.14457, 4.92302], [-4.63176,
                 2.81952], [4.84414, 4.63699], [2.4259, -0.747268], [-1.52088, -4.58305], [1.6961, -3.73678], [-0.483003, -3.67283],
                 [-3.72746, -0.284265], [2.07629, 1.99902], [-3.12698, -0.96353], [4.02254, 3.41521], [-0.963391, -3.2143], [0.315255,
                 0.593049], [1.57006, 1.80436], [4.60957, -2.86325]];
    assert_equal(sort(hull(rand75_2d)),[5,7,23,33,36,42,56,60,62,64]);

    rand10_2d_rot = rot([22,44,12], p=path3d(rand10_2d));
    assert_equal(sort(hull(rand10_2d_rot)), [1,2,5,8,9]);

    rand75_2d_rot = rot([122,-44,32], p=path3d(rand75_2d));
    assert_equal(sort(hull(rand75_2d_rot)), [5,7,23,33,36,42,56,60,62,64]);

    testpoints_on_sphere = [ for(p = 
        [
            [1,PHI,0], [-1,PHI,0], [1,-PHI,0], [-1,-PHI,0],
            [0,1,PHI], [0,-1,PHI], [0,1,-PHI], [0,-1,-PHI],
            [PHI,0,1], [-PHI,0,1], [PHI,0,-1], [-PHI,0,-1]
        ])
        unit(p)
    ];
    assert_equal(standard_faces(hull(testpoints_on_sphere)),  
                 standard_faces([[8, 4, 0], [0, 4, 1], [4, 8, 5], [8, 2, 5], [2, 3, 5], [0, 1, 6], [3, 2, 7], [1, 4, 9], [4, 5, 9],
                 [5, 3, 9], [8, 0, 10], [2, 8, 10], [0, 6, 10], [6, 7, 10], [7, 2, 10], [6, 1, 11], [3, 7, 11], [7, 6, 11], [1, 9, 11], [9, 3, 11]]));

    rand10_3d = [[14.0893, -15.2751, 21.0843], [-14.1564, 17.5751, 3.32094], [17.4966, 12.1717, 18.0607], [24.5489, 9.64591, 10.4738], [-12.0233, -24.4368, 13.1614],
                 [6.24019, -18.4135, 24.9554], [11.9438, -15.9724, -22.6454], [11.6147, 7.56059, 7.5667], [-19.7491, 9.42769, 15.3419], [-10.3726, 16.3559, 3.38503]];
    assert_equal(standard_faces(hull(rand10_3d)),
                 standard_faces([[3, 6, 0], [1, 3, 2], [3, 0, 2], [6, 1, 4], [0, 6, 5], [6, 4, 5], [2, 0, 5], [1, 2, 8], [2, 5, 8], [4, 1, 8], [5, 4, 8], [6, 3, 9], [3, 1, 9], [1, 6, 9]]));

    rand25_3d = [[-20.5261, 14.5058, -11.6349], [16.4625, 20.1316, 12.9816], [-14.0268, 5.58802, 17.686], [-5.47944, 16.2501,
                 5.3086], [20.2168, -11.8466, 12.4598], [14.4633, -15.1479, 4.82151], [12.7897, 5.25704, 19.6205], [11.2456,
                 18.2794, -3.47074], [-1.87665, 22.9852, 1.99367], [-15.6052, -2.11009, 14.0096], [-10.7389, -14.569,
                 5.6121], [24.5965, 17.9039, 20.8313], [-13.7054, 13.3362, 1.50374], [10.1111, -23.1494, 19.9305], [14.154,
                 19.6682, -0.170182], [-22.6438, 22.7429, -0.776773], [-9.75056, 17.8896, -8.04152], [23.1746, 20.5475,
                 22.6957], [-10.5356, -4.32407, -7.0911], [2.20779, -8.30749, 6.87185], [23.2643, 2.64462, -19.0087],
                 [24.4055, 24.4504, 23.4777], [-3.84086, -6.98473, -10.2889], [0.178043, -16.07, 16.8081], [-8.86482,
                 -12.8256, 14.7418], [11.1759, -11.5614, -11.643], [7.16751, 13.9344, -19.1675], [2.26602, -10.5374,
                 0.125718], [-13.9053, 11.1143, -21.9289], [24.9018, -23.5307, -21.4684], [-13.6609, -19.6495, -8.91583],
                 [-16.5393, -22.4105, -6.91617], [-4.11378, -3.14362, -5.6881], [7.50883, -17.5284, -0.0615319], [-7.41739,
                 0.0721313, -7.47111], [22.6975, -7.99655, 14.0555], [-13.3644, 9.26993, 20.858], [-13.6889, 16.7462,
                 -14.5836], [16.5137, 3.90703, -5.49396], [-6.75614, -11.1444, -24.5309], [22.9868, 10.0028, 12.2866],
                 [-4.81079, -0.967785, -10.4726], [-0.949023, 23.1441, -2.08208], [16.1256, -8.2295, -24.0113], [6.45274,
                 -7.21416, 23.1409], [22.8274, 1.07038, 19.1756], [-10.6256, -10.0112, -6.12274], [6.29254, -7.81875,
                 -24.4037], [22.8538, 8.78163, -6.82567], [-1.96142, 19.1728, -1.726]];
    assert_equal(sort(hull(rand25_3d)),sort([[21, 29, 11], [29, 21, 20], [21, 14, 20], [20, 14, 26], [15, 0, 28], [13, 29, 31], [0, 15,
                                 31], [15, 9, 31], [9, 24, 31], [24, 13, 31], [28, 0, 31], [11, 29, 35], [29, 13, 35], [15,
                                 21, 36], [9, 15, 36], [24, 9, 36], [13, 24, 36], [15, 28, 37], [28, 26, 37], [28, 31, 39],
                                 [31, 29, 39], [14, 21, 42], [21, 15, 42], [26, 14, 42], [15, 37, 42], [37, 26, 42], [29, 20,
                                 43], [39, 29, 43], [20, 26, 43], [26, 28, 43], [21, 13, 44], [13, 36, 44], [36, 21, 44],
                                 [21, 11, 45], [11, 35, 45], [13, 21, 45], [35, 13, 45], [28, 39, 47], [39, 43, 47], [43, 28, 47]]));

    /*  // Inconsistently treats coplanar faces: sometimes face center vertex is included in output, sometimes not
    test_cube_3d = [for(x=[1:3], y=[1:3], z=[1:3]) [x,y,z]];
    assert_equal(hull(test_cube_3d),  [[3, 2, 0], [2, 3, 4], [26, 2, 5], [2, 4, 5], [4, 3, 6], [5, 4, 6], [5, 6, 7], [6, 26, 7], [26, 5, 8],
                                       [5, 7, 8], [7, 26, 8], [0, 2, 9], [3, 0, 9], [6, 3, 9], [9, 2, 10], [2, 26, 11], [10, 2, 11], [6, 9, 12],
                                       [26, 6, 15], [6, 12, 15], [9, 10, 18], [10, 11, 18], [12, 9, 18], [15, 12, 18], [26, 18, 19], [18, 11, 19],
                                       [11, 26, 20], [26, 19, 20], [19, 11, 20], [15, 18, 21], [18, 26, 21], [26, 15, 24], [15, 21, 24], [21, 26, 24]]);
                                       echo(len=len(hull(test_cube_3d)));
    */                                   
}
test_hull();


module test_hull2d_path() {
    assert_equal(hull([[3,4],[5,5]]), [0,1]);
    assert_equal(hull([[3,4,1],[5,5,3]]), [0,1]);

    test_collinear_2d = let(u = unit([5,3]))    [ for(i = [9,2,3,4,5,7,12,15,13]) i * u ];
    assert_equal(sort(hull(test_collinear_2d)), [1,7]);
    test_collinear_3d = let(u = unit([5,3,2]))    [ for(i = [9,2,3,4,5,7,12,15,13]) i * u ];
    assert_equal(sort(hull(test_collinear_3d)), [1,7]);

    rand10_2d = [[1.55356, -1.98965], [4.23157, -0.947788], [-4.06193, -1.55463],
                 [1.23889, -3.73133], [-1.02637, -4.0155], [4.26806, -4.61909],
                 [3.59556, -3.1574], [-2.77776, -4.21857], [-3.66253,-4.34458], [1.82324, 0.102025]];
    assert_equal(sort(hull(rand10_2d)), [1,2,5,8,9]);

    rand75_2d = [[-3.14743, -3.28139], [0.15343, -0.370249], [0.082565, 3.95939], [-2.56925, -3.16262], [-1.59463, 4.20893],
                 [-4.90744, -1.21374], [-1.0819, -1.93703], [-3.72723, -3.0744], [-3.34339, 1.53535], [3.15803, -0.307388], [4.23289,
                 4.46259], [1.73624, 1.38918], [3.72087, -1.55028], [1.2604, 2.30502], [-0.966431, 1.673], [-3.26866, -0.531443], [1.52605,
                 0.991804], [-1.26305, 1.0737], [-4.31943, 4.11932], [0.488101, 0.0425981], [1.0233, -0.723037], [-4.73406, 2.14568],
                 [-4.75915, 3.83262], [4.90999, -2.76668], [1.91971, -3.8604], [4.38594, -0.761767], [-0.352984, 1.55291], [2.02714,
                 -0.340099], [1.76052, 2.09196], [-1.27485, -4.39477], [4.36364, 3.84964], [0.593612, -4.00028], [3.06833, -3.67117],
                 [4.26834, -4.21213], [4.60226, -0.120432], [-2.45646, 2.60327], [-4.79461, 3.83724], [-3.29755, 0.760159], [0.218423,
                 4.1687], [-0.115829, -2.06242], [-3.96188, 3.21568], [4.3018, -2.5299], [-4.41694, 4.75173], [-3.8393, 2.82212], [-1.14268,
                 1.80751], [2.05805, 1.68593], [-3.0159, -2.91139], [-1.44828, -1.93564], [-0.265887, 0.519893], [-0.457361, -0.610096],
                 [-0.426359, -2.37315], [-3.1018, 2.31141], [0.179141, -3.56242], [-0.491786, 0.813055], [-3.28502, -1.18933], [0.0914813,
                 2.16122], [4.5777, 4.83972], [-1.07096, 2.74992], [-0.698689, 3.9032], [-1.21809, -1.54434], [3.14457, 4.92302], [-4.63176,
                 2.81952], [4.84414, 4.63699], [2.4259, -0.747268], [-1.52088, -4.58305], [1.6961, -3.73678], [-0.483003, -3.67283],
                 [-3.72746, -0.284265], [2.07629, 1.99902], [-3.12698, -0.96353], [4.02254, 3.41521], [-0.963391, -3.2143], [0.315255,
                 0.593049], [1.57006, 1.80436], [4.60957, -2.86325]];
    assert_equal(sort(hull(rand75_2d)),[5,7,23,33,36,42,56,60,62,64]);

    rand10_2d_rot = rot([22,44,12], p=path3d(rand10_2d));
    assert_equal(sort(hull(rand10_2d_rot)), [1,2,5,8,9]);

    rand75_2d_rot = rot([122,-44,32], p=path3d(rand75_2d));
    assert_equal(sort(hull(rand75_2d_rot)), [5,7,23,33,36,42,56,60,62,64]);
}
test_hull2d_path();


module test_hull3d_faces() {
    testpoints_on_sphere = [ for(p = 
        [
            [1,PHI,0], [-1,PHI,0], [1,-PHI,0], [-1,-PHI,0],
            [0,1,PHI], [0,-1,PHI], [0,1,-PHI], [0,-1,-PHI],
            [PHI,0,1], [-PHI,0,1], [PHI,0,-1], [-PHI,0,-1]
        ])
        unit(p)
    ];
    assert_equal(standard_faces(hull(testpoints_on_sphere)),  
                 standard_faces([[8, 4, 0], [0, 4, 1], [4, 8, 5], [8, 2, 5], [2, 3, 5], [0, 1, 6], [3, 2, 7], [1, 4, 9], [4, 5, 9],
                 [5, 3, 9], [8, 0, 10], [2, 8, 10], [0, 6, 10], [6, 7, 10], [7, 2, 10], [6, 1, 11], [3, 7, 11], [7, 6, 11], [1, 9, 11], [9, 3, 11]]));

    rand10_3d = [[14.0893, -15.2751, 21.0843], [-14.1564, 17.5751, 3.32094], [17.4966, 12.1717, 18.0607], [24.5489, 9.64591, 10.4738], [-12.0233, -24.4368, 13.1614],
                 [6.24019, -18.4135, 24.9554], [11.9438, -15.9724, -22.6454], [11.6147, 7.56059, 7.5667], [-19.7491, 9.42769, 15.3419], [-10.3726, 16.3559, 3.38503]];
    assert_equal(standard_faces(hull(rand10_3d)),
                 standard_faces([[3, 6, 0], [1, 3, 2], [3, 0, 2], [6, 1, 4], [0, 6, 5], [6, 4, 5], [2, 0, 5], [1, 2, 8], [2, 5, 8], [4, 1, 8], [5, 4, 8], [6, 3, 9], [3, 1, 9], [1, 6, 9]]));

    rand25_3d = [[-20.5261, 14.5058, -11.6349], [16.4625, 20.1316, 12.9816], [-14.0268, 5.58802, 17.686], [-5.47944, 16.2501,
                 5.3086], [20.2168, -11.8466, 12.4598], [14.4633, -15.1479, 4.82151], [12.7897, 5.25704, 19.6205], [11.2456,
                 18.2794, -3.47074], [-1.87665, 22.9852, 1.99367], [-15.6052, -2.11009, 14.0096], [-10.7389, -14.569,
                 5.6121], [24.5965, 17.9039, 20.8313], [-13.7054, 13.3362, 1.50374], [10.1111, -23.1494, 19.9305], [14.154,
                 19.6682, -0.170182], [-22.6438, 22.7429, -0.776773], [-9.75056, 17.8896, -8.04152], [23.1746, 20.5475,
                 22.6957], [-10.5356, -4.32407, -7.0911], [2.20779, -8.30749, 6.87185], [23.2643, 2.64462, -19.0087],
                 [24.4055, 24.4504, 23.4777], [-3.84086, -6.98473, -10.2889], [0.178043, -16.07, 16.8081], [-8.86482,
                 -12.8256, 14.7418], [11.1759, -11.5614, -11.643], [7.16751, 13.9344, -19.1675], [2.26602, -10.5374,
                 0.125718], [-13.9053, 11.1143, -21.9289], [24.9018, -23.5307, -21.4684], [-13.6609, -19.6495, -8.91583],
                 [-16.5393, -22.4105, -6.91617], [-4.11378, -3.14362, -5.6881], [7.50883, -17.5284, -0.0615319], [-7.41739,
                 0.0721313, -7.47111], [22.6975, -7.99655, 14.0555], [-13.3644, 9.26993, 20.858], [-13.6889, 16.7462,
                 -14.5836], [16.5137, 3.90703, -5.49396], [-6.75614, -11.1444, -24.5309], [22.9868, 10.0028, 12.2866],
                 [-4.81079, -0.967785, -10.4726], [-0.949023, 23.1441, -2.08208], [16.1256, -8.2295, -24.0113], [6.45274,
                 -7.21416, 23.1409], [22.8274, 1.07038, 19.1756], [-10.6256, -10.0112, -6.12274], [6.29254, -7.81875,
                 -24.4037], [22.8538, 8.78163, -6.82567], [-1.96142, 19.1728, -1.726]];
    assert_equal(sort(hull(rand25_3d)), sort([[21, 29, 11], [29, 21, 20], [21, 14, 20], [20, 14, 26], [15, 0, 28], [13, 29, 31], [0, 15,
                                 31], [15, 9, 31], [9, 24, 31], [24, 13, 31], [28, 0, 31], [11, 29, 35], [29, 13, 35], [15,
                                 21, 36], [9, 15, 36], [24, 9, 36], [13, 24, 36], [15, 28, 37], [28, 26, 37], [28, 31, 39],
                                 [31, 29, 39], [14, 21, 42], [21, 15, 42], [26, 14, 42], [15, 37, 42], [37, 26, 42], [29, 20,
                                 43], [39, 29, 43], [20, 26, 43], [26, 28, 43], [21, 13, 44], [13, 36, 44], [36, 21, 44],
                                 [21, 11, 45], [11, 35, 45], [13, 21, 45], [35, 13, 45], [28, 39, 47], [39, 43, 47], [43, 28, 47]]));
}
test_hull3d_faces();



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
