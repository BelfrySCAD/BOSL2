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
