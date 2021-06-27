//////////////////////////////////////////////////////////////////////////////////////////////
// LibFile: gears.scad
//   Spur Gears, Bevel Gears, Racks, Worms and Worm Gears.
//   Originally based on code by Leemon Baird, 2011, Leemon@Leemon.com
//   Almost completely rewritten for BOSL2 by Revar Desmera, 2017-2021, revarbat@gmail.com
// Includes:
//   include <BOSL2/std.scad>
//   include <BOSL2/gears.scad>
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
// Usage:
//   circp = circular_pitch(pitch|mod);
// Topics: Gears
// Description:
//   Get tooth density expressed as "circular pitch".
// Arguments:
//   pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.
//   mod = The metric module/modulus of the gear.
// Examples:
//   circp = circular_pitch(pitch=5);
//   circp = circular_pitch(mod=2);
function circular_pitch(pitch=5, mod) =
    let( pitch = is_undef(mod) ? pitch : pitch_value(mod) )
    pitch;


// Function: diametral_pitch()
// Usage:
//   dp = diametral_pitch(pitch|mod);
// Topics: Gears
// Description:
//   Get tooth density expressed as "diametral pitch".
// Arguments:
//   pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.
//   mod = The metric module/modulus of the gear.
// Examples:
//   dp = diametral_pitch(pitch=5);
//   dp = diametral_pitch(mod=2);
function diametral_pitch(pitch=5, mod) =
    let( pitch = is_undef(mod) ? pitch : pitch_value(mod) )
    PI / pitch;


// Function: pitch_value()
// Usage:
//   pitch = pitch_value(mod);
// Topics: Gears
// Description:
//   Get circular pitch in mm from module/modulus.  The circular pitch of a gear is the number of
//   millimeters per tooth around the pitch radius circle.
// Arguments:
//   mod = The module/modulus of the gear.
function pitch_value(mod) = mod * PI;


// Function: module_value()
// Usage:
//   mod = module_value(pitch);
// Topics: Gears
// Description:
//   Get tooth density expressed as "module" or "modulus" in millimeters.  The module is the pitch
//   diameter of the gear divided by the number of teeth on it.  For example, a gear with a pitch
//   diameter of 40mm, with 20 teeth on it will have a modulus of 2.
// Arguments:
//   pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.
function module_value(pitch=5) = pitch / PI;


// Function: adendum()
// Usage:
//   ad = adendum(pitch|mod);
// Topics: Gears
// Description:
//   The height of the top of a gear tooth above the pitch radius circle.
// Arguments:
//   pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.
//   mod = The metric module/modulus of the gear.
// Examples:
//   ad = adendum(pitch=5);
//   ad = adendum(mod=2);
// Example(2D):
//   pitch = 5; teeth = 17;
//   pr = pitch_radius(pitch=pitch, teeth=teeth);
//   adn = adendum(pitch=5);
//   #spur_gear2d(pitch=pitch, teeth=teeth);
//   color("black") {
//       stroke(circle(r=pr),width=0.1,closed=true);
//       stroke(circle(r=pr+adn),width=0.1,closed=true);
//   }
function adendum(pitch=5, mod) =
    let( pitch = is_undef(mod) ? pitch : pitch_value(mod) )
    module_value(pitch) * 1.0;


// Function: dedendum()
// Usage:
//   ddn = dedendum(pitch|mod, [clearance]);
// Topics: Gears
// Description:
//   The depth of the gear tooth valley, below the pitch radius.
// Arguments:
//   pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.
//   clearance = If given, sets the clearance between meshing teeth.
//   mod = The metric module/modulus of the gear.
// Examples:
//   ddn = dedendum(pitch=5);
//   ddn = dedendum(mod=2);
// Example(2D):
//   pitch = 5; teeth = 17;
//   pr = pitch_radius(pitch=pitch, teeth=teeth);
//   ddn = dedendum(pitch=5);
//   #spur_gear2d(pitch=pitch, teeth=teeth);
//   color("black") {
//       stroke(circle(r=pr),width=0.1,closed=true);
//       stroke(circle(r=pr-ddn),width=0.1,closed=true);
//   }
function dedendum(pitch=5, clearance, mod) =
    let( pitch = is_undef(mod) ? pitch : pitch_value(mod) )
    is_undef(clearance)? (1.25 * module_value(pitch)) :
    (module_value(pitch) + clearance);


// Function: pitch_radius()
// Usage:
//   pr = pitch_radius(pitch|mod, teeth);
// Topics: Gears
// Description:
//   Calculates the pitch radius for the gear.  Two mated gears will have their centers spaced apart
//   by the sum of the two gear's pitch radii.
// Arguments:
//   pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.
//   teeth = The number of teeth on the gear.
//   mod = The metric module/modulus of the gear.
// Examples:
//   pr = pitch_radius(pitch=5, teeth=11);
//   pr = pitch_radius(mod=2, teeth=20);
// Example(2D):
//   pr = pitch_radius(pitch=5, teeth=11);
//   #spur_gear2d(pitch=5, teeth=11);
//   color("black")
//       stroke(circle(r=pr),width=0.1,closed=true);
function pitch_radius(pitch=5, teeth=11, mod) =
    let( pitch = is_undef(mod) ? pitch : pitch_value(mod) )
    pitch * teeth / PI / 2;


// Function: outer_radius()
// Usage:
//   or = outer_radius(pitch|mod, teeth, [clearance], [interior]);
// Topics: Gears
// Description:
//   Calculates the outer radius for the gear. The gear fits entirely within a cylinder of this radius.
// Arguments:
//   pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.
//   teeth = The number of teeth on the gear.
//   clearance = If given, sets the clearance between meshing teeth.
//   interior = If true, calculate for an interior gear.
//   mod = The metric module/modulus of the gear.
// Examples:
//   or = outer_radius(pitch=5, teeth=20);
//   or = outer_radius(mod=2, teeth=16);
// Example(2D):
//   pr = outer_radius(pitch=5, teeth=11);
//   #spur_gear2d(pitch=5, teeth=11);
//   color("black")
//       stroke(circle(r=pr),width=0.1,closed=true);
function outer_radius(pitch=5, teeth=11, clearance, interior=false, mod) =
    let( pitch = is_undef(mod) ? pitch : pitch_value(mod) )
    pitch_radius(pitch, teeth) +
    (interior? dedendum(pitch, clearance) : adendum(pitch));


// Function: root_radius()
// Usage:
//   rr = root_radius(pitch|mod, teeth, [clearance], [interior]);
// Topics: Gears
// Description:
//   Calculates the root radius for the gear, at the base of the dedendum.
// Arguments:
//   pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.
//   teeth = The number of teeth on the gear.
//   clearance = If given, sets the clearance between meshing teeth.
//   interior = If true, calculate for an interior gear.
//   mod = The metric module/modulus of the gear.
// Examples:
//   rr = root_radius(pitch=5, teeth=11);
//   rr = root_radius(mod=2, teeth=16);
// Example(2D):
//   pr = root_radius(pitch=5, teeth=11);
//   #spur_gear2d(pitch=5, teeth=11);
//   color("black")
//       stroke(circle(r=pr),width=0.1,closed=true);
function root_radius(pitch=5, teeth=11, clearance, interior=false, mod) =
    let( pitch = is_undef(mod) ? pitch : pitch_value(mod) )
    pitch_radius(pitch, teeth) -
    (interior? adendum(pitch) : dedendum(pitch, clearance));


// Function: base_radius()
// Usage:
//   br = base_radius(pitch|mod, teeth, [pressure_angle]);
// Topics: Gears
// Description:
//   Get the base circle for involute teeth, at the base of the teeth.
// Arguments:
//   pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.
//   teeth = The number of teeth on the gear.
//   pressure_angle = Pressure angle in degrees.  Controls how straight or bulged the tooth sides are.
//   mod = The metric module/modulus of the gear.
// Examples:
//   br = base_radius(pitch=5, teeth=20, pressure_angle=20);
//   br = base_radius(mod=2, teeth=18, pressure_angle=20);
// Example(2D):
//   pr = base_radius(pitch=5, teeth=11);
//   #spur_gear2d(pitch=5, teeth=11);
//   color("black")
//       stroke(circle(r=pr),width=0.1,closed=true);
function base_radius(pitch=5, teeth=11, pressure_angle=28, mod) =
    let( pitch = is_undef(mod) ? pitch : pitch_value(mod) )
    pitch_radius(pitch, teeth) * cos(pressure_angle);


// Function: bevel_pitch_angle()
// Usage:
//   ang = bevel_pitch_angle(teeth, mate_teeth, [drive_angle]);
// Topics: Gears
// See Also: bevel_gear()
// Description:
//   Returns the correct pitch angle for a bevel gear with a given number of tooth, that is
//   matched to another bevel gear with a (possibly different) number of teeth.
// Arguments:
//   teeth = Number of teeth that this gear has.
//   mate_teeth = Number of teeth that the matching gear has.
//   drive_angle = Angle between the drive shafts of each gear.  Default: 90º.
// Examples:
//   ang = bevel_pitch_angle(teeth=18, mate_teeth=30);
// Example(2D):
//   t1 = 13; t2 = 19; pitch=5;
//   pang = bevel_pitch_angle(teeth=t1, mate_teeth=t2, drive_angle=90);
//   color("black") {
//       zrot_copies([0,pang])
//           stroke([[0,0,0], [0,-20,0]],width=0.2);
//       stroke(arc(r=3, angle=[270,270+pang]),width=0.2);
//   }
//   #bevel_gear(
//       pitch=5, teeth=t1, mate_teeth=t2,
//       spiral_angle=0, cutter_radius=1000,
//       slices=12, anchor="apex", orient=BACK
//   );
function bevel_pitch_angle(teeth, mate_teeth, drive_angle=90) =
    atan(sin(drive_angle)/((mate_teeth/teeth)+cos(drive_angle)));


// Function: worm_gear_thickness()
// Usage:
//   thick = worm_gear_thickness(pitch|mod, teeth, worm_diam, [worm_arc], [crowning], [clearance]);
// Topics: Gears
// See Also: worm(), worm_gear()
// Description:
//   Calculate the thickness of the worm gear.
// Arguments:
//   pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.  Default: 5
//   teeth = Total number of teeth along the rack.  Default: 30
//   worm_diam = The pitch diameter of the worm gear to match to.  Default: 30
//   worm_arc = The arc of the worm to mate with, in degrees. Default: 60 degrees
//   crowning = The amount to oversize the virtual hobbing cutter used to make the teeth, to add a slight crowning to the teeth to make them fir the work easier.  Default: 1
//   clearance = Clearance gap at the bottom of the inter-tooth valleys.
//   mod = The metric module/modulus of the gear.
// Examples:
//   thick = worm_gear_thickness(pitch=5, teeth=36, worm_diam=30);
//   thick = worm_gear_thickness(mod=2, teeth=28, worm_diam=25);
// Example(2D):
//   pitch = 5;  teeth=17;
//   worm_diam = 30; starts=2;
//   y = worm_gear_thickness(pitch=pitch, teeth=teeth, worm_diam=worm_diam);
//   #worm_gear(
//       pitch=pitch, teeth=teeth,
//       worm_diam=worm_diam,
//       worm_starts=starts,
//       orient=BACK
//   );
//   color("black") {
//       ycopies(y) stroke([[-25,0],[25,0]], width=0.5);
//       stroke([[-20,-y/2],[-20,y/2]],width=0.5,endcaps="arrow");
//   }
function worm_gear_thickness(pitch=5, teeth=30, worm_diam=30, worm_arc=60, crowning=1, clearance, mod) =
    let(
        pitch = is_undef(mod) ? pitch : pitch_value(mod),
        r = worm_diam/2 + crowning,
        pitch_thick = r * sin(worm_arc/2) * 2,
        pr = pitch_radius(pitch, teeth),
        rr = root_radius(pitch, teeth, clearance, false),
        pitchoff = (pr-rr) * sin(worm_arc/2),
        thickness = pitch_thick + 2*pitchoff
    ) thickness;


function _gear_polar(r,t) = r*[sin(t),cos(t)];
function _gear_iang(r1,r2) = sqrt((r2/r1)*(r2/r1) - 1)/PI*180 - acos(r1/r2);  //unwind a string this many degrees to go from radius r1 to radius r2
function _gear_q6(b,s,t,d) = _gear_polar(d,s*(_gear_iang(b,d)+t));            //point at radius d on the involute curve
function _gear_q7(f,r,b,r2,t,s) = _gear_q6(b,s,t,(1-f)*max(b,r)+f*r2);        //radius a fraction f up the curved side of the tooth


// Section: 2D Profiles


// Function&Module: gear_tooth_profile()
// Usage: As Module
//   gear_tooth_profile(pitch|mod, teeth, [pressure_angle], [clearance], [backlash], [interior], [valleys]);
// Usage: As Function
//   path = gear_tooth_profile(pitch|mod, teeth, [pressure_angle], [clearance], [backlash], [interior], [valleys]);
// Topics: Gears
// See Also: spur_gear2d()
// Description:
//   When called as a function, returns the 2D profile path for an individual gear tooth.
//   When called as a module, creates the 2D profile shape for an individual gear tooth.
// Arguments:
//   pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.
//   teeth = Total number of teeth on the spur gear that this is a tooth for.
//   pressure_angle = Pressure Angle.  Controls how straight or bulged the tooth sides are. In degrees.
//   clearance = Gap between top of a tooth on one gear and bottom of valley on a meshing gear (in millimeters)
//   backlash = Gap between two meshing teeth, in the direction along the circumference of the pitch circle
//   interior = If true, create a mask for difference()ing from something else.
//   valleys = If true, add the valley bottoms on either side of the tooth.  Default: true
//   center = If true, centers the pitch circle of the tooth profile at the origin.  Default: false.
//   mod = The metric module/modulus of the gear.
// Example(2D):
//   gear_tooth_profile(pitch=5, teeth=20, pressure_angle=20);
// Example(2D): Metric Gear Tooth
//   gear_tooth_profile(mod=2, teeth=20, pressure_angle=20);
// Example(2D):
//   gear_tooth_profile(
//       pitch=5, teeth=20, pressure_angle=20, valleys=false
//   );
// Example(2D): As a function
//   path = gear_tooth_profile(
//       pitch=5, teeth=20, pressure_angle=20, valleys=false
//   );
//   stroke(path, width=0.1);
function gear_tooth_profile(
    pitch = 3,
    teeth = 11,
    pressure_angle = 28,
    clearance = undef,
    backlash = 0.0,
    interior = false,
    valleys = true,
    center = false,
    mod
) = let(
    pitch = is_undef(mod) ? pitch : pitch_value(mod),
    p = pitch_radius(pitch, teeth),
    c = outer_radius(pitch, teeth, clearance, interior),
    r = root_radius(pitch, teeth, clearance, interior),
    b = base_radius(pitch, teeth, pressure_angle),
    t  = pitch/2-backlash/2,                //tooth thickness at pitch circle
    k  = -_gear_iang(b, p) - t/2/p/PI*180,  //angle to where involute meets base circle on each side of tooth
    kk = r<b? k : -180/teeth,
    isteps = 5,
    pts = [
        if (valleys) each [
            _gear_polar(r-1, 180.1/teeth),
            _gear_polar(r, 180.1/teeth),
        ],
        _gear_polar(r, -kk),
        for (i=[0: 1:isteps]) _gear_q7(i/isteps,r,b,c,k,-1),
        for (i=[isteps:-1:0]) _gear_q7(i/isteps,r,b,c,k, 1),
        _gear_polar(r, kk),
        if (valleys) each [
            _gear_polar(r, -180.1/teeth),
            _gear_polar(r-1, -180.1/teeth),
        ]
    ],
    pts2 = center? fwd(p, p=pts) : pts
) pts2;


module gear_tooth_profile(
    pitch = 3,
    teeth = 11,
    pressure_angle = 28,
    backlash  = 0.0,
    clearance = undef,
    interior = false,
    valleys = true,
    center = false,
    mod
) {
    pitch = is_undef(mod) ? pitch : pitch_value(mod);
    r = root_radius(pitch, teeth, clearance, interior);
    fwd(r)
    polygon(
        points=gear_tooth_profile(
            pitch = pitch,
            teeth = teeth,
            pressure_angle = pressure_angle,
            backlash = backlash,
            clearance = clearance,
            interior = interior,
            valleys = valleys,
            center = center
        )
    );
}


// Function&Module: spur_gear2d()
// Usage: As Module
//   spur_gear2d(pitch|mod, teeth, [hide], [pressure_angle], [clearance], [backlash], [interior]);
// Usage: As Function
//   poly = spur_gear2d(pitch|mod, teeth, [hide], [pressure_angle], [clearance], [backlash], [interior]);
// Topics: Gears
// See Also: spur_gear()
// Description:
//   When called as a module, creates a 2D involute spur gear.  When called as a function, returns a
//   2D path for the perimeter of a 2D involute spur gear.  Normally, you should just specify the
//   first 2 parameters `pitch` and `teeth`, and let the rest be default values.
//   Meshing gears must match in `pitch`, `pressure_angle`, and `helical`, and be separated by
//   the sum of their pitch radii, which can be found with `pitch_radius()`.
// Arguments:
//   pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.
//   teeth = Total number of teeth around the spur gear.
//   hide = Number of teeth to delete to make this only a fraction of a circle
//   pressure_angle = Controls how straight or bulged the tooth sides are. In degrees.
//   clearance = Gap between top of a tooth on one gear and bottom of valley on a meshing gear (in millimeters)
//   backlash = Gap between two meshing teeth, in the direction along the circumference of the pitch circle
//   interior = If true, create a mask for difference()ing from something else.
//   mod = The metric module/modulus of the gear.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
// Example(2D): Typical Gear Shape
//   spur_gear2d(pitch=5, teeth=20);
// Example(2D): Metric Gear
//   spur_gear2d(mod=2, teeth=20);
// Example(2D): Lower Pressure Angle
//   spur_gear2d(pitch=5, teeth=20, pressure_angle=20);
// Example(2D): Partial Gear
//   spur_gear2d(pitch=5, teeth=20, hide=15, pressure_angle=20);
// Example(2D): Called as a Function
//   path = spur_gear2d(pitch=8, teeth=16);
//   polygon(path);
function spur_gear2d(
    pitch = 3,
    teeth = 11,
    hide = 0,
    pressure_angle = 28,
    clearance = undef,
    backlash = 0.0,
    interior = false,
    mod,
    anchor = CENTER,
    spin = 0
) = let(
    pitch = is_undef(mod) ? pitch : pitch_value(mod),
    pr = pitch_radius(pitch=pitch, teeth=teeth),
    pts = concat(
        [for (tooth = [0:1:teeth-hide-1])
            each rot(tooth*360/teeth,
                planar=true,
                p=gear_tooth_profile(
                    pitch = pitch,
                    teeth = teeth,
                    pressure_angle = pressure_angle,
                    clearance = clearance,
                    backlash = backlash,
                    interior = interior,
                    valleys = false
                )
            )
        ],
        hide>0? [[0,0]] : []
    )
) reorient(anchor,spin, two_d=true, r=pr, p=pts);


module spur_gear2d(
    pitch = 3,
    teeth = 11,
    hide = 0,
    pressure_angle = 28,
    clearance = undef,
    backlash = 0.0,
    interior = false,
    mod,
    anchor = CENTER,
    spin = 0
) {
    pitch = is_undef(mod) ? pitch : pitch_value(mod);
    path = spur_gear2d(
        pitch = pitch,
        teeth = teeth,
        hide = hide,
        pressure_angle = pressure_angle,
        clearance = clearance,
        backlash = backlash,
        interior = interior
    );
    pr = pitch_radius(pitch=pitch, teeth=teeth);
    attachable(anchor,spin, two_d=true, r=pr) {
        polygon(path);
        children();
    }
}


// Function&Module: rack2d()
// Usage: As a Function
//   path = rack2d(pitch|mod, teeth, height, [pressure_angle], [backlash]);
// Usage: As a Module
//   rack2d(pitch|mod, teeth, height, [pressure_angle], [backlash]);
// Topics: Gears
// See Also: spur_gear2d()
// Description:
//   This is used to create a 2D rack, which is a linear bar with teeth that a gear can roll along.
//   A rack can mesh with any gear that has the same `pitch` and `pressure_angle`.
//   When called as a function, returns a 2D path for the outline of the rack.
//   When called as a module, creates a 2D rack shape.
// Arguments:
//   pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.
//   teeth = Total number of teeth along the rack
//   height = Height of rack in mm, from tooth top to back of rack.
//   pressure_angle = Controls how straight or bulged the tooth sides are. In degrees.
//   backlash = Gap between two meshing teeth, in the direction along the circumference of the pitch circle
//   mod = The metric module/modulus of the gear.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
// Extra Anchors:
//   "adendum" = At the tips of the teeth, at the center of rack.
//   "adendum-left" = At the tips of the teeth, at the left end of the rack.
//   "adendum-right" = At the tips of the teeth, at the right end of the rack.
//   "dedendum" = At the height of the teeth, at the center of rack.
//   "dedendum-left" = At the height of the teeth, at the left end of the rack.
//   "dedendum-right" = At the height of the teeth, at the right end of the rack.
// Example(2D):
//   rack2d(pitch=5, teeth=10, height=10, pressure_angle=20);
// Example(2D): Called as a Function
//   path = rack2d(pitch=8, teeth=8, height=10, pressure_angle=28);
//   polygon(path);
function rack2d(
    pitch = 5,
    teeth = 20,
    height = 10,
    pressure_angle = 28,
    backlash = 0.0,
    clearance = undef,
    mod,
    anchor = CENTER,
    spin = 0
) =
    let(
        pitch = is_undef(mod) ? pitch : pitch_value(mod),
        a = adendum(pitch),
        d = dedendum(pitch, clearance)
    )
    assert(a+d < height)
    let(
        xa = a * sin(pressure_angle),
        xd = d * sin(pressure_angle),
        l = teeth * pitch,
        anchors = [
            anchorpt("adendum",         [   0, a,0],  BACK),
            anchorpt("adendum-left",    [-l/2, a,0],  LEFT),
            anchorpt("adendum-right",   [ l/2, a,0],  RIGHT),
            anchorpt("dedendum",        [   0,-d,0],  BACK),
            anchorpt("dedendum-left",   [-l/2,-d,0],  LEFT),
            anchorpt("dedendum-right",  [ l/2,-d,0],  RIGHT),
        ],
        path = [
            [-(teeth-1)/2 * pitch + -1/2 * pitch,  a-height],
            [-(teeth-1)/2 * pitch + -1/2 * pitch,  -d],
            for (i = [0:1:teeth-1]) let(
                off = (i-(teeth-1)/2) * pitch
            ) each [
                [off + -1/4 * pitch + backlash - xd, -d],
                [off + -1/4 * pitch + backlash + xa,  a],
                [off +  1/4 * pitch - backlash - xa,  a],
                [off +  1/4 * pitch - backlash + xd, -d],
            ],
            [ (teeth-1)/2 * pitch +  1/2 * pitch,  -d],
            [ (teeth-1)/2 * pitch +  1/2 * pitch,  a-height],
        ]
    ) reorient(anchor,spin, two_d=true, size=[l,2*abs(a-height)], anchors=anchors, p=path);


module rack2d(
    pitch = 5,
    teeth = 20,
    height = 10,
    pressure_angle = 28,
    backlash = 0.0,
    clearance = undef,
    mod,
    anchor = CENTER,
    spin = 0
) {
    pitch = is_undef(mod) ? pitch : pitch_value(mod);
    a = adendum(pitch);
    d = dedendum(pitch, clearance);
    l = teeth * pitch;
    anchors = [
        anchorpt("adendum",         [   0, a,0],  BACK),
        anchorpt("adendum-left",    [-l/2, a,0],  LEFT),
        anchorpt("adendum-right",   [ l/2, a,0],  RIGHT),
        anchorpt("dedendum",        [   0,-d,0],  BACK),
        anchorpt("dedendum-left",   [-l/2,-d,0],  LEFT),
        anchorpt("dedendum-right",  [ l/2,-d,0],  RIGHT),
    ];
    path = rack2d(
        pitch = pitch,
        teeth = teeth,
        height = height,
        pressure_angle = pressure_angle,
        backlash  = backlash,
        clearance = clearance
    );
    attachable(anchor,spin, two_d=true, size=[l, 2*abs(a-height)], anchors=anchors) {
        polygon(path);
        children();
    }
}



// Section: 3D Gears and Racks


// Function&Module: spur_gear()
// Usage: As a Module
//   spur_gear(pitch, teeth, thickness, [shaft_diam=], [hide], [pressure_angle], [clearance], [backlash], [helical], [slices], [interior]);
//   spur_gear(mod=, teeth=, thickness=, [shaft_diam=], ...);
// Usage: As a Function
//   vnf = spur_gear(pitch, teeth, thickness, [shaft_diam], ...);
//   vnf = spur_gear(mod=, teeth=, thickness=, [shaft_diam], ...);
// Topics: Gears
// See Also: rack()
// Description:
//   Creates a (potentially helical) involute spur gear.  The module `spur_gear()` gives an involute
//   spur gear, with reasonable defaults for all the parameters.  Normally, you should just choose the
//   first 4 parameters, and let the rest be default values.  The module `spur_gear()` gives a gear in
//   the XY plane, centered on the origin, with one tooth centered on the positive Y axis.  The most
//   important is `pitch_radius()`, which tells how far apart to space gears that are meshing, and
//   `outer_radius()`, which gives the size of the region filled by the gear.  A gear has a "pitch
//   circle", which is an invisible circle that cuts through the middle of each tooth (though not the
//   exact center). In order for two gears to mesh, their pitch circles should just touch.  So the
//   distance between their centers should be `pitch_radius()` for one, plus `pitch_radius()` for the
//   other, which gives the radii of their pitch circles.  In order for two gears to mesh, they must
//   have the same `pitch` and `pressure_angle` parameters.  `pitch` gives the number of millimeters
//   of arc around the pitch circle covered by one tooth and one space between teeth.  The
//   `pressure_angle` controls how flat or bulged the sides of the teeth are.  Common values include
//   14.5 degrees and 20 degrees, and occasionally 25.  Though I've seen 28 recommended for plastic
//   gears. Larger numbers bulge out more, giving stronger teeth, so 28 degrees is the default here.
//   The ratio of `teeth` for two meshing gears gives how many times one will make a full revolution
//   when the the other makes one full revolution.  If the two numbers are coprime (i.e.  are not both
//   divisible by the same number greater than 1), then every tooth on one gear will meet every tooth
//   on the other, for more even wear.  So coprime numbers of teeth are good.
// Arguments:
//   pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.
//   teeth = Total number of teeth around the entire perimeter
//   thickness = Thickness of gear in mm
//   shaft_diam = Diameter of the hole in the center, in mm.  Default: 0 (no shaft hole)
//   ---
//   hide = Number of teeth to delete to make this only a fraction of a circle
//   pressure_angle = Controls how straight or bulged the tooth sides are. In degrees.
//   clearance = Clearance gap at the bottom of the inter-tooth valleys.
//   backlash = Gap between two meshing teeth, in the direction along the circumference of the pitch circle
//   helical = Teeth are slanted around the spur gear at this angle away from the gear axis of rotation.
//   slices = Number of vertical layers to divide gear into.  Useful for refining gears with `helical`.
//   scale = Scale of top of gear compared to bottom.  Useful for making crown gears.
//   interior = If true, create a mask for difference()ing from something else.
//   mod = The metric module/modulus of the gear.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
// Example: Spur Gear
//   spur_gear(pitch=5, teeth=20, thickness=8, shaft_diam=5);
// Example: Metric Gear
//   spur_gear(mod=2, teeth=20, thickness=8, shaft_diam=5);
// Example: Helical Gear
//   spur_gear(
//       pitch=5, teeth=20, thickness=10,
//       shaft_diam=5, helical=-30, slices=12,
//       $fa=1, $fs=1
//   );
// Example(Anim,Frames=8,VPT=[0,30,0],VPR=[0,0,0],VPD=300): Assembly of Gears
//   n1 = 11; //red gear number of teeth
//   n2 = 20; //green gear
//   n3 = 5;  //blue gear
//   n4 = 16; //orange gear
//   n5 = 9;  //gray rack
//   pitch = 9; //all meshing gears need the same `pitch` (and the same `pressure_angle`)
//   thickness    = 6;
//   hole         = 3;
//   rack_base    = 12;
//   r1 = pitch_radius(pitch,n1);
//   r2 = pitch_radius(pitch,n2);
//   r3 = pitch_radius(pitch,n3);
//   r4 = pitch_radius(pitch,n4);
//   r5 = pitch_radius(pitch,n5);
//   a1 =  $t * 360 / n1;
//   a2 = -$t * 360 / n2 + 180/n2;
//   a3 = -$t * 360 / n3;
//   a4 = -$t * 360 / n4 - 7.5*180/n4;
//   color("#f77")              zrot(a1) spur_gear(pitch,n1,thickness,hole);
//   color("#7f7") back(r1+r2)  zrot(a2) spur_gear(pitch,n2,thickness,hole);
//   color("#77f") right(r1+r3) zrot(a3) spur_gear(pitch,n3,thickness,hole);
//   color("#fc7") left(r1+r4)  zrot(a4) spur_gear(pitch,n4,thickness,hole,hide=n4-3);
//   color("#ccc") fwd(r1) right(pitch*$t)
//       rack(pitch=pitch,teeth=n5,thickness=thickness,height=rack_base,anchor=CENTER,orient=BACK);
function spur_gear(
    pitch = 3,
    teeth = 11,
    thickness = 6,
    shaft_diam = 0,
    hide = 0,
    pressure_angle = 28,
    clearance = undef,
    backlash = 0.0,
    helical = 0,
    slices = 2,
    interior = false,
    mod,
    anchor = CENTER,
    spin = 0,
    orient = UP
) =
    let(
        pitch = is_undef(mod) ? pitch : pitch_value(mod),
        p = pitch_radius(pitch, teeth),
        c = outer_radius(pitch, teeth, clearance, interior),
        r = root_radius(pitch, teeth, clearance, interior),
        twist = atan2(thickness*tan(helical),p),
        rgn = [
            spur_gear2d(
                pitch = pitch,
                teeth = teeth,
                pressure_angle = pressure_angle,
                hide = hide,
                clearance = clearance,
                backlash = backlash,
                interior = interior
            ),
            if (shaft_diam > 0) circle(d=shaft_diam, $fn=max(12,segs(shaft_diam/2)))
        ],
        vnf = linear_sweep(rgn, height=thickness, center=true)
    ) reorient(anchor,spin,orient, h=thickness, r=p, p=vnf);


module spur_gear(
    pitch = 3,
    teeth = 11,
    thickness = 6,
    shaft_diam = 0,
    hide = 0,
    pressure_angle = 28,
    clearance = undef,
    backlash = 0.0,
    helical = 0,
    slices = 2,
    interior = false,
    mod,
    anchor = CENTER,
    spin = 0,
    orient = UP
) {
    pitch = is_undef(mod) ? pitch : pitch_value(mod);
    p = pitch_radius(pitch, teeth);
    c = outer_radius(pitch, teeth, clearance, interior);
    r = root_radius(pitch, teeth, clearance, interior);
    twist = atan2(thickness*tan(helical),p);
    attachable(anchor,spin,orient, r=p, l=thickness) {
        difference() {
            linear_extrude(height=thickness, center=true, convexity=teeth/2, twist=twist) {
                spur_gear2d(
                    pitch = pitch,
                    teeth = teeth,
                    pressure_angle = pressure_angle,
                    hide = hide,
                    clearance = clearance,
                    backlash = backlash,
                    interior = interior
                );
            }
            if (shaft_diam > 0) {
                cylinder(h=2*thickness+1, r=shaft_diam/2, center=true, $fn=max(12,segs(shaft_diam/2)));
            }
        }
        children();
    }
}



// Function&Module: bevel_gear()
// Usage: As a Module
//   bevel_gear(pitch|mod, teeth, face_width, pitch_angle, [shaft_diam], [hide], [pressure_angle], [clearance], [backlash], [cutter_radius], [spiral_angle], [slices], [interior]);
// Usage: As a Function
//   vnf = bevel_gear(pitch|mod, teeth, face_width, pitch_angle, [hide], [pressure_angle], [clearance], [backlash], [cutter_radius], [spiral_angle], [slices], [interior]);
// Topics: Gears
// See Also: bevel_pitch_angle()
// Description:
//   Creates a (potentially spiral) bevel gear.  The module `bevel_gear()` gives a bevel gear, with
//   reasonable defaults for all the parameters.  Normally, you should just choose the first 4
//   parameters, and let the rest be default values.  The module `bevel_gear()` gives a gear in the XY
//   plane, centered on the origin, with one tooth centered on the positive Y axis.  The various
//   functions below it take the same parameters, and return various measurements for the gear.  The
//   most important is `pitch_radius()`, which tells how far apart to space gears that are meshing,
//   and `outer_radius()`, which gives the size of the region filled by the gear.  A gear has a "pitch
//   circle", which is an invisible circle that cuts through the middle of each tooth (though not the
//   exact center). In order for two gears to mesh, their pitch circles should just touch.  So the
//   distance between their centers should be `pitch_radius()` for one, plus `pitch_radius()` for the
//   other, which gives the radii of their pitch circles.  In order for two gears to mesh, they must
//   have the same `pitch` and `pressure_angle` parameters.  `pitch` gives the number of millimeters of arc around
//   the pitch circle covered by one tooth and one space between teeth.  The `pressure_angle` controls how flat or
//   bulged the sides of the teeth are.  Common values include 14.5 degrees and 20 degrees, and
//   occasionally 25.  Though I've seen 28 recommended for plastic gears. Larger numbers bulge out
//   more, giving stronger teeth, so 28 degrees is the default here.  The ratio of `teeth` for two
//   meshing gears gives how many times one will make a full revolution when the the other makes one
//   full revolution.  If the two numbers are coprime (i.e.  are not both divisible by the same number
//   greater than 1), then every tooth on one gear will meet every tooth on the other, for more even
//   wear.  So coprime numbers of teeth are good.
// Arguments:
//   pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.  Default: 5
//   teeth = Total number of teeth around the entire perimeter.  Default: 20
//   face_width = Width of the toothed surface in mm, from inside to outside.  Default: 10
//   pitch_angle = Angle of beveled gear face.  Default: 45
//   mate_teeth = The number of teeth in the gear that this gear will mate with.  Overrides `pitch_angle` if given.
//   shaft_diam = Diameter of the hole in the center, in mm.  Module use only.  Default: 0 (no shaft hole)
//   hide = Number of teeth to delete to make this only a fraction of a circle.  Default: 0
//   pressure_angle = Controls how straight or bulged the tooth sides are. In degrees. Default: 28
//   clearance = Clearance gap at the bottom of the inter-tooth valleys.
//   backlash = Gap between two meshing teeth, in the direction along the circumference of the pitch circle.  Default: 0
//   cutter_radius = Radius of spiral arc for teeth.  If 0, then gear will not be spiral.  Default: 0
//   spiral_angle = The base angle for spiral teeth.  Default: 0
//   left_handed = If true, the gear returned will have a left-handed spiral.  Default: false
//   slices = Number of vertical layers to divide gear into.  Useful for refining gears with `spiral`.  Default: 1
//   interior = If true, create a mask for difference()ing from something else.
//   mod = The metric module/modulus of the gear.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
// Extra Anchors:
//   "apex" = At the pitch cone apex for the bevel gear.
//   "pitchbase" = At the natural height of the pitch radius of the beveled gear.
//   "flattop" = At the top of the flat top of the bevel gear.
// Example: Beveled Gear
//   bevel_gear(
//       pitch=5, teeth=36, face_width=10, shaft_diam=5,
//       pitch_angle=45, spiral_angle=0
//   );
// Example: Spiral Beveled Gear and Pinion
//   t1 = 16; t2 = 28;
//   bevel_gear(
//       pitch=5, teeth=t1, mate_teeth=t2,
//       slices=12, anchor="apex", orient=FWD
//   );
//   bevel_gear(
//       pitch=5, teeth=t2, mate_teeth=t1, left_handed=true,
//       slices=12, anchor="apex", spin=180/t2
//   );
// Example(Anim,Frames=4,VPD=175): Manual Spacing of Pinion and Gear
//   t1 = 14; t2 = 28; pitch=5;
//   back(pitch_radius(pitch=pitch, teeth=t2)) {
//     yrot($t*360/t1)
//     bevel_gear(
//       pitch=pitch, teeth=t1, mate_teeth=t2, shaft_diam=5,
//       slices=12, orient=FWD
//     );
//   }
//   down(pitch_radius(pitch=pitch, teeth=t1)) {
//     zrot($t*360/t2)
//     bevel_gear(
//       pitch=pitch, teeth=t2, mate_teeth=t1, left_handed=true,
//       shaft_diam=5, slices=12, spin=180/t2
//     );
//   }
function bevel_gear(
    pitch = 5,
    teeth = 20,
    face_width = 10,
    pitch_angle = 45,
    mate_teeth,
    hide = 0,
    pressure_angle = 20,
    clearance = undef,
    backlash = 0.0,
    cutter_radius = 30,
    spiral_angle = 35,
    left_handed = false,
    slices = 5,
    interior = false,
    mod,
    anchor = "pitchbase",
    spin = 0,
    orient = UP
) =
    let(
        pitch = is_undef(mod) ? pitch : pitch_value(mod),
        slices = cutter_radius==0? 1 : slices,
        pitch_angle = is_undef(mate_teeth)? pitch_angle : atan(teeth/mate_teeth),
        pr = pitch_radius(pitch, teeth),
        rr = root_radius(pitch, teeth, clearance, interior),
        pitchoff = (pr-rr) * sin(pitch_angle),
        ocone_rad = opp_ang_to_hyp(pr, pitch_angle),
        icone_rad = ocone_rad - face_width,
        cutter_radius = cutter_radius==0? 1000 : cutter_radius,
        midpr = (icone_rad + ocone_rad) / 2,
        radcp = [0, midpr] + polar_to_xy(cutter_radius, 180+spiral_angle),
        angC1 = law_of_cosines(a=cutter_radius, b=norm(radcp), c=ocone_rad),
        angC2 = law_of_cosines(a=cutter_radius, b=norm(radcp), c=icone_rad),
        radcpang = v_theta(radcp),
        sang = radcpang - (180-angC1),
        eang = radcpang - (180-angC2),
        profile = gear_tooth_profile(
            pitch = pitch,
            teeth = teeth,
            pressure_angle = pressure_angle,
            clearance = clearance,
            backlash = backlash,
            interior = interior,
            valleys = false,
            center = true
        ),
        verts1 = [
            for (v = lerpn(0,1,slices+1)) let(
                p = radcp + polar_to_xy(cutter_radius, lerp(sang,eang,v)),
                ang = v_theta(p)-90,
                dist = norm(p)
            ) [
                let(
                    u = dist / ocone_rad,
                    m = up((1-u) * pr / tan(pitch_angle)) *
                        up(pitchoff) *
                        zrot(ang/sin(pitch_angle)) *
                        back(u * pr) *
                        xrot(pitch_angle) *
                        scale(u)
                )
                for (tooth=[0:1:teeth-1])
                each apply(xflip() * zrot(360*tooth/teeth) * m, path3d(profile))
            ]
        ],
        botz = verts1[0][0].z,
        topz = last(verts1)[0].z,
        thickness = abs(topz - botz),
        cpz = (topz + botz) / 2,
        vertices = [for (x=verts1) reverse(x)],
        sides_vnf = vnf_vertex_array(vertices, caps=false, col_wrap=true, reverse=true),
        top_verts = last(vertices),
        bot_verts = vertices[0],
        gear_pts = len(top_verts),
        face_pts = gear_pts / teeth,
        top_faces =[
            for (i=[0:1:teeth-1], j=[0:1:(face_pts/2)-1]) each [
                [i*face_pts+j, (i+1)*face_pts-j-1, (i+1)*face_pts-j-2],
                [i*face_pts+j, (i+1)*face_pts-j-2, i*face_pts+j+1]
            ],
            for (i=[0:1:teeth-1]) each [
                [gear_pts, (i+1)*face_pts-1, i*face_pts],
                [gear_pts, ((i+1)%teeth)*face_pts, (i+1)*face_pts-1]
            ]
        ],
        vnf1 = vnf_merge([
            [
                [each top_verts, [0,0,top_verts[0].z]],
                top_faces
            ],
            [
                [each bot_verts, [0,0,bot_verts[0].z]],
                [for (x=top_faces) reverse(x)]
            ],
            sides_vnf
        ]),
        lvnf = left_handed? vnf1 : xflip(p=vnf1),
        vnf = down(cpz, p=lvnf),
        anchors = [
            anchorpt("pitchbase", [0,0,pitchoff-thickness/2]),
            anchorpt("flattop", [0,0,thickness/2]),
            anchorpt("apex", [0,0,hyp_ang_to_opp(ocone_rad,90-pitch_angle)+pitchoff-thickness/2])
        ]
    ) reorient(anchor,spin,orient, vnf=vnf, extent=true, anchors=anchors, p=vnf);


module bevel_gear(
    pitch = 5,
    teeth = 20,
    face_width = 10,
    pitch_angle = 45,
    mate_teeth,
    shaft_diam = 0,
    hide = 0,
    pressure_angle = 20,
    clearance = undef,
    backlash = 0.0,
    cutter_radius = 30,
    spiral_angle = 35,
    left_handed = false,
    slices = 5,
    interior = false,
    mod,
    anchor = "pitchbase",
    spin = 0,
    orient = UP
) {
    pitch = is_undef(mod) ? pitch : pitch_value(mod);
    slices = cutter_radius==0? 1 : slices;
    pitch_angle = is_undef(mate_teeth)? pitch_angle : atan(teeth/mate_teeth);
    pr = pitch_radius(pitch, teeth);
    ipr = pr - face_width*sin(pitch_angle);
    rr = root_radius(pitch, teeth, clearance, interior);
    pitchoff = (pr-rr) * sin(pitch_angle);
    vnf = bevel_gear(
        pitch = pitch,
        teeth = teeth,
        face_width = face_width,
        pitch_angle = pitch_angle,
        hide = hide,
        pressure_angle = pressure_angle,
        clearance = clearance,
        backlash = backlash,
        cutter_radius = cutter_radius,
        spiral_angle = spiral_angle,
        left_handed = left_handed,
        slices = slices,
        interior = interior,
        anchor=CENTER
    );
    axis_zs = [for (p=vnf[0]) if(norm(point2d(p)) < EPSILON) p.z];
    thickness = max(axis_zs) - min(axis_zs);
    anchors = [
        anchorpt("pitchbase", [0,0,pitchoff-thickness/2]),
        anchorpt("flattop", [0,0,thickness/2]),
        anchorpt("apex", [0,0,adj_ang_to_opp(pr,90-pitch_angle)+pitchoff-thickness/2])
    ];
    attachable(anchor,spin,orient, r1=pr, r2=ipr, h=thickness, anchors=anchors) {
        difference() {
            vnf_polyhedron(vnf, convexity=teeth/2);
            if (shaft_diam > 0) {
                cylinder(h=2*thickness+1, r=shaft_diam/2, center=true, $fn=max(12,segs(shaft_diam/2)));
            }
        }
        children();
    }
}


// Function&Module: rack()
// Usage: As a Module
//   rack(pitch, teeth, thickness, height, [pressure_angle=], [backlash=]);
//   rack(mod=, teeth=, thickness=, height=, [pressure_angle=], [backlash]=);
// Usage: As a Function
//   vnf = rack(pitch, teeth, thickness, height, [pressure_angle=], [backlash=]);
//   vnf = rack(mod=, teeth=, thickness=, height=, [pressure_angle=], [backlash=]);
// Topics: Gears
// See Also: spur_gear()
// Description:
//   This is used to create a 3D rack, which is a linear bar with teeth that a gear can roll along.
//   A rack can mesh with any gear that has the same `pitch` and `pressure_angle`.
//   When called as a function, returns a 3D [VNF](vnf.scad) for the rack.
//   When called as a module, creates a 3D rack shape.
// Arguments:
//   pitch = The circular pitch, or distance between teeth around the pitch circle, in mm. Default: 5
//   teeth = Total number of teeth along the rack.  Default: 20
//   thickness = Thickness of rack in mm (affects each tooth).  Default: 5
//   height = Height of rack in mm, from tooth top to back of rack.  Default: 10
//   ---
//   pressure_angle = Controls how straight or bulged the tooth sides are. In degrees.  Default: 28
//   backlash = Gap between two meshing teeth, in the direction along the circumference of the pitch circle.  Default: 0
//   clearance = Clearance gap at the bottom of the inter-tooth valleys.
//   helical = The angle of the rack teeth away from perpendicular to the rack length.  Used to match helical spur gear pinions.  Default: 0
//   mod = The metric module/modulus of the gear.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
// Extra Anchors:
//   "adendum" = At the tips of the teeth, at the center of rack.
//   "adendum-left" = At the tips of the teeth, at the left end of the rack.
//   "adendum-right" = At the tips of the teeth, at the right end of the rack.
//   "adendum-back" = At the tips of the teeth, at the back of the rack.
//   "adendum-front" = At the tips of the teeth, at the front of the rack.
//   "dedendum" = At the base of the teeth, at the center of rack.
//   "dedendum-left" = At the base of the teeth, at the left end of the rack.
//   "dedendum-right" = At the base of the teeth, at the right end of the rack.
//   "dedendum-back" = At the base of the teeth, at the back of the rack.
//   "dedendum-front" = At the base of the teeth, at the front of the rack.
// Example(VPR=[60,0,325],VPD=130):
//   rack(pitch=5, teeth=10, thickness=5, height=5, pressure_angle=20);
// Example: Rack for Helical Gear
//   rack(pitch=5, teeth=10, thickness=5, height=5, pressure_angle=20, helical=30);
// Example: Alternate Helical Gear
//   rack(pitch=5, teeth=10, thickness=5, height=5, pressure_angle=20, helical=-30);
// Example: Metric Rack
//   rack(mod=2, teeth=10, thickness=5, height=5, pressure_angle=20);
// Example(Anim,VPT=[0,0,12],VPD=100,Frames=6): Rack and Pinion
//   teeth1 = 16; teeth2 = 16;
//   pitch = 5; thick = 5; helical = 30;
//   pr = pitch_radius(pitch=pitch, teeth=teeth2);
//   right(pr*2*PI/teeth2*$t) rack(pitch=pitch, teeth=teeth1, thickness=thick, height=5, helical=helical);
//   up(pr) yrot(186.5-$t*360/teeth2)
//       spur_gear(pitch=pitch, teeth=teeth2, thickness=thick, helical=helical, shaft_diam=5, orient=BACK);
module rack(
    pitch = 5,
    teeth = 20,
    thickness = 5,
    height = 10,
    pressure_angle = 28,
    backlash = 0.0,
    clearance,
    helical=0,
    mod,
    anchor = CENTER,
    spin = 0,
    orient = UP
) {
    pitch = is_undef(mod) ? pitch : pitch_value(mod);
    a = adendum(pitch);
    d = dedendum(pitch, clearance);
    l = teeth * pitch;
    anchors = [
        anchorpt("adendum",         [0,0,a],             BACK),
        anchorpt("adendum-left",    [-l/2,0,a],          LEFT),
        anchorpt("adendum-right",   [ l/2,0,a],          RIGHT),
        anchorpt("adendum-front",   [0,-thickness/2,a],  DOWN),
        anchorpt("adendum-back",    [0, thickness/2,a],  UP),
        anchorpt("dedendum",        [0,0,-d],            BACK),
        anchorpt("dedendum-left",   [-l/2,0,-d],         LEFT),
        anchorpt("dedendum-right",  [ l/2,0,-d],         RIGHT),
        anchorpt("dedendum-front",  [0,-thickness/2,-d], DOWN),
        anchorpt("dedendum-back",   [0, thickness/2,-d], UP),
    ];
    attachable(anchor,spin,orient, size=[l, thickness, 2*abs(a-height)], anchors=anchors) {
        skew(sxy=tan(helical)) xrot(90) {
            linear_extrude(height=thickness, center=true, convexity=teeth*2) {
                rack2d(
                    pitch = pitch,
                    teeth = teeth,
                    height = height,
                    pressure_angle = pressure_angle,
                    backlash = backlash,
                    clearance = clearance
                );
            }
        }
        children();
    }
}


function rack(
    pitch = 5,
    teeth = 20,
    thickness = 5,
    height = 10,
    pressure_angle = 28,
    backlash = 0.0,
    clearance,
    helical=0,
    mod,
    anchor = CENTER,
    spin = 0,
    orient = UP
) =
    let(
        pitch = is_undef(mod) ? pitch : pitch_value(mod),
        a = adendum(pitch),
        d = dedendum(pitch, clearance),
        l = teeth * pitch,
        anchors = [
            anchorpt("adendum",         [0,0,a],             BACK),
            anchorpt("adendum-left",    [-l/2,0,a],          LEFT),
            anchorpt("adendum-right",   [ l/2,0,a],          RIGHT),
            anchorpt("adendum-front",   [0,-thickness/2,a],  DOWN),
            anchorpt("adendum-back",    [0, thickness/2,a],  UP),
            anchorpt("dedendum",        [0,0,-d],            BACK),
            anchorpt("dedendum-left",   [-l/2,0,-d],         LEFT),
            anchorpt("dedendum-right",  [ l/2,0,-d],         RIGHT),
            anchorpt("dedendum-front",  [0,-thickness/2,-d], DOWN),
            anchorpt("dedendum-back",   [0, thickness/2,-d], UP),
        ],
        path = rack2d(
            pitch = pitch,
            teeth = teeth,
            height = height,
            pressure_angle = pressure_angle,
            backlash = backlash,
            clearance = clearance
        ),
        vnf = linear_sweep(path, height=thickness, anchor="origin", orient=FWD),
        out = helical==0? vnf : skew(sxy=tan(helical), p=vnf)
    ) reorient(anchor,spin,orient, size=[l, thickness, 2*abs(a-height)], anchors=anchors, p=out);



// Function&Module: worm()
// Usage: As a Module
//   worm(pitch|mod, d, l, [starts], [left_handed], [pressure_angle], [backlash], [clearance]);
// Usage: As a Function
//   vnf = worm(pitch|mod, d, l, [starts], [left_handed], [pressure_angle], [backlash], [clearance]);
// Topics: Gears
// See Also: worm_gear()
// Description:
//   Creates a worm shape that can be matched to a worm gear.
// Arguments:
//   pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.  Default: 5
//   d = The diameter of the worm.  Default: 30
//   l = The length of the worm.  Default: 100
//   starts = The number of lead starts.  Default: 1
//   left_handed = If true, the gear returned will have a left-handed spiral.  Default: false
//   pressure_angle = Controls how straight or bulged the tooth sides are. In degrees. Default: 20
//   backlash = Gap between two meshing teeth, in the direction along the circumference of the pitch circle.  Default: 0
//   clearance = Clearance gap at the bottom of the inter-tooth valleys.
//   mod = The metric module/modulus of the gear.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
// Example:
//   worm(pitch=8, d=30, l=50, $fn=72);
// Example: Multiple Starts.
//   worm(pitch=8, d=30, l=50, starts=3, $fn=72);
// Example: Left Handed
//   worm(pitch=8, d=30, l=50, starts=3, left_handed=true, $fn=72);
// Example: Called as Function
//   vnf = worm(pitch=8, d=35, l=50, starts=2, left_handed=true, pressure_angle=20, $fn=72);
//   vnf_polyhedron(vnf);
function worm(
    pitch=5,
    d=30, l=100,
    starts=1,
    left_handed=false,
    pressure_angle=20,
    backlash=0,
    clearance,
    mod,
    anchor=CENTER,
    spin=0,
    orient=UP
) =
    let(
        pitch = is_undef(mod) ? pitch : pitch_value(mod),
        rack_profile = select(rack2d(
            pitch = pitch,
            teeth = starts,
            height = d,
            pressure_angle = pressure_angle,
            backlash = backlash,
            clearance = clearance
        ), 1, -2),
        polars = [
            for (i=idx(rack_profile)) let(
                p = rack_profile[i],
                a = 360 * p.x / pitch / starts
            ) [a, p.y + d/2]
        ],
        maxang = 360 / segs(d/2),
        refined_polars = [
            for (i=idx(polars,e=-2)) let(
                delta = polars[i+1].x - polars[i].x,
                steps = ceil(delta/maxang),
                step = delta/steps
            ) for (j = [0:1:steps-1])
            [polars[i].x + j*step, lerp(polars[i].y,polars[i+1].y, j/steps)]
        ],
        cross_sect = [ for (p = refined_polars) polar_to_xy(p.y, p.x) ],
        revs = l/pitch/starts,
        zsteps = ceil(revs*360/maxang),
        zstep = l/zsteps,
        astep = revs*360/zsteps,
        profiles = [
            for (i=[0:1:zsteps]) let(
                z = i*zstep - l/2,
                a = i*astep - 360*revs/2
            )
            apply(zrot(a)*up(z), path3d(cross_sect))
        ],
        rprofiles = [ for (prof=profiles) reverse(prof) ],
        vnf1 = vnf_vertex_array(rprofiles, caps=true, col_wrap=true, style="min_edge"),
        vnf = left_handed? xflip(p=vnf1) : vnf1
    ) reorient(anchor,spin,orient, d=d, l=l, p=vnf);


module worm(
    pitch=5,
    d=15, l=100,
    starts=1,
    left_handed=false,
    pressure_angle=20,
    backlash=0,
    clearance,
    mod,
    anchor=CENTER,
    spin=0,
    orient=UP
) {
    vnf = worm(
        pitch=pitch,
        starts=starts,
        d=d, l=l,
        left_handed=left_handed,
        pressure_angle=pressure_angle,
        backlash=backlash,
        clearance=clearance,
        mod=mod
    );
    attachable(anchor,spin,orient, d=d, l=l) {
        vnf_polyhedron(vnf, convexity=ceil(l/pitch)*2);
        children();
    }
}


// Function&Module: worm_gear()
// Usage: As a Module
//   worm_gear(pitch|mod, teeth, worm_diam, [worm_starts], [crowning], [left_handed], [pressure_angle], [backlash], [slices], [clearance], [shaft_diam]);
// Usage: As a Function
//   vnf = worm_gear(pitch|mod, teeth, worm_diam, [worm_starts], [crowning], [left_handed], [pressure_angle], [backlash], [slices], [clearance]);
// Topics: Gears
// See Also: worm()
// Description:
//   Creates a worm gear to match with a worm.
// Arguments:
//   pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.  Default: 5
//   teeth = Total number of teeth along the rack.  Default: 30
//   worm_diam = The pitch diameter of the worm gear to match to.  Default: 30
//   worm_starts = The number of lead starts on the worm gear to match to.  Default: 1
//   worm_arc = The arc of the worm to mate with, in degrees. Default: 60 degrees
//   crowning = The amount to oversize the virtual hobbing cutter used to make the teeth, to add a slight crowning to the teeth to make them fir the work easier.  Default: 1
//   left_handed = If true, the gear returned will have a left-handed spiral.  Default: false
//   pressure_angle = Controls how straight or bulged the tooth sides are. In degrees. Default: 20
//   backlash = Gap between two meshing teeth, in the direction along the circumference of the pitch circle.  Default: 0
//   clearance = Clearance gap at the bottom of the inter-tooth valleys.
//   slices = The number of vertical slices to refine the curve of the worm throat.  Default: 10
//   mod = The metric module/modulus of the gear.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
// Example: Right-Handed
//   worm_gear(pitch=5, teeth=36, worm_diam=30, worm_starts=1);
// Example: Left-Handed
//   worm_gear(pitch=5, teeth=36, worm_diam=30, worm_starts=1, left_handed=true);
// Example: Multiple Starts
//   worm_gear(pitch=5, teeth=36, worm_diam=30, worm_starts=4);
// Example: Metric Worm Gear
//   worm_gear(mod=2, teeth=32, worm_diam=30, worm_starts=1);
// Example(Anim,Frames=4,FrameMS=125,VPD=220,VPT=[-15,0,0]): Meshing Worm and Gear
//   $fn=36;
//   pitch = 5; starts = 4;
//   worm_diam = 30; worm_length = 50;
//   gear_teeth=36;
//   right(worm_diam/2)
//     yrot($t*360/starts)
//       worm(d=worm_diam, l=worm_length, pitch=pitch, starts=starts, orient=BACK);
//   left(pitch_radius(pitch=pitch, teeth=gear_teeth))
//     zrot(-$t*360/gear_teeth)
//       worm_gear(pitch=pitch, teeth=gear_teeth, worm_diam=worm_diam, worm_starts=starts);
// Example: Meshing Worm and Gear Metricly
//   $fn = 72;
//   modulus = 2; starts = 3;
//   worm_diam = 30; worm_length = 50;
//   gear_teeth=36;
//   right(worm_diam/2)
//       worm(d=worm_diam, l=worm_length, mod=modulus, starts=starts, orient=BACK);
//   left(pitch_radius(mod=modulus, teeth=gear_teeth))
//       worm_gear(mod=modulus, teeth=gear_teeth, worm_diam=worm_diam, worm_starts=starts);
// Example: Called as Function
//   vnf = worm_gear(pitch=8, teeth=30, worm_diam=30, worm_starts=1);
//   vnf_polyhedron(vnf);
function worm_gear(
    pitch = 5,
    teeth = 36,
    worm_diam = 30,
    worm_starts = 1,
    worm_arc = 60,
    crowning = 1,
    left_handed = false,
    pressure_angle = 20,
    backlash = 0,
    clearance,
    mod,
    slices = 10,
    anchor = CENTER,
    spin = 0,
    orient = UP
) =
    assert(worm_arc >= 10 && worm_arc <= 60)
    let(
        pitch = is_undef(mod) ? pitch : pitch_value(mod),
        p = pitch_radius(pitch, teeth),
        circ = 2 * PI * p,
        r1 = p + worm_diam/2 + crowning,
        r2 = worm_diam/2 + crowning,
        thickness = worm_gear_thickness(pitch=pitch, teeth=teeth, worm_diam=worm_diam, worm_arc=worm_arc, crowning=crowning, clearance=clearance),
        helical = pitch * worm_starts * worm_arc / 360 * 360 / circ,
        tooth_profile = reverse(gear_tooth_profile(
            pitch = pitch,
            teeth = teeth,
            pressure_angle = pressure_angle,
            clearance = clearance,
            backlash = backlash,
            valleys = false,
            center = true
        )),
        profiles = [
            for (slice = [0:1:slices]) let(
                u = slice/slices - 0.5,
                zang = u * worm_arc,
                tp = [0,r1,0] - spherical_to_xyz(r2, 90, 90+zang),
                zang2 = u * helical
            ) [
                for (i = [0:1:teeth-1]) each
                apply(
                    zrot(-i*360/teeth+zang2) *
                        move(tp) *
                        xrot(-zang) *
                        scale(cos(zang)),
                    path3d(tooth_profile)
                )
            ]
        ],
        top_verts = last(profiles),
        bot_verts = profiles[0],
        face_pts = len(tooth_profile),
        gear_pts = face_pts * teeth,
        top_faces =[
            for (i=[0:1:teeth-1], j=[0:1:(face_pts/2)-2]) each [
                [i*face_pts+j, (i+1)*face_pts-j-1, (i+1)*face_pts-j-2],
                [i*face_pts+j, (i+1)*face_pts-j-2, i*face_pts+j+1]
            ],
            for (i=[0:1:teeth-1]) each [
                [gear_pts, (i+1)*face_pts-1, i*face_pts],
                [gear_pts, ((i+1)%teeth)*face_pts, (i+1)*face_pts-1]
            ]
        ],
        sides_vnf = vnf_vertex_array(profiles, caps=false, col_wrap=true, style="min_edge"),
        vnf1 = vnf_merge([
            [
                [each top_verts, [0,0,top_verts[0].z]],
                [for (x=top_faces) reverse(x)]
            ],
            [
                [each bot_verts, [0,0,bot_verts[0].z]],
                top_faces
            ],
            sides_vnf
        ]),
        vnf = left_handed? xflip(p=vnf1) : vnf1
    ) reorient(anchor,spin,orient, r=p, l=thickness, p=vnf);


module worm_gear(
    pitch = 5,
    teeth = 36,
    worm_diam = 30,
    worm_starts = 1,
    worm_arc = 60,
    crowning = 1,
    left_handed = false,
    pressure_angle = 20,
    backlash = 0,
    slices = 10,
    clearance,
    mod,
    shaft_diam = 0,
    anchor = CENTER,
    spin = 0,
    orient = UP
) {
    pitch = is_undef(mod) ? pitch : pitch_value(mod);
    p = pitch_radius(pitch, teeth);
    vnf = worm_gear(
        pitch = pitch,
        teeth = teeth,
        worm_diam = worm_diam,
        worm_starts = worm_starts,
        worm_arc = worm_arc,
        crowning = crowning,
        left_handed = left_handed,
        pressure_angle = pressure_angle,
        backlash = backlash,
        slices = slices,
        clearance = clearance
    );
    thickness = pointlist_bounds(vnf[0])[1].z;
    attachable(anchor,spin,orient, r=p, l=thickness) {
        difference() {
            vnf_polyhedron(vnf, convexity=teeth/2);
            if (shaft_diam > 0) {
                cylinder(d=shaft_diam, l=worm_diam, center=true);
            }
        }
        children();
    }
}


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
