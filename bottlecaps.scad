//////////////////////////////////////////////////////////////////////
// LibFile: bottlecaps.scad
//   Bottle caps and necks for PCO18XX standard plastic beverage bottles.
// Includes:
//   include <BOSL2/std.scad>
//   include <BOSL2/bottlecaps.scad>
//////////////////////////////////////////////////////////////////////


include <threading.scad>
include <knurling.scad>


// Section: PCO-1810 Bottle Threading


// Module: pco1810_neck()
// Usage:
//   pco1810_neck([wall])
// Description:
//   Creates an approximation of a standard PCO-1810 threaded beverage bottle neck.
// Arguments:
//   wall = Wall thickness in mm.
//   ---
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
// Extra Anchors:
//   "tamper-ring" = Centered at the top of the anti-tamper ring channel.
//   "support-ring" = Centered at the bottom of the support ring.
// Example:
//   pco1810_neck();
// Example: Standard Anchors
//   pco1810_neck() show_anchors(custom=false);
// Example: Custom Named Anchors
//   expose_anchors(0.3)
//       pco1810_neck()
//           show_anchors(std=false);
module pco1810_neck(wall=2, anchor="support-ring", spin=0, orient=UP)
{
    inner_d = 21.74;
    neck_d = 26.19;
    neck_h = 5.00;
    support_d = 33.00;
    support_width = 1.45;
    support_rad = 0.40;
    support_h = 21.00;
    support_ang = 16;
    tamper_ring_d = 27.97;
    tamper_ring_width = 0.50;
    tamper_ring_r = 1.60;
    tamper_base_d = 25.71;
    tamper_base_h = 14.10;
    threadbase_d = 24.51;
    thread_pitch = 3.18;
    thread_angle = 20;
    thread_od = 27.43;
    lip_d = 25.07;
    lip_h = 1.70;
    lip_leadin_r = 0.20;
    lip_recess_d = 24.94;
    lip_recess_h = 1.00;
    lip_roundover_r = 0.58;

    $fn = segs(support_d/2);
    h = support_h+neck_h;
    thread_h = (thread_od-threadbase_d)/2;
    anchors = [
        anchorpt("support-ring", [0,0,neck_h-h/2]),
        anchorpt("tamper-ring", [0,0,h/2-tamper_base_h])
    ];
    attachable(anchor,spin,orient, d1=neck_d, d2=lip_recess_d+2*lip_leadin_r, l=h, anchors=anchors) {
        down(h/2) {
            rotate_extrude(convexity=10) {
                polygon(turtle(
                    state=[inner_d/2,0], [
                        "untilx", neck_d/2,
                        "left", 90,
                        "move", neck_h - 1,
                        "arcright", 1, 90,
                        "untilx", support_d/2-support_rad,
                        "arcleft", support_rad, 90,
                        "move", support_width,
                        "arcleft", support_rad, 90-support_ang,
                        "untilx", tamper_base_d/2,
                        "right", 90-support_ang,
                        "untily", h-tamper_base_h,   // Tamper ring holder base.
                        "right", 90,
                        "untilx", tamper_ring_d/2,
                        "left", 90,
                        "move", tamper_ring_width,
                        "arcleft", tamper_ring_r, 90,
                        "untilx", threadbase_d/2,
                        "right", 90,
                        "untily", h-lip_h-lip_leadin_r,  // Lip base.
                        "arcright", lip_leadin_r, 90,
                        "untilx", lip_d/2,
                        "left", 90,
                        "untily", h-lip_recess_h,
                        "left", 90,
                        "untilx", lip_recess_d/2,
                        "right", 90,
                        "untily", h-lip_roundover_r,
                        "arcleft", lip_roundover_r, 90,
                        "untilx", inner_d/2
                    ]
                ));
            }
            up(h-lip_h) {
                bottom_half() {
                    difference() {
                        thread_helix(
                            d=threadbase_d-0.1,
                            pitch=thread_pitch,
                            thread_depth=thread_h+0.1,
                            thread_angle=thread_angle,
                            twist=810,
                            higbee=thread_h*2,
                            anchor=TOP
                        );
                        zrot_copies(rots=[90,270]) {
                            zrot_copies(rots=[-28,28], r=threadbase_d/2) {
                                prismoid([20,1.82], [20,1.82+2*sin(29)*thread_h], h=thread_h+0.1, anchor=BOT, orient=RIGHT);
                            }
                        }
                    }
                }
            }
        }
        children();
    }
}

function  pco1810_neck(wall=2, anchor="support-ring", spin=0, orient=UP) =
    no_function("pco1810_neck");


// Module: pco1810_cap()
// Usage:
//   pco1810_cap([wall], [texture]);
// Description:
//   Creates a basic cap for a PCO1810 threaded beverage bottle.
// Arguments:
//   wall = Wall thickness in mm.
//   texture = The surface texture of the cap.  Valid values are "none", "knurled", or "ribbed".  Default: "none"
//   ---
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
// Extra Anchors:
//   "inside-top" = Centered on the inside top of the cap.
// Examples:
//   pco1810_cap();
//   pco1810_cap(texture="knurled");
//   pco1810_cap(texture="ribbed");
// Example: Standard Anchors
//   pco1810_cap(texture="ribbed") show_anchors(custom=false);
// Example: Custom Named Anchors
//   expose_anchors(0.3)
//       pco1810_cap(texture="ribbed")
//           show_anchors(std=false);
module pco1810_cap(wall=2, texture="none", anchor=BOTTOM, spin=0, orient=UP)
{
    cap_id = 28.58;
    tamper_ring_h = 14.10;
    thread_pitch = 3.18;
    thread_angle = 20;
    thread_od = cap_id;
    thread_depth = 1.6;

    $fn = segs(33/2);
    w = cap_id + 2*wall;
    h = tamper_ring_h + wall;
    anchors = [
        anchorpt("inside-top", [0,0,-(h/2-wall)])
    ];
    attachable(anchor,spin,orient, d=w, l=h, anchors=anchors) {
        down(h/2) zrot(45) {
            difference() {
                union() {
                    if (texture == "knurled") {
                        knurled_cylinder(d=w, helix=45, l=tamper_ring_h+wall, anchor=BOTTOM);
                        cyl(d=w-1.5, l=tamper_ring_h+wall, anchor=BOTTOM);
                    } else if (texture == "ribbed") {
                        zrot_copies(n=30, r=(w-1)/2) {
                            cube([1, 1, tamper_ring_h+wall], anchor=BOTTOM);
                        }
                        cyl(d=w-1, l=tamper_ring_h+wall, anchor=BOTTOM);
                    } else {
                        cyl(d=w, l=tamper_ring_h+wall, anchor=BOTTOM);
                    }
                }
                up(wall) cyl(d=cap_id, h=tamper_ring_h+wall, anchor=BOTTOM);
            }
            up(wall+2) thread_helix(d=thread_od-thread_depth*2, pitch=thread_pitch, thread_depth=thread_depth, thread_angle=thread_angle, twist=810, higbee=thread_depth, internal=true, anchor=BOTTOM);
        }
        children();
    }
}

function pco1810_cap(wall=2, texture="none", anchor=BOTTOM, spin=0, orient=UP) =
    no_function("pco1810_cap");



// Section: PCO-1881 Bottle Threading


// Module: pco1881_neck()
// Usage:
//   pco1881_neck([wall])
// Description:
//   Creates an approximation of a standard PCO-1881 threaded beverage bottle neck.
// Arguments:
//   wall = Wall thickness in mm.
//   ---
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
// Extra Anchors:
//   "tamper-ring" = Centered at the top of the anti-tamper ring channel.
//   "support-ring" = Centered at the bottom of the support ring.
// Example:
//   pco1881_neck();
// Example:
//   pco1881_neck() show_anchors(custom=false);
// Example:
//   expose_anchors(0.3)
//       pco1881_neck()
//           show_anchors(std=false);
module pco1881_neck(wall=2, anchor="support-ring", spin=0, orient=UP)
{
    inner_d = 21.74;
    neck_d = 26.19;
    neck_h = 5.00;
    support_d = 33.00;
    support_width = 0.58;
    support_rad = 0.30;
    support_h = 17.00;
    support_ang = 15;
    tamper_ring_d = 28.00;
    tamper_ring_width = 0.30;
    tamper_ring_ang = 45;
    tamper_base_d = 25.71;
    tamper_base_h = 11.20;
    tamper_divot_r = 1.08;
    threadbase_d = 24.20;
    thread_pitch = 2.70;
    thread_angle = 15;
    thread_od = 27.4;
    lip_d = 25.07;
    lip_h = 1.70;
    lip_leadin_r = 0.30;
    lip_recess_d = 24.94;
    lip_recess_h = 1.00;
    lip_roundover_r = 0.58;

    $fn = segs(support_d/2);
    h = support_h+neck_h;
    thread_h = (thread_od-threadbase_d)/2;
    anchors = [
        anchorpt("support-ring", [0,0,neck_h-h/2]),
        anchorpt("tamper-ring", [0,0,h/2-tamper_base_h])
    ];
    attachable(anchor,spin,orient, d1=neck_d, d2=lip_recess_d+2*lip_leadin_r, l=h, anchors=anchors) {
        down(h/2) {
            rotate_extrude(convexity=10) {
                polygon(turtle(
                    state=[inner_d/2,0], [
                        "untilx", neck_d/2,
                        "left", 90,
                        "move", neck_h - 1,
                        "arcright", 1, 90,
                        "untilx", support_d/2-support_rad,
                        "arcleft", support_rad, 90,
                        "move", support_width,
                        "arcleft", support_rad, 90-support_ang,
                        "untilx", tamper_base_d/2,
                        "arcright", tamper_divot_r, 180-support_ang*2,
                        "left", 90-support_ang,
                        "untily", h-tamper_base_h,   // Tamper ring holder base.
                        "right", 90,
                        "untilx", tamper_ring_d/2,
                        "left", 90,
                        "move", tamper_ring_width,
                        "left", tamper_ring_ang,
                        "untilx", threadbase_d/2,
                        "right", tamper_ring_ang,
                        "untily", h-lip_h-lip_leadin_r,  // Lip base.
                        "arcright", lip_leadin_r, 90,
                        "untilx", lip_d/2,
                        "left", 90,
                        "untily", h-lip_recess_h,
                        "left", 90,
                        "untilx", lip_recess_d/2,
                        "right", 90,
                        "untily", h-lip_roundover_r,
                        "arcleft", lip_roundover_r, 90,
                        "untilx", inner_d/2
                    ]
                ));
            }
            up(h-lip_h) {
                difference() {
                    thread_helix(
                        d=threadbase_d-0.1,
                        pitch=thread_pitch,
                        thread_depth=thread_h+0.1,
                        thread_angle=thread_angle,
                        twist=650,
                        higbee=thread_h*2,
                        anchor=TOP
                    );
                    zrot_copies(rots=[90,270]) {
                        zrot_copies(rots=[-28,28], r=threadbase_d/2) {
                            prismoid([20,1.82], [20,1.82+2*sin(29)*thread_h], h=thread_h+0.1, anchor=BOT, orient=RIGHT);
                        }
                    }
                }
            }
        }
        children();
    }
}

function pco1881_neck(wall=2, anchor="support-ring", spin=0, orient=UP) =
    no_function("pco1881_neck");


// Module: pco1881_cap()
// Usage:
//   pco1881_cap(wall, [texture]);
// Description:
//   Creates a basic cap for a PCO1881 threaded beverage bottle.
// Arguments:
//   wall = Wall thickness in mm.
//   texture = The surface texture of the cap.  Valid values are "none", "knurled", or "ribbed".  Default: "none"
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
// Extra Anchors:
//   "inside-top" = Centered on the inside top of the cap.
// Examples:
//   pco1881_cap();
//   pco1881_cap(texture="knurled");
//   pco1881_cap(texture="ribbed");
// Example: Standard Anchors
//   pco1881_cap(texture="ribbed") show_anchors(custom=false);
// Example: Custom Named Anchors
//   expose_anchors(0.5)
//       pco1881_cap(texture="ribbed")
//           show_anchors(std=false);
module pco1881_cap(wall=2, texture="none", anchor=BOTTOM, spin=0, orient=UP)
{
    $fn = segs(33/2);
    w = 28.58 + 2*wall;
    h = 11.2 + wall;
    anchors = [
        anchorpt("inside-top", [0,0,-(h/2-wall)])
    ];
    attachable(anchor,spin,orient, d=w, l=h, anchors=anchors) {
        down(h/2) zrot(45) {
            difference() {
                union() {
                    if (texture == "knurled") {
                        knurled_cylinder(d=w, helix=45, l=11.2+wall, anchor=BOTTOM);
                        cyl(d=w-1.5, l=11.2+wall, anchor=BOTTOM);
                    } else if (texture == "ribbed") {
                        zrot_copies(n=30, r=(w-1)/2) {
                            cube([1, 1, 11.2+wall], anchor=BOTTOM);
                        }
                        cyl(d=w-1, l=11.2+wall, anchor=BOTTOM);
                    } else {
                        cyl(d=w, l=11.2+wall, anchor=BOTTOM);
                    }
                }
                up(wall) cyl(d=28.58, h=11.2+wall, anchor=BOTTOM);
            }
            up(wall+2) thread_helix(d=25.5, pitch=2.7, thread_depth=1.6, thread_angle=15, twist=650, higbee=1.6, internal=true, anchor=BOTTOM);
        }
        children();
    }
}

function pco1881_cap(wall=2, texture="none", anchor=BOTTOM, spin=0, orient=UP) =
    no_function("pco1881_cap");



// Section: Generic Bottle Connectors

// Module: generic_bottle_neck()
// Usage:
//   generic_bottle_neck([wall], ...)
// Description:
//   Creates a bottle neck given specifications.
// Arguments:
//   wall = distance between ID and any wall that may be below the support
//   neck_d = Outer diameter of neck without threads
//   id = Inner diameter of neck
//   thread_od = Outer diameter of thread
//   height = Height of neck above support
//   support_d = Outer diameter of support ring.  Set to 0 for no support.
//   pitch = Thread pitch
//   round_supp = True to round the lower edge of the support ring
//   ---
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
// Extra Anchors:
//   "support-ring" = Centered at the bottom of the support ring.
// Example:
//   generic_bottle_neck();
module generic_bottle_neck(
    wall,
    neck_d = 25,
    id = 21.4,
    thread_od = 27.2,
    height = 17,
    support_d = 33.0,
    pitch = 3.2,
    round_supp = false,
    anchor = "support-ring",
    spin = 0,
    orient = UP
) {
    inner_d = id;
    neck_d = neck_d;
    supp_d = max(neck_d, support_d);
    thread_pitch = pitch;
    thread_angle = 15;

    diamMagMult = neck_d / 26.19;
    heightMagMult = height / 17.00;

    sup_r = 0.30 * (heightMagMult > 1 ? heightMagMult : 1);
    support_r = floor(((supp_d == neck_d) ? sup_r : min(sup_r, (supp_d - neck_d) / 2)) * 5000) / 10000;
    support_rad = (wall == undef || !round_supp) ? support_r :
        min(support_r, floor((supp_d - (inner_d + 2 * wall)) * 5000) / 10000);
        //Too small of a radius will cause errors with the arc, this limits granularity to .0001mm
    support_width = 1 * (heightMagMult > 1 ? heightMagMult : 1) * sign(support_d);
    roundover = 0.58 * diamMagMult;
    lip_roundover_r = (roundover > (neck_d - inner_d) / 2) ? 0 : roundover;
    h = height + support_width;
    threadbase_d = neck_d - 0.8 * diamMagMult;

    $fn = segs(33 / 2);
    thread_h = (thread_od - threadbase_d) / 2;
    anchors = [
        anchorpt("support-ring", [0, 0, 0 - h / 2])
    ];
    attachable(anchor, spin, orient, d1 = neck_d, d2 = 0, l = h, anchors = anchors) {
        down(h / 2) {
            rotate_extrude(convexity = 10) {
                polygon(turtle(
                    state = [inner_d / 2, 0], (supp_d != neck_d) ? [
                        "untilx", supp_d / 2 - ((round_supp) ? support_rad : 0),
                        "arcleft", ((round_supp) ? support_rad : 0), 90,
                        "untily", support_width - support_rad,
                        "arcleft", support_rad, 90,
                        "untilx", neck_d / 2,
                        "right", 90,
                        "untily", h - lip_roundover_r,
                        "arcleft", lip_roundover_r, 90,
                        "untilx", inner_d / 2
                    ] : [
                        "untilx", supp_d / 2 - ((round_supp) ? support_rad : 0),
                        "arcleft", ((round_supp) ? support_rad : 0), 90,
                        "untily", h - lip_roundover_r,
                        "arcleft", lip_roundover_r, 90,
                        "untilx", inner_d / 2
                    ]
                ));
            }
            up(h - pitch / 2 - lip_roundover_r) {
                difference() {
                    thread_helix(
                        d = threadbase_d - 0.1 * diamMagMult,
                        pitch = thread_pitch,
                        thread_depth = thread_h + 0.1 * diamMagMult,
                        thread_angle = thread_angle,
                        twist = 360 * (height - pitch - lip_roundover_r) * .6167 / pitch,
                        higbee = thread_h * 2,
                        anchor = TOP
                    );
                    zrot_copies(rots = [90, 270]) {
                        zrot_copies(rots = [-28, 28], r = threadbase_d / 2) {
                            prismoid(
                                [20 * heightMagMult, 1.82 * diamMagMult],
                                [20 * heightMagMult, 1.82 * diamMagMult * .6 + 2 * sin(29) * thread_h],
                                h = thread_h + 0.1 * diamMagMult,
                                anchor = BOT,
                                orient = RIGHT
                            );
                        }
                    }
                }
            }
        }
        children();
    }
}

function generic_bottle_neck(
    neck_d,
    id,
    thread_od,
    height,
    support_d,
    pitch,
    round_supp,
    wall,
    anchor, spin, orient
) = no_function("generic_bottle_neck");


// Module: generic_bottle_cap()
// Usage:
//   generic_bottle_cap(wall, [texture], ...);
// Description:
//   Creates a basic threaded cap given specifications.
// Arguments:
//   wall = Wall thickness in mm.
//   texture = The surface texture of the cap.  Valid values are "none", "knurled", or "ribbed".  Default: "none"
//   ---
//   height = Interior height of the cap in mm.
//   thread_od = Outer diameter of the threads in mm.
//   tolerance = Extra space to add to the outer diameter of threads and neck in mm.  Applied to radius.
//   neck_od = Outer diameter of neck in mm.
//   thread_angle = Angle of taper on threads.
//   pitch = Thread pitch in mm.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
// Extra Anchors:
//   "inside-top" = Centered on the inside top of the cap.
// Examples:
//   generic_bottle_cap();
//   generic_bottle_cap(texture="knurled");
//   generic_bottle_cap(texture="ribbed");
module generic_bottle_cap(
    wall = 2,
    texture = "none",
    height = 11.2,
    thread_od = 28.58,
    tolerance = .2,
    neck_od = 25.5,
    thread_angle = 15,
    pitch = 4,
    anchor = BOTTOM,
    spin = 0,
    orient = UP
) {
    $fn = segs(33 / 2);
    threadOuterDTol = thread_od + 2 * tolerance;
    w = threadOuterDTol + 2 * wall;
    h = height + wall;
    neckOuterDTol = neck_od + 2 * tolerance;
    threadDepth = (thread_od - neck_od) / 2 + .8;

    diamMagMult = (w > 32.58) ? w / 32.58 : 1;
    heightMagMult = (height > 11.2) ? height / 11.2 : 1;

    anchors = [
        anchorpt("inside-top", [0, 0, -(h / 2 - wall)])
    ];
    attachable(anchor, spin, orient, d = w, l = h, anchors = anchors) {
        down(h / 2) {
            difference() {
                union() {
                    // For the knurled and ribbed caps the PCO caps in BOSL2 cut into the wall
                    // thickness so the wall+texture are the specified wall thickness.  That
                    // seems wrong so this does specified thickness+texture
                    if (texture == "knurled") {
                        knurled_cylinder(d = w + 1.5 * diamMagMult, helix = 45, l = h, anchor = BOTTOM);
                        cyl(d = w, l = h, anchor = BOTTOM);
                    } else if (texture == "ribbed") {
                        zrot_copies(n = 30, r = (w + .2 * diamMagMult) / 2) {
                            cube([1 * diamMagMult, 1 * diamMagMult, h], anchor = BOTTOM);
                        }
                        cyl(d = w, l = h, anchor = BOTTOM);
                    } else {
                        cyl(d = w, l = h, anchor = BOTTOM);
                    }
                }
                up(wall) cyl(d = threadOuterDTol, h = h, anchor = BOTTOM);
            }
            difference(){
                up(wall + pitch / 2) {
                    thread_helix(d = neckOuterDTol, pitch = pitch, thread_depth = threadDepth, thread_angle = thread_angle, twist = 360 * ((height - pitch) / pitch), higbee = threadDepth, internal = true, anchor = BOTTOM);
                }
            }
        }
        children();
    }
}

function generic_bottle_cap(
    wall, texture, height,
    thread_od, tolerance,
    neck_od, thread_angle, pitch,
    anchor, spin, orient
) = no_function("generic_bottle_cap");


// Module: bottle_adapter_neck_to_cap()
// Usage:
//   bottle_adapter_neck_to_cap(wall, [texture]);
// Description:
//   Creates a threaded neck to cap adapter
// Arguments:
//   wall = Thickness of wall between neck and cap when d=0.  Leave undefined to have the outside of the tube go from the OD of the neck support ring to the OD of the cap.  Default: undef
//   texture = The surface texture of the cap.  Valid values are "none", "knurled", or "ribbed".  Default: "none"
//   cap_wall = Wall thickness of the cap in mm.
//   cap_h = Interior height of the cap in mm.
//   cap_thread_od = Outer diameter of cap threads in mm.
//   tolerance = Extra space to add to the outer diameter of threads and neck in mm.  Applied to radius.
//   cap_neck_od = Inner diameter of the cap threads.
//   cap_neck_id = Inner diameter of the hole through the cap.
//   cap_thread_taper = Angle of taper on threads.
//   cap_thread_pitch = Thread pitch in mm
//   neck_d = Outer diameter of neck w/o threads
//   neck_id = Inner diameter of neck
//   neck_thread_od = 27.2
//   neck_h = Height of neck down to support ring
//   neck_thread_pitch = Thread pitch in mm.
//   neck_support_od = Outer diameter of neck support ring.  Leave undefined to set equal to OD of cap.  Set to 0 for no ring.  Default: undef
//   d = Distance between bottom of neck and top of cap
//   taper_lead_in = Length to leave straight before tapering on tube between neck and cap if exists.
// Examples:
//   bottle_adapter_neck_to_cap();
module bottle_adapter_neck_to_cap(
    wall,
    texture = "none",
    cap_wall = 2,
    cap_h = 11.2,
    cap_thread_od = 28.58,
    tolerance = .2,
    cap_neck_od = 25.5,
    cap_neck_id,
    cap_thread_taper = 15,
    cap_thread_pitch = 4,
    neck_d = 25,
    neck_id = 21.4,
    neck_thread_od = 27.2,
    neck_h = 17,
    neck_thread_pitch = 3.2,
    neck_support_od,
    d = 0,
    taper_lead_in = 0
) {
    neck_support_od = (neck_support_od == undef || (d == 0 && neck_support_od < cap_thread_od + 2 * tolerance)) ? cap_thread_od + 2 * (cap_wall + tolerance) : neck_support_od;
    cap_neck_id = (cap_neck_id == undef) ? neck_id : cap_neck_id;
    wall = (wall == undef) ? neck_support_od + neck_d + cap_thread_od + neck_id : wall;

    $fn = segs(33 / 2);
    wallt1 = min(wall, (max(neck_support_od, neck_d) - neck_id) / 2);
    wallt2 = min(wall, (cap_thread_od + 2 * (cap_wall + tolerance) - cap_neck_id) / 2);

    difference(){
        union(){
            up(d / 2) {
                generic_bottle_neck(neck_d = neck_d,
                    id = neck_id,
                    thread_od = neck_thread_od,
                    height = neck_h,
                    support_d = neck_support_od,
                    pitch = neck_thread_pitch,
                    round_supp = ((wallt1 < (neck_support_od - neck_id) / 2) && (d > 0 || neck_support_od > (cap_thread_od + 2 * (cap_wall + tolerance)))),
                    wall = (d > 0) ? wallt1 : min(wallt1, ((cap_thread_od + 2 * (cap_wall + tolerance) - neck_id) / 2))
                );
            }
            if (d != 0) {
                rotate_extrude(){
                    polygon(points = [
                        [0, d / 2],
                        [neck_id / 2 + wallt1, d / 2],
                        [neck_id / 2 + wallt1, d / 2 - taper_lead_in],
                        [cap_neck_id / 2 + wallt2, taper_lead_in - d / 2],
                        [cap_neck_id / 2 + wallt2, -d / 2],
                        [0, -d / 2]
                    ]);
                }
            }
            down(d / 2){
                generic_bottle_cap(wall = cap_wall,
                    texture = texture,
                    height = cap_h,
                    thread_od = cap_thread_od,
                    tolerance = tolerance,
                    neck_od = cap_neck_od,
                    thread_angle = cap_thread_taper,
                    orient = DOWN,
                    pitch = cap_thread_pitch
                );
            }
        }
        rotate_extrude() {
            polygon(points = [
                [0, d / 2 + 0.1],
                [neck_id / 2, d / 2],
                [neck_id / 2, d / 2 - taper_lead_in],
                [cap_neck_id / 2, taper_lead_in - d / 2],
                [cap_neck_id / 2, -d / 2 - cap_wall],
                [0, -d / 2 - cap_wall - 0.1]
            ]);
        }
    }
}

function bottle_adapter_neck_to_cap(
    wall, texture, cap_wall, cap_h, cap_thread_od,
    tolerance, cap_neck_od, cap_neck_id, cap_thread_taper,
    cap_thread_pitch, neck_d, neck_id, neck_thread_od,
    neck_h, neck_thread_pitch, neck_support_od, d, taper_lead_in
) = no_fuction("bottle_adapter_neck_to_cap");


// Module: bottle_adapter_cap_to_cap()
// Usage:
//   bottle_adapter_cap_to_cap(wall, [texture]);
// Description:
//   Creates a threaded cap to cap adapter.
// Arguments:
//   wall = Wall thickness in mm.
//   texture = The surface texture of the cap.  Valid values are "none", "knurled", or "ribbed".  Default: "none"
//   cap_h1 = Interior height of top cap.
//   cap_thread_od1 = Outer diameter of threads on top cap.
//   tolerance = Extra space to add to the outer diameter of threads and neck in mm.  Applied to radius.
//   cap_neck_od1 = Inner diameter of threads on top cap.
//   cap_thread_pitch1 = Thread pitch of top cap in mm.
//   cap_h2 = Interior height of bottom cap.  Leave undefined to duplicate cap_h1.
//   cap_thread_od2 = Outer diameter of threads on bottom cap.  Leave undefined to duplicate capThread1.
//   cap_neck_od2 = Inner diameter of threads on top cap.  Leave undefined to duplicate cap_neck_od1.
//   cap_thread_pitch2 = Thread pitch of bottom cap in mm.  Leave undefinced to duplicate cap_thread_pitch1.
//   d = Distance between caps.
//   neck_id1 = Inner diameter of cutout in top cap.
//   neck_id2 = Inner diameter of cutout in bottom cap.
//   taper_lead_in = Length to leave straight before tapering on tube between caps if exists.
// Examples:
//   bottle_adapter_cap_to_cap();
module bottle_adapter_cap_to_cap(
    wall = 2,
    texture = "none",
    cap_h1 = 11.2,
    cap_thread_od1 = 28.58,
    tolerance = .2,
    cap_neck_od1 = 25.5,
    cap_thread_pitch1 = 4,
    cap_h2,
    cap_thread_od2,
    cap_neck_od2,
    cap_thread_pitch2,
    d = 0,
    neck_id1, neck_id2,
    taper_lead_in = 0
) {
    cap_h2 = (cap_h2 == undef) ? cap_h1 : cap_h2;
    cap_thread_od2 = (cap_thread_od2 == undef) ? cap_thread_od1 : cap_thread_od2;
    cap_neck_od2 = (cap_neck_od2 == undef) ? cap_neck_od1 : cap_neck_od2;
    cap_thread_pitch2 = (cap_thread_pitch2 == undef) ? cap_thread_pitch1 : cap_thread_pitch2;
    neck_id2 = (neck_id2 == undef && neck_id1 != undef) ? neck_id1 : neck_id2;
    taper_lead_in = (d >= taper_lead_in * 2) ? taper_lead_in : d / 2;


    $fn = segs(33 / 2);

    difference(){
        union(){
            up(d / 2){
                generic_bottle_cap(
                    orient = UP,
                    wall = wall,
                    texture = texture,
                    height = cap_h1,
                    thread_od = cap_thread_od1,
                    tolerance = tolerance,
                    neck_od = cap_neck_od1,
                    pitch = cap_thread_pitch1
                );
            }
            if (d != 0) {
                rotate_extrude() {
                    polygon(points = [
                        [0, d / 2],
                        [cap_thread_od1 / 2 + (wall + tolerance), d / 2],
                        [cap_thread_od1 / 2 + (wall + tolerance), d / 2 - taper_lead_in],
                        [cap_thread_od2 / 2 + (wall + tolerance), taper_lead_in - d / 2],
                        [cap_thread_od2 / 2 + (wall + tolerance), -d / 2],
                        [0, -d / 2]
                    ]);
                }
            }
            down(d / 2){
                generic_bottle_cap(
                    orient = DOWN,
                    wall = wall,
                    texture = texture,
                    height = cap_h2,
                    thread_od = cap_thread_od2,
                    tolerance = tolerance,
                    neck_od = cap_neck_od2,
                    pitch = cap_thread_pitch2
                );
            }
        }
        if (neck_id1 != undef || neck_id2 != undef) {
            neck_id1 = (neck_id1 == undef) ? neck_id2 : neck_id1;
            neck_id2 = (neck_id2 == undef) ? neck_id1 : neck_id2;

            rotate_extrude() {
                polygon(points = [
                    [0, wall + d / 2 + 0.1],
                    [neck_id1 / 2, wall + d / 2],
                    [neck_id1 / 2, wall + d / 2 - taper_lead_in],
                    [neck_id2 / 2, taper_lead_in - d / 2 - wall],
                    [neck_id2 / 2, -d / 2 - wall],
                    [0, -d / 2 - wall - 0.1]
                ]);
            }
        }
    }
}

function bottle_adapter_cap_to_cap(
    wall, texture, cap_h1, cap_thread_od1, tolerance,
    cap_neck_od1, cap_thread_pitch1, cap_h2, cap_thread_od2,
    cap_neck_od2, cap_thread_pitch2, d, neck_id1, neck_id2, taper_lead_in
) = no_function("bottle_adapter_cap_to_cap");


// Module: bottle_adapter_neck_to_neck()
// Usage:
//   bottle_adapter_neck_to_neck();
// Description:
//   Creates a threaded neck to neck adapter.
// Arguments:
//   d = Distance between bottoms of necks
//   neck_od1 = Outer diameter of top neck w/o threads
//   neck_id1 = Inner diameter of top neck
//   thread_od1 = Outer diameter of threads on top neck
//   height1 =  Height of top neck above support ring.
//   support_od1 = Outer diameter of the support ring on the top neck.  Set to 0 for no ring.
//   thread_pitch1 = Thread pitch of top neck.
//   neck_od2 = Outer diameter of bottom neck w/o threads.  Leave undefined to duplicate neck_od1
//   neck_id2 = Inner diameter of bottom neck.  Leave undefined to duplicate neck_id1
//   thread_od2 = Outer diameter of threads on bottom neck.  Leave undefined to duplicate thread_od1
//   height2 = Height of bottom neck above support ring.  Leave undefined to duplicate height1
//   support_od2 = Outer diameter of the support ring on bottom neck.  Set to 0 for no ring.  Leave undefined to duplicate support_od1 
//   pitch2 = Thread pitch of bottom neck.  Leave undefined to duplicate thread_pitch1
//   taper_lead_in = Length to leave straight before tapering on tube between necks if exists.
//   wall = Thickness of tube wall between necks.  Leave undefined to match outer diameters with the neckODs/supportODs.  
// Examples:
//   bottle_adapter_neck_to_neck();
module bottle_adapter_neck_to_neck(
    d = 0,
    neck_od1 = 25,
    neck_id1 = 21.4,
    thread_od1 = 27.2,
    height1 = 17,
    support_od1 = 33.0,
    thread_pitch1 = 3.2,
    neck_od2, neck_id2,
    thread_od2, height2,
    support_od2, pitch2,
    taper_lead_in = 0, wall
) {
    neck_od2 = (neck_od2 == undef) ? neck_od1 : neck_od2;
    neck_id2 = (neck_id2 == undef) ? neck_id1 : neck_id2;
    thread_od2 = (thread_od2 == undef) ? thread_od1 : thread_od2;
    height2 = (height2 == undef) ? height1 : height2;
    support_od2 = (support_od2 == undef) ? support_od1 : support_od2;
    pitch2 = (pitch2 == undef) ? thread_pitch1 : pitch2;
    wall = (wall == undef) ? support_od1 + support_od2 + neck_id1 + neck_id2 : wall;

    supprtOD2 = (d == 0 && support_od2 != 0) ? max(neck_od1, support_od2) : support_od2;
    supprtOD1 = (d == 0 && support_od1 != 0) ? max(neck_od2, support_od1) : support_od1;

    $fn = segs(33 / 2);
    wallt1 = min(wall, (max(supprtOD1, neck_od1) - neck_id1) / 2);
    wallt2 = min(wall, (max(supprtOD2, neck_od2) - neck_id2) / 2);

    taper_lead_in = (d >= taper_lead_in * 2) ? taper_lead_in : d / 2;

    difference(){
        union(){
            up(d / 2){
                generic_bottle_neck(orient = UP,
                    neck_d = neck_od1,
                    id = neck_id1,
                    thread_od = thread_od1,
                    height = height1,
                    support_d = supprtOD1,
                    pitch = thread_pitch1,
                    round_supp = ((wallt1 < (supprtOD1 - neck_id1) / 2) || (support_od1 > max(neck_od2, support_od2) && d == 0)),
                    wall = (d > 0) ? wallt1 : min(wallt1, ((max(neck_od2, support_od2)) - neck_id1) / 2)
                );
            }
            if (d != 0) {
                rotate_extrude() {
                    polygon(points = [
                        [0, d / 2],
                        [neck_id1 / 2 + wallt1, d / 2],
                        [neck_id1 / 2 + wallt1, d / 2 - taper_lead_in],
                        [neck_id2 / 2 + wallt2, taper_lead_in - d / 2],
                        [neck_id2 / 2 + wallt2, -d / 2],
                        [0, -d / 2]
                    ]);
                }
            }
            down(d / 2){
                generic_bottle_neck(orient = DOWN,
                    neck_d = neck_od2,
                    id = neck_id2,
                    thread_od = thread_od2,
                    height = height2,
                    support_d = supprtOD2,
                    pitch = pitch2,
                    round_supp = ((wallt2 < (supprtOD2 - neck_id2) / 2) || (support_od2 > max(neck_od1, support_od1) && d == 0)),
                    wall = (d > 0) ? wallt2 : min(wallt2, ((max(neck_od1, support_od1)) - neck_id2) / 2)
                );
            }
        }
        if (neck_id1 != undef || neck_id2 != undef) {
            neck_id1 = (neck_id1 == undef) ? neck_id2 : neck_id1;
            neck_id2 = (neck_id2 == undef) ? neck_id1 : neck_id2;

            rotate_extrude() {
                polygon(points = [
                    [0, d / 2],
                    [neck_id1 / 2, d / 2],
                    [neck_id1 / 2, d / 2 - taper_lead_in],
                    [neck_id2 / 2, taper_lead_in - d / 2],
                    [neck_id2 / 2, -d / 2],
                    [0, -d / 2]
                ]);
            }
        }
    }
}

function bottle_adapter_neck_to_neck(
    d, neck_od1, neck_id1, thread_od1, height1,
    support_od1, thread_pitch1, neck_od2, neck_id2,
    thread_od2, height2, support_od2,
    pitch2, taper_lead_in, wall
) = no_fuction("bottle_adapter_neck_to_neck");



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
