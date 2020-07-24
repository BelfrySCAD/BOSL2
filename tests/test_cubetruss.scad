include <../std.scad>
include <../cubetruss.scad>


module test_cubetruss_dist() {
    assert(cubetruss_dist(5,1,size=30,strut=3) == 138);
    assert(cubetruss_dist(3,2,size=30,strut=3) == 87);
    assert(cubetruss_dist(5,1,size=20,strut=2) == 92);
    assert(cubetruss_dist(3,2,size=20,strut=2) == 58);
}
test_cubetruss_dist();


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
