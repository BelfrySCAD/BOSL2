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


// Section: Thread Ends and Options
//   A standard process for making machine screws is to begin with round stock that has
//   beveled ends.  This stock is then rolled between flat, grooved plates to form the threads.
//   The result is a bolt that looks like this at the end:
// Figure(3D,Med,NoAxes,VPR=[83.7,0,115.5],VPT=[1.37344,1.26411,-0.299415],VPD=35.5861): 
//   threaded_rod(d=13,pitch=2,l=10,blunt_start=false,$fn=80);
// Figure(2D,Med,NoAxes): A properly mated screw and bolt with beveled ends
//   $fn=32;
//   projection(cut=true)
//   xrot(-90){
//   down(2.5)difference(){
//     cuboid([20,20,5]);
//     zrot(20)
//     threaded_rod(d=13.2, pitch=2,l=5.1,blunt_start=false,internal=true);
//   }
//   up(2.85-2)threaded_rod(d=13, pitch=2, l=10, blunt_start=false);
//   
//   }
// Continues:
//   Cross threading occurs when the bolt is misaligned with the threads in the nut.
//   It can destroy the threads, or cause the nut to jam.  The standard beveled end process
//   makes cross threading a possibility because the beveled partial threads can pass
//   each other when the screw enters the nut.
// Figure(2D,Med,NoAxes):
//   $fn=32;
//   projection(cut=true)
//   xrot(-90){
//   down(2.5)difference(){
//     cuboid([20,20,5]);
//     zrot(20)
//     threaded_rod(d=13.2, pitch=2,l=5.1,blunt_start=false,internal=true);
//   }
//   left(.6)up(2.99)yrot(-atan(2/13)-1)rot(180+30)threaded_rod(d=13, pitch=2, l=10, blunt_start=false);
//   }
// Continues:
//   In addition, those partial screw threads may be weak, and easily broken.  They do
//   not contribute to the strength of the assembly.  
//   In 1891 Clinton A. Higbee received a patent for a modification to screw threads
//   https://patents.google.com/patent/US447775A meant to address these limitations.
//   Instead of beveling the end of the screw, Higbee said to remove the partial thread.
//   The resulting screw might look like this:
// Figure(3D,Med,NoAxes,VPR=[72,0,294],VPT=[0,0,0],VPD=44):
//   $fn=48;
//   threaded_rod(d=13,pitch=2,l=10,blunt_start=true,lead_in_shape="cut",end_len=.2);
// Continues:
//   Because the threads are complete everywhere, cross threading is unlikely to occur.
//   This type of threading has been called "Higbee threads", but in recent machinist
//   handbooks it is called "blunt start" threading.  
//   This style of thread is not commonly used in metal fasteners because it requires
//   machining the threads, which is much more costly than the rolling procedure described
//   above.  However, plastic threads usually have some sort of gradual thread end.
//   For models that will be 3D printed, there is no reason to choose the standard
//   bevel end bolt, so in this library the blunt start threads are the default.
//   If you need standard bevel-end threads, you can choose them with the `blunt_start` options.
//   Note that blunt start threads are more efficient.
//   .
//   Various options exist for controlling the ends of threads. You can specify bevels on threaded rods.
//   In conventional threading, bevels are needed on the ends to remove sharp, thin edges, and
//   the bevel is sized to the full outer diameter of the threaded rod.  
//   With blunt start threading, the bevel appears on the unthreaded part of the rod.
//   On a threaded rod, a bevel value of `true` or a positive bevel value cut off the corner.
// Figure(3D,Med,NoAxes,VPR=[72,0,54],VPT=[0,0,0],VPD=44):
//   threaded_rod(d=13,pitch=2,l=10,blunt_start=true,bevel=true,$fn=80);
// Continues:
//   A negative bevel value produces a flaring bevel, that might be useful if the rod needs to mate with another part.
//   You can also set `bevel="reverse"` to get a flaring bevel of the default size.
// Figure(3D,Med,NoAxes,VPR=[72,0,54],VPT=[0,0,0],VPD=44): Negative bevel on a regular threaded rod.
//   threaded_rod(d=13,pitch=2,l=10,blunt_start=true,bevel=-2,$fn=80);
// Continues:
//   If you set `internal=true` to create a mask for a threaded hole, then bevels are reversed: positive bevels flare outward so that when you subtract
//   the threaded rod it gives a beveled edge to the hole.  In this case, negative bevels go inward, which might be useful to
//   create a bevel at the bottom of a threaded hole.
// Figure(3D,Med,NoAxes,VPR=[72,0,54],VPT=[0,0,0],VPD=44): Threaded rod mask produced using `internal=true` with regular bevel at the top and reversed bevel at the bottom.  
//   threaded_rod(d=13,pitch=2,l=10,blunt_start=true,bevel2=true,bevel1="reverse",internal=true,$fn=80);
// Continues:
//   You can also extend the unthreaded section using the `end_len` parameters.  A long unthreaded section will make
//   it impossible to tilt the bolt and produce misaligned threads, so it could make assembly easier.  
// Figure(3D,Med,NoAxes,VPR=[72,0,54],VPT=[0,0,0],VPD=48): Negative bevel on a regular threaded rod.
//   threaded_rod(d=13,pitch=2,l=15,end_len2=5,blunt_start=true,bevel=true,$fn=80);
// Continues:
//   It is also possible to adjust the length of the lead-in section of threads, or the
//   shape of that lead-in section.  The lead-in length can be set using the `lead_in` arguments
//   to specify a length or the `lead_in_ang` arguments to specify an angle.  For general
//   threading applications, making the lead in long creates a smaller thread that could
//   be more fragile and more prone to cross threading.  
// Figure(3D,Med,NoAxes,VPR=[52,0,300],VPT=[0,0,4],VPD=35.5861):
//   threaded_rod(d=13,pitch=2,l=10,lead_in=6,blunt_start=true,bevel=false,$fn=80);
// Continues:
//   To change the form of the thread end you use the `lead_in_shape` argument.
//   You can specify "sqrt", "cut" or "smooth" shapes.  The "sqrt" shape is the historical
//   shape used in the library.  The "cut" shape is available to model Higbee pattern threads, but
//   is not as good as the others in practice, because the flat faces on the threads can hit each other.
//   The lead-in shape is produced by applying a scale factor to the thread cross section that varies along the lead-in length. 
//   You can also specify a custom shape
//   by giving a function literal, `f(x,L)` where `L` will be the total linear
//   length of the lead-in section and `x` will be a value between 0 and 1 giving
//   the position in the lead in, with 0 being the tip and 1 being the full height thread.
//   The return value must be a 2-vector giving the thread width scale and thread height
//   scale at that location.  If `x<0` the function must return a thread height scale
//   of zero, but it is usually best if the thread width scale does not go to zero,
//   because that will give a sharply pointed thread end.  If `x>1` the function must
//   return `[1,1]`.  
// Figure(3D,Med,NoAxes,VPR=[75,0,338],VPT=[-2,0,3.3],VPD=25): The standard lead in shapes
//   left_half()zrot(0){
//   up(2)   threaded_rod(d=13,pitch=2,l=2,blunt_start=true,bevel=false,$fn=128,anchor=BOT);
//   up(4)   threaded_rod(d=13,pitch=2,l=2.5,blunt_start=true,bevel=false,$fn=128,lead_in_shape="cut",end_len2=.5,anchor=BOT);
//      threaded_rod(d=13,pitch=2,l=2,blunt_start=true,bevel=false,$fn=128,lead_in_shape="smooth",anchor=BOT);
//   }
//   $fn=64;
//   s=.85;
//   color("black")
//   up(3.5)left(4.5)fwd(6)rot($vpr){
//      back(1.9)text3d("cut",size=s);
//      text3d("sqrt",size=s);
//      fwd(1.9)text3d("smooth",size=s);
//   }   


// Section: Standard (UTS/ISO) Threading

// Module: threaded_rod()
// Synopsis: Creates an UTS/ISO triangular threaded rod.
// SynTags: Geom
// Topics: Threading, Screws
// See Also: threaded_nut()
// Usage:
//   threaded_rod(d, l|length, pitch, [internal=], ...) [ATTACHMENTS];
// Description:
//   Constructs a standard ISO (metric) or UTS (English) threaded rod.  These threads are close to triangular,
//   with a 60 degree thread angle.  You can give diameter value which specifies the outer diameter and will produce
//   the "basic form" or you can
//   set d to a triplet [d_min, d_pitch, d_major] where are parameters determined by the ISO and UTS specifications
//   that define clearance sizing for the threading.  See screws.scad for how to make screws
//   using the specification parameters.  
// Arguments:
//   d = Outer diameter of threaded rod, or a triplet of [d_min, d_pitch, d_major]. 
//   l / length / h / height = length of threaded rod.
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
//   blunt_start = If true apply truncated blunt start threads at both ends.  Default: true
//   blunt_start1 = If true apply truncated blunt start threads bottom end.
//   blunt_start2 = If true apply truncated blunt start threads top end.
//   end_len = Specify the unthreaded length at the end after blunt start threads.  Default: 0
//   end_len1 = Specify unthreaded length at the bottom
//   end_len2 = Specify unthreaded length at the top
//   lead_in = Specify linear length of the lead in section of the threading with blunt start threads
//   lead_in1 = Specify linear length of the lead in section of the threading at the bottom with blunt start threads
//   lead_in2 = Specify linear length of the lead in section of the threading at the top with blunt start threads
//   lead_in_ang = Specify angular length in degrees of the lead in section of the threading with blunt start threads
//   lead_in_ang1 = Specify angular length in degrees of the lead in section of the threading at the bottom with blunt start threads
//   lead_in_ang2 = Specify angular length in degrees of the lead in section of the threading at the top with blunt start threads
//   lead_in_shape = Specify the shape of the thread lead in by giving a text string or function.  Default: "default"
//   teardrop = If true, adds a teardrop profile to the back (Y+) side of the threaded rod, for 3d printability of horizontal holes. If numeric, specifies the proportional extra distance of the teardrop flat top from the screw center, or set to "max" for a pointed teardrop. Default: false
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   $slop = The printer-specific slop value, which adds clearance (`4*$slop`) to internal threads.
// Example(2D):
//   projection(cut=true)
//       threaded_rod(d=10, l=15, pitch=1.5, orient=BACK);
// Examples(Med):
//   threaded_rod(d=25, height=20, pitch=2, $fa=1, $fs=1);
//   threaded_rod(d=10, l=20, pitch=1.25, left_handed=true, $fa=1, $fs=1);
//   threaded_rod(d=25, l=20, pitch=2, $fa=1, $fs=1, end_len=1.5, bevel=true);
//   threaded_rod(d=25, l=20, pitch=2, $fa=1, $fs=1, blunt_start=false);
// Example(Med;VPR=[100,0,5];VPD=220): Masking a Horizontal Threaded Hole
//   difference() {
//     cuboid(50);
//     threaded_rod(
//         d=25, l=51, pitch=4, $fn=36,
//         internal=true, bevel=true,
//         blunt_start=false,
//         teardrop=true, orient=FWD
//     );
//   }
// Example(Big,NoAxes): Diamond threading where both left-handed and right-handed nuts travel (in the same direction) on the threaded rod:
//   $fn=32;
//   $slop = 0.075;
//   d = 3/8*INCH;
//   pitch = 1/16*INCH;
//   starts=3;
//   xdistribute(19){
//       intersection(){
//         threaded_rod(l=40, pitch=pitch, d=d,starts=starts,anchor=BOTTOM,end_len=.44);
//         threaded_rod(l=40, pitch=pitch, d=d, left_handed=true,starts=starts,anchor=BOTTOM);
//       }
//       threaded_nut(nutwidth=4.5/8*INCH,id=d,h=3/8*INCH,pitch=pitch,starts=starts,anchor=BOTTOM);
//       threaded_nut(nutwidth=4.5/8*INCH,id=d,h=3/8*INCH,pitch=pitch,starts=starts,left_handed=true,anchor=BOTTOM);
//   }
function threaded_rod(
    d, l, pitch,
    left_handed=false,
    bevel,bevel1,bevel2,starts=1,
    internal=false,
    d1, d2, length, h, height,
    blunt_start, blunt_start1, blunt_start2,
    lead_in, lead_in1, lead_in2,
    lead_in_ang, lead_in_ang1, lead_in_ang2,
    end_len, end_len1, end_len2,
    lead_in_shape="default",
    teardrop=false,
    anchor, spin, orient
) = no_function("threaded_rod");

module threaded_rod(
    d, l, pitch,
    left_handed=false,
    bevel,bevel1,bevel2,starts=1,
    internal=false,
    d1, d2, length, h, height,
    blunt_start, blunt_start1, blunt_start2,
    lead_in, lead_in1, lead_in2,
    lead_in_ang, lead_in_ang1, lead_in_ang2,
    end_len, end_len1, end_len2,
    lead_in_shape="default",
    teardrop=false,
    anchor, spin, orient
) {
    dummy1=
      assert(all_positive(pitch))
      assert(all_positive(d) || (is_undef(d) && all_positive([d1,d2])));
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
        internal=internal, length=length, height=height, h=h,
        blunt_start=blunt_start, blunt_start1=blunt_start1, blunt_start2=blunt_start2,
        lead_in=lead_in, lead_in1=lead_in1, lead_in2=lead_in2, lead_in_shape=lead_in_shape,
        lead_in_ang=lead_in_ang, lead_in_ang1=lead_in_ang1, lead_in_ang2=lead_in_ang2,
        end_len=end_len, end_len1=end_len1, end_len2=end_len2,
        teardrop=teardrop,
        anchor=anchor,
        spin=spin,
        orient=orient
    ) children();
}



// Module: threaded_nut()
// Synopsis: Creates an UTS/ISO triangular threaded nut.
// SynTags: Geom
// Topics: Threading, Screws
// See Also: threaded_rod()
// Usage:
//   threaded_nut(nutwidth, id, h|height|thickness, pitch,...) [ATTACHMENTS];
// Description:
//   Constructs a hex nut or square nut for an ISO (metric) or UTS (English) threaded rod.
//   The inner diameter is measured from the bottom of the threads.  
// Arguments:
//   nutwidth = flat to flat width of nut
//   id = inner diameter of threaded hole, measured from bottom of threads
//   h / height / l / length / thickness = height/thickness of nut.
//   pitch = Distance between threads, or zero for no threads. 
//   ---
//   shape = specifies shape of nut, either "hex" or "square".  Default: "hex"
//   left_handed = if true, create left-handed threads.  Default = false
//   starts = The number of lead starts.  Default: 1
//   bevel = if true, bevel the outside of the nut.  Default: true for hex nuts, false for square nuts
//   bevel1 = if true, bevel the outside of the nut bottom.
//   bevel2 = if true, bevel the outside of the nut top. 
//   bevang = set the angle for the outside nut bevel.  Default: 30
//   ibevel = if true, bevel the inside (the hole).   Default: true
//   ibevel1 = if true bevel the inside, bottom end.
//   ibevel2 = if true bevel the inside, top end.
//   blunt_start = If true apply truncated blunt start threads at both ends.  Default: true
//   blunt_start1 = If true apply truncated blunt start threads bottom end.
//   blunt_start2 = If true apply truncated blunt start threads top end.
//   end_len = Specify the unthreaded length at the end after blunt start threads.  Default: 0
//   end_len1 = Specify unthreaded length at the bottom
//   end_len2 = Specify unthreaded length at the top
//   lead_in = Specify linear length of the lead in section of the threading with blunt start threads
//   lead_in1 = Specify linear length of the lead in section of the threading at the bottom with blunt start threads
//   lead_in2 = Specify linear length of the lead in section of the threading at the top with blunt start threads
//   lead_in_ang = Specify angular length in degrees of the lead in section of the threading with blunt start threads
//   lead_in_ang1 = Specify angular length in degrees of the lead in section of the threading at the bottom with blunt start threads
//   lead_in_ang2 = Specify angular length in degrees of the lead in section of the threading at the top with blunt start threads
//   lead_in_shape = Specify the shape of the thread lead in by giving a text string or function.  Default: "default"
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   $slop = The printer-specific slop value, which adds clearance (`4*$slop`) to internal threads.
// Examples(Med):
//   threaded_nut(nutwidth=16, id=8, h=8, pitch=1.25, $slop=0.05, $fa=1, $fs=1);
//   threaded_nut(nutwidth=16, id=8, h=8, pitch=1.25, left_handed=true, bevel=false, $slop=0.1, $fa=1, $fs=1);
//   threaded_nut(shape="square", nutwidth=16, id=8, h=8, pitch=1.25, $slop=0.1, $fa=1, $fs=1);
//   threaded_nut(shape="square", nutwidth=16, id=8, h=8, pitch=1.25, bevel2=true, $slop=0.1, $fa=1, $fs=1);
//   rot(90)threaded_nut(nutwidth=16, id=8, h=8, pitch=1.25,blunt_start=false, $slop=0.1, $fa=1, $fs=1);
function threaded_nut(
    nutwidth, id, h,
    pitch, starts=1, shape="hex", left_handed=false, bevel, bevel1, bevel2, id1,id2,
    ibevel1, ibevel2, ibevel, bevang=30, thickness, height,
    length, l,
    blunt_start, blunt_start1, blunt_start2,
    lead_in, lead_in1, lead_in2,
    lead_in_ang, lead_in_ang1, lead_in_ang2,
    end_len, end_len1, end_len2,
    lead_in_shape="default",
    anchor, spin, orient
)=no_function("threaded_nut");
module threaded_nut(
    nutwidth, id, h,
    pitch, starts=1, shape="hex", left_handed=false, bevel, bevel1, bevel2, id1,id2,
    ibevel1, ibevel2, ibevel, bevang=30, thickness, height,
    length, l,
    blunt_start, blunt_start1, blunt_start2,
    lead_in, lead_in1, lead_in2,
    lead_in_ang, lead_in_ang1, lead_in_ang2,
    end_len, end_len1, end_len2,
    lead_in_shape="default",
    anchor, spin, orient
) {
    dummy1=
          assert(all_nonnegative(pitch), "Nut pitch must be nonnegative")
          assert(all_positive(id), "Nut inner diameter must be positive")
          assert(all_positive(h),"Nut thickness must be positive");
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
        nutwidth=nutwidth,
        id=basic ? id : id[2], id1=id1, id2=id2,
        h=h,
        pitch=pitch,
        profile=profile,starts=starts,shape=shape, 
        left_handed=left_handed,
        bevel=bevel,bevel1=bevel1,bevel2=bevel2,
        ibevel1=ibevel1, ibevel2=ibevel2, ibevel=ibevel,
        blunt_start=blunt_start, blunt_start1=blunt_start1, blunt_start2=blunt_start2,
        lead_in=lead_in, lead_in1=lead_in1, lead_in2=lead_in2, lead_in_shape=lead_in_shape,
        lead_in_ang=lead_in_ang, lead_in_ang1=lead_in_ang1, lead_in_ang2=lead_in_ang2,
        end_len=end_len, end_len1=end_len1, end_len2=end_len2,
        l=l,length=length,
        anchor=anchor, spin=spin,
        orient=orient
    ) children();
}

// Section: Trapezoidal Threading


// Module: trapezoidal_threaded_rod()
// Synopsis: Creates a trapezoidal threaded rod.
// SynTags: Geom
// Topics: Threading, Screws
// See Also: trapezoidal_threaded_nut()
// Usage:
//   trapezoidal_threaded_rod(d, l|length, pitch, [thread_angle=|flank_angle=], [thread_depth=], [internal=], ...) [ATTACHMENTS];
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
// Figure(2D,Med,NoAxes):
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
// Arguments:
//   d = Outer diameter of threaded rod.
//   l / length / h / height = Length of threaded rod.
//   pitch = Thread spacing. 
//   ---
//   thread_angle = Angle between two thread faces.  Default: 30
//   thread_depth = Depth of threads.  Default: pitch/2
//   flank_angle = Angle of thread faces to plane perpendicular to screw. 
//   left_handed = If true, create left-handed threads.  Default: false
//   starts = The number of lead starts.  Default: 1
//   bevel = if true, bevel the thread ends.  Default: false
//   bevel1 = if true bevel the bottom end.
//   bevel2 = if true bevel the top end. 
//   internal = If true, make this a mask for making internal threads.  Default: false
//   d1 = Bottom outside diameter of threads.
//   d2 = Top outside diameter of threads.
//   blunt_start = If true apply truncated blunt start threads at both ends.  Default: true
//   blunt_start1 = If true apply truncated blunt start threads bottom end.
//   blunt_start2 = If true apply truncated blunt start threads top end.
//   end_len = Specify the unthreaded length at the end after blunt start threads.  Default: 0
//   end_len1 = Specify unthreaded length at the bottom
//   end_len2 = Specify unthreaded length at the top
//   lead_in = Specify linear length of the lead in section of the threading with blunt start threads
//   lead_in1 = Specify linear length of the lead in section of the threading at the bottom with blunt start threads
//   lead_in2 = Specify linear length of the lead in section of the threading at the top with blunt start threads
//   lead_in_ang = Specify angular length in degrees of the lead in section of the threading with blunt start threads
//   lead_in_ang1 = Specify angular length in degrees of the lead in section of the threading at the bottom with blunt start threads
//   lead_in_ang2 = Specify angular length in degrees of the lead in section of the threading at the top with blunt start threads
//   lead_in_shape = Specify the shape of the thread lead in by giving a text string or function.  Default: "default"
//   teardrop = If true, adds a teardrop profile to the back (Y+) side of the threaded rod, for 3d printability of horizontal holes. If numeric, specifies the proportional extra distance of the teardrop flat top from the screw center, or set to "max" for a pointed teardrop. Default: false
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   $slop = The printer-specific slop value, which adds clearance (`4*$slop`) to internal threads.
// Example(2D):
//   projection(cut=true)
//       trapezoidal_threaded_rod(d=10, l=15, pitch=2, orient=BACK);
// Examples(Med): 
//   trapezoidal_threaded_rod(d=10, l=40, pitch=2, $fn=32);  // Standard metric threading
//   rot(-65)trapezoidal_threaded_rod(d=10, l=17, pitch=2, blunt_start=false, $fn=32);  // Standard metric threading
//   trapezoidal_threaded_rod(d=10, l=17, pitch=2, bevel=true, $fn=32);  // Standard metric threading
//   trapezoidal_threaded_rod(d=10, h=30, pitch=2, left_handed=true, $fa=1, $fs=1);  // Standard metric threading
//   trapezoidal_threaded_rod(d=10, l=40, pitch=3, left_handed=true, starts=3, $fn=36);
//   trapezoidal_threaded_rod(l=25, d=10, pitch=2, starts=3, $fa=1, $fs=1, bevel=true, orient=RIGHT, anchor=BOTTOM);
//   trapezoidal_threaded_rod(d=60, l=16, pitch=8, thread_depth=3, thread_angle=90, blunt_start=false, $fa=2, $fs=2);
//   trapezoidal_threaded_rod(d=60, l=16, pitch=8, thread_depth=3, thread_angle=90, end_len=0, $fa=2, $fs=2);   
//   trapezoidal_threaded_rod(d=60, l=16, pitch=8, thread_depth=3, thread_angle=90, left_handed=true, starts=4, $fa=2, $fs=2,end_len=0);
//   trapezoidal_threaded_rod(d=16, l=40, pitch=2, thread_angle=60);
//   trapezoidal_threaded_rod(d=25, l=40, pitch=10, thread_depth=8/3, thread_angle=100, starts=4, anchor=BOT, $fa=2, $fs=2,end_len=-2);
//   trapezoidal_threaded_rod(d=50, l=35, pitch=8, thread_angle=60, starts=11, lead_in=3, $fn=120);
//   trapezoidal_threaded_rod(d=10, l=40, end_len2=10, pitch=2, $fn=32);  // Unthreaded top end section
// Example(Med): Using as a Mask to Make Internal Threads
//   bottom_half() difference() {
//       cube(50, center=true);
//       trapezoidal_threaded_rod(d=40, l=51, pitch=5, thread_angle=30, internal=true, bevel=true, orient=RIGHT, $fn=36);
//   }
// Example(Med;VPR=[100,0,5];VPD=220): Masking a Horizontal Threaded Hole
//   difference() {
//     cuboid(50);
//     trapezoidal_threaded_rod(
//         d=25, l=51, pitch=4, $fn=36,
//         thread_angle=30,
//         internal=true, bevel=true,
//         blunt_start=false,
//         teardrop=true, orient=FWD
//     );
//   }
function trapezoidal_threaded_rod(
    d, l, pitch,
    thread_angle,
    thread_depth,
    flank_angle,
    left_handed=false,
    bevel,bevel1,bevel2,
    starts=1, 
    internal=false,
    d1, d2, length, h, height,
    blunt_start, blunt_start1, blunt_start2,
    lead_in, lead_in1, lead_in2,
    lead_in_ang, lead_in_ang1, lead_in_ang2,
    end_len, end_len1, end_len2,
    lead_in_shape="default",
    teardrop=false,
    anchor, spin, orient
) = no_function("trapezoidal_threaded_rod");
module trapezoidal_threaded_rod(
    d, l, pitch,
    thread_angle,
    thread_depth,
    flank_angle,
    left_handed=false,
    bevel,bevel1,bevel2,
    starts=1, 
    internal=false,
    d1, d2, length, h, height,
    blunt_start, blunt_start1, blunt_start2,
    lead_in, lead_in1, lead_in2,
    lead_in_ang, lead_in_ang1, lead_in_ang2,
    end_len, end_len1, end_len2,
    lead_in_shape="default",
    teardrop=false,
    anchor, spin, orient
) {
    dummy0 = assert(num_defined([thread_angle,flank_angle])<=1, "Cannot define both flank angle and thread angle");
    thread_angle = first_defined([thread_angle, u_mul(2,flank_angle), 30]);
    dummy1 = assert(all_nonnegative(pitch),"Must give a positive pitch value")
             assert(thread_angle>=0 && thread_angle<180, "Invalid thread angle or flank angle")
             assert(thread_angle<=90 || all_positive([thread_depth]),
                   "Thread angle (2*flank_angle) must be smaller than 90 degrees with default thread depth of pitch/2");
    depth = first_defined([thread_depth,pitch/2]);
    pa_delta = 0.5*depth*tan(thread_angle/2) / pitch;
    dummy2 = assert(pa_delta<=1/4, "Specified thread geometry is impossible");
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
                         left_handed=left_handed,bevel=bevel,bevel1=bevel1,bevel2=bevel2,starts=starts,d1=d1,d2=d2,
                         internal=internal, length=length, height=height, h=h,
                         blunt_start=blunt_start, blunt_start1=blunt_start1, blunt_start2=blunt_start2,
                         lead_in=lead_in, lead_in1=lead_in1, lead_in2=lead_in2, lead_in_shape=lead_in_shape,
                         lead_in_ang=lead_in_ang, lead_in_ang1=lead_in_ang1, lead_in_ang2=lead_in_ang2,
                         end_len=end_len, end_len1=end_len1, end_len2=end_len2,
                         teardrop=teardrop, anchor=anchor,spin=spin,orient=orient)
      children();
}


// Module: trapezoidal_threaded_nut()
// Synopsis: Creates a trapezoidal threaded nut.
// SynTags: Geom
// Topics: Threading, Screws
// See Also: trapezoidal_threaded_rod()
// Usage:
//   trapezoidal_threaded_nut(nutwidth, id, h|height|thickness, pitch, [thread_angle=|flank_angle=], [thread_depth], ...) [ATTACHMENTS];
// Description:
//   Constructs a hex nut or square nut for a symmetric trapzoidal threaded rod.  By default produces
//   the nominal dimensions for metric trapezoidal threads: a thread angle of 30 degrees and a depth
//   set to half the pitch.  You can also specify your own trapezoid parameters.  For ACME threads see
//   acme_threaded_nut().
// Arguments:
//   nutwidth = flat to flat width of nut
//   id = inner diameter of threaded hole, measured from bottom of threads
//   h / height / l / length / thickness = height/thickness of nut.
//   pitch = Thread spacing.
//   ---
//   thread_angle = Angle between two thread faces.  Default: 30
//   thread_depth = Depth of the threads.  Default: pitch/2
//   flank_angle = Angle of thread faces to plane perpendicular to screw. 
//   shape = specifies shape of nut, either "hex" or "square".  Default: "hex"
//   left_handed = if true, create left-handed threads.  Default = false
//   starts = The number of lead starts.  Default = 1
//   bevel = if true, bevel the outside of the nut.  Default: true for hex nuts, false for square nuts
//   bevel1 = if true, bevel the outside of the nut bottom.
//   bevel2 = if true, bevel the outside of the nut top. 
//   bevang = set the angle for the outside nut bevel.  Default: 30
//   ibevel = if true, bevel the inside (the hole).   Default: true
//   ibevel1 = if true bevel the inside, bottom end.
//   ibevel2 = if true bevel the inside, top end.
//   blunt_start = If true apply truncated blunt start threads at both ends.  Default: true
//   blunt_start1 = If true apply truncated blunt start threads bottom end.
//   blunt_start2 = If true apply truncated blunt start threads top end.
//   end_len = Specify the unthreaded length at the end after blunt start threads.  Default: 0
//   end_len1 = Specify unthreaded length at the bottom
//   end_len2 = Specify unthreaded length at the top
//   lead_in = Specify linear length of the lead in section of the threading with blunt start threads
//   lead_in1 = Specify linear length of the lead in section of the threading at the bottom with blunt start threads
//   lead_in2 = Specify linear length of the lead in section of the threading at the top with blunt start threads
//   lead_in_ang = Specify angular length in degrees of the lead in section of the threading with blunt start threads
//   lead_in_ang1 = Specify angular length in degrees of the lead in section of the threading at the bottom with blunt start threads
//   lead_in_ang2 = Specify angular length in degrees of the lead in section of the threading at the top with blunt start threads
//   lead_in_shape = Specify the shape of the thread lead in by giving a text string or function.  Default: "default"
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   $slop = The printer-specific slop value, which adds clearance (`4*$slop`) to internal threads.
// Examples(Med):
//   trapezoidal_threaded_nut(nutwidth=16, id=8, h=8, pitch=2, $slop=0.1, anchor=UP);
//   trapezoidal_threaded_nut(nutwidth=16, id=8, h=8, pitch=2, bevel=false, $slop=0.05, anchor=UP);
//   trapezoidal_threaded_nut(nutwidth=17.4, id=10, h=10, pitch=2, $slop=0.1, left_handed=true);
//   trapezoidal_threaded_nut(nutwidth=17.4, id=10, h=10, pitch=2, starts=3, $fa=1, $fs=1, $slop=0.15);
//   trapezoidal_threaded_nut(nutwidth=17.4, id=10, h=10, pitch=2, starts=3, $fa=1, $fs=1, $slop=0.15, blunt_start=false);
//   trapezoidal_threaded_nut(nutwidth=17.4, id=10, h=10, pitch=0, $slop=0.2);   // No threads
function trapezoidal_threaded_nut(
    nutwidth,
    id,
    h,
    pitch,
    thread_angle,
    thread_depth, shape="hex",
    flank_angle,
    left_handed=false,
    starts=1,
    bevel,bevel1,bevel2,bevang=30,
    ibevel1,ibevel2,ibevel,
    thickness,height,
    id1,id2,
    length, l,
    blunt_start, blunt_start1, blunt_start2,
    lead_in, lead_in1, lead_in2,
    lead_in_ang, lead_in_ang1, lead_in_ang2,
    end_len, end_len1, end_len2,
    lead_in_shape="default",
    anchor, spin, orient
) = no_function("trapezoidal_threaded_nut");
module trapezoidal_threaded_nut(
    nutwidth,
    id,
    h,
    pitch,
    thread_angle,
    thread_depth, shape="hex",
    flank_angle,
    left_handed=false,
    starts=1,
    bevel,bevel1,bevel2,bevang=30,
    ibevel1,ibevel2,ibevel,
    thickness,height,
    id1,id2,
    length, l,
    blunt_start, blunt_start1, blunt_start2,
    lead_in, lead_in1, lead_in2,
    lead_in_ang, lead_in_ang1, lead_in_ang2,
    end_len, end_len1, end_len2,
    lead_in_shape="default",
    anchor, spin, orient
) {
    dummy0 = assert(num_defined([thread_angle,flank_angle])<=1, "Cannot define both flank angle and thread angle");
    thread_angle = first_defined([thread_angle, u_mul(2,flank_angle), 30]);
    dummy1 = assert(all_nonnegative(pitch),"Must give a positive pitch value")
             assert(thread_angle>=0 && thread_angle<180, "Invalid thread angle or flank angle")
             assert(thread_angle<=90 || all_positive([thread_depth]),
                   "Thread angle (2*flank_angle) must be smaller than 90 degrees with default thread depth of pitch/2");
    depth = first_defined([thread_depth,pitch/2]);
    pa_delta = 0.5*depth*tan(thread_angle/2) / pitch;
    dummy2 = assert(pitch==0 || pa_delta<1/4, "Specified thread geometry is impossible");
    rr1 = -depth/pitch;
    z1 = 1/4-pa_delta;
    z2 = 1/4+pa_delta;
    profile = [
               [-z2, rr1],
               [-z1,  0],
               [ z1,  0],
               [ z2, rr1],
              ];
    generic_threaded_nut(nutwidth=nutwidth,id=id,h=h,pitch=pitch,profile=profile,id1=id1,id2=id2,
                         shape=shape,left_handed=left_handed,bevel=bevel,bevel1=bevel1,bevel2=bevel2,starts=starts,
                         ibevel=ibevel,ibevel1=ibevel1,ibevel2=ibevel2,bevang=bevang,height=height,thickness=thickness,
                         blunt_start=blunt_start, blunt_start1=blunt_start1, blunt_start2=blunt_start2,
                         lead_in=lead_in, lead_in1=lead_in1, lead_in2=lead_in2, lead_in_shape=lead_in_shape,
                         lead_in_ang=lead_in_ang, lead_in_ang1=lead_in_ang1, lead_in_ang2=lead_in_ang2,
                         end_len=end_len, end_len1=end_len1, end_len2=end_len2,
                         l=l,length=length,
                         anchor=anchor,spin=spin,orient=orient)
      children();
}


// Module: acme_threaded_rod()
// Synopsis: Creates an ACME threaded rod.
// SynTags: Geom
// Topics: Threading, Screws
// See Also: acme_threaded_nut()
// Usage:
//   acme_threaded_rod(d, l|length, tpi|pitch=, [internal=], ...) [ATTACHMENTS];
// Description:
//   Constructs an ACME trapezoidal threaded screw rod.  This form has a 29 degree thread angle with a
//   symmetric trapezoidal thread.  
// Arguments:
//   d = Outer diameter of threaded rod.
//   l / length / h / height = Length of threaded rod.
//   tpi = threads per inch.
//   ---
//   pitch = thread spacing (alternative to tpi)
//   starts = The number of lead starts.  Default = 1
//   left_handed = if true, create left-handed threads.  Default = false
//   bevel = if true, bevel the thread ends.  Default: false
//   bevel1 = if true bevel the bottom end.
//   bevel2 = if true bevel the top end. 
//   internal = If true, this is a mask for making internal threads.
//   blunt_start = If true apply truncated blunt start threads at both ends.  Default: true
//   blunt_start1 = If true apply truncated blunt start threads bottom end.
//   blunt_start2 = If true apply truncated blunt start threads top end.
//   end_len = Specify the unthreaded length at the end after blunt start threads.  Default: 0
//   end_len1 = Specify unthreaded length at the bottom
//   end_len2 = Specify unthreaded length at the top
//   lead_in = Specify linear length of the lead in section of the threading with blunt start threads
//   lead_in1 = Specify linear length of the lead in section of the threading at the bottom with blunt start threads
//   lead_in2 = Specify linear length of the lead in section of the threading at the top with blunt start threads
//   lead_in_ang = Specify angular length in degrees of the lead in section of the threading with blunt start threads
//   lead_in_ang1 = Specify angular length in degrees of the lead in section of the threading at the bottom with blunt start threads
//   lead_in_ang2 = Specify angular length in degrees of the lead in section of the threading at the top with blunt start threads
//   lead_in_shape = Specify the shape of the thread lead in by giving a text string or function.  Default: "default"
//   teardrop = If true, adds a teardrop profile to the back (Y+) side of the threaded rod, for 3d printability of horizontal holes. If numeric, specifies the proportional extra distance of the teardrop flat top from the screw center, or set to "max" for a pointed teardrop. Default: false
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
// Example(Med;VPR=[100,0,5];VPD=220): Masking a Horizontal Threaded Hole
//   difference() {
//     cuboid(50);
//     acme_threaded_rod(
//         d=25, l=51, pitch=4, $fn=36,
//         internal=true, bevel=true,
//         blunt_start=false,
//         teardrop=true, orient=FWD
//     );
//   }
function acme_threaded_rod(
    d, l, tpi, pitch,
    starts=1,
    left_handed=false,
    bevel,bevel1,bevel2,
    internal=false, 
    d1, d2, length, h, height,
    blunt_start, blunt_start1, blunt_start2,
    lead_in, lead_in1, lead_in2,
    lead_in_ang, lead_in_ang1, lead_in_ang2,
    end_len, end_len1, end_len2,
    lead_in_shape="default",
    teardrop=false,
    anchor, spin, orient
) = no_function("acme_threaded_rod");
module acme_threaded_rod(
    d, l, tpi, pitch,
    starts=1,
    left_handed=false,
    bevel,bevel1,bevel2,
    internal=false, 
    d1, d2, length, h, height,
    blunt_start, blunt_start1, blunt_start2,
    lead_in, lead_in1, lead_in2,
    lead_in_ang, lead_in_ang1, lead_in_ang2,
    end_len, end_len1, end_len2,
    lead_in_shape="default",
    teardrop=false,
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
        internal=internal, length=length, height=height, h=h,
        blunt_start=blunt_start, blunt_start1=blunt_start1, blunt_start2=blunt_start2,
        lead_in=lead_in, lead_in1=lead_in1, lead_in2=lead_in2, lead_in_shape=lead_in_shape,
        lead_in_ang=lead_in_ang, lead_in_ang1=lead_in_ang1, lead_in_ang2=lead_in_ang2,
        end_len=end_len, end_len1=end_len1, end_len2=end_len2,
        teardrop=teardrop,
        anchor=anchor,
        spin=spin,
        orient=orient
    ) children();
}



// Module: acme_threaded_nut()
// Synopsis: Creates an ACME threaded nut.
// SynTags: Geom
// Topics: Threading, Screws
// See Also: acme_threaded_rod()
// Usage:
//   acme_threaded_nut(nutwidth, id, h|height|thickness, tpi|pitch=, [shape=], ...) [ATTACHMENTS];
// Description:
//   Constructs a hexagonal or square nut for an ACME threaded screw rod. 
// Arguments:
//   nutwidth = flat to flat width of nut.
//   id = inner diameter of threaded hole, measured from bottom of threads
//   h / height / l / length / thickness = height/thickness of nut.
//   tpi = threads per inch
//   ---
//   pitch = Thread spacing (alternative to tpi)
//   shape = specifies shape of nut, either "hex" or "square".  Default: "hex"
//   left_handed = if true, create left-handed threads.  Default = false
//   starts = Number of lead starts.  Default: 1
//   bevel = if true, bevel the outside of the nut.  Default: true for hex nuts, false for square nuts
//   bevel1 = if true, bevel the outside of the nut bottom.
//   bevel2 = if true, bevel the outside of the nut top. 
//   bevang = set the angle for the outside nut bevel.  Default: 30
//   ibevel = if true, bevel the inside (the hole).   Default: true
//   ibevel1 = if true bevel the inside, bottom end.
//   ibevel2 = if true bevel the inside, top end.
//   blunt_start = If true apply truncated blunt start threads at both ends.  Default: true
//   blunt_start1 = If true apply truncated blunt start threads bottom end.
//   blunt_start2 = If true apply truncated blunt start threads top end.
//   end_len = Specify the unthreaded length at the end after blunt start threads.  Default: 0
//   end_len1 = Specify unthreaded length at the bottom
//   end_len2 = Specify unthreaded length at the top
//   lead_in = Specify linear length of the lead in section of the threading with blunt start threads
//   lead_in1 = Specify linear length of the lead in section of the threading at the bottom with blunt start threads
//   lead_in2 = Specify linear length of the lead in section of the threading at the top with blunt start threads
//   lead_in_ang = Specify angular length in degrees of the lead in section of the threading with blunt start threads
//   lead_in_ang1 = Specify angular length in degrees of the lead in section of the threading at the bottom with blunt start threads
//   lead_in_ang2 = Specify angular length in degrees of the lead in section of the threading at the top with blunt start threads
//   lead_in_shape = Specify the shape of the thread lead in by giving a text string or function.  Default: "default"
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   $slop = The printer-specific slop value, which adds clearance (`4*$slop`) to internal threads.
// Examples(Med):
//   acme_threaded_nut(nutwidth=16, id=3/8*INCH, h=8, tpi=8, $slop=0.05);
//   acme_threaded_nut(nutwidth=16, id=3/8*INCH, h=10, tpi=12, starts=3, $slop=0.1, $fa=1, $fs=1, ibevel=false);
//   acme_threaded_nut(nutwidth=16, id=3/8*INCH, h=10, tpi=12, starts=3, $slop=0.1, $fa=1, $fs=1, blunt_start=false);
function acme_threaded_nut(
    nutwidth, id, h, tpi, pitch,
    starts=1,
    left_handed=false,shape="hex",
    bevel,bevel1,bevel2,bevang=30,
    ibevel,ibevel1,ibevel2,
    height,thickness,
    length, l,
    blunt_start, blunt_start1, blunt_start2,
    lead_in, lead_in1, lead_in2,
    lead_in_ang, lead_in_ang1, lead_in_ang2,
    end_len, end_len1, end_len2,
    lead_in_shape="default",
    anchor, spin, orient
) = no_function("acme_threaded_nut");
module acme_threaded_nut(
    nutwidth, id, h, tpi, pitch,
    starts=1,
    left_handed=false,shape="hex",
    bevel,bevel1,bevel2,bevang=30,
    ibevel,ibevel1,ibevel2,
    height,thickness,
    length, l,
    blunt_start, blunt_start1, blunt_start2,
    lead_in, lead_in1, lead_in2,
    lead_in_ang, lead_in_ang1, lead_in_ang2,
    end_len, end_len1, end_len2,
    lead_in_shape="default",
    anchor, spin, orient
) {
    dummy = assert(num_defined([pitch,tpi])==1,"Must give exactly one of pitch and tpi");
    pitch = is_undef(pitch) ? INCH/tpi : pitch;
    dummy2=assert(is_num(pitch) && pitch>=0);
    trapezoidal_threaded_nut(
        nutwidth=nutwidth, id=id, h=h, pitch=pitch,
        thread_depth = pitch/2, 
        thread_angle=29,shape=shape, 
        left_handed=left_handed,
        bevel=bevel,bevel1=bevel1,bevel2=bevel2,
        ibevel=ibevel,ibevel1=ibevel1,ibevel2=ibevel2,
        height=height,thickness=thickness,
        blunt_start=blunt_start, blunt_start1=blunt_start1, blunt_start2=blunt_start2,
        lead_in=lead_in, lead_in1=lead_in1, lead_in2=lead_in2, lead_in_shape=lead_in_shape,
        lead_in_ang=lead_in_ang, lead_in_ang1=lead_in_ang1, lead_in_ang2=lead_in_ang2,
        end_len=end_len, end_len1=end_len1, end_len2=end_len2,
        l=l,length=length,
        starts=starts,
        anchor=anchor,
        spin=spin,
        orient=orient
    ) children();
}




// Section: Pipe Threading

// Module: npt_threaded_rod()
// Synopsis: Creates NPT pipe threading.
// SynTags: Geom
// Topics: Threading, Screws
// See Also: acme_threaded_rod()
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
                blunt_start=true
            );
            if (hollow) cylinder(h=l+1, d=size*INCH, center=true);
        }
        children();
    }
}



// Section: Buttress Threading

// Module: buttress_threaded_rod()
// Synopsis: Creates a buttress-threaded rod.
// SynTags: Geom
// Topics: Threading, Screws
// See Also: buttress_threaded_nut()
// Usage:
//   buttress_threaded_rod(d, l|length, pitch, [internal=], ...) [ATTACHMENTS];
// Description:
//   Constructs a simple buttress threaded rod with a 45 degree angle.  The buttress thread or sawtooth thread has low friction and high loading
//   in one direction at the cost of higher friction and inferior loading in the other direction.  Buttress threads are sometimes used on
//   vises, which are loaded only in one direction.  
// Arguments:
//   d = Outer diameter of threaded rod.
//   l / length / h / height = Length of threaded rod.
//   pitch = Thread spacing.
//   ---
//   left_handed = if true, create left-handed threads.  Default = false
//   starts = Number of lead starts.  Default: 1
//   bevel = if true, bevel the thread ends.  Default: false
//   bevel1 = if true bevel the bottom end.
//   bevel2 = if true bevel the top end. 
//   internal = If true, this is a mask for making internal threads.
//   blunt_start = If true apply truncated blunt start threads at both ends.  Default: true
//   blunt_start1 = If true apply truncated blunt start threads bottom end.
//   blunt_start2 = If true apply truncated blunt start threads top end.
//   end_len = Specify the unthreaded length at the end after blunt start threads.  Default: 0
//   end_len1 = Specify unthreaded length at the bottom
//   end_len2 = Specify unthreaded length at the top
//   lead_in = Specify linear length of the lead in section of the threading with blunt start threads
//   lead_in1 = Specify linear length of the lead in section of the threading at the bottom with blunt start threads
//   lead_in2 = Specify linear length of the lead in section of the threading at the top with blunt start threads
//   lead_in_ang = Specify angular length in degrees of the lead in section of the threading with blunt start threads
//   lead_in_ang1 = Specify angular length in degrees of the lead in section of the threading at the bottom with blunt start threads
//   lead_in_ang2 = Specify angular length in degrees of the lead in section of the threading at the top with blunt start threads
//   lead_in_shape = Specify the shape of the thread lead in by giving a text string or function.  Default: "default"
//   teardrop = If true, adds a teardrop profile to the back (Y+) side of the threaded rod, for 3d printability of horizontal holes. If numeric, specifies the proportional extra distance of the teardrop flat top from the screw center, or set to "max" for a pointed teardrop. Default: false
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
//   buttress_threaded_rod(d=25, l=20, pitch=2, $fa=1, $fs=1,end_len=0);
//   buttress_threaded_rod(d=10, l=20, pitch=1.25, left_handed=true, $fa=1, $fs=1);
// Example(Med;VPR=[100,0,5];VPD=220): Masking a Horizontal Threaded Hole
//   difference() {
//     cuboid(50);
//     buttress_threaded_rod(
//         d=25, l=51, pitch=4, $fn=36,
//         internal=true, bevel=true,
//         blunt_start=false,
//         teardrop=true, orient=FWD
//     );
//   }
function buttress_threaded_rod(
    d, l, pitch,
    left_handed=false, starts=1,
    bevel,bevel1,bevel2,
    internal=false,
    d1, d2, length, h, height,
    blunt_start, blunt_start1, blunt_start2,
    lead_in, lead_in1, lead_in2,
    lead_in_ang, lead_in_ang1, lead_in_ang2,
    end_len, end_len1, end_len2,
    lead_in_shape="default",
    teardrop=false,
    anchor, spin, orient
) = no_function("buttress_threaded_rod");
module buttress_threaded_rod(
    d, l, pitch,
    left_handed=false, starts=1,
    bevel,bevel1,bevel2,
    internal=false,
    d1, d2, length, h, height,
    blunt_start, blunt_start1, blunt_start2,
    lead_in, lead_in1, lead_in2,
    lead_in_ang, lead_in_ang1, lead_in_ang2,
    end_len, end_len1, end_len2,
    lead_in_shape="default",
    teardrop=false,
    anchor, spin, orient
) {
    depth = pitch * 3/4;
    profile = [
        [  -1/2, -0.77],
        [ -7/16, -0.75],
        [  5/16,  0],
        [  7/16,  0],
        [  7/16, -0.75],
        [   1/2, -0.77],
    ];
    generic_threaded_rod(
        d=d, l=l, pitch=pitch,
        profile=profile, 
        left_handed=left_handed,
        bevel=bevel,bevel1=bevel1,bevel2=bevel2,
        internal=internal, length=length, height=height, h=h,
        blunt_start=blunt_start, blunt_start1=blunt_start1, blunt_start2=blunt_start2,
        lead_in=lead_in, lead_in1=lead_in1, lead_in2=lead_in2, lead_in_shape=lead_in_shape,
        lead_in_ang=lead_in_ang, lead_in_ang1=lead_in_ang1, lead_in_ang2=lead_in_ang2,
        end_len=end_len, end_len1=end_len1, end_len2=end_len2,
        d1=d1,d2=d2,
        teardrop=teardrop,
        anchor=anchor,
        spin=spin,starts=starts,
        orient=orient
    ) children();
}



// Module: buttress_threaded_nut()
// Synopsis: Creates a buttress-threaded nut.
// SynTags: Geom
// Topics: Threading, Screws
// See Also: buttress_threaded_rod()
// Usage:
//   buttress_threaded_nut(nutwidth, id, h|height|thickness, pitch, ...) [ATTACHMENTS];
// Description:
//   Constructs a hexagonal or square nut for a simple buttress threaded screw rod.  
// Arguments:
//   nutwidth = diameter of the nut.
//   id = inner diameter of threaded hole, measured from bottom of threads
//   h / height / l / length / thickness = height/thickness of nut.
//   pitch = Thread spacing. 
//   ---
//   shape = specifies shape of nut, either "hex" or "square".  Default: "hex"
//   left_handed = if true, create left-handed threads.  Default = false
//   starts = The number of lead starts.  Default: 1
//   bevel = if true, bevel the outside of the nut.  Default: true for hex nuts, false for square nuts
//   bevel1 = if true, bevel the outside of the nut bottom.
//   bevel2 = if true, bevel the outside of the nut top. 
//   bevang = set the angle for the outside nut bevel.  Default: 30
//   ibevel = if true, bevel the inside (the hole).   Default: true
//   ibevel1 = if true bevel the inside, bottom end.
//   ibevel2 = if true bevel the inside, top end.
//   blunt_start = If true apply truncated blunt start threads at both ends.  Default: true
//   blunt_start1 = If true apply truncated blunt start threads bottom end.
//   blunt_start2 = If true apply truncated blunt start threads top end.
//   end_len = Specify the unthreaded length at the end after blunt start threads.  Default: 0
//   end_len1 = Specify unthreaded length at the bottom
//   end_len2 = Specify unthreaded length at the top
//   lead_in = Specify linear length of the lead in section of the threading with blunt start threads
//   lead_in1 = Specify linear length of the lead in section of the threading at the bottom with blunt start threads
//   lead_in2 = Specify linear length of the lead in section of the threading at the top with blunt start threads
//   lead_in_ang = Specify angular length in degrees of the lead in section of the threading with blunt start threads
//   lead_in_ang1 = Specify angular length in degrees of the lead in section of the threading at the bottom with blunt start threads
//   lead_in_ang2 = Specify angular length in degrees of the lead in section of the threading at the top with blunt start threads
//   lead_in_shape = Specify the shape of the thread lead in by giving a text string or function.  Default: "default"
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   $slop = The printer-specific slop value, which adds clearance (`4*$slop`) to internal threads.
// Examples(Med):
//   buttress_threaded_nut(nutwidth=16, id=8, h=8, pitch=1.25, left_handed=true, $slop=0.05, $fa=1, $fs=1);
function buttress_threaded_nut(
    nutwidth, id, h,
    pitch, shape="hex", left_handed=false,
    bevel,bevel1,bevel2,bevang=30,starts=1,
    ibevel,ibevel1,ibevel2,height,thickness,
    length, l,
    blunt_start, blunt_start1, blunt_start2,
    lead_in, lead_in1, lead_in2,
    lead_in_ang, lead_in_ang1, lead_in_ang2,
    end_len, end_len1, end_len2,
    lead_in_shape="default",
    anchor, spin, orient
) = no_function("buttress_threaded_nut");
module buttress_threaded_nut(
    nutwidth, id, h,
    pitch, shape="hex", left_handed=false,
    bevel,bevel1,bevel2,bevang=30,starts=1,
    ibevel,ibevel1,ibevel2,height,thickness,
    length, l,
    blunt_start, blunt_start1, blunt_start2,
    lead_in, lead_in1, lead_in2,
    lead_in_ang, lead_in_ang1, lead_in_ang2,
    end_len, end_len1, end_len2,
    lead_in_shape="default",
    anchor, spin, orient
) {
    depth = pitch * 3/4;
    profile = [
        [  -1/2, -0.77],
        [ -7/16, -0.75],
        [  5/16,  0],
        [  7/16,  0],
        [  7/16, -0.75],
        [  1/ 2, -0.77],
    ];
    generic_threaded_nut(
        nutwidth=nutwidth, id=id, h=h,
        pitch=pitch,
        profile=profile,
        shape=shape,
        left_handed=left_handed,starts=starts,
        bevel=bevel,bevel1=bevel1,bevel2=bevel2,bevang=bevang,
        ibevel=ibevel,ibevel1=ibevel1,ibevel2=ibevel2,
        blunt_start=blunt_start, blunt_start1=blunt_start1, blunt_start2=blunt_start2,
        lead_in=lead_in, lead_in1=lead_in1, lead_in2=lead_in2, lead_in_shape=lead_in_shape,
        lead_in_ang=lead_in_ang, lead_in_ang1=lead_in_ang1, lead_in_ang2=lead_in_ang2,
        end_len=end_len, end_len1=end_len1, end_len2=end_len2,
        l=l,length=length,
        anchor=anchor, spin=spin, height=height, thickness=thickness, 
        orient=orient
    ) children();
}



// Section: Square Threading

// Module: square_threaded_rod()
// Synopsis: Creates a square-threaded rod.
// SynTags: Geom
// Topics: Threading, Screws
// See Also: square_threaded_nut()
// Usage:
//   square_threaded_rod(d, l|length, pitch, [internal=], ...) [ATTACHMENTS];
// Description:
//   Constructs a square profile threaded screw rod.  The greatest advantage of square threads is
//   that they have the least friction and a much higher intrinsic efficiency than trapezoidal threads.
//   They produce no radial load on the nut.  However, square threads cannot carry as much load as trapezoidal threads. 
// Arguments:
//   d = Outer diameter of threaded rod.
//   l / length / h / height = Length of threaded rod.
//   pitch = Thread spacing.
//   ---
//   left_handed = if true, create left-handed threads.  Default = false
//   starts = The number of lead starts.  Default = 1
//   bevel = if true, bevel the thread ends.  Default: false
//   bevel1 = if true bevel the bottom end.
//   bevel2 = if true bevel the top end. 
//   internal = If true, this is a mask for making internal threads.
//   blunt_start = If true apply truncated blunt start threads at both ends.  Default: true
//   blunt_start1 = If true apply truncated blunt start threads bottom end.
//   blunt_start2 = If true apply truncated blunt start threads top end.
//   end_len = Specify the unthreaded length at the end after blunt start threads.  Default: 0
//   end_len1 = Specify unthreaded length at the bottom
//   end_len2 = Specify unthreaded length at the top
//   lead_in = Specify linear length of the lead in section of the threading with blunt start threads
//   lead_in1 = Specify linear length of the lead in section of the threading at the bottom with blunt start threads
//   lead_in2 = Specify linear length of the lead in section of the threading at the top with blunt start threads
//   lead_in_ang = Specify angular length in degrees of the lead in section of the threading with blunt start threads
//   lead_in_ang1 = Specify angular length in degrees of the lead in section of the threading at the bottom with blunt start threads
//   lead_in_ang2 = Specify angular length in degrees of the lead in section of the threading at the top with blunt start threads
//   lead_in_shape = Specify the shape of the thread lead in by giving a text string or function.  Default: "default"
//   teardrop = If true, adds a teardrop profile to the back (Y+) side of the threaded rod, for 3d printability of horizontal holes. If numeric, specifies the proportional extra distance of the teardrop flat top from the screw center, or set to "max" for a pointed teardrop. Default: false
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
// Example(Med;VPR=[100,0,5];VPD=220): Masking a Horizontal Threaded Hole
//   difference() {
//     cuboid(50);
//     square_threaded_rod(
//         d=25, l=51, pitch=4, $fn=36,
//         internal=true, bevel=true,
//         blunt_start=false,
//         teardrop=true, orient=FWD
//     );
//   }
function square_threaded_rod(
    d, l, pitch,
    left_handed=false,
    bevel,bevel1,bevel2,
    starts=1,
    internal=false,
    d1, d2, length, h, height,
    blunt_start, blunt_start1, blunt_start2,
    lead_in, lead_in1, lead_in2,
    lead_in_ang, lead_in_ang1, lead_in_ang2,
    end_len, end_len1, end_len2,
    lead_in_shape="default",
    teardrop=false,
    anchor, spin, orient
) = no_function("square_threaded_rod");
module square_threaded_rod(
    d, l, pitch,
    left_handed=false,
    bevel,bevel1,bevel2,
    starts=1,
    internal=false,
    d1, d2, length, h, height,
    blunt_start, blunt_start1, blunt_start2,
    lead_in, lead_in1, lead_in2,
    lead_in_ang, lead_in_ang1, lead_in_ang2,
    end_len, end_len1, end_len2,
    lead_in_shape="default",
    teardrop=false,
    anchor, spin, orient
) {
    trapezoidal_threaded_rod(
        d=d, l=l, pitch=pitch,
        thread_angle=0.1,
        left_handed=left_handed,
        bevel=bevel,bevel1=bevel1,bevel2=bevel2,
        starts=starts,
        internal=internal, length=length, height=height, h=h,
        blunt_start=blunt_start, blunt_start1=blunt_start1, blunt_start2=blunt_start2,
        lead_in=lead_in, lead_in1=lead_in1, lead_in2=lead_in2, lead_in_shape=lead_in_shape,
        lead_in_ang=lead_in_ang, lead_in_ang1=lead_in_ang1, lead_in_ang2=lead_in_ang2,
        end_len=end_len, end_len1=end_len1, end_len2=end_len2,
        teardrop=teardrop,
        d1=d1, d2=d2,
        anchor=anchor,
        spin=spin,
        orient=orient
    ) children();
}



// Module: square_threaded_nut()
// Synopsis: Creates a square-threaded nut.
// SynTags: Geom
// Topics: Threading, Screws
// See Also: square_threaded_rod()
// Usage:
//   square_threaded_nut(nutwidth, id, h|height|thickness, pitch, ...) [ATTACHMENTS];
// Description:
//   Constructs a hexagonal or square nut for a square profile threaded screw rod.  
// Arguments:
//   nutwidth = diameter of the nut.
//   id = inner diameter of threaded hole, measured from bottom of threads
//   h / height / l / length / thickness = height/thickness of nut.
//   pitch = Length between threads.
//   ---
//   shape = specifies shape of nut, either "hex" or "square".  Default: "hex"
//   left_handed = if true, create left-handed threads.  Default = false
//   starts = The number of lead starts.  Default = 1
//   bevel = if true, bevel the outside of the nut.  Default: true for hex nuts, false for square nuts
//   bevel1 = if true, bevel the outside of the nut bottom.
//   bevel2 = if true, bevel the outside of the nut top. 
//   bevang = set the angle for the outside nut bevel.  Default: 30
//   ibevel = if true, bevel the inside (the hole).   Default: true
//   ibevel1 = if true bevel the inside, bottom end.
//   ibevel2 = if true bevel the inside, top end.
//   blunt_start = If true apply truncated blunt start threads at both ends.  Default: true
//   blunt_start1 = If true apply truncated blunt start threads bottom end.
//   blunt_start2 = If true apply truncated blunt start threads top end.
//   end_len = Specify the unthreaded length at the end after blunt start threads.  Default: 0
//   end_len1 = Specify unthreaded length at the bottom
//   end_len2 = Specify unthreaded length at the top
//   lead_in = Specify linear length of the lead in section of the threading with blunt start threads
//   lead_in1 = Specify linear length of the lead in section of the threading at the bottom with blunt start threads
//   lead_in2 = Specify linear length of the lead in section of the threading at the top with blunt start threads
//   lead_in_ang = Specify angular length in degrees of the lead in section of the threading with blunt start threads
//   lead_in_ang1 = Specify angular length in degrees of the lead in section of the threading at the bottom with blunt start threads
//   lead_in_ang2 = Specify angular length in degrees of the lead in section of the threading at the top with blunt start threads
//   lead_in_shape = Specify the shape of the thread lead in by giving a text string or function.  Default: "default"
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   $slop = The printer-specific slop value, which adds clearance (`4*$slop`) to internal threads.
// Examples(Med):
//   square_threaded_nut(nutwidth=16, id=10, h=10, pitch=2, starts=2, $slop=0.1, $fn=32);
function square_threaded_nut(
    nutwidth, id, h,
    pitch,
    left_handed=false,
    bevel,bevel1,bevel2,bevang=30,
    ibevel,ibevel1,ibevel2,
    height,thickness,    
    length, l,
    blunt_start, blunt_start1, blunt_start2,
    lead_in, lead_in1, lead_in2,
    lead_in_ang, lead_in_ang1, lead_in_ang2,
    end_len, end_len1, end_len2,
    lead_in_shape="default",
    starts=1,
    anchor, spin, orient
) = no_function("square_threaded_nut");
module square_threaded_nut(
    nutwidth, id, h,
    pitch,
    left_handed=false,
    bevel,bevel1,bevel2,bevang=30,
    ibevel,ibevel1,ibevel2,
    height,thickness,    
    length, l,
    blunt_start, blunt_start1, blunt_start2,
    lead_in, lead_in1, lead_in2,
    lead_in_ang, lead_in_ang1, lead_in_ang2,
    end_len, end_len1, end_len2,
    lead_in_shape="default",
    starts=1,
    anchor, spin, orient
) {
    assert(is_num(pitch) && pitch>=0)
    trapezoidal_threaded_nut(
        nutwidth=nutwidth, id=id, h=h, pitch=pitch,
        thread_angle=0,
        left_handed=left_handed,
        bevel=bevel,bevel1=bevel1,bevel2=bevel2, bevang=bevang,
        ibevel=ibevel, ibevel1=ibevel1, ibevel2=ibevel2,
        height=height,thickness=thickness,
        starts=starts,
        blunt_start=blunt_start, blunt_start1=blunt_start1, blunt_start2=blunt_start2,
        lead_in=lead_in, lead_in1=lead_in1, lead_in2=lead_in2, lead_in_shape=lead_in_shape,
        lead_in_ang=lead_in_ang, lead_in_ang1=lead_in_ang1, lead_in_ang2=lead_in_ang2,
        end_len=end_len, end_len1=end_len1, end_len2=end_len2,
        l=l,length=length,
        anchor=anchor,
        spin=spin,
        orient=orient
    ) children();
}


// Section: Ball Screws

// Module: ball_screw_rod()
// Synopsis: Creates a ball screw rod.
// SynTags: Geom
// Topics: Threading, Screws
// Usage:
//   ball_screw_rod(d, l|length, pitch, [ball_diam], [ball_arc], [internal=], ...) [ATTACHMENTS];
// Description:
//   Constructs a ball screw rod.  This type of rod is used with ball bearings.  
// Arguments:
//   d = Outer diameter of threaded rod.
//   l / length / h / height = Length of threaded rod.
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
//   blunt_start = If true apply truncated blunt start threads at both ends.  Default: true
//   blunt_start1 = If true apply truncated blunt start threads bottom end.
//   blunt_start2 = If true apply truncated blunt start threads top end.
//   end_len = Specify the unthreaded length at the end after blunt start threads.  Default: 0
//   end_len1 = Specify unthreaded length at the bottom
//   end_len2 = Specify unthreaded length at the top
//   lead_in = Specify linear length of the lead in section of the threading with blunt start threads
//   lead_in1 = Specify linear length of the lead in section of the threading at the bottom with blunt start threads
//   lead_in2 = Specify linear length of the lead in section of the threading at the top with blunt start threads
//   lead_in_ang = Specify angular length in degrees of the lead in section of the threading with blunt start threads
//   lead_in_ang1 = Specify angular length in degrees of the lead in section of the threading at the bottom with blunt start threads
//   lead_in_ang2 = Specify angular length in degrees of the lead in section of the threading at the top with blunt start threads
//   lead_in_shape = Specify the shape of the thread lead in by giving a text string or function.  Default: "default"
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   $slop = The printer-specific slop value, which adds clearance (`4*$slop`) to internal threads.
// Example(2D): Thread Profile, ball_diam=4, ball_arc=100
//   projection(cut=true) ball_screw_rod(d=10, l=15, pitch=5, ball_diam=4, ball_arc=100, orient=BACK, $fn=24, blunt_start=false);
// Example(2D): Thread Profile, ball_diam=4, ball_arc=120
//   projection(cut=true) ball_screw_rod(d=10, l=15, pitch=5, ball_diam=4, ball_arc=120, orient=BACK, $fn=24, blunt_start=false);
// Example(2D): Thread Profile, ball_diam=3, ball_arc=120
//   projection(cut=true) ball_screw_rod(d=10, l=15, pitch=5, ball_diam=3, ball_arc=120, orient=BACK, $fn=24, blunt_start=false);
// Examples(Med):
//   ball_screw_rod(d=15, l=20, pitch=8, ball_diam=5, ball_arc=120, $fa=1, $fs=0.5, blunt_start=false);
//   ball_screw_rod(d=15, l=20, pitch=5, ball_diam=4, ball_arc=120, $fa=1, $fs=0.5, blunt_start=false);
//   ball_screw_rod(d=15, l=20, pitch=5, ball_diam=4, ball_arc=120, left_handed=true, $fa=1, $fs=0.5, blunt_start=false);
function ball_screw_rod(
    d, l, pitch, 
    ball_diam=5, ball_arc=100,
    starts=1,
    left_handed=false,
    internal=false,
    length, h, height,
    bevel, bevel1, bevel2,
    blunt_start, blunt_start1, blunt_start2,
    lead_in, lead_in1, lead_in2,
    lead_in_ang, lead_in_ang1, lead_in_ang2,
    end_len, end_len1, end_len2,
    lead_in_shape="default",
    anchor, spin, orient
) = no_function("ball_screw_rod");
module ball_screw_rod(
    d, l, pitch, 
    ball_diam=5, ball_arc=100,
    starts=1,
    left_handed=false,
    internal=false,
    length, h, height,
    bevel, bevel1, bevel2,
    blunt_start, blunt_start1, blunt_start2,
    lead_in, lead_in1, lead_in2,
    lead_in_ang, lead_in_ang1, lead_in_ang2,
    end_len, end_len1, end_len2,
    lead_in_shape="default",
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
        internal=internal, length=length, height=height, h=h,
        blunt_start=blunt_start, blunt_start1=blunt_start1, blunt_start2=blunt_start2,
        lead_in=lead_in, lead_in1=lead_in1, lead_in2=lead_in2, lead_in_shape=lead_in_shape,
        lead_in_ang=lead_in_ang, lead_in_ang1=lead_in_ang1, lead_in_ang2=lead_in_ang2,
        end_len=end_len, end_len1=end_len1, end_len2=end_len2,
        anchor=anchor,
        spin=spin,
        orient=orient
    ) children();
}


// Section: Generic Threading

// Module: generic_threaded_rod()
// Synopsis: Creates a generic threaded rod.
// SynTags: Geom
// Topics: Threading, Screws
// See Also: generic_threaded_nut()
// Usage:
//   generic_threaded_rod(d, l|length, pitch, profile, [internal=], ...) [ATTACHMENTS];
// Description:
//   Constructs a generic threaded rod using an arbitrary thread profile that you supply.  The rod can be tapered
//   (e.g. for pipe threads).  For specific thread types use other modules that supply the appropriate profile.
//   .
//   You give the profile as a 2D path that will be scaled by the pitch to produce the final thread shape.  The profile
//   X values must be between -1/2 and 1/2.  The Y=0 point will align with the specified rod diameter, so generally you
//   want a Y value of zero at the peak (which makes your specified diameter the outer diameter of the threads).  The
//   value in the valleys of the thread should then be `-depth/pitch` due to the scaling by the thread pitch.  The first
//   and last points should generally have the same Y value, but it is not necessary to give values at X=1/2 or X=-1/2
//   if unless the Y values differ from the interior points in the profile.  Generally you should center the profile
//   horizontally in the interval [-1/2, 1/2].
//   .
//   If internal is true then produce a thread mask to difference from an object.  When internal is true the rod
//   diameter is enlarged to correct for the polygonal nature of circles to ensure that the internal diameter is the
//   specified size.  The diameter is also increased by `4 * $slop` to create clearance for threading by allowing a `2 *
//   $slop` gap on each side.  If bevel is set to true and internal is false then the ends of the rod will be beveled.
//   When bevel is true and internal is true the ends of the rod will be filled in so that the rod mask will create a
//   bevel when subtracted from an object.  The bevel is at 45 deg and is the depth of the threads.
//   .
//   Blunt start threading, which is the default, specifies that the thread ends abruptly at its full width instead of
//   running off the end of the shaft and leaving a sharp edged partial thread at the end of the screw.  This makes
//   screws easier to start and prevents cross threading.  Blunt start threads should always be superior, and they are
//   faster to model, but if you really need standard threads that run off the end you can set `blunt_start=false`.
//   .
//   The teardrop option cuts off the threads with a teardrop for 3d printability of horizontal holes.  By default,
//   if the screw outer radius is r then the flat top will be at distance 1.05r from the center, adding a 5% space.  
//   You can set teardrop to a numerical value to adjust that percentage, e.g. a value of 0.1 would give a 10% space.
//   You can set teardrop to "max" to create a pointy-top teardrop with no flat section.  
// Arguments:
//   d = Outer diameter of threaded rod.
//   l / length / h / height = Length of threaded rod.
//   pitch = Thread spacing.
//   profile = A 2D path giving the shape of a thread
//   ---
//   left_handed = If true, create left-handed threads.  Default: false
//   starts = The number of lead starts.  Default: 1
//   internal = If true, make this a mask for making internal threads.  Default: false
//   d1 = Bottom outside diameter of threads.
//   d2 = Top outside diameter of threads.
//   bevel = set to true to bevel both ends, a number to specify a bevel size, false for no bevel, and "reverse" for an inverted bevel
//   bevel1 = set bevel for bottom end. 
//   bevel2 = set bevel for top end.
//   blunt_start = If true apply truncated blunt start threads at both ends.  Default: true
//   blunt_start1 = If true apply truncated blunt start threads bottom end.
//   blunt_start2 = If true apply truncated blunt start threads top end.
//   end_len = Specify the unthreaded length at the end after blunt start threads.  Default: 0
//   end_len1 = Specify unthreaded length at the bottom
//   end_len2 = Specify unthreaded length at the top
//   lead_in = Specify linear length of the lead in section of the threading with blunt start threads
//   lead_in1 = Specify linear length of the lead in section of the threading at the bottom with blunt start threads
//   lead_in2 = Specify linear length of the lead in section of the threading at the top with blunt start threads
//   lead_in_ang = Specify angular length in degrees of the lead in section of the threading with blunt start threads
//   lead_in_ang1 = Specify angular length in degrees of the lead in section of the threading at the bottom with blunt start threads
//   lead_in_ang2 = Specify angular length in degrees of the lead in section of the threading at the top with blunt start threads
//   lead_in_shape = Specify the shape of the thread lead in by giving a text string or function.  Default: "default"
//   teardrop = If true, adds a teardrop profile to the back (Y+) side of the threaded rod, for 3d printability of horizontal holes. If numeric, specifies the proportional extra distance of the teardrop flat top from the screw center, or set to "max" for a pointed teardrop (see above). Default: false
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
    left_handed=false, internal=false,
    bevel, bevel1, bevel2, 
    starts=1,
    d1, d2, length, h, height,
    blunt_start, blunt_start1, blunt_start2,
    lead_in, lead_in1, lead_in2,
    lead_in_ang, lead_in_ang1, lead_in_ang2,
    end_len, end_len1, end_len2,
    lead_in_shape="default",
    teardrop=false,
    anchor, spin, orient
) = no_function("generic_threaded_rod");
module generic_threaded_rod(
    d, l, pitch, profile,
    left_handed=false, internal=false,
    bevel, bevel1, bevel2, 
    starts=1,
    d1, d2, length, h, height,
    blunt_start, blunt_start1, blunt_start2,
    lead_in, lead_in1, lead_in2,
    lead_in_ang, lead_in_ang1, lead_in_ang2,
    end_len, end_len1, end_len2,
    lead_in_shape="default",
    teardrop=false,
    anchor, spin, orient
) {
    len = one_defined([l,length,h,height],"l,length,h,height");
    bevel1 = first_defined([bevel1,bevel]);
    bevel2 = first_defined([bevel2,bevel]);
    blunt_start1 = first_defined([blunt_start1, blunt_start, true]);
    blunt_start2 = first_defined([blunt_start2, blunt_start, true]);                           
    r1 = get_radius(d1=d1, d=d);
    r2 = get_radius(d1=d2, d=d);
    lead_in1 = first_defined([lead_in1, lead_in]);
    lead_in2 = first_defined([lead_in2, lead_in]);
    lead_in_func = is_func(lead_in_shape) ? lead_in_shape
                 : assert(is_string(lead_in_shape),"lead_in_shape must be a function or string")
                   let(ind = search([lead_in_shape], _lead_in_table,0)[0])
                   assert(ind!=[],str("Unknown lead_in_shape, \"",lead_in_shape,"\""))
                   _lead_in_table[ind[0]][1];
    dummy0 = 
      assert(all_positive([pitch]),"Thread pitch must be a positive value")
      assert(all_positive([len]),"Length must be a postive value")
      assert(is_path(profile),"Profile must be a path")
      assert(is_bool(blunt_start1), "blunt_start1/blunt_start must be boolean")
      assert(is_bool(blunt_start2), "blunt_start2/blunt_start must be boolean")
      assert(is_bool(left_handed))
      assert(all_positive([r1,r2]), "Must give d or both d1 and d2 as positive values")
      assert(is_undef(bevel1) || is_num(bevel1) || is_bool(bevel1) || bevel1=="reverse", "bevel1/bevel must be a number, boolean or \"reverse\"")
      assert(is_undef(bevel2) || is_num(bevel2) || is_bool(bevel2) || bevel2=="reverse", "bevel2/bevel must be a number, boolean or \"reverse\"");
    sides = quantup(segs(max(r1,r2)), starts);
    rsc = internal? (1/cos(180/sides)) : 1;    // Internal radius adjusted for faceting
    islop = internal? 2*get_slop() : 0;
    r1adj = r1 * rsc + islop;
    r2adj = r2 * rsc + islop;

    extreme = internal? max(column(profile,1)) : min(column(profile,1));
    profile = !internal ? profile
            : let(
                 maxidx = [for(i=idx(profile)) if (profile[i].y==extreme) i],
                 cutpt = len(maxidx)==1 ? profile(maxidx[0]).x
                       : mean([profile[maxidx[0]].x, profile[maxidx[1]].x])
              )
              [
                 for(entry=profile) if (entry.x>=cutpt) [entry.x-cutpt-1/2,entry.y], 
                 for(entry=profile) if (entry.x<cutpt) [entry.x-cutpt+1/2,entry.y]
              ];
    profmin = pitch * min(column(profile,1));
    pmax = pitch * max(column(profile,1));
    rmax = max(r1adj,r2adj)+pmax;

    // These parameters give the size of the bevel, negative for an outward bevel (e.g. on internal thread mask)  
    bev1 = (bevel1=="reverse"?-1:1)*(internal?-1:1) *
               ( is_num(bevel1)? bevel1
               : bevel1==false? 0
               : blunt_start1? (bevel1==undef?0
                               :internal ? r1/6
                               :(r1+profmin)/6)
               : pmax-profmin);
    bev2 = (bevel2=="reverse"?-1:1)*(internal?-1:1) *
               ( is_num(bevel2)? bevel2
               : bevel2==false? 0
               : blunt_start2? (bevel2==undef?0
                               :internal ? r2/6
                               :(r2+profmin)/6)
               : pmax-profmin);
    // This is the bevel size used for constructing the polyhedron.  The bevel is integrated when blunt start is on, but
    // applied later via difference/union if blunt start is off, so set bevel to zero in the latter case.  
    bevel_size1 = blunt_start1?bev1:0;
    bevel_size2 = blunt_start2?bev2:0;
    // This is the bevel size for clipping, which is only done when blunt start is off
    clip_bev1 = blunt_start1?0:bev1;
    clip_bev2 = blunt_start2?0:bev2;
    end_len1_base = !blunt_start1? 0 : first_defined([end_len1,end_len, 0]);
    end_len2_base = !blunt_start2? 0 : first_defined([end_len2,end_len, 0]);    
    // Enlarge end lengths to give sufficient room for requested bevel
    end_len1 = abs(bevel_size1)>0 ? max(end_len1_base, abs(bevel_size1)) : end_len1_base;
    end_len2 = abs(bevel_size2)>0 ? max(end_len2_base, abs(bevel_size2)) : end_len2_base;
    // length to create below/above z=0, with an extra revolution in non-blunt-start case so
    // the threads can continue to the specified length and we can clip off the blunt start                       
    len1 = -len/2 - (blunt_start1?0:pitch);   
    len2 =  len/2 + (blunt_start2?0:pitch);

    // Thread turns below and above z=0, with extra to ensure we go beyond the length needed
    turns1 = len1/pitch-1;
    turns2 = len2/pitch+1;
    dir = left_handed? -1 : 1;
    dummy2=
        assert(abs(bevel_size1)+abs(bevel_size2)<len, "Combined bevel size exceeds length of screw")
        assert(r1adj+extreme*pitch-bevel_size1>0, "bevel1 is too large to fit screw diameter")
        assert(r2adj+extreme*pitch-bevel_size2>0, "bevel2 is too large to fit screw diameter");
         
    margin1 = profile[0].y==extreme ? profile[0].x : -1/2;
    margin2 = last(profile).y==extreme? last(profile).x : 1/2;
    lead_in_default = pmax-profmin;//2*pitch;
        // 0*360/10;// /4/32*360; higlen_default;//0*4/32*360; //2/32*360;//360*max(pitch/2, pmax-depth)/(2*PI*r2adj);
    // lead_in length needs to be quantized to match the samples
    lead_in_ang1 = !blunt_start1? 0 :
         let(
             user_ang = first_defined([lead_in_ang1,lead_in_ang])
         )
         assert(is_undef(user_ang) || is_undef(lead_in1), "Cannot define lead_in/lead_in1 by both length and angle")
         quantup(
                 is_def(user_ang) ? user_ang : default(lead_in1, lead_in_default)*360/(2*PI*r1adj)
                 , 360/sides);
    lead_in_ang2 = !blunt_start2? 0 :
         let(
             user_ang = first_defined([lead_in_ang2,lead_in_ang])
         )
         assert(is_undef(user_ang) || is_undef(lead_in2), "Cannot define lead_in/lead_in2 by both length and angle")
         quantup(
                 is_def(user_ang) ? user_ang : default(lead_in2, lead_in_default)*360/(2*PI*r2adj)
                 , 360/sides);
    // cut_ang also need to be quantized, but the comparison is offset by 36*turns1/starts, so we need to pull that factor out
    // of the quantization.  (The loop over angle starts at 360*turns1/starts, not at a multiple of 360/sides.)  
//    cut_ang1 = 360 * (len1/pitch-margin1+end_len1/pitch) / starts + lead_in_ang1;
//    cut_ang2 = 360 * (len2/pitch-margin2-end_len2/pitch) / starts - lead_in_ang2;
    cut_ang1 = quantup(360 * (len1/pitch-margin1+end_len1/pitch) / starts + lead_in_ang1-360*turns1/starts,360/sides)+360*turns1/starts;
    cut_ang2 = quantdn(360 * (len2/pitch-margin2-end_len2/pitch) / starts - lead_in_ang2-360*turns1/starts,360/sides)+360*turns1/starts;
    dummy1 =
      assert(cut_ang1<cut_ang2, "lead in length are too long for the amount of thread: they overlap")
      assert(is_num(lead_in_ang1), "lead_in1/lead_in must be a number")
      assert(r1adj+profmin>0 && r2adj+profmin>0, "Screw profile deeper than rod radius");
    map_threads = right((r1adj + r2adj) / 2)                   // Shift profile out to thread radius
                * affine3d_skew(sxz=(r2adj-r1adj)/len)         // Skew correction for tapered threads
                * frame_map(x=[0,0,1], y=[1,0,0])          // Map profile to 3d, parallel to z axis
                * scale(pitch);                            // scale profile by pitch
    start_steps = sides / starts;

    // This is the location for clipping the polyhedron, below the bevel, if one is present, or at length otherwise
    // Clipping is done before scaling to pitch, so we need to divide by the pitch
    rod_clip1 = (len1+abs(bevel_size1))/pitch;
    rod_clip2 = (len2-abs(bevel_size2))/pitch;
    prof3d=path3d(profile,1);
    thread_verts = [
        // Outer loop constructs a vertical column of the screw at each angle
        // covering 360/starts degrees of the cylinder.  
        for (step = [0:1:start_steps])
            let(
                ang = 360 * step/sides,
                dz = step / start_steps,    // z offset for threads at this angle
                rot_prof = zrot(ang*dir)*map_threads,   // Rotate profile to correct angular location
                full_profile =  [   // profile for the entire rod
                    for (turns = [turns1:1:turns2]) 
                        let(
                            tang = turns/starts * 360 + ang,
                            // EPSILON offset prevents funny looking extensions of the thread from its very tip
                            // by forcing values near the tip to evaluate as less than zero = beyond the tip end
                            hsc = tang < cut_ang1 ? lead_in_func(-EPSILON+1-(cut_ang1-tang)/lead_in_ang1,PI*2*r1adj*lead_in_ang1/360 )
                                : tang > cut_ang2 ? lead_in_func(-EPSILON+1-(tang-cut_ang2)/lead_in_ang2,PI*2*r2adj*lead_in_ang2/360 )
                                : [1,1],
                            shift_and_scale = [[hsc.x, 0], [0,hsc.y], [dz+turns,(1-hsc.y)*extreme]]
                        )
                        // This is equivalent to apply(right(dz+turns)*higscale, profile)
                        //
                        // The right movement finds the position of the thread along
                        // what will be the z axis after the profile is mapped to 3d,
                        // and higscale creates a taper and the end of the threads.  
                        each prof3d*shift_and_scale
                ],
                // Clip profile at the ends of the rod and add a z coordinate
                full_profile_clipped = [
                    for(pts=full_profile) [max(rod_clip1,min(rod_clip2,pts.x)), pts.y, 0]
                ]
            )
            [
              [0,0,len1],
              //if (true) apply(rot_prof, [len1/pitch,extreme+2/pitch ,0]), 
              if (bevel_size1) apply(rot_prof, [len1/pitch,extreme-bevel_size1/pitch ,0]), 
              each apply(rot_prof, full_profile_clipped),
              if (bevel_size2) apply(rot_prof, [len2/pitch,extreme-bevel_size2/pitch ,0]), 
              //if (true) apply(rot_prof, [len2/pitch,extreme+2/pitch ,0]), 
              [0, 0, len2]
            ]
    ];
    style=internal?"concave":"convex";
    thread_vnf = vnf_join([
                           for (i=[0:1:starts-1])
                             zrot(i*360/starts, p=vnf_vertex_array(thread_verts, reverse=left_handed, style=style,col_wrap=false)),
                          ]);
    slope = (r1adj-r2adj)/len;
    dummy3 = 
      assert(r1adj+pmax-clip_bev1>0, "bevel1 is too large to fit screw diameter")
      assert(r2adj+pmax-clip_bev2>0, "bevel2 is too large to fit screw diameter")
      assert(abs(clip_bev1)+abs(clip_bev2)<len, "Combined bevel size exceeds length of screw");
    attachable(anchor,spin,orient, r1=r1adj, r2=r2adj, l=len) {
        union(){
          difference() {
              vnf_polyhedron(thread_vnf,convexity=10);              
              if (clip_bev1>0)
                  rotate_extrude()
                      polygon([[                         0,-len/2],
                               [r1adj+pmax-clip_bev1      ,-len/2],
                               [r1adj+pmax-slope*clip_bev1,-len/2+clip_bev1],
                               [                    rmax+1,-len/2+clip_bev1],
                               [                    rmax+1, len1-1],
                               [                         0, len1-1]]);
              if (clip_bev2>0)
                  rotate_extrude()
                      polygon([[                         0, len/2],
                               [r2adj+pmax-clip_bev2      , len/2],
                               [r2adj+pmax+slope*clip_bev2, len/2-clip_bev2],
                               [                    rmax+1, len/2-clip_bev2],
                               [                    rmax+1, len2+1],
                               [                         0, len2+1]]);
              if (!blunt_start1 && clip_bev1<=0)
                  down(len/2) cuboid([2*rmax+1,2*rmax+1, -len1+1], anchor=TOP);                     
              if (!blunt_start2 && clip_bev2<=0)
                  up(len/2) cuboid([2*rmax+1,2*rmax+1, len2+1], anchor=BOTTOM);
          }

          // Add bevel for internal thread mask
          if (clip_bev1<0) 
              down(len/2+.001)cyl(l=-clip_bev1, r2=r1adj+profmin, r1=r1adj+profmin+slope*clip_bev1-clip_bev1,anchor=BOTTOM);
          if (clip_bev2<0) 
              up(len/2+.001)cyl(l=-clip_bev2, r1=r2adj+profmin, r2=r2adj+profmin+slope*clip_bev1-clip_bev2,anchor=TOP);

          // Add teardrop profile
          if (teardrop!=false) {
              fact = is_num(teardrop) ? assert(teardrop>=0,"teardrop value cannot be negative")1-1/sqrt(2)+teardrop
                   : is_bool(teardrop) ? 1-1/sqrt(2)+0.05
                   : teardrop=="max" ? 1/sqrt(2)
                   : assert(false,"invalid teardrop value");
              dummy = assert(fact<=1/sqrt(2), "teardrop value too large");
              pdepth = pmax-profmin;              
              trap1 = back((r1adj+pmax)/sqrt(2),path3d(list_rotate(trapezoid(ang=45,w1 = (r1adj+pmax)*sqrt(2), h = (r1adj+pmax)*fact,anchor=FWD),1),-l/2));
              trap2 = back((r2adj+pmax)/sqrt(2),path3d(list_rotate(trapezoid(ang=45,w1 = (r2adj+pmax)*sqrt(2), h = (r2adj+pmax)*fact,anchor=FWD),1), l/2));
              yproj = [[1,0,0],[0,0,0],[0,0,1]];
              p1a=trap1[0]+unit([0,0,-l/2]-trap1[0])*pdepth*3/4;
              p1b=last(trap1)+unit([0,0,-l/2]-last(trap1))*pdepth*3/4;
              p2a=trap2[0]+unit([0,0,l/2]-trap2[0])*pdepth*3/4;
              p2b=last(trap2)+  unit([0,0,l/2]-last(trap2))*pdepth*3/4     ;
              cut1 = reverse([p1a, p1a*yproj, p1b*yproj, p1b]);
              cut2 = reverse([p2a, p2a*yproj, p2b*yproj, p2b]);
              vert = [
                      [each cut1, each trap1],
                      [each cut2, each trap2]
              ];
              vnf_polyhedron(vnf_vertex_array(vert,caps=true,col_wrap=true));
              //     Old code creates an internal teardrop which unfortunately doesn't print well
              //ang = min(45,opp_hyp_to_ang(rmax+profmin, rmax+pmax));
              //xrot(-90) teardrop(l=l, r1=r1adj+profmin, r2=r2adj+profmin, ang=ang, cap_h1=r1adj+pmax, cap_h2=r2adj+pmax);
          }
        }
        children();
    }
}



// Module: generic_threaded_nut()
// Synopsis: Creates a generic threaded nut.
// SynTags: Geom
// Topics: Threading, Screws
// See Also: generic_threaded_rod()
// Usage:
//   generic_threaded_nut(nutwidth, id, h|height|thickness, pitch, profile, [$slop], ...) [ATTACHMENTS];
// Description:
//   Constructs a hexagonal or square nut for an generic threaded rod using a user-supplied thread profile.
//   See {{generic_threaded_rod()}} for details on the profile specification.  
// Arguments:
//   nutwidth = outer dimension of nut from flat to flat.
//   id = inner diameter of threaded hole, measured from bottom of threads
//   h / height / thickness = height/thickness of nut.
//   pitch = Thread spacing.
//   profile = Thread profile.
//   ---
//   shape = specifies shape of nut, either "hex" or "square".  Default: "hex"
//   left_handed = if true, create left-handed threads.  Default = false
//   starts = The number of lead starts.  Default = 1
//   id1 = inner diameter at the bottom
//   id2 = inner diameter at the top
//   bevel = if true, bevel the outside of the nut.  Default: true for hex nuts, false for square nuts
//   bevel1 = if true, bevel the outside of the nut bottom.
//   bevel2 = if true, bevel the outside of the nut top. 
//   bevang = set the angle for the outside nut bevel.  Default: 30
//   ibevel = if true, bevel the inside (the hole).   Default: true
//   ibevel1 = if true bevel the inside, bottom end.
//   ibevel2 = if true bevel the inside, top end.
//   blunt_start = If true apply truncated blunt start threads at both ends.  Default: true
//   blunt_start1 = If true apply truncated blunt start threads bottom end.
//   blunt_start2 = If true apply truncated blunt start threads top end.
//   end_len = Specify the unthreaded length at the end after blunt start threads.  Default: 0
//   end_len1 = Specify unthreaded length at the bottom
//   end_len2 = Specify unthreaded length at the top
//   lead_in = Specify linear length of the lead in section of the threading with blunt start threads
//   lead_in1 = Specify linear length of the lead in section of the threading at the bottom with blunt start threads
//   lead_in2 = Specify linear length of the lead in section of the threading at the top with blunt start threads
//   lead_in_ang = Specify angular length in degrees of the lead in section of the threading with blunt start threads
//   lead_in_ang1 = Specify angular length in degrees of the lead in section of the threading at the bottom with blunt start threads
//   lead_in_ang2 = Specify angular length in degrees of the lead in section of the threading at the top with blunt start threads
//   lead_in_shape = Specify the shape of the thread lead in by giving a text string or function.  Default: "default"
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   $slop = The printer-specific slop value, which adds clearance (`4*$slop`) to internal threads.
function generic_threaded_nut(
    nutwidth,
    id,
    h,
    pitch,
    profile,
    shape="hex",
    left_handed=false,
    starts=1,
    bevel,bevel1,bevel2,bevang=30,
    ibevel, ibevel1, ibevel2,
    id1,id2, height, thickness, 
    length, l,
    blunt_start, blunt_start1, blunt_start2,
    lead_in, lead_in1, lead_in2,
    lead_in_ang, lead_in_ang1, lead_in_ang2,
    end_len, end_len1, end_len2,
    lead_in_shape="default",
    anchor, spin, orient
) = no_function("generic_threaded_nut");
module generic_threaded_nut(
    nutwidth,
    id,
    h,
    pitch,
    profile,
    shape="hex",
    left_handed=false,
    starts=1,
    bevel,bevel1,bevel2,bevang=30,
    ibevel, ibevel1, ibevel2,
    id1,id2, height, thickness, 
    length, l,
    blunt_start, blunt_start1, blunt_start2,
    lead_in, lead_in1, lead_in2,
    lead_in_ang, lead_in_ang1, lead_in_ang2,
    end_len, end_len1, end_len2,
    lead_in_shape="default",
    anchor, spin, orient
) {
    
    extra = 0.01;
    id1 = first_defined([id1,id]);
    id2 = first_defined([id2,id]);
    h = one_defined([h,height,thickness,l,length],"h,height,thickness,l,length");
    dummyA = assert(is_num(pitch) && pitch>=0, "pitch must be a nonnegative number")
             assert(is_num(h) && h>0, "height/thickness must be a positive number")
             assert(in_list(shape,["square","hex"]), "shape must be \"hex\" or \"square\"")
             assert(all_positive([id1,id2]), "Inner diameter(s) of nut must be positive number(s)");
    slope = (id2-id1)/h;
    full_id1 = id1-slope*extra/2;
    full_id2 = id2+slope*extra/2;
    ibevel1 = first_defined([ibevel1,ibevel,true]);
    ibevel2 = first_defined([ibevel2,ibevel,true]);
    bevel1 = first_defined([bevel1,bevel,shape=="hex"?true:false]);
    bevel2 = first_defined([bevel2,bevel,shape=="hex"?true:false]);
    depth = -pitch*min(column(profile,1));
    IBEV=0.05;
    vnf = linear_sweep(hexagon(id=nutwidth), height=h, center=true);
    attachable(anchor,spin,orient, size=shape=="square" ? [nutwidth,nutwidth,h] : undef, vnf=shape=="hex" ? vnf : undef) {
        difference() {
            _nutshape(nutwidth,h, shape,bevel1,bevel2);
            if (pitch==0) 
               cyl(l=h+extra, d1=full_id1+4*get_slop(), d2=full_id2+4*get_slop(),
                   chamfer1=ibevel1?-IBEV*full_id1:undef,
                   chamfer2=ibevel2?-IBEV*full_id2:undef);
            else
               generic_threaded_rod(
                     d1=full_id1,d2=full_id2,
                     l=h+extra,
                     pitch=pitch,
                     profile=profile,
                     left_handed=left_handed,
                     starts=starts,
                     internal=true,
                     bevel1=ibevel1,bevel2=ibevel2,
                     blunt_start=blunt_start, blunt_start1=blunt_start1, blunt_start2=blunt_start2,
                     lead_in=lead_in, lead_in1=lead_in1, lead_in2=lead_in2, lead_in_shape=lead_in_shape,
                     lead_in_ang=lead_in_ang, lead_in_ang1=lead_in_ang1, lead_in_ang2=lead_in_ang2,
                     end_len=end_len, end_len1=end_len1, end_len2=end_len2
                );
        }
        children();
    }
}


module _nutshape(nutwidth, h, shape, bevel1, bevel2)
{
   bevel_d=0.9;
   intersection(){
       if (shape=="hex")
         cyl(d=nutwidth, circum=true, $fn=6, l=h, chamfer1=bevel1?0:nutwidth*.01, chamfer2=bevel2?0:nutwidth*.01);
       else
         cuboid([nutwidth,nutwidth,h],chamfer=nutwidth*.01, except=[if (bevel1) BOT, if(bevel2) TOP]);
       fn = quantup(segs(r=nutwidth/2),shape=="hex"?6:4);
       d = shape=="hex" ? 2*nutwidth/sqrt(3) : sqrt(2)*nutwidth;
       chamfsize = (d-nutwidth)/2/bevel_d;
       cyl(d=d*.99,h=h+.01,realign=true,circum=true,$fn=fn,chamfer1=bevel1?chamfsize:0,chamfer2=bevel2?chamfsize:0,chamfang=30);
   }
}


// Module: thread_helix()
// Synopsis: Creates a thread helix to add to a cylinder.
// SynTags: Geom
// Topics: Threading, Screws
// See Also: generic_threaded_rod()
// Usage:
//     thread_helix(d, pitch, turns=, [thread_depth=], [thread_angle=|flank_angle=], [profile=], [starts=], [internal=], ...) {ATTACHMENTS};
//     thread_helix(d1=,d2=, pitch=, turns=, [thread_depth=], [thread_angle=|flank_angle=], [profile=], [starts=], [internal=], ...) {ATTACHMENTS};
// Description:
//   Creates a right-handed helical thread with optional end tapering.  Unlike
//   {{generic_threaded_rod()}, this module just generates the thread, and you specify the total
//   angle of threading that you want, which makes it easy to put complete threads onto a longer
//   shaft.  It also optionally makes a finely divided taper at the thread ends.  However, it takes
//   2-3 times as long to render compared to {{generic_threaded_rod()}}.  This module was designed
//   to handle threads found in plastic and glass bottles.
//   .
//   You can specify a thread_depth and flank_angle, in which case you get a symmetric trapezoidal
//   thread, whose inner diameter (the base of the threads for external threading) is d (so the
//   total diameter will be d + thread_depth).  This differs from the threaded_rod modules, where
//   the specified diameter is the outer diameter.  Alternatively you can give a profile, following
//   the same rules as for general_threaded_rod.  The Y=0 point will align with the specified
//   diameter, and the profile should range in X from -1/2 to 1/2.  You cannot specify both the
//   profile and the thread_depth or flank_angle.
//   .
//   Unlike {{generic_threaded_rod()}, when internal=true this module generates the threads, not a thread mask.
//   The profile needs to be inverted to produce the proper thread form.  If you use the built-in trapezoidal
//   thread you get the inverted thread, designed so that the inner diameter is d.  If you supply a custom profile
//   you must invert it yourself to get internal threads.  With adequate clearance
//   this thread will mate with the thread that uses the same parameters but has internal=false.  Note that
//   unlike the threaded_rod modules, thread_helix does not adjust the diameter for faceting, nor does it
//   subtract any $slop for clearance.  
//   .
//   The lead_in options specify a lead-in section where the ends of the threads scale down to avoid a sharp face at the thread ends.
//   You can specify the length of this scaling directly with the lead_in parameters or as an angle using the lead_in_ang parameters.
//   If you give a positive value, the extrusion is lengthenend by the specified distance or angle; if you give a negative
//   value then the scaled end is included in the extrusion length specified by `turns`.  If the value is zero then no scaled ends
//   are produced.  The shape of the scaled ends can be controlled with the lead_in_shape parameter.  Supported options are "sqrt", "linear"
//   "smooth" and "cut".  Lead-in works on both internal and external threads.
// Figure(2D,Med,NoAxes):
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
//   d = Base diameter of threads.  Default: 10
//   pitch = Distance between threads.  Default: 2
//   ---
//   turns = Number of revolutions to rotate thread around.
//   thread_depth = Depth of threads from top to bottom.
//   flank_angle = Angle of thread faces to plane perpendicular to screw.  Default: 15 degrees.
//   thread_angle = Angle between two thread faces.  
//   profile = If an asymmetrical thread profile is needed, it can be specified here.
//   starts = The number of thread starts.  Default: 1
//   left_handed = If true, thread has a left-handed winding.
//   internal = if true make internal threads.  The only effect this has is to change how the thread lead_in is constructed. When true, the lead-in section tapers towards the outside; when false, it tapers towards the inside.  Default: false
//   d1 = Bottom inside base diameter of threads.
//   d2 = Top inside base diameter of threads.
//   lead_in = Specify linear length of the lead in section of the threading with blunt start threads
//   lead_in1 = Specify linear length of the lead in section of the threading at the bottom with blunt start threads
//   lead_in2 = Specify linear length of the lead in section of the threading at the top with blunt start threads
//   lead_in_ang = Specify angular length in degrees of the lead in section of the threading with blunt start threads
//   lead_in_ang1 = Specify angular length in degrees of the lead in section of the threading at the bottom with blunt start threads
//   lead_in_ang2 = Specify angular length in degrees of the lead in section of the threading at the top with blunt start threads
//   lead_in_shape = Specify the shape of the thread lead in by giving a text string or function.  Default: "sqrt"
//   lead_in_sample = Factor to increase sample rate in the lead-in section.  Default: 10
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
// Examples:
//   thread_helix(d=10, pitch=2, thread_depth=0.75, flank_angle=15, turns=2.5, $fn=72);
//   thread_helix(d=10, pitch=2, thread_depth=0.75, flank_angle=15, turns=2.5, lead_in=1, $fn=72);
//   thread_helix(d=10, pitch=2, thread_depth=0.75, flank_angle=15, turns=2, lead_in=2, internal=true, $fn=72);
//   thread_helix(d=10, pitch=2, thread_depth=0.75, flank_angle=15, turns=1, left_handed=true, lead_in=1, $fn=36);
function thread_helix(
    d, pitch, thread_depth, flank_angle, turns,
    profile, starts=1, left_handed=false, internal=false,
    d1, d2, thread_angle, 
    lead_in_shape,
    lead_in, lead_in1, lead_in2,
    lead_in_ang, lead_in_ang1, lead_in_ang2,
    lead_in_sample=10,
    anchor, spin, orient
) = no_function("thread_helix");
module thread_helix(
    d, pitch, thread_depth, flank_angle, turns,
    profile, starts=1, left_handed=false, internal=false,
    d1, d2, thread_angle, 
    lead_in_shape,
    lead_in, lead_in1, lead_in2,
    lead_in_ang, lead_in_ang1, lead_in_ang2,
    lead_in_sample=10,
    anchor, spin, orient
) {
    dummy1=assert(num_defined([thread_angle,flank_angle])<=1, "Cannot define both flank angle and thread angle")
           assert(is_undef(profile) || !any_defined([thread_depth, flank_angle]),
                  "Cannot give thread_depth or flank_angle with a profile")
           assert(all_positive([turns]), "The turns parameter must be a positive number")
           assert(all_positive(pitch), "pitch must be a positive number")
           assert(num_defined([flank_angle,thread_angle])<=1, "Cannot give both thread_angle and flank_angle")
           assert(is_def(profile) || is_def(thread_depth), "If profile is not given, must give thread depth");
    flank_angle = first_defined([flank_angle,u_mul(0.5,thread_angle),15]);
    h = pitch*starts*abs(turns);
    r1 = get_radius(d1=d1, d=d, dflt=10);
    r2 = get_radius(d1=d2, d=d, dflt=10);
    profile = is_def(profile) ? profile :
        let(
            tdp = thread_depth / pitch,
            dz = tdp * tan(flank_angle),
            cap = (1 - 2*dz)/2
        )
        assert(cap/2+dz<=0.5, "Invalid geometry: incompatible thread depth and thread_angle/flank_angle")
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
        union(){
        zrot_copies(n=starts)
            spiral_sweep(pline, h=h, r1=r1, r2=r2, turns=turns*dir, internal=internal,
                         lead_in_shape=lead_in_shape,
                         lead_in=lead_in, lead_in1=lead_in1, lead_in2=lead_in2,
                         lead_in_ang=lead_in_ang, lead_in_ang1=lead_in_ang1, lead_in_ang2=lead_in_ang2,
                         lead_in_sample=lead_in_sample,anchor=CENTER);
        }
        children();
    }
}



// Questions
//   Should nut modules take d1/d2 for tapered nuts?
//
// Need explanation of what exactly the diff is between threaded_rod and helix_threads.
//
// What about blunt_start for ball screws?
// Should default bevel be capped at 1mm or 2mm or something like that?  Including/especially inner bevel on nuts

// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap

