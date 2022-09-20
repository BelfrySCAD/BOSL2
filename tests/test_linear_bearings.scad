include <../std.scad>
include <../linear_bearings.scad>


module test_lmXuu_info() {
    assert_equal(lmXuu_info(4), [8, 12]);
    assert_equal(lmXuu_info(8), [15, 24]);
    assert_equal(lmXuu_info(10), [19, 29]);
    assert_equal(lmXuu_info(25), [40, 59]);
    assert_equal(lmXuu_info(50), [80, 100]);
    assert_equal(lmXuu_info(100), [150, 175]);
}
test_lmXuu_info();


// vim: expandtab shiftwidth=4 softtabstop=4 nowrap
