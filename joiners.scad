//////////////////////////////////////////////////////////////////////
// LibFile: joiners.scad
//   Snap-together joiners.
//   To use, add the following lines to the beginning of your file:
//   ```
//   include <BOSL2/std.scad>
//   include <BOSL2/joiners.scad>
//   ```
//////////////////////////////////////////////////////////////////////


include <rounding.scad>
include <skin.scad>


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
            ycopies(overlap, n=overlap>0? 2 : 1) {
                difference() {
                    // Diamonds.
                    scale([w+clearance, dmnd_width/2, dmnd_height/2]) {
                        xrot(45) cube(size=[1,sqrt(2),sqrt(2)], center=true);
                    }
                    // Blunt point of tab.
                    ycopies(guide_width+4) {
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
                    xcopies(2*w*2/3) {
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
                    xcopies(w/3-$slop*2) {
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
        xcopies(spacing, n=n) {
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
//     attach(BACK) xcopies(10,5) dovetail("male", length=10, width=7, height=4);
// Example: Mating pin board for a right angle joint.  Note that the anchor method and use of `spin` ensures that the joint works even with a taper.
//   diff("remove")
//     cuboid([50,30,10])
//       position(TOP+BACK) xcopies(10,5) dovetail("female", length=10, width=7, taper=4, height=4, $tags="remove",anchor=BOTTOM+FRONT,spin=180);
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

    fullsize = round ? [size,size] :
        gender == "male" ? [size,0] : [0,size];

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
        method=type, cut = fullsize, closed=false
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
                slices=0, convexity=4
            );
        }
        children();
    }
}



// h is total height above 0 of the nub
// nub extends below xy plane by distance nub/2
module _pin_nub(r, nub, h)
{
    L = h / 4;
    rotate_extrude(){
      polygon(
       [[ 0,-nub/2],
        [-r,-nub/2],
        [-r-nub, nub/2],
        [-r-nub, nub/2+L],
        [-r, h],
        [0, h]]);
     }  
}


module _pin_slot(l, r, t, d, nub, depth, stretch) {
  yscale(4)
    intersection() {
      translate([t, 0, d + t / 4])
          _pin_nub(r = r + t, nub = nub, h = l - (d + t / 4));
      translate([-t, 0, d + t / 4]) 
          _pin_nub(r = r + t, nub = nub, h = l - (d + t / 4));
    }
  cube([2 * r, depth, 2 * l], center = true);
  up(l)
    zscale(stretch)
      ycyl(r = r, h = depth);
}


module _pin_shaft(r, lStraight, nub, nubscale, stretch, d, pointed)
{
   extra = 0.02;
   rPoint = r / sqrt(2);
   down(extra) cylinder(r = r, h = lStraight + extra);
   up(lStraight) {
      zscale(stretch) {
         sphere(r = r);
         if (pointed) up(rPoint) cylinder(r1 = rPoint, r2 = 0, h = rPoint);
      }
   }
   up(d) yscale(nubscale) _pin_nub(r = r, nub = nub, h = lStraight - d);
}

function _pin_size(size) =
  is_undef(size) ? [] :
  let(sizeok = in_list(size,["tiny", "small","medium", "large", "standard"]))
  assert(sizeok,"Pin size must be one of \"tiny\", \"small\", or \"standard\"")
  size=="standard" || size=="large" ?
     struct_set([], ["length", 10.8,
                     "diameter", 7,
                     "snap", 0.5,
                     "nub_depth", 1.8,
                     "thickness", 1.8,
                     "preload", 0.2]):
  size=="medium" ?
     struct_set([], ["length", 8,
                     "diameter", 4.6,
                     "snap", 0.45,
                     "nub_depth", 1.5,
                     "thickness", 1.4,
                     "preload", 0.2]) :
  size=="small" ? 
     struct_set([], ["length", 6, 
                     "diameter", 3.2,
                     "snap", 0.4,
                     "nub_depth", 1.2,
                     "thickness", 1.0,
                     "preload", 0.16]) :
  size=="tiny" ? 
     struct_set([], ["length", 4, 
                     "diameter", 2.5,
                     "snap", 0.25,
                     "nub_depth", 0.9,
                     "thickness", 0.8,
                     "preload", 0.1]):
  undef;


// Module: snap_pin()
// Usage:
//    snap_pin(size, [pointed], [anchor], [spin], [orient])
//    snap_pin(r|radius|d|diameter, l|length, nub_depth, snap, thickness, [clearance], [preload], [pointed], [anchor], [spin], [orient])
// Description:
//    Creates a snap pin that can be inserted into an appropriate socket to connect two objects together.  You can choose from some standard
//    pin dimensions by giving a size, or you can specify all the pin geometry parameters yourself.  If you use a standard size you can
//    override the standard parameters by specifying other ones.  The pins have flat sides so they can
//    be printed.  When oriented UP the shaft of the pin runs in the Z direction and the flat sides are the front and back.  The default
//    orientation (FRONT) and anchor (FRONT) places the pin in a printable configuration, flat side down on the xy plane.
//    The tightness of fit is determined by `preload` and `clearance`.  To make pins tighter increase `preload` and/or decrease `clearance`.  
//    .
//    The "large" or "standard" size pin has a length of 10.8 and diameter of 7.  The "medium" pin has a length of 8 and diameter of 4.6.  The "small" pin
//    has a length of 6 and diameter of 3.2.  The "tiny" pin has a length of 4 and a diameter of 2.5.  
//    .
//    This pin is based on https://www.thingiverse.com/thing:213310 by Emmett Lalishe
//    and a modified version at https://www.thingiverse.com/thing:3218332 by acwest
//    and distributed under the Creative Commons - Attribution - Share Alike License
// Arguments:
//    size = text string to select from a list of predefined sizes, one of "standard", "small", or "tiny".
//    pointed = set to true to get a pointed pin, false to get one with a rounded end.  Default: true
//    r|radius = radius of the pin
//    d|diameter = diameter of the pin
//    l|length = length of the pin
//    nub_depth = the distance of the nub from the base of the pin
//    snap = how much snap the pin provides (the nub projection)
//    thickness = thickness of the pin walls
//    pointed = if true the pin is pointed, otherwise it has a rounded tip.  Default: true
//    clearance = how far to shrink the pin away from the socket walls.  Default: 0.2
//    preload = amount to move the nub towards the pin base, which can create tension from the misalignment with the socket.  Default: 0.2
// Example: Pin in native orientation
//    snap_pin("standard", anchor=CENTER, orient=UP, thickness = 1, $fn=40);
// Example: Pins oriented for printing
//    xcopies(spacing=10, n=4) snap_pin("standard", $fn=40);
module snap_pin(size,r,radius,d,diameter, l,length, nub_depth, snap, thickness, clearance=0.2, preload, pointed=true, anchor=FRONT, spin=0, orient=FRONT, center) {
  preload_default = 0.2;
  sizedat = _pin_size(size);
  radius = get_radius(r1=r,r2=radius,d1=d,d2=diameter,dflt=struct_val(sizedat,"diameter")/2);
  length = first_defined([l,length,struct_val(sizedat,"length")]);
  snap = first_defined([snap, struct_val(sizedat,"snap")]);
  thickness = first_defined([thickness, struct_val(sizedat,"thickness")]);
  nub_depth = first_defined([nub_depth, struct_val(sizedat,"nub_depth")]);
  preload = first_defined([first_defined([preload, struct_val(sizedat, "preload")]),preload_default]);

  nubscale = 0.9;      // Mysterious arbitrary parameter

  // The basic pin assumes a rounded cap of length sqrt(2)*r, which defines lStraight.
  // If the point is enabled the cap length is instead 2*r
  // preload shrinks the length, bringing the nubs closer together  

  rInner = radius - clearance;
  stretch = sqrt(2)*radius/rInner;  // extra stretch factor to make cap have proper length even though r is reduced.
  lStraight = length - sqrt(2) * radius - clearance;
  lPin = lStraight + (pointed ? 2*radius : sqrt(2)*radius);
  attachable(anchor=anchor,spin=spin, orient=orient,
             size=[nubscale*(2*rInner+2*snap + clearance),radius*sqrt(2)-2*clearance,2*lPin]){
  zflip_copy()
      difference() {
        intersection() {
            cube([3 * (radius + snap), radius * sqrt(2) - 2 * clearance, 2 * length + 3 * radius], center = true);
            _pin_shaft(rInner, lStraight, snap+clearance/2, nubscale, stretch, nub_depth-preload, pointed);
        }
        _pin_slot(l = lStraight, r = rInner - thickness, t = thickness, d = nub_depth - preload, nub = snap, depth = 2 * radius + 0.02, stretch = stretch);
      }
  children();
  }
}

// Module: snap_pin_socket()
// Usage:
//   snap_pin_socket(size, [fixed], [fins], [pointed], [anchor], [spin], [orient]);
//   snap_pin_socket(r|radius|d|diameter, l|length, nub_depth, snap, [fixed], [pointed], [fins], [anchor], [spin], [orient])
// Description:
//   Constructs a socket suitable for a snap_pin with the same parameters.   If `fixed` is true then the socket has flat walls and the
//   pin will not rotate in the socket.  If `fixed` is false then the socket is round and the pin will rotate, particularly well
//   if you add a lubricant.  If `pointed` is true the socket is pointed to receive a pointed pin, otherwise it has a rounded and and
//   will be shorter.  If `fins` is set to true then two fins are included inside the socket to act as supports (which may help when printing tip up,
//   especially when `pointed=false`).  The default orientation is DOWN with anchor BOTTOM so that you can difference() the socket away from an object.
//   .
//   The "large" or "standard" size pin has a length of 10.8 and diameter of 7.  The "medium" pin has a length of 8 and diameter of 4.6.  The "small" pin
//   has a length of 6 and diameter of 3.2.  The "tiny" pin has a length of 4 and a diameter of 2.5.  
// Arguments:
//   size = text string to select from a list of predefined sizes, one of "standard", "small", or "tiny".
//   pointed = set to true to get a pointed pin, false to get one with a rounded end.  Default: true
//   r|radius = radius of the pin
//   d|diameter = diameter of the pin
//   l|length = length of the pin
//   nub_depth = the distance of the nub from the base of the pin
//   snap = how much snap the pin provides (the nub projection)
//   fixed = if true the pin cannot rotate, if false it can.  Default: true
//   pointed = if true the socket has a pointed tip.  Default: true
//   fins = if true supporting fins are included.  Default: false
// Example:  The socket shape itself in native orientation.
//   snap_pin_socket("standard", anchor=CENTER, orient=UP, fins=true, $fn=40);
// Example:  A spinning socket with fins:
//   snap_pin_socket("standard", anchor=CENTER, orient=UP, fins=true, fixed=false, $fn=40);
// Example:  A cube with a socket in the middle and one half-way off the front edge so you can see inside:
//   $fn=40;
//   diff("socket") cuboid([20,20,20]) {
//     attach(TOP) snap_pin_socket("standard", $tags="socket");
//     position(TOP+FRONT)snap_pin_socket("standard", $tags="socket");
//   }  
module snap_pin_socket(size, r, radius, l,length, d,diameter,nub_depth, snap, fixed=true, pointed=true, fins=false, anchor=BOTTOM, spin=0, orient=DOWN) {
  sizedat = _pin_size(size);
  radius = get_radius(r1=r,r2=radius,d1=d,d2=diameter,dflt=struct_val(sizedat,"diameter")/2);
  length = first_defined([l,length,struct_val(sizedat,"length")]);
  snap = first_defined([snap, struct_val(sizedat,"snap")]);
  nub_depth = first_defined([nub_depth, struct_val(sizedat,"nub_depth")]);

  tip = pointed ? sqrt(2) * radius : radius;
  lPin = length + (pointed?(2-sqrt(2))*radius:0);
  lStraight = lPin - (pointed?sqrt(2)*radius:radius);
  attachable(anchor=anchor,spin=spin,orient=orient,
             size=[2*(radius+snap),radius*sqrt(2),lPin])
  {  
  down(lPin/2)
    intersection() {
      if (fixed) 
        cube([3 * (radius + snap), radius * sqrt(2), 3 * lPin + 3 * radius], center = true);
      union() {
        _pin_shaft(radius,lStraight,snap,1,1,nub_depth,pointed);
        if (fins) 
          up(lStraight){
            cube([2 * radius, 0.01, 2 * tip], center = true);
            cube([0.01, 2 * radius, 2 * tip], center = true);
          }
      }
    }
  children();
  } 
}




// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
