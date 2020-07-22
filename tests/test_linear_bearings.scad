include <../std.scad>
include <../linear_bearings.scad>


module test_get_lmXuu_bearing_diam() {
    assert_equal(get_lmXuu_bearing_diam(4), 8);
    assert_equal(get_lmXuu_bearing_diam(8), 15);
    assert_equal(get_lmXuu_bearing_diam(10), 19);
    assert_equal(get_lmXuu_bearing_diam(25), 40);
    assert_equal(get_lmXuu_bearing_diam(50), 80);
    assert_equal(get_lmXuu_bearing_diam(100), 150);
}
test_get_lmXuu_bearing_diam();


module test_get_lmXuu_bearing_length() {
    assert_equal(get_lmXuu_bearing_length(4), 12);
    assert_equal(get_lmXuu_bearing_length(8), 24);
    assert_equal(get_lmXuu_bearing_length(10), 29);
    assert_equal(get_lmXuu_bearing_length(25), 59);
    assert_equal(get_lmXuu_bearing_length(50), 100);
    assert_equal(get_lmXuu_bearing_length(100), 175);
}
test_get_lmXuu_bearing_length();



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
