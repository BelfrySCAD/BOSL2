include <BOSL2/std.scad>
include <BOSL2/debug.scad>

$fn = 36;

rgn1 = [
	square(100),
	move([50,50], p=circle(d=60)),
	[[40,40],[40,60],[60,60]]
];

rgn2 = [
	[[0,0], [100,100], [100,0]],
	[[27,10], [90,73], [90,10]],
	move([70,30], p=circle(d=20))
];


module showit(label, rgn, poly=undef, outline=undef, width=0.75) {
	move([-50,-50]) {
		if(outline) color(outline) linear_extrude(height=max(0.1,1-width)) for(path=rgn) stroke(path, width=width, close=true);
		if(poly) color(poly) linear_extrude(height=0.1) region(rgn);
		color("black") right(50) fwd(7) linear_extrude(height=0.1) text(text=label, size=8, halign="center", valign="center");
	}
}


ydistribute(-125) {
	xdistribute(120) {
		showit("Region A", rgn1, poly="green", outline="black");
		showit("Region B", rgn2, poly="green", outline="black");
		union() {
			showit("A and B Overlaid", rgn1, outline="red",width=1);
			showit("", rgn2, outline="blue",width=0.5);
		}
	}
	xdistribute(120) {
		showit("Union A+B", union(rgn1, rgn2), poly="green", outline="black");
		showit("Difference A-B", difference(rgn1, rgn2), poly="green", outline="black");
		showit("Difference B-A", difference(rgn2, rgn1), poly="green", outline="black");
	}
	xdistribute(120) {
		showit("Intersection A&B", intersection(rgn1, rgn2), poly="green", outline="black");
		showit("Exclusive OR A^B", exclusive_or(rgn1, rgn2), poly="green", outline="black");
	}
}

// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
