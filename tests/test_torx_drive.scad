include <../std.scad>
include <../torx_drive.scad>


module test_torx_outer_diam() {
    assert_approx(torx_outer_diam(10), 2.80);
    assert_approx(torx_outer_diam(15), 3.35);
    assert_approx(torx_outer_diam(20), 3.95);
    assert_approx(torx_outer_diam(25), 4.50);
    assert_approx(torx_outer_diam(30), 5.60);
    assert_approx(torx_outer_diam(40), 6.75);
}
test_torx_outer_diam();


module test_torx_inner_diam() {
    assert_approx(torx_inner_diam(10), 2.05);
    assert_approx(torx_inner_diam(15), 2.40);
    assert_approx(torx_inner_diam(20), 2.85);
    assert_approx(torx_inner_diam(25), 3.25);
    assert_approx(torx_inner_diam(30), 4.05);
    assert_approx(torx_inner_diam(40), 4.85);
}
test_torx_inner_diam();


module test_torx_depth() {
    assert_approx(torx_depth(10), 3.56);
    assert_approx(torx_depth(15), 3.81);
    assert_approx(torx_depth(20), 4.07);
    assert_approx(torx_depth(25), 4.45);
    assert_approx(torx_depth(30), 4.95);
    assert_approx(torx_depth(40), 5.59);
}
test_torx_depth();


module test_torx_tip_radius() {
    assert_approx(torx_tip_radius(10), 0.229);
    assert_approx(torx_tip_radius(15), 0.267);
    assert_approx(torx_tip_radius(20), 0.305);
    assert_approx(torx_tip_radius(25), 0.375);
    assert_approx(torx_tip_radius(30), 0.451);
    assert_approx(torx_tip_radius(40), 0.546);
}
test_torx_tip_radius();


module test_torx_rounding_radius() {
    assert_approx(torx_rounding_radius(10), 0.598);
    assert_approx(torx_rounding_radius(15), 0.716);
    assert_approx(torx_rounding_radius(20), 0.859);
    assert_approx(torx_rounding_radius(25), 0.920);
    assert_approx(torx_rounding_radius(30), 1.194);
    assert_approx(torx_rounding_radius(40), 1.428);
}
test_torx_rounding_radius();



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
