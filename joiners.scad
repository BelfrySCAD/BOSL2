//////////////////////////////////////////////////////////////////////
// LibFile: joiners.scad
//   Snap-together joiners.
//   To use, add the following lines to the beginning of your file:
//   ```
//   include <BOSL2/std.scad>
//   include <BOSL2/joiners.scad>
//   ```
//////////////////////////////////////////////////////////////////////


include <BOSL2/rounding.scad>
include <BOSL2/skin.scad>


// Section: Half Joiners


// Module: half_joiner_clear()
// Description:
//   Creates a mask to clear an area so that a half_joiner can be placed there.
// Usage:
//   half_joiner_clear(h, w, [a], [clearance], [overlap])
// Arguments:
//   h = Height of the joiner to clear space for.
//   w = Width of the joiner to clear space for.
//   a = Overhang angle of the joiner.
//   clearance = Extra width to clear.
//   overlap = Extra depth to clear.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
// Example:
//   half_joiner_clear(spin=-90);
module half_joiner_clear(h=20, w=10, a=30, clearance=0, overlap=0.01, anchor=CENTER, spin=0, orient=UP)
{
	dmnd_height = h*1.0;
	dmnd_width = dmnd_height*tan(a);
	guide_size = w/3;
	guide_width = 2*(dmnd_height/2-guide_size)*tan(a);

	attachable(anchor,spin,orient, size=[w, guide_width, h]) {
		union() {
			yspread(overlap, n=overlap>0? 2 : 1) {
				difference() {
					// Diamonds.
					scale([w+clearance, dmnd_width/2, dmnd_height/2]) {
						xrot(45) cube(size=[1,sqrt(2),sqrt(2)], center=true);
					}
					// Blunt point of tab.
					yspread(guide_width+4) {
						cube(size=[(w+clearance)*1.05, 4, h*0.99], center=true);
					}
				}
			}
			if (overlap>0) cube([w+clearance, overlap+0.001, h], center=true);
		}
		children();
	}
}



// Module: half_joiner()
// Usage:
//   half_joiner(h, w, l, [a], [screwsize], [guides], [$slop])
// Description:
//   Creates a half_joiner object that can be attached to half_joiner2 object.
// Arguments:
//   h = Height of the half_joiner.
//   w = Width of the half_joiner.
//   l = Length of the backing to the half_joiner.
//   a = Overhang angle of the half_joiner.
//   screwsize = Diameter of screwhole.
//   guides = If true, create sliding alignment guides.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
//   $slop = Printer specific slop value to make parts fit more closely.
// Example:
//   half_joiner(screwsize=3, spin=-90);
module half_joiner(h=20, w=10, l=10, a=30, screwsize=undef, guides=true, anchor=CENTER, spin=0, orient=UP)
{
	dmnd_height = h*1.0;
	dmnd_width = dmnd_height*tan(a);
	guide_size = w/3;
	guide_width = 2*(dmnd_height/2-guide_size)*tan(a);

	render(convexity=12)
	attachable(anchor,spin,orient, size=[w, 2*l, h]) {
		difference() {
			union() {
				// Make base.
				difference() {
					// Solid backing base.
					fwd(l/2) cube(size=[w, l, h], center=true);

					// Clear diamond for tab
					xspread(2*w*2/3) {
						half_joiner_clear(h=h+0.01, w=w, clearance=$slop*2, a=a);
					}
				}

				difference() {
					// Make tab
					scale([w/3-$slop*2, dmnd_width/2, dmnd_height/2]) xrot(45)
						cube(size=[1,sqrt(2),sqrt(2)], center=true);

					// Blunt point of tab.
					back(guide_width/2+2)
						cube(size=[w*0.99,4,guide_size*2], center=true);
				}


				// Guide ridges.
				if (guides == true) {
					xspread(w/3-$slop*2) {
						// Guide ridge.
						fwd(0.05/2) {
							scale([0.75, 1, 2]) yrot(45)
								cube(size=[guide_size/sqrt(2), guide_width+0.05, guide_size/sqrt(2)], center=true);
						}

						// Snap ridge.
						scale([0.25, 0.5, 1]) zrot(45)
							cube(size=[guide_size/sqrt(2), guide_size/sqrt(2), dmnd_width], center=true);
					}
				}
			}

			// Make screwholes, if needed.
			if (screwsize != undef) {
				yrot(90) cylinder(r=screwsize*1.1/2, h=w+1, center=true, $fn=12);
			}
		}
		children();
	}
}
//half_joiner(screwsize=3);



// Module: half_joiner2()
// Usage:
//   half_joiner2(h, w, l, [a], [screwsize], [guides])
// Description:
//   Creates a half_joiner2 object that can be attached to half_joiner object.
// Arguments:
//   h = Height of the half_joiner.
//   w = Width of the half_joiner.
//   l = Length of the backing to the half_joiner.
//   a = Overhang angle of the half_joiner.
//   screwsize = Diameter of screwhole.
//   guides = If true, create sliding alignment guides.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
// Example:
//   half_joiner2(screwsize=3, spin=-90);
module half_joiner2(h=20, w=10, l=10, a=30, screwsize=undef, guides=true, anchor=CENTER, spin=0, orient=UP)
{
	dmnd_height = h*1.0;
	dmnd_width = dmnd_height*tan(a);
	guide_size = w/3;
	guide_width = 2*(dmnd_height/2-guide_size)*tan(a);

	render(convexity=12)
	attachable(anchor,spin,orient, size=[w, 2*l, h]) {
		difference() {
			union () {
				fwd(l/2) cube(size=[w, l, h], center=true);
				cube([w, guide_width, h], center=true);
			}

			// Subtract mated half_joiner.
			zrot(180) half_joiner(h=h+0.01, w=w+0.01, l=guide_width+0.01, a=a, screwsize=undef, guides=guides, $slop=0.0);

			// Make screwholes, if needed.
			if (screwsize != undef) {
				xcyl(r=screwsize*1.1/2, l=w+1, $fn=12);
			}
		}
		children();
	}
}



// Section: Full Joiners


// Module: joiner_clear()
// Description:
//   Creates a mask to clear an area so that a joiner can be placed there.
// Usage:
//   joiner_clear(h, w, [a], [clearance], [overlap])
// Arguments:
//   h = Height of the joiner to clear space for.
//   w = Width of the joiner to clear space for.
//   a = Overhang angle of the joiner.
//   clearance = Extra width to clear.
//   overlap = Extra depth to clear.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
// Example:
//   joiner_clear(spin=-90);
module joiner_clear(h=40, w=10, a=30, clearance=0, overlap=0.01, anchor=CENTER, spin=0, orient=UP)
{
	dmnd_height = h*0.5;
	dmnd_width = dmnd_height*tan(a);
	guide_size = w/3;
	guide_width = 2*(dmnd_height/2-guide_size)*tan(a);

	attachable(anchor,spin,orient, size=[w, guide_width, h]) {
		union() {
			up(h/4) half_joiner_clear(h=h/2.0-0.01, w=w, a=a, overlap=overlap, clearance=clearance);
			down(h/4) half_joiner_clear(h=h/2.0-0.01, w=w, a=a, overlap=overlap, clearance=-0.01);
		}
		children();
	}
}



// Module: joiner()
// Usage:
//   joiner(h, w, l, [a], [screwsize], [guides], [$slop])
// Description:
//   Creates a joiner object that can be attached to another joiner object.
// Arguments:
//   h = Height of the joiner.
//   w = Width of the joiner.
//   l = Length of the backing to the joiner.
//   a = Overhang angle of the joiner.
//   screwsize = Diameter of screwhole.
//   guides = If true, create sliding alignment guides.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
//   $slop = Printer specific slop value to make parts fit more closely.
// Examples:
//   joiner(screwsize=3, spin=-90);
//   joiner(w=10, l=10, h=40, spin=-90) cuboid([10, 10*2, 40], anchor=RIGHT);
module joiner(h=40, w=10, l=10, a=30, screwsize=undef, guides=true, anchor=CENTER, spin=0, orient=UP)
{
	attachable(anchor,spin,orient, size=[w, 2*l, h]) {
		union() {
			up(h/4) half_joiner(h=h/2, w=w, l=l, a=a, screwsize=screwsize, guides=guides);
			down(h/4) half_joiner2(h=h/2, w=w, l=l, a=a, screwsize=screwsize, guides=guides);
		}
		children();
	}
}



// Section: Full Joiners Pairs/Sets


// Module: joiner_pair_clear()
// Description:
//   Creates a mask to clear an area so that a pair of joiners can be placed there.
// Usage:
//   joiner_pair_clear(spacing, [n], [h], [w], [a], [clearance], [overlap])
// Arguments:
//   spacing = Spacing between joiner centers.
//   h = Height of the joiner to clear space for.
//   w = Width of the joiner to clear space for.
//   a = Overhang angle of the joiner.
//   n = Number of joiners (2 by default) to clear for.
//   clearance = Extra width to clear.
//   overlap = Extra depth to clear.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
// Examples:
//   joiner_pair_clear(spacing=50, n=2);
//   joiner_pair_clear(spacing=50, n=3);
module joiner_pair_clear(spacing=100, h=40, w=10, a=30, n=2, clearance=0, overlap=0.01, anchor=CENTER, spin=0, orient=UP)
{
	dmnd_height = h*0.5;
	dmnd_width = dmnd_height*tan(a);
	guide_size = w/3;
	guide_width = 2*(dmnd_height/2-guide_size)*tan(a);

	attachable(anchor,spin,orient, size=[spacing+w, guide_width, h]) {
		xspread(spacing, n=n) {
			joiner_clear(h=h, w=w, a=a, clearance=clearance, overlap=overlap);
		}
		children();
	}
}



// Module: joiner_pair()
// Usage:
//   joiner_pair(h, w, l, [a], [screwsize], [guides], [$slop])
// Description:
//   Creates a joiner_pair object that can be attached to other joiner_pairs .
// Arguments:
//   spacing = Spacing between joiner centers.
//   h = Height of the joiners.
//   w = Width of the joiners.
//   l = Length of the backing to the joiners.
//   a = Overhang angle of the joiners.
//   n = Number of joiners in a row.  Default: 2
//   alternate = If true (default), each joiner alternates it's orientation.  If alternate is "alt", do opposite alternating orientations.
//   screwsize = Diameter of screwhole.
//   guides = If true, create sliding alignment guides.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
//   $slop = Printer specific slop value to make parts fit more closely.
// Examples:
//   joiner_pair(spacing=50, l=10, spin=-90) cuboid([10, 50+10-0.1, 40], anchor=RIGHT);
//   joiner_pair(spacing=50, l=10, n=2, spin=-90);
//   joiner_pair(spacing=50, l=10, n=3, alternate=false, spin=-90);
//   joiner_pair(spacing=50, l=10, n=3, alternate=true, spin=-90);
//   joiner_pair(spacing=50, l=10, n=3, alternate="alt", spin=-90);
module joiner_pair(spacing=100, h=40, w=10, l=10, a=30, n=2, alternate=true, screwsize=undef, guides=true, anchor=CENTER, spin=0, orient=UP)
{
	attachable(anchor,spin,orient, size=[spacing+w, 2*l, h]) {
		left((n-1)*spacing/2) {
			for (i=[0:1:n-1]) {
				right(i*spacing) {
					yrot(180 + (alternate? (i*180+(alternate=="alt"?180:0))%360 : 0)) {
						joiner(h=h, w=w, l=l, a=a, screwsize=screwsize, guides=guides);
					}
				}
			}
		}
		children();
	}
}



// Section: Full Joiners Quads/Sets


// Module: joiner_quad_clear()
// Description:
//   Creates a mask to clear an area so that a pair of joiners can be placed there.
// Usage:
//   joiner_quad_clear(spacing, [n], [h], [w], [a], [clearance], [overlap])
// Arguments:
//   spacing1 = Spacing between joiner centers.
//   spacing2 = Spacing between back-to-back pairs/sets of joiners.
//   h = Height of the joiner to clear space for.
//   w = Width of the joiner to clear space for.
//   a = Overhang angle of the joiner.
//   n = Number of joiners in a row.  Default: 2
//   clearance = Extra width to clear.
//   overlap = Extra depth to clear.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
// Examples:
//   joiner_quad_clear(spacing1=50, spacing2=50, n=2);
//   joiner_quad_clear(spacing1=50, spacing2=50, n=3);
module joiner_quad_clear(xspacing=undef, yspacing=undef, spacing1=undef, spacing2=undef, n=2, h=40, w=10, a=30, clearance=0, overlap=0.01, anchor=CENTER, spin=0, orient=UP)
{
	spacing1 = first_defined([spacing1, xspacing, 100]);
	spacing2 = first_defined([spacing2, yspacing, 50]);
	attachable(anchor,spin,orient, size=[w+spacing1, spacing2, h]) {
		zrot_copies(n=2) {
			back(spacing2/2) {
				joiner_pair_clear(spacing=spacing1, n=n, h=h, w=w, a=a, clearance=clearance, overlap=overlap);
			}
		}
		children();
	}
}



// Module: joiner_quad()
// Usage:
//   joiner_quad(h, w, l, [a], [screwsize], [guides], [$slop])
// Description:
//   Creates a joiner_quad object that can be attached to other joiner_pairs .
// Arguments:
//   spacing = Spacing between joiner centers.
//   h = Height of the joiners.
//   w = Width of the joiners.
//   l = Length of the backing to the joiners.
//   a = Overhang angle of the joiners.
//   n = Number of joiners in a row.  Default: 2
//   alternate = If true (default), each joiner alternates it's orientation.  If alternate is "alt", do opposite alternating orientations.
//   screwsize = Diameter of screwhole.
//   guides = If true, create sliding alignment guides.
//   $slop = Printer specific slop value to make parts fit more closely.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
// Examples:
//   joiner_quad(spacing1=50, spacing2=50, l=10, spin=-90) cuboid([50, 50+10-0.1, 40]);
//   joiner_quad(spacing1=50, spacing2=50, l=10, n=2, spin=-90);
//   joiner_quad(spacing1=50, spacing2=50, l=10, n=3, alternate=false, spin=-90);
//   joiner_quad(spacing1=50, spacing2=50, l=10, n=3, alternate=true, spin=-90);
//   joiner_quad(spacing1=50, spacing2=50, l=10, n=3, alternate="alt", spin=-90);
module joiner_quad(spacing1=undef, spacing2=undef, xspacing=undef, yspacing=undef, h=40, w=10, l=10, a=30, n=2, alternate=true, screwsize=undef, guides=true, anchor=CENTER, spin=0, orient=UP)
{
	spacing1 = first_defined([spacing1, xspacing, 100]);
	spacing2 = first_defined([spacing2, yspacing, 50]);
	attachable(anchor,spin,orient, size=[w+spacing1, spacing2, h]) {
		zrot_copies(n=2) {
			back(spacing2/2) {
				joiner_pair(spacing=spacing1, n=n, h=h, w=w, l=l, a=a, screwsize=screwsize, guides=guides);
			}
		}
		children();
	}
}


// Section: Dovetails

// Module: dovetail()
//
// Usage:
//   dovetail(l|length, h|height, w|width, slope|angle, taper|back_width, [chamfer], [r|radius], [round], [$slop])
//
// Description:
//   Produces a possibly tapered dovetail joint shape to attach to or subtract from two parts you wish to join together.
//   The tapered dovetail is particularly advantageous for long joints because the joint assembles without binding until
//   it is fully closed, and then wedges tightly.  You can chamfer or round the corners of the dovetail shape for better
//   printing and assembly, or choose a fully rounded joint that looks more like a puzzle piece.  The dovetail appears 
//   parallel to the Y axis and projecting upwards, so in its default orientation it will slide together with a translation
//   in the positive Y direction.  The default anchor for dovetails is BOTTOM; the default orientation depends on the gender,
//   with male dovetails oriented UP and female ones DOWN.  
//
// Arguments:
//   l / length = Length of the dovetail (amount the joint slides during assembly)
//   h / height = Height of the dovetail
//   w / width = Width (at the wider, top end) of the dovetail before tapering
//   slope = slope of the dovetail.  Standard woodworking slopes are 4, 6, or 8.  Default: 6.  
//   angle = angle (in degrees) of the dovetail.  Specify only one of slope and angle.
//   taper = taper angle (in degrees). Dovetail gets narrower by this angle.  Default: no taper
//   back_width = width of right hand end of the dovetail.  This alternate method of specifying the taper may be easier to manage.  Specify only one of `taper` and `back_width`.  Note that `back_width` should be smaller than `width` to taper in the customary direction, with the smaller end at the back.  
//   chamfer = amount to chamfer the corners of the joint (Default: no chamfer)
//   r / radius = amount to round over the corners of the joint (Default: no rounding)
//   round = true to round both corners of the dovetail and give it a puzzle piece look.  Default: false.  
//   extra = amount of extra length and base extension added to dovetails for unions and differences.  Default: 0.01
// Example: Ordinary straight dovetail, male version (sticking up) and female version (below the xy plane)
//   dovetail("male", length=30, width=15, height=8);
//   right(20) dovetail("female", length=30, width=15, height=8);
// Example: Adding a 6 degree taper (Such a big taper is usually not necessary, but easier to see for the example.)
//   dovetail("male", length=30, width=15, height=8, taper=6);
//   right(20) dovetail("female", length=30, width=15, height=8, taper=6);
// Example: A block that can link to itself
//   diff("remove")
//     cuboid([50,30,10]){
//       attach(BACK) dovetail("male", length=10, width=15, height=8);
//       attach(FRONT) dovetail("female", length=10, width=15, height=8,$tags="remove");
//     }
// Example: Setting the dovetail angle.  This is too extreme to be useful.  
//   diff("remove")
//     cuboid([50,30,10]){
//       attach(BACK) dovetail("male", length=10, width=15, height=8,angle=30);
//       attach(FRONT) dovetail("female", length=10, width=15, height=8,angle=30,$tags="remove");
//     }
// Example: Adding a chamfer helps printed parts fit together without problems at the corners
//   diff("remove")
//     cuboid([50,30,10]){
//       attach(BACK) dovetail("male", length=10, width=15, height=8,chamfer=1);
//       attach(FRONT) dovetail("female", length=10, width=15, height=8,chamfer=1,$tags="remove");
//     }
// Example: Rounding the outside corners is another option
//   diff("remove")
//     cuboid([50,30,10]){
//       attach(BACK) dovetail("male", length=10, width=15, height=8,radius=1,$fn=32);
//       attach(FRONT) dovetail("female", length=10, width=15, height=8,radius=1,$tags="remove",$fn=32);
//     }
// Example: Or you can make a fully rounded joint
//   $fn=32;
//   diff("remove")
//     cuboid([50,30,10]){
//       attach(BACK) dovetail("male", length=10, width=15, height=8,radius=1.5, round=true);
//       attach(FRONT) dovetail("female", length=10, width=15, height=8,radius=1.5, round=true, $tags="remove");
//   }
// Example: With a long joint like this, a taper makes the joint easy to assemble.  It will go together easily and wedge tightly if you get the tolerances right.  Specifying the taper with `back_width` may be easier than using a taper angle.  
//   cuboid([50,30,10])
//     attach(TOP) dovetail("male", length=50, width=18, height=4, back_width=15, spin=90);
//   fwd(35)
//     diff("remove")
//       cuboid([50,30,10])
//         attach(TOP) dovetail("female", length=50, width=18, height=4, back_width=15, spin=90,$tags="remove");
// Example: A series of dovtails
//   cuboid([50,30,10])
//     attach(BACK) xspread(10,5) dovetail("male", length=10, width=7, height=4);
// Example: Mating pin board for a right angle joint.  Note that the anchor method and use of `spin` ensures that the joint works even with a taper.
//   diff("remove")
//     cuboid([50,30,10])
//       position(TOP+BACK) xspread(10,5) dovetail("female", length=10, width=7, taper=4, height=4, $tags="remove",anchor=BOTTOM+FRONT,spin=180);
module dovetail(gender, length, l, width, w, height, h, angle, slope, taper, back_width, chamfer, extra=0.01, r, radius, round=false, anchor=BOTTOM, spin=0, orient)
{
	radius = get_radius(r1=radius,r2=r);
	lcount = num_defined([l,length]);
	hcount = num_defined([h,height]);
	wcount = num_defined([w,width]);
	assert(lcount==1, "Must define exactly one of l and length");
	assert(wcount==1, "Must define exactly one of w and width");
	assert(hcount==1, "Must define exactly one of h and height");
	h = first_defined([h,height]);
	w = first_defined([w,width]);
	length = first_defined([l,length]);
	orient = is_def(orient) ? orient :
		gender == "female" ? DOWN : UP;
	count = num_defined([angle,slope]);
	assert(count<=1, "Do not specify both angle and slope");
	count2 = num_defined([taper,back_width]);
	assert(count2<=1, "Do not specify both taper and back_width");
	count3 = num_defined([chamfer, radius]);
	assert(count3<=1 || (radius==0 && chamfer==0), "Do not specify both chamfer and radius");
	slope = is_def(slope) ? slope :
		is_def(angle) ? 1/tan(angle) :  6;
	width = gender == "male" ? w : w + 2*$slop;
	height = h + (gender == "female" ? 2*$slop : 0);

	front_offset = is_def(taper) ? -extra * tan(taper) :
		is_def(back_width) ? extra * (back_width-width)/length/2 : 0;

	size = is_def(chamfer) && chamfer>0 ? chamfer :
		is_def(radius) && radius>0 ? radius : 0;
	type = is_def(chamfer) && chamfer>0 ? "chamfer" : "circle";

	fullsize = round ? [0,size,size] :
		gender == "male" ? [0,size,0] : [0,0,size];

	smallend_half = round_corners(
		move(
			[0,-length/2-extra,0],
			p=[
				[0                     , 0, height],
				[width/2-front_offset  , 0, height],
				[width/2 - height/slope - front_offset, 0, 0 ],
				[width/2 - front_offset + height, 0, 0]
			]
		),
		curve=type, size=fullsize, closed=false
	);
	smallend_points = concat(select(smallend_half, 1, -2), [down(extra,p=select(smallend_half, -2))]);
	offset = is_def(taper) ? -(length+extra) * tan(taper) :
		is_def(back_width) ? (back_width-width) / 2 : 0;
	bigend_points = move([offset,length+2*extra,0], p=smallend_points);

	adjustment = gender == "male" ? -0.01 : 0.01;  // Adjustment for default overlap in attach()

	attachable(anchor,spin,orient, size=[width+2*offset, length, height]) {
		down(height/2+adjustment) {
			skin(
				[
					reverse(concat(smallend_points, xflip(p=reverse(smallend_points)))),
					reverse(concat(bigend_points, xflip(p=reverse(bigend_points))))
				],
				convexity=4, slices=0
			);
		}
		children();
	}
}



// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
