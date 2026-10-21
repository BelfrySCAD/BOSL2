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


// BEGIN GEAR_API_COMPAT
// Transitional positional circular pitch. Only documented positional prefixes are captured.
function _gear_legacy_missing(v) = v == "__gear_legacy_omitted__";
function _gear_legacy_index(name,names) =
    let(found=[for(i=[0:1:len(names)-1]) if(names[i]==name) i])
    len(found)==0 ? undef : found[0];
function _gear_legacy_merge(p,n,fname,name) =
    assert(is_undef(p) || is_undef(n), str(fname, ": ",name," supplied positionally and by name"))
    is_undef(p) ? n : p;
function _gear_legacy_args(fname,slots,extra,old_names,new_names,named,circ_pitch,mod,diam_pitch) =
    assert(_gear_legacy_missing(extra),str(fname, ": too many positional arguments; use names after the documented positional prefix"))
    let(
        explicit_size=num_defined([mod,circ_pitch,diam_pitch])>0,
        has_pos=!_gear_legacy_missing(slots[0]),
        legacy=has_pos && (len(new_names)==0 || is_undef(slots[0]) || !explicit_size),
        order=legacy?old_names:new_names,
        excess=[for(i=[0:1:len(slots)-1]) if(i>=len(order) && !_gear_legacy_missing(slots[i])) i],
        cp=_gear_legacy_merge(legacy && !_gear_legacy_missing(slots[0]) ? slots[0] : undef,circ_pitch,fname,"circ_pitch"),
        dimensions=[for(i=[0:1:len(new_names)-1])
            let(k=_gear_legacy_index(new_names[i],order),
                v=is_undef(k)?undef:slots[k])
            _gear_legacy_merge(_gear_legacy_missing(v)?undef:v,named[i],fname,new_names[i])],
        result=[cp,each dimensions]
    )
    assert(len(excess)==0,str(fname, ": too many positional arguments; use names after the documented positional prefix"))
    legacy ? echo(str("DEPRECATED: ",fname,
        len(new_names)==0 ? ": name the size measure: mod=, circ_pitch=, or diam_pitch=."
            : ": positional circular pitch; use a named size followed by dimensions, or name dimensions to inherit size.")) result : result;
// END GEAR_API_COMPAT

_BOSL2_GEARS = is_undef(_BOSL2_STD) && (is_undef(BOSL2_NO_STD_WARNING) || !BOSL2_NO_STD_WARNING) ?
       echo("Warning: gears.scad included without std.scad; dependencies may be missing\nSet BOSL2_NO_STD_WARNING = true to mute this warning.") true : true;


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


function _inherit_gear_pitch(fname,circ_pitch,diam_pitch,mod) =
    assert(num_defined([mod,circ_pitch,diam_pitch])<=1,
           str(fname, ": specify only one of mod=, circ_pitch=, or diam_pitch="))
    let(cp = num_defined([mod,circ_pitch,diam_pitch])>0
          ? circular_pitch(mod=mod,circ_pitch=circ_pitch,diam_pitch=diam_pitch)
          : default($parent_gear_pitch,5))
    assert(is_finite(cp) && cp>0, str(fname, ": invalid gear pitch"))
    cp;

// Resolve the rack-only alias before API dispatch, defaults, or inheritance.
function _rack_circ_pitch(fname,pitch,circ_pitch,mod,diam_pitch) =
    assert(num_defined([pitch,circ_pitch,mod,diam_pitch])<=1,
           str(fname, ": specify only one of pitch=, circ_pitch=, mod=, or diam_pitch="))
    is_undef(pitch) ? circ_pitch : pitch;

function _inherit_gear_pa(pressure_angle) =
    _inherit_gear_param(name="pressure_angle", val=pressure_angle, pval=$parent_gear_pa, dflt=20);

function _inherit_gear_helical(helical,invert=false) =
    _inherit_gear_param(name="helical", val=helical, pval=$parent_gear_helical, dflt=0, invert=invert);

function _inherit_gear_thickness(thickness,dflt=10) =
    _inherit_gear_param(name="thickness", val=thickness, pval=$parent_gear_thickness, dflt=dflt);


// Section: Parameter order and migration
//   Legacy invocation of many gear modules and functions has the form
//   `spur_gear(circ_pitch, teeth, thickness, ...)`
//   The gears parameter order is migrating to a unified calling convention
//   where the size **must** be given as a named parameter:
//   `mod=`, `circ_pitch=`, or `diam_pitch=`.  You can still give the size first,
//   so an invocation with 3 positional parameters becomes `spur_gear(circ_pitch=10, 47, 15)`.
//   If you want to use inheritance, use all named arguments:
//   `spur_gear(teeth=20, thickness=10)`. Fully named call will always work correctly.  
//   An old style call such as `spur_gear(5,20,10)` still means circ_pitch 5, 20 teeth and
//   thickness 10, and emits a deprecation message.  The legacy support is temporary and
//   will be removed in July 2027.  

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
//       * [Worm drive](https://www.tec-science.com/mechanical-power-transmission/gear-types/worms-and-worm-gears/)
//       * [Bevel gears](https://www.tec-science.com/mechanical-power-transmission/gear-types/bevel-gears/)
//   - SDPSI (A long document covering a variety of gear types and gear calculations)
//       * [Elements of Gear Technology](https://www.sdp-si.com/resources/elements-of-metric-gear-technology/index.php)
//   - Drivetrain Hub (A collection of "notebooks" on some gear topics)
//       * [Gear Geometry, Strength, Tooling and Mechanics](https://drivetrainhub.com/notebooks/#toc)
//   - Crown Face Gears
//       * [Crown Gearboxes](https://mag.ebmpapst.com/en/industries/drives/crown-gearboxes-efficiency-energy-savings-decentralized-drive-technology_14834/)
//       * [Crown gear pressure angle](https://mag.ebmpapst.com/en/industries/drives/the-formula-for-the-pressure-angle_14624/)
//       * [Face Gears: Geometry and Strength](https://www.geartechnology.com/ext/resources/issues/0107x/kissling.pdf)

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
//     stroke(arc(r=_root_radius_basic(mod=5,teeth=30),angle=[70,110]),width=.25);
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
//   stroke(arc(r=pitch_radius(mod=5,teeth=30),angle=[87,87+12]),width=.4,endcaps="arrow2",color="red");
//   color([1,0,0,1])     back(70)right(-13)zrot(4)text("circular pitch", size=2.5);
// Continues:
//   The size of the teeth can be specified as the *circular pitch*, which is the tooth width, or more precisely,
//   the distance along the pitch circle from the start of one tooth to the start of the text tooth.
//   The circular pitch can be computed as
//   `PI*d/teeth` where `d` is the diameter of the pitch circle and `teeth` is the number of teeth on the gear.
//   This simply divides up the pitch circle into the specified number of teeth.  However, the customary
//   way to specify metric gears is using the module, ratio of the diameter of the gear to the number of teeth: `m=d/teeth`.
//   The module is hence the circular pitch divided by a factor of π.  A third way to specify gear sizes is the diametral pitch,
//   which is the number of teeth that fit on a gear with a diameter of one inch, or π times the number of teeth per inch.
//   Note that for the module or circular pitch, larger values make larger teeth,
//   but for the diametral pitch, the opposite is true.  Throughout this library, module and circular pitch
//   are specified basic OpenSCAD units, so if you work in millimeters and want to give circular pitch in inches, be
//   sure to multiply by `INCH`.  The diametral pitch is given based on inches under the assumption that OpenSCAD units are millimeters.
//   .
//   You cannot directly specify the size of a gear.  The diameter of a gear depends on its tooth count
//   and tooth size.  If you want a gear with a particular diameter you can get close by seeting the module to `d/teeth`,
//   but that specifies the pitch circle, so the gear teeth will have a somewhat larger radius.  You should **not**
//   apply scale() to gears.  Always change their size by adjusting the tooth size parameters.  
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
// Figure(2D,Med,NoAxes): Teeth of the same size with different pressure angles.  The industry standard is 20°.
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
//   If the clearance is too large it can lead to a self-intersecting gear profile.  When this occurs, you
//   will see a message indicating that the profile was clipped, and what the required clearance is to
//   avoid the clipping.  This can be a starting point for adjusting the clipping.  Typical gear pressure angles,
//   as noted above, are 14.5, 20, or sometimes 25 degrees, but in some cases, larger pressure angles
//   may be useful.  These large pressure angles can give rise to self-intersecting gear geometry even
//   with a zero clearance.  To get a valid model, such gears need a **negative** clearance value.
// Figure(2D,NoAxes): This gear has a 55 degree pressure angle. If you don't specify clearance, the message tells you it clipped at -2.2.  Here we have used -2.3 to avoid a sharp corner in the valleys between teeth.  
//   spur_gear2d(mod=5, teeth=7, profile_shift=0, pressure_angle=55,clearance=-2.3);
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
// Figure(2D,Med,NoAxes): The green gear is a 7 tooth gear without profile shifting.  Its teeth are narrow and weak at their base.  In yellow is the same gear, profile shifted.  It has much stronger teeth.  The profile shifted gear also has a larger root circle radius and longer teeth.  
//   spur_gear2d(mod=5, teeth=7);
//   color("green")spur_gear2d(mod=5, teeth=7, profile_shift=0);
// Continues:
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
//   You can compute the shortening parameter using {{gear_shorten()}}.  The actual shortening distance is obtained
//   by scaling the shortening factor by the gear's module.  
// Figure(2D,Big,NoAxes,VPT=[55.8861,-4.31463,8.09832],VPR=[0,0,0],VPD=325.228): With large profile shifts the teeth need to be shortened or they don't have clearance in the valleys of the teeth in the meshing gear.  
//   teeth1=25;
//   teeth2=19;
//   mod=4;
//   ps1 = 0.75;
//   ps2 = 0.75;
//   d = gear_dist(mod=mod, teeth1=teeth1,teeth2=teeth2,helical=0,profile_shift1=ps1,profile_shift2=ps2);
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
//   d = gear_dist(mod=mod, teeth1=teeth1,teeth2=teeth2,helical=0,profile_shift1=ps1,profile_shift2=ps2);
//   shorten=gear_shorten(teeth1=teeth1,teeth2=teeth2,helical=0,profile_shift1=ps1,profile_shift2=ps2);
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
// Subsection: Worm Drive
//   A worm drive is a gear system for connecting skew shafts at 90 degrees.  They offer higher load capacity compared to
//   crossed helical gears.  The assembly is driven by the "worm", which is a gear that resembles a screw.
//   Like a screw, it can have one, or several starts.  These starts correspond to teeth on a helical gear;
//   in fact, the worm can be regarded as a type of helical gear at a very extreme angle, where the teeth wrap
//   around the gear.  The worm mates with the "worm gear" which is also called the "worm wheel".  The worm gear
//   resembles a helical gear at a very slight angle.
// Figure(3D,Med,NoAxes,VPT=[38.1941,-7.67869,7.95996],VPR=[56.4,0,25],VPD=361.364):  Worm drive assembly, with worm on the left and worm gear (worm wheel) on the right.  When the worm turns, its screwing action drives the worm gear.  
//   starts=2;
//   ps=0;
//   dist_ba=0;
//   gear_ba=0;
//     worm(
//          d=44, // mate_teeth=30,
//          circ_pitch=3*PI,
//          starts=starts,orient=BACK);
//   right(worm_dist(d=44,mod=3,teeth=30, starts=starts,profile_shift=ps,backlash=dist_ba))
//     zrot(360/30*.5) 
//       worm_gear(
//          circ_pitch=3*PI, 
//          teeth=30,
//          worm_diam=44,profile_shift=ps,
//          worm_starts=starts,backlash=gear_ba);
//   color("black"){
//      rot($vpr)left(45)back(25)text3d("worm",size=8);
//      rot($vpr)right(55)back(27)text3d("worm gear",size=8);  
//   }
// Continues:
//   A close look at the worm gear reveals that it differs significantly from a helical or spur gear.
//   This gear is an "enveloping" gear, which is designed to follow the curved profile of the worm,
//   resulting in much better contact between the teeth of the worm and the teeth of the worm gear.
//   The worm shown above is a cylindrical worm, which is the most common type.
//   It is possible to design the worm to follow the curved shape of its mated gear, resulting
//   in an enveloping (also called "globoid") worm.  This type of worm makes better contact with
//   the worm gear, but is less often used due to manufacturing complexity and consequent expense.  
// Figure(3D,Big,NoAxes,VPT=[0,0,0],VPR=[192,0,180],VPD=172.84): The enveloping (globoid) worm appears on the left in green.  Its sides curve so several teeth can mate with the worm gear, and it requires a complex tooth form.  A cylindrical worm appears on the right in blue.  Note its straight sides.
//   tilt=20;
//   starts=1;
//   ps=0;
//   pa=27;
//   dist_ba=0;
//   gear_ba=0;
//   xdistribute(spacing=25){
//      zrot(180)yrot(-tilt)  
//      union(){
//       color("lightgreen")
//         xrot(90) 
//         zrot(-90)
//         enveloping_worm(     mate_teeth=60,$fn=128,
//             d=14, pressure_angle=pa,  mod=3/2,
//             starts=starts);
//        right(worm_dist(d=14,mod=3/2,teeth=60, starts=starts,profile_shift=ps,backlash=dist_ba,pressure_angle=pa))
//          zrot(360/30*.25)
//            worm_gear(
//             mod=3/2,pressure_angle=pa,
//             teeth=60,crowning=0,
//             worm_diam=14,profile_shift=ps,
//             worm_starts=starts,backlash=gear_ba);
//      }
//      yrot(-tilt)
//      union(){
//       color("lightblue")
//         xrot(90) 
//         zrot(-90)
//                                worm(l=43, $fn=128,
//             d=14, pressure_angle=pa, left_handed=true,
//             mod=3/2,//circ_pitch=3*PI/2,
//             starts=starts);
//        right(worm_dist(d=14,mod=3/2,teeth=60, starts=starts,profile_shift=ps,backlash=dist_ba,pressure_angle=pa))
//          zrot(360/30*.25)
//            worm_gear(
//             mod=3/2,pressure_angle=pa,
//             teeth=60,crowning=0,left_handed=true,
//             worm_diam=14,profile_shift=ps,
//             worm_starts=starts,backlash=gear_ba);
//      }  
//   }
// Continues:
//   As usual, a proper mesh requires that the pressure angles match and the teeth of the worm and worm gear
//   are the same size.  Additionally the worm gear must be constructed to match the diameter of the worm
//   and the number of starts on the worm.  Note that the number of starts changes the angle at of the 
//   teeth on the worm, and hence requires a change to the angle of teeth on the worm gear.  
//   Of course an enveloping worm needs to know the diameter of the worm gear; you provide this
//   information indirectly by giving the number of teeth on the worm gear.
//   The {{worm_dist()}} function will give the correct center spacing for the worm from its mating worm gear.  
//   .  
//   Worm drives are often "self-locking", which means that torque transmission can occur only from the worm to the worm gear,
//   so they must be driven by the worm.  Self-locking results from the small lead angle of the worm threads, which produces
//   high frictional forces at contact.  A multi-start worm has a higher lead angle and as a result is less likely
//   to be self-locking, so a multi-start worm can be chosen to avoid self-locking.
//   Since self-locking is associated with friction, self-locking drives have lower efficiency,
//   usually less than 50%.  Worm drive efficiency can exceed 90% if self-locking is not required.  One consideration
//   with self-locking systems is that if the worm gear moves a large mass and the drive is suddenly shut off, the
//   worm gear is still trying to move due to inertia, which can create large loads that fracture the worm.
//   In such cases, the worm cannot be stopped abruptly but must be allowed to rotate a little further (called "over travel")
//   after switching off the drive.
// Subsection: Bevel Gears
//   Bevel gearing is another way of dealing with intersecting gear shafts.  For bevel gears, the teeth centers lie on
//   the surface of an imaginary cone, which is the "pitch cone" of the bevel gear.  Two bevel gears can mesh when their pitch cone
//   apexes coincide and the cones touch along their length.  The teeth of bevel gears shrink as they get closer to the center of the gear.
//   Tooth dimensions and pitch diameter (the base of the pitch cone) are referenced to the outer end of the teeth.
//   The pitch radius, computed the same was as for other gears, gives the radius of the pitch cone's base.  
//   Bevel gears can be made with straight teeth, analogous to spur gears, and with the
//   same disadvantage of sudden full contact that is noisy.  Spiral teeth are analogous to helical
//   teeth on cylindrical gears: the teeth engage gradually and smoothly, transmitting motion more smoothly
//   and quietly.  Also like helical gears, they have the disadvantage of introducing axial forces, and
//   usually they can only operate in one rotation direction.  
//   A third type of tooth is the zerol tooth, which has curved teeth like the spiral teeth,
//   but with a zero angle.  These share advantages of straight teeth and spiral teeth: they are quiet like
//   straight teeth but they lack the axial thrust of spiral gears, and they can operate in both directions.
//   They are also reportedly stronger than either spiral or bevel gears.
// Figure(3D,Med,VPT=[-5.10228,-3.09311,3.06426],VPR=[67.6,0,131.9],VPD=237.091,NoAxes): Straight tooth bevel gear with 45 degree angled teeth.  To get a gear like this you must specify a spiral angle of zero and a cutter radius of zero.  This gear would mate with a copy of itself and would change direction of rotation without changing the rotation rate. 
//   bevel_gear(mod=3,teeth=35,mate_teeth=35,face_width=20,spiral=0,cutter_radius=0);
// Figure(3D,Med,VPT=[-5.10228,-3.09311,3.06426],VPR=[67.6,0,131.9],VPD=237.091,NoAxes): Straight tooth bevel gear with 45 degree angled teeth.  A gear like this has a positive spiral angle, which determines how sloped the teeth are and a positive cutter radius, which determines how curved the teeth are.  
//   bevel_gear(mod=3,teeth=35,mate_teeth=35,face_width=20,slices=12);
// Figure(3D,Med,VPT=[-5.10228,-3.09311,3.06426],VPR=[67.6,0,131.9],VPD=237.091,NoAxes): Zerol tooth bevel gear with 45 degree angled teeth.  A gear like this has a spiral angle of zero, but a positive cutter radius, which determines how curved the teeth are.  
//   bevel_gear(mod=3,teeth=35,mate_teeth=35,face_width=20,spiral=0,slices=12);
// Continues:
//   Bevel gears have demanding requirements for successful mating of two gears.  Of course the tooth size
//   and pressure angle must match.  But beyond that, their pitch cones have to meet at their points.
//   This means that if you specify the tooth counts
//   of two gears and the desired shaft angle, then that information completely determines the pitch cones, and hence
//   the geometry of the gear.  You cannot simply mate two arbitary gears that have the same tooth size
//   and pressure angle like you can with helical gears: the gears must be designed in pairs to work together.
//   .
//   It is most common to design bevel gears so operate with their shafts at 90 degree angles, but
//   this is not required, and you can design pairs of bevel gears for any desired shaft angle.
//   Note, however, that some shaft angles may result in extreme bevel gear configurations.  
// Figure(3D,Med,NoAxes,VPT=[-1.42254,-1.98925,13.5702],VPR=[76,0,145],VPD=263.435): Two zerol bevel gears mated with shafts at 90 degrees.  
//   bevel_gear(mod=3,teeth=35,face_width=undef,spiral=0,mate_teeth=15,backing=3);
//   cyl(h=28,d=3,$fn=16,anchor=BOT);
//   color("lightblue")left(pitch_radius(mod=3,teeth=35))up(pitch_radius(mod=3,teeth=15))
//   yrot(90){zrot(360/15/2)bevel_gear(mod=3,teeth=15,face_width=undef,spiral=0,right_handed=true,mate_teeth=35);
//             cyl(h=57,d=3,$fn=16,anchor=BOT);}
// Figure(3D,Med,NoAxes,VPT=[2.01253,-0.673328,8.98056],VPD=263.435,VPR=[79.5,0,68.6]): Two zerol bevel gears mated with shafts at a 115.38 deg angle.  This is a planar bevel gear.  The axes intersect on the pitch base of the yellow gear.  If the blue gear is tipped slightly more its shaft will intersect the shaft of the yellow gear underneath that gear's pitch base, indicating an impossible angle for a normal bevel gear at this pair of teeth counts.
//   ang=acos(-15/35);
//   bevel_gear(mod=3,teeth=35,mate_teeth=15,shaft_angle=ang,spiral=0,face_width=undef,backing=5,anchor="apex")   
//     cyl(h=25,d=3,$fn=16,anchor=BOT);
//   color("lightblue")
//   xrot(ang)
//   bevel_gear(mod=3,teeth=15,mate_teeth=35,shaft_angle=ang,spiral=0,face_width=undef,right_handed=true,anchor="apex")
//     cyl(h=70,d=3,$fn=16,anchor=BOT);
// Continues:
//   In the above figure you can see a flat bevel gear.  Such a bevel gear is called a planar bevel gear or
//   sometimes also a crown gear.  The latter term may be confusing because it also refers to a similar looking
//   but very different type of gear that is described below.  A planar bevel gear can only mate with another
//   compatible bevel gear.  It has a degenerate cone with its apex on the gear itself, so the mating pinion gear cannot
//   mate at a 90 degree angle because if it did, its cone could not meet the center of the planar bevel gear.
//   If you request a larger shaft angle, the teeth of the bevel gear will tilt inward, producing an internal bevel gear.
//   Gears with this design are rarely used.  The mate of an interior gear is always an exterior gear.  
// Figure(Med,VPT=[-1.07698,0.67915,-2.25898],VPD=263.435,VPR=[69.7,0,49.3],NoAxes): Internal bevel gear (yellow) mated to an external bevel gear (blue) to achieve a 135 degree shaft angle.  
//   ang=135;
//   bevel_gear(mod=3,teeth=35,mate_teeth=15,shaft_angle=ang,spiral=0,cone_backing=false);
//      down(15)cyl(h=40,d=3,$fn=16,anchor=BOT);
//   color("lightblue")
//     back(pitch_radius(mod=3,teeth=35)+pitch_radius(mod=3,teeth=15))
//     xrot(ang,cp=[0,-pitch_radius(mod=3,teeth=15),0]){
//         bevel_gear(mod=3,teeth=15,mate_teeth=35,shaft_angle=ang,right_handed=true,spiral=0);
//               cyl(h=40,d=3,$fn=16,anchor=BOT);
//     }
// Subsection: Crown Gears (Face Gears)
//   Crown gears, sometimes called Face Crown Gears or just Face Gears, are gears with teeth pointing straight up so
//   the gear resembles a crown.  This type of gear is not the same as a bevel gear with vertical teeth, which would mate
//   to another bevel gear.  A crown gear mates to a spur gear at a ninety degree angle.  A feature of the crown gear assembly
//   is that the spur gear can shift along its axis without affecting the mesh.  
// Figure(Med,NoAxes,VPT=[-2.19006,-1.67419,-4.49379],VPR=[67.6,0,131.9],VPD=113.4): A Crown or Face gear with its mating spur gear in blue.  
//   crown_gear(mod=1, teeth=32, backing=3, face_width=7);
//   color("lightblue")
//   back(pitch_radius(mod=1,teeth=32)+7/2)
//     up(gear_dist(mod=1,teeth1=0,teeth2=9))spur_gear(mod=1, teeth=9,orient=BACK,thickness=7,gear_spin=360/9/2);
// Continues:
//   When constructing a crown gear you need to make it with the same given pressure and and tooth size as
//   the spur gear you wish to mate to it.  However, the teeth of a crown gear have pressure angle that varies
//   along the width of the tooth.  The vertical separation of the spur gear from the crown gear is given
//   by {{gear_dist()}} where you treat the crown gear as a rack.  The inner radius of the teeth on the
//   crown gear is the pitch radius determined by the gear's tooth size and number of teeth.  The face width
//   of a crown gear is limited by geometry, so if you make it too large you will get an error.
//   .
//   The geometry of these crown gears is tricky and not well documented by sources we have found.
//   If you know something about crown gears that could improve the implementation, please open an issue
//   on github.  
// Section: Backlash (Fitting Real Gears Together)
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
// Figure(2D,Big,VPT=[4.5244,64.112,0.0383045],VPR=[0,0,0],VPD=48.517,NoAxes): Backlash narrows the teeth by the specified length along the pitch circle.  Below the ideal gear appears in the lighter color and the darker color shows the same gear with a very large backlash, which appears with half of the backlash on either side of the tooth.  
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
// Figure(2D,Med,VPT=[0.532987,50.0891,0.0383045],VPR=[0,0,0],VPD=53.9078): Here two gears appear together with a more reasonable backlash applied to both gears. Again the lighter color shows the ideal gears and the darker shade shows the gear with backlash.  In this example, backlash is present on both of the meshing gears, so the total backlash of the system is the combined backlash from both gears.
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
// Figure(2D,Med,VPT=[0.532987,50.0891,0.0383045],VPR=[0,0,0],VPD=53.9078): Here the same gears as in the previous figure appear with backlash applied using the `backlash` parameter to {{gear_dist()}} to shift them apart.  The original ideal gears are in the lighter shade and the darker colored gears have been separated to create the backlash.  
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
// Usage: As a Function
//   vnf = spur_gear(mod=|circ_pitch=|diam_pitch=, teeth, [thickness], [helical=], [herringbone=], [pressure_angle=], [profile_shift=], [shorten=], [backlash=], [shaft_diam=], [hide=], [gear_spin=], [clearance=], [slices=], [internal=], [$gear_steps=], [atype=], [anchor=], [spin=], [orient=], [interior=]);
// Usage: As a Module
//   spur_gear(mod=|circ_pitch=|diam_pitch=, teeth, [thickness], [helical=], [herringbone=], [pressure_angle=], [profile_shift=], [shorten=], [backlash=], [shaft_diam=], [hide=], [gear_spin=], [clearance=], [slices=], [internal=], [$gear_steps=], [atype=], [anchor=], [spin=], [orient=], [interior=]) [ATTACHMENTS];
// Description:
//   Creates a involute spur gear, helical gear, herringbone gear, or a mask for an internal ring gear.
//   For more information about gears, see [A Quick Introduction to Gears](gears.scad#section-a-quick-introduction-to-gears).
//   Give the number of teeth. Specify size with `mod=`, `circ_pitch=` or
//   `diam_pitch=`, or inherit it from the parent; the fallback circular pitch is 5.
//   Spur gears have straight teeth and
//   mesh together on parallel shafts without creating any axial thrust.  The teeth engage suddenly across their
//   entire width, creating stress and noise.  Helical gears have angled teeth and engage more gradually, so they
//   run more smoothly and quietly, however they do produce thrust along the gear axis.  This can be
//   circumvented using herringbone or double helical gears, which have no axial thrust and also self-align.
//   Helical gears can mesh along shafts that are not parallel, where the angle between the shafts is
//   the sum of the helical angles of the two gears.
//   .
//   The module creates the gear in the XY plane, centered on the origin, with one tooth centered on the positive Y axis.
//   In order for two gears to mesh they must have the same tooth size and `pressure_angle`, and
//   generally the helical angles should be of opposite sign.  
//   The usual pressure angle (and default) is 20 degrees.  Another common value is 14.5 degrees.
//   Ideally the teeth count of two meshing gears will be relatively prime because this ensures that
//   every tooth on one gear will meet every tooth on the other, creating even wear.
//   .
//   The "pitch circle" of the gear is a reference circle where the circular pitch is defined that
//   is used to construct the gear.  It runs approximately through the centers of the teeth.  
//   Two basic gears will mesh when their pitch circles are tangent.  Anchoring for these gears is
//   done on the pitch circle by default, so basic gears can be meshed using anchoring.
//   However, when a gear has a small number of teeth, the basic gear form will result in undercutting,
//   which weakens the teeth.  To avoid this, profile shifting is automatically applied and in this
//   case, the distance between the gears is a complicated calculation and must be determined using {{gear_dist()}}.  
//   If you wish to override this correction, you can use `profile_shift=0`, or set it to a specific
//   value like 0.5.  Another complication with profile shifted gears is that the tips may be too long,
//   which can eat into the clearance space.  To address this problem you can use the `shorten` parameter,
//   which you can compute using {{gear_shorten()}}.
//   .
//   Helical gears can mesh with skew or crossed axes, a configuration sometimes called "screw gears".  
//   Without profile shifting, that angle is the  sum of the helical angles.
//   With profile shifting it is slightly different and is given by {{gear_skew_angle()}}.
//   These gears still mesh on the pitch circle when they are not profile shifted, but the correction to
//   gear separation for a proper mesh of profile shifted gears is different for skew gears and is
//   computed using {{gear_dist_skew()}}. 
//   .
//   To create space for gears to mesh in practice you will need to set a positive value for backlash, or
//   use the `backlash` argument to {{gear_dist()}}.  
// Arguments:
//   teeth = Total number of teeth around the entire perimeter
//   thickness = Thickness of gear.  Default: 10 
//   ---
//   mod = The module of the gear (pitch diameter / teeth)
//   circ_pitch = The circular pitch, the distance between teeth centers around the pitch circle.
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  The diametral pitch is a completely different thing than the pitch diameter.
//   helical = Teeth spiral around the gear at this angle, positive for left handed, negative for right handed.  Default: 0
//   herringbone = If true, and helical is set, creates a herringbone gear.  Default: False
//   pressure_angle = Controls how straight or bulged the tooth sides are. In degrees.  Default: 20
//   profile_shift = Profile shift factor x.  Default: "auto"
//   shorten = Shorten gear tips by the module times this value.  Needed for large profile shifted gears.  Default: 0
//   backlash = Gap between two meshing teeth, in the direction along the circumference of the pitch circle.  Default: 0
//   shaft_diam = Diameter of the hole in the center.  Default: 0 (no shaft hole)
//   hide = Number of teeth to delete to make this only a fraction of a circle.  Default: 0
//   gear_spin = Rotate the tooth geometry about the gear center before anchoring; attached children are not rotated.  Default: 0
//   clearance = Clearance gap at the bottom of the inter-tooth valleys.  Default: mod/4
//   slices = Number of vertical layers to divide gear into.  Useful for refining gears with `helical`.
//   internal = If true, create a mask for difference()ing from something else.
//   $gear_steps = Number of points to sample gear profile.  Default: 16
//   atype = Set to "root", "tip" or "pitch" to determine anchoring circle.  Default: "pitch"
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top toward, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   interior = Deprecated alias for internal.
// Side Effects:
//   If internal is true then the default tag is "remove"
// Anchor Types:
//   root = anchor on the root circle
//   pitch = anchor on the pitch circle (default)
//   tip = anchor on the tip circle
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
//   pr = pitch_radius(circ_pitch=circ_pitch, teeth=teeth);
//   left(10) {
//       profile_shift = 0;
//       d = gear_dist(circ_pitch=circ_pitch,teeth1=teeth,teeth2=0,profile_shift1=profile_shift);
//       back(d) spur_gear(circ_pitch=circ_pitch, teeth=teeth, thickness=thick, shaft_diam=shaft, profile_shift=profile_shift);
//       rack(circ_pitch=circ_pitch, teeth=3, thickness=thick, orient=BACK);
//       color("black") up(thick/2) linear_extrude(height=0.1) {
//           back(d) dashed_stroke(circle(r=pr), width=strokewidth, closed=true);
//           dashed_stroke([[-7.5,0],[7.5,0]], width=strokewidth);
//       }
//   }
//   right(10) {
//       profile_shift = 0.59;
//       d = gear_dist(circ_pitch=circ_pitch,teeth1=teeth,teeth2=0,profile_shift1=profile_shift);
//       back(d) spur_gear(circ_pitch=circ_pitch, teeth=teeth, thickness=thick, shaft_diam=shaft, profile_shift=profile_shift);
//       rack(circ_pitch=circ_pitch, teeth=3, thickness=thick, orient=BACK);
//       color("black") up(thick/2) linear_extrude(height=0.1) {
//           back(d)
//               dashed_stroke(circle(r=pr), width=strokewidth, closed=true);
//           dashed_stroke([[-7.5,0],[7.5,0]], width=strokewidth);
//       }
//   }
// Example(Anim,Med,NoAxes,Frames=8,VPT=[0,30,0],VPR=[0,0,0],VPD=300): Assembly of Gears
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
//   color("#f77")              zrot(a1) spur_gear(circ_pitch=circ_pitch,teeth=n1,thickness=thickness,shaft_diam=hole);
//   color("#7f7") back(d12)  zrot(a2) spur_gear(circ_pitch=circ_pitch,teeth=n2,thickness=thickness,shaft_diam=hole);
//   color("#77f") right(d13) zrot(a3) spur_gear(circ_pitch=circ_pitch,teeth=n3,thickness=thickness,shaft_diam=hole);
//   color("#fc7") left(d14)  zrot(a4) spur_gear(circ_pitch=circ_pitch,teeth=n4,thickness=thickness,shaft_diam=hole,hide=n4-3);
//   color("#ccc") fwd(d1r) right(circ_pitch*$t)
//       rack(circ_pitch=circ_pitch,teeth=n5,thickness=thickness,width=rack_base,anchor=CENTER,orient=BACK);
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
//          circ_pitch=circ_pitch, teeth=n, thickness=10,
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
//   gd = gear_dist(circ_pitch=circ_pitch, teeth1=cteeth, teeth2=pteeth);
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
    // BEGIN GEAR_API_COMPAT
    _p0="__gear_legacy_omitted__", _p1="__gear_legacy_omitted__", _p2="__gear_legacy_omitted__",
    _extra="__gear_legacy_omitted__",
    // END GEAR_API_COMPAT
    teeth, thickness, _named, mod, circ_pitch, diam_pitch, helical, herringbone, pressure_angle,
    profile_shift, shorten, backlash, shaft_diam, hide, gear_spin, clearance, slices, internal, atype,
    anchor, spin, orient, interior
) =
    // BEGIN GEAR_API_COMPAT
    let(_gear_args=_gear_legacy_args(
        "spur_gear()", [_p0,_p1,_p2], _extra,
        ["circ_pitch", "teeth", "thickness"], ["teeth", "thickness"],
        [teeth,thickness], circ_pitch, mod, diam_pitch))
    let(circ_pitch=_gear_args[0], teeth=_gear_args[1], thickness=_gear_args[2])
    // END GEAR_API_COMPAT

    assert(is_undef(_named), "spur_gear(): arguments after teeth, thickness must be named")

    let(
        shaft_diam=is_undef(shaft_diam)?0:shaft_diam, hide=is_undef(hide)?0:hide,
        backlash=is_undef(backlash)?0.0:backlash,
        profile_shift=is_undef(profile_shift)?"auto":profile_shift,
        herringbone=is_undef(herringbone)?false:herringbone, shorten=is_undef(shorten)?0:shorten,
        atype=is_undef(atype)?"pitch":atype, gear_spin=is_undef(gear_spin)?0:gear_spin,
        anchor=is_undef(anchor)?CENTER:anchor, spin=is_undef(spin)?0:spin,
        orient=is_undef(orient)?UP:orient
    )

    let(  
        dummy = !is_undef(interior) ? echo("In spur_gear(), the argument 'interior=' has been deprecated, and may be removed in the future.  Please use 'internal=' instead."):0,
        internal = first_defined([internal,interior,false]),
        circ_pitch = _inherit_gear_pitch(fname="spur_gear()", circ_pitch=circ_pitch, diam_pitch=diam_pitch, mod=mod),
        PA = _inherit_gear_pa(pressure_angle=pressure_angle),
        helical = _inherit_gear_helical(helical=helical, invert=!internal),
        thickness = _inherit_gear_thickness(thickness=thickness)
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
        profile_shift = auto_profile_shift(teeth=teeth,pressure_angle=PA,helical=helical,profile_shift=profile_shift),
        pr = pitch_radius(circ_pitch=circ_pitch, teeth=teeth, helical=helical),
        or = outer_radius(circ_pitch=circ_pitch, teeth=teeth, helical=helical, profile_shift=profile_shift, internal=internal,shorten=shorten),
        rr = root_radius(circ_pitch=circ_pitch, teeth=teeth, helical=helical,
                         clearance=clearance, profile_shift=profile_shift, internal=internal,
                         pressure_angle=PA, backlash=backlash),
        anchor_rad = atype=="pitch" ? pr
                   : atype=="tip" ? or
                   : atype=="root" ? rr
                   : assert(false,"atype must be one of \"root\", \"tip\" or \"pitch\""),
        circum = 2 * PI * pr,
        twist = 360*thickness*tan(helical)/circum,
        slices = default(slices, ceil(abs(twist)/360*segs(pr)+1)),
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
          ? let(
                wall_vnf = linear_sweep(rgn, height=thickness/2, twist=twist/2, slices=ceil(slices/2), center=false, caps=false),
                cap_vnf = vnf_from_region(rgn, transform=up(thickness/2)*zrot(twist/2))
            )
            vnf_join([
                wall_vnf, zflip(p=wall_vnf),
                cap_vnf,  zflip(p=cap_vnf),
            ])
          : zrot(twist/2, p=linear_sweep(rgn, height=thickness, twist=twist, slices=slices, center=true)),
        vnf = zrot(gear_spin, p=rvnf)
    ) reorient(anchor,spin,orient, h=thickness, r=anchor_rad, p=vnf);


module spur_gear(
    // BEGIN GEAR_API_COMPAT
    _p0="__gear_legacy_omitted__", _p1="__gear_legacy_omitted__", _p2="__gear_legacy_omitted__",
    _extra="__gear_legacy_omitted__",
    // END GEAR_API_COMPAT
    teeth, thickness, _named, mod, circ_pitch, diam_pitch, helical, herringbone, pressure_angle,
    profile_shift, shorten, backlash, shaft_diam, hide, gear_spin, clearance, slices, internal, atype,
    anchor, spin, orient, interior
)
    // BEGIN GEAR_API_COMPAT
    let(_gear_args=_gear_legacy_args(
        "spur_gear()", [_p0,_p1,_p2], _extra,
        ["circ_pitch", "teeth", "thickness"], ["teeth", "thickness"],
        [teeth,thickness], circ_pitch, mod, diam_pitch))
    let(circ_pitch=_gear_args[0], teeth=_gear_args[1], thickness=_gear_args[2])
    // END GEAR_API_COMPAT

    assert(is_undef(_named), "spur_gear(): arguments after teeth, thickness must be named")
 
    let(
        shaft_diam=is_undef(shaft_diam)?0:shaft_diam, hide=is_undef(hide)?0:hide,
        backlash=is_undef(backlash)?0.0:backlash,
        profile_shift=is_undef(profile_shift)?"auto":profile_shift,
        herringbone=is_undef(herringbone)?false:herringbone, shorten=is_undef(shorten)?0:shorten,
        atype=is_undef(atype)?"pitch":atype, gear_spin=is_undef(gear_spin)?0:gear_spin,
        anchor=is_undef(anchor)?CENTER:anchor, spin=is_undef(spin)?0:spin,
        orient=is_undef(orient)?UP:orient
    )
{
    dummy = !is_undef(interior) ? echo("In spur_gear(), the argument 'interior=' has been deprecated, and may be removed in the future.  Please use 'internal=' instead."):0;
    internal = first_defined([internal,interior,false]);
    circ_pitch = _inherit_gear_pitch(fname="spur_gear()", circ_pitch=circ_pitch, diam_pitch=diam_pitch, mod=mod);
    PA = _inherit_gear_pa(pressure_angle=pressure_angle);
    helical = _inherit_gear_helical(helical=helical, invert=!internal);
    thickness = _inherit_gear_thickness(thickness=thickness);
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
    profile_shift = auto_profile_shift(teeth=teeth,pressure_angle=PA,helical=helical,profile_shift=profile_shift);
    pr = pitch_radius(circ_pitch=circ_pitch, teeth=teeth, helical=helical);
    or = outer_radius(circ_pitch=circ_pitch, teeth=teeth, helical=helical, profile_shift=profile_shift, internal=internal,shorten=shorten);
    rr = root_radius(circ_pitch=circ_pitch, teeth=teeth, helical=helical, clearance=clearance, internal=internal,
                     profile_shift=profile_shift, pressure_angle=PA,  backlash=backlash);
    convexity = ceil(2 * teeth * hyp_adj_to_ang(or,rr)/180);
    anchor_rad = atype=="pitch" ? pr
               : atype=="tip" ? or
               : atype=="root" ? rr
               : assert(false,"atype must be one of \"root\", \"tip\" or \"pitch\"");
    circum = 2 * PI * pr;
    twist = 360*thickness*tan(helical)/circum;
    slices = default(slices, ceil(abs(twist)/360*segs(pr)+1));
    default_tag("remove", internal) {
        attachable(anchor,spin,orient, r=anchor_rad, l=thickness) {
            zrot(gear_spin)
            if (herringbone) {
                zflip_copy()
                linear_extrude(
                    height=thickness/2, center=false,
                    twist=twist/2, slices=ceil(slices/2),
                    convexity=convexity
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
                    convexity=convexity
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
// Usage: As a Function
//   rgn = spur_gear2d(mod=|circ_pitch=|diam_pitch=, teeth, [pressure_angle=], [profile_shift=], [shorten=], [backlash=], [helical=], [hide=], [gear_spin=], [clearance=], [internal=], [$gear_steps=], [shaft_diam=], [atype=], [anchor=], [spin=], [interior=]);
// Usage: As a Module
//   spur_gear2d(mod=|circ_pitch=|diam_pitch=, teeth, [pressure_angle=], [profile_shift=], [shorten=], [backlash=], [helical=], [hide=], [gear_spin=], [clearance=], [internal=], [$gear_steps=], [shaft_diam=], [atype=], [anchor=], [spin=], [interior=]) [ATTACHMENTS];
// Description:
//   Creates a 2D involute spur gear, or a mask for an internal ring gear.
//   For more information about gears, see [A Quick Introduction to Gears](gears.scad#section-a-quick-introduction-to-gears).
//   Give the number of teeth. Specify tooth size with `mod=`, `circ_pitch=` or
//   `diam_pitch=`, or inherit it from the parent; the fallback circular pitch is 5.  
//   .
//   The module creates the gear in centered on the origin, with one tooth centered on the positive Y axis.
//   In order for two gears to mesh they must have the same tooth size and `pressure_angle`
//   The usual pressure angle (and default) is 20 degrees.  Another common value is 14.5 degrees.
//   Ideally the teeth count of two meshing gears will be relatively prime because this ensures that
//   every tooth on one gear will meet every tooth on the other, creating even wear.
//   .
//   The "pitch circle" of the gear is a reference circle where the circular pitch is defined that
//   is used to construct the gear.  It runs approximately through the centers of the teeth.  
//   Two basic gears will mesh when their pitch circles are tangent.  Anchoring for these gears is
//   done on the pitch circle by default, so basic gears can be meshed using anchoring.
//   However, when a gear has a small number of teeth, the basic gear form will result in undercutting,
//   which weakens the teeth.  To avoid this, profile shifting is automatically applied and in this
//   case, the distance between the gears is a complicated calculation and must be determined using {{gear_dist()}}.  
//   If you wish to override this correction, you can use `profile_shift=0`, or set it to a specific
//   value like 0.5.  Another complication with profile shifted gears is that the tips may be too long,
//   which can eat into the clearance space.  To address this problem you can use the `shorten` parameter,
//   which you can compute using {{gear_shorten()}}.
//   .
//   To create space for gears to mesh in practice you will need to set a positive value for backlash, or
//   use the `backlash` argument to {{gear_dist()}}.  
// Arguments:
//   teeth = Total number of teeth around the spur gear.
//   ---
//   mod = The module of the gear (pitch diameter / teeth)
//   circ_pitch = The circular pitch, the distance between teeth centers around the pitch circle.
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  The diametral pitch is a completely different thing than the pitch diameter.
//   pressure_angle = Controls how straight or bulged the tooth sides are. In degrees.
//   profile_shift = Profile shift factor x.  Default: "auto"
//   shorten = Shorten gear tips by the module times this value.  Needed for large profile shifted gears.  Default: 0
//   backlash = Gap between two meshing teeth, in the direction along the circumference of the pitch circle.  Default: 0
//   helical = Adjust teeth form (stretch out the teeth) to give the cross section of a gear with this helical angle.  Default: 0
//   hide = Number of teeth to delete to make this only a fraction of a circle
//   gear_spin = Rotate the tooth geometry about the gear center before anchoring; attached children are not rotated.  Default: 0
//   clearance = Gap between top of a tooth on one gear and bottom of valley on a meshing gear.  Default: mod/4
//   internal = If true, create a mask for difference()ing from something else.
//   $gear_steps = Number of points to sample gear profile.  Default: 16
//   shaft_diam = If given, the diameter of the central shaft hole.
//   atype = Set to "root", "tip" or "pitch" to determine anchoring circle.  Default: "pitch"
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   interior = Deprecated alias for internal.
// Side Effects:
//   If internal is true then the default tag is "remove"
// Anchor Types:
//   root = anchor on the root circle
//   pitch = anchor on the pitch circle (default)
//   tip = anchor on the tip circle
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
//       pr = pitch_radius(circ_pitch=circ_pitch,teeth=teeth);
//       mr = gear_dist(circ_pitch=circ_pitch,teeth1=teeth,profile_shift1=profile_shift,teeth2=0);
//       back(mr) {
//           spur_gear2d(circ_pitch=circ_pitch, teeth=teeth, shaft_diam=shaft, profile_shift=profile_shift);
//           up(0.1) color("black")
//               dashed_stroke(circle(r=pr), width=strokewidth, closed=true);
//       }
//   }
//   module the_rack() {
//       $fn=72;
//       rack2d(circ_pitch=circ_pitch, teeth=3);
//       up(0.1) color("black")
//           dashed_stroke([[-7.5,0],[7.5,0]], width=strokewidth);
//   }
//   left(10) { the_gear(0); the_rack(); }
//   right(10) { the_gear(0.59); the_rack(); }
// Example(2D): Planetary Gear Assembly
//   rteeth=56; pteeth=16; cteeth=24;
//   circ_pitch=5; pa=20;
//   gd = gear_dist(circ_pitch=circ_pitch, teeth1=cteeth,teeth2=pteeth);
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
    // BEGIN GEAR_API_COMPAT
    _p0="__gear_legacy_omitted__", _p1="__gear_legacy_omitted__", _extra="__gear_legacy_omitted__",
    // END GEAR_API_COMPAT
    teeth, _named, mod, circ_pitch, diam_pitch, pressure_angle, profile_shift, shorten, backlash,
    helical, hide, gear_spin, clearance, internal, shaft_diam, atype, anchor, spin, interior
) =
    // BEGIN GEAR_API_COMPAT
    let(_gear_args=_gear_legacy_args(
        "spur_gear2d()", [_p0,_p1], _extra,
        ["circ_pitch", "teeth"], ["teeth"],
        [teeth], circ_pitch, mod, diam_pitch))
    let(circ_pitch=_gear_args[0], teeth=_gear_args[1])
    // END GEAR_API_COMPAT

    assert(is_undef(_named), "spur_gear2d(): arguments after teeth must be named")

    let(
        hide=is_undef(hide)?0:hide, backlash=is_undef(backlash)?0.0:backlash,
        profile_shift=is_undef(profile_shift)?"auto":profile_shift,
        shorten=is_undef(shorten)?0:shorten, shaft_diam=is_undef(shaft_diam)?0:shaft_diam,
        gear_spin=is_undef(gear_spin)?0:gear_spin, atype=is_undef(atype)?"pitch":atype,
        anchor=is_undef(anchor)?CENTER:anchor, spin=is_undef(spin)?0:spin
    )
 let(
        dummy = !is_undef(interior) ? echo("In spur_gear2d(), the argument 'interior=' has been deprecated, and may be removed in the future.  Please use 'internal=' instead."):0,
        internal = first_defined([internal,interior,false]),
        circ_pitch = _inherit_gear_pitch(fname="spur_gear2d()", circ_pitch=circ_pitch, diam_pitch=diam_pitch, mod=mod),
        PA = _inherit_gear_pa(pressure_angle=pressure_angle),
        helical = _inherit_gear_helical(helical=helical, invert=!internal)
    )
    assert(is_integer(teeth) && teeth>3)
    assert(is_finite(shaft_diam) && shaft_diam>=0)
    assert(is_integer(hide) && hide>=0 && hide<teeth)
    assert(is_finite(PA) && PA>=0 && PA<90, "Bad pressure_angle value.")
    assert(clearance==undef || is_finite(clearance))
    assert(is_finite(backlash) && backlash>=0)
    assert(is_finite(helical) && abs(helical)<90)
    assert(is_finite(gear_spin))
    let(
        profile_shift = auto_profile_shift(teeth=teeth,pressure_angle=PA,helical=helical,profile_shift=profile_shift),
        pr = pitch_radius(circ_pitch=circ_pitch, teeth=teeth, helical=helical),
        or = outer_radius(circ_pitch=circ_pitch, teeth=teeth, helical=helical, profile_shift=profile_shift, internal=internal,shorten=shorten),
        rr = root_radius(circ_pitch=circ_pitch, teeth=teeth, helical=helical,
                         clearance=clearance, profile_shift=profile_shift, internal=internal,
                         pressure_angle=PA, backlash=backlash),
        anchor_rad = atype=="pitch" ? pr
                   : atype=="tip" ? or
                   : atype=="root" ? rr
                   : assert(false,"atype must be one of \"root\", \"tip\" or \"pitch\""),
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
    ) reorient(anchor,spin, two_d=true, r=anchor_rad, p=rgn);


module spur_gear2d(
    // BEGIN GEAR_API_COMPAT
    _p0="__gear_legacy_omitted__", _p1="__gear_legacy_omitted__", _extra="__gear_legacy_omitted__",
    // END GEAR_API_COMPAT
    teeth, _named, mod, circ_pitch, diam_pitch, pressure_angle, profile_shift, shorten, backlash,
    helical, hide, gear_spin, clearance, internal, shaft_diam, atype, anchor, spin, interior
)
    // BEGIN GEAR_API_COMPAT
    let(_gear_args=_gear_legacy_args(
        "spur_gear2d()", [_p0,_p1], _extra,
        ["circ_pitch", "teeth"], ["teeth"],
        [teeth], circ_pitch, mod, diam_pitch))
    let(circ_pitch=_gear_args[0], teeth=_gear_args[1])
    // END GEAR_API_COMPAT

    assert(is_undef(_named), "spur_gear2d(): arguments after teeth must be named")
 
    let(
        hide=is_undef(hide)?0:hide, backlash=is_undef(backlash)?0.0:backlash,
        profile_shift=is_undef(profile_shift)?"auto":profile_shift,
        shorten=is_undef(shorten)?0:shorten, shaft_diam=is_undef(shaft_diam)?0:shaft_diam,
        gear_spin=is_undef(gear_spin)?0:gear_spin, atype=is_undef(atype)?"pitch":atype,
        anchor=is_undef(anchor)?CENTER:anchor, spin=is_undef(spin)?0:spin
    )
{
    dummy = !is_undef(interior) ? echo("In spur_gear2d(), the argument 'interior=' has been deprecated, and may be removed in the future.  Please use 'internal=' instead."):0;
    internal = first_defined([internal,interior,false]);
    circ_pitch = _inherit_gear_pitch(fname="spur_gear2d()", circ_pitch=circ_pitch, diam_pitch=diam_pitch, mod=mod);
    PA = _inherit_gear_pa(pressure_angle=pressure_angle);
    helical = _inherit_gear_helical(helical=helical, invert=!internal);
    checks =
        assert(is_integer(teeth) && teeth>3)
        assert(is_finite(shaft_diam) && shaft_diam>=0)
        assert(is_integer(hide) && hide>=0 && hide<teeth)
        assert(is_finite(PA) && PA>=0 && PA<90, "Bad pressure_angle value.")
        assert(clearance==undef || is_finite(clearance))
        assert(is_finite(backlash) && backlash>=0)
        assert(is_finite(helical) && abs(helical)<90)
        assert(is_finite(gear_spin));
    profile_shift = auto_profile_shift(teeth=teeth,pressure_angle=PA,helical=helical,profile_shift=profile_shift);
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
    pr = pitch_radius(circ_pitch=circ_pitch, teeth=teeth, helical=helical);
    or = outer_radius(circ_pitch=circ_pitch, teeth=teeth, helical=helical, profile_shift=profile_shift, internal=internal,shorten=shorten);
    rr = root_radius(circ_pitch=circ_pitch, teeth=teeth, helical=helical, clearance=clearance, internal=internal,
                     profile_shift=profile_shift, pressure_angle=PA,  backlash=backlash);
    anchor_rad = atype=="pitch" ? pr
               : atype=="tip" ? or
               : atype=="root" ? rr
               : assert(false,"atype must be one of \"root\", \"tip\" or \"pitch\"");
    attachable(anchor,spin, two_d=true, r=anchor_rad) {
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
// Usage: As a Module
//   ring_gear(mod=|circ_pitch=|diam_pitch=, teeth, [thickness], [backing], [$gear_steps=], [od=], [or=], [width=], [pressure_angle=], [helical=], [herringbone=], [profile_shift=], [clearance=], [backlash=], [anchor=], [spin=], [orient=], [atype=], [gear_spin=], [slices=]) [ATTACHMENTS];
// Description:
//   Creates a 3D involute ring gear.
//   Meshing gears must have the same tooth size, pressure angle and helical angle as usual.
//   Additionally, you must have more teeth on an internal gear than its mating external gear, and
//   the profile shift on the ring gear must be at least as big as the profile shift on the mating gear.
//   You may need to use {{auto_profile_shift()}} to find this value if your mating gear has a small number of teeth.
//   The gear spacing is given by {{gear_dist()}}.
// Arguments:
//   teeth = Total number of teeth around the spur gear.
//   thickness = Thickness of ring gear
//   backing = The width of the ring gear backing.  Default: height of teeth
//   ---
//   mod = The module of the gear (pitch diameter / teeth)
//   $gear_steps = Number of points to sample gear profile.  Default: 16
//   circ_pitch = The circular pitch, the distance between teeth centers around the pitch circle.
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  The diametral pitch is a completely different thing than the pitch diameter.
//   od = outer diameter of the ring
//   or = outer radius of the ring
//   width = width of the ring, measuring from tips of teeth to outside of ring.  
//   pressure_angle = Controls how straight or bulged the tooth sides are. In degrees.
//   helical = The angle of the rack teeth away from perpendicular to the gear axis of rotation.  Stretches out the tooth shapes.  Used to match helical spur gear pinions.  Default: 0
//   herringbone = If true, and helical is set, creates a herringbone gear.
//   profile_shift = Profile shift factor x for tooth profile.  Default: 0
//   clearance = Gap between top of a tooth on one gear and bottom of valley on a meshing gear (in millimeters)
//   backlash = Gap between two meshing teeth, in the direction along the circumference of the pitch circle
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top toward, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   atype = Anchoring radius: "pitch" or "outside". Default: "pitch"
//   gear_spin = Rotate tooth geometry about the gear center before anchoring; does not rotate attached children. Default: 0
//   slices = Axial slices used by the extrusion; calculated from twist when omitted or undef.
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
    // BEGIN GEAR_API_COMPAT
    _p0="__gear_legacy_omitted__", _p1="__gear_legacy_omitted__", _p2="__gear_legacy_omitted__",
    _p3="__gear_legacy_omitted__", _extra="__gear_legacy_omitted__",
    // END GEAR_API_COMPAT
    teeth, thickness, backing, _named, mod, circ_pitch, diam_pitch, od, or, width, pressure_angle,
    helical, herringbone, profile_shift, clearance, backlash, anchor, spin, orient, atype, gear_spin,
    slices
)
    // BEGIN GEAR_API_COMPAT
    let(_gear_args=_gear_legacy_args(
        "ring_gear()", [_p0,_p1,_p2,_p3], _extra,
        ["circ_pitch", "teeth", "thickness", "backing"], ["teeth", "thickness", "backing"],
        [teeth,thickness,backing], circ_pitch, mod, diam_pitch))
    let(circ_pitch=_gear_args[0], teeth=_gear_args[1], thickness=_gear_args[2], backing=_gear_args[3])
    // END GEAR_API_COMPAT

    assert(is_undef(_named), "ring_gear(): arguments after teeth, thickness, backing must be named")
 
    let(
        thickness=is_undef(thickness)?10:thickness,
        herringbone=is_undef(herringbone)?false:herringbone,
        profile_shift=is_undef(profile_shift)?0:profile_shift,
        backlash=is_undef(backlash)?0.0:backlash, gear_spin=is_undef(gear_spin)?0:gear_spin,
        anchor=is_undef(anchor)?CENTER:anchor, atype=is_undef(atype)?"pitch":atype,
        spin=is_undef(spin)?0:spin, orient=is_undef(orient)?UP:orient
    )
{
    circ_pitch = _inherit_gear_pitch(fname="ring_gear()",circ_pitch=circ_pitch, diam_pitch=diam_pitch, mod=mod);
    PA = _inherit_gear_pa(pressure_angle=pressure_angle);
    helical = _inherit_gear_helical(helical=helical);       //Maybe broken???
    thickness = _inherit_gear_thickness(thickness=thickness);
    checks =
        assert(in_list(atype,["outside","pitch"]))
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
    pr = pitch_radius(circ_pitch=circ_pitch, teeth=teeth, helical=helical);
    ar = outer_radius(circ_pitch=circ_pitch, teeth=teeth, helical=helical, profile_shift=profile_shift, internal=true);
    //rr=_root_radius_basic(circ_pitch, teeth, clearance, profile_shift=profile_shift, internal=true, helical=helical);
    rr = root_radius(circ_pitch=circ_pitch, teeth=teeth, helical=helical, clearance=clearance, internal=true,
                     profile_shift=profile_shift);
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
    slices = default(slices, ceil(abs(twist)/360*segs(pr)+1));
    attachable(anchor,spin,orient, h=thickness, r=atype=="outside"?or:pr) {
        zrot(gear_spin)
        if (herringbone) {
            zflip_copy()
            linear_extrude(height=thickness/2, center=false, twist=twist/2, slices=ceil(slices/2), convexity=12) {
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
            linear_extrude(height=thickness,center=true, twist=twist, slices=slices, convexity=12) {
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
// Usage: As a Module
//   ring_gear2d(mod=|circ_pitch=|diam_pitch=, teeth, [backing], [$gear_steps=], [od=], [or=], [width=], [helical=], [pressure_angle=], [profile_shift=], [clearance=], [backlash=], [anchor=], [spin=], [atype=], [gear_spin=], [shorten=]) [ATTACHMENTS];
// Description:
//   Creates a 2D involute ring gear.  
//   Meshing gears must have the same tooth size, pressure angle and helical angle as usual.
//   Additionally, you must have more teeth on an internal gear than its mating external gear, and
//   the profile shift on the ring gear must be at least as big as the profile shift on the mating gear.
//   You may need to use {{auto_profile_shift()}} to find this value if your mating gear has a small number of teeth.
//   The gear spacing is given by {{gear_dist()}}.
// Arguments:
//   teeth = Total number of teeth around the spur gear.
//   backing = The width of the ring gear backing.  Default: height of teeth
//   ---
//   mod = The module of the gear (pitch diameter / teeth)
//   $gear_steps = Number of points to sample gear profile.  Default: 16
//   circ_pitch = The circular pitch, the distance between teeth centers around the pitch circle.
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  The diametral pitch is a completely different thing than the pitch diameter.
//   od = outer diameter of the ring
//   or = outer radius of the ring
//   width = width of the ring, measuring from tips of teeth to outside of ring.  
//   helical = The angle of the rack teeth away from perpendicular to the gear axis of rotation.  Stretches out the tooth shapes.  Used to match helical spur gear pinions.  Default: 0
//   pressure_angle = Controls how straight or bulged the tooth sides are. In degrees.
//   profile_shift = Profile shift factor x for tooth profile.  Default: 0
//   clearance = Gap between top of a tooth on one gear and bottom of valley on a meshing gear (in millimeters)
//   backlash = Gap between two meshing teeth, in the direction along the circumference of the pitch circle
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   atype = Anchoring radius: "pitch" or "outside". Default: "pitch"
//   gear_spin = Rotate tooth geometry about the gear center before anchoring; does not rotate attached children. Default: 0
//   shorten = Shorten tips by this factor times the module. Default: 0
// Anchor Types:
//   pitch = anchor on the pitch circle (default)
//   outside = outside edge of the gear
// Example(2D,Big):  Meshing a ring gear with a spur gear
//   circ_pitch=5; teeth1=50; teeth2=18;
//   dist = gear_dist(circ_pitch=circ_pitch, teeth1=teeth1, teeth2=teeth2, internal1=true);
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
    // BEGIN GEAR_API_COMPAT
    _p0="__gear_legacy_omitted__", _p1="__gear_legacy_omitted__", _p2="__gear_legacy_omitted__",
    _extra="__gear_legacy_omitted__",
    // END GEAR_API_COMPAT
    teeth, backing, _named, mod, circ_pitch, diam_pitch, od, or, width, helical, pressure_angle,
    profile_shift, clearance, backlash, anchor, spin, atype, gear_spin, shorten
)
    // BEGIN GEAR_API_COMPAT
    let(_gear_args=_gear_legacy_args(
        "ring_gear2d()", [_p0,_p1,_p2], _extra,
        ["circ_pitch", "teeth", "backing"], ["teeth", "backing"],
        [teeth,backing], circ_pitch, mod, diam_pitch))
    let(circ_pitch=_gear_args[0], teeth=_gear_args[1], backing=_gear_args[2])
    // END GEAR_API_COMPAT

    assert(is_undef(_named), "ring_gear2d(): arguments after teeth, backing must be named")
 
    let(
        profile_shift=is_undef(profile_shift)?0:profile_shift,
        backlash=is_undef(backlash)?0.0:backlash, atype=is_undef(atype)?"pitch":atype,
        gear_spin=is_undef(gear_spin)?0:gear_spin, shorten=is_undef(shorten)?0:shorten,
        anchor=is_undef(anchor)?CENTER:anchor, spin=is_undef(spin)?0:spin
    )
{
    
    circ_pitch = _inherit_gear_pitch(fname="ring_gear2d()",circ_pitch=circ_pitch, diam_pitch=diam_pitch, mod=mod);
    PA = _inherit_gear_pa(pressure_angle=pressure_angle);
    helical = _inherit_gear_helical(helical=helical);
    checks =
        assert(in_list(atype,["outside","pitch"]))
        assert(is_finite(profile_shift), "Profile shift for ring gears must be numerical")
        assert(is_integer(teeth) && teeth>3)
        assert(num_defined([backing,or,od,width])<=1, "Cannot define more than one of backing, or, od and width")
        assert(is_finite(PA) && PA>=0 && PA<90, "Bad pressure_angle value.")
        assert(is_finite(helical) && abs(helical)<90)
        assert(clearance==undef || (is_finite(clearance) && clearance>=0))
        assert(is_finite(backlash) && backlash>=0)
        assert(is_finite(gear_spin));
    pr = pitch_radius(circ_pitch=circ_pitch, teeth=teeth, helical=helical);
    ar = outer_radius(circ_pitch=circ_pitch, teeth=teeth, helical=helical, profile_shift=profile_shift, internal=true);
    //rr=_root_radius_basic(circ_pitch, teeth, clearance, profile_shift=profile_shift, internal=true);
    rr = root_radius(circ_pitch=circ_pitch, teeth=teeth, helical=helical, clearance=clearance, internal=true,
                     profile_shift=profile_shift);
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
    attachable(anchor,spin, two_d=true, r=atype=="pitch"?pr:or) {
        zrot(gear_spin)
        difference() {
            circle(r=or);
            spur_gear2d(
                circ_pitch = circ_pitch,
                teeth = teeth,
                pressure_angle = PA,
                helical = helical,
                clearance = clearance,
                backlash = backlash,shorten=shorten,
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
//   rack(pitch=|mod=|circ_pitch=|diam_pitch=, teeth, [thickness], [backing], [bottom=], [width=], [helical=], [herringbone=], [profile_shift=], [pressure_angle=], [backlash=], [clearance=], [anchor=], [spin=], [orient=], [gear_travel=]) [ATTACHMENTS];
// Usage: As a Function
//   vnf = rack(pitch=|mod=|circ_pitch=|diam_pitch=, teeth, [thickness], [backing], [bottom=], [width=], [helical=], [herringbone=], [profile_shift=], [pressure_angle=], [backlash=], [clearance=], [anchor=], [spin=], [orient=], [gear_travel=]);
// Description:
//   This is used to create a 3D rack, which is a linear bar with teeth that a gear can roll along.
//   A rack can mesh with any gear that has the same `circ_pitch` and `pressure_angle`.  A helical rack meshes with a gear with the opposite
//   helical angle.   
//   When called as a function, returns a 3D [VNF](vnf.scad) for the rack.
//   When called as a module, creates a 3D rack shape.
//   .
//   By default the rack has a backing whose height is equal to the height of the teeth.  You can specify a different backing size
//   or you can specify the total width of the rack (from the bottom of the rack to tooth tips) or the
//   bottom point of the rack, which is the distance from the pitch line to the bottom of the rack.
//   .
//   The rack appears oriented with
//   its teeth pointed UP, so to mesh with gears in the XY plane, use `orient=BACK` or `orient=FWD` and apply any desired rotation.  
//   The pitch line of the rack is aligned with the x axis, the TOP anchors are at the tips of the teeth and the BOTTOM anchors at
//   the bottom of the backing.  Note that for helical racks the corner anchors still point at 45° angles.  
// Arguments:
//   teeth = Total number of teeth along the rack. Required.
//   thickness = Thickness of rack. Inherits from the parent when omitted or undef; fallback: 10
//   backing = Distance from bottom of rack to the roots of the rack's teeth.  (Alternative to bottom or width.)  Default: height of rack teeth
//   ---
//   mod = The module of the gear (pitch diameter / teeth)
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  The diametral pitch is a completely different thing than the pitch diameter.
//   pitch = Normal tooth pitch, perpendicular to the tooth lines. Exact synonym for circ_pitch. Inherits when no size is specified; fallback: 5
//   circ_pitch = Synonym for pitch. Spacing along the rack is pitch/cos(helical). Specify only one of pitch, circ_pitch, mod, and diam_pitch.
//   bottom = Distance from rack's pitch line (the x-axis) to the bottom of the rack.  (Alternative to backing or width)
//   width = Distance from base of rack to tips of teeth (alternative to bottom and backing).
//   helical = The angle of the rack teeth away from perpendicular to the rack length.  Used to match helical spur gear pinions.  Default: 0
//   herringbone = If true, and helical is set, creates a herringbone rack.
//   profile_shift = Profile shift factor x.  Default: 0
//   pressure_angle = Controls how straight or bulged the tooth sides are. In degrees.  Default: 20
//   backlash = Gap between two meshing teeth, in the direction along the circumference of the pitch circle.  Default: 0
//   clearance = Clearance gap at the bottom of the inter-tooth valleys.  Default: module/4
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top toward, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   gear_travel = Translate the rack along its length without moving its anchors or children. Default: 0
// Named Anchors:
//   "root" = At the base of the teeth, at the center of rack.
//   "root-left" = At the base of the teeth, at the left end of the rack.
//   "root-right" = At the base of the teeth, at the right end of the rack.
//   "root-back" = At the base of the teeth, at the back of the rack.
//   "root-front" = At the base of the teeth, at the front of the rack.
// Example(NoScales,VPR=[60,0,325],VPD=130):
//   rack(pitch=5, 10, 5);
// Example(NoScales,VPT=[0.317577,3.42688,7.83665],VPR=[27.7,0,359.8],VPD=139.921): Rack for Helical Gear
//   rack(circ_pitch=5, teeth=10, thickness=5, backing=5, helical=30);
// Example(NoScales): Metric Rack, oriented BACK to align with a gear in default orientation.  With profile shifting set to zero the gears mesh at their pitch circles.  
//   rack(mod=2, teeth=10, thickness=5, bottom=5, pressure_angle=14.5,orient=BACK);
//   color("red") spur_gear(mod=2, teeth=18, thickness=5, pressure_angle=14.5,anchor=FRONT,profile_shift=0);
// Example(NoScales): Orienting the rack to the right using {zrot()}.  In this case the gear has automatic profile shifting so we must use {{gear_dist()}} to correctly position the gear.  
//   zrot(-90)rack(mod=2, teeth=6, thickness=5, bottom=5, pressure_angle=14.5,orient=BACK);
//   color("red")
//    right(gear_dist(mod=2,teeth1=0,teeth2=12,pressure_angle=14.5))
//      spur_gear(mod=2, teeth=12, thickness=5, pressure_angle=14.5);
// Example(NoScales,Anim,VPT=[0,0,12],VPD=100,Frames=18): Rack and Pinion with helical teeth
//   teeth1 = 16; teeth2 = 16;
//   pitch = 5; thick = 5; helical = 30;
//   pr = pitch_radius(circ_pitch=pitch, teeth=teeth2, helical=helical);
//   pos = 3*(1-2*abs($t-1/2))-1.5;
//   right(pr*2*PI/teeth2*pos)
//       rack(circ_pitch=pitch, teeth=teeth1, thickness=thick, helical=helical);
//   up(pr)
//       spur_gear(
//           circ_pitch=pitch, teeth=teeth2,
//           thickness = thick,
//           helical = -helical,
//           shaft_diam = 5,
//           orient = BACK,
//           gear_spin = 180-pos*360/teeth2);
// Example(NoAxes,VPT=[-7.10396,-9.70691,3.50121],VPR=[60.2,0,325],VPD=213.262): Skew axis helical gear and rack engagement.
//    mod=5; teeth=8; helical1=17.5; helical2=22.5;
//    d = gear_dist_skew(mod=mod, teeth1=teeth, teeth2=0, helical1=helical1,helical2=helical2);
//    rack(mod=mod, teeth=5, thickness=30, helical=helical2, orient=FWD);
//    color("lightblue")
//      yrot(-helical1-helical2) fwd(d)
//      spur_gear(mod=mod, teeth=teeth, helical=helical1, gear_spin=180/teeth, thickness=30);

module rack(
    // BEGIN GEAR_API_COMPAT
    _p0="__gear_legacy_omitted__", _p1="__gear_legacy_omitted__", _p2="__gear_legacy_omitted__",
    _p3="__gear_legacy_omitted__", _extra="__gear_legacy_omitted__",
    // END GEAR_API_COMPAT
    teeth, thickness, backing, _named, mod, diam_pitch, circ_pitch, pitch, bottom, width, helical,
    herringbone, profile_shift, pressure_angle, backlash, clearance, anchor, spin, orient, gear_travel
)
    let(circ_pitch=_rack_circ_pitch("rack()",pitch,circ_pitch,mod,diam_pitch))
    // BEGIN GEAR_API_COMPAT
    let(_gear_args=_gear_legacy_args(
        "rack()", [_p0,_p1,_p2,_p3], _extra,
        ["circ_pitch", "teeth", "thickness", "backing"], ["teeth", "thickness", "backing"],
        [teeth,thickness,backing], circ_pitch, mod, diam_pitch))
    let(circ_pitch=_gear_args[0], teeth=_gear_args[1], thickness=_gear_args[2], backing=_gear_args[3])
    // END GEAR_API_COMPAT

    assert(is_undef(_named), "rack(): arguments after teeth, thickness, backing must be named")
 
    let(
        backlash=is_undef(backlash)?0.0:backlash, herringbone=is_undef(herringbone)?false:herringbone,
        profile_shift=is_undef(profile_shift)?0:profile_shift,
        gear_travel=is_undef(gear_travel)?0:gear_travel, anchor=is_undef(anchor)?CENTER:anchor,
        spin=is_undef(spin)?0:spin, orient=is_undef(orient)?UP:orient
    )
{
    pitch = _inherit_gear_pitch(fname="rack()",circ_pitch=circ_pitch, diam_pitch=diam_pitch, mod=mod);
    PA = _inherit_gear_pa(pressure_angle=pressure_angle);
    helical = _inherit_gear_helical(helical=helical);
    thickness = _inherit_gear_thickness(thickness=thickness);
    checks=
        assert(num_defined([backing,bottom,width])<=1,
               "rack(): specify only one of backing, bottom, or width")
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
    a = _adendum(circ_pitch=pitch, profile_shift=profile_shift);
    d = _dedendum(circ_pitch=pitch, clearance=clearance, profile_shift=profile_shift);
    bottom = is_def(bottom) ?
                 assert(is_finite(bottom) && bottom>d, "bottom is invalid or too small for teeth")
                 bottom
           : is_def(width) ?
                 assert(is_finite(width) && width>a+d, "width is invalid or too small for teeth")
                 width - a
           : is_def(backing) ?
                 assert(all_positive([backing]), "backing must be a positive value")
                 backing+d
           : 2*d+a;  // default case
    l = teeth * trans_pitch;
    anchors = [
        named_anchor("root",        [0,0,-d],            BACK),
        named_anchor("root-left",   [-l/2,0,-d],         LEFT),
        named_anchor("root-right",  [ l/2,0,-d],         RIGHT),
        named_anchor("root-front",  [0,-thickness/2,-d], FWD),
        named_anchor("root-back",   [0, thickness/2,-d], BACK),
    ];
    endfix = sin(helical)*thickness/2;
    override = function(anchor)
        anchor.z==1 ? [ [anchor.x*l/2-endfix*anchor.y,anchor.y*thickness/2,a], undef, undef]
      : anchor.x!=0 ? [ [anchor.x*l/2-endfix*anchor.y,anchor.y*thickness/2,anchor.z*bottom], undef,undef]
      :               undef;
    size = [l, thickness, 2*bottom];
    attachable(anchor,spin,orient, size=size, anchors=anchors, override=override) {
        right(gear_travel)
        xrot(90) {
            if (herringbone) {
                zflip_copy()
                skew(axz=-helical) 
                linear_extrude(height=thickness/2, center=false, convexity=teeth*2) {
                    rack2d(
                        circ_pitch = pitch,
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
                        circ_pitch = pitch,
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
    // BEGIN GEAR_API_COMPAT
    _p0="__gear_legacy_omitted__", _p1="__gear_legacy_omitted__", _p2="__gear_legacy_omitted__",
    _p3="__gear_legacy_omitted__", _extra="__gear_legacy_omitted__",
    // END GEAR_API_COMPAT
    teeth, thickness, backing, _named, mod, diam_pitch, circ_pitch, pitch, bottom, width, helical,
    herringbone, profile_shift, pressure_angle, backlash, clearance, anchor, spin, orient, gear_travel
) =
    let(circ_pitch=_rack_circ_pitch("rack()",pitch,circ_pitch,mod,diam_pitch))
    // BEGIN GEAR_API_COMPAT
    let(_gear_args=_gear_legacy_args(
        "rack()", [_p0,_p1,_p2,_p3], _extra,
        ["circ_pitch", "teeth", "thickness", "backing"], ["teeth", "thickness", "backing"],
        [teeth,thickness,backing], circ_pitch, mod, diam_pitch))
    let(circ_pitch=_gear_args[0], teeth=_gear_args[1], thickness=_gear_args[2], backing=_gear_args[3])
    // END GEAR_API_COMPAT

    assert(is_undef(_named), "rack(): arguments after teeth, thickness, backing must be named")

    let(
        backlash=is_undef(backlash)?0.0:backlash, herringbone=is_undef(herringbone)?false:herringbone,
        profile_shift=is_undef(profile_shift)?0:profile_shift,
        gear_travel=is_undef(gear_travel)?0:gear_travel, anchor=is_undef(anchor)?CENTER:anchor,
        spin=is_undef(spin)?0:spin, orient=is_undef(orient)?UP:orient
    )

    let(
        pitch = _inherit_gear_pitch(fname="rack()",circ_pitch=circ_pitch, diam_pitch=diam_pitch, mod=mod),
        PA = _inherit_gear_pa(pressure_angle=pressure_angle),
        helical = _inherit_gear_helical(helical=helical),
        thickness = _inherit_gear_thickness(thickness=thickness)
    )
    assert(num_defined([backing,bottom,width])<=1,
               "rack(): specify only one of backing, bottom, or width")
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
        a = _adendum(circ_pitch=pitch, profile_shift=profile_shift),
        d = _dedendum(circ_pitch=pitch, clearance=clearance, profile_shift=profile_shift),
        bottom = is_def(bottom) ?
                     assert(is_finite(bottom) && bottom>d, "bottom is invalid or too small for teeth")
                     bottom
               : is_def(width) ?
                     assert(is_finite(width) && width>a+d, "width is invalid or too small for teeth")
                     width - a
               : is_def(backing) ?
                     assert(all_positive([backing]), "backing must be a positive value")
                     backing+d
               : 2*d+a,  // default case
        l = teeth * trans_pitch,
        path = rack2d(
            circ_pitch = pitch,
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
// Usage: As a Function
//   path = rack2d(pitch=|mod=|circ_pitch=|diam_pitch=, teeth, [backing], [bottom=], [width=], [helical=], [pressure_angle=], [profile_shift=], [backlash=], [clearance=], [gear_travel=], [rounding=], [anchor=], [spin=]);
// Usage: As a Module
//   rack2d(pitch=|mod=|circ_pitch=|diam_pitch=, teeth, [backing], [bottom=], [width=], [helical=], [pressure_angle=], [profile_shift=], [backlash=], [clearance=], [gear_travel=], [rounding=], [anchor=], [spin=]) [ATTACHMENTS];
// Description:
//   Create a 2D rack, a linear bar with teeth that a gear can roll along.
//   A rack can mesh with any spur gear or helical gear that has the same `circ_pitch` and `pressure_angle`.  
//   When called as a function, returns a 2D path for the outline of the rack.
//   When called as a module, creates a 2D rack shape.
//   .
//   By default the rack has a backing whose height is equal to the height of the teeth.  You can specify a different backing size
//   or you can specify the total width of the rack (from the bottom of the rack to tooth tips) or the
//   bottom point of the rack, which is the distance from the pitch line to the bottom of the rack.
//   .
//   The rack appears with its pitch line on top of the x axis.  The BACK anchor refers to the tips of the teeth and the FRONT
//   anchor refers to the front of the backing.  You can use named anchors to access the roots of the teeth.  
// Arguments:
//   teeth = Total number of teeth along the rack
//   backing = Distance from bottom of rack to the roots of the rack's teeth.  (Alternative to bottom or width.)  Default: height of rack teeth
//   ---
//   mod = The module of the gear (pitch diameter / teeth)
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  The diametral pitch is a completely different thing than the pitch diameter.
//   pitch = Normal tooth pitch, perpendicular to the tooth lines. Exact synonym for circ_pitch. Inherits when no size is specified; fallback: 5
//   circ_pitch = Synonym for pitch. Spacing along the rack is pitch/cos(helical). Specify only one of pitch, circ_pitch, mod, and diam_pitch.
//   bottom = Distance from rack's pitch line (the x-axis) to the bottom of the rack.  (Alternative to backing or width)
//   width = Distance from base of rack to tips of teeth (alternative to bottom and backing).
//   helical = The angle of the rack teeth away from perpendicular to the rack length.  Stretches out the tooth shapes.  Used to match helical spur gear pinions.  Default: 0
//   pressure_angle = Controls how straight or bulged the tooth sides are. In degrees.
//   profile_shift = Profile shift factor x for tooth shape.  Default: 0
//   backlash = Gap between two meshing teeth, in the direction along the circumference of the pitch circle
//   clearance = Clearance gap at the bottom of the inter-tooth valleys.  Default: module/4
//   gear_travel = The distance the rack should be moved by linearly.  Default: 0
//   rounding = If true, rack tips and valleys are slightly rounded.  Default: true
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
// Named Anchors:
//   "root" = At the height of the teeth, at the center of rack.
//   "root-left" = At the height of the teeth, at the left end of the rack.
//   "root-right" = At the height of the teeth, at the right end of the rack.
// Example(2D):
//   rack2d(pitch=5, 10);
// Example(2D): Called as a Function
//   path = rack2d(circ_pitch=8, teeth=8, pressure_angle=25);
//   polygon(path);

function rack2d(
    // BEGIN GEAR_API_COMPAT
    _p0="__gear_legacy_omitted__", _p1="__gear_legacy_omitted__", _p2="__gear_legacy_omitted__",
    _extra="__gear_legacy_omitted__",
    // END GEAR_API_COMPAT
    teeth, backing, _named, mod, diam_pitch, circ_pitch, pitch, bottom, width, helical, pressure_angle,
    profile_shift, backlash, clearance, gear_travel, rounding, anchor, spin
) =
    let(circ_pitch=_rack_circ_pitch("rack2d()",pitch,circ_pitch,mod,diam_pitch))
    // BEGIN GEAR_API_COMPAT
    let(_gear_args=_gear_legacy_args(
        "rack2d()", [_p0,_p1,_p2], _extra,
        ["circ_pitch", "teeth", "backing"], ["teeth", "backing"],
        [teeth,backing], circ_pitch, mod, diam_pitch))
    let(circ_pitch=_gear_args[0], teeth=_gear_args[1], backing=_gear_args[2])
    // END GEAR_API_COMPAT

    assert(is_undef(_named), "rack2d(): arguments after teeth, backing must be named")

    let(
        backlash=is_undef(backlash)?0:backlash, profile_shift=is_undef(profile_shift)?0:profile_shift,
        gear_travel=is_undef(gear_travel)?0:gear_travel, rounding=is_undef(rounding)?true:rounding,
        anchor=is_undef(anchor)?CENTER:anchor, spin=is_undef(spin)?0:spin
    )
 let(
        pitch = _inherit_gear_pitch(fname="rack2d()",circ_pitch=circ_pitch, diam_pitch=diam_pitch, mod=mod),
        PA = _inherit_gear_pa(pressure_angle=pressure_angle),
        helical = _inherit_gear_helical(helical=helical),
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
        adendum = _adendum(circ_pitch=pitch, profile_shift=profile_shift),
        dedendum = _dedendum(circ_pitch=pitch, clearance=clearance, profile_shift=profile_shift),
        clear = default(clearance, 0.25 * mod),
        bottom = is_def(bottom) ?
                     assert(is_finite(bottom) && bottom>dedendum, "bottom is invalid or too small for teeth")
                     bottom
               : is_def(width) ?
                     assert(is_finite(width) && width>adendum+dedendum, "width is invalid or too small for teeth")
                     width - adendum
               : is_def(backing) ?
                     assert(all_positive([backing]), "backing must be a positive value")
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
            named_anchor("root",        [   0,-dedendum,0],  BACK),
            named_anchor("root-left",   [-l/2,-dedendum,0],  LEFT),
            named_anchor("root-right",  [ l/2,-dedendum,0],  RIGHT),
        ],
        override = [
           [[0,1] , [[0,adendum]]],
           [[1,1] , [[l/2,adendum]]],
           [[-1,1] , [[-l/2,adendum]]],
        ]
    ) reorient(anchor,spin, two_d=true, size=size, anchors=anchors, override=override, p=path);



module rack2d(
    // BEGIN GEAR_API_COMPAT
    _p0="__gear_legacy_omitted__", _p1="__gear_legacy_omitted__", _p2="__gear_legacy_omitted__",
    _extra="__gear_legacy_omitted__",
    // END GEAR_API_COMPAT
    teeth, backing, _named, mod, diam_pitch, circ_pitch, pitch, bottom, width, helical, pressure_angle,
    profile_shift, backlash, clearance, gear_travel, rounding, anchor, spin
)
    let(circ_pitch=_rack_circ_pitch("rack2d()",pitch,circ_pitch,mod,diam_pitch))
    // BEGIN GEAR_API_COMPAT
    let(_gear_args=_gear_legacy_args(
        "rack2d()", [_p0,_p1,_p2], _extra,
        ["circ_pitch", "teeth", "backing"], ["teeth", "backing"],
        [teeth,backing], circ_pitch, mod, diam_pitch))
    let(circ_pitch=_gear_args[0], teeth=_gear_args[1], backing=_gear_args[2])
    // END GEAR_API_COMPAT

    assert(is_undef(_named), "rack2d(): arguments after teeth, backing must be named")
 
    let(
        backlash=is_undef(backlash)?0:backlash, profile_shift=is_undef(profile_shift)?0:profile_shift,
        gear_travel=is_undef(gear_travel)?0:gear_travel, rounding=is_undef(rounding)?true:rounding,
        anchor=is_undef(anchor)?CENTER:anchor, spin=is_undef(spin)?0:spin
    )
{
    pitch = _inherit_gear_pitch(fname="rack2d()",circ_pitch=circ_pitch, diam_pitch=diam_pitch, mod=mod);
    PA = _inherit_gear_pa(pressure_angle=pressure_angle);
    helical = _inherit_gear_helical(helical=helical);
    checks =
        assert(is_integer(teeth) && teeth>0)
        assert(is_finite(PA) && PA>=0 && PA<90, "Bad pressure_angle value.")
        assert(clearance==undef || (is_finite(clearance) && clearance>=0))
        assert(is_finite(backlash) && backlash>=0)
        assert(is_finite(helical) && abs(helical)<90)
        assert(is_finite(gear_travel))
        assert(num_defined([width,backing,bottom])<=1, "Can define only one of width, backing and bottom");
    trans_pitch = pitch / cos(helical);
    a = _adendum(circ_pitch=pitch, profile_shift=profile_shift);
    d = _dedendum(circ_pitch=pitch, clearance=clearance, profile_shift=profile_shift);
    bottom = is_def(bottom) ?
                 assert(is_finite(bottom) && bottom>d, "bottom is invalid or too small for teeth")
                 bottom
           : is_def(width) ?
                 assert(is_finite(width) && width>a+d, "width is invalid or too small for teeth")
                 width - a
           : is_def(backing) ?
                 assert(all_positive([backing]), "backing must be a positive value")
                 backing+d
           : 2*d+a;  // default case
    l = teeth * trans_pitch;
    path = rack2d(
        circ_pitch = pitch,
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
        named_anchor("root",        [   0,-d,0],  BACK),
        named_anchor("root-left",   [-l/2,-d,0],  LEFT),
        named_anchor("root-right",  [ l/2,-d,0],  RIGHT),
    ];
    override = [
       [[0,1] , [[0,a]]],
       [[1,1] , [[l/2,a]]],
       [[-1,1] , [[-l/2,a]]],
    ];
    attachable(anchor,spin, two_d=true, size=size, anchors=anchors, override=override) {
        right(gear_travel) polygon(path);
        children();
    }
}



// Function&Module: crown_gear()
// Synopsis: Creates a crown gear that can mesh with a spur gear.
// SynTags: Geom, VNF
// Topics: Gears, Parts
// See Also: rack(), rack2d(), spur_gear(), spur_gear2d(), bevel_pitch_angle(), bevel_gear()
// Usage: As a Function
//   vnf = crown_gear(mod=|circ_pitch=|diam_pitch=, teeth, [backing], [face_width], [bottom=], [thickness=], [pressure_angle=], [clearance=], [backlash=], [profile_shift=], [slices=], [anchor=], [spin=], [orient=], [gear_spin=]);
// Usage: As a Module
//   crown_gear(mod=|circ_pitch=|diam_pitch=, teeth, [backing], [face_width], [bottom=], [thickness=], [pressure_angle=], [clearance=], [backlash=], [profile_shift=], [slices=], [anchor=], [spin=], [orient=], [gear_spin=]) [ATTACHMENTS];
// Description:
//   Creates a crown gear.  The module `crown_gear()` gives a crown gear, with reasonable defaults
//   for all the parameters.  Normally, you should just choose the first 4 parameters, and let the
//   rest be default values.
//   .
//   The module `crown_gear()` gives a crown gear in the XY plane, centered on the origin, with one tooth
//   centered on the positive Y axis.  The crown gear will have the pitch circle of the teeth at Z=0 by default.
//   The inner radius of the crown teeth can be calculated with the `pitch_radius()` function, and the outer
//   radius of the teeth is `face_width=` more than that.
// Arguments:
//   teeth = Total number of teeth around the entire perimeter. Required.
//   backing = Distance from base of crown gear to roots of teeth (alternative to bottom and thickness).
//   face_width = Width of the toothed surface, from inside radius to outside.  Default: 10
//   ---
//   mod = The module of the gear (pitch diameter / teeth)
//   circ_pitch = The circular pitch, the distance between teeth centers around the pitch circle.  Default: 5
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  The diametral pitch is a completely different thing than the pitch diameter.
//   bottom = Distance from crown's pitch plane (Z=0) to the bottom of the crown gear.  (Alternative to backing or thickness)
//   thickness = Distance from base of crown gear to tips of teeth (alternative to bottom and backing).
//   pressure_angle = Normal pressure angle in degrees. Omitted or undef inherits from the parent, otherwise defaults to 20
//   clearance = Clearance gap at the bottom of the inter-tooth valleys.  Default: module/4
//   backlash = Gap between two meshing teeth, in the direction along the circumference of the pitch circle.  Default: 0
//   profile_shift = Profile shift factor x. Default: 0
//   slices = Number of radial samples across the toothed face. Must be an integer >= 2. Default: 10
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top toward, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   gear_spin = Rotate tooth geometry about the gear center before anchoring; does not rotate children. Default: 0
// Example:
//   crown_gear(mod=1, teeth=40, backing=3, face_width=5, pressure_angle=20);
// Example:
//   mod=1; cteeth=40; pteeth=17; backing=3; PA=20; face=5;
//   cpr = pitch_radius(mod=mod, teeth=cteeth);
//   ppr = pitch_radius(mod=mod, teeth=pteeth);
//   crown_gear(mod=mod, teeth=cteeth, backing=backing,
//       face_width=face, pressure_angle=PA);
//   back(cpr+face/2)
//     up(ppr)
//       spur_gear(mod=mod, teeth=pteeth,
//           pressure_angle=PA, thickness=face,
//           orient=BACK, gear_spin=180/pteeth,
//           profile_shift=0);

function crown_gear(
    // BEGIN GEAR_API_COMPAT
    _p0="__gear_legacy_omitted__", _p1="__gear_legacy_omitted__", _p2="__gear_legacy_omitted__",
    _p3="__gear_legacy_omitted__", _extra="__gear_legacy_omitted__",
    // END GEAR_API_COMPAT
    teeth, backing, face_width, _named, mod, circ_pitch, diam_pitch, bottom, thickness,
    pressure_angle, clearance, backlash, profile_shift, slices, anchor, spin, orient, gear_spin
) =
    // BEGIN GEAR_API_COMPAT
    let(_gear_args=_gear_legacy_args(
        "crown_gear()", [_p0,_p1,_p2,_p3], _extra,
        ["circ_pitch", "teeth", "backing", "face_width"], ["teeth", "backing", "face_width"],
        [teeth,backing,face_width], circ_pitch, mod, diam_pitch))
    let(circ_pitch=_gear_args[0], teeth=_gear_args[1], backing=_gear_args[2], face_width=_gear_args[3])
    // END GEAR_API_COMPAT

    assert(is_undef(_named), "crown_gear(): arguments after teeth, backing, face_width must be named")

    let(
        face_width=is_undef(face_width)?10:face_width,
        
        backlash=is_undef(backlash)?0:backlash, profile_shift=is_undef(profile_shift)?0:profile_shift,
        slices=is_undef(slices)?10:slices, gear_spin=is_undef(gear_spin)?0:gear_spin,
        anchor=is_undef(anchor)?CTR:anchor, spin=is_undef(spin)?0:spin,
        orient=is_undef(orient)?UP:orient
    )
 let(
        pitch = _inherit_gear_pitch(fname="crown_gear()", circ_pitch=circ_pitch, diam_pitch=diam_pitch, mod=mod),
        PA = _inherit_gear_pa(pressure_angle=pressure_angle)
    )
    assert(is_integer(slices) && slices>=2, "crown_gear(): slices must be an integer >= 2")
        assert(is_finite(face_width) && face_width>0, "crown_gear(): face_width must be positive")
        assert(is_integer(teeth) && teeth>0)
    assert(is_finite(PA) && PA>=0 && PA<90, "Bad pressure_angle value.")
    assert(clearance==undef || (is_finite(clearance) && clearance>=0))
    assert(is_finite(backlash) && backlash>=0)
    assert(is_finite(gear_spin))
    assert(num_defined([thickness,backing,bottom])<=1, "Can define only one of thickness, backing and bottom")
    let(
        a = _adendum(circ_pitch=pitch, profile_shift=profile_shift),
        d = _dedendum(circ_pitch=pitch, clearance=clearance, profile_shift=profile_shift),
        bottom = is_def(bottom) ?
                     assert(is_finite(bottom) && bottom>d, "bottom is invalid or too small for teeth")
                     bottom
               : is_def(thickness) ?
                     assert(is_finite(thickness) && thickness>a+d, "thickness is invalid or too small for teeth")
                     thickness - a
               : is_def(backing) ?
                     assert(all_positive([backing]), "backing must be a positive value")
                     backing+d
               : 2*d+a,  // default case
        mod = module_value(circ_pitch=pitch),
        ir = mod * teeth / 2,
        or = ir + face_width,
        profiles = [
            for (slice = [0:1:slices-1])
            let(
                u = slice / (slices-1),
                r = or - u*face_width,
                wpa = acos(ir * cos(PA) / r),
                profile = select(
                    rack2d(
                        mod=mod, teeth=1,
                        pressure_angle=wpa,
                        clearance=clearance,
                        backlash=backlash,
                        profile_shift=profile_shift,
                        rounding=false
                    ), 2, -3
                ),
                delta = profile[1] - profile[0],
                slope = delta.y / delta.x,
                C = profile[0].y - slope * profile[0].x,
                profile2 = profile[1].x > 0
                  ? [profile[0], [0,C], [0,C], profile[3]]
                  : profile,
                m = back(r) * xrot(90),
                tooth = apply(m, path3d(profile2)),
                rpitch = pitch * r / ir
            )
            assert(profile[3].x <= rpitch/2, "face_width is too wide for the given gear geometry.  Either decrease face_width, or increase the module or tooth count.")
            [
                for (i = [0:1:teeth-1])
                let(a = gear_spin - i * 360 / teeth) 
                each zrot(a, p=tooth)
            ]
        ],
        rows = [
            [for (p=profiles[0]) [p.x,p.y,-bottom]],
            each profiles,
            [for (p=last(profiles)) [p.x,p.y,last(profiles)[0].z]],
        ],
        vnf = vnf_vertex_array(rows, col_wrap=true, caps=true)
    ) reorient(anchor,spin,orient, r=or, h=2*bottom, p=vnf);


module crown_gear(
    // BEGIN GEAR_API_COMPAT
    _p0="__gear_legacy_omitted__", _p1="__gear_legacy_omitted__", _p2="__gear_legacy_omitted__",
    _p3="__gear_legacy_omitted__", _extra="__gear_legacy_omitted__",
    // END GEAR_API_COMPAT
    teeth, backing, face_width, _named, mod, circ_pitch, diam_pitch, bottom, thickness,
    pressure_angle, clearance, backlash, profile_shift, slices, anchor, spin, orient, gear_spin
)
    // BEGIN GEAR_API_COMPAT
    let(_gear_args=_gear_legacy_args(
        "crown_gear()", [_p0,_p1,_p2,_p3], _extra,
        ["circ_pitch", "teeth", "backing", "face_width"], ["teeth", "backing", "face_width"],
        [teeth,backing,face_width], circ_pitch, mod, diam_pitch))
    let(circ_pitch=_gear_args[0], teeth=_gear_args[1], backing=_gear_args[2], face_width=_gear_args[3])
    // END GEAR_API_COMPAT

    assert(is_undef(_named), "crown_gear(): arguments after teeth, backing, face_width must be named")
 
    let(
        face_width=is_undef(face_width)?10:face_width,
        
        backlash=is_undef(backlash)?0:backlash, profile_shift=is_undef(profile_shift)?0:profile_shift,
        slices=is_undef(slices)?10:slices, gear_spin=is_undef(gear_spin)?0:gear_spin,
        anchor=is_undef(anchor)?CTR:anchor, spin=is_undef(spin)?0:spin,
        orient=is_undef(orient)?UP:orient
    )
{
    pitch = _inherit_gear_pitch(fname="crown_gear()", circ_pitch=circ_pitch, diam_pitch=diam_pitch, mod=mod);
    PA = _inherit_gear_pa(pressure_angle=pressure_angle);
    checks =
        assert(is_integer(slices) && slices>=2, "crown_gear(): slices must be an integer >= 2")
        assert(is_finite(face_width) && face_width>0, "crown_gear(): face_width must be positive")
        assert(is_integer(teeth) && teeth>0)
        assert(is_finite(PA) && PA>=0 && PA<90, "Bad pressure_angle value.")
        assert(clearance==undef || (is_finite(clearance) && clearance>=0))
        assert(is_finite(backlash) && backlash>=0)
        assert(is_finite(gear_spin))
        assert(num_defined([thickness,backing,bottom])<=1, "Can define only one of thickness, backing and bottom")
        ;
    pr = pitch_radius(circ_pitch=pitch, teeth=teeth);
    a = _adendum(circ_pitch=pitch, profile_shift=profile_shift);
    d = _dedendum(circ_pitch=pitch, clearance=clearance, profile_shift=profile_shift);
    bottom = is_def(bottom) ?
                 assert(is_finite(bottom) && bottom>d, "bottom is invalid or too small for teeth")
                 bottom
           : is_def(thickness) ?
                 assert(is_finite(thickness) && thickness>a+d, "thickness is invalid or too small for teeth")
                 thickness - a
           : is_def(backing) ?
                 assert(all_positive([backing]), "backing must be a positive value")
                 backing+d
           : 2*d+a;  // default case
    vnf = crown_gear(
        circ_pitch=pitch,
        teeth=teeth,
        bottom=bottom,
        face_width=face_width,
        pressure_angle=PA,
        clearance=clearance,
        backlash=backlash,
        profile_shift=profile_shift,
        slices=slices,
        gear_spin=gear_spin
    );
    attachable(anchor,spin,orient, r=pr+face_width, h=2*bottom) {
        vnf_polyhedron(vnf, convexity=12);
        children();
    }
}


// Function&Module: bevel_gear()
// Synopsis: Creates a straight, zerol, or spiral bevel gear.
// SynTags: Geom, VNF
// Topics: Gears, Parts
// See Also: rack(), rack2d(), spur_gear(), spur_gear2d(), bevel_pitch_angle(), bevel_gear()
// Usage: As a Function
//   vnf = bevel_gear(mod=|circ_pitch=|diam_pitch=, teeth, mate_teeth, [shaft_angle], [backing=], [bottom=], [thickness=], [cone_backing=], [face_width=], [pressure_angle=], [clearance=], [backlash=], [spiral=], [cutter_radius=], [right_handed=], [slices=], [gear_spin=], [anchor=], [spin=], [orient=]);
// Usage: As a Module
//   bevel_gear(mod=|circ_pitch=|diam_pitch=, teeth, mate_teeth, [shaft_angle], [backing=], [bottom=], [thickness=], [cone_backing=], [face_width=], [shaft_diam=], [pressure_angle=], [clearance=], [backlash=], [spiral=], [cutter_radius=], [right_handed=], [slices=], [gear_spin=], [anchor=], [spin=], [orient=]) [ATTACHMENTS];
// Description:
//   Creates a spiral, zerol, or straight bevel gear.  In straight bevel gear sets, when each tooth
//   engages it inpacts the corresponding tooth.  The abrupt tooth engagement causes impact stress
//   which makes them more prone to breakage.  Spiral bevel gears have teeth formed along spirals so
//   they engage more gradually, resulting in a less abrupt transfer of force, so they are quieter
//   in operation and less likely to break.
//   .
//   Bevel gears must be created in mated pairs to work together at a chosen shaft angle.  You therefore
//   must specify both the number of teeth on the gear and the number of teeth on its mating gear.
//   Additional requirements for bevel gears to mesh are that they share the same
//   tooth size and the same pressure angle and they must be of opposite handedness.
//   The pressure angle controls how much the teeth bulge at their
//   sides and is almost always 20 degrees for standard bevel gears.  The ratio of `teeth` for two meshing gears
//   gives how many times one will make a full
//   revolution when the the other makes one full revolution.  If the two numbers are coprime (i.e.
//   are not both divisible by the same number greater than 1), then every tooth on one gear will meet
//   every tooth on the other, for more even wear.  So relatively prime numbers of teeth are good.
//   .
//   The gear appears centered on the origin, with one tooth
//   centered on the positive Y axis.  The base of the pitch cone (the "pitchbase") will lie in the XY plane.  This is
//   the natural position: in order to mesh the mating gear must be positioned so their pitch bases are tangent.
//   The apexes of the pitch cones must coincide.
//   . 
//   By default backing will be added to ensure
//   that the center of the gear (where there are no teeth) is at least half the face width in thickness.
//   You can change this using the `backing`, `thickness` or `bottom` parameters.  The backing appears with
//   a conical shape, extended the sloped edges of the teeth.  You can set `cone_backing=false` if your application
//   requires cylindrical backing.  
// Arguments:
//   teeth = Number of teeth on the gear
//   mate_teeth = Number of teeth on the gear that will mate to this gear
//   shaft_angle = Angle between the shafts of the two gears.  Default: 90
//   ---
//   mod = The module of the gear (pitch diameter / teeth)
//   circ_pitch = The circular pitch, the distance between teeth centers around the pitch circle.
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  The diametral pitch is a completely different thing than the pitch diameter.
//   backing = Distance from bottom of bevel gear to bottom corner of teeth (Alternative to bottom or thickness).  Default: 0 if the gear is thick enough (see above)
//   bottom = Distance from bevel gear's pitch base to the bottom of the bevel gear.  (Alternative to backing or thickness)
//   thickness = Thickness of bevel gear at the center, where there are no teeth.  (Alternative to backing or bottom). 
//   cone_backing = If true backing extends conical shape of the gear; otherwise backing is an attached cylinder.  Default: true
//   face_width = Width of teeth.  Default: minimum of one third the cone distance and 10*module
//   shaft_diam = Diameter of the hole in the center, or zero for no hole.  (Module only.)  Default: 0
//   pressure_angle = Controls how straight or bulged the tooth sides are. In degrees. Default: 20
//   clearance = Clearance gap at the bottom of the inter-tooth valleys.  Default: module/4
//   backlash = Gap between two meshing teeth, in the direction along the circumference of the pitch circle.  Default: 0
//   spiral = The base angle for spiral teeth.  If zero the teeth will be zerol or straight.  Default: 35
//   cutter_radius = Radius of spiral arc for teeth.  If 0, then gear will have straight teeth.  Default: face_width/2/cos(spiral)
//   right_handed = If true, the gear returned will have a right-handed teeth.  Default: false 
//   slices = Number of vertical layers to divide gear into.  Useful for refining gears with `spiral`.  Default: 5
//   gear_spin = Rotate the tooth geometry about the gear center before anchoring; attached children are not rotated.  Default: 0
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: "pitchbase"
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top toward, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Named Anchors:
//   "pitchbase" = With the base of the pitch cone in the XY plane, centered at the origin.  This is the natural height for the gear, and the default anchor.
//   "apex" = At the pitch cone apex for the bevel gear.
//   "flattop" = At the top of the flat top of the bevel gear.
// Example(NoAxes): Bevel Gear with zerol teeth
//   bevel_gear(
//       circ_pitch=5, teeth=36, mate_teeth=36,
//       shaft_diam=5, spiral=0
//   );
// Example(NoAxes): Spiral Beveled Gear and Pinion.  Conical backing added to the yellow gear to prevents it from being thin.
//   t1 = 16; t2 = 28;
//   color("lightblue")bevel_gear(
//       circ_pitch=5, teeth=t1, mate_teeth=t2,
//       slices=12, anchor="apex", orient=FWD
//   );
//   bevel_gear(
//       circ_pitch=5, teeth=t2, mate_teeth=t1, right_handed=true,
//       slices=12, anchor="apex", backing=3, spin=180/t2
//   );
// Example(Anim,Frames=4,VPD=175,NoAxes): Manual Spacing of Pinion and Gear.  Here conical backing has been turned off.  
//   t1 = 14; t2 = 28; circ_pitch=5;
//   color("lightblue")back(pitch_radius(circ_pitch=circ_pitch, teeth=t2)) {
//     yrot($t*360/t1)
//     bevel_gear(
//       circ_pitch=circ_pitch, teeth=t1, mate_teeth=t2, shaft_diam=5,
//       slices=12, orient=FWD
//     );
//   }
//   down(pitch_radius(circ_pitch=circ_pitch, teeth=t1)) {
//     zrot($t*360/t2)
//     bevel_gear(
//       circ_pitch=circ_pitch, teeth=t2, mate_teeth=t1, right_handed=true,
//       shaft_diam=5, slices=12, backing=3, spin=180/t2, cone_backing=false
//     );
//   }
// Example(NoAxes,VPT=[-12.7062,12.914,17.7517],VPR=[71.1,0,35.5],VPD=213.382): Placing bevel gears onto a frame using the `bottom=` parameter to get the correct position, and with holes cut in the frame for the shafts.  
//   t1=17; t2=29; mod=2; bot=4; wall=2; shaft=5;
//   r1 = pitch_radius(mod=mod, teeth=t1);
//   r2 = pitch_radius(mod=mod, teeth=t2);
//   difference(){
//     move([0,bot,-bot]){
//        cuboid([60,40,wall], anchor=TOP+BACK);
//        down(wall)cuboid([60,wall,70], anchor=BOT+FWD);
//     }
//     up(r2) ycyl(d=shaft, l=100);
//     fwd(r1) zcyl(d=shaft, l=100);
//   }  
//   fwd(r1) color("lightblue")
//     bevel_gear(mod=mod, teeth=t1,mate_teeth=t2, bottom=bot, shaft_diam=shaft, slices=12);
//   up(r2) color("orange")
//     bevel_gear(mod=mod, teeth=t2,mate_teeth=t1, bottom=bot, right_handed=true, orient=FWD, shaft_diam=shaft, slices=12);
// Example(NoAxes,VPT=[24.4306,-9.20912,-29.3331],VPD=292.705,VPR=[71.8,0,62.5]): Bevel gears at a non right angle, positioned by aligning the pitch cone apexes.  
//   ang=65;
//   bevel_gear(mod=3,teeth=35,mate_teeth=15,shaft_angle=ang,spiral=0,backing=5,anchor="apex")   
//     cyl(h=48,d=3,$fn=16,anchor=BOT);
//   color("lightblue")
//   xrot(ang)
//     bevel_gear(mod=3,teeth=15,mate_teeth=35,shaft_angle=ang,spiral=0,right_handed=true,anchor="apex")
//       cyl(h=65,d=3,$fn=16,anchor=BOT);
// Example(NoAxes,VPT=[-6.28233,3.60349,15.6594],VPR=[71.1,0,52.1],VPD=213.382): Non-right angled bevel gear pair positioned in a frame, with holes cut in the frame for the shafts.  When rotating a gear to its appropriate angle, you must rotate around an axis tangent to the gear's pitch base, **not** the gear center.  This is accomplished by shifting the gear by its pitch radius before applying the rotation.    
//   angle = 60;
//   t1=17; t2=29; mod=2; bot=4; wall=2; shaft=5;
//   r1 = pitch_radius(mod=mod, teeth=t1);
//   r2 = pitch_radius(mod=mod, teeth=t2);
//   difference(){
//     move(bot*[0, 1/tan(90-angle/2),-1])
//       rot(90)xrot(90)
//       linear_extrude(height=60,center=true,convexity=5)
//       offset_stroke([[-40,0],[0,0], polar_to_xy(60,angle)], width=[-wall,0]);
//     move(r2*[0,cos(angle),sin(angle)])
//       xrot(angle)zcyl(d=shaft, l=50);
//     fwd(r1)
//       zcyl(d=shaft, l=50);
//   }
//   fwd(r1) color("lightblue")
//     bevel_gear(mod=mod, teeth=t1,mate_teeth=t2, bottom=bot, shaft_angle=angle, shaft_diam=shaft, slices=12);
//   xrot(angle) back(r2) color("orange")
//     bevel_gear(mod=mod, teeth=t2,mate_teeth=t1, bottom=bot, shaft_angle=angle, shaft_diam=shaft, right_handed=true, slices=12);
// Example(NoAxes,VPT=[-0.482968,-0.51139,-4.48142],VPR=[69.7,0,40.9],VPD=263.435): At this extreme 135 degree angle the yellow gear has internal teeth.  This is a rare configuration.  
//   ang=135;
//   bevel_gear(mod=3,teeth=35,mate_teeth=15,shaft_angle=ang);   
//   color("lightblue")
//     back(pitch_radius(mod=3,teeth=35)+pitch_radius(mod=3,teeth=15))
//     xrot(ang,cp=[0,-pitch_radius(mod=3,teeth=15),0])
//         bevel_gear(mod=3,teeth=15,mate_teeth=35,shaft_angle=ang,right_handed=true);




function bevel_gear(
    teeth, mate_teeth, shaft_angle, _named, mod, circ_pitch, diam_pitch, backing, bottom, thickness,
    cone_backing, face_width, pressure_angle, clearance, backlash, spiral, cutter_radius,
    right_handed, slices, gear_spin, anchor, spin, orient, _return_anchors
) =
    assert(is_undef(_named), "bevel_gear(): arguments after teeth, mate_teeth, shaft_angle must be named")

    let(shaft_angle=default(shaft_angle,90),
        backlash=default(backlash,0.0),
        spiral=default(spiral,35),
        right_handed=default(right_handed,false),
        slices=default(slices,5),
        cone_backing=default(cone_backing,true),
        anchor=default(anchor,"pitchbase"),
        spin=default(spin,0),
        gear_spin=default(gear_spin,0),
        orient=default(orient,UP),
        _return_anchors=default(_return_anchors,false))
    let(pressure_angle=_inherit_gear_pa(pressure_angle))
 assert(all_integer([teeth,mate_teeth]) && teeth>=3 && mate_teeth>=3, "Must give teeth and mate_teeth, integers greater than or equal to 3")
    assert(all_nonnegative([spiral]), "spiral must be nonnegative")
    assert(is_undef(cutter_radius) || all_nonnegative([cutter_radius]), "cutter_radius must be nonnegative")
    assert(is_finite(shaft_angle) && shaft_angle>0 && shaft_angle<180,"shaft_angle must be strictly between 0 and 180")  
    let(
        circ_pitch = _inherit_gear_pitch(fname="bevel_gear()",circ_pitch=circ_pitch, diam_pitch=diam_pitch, mod=mod),
        PA = _inherit_gear_pa(pressure_angle=pressure_angle),
        spiral = _inherit_gear_helical(helical=spiral),
        slices = cutter_radius==0? 1 : slices,
        pitch_angle = posmod(atan(sin(shaft_angle)/((mate_teeth/teeth)+cos(shaft_angle))),180),
        pr = pitch_radius(circ_pitch=circ_pitch, teeth=teeth),
        rr = _root_radius_basic(circ_pitch=circ_pitch, teeth=teeth, clearance=clearance),
        pitchoff = (pr-rr) * sin(pitch_angle),
        ocone_rad = pitch_angle<90 ? opp_ang_to_hyp(pr, pitch_angle)
                                   : opp_ang_to_hyp(pitch_radius(circ_pitch=circ_pitch,teeth=mate_teeth), shaft_angle-pitch_angle),
        default_face_width = min(ocone_rad/3, 10*module_value(circ_pitch=circ_pitch)),
        face_width = _inherit_gear_thickness(thickness=face_width,dflt=default_face_width),
        icone_rad = ocone_rad - face_width,
        
        cutter_radius = is_undef(cutter_radius) ? face_width * 2 / cos(spiral)
                      : cutter_radius==0? face_width*100
                      : cutter_radius,
        midpr = (icone_rad + ocone_rad) / 2,
        radcp = [0, midpr] + polar_to_xy(cutter_radius, 180+spiral),
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
        botz = verts1[0][0].z,      // bottom of center
        topz = last(verts1)[0].z,   // top of center
        ctr_thickness = topz - botz,  
        vertices = [for (x=verts1) reverse(x)],
        sides_vnf = vnf_vertex_array(vertices, caps=false, col_wrap=true, reverse=true),
        top_verts = last(vertices),
        bot_verts = vertices[0],
        gear_pts = len(top_verts),
        face_pts = gear_pts / teeth,
        minbacking = -min(0,ctr_thickness),  
        backing = is_def(backing) ?
                      assert(all_nonnegative([backing]), "backing must be a non-negative value")
                      assert(ctr_thickness>0 || backing>0, "internal gears require backing>0")
                      backing-min(0,ctr_thickness)
                : is_def(thickness) ?
                      let(thick_OK=is_finite(thickness) && (thickness>abs(ctr_thickness) || (thickness==ctr_thickness && ctr_thickness>0)))
                      assert(thick_OK, str("thickness is invalid or too small for teeth; thickness must be larger than ",abs(ctr_thickness)))
                      thickness-ctr_thickness
                : is_def(bottom)?
                    assert(is_finite(bottom) && bottom-pitchoff>minbacking,
                           str("bottom is invalid or too small for teeth, must exceed ",minbacking+pitchoff))
                    bottom-pitchoff
                : ctr_thickness>face_width/2 ? 0
                : -ctr_thickness+face_width/2,
        cpz = (topz + botz - backing) / 2,
        teeth_top_faces =[
            for (i=[0:1:teeth-1], j=[0:1:(face_pts/2)-1]) each [
                [i*face_pts+j, (i+1)*face_pts-j-1, (i+1)*face_pts-j-2],
                [i*face_pts+j, (i+1)*face_pts-j-2, i*face_pts+j+1]
            ]
        ],
        flat_top_faces = [    
            for (i=[0:1:teeth-1]) each [
                [gear_pts, (i+1)*face_pts-1, i*face_pts],
                [gear_pts, ((i+1)%teeth)*face_pts, (i+1)*face_pts-1]
            ]
        ],
        backing_vert = backing==0? []
                     : !cone_backing ? down(backing,[for(i=[0:1:teeth-1]) each( [bot_verts[i*face_pts], bot_verts[(i+1)*face_pts-1]])])
                     : let(
                           factor = tan(pitch_angle-90)*backing
                       )
                       [for(i=[0:1:teeth-1]) let(
                           A = bot_verts[i*face_pts],
                           B = bot_verts[(i+1)*face_pts-1],
                           adjA = point3d(factor*unit(point2d(A)),-backing),
                           adjB = point3d(factor*unit(point2d(B)),-backing)
                       )
                       each [ A+adjA, B+adjB]],
        shift = len(bot_verts),
        backing_bot_faces = backing==0? flat_top_faces
                          :[for (i=idx(backing_vert))
                               [shift+len(backing_vert), shift+(i+1)%len(backing_vert),shift+i]
                            ],
        backing_side_faces = backing==0 ? []
                         : [
                             for (i=[0:1:teeth-1]) 
                               each [
                                     [shift+2*i,shift+(2*i+1),(i+1)*face_pts-1],
                                     [shift+2*i+1,shift+2*((i+1)%teeth), ((i+1)%teeth)*face_pts],
                                     [(i+1)*face_pts-1, i*face_pts, shift+2*i],
                                     [((i+1)%teeth)*face_pts, (i+1)*face_pts-1, shift+2*i+1]
                               ]              
                           ],
        vnf1 = vnf_join([
            [
                [each top_verts, [0,0,top_verts[0].z]],
                concat(teeth_top_faces, flat_top_faces)
            ],
            [
                [each bot_verts,each backing_vert, [0,0,bot_verts[0].z-backing]   ],
                [for (x=concat(teeth_top_faces,backing_bot_faces,backing_side_faces)) reverse(x)]
            ],
            sides_vnf
        ]),
        lvnf = right_handed? vnf1 : xflip(p=vnf1),
        vnf = zrot(gear_spin,down(cpz, p=lvnf)),
        anchors = [
            named_anchor("pitchbase", [0,0,pitchoff-ctr_thickness/2+backing/2]),
            named_anchor("flattop", [0,0,ctr_thickness/2+backing/2]),
            named_anchor("apex", [0,0,hyp_ang_to_opp(pitch_angle<90?ocone_rad:icone_rad,90-pitch_angle)+pitchoff-ctr_thickness/2+backing/2])
        ],
        final_vnf = reorient(anchor,spin,orient, vnf=vnf, extent=true, anchors=anchors, p=vnf)
    )
    _return_anchors==false ? final_vnf
                        : [final_vnf, anchors, ctr_thickness+backing];


module bevel_gear(
    teeth, mate_teeth, shaft_angle, _named, mod, circ_pitch, diam_pitch, backing, bottom, thickness,
    cone_backing, face_width, shaft_diam, pressure_angle, clearance, backlash, spiral, cutter_radius,
    right_handed, slices, gear_spin, anchor, spin, orient
)
    assert(is_undef(_named), "bevel_gear(): arguments after teeth, mate_teeth, shaft_angle must be named")

    let(shaft_angle=default(shaft_angle,90),
        cone_backing=default(cone_backing,true),
        shaft_diam=default(shaft_diam,0),
        backlash=default(backlash,0.0),
        spiral=default(spiral,35),
        right_handed=default(right_handed,false),
        slices=default(slices,5),
        anchor=default(anchor,"pitchbase"),
        spin=default(spin,0),
        gear_spin=default(gear_spin,0),
        orient=default(orient,UP))
    let(pressure_angle=_inherit_gear_pa(pressure_angle))
 {
    vnf_anchors = bevel_gear(
        circ_pitch = circ_pitch, mod=mod, diam_pitch=diam_pitch, 
        teeth = teeth,
        mate_teeth = mate_teeth,
        shaft_angle=shaft_angle,
        bottom=bottom,thickness=thickness,backing=backing,cone_backing=cone_backing,
        face_width = face_width,
        pressure_angle = pressure_angle,
        clearance = clearance,
        backlash = backlash,
        cutter_radius = cutter_radius,
        spiral = spiral,
        right_handed = right_handed,
        slices = slices,
        anchor=CENTER,
        gear_spin=gear_spin,
        _return_anchors=true
    );
    vnf=vnf_anchors[0];
    anchors=vnf_anchors[1];
    thickness = vnf_anchors[2];
    attachable(anchor,spin,orient, vnf=vnf, extent=true, anchors=anchors) {        
        difference() {
           vnf_polyhedron(vnf, convexity=12);
           if (shaft_diam > 0)
               cylinder(h=2*thickness, r=shaft_diam/2, center=true, $fn=max(12,segs(shaft_diam/2)));
        }
        children();
    }
}


// Function&Module: worm()
// Synopsis: Creates a worm that will mate with a worm gear.
// SynTags: Geom, VNF
// Topics: Gears, Parts
// See Also: worm(), worm_gear(), rack(), rack2d(), spur_gear(), spur_gear2d(), bevel_pitch_angle(), bevel_gear()
// Usage: As a Function
//   vnf = worm(mod=|circ_pitch=|diam_pitch=, [d], [l], [starts], [left_handed], [pressure_angle], [backlash], [clearance], [anchor], [spin], [orient], [gear_spin=]);
// Usage: As a Module
//   worm(mod=|circ_pitch=|diam_pitch=, [d], [l], [starts], [left_handed], [pressure_angle], [backlash], [clearance], [anchor], [spin], [orient], [gear_spin=]) [ATTACHMENTS];
// Description:
//   Creates a worm shape that can be matched to a worm gear.
// Arguments:
//   d = The pitch diameter of the worm.  Default: 15
//   l = The length of the worm.  Default: 100
//   starts = The number of lead starts.  Default: 1
//   left_handed = If true, the gear returned will have a left-handed spiral.  Default: false
//   pressure_angle = Controls how straight or bulged the tooth sides are. In degrees. Default: 20
//   backlash = Gap between two meshing teeth, in the direction along the circumference of the pitch circle.  Default: 0
//   clearance = Clearance gap at the bottom of the inter-tooth valleys.  Default: module/4
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top toward, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   ---
//   mod = The module of the gear (pitch diameter / teeth)
//   circ_pitch = The circular pitch, the distance between teeth centers around the pitch circle.  Default: 5
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  The diametral pitch is a completely different thing than the pitch diameter.
//   gear_spin = Rotate the worm thread about its axis before anchoring; does not rotate children. Default: 0
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
    // BEGIN GEAR_API_COMPAT
    _p0="__gear_legacy_omitted__", _p1="__gear_legacy_omitted__", _p2="__gear_legacy_omitted__",
    _p3="__gear_legacy_omitted__", _p4="__gear_legacy_omitted__", _p5="__gear_legacy_omitted__",
    _p6="__gear_legacy_omitted__", _p7="__gear_legacy_omitted__", _p8="__gear_legacy_omitted__",
    _p9="__gear_legacy_omitted__", _extra="__gear_legacy_omitted__",
    // END GEAR_API_COMPAT
    d, l, starts, left_handed, pressure_angle, backlash, clearance, anchor, spin, orient, _named, mod,
    circ_pitch, diam_pitch, gear_spin
) =
    // BEGIN GEAR_API_COMPAT
    let(_gear_args=_gear_legacy_args(
        "worm()", [_p0,_p1,_p2,_p3,_p4,_p5,_p6,_p7,_p8,_p9], _extra,
        ["circ_pitch", "d", "l", "starts", "left_handed", "pressure_angle", "backlash", "clearance"], ["d", "l", "starts", "left_handed", "pressure_angle", "backlash", "clearance", "anchor", "spin", "orient"],
        [d,l,starts,left_handed,pressure_angle,backlash,clearance,anchor,spin,orient], circ_pitch, mod, diam_pitch))
    let(circ_pitch=_gear_args[0], d=_gear_args[1], l=_gear_args[2], starts=_gear_args[3], left_handed=_gear_args[4], pressure_angle=_gear_args[5], backlash=_gear_args[6], clearance=_gear_args[7], anchor=_gear_args[8], spin=_gear_args[9], orient=_gear_args[10])
    // END GEAR_API_COMPAT

    assert(is_undef(_named), "worm(): arguments after d, l, starts, left_handed, pressure_angle, backlash, clearance, anchor, spin, orient must be named")

    let(
        d=is_undef(d)?15:d, l=is_undef(l)?100:l, starts=is_undef(starts)?1:starts,
        left_handed=is_undef(left_handed)?false:left_handed, backlash=is_undef(backlash)?0:backlash,
        gear_spin=is_undef(gear_spin)?0:gear_spin, anchor=is_undef(anchor)?CENTER:anchor,
        spin=is_undef(spin)?0:spin, orient=is_undef(orient)?UP:orient
    )

    let(
        circ_pitch = _inherit_gear_pitch(fname="worm()", circ_pitch=circ_pitch, diam_pitch=diam_pitch, mod=mod),
        PA = _inherit_gear_pa(pressure_angle=pressure_angle)
    )
    assert(is_integer(starts) && starts>0)
        assert(is_finite(d) && d>max(2,starts)*circ_pitch/PI,
               "worm(): d must exceed 2*module and starts*module")
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
                circ_pitch=circ_pitch,
                teeth=1,
                pressure_angle=PA,
                clearance=clearance,
                backlash=backlash,
                helical=helical,
                profile_shift=0
            ), 1, -2)
        ),

        rack_profile = [
            for (t = xcopies(trans_pitch, n=2*ceil(l/trans_pitch)+1))
                each apply(t, tooth)
        ],
        nrp = select(rack2d(
                circ_pitch=circ_pitch,
                teeth=2*ceil(l/trans_pitch)+1,
                pressure_angle=PA,
                clearance=clearance,
                backlash=backlash,
                helical=helical,
                profile_shift=0
            ), 1, -2),
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
    // BEGIN GEAR_API_COMPAT
    _p0="__gear_legacy_omitted__", _p1="__gear_legacy_omitted__", _p2="__gear_legacy_omitted__",
    _p3="__gear_legacy_omitted__", _p4="__gear_legacy_omitted__", _p5="__gear_legacy_omitted__",
    _p6="__gear_legacy_omitted__", _p7="__gear_legacy_omitted__", _p8="__gear_legacy_omitted__",
    _p9="__gear_legacy_omitted__", _extra="__gear_legacy_omitted__",
    // END GEAR_API_COMPAT
    d, l, starts, left_handed, pressure_angle, backlash, clearance, anchor, spin, orient, _named, mod,
    circ_pitch, diam_pitch, gear_spin
)
    // BEGIN GEAR_API_COMPAT
    let(_gear_args=_gear_legacy_args(
        "worm()", [_p0,_p1,_p2,_p3,_p4,_p5,_p6,_p7,_p8,_p9], _extra,
        ["circ_pitch", "d", "l", "starts", "left_handed", "pressure_angle", "backlash", "clearance"], ["d", "l", "starts", "left_handed", "pressure_angle", "backlash", "clearance", "anchor", "spin", "orient"],
        [d,l,starts,left_handed,pressure_angle,backlash,clearance,anchor,spin,orient], circ_pitch, mod, diam_pitch))
    let(circ_pitch=_gear_args[0], d=_gear_args[1], l=_gear_args[2], starts=_gear_args[3], left_handed=_gear_args[4], pressure_angle=_gear_args[5], backlash=_gear_args[6], clearance=_gear_args[7], anchor=_gear_args[8], spin=_gear_args[9], orient=_gear_args[10])
    // END GEAR_API_COMPAT

    assert(is_undef(_named), "worm(): arguments after d, l, starts, left_handed, pressure_angle, backlash, clearance, anchor, spin, orient must be named")
 
    let(
        d=is_undef(d)?15:d, l=is_undef(l)?100:l, starts=is_undef(starts)?1:starts,
        left_handed=is_undef(left_handed)?false:left_handed, backlash=is_undef(backlash)?0:backlash,
        gear_spin=is_undef(gear_spin)?0:gear_spin, anchor=is_undef(anchor)?CENTER:anchor,
        spin=is_undef(spin)?0:spin, orient=is_undef(orient)?UP:orient
    )
{
    circ_pitch = _inherit_gear_pitch(fname="worm()", circ_pitch=circ_pitch, diam_pitch=diam_pitch, mod=mod);
    PA = _inherit_gear_pa(pressure_angle=pressure_angle);
    checks =
        assert(is_integer(starts) && starts>0)
        assert(is_finite(d) && d>max(2,starts)*circ_pitch/PI,
               "worm(): d must exceed 2*module and starts*module")
        assert(is_finite(l) && l>0)
        //assert(is_finite(shaft_diam) && shaft_diam>=0)
        assert(is_finite(PA) && PA>=0 && PA<90, "Bad pressure_angle value.")
        assert(clearance==undef || (is_finite(clearance) && clearance>=0))
        assert(is_finite(backlash) && backlash>=0)
        assert(is_bool(left_handed))
        assert(is_finite(gear_spin));
    helical = asin(starts * circ_pitch / PI / d);
    trans_pitch = circ_pitch / cos(helical);
    vnf = worm(
        circ_pitch=circ_pitch,
        starts=starts,
        d=d, l=l,
        left_handed=left_handed,
        pressure_angle=PA,
        backlash=backlash,
        clearance=clearance
    );
    attachable(anchor,spin,orient, d=d, l=l) {
        zrot(gear_spin) vnf_polyhedron(vnf, convexity=ceil(l/trans_pitch)*2);
        children();
    }
}


// Function&Module: enveloping_worm()
// Synopsis: Creates a double-enveloping worm that will mate with a worm gear.
// SynTags: Geom, VNF
// Topics: Gears, Parts
// See Also: worm(), worm_gear(), rack(), rack2d(), spur_gear(), spur_gear2d(), bevel_pitch_angle(), bevel_gear()
// Usage: As a Function
//   vnf = enveloping_worm(mod=|circ_pitch=|diam_pitch=, mate_teeth, d, [left_handed], [starts=], [arc=], [pressure_angle=], [anchor=], [spin=], [orient=], [gear_spin=], [rounding=], [taper=]);
// Usage: As a Module
//   enveloping_worm(mod=|circ_pitch=|diam_pitch=, mate_teeth, d, [left_handed], [starts=], [arc=], [pressure_angle=], [anchor=], [spin=], [orient=], [gear_spin=], [rounding=], [taper=]) [ATTACHMENTS];
// Description:
//   Creates a double-enveloping worm shape that can be matched to a worm gear.
// Arguments:
//   mate_teeth = The number of teeth in the mated worm gear.
//   d = The pitch diameter of the worm at its middle.
//   left_handed = If true, the gear returned will have a left-handed spiral.  Default: false
//   ---
//   mod = The module of the gear (pitch diameter / teeth)
//   circ_pitch = The circular pitch, the distance between teeth centers around the pitch circle.  Default: 5
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  The diametral pitch is a completely different thing than the pitch diameter.
//   starts = The number of lead starts.  Default: 1
//   arc = Arc angle of the mated worm gear to envelop.  Default: `2 * pressure_angle`
//   pressure_angle = Controls how straight or bulged the tooth sides are. In degrees. Default: 20
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top toward, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   gear_spin = Rotate worm geometry about its axis before anchoring. Default: 0
//   rounding = Round the generating rack profile corners. Default: true
//   taper = Taper the thread near the ends of the enveloping arc. Default: true
// Example:
//   enveloping_worm(circ_pitch=8, mate_teeth=45, d=30, $fn=72);
// Example: Multiple Starts.
//   enveloping_worm(circ_pitch=8, mate_teeth=33, d=30, starts=3, $fn=72);
// Example: Left Handed
//   enveloping_worm(circ_pitch=8, mate_teeth=33, d=30, starts=3, left_handed=true, $fn=72);
// Example: Called as Function
//   vnf = enveloping_worm(circ_pitch=8, mate_teeth=37, d=35, starts=2, left_handed=true, pressure_angle=20, $fn=72);
//   vnf_polyhedron(vnf);

function enveloping_worm(
    // BEGIN GEAR_API_COMPAT
    _p0="__gear_legacy_omitted__", _p1="__gear_legacy_omitted__", _p2="__gear_legacy_omitted__",
    _p3="__gear_legacy_omitted__", _extra="__gear_legacy_omitted__",
    // END GEAR_API_COMPAT
    mate_teeth, d, left_handed, _named, mod, circ_pitch, diam_pitch, starts, arc, pressure_angle,
    anchor, spin, orient, gear_spin, rounding, taper
) =
    // BEGIN GEAR_API_COMPAT
    let(_gear_args=_gear_legacy_args(
        "enveloping_worm()", [_p0,_p1,_p2,_p3], _extra,
        ["circ_pitch", "mate_teeth", "d", "left_handed"], ["mate_teeth", "d", "left_handed"],
        [mate_teeth,d,left_handed], circ_pitch, mod, diam_pitch))
    let(circ_pitch=_gear_args[0], mate_teeth=_gear_args[1], d=_gear_args[2], left_handed=_gear_args[3])
    // END GEAR_API_COMPAT

    assert(is_undef(_named), "enveloping_worm(): arguments after mate_teeth, d, left_handed must be named")

    let(
        left_handed=is_undef(left_handed)?false:left_handed, starts=is_undef(starts)?1:starts,
        gear_spin=is_undef(gear_spin)?0:gear_spin, rounding=is_undef(rounding)?true:rounding,
        taper=is_undef(taper)?true:taper, anchor=is_undef(anchor)?CTR:anchor,
        spin=is_undef(spin)?0:spin, orient=is_undef(orient)?UP:orient
    )

    let(
        circ_pitch = _inherit_gear_pitch(fname="worm_gear()", circ_pitch=circ_pitch, diam_pitch=diam_pitch, mod=mod),
        pressure_angle = _inherit_gear_pa(pressure_angle=pressure_angle),
        arc = default(arc, 2*pressure_angle)
    )
    assert(is_integer(mate_teeth) && mate_teeth>10)
    assert(is_finite(d) && d>0)
    assert(is_bool(left_handed))
    assert(is_integer(starts) && starts>0)
    assert(is_finite(arc) && arc>10 && arc<=2*pressure_angle)
    assert(is_finite(gear_spin))
    let(
        hsteps = segs(d/2),
        vsteps = hsteps,
        helical = asin(starts * circ_pitch / PI / d),
        pr = pitch_radius(circ_pitch=circ_pitch, teeth=mate_teeth, helical=helical),
        taper_table = taper
          ? [
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
            ]
          : [
                [-180, 0],
                [-arc/2-0.00001, 0],
                [-arc/2, 1],
                [+arc/2, 1],
                [+arc/2+0.00001, 0],
                [+180, 0],
            ],
        tarc = 360 / mate_teeth,
        rteeth = quantup(ceil(mate_teeth*arc/360),2)+1+2*starts,
        rack_path = select(
            rack2d(
                circ_pitch=circ_pitch, teeth=rteeth,
                pressure_angle=pressure_angle,
                rounding=rounding, spin=90
            ),
            1,-2
        ),
        adendum = _adendum(circ_pitch=circ_pitch, profile_shift=0),
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


module enveloping_worm(
    // BEGIN GEAR_API_COMPAT
    _p0="__gear_legacy_omitted__", _p1="__gear_legacy_omitted__", _p2="__gear_legacy_omitted__",
    _p3="__gear_legacy_omitted__", _extra="__gear_legacy_omitted__",
    // END GEAR_API_COMPAT
    mate_teeth, d, left_handed, _named, mod, circ_pitch, diam_pitch, starts, arc, pressure_angle,
    anchor, spin, orient, gear_spin, rounding, taper
)
    // BEGIN GEAR_API_COMPAT
    let(_gear_args=_gear_legacy_args(
        "enveloping_worm()", [_p0,_p1,_p2,_p3], _extra,
        ["circ_pitch", "mate_teeth", "d", "left_handed"], ["mate_teeth", "d", "left_handed"],
        [mate_teeth,d,left_handed], circ_pitch, mod, diam_pitch))
    let(circ_pitch=_gear_args[0], mate_teeth=_gear_args[1], d=_gear_args[2], left_handed=_gear_args[3])
    // END GEAR_API_COMPAT

    assert(is_undef(_named), "enveloping_worm(): arguments after mate_teeth, d, left_handed must be named")
 
    let(
        left_handed=is_undef(left_handed)?false:left_handed, starts=is_undef(starts)?1:starts,
        pressure_angle=is_undef(pressure_angle)?20:pressure_angle,
        gear_spin=is_undef(gear_spin)?0:gear_spin, rounding=is_undef(rounding)?true:rounding,
        taper=is_undef(taper)?true:taper, anchor=is_undef(anchor)?CTR:anchor,
        spin=is_undef(spin)?0:spin, orient=is_undef(orient)?UP:orient
    )
{
    vnf = enveloping_worm(
        mate_teeth=mate_teeth,
        d=d,
        left_handed=left_handed,
        starts=starts,
        arc=arc,
        pressure_angle=pressure_angle,
        gear_spin=gear_spin,
        rounding=rounding,
        taper=taper,
        circ_pitch=circ_pitch,
        diam_pitch=diam_pitch,
        mod=mod
    );
    bounds = pointlist_bounds(vnf[0]);
    delta = bounds[1] - bounds[0];
    attachable(anchor,spin,orient, d=max(delta.x,delta.y), l=delta.z) {
        vnf_polyhedron(vnf, convexity=mate_teeth);
        children();
    }
}

// Function&Module: worm_gear()
// Synopsis: Generates a cylindrical worm wheel with a minimum blunt tip width.
// SynTags: Geom, VNF
// Topics: Gears, Parts
// See Also: worm(), worm_gear_dist(), worm_gear_thickness()
// Usage: As a Function
//   vnf = worm_gear(mod=|circ_pitch=|diam_pitch=, teeth, worm_diam, [worm_starts], [worm_arc], [crowning], [left_handed], [pressure_angle], [backlash], [clearance], [profile_shift], [slices], [gear_spin], [thickness=], [min_tip=], [face_chamfer=], [anchor=], [spin=], [orient=], [get_thickness=]);
// Usage: As a Module
//   worm_gear(mod=|circ_pitch=|diam_pitch=, teeth, worm_diam, [worm_starts], [worm_arc], [crowning], [left_handed], [pressure_angle], [backlash], [clearance], [profile_shift], [slices], [shaft_diam], [gear_spin], [thickness=], [min_tip=], [face_chamfer=], [anchor=], [spin=], [orient=]) [ATTACHMENTS];
// Description:
//   Generates an enveloping worm gear (also called a worm wheel) that matches to a worm.
//   You can specify the thickness or the angle that the worm gear wraps around the worm.
//   A general rule of thumb for thickness is to stay below half the worm diameter.
//   .
//   The `min_tip` parameter measures the widths of the teeth tops.  The teeth
//   will be shortened to ensure that they have at least this specified width
//   on the top and do not come to sharp points.  
//   The prevent sharp edges around the ring of the worm gear you can
//   use `face_chamfer`.
//   .
//   To correctly position the worm gear relative to the worm use {{worm_gear_dist()}} with the same pitch,
//   teeth, worm diameter, starts, pressure angle and profile shift. 
// Arguments:
//   teeth = Number of wheel teeth; integer greater than 7.
//   worm_diam = Worm pitch diameter.
//   worm_starts = Number of worm starts. Default: 1
//   worm_arc = Alternative width specification in (0,90] degrees. Default: 45 when neither width option is supplied.
//   crowning = Extra relief per flank, measured as wheel pitch-circle arc length; quadratic from zero at the middle to this value at each axial face. Default: 0.1
//   left_handed = Use a left-handed worm. Default: false
//   pressure_angle = Normal pressure angle. Default: 20
//   backlash = Tooth thinning measured along the wheel pitch circle; the generating distance is unchanged. Default: 0
//   clearance = Extra depth generated by extending the cutter tip. Default: module/4
//   profile_shift = Wheel profile-shift coefficient. Default: "auto"
//   slices = Width intervals, rounded up to an even number. Default: 10
//   shaft_diam = Axial shaft hole; module only. Default: 0
//   gear_spin = Tooth phase in degrees. Default: 0
//   ---
//   mod = Normal module.
//   circ_pitch = Normal circular pitch. Default: 5
//   diam_pitch = Normal diametral pitch, teeth per inch.
//   thickness = Exact axial wheel thickness, mutually exclusive with worm_arc.
//   min_tip = Minimum 3D crest-edge separation in model length units; must be positive. Default: 0.4*module
//   face_chamfer = Equal setback length in a radial-axial section of the already shortened rim; makes conical trims at both faces. Preserves thickness. Default: 0
//   anchor = Attachment anchor. Default: CENTER
//   spin = Rotation after anchoring. Default: 0
//   orient = Direction of the wheel axis. Default: UP
//   get_thickness = Return the selected axial thickness instead of the VNF. Function only. Default: false
// Example: Explicit axial thickness and minimum tip width
//   worm_gear(mod=3,teeth=75,worm_diam=44,worm_starts=4,
//             thickness=24,min_tip=1.2,profile_shift=0,crowning=0,slices=24);

// Example: Conical face bevel
//   worm_gear(mod=3,75,44,4,thickness=30,min_tip=1.2,face_chamfer=.6,crowning=0,slices=32);

function worm_gear(
    // BEGIN GEAR_API_COMPAT
    _p0="__gear_legacy_omitted__", _p1="__gear_legacy_omitted__", _p2="__gear_legacy_omitted__",
    _p3="__gear_legacy_omitted__", _p4="__gear_legacy_omitted__", _p5="__gear_legacy_omitted__",
    _p6="__gear_legacy_omitted__", _p7="__gear_legacy_omitted__", _p8="__gear_legacy_omitted__",
    _p9="__gear_legacy_omitted__", _p10="__gear_legacy_omitted__", _p11="__gear_legacy_omitted__",
    _p12="__gear_legacy_omitted__", _extra="__gear_legacy_omitted__",
    // END GEAR_API_COMPAT
    teeth, worm_diam, worm_starts, worm_arc, crowning, left_handed, pressure_angle, backlash,
    clearance, profile_shift, slices, gear_spin, _named, mod, circ_pitch, diam_pitch, thickness,
    min_tip, face_chamfer, anchor, spin, orient, get_thickness
) =
    // BEGIN GEAR_API_COMPAT
    let(_gear_args=_gear_legacy_args(
        "worm_gear()", [_p0,_p1,_p2,_p3,_p4,_p5,_p6,_p7,_p8,_p9,_p10,_p11,_p12], _extra,
        ["circ_pitch", "teeth", "worm_diam", "worm_starts", "worm_arc", "crowning", "left_handed", "pressure_angle", "backlash", "clearance", "profile_shift", "slices", "gear_spin"], ["teeth", "worm_diam", "worm_starts", "worm_arc", "crowning", "left_handed", "pressure_angle", "backlash", "clearance", "profile_shift", "slices", "gear_spin"],
        [teeth,worm_diam,worm_starts,worm_arc,crowning,left_handed,pressure_angle,backlash,clearance,profile_shift,slices,gear_spin], circ_pitch, mod, diam_pitch))
    let(circ_pitch=_gear_args[0], teeth=_gear_args[1], worm_diam=_gear_args[2], worm_starts=_gear_args[3], worm_arc=_gear_args[4], crowning=_gear_args[5], left_handed=_gear_args[6], pressure_angle=_gear_args[7], backlash=_gear_args[8], clearance=_gear_args[9], profile_shift=_gear_args[10], slices=_gear_args[11], gear_spin=_gear_args[12])
    // END GEAR_API_COMPAT

    assert(is_undef(_named), "worm_gear(): arguments after teeth, worm_diam, worm_starts, worm_arc, crowning, left_handed, pressure_angle, backlash, clearance, profile_shift, slices, gear_spin must be named")

    let(
        worm_starts=is_undef(worm_starts)?1:worm_starts, crowning=is_undef(crowning)?0.1:crowning,
        left_handed=is_undef(left_handed)?false:left_handed, backlash=is_undef(backlash)?0:backlash,
        profile_shift=is_undef(profile_shift)?"auto":profile_shift, slices=is_undef(slices)?10:slices,
        gear_spin=is_undef(gear_spin)?0:gear_spin, anchor=is_undef(anchor)?CTR:anchor,
        spin=is_undef(spin)?0:spin, orient=is_undef(orient)?UP:orient,
        face_chamfer=is_undef(face_chamfer)?0:face_chamfer,
        get_thickness=is_undef(get_thickness)?false:get_thickness
    )

    let(
        cp = _inherit_gear_pitch(fname="worm_gear()", circ_pitch=circ_pitch, diam_pitch=diam_pitch, mod=mod),
        pa = _inherit_gear_pa(pressure_angle=pressure_angle),
        ps = auto_profile_shift(teeth=teeth, pressure_angle=pa, profile_shift=profile_shift),
        m = cp/PI,
        c = is_undef(clearance) ? m/4 : clearance,
        nt = is_undef(min_tip) ? 0.4*m : min_tip,
        nprofile = is_undef($gear_steps) ? 16 : $gear_steps,
        nsearch = is_undef($worm_gear_search_steps) ? 24 : $worm_gear_search_steps,
        niters = is_undef($worm_gear_search_iters) ? 30 : $worm_gear_search_iters,
        P = _wormgear_data(m=m,teeth=teeth,d=worm_diam,starts=worm_starts,pa=pa,ps=ps,clear=c,
                          backlash=backlash,crown=crowning,arc=worm_arc,left=left_handed,thickness=thickness,min_tip=nt)
    )
    assert(is_bool(get_thickness), "worm_gear(): get_thickness must be boolean")
    assert(is_finite(gear_spin), "worm_gear(): invalid gear_spin")
    assert(is_finite(face_chamfer) && face_chamfer>=0, "worm_gear(): face_chamfer must be nonnegative")
    get_thickness ? 2*P[8] :
    let(vnf = _wormgear_build(P=P,slices=slices,nprofile=nprofile,nsearch=nsearch,niters=niters,gear_spin=gear_spin,face_chamfer=face_chamfer))
    reorient(anchor,spin,orient, r=P[0], h=2*P[8], p=vnf);

module worm_gear(
    // BEGIN GEAR_API_COMPAT
    _p0="__gear_legacy_omitted__", _p1="__gear_legacy_omitted__", _p2="__gear_legacy_omitted__",
    _p3="__gear_legacy_omitted__", _p4="__gear_legacy_omitted__", _p5="__gear_legacy_omitted__",
    _p6="__gear_legacy_omitted__", _p7="__gear_legacy_omitted__", _p8="__gear_legacy_omitted__",
    _p9="__gear_legacy_omitted__", _p10="__gear_legacy_omitted__", _p11="__gear_legacy_omitted__",
    _p12="__gear_legacy_omitted__", _p13="__gear_legacy_omitted__", _extra="__gear_legacy_omitted__",
    // END GEAR_API_COMPAT
    teeth, worm_diam, worm_starts, worm_arc, crowning, left_handed, pressure_angle, backlash,
    clearance, profile_shift, slices, shaft_diam, gear_spin, _named, mod, circ_pitch, diam_pitch,
    thickness, min_tip, face_chamfer, anchor, spin, orient
)
    // BEGIN GEAR_API_COMPAT
    let(_gear_args=_gear_legacy_args(
        "worm_gear()", [_p0,_p1,_p2,_p3,_p4,_p5,_p6,_p7,_p8,_p9,_p10,_p11,_p12,_p13], _extra,
        ["circ_pitch", "teeth", "worm_diam", "worm_starts", "worm_arc", "crowning", "left_handed", "pressure_angle", "backlash", "clearance", "profile_shift", "slices", "shaft_diam", "gear_spin"], ["teeth", "worm_diam", "worm_starts", "worm_arc", "crowning", "left_handed", "pressure_angle", "backlash", "clearance", "profile_shift", "slices", "shaft_diam", "gear_spin"],
        [teeth,worm_diam,worm_starts,worm_arc,crowning,left_handed,pressure_angle,backlash,clearance,profile_shift,slices,shaft_diam,gear_spin], circ_pitch, mod, diam_pitch))
    let(circ_pitch=_gear_args[0], teeth=_gear_args[1], worm_diam=_gear_args[2], worm_starts=_gear_args[3], worm_arc=_gear_args[4], crowning=_gear_args[5], left_handed=_gear_args[6], pressure_angle=_gear_args[7], backlash=_gear_args[8], clearance=_gear_args[9], profile_shift=_gear_args[10], slices=_gear_args[11], shaft_diam=_gear_args[12], gear_spin=_gear_args[13])
    // END GEAR_API_COMPAT

    assert(is_undef(_named), "worm_gear(): arguments after teeth, worm_diam, worm_starts, worm_arc, crowning, left_handed, pressure_angle, backlash, clearance, profile_shift, slices, shaft_diam, gear_spin must be named")
 
    let(
        worm_starts=is_undef(worm_starts)?1:worm_starts, crowning=is_undef(crowning)?0.1:crowning,
        left_handed=is_undef(left_handed)?false:left_handed, backlash=is_undef(backlash)?0:backlash,
        profile_shift=is_undef(profile_shift)?"auto":profile_shift, slices=is_undef(slices)?10:slices,
        shaft_diam=is_undef(shaft_diam)?0:shaft_diam, gear_spin=is_undef(gear_spin)?0:gear_spin,
        anchor=is_undef(anchor)?CENTER:anchor, spin=is_undef(spin)?0:spin,
        orient=is_undef(orient)?UP:orient, face_chamfer=is_undef(face_chamfer)?0:face_chamfer
    )
{
    cp = _inherit_gear_pitch(fname="worm_gear()",circ_pitch=circ_pitch,diam_pitch=diam_pitch,mod=mod);
    pa = _inherit_gear_pa(pressure_angle=pressure_angle);
    ps = auto_profile_shift(teeth=teeth,pressure_angle=pa,profile_shift=profile_shift);
    assert(is_finite(shaft_diam) && shaft_diam>=0,
           "worm_gear(): shaft_diam must be nonnegative");
    assert(is_finite(gear_spin), "worm_gear(): invalid gear_spin");
    vnf = worm_gear(
        circ_pitch=cp, teeth=teeth, worm_diam=worm_diam,
        worm_starts=worm_starts, worm_arc=worm_arc, crowning=crowning,
        left_handed=left_handed, pressure_angle=pa, backlash=backlash,
        clearance=clearance, profile_shift=ps, slices=slices,
        thickness=thickness, min_tip=min_tip, gear_spin=gear_spin,
        face_chamfer=face_chamfer,
        anchor=CENTER, spin=0, orient=UP
    );
    // Uniform-height sections are ordered top to bottom.
    h = 2*vnf[0][0].z;
    pr = _wormgear_reference(m=cp/PI,teeth=teeth,d=worm_diam,starts=worm_starts,pa=pa,ps=ps)[0];
    attachable(anchor,spin,orient, r=pr, l=h) {
        difference() {
            vnf_polyhedron(vnf,convexity=12);
            if (shaft_diam>0)
                cylinder(h=2*h+1,d=shaft_diam,center=true,
                         $fn=max(12,segs(shaft_diam/2)));
        }
        children();
    }
}

// Helpers deliberately use native OpenSCAD only so that the envelope/mesh core
// is independently testable. The public wrappers provide BOSL2 integration.
function _wormgear_finite(x) = is_num(x) && (x-x)==0;

// [wheel_pr, center_distance, worm_pr, axial_flank_slope, lead/radian, axial_pitch]
function _wormgear_reference(m,teeth,d,starts,pa,ps) =
    assert(_wormgear_finite(x=m) && m>0, "worm_gear(): module must be positive")
    assert(_wormgear_finite(x=teeth) && teeth==floor(teeth) && teeth>7,
           "worm_gear(): teeth must be an integer greater than 7")
    assert(_wormgear_finite(x=starts) && starts==floor(starts) && starts>0,
           "worm_gear(): worm_starts must be a positive integer")
    assert(_wormgear_finite(x=d) && d>starts*m && d>2*m,
           "worm_gear(): worm_diam must exceed starts*module and 2*module")
    assert(_wormgear_finite(x=pa) && pa>=0 && pa<90, "worm_gear(): invalid pressure_angle")
    assert(_wormgear_finite(x=ps) && abs(ps)<1, "worm_gear(): abs(profile_shift) must be < 1")
    let(
        cb=sqrt(1-pow(starts*m/d,2)), p=PI*m/cb, R=teeth*p/(2*PI)
    ) [R,R+d/2+ps*m,d/2,tan(pa)/cb,starts*p/(2*PI),p];

function _wormgear_halfwidth(m,d,ps,clear,arc,thickness) =
    assert(is_undef(arc) || is_undef(thickness),
           "worm_gear(): specify thickness OR worm_arc, not both")
    assert(_wormgear_finite(x=clear) && clear>=0, "worm_gear(): invalid clearance")
    assert(is_undef(arc) || (_wormgear_finite(x=arc) && arc>0 && arc<=90),
           "worm_gear(): worm_arc must be in (0,90]")
    assert(is_undef(thickness) || (_wormgear_finite(x=thickness) && thickness>0),
           "worm_gear(): thickness must be positive")
    let(
        C=d/2+m*(1-ps)+clear,
        H=is_undef(thickness) ? C*sin((is_undef(arc)?45:arc)/2) : thickness/2,
        rb=d/2-m
    )
    assert(H<rb*(1-1e-9),
           str("worm_gear(): thickness is too large for this throat; require thickness < ",
               2*rb," (equivalent worm_arc < ",2*asin(min(1,rb/C))," degrees)"))
    H;

// P = [R, a, worm_pr, cutter_tip_r, blank_throat_r, flank_slope,
//      signed_lead_per_rad, axial_pitch, half_thickness, backlash,
//      crown_relief_per_flank, teeth, module, min_tip]
function _wormgear_data(m,teeth,d,starts,pa,ps,clear,backlash,crown,arc,
                        left=false,thickness,min_tip) =
    let(
        ref=_wormgear_reference(m=m,teeth=teeth,d=d,starts=starts,pa=pa,ps=ps),
        H=_wormgear_halfwidth(m=m,d=d,ps=ps,clear=clear,arc=arc,thickness=thickness),
        nt=is_undef(min_tip)?0.4*m:min_tip,
        rt=d/2+m+clear
    )
    assert(_wormgear_finite(x=backlash) && backlash>=0, "worm_gear(): invalid backlash")
    assert(_wormgear_finite(x=crown) && crown>=0, "worm_gear(): invalid crowning")
    assert(is_bool(left), "worm_gear(): invalid left_handed")
    assert(_wormgear_finite(x=nt) && nt>0, "worm_gear(): min_tip must be positive")
    assert(ref[1]>rt, "worm_gear(): cutter reaches the wheel axis; increase teeth")
    assert(ref[5]/4-ref[3]*(m+clear)+backlash/2>1e-9*m,
           "worm_gear(): extended cutter tip is pointed or inverted; reduce pressure_angle or clearance")
    [ref[0],ref[1],ref[2],rt,d/2-m,ref[3],(left?-1:1)*ref[4],ref[5],H,
     backlash,crown,teeth,m,nt];

// Angular interval cut by ONE worm thread on a wheel-centered circle.
// Let t be the wheel angle at contact, with physical coordinates
//   x=a-rho*cos(t), y=rho*sin(t), r=sqrt(x*x+z*z).
// A cutter flank at axial coordinate +/-w(r)-h*atan2(z,x) reaches this
// point when the equivalent rack has translated -R*psi. Eliminating psi:
//   angle=(y+h*atan2(z,x)+/-w(r))/R - t, in radians.
// As t ranges between the two intersections with the cutter-tip cylinder,
// the cut intervals form a connected union (they meet at t=0).
// Its min/max bounds therefore select the EXPOSED envelope, including
// tip-generated roots and undercut, not just local tangency candidates.
function _wormgear_cutangle(t,rho,z,side,P) =
    let(
        x=P[1]-rho*cos(t),
        r=sqrt(x*x+z*z),
        w=P[7]/4-P[5]*(r-P[2])+P[9]/2+P[10]*pow(z/P[8],2)
    )
    (rho*sin(t)+P[6]*atan2(z,x)*PI/180+side*w)/P[0]*180/PI-t;

// Positive factor R times derivative of cutangle with respect to t.
function _wormgear_cutderiv(t,rho,z,side,P) =
    let(
        x=P[1]-rho*cos(t),
        y=rho*sin(t),
        r=sqrt(x*x+z*z)
    )
    rho*cos(t)-P[0]-y*(P[6]*z/(r*r)+side*P[5]*x/r);

function _wormgear_stationary(rho,z,side,P,lo,hi,dlo,n) =
    n==0 || dlo==0 ? (dlo==0 ? lo : (lo+hi)/2) :
    let(
        mid=(lo+hi)/2,
        dm=_wormgear_cutderiv(t=mid,rho=rho,z=z,side=side,P=P)
    )
    dm*dlo>0
      ? _wormgear_stationary(rho=rho,z=z,side=side,P=P,lo=mid,hi=hi,dlo=dm,n=n-1)
      : _wormgear_stationary(rho=rho,z=z,side=side,P=P,lo=lo,hi=mid,dlo=dlo,n=n-1);

function _wormgear_cutlimits(rho,z,P,nsearch,niters) =
    let(
        root=P[1]-sqrt(P[3]*P[3]-z*z),
        tmax=rho<=root*(1+1e-14) ? 0 : acos(min(1,max(-1,root/rho)))
    )
    tmax==0 ? [for(side=[-1,1]) _wormgear_cutangle(t=0,rho=rho,z=z,side=side,P=P)] :
    [for(side=[-1,1])
        let(
            ts=[for(j=[0:1:nsearch]) -tmax+2*tmax*j/nsearch],
            ds=[for(t=ts) _wormgear_cutderiv(t=t,rho=rho,z=z,side=side,P=P)],
            candidates=[
                each ts,
                for(j=[0:1:nsearch-1])
                    if(ds[j]*ds[j+1]<0)
                        _wormgear_stationary(rho=rho,z=z,side=side,P=P,lo=ts[j],hi=ts[j+1],dlo=ds[j],n=niters)
            ],
            angles=[for(t=candidates) _wormgear_cutangle(t=t,rho=rho,z=z,side=side,P=P)]
        ) side<0 ? min(angles) : max(angles)
    ];

// Transverse chord between the two flanks; negative means overlapping cuts.
function _wormgear_tipchord(r,b,P) =
    let(gap=360/P[11]-(b[1]-b[0]))
    gap<=0 ? -1 : 2*r*sin(gap/2);

/// Bracket: lo has enough tip land, hi does not. Returning lo conservatively
/// preserves the target rather than a radius that might fall short of it.
function _wormgear_tipradius(z,P,lo,hi,target,nsearch,niters,n=30) =
    n==0 ? lo :
    let(mid=(lo+hi)/2,b=_wormgear_cutlimits(rho=mid,z=z,P=P,nsearch=nsearch,niters=niters))
    _wormgear_tipchord(r=mid,b=b,P=P)<target
      ? _wormgear_tipradius(z=z,P=P,lo=lo,hi=mid,target=target,nsearch=nsearch,niters=niters,n=n-1)
      : _wormgear_tipradius(z=z,P=P,lo=mid,hi=hi,target=target,nsearch=nsearch,niters=niters,n=n-1);

function _wormgear_polar(r,a,z) = [r*cos(a),r*sin(a),z];

// One CCW tooth followed by its root gap. All rows have the same point count.
// Return [points, shortened, top_radius, transverse_target]. A tooth can be
// wider ABOVE its undercut root, so do not require min_tip at the root.
function _wormgear_section(z,P,nprofile,narc,nsearch,niters,target,max_radius) =
    let(
        goal=is_undef(target)?P[13]:target,
        period=360/P[11], base=90-period/2,
        root=P[1]-sqrt(P[3]*P[3]-z*z),
        blank0=P[1]-sqrt(P[4]*P[4]-z*z),
        blank=is_undef(max_radius)?blank0:min(blank0,max_radius),
        check=assert(blank>root+1e-8*P[12],
                     "worm_gear(): face_chamfer removes the tooth; reduce face_chamfer"),
        bt=_wormgear_cutlimits(rho=blank,z=z,P=P,nsearch=nsearch,niters=niters),
        clipped=_wormgear_tipchord(r=blank,b=bt,P=P)<goal,
        // Scan only when necessary. It brackets the OUTERMOST feasible tip,
        // including a root-narrowed/undercut tooth with its maximum above root.
        nscan=max(32,2*nprofile,nsearch),
        rr0=clipped ? [for(j=[0:1:nscan]) root+(blank-root)*j/nscan] : [],
        bb0=clipped ? [for(r=rr0) _wormgear_cutlimits(rho=r,z=z,P=P,nsearch=nsearch,niters=niters)] : [],
        good=clipped ? [for(j=[0:1:nscan])
                           if(_wormgear_tipchord(r=rr0[j],b=bb0[j],P=P)>=goal) j] : []
    )
    assert(!clipped || len(good)>0,
           str("worm_gear(): cannot retain min_tip=",P[13]," at z=",z,
               ". Reduce face_chamfer (when used), thickness/worm_arc, or revise the tooth parameters; ",
               "the requested minimum has not been relaxed."))
    let(
        last_good=clipped?good[len(good)-1]:0,
        top=clipped ? _wormgear_tipradius(z=z,P=P,lo=rr0[last_good],hi=rr0[last_good+1],
                                          target=goal,nsearch=nsearch,niters=niters) : blank,
        rr=[for(j=[0:1:nprofile]) root+(top-root)*j/nprofile],
        bb=[for(r=rr) _wormgear_cutlimits(rho=r,z=z,P=P,nsearch=nsearch,niters=niters)],
        gaps=[for(b=bb) period-b[1]+b[0]]
    )
    assert(min(gaps)>1e-9,
           "worm_gear(): generated cuts remove the tooth; reduce backlash/crowning or revise tooth parameters")
    assert(top*cos(gaps[nprofile]/2)>root+1e-8*P[12],
           is_undef(max_radius)
                ? "worm_gear(): min_tip leaves insufficient tooth height; reduce thickness or revise tooth parameters"
                : "worm_gear(): face_chamfer/min_tip leaves insufficient tooth height; reduce face_chamfer or thickness")
    let(
        points=[
            for(j=[0:1:nprofile]) _wormgear_polar(r=rr[j],a=base+bb[j][1],z=z),
            // One chord across the land, rather than a nearly collinear arc.
            for(j=[nprofile:-1:0]) _wormgear_polar(r=rr[j],a=base+bb[j][0]+period,z=z),
            for(j=[1:1:narc-1])
                _wormgear_polar(r=root,a=base+bb[0][0]+period
                    +(bb[0][1]-bb[0][0])*j/narc,z=z)
        ]
    ) [points,clipped,top,goal];

// Squared distances in 3D. Segment/segment minimum consists of the four
// endpoint/segment minima plus the interior stationary point (if feasible).
function _wormgear_pointseg2(p,a,b) =
    let(v=b-a,w=p-a,vv=v*v,t=vv==0?0:max(0,min(1,(w*v)/vv)),d=w-t*v) d*d;

function _wormgear_segdist2(p0,p1,q0,q1) =
    let(
        u=p1-p0,v=q1-q0,w=p0-q0,
        a=u*u,b=u*v,c=v*v,d=u*w,e=v*w,den=a*c-b*b,
        s=den>1e-14*a*c ? (b*e-c*d)/den : -1,
        t=den>1e-14*a*c ? (a*e-b*d)/den : -1,
        delta=w+s*u-t*v
    )
    min([
        _wormgear_pointseg2(p=p0,a=q0,b=q1), _wormgear_pointseg2(p=p1,a=q0,b=q1),
        _wormgear_pointseg2(p=q0,a=p0,b=p1), _wormgear_pointseg2(p=q1,a=p0,b=p1),
        if(s>=0 && s<=1 && t>=0 && t<=1) max(0,delta*delta)
    ]);

// Pairs of opposite crest segments closer than the required width. Skipping
// pairs already separated enough in z is an exact lower-bound optimization.
// Each entry is [left_segment_index, right_segment_index, target_multiplier].
function _wormgear_narrow_pairs(sections,nprofile,goal) =
    let(n=len(sections)-1)
    [for(i=[0:1:n-1],j=[0:1:n-1])
        let(
            a=sections[i][0][nprofile], b=sections[i+1][0][nprofile],
            c=sections[j][0][nprofile+1], d=sections[j+1][0][nprofile+1],
            dz=max(0,max(min(a.z,b.z),min(c.z,d.z))-min(max(a.z,b.z),max(c.z,d.z)))
        )
        if(dz<goal)
        let(dist2=_wormgear_segdist2(p0=a,p1=b,q0=c,q1=d))
        if(dist2<goal*goal)
            [i,j,1.01*goal/sqrt(max(dist2,goal*goal*1e-12))]
    ];

// First solve the transverse problem, then enlarge only affected transverse
// targets until opposite CREST EDGES are separated in 3D. This handles skew,
// not just vanishing tooth width at one z. Cached unaffected sections are reused.
// The small scale-relative margin also covers ordinary STL float rounding.
function _wormgear_blunt_sections(zs,P,nprofile,narc,nsearch,niters,
                                  targets,previous,n=12,limits) =
    let(
        goal=P[13]+max(1e-5*P[12],2e-7*P[0]),
        goals=is_undef(targets)?[for(z=zs)goal]:targets,
        secs=[for(j=[0:1:len(zs)-1])
            !is_undef(previous) && previous[j][3]==goals[j] ? previous[j] :
            _wormgear_section(z=zs[j],P=P,nprofile=nprofile,narc=narc,nsearch=nsearch,niters=niters,target=goals[j],
                              max_radius=is_undef(limits)?undef:limits[j])],
        bad=_wormgear_narrow_pairs(sections=secs,nprofile=nprofile,goal=goal)
    )
    len(bad)==0 ? secs :
    assert(n>0,
           "worm_gear(): 3D min_tip constraint did not converge; increase slices or reduce thickness (minimum not relaxed)")
    let(
        next=[for(j=[0:1:len(zs)-1]) goals[j]*max([
            1, for(b=bad) if(j==b[0] || j==b[0]+1 || j==b[1] || j==b[1]+1) b[2]
        ])]
    ) _wormgear_blunt_sections(zs=zs,P=P,nprofile=nprofile,narc=narc,nsearch=nsearch,niters=niters,targets=next,previous=secs,n=n-1,limits=limits);

function _wormgear_rotate(p,a) =
    [p[0]*cos(a)-p[1]*sin(a),p[0]*sin(a)+p[1]*cos(a),p[2]];

// Rows run TOP to BOTTOM, counterclockwise around each section. The face
// winding below follows OpenSCAD/BOSL2's clockwise-outside convention.
// Caps are planar polygons; no potentially invalid center-fan triangulation
// is used for an undercut section.
function _wormgear_mesh(rows) =
    let(
        nr=len(rows), nc=len(rows[0]),
        vertices=[for(row=rows) each row],
        faces=[
            [for(i=[nc-1:-1:0]) i],
            [for(i=[0:1:nc-1]) (nr-1)*nc+i],
            for(j=[0:1:nr-2],i=[0:1:nc-1]) each
                let(a=j*nc+i,b=j*nc+(i+1)%nc,
                    c=(j+1)*nc+i,d=(j+1)*nc+(i+1)%nc)
                ((i+j)%2==0 ? [[a,b,c],[c,b,d]] : [[a,b,d],[a,d,c]])
        ]
    ) [vertices,faces];


// Equal-setback conical face trims. These operate on the meridional (r,z)
// outside profile, NOT on the individual tooth-outline edges. The reference
// profile is the unchamfered, min_tip-compliant sampled rim. One endpoint is
// face_chamfer inward along the face; the other is that same distance along
// the rim polyline. Rotating their connecting line gives the trimming cone.
// Bevel transition rows are inserted independently of the requested slices.
function _wormgear_walk_rim(rim,d,i=0) =
    assert(i<len(rim)-1,
           "worm_gear(): face_chamfer reaches the middle plane; reduce face_chamfer")
    let(delta=rim[i+1]-rim[i],length=norm(delta))
    d<=length ? rim[i]+delta*(d/length) : _wormgear_walk_rim(rim=rim,d=d-length,i=i+1);

// Return [face_radius_after_setback, radial_slope_per_axial_depth, transition_z].
function _wormgear_face_cone(sections,chamfer,bottom=false,tolerance=0) =
    let(
        n=len(sections)-1,
        rim=[for(j=[0:1:n/2])
            let(k=bottom?n-j:j) [sections[k][2],abs(sections[k][0][0].z)]],
        B=_wormgear_walk_rim(rim=rim,d=chamfer),
        A=[rim[0].x-chamfer,rim[0].y],
        dz=A.y-B.y
    )
    assert(dz>3*tolerance, "worm_gear(): face_chamfer is below axial mesh precision; increase it or use zero")
    assert(B.y>0 && dz>0 && A.x>0 && B.x>A.x,
           "worm_gear(): face_chamfer is too large or cannot form an inward conical trim")
    [A.x,(B.x-A.x)/dz,B.y];

function _wormgear_insert_z(zs,z,eps,i=0) =
    i==len(zs)?concat(zs,[z]):
    abs(z-zs[i])<=eps?zs:
    z>zs[i]?[for(j=[0:1:i-1]) if(i>0) zs[j],z,for(j=[i:1:len(zs)-1])zs[j]]:
    _wormgear_insert_z(zs=zs,z=z,eps=eps,i=i+1);

function _wormgear_insert_zs(zs,extra,eps,i=0) =
    i==len(extra)?zs:_wormgear_insert_zs(zs=_wormgear_insert_z(zs=zs,z=extra[i],eps=eps),extra=extra,eps=eps,i=i+1);

// Linear interpolation of the radius/target field on the descending-z rim.
function _wormgear_rim_value(sections,z,field,i=0) =
    i>=len(sections)-1?sections[len(sections)-1][field]:
    let(z0=sections[i][0][0].z,z1=sections[i+1][0][0].z)
    z>=z1 ? let(t=max(0,min(1,(z0-z)/(z0-z1))))
               (1-t)*sections[i][field]+t*sections[i+1][field] :
            _wormgear_rim_value(sections=sections,z=z,field=field,i=i+1);

function _wormgear_chamfer_sections(base,P,nprofile,narc,nsearch,niters,chamfer) =
    chamfer==0?base:
    let(
        H=P[8],
        top=_wormgear_face_cone(sections=base,chamfer=chamfer,tolerance=max(1e-6*P[12],2e-7*P[0])),
        bot=_wormgear_face_cone(sections=base,chamfer=chamfer,bottom=true,tolerance=max(1e-6*P[12],2e-7*P[0])),
        // Two interior bevel rows and the exact reference transition per face.
        extra=[for(i=[1:1:3]) H-(H-top[2])*i/3,
               for(i=[1:1:3]) -H+(H-bot[2])*i/3],
        zs=_wormgear_insert_zs(zs=[for(s=base)s[0][0].z],extra=extra,eps=1e-10*P[12]),
        limits=[for(z=zs) min(_wormgear_rim_value(sections=base,z=z,field=2),
                              top[0]+top[1]*(H-z),bot[0]+bot[1]*(H+z))],
        targets=[for(z=zs)_wormgear_rim_value(sections=base,z=z,field=3)]
    )
    _wormgear_blunt_sections(zs=zs,P=P,nprofile=nprofile,narc=narc,nsearch=nsearch,niters=niters,
                            targets=targets,limits=limits);

function _wormgear_build(P,slices=10,nprofile=16,nsearch=24,niters=30,gear_spin=0,face_chamfer=0) =
    assert(_wormgear_finite(x=face_chamfer) && face_chamfer>=0,
           "worm_gear(): face_chamfer must be finite and nonnegative")
    assert(face_chamfer==0 || face_chamfer>=max(1e-6*P[12],2e-7*P[0]),
           "worm_gear(): face_chamfer is below mesh precision; increase it or use zero")
    assert(_wormgear_finite(x=slices) && slices==floor(slices) && slices>0,
           "worm_gear(): slices must be a positive integer")
    assert(_wormgear_finite(x=nprofile) && nprofile==floor(nprofile) && nprofile>=4,
           "worm_gear(): $gear_steps must be an integer >= 4")
    assert(_wormgear_finite(x=nsearch) && nsearch==floor(nsearch) && nsearch>=8,
           "worm_gear(): $worm_gear_search_steps must be an integer >= 8")
    assert(_wormgear_finite(x=niters) && niters==floor(niters) && niters>=10,
           "worm_gear(): $worm_gear_search_iters must be an integer >= 10")
    let(
        ns=2*ceil(slices/2), na=max(2,ceil(nprofile/4)),
        zs=[for(j=[0:1:ns]) P[8]*(1-2*j/ns)],
        base=_wormgear_blunt_sections(zs=zs,P=P,nprofile=nprofile,narc=na,nsearch=nsearch,niters=niters),
        sections=_wormgear_chamfer_sections(base=base,P=P,nprofile=nprofile,narc=na,nsearch=nsearch,niters=niters,chamfer=face_chamfer),
        rows=[for(sec=sections) [
            for(k=[0:1:P[11]-1],p=sec[0])
                _wormgear_rotate(p=p,a=k*360/P[11]+gear_spin)
        ]]
    ) _wormgear_mesh(rows=rows);


/// Function: _gear_tooth_profile()
/// Usage: As a Function
///   value = _gear_tooth_profile(mod=|circ_pitch=|diam_pitch=, teeth, [pressure_angle], [clearance], [backlash], [internal], [center], [helical=], [profile_shift=], [shorten=]);
/// Topics: Gears
/// See Also: spur_gear2d()
/// Description:
///   When called as a function, returns the 2D profile path for an individual gear tooth.
///   When called as a module, creates the 2D profile shape for an individual gear tooth.
/// Arguments:
///   teeth = Total number of teeth on the spur gear that this is a tooth for.
///   pressure_angle = Pressure Angle.  Controls how straight or bulged the tooth sides are. In degrees.
///   clearance = Gap between top of a tooth on one gear and bottom of valley on a meshing gear (in millimeters)
///   backlash = Gap between two meshing teeth, in the direction along the circumference of the pitch circle
///   internal = If true, create a mask for difference()ing from something else.
///   center = If true, centers the pitch circle of the tooth profile at the origin.  Default: false.
///   ---
///   circ_pitch = The circular pitch, the distance between teeth centers around the pitch circle.
///   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  The diametral pitch is a completely different thing than the pitch diameter.
///   mod = The module of the gear (pitch diameter / teeth)
///   helical = Helix angle. Default: 0
///   profile_shift = Profile shift coefficient. Default: 0
///   shorten = Tip shortening factor. Default: 0
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
    teeth, pressure_angle=20, clearance, backlash=0.0, internal=false, center=false, _named,
    circ_pitch, diam_pitch, mod, helical=0, profile_shift=0.0, shorten=0
) =
    assert(is_undef(_named), "_gear_tooth_profile(): arguments after teeth, pressure_angle, clearance, backlash, internal, center must be named")
 let(
    // Calculate a point on the involute curve, by angle.
    _involute = function(base_r,a)
        let(b=a*PI/180) base_r * [cos(a)+b*sin(a), sin(a)-b*cos(a)],

    steps = !is_undef($gear_steps) ? $gear_steps : 16,
    circ_pitch = circular_pitch(circ_pitch=circ_pitch, diam_pitch=diam_pitch, mod=mod),
    mod = module_value(circ_pitch=circ_pitch),
    clear = default(clearance, 0.25 * mod),

    // Calculate the important circle radii
    arad = outer_radius(circ_pitch=circ_pitch, teeth=teeth, helical=helical, profile_shift=profile_shift, internal=internal, shorten=shorten),
    prad = pitch_radius(circ_pitch=circ_pitch, teeth=teeth, helical=helical),
    brad = _base_radius(circ_pitch=circ_pitch, teeth=teeth, pressure_angle=pressure_angle, helical=helical),
    rrad = _root_radius_basic(circ_pitch=circ_pitch, teeth=teeth, clearance=clear, helical=helical, profile_shift=profile_shift, internal=internal),
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
            if (pol.x <= arad * 1.1) [pol.x, 90-pol.y]
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
    maxr =  norm(rcorner[0]-rcorner[1])*tan(vector_angle(rcorner)/2),  // Max radius that will actually fit on the corner
    round_r = min(maxr, clear, rcircum*rpart),
    rounded_tooth_half = deduplicate([
        if (!internal && round_r>0) each arc(n=8, r=round_r, corner=rcorner),
        if (!internal && round_r<=0) isect_pt,
        each tooth_half_raw,
        if (internal && round_r>0) each arc(n=8, r=round_r, corner=rcorner),
        if (internal && round_r<=0) isect_pt,
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

    // look for self-intersections in the gear profile.  If found, clip them off
    invalid = [for(i=idx(tooth_half)) if (atan2(tooth_half[i].y,tooth_half[i].x)>90+180/teeth) i],
    clipped = invalid==[] ? tooth_half
            : let(
                   ind = last(invalid),
                   ipt = line_intersection([[0,0],polar_to_xy(1,90+180/teeth)], select(tooth_half,ind,ind+1)),
                   c = prad - mod*(1-profile_shift) - norm(ipt)
              )
              //echo(str(teeth, " tooth gear profile clipped at clearance = ",c))
              [
                 ipt,
                 each slice(tooth_half, ind+1,-1)
              ], 
    
    // Mirror the tooth to complete it.
    full_tooth = deduplicate([
        each clipped, 
        each reverse(xflip(clipped)),
    ]),
    // Reduce number of vertices.
    tooth = path_merge_collinear(
        resample_path(full_tooth, n=ceil(2*steps), keep_corners=30, closed=false)
    ),
    out = center? fwd(prad, p=tooth) : tooth
) out;


// Section: Gear Assemblies

// Function: planetary_gears()
// Synopsis: Calculate teeth counts and angles for planetary gear assembly with specified ratio.
// Usage: As a Function
//   gear_data = planetary_gears(mod=|circ_pitch=|diam_pitch=, n, max_teeth, ring_carrier=|carrier_ring=|sun_carrier=|carrier_sun=|ring_sun=|sun_ring=, [helical=], [gear_spin=]);
// Description:
//   Calculates a planetary gear assembly that approximates a desired transmission ratio.  A planetary gear assembly can be regarded as having three
//   elements: the outer ring gear, the central sun gear, and a carrier that holds several planet gears, which fit between the sun and ring.
//   The transmission ratio of a planetary gear assembly depends on which element is fixed and which ones are considered the input and output shafts.
//   The fixed element can be the ring gear, the sun gear, or the carrier, and then you specify the desired ratio between the other two.
//   You must also specify a maximum number of teeth on the ring gear.  The function calculates the best approximation to your desired
//   transmission ratio under that constraint: a large enough increase in the allowed number of teeth will yield a more accurate approximation.  The planet gears
//   appear uniformly spaced around the sun gear, but this uniformity is often only approximate.  Exact uniformity occurs when teeth_sun+teeth_ring
//   is a multiple of the number of planet gears.
//   .
//   You specify the desired ratio using one of six parameters that identify which ratio you want to specify, and which is the driven element.
//   Each different ratio is limited to certain bounds.  For the case of the fixed carrier system, the sun and ring rotate in opposite directions.
//   This is sometimes indicated by a negative transmission ratio.  For these cases you can give a positive or negative value.  
//   .
//   The return is a list of entries that describe the elements of the planetary assembly.  The list entries are:
//   - ["sun", teeth, profile_shift, spin]
//   - ["ring", teeth, profile_shift, spin]
//   - ["planets", teeth, profile_shift, spins, positions, angles]
//   - ["ratio", realized_ratio]
//   .
//   The sun and ring gear are assumed to be placed at the origin.  The planet gears are placed at the list of positions.  The gears all
//   have a spin in degrees.  The planets list also includes the angular position of each planet in the `angles` list.
//   One of the planets always appears on the X+ axis when `gear_spin` is zero.  The final list entry gives the realized ratio of
//   the assembly, so you can determine how closely it approaches your desired ratio.  This will always be a positive value.  
//   .
//   The sun gear appears by default with a tooth pointing on the Y+ axis with no spin, so if gear_spin is not used then the sun gear spin will
//   always be zero.  If you set `gear_spin` then the drive gear for the ratio you specified will be rotated by the specified angle and all
//   of the other gears will be rotated appropriately.
//   .
//   The computation of planetary gear assembles is about determining the teeth counts on the sun, ring and planet gears,
//   and the angular positions of the planet gears.
//   The tooth size or helical angle are needed only for determining proper profile shifting and for determining the
//   gear positions for the profiled shifted gears.  To control the size of the assembly, do a planetary calculation
//   with a module of 1 and then scale the module to produce the required gear dimensions.  Remember, you should never
//   use `scale()` on gears; change their size by scaling the module or one of the other tooth size parameters.  
// Arguments:
//   n = Number of planetary gears
//   max_teeth = maximum number of teeth allowed on the ring gear
//   ---
//   mod = The module of the gear, pitch diameter divided by tooth count. 
//   circ_pitch = distance between teeth centers around the pitch circle.
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  The diametral pitch is a completely different thing than the pitch diameter.
//   ring_carrier = set ring/carrier transmission ratio to this value in a ring driven system, must be between 1 and 2
//   carrier_ring = set carrier/ring transmission ratio to this value in a carrier driven system, must be between 1/2 and 1
//   sun_carrier = set sun/carrier transmission ratio to this value in a sun driven system, must be larger than 2
//   carrier_sun = set carrier/sun transmission ratio to this value in a carrier driven system, must be smaller than 1/2
//   ring_sun = set ring/sun transmission ratio to this value in a ring driven system, must have absolute value smaller than 1
//   sun_ring = set sun/ring transmission ratio to this value in a sun driven system, must have absolute value larger than 1
//   helical = create gears with specified helical angle.  Default: 0
//   gear_spin = rotate the driven gear by this number of degrees.  Default:0
// Example(2D,NoAxes,Anim,Frames=90,FrameMS=30,VPT=[-0.875705,-0.110537,-66.3877],VPR=[0,0,0],VPD=102,Med): In this example we request a ring/carrier ratio of 1.341 and the system produced has a ratio of 4/3.  The sun is fixed, the input is carried by the ring, and the carrier, shown as the blue triangle, is the output, rotating approximately in accordance with the requested ratio.  
//   mod=1;
//   gear_data = planetary_gears(mod=mod, n=3, max_teeth=28, ring_carrier=1.341, gear_spin=4/3*360/3*$t);
//   ring_gear2d(mod=mod, teeth=gear_data[1][1], profile_shift=gear_data[1][2], gear_spin=gear_data[1][3],backing=2);
//   stroke(gear_data[2][4],closed=true,color="blue",width=2);
//     spur_gear2d(mod=mod, teeth=gear_data[0][1], profile_shift=gear_data[0][2], gear_spin=gear_data[0][3]);  //sun
//   color("red")move_copies(gear_data[2][4])
//     spur_gear2d(mod=mod, teeth=gear_data[2][1], profile_shift=gear_data[2][2], gear_spin=gear_data[2][3][$idx]);
// Example(2D,Med,NoAxes,Anim,FrameMS=60,Frames=90,VPT=[-0.125033,0.508151,-66.3877],VPR=[0,0,0],VPD=192.044): In this example we request a sun/carrier ratio of 3.6 and get exactly that ratio.  The carrier shown as the blue pentagon moves very slowly as the central sun turns.  The ring is fixed.  
//   mod=1;
//   gear_data = planetary_gears(mod=mod, n=5, max_teeth=70, sun_carrier=3.6, gear_spin=3.6*360/5*$t);
//   ring_gear2d(mod=mod, teeth=gear_data[1][1], profile_shift=gear_data[1][2], gear_spin=gear_data[1][3],backing=2);
//   stroke(gear_data[2][4],closed=true,color="blue");
//   color("gold")
//     spur_gear2d(mod=mod, teeth=gear_data[0][1], profile_shift=gear_data[0][2], gear_spin=gear_data[0][3]);  //sun
//   color("red")move_copies(gear_data[2][4])
//       spur_gear2d(mod=mod, teeth=gear_data[2][1], profile_shift=gear_data[2][2], gear_spin=gear_data[2][3][$idx]);
// Example(3D,Med,NoAxes,Anim,Frames=7,FrameMS=50,VPT=[0.128673,0.24149,0.651451],VPR=[38.5,0,21],VPD=222.648): Here we request a sun/ring ratio of 3 and it is exactly achieved.  The carrier, shown in blue, is fixed.  This example is shown with helical gears.  It is important to remember to flip the sign of the helical angle for the planet gears.  
//   $fn=81;
//   mod=1;
//   helical=25;
//   gear_data = planetary_gears(mod=mod, n=4, max_teeth=82, sun_ring=3, helical=helical,gear_spin=360/27*$t);
//   ring_gear(mod=mod, teeth=gear_data[1][1], profile_shift=gear_data[1][2], helical=helical, gear_spin=gear_data[1][3],backing=4,thickness=7);
//   color("blue"){
//       move_copies(gear_data[2][4]) cyl(h=12,d=4);
//       down(9)linear_extrude(height=3)scale(1.2)polygon(gear_data[2][4]);
//   }    
//   spur_gear(mod=mod, teeth=gear_data[0][1], profile_shift=gear_data[0][2], helical=helical, gear_spin=gear_data[0][3]);  //sun
//   color("red")move_copies(gear_data[2][4])
//       spur_gear(mod=mod, teeth=gear_data[2][1], profile_shift=gear_data[2][2], helical=-helical, gear_spin=gear_data[2][3][$idx]);
function planetary_gears(
    n, max_teeth, _named, mod, circ_pitch, diam_pitch, ring_carrier, carrier_ring, sun_carrier,
    carrier_sun, ring_sun, sun_ring, helical, gear_spin
) =
    assert(is_undef(_named), "planetary_gears(): arguments after n, max_teeth must be named")

    let(helical=default(helical,0),
        gear_spin=default(gear_spin,0))

    let(
        mod = module_value(mod=mod,circ_pitch=circ_pitch,diam_pitch=diam_pitch),
        dummy = one_defined([ring_carrier,carrier_ring,sun_carrier,carrier_sun,sun_ring,ring_sun],
                            "ring_carrier,carrier_ring,sun_carrier,carrier_sun,sun_ring,ring_sun"),
        // ratio is between the sun and ring 
        ratio = is_def(ring_carrier) ? assert(is_finite(ring_carrier) && ring_carrier>1 && ring_carrier<2, "ring/carrier ratio must be between 1 and 2")
                                       ring_carrier - 1
              : is_def(carrier_ring) ? assert(is_finite(carrier_ring) && carrier_ring>1/2 && carrier_ring<1, "carrier/ring ratio must be between 1/2 and 1")
                                       1/carrier_ring - 1
              : is_def(sun_carrier) ?  assert(is_finite(sun_carrier) && sun_carrier>2, "sun/carrier ratio must be larger than 2")
                                       1/(sun_carrier-1)
              : is_def(carrier_sun) ?  assert(is_finite(carrier_sun) && carrier_sun<1/2, "carrier/sun ratio must be smaller than 1/2")
                                       1/(1/carrier_sun-1)
              : is_def(sun_ring) ?     assert(is_finite(sun_ring) && abs(sun_ring)>1, "abs(sun/ring) ratio must be larger than 1")
                                       1/abs(sun_ring)
              : /*is_def(ring_sun)*/   assert(is_finite(ring_sun) && abs(ring_sun)<1, "abs(ring/sun) ratio must be smaller than 1")
                                       abs(ring_sun),
        pq = rational_approx(ratio, max_teeth),
        factor = floor(max_teeth/pq[1]),
        temp_z_sun = factor*pq[0],
        temp_z_ring = factor*pq[1],
        z_sun = temp_z_sun%2==0 ? temp_z_sun+1 : temp_z_sun,
        z_ring = temp_z_ring%2==0 ? min(temp_z_ring+1, max_teeth-(max_teeth%2==0?1:0)) : temp_z_ring,
        z_planet = (z_ring-z_sun)/2
    )
    assert(z_planet==floor(z_planet),"Planets have non-integer teeth count!  Algorithm failed.")
    let(
        d12 = gear_dist(mod=mod,teeth1=z_sun,teeth2=z_planet,helical=helical),
        ps_sun = auto_profile_shift(teeth=z_sun,helical=helical),
        ps_planet = auto_profile_shift(teeth=z_planet,helical=helical),
        ps_ring = ps_sun+2*ps_planet,
        ring_spin = ring_sun || ring_carrier ? gear_spin
                  : sun_ring ? -gear_spin*z_sun/z_ring
                  : carrier_ring ? gear_spin*(z_ring+z_sun)/z_ring
                  : 0,
        planet_rot = ring_carrier ? gear_spin*z_ring/(z_ring+z_sun)
                   : carrier_sun || carrier_ring ? gear_spin
                   : sun_carrier ? gear_spin*z_sun/(z_ring+z_sun)
                   : carrier_ring ? gear_spin*z_ring/(z_ring+z_sun)
                   : 0,
        sun_spin = ring_sun ? -gear_spin*z_ring/z_sun
                 : sun_ring || sun_carrier ? gear_spin
                 : carrier_sun ? (z_ring+z_sun)*gear_spin/z_sun
                 : 0,
        planet_spin = -sun_spin*z_sun/z_planet,

        quant = 360/(z_sun+z_ring),
        planet_angles = [for (uang=lerpn(0,360,n,endpoint=false)) quant(uang,quant)+planet_rot],
        planet_pos = [for(ang=planet_angles) d12*[cos(ang),sin(ang)]],
        planet_spins = [for(ang=planet_angles) (z_sun/z_planet)*(ang-90)+90+ang+360/z_planet/2+planet_spin],

        final_ratio = ring_carrier ? 1+z_sun/z_ring
                    : carrier_ring ? 1/(1+z_sun/z_ring)
                    : sun_carrier ? 1+z_ring/z_sun
                    : carrier_sun ? 1/(1+z_ring/z_sun)
                    : sun_ring ? z_ring/z_sun
                    : /* ring_run */ z_sun/z_ring
   )   
   [  
     ["sun", z_sun, ps_sun, sun_spin],
     ["ring", z_ring, ps_ring, 360/z_ring/2 * (1-(z_sun%2))+ring_spin],
     ["planets", z_planet, ps_planet, planet_spins, planet_pos, planet_angles],
     ["ratio", final_ratio]
   ];



// Section: Computing Gear Dimensions
//   These functions let the user find the derived dimensions of the gear.
//   A gear fits within a circle of radius outer_radius, and two gears should have
//   their centers separated by the sum of their pitch_radius.


// Function: circular_pitch()
// Synopsis: Returns tooth density expressed as "circular pitch".
// Topics: Gears, Parts
// See Also: spur_gear(), diametral_pitch(), circular_pitch(), module_value()
// Usage: As a Function
//   cp = circular_pitch(mod=|circ_pitch=|diam_pitch=);
// Description:
//   Get tooth size expressed as "circular pitch", or the distance between teeth centers around the pitch circle.
//   For example, an 11 tooth gear with a pitch circumference of 110 mm has a circular pitch of 110 mm /11, or 10 mm / tooth.
//   Note that this calculation is does not depend on units for circ_pitch or mod, but the `diam_pitch` argument is based
//   on inches and returns its value in millimeters.  
// Arguments:
//   ---
//   mod = The module of the gear (pitch diameter / teeth)
//   circ_pitch = The circular pitch, the distance between teeth centers around the pitch circle.
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  The diametral pitch is a completely different thing than the pitch diameter.
// Example(2D,Med,VPT=[0,31,0],VPR=[0,0,0],VPD=40):
//   $fn=144;
//   teeth=20;
//   circ_pitch = circular_pitch(diam_pitch=8);
//   pr = pitch_radius(circ_pitch=circ_pitch, teeth=teeth);
//   stroke(spur_gear2d(circ_pitch=circ_pitch, teeth=teeth), width=0.1);
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

function circular_pitch(
    // BEGIN GEAR_API_COMPAT
    _p0="__gear_legacy_omitted__", _extra="__gear_legacy_omitted__",
    // END GEAR_API_COMPAT
    _named, mod, circ_pitch, diam_pitch
) =
    // BEGIN GEAR_API_COMPAT
    let(_gear_args=_gear_legacy_args(
        "circular_pitch()", [_p0], _extra,
        ["circ_pitch"], [],
        [], circ_pitch, mod, diam_pitch))
    let(circ_pitch=_gear_args[0])
    // END GEAR_API_COMPAT

    assert(is_undef(_named), "circular_pitch(): arguments after the function name must be named")

    assert(num_defined([mod,circ_pitch,diam_pitch])==1,
           "circular_pitch(): specify exactly one of mod=, circ_pitch=, or diam_pitch=")
    circ_pitch != undef ? assert(is_finite(circ_pitch) && circ_pitch>0) circ_pitch :
    diam_pitch != undef ? assert(is_finite(diam_pitch) && diam_pitch>0) PI*INCH/diam_pitch :
    assert(is_finite(mod) && mod>0) mod*PI;


// Function: diametral_pitch()
// Synopsis: Returns tooth density expressed as "diametral pitch".
// Topics: Gears, Parts
// See Also: spur_gear(), diametral_pitch(), circular_pitch(), module_value()
// Usage: As a Function
//   dp = diametral_pitch(mod=|circ_pitch=|diam_pitch=);
// Description:
//   Returns tooth density expressed as "diametral pitch", the number of teeth per inch of pitch diameter.
//   For example, if you have a gear with 30 teeth, with a 1.5 inch pitch diameter, then you have a
//   diametral pitch of 20 teeth/inch.
// Arguments:
//   ---
//   mod = The module of the gear (pitch diameter / teeth)
//   circ_pitch = The circular pitch, the distance between teeth centers around the pitch circle.
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  The diametral pitch is a completely different thing than the pitch diameter.
// Example:
//   diam_pitch1 = diametral_pitch(mod=2);
//   diam_pitch2 = diametral_pitch(circ_pitch=8);
//   diam_pitch3 = diametral_pitch(diam_pitch=16);

function diametral_pitch(
    // BEGIN GEAR_API_COMPAT
    _p0="__gear_legacy_omitted__", _extra="__gear_legacy_omitted__",
    // END GEAR_API_COMPAT
    _named, mod, circ_pitch, diam_pitch
) =
    // BEGIN GEAR_API_COMPAT
    let(_gear_args=_gear_legacy_args(
        "diametral_pitch()", [_p0], _extra,
        ["circ_pitch"], [],
        [], circ_pitch, mod, diam_pitch))
    let(circ_pitch=_gear_args[0])
    // END GEAR_API_COMPAT

    assert(is_undef(_named), "diametral_pitch(): arguments after the function name must be named")


    let( circ_pitch = circular_pitch(circ_pitch=circ_pitch, mod=mod, diam_pitch=diam_pitch) )
    PI / circ_pitch * INCH;


// Function: module_value()
// Synopsis: Returns tooth density expressed as "module"
// Topics: Gears, Parts
// See Also: spur_gear(), diametral_pitch(), circular_pitch(), module_value()
// Usage: As a Function
//   m = module_value(mod=|circ_pitch=|diam_pitch=);
// Description:
//   Get tooth size expressed as "module".  The module is the pitch
//   diameter of the gear divided by the number of teeth on the gear.  For example, a gear with a pitch
//   diameter of 40 mm, with 20 teeth on it will have a modulus of 2 mm.  For circ_pitch and mod this
//   calculation does not depend on untis.  If you give diametral pitch, which is based on inputs, then
//   the module is returned in millimeters.  
// Arguments:
//   ---
//   mod = The module of the gear (pitch diameter / teeth)
//   circ_pitch = The circular pitch, the distance between teeth centers around the pitch circle.
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  The diametral pitch is a completely different thing than the pitch diameter.
// Example:
//   mod1 = module_value(circ_pitch=8);
//   mod2 = module_value(mod=2);
//   mod3 = module_value(diam_pitch=16);

function module_value(
    // BEGIN GEAR_API_COMPAT
    _p0="__gear_legacy_omitted__", _extra="__gear_legacy_omitted__",
    // END GEAR_API_COMPAT
    _named, mod, circ_pitch, diam_pitch
) =
    // BEGIN GEAR_API_COMPAT
    let(_gear_args=_gear_legacy_args(
        "module_value()", [_p0], _extra,
        ["circ_pitch"], [],
        [], circ_pitch, mod, diam_pitch))
    let(circ_pitch=_gear_args[0])
    // END GEAR_API_COMPAT

    assert(is_undef(_named), "module_value(): arguments after the function name must be named")


    let( circ_pitch = circular_pitch(circ_pitch=circ_pitch, mod=mod, diam_pitch=diam_pitch) )
    circ_pitch / PI;


/// Function: _adendum()
/// Usage: As a Function
///   value = _adendum(mod=|circ_pitch=|diam_pitch=, [profile_shift], [shorten=]);
/// Topics: Gears
/// Description:
///   The height of the top of a gear tooth above the pitch radius circle.
/// Arguments:
///   profile_shift = Profile shift factor x.  Default: 0 
///   ---
///   circ_pitch = The circular pitch, the distance between teeth centers around the pitch circle.
///   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  The diametral pitch is a completely different thing than the pitch diameter.
///   mod = The module of the gear (pitch diameter / teeth)
///   shorten = Tip shortening factor. Default: 0
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
    profile_shift=0, _named, circ_pitch, diam_pitch, mod, shorten=0
) =
    assert(is_undef(_named), "_adendum(): arguments after profile_shift must be named")

    let( mod = module_value(circ_pitch=circ_pitch, mod=mod, diam_pitch=diam_pitch) )
    mod * (1 + profile_shift - shorten);



/// Function: _dedendum()
/// Usage: As a Function
///   value = _dedendum(mod=|circ_pitch=|diam_pitch=, [clearance], [profile_shift]);
/// Topics: Gears
/// Description:
///   The depth of the gear tooth valley, below the pitch radius.
/// Arguments:
///   clearance = If given, sets the clearance between meshing teeth.  Default: module/4
///   profile_shift = Profile shift factor x.  Default: 0
///   ---
///   circ_pitch = The circular pitch, the distance between teeth centers around the pitch circle.
///   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  The diametral pitch is a completely different thing than the pitch diameter.
///   mod = The module of the gear (pitch diameter / teeth)
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
    clearance, profile_shift=0, _named, circ_pitch, diam_pitch, mod
) =
    assert(is_undef(_named), "_dedendum(): arguments after clearance, profile_shift must be named")
 let(
        mod = module_value(circ_pitch=circ_pitch, mod=mod, diam_pitch=diam_pitch),
        clearance = default(clearance, 0.25 * mod)
    )
    mod * (1 - profile_shift) + clearance;


// Function: pitch_radius()
// Synopsis: Returns the pitch radius for a gear.
// Topics: Gears, Parts
// See Also: spur_gear(), diametral_pitch(), circular_pitch(), module_value(), outer_radius()
// Usage: As a Function
//   pr = pitch_radius(mod=|circ_pitch=|diam_pitch=, teeth, [helical]);
// Description:
//   Calculates the pitch radius for the gear.  Two mated gears will have their centers spaced apart
//   by the sum of the two gear's pitch radii.
// Arguments:
//   teeth = The number of teeth on the gear.
//   helical = The helical angle (from vertical) of the teeth on the gear.  Default: 0
//   ---
//   mod = The module of the gear (pitch diameter / teeth)
//   circ_pitch = The circular pitch, the distance between teeth centers around the pitch circle.
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  The diametral pitch is a completely different thing than the pitch diameter.
// Example:
//   pr = pitch_radius(circ_pitch=5, teeth=11);
//   pr = pitch_radius(circ_pitch=5, teeth=11, helical=30);
//   pr = pitch_radius(diam_pitch=10, teeth=11);
//   pr = pitch_radius(mod=2, teeth=20);
//   pr = pitch_radius(mod=2, teeth=20, helical=30);
// Example(2D,Med,NoScales,VPT=[-0.20531,0.133721,0.658081],VPR=[0,0,0],VPD=82.6686):
//   $fn=144;
//   teeth=17; circ_pitch = 5;
//   pr = pitch_radius(circ_pitch=circ_pitch, teeth=teeth);
//   stroke(spur_gear2d(circ_pitch=circ_pitch, teeth=teeth), width=0.2);
//   color("blue") dashed_stroke(circle(r=pr), width=0.2);
//   color("black") {
//       stroke([[0,0],polar_to_xy(pr,45)],
//           endcaps="arrow", width=0.3);
//       fwd(1)
//           text("Pitch Radius", size=1.5,
//               halign="center", valign="top");
//   }

function pitch_radius(
    // BEGIN GEAR_API_COMPAT
    _p0="__gear_legacy_omitted__", _p1="__gear_legacy_omitted__", _p2="__gear_legacy_omitted__",
    _extra="__gear_legacy_omitted__",
    // END GEAR_API_COMPAT
    teeth, helical, _named, mod, circ_pitch, diam_pitch
) =
    // BEGIN GEAR_API_COMPAT
    let(_gear_args=_gear_legacy_args(
        "pitch_radius()", [_p0,_p1,_p2], _extra,
        ["circ_pitch", "teeth", "helical"], ["teeth", "helical"],
        [teeth,helical], circ_pitch, mod, diam_pitch))
    let(circ_pitch=_gear_args[0], teeth=_gear_args[1], helical=_gear_args[2])
    // END GEAR_API_COMPAT

    assert(is_undef(_named), "pitch_radius(): arguments after teeth, helical must be named")

    let(
        helical=is_undef(helical)?0:helical
    )

    let( circ_pitch = circular_pitch(circ_pitch=circ_pitch, mod=mod, diam_pitch=diam_pitch) )
    assert(is_finite(helical))
    assert(is_finite(circ_pitch))
    circ_pitch * teeth / PI / 2 / cos(helical);

// Function: outer_radius()
// Synopsis: Returns the outer radius for a gear.
// Topics: Gears, Parts
// See Also: spur_gear(), diametral_pitch(), circular_pitch(), module_value(), pitch_radius(), outer_radius()
// Usage: As a Function
//   r = outer_radius(mod=|circ_pitch=|diam_pitch=, teeth, [clearance=], [profile_shift=], [pressure_angle=], [helical=], [shorten=], [internal=]);
// Description:
//   Calculates the standard outer radius for the gear. The gear fits entirely within a cylinder of this radius.  The gear
//   will fit exactly in the cylinder except in two cases:
//      1.  It has been strongly profile shifted, in which case it will be undersized due to tip clipping.
//      2.  The pressure angle is very high, in which case the tips meet in points before the standard radius, also resulting in undersized teeth
// Arguments:
//   teeth = The number of teeth on the gear.
//   ---
//   mod = The module of the gear (pitch diameter / teeth)
//   circ_pitch = The circular pitch, the distance between teeth centers around the pitch circle.
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  The diametral pitch is a completely different thing than the pitch diameter.
//   clearance = If given, sets the clearance between meshing teeth.  Default: module/4
//   profile_shift = Profile shift factor x.  Default: "auto"
//   pressure_angle = Pressure angle.  Default: 20
//   helical = The helical angle (from vertical) of the teeth on the gear.  Default: 0
//   shorten = Shortening factor, needed to maintain clearance with profile shifting.  Default: 0
//   internal = If true, calculate for an internal gear.
// Example:
//   or = outer_radius(circ_pitch=5, teeth=20);
//   or = outer_radius(circ_pitch=5, teeth=20, helical=30);
//   or = outer_radius(diam_pitch=10, teeth=17);
//   or = outer_radius(mod=2, teeth=16);
// Example(2D,Med,NoScales,VPT=[-0.20531,0.133721,0.658081],VPR=[0,0,0],VPD=82.6686):
//   $fn=144;
//   teeth=17; circ_pitch = 5;
//   or = outer_radius(circ_pitch=circ_pitch, teeth=teeth);
//   stroke(spur_gear2d(circ_pitch=circ_pitch, teeth=teeth), width=0.2);
//   color("blue") dashed_stroke(circle(r=or), width=0.2);
//   color("black") {
//       stroke([[0,0],polar_to_xy(or,45)],
//           endcaps="arrow", width=0.3);
//       fwd(1)
//           text("Outer Radius", size=1.5,
//               halign="center", valign="top");
//   }

function outer_radius(
    // BEGIN GEAR_API_COMPAT
    _p0="__gear_legacy_omitted__", _p1="__gear_legacy_omitted__", _extra="__gear_legacy_omitted__",
    // END GEAR_API_COMPAT
    teeth, _named, mod, circ_pitch, diam_pitch, clearance, profile_shift, pressure_angle, helical,
    shorten, internal
) =
    // BEGIN GEAR_API_COMPAT
    let(_gear_args=_gear_legacy_args(
        "outer_radius()", [_p0,_p1], _extra,
        ["circ_pitch", "teeth"], ["teeth"],
        [teeth], circ_pitch, mod, diam_pitch))
    let(circ_pitch=_gear_args[0], teeth=_gear_args[1])
    // END GEAR_API_COMPAT

    assert(is_undef(_named), "outer_radius(): arguments after teeth must be named")

    let(
        internal=is_undef(internal)?false:internal, helical=is_undef(helical)?0:helical,
        profile_shift=is_undef(profile_shift)?"auto":profile_shift,
        pressure_angle=is_undef(pressure_angle)?20:pressure_angle, shorten=is_undef(shorten)?0:shorten
    )

    let(
       circ_pitch = circular_pitch(circ_pitch=circ_pitch, mod=mod, diam_pitch=diam_pitch),
       profile_shift = auto_profile_shift(teeth=teeth, pressure_angle=pressure_angle, helical=helical, profile_shift=profile_shift)
    )
    pitch_radius(circ_pitch=circ_pitch, teeth=teeth, helical=helical) + (
        internal
          ? _dedendum(circ_pitch=circ_pitch, clearance=clearance, profile_shift=-profile_shift)
          : _adendum(circ_pitch=circ_pitch, profile_shift=profile_shift, shorten=shorten)
    );



// Function: root_radius()
// Synopsis: Returns the radius of the roots of the teeth
// Topics: Gears, Parts
// See Also: spur_gear(), diametral_pitch(), circular_pitch(), module_value(), pitch_radius(), outer_radius()
// Usage: As a Function
//   rr = root_radius(mod=|circ_pitch=|diam_pitch=, teeth, [helical], [profile_shift=], [pressure_angle=], [clearance=], [backlash=], [internal=]);
// Description:
//   Calculates the actual radius of the roots of the teeth.  The root radius is usually given as a straight forward calcluation, but
//   when large pressure-angle teeth are clipped, it is more difficult to determine this radius.  This function calculates the actual
//   root radius so that you can, for example, place a partial tooth gear onto a matching circle.   The `backlash` parameter may seem
//   unnecessary, but when large pressure angle teeth are clipped, the value of backlash changes the clipping radius.  For regular
//   gear teeth, `backlash` has no effect on the radius.    
// Arguments:
//   teeth = The number of teeth on the gear.
//   helical = The helical angle (from vertical) of the teeth on the gear.  Default: 0
//   ---
//   mod = The module of the gear (pitch diameter / teeth)
//   circ_pitch = The circular pitch, the distance between teeth centers around the pitch circle.
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  The diametral pitch is a completely different thing than the pitch diameter.
//   profile_shift = Profile shift factor x.  Default: "auto"
//   pressure_angle = Pressure angle.  Default: 20
//   clearance = If given, sets the clearance between meshing teeth.  Default: module/4
//   backlash = Tooth-thinning backlash of the gear whose root is measured; use the same value as in the gear constructor. Default: 0 
//   internal = If true, calculate for an internal gear.
// Example(2D,NoAxes): A partial gear with its circle added to complete it.  
//   teeth=5;
//   mod=5;
//   rr = root_radius(mod=mod, teeth=teeth);
//   spur_gear2d(mod=mod, teeth=teeth, hide=floor(teeth/2));
//   circle(r=rr, $fn=64);

function root_radius(
    teeth, helical, _named, mod, circ_pitch, diam_pitch, profile_shift, pressure_angle, clearance,
    backlash, internal
) =
    assert(is_undef(_named), "root_radius(): arguments after teeth, helical must be named")

    let(helical=default(helical,0),
        internal=default(internal,false),
        profile_shift=default(profile_shift,"auto"),
        pressure_angle=default(pressure_angle,20),
        backlash=default(backlash,0))

  let(
      profile_shift = auto_profile_shift(teeth=teeth, pressure_angle=pressure_angle, helical=helical, profile_shift=profile_shift),
      tooth = _gear_tooth_profile(teeth=teeth, pressure_angle=pressure_angle, clearance=clearance, backlash=backlash, helical=helical,
                                  internal=internal, profile_shift=profile_shift, mod=mod, diam_pitch=diam_pitch, circ_pitch=circ_pitch),
      miny = norm(tooth[0])
  )
  miny;
      


/// Function: _root_radius_basic()
/// Usage: As a Function
///   value = _root_radius_basic(mod=|circ_pitch=|diam_pitch=, teeth, [clearance=], [internal=], [helical=], [profile_shift=]);
/// Topics: Gears
/// Description:
///   Calculates the root radius for the gear, at the base of the dedendum.  Does not apply auto profile shifting. 
/// Arguments:
///   teeth = The number of teeth on the gear.
///   ---
///   circ_pitch = The circular pitch, the distance between teeth centers around the pitch circle.
///   clearance = If given, sets the clearance between meshing teeth.  Default: module/4
///   internal = If true, calculate for an internal gear.
///   helical = The helical angle (from vertical) of the teeth on the gear.  Default: 0
///   profile_shift = Profile shift factor x.  Default:0
///   mod = The module of the gear (pitch diameter / teeth)
///   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  The diametral pitch is a completely different thing than the pitch diameter.
/// Example:
///   rr = _root_radius_basic(circ_pitch=5, teeth=11);
///   rr = _root_radius_basic(circ_pitch=5, teeth=16, helical=30);
///   rr = _root_radius_basic(diam_pitch=10, teeth=11);
///   rr = _root_radius_basic(mod=2, teeth=16);
/// Example(2D):
///   pr = _root_radius_basic(circ_pitch=5, teeth=11);
///   #spur_gear2d(circ_pitch=5, teeth=11);
///   color("black")
///       stroke(circle(r=pr),width=0.1,closed=true);

function _root_radius_basic(
    teeth, _named, circ_pitch, clearance, internal=false, helical=0, profile_shift=0, mod, diam_pitch
) =
    assert(is_undef(_named), "_root_radius_basic(): arguments after teeth must be named")

    let( circ_pitch = circular_pitch(circ_pitch=circ_pitch, mod=mod, diam_pitch=diam_pitch) )
    pitch_radius(circ_pitch=circ_pitch, teeth=teeth, helical=helical) - (
        internal
          ? _adendum(circ_pitch=circ_pitch, profile_shift=-profile_shift)
          : _dedendum(circ_pitch=circ_pitch, clearance=clearance, profile_shift=profile_shift)
    );


/// Function: _base_radius()
/// Usage: As a Function
///   value = _base_radius(mod=|circ_pitch=|diam_pitch=, teeth, [pressure_angle], [helical]);
/// Topics: Gears
/// Description:
///   Get the base circle for involute teeth, at the base of the teeth.
/// Arguments:
///   teeth = The number of teeth on the gear.
///   pressure_angle = Pressure angle in degrees.  Controls how straight or bulged the tooth sides are.
///   helical = The helical angle (from vertical) of the teeth on the gear.  Default: 0
///   ---
///   mod = The module of the gear (pitch diameter / teeth)
///   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  The diametral pitch is a completely different thing than the pitch diameter.
///   circ_pitch = The circular pitch, the distance between teeth centers around the pitch circle.
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

function _base_radius(
    teeth, pressure_angle=20, helical=0, _named, mod, diam_pitch, circ_pitch
) =
    assert(is_undef(_named), "_base_radius(): arguments after teeth, pressure_angle, helical must be named")

    let(
        circ_pitch = circular_pitch(circ_pitch=circ_pitch, mod=mod, diam_pitch=diam_pitch),
        trans_pa = atan(tan(pressure_angle)/cos(helical))
    )
    pitch_radius(circ_pitch=circ_pitch, teeth=teeth, helical=helical) * cos(trans_pa);


// Function: bevel_pitch_angle()
// Synopsis: Returns the pitch cone angle for a bevel gear.
// Topics: Gears, Parts
// See Also: bevel_gear(), pitch_radius(), outer_radius()
// Usage: As a Function
//   ang = bevel_pitch_angle(teeth, mate_teeth, [drive_angle]);
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
//       circ_pitch=5, teeth=t1, mate_teeth=t2,
//       spiral=0, cutter_radius=1000,
//       slices=12, anchor="apex", orient=BACK
//   );

function bevel_pitch_angle(
    teeth, mate_teeth, drive_angle, _named
) =
    assert(is_undef(_named), "bevel_pitch_angle(): arguments after teeth, mate_teeth, drive_angle must be named")

    let(drive_angle=default(drive_angle,90))

    atan(sin(drive_angle)/((mate_teeth/teeth)+cos(drive_angle)));


// Function: worm_gear_dist()
// Synopsis: Returns the assembly center distance for a cylindrical worm wheel.
// Topics: Gears, Parts
// See Also: worm(), worm_gear(), worm_gear_thickness(), worm_dist()
// Usage: As a Function
//   a = worm_gear_dist(mod=|circ_pitch=|diam_pitch=, teeth, worm_diam, [worm_starts], [profile_shift], [pressure_angle], [backlash=]);
// Description:
//   Returns worm_diam/2 + module*teeth/(2*cos(beta)) + module*profile_shift,
//   where beta=asin(module*worm_starts/worm_diam). Automatic profile shift and
//   pitch/pressure-angle inheritance are resolved exactly as in worm_gear().
//   Positive backlash INCREASES the assembly distance instead of thinning teeth.
//   It adds backlash*cos(beta)/tan(pressure_angle), the center-plane relation
//   for total wheel pitch-circle backlash 2*backlash. No existing tooth-thinning
//   value is needed. Use this OR tooth thinning for the same requested play.
//   Across a wide worm wheel, this does not guarantee uniform clearance or the
//   original full-width contact pattern at the increased assembly distance.
// Arguments:
//   teeth = Number of wheel teeth.
//   worm_diam = Worm pitch diameter.
//   worm_starts = Number of worm starts. Default: 1
//   profile_shift = Wheel profile-shift coefficient. Default: "auto"
//   pressure_angle = Normal pressure angle. Default: 20
//   ---
//   mod = Normal module.
//   circ_pitch = Normal circular pitch. Default: 5
//   diam_pitch = Normal diametral pitch, teeth per inch.
//   backlash = Increase spacing for total nominal wheel backlash 2*backlash. Default: 0

// Assembly center distance for a cylindrical worm-wheel pair. With backlash=0
// this is exactly the nominal GENERATING distance. Positive backlash moves the
// axes apart instead of thinning either part. As in BOSL2's other dist helpers,
// the argument targets TOTAL wheel pitch-circle backlash 2*backlash, using the
// center-plane straight-flank relation. No tooth-thinning value is an input.
// Do not also thin the teeth for the same requested play. The spacing relation
// is not a guarantee of uniform clearance/contact across a wide worm wheel.
function worm_gear_dist(
    // BEGIN GEAR_API_COMPAT
    _p0="__gear_legacy_omitted__", _p1="__gear_legacy_omitted__", _p2="__gear_legacy_omitted__",
    _p3="__gear_legacy_omitted__", _p4="__gear_legacy_omitted__", _p5="__gear_legacy_omitted__",
    _extra="__gear_legacy_omitted__",
    // END GEAR_API_COMPAT
    teeth, worm_diam, worm_starts, profile_shift, pressure_angle, _named, mod, circ_pitch, diam_pitch,
    backlash
) =
    // BEGIN GEAR_API_COMPAT
    let(_gear_args=_gear_legacy_args(
        "worm_gear_dist()", [_p0,_p1,_p2,_p3,_p4,_p5], _extra,
        ["circ_pitch", "teeth", "worm_diam", "worm_starts", "profile_shift", "pressure_angle"], ["teeth", "worm_diam", "worm_starts", "profile_shift", "pressure_angle"],
        [teeth,worm_diam,worm_starts,profile_shift,pressure_angle], circ_pitch, mod, diam_pitch))
    let(circ_pitch=_gear_args[0], teeth=_gear_args[1], worm_diam=_gear_args[2], worm_starts=_gear_args[3], profile_shift=_gear_args[4], pressure_angle=_gear_args[5])
    // END GEAR_API_COMPAT

    assert(is_undef(_named), "worm_gear_dist(): arguments after teeth, worm_diam, worm_starts, profile_shift, pressure_angle must be named")

    let(
        worm_starts=is_undef(worm_starts)?1:worm_starts,
        profile_shift=is_undef(profile_shift)?"auto":profile_shift,
        backlash=is_undef(backlash)?0:backlash
    )

    let(
        cp = _inherit_gear_pitch(fname="worm_gear_dist()",circ_pitch=circ_pitch,diam_pitch=diam_pitch,mod=mod),
        pa = _inherit_gear_pa(pressure_angle=pressure_angle),
        ps = auto_profile_shift(teeth=teeth,pressure_angle=pa,profile_shift=profile_shift),
        ref = _wormgear_reference(m=cp/PI,teeth=teeth,d=worm_diam,starts=worm_starts,pa=pa,ps=ps)
    ) _wormgear_spacing(ref=ref,backlash=backlash);

// Function: worm_dist()
// Synopsis: Returns worm center distance with optional spacing backlash.
// Topics: Gears, Parts
// See Also: worm_gear_dist(), worm_gear()
// Usage: As a Function
//   a = worm_dist(mod=|circ_pitch=|diam_pitch=, d, starts, teeth, [profile_shift], [pressure_angle=], [backlash=]);
// Description:
//   Alternate spelling for worm_gear_dist(), with d/starts/teeth positional order.
//   Size, pressure angle, and profile shift resolve exactly as in worm_gear_dist().
//   Omitted or undef profile_shift selects "auto"; pass 0 to disable shifting.
//   Backlash increases spacing for total nominal wheel backlash 2*backlash;
//   it does not describe or query thinning already applied to the teeth.
//   With profile_shift=0, zero-backlash distance is finite at pressure_angle=0; positive
//   spacing backlash at that angle raises an assertion.
// Arguments:
//   d = Worm pitch diameter.
//   starts = Number of starts.
//   teeth = Number of wheel teeth.
//   profile_shift = Wheel profile shift. Default: "auto"
//   ---
//   mod = Normal module.
//   circ_pitch = Normal circular pitch.
//   diam_pitch = Normal diametral pitch.
//   pressure_angle = Normal pressure angle. Default: 20
//   backlash = Increase spacing for total nominal wheel backlash 2*backlash. Default: 0
// Alternate name with matching automatic profile-shift and inheritance defaults.
// Positive backlash keeps the ORIGINAL distance-based meaning and factor of 2.
function worm_dist(
    d, starts, teeth, profile_shift, _named, mod, circ_pitch, diam_pitch, pressure_angle, backlash
) =
    assert(is_undef(_named), "worm_dist(): arguments after d, starts, teeth, profile_shift must be named")

    let(backlash=default(backlash,0))

    worm_gear_dist(teeth=teeth,worm_diam=d,worm_starts=starts,
                   profile_shift=profile_shift,mod=mod,circ_pitch=circ_pitch,
                   diam_pitch=diam_pitch,pressure_angle=pressure_angle,backlash=backlash);

function _wormgear_spacing(ref,backlash) =
    assert(_wormgear_finite(x=backlash) && backlash>=0,
           "worm distance: backlash must be finite and nonnegative")
    // Avoid 0/0 at zero pressure angle when no spacing backlash was requested.
    backlash==0 ? ref[1] :
    assert(ref[3]>0,
           "worm distance: positive distance backlash requires pressure_angle > 0")
    ref[1]+backlash/ref[3];

// Function: worm_gear_thickness()
// Synopsis: Returns the exact axial thickness selected for a worm wheel.
// Topics: Gears, Parts
// See Also: worm_gear(), worm_gear_dist()
// Usage: As a Function
//   h = worm_gear_thickness(mod=|circ_pitch=|diam_pitch=, teeth, worm_diam, [worm_arc], [pressure_angle], [crowning], [clearance], [worm_starts=], [profile_shift=], [thickness=]);
// Description:
//   Resolves thickness or worm_arc in exactly the same way as worm_gear().
//   The result is independent of crowning and min_tip. This is a dimension
//   query, not a check that teeth can satisfy a requested min_tip.
// Arguments:
//   teeth = Number of wheel teeth (used to resolve automatic profile shift).
//   worm_diam = Worm pitch diameter.
//   worm_arc = Width angle; mutually exclusive with thickness. Default: 45 when neither is given.
//   pressure_angle = Normal pressure angle. Default: 20
//   crowning = Retained for compatibility; does not affect thickness. Default: 0.1
//   clearance = Extra cutter-tip height. Default: module/4
//   ---
//   mod = Normal module.
//   circ_pitch = Normal circular pitch. Default: 5
//   diam_pitch = Normal diametral pitch, teeth per inch.
//   worm_starts = Number of starts. Default: 1
//   profile_shift = Wheel profile-shift coefficient. Default: "auto"
//   thickness = Explicit axial thickness.
// The helper uses the documented positional dimensions and named size measures. This is a
// dimension query, not a min_tip/contact/strength feasibility check.
function worm_gear_thickness(
    // BEGIN GEAR_API_COMPAT
    _p0="__gear_legacy_omitted__", _p1="__gear_legacy_omitted__", _p2="__gear_legacy_omitted__",
    _p3="__gear_legacy_omitted__", _p4="__gear_legacy_omitted__", _p5="__gear_legacy_omitted__",
    _extra="__gear_legacy_omitted__",
    // END GEAR_API_COMPAT
    teeth, worm_diam, worm_arc, pressure_angle, crowning, clearance, _named, mod, circ_pitch,
    diam_pitch, worm_starts, profile_shift, thickness
) =
    // BEGIN GEAR_API_COMPAT
    let(_gear_args=_gear_legacy_args(
        "worm_gear_thickness()", [_p0,_p1,_p2,_p3,_p4,_p5], _extra,
        ["circ_pitch", "teeth", "worm_diam"], ["teeth", "worm_diam", "worm_arc", "pressure_angle", "crowning", "clearance"],
        [teeth,worm_diam,worm_arc,pressure_angle,crowning,clearance], circ_pitch, mod, diam_pitch))
    let(circ_pitch=_gear_args[0], teeth=_gear_args[1], worm_diam=_gear_args[2], worm_arc=_gear_args[3], pressure_angle=_gear_args[4], crowning=_gear_args[5], clearance=_gear_args[6])
    // END GEAR_API_COMPAT

    assert(is_undef(_named), "worm_gear_thickness(): arguments after teeth, worm_diam, worm_arc, pressure_angle, crowning, clearance must be named")

    let(
        crowning=is_undef(crowning)?0.1:crowning, worm_starts=is_undef(worm_starts)?1:worm_starts,
        profile_shift=is_undef(profile_shift)?"auto":profile_shift
    )

    let(
        cp = _inherit_gear_pitch(fname="worm_gear_thickness()",circ_pitch=circ_pitch,diam_pitch=diam_pitch,mod=mod),
        pa = _inherit_gear_pa(pressure_angle=pressure_angle),
        ps = auto_profile_shift(teeth=teeth,pressure_angle=pa,profile_shift=profile_shift),
        m = cp/PI,
        c = is_undef(clearance) ? m/4 : clearance,
        ref = _wormgear_reference(m=m,teeth=teeth,d=worm_diam,starts=worm_starts,pa=pa,ps=ps)
    )
    assert(is_finite(crowning) && crowning>=0, "worm_gear_thickness(): invalid crowning")
    assert(ref[1]>worm_diam/2+m+c, "worm_gear_thickness(): cutter reaches wheel axis")
    2*_wormgear_halfwidth(m=m,d=worm_diam,ps=ps,clear=c,arc=worm_arc,thickness=thickness);


// Function: gear_dist()
// Synopsis: Returns the distance between two gear centers for spur gears or parallel axis helical gears.
// Topics: Gears, Parts
// See Also: worm(), worm_gear(), pitch_radius(), outer_radius()
// Usage: As a Function
//   a = gear_dist(mod=|circ_pitch=|diam_pitch=, teeth1, teeth2, [helical], [profile_shift1], [profile_shift2], [internal1=], [internal2=], [pressure_angle=], [backlash=]);
// Description:
//   Calculate the distance between the centers of two spur gears gears or helical gears with parallel axes,
//   taking into account profile shifting and helical angle.  You can give the helical angle as either positive or negative.  
//   If you set one of the tooth counts to zero than that gear will be treated as a rack and the distance returned is the
//   distance between the rack's pitch line and the gear's center.  If you set internal1 or internal2 to true then the
//   specified gear is a ring gear;  the returned distance is still the distance between the centers of the gears.  
//   For a regular gear and ring gear to be compatible the ring gear must have more teeth and at least as much profile shift
//   as the regular gear.
//   .
//   The backlash parameter computes the distance offset that produces a total backlash of `2*backlash` in the
//   two gear mesh system.  This is equivalent to giving the same backlash argument to both gears.  
// Arguments:
//   teeth1 = Total number of teeth in the first gear.  If given 0, we assume this is a rack or worm.
//   teeth2 = Total number of teeth in the second gear.  If given 0, we assume this is a rack or worm.
//   helical = The value of the helical angle (from vertical) of the teeth on the two gears (either sign).  Default: 0
//   profile_shift1 = Profile shift factor x for the first gear.  Default: "auto"
//   profile_shift2 = Profile shift factor x for the second gear.  Default: "auto"
//   ---
//   mod = The module of the gear (pitch diameter / teeth)
//   circ_pitch = The circular pitch, the distance between teeth centers around the pitch circle.
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  The diametral pitch is a completely different thing than the pitch diameter.
//   internal1 = first gear is an internal (ring) gear.  Default: false
//   internal2 = second gear is an internal (ring) gear.  Default: false
//   pressure_angle = The pressure angle of the gear.
//   backlash = Add extra space to produce a total of 2*backlash between the two gears. 
// Example(2D,NoAxes): Spur gears (with automatic profile shifting on both)
//   circ_pitch=5; teeth1=7; teeth2=24;
//   d = gear_dist(circ_pitch=circ_pitch, teeth1=teeth1, teeth2=teeth2);
//   spur_gear2d(circ_pitch=circ_pitch, teeth=teeth1, gear_spin=-90);
//   right(d) spur_gear2d(circ_pitch=circ_pitch, teeth=teeth2, gear_spin=90-180/teeth2);
// Example(3D,NoAxes,Med,VPT=[23.9049,5.42594,-4.68026],VPR=[64.8,0,353.5],VPD=140): Helical gears (with auto profile shifting on one of the gears)
//   circ_pitch=5; teeth1=7; teeth2=24; helical=37;
//   d = gear_dist(circ_pitch=circ_pitch, teeth1=teeth1, teeth2=teeth2, helical=helical);
//   spur_gear(circ_pitch=circ_pitch, teeth=teeth1, helical=helical, gear_spin=-90,slices=15);
//   right(d) spur_gear(circ_pitch=circ_pitch, teeth=teeth2, helical=-helical, gear_spin=-90-180/teeth2,slices=9);
// Example(2D,NoAxes): Disable Auto Profile Shifting on the smaller gear
//   circ_pitch=5; teeth1=7; teeth2=24;
//   d = gear_dist(circ_pitch=circ_pitch, teeth1=teeth1, teeth2=teeth2, profile_shift1=0);
//   spur_gear2d(circ_pitch=circ_pitch, teeth=teeth1, profile_shift=0, gear_spin=-90);
//   right(d) spur_gear2d(circ_pitch=circ_pitch, teeth=teeth2, gear_spin=90-180/teeth2);
// Example(2D,NoAxes): Manual Profile Shifting
//   circ_pitch=5; teeth1=7; teeth2=24; ps1 = 0.5; ps2 = -0.2;
//   d = gear_dist(circ_pitch=circ_pitch, teeth1=teeth1, teeth2=teeth2, profile_shift1=ps1, profile_shift2=ps2);
//   spur_gear2d(circ_pitch=circ_pitch, teeth=teeth1, profile_shift=ps1, gear_spin=-90);
//   right(d) spur_gear2d(circ_pitch=circ_pitch, teeth=teeth2, profile_shift=ps2, gear_spin=90-180/teeth2);
// Example(2D,NoAxes): Profile shifted gear and a rack
//   mod=3; teeth=8;
//   d = gear_dist(mod=mod, teeth1=teeth, teeth2=0);
//   rack2d(mod=mod, teeth=5, bottom=9);
//   back(d) spur_gear2d(mod=mod, teeth=teeth, gear_spin=180/teeth);
// Example(3D,Med,NoAxes,VPT=[-0.0608489,1.3772,-3.68839],VPR=[63.4,0,29.7],VPD=113.336): Profile shifted helical gear and rack 
//   mod=3; teeth=8; helical=29;
//   d = gear_dist(mod=mod, teeth1=teeth, teeth2=0, helical=helical);
//   rack(mod=mod, teeth=5, helical=helical, orient=FWD);
//   color("lightblue")
//     fwd(d) spur_gear(mod=mod, teeth=teeth, helical=-helical, gear_spin=180/teeth);
function gear_dist(
    teeth1, teeth2, helical, profile_shift1, profile_shift2, _named, mod, circ_pitch, diam_pitch,
    internal1, internal2, pressure_angle, backlash
) =
    assert(is_undef(_named), "gear_dist(): arguments after teeth1, teeth2, helical, profile_shift1, profile_shift2 must be named")

    let(helical=default(helical,0),
        internal1=default(internal1,false),
        internal2=default(internal2,false),
        backlash=default(backlash,0),
        pressure_angle=default(pressure_angle,20))

    assert(all_nonnegative([teeth1,teeth2]),"Must give nonnegative values for teeth")
    assert(teeth1>0 || teeth2>0, "One of the teeth counts must be nonzero")
    assert(is_bool(internal1))
    assert(is_bool(internal2))
    assert(is_finite(helical))
    assert(!(internal1&&internal2), "Cannot specify both gears as internal")
    assert(!(internal1 || internal2) || (teeth1>0 && teeth2>0), "Cannot specify internal gear with rack (zero tooth count)")
    let(
        mod = module_value(mod=mod,circ_pitch=circ_pitch,diam_pitch=diam_pitch),
        spacing_backlash = _gear_spacing_backlash(backlash,pressure_angle,helical),
        profile_shift1 = auto_profile_shift(teeth=teeth1,pressure_angle=pressure_angle,helical=helical,profile_shift=profile_shift1),
        profile_shift2 = auto_profile_shift(teeth=teeth2,pressure_angle=pressure_angle,helical=helical,profile_shift=profile_shift2),
        teeth1 = internal2? -teeth1 : teeth1,
        teeth2 = internal1? -teeth2 : teeth2
    )
    assert(teeth1+teeth2>0, "Internal gear must have more teeth than the mated external gear")
    let(
        profile_shift1 = internal2? -profile_shift1 : profile_shift1,
        profile_shift2 = internal1? -profile_shift2 : profile_shift2
    )
    assert(!(internal1||internal2) || profile_shift1+profile_shift2>=0, "Internal gear must have profile shift equal or greater than mated external gear")
    teeth1==0 || teeth2==0? pitch_radius(mod=mod, teeth=teeth1+teeth2, helical=helical) + (profile_shift1+profile_shift2)*mod + spacing_backlash
    :
    let(
        pa_eff = _working_pressure_angle(teeth1=teeth1,profile_shift1=profile_shift1,teeth2=teeth2,profile_shift2=profile_shift2,pressure_angle=pressure_angle,helical=helical),
        pa_transv = atan(tan(pressure_angle)/cos(helical))
    )
    mod*(teeth1+teeth2)*cos(pa_transv)/cos(pa_eff)/cos(helical)/2
        + (internal1||internal2?-1:1) * spacing_backlash;


// Straight-flank reference relation: total transverse play is 2*backlash.
// A zero tooth count denotes a rack; measure its pair's play at the pinion pitch circle.
function _gear_spacing_backlash(backlash,pressure_angle,helical) =
    assert(is_finite(backlash) && backlash>=0, "backlash must be finite and nonnegative")
    assert(is_finite(pressure_angle) && pressure_angle>=0 && pressure_angle<90,
           "pressure_angle must be in [0,90)")
    assert(is_finite(helical) && abs(helical)<90, "abs(helical) must be < 90")
    backlash==0 ? 0 :
    assert(pressure_angle>0, "Positive spacing backlash requires pressure_angle > 0")
    backlash*cos(helical)/tan(pressure_angle);

function _invol(a) = tan(a) - a*PI/180;

function _working_pressure_angle(teeth1,profile_shift1, teeth2, profile_shift2, pressure_angle, helical) =
  let(
      pressure_angle = atan(tan(pressure_angle)/cos(helical))
  )
  teeth1==0 || teeth2==0 || profile_shift1+profile_shift2==0 ? pressure_angle
  :
  let(
      rhs = 2*(profile_shift1+profile_shift2)/(teeth1+teeth2)*cos(helical)*tan(pressure_angle) + _invol(a=pressure_angle)
  )
  assert(rhs>0, "Total profile shift is too small, so working pressure angle is negative, and no valid gear separation exists")
  let(
      pa_eff = root_find(function (x) _invol(a=x)-rhs, 1, 75)
  )
  pa_eff;



// Function: gear_dist_skew()
// Synopsis: Returns the distance between two helical gear centers with skew axes.  
// Topics: Gears, Parts
// See Also: gear_dist(), worm(), worm_gear(), pitch_radius(), outer_radius()
// Usage: As a Function
//   a = gear_dist_skew(mod=|circ_pitch=|diam_pitch=, teeth1, teeth2, helical1, helical2, [profile_shift1], [profile_shift2], [pressure_angle=], [backlash=]);
// Description:
//   Calculate the distance between two helical gears that mesh with non-parallel axes, taking into account
//   profile shift and the helical angles.
//   For a rack pair (one zero tooth count), backlash is measured at the finite
//   pinion's pitch circle. The spacing increment is backlash*cos(pinion_helical)/tan(pressure_angle).
//   The nonzero/nonzero skew-pair backlash adjustment remains a reference approximation.
// Arguments:
//   teeth1 = Total number of teeth in the first gear.  If given 0, we assume this is a rack or worm.
//   teeth2 = Total number of teeth in the second gear.  If given 0, we assume this is a rack or worm.
//   helical1 = The helical angle (from vertical) of the teeth on the first gear. 
//   helical2 = The helical angle (from vertical) of the teeth on the second gear.
//   profile_shift1 = Profile shift factor x for the first gear.  Default: "auto"
//   profile_shift2 = Profile shift factor x for the second gear.  Default: "auto"
//   ---
//   mod = The module of the gear (pitch diameter / teeth)
//   circ_pitch = The circular pitch, the distance between teeth centers around the pitch circle.
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  The diametral pitch is a completely different thing than the pitch diameter.
//   pressure_angle = The pressure angle of the gear.
//   backlash = Add extra space to produce a total of 2*backlash between the two gears. 
// Example(3D,Med,NoAxes,VPT=[-0.302111,3.7924,-9.252],VPR=[55,0,25],VPD=155.556): Non-parallel Helical Gears (without any profile shifting)
//   circ_pitch=5; teeth1=15; teeth2=24; ha1=45; ha2=30; thick=10;
//   d = gear_dist_skew(circ_pitch=circ_pitch, teeth1=teeth1, teeth2=teeth2, helical1=ha1, helical2=ha2);
//   left(d/2) spur_gear(circ_pitch=circ_pitch, teeth=teeth1, helical=ha1, thickness=thick, gear_spin=-90);
//   right(d/2) xrot(ha1+ha2) spur_gear(circ_pitch=circ_pitch, teeth=teeth2, helical=ha2, thickness=thick, gear_spin=90-180/teeth2);
function gear_dist_skew(
    teeth1, teeth2, helical1, helical2, profile_shift1, profile_shift2, _named, mod, circ_pitch,
    diam_pitch, pressure_angle, backlash
) =
    assert(is_undef(_named), "gear_dist_skew(): arguments after teeth1, teeth2, helical1, helical2, profile_shift1, profile_shift2 must be named")

    let(pressure_angle=default(pressure_angle,20),
        backlash=default(backlash,0))

  assert(all_nonnegative([teeth1,teeth2]),"Must give nonnegative values for teeth")
  assert(teeth1>0 || teeth2>0, "One of the teeth counts must be nonzero")
  let(
      profile_shift1 = auto_profile_shift(teeth=teeth1,pressure_angle=pressure_angle,helical=helical1,profile_shift=profile_shift1),
      profile_shift2 = auto_profile_shift(teeth=teeth2,pressure_angle=pressure_angle,helical=helical2,profile_shift=profile_shift2),
      mod = module_value(circ_pitch=circ_pitch, diam_pitch=diam_pitch, mod=mod),
      spacing_backlash = _gear_spacing_backlash(backlash,pressure_angle,
          teeth1==0 ? helical2 : teeth2==0 ? helical1 : (helical1-helical2)/2)
  )
  teeth1==0 || teeth2==0? pitch_radius(mod=mod, teeth=teeth1+teeth2, helical=teeth1?helical1:helical2) + (profile_shift1+profile_shift2)*mod + spacing_backlash
  :
  let(
      pa_normal_eff = _working_normal_pressure_angle_skew(teeth1=teeth1,profile_shift1=profile_shift1,helical1=helical1,teeth2=teeth2,profile_shift2=profile_shift2,helical2=helical2,pressure_angle=pressure_angle),
      dist_adj = 0.5*(teeth1/cos(helical1)^3+teeth2/cos(helical2)^3)*(cos(pressure_angle)/cos(pa_normal_eff)-1)
  )
  mod*(teeth1/2/cos(helical1)+teeth2/2/cos(helical2)+dist_adj)
      // This expression is a guess based on finding the cross section where pressure angles match so that there is a single
      // pressure angle to reference the movement by. 
      + spacing_backlash;


function _working_normal_pressure_angle_skew(teeth1,profile_shift1,helical1, teeth2, profile_shift2, helical2, pressure_angle) = 
  let(
      inv = function(a) tan(a) + a*PI/180, 
      rhs = 2*(profile_shift1+profile_shift2)/(teeth1/cos(helical1)^3+teeth2/cos(helical2)^3)*tan(pressure_angle) + _invol(a=pressure_angle),
      pa_eff_normal = root_find(function (x) _invol(a=x)-rhs, 5, 75)
  )
  pa_eff_normal;


// Function: gear_skew_angle()
// Usage: As a Function
//   ang = gear_skew_angle(teeth1, teeth2, helical1, helical2, [profile_shift1], [profile_shift2], [pressure_angle=]);
// Synopsis: Returns corrected skew angle between two profile shifted helical gears.  
// Description:
//   Compute the correct skew angle between the axes of two profile shifted helical gears.  When profile shifting is zero, or when one of
//   the gears is a rack, this angle is simply the sum of the helical angles of the two gears.  But with profile shifted gears, a small
//   correction to the skew angle is needed for proper meshing.  
// Arguments:
//   teeth1 = Total number of teeth in the first gear.  If given 0, we assume this is a rack or worm.
//   teeth2 = Total number of teeth in the second gear.  If given 0, we assume this is a rack or worm.
//   helical1 = The helical angle (from vertical) of the teeth on the first gear. 
//   helical2 = The helical angle (from vertical) of the teeth on the second gear.
//   profile_shift1 = Profile shift factor x for the first gear.  Default: "auto"
//   profile_shift2 = Profile shift factor x for the second gear.  Default: "auto"
//   ---
//   pressure_angle = The pressure angle of the gear.
// Example(3D,Med,NoAxes,VPT=[-2.62091,2.01048,-1.31405],VPR=[55,0,25],VPD=74.4017): These gears are auto profile shifted and as a result, do not mesh at the sum of their helical angles, but at 2.5 degrees more.  
//   circ_pitch=5; teeth1=12; teeth2=7; ha1=25; ha2=30; thick=10;
//   d = gear_dist_skew(circ_pitch=circ_pitch, teeth1=teeth1, teeth2=teeth2, helical1=ha1, helical2=ha2);
//   ang = gear_skew_angle(teeth1=teeth1, teeth2=teeth2, helical1=ha1, helical2=ha2);  // Returns 57.7
//   left(d/2)
//     spur_gear(circ_pitch=circ_pitch, teeth=teeth1, helical=ha1, thickness=thick, gear_spin=-90);
//   right(d/2) color("lightblue")
//     xrot(ang) spur_gear(circ_pitch=circ_pitch, teeth=teeth2, helical=ha2, thickness=thick, gear_spin=90-180/teeth2);

function gear_skew_angle(
    teeth1, teeth2, helical1, helical2, profile_shift1, profile_shift2, _named, pressure_angle
) =
    assert(is_undef(_named), "gear_skew_angle(): arguments after teeth1, teeth2, helical1, helical2, profile_shift1, profile_shift2 must be named")

    let(pressure_angle=default(pressure_angle,20))

   assert(all_nonnegative([teeth1,teeth2]),"Must give nonnegative values for teeth")
   assert(teeth1>0 || teeth2>0, "One of the teeth counts must be nonzero")
   let(
       mod = 1,  // This is independent of module size
       profile_shift1 = auto_profile_shift(teeth=teeth1,pressure_angle=pressure_angle,helical=helical1,profile_shift=profile_shift1),
       profile_shift2 = auto_profile_shift(teeth=teeth2,pressure_angle=pressure_angle,helical=helical2,profile_shift=profile_shift2)
   )
   profile_shift1==0 && profile_shift2==0 ? helical1+helical2
 : teeth1==0 || teeth2==0 ? helical1+helical2
 : let(
        a = gear_dist_skew(mod=mod,teeth1=teeth1,teeth2=teeth2,helical1=helical1,helical2=helical2,profile_shift1=profile_shift1,profile_shift2=profile_shift2,pressure_angle=pressure_angle),
        b = gear_dist_skew(mod=mod,teeth1=teeth1,teeth2=teeth2,helical1=helical1,helical2=helical2,profile_shift1=0,profile_shift2=0,pressure_angle=pressure_angle),
        d1 = 2*pitch_radius(mod=mod,teeth=teeth1,helical=helical1),
        d2 = 2*pitch_radius(mod=mod,teeth=teeth2,helical=helical2),
        dw1 = 2*a*d1/(d1+d2),
        dw2 = 2*a*d2/(d1+d2),
        beta1 = atan(dw1/d1*tan(helical1)),
        beta2 = atan(dw2/d2*tan(helical2))
   )
   beta1+beta2;


// Function: get_profile_shift()
// Usage: As a Function
//   shift = get_profile_shift(mod=|circ_pitch=|diam_pitch=, desired, teeth1, teeth2, [helical], [internal1=], [internal2=], [pressure_angle=]);
// Synopsis: Returns total profile shift needed to achieve a desired spacing between two gears
// Description:
//   Compute the total profile shift, split between two gears, needed to place those gears with a specified separation.
//   If the requested separation is too small, returns NaN.  The profile shift returned may also be impractically
//   large or small and does not necessarily lead to a valid gear configuration.  You will need to split the profile shift
//   between the two gears.  Note that for helical gears, much more adjustment is available by modifying the helical angle.
//   . 
//   For a ring gear you can specify internal teeth.  The computed profile shift must equal the **difference** of the ring gear
//   profile shift and its mated spur gear profile shift.  You can only increase the spacing using profile shifting, because
//   decreasing spacing would require that the profile shift of the ring gear is smaller than that of the spur gear, and
//   that is not a valid configuration.  
// Arguments:
//   desired = desired gear center separation
//   teeth1 = number of teeth on first gear
//   teeth2 = number of teeth on second gear
//   helical = The helical angle (from vertical) of the teeth on the gear.  Default: 0
//   ---
//   mod = The module of the gear (pitch diameter / teeth)
//   circ_pitch = The circular pitch, the distance between teeth centers around the pitch circle.
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  The diametral pitch is a completely different thing than the pitch diameter.
//   internal1 = first gear is a ring gear with internal teeth.  Default: false
//   internal2 = second gear is a ring gear with internal teeth.  Default: false
//   pressure_angle = normal pressure angle of gear teeth.  Default: 20
// Example(2D,Med,NoAxes,VPT=[37.0558,0.626722,9.78411],VPR=[0,0,0],VPD=496): For a pair of module 4 gears with 19, and 37 teeth, the separation without profile shifting is 112.  Suppose we want it instead to be 115.  A positive profile shift, split evenly between the gears, achieves the goal, as shown by the red rectangle, with width 115.  
//   teeth1=37;
//   teeth2=19;
//   mod=4;
//   desired=115;
//   pshift = get_profile_shift(desired=desired,teeth1=teeth1,teeth2=teeth2,mod=mod);  // Returns 0.82
//   ps1 = pshift/2;
//   ps2 = pshift/2;
//   shorten=gear_shorten(teeth1=teeth1,teeth2=teeth2,helical=0,profile_shift1=ps1,profile_shift2=ps2);       // Returns 0.07
//   d = gear_dist(mod=mod, teeth1=teeth1,teeth2=teeth2,helical=0,profile_shift1=ps1,profile_shift2=ps2);
//   spur_gear2d(mod=mod,teeth=teeth1,profile_shift=ps1,shorten=shorten,gear_spin=-90,shaft_diam=5);
//   right(d)
//     spur_gear2d(mod=mod,teeth=teeth2,profile_shift=ps2,shorten=shorten,gear_spin=-90,shaft_diam=5);
//   stroke([rect([desired,40], anchor=LEFT)],color="red");
// Example(2D,Med,NoAxes,VPT=[37.0558,0.626722,9.78411],VPR=[0,0,0],VPD=496): For the same pair of module 4 gears with 19, and 37 teeth, suppose we want a closer spacing of 110 instead of 112.  A negative profile shift does the job, as shown by the red rectangle with width 110.  More of the negative shift is assigned to the large gear, to avoid undercutting the smaller gear.  
//   teeth1=37;
//   teeth2=19;
//   mod=4;
//   desired=110;
//   pshift = get_profile_shift(desired=desired,teeth1=teeth1,teeth2=teeth2,mod=mod);  // Returns -0.46
//   ps1 = 0.8*pshift;
//   ps2 = 0.2*pshift;
//   shorten=gear_shorten(teeth1=teeth1,teeth2=teeth2,helical=0,profile_shift1=ps1,profile_shift2=ps2);  // Returns 0.04
//   d = gear_dist(mod=mod, teeth1=teeth1,teeth2=teeth2,helical=0,profile_shift1=ps1,profile_shift2=ps2);
//   spur_gear2d(mod=mod,teeth=teeth1,profile_shift=ps1,shorten=shorten,gear_spin=-90,shaft_diam=5);
//   right(d)
//     spur_gear2d(mod=mod,teeth=teeth2,profile_shift=ps2,shorten=shorten,gear_spin=-90,shaft_diam=5);
//   stroke([rect([desired,40], anchor=LEFT)],color="red");
// Example(2D,Med,NoScales,VPR=[0.00,0.00,0.00],VPD=245,VPT=[0.16,24.60,28.81]): The natural center distance between these gears is 32.  Using profile shifting we increase this to 34. With a ring gear and spur gear the **difference** in profile shifts must equal the computed value.  The only way to divide the profile shift is hence to place negative shift onto the spur gear, which is only acceptable for large tooth count spur gears.  It is not possible to use profile shifting to decrease the distance, because that would requires the ring gear profile shift to be less than the spur gear profile shift.  
//   teeth_ring = 57;
//   teeth_spur = 25;
//   mod = 2;
//   desired = 34;     
//   ps = get_profile_shift(desired=desired, teeth1=teeth_ring, internal1=true,  // Returns 1.2
//                                   teeth2=teeth_spur, mod=mod);
//   ps_spur = -0.4;       // The biggest negative profile shift that looks reasonable
//   ps_ring = ps+ps_spur; // Must have ps_ring - ps_spur = ps
//   d = gear_dist(mod=mod, teeth1=teeth_ring, internal1=true, profile_shift1=ps_ring,
//                          teeth2=teeth_spur, profile_shift2=ps_spur);
//   ring_gear2d(mod=mod, teeth=teeth_ring, profile_shift=ps_ring)
//   back(d)
//     spur_gear2d(mod=mod, teeth=teeth_spur, profile_shift=ps_spur, shaft_diam=3);
//   stroke([[0,0],[0,desired]], endcaps="arrow2", color="red");

function get_profile_shift(
    desired, teeth1, teeth2, helical, _named, mod, circ_pitch, diam_pitch, internal1, internal2,
    pressure_angle
) =
    assert(is_undef(_named), "get_profile_shift(): arguments after desired, teeth1, teeth2, helical must be named")

    let(helical=default(helical,0),
        pressure_angle=default(pressure_angle,20),
        internal1=default(internal1,false),
        internal2=default(internal2,false))

  assert(all_nonnegative([teeth1,teeth2]),"Must give nonnegative values for teeth")
  assert(teeth1>0 || teeth2>0, "One of the teeth counts must be nonzero")
  assert(is_bool(internal1))
  assert(is_bool(internal2))
  assert(is_finite(helical))
  assert(!(internal1&&internal2), "Cannot specify both gears as internal")
  assert(!(internal1 || internal2) || (teeth1>0 && teeth2>0), "Cannot specify internal gear with rack (zero tooth count)")
  let(
       teeth1 = internal2? -teeth1 : teeth1,
       teeth2 = internal1? -teeth2 : teeth2,
       mod = module_value(mod=mod, circ_pitch=circ_pitch, diam_pitch=diam_pitch),
       teethsum = teeth1+teeth2,
       pressure_angle_trans = atan(tan(pressure_angle)/cos(helical)),
       y = desired/mod - teethsum/2/cos(helical),
       thing=teethsum*cos(pressure_angle_trans) / (teethsum+2*y*cos(helical)),
       pa_eff = acos(teethsum*cos(pressure_angle_trans) / (teethsum+2*y*cos(helical)))
  )
  teethsum * (_invol(a=pa_eff)-_invol(a=pressure_angle_trans))/2/tan(pressure_angle);


// Function: auto_profile_shift()
// Synopsis: Returns the recommended profile shift for a gear.
// Topics: Gears, Parts
// See Also: worm(), worm_gear(), pitch_radius(), outer_radius()
// Usage: As a Function
//   x = auto_profile_shift(teeth, [pressure_angle], [helical], [min_teeth=], [get_min=], [profile_shift=]);
// Description:
//   Calculates the recommended profile shift to avoid gear tooth undercutting.  You can set `min_teeth` to a
//   value to allow small undercutting, and only activate the profile shift for more extreme cases.  Is is common
//   practice to make gears with 15-17 teeth with undercutting with the standard 20 deg pressure angle.
//   .
//   The `get_min` argument returns the minimum profile shift needed to avoid undercutting for the specified
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
function auto_profile_shift(
    teeth, pressure_angle, helical, _named, min_teeth, get_min, profile_shift
) =
    assert(is_undef(_named), "auto_profile_shift(): arguments after teeth, pressure_angle, helical must be named")

    let(pressure_angle=default(pressure_angle,20),
        helical=default(helical,0),
        get_min=default(get_min,false))

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
// Usage: As a Function
//   shorten = gear_shorten(teeth1, teeth2, [helical], [profile_shift1], [profile_shift2], [pressure_angle=]);
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
//   d = gear_dist(mod=mod, teeth1=teeth1,teeth2=teeth2,helical=0,profile_shift1=ps1,profile_shift2=ps2);
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
//   d = gear_dist(mod=mod, teeth1=teeth1,teeth2=teeth2,helical=0,profile_shift1=ps1,profile_shift2=ps2);
//   shorten=gear_shorten(teeth1=teeth1,teeth2=teeth2,helical=0,profile_shift1=ps1,profile_shift2=ps2);
//   color("lightblue")
//     spur_gear2d(mod=mod,teeth=teeth1,profile_shift=ps1,shorten=shorten,gear_spin=-90);
//   right(d)
//     spur_gear2d(mod=mod,teeth=teeth2,profile_shift=ps2,shorten=shorten,gear_spin=-90);
function gear_shorten(
    teeth1, teeth2, helical, profile_shift1, profile_shift2, _named, pressure_angle
) =
    assert(is_undef(_named), "gear_shorten(): arguments after teeth1, teeth2, helical, profile_shift1, profile_shift2 must be named")

    let(helical=default(helical,0),
        profile_shift1=default(profile_shift1,"auto"),
        profile_shift2=default(profile_shift2,"auto"),
        pressure_angle=default(pressure_angle,20))

    teeth1==0 || teeth2==0 ? 0
  : let(
         profile_shift1 = auto_profile_shift(teeth=teeth1,pressure_angle=pressure_angle,helical=helical,profile_shift=profile_shift1),
         profile_shift2 = auto_profile_shift(teeth=teeth2,pressure_angle=pressure_angle,helical=helical,profile_shift=profile_shift2),
         ax = gear_dist(mod=1,teeth1=teeth1,teeth2=teeth2,helical=helical,profile_shift1=profile_shift1,profile_shift2=profile_shift2,pressure_angle=pressure_angle),
         y = ax - (teeth1+teeth2)/2/cos(helical)
    )
    profile_shift1+profile_shift2-y;


// Function: gear_shorten_skew()
// Usage: As a Function
//   shorten = gear_shorten_skew(teeth1, teeth2, helical1, helical2, [profile_shift1], [profile_shift2], [pressure_angle=]);
// Synopsis: Returns the tip shortening parameter for profile shifted skew axis helical gears.
// Description:
//    Compute the gear tip shortening factor for skew axis helical gears that have profile shifts.  This factor depends on both
//    gears in a pair and when applied, will results in teeth that meet the specified clearance distance.
//    Generally if you don't apply it the teeth clearance will be decreased due to the profile shifting.
//    Because it operates pairwise, if a gear mates with more than one other gear, you may have to decide
//    which shortening factor to use. The factor is independent of tooth size and is zero for a rack pair.
// Arguments:
//   teeth1 = Total number of teeth in the first gear.  If given 0, we assume this is a rack or worm.
//   teeth2 = Total number of teeth in the second gear.  If given 0, we assume this is a rack or worm.
//   helical1 = The helical angle (from vertical) of the teeth on the first gear. 
//   helical2 = The helical angle (from vertical) of the teeth on the second gear.
//   profile_shift1 = Profile shift factor x for the first gear.  Default: "auto"
//   profile_shift2 = Profile shift factor x for the second gear.  Default: "auto"
//   ---
//   pressure_angle = The pressure angle of the gear.
function gear_shorten_skew(
    teeth1, teeth2, helical1, helical2, profile_shift1, profile_shift2, _named, pressure_angle
) =
    assert(is_undef(_named), "gear_shorten_skew(): arguments after teeth1, teeth2, helical1, helical2, profile_shift1, profile_shift2 must be named")

    let(profile_shift1=default(profile_shift1,"auto"),
        profile_shift2=default(profile_shift2,"auto"),
        pressure_angle=default(pressure_angle,20))

    teeth1==0 || teeth2==0 ? 0 :
    let(
         profile_shift1 = auto_profile_shift(teeth=teeth1,pressure_angle=pressure_angle,helical=helical1,profile_shift=profile_shift1),
         profile_shift2 = auto_profile_shift(teeth=teeth2,pressure_angle=pressure_angle,helical=helical2,profile_shift=profile_shift2),
         ax = gear_dist_skew(mod=1,teeth1=teeth1,teeth2=teeth2,helical1=helical1,helical2=helical2,profile_shift1=profile_shift1,profile_shift2=profile_shift2,pressure_angle=pressure_angle),
         y = ax - teeth1/2/cos(helical1) - teeth2/2/cos(helical2)
    )
    profile_shift1+profile_shift2-y;


module _show_gear_tooth_profile(
    circ_pitch,
    teeth,
    pressure_angle=20,
    profile_shift,
    helical=0,
    internal=false,
    clearance,
    backlash=0,
    show_verts=false,
    diam_pitch,
    mod
) {
    mod = module_value(circ_pitch=circ_pitch, diam_pitch=diam_pitch, mod=mod);
    profile_shift = default(profile_shift, auto_profile_shift(teeth=teeth, pressure_angle=pressure_angle, helical=helical));
    or = outer_radius(mod=mod, teeth=teeth, clearance=clearance, helical=helical, profile_shift=profile_shift, internal=internal);
    pr = pitch_radius(mod=mod, teeth=teeth, helical=helical);
    rr = _root_radius_basic(mod=mod, teeth=teeth, helical=helical, profile_shift=profile_shift, clearance=clearance, internal=internal);
    br = _base_radius(mod=mod, teeth=teeth, helical=helical, pressure_angle=pressure_angle);
    tang = 360/teeth;
    rang = tang * 1.075;
    tsize = (or-rr) / 20;
    clear = (1-profile_shift)*mod;
    tooth = _gear_tooth_profile(
        mod=mod, teeth=teeth,
        pressure_angle=pressure_angle,
        clearance=clearance,
        backlash=backlash,
        helical=helical,
        internal=internal,
        profile_shift=profile_shift
    );
    $fn=360;
    union() {
        color("cyan") { // Pitch circle
            stroke(arc(r=pr,start=90-rang/2,angle=rang), width=0.05);
            zrot(-tang/2*1.10) back(pr) text("pitch", size=tsize, halign="left", valign="center");
        }
        color("lightgreen") { // Outer and Root circles
            stroke(arc(r=or,start=90-rang/2,angle=rang), width=0.05);
            stroke(arc(r=rr,start=90-rang/2,angle=rang), width=0.05);
            zrot(-tang/2*1.10) back(or) text("tip", size=tsize, halign="left", valign="center");
            zrot(-tang/2*1.10) back(rr) text("root", size=tsize, halign="left", valign="center");
        }
        color("#fcf") { // Base circle
            stroke(arc(r=br,start=90-rang/2,angle=rang), width=0.05);
            zrot(tang/2*1.10) back(br) text("base", size=tsize, halign="right", valign="center");
        }
        color("#ddd") { // Clearance area
            if (internal) {
                dashed_stroke(arc(r=pr+clear, start=90-rang/2, angle=rang), width=0.05);
                back((pr+clear+or)/2) text("clearance", size=tsize, halign="center", valign="center");
            } else {
                dashed_stroke(arc(r=pr-clear, start=90-rang/2, angle=rang), width=0.05);
                back((pr-clear+rr)/2) text("clearance", size=tsize, halign="center", valign="center");
            }
        }
        color("#ddd") { // Tooth width markers
            stroke([polar_to_xy(min(rr,br)-mod/10,90-180/teeth),polar_to_xy(or+mod/10,90-180/teeth)], width=0.05, closed=true);
            stroke([polar_to_xy(min(rr,br)-mod/10,90+180/teeth),polar_to_xy(or+mod/10,90+180/teeth)], width=0.05, closed=true);
        }
        zrot_copies([0]) { // Tooth profile overlay
            stroke(tooth, width=0.1, dots=(show_verts?"dot":false), endcap_color1="green", endcap_color2="red");
        }
    }
}



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
