include <../std.scad>


module test_line_of() {
    assert_equal(line_of(l=100,n=5), [[-50,0,0],[-25,0,0],[0,0,0],[25,0,0],[50,0,0]]);
    assert_equal(line_of(20,n=5), [[-40,0,0],[-20,0,0],[0,0,0],[20,0,0],[40,0,0]]);
    assert_equal(line_of(spacing=20,n=5), [[-40,0,0],[-20,0,0],[0,0,0],[20,0,0],[40,0,0]]);
    assert_equal(line_of(spacing=[0,20],n=5), [[0,-40,0],[0,-20,0],[0,0,0],[0,20,0],[0,40,0]]);

    assert_equal(line_of(p1=[0,0],l=100,n=5), [[0,0,0],[25,0,0],[50,0,0],[75,0,0],[100,0,0]]);
    assert_equal(line_of(p1=[0,0],20,n=5), [[0,0,0],[20,0,0],[40,0,0],[60,0,0],[80,0,0]]);
    assert_equal(line_of(p1=[0,0],spacing=20,n=5), [[0,0,0],[20,0,0],[40,0,0],[60,0,0],[80,0,0]]);
    assert_equal(line_of(p1=[0,0],spacing=[0,20],n=5), [[0,0,0],[0,20,0],[0,40,0],[0,60,0],[0,80,0]]);
}
test_line_of();



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
