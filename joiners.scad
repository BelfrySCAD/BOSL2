//////////////////////////////////////////////////////////////////////
// LibFile: joiners.scad
//   Modules for joining separately printed parts including screw together, snap-together and dovetails.
// Includes:
//   include <BOSL2/std.scad>
//   include <BOSL2/joiners.scad>
// FileGroup: Parts
// FileSummary: Joiner shapes for connecting separately printed objects.
//////////////////////////////////////////////////////////////////////


include <rounding.scad>


// Section: Half Joiners


// Function&Module: half_joiner_clear()
// Synopsis: Creates a mask to clear space for a {{half_joiner()}}.
// SynTags: Geom, VNF
// Topics: Joiners, Parts
// See Also: half_joiner_clear(), half_joiner(), half_joiner2(), joiner_clear(), joiner(), snap_pin(), rabbit_clip(), dovetail()
// Usage: As Module
//   half_joiner_clear(l, w, [ang=], [clearance=], [overlap=]) [ATTACHMENTS];
// Usage: As Function
//   vnf = half_joiner_clear(l, w, [ang=], [clearance=], [overlap=]);
// Description:
//   Creates a mask to clear an area so that a half_joiner can be placed there.
// Arguments:
//   l = Length of the joiner to clear space for.
//   w = Width of the joiner to clear space for.
//   ang = Overhang angle of the joiner.
//   ---
//   clearance = Extra width to clear.
//   overlap = Extra depth to clear.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Example:
//   half_joiner_clear();
function half_joiner_clear(l=20, w=10, ang=30, clearance=0, overlap=0.01, anchor=CENTER, spin=0, orient=UP) =
    let(
        guide = [w/3-get_slop()*2, ang_adj_to_opp(ang, l/3)*2, l/3],
        path = [
            [ l/2,-overlap], [ guide.z/2, -guide.y/2-overlap],
            [-guide.z/2, -guide.y/2-overlap], [-l/2,-overlap],
            [-l/2, overlap], [-guide.z/2,  guide.y/2+overlap],
            [ guide.z/2,  guide.y/2+overlap], [ l/2, overlap],
        ],
        dpath = deduplicate(path, closed=true),
        vnf = linear_sweep(dpath, height=w+clearance*2, center=true, spin=90, orient=RIGHT)
    ) reorient(anchor,spin,orient, vnf=vnf, p=vnf);

module half_joiner_clear(l=20, w=10, ang=30, clearance=0, overlap=0.01, anchor=CENTER, spin=0, orient=UP)
{
    vnf = half_joiner_clear(l=l, w=w, ang=ang, clearance=clearance, overlap=overlap);
    attachable(anchor,spin,orient, vnf=vnf) {
        vnf_polyhedron(vnf, convexity=2);
        children();
    }
}


// Function&Module: half_joiner()
// Synopsis: Creates a half-joiner shape to mate with a {{half_joiner2()}} shape..
// SynTags: Geom, VNF
// Topics: Joiners, Parts
// See Also: half_joiner_clear(), half_joiner(), half_joiner2(), joiner_clear(), joiner(), snap_pin(), rabbit_clip(), dovetail()
// Usage: As Module
//   half_joiner(l, w, [base=], [ang=], [screwsize=], [$slop=]) [ATTACHMENTS];
// Usage: As Function
//   vnf = half_joiner(l, w, [base=], [ang=], [screwsize=], [$slop=]);
// Description:
//   Creates a half_joiner object that can be attached to a matching half_joiner2 object.
// Arguments:
//   l = Length of the half_joiner.
//   w = Width of the half_joiner.
//   ---
//   base = Length of the backing to the half_joiner.
//   ang = Overhang angle of the half_joiner.
//   screwsize = If given, diameter of screwhole.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   $slop = Printer specific slop value to make parts fit more closely.
// Examples(FlatSpin,VPD=75):
//   half_joiner(screwsize=3);
//   half_joiner(l=20,w=10,base=10);
// Example(3D):
//   diff()
//   cuboid(40)
//       attach([FWD,TOP,RIGHT])
//           xcopies(20) half_joiner();
function half_joiner(l=20, w=10, base=10, ang=30, screwsize, anchor=CENTER, spin=0, orient=UP) =
    let(
        guide = [w/3-get_slop()*2, ang_adj_to_opp(ang, l/3)*2, l/3],
        snap_h = 1,
        snap = [guide.x+snap_h, 2*snap_h, l*0.6],
        slope = guide.z/2/(w/8),
        snap_top = slope * (snap.x-guide.x)/2,

        verts = [
            [-w/2,-base,-l/2], [-w/2,-base,l/2], [w/2,-base,l/2], [w/2,-base,-l/2],

            [-w/2, 0,-l/2],
            [-w/2,-guide.y/2,-guide.z/2],
            [-w/2,-guide.y/2, guide.z/2],
            [-w/2, 0,l/2],
            [ w/2, 0,l/2],
            [ w/2,-guide.y/2, guide.z/2],
            [ w/2,-guide.y/2,-guide.z/2],
            [ w/2, 0,-l/2],

            [-guide.x/2, 0,-l/2],
            [-guide.x/2,-guide.y/2,-guide.z/2],
            [-guide.x/2-w/8,-guide.y/2, 0],
            [-guide.x/2,-guide.y/2, guide.z/2],
            [-guide.x/2, 0,l/2],
            [ guide.x/2, 0,l/2],
            [ guide.x/2,-guide.y/2, guide.z/2],
            [ guide.x/2+w/8,-guide.y/2, 0],
            [ guide.x/2,-guide.y/2,-guide.z/2],
            [ guide.x/2, 0,-l/2],

            [-w/6, -snap.y/2, -snap.z/2],
            [-w/6, -snap.y/2, -guide.z/2],
            [-snap.x/2, 0, min(snap_top-guide.z/2,-default(screwsize,0)*1.1/2)],
            [-w/6,  snap.y/2, -guide.z/2],
            [-w/6,  snap.y/2, -snap.z/2],
            [-snap.x/2, 0, snap_top-snap.z/2],

            [-w/6, -snap.y/2, snap.z/2],
            [-w/6, -snap.y/2, guide.z/2],
            [-snap.x/2, 0, max(guide.z/2-snap_top, default(screwsize,0)*1.1/2)],
            [-w/6,  snap.y/2, guide.z/2],
            [-w/6,  snap.y/2, snap.z/2],
            [-snap.x/2, 0, snap.z/2-snap_top],

            [ w/6, -snap.y/2, snap.z/2],
            [ w/6, -snap.y/2, guide.z/2],
            [ snap.x/2, 0, max(guide.z/2-snap_top, default(screwsize,0)*1.1/2)],
            [ w/6,  snap.y/2, guide.z/2],
            [ w/6,  snap.y/2, snap.z/2],
            [ snap.x/2, 0, snap.z/2-snap_top],

            [ w/6, -snap.y/2, -snap.z/2],
            [ w/6, -snap.y/2, -guide.z/2],
            [ snap.x/2, 0, min(snap_top-guide.z/2,-default(screwsize,0)*1.1/2)],
            [ w/6,  snap.y/2, -guide.z/2],
            [ w/6,  snap.y/2, -snap.z/2],
            [ snap.x/2, 0, snap_top-snap.z/2],

            [-w/6, guide.y/2, -guide.z/2],
            [-guide.x/2-w/8, guide.y/2, 0],
            [-w/6, guide.y/2,  guide.z/2],
            [ w/6, guide.y/2,  guide.z/2],
            [ guide.x/2+w/8, guide.y/2, 0],
            [ w/6, guide.y/2, -guide.z/2],

            if (screwsize != undef) each [
                for (a = [0:45:359]) [guide.x/2+w/8, 0, 0] + screwsize * 1.1 / 2 * [-abs(sin(a))/slope, cos(a), sin(a)],
                for (a = [0:45:359]) [-(guide.x/2+w/8), 0, 0] + screwsize * 1.1 / 2 * [abs(sin(a))/slope, cos(a), sin(a)],
            ]
        ],
        faces = [
            [0,1,2], [2,3,0],

            [0,4,5], [0,5,6], [0,6,1], [1,6,7],
            [3,10,11], [3,9,10], [2,9,3], [2,8,9],

            [1,7,16], [1,16,17], [1,17,8], [1,8,2],
            [0,3,11], [0,11,21], [0,21,12], [0,12,4],

            [10,20,11], [20,21,11],
            [12,13,5], [12,5,4],
            [9,8,18], [17,18,8],
            [6,16,7], [6,15,16],

            [19,10,9], [19,9,18], [19,20,10],
            [6,14,15], [6,5,14], [5,13,14],

            [24,26,25], [26,24,27],
            [22,27,24], [22,24,23],
            [22,26,27],

            [30,32,33], [30,31,32],
            [30,33,28], [30,28,29],
            [32,28,33],

            [40,41,42], [40,42,45],
            [45,42,43], [43,44,45],
            [40,45,44],

            [36,38,37], [36,39,38],
            [36,35,34], [36,34,39],
            [39,34,38],

            [12,26,22], [12,22,13], [22,23,13], [12,46,26], [46,25,26],
            [16,28,32], [16,15,28], [15,29,28], [48,16,32], [32,31,48],
            [17,38,34], [17,34,18], [18,34,35], [49,38,17], [37,38,49],
            [21,40,44], [51,21,44], [43,51,44], [20,40,21], [20,41,40],

            [17,16,49], [49,16,48],
            [21,51,46], [46,12,21],

            [51,50,49], [48,47,46], [46,51,49], [46,49,48],

            if (screwsize == undef) each [
                [19,36,50], [19,35,36], [19,18,35], [36,37,50], [49,50,37],
                [19,50,42], [19,42,41], [41,20,19], [50,43,42], [50,51,43],
                [14,24,47], [14,23,24], [14,13,23], [47,24,25], [46,47,25],
                [47,30,14], [14,30,29], [14,29,15], [47,31,30], [47,48,31],
            ] else each [
                [20,19,56], [20,56,57], [20,57,58], [41,58,42], [20,58,41],
                [50,51,52], [51,59,52], [51,58,59], [43,42,58], [51,43,58],
                [49,50,52], [49,52,53], [49,53,54], [37,54,36], [49,54,37],
                [56,19,18], [18,55,56], [18,54,55], [35,36,54], [18,35,54],
                [14,64,15], [15,64,63], [15,63,62], [29,62,30], [15,62,29],
                [48,31,62], [31,30,62], [48,62,61], [48,61,60], [60,47,48],
                [13,23,66], [23,24,66], [13,66,65], [13,65,64], [64,14,13],
                [46,47,60], [46,60,67], [46,67,66], [46,66,25], [66,24,25],
                for (i=[0:7]) let(b=52) [b+i, b+8+i, b+8+(i+1)%8],
                for (i=[0:7]) let(b=52) [b+i, b+8+(i+1)%8, b+(i+1)%8],
            ],
        ],
        pvnf = [verts, faces],
        vnf = xrot(90, p=pvnf)
    ) reorient(anchor,spin,orient, size=[w,l,base*2], p=vnf);

module half_joiner(l=20, w=10, base=10, ang=30, screwsize, anchor=CENTER, spin=0, orient=UP)
{
    vnf = half_joiner(l=l, w=w, base=base, ang=ang, screwsize=screwsize);
    if (is_list($tags_shown) && in_list("remove",$tags_shown)) {
        attachable(anchor,spin,orient, size=[w,l,base*2], $tag="remove") {
            half_joiner_clear(l=l, w=w, ang=ang, clearance=1);
            union();
        }
    } else {
        attachable(anchor,spin,orient, size=[w,base*2,l], $tag="keep") {
            vnf_polyhedron(vnf, convexity=12);
            children();
        }
    }
}


// Function&Module: half_joiner2()
// Synopsis: Creates a half_joiner2 shape to mate with a {{half_joiner()}} shape..
// SynTags: Geom, VNF
// Topics: Joiners, Parts
// See Also: half_joiner_clear(), half_joiner(), half_joiner2(), joiner_clear(), joiner(), snap_pin(), rabbit_clip(), dovetail()
// Usage: As Module
//   half_joiner2(l, w, [base=], [ang=], [screwsize=])
// Usage: As Function
//   vnf = half_joiner2(l, w, [base=], [ang=], [screwsize=])
// Description:
//   Creates a half_joiner2 object that can be attached to half_joiner object.
// Arguments:
//   l = Length of the half_joiner.
//   w = Width of the half_joiner.
//   ---
//   base = Length of the backing to the half_joiner.
//   ang = Overhang angle of the half_joiner.
//   screwsize = Diameter of screwhole.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Examples(FlatSpin,VPD=75):
//   half_joiner2(screwsize=3);
//   half_joiner2(w=10,base=10,l=20);
// Example(3D):
//   diff()
//   cuboid(40)
//       attach([FWD,TOP,RIGHT])
//           xcopies(20) half_joiner2();
function half_joiner2(l=20, w=10, base=10, ang=30, screwsize, anchor=CENTER, spin=0, orient=UP) =
    let(
        guide = [w/3, ang_adj_to_opp(ang, l/3)*2, l/3],
        snap_h = 1,
        snap = [guide.x+snap_h, 2*snap_h, l*0.6],
        slope = guide.z/2/(w/8),
        snap_top = slope * (snap.x-guide.x)/2,
        s1 = min(snap_top-guide.z/2,-default(screwsize,0)*1.1/2),
        s2 = max(guide.z/2-snap_top, default(screwsize,0)*1.1/2),

        verts = [
            [-w/2,-base,-l/2], [-w/2,-base,l/2], [w/2,-base,l/2], [w/2,-base,-l/2],

            [-w/2, 0,-l/2],
            [-w/2, guide.y/2,-guide.z/2],
            [-w/2, guide.y/2, guide.z/2],
            [-w/2, 0,l/2],
            [ w/2, 0,l/2],
            [ w/2, guide.y/2, guide.z/2],
            [ w/2, guide.y/2,-guide.z/2],
            [ w/2, 0,-l/2],

            [-guide.x/2, 0,-l/2],
            [-guide.x/2,-guide.y/2,-guide.z/2],
            [-guide.x/2-w/8,-guide.y/2, 0],
            [-guide.x/2,-guide.y/2, guide.z/2],
            [-guide.x/2, 0,l/2],
            [ guide.x/2, 0,l/2],
            [ guide.x/2,-guide.y/2, guide.z/2],
            [ guide.x/2+w/8,-guide.y/2, 0],
            [ guide.x/2,-guide.y/2,-guide.z/2],
            [ guide.x/2, 0,-l/2],

            [-w/6, -snap.y/2, -snap.z/2],
            [-w/6, -snap.y/2, -guide.z/2],
            [-snap.x/2, 0, s1],
            [-w/6,  snap.y/2, -guide.z/2],
            [-w/6,  snap.y/2, -snap.z/2],
            [-snap.x/2, 0, snap_top-snap.z/2],

            [-w/6, -snap.y/2, snap.z/2],
            [-w/6, -snap.y/2, guide.z/2],
            [-snap.x/2, 0, s2],
            [-w/6,  snap.y/2, guide.z/2],
            [-w/6,  snap.y/2, snap.z/2],
            [-snap.x/2, 0, snap.z/2-snap_top],

            [ w/6, -snap.y/2, snap.z/2],
            [ w/6, -snap.y/2, guide.z/2],
            [ snap.x/2, 0, s2],
            [ w/6,  snap.y/2, guide.z/2],
            [ w/6,  snap.y/2, snap.z/2],
            [ snap.x/2, 0, snap.z/2-snap_top],

            [ w/6, -snap.y/2, -snap.z/2],
            [ w/6, -snap.y/2, -guide.z/2],
            [ snap.x/2, 0, s1],
            [ w/6,  snap.y/2, -guide.z/2],
            [ w/6,  snap.y/2, -snap.z/2],
            [ snap.x/2, 0, snap_top-snap.z/2],

            [-w/6, guide.y/2, -guide.z/2],
            [-guide.x/2-w/8, guide.y/2, 0],
            [-w/6, guide.y/2,  guide.z/2],
            [ w/6, guide.y/2,  guide.z/2],
            [ guide.x/2+w/8, guide.y/2, 0],
            [ w/6, guide.y/2, -guide.z/2],

            if (screwsize != undef) each [
                for (a = [0:45:359]) [guide.x/2+w/8, 0, 0] + screwsize * 1.1 / 2 * [-abs(sin(a))/slope, cos(a), sin(a)],
                for (a = [0:45:359]) [-(guide.x/2+w/8), 0, 0] + screwsize * 1.1 / 2 * [abs(sin(a))/slope, cos(a), sin(a)],
                for (a = [0:45:359]) [w/2, 0, 0] + screwsize * 1.1 / 2 * [0, cos(a), sin(a)],
                for (a = [0:45:359]) [-w/2, 0, 0] + screwsize * 1.1 / 2 * [0, cos(a), sin(a)],
            ]
        ],
        faces = [
            [0,1,2], [2,3,0],

            [1,7,16], [1,16,17], [1,17,8], [1,8,2],
            [0,3,11], [0,11,21], [0,21,12], [0,12,4],

            [10,51,11], [51,21,11],
            [12,46,5], [12,5,4],
            [9,8,49], [17,49,8],
            [6,16,7], [6,48,16],

            [50,10,9], [50,9,49], [50,51,10],
            [6,47,48], [6,5,47], [5,46,47],

            [24,25,26], [26,27,24],
            [22,24,27], [22,23,24],
            [22,27,26],

            [30,33,32], [30,32,31],
            [30,28,33], [30,29,28],
            [32,33,28],

            [40,42,41], [40,45,42],
            [45,43,42], [43,45,44],
            [40,44,45],

            [36,37,38], [36,38,39],
            [36,34,35], [36,39,34],
            [39,38,34],

            [12,22,26], [12,13,22], [22,13,23], [12,26,46], [46,26,25],
            [16,32,28], [16,28,15], [15,28,29], [48,32,16], [32,48,31],
            [17,34,38], [17,18,34], [18,35,34], [49,17,38], [37,49,38],
            [21,44,40], [51,44,21], [43,44,51], [20,21,40], [20,40,41],

            [17,16,18], [18,16,15],
            [21,20,13], [13,12,21],

            [20,19,18], [15,14,13], [13,20,18], [13,18,15],

            if (screwsize == undef) each [
                [0,4,5], [0,5,6], [0,6,1], [1,6,7],
                [3,10,11], [3,9,10], [2,9,3], [2,8,9],

                [19,50,36], [19,36,35], [19,35,18], [36,50,37], [49,37,50],
                [19,42,50], [19,41,42], [41,19,20], [50,42,43], [50,43,51],
                [14,47,24], [14,24,23], [14,23,13], [47,25,24], [46,25,47],
                [47,14,30], [14,29,30], [14,15,29], [47,30,31], [47,31,48],
            ] else each [
                [3,2,72], [2,71,72], [2,70,71], [2,8,70],
                [8,9,70], [9,69,70], [9,68,69], [9,10,68],
                [10,75,68], [10,74,75], [10,11,74],
                [3,72,73], [3,73,74], [3,74,11],

                [1,0,80], [0,81,80], [0,82,81], [0,4,82],
                [4,5,82], [5,83,82], [5,76,83], [5,6,76],
                [6,77,76], [6,78,77], [6,7,78],
                [7,1,78], [1,79,78], [1,80,79],

                [20,56,19], [20,57,56], [20,41,57], [41,58,57], [41,42,58],
                [50,52,51], [51,52,59], [43,59,58], [43,58,42], [51,59,43],
                [49,52,50], [49,53,52], [49,37,53], [37,36,54], [54,53,37],
                [56,18,19], [18,56,55], [18,55,35], [35,55,54], [36,35,54],
                [14,15,64], [15,63,64], [15,29,63], [29,62,63], [29,30,62],
                [31,48,61], [31,61,62], [30,31,62], [48,60,61], [60,48,47],
                [23,13,65], [65,66,23], [24,23,66], [13,64,65], [64,13,14],
                [46,60,47], [46,67,60], [46,25,67], [66,67,25], [25,24,66],

                for (i=[0:7]) let(b=52) each [
                    [b+i, b+16+(i+1)%8, b+16+i],
                    [b+i, b+(i+1)%8, b+16+(i+1)%8],
                ],
                for (i=[0:7]) let(b=60) each [
                    [b+i, b+16+i, b+16+(i+1)%8],
                    [b+i, b+16+(i+1)%8, b+(i+1)%8],
                ],
            ],
        ],
        verts2 = [
            for (i = idx(verts))
            !approx(s2, verts[54].z)? verts[i] :
            i==54? [ snap.x/2-0.01, verts[i].y, verts[i].z] :
            i==58? [ snap.x/2-0.01, verts[i].y, verts[i].z] :
            i==62? [-snap.x/2+0.01, verts[i].y, verts[i].z] :
            i==66? [-snap.x/2+0.01, verts[i].y, verts[i].z] :
            verts[i]
        ],
        pvnf = [verts2, faces],
        vnf = xrot(90, p=pvnf)
    ) reorient(anchor,spin,orient, size=[w,l,base*2], p=vnf);

module half_joiner2(l=20, w=10, base=10, ang=30, screwsize, anchor=CENTER, spin=0, orient=UP)
{
    vnf = half_joiner2(l=l, w=w, base=base, ang=ang, screwsize=screwsize);
    if (is_list($tags_shown) && in_list("remove",$tags_shown)) {
        attachable(anchor,spin,orient, size=[w,l,base*2], $tag="remove") {
            half_joiner_clear(l=l, w=w, ang=ang, clearance=1);
            union();
        }
    } else {
        attachable(anchor,spin,orient, size=[w,base*2,l], $tag="keep") {
            vnf_polyhedron(vnf, convexity=12);
            children();
        }
    }
}



// Section: Full Joiners


// Module: joiner_clear()
// Synopsis: Creates a mask to clear space for a {{joiner()}} shape.
// SynTags: Geom
// Topics: Joiners, Parts
// See Also: half_joiner_clear(), half_joiner(), half_joiner2(), joiner_clear(), joiner(), snap_pin(), rabbit_clip(), dovetail()
// Description:
//   Creates a mask to clear an area so that a joiner can be placed there.
// Usage:
//   joiner_clear(l, w, [ang=], [clearance=], [overlap=]) [ATTACHMENTS];
// Arguments:
//   l = Length of the joiner to clear space for.
//   w = Width of the joiner to clear space for.
//   ang = Overhang angle of the joiner.
//   ---
//   clearance = Extra width to clear.
//   overlap = Extra depth to clear.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Example:
//   joiner_clear();
function joiner_clear(l=40, w=10, ang=30, clearance=0, overlap=0.01, anchor=CENTER, spin=0, orient=UP) = no_function("joiner_clear");
module joiner_clear(l=40, w=10, ang=30, clearance=0, overlap=0.01, anchor=CENTER, spin=0, orient=UP)
{
    dmnd_height = l*0.5;
    dmnd_width = dmnd_height*tan(ang);
    guide_size = w/3;
    guide_width = 2*(dmnd_height/2-guide_size)*tan(ang);

    attachable(anchor,spin,orient, size=[w, guide_width, l]) {
        union() {
            back(l/4) half_joiner_clear(l=l/2+0.01, w=w, ang=ang, overlap=overlap, clearance=clearance);
            fwd(l/4) half_joiner_clear(l=l/2+0.01, w=w, ang=ang, overlap=overlap, clearance=-0.01);
        }
        children();
    }
}



// Module: joiner()
// Synopsis: Creates a joiner shape that can mate with another rotated joiner shape.
// SynTags: Geom
// Topics: Joiners, Parts
// See Also: half_joiner_clear(), half_joiner(), half_joiner2(), joiner_clear(), joiner(), snap_pin(), rabbit_clip(), dovetail()
// Usage:
//   joiner(l, w, base, [ang=], [screwsize=], [$slop=]) [ATTACHMENTS];
// Description:
//   Creates a joiner object that can be attached to another joiner object.
// Arguments:
//   l = Length of the joiner.
//   w = Width of the joiner.
//   base = Length of the backing to the joiner.
//   ang = Overhang angle of the joiner.
//   ---
//   screwsize = If given, diameter of screwhole.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   $slop = Printer specific slop value to make parts fit more closely.
// Examples(FlatSpin,VPD=125):
//   joiner(screwsize=3);
//   joiner(l=40, w=10, base=10);
// Example(3D):
//   diff()
//   cuboid(50)
//     attach([FWD,TOP,RIGHT])
//       zrot_copies(n=2,r=15)
//         joiner();
function joiner(l=40, w=10, base=10, ang=30, screwsize, anchor=CENTER, spin=0, orient=UP) = no_function("joiner");
module joiner(l=40, w=10, base=10, ang=30, screwsize, anchor=CENTER, spin=0, orient=UP)
{
    if (is_list($tags_shown) && in_list("remove",$tags_shown)) {
        attachable(anchor,spin,orient, size=[w,l,base*2], $tag="remove") {
            joiner_clear(w=w, l=l, ang=ang, clearance=1);
            union();
        }
    } else {
        attachable(anchor,spin,orient, size=[w,l,base*2], $tag="keep") {
            union() {
                back(l/4) half_joiner(l=l/2, w=w, base=base, ang=ang, screwsize=screwsize);
                fwd(l/4) half_joiner2(l=l/2, w=w, base=base, ang=ang, screwsize=screwsize);
            }
            children();
        }
    }
}



// Section: Dovetails

// Module: dovetail()
// Synopsis: Creates a possibly tapered dovetail shape.
// SynTags: Geom
// Topics: Joiners, Parts
// See Also: joiner(), snap_pin(), rabbit_clip(), partition(), partition_mask(), partition_cut_mask()
//
// Usage:
//   dovetail(gender, w=|width, h=|height, slide|thickness=, [slope=|angle=], [taper=|back_width=], [chamfer=], [r=|radius=], [round=], [extra=], [$slop=])
//
// Description:
//   Produces a possibly tapered dovetail joint shape to attach to or subtract from two parts you wish to join together.
//   The tapered dovetail is particularly advantageous for long joints because the joint assembles without binding until
//   it is fully closed, and then wedges tightly.  You can chamfer or round the corners of the dovetail shape for better
//   printing and assembly, or choose a fully rounded joint that looks more like a puzzle piece.  The dovetail appears
//   parallel to the Y axis and projecting upwards, so in its default orientation it will slide together with a translation
//   in the positive Y direction.  The gender determines whether the shape is meant to be added to your model or
//   differenced, and it also changes the anchor and orientation.  The default anchor for dovetails is BOTTOM;
//   the default orientation depends on the gender, with male dovetails oriented UP and female ones DOWN.  The dovetails by default
//   have extra extension of 0.01 for unions and differences.  You should ensure that attachment is done with overlap=0 to ensure that
//   the sizing and positioning is correct.  To adjust the fit, use the $slop variable, which increases the depth and width of
//   the female part of the joint to allow a clearance gap of $slop on each of the three sides.
//
// Arguments:
//   gender = A string, "male" or "female", to specify the gender of the dovetail.
//   w / width = Width (at the wider, top end) of the dovetail before tapering
//   h / height = Height of the dovetail (the amount it projects from its base)
//   slide / thickness = Distance the dovetail slides when you assemble it (length of sliding dovetails, thickness of regular dovetails)
//   ---
//   slope = slope of the dovetail.  Standard woodworking slopes are 4, 6, or 8.  Default: 6.
//   angle = angle (in degrees) of the dovetail.  Specify only one of slope and angle.
//   taper = taper angle (in degrees). Dovetail gets narrower by this angle.  Default: no taper
//   back_width = width of right hand end of the dovetail.  This alternate method of specifying the taper may be easier to manage.  Specify only one of `taper` and `back_width`.  Note that `back_width` should be smaller than `width` to taper in the customary direction, with the smaller end at the back.
//   chamfer = amount to chamfer the corners of the joint (Default: no chamfer)
//   r / radius = amount to round over the corners of the joint (Default: no rounding)
//   round = true to round both corners of the dovetail and give it a puzzle piece look.  Default: false.
//   $slop = Increase the width of socket by double this amount and depth by this amount to allow adjustment of the fit.
//   extra = amount of extra length and base extension added to dovetails for unions and differences.  Default: 0.01
// Example: Ordinary straight dovetail, male version (sticking up) and female version (below the xy plane)
//   dovetail("male", width=15, height=8, slide=30);
//   right(20) dovetail("female", width=15, height=8, slide=30);
// Example: Adding a 6 degree taper (Such a big taper is usually not necessary, but easier to see for the example.)
//   dovetail("male", w=15, h=8, slide=30, taper=6);
//   right(20) dovetail("female", 15, 8, 30, taper=6);  // Same as above
// Example: A block that can link to itself
//   diff()
//     cuboid([50,30,10]){
//       attach(BACK) dovetail("male", slide=10, width=15, height=8);
//       tag("remove")attach(FRONT) dovetail("female", slide=10, width=15, height=8);
//     }
// Example: Setting the dovetail angle.  This is too extreme to be useful.
//   diff()
//     cuboid([50,30,10]){
//       attach(BACK) dovetail("male", slide=10, width=15, height=8, angle=30);
//       tag("remove")attach(FRONT) dovetail("female", slide=10, width=15, height=8, angle=30);
//     }
// Example: Adding a chamfer helps printed parts fit together without problems at the corners
//   diff("remove")
//     cuboid([50,30,10]){
//       attach(BACK) dovetail("male", slide=10, width=15, height=8, chamfer=1);
//       tag("remove")attach(FRONT) dovetail("female", slide=10, width=15, height=8,chamfer=1);
//     }
// Example: Rounding the outside corners is another option
//   diff("remove")
//   cuboid([50,30,10]) {
//       attach(BACK)  dovetail("male", slide=10, width=15, height=8, radius=1, $fn=32);
//       tag("remove") attach(FRONT) dovetail("female", slide=10, width=15, height=8, radius=1, $fn=32);
//   }
// Example: Or you can make a fully rounded joint
//   $fn=32;
//   diff("remove")
//   cuboid([50,30,10]){
//       attach(BACK) dovetail("male", slide=10, width=15, height=8, radius=1.5, round=true);
//       tag("remove")attach(FRONT) dovetail("female", slide=10, width=15, height=8, radius=1.5, round=true);
//   }
// Example: With a long joint like this, a taper makes the joint easy to assemble.  It will go together easily and wedge tightly if you get the tolerances right.  Specifying the taper with `back_width` may be easier than using a taper angle.
//   cuboid([50,30,10])
//     attach(TOP) dovetail("male", slide=50, width=18, height=4, back_width=15, spin=90);
//   fwd(35)
//     diff("remove")
//       cuboid([50,30,10])
//         tag("remove") attach(TOP) dovetail("female", slide=50, width=18, height=4, back_width=15, spin=90);
// Example: A series of dovetails forming a tail board, with the inside of the joint up.  A standard wood joint would have a zero taper.
//   cuboid([50,30,10])
//     attach(BACK) xcopies(10,5) dovetail("male", slide=10, width=7, taper=4, height=4);
// Example: Mating pin board for a half-blind right angle joint, where the joint only shows on the side but not the front.  Note that the anchor method and use of `spin` ensures that the joint works even with a taper.
//   diff("remove")
//     cuboid([50,30,10])
//       tag("remove")position(TOP+BACK) xcopies(10,5) dovetail("female", slide=10, width=7, taper=4, height=4, anchor=BOTTOM+FRONT,spin=180);
function dovetail(gender, width, height, slide, h, w, angle, slope, thickness, taper, back_width, chamfer, extra=0.01, r, radius, round=false, anchor=BOTTOM, spin=0, orient) = no_function("dovetail");
module dovetail(gender, width, height, slide, h, w, angle, slope, thickness, taper, back_width, chamfer, extra=0.01, r, radius, round=false, anchor=BOTTOM, spin=0, orient)
{
    radius = get_radius(r1=radius,r2=r);
    slide = one_defined([slide,thickness],"slide,thickness");
    h = one_defined([h,height],"h,height");
    w = one_defined([w,width],"w,width");
    orient = is_def(orient) ? orient
           : gender == "female" ? DOWN
           : UP;
    count = num_defined([angle,slope]);
    count2 = num_defined([taper,back_width]);
    count3 = num_defined([chamfer, radius]);
    dummy =
        assert(count<=1, "Do not specify both angle and slope")
        assert(count2<=1, "Do not specify both taper and back_width")
        assert(count3<=1 || (radius==0 && chamfer==0), "Do not specify both chamfer and radius");
    slope = is_def(slope) ? slope
          : is_def(angle) ? 1/tan(angle)
          :  6;
    height_slop = gender == "female" ? get_slop() : 0;

    // Need taper angle for computing width adjustment, but not used elsewhere
    taper_ang = is_def(taper) ? taper
              : is_def(back_width) ? atan((back_width-w)/2/slide)
              : 0;
    // This is the adjustment factor for width to grow in the direction normal to the dovetail face
    wfactor = sqrt( 1/slope^2 + 1/cos(taper_ang)^2 );
             // adjust width for increased height    adjust for normal to dovetail surface
    width_slop = 2*height_slop/slope                + 2* height_slop * wfactor;
    width = w + width_slop;
    height = h + height_slop;
    back_width = u_add(back_width, width_slop);

    extra_offset = is_def(taper) ? -extra * tan(taper)
                 : is_def(back_width) ? extra * (back_width-width)/slide/2
                 : 0;

    size = is_def(chamfer) && chamfer>0 ? chamfer
         : is_def(radius) && radius>0 ? radius
         : 0;
    fullsize = round ? [size,size]
             : gender == "male" ? [size,0]
             : [0,size];

    type = is_def(chamfer) && chamfer>0 ? "chamfer" : "circle";

    smallend_half = round_corners(
        move(
            [0,-slide/2-extra,0],
            p=[
                [0,                                     0, height],
                [width/2 - extra_offset,                0, height],
                [width/2 - extra_offset - height/slope, 0, 0     ],
                [width/2 - extra_offset + height,       0, 0     ]
            ]
        ),
        method=type, cut = fullsize, closed=false
    );

    smallend_points = concat(select(smallend_half, 1, -2), [down(extra,p=select(smallend_half, -2))]);
    offset = is_def(taper) ? -slide * tan(taper)
           : is_def(back_width) ? (back_width-width) / 2
           : 0;
    bigend_points = move([offset+2*extra_offset,slide+2*extra,0], p=smallend_points);

    bigenough = all_nonnegative(column(smallend_half,0)) && all_nonnegative(column(bigend_points,0));

    assert(bigenough, "Width (or back_width) of dovetail is not large enough for its geometry (angle and taper");

    //adjustment = $overlap * (gender == "male" ? -1 : 1);  // Adjustment for default overlap in attach()
    adjustment = 0;    // Default overlap is assumed to be zero

    // This code computes the true normal from which the exact width factor can be obtained
    // as the x component.  Comparing to wfactor above shows that they agree.
    //   pts = [smallend_points[0], smallend_points[1], bigend_points[1],bigend_points[0]];
    //   n = -polygon_normal(pts);
    //   echo(n=n);
    //   echo(invwfactor = 1/wfactor, error = n.x-1/wfactor);

    attachable(anchor,spin,orient, size=[width+2*offset, slide, height]) {
        down(height/2+adjustment) {
            //color("red")stroke([pts],width=.1);

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


// Section: Tension Clips

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
   extra = 0.02;         // This sets the extra extension below the socket bottom
                         // so that difference() works without issues
   rPoint = r / sqrt(2);
   down(extra) cylinder(r = r, h = lStraight + extra);
   up(lStraight) {
      zscale(stretch) {
         hull() {
            sphere(r = r);
            if (pointed) up(rPoint) cylinder(r1 = rPoint, r2 = 0, h = rPoint/stretch);
         }
      }
   }
   up(d) yscale(nubscale) _pin_nub(r = r, nub = nub, h = lStraight - d);
}

function _pin_size(size) =
  is_undef(size) ? [] :
  let(sizeok = in_list(size,["tiny", "small","medium", "large", "standard"]))
  assert(sizeok,"Pin size must be one of \"tiny\", \"small\", \"medium\" or \"standard\"")
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
// Synopsis: Creates a snap-pin that can slot into a {{snap_pin_socket()}} to join two parts.
// SynTags: Geom
// Topics: Joiners, Parts
// See Also: snap_pin_socket(), joiner(), dovetail(), snap_pin(), rabbit_clip()
// Usage:
//    snap_pin(size, [pointed=], [anchor=], [spin=], [orient]=) [ATTACHMENTS];
//    snap_pin(r=|radius=|d=|diameter=, l=|length=, nub_depth=, snap=, thickness=, [clearance=], [preload=], [pointed=]) [ATTACHMENTS];
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
//    size = text string to select from a list of predefined sizes, one of "standard", "medium", "small", or "tiny".
//    ---
//    pointed = set to true to get a pointed pin, false to get one with a rounded end.  Default: true
//    r/radius = radius of the pin
//    d/diameter = diameter of the pin
//    l/length = length of the pin
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
function snap_pin(size,r,radius,d,diameter, l,length, nub_depth, snap, thickness, clearance=0.2, preload, pointed=true, anchor=FRONT, spin=0, orient=FRONT, center) =no_function("snap_pin");
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
// Synopsis: Creates a snap-pin socket for a {{snap_pin()}} to slot into.
// SynTags: Geom
// Topics: Joiners, Parts
// See Also: snap_pin(), joiner(), dovetail(), snap_pin(), rabbit_clip()
// Usage:
//   snap_pin_socket(size, [fixed=], [fins=], [pointed=], [anchor=], [spin=], [orient=]) [ATTACHMENTS];
//   snap_pin_socket(r=|radius=|d=|diameter=, l=|length=, nub_depth=, snap=, [fixed=], [pointed=], [fins=]) [ATTACHMENTS];
// Description:
//   Constructs a socket suitable for a snap_pin with the same parameters.   If `fixed` is true then the socket has flat walls and the
//   pin will not rotate in the socket.  If `fixed` is false then the socket is round and the pin will rotate, particularly well
//   if you add a lubricant.  If `pointed` is true the socket is pointed to receive a pointed pin, otherwise it has a rounded and and
//   will be shorter.  If `fins` is set to true then two fins are included inside the socket to act as supports (which may help when printing tip up,
//   especially when `pointed=false`).  The default orientation is DOWN with anchor BOTTOM so that you can difference() the socket away from an object.
//   The socket extends 0.02 extra below its bottom anchor point so that differences will work correctly.  (You must have $overlap smaller than 0.02 in
//   attach or the socket will be beneath the surface of the parent object.)
//   .
//   The "large" or "standard" size pin has a length of 10.8 and diameter of 7.  The "medium" pin has a length of 8 and diameter of 4.6.  The "small" pin
//   has a length of 6 and diameter of 3.2.  The "tiny" pin has a length of 4 and a diameter of 2.5.
// Arguments:
//   size = text string to select from a list of predefined sizes, one of "standard", "medium", "small", or "tiny".
//   ---
//   pointed = set to true to get a pointed pin, false to get one with a rounded end.  Default: true
//   r/radius = radius of the pin
//   d/diameter = diameter of the pin
//   l/length = length of the pin
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
//   diff("socket") cuboid([20,20,20])
//     tag("socket"){
//       attach(TOP) snap_pin_socket("standard");
//       position(TOP+FRONT)snap_pin_socket("standard");
//     }
function snap_pin_socket(size, r, radius, l,length, d,diameter,nub_depth, snap, fixed=true, pointed=true, fins=false, anchor=BOTTOM, spin=0, orient=DOWN) = no_function("snap_pin_socket");
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
      cube([3 * (radius + snap), fixed ? radius * sqrt(2) : 3*(radius+snap), 3 * lPin + 3 * radius], center = true);
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



// Module: rabbit_clip()
// Synopsis: Creates a rabbit-eared clip that can snap into a slot.
// SynTags: Geom
// Topics: Joiners, Parts
// See Also: snap_pin(), joiner(), dovetail(), snap_pin(), rabbit_clip()
// Usage:
//   rabbit_clip(type, length, width, snap, thickness, depth, [compression=], [clearance=], [lock=], [lock_clearance=], [splineteps=], [anchor=], [orient=], [spin=]) [ATTACHMENTS];
// Description:
//   Creates a clip with two flexible ears to lock into a mating socket, or create a mask to produce the appropriate
//   mating socket.  The clip can be made to insert and release easily, or to hold much better, or it can be
//   created with locking flanges that will make it very hard or impossible to remove.  Unlike the snap pin, this clip
//   is rectangular and can be made at any height, so a suitable clip could be very thin.  It's also possible to get a
//   solid connection with a short pin.
//   .
//   The type parameters specifies whether to make a clip, a socket mask, or a double clip.  The length is the
//   total nominal length of the clip.  (The actual length will be very close, but not equal to this.)  The width
//   gives the nominal width of the clip, which is the actual width of the clip at its base.  The snap parameter
//   gives the depth of the clip sides, which controls how easy the clip is to insert and remove.  The clip "ears" are
//   made over-wide by the compression value.  A nonzero compression helps make the clip secure in its socket.
//   The socket's width and length are increased by the clearance value which creates some space and can compensate
//   for printing inaccuracy.  The socket will be slightly longer than the nominal width.  The thickness is the thickness
//   curved line that forms the clip.  The clip depth is the amount the basic clip shape is extruded.  Be sure that you
//   make the socket with a larger depth than the clip (try 0.4 mm) to allow ease of insertion of the clip.  The clearance
//   value does not apply to the depth.  The splinesteps parameter increases the sampling of the clip curves.
//   .
//   By default clips appear with orient=UP and sockets with orient=DOWN.  The clips and sockets extend 0.02 units below
//   their base so that unions and differences will work without trouble, but be sure that the attach overlap is smaller
//   than 0.02.
//   .
//   The first figure shows the dimensions of the rabbit clip.  The second figure shows the clip in red overlayed on
//   its socket in yellow.  The left clip has a nonzero clearance, so its socket is bigger than the clip all around.
//   The right hand locking clip has no clearance, but it has a lock clearance, which provides some space behind
//   the lock to allow the clip to fit.  (Note that depending on your printer, this can be set to zero.)
// Figure(2DMed,NoAxes):
//   snap=1.5;
//   comp=0.75;
//   mid = 8.053;  // computed in rabbit_clip
//   tip = [-4.58,18.03];
//   translate([9,3]){
//   back_half()
//      rabbit_clip("pin",width=12, length=18, depth=1, thickness = 1, compression=comp, snap=snap, orient=BACK);
//   color("blue"){
//      stroke([[6,0],[6,18]],width=0.1);
//      stroke([[6+comp, 12], [6+comp, 18]], width=.1);
//   }
//   color("red"){
//      stroke([[6-snap,mid], [6,mid]], endcaps="arrow2",width=0.15);
//      translate([6+.4,mid-.15])text("snap",size=1,valign="center");
//      translate([6+comp/2,19.5])text("compression", size=1, halign="center");
//      stroke([[6+comp/2,19.3], [6+comp/2,17.7]], endcap2="arrow2", width=.15);
//      fwd(1.1)text("width",size=1,halign="center");
//      xflip_copy()stroke([[2,-.7], [6,-.7]], endcap2="arrow2", width=.15);
//      move([-6.7,mid])rot(90)text("length", size=1, halign="center");
//      stroke([[-7,10.3], [-7,18]], width=.15, endcap2="arrow2");
//      stroke([[-7,0], [-7,5.8]], width=.15,endcap1="arrow2");
//      stroke([tip, tip-[0,1]], width=.15);
//      move([tip.x+2,19.5])text("thickness", halign="center",size=1);
//      stroke([[tip.x+2, 19.3], tip+[.1,.1]], width=.15, endcap2="arrow2");
//   }
//   }
//
// Figure(2DMed,NoAxes):
//   snap=1.5;
//   comp=0;
//   translate([29,3]){
//   back_half()
//      rabbit_clip("socket", width=12, length=18, depth=1, thickness = 1, compression=comp, snap=snap, orient=BACK,lock=true);
//   color("red")back_half()
//      rabbit_clip("pin",width=12, length=18, depth=1, thickness = 1, compression=comp, snap=snap,
//               orient=BACK,lock=true,lock_clearance=1);
//   }
//   translate([9,3]){
//   back_half()
//      rabbit_clip("socket", clearance=.5,width=12, length=18, depth=1, thickness = 1,
//                  compression=comp, snap=snap, orient=BACK,lock=false);
//   color("red")back_half()
//      rabbit_clip("pin",width=12, length=18, depth=1, thickness = 1, compression=comp, snap=snap,
//               orient=BACK,lock=false,lock_clearance=1);
//   }
// Arguments:
//   type = One of "pin",  "socket", "male", "female" or "double" to specify what to make.
//   length = nominal clip length
//   width = nominal clip width
//   snap = depth of hollow on the side of the clip
//   thickness = thickness of the clip "line"
//   depth = amount to extrude clip (give extra room for the socket, about 0.4mm)
//   ---
//   compression = excess width at the "ears" to lock more tightly.  Default: 0.1
//   clearance = extra space in the socket for easier insertion.  Default: 0.1
//   lock = set to true to make a locking clip that may be irreversible.  Default: false
//   lock_clearance = give clearance for the lock.  Default: 0
//   splinesteps = number of samples in the curves of the clip.  Default: 8
//   anchor = anchor point for clip
//   orient = clip orientation.  Default: UP for pins, DOWN for sockets
//   spin = spin the clip.  Default: 0
//
// Example:  Here are several sizes that work printed in PLA on a Prusa MK3, with default clearance of 0.1 and a depth of 5
//   module test_pair(length, width, snap, thickness, compression, lock=false)
//   {
//     depth = 5;
//     extra_depth = 10;// Change this to 0.4 for closed sockets
//     cuboid([max(width+5,12),12, depth], chamfer=.5, edges=[FRONT,"Y"], anchor=BOTTOM)
//         attach(BACK)
//           rabbit_clip(type="pin",length=length, width=width,snap=snap,thickness=thickness,depth=depth,
//                       compression=compression,lock=lock);
//     right(width+13)
//     diff("remove")
//         cuboid([width+8,max(12,length+2),depth+3], chamfer=.5, edges=[FRONT,"Y"], anchor=BOTTOM)
//           tag("remove")
//             attach(BACK)
//               rabbit_clip(type="socket",length=length, width=width,snap=snap,thickness=thickness,
//                           depth=depth+extra_depth, lock=lock,compression=0);
//   }
//   left(37)ydistribute(spacing=28){
//     test_pair(length=6, width=7, snap=0.25, thickness=0.8, compression=0.1);
//     test_pair(length=3.5, width=7, snap=0.1, thickness=0.8, compression=0.1);  // snap = 0.2 gives a firmer connection
//     test_pair(length=3.5, width=5, snap=0.1, thickness=0.8, compression=0.1);  // hard to take apart
//   }
//   right(17)ydistribute(spacing=28){
//     test_pair(length=12, width=10, snap=1, thickness=1.2, compression=0.2);
//     test_pair(length=8, width=7, snap=0.75, thickness=0.8, compression=0.2, lock=true); // With lock, very firm and irreversible
//     test_pair(length=8, width=7, snap=0.75, thickness=0.8, compression=0.2, lock=true); // With lock, very firm and irreversible
//   }
// Example: Double clip to connect two sockets
//   rabbit_clip("double",length=8, width=7, snap=0.75, thickness=0.8, compression=0.2,depth=5);
// Example:  A modified version of the clip that acts like a backpack strap clip, where it locks tightly but you can squeeze to release.
//   cuboid([25,15,5],anchor=BOTTOM)
//       attach(BACK)rabbit_clip("pin", length=25, width=25, thickness=1.5, snap=2, compression=0, lock=true, depth=5, lock_clearance=3);
//   left(32)
//   diff("remove")
//   cuboid([30,30,11],orient=BACK,anchor=BACK){
//       tag("remove")attach(BACK)rabbit_clip("socket", length=25, width=25, thickness=1.5, snap=2, compression=0, lock=true, depth=5.5, lock_clearance=3);
//       xflip_copy()
//         position(FRONT+LEFT)
//         xscale(0.8)
//         tag("remove")zcyl(l=20,r=13.5, $fn=64);
//   }

function rabbit_clip(type, length, width,  snap, thickness, depth, compression=0.1,  clearance=.1, lock=false, lock_clearance=0,
                   splinesteps=8, anchor, orient, spin=0) = no_function("rabbit_clip");

module rabbit_clip(type, length, width,  snap, thickness, depth, compression=0.1,  clearance=.1, lock=false, lock_clearance=0,
                   splinesteps=8, anchor, orient, spin=0)
{
  legal_types = ["pin","socket","male","female","double"];
  check =
    assert(is_num(width) && width>0,"Width must be a positive value")
    assert(is_num(length) && length>0, "Length must be a positive value")
    assert(is_num(thickness) && thickness>0, "Thickness must be a positive value")
    assert(is_num(snap) && snap>=0, "Snap must be a non-negative value")
    assert(is_num(depth) && depth>0, "Depth must be a positive value")
    assert(is_num(compression) && compression >= 0, "Compression must be a nonnegative value")
    assert(is_bool(lock))
    assert(is_num(lock_clearance))
    assert(in_list(type,legal_types),str("type must be one of ",legal_types));
  if (type=="double") {
    attachable(size=[width+2*compression, depth, 2*length], anchor=default(anchor,BACK), spin=spin, orient=default(orient,BACK)){
      union(){
        rabbit_clip("pin", length=length, width=width, snap=snap, thickness=thickness, depth=depth, compression=compression,
                    lock=lock, anchor=BOTTOM, orient=UP);
        rabbit_clip("pin", length=length, width=width, snap=snap, thickness=thickness, depth=depth, compression=compression,
                    lock=lock, anchor=BOTTOM, orient=DOWN);
        cuboid([width-thickness, depth, thickness]);
      }
      children();
    }
  } else {
    anchor = default(anchor,BOTTOM);
    is_pin = in_list(type,["pin","male"]);
    //default_overlap = 0.01 * (is_pin?1:-1);    // Shift by this much to undo default overlap
    default_overlap = 0;
    extra = 0.02;  // Amount of extension below nominal based position for the socket, must exceed default overlap of 0.01
    clearance = is_pin ? 0 : clearance;
    compression = is_pin ? compression : 0;
    orient =  is_def(orient) ? orient
            : is_pin ? UP
            : DOWN;
    earwidth = 2*thickness+snap;
    point_length = earwidth/2.15;
    // The adjustment is using cos(theta)*earwidth/2 and sin(theta)*point_length, but the computation
    // is obscured because theta is atan(length/2/snap)
    scaled_len = length - 0.5 * (earwidth * snap + point_length * length) / sqrt(sqr(snap)+sqr(length/2));
    bottom_pt = [0,max(scaled_len*0.15+thickness, 2*thickness)];
    ctr = [width/2,scaled_len] + line_normal([width/2-snap, scaled_len/2], [width/2, scaled_len]) * earwidth/2;
    inside_pt = circle_circle_tangents(0, bottom_pt, earwidth/2, ctr)[0][1];
    sidepath =[
               [width/2,0],
               [width/2-snap,scaled_len/2],
               [width/2+(is_pin?compression:0), scaled_len],
               ctr - point_length * line_normal([width/2,scaled_len], inside_pt),
               inside_pt
              ];
    fullpath = concat(
                      sidepath,
                      [bottom_pt],
                      reverse(apply(xflip(),sidepath))
                      );
    dummy2 = assert(fullpath[4].y < fullpath[3].y, "Pin is too wide for its length");

    snapmargin = -snap + last(sidepath).x;// - compression;
    if (is_pin){
      if (snapmargin<0) echo("WARNING: The snap is too large for the clip to squeeze to fit its socket")
      echo(snapmargin=snapmargin);
    }
    // Force tangent to be vertical at the outer edge of the clip to avoid overshoot
    fulltangent = list_set(path_tangents(fullpath, uniform=false),[2,8], [[0,1],[0,-1]]);

    subset = is_pin ? [0:10] : [0,1,2,3, 7,8,9,10];  // Remove internal points from the socket
    tangent = select(fulltangent, subset);
    path = select(fullpath, subset);

    socket_smooth = .04;
    pin_smooth = [.075, .075, .15, .12, .06];
    smoothing = is_pin
                  ? concat(pin_smooth, reverse(pin_smooth))
                  : let(side_smooth=select(pin_smooth, 0, 2))
                    concat(side_smooth, [socket_smooth], reverse(side_smooth));
    bez = path_to_bezpath(path,relsize=smoothing,tangents=tangent);
    rounded = bezpath_curve(bez,splinesteps=splinesteps);
    bounds = pointlist_bounds(rounded);
    extrapt = is_pin ? [] : [rounded[0] - [0,extra]];
    finalpath = is_pin ? rounded
                       : let(withclearance=offset(rounded, r=-clearance, closed=false))
                         concat( [[withclearance[0].x,-extra]],
                                 withclearance,
                                 [[-withclearance[0].x,-extra]]);
    attachable(size=[bounds[1].x-bounds[0].x, depth, bounds[1].y-bounds[0].y], anchor=anchor, spin=spin, orient=orient){
      xrot(90)
        translate([0,-(bounds[1].y-bounds[0].y)/2+default_overlap,-depth/2])
        linear_extrude(height=depth, convexity=10) {
            if (lock)
              xflip_copy()
              right(clearance)
              polygon([sidepath[1]+[-thickness/10,lock_clearance],
                       sidepath[2]-[thickness*.75,0],
                       sidepath[2],
                       [sidepath[2].x,sidepath[1].y+lock_clearance]]);
            if (is_pin)
              offset_stroke(finalpath, width=[thickness,0]);
            else
              polygon(finalpath);
        }
      children();
    }
  }
}



// Section: Splines

// Module: hirth()
// Synopsis: Creates a Hirth face spline that locks together two cylinders.
// SynTags: Geom
// Usage:
//   hirth(n, ir|id=, or|od=, tooth_angle, [cone_angle=], [chamfer=], [rounding=], [base=], [crop=], [anchor=], [spin=], [orient=]
// Description:
//   Create a Hirth face spline.  The Hirth face spline is a joint that locks together two cylinders using radially
//   positioned triangular teeth on the ends of the cylinders.  If the joint is held together (e.g. with a screw) then
//   the two parts will rotate (or not) together.  The two parts of the regular Hirth spline joint are identical.
//   Each tooth is a triangle that grows larger with radius.  You specify a nominal tooth angle; the actual tooth
//   angle will be slightly different.
//   .
//   You can also specify a cone_angle which raises or lowers the angle of the teeth.  When you do this you need to
//   mate splines with opposite angles such as -20 and +20.  The splines appear centered at the origin so that two
//   splines will mate if their centers coincide.  Therefore `attach(CENTER,CENTER)` will produce two mating splines
//   assuming that they are rotated correctly.  The bottom anchors will be at the bottom of the spline base.  The top
//   anchors are at an arbitrary location and are not useful.  
//   .
//   By default the spline is created as a polygon with `2n` edges and the radius is the outer radius to the unchamfered corners.
//   For large choices of `n` this will produce result that is close to circular.  For small `n` the result will be obviously polygonal.
//   If you want a cylindrical result then set `crop=true`, which will intersect an oversized version of the joint with a suitable cylinder.
//   Note that cropping makes the most difference when the tooth count is low.  
//   .
//   The teeth are chamfered proportionally based on the `chamfer` argument which specifies the fraction of the teeth tips
//   to remove.  The teeth valleys are chamfered by half the specified value to ensure that there is room for the parts
//   to mate.  If you use the rounding parameter then the roundings cut away the chamfer corners, so chamfered and rounded
//   joints are compatible with each other.  Note that rounding doesn't always produce a smooth transition to the roundover,
//   particularly with large cone angle.  
//   The base is added based on the unchamfered dimensions of the joint, and the "teeth_bot" anchor is located
//   based on the unchamfered dimensions.
//   .
//   By default the teeth are symmetric, which is ideal for registration and for situations where loading may occur in either
//   direction.   The skew parameter will skew the teeth by the specified amount, where a skew of ±1 gives a tooth with a vertical
//   side either on the left or the right.  Intermediate values will produce partially skewed teeth.  Note that the skew
//   applies after the tooth profile is computed with the specified tooth_angle, which means that the skewed tooth will
//   have an altered tooth angle from the one specified.
//   .
//   The joint is constructed with a tooth peak aligned with the X+ axis.  
//   For two hirth joints to mate they must have the same tooth count, opposite cone angles, and the chamfer/rounding values
//   must be equal.  (One can be chamfered and one rounded, but with the same value.)  The rotation required to mate the parts
//   depends on the skew and whether the tooth count is odd or even.  To apply this rotation automatically, set `rot=true`.
//   .
//   When you pick extreme parameters such as very large cone angle, or very small tooth count (e.g. 2 or 3), the joint may
//   develop a weird shape, and the shape may be unexpectedly sensitive to things like whether chamfering is enabled.  It is difficult
//   to identify the point where the shapes become odd, or even perhaps invalid.  For example, with 2 teeth a skew of 0.95 works fine, but
//   a skew of 0.97 produces a truncated shape and 0.99 produces a 2-part shape.  A skew of 1 produces a degenerate, invalid shape.  
//   Since it's hard to determine which parameters, exactly, produce "bad" outcomes, we have chosen not to limit the production
//   of the extreme shapes, so take care if using extreme parameter values.  
// Named Anchors:
//   "teeth_bot" = center of the joint, aligned with the bottom of the (unchamfered/unrounded) teeth, pointing DOWN.  
// Arguments:
//   n = number of teeth
//   ir/id = inner radius or diameter
//   or/od = outer radius or diameter
//   tooth_angle = nominal tooth angle.  Default: 60
//   cone_angle = raise or lower the angle of the teeth in the radial direction.  Default: 0
//   skew = skew the tooth shape.  Default: 0
//   chamfer = chamfer teeth by this fraction at tips and half this fraction at valleys.  Default: 0
//   rounding = round the teeth by this fraction at the tips, and half this fraction at valleys.  Default: 0
//   rot = if true rotate so the part will mate (via attachment) with another identical part.  Default: false
//   base = add base of this height to the bottom.  Default: 1
//   crop = crop to a cylindrical shape.  Default: false
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Example(3D,NoScale):  Basic uncropped hirth spline
//   hirth(32,20,50);
// Example(3D,NoScale): Raise cone angle
//   hirth(32,20,50,cone_angle=30);
// Example(3D,NoScale): Lower cone angle
//   hirth(32,20,50,cone_angle=-30);
// Example(3D,NoScale): Adding a large base
//   hirth(20,20,50,base=20);
// Example(3D,NoScale): Only 8 teeth, with chamfering
//   hirth(8,20,50,tooth_angle=60,base=10,chamfer=.1);
// Example(3D,NoScale): Only 8 teeth, cropped
//   hirth(8,20,50,tooth_angle=60,base=10,chamfer=.1, crop=true);
// Example(3D,NoScale): Only 8 teeth, with rounding
//   hirth(8,20,50,tooth_angle=60,base=10,rounding=.1);
// Example(3D,NoScale): Only 8 teeth, different tooth angle, cropping with $fn to crop cylinder aligned with teeth
//   hirth(8,20,50,tooth_angle=90,base=10,rounding=.05,crop=true,$fn=48);
// Example(3D,NoScale): Two identical parts joined together (with 1 unit offset to reveal the joint line).  With odd tooth count and no skew the teeth line up correctly:
//   hirth(27,20,50, tooth_angle=60,base=2,chamfer=.05)
//     up(1) attach(CENTER,CENTER)
//       hirth(27,20,50, tooth_angle=60,base=2,chamfer=.05);
// Example(3D,NoScale): Two conical parts joined together, with opposite cone angles for a correct joint.  With an even tooth count one part needs to be rotated for the parts to align:
//   hirth(26,20,50, tooth_angle=60,base=2,cone_angle=30,chamfer=.05)
//     up(1) attach(CENTER,CENTER)
//       hirth(26,20,50, tooth_angle=60,base=2,cone_angle=-30, chamfer=.05, rot=true);
// Example(3D,NoScale): Using skew to create teeth with vertical faces
//   hirth(17,20,50,skew=-1, base=5, chamfer=0.05);
// Example(3D,NoScale): If you want to change how tall the teeth are you do that by changing the tooth angle.  Increasing the tooth angle makes the teeth shorter:
//   hirth(17,20,50,tooth_angle=120,skew=0, base=5, rounding=0.05, crop=true);

module hirth(n, ir, or, id, od, tooth_angle=60, cone_angle=0, chamfer, rounding, base=1, crop=false,skew=0, rot=false, orient,anchor,spin)
{
  ir = get_radius(r=ir,d=id);
  or = get_radius(r=or,d=od);
  dummy = assert(all_positive([ir]), "ir/id must be a positive value")
          assert(all_positive([or]), "or/od must be a positive value")
          assert(is_int(n) && n>1, "n must be an integer larger than 1")
          assert(is_finite(skew) && abs(skew)<=1, "skew must be a number between -1 and 1")
          assert(ir<or, "inside radius (ir/id) must be smaller than outside radius (or/od)")
          assert(all_positive([tooth_angle]) && tooth_angle<360*(n-1)/2/n, str("tooth angle must be between 0 and ",360*(n-1)/2/n," for spline with ",n," teeth."))
          assert(num_defined([chamfer,rounding]) <=1, "Cannot define both chamfer and rounding")
          assert(is_undef(chamfer) || all_nonnegative([chamfer]) && chamfer<1/2, "chamfer must be a non-negative value smaller than 1/2")
          assert(is_undef(rounding) || all_nonnegative([rounding]) && rounding<1/2, "rounding must be a non-negative value smaller than 1/2")
          assert(all_positive([base]), "base must be a positive value") ;
  tooth_height = sin(180/n) / tan(tooth_angle/2);     // Normalized tooth height
  cone_height = -tan(cone_angle);                        // Normalized height change corresponding to the cone angle
  ridge_angle = atan(tooth_height/2 + cone_height);
  valley_angle = atan(-tooth_height/2 + cone_height);
  angle = 180/n;    // Half the angle occupied by each tooth going around the circle
  
  factor = crop ? 3 : 1;   // Make it oversized when crop is true

// project spherical coordinate point onto cylinder of radius r
  cyl_proj = function (r,theta_phi)
     [for(pt=theta_phi)
        let(xyz = spherical_to_xyz(1,pt[0], 90-pt[1]))
        r * xyz / norm(point2d(xyz))];

  edge = cyl_proj(or,[[-angle, valley_angle], [0, ridge_angle]]);
  cutfrac = first_defined([chamfer,rounding,0]);
  rounding = rounding==0? undef:rounding;
  ridgecut=xyz_to_spherical(lerp(edge[0],edge[1], 1-cutfrac));
  valleycut=xyz_to_spherical(lerp(edge[0],edge[1], cutfrac/2));
  ridge_chamf = [ridgecut.y,90-ridgecut.z];
  valley_chamf = [valleycut.y,90-valleycut.z];
  basicprof = [
                if (is_def(rounding)) [-angle, valley_chamf.y],
                valley_chamf,
                ridge_chamf
              ];
  full = deduplicate(concat(basicprof, reverse(xflip(basicprof))));
  skewed = back(valley_angle, skew(sxy=skew*angle/(ridge_angle-valley_angle),fwd(valley_angle,full)));
  pprofile = is_undef(rounding) ? skewed
          :
            let(
                segs = max(16,segs(or*rounding)),
                                // Using computed values for the joints lead to round-off error issues
                joints = [(skewed[1]-skewed[0]).x, (skewed[3]-skewed[2]).x/2, (skewed[3]-skewed[2]).x/2,(skewed[5]-skewed[4]).x ],
                roundpts = round_corners(skewed, joint=joints, closed=false,$fn=segs)
            )
            roundpts;
  profile = [
               for(i=[0:1:len(pprofile)-2]) each [pprofile[i],
                                                  if (pprofile[i+1].x-pprofile[i].x > 90)    // Interpolate an extra point if angle > 90 deg
                                                       let(
                                                            edge = cyl_proj(or, select(pprofile,i,i+1)),
                                                            cutpt = xyz_to_spherical(lerp(edge[0],edge[1],.48))  // Exactly .5 is too close to or crosses the origin
                                                       )
                                                       [cutpt.y,90-cutpt.z]
                                                 ], 
               last(pprofile)
             ];

  // This code computes the realized tooth angle
  //  out = cyl_proj(or, pprofile);
  //  in = cyl_proj(ir,pprofile);
  //  p1 = plane3pt(out[0], out[1], in[1]);
  //  p2 = plane3pt(out[2], out[1], in[1]);
  //  echo(toothang=vector_angle(plane_normal(p1), plane_normal(p2)));
  
  bottom = min([tan(valley_angle)*ir,tan(valley_angle)*or])-base-cone_height*ir;
  ang_ofs = !rot ? -skew*angle
          :  n%2==0 ? -(angle-skew*angle)  - skew*angle
          :  -angle*(2-skew)-skew*angle;

  topinner = down(cone_height*ir,[for(ang=lerpn(0,360,n,endpoint=false))
                                  each zrot(ang+ang_ofs,cyl_proj(ir/factor,profile))]);
  topouter = down(cone_height*ir,[for(ang=lerpn(0,360,n,endpoint=false))
                                  each zrot(ang+ang_ofs,cyl_proj(factor*or,profile))]);

  safebottom = min(min(column(topinner,2)), min(column(topouter,2))) - base - (crop?1:0);
  
  botinner = [for(val=topinner) [val.x,val.y,safebottom]];
  botouter = [for(val=topouter) [val.x,val.y,safebottom]];  
  vert = [topouter, topinner, botinner, botouter];

  datamin = min(min(column(topinner,2)), min(column(topouter,2)));
  
  anchors = [
             named_anchor("teeth_bot", [0,0,bottom], DOWN)
            ];
  attachable(anchor=anchor,spin=spin,orient=orient, r=or, h=-2*bottom,anchors=anchors){
      intersection(){
        vnf_polyhedron(vnf_vertex_array(vert, reverse=true, col_wrap=true, row_wrap=true),convexity=min(10,n));
        if (crop)
           zmove(bottom)tube(or=or,ir=ir,height=4*or,anchor=BOT,$fa=1,$fs=1);
      }
    children();
  }
}

// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
