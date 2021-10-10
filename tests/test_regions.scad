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
}
test_difference();



