//////////////////////////////////////////////////////////////////////////////////////////////
// LibFile: gears.scad
//   Spur Gears, Bevel Gears, Racks, Worms and Worm Gears.
//   Inspired by code by Leemon Baird, 2011, Leemon@Leemon.com
// Includes:
//   include <BOSL2/std.scad>
//   include <BOSL2/gears.scad>
// FileGroup: Parts
// FileSummary: Gears, racks, worms, and worm gears.
//////////////////////////////////////////////////////////////////////////////////////////////


_GEAR_PITCH = 5;
_GEAR_HELICAL = 0;
_GEAR_THICKNESS = 10;
_GEAR_PA = 20;


$parent_gear_type = undef;
$parent_gear_pitch = undef;
$parent_gear_teeth = undef;
$parent_gear_pa = undef;
$parent_gear_helical = undef;
$parent_gear_thickness = undef;
$parent_gear_dir = undef;
$parent_gear_travel = 0;


function _inherit_gear_param(name, val, pval, dflt, invert=false) =
    is_undef(val)
      ? is_undef(pval)
        ? dflt
        : (invert?-1:1)*pval
      : is_undef(pval)
        ? assert(is_finite(val), str("Invalid ",name," value: ",val))
          val
        : (invert?-1:1)*val;


function _inherit_gear_pitch(fname,pitch,circ_pitch,diam_pitch,mod,warn=true) =
    pitch != undef?
        assert(is_finite(pitch) && pitch>0)
        warn? echo(str(
            "WARNING: The use of the argument pitch= in ", fname,
            " is deprecated.  Please use circ_pitch= instead."
        )) pitch : pitch :
    circ_pitch != undef?
        assert(is_finite(circ_pitch) && circ_pitch>0)
        circ_pitch :
    diam_pitch != undef?
        assert(is_finite(diam_pitch) && diam_pitch>0)
        circular_pitch(diam_pitch=diam_pitch) :
    mod != undef?
        assert(is_finite(mod) && mod>0)
        circular_pitch(mod=mod) :
    $parent_gear_pitch != undef? $parent_gear_pitch :
    5;

function _inherit_gear_pa(pressure_angle) =
    _inherit_gear_param("pressure_angle", pressure_angle, $parent_gear_pa, dflt=20);

function _inherit_gear_helical(helical,invert=false) =
    _inherit_gear_param("helical", helical, $parent_gear_helical, dflt=0, invert=invert);

function _inherit_gear_thickness(thickness) =
    _inherit_gear_param("thickness", thickness, $parent_gear_thickness, dflt=10);


// Section: Quick Introduction to Gears
//   This section gives a quick overview of gears with a focus on the information you need
//   to know to understand the gear parameters and create some gears.  The topic of gears is very complex and highly technical and
//   this section provides the minimal information needed for gear making.  If you want more information about the
//   details of gears, consult the references below, which are the ones that we consulted when writing the library code.
//   - Tec Science
//       * [Involute Gears](https://www.tec-science.com/mechanical-power-transmission/involute-gear/geometry-of-involute-gears/)
//       * [Gear engagement](https://www.tec-science.com/mechanical-power-transmission/involute-gear/meshing-line-action-contact-pitch-circle-law/)
//       * [Gears meshing with racks](https://www.tec-science.com/mechanical-power-transmission/involute-gear/rack-meshing/)
//       * [Gear undercutting](https://www.tec-science.com/mechanical-power-transmission/involute-gear/undercut/)
//       * [Profile shifting](https://www.tec-science.com/mechanical-power-transmission/involute-gear/profile-shift/)
//       * [Detailed gear calculations](https://www.tec-science.com/mechanical-power-transmission/involute-gear/calculation-of-involute-gears/)
//   - SDPSI
//       * [Elements of Gear Technology](https://www.sdp-si.com/resources/elements-of-metric-gear-technology/index.php)
// Subsection: Involute Spur Gears
// The simplest gear form is the involute spur gear, which is an extrusion of a two dimensional form.
// Figure(3D,Med,NoAxes,VPT=[4.62654,-1.10349,0.281802],VPR=[55,0,25],VPD=236.957): Involute Spur Gear
//   spur_gear(mod=5,teeth=18,pressure_angle=20,thickness=25,shaft_diam=15);
// Continues:
//   The term "involute" refers to the shape of the teeth:  the curves of the teeth are involutes of circles, 
//   which are curves that optimize gear performance.
// Figure(2D,Med,NoAxes,VPT=[8,74,0],VPR=[0,0,0],VPD=150): The three marked circles are key references on gear teeth.  The pitch circle, which is roughly in the middle of the teeth, is the reference used to define the pitch of teeth on the gear.  The pressure angle is the angle the tooth makes with the pitch circle.  In this example, the pressure angle is 20 degrees as shown by the red lines.  
//   $fn=128;
//   intersection(){
//     spur_gear2d(mod=5,teeth=30,pressure_angle=20);
//     back(82)rect([45, 20],anchor=BACK);
//   }
//   color("black"){
//     stroke(arc(r=_root_radius(mod=5,teeth=30),angle=[70,110]),width=.25);
//     stroke(arc(r=pitch_radius(mod=5,teeth=30),angle=[70,110]),width=.25);
//     stroke(arc(r=outer_radius(mod=5,teeth=30),angle=[70,110]),width=.25);
//     back(63.5)right(24.2)text("root circle",size=2.5);
//     back(69.5)right(26.5)text("pitch circle",size=2.5);
//     back(74)right(28)text("outer circle",size=2.5);    
//   }  
//   base = _base_radius(mod=5, teeth=30);
//   pitchpt = pitch_radius(mod=5, teeth=30);
//   color("red"){
//     zrot(87-360/30) zrot(20,cp=[pitchpt,0]) stroke([[base-5,0],[base+15,0]], width=0.25);
//     zrot(87-360/30) stroke([[pitchpt,0],[pitchpt+11,0]], width=0.25);
//     right(8.3) back(74) zrot(87-360/30) zrot(10,cp=[pitchpt,0]) stroke(arc(angle=[0,20],r=10.5),endcaps="arrow2",width=.25);
//     back(84) right(13) text("pressure angle",size=2.5);
//   }
// Continues:
//   The size of the teeth can be specified as the circular pitch, the distance along the pitch circle
//   from the start of one tooth to the start of the text tooth.  The circular pitch can be computed as
//   `PI*d/teeth` where `d` is the diameter of the pitch circle and `teeth` is the number of teeth on the gear.
//   This simply divides up the pitch circle into the specified number of teeth.  However, the customary
//   way to specify metric gears is using the module, the number of teeth that would fit on the diameter of the gear: `m=d/teeth`.
//   The module is hence the circular pitch divided by a factor of π.  A third way to specify gear sizes is the diametral pitch,
//   which is the number of teeth that fit on a gear with a diameter of one inch, or π times the number of teeth per inch.
//   Note that for the module or circular pitch, larger values make larger teeth,
//   but for the diametral pitch, the opposite is true.  Throughout this library, module and circular pitch
//   are specified basic OpenSCAD units, so if you work in millimeters and want to give circular pitch in inches, be
//   sure to multiply by `INCH`.  The diametral pitch is given based on inches under the assumption that OpenSCAD units are millimeters.
//   .
//   Basic gears as shown above will mesh when their pitch circles are tangent.
//   The critical requirements for two gears to mesh are that
//   - The teeth are the same size
//   - The pressure angles are identical
//   .
//   Increasing pressure angle makes the tooth stronger, increases power transmission, and can reduce tooth interference for
//   gears with a small number of teeth, but it also increases gear wear and meshing noise.  Higher pressure angles also
//   increase the force that tries to push the gears apart, and hence the load on the gear axles.  The current standard pressure
//   angle is 20 degrees.  It replaces an old 14.5 degree standard.  
// Figure(2D,Med,NoAxes): Teeth of the same size with different pressure angles.  Note that 20 deg is the industry standard. 
//   pang = [30,20,14.5];
//   ycopies(n=3, spacing=25){
//     intersection(){
//       spur_gear2d(mod=5, teeth=30, pressure_angle=pang[$idx]);
//       back(82) rect([45,20], anchor=BACK);
//     }
//     back(68) right(26) text(str(pang[$idx]), size=6.5);
//   }
// Continues:
//   In order for the gear teeth to fit together, and to allow space for lubricant, the valleys of the teeth
//   are made deeper by the `clearance` distance.  This defaults to `module/4`.  
// Figure(2D,Med,NoAxes,VPT=[5.62512,-1.33268,-0.0144912],VPR=[0,0,0],VPD=126): The clearance is extra space at the tooth valley that separates the tooth tip (in green) from the tooth valley below it.  
//   intersection(){
//     rack2d(mod=5, teeth=10, bottom=15, pressure_angle=14.5);
//     rect([35,20]);
//   }  
//   color("lightgreen")render()
//   intersection(){
//      back(gear_dist(mod=5, teeth1=146, teeth2=0 ,profile_shift1=0))
//          spur_gear2d(mod=5, teeth=146, profile_shift=0, pressure_angle=14.5);
//      rect([45,20]);
//   }   
//   color("black") {
//       stroke([[-10,-5],[20,-5]], width=.25);
//       stroke([[-10,-6.2],[20,-6.2]], width=.25);
//       fwd(6.4) right(22) text("clearance", size=2.5);
//   }    
// Continues:
//   Another clearance requirement can present a serious problem when the number of teeth is low.  As the gear rotates, the
//   teeth may interfere with each other.  This may require undercutting the gear teeth to create space, which weakens the teeth.
//   Is is best to avoid gears with very small numbers of teeth when possible.  
// Figure(2D,Med,NoAxes,VPT=[0.042845,6.5338,-0.0144912],VPR=[0,0,0],VPD=126):  The green gear with only five teeth has a severe undercut, which weakens its teeth.  This undercut is necessary to avoid interference with the teeth from the other gear during rotation.  Note that the yellow rack tooth is deep into the undercut space.
//   ang=16;
//   rack2d(mod=5, teeth=3, bottom=15, pressure_angle=14.5, rounding=0);
//   left(2*PI*pitch_radius(mod=5, teeth=5)*ang/360)
//   color("lightgreen")
//     back(gear_dist(mod=5, teeth1=5, profile_shift1=0, teeth2=0))
//       zrot(ang)
//         spur_gear2d(mod=5, teeth=5, clearance=.00001, profile_shift=0, pressure_angle=14.5, shaft_diam=5);

// Subsection: Corrected Gears and Profile Shifting
//   A solution to the problem of undercutting is to use profile shifting.  Profile shifting uses a different portion of the
//   involute curve to form the gear teeth, and this adjustment to the tooth form can eliminate undercutting, while
//   still allowing the gear to mesh with unmodified gears.  Profile shifting
//   changes the diameter at which the gear meshes so it no longer meshes at the pitch circle.  
//   A profile shift of `x`
//   will increase the mesh distance by approximately `x*m` where `m` is the gear module.  The exact adjustment,
//   which you compute with {{gear_dist()}}, is a complex calculation that depends on the profile shifts of both meshing gears.  This means that profile shifting
//   can also be used to fine tune the spacing between gears.  When the gear has many teeth a negative profile shift may
//   be able to bring the gears slightly closer together, while still avoiding undercutting.
//   Profile shifting also changes the effective pressure angle of the gear engagement.  
//   .
//   The minimum number of teeth to avoid undercutting is 17 for a pressure angle of 20, but it is 32 for a pressure
//   angle of 14.5 degrees.  It can be computed as `2/(sin(alpha))^2` where `alpha` is the pressure angle.
//   By default, the gear modules produce corrected gears.  You can override this by specifying the profile shift
//   yourself.  A small undercut may be acceptable, for example: a rule of thumb indicates that gears as small as 14
//   teeth are OK with a 20 degree pressure angle, because the undercut is too small to weaken the teeth significantly.  
// Figure(2D,Med,NoAxes,VPT=[1.33179,10.6532,-0.0144912],VPR=[0,0,0],VPD=155.556): Basic five tooth gear form on the left.  Corrected gear with profile shifting on the right.  The profile shifted teeth lack the weak undercut section.  The axis of the corrected gear is shifted away from the mating rack.
//   $fn=32;
//   ang1=-20;
//   ang2=20;
//   color("blue")
//   left(2*PI*pitch_radius(mod=5, teeth=5)*ang1/360)
//   left(3*5*PI/2)
//     back(gear_dist(mod=5,teeth1=5,profile_shift1=0,teeth2=0,pressure_angle=14.5))
//       zrot(ang1)
//          spur_gear2d(mod=5, teeth=5, profile_shift=0, pressure_angle=14.5, shaft_diam=2);
//   color("green")
//   left(2*PI*pitch_radius(mod=5, teeth=5)*ang2/360)
//   right(3*5*PI/2)
//     back(gear_dist(mod=5, teeth1=5, teeth2=0,pressure_angle=14.5))
//       zrot(ang2)
//         spur_gear2d(mod=5, teeth=5, pressure_angle=14.5, shaft_diam=2);
//   rack2d(teeth=4, bottom=15, mod=5, pressure_angle=14.5);
// Continues:
//   Profile shifting brings with it another complication: in order to maintain the specified clearance, the tips of the
//   gear teeth need to be shortened.  The shortening factor depends on characteristics of both gears, so it cannot
//   be automatically incorporated.  (Consider the situation where one gear mates with multiple other gears.)  With modest
//   profile shifts, you can probably ignore this adjustment, but with more extreme profile shifts, it may be important.
//   You can compute the shortening parameter using {{gear_shorten()}}.  Note that the actual shortening distance is obtained
//   by scaling the shortening factor by the gear's module.  
// Figure(2D,Big,NoAxes,VPT=[55.8861,-4.31463,8.09832],VPR=[0,0,0],VPD=325.228): With large profile shifts the teeth need to be shortened or they don't have clearance in the valleys of the teeth in the meshing gear.  
//   teeth1=25;
//   teeth2=19;
//   mod=4;
//   ps1 = 0.75;
//   ps2 = 0.75;
//   d = gear_dist(mod=mod, teeth1,teeth2,0,ps1,ps2);
//   color("lightblue")
//     spur_gear2d(mod=mod,teeth=teeth1,profile_shift=ps1,gear_spin=-90);
//   right(d)
//     spur_gear2d(mod=mod,teeth=teeth2,profile_shift=ps2,gear_spin=-90);
//   right(9)stroke([[1.3*d/2,0],[d/2+4,0]], endcap2="arrow2",color="black");
//   fwd(2)right(d/2+25)color("black"){back(4)text("No clearance",size=6);
//                           fwd(4)text("at tooth tip",size=6);}
// Figure(2D,Big,NoAxes,VPT=[55.8861,-4.31463,8.09832],VPR=[0,0,0],VPD=325.228): Applying the correct shortening factor restores the clearance to its set value.  
//   teeth1=25;
//   teeth2=19;
//   mod=4;
//   ps1 = 0.75;
//   ps2 = 0.75;
//   d = gear_dist(mod=mod, teeth1,teeth2,0,ps1,ps2);
//   shorten=gear_shorten(teeth1,teeth2,0,ps1,ps2);
//   color("lightblue")
//     spur_gear2d(mod=mod,teeth=teeth1,profile_shift=ps1,shorten=shorten,gear_spin=-90);
//   right(d)
//     spur_gear2d(mod=mod,teeth=teeth2,profile_shift=ps2,shorten=shorten,gear_spin=-90);
//   right(9)stroke([[1.3*d/2,0],[d/2+4,0]], endcap2="arrow2",color="black");
//   fwd(2)right(d/2+25)color("black"){back(4)text("Normal",size=6);
//                           fwd(4)text("Clearance",size=6);}
// Subsection: Helical Gears
//   Helicals gears are a modification of spur gears.  They can replace spur gears in any application.  The teeth are cut
//   following a slanted, helical path.  The angled teeth engage more gradually than spur gear teeth, so they run more smoothly
//   and quietly.  A disadvantage of helical gears is that they have thrust along the axis of the gear that must be 
//   accomodated.  Helical gears also have more sliding friction between the meshing teeth compared to spur gears. 
// Figure(3D,Med,NoAxes,VPT=[3.5641,-7.03148,4.86523],VPR=[62.7,0,29.2],VPD=263.285): A Helical Gear
//   spur_gear(mod=5,teeth=18,pressure_angle=20,thickness=35,helical=-29,shaft_diam=15,slices=15);
// Continues:
//   Helical gears have the same compatibility requirements as spur gears, with the additional requirement that
//   the helical angles must be opposite each other, so a gear with a helical angle of 35 must mesh with one
//   that has an angle of −35.  The industry convention refers to these as left-handed and right handed.  In
//   this library, positive helical angles produce a left handed gear and negative angles produce a right handed gear.
// Figure(3D,Med,NoAxes,VPT=[73.6023,-29.9518,-12.535],VPR=[76,0,1.2],VPD=610): Left and right handed helical gears at 35 degrees.
//   spur_gear(mod=5, teeth=20, helical=35, thickness=70,slices=15);
//   right(150)
//   spur_gear(mod=5, teeth=20, helical=-35, thickness=70,slices=15);
//   down(22)
//   left(60)
//   fwd(220)
//   rot($vpr)
//   color("black")text3d("left handed    right handed",size=18);
//   down(52)
//   left(55)
//   fwd(220)
//   rot($vpr)
//   color("black")text3d("helical=35     helical=−35",size=18);
// Continues:
//   The pitch circle of a helical gear is larger compared to a spur gear
//   by the cosine of the helical angle, so you cannot simply drop helical gears in to replace spur gears without
//   making other adjustments.  This dependence does allow you to make 
//   make much bigger spacing adjustments than are possible with profile shifting—without changing the tooth count.
//   The {{gear_dist()}} function will also compute the appropriate gear spacing for helical gears.
//   The effective pressure angle of helical gears is larger than the nominal pressure angle.  This can make it possible
//   to avoid undercutting without having to use profile shifting, so smaller tooth count gears can be more effective
//   using the helical form. 
// Figure(Anim,Med,Frames=10,NoAxes,VPT=[43.8006,15.9214,3.52727],VPR=[62.3,0,20.3],VPD=446.129): Meshing compatible helical gears
//   zrot($t*360/18)
//     spur_gear(mod=5, teeth=18, pressure_angle=20, thickness=25, helical=-29, shaft_diam=15);
//   right(gear_dist(mod=5, teeth1=18, teeth2=18, helical=29))
//     zrot(360/18/2)
//       zrot(-$t*360/18)
//         spur_gear(mod=5, teeth=18, pressure_angle=20, thickness=25, helical=29, shaft_diam=15);
// Continues:
//   Helical gears can mesh in a second manner that is different from spur gears: they can turn on skew, or crossed axes.  These are also
//   sometimes called "screw gears".  The general requirement for two non-profile-shifted helical gears to mesh is that the angle 
//   between the gears' axes must equal the sum of the helical angles of the two gears, thus for parallel axes, the helical
//   angles must sum to zero.  If helical gears are profile shifted, then in addition to adjusting the distance between the
//   gears, a small adjustment in the angle is needed, so profile shifted gears won't mesh exactly at the sum of their angles.
//   The calculation for gear spacing is different for skew axis gears than for parallel gears, so you do this using {{gear_dist_skew()}},
//   and if you use profile shifting, then you can compute the angle using {{gear_skew_angle()}}. 
// Figure(Anim,Med,NoAxes,Frames=10,VPT=[44.765,6.09492,-3.01199],VPR=[55.7,0,33.2],VPD=401.289): Two helical gears meshing with axes at a 45 degree angle
//   dist = gear_dist_skew(mod=5, teeth1=18, teeth2=18, helical1=22.5,helical2=22.5);
//    axiscolor="darkgray";
//      down(10)color(axiscolor) cyl(d=15, l=145);
//       zrot($t*360/18)
//              color("lightblue")spur_gear(mod=5,teeth=18,pressure_angle=20,thickness=25,helical=22.5,shaft_diam=15);
//   right(dist)
//       xrot(45) {color(axiscolor)cyl(d=15,l=85);
//           zrot(360/18/2)
//               zrot(-$t*360/18)
//                   spur_gear(mod=5,teeth=18,pressure_angle=20,thickness=25,helical=22.5,shaft_diam=15);}
// Subsection: Herringbone Gears
//   The herringbone gear is made from two stacked helical gears with opposite angles.  This design addresses the problem
//   of axial forces that afflict helical gears by having one section that slopes to the
//   right and another that slopes to the left.  Herringbone gears also have the advantage of being self-aligning.
// Figure(3D,Med,NoAxes,VPT=[3.5641,-7.03148,4.86523],VPR=[62.7,0,29.2],VPD=263.285): A herringbone gear
//   spur_gear(mod=5, teeth=16, pressure_angle=20, thickness=35, helical=-20, herringbone=true, shaft_diam=15);
// Subsection: Ring Gears (Internal Gears)
//   A ring gear (or internal gear) is a gear where the teeth are on the inside of a circle.  Such gears must be mated
//   to a regular (external) gear, which rotates around the inside.
// Figure(2D,Med,NoAxes,VPT=[0.491171,1.07815,0.495977],VPR=[0,0,0],VPD=292.705): A interior or ring gear (yellow) with a mating spur gear (blue)
//   teeth1=18;
//   teeth2=30;
//   ps1=undef;
//   ps2=auto_profile_shift(teeth=teeth1);
//   mod=3;
//   d = gear_dist(mod=mod, teeth1=teeth1, teeth2=teeth2,profile_shift1=ps1, profile_shift2=ps2,helical=0, internal2=true);
//   ang = 0;
//     ring_gear2d(mod=mod, teeth=teeth2,profile_shift=ps2,helical=0,backing=4);
//     zrot(ang*360/teeth2)
//     color("lightblue")
//     fwd(d)
//        spur_gear2d(mod=mod, teeth=teeth1, profile_shift=ps1,gear_spin=-ang*360/teeth1,helical=0);
// Continues:
//    Ring gears are subject to all the usual mesh requirements: the teeth must be the same size, the pressure angles must
//    match and they must have opposite helical angles.  The {{gear_dist()}} function can give the center separation of
//    a ring gear and its mating spur gear.  Ring gears have additional complications that tend to arise when the number of
//    teeth is small or the teeth counts of the ring gear and spur gear are too close together.  The mating spur gear must
//    have few enough teeth so that the teeth don't interfere on the other side of the ring.  Very small spur gears can interfere
//    on the tips of the ring gear's teeth.  
// Figure(2D,Med,NoAxes,VPT=[-1.16111,0.0525612,0.495977],VPR=[0,0,0],VPD=213.382): The red regions show interference between the two gears: the 18 tooth spur gear does not fit inside the 20 tooth ring gear. 
//    teeth1=18;
//    teeth2=20;
//    ps1=undef;
//    ps2=auto_profile_shift(teeth=teeth1);
//    mod=3;
//    d = gear_dist(mod=mod, teeth1=teeth1, teeth2=teeth2,profile_shift1=ps1, profile_shift2=ps2,helical=0, internal2=true);
//    ang = 0;
//    color_overlaps(){
//      ring_gear2d(mod=mod, teeth=teeth2,profile_shift=ps2,helical=0,backing=4);
//      zrot(ang*360/teeth2)
//      fwd(d)
//         spur_gear2d(mod=mod, teeth=teeth1, profile_shift=ps1,gear_spin=-ang*360/teeth1,helical=0);
//    }
// Figure(2D,Big,NoAxes,VPT=[10.8821,-26.1226,-0.0685569],VPD=43.9335,VPR=[0,0,16.8]): Interference at teeth tips, shown in red, with a 5 tooth and 19 tooth gear.  
//    $fn=128;
//    teeth1=5;
//    teeth2=19;
//    ps1=0;
//    ps2=0;
//    mod=3;
//    d = gear_dist(mod=mod, teeth1=teeth1, teeth2=teeth2,profile_shift1=ps1, profile_shift2=ps2,helical=0, internal2=true);
//    ang = 1;
//    color_overlaps(){
//      ring_gear2d(mod=mod, teeth=teeth2,profile_shift=ps2,helical=0,backing=4);
//      zrot(ang*360/teeth2)
//      fwd(d)
//         spur_gear2d(mod=mod, teeth=teeth1, profile_shift=ps1,gear_spin=-ang*360/teeth1,helical=0);
//    }
// Continues:
//    The tooth tip interference can often be controlled using profile shifting of the ring gear, but another requirement is
//    that the profile shift of the ring gear must be at least as big as the profile shift of the mated spur gear.  In order
//    to ensure that this condition holds, you may need to use {{auto_profile_shift()}} to find the profile shift that is
//    automatically applied to the spur gear you want to use.
// Figure(2D,Med,VPT=[4.02885,-46.6334,1.23363],VPR=[0,0,6.3],VPD=75.2671,NoAxes): Ring gear without profile shifting doesn't have room for the fat profile shifted teeth of the 5-tooth spur gear, with overlaps shown in red.  
//    $fn=128;
//    teeth1=5;
//    teeth2=35;
//    ps1=undef;
//    ps2=0;
//    mod=3;
//    d=45-.7;
//    ang = .5;
//    color_overlaps(){
//      ring_gear2d(mod=mod, teeth=teeth2,profile_shift=ps2,helical=0,backing=4);
//      zrot(ang*360/teeth2)
//      fwd(d)
//         spur_gear2d(mod=mod, teeth=teeth1, profile_shift=ps1,gear_spin=-ang*360/teeth1,helical=0);
//    }
// Figure(2D,Med,VPT=[9.87969,-45.6706,0.60448],VPD=82.6686,VPR=[0,0,11],NoAxes): When the ring gear is profile shifted to match the spur gear, then the gears mesh without interference.  
//    $fn=128;
//    teeth1=5;
//    teeth2=35;
//    ps1=undef;
//    ps2=auto_profile_shift(teeth=teeth1);
//    mod=3;
//    d = gear_dist(mod=mod, teeth1=teeth1, teeth2=teeth2,profile_shift1=ps1, profile_shift2=ps2,helical=0, internal2=true);
//    ang = .5;
//    color_overlaps(){
//      ring_gear2d(mod=mod, teeth=teeth2,profile_shift=ps2,helical=0,backing=4);
//      zrot(ang*360/teeth2)
//      fwd(d)
//         spur_gear2d(mod=mod, teeth=teeth1, profile_shift=ps1,gear_spin=-ang*360/teeth1,helical=0);
//    }
// Figure(3D,Med,NoAxes,VPT=[2.48983,2.10149,0.658081],VPR=[70.4,0,123],VPD=237.091): A helical ring gear (yellow) mating with the compatible spur gear (blue)
//    $fn=128;
//    teeth1=18;
//    teeth2=30;
//    ps1=undef;
//    ps2=auto_profile_shift(teeth=teeth1);
//    mod=3;
//    d = gear_dist(mod=mod, teeth1=teeth1, teeth2=teeth2,profile_shift1=ps1, profile_shift2=ps2,helical=30, internal2=true);
//    ang = 0;
//      ring_gear(mod=mod, teeth=teeth2,profile_shift=ps2,backing=4,helical=30,thickness=15);
//      zrot(ang*360/teeth2)
//      color("lightblue")
//      fwd(d)
//         spur_gear(mod=mod, teeth=teeth1, profile_shift=ps1,gear_spin=-ang*360/teeth1,helical=-30,thickness=15);
// Subsection: Backlash (Fitting Real Gears Together)
//   You may have noticed that the example gears shown fit together perfectly, making contact on both sides of
//   the teeth.  Real gears need space between the teeth to prevent the gears from jamming, to provide space
//   for lubricant, and to provide allowance for fabrication error.  This space is called backlash.  Excessive backlash
//   is undesirable, especially if the drive reverses frequently.
//   .
//   Backlash can be introduced in two ways.  One is to make the teeth narrower, so the gaps between the teeth are
//   larger than the teeth.  Alternatively, you can move the gears farther apart than their ideal spacing.
//   Backlash can be measured in several different ways.  The gear modules in this library accept a backlash
//   parameter which specifies backlash as a circular distance at the pitch circle.  The modules narrow
//   the teeth by the amount specified, which means the spaces between the teeth grow larger.  Of course, if you apply
//   backlash to both gears then the total backlash in the system is the combined amount from both gears.
//   Usually it is best to apply backlash symmetrically to both gears, but if one gear is very small it may
//   be better to place the backlash entirely on the larger gear to avoid weakening the teeth of the small gear.  
// Figure(2D,Big,VPT=[4.5244,64.112,0.0383045],VPR=[0,0,0],VPD=48.517,NoAxes): Backlash narrows the teeth by the specified length along the pitch circle.  Below a very large backlash appears, with half of the backlash on either side of the tooth.  
//   teeth1=20;
//   mod=5;
//   r1 = pitch_radius(mod=mod,teeth=teeth1,helical=40);
//   bang=4/(2*PI*r1) * 360 ;
//   zrot(-180/teeth1*.5){
//   color("white")
//   dashed_stroke(arc(r=r1, n=30, angle=[80,110]), width=.05);
//     spur_gear2d(mod=mod, teeth=teeth1,backlash=0+.5*0,profile_shift="auto",gear_spin=180/teeth1*.5,helical=40);
//   %spur_gear2d(mod=mod, teeth=teeth1,backlash=4+.5*0,profile_shift="auto",gear_spin=180/teeth1*.5,helical=40);
//   color("black")stroke(arc(n=32,r=r1,angle=[90+bang/2,90]),width=.1,endcaps="arrow2");
//   }    
//   color("black")back(r1+.25)right(5.5)text("backlash/2",size=1);
// Figure(2D,Med,VPT=[0.532987,50.0891,0.0383045],VPR=[0,0,0],VPD=53.9078): Here two gears appear together with a more reasonable backlash applied to both gears. 
//   teeth1=20;teeth2=33;
//   mod=5;
//   ha=0;
//   r1 = pitch_radius(mod=mod,teeth=teeth1,helical=ha);
//   r2=pitch_radius(mod=mod,teeth=teeth2,helical=ha);
//   bang=4/(2*PI*r1) * 360 ;
//   
//   back(r1+pitch_radius(mod=mod,teeth=teeth2,helical=ha)){
//      spur_gear2d(mod=mod, teeth=teeth2,backlash=.5*0,helical=ha,gear_spin=-180/teeth2/2);
//      %spur_gear2d(mod=mod, teeth=teeth2,backlash=1,helical=ha,gear_spin=-180/teeth2/2);
//      }
//   {
//     spur_gear2d(mod=mod, teeth=teeth1,backlash=0+.5*0,profile_shift=0,gear_spin=180/teeth1*.5,helical=ha);
//   %spur_gear2d(mod=mod, teeth=teeth1,backlash=1+.5*0,profile_shift=0,gear_spin=180/teeth1*.5,helical=ha);
//   *color("white"){
//     dashed_stroke(arc(r=r1, n=30, angle=[80,110]), width=.05);
//     back(r1+r2)
//        dashed_stroke(arc(r=r2, n=30, angle=[-80,-110]), width=.05);
//   }
//   //color("black")stroke(arc(n=32,r=r1,angle=[90+bang/2,90]),width=.1,endcaps="arrow2");
//   }
// Figure(2D,Med,VPT=[0.532987,50.0891,0.0383045],VPR=[0,0,0],VPD=53.9078): Here the same gears appear with backlash applied using the `backlash` parameter to {{gear_dist()}} to shift them apart.  
//   teeth1=20;teeth2=33;
//   mod=5;
//   ha=0;
//   r1 = pitch_radius(mod=mod,teeth=teeth1,helical=ha);
//   r2 = pitch_radius(mod=mod,teeth=teeth2,helical=ha);
//   bang=4/(2*PI*r1) * 360 ;
//   shift = 1 * cos(ha)/2/tan(20);
//   back(r1+pitch_radius(mod=mod,teeth=teeth2,helical=ha)){
//      zrot(-180/teeth2/2){
//      %back(shift)spur_gear2d(mod=mod, teeth=teeth2,backlash=0,helical=ha);
//      spur_gear2d(mod=mod, teeth=teeth2,backlash=0,helical=ha);
//      }
//      }
//   zrot(180/teeth1*.5){
//     %fwd(shift)spur_gear2d(mod=mod, teeth=teeth1,backlash=0+.5*0,profile_shift=0,helical=ha);     
//     spur_gear2d(mod=mod, teeth=teeth1,backlash=0,profile_shift=0,helical=ha);
//   }  

// Section: Gears

// Function&Module: spur_gear()
// Synopsis: Creates a spur gear, helical gear, or internal ring gear.
// SynTags: Geom, VNF
// Topics: Gears, Parts
// See Also: rack(), spur_gear(), spur_gear2d(), bevel_gear()
// Usage: As a Module
//   spur_gear(circ_pitch, teeth, thickness, [shaft_diam], [hide=], [pressure_angle=], [clearance=], [backlash=], [helical=], [slices=], [internal=], [herringbone=]) [ATTACHMENTS];
//   spur_gear(mod=, teeth=, thickness=, [shaft_diam=], ...) [ATTACHMENTS];
// Usage: As a Function
//   vnf = spur_gear(circ_pitch, teeth, thickness, [shaft_diam=], ...);
//   vnf = spur_gear(mod=, teeth=, thickness=, [shaft_diam=], ...);
// Description:
//   Creates a involute spur gear, helical gear, or a mask for an internal ring gear.  The module `spur_gear()` gives an involute
//   spur gear, with reasonable defaults for all the parameters.  Normally, you should just choose the
//   first 4 parameters, and let the rest be default values.  Spur gears have straight teeth and
//   mesh together on parallel shafts without creating any axial thrust.  The teeth engage suddenly across their
//   entire width, creating stress and noise.  Helical gears have angled teeth and engage more gradually, so they
//   run more smoothly and quietly, however they do produce thrust along the gear axis.  This can be
//   circumvented using herringbone or double helical gears, which have no axial thrust and also self-align.
//   Helical gears can mesh along shafts that are not parallel, where the angle between the shafts is
//   the sum of the helical angles of the two gears.
//   .
//   The module `spur_gear()` gives a gear in
//   the XY plane, centered on the origin, with one tooth centered on the positive Y axis.  The most
//   important function is `gear_dist()`, which tells how far apart to space gears that are meshing, and
//   `outer_radius()`, which gives the size of the region filled by the gear.  A gear has a "pitch
//   circle", which is an invisible circle that cuts through the middle of each tooth (though not the
//   exact center). In order for two gears to mesh, their pitch circles should just touch.  So the
//   distance between their centers should be `mesh_radius()` for one, plus `mesh_radius()` for the
//   other, which gives the overall meshing distance.  In order for two gears to mesh, they must
//   have the same `pitch` and `pressure_angle` parameters.  `pitch` gives the number of millimeters
//   of arc around the pitch circle covered by one tooth and one space between teeth.  The
//   `pressure_angle` controls how flat or bulged the sides of the teeth are.  Common values include
//   14.5 degrees and 20 degrees, and occasionally 25.  The default here is 20 degrees.
//   The ratio of `teeth` for two meshing gears gives how many times one will make a full revolution
//   when the the other makes one full revolution.  If the two numbers are coprime (i.e.  are not both
//   divisible by the same number greater than 1), then every tooth on one gear will meet every tooth
//   on the other, for more even wear.  So coprime numbers of teeth are good.
//   Normally, If the number of teeth is too few, gear tooth shapes may be undercut to allow meshing
//   with other gears.  If this is the case, profile shifting will automatically be applies to enlarge
//   the teeth, removing the undercut.  This may add to the distance needed between gears.
//   If you with to override this correction, you can use `profile_shift=0`, or set it to a specific
//   value like 0.5.
// Arguments:
//   circ_pitch = The circular pitch, or distance in mm between teeth around the pitch circle.
//   teeth = Total number of teeth around the entire perimeter
//   thickness = Thickness of gear in mm
//   shaft_diam = Diameter of the hole in the center, in mm.  Default: 0 (no shaft hole)
//   ---
//   hide = Number of teeth to delete to make this only a fraction of a circle
//   pressure_angle = Controls how straight or bulged the tooth sides are. In degrees.
//   clearance = Clearance gap at the bottom of the inter-tooth valleys.
//   backlash = Gap between two meshing teeth, in the direction along the circumference of the pitch circle
//   helical = Teeth are slanted around the spur gear at this angle away from the gear axis of rotation.
//   slices = Number of vertical layers to divide gear into.  Useful for refining gears with `helical`.
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  Note that the diametral pitch is a completely different thing than the pitch diameter.
//   mod = The metric module/modulus of the gear, or mm of pitch diameter per tooth.
//   internal = If true, create a mask for difference()ing from something else.
//   profile_shift = Profile shift factor x.  Default: "auto"
//   herringbone = If true, and helical is set, creates a herringbone gear.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Side Effects:
//   If internal is true then the default tag is "remove"
// Example: Spur Gear
//   spur_gear(circ_pitch=5, teeth=20, thickness=8, shaft_diam=5);
// Example: Metric Gear
//   spur_gear(mod=2, teeth=20, thickness=8, shaft_diam=5);
// Example: Helical Gear
//   spur_gear(
//       circ_pitch=5, teeth=20, thickness=10,
//       shaft_diam=5, helical=-30, slices=12,
//       $fa=1, $fs=1
//   );
// Example: Herringbone Gear
//   spur_gear(
//       circ_pitch=5, teeth=20, thickness=10, shaft_diam=5,
//       helical=30, herringbone=true, slices=5
//   );
// Example(Med,VPT=[-0.0213774,2.42972,-0.2709],VPR=[36.1,0,20.1],VPD=74.3596): Effects of Profile Shifting.
//   circ_pitch=5; teeth=7; thick=10; shaft=5; strokewidth=0.2;
//   pr = pitch_radius(circ_pitch, teeth);
//   left(10) {
//       profile_shift = 0;
//       d = gear_dist(circ_pitch=circ_pitch,teeth,0,profile_shift1=profile_shift);
//       back(d) spur_gear(circ_pitch, teeth, thick, shaft, profile_shift=profile_shift);
//       rack(circ_pitch, teeth=3, thickness=thick, orient=BACK);
//       color("black") up(thick/2) linear_extrude(height=0.1) {
//           back(d) dashed_stroke(circle(r=pr), width=strokewidth, closed=true);
//           dashed_stroke([[-7.5,0],[7.5,0]], width=strokewidth);
//       }
//   }
//   right(10) {
//       profile_shift = 0.59;
//       d = gear_dist(circ_pitch=circ_pitch,teeth,0,profile_shift1=profile_shift);
//       back(d) spur_gear(circ_pitch, teeth, thick, shaft, profile_shift=profile_shift);
//       rack(circ_pitch, teeth=3, thickness=thick, orient=BACK);
//       color("black") up(thick/2) linear_extrude(height=0.1) {
//           back(d)
//               dashed_stroke(circle(r=pr), width=strokewidth, closed=true);
//           dashed_stroke([[-7.5,0],[7.5,0]], width=strokewidth);
//       }
//   }
// Example(Anim,Med,Frames=8,VPT=[0,30,0],VPR=[0,0,0],VPD=300): Assembly of Gears
//   $fn=12;
//   n1 = 11; //red gear number of teeth
//   n2 = 20; //green gear
//   n3 = 6;  //blue gear
//   n4 = 16; //orange gear
//   n5 = 9;  //gray rack
//   circ_pitch = 9; //all meshing gears need the same `circ_pitch` (and the same `pressure_angle`)
//   thickness    = 6;
//   hole         = 3;
//   rack_base    = 12;
//   d12 = gear_dist(circ_pitch=circ_pitch,teeth1=n1,teeth2=n2);
//   d13 = gear_dist(circ_pitch=circ_pitch,teeth1=n1,teeth2=n3);
//   d14 = gear_dist(circ_pitch=circ_pitch,teeth1=n1,teeth2=n4);
//   d1r = gear_dist(circ_pitch=circ_pitch,teeth1=n1,teeth2=0);
//   a1 =  $t * 360 / n1;
//   a2 = -$t * 360 / n2 + 180/n2;
//   a3 = -$t * 360 / n3 - 3*90/n3;
//   a4 = -$t * 360 / n4 - 3.5*180/n4;
//   color("#f77")              zrot(a1) spur_gear(circ_pitch,n1,thickness,hole);
//   color("#7f7") back(d12)  zrot(a2) spur_gear(circ_pitch,n2,thickness,hole);
//   color("#77f") right(d13) zrot(a3) spur_gear(circ_pitch,n3,thickness,hole);
//   color("#fc7") left(d14)  zrot(a4) spur_gear(circ_pitch,n4,thickness,hole,hide=n4-3);
//   color("#ccc") fwd(d1r) right(circ_pitch*$t)
//       rack(pitch=circ_pitch,teeth=n5,thickness=thickness,width=rack_base,anchor=CENTER,orient=BACK);
// Example(NoAxes,VPT=[1.13489,-4.48517,1.04995],VPR=[55,0,25],VPD=139.921): Helical gears meshing with non-parallel shafts
//   ang1 = 30;
//   ang2 = 10;
//   circ_pitch = 5;
//   n = 20;
//   dist = gear_dist_skew(
//      circ_pitch=circ_pitch,
//      teeth1=n, teeth2=n,
//      helical1=ang1, helical2=ang2);
//   left(dist/2) spur_gear(
//          circ_pitch, teeth=n, thickness=10,
//          shaft_diam=5, helical=ang1, slices=12,
//          gear_spin=-90
//      );
//   right(dist/2)
//   xrot(ang1+ang2)
//   spur_gear(
//          circ_pitch=circ_pitch, teeth=n, thickness=10,
//          shaft_diam=5, helical=ang2, slices=12,
//          gear_spin=90-180/n
//      );
// Example(Anim,Big,NoAxes,Frames=36,VPT=[0,0,0],VPR=[55,0,25],VPD=220): Planetary Gear Assembly
//   $fn=128;
//   rteeth=56; pteeth=16; cteeth=24;
//   circ_pitch=5; thick=10; pa=20;
//   gd = gear_dist(circ_pitch=circ_pitch, cteeth, pteeth);
//   ring_gear(
//       circ_pitch=circ_pitch,
//       teeth=rteeth,
//       thickness=thick,
//       pressure_angle=pa);
//   for (a=[0:3]) {
//       zrot($t*90+a*90) back(gd) {
//           color("green")
//           spur_gear(
//               circ_pitch=circ_pitch,
//               teeth=pteeth,
//               thickness=thick,
//               shaft_diam=5,
//               pressure_angle=pa,
//               spin=-$t*90*rteeth/pteeth);
//       }
//   }
//   color("orange")
//   zrot($t*90*rteeth/cteeth+$t*90+180/cteeth)
//   spur_gear(
//       circ_pitch=circ_pitch,
//       teeth=cteeth,
//       thickness=thick,
//       shaft_diam=5,
//       pressure_angle=pa);

function spur_gear(
    circ_pitch,
    teeth,
    thickness,
    shaft_diam = 0,
    hide = 0,
    pressure_angle,
    clearance,
    backlash = 0.0,
    helical,
    interior,
    internal,
    profile_shift="auto",
    slices,
    herringbone=false,
    shorten=0,
    diam_pitch,
    mod,
    pitch,
    gear_spin = 0,
    anchor = CENTER,
    spin = 0,
    orient = UP
) =
    let(
        dummy = !is_undef(interior) ? echo("In spur_gear(), the argument 'interior=' has been deprecated, and may be removed in the future.  Please use 'internal=' instead."):0,
        internal = first_defined([internal,interior,false]),
        circ_pitch = _inherit_gear_pitch("spur_gear()", pitch, circ_pitch, diam_pitch, mod),
        PA = _inherit_gear_pa(pressure_angle),
        helical = _inherit_gear_helical(helical, invert=!internal),
        thickness = _inherit_gear_thickness(thickness),
        profile_shift = auto_profile_shift(teeth,PA,helical,profile_shift=profile_shift)
    )
    assert(is_integer(teeth) && teeth>3)
    assert(is_finite(thickness) && thickness>0)
    assert(is_finite(shaft_diam) && shaft_diam>=0)
    assert(is_integer(hide) && hide>=0 && hide<teeth)
    assert(is_finite(PA) && PA>=0 && PA<90, "Bad pressure_angle value.")
    assert(clearance==undef || (is_finite(clearance) && clearance>=0))
    assert(is_finite(backlash) && backlash>=0)
    assert(is_finite(helical) && abs(helical)<90)
    assert(is_bool(herringbone))
    assert(slices==undef || (is_integer(slices) && slices>0))
    assert(is_finite(gear_spin))
    let(
        pr = pitch_radius(circ_pitch, teeth, helical),
        circum = 2 * PI * pr,
        twist = 360*thickness*tan(helical)/circum,
        slices = default(slices, ceil(twist/360*segs(pr)+1)),
        rgn = spur_gear2d(
                circ_pitch = circ_pitch,
                teeth = teeth,
                pressure_angle = PA,
                hide = hide,
                helical = helical,
                clearance = clearance,
                backlash = backlash,
                internal = internal,
                shorten = shorten,
                profile_shift = profile_shift,
                shaft_diam = shaft_diam
            ),
        rvnf = herringbone
          ? zrot(twist/2, p=linear_sweep(rgn, height=thickness, twist=twist, slices=slices, center=true))
          : let(
                wall_vnf = linear_sweep(rgn, height=thickness/2, twist=twist/2, slices=ceil(slices/2), center=false, caps=false),
                cap_vnf = vnf_from_region(rgn, transform=up(thickness/2)*zrot(twist/2))
            )
            vnf_join([
                wall_vnf, zflip(p=wall_vnf),
                cap_vnf,  zflip(p=cap_vnf),
            ]),
        vnf = zrot(gear_spin, p=rvnf)
    ) reorient(anchor,spin,orient, h=thickness, r=pr, p=vnf);


module spur_gear(
    circ_pitch,
    teeth,
    thickness,
    shaft_diam = 0,
    hide = 0,
    pressure_angle,
    clearance,
    backlash = 0.0,
    helical,
    internal,
    interior,
    profile_shift="auto",
    slices,
    herringbone=false,
    shorten=0,
    pitch,
    diam_pitch,
    mod,
    gear_spin = 0,
    anchor = CENTER,
    spin = 0,
    orient = UP
) {
    dummy = !is_undef(interior) ? echo("In spur_gear(), the argument 'interior=' has been deprecated, and may be removed in the future.  Please use 'internal=' instead."):0;
    internal = first_defined([internal,interior,false]);
    circ_pitch = _inherit_gear_pitch("spur_gear()", pitch, circ_pitch, diam_pitch, mod);
    PA = _inherit_gear_pa(pressure_angle);
    helical = _inherit_gear_helical(helical, invert=!internal);
    thickness = _inherit_gear_thickness(thickness);
    profile_shift = auto_profile_shift(teeth,PA,helical,profile_shift=profile_shift);
    checks =
        assert(is_integer(teeth) && teeth>3)
        assert(is_finite(thickness) && thickness>0)
        assert(is_finite(shaft_diam) && shaft_diam>=0)
        assert(is_integer(hide) && hide>=0 && hide<teeth)
        assert(is_finite(PA) && PA>=0 && PA<90, "Bad pressure_angle value.")
        assert(clearance==undef || (is_finite(clearance) && clearance>=0))
        assert(is_finite(backlash) && backlash>=0)
        assert(is_finite(helical) && abs(helical)<90)
        assert(is_bool(herringbone))
        assert(slices==undef || (is_integer(slices) && slices>0))
        assert(is_finite(gear_spin));
    pr = pitch_radius(circ_pitch, teeth, helical);
    circum = 2 * PI * pr;
    twist = 360*thickness*tan(helical)/circum;
    slices = default(slices, ceil(twist/360*segs(pr)+1));
    default_tag("remove", internal) {
        attachable(anchor,spin,orient, r=pr, l=thickness) {
            zrot(gear_spin)
            if (herringbone) {
                zflip_copy() down(0.01)
                linear_extrude(
                    height=thickness/2+0.01, center=false,
                    twist=twist/2, slices=ceil(slices/2),
                    convexity=teeth/2
                ) {
                    spur_gear2d(
                        circ_pitch = circ_pitch,
                        teeth = teeth,
                        pressure_angle = PA,
                        hide = hide,
                        helical = helical,
                        clearance = clearance,
                        backlash = backlash,
                        internal = internal,
                        shorten = shorten, 
                        profile_shift = profile_shift,
                        shaft_diam = shaft_diam
                    );
                }
            } else {
                zrot(twist/2)
                linear_extrude(
                    height=thickness, center=true,
                    twist=twist, slices=slices,
                    convexity=teeth/2
                ) {
                    spur_gear2d(
                        circ_pitch = circ_pitch,
                        teeth = teeth,
                        pressure_angle = PA,
                        hide = hide,
                        helical = helical,
                        clearance = clearance,
                        backlash = backlash,
                        internal = internal,
                        profile_shift = profile_shift,
                        shaft_diam = shaft_diam
                    );
                }
            }
            union() {
                $parent_gear_type = "spur";
                $parent_gear_pitch = circ_pitch;
                $parent_gear_teeth = teeth;
                $parent_gear_pa = PA;
                $parent_gear_helical = helical;
                $parent_gear_thickness = thickness;
                union() children();
            }
        }
    }
}


// Function&Module: spur_gear2d()
// Synopsis: Creates a 2D spur gear or internal ring gear.
// SynTags: Geom, Region
// Topics: Gears, Parts
// See Also: rack(), spur_gear(), spur_gear2d(), bevel_gear()
// Usage: As Module
//   spur_gear2d(circ_pitch, teeth, [hide=], [pressure_angle=], [clearance=], [backlash=], [internal=]) [ATTACHMENTS];
//   spur_gear2d(mod=, teeth=, [hide=], [pressure_angle=], [clearance=], [backlash=], [internal=]) [ATTACHMENTS];
// Usage: As Function
//   rgn = spur_gear2d(circ_pitch, teeth, [hide=], [pressure_angle=], [clearance=], [backlash=], [internal=]);
//   rgn = spur_gear2d(mod=, teeth=, [hide=], [pressure_angle=], [clearance=], [backlash=], [internal=]);
// Description:
//   When called as a module, creates a 2D involute spur gear.  When called as a function,
//   returns a 2D region for the 2D involute spur gear.  Normally, you should just specify the
//   first 2 parameters `circ_pitch` and `teeth`, and let the rest be default values.
//   Meshing gears must match in `circ_pitch`, `pressure_angle`, and `helical`, and be separated by
//   the distance given by {{gear_dist()}}.
// Arguments:
//   circ_pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.
//   teeth = Total number of teeth around the spur gear.
//   hide = Number of teeth to delete to make this only a fraction of a circle
//   pressure_angle = Controls how straight or bulged the tooth sides are. In degrees.
//   ---
//   hide = Number of teeth to delete to make this only a fraction of a circle
//   clearance = Gap between top of a tooth on one gear and bottom of valley on a meshing gear (in millimeters)
//   backlash = Gap between two meshing teeth, in the direction along the circumference of the pitch circle
//   helical = The angle of the rack teeth away from perpendicular to the gear axis of rotation.  Stretches out the tooth shapes.  Used to match helical spur gear pinions.  Default: 0
//   internal = If true, create a mask for difference()ing from something else.
//   profile_shift = Profile shift factor x.  Default: "auto"
//   shaft_diam = If given, the diameter of the central shaft hole.
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  Note that the diametral pitch is a completely different thing than the pitch diameter.
//   mod = The metric module/modulus of the gear, or mm of pitch diameter per tooth.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
// Example(2D): Typical Gear Shape
//   spur_gear2d(circ_pitch=5, teeth=20, shaft_diam=5);
// Example(2D): By Metric Module
//   spur_gear2d(mod=2, teeth=20, shaft_diam=5);
// Example(2D): By Imperial Gear Pitch
//   spur_gear2d(diam_pitch=10, teeth=20, shaft_diam=5);
// Example(2D): Lower Pressure Angle
//   spur_gear2d(circ_pitch=5, teeth=20, pressure_angle=14);
// Example(2D): Partial Gear
//   spur_gear2d(circ_pitch=5, teeth=20, hide=15, pressure_angle=20);
// Example(2D,Med,VPT=[0.151988,3.93719,1.04995],VPR=[0,0,0],VPD=74.3596): Effects of Profile Shifting.
//   circ_pitch=5; teeth=7; shaft=5; strokewidth=0.2;
//   module the_gear(profile_shift=0) {
//       $fn=72;
//       pr = pitch_radius(circ_pitch,teeth);
//       mr = gear_dist(circ_pitch=circ_pitch,teeth,profile_shift1=profile_shift,teeth2=0);
//       back(mr) {
//           spur_gear2d(circ_pitch, teeth, shaft_diam=shaft, profile_shift=profile_shift);
//           up(0.1) color("black")
//               dashed_stroke(circle(r=pr), width=strokewidth, closed=true);
//       }
//   }
//   module the_rack() {
//       $fn=72;
//       rack2d(circ_pitch, teeth=3);
//       up(0.1) color("black")
//           dashed_stroke([[-7.5,0],[7.5,0]], width=strokewidth);
//   }
//   left(10) { the_gear(0); the_rack(); }
//   right(10) { the_gear(0.59); the_rack(); }
// Example(2D): Planetary Gear Assembly
//   rteeth=56; pteeth=16; cteeth=24;
//   circ_pitch=5; pa=20;
//   gd = gear_dist(circ_pitch=circ_pitch, cteeth,pteeth);
//   ring_gear2d(
//       circ_pitch=circ_pitch,
//       teeth=rteeth,
//       pressure_angle=pa);
//   for (a=[0:3]) {
//       zrot(a*90) back(gd) {
//           color("green")
//           spur_gear2d(
//               circ_pitch=circ_pitch,
//               teeth=pteeth,
//               pressure_angle=pa);
//       }
//   }
//   color("orange")
//     zrot(180/cteeth)
//       spur_gear2d(
//           circ_pitch=circ_pitch,
//           teeth=cteeth,
//           pressure_angle=pa);
// Example(2D): Called as a Function
//   rgn = spur_gear2d(circ_pitch=8, teeth=16, shaft_diam=5);
//   region(rgn);

function spur_gear2d(
    circ_pitch,
    teeth,
    hide = 0,
    pressure_angle,
    clearance,
    backlash = 0.0,
    internal,
    interior,
    profile_shift="auto",
    helical,
    shaft_diam = 0,
    shorten = 0, 
    pitch,
    diam_pitch,
    mod,
    gear_spin = 0,
    anchor = CENTER,
    spin = 0
) = let(
        dummy = !is_undef(interior) ? echo("In spur_gear2d(), the argument 'interior=' has been deprecated, and may be removed in the future.  Please use 'internal=' instead."):0,
        internal = first_defined([internal,interior,false]),
        circ_pitch = _inherit_gear_pitch("spur_gear2d()", pitch, circ_pitch, diam_pitch, mod),
        PA = _inherit_gear_pa(pressure_angle),
        helical = _inherit_gear_helical(helical, invert=!internal),
        profile_shift = auto_profile_shift(teeth,PA,helical,profile_shift=profile_shift)
    )
    assert(is_integer(teeth) && teeth>3)
    assert(is_finite(shaft_diam) && shaft_diam>=0)
    assert(is_integer(hide) && hide>=0 && hide<teeth)
    assert(is_finite(PA) && PA>=0 && PA<90, "Bad pressure_angle value.")
    assert(clearance==undef || (is_finite(clearance) && clearance>=0))
    assert(is_finite(backlash) && backlash>=0)
    assert(is_finite(helical) && abs(helical)<90)
    assert(is_finite(gear_spin))
    let(
        pr = pitch_radius(circ_pitch, teeth, helical=helical),
        tooth = _gear_tooth_profile(
                circ_pitch=circ_pitch,
                teeth=teeth,
                pressure_angle=PA,
                clearance=clearance,
                backlash=backlash,
                profile_shift=profile_shift,
                helical=helical,
                shorten=shorten,
                internal=internal
            ),
        perim = [
            for (i = [0:1:teeth-1-hide])
                each zrot(-i*360/teeth+gear_spin, p=tooth),
            if (hide>0) [0,0],
        ],
        rgn = [
            list_unwrap(deduplicate(perim)),
            if (shaft_diam>0 && !hide)
                reverse(circle(d=shaft_diam, $fn=max(16,segs(shaft_diam/2)))),
        ]
    ) reorient(anchor,spin, two_d=true, r=pr, p=rgn);


module spur_gear2d(
    circ_pitch,
    teeth,
    hide = 0,
    pressure_angle,
    clearance,
    backlash = 0.0,
    internal,
    interior,
    profile_shift="auto",
    helical,
    shorten = 0, 
    shaft_diam = 0,
    pitch,
    diam_pitch,
    mod,
    gear_spin = 0,
    anchor = CENTER,
    spin = 0
) {
    dummy = !is_undef(interior) ? echo("In spur_gear2d(), the argument 'interior=' has been deprecated, and may be removed in the future.  Please use 'internal=' instead."):0;
    internal = first_defined([internal,interior,false]);
    circ_pitch = _inherit_gear_pitch("spur_gear2d()", pitch, circ_pitch, diam_pitch, mod);
    PA = _inherit_gear_pa(pressure_angle);
    helical = _inherit_gear_helical(helical, invert=!internal);
    profile_shift = auto_profile_shift(teeth,PA,helical,profile_shift=profile_shift);
    checks =
        assert(is_integer(teeth) && teeth>3)
        assert(is_finite(shaft_diam) && shaft_diam>=0)
        assert(is_integer(hide) && hide>=0 && hide<teeth)
        assert(is_finite(PA) && PA>=0 && PA<90, "Bad pressure_angle value.")
        assert(clearance==undef || (is_finite(clearance) && clearance>=0))
        assert(is_finite(backlash) && backlash>=0)
        assert(is_finite(helical) && abs(helical)<90)
        assert(is_finite(gear_spin));
    rgn = spur_gear2d(
        circ_pitch = circ_pitch,
        teeth = teeth,
        hide = hide,
        pressure_angle = PA,
        clearance = clearance,
        helical = helical,
        backlash = backlash,
        profile_shift = profile_shift,
        internal = internal,
        shorten = shorten, 
        shaft_diam = shaft_diam
    );
    pr = pitch_radius(circ_pitch, teeth, helical=helical);
    attachable(anchor,spin, two_d=true, r=pr) {
        zrot(gear_spin) region(rgn);
        union() {
            $parent_gear_type = "spur2D";
            $parent_gear_pitch = circ_pitch;
            $parent_gear_teeth = teeth;
            $parent_gear_pa = PA;
            $parent_gear_helical = helical;
            $parent_gear_thickness = 0;
            union() children();
        }
    }
}


// Module: ring_gear()
// Synopsis: Creates a 3D ring gear.
// SynTags: Geom
// Topics: Gears, Parts
// See Also: rack(), ring_gear2d(), spur_gear(), spur_gear2d(), bevel_gear()
// Usage:
//   ring_gear(circ_pitch, teeth, thickness, [backing|od=|or=|width=], [pressure_angle=], [helical=], [herringbone=], [profile_shift=], [clearance=], [backlash=]) [ATTACHMENTS];
//   ring_gear(mod=, teeth=, thickness=, [backing=|od=|or=|width=], [pressure_angle=], [helical=], [herringbone=], [profile_shift=], [clearance=], [backlash=]) [ATTACHMENTS];
//   ring_gear(diam_pitch=, teeth=, thickness=, [backing=|od=|or=|width=], [pressure_angle=], [helical=], [herringbone=], [profile_shift=], [clearance=], [backlash=]) [ATTACHMENTS];
// Description:
//   Creates a 3D involute ring gear.
//   Meshing gears must have the same tooth size, pressure angle and helical angle as usual.
//   Additionally, you must have more teeth on an internal gear than its mating external gear, and
//   the profile shift on the ring gear must be at least as big as the profile shift on the mating gear.
//   You may need to use {{auto_profile_shift()}} to find this value if your mating gear has a small number of teeth.
//   The gear spacing is given by {{gear_dist()}}.
// Arguments:
//   circ_pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.
//   teeth = Total number of teeth around the spur gear.
//   thickness = Thickness of ring gear in mm
//   backing = The width of the ring gear backing.  Default: height of teeth
//   ---
//   od = outer diameter of the ring
//   or = outer radius of the ring
//   width = width of the ring, measuring from tips of teeth to outside of ring.  
//   pressure_angle = Controls how straight or bulged the tooth sides are. In degrees.
//   helical = The angle of the rack teeth away from perpendicular to the gear axis of rotation.  Stretches out the tooth shapes.  Used to match helical spur gear pinions.  Default: 0
//   herringbone = If true, and helical is set, creates a herringbone gear.
//   profile_shift = Profile shift factor x for tooth profile.  Default: 0
//   clearance = Gap between top of a tooth on one gear and bottom of valley on a meshing gear (in millimeters)
//   backlash = Gap between two meshing teeth, in the direction along the circumference of the pitch circle
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  Note that the diametral pitch is a completely different thing than the pitch diameter.
//   mod = The metric module/modulus of the gear, or mm of pitch diameter per tooth.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Example:
//   ring_gear(circ_pitch=5, teeth=48, thickness=10);
// Example: Adjusting Backing
//   ring_gear(circ_pitch=5, teeth=48, thickness=10, backing=30);
// Example(Med): Adjusting Pressure Angle
//   ring_gear(circ_pitch=5, teeth=48, thickness=10, pressure_angle=28);
// Example(Med): Tooth Profile Shifting
//   ring_gear(circ_pitch=5, teeth=48, thickness=10, profile_shift=0.5);
// Example(Med): Helical Ring Gear
//   ring_gear(circ_pitch=5, teeth=48, thickness=15, helical=30);
// Example(Med): Herringbone Ring Gear
//   ring_gear(circ_pitch=5, teeth=48, thickness=30, helical=30, herringbone=true);

module ring_gear(
    circ_pitch,
    teeth,
    thickness = 10,
    backing,
    pressure_angle,
    helical,
    herringbone = false,
    profile_shift=0,
    clearance,
    backlash = 0.0,
    or,od,width,
    pitch,
    diam_pitch,
    mod,
    slices,
    gear_spin = 0,
    anchor = CENTER,
    spin = 0,
    orient = UP
) {
    circ_pitch = _inherit_gear_pitch("ring_gear()",pitch, circ_pitch, diam_pitch, mod);
    PA = _inherit_gear_pa(pressure_angle);
    helical = _inherit_gear_helical(helical);       //Maybe broken???
    thickness = _inherit_gear_thickness(thickness);
    checks =
        assert(is_finite(profile_shift), "Profile shift for ring gears must be numerical")
        assert(is_integer(teeth) && teeth>3)
        assert(is_finite(thickness) && thickness>0)
        assert(is_finite(PA) && PA>=0 && PA<90, "Bad pressure_angle value.")
        assert(is_finite(helical) && abs(helical)<90)
        assert(is_bool(herringbone))
        assert(clearance==undef || (is_finite(clearance) && clearance>=0))
        assert(is_finite(backlash) && backlash>=0)
        assert(slices==undef || (is_integer(slices) && slices>0))
        assert(num_defined([backing,or,od,width])<=1, "Cannot define more than one of backing, or, od and width")
        assert(is_finite(gear_spin));
    pr = pitch_radius(circ_pitch, teeth, helical=helical);
    ar = outer_radius(circ_pitch, teeth, helical=helical, profile_shift=profile_shift, internal=true);
    rr=_root_radius(circ_pitch, teeth, clearance, profile_shift=profile_shift, internal=true);
    or = is_def(or) ?
            assert(is_finite(or) && or>ar, "or is invalid or too small for teeth")
            or
       : is_def(od) ?
            assert(is_finite(od) && od>2*ar, "od is invalid or too small for teeth")
            od/2
       : is_def(width) ?
            assert(is_finite(width) && width>ar-rr, "width is invalid or too small for teeth")
            rr+width
       : is_def(backing) ?
            assert(all_positive([backing]), "backing must be a positive value")
            ar+backing
       : 2*ar - rr;    // default case
    circum = 2 * PI * pr;
    twist = 360*thickness*tan(-helical)/circum;
    slices = default(slices, ceil(twist/360*segs(pr)+1));
    attachable(anchor,spin,orient, h=thickness, r=pr) {
        zrot(gear_spin)
        if (herringbone) {
            zflip_copy() down(0.01)
            linear_extrude(height=thickness/2, center=false, twist=twist/2, slices=ceil(slices/2), convexity=teeth/4) {
                difference() {
                    circle(r=or);
                    spur_gear2d(
                        circ_pitch = circ_pitch,
                        teeth = teeth,
                        pressure_angle = PA,
                        helical = helical,
                        clearance = clearance,
                        backlash = backlash,
                        profile_shift = profile_shift,
                        internal = true
                    );
                }
            }
        } else {
            zrot(twist/2)
            linear_extrude(height=thickness,center=true, twist=twist, convexity=teeth/4) {
                difference() {
                    circle(r=or);
                    spur_gear2d(
                        circ_pitch = circ_pitch,
                        teeth = teeth,
                        pressure_angle = PA,
                        helical = helical,
                        clearance = clearance,
                        backlash = backlash,
                        profile_shift = profile_shift,
                        internal = true
                    );
                }
            }
        }
        children();
    }
}


// Module: ring_gear2d()
// Synopsis: Creates a 2D ring gear.
// SynTags: Geom
// Topics: Gears, Parts
// See Also: rack(), spur_gear(), spur_gear2d(), bevel_gear()
// Usage:
//   ring_gear2d(circ_pitch, teeth, [backing|od=|or=|width=], [pressure_angle=], [helical=], [profile_shift=], [clearance=], [backlash=]) [ATTACHMENTS];
//   ring_gear2d(mod=, teeth=, [backing=|od=|or=|width=], [pressure_angle=], [helical=], [profile_shift=], [clearance=], [backlash=]) [ATTACHMENTS];
//   ring_gear2d(diam_pitch=, teeth=, [backing=|od=|or=|width=], [pressure_angle=], [helical=], [profile_shift=], [clearance=], [backlash=]) [ATTACHMENTS];
// Description:
//   Creates a 2D involute ring gear.  
//   Meshing gears must have the same tooth size, pressure angle and helical angle as usual.
//   Additionally, you must have more teeth on an internal gear than its mating external gear, and
//   the profile shift on the ring gear must be at least as big as the profile shift on the mating gear.
//   You may need to use {{auto_profile_shift()}} to find this value if your mating gear has a small number of teeth.
//   The gear spacing is given by {{gear_dist()}}.
// Arguments:
//   circ_pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.
//   teeth = Total number of teeth around the spur gear.
//   backing = The width of the ring gear backing.  Default: height of teeth
//   ---
//   od = outer diameter of the ring
//   or = outer radius of the ring
//   width = width of the ring, measuring from tips of teeth to outside of ring.  
//   helical = The angle of the rack teeth away from perpendicular to the gear axis of rotation.  Stretches out the tooth shapes.  Used to match helical spur gear pinions.  Default: 0
//   pressure_angle = Controls how straight or bulged the tooth sides are. In degrees.
//   profile_shift = Profile shift factor x for tooth profile.  Default: 0
//   clearance = Gap between top of a tooth on one gear and bottom of valley on a meshing gear (in millimeters)
//   backlash = Gap between two meshing teeth, in the direction along the circumference of the pitch circle
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  Note that the diametral pitch is a completely different thing than the pitch diameter.
//   mod = The metric module/modulus of the gear, or mm of pitch diameter per tooth.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
// Example(2D,Big):  Meshing a ring gear with a spur gear
//   circ_pitch=5; teeth1=50; teeth2=18;
//   dist = gear_dist(circ_pitch=circ_pitch, teeth1, teeth2, internal1=true);
//   ring_gear2d(circ_pitch=circ_pitch, teeth=teeth1);
//   color("lightblue")back(dist)
//     spur_gear2d(circ_pitch=circ_pitch, teeth=teeth2);
// Example(2D,Med,VPT=[-0.117844,-0.439102,-0.372203],VPR=[0,0,0],VPD=192.044): Meshing a ring gear with an auto-profile-shifted spur gear:
//   teeth1=7;    teeth2=15;
//   ps1=undef;     // Allow auto profile shifting for first gear
//   ps2=auto_profile_shift(teeth=teeth1);
//   mod=3;
//   d = gear_dist(mod=mod, teeth1=teeth1, teeth2=teeth2, profile_shift1=ps1, profile_shift2=ps2, internal2=true);
//   ring_gear2d(mod=mod, teeth=teeth2,profile_shift=ps2);
//   color("lightblue") fwd(d)
//      spur_gear2d(mod=mod, teeth=teeth1, profile_shift=ps1);

module ring_gear2d(
    circ_pitch,
    teeth,
    backing,
    pressure_angle,
    helical,
    profile_shift=0,
    clearance,
    backlash = 0.0,
    or,od,width,
    pitch,
    diam_pitch,
    mod,
    gear_spin = 0,
    anchor = CENTER,
    spin = 0
) {
    circ_pitch = _inherit_gear_pitch("ring_gear2d()",pitch, circ_pitch, diam_pitch, mod);
    PA = _inherit_gear_pa(pressure_angle);
    helical = _inherit_gear_helical(helical);
    checks =
        assert(is_finite(profile_shift), "Profile shift for ring gears must be numerical")
        assert(is_integer(teeth) && teeth>3)
        assert(num_defined([backing,or,od,width])<=1, "Cannot define more than one of backing, or, od and width")
        assert(is_finite(PA) && PA>=0 && PA<90, "Bad pressure_angle value.")
        assert(is_finite(helical) && abs(helical)<90)
        assert(clearance==undef || (is_finite(clearance) && clearance>=0))
        assert(is_finite(backlash) && backlash>=0)
        assert(is_finite(gear_spin));
    pr = pitch_radius(circ_pitch, teeth, helical=helical);
    ar = outer_radius(circ_pitch, teeth, helical=helical, profile_shift=profile_shift, internal=true);
    rr=_root_radius(circ_pitch, teeth, clearance, profile_shift=profile_shift, internal=true);
    or = is_def(or) ?
            assert(is_finite(or) && or>ar, "or is invalid or too small for teeth")
            or
       : is_def(od) ?
            assert(is_finite(od) && od>2*ar, "od is invalid or too small for teeth")
            od/2
       : is_def(width) ?
            assert(is_finite(width) && width>ar-rr, "width is invalid or too small for teeth")
            rr+width
       : is_def(backing) ?
            assert(all_positive([backing]), "backing must be a positive value")
            ar+backing
       : 2*ar - rr;    // default case
    attachable(anchor,spin, two_d=true, r=pr) {
        zrot(gear_spin)
        difference() {
            circle(r=or);
            spur_gear2d(
                circ_pitch = circ_pitch,
                teeth = teeth,
                pressure_angle = PA,
                helical = helical,
                clearance = clearance,
                backlash = backlash,
                profile_shift = profile_shift,
                internal = true 
            );
        }
        children();
    }
}




// Function&Module: rack()
// Synopsis: Creates a straight or helical gear rack.
// SynTags: Geom, VNF
// Topics: Gears, Parts
// See Also: rack2d(), spur_gear(), spur_gear2d(), bevel_gear()
// Usage: As a Module
//   rack(pitch, teeth, thickness, [base|bottom=|width=], [helical=], [pressure_angle=], [backlash=], [clearance=]) [ATTACHMENTS];
//   rack(mod=, teeth=, thickness=, [base=|bottom=|width=], [helical=], [pressure_angle=], [backlash]=, [clearance=]) [ATTACHMENTS];
// Usage: As a Function
//   vnf = rack(pitch, teeth, thickness, [base|bottom=|width=], [helical=], [pressure_angle=], [backlash=], [clearance=]);
//   vnf = rack(mod=, teeth=, thickness=, [base=|bottom=|width=], [helical=], [pressure_angle=], [backlash=], [clearance=]);
// Description:
//   This is used to create a 3D rack, which is a linear bar with teeth that a gear can roll along.
//   A rack can mesh with any gear that has the same `pitch` and `pressure_angle`.  A helical rack meshes with a gear with the opposite
//   helical angle.   The rack appears oriented with
//   its teeth pointed UP, so it will need to be oriented to mesh with gears.  
//   The pitch line of the rack is aligned with the x axis.  
//   When called as a function, returns a 3D [VNF](vnf.scad) for the rack.
//   When called as a module, creates a 3D rack shape.
//   .
//   By default the rack has a backing whose height is equal to the height of the teeth.  You can specify a different backing size
//   or you can specify the total width of the rack (from the bottom of the rack to tooth tips) or the
//   bottom point of the rack, which is the distance from the pitch line to the bottom of the rack.  
// Arguments:
//   pitch = The pitch, or distance in mm between teeth along the rack. Matches up with circular pitch on a spur gear.  Default: 5
//   teeth = Total number of teeth along the rack.  Default: 20
//   thickness = Thickness of rack in mm (affects each tooth).  Default: 5
//   backing = Distance from bottom of rack to the roots of the rack's teeth.  (Alternative to bottom or width.)  Default: height of rack teeth
//   ---
//   bottom = Distance from rack's pitch line (the x-axis) to the bottom of the rack.  (Alternative to backing or width)
//   width = Distance from base of rack to tips of teeth (alternative to bottom and backing).
//   mod = The metric module/modulus of the gear, or mm of pitch diameter per tooth.
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  Note that the diametral pitch is a completely different thing than the pitch diameter.
//   helical = The angle of the rack teeth away from perpendicular to the rack length.  Used to match helical spur gear pinions.  Default: 0
//   herringbone = If true, and helical is set, creates a herringbone rack.
//   profile_shift = Profile shift factor x.  Default: 0
//   pressure_angle = Controls how straight or bulged the tooth sides are. In degrees.  Default: 20
//   backlash = Gap between two meshing teeth, in the direction along the circumference of the pitch circle.  Default: 0
//   clearance = Clearance gap at the bottom of the inter-tooth valleys.  Default: module/4
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Extra Anchors:
//   "tip" = At the tips of the teeth, at the center of rack.
//   "tip-left" = At the tips of the teeth, at the left end of the rack.
//   "tip-right" = At the tips of the teeth, at the right end of the rack.
//   "tip-back" = At the tips of the teeth, at the back of the rack.
//   "tip-front" = At the tips of the teeth, at the front of the rack.
//   "root" = At the base of the teeth, at the center of rack.
//   "root-left" = At the base of the teeth, at the left end of the rack.
//   "root-right" = At the base of the teeth, at the right end of the rack.
//   "root-back" = At the base of the teeth, at the back of the rack.
//   "root-front" = At the base of the teeth, at the front of the rack.
// Example(NoScales,VPR=[60,0,325],VPD=130):
//   rack(pitch=5, teeth=10, thickness=5);
// Example(NoScales,VPT=[0.317577,3.42688,7.83665],VPR=[27.7,0,359.8],VPD=139.921): Rack for Helical Gear
//   rack(pitch=5, teeth=10, thickness=5, backing=5, helical=30);
// Example(NoScales): Metric Rack, oriented BACK to align with a gear in default orientation
//   rack(mod=2, teeth=10, thickness=5, bottom=5, pressure_angle=14.5,orient=BACK);
// Example(NoScales,Anim,VPT=[0,0,12],VPD=100,Frames=18): Rack and Pinion with helical teeth
//   teeth1 = 16; teeth2 = 16;
//   pitch = 5; thick = 5; helical = 30;
//   pr = pitch_radius(pitch, teeth2, helical=helical);
//   pos = 3*(1-2*abs($t-1/2))-1.5;
//   right(pr*2*PI/teeth2*pos)
//       rack(pitch, teeth1, thickness=thick, helical=helical);
//   up(pr)
//       spur_gear(
//           pitch, teeth2,
//           thickness = thick,
//           helical = -helical,
//           shaft_diam = 5,
//           orient = BACK,
//           gear_spin = 180-pos*360/teeth2);
// Example(NoAxes,VPT=[-7.10396,-9.70691,3.50121],VPR=[60.2,0,325],VPD=213.262): Skew axis helical gear and rack engagement.
//    mod=5; teeth=8; helical1=17.5; helical2=22.5;
//    d = gear_dist_skew(mod=mod, teeth, 0, helical1,helical2);
//    rack(mod=mod, teeth=5, thickness=30, helical=helical2, orient=FWD);
//    color("lightblue")
//      yrot(-helical1-helical2) fwd(d)
//      spur_gear(mod=mod, teeth=teeth, helical=helical1, gear_spin=180/teeth, thickness=30);

module rack(
    pitch,
    teeth,
    thickness,
    backing,
    width, bottom,
    pressure_angle,
    backlash = 0.0,
    clearance,
    helical,
    herringbone = false,
    profile_shift = 0,
    gear_travel = 0,
    circ_pitch,
    diam_pitch,
    mod,
    anchor = CENTER,
    spin = 0,
    orient = UP
) {
    pitch = _inherit_gear_pitch("rack()",pitch, circ_pitch, diam_pitch, mod, warn=false);
    PA = _inherit_gear_pa(pressure_angle);
    helical = _inherit_gear_helical(helical);
    thickness = _inherit_gear_thickness(thickness);
    checks=
        assert(is_integer(teeth) && teeth>0)
        assert(is_finite(thickness) && thickness>0)
        assert(is_finite(PA) && PA>=0 && PA<90, "Bad pressure_angle value.")
        assert(clearance==undef || (is_finite(clearance) && clearance>=0))
        assert(is_finite(backlash) && backlash>=0)
        assert(is_finite(helical) && abs(helical)<90)
        assert(is_bool(herringbone))
        assert(is_finite(profile_shift))
        assert(is_finite(gear_travel));
    trans_pitch = pitch / cos(helical);
    a = _adendum(pitch, profile_shift);
    d = _dedendum(pitch, clearance, profile_shift);
    bottom = is_def(bottom) ?
                 assert(is_finite(bottom) && bottom>d, "bottom is invalid or too small for teeth")
                 bottom
           : is_def(width) ?
                 assert(is_finite(width) && width>a+d, "Width is invalid or too small for teeth")
                 width - a
           : is_def(backing) ?
                 assert(all_positive([backing]), "Backing must be a positive value")
                 backing+d
           : 2*d+a;  // default case
    l = teeth * trans_pitch;
    anchors = [
        named_anchor("tip",         [0,0,a],             BACK),
        named_anchor("tip-left",    [-l/2,0,a],          LEFT),
        named_anchor("tip-right",   [ l/2,0,a],          RIGHT),
        named_anchor("tip-front",   [0,-thickness/2,a],  DOWN),
        named_anchor("tip-back",    [0, thickness/2,a],  UP),
        named_anchor("root",        [0,0,-d],            BACK),
        named_anchor("root-left",   [-l/2,0,-d],         LEFT),
        named_anchor("root-right",  [ l/2,0,-d],         RIGHT),
        named_anchor("root-front",  [0,-thickness/2,-d], DOWN),
        named_anchor("root-back",   [0, thickness/2,-d], UP),
    ];
    size = [l, thickness, 2*bottom];
    attachable(anchor,spin,orient, size=size, anchors=anchors) {
        right(gear_travel)
        xrot(90) {
            if (herringbone) {
                zflip_copy()
                skew(axz=-helical) down(0.01)
                linear_extrude(height=thickness/2, center=false, convexity=teeth*2) {
                    rack2d(
                        pitch = pitch,
                        teeth = teeth,
                        bottom = bottom,
                        pressure_angle = PA,
                        backlash = backlash,
                        clearance = clearance,
                        helical = helical,
                        profile_shift = profile_shift
                    );
                }
            } else {
                skew(axz=helical)
                linear_extrude(height=thickness, center=true, convexity=teeth*2) {
                    rack2d(
                        pitch = pitch,
                        teeth = teeth,
                        bottom = bottom,
                        pressure_angle = PA,
                        backlash = backlash,
                        clearance = clearance,
                        helical = helical,
                        profile_shift = profile_shift
                    );
                }
            }
        }
        children();
    }
}


function rack(
    pitch,
    teeth,
    thickness,
    backing, bottom, width, 
    pressure_angle,
    backlash = 0.0,
    clearance,
    helical,
    herringbone = false,
    profile_shift = 0,
    circ_pitch,
    diam_pitch,
    mod,
    gear_travel = 0,
    anchor = CENTER,
    spin = 0,
    orient = UP
) =
    let(
        pitch = _inherit_gear_pitch("rack()",pitch, circ_pitch, diam_pitch, mod, warn=false),
        PA = _inherit_gear_pa(pressure_angle),
        helical = _inherit_gear_helical(helical),
        thickness = _inherit_gear_thickness(thickness)
    )
    assert(is_integer(teeth) && teeth>0)
    assert(is_finite(thickness) && thickness>0)
    assert(is_finite(PA) && PA>=0 && PA<90, "Bad pressure_angle value.")
    assert(clearance==undef || (is_finite(clearance) && clearance>=0))
    assert(is_finite(backlash) && backlash>=0)
    assert(is_finite(helical) && abs(helical)<90)
    assert(is_bool(herringbone))
    assert(is_finite(profile_shift))
    assert(is_finite(gear_travel))
    let(
        trans_pitch = pitch / cos(helical),
        a = _adendum(pitch, profile_shift),
        d = _dedendum(pitch, clearance, profile_shift),
        bottom = is_def(bottom) ?
                     assert(is_finite(bottom) && bottom>d, "bottom is invalid or too small for teeth")
                     bottom
               : is_def(width) ?
                     assert(is_finite(width) && width>a+d, "Width is invalid or too small for teeth")
                     width - a
               : is_def(backing) ?
                     assert(all_positive([backing]), "Backing must be a positive value")
                     backing+d
               : 2*d+a,  // default case
        l = teeth * trans_pitch,
        path = rack2d(
            pitch = pitch,
            teeth = teeth,
            bottom = bottom,
            pressure_angle = PA,
            backlash = backlash,
            clearance = clearance,
            helical = helical,
            profile_shift = profile_shift
        ),
        vnf = herringbone
          ? sweep(path, [
                left(adj_ang_to_opp(thickness/2,helical)) *
                    back(thickness/2) * xrot(90),
                xrot(90),
                left(adj_ang_to_opp(thickness/2,helical)) *
                    fwd(thickness/2) * xrot(90),
            ], style="alt", orient=FWD)
          : skew(axy=-helical, p=linear_sweep(path, height=thickness, anchor="origin", orient=FWD)),
        out = right(gear_travel, p=vnf),
        size = [l, thickness, 2*bottom],
        anchors = [
            named_anchor("tip",         [0,0,a],             BACK),
            named_anchor("tip-left",    [-l/2,0,a],          LEFT),
            named_anchor("tip-right",   [ l/2,0,a],          RIGHT),
            named_anchor("tip-front",   [0,-thickness/2,a],  DOWN),
            named_anchor("tip-back",    [0, thickness/2,a],  UP),
            named_anchor("root",        [0,0,-d],            BACK),
            named_anchor("root-left",   [-l/2,0,-d],         LEFT),
            named_anchor("root-right",  [ l/2,0,-d],         RIGHT),
            named_anchor("root-front",  [0,-thickness/2,-d], DOWN),
            named_anchor("root-back",   [0, thickness/2,-d], UP),
        ]
    ) reorient(anchor,spin,orient, size=size, anchors=anchors, p=out);




// Function&Module: rack2d()
// Synopsis: Creates a 2D gear rack.
// SynTags: Geom, Path
// Topics: Gears, Parts
// See Also: rack(), spur_gear(), spur_gear2d(), bevel_gear()
// Usage: As a Module
//   rack2d(pitch, teeth, [base|bottom=|width=], [pressure_angle=], [backlash=], [clearance=]) [ATTACHMENTS];
//   rack2d(mod=, teeth=, [base=|bottom=|width=], [pressure_angle=], [backlash=], [clearance=]) [ATTACHMENTS];
// Usage: As a Function
//   path = rack2d(pitch, teeth, [base|bottom=|width=], [pressure_angle=], [backlash=], [clearance=]);
//   path = rack2d(mod=, teeth=, [base=|bottom=|width=], [pressure_angle=], [backlash=], [clearance=]);
// Description:
//   Create a 2D rack, a linear bar with teeth that a gear can roll along.
//   A rack can mesh with any spur gear or helical gear that has the same `pitch` and `pressure_angle`.  
//   When called as a function, returns a 2D path for the outline of the rack.
//   When called as a module, creates a 2D rack shape.
//   .
//   By default the rack has a backing whose height is equal to the height of the teeth.  You can specify a different backing size
//   or you can specify the total width of the rack (from the bottom of the rack to tooth tips) or the
//   bottom point of the rack, which is the distance from the pitch line to the bottom of the rack.  
// Arguments:
//   pitch = The pitch, or distance in mm between teeth along the rack. Matches up with circular pitch on a spur gear.  Default: 5
//   teeth = Total number of teeth along the rack
//   backing = Distance from bottom of rack to the roots of the rack's teeth.  (Alternative to bottom or width.)  Default: height of rack teeth
//   ---
//   bottom = Distance from rack's pitch line (the x-axis) to the bottom of the rack.  (Alternative to backing or width)
//   width = Distance from base of rack to tips of teeth (alternative to bottom and backing).
//   mod = The metric module/modulus of the gear, or mm of pitch diameter per tooth.
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  Note that the diametral pitch is a completely different thing than the pitch diameter.
//   helical = The angle of the rack teeth away from perpendicular to the rack length.  Stretches out the tooth shapes.  Used to match helical spur gear pinions.  Default: 0
//   pressure_angle = Controls how straight or bulged the tooth sides are. In degrees.
//   profile_shift = Profile shift factor x for tooth shape.  Default: 0
//   backlash = Gap between two meshing teeth, in the direction along the circumference of the pitch circle
//   clearance = Clearance gap at the bottom of the inter-tooth valleys.  Default: module/4
//   gear_travel = The distance the rack should be moved by linearly.  Default: 0
//   rounding = If true, rack tips and valleys are slightly rounded.  Default: true
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
// Extra Anchors:
//   "tip" = At the tips of the teeth, at the center of rack.
//   "tip-left" = At the tips of the teeth, at the left end of the rack.
//   "tip-right" = At the tips of the teeth, at the right end of the rack.
//   "root" = At the height of the teeth, at the center of rack.
//   "root-left" = At the height of the teeth, at the left end of the rack.
//   "root-right" = At the height of the teeth, at the right end of the rack.
// Example(2D):
//   rack2d(pitch=5, teeth=10);
// Example(2D): Called as a Function
//   path = rack2d(pitch=8, teeth=8, pressure_angle=25);
//   polygon(path);

function rack2d(
    pitch,
    teeth,
    backing,
    pressure_angle,
    backlash = 0,
    clearance,
    helical,
    profile_shift = 0,
    circ_pitch,
    diam_pitch,
    mod,
    width, bottom,
    gear_travel = 0,
    rounding = true,
    anchor = CENTER,
    spin = 0
) = let(
        pitch = _inherit_gear_pitch("rack2d()",pitch, circ_pitch, diam_pitch, mod, warn=false),
        PA = _inherit_gear_pa(pressure_angle),
        helical = _inherit_gear_helical(helical),
        mod = module_value(circ_pitch=pitch)
    )
    assert(is_integer(teeth) && teeth>0)
    assert(is_finite(PA) && PA>=0 && PA<90, "Bad pressure_angle value.")
    assert(clearance==undef || (is_finite(clearance) && clearance>=0))
    assert(is_finite(backlash) && backlash>=0)
    assert(is_finite(helical) && abs(helical)<90)
    assert(is_finite(gear_travel))
    assert(num_defined([width,backing,bottom])<=1, "Can define only one of width, backing and bottom")
    let(
        adendum = _adendum(pitch, profile_shift),
        dedendum = _dedendum(pitch, clearance, profile_shift),
        clear = default(clearance, 0.25 * mod),
        bottom = is_def(bottom) ?
                     assert(is_finite(bottom) && bottom>dedendum, "bottom is invalid or too small for teeth")
                     bottom
               : is_def(width) ?
                     assert(is_finite(width) && width>adendum+dedendum, "Width is invalid or too small for teeth")
                     width - adendum
               : is_def(backing) ?
                     assert(all_positive([backing]), "Backing must be a positive value")
                     backing+dedendum
               : 2*dedendum+adendum  // default case
    )
    let(
        trans_pitch = pitch / cos(helical),
        trans_pa = atan(tan(PA)/cos(helical)),
        tthick = trans_pitch/PI * (PI/2 + 2*profile_shift * tan(PA)) - backlash,
        l = teeth * trans_pitch,
        ax = ang_adj_to_opp(trans_pa, adendum),
        dx = dedendum*tan(trans_pa),
        poff = tthick/2,
        tooth = [
            [-trans_pitch/2, -dedendum],
            if (rounding) each arc(n=4, r=clear, corner=[
                [-trans_pitch/2, -dedendum],
                [-poff-dx, -dedendum],
                [-poff+ax, +adendum],
            ]) else [-poff-dx, -dedendum],
            if (rounding) each arc(n=4, r=trans_pitch/16, corner=[
                [-poff-dx, -dedendum],
                [-poff+ax, +adendum],
                [+poff-ax, +adendum],
            ]) else [-poff+ax, +adendum],
            if (rounding) each arc(n=4, r=trans_pitch/16, corner=[
                [-poff+ax, +adendum],
                [+poff-ax, +adendum],
                [+poff+dx, -dedendum],
            ]) else [+poff-ax, +adendum],
            if (rounding) each arc(n=4, r=clear, corner=[
                [+poff-ax, +adendum],
                [+poff+dx, -dedendum],
                [+trans_pitch/2, -dedendum],
            ]) else [+poff+dx, -dedendum],
            [+trans_pitch/2, -dedendum],
        ],
        path2 = [
            for(m = xcopies(trans_pitch,n=teeth))
                each apply(m,tooth)
        ],
        path = right(gear_travel, p=[
            [path2[0].x, -bottom],
            each path2,
            [last(path2).x, -bottom],
        ]),
        size=[l,2*bottom],
        anchors = [
            named_anchor("tip",         [   0, adendum,0],  BACK),
            named_anchor("tip-left",    [-l/2, adendum,0],  LEFT),
            named_anchor("tip-right",   [ l/2, adendum,0],  RIGHT),
            named_anchor("root",        [   0,-dedendum,0],  BACK),
            named_anchor("root-left",   [-l/2,-dedendum,0],  LEFT),
            named_anchor("root-right",  [ l/2,-dedendum,0],  RIGHT),
        ]
    ) reorient(anchor,spin, two_d=true, size=size, anchors=anchors, p=path);



module rack2d(
    pitch,
    teeth,
    backing,
    width, bottom,
    pressure_angle,
    backlash = 0.0,
    clearance,
    helical,
    profile_shift = 0,
    gear_travel = 0,
    circ_pitch,
    diam_pitch,
    mod, rounding=true, 
    anchor = CENTER,
    spin = 0
) {
    pitch = _inherit_gear_pitch("rack2d()",pitch, circ_pitch, diam_pitch, mod, warn=false);
    PA = _inherit_gear_pa(pressure_angle);
    helical = _inherit_gear_helical(helical);
    checks =
        assert(is_integer(teeth) && teeth>0)
        assert(is_finite(PA) && PA>=0 && PA<90, "Bad pressure_angle value.")
        assert(clearance==undef || (is_finite(clearance) && clearance>=0))
        assert(is_finite(backlash) && backlash>=0)
        assert(is_finite(helical) && abs(helical)<90)
        assert(is_finite(gear_travel))
        assert(num_defined([width,backing,bottom])<=1, "Can define only one of width, backing and bottom");
    trans_pitch = pitch / cos(helical);
    a = _adendum(pitch, profile_shift);
    d = _dedendum(pitch, clearance, profile_shift);
    bottom = is_def(bottom) ?
                 assert(is_finite(bottom) && bottom>d, "bottom is invalid or too small for teeth")
                 bottom
           : is_def(width) ?
                 assert(is_finite(width) && width>a+d, "Width is invalid or too small for teeth")
                 width - a
           : is_def(backing) ?
                 assert(all_positive([backing]), "Backing must be a positive value")
                 backing+d
           : 2*d+a;  // default case
    l = teeth * trans_pitch;
    path = rack2d(
        pitch = pitch,
        teeth = teeth,
        bottom=bottom, 
        pressure_angle = PA,
        backlash = backlash,
        clearance = clearance,
        helical = helical,
        rounding=rounding, 
        profile_shift= profile_shift
    );
    size = [l, 2*bottom];
    anchors = [
        named_anchor("tip",         [   0, a,0],  BACK),
        named_anchor("tip-left",    [-l/2, a,0],  LEFT),
        named_anchor("tip-right",   [ l/2, a,0],  RIGHT),
        named_anchor("root",        [   0,-d,0],  BACK),
        named_anchor("root-left",   [-l/2,-d,0],  LEFT),
        named_anchor("root-right",  [ l/2,-d,0],  RIGHT),
    ];
    attachable(anchor,spin, two_d=true, size=size, anchors=anchors) {
        right(gear_travel) polygon(path);
        children();
    }
}



// Function&Module: bevel_gear()
// Synopsis: Creates a straight or spiral bevel gear.
// SynTags: Geom, VNF
// Topics: Gears, Parts
// See Also: rack(), rack2d(), spur_gear(), spur_gear2d(), bevel_pitch_angle(), bevel_gear()
// Usage: As a Module
//   bevel_gear(circ_pitch, teeth, face_width, [pitch_angle=]|[mate_teeth=], [shaft_diam=], [hide=], [pressure_angle=], [clearance=], [backlash=], [cutter_radius=], [spiral_angle=], [left_handed=], [slices=], [internal=]);
//   bevel_gear(mod=, teeth=, face_width=, [pitch_angle=]|[mate_teeth=], [shaft_diam=], [hide=], [pressure_angle=], [clearance=], [backlash=], [cutter_radius=], [spiral_angle=], [left_handed=], [slices=], [internal=]);
// Usage: As a Function
//   vnf = bevel_gear(circ_pitch, teeth, face_width, [pitch_angle=]|[mate_teeth=], [hide=], [pressure_angle=], [clearance=], [backlash=], [cutter_radius=], [spiral_angle=], [left_handed=], [slices=], [internal=]);
//   vnf = bevel_gear(mod=, teeth=, face_width=, [pitch_angle=]|[mate_teeth=], [hide=], [pressure_angle=], [clearance=], [backlash=], [cutter_radius=], [spiral_angle=], [left_handed=], [slices=], [internal=]);
// Description:
//   Creates a (potentially spiral) bevel gear.  The module `bevel_gear()` gives a bevel gear, with
//   reasonable defaults for all the parameters.  Normally, you should just choose the first 4
//   parameters, and let the rest be default values.  In straight bevel gear sets, when each tooth
//   engages it inpacts the corresponding tooth.  The abrupt tooth engagement causes impact stress
//   which makes them more prone to breakage.  Spiral bevel gears have teeth formed along spirals so
//   they engage more gradually, resulting in a less abrupt transfer of force, so they are quieter
//   in operation and less likely to break.
//   .
//   The module `bevel_gear()` gives a gear in the XY plane, centered on the origin, with one tooth
//   centered on the positive Y axis.  The various functions below it take the same parameters, and
//   return various measurements for the gear.  The most important function is `mesh_radius()`, which tells
//   how far apart to space gears that are meshing, and `outer_radius()`, which gives the size of the
//   region filled by the gear.  A gear has a "pitch circle", which is an invisible circle that cuts
//   through the middle of each tooth (though not the exact center). In order for two gears to mesh,
//   their pitch circles should just touch, if no profile shifting is done).  So the distance between
//   their centers should be `mesh_radius()` for one, plus `mesh_radius()` for the other, which gives
//   the radii of their pitch circles and profile shifts.  In order for two gears to mesh, they must
//   have the same `circ_pitch` and `pressure_angle` parameters.  `circ_pitch` gives the number of millimeters
//   of arc around the pitch circle covered by one tooth and one space between teeth.  The `pressure_angle`
//   controls how flat or bulged the sides of the teeth are.  Common values include 14.5 degrees and 20
//   degrees, and occasionally 25.  The default here is 20 degrees.  Larger numbers bulge out more,
//   giving stronger teeth.  The ratio of `teeth` for two meshing gears gives how many times one will make a full
//   revolution when the the other makes one full revolution.  If the two numbers are coprime (i.e.
//   are not both divisible by the same number greater than 1), then every tooth on one gear will meet
//   every tooth on the other, for more even wear.  So coprime numbers of teeth are good.
// Arguments:
//   circ_pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.  Default: 5
//   teeth = Total number of teeth around the entire perimeter.  Default: 20
//   face_width = Width of the toothed surface in mm, from inside to outside.  Default: 10
//   ---
//   pitch_angle = Angle of beveled gear face.  Default: 45
//   mate_teeth = The number of teeth in the gear that this gear will mate with.  Overrides `pitch_angle` if given.
//   shaft_diam = Diameter of the hole in the center, in mm.  Module use only.  Default: 0 (no shaft hole)
//   hide = Number of teeth to delete to make this only a fraction of a circle.  Default: 0
//   pressure_angle = Controls how straight or bulged the tooth sides are. In degrees. Default: 20
//   clearance = Clearance gap at the bottom of the inter-tooth valleys.  Default: module/4
//   backlash = Gap between two meshing teeth, in the direction along the circumference of the pitch circle.  Default: 0
//   cutter_radius = Radius of spiral arc for teeth.  If 0, then gear will not be spiral.  Default: 0
//   spiral_angle = The base angle for spiral teeth.  Default: 0
//   left_handed = If true, the gear returned will have a left-handed spiral.  Default: false
//   slices = Number of vertical layers to divide gear into.  Useful for refining gears with `spiral`.  Default: 1
//   internal = If true, create a mask for difference()ing from something else.
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  Note that the diametral pitch is a completely different thing than the pitch diameter.
//   mod = The metric module/modulus of the gear, or mm of pitch diameter per tooth.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Extra Anchors:
//   "apex" = At the pitch cone apex for the bevel gear.
//   "pitchbase" = At the natural height of the pitch radius of the beveled gear.
//   "flattop" = At the top of the flat top of the bevel gear.
// Side Effects:
//   If internal is true then the default tag is "remove"
// Example: Beveled Gear
//   bevel_gear(
//       circ_pitch=5, teeth=36, face_width=10, shaft_diam=5,
//       pitch_angle=45, spiral_angle=0
//   );
// Example: Spiral Beveled Gear and Pinion
//   t1 = 16; t2 = 28;
//   bevel_gear(
//       circ_pitch=5, teeth=t1, mate_teeth=t2,
//       slices=12, anchor="apex", orient=FWD
//   );
//   bevel_gear(
//       circ_pitch=5, teeth=t2, mate_teeth=t1, left_handed=true,
//       slices=12, anchor="apex", spin=180/t2
//   );
// Example(Anim,Frames=4,VPD=175): Manual Spacing of Pinion and Gear
//   t1 = 14; t2 = 28; circ_pitch=5;
//   back(pitch_radius(circ_pitch, t2)) {
//     yrot($t*360/t1)
//     bevel_gear(
//       circ_pitch=circ_pitch, teeth=t1, mate_teeth=t2, shaft_diam=5,
//       slices=12, orient=FWD
//     );
//   }
//   down(pitch_radius(circ_pitch, t1)) {
//     zrot($t*360/t2)
//     bevel_gear(
//       circ_pitch=circ_pitch, teeth=t2, mate_teeth=t1, left_handed=true,
//       shaft_diam=5, slices=12, spin=180/t2
//     );
//   }

function bevel_gear(
    circ_pitch,
    teeth,
    face_width = 10,
    pitch_angle = 45,
    mate_teeth,
    hide = 0,
    pressure_angle = 20,
    clearance,
    backlash = 0.0,
    cutter_radius = 30,
    spiral_angle = 35,
    left_handed = false,
    slices = 5,
    internal,
    interior,
    pitch,
    diam_pitch,
    mod,
    anchor = "pitchbase",
    spin = 0,
    orient = UP
) = let(
        dummy = !is_undef(interior) ? echo("In bevel_gear(), the argument 'interior=' has been deprecated, and may be removed in the future.  Please use 'internal=' instead."):0,
        internal = first_defined([internal,interior,false]),
        circ_pitch = _inherit_gear_pitch("bevel_gear()",pitch, circ_pitch, diam_pitch, mod),
        PA = _inherit_gear_pa(pressure_angle),
        spiral_angle = _inherit_gear_helical(spiral_angle, invert=!internal),
        face_width = _inherit_gear_thickness(face_width),
        slices = cutter_radius==0? 1 : slices,
        pitch_angle = is_undef(mate_teeth)? pitch_angle : atan(teeth/mate_teeth),
        pr = pitch_radius(circ_pitch, teeth),
        rr = _root_radius(circ_pitch, teeth, clearance, internal),
        pitchoff = (pr-rr) * sin(pitch_angle),
        ocone_rad = opp_ang_to_hyp(pr, pitch_angle),
        icone_rad = ocone_rad - face_width,
        cutter_radius = cutter_radius==0? 1000 : cutter_radius,
        midpr = (icone_rad + ocone_rad) / 2,
        radcp = [0, midpr] + polar_to_xy(cutter_radius, 180+spiral_angle),
        angC1 = law_of_cosines(a=cutter_radius, b=norm(radcp), c=ocone_rad),
        angC2 = law_of_cosines(a=cutter_radius, b=norm(radcp), c=icone_rad),
        radcpang = v_theta(radcp),
        sang = radcpang - (180-angC1),
        eang = radcpang - (180-angC2),
        profile = reverse(_gear_tooth_profile(
            circ_pitch = circ_pitch,
            teeth = teeth,
            pressure_angle = PA,
            clearance = clearance,
            backlash = backlash,
            internal = internal,
            center = true
        )),
        verts1 = [
            for (v = lerpn(0,1,slices+1)) let(
                p = radcp + polar_to_xy(cutter_radius, lerp(sang,eang,v)),
                ang = v_theta(p)-90,
                dist = norm(p)
            ) [
                let(
                    u = dist / ocone_rad,
                    m = up((1-u) * pr / tan(pitch_angle)) *
                        up(pitchoff) *
                        zrot(ang/sin(pitch_angle)) *
                        back(u * pr) *
                        xrot(pitch_angle) *
                        scale(u)
                )
                for (tooth=[0:1:teeth-1])
                each apply(xflip() * zrot(360*tooth/teeth) * m, path3d(profile))
            ]
        ],
        botz = verts1[0][0].z,
        topz = last(verts1)[0].z,
        thickness = abs(topz - botz),
        cpz = (topz + botz) / 2,
        vertices = [for (x=verts1) reverse(x)],
        sides_vnf = vnf_vertex_array(vertices, caps=false, col_wrap=true, reverse=true),
        top_verts = last(vertices),
        bot_verts = vertices[0],
        gear_pts = len(top_verts),
        face_pts = gear_pts / teeth,
        top_faces =[
            for (i=[0:1:teeth-1], j=[0:1:(face_pts/2)-1]) each [
                [i*face_pts+j, (i+1)*face_pts-j-1, (i+1)*face_pts-j-2],
                [i*face_pts+j, (i+1)*face_pts-j-2, i*face_pts+j+1]
            ],
            for (i=[0:1:teeth-1]) each [
                [gear_pts, (i+1)*face_pts-1, i*face_pts],
                [gear_pts, ((i+1)%teeth)*face_pts, (i+1)*face_pts-1]
            ]
        ],
        vnf1 = vnf_join([
            [
                [each top_verts, [0,0,top_verts[0].z]],
                top_faces
            ],
            [
                [each bot_verts, [0,0,bot_verts[0].z]],
                [for (x=top_faces) reverse(x)]
            ],
            sides_vnf
        ]),
        lvnf = left_handed? vnf1 : xflip(p=vnf1),
        vnf = down(cpz, p=lvnf),
        anchors = [
            named_anchor("pitchbase", [0,0,pitchoff-thickness/2]),
            named_anchor("flattop", [0,0,thickness/2]),
            named_anchor("apex", [0,0,hyp_ang_to_opp(ocone_rad,90-pitch_angle)+pitchoff-thickness/2])
        ]
    ) reorient(anchor,spin,orient, vnf=vnf, extent=true, anchors=anchors, p=vnf);


module bevel_gear(
    circ_pitch,
    teeth,
    face_width = 10,
    pitch_angle = 45,
    mate_teeth,
    shaft_diam = 0,
    pressure_angle = 20,
    clearance = undef,
    backlash = 0.0,
    cutter_radius = 30,
    spiral_angle = 35,
    left_handed = false,
    slices = 5,
    internal,
    interior,
    pitch,
    diam_pitch,
    mod,
    anchor = "pitchbase",
    spin = 0,
    orient = UP
) {
    dummy = !is_undef(interior) ? echo("In bevel_gear(), the argument 'interior=' has been deprecated, and may be removed in the future.  Please use 'internal=' instead."):0;
    internal = first_defined([internal,interior,false]);
    circ_pitch = _inherit_gear_pitch("bevel_gear()",pitch, circ_pitch, diam_pitch, mod);
    PA = _inherit_gear_pa(pressure_angle);
    spiral_angle = _inherit_gear_helical(spiral_angle, invert=!internal);
    face_width = _inherit_gear_thickness(face_width);
    slices = cutter_radius==0? 1 : slices;
    pitch_angle = is_undef(mate_teeth)? pitch_angle : atan(teeth/mate_teeth);
    pr = pitch_radius(circ_pitch, teeth);
    ipr = pr - face_width*sin(pitch_angle);
    rr = _root_radius(circ_pitch, teeth, clearance, internal);
    pitchoff = (pr-rr) * sin(pitch_angle);
    vnf = bevel_gear(
        circ_pitch = circ_pitch,
        teeth = teeth,
        face_width = face_width,
        pitch_angle = pitch_angle,
        pressure_angle = PA,
        clearance = clearance,
        backlash = backlash,
        cutter_radius = cutter_radius,
        spiral_angle = spiral_angle,
        left_handed = left_handed,
        slices = slices,
        internal = internal,
        anchor=CENTER
    );
    axis_zs = [for (p=vnf[0]) if(norm(point2d(p)) < EPSILON) p.z];
    thickness = max(axis_zs) - min(axis_zs);
    anchors = [
        named_anchor("pitchbase", [0,0,pitchoff-thickness/2]),
        named_anchor("flattop", [0,0,thickness/2]),
        named_anchor("apex", [0,0,adj_ang_to_opp(pr,90-pitch_angle)+pitchoff-thickness/2])
    ];
    default_tag("remove",internal) {
        attachable(anchor,spin,orient, r1=pr, r2=ipr, h=thickness, anchors=anchors) {
            difference() {
                vnf_polyhedron(vnf, convexity=teeth/2);
                if (shaft_diam > 0) {
                    cylinder(h=2*thickness+1, r=shaft_diam/2, center=true, $fn=max(12,segs(shaft_diam/2)));
                }
            }
            children();
        }
    }
}


// Function&Module: worm()
// Synopsis: Creates a worm that will mate with a worm gear.
// SynTags: Geom, VNF
// Topics: Gears, Parts
// See Also: worm(), worm_gear(), rack(), rack2d(), spur_gear(), spur_gear2d(), bevel_pitch_angle(), bevel_gear()
// Usage: As a Module
//   worm(circ_pitch, d, l, [starts=], [left_handed=], [pressure_angle=], [backlash=], [clearance=]);
//   worm(mod=, d=, l=, [starts=], [left_handed=], [pressure_angle=], [backlash=], [clearance=]);
// Usage: As a Function
//   vnf = worm(circ_pitch, d, l, [starts=], [left_handed=], [pressure_angle=], [backlash=], [clearance=]);
//   vnf = worm(mod=, d=, l=, [starts=], [left_handed=], [pressure_angle=], [backlash=], [clearance=]);
// Description:
//   Creates a worm shape that can be matched to a worm gear.
// Arguments:
//   circ_pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.  Default: 5
//   d = The diameter of the worm.  Default: 30
//   l = The length of the worm.  Default: 100
//   starts = The number of lead starts.  Default: 1
//   left_handed = If true, the gear returned will have a left-handed spiral.  Default: false
//   pressure_angle = Controls how straight or bulged the tooth sides are. In degrees. Default: 20
//   backlash = Gap between two meshing teeth, in the direction along the circumference of the pitch circle.  Default: 0
//   clearance = Clearance gap at the bottom of the inter-tooth valleys.  Default: module/4
//   profile_shift = Profile shift factor x.  Default: 0
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  Note that the diametral pitch is a completely different thing than the pitch diameter.
//   mod = The metric module/modulus of the gear, or mm of pitch diameter per tooth.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Example:
//   worm(circ_pitch=8, d=30, l=50, $fn=72);
// Example: Multiple Starts.
//   worm(circ_pitch=8, d=30, l=50, starts=3, $fn=72);
// Example: Left Handed
//   worm(circ_pitch=8, d=30, l=50, starts=3, left_handed=true, $fn=72);
// Example: Called as Function
//   vnf = worm(circ_pitch=8, d=35, l=50, starts=2, left_handed=true, pressure_angle=20, $fn=72);
//   vnf_polyhedron(vnf);

function worm(
    circ_pitch,
    d=30, l=100,
    starts=1,
    left_handed=false,
    pressure_angle,
    backlash=0,
    clearance,
    profile_shift=0,
    diam_pitch,
    mod,
    pitch,
    gear_spin=0,
    anchor=CENTER,
    spin=0,
    orient=UP
) =
    let(
        circ_pitch = _inherit_gear_pitch("worm()", pitch, circ_pitch, diam_pitch, mod),
        PA = _inherit_gear_pa(pressure_angle)
    )
    assert(is_integer(starts) && starts>0)
    assert(is_finite(l) && l>0)
    //assert(is_finite(shaft_diam) && shaft_diam>=0)
    assert(is_finite(PA) && PA>=0 && PA<90, "Bad pressure_angle value.")
    assert(clearance==undef || (is_finite(clearance) && clearance>=0))
    assert(is_finite(backlash) && backlash>=0)
    assert(is_bool(left_handed))
    assert(is_finite(gear_spin))
    let(
        helical = asin(starts * circ_pitch / PI / d),
        trans_pitch = circ_pitch / cos(helical),
        tooth = xflip(
            p=select(rack2d(
                pitch=circ_pitch,
                teeth=1,
                pressure_angle=PA,
                clearance=clearance,
                backlash=backlash,
                helical=helical,
                profile_shift=profile_shift
            ), 1, -2)
        ),
        rack_profile = [
            for (t = xcopies(trans_pitch, n=2*ceil(l/trans_pitch)+1))
                each apply(t, tooth)
        ],
        steps = max(36, segs(d/2)),
        step = 360 / steps,
        zsteps = ceil(l / trans_pitch / starts * steps),
        zstep = l / zsteps,
        profiles = [
            for (j = [0:1:zsteps]) [
                for (i = [0:1:steps-1]) let(
                    u = i / steps - 0.5,
                    ang = 360 * (1 - u) + 90,
                    z = j*zstep - l/2,
                    zoff = trans_pitch * starts * u,
                    h = lookup(z+zoff, rack_profile)
                )
                cylindrical_to_xyz(d/2+h, ang, z)
            ]
        ],
        vnf1 = vnf_vertex_array(profiles, caps=true, col_wrap=true, style="alt"),
        m = product([
            zrot(gear_spin),
            if (left_handed) xflip(),
        ]),
        vnf = apply(m, vnf1)
    ) reorient(anchor,spin,orient, d=d, l=l, p=vnf);


module worm(
    circ_pitch,
    d=15, l=100,
    starts=1,
    left_handed=false,
    pressure_angle,
    backlash=0,
    clearance,
    profile_shift=0,
    pitch,
    diam_pitch,
    mod,
    gear_spin=0,
    anchor=CENTER,
    spin=0,
    orient=UP
) {
    circ_pitch = _inherit_gear_pitch("worm()", pitch, circ_pitch, diam_pitch, mod);
    PA = _inherit_gear_pa(pressure_angle);
    profile_shift = auto_profile_shift(starts,PA,profile_shift=profile_shift);
    checks =
        assert(is_integer(starts) && starts>0)
        assert(is_finite(l) && l>0)
        //assert(is_finite(shaft_diam) && shaft_diam>=0)
        assert(is_finite(PA) && PA>=0 && PA<90, "Bad pressure_angle value.")
        assert(clearance==undef || (is_finite(clearance) && clearance>=0))
        assert(is_finite(backlash) && backlash>=0)
        assert(is_bool(left_handed))
        assert(is_finite(gear_spin))
        assert(is_finite(profile_shift) && abs(profile_shift)<1);
    helical = asin(starts * circ_pitch / PI / d);
    trans_pitch = circ_pitch / cos(helical);
    vnf = worm(
        circ_pitch=circ_pitch,
        starts=starts,
        d=d, l=l,
        left_handed=left_handed,
        pressure_angle=PA,
        backlash=backlash,
        clearance=clearance,
        profile_shift=profile_shift,
        mod=mod
    );
    attachable(anchor,spin,orient, d=d, l=l) {
        zrot(gear_spin) vnf_polyhedron(vnf, convexity=ceil(l/trans_pitch)*2);
        children();
    }
}


// Function&Module: double_enveloping_worm()
// Synopsis: Creates a double-enveloping worm that will mate with a worm gear.
// SynTags: Geom, VNF
// Topics: Gears, Parts
// See Also: worm(), worm_gear(), rack(), rack2d(), spur_gear(), spur_gear2d(), bevel_pitch_angle(), bevel_gear()
// Usage: As a Module
//   double_enveloping_worm(circ_pitch, mate_teeth, d, [left_handed=], [starts=], [arc=], [pressure_angle=]);
//   double_enveloping_worm(mod=, mate_teeth=, d=, [left_handed=], [starts=], [arc=], [pressure_angle=]);
//   double_enveloping_worm(diam_pitch=, mate_teeth=, d=, [left_handed=], [starts=], [arc=], [pressure_angle=]);
// Usage: As a Function
//   vnf = double_enveloping_worm(circ_pitch, mate_teeth, d, [left_handed=], [starts=], [arc=], [pressure_angle=]);
//   vnf = double_enveloping_worm(mod=, mate_teeth=, d=, [left_handed=], [starts=], [arc=], [pressure_angle=]);
//   vnf = double_enveloping_worm(diam_pitch=, mate_teeth=, d=, [left_handed=], [starts=], [arc=], [pressure_angle=]);
// Description:
//   Creates a double-enveloping worm shape that can be matched to a worm gear.
// Arguments:
//   circ_pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.  Default: 5
//   mate_teeth = The number of teeth in the mated worm gear.
//   d = The pitch diameter of the worm at its middle.
//   left_handed = If true, the gear returned will have a left-handed spiral.  Default: false
//   ---
//   starts = The number of lead starts.  Default: 1
//   arc = Arc angle of the mated worm gear to envelop.  Default: 45º
//   pressure_angle = Controls how straight or bulged the tooth sides are. In degrees. Default: 20
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  Note that the diametral pitch is a completely different thing than the pitch diameter.
//   mod = The metric module/modulus of the gear, or mm of pitch diameter per tooth.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Example:
//   double_enveloping_worm(circ_pitch=8, mate_teeth=45, d=30, $fn=72);
// Example: Multiple Starts.
//   double_enveloping_worm(circ_pitch=8, mate_teeth=33, d=30, starts=3, $fn=72);
// Example: Left Handed
//   double_enveloping_worm(circ_pitch=8, mate_teeth=33, d=30, starts=3, left_handed=true, $fn=72);
// Example: Called as Function
//   vnf = double_enveloping_worm(circ_pitch=8, mate_teeth=37, d=35, starts=2, left_handed=true, pressure_angle=20, $fn=72);
//   vnf_polyhedron(vnf);

function double_enveloping_worm(
    circ_pitch,
    mate_teeth,
    d,
    left_handed=false,
    starts=1,
    arc=45,
    pressure_angle=20,
    gear_spin=0,
    anchor=CTR,
    diam_pitch,
    mod,
    pitch,
    spin=0,
    orient=UP
) =
    assert(is_integer(mate_teeth) && mate_teeth>10)
    assert(is_finite(d) && d>0)
    assert(is_bool(left_handed))
    assert(is_integer(starts) && starts>0)
    assert(is_finite(arc) && arc>10 && arc<75)
    assert(is_finite(pressure_angle) && pressure_angle>0 && pressure_angle<45)
    assert(is_finite(gear_spin))
    let(
        circ_pitch = circular_pitch(circ_pitch=circ_pitch, diam_pitch=diam_pitch, pitch=pitch, mod=mod),
        hsteps = segs(d/2),
        vsteps = hsteps*3,
        helical = asin(starts * circ_pitch / PI / d),
        pr = pitch_radius(circ_pitch, mate_teeth, helical=helical),
        taper_table = [
            [-180, 0],
            [-arc/2, 0],
            [-arc/2*0.85, 0.75],
            [-arc/2*0.8, 0.93],
            [-arc/2*0.75, 1],
            [+arc/2*0.75, 1],
            [+arc/2*0.8, 0.93],
            [+arc/2*0.85, 0.75],
            [+arc/2, 0],
            [+180, 0],
        ],
        tarc = 360 / mate_teeth,
        rteeth = quantup(ceil(mate_teeth*arc/360),2)+1+2*starts,
        rack_path = select(
            rack2d(
                circ_pitch, rteeth,
                pressure_angle=pressure_angle,
                rounding=true, spin=90
            ),
            1,-2
        ),
        adendum = _adendum(circ_pitch, profile_shift=0),
        m1 = yscale(360/(circ_pitch*mate_teeth)) * left(adendum),
        rows = [
            for (i = [0:1:hsteps-1]) let(
                u = i / hsteps,
                theta = (1-u) * 360,
                m2 = back(circ_pitch*starts*u),
                polars = [
                    for (p=apply(m1*m2, rack_path))
                    if(p.y>=-arc-tarc && p.y<=arc+tarc)
                    [pr+p.x*lookup(p.y,taper_table)+adendum, p.y]
                ],
                rpolars = mirror([-1,1],p=polars)
            ) [
                for (j = [0:1:vsteps-1]) let(
                    v = j / (vsteps-1),
                    phi = (v-0.5) * arc,
                    minor_r = lookup(phi, rpolars),
                    xy = [d/2+pr,0] + polar_to_xy(minor_r,180-phi),
                    xyz = xrot(90,p=point3d(xy))
                ) zrot(theta, p=xyz)
            ]
        ],
        ys = column(flatten(rows),1),
        miny = min(ys),
        maxy = max(ys),
        vnf1 = vnf_vertex_array(transpose(rows), col_wrap=true, caps=true),
        m = product([
            zrot(gear_spin),
            if (!left_handed) xflip(),
            zrot(90),
        ]),
        vnf = apply(m, vnf1)
    ) reorient(anchor,spin,orient, d=d, l=maxy-miny, p=vnf);


module double_enveloping_worm(
    circ_pitch,
    mate_teeth,
    d,
    left_handed=false,
    starts=1,
    arc=45,
    pressure_angle=20,
    gear_spin=0,
    diam_pitch,
    mod,
    pitch,
    anchor=CTR,
    spin=0,
    orient=UP
) {
    vnf = double_enveloping_worm(
        mate_teeth=mate_teeth,
        d=d,
        left_handed=left_handed,
        starts=starts,
        arc=arc,
        pressure_angle=pressure_angle,
        gear_spin=gear_spin,
        circ_pitch=circ_pitch,
        diam_pitch=diam_pitch,
        mod=mod,
        pitch=pitch
    );
    bounds = pointlist_bounds(vnf[0]);
    delta = bounds[1] - bounds[0];
    attachable(anchor,spin,orient, d=max(delta.x,delta.y), l=delta.z) {
        vnf_polyhedron(vnf, convexity=mate_teeth);
        children();
    }
}

// Function&Module: worm_gear()
// Synopsis: Creates a worm gear that will mate with a worm.
// SynTags: Geom, VNF
// Topics: Gears, Parts
// See Also: worm(), worm_gear(), rack(), rack2d(), spur_gear(), spur_gear2d(), bevel_pitch_angle(), bevel_gear()
// Usage: As a Module
//   worm_gear(circ_pitch, teeth, worm_diam, [worm_starts=], [worm_arc=], [crowning=], [left_handed=], [pressure_angle=], [backlash=], [clearance=], [slices=], [shaft_diam=]) [ATTACHMENTS];
//   worm_gear(mod=, teeth=, worm_diam=, [worm_starts=], [worm_arc=], [crowning=], [left_handed=], [pressure_angle=], [backlash=], [clearance=], [slices=], [shaft_diam=]) [ATTACHMENTS];
// Usage: As a Function
//   vnf = worm_gear(circ_pitch, teeth, worm_diam, [worm_starts=], [worm_arc=], [crowning=], [left_handed=], [pressure_angle=], [backlash=], [clearance=], [slices=]);
//   vnf = worm_gear(mod=, teeth=, worm_diam=, [worm_starts=], [worm_arc=], [crowning=], [left_handed=], [pressure_angle=], [backlash=], [clearance=], [slices=]);
// Description:
//   Creates a worm gear to match with a worm.
// Arguments:
//   circ_pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.  Default: 5
//   teeth = Total number of teeth along the rack.  Default: 30
//   worm_diam = The pitch diameter of the worm gear to match to.  Default: 30
//   worm_starts = The number of lead starts on the worm gear to match to.  Default: 1
//   worm_arc = The arc of the worm to mate with, in degrees. Default: 60 degrees
//   crowning = The amount to oversize the virtual hobbing cutter used to make the teeth, to add a slight crowning to the teeth to make them fit the work easier.  Default: 1
//   left_handed = If true, the gear returned will have a left-handed spiral.  Default: false
//   pressure_angle = Controls how straight or bulged the tooth sides are. In degrees. Default: 20
//   backlash = Gap between two meshing teeth, in the direction along the circumference of the pitch circle.  Default: 0
//   clearance = Clearance gap at the bottom of the inter-tooth valleys.  Default: module/4
//   profile_shift = Profile shift factor x.  Default: "auto"
//   slices = The number of vertical slices to refine the curve of the worm throat.  Default: 10
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  Note that the diametral pitch is a completely different thing than the pitch diameter.
//   mod = The metric module/modulus of the gear, or mm of pitch diameter per tooth.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Example: Right-Handed
//   worm_gear(circ_pitch=5, teeth=36, worm_diam=30, worm_starts=1);
// Example: Left-Handed
//   worm_gear(circ_pitch=5, teeth=36, worm_diam=30, worm_starts=1, left_handed=true);
// Example: Multiple Starts
//   worm_gear(circ_pitch=5, teeth=36, worm_diam=30, worm_starts=4);
// Example: Metric Worm Gear
//   worm_gear(mod=2, teeth=32, worm_diam=30, worm_starts=1);
// Example(Anim,Frames=4,FrameMS=125,VPD=220,VPT=[-15,0,0]): Meshing Worm and Gear
//   $fn=36;
//   circ_pitch = 5; starts = 4;
//   worm_diam = 30; worm_length = 50;
//   gear_teeth=36;
//   right(worm_diam/2)
//     yrot($t*360/starts)
//       worm(
//          d=worm_diam,
//          l=worm_length,
//          circ_pitch=circ_pitch,
//          starts=starts,
//          orient=BACK);
//   left(pitch_radius(circ_pitch, gear_teeth))
//     zrot(-$t*360/gear_teeth)
//       worm_gear(
//          circ_pitch=circ_pitch,
//          teeth=gear_teeth,
//          worm_diam=worm_diam,
//          worm_starts=starts);
// Example: Meshing Worm and Gear Metricly
//   $fn = 72;
//   modulus = 2; starts = 3;
//   worm_diam = 30; worm_length = 50;
//   gear_teeth=36;
//   right(worm_diam/2)
//       worm(d=worm_diam, l=worm_length, mod=modulus, starts=starts, orient=BACK);
//   left(pitch_radius(mod=modulus, teeth=gear_teeth))
//       worm_gear(mod=modulus, teeth=gear_teeth, worm_diam=worm_diam, worm_starts=starts);
// Example: Called as Function
//   vnf = worm_gear(circ_pitch=8, teeth=30, worm_diam=30, worm_starts=1);
//   vnf_polyhedron(vnf);

function worm_gear(
    circ_pitch,
    teeth,
    worm_diam,
    worm_starts = 1,
    worm_arc = 60,
    crowning = 0.1,
    left_handed = false,
    pressure_angle,
    backlash = 0,
    clearance,
    profile_shift="auto",
    slices = 10,
    gear_spin=0,
    pitch,
    diam_pitch,
    mod,
    anchor = CENTER,
    spin = 0,
    orient = UP
) =
    assert(worm_arc >= 10 && worm_arc <= 60)
    let(
        circ_pitch = _inherit_gear_pitch("worm_gear()", pitch, circ_pitch, diam_pitch, mod),
        PA = _inherit_gear_pa(pressure_angle),
        profile_shift = auto_profile_shift(teeth,PA,profile_shift=profile_shift)
    )
    assert(is_integer(teeth) && teeth>10)
    assert(is_finite(worm_diam) && worm_diam>0)
    assert(is_integer(worm_starts) && worm_starts>0)
    assert(is_finite(worm_arc) && worm_arc>0 && worm_arc<90)
    assert(is_finite(crowning) && crowning>=0)
    assert(is_bool(left_handed))
    assert(is_finite(PA) && PA>=0 && PA<90, "Bad pressure_angle value.")
    assert(clearance==undef || (is_finite(clearance) && clearance>=0))
    assert(is_finite(backlash) && backlash>=0)
    //assert(is_finite(shaft_diam) && shaft_diam>=0)
    assert(slices==undef || (is_integer(slices) && slices>0))
    assert(is_finite(profile_shift) && abs(profile_shift)<1)
    assert(is_finite(gear_spin))
    let(
        helical = asin(worm_starts * circ_pitch / PI / worm_diam),
        pr = pitch_radius(circ_pitch, teeth,helical),
        hob_rad = worm_diam / 2 + crowning,
        thickness = worm_gear_thickness(circ_pitch=circ_pitch, teeth=teeth, worm_diam=worm_diam, worm_arc=worm_arc, crowning=crowning, clearance=clearance),
        tooth_profile = _gear_tooth_profile(
            circ_pitch=circ_pitch,
            teeth=teeth,
            pressure_angle=PA,
            clearance=clearance,
            backlash=backlash,
            helical=helical,
            profile_shift=profile_shift,
            center=true
        ),
        tbot = min(column(tooth_profile,1)),
        arcthick = hob_rad * sin(worm_arc/2) * 2,
        twist = sin(helical)*arcthick / (2*PI*pr) * 360,
        profiles = [
            for (slice = [0:1:slices]) let(
                u = slice/slices - 0.5
            ) [
                for (i = [0:1:teeth-1]) each
                apply(
                    zrot(-i*360/teeth + twist*u - 0.5) *
                        right(pr+hob_rad) *
                        yrot(u*worm_arc) *
                        left(hob_rad) *
                        zrot(-90) *
                        back(tbot) *
                        scale(pow(cos(u*worm_arc),2)) *
                        fwd(tbot),
                    path3d(tooth_profile)
                )
            ]
        ],
        top_verts = last(profiles),
        bot_verts = profiles[0],
        face_pts = len(tooth_profile),
        gear_pts = face_pts * teeth,
        top_faces =[
            for (i=[0:1:teeth-1], j=[0:1:(face_pts/2)-2]) each [
                [i*face_pts+j, (i+1)*face_pts-j-1, (i+1)*face_pts-j-2],
                [i*face_pts+j, (i+1)*face_pts-j-2, i*face_pts+j+1]
            ],
            for (i=[0:1:teeth-1]) each [
                [gear_pts, (i+1)*face_pts-1, i*face_pts],
                [gear_pts, ((i+1)%teeth)*face_pts, (i+1)*face_pts-1]
            ]
        ],
        sides_vnf = vnf_vertex_array(profiles, caps=false, col_wrap=true, style="min_edge"),
        vnf1 = vnf_join([
            [
                [each top_verts, [0,0,top_verts[0].z]],
                [for (x=top_faces) reverse(x)]
            ],
            [
                [each bot_verts, [0,0,bot_verts[0].z]],
                top_faces
            ],
            sides_vnf
        ]),
        m = product([
            zrot(gear_spin),
            if (left_handed) xflip(),
            zrot(90),
        ]),
        vnf = apply(m,vnf1)
    ) reorient(anchor,spin,orient, r=pr, l=thickness, p=vnf);


module worm_gear(
    circ_pitch,
    teeth,
    worm_diam,
    worm_starts = 1,
    worm_arc = 60,
    crowning = 0.1,
    left_handed = false,
    pressure_angle,
    clearance,
    backlash = 0,
    shaft_diam = 0,
    slices = 10,
    profile_shift="auto",
    gear_spin=0,
    pitch,
    diam_pitch,
    mod,
    anchor = CENTER,
    spin = 0,
    orient = UP
) {
    circ_pitch = _inherit_gear_pitch("worm_gear()", pitch, circ_pitch, diam_pitch, mod);
    PA = _inherit_gear_pa(pressure_angle);
    profile_shift = auto_profile_shift(teeth,PA,profile_shift=profile_shift);
    checks =
        assert(is_integer(teeth) && teeth>10)
        assert(is_finite(worm_diam) && worm_diam>0)
        assert(is_integer(worm_starts) && worm_starts>0)
        assert(is_finite(worm_arc) && worm_arc>0 && worm_arc<90)
        assert(is_finite(crowning) && crowning>=0)
        assert(is_bool(left_handed))
        assert(is_finite(PA) && PA>=0 && PA<90, "Bad pressure_angle value.")
        assert(clearance==undef || (is_finite(clearance) && clearance>=0))
        assert(is_finite(backlash) && backlash>=0)
        assert(is_finite(shaft_diam) && shaft_diam>=0)
        assert(slices==undef || (is_integer(slices) && slices>0))
        assert(is_finite(profile_shift) && abs(profile_shift)<1)
        assert(is_finite(gear_spin));
    helical = asin(worm_starts * circ_pitch / PI / worm_diam);
    pr = pitch_radius(circ_pitch, teeth, helical);
    vnf = worm_gear(
        circ_pitch = circ_pitch,
        teeth = teeth,
        worm_diam = worm_diam,
        worm_starts = worm_starts,
        worm_arc = worm_arc,
        crowning = crowning,
        left_handed = left_handed,
        pressure_angle = PA,
        backlash = backlash,
        clearance = clearance,
        profile_shift = profile_shift,
        slices = slices
    );
    thickness = pointlist_bounds(vnf[0])[1].z;
    attachable(anchor,spin,orient, r=pr, l=thickness) {
        zrot(gear_spin)
        difference() {
            vnf_polyhedron(vnf, convexity=teeth/2);
            if (shaft_diam > 0) {
                cylinder(h=2*thickness+1, r=shaft_diam/2, center=true, $fn=max(12,segs(shaft_diam/2)));
            }
        }
        children();
    }
}




/// Function: _gear_tooth_profile()
/// Usage: As Function
///   path = _gear_tooth_profile(pitch, teeth, [pressure_angle], [clearance], [backlash], [internal]);
/// Topics: Gears
/// See Also: spur_gear2d()
/// Description:
///   When called as a function, returns the 2D profile path for an individual gear tooth.
///   When called as a module, creates the 2D profile shape for an individual gear tooth.
/// Arguments:
///   circ_pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.
///   teeth = Total number of teeth on the spur gear that this is a tooth for.
///   pressure_angle = Pressure Angle.  Controls how straight or bulged the tooth sides are. In degrees.
///   clearance = Gap between top of a tooth on one gear and bottom of valley on a meshing gear (in millimeters)
///   backlash = Gap between two meshing teeth, in the direction along the circumference of the pitch circle
///   internal = If true, create a mask for difference()ing from something else.
///   center = If true, centers the pitch circle of the tooth profile at the origin.  Default: false.
///   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  Note that the diametral pitch is a completely different thing than the pitch diameter.
///   mod = The metric module/modulus of the gear, or mm of pitch diameter per tooth.
/// Example(2D):
///   _gear_tooth_profile(circ_pitch=5, teeth=20, pressure_angle=20);
/// Example(2D): Metric Gear Tooth
///   _gear_tooth_profile(mod=2, teeth=20, pressure_angle=20);
/// Example(2D):
///   _gear_tooth_profile(
///       circ_pitch=5, teeth=20, pressure_angle=20
///   );
/// Example(2D): As a function
///   path = _gear_tooth_profile(
///       circ_pitch=5, teeth=20, pressure_angle=20
///   );
///   stroke(path, width=0.1);

function _gear_tooth_profile(
    circ_pitch,
    teeth,
    pressure_angle = 20,
    clearance,
    backlash = 0.0,
    helical = 0,
    internal = false,
    profile_shift = 0.0,
    shorten = 0, 
    mod,
    diam_pitch,
    pitch,
    center = false
) = let(
    // Calculate a point on the involute curve, by angle.
    _involute = function(base_r,a)
        let(b=a*PI/180) base_r * [cos(a)+b*sin(a), sin(a)-b*cos(a)],

    steps = 16,
    circ_pitch = circular_pitch(pitch=pitch, circ_pitch=circ_pitch, diam_pitch=diam_pitch, mod=mod),
    mod = module_value(circ_pitch=circ_pitch),
    clear = default(clearance, 0.25 * mod),

    // Calculate the important circle radii
    arad = outer_radius(circ_pitch, teeth, helical=helical, profile_shift=profile_shift, internal=internal, shorten=shorten),
    prad = pitch_radius(circ_pitch, teeth, helical=helical),
    brad = _base_radius(circ_pitch, teeth, pressure_angle, helical=helical),
    rrad = _root_radius(circ_pitch, teeth, clearance, helical=helical, profile_shift=profile_shift, internal=internal),
    srad = max(rrad,brad),
    tthick = circ_pitch/PI / cos(helical) * (PI/2 + 2*profile_shift * tan(pressure_angle)) + (internal?backlash:-backlash),
    tang = tthick / prad / 2 * 180 / PI,

    // Generate a lookup table for the involute curve angles, by radius
    involute_lup = [
        for (i=[0:5:arad/PI/brad*360])
            let(
                xy = _involute(brad,i),
                pol = xy_to_polar(xy)
            )
            if (pol.x <= arad * 1.1)
            [pol.x, 90-pol.y]
    ],

    // Generate reverse lookup table for involute radii, by angle
    involute_rlup = mirror([-1,1],p=involute_lup), // swaps X and Y columns.

    a_ang = lookup(arad, involute_lup),
    p_ang = lookup(prad, involute_lup),
    b_ang = lookup(brad, involute_lup),
    r_ang = lookup(rrad, involute_lup),
    s_ang = lookup(srad, involute_lup),
    soff = tang + (b_ang - p_ang),
    ma_rad = min(arad, lookup(90-soff+0.05*360/teeth/2, involute_rlup)),
    ma_ang = lookup(ma_rad, involute_lup),
    cap_steps = ceil((ma_ang + soff - 90) / 5),
    cap_step = (ma_ang + soff - 90) / cap_steps,
    ax = circ_pitch/4 - ang_adj_to_opp(pressure_angle, circ_pitch/PI),

    // Calculate the undercut a meshing rack might carve out of this tooth.
    undercut = [
        for (a=[atan2(ax,rrad):-1:-90])
        let(
            bx = -a/360 * 2*PI*prad,
            x = bx + ax,
            y = prad - circ_pitch/PI + profile_shift*circ_pitch/PI,
            pol = xy_to_polar(x,y)
        )
        if (pol.x < arad*1.05)
        [pol.x, pol.y-a+180/teeth]
    ],
    uc_min = min_index(column(undercut,0)),

    // Generate a fast lookup table for the undercut.
    undercut_lup = [for (i=idx(undercut)) if (i>=uc_min) undercut[i]],

    // The u values to use when generating the tooth.
    us = [for (i=[0:1:steps*2]) i/steps/2],

    // Find top of undercut.
    undercut_max = max([
        0,
        for (u = us) let(
            r = lerp(rrad, ma_rad, u),
            a1 = lookup(r, involute_lup) + soff,
            a2 = lookup(r, undercut_lup),
            a = internal || r < undercut_lup[0].x? a1 : min(a1,a2),
            b = internal || r < undercut_lup[0].x? false : a1>a2
        ) if(a<90+180/teeth && b) r
    ]),

    // Generate the left half of the tooth.
    tooth_half_raw = deduplicate([
        for (u = us)
            let(
                r = lerp(rrad, ma_rad, u),
                a1 = lookup(r, involute_lup) + soff,
                a2 = lookup(r, undercut_lup),
                a = internal || r < undercut_lup[0].x? a1 : min(a1,a2)
            )
            if ( internal || r > (rrad+clear) )
            if (!internal || r < (ma_rad-clear) )
            if (a < 90+180/teeth)
            polar_to_xy(r, a),
        if (!internal)
            for (i=[0:1:cap_steps-1]) let(
                a = ma_ang + soff - i * (cap_step-1)
            ) polar_to_xy(ma_rad, a),
    ]),

    // Round out the clearance valley
    rcircum = 2 * PI * (internal? ma_rad : rrad),
    rpart = (180/teeth-tang)/360,
    round_r = min(clear, rcircum*rpart),
    line1 = internal
          ? select(tooth_half_raw,-2,-1)
          : select(tooth_half_raw,0,1),
    line2 = internal
          ? [[0,ma_rad],[-1,ma_rad]]
          : zrot(180/teeth, p=[[0,rrad],[1,rrad]]),
    isect_pt = line_intersection(line1,line2),
    rcorner = internal
      ? [last(line1), isect_pt, line2[0]]
      : [line2[0], isect_pt, line1[0]],
    rounded_tooth_half = deduplicate([
        if (!internal && round_r>0) each arc(n=8, r=round_r, corner=rcorner),
        if (!internal && round_r<=0) isect_pt,
        each tooth_half_raw,
        if (internal && round_r>0) each arc(n=8, r=round_r, corner=rcorner),
        if (internal && round_r<=0) isect,
    ]),

    // Strip "jaggies" if found.
    strip_left = function(path,i)
        i > len(path)? [] :
        norm(path[i]) >= undercut_max? [for (j=idx(path)) if(j>=i) path[j]] :
        let(
            angs = [
                for (j=[i+1:1:len(path)-1]) let(
                    p = path[i],
                    np = path[j],
                    r = norm(np),
                    a = v_theta(np-p)
                ) if(r<undercut_max) a
            ],
            mti = !angs? 0 : min_index(angs),
            out = concat([path[i]], strip_left(path, i + mti + 1))
        ) out,
    tooth_half = !undercut_max? rounded_tooth_half :
        strip_left(rounded_tooth_half, 0),

    // Mirror the tooth to complete it.
    full_tooth = deduplicate([
        each tooth_half,
        each reverse(xflip(tooth_half)),
    ]),

    // Reduce number of vertices.
    tooth = path_merge_collinear(
        resample_path(full_tooth, n=ceil(2*steps), closed=false)
    ),

    out = center? fwd(prad, p=tooth) : tooth
) out;



// Section: Computing Gear Dimensions
//   These functions let the user find the derived dimensions of the gear.
//   A gear fits within a circle of radius outer_radius, and two gears should have
//   their centers separated by the sum of their pitch_radius.


// Function: circular_pitch()
// Synopsis: Returns tooth density expressed as "circular pitch".
// Topics: Gears, Parts
// See Also: spur_gear(), diametral_pitch(), circular_pitch(), module_value()
// Usage:
//   circ_pitch = circular_pitch(circ_pitch);
//   circ_pitch = circular_pitch(mod=);
//   circ_pitch = circular_pitch(diam_pitch=);
// Description:
//   Get tooth density expressed as "circular pitch", or the distance in mm between teeth around the pitch circle.
//   For example, if you have a gear with 11 teeth, and the pitch diameter is 35mm, then the circumfrence
//   of the pitch diameter is really close to 110mm, making the circular pitch of that gear about 10mm/tooth.
// Arguments:
//   circ_pitch = The circular pitch, or distance in mm between teeth around the pitch circle.
//   ---
//   mod = The metric module/modulus of the gear, or mm of pitch diameter per tooth.
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  Note that the diametral pitch is a completely different thing than the pitch diameter.
// Example(2D,Med,VPT=[0,31,0],VPR=[0,0,0],VPD=40):
//   $fn=144;
//   teeth=20;
//   circ_pitch = circular_pitch(diam_pitch=8);
//   pr = pitch_radius(circ_pitch, teeth);
//   stroke(spur_gear2d(circ_pitch, teeth), width=0.1);
//   color("cyan")
//       dashed_stroke(circle(r=pr), width=0.1);
//   color("black") {
//       stroke(
//           arc(r=pr, start=90+90/teeth, angle=-360/teeth),
//           width=0.2, endcaps="arrow");
//       back(pr+1) right(3)
//          zrot(30) text("Circular Pitch", size=1);
//   }
// Example:
//   circ_pitch1 = circular_pitch(circ_pitch=5);
//   circ_pitch2 = circular_pitch(diam_pitch=12);
//   circ_pitch3 = circular_pitch(mod=2);

function circular_pitch(circ_pitch, mod, pitch, diam_pitch) =
    assert(one_defined([pitch, mod, circ_pitch, diam_pitch], "pitch,mod,circ_pitch,diam_pitch"))
    pitch != undef? assert(is_finite(pitch) && pitch>0) pitch :
    circ_pitch != undef? assert(is_finite(circ_pitch) && circ_pitch>0) circ_pitch :
    diam_pitch != undef? assert(is_finite(diam_pitch) && diam_pitch>0) PI / diam_pitch * INCH :
    assert(is_finite(mod) && mod>0) mod * PI;


// Function: diametral_pitch()
// Synopsis: Returns tooth density expressed as "diametral pitch".
// Topics: Gears, Parts
// See Also: spur_gear(), diametral_pitch(), circular_pitch(), module_value()
// Usage:
//   dp = diametral_pitch(circ_pitch);
//   dp = diametral_pitch(mod=);
//   dp = diametral_pitch(diam_pitch=);
// Description:
//   Returns tooth density expressed as "diametral pitch", the number of teeth per inch of pitch diameter.
//   For example, if you have a gear with 30 teeth, with a 1.5 inch pitch diameter, then you have a
//   diametral pitch of 20 teeth/inch.
// Arguments:
//   circ_pitch = The circular pitch, or distance in mm between teeth around the pitch circle.
//   ---
//   mod = The metric module/modulus of the gear, or mm of pitch diameter per tooth.
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  Note that the diametral pitch is a completely different thing than the pitch diameter.
// Example:
//   diam_pitch1 = diametral_pitch(mod=2);
//   diam_pitch2 = diametral_pitch(circ_pitch=8);
//   diam_pitch3 = diametral_pitch(diam_pitch=16);

function diametral_pitch(circ_pitch, mod, pitch, diam_pitch) =
    let( circ_pitch = circular_pitch(pitch, mod, circ_pitch, diam_pitch) )
    PI / circ_pitch / INCH;


// Function: module_value()
// Synopsis: Returns tooth density expressed as "module" or "modulus" in millimeters.
// Topics: Gears, Parts
// See Also: spur_gear(), diametral_pitch(), circular_pitch(), module_value()
// Usage:
//   mod = module_value(circ_pitch);
//   mod = module_value(mod=);
//   mod = module_value(diam_pitch=);
// Description:
//   Get tooth density expressed as "module" or "modulus" in millimeters.  The module is the pitch
//   diameter of the gear divided by the number of teeth on it.  For example, a gear with a pitch
//   diameter of 40mm, with 20 teeth on it will have a modulus of 2.
// Arguments:
//   circ_pitch = The circular pitch, or distance in mm between teeth around the pitch circle.
//   ---
//   mod = The metric module/modulus of the gear, or mm of pitch diameter per tooth.
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  Note that the diametral pitch is a completely different thing than the pitch diameter.
// Example:
//   mod1 = module_value(circ_pitch=8);
//   mod2 = module_value(mod=2);
//   mod3 = module_value(diam_pitch=16);

function module_value(circ_pitch, mod, pitch, diam_pitch) =
    let( circ_pitch = circular_pitch(pitch, mod, circ_pitch, diam_pitch) )
    circ_pitch / PI;


/// Function: _adendum()
/// Usage:
///   ad = _adendum(circ_pitch, [profile_shift]);
///   ad = _adendum(diam_pitch=, [profile_shift=]);
///   ad = _adendum(mod=, [profile_shift=]);
/// Topics: Gears
/// Description:
///   The height of the top of a gear tooth above the pitch radius circle.
/// Arguments:
///   circ_pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.
///   profile_shift = Profile shift factor x.  Default: 0 
///   ---
///   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  Note that the diametral pitch is a completely different thing than the pitch diameter.
///   mod = The metric module/modulus of the gear, or mm of pitch diameter per tooth.
/// Example:
///   ad = _adendum(circ_pitch=5);
///   ad = _adendum(mod=2);
/// Example(2D):
///   circ_pitch = 5; teeth = 17;
///   pr = pitch_radius(circ_pitch, teeth);
///   adn = _adendum(circ_pitch=5);
///   #spur_gear2d(circ_pitch=circ_pitch, teeth=teeth);
///   color("black") {
///       stroke(circle(r=pr),width=0.1,closed=true);
///       stroke(circle(r=pr+adn),width=0.1,closed=true);
///   }

function _adendum(
    circ_pitch,
    profile_shift=0,
    shorten=0,
    diam_pitch,
    mod,
    pitch
) =
    let( mod = module_value(circ_pitch, mod, pitch, diam_pitch) )
    mod * (1 + profile_shift - shorten);



/// Function: _dedendum()
/// Usage:
///   ddn = _dedendum(circ_pitch=, [clearance], [profile_shift]);
///   ddn = _dedendum(diam_pitch=, [clearance=], [profile_shift=]);
///   ddn = _dedendum(mod=, [clearance=], [profile_shift=]);
/// Topics: Gears
/// Description:
///   The depth of the gear tooth valley, below the pitch radius.
/// Arguments:
///   circ_pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.
///   clearance = If given, sets the clearance between meshing teeth.  Default: module/4
///   profile_shift = Profile shift factor x.  Default: 0
///   ---
///   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  Note that the diametral pitch is a completely different thing than the pitch diameter.
///   mod = The metric module/modulus of the gear, or mm of pitch diameter per tooth.
///   shorten = amount to shorten tip 
/// Example:
///   ddn = _dedendum(circ_pitch=5);
///   ddn = _dedendum(mod=2);
/// Example(2D):
///   circ_pitch = 5; teeth = 17;
///   pr = pitch_radius(circ_pitch, teeth);
///   ddn = _dedendum(circ_pitch=5);
///   #spur_gear2d(circ_pitch=circ_pitch, teeth=teeth);
///   color("black") {
///       stroke(circle(r=pr),width=0.1,closed=true);
///       stroke(circle(r=pr-ddn),width=0.1,closed=true);
///   }

function _dedendum(
    circ_pitch,
    clearance,
    profile_shift=0,
    diam_pitch,
    mod,
    pitch
) = let(
        mod = module_value(circ_pitch, mod, pitch, diam_pitch),
        clearance = default(clearance, 0.25 * mod)
    )
    mod * (1 - profile_shift) + clearance;


// Function: pitch_radius()
// Synopsis: Returns the pitch radius for a gear.
// Topics: Gears, Parts
// See Also: spur_gear(), diametral_pitch(), circular_pitch(), module_value(), outer_radius()
// Usage:
//   pr = pitch_radius(pitch, teeth, [helical]);
//   pr = pitch_radius(mod=, teeth=, [helical=]);
// Description:
//   Calculates the pitch radius for the gear.  Two mated gears will have their centers spaced apart
//   by the sum of the two gear's pitch radii.
// Arguments:
//   circ_pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.
//   teeth = The number of teeth on the gear.
//   helical = The helical angle (from vertical) of the teeth on the gear.  Default: 0
//   ---
//   mod = The metric module/modulus of the gear, or mm of pitch diameter per tooth.
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  Note that the diametral pitch is a completely different thing than the pitch diameter.
// Example:
//   pr = pitch_radius(circ_pitch=5, teeth=11);
//   pr = pitch_radius(circ_pitch=5, teeth=11, helical=30);
//   pr = pitch_radius(diam_pitch=10, teeth=11);
//   pr = pitch_radius(mod=2, teeth=20);
//   pr = pitch_radius(mod=2, teeth=20, helical=30);
// Example(2D,Med,NoScales,VPT=[-0.20531,0.133721,0.658081],VPR=[0,0,0],VPD=82.6686):
//   $fn=144;
//   teeth=17; circ_pitch = 5;
//   pr = pitch_radius(circ_pitch, teeth);
//   stroke(spur_gear2d(circ_pitch, teeth), width=0.2);
//   color("blue") dashed_stroke(circle(r=pr), width=0.2);
//   color("black") {
//       stroke([[0,0],polar_to_xy(pr,45)],
//           endcaps="arrow", width=0.3);
//       fwd(1)
//           text("Pitch Radius", size=1.5,
//               halign="center", valign="top");
//   }

function pitch_radius(
    circ_pitch,
    teeth,
    helical=0,
    mod,
    diam_pitch,
    pitch
) =
    let( circ_pitch = circular_pitch(pitch, mod, circ_pitch, diam_pitch) )
    assert(is_finite(helical))
    assert(is_finite(circ_pitch))
    circ_pitch * teeth / PI / 2 / cos(helical);


// Function: outer_radius()
// Synopsis: Returns the outer radius for a gear.
// Topics: Gears, Parts
// See Also: spur_gear(), diametral_pitch(), circular_pitch(), module_value(), pitch_radius(), outer_radius()
// Usage:
//   or = outer_radius(circ_pitch, teeth, [helical=], [clearance=], [internal=], [profile_shift=]);
//   or = outer_radius(mod=, teeth=, [helical=], [clearance=], [internal=], [profile_shift=]);
//   or = outer_radius(diam_pitch=, teeth=, [helical=], [clearance=], [internal=], [profile_shift=]);
// Description:
//   Calculates the outer radius for the gear. The gear fits entirely within a cylinder of this radius, unless
//   it has been strongly profile shifted, in which case it will be undersized due to tip clipping.
// Arguments:
//   circ_pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.
//   teeth = The number of teeth on the gear.
//   ---
//   clearance = If given, sets the clearance between meshing teeth.  Default: module/4
//   profile_shift = Profile shift factor x.  Default: "auto"
//   pressure_angle = Pressure angle.  Default: 20
//   helical = The helical angle (from vertical) of the teeth on the gear.  Default: 0
//   shorten = Shortening factor, needed to maintain clearance with profile shifting.  Default: 0
//   internal = If true, calculate for an internal gear.
//   mod = The metric module/modulus of the gear, or mm of pitch diameter per tooth.
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  Note that the diametral pitch is a completely different thing than the pitch diameter.
// Example:
//   or = outer_radius(circ_pitch=5, teeth=20);
//   or = outer_radius(circ_pitch=5, teeth=20, helical=30);
//   or = outer_radius(diam_pitch=10, teeth=17);
//   or = outer_radius(mod=2, teeth=16);
// Example(2D,Med,NoScales,VPT=[-0.20531,0.133721,0.658081],VPR=[0,0,0],VPD=82.6686):
//   $fn=144;
//   teeth=17; circ_pitch = 5;
//   or = outer_radius(circ_pitch, teeth);
//   stroke(spur_gear2d(circ_pitch, teeth), width=0.2);
//   color("blue") dashed_stroke(circle(r=or), width=0.2);
//   color("black") {
//       stroke([[0,0],polar_to_xy(or,45)],
//           endcaps="arrow", width=0.3);
//       fwd(1)
//           text("Outer Radius", size=1.5,
//               halign="center", valign="top");
//   }

function outer_radius(circ_pitch, teeth, clearance, internal=false, helical=0, profile_shift="auto", pressure_angle=20, shorten=0, mod, pitch, diam_pitch) =
    let(
       circ_pitch = circular_pitch(pitch, mod, circ_pitch, diam_pitch),
       profile_shift = auto_profile_shift(teeth, pressure_angle, helical, profile_shift=profile_shift)
    )
    pitch_radius(circ_pitch, teeth, helical) + (
        internal
          ? _dedendum(circ_pitch, clearance, profile_shift=-profile_shift)
          : _adendum(circ_pitch, profile_shift=profile_shift, shorten=shorten)
    );


/// Function: _root_radius()
/// Usage:
///   rr = _root_radius(circ_pitch, teeth, [helical], [clearance=], [internal=], [profile_shift=]);
///   rr = _root_radius(diam_pitch=, teeth=, [helical=], [clearance=], [internal=], [profile_shift=]);
///   rr = _root_radius(mod=, teeth=, [helical=], [clearance=], [internal=], [profile_shift=]);
/// Topics: Gears
/// Description:
///   Calculates the root radius for the gear, at the base of the dedendum.  Does not apply auto profile shifting. 
/// Arguments:
///   circ_pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.
///   teeth = The number of teeth on the gear.
///   ---
///   clearance = If given, sets the clearance between meshing teeth.  Default: module/4
///   internal = If true, calculate for an internal gear.
///   helical = The helical angle (from vertical) of the teeth on the gear.  Default: 0
///   profile_shift = Profile shift factor x.  Default:0 
///   mod = The metric module/modulus of the gear, or mm of pitch diameter per tooth.
///   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  Note that the diametral pitch is a completely different thing than the pitch diameter.
/// Example:
///   rr = _root_radius(circ_pitch=5, teeth=11);
///   rr = _root_radius(circ_pitch=5, teeth=16, helical=30);
///   rr = _root_radius(diam_pitch=10, teeth=11);
///   rr = _root_radius(mod=2, teeth=16);
/// Example(2D):
///   pr = _root_radius(circ_pitch=5, teeth=11);
///   #spur_gear2d(pitch=5, teeth=11);
///   color("black")
///       stroke(circle(r=pr),width=0.1,closed=true);

function _root_radius(circ_pitch, teeth, clearance, internal=false, helical=0, profile_shift=0, diam_pitch, mod, pitch) =
    let( circ_pitch = circular_pitch(pitch, mod, circ_pitch, diam_pitch) )
    pitch_radius(circ_pitch, teeth, helical) - (
        internal
          ? _adendum(circ_pitch, profile_shift=-profile_shift)
          : _dedendum(circ_pitch, clearance, profile_shift=profile_shift)
    );


/// Function: _base_radius()
/// Usage:
///   br = _base_radius(circ_pitch, teeth, [pressure_angle], [helical]);
///   br = _base_radius(diam_pitch=, teeth=, [pressure_angle=], [helical=]);
///   br = _base_radius(mod=, teeth=, [pressure_angle=], [helical=]);
/// Topics: Gears
/// Description:
///   Get the base circle for involute teeth, at the base of the teeth.
/// Arguments:
///   pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.
///   teeth = The number of teeth on the gear.
///   pressure_angle = Pressure angle in degrees.  Controls how straight or bulged the tooth sides are.
///   helical = The helical angle (from vertical) of the teeth on the gear.  Default: 0
///   ---
///   mod = The metric module/modulus of the gear, or mm of pitch diameter per tooth.
///   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  Note that the diametral pitch is a completely different thing than the pitch diameter.
/// Example:
///   br = _base_radius(circ_pitch=5, teeth=20, pressure_angle=20);
///   br = _base_radius(circ_pitch=5, teeth=20, pressure_angle=20, helical=30);
///   br = _base_radius(diam_pitch=10, teeth=20, pressure_angle=20);
///   br = _base_radius(mod=2, teeth=18, pressure_angle=20);
/// Example(2D):
///   pr = _base_radius(circ_pitch=5, teeth=11);
///   #spur_gear2d(circ_pitch=5, teeth=11);
///   color("black")
///       stroke(circle(r=pr),width=0.1,closed=true);

function _base_radius(circ_pitch, teeth, pressure_angle=20, helical=0, diam_pitch, mod, pitch) =
    let(
        circ_pitch = circular_pitch(pitch, mod, circ_pitch, diam_pitch),
        trans_pa = atan(tan(pressure_angle)/cos(helical))
    )
    pitch_radius(circ_pitch, teeth, helical) * cos(trans_pa);


// Function: bevel_pitch_angle()
// Synopsis: Returns the pitch cone angle for a bevel gear.
// Topics: Gears, Parts
// See Also: bevel_gear(), pitch_radius(), outer_radius()
// Usage:
//   ang = bevel_pitch_angle(teeth, mate_teeth, [drive_angle=]);
// Description:
//   Returns the correct pitch cone angle for a bevel gear with a given number of teeth, that is
//   matched to another bevel gear with a (possibly different) number of teeth.
// Arguments:
//   teeth = Number of teeth that this gear has.
//   mate_teeth = Number of teeth that the matching gear has.
//   drive_angle = Angle between the drive shafts of each gear.  Default: 90º.
// Example:
//   ang = bevel_pitch_angle(teeth=18, mate_teeth=30);
// Example(2D):
//   t1 = 13; t2 = 19; pitch=5;
//   pang = bevel_pitch_angle(teeth=t1, mate_teeth=t2, drive_angle=90);
//   color("black") {
//       zrot_copies([0,pang])
//           stroke([[0,0,0], [0,-20,0]],width=0.2);
//       stroke(arc(r=3, angle=[270,270+pang]),width=0.2);
//   }
//   #bevel_gear(
//       pitch=5, teeth=t1, mate_teeth=t2,
//       spiral_angle=0, cutter_radius=1000,
//       slices=12, anchor="apex", orient=BACK
//   );

function bevel_pitch_angle(teeth, mate_teeth, drive_angle=90) =
    atan(sin(drive_angle)/((mate_teeth/teeth)+cos(drive_angle)));


// Function: worm_gear_thickness()
// Synopsis: Returns the thickness for a worm gear.
// Topics: Gears, Parts
// See Also: worm(), worm_gear(), pitch_radius(), outer_radius()
// Usage:
//   thick = worm_gear_thickness(pitch, teeth, worm_diam, [worm_arc=], [crowning=], [clearance=]);
//   thick = worm_gear_thickness(mod=, teeth=, worm_diam=, [worm_arc=], [crowning=], [clearance=]);
// Description:
//   Calculate the thickness of the worm gear.
// Arguments:
//   circ_pitch = The circular pitch, or distance between teeth around the pitch circle, in mm.  Default: 5
//   teeth = Total number of teeth along the rack.  Default: 30
//   worm_diam = The pitch diameter of the worm gear to match to.  Default: 30
//   ---
//   worm_arc = The arc of the worm to mate with, in degrees. Default: 60 degrees
//   crowning = The amount to oversize the virtual hobbing cutter used to make the teeth, to add a slight crowning to the teeth to make them fit the work easier.  Default: 1
//   clearance = Clearance gap at the bottom of the inter-tooth valleys.  Default: module/4
//   mod = The metric module/modulus of the gear, or mm of pitch diameter per tooth.
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  Note that the diametral pitch is a completely different thing than the pitch diameter.
// Example:
//   thick = worm_gear_thickness(circ_pitch=5, teeth=36, worm_diam=30);
//   thick = worm_gear_thickness(mod=2, teeth=28, worm_diam=25);
// Example(2D):
//   circ_pitch = 5;  teeth=17;
//   worm_diam = 30; starts=2;
//   y = worm_gear_thickness(circ_pitch=circ_pitch, teeth=teeth, worm_diam=worm_diam);
//   #worm_gear(
//       circ_pitch=circ_pitch, teeth=teeth,
//       worm_diam=worm_diam,
//       worm_starts=starts,
//       orient=BACK
//   );
//   color("black") {
//       ycopies(y) stroke([[-25,0],[25,0]], width=0.5);
//       stroke([[-20,-y/2],[-20,y/2]],width=0.5,endcaps="arrow");
//   }

function worm_gear_thickness(circ_pitch, teeth, worm_diam, worm_arc=60, crowning=1, clearance, diam_pitch, mod, pitch) =
    let(
        circ_pitch = circular_pitch(pitch, mod, circ_pitch, diam_pitch),
        r = worm_diam/2 + crowning,
        pitch_thick = r * sin(worm_arc/2) * 2,
        pr = pitch_radius(circ_pitch, teeth),
        rr = _root_radius(circ_pitch, teeth, clearance, false),
        pitchoff = (pr-rr) * sin(worm_arc/2),
        thickness = pitch_thick + 2*pitchoff
    ) thickness;


// Function: worm_dist()
// Synopsis: Returns the distance between a worm and a worm gear
// Topics: Gears, Parts
// See Also: worm(), worm_gear(), pitch_radius(), outer_radius()
// Usage:
//   dist = worm_dist(mod=|diam_pitch=|circ_pitch=, d, starts, teeth, [profile_shift], [pressure_angle=]);
// Description:
//   Calculate the distance between the centers of a worm and its mating worm gear, taking account
//   possible profile shifting of the worm gear.
// Arguments:
//   d = diameter of worm
//   starts = number of starts of worm
//   teeth = number of teeth on worm gear
//   profile_shift = profile shift of worm gear
//   ---
//   mod = The metric module/modulus of the gear, or mm of pitch diameter per tooth.
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  Note that the diametral pitch is a completely different thing than the pitch diameter.
//   circ_pitch = distance between teeth around the pitch circle.
//   pressure_angle = The pressure angle of the gear.
//   backlash = Add extra space to produce a total of 2*backlash between the two gears. 

function worm_dist(d,starts,teeth,mod,profile_shift=0,diam_pitch,circ_pitch,pressure_angle=20,backlash=0) =
  let(
      mod = module_value(mod=mod,diam_pitch=diam_pitch,circ_pitch=circ_pitch),
      lead_angle = asin(mod*starts/d),
      pitch_diam = mod*teeth/cos(lead_angle)
  )
  (d+pitch_diam)/2 + profile_shift*mod
//   + backlash * (cos(lead_angle)+cos(90-lead_angle)) / tan(pressure_angle);
//    + backlash * cos(45-lead_angle) / tan(pressure_angle);
     + backlash * cos(lead_angle) / tan(pressure_angle);



// Function: gear_dist()
// Synopsis: Returns the distance between two gear centers for spur gears or parallel axis helical gears.
// Topics: Gears, Parts
// See Also: worm(), worm_gear(), pitch_radius(), outer_radius()
// Usage:
//   dist = gear_dist(mod=|diam_pitch=|circ_pitch=, teeth1, teeth2, [helical], [profile_shift1], [profile_shift2], [pressure_angle=], [backlash=]);
// Description:
//   Calculate the distance between the centers of two spur gears gears or helical gears with parallel axes,
//   taking into account profile shifting and helical angle.  You can give the helical angle as either positive or negative.  
//   If you set one of the tooth counts to zero than that gear will be treated as a rack and the distance returned is the
//   distance between the rack's pitch line and the gear's center.  If you set internal1 or internal2 to true then the
//   specified gear is a ring gear;  the returned distance is still the distance between the centers of the gears.  Note that
//   for a regular gear and ring gear to be compatible the ring gear must have more teeth and at least as much profile shift
//   as the regular gear.
//   .
//   The backlash parameter computes the distance offset that produces a total backlash of `2*backlash` in the
//   two gear mesh system.  This is equivalent to giving the same backlash argument to both gears.  
// Arguments:
//   teeth1 = Total number of teeth in the first gear.  If given 0, we assume this is a rack or worm.
//   teeth2 = Total number of teeth in the second gear.  If given 0, we assume this is a rack or worm.
//   helical = The value of the helical angle (from vertical) of the teeth on the two gears (either sign).  Default: 0
//   profile_shift1 = Profile shift factor x for the first gear.  Default: 0
//   profile_shift2 = Profile shift factor x for the second gear.  Default: 0
//   --
//   mod = The metric module/modulus of the gear, or mm of pitch diameter per tooth.
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  Note that the diametral pitch is a completely different thing than the pitch diameter.
//   circ_pitch = distance between teeth around the pitch circle.
//   internal1 = first gear is an internal (ring) gear.  Default: false
//   internal2 = second gear is an internal (ring) gear.  Default: false
//   pressure_angle = The pressure angle of the gear.
//   backlash = Add extra space to produce a total of 2*backlash between the two gears. 
// Example(2D,NoAxes): Spur gears (with automatic profile shifting on both)
//   circ_pitch=5; teeth1=7; teeth2=24;
//   d = gear_dist(circ_pitch=circ_pitch, teeth1, teeth2);
//   spur_gear2d(circ_pitch, teeth1, gear_spin=-90);
//   right(d) spur_gear2d(circ_pitch, teeth2, gear_spin=90-180/teeth2);
// Example(3D,NoAxes,Med,VPT=[23.9049,5.42594,-4.68026],VPR=[64.8,0,353.5],VPD=140): Helical gears (with auto profile shifting on one of the gears)
//   circ_pitch=5; teeth1=7; teeth2=24; helical=37;
//   d = gear_dist(circ_pitch=circ_pitch, teeth1, teeth2, helical);
//   spur_gear(circ_pitch, teeth1, helical=helical, gear_spin=-90,slices=15);
//   right(d) spur_gear(circ_pitch, teeth2, helical=-helical, gear_spin=-90-180/teeth2,slices=9);
// Example(2D,NoAxes): Disable Auto Profile Shifting on the smaller gear
//   circ_pitch=5; teeth1=7; teeth2=24;
//   d = gear_dist(circ_pitch=circ_pitch, teeth1, teeth2, profile_shift1=0);
//   spur_gear2d(circ_pitch, teeth1, profile_shift=0, gear_spin=-90);
//   right(d) spur_gear2d(circ_pitch, teeth2, gear_spin=90-180/teeth2);
// Example(2D,NoAxes): Manual Profile Shifting
//   circ_pitch=5; teeth1=7; teeth2=24; ps1 = 0.5; ps2 = -0.2;
//   d = gear_dist(circ_pitch=circ_pitch, teeth1, teeth2, profile_shift1=ps1, profile_shift2=ps2);
//   spur_gear2d(circ_pitch, teeth1, profile_shift=ps1, gear_spin=-90);
//   right(d) spur_gear2d(circ_pitch, teeth2, profile_shift=ps2, gear_spin=90-180/teeth2);
// Example(2D,NoAxes): Profile shifted gear and a rack
//   mod=3; teeth=8;
//   d = gear_dist(mod=mod, teeth, 0);
//   rack2d(mod=mod, teeth=5, bottom=9);
//   back(d) spur_gear2d(mod=mod, teeth=teeth, gear_spin=180/teeth);
// Example(3D,Med,NoAxes,VPT=[-0.0608489,1.3772,-3.68839],VPR=[63.4,0,29.7],VPD=113.336): Profile shifted helical gear and rack 
//   mod=3; teeth=8; helical=29;
//   d = gear_dist(mod=mod, teeth, 0, helical);
//   rack(mod=mod, teeth=5, helical=helical, orient=FWD);
//   color("lightblue")
//     fwd(d) spur_gear(mod=mod, teeth=teeth, helical=-helical, gear_spin=180/teeth);
function gear_dist(
    teeth1,
    teeth2,
    helical=0,
    profile_shift1,
    profile_shift2,
    internal1=false,
    internal2=false,
    backlash = 0,
    pressure_angle=20,
    diam_pitch,
    circ_pitch,
    mod
) =
    assert(all_nonnegative([teeth1,teeth2]),"Must give nonnegative values for teeth")
    assert(teeth1>0 || teeth2>0, "One of the teeth counts must be nonzero")
    assert(is_bool(internal1))
    assert(is_bool(internal2))
    assert(is_finite(helical))
    assert(!(internal1&&internal2), "Cannot specify both gears as internal")
    assert(!(internal1 || internal2) || (teeth1>0 && teeth2>0), "Cannot specify internal gear with rack (zero tooth count)")
    let(
        mod = module_value(mod=mod,circ_pitch= circ_pitch, diam_pitch=diam_pitch),
        profile_shift1 = auto_profile_shift(teeth1,pressure_angle,helical,profile_shift=profile_shift1),
        profile_shift2 = auto_profile_shift(teeth2,pressure_angle,helical,profile_shift=profile_shift2),
        teeth1 = internal2? -teeth1 : teeth1,
        teeth2 = internal1? -teeth2 : teeth2
    )
    assert(teeth1+teeth2>0, "Internal gear must have more teeth than the mated external gear")
    let(
        profile_shift1 = internal2? -profile_shift1 : profile_shift1,
        profile_shift2 = internal1? -profile_shift2 : profile_shift2
    )
    assert(!(internal1||internal2) || profile_shift1+profile_shift2>=0, "Internal gear must have profile shift equal or greater than mated external gear")
    teeth1==0 || teeth2==0? pitch_radius(mod=mod, teeth=teeth1+teeth2, helical=helical) + (profile_shift1+profile_shift2)*mod
    :
    let(
        pa_eff = _working_pressure_angle(teeth1,profile_shift1,teeth2,profile_shift2,pressure_angle,helical),
        pa_transv = atan(tan(pressure_angle)/cos(helical))
    )
    mod*(teeth1+teeth2)*cos(pa_transv)/cos(pa_eff)/cos(helical)/2
        + (internal1||internal2?-1:1) * backlash*cos(helical)/tan(pressure_angle);

function _invol(a) = tan(a) - a*PI/180;

function _working_pressure_angle(teeth1,profile_shift1, teeth2, profile_shift2, pressure_angle, helical) =
  let(
      pressure_angle = atan(tan(pressure_angle)/cos(helical))
  )
  teeth1==0 || teeth2==0 ? pressure_angle
  :
  let(
      rhs = 2*(profile_shift1+profile_shift2)/(teeth1+teeth2)*cos(helical)*tan(pressure_angle) + _invol(pressure_angle)
  )
  assert(rhs>0, "Total profile shift is too small, so working pressure angle is negative, and no valid gear separation exists")
  let(
      pa_eff = root_find(function (x) _invol(x)-rhs, 1, 75)
  )
  pa_eff;



// Function: gear_dist_skew()
// Usage:
// Synopsis: Returns the distance between two helical gear centers with skew axes.  
// Topics: Gears, Parts
// See Also: gear_dist(), worm(), worm_gear(), pitch_radius(), outer_radius()
// Usage:
//   dist = gear_dist_skew(mod=|diam_pitch=|circ_pitch=, teeth1, teeth2, helical1, helical2, [profile_shift1], [profile_shift2], [pressure_angle=]
// Description:
//   Calculate the distance between two helical gears that mesh with non-parallel axes, taking into account
//   profile shift and the helical angles.
// Arguments:
//   teeth1 = Total number of teeth in the first gear.  If given 0, we assume this is a rack or worm.
//   teeth2 = Total number of teeth in the second gear.  If given 0, we assume this is a rack or worm.
//   helical1 = The helical angle (from vertical) of the teeth on the first gear. 
//   helical1 = The helical angle (from vertical) of the teeth on the second gear.
//   profile_shift1 = Profile shift factor x for the first gear.  Default: "auto"
//   profile_shift2 = Profile shift factor x for the second gear.  Default: "auto"
//   --
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  Note that the diametral pitch is a completely different thing than the pitch diameter.
//   mod = The metric module/modulus of the gear, or mm of pitch diameter per tooth.
//   circ_pitch = distance between teeth around the pitch circle.
//   pressure_angle = The pressure angle of the gear.
//   backlash = Add extra space to produce a total of 2*backlash between the two gears. 
// Example(3D,Med,NoAxes,VPT=[-0.302111,3.7924,-9.252],VPR=[55,0,25],VPD=155.556): Non-parallel Helical Gears (without any profile shifting)
//   circ_pitch=5; teeth1=15; teeth2=24; ha1=45; ha2=30; thick=10;
//   d = gear_dist_skew(circ_pitch=circ_pitch, teeth1, teeth2, helical1=ha1, helical2=ha2);
//   left(d/2) spur_gear(circ_pitch, teeth1, helical=ha1, thickness=thick, gear_spin=-90);
//   right(d/2) xrot(ha1+ha2) spur_gear(circ_pitch, teeth2, helical=ha2, thickness=thick, gear_spin=90-180/teeth2);
function gear_dist_skew(teeth1,teeth2,helical1,helical2,profile_shift1,profile_shift2,pressure_angle=20,
                        mod, circ_pitch, diam_pitch, backlash=0) =
  assert(all_nonnegative([teeth1,teeth2]),"Must give nonnegative values for teeth")
  assert(teeth1>0 || teeth2>0, "One of the teeth counts must be nonzero")
  let(
      profile_shift1 = auto_profile_shift(teeth1,pressure_angle,helical1,profile_shift=profile_shift1),
      profile_shift2 = auto_profile_shift(teeth2,pressure_angle,helical2,profile_shift=profile_shift2),
      mod = module_value(circ_pitch=circ_pitch, diam_pitch=diam_pitch, mod=mod)
  )
  teeth1==0 || teeth2==0? pitch_radius(mod=mod, teeth=teeth1+teeth2, helical=teeth1?helical1:helical2) + (profile_shift1+profile_shift2)*mod
  :
  let(
      pa_normal_eff = _working_normal_pressure_angle_skew(teeth1,profile_shift1,helical1,teeth2,profile_shift2,helical2,pressure_angle),
      dist_adj = 0.5*(teeth1/cos(helical1)^3+teeth2/cos(helical2)^3)*(cos(pressure_angle)/cos(pa_normal_eff)-1)
  )
  mod*(teeth1/2/cos(helical1)+teeth2/2/cos(helical2)+dist_adj)
      // This expression is a guess based on finding the cross section where pressure angles match so that there is a single
      // pressure angle to reference the movement by. 
      + backlash * cos((helical1-helical2)/2) / tan(pressure_angle);


function _working_normal_pressure_angle_skew(teeth1,profile_shift1,helical1, teeth2, profile_shift2, helical2, pressure_angle) = 
  let(
      inv = function(a) tan(a) + a*PI/180, 
      rhs = 2*(profile_shift1+profile_shift2)/(teeth1/cos(helical1)^3+teeth2/cos(helical2)^3)*tan(pressure_angle) + _invol(pressure_angle),
      pa_eff_normal = root_find(function (x) _invol(x)-rhs, 5, 75)
  )
  pa_eff_normal;


// Function: gear_skew_angle()
// Usage:
//   ang = gear_skew_angle(teeth1, teeth2, helical1, helical2, [profile_shift1], [profile_shift2], [pressure_angle=]
// Synopsis: Returns corrected skew angle between two profile shifted helical gears.  
// Description:
//   Compute the correct skew angle between the axes of two profile shifted helical gears.  When profile shifting is zero, or when one of
//   the gears is a rack, this angle is simply the sum of the helical angles of the two gears.  But with profile shifted gears, a small
//   correction to the skew angle is needed for proper meshing.  
// Arguments:
//   teeth1 = Total number of teeth in the first gear.  If given 0, we assume this is a rack or worm.
//   teeth2 = Total number of teeth in the second gear.  If given 0, we assume this is a rack or worm.
//   helical1 = The helical angle (from vertical) of the teeth on the first gear. 
//   helical1 = The helical angle (from vertical) of the teeth on the second gear.
//   profile_shift1 = Profile shift factor x for the first gear.  Default: "auto"
//   profile_shift2 = Profile shift factor x for the second gear.  Default: "auto"
//   --
//   pressure_angle = The pressure angle of the gear.
// Example(3D,Med,NoAxes,VPT=[-2.62091,2.01048,-1.31405],VPR=[55,0,25],VPD=74.4017): These gears are auto profile shifted and as a result, do not mesh at the sum of their helical angles, but at 2.5 degrees more.  
//   circ_pitch=5; teeth1=12; teeth2=7; ha1=25; ha2=30; thick=10;
//   d = gear_dist_skew(circ_pitch=circ_pitch, teeth1, teeth2, ha1, ha2);
//   ang = gear_skew_angle(teeth1, teeth2, helical1=ha1, helical2=ha2);  // Returns 57.7
//   left(d/2)
//     spur_gear(circ_pitch, teeth1, helical=ha1, thickness=thick, gear_spin=-90);
//   right(d/2) color("lightblue")
//     xrot(ang) spur_gear(circ_pitch, teeth2, helical=ha2, thickness=thick, gear_spin=90-180/teeth2);

function gear_skew_angle(teeth1,teeth2,helical1,helical2,profile_shift1,profile_shift2,pressure_angle=20) =
   assert(all_nonnegative([teeth1,teeth2]),"Must give nonnegative values for teeth")
   assert(teeth1>0 || teeth2>0, "One of the teeth counts must be nonzero")
   let(
       mod = 1,  // This is independent of module size
       profile_shift1 = auto_profile_shift(teeth1,pressure_angle,helical1,profile_shift=profile_shift1),
       profile_shift2 = auto_profile_shift(teeth2,pressure_angle,helical2,profile_shift=profile_shift2)
   )
   profile_shift1==0 && profile_shift2==0 ? helical1+helical2
 : teeth1==0 || teeth2==0 ? helical1+helical2
 : let(
        a = gear_dist_skew(mod=mod,teeth1,teeth2,helical1,helical2,profile_shift1,profile_shift2,pressure_angle=pressure_angle),
        b = gear_dist_skew(mod=mod,teeth1,teeth2,helical1,helical2,0,0,pressure_angle=pressure_angle),
        d1 = 2*pitch_radius(mod=mod,teeth=teeth1,helical=helical1),
        d2 = 2*pitch_radius(mod=mod,teeth=teeth2,helical=helical2),
        dw1 = 2*a*d1/(d1+d2),
        dw2 = 2*a*d2/(d1+d2),
        beta1 = atan(dw1/d1*tan(helical1)),
        beta2 = atan(dw2/d2*tan(helical2))
   )
   beta1+beta2;


// Function: get_profile_shift()
// Usage:
//   total_shift = get_profile_shift(mod=|diam_pitch=|circ_pitch=, desired, teeth1, teeth2, [helical], [pressure_angle=],
// Synopsis: Returns total profile shift needed to achieve a desired spacing between two gears
// Description:
//   Compute the total profile shift, split between two gears, needed to place those gears with a specified separation.
//   If the requested separation is too small, returns NaN.  Note that the profile shift returned may also be impractically
//   large or small and does not necessarily lead to a valid gear configuration.  You will need to split the profile shift
//   between the two gears.  Note that for helical gears, much more adjustment is available by modifying the helical angle.  
// Arguments:
//   desired = desired gear center separation
//   teeth1 = number of teeth on first gear
//   teeth2 = number of teeth on second gear
//   helical = The helical angle (from vertical) of the teeth on the gear.  Default: 0
//   ---
//   mod = The metric module/modulus of the gear, or mm of pitch diameter per tooth.
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  Note that the diametral pitch is a completely different thing than the pitch diameter.
//   circ_pitch = distance between teeth around the pitch circle.
//   pressure_angle = normal pressure angle of gear teeth.  Default: 20
// Example(2D,Med,NoAxes,VPT=[37.0558,0.626722,9.78411],VPR=[0,0,0],VPD=496): For a pair of module 4 gears with 19, and 37 teeth, the separation without profile shifting is 112.  Suppose we want it instead to be 115.  A positive profile shift, split evenly between the gears, achieves the goal, as shown by the red rectangle, with width 115.  
//   teeth1=37;
//   teeth2=19;
//   mod=4;
//   desired=115;
//   pshift = get_profile_shift(desired,teeth1,teeth2,mod=mod);  // Returns 0.82
//   ps1 = pshift/2;
//   ps2 = pshift/2;
//   shorten=gear_shorten(teeth1,teeth2,0,ps1,ps2);       // Returns 0.07
//   d = gear_dist(mod=mod, teeth1,teeth2,0,ps1,ps2);
//   spur_gear2d(mod=mod,teeth=teeth1,profile_shift=ps1,shorten=shorten,gear_spin=-90,shaft_diam=5);
//   right(d)
//     spur_gear2d(mod=mod,teeth=teeth2,profile_shift=ps2,shorten=shorten,gear_spin=-90,shaft_diam=5);
//   stroke([rect([desired,40], anchor=LEFT)],color="red");
// Example(2D,Med,NoAxes,VPT=[37.0558,0.626722,9.78411],VPR=[0,0,0],VPD=496): For the same pair of module 4 gears with 19, and 37 teeth, suppose we want a closer spacing of 110 instead of 112.  A positive profile shift does the job, as shown by the red rectangle with width 110.  More of the negative shift is assigned to the large gear, to avoid undercutting the smaller gear.  
//   teeth1=37;
//   teeth2=19;
//   mod=4;
//   desired=110;
//   pshift = get_profile_shift(desired,teeth1,teeth2,mod=mod);  // Returns -0.46
//   ps1 = 0.8*pshift;
//   ps2 = 0.2*pshift;
//   shorten=gear_shorten(teeth1,teeth2,0,ps1,ps2);  // Returns 0.04
//   d = gear_dist(mod=mod, teeth1,teeth2,0,ps1,ps2);
//   spur_gear2d(mod=mod,teeth=teeth1,profile_shift=ps1,shorten=shorten,gear_spin=-90,shaft_diam=5);
//   right(d)
//     spur_gear2d(mod=mod,teeth=teeth2,profile_shift=ps2,shorten=shorten,gear_spin=-90,shaft_diam=5);
//   stroke([rect([desired,40], anchor=LEFT)],color="red");
function get_profile_shift(desired,teeth1,teeth2,helical=0,pressure_angle=20,mod,diam_pitch,circ_pitch) =
  let(
       mod = module_value(mod=mod, circ_pitch=circ_pitch, diam_pitch=diam_pitch),
       teethsum = teeth1+teeth2,
       pressure_angle_trans = atan(tan(pressure_angle)/cos(helical)),
       y = desired/mod - teethsum/2/cos(helical),
       thing=teethsum*cos(pressure_angle_trans) / (teethsum+2*y*cos(helical)),
       pa_eff = acos(teethsum*cos(pressure_angle_trans) / (teethsum+2*y*cos(helical)))
  )
  teethsum * (_invol(pa_eff)-_invol(pressure_angle_trans))/2/tan(pressure_angle);


// Function: auto_profile_shift()
// Synopsis: Returns the recommended profile shift for a gear.
// Topics: Gears, Parts
// See Also: worm(), worm_gear(), pitch_radius(), outer_radius()
// Usage:
//   x = auto_profile_shift(teeth, [pressure_angle], [helical], [profile_shift=]);
//   x = auto_profile_shift(teeth, [pressure_angle], [helical], get_min=);
//   x = auto_profile_shift(teeth, min_teeth=);
// Description:
//   Calculates the recommended profile shift to avoid gear tooth undercutting.  You can set `min_teeth` to a
//   value to allow small undercutting, and only activate the profile shift for more extreme cases.  Is is common
//   practice to make gears with 15-17 teeth with undercutting with the standard 20 deg pressure angle.
//   .
//   The `get_min` argument returns the minimum profile shift needed to avoid undercutting regardless of the
//   number of teeth.  This will be a negative value for gears with a large number of teeth; such gears can
//   be given a negative profile shift without undercutting.  
// Arguments:
//   teeth = Total number of teeth in the gear.
//   pressure_angle = The pressure angle of the gear.
//   helical = helical angle
//   ---
//   min_teeth = If given, the minimum number of teeth on a gear that has acceptable undercut.
//   get_min = If true then return the minimum profile shift to avoid undercutting, which may be a negative value for large gears.  
//   profile_shift = If numerical then just return this value; if "auto" or not given then compute the automatic profile shift.
function auto_profile_shift(teeth, pressure_angle=20, helical=0, min_teeth, profile_shift, get_min=false) =
    assert(is_undef(profile_shift) || is_finite(profile_shift) || profile_shift=="auto", "Profile shift must be \"auto\" or a number")
    is_num(profile_shift) ? profile_shift
  : teeth==0 ? 0
  : let(
        pressure_angle=atan(tan(pressure_angle)/cos(helical)),
        min_teeth = default(min_teeth, 2 / sin(pressure_angle)^2)
    )
    !get_min && teeth > floor(min_teeth)? 0
  : (1 - (teeth / min_teeth))/cos(helical);


// Function: gear_shorten()
// Usage:
//    shorten = gear_shorten(teeth1, teeth2, [helical], [profile_shift1], [profile_shift2], [pressure_angle=]);
// Synopsis: Returns the tip shortening parameter for profile shifted parallel axis gears.
// Description:
//    Compute the gear tip shortening factor for gears that have profile shifts.  This factor depends on both
//    gears in a pair and when applied, will results in teeth that meet the specified clearance distance.
//    Generally if you don't apply it the teeth clearance will be decreased due to the profile shifting.
//    Because it operates pairwise, if a gear mates with more than one other gear, you may have to decide
//    which shortening factor to use.  The shortening factor is independent of the size of the teeth.
// Arguments:
//   teeth1 = number of teeth on first gear
//   teeth2 = number of teeth on second gear
//   helical = The helical angle (from vertical) of the teeth on the gear.  Default: 0
//   profile_shift1 = Profile shift factor x for the first gear.  Default: "auto"
//   profile_shift2 = Profile shift factor x for the second gear.  Default: "auto"
//   ---
//   pressure_angle = normal pressure angle of gear teeth.  Default: 20
// Example(2D,Med,VPT=[53.9088,1.83058,26.0319],VPR=[0,0,0],VPD=140): Big profile shift eliminates the clearance between the teeth
//   teeth1=25;
//   teeth2=19;
//   mod=4;
//   ps1 = 0.75;
//   ps2 = 0.75;
//   d = gear_dist(mod=mod, teeth1,teeth2,0,ps1,ps2);
//   color("lightblue")
//     spur_gear2d(mod=mod,teeth=teeth1,profile_shift=ps1,gear_spin=-90);
//   right(d)
//     spur_gear2d(mod=mod,teeth=teeth2,profile_shift=ps2,gear_spin=-90);
// Example(2D,Med,VPT=[53.9088,1.83058,26.0319],VPR=[0,0,0],VPD=140,NoAxes): Applying the correct shortening factor restores the clearance to its normal value.  
//   teeth1=25;
//   teeth2=19;
//   mod=4;
//   ps1 = 0.75;
//   ps2 = 0.75;
//   d = gear_dist(mod=mod, teeth1,teeth2,0,ps1,ps2);
//   shorten=gear_shorten(teeth1,teeth2,0,ps1,ps2);
//   color("lightblue")
//     spur_gear2d(mod=mod,teeth=teeth1,profile_shift=ps1,shorten=shorten,gear_spin=-90);
//   right(d)
//     spur_gear2d(mod=mod,teeth=teeth2,profile_shift=ps2,shorten=shorten,gear_spin=-90);
function gear_shorten(teeth1,teeth2,helical=0,profile_shift1="auto",profile_shift2="auto",pressure_angle=20) =
    teeth1==0 || teeth2==0 ? 0
  : let(
         profile_shift1 = auto_profile_shift(teeth1,pressure_angle,helical,profile_shift=profile_shift1),
         profile_shift2 = auto_profile_shift(teeth2,pressure_angle,helical,profile_shift=profile_shift2),
         ax = gear_dist(mod=1,teeth1,teeth2,helical,profile_shift1,profile_shift2,pressure_angle=pressure_angle),
         y = ax - (teeth1+teeth2)/2/cos(helical)
    )
    profile_shift1+profile_shift2-y;


// Function: gear_shorten_skew()
// Usage:
//    shorten = gear_shorten_skew(teeth1, teeth2, helical1, helical2, [profile_shift1], [profile_shift2], [pressure_angle=]);
// Synopsis: Returns the tip shortening parameter for profile shifted skew axis helical gears.
// Description:
//    Compute the gear tip shortening factor for skew axis helical gears that have profile shifts.  This factor depends on both
//    gears in a pair and when applied, will results in teeth that meet the specified clearance distance.
//    Generally if you don't apply it the teeth clearance will be decreased due to the profile shifting.
//    Because it operates pairwise, if a gear mates with more than one other gear, you may have to decide
//    which shortening factor to use.  The shortening factor is independent of the size of the teeth.
// Arguments:
//   teeth1 = Total number of teeth in the first gear.  If given 0, we assume this is a rack or worm.
//   teeth2 = Total number of teeth in the second gear.  If given 0, we assume this is a rack or worm.
//   helical1 = The helical angle (from vertical) of the teeth on the first gear. 
//   helical1 = The helical angle (from vertical) of the teeth on the second gear.
//   profile_shift1 = Profile shift factor x for the first gear.  Default: "auto"
//   profile_shift2 = Profile shift factor x for the second gear.  Default: "auto"
//   ---
//   pressure_angle = The pressure angle of the gear.
function gear_shorten_skew(teeth1,teeth2,helical1,helical2,profile_shift1="auto",profile_shift2="auto",pressure_angle=20) =
    let(
         profile_shift1 = auto_profile_shift(teeth1,pressure_angle,helical1,profile_shift=profile_shift1),
         profile_shift2 = auto_profile_shift(teeth2,pressure_angle,helical2,profile_shift=profile_shift2),
         ax = gear_dist(mod=1,teeth1,teeth2,helical,profile_shift1,profile_shift2,pressure_angle=pressure_angle),
         y = ax - (teeth1+teeth2)/2/cos(helical)
    )
    profile_shift1+profile_shift2-y;



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
