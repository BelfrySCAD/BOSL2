//////////////////////////////////////////////////////////////////////////////////////////////
// LibFile: gears.scad
//   Spur Gears, Bevel Gears, Racks, Worms and Worm Gears.
//   Inspired by code by Leemon Baird, 2011, Leemon@Leemon.com
// Includes:
//   include <BOSL2/std.scad>
//   include <BOSL2/gears.scad>
// FileGroup: Parts
// FileSummary: Gears, racks, worms, and worm gears.
//////////////////////////////////////////////////////////////////////////////////////////////


_GEAR_PITCH = 5;
_GEAR_HELICAL = 0;
_GEAR_THICKNESS = 10;
_GEAR_PA = 20;


$parent_gear_type = undef;
$parent_gear_pitch = undef;
$parent_gear_teeth = undef;
$parent_gear_pa = undef;
$parent_gear_helical = undef;
$parent_gear_thickness = undef;
$parent_gear_dir = undef;
$parent_gear_travel = 0;


function _inherit_gear_param(name, val, pval, dflt, invert=false) =
    is_undef(val)
      ? is_undef(pval)
        ? dflt
        : (invert?-1:1)*pval
      : is_undef(pval)
        ? assert(is_finite(val), str("Invalid ",name," value: ",val))
          val
        : (invert?-1:1)*val;


function _inherit_gear_pitch(fname,pitch,circ_pitch,diam_pitch,mod,warn=true) =
    pitch != undef?
        assert(is_finite(pitch) && pitch>0)
        warn? echo(str(
            "WARNING: The use of the argument pitch= in ", fname,
            " is deprecated.  Please use circ_pitch= instead."
        )) pitch : pitch :
    circ_pitch != undef?
        assert(is_finite(circ_pitch) && circ_pitch>0)
        circ_pitch :
    diam_pitch != undef?
        assert(is_finite(diam_pitch) && diam_pitch>0)
        pitch_value(diam_pitch=diam_pitch) :
    mod != undef?
        assert(is_finite(mod) && mod>0)
        pitch_value(mod) :
    $parent_gear_pitch != undef? $parent_gear_pitch :
    5;

function _inherit_gear_pa(pressure_angle) =
    _inherit_gear_param("pressure_angle", pressure_angle, $parent_gear_pa, dflt=20);

function _inherit_gear_helical(helical,invert=false) =
    _inherit_gear_param("helical", helical, $parent_gear_helical, dflt=0, invert=invert);

function _inherit_gear_thickness(thickness) =
    _inherit_gear_param("thickness", thickness, $parent_gear_thickness, dflt=10);


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


// Section: Gears

// Function&Module: spur_gear()
// Synopsis: Creates a spur gear, helical gear, or internal ring gear.
// SynTags: Geom, VNF
// Topics: Gears, Parts
// See Also: rack(), spur_gear(), spur_gear2d(), bevel_gear()
// Usage: As a Module
//   spur_gear(circ_pitch, teeth, thickness, [shaft_diam], [hide=], [pressure_angle=], [clearance=], [backlash=], [helical=], [slices=], [internal=], [herringbone=]) [ATTACHMENTS];
//   spur_gear(mod=, teeth=, thickness=, [shaft_diam=], ...) [ATTACHMENTS];
// Usage: As a Function
//   vnf = spur_gear(circ_pitch, teeth, thickness, [shaft_diam=], ...);
//   vnf = spur_gear(mod=, teeth=, thickness=, [shaft_diam=], ...);
// Description:
//   Creates a involute spur gear, helical gear, or a mask for an internal ring gear.  The module `spur_gear()` gives an involute
//   spur gear, with reasonable defaults for all the parameters.  Normally, you should just choose the
//   first 4 parameters, and let the rest be default values.  Spur gears have straight teeth and
//   mesh together on parallel shafts without creating any axial thrust.  The teeth engage suddenly across their
//   entire width, creating stress and noise.  Helical gears have angled teeth and engage more gradually, so they
//   run more smoothly and quietly, however they do produce thrust along the gear axis.  This can be
//   circumvented using herringbone or double helical gears, which have no axial thrust and also self-align.
//   Helical gears can mesh along shafts that are not parallel, where the angle between the shafts is
//   the sum of the helical angles of the two gears.
//   .
//   The module `spur_gear()` gives a gear in
//   the XY plane, centered on the origin, with one tooth centered on the positive Y axis.  The most
//   important function is `mesh_radius()`, which tells how far apart to space gears that are meshing, and
//   `outer_radius()`, which gives the size of the region filled by the gear.  A gear has a "pitch
//   circle", which is an invisible circle that cuts through the middle of each tooth (though not the
//   exact center). In order for two gears to mesh, their pitch circles should just touch.  So the
//   distance between their centers should be `mesh_radius()` for one, plus `mesh_radius()` for the
//   other, which gives the overall meshing distance.  In order for two gears to mesh, they must
//   have the same `pitch` and `pressure_angle` parameters.  `pitch` gives the number of millimeters
//   of arc around the pitch circle covered by one tooth and one space between teeth.  The
//   `pressure_angle` controls how flat or bulged the sides of the teeth are.  Common values include
//   14.5 degrees and 20 degrees, and occasionally 25.  The default here is 20 degrees.
//   The ratio of `teeth` for two meshing gears gives how many times one will make a full revolution
//   when the the other makes one full revolution.  If the two numbers are coprime (i.e.  are not both
//   divisible by the same number greater than 1), then every tooth on one gear will meet every tooth
//   on the other, for more even wear.  So coprime numbers of teeth are good.
//   Normally, If the number of teeth is too few, gear tooth shapes may be undercut to allow meshing
//   with other gears.  If this is the case, profile shifting will automatically be applies to enlarge
//   the teeth, removing the undercut.  This may add to the distance needed between gears.
//   If you with to override this correction, you can use `profile_shift=0`, or set it to a specific
//   value like 0.5.
// Arguments:
//   circ_pitch = The circular pitch, or distance in mm between teeth around the pitch circle.
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
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  Note that the diametral pitch is a completely different thing than the pitch diameter.
//   mod = The metric module/modulus of the gear, or mm of pitch diameter per tooth.
//   internal = If true, create a mask for difference()ing from something else.
//   profile_shift = Profile shift factor x.
//   herringbone = If true, and helical is set, creates a herringbone gear.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Side Effects:
//   If internal is true then the default tag is "remove"
// Example: Spur Gear
//   spur_gear(circ_pitch=5, teeth=20, thickness=8, shaft_diam=5);
// Example: Metric Gear
//   spur_gear(mod=2, teeth=20, thickness=8, shaft_diam=5);
// Example: Helical Gear
//   spur_gear(
//       circ_pitch=5, teeth=20, thickness=10,
//       shaft_diam=5, helical=-30, slices=12,
//       $fa=1, $fs=1
//   );
// Example: Herringbone Gear
//   spur_gear(
//       circ_pitch=5, teeth=20, thickness=10, shaft_diam=5,
//       helical=30, herringbone=true, slices=5
//   );
// Example(Big): Effects of Profile Shifting.
//   circ_pitch=5; teeth=7; thick=10; shaft=5; strokewidth=0.2;
//   pr = pitch_radius(circ_pitch, teeth);
//   left(10) {
//       profile_shift = 0;
//       mr = mesh_radius(circ_pitch,teeth,profile_shift=profile_shift);
//       back(mr) spur_gear(circ_pitch, teeth, thick, shaft, profile_shift=profile_shift);
//       rack(circ_pitch, teeth=3, thickness=thick, height=5, orient=BACK);
//       color("black") up(thick/2) linear_extrude(height=0.1) {
//           back(mr) dashed_stroke(circle(r=pr), width=strokewidth, closed=true);
//           dashed_stroke([[-7.5,0],[7.5,0]], width=strokewidth);
//       }
//   }
//   right(10) {
//       profile_shift = 0.59;
//       mr = mesh_radius(circ_pitch,teeth,profile_shift=profile_shift);
//       back(mr) spur_gear(circ_pitch, teeth, thick, shaft, profile_shift=profile_shift);
//       rack(circ_pitch, teeth=3, thickness=thick, height=5, orient=BACK);
//       color("black") up(thick/2) linear_extrude(height=0.1) {
//           back(mr)
//               dashed_stroke(circle(r=pr), width=strokewidth, closed=true);
//           dashed_stroke([[-7.5,0],[7.5,0]], width=strokewidth);
//       }
//   }
// Example(Anim,Frames=8,VPT=[0,30,0],VPR=[0,0,0],VPD=300): Assembly of Gears
//   n1 = 11; //red gear number of teeth
//   n2 = 20; //green gear
//   n3 = 6;  //blue gear
//   n4 = 16; //orange gear
//   n5 = 9;  //gray rack
//   circ_pitch = 9; //all meshing gears need the same `circ_pitch` (and the same `pressure_angle`)
//   thickness    = 6;
//   hole         = 3;
//   rack_base    = 12;
//   r1 = mesh_radius(circ_pitch,n1);
//   r2 = mesh_radius(circ_pitch,n2);
//   r3 = mesh_radius(circ_pitch,n3);
//   r4 = mesh_radius(circ_pitch,n4);
//   r5 = mesh_radius(circ_pitch,n5);
//   a1 =  $t * 360 / n1;
//   a2 = -$t * 360 / n2 + 180/n2;
//   a3 = -$t * 360 / n3 - 3*90/n3;
//   a4 = -$t * 360 / n4 - 3.5*180/n4;
//   color("#f77")              zrot(a1) spur_gear(circ_pitch,n1,thickness,hole);
//   color("#7f7") back(r1+r2)  zrot(a2) spur_gear(circ_pitch,n2,thickness,hole);
//   color("#77f") right(r1+r3) zrot(a3) spur_gear(circ_pitch,n3,thickness,hole);
//   color("#fc7") left(r1+r4)  zrot(a4) spur_gear(circ_pitch,n4,thickness,hole,hide=n4-3);
//   color("#ccc") fwd(r1) right(circ_pitch*$t)
//       rack(pitch=circ_pitch,teeth=n5,thickness=thickness,height=rack_base,anchor=CENTER,orient=BACK);
// Example: Helical gears meshing with non-parallel shafts
//   ang1 = 30;
//   ang2 = 10;
//   circ_pitch = 5;
//   n = 20;
//   r1 = mesh_radius(circ_pitch,n,helical=ang1);
//   r2 = mesh_radius(circ_pitch,n,helical=ang2);
//   left(r1) spur_gear(
//          circ_pitch, teeth=n, thickness=10,
//          shaft_diam=5, helical=ang1, slices=12,
//          gear_spin=-90
//      );
//   right(r2)
//   xrot(ang1+ang2)
//   spur_gear(
//          circ_pitch=circ_pitch, teeth=n, thickness=10,
//          shaft_diam=5, helical=ang2, slices=12,
//          gear_spin=90-180/n
//      );
// Example(Anim,Frames=36,VPT=[0,0,0],VPR=[55,0,25],VPD=375): Planetary Gear Assembly
//   rteeth=56; pteeth=16; cteeth=24;
//   circ_pitch=5; thick=10; pa=20;
//   cr = mesh_radius(circ_pitch,cteeth);
//   pr = mesh_radius(circ_pitch,pteeth);
//   ring_gear(
//       circ_pitch=circ_pitch,
//       teeth=rteeth,
//       thickness=thick,
//       pressure_angle=pa);
//   for (a=[0:3]) {
//       zrot($t*90+a*90) back(cr+pr) {
//           color("green")
//           spur_gear(
//               circ_pitch=circ_pitch,
//               teeth=pteeth,
//               thickness=thick,
//               shaft_diam=5,
//               pressure_angle=pa,
//               spin=-$t*90*rteeth/pteeth);
//       }
//   }
//   color("orange")
//   zrot($t*90*rteeth/cteeth+$t*90+180/cteeth)
//   spur_gear(
//       circ_pitch=circ_pitch,
//       teeth=cteeth,
//       thickness=thick,
//       shaft_diam=5,
//       pressure_angle=pa);

function spur_gear(
    circ_pitch,
    teeth,
    thickness,
    shaft_diam = 0,
    hide = 0,
    pressure_angle,
    clearance,
    backlash = 0.0,
    helical,
    interior,
    internal,
    profile_shift,
    slices,
    herringbone=false,
    diam_pitch,
    mod,
    pitch,
    gear_spin = 0,
    anchor = CENTER,
    spin = 0,
    orient = UP
) =
    let(
        dummy = !is_undef(interior) ? echo("In spur_gear(), the argument 'interior=' has been deprecated, and may be removed in the future.  Please use 'internal=' instead."):0,
        internal = first_defined([internal,interior,false]),
        circ_pitch = _inherit_gear_pitch("spur_gear()", pitch, circ_pitch, diam_pitch, mod),
        PA = _inherit_gear_pa(pressure_angle),
        helical = _inherit_gear_helical(helical, invert=!internal),
        thickness = _inherit_gear_thickness(thickness),
        profile_shift = default(profile_shift, auto_profile_shift(teeth,PA))
    )
    assert(is_integer(teeth) && teeth>3)
    assert(is_finite(thickness) && thickness>0)
    assert(is_finite(shaft_diam) && shaft_diam>=0)
    assert(is_integer(hide) && hide>=0 && hide<teeth)
    assert(is_finite(PA) && PA>=0 && PA<90, "Bad pressure_angle value.")
    assert(clearance==undef || (is_finite(clearance) && clearance>=0))
    assert(is_finite(backlash) && backlash>=0)
    assert(is_finite(helical) && abs(helical)<90)
    assert(is_bool(herringbone))
    assert(slices==undef || (is_integer(slices) && slices>0))
    assert(is_finite(profile_shift) && abs(profile_shift)<1)
    assert(is_finite(gear_spin))
    let(
        pr = pitch_radius(circ_pitch, teeth, helical),
        circum = 2 * PI * pr,
        twist = 360*thickness*tan(helical)/circum,
        slices = default(slices, ceil(twist/360*segs(pr)+1)),
        rgn = spur_gear2d(
                circ_pitch = circ_pitch,
                teeth = teeth,
                pressure_angle = PA,
                hide = hide,
                helical = helical,
                clearance = clearance,
                backlash = backlash,
                internal = internal,
                profile_shift = profile_shift,
                shaft_diam = shaft_diam
            ),
        rvnf = herringbone
          ? zrot(twist/2, p=linear_sweep(rgn, height=thickness, twist=twist, slices=slices, center=true))
          : let(
                wall_vnf = linear_sweep(rgn, height=thickness/2, twist=twist/2, slices=ceil(slices/2), center=false, caps=false),
                cap_vnf = vnf_from_region(rgn, transform=up(thickness/2)*zrot(twist/2))
            )
            vnf_join([
                wall_vnf, zflip(p=wall_vnf),
                cap_vnf,  zflip(p=cap_vnf),
            ]),
        vnf = zrot(gear_spin, p=rvnf)
    ) reorient(anchor,spin,orient, h=thickness, r=pr, p=vnf);


module spur_gear(
    circ_pitch,
    teeth,
    thickness,
    shaft_diam = 0,
    hide = 0,
    pressure_angle,
    clearance,
    backlash = 0.0,
    helical,
    internal,
    interior,
    profile_shift,
    slices,
    herringbone=false,
    pitch,
    diam_pitch,
    mod,
    gear_spin = 0,
    anchor = CENTER,
    spin = 0,
    orient = UP
) {
    dummy = !is_undef(interior) ? echo("In spur_gear(), the argument 'interior=' has been deprecated, and may be removed in the future.  Please use 'internal=' instead."):0;
    internal = first_defined([internal,interior,false]);
    circ_pitch = _inherit_gear_pitch("spur_gear()", pitch, circ_pitch, diam_pitch, mod);
    PA = _inherit_gear_pa(pressure_angle);
    helical = _inherit_gear_helical(helical, invert=!internal);
    thickness = _inherit_gear_thickness(thickness);
    profile_shift = default(profile_shift, auto_profile_shift(teeth,PA));
    checks =
        assert(is_integer(teeth) && teeth>3)
        assert(is_finite(thickness) && thickness>0)
        assert(is_finite(shaft_diam) && shaft_diam>=0)
        assert(is_integer(hide) && hide>=0 && hide<teeth)
        assert(is_finite(PA) && PA>=0 && PA<90, "Bad pressure_angle value.")
        assert(clearance==undef || (is_finite(clearance) && clearance>=0))
        assert(is_finite(backlash) && backlash>=0)
        assert(is_finite(helical) && abs(helical)<90)
        assert(is_bool(herringbone))
        assert(is_finite(profile_shift) && abs(profile_shift)<1)
        assert(slices==undef || (is_integer(slices) && slices>0))
        assert(is_finite(gear_spin));
    pr = pitch_radius(circ_pitch, teeth, helical);
    circum = 2 * PI * pr;
    twist = 360*thickness*tan(helical)/circum;
    slices = default(slices, ceil(twist/360*segs(pr)+1));
    default_tag("remove", internal) {
        attachable(anchor,spin,orient, r=pr, l=thickness) {
            zrot(gear_spin)
            if (herringbone) {
                zflip_copy() down(0.01)
                linear_extrude(
                    height=thickness/2+0.01, center=false,
                    twist=twist/2, slices=ceil(slices/2),
                    convexity=teeth/2
                ) {
                    spur_gear2d(
                        circ_pitch = circ_pitch,
                        teeth = teeth,
                        pressure_angle = PA,
                        hide = hide,
                        helical = helical,
                        clearance = clearance,
                        backlash = backlash,
                        internal = internal,
                        profile_shift = profile_shift,
                        shaft_diam = shaft_diam
                    );
                }
            } else {
                zrot(twist/2)
                linear_extrude(
                    height=thickness, center=true,
                    twist=twist, slices=slices,
                    convexity=teeth/2
                ) {
                    spur_gear2d(
                        circ_pitch = circ_pitch,
                        teeth = teeth,
                        pressure_angle = PA,
                        hide = hide,
                        helical = helical,
                        clearance = clearance,
                        backlash = backlash,
                        internal = internal,
                        profile_shift = profile_shift,
                        shaft_diam = shaft_diam
                    );
                }
            }
            union() {
                $parent_gear_type = "spur";
                $parent_gear_pitch = circ_pitch;
                $parent_gear_teeth = teeth;
                $parent_gear_pa = PA;
                $parent_gear_helical = helical;
                $parent_gear_thickness = thickness;
                union() children();
            }
        }
    }
}


// Function&Module: spur_gear2d()
// Synopsis: Creates a 2D spur gear or internal ring gear.
// SynTags: Geom, Region
// Topics: Gears, Parts
// See Also: rack(), spur_gear(), spur_gear2d(), bevel_gear()
// Usage: As Module
//   spur_gear2d(circ_pitch, teeth, [hide=], [pressure_angle=], [clearance=], [backlash=], [internal=]) [ATTACHMENTS];
//   spur_gear2d(mod=, teeth=, [hide=], [pressure_angle=], [clearance=], [backlash=], [internal=]) [ATTACHMENTS];
// Usage: As Function
//   rgn = spur_gear2d(circ_pitch, teeth, [hide=], [pressure_angle=], [clearance=], [backlash=], [internal=]);
//   rgn = spur_gear2d(mod=, teeth=, [hide=], [pressure_angle=], [clearance=], [backlash=], [internal=]);
// Description:
//   When called as a module, creates a 2D involute spur gear.  When called as a function,
//   returns a 2D region for the 2D involute spur gear.  Normally, you should just specify the
//   first 2 parameters `circ_pitch` and `teeth`, and let the rest be default values.
//   Meshing gears must match in `circ_pitch`, `pressure_angle`, and `helical`, and be separated by
//   the sum of their meshing radii, which can be found with `mesh_radius()`.
// Arguments:
//   circ_pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.
//   teeth = Total number of teeth around the spur gear.
//   hide = Number of teeth to delete to make this only a fraction of a circle
//   pressure_angle = Controls how straight or bulged the tooth sides are. In degrees.
//   ---
//   hide = Number of teeth to delete to make this only a fraction of a circle
//   clearance = Gap between top of a tooth on one gear and bottom of valley on a meshing gear (in millimeters)
//   backlash = Gap between two meshing teeth, in the direction along the circumference of the pitch circle
//   helical = The angle of the rack teeth away from perpendicular to the gear axis of rotation.  Stretches out the tooth shapes.  Used to match helical spur gear pinions.  Default: 0
//   internal = If true, create a mask for difference()ing from something else.
//   profile_shift = Profile shift factor x.
//   shaft_diam = If given, the diameter of the central shaft hole.
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  Note that the diametral pitch is a completely different thing than the pitch diameter.
//   mod = The metric module/modulus of the gear, or mm of pitch diameter per tooth.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
// Example(2D): Typical Gear Shape
//   spur_gear2d(circ_pitch=5, teeth=20, shaft_diam=5);
// Example(2D): By Metric Module
//   spur_gear2d(mod=2, teeth=20, shaft_diam=5);
// Example(2D): By Imperial Gear Pitch
//   spur_gear2d(diam_pitch=10, teeth=20, shaft_diam=5);
// Example(2D): Lower Pressure Angle
//   spur_gear2d(circ_pitch=5, teeth=20, pressure_angle=14);
// Example(2D): Partial Gear
//   spur_gear2d(circ_pitch=5, teeth=20, hide=15, pressure_angle=20);
// Example(2D): Effects of Profile Shifting.
//   circ_pitch=5; teeth=7; shaft=5; strokewidth=0.2;
//   module the_gear(profile_shift=0) {
//       $fn=72;
//       pr = pitch_radius(circ_pitch,teeth);
//       mr = mesh_radius(circ_pitch,teeth,profile_shift=profile_shift);
//       back(mr) {
//           spur_gear2d(circ_pitch, teeth, shaft_diam=shaft, profile_shift=profile_shift);
//           up(0.1) color("black")
//               dashed_stroke(circle(r=pr), width=strokewidth, closed=true);
//       }
//   }
//   module the_rack() {
//       $fn=72;
//       rack2d(circ_pitch, teeth=3, height=5);
//       up(0.1) color("black")
//           dashed_stroke([[-7.5,0],[7.5,0]], width=strokewidth);
//   }
//   left(10) { the_gear(0); the_rack(); }
//   right(10) { the_gear(0.59); the_rack(); }
// Example(2D): Planetary Gear Assembly
//   rteeth=56; pteeth=16; cteeth=24;
//   circ_pitch=5; pa=20;
//   cr = mesh_radius(circ_pitch, cteeth);
//   pr = mesh_radius(circ_pitch, pteeth);
//   ring_gear2d(
//       circ_pitch=circ_pitch,
//       teeth=rteeth,
//       pressure_angle=pa);
//   for (a=[0:3]) {
//       zrot(a*90) back(cr+pr) {
//           color("green")
//           spur_gear2d(
//               circ_pitch=circ_pitch,
//               teeth=pteeth,
//               pressure_angle=pa);
//       }
//   }
//   color("orange")
//     zrot(180/cteeth)
//       spur_gear2d(
//           circ_pitch=circ_pitch,
//           teeth=cteeth,
//           pressure_angle=pa);
// Example(2D): Called as a Function
//   rgn = spur_gear2d(circ_pitch=8, teeth=16, shaft_diam=5);
//   region(rgn);

function spur_gear2d(
    circ_pitch,
    teeth,
    hide = 0,
    pressure_angle,
    clearance,
    backlash = 0.0,
    internal,
    interior,
    profile_shift,
    helical,
    shaft_diam = 0,
    pitch,
    diam_pitch,
    mod,
    gear_spin = 0,
    anchor = CENTER,
    spin = 0
) = let(
        dummy = !is_undef(interior) ? echo("In spur_gear2d(), the argument 'interior=' has been deprecated, and may be removed in the future.  Please use 'internal=' instead."):0,
        internal = first_defined([internal,interior,false]),
        circ_pitch = _inherit_gear_pitch("spur_gear2d()", pitch, circ_pitch, diam_pitch, mod),
        PA = _inherit_gear_pa(pressure_angle),
        helical = _inherit_gear_helical(helical, invert=!internal),
        profile_shift = default(profile_shift, auto_profile_shift(teeth,PA))
    )
    assert(is_integer(teeth) && teeth>3)
    assert(is_finite(shaft_diam) && shaft_diam>=0)
    assert(is_integer(hide) && hide>=0 && hide<teeth)
    assert(is_finite(PA) && PA>=0 && PA<90, "Bad pressure_angle value.")
    assert(clearance==undef || (is_finite(clearance) && clearance>=0))
    assert(is_finite(backlash) && backlash>=0)
    assert(is_finite(profile_shift) && abs(profile_shift)<1)
    assert(is_finite(helical) && abs(helical)<90)
    assert(is_finite(gear_spin))
    let(
        pr = pitch_radius(circ_pitch, teeth, helical=helical),
        tooth = _gear_tooth_profile(
                circ_pitch=circ_pitch,
                teeth=teeth,
                pressure_angle=PA,
                clearance=clearance,
                backlash=backlash,
                profile_shift=profile_shift,
                helical=helical,
                internal=internal
            ),
        perim = [
            for (i = [0:1:teeth-1-hide])
                each zrot(-i*360/teeth+gear_spin, p=tooth),
            if (hide>0) [0,0],
        ],
        rgn = [
            list_unwrap(deduplicate(perim)),
            if (shaft_diam>0 && !hide)
                reverse(circle(d=shaft_diam)),
        ]
    ) reorient(anchor,spin, two_d=true, r=pr, p=rgn);


module spur_gear2d(
    circ_pitch,
    teeth,
    hide = 0,
    pressure_angle,
    clearance,
    backlash = 0.0,
    internal,
    interior,
    profile_shift,
    helical,
    shaft_diam = 0,
    pitch,
    diam_pitch,
    mod,
    gear_spin = 0,
    anchor = CENTER,
    spin = 0
) {
    dummy = !is_undef(interior) ? echo("In spur_gear2d(), the argument 'interior=' has been deprecated, and may be removed in the future.  Please use 'internal=' instead."):0;
    internal = first_defined([internal,interior,false]);
    circ_pitch = _inherit_gear_pitch("spur_gear2d()", pitch, circ_pitch, diam_pitch, mod);
    PA = _inherit_gear_pa(pressure_angle);
    helical = _inherit_gear_helical(helical, invert=!internal);
    profile_shift = default(profile_shift, auto_profile_shift(teeth,PA));
    checks =
        assert(is_integer(teeth) && teeth>3)
        assert(is_finite(shaft_diam) && shaft_diam>=0)
        assert(is_integer(hide) && hide>=0 && hide<teeth)
        assert(is_finite(PA) && PA>=0 && PA<90, "Bad pressure_angle value.")
        assert(clearance==undef || (is_finite(clearance) && clearance>=0))
        assert(is_finite(backlash) && backlash>=0)
        assert(is_finite(profile_shift) && abs(profile_shift)<1)
        assert(is_finite(helical) && abs(helical)<90)
        assert(is_finite(gear_spin));
    rgn = spur_gear2d(
        circ_pitch = circ_pitch,
        teeth = teeth,
        hide = hide,
        pressure_angle = PA,
        clearance = clearance,
        helical = helical,
        backlash = backlash,
        profile_shift = profile_shift,
        internal = internal,
        shaft_diam = shaft_diam
    );
    pr = pitch_radius(circ_pitch, teeth, helical=helical);
    attachable(anchor,spin, two_d=true, r=pr) {
        zrot(gear_spin) region(rgn);
        union() {
            $parent_gear_type = "spur2D";
            $parent_gear_pitch = circ_pitch;
            $parent_gear_teeth = teeth;
            $parent_gear_pa = PA;
            $parent_gear_helical = helical;
            $parent_gear_thickness = 0;
            union() children();
        }
    }
}


// Module: ring_gear()
// Synopsis: Creates a 3D ring gear.
// SynTags: Geom
// Topics: Gears, Parts
// See Also: rack(), ring_gear2d(), spur_gear(), spur_gear2d(), bevel_gear()
// Usage:
//   ring_gear(circ_pitch, teeth, thickness, [backing], [pressure_angle=], [helical=], [herringbone=], [profile_shift=], [clearance=], [backlash=]) [ATTACHMENTS];
//   ring_gear(mod=, teeth=, thickness=, backing=, [pressure_angle=], [helical=], [herringbone=], [profile_shift=], [clearance=], [backlash=]) [ATTACHMENTS];
//   ring_gear(diam_pitch=, teeth=, thickness=, backing=, [pressure_angle=], [helical=], [herringbone=], [profile_shift=], [clearance=], [backlash=]) [ATTACHMENTS];
// Description:
//   Creates a 3D involute ring gear.  Normally, you should just specify the
//   first 3 parameters `circ_pitch`, `teeth`, and `thickness`, and let the rest be default values.
//   Meshing gears must match in `circ_pitch`, `pressure_angle`, and `helical`, and be separated by
//   the sum of their profile shifts and pitch radii, which can be found with `mesh_radius()`.
// Arguments:
//   circ_pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.
//   teeth = Total number of teeth around the spur gear.
//   thickness = Thickness of ring gear in mm
//   backing = The width of the ring gear backing, in mm.
//   pressure_angle = Controls how straight or bulged the tooth sides are. In degrees.
//   ---
//   helical = The angle of the rack teeth away from perpendicular to the gear axis of rotation.  Stretches out the tooth shapes.  Used to match helical spur gear pinions.  Default: 0
//   herringbone = If true, and helical is set, creates a herringbone gear.
//   profile_shift = Profile shift factor x for tooth profile.
//   clearance = Gap between top of a tooth on one gear and bottom of valley on a meshing gear (in millimeters)
//   backlash = Gap between two meshing teeth, in the direction along the circumference of the pitch circle
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  Note that the diametral pitch is a completely different thing than the pitch diameter.
//   mod = The metric module/modulus of the gear, or mm of pitch diameter per tooth.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Example:
//   ring_gear(circ_pitch=5, teeth=48, thickness=10);
// Example: Adjusting Backing
//   ring_gear(circ_pitch=5, teeth=48, thickness=10, backing=30);
// Example(Med): Adjusting Pressure Angle
//   ring_gear(circ_pitch=5, teeth=48, thickness=10, pressure_angle=28);
// Example(Med): Tooth Profile Shifting
//   ring_gear(circ_pitch=5, teeth=48, thickness=10, profile_shift=0.5);
// Example(Med): Helical Ring Gear
//   ring_gear(circ_pitch=5, teeth=48, thickness=10, helical=30);
// Example(Med): Herringbone Ring Gear
//   ring_gear(circ_pitch=5, teeth=48, thickness=10, helical=30, herringbone=true);

module ring_gear(
    circ_pitch,
    teeth,
    thickness = 10,
    backing = 10,
    pressure_angle,
    helical,
    herringbone = false,
    profile_shift,
    clearance,
    backlash = 0.0,
    pitch,
    diam_pitch,
    mod,
    slices,
    gear_spin = 0,
    anchor = CENTER,
    spin = 0,
    orient = UP
) {
    circ_pitch = _inherit_gear_pitch("ring_gear()",pitch, circ_pitch, diam_pitch, mod);
    PA = _inherit_gear_pa(pressure_angle);
    helical = _inherit_gear_helical(helical);
    thickness = _inherit_gear_thickness(thickness);
    profile_shift = default(profile_shift, auto_profile_shift(teeth,PA));
    checks =
        assert(is_integer(teeth) && teeth>3)
        assert(is_finite(thickness) && thickness>0)
        assert(is_finite(backing) && backing>0)
        assert(is_finite(PA) && PA>=0 && PA<90, "Bad pressure_angle value.")
        assert(is_finite(helical) && abs(helical)<90)
        assert(is_bool(herringbone))
        assert(clearance==undef || (is_finite(clearance) && clearance>=0))
        assert(is_finite(backlash) && backlash>=0)
        assert(is_finite(profile_shift) && abs(profile_shift)<1)
        assert(slices==undef || (is_integer(slices) && slices>0))
        assert(is_finite(gear_spin));
    pr = pitch_radius(circ_pitch, teeth, helical=helical);
    ar = outer_radius(circ_pitch, teeth, helical=helical, profile_shift=profile_shift, internal=true);
    circum = 2 * PI * pr;
    twist = 360*thickness*tan(helical)/circum;
    slices = default(slices, ceil(twist/360*segs(pr)+1));
    attachable(anchor,spin,orient, h=thickness, r=pr) {
        zrot(gear_spin)
        if (herringbone) {
            zflip_copy() down(0.01)
            linear_extrude(height=thickness/2, center=false, twist=twist/2, slices=ceil(slices/2), convexity=teeth/4) {
                difference() {
                    circle(r=ar+backing);
                    spur_gear2d(
                        circ_pitch = circ_pitch,
                        teeth = teeth,
                        pressure_angle = PA,
                        helical = helical,
                        clearance = clearance,
                        backlash = backlash,
                        profile_shift = profile_shift,
                        internal = true
                    );
                }
            }
        } else {
            zrot(twist/2)
            linear_extrude(height=thickness,center=true, twist=twist, convexity=teeth/4) {
                difference() {
                    circle(r=ar+backing);
                    spur_gear2d(
                        circ_pitch = circ_pitch,
                        teeth = teeth,
                        pressure_angle = PA,
                        helical = helical,
                        clearance = clearance,
                        backlash = backlash,
                        profile_shift = profile_shift,
                        internal = true
                    );
                }
            }
        }
        children();
    }
}


// Module: ring_gear2d()
// Synopsis: Creates a 2D ring gear.
// SynTags: Geom
// Topics: Gears, Parts
// See Also: rack(), spur_gear(), spur_gear2d(), bevel_gear()
// Usage:
//   ring_gear2d(circ_pitch, teeth, [backing], [pressure_angle=], [helical=], [profile_shift=], [clearance=], [backlash=]) [ATTACHMENTS];
//   ring_gear2d(mod=, teeth=, [backing=], [pressure_angle=], [helical=], [profile_shift=], [clearance=], [backlash=]) [ATTACHMENTS];
//   ring_gear2d(diam_pitch=, teeth=, [backing=], [pressure_angle=], [helical=], [profile_shift=], [clearance=], [backlash=]) [ATTACHMENTS];
// Description:
//   Creates a 2D involute ring gear.  Normally, you should just specify the
//   first 2 parameters `circ_pitch` and `teeth`, and let the rest be default values.
//   Meshing gears must match in `circ_pitch`, `pressure_angle`, and `helical`, and be separated by
//   the sum of their profile shifts and pitch radii, which can be found with `mesh_radius()`.
// Arguments:
//   circ_pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.
//   teeth = Total number of teeth around the spur gear.
//   backing = The width of the ring gear backing, in mm.
//   pressure_angle = Controls how straight or bulged the tooth sides are. In degrees.
//   ---
//   helical = The angle of the rack teeth away from perpendicular to the gear axis of rotation.  Stretches out the tooth shapes.  Used to match helical spur gear pinions.  Default: 0
//   profile_shift = Profile shift factor x for tooth profile.
//   clearance = Gap between top of a tooth on one gear and bottom of valley on a meshing gear (in millimeters)
//   backlash = Gap between two meshing teeth, in the direction along the circumference of the pitch circle
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  Note that the diametral pitch is a completely different thing than the pitch diameter.
//   mod = The metric module/modulus of the gear, or mm of pitch diameter per tooth.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
// Example(2D;Big):
//   circ_pitch=5; teeth1=50; teeth2=16;
//   pr1 = pitch_radius(circ_pitch, teeth1);
//   pr2 = pitch_radius(circ_pitch, teeth2);
//   ring_gear2d(circ_pitch=circ_pitch, teeth=teeth1);
//   back(pr1-pr2) spur_gear2d(circ_pitch=circ_pitch, teeth=teeth2);
module ring_gear2d(
    circ_pitch,
    teeth,
    backing = 10,
    pressure_angle,
    helical,
    profile_shift,
    clearance,
    backlash = 0.0,
    pitch,
    diam_pitch,
    mod,
    gear_spin = 0,
    anchor = CENTER,
    spin = 0
) {
    circ_pitch = _inherit_gear_pitch("ring_gear2d()",pitch, circ_pitch, diam_pitch, mod);
    PA = _inherit_gear_pa(pressure_angle);
    helical = _inherit_gear_helical(helical);
    profile_shift = default(profile_shift, auto_profile_shift(teeth,PA));
    checks =
        assert(is_integer(teeth) && teeth>3)
        assert(is_finite(backing) && backing>0)
        assert(is_finite(PA) && PA>=0 && PA<90, "Bad pressure_angle value.")
        assert(is_finite(helical) && abs(helical)<90)
        assert(clearance==undef || (is_finite(clearance) && clearance>=0))
        assert(is_finite(backlash) && backlash>=0)
        assert(is_finite(profile_shift) && abs(profile_shift)<1)
        assert(is_finite(gear_spin));
    pr = pitch_radius(circ_pitch, teeth, helical=helical);
    ar = outer_radius(circ_pitch, teeth, helical=helical, profile_shift=profile_shift, internal=true);
    attachable(anchor,spin, two_d=true, r=pr) {
        zrot(gear_spin)
        difference() {
            circle(r=ar+backing);
            spur_gear2d(
                circ_pitch = circ_pitch,
                teeth = teeth,
                pressure_angle = PA,
                helical = helical,
                clearance = clearance,
                backlash = backlash,
                profile_shift = profile_shift,
                internal = true
            );
        }
        children();
    }
}


// Function&Module: rack()
// Synopsis: Creates a straight or helical gear rack.
// SynTags: Geom, VNF
// Topics: Gears, Parts
// See Also: rack2d(), spur_gear(), spur_gear2d(), bevel_gear()
// Usage: As a Module
//   rack(pitch, teeth, thickness, height, [pressure_angle=], [backlash=], [clearance=], [helical=]) [ATTACHMENTS];
//   rack(mod=, teeth=, thickness=, height=, [pressure_angle=], [backlash]=, [clearance=], [helical=]) [ATTACHMENTS];
// Usage: As a Function
//   vnf = rack(pitch, teeth, thickness, height, [pressure_angle=], [backlash=], [clearance=], [helical=]);
//   vnf = rack(mod=, teeth=, thickness=, height=, [pressure_angle=], [backlash=], [clearance=], [helical=]);
// Description:
//   This is used to create a 3D rack, which is a linear bar with teeth that a gear can roll along.
//   A rack can mesh with any gear that has the same `pitch` and `pressure_angle`.
//   When called as a function, returns a 3D [VNF](vnf.scad) for the rack.
//   When called as a module, creates a 3D rack shape.
// Arguments:
//   pitch = The pitch, or distance in mm between teeth along the rack. Matches up with circular pitch on a spur gear.  Default: 5
//   teeth = Total number of teeth along the rack.  Default: 20
//   thickness = Thickness of rack in mm (affects each tooth).  Default: 5
//   height = Height of rack in mm, from tooth top to back of rack.  Default: 10
//   ---
//   pressure_angle = Controls how straight or bulged the tooth sides are. In degrees.  Default: 20
//   backlash = Gap between two meshing teeth, in the direction along the circumference of the pitch circle.  Default: 0
//   clearance = Clearance gap at the bottom of the inter-tooth valleys.
//   helical = The angle of the rack teeth away from perpendicular to the rack length.  Used to match helical spur gear pinions.  Default: 0
//   profile_shift = Profile shift factor x.
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  Note that the diametral pitch is a completely different thing than the pitch diameter.
//   mod = The metric module/modulus of the gear, or mm of pitch diameter per tooth.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
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
//   pr = pitch_radius(pitch, teeth2, helical=helical);
//   right(pr*2*PI/teeth2*$t)
//       rack(pitch, teeth1, thickness=thick, height=5, helical=helical);
//   up(pr)
//       spur_gear(
//           pitch, teeth2,
//           thickness=thick,
//           helical=helical,
//           shaft_diam=5,
//           orient=BACK,
//           gear_spin=180-$t*360/teeth2);

module rack(
    pitch,
    teeth,
    thickness,
    height = 10,
    pressure_angle,
    backlash = 0.0,
    clearance,
    helical,
    profile_shift = 0,
    gear_travel=0,
    circ_pitch,
    diam_pitch,
    mod,
    anchor = CENTER,
    spin = 0,
    orient = UP
) {
    pitch = _inherit_gear_pitch("rack()",pitch, circ_pitch, diam_pitch, mod, warn=false);
    PA = _inherit_gear_pa(pressure_angle);
    helical = _inherit_gear_helical(helical);
    thickness = _inherit_gear_thickness(thickness);
    checks=
        assert(is_integer(teeth) && teeth>0)
        assert(is_finite(thickness) && thickness>0)
        assert(is_finite(height) && height>0)
        assert(is_finite(PA) && PA>=0 && PA<90, "Bad pressure_angle value.")
        assert(clearance==undef || (is_finite(clearance) && clearance>=0))
        assert(is_finite(backlash) && backlash>=0)
        assert(is_finite(helical) && abs(helical)<90)
        //assert(is_bool(herringbone))
        assert(is_finite(profile_shift) && abs(profile_shift)<1)
        assert(is_finite(gear_travel));
    trans_pitch = pitch / cos(helical);
    a = _adendum(pitch, profile_shift);
    d = _dedendum(pitch, clearance, profile_shift);
    l = teeth * trans_pitch;
    anchors = [
        named_anchor("adendum",         [0,0,a],             BACK),
        named_anchor("adendum-left",    [-l/2,0,a],          LEFT),
        named_anchor("adendum-right",   [ l/2,0,a],          RIGHT),
        named_anchor("adendum-front",   [0,-thickness/2,a],  DOWN),
        named_anchor("adendum-back",    [0, thickness/2,a],  UP),
        named_anchor("dedendum",        [0,0,-d],            BACK),
        named_anchor("dedendum-left",   [-l/2,0,-d],         LEFT),
        named_anchor("dedendum-right",  [ l/2,0,-d],         RIGHT),
        named_anchor("dedendum-front",  [0,-thickness/2,-d], DOWN),
        named_anchor("dedendum-back",   [0, thickness/2,-d], UP),
    ];
    size = [l, thickness, 2*height];
    attachable(anchor,spin,orient, size=size, anchors=anchors) {
        right(gear_travel)
        skew(sxy=tan(helical)) xrot(90) {
            linear_extrude(height=thickness, center=true, convexity=teeth*2) {
                rack2d(
                    pitch = pitch,
                    teeth = teeth,
                    height = height,
                    pressure_angle = PA,
                    backlash = backlash,
                    clearance = clearance,
                    helical = helical,
                    profile_shift = profile_shift
                );
            }
        }
        children();
    }
}


function rack(
    pitch,
    teeth,
    thickness,
    height = 10,
    pressure_angle,
    backlash = 0.0,
    clearance,
    helical,
    profile_shift = 0,
    circ_pitch,
    diam_pitch,
    mod,
    gear_travel=0,
    anchor = CENTER,
    spin = 0,
    orient = UP
) =
    let(
        pitch = _inherit_gear_pitch("rack()",pitch, circ_pitch, diam_pitch, mod, warn=false),
        PA = _inherit_gear_pa(pressure_angle),
        helical = _inherit_gear_helical(helical),
        thickness = _inherit_gear_thickness(thickness)
    )
    assert(is_integer(teeth) && teeth>0)
    assert(is_finite(thickness) && thickness>0)
    assert(is_finite(height) && height>0)
    assert(is_finite(PA) && PA>=0 && PA<90, "Bad pressure_angle value.")
    assert(clearance==undef || (is_finite(clearance) && clearance>=0))
    assert(is_finite(backlash) && backlash>=0)
    assert(is_finite(helical) && abs(helical)<90)
    //assert(is_bool(herringbone))
    assert(is_finite(profile_shift) && abs(profile_shift)<1)
    assert(is_finite(gear_travel))
    let(
        trans_pitch = pitch / cos(helical),
        a = _adendum(pitch, profile_shift),
        d = _dedendum(pitch, clearance, profile_shift),
        l = teeth * trans_pitch,
        path = rack2d(
            pitch = pitch,
            teeth = teeth,
            height = height,
            pressure_angle = PA,
            backlash = backlash,
            clearance = clearance,
            helical = helical,
            profile_shift = profile_shift
        ),
        vnf = linear_sweep(path, height=thickness, anchor="origin", orient=FWD),
        m = product([
            right(gear_travel),
            if (helical) skew(sxy=tan(helical)),
        ]),
        out = apply(m, vnf),
        size = [l, thickness, 2*height],
        anchors = [
            named_anchor("adendum",         [0,0,a],             BACK),
            named_anchor("adendum-left",    [-l/2,0,a],          LEFT),
            named_anchor("adendum-right",   [ l/2,0,a],          RIGHT),
            named_anchor("adendum-front",   [0,-thickness/2,a],  DOWN),
            named_anchor("adendum-back",    [0, thickness/2,a],  UP),
            named_anchor("dedendum",        [0,0,-d],            BACK),
            named_anchor("dedendum-left",   [-l/2,0,-d],         LEFT),
            named_anchor("dedendum-right",  [ l/2,0,-d],         RIGHT),
            named_anchor("dedendum-front",  [0,-thickness/2,-d], DOWN),
            named_anchor("dedendum-back",   [0, thickness/2,-d], UP),
        ]
    ) reorient(anchor,spin,orient, size=size, anchors=anchors, p=out);




// Function&Module: rack2d()
// Synopsis: Creates a 2D gear rack.
// SynTags: Geom, Path
// Topics: Gears, Parts
// See Also: rack(), spur_gear(), spur_gear2d(), bevel_gear()
// Usage: As a Module
//   rack2d(pitch, teeth, height, [pressure_angle=], [backlash=], [clearance=]) [ATTACHMENTS];
//   rack2d(mod=, teeth=, height=, [pressure_angle=], [backlash=], [clearance=]) [ATTACHMENTS];
// Usage: As a Function
//   path = rack2d(pitch, teeth, height, [pressure_angle=], [backlash=], [clearance=]);
//   path = rack2d(mod=, teeth=, height=, [pressure_angle=], [backlash=], [clearance=]);
// Description:
//   This is used to create a 2D rack, which is a linear bar with teeth that a gear can roll along.
//   A rack can mesh with any gear that has the same `pitch` and `pressure_angle`.
//   When called as a function, returns a 2D path for the outline of the rack.
//   When called as a module, creates a 2D rack shape.
// Arguments:
//   pitch = The pitch, or distance in mm between teeth along the rack. Matches up with circular pitch on a spur gear.  Default: 5
//   teeth = Total number of teeth along the rack
//   height = Height of rack in mm, from pitch line to back of rack.
//   ---
//   pressure_angle = Controls how straight or bulged the tooth sides are. In degrees.
//   backlash = Gap between two meshing teeth, in the direction along the circumference of the pitch circle
//   clearance = Clearance gap at the bottom of the inter-tooth valleys.
//   helical = The angle of the rack teeth away from perpendicular to the rack length.  Stretches out the tooth shapes.  Used to match helical spur gear pinions.  Default: 0
//   profile_shift = Profile shift factor x for tooth shape.
//   gear_travel = The distance the rack should be moved by linearly.  Default: 0
//   rounding = If true, rack tips and valleys are slightly rounded.  Default: true
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  Note that the diametral pitch is a completely different thing than the pitch diameter.
//   mod = The metric module/modulus of the gear, or mm of pitch diameter per tooth.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
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
//   path = rack2d(pitch=8, teeth=8, height=10, pressure_angle=20);
//   polygon(path);

function rack2d(
    pitch,
    teeth,
    height = 10,
    pressure_angle,
    backlash = 0,
    clearance,
    helical,
    profile_shift = 0,
    circ_pitch,
    diam_pitch,
    mod,
    gear_travel = 0,
    rounding = true,
    anchor = CENTER,
    spin = 0
) = let(
        pitch = _inherit_gear_pitch("rack2d()",pitch, circ_pitch, diam_pitch, mod, warn=false),
        PA = _inherit_gear_pa(pressure_angle),
        helical = _inherit_gear_helical(helical)
    )
    assert(is_integer(teeth) && teeth>0)
    assert(is_finite(height) && height>0)
    assert(is_finite(PA) && PA>=0 && PA<90, "Bad pressure_angle value.")
    assert(clearance==undef || (is_finite(clearance) && clearance>=0))
    assert(is_finite(backlash) && backlash>=0)
    assert(is_finite(helical) && abs(helical)<90)
    assert(is_finite(profile_shift) && abs(profile_shift)<1)
    assert(is_finite(gear_travel))
    let(
        adendum = _adendum(pitch, profile_shift),
        dedendum = _dedendum(pitch, clearance, profile_shift)
    )
    assert(dedendum < height, "height= is not large enough.")
    let(
        trans_pitch = pitch / cos(helical),
        trans_pa = atan(tan(PA)/cos(helical)),
        tthick = trans_pitch/PI * (PI/2 + 2*profile_shift * tan(PA)) - backlash,
        l = teeth * trans_pitch,
        ax = ang_adj_to_opp(trans_pa, adendum),
        dx = ang_adj_to_opp(trans_pa, dedendum),
        clear = dedendum - adendum,
        poff = tthick/2 - backlash,
        tooth = [
            [-trans_pitch/2, -dedendum],
            if (rounding) each arc(n=4, r=clear, corner=[
                [-trans_pitch/2, -dedendum],
                [-poff-dx, -dedendum],
                [-poff+ax, +adendum],
            ]) else [-poff-dx, -dedendum],
            if (rounding) each arc(n=4, r=trans_pitch/16, corner=[
                [-poff-dx, -dedendum],
                [-poff+ax, +adendum],
                [+poff-ax, +adendum],
            ]) else [-poff+ax, +adendum],
            if (rounding) each arc(n=4, r=trans_pitch/16, corner=[
                [-poff+ax, +adendum],
                [+poff-ax, +adendum],
                [+poff+dx, -dedendum],
            ]) else [+poff-ax, +adendum],
            if (rounding) each arc(n=4, r=clear, corner=[
                [+poff-ax, +adendum],
                [+poff+dx, -dedendum],
                [+trans_pitch/2, -dedendum],
            ]) else [+poff+dx, -dedendum],
            [+trans_pitch/2, -dedendum],
        ],
        path2 = [
            for(m = xcopies(trans_pitch,n=teeth))
                each apply(m,tooth)
        ],
        path = right(gear_travel, p=[
            [path2[0].x, -height],
            each path2,
            [last(path2).x, -height],
        ]),
        size=[l,2*height],
        anchors = [
            named_anchor("adendum",         [   0, adendum,0],  BACK),
            named_anchor("adendum-left",    [-l/2, adendum,0],  LEFT),
            named_anchor("adendum-right",   [ l/2, adendum,0],  RIGHT),
            named_anchor("dedendum",        [   0,-dedendum,0],  BACK),
            named_anchor("dedendum-left",   [-l/2,-dedendum,0],  LEFT),
            named_anchor("dedendum-right",  [ l/2,-dedendum,0],  RIGHT),
        ]
    ) reorient(anchor,spin, two_d=true, size=size, anchors=anchors, p=path);



module rack2d(
    pitch,
    teeth,
    height = 10,
    pressure_angle,
    backlash = 0.0,
    clearance,
    helical,
    profile_shift = 0,
    gear_travel = 0,
    circ_pitch,
    diam_pitch,
    mod,
    anchor = CENTER,
    spin = 0
) {
    pitch = _inherit_gear_pitch("rack2d()",pitch, circ_pitch, diam_pitch, mod, warn=false);
    PA = _inherit_gear_pa(pressure_angle);
    helical = _inherit_gear_helical(helical);
    checks =
        assert(is_integer(teeth) && teeth>0)
        assert(is_finite(height) && height>0)
        assert(is_finite(PA) && PA>=0 && PA<90, "Bad pressure_angle value.")
        assert(clearance==undef || (is_finite(clearance) && clearance>=0))
        assert(is_finite(backlash) && backlash>=0)
        assert(is_finite(helical) && abs(helical)<90)
        assert(is_finite(profile_shift) && abs(profile_shift)<1)
        assert(is_finite(gear_travel));
    trans_pitch = pitch / cos(helical);
    a = _adendum(pitch, profile_shift);
    d = _dedendum(pitch, clearance, profile_shift);
    l = teeth * trans_pitch;
    path = rack2d(
        pitch = pitch,
        teeth = teeth,
        height = height,
        pressure_angle = PA,
        backlash = backlash,
        clearance = clearance,
        helical = helical,
        profile_shift= profile_shift
    );
    size = [l, 2*height];
    anchors = [
        named_anchor("adendum",         [   0, a,0],  BACK),
        named_anchor("adendum-left",    [-l/2, a,0],  LEFT),
        named_anchor("adendum-right",   [ l/2, a,0],  RIGHT),
        named_anchor("dedendum",        [   0,-d,0],  BACK),
        named_anchor("dedendum-left",   [-l/2,-d,0],  LEFT),
        named_anchor("dedendum-right",  [ l/2,-d,0],  RIGHT),
    ];
    attachable(anchor,spin, two_d=true, size=size, anchors=anchors) {
        right(gear_travel) polygon(path);
        children();
    }
}




// Function&Module: bevel_gear()
// Synopsis: Creates a straight or spiral bevel gear.
// SynTags: Geom, VNF
// Topics: Gears, Parts
// See Also: rack(), rack2d(), spur_gear(), spur_gear2d(), bevel_pitch_angle(), bevel_gear()
// Usage: As a Module
//   bevel_gear(circ_pitch, teeth, face_width, [pitch_angle=]|[mate_teeth=], [shaft_diam=], [hide=], [pressure_angle=], [clearance=], [backlash=], [cutter_radius=], [spiral_angle=], [left_handed=], [slices=], [internal=]);
//   bevel_gear(mod=, teeth=, face_width=, [pitch_angle=]|[mate_teeth=], [shaft_diam=], [hide=], [pressure_angle=], [clearance=], [backlash=], [cutter_radius=], [spiral_angle=], [left_handed=], [slices=], [internal=]);
// Usage: As a Function
//   vnf = bevel_gear(circ_pitch, teeth, face_width, [pitch_angle=]|[mate_teeth=], [hide=], [pressure_angle=], [clearance=], [backlash=], [cutter_radius=], [spiral_angle=], [left_handed=], [slices=], [internal=]);
//   vnf = bevel_gear(mod=, teeth=, face_width=, [pitch_angle=]|[mate_teeth=], [hide=], [pressure_angle=], [clearance=], [backlash=], [cutter_radius=], [spiral_angle=], [left_handed=], [slices=], [internal=]);
// Description:
//   Creates a (potentially spiral) bevel gear.  The module `bevel_gear()` gives a bevel gear, with
//   reasonable defaults for all the parameters.  Normally, you should just choose the first 4
//   parameters, and let the rest be default values.  In straight bevel gear sets, when each tooth
//   engages it inpacts the corresponding tooth.  The abrupt tooth engagement causes impact stress
//   which makes them more prone to breakage.  Spiral bevel gears have teeth formed along spirals so
//   they engage more gradually, resulting in a less abrupt transfer of force, so they are quieter
//   in operation and less likely to break.
//   .
//   The module `bevel_gear()` gives a gear in the XY plane, centered on the origin, with one tooth
//   centered on the positive Y axis.  The various functions below it take the same parameters, and
//   return various measurements for the gear.  The most important function is `mesh_radius()`, which tells
//   how far apart to space gears that are meshing, and `outer_radius()`, which gives the size of the
//   region filled by the gear.  A gear has a "pitch circle", which is an invisible circle that cuts
//   through the middle of each tooth (though not the exact center). In order for two gears to mesh,
//   their pitch circles should just touch, if no profile shifting is done).  So the distance between
//   their centers should be `mesh_radius()` for one, plus `mesh_radius()` for the other, which gives
//   the radii of their pitch circles and profile shifts.  In order for two gears to mesh, they must
//   have the same `circ_pitch` and `pressure_angle` parameters.  `circ_pitch` gives the number of millimeters
//   of arc around the pitch circle covered by one tooth and one space between teeth.  The `pressure_angle`
//   controls how flat or bulged the sides of the teeth are.  Common values include 14.5 degrees and 20
//   degrees, and occasionally 25.  The default here is 20 degrees.  Larger numbers bulge out more,
//   giving stronger teeth.  The ratio of `teeth` for two meshing gears gives how many times one will make a full
//   revolution when the the other makes one full revolution.  If the two numbers are coprime (i.e.
//   are not both divisible by the same number greater than 1), then every tooth on one gear will meet
//   every tooth on the other, for more even wear.  So coprime numbers of teeth are good.
// Arguments:
//   circ_pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.  Default: 5
//   teeth = Total number of teeth around the entire perimeter.  Default: 20
//   face_width = Width of the toothed surface in mm, from inside to outside.  Default: 10
//   ---
//   pitch_angle = Angle of beveled gear face.  Default: 45
//   mate_teeth = The number of teeth in the gear that this gear will mate with.  Overrides `pitch_angle` if given.
//   shaft_diam = Diameter of the hole in the center, in mm.  Module use only.  Default: 0 (no shaft hole)
//   hide = Number of teeth to delete to make this only a fraction of a circle.  Default: 0
//   pressure_angle = Controls how straight or bulged the tooth sides are. In degrees. Default: 20
//   clearance = Clearance gap at the bottom of the inter-tooth valleys.
//   backlash = Gap between two meshing teeth, in the direction along the circumference of the pitch circle.  Default: 0
//   cutter_radius = Radius of spiral arc for teeth.  If 0, then gear will not be spiral.  Default: 0
//   spiral_angle = The base angle for spiral teeth.  Default: 0
//   left_handed = If true, the gear returned will have a left-handed spiral.  Default: false
//   slices = Number of vertical layers to divide gear into.  Useful for refining gears with `spiral`.  Default: 1
//   internal = If true, create a mask for difference()ing from something else.
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  Note that the diametral pitch is a completely different thing than the pitch diameter.
//   mod = The metric module/modulus of the gear, or mm of pitch diameter per tooth.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Extra Anchors:
//   "apex" = At the pitch cone apex for the bevel gear.
//   "pitchbase" = At the natural height of the pitch radius of the beveled gear.
//   "flattop" = At the top of the flat top of the bevel gear.
// Side Effects:
//   If internal is true then the default tag is "remove"
// Example: Beveled Gear
//   bevel_gear(
//       circ_pitch=5, teeth=36, face_width=10, shaft_diam=5,
//       pitch_angle=45, spiral_angle=0
//   );
// Example: Spiral Beveled Gear and Pinion
//   t1 = 16; t2 = 28;
//   bevel_gear(
//       circ_pitch=5, teeth=t1, mate_teeth=t2,
//       slices=12, anchor="apex", orient=FWD
//   );
//   bevel_gear(
//       circ_pitch=5, teeth=t2, mate_teeth=t1, left_handed=true,
//       slices=12, anchor="apex", spin=180/t2
//   );
// Example(Anim,Frames=4,VPD=175): Manual Spacing of Pinion and Gear
//   t1 = 14; t2 = 28; circ_pitch=5;
//   back(pitch_radius(circ_pitch, t2)) {
//     yrot($t*360/t1)
//     bevel_gear(
//       circ_pitch=circ_pitch, teeth=t1, mate_teeth=t2, shaft_diam=5,
//       slices=12, orient=FWD
//     );
//   }
//   down(pitch_radius(circ_pitch, t1)) {
//     zrot($t*360/t2)
//     bevel_gear(
//       circ_pitch=circ_pitch, teeth=t2, mate_teeth=t1, left_handed=true,
//       shaft_diam=5, slices=12, spin=180/t2
//     );
//   }

function bevel_gear(
    circ_pitch,
    teeth,
    face_width = 10,
    pitch_angle = 45,
    mate_teeth,
    hide = 0,
    pressure_angle = 20,
    clearance,
    backlash = 0.0,
    cutter_radius = 30,
    spiral_angle = 35,
    left_handed = false,
    slices = 5,
    internal,
    interior,
    pitch,
    diam_pitch,
    mod,
    anchor = "pitchbase",
    spin = 0,
    orient = UP
) = let(
        dummy = !is_undef(interior) ? echo("In bevel_gear(), the argument 'interior=' has been deprecated, and may be removed in the future.  Please use 'internal=' instead."):0,
        internal = first_defined([internal,interior,false]),
        circ_pitch = _inherit_gear_pitch("bevel_gear()",pitch, circ_pitch, diam_pitch, mod),
        PA = _inherit_gear_pa(pressure_angle),
        spiral_angle = _inherit_gear_helical(spiral_angle, invert=!internal),
        face_width = _inherit_gear_thickness(face_width),
        slices = cutter_radius==0? 1 : slices,
        pitch_angle = is_undef(mate_teeth)? pitch_angle : atan(teeth/mate_teeth),
        pr = pitch_radius(circ_pitch, teeth),
        rr = _root_radius(circ_pitch, teeth, clearance, internal),
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
        profile = reverse(_gear_tooth_profile(
            circ_pitch = circ_pitch,
            teeth = teeth,
            pressure_angle = PA,
            clearance = clearance,
            backlash = backlash,
            internal = internal,
            center = true
        )),
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
        vnf1 = vnf_join([
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
            named_anchor("pitchbase", [0,0,pitchoff-thickness/2]),
            named_anchor("flattop", [0,0,thickness/2]),
            named_anchor("apex", [0,0,hyp_ang_to_opp(ocone_rad,90-pitch_angle)+pitchoff-thickness/2])
        ]
    ) reorient(anchor,spin,orient, vnf=vnf, extent=true, anchors=anchors, p=vnf);


module bevel_gear(
    circ_pitch,
    teeth,
    face_width = 10,
    pitch_angle = 45,
    mate_teeth,
    shaft_diam = 0,
    pressure_angle = 20,
    clearance = undef,
    backlash = 0.0,
    cutter_radius = 30,
    spiral_angle = 35,
    left_handed = false,
    slices = 5,
    internal,
    interior,
    pitch,
    diam_pitch,
    mod,
    anchor = "pitchbase",
    spin = 0,
    orient = UP
) {
    dummy = !is_undef(interior) ? echo("In bevel_gear(), the argument 'interior=' has been deprecated, and may be removed in the future.  Please use 'internal=' instead."):0;
    internal = first_defined([internal,interior,false]);
    circ_pitch = _inherit_gear_pitch("bevel_gear()",pitch, circ_pitch, diam_pitch, mod);
    PA = _inherit_gear_pa(pressure_angle);
    spiral_angle = _inherit_gear_helical(spiral_angle, invert=!internal);
    face_width = _inherit_gear_thickness(face_width);
    slices = cutter_radius==0? 1 : slices;
    pitch_angle = is_undef(mate_teeth)? pitch_angle : atan(teeth/mate_teeth);
    pr = pitch_radius(circ_pitch, teeth);
    ipr = pr - face_width*sin(pitch_angle);
    rr = _root_radius(circ_pitch, teeth, clearance, internal);
    pitchoff = (pr-rr) * sin(pitch_angle);
    vnf = bevel_gear(
        circ_pitch = circ_pitch,
        teeth = teeth,
        face_width = face_width,
        pitch_angle = pitch_angle,
        pressure_angle = PA,
        clearance = clearance,
        backlash = backlash,
        cutter_radius = cutter_radius,
        spiral_angle = spiral_angle,
        left_handed = left_handed,
        slices = slices,
        internal = internal,
        anchor=CENTER
    );
    axis_zs = [for (p=vnf[0]) if(norm(point2d(p)) < EPSILON) p.z];
    thickness = max(axis_zs) - min(axis_zs);
    anchors = [
        named_anchor("pitchbase", [0,0,pitchoff-thickness/2]),
        named_anchor("flattop", [0,0,thickness/2]),
        named_anchor("apex", [0,0,adj_ang_to_opp(pr,90-pitch_angle)+pitchoff-thickness/2])
    ];
    default_tag("remove",internal) {
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
}


// Function&Module: worm()
// Synopsis: Creates a worm that will mate with a worm gear.
// SynTags: Geom, VNF
// Topics: Gears, Parts
// See Also: worm(), worm_gear(), rack(), rack2d(), spur_gear(), spur_gear2d(), bevel_pitch_angle(), bevel_gear()
// Usage: As a Module
//   worm(circ_pitch, d, l, [starts=], [left_handed=], [pressure_angle=], [backlash=], [clearance=]);
//   worm(mod=, d=, l=, [starts=], [left_handed=], [pressure_angle=], [backlash=], [clearance=]);
// Usage: As a Function
//   vnf = worm(circ_pitch, d, l, [starts=], [left_handed=], [pressure_angle=], [backlash=], [clearance=]);
//   vnf = worm(mod=, d=, l=, [starts=], [left_handed=], [pressure_angle=], [backlash=], [clearance=]);
// Description:
//   Creates a worm shape that can be matched to a worm gear.
// Arguments:
//   circ_pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.  Default: 5
//   d = The diameter of the worm.  Default: 30
//   l = The length of the worm.  Default: 100
//   starts = The number of lead starts.  Default: 1
//   left_handed = If true, the gear returned will have a left-handed spiral.  Default: false
//   pressure_angle = Controls how straight or bulged the tooth sides are. In degrees. Default: 20
//   backlash = Gap between two meshing teeth, in the direction along the circumference of the pitch circle.  Default: 0
//   clearance = Clearance gap at the bottom of the inter-tooth valleys.
//   profile_shift = Profile shift factor x.
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  Note that the diametral pitch is a completely different thing than the pitch diameter.
//   mod = The metric module/modulus of the gear, or mm of pitch diameter per tooth.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Example:
//   worm(circ_pitch=8, d=30, l=50, $fn=72);
// Example: Multiple Starts.
//   worm(circ_pitch=8, d=30, l=50, starts=3, $fn=72);
// Example: Left Handed
//   worm(circ_pitch=8, d=30, l=50, starts=3, left_handed=true, $fn=72);
// Example: Called as Function
//   vnf = worm(circ_pitch=8, d=35, l=50, starts=2, left_handed=true, pressure_angle=20, $fn=72);
//   vnf_polyhedron(vnf);

function worm(
    circ_pitch,
    d=30, l=100,
    starts=1,
    left_handed=false,
    pressure_angle,
    backlash=0,
    clearance,
    profile_shift,
    diam_pitch,
    mod,
    pitch,
    anchor=CENTER,
    spin=0,
    orient=UP
) =
    let(
        circ_pitch = _inherit_gear_pitch("worm()", pitch, circ_pitch, diam_pitch, mod),
        PA = _inherit_gear_pa(pressure_angle),
        profile_shift = default(profile_shift, 0)
    )
    assert(is_integer(starts) && starts>0)
    assert(is_finite(l) && l>0)
    //assert(is_finite(shaft_diam) && shaft_diam>=0)
    assert(is_finite(PA) && PA>=0 && PA<90, "Bad pressure_angle value.")
    assert(clearance==undef || (is_finite(clearance) && clearance>=0))
    assert(is_finite(backlash) && backlash>=0)
    assert(is_bool(left_handed))
    assert(is_finite(profile_shift) && abs(profile_shift)<1)
    //assert(is_finite(gear_spin))
    let(
        helical = asin(starts * circ_pitch / PI / d),
        trans_pitch = circ_pitch / cos(helical),
        tooth = xflip(
            p=select(rack2d(
                pitch=circ_pitch,
                teeth=1,
                pressure_angle=PA,
                clearance=clearance,
                backlash=backlash,
                helical=helical,
                profile_shift=profile_shift
            ), 1, -2)
        ),
        rack_profile = [
            for (t = xcopies(trans_pitch, n=2*ceil(l/trans_pitch)+1))
                each apply(t, tooth)
        ],
        steps = max(36, segs(d/2)),
        step = 360 / steps,
        zsteps = ceil(l / circ_pitch * cos(helical) / starts * steps),
        zstep = l / zsteps,
        profiles = [
            for (j = [0:1:zsteps]) [
                for (i = [0:1:steps-1]) let(
                    u = i / steps - 0.5,
                    ang = 360 * (1 - u) + 90,
                    z = j*zstep - l/2,
                    zoff = circ_pitch * starts * u / cos(helical),
                    h = lookup(z+zoff, rack_profile)
                )
                cylindrical_to_xyz(d/2+h, ang, z)
            ]
        ],
        vnf1 = vnf_vertex_array(profiles, caps=true, col_wrap=true, style="alt"),
        vnf = left_handed? xflip(p=vnf1) : vnf1
    ) reorient(anchor,spin,orient, d=d, l=l, p=vnf);


module worm(
    circ_pitch,
    d=15, l=100,
    starts=1,
    left_handed=false,
    pressure_angle,
    backlash=0,
    clearance,
    profile_shift=0,
    pitch,
    diam_pitch,
    mod,
    gear_spin=0,
    anchor=CENTER,
    spin=0,
    orient=UP
) {
    circ_pitch = _inherit_gear_pitch("worm()", pitch, circ_pitch, diam_pitch, mod);
    PA = _inherit_gear_pa(pressure_angle);
    profile_shift = default(profile_shift, auto_profile_shift(starts,PA));
    checks =
        assert(is_integer(starts) && starts>0)
        assert(is_finite(l) && l>0)
        //assert(is_finite(shaft_diam) && shaft_diam>=0)
        assert(is_finite(PA) && PA>=0 && PA<90, "Bad pressure_angle value.")
        assert(clearance==undef || (is_finite(clearance) && clearance>=0))
        assert(is_finite(backlash) && backlash>=0)
        assert(is_bool(left_handed))
        assert(is_finite(gear_spin))
        assert(is_finite(profile_shift) && abs(profile_shift)<1);
    vnf = worm(
        circ_pitch=circ_pitch,
        starts=starts,
        d=d, l=l,
        left_handed=left_handed,
        pressure_angle=PA,
        backlash=backlash,
        clearance=clearance,
        profile_shift=profile_shift,
        mod=mod
    );
    attachable(anchor,spin,orient, d=d, l=l) {
        zrot(gear_spin) vnf_polyhedron(vnf, convexity=ceil(l/circ_pitch)*2);
        children();
    }
}


// Function&Module: worm_gear()
// Synopsis: Creates a worm gear that will mate with a worm.
// SynTags: Geom, VNF
// Topics: Gears, Parts
// See Also: worm(), worm_gear(), rack(), rack2d(), spur_gear(), spur_gear2d(), bevel_pitch_angle(), bevel_gear()
// Usage: As a Module
//   worm_gear(circ_pitch, teeth, worm_diam, [worm_starts=], [worm_arc=], [crowning=], [left_handed=], [pressure_angle=], [backlash=], [clearance=], [slices=], [shaft_diam=]) [ATTACHMENTS];
//   worm_gear(mod=, teeth=, worm_diam=, [worm_starts=], [worm_arc=], [crowning=], [left_handed=], [pressure_angle=], [backlash=], [clearance=], [slices=], [shaft_diam=]) [ATTACHMENTS];
// Usage: As a Function
//   vnf = worm_gear(circ_pitch, teeth, worm_diam, [worm_starts=], [worm_arc=], [crowning=], [left_handed=], [pressure_angle=], [backlash=], [clearance=], [slices=]);
//   vnf = worm_gear(mod=, teeth=, worm_diam=, [worm_starts=], [worm_arc=], [crowning=], [left_handed=], [pressure_angle=], [backlash=], [clearance=], [slices=]);
// Description:
//   Creates a worm gear to match with a worm.
// Arguments:
//   circ_pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.  Default: 5
//   teeth = Total number of teeth along the rack.  Default: 30
//   worm_diam = The pitch diameter of the worm gear to match to.  Default: 30
//   worm_starts = The number of lead starts on the worm gear to match to.  Default: 1
//   worm_arc = The arc of the worm to mate with, in degrees. Default: 60 degrees
//   crowning = The amount to oversize the virtual hobbing cutter used to make the teeth, to add a slight crowning to the teeth to make them fit the work easier.  Default: 1
//   left_handed = If true, the gear returned will have a left-handed spiral.  Default: false
//   pressure_angle = Controls how straight or bulged the tooth sides are. In degrees. Default: 20
//   backlash = Gap between two meshing teeth, in the direction along the circumference of the pitch circle.  Default: 0
//   clearance = Clearance gap at the bottom of the inter-tooth valleys.
//   profile_shift = Profile shift factor x.
//   slices = The number of vertical slices to refine the curve of the worm throat.  Default: 10
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  Note that the diametral pitch is a completely different thing than the pitch diameter.
//   mod = The metric module/modulus of the gear, or mm of pitch diameter per tooth.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Example: Right-Handed
//   worm_gear(circ_pitch=5, teeth=36, worm_diam=30, worm_starts=1);
// Example: Left-Handed
//   worm_gear(circ_pitch=5, teeth=36, worm_diam=30, worm_starts=1, left_handed=true);
// Example: Multiple Starts
//   worm_gear(circ_pitch=5, teeth=36, worm_diam=30, worm_starts=4);
// Example: Metric Worm Gear
//   worm_gear(mod=2, teeth=32, worm_diam=30, worm_starts=1);
// Example(Anim,Frames=4,FrameMS=125,VPD=220,VPT=[-15,0,0]): Meshing Worm and Gear
//   $fn=36;
//   circ_pitch = 5; starts = 4;
//   worm_diam = 30; worm_length = 50;
//   gear_teeth=36;
//   right(worm_diam/2)
//     yrot($t*360/starts)
//       worm(
//          d=worm_diam,
//          l=worm_length,
//          circ_pitch=circ_pitch,
//          starts=starts,
//          orient=BACK);
//   left(pitch_radius(circ_pitch, gear_teeth))
//     zrot(-$t*360/gear_teeth)
//       worm_gear(
//          circ_pitch=circ_pitch,
//          teeth=gear_teeth,
//          worm_diam=worm_diam,
//          worm_starts=starts);
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
//   vnf = worm_gear(circ_pitch=8, teeth=30, worm_diam=30, worm_starts=1);
//   vnf_polyhedron(vnf);

function worm_gear(
    circ_pitch,
    teeth,
    worm_diam,
    worm_starts = 1,
    worm_arc = 60,
    crowning = 0.1,
    left_handed = false,
    pressure_angle,
    backlash = 0,
    clearance,
    profile_shift,
    slices = 10,
    gear_spin=0,
    pitch,
    diam_pitch,
    mod,
    anchor = CENTER,
    spin = 0,
    orient = UP
) =
    assert(worm_arc >= 10 && worm_arc <= 60)
    let(
        circ_pitch = _inherit_gear_pitch("worm_gear()", pitch, circ_pitch, diam_pitch, mod),
        PA = _inherit_gear_pa(pressure_angle),
        profile_shift = default(profile_shift, auto_profile_shift(teeth,PA))
    )
    assert(is_integer(teeth) && teeth>10)
    assert(is_finite(worm_diam) && worm_diam>0)
    assert(is_integer(worm_starts) && worm_starts>0)
    assert(is_finite(worm_arc) && worm_arc>0 && worm_arc<90)
    assert(is_finite(crowning) && crowning>=0)
    assert(is_bool(left_handed))
    assert(is_finite(PA) && PA>=0 && PA<90, "Bad pressure_angle value.")
    assert(clearance==undef || (is_finite(clearance) && clearance>=0))
    assert(is_finite(backlash) && backlash>=0)
    //assert(is_finite(shaft_diam) && shaft_diam>=0)
    assert(slices==undef || (is_integer(slices) && slices>0))
    assert(is_finite(profile_shift) && abs(profile_shift)<1)
    assert(is_finite(gear_spin))
    let(
        helical = asin(worm_starts * circ_pitch / PI / worm_diam),
        pr = pitch_radius(circ_pitch, teeth, helical),
        hob_rad = worm_diam / 2 + crowning,
        thickness = worm_gear_thickness(circ_pitch=circ_pitch, teeth=teeth, worm_diam=worm_diam, worm_arc=worm_arc, crowning=crowning, clearance=clearance),
        tooth_profile = _gear_tooth_profile(
            circ_pitch=circ_pitch,
            teeth=teeth,
            pressure_angle=PA,
            clearance=clearance,
            backlash=backlash,
            helical=helical,
            profile_shift=profile_shift,
            center=true
        ),
        tbot = min(column(tooth_profile,1)),
        arcthick = hob_rad * sin(worm_arc/2) * 2,
        twist = sin(helical)*arcthick / (2*PI*pr) * 360,
        profiles = [
            for (slice = [0:1:slices]) let(
                u = slice/slices - 0.5
            ) [
                for (i = [0:1:teeth-1]) each
                apply(
                    zrot(-i*360/teeth + twist*u - 0.5) *
                        right(pr+hob_rad) *
                        yrot(u*worm_arc) *
                        left(hob_rad) *
                        zrot(-90) *
                        back(tbot) *
                        scale(cos(u*worm_arc)) *
                        fwd(tbot),
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
        vnf1 = vnf_join([
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
        m = product([
            zrot(gear_spin),
            if (left_handed) xflip(),
        ]),
        vnf = apply(m,vnf1)
    ) reorient(anchor,spin,orient, r=pr, l=thickness, p=vnf);


module worm_gear(
    circ_pitch,
    teeth,
    worm_diam,
    worm_starts = 1,
    worm_arc = 60,
    crowning = 0.1,
    left_handed = false,
    pressure_angle,
    clearance,
    backlash = 0,
    shaft_diam = 0,
    slices = 10,
    profile_shift,
    gear_spin=0,
    pitch,
    diam_pitch,
    mod,
    anchor = CENTER,
    spin = 0,
    orient = UP
) {
    circ_pitch = _inherit_gear_pitch("worm_gear()", pitch, circ_pitch, diam_pitch, mod);
    PA = _inherit_gear_pa(pressure_angle);
    profile_shift = default(profile_shift, auto_profile_shift(teeth,PA));
    checks =
        assert(is_integer(teeth) && teeth>10)
        assert(is_finite(worm_diam) && worm_diam>0)
        assert(is_integer(worm_starts) && worm_starts>0)
        assert(is_finite(worm_arc) && worm_arc>0 && worm_arc<90)
        assert(is_finite(crowning) && crowning>=0)
        assert(is_bool(left_handed))
        assert(is_finite(PA) && PA>=0 && PA<90, "Bad pressure_angle value.")
        assert(clearance==undef || (is_finite(clearance) && clearance>=0))
        assert(is_finite(backlash) && backlash>=0)
        assert(is_finite(shaft_diam) && shaft_diam>=0)
        assert(slices==undef || (is_integer(slices) && slices>0))
        assert(is_finite(profile_shift) && abs(profile_shift)<1)
        assert(is_finite(gear_spin));
    helical = asin(worm_starts * circ_pitch / PI / worm_diam);
    pr = pitch_radius(circ_pitch, teeth, helical);
    vnf = worm_gear(
        circ_pitch = circ_pitch,
        teeth = teeth,
        worm_diam = worm_diam,
        worm_starts = worm_starts,
        worm_arc = worm_arc,
        crowning = crowning,
        left_handed = left_handed,
        pressure_angle = PA,
        backlash = backlash,
        clearance = clearance,
        profile_shift = profile_shift,
        slices = slices
    );
    thickness = pointlist_bounds(vnf[0])[1].z;
    attachable(anchor,spin,orient, r=pr, l=thickness) {
        zrot(gear_spin)
        difference() {
            vnf_polyhedron(vnf, convexity=teeth/2);
            if (shaft_diam > 0) {
                cylinder(h=2*thickness+1, r=shaft_diam/2, center=true, $fn=max(12,segs(shaft_diam/2)));
            }
        }
        children();
    }
}




/// Function: _gear_tooth_profile()
/// Usage: As Function
///   path = _gear_tooth_profile(pitch, teeth, [pressure_angle], [clearance], [backlash], [internal]);
/// Topics: Gears
/// See Also: spur_gear2d()
/// Description:
///   When called as a function, returns the 2D profile path for an individual gear tooth.
///   When called as a module, creates the 2D profile shape for an individual gear tooth.
/// Arguments:
///   circ_pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.
///   teeth = Total number of teeth on the spur gear that this is a tooth for.
///   pressure_angle = Pressure Angle.  Controls how straight or bulged the tooth sides are. In degrees.
///   clearance = Gap between top of a tooth on one gear and bottom of valley on a meshing gear (in millimeters)
///   backlash = Gap between two meshing teeth, in the direction along the circumference of the pitch circle
///   internal = If true, create a mask for difference()ing from something else.
///   center = If true, centers the pitch circle of the tooth profile at the origin.  Default: false.
///   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  Note that the diametral pitch is a completely different thing than the pitch diameter.
///   mod = The metric module/modulus of the gear, or mm of pitch diameter per tooth.
/// Example(2D):
///   _gear_tooth_profile(circ_pitch=5, teeth=20, pressure_angle=20);
/// Example(2D): Metric Gear Tooth
///   _gear_tooth_profile(mod=2, teeth=20, pressure_angle=20);
/// Example(2D):
///   _gear_tooth_profile(
///       circ_pitch=5, teeth=20, pressure_angle=20
///   );
/// Example(2D): As a function
///   path = _gear_tooth_profile(
///       circ_pitch=5, teeth=20, pressure_angle=20
///   );
///   stroke(path, width=0.1);

function _gear_tooth_profile(
    circ_pitch,
    teeth,
    pressure_angle = 20,
    clearance,
    backlash = 0.0,
    helical = 0,
    internal = false,
    profile_shift = 0.0,
    mod,
    diam_pitch,
    pitch,
    center = false
) = let(
    // Calculate a point on the involute curve, by angle.
    _involute = function(base_r,a)
        let(b=a*PI/180) base_r * [cos(a)+b*sin(a), sin(a)-b*cos(a)],

    steps = 16,
    circ_pitch = circular_pitch(pitch=pitch, circ_pitch=circ_pitch, diam_pitch=diam_pitch, mod=mod),

    // Calculate the important circle radii
    arad = outer_radius(circ_pitch, teeth, helical=helical, profile_shift=profile_shift, internal=internal),
    prad = pitch_radius(circ_pitch, teeth, helical=helical),
    brad = _base_radius(circ_pitch, teeth, pressure_angle, helical=helical),
    rrad = _root_radius(circ_pitch, teeth, clearance, helical=helical, profile_shift=profile_shift, internal=internal),

    srad = max(rrad,brad),
    clear = default(clearance, circ_pitch/PI * 0.25),
    tthick = circ_pitch/PI / cos(helical) * (PI/2 + 2*profile_shift * tan(pressure_angle)) - backlash,
    tang = tthick / prad / 2 * 180 / PI,

    // Generate a lookup table for the involute curve angles, by radius
    involute_lup = [
        if (rrad < brad)
            each xy_to_polar(arc(n=4, r=min(brad-rrad,clear), corner=[
                polar_to_xy(rrad,90+180/teeth),
                polar_to_xy(rrad,90),
                polar_to_xy(brad,90),
            ])),
        for (i=[0:5:arad/PI/brad*360])
            let(
                xy = _involute(brad,i),
                pol = xy_to_polar(xy)
            )
            if (pol.x <= arad * 1.1)
            [pol.x, 90-pol.y]
    ],

    // Generate reverse lookup table for involute radii, by angle
    involute_rlup = mirror([-1,1],p=involute_lup), // swaps X and Y columns.

    a_ang = lookup(arad, involute_lup),
    p_ang = lookup(prad, involute_lup),
    b_ang = lookup(brad, involute_lup),
    r_ang = lookup(rrad, involute_lup),
    s_ang = lookup(srad, involute_lup),
    soff = tang + (b_ang - p_ang),
    ma_rad = min(arad, lookup(90-soff+0.05*360/teeth/2, involute_rlup)),
    ma_ang = lookup(ma_rad, involute_lup),
    cap_steps = ceil((ma_ang + soff - 90) / 5),
    cap_step = (ma_ang + soff - 90) / cap_steps,
    ax = circ_pitch/4 - ang_adj_to_opp(pressure_angle, circ_pitch/PI),

    // Calculate the undercut a meshing rack might carve out of this tooth.
    undercut = [
        for (a=[atan2(ax,rrad):-1:-90])
        let(
            bx = -a/360 * 2*PI*prad,
            x = bx + ax,
            y = prad - circ_pitch/PI + profile_shift*circ_pitch/PI,
            pol = xy_to_polar(x,y)
        )
        if (pol.x < arad*1.05)
        [pol.x, pol.y-a+180/teeth]
    ],
    uc_min = min_index(column(undercut,0)),

    // Generate a fast lookup table for the undercut.
    undercut_lup = [for (i=idx(undercut)) if (i>=uc_min) undercut[i]],

    // The u values to use when generating the tooth.
    us = [
        for (i=[0.0:0.02:0.2-EPSILON]) i,
        for (i=[0:1:steps-1]) 0.2 + i/(steps-1)*0.8,
    ],

    // Generate the left half of the tooth.
    tooth_half_raw = deduplicate([
        for (u = us) let(
            r = lerp(rrad, ma_rad, u),
            a1 = lookup(r, involute_lup) + soff,
            a2 = lookup(r, undercut_lup),
            a = internal || r < undercut_lup[0].x? a1 : min(a1,a2)
        ) if(a<90+180/teeth) polar_to_xy(r, a),
        for (i=[0:1:cap_steps-1]) let(
            a = ma_ang + soff - i * (cap_step-1)
        ) polar_to_xy(ma_rad, a),
    ]),

    // Strip "jaggies" if found.
    strip_left = function(path,i)
        i > len(path)? [] :
        norm(path[i]) >= prad? [for (j=idx(path)) if(j>=i) path[j]] :
        let(
            angs = [
                for (j=[i+1:1:len(path)-1]) let(
                    p = path[i],
                    np = path[j],
                    r = norm(np),
                    a = v_theta(np-p)
                ) if(r<prad) a
            ],
            mti = !angs? 0 : min_index(angs),
            out = concat([path[i]], strip_left(path, i + mti + 1))
        ) out,
    tooth_half = strip_left(tooth_half_raw, 0),

    // Mirror the tooth to complete it.
    tooth = deduplicate([
        each tooth_half,
        each reverse(xflip(tooth_half)),
    ]),
    out = center? fwd(prad, p=tooth) : tooth
) out;



// Section: Computing Gear Dimensions
//   These functions let the user find the derived dimensions of the gear.
//   A gear fits within a circle of radius outer_radius, and two gears should have
//   their centers separated by the sum of their pitch_radius.


// Function: circular_pitch()
// Synopsis: Returns tooth density expressed as "circular pitch".
// Topics: Gears, Parts
// See Also: spur_gear(), diametral_pitch(), circular_pitch(), pitch_value(), module_value()
// Usage:
//   circ_pitch = circular_pitch(circ_pitch);
//   circ_pitch = circular_pitch(mod=);
//   circ_pitch = circular_pitch(diam_pitch=);
// Description:
//   Get tooth density expressed as "circular pitch", or the distance in mm between teeth around the pitch circle.
//   For example, if you have a gear with 11 teeth, and the pitch diameter is 35mm, then the circumfrence
//   of the pitch diameter is really close to 110mm, making the circular pitch of that gear about 10mm/tooth.
// Arguments:
//   circ_pitch = The circular pitch, or distance in mm between teeth around the pitch circle.
//   ---
//   mod = The metric module/modulus of the gear, or mm of pitch diameter per tooth.
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  Note that the diametral pitch is a completely different thing than the pitch diameter.
// Example(VPT=[0,31,0];VPR=[0,0,0];VPD=40):
//   $fn=144;
//   teeth=20;
//   circ_pitch = circular_pitch(diam_pitch=8);
//   pr = pitch_radius(circ_pitch, teeth);
//   stroke(spur_gear2d(circ_pitch, teeth), width=0.1);
//   color("cyan")
//       dashed_stroke(circle(r=pr), width=0.1);
//   color("black") {
//       stroke(
//           arc(r=pr, start=90+90/teeth, angle=-360/teeth),
//           width=0.2, endcaps="arrow");
//       back(pr+1) right(3)
//          zrot(30) text("Circular Pitch", size=1);
//   }
// Example:
//   circ_pitch = circular_pitch(circ_pitch=5);
//   circ_pitch = circular_pitch(diam_pitch=12);
//   circ_pitch = circular_pitch(mod=2);

function circular_pitch(circ_pitch, mod, pitch, diam_pitch) =
    assert(one_defined([pitch, mod, circ_pitch, diam_pitch], "pitch,mod,circ_pitch,diam_pitch"))
    pitch != undef? assert(is_finite(pitch) && pitch>0) pitch :
    circ_pitch != undef? assert(is_finite(circ_pitch) && circ_pitch>0) circ_pitch :
    diam_pitch != undef? assert(is_finite(diam_pitch) && diam_pitch>0) PI / diam_pitch * INCH :
    assert(is_finite(mod) && mod>0) mod * PI;


// Function: diametral_pitch()
// Synopsis: Returns tooth density expressed as "diametral pitch".
// Topics: Gears, Parts
// See Also: spur_gear(), diametral_pitch(), circular_pitch(), pitch_value(), module_value()
// Usage:
//   dp = diametral_pitch(circ_pitch);
//   dp = diametral_pitch(mod=);
//   dp = diametral_pitch(diam_pitch=);
// Description:
//   Returns tooth density expressed as "diametral pitch", the number of teeth per inch of pitch diameter.
//   For example, if you have a gear with 30 teeth, with a 1.5 inch pitch diameter, then you have a
//   diametral pitch of 20 teeth/inch.
// Arguments:
//   circ_pitch = The circular pitch, or distance in mm between teeth around the pitch circle.
//   ---
//   mod = The metric module/modulus of the gear, or mm of pitch diameter per tooth.
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  Note that the diametral pitch is a completely different thing than the pitch diameter.
// Example:
//   diam_pitch = diametral_pitch(mod=2);
//   diam_pitch = diametral_pitch(circ_pitch=8);
//   diam_pitch = diametral_pitch(diam_pitch=16);

function diametral_pitch(circ_pitch, mod, pitch, diam_pitch) =
    let( circ_pitch = circular_pitch(pitch, mod, circ_pitch, diam_pitch) )
    PI / circ_pitch / INCH;


// Function: pitch_value()
// Synopsis: Returns tooth density expressed as "circular pitch".
// Topics: Gears, Parts
// See Also: spur_gear(), diametral_pitch(), circular_pitch(), pitch_value(), module_value()
// Usage:
//   circ_pitch = pitch_value(mod);
//   circ_pitch = pitch_value(circ_pitch=);
//   circ_pitch = pitch_value(diam_pitch=);
// Description:
//   Returns the circular pitch in mm from module/modulus or diametral pitch.
//   The circular pitch of a gear is the number of millimeters per tooth around the pitch radius circle.
//   For example, if you have a gear with 11 teeth, and the pitch diameter is 35mm, then the circumfrence
//   of the pitch diameter is really close to 110mm, making the circular pitch of that gear about 10mm/tooth.
// Arguments:
//   mod = The metric module/modulus of the gear, or mm of pitch diameter per tooth.
//   ---
//   circ_pitch = The circular pitch, or distance in mm between teeth around the pitch circle.
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  Note that the diametral pitch is a completely different thing than the pitch diameter.
// Example:
//   circ_pitch = pitch_value(mod=2);
//   circ_pitch = pitch_value(circ_pitch=8);
//   circ_pitch = pitch_value(diam_pitch=16);

function pitch_value(mod, circ_pitch, diam_pitch) =
    circular_pitch(mod=mod, circ_pitch=circ_pitch, diam_pitch=diam_pitch);


// Function: module_value()
// Synopsis: Returns tooth density expressed as "module" or "modulus" in millimeters.
// Topics: Gears, Parts
// See Also: spur_gear(), diametral_pitch(), circular_pitch(), pitch_value(), module_value()
// Usage:
//   mod = module_value(circ_pitch);
//   mod = module_value(mod=);
//   mod = module_value(diam_pitch=);
// Description:
//   Get tooth density expressed as "module" or "modulus" in millimeters.  The module is the pitch
//   diameter of the gear divided by the number of teeth on it.  For example, a gear with a pitch
//   diameter of 40mm, with 20 teeth on it will have a modulus of 2.
// Arguments:
//   circ_pitch = The circular pitch, or distance in mm between teeth around the pitch circle.
//   ---
//   mod = The metric module/modulus of the gear, or mm of pitch diameter per tooth.
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  Note that the diametral pitch is a completely different thing than the pitch diameter.
// Example:
//   mod = module_value(circ_pitch=8);
//   mod = module_value(mod=2);
//   mod = module_value(diam_pitch=16);

function module_value(circ_pitch, mod, pitch, diam_pitch) =
    let( circ_pitch = circular_pitch(pitch, mod, circ_pitch, diam_pitch) )
    circ_pitch / PI;


/// Function: _adendum()
/// Usage:
///   ad = _adendum(circ_pitch, [profile_shift]);
///   ad = _adendum(diam_pitch=, [profile_shift=]);
///   ad = _adendum(mod=, [profile_shift=]);
/// Topics: Gears
/// Description:
///   The height of the top of a gear tooth above the pitch radius circle.
/// Arguments:
///   circ_pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.
///   profile_shift = Profile shift factor x.
///   ---
///   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  Note that the diametral pitch is a completely different thing than the pitch diameter.
///   mod = The metric module/modulus of the gear, or mm of pitch diameter per tooth.
/// Example:
///   ad = _adendum(circ_pitch=5);
///   ad = _adendum(mod=2);
/// Example(2D):
///   circ_pitch = 5; teeth = 17;
///   pr = pitch_radius(circ_pitch, teeth);
///   adn = _adendum(circ_pitch=5);
///   #spur_gear2d(circ_pitch=circ_pitch, teeth=teeth);
///   color("black") {
///       stroke(circle(r=pr),width=0.1,closed=true);
///       stroke(circle(r=pr+adn),width=0.1,closed=true);
///   }

function _adendum(
    circ_pitch,
    profile_shift=0,
    diam_pitch,
    mod,
    pitch
) =
    let( mod = module_value(circ_pitch, mod, pitch, diam_pitch) )
    mod * (1 + profile_shift);


/// Function: _dedendum()
/// Usage:
///   ddn = _dedendum(circ_pitch=, [clearance], [profile_shift]);
///   ddn = _dedendum(diam_pitch=, [clearance=], [profile_shift=]);
///   ddn = _dedendum(mod=, [clearance=], [profile_shift=]);
/// Topics: Gears
/// Description:
///   The depth of the gear tooth valley, below the pitch radius.
/// Arguments:
///   circ_pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.
///   clearance = If given, sets the clearance between meshing teeth.
///   profile_shift = Profile shift factor x.
///   ---
///   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  Note that the diametral pitch is a completely different thing than the pitch diameter.
///   mod = The metric module/modulus of the gear, or mm of pitch diameter per tooth.
/// Example:
///   ddn = _dedendum(circ_pitch=5);
///   ddn = _dedendum(mod=2);
/// Example(2D):
///   circ_pitch = 5; teeth = 17;
///   pr = pitch_radius(circ_pitch, teeth);
///   ddn = _dedendum(circ_pitch=5);
///   #spur_gear2d(circ_pitch=circ_pitch, teeth=teeth);
///   color("black") {
///       stroke(circle(r=pr),width=0.1,closed=true);
///       stroke(circle(r=pr-ddn),width=0.1,closed=true);
///   }

function _dedendum(
    circ_pitch,
    clearance,
    profile_shift=0,
    diam_pitch,
    mod,
    pitch
) = let(
        mod = module_value(circ_pitch, mod, pitch, diam_pitch),
        clearance = default(clearance, 0.25 * mod)
    )
    mod * (1 - profile_shift) + clearance;


// Function: pitch_radius()
// Synopsis: Returns the pitch radius for a gear.
// Topics: Gears, Parts
// See Also: spur_gear(), diametral_pitch(), circular_pitch(), pitch_value(), module_value(), outer_radius()
// Usage:
//   pr = pitch_radius(pitch, teeth, [helical]);
//   pr = pitch_radius(mod=, teeth=, [helical=]);
// Description:
//   Calculates the pitch radius for the gear.  Two mated gears will have their centers spaced apart
//   by the sum of the two gear's pitch radii.
// Arguments:
//   circ_pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.
//   teeth = The number of teeth on the gear.
//   helical = The helical angle (from vertical) of the teeth on the gear.  Default: 0
//   ---
//   mod = The metric module/modulus of the gear, or mm of pitch diameter per tooth.
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  Note that the diametral pitch is a completely different thing than the pitch diameter.
// Example:
//   pr = pitch_radius(circ_pitch=5, teeth=11);
//   pr = pitch_radius(circ_pitch=5, teeth=11, helical=30);
//   pr = pitch_radius(diam_pitch=10, teeth=11);
//   pr = pitch_radius(mod=2, teeth=20);
//   pr = pitch_radius(mod=2, teeth=20, helical=30);
// Example(2D):
//   $fn=144;
//   teeth=17; circ_pitch = 5;
//   pr = pitch_radius(circ_pitch, teeth);
//   stroke(spur_gear2d(circ_pitch, teeth), width=0.1);
//   color("blue") dashed_stroke(circle(r=pr), width=0.1);
//   color("black") {
//       stroke([[0,0],polar_to_xy(pr,45)],
//           endcaps="arrow", width=0.3);
//       fwd(1)
//           text("Pitch Radius", size=1.5,
//               halign="center", valign="top");
//   }

function pitch_radius(
    circ_pitch,
    teeth,
    helical=0,
    mod,
    diam_pitch,
    pitch
) =
    let( circ_pitch = circular_pitch(pitch, mod, circ_pitch, diam_pitch) )
    circ_pitch * teeth / PI / 2 / cos(helical);


// Function: outer_radius()
// Synopsis: Returns the outer radius for a gear.
// Topics: Gears, Parts
// See Also: spur_gear(), diametral_pitch(), circular_pitch(), pitch_value(), module_value(), pitch_radius(), outer_radius()
// Usage:
//   or = outer_radius(circ_pitch, teeth, [helical=], [clearance=], [internal=], [profile_shift=]);
//   or = outer_radius(mod=, teeth=, [helical=], [clearance=], [internal=], [profile_shift=]);
//   or = outer_radius(diam_pitch=, teeth=, [helical=], [clearance=], [internal=], [profile_shift=]);
// Description:
//   Calculates the outer radius for the gear. The gear fits entirely within a cylinder of this radius.
// Arguments:
//   circ_pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.
//   teeth = The number of teeth on the gear.
//   ---
//   clearance = If given, sets the clearance between meshing teeth.
//   profile_shift = Profile shift factor x.
//   internal = If true, calculate for an internal gear.
//   helical = The helical angle (from vertical) of the teeth on the gear.  Default: 0
//   mod = The metric module/modulus of the gear, or mm of pitch diameter per tooth.
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  Note that the diametral pitch is a completely different thing than the pitch diameter.
// Example:
//   or = outer_radius(circ_pitch=5, teeth=20);
//   or = outer_radius(circ_pitch=5, teeth=20, helical=30);
//   or = outer_radius(diam_pitch=10, teeth=17);
//   or = outer_radius(mod=2, teeth=16);
// Example(2D):
//   $fn=144;
//   teeth=17; circ_pitch = 5;
//   or = outer_radius(circ_pitch, teeth);
//   stroke(spur_gear2d(circ_pitch, teeth), width=0.1);
//   color("blue") dashed_stroke(circle(r=or), width=0.1);
//   color("black") {
//       stroke([[0,0],polar_to_xy(or,45)],
//           endcaps="arrow", width=0.3);
//       fwd(1)
//           text("Outer Radius", size=1.5,
//               halign="center", valign="top");
//   }

function outer_radius(circ_pitch, teeth, clearance, internal=false, helical=0, profile_shift=0, mod, pitch, diam_pitch) =
    let( circ_pitch = circular_pitch(pitch, mod, circ_pitch, diam_pitch) )
    pitch_radius(circ_pitch, teeth, helical) + (
        internal
          ? _dedendum(circ_pitch, clearance, profile_shift=profile_shift)
          : _adendum(circ_pitch, profile_shift=profile_shift)
    );


/// Function: _root_radius()
/// Usage:
///   rr = _root_radius(circ_pitch, teeth, [helical], [clearance=], [internal=], [profile_shift=]);
///   rr = _root_radius(diam_pitch=, teeth=, [helical=], [clearance=], [internal=], [profile_shift=]);
///   rr = _root_radius(mod=, teeth=, [helical=], [clearance=], [internal=], [profile_shift=]);
/// Topics: Gears
/// Description:
///   Calculates the root radius for the gear, at the base of the dedendum.
/// Arguments:
///   circ_pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.
///   teeth = The number of teeth on the gear.
///   ---
///   clearance = If given, sets the clearance between meshing teeth.
///   internal = If true, calculate for an internal gear.
///   helical = The helical angle (from vertical) of the teeth on the gear.  Default: 0
///   profile_shift = Profile shift factor x.
///   mod = The metric module/modulus of the gear, or mm of pitch diameter per tooth.
///   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  Note that the diametral pitch is a completely different thing than the pitch diameter.
/// Example:
///   rr = _root_radius(circ_pitch=5, teeth=11);
///   rr = _root_radius(circ_pitch=5, teeth=16, helical=30);
///   rr = _root_radius(diam_pitch=10, teeth=11);
///   rr = _root_radius(mod=2, teeth=16);
/// Example(2D):
///   pr = _root_radius(circ_pitch=5, teeth=11);
///   #spur_gear2d(pitch=5, teeth=11);
///   color("black")
///       stroke(circle(r=pr),width=0.1,closed=true);

function _root_radius(circ_pitch, teeth, clearance, internal=false, helical=0, profile_shift=0, diam_pitch, mod, pitch) =
    let( circ_pitch = circular_pitch(pitch, mod, circ_pitch, diam_pitch) )
    pitch_radius(circ_pitch, teeth, helical) - (
        internal
          ? _adendum(circ_pitch, profile_shift=profile_shift)
          : _dedendum(circ_pitch, clearance, profile_shift=profile_shift)
    );


/// Function: _base_radius()
/// Usage:
///   br = _base_radius(circ_pitch, teeth, [pressure_angle], [helical]);
///   br = _base_radius(diam_pitch=, teeth=, [pressure_angle=], [helical=]);
///   br = _base_radius(mod=, teeth=, [pressure_angle=], [helical=]);
/// Topics: Gears
/// Description:
///   Get the base circle for involute teeth, at the base of the teeth.
/// Arguments:
///   pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.
///   teeth = The number of teeth on the gear.
///   pressure_angle = Pressure angle in degrees.  Controls how straight or bulged the tooth sides are.
///   helical = The helical angle (from vertical) of the teeth on the gear.  Default: 0
///   ---
///   mod = The metric module/modulus of the gear, or mm of pitch diameter per tooth.
///   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  Note that the diametral pitch is a completely different thing than the pitch diameter.
/// Example:
///   br = _base_radius(circ_pitch=5, teeth=20, pressure_angle=20);
///   br = _base_radius(circ_pitch=5, teeth=20, pressure_angle=20, helical=30);
///   br = _base_radius(diam_pitch=10, teeth=20, pressure_angle=20);
///   br = _base_radius(mod=2, teeth=18, pressure_angle=20);
/// Example(2D):
///   pr = _base_radius(circ_pitch=5, teeth=11);
///   #spur_gear2d(circ_pitch=5, teeth=11);
///   color("black")
///       stroke(circle(r=pr),width=0.1,closed=true);

function _base_radius(circ_pitch, teeth, pressure_angle=20, helical=0, diam_pitch, mod, pitch) =
    let(
        circ_pitch = circular_pitch(pitch, mod, circ_pitch, diam_pitch),
        trans_pa = atan(tan(pressure_angle)/cos(helical))
    )
    pitch_radius(circ_pitch, teeth, helical) * cos(trans_pa);


// Function: bevel_pitch_angle()
// Synopsis: Returns the pitch cone angle for a bevel gear.
// Topics: Gears, Parts
// See Also: bevel_gear(), pitch_radius(), outer_radius()
// Usage:
//   ang = bevel_pitch_angle(teeth, mate_teeth, [drive_angle=]);
// Description:
//   Returns the correct pitch cone angle for a bevel gear with a given number of teeth, that is
//   matched to another bevel gear with a (possibly different) number of teeth.
// Arguments:
//   teeth = Number of teeth that this gear has.
//   mate_teeth = Number of teeth that the matching gear has.
//   drive_angle = Angle between the drive shafts of each gear.  Default: 90º.
// Example:
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
// Synopsis: Returns the thickness for a worm gear.
// Topics: Gears, Parts
// See Also: worm(), worm_gear(), pitch_radius(), outer_radius()
// Usage:
//   thick = worm_gear_thickness(pitch, teeth, worm_diam, [worm_arc=], [crowning=], [clearance=]);
//   thick = worm_gear_thickness(mod=, teeth=, worm_diam=, [worm_arc=], [crowning=], [clearance=]);
// Description:
//   Calculate the thickness of the worm gear.
// Arguments:
//   circ_pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.  Default: 5
//   teeth = Total number of teeth along the rack.  Default: 30
//   worm_diam = The pitch diameter of the worm gear to match to.  Default: 30
//   ---
//   worm_arc = The arc of the worm to mate with, in degrees. Default: 60 degrees
//   crowning = The amount to oversize the virtual hobbing cutter used to make the teeth, to add a slight crowning to the teeth to make them fit the work easier.  Default: 1
//   clearance = Clearance gap at the bottom of the inter-tooth valleys.
//   mod = The metric module/modulus of the gear, or mm of pitch diameter per tooth.
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  Note that the diametral pitch is a completely different thing than the pitch diameter.
// Example:
//   thick = worm_gear_thickness(circ_pitch=5, teeth=36, worm_diam=30);
//   thick = worm_gear_thickness(mod=2, teeth=28, worm_diam=25);
// Example(2D):
//   circ_pitch = 5;  teeth=17;
//   worm_diam = 30; starts=2;
//   y = worm_gear_thickness(circ_pitch=circ_pitch, teeth=teeth, worm_diam=worm_diam);
//   #worm_gear(
//       circ_pitch=circ_pitch, teeth=teeth,
//       worm_diam=worm_diam,
//       worm_starts=starts,
//       orient=BACK
//   );
//   color("black") {
//       ycopies(y) stroke([[-25,0],[25,0]], width=0.5);
//       stroke([[-20,-y/2],[-20,y/2]],width=0.5,endcaps="arrow");
//   }

function worm_gear_thickness(circ_pitch, teeth, worm_diam, worm_arc=60, crowning=1, clearance, diam_pitch, mod, pitch) =
    let(
        circ_pitch = circular_pitch(pitch, mod, circ_pitch, diam_pitch),
        r = worm_diam/2 + crowning,
        pitch_thick = r * sin(worm_arc/2) * 2,
        pr = pitch_radius(circ_pitch, teeth),
        rr = _root_radius(circ_pitch, teeth, clearance, false),
        pitchoff = (pr-rr) * sin(worm_arc/2),
        thickness = pitch_thick + 2*pitchoff
    ) thickness;


// Function: mesh_radius()
// Synopsis: Returns the distance between two gear centers.
// Topics: Gears, Parts
// See Also: worm(), worm_gear(), pitch_radius(), outer_radius()
// Usage:
//   dist = mesh_radius(pitch, teeth, [helical=], [profile_shift=], [pressure_angle=]);
//   dist = mesh_radius(mod=, teeth=, [helical=], [profile_shift=], [pressure_angle=]);
// Description:
//   Calculate the distance between the centers of two gears.
// Arguments:
//   pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.  Default: 5
//   teeth = Total number of teeth in the first gear.  If given 0, we assume this is a rack or worm.
//   ---
//   helical = The helical angle (from vertical) of the teeth on the first gear.  Default: 0
//   profile_shift = Profile shift factor x for the first gear.  Default: 0
//   pressure_angle = The pressure angle of the gear.
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  Note that the diametral pitch is a completely different thing than the pitch diameter.
//   mod = The metric module/modulus of the gear, or mm of pitch diameter per tooth.
// Example(2D):
//   pitch=5; teeth1=7; teeth2=24;
//   mr1 = mesh_radius(pitch, teeth1);
//   mr2 = mesh_radius(pitch, teeth2);
//   left(mr1) spur_gear2d(pitch, teeth1, gear_spin=-90);
//   right(mr2) spur_gear2d(pitch, teeth2, gear_spin=90-180/teeth2);
// Example: Non-parallel Helical Gears
//   pitch=5; teeth1=15; teeth2=24; ha1=45; ha2=30; thick=10;
//   mr1 = mesh_radius(pitch, teeth1, helical=ha1);
//   mr2 = mesh_radius(pitch, teeth2, helical=ha2);
//   left(mr1) spur_gear(pitch, teeth1, helical=ha1, thickness=thick, gear_spin=-90);
//   right(mr2) xrot(ha1+ha2) spur_gear(pitch, teeth2, helical=ha2, thickness=thick, gear_spin=90-180/teeth2);
// Example(2D): Disable Auto Profile Shifting on the Small Gear
//   pitch=5; teeth1=7; teeth2=24;
//   mr1 = mesh_radius(pitch, teeth1, profile_shift=0);
//   mr2 = mesh_radius(pitch, teeth2);
//   left(mr1) spur_gear2d(pitch, teeth1, profile_shift=0, gear_spin=-90);
//   right(mr2) spur_gear2d(pitch, teeth2, gear_spin=90-180/teeth2);
// Example(2D): Manual Profile Shifting
//   pitch=5; teeth1=7; teeth2=24; ps1 = 0.5; ps2 = -0.2;
//   mr1 = mesh_radius(pitch, teeth1, profile_shift=ps1);
//   mr2 = mesh_radius(pitch, teeth2, profile_shift=ps2);
//   left(mr1) spur_gear2d(pitch, teeth1, profile_shift=ps1, gear_spin=-90);
//   right(mr2) spur_gear2d(pitch, teeth2, profile_shift=ps2, gear_spin=90-180/teeth2);

function mesh_radius(
    circ_pitch,
    teeth,
    helical=0,
    profile_shift,
    pressure_angle=20,
    diam_pitch,
    mod,
    pitch
) =
    let(
        circ_pitch = circular_pitch(pitch, mod, circ_pitch, diam_pitch),
        profile_shift = default(profile_shift, teeth>0? auto_profile_shift(teeth,pressure_angle) : 0),
        mod = circ_pitch / PI,
        pr = teeth>0? pitch_radius(circ_pitch, teeth, helical) : 0,
        r = pr + profile_shift * mod
    ) r;


// Function: auto_profile_shift()
// Synopsis: Returns the recommended profile shift for a gear.
// Topics: Gears, Parts
// See Also: worm(), worm_gear(), pitch_radius(), outer_radius()
// Usage:
//   x = auto_profile_shift(teeth, pressure_angle);
//   x = auto_profile_shift(teeth, min_teeth=);
// Description:
//   Calculates the recommended profile shift to avoid gear tooth undercutting.
// Arguments:
//   teeth = Total number of teeth in the gear.
//   pressure_angle = The pressure angle of the gear.
//   ---
//   min_teeth = If given, the minimum number of teeth on a gear that has acceptable undercut.

function auto_profile_shift(teeth, pressure_angle=20, min_teeth) =
    let(
        min_teeth = is_undef(min_teeth)
          ? 2 / pow(sin(pressure_angle),2)
          : min_teeth
    )
    teeth > floor(min_teeth)? 0 :
    1 - (teeth / min_teeth);



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
