include<../std.scad>

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



module test_union() {
  R1 = [square(10,center=true), square(9,center=true)];
  R2 = [square(9,center=true)];
  assert(are_regions_equal(union(R1,R2), [square(10,center=true)]));
}
test_union();


module test_intersection() {
  R1 = [square(10,center=true), square(9,center=true)];
  R6 = [square(9.5,center=true), square(9,center=true)];
  assert(are_regions_equal(intersection(R6,R1), R6));
  assert(are_regions_equal(intersection(R1,R6), R6));
}
test_intersection();


module test_difference() {
  R5 = [square(10,center=true), square(9,center=true),square(4,center=true)];
  R4 = [square(9,center=true), square(3,center=true)];
  assert(are_regions_equal(difference(R5,R4),
                         [square(10,center=true), square(9, center=true), square(3,center=true)]));

  pathA = [
    [-9,12], [-6,2], [-3,12], [0,2], [3,10], [5,10], [19,-4], [-8,-4], [-12,0]
  ];

  pathB = [
    [-12,8], [7,8], [9,6], [7,5], [-3,5], [-5,-6], [-2,-6], [0,-4],
    [6,-4], [2,-8], [-7,-8], [-15,0]
  ];


  right=[[[-10, 8], [-9, 12], [-7.8, 8]], [[0, -4], [-4.63636363636, -4], [-3, 5], [-0.9, 5], [0, 2], [1.125, 5], [7, 5], [9, 6], [19, -4], [6, -4]], [[-4.2, 8], [-1.8, 8], [-3, 12]], [[2.25, 8], [3, 10], [5, 10], [7, 8]]];
  assert(are_regions_equal(difference(pathA,pathB),right));


}
test_difference();



