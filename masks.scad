//////////////////////////////////////////////////////////////////////
// LibFile: masks.scad
//   Masking shapes.
//   To use, add the following lines to the beginning of your file:
//   ```
//   include <BOSL2/std.scad>
//   ```
//////////////////////////////////////////////////////////////////////


// Section: General Masks

// Module: angle_pie_mask()
// Usage:
//   angle_pie_mask(r|d, l, ang, [orient], [anchor]);
//   angle_pie_mask(r1|d1, r2|d2, l, ang, [orient], [anchor]);
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
//   orient = Orientation of the pie slice.  Use the ORIENT_ constants from constants.h.  Default: ORIENT_Z.
//   anchor = Alignment of the pie slice.  Use the constants from constants.h.  Default: CENTER.
// Example(FR):
//   angle_pie_mask(ang=30, d=100, l=20);
module angle_pie_mask(
	ang=45, l=undef,
	r=undef, r1=undef, r2=undef,
	d=undef, d1=undef, d2=undef,
	orient=ORIENT_Z, anchor=CENTER,
	h=undef
) {
	l = first_defined([l, h, 1]);
	r1 = get_radius(r1, r, d1, d, 10);
	r2 = get_radius(r2, r, d2, d, 10);
	orient_and_anchor([2*r1, 2*r1, l], orient, anchor, chain=true) {
		pie_slice(ang=ang, l=l+0.1, r1=r1, r2=r2, anchor=CENTER);
		children();
	}
}


// Module: cylinder_mask()
// Usage: Mask objects
//   cylinder_mask(l, r|d, chamfer, [chamfang], [from_end], [circum], [overage], [ends_only], [orient], [anchor]);
//   cylinder_mask(l, r|d, rounding, [circum], [overage], [ends_only], [orient], [anchor]);
//   cylinder_mask(l, r|d, [chamfer1|rounding1], [chamfer2|rounding2], [chamfang1], [chamfang2], [from_end], [circum], [overage], [ends_only], [orient], [anchor]);
// Usage: Masking operators
//   cylinder_mask(l, r|d, chamfer, [chamfang], [from_end], [circum], [overage], [ends_only], [orient], [anchor]) ...
//   cylinder_mask(l, r|d, rounding, [circum], [overage], [ends_only], [orient], [anchor]) ...
//   cylinder_mask(l, r|d, [chamfer1|rounding1], [chamfer2|rounding2], [chamfang1], [chamfang2], [from_end], [circum], [overage], [ends_only], [orient], [anchor]) ...
// Description:
//   If passed children, bevels/chamfers and/or rounds one or both
//   ends of the origin-centered cylindrical region specified.  If
//   passed no children, creates a mask to bevel/chamfer and/or round
//   one or both ends of the cylindrical region.  Difference the mask
//   from the region, making sure the center of the mask object is
//   anchored exactly with the center of the cylindrical region to
//   be chamferred.
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
//   overage = The extra thickness of the mask.  Default: `10`.
//   ends_only = If true, only mask the ends and not around the middle of the cylinder.
//   orient = Orientation.  Use the `ORIENT_` constants from `constants.scad`.  Default: `ORIENT_Z`.
//   anchor = Alignment of the region.  Use the constants from `constants.scad`.  Default: `CENTER`.
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
	overage=10, ends_only=false,
	orient=ORIENT_Z, anchor=CENTER
) {
	r1 = get_radius(r=r, d=d, r1=r1, d1=d1, dflt=1);
	r2 = get_radius(r=r, d=d, r1=r2, d1=d2, dflt=1);
	sides = segs(max(r1,r2));
	sc = circum? 1/cos(180/sides) : 1;
	vang = atan2(l, r1-r2)/2;
	ang1 = first_defined([chamfang1, chamfang, vang]);
	ang2 = first_defined([chamfang2, chamfang, 90-vang]);
	cham1 = first_defined([chamfer1, chamfer, 0]);
	cham2 = first_defined([chamfer2, chamfer, 0]);
	fil1 = first_defined([rounding1, rounding, 0]);
	fil2 = first_defined([rounding2, rounding, 0]);
	maxd = max(r1,r2);
	if ($children > 0) {
		difference() {
			children();
			cylinder_mask(l=l, r1=sc*r1, r2=sc*r2, chamfer1=cham1, chamfer2=cham2, chamfang1=ang1, chamfang2=ang2, rounding1=fil1, rounding2=fil2, orient=orient, from_end=from_end);
		}
	} else {
		orient_and_anchor([2*r1, 2*r1, l], orient, anchor, chain=true) {
			difference() {
				union() {
					chlen1 = cham1 / (from_end? 1 : tan(ang1));
					chlen2 = cham2 / (from_end? 1 : tan(ang2));
					if (!ends_only) {
						cylinder(r=maxd+overage, h=l+2*overage, center=true);
					} else {
						if (cham2>0) up(l/2-chlen2) cylinder(r=maxd+overage, h=chlen2+overage, center=false);
						if (cham1>0) down(l/2+overage) cylinder(r=maxd+overage, h=chlen1+overage, center=false);
						if (fil2>0) up(l/2-fil2) cylinder(r=maxd+overage, h=fil2+overage, center=false);
						if (fil1>0) down(l/2+overage) cylinder(r=maxd+overage, h=fil1+overage, center=false);
					}
				}
				cyl(r1=sc*r1, r2=sc*r2, l=l, chamfer1=cham1, chamfer2=cham2, chamfang1=ang1, chamfang2=ang2, from_end=from_end, rounding1=fil1, rounding2=fil2);
			}
			children();
		}
	}
}



// Section: Chamfers


// Module: chamfer_mask()
// Usage:
//   chamfer_mask(l, chamfer, [orient], [anchor]);
// Description:
//   Creates a shape that can be used to chamfer a 90 degree edge.
//   Difference it from the object to be chamfered.  The center of
//   the mask object should align exactly with the edge to be chamfered.
// Arguments:
//   l = Length of mask.
//   chamfer = Size of chamfer
//   orient = Orientation of the mask.  Use the `ORIENT_` constants from `constants.h`.  Default: vertical.
//   anchor = Alignment of the mask.  Use the constants from `constants.h`.  Default: centered.
// Example:
//   difference() {
//       cube(50);
//       #chamfer_mask(l=50, chamfer=10, orient=ORIENT_X, anchor=BOTTOM);
//   }
module chamfer_mask(l=1, chamfer=1, orient=ORIENT_Z, anchor=CENTER) {
	orient_and_anchor([chamfer*2, chamfer*2, l], orient, anchor, chain=true) {
		cylinder(r=chamfer, h=l+0.1, center=true, $fn=4);
		children();
	}
}


// Module: chamfer_mask_x()
// Usage:
//   chamfer_mask_x(l, chamfer, [anchor]);
// Description:
//   Creates a shape that can be used to chamfer a 90 degree edge along the X axis.
//   Difference it from the object to be chamfered.  The center of the mask
//   object should align exactly with the edge to be chamfered.
// Arguments:
//   l = Height of mask
//   chamfer = size of chamfer
//   anchor = Alignment of the cylinder.  Use the constants from constants.h.  Default: centered.
// Example:
//   difference() {
//       left(40) cube(80);
//       #chamfer_mask_x(l=80, chamfer=20);
//   }
module chamfer_mask_x(l=1.0, chamfer=1.0, anchor=CENTER) {
	chamfer_mask(l=l, chamfer=chamfer, orient=ORIENT_X, anchor=anchor) children();
}


// Module: chamfer_mask_y()
// Usage:
//   chamfer_mask_y(l, chamfer, [anchor]);
// Description:
//   Creates a shape that can be used to chamfer a 90 degree edge along the Y axis.
//   Difference it from the object to be chamfered.  The center of the mask
//   object should align exactly with the edge to be chamfered.
// Arguments:
//   l = Height of mask
//   chamfer = size of chamfer
//   anchor = Alignment of the cylinder.  Use the constants from constants.h.  Default: centered.
// Example:
//   difference() {
//       fwd(40) cube(80);
//       right(80) #chamfer_mask_y(l=80, chamfer=20);
//   }
module chamfer_mask_y(l=1.0, chamfer=1.0, anchor=CENTER) {
	chamfer_mask(l=l, chamfer=chamfer, orient=ORIENT_Y, anchor=anchor) children();
}


// Module: chamfer_mask_z()
// Usage:
//   chamfer_mask_z(l, chamfer, [anchor]);
// Description:
//   Creates a shape that can be used to chamfer a 90 degree edge along the Z axis.
//   Difference it from the object to be chamfered.  The center of the mask
//   object should align exactly with the edge to be chamfered.
// Arguments:
//   l = Height of mask
//   chamfer = size of chamfer
//   anchor = Alignment of the cylinder.  Use the constants from constants.h.  Default: centered.
// Example:
//   difference() {
//       down(40) cube(80);
//       #chamfer_mask_z(l=80, chamfer=20);
//   }
module chamfer_mask_z(l=1.0, chamfer=1.0, anchor=CENTER) {
	chamfer_mask(l=l, chamfer=chamfer, orient=ORIENT_Z, anchor=anchor) children();
}


// Module: chamfer()
// Usage:
//   chamfer(chamfer, size, [edges]) ...
// Description:
//   Chamfers the edges of a cuboid region containing childrem, centered on the origin.
// Arguments:
//   chamfer = Inset of the chamfer from the edge. (Default: 1)
//   size = The size of the rectangular cuboid we want to chamfer.
//   edges = Which edges to chamfer.  Use of [`edges()`](edges.scad#edges) from [`edges.scad`](edges.scad) is recommend.
// Description:
//   You should use [`edges()`](edges.scad#edges) from [`edges.scad`](edges.scad) with the `edge` argument.
//   However, if you must handle it raw, the edge ordering is this:
//       [
//           [Y-Z-, Y+Z-, Y-Z+, Y+Z+],
//           [X-Z-, X+Z-, X-Z+, X+Z+],
//           [X-Y-, X+Y-, X-Y+, X+Y+]
//       ]
// Example(FR):
//   chamfer(chamfer=2, size=[20,40,30]) {
//     cube(size=[20,40,30], center=true);
//   }
// Example(FR):
//   chamfer(chamfer=2, size=[20,40,30], edges=edges([TOP,FRONT+RIGHT], except=TOP+LEFT)) {
//     cube(size=[20,40,30], center=true);
//   }
module chamfer(chamfer=1, size=[1,1,1], edges=EDGES_ALL)
{
	difference() {
		children();
		difference() {
			cube(size, center=true);
			cuboid(size+[1,1,1]*0.02, chamfer=chamfer+0.01, edges=edges, trimcorners=true);
		}
	}
}


// Module: chamfer_cylinder_mask()
// Usage:
//   chamfer_cylinder_mask(r|d, chamfer, [ang], [from_end], [orient])
// Description:
//   Create a mask that can be used to bevel/chamfer the end of a cylindrical region.
//   Difference it from the end of the region to be chamferred.  The center of the mask
//   object should align exactly with the center of the end of the cylindrical region
//   to be chamferred.
// Arguments:
//   r = Radius of cylinder to chamfer.
//   d = Diameter of cylinder to chamfer. Use instead of r.
//   chamfer = Size of the edge chamferred, inset from edge. (Default: 0.25)
//   ang = Angle of chamfer in degrees from vertical.  (Default: 45)
//   from_end = If true, chamfer size is measured from end of cylinder.  If false, chamfer is measured outset from the radius of the cylinder.  (Default: false)
//   orient = Orientation of the mask.  Use the `ORIENT_` constants from `constants.h`.  Default: ORIENT_Z.
// Example:
//   difference() {
//       cylinder(r=50, h=100, center=true);
//       up(50) #chamfer_cylinder_mask(r=50, chamfer=10);
//   }
module chamfer_cylinder_mask(r=undef, d=undef, chamfer=0.25, ang=45, from_end=false, orient=ORIENT_Z)
{
	r = get_radius(r=r, d=d, dflt=1);
	rot(orient) cylinder_mask(l=chamfer*3, r=r, chamfer2=chamfer, chamfang2=ang, from_end=from_end, ends_only=true, anchor=TOP);
}


// Module: chamfer_hole_mask()
// Usage:
//   chamfer_hole_mask(r|d, chamfer, [ang], [from_end]);
// Description:
//   Create a mask that can be used to bevel/chamfer the end of a cylindrical hole.
//   Difference it from the hole to be chamferred.  The center of the mask object
//   should align exactly with the center of the end of the hole to be chamferred.
// Arguments:
//   r = Radius of hole to chamfer.
//   d = Diameter of hole to chamfer. Use instead of r.
//   chamfer = Size of the chamfer. (Default: 0.25)
//   ang = Angle of chamfer in degrees from vertical.  (Default: 45)
//   from_end = If true, chamfer size is measured from end of hole.  If false, chamfer is measured outset from the radius of the hole.  (Default: false)
//   overage = The extra thickness of the mask.  Default: `0.1`.
//   orient = Orientation of the mask.  Use the `ORIENT_` constants from `constants.h`.  Default: `ORIENT_Z`.
//   anchor = Alignment of the mask.  Use the constants from `constants.h`.  Default: `CENTER`.
// Example:
//   difference() {
//       cube(100, center=true);
//       cylinder(d=50, h=100.1, center=true);
//       up(50) #chamfer_hole_mask(d=50, chamfer=10);
//   }
// Example:
//   chamfer_hole_mask(d=100, chamfer=25, ang=30, overage=10);
module chamfer_hole_mask(r=undef, d=undef, chamfer=0.25, ang=45, from_end=false, overage=0.1, orient=ORIENT_Z, anchor=CENTER)
{
	r = get_radius(r=r, d=d, dflt=1);
	h = chamfer * (from_end? 1 : tan(90-ang));
	r2 = r + chamfer * (from_end? tan(ang) : 1);
	$fn = segs(r);
	orient_and_anchor([2*r, 2*r, h*2], orient, anchor, size2=[2*r2, 2*r2], chain=true) {
		union() {
			cylinder(r=r2, h=overage, center=false);
			down(h) cylinder(r1=r, r2=r2, h=h, center=false);
		}
		children();
	}
}



// Section: Rounding

// Module: rounding_mask()
// Usage:
//   rounding_mask(l|h, r, [orient], [anchor])
// Description:
//   Creates a shape that can be used to round a vertical 90 degree edge.
//   Difference it from the object to be rounded.  The center of the mask
//   object should align exactly with the edge to be rounded.
// Arguments:
//   l = Length of mask.
//   r = Radius of the rounding.
//   orient = Orientation of the mask.  Use the `ORIENT_` constants from `constants.h`.  Default: vertical.
//   anchor = Alignment of the mask.  Use the constants from `constants.h`.  Default: centered.
// Example:
//   difference() {
//       cube(size=100, center=false);
//       #rounding_mask(l=100, r=25, orient=ORIENT_Z, anchor=BOTTOM);
//   }
module rounding_mask(l=undef, r=1.0, orient=ORIENT_Z, anchor=CENTER, h=undef)
{
	l = first_defined([l, h, 1]);
	sides = quantup(segs(r),4);
	orient_and_anchor([2*r, 2*r, l], orient, anchor, chain=true) {
		linear_extrude(height=l+0.1, convexity=4, center=true) {
			difference() {
				square(2*r, center=true);
				xspread(2*r) yspread(2*r) circle(r=r, $fn=sides);
			}
		}
		children();
	}
}


// Module: rounding_mask_x()
// Usage:
//   rounding_mask_x(l, r, [anchor])
// Description:
//   Creates a shape that can be used to round a 90 degree edge oriented
//   along the X axis.  Difference it from the object to be rounded.
//   The center of the mask object should align exactly with the edge to
//   be rounded.
// Arguments:
//   l = Length of mask.
//   r = Radius of the rounding.
//   anchor = Alignment of the mask.  Use the constants from `constants.h`.  Default: centered.
// Example:
//   difference() {
//       cube(size=100, center=false);
//       #rounding_mask_x(l=100, r=25, anchor=LEFT);
//   }
module rounding_mask_x(l=1.0, r=1.0, anchor=CENTER)
{
	orient_and_anchor([l, 2*r, 2*r], ORIENT_Z, anchor, chain=true) {
		rounding_mask(l=l, r=r, orient=ORIENT_X, anchor=CENTER)
		children();
	}
}


// Module: rounding_mask_y()
// Usage:
//   rounding_mask_y(l, r, [anchor])
// Description:
//   Creates a shape that can be used to round a 90 degree edge oriented
//   along the Y axis.  Difference it from the object to be rounded.
//   The center of the mask object should align exactly with the edge to
//   be rounded.
// Arguments:
//   l = Length of mask.
//   r = Radius of the rounding.
//   anchor = Alignment of the mask.  Use the constants from `constants.h`.  Default: centered.
// Example:
//   difference() {
//       cube(size=100, center=false);
//       right(100) #rounding_mask_y(l=100, r=25, anchor=FRONT);
//   }
module rounding_mask_y(l=1.0, r=1.0, anchor=CENTER)
{
	orient_and_anchor([2*r, l, 2*r], ORIENT_Z, anchor, chain=true) {
		rounding_mask(l=l, r=r, orient=ORIENT_Y, anchor=CENTER)
		children();
	}
}


// Module: rounding_mask_z()
// Usage:
//   rounding_mask_z(l, r, [anchor])
// Description:
//   Creates a shape that can be used to round a 90 degree edge oriented
//   along the Z axis.  Difference it from the object to be rounded.
//   The center of the mask object should align exactly with the edge to
//   be rounded.
// Arguments:
//   l = Length of mask.
//   r = Radius of the rounding.
//   anchor = Alignment of the mask.  Use the constants from `constants.h`.  Default: centered.
// Example:
//   difference() {
//       cube(size=100, center=false);
//       #rounding_mask_z(l=100, r=25, anchor=BOTTOM);
//   }
module rounding_mask_z(l=1.0, r=1.0, anchor=CENTER) rounding_mask(l=l, r=r, orient=ORIENT_Z, anchor=anchor) children();


// Module: rounding()
// Usage:
//   rounding(r, size, [edges]) ...
// Description:
//   Rounds the edges of a cuboid region containing the given children.
// Arguments:
//   r = Radius of the rounding. (Default: 1)
//   size = The size of the rectangular cuboid we want to chamfer.
//   edges = Which edges to chamfer.  Use of [`edges()`](edges.scad#edges) from [`edges.scad`](edges.scad) is recommend.
// Description:
//   You should use [`edges()`](edges.scad#edges) from [`edges.scad`](edges.scad) to generate the edge array for the `edge` argument.
//   However, if you must handle it raw, the edge ordering is this:
//       [
//           [Y-Z-, Y+Z-, Y-Z+, Y+Z+],
//           [X-Z-, X+Z-, X-Z+, X+Z+],
//           [X-Y-, X+Y-, X-Y+, X+Y+]
//       ]
// Example(FR):
//   rounding(r=10, size=[50,100,150], $fn=24) {
//     cube(size=[50,100,150], center=true);
//   }
// Example(FR,FlatSpin):
//   rounding(r=10, size=[50,50,75], edges=edges([TOP,FRONT+RIGHT], except=TOP+LEFT), $fn=24) {
//     cube(size=[50,50,75], center=true);
//   }
module rounding(r=1, size=[1,1,1], edges=EDGES_ALL)
{
	difference() {
		children();
		difference() {
			cube(size, center=true);
			cuboid(size+[1,1,1]*0.01, rounding=r, edges=edges, trimcorners=true);
		}
	}
}


// Module: rounding_angled_edge_mask()
// Usage:
//   rounding_angled_edge_mask(h, r, [ang], [orient], [anchor]);
// Description:
//   Creates a vertical mask that can be used to round the edge where two
//   face meet, at any arbitrary angle.  Difference it from the object to
//   be rounded.  The center of the mask should align exactly with the
//   edge to be rounded.
// Arguments:
//   h = height of vertical mask.
//   r = radius of the rounding.
//   ang = angle that the planes meet at.
//   orient = Orientation of the mask.  Use the `ORIENT_` constants from `constants.h`.  Default: `ORIENT_Z`.
//   anchor = Alignment of the mask.  Use the constants from `constants.h`.  Default: `CENTER`.
// Example:
//   difference() {
//       angle_pie_mask(ang=70, h=50, d=100);
//       #rounding_angled_edge_mask(h=51, r=20.0, ang=70, $fn=32);
//   }
module rounding_angled_edge_mask(h=1.0, r=1.0, ang=90, orient=ORIENT_Z, anchor=CENTER)
{
	sweep = 180-ang;
	n = ceil(segs(r)*sweep/360);
	x = r*sin(90-(ang/2))/sin(ang/2);
	orient_and_anchor([2*x,2*r,h], orient, anchor, chain=true) {
		linear_extrude(height=h, convexity=4, center=true) {
			polygon(
				points=concat(
					[for (i = [0:n]) let (a=90+ang+i*sweep/n) [r*cos(a)+x, r*sin(a)+r]],
					[for (i = [0:n]) let (a=90+i*sweep/n) [r*cos(a)+x, r*sin(a)-r]],
					[
						[min(-1, r*cos(270-ang)+x-1), r*sin(270-ang)-r],
						[min(-1, r*cos(90+ang)+x-1), r*sin(90+ang)+r],
					]
				)
			);
		}
		children();
	}
}


// Module: rounding_angled_corner_mask()
// Usage:
//   rounding_angled_corner_mask(r, ang, [orient], [anchor]);
// Description:
//   Creates a shape that can be used to round the corner of an angle.
//   Difference it from the object to be rounded.  The center of the mask
//   object should align exactly with the point of the corner to be rounded.
// Arguments:
//   r = Radius of the rounding.
//   ang = Angle between planes that you need to round the corner of.
//   orient = Orientation of the mask.  Use the `ORIENT_` constants from `constants.h`.  Default: `ORIENT_Z`.
//   anchor = Alignment of the mask.  Use the constants from `constants.h`.  Default: `CENTER`.
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
module rounding_angled_corner_mask(r=1.0, ang=90, orient=ORIENT_Z, anchor=CENTER)
{
	dx = r / tan(ang/2);
	dx2 = dx / cos(ang/2) + 1;
	fn = quantup(segs(r), 4);
	orient_and_anchor([2*dx2, 2*dx2, r*2], orient, anchor, chain=true) {
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
//   rounding_corner_mask(r, [anchor]);
// Description:
//   Creates a shape that you can use to round 90 degree corners.
//   Difference it from the object to be rounded.  The center of the mask
//   object should align exactly with the corner to be rounded.
// Arguments:
//   r = Radius of corner rounding.
//   anchor = Alignment of the mask.  Use the constants from `constants.h`.  Default: `CENTER`.
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
module rounding_corner_mask(r=1.0, anchor=CENTER)
{
	orient_and_anchor([2*r, 2*r, 2*r], ORIENT_Z, anchor, chain=true) {
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
//   rounding_cylinder_mask(r, rounding);
// Description:
//   Create a mask that can be used to round the end of a cylinder.
//   Difference it from the cylinder to be rounded.  The center of the
//   mask object should align exactly with the center of the end of the
//   cylinder to be rounded.
// Arguments:
//   r = Radius of cylinder. (Default: 1.0)
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
module rounding_cylinder_mask(r=1.0, rounding=0.25)
{
	cylinder_mask(l=rounding*3, r=r, rounding2=rounding, overage=rounding, ends_only=true, anchor=TOP);
}



// Module: rounding_hole_mask()
// Usage:
//   rounding_hole_mask(r|d, rounding);
// Description:
//   Create a mask that can be used to round the edge of a circular hole.
//   Difference it from the hole to be rounded.  The center of the
//   mask object should align exactly with the center of the end of the
//   hole to be rounded.
// Arguments:
//   r = Radius of hole.
//   d = Diameter of hole to rounding.
//   rounding = Radius of the rounding. (Default: 0.25)
//   overage = The extra thickness of the mask.  Default: `0.1`.
//   orient = Orientation of the mask.  Use the `ORIENT_` constants from `constants.h`.  Default: `ORIENT_Z`.
//   anchor = Alignment of the mask.  Use the constants from `constants.h`.  Default: `CENTER`.
// Example(Med):
//   difference() {
//     cube([150,150,100], center=true);
//     cylinder(r=50, h=100.1, center=true);
//     up(50) #rounding_hole_mask(r=50, rounding=10);
//   }
// Example:
//   rounding_hole_mask(r=40, rounding=20, $fa=2, $fs=2);
module rounding_hole_mask(r=undef, d=undef, rounding=0.25, overage=0.1, orient=ORIENT_Z, anchor=CENTER)
{
	r = get_radius(r=r, d=d, dflt=1);
	orient_and_anchor([2*(r+rounding), 2*(r+rounding), rounding*2], orient, anchor, chain=true) {
		rotate_extrude(convexity=4) {
			difference() {
				right(r-overage) fwd(rounding) square(rounding+overage, center=false);
				right(r+rounding) fwd(rounding) circle(r=rounding);
			}
		}
		children();
	}
}


// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
