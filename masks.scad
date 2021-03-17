//////////////////////////////////////////////////////////////////////
// LibFile: masks.scad
//   Masking shapes.
// Includes:
//   include <BOSL2/std.scad>
//////////////////////////////////////////////////////////////////////


// Section: General Masks

// Module: angle_pie_mask()
// Usage:
//   angle_pie_mask(r|d, l, ang, [excess]);
//   angle_pie_mask(r1|d1, r2|d2, l, ang, [excess]);
// Description:
//   Creates a pie wedge shape that can be used to mask other shapes.
// Arguments:
//   ang = angle of wedge in degrees.
//   l = height of wedge.
//   r = Radius of circle wedge is created from. (optional)
//   r1 = Bottom radius of cone that wedge is created from.  (optional)
//   r2 = Upper radius of cone that wedge is created from.  (optional)
//   d = Diameter of circle wedge is created from. (optional)
//   d1 = Bottom diameter of cone that wedge is created from.  (optional)
//   d2 = Upper diameter of cone that wedge is created from. (optional)
//   excess = The extra thickness of the mask.  Default: `0.1`.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
// Example(Render):
//   angle_pie_mask(ang=30, d=100, l=20);
module angle_pie_mask(
    ang=45, l=undef,
    r=undef, r1=undef, r2=undef,
    d=undef, d1=undef, d2=undef,
    h=undef, excess=0.1,
    anchor=CENTER, spin=0, orient=UP
) {
    l = first_defined([l, h, 1]);
    r1 = get_radius(r1=r1, r=r, d1=d1, d=d, dflt=10);
    r2 = get_radius(r1=r2, r=r, d1=d2, d=d, dflt=10);
    attachable(anchor,spin,orient, r1=r1, r2=r2, l=l) {
        pie_slice(ang=ang, l=l+excess, r1=r1, r2=r2, anchor=CENTER);
        children();
    }
}


// Module: cylinder_mask()
// Usage: Mask objects
//   cylinder_mask(l, r|d, chamfer, [chamfang], [from_end], [circum], [excess], [ends_only]);
//   cylinder_mask(l, r|d, rounding, [circum], [excess], [ends_only]);
//   cylinder_mask(l, r|d, [chamfer1|rounding1], [chamfer2|rounding2], [chamfang1], [chamfang2], [from_end], [circum], [excess], [ends_only]);
// Usage: Masking operators
//   cylinder_mask(l, r|d, chamfer, [chamfang], [from_end], [circum], [excess], [ends_only]) ...
//   cylinder_mask(l, r|d, rounding, [circum], [excess], [ends_only]) ...
//   cylinder_mask(l, r|d, [chamfer1|rounding1], [chamfer2|rounding2], [chamfang1], [chamfang2], [from_end], [circum], [excess], [ends_only]) ...
// Description:
//   If passed children, bevels/chamfers and/or rounds one or both
//   ends of the origin-centered cylindrical region specified.  If
//   passed no children, creates a mask to bevel/chamfer and/or round
//   one or both ends of the cylindrical region.  Difference the mask
//   from the region, making sure the center of the mask object is
//   anchored exactly with the center of the cylindrical region to
//   be chamfered.
// Arguments:
//   l = Length of the cylindrical/conical region.
//   r = Radius of cylindrical region to chamfer.
//   r1 = Radius of axis-negative end of the region to chamfer.
//   r2 = Radius of axis-positive end of the region to chamfer.
//   d = Diameter of cylindrical region to chamfer.
//   d1 = Diameter of axis-negative end of the region to chamfer.
//   d1 = Diameter of axis-positive end of the region to chamfer.
//   chamfer = Size of the chamfers/bevels. (Default: 0.25)
//   chamfer1 = Size of the chamfers/bevels for the axis-negative end of the region.
//   chamfer2 = Size of the chamfers/bevels for the axis-positive end of the region.
//   chamfang = Angle of chamfers/bevels in degrees from the length axis of the region.  (Default: 45)
//   chamfang1 = Angle of chamfer/bevel of the axis-negative end of the region, in degrees from the length axis.
//   chamfang2 = Angle of chamfer/bevel of the axis-positive end of the region, in degrees from the length axis.
//   rounding = The radius of the rounding on the ends of the region.  Default: none.
//   rounding1 = The radius of the rounding on the axis-negative end of the region.
//   rounding2 = The radius of the rounding on the axis-positive end of the region.
//   circum = If true, region will circumscribe the circle of the given radius/diameter.
//   from_end = If true, chamfer/bevel size is measured from end of region.  If false, chamfer/bevel is measured outset from the radius of the region.  (Default: false)
//   excess = The extra thickness of the mask.  Default: `10`.
//   ends_only = If true, only mask the ends and not around the middle of the cylinder.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
// Example:
//   difference() {
//       cylinder(h=100, r1=60, r2=30, center=true);
//       cylinder_mask(l=100, r1=60, r2=30, chamfer=10, from_end=true);
//   }
// Example:
//   cylinder_mask(l=100, r=50, chamfer1=10, rounding2=10) {
//       cube([100,50,100], center=true);
//   }
module cylinder_mask(
    l,
    r=undef, r1=undef, r2=undef,
    d=undef, d1=undef, d2=undef,
    chamfer=undef, chamfer1=undef, chamfer2=undef,
    chamfang=undef, chamfang1=undef, chamfang2=undef,
    rounding=undef, rounding1=undef, rounding2=undef,
    circum=false, from_end=false,
    excess=10, ends_only=false,
    anchor=CENTER, spin=0, orient=UP
) {
    r1 = get_radius(r=r, d=d, r1=r1, d1=d1, dflt=1);
    r2 = get_radius(r=r, d=d, r1=r2, d1=d2, dflt=1);
    sides = segs(max(r1,r2));
    sc = circum? 1/cos(180/sides) : 1;
    vang = atan2(l, r1-r2)/2;
    ang1 = first_defined([chamfang1, chamfang, vang]);
    ang2 = first_defined([chamfang2, chamfang, 90-vang]);
    cham1 = first_defined([chamfer1, chamfer]);
    cham2 = first_defined([chamfer2, chamfer]);
    fil1 = first_defined([rounding1, rounding]);
    fil2 = first_defined([rounding2, rounding]);
    maxd = max(r1,r2);
    if ($children > 0) {
        difference() {
            children();
            cylinder_mask(
                l=l, r1=sc*r1, r2=sc*r2,
                chamfer1=cham1, chamfer2=cham2,
                chamfang1=ang1, chamfang2=ang2,
                rounding1=fil1, rounding2=fil2,
                orient=orient, from_end=from_end
            );
        }
    } else {
        attachable(anchor,spin,orient, r=r1, l=l) {
            difference() {
                union() {
                    chlen1 = default(cham1,0) / (from_end? 1 : tan(ang1));
                    chlen2 = default(cham2,0) / (from_end? 1 : tan(ang2));
                    if (!ends_only) {
                        cylinder(r=maxd+excess, h=l+2*excess, center=true);
                    } else {
                        if (is_num(cham2) && cham2>0) up(l/2-chlen2)
                            cylinder(r=maxd+excess, h=chlen2+excess, center=false);
                        if (is_num(cham1) && cham1>0)
                            down(l/2+excess) cylinder(r=maxd+excess, h=chlen1+excess, center=false);
                        if (is_num(fil2) && fil2>0)
                            up(l/2-fil2) cylinder(r=maxd+excess, h=fil2+excess, center=false);
                        if (is_num(fil1) && fil1>0)
                            down(l/2+excess) cylinder(r=maxd+excess, h=fil1+excess, center=false);
                    }
                }
                cyl(
                    r1=sc*r1, r2=sc*r2, l=l,
                    chamfer1=cham1, chamfer2=cham2,
                    chamfang1=ang1, chamfang2=ang2,
                    from_end=from_end,
                    rounding1=fil1, rounding2=fil2
                );
            }
            children();
        }
    }
}



// Section: Chamfers


// Module: chamfer_mask()
// Usage:
//   chamfer_mask(l, chamfer, [excess]);
// Description:
//   Creates a shape that can be used to chamfer a 90 degree edge.
//   Difference it from the object to be chamfered.  The center of
//   the mask object should align exactly with the edge to be chamfered.
// Arguments:
//   l = Length of mask.
//   chamfer = Size of chamfer.
//   excess = The extra amount to add to the length of the mask so that it differences away from other shapes cleanly.  Default: `0.1`
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
// Example:
//   difference() {
//       cube(50, anchor=BOTTOM+FRONT);
//       #chamfer_mask(l=50, chamfer=10, orient=RIGHT);
//   }
module chamfer_mask(l=1, chamfer=1, excess=0.1, anchor=CENTER, spin=0, orient=UP) {
    attachable(anchor,spin,orient, size=[chamfer*2, chamfer*2, l]) {
        cylinder(r=chamfer, h=l+excess, center=true, $fn=4);
        children();
    }
}


// Module: chamfer_mask_x()
// Usage:
//   chamfer_mask_x(l, chamfer, [excess]);
// Description:
//   Creates a shape that can be used to chamfer a 90 degree edge along the X axis.
//   Difference it from the object to be chamfered.  The center of the mask
//   object should align exactly with the edge to be chamfered.
// Arguments:
//   l = Length of mask.
//   chamfer = Size of chamfer.
//   excess = The extra amount to add to the length of the mask so that it differences away from other shapes cleanly.  Default: `0.1`
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the X axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
// Example:
//   difference() {
//       cube(50, anchor=BOTTOM+FRONT);
//       #chamfer_mask_x(l=50, chamfer=10);
//   }
module chamfer_mask_x(l=1.0, chamfer=1.0, excess=0.1, anchor=CENTER, spin=0) {
    chamfer_mask(l=l, chamfer=chamfer, excess=excess, anchor=anchor, spin=spin, orient=RIGHT) children();
}


// Module: chamfer_mask_y()
// Usage:
//   chamfer_mask_y(l, chamfer, [excess]);
// Description:
//   Creates a shape that can be used to chamfer a 90 degree edge along the Y axis.
//   Difference it from the object to be chamfered.  The center of the mask
//   object should align exactly with the edge to be chamfered.
// Arguments:
//   l = Length of mask.
//   chamfer = Size of chamfer.
//   excess = The extra amount to add to the length of the mask so that it differences away from other shapes cleanly.  Default: `0.1`
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Y axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
// Example:
//   difference() {
//       cube(50, anchor=BOTTOM+RIGHT);
//       #chamfer_mask_y(l=50, chamfer=10);
//   }
module chamfer_mask_y(l=1.0, chamfer=1.0, excess=0.1, anchor=CENTER, spin=0) {
    chamfer_mask(l=l, chamfer=chamfer, excess=excess, anchor=anchor, spin=spin, orient=BACK) children();
}


// Module: chamfer_mask_z()
// Usage:
//   chamfer_mask_z(l, chamfer, [excess]);
// Description:
//   Creates a shape that can be used to chamfer a 90 degree edge along the Z axis.
//   Difference it from the object to be chamfered.  The center of the mask
//   object should align exactly with the edge to be chamfered.
// Arguments:
//   l = Length of mask.
//   chamfer = Size of chamfer.
//   excess = The extra amount to add to the length of the mask so that it differences away from other shapes cleanly.  Default: `0.1`
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
// Example:
//   difference() {
//       cube(50, anchor=FRONT+RIGHT);
//       #chamfer_mask_z(l=50, chamfer=10);
//   }
module chamfer_mask_z(l=1.0, chamfer=1.0, excess=0.1, anchor=CENTER, spin=0) {
    chamfer_mask(l=l, chamfer=chamfer, excess=excess, anchor=anchor, spin=spin, orient=UP) children();
}


// Module: chamfer()
// Usage:
//   chamfer(chamfer, size, [edges]) ...
// Description:
//   Chamfers the edges of a cuboid region containing the given children, centered on the origin.
// Arguments:
//   chamfer = Inset of the chamfer from the edge. (Default: 1)
//   size = The size of the rectangular cuboid we want to chamfer.
//   edges = Edges to chamfer.  See the docs for [`edges()`](edges.scad#edges) to see acceptable values.  Default: All edges.
//   except_edges = Edges to explicitly NOT chamfer.  See the docs for [`edges()`](edges.scad#edges) to see acceptable values.  Default: No edges.
// Example(Render):
//   chamfer(chamfer=2, size=[20,40,30]) {
//     cube(size=[20,40,30], center=true);
//   }
// Example(Render):
//   chamfer(chamfer=2, size=[20,40,30], edges=[TOP,FRONT+RIGHT], except_edges=TOP+LEFT) {
//     cube(size=[20,40,30], center=true);
//   }
module chamfer(chamfer=1, size=[1,1,1], edges=EDGES_ALL, except_edges=[])
{
    difference() {
        children();
        difference() {
            cube(size, center=true);
            cuboid(size+[1,1,1]*0.02, chamfer=chamfer+0.01, edges=edges, except_edges=except_edges, trimcorners=true);
        }
    }
}


// Module: chamfer_cylinder_mask()
// Usage:
//   chamfer_cylinder_mask(r|d, chamfer, [ang], [from_end])
// Description:
//   Create a mask that can be used to bevel/chamfer the end of a cylindrical region.
//   Difference it from the end of the region to be chamfered.  The center of the mask
//   object should align exactly with the center of the end of the cylindrical region
//   to be chamfered.
// Arguments:
//   r = Radius of cylinder to chamfer.
//   d = Diameter of cylinder to chamfer. Use instead of r.
//   chamfer = Size of the edge chamfered, inset from edge. (Default: 0.25)
//   ang = Angle of chamfer in degrees from vertical.  (Default: 45)
//   from_end = If true, chamfer size is measured from end of cylinder.  If false, chamfer is measured outset from the radius of the cylinder.  (Default: false)
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
// Example:
//   difference() {
//       cylinder(r=50, h=100, center=true);
//       up(50) #chamfer_cylinder_mask(r=50, chamfer=10);
//   }
// Example:
//   difference() {
//       cylinder(r=50, h=100, center=true);
//       up(50) chamfer_cylinder_mask(r=50, chamfer=10);
//   }
module chamfer_cylinder_mask(r=undef, d=undef, chamfer=0.25, ang=45, from_end=false, anchor=CENTER, spin=0, orient=UP)
{
    r = get_radius(r=r, d=d, dflt=1);
    attachable(anchor,spin,orient, r=r, l=chamfer*2) {
        cylinder_mask(l=chamfer*3, r=r, chamfer2=chamfer, chamfang2=ang, from_end=from_end, ends_only=true, anchor=TOP);
        children();
    }
}


// Module: chamfer_hole_mask()
// Usage:
//   chamfer_hole_mask(r|d, chamfer, [ang], [from_end], [excess]);
// Description:
//   Create a mask that can be used to bevel/chamfer the end of a cylindrical hole.
//   Difference it from the hole to be chamfered.  The center of the mask object
//   should align exactly with the center of the end of the hole to be chamfered.
// Arguments:
//   r = Radius of hole to chamfer.
//   d = Diameter of hole to chamfer. Use instead of r.
//   chamfer = Size of the chamfer. (Default: 0.25)
//   ang = Angle of chamfer in degrees from vertical.  (Default: 45)
//   from_end = If true, chamfer size is measured from end of hole.  If false, chamfer is measured outset from the radius of the hole.  (Default: false)
//   excess = The extra thickness of the mask.  Default: `0.1`.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
// Example:
//   difference() {
//       cube(100, center=true);
//       cylinder(d=50, h=100.1, center=true);
//       up(50) #chamfer_hole_mask(d=50, chamfer=10);
//   }
// Example:
//   difference() {
//       cube(100, center=true);
//       cylinder(d=50, h=100.1, center=true);
//       up(50) chamfer_hole_mask(d=50, chamfer=10);
//   }
// Example:
//   chamfer_hole_mask(d=100, chamfer=25, ang=30, excess=10);
module chamfer_hole_mask(r=undef, d=undef, chamfer=0.25, ang=45, from_end=false, excess=0.1, anchor=CENTER, spin=0, orient=UP)
{
    r = get_radius(r=r, d=d, dflt=1);
    h = chamfer * (from_end? 1 : tan(90-ang));
    r2 = r + chamfer * (from_end? tan(ang) : 1);
    $fn = segs(r);
    attachable(anchor,spin,orient, r1=r, r2=r2, l=h*2) {
        union() {
            cylinder(r=r2, h=excess, center=false);
            down(h) cylinder(r1=r, r2=r2, h=h, center=false);
        }
        children();
    }
}



// Section: Rounding

// Module: rounding_mask()
// Usage:
//   rounding_mask(l|h, r|d)
//   rounding_mask(l|h, r1|d1, r2|d2)
// Description:
//   Creates a shape that can be used to round a vertical 90 degree edge.
//   Difference it from the object to be rounded.  The center of the mask
//   object should align exactly with the edge to be rounded.
// Arguments:
//   l = Length of mask.
//   r = Radius of the rounding.
//   r1 = Bottom radius of rounding.
//   r2 = Top radius of rounding.
//   d = Diameter of the rounding.
//   d1 = Bottom diameter of rounding.
//   d2 = Top diameter of rounding.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
// Example:
//   difference() {
//       cube(size=100, center=false);
//       #rounding_mask(l=100, r=25, orient=UP, anchor=BOTTOM);
//   }
// Example: Varying Rounding Radius
//   difference() {
//       cube(size=100, center=false);
//       #rounding_mask(l=100, r1=25, r2=10, orient=UP, anchor=BOTTOM);
//   }
// Example: Masking by Attachment
//   diff("mask")
//   cube(100, center=true)
//       attach(FRONT+RIGHT)
//           #rounding_mask(l=$parent_size.z+0.01, r=25, spin=45, orient=BACK, $tags="mask");
// Example: Multiple Masking by Attachment
//   diff("mask")
//   cube([80,90,100], center=true) {
//       let(p = $parent_size*1.01, $tags="mask") {
//           attach([for (x=[-1,1],y=[-1,1]) [x,y,0]])
//               rounding_mask(l=p.z, r=25, spin=45, orient=BACK);
//           attach([for (x=[-1,1],z=[-1,1]) [x,0,z]])
//               chamfer_mask(l=p.y, chamfer=20, spin=45, orient=RIGHT);
//           attach([for (y=[-1,1],z=[-1,1]) [0,y,z]])
//               rounding_mask(l=p.x, r=25, spin=45, orient=RIGHT);
//       }
//   }
module rounding_mask(l, r, r1, r2, d, d1, d2, anchor=CENTER, spin=0, orient=UP, h=undef)
{
    l = first_defined([l, h, 1]);
    r1 = get_radius(r1=r1, r=r, d1=d1, d=d, dflt=1);
    r2 = get_radius(r1=r2, r=r, d1=d2, d=d, dflt=1);
    sides = quantup(segs(max(r1,r2)),4);
    attachable(anchor,spin,orient, size=[2*r1,2*r1,l], size2=[2*r2,2*r2]) {
        if (r1<r2) {
            zflip() {
                linear_extrude(height=l, convexity=4, center=true, scale=r1/r2) {
                    difference() {
                        square(2*r2, center=true);
                        xcopies(2*r2) ycopies(2*r2) circle(r=r2, $fn=sides);
                    }
                }
            }
        } else {
            linear_extrude(height=l, convexity=4, center=true, scale=r2/r1) {
                difference() {
                    square(2*r1, center=true);
                    xcopies(2*r1) ycopies(2*r1) circle(r=r1, $fn=sides);
                }
            }
        }
        children();
    }
}


// Module: rounding_mask_x()
// Usage:
//   rounding_mask_x(l, r|d, [anchor])
//   rounding_mask_x(l, r1|d1, r2|d2, [anchor])
// Description:
//   Creates a shape that can be used to round a 90 degree edge oriented
//   along the X axis.  Difference it from the object to be rounded.
//   The center of the mask object should align exactly with the edge to
//   be rounded.
// Arguments:
//   l = Length of mask.
//   r = Radius of the rounding.
//   r1 = Left end radius of rounding.
//   r2 = Right end radius of rounding.
//   d = Diameter of the rounding.
//   d1 = Left end diameter of rounding.
//   d2 = Right end diameter of rounding.
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
// Example:
//   difference() {
//       cube(size=100, center=false);
//       #rounding_mask_x(l=100, r=25, anchor=LEFT);
//   }
// Example: Varying Rounding Radius
//   difference() {
//       cube(size=100, center=false);
//       #rounding_mask_x(l=100, r1=10, r2=30, anchor=LEFT);
//   }
module rounding_mask_x(l=1.0, r, r1, r2, d, d1, d2, anchor=CENTER, spin=0)
{
    anchor = rot(p=anchor, from=RIGHT, to=TOP);
    rounding_mask(l=l, r=r, r1=r1, r2=r2, d=d, d1=d1, d2=d2, anchor=anchor, spin=spin, orient=RIGHT) {
        for (i=[0:1:$children-2]) children(i);
        if ($children) children($children-1);
    }
}


// Module: rounding_mask_y()
// Usage:
//   rounding_mask_y(l, r|d, [anchor])
//   rounding_mask_y(l, r1|d1, r2|d2, [anchor])
// Description:
//   Creates a shape that can be used to round a 90 degree edge oriented
//   along the Y axis.  Difference it from the object to be rounded.
//   The center of the mask object should align exactly with the edge to
//   be rounded.
// Arguments:
//   l = Length of mask.
//   r = Radius of the rounding.
//   r1 = Front end radius of rounding.
//   r2 = Back end radius of rounding.
//   d = Diameter of the rounding.
//   d1 = Front end diameter of rounding.
//   d2 = Back end diameter of rounding.
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
// Example:
//   difference() {
//       cube(size=100, center=false);
//       right(100) #rounding_mask_y(l=100, r=25, anchor=FRONT);
//   }
// Example: Varying Rounding Radius
//   difference() {
//       cube(size=100, center=false);
//       right(100) #rounding_mask_y(l=100, r1=10, r2=30, anchor=FRONT);
//   }
module rounding_mask_y(l=1.0, r, r1, r2, d, d1, d2, anchor=CENTER, spin=0)
{
    anchor = rot(p=anchor, from=BACK, to=TOP);
    rounding_mask(l=l, r=r, r1=r1, r2=r2, d=d, d1=d1, d2=d2, anchor=anchor, spin=spin, orient=BACK) {
        for (i=[0:1:$children-2]) children(i);
        if ($children) children($children-1);
    }
}


// Module: rounding_mask_z()
// Usage:
//   rounding_mask_z(l, r|d, [anchor])
//   rounding_mask_z(l, r1|d1, r2|d2, [anchor])
// Description:
//   Creates a shape that can be used to round a 90 degree edge oriented
//   along the Z axis.  Difference it from the object to be rounded.
//   The center of the mask object should align exactly with the edge to
//   be rounded.
// Arguments:
//   l = Length of mask.
//   r = Radius of the rounding.
//   r1 = Bottom radius of rounding.
//   r2 = Top radius of rounding.
//   d = Diameter of the rounding.
//   d1 = Bottom diameter of rounding.
//   d2 = Top diameter of rounding.
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
// Example:
//   difference() {
//       cube(size=100, center=false);
//       #rounding_mask_z(l=100, r=25, anchor=BOTTOM);
//   }
// Example: Varying Rounding Radius
//   difference() {
//       cube(size=100, center=false);
//       #rounding_mask_z(l=100, r1=10, r2=30, anchor=BOTTOM);
//   }
module rounding_mask_z(l=1.0, r, r1, r2, d, d1, d2, anchor=CENTER, spin=0)
{
    rounding_mask(l=l, r=r, r1=r1, r2=r2, d=d, d1=d1, d2=d2, anchor=anchor, spin=spin, orient=UP) {
        for (i=[0:1:$children-2]) children(i);
        if ($children) children($children-1);
    }
}


// Module: rounding()
// Usage:
//   rounding(r|d, size, [edges]) ...
// Description:
//   Rounds the edges of a cuboid region containing the given children.
// Arguments:
//   r = Radius of the rounding. (Default: 1)
//   d = Diameter of the rounding. (Default: 1)
//   size = The size of the rectangular cuboid we want to chamfer.
//   edges = Edges to round.  See the docs for [`edges()`](edges.scad#edges) to see acceptable values.  Default: All edges.
//   except_edges = Edges to explicitly NOT round.  See the docs for [`edges()`](edges.scad#edges) to see acceptable values.  Default: No edges.
// Example(Render):
//   rounding(r=10, size=[50,100,150], $fn=24) {
//     cube(size=[50,100,150], center=true);
//   }
// Example(FlatSpin,VPD=266):
//   rounding(r=10, size=[50,50,75], edges=[TOP,FRONT+RIGHT], except_edges=TOP+LEFT, $fn=24) {
//     cube(size=[50,50,75], center=true);
//   }
module rounding(r, size=[1,1,1], d, edges=EDGES_ALL, except_edges=[])
{
    r = get_radius(r=r, d=d, dflt=1);
    difference() {
        children();
        difference() {
            cube(size, center=true);
            cuboid(size+[1,1,1]*0.01, rounding=r, edges=edges, except_edges=except_edges, trimcorners=true);
        }
    }
}


// Module: rounding_angled_edge_mask()
// Usage:
//   rounding_angled_edge_mask(h, r|d, [ang]);
//   rounding_angled_edge_mask(h, r1|d1, r2|d2, [ang]);
// Description:
//   Creates a vertical mask that can be used to round the edge where two face meet, at any arbitrary
//   angle.  Difference it from the object to be rounded.  The center of the mask should align exactly
//   with the edge to be rounded.
// Arguments:
//   h = Height of vertical mask.
//   r = Radius of the rounding.
//   r1 = Bottom radius of rounding.
//   r2 = Top radius of rounding.
//   d = Diameter of the rounding.
//   d1 = Bottom diameter of rounding.
//   d2 = Top diameter of rounding.
//   ang = Angle that the planes meet at.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
// Example:
//   difference() {
//       angle_pie_mask(ang=70, h=50, d=100);
//       #rounding_angled_edge_mask(h=51, r=20.0, ang=70, $fn=32);
//   }
// Example: Varying Rounding Radius
//   difference() {
//       angle_pie_mask(ang=70, h=50, d=100);
//       #rounding_angled_edge_mask(h=51, r1=10, r2=25, ang=70, $fn=32);
//   }
module rounding_angled_edge_mask(h=1.0, r, r1, r2, d, d1, d2, ang=90, anchor=CENTER, spin=0, orient=UP)
{
    function _mask_shape(r) = [
        for (i = [0:1:n]) let (a=90+ang+i*sweep/n) [r*cos(a)+x, r*sin(a)+r],
        for (i = [0:1:n]) let (a=90+i*sweep/n) [r*cos(a)+x, r*sin(a)-r],
        [min(-1, r*cos(270-ang)+x-1), r*sin(270-ang)-r],
        [min(-1, r*cos(90+ang)+x-1), r*sin(90+ang)+r],
    ];

    sweep = 180-ang;
    r1 = get_radius(r1=r1, r=r, d1=d1, d=d, dflt=1);
    r2 = get_radius(r1=r2, r=r, d1=d2, d=d, dflt=1);
    n = ceil(segs(max(r1,r2))*sweep/360);
    x = sin(90-(ang/2))/sin(ang/2) * (r1<r2? r2 : r1);
    if(r1<r2) {
        attachable(anchor,spin,orient, size=[2*x*r1/r2,2*r1,h], size2=[2*x,2*r2]) {
            zflip() {
                linear_extrude(height=h, convexity=4, center=true, scale=r1/r2) {
                    polygon(_mask_shape(r2));
                }
            }
            children();
        }
    } else {
        attachable(anchor,spin,orient, size=[2*x,2*r1,h], size2=[2*x*r2/r1,2*r2]) {
            linear_extrude(height=h, convexity=4, center=true, scale=r2/r1) {
                polygon(_mask_shape(r1));
            }
            children();
        }
    }
}


// Module: rounding_angled_corner_mask()
// Usage:
//   rounding_angled_corner_mask(r|d, ang);
// Description:
//   Creates a shape that can be used to round the corner of an angle.
//   Difference it from the object to be rounded.  The center of the mask
//   object should align exactly with the point of the corner to be rounded.
// Arguments:
//   r = Radius of the rounding.
//   d = Diameter of the rounding.
//   ang = Angle between planes that you need to round the corner of.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
// Example(Med):
//   ang=60;
//   difference() {
//       angle_pie_mask(ang=ang, h=50, r=200);
//       up(50/2) {
//           #rounding_angled_corner_mask(r=20, ang=ang);
//           zrot_copies([0, ang]) right(200/2) rounding_mask_x(l=200, r=20);
//       }
//       rounding_angled_edge_mask(h=51, r=20, ang=ang);
//   }
module rounding_angled_corner_mask(r, ang=90, d, anchor=CENTER, spin=0, orient=UP)
{
    r = get_radius(r=r, d=d, dflt=1);
    dx = r / tan(ang/2);
    dx2 = dx / cos(ang/2) + 1;
    fn = quantup(segs(r), 4);
    attachable(anchor,spin,orient, d=dx2, l=2*r) {
        difference() {
            down(r) cylinder(r=dx2, h=r+1, center=false);
            yflip_copy() {
                translate([dx, r, -r]) {
                    hull() {
                        sphere(r=r, $fn=fn);
                        down(r*3) sphere(r=r, $fn=fn);
                        zrot_copies([0,ang]) {
                            right(r*3) sphere(r=r, $fn=fn);
                        }
                    }
                }
            }
        }
        children();
    }
}


// Module: rounding_corner_mask()
// Usage:
//   rounding_corner_mask(r|d, [anchor]);
// Description:
//   Creates a shape that you can use to round 90 degree corners.
//   Difference it from the object to be rounded.  The center of the mask
//   object should align exactly with the corner to be rounded.
// Arguments:
//   r = Radius of corner rounding.
//   d = Diameter of corner rounding.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
// Example:
//   rounding_corner_mask(r=20.0);
// Example:
//   difference() {
//     cube(size=[30, 50, 80], center=true);
//     translate([0, 25, 40]) rounding_mask_x(l=31, r=15);
//     translate([15, 0, 40]) rounding_mask_y(l=51, r=15);
//     translate([15, 25, 0]) rounding_mask_z(l=81, r=15);
//     translate([15, 25, 40]) #rounding_corner_mask(r=15);
//   }
module rounding_corner_mask(r, d, anchor=CENTER, spin=0, orient=UP)
{
    r = get_radius(r=r, d=d, dflt=1);
    attachable(anchor,spin,orient, size=[2,2,2]*r) {
        difference() {
            cube(size=r*2, center=true);
            grid3d(n=[2,2,2], spacing=r*2-0.05) {
                sphere(r=r);
            }
        }
        children();
    }
}


// Module: rounding_cylinder_mask()
// Usage:
//   rounding_cylinder_mask(r|d, rounding);
// Description:
//   Create a mask that can be used to round the end of a cylinder.
//   Difference it from the cylinder to be rounded.  The center of the
//   mask object should align exactly with the center of the end of the
//   cylinder to be rounded.
// Arguments:
//   r = Radius of cylinder. (Default: 1.0)
//   d = Diameter of cylinder. (Default: 1.0)
//   rounding = Radius of the edge rounding. (Default: 0.25)
// Example:
//   difference() {
//     cylinder(r=50, h=50, center=false);
//     up(50) #rounding_cylinder_mask(r=50, rounding=10);
//   }
// Example:
//   difference() {
//     cylinder(r=50, h=50, center=false);
//     up(50) rounding_cylinder_mask(r=50, rounding=10);
//   }
module rounding_cylinder_mask(r, rounding=0.25, d)
{
    r = get_radius(r=r, d=d, dflt=1);
    cylinder_mask(l=rounding*3, r=r, rounding2=rounding, excess=rounding, ends_only=true, anchor=TOP);
}



// Module: rounding_hole_mask()
// Usage:
//   rounding_hole_mask(r|d, rounding, [excess]);
// Description:
//   Create a mask that can be used to round the edge of a circular hole.
//   Difference it from the hole to be rounded.  The center of the
//   mask object should align exactly with the center of the end of the
//   hole to be rounded.
// Arguments:
//   r = Radius of hole.
//   d = Diameter of hole to rounding.
//   rounding = Radius of the rounding. (Default: 0.25)
//   excess = The extra thickness of the mask.  Default: `0.1`.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
// Example(Med):
//   difference() {
//     cube([150,150,100], center=true);
//     cylinder(r=50, h=100.1, center=true);
//     up(50) #rounding_hole_mask(r=50, rounding=10);
//   }
// Example(Med):
//   difference() {
//     cube([150,150,100], center=true);
//     cylinder(r=50, h=100.1, center=true);
//     up(50) rounding_hole_mask(r=50, rounding=10);
//   }
// Example:
//   rounding_hole_mask(r=40, rounding=20, $fa=2, $fs=2);
module rounding_hole_mask(r, rounding=0.25, excess=0.1, d, anchor=CENTER, spin=0, orient=UP)
{
    r = get_radius(r=r, d=d, dflt=1);
    attachable(anchor,spin,orient, r=r+rounding, l=2*rounding) {
        rotate_extrude(convexity=4) {
            difference() {
                right(r-excess) fwd(rounding) square(rounding+excess, center=false);
                right(r+rounding) fwd(rounding) circle(r=rounding);
            }
        }
        children();
    }
}


// Module: teardrop_corner_mask()
// Usage:
//   teardrop_corner_mask(r|d, [angle], [excess]);
// Description:
//   Makes an apropriate 3D corner rounding mask that keeps within `angle` degrees of vertical.
// Arguments:
//   r = Radius of the mask rounding.
//   d = Diameter of the mask rounding.
//   angle = Maximum angle from vertical. Default: 45
//   excess = Excess mask size.  Default: 0.1
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
// Example:
//   teardrop_corner_mask(r=20, angle=40);
// Example:
//   diff("mask")
//   cuboid([50,60,70],rounding=10,edges="Z",anchor=CENTER) {
//       edge_profile(BOT)
//           mask2d_teardrop(r=10, angle=40);
//          corner_profile(BOT,r=10)
//              mask2d_teardrop(r=10, angle=40);
//   }
module teardrop_corner_mask(r, angle, excess=0.1, d, anchor=CENTER, spin=0, orient=UP) {
    assert(is_num(angle));
    assert(is_num(excess));
    assert(angle>0 && angle<90);
    r = get_radius(r=r, d=d, dflt=1);
    difference() {
        translate(-[1,1,1]*excess) cube(r+excess, center=false);
        translate([1,1,1]*r) onion(r=r, ang=angle, orient=DOWN);
    }
}


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
