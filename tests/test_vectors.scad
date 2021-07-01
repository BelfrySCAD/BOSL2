include <../std.scad>

seed = floor(rands(0,10000,1)[0]);

module test_is_vector() {
    assert(is_vector([1,2,3]) == true);
    assert(is_vector([[1,2,3]]) == false);
    assert(is_vector([[1,2,3,4],[5,6,7,8]]) == false);
    assert(is_vector([[1,2,3,4],[5,6]]) == false);
    assert(is_vector(["foo"]) == false);
    assert(is_vector([]) == false);
    assert(is_vector(1) == false);
    assert(is_vector("foo") == false);
    assert(is_vector(true) == false);
    assert(is_vector([3,4,"foo"]) == false);
    assert(is_vector([3,4,[4,5]]) == false);
    assert(is_vector([3,4,undef]) == false);
    assert(is_vector(["foo","bar"]) == false);

    assert(is_vector([0,0,0],zero=true) == true);
    assert(is_vector([0,0,0],zero=false) == false);
    assert(is_vector([0,1,0],zero=true) == false);
    assert(is_vector([0,0,1],zero=false) == true);
    assert(is_vector([1,1,1],zero=false) == true);

    assert(is_vector([0,0,0],all_nonzero=true) == false);
    assert(is_vector([0,1,0],all_nonzero=true) == false);
    assert(is_vector([0,0,1],all_nonzero=true) == false);
    assert(is_vector([1,1,1],all_nonzero=true) == true);
    assert(is_vector([-1,1,1],all_nonzero=true) == true);
    assert(is_vector([-1,-1,-1],all_nonzero=true) == true);
}
test_is_vector();


module test_v_floor() {
    assert_equal(v_floor([2.0, 3.14, 18.9, 7]), [2,3,18,7]);
    assert_equal(v_floor([-2.0, -3.14, -18.9, -7]), [-2,-4,-19,-7]);
}
test_v_floor();


module test_v_ceil() {
    assert_equal(v_ceil([2.0, 3.14, 18.9, 7]), [2,4,19,7]);
    assert_equal(v_ceil([-2.0, -3.14, -18.9, -7]), [-2,-3,-18,-7]);
}
test_v_ceil();


module test_v_mul() {
    assert_equal(v_mul([3,4,5], [8,7,6]), [24,28,30]);
    assert_equal(v_mul([1,2,3], [4,5,6]), [4,10,18]);
    assert_equal(v_mul([[1,2,3],[4,5,6],[7,8,9]], [[4,5,6],[3,2,1],[5,9,3]]), [32,28,134]);
}
test_v_mul();


module test_v_div() {
    assert(v_div([24,28,30], [8,7,6]) == [3, 4, 5]);
}
test_v_div();


module test_v_abs() {
    assert(v_abs([2,4,8]) == [2,4,8]);
    assert(v_abs([-2,-4,-8]) == [2,4,8]);
    assert(v_abs([-2,4,8]) == [2,4,8]);
    assert(v_abs([2,-4,8]) == [2,4,8]);
    assert(v_abs([2,4,-8]) == [2,4,8]);
}
test_v_abs();

include <../strings.scad>
module test_v_theta() {
    assert_approx(v_theta([0,0]), 0);
    assert_approx(v_theta([1,0]), 0);
    assert_approx(v_theta([0,1]), 90);
    assert_approx(v_theta([-1,0]), 180);
    assert_approx(v_theta([0,-1]), -90);
    assert_approx(v_theta([1,1]), 45);
    assert_approx(v_theta([-1,1]), 135);
    assert_approx(v_theta([1,-1]), -45);
    assert_approx(v_theta([-1,-1]), -135);
    assert_approx(v_theta([0,0,1]), 0);
    assert_approx(v_theta([0,1,1]), 90);
    assert_approx(v_theta([0,1,-1]), 90);
    assert_approx(v_theta([1,0,0]), 0);
    assert_approx(v_theta([0,1,0]), 90);
    assert_approx(v_theta([0,-1,0]), -90);
    assert_approx(v_theta([-1,0,0]), 180);
    assert_approx(v_theta([1,0,1]), 0);
    assert_approx(v_theta([0,1,1]), 90);
    assert_approx(v_theta([0,-1,1]), -90);
    assert_approx(v_theta([1,1,1]), 45);
}
test_v_theta();


module test_unit() {
    assert(unit([10,0,0]) == [1,0,0]);
    assert(unit([0,10,0]) == [0,1,0]);
    assert(unit([0,0,10]) == [0,0,1]);
    assert(abs(norm(unit([10,10,10]))-1) < EPSILON);
    assert(abs(norm(unit([-10,-10,-10]))-1) < EPSILON);
    assert(abs(norm(unit([-10,0,0]))-1) < EPSILON);
    assert(abs(norm(unit([0,-10,0]))-1) < EPSILON);
    assert(abs(norm(unit([0,0,-10]))-1) < EPSILON);
}
test_unit();


module test_vector_angle() {
    vecs = [[10,0,0], [-10,0,0], [0,10,0], [0,-10,0], [0,0,10], [0,0,-10]];
    for (a=vecs, b=vecs) {
        if(a==b) {
            assert(vector_angle(a,b)==0);
            assert(vector_angle([a,b])==0);
        } else if(a==-b) {
            assert(vector_angle(a,b)==180);
            assert(vector_angle([a,b])==180);
        } else {
            assert(vector_angle(a,b)==90);
            assert(vector_angle([a,b])==90);
        }
    }
    assert(abs(vector_angle([10,10,0],[10,0,0])-45) < EPSILON);
    assert(abs(vector_angle([[10,10,0],[10,0,0]])-45) < EPSILON);
    assert(abs(vector_angle([11,11,1],[1,1,1],[11,-9,1])-90) < EPSILON);
    assert(abs(vector_angle([[11,11,1],[1,1,1],[11,-9,1]])-90) < EPSILON);
}
test_vector_angle();


module test_vector_axis() {
    assert(norm(vector_axis([10,0,0],[10,10,0]) - [0,0,1]) < EPSILON);
    assert(norm(vector_axis([[10,0,0],[10,10,0]]) - [0,0,1]) < EPSILON);
    assert(norm(vector_axis([10,0,0],[0,10,0]) - [0,0,1]) < EPSILON);
    assert(norm(vector_axis([[10,0,0],[0,10,0]]) - [0,0,1]) < EPSILON);
    assert(norm(vector_axis([0,10,0],[10,0,0]) - [0,0,-1]) < EPSILON);
    assert(norm(vector_axis([[0,10,0],[10,0,0]]) - [0,0,-1]) < EPSILON);
    assert(norm(vector_axis([0,0,10],[10,0,0]) - [0,1,0]) < EPSILON);
    assert(norm(vector_axis([[0,0,10],[10,0,0]]) - [0,1,0]) < EPSILON);
    assert(norm(vector_axis([10,0,0],[0,0,10]) - [0,-1,0]) < EPSILON);
    assert(norm(vector_axis([[10,0,0],[0,0,10]]) - [0,-1,0]) < EPSILON);
    assert(norm(vector_axis([10,0,10],[0,-10,0]) - [sin(45),0,-sin(45)]) < EPSILON);
    assert(norm(vector_axis([[10,0,10],[0,-10,0]]) - [sin(45),0,-sin(45)]) < EPSILON);
    assert(norm(vector_axis([11,1,11],[1,1,1],[1,-9,1]) - [sin(45),0,-sin(45)]) < EPSILON);
    assert(norm(vector_axis([[11,1,11],[1,1,1],[1,-9,1]]) - [sin(45),0,-sin(45)]) < EPSILON);
}
test_vector_axis();

module test_vector_search(){
    points = [for(i=[0:9], j=[0:9], k=[1:5]) [i,j,k] ];
    ind = vector_search([5,5,1],1,points);
    assert(ind== [225, 270, 275, 276, 280, 325]);
    assert([for(i=ind) if(norm(points[i]-[5,5,1])>1) i ]==[]);
    assert([for(i=idx(points)) if(norm(points[i]-[5,5,1])<=1) i]==sort(ind));
}
test_vector_search();

module test_vector_search_tree(){
    points1 = [ [0,1,2], [1,2,3], [2,3,4] ];
    tree1 = vector_search_tree(points1);
    assert(tree1 == [ points1, [[0,1,2]] ]);
    points2 = [for(i=[0:9], j=[0:9], k=[1:5]) [i,j,k] ];
    tree2 = vector_search_tree(points2);
    assert(tree2[0]==points2);
    ind = vector_search([5,5,1],1,tree2);
    assert(ind== [225, 270, 275, 276, 280, 325]);
    rpts = array_group(rands(0,10,50*3,seed=seed),3);
    rtree = vector_search_tree(rpts);
    radius = 3;
    found0 = vector_search([0,0,0],radius,rpts);
    found1 = vector_search([0,0,0],radius,rtree);
    found2 = [for(i=idx(rpts)) if(norm(rpts[i])<=radius) i];
    assert(sort(found0)==sort(found1), str("Seed = ",seed));
    assert(sort(found1)==sort(found2), str("Seed = ",seed));
}
test_vector_search_tree();

module test_vector_nearest(){
    points = [for(i=[0:9], j=[0:9], k=[1:5]) [i,j,k] ];
    ind1 = vector_nearest([5,5,1], 4, points);
    assert(ind1==[275, 225, 270, 276]);
    pts = array_group(rands(0,10,50*3,seed=seed),3);
    tree = vector_search_tree(pts);
    nearest = vector_nearest([0,0,0], 4, tree);
    closest = select(sortidx([for(p=pts) norm(p)]), [0:3]);
    assert(closest==nearest,str("Seed = ",seed));
}
test_vector_nearest();

cube();


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
