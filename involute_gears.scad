//////////////////////////////////////////////////////////////////////////////////////////////
// Public Domain Parametric Involute Spur Gear (and involute helical gear and involute rack)
// version 1.1
// by Leemon Baird, 2011, Leemon@Leemon.com
// http://www.thingiverse.com/thing:5505
// Tweaked, and improved by Revar Desmera, 2017-2019, revarbat@gmail.com
//
// This file is public domain.  Use it for any purpose, including commercial
// applications.  Attribution would be nice, but is not required.  There is
// no warranty of any kind, including its correctness, usefulness, or safety.
//
// This is parameterized involute spur (or helical) gear.  It is much simpler and less powerful than
// others on Thingiverse.  But it is public domain.  I implemented it from scratch from the
// descriptions and equations on Wikipedia and the web, using Mathematica for calculations and testing,
// and I now release it into the public domain.
//
//		http://en.wikipedia.org/wiki/Involute_gear
//		http://en.wikipedia.org/wiki/Gear
//		http://en.wikipedia.org/wiki/List_of_gear_nomenclature
//		http://gtrebaol.free.fr/doc/catia/spur_gear.html
//		http://www.cs.cmu.edu/~rapidproto/mechanisms/chpt7.html
//
// The module gear() gives an involute spur gear, with reasonable defaults for all the parameters.
// Normally, you should just choose the first 4 parameters, and let the rest be default values.
// The module gear() gives a gear in the XY plane, centered on the origin, with one tooth centered on
// the positive Y axis.  The various functions below it take the same parameters, and return various
// measurements for the gear.  The most important is pitch_radius, which tells how far apart to space
// gears that are meshing, and adendum_radius, which gives the size of the region filled by the gear.
// A gear has a "pitch circle", which is an invisible circle that cuts through the middle of each
// tooth (though not the exact center). In order for two gears to mesh, their pitch circles should
// just touch.  So the distance between their centers should be pitch_radius() for one, plus pitch_radius()
// for the other, which gives the radii of their pitch circles.
//
// In order for two gears to mesh, they must have the same mm_per_tooth and pressure_angle parameters.
// mm_per_tooth gives the number of millimeters of arc around the pitch circle covered by one tooth and one
// space between teeth.  The pitch angle controls how flat or bulged the sides of the teeth are.  Common
// values include 14.5 degrees and 20 degrees, and occasionally 25.  Though I've seen 28 recommended for
// plastic gears. Larger numbers bulge out more, giving stronger teeth, so 28 degrees is the default here.
//
// The ratio of number_of_teeth for two meshing gears gives how many times one will make a full
// revolution when the the other makes one full revolution.  If the two numbers are coprime (i.e.
// are not both divisible by the same number greater than 1), then every tooth on one gear
// will meet every tooth on the other, for more even wear.  So coprime numbers of teeth are good.
//
// The module rack() gives a rack, which is a bar with teeth.  A rack can mesh with any
// gear that has the same mm_per_tooth and pressure_angle.
//
// Some terminology:
// The outline of a gear is a smooth circle (the "pitch circle") which has mountains and valleys
// added so it is toothed.  So there is an inner circle (the "root circle") that touches the
// base of all the teeth, an outer circle that touches the tips of all the teeth,
// and the invisible pitch circle in between them.  There is also a "base circle", which can be smaller than
// all three of the others, which controls the shape of the teeth.  The side of each tooth lies on the path
// that the end of a string would follow if it were wrapped tightly around the base circle, then slowly unwound.
// That shape is an "involute", which gives this type of gear its name.
//
//////////////////////////////////////////////////////////////////////////////////////////////


//gear_tooth_profile(mm_per_tooth=5, number_of_teeth=20, pressure_angle=20);
module gear_tooth_profile(
	mm_per_tooth    = 3,     //this is the "circular pitch", the circumference of the pitch circle divided by the number of teeth
	number_of_teeth = 11,    //total number of teeth around the entire perimeter
	pressure_angle  = 28,    //Controls how straight or bulged the tooth sides are. In degrees.
	backlash        = 0.0,   //gap between two meshing teeth, in the direction along the circumference of the pitch circle
	bevelang        = 0.0,   //Gear face angle for bevelled gears.
	clearance       = undef  //gap between top of a tooth on one gear and bottom of valley on a meshing gear (in millimeters)
) {
	function polar(r,theta)   = r*[sin(theta), cos(theta)];                      //convert polar to cartesian coordinates
	function iang(r1,r2)      = sqrt((r2/r1)*(r2/r1) - 1)/PI*180 - acos(r1/r2);  //unwind a string this many degrees to go from radius r1 to radius r2
	function q7(f,r,b,r2,t,s) = q6(b,s,t,(1-f)*max(b,r)+f*r2);                   //radius a fraction f up the curved side of the tooth
	function q6(b,s,t,d)      = polar(d,s*(iang(b,d)+t));                        //point at radius d on the involute curve

	p = pitch_radius(mm_per_tooth, number_of_teeth);
	c = outer_radius(mm_per_tooth, number_of_teeth);
	r = root_radius(mm_per_tooth, number_of_teeth, clearance);
	b = base_radius(mm_per_tooth, number_of_teeth, pressure_angle);
	t  = mm_per_tooth/2-backlash/2;               //tooth thickness at pitch circle
	k  = -iang(b, p) - t/2/p/PI*180;              //angle to where involute meets base circle on each side of tooth
	scale([1, 1/cos(bevelang), 1])
	translate([0,-r,0])
	polygon(
		points=[
			polar(r-1, -181/number_of_teeth),
			polar(r, -181/number_of_teeth),
			polar(r, r<b ? k : -180/number_of_teeth),
			q7(0/5,r,b,c,k, 1),q7(1/5,r,b,c,k, 1),q7(2/5,r,b,c,k, 1),q7(3/5,r,b,c,k, 1),q7(4/5,r,b,c,k, 1),q7(5/5,r,b,c,k, 1),
			q7(5/5,r,b,c,k,-1),q7(4/5,r,b,c,k,-1),q7(3/5,r,b,c,k,-1),q7(2/5,r,b,c,k,-1),q7(1/5,r,b,c,k,-1),q7(0/5,r,b,c,k,-1),
			polar(r, r<b ? -k : 180/number_of_teeth),
			polar(r, 181/number_of_teeth),
			polar(r-1, 181/number_of_teeth),
		]
	);
}


// Creates a 2D involute spur gear, with reasonable defaults for all the parameters.
// Normally, you should just specify the first 2 parameters, and let the rest be default values.
// Meshing gears must match in mm_per_tooth, pressure_angle, and twist,
// and be separated by the sum of their pitch radii, which can be found with pitch_radius().
//   mm_per_tooth  = This is the "circular pitch", the circumference of the pitch circle divided by the number of teeth
//   number_of_teeth = Total number of teeth along the rack
//   teeth_to_hide = Number of teeth to delete to make this only a fraction of a circle
//   pressure_angle = Controls how straight or bulged the tooth sides are. In degrees.
//   clearance = Gap between top of a tooth on one gear and bottom of valley on a meshing gear (in millimeters)
//   backlash = Gap between two meshing teeth, in the direction along the circumference of the pitch circle
// Example:
//   gear2d(mm_per_tooth=5, number_of_teeth=20);
//   linear_extrude(height=5*20/PI/2/2, scale=0.5) gear2d(mm_per_tooth=5, number_of_teeth=20);
module gear2d(
	mm_per_tooth    = 3,     //this is the "circular pitch", the circumference of the pitch circle divided by the number of teeth
	number_of_teeth = 11,    //total number of teeth around the entire perimeter
	teeth_to_hide   = 0,     //number of teeth to delete to make this only a fraction of a circle
	pressure_angle  = 28,    //Controls how straight or bulged the tooth sides are. In degrees.
	clearance       = undef, //gap between top of a tooth on one gear and bottom of valley on a meshing gear (in millimeters)
	backlash        = 0.0,   //gap between two meshing teeth, in the direction along the circumference of the pitch circle
	bevelang        = 0.0
) {
	r = root_radius(mm_per_tooth, number_of_teeth, clearance);
	union() {
		circle(r=r-0.5, $fn=number_of_teeth);
		for (i = [0:number_of_teeth-teeth_to_hide-1] ) {
			rotate(i*360/number_of_teeth) {
				translate([0,r,0]) {
					gear_tooth_profile(
						mm_per_tooth    = mm_per_tooth,
						number_of_teeth = number_of_teeth,
						pressure_angle  = pressure_angle,
						clearance       = clearance,
						backlash        = backlash,
						bevelang        = bevelang
					);
				}
			}
		}
	}
}


// Creates an involute spur gear, with reasonable defaults for all the parameters.
// Normally, you should just choose the first 4 parameters, and let the rest be default values.
// Meshing gears must match in mm_per_tooth, pressure_angle, and twist,
// and be separated by the sum of their pitch radii, which can be found with pitch_radius().
//   mm_per_tooth  = This is the "circular pitch", the circumference of the pitch circle divided by the number of teeth
//   number_of_teeth = Total number of teeth along the rack
//   thickness = Thickness of rack in mm (affects each tooth)
//   hole_diameter = Diameter of centeral shaft hole.
//   teeth_to_hide = Number of teeth to delete to make this only a fraction of a circle
//   pressure_angle = Controls how straight or bulged the tooth sides are. In degrees.
//   clearance = Gap between top of a tooth on one gear and bottom of valley on a meshing gear (in millimeters)
//   backlash = Gap between two meshing teeth, in the direction along the circumference of the pitch circle
//   twist = Teeth rotate this many degrees from bottom of gear to top.  360 makes the gear a screw with each thread going around once
//   scale = Scale of top of gear compared to bottom.  Useful for making crown gears.
//	 slices = Number of slices to divide gear into.  Useful for refining gears with `twist`.
// Example:
//   gear(mm_per_tooth=5, number_of_teeth=20, thickness=10*cos(45), hole_diameter=5, twist=-30, bevelang=45, slices=12, $fa=1, $fs=1);
//   gear(mm_per_tooth=5, number_of_teeth=20, thickness=8, hole_diameter=5, $fa=1, $fs=1);
module gear(
	mm_per_tooth    = 3,     //this is the "circular pitch", the circumference of the pitch circle divided by the number of teeth
	number_of_teeth = 11,    //total number of teeth around the entire perimeter
	thickness       = 6,     //thickness of gear in mm
	hole_diameter   = 3,     //diameter of the hole in the center, in mm
	teeth_to_hide   = 0,     //number of teeth to delete to make this only a fraction of a circle
	pressure_angle  = 28,    //Controls how straight or bulged the tooth sides are. In degrees.
	clearance       = undef, //gap between top of a tooth on one gear and bottom of valley on a meshing gear (in millimeters)
	backlash        = 0.0,   //gap between two meshing teeth, in the direction along the circumference of the pitch circle
	bevelang        = 0.0,   //angle of bevelled gear face.
	twist           = undef, //teeth rotate this many degrees from bottom of gear to top.  360 makes the gear a screw with each thread going around once
	slices          = undef  //Number of slices to divide gear into.  Useful for refining gears with `twist`.
) {
	p = pitch_radius(mm_per_tooth, number_of_teeth);
	c = outer_radius(mm_per_tooth, number_of_teeth);
	r = root_radius(mm_per_tooth, number_of_teeth, clearance);
	p2 = p - (thickness*tan(bevelang));
	difference() {
		linear_extrude(height=thickness, center=true, convexity=10, twist=twist, scale=p2/p, slices=slices) {
			gear2d(
				mm_per_tooth    = mm_per_tooth,
				number_of_teeth = number_of_teeth,
				teeth_to_hide   = teeth_to_hide,
				pressure_angle  = pressure_angle,
				clearance       = clearance,
				backlash        = backlash,
				bevelang        = bevelang
			);
		}
		if (hole_diameter > 0) {
			cylinder(h=2*thickness+1, r=hole_diameter/2, center=true);
		}
		if (bevelang != 0) {
			h = (c-r)*sin(bevelang);
			translate([0,0,-thickness/2]) {
				difference() {
					cube([2*c/cos(bevelang),2*c/cos(bevelang),2*h], center=true);
					cylinder(h=h, r1=r, r2=c, center=false);
				}
			}
		}
	}
}


// Creates a rack, which is a straight line with teeth.
// The same as a segment of teeth from an infinite diameter gear.
// The "pitch circle" is a line along the X axis.
//   mm_per_tooth  = This is the "circular pitch", the circumference of the pitch circle divided by the number of teeth
//   number_of_teeth = Total number of teeth along the rack
//   thickness = Thickness of rack in mm (affects each tooth)
//   height = Height of rack in mm, from tooth top to back of rack.
//   pressure_angle = Controls how straight or bulged the tooth sides are. In degrees.
//   backlash = Gap between two meshing teeth, in the direction along the circumference of the pitch circle
// Example:
//   rack(mm_per_tooth=5, number_of_teeth=30, thickness=5, height=5, pressure_angle=20);
module rack(
	mm_per_tooth    = 5,    //this is the "circular pitch", the circumference of the pitch circle divided by the number of teeth
	number_of_teeth = 20,   //total number of teeth along the rack
	thickness       = 5,    //thickness of rack in mm (affects each tooth)
	height          = 10,   //height of rack in mm, from tooth top to back of rack.
	pressure_angle  = 28,   //Controls how straight or bulged the tooth sides are. In degrees.
	backlash        = 0.0,  //gap between two meshing teeth, in the direction along the circumference of the pitch circle
	clearance       = undef
) {
	a = adendum(mm_per_tooth);
	d = dedendum(mm_per_tooth, clearance);
	xa = a * sin(pressure_angle);
	xd = d * sin(pressure_angle);
	linear_extrude(height = thickness, center = true, convexity = 10) {
		for (i = [0:number_of_teeth-1] ) {
			translate([i*mm_per_tooth,0,0]) {
				polygon(
					points=[
						[-1/2 * mm_per_tooth - 0.01,          a-height],
						[-1/2 * mm_per_tooth,                 -d],
						[-1/4 * mm_per_tooth + backlash - xd, -d],
						[-1/4 * mm_per_tooth + backlash + xa,  a],
						[ 1/4 * mm_per_tooth - backlash - xa,  a],
						[ 1/4 * mm_per_tooth - backlash + xd, -d],
						[ 1/2 * mm_per_tooth,                 -d],
						[ 1/2 * mm_per_tooth + 0.01,          a-height],
					]
				);
			}
		}
	}
}


//These functions let the user find the derived dimensions of the gear.
//A gear fits within a circle of radius outer_radius, and two gears should have
//their centers separated by the sum of their pitch_radius.
function circular_pitch(mm_per_tooth=5) = mm_per_tooth;                     //tooth density expressed as "circular pitch" in millimeters
function diametral_pitch(mm_per_tooth=5) = PI / mm_per_tooth;         //tooth density expressed as "diametral pitch" in teeth per millimeter

function module_value(mm_per_tooth=5) = mm_per_tooth / PI;                //tooth density expressed as "module" or "modulus" in millimeters
function adendum     (mm_per_tooth=5) = module_value(mm_per_tooth);
function dedendum    (mm_per_tooth=5, clearance=undef) = (clearance==undef)? (1.25 * module_value(mm_per_tooth)) : (module_value(mm_per_tooth) + clearance);
function pitch_radius(mm_per_tooth=5, number_of_teeth=11) = mm_per_tooth * number_of_teeth / PI / 2;

//The gear fits entirely within a cylinder of this radius.
function outer_radius(mm_per_tooth=5, number_of_teeth=11)
	= pitch_radius(mm_per_tooth, number_of_teeth) + adendum(mm_per_tooth);

// Radius of circle at base of dedendum.
function root_radius(mm_per_tooth=5, number_of_teeth=11, clearance=undef)
	= pitch_radius(mm_per_tooth, number_of_teeth) - dedendum(mm_per_tooth, clearance);

// The base circle for involute teeth.
function base_radius(mm_per_tooth=5, number_of_teeth=11, pressure_angle=28)
	= pitch_radius(mm_per_tooth, number_of_teeth) * cos(pressure_angle);


//////////////////////////////////////////////////////////////////////////////////////////////
//example gear train.
//Try it with OpenSCAD View/Animate command with 20 steps and 24 FPS.
//The gears will continue to be rotated to mesh correctly if you change the number of teeth.

/*
n1 = 11; //red gear number of teeth
n2 = 20; //green gear
n3 = 5;  //blue gear
n4 = 20; //orange gear
n5 = 8;  //gray rack
mm_per_tooth = 9; //all meshing gears need the same mm_per_tooth (and the same pressure_angle)
thickness    = 6;
hole         = 3;
height       = 12;

d1 =pitch_radius(mm_per_tooth,n1);
d12=pitch_radius(mm_per_tooth,n1) + pitch_radius(mm_per_tooth,n2);
d13=pitch_radius(mm_per_tooth,n1) + pitch_radius(mm_per_tooth,n3);
d14=pitch_radius(mm_per_tooth,n1) + pitch_radius(mm_per_tooth,n4);

translate([ 0,    0, 0]) rotate([0,0, $t*360/n1])                 color([1.00,0.75,0.75]) gear(mm_per_tooth,n1,thickness,hole);
translate([ 0,  d12, 0]) rotate([0,0,-($t+n2/2-0*n1+1/2)*360/n2]) color([0.75,1.00,0.75]) gear(mm_per_tooth,n2,thickness,hole);
translate([ d13,  0, 0]) rotate([0,0,-($t-n3/4+n1/4+1/2)*360/n3]) color([0.75,0.75,1.00]) gear(mm_per_tooth,n3,thickness,hole);
translate([ d13,  0, 0]) rotate([0,0,-($t-n3/4+n1/4+1/2)*360/n3]) color([0.75,0.75,1.00]) gear(mm_per_tooth,n3,thickness,hole);
translate([-d14,  0, 0]) rotate([0,0,-($t-n4/4-n1/4+1/2-floor(n4/4)-3)*360/n4]) color([1.00,0.75,0.50]) gear(mm_per_tooth,n4,thickness,hole);
translate([(-floor(n5/2)-floor(n1/2)+$t+n1/2-1/2)*9, -d1+0.0, 0]) rotate([0,0,0]) color([0.75,0.75,0.75]) rack(mm_per_tooth,n5,thickness,height);
*/


// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap

