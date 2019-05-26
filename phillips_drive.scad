//////////////////////////////////////////////////////////////////////
// LibFile: phillips_drive.scad
//   Phillips driver bits
//   To use, add these lines to the top of your file:
//   ```
//   include <BOSL2/std.scad>
//   include <BOSL2/phillips_drive.scad>
//   ```
//////////////////////////////////////////////////////////////////////


// Section: Modules


// Module: phillips_drive()
// Description: Creates a model of a phillips driver bit of a given named size.
// Arguments:
//   size = The size of the bit.  "#1", "#2", or "#3"
//   shaft = The diameter of the drive bit's shaft.
//   l = The length of the drive bit.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
// Example:
//   xdistribute(10) {
//      phillips_drive(size="#1", shaft=4, l=20);
//      phillips_drive(size="#2", shaft=6, l=20);
//      phillips_drive(size="#3", shaft=6, l=20);
//   }
module phillips_drive(size="#2", shaft=6, l=20, anchor=BOTTOM, spin=0, orient=UP) {
	// These are my best guess reverse-engineered measurements of
	// the tip diameters of various phillips screwdriver sizes.
	ang = 11;
	rads = [["#1", 1.25], ["#2", 1.77], ["#3", 2.65]];
	radidx = search([size], rads)[0];
	r = radidx == []? 0 : rads[radidx][1];
	h = (r/2)/tan(ang);
	cr = r/2;
	orient_and_anchor([shaft, shaft, l], orient, anchor, chain=true) {
		down(l/2) {
			difference() {
				intersection() {
					union() {
						clip = (shaft-1.2*r)/2/tan(26.5);
						zrot(360/8/2) cylinder(h=clip, d1=1.2*r/cos(360/8/2), d2=shaft/cos(360/8/2), center=false, $fn=8);
						up(clip-0.01) cylinder(h=l-clip, d=shaft, center=false, $fn=24);
					}
					cylinder(d=shaft, h=l, center=false, $fn=24);
				}
				zrot(45)
				zring(n=4) {
					yrot(ang) {
						zrot(-45) {
							off = (r/2-cr*(sqrt(2)-1))/sqrt(2);
							translate([off, off, 0]) {
								linear_extrude(height=l, convexity=4) {
									difference() {
										union() {
											square([shaft/2, shaft/2], center=false);
											mirror_copy([1,-1]) back(cr) zrot(1.125) square([shaft/2, shaft/2], center=false);
										}
										difference() {
											square([cr*2, cr*2], center=true);
											translate([cr,cr,0]) circle(r=cr, $fn=8);
										}
									}
								}
							}
						}
					}
				}
			}
		}
		children();
	}
}


// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
