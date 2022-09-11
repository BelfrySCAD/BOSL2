//////////////////////////////////////////////////////////////////////
// LibFile: threading.scad
//   Provides generic threading support and specialized support for standard triangular (UTS/ISO) threading,
//   trapezoidal threading (ACME), pipe threading, buttress threading, square threading and ball screws.  
// Includes:
//   include <BOSL2/std.scad>
//   include <BOSL2/threading.scad>
// FileGroup: Threaded Parts
// FileSummary: Various types of threaded rods and nuts.
//////////////////////////////////////////////////////////////////////

// Section: Standard (UTS/ISO) Threading

// Module: threaded_rod()
// Usage:
//   threaded_rod(d, l, pitch, [internal=], ...) [ATTACHMENTS];
// Description:
//   Constructs a standard ISO (metric) or UTS (English) threaded rod.  These threads are close to triangular,
//   with a 60 degree thread angle.  You can give the outer diameter and get the "basic form" or you can
//   set d to a triplet [d_min, d_pitch, d_major] where are parameters determined by the ISO and UTS specifications
//   that define clearance sizing for the threading.  See screws.scad for how to make screws
//   using the specification parameters.  
// Arguments:
//   d = Outer diameter of threaded rod, or a triplet of [d_min, d_pitch, d_major]. 
//   l = length of threaded rod.
//   pitch = Length between threads.
//   ---
//   left_handed = if true, create left-handed threads.  Default = false
//   starts = The number of lead starts.  Default: 1
//   bevel = if true, bevel the thread ends.  Default: false
//   bevel1 = if true bevel the bottom end.
//   bevel2 = if true bevel the top end.
//   internal = If true, make this a mask for making internal threads.
//   d1 = Bottom outside diameter of threads.
//   d2 = Top outside diameter of threads.
//   higbee = Length to taper thread ends over.  Default: 0
//   higbee1 = Length to taper bottom thread end over.
//   higbee2 = Length to taper top thread end over.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   $slop = The printer-specific slop value, which adds clearance (`4*$slop`) to internal threads.
// Example(2D):
//   projection(cut=true)
//       threaded_rod(d=10, l=15, pitch=1.5, orient=BACK);
// Examples(Med):
//   threaded_rod(d=10, l=20, pitch=1.25, left_handed=true, $fa=1, $fs=1);
//   threaded_rod(d=25, l=20, pitch=2, $fa=1, $fs=1);
// Example: Diamond threading where both left-handed and right-handed nuts travel (in the same direction) on the threaded rod:
//   $slop = 0.075;
//   d = 3/8*INCH;
//   pitch = 1/16*INCH;
//   starts=3;
//   xdistribute(19){
//       intersection(){
//         threaded_rod(l=40, pitch=pitch, d=d,starts=starts,anchor=BOTTOM);
//         threaded_rod(l=40, pitch=pitch, d=d, left_handed=true,starts=starts,anchor=BOTTOM);
//       }
//       threaded_nut(od=4.5/8*INCH,id=d,h=3/8*INCH,pitch=pitch,starts=starts,anchor=BOTTOM);
//       threaded_nut(od=4.5/8*INCH,id=d,h=3/8*INCH,pitch=pitch,starts=starts,left_handed=true,anchor=BOTTOM);
//   }
function threaded_rod(
    d, l, pitch,
    left_handed=false,
    bevel,bevel1,bevel2,starts=1,
    internal=false,
    d1, d2,
    higbee, higbee1, higbee2,
    anchor, spin, orient
) = no_function("threaded_rod");

module threaded_rod(
    d, l, pitch,
    left_handed=false,
    bevel,bevel1,bevel2,starts=1,
    internal=false,
    d1, d2,
    higbee, higbee1, higbee2,
    anchor, spin, orient
) {
    dummy1=
      assert(all_positive(pitch))
      assert(all_positive(d))
      assert(all_positive(l));
    basic = is_num(d) || is_undef(d) || is_def(d1) || is_def(d2);
    dummy2 = assert(basic || is_vector(d,3));
    depth = basic ? cos(30) * 5/8
                  : (d[2] - d[0])/2/pitch;
    crestwidth = basic ? 1/8 : 1/2 - (d[2]-d[1])/sqrt(3)/pitch;
    profile =    [
                  [-depth/sqrt(3)-crestwidth/2, -depth],
                  [              -crestwidth/2,      0],
                  [               crestwidth/2,      0],
                  [ depth/sqrt(3)+crestwidth/2, -depth]
                 ];
    oprofile = internal? [
        [-6/16, -depth],
        [-1/16,  0],
        [-1/32,  0.02],
        [ 1/32,  0.02],
        [ 1/16,  0],
        [ 6/16, -depth]
    ] : [
        [-7/16, -depth*1.07],
        [-6/16, -depth],
        [-1/16,  0],
        [ 1/16,  0],
        [ 6/16, -depth],
        [ 7/16, -depth*1.07]
    ];
    generic_threaded_rod(
        d=basic ? d : d[2], d1=d1, d2=d2, l=l,
        pitch=pitch,
        profile=profile,starts=starts,
        left_handed=left_handed,
        bevel=bevel,bevel1=bevel1,bevel2=bevel2,
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
// Usage:
//   threaded_nut(od, id, h, pitch,...) [ATTACHMENTS];
// Description:
//   Constructs a hex nut for an ISO (metric) or UTS (English) threaded rod. 
// Arguments:
//   od = diameter of the nut.
//   id = diameter of threaded rod to screw onto.
//   h = height/thickness of nut.
//   pitch = Length between threads.
//   ---
//   left_handed = if true, create left-handed threads.  Default = false
//   starts = The number of lead starts.  Default: 1
//   bevel = if true, bevel the thread ends.  Default: false
//   bevel1 = if true bevel the bottom end.
//   bevel2 = if true bevel the top end. 
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   $slop = The printer-specific slop value, which adds clearance (`4*$slop`) to internal threads.
// Examples(Med):
//   threaded_nut(od=16, id=8, h=8, pitch=1.25, $slop=0.05, $fa=1, $fs=1);
//   threaded_nut(od=16, id=8, h=8, pitch=1.25, left_handed=true, bevel=true, $slop=0.1, $fa=1, $fs=1);
function threaded_nut(
    od, id, h,
    pitch, starts=1, left_handed=false, bevel, bevel1, bevel2, id1,id2,
    anchor, spin, orient
)=no_function("threaded_nut");
module threaded_nut(
    od, id, h,
    pitch, starts=1, left_handed=false, bevel, bevel1, bevel2, id1,id2,
    anchor, spin, orient
) {
    dummy1=
    assert(all_positive(pitch))
    assert(all_positive(id))
    assert(all_positive(h));
    basic = is_num(id) || is_undef(id) || is_def(id1) || is_def(id2);
    dummy2 = assert(basic || is_vector(id,3));
    depth = basic ? cos(30) * 5/8
                  : (id[2] - id[0])/2/pitch;
    crestwidth = basic ? 1/8 : 1/2 - (id[2]-id[1])/sqrt(3)/pitch;
    profile =    [
                  [-depth/sqrt(3)-crestwidth/2, -depth],
                  [              -crestwidth/2,      0],
                  [               crestwidth/2,      0],
                  [ depth/sqrt(3)+crestwidth/2, -depth]
                 ];
    oprofile = [
        [-6/16, -depth/pitch],
        [-1/16,  0],
        [-1/32,  0.02],
        [ 1/32,  0.02],
        [ 1/16,  0],
        [ 6/16, -depth/pitch]
    ];
    generic_threaded_nut(
        od=od,
        id=basic ? id : id[2], id1=id1, id2=id2,
        h=h,
        pitch=pitch,
        profile=profile,starts=starts,
        left_handed=left_handed,
        bevel=bevel,bevel1=bevel1,bevel2=bevel2,
        anchor=anchor, spin=spin,
        orient=orient
    ) children();
}

// Section: Trapezoidal Threading


// Module: trapezoidal_threaded_rod()
// Usage:
//   trapezoidal_threaded_rod(d, l, pitch, [thread_angle], [thread_depth], [internal=], ...) [ATTACHMENTS];
// Description:
//   Constructs a threaded rod with a symmetric trapezoidal thread.  Trapezoidal threads are used for lead screws because
//   they are one of the strongest symmetric profiles.  This tooth shape is stronger than a similarly
//   sized square thread becuase of its wider base.  However, it does place a radial load on the nut, unlike the square thread.
//   For loads in only one direction the asymmetric buttress thread profile can bear greater loads.  
//   .
//   By default produces the nominal dimensions
//   for metric trapezoidal threads: a thread angle of 30 degrees and a depth set to half the pitch.
//   You can also specify your own trapezoid parameters.  For ACME threads see acme_threaded_rod().
// Figure(2D,Med,NoAxes):
//   pa_delta = tan(15)/4;
//   rr1 = -1/2;
//   z1 = 1/4-pa_delta;
//   z2 = 1/4+pa_delta;
//   profile = [
//               [-z2, rr1],
//               [-z1,  0],
//               [ z1,  0],
//               [ z2, rr1],
//             ];
//   fullprofile = 50*left(1/2,p=concat(profile, right(1, p=profile)));
//   stroke(fullprofile,width=1);
//   dir = fullprofile[2]-fullprofile[3];
//   dir2 = fullprofile[5]-fullprofile[4];
//   curve = arc(32,angle=[75,105],r=67.5);
//   avgpt = mean([fullprofile[5]+.1*dir2, fullprofile[5]+.4*dir2]);
//   color("red"){
//    stroke([fullprofile[2]+.1*dir, fullprofile[2]+.4*dir], width=1);
//    stroke([fullprofile[5]+.1*dir2, fullprofile[5]+.4*dir2], width=1);
//    stroke(move(-curve[0]+avgpt,p=curve), width=1,endcaps="arrow2");
//    back(10)text("thread",size=4,halign="center");
//    back(3)text("angle",size=4,halign="center");
//   }
// Arguments:
//   d = Outer diameter of threaded rod.
//   l = Length of threaded rod.
//   pitch = Thread spacing. 
//   thread_angle = Angle between two thread faces.  Default: 30
//   thread_depth = Depth of threads.  Default: pitch/2
//   ---
//   left_handed = If true, create left-handed threads.  Default: false
//   starts = The number of lead starts.  Default: 1
//   bevel = if true, bevel the thread ends.  Default: false
//   bevel1 = if true bevel the bottom end.
//   bevel2 = if true bevel the top end. 
//   internal = If true, make this a mask for making internal threads.  Default: false
//   d1 = Bottom outside diameter of threads.
//   d2 = Top outside diameter of threads.
//   higbee = Length to taper thread ends over.  Default: 0 (No higbee thread tapering)
//   higbee1 = Length to taper bottom thread end over.
//   higbee2 = Length to taper top thread end over.
//   center = If given, overrides `anchor`.  A true value sets `anchor=CENTER`, false sets `anchor=UP`.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   $slop = The printer-specific slop value, which adds clearance (`4*$slop`) to internal threads.
// Example(2D):
//   projection(cut=true)
//       trapezoidal_threaded_rod(d=10, l=15, pitch=2, orient=BACK);
// Examples(Med): 
//   trapezoidal_threaded_rod(d=10, l=40, pitch=2, $fn=32);  // Standard metric threading
//   trapezoidal_threaded_rod(d=10, l=17, pitch=2, higbee=25, $fn=32);  // Standard metric threading
//   trapezoidal_threaded_rod(d=10, l=17, pitch=2, bevel=true, $fn=32);  // Standard metric threading
//   trapezoidal_threaded_rod(d=10, l=30, pitch=2, left_handed=true, $fa=1, $fs=1);  // Standard metric threading
//   trapezoidal_threaded_rod(d=10, l=40, pitch=3, left_handed=true, starts=3, $fn=36);
//   trapezoidal_threaded_rod(l=25, d=10, pitch=2, starts=3, $fa=1, $fs=1, orient=RIGHT, anchor=BOTTOM);
//   trapezoidal_threaded_rod(d=60, l=16, pitch=8, thread_depth=3, thread_angle=90, left_handed=true, $fa=2, $fs=2);
//   trapezoidal_threaded_rod(d=60, l=16, pitch=8, thread_depth=3, thread_angle=90, left_handed=true, starts=4, $fa=2, $fs=2);
//   trapezoidal_threaded_rod(d=16, l=40, pitch=2, thread_angle=60);
//   trapezoidal_threaded_rod(d=25, l=40, pitch=10, thread_depth=8/3, thread_angle=100, starts=4, center=false, $fa=2, $fs=2);
//   trapezoidal_threaded_rod(d=50, l=35, pitch=8, thread_angle=60, starts=11, higbee=10,$fn=120);
// Example(Med): Using as a Mask to Make Internal Threads
//   bottom_half() difference() {
//       cube(50, center=true);
//       trapezoidal_threaded_rod(d=40, l=51, pitch=5, thread_angle=30, internal=true, orient=RIGHT, $fn=36);
//   }
function trapezoidal_threaded_rod(
    d, l, pitch,
    thread_angle=30,
    thread_depth=undef,
    left_handed=false,
    bevel,bevel1,bevel2,
    starts=1,
    internal=false,
    higbee, higbee1, higbee2,d1,d2,
    center, anchor, spin, orient
) = no_function("trapezoidal_threaded_rod");
module trapezoidal_threaded_rod(
    d, l, pitch,
    thread_angle=30,
    thread_depth=undef,
    left_handed=false,
    bevel,bevel1,bevel2,
    starts=1,
    internal=false,
    higbee, higbee1, higbee2,d1,d2,
    center, anchor, spin, orient
) {
    dummy0 = assert(all_positive(pitch));
    dummy1 = assert(thread_angle>=0 && thread_angle<180);
    depth = first_defined([thread_depth, pitch/2]);
    pa_delta = 0.5*depth*tan(thread_angle/2) / pitch;
    dummy2 = assert(pa_delta<1/4, "Specified thread geometry is impossible");
    rr1 = -depth/pitch;
    z1 = 1/4-pa_delta;
    z2 = 1/4+pa_delta;
    profile = [
               [-z2, rr1],
               [-z1,  0],
               [ z1,  0],
               [ z2, rr1],
              ];
    generic_threaded_rod(d=d,l=l,pitch=pitch,profile=profile,
                         left_handed=left_handed,bevel=bevel,bevel1=bevel1,bevel2=bevel2,starts=starts,internal=internal,d1=d1,d2=d2,
                         higbee=higbee,higbee1=higbee1,higbee2=higbee2,center=center,anchor=anchor,spin=spin,orient=orient)
      children();
}


// Module: trapezoidal_threaded_nut()
// Usage:
//   trapezoidal_threaded_nut(od, id, h, pitch, [thread_angle], [thread_depth], ...) [ATTACHMENTS];
// Description:
//   Constructs a hex nut for a symmetric trapzoidal threaded rod.
//   By default produces the nominal dimensions
//   for metric trapezoidal threads: a thread angle of 30 degrees and a depth set to half the pitch.
//   You can also specify your own trapezoid parameters.  For ACME threads see acme_threaded_nut(). 
// Arguments:
//   od = diameter of the nut.
//   id = diameter of threaded rod to screw onto.
//   h = height/thickness of nut.
//   pitch = Thread spacing.
//   thread_angle = Angle between two thread faces.  Default: 30
//   thread_depth = Depth of the threads.  Default: pitch/2
//   ---
//   left_handed = if true, create left-handed threads.  Default = false
//   starts = The number of lead starts.  Default = 1
//   bevel = if true, bevel the thread ends.  Default: false
//   bevel1 = if true bevel the bottom end.
//   bevel2 = if true bevel the top end. 
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   $slop = The printer-specific slop value, which adds clearance (`4*$slop`) to internal threads.
// Examples(Med):
//   trapezoidal_threaded_nut(od=16, id=8, h=8, pitch=2, $slop=0.1, anchor=UP);
//   trapezoidal_threaded_nut(od=16, id=8, h=8, pitch=2, bevel=true, $slop=0.05, anchor=UP);
//   trapezoidal_threaded_nut(od=17.4, id=10, h=10, pitch=2, $slop=0.1, left_handed=true);
//   trapezoidal_threaded_nut(od=17.4, id=10, h=10, pitch=2, starts=3, $fa=1, $fs=1, $slop=0.15);
function trapezoidal_threaded_rod(
    d, l, pitch,
    thread_angle=30,
    thread_depth=undef,
    left_handed=false,
    bevel,bevel1,bevel2,
    starts=1,
    internal=false,
    higbee, higbee1, higbee2,d1,d2,
    center, anchor, spin, orient
) = no_function("trapezoidal_threaded_nut");
module trapezoidal_threaded_nut(
    od,
    id,
    h,
    pitch,
    thread_angle=30,
    thread_depth,
    left_handed=false,
    starts=1,
    bevel,bevel1,bevel2,
    id1,id2,
    anchor, spin, orient
) {
    dummy1 = assert(pitch>0 && thread_angle>=0 && thread_angle<180);
    depth = first_defined([thread_depth, pitch/2]);
    pa_delta = 0.5*depth*tan(thread_angle/2) / pitch;
    dummy2 = assert(pa_delta<1/4, "Specified thread geometry is impossible");
    rr1 = -depth/pitch;
    z1 = 1/4-pa_delta;
    z2 = 1/4+pa_delta;
    profile = [
               [-z2, rr1],
               [-z1,  0],
               [ z1,  0],
               [ z2, rr1],
              ];
    generic_threaded_nut(od=od,id=id,h=h,pitch=pitch,profile=profile,id1=id1,id2=id2,
                         left_handed=left_handed,bevel=bevel,bevel1=bevel1,bevel2=bevel2,starts=starts,
                         anchor=anchor,spin=spin,orient=orient)
      children();
}


// Module: acme_threaded_rod()
// Usage:
//   acme_threaded_rod(d, l, tpi|pitch=, [internal=], ...) [ATTACHMENTS];
// Description:
//   Constructs an ACME trapezoidal threaded screw rod.  This form has a 29 degree thread angle with a
//   symmetric trapezoidal thread.  
// Arguments:
//   d = Outer diameter of threaded rod.
//   l = length of threaded rod.
//   tpi = threads per inch.
//   ---
//   pitch = thread spacing (alternative to tpi)
//   starts = The number of lead starts.  Default = 1
//   left_handed = if true, create left-handed threads.  Default = false
//   bevel = if true, bevel the thread ends.  Default: false
//   bevel1 = if true bevel the bottom end.
//   bevel2 = if true bevel the top end. 
//   internal = If true, this is a mask for making internal threads.
//   higbee = Length to taper thread ends over.  Default: 0 (No higbee thread tapering)
//   higbee1 = Length to taper bottom thread end over.
//   higbee2 = Length to taper top thread end over.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   $slop = The printer-specific slop value, which adds clearance (`4*$slop`) to internal threads.
// Example(2D):
//   projection(cut=true)
//       acme_threaded_rod(d=10, l=15, pitch=2, orient=BACK);
// Examples(Med):
//   acme_threaded_rod(d=3/8*INCH, l=20, pitch=1/8*INCH, $fn=32);
//   acme_threaded_rod(d=10, l=30, pitch=2, starts=3, $fa=1, $fs=1);
function acme_threaded_rod(
    d, l, tpi, pitch,
    starts=1,
    left_handed=false,
    bevel,bevel1,bevel2,
    internal=false,
    higbee, higbee1, higbee2,
    anchor, spin, orient
) = no_function("acme_threaded_rod");
module acme_threaded_rod(
    d, l, tpi, pitch,
    starts=1,
    left_handed=false,
    bevel,bevel1,bevel2,
    internal=false,
    higbee, higbee1, higbee2,
    anchor, spin, orient
) {
    dummy = assert(num_defined([pitch,tpi])==1,"Must give exactly one of pitch and tpi");
    pitch = is_undef(pitch) ? INCH/tpi : pitch;
    trapezoidal_threaded_rod(
        d=d, l=l, pitch=pitch,
        thread_angle=29,
        thread_depth=pitch/2,
        starts=starts,
        left_handed=left_handed,
        bevel=bevel,bevel1=bevel1,bevel2=bevel2,
        internal=internal,
        anchor=anchor,
        spin=spin,
        orient=orient
    ) children();
}



// Module: acme_threaded_nut()
// Usage:
//   acme_threaded_nut(od, id, h, tpi|pitch=, ...) [ATTACHMENTS];
// Description:
//   Constructs a hex nut for an ACME threaded screw rod. 
// Arguments:
//   od = diameter of the nut.
//   id = diameter of threaded rod to screw onto.
//   h = height/thickness of nut.
//   tpi = threads per inch
//   ---
//   pitch = Thread spacing (alternative to tpi)
//   left_handed = if true, create left-handed threads.  Default = false
//   starts = Number of lead starts.  Default: 1
//   bevel = if true, bevel the thread ends.  Default: false
//   bevel1 = if true bevel the bottom end.
//   bevel2 = if true bevel the top end. 
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   $slop = The printer-specific slop value, which adds clearance (`4*$slop`) to internal threads.
// Examples(Med):
//   acme_threaded_nut(od=16, id=3/8*INCH, h=8, tpi=8, $slop=0.05);
//   acme_threaded_nut(od=16, id=1/2*INCH, h=10, tpi=12, starts=3, $slop=0.1, $fa=1, $fs=1);
function acme_threaded_nut(
    od, id, h, tpi, pitch,
    starts=1,
    left_handed=false,
    bevel,bevel1,bevel2,
    anchor, spin, orient
) = no_function("acme_threaded_nut");
module acme_threaded_nut(
    od, id, h, tpi, pitch,
    starts=1,
    left_handed=false,
    bevel,bevel1,bevel2,
    anchor, spin, orient
) {
    dummy = assert(num_defined([pitch,tpi])==1,"Must give exactly one of pitch and tpi");
    pitch = is_undef(pitch) ? INCH/tpi : pitch;
    dummy2=assert(is_num(pitch) && pitch>0);
    trapezoidal_threaded_nut(
        od=od, id=id, h=h, pitch=pitch,
        thread_depth = pitch/2, 
        thread_angle=29,
        left_handed=left_handed,
        bevel=bevel,bevel1=bevel1,bevel2=bevel2,
        starts=starts,
        anchor=anchor,
        spin=spin,
        orient=orient
    ) children();
}




// Section: Pipe Threading

// Module: npt_threaded_rod()
// Usage:
//   npt_threaded_rod(size, [internal=], ...) [ATTACHMENTS];
// Description:
//   Constructs a standard NPT pipe end threading. If `internal=true`, creates a mask for making
//   internal pipe threads.  Tapers smaller upwards if `internal=false`.  Tapers smaller downwards
//   if `internal=true`.  If `hollow=true` and `internal=false`, then the pipe threads will be
//   hollowed out into a pipe with the apropriate internal diameter.
// Arguments:
//   size = NPT standard pipe size in inches.  1/16", 1/8", 1/4", 3/8", 1/2", 3/4", 1", 1+1/4", 1+1/2", or 2".  Default: 1/2"
//   ---
//   left_handed = If true, create left-handed threads.  Default = false
//   bevel = if true, bevel the thread ends.  Default: false
//   bevel1 = if true bevel the bottom end.
//   bevel2 = if true bevel the top end. 
//   hollow = If true, create a pipe with the correct internal diameter.
//   internal = If true, make this a mask for making internal threads.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   $slop = The printer-specific slop value, which adds clearance (`4*$slop`) to internal threads.
// Example(2D): The straight gray rectangle reveals the tapered threads.  
//   projection(cut=true) npt_threaded_rod(size=1/4, orient=BACK);
//   right(.533*INCH/2) color("gray") rect([2,0.5946*INCH],anchor=LEFT);
// Examples(Med):
//   npt_threaded_rod(size=3/8, $fn=72);
//   npt_threaded_rod(size=1/2, $fn=72, bevel=true);
//   npt_threaded_rod(size=1/2, left_handed=true, $fn=72);
//   npt_threaded_rod(size=3/4, hollow=true, $fn=96);
// Example:
//   diff("remove"){
//      cuboid([40,40,40])
//      tag("remove"){
//        up(.01)position(TOP)
//            npt_threaded_rod(size=3/4, $fn=96, internal=true, $slop=0.1, anchor=TOP);
//        cyl(d=3/4*INCH, l=42, $fn=32);
//      }
//   }
function npt_threaded_rod(
    size=1/2,
    left_handed=false,
    bevel,bevel1,bevel2,
    hollow=false,
    internal=false,
    anchor, spin, orient
)=no_function("npt_threaded_rod");
module npt_threaded_rod(
    size=1/2,
    left_handed=false,
    bevel,bevel1,bevel2,
    hollow=false,
    internal=false,
    anchor, spin, orient
) {
    assert(is_finite(size));
    assert(is_bool(left_handed));
    assert(is_undef(bevel) || is_bool(bevel));
    assert(is_bool(hollow));
    assert(is_bool(internal));
    assert(!(internal&&hollow), "Cannot created a hollow internal threads mask.");
    info_table = [
        // Size    len      OD    TPI
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
    l = INCH * info[0];
    d = INCH * info[1];
    pitch = INCH / info[2];
    rr = d/2;
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
            generic_threaded_rod(
                d1=2*r1, d2=2*r2, l=l,
                pitch=pitch,
                profile=profile,
                left_handed=left_handed,
                bevel=bevel,bevel1=bevel1,bevel2=bevel2,
                internal=internal,
                higbee=r1*PI/2
            );
            if (hollow) cylinder(l=l+1, d=size*INCH, center=true);
        }
        children();
    }
}



// Section: Buttress Threading

// Module: buttress_threaded_rod()
// Usage:
//   buttress_threaded_rod(d, l, pitch, [internal=], ...) [ATTACHMENTS];
// Description:
//   Constructs a simple buttress threaded rod with a 45 degree angle.  The buttress thread or sawtooth thread has low friction and high loading
//   in one direction at the cost of higher friction and inferior loading in the other direction.  Buttress threads are sometimes used on
//   vises, which are loaded only in one direction.  
// Arguments:
//   d = Outer diameter of threaded rod.
//   l = length of threaded rod.
//   pitch = Thread spacing.
//   ---
//   left_handed = if true, create left-handed threads.  Default = false
//   starts = Number of lead starts.  Default: 1
//   bevel = if true, bevel the thread ends.  Default: false
//   bevel1 = if true bevel the bottom end.
//   bevel2 = if true bevel the top end. 
//   internal = If true, this is a mask for making internal threads.
//   higbee = Length to taper thread ends over.  Default: 0
//   higbee1 = Length to taper bottom thread end over.
//   higbee2 = Length to taper top thread end over.
//   d1 = Bottom outside diameter of threads.
//   d2 = Top outside diameter of threads.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   $slop = The printer-specific slop value, which adds clearance (`4*$slop`) to internal threads.
// Example(2D):
//   projection(cut=true)
//       buttress_threaded_rod(d=10, l=15, pitch=2, orient=BACK);
// Examples(Med):
//   buttress_threaded_rod(d=10, l=20, pitch=1.25, left_handed=true, $fa=1, $fs=1);
//   buttress_threaded_rod(d=25, l=20, pitch=2, $fa=1, $fs=1);
function buttress_threaded_rod(
    d=10, l=100, pitch=2,
    left_handed=false,
    bevel,bevel1,bevel2,
    internal=false,
    higbee=0,
    higbee1,
    higbee2,
    d1,d2,starts,
    anchor, spin, orient
) = no_function("buttress_threaded_rod");
module buttress_threaded_rod(
    d=10, l=100, pitch=2,
    left_handed=false,
    bevel,bevel1,bevel2,
    internal=false,
    higbee=0,
    higbee1,
    higbee2,
    d1,d2,starts=1,
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
    generic_threaded_rod(
        d=d, l=l, pitch=pitch,
        profile=profile, 
        left_handed=left_handed,
        bevel=bevel,bevel1=bevel1,bevel2=bevel2,
        internal=internal,
        higbee=higbee,
        higbee1=higbee1,
        higbee2=higbee2,
        d1=d1,d2=d2,
        anchor=anchor,
        spin=spin,starts=starts,
        orient=orient
    ) children();
}



// Module: buttress_threaded_nut()
// Usage:
//   buttress_threaded_nut(od, id, h, pitch, ...) [ATTACHMENTS];
// Description:
//   Constructs a hex nut for a simple buttress threaded screw rod.  
// Arguments:
//   od = diameter of the nut.
//   id = diameter of threaded rod to screw onto.
//   h = height/thickness of nut.
//   pitch = Thread spacing. 
//   ---
//   left_handed = if true, create left-handed threads.  Default = false
//   starts = The number of lead starts.  Default: 1
//   bevel = if true, bevel the thread ends.  Default: false
//   bevel1 = if true bevel the bottom end.
//   bevel2 = if true bevel the top end. 
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   $slop = The printer-specific slop value, which adds clearance (`4*$slop`) to internal threads.
// Examples(Med):
//   buttress_threaded_nut(od=16, id=8, h=8, pitch=1.25, left_handed=true, $slop=0.05, $fa=1, $fs=1);
function buttress_threaded_nut(
    od=16, id=10, h=10,
    pitch=2, left_handed=false,
    bevel,bevel1,bevel2,starts,
    anchor, spin, orient
) = no_function("buttress_threaded_nut");
module buttress_threaded_nut(
    od=16, id=10, h=10,
    pitch=2, left_handed=false,
    bevel,bevel1,bevel2,starts=1,
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
    generic_threaded_nut(
        od=od, id=id, h=h,
        pitch=pitch,
        profile=profile,
        left_handed=left_handed,starts=starts,
        bevel=bevel,bevel1=bevel1,bevel2=bevel2,
        anchor=anchor, spin=spin,
        orient=orient
    ) children();
}



// Section: Square Threading

// Module: square_threaded_rod()
// Usage:
//   square_threaded_rod(d, l, pitch, [internal=], ...) [ATTACHMENTS];
// Description:
//   Constructs a square profile threaded screw rod.  The greatest advantage of square threads is that they have the least friction and a much higher intrinsic efficiency than trapezoidal threads.
//   They produce no radial load on the nut.  However, square threads cannot carry as much load as trapezoidal threads. 
// Arguments:
//   d = Outer diameter of threaded rod.
//   l = length of threaded rod.
//   pitch = Thread spacing.
//   ---
//   left_handed = if true, create left-handed threads.  Default = false
//   starts = The number of lead starts.  Default = 1
//   bevel = if true, bevel the thread ends.  Default: false
//   bevel1 = if true bevel the bottom end.
//   bevel2 = if true bevel the top end. 
//   internal = If true, this is a mask for making internal threads.
//   higbee = Length to taper thread ends over.  Default: 0
//   higbee1 = Length to taper bottom thread end over.
//   higbee2 = Length to taper top thread end over.
//   d1 = Bottom outside diameter of threads.
//   d2 = Top outside diameter of threads.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   $slop = The printer-specific slop value, which adds clearance (`4*$slop`) to internal threads.
// Example(2D):
//   projection(cut=true)
//       square_threaded_rod(d=10, l=15, pitch=2, orient=BACK);
// Examples(Med):
//   square_threaded_rod(d=10, l=20, pitch=2, starts=2, $fn=32);
function square_threaded_rod(
    d, l, pitch,
    left_handed=false,
    bevel,bevel1,bevel2,
    starts=1,
    internal=false,
    higbee=0, higbee1, higbee2,
    d1,d2,
    anchor, spin, orient
) = no_function("square_threaded_rod");
module square_threaded_rod(
    d, l, pitch,
    left_handed=false,
    bevel,bevel1,bevel2,
    starts=1,
    internal=false,
    higbee=0, higbee1, higbee2,
    d1,d2,
    anchor, spin, orient
) {
    trapezoidal_threaded_rod(
        d=d, l=l, pitch=pitch,
        thread_angle=0.1,
        left_handed=left_handed,
        bevel=bevel,bevel1=bevel1,bevel2=bevel2,
        starts=starts,
        internal=internal,
        higbee=higbee,
        higbee1=higbee1,
        higbee2=higbee2,
        d1=d1,
        d2=d2,
        anchor=anchor,
        spin=spin,
        orient=orient
    ) children();
}



// Module: square_threaded_nut()
// Usage:
//   square_threaded_nut(od, id, h, pitch, ...) [ATTACHMENTS];
// Description:
//   Constructs a hex nut for a square profile threaded screw rod.  
// Arguments:
//   od = diameter of the nut.
//   id = diameter of threaded rod to screw onto.
//   h = height/thickness of nut.
//   pitch = Length between threads.
//   ---
//   left_handed = if true, create left-handed threads.  Default = false
//   starts = The number of lead starts.  Default = 1
//   bevel = if true, bevel the thread ends.  Default: false
//   bevel1 = if true bevel the bottom end.
//   bevel2 = if true bevel the top end. 
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   $slop = The printer-specific slop value, which adds clearance (`4*$slop`) to internal threads.
// Examples(Med):
//   square_threaded_nut(od=16, id=10, h=10, pitch=2, starts=2, $slop=0.1, $fn=32);
function square_threaded_nut(
    od, id, h,
    pitch,
    left_handed=false,
    bevel,bevel1,bevel2,
    starts=1,
    anchor, spin, orient
) = no_function("square_threaded_nut");
module square_threaded_nut(
    od, id, h,
    pitch,
    left_handed=false,
    bevel,bevel1,bevel2,
    starts=1,
    anchor, spin, orient
) {
    assert(is_num(pitch) && pitch>0)
    trapezoidal_threaded_nut(
        od=od, id=id, h=h, pitch=pitch,
        thread_angle=0,
        left_handed=left_handed,
        bevel=bevel,bevel1=bevel1,bevel2=bevel2,
        starts=starts,
        anchor=anchor,
        spin=spin,
        orient=orient
    ) children();
}


// Section: Ball Screws

// Module: ball_screw_rod()
// Usage:
//   ball_screw_rod(d, l, pitch, [ball_diam], [ball_arc], [internal=], ...) [ATTACHMENTS];
// Description:
//   Constructs a ball screw rod.  This type of rod is used with ball bearings.  
// Arguments:
//   d = Outer diameter of threaded rod.
//   l = length of threaded rod.
//   pitch = Thread spacing. Also, the diameter of the ball bearings used.
//   ball_diam = The diameter of the ball bearings to use with this ball screw.
//   ball_arc = The arc portion that should touch the ball bearings. Default: 120 degrees.
//   ---
//   left_handed = if true, create left-handed threads.  Default = false
//   starts = The number of lead starts.  Default = 1
//   bevel = if true, bevel the thread ends.  Default: false
//   bevel1 = if true bevel the bottom end.
//   bevel2 = if true bevel the top end. 
//   internal = If true, make this a mask for making internal threads.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   $slop = The printer-specific slop value, which adds clearance (`4*$slop`) to internal threads.
// Example(2D): Thread Profile, ball_diam=4, ball_arc=100
//   projection(cut=true) ball_screw_rod(d=10, l=15, pitch=5, ball_diam=4, ball_arc=100, orient=BACK, $fn=24);
// Example(2D): Thread Profile, ball_diam=4, ball_arc=120
//   projection(cut=true) ball_screw_rod(d=10, l=15, pitch=5, ball_diam=4, ball_arc=120, orient=BACK, $fn=24);
// Example(2D): Thread Profile, ball_diam=3, ball_arc=120
//   projection(cut=true) ball_screw_rod(d=10, l=15, pitch=5, ball_diam=3, ball_arc=120, orient=BACK, $fn=24);
// Examples(Med):
//   ball_screw_rod(d=15, l=20, pitch=8, ball_diam=5, ball_arc=120, $fa=1, $fs=0.5);
//   ball_screw_rod(d=15, l=20, pitch=5, ball_diam=4, ball_arc=120, $fa=1, $fs=0.5);
//   ball_screw_rod(d=15, l=20, pitch=5, ball_diam=4, ball_arc=120, left_handed=true, $fa=1, $fs=0.5);
function ball_screw_rod(
    d, l, pitch, 
    ball_diam=5, ball_arc=100,
    starts=1,
    left_handed=false,
    internal=false,
    bevel,bevel1,bevel2,
    anchor, spin, orient
) = no_function("ball_screw_rod");
module ball_screw_rod(
    d, l, pitch, 
    ball_diam=5, ball_arc=100,
    starts=1,
    left_handed=false,
    internal=false,
    bevel,bevel1,bevel2,
    anchor, spin, orient
) {
    n = max(3,ceil(segs(ball_diam/2)*ball_arc/2/360));
    depth = ball_diam * (1-cos(ball_arc/2))/2;
    cpy = ball_diam/2/pitch*cos(ball_arc/2);
    profile = [
        each arc(n=n, d=ball_diam/pitch, cp=[-0.5,cpy], start=270, angle=ball_arc/2),
        each arc(n=n, d=ball_diam/pitch, cp=[+0.5,cpy], start=270-ball_arc/2, angle=ball_arc/2)
    ];
    generic_threaded_rod(
        d=d, l=l, pitch=pitch,
        profile=profile,
        left_handed=left_handed,
        starts=starts,
        bevel=bevel,bevel1=bevel1,bevel2=bevel2,
        internal=internal,
        higbee=0,
        anchor=anchor,
        spin=spin,
        orient=orient
    ) children();
}



// Section: Generic Threading

// Module: generic_threaded_rod()
// Usage:
//   generic_threaded_rod(d, l, pitch, profile, [internal=], ...) [ATTACHMENTS];
// Description:
//   Constructs a generic threaded rod using an arbitrary thread profile that you supply.  The rod can be tapered (e.g. for pipe threads).
//   For specific thread types use other modules that supply the appropriate profile.
//   .
//   You give the profile as a 2D path that will be scaled by the pitch to produce the final thread shape.  The profile X values
//   must be between -1/2 and 1/2.  The Y=0 point will align with the specified rod diameter, so generally you want a Y value of zero at the peak (which
//   makes your specified diameter the outer diameter of the threads).  
//   The value in the valleys of the thread should then be `-depth/pitch` due to the scaling by the thread pitch.  The segment between the end
//   of one thread and the start of the next is added automatically, so you should not have the path start and end at equivalent points (X = ±1/2 with the same Y value).
//   Generally you should center the profile horizontally in the interval [-1/2, 1/2].
//   .
//   If internal is true then produce a thread mask to difference from an object.
//   When internal is true the rod diameter is enlarged to correct for the polygonal nature of circles to ensure that the internal diameter is the specified size.
//   The diameter is also increased by `4 * $slop` to create clearance for threading by allowing a `2 * $slop` gap on each side. 
//   If bevel is set to true and internal is false then the ends of the rod will be beveled.  When bevel is true and internal is true the ends of the rod will
//   be filled in so that the rod mask will create a bevel when subtracted from an object.  The bevel is at 45 deg and is the depth of the threads.
//   .
//   Higbee specifies tapering of the thread ends to make screws easier to start.  Specify the number of degrees for the taper.  Higbee
//   only works for external threads.  It is ignored if internal is true.
// Arguments:
//   d = Outer diameter of threaded rod.
//   l = Length of threaded rod.
//   pitch = Thread spacing.
//   profile = A 2D path giving the shape of a thread
//   ---
//   left_handed = If true, create left-handed threads.  Default: false
//   starts = The number of lead starts.  Default: 1
//   bevel = if true, bevel the thread ends.  Default: false
//   bevel1 = if true bevel the bottom end.
//   bevel2 = if true bevel the top end. 
//   internal = If true, make this a mask for making internal threads.  Default: false
//   d1 = Bottom outside diameter of threads.
//   d2 = Top outside diameter of threads.
//   higbee = Angle to taper thread ends over.  Default: 0 (No higbee thread tapering)
//   higbee1 = Angle to taper bottom thread end over.
//   higbee2 = Angle to taper top thread end over.
//   center = If given, overrides `anchor`.  A true value sets `anchor=CENTER`, false sets `anchor=UP`.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   $slop = The printer-specific slop value, which adds clearance (`4*$slop`) to internal threads.
// Example(2DMed): Example Tooth Profile
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
// Example:
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
//   generic_threaded_rod(d=10, l=40, pitch=2, profile=profile);
function generic_threaded_rod(
    d, l, pitch, profile,
    left_handed=false,
    bevel,
    bevel1, bevel2, 
    starts=1,
    internal=false,
    d1, d2,
    higbee, higbee1, higbee2,
    center, anchor, spin, orient
) = no_function("generic_threaded_rod");
module generic_threaded_rod(
    d, l, pitch, profile,
    left_handed=false,
    bevel,
    bevel1, bevel2, 
    starts=1,
    internal=false,
    d1, d2,
    higbee, higbee1, higbee2,
    center, anchor, spin, orient
) {
    dummy0 = 
      assert(all_positive(pitch))
      assert(all_positive(l))
      assert(is_path(profile))
      assert(is_bool(left_handed));
    bevel1 = first_defined([bevel1,bevel,false]);
    bevel2 = first_defined([bevel2,bevel,false]);
    r1 = get_radius(d1=d1, d=d);
    r2 = get_radius(d1=d2, d=d);
    sides = quantup(segs(max(r1,r2)), starts);
    rsc = internal? (1/cos(180/sides)) : 1;
    islop = internal? 2*get_slop() : 0;
    _r1 = r1 * rsc + islop;
    _r2 = r2 * rsc + islop;
    threads = quantup(l/pitch+2,1); // Was quantup(1/pitch+2,2*starts);
    dir = left_handed? -1 : 1;
    twist = 360 * l / pitch / starts;
    higang1 = first_defined([higbee1, higbee, 0]);
    higang2 = first_defined([higbee2, higbee, 0]);
    assert(higang1 < twist/2);
    assert(higang2 < twist/2);
    prof3d = path3d(profile);
    pdepth = -min(column(profile,1));
    pmax = pitch * max(column(profile,1));
    rmax = max(_r1,_r2)+pmax;
    depth = pdepth * pitch;
    dummy1 = assert(_r1>depth && _r2>depth, "Screw profile deeper than rod radius");
    map_threads = right((_r1 + _r2) / 2)                   // Shift profile out to thread radius
                * affine3d_skew(sxz=(_r2-_r1)/l)           // Skew correction for tapered threads
                * frame_map(x=[0,0,1], y=[1,0,0])          // Map profile to 3d, parallel to z axis
                * scale(pitch);                            // scale profile by pitch
    hig_table = [
        [-twist/2-0.0001, 0],
        [-twist/2+higang1, 1],
        [ twist/2-higang2, 1],
        [ twist/2+0.0001, 0],
    ];
    start_steps = sides / starts;
    thread_verts = [
         // Outer loop constructs a vertical column of the screw at each angle
         // covering 1/starts * 360 degrees of the cylinder.  
         for (step = [0:1:start_steps]) let(
             ang = 360 * step/sides,
             dz = step / start_steps,    // z offset for threads at this angle
             rot_prof = zrot(ang*dir)*map_threads,   // Rotate profile to correct angular location
             full_profile =  [   // profile for the entire rod
                 for (thread = [-threads/2:1:threads/2-1]) let(
                     tang = (thread/starts) * 360 + ang,
                     hsc = internal? 1
                         : (higang1==0 && tang<=0)? 1
                         : (higang2==0 && tang>=0)? 1
                         : lookup(tang, hig_table),
                     higscale = yscale(hsc,cp = -pdepth)  // Scale for higbee
                 )
                 // The right movement finds the position of the thread along
                 // what will be the z axis after the profile is mapped to 3d                                           
                 each apply(right(dz + thread) * higscale, prof3d)
             ]
         ) [
             [0, 0, -l/2-pitch],
             each apply(rot_prof , full_profile),
             [0, 0, +l/2+pitch]
         ]
    ];

    style = higang1>0 || higang2>0 ? "quincunx" : "min_edge";
    
    thread_vnfs = vnf_join([
        // Main thread faces
        for (i=[0:1:starts-1])
            zrot(i*360/starts, p=vnf_vertex_array(thread_verts, reverse=left_handed, style=style)),
        // Top closing face(s) of thread                                 
        for (i=[0:1:starts-1]) let(
            rmat = zrot(i*360/starts),
            pts = deduplicate(list_head(thread_verts[0], len(prof3d)+1)),
            faces = [for (i=idx(pts,e=-2)) left_handed ? [0, i, i+1] : [0, i+1, i]]
        ) [apply(rmat,pts), faces],
        // Bottom closing face(s) of thread                                 
        for (i=[0:1:starts-1]) let(
            rmat = zrot(i*360/starts),
            pts = deduplicate(list_tail(last(thread_verts), -len(prof3d)-2)),
            faces = [for (i=idx(pts,e=-2)) left_handed ? [len(pts)-1, i+1, i] : [len(pts)-1, i, i+1]]
        ) [apply(rmat,pts), faces]
    ]);

    slope = (_r1-_r2)/l;
    maxlen = 2*pitch;

    anchor = get_anchor(anchor, center, BOT, CENTER);
    attachable(anchor,spin,orient, r1=_r1, r2=_r2, l=l) {
        union(){

          // This method is faster but more complex code and it produces green tops
          difference() {
              vnf_polyhedron(vnf_quantize(thread_vnfs),convexity=10);

              if (!internal){
                  if (bevel1 || bevel2)
                      rotate_extrude(){
                         if (bevel2) polygon([[             0, l/2],
                                              [_r2+pmax-depth, l/2],
                                              [_r2+pmax+slope*depth, l/2-depth],
                                              [              rmax+1, l/2-depth],
                                              [rmax+1, l/2+maxlen],
                                              [     0, l/2+maxlen]]);
                         if (bevel1) polygon([[             0,-l/2],
                                              [_r1+pmax-depth, -l/2],
                                              [_r1+pmax-slope*depth, -l/2+depth],
                                              [              rmax+1, -l/2+depth],
                                              [rmax+1, -l/2-maxlen],
                                              [     0, -l/2-maxlen]]);
                      }
              }
              if (!bevel1 || internal)
                  down(l/2) cuboid([2*rmax+1,2*rmax+1, maxlen], anchor=TOP);                     
              if (!bevel2 || internal)
                  up(l/2) cuboid([2*rmax+1,2*rmax+1, maxlen], anchor=BOTTOM);
          }

/*          intersection(){
              //vnf_validate(vnf_quantize(thread_vnfs), size=0.1);
              vnf_polyhedron(vnf_quantize(thread_vnfs), convexity=10);
              cyl(l=l, r1=_r1+pmax, r2=_r2+pmax, chamfer1=bevel1?depth:undef, chamfer2=bevel2?depth:undef);                  
          }*/

          // Add bevel for internal thread mask
          if (internal) {
            if (bevel1)
              down(l/2+.001)cyl(l=depth, r1=_r1+pmax, r2=_r1+pmax-slope*depth-depth,anchor=BOTTOM);
            if (bevel2)
              up(l/2+.001)cyl(l=depth, r2=_r2+pmax, r1=_r2+pmax+slope*depth-depth,anchor=TOP);
          }
        }
        children();
    }
}



// Module: generic_threaded_nut()
// Usage:
//   generic_threaded_nut(od, id, h, pitch, profile, ...) [ATTACHMENTS];
// Description:
//   Constructs a hexagonal nut for an generic threaded rod using a user-supplied thread profile.
//   See generic_threaded_rod for details on the profile specification.  
// Arguments:
//   od = diameter of the nut.
//   id = diameter of threaded rod to screw onto.
//   h = height/thickness of nut.
//   pitch = Thread spacing.
//   profile = Thread profile.
//   ---
//   left_handed = if true, create left-handed threads.  Default = false
//   starts = The number of lead starts.  Default = 1
//   bevel = if true, bevel the thread ends.  Default: false
//   bevel1 = if true bevel the bottom end.
//   bevel2 = if true bevel the top end.
//   id1 = inner diameter at the bottom
//   id2 = inner diameter at the top
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   $slop = The printer-specific slop value, which adds clearance (`4*$slop`) to internal threads.
function generic_threaded_nut(
    od,
    id,
    h,
    pitch,
    profile,
    left_handed=false,
    starts=1,
    bevel,bevel1,bevel2,
    id1,id2,
    anchor, spin, orient
) = no_function("generic_threaded_nut");
module generic_threaded_nut(
    od,
    id,
    h,
    pitch,
    profile,
    left_handed=false,
    starts=1,
    bevel,bevel1,bevel2,
    id1,id2,
    anchor, spin, orient
) {
    extra = 0.01;
    id1 = first_defined([id1,id]);
    id2 = first_defined([id2,id]);
    assert(is_def(id1) && is_def(id2), "Must specify inner diameter of nut");
    slope = (id2-id1)/h;
    full_id1 = id1-slope*extra/2;
    full_id2 = id2+slope*extra/2;
    bevel1 = first_defined([bevel1,bevel,false]);
    bevel2 = first_defined([bevel2,bevel,false]);
    dummy1 = assert(is_num(pitch) && pitch>0);
    depth = -pitch*min(column(profile,1));
    attachable(anchor,spin,orient, size=[od/cos(30),od,h]) {
        difference() {
            cyl(d=od/cos(30), h=h, center=true, $fn=6,chamfer1=bevel1?depth:undef,chamfer2=bevel2?depth:undef);
            generic_threaded_rod(
                d1=full_id1,d2=full_id2,
                l=h+extra,
                pitch=pitch,
                profile=profile,
                left_handed=left_handed,
                starts=starts,
                internal=true,
                bevel1=bevel1,bevel2=bevel2
            );
        }
        children();
    }
}


// Module: thread_helix()
// Usage:
//   thread_helix(d, pitch, [thread_depth], [flank_angle], [twist], [profile=], [left_handed=], [higbee=], [internal=]);
// Description:
//   Creates a right-handed helical thread with optional end tapering.  Unlike generic_threaded_rod, this module just generates the thread, and
//   you specify the angle of thread you want, which makes it easy to put complete threads onto a longer shaft.  It also makes a more finely
//   divided taper at the thread ends.  However, it takes about twice as long to render compared to generic_threaded_rod.
//   .
//   You can specify a thread_depth and flank_angle, in which
//   case you get a symmetric trapezoidal thread, whose inner diameter (the base of the threads for external threading)
//   is d (so the total diameter will be d + thread_depth).  This differs from the threaded_rod modules, where the specified
//   diameter is the outer diameter.  
//   Alternatively you can give a profile, following the same rules as for general_threaded_rod.
//   The Y=0 point will align with the specified diameter, and the profile should 
//   range in X from -1/2 to 1/2.  You cannot specify both the profile and the thread_depth or flank_angle.  
//   .
//   Unlike generic_threaded_rod, when internal=true this module generates the threads, not a thread mask.
//   The profile needs to be inverted to produce the proper thread form.  If you use the built-in trapezoidal
//   thread you get the inverted thread, designed so that the inner diameter is d.  With adequate clearance
//   this thread will mate with the thread that uses the same parameters but has internal=false.  Note that
//   unlike the threaded_rod modules, thread_helix does not adjust the diameter for faceting, nor does it
//   subtract any $slop for clearance.  
//   .
//   Higbee specifies tapering applied to the ends of the threads and is given as the linear distance
//   over which to taper.  Tapering works on both internal and external threads.  
// Arguments:
//   d = Inside base diameter of threads.  Default: 10
//   pitch = Distance between threads.  Default: 2mm/thread
//   thread_depth = Depth of threads from top to bottom.
//   flank_angle = Angle of thread faces to plane perpendicular to screw.  Default: 15 degrees.
//   turns = Number of revolutions to rotate thread around.  Default: 2.
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
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
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
// Figure(2D,Med):
//   pa_delta = tan(15)/4;
//      rr1 = -1/2;
//      z1 = 1/4-pa_delta;
//      z2 = 1/4+pa_delta;
//      profile = [
//                  [-z2, rr1],
//                  [-z1,  0],
//                  [ z1,  0],
//                  [ z2, rr1],
//                ];
//      fullprofile = 50*left(1/2,p=concat(profile, right(1, p=profile)));
//      stroke(fullprofile,width=1);
//      dir = fullprofile[2]-fullprofile[3];
//      dir2 = fullprofile[5]-fullprofile[4];
//      curve = arc(15,angle=[75,87],r=40 /*67.5*/);
//      avgpt = mean([fullprofile[5]+.1*dir2, fullprofile[5]+.4*dir2]);
//      color("red"){
//       stroke([fullprofile[4]+[0,1], fullprofile[4]+[0,37]], width=1);
//       stroke([fullprofile[5]+.1*dir2, fullprofile[5]+.4*dir2], width=1);
//       stroke(move(-curve[0]+avgpt,p=curve), width=0.71,endcaps="arrow2");
//       right(14)back(19)text("flank",size=4,halign="center");
//       right(14)back(14)text("angle",size=4,halign="center");
//      }
// Examples:
//   thread_helix(d=10, pitch=2, thread_depth=0.75, flank_angle=15, turns=2.5, $fn=72);
//   thread_helix(d=10, pitch=2, thread_depth=0.75, flank_angle=15, turns=2.5, higbee=1, $fn=72);
//   thread_helix(d=10, pitch=2, thread_depth=0.75, flank_angle=15, turns=2, higbee=2, internal=true, $fn=72);
//   thread_helix(d=10, pitch=2, thread_depth=0.75, flank_angle=15, turns=1, left_handed=true, higbee=1, $fn=36);
function thread_helix(
    d, pitch, thread_depth, flank_angle, turns=2,
    profile, starts=1, left_handed=false, internal=false,
    d1, d2, higbee, higbee1, higbee2,
    anchor, spin, orient
) = no_function("thread_helix");
module thread_helix(
    d, pitch, thread_depth, flank_angle, turns=2,
    profile, starts=1, left_handed=false, internal=false,
    d1, d2, higbee, higbee1, higbee2,
    anchor, spin, orient
) {
    dummy1=assert(is_undef(profile) || !any_defined([thread_depth, flank_angle]),"Cannot give thread_depth or flank_angle with a profile");
    h = pitch*starts*turns;
    r1 = get_radius(d1=d1, d=d, dflt=10);
    r2 = get_radius(d1=d2, d=d, dflt=10);
    profile = is_def(profile) ? profile :
        let(
            tdp = thread_depth / pitch,
            dz = tdp * tan(flank_angle),
            cap = (1 - 2*dz)/2
        )
        internal?
          [
            [-cap/2-dz, tdp],
            [-cap/2,    0  ],
            [+cap/2,    0  ],
            [+cap/2+dz, tdp],
          ]
        :
          [
            [+cap/2+dz, 0  ],
            [+cap/2,    tdp],
            [-cap/2,    tdp],
            [-cap/2-dz, 0  ],
          ];
    pline = mirror([-1,1],  p = profile * pitch);
    dir = left_handed? -1 : 1;
    attachable(anchor,spin,orient, r1=r1, r2=r2, l=h) {
        zrot_copies(n=starts) {
            spiral_sweep(pline, h=h, r1=r1, r2=r2, turns=turns*dir, higbee=higbee, higbee1=higbee1, higbee2=higbee2, internal=internal, anchor=CENTER);
        }
        children();
    }
}



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap

// Changes
//   internal: can set bevel to true and get non-garbage result
//   bevel is always set by thread depth
//   acme takes tpi
//   square threads are at angle 0
//   added generic_threaded_{rod,nut}
//   eliminated metric_trapezoidal_*
//   cleaned up matrices some in generic_threaded_rod
//   threaded_rod can produce spec-true ISO/UTS profile with a triplet input for the diameter.
//   Added bevel1 and bevel2 to all modules.  Made default uniformly false for every case instead of
//       sometimes true, sometimes false
//   Profiles that go over zero are not clipped, and bevels are based on actual profile top, not nominal
//   When bevel is given to nuts it bevels the outside of the nut by thread depth
//   higbee looks best with quincunx, but it's more expensive.  Select quincunx when higbee is used, min_edge otherwise
//   Current code uses difference to remove excess length in the rod.  This gives faster renders at the cost
//      of more complex code and green top/bottom surfaces.
//   Changed slop to 4 * $slop.  I got good results printing with $slop=0.05 with this setting.
//   Don't generate excess threads when starts>1, and don't force threads to be even
//
//   Fixed higbee in spiral_sweep for properly centered scaling and for staying on the internal/external base of threads
//   Fixed bug in spiral_sweep where two segments were missing if higbee is zero
//   Fixed faceting bugs in spiral_sweep where segments weren't aligned with requested number of segments, and higbee
//      would pull away from the cylinder by using a higher count and following a true circle
//
// Questions
//   Should nut modules take d1/d2 for tapered nuts?
//
// Need explanation of what exactly the diff is between threaded_rod and helix_threads.
// Higbee is different, angle in one and length in another.  Need to reconcile
