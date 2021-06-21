include <../std.scad>


//the commented lines are for tests to be written
//the tests are ordered as they appear in geometry.scad



test_point_on_segment2d();
test_point_left_of_line2d();
test_collinear();
test_point_line_distance();
test_point_segment_distance();
test_segment_distance();
test_line_normal();
test_line_intersection();
//test_line_ray_intersection();
test_line_segment_intersection();
//test_ray_intersection();
//test_ray_segment_intersection();
test_segment_intersection();
test_line_closest_point();
//test_ray_closest_point();
test_segment_closest_point();
test_line_from_points();
test_tri_calc();
//test_hyp_opp_to_adj();
//test_hyp_ang_to_adj();
//test_opp_ang_to_adj();
//test_hyp_adj_to_opp();
//test_hyp_ang_to_opp();
//test_adj_ang_to_opp();
//test_adj_opp_to_hyp();
//test_adj_ang_to_hyp();
//test_opp_ang_to_hyp();
//test_hyp_adj_to_ang();
//test_hyp_opp_to_ang();
//test_adj_opp_to_ang();
test_triangle_area();
test_plane3pt();
test_plane3pt_indexed();
test_plane_from_normal();
test_plane_from_points();
test_plane_from_polygon();
test_plane_normal();
test_plane_offset();
test_projection_on_plane();
test_plane_point_nearest_origin();
test_point_plane_distance();

test__general_plane_line_intersection();
test_plane_line_angle();
test_normalize_plane();
test_plane_line_intersection();
test_polygon_line_intersection();
test_plane_intersection();
test_coplanar();
test_points_on_plane();
test_in_front_of_plane();
test_circle_2tangents();
test_circle_3points();
test_circle_point_tangents();

test_noncollinear_triple();
test_pointlist_bounds();
test_closest_point();
test_furthest_point();
test_polygon_area();
test_is_convex_polygon();
test_polygon_shift();
test_polygon_shift_to_closest_point();
test_reindex_polygon();
test_align_polygon();
test_centroid();
test_point_in_polygon();
test_polygon_is_clockwise();
test_clockwise_polygon();
test_ccw_polygon();
test_reverse_polygon();
//test_polygon_normal();
//test_split_polygons_at_each_x();
//test_split_polygons_at_each_y();
//test_split_polygons_at_each_z();

//tests to migrate to other files
test_is_path();
test_is_closed_path();
test_close_path();
test_cleanup_path();
test_simplify_path();
test_simplify_path_indexed();
test_is_region();
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


module test_normalize_plane(){
    plane = rands(-5,5,4,seed=333)+[10,0,0,0];
    plane2 = normalize_plane(plane);
    assert_approx(norm(point3d(plane2)),1);
    assert_approx(plane*plane2[3],plane2*plane[3]);
}
*test_normalize_plane();

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


module test_plane_point_nearest_origin(){
    point = rands(-1,1,3)+[2,0,0]; // a non zero vector
    plane = [ each point, point*point]; // a plane containing `point`
    info = info_str([["point = ",point],["plane = ",plane]]);
    assert_approx(plane_point_nearest_origin(plane),point,info);
    assert_approx(plane_point_nearest_origin([each point,5]),5*unit(point)/norm(point),info);
}
test_plane_point_nearest_origin();


module test_plane_offset(){
    plane = rands(-1,1,4)+[2,0,0,0]; // a valid plane
    info = info_str([["plane = ",plane]]);
    assert_approx(plane_offset(plane), normalize_plane(plane)[3],info);
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


module test_points_on_plane() {
    pts     = [for(i=[0:40]) rands(-1,1,3) ];
    dir     = rands(-10,10,3);
    normal0 = [1,2,3];
    ang     = rands(0,360,1)[0];
    normal  = rot(a=ang,p=normal0);
    plane   = [each normal, normal*dir];
    prj_pts = projection_on_plane(plane,pts);
    info = info_str([["pts = ",pts],["dir = ",dir],["ang = ",ang]]);
    assert(points_on_plane(prj_pts,plane),info);
    assert(!points_on_plane(concat(pts,[normal-dir]),plane),info);
}
*test_points_on_plane();

module test_projection_on_plane(){
    ang     = rands(0,360,1)[0];
    dir     = rands(-10,10,3);
    normal0 = unit([1,2,3]);
    normal  = rot(a=ang,p=normal0);
    plane0  = [each normal0, 0];
    plane   = [each normal,  0];
    planem  = [each normal, normal*dir];
    pts     = [for(i=[1:10]) rands(-1,1,3)];
    info = info_str([["ang = ",ang],["dir = ",dir]]);
    assert_approx( projection_on_plane(plane,pts),
                   projection_on_plane(plane,projection_on_plane(plane,pts)),info);
    assert_approx( projection_on_plane(plane,pts),
                   rot(a=ang,p=projection_on_plane(plane0,rot(a=-ang,p=pts))),info);    
    assert_approx( move((-normal*dir)*normal,p=projection_on_plane(planem,pts)),
                   projection_on_plane(plane,pts),info);
    assert_approx( move((normal*dir)*normal,p=projection_on_plane(plane,pts)),
                   projection_on_plane(planem,pts),info);
}
*test_projection_on_plane();

module test_line_from_points() {
    assert_approx(line_from_points([[1,0],[0,0],[-1,0]]),[[-1,0],[1,0]]);
    assert_approx(line_from_points([[1,1],[0,1],[-1,1]]),[[-1,1],[1,1]]);
    assert(line_from_points([[1,1],[0,1],[-1,0]])==undef);
    assert(line_from_points([[1,1],[0,1],[-1,0]],fast=true)== [[-1,0],[1,1]]);
}
*test_line_from_points();

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
*test_point_on_segment2d();


module test_point_left_of_line2d() {
    assert(point_left_of_line2d([ -3,  0], [[-10,-10], [10,10]]) > 0);
    assert(point_left_of_line2d([  0,  0], [[-10,-10], [10,10]]) == 0);
    assert(point_left_of_line2d([  3,  0], [[-10,-10], [10,10]]) < 0);
}
*test_point_left_of_line2d();

module test_collinear() {
    assert(collinear([-10,-10], [-15, -16], [10,10]) == false);
    assert(collinear([[-10,-10], [-15, -16], [10,10]]) == false);
    assert(collinear([-10,-10], [-15, -15], [10,10]) == true);
    assert(collinear([[-10,-10], [-15, -15], [10,10]]) == true);
    assert(collinear([-10,-10], [ -3,   0], [10,10]) == false);
    assert(collinear([-10,-10], [  0,   0], [10,10]) == true);
    assert(collinear([-10,-10], [  3,   0], [10,10]) == false);
    assert(collinear([-10,-10], [ 15,  15], [10,10]) == true);
    assert(collinear([-10,-10], [ 15,  16], [10,10]) == false);
}
*test_collinear();


module test_point_line_distance() {
    assert_approx(point_line_distance([1,1,1], [[-10,-10,-10], [10,10,10]]), 0);
    assert_approx(point_line_distance([-1,-1,-1], [[-10,-10,-10], [10,10,10]]), 0);
    assert_approx(point_line_distance([1,-1,0], [[-10,-10,-10], [10,10,10]]), sqrt(2));
    assert_approx(point_line_distance([8,-8,0], [[-10,-10,-10], [10,10,10]]), 8*sqrt(2));
}
*test_point_line_distance();


module test_point_segment_distance() {
    assert_approx(point_segment_distance([3,8], [[-10,0], [10,0]]), 8);
    assert_approx(point_segment_distance([14,3], [[-10,0], [10,0]]), 5);
}
*test_point_segment_distance();


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
}
*test_line_intersection();


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
*test_segment_intersection();


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
*test_line_segment_intersection();


module test_line_closest_point() {
    assert(approx(line_closest_point([[-10,-10], [10,10]], [1,-1]), [0,0]));
    assert(approx(line_closest_point([[-10,-10], [10,10]], [-1,1]), [0,0]));
    assert(approx(line_closest_point([[-10,-20], [10,20]], [1,2]+[-2,1]), [1,2]));
    assert(approx(line_closest_point([[-10,-20], [10,20]], [1,2]+[2,-1]), [1,2]));
    assert(approx(line_closest_point([[-10,-20], [10,20]], [13,31]), [15,30]));
}
*test_line_closest_point();


module test_segment_closest_point() {
    assert(approx(segment_closest_point([[-10,-10], [10,10]], [1,-1]), [0,0]));
    assert(approx(segment_closest_point([[-10,-10], [10,10]], [-1,1]), [0,0]));
    assert(approx(segment_closest_point([[-10,-20], [10,20]], [1,2]+[-2,1]), [1,2]));
    assert(approx(segment_closest_point([[-10,-20], [10,20]], [1,2]+[2,-1]), [1,2]));
    assert(approx(segment_closest_point([[-10,-20], [10,20]], [13,31]), [10,20]));
    assert(approx(segment_closest_point([[-10,-20], [10,20]], [15,25]), [10,20]));
}
*test_segment_closest_point();

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


module test_tri_calc() {
    sides = rands(1,100,100,seed_value=8888);
    for (p=pair(sides,true)) {
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
*test_tri_calc();


module test_tri_functions() {
    sides = rands(1,100,100,seed_value=8181);
    for (p = pair(sides,true)) {
        adj = p.x;
        opp = p.y;
        hyp = norm([opp,adj]);
        ang = atan2(opp,adj);
        assert_approx(hyp_opp_to_adj(hyp,opp), adj);
        assert_approx(hyp_ang_to_adj(hyp,ang), adj);
        assert_approx(opp_ang_to_adj(opp,ang), adj);
        assert_approx(hyp_adj_to_opp(hyp,adj), opp);
        assert_approx(hyp_ang_to_opp(hyp,ang), opp);
        assert_approx(adj_ang_to_opp(adj,ang), opp);
        assert_approx(adj_opp_to_hyp(adj,opp), hyp);
        assert_approx(adj_ang_to_hyp(adj,ang), hyp);
        assert_approx(opp_ang_to_hyp(opp,ang), hyp);
        assert_approx(hyp_adj_to_ang(hyp,adj), ang);
        assert_approx(hyp_opp_to_ang(hyp,opp), ang);
        assert_approx(adj_opp_to_ang(adj,opp), ang);
    }
}
*test_tri_functions();


module test_hyp_opp_to_adj() nil();  // Covered in test_tri_functions()
module test_hyp_ang_to_adj() nil();  // Covered in test_tri_functions()
module test_opp_ang_to_adj() nil();  // Covered in test_tri_functions()
module test_hyp_adj_to_opp() nil();  // Covered in test_tri_functions()
module test_hyp_ang_to_opp() nil();  // Covered in test_tri_functions()
module test_adj_ang_to_opp() nil();  // Covered in test_tri_functions()
module test_adj_opp_to_hyp() nil();  // Covered in test_tri_functions()
module test_adj_ang_to_hyp() nil();  // Covered in test_tri_functions()
module test_opp_ang_to_hyp() nil();  // Covered in test_tri_functions()
module test_hyp_adj_to_ang() nil();  // Covered in test_tri_functions()
module test_hyp_opp_to_ang() nil();  // Covered in test_tri_functions()
module test_adj_opp_to_ang() nil();  // Covered in test_tri_functions()


module test_triangle_area() {
    assert(abs(triangle_area([0,0], [0,10], [10,0]) + 50) < EPSILON);
    assert(abs(triangle_area([0,0], [0,10], [0,15])) < EPSILON);
    assert(abs(triangle_area([0,0], [10,0], [0,10]) - 50) < EPSILON);
}
*test_triangle_area();


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
}
*test_polygon_line_intersection();


module test_coplanar() {
    assert(coplanar([ [5,5,1],[0,0,1],[-1,-1,1] ]) == false);
    assert(coplanar([ [5,5,1],[0,0,0],[-1,-1,1] ]) == true);
    assert(coplanar([ [0,0,0],[1,0,1],[1,1,1], [0,1,2] ]) == false);
    assert(coplanar([ [0,0,0],[1,0,1],[1,1,2], [0,1,1] ]) == true);
 }
*test_coplanar();


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
*test_in_front_of_plane();


module test_is_path() {
    assert(is_path([[1,2,3],[4,5,6]]));
    assert(is_path([[1,2,3],[4,5,6],[7,8,9]]));
    assert(!is_path(123));
    assert(!is_path("foo"));
    assert(!is_path(true));
    assert(!is_path([]));
    assert(!is_path([[]]));
    assert(!is_path([["foo","bar","baz"]]));
    assert(!is_path([[1,2,3]]));
    assert(!is_path([["foo","bar","baz"],["qux","quux","quuux"]]));
}
*test_is_path();


module test_is_closed_path() {
    assert(!is_closed_path([[1,2,3],[4,5,6],[1,8,9]]));
    assert(is_closed_path([[1,2,3],[4,5,6],[1,8,9],[1,2,3]]));
}
*test_is_closed_path();


module test_close_path() {
    assert(close_path([[1,2,3],[4,5,6],[1,8,9]]) == [[1,2,3],[4,5,6],[1,8,9],[1,2,3]]);
    assert(close_path([[1,2,3],[4,5,6],[1,8,9],[1,2,3]]) == [[1,2,3],[4,5,6],[1,8,9],[1,2,3]]);
}
*test_close_path();


module test_cleanup_path() {
    assert(cleanup_path([[1,2,3],[4,5,6],[1,8,9]]) == [[1,2,3],[4,5,6],[1,8,9]]);
    assert(cleanup_path([[1,2,3],[4,5,6],[1,8,9],[1,2,3]]) == [[1,2,3],[4,5,6],[1,8,9]]);
}
*test_cleanup_path();


module test_polygon_area() {
    assert(approx(polygon_area([[1,1],[-1,1],[-1,-1],[1,-1]]), 4));
    assert(approx(polygon_area(circle(r=50,$fn=1000),signed=true), -PI*50*50, eps=0.1));
    assert(approx(polygon_area(rot([13,27,75],
                               p=path3d(circle(r=50,$fn=1000),fill=23)),
                               signed=true), -PI*50*50, eps=0.1));
}
*test_polygon_area();


module test_is_convex_polygon() {
    assert(is_convex_polygon([[1,1],[-1,1],[-1,-1],[1,-1]]));
    assert(is_convex_polygon(circle(r=50,$fn=1000)));
    assert(is_convex_polygon(rot([50,120,30], p=path3d(circle(1,$fn=50)))));
    assert(!is_convex_polygon([[1,1],[0,0],[-1,1],[-1,-1],[1,-1]]));
    assert(!is_convex_polygon([for (i=[0:36]) let(a=-i*10) (10+i)*[cos(a),sin(a)]])); //   spiral 
}
*test_is_convex_polygon();


module test_polygon_shift() {
    path = [[1,1],[-1,1],[-1,-1],[1,-1]];
    assert(polygon_shift(path,1) == [[-1,1],[-1,-1],[1,-1],[1,1]]);
    assert(polygon_shift(path,2) == [[-1,-1],[1,-1],[1,1],[-1,1]]);
}
*test_polygon_shift();


module test_polygon_shift_to_closest_point() {
    path = [[1,1],[-1,1],[-1,-1],[1,-1]];
    assert(polygon_shift_to_closest_point(path,[1.1,1.1]) == [[1,1],[-1,1],[-1,-1],[1,-1]]);
    assert(polygon_shift_to_closest_point(path,[-1.1,1.1]) == [[-1,1],[-1,-1],[1,-1],[1,1]]);
    assert(polygon_shift_to_closest_point(path,[-1.1,-1.1]) == [[-1,-1],[1,-1],[1,1],[-1,1]]);
    assert(polygon_shift_to_closest_point(path,[1.1,-1.1]) == [[1,-1],[1,1],[-1,1],[-1,-1]]);
}
*test_polygon_shift_to_closest_point();


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
}
*test_align_polygon();


module test_noncollinear_triple() {
    assert(noncollinear_triple([[1,1],[2,2],[3,3],[4,4],[4,5],[5,6]]) == [0,5,3]);
    assert(noncollinear_triple([[1,1],[2,2],[8,3],[4,4],[4,5],[5,6]]) == [0,2,5]);
    u = unit([5,3]);
    assert_equal(noncollinear_triple([for(i = [2,3,4,5,7,12,15]) i * u], error=false),[]);
}
*test_noncollinear_triple();


module test_centroid() {
    $fn = 24;
    assert_approx(centroid(circle(d=100)), [0,0]);
    assert_approx(centroid(rect([40,60],rounding=10,anchor=LEFT)), [20,0]);
    assert_approx(centroid(rect([40,60],rounding=10,anchor=FWD)), [0,30]);
    poly = move([1,2.5,3.1],p=rot([12,49,24], p=path3d(circle(10,$fn=33))));
    assert_approx(centroid(poly), [1,2.5,3.1]);
}
*test_centroid();


module test_simplify_path() {
    path = [[-20,-20], [-10,-20], [0,-10], [10,0], [20,10], [20,20], [15,30]];
    assert(simplify_path(path) == [[-20,-20], [-10,-20], [20,10], [20,20], [15,30]]);
}
*test_simplify_path();


module test_simplify_path_indexed() {
    pts = [[10,0], [0,-10], [20,20], [20,10], [-20,-20], [15,30], [-10,-20]];
    path = [4,6,1,0,3,2,5];
    assert(simplify_path_indexed(pts, path) == [4,6,3,2,5]);
}
*test_simplify_path_indexed();


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


module test_pointlist_bounds() {
    pts = [
        [-53,27,12],
        [-63,97,36],
        [84,-32,-5],
        [63,-24,42],
        [23,57,-42]
    ];
    assert(pointlist_bounds(pts) == [[-63,-32,-42], [84,97,42]]);
    pts2d = [
        [-53,12],
        [-63,36],
        [84,-5],
        [63,42],
        [23,-42] 
    ];
    assert(pointlist_bounds(pts2d) == [[-63,-42],[84,42]]);
    pts5d = [
        [-53, 27, 12,-53, 12],
        [-63, 97, 36,-63, 36],
        [ 84,-32, -5, 84, -5], 
        [ 63,-24, 42, 63, 42], 
        [ 23, 57,-42, 23,-42]
    ];
    assert(pointlist_bounds(pts5d) == [[-63,-32,-42,-63,-42],[84,97,42,84,42]]);
    assert(pointlist_bounds([[3,4,5,6]]), [[3,4,5,6],[3,4,5,6]]);
}
*test_pointlist_bounds();


module test_closest_point() {
    ptlist = [for (i=count(100)) rands(-100,100,2,seed_value=8463+i)];
    testpts = [for (i=count(100)) rands(-100,100,2,seed_value=6834+i)];
    for (pt = testpts) {
        pidx = closest_point(pt,ptlist);
        dists = [for (p=ptlist) norm(pt-p)];
        mindist = min(dists);
        assert(mindist == dists[pidx]);
    }
}
*test_closest_point();


module test_furthest_point() {
    ptlist = [for (i=count(100)) rands(-100,100,2,seed_value=8463+i)];
    testpts = [for (i=count(100)) rands(-100,100,2,seed_value=6834+i)];
    for (pt = testpts) {
        pidx = furthest_point(pt,ptlist);
        dists = [for (p=ptlist) norm(pt-p)];
        mindist = max(dists);
        assert(mindist == dists[pidx]);
    }
}
*test_furthest_point();


module test_polygon_is_clockwise() {
    assert(polygon_is_clockwise([[-1,1],[1,1],[1,-1],[-1,-1]]));
    assert(!polygon_is_clockwise([[1,1],[-1,1],[-1,-1],[1,-1]]));
    assert(polygon_is_clockwise(circle(d=100)));
    assert(polygon_is_clockwise(square(100)));
}
*test_polygon_is_clockwise();


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


module test_is_region() {
    assert(is_region([circle(d=10),square(10)]));
    assert(is_region([circle(d=10),square(10),circle(d=50)]));
    assert(is_region([square(10)]));
    assert(!is_region([]));
    assert(!is_region(23));
    assert(!is_region(true));
    assert(!is_region("foo"));
}
*test_is_region();

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

// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
