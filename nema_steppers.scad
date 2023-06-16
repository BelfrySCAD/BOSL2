//////////////////////////////////////////////////////////////////////
// LibFile: nema_steppers.scad
//   Mounting holes for NEMA motors, and simple motor models.
// Includes:
//   include <BOSL2/std.scad>
//   include <BOSL2/nema_steppers.scad>
// FileGroup: Parts
// FileSummary: NEMA motor mounts and stepper motor models.
//////////////////////////////////////////////////////////////////////


// Section: Motor Models


// Module: nema_stepper_motor()
// Synopsis: Creates a NEMA standard stepper motor model.
// SynTags: Geom
// Topics: Parts, Motors
// See Also: nema_stepper_motor(), nema_mount_mask()
// Usage:
//   nema_stepper_motor(size, h, shaft_len, [$slop=], ...) [ATTACHMENTS];
// Description:
//   Creates a model of a NEMA standard stepper motor.
// Arguments:
//   size = The NEMA standard size of the stepper motor.
//   h = Length of motor body.  Default: 24mm
//   shaft_len = Length of shaft protruding out the top of the stepper motor.  Default: 20mm
//   ---
//   details = If false, creates a very rough motor shape, suitable for using as a mask.  Default: true
//   atype = The attachment set type to use when anchoring.  Default: `"body"`
//   $slop = If details is false then increase size of the model by double this amount (for use as a mask)
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `TOP`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Anchor Types:
//   "shaft" = Anchor relative to the shaft.
//   "plinth" = Anchor relative to the plinth.
//   "body" = Anchor relative to the motor body.
//   "screws" = Anchor relative to the screw hole centers.  ie: TOP+RIGHT+FRONT is the center-top of the front-right screwhole.
// Examples:
//   nema_stepper_motor(size=8, h=24, shaft_len=15);
//   nema_stepper_motor(size=11, h=24, shaft_len=20);
//   nema_stepper_motor(size=17, h=40, shaft_len=30);
//   nema_stepper_motor(size=23, h=50, shaft_len=40);
//   nema_stepper_motor(size=23, h=50, shaft_len=40, details=false);
module nema_stepper_motor(size=17, h=24, shaft_len=20, details=true, atype="body", anchor=TOP, spin=0, orient=UP)
{
    info = nema_motor_info(size);
    motor_width   = info[0];
    plinth_height = info[1];
    plinth_diam   = info[2];
    screw_spacing = info[3];
    screw_size    = info[4];
    screw_depth   = info[5];
    shaft_diam    = info[6];
    geom = atype=="shaft"? attach_geom(r=shaft_diam/2, h=shaft_len-plinth_height, cp=[0,0,h/2+plinth_height/2+shaft_len/2]) :
        atype=="plinth"? attach_geom(r=plinth_diam/2, h=plinth_height, cp=[0,0,h/2+plinth_height/2]) :
        atype=="body"? attach_geom(size=[motor_width, motor_width, h]) :
        atype=="screws"? attach_geom(size=[screw_spacing, screw_spacing, screw_depth], cp=[0,0,h/2-screw_depth/2]) :
        assert(in_list(atype, ["shaft", "plinth", "body", "screws"]));
    attachable(anchor,spin,orient, geom=geom) {
        up(h/2) {
            if (details == false) {
                slop = get_slop();
                color([0.4, 0.4, 0.4]) 
                    cuboid(size=[motor_width+2*slop, motor_width+2*slop, h+slop], anchor=TOP);
                color([0.6, 0.6, 0.6])
                    cylinder(h=plinth_height+slop, d=plinth_diam+2*slop);
                color("silver")
                    cylinder(h=shaft_len+slop, d=shaft_diam+2*slop, $fn=max(12,segs(shaft_diam/2)));
            } else if (size < 23) {
                difference() {
                    color([0.4, 0.4, 0.4]) 
                        cuboid(size=[motor_width, motor_width, h], chamfer=size>=8? 2 : 0.5, edges="Z", anchor=TOP);
                    color("silver")
                        xcopies(screw_spacing)
                            ycopies(screw_spacing)
                                cyl(r=screw_size/2, h=screw_depth*2, $fn=max(12,segs(screw_size/2)));
                }
                color([0.6, 0.6, 0.6]) {
                    difference() {
                        cylinder(h=plinth_height, d=plinth_diam);
                        cyl(h=plinth_height*3, d=shaft_diam+0.75);
                    }
                }
                color("silver") cylinder(h=shaft_len, d=shaft_diam, $fn=max(12,segs(shaft_diam/2)));
            } else {
                difference() {
                    union() {
                        color([0.4, 0.4, 0.4])
                            cuboid([motor_width, motor_width, h], rounding=screw_size, edges="Z", anchor=TOP);
                        color([0.6, 0.6, 0.6]) {
                            difference() {
                                cylinder(h=plinth_height, d=plinth_diam);
                                cyl(h=plinth_height*3, d=shaft_diam+0.75);
                            }
                        }
                        color("silver")
                            cylinder(h=shaft_len, d=shaft_diam, $fn=max(12,segs(shaft_diam/2)));
                    }
                    color([0.4, 0.4, 0.4]) {
                        xcopies(screw_spacing) {
                            ycopies(screw_spacing) {
                                cyl(d=screw_size, h=screw_depth*3, $fn=max(12,segs(screw_size/2)));
                                down(screw_depth) cuboid([screw_size*2, screw_size*2, h], anchor=TOP);
                            }
                        }
                    }
                }
            }
        }
        children();
    }
}



// Section: Masking Modules


// Module: nema_mount_mask()
// Synopsis: Creates a standard NEMA mount holes mask.
// SynTags: Geom
// Topics: Parts, Motors
// See Also: nema_stepper_motor(), nema_mount_mask()
// Usage:
//   nema_mount_mask(size, depth, l, [$slop], ...);
// Description: Creates a mask to use when making standard NEMA stepper motor mounts.
// Arguments:
//   size = The standard NEMA motor size to make a mount for.
//   depth = The thickness of the mounting hole mask.  Default: 5
//   l = The length of the slots, for making an adjustable motor mount.  Default: 5
//   ---
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   $slop = The printer-specific slop value to make parts fit just right.
// Anchor Types:
//   "full" = Anchor relative the full mask.
//   "screws" = Anchor relative to the screw hole centers.  ie: TOP+RIGHT+FRONT is the center-top of the front-right screwhole.
// Examples:
//   nema_mount_mask(size=14, depth=5, l=5);
//   nema_mount_mask(size=17, depth=5, l=5);
//   nema_mount_mask(size=17, depth=5, l=0);
module nema_mount_mask(size, depth=5, l=5, atype="full", anchor=CENTER, spin=0, orient=UP)
{
    slop = get_slop();
    info = nema_motor_info(size);
    motor_width   = info[0];
    plinth_height = info[1];
    plinth_diam   = info[2] + slop;
    screw_spacing = info[3];
    screw_size    = info[4] + slop;
    screw_depth   = info[5];
    shaft_diam    = info[6];
    screwfn = quantup(max(8,segs(screw_size/2)),4);
    plinthfn = quantup(max(8,segs(plinth_diam/2)),4);
    s = atype=="full"? [screw_spacing+screw_size, screw_spacing+screw_size+l, depth] :
        atype=="screws"? [screw_spacing, screw_spacing, depth] :
        assert(in_list(atype, ["full", "screws"]));
    attachable(anchor,spin,orient, size=s) {
        union() {
            xcopies(screw_spacing) {
                ycopies(screw_spacing) {
                    if (l > 0) {
                        ycopies(l) cyl(h=depth, d=screw_size, $fn=screwfn);
                        cube([screw_size, l, depth], center=true);
                    } else {
                        cyl(h=depth, d=screw_size, $fn=screwfn);
                    }
                }
            }
            if (l > 0) {
                ycopies(l) cyl(h=depth, d=plinth_diam, $fn=plinthfn);
                cube([plinth_diam, l, depth], center=true);
            } else {
                cyl(h=depth, d=plinth_diam, $fn=plinthfn);
            }
        }
        children();
    }
}



// Section: Functions


// Function: nema_motor_info()
// Synopsis: Returns dimension info for a given NEMA motor size.
// Topics: Parts, Motors
// See Also: nema_stepper_motor(), nema_mount_mask()
// Usage:
//   info = nema_motor_info(size);
// Description:
//   Gets various dimension info for a NEMA stepper motor of a specific size.
//   Returns a list of scalar values, containing, in order:
//   - MOTOR_WIDTH: The full width and length of the motor.
//   - PLINTH_HEIGHT: The height of the circular plinth on the face of the motor.
//   - PLINTH_DIAM: The diameter of the circular plinth on the face of the motor.
//   - SCREW_SPACING: The spacing between screwhole centers in both X and Y axes.
//   - SCREW_SIZE: The diameter of the screws.
//   - SCREW_DEPTH: The depth of the screwholes.
//   - SHAFT_DIAM: The diameter of the motor shaft.
// Arguments:
//   size = The standard NEMA motor size.
function nema_motor_info(size) =
    let(
        info_arr = [
            [ 6, [ 14.0, 1.50, 11.0, 11.50, 1.6,  2.5,  4.00]],
            [ 8, [ 20.3, 1.50, 16.0, 15.40, 2.0,  2.5,  4.00]],
            [11, [ 28.2, 1.50, 22.0, 23.11, 2.6,  3.0,  5.00]],
            [14, [ 35.2, 2.00, 22.0, 26.00, 3.0,  4.5,  5.00]],
            [17, [ 42.3, 2.00, 22.0, 31.00, 3.0,  4.5,  5.00]],
            [23, [ 57.0, 1.60, 38.1, 47.00, 5.1,  4.8,  6.35]],
            [34, [ 86.0, 2.00, 73.0, 69.60, 6.5, 10.0, 14.00]],
            [42, [110.0, 1.50, 55.5, 88.90, 8.5, 12.7, 19.00]],
        ],
        found = [for(info=info_arr) if(info[0]==size) info[1]]
    )
    assert(found, "Unsupported NEMA size.")
    found[0];



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
