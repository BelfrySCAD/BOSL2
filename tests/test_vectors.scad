include <../std.scad>


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


module test_vfloor() {
    assert_equal(vfloor([2.0, 3.14, 18.9, 7]), [2,3,18,7]);
    assert_equal(vfloor([-2.0, -3.14, -18.9, -7]), [-2,-4,-19,-7]);
}
test_vfloor();


module test_vceil() {
    assert_equal(vceil([2.0, 3.14, 18.9, 7]), [2,4,19,7]);
    assert_equal(vceil([-2.0, -3.14, -18.9, -7]), [-2,-3,-18,-7]);
}
test_vceil();


module test_vmul() {
    assert_equal(vmul([3,4,5], [8,7,6]), [24,28,30]);
    assert_equal(vmul([1,2,3], [4,5,6]), [4,10,18]);
    assert_equal(vmul([[1,2,3],[4,5,6],[7,8,9]], [[4,5,6],[3,2,1],[5,9,3]]), [32,28,134]);
}
test_vmul();


module test_vdiv() {
    assert(vdiv([24,28,30], [8,7,6]) == [3, 4, 5]);
}
test_vdiv();


module test_vabs() {
    assert(vabs([2,4,8]) == [2,4,8]);
    assert(vabs([-2,-4,-8]) == [2,4,8]);
    assert(vabs([-2,4,8]) == [2,4,8]);
    assert(vabs([2,-4,8]) == [2,4,8]);
    assert(vabs([2,4,-8]) == [2,4,8]);
}
test_vabs();

include <../strings.scad>
module test_vang() {
    assert(vang([1,0])==0);
    assert(vang([0,1])==90);
    assert(vang([-1,0])==180);
    assert(vang([0,-1])==-90);
    assert(vang([1,1])==45);
    assert(vang([-1,1])==135);
    assert(vang([1,-1])==-45);
    assert(vang([-1,-1])==-135);
    assert(vang([0,0,1])==[0,90]);
    assert(vang([0,1,1])==[90,45]);
    assert(vang([0,1,-1])==[90,-45]);
    assert(vang([1,0,0])==[0,0]);
    assert(vang([0,1,0])==[90,0]);
    assert(vang([0,-1,0])==[-90,0]);
    assert(vang([-1,0,0])==[180,0]);
    assert(vang([1,0,1])==[0,45]);
    assert(vang([0,1,1])==[90,45]);
    assert(vang([0,-1,1])==[-90,45]);
    assert(approx(vang([1,1,1]),[45, 35.2643896828]));
}
test_vang();


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


cube();


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
