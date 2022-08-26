include <../std.scad>
include <../screw_drive.scad>


module test_torx_diam() {
    assert_approx(torx_diam(10), 2.80);
    assert_approx(torx_diam(15), 3.35);
    assert_approx(torx_diam(20), 3.95);
    assert_approx(torx_diam(25), 4.50);
    assert_approx(torx_diam(30), 5.60);
    assert_approx(torx_diam(40), 6.75);
}
test_torx_diam();


module test_torx_depth() {
    assert_approx(torx_depth(10), 1.142);
    assert_approx(torx_depth(15), 1.2);
    assert_approx(torx_depth(20), 1.4);
    assert_approx(torx_depth(25), 1.61);
    assert_approx(torx_depth(30), 2.22);
    assert_approx(torx_depth(40), 2.63);
}
test_torx_depth();



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
