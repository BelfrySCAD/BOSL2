//////////////////////////////////////////////////////////////////////
// LibFile: bottlecaps.scad
//   Bottle caps and necks for PCO18XX standard plastic beverage bottles.
//   To use, add the following lines to the beginning of your file:
//   ```
//   include <BOSL2/std.scad>
//   include <BOSL2/bottlecaps.scad>
//   ```
//////////////////////////////////////////////////////////////////////


include <threading.scad>
include <knurling.scad>


// Section: PCO-1810 Bottle Threading


// Module: pco1810_neck()
// Usage:
//   pco1810_neck()
// Description:
//   Creates an approximation of a standard PCO-1810 threaded beverage bottle neck.
// Arguments:
//   wall = Wall thickness in mm.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
// Extra Anchors:
//   "tamper-ring" = Centered at the top of the anti-tamper ring channel.
//   "support-ring" = Centered at the bottom of the support ring.
// Example:
//   pco1810_neck();
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
	orient_and_anchor([support_d,support_d,h], orient, anchor, spin=spin, anchors=anchors, chain=true) {
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
							base_d=threadbase_d-0.1,
							pitch=thread_pitch,
							thread_depth=thread_h+0.1,
							thread_angle=thread_angle,
							twist=810,
							higbee=75,
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


// Module: pco1810_cap()
// Usage:
//   pco1810_cap(wall, [texture]);
// Description:
//   Creates a basic cap for a PCO1810 threaded beverage bottle.
// Arguments:
//   wall = Wall thickness in mm.
//   texture = The surface texture of the cap.  Valid values are "none", "knurled", or "ribbed".  Default: "none"
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
// Extra Anchors:
//   "inside-top" = Centered on the inside top of the cap.
// Examples:
//   pco1810_cap();
//   pco1810_cap(texture="knurled");
//   pco1810_cap(texture="ribbed");
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
	orient_and_anchor([w, w, h], orient, anchor, spin=spin, anchors=anchors, chain=true) {
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
			up(wall+2) thread_helix(base_d=thread_od-thread_depth*2, pitch=thread_pitch, thread_depth=thread_depth, thread_angle=thread_angle, twist=810, higbee=45, internal=true, anchor=BOTTOM);
		}
		children();
	}
}


// Section: PCO-1881 Bottle Threading


// Module: pco1881_neck()
// Usage:
//   pco1881_neck()
// Description:
//   Creates an approximation of a standard PCO-1881 threaded beverage bottle neck.
// Arguments:
//   wall = Wall thickness in mm.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
// Extra Anchors:
//   "tamper-ring" = Centered at the top of the anti-tamper ring channel.
//   "support-ring" = Centered at the bottom of the support ring.
// Example:
//   pco1881_neck();
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
	orient_and_anchor([support_d,support_d,h], orient, anchor, spin=spin, anchors=anchors, chain=true) {
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
						base_d=threadbase_d-0.1,
						pitch=thread_pitch,
						thread_depth=thread_h+0.1,
						thread_angle=thread_angle,
						twist=650,
						higbee=75,
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
module pco1881_cap(wall=2, texture="none", anchor=BOTTOM, spin=0, orient=UP)
{
	$fn = segs(33/2);
	w = 28.58 + 2*wall;
	h = 11.2 + wall;
	anchors = [
		anchorpt("inside-top", [0,0,-(h/2-wall)])
	];
	orient_and_anchor([w, w, h], orient, anchor, spin=spin, anchors=anchors, chain=true) {
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
			up(wall+2) thread_helix(base_d=25.5, pitch=2.7, thread_depth=1.6, thread_angle=15, twist=650, higbee=45, internal=true, anchor=BOTTOM);
		}
		children();
	}
}



// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
