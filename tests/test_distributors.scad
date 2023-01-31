include <../std.scad>


module test_line_copies() {
    assert_equal(line_copies(l=100,n=5,p=[0,0,0]), [[-50,0,0],[-25,0,0],[0,0,0],[25,0,0],[50,0,0]]);
    assert_equal(line_copies(20,n=5,p=[0,0,0]), [[-40,0,0],[-20,0,0],[0,0,0],[20,0,0],[40,0,0]]);
    assert_equal(line_copies(spacing=20,n=5,p=[0,0,0]), [[-40,0,0],[-20,0,0],[0,0,0],[20,0,0],[40,0,0]]);
    assert_equal(line_copies(spacing=[0,20],n=5,p=[0,0,0]), [[0,-40,0],[0,-20,0],[0,0,0],[0,20,0],[0,40,0]]);

    assert_equal(line_copies(p1=[0,0],l=100,n=5,p=[0,0,0]), [[0,0,0],[25,0,0],[50,0,0],[75,0,0],[100,0,0]]);
    assert_equal(line_copies(p1=[0,0],20,n=5,p=[0,0,0]), [[0,0,0],[20,0,0],[40,0,0],[60,0,0],[80,0,0]]);
    assert_equal(line_copies(p1=[0,0],spacing=20,n=5,p=[0,0,0]), [[0,0,0],[20,0,0],[40,0,0],[60,0,0],[80,0,0]]);
    assert_equal(line_copies(p1=[0,0],spacing=[0,20],n=5,p=[0,0,0]), [[0,0,0],[0,20,0],[0,40,0],[0,60,0],[0,80,0]]);
}
test_line_copies();



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
