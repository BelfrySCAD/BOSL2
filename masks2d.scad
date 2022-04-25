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
// Usage: As module
//   mask2d_roundover(r|d=, [inset], [excess]) [ATTACHMENTS];
// Usage: As function
//   path = mask2d_roundover(r|d=, [inset], [excess]);
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable, Masks (2D)
// See Also: corner_profile(), edge_profile(), face_profile()
// Description:
//   Creates a 2D roundover/bead mask shape that is useful for extruding into a 3D mask for a 90° edge.
//   This 2D mask is designed to be differenced away from the edge of a shape that is in the first (X+Y+) quadrant.
//   If called as a function, this just returns a 2D path of the outline of the mask shape.
// Arguments:
//   r = Radius of the roundover.
//   inset = Optional bead inset size.  Default: 0
//   excess = Extra amount of mask shape to creates on the X- and Y- sides of the shape.  Default: 0.01
//   ---
//   d = Diameter of the roundover.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
// Example(2D): 2D Roundover Mask
//   mask2d_roundover(r=10);
// Example(2D): 2D Bead Mask
//   mask2d_roundover(r=10,inset=2);
// Example: Masking by Edge Attachment
//   diff("mask")
//   cube([50,60,70],center=true)
//       edge_profile([TOP,"Z"],except=[BACK,TOP+LEFT])
//           mask2d_roundover(r=10, inset=2);
module mask2d_roundover(r, inset=0, excess=0.01, d, anchor=CENTER,spin=0) {
    path = mask2d_roundover(r=r,d=d,excess=excess,inset=inset);
    attachable(anchor,spin, two_d=true, path=path) {
        polygon(path);
        children();
    }
}

function mask2d_roundover(r, inset=0, excess=0.01, d, anchor=CENTER,spin=0) =
    assert(is_finite(r)||is_finite(d))
    assert(is_finite(excess))
    assert(is_finite(inset)||(is_vector(inset)&&len(inset)==2))
    let(
        inset = is_list(inset)? inset : [inset,inset],
        r = get_radius(r=r,d=d,dflt=1),
        steps = quantup(segs(r),4)/4,
        step = 90/steps,
        path = [
            [r+inset.x,-excess],
            [-excess,-excess],
            [-excess, r+inset.y],
            for (i=[0:1:steps]) [r,r] + inset + polar_to_xy(r,180+i*step)
        ]
    ) reorient(anchor,spin, two_d=true, path=path, extent=false, p=path);


// Function&Module: mask2d_cove()
// Usage: As module
//   mask2d_cove(r|d=, [inset], [excess]) [ATTACHMENTS];
// Usage: As function
//   path = mask2d_cove(r|d=, [inset], [excess]);
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable, Masks (2D)
// See Also: corner_profile(), edge_profile(), face_profile()
// Description:
//   Creates a 2D cove mask shape that is useful for extruding into a 3D mask for a 90° edge.
//   This 2D mask is designed to be differenced away from the edge of a shape that is in the first (X+Y+) quadrant.
//   If called as a function, this just returns a 2D path of the outline of the mask shape.
// Arguments:
//   r = Radius of the cove.
//   inset = Optional amount to inset code from corner.  Default: 0
//   excess = Extra amount of mask shape to creates on the X- and Y- sides of the shape.  Default: 0.01
//   ---
//   d = Diameter of the cove.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
// Example(2D): 2D Cove Mask
//   mask2d_cove(r=10);
// Example(2D): 2D Inset Cove Mask
//   mask2d_cove(r=10,inset=3);
// Example: Masking by Edge Attachment
//   diff("mask")
//   cube([50,60,70],center=true)
//       edge_profile([TOP,"Z"],except=[BACK,TOP+LEFT])
//           mask2d_cove(r=10, inset=2);
module mask2d_cove(r, inset=0, excess=0.01, d, anchor=CENTER,spin=0) {
    path = mask2d_cove(r=r,d=d,excess=excess,inset=inset);
    attachable(anchor,spin, two_d=true, path=path) {
        polygon(path);
        children();
    }
}

function mask2d_cove(r, inset=0, excess=0.01, d, anchor=CENTER,spin=0) =
    assert(is_finite(r)||is_finite(d))
    assert(is_finite(excess))
    assert(is_finite(inset)||(is_vector(inset)&&len(inset)==2))
    let(
        inset = is_list(inset)? inset : [inset,inset],
        r = get_radius(r=r,d=d,dflt=1),
        steps = quantup(segs(r),4)/4,
        step = 90/steps,
        path = [
            [r+inset.x,-excess],
            [-excess,-excess],
            [-excess, r+inset.y],
            for (i=[0:1:steps]) inset + polar_to_xy(r,90-i*step)
        ]
    ) reorient(anchor,spin, two_d=true, path=path, p=path);


// Function&Module: mask2d_chamfer()
// Usage: As Module
//   mask2d_chamfer(edge, [angle], [inset], [excess]) [ATTACHMENTS];
//   mask2d_chamfer(y=, [angle=], [inset=], [excess=]) [ATTACHMENTS];
//   mask2d_chamfer(x=, [angle=], [inset=], [excess=]) [ATTACHMENTS];
// Usage: As Function
//   path = mask2d_chamfer(edge, [angle], [inset], [excess]);
//   path = mask2d_chamfer(y=, [angle=], [inset=], [excess=]);
//   path = mask2d_chamfer(x=, [angle=], [inset=], [excess=]);
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable, Masks (2D)
// See Also: corner_profile(), edge_profile(), face_profile()
// Description:
//   Creates a 2D chamfer mask shape that is useful for extruding into a 3D mask for a 90° edge.
//   This 2D mask is designed to be differenced away from the edge of a shape that is in the first (X+Y+) quadrant.
//   If called as a function, this just returns a 2D path of the outline of the mask shape.
//   The edge parameter specifies the length of the chamfer's slanted edge.  Alternatively you can give x or y to
//   specify the width or height.  Only one of x, y, or width is permitted.  
// Arguments:
//   edge = The length of the edge of the chamfer.
//   angle = The angle of the chamfer edge, away from vertical.  Default: 45.
//   inset = Optional amount to inset code from corner.  Default: 0
//   excess = Extra amount of mask shape to creates on the X- and Y- sides of the shape.  Default: 0.01
//   ---
//   x = The width of the chamfer.
//   y = The height of the chamfer.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
// Example(2D): 2D Chamfer Mask
//   mask2d_chamfer(x=10);
// Example(2D): 2D Chamfer Mask by Width.
//   mask2d_chamfer(x=10, angle=30);
// Example(2D): 2D Chamfer Mask by Height.
//   mask2d_chamfer(y=10, angle=30);
// Example(2D): 2D Inset Chamfer Mask
//   mask2d_chamfer(x=10, inset=2);
// Example: Masking by Edge Attachment
//   diff("mask")
//   cube([50,60,70],center=true)
//       edge_profile([TOP,"Z"],except=[BACK,TOP+LEFT])
//           mask2d_chamfer(x=10, inset=2);
module mask2d_chamfer(edge, angle=45, inset=0, excess=0.01, x, y, anchor=CENTER,spin=0) {
    path = mask2d_chamfer(x=x, y=y, edge=edge, angle=angle, excess=excess, inset=inset);
    attachable(anchor,spin, two_d=true, path=path, extent=true) {
        polygon(path);
        children();
    }
}

function mask2d_chamfer(edge, angle=45, inset=0, excess=0.01, x, y, anchor=CENTER,spin=0) =
    let(dummy=one_defined([x,y,edge],["x","y","edge"]))
    assert(is_finite(angle))
    assert(is_finite(excess))
    assert(is_finite(inset)||(is_vector(inset)&&len(inset)==2))
    let(
        inset = is_list(inset)? inset : [inset,inset],
        x = is_def(x)? x :
            is_def(y)? adj_ang_to_opp(adj=y,ang=angle) :
            hyp_ang_to_opp(hyp=edge,ang=angle),
        y = opp_ang_to_adj(opp=x,ang=angle),
        path = [
            [x+inset.x, -excess],
            [-excess, -excess],
            [-excess, y+inset.y],
            [inset.x, y+inset.y],
            [x+inset.x, inset.y]
        ]
    ) reorient(anchor,spin, two_d=true, path=path, extent=true, p=path);


// Function&Module: mask2d_rabbet()
// Usage: As Module
//   mask2d_rabbet(size, [excess]) [ATTACHMENTS];
// Usage: As Function
//   path = mask2d_rabbet(size, [excess]);
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable, Masks (2D)
// See Also: corner_profile(), edge_profile(), face_profile()
// Description:
//   Creates a 2D rabbet mask shape that is useful for extruding into a 3D mask for a 90° edge.
//   This 2D mask is designed to be differenced away from the edge of a shape that is in the first (X+Y+) quadrant.
//   If called as a function, this just returns a 2D path of the outline of the mask shape.
// Arguments:
//   size = The size of the rabbet, either as a scalar or an [X,Y] list.
//   excess = Extra amount of mask shape to creates on the X- and Y- sides of the shape. Default: 0.01
//   ---
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
// Example(2D): 2D Rabbet Mask
//   mask2d_rabbet(size=10);
// Example(2D): 2D Asymmetrical Rabbet Mask
//   mask2d_rabbet(size=[5,10]);
// Example: Masking by Edge Attachment
//   diff("mask")
//   cube([50,60,70],center=true)
//       edge_profile([TOP,"Z"],except=[BACK,TOP+LEFT])
//           mask2d_rabbet(size=10);
module mask2d_rabbet(size, excess=0.01, anchor=CENTER,spin=0) {
    path = mask2d_rabbet(size=size, excess=excess);
    attachable(anchor,spin, two_d=true, path=path, extent=false) {
        polygon(path);
        children();
    }
}

function mask2d_rabbet(size, excess=0.01, anchor=CENTER,spin=0) =
    assert(is_finite(size)||(is_vector(size)&&len(size)==2))
    assert(is_finite(excess))
    let(
        size = is_list(size)? size : [size,size],
        path = [
            [size.x, -excess],
            [-excess, -excess],
            [-excess, size.y],
            size
        ]
    ) reorient(anchor,spin, two_d=true, path=path, extent=false, p=path);


// Function&Module: mask2d_dovetail()
// Usage: As Module
//   mask2d_dovetail(edge, [angle], [inset], [shelf], [excess], ...) [ATTACHMENTS];
//   mask2d_dovetail(x=, [angle=], [inset=], [shelf=], [excess=], ...) [ATTACHMENTS];
//   mask2d_dovetail(y=, [angle=], [inset=], [shelf=], [excess=], ...) [ATTACHMENTS];
// Usage: As Function
//   path = mask2d_dovetail(edge, [angle], [inset], [shelf], [excess]);
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable, Masks (2D)
// See Also: corner_profile(), edge_profile(), face_profile()
// Description:
//   Creates a 2D dovetail mask shape that is useful for extruding into a 3D mask for a 90° edge.
//   This 2D mask is designed to be differenced away from the edge of a shape that is in the first (X+Y+) quadrant.
//   If called as a function, this just returns a 2D path of the outline of the mask shape.
// Arguments:
//   edge = The length of the edge of the dovetail.
//   angle = The angle of the chamfer edge, away from vertical.  Default: 30.
//   inset = Optional amount to inset code from corner.  Default: 0
//   shelf = The extra height to add to the inside corner of the dovetail.  Default: 0
//   excess = Extra amount of mask shape to creates on the X- and Y- sides of the shape.  Default: 0.01
//   ---
//   x = The width of the dovetail.
//   y = The height of the dovetail.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
// Example(2D): 2D Dovetail Mask
//   mask2d_dovetail(x=10);
// Example(2D): 2D Dovetail Mask by Width.
//   mask2d_dovetail(x=10, angle=30);
// Example(2D): 2D Dovetail Mask by Height.
//   mask2d_dovetail(y=10, angle=30);
// Example(2D): 2D Inset Dovetail Mask
//   mask2d_dovetail(x=10, inset=2);
// Example: Masking by Edge Attachment
//   diff("mask")
//   cube([50,60,70],center=true)
//       edge_profile([TOP,"Z"],except=[BACK,TOP+LEFT])
//           mask2d_dovetail(x=10, inset=2);
module mask2d_dovetail(edge, angle=30, inset=0, shelf=0, excess=0.01, x, y, anchor=CENTER, spin=0) {
    path = mask2d_dovetail(x=x, y=y, edge=edge, angle=angle, inset=inset, shelf=shelf, excess=excess);
    attachable(anchor,spin, two_d=true, path=path) {
        polygon(path);
        children();
    }
}

function mask2d_dovetail(edge, angle=30, inset=0, shelf=0, excess=0.01, x, y, anchor=CENTER, spin=0) =
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
        path = [
            [inset.x,0],
            [-excess, 0],
            [-excess, y+inset.y+shelf],
            inset+[x,y+shelf],
            inset+[x,y],
            inset
        ]
    ) reorient(anchor,spin, two_d=true, path=path, p=path);


// Function&Module: mask2d_teardrop()
// Usage: As Module
//   mask2d_teardrop(r|d=, [angle], [excess]) [ATTACHMENTS];
// Usage: As Function
//   path = mask2d_teardrop(r|d=, [angle], [excess]);
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable, Masks (2D)
// See Also: corner_profile(), edge_profile(), face_profile()
// Description:
//   Creates a 2D teardrop mask shape that is useful for extruding into a 3D mask for a 90° edge.
//   This 2D mask is designed to be differenced away from the edge of a shape that is in the first (X+Y+) quadrant.
//   If called as a function, this just returns a 2D path of the outline of the mask shape.
//   This is particularly useful to make partially rounded bottoms, that don't need support to print.
// Arguments:
//   r = Radius of the rounding.
//   angle = The maximum angle from vertical.
//   excess = Extra amount of mask shape to creates on the X- and Y- sides of the shape. Default: 0.01
//   ---
//   d = Diameter of the rounding.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
// Example(2D): 2D Teardrop Mask
//   mask2d_teardrop(r=10);
// Example(2D): Using a Custom Angle
//   mask2d_teardrop(r=10,angle=30);
// Example: Masking by Edge Attachment
//   diff("mask")
//   cube([50,60,70],center=true)
//       edge_profile(BOT)
//           mask2d_teardrop(r=10, angle=40);
function mask2d_teardrop(r, angle=45, excess=0.01, d, anchor=CENTER, spin=0) =  
    assert(is_finite(angle))
    assert(angle>0 && angle<90)
    assert(is_finite(excess))
    let(
        r = get_radius(r=r, d=d, dflt=1),
        n = ceil(segs(r) * angle/360),
        cp = [r,r],
        tp = cp + polar_to_xy(r,180+angle),
        bp = [tp.x+adj_ang_to_opp(tp.y,angle), 0],
        step = angle/n,
        path = [
            bp, bp-[0,excess], [-excess,-excess], [-excess,r],
            for (i=[0:1:n]) cp+polar_to_xy(r,180+i*step)
        ]
    ) reorient(anchor,spin, two_d=true, path=path, p=path);

module mask2d_teardrop(r, angle=45, excess=0.01, d, anchor=CENTER, spin=0) {
    path = mask2d_teardrop(r=r, d=d, angle=angle, excess=excess);
    attachable(anchor,spin, two_d=true, path=path) {
        polygon(path);
        children();
    }
}

// Function&Module: mask2d_ogee()
// Usage: As Module
//   mask2d_ogee(pattern, [excess], ...) [ATTAHCMENTS];
// Usage: As Function
//   path = mask2d_ogee(pattern, [excess], ...);
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable, Masks (2D)
// See Also: corner_profile(), edge_profile(), face_profile()
//
// Description:
//   Creates a 2D Ogee mask shape that is useful for extruding into a 3D mask for a 90° edge.
//   This 2D mask is designed to be `difference()`d  away from the edge of a shape that is in the first (X+Y+) quadrant.
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
// Example(2D): 2D Ogee Mask
//   mask2d_ogee([
//       "xstep",1,  "ystep",1,  // Starting shoulder.
//       "fillet",5, "round",5,  // S-curve.
//       "ystep",1,  "xstep",1   // Ending shoulder.
//   ]);
// Example: Masking by Edge Attachment
//   diff("mask")
//   cube([50,60,70],center=true)
//       edge_profile(TOP)
//           mask2d_ogee([
//               "xstep",1,  "ystep",1,  // Starting shoulder.
//               "fillet",5, "round",5,  // S-curve.
//               "ystep",1,  "xstep",1   // Ending shoulder.
//           ]);
module mask2d_ogee(pattern, excess=0.01, anchor=CENTER,spin=0) {
    path = mask2d_ogee(pattern, excess=excess);
    attachable(anchor,spin, two_d=true, path=path) {
        polygon(path);
        children();
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



