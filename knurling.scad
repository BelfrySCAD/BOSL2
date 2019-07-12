//////////////////////////////////////////////////////////////////////
// LibFile: knurling.scad
//   Shapes and masks for knurling cylinders.
//   To use, add the following lines to the beginning of your file:
//   ```
//   include <BOSL2/std.scad>
//   include <BOSL2/knurling.scad>
//   ```
//////////////////////////////////////////////////////////////////////


// Section: Knurling


// Module: knurled_cylinder()
// Usage:
//   knurled_cylinder(l, r|d, [overage], [count], [profile], [helix]);
//   knurled_cylinder(l, r1|d1, r2|d2, [overage], [count], [profile], [helix]);
// Description:
//   Creates a mask to difference from a cylinder to give it a knurled surface.
// Arguments:
//   l = The length of the axis of the mask.  Default: 10
//   overage = Extra backing to the mask.  Default: 5
//   r = The radius of the cylinder to knurl.  Default: 10
//   r1 = The radius of the bottom of the conical cylinder to knurl.
//   r2 = The radius of the top of the conical cylinder to knurl.
//   d = The diameter of the cylinder to knurl.
//   d1 = The diameter of the bottom of the conical cylinder to knurl.
//   d2 = The diameter of the top of the conical cylinder to knurl.
//   count = The number of grooves to have around the surface of the cylinder.  Default: 30
//   profile = The angle of the bottom of the groove, in degrees.  Default 120
//   helix = The helical angle of the grooves, in degrees.  Default: 30
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards.  See [orient](attachments.scad#orient).  Default: `UP`
// Examples:
//   knurled_cylinder(l=30, r=20, profile=120, helix=45);
//   knurled_cylinder(l=30, r=20, profile=120, helix=30);
//   knurled_cylinder(l=30, r=20, profile=90, helix=30);
module knurled_cylinder(
	l=20,
	r=undef, r1=undef, r2=undef,
	d=undef, d1=undef, d2=undef,
	count=30, profile=120, helix=30,
	anchor=CENTER, spin=0, orient=UP
) {
	r1 = get_radius(r1=r1,r=r,d1=d1,d=d,dflt=10);
	r2 = get_radius(r1=r2,r=r,d1=d2,d=d,dflt=10);
	inset = r1 * sin(180/count) / tan(profile/2);
	twist = 360*l*tan(helix)/(r1*2*PI);
	c1 = circle(r=r1,$fn=count);
	c2 = rot(-180/count,p=circle(r=r1-inset,$fn=count));
	path = [for (i=idx(c1)) each [c1[i],c2[i]]];
	knob_w = 2*PI*r1/count;
	knob_h = knob_w / tan(helix);
	orient_and_anchor([2*r1,2*r1,l], size2=[2*r2,2*r2], anchor=anchor, spin=spin, orient=orient, geometry="cylinder", chain=true) {
		intersection() {
			linear_extrude(height=l, center=true, convexity=10, twist=twist, scale=r2/r1, slices=l/knob_h*2) {
				polygon(path);
			}
			linear_extrude(height=l, center=true, convexity=10, twist=-twist, scale=r2/r1, slices=l/knob_h*2) {
				polygon(path);
			}
		}
		children();
	}
}


// Module: knurled_cylinder_mask()
// Usage:
//   knurled_cylinder_mask(l, r|d, [overage], [count], [profile], [helix]);
//   knurled_cylinder_mask(l, r1|d1, r2|d2, [overage], [count], [profile], [helix]);
// Description:
//   Creates a mask to difference from a cylinder to give it a knurled surface.
// Arguments:
//   l = The length of the axis of the mask.  Default: 10
//   overage = Extra backing to the mask.  Default: 5
//   r = The radius of the cylinder to knurl.  Default: 10
//   r1 = The radius of the bottom of the conical cylinder to knurl.
//   r2 = The radius of the top of the conical cylinder to knurl.
//   d = The diameter of the cylinder to knurl.
//   d1 = The diameter of the bottom of the conical cylinder to knurl.
//   d2 = The diameter of the top of the conical cylinder to knurl.
//   count = The number of grooves to have around the surface of the cylinder.  Default: 30
//   profile = The angle of the bottom of the groove, in degrees.  Default 120
//   helix = The helical angle of the grooves, in degrees.  Default: 30
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards.  See [orient](attachments.scad#orient).  Default: `UP`
// Examples:
//   knurled_cylinder_mask(l=30, r=20, overage=5, profile=120, helix=30);
//   knurled_cylinder_mask(l=30, r=20, overage=10, profile=120, helix=30);
module knurled_cylinder_mask(
	l=10, overage=5,
	r=undef, r1=undef, r2=undef,
	d=undef, d1=undef, d2=undef,
	count=30, profile=120, helix=30,
	anchor=CENTER, spin=0, orient=UP
) {
	r1 = get_radius(r1=r1,r=r,d1=d1,d=d,dflt=10);
	r2 = get_radius(r1=r2,r=r,d1=d2,d=d,dflt=10);
	orient_and_anchor([2*r1,2*r1,l], size2=[2*r2,2*r2], anchor=anchor, spin=spin, orient=orient, geometry="cylinder", chain=true) {
		difference() {
			cylinder(r1=r1+overage, r2=r2+overage, h=l, center=true);
			knurled_cylinder(r1=r1, r2=r2, l=l+0.01);
		}
		children();
	}
}


// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
