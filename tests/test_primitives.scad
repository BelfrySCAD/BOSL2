include <BOSL2/std.scad>


module test_square() {
	assert(square(100, center=true) == [[50,-50],[-50,-50],[-50,50],[50,50]]);
	assert(square(100, center=false) == [[100,0],[0,0],[0,100],[100,100]]);
	assert(square(100, anchor=FWD+LEFT) == [[100,0],[0,0],[0,100],[100,100]]);
	assert(square(100, anchor=BACK+RIGHT) == [[0,-100],[-100,-100],[-100,0],[0,0]]);
}
test_square();


module test_circle() {
	for (pt = circle(d=200)) {
		assert(approx(norm(pt),100));
	}
	for (pt = circle(r=100)) {
		assert(approx(norm(pt),100));
	}
	assert(polygon_is_clockwise(circle(d=200)));
	assert(polygon_is_clockwise(circle(r=100)));
	assert(len(circle(d=100,$fn=6)) == 6);
	assert(len(circle(d=100,$fn=36)) == 36);
}
test_circle();


// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
