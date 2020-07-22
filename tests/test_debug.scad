include <../std.scad>


module test_standard_anchors() {
    assert_equal(standard_anchors(), [[-1,-1,1],[0,-1,1],[1,-1,1],[-1,0,1],[0,0,1],[1,0,1],[-1,1,1],[0,1,1],[1,1,1],[-1,-1,0],[0,-1,0],[1,-1,0],[-1,0,0],[0,0,0],[1,0,0],[-1,1,0],[0,1,0],[1,1,0],[-1,-1,-1],[0,-1,-1],[1,-1,-1],[-1,0,-1],[0,0,-1],[1,0,-1],[-1,1,-1],[0,1,-1],[1,1,-1]]);
}
test_standard_anchors();



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
