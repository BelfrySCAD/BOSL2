//////////////////////////////////////////////////////////////////////
// LibFile: masks2d.scad
//   This file provides 2D masking shapes that you can use with {{edge_profile()}} to mask edges.
//   The shapes include the simple roundover and chamfer as well as more elaborate shapes
//   like the cove and ogee found in furniture and architecture.  You can make the masks
//   as geometry or as 2D paths.
// Includes:
//   include <BOSL2/std.scad>
// FileGroup: Basic Modeling
// FileSummary: 2D masking shapes for edge profiling: including roundover, cove, teardrop, ogee.
// FileFootnotes: STD=Included in std.scad
//////////////////////////////////////////////////////////////////////


// Section: 2D Masking Shapes

// Function&Module: mask2d_roundover()
// Synopsis: Creates a 2D beading mask shape useful for rounding edges.
// SynTags: Geom, Path
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable, Masks (2D)
// See Also: corner_profile(), edge_profile(), face_profile(), fillet()
// Usage: As module
//   mask2d_roundover(r|d=|h=|cut=|joint=, [inset], [mask_angle], [excess], [flat_top=]) [ATTACHMENTS];
// Usage: As function
//   path = mask2d_roundover(r|d=|h=|cut=|joint=, [inset], [mask_angle], [excess], [flat_top=]);
// Description:
//   Creates a 2D roundover/bead mask shape that is useful for extruding into a 3D mask for an edge.
//   Conversely, you can use that same extruded shape to make an interior fillet between two walls.
//   As a 2D mask, this is designed to be differenced away from the edge of a shape that is in the first (X+Y+) quadrant.
//   If called as a function, this just returns a 2D path of the outline of the mask shape.
//   The roundover can be specified by radius, diameter, height, cut, or joint length.
//   ![Types of Roundovers](images/rounding/section-types-of-roundovers_fig1.png)
// Arguments:
//   r = Radius of the roundover.
//   inset = Optional bead inset size.  Default: 0
//   mask_angle = Number of degrees in the corner angle to mask.  Default: 90
//   excess = Extra amount of mask shape to creates on the X- and Y- sides of the shape.  Default: 0.01
//   ---
//   d = Diameter of the roundover.
//   h = Mask height.  Given instead of r or d when you want a consistent mask height, no matter what the mask angle.
//   cut = Cut distance.  IE: How much of the corner to cut off.  See [Types of Roundovers](rounding.scad#section-types-of-roundovers).
//   joint = Joint distance.  IE: How far from the edge the roundover should start.  See [Types of Roundovers](rounding.scad#section-types-of-roundovers).
//   flat_top = If true, the top inset of the mask will be horizontal instead of angled by the mask_angle.  Default: true.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
// Side Effects:
//  Tags the children with "remove" (and hence sets `$tag`) if no tag is already set.
//
// Example(2D): 2D Roundover Mask by Radius
//   mask2d_roundover(r=10);
// Example(2D): 2D Bead Mask
//   mask2d_roundover(r=10,inset=2);
// Example(2D): 2D Bead Mask by Height
//   mask2d_roundover(h=10,inset=2);
// Example(2D): 2D Bead Mask for a Non-Right Edge.
//   mask2d_roundover(r=10, inset=2, mask_angle=75);
// Example(2D): Disabling flat_top=
//   mask2d_roundover(r=10, inset=2, flat_top=false, mask_angle=75);
// Example(2D): 2D Angled Bead Mask by Joint Length
//   mask2d_roundover(joint=10, inset=2, mask_angle=75);
// Example(2D): Increasing the Excess
//   mask2d_roundover(r=10, inset=2, mask_angle=75, excess=2);
// Example: Masking by Edge Attachment
//   diff()
//   cube([50,60,70],center=true)
//       edge_profile([TOP,"Z"],except=[BACK,TOP+LEFT])
//           mask2d_roundover(h=12, inset=2);
// Example: Making an interior fillet
//   %render() difference() {
//       move(-[5,0,5]) cube(30, anchor=BOT+LEFT);
//       cube(310, anchor=BOT+LEFT);
//   }
//   xrot(90)
//       linear_extrude(height=30, center=true)
//           mask2d_roundover(r=10);
module mask2d_roundover(r, inset=0, mask_angle=90, excess=0.01, flat_top=true, d, h, cut, joint, anchor=CENTER,spin=0) {
    path = mask2d_roundover(r=r, d=d, h=h, cut=cut, joint=joint, inset=inset, flat_top=flat_top, mask_angle=mask_angle, excess=excess);
    default_tag("remove") {
        attachable(anchor,spin, two_d=true, path=path) {
            polygon(path);
            children();
        }
    }
}

function mask2d_roundover(r, inset=0, mask_angle=90, excess=0.01, flat_top=true, d, h, cut, joint, anchor=CENTER, spin=0) =
    assert(one_defined([r,d,h,cut,joint],"r,d,h,cut,joint"))
    assert(is_undef(r) || is_finite(r))
    assert(is_undef(d) || is_finite(d))
    assert(is_undef(h) || is_finite(h))
    assert(is_undef(cut) || is_finite(cut))
    assert(is_undef(joint) || is_finite(joint))
    assert(is_finite(excess))
    assert(is_finite(mask_angle) && mask_angle>0 && mask_angle<180)
    assert(is_finite(inset)||(is_vector(inset)&&len(inset)==2))
    assert(is_bool(flat_top))
    let(
        inset = is_list(inset)? inset : [inset,inset],
        r = is_finite(joint)? adj_ang_to_opp(joint, mask_angle/2) :
            is_finite(h)? (
                mask_angle==90? h-inset.y :
                mask_angle < 90 ? adj_ang_to_opp(opp_ang_to_hyp(h-inset.y,mask_angle), mask_angle/2) :
                adj_ang_to_opp(adj_ang_to_hyp(h-inset.y,mask_angle-90), mask_angle/2)
            ) :
            is_finite(cut)
              ? let(
                    o = adj_ang_to_opp(cut, mask_angle/2),
                    h = adj_ang_to_hyp(cut, mask_angle/2)
                ) adj_ang_to_opp(o+h, mask_angle/2)
              : get_radius(r=r,d=d,dflt=undef),
        pts = _inset_isect(inset,mask_angle,flat_top,excess,-r),
        arcpts = arc(r=r, corner=[pts[4],pts[5],pts[0]]),
        path = [
            each select(pts, 1, 3),
            each arcpts,
        ]
    ) reorient(anchor,spin, two_d=true, path=path, extent=false, p=path);


function _inset_isect(inset,mask_angle,flat_top,excess,r,size) =
    assert(one_defined([size,r],"size,r"))
    let(
        lft_n = polar_to_xy(1, mask_angle-90),
        rgt_n = [1,0],
        top_n = flat_top? [1,0] : lft_n,
        bot_n = [0,1],

        line_lft = [[0,0], polar_to_xy(100, mask_angle)],
        line_bot = [[0,0], [100,0]],
        ex_line_lft = move(-excess*lft_n, p=line_lft),
        ex_line_bot = move(-excess*bot_n, p=line_bot),
        in_line_lft = move(inset.x*top_n, p=line_lft),
        in_line_bot = move(inset.y*bot_n, p=line_bot),

        ex_pt = line_intersection(ex_line_lft, ex_line_bot),
        in_pt = line_intersection(in_line_lft, in_line_bot),

        pos_r = r==undef || r >= 0,
        r = r==undef? undef : abs(r),
        x = is_undef(size)? r : size.x,
        y = is_undef(size)? r : size.y,
        base_pt = !flat_top && is_num(r)? in_pt :
            in_pt + [y*cos(mask_angle)/sin(mask_angle), 0],
        line_top = !flat_top && is_num(r)
          ? let( pt = in_pt + polar_to_xy(r/(pos_r?1:tan(mask_angle/2)), mask_angle) )
            [pt, pt - top_n]
          : [base_pt + [0,y], base_pt + [0,y] - top_n],
        line_rgt = !flat_top && is_num(r)
          ? pos_r
            ? [in_pt + [r,0], in_pt + [r,1]]
            : [in_pt + [r/tan(mask_angle/2),0], in_pt + [r/tan(mask_angle/2),1]]
          : [base_pt + [x,0], base_pt + [x,1]],
        top_pt = line_intersection(ex_line_lft, line_top),

        path = is_vector(size)? [
            // All size based
            base_pt + [size.x,0],
            [base_pt.x + size.x, -excess],
            ex_pt,
            top_pt,
            base_pt + [0,size.y],
            base_pt,
            base_pt + size,
        ] : flat_top? [
            // flat_top radius
            base_pt + [r,0],
            [base_pt.x + r, -excess],
            ex_pt,
            top_pt,
            base_pt + [0,r],
            base_pt,
            base_pt + [r,r],
        ] : let(
            cp_pt = line_intersection(line_rgt, line_top)
        ) pos_r? [
            // non-flat_top radius from inside
            in_pt + [r,0],
            [in_pt.x + r, -excess],
            ex_pt,
            top_pt,
            in_pt + polar_to_xy(r,mask_angle),
            in_pt,
            cp_pt,
        ] : [
            // non-flat_top radius from outside
            line_rgt[0],
            [cp_pt.x, -excess],
            ex_pt,
            top_pt,
            in_pt + polar_to_xy(r/tan(mask_angle/2),mask_angle),
            in_pt,
            cp_pt,
        ]
    ) path;



// Function&Module: mask2d_cove()
// Synopsis: Creates a 2D cove (quarter-round) mask shape.
// SynTags: Geom, Path
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable, Masks (2D)
// See Also: corner_profile(), edge_profile(), face_profile()
// Usage: As module
//   mask2d_cove(r|d=|h=, [inset], [mask_angle], [excess], [flat_top=]) [ATTACHMENTS];
// Usage: As function
//   path = mask2d_cove(r|d=|h=, [inset], [mask_angle], [excess], [flat_top=]);
// Description:
//   Creates a 2D cove mask shape that is useful for extruding into a 3D mask for an edge.
//   Conversely, you can use that same extruded shape to make an interior rounded shelf decoration between two walls.
//   As a 2D mask, this is designed to be differenced away from the edge of a shape that is in the first (X+Y+) quadrant.
//   If called as a function, this just returns a 2D path of the outline of the mask shape.
// Arguments:
//   r = Radius of the cove.
//   inset = Optional amount to inset code from corner.  Default: 0
//   mask_angle = Number of degrees in the corner angle to mask.  Default: 90
//   excess = Extra amount of mask shape to creates on the X- and Y- sides of the shape.  Default: 0.01
//   ---
//   d = Diameter of the cove.
//   h = Mask height.  Given instead of r or d when you want a consistent mask height, no matter what the mask angle.
//   flat_top = If true, the top inset of the mask will be horizontal instead of angled by the mask_angle.  Default: true.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
// Side Effects:
//  Tags the children with "remove" (and hence sets `$tag`) if no tag is already set.
// Example(2D): 2D Cove Mask by Radius
//   mask2d_cove(r=10);
// Example(2D): 2D Inset Cove Mask
//   mask2d_cove(r=10,inset=3);
// Example(2D): 2D Inset Cove Mask by Height
//   mask2d_cove(h=10,inset=2);
// Example(2D): 2D Inset Cove Mask for a Non-Right Edge
//   mask2d_cove(r=10,inset=3,mask_angle=75);
// Example(2D): Disabling flat_top=
//   mask2d_cove(r=10, inset=3, flat_top=false, mask_angle=75);
// Example(2D): Increasing the Excess
//   mask2d_cove(r=10,inset=3,mask_angle=75, excess=2);
// Example: Masking by Edge Attachment
//   diff()
//   cube([50,60,70],center=true)
//       edge_profile([TOP,"Z"],except=[BACK,TOP+LEFT])
//           mask2d_cove(h=10, inset=3);
// Example: Making an interior rounded shelf
//   %render() difference() {
//       move(-[5,0,5]) cube(30, anchor=BOT+LEFT);
//       cube(310, anchor=BOT+LEFT);
//   }
//   xrot(90)
//       linear_extrude(height=30, center=true)
//           mask2d_cove(r=5, inset=5);
module mask2d_cove(r, inset=0, mask_angle=90, excess=0.01, flat_top=true, d, h, anchor=CENTER, spin=0) {
    path = mask2d_cove(r=r, d=d, h=h, flat_top=flat_top, inset=inset, mask_angle=mask_angle, excess=excess);
    default_tag("remove") {
        attachable(anchor,spin, two_d=true, path=path) {
            polygon(path);
            children();
        }
    }
}

function mask2d_cove(r, inset=0, mask_angle=90, excess=0.01, flat_top=true, d, h, anchor=CENTER, spin=0) =
    assert(one_defined([r,d,h],"r,d,h"))
    assert(is_undef(r) || is_finite(r))
    assert(is_undef(d) || is_finite(d))
    assert(is_undef(h) || is_finite(h))
    assert(is_finite(mask_angle) && mask_angle>0 && mask_angle<180)
    assert(is_finite(excess))
    assert(is_finite(inset)||(is_vector(inset)&&len(inset)==2))
    assert(is_bool(flat_top))
    let(
        inset = is_list(inset)? inset : [inset,inset],
        r = is_finite(h)? (
                mask_angle==90? h-inset.y :
                mask_angle < 90 ? adj_ang_to_opp(opp_ang_to_hyp(h-inset.y,mask_angle), mask_angle/2) :
                adj_ang_to_opp(adj_ang_to_hyp(h-inset.y,mask_angle-90), mask_angle/2)
            ) : get_radius(r=r,d=d,dflt=undef),
        pts = _inset_isect(inset,mask_angle,flat_top,excess,r),
        arcpts = arc(r=r, corner=[pts[4],pts[6],pts[0]]),
        ipath = [
            each select(pts, 1, 3),
            each arcpts,
        ],
        path = deduplicate(ipath)
    ) reorient(anchor,spin, two_d=true, path=path, p=path);


// Function&Module: mask2d_chamfer()
// Synopsis: Produces a 2D chamfer mask shape.
// SynTags: Geom, Path
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable, Masks (2D)
// See Also: corner_profile(), edge_profile(), face_profile()
// Usage: As Module
//   mask2d_chamfer(edge, [angle], [inset], [excess]) [ATTACHMENTS];
//   mask2d_chamfer(y=, [angle=], [inset=], [excess=]) [ATTACHMENTS];
//   mask2d_chamfer(x=, [angle=], [inset=], [excess=]) [ATTACHMENTS];
// Usage: As Function
//   path = mask2d_chamfer(edge, [angle], [inset], [excess]);
//   path = mask2d_chamfer(y=, [angle=], [inset=], [excess=]);
//   path = mask2d_chamfer(x=, [angle=], [inset=], [excess=]);
// Description:
//   Creates a 2D chamfer mask shape that is useful for extruding into a 3D mask for a 90° edge.
//   Conversely, you can use that same extruded shape to make an interior chamfer between two walls at a 90º angle.
//   As a 2D mask, this is designed to be differenced away from the edge of a shape that is in the first (X+Y+) quadrant.
//   If called as a function, this just returns a 2D path of the outline of the mask shape.
//   The edge parameter specifies the length of the chamfer's slanted edge.  Alternatively you can give x or y to
//   specify the width or height.  Only one of x, y, or width is permitted.  
// Arguments:
//   edge = The length of the edge of the chamfer.
//   angle = The angle of the chamfer edge, away from vertical.  Default: 45.
//   inset = Optional amount to inset code from corner.  Default: 0
//   mask_angle = Number of degrees in the corner angle to mask.  Default: 90
//   excess = Extra amount of mask shape to creates on the X- and Y- sides of the shape.  Default: 0.01
//   ---
//   x = The width of the chamfer.
//   y = The height of the chamfer.
//   flat_top = If true, the top inset of the mask will be horizontal instead of angled by the mask_angle.  Default: true.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
// Side Effects:
//  Tags the children with "remove" (and hence sets `$tag`) if no tag is already set.
// Example(2D): 2D Chamfer Mask
//   mask2d_chamfer(x=10);
// Example(2D): 2D Chamfer Mask by Width.
//   mask2d_chamfer(x=10, angle=30);
// Example(2D): 2D Chamfer Mask by Height.
//   mask2d_chamfer(y=10, angle=30);
// Example(2D): 2D Inset Chamfer Mask
//   mask2d_chamfer(x=10, inset=2);
// Example: Masking by Edge Attachment
//   diff()
//   cube([50,60,70],center=true)
//       edge_profile([TOP,"Z"],except=[BACK,TOP+LEFT])
//           mask2d_chamfer(x=10, inset=2);
// Example: Making an interior chamfer
//   %render() difference() {
//       move(-[5,0,5]) cube(30, anchor=BOT+LEFT);
//       cube(310, anchor=BOT+LEFT);
//   }
//   xrot(90)
//       linear_extrude(height=30, center=true)
//           mask2d_chamfer(edge=10);
module mask2d_chamfer(edge, angle=45, inset=0, excess=0.01, mask_angle=90, flat_top=true, x, y, anchor=CENTER,spin=0) {
    path = mask2d_chamfer(x=x, y=y, edge=edge, angle=angle, excess=excess, inset=inset, mask_angle=mask_angle, flat_top=flat_top);
    default_tag("remove") {
        attachable(anchor,spin, two_d=true, path=path, extent=true) {
            polygon(path);
            children();
        }
    }
}

function mask2d_chamfer(edge, angle=45, inset=0, excess=0.01, mask_angle=90, flat_top=true, x, y, anchor=CENTER,spin=0) =
    let(dummy=one_defined([x,y,edge],["x","y","edge"]))
    assert(is_finite(angle))
    assert(is_finite(excess))
    assert(is_finite(mask_angle) && mask_angle>0 && mask_angle<180)
    assert(is_finite(inset)||(is_vector(inset)&&len(inset)==2))
    let(
        inset = is_list(inset)? inset : [inset,inset],
        x = is_def(x)? x :
            is_def(y)? adj_ang_to_opp(adj=y,ang=angle) :
            hyp_ang_to_opp(hyp=edge,ang=angle),
        y = opp_ang_to_adj(opp=x,ang=angle),
        pts = _inset_isect(inset,mask_angle,flat_top,excess,size=[x,y]),
        path = [
            each select(pts, 1, 4),
            pts[0],
        ]
    ) reorient(anchor,spin, two_d=true, path=path, extent=true, p=path);


// Function&Module: mask2d_rabbet()
// Synopsis: Creates a rabbet mask shape.
// SynTags: Geom, Path
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable, Masks (2D)
// See Also: corner_profile(), edge_profile(), face_profile()
// Usage: As Module
//   mask2d_rabbet(size, [mask_angle], [excess], [flat_top=]) [ATTACHMENTS];
// Usage: As Function
//   path = mask2d_rabbet(size, [mask_angle], [excess], [flat_top=]);
// Description:
//   Creates a 2D rabbet mask shape that is useful for extruding into a 3D mask for an edge.
//   Conversely, you can use that same extruded shape to make an interior shelf decoration between two walls.
//   As a 2D mask, this is designed to be differenced away from the edge of a shape that is in the first (X+Y+) quadrant.
//   If called as a function, this just returns a 2D path of the outline of the mask shape.
// Arguments:
//   size = The size of the rabbet, either as a scalar or an [X,Y] list.
//   inset = Optional bead inset size.  Default: 0
//   mask_angle = Number of degrees in the corner angle to mask.  Default: 90
//   excess = Extra amount of mask shape to creates on the X- and Y- sides of the shape. Default: 0.01
//   ---
//   flat_top = If true, the top inset of the mask will be horizontal instead of angled by the mask_angle.  Default: true.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
// Side Effects:
//  Tags the children with "remove" (and hence sets `$tag`) if no tag is already set.
// Example(2D): 2D Rabbet Mask
//   mask2d_rabbet(size=10);
// Example(2D): 2D Asymmetrical Rabbet Mask
//   mask2d_rabbet(size=[5,10]);
// Example(2D): 2D Mask for a Non-Right Edge
//   mask2d_rabbet(size=10, mask_angle=75);
// Example(2D): Disabling flat_top=
//   mask2d_rabbet(size=10, flat_top=false, mask_angle=75);
// Example: Masking by Edge Attachment
//   diff()
//   cube([50,60,70],center=true)
//       edge_profile([TOP,"Z"],except=[BACK,TOP+LEFT])
//           mask2d_rabbet(size=10);
// Example: Making an interior shelf
//   %render() difference() {
//       move(-[5,0,5]) cube(30, anchor=BOT+LEFT);
//       cube(310, anchor=BOT+LEFT);
//   }
//   xrot(90)
//       linear_extrude(height=30, center=true)
//           mask2d_rabbet(size=[5,10]);
module mask2d_rabbet(size, inset=[0,0], mask_angle=90, excess=0.01, flat_top=true, anchor=CTR, spin=0) {
    path = mask2d_rabbet(size=size, inset=inset, mask_angle=mask_angle, excess=excess, flat_top=flat_top);
    default_tag("remove") {
        attachable(anchor,spin, two_d=true, path=path, extent=false) {
            polygon(path);
            children();
        }
    }
}

function mask2d_rabbet(size, inset=[0,0], mask_angle=90, excess=0.01, flat_top=true, anchor=CTR, spin=0) =
    assert(is_finite(size)||(is_vector(size)&&len(size)==2))
    assert(is_finite(mask_angle) && mask_angle>0 && mask_angle<180)
    assert(is_finite(excess))
    assert(is_bool(flat_top))
    let(
        size = is_list(size)? size : [size,size],
        pts = _inset_isect(inset,mask_angle,flat_top,excess,size=size),
        path = [
            each select(pts, 1, 4),
            pts[6],
            pts[0],
        ]
    ) reorient(anchor,spin, two_d=true, path=path, extent=false, p=path);


// Function&Module: mask2d_dovetail()
// Synopsis: Creates a 2D dovetail mask shape.
// SynTags: Geom, Path
// Topics: Masks (2D), Shapes (2D), Paths (2D), Path Generators, Attachable 
// See Also: corner_profile(), edge_profile(), face_profile()
// Usage: As Module
//   mask2d_dovetail(edge, [angle], [inset], [shelf], [excess], ...) [ATTACHMENTS];
//   mask2d_dovetail(x=, [angle=], [inset=], [shelf=], [excess=], ...) [ATTACHMENTS];
//   mask2d_dovetail(y=, [angle=], [inset=], [shelf=], [excess=], ...) [ATTACHMENTS];
// Usage: As Function
//   path = mask2d_dovetail(edge, [angle], [inset], [shelf], [excess]);
// Description:
//   Creates a 2D dovetail mask shape that is useful for extruding into a 3D mask for a 90° edge.
//   Conversely, you can use that same extruded shape to make an interior dovetail between two walls at a 90º angle.
//   As a 2D mask, this is designed to be differenced away from the edge of a shape that is in the first (X+Y+) quadrant.
//   If called as a function, this just returns a 2D path of the outline of the mask shape.
// Arguments:
//   edge = The length of the edge of the dovetail.
//   angle = The angle of the chamfer edge, away from vertical.  Default: 30.
//   shelf = The extra height to add to the inside corner of the dovetail.  Default: 0
//   inset = Optional amount to inset code from corner.  Default: 0
//   mask_angle = Number of degrees in the corner angle to mask.  Default: 90
//   excess = Extra amount of mask shape to creates on the X- and Y- sides of the shape.  Default: 0.01
//   ---
//   x = The width of the dovetail.
//   y = The height of the dovetail.
//   flat_top = If true, the top inset of the mask will be horizontal instead of angled by the mask_angle.  Default: true.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
// Side Effects:
//  Tags the children with "remove" (and hence sets `$tag`) if no tag is already set.
// Example(2D): 2D Dovetail Mask
//   mask2d_dovetail(x=10);
// Example(2D): 2D Dovetail Mask by Width.
//   mask2d_dovetail(x=10, angle=30);
// Example(2D): 2D Dovetail Mask by Height.
//   mask2d_dovetail(y=10, angle=30);
// Example(2D): 2D Inset Dovetail Mask
//   mask2d_dovetail(x=10, inset=2);
// Example: Masking by Edge Attachment
//   diff()
//   cube([50,60,70],center=true)
//       edge_profile([TOP,"Z"],except=[BACK,TOP+LEFT])
//           mask2d_dovetail(x=10, inset=2);
// Example: Making an interior dovetail
//   %render() difference() {
//       move(-[5,0,5]) cube(30, anchor=BOT+LEFT);
//       cube(310, anchor=BOT+LEFT);
//   }
//   xrot(90)
//       linear_extrude(height=30, center=true)
//           mask2d_dovetail(x=10);
module mask2d_dovetail(edge, angle=30, shelf=0, inset=0, mask_angle=90, excess=0.01, flat_top=true, x, y, anchor=CENTER, spin=0) {
    path = mask2d_dovetail(x=x, y=y, edge=edge, angle=angle, inset=inset, shelf=shelf, excess=excess, flat_top=flat_top, mask_angle=mask_angle);
    default_tag("remove") {
        attachable(anchor,spin, two_d=true, path=path) {
            polygon(path);
            children();
        }
    }
}

function mask2d_dovetail(edge, angle=30, shelf=0, inset=0, mask_angle=90, excess=0.01, flat_top=true, x, y, anchor=CENTER, spin=0) =
    assert(num_defined([x,y,edge])==1)
    assert(is_finite(first_defined([x,y,edge])))
    assert(is_finite(angle))
    assert(is_finite(excess))
    assert(is_finite(inset)||(is_vector(inset)&&len(inset)==2))
    let(
        inset = is_list(inset)? inset : [inset,inset],
        x = !is_undef(x)? x :
            !is_undef(y)? adj_ang_to_opp(adj=y,ang=angle) :
            hyp_ang_to_opp(hyp=edge,ang=angle),
        y = opp_ang_to_adj(opp=x,ang=angle),
        pts = _inset_isect(inset,mask_angle,flat_top,excess,size=[x,y+shelf]),
        path = [
            [max(0,pts[5].x),-excess],
            each select(pts, 2, 4),
            pts[6],
            pts[6]-[0,shelf],
            pts[5],
        ]
    ) reorient(anchor,spin, two_d=true, path=path, p=path);


// Function&Module: mask2d_teardrop()
// Synopsis: Creates a 2D teardrop mask shape with a controllable maximum angle from vertical.
// SynTags: Geom, Path
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable, Masks (2D), FDM Optimized
// See Also: corner_profile(), edge_profile(), face_profile()
// Usage: As Module
//   mask2d_teardrop(r|d=, [angle], [mask_angle], [excess]) [ATTACHMENTS];
// Usage: As Function
//   path = mask2d_teardrop(r|d=, [angle], [mask_angle], [excess]);
// Description:
//   Creates a 2D teardrop mask shape that is useful for extruding into a 3D mask for an edge.
//   Conversely, you can use that same extruded shape to make an interior teardrop fillet between two walls.
//   As a 2D mask, this is designed to be differenced away from the edge of a shape that is in the first (X+Y+) quadrant.
//   If called as a function, this just returns a 2D path of the outline of the mask shape.
//   This is particularly useful to make partially rounded bottoms, that don't need support to print.
//   The roundover can be specified by radius, diameter, height, cut, or joint length.
//   ![Types of Roundovers](images/rounding/section-types-of-roundovers_fig1.png)
// Arguments:
//   r = Radius of the rounding.
//   angle = The maximum angle from vertical.
//   inset = Optional bead inset size.  Default: 0
//   mask_angle = Number of degrees in the corner angle to mask.  Default: 90
//   excess = Extra amount of mask shape to creates on the X- and Y- sides of the shape. Default: 0.01
//   ---
//   d = Diameter of the rounding.
//   h = Mask height.  Given instead of r or d when you want a consistent mask height, no matter what the mask angle.
//   cut = Cut distance.  IE: How much of the corner to cut off.  See [Types of Roundovers](rounding.scad#section-types-of-roundovers).
//   joint = Joint distance.  IE: How far from the edge the roundover should start.  See [Types of Roundovers](rounding.scad#section-types-of-roundovers).
//   flat_top = If true, the top inset of the mask will be horizontal instead of angled by the mask_angle.  Default: true.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
// Side Effects:
//  Tags the children with "remove" (and hence sets `$tag`) if no tag is already set.
// Example(2D): 2D Teardrop Mask
//   mask2d_teardrop(r=10);
// Example(2D): 2D Teardrop Mask for a Non-Right Edge
//   mask2d_teardrop(r=10, mask_angle=75);
// Example(2D): Increasing Excess
//   mask2d_teardrop(r=10, mask_angle=75, excess=2);
// Example(2D): Using a Custom Angle
//   mask2d_teardrop(r=10,angle=30);
// Example: Masking by Edge Attachment
//   diff()
//   cube([50,60,70],center=true)
//       edge_profile(BOT)
//           mask2d_teardrop(r=10, angle=40);
// Example: Making an interior teardrop fillet
//   %render() difference() {
//       move(-[5,0,5]) cube(30, anchor=BOT+LEFT);
//       cube(310, anchor=BOT+LEFT);
//   }
//   xrot(90)
//       linear_extrude(height=30, center=true)
//           mask2d_teardrop(r=10);
function mask2d_teardrop(r, angle=45, inset=[0,0], mask_angle=90, excess=0.01, flat_top=true, d, h, cut, joint, anchor=CENTER, spin=0) =  
    assert(one_defined([r,d,h,cut,joint],"r,d,h,cut,joint"))
    assert(is_undef(r) || is_finite(r))
    assert(is_undef(d) || is_finite(d))
    assert(is_undef(h) || is_finite(h))
    assert(is_undef(cut) || is_finite(cut))
    assert(is_undef(joint) || is_finite(joint))
    assert(is_finite(angle))
    assert(angle>0 && angle<90)
    assert(is_finite(mask_angle) && mask_angle>0 && mask_angle<180)
    assert(is_finite(excess))
    let(
        r = is_finite(joint)? adj_ang_to_opp(joint, mask_angle/2) :
            is_finite(h)? (
                mask_angle==90? h :
                mask_angle < 90 ? adj_ang_to_opp(opp_ang_to_hyp(h,mask_angle), mask_angle/2) :
                adj_ang_to_opp(adj_ang_to_hyp(h,mask_angle-90), mask_angle/2)
            ) :
            is_finite(cut)
              ? let(
                    o = adj_ang_to_opp(cut, mask_angle/2),
                    h = adj_ang_to_hyp(cut, mask_angle/2)
                ) adj_ang_to_opp(o+h, mask_angle/2)
              : get_radius(r=r,d=d,dflt=undef),
        pts = _inset_isect(inset,mask_angle,flat_top,excess,-r),
        arcpts = arc(r=r, corner=[pts[4],pts[5],pts[0]]),
        arcpts2 = [
            for (i = idx(arcpts))
            if(i==0 || v_theta(arcpts[i]-arcpts[i-1]) <= angle-90)
            arcpts[i]
        ],
        line1 = [last(arcpts2), last(arcpts2) + polar_to_xy(1, angle-90)],
        line2 = [[0,inset.y], [100,inset.y]],
        ipt = line_intersection(line1,line2),
        path = [
            [ipt.x, -excess],
            each select(pts, 2, 3),
            each arcpts2,
            ipt,
        ]
    ) reorient(anchor,spin, two_d=true, path=path, p=path);

module mask2d_teardrop(r, angle=45, mask_angle=90, excess=0.01, flat_top=true, d, h, cut, joint, anchor=CENTER, spin=0) {
    path = mask2d_teardrop(r=r, d=d, h=h, cut=cut, joint=joint, angle=angle, mask_angle=mask_angle, excess=excess);
    default_tag("remove") {
        attachable(anchor,spin, two_d=true, path=path) {
            polygon(path);
            children();
        }
    }
}


// Function&Module: mask2d_ogee()
// Synopsis: Creates a 2D ogee mask shape.
// SynTags: Geom, Path
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable, Masks (2D)
// See Also: corner_profile(), edge_profile(), face_profile()
// Usage: As Module
//   mask2d_ogee(pattern, [excess], ...) [ATTAHCMENTS];
// Usage: As Function
//   path = mask2d_ogee(pattern, [excess], ...);
//
// Description:
//   Creates a 2D Ogee mask shape that is useful for extruding into a 3D mask for a 90° edge.
//   Conversely, you can use that same extruded shape to make an interior ogee decoration between two walls at a 90º angle.
//   As a 2D mask, this is designed to be differenced away from the edge of a shape that is in the first (X+Y+) quadrant.
//   Since there are a number of shapes that fall under the name ogee, the shape of this mask is given as a pattern.
//   Patterns are given as TYPE, VALUE pairs.  ie: `["fillet",10, "xstep",2, "step",[5,5], ...]`.  See Patterns below.
//   If called as a function, this just returns a 2D path of the outline of the mask shape.
//   .
//   ### Patterns
//   .
//   Type     | Argument  | Description
//   -------- | --------- | ----------------
//   "step"   | [x,y]     | Makes a line to a point `x` right and `y` down.
//   "xstep"  | dist      | Makes a `dist` length line towards X+.
//   "ystep"  | dist      | Makes a `dist` length line towards Y-.
//   "round"  | radius    | Makes an arc that will mask a roundover.
//   "fillet" | radius    | Makes an arc that will mask a fillet.
//
// Arguments:
//   pattern = A list of pattern pieces to describe the Ogee.
//   excess = Extra amount of mask shape to creates on the X- and Y- sides of the shape. Default: 0.01
//   ---
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//
// Side Effects:
//  Tags the children with "remove" (and hence sets `$tag`) if no tag is already set.
//
// Example(2D): 2D Ogee Mask
//   mask2d_ogee([
//       "xstep",1,  "ystep",1,  // Starting shoulder.
//       "fillet",5, "round",5,  // S-curve.
//       "ystep",1,  "xstep",1   // Ending shoulder.
//   ]);
// Example: Masking by Edge Attachment
//   diff()
//   cube([50,60,70],center=true)
//       edge_profile(TOP)
//           mask2d_ogee([
//               "xstep",1,  "ystep",1,  // Starting shoulder.
//               "fillet",5, "round",5,  // S-curve.
//               "ystep",1,  "xstep",1   // Ending shoulder.
//           ]);
// Example: Making an interior ogee
//   %render() difference() {
//       move(-[5,0,5]) cube(30, anchor=BOT+LEFT);
//       cube(310, anchor=BOT+LEFT);
//   }
//   xrot(90)
//       linear_extrude(height=30, center=true)
//           mask2d_ogee([
//               "xstep", 1, "round",5,
//               "ystep",1, "fillet",5,
//               "xstep", 1, "ystep", 1,
//           ]);
module mask2d_ogee(pattern, excess=0.01, anchor=CENTER,spin=0) {
    path = mask2d_ogee(pattern, excess=excess);
    default_tag("remove") {
        attachable(anchor,spin, two_d=true, path=path) {
            polygon(path);
            children();
        }
    }
}

function mask2d_ogee(pattern, excess=0.01, anchor=CENTER, spin=0) =
    assert(is_list(pattern))
    assert(len(pattern)>0)
    assert(len(pattern)%2==0,"pattern must be a list of TYPE, VAL pairs.")
    assert(all([for (i = idx(pattern,step=2)) in_list(pattern[i],["step","xstep","ystep","round","fillet"])]))
    let(
        x = concat([0], cumsum([
            for (i=idx(pattern,step=2)) let(
                type = pattern[i],
                val = pattern[i+1]
            ) (
                type=="step"?   val.x :
                type=="xstep"?  val :
                type=="round"?  val :
                type=="fillet"? val :
                0
            )
        ])),
        y = concat([0], cumsum([
            for (i=idx(pattern,step=2)) let(
                type = pattern[i],
                val = pattern[i+1]
            ) (
                type=="step"?   val.y :
                type=="ystep"?  val :
                type=="round"?  val :
                type=="fillet"? val :
                0
            )
        ])),
        tot_x = last(x),
        tot_y = last(y),
        data = [
            for (i=idx(pattern,step=2)) let(
                type = pattern[i],
                val = pattern[i+1],
                pt = [x[i/2], tot_y-y[i/2]] + (
                    type=="step"?   [val.x,-val.y] :
                    type=="xstep"?  [val,0] :
                    type=="ystep"?  [0,-val] :
                    type=="round"?  [val,0] :
                    type=="fillet"? [0,-val] :
                    [0,0]
                )
            ) [type, val, pt]
        ],
        path = [
            [tot_x,-excess],
            [-excess,-excess],
            [-excess,tot_y],
            for (pat = data) each
                pat[0]=="step"?  [pat[2]] :
                pat[0]=="xstep"? [pat[2]] :
                pat[0]=="ystep"? [pat[2]] :
                let(
                    r = pat[1],
                    steps = segs(abs(r)),
                    step = 90/steps
                ) [
                    for (i=[0:1:steps]) let(
                        a = pat[0]=="round"? (180+i*step) : (90-i*step)
                    ) pat[2] + abs(r)*[cos(a),sin(a)]
                ]
        ],
        path2 = deduplicate(path)
    ) reorient(anchor,spin, two_d=true, path=path2, p=path2);



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
