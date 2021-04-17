//////////////////////////////////////////////////////////////////////
// LibFile: bottlecaps_adapters.scad
//   Adapters for various combinations of bottle necks and caps.
// Includes:
//   include <BOSL2/std.scad>
//   include <BOSL2/bottlecaps_adapters.scad>
//////////////////////////////////////////////////////////////////////

include <BOSL2/threading.scad>
include <BOSL2/knurling.scad>


// Module: generic_bottle_neck()
// Usage:
//   generic_bottle_neck(<wall>)
// Description:
//   Creates a bottle neck given specifications.
// Arguments:
//   neckDiam = Outer diameter of neck without threads
//   innerDiam = Inner diameter of neck
//   threadOuterD = Outer diameter of thread
//   height = Height of neck above support
//   supportDiam = Outer diameter of support ring.  Set to 0 for no support.
//   threadPitch = Thread pitch
//   wall = distance between ID and any wall that may be below the support
//   roundLowerSupport = True to round the lower edge of the support ring
//   ---
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
// Extra Anchors:
//   "support-ring" = Centered at the bottom of the support ring.
// Example:
//   generic_bottle_neck();
module generic_bottle_neck(
    neckDiam = 25,
    innerDiam = 21.4,
    threadOuterD = 27.2,
    height = 17,
    supportDiam = 33.0,
    threadPitch = 3.2,
    roundLowerSupport = false,
    wall,
    anchor = "support-ring",
    spin = 0,
    orient = UP
) {
    inner_d = innerDiam;
    neck_d = neckDiam;
    support_d = max(neckDiam, supportDiam);
    thread_pitch = threadPitch;
    thread_angle = 15;
    thread_od = threadOuterD;

    diamMagMult = neckDiam / 26.19;
    heightMagMult = height / 17.00;

    sup_r = 0.30 * (heightMagMult > 1 ? heightMagMult : 1);
    support_r = floor(((support_d == neck_d) ? sup_r : min(sup_r, (support_d - neck_d) / 2)) * 5000) / 10000;
    support_rad = (wall == undef || !roundLowerSupport) ? support_r :
        min(support_r, floor((support_d - (inner_d + 2 * wall)) * 5000) / 10000);
        //Too small of a radius will cause errors with the arc, this limits granularity to .0001mm
    support_width = 1 * (heightMagMult > 1 ? heightMagMult : 1) * sign(supportDiam);
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
                    state = [inner_d / 2, 0], (support_d != neck_d) ? [
                        "untilx", support_d / 2 - ((roundLowerSupport) ? support_rad : 0),
                        "arcleft", ((roundLowerSupport) ? support_rad : 0), 90,
                        "untily", support_width - support_rad,
                        "arcleft", support_rad, 90,
                        "untilx", neck_d / 2,
                        "right", 90,
                        "untily", h - lip_roundover_r,
                        "arcleft", lip_roundover_r, 90,
                        "untilx", inner_d / 2
                    ] : [
                        "untilx", support_d / 2 - ((roundLowerSupport) ? support_rad : 0),
                        "arcleft", ((roundLowerSupport) ? support_rad : 0), 90,
                        "untily", h - lip_roundover_r,
                        "arcleft", lip_roundover_r, 90,
                        "untilx", inner_d / 2
                    ]
                ));
            }
            up(h - threadPitch / 2 - lip_roundover_r) {
                difference() {
                    thread_helix(
                        d = threadbase_d - 0.1 * diamMagMult,
                        pitch = thread_pitch,
                        thread_depth = thread_h + 0.1 * diamMagMult,
                        thread_angle = thread_angle,
                        twist = 360 * (height - threadPitch - lip_roundover_r) * .6167 / threadPitch,
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
	neckDiam,
    innerDiam,
    threadOuterD,
    height,
    supportDiam,
    threadPitch,
    roundLowerSupport,
    wall,
    anchor, spin, orient
) = no_function("generic_bottle_neck");


// Module: generic_bottle_cap()
// Usage:
//   generic_bottle_cap(wall, <texture>, ...);
// Description:
//   Creates a basic threaded cap given specifications.
// Arguments:
//   wall = Wall thickness in mm.
//   texture = The surface texture of the cap.  Valid values are "none", "knurled", or "ribbed".  Default: "none"
//   ---
//   height = Interior height of the cap in mm.
//   threadOuterD = Outer diameter of the threads in mm.
//   tolerance = Extra space to add to the outer diameter of threads and neck in mm.  Applied to radius.
//   neckOuterD = Outer diameter of neck in mm.
//   threadAngle = Angle of taper on threads.
//   threadPitch = Thread pitch in mm.
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
    threadOuterD = 28.58,
    tolerance = .2,
    neckOuterD = 25.5,
    threadAngle = 15,
    threadPitch = 4,
    anchor = BOTTOM,
    spin = 0,
    orient = UP
) {
    $fn = segs(33 / 2);
    threadOuterDTol = threadOuterD + 2 * tolerance;
    w = threadOuterDTol + 2 * wall;
    h = height + wall;
    neckOuterDTol = neckOuterD + 2 * tolerance;
    threadDepth = (threadOuterD - neckOuterD) / 2 + .8;

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
                up(wall + threadPitch / 2) {
                    thread_helix(d = neckOuterDTol, pitch = threadPitch, thread_depth = threadDepth, thread_angle = threadAngle, twist = 360 * ((height - threadPitch) / threadPitch), higbee = threadDepth, internal = true, anchor = BOTTOM);
                }
            }
        }
        children();
    }
}

function generic_bottle_cap(
    wall, texture, height,
    threadOuterD, tolerance,
    neckOuterD, threadAngle, threadPitch,
    anchor, spin, orient
) = no_function("generic_bottle_cap");


// Module: thread_adapter_NC()
// Usage:
//   thread_adapter_NC(wall, [texture]);
// Description:
//   Creates a threaded neck to cap adapter
// Arguments:
//   wall = Thickness of wall between neck and cap when d=0.  Leave undefined to have the outside of the tube go from the OD of the neck support ring to the OD of the cap.  Default: undef
//   texture = The surface texture of the cap.  Valid values are "none", "knurled", or "ribbed".  Default: "none"
//   capWall = Wall thickness of the cap in mm.
//   capHeight = Interior height of the cap in mm.
//   capThreadOD = Outer diameter of cap threads in mm.
//   tolerance = Extra space to add to the outer diameter of threads and neck in mm.  Applied to radius.
//   capNeckOD = Inner diameter of the cap threads.
//   capNeckID = Inner diameter of the hole through the cap.
//   capThreadTaperAngle = Angle of taper on threads.
//   capThreadPitch = Thread pitch in mm
//   neckDiam = Outer diameter of neck w/o threads
//   neckID = Inner diameter of neck
//   neckThreadOD = 27.2
//   neckHeight = Height of neck down to support ring
//   neckThreadPitch = Thread pitch in mm.
//   neckSupportOD = Outer diameter of neck support ring.  Leave undefined to set equal to OD of cap.  Set to 0 for no ring.  Default: undef
//   d = Distance between bottom of neck and top of cap
//   taperLeadIn = Length to leave straight before tapering on tube between neck and cap if exists.
// Examples:
//   thread_adapter_NC();
module thread_adapter_NC(
    wall,
    texture = "none",
    capWall = 2,
    capHeight = 11.2,
    capThreadOD = 28.58,
    tolerance = .2,
    capNeckOD = 25.5,
    capNeckID,
    capThreadTaperAngle = 15,
    capThreadPitch = 4,
    neckDiam = 25,
    neckID = 21.4,
    neckThreadOD = 27.2,
    neckHeight = 17,
    neckThreadPitch = 3.2,
    neckSupportOD,
    d = 0,
    taperLeadIn = 0
) {
    neckSupportOD = (neckSupportOD == undef || (d == 0 && neckSupportOD < capThreadOD + 2 * tolerance)) ? capThreadOD + 2 * (capWall + tolerance) : neckSupportOD;
    capNeckID = (capNeckID == undef) ? neckID : capNeckID;
    wall = (wall == undef) ? neckSupportOD + neckDiam + capThreadOD + neckID : wall;

    $fn = segs(33 / 2);
    wallt1 = min(wall, (max(neckSupportOD, neckDiam) - neckID) / 2);
    wallt2 = min(wall, (capThreadOD + 2 * (capWall + tolerance) - capNeckID) / 2);

    difference(){
        union(){
            up(d / 2) {
                generic_bottle_neck(neckDiam = neckDiam,
                    innerDiam = neckID,
                    threadOuterD = neckThreadOD,
                    height = neckHeight,
                    supportDiam = neckSupportOD,
                    threadPitch = neckThreadPitch,
                    roundLowerSupport = ((wallt1 < (neckSupportOD - neckID) / 2) && (d > 0 || neckSupportOD > (capThreadOD + 2 * (capWall + tolerance)))),
                    wall = (d > 0) ? wallt1 : min(wallt1, ((capThreadOD + 2 * (capWall + tolerance) - neckID) / 2))
                );
            }
            if (d != 0) {
                rotate_extrude(){
                    polygon(points = [
                        [0, d / 2],
                        [neckID / 2 + wallt1, d / 2],
                        [neckID / 2 + wallt1, d / 2 - taperLeadIn],
                        [capNeckID / 2 + wallt2, taperLeadIn - d / 2],
                        [capNeckID / 2 + wallt2, -d / 2],
                        [0, -d / 2]
                    ]);
                }
            }
            down(d / 2){
                generic_bottle_cap(wall = capWall,
                    texture = texture,
                    height = capHeight,
                    threadOuterD = capThreadOD,
                    tolerance = tolerance,
                    neckOuterD = capNeckOD,
                    threadAngle = capThreadTaperAngle,
                    orient = DOWN,
                    threadPitch = capThreadPitch
                );
            }
        }
        rotate_extrude() {
            polygon(points = [
                [0, d / 2 + 0.1],
                [neckID / 2, d / 2],
                [neckID / 2, d / 2 - taperLeadIn],
                [capNeckID / 2, taperLeadIn - d / 2],
                [capNeckID / 2, -d / 2 - capWall],
                [0, -d / 2 - capWall - 0.1]
            ]);
        }
    }
}

function thread_adapter_NC(
    wall, texture, capWall, capHeight, capThreadOD,
    tolerance, capNeckOD, capNeckId, capThreadTaperAngle,
    capThreadPitch, neckDiam, neckID, neckThreadOD,
    neckHeight, neckThreadPitch, neckSupportOD, d, taperLeadIn
) = no_fuction("thread_adapter_NC");


// Module: thread_adapter_CC()
// Usage:
//   thread_adapter_CC(wall, [texture]);
// Description:
//   Creates a threaded cap to cap adapter.
// Arguments:
//   wall = Wall thickness in mm.
//   texture = The surface texture of the cap.  Valid values are "none", "knurled", or "ribbed".  Default: "none"
//   capHeight1 = Interior height of top cap.
//   capThreadOD1 = Outer diameter of threads on top cap.
//   tolerance = Extra space to add to the outer diameter of threads and neck in mm.  Applied to radius.
//   capNeckOD1 = Inner diameter of threads on top cap.
//   capThreadPitch1 = Thread pitch of top cap in mm.
//   capHeight2 = Interior height of bottom cap.  Leave undefined to duplicate capHeight1.
//   capThreadOD2 = Outer diameter of threads on bottom cap.  Leave undefined to duplicate capThread1.
//   capNeckOD2 = Inner diameter of threads on top cap.  Leave undefined to duplicate capNeckOD1.
//   capThreadPitch2 = Thread pitch of bottom cap in mm.  Leave undefinced to duplicate capThreadPitch1.
//   d = Distance between caps.
//   neckID1 = Inner diameter of cutout in top cap.
//   neckID2 = Inner diameter of cutout in bottom cap.
//   taperLeadIn = Length to leave straight before tapering on tube between caps if exists.
// Examples:
//   thread_adapter_CC();
module thread_adapter_CC(
    wall = 2,
    texture = "none",
    capHeight1 = 11.2,
    capThreadOD1 = 28.58,
    tolerance = .2,
    capNeckOD1 = 25.5,
    capThreadPitch1 = 4,
    capHeight2,
    capThreadOD2,
    capNeckOD2,
    capThreadPitch2,
    d = 0,
    neckID1, neckID2,
    taperLeadIn = 0
) {
    capHeight2 = (capHeight2 == undef) ? capHeight1 : capHeight2;
    capThreadOD2 = (capThreadOD2 == undef) ? capThreadOD1 : capThreadOD2;
    capNeckOD2 = (capNeckOD2 == undef) ? capNeckOD1 : capNeckOD2;
    capThreadPitch2 = (capThreadPitch2 == undef) ? capThreadPitch1 : capThreadPitch2;
    neckID2 = (neckID2 == undef && neckID1 != undef) ? neckID1 : neckID2;
    taperLeadIn = (d >= taperLeadIn * 2) ? taperLeadIn : d / 2;


    $fn = segs(33 / 2);

    difference(){
        union(){
            up(d / 2){
                generic_bottle_cap(
                    orient = UP,
                    wall = wall,
                    texture = texture,
                    height = capHeight1,
                    threadOuterD = capThreadOD1,
                    tolerance = tolerance,
                    neckOuterD = capNeckOD1,
                    threadPitch = capThreadPitch1
                );
            }
            if (d != 0) {
                rotate_extrude() {
                    polygon(points = [
                        [0, d / 2],
                        [capThreadOD1 / 2 + (wall + tolerance), d / 2],
                        [capThreadOD1 / 2 + (wall + tolerance), d / 2 - taperLeadIn],
                        [capThreadOD2 / 2 + (wall + tolerance), taperLeadIn - d / 2],
                        [capThreadOD2 / 2 + (wall + tolerance), -d / 2],
                        [0, -d / 2]
                    ]);
                }
            }
            down(d / 2){
                generic_bottle_cap(
                    orient = DOWN,
                    wall = wall,
                    texture = texture,
                    height = capHeight2,
                    threadOuterD = capThreadOD2,
                    tolerance = tolerance,
                    neckOuterD = capNeckOD2,
                    threadPitch = capThreadPitch2
                );
            }
        }
        if (neckID1 != undef || neckID2 != undef) {
            neckID1 = (neckID1 == undef) ? neckID2 : neckID1;
            neckID2 = (neckID2 == undef) ? neckID1 : neckID2;

            rotate_extrude() {
                polygon(points = [
                    [0, wall + d / 2 + 0.1],
                    [neckID1 / 2, wall + d / 2],
                    [neckID1 / 2, wall + d / 2 - taperLeadIn],
                    [neckID2 / 2, taperLeadIn - d / 2 - wall],
                    [neckID2 / 2, -d / 2 - wall],
                    [0, -d / 2 - wall - 0.1]
                ]);
            }
        }
    }
}

function thread_adapter_CC(
    wall, texture, capHeight1, capThreadOD1, tolerance,
    capNeckOD1, capThreadPitch1, capHeight2, capThreadOD2,
    capNeckOD2, capThreadPitch2, d, neckID1, neckID2, taperLeadIn
) = no_function("thread_adapter_CC");


// Module: thread_adapter_NN()
// Usage:
//   thread_adapter_NN();
// Description:
//   Creates a threaded neck to neck adapter.
// Arguments:
//   d = Distance between bottoms of necks
//   neckOD1 = Outer diameter of top neck w/o threads
//   neckID1 = Inner diameter of top neck
//   threadOD1 = Outer diameter of threads on top neck
//   height1 =  Height of top neck above support ring.
//   supportOD1 = Outer diameter of the support ring on the top neck.  Set to 0 for no ring.
//   threadPitch1 = Thread pitch of top neck.
//   neckOD2 = Outer diameter of bottom neck w/o threads.  Leave undefined to duplicate neckOD1
//   neckID2 = Inner diameter of bottom neck.  Leave undefined to duplicate neckID1
//   threadOD2 = Outer diameter of threads on bottom neck.  Leave undefined to duplicate threadOD1
//   height2 = Height of bottom neck above support ring.  Leave undefined to duplicate height1
//   supportOD2 = Outer diameter of the support ring on bottom neck.  Set to 0 for no ring.  Leave undefined to duplicate supportOD1 
//   threadPitch2 = Thread pitch of bottom neck.  Leave undefined to duplicate threadPitch1
//   taperLeadIn = Length to leave straight before tapering on tube between necks if exists.
//   wall = Thickness of tube wall between necks.  Leave undefined to match outer diameters with the neckODs/supportODs.  
// Examples:
//   thread_adapter_NN();
module thread_adapter_NN(
    d = 0,
    neckOD1 = 25,
    neckID1 = 21.4,
    threadOD1 = 27.2,
    height1 = 17,
    supportOD1 = 33.0,
    threadPitch1 = 3.2,
    neckOD2, neckID2,
    threadOD2, height2,
    supportOD2, threadPitch2,
    taperLeadIn = 0, wall
) {
    neckOD2 = (neckOD2 == undef) ? neckOD1 : neckOD2;
    neckID2 = (neckID2 == undef) ? neckID1 : neckID2;
    threadOD2 = (threadOD2 == undef) ? threadOD1 : threadOD2;
    height2 = (height2 == undef) ? height1 : height2;
    supportOD2 = (supportOD2 == undef) ? supportOD1 : supportOD2;
    threadPitch2 = (threadPitch2 == undef) ? threadPitch1 : threadPitch2;
    wall = (wall == undef) ? supportOD1 + supportOD2 + neckID1 + neckID2 : wall;

    supprtOD2 = (d == 0 && supportOD2 != 0) ? max(neckOD1, supportOD2) : supportOD2;
    supprtOD1 = (d == 0 && supportOD1 != 0) ? max(neckOD2, supportOD1) : supportOD1;

    $fn = segs(33 / 2);
    wallt1 = min(wall, (max(supprtOD1, neckOD1) - neckID1) / 2);
    wallt2 = min(wall, (max(supprtOD2, neckOD2) - neckID2) / 2);

    taperLeadIn = (d >= taperLeadIn * 2) ? taperLeadIn : d / 2;

    difference(){
        union(){
            up(d / 2){
                generic_bottle_neck(orient = UP,
                    neckDiam = neckOD1,
                    innerDiam = neckID1,
                    threadOuterD = threadOD1,
                    height = height1,
                    supportDiam = supprtOD1,
                    threadPitch = threadPitch1,
                    roundLowerSupport = ((wallt1 < (supprtOD1 - neckID1) / 2) || (supportOD1 > max(neckOD2, supportOD2) && d == 0)),
                    wall = (d > 0) ? wallt1 : min(wallt1, ((max(neckOD2, supportOD2)) - neckID1) / 2)
                );
            }
            if (d != 0) {
                rotate_extrude() {
                    polygon(points = [
                        [0, d / 2],
                        [neckID1 / 2 + wallt1, d / 2],
                        [neckID1 / 2 + wallt1, d / 2 - taperLeadIn],
                        [neckID2 / 2 + wallt2, taperLeadIn - d / 2],
                        [neckID2 / 2 + wallt2, -d / 2],
                        [0, -d / 2]
                    ]);
                }
            }
            down(d / 2){
                generic_bottle_neck(orient = DOWN,
                    neckDiam = neckOD2,
                    innerDiam = neckID2,
                    threadOuterD = threadOD2,
                    height = height2,
                    supportDiam = supprtOD2,
                    threadPitch = threadPitch2,
                    roundLowerSupport = ((wallt2 < (supprtOD2 - neckID2) / 2) || (supportOD2 > max(neckOD1, supportOD1) && d == 0)),
                    wall = (d > 0) ? wallt2 : min(wallt2, ((max(neckOD1, supportOD1)) - neckID2) / 2)
                );
            }
        }
        if (neckID1 != undef || neckID2 != undef) {
            neckID1 = (neckID1 == undef) ? neckID2 : neckID1;
            neckID2 = (neckID2 == undef) ? neckID1 : neckID2;

            rotate_extrude() {
                polygon(points = [
                    [0, d / 2],
                    [neckID1 / 2, d / 2],
                    [neckID1 / 2, d / 2 - taperLeadIn],
                    [neckID2 / 2, taperLeadIn - d / 2],
                    [neckID2 / 2, -d / 2],
                    [0, -d / 2]
                ]);
            }
        }
    }
}

function thread_adapter_NN(
    d, neckOD1, neckID1, threadOD1, height1,
    supportOD1, threadPitch1, neckOD2, neckID2,
    threadOD2, height2, supportOD2,
    threadPitch2, taperLeadIn, wall
) = no_fuction("thread_adapter_NN");


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
