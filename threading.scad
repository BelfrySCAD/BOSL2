//////////////////////////////////////////////////////////////////////
// LibFile: threading.scad
//   Triangular and Trapezoidal-Threaded Screw Rods and Nuts.
// Includes:
//   include <BOSL2/std.scad>
//   include <BOSL2/threading.scad>
//////////////////////////////////////////////////////////////////////


// Section: Generic Threading

// Module: thread_helix()
// Usage:
//   thread_helix(d, pitch, thread_depth, [thread_angle], [twist], [profile=], [left_handed=], [higbee=], [internal=]);
// Description:
//   Creates a helical thread with optional end tapering.
// Arguments:
//   d = Inside base diameter of threads.  Default: 10
//   pitch = Distance between threads.  Default: 2mm/thread
//   thread_depth = Depth of threads from top to bottom.
//   thread_angle = Angle of the thread faces.  Default: 15 degrees.
//   twist = Number of degrees to rotate thread around.  Default: 720 degrees.
//   ---
//   profile = If an asymmetrical thread profile is needed, it can be specified here.
//   starts = The number of thread starts.  Default: 1
//   left_handed = If true, thread has a left-handed winding.
//   internal = If true, invert threads for internal threading.
//   d1 = Bottom inside base diameter of threads.
//   d2 = Top inside base diameter of threads.
//   higbee = Length to taper thread ends over.  Default: 0
//   higbee1 = Length to taper bottom thread end over.
//   higbee2 = Length to taper top thread end over.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
// Example(2DMed): Typical Tooth Profile
//   pitch = 2;
//   depth = pitch * cos(30) * 5/8;
//   profile = [
//       [-6/16, 0           ],
//       [-1/16, depth/pitch ],
//       [ 1/16, depth/pitch ],
//       [ 6/16, 0           ],
//   ];
//   stroke(profile, width=0.02);
// Example:
//   thread_helix(d=10, pitch=2, thread_depth=0.75, thread_angle=15, twist=900, $fn=72);
module thread_helix(
    d, pitch=2, thread_depth, thread_angle=15, twist=720,
    profile, starts=1, left_handed=false, internal=false,
    d1, d2, higbee, higbee1, higbee2,
    anchor, spin, orient
) {
    h = pitch*starts*twist/360;
    r1 = get_radius(d1=d1, d=d, dflt=10);
    r2 = get_radius(d1=d2, d=d, dflt=10);
    tdp = thread_depth / pitch;
    dz = tdp * tan(thread_angle);
    cap = (1 - 2*dz)/2;
    profile = !is_undef(profile)? profile : (
        internal? [
            [-cap/2-dz, tdp],
            [-cap/2,    0  ],
            [+cap/2,    0  ],
            [+cap/2+dz, tdp],
        ] : [
            [+cap/2+dz, 0  ],
            [+cap/2,    tdp],
            [-cap/2,    tdp],
            [-cap/2-dz, 0  ],
        ]
    );
    pline = mirror([-1,1],  p = profile * pitch);
    dir = left_handed? -1 : 1;
    idir = internal? -1 : 1;
    attachable(anchor,spin,orient, r1=r1, r2=r2, l=h) {
        zrot_copies(n=starts) {
            spiral_sweep(pline, h=h, r1=r1, r2=r2, twist=twist*dir, higbee=higbee, higbee1=higbee1, higbee2=higbee2, anchor=CENTER);
        }
        children();
    }
}



// Module: trapezoidal_threaded_rod()
// Description:
//   Constructs a generic trapezoidal threaded screw rod.  This method makes
//   much smoother threads than the naive linear_extrude method.
//   For metric trapezoidal threads, use thread_angle=15 and thread_depth=pitch/2.
//   For ACME threads, use thread_angle=14.5 and thread_depth=pitch/2.
//   For square threads, use thread_angle=0 and thread_depth=pitch/2.
//   For normal UTS or ISO screw threads, use the `threaded_rod()` module instead to get the correct thread profile.
//   For NPT (National Pipe Threading) threads, use the `npt_threaded_rod() module instead.
// Arguments:
//   d = Outer diameter of threaded rod.
//   l = Length of threaded rod.
//   pitch = Length between threads.
//   thread_angle = The pressure angle profile angle of the threads.  Default = 14.5 degree ACME profile.
//   ---
//   thread_depth = Depth of the threads.  Default=pitch/2
//   left_handed = If true, create left-handed threads.  Default = false
//   bevel = if true, bevel the thread ends.  Default: true
//   starts = The number of lead starts.  Default = 1
//   profile = The shape of a thread, if not a symmetric trapezoidal form.  Given as a 2D path, where X is between -1/2 and 1/2, representing the pitch distance, and Y is 0 for the peak, and `-depth/pitch` for the valleys.  The segment between the end of one thread profile and the start of the next is automatic, so the start and end coordinates should not both be at the same Y at X = ±1/2.  This path is scaled up by the pitch size in both dimensions when making the final threading.  This overrides the `thread_angle` and `thread_depth` options.
//   internal = If true, make this a mask for making internal threads.
//   d1 = Bottom outside diameter of threads.
//   d2 = Top outside diameter of threads.
//   higbee = Length to taper thread ends over.  Default: 0 (No higbee thread tapering)
//   higbee1 = Length to taper bottom thread end over.
//   higbee2 = Length to taper top thread end over.
//   center = If given, overrides `anchor`.  A true value sets `anchor=CENTER`, false sets `anchor=UP`.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
//   $slop = The printer-specific slop value to make parts fit just right.
// Examples(Med):
//   trapezoidal_threaded_rod(d=10, l=40, pitch=2, thread_angle=15, $fn=32);
//   trapezoidal_threaded_rod(d=3/8*25.4, l=20, pitch=1/8*25.4, thread_angle=29, $fn=32);
//   trapezoidal_threaded_rod(d=60, l=16, pitch=8, thread_depth=3, thread_angle=45, left_handed=true, $fa=2, $fs=2);
//   trapezoidal_threaded_rod(d=60, l=16, pitch=8, thread_depth=3, thread_angle=45, left_handed=true, starts=4, $fa=2, $fs=2);
//   trapezoidal_threaded_rod(d=16, l=40, pitch=2, thread_angle=30);
//   trapezoidal_threaded_rod(d=10, l=40, pitch=3, thread_angle=15, left_handed=true, starts=3, $fn=36);
//   trapezoidal_threaded_rod(d=25, l=40, pitch=10, thread_depth=8/3, thread_angle=50, starts=4, center=false, $fa=2, $fs=2);
//   trapezoidal_threaded_rod(d=50, l=35, pitch=8, thread_angle=30, starts=3, bevel=true);
//   trapezoidal_threaded_rod(l=25, d=10, pitch=2, thread_angle=15, starts=3, $fa=1, $fs=1, orient=RIGHT, anchor=BOTTOM);
// Example(Med): Using as a Mask to Make Internal Threads
//   bottom_half() difference() {
//       cube(50, center=true);
//       trapezoidal_threaded_rod(d=40, l=51, pitch=5, thread_angle=30, internal=true, orient=RIGHT, $fn=36);
//   }
// Example(2DMed): Typical Tooth Profile
//   pitch = 2;
//   depth = pitch * cos(30) * 5/8;
//   profile = [
//       [-7/16, -depth/pitch*1.07],
//       [-6/16, -depth/pitch],
//       [-1/16,  0],
//       [ 1/16,  0],
//       [ 6/16, -depth/pitch],
//       [ 7/16, -depth/pitch*1.07]
//   ];
//   stroke(profile, width=0.02);
module trapezoidal_threaded_rod(
    d, l=100, pitch=2,
    thread_angle=15,
    thread_depth=undef,
    left_handed=false,
    bevel=false,
    starts=1,
    profile,
    internal=false,
    d1, d2,
    higbee, higbee1, higbee2,
    center, anchor, spin, orient
) {
    r1 = get_radius(d1=d1, d=d, dflt=10);
    r2 = get_radius(d1=d2, d=d, dflt=10);
    sides = quantup(segs(max(r1,r2)), starts);
    rsc = internal? (1/cos(180/sides)) : 1;
    islop = internal? $slop*3 : 0;
    _r1 = r1 * rsc + islop;
    _r2 = r2 * rsc + islop;
    threads = quantup(l/pitch+2, 2*starts);
    depth = min((thread_depth==undef? pitch/2 : thread_depth), pitch/2/tan(thread_angle));
    pa_delta = min(pitch/4-0.01,depth*tan(thread_angle)/2)/pitch;
    dir = left_handed? -1 : 1;
    twist = 360 * l / pitch / starts;
    higang1 = first_defined([higbee1, higbee, 0]);
    higang2 = first_defined([higbee2, higbee, 0]);
    assert(higang1 < twist/2);
    assert(higang2 < twist/2);

    rr1 = -depth/pitch;
    z1 = 1/4-pa_delta;
    z2 = 1/4+pa_delta;
    profile = (
        profile!=undef? profile : [
            [-z2, rr1],
            [-z1,  0],
            [ z1,  0],
            [ z2, rr1],
        ]
    );
    prof3d = path3d(profile);
    higthr1 = ceil(higang1 / 360);
    higthr2 = ceil(higang2 / 360);
    pdepth = -min(subindex(profile,1));
    dummy1 = assert(_r1>pdepth) assert(_r2>pdepth);
    skew_mat = affine3d_skew(sxz=(_r2-_r1)/l);
    side_mat = affine3d_xrot(90) *
        affine3d_mirror([-1,1,0]) *
        affine3d_scale([1,1,1] * pitch);
    hig_table = [
        [-twist,           0],
        [-twist/2-0.00001, 0],
        [-twist/2+higang1, 1],
        [+twist/2-higang2, 1],
        [+twist/2+0.00001, 0],
        [+twist,           0],
    ];
    start_steps = floor(sides / starts);
    thread_verts = [
        for (step = [0:1:start_steps]) let(
            ang = 360 * step/sides,
            dz = pitch * step / start_steps,
            mat1 = affine3d_zrot(ang*dir),
            mat2 = affine3d_translate([(_r1 + _r2) / 2 - pdepth*pitch, 0, 0]) *
                skew_mat *
                affine3d_translate([0, 0, dz]),
            prof = apply(side_mat, [
                for (thread = [-threads/2:1:threads/2-1]) let(
                    tang = (thread/starts) * 360 + ang,
                    hsc = internal? 1 :
                        (higang1==0 && tang<=0)? 1 :
                        (higang2==0 && tang>=0)? 1 :
                        lookup(tang, hig_table),
                    mat3 = affine3d_translate([thread, 0, 0]) *
                        affine3d_scale([1, hsc, 1]) *
                        affine3d_translate([0,pdepth,0])
                ) each apply(mat3, prof3d)
            ])
        ) [
            [0, 0, -l/2-pitch],
            each apply(mat1*mat2, prof),
            [0, 0, +l/2+pitch]
        ]
    ];
    thread_vnfs = vnf_merge([
        for (i=[0:1:starts-1])
            zrot(i*360/starts, p=vnf_vertex_array(thread_verts, reverse=left_handed, style="min_edge")),
        for (i=[0:1:starts-1]) let(
            rmat = zrot(i*360/starts),
            pts = deduplicate(list_head(thread_verts[0], len(prof3d)+1)),
            faces = [for (i=idx(pts,e=-2)) [0, i+1, i]],
            rfaces = left_handed? [for (x=faces) reverse(x)] : faces
        ) [apply(rmat,pts), rfaces],
        for (i=[0:1:starts-1]) let(
            rmat = zrot(i*360/starts),
            pts = deduplicate(list_tail(last(thread_verts), -len(prof3d)-2)),
            faces = [for (i=idx(pts,e=-2)) [len(pts)-1, i, i+1]],
            rfaces = left_handed? [for (x=faces) reverse(x)] : faces
        ) [apply(rmat,pts), rfaces]
    ]);

    anchor = get_anchor(anchor, center, BOT, CENTER);
    attachable(anchor,spin,orient, r1=_r1, r2=_r2, l=l) {
        intersection() {
            //vnf_validate(vnf_quantize(thread_vnfs), size=0.1);
            vnf_polyhedron(vnf_quantize(thread_vnfs), convexity=10);
            if (bevel) {
                cyl(l=l, r1=_r1, r2=_r2, chamfer=depth);
            } else {
                cyl(l=l, r1=_r1, r2=_r2);
            }
        }
        children();
    }
}


// Module: trapezoidal_threaded_nut()
// Description:
//   Constructs a hex nut for a threaded screw rod.  This method makes
//   much smoother threads than the naive linear_extrude method.
//   For metric screw threads, use thread_angle=30 and leave out thread_depth argument.
//   For SAE screw threads, use thread_angle=30 and leave out thread_depth argument.
//   For metric trapezoidal threads, use thread_angle=15 and thread_depth=pitch/2.
//   For ACME threads, use thread_angle=14.5 and thread_depth=pitch/2.
//   For square threads, use thread_angle=0 and thread_depth=pitch/2.
// Arguments:
//   od = diameter of the nut.
//   id = diameter of threaded rod to screw onto.
//   h = height/thickness of nut.
//   pitch = Length between threads.
//   thread_depth = Depth of the threads.  Default=pitch/2.
//   thread_angle = The pressure angle profile angle of the threads.  Default = 14.5 degree ACME profile.
//   left_handed = if true, create left-handed threads.  Default = false
//   starts = The number of lead starts.  Default = 1
//   bevel = if true, bevel the thread ends.  Default: true
//   profile = The shape of a thread, if not a symmetric trapezoidal form.  Given as a 2D path, where X is between -1/2 and 1/2, representing the pitch distance, and Y is 0 for the peak, and `-depth/pitch` for the valleys.  The segment between the end of one thread profile and the start of the next is automatic, so the start and end coordinates should not both be at the same Y at X = ±1/2.  This path is scaled up by the pitch size in both dimensions when making the final threading.  This overrides the `thread_angle` and `thread_depth` options.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
//   $slop = The printer-specific slop value to make parts fit just right.
// Examples(Med):
//   trapezoidal_threaded_nut(od=16, id=8, h=8, pitch=2, $slop=0.2, anchor=UP);
//   trapezoidal_threaded_nut(od=17.4, id=10, h=10, pitch=2, $slop=0.2, left_handed=true);
//   trapezoidal_threaded_nut(od=17.4, id=10, h=10, pitch=2, thread_angle=15, starts=3, $fa=1, $fs=1);
module trapezoidal_threaded_nut(
    od=17.4,
    id=10,
    h=10,
    pitch=2,
    thread_depth=undef,
    thread_angle=15,
    profile=undef,
    left_handed=false,
    starts=1,
    bevel=true,
    anchor, spin, orient
) {
    depth = min((thread_depth==undef? pitch/2 : thread_depth), pitch/2/tan(thread_angle));
    attachable(anchor,spin,orient, size=[od/cos(30),od,h]) {
        difference() {
            cylinder(d=od/cos(30), h=h, center=true, $fn=6);
            trapezoidal_threaded_rod(
                d=id,
                l=h+1,
                pitch=pitch,
                thread_depth=depth,
                thread_angle=thread_angle,
                profile=profile,
                left_handed=left_handed,
                starts=starts,
                internal=true
            );
            if (bevel) {
                zflip_copy() {
                    down(h/2+0.01) {
                        cylinder(r1=id/2+$slop, r2=id/2+$slop-depth, h=depth, center=false);
                    }
                }
            }
        }
        children();
    }
}


// Section: Triangular Threading

// Module: threaded_rod()
// Description:
//   Constructs a standard metric or UTS threaded screw rod.  This method
//   makes much smoother threads than the naive linear_extrude method.
// Arguments:
//   d = Outer diameter of threaded rod.
//   l = length of threaded rod.
//   pitch = Length between threads.
//   left_handed = if true, create left-handed threads.  Default = false
//   bevel = if true, bevel the thread ends.  Default: false
//   internal = If true, make this a mask for making internal threads.
//   d1 = Bottom outside diameter of threads.
//   d2 = Top outside diameter of threads.
//   higbee = Length to taper thread ends over.  Default: 0
//   higbee1 = Length to taper bottom thread end over.
//   higbee2 = Length to taper top thread end over.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
//   $slop = The printer-specific slop value to make parts fit just right.
// Example(2D):
//   projection(cut=true)
//       threaded_rod(d=10, l=15, pitch=2, orient=BACK);
// Examples(Med):
//   threaded_rod(d=10, l=20, pitch=1.25, left_handed=true, $fa=1, $fs=1);
//   threaded_rod(d=25, l=20, pitch=2, $fa=1, $fs=1);
module threaded_rod(
    d, l=100, pitch=2,
    left_handed=false,
    bevel=false,
    internal=false,
    d1, d2,
    higbee, higbee1, higbee2,
    anchor, spin, orient
) {
    _r1 = get_radius(d1=d1, d=d, dflt=10);
    _r2 = get_radius(d1=d2, d=d, dflt=10);
    depth = pitch * cos(30) * 5/8;
    profile = internal? [
        [-6/16, -depth/pitch],
        [-1/16,  0],
        [-1/32,  0.02],
        [ 1/32,  0.02],
        [ 1/16,  0],
        [ 6/16, -depth/pitch]
    ] : [
        [-7/16, -depth/pitch*1.07],
        [-6/16, -depth/pitch],
        [-1/16,  0],
        [ 1/16,  0],
        [ 6/16, -depth/pitch],
        [ 7/16, -depth/pitch*1.07]
    ];
    trapezoidal_threaded_rod(
        d=d, d1=d1, d2=d2, l=l,
        pitch=pitch,
        thread_depth=depth,
        thread_angle=30,
        profile=profile,
        left_handed=left_handed,
        bevel=bevel,
        internal=internal,
        higbee=higbee,
        higbee1=higbee1,
        higbee2=higbee2,
        anchor=anchor,
        spin=spin,
        orient=orient
    ) children();
}



// Module: threaded_nut()
// Description:
//   Constructs a hex nut for a metric or UTS threaded screw rod.  This method
//   makes much smoother threads than the naive linear_extrude method.
// Arguments:
//   od = diameter of the nut.
//   id = diameter of threaded rod to screw onto.
//   h = height/thickness of nut.
//   pitch = Length between threads.
//   left_handed = if true, create left-handed threads.  Default = false
//   bevel = if true, bevel the thread ends.  Default: false
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
//   $slop = The printer-specific slop value to make parts fit just right.
// Examples(Med):
//   threaded_nut(od=16, id=8, h=8, pitch=1.25, left_handed=true, $slop=0.2, $fa=1, $fs=1);
module threaded_nut(
    od=16, id=10, h=10,
    pitch=2, left_handed=false, bevel=false,
    anchor, spin, orient
) {
    depth = pitch * cos(30) * 5/8;
    profile = [
        [-6/16, -depth/pitch],
        [-1/16,  0],
        [-1/32,  0.02],
        [ 1/32,  0.02],
        [ 1/16,  0],
        [ 6/16, -depth/pitch]
    ];
    trapezoidal_threaded_nut(
        od=od, id=id, h=h,
        pitch=pitch, thread_angle=30,
        profile=profile,
        left_handed=left_handed,
        bevel=bevel,
        anchor=anchor, spin=spin,
        orient=orient
    ) children();
}


// Section: Pipe Threading

// Module: npt_threaded_rod()
// Description:
//   Constructs a standard NPT pipe end threading. If `internal=true`, creates a mask for making
//   internal pipe threads.  Tapers smaller upwards if `internal=false`.  Tapers smaller downwards
//   if `internal=true`.  If `hollow=true` and `internal=false`, then the pipe threads will be
//   hollowed out into a pipe with the apropriate internal diameter.
// Arguments:
//   size = NPT standard pipe size in inches.  1/16", 1/8", 1/4", 3/8", 1/2", 3/4", 1", 1+1/4", 1+1/2", or 2".  Default: 1/2"
//   left_handed = If true, create left-handed threads.  Default = false
//   bevel = If true, bevel the thread ends.  Default: false
//   hollow = If true, create a pipe with the correct internal diameter.
//   internal = If true, make this a mask for making internal threads.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
//   $slop = The printer-specific slop value to make parts fit just right.
// Example(2D):
//   projection(cut=true) npt_threaded_rod(size=1/4, orient=BACK);
// Examples(Med):
//   npt_threaded_rod(size=3/8, $fn=72);
//   npt_threaded_rod(size=1/2, $fn=72);
//   npt_threaded_rod(size=1/2, left_handed=true, $fn=72);
module npt_threaded_rod(
    size=1/2,
    left_handed=false,
    bevel=false,
    hollow=false,
    internal=false,
    anchor, spin, orient
) {
    assert(is_finite(size));
    assert(is_bool(left_handed));
    assert(is_bool(bevel));
    assert(is_bool(hollow));
    assert(is_bool(internal));
    assert(!(internal&&hollow), "Cannot created a hollow internal threads mask.");
    info_table = [
        // Size    OD      len    TPI
        [ 1/16,  [ 0.3896, 0.308, 27  ]],
        [ 1/8,   [ 0.3924, 0.401, 27  ]],
        [ 1/4,   [ 0.5946, 0.533, 18  ]],
        [ 3/8,   [ 0.6006, 0.668, 18  ]],
        [ 1/2,   [ 0.7815, 0.832, 14  ]],
        [ 3/4,   [ 0.7935, 1.043, 14  ]],
        [ 1,     [ 0.9845, 1.305, 11.5]],
        [ 1+1/4, [ 1.0085, 1.649, 11.5]],
        [ 1+1/2, [ 1.0252, 1.888, 11.5]],
        [ 2,     [ 1.0582, 2.362, 11.5]],
    ];
    info = [for (data=info_table) if(approx(size,data[0])) data[1]][0];
    dummy1 = assert(is_def(info), "Unsupported NPT size.  Try one of 1/16, 1/8, 1/4, 3/8, 1/2, 3/4, 1, 1+1/4, 1+1/2, 2");
    l = 25.4 * info[0];
    d = 25.4 * info[1];
    pitch = 25.4 / info[2];
    rr = get_radius(d=d, dflt=0.84 * 25.4 / 2);
    rr2 = rr - l/32;
    r1 = internal? rr2 : rr;
    r2 = internal? rr : rr2;
    depth = pitch * cos(30) * 5/8;
    profile = internal? [
        [-6/16, -depth/pitch],
        [-1/16,  0],
        [-1/32,  0.02],
        [ 1/32,  0.02],
        [ 1/16,  0],
        [ 6/16, -depth/pitch]
    ] : [
        [-7/16, -depth/pitch*1.07],
        [-6/16, -depth/pitch],
        [-1/16,  0],
        [ 1/16,  0],
        [ 6/16, -depth/pitch],
        [ 7/16, -depth/pitch*1.07]
    ];
    attachable(anchor,spin,orient, l=l, r1=r1, r2=r2) {
        difference() {
            trapezoidal_threaded_rod(
                d1=2*r1, d2=2*r2, l=l,
                pitch=pitch,
                thread_depth=depth,
                thread_angle=30,
                profile=profile,
                left_handed=left_handed,
                bevel=bevel,
                internal=internal,
                higbee=r1*PI/2
            );
            if (hollow) {
                cylinder(l=l+1, d=size*INCH, center=true);
            } else nil();
        }
        children();
    }
}



// Section: Buttress Threading

// Module: buttress_threaded_rod()
// Description:
//   Constructs a simple buttress threaded screw rod.  This method
//   makes much smoother threads than the naive linear_extrude method.
// Arguments:
//   d = Outer diameter of threaded rod.
//   l = length of threaded rod.
//   pitch = Length between threads.
//   left_handed = if true, create left-handed threads.  Default = false
//   bevel = if true, bevel the thread ends.  Default: false
//   internal = If true, this is a mask for making internal threads.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
//   $slop = The printer-specific slop value to make parts fit just right.
// Example(2D):
//   projection(cut=true)
//       buttress_threaded_rod(d=10, l=15, pitch=2, orient=BACK);
// Examples(Med):
//   buttress_threaded_rod(d=10, l=20, pitch=1.25, left_handed=true, $fa=1, $fs=1);
//   buttress_threaded_rod(d=25, l=20, pitch=2, $fa=1, $fs=1);
module buttress_threaded_rod(
    d=10, l=100, pitch=2,
    left_handed=false,
    bevel=false,
    internal=false,
    anchor, spin, orient
) {
    depth = pitch * 3/4;
    profile = [
        [ -7/16, -0.75],
        [  5/16,  0],
        [  7/16,  0],
        [  7/16, -0.75],
        [  1/ 2, -0.77],
    ];
    trapezoidal_threaded_rod(
        d=d, l=l, pitch=pitch,
        thread_depth=depth,
        thread_angle=30,
        profile=profile,
        left_handed=left_handed,
        bevel=bevel,
        internal=internal,
        anchor=anchor,
        spin=spin,
        orient=orient
    ) children();
}



// Module: buttress_threaded_nut()
// Description:
//   Constructs a hex nut for a simple buttress threaded screw rod.  This method
//   makes much smoother threads than the naive linear_extrude method.
// Arguments:
//   od = diameter of the nut.
//   id = diameter of threaded rod to screw onto.
//   h = height/thickness of nut.
//   pitch = Length between threads.
//   left_handed = if true, create left-handed threads.  Default = false
//   bevel = if true, bevel the thread ends.  Default: false
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
//   $slop = The printer-specific slop value to make parts fit just right.
// Examples(Med):
//   buttress_threaded_nut(od=16, id=8, h=8, pitch=1.25, left_handed=true, $slop=0.2, $fa=1, $fs=1);
module buttress_threaded_nut(
    od=16, id=10, h=10,
    pitch=2, left_handed=false,
    bevel=false,
    anchor, spin, orient
) {
    depth = pitch * 3/4;
    profile = [
        [ -7/16, -0.75],
        [  5/16,  0],
        [  7/16,  0],
        [  7/16, -0.75],
        [  1/ 2, -0.77],
    ];
    trapezoidal_threaded_nut(
        od=od, id=id, h=h,
        pitch=pitch, thread_angle=30,
        profile=profile,
        thread_depth=pitch*3*sqrt(3)/8,
        left_handed=left_handed,
        bevel=bevel,
        anchor=anchor, spin=spin,
        orient=orient
    ) children();
}


// Section: Metric Trapezoidal Threading

// Module: metric_trapezoidal_threaded_rod()
// Description:
//   Constructs a metric trapezoidal threaded screw rod.  This method makes much
//   smoother threads than the naive linear_extrude method.
// Arguments:
//   d = Outer diameter of threaded rod.
//   l = length of threaded rod.
//   pitch = Length between threads.
//   left_handed = if true, create left-handed threads.  Default = false
//   bevel = if true, bevel the thread ends.  Default: false
//   starts = The number of lead starts.  Default = 1
//   internal = If true, this is a mask for making internal threads.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
//   $slop = The printer-specific slop value to make parts fit just right.
// Example(2D):
//   projection(cut=true)
//       metric_trapezoidal_threaded_rod(d=10, l=15, pitch=2, orient=BACK);
// Examples(Med):
//   metric_trapezoidal_threaded_rod(d=10, l=30, pitch=2, left_handed=true, $fa=1, $fs=1);
module metric_trapezoidal_threaded_rod(
    d=10, l=100, pitch=2,
    left_handed=false,
    starts=1,
    bevel=false,
    internal=false,
    anchor, spin, orient
) {
    trapezoidal_threaded_rod(
        d=d, l=l,
        pitch=pitch,
        thread_angle=15,
        left_handed=left_handed,
        starts=starts,
        bevel=bevel,
        internal=internal,
        anchor=anchor,
        spin=spin,
        orient=orient
    ) children();
}



// Module: metric_trapezoidal_threaded_nut()
// Description:
//   Constructs a hex nut for a metric trapezoidal threaded screw rod.  This method
//   makes much smoother threads than the naive linear_extrude method.
// Arguments:
//   od = diameter of the nut.
//   id = diameter of threaded rod to screw onto.
//   h = height/thickness of nut.
//   pitch = Length between threads.
//   left_handed = if true, create left-handed threads.  Default = false
//   bevel = if true, bevel the thread ends.  Default: false
//   starts = The number of lead starts.  Default = 1
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
//   $slop = The printer-specific slop value to make parts fit just right.
// Examples(Med):
//   metric_trapezoidal_threaded_nut(od=16, id=10, h=10, pitch=2, left_handed=true, bevel=true, $fa=1, $fs=1);
module metric_trapezoidal_threaded_nut(
    od=17.4, id=10.5, h=10,
    pitch=3.175,
    starts=1,
    left_handed=false,
    bevel=false,
    anchor, spin, orient
) {
    trapezoidal_threaded_nut(
        od=od, id=id, h=h,
        pitch=pitch, thread_angle=15,
        left_handed=left_handed,
        starts=starts,
        bevel=bevel,
        anchor=anchor,
        spin=spin,
        orient=orient
    ) children();
}


// Section: ACME Trapezoidal Threading

// Module: acme_threaded_rod()
// Description:
//   Constructs an ACME trapezoidal threaded screw rod.  This method makes
//   much smoother threads than the naive linear_extrude method.
// Arguments:
//   d = Outer diameter of threaded rod.
//   l = length of threaded rod.
//   pitch = Length between threads.
//   thread_depth = Depth of the threads.  Default = pitch/2
//   thread_angle = The pressure angle profile angle of the threads.  Default = 14.5 degrees
//   starts = The number of lead starts.  Default = 1
//   left_handed = if true, create left-handed threads.  Default = false
//   bevel = if true, bevel the thread ends.  Default: false
//   internal = If true, this is a mask for making internal threads.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
//   $slop = The printer-specific slop value to make parts fit just right.
// Example(2D):
//   projection(cut=true)
//       acme_threaded_rod(d=10, l=15, pitch=2, orient=BACK);
// Examples(Med):
//   acme_threaded_rod(d=3/8*25.4, l=20, pitch=1/8*25.4, $fn=32);
//   acme_threaded_rod(d=10, l=30, pitch=2, starts=3, $fa=1, $fs=1);
module acme_threaded_rod(
    d=10, l=100, pitch=2,
    thread_angle=14.5,
    thread_depth=undef,
    starts=1,
    left_handed=false,
    bevel=false,
    internal=false,
    anchor, spin, orient
) {
    trapezoidal_threaded_rod(
        d=d, l=l, pitch=pitch,
        thread_angle=thread_angle,
        thread_depth=thread_depth,
        starts=starts,
        left_handed=left_handed,
        bevel=bevel,
        internal=internal,
        anchor=anchor,
        spin=spin,
        orient=orient
    ) children();
}



// Module: acme_threaded_nut()
// Description:
//   Constructs a hex nut for an ACME threaded screw rod.  This method makes
//   much smoother threads than the naive linear_extrude method.
// Arguments:
//   od = diameter of the nut.
//   id = diameter of threaded rod to screw onto.
//   h = height/thickness of nut.
//   pitch = Length between threads.
//   thread_depth = Depth of the threads.  Default=pitch/2
//   thread_angle = The pressure angle profile angle of the threads.  Default = 14.5 degree ACME profile.
//   left_handed = if true, create left-handed threads.  Default = false
//   bevel = if true, bevel the thread ends.  Default: false
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
//   $slop = The printer-specific slop value to make parts fit just right.
// Examples(Med):
//   acme_threaded_nut(od=16, id=3/8*25.4, h=8, pitch=1/8*25.4, $slop=0.2);
//   acme_threaded_nut(od=16, id=10, h=10, pitch=2, starts=3, $slop=0.2, $fa=1, $fs=1);
module acme_threaded_nut(
    od, id, h, pitch,
    thread_angle=14.5,
    thread_depth=undef,
    starts=1,
    left_handed=false,
    bevel=false,
    anchor, spin, orient
) {
    trapezoidal_threaded_nut(
        od=od, id=id, h=h, pitch=pitch,
        thread_depth=thread_depth,
        thread_angle=thread_angle,
        left_handed=left_handed,
        bevel=bevel,
        starts=starts,
        anchor=anchor,
        spin=spin,
        orient=orient
    ) children();
}


// Section: Square Threading

// Module: square_threaded_rod()
// Description:
//   Constructs a square profile threaded screw rod.  This method makes
//   much smoother threads than the naive linear_extrude method.
// Arguments:
//   d = Outer diameter of threaded rod.
//   l = length of threaded rod.
//   pitch = Length between threads.
//   left_handed = if true, create left-handed threads.  Default = false
//   bevel = if true, bevel the thread ends.  Default: false
//   starts = The number of lead starts.  Default = 1
//   internal = If true, this is a mask for making internal threads.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
//   $slop = The printer-specific slop value to make parts fit just right.
// Example(2D):
//   projection(cut=true)
//       square_threaded_rod(d=10, l=15, pitch=2, orient=BACK);
// Examples(Med):
//   square_threaded_rod(d=10, l=20, pitch=2, starts=2, $fn=32);
module square_threaded_rod(
    d=10, l=100, pitch=2,
    left_handed=false,
    bevel=false,
    starts=1,
    internal=false,
    anchor, spin, orient
) {
    trapezoidal_threaded_rod(
        d=d, l=l, pitch=pitch,
        thread_angle=0.1,
        left_handed=left_handed,
        bevel=bevel,
        starts=starts,
        internal=internal,
        anchor=anchor,
        spin=spin,
        orient=orient
    ) children();
}



// Module: square_threaded_nut()
// Description:
//   Constructs a hex nut for a square profile threaded screw rod.  This method
//   makes much smoother threads than the naive linear_extrude method.
// Arguments:
//   od = diameter of the nut.
//   id = diameter of threaded rod to screw onto.
//   h = height/thickness of nut.
//   pitch = Length between threads.
//   left_handed = if true, create left-handed threads.  Default = false
//   bevel = if true, bevel the thread ends.  Default: false
//   starts = The number of lead starts.  Default = 1
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
//   $slop = The printer-specific slop value to make parts fit just right.
// Examples(Med):
//   square_threaded_nut(od=16, id=10, h=10, pitch=2, starts=2, $slop=0.15, $fn=32);
module square_threaded_nut(
    od=17.4, id=10.5, h=10,
    pitch=3.175,
    left_handed=false,
    bevel=false,
    starts=1,
    anchor, spin, orient
) {
    trapezoidal_threaded_nut(
        od=od, id=id, h=h, pitch=pitch,
        thread_angle=0,
        left_handed=left_handed,
        bevel=bevel,
        starts=starts,
        anchor=anchor,
        spin=spin,
        orient=orient
    ) children();
}


// Section: Ball Screws

// Module: ball_screw_rod()
// Description:
//   Constructs a ball screw rod.  This method makes much smoother threads than the naive linear_extrude method.
// Arguments:
//   d = Outer diameter of threaded rod.
//   l = length of threaded rod.
//   pitch = Length between threads.  Also, the diameter of the ball bearings used.
//   ball_diam = The diameter of the ball bearings to use with this ball screw.
//   ball_arc = The arc portion that should touch the ball bearings. Default: 120 degrees.
//   left_handed = if true, create left-handed threads.  Default = false
//   starts = The number of lead starts.  Default = 1
//   bevel = if true, bevel the thread ends.  Default: false
//   internal = If true, make this a mask for making internal threads.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
//   $slop = The printer-specific slop value to make parts fit just right.
// Example(2D): Thread Profile, ball_diam=4, ball_arc=100
//   projection(cut=true) ball_screw_rod(d=10, l=15, pitch=5, ball_diam=4, ball_arc=100, orient=BACK);
// Example(2D): Thread Profile, ball_diam=4, ball_arc=120
//   projection(cut=true) ball_screw_rod(d=10, l=15, pitch=5, ball_diam=4, ball_arc=120, orient=BACK);
// Example(2D): Thread Profile, ball_diam=3, ball_arc=120
//   projection(cut=true) ball_screw_rod(d=10, l=15, pitch=5, ball_diam=3, ball_arc=120, orient=BACK);
// Examples(Med):
//   ball_screw_rod(d=15, l=20, pitch=8, ball_diam=5, ball_arc=120, $fa=1, $fs=1);
//   ball_screw_rod(d=15, l=20, pitch=5, ball_diam=4, ball_arc=120, $fa=1, $fs=1);
//   ball_screw_rod(d=15, l=20, pitch=5, ball_diam=4, ball_arc=120, left_handed=true, $fa=1, $fs=1);
module ball_screw_rod(
    d=10, l=100, pitch=2, starts=1,
    ball_diam=5, ball_arc=100,
    left_handed=false,
    internal=false,
    bevel=false,
    anchor, spin, orient
) {
    n = ceil(segs(ball_diam/2)*ball_arc/2/360);
    depth = ball_diam * (1-cos(ball_arc/2))/2;
    cpy = ball_diam/2/pitch*cos(ball_arc/2);
    profile = [
        each arc(N=n, d=ball_diam/pitch, cp=[-0.5,cpy], start=270, angle=ball_arc/2),
        each arc(N=n, d=ball_diam/pitch, cp=[+0.5,cpy], start=270-ball_arc/2, angle=ball_arc/2)
    ];
    trapezoidal_threaded_rod(
        d=d, l=l, pitch=pitch,
        thread_depth=depth,
        thread_angle=90-ball_arc/2,
        profile=profile,
        left_handed=left_handed,
        starts=starts,
        bevel=bevel,
        internal=internal,
        higbee=0,
        anchor=anchor,
        spin=spin,
        orient=orient
    ) children();
}



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
