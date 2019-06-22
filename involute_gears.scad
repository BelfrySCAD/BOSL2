//////////////////////////////////////////////////////////////////////////////////////////////
// LibFile: involute_gears.scad
//   Involute Spur Gears and Racks
//   
//   by Leemon Baird, 2011, Leemon@Leemon.com
//   http://www.thingiverse.com/thing:5505
//   
//   Additional fixes and improvements by Revar Desmera, 2017-2019, revarbat@gmail.com
//   
//   This file is public domain.  Use it for any purpose, including commercial
//   applications.  Attribution would be nice, but is not required.  There is
//   no warranty of any kind, including its correctness, usefulness, or safety.
//   
//   This is parameterized involute spur (or helical) gear.  It is much simpler
//   and less powerful than others on Thingiverse.  But it is public domain.  I
//   implemented it from scratch from the descriptions and equations on Wikipedia
//   and the web, using Mathematica for calculations and testing, and I now
//   release it into the public domain.
//   
//   To use, add the following line to the beginning of your file:
//   ```
//   include <BOSL2/std.scad>
//   include <BOSL2/involute_gears.scad>
//   ```
//////////////////////////////////////////////////////////////////////////////////////////////


// Section: Terminology
//   The outline of a gear is a smooth circle (the "pitch circle") which has
//   mountains and valleys added so it is toothed.  There is an inner
//   circle (the "root circle") that touches the base of all the teeth, an
//   outer circle that touches the tips of all the teeth, and the invisible
//   pitch circle in between them.  There is also a "base circle", which can
//   be smaller than all three of the others, which controls the shape of
//   the teeth.  The side of each tooth lies on the path that the end of a
//   string would follow if it were wrapped tightly around the base circle,
//   then slowly unwound.  That shape is an "involute", which gives this
//   type of gear its name.


// Section: Functions
//   These functions let the user find the derived dimensions of the gear.
//   A gear fits within a circle of radius outer_radius, and two gears should have
//   their centers separated by the sum of their pitch_radius.


// Function: circular_pitch()
// Description: Get tooth density expressed as "circular pitch".
// Arguments:
//   pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.
function circular_pitch(pitch=5) = pitch;


// Function: diametral_pitch()
// Description: Get tooth density expressed as "diametral pitch".
// Arguments:
//   pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.
function diametral_pitch(pitch=5) = PI / pitch;


// Function: module_value()
// Description: Get tooth density expressed as "module" or "modulus" in millimeters
// Arguments:
//   pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.
function module_value(pitch=5) = pitch / PI;


// Function: adendum()
// Description: The height of the gear tooth above the pitch radius.
// Arguments:
//   pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.
function adendum(pitch=5) = module_value(pitch);


// Function: dedendum()
// Description: The depth of the gear tooth valley, below the pitch radius.
// Arguments:
//   pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.
//   clearance = If given, sets the clearance between meshing teeth.
function dedendum(pitch=5, clearance=undef) =
	(clearance==undef)? (1.25 * module_value(pitch)) : (module_value(pitch) + clearance);


// Function: pitch_radius()
// Description: Calculates the pitch radius for the gear.
// Arguments:
//   pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.
//   teeth = The number of teeth on the gear.
function pitch_radius(pitch=5, teeth=11) =
	pitch * teeth / PI / 2;


// Function: outer_radius()
// Description:
//   Calculates the outer radius for the gear. The gear fits entirely within a cylinder of this radius.
// Arguments:
//   pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.
//   teeth = The number of teeth on the gear.
//   clearance = If given, sets the clearance between meshing teeth.
//   interior = If true, calculate for an interior gear.
function outer_radius(pitch=5, teeth=11, clearance=undef, interior=false) =
	pitch_radius(pitch, teeth) +
	(interior? dedendum(pitch, clearance) : adendum(pitch));


// Function: root_radius()
// Description:
//   Calculates the root radius for the gear, at the base of the dedendum.
// Arguments:
//   pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.
//   teeth = The number of teeth on the gear.
//   clearance = If given, sets the clearance between meshing teeth.
//   interior = If true, calculate for an interior gear.
function root_radius(pitch=5, teeth=11, clearance=undef, interior=false) =
	pitch_radius(pitch, teeth) -
	(interior? adendum(pitch) : dedendum(pitch, clearance));


// Function: base_radius()
// Description: Get the base circle for involute teeth.
// Arguments:
//   pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.
//   teeth = The number of teeth on the gear.
//   PA = Pressure angle in degrees.  Controls how straight or bulged the tooth sides are.
function base_radius(pitch=5, teeth=11, PA=28) =
	pitch_radius(pitch, teeth) * cos(PA);


// Function bevel_pitch_angle()
// Usage:
//   bevel_pitch_angle(teeth, mate_teeth, [drive_angle]);
// Description:
//   Returns the correct pitch angle (bevelang) for a bevel gear with a given number of tooth, that is
//   matched to another bevel gear with a (possibly different) number of teeth.
// Arguments:
//   teeth = Number of teeth that this gear has.
//   mate_teeth = Number of teeth that the matching gear has.
//   drive_angle = Angle between the drive shafts of each gear.  Usually 90º.
function bevel_pitch_angle(teeth, mate_teeth, drive_angle=90) =
	atan(sin(drive_angle)/((mate_teeth/teeth)+cos(drive_angle)));


function _gear_polar(r,t) = r*[sin(t),cos(t)];
function _gear_iang(r1,r2) = sqrt((r2/r1)*(r2/r1) - 1)/PI*180 - acos(r1/r2);  //unwind a string this many degrees to go from radius r1 to radius r2
function _gear_q6(b,s,t,d) = _gear_polar(d,s*(_gear_iang(b,d)+t));            //point at radius d on the involute curve
function _gear_q7(f,r,b,r2,t,s) = _gear_q6(b,s,t,(1-f)*max(b,r)+f*r2);        //radius a fraction f up the curved side of the tooth


// Section: Modules


// Function&Module: gear_tooth_profile()
// Description:
//   When called as a function, returns the 2D profile path for an individual gear tooth.
//   When called as a module, creates the 2D profile shape for an individual gear tooth.
// Arguments:
//   pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.
//   teeth = Total number of teeth along the rack
//   PA = Controls how straight or bulged the tooth sides are. In degrees.
//   backlash = Gap between two meshing teeth, in the direction along the circumference of the pitch circle
//   clearance = Gap between top of a tooth on one gear and bottom of valley on a meshing gear (in millimeters)
//   interior = If true, create a mask for difference()ing from something else.
//   valleys = If true, add the valley bottoms on either side of the tooth.
// Example(2D):
//   gear_tooth_profile(pitch=5, teeth=20, PA=20);
// Example(2D):
//   gear_tooth_profile(pitch=5, teeth=20, PA=20, valleys=true);
function gear_tooth_profile(
	pitch     = 3,
	teeth     = 11,
	PA        = 28,
	backlash  = 0.0,
	clearance = undef,
	interior  = false,
	valleys   = true
) = let(
	p = pitch_radius(pitch, teeth),
	c = outer_radius(pitch, teeth, clearance, interior),
	r = root_radius(pitch, teeth, clearance, interior),
	b = base_radius(pitch, teeth, PA),
	t  = pitch/2-backlash/2,                //tooth thickness at pitch circle
	k  = -_gear_iang(b, p) - t/2/p/PI*180,  //angle to where involute meets base circle on each side of tooth
	kk = r<b? k : -180/teeth,
	isteps = 5,
	pts = concat(
		valleys? [
			_gear_polar(r-1, -180.1/teeth),
			_gear_polar(r, -180.1/teeth),
		] : [
		],
		[_gear_polar(r, kk)],
		[for (i=[0: 1:isteps]) _gear_q7(i/isteps,r,b,c,k, 1)],
		[for (i=[isteps:-1:0]) _gear_q7(i/isteps,r,b,c,k,-1)],
		[_gear_polar(r, -kk)],
		valleys? [
			_gear_polar(r, 180.1/teeth),
			_gear_polar(r-1, 180.1/teeth),
		] : [
		]
	)
) reverse(pts);


module gear_tooth_profile(
	pitch     = 3,
	teeth     = 11,
	PA        = 28,
	backlash  = 0.0,
	clearance = undef,
	interior  = false,
	valleys   = true
) {
	r = root_radius(pitch, teeth, clearance, interior);
	translate([0,-r,0])
	polygon(
		points=gear_tooth_profile(
			pitch     = pitch,
			teeth     = teeth,
			PA        = PA,
			backlash  = backlash,
			clearance = clearance,
			interior  = interior,
			valleys   = valleys
		)
	);
}


// Function&Module: gear2d()
// Description:
//   When called as a module, creates a 2D involute spur gear.  When called as a function, returns a
//   2D path for the perimeter of a 2D involute spur gear.  Normally, you should just specify the
//   first 2 parameters `pitch` and `teeth`, and let the rest be default values.
//   Meshing gears must match in `pitch`, `PA`, and `helical`, and be separated by
//   the sum of their pitch radii, which can be found with `pitch_radius()`.
// Arguments:
//   pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.
//   teeth = Total number of teeth along the rack
//   hide = Number of teeth to delete to make this only a fraction of a circle
//   PA = Controls how straight or bulged the tooth sides are. In degrees.
//   clearance = Gap between top of a tooth on one gear and bottom of valley on a meshing gear (in millimeters)
//   backlash = Gap between two meshing teeth, in the direction along the circumference of the pitch circle
//   interior = If true, create a mask for difference()ing from something else.
// Example(2D): Typical Gear Shape
//   gear2d(pitch=5, teeth=20);
// Example(2D): Lower Pressure Angle
//   gear2d(pitch=5, teeth=20, PA=20);
// Example(2D): Partial Gear
//   gear2d(pitch=5, teeth=20, hide=15, PA=20);
function gear2d(
	pitch     = 3,
	teeth     = 11,
	hide      = 0,
	PA        = 28,
	clearance = undef,
	backlash  = 0.0,
	interior  = false
) = let(
	pts = concat(
		[for (tooth = [0:1:teeth-hide-1])
			each rot(tooth*360/teeth,
				planar=true,
				p=gear_tooth_profile(
					pitch     = pitch,
					teeth     = teeth,
					PA        = PA,
					clearance = clearance,
					backlash  = backlash,
					interior  = interior,
					valleys   = false
				)
			)
		],
		hide>0? [[0,0]] : []
	)
) pts;


module gear2d(
	pitch     = 3,
	teeth     = 11,
	hide      = 0,
	PA        = 28,
	clearance = undef,
	backlash  = 0.0,
	interior  = false
) {
	polygon(
		gear2d(
			pitch     = pitch,
			teeth     = teeth,
			hide      = hide,
			PA        = PA,
			clearance = clearance,
			backlash  = backlash,
			interior  = interior
		)
	);
}


// Module: gear()
// Description:
//   Creates a (potentially helical) involute spur gear.
//   The module `gear()` gives an involute spur gear, with reasonable
//   defaults for all the parameters.  Normally, you should just choose
//   the first 4 parameters, and let the rest be default values.  The
//   module `gear()` gives a gear in the XY plane, centered on the origin,
//   with one tooth centered on the positive Y axis.  The various functions
//   below it take the same parameters, and return various measurements
//   for the gear.  The most important is `pitch_radius()`, which tells
//   how far apart to space gears that are meshing, and `outer_radius()`,
//   which gives the size of the region filled by the gear.  A gear has
//   a "pitch circle", which is an invisible circle that cuts through
//   the middle of each tooth (though not the exact center). In order
//   for two gears to mesh, their pitch circles should just touch.  So
//   the distance between their centers should be `pitch_radius()` for
//   one, plus `pitch_radius()` for the other, which gives the radii of
//   their pitch circles.
//   In order for two gears to mesh, they must have the same `pitch`
//   and `PA` parameters.  `pitch` gives the number
//   of millimeters of arc around the pitch circle covered by one tooth
//   and one space between teeth.  The `PA` controls how flat or
//   bulged the sides of the teeth are.  Common values include 14.5
//   degrees and 20 degrees, and occasionally 25.  Though I've seen 28
//   recommended for plastic gears. Larger numbers bulge out more, giving
//   stronger teeth, so 28 degrees is the default here.
//   The ratio of `teeth` for two meshing gears gives how many
//   times one will make a full revolution when the the other makes one
//   full revolution.  If the two numbers are coprime (i.e.  are not
//   both divisible by the same number greater than 1), then every tooth
//   on one gear will meet every tooth on the other, for more even wear.
//   So coprime numbers of teeth are good.
// Arguments:
//   pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.
//   teeth = Total number of teeth around the entire perimeter
//   thickness = Thickness of gear in mm
//   shaft_diam = Diameter of the hole in the center, in mm
//   hide = Number of teeth to delete to make this only a fraction of a circle
//   PA = Controls how straight or bulged the tooth sides are. In degrees.
//   clearance = Clearance gap at the bottom of the inter-tooth valleys.
//   backlash = Gap between two meshing teeth, in the direction along the circumference of the pitch circle
//   helical = Teeth rotate this many degrees from bottom of gear to top.  360 makes the gear a screw with each thread going around once.
//   slices = Number of vertical layers to divide gear into.  Useful for refining gears with `helical`.
//   scale = Scale of top of gear compared to bottom.  Useful for making crown gears.
//   interior = If true, create a mask for difference()ing from something else.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
// Example: Spur Gear
//   gear(pitch=5, teeth=20, thickness=8, shaft_diam=5);
// Example: Beveled Gear
//   gear(pitch=5, teeth=20, thickness=10, shaft_diam=5, helical=-30, slices=12, $fa=1, $fs=1);
module gear(
	pitch     = 3,
	teeth     = 11,
	PA        = 28,
	thickness = 6,
	hide      = 0,
	shaft_diam = 3,
	clearance = undef,
	backlash  = 0.0,
	helical   = 0,
	slices    = 2,
	interior  = false,
	anchor    = CENTER,
	spin      = 0,
	orient    = UP
) {
	p = pitch_radius(pitch, teeth);
	c = outer_radius(pitch, teeth, clearance, interior);
	r = root_radius(pitch, teeth, clearance, interior);
	twist = atan2(thickness*tan(helical),p);
	orient_and_anchor([p, p, thickness], orient, anchor, spin=spin, geometry="cylinder", chain=true) {
		difference() {
			linear_extrude(height=thickness, center=true, convexity=10, twist=twist) {
				gear2d(
					pitch     = pitch,
					teeth     = teeth,
					PA        = PA,
					hide      = hide,
					clearance = clearance,
					backlash  = backlash,
					interior  = interior
				);
			}
			if (shaft_diam > 0) {
				cylinder(h=2*thickness+1, r=shaft_diam/2, center=true, $fn=max(12,segs(shaft_diam/2)));
			}
		}
		children();
	}
}



// Module: bevel_gear()
// Description:
//   Creates a (potentially spiral) bevel gear.
//   The module `bevel_gear()` gives an bevel gear, with reasonable
//   defaults for all the parameters.  Normally, you should just choose
//   the first 4 parameters, and let the rest be default values.  The
//   module `bevel_gear()` gives a gear in the XY plane, centered on the origin,
//   with one tooth centered on the positive Y axis.  The various functions
//   below it take the same parameters, and return various measurements
//   for the gear.  The most important is `pitch_radius()`, which tells
//   how far apart to space gears that are meshing, and `outer_radius()`,
//   which gives the size of the region filled by the gear.  A gear has
//   a "pitch circle", which is an invisible circle that cuts through
//   the middle of each tooth (though not the exact center). In order
//   for two gears to mesh, their pitch circles should just touch.  So
//   the distance between their centers should be `pitch_radius()` for
//   one, plus `pitch_radius()` for the other, which gives the radii of
//   their pitch circles.
//   In order for two gears to mesh, they must have the same `pitch`
//   and `PA` parameters.  `pitch` gives the number
//   of millimeters of arc around the pitch circle covered by one tooth
//   and one space between teeth.  The `PA` controls how flat or
//   bulged the sides of the teeth are.  Common values include 14.5
//   degrees and 20 degrees, and occasionally 25.  Though I've seen 28
//   recommended for plastic gears. Larger numbers bulge out more, giving
//   stronger teeth, so 28 degrees is the default here.
//   The ratio of `teeth` for two meshing gears gives how many
//   times one will make a full revolution when the the other makes one
//   full revolution.  If the two numbers are coprime (i.e.  are not
//   both divisible by the same number greater than 1), then every tooth
//   on one gear will meet every tooth on the other, for more even wear.
//   So coprime numbers of teeth are good.
// Arguments:
//   pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.
//   teeth = Total number of teeth around the entire perimeter
//   face_width = Width of the toothed surface in mm, from inside to outside.
//   shaft_diam = Diameter of the hole in the center, in mm
//   hide = Number of teeth to delete to make this only a fraction of a circle
//   PA = Controls how straight or bulged the tooth sides are. In degrees.
//   clearance = Clearance gap at the bottom of the inter-tooth valleys.
//   backlash = Gap between two meshing teeth, in the direction along the circumference of the pitch circle
//   bevelang = Angle of beveled gear face.
//   spiral_rad = Radius of spiral arc for teeth.  If 0, then gear will not be spiral.  Default: 0
//   spiral_ang = The base angle for spiral teeth.  Default: 0
//   slices = Number of vertical layers to divide gear into.  Useful for refining gears with `spiral`.
//   scale = Scale of top of gear compared to bottom.  Useful for making crown gears.
//   interior = If true, create a mask for difference()ing from something else.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
// Example: Beveled Gear
//   bevel_gear(pitch=5, teeth=36, face_width=10, shaft_diam=5, spiral_rad=-20, spiral_ang=35, bevelang=45, slices=12, $fa=1, $fs=1);
module bevel_gear(
	pitch      = 3,
	teeth      = 11,
	PA         = 20,
	face_width = 6,
	bevelang   = 45,
	hide       = 0,
	shaft_diam = 3,
	clearance  = undef,
	backlash   = 0.0,
	spiral_rad = 0,
	spiral_ang = 0,
	slices     = 2,
	interior   = false,
	anchor     = CENTER,
	spin       = 0,
	orient     = UP
) {
	thickness = face_width * cos(bevelang);
	slices = spiral_rad==0? 1 : slices;
	spiral_rad = spiral_rad==0? 10000 : spiral_rad;
	p1 = pitch_radius(pitch, teeth);
	r1 = root_radius(pitch, teeth, clearance, interior);
	c1 = outer_radius(pitch, teeth, clearance, interior);
	dx = thickness * tan(bevelang);
	dy = (p1-r1) * sin(bevelang);
	scl = (p1-dx)/p1;
	p2 = pitch_radius(pitch*scl, teeth);
	r2 = root_radius(pitch*scl, teeth, clearance, interior);
	c2 = outer_radius(pitch*scl, teeth, clearance, interior);
	slice_u = 1/slices;
	Rm = (p1+p2)/2;
	H = spiral_rad * cos(spiral_ang);
	V = Rm - abs(spiral_rad) * sin(spiral_ang);
	spiral_cp = [H,V,0];
	S = norm(spiral_cp);
	theta_r = acos((S*S+spiral_rad*spiral_rad-p1*p1)/(2*S*spiral_rad)) - acos((S*S+spiral_rad*spiral_rad-p2*p2)/(2*S*spiral_rad));
	theta_ro = acos((S*S+spiral_rad*spiral_rad-p1*p1)/(2*S*spiral_rad)) - acos((S*S+spiral_rad*spiral_rad-Rm*Rm)/(2*S*spiral_rad));
	theta_ri = theta_r - theta_ro;
	extent_u = 2*(p2-r2)*tan(bevelang) / thickness;
	slice_us = concat(
		[for (u = [0:slice_u:1+extent_u]) u]
	);
	lsus = len(slice_us);
	vertices = concat(
		[
			for (u=slice_us, tooth=[0:1:teeth-1]) let(
				p = lerp(p1,p2,u),
				r = lerp(r1,r2,u),
				theta = lerp(-theta_ro, theta_ri, u),
				profile = gear_tooth_profile(
					pitch     = pitch*(p/p1),
					teeth     = teeth,
					PA        = PA,
					clearance = clearance,
					backlash  = backlash,
					interior  = interior,
					valleys   = false
				),
				pp = rot(theta, cp=spiral_cp, p=[0,Rm,0]),
				ang = atan2(pp.y,pp.x)-90,
				pts = affine3d_apply(pts=profile, affines=[
					move([0,-p,0]),
					rot([0,ang,0]),
					rot([bevelang,0,0]),
					move(pp),
					rot(tooth*360/teeth),
					move([0,0,thickness*u])
				])
			) each pts
		], [
			[0,0,-dy], [0,0,thickness]
		]
	);
	lcnt = (len(vertices)-2)/lsus/teeth;
	function _gv(layer,tooth,i) = ((layer*teeth)+(tooth%teeth))*lcnt+(i%lcnt);
	function _lv(layer,i) = layer*teeth*lcnt+(i%(teeth*lcnt));
	faces = concat(
		[
			for (sl=[0:1:lsus-2], i=[0:1:lcnt*teeth-1]) each [
				[_lv(sl,i), _lv(sl+1,i), _lv(sl,i+1)],
				[_lv(sl+1,i), _lv(sl+1,i+1), _lv(sl,i+1)]
			]
		], [
			for (tooth=[0:1:teeth-1], i=[0:1:lcnt/2-1]) each [
				[_gv(0,tooth,i), _gv(0,tooth,i+1), _gv(0,tooth,lcnt-1-(i+1))],
				[_gv(0,tooth,i), _gv(0,tooth,lcnt-1-(i+1)), _gv(0,tooth,lcnt-1-i)],
				[_gv(lsus-1,tooth,i), _gv(lsus-1,tooth,lcnt-1-(i+1)), _gv(lsus-1,tooth,i+1)],
				[_gv(lsus-1,tooth,i), _gv(lsus-1,tooth,lcnt-1-i), _gv(lsus-1,tooth,lcnt-1-(i+1))],
			]
		], [
			for (tooth=[0:1:teeth-1]) each [
				[len(vertices)-2, _gv(0,tooth,0), _gv(0,tooth,lcnt-1)],
				[len(vertices)-2, _gv(0,tooth,lcnt-1), _gv(0,tooth+1,0)],
				[len(vertices)-1, _gv(lsus-1,tooth,lcnt-1), _gv(lsus-1,tooth,0)],
				[len(vertices)-1, _gv(lsus-1,tooth+1,0), _gv(lsus-1,tooth,lcnt-1)],
			]
		]
	);
	orient_and_anchor([p1, p1, thickness], orient, anchor, spin=spin, size2=[p2,p2], geometry="cylinder", chain=true) {
		union() {
			difference() {
				down(thickness/2) {
					polyhedron(points=vertices, faces=faces, convexity=floor(teeth/2));
				}
				if (shaft_diam > 0) {
					cylinder(h=2*thickness+1, r=shaft_diam/2, center=true, $fn=max(12,segs(shaft_diam/2)));
				}
				if (bevelang != 0) {
					h = (c1-r1)/tan(45);
					down(thickness/2+dy) {
						difference() {
							cube([2*c1/cos(45),2*c1/cos(45),2*h], center=true);
							cylinder(h=h, r1=r1-0.5, r2=c1-0.5, center=false, $fn=teeth*4);
						}
					}
					up(thickness/2-0.01) {
						cylinder(h=(c2-r2)/tan(45)*5, r1=r2-0.5, r2=lerp(r2-0.5,c2-0.5,5), center=false, $fn=teeth*4);
					}
				}
			}
		}
		children();
	}
}


// Module: rack()
// Description:
//   The module `rack()` gives a rack, which is a bar with teeth.  A
//   rack can mesh with any gear that has the same `pitch` and
//   `PA`.
// Arguments:
//   pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.
//   teeth = Total number of teeth along the rack
//   thickness = Thickness of rack in mm (affects each tooth)
//   height = Height of rack in mm, from tooth top to back of rack.
//   PA = Controls how straight or bulged the tooth sides are. In degrees.
//   backlash = Gap between two meshing teeth, in the direction along the circumference of the pitch circle
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
// Anchors:
//   "adendum" = At the tips of the teeth, at the center of rack.
//   "adendum-left" = At the tips of the teeth, at the left end of the rack.
//   "adendum-right" = At the tips of the teeth, at the right end of the rack.
//   "adendum-top" = At the tips of the teeth, at the top of the rack.
//   "adendum-bottom" = At the tips of the teeth, at the bottom of the rack.
//   "dedendum" = At the base of the teeth, at the center of rack.
//   "dedendum-left" = At the base of the teeth, at the left end of the rack.
//   "dedendum-right" = At the base of the teeth, at the right end of the rack.
//   "dedendum-top" = At the base of the teeth, at the top of the rack.
//   "dedendum-bottom" = At the base of the teeth, at the bottom of the rack.
// Example:
//   rack(pitch=5, teeth=10, thickness=5, height=5, PA=20);
module rack(
	pitch     = 5,
	teeth     = 20,
	thickness = 5,
	height    = 10,
	PA        = 28,
	backlash  = 0.0,
	clearance = undef,
	anchor    = CENTER,
	spin      = 0,
	orient    = UP
) {
	a = adendum(pitch);
	d = dedendum(pitch, clearance);
	xa = a * sin(PA);
	xd = d * sin(PA);
	l = teeth * pitch;
	anchors = [
		anchorpt("adendum",         [0,a,0],             BACK),
		anchorpt("adendum-left",    [-l/2,a,0],          LEFT),
		anchorpt("adendum-right",   [l/2,a,0],           RIGHT),
		anchorpt("adendum-top",     [0,a,thickness/2],   UP),
		anchorpt("adendum-bottom",  [0,a,-thickness/2],  DOWN),
		anchorpt("dedendum",        [0,-d,0],            BACK),
		anchorpt("dedendum-left",   [-l/2,-d,0],         LEFT),
		anchorpt("dedendum-right",  [l/2,-d,0],          RIGHT),
		anchorpt("dedendum-top",    [0,-d,thickness/2],  UP),
		anchorpt("dedendum-bottom", [0,-d,-thickness/2], DOWN),
	];
	orient_and_anchor([l, 2*abs(a-height), thickness], orient, anchor, spin=spin, anchors=anchors, chain=true) {
		left((teeth-1)*pitch/2) {
			linear_extrude(height = thickness, center = true, convexity = 10) {
				for (i = [0:1:teeth-1] ) {
					translate([i*pitch,0,0]) {
						polygon(
							points=[
								[-1/2 * pitch - 0.01,          a-height],
								[-1/2 * pitch,                 -d],
								[-1/4 * pitch + backlash - xd, -d],
								[-1/4 * pitch + backlash + xa,  a],
								[ 1/4 * pitch - backlash - xa,  a],
								[ 1/4 * pitch - backlash + xd, -d],
								[ 1/2 * pitch,                 -d],
								[ 1/2 * pitch + 0.01,          a-height],
							]
						);
					}
				}
			}
		}
		children();
	}
}


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
pitch = 9; //all meshing gears need the same `pitch` (and the same `PA`)
thickness    = 6;
hole         = 3;
height       = 12;

d1 =pitch_radius(pitch,n1);
d12=pitch_radius(pitch,n1) + pitch_radius(pitch,n2);
d13=pitch_radius(pitch,n1) + pitch_radius(pitch,n3);
d14=pitch_radius(pitch,n1) + pitch_radius(pitch,n4);

translate([ 0,    0, 0]) rotate([0,0, $t*360/n1])                 color([1.00,0.75,0.75]) gear(pitch,n1,thickness,hole);
translate([ 0,  d12, 0]) rotate([0,0,-($t+n2/2-0*n1+1/2)*360/n2]) color([0.75,1.00,0.75]) gear(pitch,n2,thickness,hole);
translate([ d13,  0, 0]) rotate([0,0,-($t-n3/4+n1/4+1/2)*360/n3]) color([0.75,0.75,1.00]) gear(pitch,n3,thickness,hole);
translate([ d13,  0, 0]) rotate([0,0,-($t-n3/4+n1/4+1/2)*360/n3]) color([0.75,0.75,1.00]) gear(pitch,n3,thickness,hole);
translate([-d14,  0, 0]) rotate([0,0,-($t-n4/4-n1/4+1/2-floor(n4/4)-3)*360/n4]) color([1.00,0.75,0.50]) gear(pitch,n4,thickness,hole,hide=n4-3);
translate([(-floor(n5/2)-floor(n1/2)+$t+n1/2-1/2)*9, -d1+0.0, 0]) rotate([0,0,0]) color([0.75,0.75,0.75]) rack(pitch,n5,thickness,height);
*/


// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap

