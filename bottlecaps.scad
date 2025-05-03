//////////////////////////////////////////////////////////////////////
// LibFile: bottlecaps.scad
//   Bottle caps and necks for PCO18XX standard plastic beverage bottles, and SPI standard bottle necks.  
// Includes:
//   include <BOSL2/std.scad>
//   include <BOSL2/bottlecaps.scad>
// FileGroup: Threaded Parts
// FileSummary: Standard bottle caps and necks.
//////////////////////////////////////////////////////////////////////


include <threading.scad>
include <structs.scad>
include <rounding.scad>

// Section: PCO-1810 Bottle Threading


// Module: pco1810_neck()
// Synopsis: Creates a neck for a PCO1810 standard bottle.
// SynTags: Geom
// Topics: Bottles, Threading
// See Also: pco1810_cap()
// Usage:
//   pco1810_neck([wall]) [ATTACHMENTS];
// Description:
//   Creates an approximation of a standard PCO-1810 threaded beverage bottle neck.
// Arguments:
//   wall = Wall thickness in mm.
//   ---
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Named Anchors:
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
    flank_angle = 20;
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
        named_anchor("support-ring", [0,0,neck_h-h/2]),
        named_anchor("tamper-ring", [0,0,h/2-tamper_base_h])
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
                            flank_angle=flank_angle,
                            turns=810/360,
                            lead_in=-thread_h*2,
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
// Synopsis: Creates a cap for a PCO1810 standard bottle.
// SynTags: Geom
// Topics: Bottles, Threading
// See Also: pco1810_neck()
// Usage:
//   pco1810_cap([h], [r|d], [wall], [texture]) [ATTACHMENTS];
// Description:
//   Creates a basic cap for a PCO1810 threaded beverage bottle.
// Arguments:
//   h = The height of the cap.
//   r = Outer radius of the cap.
//   d = Outer diameter of the cap.
//   wall = Wall thickness in mm.
//   texture = The surface texture of the cap.  Valid values are "none", "knurled", or "ribbed".  Default: "none"
//   ---
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Named Anchors:
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
module pco1810_cap(h, r, d, wall, texture="none", anchor=BOTTOM, spin=0, orient=UP)
{
    cap_id = 28.58;
    tamper_ring_h = 14.10;
    thread_pitch = 3.18;
    flank_angle = 20;
    thread_od = cap_id;
    thread_depth = 1.6;

    rr = get_radius(r=r, d=d, dflt=undef);
    wwall = default(u_sub(rr,cap_id/2), default(wall, 2));
    hh = default(h, tamper_ring_h + wwall);
    checks =
        assert(wwall >= 0, "wall can't be negative.")
        assert(hh >= tamper_ring_h, str("height can't be less than ", tamper_ring_h, "."));

    $fn = segs(33/2);
    w = cap_id + 2*wwall;
    anchors = [
        named_anchor("inside-top", [0,0,-(hh/2-wwall)])
    ];
    attachable(anchor,spin,orient, d=w, l=hh, anchors=anchors) {
        down(hh/2) zrot(45) {
            difference() {
                union() {
                    if (texture == "knurled") {
                        cyl(d=w, h=hh, texture="diamonds", tex_size=[3,3], style="concave", anchor=BOT);
                    } else if (texture == "ribbed") {
                        cyl(d=w, h=hh, texture="ribs", tex_size=[3,3], style="min_edge", anchor=BOT);
                    } else {
                        cyl(d=w, l=hh, anchor=BOTTOM);
                    }
                }
                up(hh-tamper_ring_h) cyl(d=cap_id, h=tamper_ring_h+wwall, anchor=BOTTOM);
            }
            up(hh-tamper_ring_h+2) thread_helix(d=thread_od-thread_depth*2, pitch=thread_pitch, thread_depth=thread_depth, flank_angle=flank_angle, turns=810/360, lead_in=-thread_depth, internal=true, anchor=BOTTOM);
        }
        children();
    }
}

function pco1810_cap(h, r, d, wall, texture="none", anchor=BOTTOM, spin=0, orient=UP) =
    no_function("pco1810_cap");



// Section: PCO-1881 Bottle Threading


// Module: pco1881_neck()
// Synopsis: Creates a neck for a PCO1881 standard bottle.
// SynTags: Geom
// Topics: Bottles, Threading
// See Also: pco1881_cap()
// Usage:
//   pco1881_neck([wall]) [ATTACHMENTS];
// Description:
//   Creates an approximation of a standard PCO-1881 threaded beverage bottle neck.
// Arguments:
//   wall = Wall thickness in mm.
//   ---
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Named Anchors:
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
    flank_angle = 15;
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
        named_anchor("support-ring", [0,0,neck_h-h/2]),
        named_anchor("tamper-ring", [0,0,h/2-tamper_base_h])
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
                        flank_angle=flank_angle,
                        turns=650/360,
                        lead_in=-thread_h*2,
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
// Synopsis: Creates a cap for a PCO1881 standard bottle.
// SynTags: Geom
// Topics: Bottles, Threading
// See Also: pco1881_neck()
// Usage:
//   pco1881_cap(wall, [texture]) [ATTACHMENTS];
// Description:
//   Creates a basic cap for a PCO1881 threaded beverage bottle.
// Arguments:
//   wall = Wall thickness in mm.
//   texture = The surface texture of the cap.  Valid values are "none", "knurled", or "ribbed".  Default: "none"
//   ---
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Named Anchors:
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
        named_anchor("inside-top", [0,0,-(h/2-wall)])
    ];
    attachable(anchor,spin,orient, d=w, l=h, anchors=anchors) {
        down(h/2) zrot(45) {
            difference() {
                union() {
                    if (texture == "knurled") {
                        cyl(d=w, h=11.2+wall, texture="diamonds", tex_size=[3,3], style="concave", anchor=BOT);
                    } else if (texture == "ribbed") {
                        cyl(d=w, h=11.2+wall, texture="ribs", tex_size=[3,3], style="min_edge", anchor=BOT);
                    } else {
                        cyl(d=w, l=11.2+wall, anchor=BOTTOM);
                    }
                }
                up(wall) cyl(d=28.58, h=11.2+wall, anchor=BOTTOM);
            }
            up(wall+2) thread_helix(d=25.5, pitch=2.7, thread_depth=1.6, flank_angle=15, turns=650/360, lead_in=-1.6, internal=true, anchor=BOTTOM);
        }
        children();
    }
}

function pco1881_cap(wall=2, texture="none", anchor=BOTTOM, spin=0, orient=UP) =
    no_function("pco1881_cap");



// Section: Generic Bottle Connectors

// Module: generic_bottle_neck()
// Synopsis: Creates a generic neck for a bottle.
// SynTags: Geom
// Topics: Bottles, Threading
// See Also: generic_bottle_cap()
// Usage:
//   generic_bottle_neck([wall], ...) [ATTACHMENTS];
// Description:
//   Creates a bottle neck given specifications.
// Arguments:
//   wall = distance between ID and any wall that may be below the support
//   ---
//   neck_d = Outer diameter of neck without threads
//   id = Inner diameter of neck
//   thread_od = Outer diameter of thread
//   height = Height of neck above support
//   support_d = Outer diameter of support ring.  Set to 0 for no support.
//   pitch = Thread pitch
//   round_supp = True to round the lower edge of the support ring
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Named Anchors:
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
    flank_angle = 15;

    diamMagMult = neck_d / 26.19;
    heightMagMult = height / 17.00;

    assert(all_nonnegative([support_d]),"support_d must be a nonnegative number");
    sup_r = 0.30 * (heightMagMult > 1 ? heightMagMult : 1);
    support_r = floor(((supp_d == neck_d) ? sup_r : min(sup_r, (supp_d - neck_d) / 2)) * 5000) / 10000;
    support_rad = (wall == undef || !round_supp) ? support_r :
        min(support_r, floor((supp_d - (inner_d + 2 * wall)) * 5000) / 10000);
        //Too small of a radius will cause errors with the arc, this limits granularity to .0001mm
    support_width = max(heightMagMult,1) * sign(support_d);
    roundover = 0.58 * diamMagMult;
    lip_roundover_r = (roundover > (neck_d - inner_d) / 2) ? 0 : roundover;
    h = height + support_width;
    threadbase_d = neck_d - 0.8 * diamMagMult;

    $fn = segs(33 / 2);
    thread_h = (thread_od - threadbase_d) / 2;
    anchors = [
        named_anchor("support-ring", [0, 0, 0 - h / 2])
    ];
    attachable(anchor, spin, orient, d = neck_d, l = h, anchors = anchors) {
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
                        flank_angle = flank_angle,
                        turns = (height - pitch - lip_roundover_r) * .6167 / pitch,
                        lead_in = -thread_h * 2,
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
// Synopsis: Creates a generic cap for a bottle.
// SynTags: Geom
// Topics: Bottles, Threading
// See Also: generic_bottle_neck(), sp_cap()
// Usage:
//   generic_bottle_cap(wall, [texture], ...) [ATTACHMENTS];
// Description:
//   Creates a basic threaded cap given specifications.  You must give exactly two of `thread_od`, `neck_od` and `thread_depth` to
//   specify the thread geometry.  Note that most glass bottles conform to the SPI standard and caps for them may be more easily produced using {{sp_cap()}}.
// Arguments:
//   wall = Wall thickness.  Default: 2
//   texture = The surface texture of the cap.  Valid values are "none", "knurled", or "ribbed".  Default: "none"
//   ---
//   height = Interior height of the cap
//   thread_od = Outer diameter of the threads
//   neck_od = Outer diameter of neck
//   thread_depth = Depth of the threads 
//   tolerance = Extra space to add to the outer diameter of threads and neck.  Applied to radius.  Default: 0.2
//   flank_angle = Angle of taper on threads.  Default: 15
//   pitch = Thread pitch.  Default: 4
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Named Anchors:
//   "inside-top" = Centered on the inside top of the cap.
// Examples:
//   generic_bottle_cap(thread_depth=2,neck_od=INCH,height=INCH/2);
//   generic_bottle_cap(texture="knurled",neck_od=25,thread_od=30,height=10);
//   generic_bottle_cap(texture="ribbed",thread_depth=3,thread_od=25,height=13);
module generic_bottle_cap(
    wall = 2,
    texture = "none",
    height,
    thread_depth,
    thread_od, 
    tolerance = .2,
    neck_od,
    flank_angle = 15,
    pitch = 4,
    anchor = BOTTOM,
    spin = 0,
    orient = UP
) {
    $fn = segs(33 / 2);
    dummy = assert(num_defined([thread_od,neck_od,thread_depth])==2, "Must define exactly two of thread_od, neck_od and thread_depth")
            assert(is_def(thread_depth) || (all_positive([neck_od,thread_od]) && thread_od>neck_od), "thread_od must be larger than neck_od")
            assert(is_undef(thread_depth) || all_positive([thread_depth,first_defined([neck_od,thread_od])]), "thread_depth, and neck_od/thread_od must be positive");
    thread_depth = !is_undef(thread_depth) ? thread_depth :  (thread_od - neck_od)/2;
    neck_od = !is_undef(neck_od) ? neck_od : thread_od-2*thread_depth;
    thread_od = !is_undef(thread_od) ? thread_od : neck_od+2*thread_depth;
    threadOuterDTol = thread_od + 2*tolerance;
    w = threadOuterDTol + 2 * wall;                               
    h = height + wall;
    neckOuterDTol = neck_od + 2 * tolerance;

    diamMagMult = (w > 32.58) ? w / 32.58 : 1;
    heightMagMult = (height > 11.2) ? height / 11.2 : 1;

    anchors = [
        named_anchor("inside-top", [0, 0, -(h / 2 - wall)])
    ];
    attachable(anchor, spin, orient, d = w, l = h, anchors = anchors) {
        down(h / 2) {
            difference() {
                union() {
                    // For the knurled and ribbed caps the PCO caps in BOSL2 cut into the wall
                    // thickness so the wall+texture are the specified wall thickness.  That
                    // seems wrong so this does specified thickness+texture
                    if (texture == "knurled") 
                        cyl(d=w + 1.5*diamMagMult, l=h, texture="diamonds", tex_size=[3,3], style="concave", anchor=BOT);
                    else if (texture == "ribbed") 
                        cyl(d=w + 1.5*diamMagMult, l=h, texture="ribs", tex_size=[3,3], style="min_edge", anchor=BOT);
                    else 
                        cyl(d = w, l = h, anchor = BOTTOM);
                }
                up(wall) cyl(d = threadOuterDTol, h = h, anchor = BOTTOM);
            }
            up(wall + pitch / 2) {
                thread_helix(d = neckOuterDTol+.02, pitch = pitch, thread_depth = thread_depth+.01, flank_angle = flank_angle,
                             turns = ((height - pitch) / pitch), lead_in = -thread_depth, internal = true, anchor = BOTTOM);
            }
        }
        children();
    }
}

function generic_bottle_cap(
    wall, texture, height,
    thread_od, tolerance,
    neck_od, flank_angle, pitch,
    anchor, spin, orient
) = no_function("generic_bottle_cap");


// Module: bottle_adapter_neck_to_cap()
// Synopsis: Creates a generic adaptor between a neck and a cap.
// SynTags: Geom
// Topics: Bottles, Threading
// See Also: bottle_adapter_neck_to_neck()
// Usage:
//   bottle_adapter_neck_to_cap(wall, [texture], ...) [ATTACHMENTS];
// Description:
//   Creates a threaded neck to cap adapter
// Arguments:
//   wall = Thickness of wall between neck and cap when d=0.  Leave undefined to have the outside of the tube go from the OD of the neck support ring to the OD of the cap.  Default: undef
//   texture = The surface texture of the cap.  Valid values are "none", "knurled", or "ribbed".  Default: "none"
//   cap_wall = Wall thickness of the cap in mm.
//   cap_h = Interior height of the cap in mm.
//   cap_thread_depth = Cap thread depth.  Default: 2.34
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
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Examples:
//   bottle_adapter_neck_to_cap();
module bottle_adapter_neck_to_cap(
    wall,
    texture = "none",
    cap_wall = 2,
    cap_h = 11.2,
    cap_thread_depth = 2.34,
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
    taper_lead_in = 0, anchor, spin,orient
) {
    cap_od = cap_neck_od + 2*(cap_thread_depth - 0.8) + 2 * tolerance;
    neck_support_od = (neck_support_od == undef || (d == 0 && neck_support_od < cap_od)) ? cap_od+2*cap_wall
                    : neck_support_od;
    cap_neck_id = default(cap_neck_id,neck_id);
    wall = default(wall, neck_support_od + neck_d + cap_od + neck_id - 2*tolerance);

    $fn = segs(33 / 2);
    wallt1 = min(wall, (max(neck_support_od, neck_d) - neck_id) / 2);
    wallt2 = min(wall, (cap_od + 2 * cap_wall - cap_neck_id) / 2);

    top_h = neck_h + max(1,neck_h/17)*sign(neck_support_od);
    bot_h = cap_h + cap_wall;
    attachable(anchor=anchor,orient=orient,spin=spin, r=max([neck_id/2+wallt1, cap_neck_id/2+wallt2, neck_support_od/2]), h=top_h+bot_h+d) {      
      zmove((bot_h-top_h)/2)
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
                        wall = (d > 0) ? wallt1 : min(wallt1, ((cap_od + 2 * (cap_wall) - neck_id) / 2))
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
                        thread_depth = cap_thread_depth,
                        tolerance = tolerance,
                        neck_od = cap_neck_od,
                        flank_angle = cap_thread_taper,
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
      children();
    }
}

function bottle_adapter_neck_to_cap(
    wall, texture, cap_wall, cap_h, cap_thread_depth1,
    tolerance, cap_neck_od, cap_neck_id, cap_thread_taper,
    cap_thread_pitch, neck_d, neck_id, neck_thread_od,
    neck_h, neck_thread_pitch, neck_support_od, d, taper_lead_in
) = no_fuction("bottle_adapter_neck_to_cap");


// Module: bottle_adapter_cap_to_cap()
// Synopsis: Creates a generic adaptor between a cap and a cap.
// SynTags: Geom
// Topics: Bottles, Threading
// See Also: bottle_adapter_neck_to_cap(), bottle_adapter_neck_to_neck()
// Usage:
//   bottle_adapter_cap_to_cap(wall, [texture]) [ATTACHMENTS];
// Description:
//   Creates a threaded cap to cap adapter.
// Arguments:
//   wall = Wall thickness in mm.
//   texture = The surface texture of the cap.  Valid values are "none", "knurled", or "ribbed".  Default: "none"
//   cap_h1 = Interior height of top cap.
//   cap_thread_depth1 = Thread depth on top cap.  Default: 2.34
//   tolerance = Extra space to add to the outer diameter of threads and neck in mm.  Applied to radius.
//   cap_neck_od1 = Inner diameter of threads on top cap.
//   cap_thread_pitch1 = Thread pitch of top cap in mm.
//   cap_h2 = Interior height of bottom cap.  Leave undefined to duplicate cap_h1.
//   cap_thread_depth2 = Thread depth on bottom cap.  Default: same as cap_thread_depth1
//   cap_neck_od2 = Inner diameter of threads on top cap.  Leave undefined to duplicate cap_neck_od1.
//   cap_thread_pitch2 = Thread pitch of bottom cap in mm.  Leave undefinced to duplicate cap_thread_pitch1.
//   d = Distance between caps.
//   neck_id1 = Inner diameter of cutout in top cap.
//   neck_id2 = Inner diameter of cutout in bottom cap.
//   taper_lead_in = Length to leave straight before tapering on tube between caps if exists.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Examples:
//   bottle_adapter_cap_to_cap();
module bottle_adapter_cap_to_cap(
    wall = 2,
    texture = "none",
    cap_h1 = 11.2,
    cap_thread_depth1 = 2.34,
    tolerance = .2,
    cap_neck_od1 = 25.5,
    cap_thread_pitch1 = 4,
    cap_h2,
    cap_thread_depth2,
    cap_neck_od2,
    cap_thread_pitch2,
    d = 0,
    neck_id,
    taper_lead_in = 0, anchor, spin,orient
) {
    cap_h2 = default(cap_h2,cap_h1);
    cap_thread_depth2 = default(cap_thread_depth2,cap_thread_depth1);
    cap_neck_od2 = default(cap_neck_od2,cap_neck_od1);
    cap_thread_pitch2 = default(cap_thread_pitch2,cap_thread_pitch1);
    taper_lead_in = (d >= taper_lead_in * 2) ? taper_lead_in : d / 2;

    neck_id = min(cap_neck_od1 - cap_thread_depth1, cap_neck_od2-cap_thread_depth2);
    
    top_h = cap_h1+wall;
    bot_h = cap_h2+wall;
    

    cap_od1 = cap_neck_od1 + 2*(cap_thread_depth1 - 0.8) + 2 * tolerance;   // WTF; Engineered for consistency with old code, but
    cap_od2 = cap_neck_od2 + 2*(cap_thread_depth2 - 0.8) + 2 * tolerance;   // WTF; Engineered for consistency with old code, but 
    
    $fn = segs(33 / 2);
    attachable(anchor=anchor,spin=spin,orient=orient, h=top_h+bot_h+d, d=max(cap_od1,cap_od2)+2*wall){
      zmove((bot_h-top_h)/2)
        difference(){
          union(){
              up(d / 2){
                  generic_bottle_cap(
                      orient = UP,
                      wall = wall,
                      texture = texture,
                      height = cap_h1,
                      thread_depth = cap_thread_depth1,
                      tolerance = tolerance,
                      neck_od = cap_neck_od1,
                      pitch = cap_thread_pitch1
                  );
              }
              if (d != 0) {
                  rotate_extrude() {
                      polygon(points = [
                          [0, d / 2],
                          [cap_od1 / 2 + wall, d / 2],
                          [cap_od1 / 2 + wall, d / 2 - taper_lead_in],
                          [cap_od2 / 2 + wall, taper_lead_in - d / 2],
                          [cap_od2 / 2 + wall, -d / 2],
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
                      thread_depth = cap_thread_depth2,
                      tolerance = tolerance,
                      neck_od = cap_neck_od2,
                      pitch = cap_thread_pitch2
                  );
              }
          }
          rotate_extrude() {
                  polygon(points = [
                      [0, wall + d / 2 + 0.1],
                      [neck_id / 2, wall + d / 2],
                      [neck_id / 2, wall + d / 2 - taper_lead_in],
                      [neck_id / 2, taper_lead_in - d / 2 - wall],
                      [neck_id / 2, -d / 2 - wall],
                      [0, -d / 2 - wall - 0.1]
                  ]);
              }
      }
      children();
    }
}

function bottle_adapter_cap_to_cap(
    wall, texture, cap_h1, cap_thread_od1, tolerance,
    cap_neck_od1, cap_thread_pitch1, cap_h2, cap_thread_od2,
    cap_neck_od2, cap_thread_pitch2, d, neck_id1, neck_id2, taper_lead_in
) = no_function("bottle_adapter_cap_to_cap");


// Module: bottle_adapter_neck_to_neck()
// Synopsis: Creates a generic adaptor between a neck and a neck.
// SynTags: Geom
// Topics: Bottles, Threading
// See Also: bottle_adapter_neck_to_cap(), bottle_adapter_cap_to_cap()
// Usage:
//   bottle_adapter_neck_to_neck(...) [ATTACHMENTS];
// Description:
//   Creates a threaded neck to neck adapter.
// Arguments:
//   ---
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
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
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
    support_od2,  pitch2,
    taper_lead_in = 0, wall, anchor, spin, orient
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

    top_h = height1 + max(1,height1/17)*sign(support_od1);
    bot_h = height2 + max(1,height2/17)*sign(support_od2);
    
    attachable(anchor=anchor,orient=orient,spin=spin, h=top_h+bot_h+d, d=max(neck_od1,neck_od2)){
      zmove((bot_h-top_h)/2)
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
      children();
    }
}

function bottle_adapter_neck_to_neck(
    d, neck_od1, neck_id1, thread_od1, height1,
    support_od1, thread_pitch1, neck_od2, neck_id2,
    thread_od2, height2, support_od2,
    pitch2, taper_lead_in, wall
) = no_fuction("bottle_adapter_neck_to_neck");



// Section: SPI Bottle Threading


// Module: sp_neck()
// Synopsis: Creates an SPI threaded bottle neck.
// SynTags: Geom
// Topics: Bottles, Threading
// See Also: sp_cap()
// Usage:
//   sp_neck(diam, type, wall|id=, [style=], [bead=]) [ATTACHMENTS];
// Description:
//   Make a SPI (Society of Plastics Industry) threaded bottle neck.  You must
//   supply the nominal outer diameter of the threads and the thread type, one of
//   400, 410 and 415.  The 400 type neck has 360 degrees of thread, the 410
//   neck has 540 degrees of thread, and the 415 neck has 720 degrees of thread.
//   You can also choose between the L style thread, which is symmetric and
//   the M style thread, which is an asymmetric buttress thread.  The M style
//   may be good for 3d printing if printed with the flat face up.  
//   You can specify the wall thickness (measured from the base of the threads) or
//   the inner diameter, and you can specify an optional bead at the base of the threads.
// Arguments:
//   diam = nominal outer diameter of threads
//   type = thread type, one of 400, 410 and 415
//   wall = wall thickness
//   ---
//   id = inner diameter
//   style = Either "L" or "M" to specify the thread style.  Default: "L"
//   bead = if true apply a bad to the neck.  Default: false
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Examples:
//   sp_neck(48,400,2);
//   sp_neck(48,400,2,bead=true);
//   sp_neck(22,410,2);
//   sp_neck(22,410,2,bead=true);
//   sp_neck(28,415,id=20,style="M");
//   sp_neck(13,415,wall=1,style="M",bead=true);


// Thread specs from https://www.isbt.com/threadspecs-downloads.asp

//  T = peak to peak diameter (outer diameter)
//  I = Inner diameter
//  S = space above top thread
//  H = total height of neck

_sp_specs = [
  [400, //diam     T      I      H     S    tpi
        [[ 18, [ 17.68,  8.26,  9.42, 0.94, 8]],
         [ 20, [ 19.69, 10.26,  9.42, 0.94, 8]],
         [ 22, [ 21.69, 12.27,  9.42, 0.94, 8]],
         [ 24, [ 23.67, 13.11, 10.16, 1.17, 8]],
         [ 28, [ 27.38, 15.60, 10.16, 1.17, 6]],
         [ 30, [ 28.37, 16.59, 10.24, 1.17, 6]],
         [ 33, [ 31.83, 20.09, 10.24, 1.17, 6]],
         [ 35, [ 34.34, 22.23, 10.24, 1.17, 6]],
         [ 38, [ 37.19, 25.07, 10.24, 1.17, 6]],
         [ 40, [ 39.75, 27.71, 10.24, 1.17, 6]],
         [ 43, [ 41.63, 29.59, 10.24, 1.17, 6]],
         [ 45, [ 43.82, 31.78, 10.24, 1.17, 6]],
         [ 48, [ 47.12, 35.08, 10.24, 1.17, 6]],
         [ 51, [ 49.56, 37.57, 10.36, 1.17, 6]],
         [ 53, [ 52.07, 40.08, 10.36, 1.17, 6]],
         [ 58, [ 56.06, 44.07, 10.36, 1.17, 6]],
         [ 60, [ 59.06, 47.07, 10.36, 1.17, 6]],
         [ 63, [ 62.08, 50.09, 10.36, 1.17, 6]],
         [ 66, [ 65.07, 53.09, 10.36, 1.17, 6]],
         [ 70, [ 69.06, 57.07, 10.36, 1.17, 6]],
         [ 75, [ 73.56, 61.57, 10.36, 1.17, 6]],
         [ 77, [ 76.66, 64.67, 12.37, 1.52, 6]],
         [ 83, [ 82.58, 69.93, 12.37, 1.52, 5]],
         [ 89, [ 88.75, 74.12, 13.59, 1.52, 5]],
         [100, [ 99.57, 84.94, 15.16, 1.52, 5]],
         [110, [109.58, 94.92, 15.16, 1.52, 5]],
         [120, [119.56,104.93, 17.40, 1.52, 5]],
        ]],
  [410, //diam     T      I      H     S    tpi  L      W
        [[ 18, [ 17.68,  8.26, 13.28, 0.94, 8,  9.17, 2.13]],
         [ 20, [ 19.59, 10.26, 14.07, 0.94, 8,  9.17, 2.13]],
         [ 22, [ 21.69, 12.27, 14.86, 0.94, 8,  9.55, 2.13]],
         [ 24, [ 23.67, 13.11, 16.41, 1.17, 8, 11.10, 2.13]],
         [ 28, [ 27.38, 15.60, 17.98, 1.17, 6, 11.76, 2.39]],
         ]],
  [415, //diam     T      I      H     S    tpi  L      W
        [[ 13, [ 12.90,  5.54, 11.48, 0.94,12,  7.77, 1.14]],
         [ 15, [ 14.61,  6.55, 14.15, 0.94,12,  8.84, 1.14]],
         [ 18, [ 17.68,  8.26, 15.67, 0.94, 8, 10.90, 2.13]],
         [ 20, [ 19.69, 10.26, 18.85, 0.94, 8, 11.58, 2.13]],
         [ 22, [ 21.69, 12.27, 21.26, 0.94, 8, 13.87, 2.13]],
         [ 24, [ 23.67, 13.11, 24.31, 1.17, 8, 14.25, 2.13]],
         [ 28, [ 27.38, 15.60, 27.48, 1.17, 6, 16.64, 2.39]],
         [ 33, [ 31.83, 20.09, 32.36, 1.17, 6, 19.61, 2.39]],
         ]]
];

_sp_twist = [ [400, 360],
              [410, 540],
              [415, 720]
            ];


// profile data: tpi, total width, depth, 
_sp_thread_width= [
                [5, 3.05],
                [6, 2.39],
                [8, 2.13],
                [12, 1.14],  // But note style M is different
               ];


function _sp_thread_profile(tpi, a, S, style, flip=false) = 
    let(
        pitch = 1/tpi*INCH,
        cL = a*(1-1/sqrt(3)),
        cM = (1-tan(10))*a/2,
        // SP specified roundings for the thread profile have special case for tpi=12
        roundings = style=="L" && tpi < 12 ? 0.5 
                  : style=="M" && tpi < 12 ? [0.25, 0.25, 0.75, 0.75]
                  : style=="L" ? [0.38, 0.13, 0.13, 0.38]
                  : /* style=="M" */  [0.25, 0.25, 0.2, 0.5],
        path1 = style=="L"
                  ? round_corners([[-1/2*pitch,-a/2],
                                   [-a/2,-a/2],
                                   [-cL/2,0],
                                   [cL/2,0],
                                   [a/2,-a/2],
                                   [1/2*pitch,-a/2]], radius=roundings, closed=false,$fn=24)
                  : round_corners(
                       [[-1/2*pitch,-a/2],
                                   [-a/2, -a/2],
                                   [-cM, 0],
                                   [0,0],
                                   [a/2,-a/2],
                                   [1/2*pitch,-a/2]], radius=roundings, closed=false, $fn=24),
        path2 = flip ? reverse(xflip(path1)) : path1
   )
   // Shift so that the profile is S mm from the right end to create proper length S top gap
   select(right(-a/2+1/2-S,p=path2),1,-2)/pitch;


function sp_neck(diam,type,wall,id,style="L",bead=false, anchor, spin, orient) = no_function("sp_neck");
module sp_neck(diam,type,wall,id,style="L",bead=false, anchor, spin, orient)
{
    assert(num_defined([wall,id])==1, "Must define exactly one of wall and id");
    
    table = struct_val(_sp_specs,type);
    dum1=assert(is_def(table),"Unknown SP closure type.  Type must be one of 400, 410, or 415");
    entry = struct_val(table, diam);
    dum2=assert(is_def(entry), str("Unknown closure nominal diameter.  Allowed diameters for SP",type,": ",struct_keys(table)))
         assert(style=="L" || style=="M", "style must be \"L\" or \"M\"");

    T = entry[0];
    I = entry[1];
    H = entry[2];
    S = entry[3];
    tpi = entry[4];

    // a is the width of the thread 
    a = (style=="M" && tpi==12) ? 1.3 : struct_val(_sp_thread_width,tpi);

    twist = struct_val(_sp_twist, type);

    profile = _sp_thread_profile(tpi,a,S,style);

    depth = a/2;
    taperlen = 2*a;

    beadmax = type==400 ? (T/2-depth)+depth*1.25
            : diam <=15 ? (T-.15)/2 : (T-.05)/2;
    
    W = type==400 ? a*1.5      // arbitrary decision for type 400
                  : entry[6];  // specified width for 410 and 415

    beadpts = [
                [0,-W/2],
                each arc(16, points = [[T/2-depth, -W/2],
                                       [beadmax, 0],
                                       [T/2-depth, W/2]]),
                [0,W/2]
              ];

    isect400 = [for(seg=pair(beadpts)) let(segisect = line_intersection([[T/2,0],[T/2,1]] , seg, LINE, SEGMENT)) if (is_def(segisect)) segisect.y];

    extra_bot = type==400 && bead ? -min(column(beadpts,1))+max(isect400) : 0;
    bead_shift = type==400 ? H+max(isect400) : entry[5]+W/2;  // entry[5] is L

    attachable(anchor,spin,orient,r=bead ? beadmax : T/2, l=H+extra_bot){
        up((H+extra_bot)/2){
            difference(){
                union(){
                    thread_helix(d=T-.01, profile=profile, pitch = INCH/tpi, turns=twist/360, lead_in=taperlen, anchor=TOP);
                    cylinder(d=T-depth*2,h=H,anchor=TOP);
                    if (bead)
                      down(bead_shift)
                         rotate_extrude()
                            polygon(beadpts);
                }
                up(.5)cyl(d=is_def(id) ? id : T-a-2*wall, l=H-extra_bot+1, anchor=TOP);
            }
        }
        children();
    }
}



// Module: sp_cap()
// Synopsis: Creates an SPI threaded bottle cap.
// SynTags: Geom
// Topics: Bottles, Threading
// See Also: sp_neck()
// Usage:
//   sp_cap(diam, type, wall, [style=], [top_adj=], [bot_adj=], [texture=], [$slop]) [ATTACHMENTS];
// Description:
//   Make a SPI (Society of Plastics Industry) threaded bottle neck.  You must
//   supply the nominal outer diameter of the threads and the thread type, one of
//   400, 410 and 415.  The 400 type neck has 360 degrees of thread, the 410
//   neck has 540 degrees of thread, and the 415 neck has 720 degrees of thread.
//   You can also choose between the L style thread, which is symmetric and
//   the M style thread, which is an asymmetric buttress thread.  Note that it
//   is OK to mix styles, so you can put an L-style cap onto an M-style neck.  
//   .
//   The 410 and 415 caps have very long unthreaded sections at the bottom.
//   The bot_adj parameter specifies an amount to reduce that bottom extension, which might be
//   necessary if the cap bottoms out on the bead.  Be careful that you don't shrink past the threads,
//   especially if making adjustments to 400 caps which have a very small bottom extension.  
//   These caps often contain a cardboard or foam sealer disk, which can be as much as 1mm thick, and
//   would cause the cap to stop in a higher position.
//   .
//   You can also adjust the space between the top of the cap and the threads using top_adj.  This
//   will change how the threads engage when the cap is fully seated.
//   .
//   The inner diameter of the cap is set to allow 10% of the thread depth in clearance.  The diameter
//   is further increased by `2 * $slop` so you can increase clearance if necessary. 
//   .
//   Note: there is a published SPI standard for necks, but absolutely nothing for caps.  This
//   cap module was designed based on the neck standard to mate reasonably well, but if you
//   find ways that it does the wrong thing, file a report.  
// Arguments:
//   diam = nominal outer diameter of threads
//   type = thread type, one of 400, 410 and 415
//   wall = wall thickness
//   ---
//   style = Either "L" or "M" to specify the thread style.  Default: "L"
//   top_adj = Amount to reduce top space in the cap, which means it doesn't screw down as far.  Default: 0
//   bot_adj = Amount to reduce extension of cap at the bottom, which also means it doesn't screw down as far.  Default: 0
//   texture = texture for outside of cap, one of "knurled", "ribbed" or "none.  Default: "none"
//   $slop = Increase inner diameter by `2 * $slop`.  
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Examples:
//   sp_cap(48,400,2);
//   sp_cap(22,400,2);
//   sp_cap(22,410,2);
//   sp_cap(28,415,1.5,style="M");
module sp_cap(diam,type,wall,style="L",top_adj=0, bot_adj=0, texture="none", anchor, spin, orient)
{
    table = struct_val(_sp_specs,type);
    dum1=assert(is_def(table),"Unknown SP closure type.  Type must be one of 400, 410, or 415");
    entry = struct_val(table, diam);
    dum2=assert(is_def(entry), str("Unknown closure nominal diameter.  Allowed diameters for SP",type,": ",struct_keys(table)))
         assert(style=="L" || style=="M", "style must be \"L\" or \"M\"");

    T = entry[0];
    I = entry[1];
    H = entry[2]-0.5;
    S = entry[3];
    tpi = entry[4];
    a = (style=="M" && tpi==12) ? 1.3 : struct_val(_sp_thread_width,tpi);

    twist = struct_val(_sp_twist, type);

    dum3=assert(top_adj<S+0.75*a, str("The top_adj value is too large so the thread won't fit.  It must be smaller than ",S+0.75*a));
    oprofile = _sp_thread_profile(tpi,a,S+0.75*a-top_adj,style,flip=true);
    bounds=pointlist_bounds(oprofile);
    profile = fwd(-bounds[0].y,yflip(oprofile));

    depth = a/2;
    taperlen = 2*a;
    assert(in_list(texture, ["none","knurled","ribbed"]));
    space=2*depth/10+2*get_slop();
    attachable(anchor,spin,orient,r= (T+space)/2+wall, l=H-bot_adj+wall){
        xrot(180)
        up((H-bot_adj)/2-wall/2){
            difference(){
                up(wall){
                   if (texture=="knurled")
                        cyl(d=T+space+2*wall,l=H+wall-bot_adj,anchor=TOP,texture="trunc_pyramids", tex_size=[3,3], style="convex");
                   else if (texture == "ribbed") 
                        cyl(d=T+space+2*wall,l=H+wall-bot_adj,anchor=TOP,chamfer2=.8,tex_taper=0,texture="trunc_ribs", tex_size=[3,3], style="min_edge");
                   else
                        cyl(d=T+space+2*wall,l=H+wall-bot_adj,anchor=TOP,chamfer2=.8);
                }
                cyl(d=T+space, l=H-bot_adj+1, anchor=TOP);
            }
            thread_helix(d=T+space-.01, profile=profile, pitch = INCH/tpi, turns=twist/360, lead_in=taperlen, anchor=TOP, internal=true);
        }
        children();
    }
}



// Function: sp_diameter()
// Synopsis: Returns the base diameter of an SPI bottle neck from the nominal diameter and type number.
// Topics: Bottles, Threading
// See Also: sp_neck(), sp_cap()
// Usage:
//   true_diam = sp_diameter(diam,type)
// Description:
//   Returns the actual base diameter (root of the threads) for a SPI plastic bottle neck given the nominal diameter and type number (400, 410, 415). 
// Arguments:
//   diam = nominal diameter
//   type = closure type number (400, 410 or 415)
function sp_diameter(diam,type) =
  let(
      table = struct_val(_sp_specs,type)
  )
  assert(is_def(table),"Unknown SP closure type.  Type must be one of 400, 410, or 415")
  let(
      entry = struct_val(table, diam)
  )
  assert(is_def(entry), str("Unknown closure nominal diameter.  Allowed diameters for SP",type,": ",struct_keys(table)))
  entry[0];



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
