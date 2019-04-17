include <BOSL/constants.scad>
include <BOSL/transforms.scad>
include <BOSL/primitives.scad>
include <BOSL/shapes.scad>
include <BOSL/debug.scad>

cuboid([60,40,40], fillet=5, edges=EDGES_Z_ALL, align="bottom") {
	attach("top") rounded_prismoid([60,40],[20,20], h=50, r1=5, r2=10) {
		attach("top") cylinder(d=20, h=30) {
			attach("top") cylinder(d1=50, d2=30, h=12);
		}
		for (a = ["front", "back", "left", "right"]) {
			attach(a) cylinder(d1=14, d2=5, h=20) {
				attach("top", "left", overlap=5) prismoid([30,20], [20,20], h=10, shift=[-7,0]);
			}
		}
	}
}


// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
