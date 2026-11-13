//////////////////////////////////////////////////////////////////////////////////////////////
// LibFile: gears.scad
//   Provides involute spur gears, ring gears, crown face gears, and racks, with the option to
//   create helical and herringbone forms.  Provides octoid bevel gears and enveloping and
//   globoid (double enveloping) worm drives; the globoid worm can be constructed with asymmetric
//   teeth for easier printing.
//   .
//   The {{attach_gear()}} module lets you assemble and then automatically drive
//   a meshing gear chain without having to manually fiddle with gear spacing or teeth alignment for
//   the proper mesh.
//   .
//   Originally inspired by code by Leemon Baird, 2011, Leemon@Leemon.com.
// 
// Includes:
//   include <BOSL2/std.scad>
//   include <BOSL2/gears.scad>
// FileGroup: Parts
// FileSummary: Gears, racks, worms, and worm gears.
//////////////////////////////////////////////////////////////////////////////////////////////
include <threading.scad>
// BEGIN GEAR_API_COMPAT
// Transitional positional circular pitch. Only documented positional prefixes are captured.
function _gear_legacy_missing(v) = v == "__gear_legacy_omitted__";
function _gear_legacy_index(name,names) =
    let(found=[for(i=[0:1:len(names)-1]) if(names[i]==name) i])
    len(found)==0 ? undef : found[0];
function _gear_legacy_merge(p,n,fname,name) =
    assert(is_undef(p) || is_undef(n), str("\n", fname, ": ",name," supplied positionally and by name"))
    is_undef(p) ? n : p;
function _gear_legacy_args(fname,slots,extra,old_names,new_names,named,circ_pitch,mod,diam_pitch) =
    let(
        explicit_size=num_defined([mod,circ_pitch,diam_pitch])>0,
        has_pos=!_gear_legacy_missing(slots[0]),
        legacy=has_pos && (len(new_names)==0 || is_undef(slots[0]) || !explicit_size),
        order=legacy?old_names:new_names,
        excess=[for(i=[0:1:len(slots)-1]) if(i>=len(order) && !_gear_legacy_missing(slots[i])) i]
    )
    assert(_gear_legacy_missing(extra) && len(excess)==0,
           str("\nToo many positional arguments (only ",len(order),
               len(order)==1?" is accepted) for ":" are accepted) for ",fname))
    let(cp=_gear_legacy_merge(legacy && !_gear_legacy_missing(slots[0]) ? slots[0] : undef,circ_pitch,fname,"circ_pitch"),
        names=new_names, values=named,
        dimensions=[for(i=[0:1:len(names)-1])
            let(k=_gear_legacy_index(names[i],order),
                v=is_undef(k)?undef:slots[k])
            _gear_legacy_merge(_gear_legacy_missing(v)?undef:v,values[i],fname,names[i])],
        result=[cp,each dimensions]
    )
    legacy ? echo(str("DEPRECATED: ",fname,
        len(new_names)==0 ? ": name the size measure: mod=, circ_pitch=, or diam_pitch=."
            : ": positional circular pitch; use a named size followed by dimensions, or name dimensions to inherit size.")) result : result;
// END GEAR_API_COMPAT
_BOSL2_GEARS = is_undef(_BOSL2_STD) && (is_undef(BOSL2_NO_STD_WARNING) || !BOSL2_NO_STD_WARNING) ?
       echo("Warning: gears.scad included without std.scad; dependencies may be missing\nSet BOSL2_NO_STD_WARNING = true to mute this warning.") true : true;
_GEAR_PITCH = undef;
_GEAR_HELICAL = 0;
_GEAR_THICKNESS = 10;
_GEAR_PA = 20;
/// Resolved values published to the user's children; no historical pitch state.
$parent_gear_type = undef;
$parent_gear_mod = undef;
$parent_gear_teeth = undef;
$parent_gear_pa = undef;
$parent_gear_helical = undef;
$parent_gear_thickness = undef;
$parent_gear_face_width = undef;
$parent_gear_shaft_offset = undef;
$_gear_worm_face_data = undef;
$parent_gear_profile_shift = undef;
$parent_gear_worm_diam = undef;
$parent_gear_starts = undef;
$parent_gear_worm_length = undef;
$parent_gear_wheel_teeth = undef;
$parent_gear_left_handed = undef;
$parent_gear_clearance = undef;
$parent_gear_herringbone = undef;
$gear_rotation = 0;
$_gear_tooth_angle = 0;
$gear_ratio = 0;
$gear_travel = 0;
$_gear_tooth_travel = 0;
$gear_travel_ratio = 0;
$gear_input = undef;
$gear_contact_dir = undef;
$gear_contact_angle = undef;
$gear_chain_locs = [];
$gear_chain_axes = [];
/// Private mating and coordinate-frame bookkeeping.
$_gear_parent_spec = undef;
$_gear_attach_request = undef;
$_gear_frame_motion = ident(4);
$_gear_frame_phase = 0;
// Carrier support [angular displacement, signed gain]. Entry retains a distinct
// meshing parent while ordinary children belong to the carrier output shaft.
$_gear_carrier = undef;
$_gear_carrier_parent = undef;
$_gear_chain_active = false;
$_gear_driver = undef;
// Motion provenance is independent of the geometry/reset scopes.
$_gear_drive_id = undef;
$_gear_mount_id = undef;
$_gear_motion_plane_ok = true;
$_gear_shaft_motion = undef;
$gear_angle_offset = 0;
$gear_travel_offset = 0;
$worm_length = undef;

$backlash = 0;
$_gear_rack_reference = undef;

function _gear_backlash(value) =
    let(b=default(value,default($backlash,0)))
    assert(is_finite(b) && b>=0, "\nbacklash (or $backlash) must be nonnegative and finite")
    b;
function _inherit_gear_param(name, val, pval, dflt, invert=false) =
    let(resolved=is_undef(val) ? default(pval,dflt) : val)
    assert(is_finite(resolved), str("\n", name," must be a finite number; got ",resolved))
    (!is_undef(pval) && is_undef(val) && invert ? -1 : 1)*resolved;
function _inherit_gear_pitch(fname,circ_pitch,diam_pitch,mod) =
    assert(num_defined([mod,circ_pitch,diam_pitch])<=1,
           str("\n", fname, ": specify only one of mod, circ_pitch, or diam_pitch"))
    assert(is_undef(mod) || (is_finite(mod) && mod>0), "\nmod must be greater than zero and finite")
    assert(is_undef(circ_pitch) || (is_finite(circ_pitch) && circ_pitch>0), "\ncirc_pitch must be greater than zero and finite")
    assert(is_undef(diam_pitch) || (is_finite(diam_pitch) && diam_pitch>0), "\ndiam_pitch must be greater than zero and finite")
    let(cp = num_defined([mod,circ_pitch,diam_pitch])>0
          ? circular_pitch(mod=mod,circ_pitch=circ_pitch,diam_pitch=diam_pitch)
          : is_undef($parent_gear_mod) ? undef : PI*$parent_gear_mod)
    assert(!is_undef(cp), str("\n", fname, ": no tooth size supplied or inherited; specify mod, circ_pitch, or diam_pitch.\n",
               "Earlier versions used circ_pitch=5 here. Specify circ_pitch=5 explicitly to retain that tooth size."))
    assert(is_finite(cp) && cp>0, str("\n", fname, ": inherited tooth size must be greater than zero and finite; got ",cp))
    cp;
// Resolve the rack-only alias before API dispatch, defaults, or inheritance.
function _rack_circ_pitch(fname,pitch,circ_pitch,mod,diam_pitch) =
    assert(num_defined([pitch,circ_pitch,mod,diam_pitch])<=1,
           str("\n", fname, ": specify only one of pitch=, circ_pitch=, mod=, or diam_pitch="))
    is_undef(pitch) ? circ_pitch : pitch;
function _inherit_gear_pa(pressure_angle) =
    _inherit_gear_param(name="pressure_angle", val=pressure_angle, pval=$parent_gear_pa, dflt=20);
function _inherit_gear_helical(helical,invert=false,rack=false) =
    // The native herringbone rack mirrors a different extrusion axis from a
    // spur. Its canonical automatic orientation therefore needs the SAME sign.
    let(rack_herringbone=default($parent_gear_herringbone,false) &&
                         (rack || $parent_gear_type=="rack"))
    _inherit_gear_param(name="helical", val=helical, pval=$parent_gear_helical, dflt=0,
                        invert=invert && !rack_herringbone);
/// A crown publishes the pinion used to generate its tooth spaces.
function _crown_spur_value(value,slot,fallback=undef) =
    is_def(value)?value:$parent_gear_type=="crown"?$_gear_parent_spec[16][slot]:fallback;

function _inherit_gear_thickness(thickness,dflt=10) =
    _inherit_gear_param(name="thickness",val=thickness,
        pval=$parent_gear_type=="crown" ?
                $parent_gear_face_width : $parent_gear_thickness,dflt=dflt);
/// Same shaft-axis angle spelling accepted by both bevel APIs.
function _gear_shaft_angle(shaft_angle,drive_angle) =
    assert(num_defined([shaft_angle,drive_angle])<=1,
           "\nspecify only one of shaft_angle and drive_angle")
    let(angle=first_defined([shaft_angle,drive_angle,90]))
    assert(is_finite(angle) && angle>0 && angle<180,
           str("\nshaft_angle/drive_angle must be between 0 and 180 degrees; got ",angle))
    angle;
// Bevel-only compatibility: the old right_handed and the consistent
// left_handed spelling are inverse aliases, not independent options.
function _gear_left_handed(left_handed,right_handed,default_left=false) =
    assert(is_undef(left_handed) || is_bool(left_handed), "\nleft_handed must be boolean")
    assert(is_undef(right_handed) || is_bool(right_handed), "\nright_handed must be boolean")
    assert(num_defined([left_handed,right_handed])<=1, "\nSpecify left_handed OR right_handed, not both")
    is_undef(right_handed) ? default(left_handed,default_left) : !right_handed;
/// The worm's mate tooth count controls its double-enveloping throat.
function _gear_mate_teeth(teeth,mate_teeth) =
    assert(num_defined([teeth,mate_teeth])<=1,
           "\nspecify only one of teeth and mate_teeth")
    first_defined([teeth,mate_teeth,$parent_gear_wheel_teeth]);
function _gear_worm_length(l,length,h,height,worm_length) =
    assert(num_defined([l,length,h,height,worm_length])<=1,
           "\nspecify only one of l, length, h, height, and worm_length")
    first_defined([l,length,h,height,worm_length,$parent_gear_worm_length,100]);
/// Shared worm aliases are resolved before literal defaults or derived geometry.
/// Keep them outside the removable positional-size compatibility blocks.
function _gear_worm_diameter(d,worm_diam,dflt,worm_root_diam,mod,circ_pitch,diam_pitch,clearance,family=1) =
    assert(num_defined([d,worm_diam,worm_root_diam])<=1,
           "\nspecify only one of d, worm_diam and worm_root_diam")
    let(value=is_undef(worm_root_diam)
            ? first_defined([d,worm_diam,$parent_gear_worm_diam,dflt])
            : _gear_worm_pitch_from_root(worm_root_diam,mod,circ_pitch,diam_pitch,clearance,family))
    assert(is_finite(value) && value>0,
           str("\nworm_diam, d or worm_root_diam must be supplied and must be greater than zero and finite; got ",value))
    value;
/// Convert a nominal minimum root diameter before reference geometry is built.
/// The cylindrical and globoid families inherit clearance independently.
function _gear_worm_pitch_from_root(root,mod,cp,dp,clearance,family) =
    assert(is_finite(root) && root>0,
           "\nworm_root_diam must be positive and finite")
    let(m=_inherit_gear_pitch("worm_root_diam",cp,dp,mod)/PI,
        c=default(clearance,default(_gear_worm_family($parent_gear_type)==family
                                   ?$parent_gear_clearance:undef,m/4)))
    assert(is_finite(c) && c>=0,"\nclearance must be nonnegative and finite")
    root+2*(m+c);

function _gear_worm_starts(starts,worm_starts) =
    assert(num_defined([starts,worm_starts])<=1,
           "\nspecify only one of starts and worm_starts")
    let(value=first_defined([starts,worm_starts,$parent_gear_starts,1]))
    assert(is_int(value) && value>0,
           str("\nstarts (or worm_starts) must be a positive integer; got ",value))
    value;
// Section: Legacy Gear Parameters and Migration
//   Legacy invocation of many gear modules and functions has the form
//   `spur_gear(circ_pitch, teeth, thickness, ...)`
//   The gears parameter order is migrating to a unified calling convention
//   where the size **must** be given as a named parameter:
//   `mod=`, `circ_pitch=`, or `diam_pitch=`.  You can still give the size first,
//   so an invocation with 3 positional parameters becomes `spur_gear(circ_pitch=10, 47, 15)`.
//   Gear parameters can be inherited from parent gears.  If you want to use inheritance, use all named arguments:
//   `spur_gear(teeth=20, thickness=10)`. Fully named call will always work correctly.  
//   An old style call such as `spur_gear(5,20,10)` still means circ_pitch 5, 20 teeth and
//   thickness 10, and emits a deprecation message.  The legacy default gear size, which is no longer supported, was 
//   `circ_pitch=5`.  The legacy support is temporary and will be removed in July 2027 with the
//   final migration.  
///   Delete GEAR_API_COMPAT blocks with tools/remove_compat.py for the final API.
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
//       * [NASA Handbook on Face Gear Drives](https://ntrs.nasa.gov/citations/20000027536)
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
//   The module is hence the circular pitch divided by a factor of π.  A third way, and the most common for Imperial gears,
//   is to give the size using the diametral pitch,
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
//   Helical gears are a modification of spur gears.  They can replace spur gears in any application.  The teeth are cut
//   following a slanted, helical path.  The angled teeth engage more gradually than spur gear teeth, so they run more smoothly
//   and quietly.  A disadvantage of helical gears is that they have thrust along the axis of the gear that must be 
//   accommodated.  Helical gears also have more sliding friction between the meshing teeth compared to spur gears. 
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
// Figure(Anim,Med,Frames=10,NoAxes,VPT=[43.8006,15.9214,3.52727],VPR=[62.3,0,20.3],VPD=446.129): Meshing compatible (coplanar) helical gears
//   zrot($t*360/18)
//     color("lightblue")spur_gear(mod=5, teeth=18, pressure_angle=20, thickness=25, helical=-29, shaft_diam=15);
//   right(gear_dist(mod=5, teeth1=18, teeth2=18, helical=29))
//     zrot(360/18/2)
//       zrot(-$t*360/18)
//         spur_gear(mod=5, teeth=18, pressure_angle=20, thickness=25, helical=29, shaft_diam=15);
// Continues:
//   Helical gears can mesh in a second manner that is different from spur gears: they can rotate on skew, or crossed axes.  These are also
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
//   A worm drive is a gear system for connecting perpendicular offset shafts.  They offer higher load capacity compared to
//   crossed helical gears.  The assembly is driven by the "worm", which is a gear that resembles a screw.
//   Like a screw, it can have one, or several starts.  These starts correspond to teeth on a helical gear;
//   in fact, the worm can be regarded as a type of helical gear at a very extreme angle, where the teeth wrap
//   around the gear.  The worm mates with the "worm gear" which is also called the "worm wheel".  The worm gear
//   superficially resembles a helical gear at a very slight angle, but it has a different tooth form.  
// Figure(3D,Med,NoAxes,VPT=[38.1941,-7.67869,7.95996],VPR=[56.4,0,25],VPD=361.364):  Worm drive assembly, with worm on the left and worm gear (worm wheel) on the right.  When the worm turns, its screwing action drives the worm gear.  
//   starts=2;
//   ps=0;
//   dist_ba=0;
//   gear_ba=0;
//     worm(
//          d=44, 
//          circ_pitch=3*PI,
//          starts=starts,orient=BACK,lead_in=6,gear_spin=90);
//   right(worm_dist(worm_diam=44,mod=3,teeth=30, worm_starts=starts,profile_shift=ps,backlash=dist_ba))
//    color("lightblue")
//       worm_gear(
//          circ_pitch=3*PI, 
//          teeth=30,
//          worm_diam=44,profile_shift=ps,
//          worm_starts=starts,backlash=gear_ba,gear_spin=90);
//   color("black"){
//      rot($vpr)left(45)back(25)text3d("worm",size=8);
//      rot($vpr)right(55)back(27)text3d("worm gear",size=8);  
//   }
// Continues:
//   A close look at the worm gear reveals that it differs significantly from a helical or spur gear.
//   This gear is an "enveloping" gear, which is designed to follow the curved profile of the worm,
//   resulting in much better contact between the teeth of the worm and the teeth of the worm gear.
//   The worm shown above is a cylindrical worm, which is the most common type.
//   It is possible to design the worm with an hourglass shape so it follows the curved shape of its mated gear, resulting
//   in an enveloping worm.  This configuration, where both gears envelope each other is called double enveloping
//   or "globoid".  This type of worm gear drive makes better contact between the gears 
//   but is less often used due to manufacturing complexity and consequent expense.  
// Figure(3D,Big,NoAxes,VPT=[0,0,0],VPR=[192,0,180],VPD=172.84): The cylindrical worm appears on the left in blue; it has straight sides.  The globoid (enveloping) worm appears on the right in green.  Its sides curve around its worm gear so that several teeth can mate with the worm gear, which requires a more complex tooth form.
//   tilt=20;
//   starts=1;
//   ps=0;
//   pa=27;
//   dist_ba=0;
//   gear_ba=0;
//   xdistribute(spacing=27){
//      zrot(180)yrot(-tilt)  
//      union(){
//       color("lightgreen")
//         xrot(90) 
//         zrot(-90)
//         globoid_worm(     teeth=60,$fn=128, l=50,
//             d=14, pressure_angle=pa,  mod=3/2,
//             starts=starts);
//        right(globoid_worm_dist(worm_diam=14,mod=3/2,teeth=60,worm_starts=starts))
//          zrot(360/30*.25)
//            globoid_worm_gear(
//             mod=3/2,pressure_angle=pa,
//             teeth=60,worm_length=50,
//             worm_diam=14,
//             worm_starts=starts,backlash=gear_ba);
//      }
//      yrot(-tilt)
//      union(){
//       color("lightblue")
//         xrot(90) 
//         zrot(-90)
//                                worm(l=50, $fn=128,
//             d=14, pressure_angle=20, left_handed=true,
//             mod=3/2,//circ_pitch=3*PI/2,
//             starts=starts);
//        right(worm_dist(worm_diam=14,mod=3/2,teeth=60, worm_starts=starts,profile_shift=ps,backlash=dist_ba,pressure_angle=pa))
//          zrot(360/30*.25)
//            worm_gear(
//             mod=3/2,pressure_angle=20,
//             teeth=60,crowning=0,left_handed=true,
//             worm_diam=14,profile_shift=ps,
//             worm_starts=starts,backlash=gear_ba);
//      }  
//   }
// Continues:
//   The worm and its worm gear must be designed together.  
//   As usual, a proper mesh requires that the pressure angles match
//   and the teeth on the mating gears are the same size. 
//   Additionally the worm gear must be constructed to match the
//   diameter of the worm and the number of starts on the worm.  The
//   number of starts on the worm changes the angle at of the teeth on
//   the worm, and hence requires a change to the angle of teeth on
//   the worm gear.
//   One worm revolution advances the worm gear by a tooth count equal to the worm's start count.
//   The reduction ratio is therefore `teeth/starts`: the worm gear rotates `starts/teeth` times the number of revolutions made by the worm.
//   .
//   For globoid pairs the worm gear design takes into account the length of the worm
//   in order to ensure that the teeth don't interfere anywhere along its length, and
//   the worm design obviously requires the diameter of the worm gear, which it computes from the tooth count.
//   You cannot use a globoid worm with a regular worm gear, even though the two worm gears look similar.  
//   .
//   To achieve proper mesh, as usual you must separate the gears by the correct distance.  
//   The {{worm_dist()}} and {{globoid_worm_dist()}} functions give the correct center spacing for the worm from its mating worm gear.  
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
//   .
//   Globoid worms have overhangs that may make them difficult to print.  The library supports asymmetric pressure
//   angle globoid worm drives, which can create a gear well suited to driving in one direction and with reduced overhang.
// Figure(3D,Big,NoAxes,VPR=[93.30,0.00,0.00],VPD=192.04,VPT=[0,0,0]): Asymmetric tooth globoid worms with their mating worm gears
//   ang=20;
//   tilt=20;
//   starts=1;
//   pa=[45,5];
//   xdistribute(spacing=27){
//      color_this("lightblue") worm($fn=128, l=50, d=14, pressure_angle=pa, mod=3/2, starts=starts)
//         attach_gear(160) worm_gear(teeth=60);
//      color_this("lightgreen") globoid_worm(teeth=60, $fn=128, l=50, d=14, pressure_angle=pa, mod=3/2, starts=starts)
//         attach_gear(20) globoid_worm_gear();
//   }
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
//   crown_gear(mod=1, teeth=32, mate_teeth=9, backing=3, face_width=7);
//   color("lightblue")
//   back(pitch_radius(mod=1,teeth=32)+7/2)
//     up(gear_dist(mod=1,teeth1=0,teeth2=9))spur_gear(mod=1, teeth=9,orient=BACK,thickness=7,gear_spin=360/9/2);
// Continues:
//   When constructing a crown gear you need to mate it to a non-helical spur gear with a specified number of teeth.  
//   You specify the pressure angle of the mating spur gear, but the teeth of a crown gear have pressure angle that varies
//   along the width of the tooth.  The vertical separation of the spur gear from the crown gear is given
//   by {{gear_dist()}} where you treat the crown gear as a rack.  The inner radius of the teeth on the
//   crown gear is the pitch radius determined by the gear's tooth size and number of teeth.  The face width
//   of a crown gear affects tooth height: toward the outer edge, min_tip may require shorter teeth.
//   A very wide face may add little useful contact area once the outer teeth have been shortened.
// Subsection: Worm Face Drive
//   A worm face drive combines a cylindrical worm with a worm face gear that looks similar to the crown face gear, except it has spiral teeth.
//   It meshes with a worm whose shaft is parallel to the face and offset to one side of the face gear axis.
//   As with a standard worm drive, one worm revolution advances the mated gear by one tooth per worm start,
//   so the reduction ratio is the face gear's tooth count divided by the worm start count.
//   Cylindrical worm face drives are often referred to by the trade name Helicon.  The Spiroid is a related
//   trade named gear form where a tapered worm engages a beveled gear.  [Comparison](https://www.spiroidgearing.com/products/spiroid/spiroid-and-helicon-comparison/).
// Figure(3D,Med,NoAxes): A cylindrical worm meshes with vertical spiral teeth on the face of an offset wheel.
//   worm_face_gear(mod=2, teeth=40, worm_diam=20, shaft_offset=35,
//                  face_width=8, backing=3, backlash=.15)
//       attach_gear(90) recolor("lightblue") worm(l=55);
// Continues:
//   The worm face drive can provide a more compact package than a regular worm drive.  Several teeth
//   can participate in the engagement and like worm drive, it can be self-locking or can permit back drive,
//   depending on the design parameters.  
//   Like other worm drives, the contact involves substantial sliding, so friction, lubrication, material
//   choice and wear matter. 
//   .
//   The shaft offset is the distance between the axis of the worm and the axis of the worm face gear.
//   If the tooth count and mating worm are fixed then the shaft offset and the worm face gear diameter
//   together determine the angle of the teeth.  If you choose only one of these values and let the library
//   select the other you will get an optimized tooth form.  Typically 
//   The face gear diameter will be larger when the shaft offset is smaller, as this requires teeth that are closer to the tangent direction on the gear face.  
// Figure(3D,Med,NoAxes,VPR=[0.00,0.00,0.00],VPD=755.52,VPT=[-22.66,0.81,-15.03]): These worm drives differ only in their shaft offset parameter:
//   xdistribute(spacing=205){
//      worm_face_gear(mod=2, teeth=40, worm_diam=20, shaft_offset=10,
//                     backing=3, backlash=.15,face_width=18)
//          attach_gear(90) recolor("lightblue") worm(l=55);
//      worm_face_gear(mod=2, teeth=40, worm_diam=20, shaft_offset=34,
//                     backing=3, backlash=.15,face_width=18)
//          attach_gear(90) recolor("lightblue") worm(l=68);
//   }
// Continues:
//   You can slide the worm along its axis without changing its engagement until you run out of worm length.
//   Its height above the worm face gear is provided by {{worm_face_dist()}}.  The library supports asymmetric pressure
//   angles. Helicon gears commonly use a small angle like 10 degrees on the drive side and a large
//   angle like 35 degrees on the coast side.
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
// See Also: rack(), spur_gear(), spur_gear2d(), bevel_gear(), attach_gear()
// Usage: As a Function
//   vnf = spur_gear(mod=|circ_pitch=|diam_pitch=, teeth, [thickness], [helical=], [herringbone=], [pressure_angle=], [profile_shift=], [shorten=], [backlash=], [shaft_diam=], [hide=], [gear_spin=], [clearance=], [slices=], [internal=], [$gear_steps=], [atype=], [anchor=], [spin=], [orient=], [interior=]);
// Usage: As a Module
//   spur_gear(mod=|circ_pitch=|diam_pitch=, teeth, [thickness], [helical=], [herringbone=], [pressure_angle=], [profile_shift=], [shorten=], [backlash=], [shaft_diam=], [hide=], [gear_spin=], [clearance=], [slices=], [internal=], [$gear_steps=], [atype=], [anchor=], [spin=], [orient=], [interior=]) [ATTACHMENTS];
// Description:
//   Creates a involute spur gear, helical gear, herringbone gear, or a mask for an internal ring gear.
//   For more information about gears, see [A Quick Introduction to Gears](gears.scad#section-quick-introduction-to-gears).
//   Specify tooth size using `mod`, `circ_pitch`, or `diam_pitch`, or inherit it from a parent gear. 
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
//   The pressure angle inherits from the parent when available; otherwise it defaults to 20 degrees. Another common value is 14.5 degrees.
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
//   .
//   You can position gears directly using {{gear_dist()}}, but it may be easier to use
//   {{attach_gear()}}, which positions the gears and aligns the teeth automatically.
//   When using {{attach_gear()}} for parallel axis gears only TOP, BOTTOM and CENTER anchors are permitted and they
//   align the corresponding gear faces or midpoints.  Skew pairs and helical herringbone gears only accept the CENTER anchor.
// Arguments:
//   teeth = Total number of teeth around the entire perimeter. Inherits mate_teeth from a crown parent.
//   thickness = Axial thickness. Default: inherited from the parent gear if available, 10 otherwise.
//   ---
//   mod = The module of the gear (pitch diameter / teeth)
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  The diametral pitch is a completely different thing than the pitch diameter.
//   circ_pitch = Normal circular pitch.
//   helical = Teeth spiral around the gear at this angle, positive for left handed, negative for right handed. Inherits to mate with parent when omitted.  Default: 0
//   herringbone = If true, and helical is set, creates a herringbone gear.  Default: inherited from the parent gear if available, false otherwise.
//   pressure_angle = Normal pressure angle in degrees. Inherits from the parent when omitted. Default: 20.
//   profile_shift = Profile shift factor x. Inherits mate_profile_shift from a crown parent. Default: "auto"
//   shorten = Shorten gear tips by the module times this value.  Needed for large profile shifted gears.  Default: 0
//   backlash = Gap between two meshing teeth, in the direction along the circumference of the pitch circle.  Default: $backlash
//   shaft_diam = Diameter of the central hole. Default: 0 (no hole).
//   hide = Number of teeth to omit for a partial gear. Default: 0.
//   gear_spin = Rotates the gear around its center by the given number of degrees without affecting any children. Use {{gear_spin()}} to drive the gear and its children.  Default: 0
//   clearance = Clearance gap at the bottom of the inter-tooth valleys. Inherits mate_clearance from a crown parent. Default: mod/4 otherwise.
//   slices = Number of axial extrusion intervals. Calculated from twist and curve resolution when omitted or undef.
//   internal = If true, create an internal-tooth mask. Default: false.
//   $gear_steps = Number of points to sample gear profile.  Default: 16
//   atype = Set to "root", "tip" or "pitch" to determine anchoring circle.  Default: "pitch"
//   anchor = For a child of {{attach_gear()}} specify TOP, BOT or CENTER to align gear to parent.  Otherwise translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top toward, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   interior = Deprecated alias for internal.
// Side Effects:
//   See {{attach_gear()}} for reference frames, units, and inheritance details.
//   If internal is true then the default tag is "remove"
//   Sets internal variables for gear inheritance.
//   `$gear_rotation` is set to the total gear rotation resulting from {{gear_spin()}} or {{gear_travel()}} applied to the gear chain root.
//   `$gear_angle_offset` is set to the angular tooth-alignment offset in degrees, including meshing alignment and local `gear_spin`.
//   `$gear_ratio` is set to signed angular gain: (output degrees)/(input degrees) for rotational input, or (output degrees)/(input travel) for travel input in model units.
//   `$gear_input` is set to "rotation" (degrees), "travel" (model units), or undef for an undriven chain.
//   `$gear_contact_dir` is set to the nominal engagement direction with the parent in the current child frame.
//   `$gear_contact_angle` is set to the corresponding engagement angle in degrees in the current child frame.
//   `$gear_chain_locs` is set to a list of gear center coordinates (pitch-line origins for racks) in the current child frame, with the root gear first and the current gear last.
//   `$gear_chain_axes` is set to a list of shaft-axis unit vectors (`undef` for racks) in the current child frame, with the root gear first and the current gear last.
//   `$gear_travel` is set to zero.
//   `$gear_travel_offset` is set to zero.
//   `$gear_travel_ratio` is set to zero.
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
// Example(Anim,Big,NoAxes,Frames=50,VPT=[0,0,0],VPR=[55,0,25],VPD=220): Planetary Gear Assembly
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
    assert(is_undef(_named), "\nToo many positional arguments (only 2 are accepted)")
    let(
        teeth=_crown_spur_value(teeth,1), clearance=_crown_spur_value(clearance,3),
        shaft_diam=is_undef(shaft_diam)?0:shaft_diam, hide=is_undef(hide)?0:hide,
        backlash=_gear_backlash(backlash),
        profile_shift=_crown_spur_value(profile_shift,2,"auto"),
        herringbone=default(herringbone,default($parent_gear_herringbone,false)), shorten=is_undef(shorten)?0:shorten,
        atype=is_undef(atype)?"pitch":atype, gear_spin=is_undef(gear_spin)?0:gear_spin,
        anchor=is_undef(anchor)?CENTER:anchor, spin=is_undef(spin)?0:spin,
        orient=is_undef(orient)?UP:orient
    )
    let(  
        dummy = !is_undef(interior) ? echo("In spur_gear(), the argument 'interior=' has been deprecated, and may be removed in the future.  Please use 'internal=' instead."):0,
        internal = first_defined([internal,interior,false]),
        circ_pitch = _inherit_gear_pitch(fname="spur_gear()", circ_pitch=circ_pitch, diam_pitch=diam_pitch, mod=mod),
        PA = _inherit_gear_pa(pressure_angle=pressure_angle),
        helical = _inherit_gear_helical(helical=helical, invert=true),
        thickness = _inherit_gear_thickness(thickness=thickness)
    )
    assert(is_integer(teeth) && teeth>=4, str("\nteeth must be an integer at least 4; got ",teeth))
    assert(is_finite(thickness) && thickness>0, "\nthickness must be greater than zero and finite")
    assert(is_finite(shaft_diam) && shaft_diam>=0, "\nshaft_diam must be nonnegative and finite")
    assert(is_integer(hide) && hide>=0 && hide<teeth, str("\nhide must be an integer from 0 to ",teeth-1,"; got ",hide))
    assert(is_finite(PA) && PA>=0 && PA<90, str("\npressure_angle must be finite and in [0,90) degrees; got ",PA))
    assert(clearance==undef || (is_finite(clearance) && clearance>=0), "\nclearance must be nonnegative and finite")
    assert(is_finite(backlash) && backlash>=0, "\nbacklash must be nonnegative and finite")
    assert(is_finite(helical) && abs(helical)<90, str("\nhelical must be finite and strictly between -90 and 90 degrees; got ",helical))
    assert(is_bool(herringbone), "\nherringbone must be boolean")
    assert(slices==undef || (is_integer(slices) && slices>0), "\nslices must be a positive integer or undef for automatic sampling")
    assert(is_finite(gear_spin), "\ngear_spin must be finite")
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
                   : assert(false,"\natype must be one of \"root\", \"tip\" or \"pitch\""),
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
    assert(is_undef(_named), "\nToo many positional arguments (only 2 are accepted)")
 
    let(
        teeth=_crown_spur_value(teeth,1), clearance=_crown_spur_value(clearance,3),
        shaft_diam=is_undef(shaft_diam)?0:shaft_diam, hide=is_undef(hide)?0:hide,
        backlash=_gear_backlash(backlash),
        profile_shift=_crown_spur_value(profile_shift,2,"auto"),
        _profile_auto=is_undef(profile_shift)||profile_shift=="auto",
        herringbone=default(herringbone,default($parent_gear_herringbone,false)), shorten=is_undef(shorten)?0:shorten,
        atype=is_undef(atype)?"pitch":atype, gear_spin=is_undef(gear_spin)?0:gear_spin,
        anchor=is_undef(anchor)?CENTER:anchor, spin=is_undef(spin)?0:spin,
        orient=is_undef(orient)?UP:orient
    )
{
    dummy = !is_undef(interior) ? echo("In spur_gear(), the argument 'interior=' has been deprecated, and may be removed in the future.  Please use 'internal=' instead."):0;
    internal = first_defined([internal,interior,false]);
    circ_pitch = _inherit_gear_pitch(fname="spur_gear()", circ_pitch=circ_pitch, diam_pitch=diam_pitch, mod=mod);
    PA = _inherit_gear_pa(pressure_angle=pressure_angle);
    helical = _inherit_gear_helical(helical=helical, invert=true);
    thickness = _inherit_gear_thickness(thickness=thickness);
    checks =
        assert(is_integer(teeth) && teeth>=4, str("\nteeth must be an integer at least 4; got ",teeth))
        assert(is_finite(thickness) && thickness>0, "\nthickness must be greater than zero and finite")
        assert(is_finite(shaft_diam) && shaft_diam>=0, "\nshaft_diam must be nonnegative and finite")
        assert(is_integer(hide) && hide>=0 && hide<teeth, str("\nhide must be an integer from 0 to ",teeth-1,"; got ",hide))
        assert(is_finite(PA) && PA>=0 && PA<90, str("\npressure_angle must be finite and in [0,90) degrees; got ",PA))
        assert(clearance==undef || (is_finite(clearance) && clearance>=0), "\nclearance must be nonnegative and finite")
        assert(is_finite(backlash) && backlash>=0, "\nbacklash must be nonnegative and finite")
        assert(is_finite(helical) && abs(helical)<90, str("\nhelical must be finite and strictly between -90 and 90 degrees; got ",helical))
        assert(is_bool(herringbone), "\nherringbone must be boolean")
        assert(slices==undef || (is_integer(slices) && slices>0), "\nslices must be a positive integer or undef for automatic sampling")
        assert(is_finite(gear_spin), "\ngear_spin must be finite");
    profile_shift = auto_profile_shift(teeth=teeth,pressure_angle=PA,helical=helical,profile_shift=profile_shift);
    pr = pitch_radius(circ_pitch=circ_pitch, teeth=teeth, helical=helical);
    or = outer_radius(circ_pitch=circ_pitch, teeth=teeth, helical=helical, profile_shift=profile_shift, internal=internal,shorten=shorten);
    rr = root_radius(circ_pitch=circ_pitch, teeth=teeth, helical=helical, clearance=clearance, internal=internal,
                     profile_shift=profile_shift, pressure_angle=PA,  backlash=backlash);
    convexity = ceil(2 * teeth * hyp_adj_to_ang(or,rr)/180);
    anchor_rad = atype=="pitch" ? pr
               : atype=="tip" ? or
               : atype=="root" ? rr
               : assert(false,"\natype must be one of \"root\", \"tip\" or \"pitch\"");
    circum = 2 * PI * pr;
    twist = 360*thickness*tan(helical)/circum;
    slices = default(slices, ceil(abs(twist)/360*segs(pr)+1));
    _spec = _gear_spec("spur",circ_pitch/PI,teeth,PA,helical,thickness=thickness,
                           shift=profile_shift,clearance=default(clearance,circ_pitch/PI/4),
                           internal=internal,herringbone=herringbone,two_d=false,shift_auto=_profile_auto);
    _geom = attach_geom(r=anchor_rad, l=thickness);
    _pose = _gear_pose(_spec, gear_spin, anchor, spin, orient,geom=_geom);
    default_tag("remove", internal) {
        _gear_place(_pose)
    attachable(anchor,spin,orient,geom=_geom) {
            zrot(_pose[1])
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
        _gear_publish(_spec,_pose) children();
        }
    }
}
// Function&Module: spur_gear2d()
// Synopsis: Creates a 2D spur gear or internal ring gear.
// SynTags: Geom, Region
// Topics: Gears, Parts
// See Also: rack(), spur_gear(), spur_gear2d(), bevel_gear(), attach_gear()
// Usage: As a Function
//   value = spur_gear2d(mod=|circ_pitch=|diam_pitch=, teeth, [pressure_angle=], [profile_shift=], [shorten=], [backlash=], [helical=], [hide=], [gear_spin=], [clearance=], [internal=], [$gear_steps=], [shaft_diam=], [atype=], [anchor=], [spin=], [interior=]);
// Usage: As a Module
//   spur_gear2d(mod=|circ_pitch=|diam_pitch=, teeth, [pressure_angle=], [profile_shift=], [shorten=], [backlash=], [helical=], [hide=], [gear_spin=], [clearance=], [internal=], [$gear_steps=], [shaft_diam=], [atype=], [anchor=], [spin=], [interior=]) [ATTACHMENTS];
// Description:
//   Creates a 2D involute spur gear, or a mask for an internal ring gear.
//   For more information about gears, see [A Quick Introduction to Gears](gears.scad#section-quick-introduction-to-gears).
//   Specify tooth size using `mod`, `circ_pitch`, or `diam_pitch`, or inherit it from a parent gear.
//   .
//   The module creates the gear in centered on the origin, with one tooth centered on the positive Y axis.
//   In order for two gears to mesh they must have the same tooth size and `pressure_angle`
//   The pressure angle inherits from the parent when available; otherwise it defaults to 20 degrees. Another common value is 14.5 degrees.
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
//   .
//   You can position gears directly using {{gear_dist()}}, but it may be easier to use
//   {{attach_gear()}}, which positions the gears and aligns the teeth automatically.
// Arguments:
//   teeth = Total number of teeth around the spur gear.
//   ---
//   mod = The module of the gear (pitch diameter / teeth)
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  The diametral pitch is a completely different thing than the pitch diameter.
//   circ_pitch = Normal circular pitch.
//   pressure_angle = Normal pressure angle in degrees. Inherits from the parent when omitted. Default: 20.
//   profile_shift = Profile shift factor x.  Profile shift is not inherited. Default: "auto"
//   shorten = Shorten gear tips by the module times this value.  Needed for large profile shifted gears.  Default: 0
//   backlash = Gap between two meshing teeth, in the direction along the circumference of the pitch circle.  Default: $backlash
//   helical = Cross-section of teeth spiraling at this angle, positive for left handed, negative for right handed. Inherits to mate with parent when omitted.  Default: 0
//   hide = Number of teeth to omit for a partial gear. Default: 0.
//   gear_spin = Rotates the gear around its center by the given number of degrees without affecting any children. Use {{gear_spin()}} to drive the gear and its children.  Default: 0
//   clearance = Gap between top of a tooth on one gear and bottom of valley on a meshing gear.  Default: mod/4
//   internal = If true, create an internal-tooth mask. Default: false.
//   $gear_steps = Number of points to sample gear profile.  Default: 16
//   shaft_diam = Diameter of the central hole. Default: 0 (no hole).
//   atype = Set to "root", "tip" or "pitch" to determine anchoring circle.  Default: "pitch"
//   anchor = For a child of {{attach_gear()}} must be CENTER.  Otherwise translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   interior = Deprecated alias for internal.
// Side Effects:
//   See {{attach_gear()}} for reference frames, units, and inheritance details.
//   If internal is true then the default tag is "remove"
//   Sets internal variables for gear inheritance.
//   `$gear_rotation` is set to the total gear rotation resulting from {{gear_spin()}} or {{gear_travel()}} applied to the gear chain root.
//   `$gear_angle_offset` is set to the angular tooth-alignment offset in degrees, including meshing alignment and local `gear_spin`.
//   `$gear_ratio` is set to signed angular gain: (output degrees)/(input degrees) for rotational input, or (output degrees)/(input travel) for travel input in model units.
//   `$gear_input` is set to "rotation" (degrees), "travel" (model units), or undef for an undriven chain.
//   `$gear_contact_dir` is set to the nominal engagement direction with the parent in the current child frame.
//   `$gear_contact_angle` is set to the corresponding engagement angle in degrees in the current child frame.
//   `$gear_chain_locs` is set to a list of gear center coordinates (pitch-line origins for racks) in the current child frame, with the root gear first and the current gear last.
//   `$gear_chain_axes` is set to a list of shaft-axis unit vectors (`undef` for racks) in the current child frame, with the root gear first and the current gear last.
//   `$gear_travel` is set to zero.
//   `$gear_travel_offset` is set to zero.
//   `$gear_travel_ratio` is set to zero.
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
    assert(is_undef(_named), "\nToo many positional arguments (only 1 is accepted)")
    let(
        hide=is_undef(hide)?0:hide, backlash=_gear_backlash(backlash),
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
        helical = _inherit_gear_helical(helical=helical, invert=true)
    )
    assert(is_integer(teeth) && teeth>=4, str("\nteeth must be an integer at least 4; got ",teeth))
    assert(is_finite(shaft_diam) && shaft_diam>=0, "\nshaft_diam must be nonnegative and finite")
    assert(is_integer(hide) && hide>=0 && hide<teeth, str("\nhide must be an integer from 0 to ",teeth-1,"; got ",hide))
    assert(is_finite(PA) && PA>=0 && PA<90, str("\npressure_angle must be finite and in [0,90) degrees; got ",PA))
    assert(clearance==undef || is_finite(clearance), "\nclearance must be nonnegative and finite")
    assert(is_finite(backlash) && backlash>=0, "\nbacklash must be nonnegative and finite")
    assert(is_finite(helical) && abs(helical)<90, str("\nhelical must be finite and strictly between -90 and 90 degrees; got ",helical))
    assert(is_finite(gear_spin), "\ngear_spin must be finite")
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
                   : assert(false,"\natype must be one of \"root\", \"tip\" or \"pitch\""),
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
    assert(is_undef(_named), "\nToo many positional arguments (only 1 is accepted)")
 
    let(
        hide=is_undef(hide)?0:hide, backlash=_gear_backlash(backlash),
        profile_shift=is_undef(profile_shift)?"auto":profile_shift,
        _profile_auto=is_undef(profile_shift)||profile_shift=="auto",
        shorten=is_undef(shorten)?0:shorten, shaft_diam=is_undef(shaft_diam)?0:shaft_diam,
        gear_spin=is_undef(gear_spin)?0:gear_spin, atype=is_undef(atype)?"pitch":atype,
        anchor=is_undef(anchor)?CENTER:anchor, spin=is_undef(spin)?0:spin
    )
{
    dummy = !is_undef(interior) ? echo("In spur_gear2d(), the argument 'interior=' has been deprecated, and may be removed in the future.  Please use 'internal=' instead."):0;
    internal = first_defined([internal,interior,false]);
    circ_pitch = _inherit_gear_pitch(fname="spur_gear2d()", circ_pitch=circ_pitch, diam_pitch=diam_pitch, mod=mod);
    PA = _inherit_gear_pa(pressure_angle=pressure_angle);
    helical = _inherit_gear_helical(helical=helical, invert=true);
    checks =
        assert(is_integer(teeth) && teeth>=4, str("\nteeth must be an integer at least 4; got ",teeth))
        assert(is_finite(shaft_diam) && shaft_diam>=0, "\nshaft_diam must be nonnegative and finite")
        assert(is_integer(hide) && hide>=0 && hide<teeth, str("\nhide must be an integer from 0 to ",teeth-1,"; got ",hide))
        assert(is_finite(PA) && PA>=0 && PA<90, str("\npressure_angle must be finite and in [0,90) degrees; got ",PA))
        assert(clearance==undef || is_finite(clearance), "\nclearance must be nonnegative and finite")
        assert(is_finite(backlash) && backlash>=0, "\nbacklash must be nonnegative and finite")
        assert(is_finite(helical) && abs(helical)<90, str("\nhelical must be finite and strictly between -90 and 90 degrees; got ",helical))
        assert(is_finite(gear_spin), "\ngear_spin must be finite");
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
               : assert(false,"\natype must be one of \"root\", \"tip\" or \"pitch\"");
    _spec = _gear_spec("spur2D",circ_pitch/PI,teeth,PA,helical,thickness=0,
                           shift=profile_shift,clearance=default(clearance,circ_pitch/PI/4),
                           internal=internal,herringbone=false,two_d=true,shift_auto=_profile_auto);
    _geom = attach_geom(two_d=true, r=anchor_rad);
    _pose = _gear_pose(_spec, gear_spin, anchor, spin, UP,geom=_geom);
    _gear_place(_pose)
    attachable(anchor,spin,geom=_geom) {
        zrot(_pose[1]) region(rgn);
        _gear_publish(_spec,_pose) children();
    }
}
// Module: ring_gear()
// Synopsis: Creates a 3D ring gear.
// SynTags: Geom
// Topics: Gears, Parts
// See Also: rack(), ring_gear2d(), spur_gear(), spur_gear2d(), bevel_gear(), attach_gear()
// Usage: As a Module
//   ring_gear(mod=|circ_pitch=|diam_pitch=, teeth, [thickness], [backing], [$gear_steps=], [od=], [or=], [width=], [pressure_angle=], [helical=], [herringbone=], [profile_shift=], [clearance=], [backlash=], [anchor=], [spin=], [orient=], [atype=], [gear_spin=], [slices=]) [ATTACHMENTS];
// Description:
//   Creates a 3D involute ring gear.
//   Meshing gears must have the same tooth size, pressure angle and helical angle as usual.
//   Additionally, you must have more teeth on an internal gear than its mating external gear, and
//   the profile shift on the ring gear must be at least as big as the profile shift on the mating gear.
//   Specify tooth size using `mod`, `circ_pitch`, or `diam_pitch`, or inherit it from a parent gear. 
//   The ring gear's `profile_shift` defaults to zero, even when the mating spur gear may automatically profile shift.
//   You may need to use {{auto_profile_shift()}} to find the profile shift of a mating spur gear if it has a small number of teeth
//   and you use the default "auto" profile shift.  The gear spacing is given by {{gear_dist()}}.  
//   .
//   You can position gears directly using {{gear_dist()}}, but it may be easier to use
//   {{attach_gear()}}, which positions the gears and aligns the teeth automatically.
//   When using {{attach_gear()}} only TOP, BOTTOM and CENTER anchors are permitted and they
//   control the alignment of the gear to its parent, aligning to the same anchor on the parent.
//   So for example, a TOP anchor will line up the two top faces of the parent and child. 
// Arguments:
//   teeth = Total number of teeth around the ring gear.
//   thickness = Axial thickness. Default: inherited from the parent gear if available, 10 otherwise.
//   backing = The width of the ring gear backing.  Default: height of teeth
//   ---
//   mod = The module of the gear (pitch diameter / teeth)
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  The diametral pitch is a completely different thing than the pitch diameter.
//   circ_pitch = Normal circular pitch.
//   od = outer diameter of the ring
//   or = outer radius of the ring
//   width = width of the ring, measuring from tips of teeth to outside of ring.  
//   pressure_angle = Normal pressure angle in degrees. Inherits from the parent when omitted. Default: 20.
//   helical = Teeth spiral around the gear at this angle, positive for left handed, negative for right handed. Inherits to mate with parent when omitted.  Default: 0
//   herringbone = Make a herringbone gear when true and helical is nonzero. Default: inherited from the parent gear if available, false otherwise.
//   profile_shift = Profile shift factor for tooth profile.  Must be at least as big as profile shift of the mating gear.  Profile shift is not inherited. Default: 0
//   clearance = Tooth-root clearance. Default: module/4.
//   backlash = Tooth-thinning backlash at the pitch circle. Default: $backlash.
//   $gear_steps = Number of points to sample gear profile.  Default: 16
//   anchor = For a child of {{attach_gear()}} specify TOP, BOT or CENTER to align gear to parent.  Otherwise translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top toward, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   atype = Anchoring radius: "pitch" or "outside". Default: "pitch"
//   gear_spin = Rotates the gear around its center by the given number of degrees without affecting any children. Use {{gear_spin()}} to drive the gear and its children.  Default: 0
//   slices = Axial slices used by the extrusion; calculated from twist when omitted or undef.
// Side Effects:
//   See {{attach_gear()}} for reference frames, units, and inheritance details.
//   Sets internal variables for gear inheritance.
//   `$gear_rotation` is set to the total gear rotation resulting from {{gear_spin()}} or {{gear_travel()}} applied to the gear chain root.
//   `$gear_angle_offset` is set to the angular tooth-alignment offset in degrees, including meshing alignment and local `gear_spin`.
//   `$gear_ratio` is set to signed angular gain: (output degrees)/(input degrees) for rotational input, or (output degrees)/(input travel) for travel input in model units.
//   `$gear_input` is set to "rotation" (degrees), "travel" (model units), or undef for an undriven chain.
//   `$gear_contact_dir` is set to the nominal engagement direction with the parent in the current child frame.
//   `$gear_contact_angle` is set to the corresponding engagement angle in degrees in the current child frame.
//   `$gear_chain_locs` is set to a list of gear center coordinates (pitch-line origins for racks) in the current child frame, with the root gear first and the current gear last.
//   `$gear_chain_axes` is set to a list of shaft-axis unit vectors (`undef` for racks) in the current child frame, with the root gear first and the current gear last.
//   `$gear_travel` is set to zero.
//   `$gear_travel_offset` is set to zero.
//   `$gear_travel_ratio` is set to zero.
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
    assert(is_undef(_named), "\nToo many positional arguments (only 3 are accepted)")
 
    let(
        herringbone=default(herringbone,default($parent_gear_herringbone,false)),
        profile_shift=is_undef(profile_shift)?0:profile_shift,
        backlash=_gear_backlash(backlash), gear_spin=is_undef(gear_spin)?0:gear_spin,
        anchor=is_undef(anchor)?CENTER:anchor, atype=is_undef(atype)?"pitch":atype,
        spin=is_undef(spin)?0:spin, orient=is_undef(orient)?UP:orient
    )
{
    circ_pitch = _inherit_gear_pitch(fname="ring_gear()",circ_pitch=circ_pitch, diam_pitch=diam_pitch, mod=mod);
    PA = _inherit_gear_pa(pressure_angle=pressure_angle);
    helical = _inherit_gear_helical(helical=helical,invert=true);       // Maybe broken???
    thickness = _inherit_gear_thickness(thickness=thickness);
    checks =
        assert(in_list(atype,["outside","pitch"]), str("\natype must be \"outside\" or \"pitch\"; got ",atype))
        assert(is_finite(profile_shift), "\nProfile shift for ring gears must be numerical")
        assert(is_integer(teeth) && teeth>=4, str("\nteeth must be an integer at least 4; got ",teeth))
        assert(is_finite(thickness) && thickness>0, "\nthickness must be greater than zero and finite")
        assert(is_finite(PA) && PA>=0 && PA<90, str("\npressure_angle must be finite and in [0,90) degrees; got ",PA))
        assert(is_finite(helical) && abs(helical)<90, str("\nhelical must be finite and strictly between -90 and 90 degrees; got ",helical))
        assert(is_bool(herringbone), "\nherringbone must be boolean")
        assert(clearance==undef || (is_finite(clearance) && clearance>=0), "\nclearance must be nonnegative and finite")
        assert(is_finite(backlash) && backlash>=0, "\nbacklash must be nonnegative and finite")
        assert(slices==undef || (is_integer(slices) && slices>0), "\nslices must be a positive integer or undef for automatic sampling")
        assert(num_defined([backing,or,od,width])<=1, "\nCannot define more than one of backing, or, od and width")
        assert(is_finite(gear_spin), "\ngear_spin must be finite");
    pr = pitch_radius(circ_pitch=circ_pitch, teeth=teeth, helical=helical);
    ar = outer_radius(circ_pitch=circ_pitch, teeth=teeth, helical=helical, profile_shift=profile_shift, internal=true);
    //rr=_root_radius_basic(circ_pitch, teeth, clearance, profile_shift=profile_shift, internal=true, helical=helical);
    rr = root_radius(circ_pitch=circ_pitch, teeth=teeth, helical=helical, clearance=clearance, internal=true,
                     profile_shift=profile_shift, pressure_angle=PA, backlash=backlash);
    or = _ring_gear_outer_radius(ar,rr,backing,or,od,width);
    circum = 2 * PI * pr;
    twist = 360*thickness*tan(-helical)/circum;
    slices = default(slices, ceil(abs(twist)/360*segs(pr)+1));
    _spec = _gear_spec("ring",circ_pitch/PI,teeth,PA,helical,thickness=thickness,
                           shift=profile_shift,clearance=default(clearance,circ_pitch/PI/4),
                           internal=true,herringbone=herringbone,two_d=false);
    _geom = attach_geom(h=thickness, r=atype=="outside"?or:pr);
    _pose = _gear_pose(_spec, gear_spin, anchor, spin, orient,geom=_geom);
    _gear_place(_pose)
    attachable(anchor,spin,orient,geom=_geom) {
        zrot(_pose[1])
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
        _gear_publish(_spec,_pose) children();
    }
}
// Module: ring_gear2d()
// Synopsis: Creates a 2D ring gear.
// SynTags: Geom
// Topics: Gears, Parts
// See Also: rack(), spur_gear(), spur_gear2d(), bevel_gear(), attach_gear()
// Usage: As a Module
//   ring_gear2d(mod=|circ_pitch=|diam_pitch=, teeth, [backing], [$gear_steps=], [od=], [or=], [width=], [helical=], [pressure_angle=], [profile_shift=], [clearance=], [backlash=], [anchor=], [spin=], [atype=], [gear_spin=], [shorten=]) [ATTACHMENTS];
// Description:
//   Creates a 2D involute ring gear.
//   Meshing gears must have the same tooth size, pressure angle and helical angle as usual.
//   Additionally, you must have more teeth on an internal gear than its mating external gear, and
//   the profile shift on the ring gear must be at least as big as the profile shift on the mating gear.
//   Specify tooth size using `mod`, `circ_pitch`, or `diam_pitch`, or inherit it from a parent gear. 
//   .
//   The ring gear's `profile_shift` defaults to zero, even when the mating spur gear may automatically profile shift.
//   You may need to use {{auto_profile_shift()}} to find the profile shift of a mating spur gear if it has a small number of teeth
//   and you use the default "auto" profile shift.  The gear spacing is given by {{gear_dist()}}.  
//   .
//   You can position gears directly using {{gear_dist()}}, but it may be easier to use
//   {{attach_gear()}}, which positions the gears and aligns the teeth automatically.
// Arguments:
//   teeth = Total number of teeth around the ring gear.
//   backing = The width of the ring gear backing.  Default: height of teeth
//   ---
//   mod = The module of the gear (pitch diameter / teeth)
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  The diametral pitch is a completely different thing than the pitch diameter.
//   circ_pitch = Normal circular pitch.
//   od = outer diameter of the ring
//   or = outer radius of the ring
//   width = width of the ring, measuring from tips of teeth to outside of ring.  
//   helical = Cross-section of teeth spiraling at this angle, positive for left handed, negative for right handed. Inherits to mate with parent when omitted.  Default: 0
//   pressure_angle = Normal pressure angle in degrees. Inherits from the parent when omitted. Default: 20.
//   profile_shift = Profile shift factor for tooth profile.  Must be at least as big as profile shift of the mating gear.  Profile shift is not inherited. Default: 0
//   clearance = Tooth-root clearance. Default: module/4.
//   backlash = Tooth-thinning backlash at the pitch circle. Default: $backlash.
//   $gear_steps = Number of points to sample gear profile.  Default: 16
//   anchor = For a child of {{attach_gear()}} must be CENTER.  Otherwise translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   atype = Anchoring radius: "pitch" or "outside". Default: "pitch"
//   gear_spin = Rotates the gear around its center by the given number of degrees without affecting any children. Use {{gear_spin()}} to drive the gear and its children.  Default: 0
//   shorten = Shorten tips by this factor times the module. Default: 0
// Side Effects:
//   See {{attach_gear()}} for reference frames, units, and inheritance details.
//   Sets internal variables for gear inheritance.
//   `$gear_rotation` is set to the total gear rotation resulting from {{gear_spin()}} or {{gear_travel()}} applied to the gear chain root.
//   `$gear_angle_offset` is set to the angular tooth-alignment offset in degrees, including meshing alignment and local `gear_spin`.
//   `$gear_ratio` is set to signed angular gain: (output degrees)/(input degrees) for rotational input, or (output degrees)/(input travel) for travel input in model units.
//   `$gear_input` is set to "rotation" (degrees), "travel" (model units), or undef for an undriven chain.
//   `$gear_contact_dir` is set to the nominal engagement direction with the parent in the current child frame.
//   `$gear_contact_angle` is set to the corresponding engagement angle in degrees in the current child frame.
//   `$gear_chain_locs` is set to a list of gear center coordinates (pitch-line origins for racks) in the current child frame, with the root gear first and the current gear last.
//   `$gear_chain_axes` is set to a list of shaft-axis unit vectors (`undef` for racks) in the current child frame, with the root gear first and the current gear last.
//   `$gear_travel` is set to zero.
//   `$gear_travel_offset` is set to zero.
//   `$gear_travel_ratio` is set to zero.
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
    assert(is_undef(_named), "\nToo many positional arguments (only 2 are accepted)")
 
    let(
        profile_shift=is_undef(profile_shift)?0:profile_shift,
        backlash=_gear_backlash(backlash), atype=is_undef(atype)?"pitch":atype,
        gear_spin=is_undef(gear_spin)?0:gear_spin, shorten=is_undef(shorten)?0:shorten,
        anchor=is_undef(anchor)?CENTER:anchor, spin=is_undef(spin)?0:spin
    )
{
    
    circ_pitch = _inherit_gear_pitch(fname="ring_gear2d()",circ_pitch=circ_pitch, diam_pitch=diam_pitch, mod=mod);
    PA = _inherit_gear_pa(pressure_angle=pressure_angle);
    helical = _inherit_gear_helical(helical=helical,invert=true);
    checks =
        assert(in_list(atype,["outside","pitch"]), str("\natype must be \"outside\" or \"pitch\"; got ",atype))
        assert(is_finite(profile_shift), "\nProfile shift for ring gears must be numerical")
        assert(is_integer(teeth) && teeth>=4, str("\nteeth must be an integer at least 4; got ",teeth))
        assert(num_defined([backing,or,od,width])<=1, "\nCannot define more than one of backing, or, od and width")
        assert(is_finite(PA) && PA>=0 && PA<90, str("\npressure_angle must be finite and in [0,90) degrees; got ",PA))
        assert(is_finite(helical) && abs(helical)<90, str("\nhelical must be finite and strictly between -90 and 90 degrees; got ",helical))
        assert(clearance==undef || (is_finite(clearance) && clearance>=0), "\nclearance must be nonnegative and finite")
        assert(is_finite(backlash) && backlash>=0, "\nbacklash must be nonnegative and finite")
        assert(is_finite(gear_spin), "\ngear_spin must be finite");
    pr = pitch_radius(circ_pitch=circ_pitch, teeth=teeth, helical=helical);
    ar = outer_radius(circ_pitch=circ_pitch, teeth=teeth, helical=helical, profile_shift=profile_shift, internal=true);
    //rr=_root_radius_basic(circ_pitch, teeth, clearance, profile_shift=profile_shift, internal=true);
    rr = root_radius(circ_pitch=circ_pitch, teeth=teeth, helical=helical, clearance=clearance, internal=true,
                     profile_shift=profile_shift, pressure_angle=PA, backlash=backlash);
    or = _ring_gear_outer_radius(ar,rr,backing,or,od,width);
    _spec = _gear_spec("ring2D",circ_pitch/PI,teeth,PA,helical,thickness=0,
                           shift=profile_shift,clearance=default(clearance,circ_pitch/PI/4),
                           internal=true,herringbone=false,two_d=true);
    _geom = attach_geom(two_d=true, r=atype=="pitch"?pr:or);
    _pose = _gear_pose(_spec, gear_spin, anchor, spin, UP,geom=_geom);
    _gear_place(_pose)
    attachable(anchor,spin,geom=_geom) {
        zrot(_pose[1])
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
        _gear_publish(_spec,_pose) children();
    }
}
// Shared outside radius for ring constructors and assembly sizing.
// ar is the outside tooth-root envelope; rr is the inner tooth-tip radius.
function _ring_gear_outer_radius(ar,rr,backing,or,od,width) =
    is_def(or) ?
            assert(is_finite(or) && or>ar, str("\nor must exceed ",ar," for this ring; got ",or))
            or
       : is_def(od) ?
            assert(is_finite(od) && od>2*ar, str("\nod must exceed ",2*ar," for this ring; got ",od))
            od/2
       : is_def(width) ?
            assert(is_finite(width) && width>ar-rr, str("\nwidth must be greater than ",ar-rr,"; got ",width))
            rr+width
       : is_def(backing) ?
            assert(all_positive([backing]), "\nbacking must be a positive value")
            ar+backing
       : 2*ar - rr;

// Function&Module: rack()
// Synopsis: Creates a straight or helical gear rack.
// SynTags: Geom, VNF
// Topics: Gears, Parts
// See Also: rack2d(), spur_gear(), spur_gear2d(), bevel_gear(), attach_gear()
// Usage: As a Module
//   rack(pitch=|mod=|circ_pitch=|diam_pitch=, teeth, [thickness], [backing], [bottom=], [width=], [helical=], [herringbone=], [profile_shift=], [pressure_angle=], [backlash=], [clearance=], [anchor=], [spin=], [orient=], [gear_travel=]) [ATTACHMENTS];
// Usage: As a Function
//   vnf = rack(pitch=|mod=|circ_pitch=|diam_pitch=, teeth, [thickness], [backing], [bottom=], [width=], [helical=], [herringbone=], [profile_shift=], [pressure_angle=], [backlash=], [clearance=], [anchor=], [spin=], [orient=], [gear_travel=]);
// Description:
//   This is used to create a 3D rack, which is a linear bar with teeth that a gear can roll along.
//   A rack meshes with an external spur or helical pinion using the same normal tooth size and pressure angle.
//   The helical angle of the mating gear must be the negative of the rack's helical angle for the usual planar engagement.
//   Other angles angles require engagement at a skew angle determined by the sum of the  helical angles of the two gears. 
//   When called as a function, returns a 3D [VNF](vnf.scad) for the rack.
//   When called as a module, creates a 3D rack shape.
//   .
//   Specify tooth size using `pitch`, `mod`, `circ_pitch`, or `diam_pitch`, or inherit it from a parent spur gear. 
//   For a rack, `pitch=` specifies normal tooth pitch, perpendicular to the tooth lines, and `circ_pitch=` is permitted
//   as a synonym for consistency and compatibility with other gears.
//   By default the rack has a backing whose height is equal to the height of the teeth.  You can specify a different backing size
//   or you can specify the total width of the rack (from the bottom of the rack to tooth tips) or the
//   bottom point of the rack, which is the distance from the pitch line to the bottom of the rack.
//   .
//   The rack appears oriented with
//   its teeth pointed UP, so to mesh with gears in the XY plane, use `orient=BACK` or `orient=FWD` and apply any desired rotation.  
//   The pitch line of the rack is aligned with the x axis, the TOP anchors are at the tips of the teeth and the BOTTOM anchors at
//   the bottom of the backing.  Note that for helical racks the corner anchors still point at 45° angles.
//   .
//   You can position gears directly using {{gear_dist()}}, but it may be easier to use
//   {{attach_gear()}}, which positions the gears and aligns the teeth automatically.
//   When using {{attach_gear()}} with parallel engagement the FWD, BACK and CENTER anchors align the rack
//   with the TOP, BOTTOM and CENTER of the parent respectively.  For consistency with other
//   gears you can also use TOP and BOTTOM instead of FWD and BACK.  For skew engagement only CENTER is permitted.
//   In either the parallel or skew case you can add LEFT or RIGHT components to your anchor to select which end of the RACK
//   aligns with the parent gear.
// Arguments:
//   teeth = Total number of teeth along the rack. Required.
//   thickness = Axial thickness. Default: inherited from the parent gear if available, 10 otherwise.
//   backing = Distance from bottom of rack to the roots of the rack's teeth.  (Alternative to bottom or width.)  Default: height of rack teeth
//   ---
//   mod = The module of the gear (pitch diameter / teeth)
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  The diametral pitch is a completely different thing than the pitch diameter.
//   pitch/circ_pitch = Tooth pitch perpendicular to the tooth lines.
//   bottom = Distance from rack's pitch line (the x-axis) to the bottom of the rack.  (Alternative to backing or width)
//   width = Distance from base of rack to tips of teeth (alternative to bottom and backing).
//   helical = Angle of the rack teeth away from perpendicular to its length. Inherits to mate with parent when omitted.  Default: 0
//   herringbone = Make a herringbone rack when true and helical is nonzero. Default: inherited from the parent gear if available, false otherwise.
//   profile_shift = Profile shift factor x.  Profile shift is not inherited. Default: 0
//   pressure_angle = Normal pressure angle in degrees. Inherits from the parent when omitted. Default: 20.
//   backlash = Gap between two meshing teeth, in the direction along the circumference of the pitch circle.  Default: $backlash
//   clearance = Clearance gap at the bottom of the inter-tooth valleys.  Default: module/4
//   anchor = As a child of {{attach_gear()}} specifies face and end alignment of the rack to the parent.  Otherwise translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top toward, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   gear_travel = Translate the rack along its length without moving its anchors or children.  Use {{gear_travel()}} to drive the rack and its children. Default: 0
// Side Effects:
//   See {{attach_gear()}} for reference frames, units, and inheritance details.
//   Sets internal variables for gear inheritance.
//   `$gear_travel` is set to the displacement in model units of the rack resulting from {{gear_spin()}} or {{gear_travel()}} applied to the gear chain root. 
//   `$gear_travel_offset` is set to the local `gear_travel` offset in model units.
//   `$gear_travel_ratio` is set to signed linear gain: (output travel)/(input rotation) for rotational input, or (output travel)/(input travel) for travel input. 
//   `$gear_input` is set to "rotation" (degrees), "travel" (model units), or undef for an undriven chain.
//   `$gear_contact_dir` is set to the engagement direction with the parent in the current child frame, which is always UP for 3D racks engaged with a parent.
//   `$gear_contact_angle` is set to the corresponding engagement angle, which is always 90 degrees for racks.
//   `$gear_chain_locs` is set to a list of gear center coordinates (pitch-line origins for racks) in the current child frame, with the root gear first and the current gear last.
//   `$gear_chain_axes` is set to a list of shaft-axis unit vectors (`undef` for racks) in the current child frame, with the root gear first and the current gear last.
//   `$gear_rotation` is set to zero.
//   `$gear_angle_offset` is set to zero.
//   `$gear_ratio` is set to zero.
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
    assert(is_undef(_named), "\nToo many positional arguments (only 3 are accepted)")
 
    let(
        backlash=_gear_backlash(backlash), herringbone=default(herringbone,default($parent_gear_herringbone,false)),
        profile_shift=is_undef(profile_shift)?0:profile_shift,
        gear_travel=is_undef(gear_travel)?0:gear_travel,
        anchor=is_undef($_gear_attach_request) ? default(anchor,CENTER) :
               _gear_rack_anchor(default(anchor,CENTER)),
        spin=is_undef(spin)?0:spin, orient=is_undef(orient)?UP:orient
    )
{
    pitch = _inherit_gear_pitch(fname="rack()",circ_pitch=circ_pitch, diam_pitch=diam_pitch, mod=mod);
    PA = _inherit_gear_pa(pressure_angle=pressure_angle);
    helical = _inherit_gear_helical(helical=helical,invert=true,rack=true);
    thickness = _inherit_gear_thickness(thickness=thickness);
    checks=
        assert(num_defined([backing,bottom,width])<=1,
               "\nspecify only one of backing, bottom, or width")
        assert(is_integer(teeth) && teeth>=1, str("\nteeth must be a positive integer; got ",teeth))
        assert(is_finite(thickness) && thickness>0, "\nthickness must be greater than zero and finite")
        assert(is_finite(PA) && PA>=0 && PA<90, str("\npressure_angle must be finite and in [0,90) degrees; got ",PA))
        assert(clearance==undef || (is_finite(clearance) && clearance>=0), "\nclearance must be nonnegative and finite")
        assert(is_finite(backlash) && backlash>=0, "\nbacklash must be nonnegative and finite")
        assert(is_finite(helical) && abs(helical)<90, str("\nhelical must be finite and strictly between -90 and 90 degrees; got ",helical))
        assert(is_bool(herringbone), "\nherringbone must be boolean")
        assert(is_finite(profile_shift), "\nprofile_shift must be finite")
        assert(is_finite(gear_travel), "\ngear_travel must be finite");
    trans_pitch = pitch / cos(helical);
    a = _adendum(circ_pitch=pitch, profile_shift=profile_shift);
    d = _dedendum(circ_pitch=pitch, clearance=clearance, profile_shift=profile_shift);
    bottom = is_def(bottom) ?
                 assert(is_finite(bottom) && bottom>d, str("\nbottom must be greater than ",d,"; got ",bottom))
                 bottom
           : is_def(width) ?
                 assert(is_finite(width) && width>a+d, str("\nwidth must be greater than ",a+d,"; got ",width))
                 width - a
           : is_def(backing) ?
                 assert(all_positive([backing]), "\nbacking must be a positive value")
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
    _spec = _gear_spec("rack",pitch/PI,teeth,PA,helical,thickness=thickness,
                           shift=profile_shift,clearance=default(clearance,pitch/PI/4),
                           herringbone=herringbone,two_d=false,family_data=[l]);
    _geom = attach_geom(size=size, anchors=anchors, override=override);
    _pose = _gear_pose(_spec,0,anchor,spin,orient,travel=gear_travel,geom=_geom);
    _gear_place(_pose)
    attachable(anchor,spin,orient,geom=_geom) {
        zrot(_pose[1]) right(_pose[12])
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
        _gear_publish(_spec,_pose) children();
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
    assert(is_undef(_named), "\nToo many positional arguments (only 3 are accepted)")
    let(
        backlash=_gear_backlash(backlash), herringbone=default(herringbone,default($parent_gear_herringbone,false)),
        profile_shift=is_undef(profile_shift)?0:profile_shift,
        gear_travel=is_undef(gear_travel)?0:gear_travel, anchor=is_undef(anchor)?CENTER:anchor,
        spin=is_undef(spin)?0:spin, orient=is_undef(orient)?UP:orient
    )
    let(
        pitch = _inherit_gear_pitch(fname="rack()",circ_pitch=circ_pitch, diam_pitch=diam_pitch, mod=mod),
        PA = _inherit_gear_pa(pressure_angle=pressure_angle),
        helical = _inherit_gear_helical(helical=helical,invert=true,rack=true),
        thickness = _inherit_gear_thickness(thickness=thickness)
    )
    assert(num_defined([backing,bottom,width])<=1,
               "\nspecify only one of backing, bottom, or width")
        assert(is_integer(teeth) && teeth>=1, str("\nteeth must be a positive integer; got ",teeth))
    assert(is_finite(thickness) && thickness>0, "\nthickness must be greater than zero and finite")
    assert(is_finite(PA) && PA>=0 && PA<90, str("\npressure_angle must be finite and in [0,90) degrees; got ",PA))
    assert(clearance==undef || (is_finite(clearance) && clearance>=0), "\nclearance must be nonnegative and finite")
    assert(is_finite(backlash) && backlash>=0, "\nbacklash must be nonnegative and finite")
    assert(is_finite(helical) && abs(helical)<90, str("\nhelical must be finite and strictly between -90 and 90 degrees; got ",helical))
    assert(is_bool(herringbone), "\nherringbone must be boolean")
    assert(is_finite(profile_shift), "\nprofile_shift must be finite")
    assert(is_finite(gear_travel), "\ngear_travel must be finite")
    let(
        trans_pitch = pitch / cos(helical),
        a = _adendum(circ_pitch=pitch, profile_shift=profile_shift),
        d = _dedendum(circ_pitch=pitch, clearance=clearance, profile_shift=profile_shift),
        bottom = is_def(bottom) ?
                     assert(is_finite(bottom) && bottom>d, str("\nbottom must be greater than ",d,"; got ",bottom))
                     bottom
               : is_def(width) ?
                     assert(is_finite(width) && width>a+d, str("\nwidth must be greater than ",a+d,"; got ",width))
                     width - a
               : is_def(backing) ?
                     assert(all_positive([backing]), "\nbacking must be a positive value")
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
            ], style="alt")
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
// See Also: rack(), spur_gear(), spur_gear2d(), bevel_gear(), attach_gear()
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
//   Specify tooth size using `pitch`, `mod`, `circ_pitch`, or `diam_pitch`, or inherit it from a parent spur gear.  
//   For a rack, `pitch=` specifies normal tooth pitch, perpendicular to the tooth lines, and `circ_pitch=` is permitted
//   for consistency and compatibility with other gears.
//   By default the rack has a backing whose height is equal to the height of the teeth.  You can specify a different backing size
//   or you can specify the total width of the rack (from the bottom of the rack to tooth tips) or the
//   bottom point of the rack, which is the distance from the pitch line to the bottom of the rack.
//   .
//   The rack appears with its pitch line on top of the x axis.  The BACK anchor refers to the tips of the teeth and the FRONT
//   anchor refers to the front of the backing.  You can use named anchors to access the roots of the teeth.
//   .
//   You can position gears directly using {{gear_dist()}}, but it may be easier to use
//   {{attach_gear()}}, which positions the gears and aligns the teeth automatically.
//   When using {{attach_gear()}} the only anchors permitted are LEFT, CENTER and RIGHT, which
//   control which end of the rack aligns to the parent gear.  
// Arguments:
//   teeth = Total number of teeth along the rack
//   backing = Distance from bottom of rack to the roots of the rack's teeth.  (Alternative to bottom or width.)  Default: height of rack teeth
//   ---
//   mod = The module of the gear (pitch diameter / teeth)
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  The diametral pitch is a completely different thing than the pitch diameter.
//   pitch/circ_pitch = Tooth pitch perpendicular to the tooth lines.
//   bottom = Distance from rack's pitch line (the x-axis) to the bottom of the rack.  (Alternative to backing or width)
//   width = Distance from base of rack to tips of teeth (alternative to bottom and backing).
//   helical = Angle of the rack teeth away from perpendicular to its length. Inherits to mate with parent when omitted.  Default: 0
//   pressure_angle = Normal pressure angle in degrees. Inherits from the parent when omitted. Default: 20.
//   profile_shift = Profile shift factor for tooth shape.  Profile shift is not inherited. Default: 0
//   backlash = Tooth-thinning backlash along the rack pitch line. Default: $backlash.
//   clearance = Tooth-root clearance. Default: module/4.
//   gear_travel = Translate the rack along its length without moving its anchors or children.  Use {{gear_travel()}} to drive the rack and its children. Default: 0
//   rounding = If true, rack tips and valleys are slightly rounded.  Default: true
//   anchor = As a child of {{attach_gear()}} use LEFT, RIGHT or CENTER to specify end alignment.  Otherwise translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
// Side Effects:
//   See {{attach_gear()}} for reference frames, units, and inheritance details.
//   Sets internal variables for gear inheritance.
//   `$gear_travel` is set to the displacement in model units of the rack resulting from {{gear_spin()}} or {{gear_travel()}} applied to the gear chain root. 
//   `$gear_travel_offset` is set to the local `gear_travel` offset in model units.
//   `$gear_travel_ratio` is set to signed linear gain: (output travel)/(input rotation) for rotational input, or (output travel)/(input travel) for travel input. 
//   `$gear_input` is set to "rotation" (degrees), "travel" (model units), or undef for an undriven chain.
//   `$gear_contact_dir` is set to the engagement direction with the parent in the current child frame, which is always BACK for 2D racks engaged to a parent.
//   `$gear_contact_angle` is set to the corresponding engagement angle, which is always 90 degrees for racks.
//   `$gear_chain_locs` is set to a list of gear center coordinates (pitch-line origins for racks) in the current child frame, with the root gear first and the current gear last.
//   `$gear_chain_axes` is set to a list of shaft-axis unit vectors (`undef` for racks) in the current child frame, with the root gear first and the current gear last.
//   `$gear_rotation` is set to zero.
//   `$gear_angle_offset` is set to zero.
//   `$gear_ratio` is set to zero.
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
    assert(is_undef(_named), "\nToo many positional arguments (only 2 are accepted)")
    let(
        backlash=_gear_backlash(backlash), profile_shift=is_undef(profile_shift)?0:profile_shift,
        gear_travel=is_undef(gear_travel)?0:gear_travel, rounding=is_undef(rounding)?true:rounding,
        anchor=is_undef(anchor)?CENTER:anchor, spin=is_undef(spin)?0:spin
    )
 let(
        pitch = _inherit_gear_pitch(fname="rack2d()",circ_pitch=circ_pitch, diam_pitch=diam_pitch, mod=mod),
        PA = _inherit_gear_pa(pressure_angle=pressure_angle),
        helical = _inherit_gear_helical(helical=helical,invert=true,rack=true),
        mod = module_value(circ_pitch=pitch)
    )
    assert(is_integer(teeth) && teeth>=1, str("\nteeth must be a positive integer; got ",teeth))
    assert(is_finite(PA) && PA>=0 && PA<90, str("\npressure_angle must be finite and in [0,90) degrees; got ",PA))
    assert(clearance==undef || (is_finite(clearance) && clearance>=0), "\nclearance must be nonnegative and finite")
    assert(is_finite(backlash) && backlash>=0, "\nbacklash must be nonnegative and finite")
    assert(is_finite(helical) && abs(helical)<90, str("\nhelical must be finite and strictly between -90 and 90 degrees; got ",helical))
    assert(is_finite(gear_travel), "\ngear_travel must be finite")
    assert(num_defined([width,backing,bottom])<=1, "\nCan define only one of width, backing and bottom")
    let(
        adendum = _adendum(circ_pitch=pitch, profile_shift=profile_shift),
        dedendum = _dedendum(circ_pitch=pitch, clearance=clearance, profile_shift=profile_shift),
        clear = default(clearance, 0.25 * mod),
        bottom = is_def(bottom) ?
                     assert(is_finite(bottom) && bottom>dedendum, str("\nbottom must be greater than ",dedendum,"; got ",bottom))
                     bottom
               : is_def(width) ?
                     assert(is_finite(width) && width>adendum+dedendum, str("\nwidth must be greater than ",adendum+dedendum,"; got ",width))
                     width - adendum
               : is_def(backing) ?
                     assert(all_positive([backing]), "\nbacking must be a positive value")
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
    assert(is_undef(_named), "\nToo many positional arguments (only 2 are accepted)")
 
    let(
        backlash=_gear_backlash(backlash), profile_shift=is_undef(profile_shift)?0:profile_shift,
        gear_travel=is_undef(gear_travel)?0:gear_travel, rounding=is_undef(rounding)?true:rounding,
        anchor=is_undef(anchor)?CENTER:anchor, spin=is_undef(spin)?0:spin
    )
{
    pitch = _inherit_gear_pitch(fname="rack2d()",circ_pitch=circ_pitch, diam_pitch=diam_pitch, mod=mod);
    PA = _inherit_gear_pa(pressure_angle=pressure_angle);
    helical = _inherit_gear_helical(helical=helical,invert=true);
    checks =
        assert(is_integer(teeth) && teeth>=1, str("\nteeth must be a positive integer; got ",teeth))
        assert(is_finite(PA) && PA>=0 && PA<90, str("\npressure_angle must be finite and in [0,90) degrees; got ",PA))
        assert(clearance==undef || (is_finite(clearance) && clearance>=0), "\nclearance must be nonnegative and finite")
        assert(is_finite(backlash) && backlash>=0, "\nbacklash must be nonnegative and finite")
        assert(is_finite(helical) && abs(helical)<90, str("\nhelical must be finite and strictly between -90 and 90 degrees; got ",helical))
        assert(is_finite(gear_travel), "\ngear_travel must be finite")
        assert(num_defined([width,backing,bottom])<=1, "\nCan define only one of width, backing and bottom");
    trans_pitch = pitch / cos(helical);
    a = _adendum(circ_pitch=pitch, profile_shift=profile_shift);
    d = _dedendum(circ_pitch=pitch, clearance=clearance, profile_shift=profile_shift);
    bottom = is_def(bottom) ?
                 assert(is_finite(bottom) && bottom>d, str("\nbottom must be greater than ",d,"; got ",bottom))
                 bottom
           : is_def(width) ?
                 assert(is_finite(width) && width>a+d, str("\nwidth must be greater than ",a+d,"; got ",width))
                 width - a
           : is_def(backing) ?
                 assert(all_positive([backing]), "\nbacking must be a positive value")
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
    _spec = _gear_spec("rack2D",pitch/PI,teeth,PA,helical,thickness=0,
                           shift=profile_shift,clearance=default(clearance,pitch/PI/4),
                           herringbone=false,two_d=true,family_data=[l]);
    _geom = attach_geom(two_d=true, size=size, anchors=anchors, override=override);
    _pose = _gear_pose(_spec,0,anchor,spin,UP,travel=gear_travel,geom=_geom);
    _gear_place(_pose)
    attachable(anchor,spin,geom=_geom) {
        zrot(_pose[1]) right(_pose[12]) polygon(path);
        _gear_publish(_spec,_pose) children();
    }
}
/// Each cutter segment stores [radius0, point0, vector, squared_length,
/// dot(point0,vector), cross(point0,point1), half_angle0, radius1, half_angle1].
/// The tooth is the same sampled
/// profile used by spur_gear(), with a radial extension for crown root clearance.
function _crown_tool(m,np,pa,xp,clearance,extra) =
    let(tooth=_gear_tooth_profile(mod=m,teeth=np,pressure_angle=pa,
                profile_shift=xp,clearance=clearance,backlash=0,helical=0),
        raw=sort([for(p=tooth)if(p.x<=1e-10*m)[norm(p),p]],idx=0),
        half=[for(i=idx(raw))if(i==0 || raw[i][0]>raw[i-1][0]+1e-10*m)raw[i]],
        last=last(half),ra=m*(np/2+1+xp)+extra,
        points=ra>last[0]+1e-10*m?concat(half,[[ra,last[1]*ra/last[0]]]):half)
    assert(len(half)>=2,"\nThe generating pinion has no usable tooth flank; revise mate_teeth or mate_profile_shift")
    [for(i=[0:1:len(points)-2])let(a=points[i][1],b=points[i+1][1],v=b-a)
        [points[i][0],a,v,v*v,a*v,cross(a,b),atan2(-a.x,a.y),points[i+1][0],atan2(-b.x,b.y)]];

function _crown_segment(v,r,lo=0,hi) =
    let(hi=is_undef(hi)?len(v):hi,j=floor((lo+hi)/2))
    hi-lo<=1?lo:r<v[j][0]?_crown_segment(v,r,lo,j):_crown_segment(v,r,j,hi);

/// Half-angle of the actual cutter polygon at radius r and its derivative.
/// Intersect the circle with the segment; angular interpolation would change
/// the pinion profile and can leave interference even with a finely sampled loft.
function _crown_width(r,P) =
    let(v=P[5])
    r<v[0][0]?[180/P[2],0]:
    let(s=v[_crown_segment(v,r)],D=max(0,s[4]*s[4]+s[3]*(r*r-s[1]*s[1])),
        t=constrain((-s[4]+sqrt(D))/s[3],0,1),p=s[1]+t*s[2])
    [atan2(-p.x,p.y),s[5]/(r*max(1e-12*P[0]*P[0],sqrt(D)))];

/// At world polar angle t from Y+, the pinion cross-section is
/// [r*sin(t), axis_height-z]. Eliminate its rotation using the tooth-count ratio.
/// The exposed swept tooth-space boundary is the maximum over the whole orbit.
/// Work on positive orbit angles, evaluating both mirrored candidates. Within
/// each interval the cutter segment is fixed, so derivative searches need no
/// profile lookup or angle calculation. Cutter corners remain explicit probes.
/// Walk the already ordered cutter segments. Subdivide at the same uniform
/// orbit stations as before, without sorting or searching for their segments.
function _crown_cut_terms(t,r,h,k,s) =
    let(st=sin(t),ct=cos(t),rho2=h*h+r*r*st*st,
        root=is_undef(s)?1:sqrt(max(0,s[4]*s[4]+s[3]*(rho2-s[1]*s[1]))))
    [1-r*h*ct/(k*rho2),is_undef(s)?0:
        s[5]*r*r*st*ct/(k*rho2*max(1e-30,root))];

/// Derivative and its rate of change per radian for a safeguarded Newton step.
function _crown_cut_slope_pair(t,r,h,k,s,side) =
    let(st=sin(t),ct=cos(t),rr=r*r,sc=st*ct,y=h*h+rr*st*st,
        b=1-r*h*ct/(k*y),db=r*h*st/(k*y)*(1+2*rr*ct*ct/y),
        g=is_undef(s)?1:max(1e-30,s[4]*s[4]+s[3]*(y-s[1]*s[1])),
        f=is_undef(s)?0:s[5]*rr/(k*y*sqrt(g)))
    [side*b+f*sc,
     side*db+f*(ct*ct-st*st-2*rr*sc*sc/y-(is_undef(s)?0:s[3]*rr*sc*sc/g))];

function _crown_cut_stationary(lo,hi,r,h,k,s,side,n=40,t) =
    let(t=is_undef(t)?(lo+hi)/2:t,d=_crown_cut_slope_pair(t,r,h,k,s,side))
    n==0 || hi-lo<1e-10 || abs(d[0])<1e-12?t:
    let(a=d[0]>0?t:lo,b=d[0]>0?hi:t,
        candidate=d[1]==0?undef:t-d[0]/d[1]*180/PI,
        next=is_finite(candidate) && candidate>a && candidate<b?candidate:(a+b)/2)
    _crown_cut_stationary(a,b,r,h,k,s,side,n-1,next);

function _crown_segment_angle(rho,s,np) =
    is_undef(s)?180/np:
    let(D=max(0,s[4]*s[4]+s[3]*(rho*rho-s[1]*s[1])),
        u=constrain((-s[4]+sqrt(D))/s[3],0,1),p=s[1]+u*s[2])
    atan2(-p.x,p.y);

function _crown_cut_candidate(t,r,h,k,P,s,side=0) =
    let(x=r*sin(t),w=_crown_segment_angle(sqrt(h*h+x*x),s,P[2])/k,
        phase=t-atan2(x,h)/k)
    // side=0 evaluates the larger of the positive/negative orbit candidates.
    w+(side==0?abs(phase):side*phase);

function _crown_cut_piece(lo,hi,r,h,k,P,s,step) =
    let(first=floor(lo/step)+1,last=ceil(hi/step)-1,
        ts=[lo,for(j=[first:1:last])if(j*step>lo+1e-10 && j*step<hi-1e-10)j*step,hi],
        vals=[for(i=[0:len(ts)-1])
            // The segment endpoints already store their half angles.
            let(t=ts[i],corner=is_def(s) && ((i==0 && s[0]>h) || i==len(ts)-1),
                rho=corner?(i==0?s[0]:s[7]):sqrt(h*h+pow(r*sin(t),2)),
                x=sqrt(max(0,rho*rho-h*h)),
                w=corner?(i==0?s[6]:s[8]):_crown_segment_angle(rho,s,P[2]))
            w/k+abs(t-atan2(x,h)/k)],
        roots=[for(i=[0:1:len(ts)-2])
            let(eps=min(1e-8,(ts[i+1]-ts[i])/4),a=ts[i]+eps,b=ts[i+1]-eps,
                left=_crown_cut_terms(a,r,h,k,s),right=_crown_cut_terms(b,r,h,k,s))
            for(side=[-1,1])
            if(b>a && side*left[0]+left[1]>0 && side*right[0]+right[1]<0)
                _crown_cut_candidate(_crown_cut_stationary(a,b,r,h,k,s,side),r,h,k,P,s,side)])
    max(concat(vals,roots));

/// Balanced radial bounds for the fixed cutter profile. A node stores
/// [radius0, radius1, maximum_half_angle, segment_index] at a leaf, or
/// [radius0, radius1, maximum_half_angle, left_child, right_child].
function _crown_cut_tree(v,lo=0,hi) =
    let(hi=is_undef(hi)?len(v):hi)
    hi-lo==1?[v[lo][0],v[lo][7],max(v[lo][6],v[lo][8]),lo]:
    let(mid=floor((lo+hi)/2),a=_crown_cut_tree(v,lo,mid),b=_crown_cut_tree(v,mid,hi))
    [a[0],b[1],max(a[2],b[2]),a,b];

function _crown_cut_search(node,best,r,h,k,P,step,tc,ac) =
    node[1]<=h?best:
    let(xa=sqrt(max(0,node[0]*node[0]-h*h)),xb=sqrt(max(0,node[1]*node[1]-h*h)),
        a=node[0]<=h?0:asin(xa/r),b=asin(xb/r),
        aa=a==0?0:abs(a-atan2(xa,h)/k),ab=abs(b-atan2(xb,h)/k),
        bound=node[2]/k+max(aa,ab,tc>a && tc<b?ac:0))
    bound<best-1e-12 || b<=a?best:
    len(node)==4?max(best,_crown_cut_piece(a,b,r,h,k,P,P[5][node[3]],step)):
    let(left=_crown_cut_search(node[3],best,r,h,k,P,step,tc,ac))
    _crown_cut_search(node[4],left,r,h,k,P,step,tc,ac);

function _crown_cut(r,z,P,ns) =
    let(h=P[3]-z,k=P[1]/P[2],tmax=asin(sqrt(max(0,P[4]*P[4]-h*h))/r),
        // Only explicit backlash changes the nominal flank position.
        allowance=P[10],v=P[5])
    tmax<1e-9?last(v)[8]/k+allowance:
    let(step=tmax/ceil(ns/2),
        // A(t)=t-atan(r*sin(t)/h)/k is convex on the positive orbit.
        // Its only possible interior extremum is this minimum. The cutter
        // angle on a straight segment lies between its endpoint angles.
        // Together these give an upper bound for each segment's contribution.
        tc=r<=k*h?0:acos(constrain(2*k*(h*h+r*r)/(r*(h+sqrt(h*h+4*k*k*(h*h+r*r)))),0,1)),
        ac=abs(tc-atan2(r*sin(tc),h)/k),
        endphase=abs(tmax-atan2(r*sin(tmax),h)/k),
        seed=max(_crown_width(h,P)[0]/k,last(v)[8]/k+endphase,
                 tc>0 && tc<tmax?_crown_width(sqrt(h*h+pow(r*sin(tc),2)),P)[0]/k+ac:0),
        best=h<v[0][0]?max(seed,_crown_cut_piece(0,asin(sqrt(v[0][0]*v[0][0]-h*h)/r),r,h,k,P,undef,step)):seed)
    _crown_cut_search(P[18],best,r,h,k,P,step,tc,ac)+allowance;


function _crown_land(r,z,P,ns) = 2*r*sin(180/P[1]-_crown_cut(r,z,P,ns));
function _crown_tip(r,P,ns,lo,hi,n=32) =
    n==0 || hi-lo<1e-7*P[0]?lo:
    let(mid=(lo+hi)/2)
    _crown_land(r,mid,P,ns)>=P[16]
      ?_crown_tip(r,P,ns,mid,hi,n-1):_crown_tip(r,P,ns,lo,mid,n-1);

/// P = [module, crown_teeth, mate_teeth, axis_height, cutter_radius, segments,
///      inner_radius, outer_radius, root_z, nominal_tip_z, backlash_half_angle,
///      pressure_angle, profile_shift, mate_profile_shift, clearance,
///      mate_clearance, min_tip, mesh_tol, cutter_bounds].
function _crown_arguments(teeth,mate_teeth,face_width,pressure_angle,profile_shift,
                          mate_profile_shift,clearance,mate_clearance,backlash,min_tip,
                          mesh_tol,mod,circ_pitch,diam_pitch) =
    let(m=_inherit_gear_pitch("crown_gear()",circ_pitch,diam_pitch,mod)/PI,
        parent=_gear_is_circular(default($parent_gear_type,"")),
        np=default(mate_teeth,parent?$parent_gear_teeth:undef),
        pa=_inherit_gear_pa(pressure_angle),x=default(profile_shift,0),
        xp=default(mate_profile_shift,parent?$parent_gear_profile_shift:"auto"),
        cp=default(mate_clearance,parent?default($parent_gear_clearance,m/4):m/4),
        c=default(clearance,m/4),fw=default(face_width,parent?default($parent_gear_thickness,10):10),
        ba=_gear_backlash(backlash),nt=default(min_tip,.4*m),tol=default(mesh_tol,m/100))
    assert(is_int(teeth) && teeth>=4,"\nteeth must be an integer at least 4")
    assert(is_int(np) && np>=4,"\nSupply mate_teeth (an integer at least 4), or inherit it from a spur parent")
    assert(is_finite(pa) && pa>=0 && pa<90,"\npressure_angle must be at least zero and less than 90")
    assert(is_finite(x),"\nprofile_shift must be finite")
    assert(is_finite(c) && c>=0 && is_finite(cp) && cp>=0,
           "\nclearance and mate_clearance must be nonnegative and finite")
    assert(is_finite(fw) && fw>0,"\nface_width must be positive and finite")
    assert(is_finite(nt) && nt>0,"\nmin_tip must be positive and finite")
    assert(is_finite(tol) && tol>0 && tol<=m/4,"\nmesh_tol must be positive and no greater than module/4")
    assert(is_undef($gear_steps) || (is_int($gear_steps) && $gear_steps>=4),
           "\n$gear_steps must be an integer at least 4")
    let(xp=auto_profile_shift(teeth=np,pressure_angle=pa,profile_shift=xp),
        h=m*(np/2+x+xp),ra=m*(np/2+1+xp)+c,ri=m*teeth/2,
        root=m*(x-1)-c,top=m*(1+x))
    assert(1+x>0 && 1+c/m-x>0,"\nprofile_shift must leave positive addendum and dedendum")
    assert(h>0 && h-top>0,"\nThe pinion is too small for these profile shifts")
    assert(ri>sqrt(max(0,ra*ra-pow(h-top,2))),
           "\nThe generating pinion reaches across the crown axis; increase teeth or reduce mate_teeth")
    let(tool=_crown_tool(m,np,pa,xp,cp,c))
    [m,teeth,np,h,ra,tool,ri,ri+fw,root,top,
     ba/(2*ri)*180/PI,pa,x,xp,c,cp,nt,tol,_crown_cut_tree(tool)];

/// The nominal flank and minimum-tip height do not depend on mesh_tol.
/// A frame stores [radius, tip_height, ascending_flank_points, transition_height].
/// Shared radial rows and profile parameters keep the mesh indexed without merging.
/// Each profile follows the pinion-tip transition; quadratic spacing resolves the root.
function _crown_height(r,P,ns) =
    assert(_crown_land(r,P[8],P,ns)>P[16],
           "\nmin_tip leaves no tooth at the root; reduce min_tip or backlash, or revise the gear dimensions")
    let(top=_crown_land(r,P[9],P,ns)>=P[16]?P[9]:_crown_tip(r,P,ns,P[8],P[9]))
    assert(top>P[8]+1e-6*P[0],"\nmin_tip leaves no usable tooth height; reduce face_width or min_tip")
    top;

/// The extended pinion tip traces the root branch of the generated envelope.
function _crown_root_cut(r,z,P) =
    let(h=P[3]-z,k=P[1]/P[2],x=sqrt(max(0,P[4]*P[4]-h*h)),t=asin(x/r))
    last(P[5])[8]/k+abs(t-atan2(x,h)/k)+P[10];

/// Locate where the rest of the envelope overtakes the pinion-tip trace.
/// Following this moving boundary avoids a staircase of height subdivisions.
/// This is a sampling landmark, so locating it to a small fraction of mesh_tol
/// is sufficient; every generated point still uses the full nominal envelope.
function _crown_transition(r,top,P,ns,lo,hi,n=28) =
    is_undef(lo)?(_crown_cut(r,top,P,ns)<=_crown_root_cut(r,top,P)+1e-10?top:
                  _crown_transition(r,top,P,ns,P[8],top,n)):
    n==0 || hi-lo<P[17]/64?(lo+hi)/2:
    let(mid=(lo+hi)/2)
    _crown_cut(r,mid,P,ns)>_crown_root_cut(r,mid,P)+1e-10?
        _crown_transition(r,top,P,ns,lo,mid,n-1):
        _crown_transition(r,top,P,ns,mid,hi,n-1);

function _crown_sample_z(u,root,top,transition) =
    // Keep both sampling bands nonzero when the landmark reaches the tip.
    // This only selects vertex heights; it does not move the nominal surface.
    let(transition=min(transition,top-(top-root)/1024))
    u<=.5?lerp(root,transition,4*u*u):lerp(transition,top,2*u-1);

function _crown_point(r,u,top,P,ns,transition) =
    let(transition=is_undef(transition)?_crown_transition(r,top,P,ns):transition,
        z=_crown_sample_z(u,P[8],top,transition))
    cylindrical_to_xyz(r,90-180/P[1]+_crown_cut(r,z,P,ns),z);

function _crown_frame(r,us,P,ns) =
    let(top=_crown_height(r,P,ns),transition=_crown_transition(r,top,P,ns))
    [r,top,[for(u=us)_crown_point(r,u,top,P,ns,transition)],transition];

function _crown_interleave(v) =
    [for(i=idx(v))each [v[i],if(i<len(v)-1)(v[i]+v[i+1])/2]];

/// Reuse every existing vertex and tip height when probing a finer grid.
function _crown_probe_index(values,x,lo=0,hi) =
    let(hi=is_undef(hi)?len(values):hi,j=floor((lo+hi)/2))
    hi-lo<=1 ? (values[lo]==x?lo:-1) :
    x<values[j]?_crown_probe_index(values,x,lo,j):_crown_probe_index(values,x,j,hi);

function _crown_probe_grid(frames,us,P,ns,cache,cache_us) =
    let(uu=_crown_interleave(us),rr=_crown_interleave(column(frames,0)),
        cr=column(cache,0),ir=[for(r=rr)_crown_probe_index(cr,r)],
        iu=[for(u=uu)_crown_probe_index(cache_us,u)])
    [for(i=idx(rr))let(top=ir[i]<0?_crown_height(rr[i],P,ns):cache[ir[i]][1],
        transition=ir[i]<0?_crown_transition(rr[i],top,P,ns):cache[ir[i]][3])
        [rr[i],top,[for(j=idx(uu))ir[i]>=0 && iu[j]>=0?cache[ir[i]][2][iu[j]]:
                           _crown_point(rr[i],uu[j],top,P,ns,transition)],transition]];

/// The same diagonal is used for both mirrored flanks and for their probes.
/// Corners a,b,c,d run from (r0,u0) to (r1,u0), (r1,u1), (r0,u1).
function _crown_short_diagonal(a,b,c,d) = norm(d-b)<norm(a-c)+_EPSILON;

/// Measure geometric distance, rather than motion along the parameterization.
/// Near the root a flank can turn almost horizontal; comparing corresponding
/// parameter positions would over-refine a nearly straight segment there.
function _crown_edge_distance(p,a,b) =
    let(v=b-a,q=v*v)
    norm(p-(q==0?a:a+constrain((p-a)*v/q,0,1)*v));

function _crown_triangle_distance(p,a,b,c) =
    let(n=cross(b-a,c-a),nn=n*n,
        inside=nn>0 && cross(b-a,p-a)*n>=-1e-12*nn &&
                       cross(c-b,p-b)*n>=-1e-12*nn && cross(a-c,p-c)*n>=-1e-12*nn)
    inside?abs((p-a)*n)/sqrt(nn):
        min(_crown_edge_distance(p,a,b),_crown_edge_distance(p,b,c),_crown_edge_distance(p,c,a));

function _crown_patch_distance(p,a,b,c,d,short) =
    short?min(_crown_triangle_distance(p,a,b,d),_crown_triangle_distance(p,b,c,d)):
          min(_crown_triangle_distance(p,a,b,c),_crown_triangle_distance(p,a,c,d));

/// Reuse a patch's error only when both radial and height interval endpoints
/// are identical. Boundary curves and the selected triangles then also agree.
function _crown_mid_errors(fine,us,cache) =
    let(nu=len(us),
        ri=is_undef(cache)?[]:[for(i=[0:1:(len(fine)-3)/2])
            let(j=_crown_probe_index(cache[0],fine[2*i][0]))
            j>=0 && j+1<len(cache[0]) && cache[0][j+1]==fine[2*i+2][0]?j:-1],
        ui=is_undef(cache)?[]:[for(i=[0:1:nu-2])
            let(j=_crown_probe_index(cache[1],us[i]))
            j>=0 && j+1<len(cache[1]) && cache[1][j+1]==us[i+1]?j:-1])
    [for(i=[0:1:(len(fine)-3)/2])
        [for(j=[0:1:nu-2])
            is_def(cache) && ri[i]>=0 && ui[j]>=0?cache[2][ri[i]][ui[j]]:
            let(a=fine[2*i][2][2*j],b=fine[2*i+2][2][2*j],
                c=fine[2*i+2][2][2*j+2],d=fine[2*i][2][2*j+2],
                short=_crown_short_diagonal(a,b,c,d),
                r0=fine[2*i+1][2][2*j],r1=fine[2*i+1][2][2*j+2],
                u0=fine[2*i][2][2*j+1],u1=fine[2*i+2][2][2*j+1],
                // The root, tip and two radial boundaries are feature curves.
                // Interior grid lines only need to approximate the surface.
                rerr=max(j==0?_crown_edge_distance(r0,a,b):_crown_patch_distance(r0,a,b,c,d,short),
                         j==nu-2?_crown_edge_distance(r1,c,d):_crown_patch_distance(r1,a,b,c,d,short)),
                uerr=max(i==0?_crown_edge_distance(u0,a,d):_crown_patch_distance(u0,a,b,c,d,short),
                         i==(len(fine)-3)/2?_crown_edge_distance(u1,b,c):_crown_patch_distance(u1,a,b,c,d,short)),
                p=fine[2*i+1][2][2*j+1],
                center=_crown_patch_distance(p,a,b,c,d,short))
            [rerr,uerr,center]]];

/// Edge probes alone can miss curvature inside a triangle. Check both triangle
/// centroids as well. At each centroid use its height and the corresponding
/// radius on the generated flank, avoiding any dependence on parameter speed.
function _crown_center_errors(frames,us,P,ns) =
    [for(i=[0:1:len(frames)-2])
        let(f=frames[i],g=frames[i+1],rr=[lerp(f[0],g[0],1/3),lerp(f[0],g[0],2/3)])
        [for(j=[0:1:len(us)-2])
            let(a=f[2][j],b=g[2][j],c=g[2][j+1],d=f[2][j+1],
                short=_crown_short_diagonal(a,b,c,d),
                p=(short?(a+b+d):(a+c+d))/3,q=(short?(b+c+d):(a+b+c))/3,
                pp=cylindrical_to_xyz(rr[0],90-180/P[1]+_crown_cut(rr[0],p.z,P,ns),p.z),
                qq=cylindrical_to_xyz(rr[1],90-180/P[1]+_crown_cut(rr[1],q.z,P,ns),q.z))
            short?max(_crown_triangle_distance(pp,a,b,d),_crown_triangle_distance(qq,b,c,d)):
                  max(_crown_triangle_distance(pp,a,c,d),_crown_triangle_distance(qq,a,b,c))]];

/// mesh_tol is a sampled approximation target, not a certified global bound.
/// Split whole rows/columns to avoid cracks and T junctions, retaining probes
/// selected as new vertices. Refine the two directions independently when the
/// edge errors identify the direction responsible for a bad diagonal probe.
function _crown_refine(frames,us,P,ns,n=0,cache,cache_us,error_cache) =
    let(cache=is_undef(cache)?frames:cache,cache_us=is_undef(cache_us)?us:cache_us,
        fine=_crown_probe_grid(frames,us,P,ns,cache,cache_us),
        errors=_crown_mid_errors(fine,us,error_cache),tol=P[17],
        mids_ok=max([for(row=errors,e=row)max(e)])<=tol,
        centers=mids_ok?_crown_center_errors(frames,us,P,ns):[],
        center_ok=mids_ok && max(flatten(centers))<=tol,
        split_r=[for(i=idx(errors))any([for(j=idx(errors[i]))
            let(e=errors[i][j]) e[0]>tol || (e[2]>tol && e[0]>=e[1]) || (mids_ok && centers[i][j]>tol)])],
        split_u=[for(j=idx(errors[0]))any([for(i=idx(errors))
            let(e=errors[i][j]) e[1]>tol || (e[2]>tol && e[1]>=e[0]) || (mids_ok && centers[i][j]>tol)])])
    center_ok ? [frames,us,max(concat([for(row=errors,e=row)max(e)],flatten(centers))),n] :
    assert(n<12,"\nCrown mesh refinement did not converge; increase mesh_tol or report the parameter set")
    let(ir=[for(i=idx(frames))each [2*i,if(i<len(frames)-1 && split_r[i])2*i+1]],
        iu=[for(j=idx(us))each [2*j,if(j<len(us)-1 && split_u[j])2*j+1]],
        uu=_crown_interleave(us),
        next=[for(i=ir)[fine[i][0],fine[i][1],[for(j=iu)fine[i][2][j]],fine[i][3]]])
    assert(len(ir)*len(iu)<100000,"\nCrown mesh refinement is too large; increase mesh_tol")
    _crown_refine(next,[for(j=iu)uu[j]],P,ns,n+1,fine,uu,[column(frames,0),us,errors]);

function _crown_section(frame,P,na,ns) =
    let(v=frame[2],np=len(v)-1,period=360/P[1],
        b=atan2(v[0].y,v[0].x)-(90-period/2),
        refz=min(frame[1],P[12]*P[0]),refwidth=_crown_land(frame[0],refz,P,ns))
    assert(all([for(p=v)p.z>=refz || 2*p.x+1e-6*P[0]>=refwidth]),
           str("\nGenerated crown tooth has an undercut neck at radius ",frame[0],
               ". Increase teeth, reduce mate_teeth, or revise mate_profile_shift."))
    [[each v,for(p=reverse(v))[-p.x,p.y,p.z],
      for(j=[1:na-1])cylindrical_to_xyz(frame[0],90+period/2-b+2*b*j/na,P[8])],frame[1]];

/// Explicit flank connectivity makes the tested triangles and delivered mesh
/// agree exactly, including the mirror on the descending flank.
function _crown_skin(rows,N,np,nr) =
    let(nc=len(rows[0]),vertices=flatten(rows),
        toothfaces=[for(i=[0:1:len(rows)-2],j=[0:1:nr-1])each
            let(k=j%nr,a=i*nc+j,b=(i+1)*nc+j,
                c=(i+1)*nc+(j+1)%nc,d=i*nc+(j+1)%nc,
                // Mirroring reverses the order of the flank's columns.
                short=k>=np+1 && k<=2*np ?
                    !_crown_short_diagonal(vertices[d],vertices[c],vertices[b],vertices[a]) :
                    _crown_short_diagonal(vertices[a],vertices[b],vertices[c],vertices[d]))
            short?[[a,d,b],[b,d,c]]:[[a,c,b],[a,d,c]]],
        faces=[for(k=[0:N-1],f=toothfaces)[for(v=f)v+k*nr-(v%nc+k*nr>=nc?nc:0)]])
    [vertices,faces];

function _crown_build(P,slices,nsearch) =
    assert(is_int(slices) && slices>=2,"\nslices must be an integer at least 2")
    assert(is_int(nsearch) && nsearch>=8,"\nsearch_steps must be an integer at least 8")
    let(us=lerpn(0,1,9),frames=[for(r=lerpn(P[6],P[7],slices))_crown_frame(r,us,P,nsearch)],
        refined=_crown_refine(frames,us,P,nsearch),np=len(refined[1])-1,
        N=P[1],na=max(2,ceil(360/N/(2*acos(max(-1,1-P[17]/P[7]))))),
        sections=[for(f=refined[0])_crown_section(f,P,na,nsearch)],
        rotations=[for(k=[0:N-1])[cos(360*k/N),sin(360*k/N)]],
        rows=[for(s=sections)[for(q=rotations,p=s[0])
            [q.x*p.x-q.y*p.y,q.y*p.x+q.x*p.y,p.z]]],
        nr=len(sections[0][0]),nc=N*nr,
        roots=[for(k=[0:N-1])each [k*nr,k*nr+2*np+1,for(j=[2*np+2:nr-1])k*nr+j]],
        skin=_crown_skin(rows,N,np,nr))
    [skin,_wfg_tooth_cap(N,np,nr,0,true),_wfg_tooth_cap(N,np,nr,(len(rows)-1)*nc),roots,sections,
     [len(rows),np,refined[2],refined[3]]];


function _crown_body(P,data,backing,bottom,thickness) =
    let(top=max([for(s=data[4])s[1]]),root=P[8],
        bot=num_defined([backing,bottom,thickness])==0?2*root-P[9]:
            is_def(backing)?root-backing:is_def(bottom)?-bottom:top-thickness)
    assert(num_defined([backing,bottom,thickness])<=1,"\nSpecify only one of backing, bottom or thickness")
    assert(is_finite(bot) && bot<root,"\nBacking must leave positive material below the tooth roots")
    [_gear_face_body(data,root,bot),bot,top];

function _crown_geom(P,body) =
    attach_geom(r=P[7],h=body[2]-body[1],cp=[0,0,(body[1]+body[2])/2],
        override=[[CENTER,[[0,0,0],undef,undef]]],
        anchors=[named_anchor("pitchplane",[0,0,0]),named_anchor("root",[0,0,P[8]])]);


// Function&Module: crown_gear()
// Synopsis: Creates a crown gear that can mesh with a spur gear.
// SynTags: Geom, VNF
// Topics: Gears, Parts
// See Also: rack(), rack2d(), spur_gear(), spur_gear2d(), bevel_pitch_angle(), bevel_gear(), attach_gear()
// Usage: As a Module
//   crown_gear(mod=|circ_pitch=|diam_pitch=, teeth, [mate_teeth], [face_width], [backing=], [bottom=], [thickness=], [mate_profile_shift=], [mate_clearance=], [min_tip=], [mesh_tol=], [search_steps=], [pressure_angle=], [clearance=], [backlash=], [profile_shift=], [slices=], [anchor=], [spin=], [orient=], [gear_spin=]) [ATTACHMENTS];
// Usage: As a Function
//   vnf = crown_gear(mod=|circ_pitch=|diam_pitch=, teeth, [mate_teeth], [face_width], [backing=], [bottom=], [thickness=], [mate_profile_shift=], [mate_clearance=], [min_tip=], [mesh_tol=], [search_steps=], [pressure_angle=], [clearance=], [backlash=], [profile_shift=], [slices=], [anchor=], [spin=], [orient=], [gear_spin=]);
// Description:
//   Creates a crown gear, a face gear designed to mate with a (non-helical) spur gear with a specific number of teeth.
//   Specify tooth size using `mod`, `circ_pitch`, or `diam_pitch`, or inherit it from a parent gear. 
//   Supply `mate_teeth=`, or inherit it from a spur gear parent. The pinion's profile shift and root clearance
//   must match `mate_profile_shift` and `mate_clearance`. These values inherit from a spur gear parent if you don't specify them.
//   .
//   The `min_tip=` parameter sets the minimum tooth tip width to avoid sharp teeth, and
//   `mesh_tol=`, which defaults to `mod/100`, controls the mesh quality, with smaller values giving a finer mesh.
//   The `slices=` parameter sets a minimum number of radial slices, and `$gear_steps` 
//   controls the generating tooth profile.  The `search_steps` parameter controls the number of search steps used for internal
//   estimation and should usually be left at its default unless you suspect convergence issues. Normally leave `slices` and `$gear_steps` at their defaults and adjust only `mesh_tol` to adjust
//   the mesh refinement.  
//   .
//   The module `crown_gear()` gives a crown gear in the XY plane, centered on the origin, with one tooth
//   centered on the positive Y axis.  The crown gear will have the pitch circle of the teeth at Z=0 by default.
//   The inner radius of the crown teeth can be calculated with the `pitch_radius()` function, and the outer
//   radius of the teeth is `face_width=` more than that.
//   .
//   You can position gears directly using {{gear_dist()}} (treating the crown as a rack), but it may be easier to use
//   {{attach_gear()}}, which positions the gears and aligns the teeth automatically.
// Arguments:
//   teeth = Number of teeth.
//   mate_teeth = Number of teeth on the matching spur gear.  Inherits from parent if available.
//   face_width = Radial width of the toothed surface. Default: inherited from thickness of spur parent if available, 10 otherwise.
//   ---
//   mod = The module of the gear (pitch diameter / teeth)
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  The diametral pitch is a completely different thing than the pitch diameter.
//   circ_pitch = Normal circular pitch.
//   backing = Distance from the bottom to the tooth roots; alternative to bottom or thickness. If none is given, the backing equals the full tooth height.
//   bottom = Distance from crown's pitch plane (Z=0) to the bottom of the crown gear.  (Alternative to backing or thickness)
//   thickness = Distance from base of crown gear to tips of teeth (alternative to bottom and backing).
//   pressure_angle = Normal pressure angle in degrees. Inherits from the parent when omitted. Default: 20.
//   clearance = Clearance gap at the bottom of the inter-tooth valleys.  Default: module/4
//   backlash = Gap between two meshing teeth, in the direction along the circumference of the pitch circle.  Default: $backlash
//   profile_shift = Profile shift factor x. Profile shift is not inherited. Default: 0
//   slices = Minimum number of radial sections.  Default: 10.
//   mate_profile_shift = Matching pinion profile shift, or "auto". Default: inherited from a spur parent, otherwise automatic as in spur_gear().
//   mate_clearance = Matching pinion root clearance. Default: inherited from a spur parent, otherwise module/4.
//   min_tip = Minimum width of tooth tips.  Default: 0.4*module.
//   mesh_tol = Mesh tolerance in model units.  Default: module/100
//   $gear_steps = Resolution of the generating spur gear.  Default: 16
//   search_steps = Number of search intervals used internally, at least 8. Adjust only when investigating numerical issues.  Default: 16.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top toward, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   gear_spin = Rotates the gear around its center by the given number of degrees without affecting any children. Use {{gear_spin()}} to drive the gear and its children.  Default: 0
// Side Effects:
//   See {{attach_gear()}} for reference frames, units, and inheritance details.
//   Sets internal variables for gear inheritance.
//   `$gear_rotation` is set to the total gear rotation resulting from {{gear_spin()}} or {{gear_travel()}} applied to a gear chain root.
//   `$gear_angle_offset` is set to the angular tooth-alignment offset in degrees, including meshing alignment and local `gear_spin`.
//   `$gear_ratio` is set to signed angular gain: (output degrees)/(input degrees) for rotational input, or (output degrees)/(input travel) for travel input in model units.
//   `$gear_input` is set to "rotation" (degrees), "travel" (model units), or undef for an undriven chain.
//   `$gear_contact_dir` is set to the nominal engagement direction with the parent in the current child frame.
//   `$gear_contact_angle` is set to the corresponding engagement angle in degrees in the current child frame.
//   `$gear_chain_locs` is set to a list of gear center coordinates (pitch-line origins for racks) in the current child frame, with the root gear first and the current gear last.
//   `$gear_chain_axes` is set to a list of shaft-axis unit vectors (`undef` for racks) in the current child frame, with the root gear first and the current gear last.
//   `$gear_travel` is set to zero.
//   `$gear_travel_offset` is set to zero.
//   `$gear_travel_ratio` is set to zero.
// Example:
//    crown_gear(mod=1, teeth=40, mate_teeth=17, backing=3, face_width=5, pressure_angle=20);
// Example:
//   mod=1; cteeth=40; pteeth=17; backing=3; PA=20; face=5;
//   cpr = pitch_radius(mod=mod, teeth=cteeth);
//   ppr = pitch_radius(mod=mod, teeth=pteeth);
//   crown_gear(mod=mod, teeth=cteeth, mate_teeth=pteeth, mate_profile_shift=0, backing=backing,
//             face_width=face, pressure_angle=PA);
//   back(cpr+face/2)
//     up(ppr)
//       spur_gear(mod=mod, teeth=pteeth,
//           pressure_angle=PA, thickness=face,
//           orient=BACK, gear_spin=180/pteeth,
//           profile_shift=0);
function crown_gear(
    teeth, mate_teeth, face_width, _named, mod, circ_pitch, diam_pitch,
    backing, bottom, thickness, pressure_angle, clearance, backlash, profile_shift,
    slices, anchor, spin, orient, gear_spin, mate_profile_shift, mate_clearance,
    min_tip, mesh_tol, search_steps
) =
    assert(is_undef(_named), "\nToo many positional arguments (only 3 are accepted)")
    let(P=_crown_arguments(teeth,mate_teeth,face_width,pressure_angle,profile_shift,
                          mate_profile_shift,clearance,mate_clearance,backlash,min_tip,
                          mesh_tol,mod,circ_pitch,diam_pitch),
        data=_crown_build(P,default(slices,10),default(search_steps,16)),
        body=_crown_body(P,data,backing,bottom,thickness),
        phase=default(gear_spin,0))
    assert(is_finite(phase),"\ngear_spin must be finite")
    reorient(default(anchor,CENTER),default(spin,0),default(orient,UP),geom=_crown_geom(P,body),
             p=zrot(phase,p=body[0]));
module crown_gear(
    teeth, mate_teeth, face_width, _named, mod, circ_pitch, diam_pitch,
    backing, bottom, thickness, pressure_angle, clearance, backlash, profile_shift,
    slices, anchor, spin, orient, gear_spin, mate_profile_shift, mate_clearance,
    min_tip, mesh_tol, search_steps
)
    assert(is_undef(_named), "\nToo many positional arguments (only 3 are accepted)")
    let(anchor=default(anchor,CENTER),spin=default(spin,0),orient=default(orient,UP),gear_spin=default(gear_spin,0))
{
    P=_crown_arguments(teeth,mate_teeth,face_width,pressure_angle,profile_shift,
                       mate_profile_shift,clearance,mate_clearance,backlash,min_tip,
                       mesh_tol,mod,circ_pitch,diam_pitch);
    data=_crown_build(P,default(slices,10),default(search_steps,16));
    body=_crown_body(P,data,backing,bottom,thickness);
    _geom=_crown_geom(P,body);
    _spec=_gear_spec("crown",P[0],P[1],P[11],thickness=body[2]-body[1],shift=P[12],
                     clearance=P[14],family_data=[P[7]-P[6],P[2],P[13],P[15],body[1],body[2]]);
    _pose=_gear_pose(_spec,gear_spin,anchor,spin,orient,geom=_geom);
    assert(is_finite(gear_spin),"\ngear_spin must be finite");
    _gear_place(_pose)
    attachable(anchor,spin,orient,geom=_geom) {
        zrot(_pose[1])vnf_polyhedron(body[0],convexity=12);
        _gear_publish(_spec,_pose)children();
    }
}


/// The current bevel loft uses the actual-count planar spur profile, not a
/// virtual back-cone profile. Its shift estimate must use that same count.
/// Keep automatic selection independent of per-member backlash, clearance,
/// backing and tessellation so separately constructed mates agree exactly.
function _bevel_min_profile_shift(teeth,pa) = 1-teeth*pow(sin(pa),2)/2;
/// Full-height nominal tip chord in units of module, before backlash.
/// A negative result means the involute flanks have crossed below the tip.
function _bevel_tip_land(teeth,pa,x) =
    let(r=teeth/2, rb=r*cos(pa), ra=r+1+x)
    ra<=rb || ra<=0 ? -1 :
    let(aa=acos(rb/ra), half=(PI/2+2*x*tan(pa))/(2*r)+_invol(pa)-_invol(aa))
    2*ra*sin(half*180/PI);
/// Preserve a pre-existing narrow tip at zero shift; correction must not
/// worsen it. Otherwise retain at least 0.2 module of nominal top land.
function _bevel_shift_tip_ok(teeth,pa,x) =
    _bevel_tip_land(teeth,pa,x)>=min(0.2,max(0,_bevel_tip_land(teeth,pa,0)))-1e-12;
function _bevel_pair_tip_ok(small,large,pa,x) =
    _bevel_shift_tip_ok(small,pa,x) && _bevel_shift_tip_ok(large,pa,-x);
/// The admissible positive correction starts at zero. Search its first
/// tip-width boundary only after the undercut allowance has bounded it.
function _bevel_tip_shift_limit(small,large,pa,lo,hi,n=40) =
    n==0 ? lo :
    let(mid=(lo+hi)/2)
    _bevel_pair_tip_ok(small,large,pa,mid)
      ? _bevel_tip_shift_limit(small,large,pa,mid,hi,n-1)
      : _bevel_tip_shift_limit(small,large,pa,lo,mid,n-1);
function _bevel_auto_profile_shift(teeth,mate_teeth,pa) =
    teeth==mate_teeth ? 0 :
    let(small=min(teeth,mate_teeth),large=max(teeth,mate_teeth),
        need=max(0,_bevel_min_profile_shift(small,pa)),
        room=max(0,-_bevel_min_profile_shift(large,pa)),
        requested=min(need,room),
        amount=requested==0 || !_bevel_pair_tip_ok(small,large,pa,0) ? 0 :
               _bevel_pair_tip_ok(small,large,pa,requested) ? requested :
               _bevel_tip_shift_limit(small,large,pa,0,requested))
    teeth<mate_teeth ? amount : -amount;
function _bevel_resolve_profile_shift(teeth,mate_teeth,pa,profile_shift) =
    assert(all_integer([teeth,mate_teeth]) && min(teeth,mate_teeth)>=3,
           "\nBevel teeth and mate_teeth must be integers at least 3")
    assert(is_finite(pa) && pa>=0 && pa<90,
           "\nBevel pressure_angle must be at least zero and less than 90 degrees")
    assert(is_undef(profile_shift) || profile_shift=="auto" || is_finite(profile_shift),
           "\nBevel profile_shift must be a finite number or \"auto\"")
    let(parent=$parent_gear_type=="bevel" && !is_undef($_gear_parent_spec),
        selected=is_undef(profile_shift) && parent ? -$_gear_parent_spec[6] : default(profile_shift,"auto"))
    selected=="auto" ? _bevel_auto_profile_shift(teeth,mate_teeth,pa) : selected;
function _bevel_check_profile_shift(teeth,pa,x,m,clearance,backlash) =
    assert(is_finite(clearance) && clearance>=0,"\nBevel clearance must be nonnegative and finite")
    assert(is_finite(backlash) && backlash>=0,"\nBevel backlash must be nonnegative and finite")
    assert(1+x>0 && 1-x+clearance/m>0 && teeth/2-1+x-clearance/m>0,
           "\nBevel profile_shift/clearance must leave positive addendum, dedendum and root radius")
    assert(PI/2+2*x*tan(pa)-backlash/m>0 && PI/2-2*x*tan(pa)>0,
           "\nBevel profile_shift/backlash removes a tooth or closes its pitch-circle space")
    assert(x==0 || _bevel_shift_tip_ok(teeth,pa,x),
           "\nBevel profile_shift leaves insufficient nominal tip land; reduce the correction")
    true;


// Function&Module: bevel_gear()
// Synopsis: Creates a straight, zerol, or spiral bevel gear.
// SynTags: Geom, VNF
// Topics: Gears, Parts
// See Also: rack(), rack2d(), spur_gear(), spur_gear2d(), bevel_pitch_angle(), bevel_gear(), attach_gear()
// Usage: As a Module
//    bevel_gear([mod=|circ_pitch=|diam_pitch=], teeth, mate_teeth, [shaft_angle|drive_angle=], [backing=], [bottom=], [thickness=], [cone_backing=], [face_width=], [shaft_diam=], [pressure_angle=], [clearance=], [profile_shift=], [backlash=], [spiral=], [cutter_radius=], [slices=], [gear_spin=], [anchor=], [spin=], [orient=], [left_handed=|right_handed=]) [ATTACHMENTS];
// Usage: As a Function
//    vnf = bevel_gear([mod=|circ_pitch=|diam_pitch=], teeth, mate_teeth, [shaft_angle|drive_angle=], [backing=], [bottom=], [thickness=], [cone_backing=], [face_width=], [pressure_angle=], [clearance=], [profile_shift=], [backlash=], [spiral=], [cutter_radius=], [slices=], [gear_spin=], [anchor=], [spin=], [orient=], [left_handed=|right_handed=]);
// Description:
//   Creates a spiral, zerol, or straight bevel gear.  In straight bevel gear sets, when each tooth
//   engages it impacts the corresponding tooth.  The abrupt tooth engagement causes impact stress
//   which makes them more prone to breakage.  Spiral bevel gears have teeth formed along spirals so
//   they engage more gradually, resulting in a less abrupt transfer of force, so they are quieter
//   in operation and less likely to break.
//   .
//   Bevel gears are designed as mated pairs to work together at a chosen shaft angle.  You therefore
//   must specify both the number of teeth on the gear and the number of teeth on its mating gear.
//   Additional requirements for bevel gears to mesh are that they share the same
//   tooth size and the same pressure angle and they must be of opposite handedness.
//   Specify tooth size using `mod`, `circ_pitch`, or `diam_pitch`, or inherit it from a parent bevel gear. 
//   The pressure angle controls how much the teeth bulge at their
//   sides and is almost always 20 degrees for standard bevel gears.  The ratio of `teeth` for two meshing gears
//   gives how many times one will make a full
//   revolution when the other makes one full revolution.  If the two numbers are coprime (i.e.
//   are not both divisible by the same number greater than 1), then every tooth on one gear will meet
//   every tooth on the other, for more even wear.  So relatively prime numbers of teeth are good.
//   .
//   The gear appears centered on the origin, with one tooth
//   centered on the Y+ axis.  The base of the pitch cone (the "pitchbase") will lie in the XY plane.
//   To manually mate two gears you must position them so that their pitch bases are tangent, they are rotated
//   to the specified shaft angle, and the apexes of the pitch cones coincide.  The "apex" anchor
//   can make it easier to align two gears.  
//   . 
//   By default backing will be added to ensure
//   that the center of the gear (where there are no teeth) is at least half the face width in thickness.
//   You can change this using the `backing`, `thickness` or `bottom` parameters.  The backing appears with
//   a conical shape, extended the sloped edges of the teeth.  You can set `cone_backing=false` if your application
//   requires cylindrical backing.
//   .
//   By default profile shifting applies automatically to reduce the undercut of small gears.
//   The smaller gear receives a positive shift and its mate the opposite shift, which leave the
//   mounting geometry unchanged.  If both gears are small then the profile shift is limited
//   to avoid introducing undercut in the mating gear.  
//   Set `profile_shift=0` to disable automatic shifting, or specify your own shift value  
//   for manual adjustment.  In this case, be sure to give the mating gear the matching negative
//   shift.
//   .
//   You can position bevel gears directly by aligning their pitch-cone apexes, but it may be easier
//   to use {{attach_gear()}}, which positions the gears and aligns the teeth automatically.
//   A bevel gear child inherits a mating design: teeth and mate_teeth are interchanged, handedness
//   is reversed, the profile shift is negated, and shaft angle, face width, spiral, and cutter settings are shared.
// Arguments:
//   teeth = Number of teeth on this gear. When omitted, inherits mate_teeth from a bevel parent. 
//   mate_teeth = Design tooth count of the matching gear. When omitted, inherits teeth from a bevel parent.
//   shaft_angle/drive_angle = Angle between the shafts of the two gears. Default: inherited from a bevel parent if available, 90 otherwise.
//   ---
//   mod = The module of the gear (pitch diameter / teeth)
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  The diametral pitch is a completely different thing than the pitch diameter.
//   circ_pitch = Normal circular pitch.
//   backing = Distance from bottom of bevel gear to bottom corner of teeth (alternative to bottom or thickness). When none is specified, add enough backing to make the center at least half the face width thick, or use zero if already thick enough.
//   bottom = Distance from bevel gear's pitch base to the bottom of the bevel gear.  (Alternative to backing or thickness)
//   thickness = Thickness of bevel gear at the center, where there are no teeth.  (Alternative to backing or bottom). 
//   cone_backing = If true backing extends conical shape of the gear; otherwise backing is an attached cylinder.  Default: true
//   face_width = Width of teeth along the cone. Inherits face_width from a bevel parent, otherwise parent thickness when available. Default: the smaller of one third the cone distance and 10*module.
//   shaft_diam = Diameter of the hole in the center, or zero for no hole.  (Module only.)  Default: 0
//   pressure_angle = Normal pressure angle in degrees. Inherits from the parent when omitted. Default: 20.
//   clearance = Clearance gap at the bottom of the inter-tooth valleys.  Default: module/4
//   profile_shift = Signed profile shift coefficient for this gear, or "auto". An omitted value inherits the negative of a bevel parent's shift. Default: "auto".
//   backlash = Gap between two meshing teeth, in the direction along the circumference of the pitch circle.  Default: $backlash
//   spiral = The base angle for spiral teeth. If zero the teeth will be zerol or straight. Default: inherited from a bevel parent if available, 35 otherwise.
//   cutter_radius = Radius of the spiral arc. Zero selects the straight-tooth approximation. Default: inherited from a bevel parent if available, 2*face_width/cos(spiral) otherwise.
//   right_handed = Select right-hand teeth when true, or left handed when false.  Default: reverse the parent's handedness, or left-handed if no parent bevel gear exists.
//   left_handed = Select left-hand teeth when true and right-hand teeth when false. Default: reverse the parent's handedness, or left-handed if no parent bevel gear exists.
//   slices = Number of vertical layers to divide gear into.  Useful for refining gears with `spiral`.  Default: 5
//   gear_spin = Rotates the gear around its center by the given number of degrees without affecting any children. Use {{gear_spin()}} to drive the gear and its children.  Default: 0
//   anchor = For a child of {{attach_gear()}} must be set to the default value.  Otherwise, translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: "pitchbase"
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top toward, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Side Effects:
//   See {{attach_gear()}} for reference frames, units, and inheritance details.
//   Sets internal variables for gear inheritance.
//   `$gear_rotation` is set to the total gear rotation resulting from {{gear_spin()}} or {{gear_travel()}} applied to the gear chain root.
//   `$gear_angle_offset` is set to the angular tooth-alignment offset in degrees, including meshing alignment and local `gear_spin`.
//   `$gear_ratio` is set to signed angular gain: (output degrees)/(input degrees) for rotational input, or (output degrees)/(input travel) for travel input in model units.
//   `$gear_input` is set to "rotation" (degrees), "travel" (model units), or undef for an undriven chain.
//   `$gear_contact_dir` is set to the nominal engagement direction with the parent in the current child frame.
//   `$gear_contact_angle` is set to the corresponding engagement angle in degrees in the current child frame.
//   `$gear_chain_locs` is set to a list of gear center coordinates (pitch-line origins for racks) in the current child frame, with the root gear first and the current gear last.
//   `$gear_chain_axes` is set to a list of shaft-axis unit vectors (`undef` for racks) in the current child frame, with the root gear first and the current gear last.
//   `$gear_travel` is set to zero.
//   `$gear_travel_offset` is set to zero.
//   `$gear_travel_ratio` is set to zero.
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
    right_handed, slices, gear_spin, anchor, spin, orient, _return_anchors, left_handed, drive_angle, profile_shift
) =
    assert(is_undef(_named), "\nToo many positional arguments (only 3 are accepted)")
    let(bevel_parent=$parent_gear_type=="bevel" && !is_undef($_gear_parent_spec),
        old=bevel_parent?$_gear_parent_spec[16]:undef,
        teeth=default(teeth,bevel_parent?old[0]:undef),
        mate_teeth=default(mate_teeth,bevel_parent?$parent_gear_teeth:undef),
        shaft_angle=num_defined([shaft_angle,drive_angle])==0 && bevel_parent ? old[1] :
                    _gear_shaft_angle(shaft_angle,drive_angle),
        face_width=default(face_width,bevel_parent?old[2]:undef),
        cutter_radius=default(cutter_radius,bevel_parent?old[4]:undef),
        backlash=_gear_backlash(backlash),
        spiral=default(spiral,bevel_parent?old[3]:35),
        right_handed=!_gear_left_handed(left_handed,right_handed,bevel_parent?!old[5]:true),
        slices=default(slices,5),
        cone_backing=default(cone_backing,true),
        anchor=default(anchor,"pitchbase"),
        spin=default(spin,0),
        gear_spin=default(gear_spin,0),
        orient=default(orient,UP),
        _return_anchors=default(_return_anchors,false))
    let(pressure_angle=_inherit_gear_pa(pressure_angle))
 assert(all_integer([teeth,mate_teeth]) && teeth>=3 && mate_teeth>=3, "\nMust give teeth and mate_teeth, integers greater than or equal to 3")
    assert(all_nonnegative([spiral]), "\nspiral must be nonnegative")
    assert(is_undef(cutter_radius) || all_nonnegative([cutter_radius]), "\ncutter_radius must be nonnegative")
    assert(is_finite(shaft_angle) && shaft_angle>0 && shaft_angle<180,"\nshaft_angle must be strictly between 0 and 180")  
    let(
        circ_pitch = _inherit_gear_pitch(fname="bevel_gear()",circ_pitch=circ_pitch, diam_pitch=diam_pitch, mod=mod),
        PA = _inherit_gear_pa(pressure_angle=pressure_angle),
        ps = _bevel_resolve_profile_shift(teeth,mate_teeth,PA,profile_shift),
        spiral = _inherit_gear_helical(helical=spiral),
        slices = cutter_radius==0? 1 : slices,
        pitch_angle = bevel_pitch_angle(teeth,mate_teeth,shaft_angle),
        pr = pitch_radius(circ_pitch=circ_pitch, teeth=teeth),
        rr = assert(_bevel_check_profile_shift(teeth,PA,ps,circ_pitch/PI,
                         default(clearance,circ_pitch/(4*PI)),backlash))
             _root_radius_basic(circ_pitch=circ_pitch, teeth=teeth, clearance=clearance, profile_shift=ps),
        pitchoff = (pr-rr) * sin(pitch_angle),
        ocone_rad = pr / sin(pitch_angle),
        apex_height = pr * cos(pitch_angle) / sin(pitch_angle),
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
            profile_shift = ps,
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
                    m = up((1-u) * apex_height) *
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
                      assert(all_nonnegative([backing]), "\nbacking must be a non-negative value")
                      assert(ctr_thickness>0 || backing>0, "\ninternal gears require backing>0")
                      backing-min(0,ctr_thickness)
                : is_def(thickness) ?
                      let(thick_OK=is_finite(thickness) && (thickness>abs(ctr_thickness) || (thickness==ctr_thickness && ctr_thickness>0)))
                      assert(thick_OK, str("\n", "thickness is invalid or too small for teeth; thickness must be larger than ",abs(ctr_thickness)))
                      thickness-ctr_thickness
                : is_def(bottom)?
                    assert(is_finite(bottom) && bottom-pitchoff+botz>minbacking,
                           str("\nbottom is too small for these teeth; it must exceed ",minbacking+pitchoff-botz))
                    bottom-pitchoff+botz
                : ctr_thickness>face_width/2 ? 0
                : -ctr_thickness+face_width/2,
        cpz = (topz + botz - backing) / 2,
        teeth_top_faces =[
            // Join opposing flanks only while their boundary indices are distinct.
            // Odd boundaries finish with one triangle; even boundaries with a quad.
            for (i=[0:1:teeth-1], j=[0:1:ceil(face_pts/2)-2])
                let(lo=i*face_pts+j, hi=(i+1)*face_pts-j-1)
                each [
                    [lo, hi, hi-1],
                    if (hi-1>lo+1) [lo, hi-1, lo+1]
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
            named_anchor("pitchbase", [0,0,pitchoff-cpz]),
            named_anchor("flattop", [0,0,topz-cpz]),
            named_anchor("apex", [0,0,pitchoff-cpz+apex_height])
        ],
        final_vnf = reorient(anchor,spin,orient, vnf=vnf, extent=true, anchors=anchors, p=vnf)
    )
    _return_anchors==false ? final_vnf
                        : [final_vnf, anchors, ctr_thickness+backing];
module bevel_gear(
    teeth, mate_teeth, shaft_angle, _named, mod, circ_pitch, diam_pitch, backing, bottom, thickness,
    cone_backing, face_width, shaft_diam, pressure_angle, clearance, backlash, spiral, cutter_radius,
    right_handed, slices, gear_spin, anchor, spin, orient, left_handed, drive_angle, profile_shift
) {
    assert(is_undef(_named), "\nToo many positional arguments (only 3 are accepted)");
    bevel_parent=$parent_gear_type=="bevel" && !is_undef($_gear_parent_spec);
    old=bevel_parent?$_gear_parent_spec[16]:undef;
    // Construction inheritance describes a mate, independently of placement/motion.
    teeth=default(teeth,bevel_parent?old[0]:undef);
    mate_teeth=default(mate_teeth,bevel_parent?$parent_gear_teeth:undef);
    sa=num_defined([shaft_angle,drive_angle])==0 && bevel_parent ? old[1] :
        _gear_shaft_angle(shaft_angle,drive_angle);
    pa=_inherit_gear_pa(pressure_angle);
    cp=_inherit_gear_pitch("bevel_gear()",circ_pitch,diam_pitch,mod);
    m=cp/PI;
    ps=_bevel_resolve_profile_shift(teeth,mate_teeth,pa,profile_shift);
    assert(all_integer([teeth,mate_teeth]) && teeth>=3 && mate_teeth>=3,
           "\nMust give teeth and mate_teeth, integers greater than or equal to 3");
    pang=bevel_pitch_angle(teeth,mate_teeth,sa);
    cone=(m*teeth/2)/sin(pang);
    fw=default(face_width,bevel_parent?old[2]:default($parent_gear_thickness,min(cone/3,10*m)));
    spir=default(spiral,bevel_parent?old[3]:35);
    cut=default(cutter_radius,bevel_parent?old[4]:2*fw/cos(spir));
    lh=_gear_left_handed(left_handed,right_handed,bevel_parent?!old[5]:true);
    anchor=default(anchor,"pitchbase"); spin=default(spin,0); orient=default(orient,UP);
    phase=default(gear_spin,0); bore=default(shaft_diam,0);
    assert(is_finite(fw) && fw>0 && fw<cone,
           str("\nface_width must be greater than zero and less than cone distance ",cone,"; got ",fw));
    assert(is_finite(spir) && spir>=0 && spir<90,"\nspiral must be in [0,90) degrees");
    assert(is_finite(bore) && bore>=0,"\nshaft_diam must be nonnegative and finite");
    data=bevel_gear(circ_pitch=cp,teeth=teeth,mate_teeth=mate_teeth,shaft_angle=sa,
        bottom=bottom,thickness=thickness,backing=backing,cone_backing=default(cone_backing,true),
        face_width=fw,pressure_angle=pa,clearance=clearance,backlash=_gear_backlash(backlash),
        cutter_radius=cut,spiral=spir,left_handed=lh,slices=default(slices,5),
        anchor=CENTER,gear_spin=0,_return_anchors=true,profile_shift=ps);
    vnf=data[0]; anchors=data[1]; body_height=data[2];
    _spec=_gear_spec("bevel",m,teeth,pa,thickness=body_height,shift=ps,clearance=default(clearance,m/4),
        family_data=[mate_teeth,sa,fw,spir,cut,lh,anchors[2][1].z,anchors[0][1].z]);
    _geom=attach_geom(vnf=zrot(phase,p=vnf),extent=true,anchors=anchors);
    _pose=_gear_pose(_spec,phase,anchor,spin,orient,geom=_geom);
    // Apply tooth phase to the actual VNF, not a nested attachable shape.
    // The outer attachable and the rendered solid must use the same geometry.
    body=zrot(_pose[1],p=vnf);
    _gear_place(_pose)
    attachable(anchor,spin,orient,geom=_geom) {
        difference() {
            polyhedron(body[0],body[1],convexity=12);
            if(bore>0) cylinder(h=2*body_height,r=bore/2,center=true,$fn=max(12,segs(bore/2)));
        }
        _gear_publish(_spec,_pose) children();
    }
}
/// Cylindrical worm angles refer to the flanks facing native Z- and Z+.
/// Keep scalar/equal-pair inputs on the original symmetric construction path.
function _worm_pressure_angle(pressure_angle) =
    let(a=default(pressure_angle,default($parent_gear_pa,20)))
    assert(is_finite(a) || (is_vector(a,2) && all([for(p=a)is_finite(p)])),
           "\npressure_angle must be a finite number or [pa_bot,pa_top]")
    assert(is_list(a)?min(a)>=0 && max(a)<90:a>=0 && a<90,
           "\nEach pressure angle must be at least zero and less than 90 degrees")
    is_list(a) && a[0]==a[1]?a[0]:a;
function _worm_swap_angles(pa) = is_list(pa)?[pa[1],pa[0]]:pa;
function _worm_slopes(pa,cb) = is_list(pa)?[tan(pa[0])/cb,tan(pa[1])/cb]:tan(pa)/cb;
function _worm_mean_slope(k) = is_list(k)?(k[0]+k[1])/2:k;
function _worm_side_slope(k,side) = is_list(k)?k[side<0?0:1]:k;
function _worm_full_tip(pa,backlash=0,m=1,cb=1) =
    let(t=is_list(pa)?tan(pa[0])+tan(pa[1]):2*tan(pa))
    assert(PI*m/2-backlash*cb-m*t>0,
           "\nPressure angles and backlash leave no full-height worm tooth tip; reduce their combined flank slope or backlash") true;

/// Axial/radial corners before the periodic window is recentered.
/// Off-center valleys remain exposed; neither flank is individually clipped
/// to the pitch-tooth center. Root fillets share the available valley land.
/// [pitch, dedendum, window_center, root_radius, tip_radius, B,C,D,E].
function _worm_asym_profile_data(cp,beta,pa,c,backlash) =
    let(m=cp/PI,cb=cos(beta),p=cp/cb,k=_worm_slopes(pa,cb),
        a=p/4-backlash/2,dd=_worm_thread_dedendum(m,beta,pa,c,backlash),
        B=[-a-k[0]*dd,-dd],C=[-a+k[0]*m,m],
        D=[a-k[1]*m,m],E=[a+k[1]*dd,-dd],
        tb=tan((90-atan(k[0]))/2),tt=tan((90-atan(k[1]))/2),
        gap=max(0,p-E.x+B.x),
        rr=gap<=1e-12*p?0:min(c,gap/(tb+tt)),rt=min(p/16,(D.x-C.x)/(tb+tt)),
        center=(B.x+E.x+rr*(tt-tb))/2)
    assert(_worm_full_tip(pa,backlash,m,cb))
    [p,dd,center,rr,rt,B,C,D,E];

/// Rotation of the recentered thread restores the original pitch-tooth phase.
/// This makes placement independent of the root fillets and tooth thinning.
function _worm_thread_center(cp,beta,pa,c,backlash) =
    is_list(pa)?_worm_asym_profile_data(cp,beta,pa,c,backlash)[2]:0;

function _worm_asym_thread_profile(cp,beta,pa,c,backlash) =
    let(F=_worm_asym_profile_data(cp,beta,pa,c,backlash),
        p=F[0],dd=F[1],s=F[2],rr=F[3],rt=F[4],
        A=[s-p/2,-dd],B=F[5],C=F[6],D=F[7],E=F[8],Z=[s+p/2,-dd],
        raw=[each(rr>0?arc(n=4,r=rr,corner=[A,B,C]):[B]),
             each arc(n=4,r=rt,corner=[B,C,D]),
             each arc(n=4,r=rt,corner=[C,D,E]),
             each(rr>0?arc(n=4,r=rr,corner=[D,E,Z]):[E])],
        tooth=[for(i=[0:len(raw)-1])if(i==0 || norm(raw[i]-raw[i-1])>1e-12*p)raw[i]],
        profile=[for(i=[0:len(tooth)-1])
            let(x=(tooth[i].x-s)/p,y=i==0 || i==len(tooth)-1?-dd:tooth[i].y)
            assert(x>=-.5-1e-10 && x<=.5+1e-10,"\nInternal error: asymmetric worm profile exceeds one pitch")
            [constrain(x,-.5,.5),(y-cp/PI)/p]])
    profile;

// Module: worm()
// Synopsis: Creates a cylindrical worm that will mate with a worm gear or worm face gear.
// SynTags: Geom
// Topics: Gears, Parts
// See Also: worm_gear(), worm_dist(), worm_root_radius(), globoid_worm(), globoid_worm_gear(), attach_gear()
// Usage: 
//   worm([mod=|circ_pitch=|diam_pitch=], [d|worm_diam=], [l|length=|h=|height=|worm_length=], [starts=|worm_starts=], [left_handed=], [pressure_angle=], [backlash=], [clearance=], [lead_in=], [anchor=], [spin=], [orient=], [gear_spin=]) [ATTACHMENTS];
// Description:
//   Creates a cylindrical worm, a screw-shaped gear that meshes with {{worm_gear()}}
//   on perpendicular, offset shafts.  See [A Quick Introduction to Gears: Worm Drive](gears.scad#subsection-worm-drive).
//   You must specify tooth size using `mod=`, `circ_pitch=`, or `diam_pitch=` or inherit it from
//   a parent gear. The worm and its mated worm gear must use the same tooth size, number of starts, worm diameter, 
//   pressure angle and handedness.  You can specify the working diameter with `d=` or `worm_diam=` or you can
//   specify `worm_root_diam=` which gives the minimum central diameter, ensuring adequate space for a shaft.
//   .
//   The `pressure_angle` can be a scalar valued angle to produce standard
//   symmetric teeth, but you can also give a pair, `[pa_bot,pa_top]` to produce a worm with asymmetric teeth.
//   In this case `pa_bot` gives the pressure angle of the tooth bottom (flank facing Z-) and `pa_top` gives the pressure
//   angle of the top of the tooth (flank facing Z+).  A pair like `[45,5]` gives an asymmetric form
//   can reduce overhangs for 3D printing, but due to the high pressure angle on the bottom
//   it is best suited to driving only in one direction.  
//   Give the mating worm gear the SAME ordered pair.  The asymmetric worm assembles
//   with the same spacing as a standard worm.  Giving a pair like `[20,20]` is equivalent
//   to giving a scalar value.  
//   .
//   The gear appears centered, oriented in the Z direction.  The FRONT point of the gear
//   (on the Y- axis) is a tooth valley so it can mesh with a tooth on the worm gear.
//   Use {{worm_dist()}} to determine the proper center-to-center space between the worm and its worm gear.
//   For such applications as attaching a shaft or creating a hole it is useful to know the root radius
//   of the gear.  You can calculate this using {{worm_root_radius()}}.
//   .
//   To create space for gears to mesh in practice you will need to set a positive value for backlash, or
//   use the `backlash` argument to {{worm_dist()}} (but not both).  Low `$fn` values can create
//   more interference with small or zero backlash.
//   The `clearance=` parameter requests extra root depth below the mating worm gear's tooth tips.
//   At high pressure angles, adjacent thread flanks can meet before the requested depth,
//   leaving a shallower valley. Increasing clearance cannot deepen that valley once the flanks
//   meet; reduce the pressure angle or revise the tooth proportions instead.
//   .
//   The `$fn`/`$fa`/`$fs` parameters control the faceting of the gear with a minimum of 36 segments, rounded to
//   a multiple of `starts`.  
//   .
//   The worm has tapered thread ends by default, with `lead_in` equal to one nominal tooth depth: `2*module+clearance`. 
//   You can set `lead_in` to zero to disable the taper, or choose a different length of lead in.
//   .
//   You can position gears directly using {{worm_dist()}}, but it may be easier to use
//   {{attach_gear()}}, which positions the gears and aligns the teeth automatically.
// Arguments:
//   d/worm_diam = Pitch diameter of the worm. Inherits when available. Default: 15
//   l/length/h/height/worm_length = Length of the worm. Inherits when available. Default: 100
//   ---
//   mod = The module of the gear (pitch diameter / teeth)
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  The diametral pitch is a completely different thing than the pitch diameter.
//   circ_pitch = Normal circular pitch.
//   worm_root_diam = Gives the worm root diameter, e.g. to ensure adequate space for a shaft.  An alternative to worm_diam or d. 
//   pressure_angle = Normal pressure angle in degrees. Inherits from the parent when omitted. Default: 20.
//   starts/worm_starts = Number of starts. Inherits when available. Default: 1
//   left_handed = Select left-handed teeth when true. Inherits from the parent when available. Default: false (right-handed).
//   backlash = Gap between two meshing teeth.  Default: $backlash
//   clearance = Nominal extra thread-root depth; can be reduced by converging flanks at high pressure angles. Inherits from a parent {{worm()}} or {{worm_gear()}} when omitted. Default: module/4
//   lead_in = Length of the thread taper at the ends, or zero for flat-cut ends.  Default: 2*module+clearance (tooth depth)
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top toward, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   gear_spin = Rotates the gear around its center by the given number of degrees without affecting any children. Use {{gear_spin()}} to drive the gear and its children.  Default: 0
// Side Effects:
//   See {{attach_gear()}} for reference frames, units, and inheritance details.
//   Sets internal variables for gear inheritance.
//   `$worm_length` is set to the resolved numerical worm length in model units.
//   `$gear_rotation` is set to the total gear rotation resulting from {{gear_spin()}} or {{gear_travel()}} applied to the gear chain root.
//   `$gear_angle_offset` is set to the angular tooth-alignment offset in degrees, including meshing alignment and local `gear_spin`.
//   `$gear_ratio` is set to signed angular gain: (output degrees)/(input degrees) for rotational input, or (output degrees)/(input travel) for travel input in model units.
//   `$gear_input` is set to "rotation" (degrees), "travel" (model units), or undef for an undriven chain.
//   `$gear_contact_dir` is set to the nominal engagement direction with the parent in the current child frame.
//   `$gear_contact_angle` is set to the corresponding engagement angle in degrees in the current child frame.
//   `$gear_chain_locs` is set to a list of gear center coordinates (pitch-line origins for racks) in the current child frame, with the root gear first and the current gear last.
//   `$gear_chain_axes` is set to a list of shaft-axis unit vectors (`undef` for racks) in the current child frame, with the root gear first and the current gear last.
//   `$gear_travel` is set to zero.
//   `$gear_travel_offset` is set to zero.
//   `$gear_travel_ratio` is set to zero.
// Example:
//   worm(mod=2, d=30, l=50, $fn=72);
// Example: Multiple Starts.
//   worm(mod=2, d=30, l=50, starts=5, $fn=72);
// Example: Left Handed
//   worm(mod=2, d=30, l=50, left_handed=true, $fn=72);
// Example: High-pressure-angle worm
//   worm(mod=2, d=24, l=35, pressure_angle=35, $fn=96);
// Example: With `lead_in=0` the worm has sharp edges at the ends
//   worm(mod=2, d=30, l=50, lead_in=0, starts=3, $fn=72);
// Example: Extending the shaft of the worm
//   $fn=64;
//   worm(mod=2, d=30, l=50)
//   attach(TOP,BOT)
//       cyl(r=worm_root_radius(mod=2, d=30), h=25);
// Example(3D,Med): Worm mated to a worm gear; note the matching parameters
//   $fn=64;
//   sep = worm_dist(mod=2, worm_diam=30, teeth=25, worm_starts=3);
//   color("lightblue")
//     worm_gear(mod=2, teeth=25, worm_diam=30, worm_starts=3);
//   back(sep)
//     worm(mod=2, l=50, worm_diam=30, worm_starts=3, orient=RIGHT);
/// The rack supplies the axial tooth corners; _worm_thread_profile() fits
/// their rounding within a single pitch. generic_threaded_rod() uses coordinates measured
/// from the OUTSIDE diameter, not the worm pitch diameter. Its lattice begins
/// at -l/2-pitch; compensate that length-dependent phase so a valley faces -Y
/// in the middle plane for either handedness and for every start count.
module worm(
    // BEGIN GEAR_API_COMPAT
    _p0="__gear_legacy_omitted__", _p1="__gear_legacy_omitted__", _p2="__gear_legacy_omitted__",
    _extra="__gear_legacy_omitted__",
    // END GEAR_API_COMPAT
    d, l, _named, starts, left_handed, pressure_angle, backlash, clearance, anchor, spin, orient, mod,
    circ_pitch, diam_pitch, gear_spin, length, h, height, worm_length, worm_diam, worm_starts, lead_in,
    worm_root_diam
)
    // BEGIN GEAR_API_COMPAT
    let(_gear_args=_gear_legacy_args(
        "worm()", [_p0,_p1,_p2], _extra,
        ["circ_pitch", "d", "l"], ["d", "l"],
        [d,l], circ_pitch, mod, diam_pitch))
    let(circ_pitch=_gear_args[0], d=_gear_args[1], l=_gear_args[2])
    // END GEAR_API_COMPAT
    assert(is_undef(_named), "\nToo many positional arguments (only 2 are accepted)")
    let(
        d=_gear_worm_diameter(d,worm_diam,15,worm_root_diam=worm_root_diam,
                mod=mod,circ_pitch=circ_pitch,diam_pitch=diam_pitch,clearance=clearance,family=1), l=_gear_worm_length(l,length,h,height,worm_length),
        starts=_gear_worm_starts(starts,worm_starts),
        left_handed=default(left_handed,default($parent_gear_left_handed,false)), backlash=_gear_backlash(backlash),
        gear_spin=default(gear_spin,0), anchor=default(anchor,CENTER),
        spin=default(spin,0), orient=default(orient,UP)
    )
{
    cp = _inherit_gear_pitch("worm()",circ_pitch,diam_pitch,mod);
    m = cp/PI;
    pa = _worm_pressure_angle(pressure_angle);
    c = default(clearance,default(_gear_worm_family($parent_gear_type)==1?$parent_gear_clearance:undef,m/4));
    assert(is_int(starts) && starts>0, "\nstarts must be a positive integer")
    assert(is_finite(d) && d>max(2,starts)*m,
           str("\nFor current parameters, d must be greater than ",max(2,starts)*m,"; got ",d))
    assert(is_finite(l) && l>0, "\nl must be greater than zero and finite")
    assert(is_list(pa)?min(pa)>=0 && max(pa)<90:is_finite(pa) && pa>=0 && pa<90, "\npressure_angle must be at least zero and less than 90 degrees")
    assert(is_finite(c) && c>=0, "\nclearance must be nonnegative and finite")
    assert(c<d/2-m, str("\nFor current parameters, clearance must be less than ",d/2-m," to leave a worm core; got ",c))
    assert(is_finite(backlash) && backlash>=0, "\nbacklash must be nonnegative and finite")
    assert(is_bool(left_handed), "\nleft_handed must be boolean")
    assert(is_finite(gear_spin), "\ngear_spin must be finite")
    assert(is_undef(lead_in) || (is_finite(lead_in) && lead_in>=0), "\nlead_in must be nonnegative and finite; use zero for flat-cut ends")
    {
        lead = default(lead_in,2*m+c);
        beta = asin(starts*m/d);
        axial_pitch = cp/cos(beta);
        outside_d = d+2*m;
        sides = quantup(max(36,segs(outside_d/2)),starts);
        profile = _worm_thread_profile(cp,beta,pa,c,backlash);
        // Check the same quantized limits as the threading generator before dispatch.
        da = 360/sides;
        la = quantup(360*lead/(PI*outside_d),da);
        first = 360*(-l/(2*axial_pitch)-1)/starts;
        cut1 = quantup(360*(-l/(2*axial_pitch)-profile[0].x)/starts+la-first,da)+first;
        cut2 = quantdn(360*( l/(2*axial_pitch)-last(profile).x)/starts-la-first,da)+first;
        assert(lead==0 || cut1<cut2,
               str("\nworm_length=",l," is too short to retain full-height threads with the current end taper and resolution. Increase worm_length."));
        phase = -90+180/starts-(left_handed?-1:1)*180*l/(starts*axial_pitch)
              -(left_handed?-1:1)*360*_worm_thread_center(cp,beta,pa,c,backlash)/(starts*axial_pitch);
        _spec = _gear_spec("worm",m,0,pa,worm_diam=d,starts=starts,worm_length=l,
                           left_handed=left_handed,clearance=c,
                           family_data=[lead,
                               lead==0?-l/2:starts*axial_pitch*cut1/360+axial_pitch*last(profile).x,
                               lead==0?l/2:starts*axial_pitch*cut2/360+axial_pitch*profile[0].x,
                                // Upper-end allowance for changing length at this resolution.
                                lead==0?0:starts*axial_pitch*(la+da)/360
                                    +axial_pitch*(last(profile).x-profile[0].x)]);
    _geom = attach_geom(d=d,l=l);
    _pose = _gear_pose(_spec, gear_spin, anchor, spin, orient,geom=_geom);
    _gear_place(_pose)
    attachable(anchor,spin,orient,geom=_geom) {
            zrot(_pose[1]+phase)
                generic_threaded_rod(d=outside_d,l=l,pitch=axial_pitch,profile=profile,
                    starts=starts,left_handed=left_handed,internal=false,
                    blunt_start=lead>0,lead_in=lead,lead_in_shape="sqrt",
                    bevel=false,end_len=0,anchor=CENTER,spin=0,orient=UP,$fn=sides);
            _gear_publish(_spec,_pose) children();
        }
    }
}
/// Actual dedendum of the periodic straight-flank worm. Adjacent threads may
/// meet before the requested valley depth: keep their EXPOSED boundary rather
/// than extending overlapping feet or compressing the whole tooth horizontally.
/// backlash is the axial pitch-line tooth thinning used by worm()/rack2d().
function _worm_thread_dedendum(m,beta,pa,c,backlash) =
    is_list(pa) ? let(t=tan(pa[0])+tan(pa[1]))
        t==0?m+c:min(m+c,(PI*m/2+backlash*cos(beta))/t) :
    pa==0 ? m+c : min(m+c,(PI*m/4+backlash*cos(beta)/2)/tan(pa));
/// Use the rack's unrounded corners, limiting the root fillet to the available
/// flat land. If adjacent flanks meet above the nominal root, their intersection
/// is the new valley bottom and there is NO flat root land or root fillet.
/// Exactly one periodic profile still fits generic_threaded_rod()'s [-.5,.5].
/// Tip rounding and the straight working flanks are unchanged. The top must
/// retain positive width; shortening a pointed crest is not done implicitly.
function _worm_thread_profile(cp,beta,pa,c,backlash) =
    is_list(pa) ? _worm_asym_thread_profile(cp,beta,pa,c,backlash) :
    let(m=cp/PI,ap=cp/cos(beta),dd=_worm_thread_dedendum(m,beta,pa,c,backlash),
        pa_tip=atan((cp/4-backlash*cos(beta)/2)/m))
    assert(pa<pa_tip,
           str("\npressure_angle and backlash leave no full-height tooth tip. For current tooth size and backlash, pressure_angle must be less than ",pa_tip,"; got ",pa))
    let(corners=select(rack2d(circ_pitch=cp,teeth=1,pressure_angle=pa,
                            clearance=c,backlash=backlash,helical=beta,
                            profile_shift=0,rounding=false),2,-3),
        closed=corners[3].x>=ap/2,
        A=[-ap/2,-dd],B=closed?A:corners[0],C=corners[1],D=corners[2],
        F=[ap/2,-dd],E=closed?F:corners[3],
        tangent=tan((90-atan(tan(pa)/cos(beta)))/2),
        root_limit=max(0,(ap/2-E.x)/tangent),tip_limit=D.x/tangent,
        root_r=closed?0:min(c,root_limit),tip_r=min(ap/16,tip_limit),
        raw=[each (root_r>0?arc(n=4,r=root_r,corner=[A,B,C]):[B]),
             each arc(n=4,r=tip_r,corner=[B,C,D]),
             each arc(n=4,r=tip_r,corner=[C,D,E]),
             each (root_r>0?arc(n=4,r=root_r,corner=[D,E,F]):[E])],
        // Adjacent tip fillets can meet at exactly one point. Keep it once.
        tooth=[for(i=[0:len(raw)-1])if(i==0 || norm(raw[i]-raw[i-1])>1e-12*ap)raw[i]],
        capped=closed || root_r==root_limit,
        profile=[for(i=[0:len(tooth)-1])
            let(x=capped && i==0?-.5:capped && i==len(tooth)-1?.5:tooth[i].x/ap,
                y=i==0 || i==len(tooth)-1?-dd:tooth[i].y)
            [x,(y-m)/ap]])
    assert(min([for(p=profile)p.x])>=-.5 && max([for(p=profile)p.x])<=.5,
           "\nInternal worm profile exceeded one pitch; report the tooth size, diameter, starts, pressure_angle, clearance and backlash")
    profile;
// Function&Module: worm_gear()
// Synopsis: Generates an enveloping worm gear for a cylindrical worm
// SynTags: Geom, VNF
// Topics: Gears, Parts
// See Also: worm(), worm_dist(), worm_root_radius(), worm_outer_radius(), globoid_worm(), globoid_worm_gear(), attach_gear(), worm_gear_radius_bound()
// Usage: As a Function
//   vnf = worm_gear([mod=|circ_pitch=|diam_pitch=], teeth, [thickness], worm_diam=, [worm_starts=], [crowning=], [left_handed=], [pressure_angle=], [backlash=], [clearance=], [profile_shift=], [slices=], [search_steps=], [gear_spin=], [min_tip=], [chamfer=], [anchor=], [spin=], [orient=]);
// Usage: As a Module
//   worm_gear([mod=|circ_pitch=|diam_pitch=], teeth, [thickness], worm_diam=, [worm_starts=], [crowning=], [left_handed=], [pressure_angle=], [backlash=], [clearance=], [profile_shift=], [slices=], [search_steps=], [shaft_diam=], [gear_spin=], [min_tip=], [chamfer=], [anchor=], [spin=], [orient=]) [ATTACHMENTS];
// Description:
//   Creates an enveloping worm gear (also called a worm wheel) that meshes with the cylindrical {{worm()}}
//   on perpendicular, offset shafts.  See [A Quick Introduction to Gears: Worm Drive](gears.scad#subsection-worm-drive).
//   The worm gear's teeth curve across its width to wrap partway around the worm.
//   You must specify tooth size using `mod=`, `circ_pitch=`, or `diam_pitch=` or inherit it from a parent gear.
//   The worm_gear and its mated worm must have matching tooth size, starts, worm diameter (or worm root diameter), pressure angle and handedness. 
//   .
//   You control the thickness using the `thickness` parameter, which inherits from any parent that provides thickness, and otherwise defaults to `worm_diam/2`.
//   Very small worms require a smaller thickness and give an error with the default.
//   Far from the center plane of the gear the teeth naturally come to sharp points.
//   The `min_tip=` parameter limits these fragile, sharp tips by imposing a minimum width
//   across the tip of the gear, with a default of `0.4*mod`.  This process shortens the
//   tips of the teeth near the edge, which will decrease their engagement with the worm.
//   .
//   The worm gear appears with a tooth centered on Y+.
//   Use {{worm_dist()}} to determine the proper center-to-center space between the worm_gear and its worm.
//   Profile shifting is supported and defaults to "auto" which applies profile shifts
//   to small tooth gears to prevent undercut teeth.  You can also use profile shifting
//   to adjust the space between the gears; if you specify `profile_shift=` be sure
//   to pass the same value to {{worm_dist()}}.  
//   .
//   The `crowning=` adds relief to each flank, increasing quadratically from zero at the
//   middle to the specified pitch-circle relief at each face.  A small amount of
//   crowning is useful for preventing edge loading, toleration of misalignment, and reduction of
//   noise and vibration.  
//   .
//   The `chamfer=` parameter trims the outer rims with a simple bevel, with
//   the specified amount of setback along the gear face and the outside.
//   .
//   To create space for gears to mesh in practice you will need to set a positive value for backlash, or
//   use the `backlash=` argument to {{worm_dist()}} (but not both).
//   The `clearance` parameter requests extra worm gear-root depth below the worm's tooth tips, independently of
//   the root depth on the worm itself. 
//   At high pressure angles the achievable root depth can be limited by converging tooth-space
//   flanks. Increasing clearance then need not deepen the roots. The remaining allowance can
//   vary across the worm gear, especially with backlash or crowning; it is not a uniform minimum gap.
//   .
//   The mesh sampling of the worm gear is governed by `slices` (axial samples) and `$gear_steps` (radial sampling).
//   During the calculation the generating motion is divided into `search_steps` intervals to check for limits.
//   Increasing it may find limits that were missed by a smaller value.  To improve visible faceting increase `slices` and
//   `$gear_steps` first and only if a contact defect persists, try doubling `search_steps`.
//   .
//   You can position gears directly using {{worm_dist()}}, but it may be easier to use
//   {{attach_gear()}}, which positions the gears and aligns the teeth automatically.
//   .
//   The function {{worm_gear_radius_bound()}} returns an upper bound
//   on the outside radius for sizing surrounding space.  This upper bound ignores
//   the tooth clipping.  
// Arguments:
//   teeth = Number of worm gear teeth; integer greater than 7.
//   thickness = Full axial thickness. Inherits thickness from any parent that provides it. Default: worm_diam/2.
//   ---
//   worm_diam = Mating worm pitch diameter. Inherits when available.
//   mod = Normal module.
//   diam_pitch = Normal diametral pitch, teeth per inch.
//   circ_pitch = Normal circular pitch.
//   worm_root_diam = Gives the worm root diameter, e.g. to ensure adequate space for a shaft.  An alternative to worm_diam or d.
//   pressure_angle = Normal pressure angle in degrees. Inherits from the parent when omitted.  Default: 20.
//   worm_starts = Number of worm starts. Inherits when available. Default: 1
//   profile_shift = Worm-gear profile-shift coefficient. Profile shift is not inherited. Default: "auto"
//   left_handed = Select left-handed teeth when true. Inherits from the parent when available. Default: false (right-handed).
//   crowning = Extra relief per flank, measured as worm gear pitch-circle arc length; quadratic from zero at the middle to this value at each axial face. Default: 0.1
//   backlash = Tooth thinning measured along the worm gear pitch circle; the generating distance is unchanged. Default: $backlash
//   clearance = Nominal extra worm gear-root depth below the worm tips; can be limited at high pressure angles. Inherits from a parent {{worm()}} or {{worm_gear()}} when omitted. Default: module/4
//   slices = Number of slices used to construct the gear, rounded up to an even number. Default: 10
//   shaft_diam = Axial shaft hole; module only. Default: 0
//   gear_spin = Rotates the gear around its center by the given number of degrees without affecting any children. Use {{gear_spin()}} to drive the gear and its children.  Default: 0
//   min_tip = Minimum width across a tooth tip before rounding in model length units; must be positive. Default: 0.4*module
//   chamfer = Amount to trim outer rims of the teeth. Default: 0
//   search_steps = Sampling intervals for locating generating-envelope limits, integer at least 8.  Increase only when checking numerical convergence. Default: 24
//   anchor = Attachment anchor. Default: CENTER
//   spin = Rotation after anchoring. Default: 0
//   orient = Direction of the worm gear axis. Default: UP
// Side Effects:
//   See {{attach_gear()}} for reference frames, units, and inheritance details.
//   Sets internal variables for gear inheritance.
//   `$worm_length` is set to the inherited working length of the mating worm, or undef when unspecified.
//   `$gear_rotation` is set to the total gear rotation resulting from {{gear_spin()}} or {{gear_travel()}} applied to the gear chain root.
//   `$gear_angle_offset` is set to the angular tooth-alignment offset in degrees, including meshing alignment and local `gear_spin`.
//   `$gear_ratio` is set to signed angular gain: (output degrees)/(input degrees) for rotational input, or (output degrees)/(input travel) for travel input in model units.
//   `$gear_input` is set to "rotation" (degrees), "travel" (model units), or undef for an undriven chain.
//   `$gear_contact_dir` is set to the nominal engagement direction with the parent in the current child frame.
//   `$gear_contact_angle` is set to the corresponding engagement angle in degrees in the current child frame.
//   `$gear_chain_locs` is set to a list of gear center coordinates (pitch-line origins for racks) in the current child frame, with the root gear first and the current gear last.
//   `$gear_chain_axes` is set to a list of shaft-axis unit vectors (`undef` for racks) in the current child frame, with the root gear first and the current gear last.
//   `$gear_travel` is set to zero.
//   `$gear_travel_offset` is set to zero.
//   `$gear_travel_ratio` is set to zero.
// Example:
//   worm_gear(mod=2, worm_diam=30, teeth=25);
// Example: Increasing worm gear detail with `slices` and `$gear_steps`, and adding `chamfer`.
//   $gear_steps=32;
//   worm_gear(mod=2, teeth=25, worm_diam=30, slices=30, chamfer=2);
// Example: With `min_tip` set very small you can see sharp points at the edges of the teeth
//   worm_gear(mod=3, teeth=20, worm_diam=38, thickness=30,
//             $fn=64, min_tip=.01);
// Example: Worm gear for a multi-start worm with a shaft hole
//   worm_gear(mod=2, worm_diam=30, teeth=25, worm_starts=5,
//             $fn=64, shaft_diam=15);
// Example(3D,Med): Worm mated to a worm gear; note the matching parameters
//   $fn=64;
//   sep = worm_dist(mod=2, worm_diam=30, teeth=25, worm_starts=3);
//   color("lightblue")
//     worm_gear(mod=2, teeth=25, worm_diam=30, worm_starts=3);
//   back(sep)
//     worm(mod=2, l=50, worm_diam=30, worm_starts=3, orient=RIGHT);
function worm_gear(
    teeth, thickness, _named, worm_diam, worm_starts, crowning, left_handed, pressure_angle,
    backlash, clearance, profile_shift, slices, gear_spin, mod, circ_pitch, diam_pitch, min_tip,
    chamfer, anchor, spin, orient, search_steps,worm_root_diam
) =
    assert(is_undef(_named), "\nToo many positional arguments (only 2 are accepted)")
    let(
        worm_diam=_gear_worm_diameter(undef,worm_diam,worm_root_diam=worm_root_diam,
                mod=mod,circ_pitch=circ_pitch,diam_pitch=diam_pitch,clearance=clearance,family=1),
        worm_starts=_gear_worm_starts(undef,worm_starts),
        clearance=default(clearance,_gear_worm_family($parent_gear_type)==1?$parent_gear_clearance:undef),
        crowning=is_undef(crowning)?0.1:crowning,
        left_handed=default(left_handed,default($parent_gear_left_handed,false)), backlash=_gear_backlash(backlash),
        profile_shift=is_undef(profile_shift)?"auto":profile_shift, slices=is_undef(slices)?10:slices,
        gear_spin=is_undef(gear_spin)?0:gear_spin, anchor=is_undef(anchor)?CTR:anchor,
        spin=is_undef(spin)?0:spin, orient=is_undef(orient)?UP:orient,
        face_chamfer=is_undef(chamfer)?0:chamfer
    )
    let(
        cp = _inherit_gear_pitch(fname="worm_gear()", circ_pitch=circ_pitch, diam_pitch=diam_pitch, mod=mod),
        pa = _worm_pressure_angle(pressure_angle=pressure_angle),
        ps = _wormgear_resolve_shift(cp/PI,teeth,worm_diam,worm_starts,pa,profile_shift),
        m = cp/PI,
        c = is_undef(clearance) ? m/4 : clearance,
        nt = is_undef(min_tip) ? 0.4*m : min_tip,
        nprofile = is_undef($gear_steps) ? 16 : $gear_steps,
        nsearch = default(search_steps,24),
        niters = 30,
        P = _wormgear_data(m=m,teeth=teeth,d=worm_diam,starts=worm_starts,pa=pa,ps=ps,clear=c,
                          backlash=backlash,crown=crowning,left=left_handed,thickness=thickness,min_tip=nt)
    )
    assert(is_finite(gear_spin), str("\ngear_spin must be finite; got ",gear_spin))
    assert(is_finite(face_chamfer) && face_chamfer>=0, "\nface_chamfer must be nonnegative")
    let(vnf = _wormgear_build(P=P,slices=slices,nprofile=nprofile,nsearch=nsearch,niters=niters,gear_spin=gear_spin,face_chamfer=face_chamfer))
    reorient(anchor,spin,orient, r=P[0], h=2*P[8], p=vnf);
module worm_gear(
    teeth, thickness, _named, worm_diam, worm_starts, crowning, left_handed, pressure_angle,
    backlash, clearance, profile_shift, slices, shaft_diam, gear_spin, mod, circ_pitch, diam_pitch,
    min_tip, chamfer, anchor, spin, orient, search_steps,worm_root_diam
)
    assert(is_undef(_named), "\nToo many positional arguments (only 2 are accepted)")
 
    let(
        worm_diam=_gear_worm_diameter(undef,worm_diam,worm_root_diam=worm_root_diam,
                mod=mod,circ_pitch=circ_pitch,diam_pitch=diam_pitch,clearance=clearance,family=1),
        worm_starts=_gear_worm_starts(undef,worm_starts),
        clearance=default(clearance,_gear_worm_family($parent_gear_type)==1?$parent_gear_clearance:undef),
        crowning=is_undef(crowning)?0.1:crowning,
        left_handed=default(left_handed,default($parent_gear_left_handed,false)), backlash=_gear_backlash(backlash),
        profile_shift=is_undef(profile_shift)?"auto":profile_shift, slices=is_undef(slices)?10:slices,
        shaft_diam=is_undef(shaft_diam)?0:shaft_diam, gear_spin=is_undef(gear_spin)?0:gear_spin,
        anchor=is_undef(anchor)?CENTER:anchor, spin=is_undef(spin)?0:spin,
        orient=is_undef(orient)?UP:orient, chamfer=is_undef(chamfer)?0:chamfer
    )
{
    cp = _inherit_gear_pitch(fname="worm_gear()",circ_pitch=circ_pitch,diam_pitch=diam_pitch,mod=mod);
    pa = _worm_pressure_angle(pressure_angle=pressure_angle);
    ps = _wormgear_resolve_shift(cp/PI,teeth,worm_diam,worm_starts,pa,profile_shift);
    assert(is_finite(shaft_diam) && shaft_diam>=0,
           "\nshaft_diam must be nonnegative");
    assert(is_finite(gear_spin), str("\ngear_spin must be finite; got ",gear_spin));
    _spec = _gear_spec("worm_gear",cp/PI,teeth,pa,thickness=2*_wormgear_halfwidth(cp/PI,worm_diam,thickness),
                           shift=ps,worm_diam=worm_diam,starts=worm_starts,
                           worm_length=$parent_gear_worm_length,left_handed=left_handed,
                           clearance=default(clearance,cp/PI/4));
    _geom=attach_geom(r=_wormgear_reference(cp/PI,teeth,worm_diam,worm_starts,pa,ps)[0],
                      l=_spec[5]);
    _pose = _gear_pose(_spec, gear_spin, anchor, spin, orient,geom=_geom);
    vnf = worm_gear(
        circ_pitch=cp, teeth=teeth, worm_diam=worm_diam,
        worm_starts=worm_starts, crowning=crowning,
        left_handed=left_handed, pressure_angle=pa, backlash=backlash,
        clearance=clearance, profile_shift=ps, slices=slices, search_steps=search_steps,
        thickness=thickness, min_tip=min_tip, gear_spin=_pose[1],
        chamfer=chamfer,
        anchor=CENTER, spin=0, orient=UP
    );
    // Uniform-height sections are ordered top to bottom.
    h = 2*vnf[0][0].z;
    pr = _wormgear_reference(m=cp/PI,teeth=teeth,d=worm_diam,starts=worm_starts,pa=pa,ps=ps)[0];
    _gear_place(_pose)
    attachable(anchor,spin,orient,geom=_geom) {
        difference() {
            vnf_polyhedron(vnf,convexity=12);
            if (shaft_diam>0)
                cylinder(h=2*h+1,d=shaft_diam,center=true,
                         $fn=max(12,segs(shaft_diam/2)));
        }
        _gear_publish(_spec,_pose) children();
    }
}
/// Cylindrical face-worm reference. R is axial-pitch radius, not face-gear radius.
/// [module, teeth, worm_radius, starts, offset, axial_pitch, lead_per_radian,
///  axial_pitch_radius, working_station, contact_radius, contact_angle,
///  axial_flank_slope]. Right-hand geometry uses the positive-X working branch.
/// With worm lead per radian h and ratio N/s, R=(N/s)*h. At the pitch point
/// [L,offset,0], the envelope condition is R-offset-h*L/rw=0. This fixes L;
/// the face-gear contact radius is hypot(L,offset), not R.
function _wfg_reference(m,teeth,d,starts,offset,pa,left=false) =
    assert(is_finite(m) && m>0,"\nTooth size must be positive and finite")
    assert(is_int(teeth) && teeth>=3,"\nteeth must be an integer at least 3")
    assert(is_int(starts) && starts>=1,"\nworm_starts must be a positive integer")
    assert(is_finite(d) && d>max(2,starts)*m,
           str("\nworm_diam must exceed ",max(2,starts)*m))
    assert(_worm_full_tip(pa))
    let(cb=sqrt(1-pow(starts*m/d,2)),p=PI*m/cb,h=starts*p/(2*PI),R=teeth*p/(2*PI))
    assert(is_finite(offset) && offset>=0 && offset<R,
           str("\nshaft_offset must be nonnegative and less than ",R))
    let(L=(R-offset)*d/(2*h),r=norm([L,offset]))
    [m,teeth,d/2,starts,offset,p,h,R,L,r,atan2(offset,L),_worm_slopes(left?pa:_worm_swap_angles(pa),cb)];

/// [reference, clearance, axial_backlash, inner_radius, outer_radius,
/// cutter_tip_radius, root_z, min_tip, angular_origin].
/// The generator is the exposed union of the full-height cutter's swept spaces.
/// Its tip extends for wheel clearance; its flank spacing includes tooth thinning.
function _wfg_data(ref,face_width,clearance,backlash,min_tip) =
    let(m=ref[0],rw=ref[2],c=default(clearance,m/4),ba=backlash*ref[7]/ref[9],
        nt=default(min_tip,.4*m))
    assert(is_finite(c) && c>=0,"\nclearance must be nonnegative and finite")
    assert(is_finite(backlash) && backlash>=0,"\nbacklash must be nonnegative and finite")
    assert(is_finite(nt) && nt>0,"\nmin_tip must be positive and finite")
    let(k=_worm_mean_slope(ref[11]),rt=k==0 ? rw+m+c : min(rw+m+c,rw+(ref[5]/4+ba/2)/k),
        reach=sqrt(max(0,rt*rt-pow(rw-m,2))),room=ref[9]-ref[4]-reach,
        fw=default(face_width,min(5*m,room)),ri=ref[9]-fw/2,ro=ref[9]+fw/2)
    assert(is_finite(fw) && fw>0,
           str("\nworm_face_gear(): face_width must be positive and finite; got ",fw))
    assert(ri>ref[4]+reach,
           str("\nworm_face_gear(): shaft_offset=",ref[4]," does not fit gear_diam=",2*ro,
               " with face_width=",fw," and clearance=",c,". ",
               ri-reach>0?str("For this wheel and worm, shaft_offset must be less than ",ri-reach,
                              " to keep the two working regions separate. Reduce shaft_offset, increase gear_diam or reduce face_width.")
                         :"No nonnegative shaft_offset fits these dimensions. Increase gear_diam or reduce face_width or clearance."))
    [ref,c,ba,ri,ro,rt,rw-rt,nt,90-180/ref[1]-ref[10]-ref[8]/ref[7]*180/PI];

function _wfg_cutangle(t,r,z,side,P) =
    let(F=P[0],v=r*sin(t)-F[4],w=F[2]-z,u=norm([v,w]),
        h=F[5]/4-_worm_side_slope(F[11],side)*(u-F[2])+P[2]/2,
        half=is_list(F[11])?h:max(0,h))
    t+(r*cos(t)-F[6]*atan2(v,w)*PI/180+side*half)/F[7]*180/PI;

/// R times the derivative of the cut angle with respect to t (in radians).
/// At a fixed ring and height the cutter covers a continuous angular interval.
/// Its exposed ends are the extrema of the two flank angles, including the
/// cutter-tip endpoints; selecting only a stationary flank can miss undercut.
function _wfg_cutderiv(t,r,z,side,P) =
    let(F=P[0],v=r*sin(t)-F[4],w=F[2]-z,u=norm([v,w]))
    F[7]-r*sin(t)-F[6]*w*r*cos(t)/(u*u)-side*_worm_side_slope(F[11],side)*v*r*cos(t)/u;

function _wfg_stationary(r,z,side,P,lo,hi,dlo,n=32) =
    n==0 || dlo==0 ? lo :
    let(mid=(lo+hi)/2,dm=_wfg_cutderiv(mid,r,z,side,P))
    dm*dlo>0 ? _wfg_stationary(r,z,side,P,mid,hi,dm,n-1)
             : _wfg_stationary(r,z,side,P,lo,mid,dlo,n-1);

function _wfg_cutlimits(r,z,P,nsearch,n=32) =
    let(F=P[0],q=sqrt(max(0,P[5]*P[5]-pow(F[2]-z,2))),
        lo=asin((F[4]-q)/r),hi=asin((F[4]+q)/r),
        ts=lerpn(lo,hi,nsearch+1))
    [for(side=[-1,1])
        let(ds=[for(t=ts)_wfg_cutderiv(t,r,z,side,P)],
            candidates=[each ts,for(j=[0:nsearch-1]) if(ds[j]*ds[j+1]<0)
                _wfg_stationary(r,z,side,P,ts[j],ts[j+1],ds[j],n)],
            a=[for(t=candidates)_wfg_cutangle(t,r,z,side,P)])
        side<0?min(a):max(a)];

function _wfg_land(r,b,P) =
    let(gap=360/P[0][1]-b[1]+b[0]) gap<=0?-1:2*r*sin(gap/2);

function _wfg_top_limit(r,P,lo,hi,nsearch,n=32) =
    n==0?lo:
    let(mid=(lo+hi)/2)
    _wfg_land(r,_wfg_cutlimits(r,mid,P,nsearch),P)>=P[7]
      ?_wfg_top_limit(r,P,mid,hi,nsearch,n-1)
      :_wfg_top_limit(r,P,lo,mid,nsearch,n-1);

function _wfg_polar(r,a,z)=[r*cos(a),r*sin(a),z];

/// A circumferential section: ascending flank, descending flank, root arc.
/// The root arc joins this tooth to the next. Undercut remains in the envelope.
/// A pointed cutter leaves a single shared root vertex instead of a root arc.
function _wfg_section(r,P,np,na,ns,pointed=false) =
    let(m=P[0][0],period=360/P[0][1],base=P[8],root=P[6],
        btop=_wfg_cutlimits(r,m,P,ns),clipped=_wfg_land(r,btop,P)<P[7],
        scan=clipped?lerpn(root,m,max(32,np*2)+1):[],
        good=clipped?[for(i=idx(scan))if(_wfg_land(r,_wfg_cutlimits(r,scan[i],P,ns),P)>=P[7])i]:[])
    assert(!clipped || len(good)>0,
           str("\nNo tooth at radius ",r," can retain min_tip=",P[7],"; revise offset, width or tooth parameters"))
    let(j=clipped?last(good):0,
        top=clipped?_wfg_top_limit(r,P,scan[j],scan[j+1],ns):m,
        zz=lerpn(root,top,np+1),bb=[for(z=zz)_wfg_cutlimits(r,z,P,ns)])
    assert(top>root+1e-7*m,"\nmin_tip leaves no usable tooth height")
    assert(min([for(b=bb)period-b[1]+b[0]])>1e-9,
           "\nGenerated spaces remove a tooth; reduce backlash or revise offset/width")
    [[for(k=[0:np])_wfg_polar(r,base+bb[k][1],zz[k]),
      for(k=[np:-1:(pointed?1:0)])_wfg_polar(r,base+bb[k][0]+period,zz[k]),
      if(!pointed) for(k=[1:na-1])_wfg_polar(r,base+bb[0][0]+period+(bb[0][1]-bb[0][0])*k/na,root)],
     top,clipped];

/// Close each tooth to its root chord. Root vertices then form a simple ring.
/// With a pointed cutter, the second root is the next tooth's first vertex.
/// Wrap within this radial row, including the seam at the final tooth.
function _wfg_tooth_cap(nteeth,np,nrow,base,reverse=false) =
    let(f=[for(t=[0:nteeth-1],j=[0:np-1])
              let(a=base+t*nrow+j,b=t*nrow+2*np+1-j,
                  b0=base+b%(nteeth*nrow),b1=base+(b-1)%(nteeth*nrow))
              each [[a,a+1,b1],[a,b1,b0]]])
    reverse?[for(x=f)reverse(x)]:f;

function _wfg_build(P,slices,nprofile,nsearch,left=false) =
    assert(is_int(slices) && slices>=2,"\nslices must be an integer at least 2")
    assert(is_int(nprofile) && nprofile>=4,"\n$gear_steps must be an integer at least 4")
    assert(is_int(nsearch) && nsearch>=8,"\nsearch_steps must be an integer at least 8")
    let(F=P[0],N=F[1],np=nprofile,na=max(2,ceil(360/N/5)),
        k=_worm_mean_slope(F[11]),pointed=k>0 && P[5]==F[2]+(F[5]/4+P[2]/2)/k,
        sections=[for(r=lerpn(P[3],P[4],slices+1))_wfg_section(r,P,np,na,nsearch,pointed)],
        rows=[for(s=sections)[for(t=[0:N-1])each zrot(360*t/N,p=s[0])]],
        nr=len(sections[0][0]),nc=N*nr,
        roots=pointed?[for(t=[0:N-1])t*nr]:
              [for(t=[0:N-1])each [t*nr,t*nr+2*np+1,for(k=[2*np+2:nr-1])t*nr+k]],
        inner=rows[0],outer=last(rows),
        topfaces=vnf_vertex_array(rows,col_wrap=true,style="min_edge",reverse=false),
        innercaps=_wfg_tooth_cap(N,np,nr,0,true),
        outercaps=_wfg_tooth_cap(N,np,nr,slices*nc,false))
    [topfaces,innercaps,outercaps,roots,sections];

function _wfg_body(P,data,backing,bottom,thickness,left) =
    let(top=max([for(s=data[4])s[1]]),root=P[6],
        bot=num_defined([backing,bottom,thickness])==0?root-(P[0][0]-root):
            is_def(backing)?root-backing:is_def(bottom)?-bottom:top-thickness)
    assert(num_defined([backing,bottom,thickness])<=1,"\nSpecify only one of backing, bottom or thickness")
    assert(is_finite(bot) && bot<root,"\nBacking must leave positive material below the tooth roots")
    [_gear_face_body(data,root,bot,left),bot,top];

function _gear_face_body(data,root,bot,left=false) =
    let(v=data[0][0],nf=len(v),nc=len(v)/(len(data[4])),outbase=len(v)-nc,
        roots=data[3],n=len(roots),
        bottomring=[for(i=roots)[v[outbase+i].x,v[outbase+i].y,bot]],
        points=[each v,each bottomring,[0,0,root],[0,0,bot]],
        faces=[each data[0][1],each data[1],each data[2],
            for(j=[0:n-1])let(k=(j+1)%n,a=outbase+roots[j],b=outbase+roots[k])
                each [[a,nf+k,nf+j],[a,b,nf+k]],
            for(j=[0:n-1])[nf+n,roots[(j+1)%n],roots[j]],
            for(j=[0:n-1])[nf+n+1,nf+j,nf+(j+1)%n]],
        // Connectivity already shares the tooth, root and body vertices.
        // A general spatial merge here dominated the gear's construction time.
        // OpenSCAD/BOSL2 faces run clockwise when viewed from outside.
        vnf=[points,faces],
        final=left?xflip(p=vnf):vnf)
    final;

/// Conservative axial span of possible contact with the actual (unextended) worm.
function _wfg_span(P) =
    let(F=P[0],q=sqrt(pow(F[2]+F[0],2)-pow(F[2]-F[0],2)),
        ymin=max(0,F[4]-q),ymax=F[4]+q)
    [sqrt(max(0,P[3]*P[3]-ymax*ymax)),sqrt(max(0,P[4]*P[4]-ymin*ymin))];

/// Centering reference on the worm axis, in the canonical angle=90 frame.
/// This is the midpoint of the required axial working span, not a tooth contact.
function _wfg_mesh_center(P,left=false) =
    [(left?-1:1)*mean(_wfg_span(P)),P[0][4],P[0][2]];

/// Rephase the worm when centering moves it from the radial-band reference.
function _wfg_center_phase(P) = (mean(_wfg_span(P))-P[0][8])/P[0][6]*180/PI;

/// Change the selected annulus without changing the generating worm or ratio.
function _wfg_at(F,e,r) =
    let(x=sqrt(max(0,r*r-e*e)))
    [for(i=idx(F)) i==4?e:i==8?x:i==9?r:i==10?atan2(e,x):F[i]];

/// Axial band coverage divided by axial thread pitch. This is a geometric
/// overlap estimate, not a loaded tooth-contact analysis or strength rating.
function _wfg_overlap(P) =
    let(e=P[0][4])
    (sqrt(P[4]*P[4]-e*e)-sqrt(P[3]*P[3]-e*e))/P[0][5];

/// A score of one passes the automatic layout criteria. Sample both edges and
/// the interior; compare the lower tooth neck to the pitch-plane thickness and
/// estimate its normal thickness using the local pitch-plane tooth direction.
/// The criteria are independent of display tessellation and apply to both hands.
function _wfg_quality(F,e,r,fw,c,ba,nt,nr=1,ns=4) =
    let(rw=F[2],m=F[0],k=_worm_mean_slope(F[11]),
        rt=k==0?rw+m+c:min(rw+m+c,rw+(F[5]/4+ba*F[7]/r/2)/k),
        reach=sqrt(max(0,rt*rt-pow(rw-m,2))))
    r-fw/2<=e+reach+.05*m ? -1 :
    let(P=_wfg_data(_wfg_at(F,e,r),fw,c,ba,nt),overlap=_wfg_overlap(P))
    overlap<1.5-1e-9 ? overlap/1.5 :
    let(rr=lerpn(P[3],P[4],nr+1),
        tops=[for(a=rr)_wfg_land(a,_wfg_cutlimits(a,m,P,ns,ns<24?16:32),P)],
        tip=min(tops)/(nt+.05*m))
    tip<1 ? tip :
    let(zz=[lerp(P[6],m,.15),-m/2,0,m/2],
        bb=[for(a=rr)[for(z=zz)_wfg_cutlimits(a,z,P,ns,ns<24?16:32)]],
        ww=[for(i=idx(rr))[for(b=bb[i])_wfg_land(rr[i],b,P)]],
        center=[for(b=bb)mean(b[2])],
        scores=[for(i=idx(rr))
            let(j=max(0,i-1),k=min(nr,i+1),
                slope=rr[i]*(center[k]-center[j])*PI/180/(rr[k]-rr[j]),
                neck=min([for(j=[0:2])ww[i][j]]))
            min(min(ww[i])/(nt+.05*m),neck/max(nt+.05*m,.8*ww[i][2]),
                neck/(.5*m*sqrt(1+slope*slope)))])
    min(tip,min(scores),overlap/1.5);

function _wfg_radius_bisect(F,e,fw,c,ba,nt,lo,hi,n=12) =
    n==0 || hi-lo<.01*F[0] ? hi :
    let(mid=(lo+hi)/2,good=_wfg_quality(F,e,mid,fw,c,ba,nt)>=1)
    _wfg_radius_bisect(F,e,fw,c,ba,nt,good?lo:mid,good?mid:hi,n-1);

function _wfg_radius_bracket(F,e,fw,c,ba,nt,lo,hi,cap,n=18) =
    _wfg_quality(F,e,hi,fw,c,ba,nt)>=1
      ?_wfg_radius_bisect(F,e,fw,c,ba,nt,lo,hi)
      :n==0 || hi>=cap ? undef
      :_wfg_radius_bracket(F,e,fw,c,ba,nt,hi,min(cap,max(hi*1.5,hi+F[0])),cap,n-1);

function _wfg_fit_radius(F,e,fw,c,ba,nt) =
    let(m=F[0],rw=F[2],k=_worm_mean_slope(F[11]),
        rt=k==0?rw+m+c:min(rw+m+c,rw+F[5]/4/k),
        lo=e+sqrt(max(0,rt*rt-pow(rw-m,2)))+fw/2+.05*m,
        a=1.5*F[5],cap=fw>=a?1e8*m:a*sqrt(e*e/(a*a-fw*fw)+.25))
    cap<=lo ? undef :
    _wfg_quality(F,e,lo,fw,c,ba,nt)>=1 ? lo :
    _wfg_radius_bracket(F,e,fw,c,ba,nt,lo,min(cap,max(lo+m,1.5*F[7])),cap);

/// Each candidate stores [objective, band_radius, shaft_offset]. A fixed
/// diameter maximizes the weakest quality score; a free diameter minimizes size.
function _wfg_candidate(F,e,r,fw,c,ba,nt) =
    let(rad=is_def(r)?r:_wfg_fit_radius(F,e,fw,c,ba,nt))
    is_undef(rad)?[-1e100,0,e]:
    [is_def(r)?_wfg_quality(F,e,rad,fw,c,ba,nt):-rad,rad,e];

function _wfg_best(a,b) = a[0]>=b[0]?a:b;

function _wfg_golden(F,r,fw,c,ba,nt,lo,hi,a,b,n=10) =
    n==0 ? _wfg_best(a,b) :
    a[0]>b[0]
      ?let(x=b[2]-(b[2]-lo)*.61803398875)
         _wfg_golden(F,r,fw,c,ba,nt,lo,b[2],_wfg_candidate(F,x,r,fw,c,ba,nt),a,n-1)
      :let(x=a[2]+(hi-a[2])*.61803398875)
         _wfg_golden(F,r,fw,c,ba,nt,a[2],hi,b,_wfg_candidate(F,x,r,fw,c,ba,nt),n-1);

function _wfg_choose_offset(F,r,fw,c,ba,nt) =
    let(m=F[0],rw=F[2],k=_worm_mean_slope(F[11]),
        rt=k==0?rw+m+c:min(rw+m+c,rw+(F[5]/4+(is_def(r)?ba*F[7]/r:0)/2)/k),
        reach=sqrt(max(0,rt*rt-pow(rw-m,2))),
        hi=is_def(r)?max(0,r-fw/2-reach-.050001*m):F[7]+2*rw,
        ee=lerpn(0,hi,9),cc=[for(e=ee)_wfg_candidate(F,e,r,fw,c,ba,nt)],
        j=max_index([for(q=cc)q[0]]),lo=ee[max(0,j-1)],up=ee[min(8,j+1)],
        a=_wfg_candidate(F,up-(up-lo)*.61803398875,r,fw,c,ba,nt),
        b=_wfg_candidate(F,lo+(up-lo)*.61803398875,r,fw,c,ba,nt))
    _wfg_best(cc[j],_wfg_golden(F,r,fw,c,ba,nt,lo,up,a,b));

/// Recheck the winning layout more densely than the search. Small outward
/// corrections handle interpolation and extremum-bracketing errors, while an
/// explicit diameter is never changed. The guard also keeps auto tips off their
/// clipping boundary when surface tessellation is subsequently increased.
function _wfg_finish_layout(F,e,r,fw,c,ba,nt,fixed,n=30) =
    _wfg_quality(F,e,r,fw,c,ba,nt,8,24)>=1-1e-8
      ?_wfg_data(_wfg_at(F,e,r),fw,c,ba,nt)
      :assert(!fixed && n>0,
          "\nNo automatic worm-face layout meets the tooth-height, neck and overlap criteria; increase face_width or revise the worm dimensions, tooth count or gear_diam")
       _wfg_finish_layout(F,e,r+.02*F[0],fw,c,ba,nt,false,n-1);

function _wfg_resolve(F,shaft_offset,gear_diam,face_width,clearance,backlash,min_tip) =
    let(m=F[0],fw=default(face_width,3*F[5]),c=default(clearance,m/4),nt=default(min_tip,.4*m))
    assert(is_undef(shaft_offset) || (is_finite(shaft_offset) && shaft_offset>=0),
           "\nshaft_offset must be nonnegative and finite")
    assert(is_finite(fw) && fw>0,"\nface_width must be positive and finite")
    assert(is_undef(gear_diam) || (is_finite(gear_diam) && gear_diam>2*fw),
           "\ngear_diam must exceed twice face_width")
    assert(is_finite(c) && c>=0,"\nclearance must be nonnegative and finite")
    assert(is_finite(backlash) && backlash>=0,"\nbacklash must be nonnegative and finite")
    assert(is_finite(nt) && nt>0,"\nmin_tip must be positive and finite")
    let(r=is_def(gear_diam)?(gear_diam-fw)/2:undef)
    is_def(shaft_offset) && is_def(r)
      ?_wfg_data(_wfg_at(F,shaft_offset,r),fw,c,backlash,nt)
      :let(best=is_def(shaft_offset)?_wfg_candidate(F,shaft_offset,r,fw,c,backlash,nt)
                 :_wfg_choose_offset(F,r,fw,c,backlash,nt))
       assert(best[0]>-1e99 && (is_undef(r) || best[0]>=1),
          str("\nworm_face_gear(): no automatic layout found with shaft_offset=",
              is_def(shaft_offset)?shaft_offset:"automatic",", gear_diam=",
              is_def(gear_diam)?gear_diam:"automatic",", face_width=",fw,
              ", teeth=",F[1],", mod=",m,", worm_diam=",2*F[2]," and worm_starts=",F[3],". ",
              "The search could not retain full tooth height and the required neck thickness and thread overlap. ",
              "Set shaft_offset or gear_diam to undef to let it be selected, increase face_width, or revise the worm/tooth parameters."))
       _wfg_finish_layout(F,best[2],best[1]+(is_undef(r)?.01*m:0),fw,c,backlash,nt,is_def(r));


/// Reversing the worm exchanges its native Z- and Z+ flanks. Only inherited
/// angles are exchanged; explicit face-gear angles retain their canonical meaning.
function _wfg_pressure_angle(pressure_angle) =
    let(pa=_worm_pressure_angle(pressure_angle))
    is_undef(pressure_angle) && $parent_gear_type=="worm" &&
    is_def($_gear_attach_request) && len($_gear_attach_request)>5 &&
    $_gear_attach_request[5]==LEFT ? _worm_swap_angles(pa) : pa;

function _wfg_arguments(teeth,worm_diam,worm_starts,shaft_offset,face_width,pressure_angle,
                        clearance,backlash,min_tip,mod,circ_pitch,diam_pitch,worm_root_diam,left_handed,gear_diam) =
    let(cp=_inherit_gear_pitch("worm_face_gear()",circ_pitch,diam_pitch,mod),
        d=_gear_worm_diameter(undef,worm_diam,worm_root_diam=worm_root_diam,
                mod=mod,circ_pitch=circ_pitch,diam_pitch=diam_pitch,clearance=clearance,family=1),
        st=_gear_worm_starts(undef,worm_starts),n=default(teeth,$parent_gear_wheel_teeth),
        pa=_wfg_pressure_angle(pressure_angle),lh=default(left_handed,default($parent_gear_left_handed,false)),
        parent=$parent_gear_type=="worm_face"?$_gear_worm_face_data:undef,
        e=default(shaft_offset,is_def(parent)?parent[0][4]:undef),
        gd=default(gear_diam,is_def(parent)?2*parent[4]:undef),
        fw=default(face_width,is_def(parent)?parent[4]-parent[3]:undef),
        c=default(clearance,_gear_worm_family($parent_gear_type)==1?$parent_gear_clearance:undef),
        ba=is_def(parent)&&is_undef(backlash)?parent[2]*parent[0][9]/parent[0][7]:_gear_backlash(backlash),
        nt=default(min_tip,is_def(parent)?parent[7]:undef))
    assert(is_bool(lh),"\nleft_handed must be boolean")
    _wfg_resolve(_wfg_reference(cp/PI,n,d,st,0,pa,lh),e,gd,fw,c,ba,nt);

function _wfg_geom(P,body) =
    attach_geom(r=P[4],h=body[2]-body[1],cp=[0,0,(body[1]+body[2])/2],
                anchors=[named_anchor("pitchplane",[0,0,0]),named_anchor("root",[0,0,P[6]])]);

// Function&Module: worm_face_gear()
// Synopsis: Creates a face gear that meshes with a cylindrical worm with a shaft offset.
// SynTags: Geom, VNF
// Topics: Gears, Parts
// See Also: worm(), attach_gear(), worm_face_dist(), worm_face_gear_radius_bound(), worm_face_gear_worm_pos(), worm_face_gear_worm_spin()
// Usage: As a Function
//    vnf = worm_face_gear([mod=|circ_pitch=|diam_pitch=], teeth, [backing], [face_width], worm_diam=, [shaft_offset=], [gear_diam=], [worm_starts=], [pressure_angle=], [left_handed=], [clearance=], [backlash=], [min_tip=], [bottom=|thickness=], [slices=], [search_steps=], [gear_spin=], [anchor=], [spin=], [orient=]);
// Usage: As a Module
//   worm_face_gear([mod=|circ_pitch=|diam_pitch=], teeth, [backing], [face_width], worm_diam=, [shaft_offset=], [gear_diam=], [worm_starts=], [pressure_angle=], [left_handed=], [clearance=], [backlash=], [min_tip=], [bottom=|thickness=], [shaft_diam=], [slices=], [search_steps=], [gear_spin=], [anchor=], [spin=], [orient=]) [ATTACHMENTS];
// Description:
//   Creates a face gear for the existing cylindrical {{worm()}} on perpendicular, offset shafts.
//   See [Worm Face Drives](gears.scad#subsection-worm-face-drive) for an overview.
//   Tooth size, worm diameter, worm starts and handedness must match the worm.
//   .
//   The `face_width=` parameter gives the radial width of toothed portion of the worm face gear, and
//   `shaft_offset=` specifies the offset between the worm shaft and the worm face gear shaft.
//   You can combine this with `gear_diam` which specifies the diameter of the gear, but you
//   may want to allow automatic selection of one parameter because automatic selection
//   makes a choice based on tooth quality metrics including tooth height, tooth thickness and thread overlap.  
//   If you give only `gear_diam=` then the shaft offset is calculated to optimize the tooth quality.
//   If you give only `shaft_offset=` then the smallest acceptable diameter is chosen.  If you give
//   neither parameter then the search returns a compact wheel that also meets the tooth quality criteria.
//   If you want to manually position a worm you may use {{worm_face_gear_info()}}, which returns
//   all calculated dimensions and placement information without computing the worm mesh.
//   .
//   The `pressure_angle` can be a scalar valued angle to mate with a standard worm with symmetric teeth, 
//   but you can also give a pair, `[pa_bot,pa_top]` to mate with an asymmetric tooth worm. 
//   In this case `pa_bot` gives the pressure angle of the tooth bottom (flank facing Z-) and `pa_top` gives the pressure
//   angle of the top of the tooth (flank facing Z+). 
//   Pressure angles match or may need to be reversed depending on how the worm is positioned on the worm face gear.
//   If you use {{attach_gear()}} then `worm_face_pos=LEFT` requires reversed pressure angles; if you allow the pressure
//   angle to inherit it will be correctly reversed as needed, but if you supply it explicitly you must manually
//   reverse it when required.  
//   .
//   The gear is constructed with teeth pointing towards Z+ and the reference pitch plane at Z=0. 
//   A tooth is centered on Y+ at the nominal radius.
//   .
//   The `min_tip=` parameter limits these fragile, sharp tooth tips by imposing a minimum width
//   across the tip of the gear, with a default of `0.4*mod`.  This process shortens the tips and
//   will decrease their engagement with the worm. 
//   Backlash is tooth thinning measured as circumferential arc length at the center of the tooth band.
//   The worm's own backlash is independent.
//   Clearance requests extra root depth below the worm tips.
//   .
//   Automatic attachment using {{attach_gear()}} supports both nesting orders.  See that module for details
//   on how to control the position of attached worm face gears.
// Arguments:
//   teeth = Number of face-gear teeth; integer at least 3. Required or inherited from a face-gear parent.
//   backing = Material below the actual root plane. Alternative to bottom or thickness. Default: nominal tooth depth.
//   face_width = Radial tooth-band width. Inherits from a face gear. Default: three axial worm-thread pitches.
//   ---
//   worm_root_diam = Positive nominal minimum worm-core diameter; alternative to worm_diam. Uses tooth size and clearance; does not cut a bore.
//   mod = Normal module, shared with the worm. Inherits when omitted.
//   circ_pitch = Normal circular pitch; alternative to mod or diam_pitch.
//   diam_pitch = Normal diametral pitch; alternative to mod or circ_pitch.
//   worm_diam = Mating worm pitch diameter. Inherits when available.
//   worm_starts = Number of worm starts. Inherits when available. Default: 1.
//   shaft_offset = Nonnegative shortest distance between shaft axes. Inherits from a face gear.  Default: calculated 
//   gear_diam = Actual wheel outside diameter. Inherits from a face gear; otherwise computed. Must exceed twice face_width.
//   pressure_angle = Normal pressure angle. Inherits when omitted. Default: 20 degrees.
//   left_handed = Worm handedness. Inherits when available. Default: false.
//   clearance = Extra requested wheel-root depth below the worm tips. Inherits from a cylindrical worm-family parent. Default: module/4.
//   backlash = Circumferential tooth thinning at the band center. Default: inherited from a face gear or $backlash.
//   min_tip = Minimum circumferential tooth-tip chord at each radial section; must be positive. Default: inherited from a face gear or 0.4*module.
//   bottom = Distance down from the pitch plane to the bottom; alternative to backing or thickness.
//   thickness = Total axial height from the bottom to the highest generated tip; alternative to backing or bottom.
//   shaft_diam = Axial bore diameter; smaller than the tooth band's inner diameter. Module only. Default: 0.
//   $gear_steps = Samples along each tooth flank; integer at least 4. Default: 16.
//   slices = Number of radial intervals; integer at least 2. Default: 12.
//   search_steps = Intervals for locating generating-envelope extrema; integer at least 8. Default: 24.
//   gear_spin = Local tooth phase in degrees. Use gear_spin() to drive an attached chain. Default: 0.
//   anchor = Named "pitchplane" or "root", or a standard directional anchor. Automatically attached children accept pitchplane, CENTER, BOT and TOP. Default: "pitchplane".
//   spin = Rotation after anchoring. Default: 0.
//   orient = Gear-axis direction. Default: UP.
// Side Effects:
//   Publishes shared gear parameters for construction inheritance and attach_gear() motion propagation.
//   $parent_gear_shaft_offset and $parent_gear_face_width contain the resolved face-gear dimensions.
//   See attach_gear() for the $gear_rotation, $gear_ratio, $gear_input and frame-history variables.
// Example(3D,Med,NoScales): A face gear and its inherited cylindrical worm.
//   worm_face_gear(mod=2, teeth=40, worm_diam=20, shaft_offset=35,
//                  face_width=18, backing=3, backlash=.15)
//       recolor("lightblue")
//       attach_gear(90) worm(l=65);
// Example(3D,Med,NoScales): Asymmetric flanks, inherited by the matching cylindrical worm.
//   worm_face_gear(mod=2, teeth=40, worm_diam=20, worm_starts=2,face_width=18,
//                  pressure_angle=[45,5], backing=3, backlash=.2)
//       recolor("lightblue")
//       attach_gear(90) worm(l=65);
// Example(3D,Anim,FrameMS=55,Frames=20,NoScales,VPR=[55.00,0.00,25.00],VPD=292.71,VPT=[34.18,18.31,-26.67]): A worm face drive animation
//   gear_spin(360*$t)
//       color_this("lightblue")
//       worm(mod=2, d=20, starts=1, l=60)
//           attach_gear(angle=90)
//               worm_face_gear(teeth=40, shaft_offset=35, face_width=8,
//                              backing=3, backlash=.15);


///   Automatic layouts retain full nominal tooth height and a tip chord at least min_tip+0.05*module.
///   At sampled heights below the pitch plane, the neck chord must be at least 80% of the
///   pitch-plane chord, and its estimated normal thickness must be at least module/2.
///   The projected axial overlap must be at least 1.5 thread pitches, and the tooth band's
///   inner edge stays at least 0.05*module beyond the opposite-working-region limit.
///   The final check samples nine radii and five heights independently of mesh tessellation.
///   These are geometric design criteria, not a guarantee of load capacity or absence of all undercut.
///   If no suitable automatic layout is found, revise the tooth parameters or increase face_width.
///   With both dimensions explicit, the original tooth-survival and tip-shortening rules apply.


function worm_face_gear(
    teeth,backing,face_width,_named,mod,circ_pitch,diam_pitch,worm_diam,worm_starts,
    shaft_offset,pressure_angle,clearance,backlash,min_tip,left_handed,
    bottom,thickness,slices=12,search_steps=24,gear_spin=0,anchor="pitchplane",spin=0,orient=UP,worm_root_diam,gear_diam
) =
    assert(is_undef(_named),"\nToo many positional arguments (only 3 are accepted)")
    assert(is_finite(gear_spin),"\ngear_spin must be finite")
    let(P=_wfg_arguments(teeth,worm_diam,worm_starts,shaft_offset,face_width,pressure_angle,
                        clearance,backlash,min_tip,mod,circ_pitch,diam_pitch,worm_root_diam=worm_root_diam,left_handed=left_handed,gear_diam=gear_diam),
        lh=default(left_handed,default($parent_gear_left_handed,false)))
    assert(is_bool(lh),"\nleft_handed must be boolean")
    let(data=_wfg_build(P,slices,is_undef($gear_steps)?16:$gear_steps,search_steps),
        body=_wfg_body(P,data,backing,bottom,thickness,lh))
    reorient(anchor,spin,orient,geom=_wfg_geom(P,body),p=zrot(gear_spin,p=body[0]));

module worm_face_gear(
    teeth,backing,face_width,_named,mod,circ_pitch,diam_pitch,worm_diam,worm_starts,
    shaft_offset,pressure_angle,clearance,backlash,min_tip,left_handed,
    bottom,thickness,slices=12,search_steps=24,shaft_diam=0,
    gear_spin=0,anchor="pitchplane",spin=0,orient=UP,worm_root_diam,gear_diam
) {
    assert(is_undef(_named),"\nToo many positional arguments (only 3 are accepted)");
    P=_wfg_arguments(teeth,worm_diam,worm_starts,shaft_offset,face_width,pressure_angle,
                    clearance,backlash,min_tip,mod,circ_pitch,diam_pitch,worm_root_diam=worm_root_diam,left_handed=left_handed,gear_diam=gear_diam);
    F=P[0];
    lh=default(left_handed,default($parent_gear_left_handed,false));
    assert(is_bool(lh),"\nleft_handed must be boolean");
    assert(is_finite(shaft_diam) && shaft_diam>=0 && shaft_diam<2*P[3],
           "\nshaft_diam must be nonnegative and smaller than the tooth band's inner diameter");
    data=_wfg_build(P,slices,is_undef($gear_steps)?16:$gear_steps,search_steps);
    body=_wfg_body(P,data,backing,bottom,thickness,lh);
    pa=_wfg_pressure_angle(pressure_angle);
    _spec=_gear_spec("worm_face",F[0],F[1],pa,thickness=body[2]-body[1],
                    worm_diam=2*F[2],starts=F[3],left_handed=lh,clearance=P[1],
                    family_data=[P,body[1],body[2]]);
    _geom=_wfg_geom(P,body);
    _pose=_gear_pose(_spec,gear_spin,anchor,spin,orient,geom=_geom);
    _gear_place(_pose)
    attachable(anchor,spin,orient,geom=_geom) {
        difference() {
            vnf_polyhedron(zrot(_pose[1],p=body[0]),convexity=12);
            if(shaft_diam>0)
                move([0,0,(body[1]+body[2])/2])
                    cylinder(d=shaft_diam,h=body[2]-body[1]+2,center=true,$fn=max(12,segs(shaft_diam/2)));
        }
        _gear_publish(_spec,_pose) children();
    }
}


/// Position limits include BOTH full-height end coverage and clearance from
/// the other tooth band. pos always follows the worm's native positive Z axis.
function _wfg_attachment_limits(P,W,pos,side=1) =
    let(F=P[0],q=side*(W[10]?-1:1),span=_wfg_span(P),station=q*mean(span)-pos,
        needed=sort([q*span[0]-station,q*span[1]-station]),limits=W[16],
        cover=[pos+limits[1]-needed[0],pos+limits[2]-needed[1]],
        bound=mean(span)+span[0]-W[9]/2,
        allowed=q>0?[cover[0],min(cover[1],bound)]:[max(cover[0],-bound),cover[1]])
    [needed,allowed,cover,2*(q*station+span[0])];

/// Round recommendations into the permitted interval, keeping four significant
/// digits where possible. format_float() avoids OpenSCAD's six-digit truncation.
function _wfg_advice_step(x) = pow(10,floor(log(max(1e-100,abs(x))))-3);
function _wfg_advice_up(x) = quantup(x,_wfg_advice_step(x));
function _wfg_advice_down(x) = quantdn(x,_wfg_advice_step(x));

function _wfg_position_advice(P,W,pos,side=1,shift_dir=1) =
    let(Q=_wfg_attachment_limits(P,W,pos,side),
        allowed=shift_dir>0?Q[1]:-reverse(Q[1]),cover=Q[2],
        step=min(_wfg_advice_step(max(abs(allowed[0]),abs(allowed[1]))),
                 _wfg_advice_step(allowed[1]-allowed[0])),
        lo=quantup(allowed[0],step),hi=quantdn(allowed[1],step))
    allowed[0]<=allowed[1]
      ?str(" Set shift between ",format_float(lo)," and ",format_float(hi),".")
      :cover[0]>cover[1]
        ?" Changing shift alone cannot cover the tooth band."
        :" No shift covers the tooth band without reaching the opposite side of the wheel.";

/// A sufficient length at the CURRENT pos. The saved upper-end allowance
/// includes one thread-sampling step, so changing length cannot invalidate the
/// recommendation by moving the threading lattice. This is a sufficient length
/// rounded upward for display, rather than a minimum-length optimization.
function _wfg_length_for_pos(P,W,pos,side=1) =
    let(needed=_wfg_attachment_limits(P,W,pos,side)[0],limits=W[16])
    2*max(limits[1]+W[9]/2-needed[0],limits[3]+needed[1]);

/// Largest face width that fits the current worm and pos when OUTSIDE diameter
/// and shaft offset stay fixed. Reducing width moves the inner edge outward;
/// both full-height coverage and opposite-band separation then improve.
function _wfg_width_for_pos(P,W,pos,side=1) =
    let(F=P[0],q=side*(W[10]?-1:1),span=_wfg_span(P),limits=W[16],
        half=min(pos-limits[1],limits[2]-pos),
        ymax=F[4]+sqrt(pow(F[2]+F[0],2)-pow(F[2]-F[0],2)),
        inner=max(0,span[1]-2*half,(W[9]+2*q*pos-span[1])/3))
    half<0 ? undef : P[4]-sqrt(ymax*ymax+inner*inner);

function _wfg_dimension_advice(P,W,pos,short=true,side=1) =
    let(Q=_wfg_attachment_limits(P,W,pos,side),eps=1e-7*max(P[4],W[9]),
        minlen=_wfg_length_for_pos(P,W,pos,side),
        length=short?_wfg_advice_up(minlen+eps):_wfg_advice_down(Q[3]-eps),
        length_ok=length>=minlen && length<=Q[3] && (short?length>W[9]:length<W[9]),
        maxwidth=_wfg_width_for_pos(P,W,pos,side),
        width=is_def(maxwidth)?_wfg_advice_down(maxwidth-eps):undef,
        width_ok=is_def(width) && width>0 && width<P[4]-P[3])
    str(length_ok?str(Q[1][0]<=Q[1][1]?" Alternatively, at the current shift, ":" At the current shift, ",short?"increase":"reduce",
                     " worm_length by ",format_float(abs(length-W[9]),8),
                     " to ",format_float(length),"."):"",
        width_ok?str(" Or reduce face_width by about ",format_float(P[4]-P[3]-width,4),
                     " to ",format_float(width),", keeping gear_diam=",format_float(2*P[4],8),
                     " and shaft_offset=",format_float(P[0][4],8),"."):"",
        !length_ok && !width_ok?" Change shift and worm_length together, or revise the wheel dimensions.":"");

function _wfg_coverage_error(P,W,pos,side=1,shift_dir=1) =
    let(Q=_wfg_attachment_limits(P,W,pos,side),needed=Q[0],limits=W[16],
        short=[max(0,limits[1]-needed[0]),max(0,needed[1]-limits[2])])
    str("\nWorm is too short",
        short[0]>1e-9?str(" at its z- end by ",format_float(short[0],4)):"",
        short[0]>1e-9 && short[1]>1e-9?" and":"",
        short[1]>1e-9?str(" at its z+ end by ",format_float(short[1],4)):"",".",
        _wfg_position_advice(P,W,pos,side,shift_dir),_wfg_dimension_advice(P,W,pos,side=side));

function _wfg_opposite_error(P,W,pos,side=1,shift_dir=1) =
    str("\nWorm reaches the opposite tooth band at its ",(side*(W[10]?-1:1)<0)?"z+":"z-"," end.",
        _wfg_position_advice(P,W,pos,side,shift_dir),_wfg_dimension_advice(P,W,pos,false,side));


/// shift translates the child along the worm's Z+ in either nesting order.
/// The private pos coordinate selects the point on the worm at the mesh center;
/// it has the opposite sign when the worm itself is the translated child.
/// The face gear uses its pitch plane as its canonical mechanical reference.
/// RIGHT selects the original offset-side branch. LEFT reverses the worm
/// relative to the wheel, selecting the other offset side and working branch.
/// A Y half-turn reverses a canonical worm without changing its FRONT valley
/// phase; asymmetric flank angles must be exchanged. The frame rolls below
/// are canceled in tooth phase, so ordinary children get the documented axes.
function _gear_worm_face_pose(A,B,angle,shift,offset,anchor,worm_face_pos=RIGHT) =
    let(pworm=A[0]=="worm",W=pworm?A:B,G=pworm?B:A,P=G[16][0],F=P[0],
        side=pworm?worm_face_pos.x:1,pos=pworm?shift:-shift,
        q=W[10]?-1:1,ratio=F[1]/F[3],span=_wfg_span(P),station=q*mean(span)-side*pos,
        needed=sort([side*(q*span[0]-station),side*(q*span[1]-station)]),
        limits=W[16])
    assert(_gear_same_number(W[7],G[7]) && W[8]==G[8] && W[10]==G[10],
           "\nWorm-face mates must have matching worm_diam, worm_starts and handedness")
    assert(pworm?in_list(anchor,["pitchplane",CENTER,BOT,TOP]):anchor==CENTER,
           "\nA worm child requires CENTER; a face-gear child accepts pitchplane, CENTER, BOT or TOP")
    assert(needed[0]>=limits[1]-1e-9 && needed[1]<=limits[2]+1e-9,
           _wfg_coverage_error(P,W,pos,side,pworm?1:-1))
    assert(q*station-W[9]/2>=-span[0]-1e-9,
           _wfg_opposite_error(P,W,pos,side,pworm?1:-1))
    // angle specifies the contact azimuth, independently of the shaft offset.
    // The same beta in placement and tooth phase preserves the generating mesh.
    let(base=90+ratio*(90-F[10])+_wfg_center_phase(P)-q*side*pos/F[6]*180/PI,
        zeta=angle-90,beta=angle+(side>0?0:180),
        T0=move([station,F[4],F[2]])*yrot(90),
        T=pworm?zrot(beta)*yrot(side>0?0:180)*rot_inverse(T0)*zrot(-90)
               :zrot(zeta)*T0*zrot(90),
        slope=pworm?side*q/ratio:q*ratio,
        phase=pworm?-q/ratio*(side*beta+base)+90:base-q*ratio*zeta-90,
        contact=pworm?unit([-F[4],q*mean(span),0]):FWD)
    _gear_finish_pose(T,slope,phase,offset,360/(pworm?F[1]:F[3]),contact,
                      _gear_anchor_transform(B,anchor));

// Function&Module: globoid_worm()
// Synopsis: Creates an enveloping hourglass-shaped worm for a double-enveloping worm drive pair.
// SynTags: Geom, VNF
// Topics: Gears, Parts
// See Also: globoid_worm_gear(), globoid_worm_dist(), globoid_worm_root_radius(), worm(), worm_gear(), attach_gear(), globoid_worm_max_length(), globoid_worm_outer_radius()
// Usage: Function
//   vnf = globoid_worm([mod=|circ_pitch=|diam_pitch=], d|worm_diam=, l|length=|h=|height=|worm_length=, teeth=|mate_teeth=, [starts=|worm_starts=], [pressure_angle=], [clearance=], [mesh_tol=], [rounding=], [left_handed=], [gear_spin=], [anchor=], [spin=], [orient=], [lead_in=]);
// Usage: Module
//   globoid_worm([mod=|circ_pitch=|diam_pitch=], d|worm_diam=, l|length=|h=|height=|worm_length=, teeth=|mate_teeth=, [starts=|worm_starts=], [pressure_angle=], [clearance=], [mesh_tol=], [rounding=], [left_handed=], [lead_in=], [gear_spin=], [shaft_diam=], [anchor=], [spin=], [orient=]) [ATTACHMENTS];
// Description:
//   Creates an enveloping, hourglass-shaped worm that meshes with
//   a matching worm gear produced by {{globoid_worm_gear()}} to form a double-enveloping, or globoid, gear pair
//   that mate using perpendicular, offset shafts.  
//   The worm wraps around the worm gear, and the worm gear wraps around the worm. This can
//   spread the load over more tooth contact than a cylindrical worm drive, allowing
//   greater load capacity in a compact pair.
//   See [A Quick Introduction to Gears: Worm Drive](gears.scad#subsection-worm-drive).
//   You must specify tooth size using `mod=`, `circ_pitch=`, or `diam_pitch=` or inherit it from
//   a parent gear.  You can specify the working diameter with `d=` or `worm_diam=` or you can
//   specify `worm_root_diam=` which gives the minimum central diameter, ensuring adequate space for a shaft. 
//   The worm and its mated globoid worm gear 
//   must have matching tooth size, starts, pressure angle, and handedness.
//   The globoid worm gear uses the worm's working length in its design. Use the same
//   length on both parts. Giving `length="max"` selects the maximum supported working
//   length.  You can compute the maximum length with {{globoid_worm_max_length()}}.  The length is
//   also available to children as `$worm_length`.  
//   .
//   The gear appears centered, oriented in the Z direction.  The FRONT point of the gear
//   (on the Y- axis) is a tooth valley so it can mesh with a tooth on the worm gear.
//   Use {{globoid_worm_dist()}} to determine the proper center-to-center space between the globoid worm and its worm gear.
//   For such applications as attaching a shaft or creating a hole it is useful to know the root radius
//   of the gear.  You can calculate this using {{globoid_worm_root_radius()}}.  
//   of the gear. You can calculate this using {{globoid_worm_root_radius()}}. The
//   nominal outer radius is given by  {{globoid_worm_outer_radius()}}. 
//   .
//   The `pressure_angle` can be a scalar valued angle to produce standard
//   symmetric teeth, but you can also give a pair, `[pa_bot,pa_top]` to produce a worm with asymmetric teeth.
//   In this case `pa_bot` gives the pressure angle of the tooth bottom (flank facing Z-) and `pa_top` gives the pressure
//   angle of the top of the tooth (flank facing Z+).  A pair like `[45,5]` gives an asymmetric form
//   can reduce overhangs for 3D printing, but due to the high pressure angle on the bottom
//   it is best suited to driving only in one direction.  
//   Give the mating worm gear the SAME ordered pair.  The asymmetric worm assembles
//   with the same spacing as a standard worm.  Giving a pair like `[20,20]` is equivalent
//   to giving a scalar value.  
//   .
//   The mesh quality is controlled by `mesh_tol`, which defaults to module/100.  Adjust this
//   value to control how coarse or fine the mesh is, with smaller values giving a finer mesh.
//   The `$fn`, `$fs` and `$fa` parameters only control the segments on the shaft hole. 
//   .
//   The `clearance=` parameter specifies
//   the nominal extra root-depth allowance, measured radially at the worm's
//   throat. Use the same clearance on both members for matched geometry.  
//   High pressure angles or excessive clearance can leave too little tooth-tip or root space.
//   Follow numerical limits given in the error message.  
//   .
//   Optional `rounding` eases the crest shoulders and root corners and specifies
//   the maximum amount of rounding.  Root rounding fills part of the clearance allowance and is disabled when `clearance=0`.
//   .
//   The threads end with a taper whose default is one nominal tooth depth: `2*module+clearance`.
//   The `lead_in` value sets the length of the taper, or you can set it to zero to get abrupt thread termination.
//   .
//   You can position gears directly using {{globoid_worm_dist()}}, but it may be easier to use
//   {{attach_gear()}}, which positions the gears and aligns the teeth automatically.
// Arguments:
//   d/worm_diam = Worm pitch diameter at the throat. Inherits when available.
//   l/length/h/height/worm_length = Worm length, or "max" for maximum supported length. Inherits when available.
//   ---
//   mod = Normal module; mutually exclusive with the other size measures.
//   diam_pitch = Normal diametral pitch, teeth per inch.
//   circ_pitch = Normal circular pitch.
//   worm_root_diam = Positive nominal minimum worm-core diameter; alternative to worm_diam. Uses tooth size and clearance; does not cut a bore.
//   teeth/mate_teeth = Number of teeth on the mating worm gear, at least 12. Inherits when available.
//   starts/worm_starts = Number of worm starts. Inherits when available. Default: 1
//   pressure_angle = Normal pressure angle, or [pa_bot, pa_top] pair. Default: inherited from the parent gear if available, 20 otherwise.
//   clearance = Nominal extra root depth at the throat. Use the same value on the mate. Inherits from a parent {{globoid_worm()}} or {{globoid_worm_gear()}} when omitted. Default: module/4
//   rounding = Maximum corner ROUNDING. Eases crests and fills roots up to this value within the available clearance. Default: 0
//   mesh_tol = Approximate surface-detail tolerance. Smaller values give finer meshes. Default: module/100
//   left_handed = Select left-handed teeth when true. Inherits from the parent when available. Default: false (right-handed).
//   shaft_diam = Through bore. Module only. Default: 0
//   lead_in = Length of the thread taper at each end, or zero for an abrupt cutoff.  Default: one tooth depth (`2*module+clearance`)
//   gear_spin = Rotates the gear around its center by the given number of degrees without affecting any children. Use {{gear_spin()}} to drive the gear and its children.  Default: 0
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top toward, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Side Effects:
//   See {{attach_gear()}} for reference frames, units, and inheritance details.
//   Sets internal variables for gear inheritance.
//   `$worm_length` is set to the length of the worm.
//   `$gear_rotation` is set to the total gear rotation resulting from {{gear_spin()}} or {{gear_travel()}} applied to the gear chain root.
//   `$gear_angle_offset` is set to the angular tooth-alignment offset in degrees, including meshing alignment and local `gear_spin`.
//   `$gear_ratio` is set to signed angular gain: (output degrees)/(input degrees) for rotational input, or (output degrees)/(input travel) for travel input in model units.
//   `$gear_input` is set to "rotation" (degrees), "travel" (model units), or undef for an undriven chain.
//   `$gear_contact_dir` is set to the nominal engagement direction with the parent in the current child frame.
//   `$gear_contact_angle` is set to the corresponding engagement angle in degrees in the current child frame.
//   `$gear_chain_locs` is set to a list of gear center coordinates (pitch-line origins for racks) in the current child frame, with the root gear first and the current gear last.
//   `$gear_chain_axes` is set to a list of shaft-axis unit vectors (`undef` for racks) in the current child frame, with the root gear first and the current gear last.
//   `$gear_travel` is set to zero.
//   `$gear_travel_offset` is set to zero.
//   `$gear_travel_ratio` is set to zero.
// Example(VPR=[83.00,0.00,20.80]): A single-start globoid worm.
//   globoid_worm(mod=2,teeth=55,d=24,worm_length=45);
// Example(VPR=[83.00,0.00,20.80]): Same worm with 4 starts has steeper threads.
//   globoid_worm(mod=2,teeth=55,d=24,worm_length=45,starts=4);
// Example(VPR=[83.00,0.00,20.80]): Left-handed worm.
//   globoid_worm(mod=2,teeth=55,d=24,worm_length=45,
//                left_handed=true);
// Example(VPR=[83.00,0.00,20.80]): Worm with no lead in.
//   globoid_worm(mod=2,teeth=55,d=24,worm_length=45,lead_in=0);
// Example(VPR=[83.00,0.00,20.80]): Worm with rounding
//   globoid_worm(mod=2,teeth=55,d=24,worm_length=45,rounding=0.2);
// Example(VPR=[83.00,0.00,20.80]): Worm with shaft extension
//   rad = globoid_worm_root_radius(mod=2, d=30,
//                                  teeth=44, length=50);
//   globoid_worm(mod=2, d=30, l=50, teeth=44)
//      attach(TOP,BOT)
//        cyl(r=rad, h=25);
// Example(3D,Med): Mating to a globoid worm gear
//   mod = 2;
//   diam = 24;
//   teeth = 45;
//   length = 40;
//   sep = globoid_worm_dist(mod=mod, worm_diam=diam, teeth=teeth);
//   color("lightblue")
//     globoid_worm_gear(mod=2,teeth=teeth,worm_diam=diam,worm_length=length);
//   back(sep)
//     globoid_worm(mod=2,teeth=teeth,worm_diam=diam,worm_length=length,orient=RIGHT);
// Example(VPR=[83.00,0.00,20.80]): A globoid worm machined from a cylindrical blank will have the threads fade away into the blank.  To get this effect you can intersect the worm with a suitably sized cylinder.  Depending on the worm this process may clip the teeth in the middle of the worm.  We construct the worm oversized to get threads that run off the ends and clip it back to the finished length.  The mating worm gear should use the `worm_length=finished_length`, not the longer pre-trimmed length.  
//   m=2; N=55; d=24; starts=5; finished_length=60; stock_length=70;
//   limit_r=globoid_worm_root_radius(mod=m,teeth=N,d=d,starts=starts,l=finished_length);
//   intersection() {
//       globoid_worm(mod=m,d,stock_length,mate_teeth=N,starts=starts,
//                    lead_in=0,mesh_tol=.06);
//       cyl(r=limit_r,l=finished_length,$fn=144);
//   }
//   zflip_copy()
//     up(finished_length/2) cyl(r=limit_r, l=15, $fn=144, anchor=BOT);
// Example(VPR=[83.00,0.00,20.80]): Standard globoid worms may not be printable vertically without support.  Here we construct an asymmetric worm that prints without support, but it is only suited for loading in one direcction.  
//     globoid_worm(mod=2,24,45,mate_teeth=55,
//                  pressure_angle=[45,5]);
// Example(3D): A maximum-length worm with end shafts chosen to give a desired total length.
//   req_len = 145;
//   globoid_worm(mod=2,d=24,length="max",mate_teeth=55,starts=5,mesh_tol=.08) {
//     for (end=[BOT,TOP])
//       attach(end,BOT)
//         cyl(r=globoid_worm_root_radius(),
//             l=(req_len-$worm_length)/2, $fn=48);
//           attach_gear(0)
//             globoid_worm_gear(thickness=8,backlash=.15,mesh_tol=.08);
//   }
function globoid_worm(d,l,_named,teeth,worm_diam,
    mod,circ_pitch,diam_pitch,starts,worm_length,pressure_angle,clearance,
    mesh_tol,gear_spin,anchor,spin,orient,left_handed, length, h, height, worm_starts, lead_in, rounding, mate_teeth,
    worm_root_diam
) =
    let(worm_length=_globoid_length(worm_length,l,length,h,height),
        worm_diam=_gear_worm_diameter(d,worm_diam,worm_root_diam=worm_root_diam,
                mod=mod,circ_pitch=circ_pitch,diam_pitch=diam_pitch,clearance=clearance,family=2),
        teeth=_gear_mate_teeth(teeth,mate_teeth),
        starts=_gear_worm_starts(starts,worm_starts))
    assert(is_undef(_named),"\nToo many positional arguments (only 2 are accepted)")
    assert(is_undef(gear_spin) || is_finite(gear_spin), "\ngear_spin must be finite")
    let(P=_dew_parameters(teeth,worm_diam,mod,circ_pitch,diam_pitch,starts,
                          worm_length,pressure_angle,clearance,left_handed),
        tol=default(mesh_tol,P[0]/100),
        vnf=_dew_worm(P,tol,default(lead_in,2*P[0]+P[9]),default(rounding,0)),
        v=zrot((default(gear_spin,0))+(-90+180/P[10]), p=vnf))
    reorient(default(anchor,CENTER),default(spin,0),default(orient,UP),
             r=_dew_worm_radius(P[3]-P[0],P[8],P),h=2*P[8],p=v);
module globoid_worm(d,l,_named,teeth,worm_diam,
    mod,circ_pitch,diam_pitch,starts,worm_length,pressure_angle,clearance,
    mesh_tol,gear_spin,shaft_diam,anchor,spin,orient,left_handed, length, h, height, worm_starts, lead_in, rounding, mate_teeth,
    worm_root_diam
) 
    let(worm_length=_globoid_length(worm_length,l,length,h,height),
        worm_diam=_gear_worm_diameter(d,worm_diam,worm_root_diam=worm_root_diam,
                mod=mod,circ_pitch=circ_pitch,diam_pitch=diam_pitch,clearance=clearance,family=2),
        teeth=_gear_mate_teeth(teeth,mate_teeth),
        starts=_gear_worm_starts(starts,worm_starts))
{
    assert(is_undef(_named),"\nToo many positional arguments (only 2 are accepted)");
    P=_dew_parameters(teeth,worm_diam,mod,circ_pitch,diam_pitch,starts,
                      worm_length,pressure_angle,clearance,left_handed);
    tol=default(mesh_tol,P[0]/100);
    _spec = _gear_spec("globoid_worm",P[0],P[1],_globoid_pressure_angle(pressure_angle),
                           worm_diam=2*P[2],starts=P[10],worm_length=2*P[8],
                           left_handed=P[5]<0,clearance=P[9]);
    _geom = attach_geom(r=_dew_worm_radius(P[3]-P[0],P[8],P),l=2*P[8]);
    _pose = _gear_pose(_spec, default(gear_spin,0), anchor, spin, orient,geom=_geom);
    vnf=zrot((_pose[1])+(-90+180/P[10]), p=_dew_worm(P,tol,default(lead_in,2*P[0]+P[9]),default(rounding,0)));
    bore=default(shaft_diam,0);
    assert(is_finite(bore) && bore>=0, str("\n", "shaft_diam must be nonnegative and finite; got ",bore));
    assert(bore<2*(P[2]-P[0]-P[9]), str("\n", "For current parameters, shaft_diam must be less than ",2*(P[2]-P[0]-P[9])," to stay below the tooth roots; got ",bore));
    _gear_place(_pose)
    attachable(default(anchor,CENTER),default(spin,0),default(orient,UP),geom=_geom) {
        difference() {
            polyhedron(vnf[0],vnf[1],convexity=20);
            if(bore>0) cylinder(d=bore,h=4*P[8]+1,center=true);
        }
        _gear_publish(_spec,_pose) children();
    }
}


// Function&Module: globoid_worm_gear()
// Synopsis: Creates an enveloping worm gear for a double-enveloping worm drive pair.
// SynTags: Geom, VNF
// Topics: Gears, Parts
// See Also: globoid_worm(), globoid_worm_dist(), worm(), worm_gear(), globoid_worm_gear(), worm_dist(), attach_gear(), globoid_worm_max_length(), globoid_worm_gear_radius_bound()
// Usage: Function
//   vnf = globoid_worm_gear([mod=|circ_pitch=|diam_pitch=], teeth, [thickness], worm_diam=, worm_length=, [worm_starts=], [pressure_angle=], [clearance=], [backlash=], [min_tip=], [mesh_tol=], [rounding=], [chamfer=], [crowning=], [search_steps=], [left_handed=], [gear_spin=], [anchor=], [spin=], [orient=]);
// Usage: Module
//   globoid_worm_gear([mod=|circ_pitch=|diam_pitch=], teeth, [thickness], worm_diam=, worm_length=, [worm_starts=], [pressure_angle=], [clearance=], [backlash=], [min_tip=], [mesh_tol=], [rounding=], [chamfer=], [crowning=], [search_steps=], [left_handed=], [gear_spin=], [shaft_diam=], [anchor=], [spin=], [orient=]) [ATTACHMENTS];
// Description:
//   Creates an enveloping worm gear (also called a worm wheel) that meshes with a globoid worm produced by {{globoid_worm()}} to form a
//   double-enveloping, or globoid, gear pair.
//   See [A Quick Introduction to Gears: Worm Drive](gears.scad#subsection-worm-drive).
//   The worm gear wraps partway around the hourglass-shaped worm while the worm wraps around the worm gear.
//   The worm_gear and its mated worm must have matching tooth size, starts, pressure angle, worm length and handedness.
//   Since the worm gear wraps around the worm it needs the worm's diameter given either using `worm_diam=` or `worm_root_diam=`.  
//   A worm gear made for a shorter worm may interfere with the ends of a longer one.
//   Giving `worm_length="max"` selects the maximum supported working length for the
//   worm. Use the same length and clearance on both parts.  The length of the worm is 
//   available as `$worm_length` inside the gear. 
//   .
//   You control the thickness using the `thickness` parameter, which inherits from any parent that provides thickness, and otherwise defaults to `worm_diam/2`.
//   Very small worms require a smaller thickness and give an error with the default.
//   Far from the center plane of the gear the teeth naturally come to sharp points.
//   The `min_tip=` parameter limits these fragile, sharp tips by imposing a minimum width
//   across the tip of the gear, with a default of `0.4*mod`.  This process shortens the
//   tips of the teeth near the edge, which will decrease their engagement with the worm.
//   .
//   The `pressure_angle` can be a scalar valued angle to produce standard
//   symmetric teeth, but you can also give a pair, `[pa_bot,pa_top]` to produce a worm gear that mates to
//   a worm with asymmetric teeth created with the identical pressure angle pair.  
//   The asymmetric worm gear assembles with the same spacing as a standard worm.  Giving a pair like `[20,20]` is equivalent
//   to giving a scalar value.  
//   .
//   The worm gear appears with a tooth located at Y+, centered if the tooth is symmetric.
//   Use {{globoid_worm_dist()}} to determine the proper center-to-center space between the worm_gear and its worm.
//   Profile shifting is **not** supported. 
//   .
//   The worm gear is centered on the origin with its axis along Z and one tooth centered
//   on Y+. Place the worm with `back(a)` and `orient=RIGHT`, using {{globoid_worm_dist()}}
//   for `a`. 
//   For animation, use `(left_handed ? -1 : 1)*worm_starts/teeth` times the worm's
//   `gear_spin` for the worm gear's `gear_spin`.
//   .
//   The mesh quality is controlled by `mesh_tol`, which defaults to module/100.  Adjust this
//   value to control how coarse or fine the mesh is, with smaller values giving a finer mesh.
//   The `$fn`, `$fs` and `$fa` parameters only control the segments on the shaft hole. 
//   .
//   Optional `rounding` eases the crest shoulders and root corners and specifies
//   the maximum amount of rounding.  Root rounding fills part of the clearance allowance and is disabled when `clearance=0`.
//   .
//   The `crowning=` adds relief to each flank, increasing quadratically from zero at the
//   middle to the specified pitch-circle relief at each face.  A small amount of
//   crowning is useful for preventing edge loading, toleration of misalignment, and reduction of
//   noise and vibration.  
//   .
//   The `chamfer=` parameter trims the outer rims with a simple bevel, with
//   the specified amount of setback along the gear face and the outside.
//   .
//   To create space for gears to mesh in practice you will need to set a positive value for backlash,
//   which creates extra space between the teeth.  Globoid gear pairs must have backlash applied
//   on the worm gear.  You cannot apply it to the worm, nor create backlash by adjusting the spacing
//   between the gears.  Lower mesh quality may result in more interference between parts when backlash is zero
//   or very small.
//   The `clearance` parameter specifies the nominal extra root-depth allowance for the matched globoid pair.
//   Give both members the same value.
//   Profiles with collapsed generating tips or root spaces are rejected; follow the numerical error guidance.
//   .
//   The `mesh_tol=` parameter, which defaults to module/100, controls surface sampling. The computation divides
//   the generating motion into `search_steps=` intervals 
//   that are used to locate candidate contact limits. Smaller `mesh_tol` smooths
//   facets, so decrease this to produce a finer mesh.  If interference between mating gears persists,
//   then try doubling `search_steps`.
//   .
//   You can position gears directly using {{globoid_worm_dist()}}, but it may be easier to use
//   {{attach_gear()}}, which positions the gears and aligns the teeth automatically.
//   .
//   The function {{globoid_worm_gear_radius_bound()}} returns an inexpensive upper bound
//   on the outside radius for sizing surrounding space.   This upper bound ignores
//   the tooth clipping.  
// Arguments:
//   teeth = Number of worm gear teeth, at least 12. Inherits mate_teeth from a parent globoid worm, or teeth from a parent worm gear.
//   thickness = Full axial thickness. Inherits thickness from any parent that provides it. Default: worm_diam/2.
//   ---
//   mod = Normal module.
//   diam_pitch = Normal diametral pitch, teeth per inch.
//   circ_pitch = Normal circular pitch.
//   worm_diam = Mating worm throat pitch diameter. Inherits when available; required otherwise.
//   worm_root_diam = Gives the worm root diameter, e.g. to ensure adequate space for a shaft.  An alternative to worm_diam or d. 
//   worm_length = Length of mating worm, or "max" for the maxijmum supported length.  Inherits when available.  Must match length given to {{globoid_worm()}}
//   worm_starts = Number of worm starts. Inherits when available. Default: 1
//   pressure_angle = Normal pressure angle, or [pa_bot, pa_top] pair. Default: inherited from the parent gear if available, 20 otherwise.
//   clearance = Nominal extra root allowance for the matched pair. Use the same value on the worm. Inherits from a parent {{globoid_worm()}} or {{globoid_worm_gear()}} when omitted. Default: module/4
//   backlash = Gap between two meshing teeth, in the direction along the circumference of the pitch circle.  Default: $backlash
//   min_tip = Minimum width across the tooth tips before rounding. Default: 0.4*module
//   rounding = Eases crests and fills roots only within the available clearance up to this maximum. Default: 0
//   chamfer = Amount to trim outer rims of the teeth. Default: 0
//   crowning = Extra relief per flank, measured as worm gear pitch-circle arc length; quadratic from zero at the middle to this value at each axial face. Default: 0
//   mesh_tol = Approximate surface-detail tolerance in model units. Smaller values give finer meshes. Default: module/100
//   gear_spin = Rotates the gear around its center by the given number of degrees without affecting any children. Use {{gear_spin()}} to drive the gear and its children.  Default: 0
//   left_handed = Select left-handed teeth when true. Inherits from the parent when available. Default: false (right-handed).
//   shaft_diam = Through bore. Module only. Default: 0
//   search_steps = Number of sampling intervals used to locate candidate contact limits in the generating motion; integer at least 8. Increase only when checking numerical convergence.  Default: 16
//   anchor = BOSL2 cylinder anchor using pitch radius and full thickness. Default: CENTER
//   spin = Rotation after anchoring. Default: 0
//   orient = Worm-gear axis direction. Default: UP
// Side Effects:
//   See {{attach_gear()}} for reference frames, units, and inheritance details.
//   Sets internal variables for gear inheritance.
//   `$worm_length` is set to the resolved numerical working length of the mating worm in model units.
//   `$gear_rotation` is set to the total gear rotation resulting from {{gear_spin()}} or {{gear_travel()}} applied to the gear chain root.
//   `$gear_angle_offset` is set to the angular tooth-alignment offset in degrees, including meshing alignment and local `gear_spin`.
//   `$gear_ratio` is set to signed angular gain: (output degrees)/(input degrees) for rotational input, or (output degrees)/(input travel) for travel input in model units.
//   `$gear_input` is set to "rotation" (degrees), "travel" (model units), or undef for an undriven chain.
//   `$gear_contact_dir` is set to the nominal engagement direction with the parent in the current child frame.
//   `$gear_contact_angle` is set to the corresponding engagement angle in degrees in the current child frame.
//   `$gear_chain_locs` is set to a list of gear center coordinates (pitch-line origins for racks) in the current child frame, with the root gear first and the current gear last.
//   `$gear_chain_axes` is set to a list of shaft-axis unit vectors (`undef` for racks) in the current child frame, with the root gear first and the current gear last.
//   `$gear_travel` is set to zero.
//   `$gear_travel_offset` is set to zero.
//   `$gear_travel_ratio` is set to zero.
// Example: 
//   globoid_worm_gear(mod=3, teeth=20, worm_diam=30, worm_length=25);
// Example: Multiple start worm
//   globoid_worm_gear(mod=3, teeth=20, worm_diam=30, worm_length=25,
//                     worm_starts=5);
// Example: With rounding
//  globoid_worm_gear(mod=3, teeth=20, worm_diam=30, worm_length=25, rounding=0.2);
// Example: A worm gear near the maximum allowed thickness
//  globoid_worm_gear(mod=3, teeth=20, worm_diam=30, thickness=23.9, worm_length=33);
// Example: Thick worm gear with very small `min_tip` value shows sharp edges on the teeth
//  globoid_worm_gear(mod=3, teeth=20, worm_diam=30, thickness=23.9,
//                    worm_length=33, min_tip=0.01);
// Example(3D,Med): Mating to a globoid worm
//   mod = 2;
//   diam = 24;
//   teeth = 45;
//   length = 40;
//   sep = globoid_worm_dist(mod=mod, worm_diam=diam, teeth=teeth);
//   color("lightblue")
//     globoid_worm_gear(mod=2,teeth=teeth,worm_diam=diam,worm_length=length);
//   back(sep)
//     globoid_worm(mod=2,teeth=teeth,worm_diam=diam,worm_length=length,orient=RIGHT);
// Example(3D): Asymmetric worm gear
//   m=2; N=25; d=24; s=5; L=30; pa=[40,5];
//   globoid_worm_gear(mod=m,N,19,worm_diam=d,
//       worm_length=L,worm_starts=s,pressure_angle=pa,rounding=.2,backlash=.1);
// Example(3D,Med): An asymmetric double-enveloping pair
//   m=2; N=45; d=24; s=5; L=50; pa=[45,5];
//   a=globoid_worm_dist(mod=m,teeth=N,d=d,starts=s);
//   color("lightblue") globoid_worm_gear(mod=m,N,16,worm_diam=d,
//       worm_length=L,worm_starts=s,pressure_angle=pa,rounding=.2,backlash=.1);
//   color("gold") back(a) globoid_worm(mod=m,d,L,mate_teeth=N,
//       starts=s,pressure_angle=pa,rounding=.2,orient=RIGHT);
function globoid_worm_gear(teeth,thickness,_named,worm_diam,
    mod,circ_pitch,diam_pitch,worm_starts,worm_length,pressure_angle,clearance,
    backlash,min_tip,mesh_tol,search_steps,left_handed,
    gear_spin,anchor,spin,orient,rounding,crowning,chamfer,worm_root_diam
) =
    assert(is_undef(_named),"\nToo many positional arguments (only 2 are accepted)")
    assert(is_undef(gear_spin) || is_finite(gear_spin), "\ngear_spin must be finite")
    let(P=_dew_parameters(teeth,worm_diam,mod,circ_pitch,diam_pitch,worm_starts,
                          worm_length,pressure_angle,clearance,left_handed,worm_root_diam=worm_root_diam),
        width=2*_wormgear_halfwidth(P[0],2*P[2],thickness),tol=default(mesh_tol,P[0]/100),
        vnf=_dew_wheel(P,width,_gear_backlash(backlash),default(min_tip,0.4*P[0]),
                       tol,default(search_steps,16),default(rounding,0),
                       default(crowning,0),default(chamfer,0)),
        v=zrot(default(gear_spin,0), p=vnf))
    reorient(default(anchor,CENTER),default(spin,0),default(orient,UP),r=P[3],h=width,p=v);
module globoid_worm_gear(teeth,thickness,_named,worm_diam,
    mod,circ_pitch,diam_pitch,worm_starts,worm_length,pressure_angle,clearance,
    backlash,min_tip,mesh_tol,search_steps,left_handed,
    gear_spin,shaft_diam,anchor,spin,orient,rounding,crowning,chamfer,worm_root_diam
) 
{
    assert(is_undef(_named),"\nToo many positional arguments (only 2 are accepted)");
    P=_dew_parameters(teeth,worm_diam,mod,circ_pitch,diam_pitch,worm_starts,
                      worm_length,pressure_angle,clearance,left_handed,worm_root_diam=worm_root_diam);
    width=2*_wormgear_halfwidth(P[0],2*P[2],thickness);tol=default(mesh_tol,P[0]/100);
    _spec = _gear_spec("globoid_worm_gear",P[0],P[1],_globoid_pressure_angle(pressure_angle),
                           thickness=width,worm_diam=2*P[2],starts=P[10],worm_length=2*P[8],
                           left_handed=P[5]<0,clearance=P[9]);
    _geom = attach_geom(r=P[3],l=width);
    _pose = _gear_pose(_spec, default(gear_spin,0), anchor, spin, orient,geom=_geom);
    vnf=zrot(_pose[1], p=_dew_wheel(P,width,_gear_backlash(backlash),default(min_tip,0.4*P[0]),
                       tol,default(search_steps,16),default(rounding,0),
                       default(crowning,0),default(chamfer,0)));
    bore=default(shaft_diam,0);
    assert(is_finite(bore) && bore>=0, str("\n", "shaft_diam must be nonnegative and finite; got ",bore));
    assert(bore<2*(P[3]-P[0]-P[9]), str("\n", "For current parameters, shaft_diam must be less than ",2*(P[3]-P[0]-P[9])," to stay below the tooth roots; got ",bore));
    _gear_place(_pose)
    attachable(default(anchor,CENTER),default(spin,0),default(orient,UP),geom=_geom) {
        difference() {
            polyhedron(vnf[0],vnf[1],convexity=20);
            if(bore>0) cylinder(d=bore,h=2*width+1,center=true);
        }
        _gear_publish(_spec,_pose) children();
    }
}
/// Cylindrical-worm envelope helpers.
/// Resolve inputs before automatic shifting or any trigonometric calculation.
function _wormgear_check_reference(m,teeth,d,starts,pa) =
    assert(is_finite(m) && m>0, "\nmodule must be greater than zero and finite")
    assert(is_int(teeth) && teeth>7, str("\n", "teeth must be an integer greater than 7; got ",teeth))
    assert(is_int(starts) && starts>0, str("\n", "worm_starts must be a positive integer; got ",starts))
    assert(is_finite(d) && d>0, str("\n", "worm_diam must be supplied and must be greater than zero and finite; got ",d))
    assert(d>max(2,starts)*m, str("\n", "For current parameters, worm_diam must be greater than ",max(2,starts)*m,"; got ",d))
    assert(is_list(pa)?min(pa)>=0 && max(pa)<90:is_finite(pa) && pa>=0 && pa<90, str("\n", "pressure_angle must be in [0,90) degrees; got ",pa))
    true;
function _wormgear_resolve_shift(m,teeth,d,starts,pa,ps) =
    assert(_wormgear_check_reference(m,teeth,d,starts,pa), "\nInvalid gear parameters")
    assert(is_undef(ps) || ps=="auto" || is_finite(ps), "\nprofile_shift must be a finite number or \"auto\"")
    assert((is_list(pa)?min(pa):pa)>0 || is_finite(ps), "\nAutomatic profile shifting requires both pressure angles greater than zero; give profile_shift=0 for an unshifted zero-pressure-angle wheel")
    let(x=auto_profile_shift(teeth=teeth,pressure_angle=is_list(pa)?min(pa):pa,profile_shift=ps))
    assert(is_finite(x) && abs(x)<1, str("\n", "profile_shift must be greater than -1 and less than 1; got ",x))
    x;
/// [wheel_pr, center_distance, worm_pr, axial_flank_slope, lead/radian, axial_pitch]
function _wormgear_reference(m,teeth,d,starts,pa,ps) =
    assert(_wormgear_check_reference(m,teeth,d,starts,pa), "\nInvalid gear parameters")
    assert(is_finite(ps) && abs(ps)<1, str("\n", "profile_shift must be greater than -1 and less than 1; got ",ps))
    let(cb=sqrt(1-pow(starts*m/d,2)),p=PI*m/cb,R=teeth*p/(2*PI))
    [R,R+d/2+ps*m,d/2,_worm_slopes(_worm_swap_angles(pa),cb),starts*p/(2*PI),p];
function _wormgear_halfwidth(m,d,thickness) =
    let(b=default(thickness,default($parent_gear_thickness,d/2)), limit=d-2*m)
    assert(is_finite(b) && b>0, str("\n", "thickness must be greater than zero and finite; got ",b))
    assert(b<limit,
           str("\n", is_undef(thickness)
             ? str("The default thickness of ",b," is too large for these parameters. Specify thickness greater than zero and less than ",limit)
             : str("For current parameters, thickness must be less than ",limit,"; got ",b)))
    b/2;
/// P = [R, a, worm_pr, cutter_tip_r, blank_throat_r, flank_slope,
///      signed_lead_per_rad, axial_pitch, half_thickness, backlash,
///      crown_relief_per_flank, teeth, module, min_tip]
function _wormgear_data(m,teeth,d,starts,pa,ps,clear,backlash,crown,
                        left=false,thickness,min_tip) =
    assert(is_finite(clear) && clear>=0, str("\nclearance must be nonnegative and finite; got ",clear))
    assert(is_finite(backlash) && backlash>=0, str("\nbacklash must be nonnegative and finite; got ",backlash))
    assert(is_finite(crown) && crown>=0, str("\ncrowning must be nonnegative and finite; got ",crown))
    assert(is_bool(left), "\nleft_handed must be boolean")
    let(
        ref=_wormgear_reference(m=m,teeth=teeth,d=d,starts=starts,pa=pa,ps=ps),
        H=_wormgear_halfwidth(m=m,d=d,thickness=thickness),
        nt=is_undef(min_tip)?0.4*m:min_tip,
        rt=d/2+m+clear
    )
    assert(is_finite(x=nt) && nt>0, str("\n", "min_tip must be greater than zero and finite; got ",nt))
    assert(ref[1]>rt, "\ncutter reaches the wheel axis; increase teeth")
    assert(_worm_full_tip(pa))
    [ref[0],ref[1],ref[2],rt,d/2-m,ref[3],(left?-1:1)*ref[4],ref[5],H,
     backlash,crown,teeth,m,nt];
/// Extended cutter flanks can meet before reaching the requested tip extension.
/// Stop at that point. Crowning widens the interval locally, so its terminal
/// radius is section-dependent. There is no arbitrary pressure-angle cap here.
function _wormgear_cutter_radius(z,P) =
    let(k=_worm_mean_slope(P[5]))
    k==0 ? P[3] :
    min(P[3],P[2]+(P[7]/4+P[9]/2+P[10]*pow(z/P[8],2))/k);
/// A zero-width cutter tip produces a point valley in this wheel section.
/// Its coincident root-arc vertices must be merged topologically, not displaced.
function _wormgear_point_root(z,P) =
    let(k=_worm_mean_slope(P[5]))
    k>0 && P[3]>=P[2]+(P[7]/4+P[9]/2+P[10]*pow(z/P[8],2))/k-1e-12*P[12];
/// Angular interval cut by ONE worm thread on a wheel-centered circle.
/// Let t be the wheel angle at contact, with physical coordinates
///   x=a-rho*cos(t), y=rho*sin(t), r=sqrt(x*x+z*z).
/// A cutter flank at axial coordinate +/-w(r)-h*atan2(z,x) reaches this
/// point when the equivalent rack has translated -R*psi. Eliminating psi:
///   angle=(y+h*atan2(z,x)+/-w(r))/R - t, in radians.
/// As t ranges between the two intersections with the cutter-tip cylinder,
/// the cut intervals form a connected union (they meet at t=0).
/// Its min/max bounds therefore select the EXPOSED envelope, including
/// tip-generated roots and undercut, not just local tangency candidates.
function _wormgear_cutangle(t,rho,z,side,P) =
    let(
        x=P[1]-rho*cos(t),
        r=sqrt(x*x+z*z),
        half=P[7]/4-_worm_side_slope(P[5],side)*(r-P[2])+P[9]/2+P[10]*pow(z/P[8],2),
        w=is_list(P[5])?half:max(0,half)
    )
    (rho*sin(t)+P[6]*atan2(z,x)*PI/180+side*w)/P[0]*180/PI-t;
/// Positive factor R times derivative of cutangle with respect to t.
function _wormgear_cutderiv(t,rho,z,side,P) =
    let(
        x=P[1]-rho*cos(t),
        y=rho*sin(t),
        r=sqrt(x*x+z*z)
    )
    rho*cos(t)-P[0]-y*(P[6]*z/(r*r)+side*_worm_side_slope(P[5],side)*x/r);
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
        rt=_wormgear_cutter_radius(z,P),
        root=P[1]-sqrt(rt*rt-z*z),
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
/// Transverse chord between the two flanks; negative means overlapping cuts.
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
/// One CCW tooth followed by its root gap. All rows have the same point count.
/// Return [points, shortened, top_radius, transverse_target]. A tooth can be
/// wider ABOVE its undercut root, so do not require min_tip at the root.
function _wormgear_section(z,P,nprofile,narc,nsearch,niters,target,max_radius) =
    let(
        goal=is_undef(target)?P[13]:target,
        period=360/P[11], base=90-period/2,
        rt=_wormgear_cutter_radius(z,P),
        root=P[1]-sqrt(rt*rt-z*z),
        blank0=P[1]-sqrt(P[4]*P[4]-z*z),
        blank=is_undef(max_radius)?blank0:min(blank0,max_radius),
        check=assert(blank>root+1e-8*P[12],
                     "\nface_chamfer removes the tooth; reduce face_chamfer"),
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
           str("\n", "cannot retain min_tip=",P[13]," at z=",z,
               ". Reduce face_chamfer (when used), thickness, or revise the tooth parameters; ",
               "the requested minimum has not been relaxed."))
    let(
        last_good=clipped?good[len(good)-1]:0,
        top=clipped ? _wormgear_tipradius(z=z,P=P,lo=rr0[last_good],hi=rr0[last_good+1],
                                          target=goal,nsearch=nsearch,niters=niters) : blank,
        // When the extended tip is clipped, the clearance band may be much
        // thinner than one uniform radial step. Resolve its outer boundary
        // explicitly so a triangle does not bridge straight into the contact
        // surface. Keep the same profile count and unchanged ordinary sampling.
        working_root=P[1]-sqrt(pow(P[2]+P[12],2)-z*z),
        band=_wormgear_point_root(0,P) && working_root>root+1e-10*P[12]
             && working_root<root+(top-root)/nprofile,
        rr=band ? [root,for(j=[1:1:nprofile]) working_root+(top-working_root)*(j-1)/(nprofile-1)]
                : [for(j=[0:1:nprofile]) root+(top-root)*j/nprofile],
        bb=[for(r=rr) _wormgear_cutlimits(rho=r,z=z,P=P,nsearch=nsearch,niters=niters)],
        gaps=[for(b=bb) period-b[1]+b[0]]
    )
    assert(min(gaps)>1e-9,
           "\ngenerated cuts remove the tooth; reduce backlash/crowning or revise tooth parameters")
    assert(top*cos(gaps[nprofile]/2)>root+1e-8*P[12],
           str("\n", is_undef(max_radius)
                ? "min_tip leaves insufficient tooth height; reduce thickness or revise tooth parameters"
                : "face_chamfer/min_tip leaves insufficient tooth height; reduce face_chamfer or thickness"))
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
/// Squared distances in 3D. Segment/segment minimum consists of the four
/// endpoint/segment minima plus the interior stationary point (if feasible).
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
/// Pairs of opposite crest segments closer than the required width. Skipping
/// pairs already separated enough in z is an exact lower-bound optimization.
/// Each entry is [left_segment_index, right_segment_index, target_multiplier].
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
/// First solve the transverse problem, then enlarge only affected transverse
/// targets until opposite CREST EDGES are separated in 3D. This handles skew,
/// not just vanishing tooth width at one z. Cached unaffected sections are reused.
/// The small scale-relative margin also covers ordinary STL float rounding.
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
           "\n3D min_tip constraint did not converge; increase slices or reduce thickness (minimum not relaxed)")
    let(
        next=[for(j=[0:1:len(zs)-1]) goals[j]*max([
            1, for(b=bad) if(j==b[0] || j==b[0]+1 || j==b[1] || j==b[1]+1) b[2]
        ])]
    ) _wormgear_blunt_sections(zs=zs,P=P,nprofile=nprofile,narc=narc,nsearch=nsearch,niters=niters,targets=next,previous=secs,n=n-1,limits=limits);
/// Rows run TOP to BOTTOM, counterclockwise around each section. The face
/// winding below follows OpenSCAD/BOSL2's clockwise-outside convention.
/// Caps use explicit flank strips and a fan restricted to the central core.
/// Cap a known tooth outline in linear time; never fan over its tooth tips.
/// nf counts points on EACH flank, nt/nr count crest/root arc intervals.
/// -1 denotes the cap center and nc denotes the next tooth's first root.
/// The flank strip, crest segment and convex central core share all edges.
function _wormgear_cap(nf,nt,nr) =
    let(nc=2*nf+nt+nr-2,rr=2*nf+nt-2)
    [for(i=[0:nf-2]) each [[i,i+1,rr-i-1],[i,rr-i-1,rr-i]],
     if(nt>1)for(i=[1:nt-1]) [nf-1,nf-1+i,nf+i],
     [-1,0,rr],for(i=[rr:nc-1])[-1,i,i+1]];
function _wormgear_mesh(rows,teeth,nprofile,narc) =
    let(nr=len(rows),nc=len(rows[0]),per=nc/teeth,
        v=[for(row=rows)each row],nv=len(v),
        cap=_wormgear_cap(nprofile+1,1,narc),
        caps=[for(end=[0,1],k=[0:teeth-1],f=cap)
            let(g=[for(i=f)i<0?nv+end:end*(nr-1)*nc+(k*per+i)%nc])
            end==0?[g[2],g[1],g[0]]:g],
        faces=[for(j=[0:nr-2],i=[0:nc-1])each
            let(a=j*nc+i,b=j*nc+(i+1)%nc,c=(j+1)*nc+i,d=(j+1)*nc+(i+1)%nc)
            ((i+j)%2==0?[[a,b,c],[c,b,d]]:[[a,b,d],[a,d,c]])])
    [concat(v,[[0,0,rows[0][0].z],[0,0,rows[nr-1][0].z]]),concat(caps,faces)];
/// Merge only the known collapsed root-arc vertices, including the next-tooth
/// seam. Other vertices stay untouched. This also handles sections where a
/// pointed root changes back to a finite root land as crowning increases.
function _wormgear_close_point_roots(vnf,point_rows,nprofile,narc,teeth) =
    !in_list(true,point_rows) ? vnf :
    let(nt=2*nprofile+narc+1,nc=nt*teeth,
        map=[for(i=[0:len(vnf[0])-1])
            let(row=floor(i/nc),col=i%nc,k=floor(col/nt),j=col%nt)
            row<len(point_rows) && point_rows[row] && j>=2*nprofile+1
              ? row*nc+((k+1)%teeth)*nt : i],
        keep=[for(i=[0:len(map)-1])map[i]==i?1:0],off=cumsum(keep),
        faces=[for(f=vnf[1])
            let(g=[for(i=f)off[map[i]]-1],
                clean=[for(j=[0:len(g)-1])if(g[j]!=g[(j+len(g)-1)%len(g)])g[j]])
            if(len(clean)>=3)clean])
    [[for(i=[0:len(keep)-1])if(keep[i])vnf[0][i]],faces];
/// Equal-setback conical face trims. These operate on the meridional (r,z)
/// outside profile, NOT on the individual tooth-outline edges. The reference
/// profile is the unchamfered, min_tip-compliant sampled rim. One endpoint is
/// face_chamfer inward along the face; the other is that same distance along
/// the rim polyline. Rotating their connecting line gives the trimming cone.
/// Bevel transition rows are inserted independently of the requested slices.
function _wormgear_walk_rim(rim,d,i=0) =
    assert(i<len(rim)-1,
           "\nface_chamfer reaches the middle plane; reduce face_chamfer")
    let(delta=rim[i+1]-rim[i],length=norm(delta))
    d<=length ? rim[i]+delta*(d/length) : _wormgear_walk_rim(rim=rim,d=d-length,i=i+1);
/// Return [face_radius_after_setback, radial_slope_per_axial_depth, transition_z].
function _wormgear_face_cone(sections,chamfer,bottom=false,tolerance=0) =
    let(
        n=len(sections)-1,
        rim=[for(j=[0:1:n/2])
            let(k=bottom?n-j:j) [sections[k][2],abs(sections[k][0][0].z)]],
        B=_wormgear_walk_rim(rim=rim,d=chamfer),
        A=[rim[0].x-chamfer,rim[0].y],
        dz=A.y-B.y
    )
    assert(dz>3*tolerance, "\nface_chamfer is below axial mesh precision; increase it or use zero")
    assert(B.y>0 && dz>0 && A.x>0 && B.x>A.x,
           "\nface_chamfer is too large or cannot form an inward conical trim")
    [A.x,(B.x-A.x)/dz,B.y];
function _wormgear_insert_z(zs,z,eps,i=0) =
    i==len(zs)?concat(zs,[z]):
    abs(z-zs[i])<=eps?zs:
    z>zs[i]?[for(j=[0:1:i-1]) if(i>0) zs[j],z,for(j=[i:1:len(zs)-1])zs[j]]:
    _wormgear_insert_z(zs=zs,z=z,eps=eps,i=i+1);
function _wormgear_insert_zs(zs,extra,eps,i=0) =
    i==len(extra)?zs:_wormgear_insert_zs(zs=_wormgear_insert_z(zs=zs,z=extra[i],eps=eps),extra=extra,eps=eps,i=i+1);
/// Linear interpolation of the radius/target field on the descending-z rim.
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
    assert(is_finite(x=face_chamfer) && face_chamfer>=0,
           "\nface_chamfer must be finite and nonnegative")
    assert(face_chamfer==0 || face_chamfer>=max(1e-6*P[12],2e-7*P[0]),
           "\nface_chamfer is below mesh precision; increase it or use zero")
    assert(is_finite(x=slices) && slices==floor(slices) && slices>0,
           "\nslices must be a positive integer")
    assert(is_finite(x=nprofile) && nprofile==floor(nprofile) && nprofile>=4,
           "\n$gear_steps must be an integer >= 4")
    assert(is_finite(x=nsearch) && nsearch==floor(nsearch) && nsearch>=8,
           "\nsearch_steps must be an integer >= 8")
    assert(is_finite(x=niters) && niters==floor(niters) && niters>=10,
           "\nInternal cylindrical envelope refinement count must be an integer >= 10")
    let(
        ns=2*ceil(slices/2), na=max(2,ceil(nprofile/4)),
        zs=[for(j=[0:1:ns]) P[8]*(1-2*j/ns)],
        base=_wormgear_blunt_sections(zs=zs,P=P,nprofile=nprofile,narc=na,nsearch=nsearch,niters=niters),
        sections=_wormgear_chamfer_sections(base=base,P=P,nprofile=nprofile,narc=na,nsearch=nsearch,niters=niters,chamfer=face_chamfer),
        rows=[for(sec=sections)
            [for(k=[0:1:P[11]-1]) each zrot(k*360/P[11]+gear_spin,p=sec[0])]]
    ) _wormgear_close_point_roots(_wormgear_mesh(rows=rows,teeth=P[11],nprofile=nprofile,narc=na),
          [for(sec=sections)_wormgear_point_root(sec[0][0].z,P)],nprofile,na,P[11]);

/// Globoid construction notes (not user documentation).
/// This is the straight-line-generated Hindley/TA family, not plane-generated TI.
/// A straight cutting line revolves about the wheel axis while the worm rotates
/// at the reciprocal ratio. The worm is the primary surface for the matching wheel.
/// The wheel finds the removed angular interval on wheel-centered circles through
/// continuous coupled motion of the finite globoid hob. Extrema include the axial
/// ends, tip edges, and smooth tangencies. Disjoint end cuts use their angular hull
/// as conservative root relief. One tooth is generated before rotational replication.
/// The worm follows straight flank generators. Flat ends are clipped numerically;
/// triangle/edge probes guide sampling. Root strips follow axial meridians, reuse
/// flank boundary vertices, and relax their sampling target only within clearance.
/// Very short cap edges are contracted with adjacent faces for stable STL export.
/// The wheel uses uniform-height rows and equal contour counts, with one explicit
/// clearance band to avoid bridging the steep cutter-tip transition. It does not
/// use the abandoned adaptive patch-merging mesher. min_tip is checked on the final
/// opposite crest polylines, not inferred only from section chord widths.
/// Background for user-facing claims: Brilianto et al., 2025,
/// https://doi.org/10.1007/s00170-025-16439-1; Polowniak et al., 2025,
/// https://doi.org/10.3390/ma18173997. More contact can improve load distribution;
/// these sources do not establish the efficiency or strength of this printed design.
/// Public aliases resolve before defaults and the geometric parameter vector.
function _globoid_length(worm_length,l,length,h,height) =
    assert(num_defined([worm_length,l,length,h,height])<=1,
           "\nspecify only one of worm_length, l, length, h, and height")
    first_defined([worm_length,l,length,h,height,$parent_gear_worm_length]);
/// ---------------------- Native geometry core ----------------------
/// Pair-defining inputs shared by the geometry and distance query.
/// The reference diameter must exceed both two modules and starts*module.
/// Clearance-dependent root radius and resolved wheel thickness are checked
/// separately. The default wheel thickness d/2 requires d>4*m, but an
/// explicitly thinner wheel permits smaller diameters.
function _globoid_check_reference(m,N,d,s) =
    assert(is_int(N) && N>=12, str("\n", "teeth must be an integer at least 12; got ",N))
    assert(is_int(s) && s>0, str("\n", "starts (worm_starts on the wheel) must be a positive integer; got ",s))
    assert(is_finite(d) && d>0, str("\n", "worm_diam must be supplied and must be greater than zero and finite; got ",d))
    assert(d>max(2,s)*m, str("\n", "For current parameters, worm_diam must be greater than ",max(2,s)*m,"; got ",d))
    true;
/// P=[module, teeth, throat_radius, wheel_pr, center_distance, signed_starts/teeth,
///    transverse_pressure_angle, blade_base_radius, half_worm_length, clearance, starts]
/// Unequal normal pressure angles describe the negative-Z and positive-Z
/// flanks at the worm's pitch-centered reference meridian. The same ordered
/// pair defines both members. Scalars and equal pairs retain the scalar path.
function _globoid_pressure_angle(pa) =
    let(a=default(pa,default($parent_gear_pa,20)))
    assert(is_finite(a) || (is_list(a) && len(a)==2 && is_finite(a[0]) && is_finite(a[1])),
           str("\npressure_angle must be a finite number or a pair of finite numbers; got ",a))
    is_list(a) && a[0]==a[1] ? a[0] : a;
/// Supported chart extent, with the same inclusive limit in queries and builds.
/// The existing 0.65 half-length restriction is well inside the meridian domain.
function _globoid_length_limit(m,N,d,s,c) =
    assert(_globoid_check_reference(m,N,d,s), "\nInvalid globoid reference parameters")
    assert(is_finite(c) && c>=0, str("\nclearance must be nonnegative and finite; got ",c))
    assert(c<d/2-m, str("\nFor current parameters, clearance must be less than ",d/2-m,
                       " to leave a positive throat root radius; got ",c))
    let(R=m*N/(2*sqrt(1-pow(s*m/d,2))),limit=1.3*(R-m-c))
    assert(limit>0, str("\nFor current parameters, clearance must be less than ",R-m,
                       " to allow a positive working length; got ",c))
    limit;
function _globoid_resolve_length(length,m,N,d,s,c,required=true) =
    let(limit=_globoid_length_limit(m,N,d,s,c))
    assert(!required || !is_undef(length),
           "\nMust give worm_length (or a length alias), inherit it, or use worm_length=\"max\"")
    assert(is_undef(length) || length=="max" || (is_finite(length) && length>0),
           str("\nworm_length must be a positive finite number or \"max\"; got ",length))
    assert(is_undef(length) || length=="max" || length<=limit,
           str("\nFor current parameters, worm_length must be no greater than ",limit,
               "; got ",length,". Use the same working length on both parts."))
    length=="max" ? limit : length;

function _gaw_asymmetric(P) = is_list(P[6]);
function _dew_parameters(N,d,mod,cp,dp,starts,length,pa,clear,left,worm_root_diam) =
    let(N=default(N,$parent_gear_wheel_teeth),
        d=_gear_worm_diameter(undef,d,worm_root_diam=worm_root_diam,
                mod=mod,circ_pitch=cp,diam_pitch=dp,clearance=clear,family=2),starts=_gear_worm_starts(undef,starts),
        length=default(length,$parent_gear_worm_length),
        clear=default(clear,_gear_worm_family($parent_gear_type)==2?$parent_gear_clearance:undef),
        left=default(left,$parent_gear_left_handed),a=_globoid_pressure_angle(pa))
    is_list(a) ? _gaw_parameters(N,d,mod,cp,dp,starts,length,a,clear,left) :
                 _dew_parameters_symmetric(N,d,mod,cp,dp,starts,length,a,clear,left);
/// P keeps the scalar layout. Only its flank angle/base-radius fields become
/// pairs. Signed half-widths may be negative: validate their SUM, not each side.
function _gaw_parameters(N,d,mod,cp,dp,starts,length,angles,clear,left) =
    let(m=_inherit_gear_pitch("globoid gears",cp,dp,mod)/PI,s=default(starts,1),
        c=default(clear,m/4),lh=default(left,false))
    assert(_globoid_check_reference(m,N,d,s), "\nInvalid globoid reference parameters")
    assert(min(angles)>0 && max(angles)<90,
           str("\nEach pressure_angle must be greater than zero and less than 90 degrees; got ",angles))
    assert(is_finite(c) && c>=0, str("\nclearance must be nonnegative and finite; got ",c))
    assert(c<d/2-m, str("\nFor current parameters, clearance must be less than ",d/2-m,"; got ",c))
    assert(is_bool(lh), "\nleft_handed must be boolean")
    let(length=_globoid_resolve_length(length,m,N,d,s,c))
    let(cb=sqrt(1-pow(s*m/d,2)),R=m*N/(2*cb),a=R+d/2,
        at=[for(an=angles)atan(tan(an)/cb)],b=[for(ax=at)R*sin(ax)],H=length/2,
        P=[m,N,d/2,R,a,(lh?-1:1)*s/N,at,b,H,c,s],et=R-m-c,er=R+m+c)
    assert(_gaw_profile_valid(P,angles),str("\n",_gaw_profile_error(P,angles)))
    P;
function _gaw_widths(e,P) =
    [for(i=[0:1])90/P[1]+P[6][i]-asin(constrain(P[7][i]/e,-1,1))];
function _gaw_half(e,P,side) =
    let(i=side<0?0:1)90/P[1]+P[6][i]-asin(constrain(P[7][i]/e,-1,1));
function _gaw_profile_valid(P,angles) =
    let(cb=sqrt(1-pow(P[10]*P[0]/(2*P[2]),2)),R=P[3],et=R-P[0]-P[9],er=R+P[0]+P[9],
        a=[for(v=angles)atan(tan(v)/cb)],b=[for(v=a)R*sin(v)],
        tip=[for(i=[0:1])90/P[1]+a[i]-asin(constrain(b[i]/et,-1,1))],
        root=[for(i=[0:1])90/P[1]+a[i]-asin(constrain(b[i]/er,-1,1))],period=360/P[1])
    max(b)<et && tip[0]+tip[1]>.02*period && root[0]+root[1]<.98*period;
function _gaw_angle_limit(P,angles,i,lo=0,hi=89.999999,n=36) =
    n==0?lo:
    let(mid=(lo+hi)/2,a=[for(j=[0:1])j==i?mid:angles[j]])
    _gaw_profile_valid(P,a) ? _gaw_angle_limit(P,angles,i,mid,hi,n-1) :
                            _gaw_angle_limit(P,angles,i,lo,mid,n-1);
function _gaw_profile_error(P,angles) =
    let(et=P[3]-P[0]-P[9],er=P[3]+P[0]+P[9],wt=_gaw_widths(et,P),wr=_gaw_widths(er,P))
    str("The asymmetric globoid generating profile does not meet its tip/root profile limits. pressure_angle=",angles,
        ", clearance=",P[9],". With the other angle fixed, angle 1 must be less than ",
        _gaw_angle_limit(P,angles,0)," degrees, or angle 2 less than ",_gaw_angle_limit(P,angles,1),
        " degrees (zero means changing that angle alone cannot satisfy this check). ",
        "Generated tip span=",wt[0]+wt[1]," degrees; root-space span=",360/P[1]-wr[0]-wr[1],
        " degrees. Both spans must exceed ",.02*360/P[1]," degrees (2% of a tooth pitch). ",
        max(P[7])>=et?"A flank generator also fails to reach the clearance-extended tip radius. ":"",
        "Use globoid_worm_pressure_angle_limit() to check one angle with the other fixed. ",
        "Reduce clearance or revise the tooth dimensions if needed; min_tip and length checks still apply.");
/// The orbit and its phase derivative are shared; each flank has its own
/// half-width derivative. The half-orbit inequality holds for either width,
/// since e(t) is even. No mirrored-tooth assumption is needed for that search.
function _gaw_fields(t,rho,z,P) =
    let(x=P[4]-rho*cos(t),y=rho*sin(t),r=sqrt(x*x+z*z),U=P[4]-r,
        e=sqrt(U*U+y*y),ep=P[4]*y*(1-x/r)/e,
        pp=(U*rho*cos(t)+x*y*y/r)/(e*e))
    [t-atan2(y,U)-P[5]*atan2(z,x),e,1-pp+P[5]*z*y/(r*r),
     [for(b=P[7])b*ep/(e*sqrt(e*e-b*b))]];
function _gaw_cut(t,rho,z,side,P,ba) =
    let(f=_gaw_fields(t,rho,z,P)) f[0]+side*(_gaw_half(f[1],P,side)+ba/(2*P[3])*180/PI);
function _gaw_dc(t,rho,z,side,P) =
    let(f=_gaw_fields(t,rho,z,P)) f[2]+side*f[3][side<0?0:1];
function _gaw_half_limits(rho,z,P,ba,lo,hi,ns,wanted) =
    let(ts=[for(i=[0:ns])lo+(hi-lo)*i/ns],fs=[for(t=ts)_gaw_fields(t,rho,z,P)])
    [for(side=is_undef(wanted)?[-1,1]:[wanted])
        let(k=side<0?0:1,
            vals=[for(f=fs)f[0]+side*(_gaw_half(f[1],P,side)+ba/(2*P[3])*180/PI)],
            roots=[for(i=[0:ns-1])let(d0=fs[i][2]+side*fs[i][3][k],d1=fs[i+1][2]+side*fs[i+1][3][k])
                if(d0*d1<0)_gaw_cut(_dew_zero(rho,z,side,P,ts[i],ts[i+1],d0),rho,z,side,P,ba)],
            all=concat(vals,roots))side<0?min(all):max(all)];
function _gaw_limits(rho,z,P,ba,ns) =
    z==0 ? let(w=_gaw_widths(rho,P),b=ba/(2*P[3])*180/PI)[-w[0]-b,w[1]+b] :
    let(o=_dew_orbit(rho,z,P),
        lower=_gaw_half_limits(rho,z,P,ba,o[0],o[1],ns,-1),
        upper=_gaw_half_limits(rho,z,P,ba,-o[1],-o[0],ns,1))
    [lower[0],upper[0]];
/// The asymmetric mesh uses common radial levels on its two straight
/// generators, preserving the existing meridian/root mesh connectivity.
/// At each radius, bounds are [negative flank, positive flank] in chi=phi-q*theta.
function _gaw_constants(P) =
    let(et=P[3]-P[0],er=P[3]+P[0]+P[9],w=_gaw_widths(et,P))
    [et,er,P[5],sign(P[5]),(w[1]-w[0])/2,0,er,et];
function _gaw_round_data(P,size,tol) =
    assert(is_finite(size) && size>=0,str("\nrounding must be nonnegative and finite; got ",size))
    let(et=P[3]-P[0],er=P[3]+P[0]+P[9],wt=_gaw_widths(et,P),wr=_gaw_widths(er,P),
        dr=min(size,P[9]/2),dt=min(size,(er-et)/4),
        kr=min(dr/er*180/PI,(360/P[1]-wr[0]-wr[1])/4),
        kt=min(dt/et*180/PI,(wt[0]+wt[1])/4))
    [size,dr,kr,dt,kt,max(2,ceil(sqrt(max(dr,dt)/tol)))];
function _gaw_bounds(e,P) =
    let(w=_gaw_widths(e,P),rd=len(P)>13?P[13]:undef)
    is_undef(rd) || rd[0]==0 ? [-w[0],w[1]] :
    let(et=P[3]-P[0],er=P[3]+P[0]+P[9],
        r=rd[1]>0?rd[2]*_globoid_ease((e-er+rd[1])/rd[1]):0,
        t=rd[3]>0?rd[4]*_globoid_ease((et+rd[3]-e)/rd[3]):0)
    [-w[0]-r+t,w[1]+r-t];
function _gaw_lead_data(P,lead_in,tol) =
    assert(is_finite(lead_in) && lead_in>=0,"\nlead_in must be nonnegative and finite; zero makes abrupt blunt ends")
    assert(lead_in==0 || lead_in>=1e-5*P[2],
           str("\nlead_in is too small for stable end geometry; use at least ",1e-5*P[2]," or use lead_in=0"))
    let(er=P[3]+P[0]+P[9],ab=_gaw_bounds(er,P),inset=min(tol/4,P[8]/100),
        half=asin((P[8]-inset)/er)-(ab[1]-ab[0])/2,
        center=-(ab[0]+ab[1])/2,
        radius=_dew_worm_radius(P[3]-P[0],P[8],P),span=abs(P[5])*lead_in/radius*180/PI)
    assert(half>0,str("\nFor current parameters, worm_length must be greater than ",
           2*er*sin((ab[1]-ab[0])/2)+2*inset," to terminate complete threads; got ",2*P[8]))
    assert(span<half,str("\nFor current parameters, lead_in must be less than ",
           half*PI/180*radius/abs(P[5]),"; got ",lead_in))
    [half,span,lead_in,tol,center];
function _gaw_lead_scales(p,lead) =
    _gw_lead_scales(p-lead[4],[lead[0],lead[1],lead[2],lead[3]]);
function _gaw_flank_tags(n,P) =
    let(rd=P[13],et=P[3]-P[0],er=P[3]+P[0]+P[9])
    rd[0]==0 ? [for(i=[0:n])i/n] :
    let(at=function(e)(er-e)/(er-et),lo=at(er-rd[1]),hi=at(et+rd[3]),k=rd[5])
    [0,if(rd[1]>0)for(j=[1:k])at(er-rd[1]+rd[1]*cos(90*j/k)),
     for(j=[1:n])lo+(hi-lo)*j/n,
     for(j=[1:k])j==k?1:at(et+rd[3]-rd[3]*sin(90*j/k))];
/// Cache each section relative to a pivot INSIDE the nominal crest interval.
/// All deeper intervals contain that pivot. Lowering increases e; contracting
/// toward the pivot therefore stays within the original nominal thread (except
/// intentional root easing, which remains in the protected clearance band).
function _gaw_profile(tags,P) =
    let(er=P[3]+P[0]+P[9],et=P[3]-P[0],pivot=P[11][4],sg=sign(P[5]))
    [for(v=tags)let(t=v<=1?v:v>=2?3-v:1,e=er+(et-er)*t,ab=_gaw_bounds(e,P),
        f=v<=1?0:v>=2?1:v-1,
        chi=sg>0?ab[1]+(ab[0]-ab[1])*f:ab[0]+(ab[1]-ab[0])*f)
        [e,e*cos(chi-pivot),e*sin(chi-pivot),v]];
function _gaw_row(p,P,profile,h,w) =
    let(er=P[3]+P[0]+P[9],pivot=P[11][4],sg=sign(P[5]),
        cp=cos(p+pivot),sp=sin(p+pivot),ct=cos(p/P[5]),st=sin(p/P[5]),
        flat=h==0 && (is_undef(P[12]) || P[12][1]==0),ab=_gaw_bounds(er,P))
    [for(c=profile)let(e=er+(c[0]-er)*h,f=c[3]<=1?0:c[3]>=2?1:c[3]-1,
        chi=sg>0?ab[1]+(ab[0]-ab[1])*f:ab[0]+(ab[1]-ab[0])*f,
        Z=flat?er*sin(chi-pivot):w*c[2],
        U=h==1 && w==1?c[1]:flat?er*cos(chi-pivot):sqrt(max(0,e*e-Z*Z)),
        r=P[4]-U*cp+Z*sp,z=U*sp+Z*cp)
        [r*ct,r*st,z]];
function _gaw_lead_stations(ps,P) =
    let(lead=P[12],c=lead[4],n=max(4,ceil(lead[2]/sqrt(8*lead[3]*(2*P[0]+P[9])))),
        extra=lead[1]==0?[c-lead[0],c+lead[0]]:
              [for(s=[-1,1],j=[0:n])c+s*(lead[0]-lead[1]*pow(sin(90*j/n),2))],
        retained=[for(p=ps)if(lead[1]==0 || abs(p-c)>lead[0] || abs(p-c)<lead[0]-lead[1])p],
        records=_gw_dedup(_sort_vectors([for(p=concat(retained,extra))[-p]],[0])))
    [for(r=records)-r[0]];
function _gaw_raw(P,na,nf,nt) =
    let(et=P[3]-P[0],er=P[3]+P[0]+P[9],ab=_gaw_bounds(er,P),
        pm=asin(P[8]/et)+max(abs(ab[0]),abs(ab[1]))+1e-5,
        period=360/P[1],nstep=max(1,ceil(period/(2*pm/na))),dp=period/nstep,
        count=ceil(pm/dp)+nstep+1,ft=_gaw_flank_tags(nf,P),
        tags=[for(i=[0:len(ft)-2])ft[i],for(i=[0:nt-1])1+i/nt,
              for(i=[len(ft)-1:-1:0])3-ft[i]],
        ps=_gaw_lead_stations([for(i=[-count:count])-i*dp],P),lead=P[12],
        high=lead[4]+lead[0],low=lead[4]-lead[0],
        stations=[for(p=ps)each lead[1]==0 && (p==high || p==low)?
            (p==high?[[p,1,0],[p,1,1]]:[[p,1,1],[p,1,0]]):
            [concat([p],_gw_lead_scales(p,lead))]],
        profile=_gaw_profile(tags,P),rows=[for(st=stations)_gaw_row(st[0],P,profile,st[2],st[1])])
    [rows,[for(st=stations)st[0]],tags,[for(st=stations)st[2]],[for(st=stations)st[1]],dp];
function _gaw_flank_excess(p,P) =
    let(r=norm([p.x,p.y]),U=P[4]-r,e=sqrt(U*U+p.z*p.z),
        ab=_gaw_bounds(e,P),center=(ab[0]+ab[1])/2,
        a=atan2(p.z,U)-P[5]*atan2(p.y,p.x),period=360/P[1],
        chi=a-period*floor((a-center)/period+.5))
    e>=P[3]+P[0]+P[9]?-1e-12:max(ab[0]-chi,chi-ab[1]);
function _gaw_root_phase(p,P,tag) =
    let(er=P[3]+P[0]+P[9],pivot=P[11][4],ab=_gaw_bounds(er,P),
        w=_gw_lead_scales(p,P[12]).x,
        chi=(tag==0)==(P[5]>0)?ab[1]:ab[0])
    p+pivot+asin(constrain(w*sin(chi-pivot),-1,1));
function _gaw_root_land(raw,P,nr,nz) =
    let(rows=raw[0],ps=raw[1],na=len(ps)-1,ns=len(raw[2]),
        N=P[10],nc=N*ns,offset=(na+1)*nc,er=P[3]+P[0]+P[9],q=P[5],shift=q*180/N,
        stations=[for(p=ps)p-shift],
        states=[for(p=stations)[_gaw_root_phase(p+shift,P,3),_gaw_root_phase(p-shift,P,0)]],
        base=[for(t=[1:1:nr-1],j=[0:na])let(p=stations[j],ab=states[j],u=ab[0]+(ab[1]-ab[0])*t/nr)
            cylindrical_to_xyz(P[4]-er*cos(u),p/q+180/N,er*sin(u))],
        points=len(base)==0?[]:[for(k=[0:N-1])each zrot(k*360/N,p=base)],
        faces=[for(k=[0:N-1])each
            let(tracks=[for(t=[0:nr])
                t==0?[for(j=[0:na])[ps[j]-shift,j*nc+k*ns+ns-1]]:
                t==nr?[for(j=[0:na])[ps[j]+shift,j*nc+((k+1)%N)*ns]]:
                [for(j=[0:na])[stations[j],offset+k*len(base)+(t-1)*(na+1)+j]]])
            [for(t=[0:nr-1])each _gw_root_zip(tracks[t],tracks[t+1])]])
    [points,faces,[for(k=[0:N-1],t=[1:1:nr-1],j=[0:na])4*k+3+t/nr]];
function _gaw_end_point(p,t,f,P,k) =
    let(er=P[3]+P[0]+P[9],et=P[3]-P[0],e=er+(et-er)*t,ab=_gaw_bounds(e,P),
        chi=P[5]>0?ab[1]+(ab[0]-ab[1])*f:ab[0]+(ab[1]-ab[0])*f,phi=p+chi)
    cylindrical_to_xyz(P[4]-e*cos(phi),p/P[5]+k*360/P[10],e*sin(phi));
function _gaw_worm_build(P,tol,n=0) =
    let(et=P[3]-P[0],er=P[3]+P[0]+P[9],ab=_gaw_bounds(er,P),wt=_gaw_widths(et,P),
        pm=asin(P[8]/et)+max(abs(ab[0]),abs(ab[1]))+1e-5,
        rmax=_dew_worm_radius(et,P[8],P),angle=2*acos(1-tol/rmax)/pow(1.3,n),
        na=ceil(2*pm/abs(P[5])/angle),
        leg=max([for(b=P[7])sqrt(er*er-b*b)-sqrt(et*et-b*b)]),
        nf=max(1,ceil(leg/(rmax*angle*PI/180))),
        nt=max(2,ceil((wt[0]+wt[1])/(2*acos(1-tol/(2*et))))),
        root_tol=max(tol,min(4*tol,P[9]/4)),wmin=P[12][1]==0?1:_leadin_sqrt(0,1).x,pivot=P[11][4],
        rootwidth=asin(wmin*sin(ab[1]-pivot))-asin(wmin*sin(ab[0]-pivot)),
        gap=360/P[10]-rootwidth/abs(P[5]),
        nr=max(1,ceil(abs(P[5])*gap/(2*acos(max(-1,1-root_tol/er))))),
        raw=_gw_make_raw(P,na,nf,nt,nr,0,tol))
    raw[1]>tol?
        assert(n<8,"\nAsymmetric worm mesh refinement did not converge; increase mesh_tol or report the parameter set")
        _gaw_worm_build(P,tol,n+1):
    let(eps=min(tol/16,(P[13][0]>0?1e-4:1e-6)*rmax))
    let(clean=_gw_flattened_rows(raw[0],raw[3],raw[2],P))
    [_gw_clip(clean[0],P[8],clean[1],4*P[10],eps,root_caps=true),[na,nf,nt,nr,raw[1],0]];
function _dew_parameters_symmetric(N,d,mod,cp,dp,starts,length,pa,clear,left) =
    let(m=_inherit_gear_pitch("globoid gears",cp,dp,mod)/PI,s=default(starts,1),an=_inherit_gear_pa(pa),
        c=default(clear,m/4),lh=default(left,false))
    assert(_globoid_check_reference(m,N,d,s), "\nInvalid gear parameters")
    assert(is_finite(an) && an>0 && an<90,"\npressure_angle must be greater than zero and less than 90 degrees")
    assert(is_finite(c) && c>=0, str("\nclearance must be nonnegative and finite; got ",c))
    assert(c<d/2-m, str("\nFor current parameters, clearance must be less than ",d/2-m,"; got ",c))
    assert(is_bool(lh),"\nleft_handed must be boolean")
    let(length=_globoid_resolve_length(length,m,N,d,s,c))
    let(cb=sqrt(1-pow(s*m/d,2)),R=m*N/(2*cb),a=R+d/2,
        at=atan(tan(an)/cb),b=R*sin(at),H=length/2,
        P=[m,N,d/2,R,a,(lh?-1:1)*s/N,at,b,H,c,s],et=R-m-c,er=R+m+c)
    assert(et>b && _dew_half_tooth(et,P)>0.02*180/N,
           str("\n",_globoid_profile_error(P,an,false)))
    assert(_dew_half_tooth(er,P)<0.98*180/N,
           str("\n",_globoid_profile_error(P,an,true)))
    P;
/// Invert the existing minimum-width checks, not a new pressure-angle cap.
/// W(e)=A+alpha-asin(R*sin(alpha)/e), A=90/N. Both checks leave
/// 0.04*A at a tip or in a root space; eps=A-0.04*A.
/// These bounds concern the nominal generating profile, not final min_tip,
/// wheel thickness, finite length, or mesh feasibility.
function _globoid_profile_limits(P) =
    let(m=P[0],R=P[3],alpha=P[6],c=P[9],
        cb=sqrt(1-pow(P[10]*m/(2*P[2]),2)),eps=0.96*90/P[1],
        et=R-m-c,er=R+m+c,
        tip_alpha=atan2(sin(eps),R/et-cos(eps)),
        root_den=cos(eps)-R/er,
        root_alpha=root_den<=0?90:atan2(sin(eps),root_den),
        tip_c=R-m-R*sin(alpha)/sin(alpha+eps),
        root_c=alpha<=eps?undef:R*sin(alpha)/sin(alpha-eps)-R-m)
    [atan(cb*tan(tip_alpha)),root_alpha==90?90:atan(cb*tan(root_alpha)),
     tip_c,root_c];
function _globoid_profile_error(P,pa,root=false) =
    let(limits=_globoid_profile_limits(P),i=root?1:0,
        max_pa=limits[i],max_clear=limits[i+2])
    str(root?"The globoid thread spaces close at the root. ":
                       "The globoid generating tooth tip is too thin. ",
        "For current parameters, pressure_angle must be less than ",max_pa,
        " degrees with clearance=",P[9],"; got ",pa,".\n",
        is_undef(max_clear) ? "This root-space check does not limit clearance at this pressure angle. " :
        max_clear>0 ?
          str("Alternatively, at pressure_angle=",pa,", clearance must be less than ",
              max_clear,"; got ",P[9],". ") :
          "No nonnegative clearance satisfies this check at the requested pressure_angle. ",
        "Reduce pressure_angle or revise the tooth count and worm diameter. ",
        "These limits address this profile check; min_tip and length limits still apply.");
function _dew_half_tooth(e,P) = 90/P[1]+P[6]-asin(constrain(P[7]/e,-1,1));
function _dew_worm_radius(e,u,P) = P[4]-sqrt(e*e-u*u);
function _dew_mesh_tolerance(tol,P) =
    assert(is_finite(tol) && tol>0, str("\n", "mesh_tol must be greater than zero and finite; got ",tol))
    assert(tol<=P[0]/4, str("\n", "For current parameters, mesh_tol must be no greater than ",P[0]/4,"; got ",tol)) true;
/// Wheel orbit: [x,y,z]=[a-rho*cos(t),rho*sin(t),z]. In worm meridian
/// coordinates: U=a-r, e=hypot(U,y), phi=atan2(y,U), gamma=atan2(z,x).
/// Eliminating both gear phases gives the cutter interval
///   [t-phi-q*gamma-W(e), t-phi-q*gamma+W(e)]
/// in wheel angle. Widen it by backlash/(2*R) on each side.
function _dew_fields(t,rho,z,P) =
    _gaw_asymmetric(P) ? _gaw_fields(t,rho,z,P) :
    let(x=P[4]-rho*cos(t),y=rho*sin(t),r=sqrt(x*x+z*z),U=P[4]-r,
        e=sqrt(U*U+y*y),ep=P[4]*y*(1-x/r)/e,
        pp=(U*rho*cos(t)+x*y*y/r)/(e*e))
    [t-atan2(y,U)-P[5]*atan2(z,x),e,
     1-pp+P[5]*z*y/(r*r),P[7]*ep/(e*sqrt(e*e-P[7]*P[7]))];
function _dew_cut(t,rho,z,side,P,ba) =
    _gaw_asymmetric(P) ? _gaw_cut(t,rho,z,side,P,ba) :
    let(f=_dew_fields(t,rho,z,P)) f[0]+side*(_dew_half_tooth(f[1],P)+ba/(2*P[3])*180/PI);
function _dew_dc(t,rho,z,side,P) =
    _gaw_asymmetric(P) ? _gaw_dc(t,rho,z,side,P) :
    let(x=P[4]-rho*cos(t),y=rho*sin(t),r=sqrt(x*x+z*z),U=P[4]-r,
        e=sqrt(U*U+y*y),ep=P[4]*y*(1-x/r)/e,
        pp=(U*rho*cos(t)+x*y*y/r)/(e*e))
    1-pp+P[5]*z*y/(r*r)+side*(P[7]*ep/(e*sqrt(e*e-P[7]*P[7])));
function _dew_zero(rho,z,side,P,lo,hi,dlo,n=26) =
    n==0?(lo+hi)/2:
    let(mid=(lo+hi)/2,dm=_dew_dc(mid,rho,z,side,P))
    dm==0?mid:dm*dlo>0?_dew_zero(rho,z,side,P,mid,hi,dm,n-1):_dew_zero(rho,z,side,P,lo,mid,dlo,n-1);
/// Radius at which the toroidal cylinder e reaches the worm's axial end.
function _dew_rim(e,z,P) =
    let(r=_dew_worm_radius(e,P[8],P))
    assert(abs(z)<r,"\nWheel thickness reaches outside the near-side globoid chart")
    sqrt(pow(P[4]-sqrt(r*r-z*z),2)+P[8]*P[8]);
function _dew_tmin(rho,z,P,tb,et,lo=0,hi,n=28) =
    let(b=is_undef(hi)?tb:hi)
    n==0?(lo+b)/2:
    let(mid=(lo+b)/2,e=_dew_fields(mid,rho,z,P)[1])
    e<et?_dew_tmin(rho,z,P,tb,et,mid,b,n-1):_dew_tmin(rho,z,P,tb,et,lo,mid,n-1);
function _dew_orbit(rho,z,P) =
    let(tb=asin(constrain(P[8]/rho,0,1)),et=P[3]-P[0]-P[9],
        e0=_dew_fields(0,rho,z,P)[1],eb=_dew_fields(tb,rho,z,P)[1],
        ta=e0>=et-1e-12*P[0]?0:eb<=et+1e-12*P[0]?tb:_dew_tmin(rho,z,P,tb,et))
    assert(eb>=et-1e-8*P[0],"\nInternal error: orbit misses generating hob") [ta,tb];
function _dew_half_limits(rho,z,P,ba,lo,hi,ns,wanted) =
    _gaw_asymmetric(P) ? _gaw_half_limits(rho,z,P,ba,lo,hi,ns,wanted) :
    let(ts=[for(i=[0:1:ns])lo+(hi-lo)*i/ns],
        fs=[for(t=ts)let(f=_dew_fields(t,rho,z,P))
             [f[0],_dew_half_tooth(f[1],P)+ba/(2*P[3])*180/PI,f[2],f[3]]])
    [for(side=is_undef(wanted)?[-1,1]:[wanted])
        let(vals=[for(f=fs)f[0]+side*f[1]],
            roots=[for(i=[0:1:ns-1])
                let(d0=fs[i][2]+side*fs[i][3],d1=fs[i+1][2]+side*fs[i+1][3])
                if(d0*d1<0)_dew_cut(_dew_zero(rho,z,side,P,ts[i],ts[i+1],d0),rho,z,side,P,ba)],
            all=concat(vals,roots)) side<0?min(all):max(all)];
/// For t>=0, y>=0 and U=a-sqrt(x*x+z*z)<=rho*cos(t), hence phi>=t.
/// W(e) and gamma are even in t: the lower bound at +t cannot exceed
/// the lower bound at -t, and the upper bound at -t cannot be smaller.
/// Search only the positive-half lower bound and negative-half upper bound.
function _dew_limits(rho,z,P,ba,ns) =
    _gaw_asymmetric(P) ? _gaw_limits(rho,z,P,ba,ns) :
    z==0?let(w=_dew_half_tooth(rho,P)+ba/(2*P[3])*180/PI)[-w,w]:
    let(o=_dew_orbit(rho,z,P),
        a=_dew_half_limits(rho,z,P,ba,-o[1],-o[0],ns,1),
        b=_dew_half_limits(rho,z,P,ba,o[0],o[1],ns,-1))
    // Conservative connected tooth space: discard residual ribs between end cuts.
    // The retained bounding flanks are still exposed cutter-envelope boundaries.
    [b[0],a[0]];
function _dew_land(rho,lim,P) =
    let(gap=360/P[1]+lim[0]-lim[1])gap<=0?-1:2*rho*sin(gap/2);
function _dew_top(z,P,ba,goal,ns,lo,hi,n=26) =
    n==0?lo:let(mid=(lo+hi)/2)
    _dew_land(mid,_dew_limits(mid,z,P,ba,ns),P)<goal?
      _dew_top(z,P,ba,goal,ns,lo,mid,n-1):_dew_top(z,P,ba,goal,ns,mid,hi,n-1);
function _dew_pointseg2(p,a,b) =
    let(v=b-a,w=p-a,t=v*v==0?0:constrain((v*w)/(v*v),0,1),d=w-t*v)d*d;
function _dew_segdist2(p0,p1,q0,q1) =
    let(u=p1-p0,v=q1-q0,w=p0-q0,a=u*u,b=u*v,c=v*v,d=u*w,e=v*w,den=a*c-b*b,
        s=den>1e-14*a*c?(b*e-c*d)/den:-1,t=den>1e-14*a*c?(a*e-b*d)/den:-1,D=w+s*u-t*v)
    min([_dew_pointseg2(p0,q0,q1),_dew_pointseg2(p1,q0,q1),_dew_pointseg2(q0,p0,p1),_dew_pointseg2(q1,p0,p1),
         if(s>=0&&s<=1&&t>=0&&t<=1)max(0,D*D)]);
/// First row strictly below a height; rows descend in z. Binary bounds avoid
/// enumerating every crest-segment pair when the worm has many axial samples.
function _dew_below(rows,z,lo=0,hi) =
    let(b=is_undef(hi)?len(rows):hi,mid=floor((lo+b)/2))
    lo>=b?lo:rows[mid][5]<z?_dew_below(rows,z,lo,mid):_dew_below(rows,z,mid+1,b);
function _dew_badlands(rows,goal) =
    [for(i=[0:1:len(rows)-2])
     let(jlo=max(0,_dew_below(rows,rows[i][5]+goal)-1),
         jhi=min(len(rows)-2,_dew_below(rows,rows[i+1][5]-goal)))
     for(j=[jlo:1:jhi])
     if(max(rows[i+1][5],rows[j+1][5])-min(rows[i][5],rows[j][5])<goal)
     let(d2=_dew_segdist2(rows[i][1],rows[i+1][1],rows[j][2],rows[j+1][2]))
     if(d2<goal*goal)[i,j,1.01*goal/sqrt(max(d2,goal*goal*1e-12))]];
function _gw_constants(P)=
    _gaw_asymmetric(P) ? _gaw_constants(P) :
 let(et=P[3]-P[0],er=P[3]+P[0]+P[9],q=P[5],sg=q>0?1:-1,
     wt=_dew_half_tooth(et,P)/abs(q),dw=sg*(_dew_half_tooth(et,P)-_dew_half_tooth(er,P)))
 [et,er,q,sg,wt,dw,sqrt(er*er-P[7]*P[7]),sqrt(et*et-P[7]*P[7])];
function _gw_lead_data(P,lead_in,tol) =
    _gaw_asymmetric(P) ? _gaw_lead_data(P,lead_in,tol) :
    assert(is_finite(lead_in) && lead_in>=0,
           "\nlead_in must be nonnegative and finite; zero makes abrupt blunt ends")
    assert(lead_in==0 || lead_in>=1e-5*P[2],
           str("\nlead_in is too small for stable end geometry; use at least ",1e-5*P[2]," or use lead_in=0"))
    let(er=P[3]+P[0]+P[9],W=_gw_section_width(er,P),root_extent=er*sin(W),
        inset=min(tol/4,P[8]/100),end=asin((P[8]-inset)/er)-W,
        radius=_dew_worm_radius(P[3]-P[0],P[8],P),
        span=abs(P[5])*lead_in/radius*180/PI)
    assert(end>0,str("\nFor current parameters, worm_length must be greater than ",
                    2*min(root_extent/.99,root_extent+tol/4)," to terminate complete threads; got ",2*P[8]))
    assert(span<end,str("\nFor current parameters, lead_in must be less than ",
                       end*PI/180*radius/abs(P[5]),"; got ",lead_in))
    [end,span,lead_in,tol];
///  Height and transverse width follow the ORIGINAL cross-section. Do not
///  multiply the widening profile exposed by clipping a tooth lower down.
///  Use the existing skin.scad square-root curve for both scale factors.
///  Normalize only its height endpoint to meet the curved root exactly.
function _gw_lead_scales(p,lead) =
    !is_undef(lead) && len(lead)>4 ? _gaw_lead_scales(p,lead) :
    is_undef(lead) ? [1,1] :
    lead[1]==0 ? [1,abs(p)<=lead[0]?1:0] :
    abs(p)<=lead[0]-lead[1] ? [1,1] :
    let(t=constrain((lead[0]-abs(p))/lead[1],0,1),
        a=_leadin_sqrt(t,1),h0=_leadin_sqrt(0,1).y)
    [a.x,constrain((a.y-h0)/(1-h0),0,1)];
function _gw_lead_scale(p,lead) = _gw_lead_scales(p,lead).y;
function _globoid_ease(u) = 1-sqrt(max(0,1-pow(constrain(u,0,1),2)));
function _gw_round_data(P,size,tol) =
    _gaw_asymmetric(P) ? _gaw_round_data(P,size,tol) :
    assert(is_finite(size) && size>=0,
           str("\nrounding must be nonnegative and finite; got ",size))
    let(et=P[3]-P[0],er=P[3]+P[0]+P[9],
        dr=min(size,P[9]/2),dt=min(size,(er-et)/4),
        kr=min(dr/er*180/PI,(180/P[1]-_dew_half_tooth(er,P))/2),
        kt=min(dt/et*180/PI,_dew_half_tooth(et,P)/2))
    [size,dr,kr,dt,kt,max(2,ceil(sqrt(max(dr,dt)/tol)))];
function _gw_section_width(e,P,h=1) =
    let(W=_dew_half_tooth(e,P),rd=len(P)>13?P[13]:undef)
    is_undef(rd) || rd[0]==0 ? W :
    let(er=P[3]+P[0]+P[9],T=lerp(P[11][6],P[11][7],h),
        tip=sqrt(T*T+P[7]*P[7]),dt=min(rd[3],(er-tip)/4),
        root=rd[1]>0 ? rd[2]*_globoid_ease((e-er+rd[1])/rd[1]):0,
        crest=dt>0 ? h*rd[4]*_globoid_ease((tip+dt-e)/dt):0)
    W+root-crest;
function _gw_lead_width(p,P,h) = _gw_lead_scales(p,len(P)>12?P[12]:undef).x;
function _gw_flank_tags(n,P) =
    _gaw_asymmetric(P) ? _gaw_flank_tags(n,P) :
    let(rd=len(P)>13?P[13]:[0]) rd[0]==0 ? [for(i=[0:n]) i/n] :
    let(et=P[3]-P[0],er=P[3]+P[0]+P[9],tr=P[11][6],tt=P[11][7],
        at=function(e) constrain((tr-sqrt(max(0,e*e-P[7]*P[7])))/(tr-tt),0,1),
        lo=at(er-rd[1]),hi=at(et+rd[3]),k=rd[5])
    [0,if(rd[1]>0) for(j=[1:k]) at(er-rd[1]+rd[1]*cos(90*j/k)),
     for(j=[1:n])lo+(hi-lo)*j/n,
     for(j=[1:k])j==k?1:at(et+rd[3]-rd[3]*sin(90*j/k))];
///  Cached one-start profile: [T, meridional_U, meridional_Z, tag]. All
///  expensive flank/rounding calculations are independent of station p.
function _gw_profile(tags,P) =
    _gaw_asymmetric(P) ? _gaw_profile(tags,P) :
    let(tr=P[11][6],tt=P[11][7],b=P[7],sg=sign(P[5]))
    [for(v=tags) let(f=v<=1?-1:v>=2?1:2*v-3,
         t=v<=1?v:v>=2?3-v:1,T=tr+(tt-tr)*t,e=sqrt(T*T+b*b),
         w=f*sg*_gw_section_width(e,P))
         [T,e*cos(w),-e*sin(w),v]];
///  One cheap station transform. Root-radius-preserving height flattening
///  and transverse width scaling give the same profile interpretation as
///  threading, in the globoid's curved meridian rather than a flat rack.
function _gw_row(p,P,profile,h,w) =
    _gaw_asymmetric(P) ? _gaw_row(p,P,profile,h,w) :
    let(tr=P[11][6],er=P[3]+P[0]+P[9],b=P[7],
        cp=cos(p),sp=sin(p),ct=cos(p/P[5]),st=sin(p/P[5]),
        oldflat=h==0 && (is_undef(P[12]) || P[12][1]==0),
        wr=_gw_section_width(er,P))
    [for(c=profile) let(T=tr+(c[0]-tr)*h,
        z0=w*c[2],
        f=c[3]<=1?-1:c[3]>=2?1:2*c[3]-3,
        Z=oldflat ? -er*sin(f*sign(P[5])*wr) : z0,
        U=h==1 && w==1 ? c[1] : oldflat ? er*cos(f*sign(P[5])*wr) :
              sqrt(max(0,T*T+b*b-Z*Z)),
        r=P[4]-U*cp+Z*sp,z=U*sp+Z*cp)
        [r*ct,r*st,z]];
function _gw_wp(p,v,P,height) =
    let(sc=_gw_lead_scales(p,len(P)>12?P[12]:undef),h=default(height,sc.y))
    _gw_row(p,P,_gw_profile([v],P),h,sc.x)[0];
///  to resolve a small end treatment. Cosine spacing resolves BOTH junctions.
function _gw_lead_stations(ps,P) =
    _gaw_asymmetric(P) ? _gaw_lead_stations(ps,P) :
    len(P)<=12 || is_undef(P[12]) ? ps :
    let(lead=P[12],n=max(4,ceil(lead[2]/sqrt(8*lead[3]*(2*P[0]+P[9])))),
        extra=lead[1]==0 ? [-lead[0],lead[0]] :
              [for(s=[-1,1],j=[0:n])s*(lead[0]-lead[1]*pow(sin(90*j/n),2))],
        // Replace, rather than superimpose on, the regular end-region grid.
        retained=[for(p=ps)if(lead[1]==0 || abs(p)>lead[0] || abs(p)<lead[0]-lead[1])p],
        recs=_gw_dedup(_sort_vectors([for(p=concat(retained,extra))[-p]],[0])))
    [for(r=recs)-r[0]];
function _gw_raw(P,na,nf,nt) =
    _gaw_asymmetric(P) ? _gaw_raw(P,na,nf,nt) :
    let(et=P[3]-P[0],er=P[3]+P[0]+P[9],
        pm=asin(P[8]/et)+_dew_half_tooth(er,P)+1e-5,
        // A whole number of samples per start spacing aligns valley tracks.
        period=360/P[1],nstep=max(1,ceil(period/(2*pm/na))),dp=period/nstep,
        count=ceil(pm/dp)+nstep+1,
        ft=_gw_flank_tags(nf,P),
        tags=[for(i=[0:len(ft)-2])ft[i],for(i=[0:nt-1])1+i/nt,
              for(i=[len(ft)-1:-1:0])3-ft[i]],
        ps=_gw_lead_stations([for(i=[-count:count])-i*dp],P),lead=P[12],
        stations=[for(p=ps)each
            !is_undef(lead) && lead[1]==0 && abs(p)==lead[0] ?
                (p>0?[[p,1,0],[p,1,1]]:[[p,1,1],[p,1,0]]) :
                [concat([p],_gw_lead_scales(p,lead))]],
        profile=_gw_profile(tags,P),
        rows=[for(st=stations)_gw_row(st[0],P,profile,st[2],st[1])])
    [rows,[for(st=stations)st[0]],tags,[for(st=stations)st[2]],
     [for(st=stations)st[1]],dp];
///  Rotate the entire one-start surface in one operation per extra start.
///  Keep row-major indexing for shared flank/root/end boundary vertices.
function _gw_expand(raw,P) =
    let(ns=len(raw[2]),one=[for(row=raw[0])each row],
        rotated=[one,for(k=[1:1:P[10]-1])zrot(k*360/P[10],p=one)],
        rows=[for(j=[0:len(raw[0])-1])
              [for(k=[0:P[10]-1],i=[0:ns-1])rotated[k][j*ns+i]]])
    [rows,raw[1],raw[2],raw[3],raw[4],raw[5]];
function _gw_trierr(p,a,b,c)=
 let(n=cross(b-a,c-a),nn=n*n,
     t=nn>0?((p-a)*n)/nn:0,foot=p-t*n,
     inside=nn>0 && cross(b-a,foot-a)*n>=0 && cross(c-b,foot-b)*n>=0 && cross(a-c,foot-c)*n>=0)
 inside?abs(t)*sqrt(nn):sqrt(min(_dew_pointseg2(p,a,b),_dew_pointseg2(p,b,c),_dew_pointseg2(p,c,a)));
function _gw_cellerr(p0,p1,v0,v1,P,diag)=
 let(a=_gw_wp(p0,v0,P),b=_gw_wp(p0,v1,P),c=_gw_wp(p1,v0,P),d=_gw_wp(p1,v1,P))
 max([for(uv=[[.5,0],[0,.5],[1,.5],[.5,1],[.5,.5],[1/3,1/3],[2/3,2/3],[1/3,2/3],[2/3,1/3]])
    let(p=_gw_wp(p0+(p1-p0)*uv[0],v0+(v1-v0)*uv[1],P))
    min(diag==0?_gw_trierr(p,a,b,d):_gw_trierr(p,a,b,c),
        diag==0?_gw_trierr(p,a,d,c):_gw_trierr(p,b,d,c))]);
function _gw_flank_excess(p,P)=
    _gaw_asymmetric(P) ? _gaw_flank_excess(p,P) :
 let(r=norm([p.x,p.y]),U=P[4]-r,e=sqrt(U*U+p.z*p.z),
     a=atan2(p.z,U)-P[5]*atan2(p.y,p.x),period=360/P[1],
     chi=a-period*floor(a/period+.5))
 e>=P[3]+P[0]+P[9]?-1e-12:abs(chi)-_dew_half_tooth(e,P);
function _gw_root_zip(a,b,i=0,j=0) =
    i==len(a)-1 && j==len(b)-1 ? [] :
    let(ta=i<len(a)-1?a[i+1][0]:-1e99,
        tb=j<len(b)-1?b[j+1][0]:-1e99,
        A=a[i][1],B=b[j][1])
    abs(ta-tb)<1e-10 ? concat([[A,B,b[j+1][1]],[A,b[j+1][1],a[i+1][1]]],
                              _gw_root_zip(a,b,i+1,j+1)) :
    ta>tb ? concat([[A,B,a[i+1][1]]],_gw_root_zip(a,b,i+1,j)) :
            concat([[A,B,b[j+1][1]]],_gw_root_zip(a,b,i,j+1));
function _gw_root_land(raw,P,nr,nz) =
    _gaw_asymmetric(P) ? _gaw_root_land(raw,P,nr,nz) :
    let(rows=raw[0],ps=raw[1],na=len(ps)-1,ns=len(raw[2]),
        N=P[10],nc=N*ns,offset=(na+1)*nc,er=P[3]+P[0]+P[9],q=P[5],
        W=_gw_section_width(er,P),shift=q*180/N,
        // Same angular lattice as the flanks; no independently phased root grid.
        stations=[for(p=ps)p-shift],
        states=[for(p=stations)let(
            a=_gw_lead_scales(p+shift,P[12]).x,
            b=_gw_lead_scales(p-shift,P[12]).x)
            [p+shift-sign(q)*asin(a*sin(W)),p-shift+sign(q)*asin(b*sin(W))]],
        base=[for(t=[1:1:nr-1],j=[0:na])let(p=stations[j],ab=states[j],
              u=ab[0]+(ab[1]-ab[0])*t/nr)
              cylindrical_to_xyz(P[4]-er*cos(u),p/q+180/N,er*sin(u))],
        points=len(base)==0?[]:[for(k=[0:N-1])each zrot(k*360/N,p=base)],
        faces=[for(k=[0:N-1])each
            let(tracks=[for(t=[0:nr])
                t==0?[for(j=[0:na])[ps[j]-shift,j*nc+k*ns+ns-1]]:
                t==nr?[for(j=[0:na])[ps[j]+shift,j*nc+((k+1)%N)*ns]]:
                [for(j=[0:na])[stations[j],offset+k*len(base)+(t-1)*(na+1)+j]]])
            [for(t=[0:nr-1])each _gw_root_zip(tracks[t],tracks[t+1])]])
    [points,faces,[for(k=[0:N-1],t=[1:1:nr-1],j=[0:na])4*k+3+t/nr]];
function _gw_end_walls(raw,P,nf,nt,offset) =
    let(ps=raw[1],ns=len(raw[2]),nc=ns*P[10],
        stops=[for(j=[0:len(ps)-2])if(ps[j]==ps[j+1])j],ni=(nf-1)*(nt-1),
        C=P[11],
        points=[for(t=[0:1:len(stops)-1],k=[0:P[10]-1],i=[1:1:nf-1],j=[1:1:nt-1])
            _gaw_asymmetric(P) ? _gaw_end_point(ps[stops[t]],raw[2][i],j/nt,P,k) :
            let(p=ps[stops[t]],T=C[6]+(C[7]-C[6])*raw[2][i],e=sqrt(T*T+P[7]*P[7]),
                phi=p-(2*j/nt-1)*C[3]*_gw_section_width(e,P))
            cylindrical_to_xyz(P[4]-e*cos(phi),p/P[5]+k*360/P[10],e*sin(phi))],
        index=function(t,k,i,j)
            let(st=stops[t],full=raw[3][st]==1?st:st+1,flat=2*st+1-full)
            i==0?flat*nc+k*ns+nf+j:
            j==0?full*nc+k*ns+i:
            j==nt?full*nc+k*ns+ns-1-i:
            i==nf?full*nc+k*ns+nf+j:
            offset+(t*P[10]+k)*ni+(i-1)*(nt-1)+j-1,
        faces=[for(t=[0:1:len(stops)-1],k=[0:P[10]-1],i=[0:nf-1],j=[0:nt-1])each
            let(a=index(t,k,i,j),b=index(t,k,i,j+1),c=index(t,k,i+1,j),d=index(t,k,i+1,j+1),
                f=[[a,b,d],[a,d,c]])
            raw[3][stops[t]]==0?f:[for(tri=f)[tri[2],tri[1],tri[0]]]])
    [points,faces,[for(t=[0:1:len(stops)-1],k=[0:P[10]-1],i=[1:1:nf-1],j=[1:1:nt-1])4*k+1+j/nt]];
///  Error probes share cached profile coordinates instead of solving each
///  rounded cross-section nine times per panel on every sampling trial.
function _gw_cellerr_points(a,b,c,d,samples,diag) =
    max([for(p=samples) min(diag==0?_gw_trierr(p,a,b,d):_gw_trierr(p,a,b,c),
                           diag==0?_gw_trierr(p,a,d,c):_gw_trierr(p,b,d,c))]);
function _gw_make_raw(P,na,nf,nt,nr,nz,tol=1e99) =
    let(local=_gw_raw(P,na,nf,nt),lr=local[0],ps=local[1],ts=local[2],
        ns=len(ts),count=len(lr)-1,
        midprofile=_gw_profile([for(i=[0:ns-2])(ts[i]+ts[i+1])/2],P),
        mids=[for(j=[0:count-1])let(p=(ps[j]+ps[j+1])/2,sc=_gw_lead_scales(p,P[12]))
              _gw_row(p,P,midprofile,sc.y,sc.x)],
        diags=[for(j=[0:count-1])[for(i=[0:ns-2])
            let(a=lr[j][i],b=lr[j][i+1],c=lr[j+1][i],d=lr[j+1][i+1],
                flank=(ts[i+1]<=1 || ts[i]>=2) && local[3][j]==1 && local[3][j+1]==1,
                ea=flank?_gw_flank_excess((a+d)/2,P):0,
                eb=flank?_gw_flank_excess((b+c)/2,P):0)
            (flank && ea*eb<0?ea<0:_dew_pointseg2(mids[j][i],a,d)<=_dew_pointseg2(mids[j][i],b,c))?0:1]],
        checkprofile=_gw_profile([for(i=[0:ns-2],t=[0,.5,1])ts[i]+(ts[i+1]-ts[i])*t],P),
        thirdprofile=_gw_profile([for(i=[0:ns-2],t=[1/3,2/3])ts[i]+(ts[i+1]-ts[i])*t],P),
        probes=[for(i=[0:16])let(j=floor((count-1)*i/16))
            if(local[3][j]==1 && local[3][j+1]==1 && ps[j]!=ps[j+1])j],
        err=max([0,for(j=probes) let(
            p0=ps[j],p1=ps[j+1],
            mid=_gw_row((p0+p1)/2,P,checkprofile,1,1),
            end0=_gw_row(p0,P,midprofile,1,1),end1=_gw_row(p1,P,midprofile,1,1),
            third0=_gw_row((2*p0+p1)/3,P,thirdprofile,1,1),
            third1=_gw_row((p0+2*p1)/3,P,thirdprofile,1,1))
            each [for(i=[0:ns-2])
                _gw_cellerr_points(lr[j][i],lr[j][i+1],lr[j+1][i],lr[j+1][i+1],
                    [mid[3*i],end0[i],end1[i],mid[3*i+2],mid[3*i+1],
                     third0[2*i],third1[2*i+1],third0[2*i+1],third1[2*i]],diags[j][i])]]))
    // Reject a sampling trial before replicating starts or constructing faces.
    err>tol ? [undef,err,local] :
    let(raw=_gw_expand(local,P),rows=raw[0],nc=ns*P[10],
        faces=[for(j=[0:count-1])if(ps[j]!=ps[j+1])
            for(k=[0:P[10]-1],i=[0:ns-2])each
            let(a=j*nc+k*ns+i,b=a+1,c=(j+1)*nc+k*ns+i,d=c+1)
            diags[j][i]==0?[[a,b,d],[a,d,c]]:[[a,b,c],[b,d,c]]],
        root=_gw_root_land(raw,P,nr,nz),
        ends=_gw_end_walls(raw,P,(ns-nt-1)/2,nt,(count+1)*nc+len(root[0])))
    [[[for(row=rows)each row,each root[0],each ends[0]],concat(faces,root[1],ends[1])],err,raw,
     [for(j=[0:count],k=[0:P[10]-1],t=ts)4*k+t,each root[2],each ends[2]]];
function _gw_flattened_rows(vnf,tags,raw,P) =
    !is_undef(P[12]) && P[12][1]>0 ? [vnf,tags] :
    let(ts=raw[2],ns=len(ts),nc=ns*P[10],main=len(raw[0])*nc,
        map=[for(i=[0:len(vnf[0])-1])
            i>=main?i:
            let(j=floor(i/nc),col=i%ns,base=i-col,
                c=raw[3][j]==0?(ts[col]<=1?0:ts[col]>=2?ns-1:col):col,
                same=j>0 && raw[1][j]==raw[1][j-1] && (c==0||c==ns-1))
            base+c-(same?nc:0)],
        keep=[for(i=[0:len(map)-1])map[i]==i?1:0],off=cumsum(keep),
        faces=[for(f=vnf[1])let(g=[for(i=f)off[map[i]]-1])
            if(g[0]!=g[1] && g[1]!=g[2] && g[0]!=g[2])g])
    [[[for(i=[0:len(keep)-1])if(keep[i])vnf[0][i]],faces],
     [for(i=[0:len(keep)-1])if(keep[i])tags[i]]];
function _gw_dedup(a)=[for(i=[0:len(a)-1])if(i==0 || a[i][0]!=a[i-1][0]) a[i]];
function _gw_find(key,a,lo=0,hi)=let(h=is_undef(hi)?len(a):hi,m=floor((lo+h)/2))
 assert(lo<h,"\nInternal globoid end-clipping lookup failed; report the parameter set and mesh_tol")
 a[m][0]==key?m:a[m][0]<key?_gw_find(key,a,m+1,h):_gw_find(key,a,lo,m);
function _gw_edgekey(a,b,z,n) = ((z<0?0:1)*n+min(a,b))*n+max(a,b);
function _gw_crossrec(i,j,z,verts,tags,period)=
 let(a=min(i,j),b=max(i,j),p=verts[a],q=verts[b],t=(z-p.z)/(q.z-p.z),
     wrap=abs(tags[a]-tags[b])>period/2,
     ta=wrap&&tags[a]<period/2?tags[a]+period:tags[a],
     tb=wrap&&tags[b]<period/2?tags[b]+period:tags[b],
     r=[(1-t)*p.x+t*q.x,(1-t)*p.y+t*q.y,z])
 [_gw_edgekey(a,b,z,len(verts)),r,((1-t)*ta+t*tb)%period];
function _gw_crosses(a,b,z)=(a<z&&b>z)||(a>z&&b<z);
function _gw_clipped_face(f,verts,edges,H)=
 [for(i=[0:2])each
    let(a=f[i],b=f[(i+1)%3],z0=verts[a].z,z1=verts[b].z,
        planes=z0<z1?[-H,H]:[H,-H])
    [if(z0>=-H && z0<=H)a,
     for(z=planes)if(_gw_crosses(z0,z1,z))len(verts)+_gw_find(_gw_edgekey(a,b,z,len(verts)),edges)]];
/// Contract only very short consecutive cap edges. Rounded profiles use a
/// slightly larger cleanup threshold, still <= mesh_tol/16, to avoid sliver
/// cap polygons that can stall direct CGAL bore operations.
/// Clipping a row almost on
/// the end plane can otherwise leave three near-collinear vertices which collapse
/// on float32 STL export. Shared side faces use the same contractions.
function _gw_cap_aliases(ids,points,eps,i=0,lastid) =
    i==len(ids)?[]:
    let(id=ids[i],rep=i>0&&norm(points[id]-points[lastid])<eps?lastid:id)
    concat([[id,rep]],_gw_cap_aliases(ids,points,eps,i+1,rep));
function _gw_clean_caps(points,faces,caps,eps) =
    let(raw=[for(cap=caps)each
            let(a=_gw_cap_aliases(cap,points,eps),first=a[0][1],last=a[len(a)-1][1],
                close=norm(points[first]-points[last])<eps)
            [for(p=a)[p[0],close&&p[1]==last?first:p[1]]]],
        changed=[for(p=raw)if(p[0]!=p[1])p])
    len(changed)==0?[points,concat(faces,caps)]:
    let(aliases=_sort_vectors(raw,[0]),
        map=[for(i=[0:len(points)-1])abs(points[i].z)==abs(points[caps[0][0]].z)?
                aliases[_gw_find(i,aliases)][1]:i],
        keep=[for(i=[0:len(points)-1])map[i]==i?1:0],offsets=cumsum(keep),
        result=[for(face=concat(faces,caps))
            let(f=[for(i=face)offsets[map[i]]-1],
                clean=[for(i=[0:len(f)-1])if(f[i]!=f[(i+len(f)-1)%len(f)])f[i]])
            if(len(clean)>=3)clean])
    [[for(i=[0:len(points)-1])if(keep[i])points[i]],result];
/// Follow the clipped-side boundary to cap the curved core at each axial end.
/// The root tracks and meridian station chart do not have a common contour order.
/// Reverse each side edge so the cap has the opposite boundary winding.
function _gw_cap_loop(faces,points,z) =
    let(edges=_sort_vectors([for(f=faces,i=[0:len(f)-1])
            let(a=f[i],b=f[(i+1)%len(f)])
            if(points[a].z==z && points[b].z==z)[b,a]],[0]))
    assert(len(edges)>=3,"\nInternal globoid end cap has fewer than three edges; report the parameter set")
    let(start=edges[0][0],loop=[for(i=start,n=0;n<len(edges);
            i=edges[_gw_find(i,edges)][1],n=n+1)i])
    assert(edges[_gw_find(loop[len(loop)-1],edges)][1]==start,
           "\nInternal globoid end-cap boundary did not close; report the parameter set")
    loop;
function _gw_clip(vnf,H,tags,period,eps,root_caps=false)=
 assert(len(vnf[0])<67108864,"\nWorm mesh exceeds exact clipping-key range")
 let(v=vnf[0],fs=vnf[1],
     ranges=[for(f=fs)[min([for(i=f)v[i].z]),max([for(i=f)v[i].z])]],
     cutfaces=[for(j=[0:len(fs)-1])
       if((ranges[j][0]<-H && ranges[j][1]>-H) || (ranges[j][0]<H && ranges[j][1]>H))fs[j]],
     raw=[for(f=cutfaces,i=[0:2],z=[-H,H])let(a=f[i],b=f[(i+1)%3])
        if(_gw_crosses(v[a].z,v[b].z,z)) _gw_crossrec(a,b,z,v,tags,period)],
     edges=_gw_dedup(_sort_vectors(raw,[0])),
     flags=[for(p=v)p.z>=-H&&p.z<=H?1:0],offsets=cumsum(flags),nv=offsets[len(offsets)-1],
     faces=[for(j=[0:len(fs)-1])
       if(ranges[j][0]<=H && ranges[j][1]>=-H)
       let(f=fs[j],whole=ranges[j][0]>=-H && ranges[j][1]<=H,
           g=whole?f:_gw_clipped_face(f,v,edges,H))if(len(g)>=3)
         [for(i=g)i<len(v)?offsets[i]-1:nv+i-len(v)]],
     points=[for(i=[0:len(v)-1])if(flags[i])v[i],each [for(e=edges)e[1]]],
     tops=root_caps?[_gw_cap_loop(faces,points,-H),_gw_cap_loop(faces,points,H)]:
          [for(z=[-H,H])let(
        recs=concat([for(i=[0:len(edges)-1])if(edges[i][1].z==z)[edges[i][2],nv+i]],
                    [for(i=[0:len(v)-1])if(v[i].z==z)[tags[i],offsets[i]-1]]),
        sorted=_gw_dedup(_sort_vectors(recs,[0]))) [for(r=sorted)r[1]]])
 // A clipped triangular side face can become a convex quad. Split it here:
 // rounding makes its four vertices only approximately coplanar, which can
 // fail a direct CGAL Boolean even when an STL export of the same mesh works.
 // Keep the genuinely planar, potentially concave end caps as polygons.
 _gw_clean_caps([for(i=[0:len(v)-1])if(flags[i])v[i],each [for(e=edges)e[1]]],
                [for(f=faces) each len(f)==4?
                    [[f[0],f[1],f[2]],[f[0],f[2],f[3]]]:[f]],
                root_caps?tops:[tops[0],[for(i=[len(tops[1])-1:-1:0])tops[1][i]]],eps);
/// Clip the two crest polylines at the same axial planes as the mesh.
///  Check the unrounded nominal crest, independent of optional finishing.
///  Rounding may remove the entire flat tip, but cannot erase the tooth.
///  Nominal tip check shared by the two end treatments; finishing is not
///  required to retain a flat land of this width.
function _gw_worm_build(P,tol,n=0) =
    _gaw_asymmetric(P) ? _gaw_worm_build(P,tol,n) :
    let(et=P[3]-P[0],er=P[3]+P[0]+P[9],
        pm=asin(P[8]/et)+_dew_half_tooth(er,P)+1e-5,
        rmax=_dew_worm_radius(et,P[8],P),angle=2*acos(1-tol/rmax)/pow(1.3,n),
        na=ceil(2*pm/abs(P[5])/angle),
        leg=P[11][6]-P[11][7],nf=max(1,ceil(leg/(rmax*angle*PI/180))),
        nt=max(2,ceil(2*_dew_half_tooth(et,P)/(2*acos(1-tol/(2*et))))),
        root_tol=max(tol,min(4*tol,P[9]/4)),root_r=_dew_worm_radius(er,P[8],P),
        root_angle=2*acos(max(-1,1-root_tol/(2*root_r))),
        wmin=is_undef(P[12]) || P[12][1]==0 ? 1 : _leadin_sqrt(0,1).x,
        gap=360/P[10]-2*asin(wmin*sin(_gw_section_width(er,P)))/abs(P[5]),
        nr=max(1,ceil(abs(P[5])*gap/(2*acos(max(-1,1-root_tol/er))))),
        root_span=pm+180/P[1],
        nz=max(2,ceil(2*root_span/abs(P[5])/root_angle),
               ceil(2*root_span/(2*acos(max(-1,1-root_tol/(2*er)))))),
        raw=_gw_make_raw(P,na,nf,nt,nr,nz,tol))
    raw[1]>tol?
        assert(n<8,"\nWorm mesh refinement did not converge; use a larger mesh_tol or report the parameter set")
        _gw_worm_build(P,tol,n+1):
    let(eps=min(tol/16,(P[13][0]>0?1e-4:1e-6)*rmax))
    let(clean=_gw_flattened_rows(raw[0],raw[3],raw[2],P))
    [_gw_clip(clean[0],P[8],clean[1],4*P[10],eps,root_caps=true),[na,nf,nt,nr,raw[1],nz]];
function _dew_worm(P,tol,lead_in=0,rounding=0) =
    assert(_dew_mesh_tolerance(tol,P), "\nInvalid gear parameters")
    let(rd=_gw_round_data(P,rounding,tol),
        B=concat(P,[_gw_constants(P),undef,rd]),lead=_gw_lead_data(B,lead_in,tol),
        Q=concat(P,[_gw_constants(P),lead,rd]))
    _gw_worm_build(Q,tol)[0];
/// Exact wheel surface evaluator. The generating envelope is unchanged.
function _dew_flank(v,root,top,z,P,ba,ns)=
 let(r=root+(top-root)*v,b=_dew_limits(r,z,P,ba,ns),base=90-180/P[1])
 assert(b[1]-b[0]<360/P[1],"\nGenerated spaces remove the wheel tooth")
 [v,cylindrical_to_xyz(r,base-b[0],z),cylindrical_to_xyz(r,base+360/P[1]-b[1],z)];
/// Row/frame: [tagged_points, left_tip, right_tip, top, target, z, root, low_limits, top_limits].
/// Frames do not sample the radial profile. Reuse them for interior surface probes.
function _gww_frame(z,P,ba,goal,ns,rounding=0,width=undef,crowning=0,chamfer=0) =
    let(extra=is_undef(width)?0:2*crowning*pow(2*z/width,2),
        section_ba=ba+extra,
        root=_dew_rim(P[3]-P[0]-P[9],z,P),
        blank=_dew_rim(P[3]+P[0],z,P),
        edge_cut=is_undef(width)?0:max(0,abs(z)-(width/2-chamfer)))
    let(br=_dew_limits(root,z,P,section_ba,ns),
        bt0=_dew_limits(blank,z,P,section_ba,ns))
    assert(_dew_land(root,br,P)>=goal,"\nCannot retain min_tip; reduce wheel thickness or worm length")
    let(top0=_dew_land(blank,bt0,P)>=goal?blank:_dew_top(z,P,section_ba,goal,ns,root,blank),
        top=top0-edge_cut)
    assert(top>root+1e-8*P[0],
           str("\nchamfer removes the tooth at z=",z,
               "; reduce chamfer or wheel thickness"))
    let(bt=edge_cut==0 && top0==blank?bt0:_dew_limits(top,z,P,section_ba,ns),
        base=90-180/P[1],
        workroot=min(root+(top-root)/2,_dew_rim(P[3]-P[0],z,P)),
        dr=min(rounding,max(0,workroot-root)/2),dt=min(rounding,(top-root)/4),
        kr=min(dr/root*180/PI,(br[1]-br[0])/4),
        // At full rounding the two crest shoulders may meet: min_tip was
        // already checked against the original full-height crest.
        tip_half=max(0,(360/P[1]+bt[0]-bt[1])/2),
        kt=min(dt/top*180/PI,tip_half),
        br2=[br[0]+kr,br[1]-kr],bt2=[bt[0]-kt,bt[1]+kt],
        L=cylindrical_to_xyz(top,base-bt2[0],z),
        R=cylindrical_to_xyz(top,base+360/P[1]-bt2[1],z),
        Ln=cylindrical_to_xyz(top,base-bt[0],z),
        Rn=cylindrical_to_xyz(top,base+360/P[1]-bt[1],z))
    assert(norm((Ln+Rn)/2-[0,0,z])>root+1e-7*P[0],
           "\nMinimum tip leaves no usable tooth height")
    [[],L,R,top,goal,z,root,br2,bt2,dr,kr,dt,kt,Ln,Rn,section_ba,br,bt];
/// Regular wheel grid. mesh_tol is a sampling scale, not a strict error bound.
/// Spacing follows sqrt(tolerance*length scale), with no local patch splitting.
/// The middle plane is a row. All rows share the same contour sample count,
/// so side panels need only two triangles and no seam stitching / point sorting.
/// Only the minimum tip width is iterated and checked exactly on the final
/// sampled crest polylines; the geometric tolerance is deliberately approximate.
function _gws_frames(P,width,ba,land,ns,nz,goal,n=0,rounding=0,crowning=0,chamfer=0) =
    let(target=is_undef(goal)?land+max(1e-5*P[0],1e-7*P[4]):goal,
        rows=[for(j=[0:nz])_gww_frame(width*(.5-j/nz),P,ba,target,ns,
                                       rounding,width,crowning,chamfer)],
        // The minimum-width specification applies to the unrounded tooth.
        nominal=[for(f=rows)[[],f[13],f[14],undef,undef,f[5]]],
        bad=_dew_badlands(nominal,land+1e-6*P[0]))
    len(bad)==0?rows:
    assert(n<8,"\nWheel nominal min_tip adjustment did not converge; revise the tooth parameters")
    _gws_frames(P,width,ba,land,ns,nz,target*max([for(b=bad)b[2]]),
                n+1,rounding,crowning,chamfer);
/// Preserve a single boundary at the operating-tip reach. The extended hob
/// creates the lower clearance band; bridging that steep transition with a
/// triangle that also covers a working flank caused avoidable interference.
/// Extremely small clearances do not create a nearly zero-area band.
function _gws_row(frame,P,ba,ns,nf,nt,nr,rounding=0,nround=2) =
    rounding>0 ? _gws_rounded_row(frame,P,ba,ns,nf,nt,nr,nround) :
    let(z=frame[5],root=frame[6],top=frame[3],br=frame[7],bt=frame[8],
        band=P[9]>1e-7*P[0],
        workroot=band?min(root+(top-root)/2, _dew_rim(P[3]-P[0],z,P)):root,
        rads=[if(band)root,for(i=[0:nf]) workroot+(top-workroot)*i/nf],
        fs=[for(i=[0:len(rads)-1])i==0?[0,cylindrical_to_xyz(root,90-180/P[1]-br[0],z),
                                       cylindrical_to_xyz(root,90+180/P[1]-br[1],z)]:
                                 i==len(rads)-1?[1,frame[1],frame[2]]:
                                 _dew_flank((rads[i]-root)/(top-root),root,top,z,P,frame[15],ns)],
        base=90-180/P[1])
    [for(f=fs)f[1],
     for(i=[1:nt-1])cylindrical_to_xyz(top,base-bt[0]+(360/P[1]+bt[0]-bt[1])*i/nt,z),
     for(i=[len(fs)-1:-1:0])fs[i][2],
     for(i=[1:nr-1])cylindrical_to_xyz(root,base+360/P[1]-br[1]+(br[1]-br[0])*i/nr,z)];
/// Root easing is restricted to half the tip-clearance band. Any added material
/// is outside the full nominal worm, irrespective of its flank phase. Crest
/// easing only removes material. Intermediate points preserve the exact
/// envelope outside the two short transition bands.
function _gws_rounded_row(f,P,ba,ns,nf,nt,nr,nround) =
    let(z=f[5],root=f[6],top=f[3],br=f[7],bt=f[8],
        dr=f[9],kr=f[10],dt=f[11],kt=f[12],
        section_ba=f[15],base=90-180/P[1],
        band=P[9]>1e-7*P[0],
        workroot=band?min(root+(top-root)/2,_dew_rim(P[3]-P[0],z,P)):root,
        // Evaluate expensive generating envelopes just at the transition
        // ends, not at every added fillet point. The short arcs are sampled
        // from interpolated limits and the prescribed easing shape.
        blo=dr>0?_dew_limits(root+dr,z,P,section_ba,ns):f[16],
        bhi=dt>0?_dew_limits(top-dt,z,P,section_ba,ns):f[17],
        rads=[root,
              if(band) each [for(j=[1:nround])root+dr*(1-cos(90*j/nround)),workroot],
              for(i=[1:nf])lerp(workroot,top-dt,i/nf),
              for(j=[1:nround])j==nround?top:top-dt+dt*sin(90*j/nround)],
        fs=[for(i=[0:len(rads)-1])let(r=rads[i])
            i==0?[cylindrical_to_xyz(root,base-br[0],z),cylindrical_to_xyz(root,base+360/P[1]-br[1],z)]:
            i==len(rads)-1?[f[1],f[2]]:
            let(b=dr>0 && r<=root+dr ? lerp(f[16],blo,constrain((r-root)/dr,0,1)):
                  dt>0 && r>=top-dt ? lerp(bhi,f[17],constrain((r-top+dt)/dt,0,1)):
                  _dew_limits(r,z,P,section_ba,ns),
                v=(dt>0?kt*_globoid_ease((r-top+dt)/dt):0)
                  -(dr>0?kr*_globoid_ease((root+dr-r)/dr):0))
            [cylindrical_to_xyz(r,base-b[0]+v,z),cylindrical_to_xyz(r,base+360/P[1]-b[1]-v,z)]])
    [for(g=fs)g[0],
     for(i=[1:nt-1])cylindrical_to_xyz(top,base-bt[0]+(360/P[1]+bt[0]-bt[1])*i/nt,z),
     for(i=[len(fs)-1:-1:0])fs[i][1],
     for(i=[1:nr-1])cylindrical_to_xyz(root,base+360/P[1]-br[1]+(br[1]-br[0])*i/nr,z)];
/// Keep one consistent diagonal pattern, mirrored for the opposite hand.
/// This is a fixed pattern, not a per-panel optimization. Whole-tooth point
/// arrays use BOSL2 zrot; the periodic root-gap edge reuses the next tooth.
/// Merge exactly coincident final crest vertices where two roundovers meet.
/// A fully rounded tip may have no flat land; adjacent coincident points in
/// that row then become one vertex, with incident quads becoming triangles.
function _gws_mesh(rows,P,nt,nr,merge=false) =
    let(nz=len(rows)-1,nc=len(rows[0]),N=P[1],nf=(nc-nt-nr+2)/2,
        one=[for(row=rows)each row],per=len(one),nv=per*N,
        vertices=[for(k=[0:N-1])each zrot(k*360/N,p=one),
                  [0,0,rows[0][0].z],[0,0,rows[nz][0].z]],
        index=function(j,k,i)((k+floor(i/nc))%N)*per+j*nc+i%nc,
        cap=_wormgear_cap(nf,nt,nr),
        capfaces=[for(end=[0,1],k=[0:N-1],f=cap)
            let(g=[for(i=f)i<0?nv+end:index(end*nz,k,i)])
            end==0?[g[2],g[1],g[0]]:g],
        faces=[for(j=[0:nz-1],k=[0:N-1],i=[0:nc-1])each
            let(a=index(j,k,i),b=index(j,k,i+1),c=index(j+1,k,i),d=index(j+1,k,i+1))
            (P[5]>0?[[a,b,c],[b,d,c]]:[[a,b,d],[a,d,c]])])
    !merge?[vertices,concat(capfaces,faces)]:
    let(keep=[for(i=[0:len(vertices)-1])
             i<nv && i%nc>0 && norm(vertices[i]-vertices[i-1])<1e-9*P[0]?0:1],
        offs=cumsum(keep),
        converted=[for(f=concat(capfaces,faces))let(g=[for(i=f)offs[i]-1])
                   if(g[0]!=g[1] && g[1]!=g[2] && g[0]!=g[2])g])
    [[for(i=[0:len(vertices)-1])if(keep[i])vertices[i]],converted];
function _gws_build(P,width,ba,land,tol,ns,rounding=0,crowning=0,chamfer=0) =
    let(nz=max(4,2*ceil(width/(2*sqrt(4*tol*(P[2]-P[0]))))),
        nf=max(2,ceil(sqrt(P[0]/(8*tol)))),
        frames=_gws_frames(P,width,ba,land,ns,nz,rounding=rounding,
                            crowning=crowning,chamfer=chamfer),
        nt=max(2,max([for(f=frames)ceil((360/P[1]+f[8][0]-f[8][1])/
                                 (2*acos(max(-1,1-tol/f[3]))))])),
        nr=max(2,max([for(f=frames)ceil((f[7][1]-f[7][0])/
                                 (2*acos(max(-1,1-tol/f[6]))))])),
        rows=[for(f=frames)_gws_row(f,P,ba,ns,nf,nt,nr,rounding,max(2,ceil(sqrt(max([for(g=frames)max(g[9],g[11])])/tol))))])
    [_gws_mesh(rows,P,nt,nr,len([for(f=frames)if(norm(f[1]-f[2])<1e-9*P[0])1])>0),
     [nz,nf,nt,nr]];
function _dew_wheel(P,width,backlash,min_tip,tol,search_steps,rounding=0,crowning=0,chamfer=0)=
    assert(is_finite(rounding) && rounding>=0, str("\nrounding must be nonnegative and finite; got ",rounding))
    assert(is_finite(crowning) && crowning>=0, str("\ncrowning must be nonnegative and finite; got ",crowning))
    assert(is_finite(chamfer) && chamfer>=0 && chamfer<width/2,
           str("\nchamfer must be nonnegative and less than half the wheel thickness (",width/2,"); got ",chamfer))
    assert(_dew_mesh_tolerance(tol,P), "\nInvalid gear parameters")
    assert(is_int(search_steps)&&search_steps>=8,"\nsearch_steps must be an integer >=8")
    assert(is_finite(width) && width>0,
           str("\n", "thickness must be greater than zero and finite; got ",width))
    assert(width<2*(P[2]-P[0]),
           str("\n", "For current parameters, thickness must be less than ",2*(P[2]-P[0]),
               "; got ",width))
    assert(is_finite(backlash)&&backlash>=0,
           str("\n", "backlash must be nonnegative and finite; got ",backlash))
    assert(is_finite(min_tip)&&min_tip>0,
           str("\n", "min_tip must be greater than zero and finite; got ",min_tip))
    _gws_build(P,width,backlash,min_tip,tol,search_steps,rounding,crowning,chamfer)[0];
/// Function: _gear_tooth_profile()
/// Usage: As a Function
///   value = _gear_tooth_profile(mod=|circ_pitch=|diam_pitch=, teeth, pressure_angle, clearance, backlash, internal, [center], [helical=], [profile_shift=], [shorten=]);
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
///   mod = Normal module.
///   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  The diametral pitch is a completely different thing than the pitch diameter.
///   circ_pitch = The circular pitch, the distance between teeth centers around the pitch circle.
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
    assert(is_undef(_named), "\nToo many positional arguments (only 6 are accepted)")
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
// Synopsis: Calculate teeth counts and angles for planetary gear assembly with specified transmission ratio.
// Usage: As a Function
//    value = planetary_gears(mod=|circ_pitch=|diam_pitch=, n, max_teeth, [uniform=], [ring_carrier=], [carrier_ring=], [sun_carrier=], [carrier_sun=], [ring_sun=], [sun_ring=], [helical=], [gear_spin=]);
// Description:
//   Calculates a planetary gear assembly approximating a specified transmission ratio.  A planetary gear assembly has three
//   elements: the outer ring gear, the central sun gear, and a carrier that holds several planet gears, which fit between the sun and ring.
//   The transmission ratio of a planetary gear assembly depends on which element is fixed and which ones are considered the input and output shafts.
//   The fixed element can be the ring gear, the sun gear, or the carrier, and then you specify the desired ratio between the other two.
//   You must also specify a maximum number of teeth on the ring gear.
//   The search selects the tooth counts on all of the gears so that no gear has more than `max_teeth`. The search chooses the closest request ratio, favoring the largest
//   ring when options are tied.  
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
//   The computation of planetary gear assemblies determines the tooth counts on the sun, ring and planet gears,
//   and the angular positions of the planet gears.
//   The tooth size or helical angle are needed only for determining proper profile shifting and for determining the
//   gear positions for the profile-shifted gears. To control the size of the assembly, do a planetary calculation
//   with a module of 1 and then scale the module to produce the required gear dimensions.  Remember, you should never
//   use `scale()` on gears; change their size by scaling the module or one of the other tooth size parameters.  
//   .
//   The planet gears
//   appear uniformly spaced around the sun gear, but this uniformity is often only approximate.  Exact uniformity occurs when teeth_sun+teeth_ring
//   is a multiple of the number of planet gears.  You can require this by specifying `uniform=true`.  When `uniform=false` (the default),
//   the gear positions are as uniform as possible but need not be exactly uniform. 
//   If no candidate fits, increase `max_teeth`, reduce the number of planets, or relax `uniform`.
// Arguments:
//   n = Number of planetary gears
//   max_teeth = maximum number of teeth allowed on the ring gear, an integer at least 12.
//   ---
//   mod = The module of the gear.
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  The diametral pitch is a completely different thing than the pitch diameter.
//   circ_pitch = Normal circular pitch.
//   ring_carrier = set ring/carrier transmission ratio to this value in a ring driven system, must be between 1 and 2
//   carrier_ring = set carrier/ring transmission ratio to this value in a carrier driven system, must be between 1/2 and 1
//   sun_carrier = set sun/carrier transmission ratio to this value in a sun driven system, must be larger than 2
//   carrier_sun = set carrier/sun transmission ratio to this value in a carrier driven system, must be smaller than 1/2
//   ring_sun = set ring/sun transmission ratio to this value in a ring driven system, must have absolute value smaller than 1
//   sun_ring = set sun/ring transmission ratio to this value in a sun driven system, must have absolute value larger than 1
//   uniform = Require exactly evenly spaced planets. Default: false
//   helical = Create gears with the specified helical angle. Default: 0
//   gear_spin = rotate the driven gear by this number of degrees.  Default:0
// Example(2D,NoAxes,Anim,Frames=72,FrameMS=50,VPT=[-0.875705,-0.110537,-66.3877],VPR=[0,0,0],VPD=102,Med): In this example we request a ring/carrier ratio of 1.341 and the system produced has a ratio of 4/3.  The sun is fixed, the input is carried by the ring, and the carrier, shown as the blue triangle, is the output, rotating approximately in accordance with the requested ratio.  
//   mod=1;
//   gear_data = planetary_gears(mod=mod, n=3, max_teeth=28, ring_carrier=1.341, gear_spin=4/3*360/3*$t);
//   ring_gear2d(mod=mod, teeth=gear_data[1][1], profile_shift=gear_data[1][2], gear_spin=gear_data[1][3],backing=2);
//   stroke(gear_data[2][4],closed=true,color="blue",width=2);
//     spur_gear2d(mod=mod, teeth=gear_data[0][1], profile_shift=gear_data[0][2], gear_spin=gear_data[0][3]);  //sun
//   color("red")move_copies(gear_data[2][4])
//     spur_gear2d(mod=mod, teeth=gear_data[2][1], profile_shift=gear_data[2][2], gear_spin=gear_data[2][3][$idx]);
// Example(2D,Med,NoAxes,Anim,FrameMS=55,Frames=72,VPT=[-0.125033,0.508151,-66.3877],VPR=[0,0,0],VPD=192.044): In this example we request a sun/carrier ratio of 3.6 and get exactly that ratio.  The carrier shown as the blue pentagon moves very slowly as the central sun turns.  The ring is fixed.  
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
    carrier_sun, ring_sun, sun_ring, helical, gear_spin, uniform=false
) =
    assert(is_undef(_named), "\nToo many positional arguments (only 2 are accepted)")
    assert(is_int(n) && n>0, "\nn must be a positive integer")
    assert(is_int(max_teeth) && max_teeth>=12, "\nmax_teeth must be an integer at least 12")
    assert(is_bool(uniform), "\nuniform must be boolean")
    assert(num_defined([ring_carrier,carrier_ring,sun_carrier,carrier_sun,sun_ring,ring_sun])==1,
           "\nSpecify exactly one of ring_carrier, carrier_ring, sun_carrier, carrier_sun, sun_ring, and ring_sun")
    let(helical=default(helical,0),gear_spin=default(gear_spin,0))
    assert(is_finite(helical) && abs(helical)<90, str("\nhelical must be finite and strictly between -90 and 90 degrees; got ",helical))
    assert(is_finite(gear_spin), "\ngear_spin must be finite")
    let(m=module_value(mod=mod,circ_pitch=circ_pitch,diam_pitch=diam_pitch),
        values=[ring_carrier,carrier_ring,sun_carrier,carrier_sun,sun_ring,ring_sun],
        mode=[for(i=[0:5]) if(!is_undef(values[i])) i][0],
        given=values[mode])
    assert(is_finite(given), "\nThe requested transmission ratio must be finite")
    let(target=mode>=4?abs(given):given)
    assert(mode==0 ? target>1 && target<2 : mode==1 ? target>0.5 && target<1 :
           mode==2 ? target>2 : mode==3 ? target>0 && target<0.5 :
           mode==4 ? target>1 : target>0 && target<1,
           str("\nInvalid transmission ratio: ",given,". ",
               mode==0?"ring_carrier must be between 1 and 2":
               mode==1?"carrier_ring must be between 0.5 and 1":
               mode==2?"sun_carrier must be greater than 2":
               mode==3?"carrier_sun must be between 0 and 0.5":
               mode==4?"abs(sun_ring) must be greater than 1":"abs(ring_sun) must be between 0 and 1"))
    let(
        // Sort inexpensive count records before solving shifted center distances.
        // For equal ratio error, retain the largest allowed ring, as a useful
        // tooth-resolution preference within the user's count budget.
        candidates=_sort_vectors([
            for(nr=[12:1:max_teeth],np=[4:1:floor((nr-4)/2)])
                let(ns=nr-2*np,total=ns+nr)
                if((n==1 || total>=n) && (!uniform || total%n==0))
                    [abs(_planetary_ratio(mode,ns,nr)-target),-nr,-ns,ns,np,nr]
        ],[0,1,2]),
        design=_planetary_pick(candidates,n,helical))
    assert(!is_undef(design),
           str("\nNo ",uniform?"uniformly spaced ":"",n,"-planet design with separated planet-tip envelopes was found with max_teeth=",max_teeth,
               ". Increase max_teeth or reduce n",uniform?", or permit nonuniform spacing":"","."))
    let(ns=design[0],np=design[1],nr=design[2],xs=design[3],xp=design[4],xr=design[5],a=m*design[6],
        // Solve the prescribed member motions. All angles are unwrapped.
        sun_spin=mode==2 || mode==4 ? gear_spin : mode==3 ? (ns+nr)*gear_spin/ns :
                 mode==5 ? -nr/ns*gear_spin : 0,
        ring_spin=mode==0 || mode==5 ? gear_spin : mode==1 ? (ns+nr)*gear_spin/nr :
                  mode==4 ? -ns/nr*gear_spin : 0,
        carrier_spin=mode==0 ? nr/(ns+nr)*gear_spin : mode==1 || mode==3 ? gear_spin :
                     mode==2 ? ns/(ns+nr)*gear_spin : 0,
        step=360/(ns+nr),
        angles=[for(i=[0:n-1]) round(i*(ns+nr)/n)*step+carrier_spin],
        positions=[for(ang=angles) a*[cos(ang),sin(ang)]],
        spins=[for(ang=angles) (ns/np)*(ang-90)+90+ang+180/np-sun_spin*ns/np])
    [["sun",ns,xs,sun_spin],
     ["ring",nr,xr,180/nr*(1-ns%2)+ring_spin],
     ["planets",np,xp,spins,positions,angles],
     ["ratio",_planetary_ratio(mode,ns,nr)]];

/// Ratio magnitudes in the six public input/output conventions.
function _planetary_ratio(mode,ns,nr) =
    mode==0 ? 1+ns/nr : mode==1 ? nr/(nr+ns) :
    mode==2 ? 1+nr/ns : mode==3 ? ns/(ns+nr) : mode==4 ? nr/ns : ns/nr;
/// Choose the best feasible count record. There is no mesh generation in this
/// search: full planet-tip envelopes separate neighboring unmeshed planets.
function _planetary_pick(candidates,n,helical,i=0) =
    i>=len(candidates) ? undef :
    let(c=candidates[i],ns=c[3],np=c[4],nr=c[5],
        xs=auto_profile_shift(teeth=ns,helical=helical),
        xp=auto_profile_shift(teeth=np,helical=helical),xr=xs+2*xp,
        a=gear_dist(mod=1,teeth1=ns,teeth2=np,helical=helical,
                    profile_shift1=xs,profile_shift2=xp),
        tip=outer_radius(mod=1,teeth=np,helical=helical,profile_shift=xp),
        // Rounding equal target angles onto the assembly lattice gives gaps
        // of floor(total/n) or ceil(total/n) cells, including the closing gap.
        gap=n==1?undef:2*a*sin(180*floor((ns+nr)/n)/(ns+nr))-2*tip,
        good=n==1 || gap>1e-9*max(1,a))
    good ? [ns,np,nr,xs,xp,xr,a] : _planetary_pick(candidates,n,helical,i+1);




// Function: stepped_planetary()
// Synopsis: Calculate the tooth counts and angles for a stepped planet gear assembly with a specified transmission ratio.
// Topics: Gears
// See Also: planetary_gears(), spur_gear(), ring_gear(), attach_gear()
// Usage: Specify tooth size in layer 1 and calculate size for layer 2
//   data = stepped_planetary(n, max_teeth, mod1=|circ_pitch1=|diam_pitch1=, [auto_size_range=], [uniform=], [min_teeth=], [exact=], [max_diam=], [backing=], [ring_carrier=], [carrier_ring=], [sun_carrier=], [carrier_sun=], [sun_ring=], [ring_sun=], [helical=], [helical1=], [helical2=], [gear_spin=]);
// Usage: Specify tooth size in layer 2 and calculate size for layer 1
//   data = stepped_planetary(n, max_teeth, mod2=|circ_pitch2=|diam_pitch2=, [auto_size_range=], [uniform=], [min_teeth=], [exact=], [max_diam=], [backing=], [ring_carrier=], [carrier_ring=], [sun_carrier=], [carrier_sun=], [sun_ring=], [ring_sun=], [helical=], [helical1=], [helical2=], [gear_spin=]);
// Usage: Fixed uniform tooth size
//   data = stepped_planetary(n, max_teeth, mod=|circ_pitch=|diam_pitch=, [uniform=], [min_teeth=], [exact=], [max_diam=], [backing=], [ring_carrier=], [carrier_ring=], [sun_carrier=], [carrier_sun=], [sun_ring=], [ring_sun=], [helical=], [helical1=], [helical2=], [gear_spin=]);
// Usage: Fixed arbitrary pair of tooth sizes
//   data = stepped_planetary(n, max_teeth, mod1=|circ_pitch1=|diam_pitch1=, mod2=|circ_pitch2=|diam_pitch2=, [uniform=], [min_teeth=], [exact=], [max_diam=], [backing=], [ring_carrier=], [carrier_ring=], [sun_carrier=], [carrier_sun=], [sun_ring=], [ring_sun=], [helical=], [helical1=], [helical2=], [gear_spin=]);
// Description:
//   Calculates a stepped planetary gear assembly that exactly or approximately matches a desired transmission ratio.
//   A stepped planetary gear assembly is like a simple planetary gear assembly but the planets are two stacked gears that rotate together.  The sun gear is in layer 1
//   and meshes with a planet gear in layer 1; the ring gear is in layer 2 and meshes with a planet gear in layer 2.  
//   Like a simple planetary gear assembly, the transmission ratio depends on which element is fixed and which ones are considered the input and output shafts.
//   The fixed element can be the ring gear, the sun gear, or the carrier (which holds the planet gears), and then you specify the desired ratio between the other two.
//   .
//   The two layers may have different tooth size and helical angle.  You must specify the helical angles for both
//   layers or use the default of zero.  If you specify the tooth size using `mod=`, `circ_pitch=` or `diam_pitch=` then that sets one fixed size for
//   both layers.  You can give separate sizes for the two layers, e.g. `mod1=2`, `mod2=3`.  If you specify the size of only one layer
//   then the omitted one is calculated during the gear optimization.  The `auto_size_range=` parameter provides a scale factor range controlling how far the
//   calculated tooth size can be from the one you provided.  This prevents the optimization from selecting very tiny teeth, for example, because it gives a more
//   accurate ratio.  
//   .
//   You specify the desired ratio using one of six parameters that identify which ratio you want to specify, and which is the driven element.
//   Each different ratio is limited to certain bounds.  For the case of the fixed carrier system, the sun and ring rotate in opposite directions.
//   This is sometimes indicated by a negative transmission ratio.  For these cases you can give a positive or negative value.  
//   By default you will get the closest possible match under the applied constraints.  If you set `exact=true` then your input is converted to a rational
//   value using {{rational_approx()}}, and an exact match is calculated, or you get an error if no exact match is found.
//   When `exact=false` you can provide a ratio interval, which specifies an allowed range of ratios, with endpoints in either order.
//   For `sun_ring` and `ring_sun`, both endpoints may be positive magnitudes or both negative signed ratios.  Intervals with mixed sign are not permitted.
//   The returned ratio is always positive.  
//   .
//   The return uses the same format as {{planetary_gears()}}, with a list of entries describing the elements of the assembly.  The entries are:
//   - ["sun", teeth, profile_shift, spin]
//   - ["ring", teeth, profile_shift, spin]
//   - ["planets", [teeth1, teeth2], [profile_shift1, profile_shift2], spins, positions, angles]
//   - ["ratio", realized_ratio]
//   - ["mod", [mod1, mod2]]
//   .
//   The planets in each layer have their oun tooth count and profile shift, but the spins, positions and angles for the planets apply to both layers.
//   The ratio constraints are always primary, either finding the exact match, the closest match, or any match in the specified interval.  
//   Various parameters constrain the solution.  All four tooth counts are bounded by `max_teeth=`, which is a required bound.  All of the gears except
//   the ring are constrained by the lower limit, `min_teeth=`, which defaults to 8.  The ring gear always has at least 12 teeth.
//   Among equally accurate scalar-ratio designs, or all designs within a requested interval, the smallest enclosing diameter is selected.
//   If diameters are equal, prefer the fewest ring teeth, then sun teeth, then first-planet teeth, then second-planet teeth.
//   The enclosing diameter is the maximum of the complete ring diameter, including backing, and the circles enclosing the planets in either layer.
//   The ring backing uses the same radial thickness and default as {{ring_gear()}}. Use the same `backing` when constructing the ring,
//   or omit it in both calls. The default is calculated for each candidate's ring. Housing, carrier, and other supporting parts are not included.
//   .
//   The planet gears are positioned as evenly as possible around the sun gear, but exact uniformity is not always possible because all of the teeth
//   must mesh correctly in both layers. You can require exact uniformity by specifying `uniform=true`. When `uniform=false` (the default), the gear positions are
//   as uniform as possible but need not be exactly uniform. If no candidate fits, increase max_teeth, reduce the number of planets, or relax uniform.   
//   .
//   When constructing the gear assembly, use `helical1` on the sun and `-helical1` on planet gear 1.  Use `helical2` on the ring and `-helical2` on planet gear 2.
//   You can also use `herringbone=true` when constructing helical gears.  If you manually assemble the gear assembly you must apply the specified spins to each
//   gear.  When `gear_spin=0` the first planet will always appear at angle 0.  It may be easier to assemble your gears using {{attach_gear()}}, either starting
//   at the ring and working inward or starting at the sun and working outward.
//   .
//   You can place the gears manually using the data from the returned data structure.  You can also place them using {{attach_gear()}}, possibly
//   with other supporting gear motion modules.  See the examples below.  
// Arguments:
//   n = Number of identical compound planets, a positive integer.
//   max_teeth = Maximum tooth count on any gear, an integer from 12 through 4096.  
//   ---
//   mod/circ_pitch/diam_pitch = Shared normal module, normal circular pitch, or diametral pitch fixing both layers equally.  Supply only one, without numbered tooth-size arguments.
//   mod1/circ_pitch1/diam_pitch1 = Normal module, normal circular pitch, or diametral pitch for the sun and first planet gear.  Supply only one.  Calculated when only layer 2's tooth size is given.
//   mod2/circ_pitch2/diam_pitch2 = Normal module, normal circular pitch, or diametral pitch for the ring and second planet gear.  Supply only one.  Calculated when only layer 1's tooth size is given.
//   auto_size_range = [minimum,maximum] factors for the calcluted tooth size relative to the specified tooth size.  Applies only when one layer is calculated. Default: [0.5,2]
//   ring_carrier = Ring/carrier ratio with fixed sun; scalar or range, all values greater than 1.
//   carrier_ring = Carrier/ring ratio with fixed sun; scalar or range, all values strictly between 0 and 1.
//   sun_carrier = Sun/carrier ratio with fixed ring; scalar ro range, all values greater than 1.
//   carrier_sun = Carrier/sun ratio with fixed ring; scalar or range, all values strictly between 0 and 1.
//   sun_ring = Sun/ring ratio with fixed carrier; scalar or range (with either sign)
//   ring_sun = Ring/sun ratio with fixed carrier; scalar or range (with either sign)
//   min_teeth = Minimum tooth count on the sun and both planet gears, an integer at least 4 and no greater than max_teeth. Default: 8
//   exact = If true gear must exactly match given ratio.  Otherwise returns best match  
//   max_diam = Maximum diameter of result.  Default: no limit
//   backing = Ring backing thickness.  Use the same value in {{ring_gear()}}. Default: height of the ring teeth (same default as {{ring_gear()}}
//   uniform = Require equally spaced planets. Default: false
//   helical = Helical angle.   Default: 0
//   helical1 = Helical angle for layer 1
//   helical2 = Helical angle for layer 2
//   gear_spin = Drive the assembly from specificied input by this many degrees.  Default: 0
// Example(3D,Med,NoAxes,VPR=[55.00,0.00,25.00],VPD=78,VPT=[-0.62,1.28,2.03],Anim,Frames=72,FrameMS=30): Here we request an exact sun/carrier ratio of 6.  Planets rotate using {{zrot()}} which means children will rotate with them.  
//   $fn=48;  $gear_steps=12;  $backlash=0.1;
//   h=4;
//   data=stepped_planetary(3,60,mod1=1,min_teeth=12,
//            sun_carrier=6,exact=true,uniform=true,gear_spin=720*$t);
//   sun=data[0]; ring=data[1]; planets=data[2]; mod=data[4][1];
//   up(1.5*h) color_this("royalblue")
//       linear_extrude(height=h/2) stroke(planets[4],width=1,closed=true);
//   spur_gear(mod=mod[0],teeth=sun[1],profile_shift=sun[2],thickness=h,gear_spin=sun[3]);
//   up(h) color_this("lightblue")
//   ring_gear(mod=mod[1],teeth=ring[1],profile_shift=ring[2],thickness=h,gear_spin=ring[3]);
//   for(i=[0:2]) move(planets[4][i]) zrot(planets[3][i])
//       color_this("coral")
//       spur_gear(mod=mod[0],teeth=planets[1][0],profile_shift=planets[2][0],thickness=h)
//           align(TOP) color_this("mediumseagreen")
//           spur_gear(mod=mod[1],teeth=planets[1][1],profile_shift=planets[2][1]);
// Example(3D,Med,NoAxes,VPR=[41.70,0.00,32.00],VPD=126.00,VPT=[-0.08,3.86,3.87],Anim,Frames=60,FrameMS=30): Set the ring/carrier ratio to 1.4.  Even though exact=false we get this exact ratio.  Helical on the planets must be the opposite sign of the mating sun or ring.  This version doesn't use {{zrot()}} for the planets but `gearspin=`, which means children of the planets will not rotate with them.  
//   $fn=48; $gear_steps=12; $backlash=0.1;
//   h=8; helical=20;
//   data=stepped_planetary(4,60,mod1=1,min_teeth=12,
//        ring_carrier=1.4,exact=false,uniform=true, helical=helical,gear_spin=1.4*90*$t);
//   sun=data[0]; ring=data[1]; planets=data[2]; mod=data[4][1];
//   up(1.5*h) color_this("royalblue")
//       linear_extrude(height=h/2) stroke(planets[4],width=1,closed=true);
//   spur_gear(mod=mod[0],teeth=sun[1],profile_shift=sun[2],thickness=h,gear_spin=sun[3],helical=helical);
//   up(h) color_this("lightblue")
//   ring_gear(mod=mod[1],teeth=ring[1],profile_shift=ring[2],thickness=h,gear_spin=ring[3],helical=helical);
//   move_copies(planets[4]) 
//       color_this("coral")
//       spur_gear(mod=mod[0],teeth=planets[1][0],profile_shift=planets[2][0],thickness=h,helical=-helical,gear_spin=planets[3][$idx])
//           align(TOP) color_this("mediumseagreen")
//           spur_gear(mod=mod[1],teeth=planets[1][1],profile_shift=planets[2][1],helical=-helical,gear_spin=planets[3][$idx]);
// Example(3D,Med,NoAxes,VPR=[55.00,0.00,46.70],VPD=91.85,VPT=[-1.89,0.80,2.40],Anim,Frames=60,FrameMS=30): Set the sun/ring ratio to an interval and create a herringbone gear set with a fixed carrier.  The sun and ring turn in opposite directions.  
//   $fn=48;   $gear_steps=12;   $backlash=0.1;
//   h=7; helical=25;
//   data=stepped_planetary(3,60,mod1=1,min_teeth=12,
//           sun_ring=[1.8,2]*PI,uniform=false, helical=helical,gear_spin=210*$t);
//   sun=data[0]; ring=data[1]; planets=data[2]; mod=data[4][1];
//   up(1.5*h) color_this("royalblue")
//       linear_extrude(height=h/2) stroke(planets[4],width=1,closed=true);
//   spur_gear(mod=mod[0],teeth=sun[1],profile_shift=sun[2],thickness=h,gear_spin=sun[3],helical=helical,herringbone=true);
//   up(h) color_this("lightblue")
//   ring_gear(mod=mod[1],teeth=ring[1],profile_shift=ring[2],thickness=h,gear_spin=ring[3],helical=helical,herringbone=true);
//   move_copies(planets[4]) zrot(planets[3][$idx])    
//       color_this("coral")
//       spur_gear(mod=mod[0],teeth=planets[1][0],profile_shift=planets[2][0],thickness=h,helical=-helical,herringbone=true)
//           align(TOP) color_this("mediumseagreen")
//           spur_gear(mod=mod[1],teeth=planets[1][1],profile_shift=planets[2][1],helical=-helical,herringbone=true);
// Example(3D,Med,NoAxes,Anim,Frames=75,FrameMS=40,VPR=[50.40,0.00,87.50],VPD=192.04,VPT=[0.31,-0.81,5.31]): Request a sun/carrier ratio of 6 with exact=false, and only 40 teeth.  We get a ratio of 5 instead of 6.  Increasing `max_teeth` or decreasing `min_teeth` improves this result and also significantly shrinks the design radius.  The sun drives the carrier and we assemble the model sun first using {{attach_gear()}} so that we can drive the sun from a previous gear.  The carrier stage outputs its motion to the pink gear which turns the purple gear.
//   $fn=48;  $gear_steps=12;  $backlash=0.1;
//   h=8;
//   data=stepped_planetary(5,40,mod1=1,min_teeth=12,
//            sun_carrier=6,uniform=true,exact=false);
//   sun=data[0]; ring=data[1]; planets=data[2]; mod=data[4][1];
//   ratio=data[3][1];
//   gear_spin($t*360)
//   spur_gear(mod=mod[0],teeth=sun[1],profile_shift=sun[2],thickness=h)
//       gear_carrier_frame(ratio){
//          // Create planets
//          attach_gear(planets[5],phase=planets[3])
//            let(planet_ind=$idx)
//            color_this("coral")
//            spur_gear(teeth=planets[1][0],profile_shift=planets[2][0])
//              align(TOP) color_this("mediumseagreen")
//              spur_gear(mod=mod[1],teeth=planets[1][1],profile_shift=planets[2][1])
//                 // create ring
//                 if(planet_ind==0) attach_gear(180)
//                    color_this("lightblue") ring_gear(teeth=ring[1],profile_shift=ring[2]);
//          // Create carrier and output gear
//          up(1.5*h) color_this("royalblue")
//             linear_extrude(h/4) for(p=planets[4]) stroke([[0,0],p],width=2);
//          up(1.5*h) color_this("royalblue") cyl(d=6,h=5,anchor=BOT)
//              align(TOP) color_this("pink")
//            spur_gear(mod=3/4,teeth=10,anchor=BOT,thickness=4)
//            attach_gear(125) color_this("mediumpurple") spur_gear(teeth=19);
//       }
// Example(3D,Med,NoAxes,Anim,VPR=[56.70,0.00,10.50],VPD=126.00,VPT=[1.41,-4.67,3.76],Frames=72,FrameMS=60): Ring driven system with carrier output needs to be built the same way, but ring first.
//    $fn=48;  $gear_steps=12;  $backlash=0.1;
//    h=6;
//    data=stepped_planetary(3,40,mod1=1,min_teeth=6,
//       ring_carrier=8/3,uniform=true,exact=true);
//    sun=data[0]; ring=data[1]; planets=data[2]; mod=data[4][1];
//    ratio=data[3][1];
//    gear_spin($t*120*ratio)
//    ring_gear(mod=mod[1], teeth=ring[1], profile_shift=ring[2], thickness=h)
//      gear_carrier_frame(ratio){
//        // create planets         
//        attach_gear(planets[5],phase=planets[3])
//          let(planet_ind=$idx)
//          color_this("coral")
//          spur_gear(teeth=planets[1][1],profile_shift=planets[2][1])
//            align(TOP) color_this("mediumseagreen")
//            spur_gear(mod=mod[0],teeth=planets[1][0],profile_shift=planets[2][0])
//               // create sun
//               if(planet_ind==0) attach_gear(180)
//                  recolor("lightblue") spur_gear(teeth=sun[1],profile_shift=sun[2]);
//         // Create carrier
//         up(1.5*h) color_this("red")
//         linear_extrude(h/4) stroke(planets[4],width=1,closed=true);
//      }
// Example(3D,Med,NoAxes,Anim,Frames=64,FrameMS=45,VPR=[51.50,0.00,351.40],VPD=120,VPT=[-0.41,1.45,0.29]): Build a carrier driven system with a sun output using gear attachment.  This requires using {{gear_carrier_frame()}}.  
//   $fn=48;  $gear_steps=12;  $backlash=0.1;
//   h=8;
//   data=stepped_planetary(3,27,mod1=1,min_teeth=9,
//       carrier_sun=1/7,uniform=true,exact=true);
//   sun=data[0]; ring=data[1]; planets=data[2]; mod=data[4][1];
//   ratio=data[3][1];
//   gear_spin($t*120)
//     let(carrier_motion=gear_motion()){
//       gear_shaft()
//         color_this("lightblue") ring_gear(mod=mod[1],teeth=ring[1],profile_shift=ring[2],thickness=h)
//           gear_carrier_frame(motion=carrier_motion)
//             attach_gear(planets[5], phase=planets[3])
//             let(planet_idx=$idx)
//             spur_gear(teeth=planets[1][1], profile_shift=planets[2][1]) 
//               align(TOP)
//                   color_this("coral")   spur_gear(mod=mod[0], teeth=planets[1][0], profile_shift=planets[2][0])
//              if (planet_idx==0)
//              attach_gear(180) color_this("pink")
//                spur_gear(teeth=sun[1], profile_shift=sun[2],thickness=2*h+1,anchor=BOT)
//                   gear_exit_carrier()
//                   attach_gear(0) color_this("lightgreen")spur_gear(teeth=7,thickness=h,anchor=TOP);
//     }

function stepped_planetary(
    n, max_teeth, _named, mod, mod1, mod2,
    circ_pitch, circ_pitch1, circ_pitch2, diam_pitch, diam_pitch1, diam_pitch2,
    ring_carrier, carrier_ring, sun_carrier, carrier_sun, ring_sun, sun_ring,
    helical, helical1, helical2, gear_spin, uniform=false, auto_size_range=[0.5,2],
    min_teeth=8, exact=false, max_diam, backing
) =
    assert(is_undef(_named), "\nToo many positional arguments (only 2 are accepted)")
    assert(is_int(n) && n>0, "\nn must be a positive integer")
    assert(is_int(max_teeth) && max_teeth>=12 && max_teeth<=4096,
           "\nmax_teeth must be an integer from 12 through 4096")
    assert(is_int(min_teeth) && min_teeth>=4 && min_teeth<=max_teeth,
           "\nmin_teeth must be an integer from 4 through max_teeth")
    assert(is_bool(uniform), "\nuniform must be boolean")
    assert(is_bool(exact), "\nexact must be boolean")
    assert(is_undef(backing) || (is_finite(backing) && backing>0), "\nbacking must be positive and finite")
    assert(is_undef(max_diam) || (is_finite(max_diam) && max_diam>0),
           "\nmax_diam must be positive and finite")
    let(shared_size=num_defined([mod,circ_pitch,diam_pitch]),
        size1=num_defined([mod1,circ_pitch1,diam_pitch1]),
        size2=num_defined([mod2,circ_pitch2,diam_pitch2]))
    assert(shared_size<=1, "\nSpecify only one of mod, circ_pitch, and diam_pitch")
    assert(size1<=1, "\nSpecify only one of mod1, circ_pitch1, and diam_pitch1")
    assert(size2<=1, "\nSpecify only one of mod2, circ_pitch2, and diam_pitch2")
    assert(shared_size==0 || size1+size2==0,
           "\nDo not combine shared tooth-size arguments with numbered tooth-size arguments")
    assert(shared_size+size1+size2>0,
           "\nSupply a tooth size using mod, circ_pitch, or diam_pitch, or their numbered layer options")
    let(shared=_stepped_planetary_size(mod,circ_pitch,diam_pitch,"Shared tooth size"),
        m1=shared_size>0?shared:_stepped_planetary_size(mod1,circ_pitch1,diam_pitch1,"Layer 1 tooth size"),
        m2=shared_size>0?shared:_stepped_planetary_size(mod2,circ_pitch2,diam_pitch2,"Layer 2 tooth size"))
    assert(is_vector(auto_size_range,2) && min(auto_size_range)>0 && auto_size_range[0]<=auto_size_range[1],
           "\nauto_size_range must be two positive finite factors in nondecreasing order")
    let(h=default(helical,0), h1=default(helical1,h), h2=default(helical2,h), drive=default(gear_spin,0))
    assert(is_finite(h) && abs(h)<90 && is_finite(h1) && abs(h1)<90 && is_finite(h2) && abs(h2)<90,
           "\nHelical angles must be finite and strictly between -90 and 90 degrees")
    assert(is_finite(drive), "\ngear_spin must be finite")
    let(values=[ring_carrier,carrier_ring,sun_carrier,carrier_sun,sun_ring,ring_sun])
    assert(num_defined(values)==1,
           "\nSpecify exactly one of ring_carrier, carrier_ring, sun_carrier, carrier_sun, sun_ring, and ring_sun")
    let(mode=[for(i=[0:5]) if(!is_undef(values[i])) i][0], given=values[mode],
        interval=is_list(given))
    assert(interval ? is_vector(given,2) : is_finite(given),
           "\nThe ratio must be a finite scalar target or two finite interval endpoints")
    assert(!interval || !exact, "\nDo not combine a ratio interval with exact=true")
    assert(!interval || mode<4 || (min(given)>0 || max(given)<0),
           "\nA fixed-carrier ratio interval must have two nonzero endpoints of the same sign")
    let(target=interval?undef:mode>=4?abs(given):given,
        ends=!interval?undef:mode>=4?[abs(given[0]),abs(given[1])]:given,
        interval_bounds=interval?[min(ends),max(ends)]:undef)
    assert(interval ? (mode==0 || mode==2 ? interval_bounds[0]>1 :
                       mode==1 || mode==3 ? interval_bounds[0]>0 && interval_bounds[1]<1 : interval_bounds[0]>0) :
                      (mode==0 || mode==2 ? target>1 : mode==1 || mode==3 ? target>0 && target<1 : target>0),
           str("\nInvalid transmission ratio: ",given,". ",
               mode==0 || mode==2 ? "The target or both interval endpoints must be greater than 1" :
               mode==1 || mode==3 ? "The target or both interval endpoints must lie strictly between 0 and 1" :
               "A fixed-carrier target must be nonzero"))
    // Intervals have no nominal target and never undergo rational reconstruction.
    let(frac=interval?undef:rational_approx(target,2*max_teeth*max_teeth),
        reconstructed=!interval && frac[0]>0 && abs(frac[0]/frac[1]-target)<=1e-12*max(1,target),
        kfrac=reconstructed?_stepped_planetary_fraction_k(mode,frac):undef)
    assert(!exact || reconstructed,
           "\nThe scalar ratio cannot be reconstructed exactly within this tooth-count budget. Increase max_teeth or use exact=false")
    let(fixed=!is_undef(m1) && !is_undef(m2),
        bounds=fixed?[m2/m1,m2/m1]:is_undef(m1)?[1/auto_size_range[1],1/auto_size_range[0]]:auto_size_range)
    assert(is_vector(bounds,2) && min(bounds)>0, "\nThe module ratio or its bounds exceed the supported numeric range")
    let(
        // cfg: n,N,m1,m2,h1,h2,mode,target,uniform,auto_range,min,backing,max_diam,
        //      cos(h1),cos(h2),m2/m1 bounds,external shifts by layer,target fraction,ratio range.
        cfg=[n,max_teeth,m1,m2,h1,h2,mode,target,uniform,auto_size_range,min_teeth,backing,max_diam,
             cos(h1),cos(h2),bounds,
             [for(z=[0:max_teeth]) auto_profile_shift(teeth=z,helical=h1)],
             [for(z=[0:max_teeth]) auto_profile_shift(teeth=z,helical=h2)],exact?frac:undef,interval_bounds],
        try_exact=!interval && !is_undef(kfrac) && (exact || frac[0]/frac[1]==target),
        seed=try_exact?_stepped_planetary_exact(cfg,kfrac[0],kfrac[1]):undef,
        best=interval ? _stepped_planetary_interval(cfg) :
             exact || !is_undef(seed) ? seed : _stepped_planetary_near(cfg))
    assert(!is_undef(best),
           str("\nNo ",exact?"exact-ratio ":"",uniform?"uniformly spaced ":"",n,
               "-planet stepped design satisfies the constraints with max_teeth=",max_teeth,
               " and min_teeth=",min_teeth,interval?str(" within ratio interval=",interval_bounds):"",
                ". Increase max_teeth, reduce n, or lower min_teeth",
                interval?", or widen the ratio interval":"",
               uniform?", or permit nonuniform spacing":"",
               !is_undef(max_diam)?", or increase max_diam":"",
               !fixed?", or widen auto_size_range.":", or permit one module to be calculated."))
    _stepped_planetary_result(best[1],n,mode,drive);

function _stepped_planetary_ceil(x) = ceil(x-1e-10*max(1,abs(x)));
function _stepped_planetary_floor(x) = floor(x+1e-10*max(1,abs(x)));
// Normalize tooth-size aliases once, before entering the module-based search.
// Preserve supplied modules exactly; use the existing converter for pitch units.
function _stepped_planetary_size(mod,circ_pitch,diam_pitch,context) =
    assert(_stepped_planetary_size_ok(mod) && _stepped_planetary_size_ok(circ_pitch) &&
           _stepped_planetary_size_ok(diam_pitch),
           str("\n",context,": values must be positive finite scalars; lists and strings are not accepted"))
    let(m=!is_undef(mod)?mod:
          is_undef(circ_pitch) && is_undef(diam_pitch)?undef:
          module_value(circ_pitch=circ_pitch,diam_pitch=diam_pitch))
    assert(is_undef(m) || (is_finite(m) && m>0),
           str("\n",context,": conversion must produce a positive finite module"))
    m;
function _stepped_planetary_size_ok(v) = is_undef(v) || (is_finite(v) && v>0);
function _stepped_planetary_mod(a,b) = (a%b+b)%b;
function _stepped_planetary_gcd(a,b) = b==0?a:_stepped_planetary_gcd(b,a%b);
function _stepped_planetary_reduce(a,b) = let(g=_stepped_planetary_gcd(a,b)) [a/g,b/g];
function _stepped_planetary_inverse(a,m,t=0,nt=1,r=undef,nr=undef) =
    m==1 ? 0 :
    let(r=is_undef(r)?m:r, nr=is_undef(nr)?a:nr)
    nr==0 ? _stepped_planetary_mod(t,m) :
    let(q=floor(r/nr)) _stepped_planetary_inverse(a,m,nt,t-q*nt,nr,r-q*nr);

// K = ring*planet1/(sun*planet2); transform rational targets without roundoff.
function _stepped_planetary_fraction_k(mode,f) =
    let(a=f[0],b=f[1],v=mode==0?[b,a-b]:mode==1?[a,b-a]:
                           mode==2?[a-b,b]:mode==3?[b-a,a]:mode==4?[a,b]:[b,a])
    _stepped_planetary_reduce(v[0],v[1]);
function _stepped_planetary_ratio_pair(mode,A,B) =
    mode==0?[A+B,A]:mode==1?[A,A+B]:mode==2?[A+B,B]:
    mode==3?[B,A+B]:mode==4?[A,B]:[B,A];
function _stepped_planetary_ratio(mode,s,p,q,r) =
    let(f=_stepped_planetary_ratio_pair(mode,r*p,s*q)) f[0]/f[1];
function _stepped_planetary_target_k(mode,t) =
    mode==0?1/(t-1):mode==1?t/(1-t):mode==2?t-1:mode==3?(1-t)/t:mode==4?t:1/t;
function _stepped_planetary_ratio_k(mode,k) =
    mode==0?1+1/k:mode==1?k/(1+k):mode==2?1+k:mode==3?1/(1+k):mode==4?k:1/k;
function _stepped_planetary_error(cfg,A,B) =
    let(v=_stepped_planetary_ratio_pair(cfg[6],A,B), t=cfg[18])
    is_undef(t)?abs(v[0]/v[1]-cfg[7]):abs(v[0]*t[1]-t[0]*v[1])/(v[1]*t[1]);
function _stepped_planetary_error_tol(cfg) = is_undef(cfg[18])?4e-15*max(1,abs(cfg[7])):0;
function _stepped_planetary_less(a,b,i=0) =
    is_undef(b)?true:i>=len(a)?false:a[i]==b[i]?_stepped_planetary_less(a,b,i+1):a[i]<b[i];
function _stepped_planetary_sort(v) = len(v)<2?v:
    let(p=v[floor(len(v)/2)]) concat(
        _stepped_planetary_sort([for(x=v) if(_stepped_planetary_less(x,p)) x]),
        [for(x=v) if(x==p) x],
        _stepped_planetary_sort([for(x=v) if(_stepped_planetary_less(p,x)) x]));

function _stepped_planetary_modules(cfg,s,p,q,r) =
    let(M=(s+p)*cfg[14]/cfg[13]/(r-q))
    [is_undef(cfg[2])?cfg[3]/M:cfg[2],is_undef(cfg[3])?cfg[2]*M:cfg[3]];

// Working distance grows by no more than mod1*(xs+xp) for nonnegative shifts.
// This upper bound rejects impossible first-layer envelopes before root solving.
function _stepped_planetary_pair_ok(cfg,s,p) =
    let(a0=(s+p)/(2*cfg[13]),xs=cfg[16][s],xp=cfg[16][p],tip=p/(2*cfg[13])+1+xp,
        min_m1=is_undef(cfg[2])?cfg[3]/cfg[15][1]:cfg[2])
    (cfg[0]==1 || (a0+xs+xp)*sin(180/cfg[0])>tip+0.5e-9*a0) &&
    (is_undef(cfg[12]) || 2*min_m1*(a0+tip)<=cfg[12]*(1+1e-10));
function _stepped_planetary_lower_diam(cfg,s,p,q,r) =
    let(m=_stepped_planetary_modules(cfg,s,p,q,r),a0=m[0]*(s+p)/(2*cfg[13]),
        rs=m[0]*(s/(2*cfg[13])+1+cfg[16][s]),
        rp=m[0]*(p/(2*cfg[13])+1+cfg[16][p]),
        rq=m[1]*(q/(2*cfg[14])+1+cfg[17][q]),
        rr=m[1]*(r/(2*cfg[14])+1.25+cfg[17][q])+default(cfg[11],0))
    2*max(rs,rr,a0+rp,a0+rq);

// Cheap count record [diameter lower bound,r,s,p,q].
function _stepped_planetary_count(cfg,s,p,q,r) =
    r<=q || q<cfg[10] || q>=cfg[1] || r<12 || r>cfg[1] ? undef :
    let(M=(s+p)*cfg[14]/cfg[13]/(r-q),b=cfg[15],
        L=(s*q+r*p)/_stepped_planetary_gcd(p,q))
    M<b[0]*(1-1e-10) || M>b[1]*(1+1e-10) || L<cfg[0] || (cfg[8] && L%cfg[0]!=0) ? undef :
    let(lo=_stepped_planetary_lower_diam(cfg,s,p,q,r))
    !is_undef(cfg[12]) && lo>cfg[12]*(1+1e-10) ? undef :
    [lo,r,s,p,q];

// Group exact families by (s,p), before materializing the r/q multiples.
// Package lower bounds prune whole groups instead of scoring every count tuple.
// An omitted backing contributes zero to lower bounds; the final score resolves
// the actual default tooth depth, including any profile clipping.
function _stepped_planetary_sp_groups(cfg,A,B) = [
    for(s=[cfg[10]:cfg[1]],p=[cfg[10]:cfg[1]])
        if(A*s>B*p && _stepped_planetary_pair_ok(cfg,s,p))
        let(g=_stepped_planetary_gcd(A*s,B*p),r0=A*s/g,q0=B*p/g,delta=r0-q0,
            C=(s+p)*cfg[14]/cfg[13],b=cfg[15],
            lo=max(1,ceil(cfg[10]/q0),ceil(12/r0),_stepped_planetary_ceil(C/(b[1]*delta))),
            hi=min(floor((cfg[1]-1)/q0),floor(cfg[1]/r0),_stepped_planetary_floor(C/(b[0]*delta))))
        if(lo<=hi)
        let(m1min=is_undef(cfg[2])?cfg[3]*delta*lo/C:cfg[2],
            m2min=is_undef(cfg[3])?cfg[2]*C/(delta*hi):cfg[3],
            a0=m1min*(s+p)/(2*cfg[13]),
            lower=2*max(m1min*(s/(2*cfg[13])+1+cfg[16][s]),
                        a0+m1min*(p/(2*cfg[13])+1+cfg[16][p]),
                        m1min*C*r0/(delta*2*cfg[14])+1.25*m2min+default(cfg[11],0),
                        a0+m1min*C*q0/(delta*2*cfg[14])+m2min))
        if(is_undef(cfg[12]) || lower<=cfg[12]*(1+1e-10))
            [lower,s,p,q0,r0,lo,hi]
];
function _stepped_planetary_pick_groups(cfg,groups,i=0,best=undef) =
    i>=len(groups) || _stepped_planetary_cannot_improve(groups[i],best)?best:
    let(g=groups[i],cs=[for(t=[g[5]:g[6]])
          let(c=_stepped_planetary_count(cfg,g[1],g[2],g[3]*t,g[4]*t)) if(!is_undef(c)) c],
        updated=_stepped_planetary_pick_counts(cfg,_stepped_planetary_sort(cs),best=best))
    _stepped_planetary_pick_groups(cfg,groups,i+1,updated);
function _stepped_planetary_divisors(z,lo,hi) = [
    for(d=[1:floor(sqrt(z))]) if(z%d==0) each [
        if(d>=lo && d<=hi) d,
        if(d*d!=z && z/d>=lo && z/d<=hi) z/d
    ]
];
// Large-numerator fractions have few products to factor: rp=A*t, sq=B*t.
function _stepped_planetary_product_counts(cfg,A,B) = [
    for(t=[max(1,ceil(12*cfg[10]/A),ceil(cfg[10]*cfg[10]/B)):1:
           min(floor(cfg[1]*cfg[1]/A),floor(cfg[1]*(cfg[1]-1)/B))])
        let(U=A*t,V=B*t,
            ps=_stepped_planetary_divisors(U,max(cfg[10],ceil(U/cfg[1])),min(cfg[1],floor(U/12))),
            ss=_stepped_planetary_divisors(V,max(cfg[10],ceil(V/(cfg[1]-1))),min(cfg[1],floor(V/cfg[10]))))
        for(p=ps,s=ss) if(_stepped_planetary_pair_ok(cfg,s,p))
            let(c=_stepped_planetary_count(cfg,s,p,V/s,U/p)) if(!is_undef(c)) c
];
function _stepped_planetary_exact(cfg,A,B) =
    A<=0 || B<=0 || max(A,B)>cfg[1]*cfg[1] ? undef :
    cfg[1]*cfg[1]/max(A,B)>cfg[1] ?
        _stepped_planetary_pick_groups(cfg,_stepped_planetary_sort(_stepped_planetary_sp_groups(cfg,A,B))) :
        _stepped_planetary_pick_counts(cfg,_stepped_planetary_sort(_stepped_planetary_product_counts(cfg,A,B)));

// Sun-pair record: s,p,xs,xp,a at mod1=1,nominal a,tip1,C,ring shift/tooth.
function _stepped_planetary_sun_data(s,p,n,h1,h2) =
    let(xs=auto_profile_shift(teeth=s,helical=h1),xp=auto_profile_shift(teeth=p,helical=h1),
        a0=(s+p)/(2*cos(h1)),
        a=xs+xp==0?a0:gear_dist(mod=1,teeth1=s,teeth2=p,helical=h1,
                               profile_shift1=xs,profile_shift2=xp,backlash=0),
        tip=outer_radius(mod=1,teeth=p,helical=h1,profile_shift=xp))
    n>1 && a*sin(180/n)-tip<=0.5e-9*a ? undef :
    let(C=(s+p)*cos(h2)/cos(h1),pa2=atan(tan(20)/cos(h2)),
        wa2=xs+xp==0?pa2:acos(min(1,cos(pa2)*a0/a)),
        factor=abs(h1)==abs(h2)?(xs+xp)/(s+p):
               xs+xp==0?0:max(0,(_invol(wa2)-_invol(pa2))/(2*cos(h2)*tan(pa2))))
    factor>0 && wa2>=75 ? undef : [s,p,xs,xp,a,a0,tip,C,factor];
function _stepped_planetary_planet_data(q,h2) =
    let(xq=auto_profile_shift(teeth=q,helical=h2))
    [q,xq,outer_radius(mod=1,teeth=q,helical=h2,profile_shift=xq)];

/// Layout: s,p,q,r,xs,xp,xq,xr,a,m1,m2,L.  Actual tip checks use the rounded lattice.
function _stepped_planetary_feasible(cfg,v,w,r) =
    let(n=cfg[0],s=v[0],p=v[1],q=w[0],M=v[7]/(r-q),
        fixed=!is_undef(cfg[2]) && !is_undef(cfg[3]),actual=fixed?cfg[3]/cfg[2]:M,
        auto_factor=is_undef(cfg[2])?1/M:M,
        L=(s*q+r*p)/_stepped_planetary_gcd(p,q),chord=n==1?0:2*v[4]*sin(180*floor(L/n)/L))
    (fixed ? abs(actual-M)>1e-10*max(actual,M) :
             auto_factor<cfg[9][0]*(1-1e-10) || auto_factor>cfg[9][1]*(1+1e-10)) ||
    L<n || (cfg[8] && L%n!=0) ||
    (n>1 && (chord-2*v[6]<=1e-9*v[4] || chord-2*actual*w[2]<=1e-9*v[4])) ? undef :
    let(m1=is_undef(cfg[2])?cfg[3]/M:cfg[2],m2=is_undef(cfg[3])?cfg[2]*M:cfg[3],
        xr=w[1]+(r-q)*v[8],a=m1*v[4])
    !is_finite(m1) || m1<=0 || !is_finite(m2) || m2<=0 || !is_finite(a) || a<=0 ? undef :
    [s,p,q,r,v[2],v[3],w[1],xr,a,m1,m2,L];
function _stepped_planetary_diameter(d,h1=0,h2=0,backing) =
    let(ar=outer_radius(mod=d[10],teeth=d[3],profile_shift=d[7],helical=h2,internal=true),
        rr=is_undef(backing)?root_radius(mod=d[10],teeth=d[3],profile_shift=d[7],helical=h2,internal=true):undef,
        ring_radius=_ring_gear_outer_radius(ar,rr,backing))
    2*max(outer_radius(mod=d[9],teeth=d[0],profile_shift=d[4],helical=h1),
          ring_radius,
          d[8]+outer_radius(mod=d[9],teeth=d[1],profile_shift=d[5],helical=h1),
          d[8]+outer_radius(mod=d[10],teeth=d[2],profile_shift=d[6],helical=h2));
function _stepped_planetary_score(cfg,d) =
    let(D=_stepped_planetary_diameter(d,cfg[4],cfg[5],cfg[11]))
    !is_undef(cfg[12]) && D>cfg[12]*(1+1e-10)?undef:
    [D,d[3],d[0],d[1],d[2]];
function _stepped_planetary_quality_less(a,b) =
    is_undef(b)?true:
    let(eps=1e-10*max(a[0],b[0]))
    abs(a[0]-b[0])>eps?a[0]<b[0]:_stepped_planetary_less([a[1],a[2],a[3],a[4]],[b[1],b[2],b[3],b[4]]);
function _stepped_planetary_cannot_improve(c,best) =
    !is_undef(best) && c[0]>best[0][0]*(1+1e-10);
function _stepped_planetary_pick_counts(cfg,cs,i=0,best=undef) =
    i>=len(cs) || _stepped_planetary_cannot_improve(cs[i],best)?best:
    let(c=cs[i],d=_stepped_planetary_layout(c[2],c[3],c[4],c[1],cfg[0],cfg[2],cfg[3],
                   cfg[4],cfg[5],cfg[8],cfg[9]),
        score=is_undef(d)?undef:_stepped_planetary_score(cfg,d),
        good=!is_undef(score) && _stepped_planetary_quality_less(score,is_undef(best)?undef:best[0]))
    _stepped_planetary_pick_counts(cfg,cs,i+1,good?[score,d]:best);

// Private known-count helper retained for regression tests and future layout API.
function _stepped_planetary_layout(s,p,q,r,n,mod1,mod2,helical1=0,helical2=0,uniform=false,auto_size_range=[0.5,2]) =
    min(s,p,q)<4 || r<12 || r<=q ? undef :
    let(v=_stepped_planetary_sun_data(s,p,n,helical1,helical2),
        cfg=[n,max(s,p,q,r),mod1,mod2,helical1,helical2,0,2,uniform,auto_size_range])
    is_undef(v)?undef:_stepped_planetary_feasible(cfg,v,_stepped_planetary_planet_data(q,helical2),r);

// Near-ratio windows are in the user's selected ratio, not K.  An oversized
// window switches to finite count enumeration instead of allocating O(N^4) fractions.
function _stepped_planetary_near(cfg,e=undef) =
    let(N=cfg[1],target=cfg[7],mode=cfg[6],kmin=cfg[10]/(N-1),kmax=N*N/(cfg[10]*cfg[10]),
        range=[_stepped_planetary_ratio_k(mode,kmin),_stepped_planetary_ratio_k(mode,kmax)],
        err=is_undef(e)?max(1,target)/(N*N*N*N):e,
        low=max(min(range),target-err),high=min(max(range),target+err))
    low>high ? _stepped_planetary_fallback(cfg) :
    let(ks=[_stepped_planetary_target_k(mode,low),_stepped_planetary_target_k(mode,high)],
        kl=min(ks),kh=max(ks),Q=N*N,bmax=min(Q,floor(Q/kl)),
        workload=(kh-kl)*bmax*(bmax+1)/2)
    workload>1200 || (low==min(range) && high==max(range)) ? _stepped_planetary_fallback(cfg) :
    let(fs=_stepped_planetary_sort([
        for(b=[1:bmax])
            let(lo=max(1,_stepped_planetary_ceil(kl*b)),hi=min(Q,_stepped_planetary_floor(kh*b)))
            if(lo<=hi) for(a=[lo:hi]) if(_stepped_planetary_gcd(a,b)==1)
                let(error=_stepped_planetary_error(cfg,a,b))
                if(error<=err+_stepped_planetary_error_tol(cfg)) [error,a,b]
        ]),
        result=_stepped_planetary_try_fractions(cfg,fs))
    !is_undef(result)?result:_stepped_planetary_near(cfg,err*10);
function _stepped_planetary_try_fractions(cfg,fs,i=0,best=undef,error=undef) =
    i>=len(fs) || (!is_undef(best) && fs[i][0]>error+_stepped_planetary_error_tol(cfg))?best:
    let(f=fs[i],candidate=_stepped_planetary_exact(cfg,f[1],f[2]),
        good=!is_undef(candidate) && (is_undef(best) ||
             _stepped_planetary_quality_less(candidate[0],best[0])))
    _stepped_planetary_try_fractions(cfg,fs,i+1,good?candidate:best,good?f[0]:error);

// Complete fallback. For each sun/first-planet pair, restrict q by module bounds,
// then walk the permitted ring counts outward from the ideal ratio.  It ends only
// after every potentially better (or tied) candidate has been considered.
function _stepped_planetary_fallback(cfg,s=undef,p=undef,best=undef) =
    let(s=is_undef(s)?cfg[10]:s,p=is_undef(p)?cfg[10]:p,N=cfg[1])
    s>N ? (is_undef(best)?undef:best[1]) :
    let(C=(s+p)*cfg[14]/cfg[13],b=cfg[15],
        qlo=max(cfg[10],_stepped_planetary_ceil(12-C/b[0])),qhi=min(N-1,_stepped_planetary_floor(N-C/b[1])),
        possible=qlo<=qhi && _stepped_planetary_pair_ok(cfg,s,p),
        kr=possible?[p/s*(1+C/(b[1]*qhi)),p/s*(1+min(C/b[0],N-qlo)/qlo)]:[0,0],
        rr=possible?[_stepped_planetary_ratio_k(cfg[6],kr[0]),_stepped_planetary_ratio_k(cfg[6],kr[1])]:[0,0],
        emin=possible?max(0,min(rr)-cfg[7],cfg[7]-max(rr)):0,
        v=!possible || (!is_undef(best) && emin>best[0]+_stepped_planetary_error_tol(cfg))?undef:
            _stepped_planetary_sun_data(s,p,cfg[0],cfg[4],cfg[5]),
        updated=is_undef(v)?best:_stepped_planetary_fallback_q(cfg,v,qlo,qhi,best),
        nextp=p==N?cfg[10]:p+1,nexts=p==N?s+1:s)
    _stepped_planetary_fallback(cfg,nexts,nextp,updated);
function _stepped_planetary_ring_bounds(cfg,v,q) =
    let(b=cfg[15],C=v[7],lo0=max(12,q+1,q+_stepped_planetary_ceil(C/b[1])),
        hi=min(cfg[1],q+_stepped_planetary_floor(C/b[0])),g=_stepped_planetary_gcd(v[1],q),
        P=v[1]/g,Q=q/g,lo=max(lo0,ceil((cfg[0]-v[0]*Q)/P)),
        d=cfg[8]?_stepped_planetary_gcd(P,cfg[0]):1)
    lo>hi || (cfg[8] && (v[0]*Q)%d!=0)?undef:
    let(stride=cfg[8]?cfg[0]/d:1,
        residue=stride==1?0:_stepped_planetary_mod(-v[0]*Q/d*_stepped_planetary_inverse(P/d,stride),stride),
        first=lo+_stepped_planetary_mod(residue-lo,stride),last=hi-_stepped_planetary_mod(hi-residue,stride))
    first>last?undef:[first,last,stride];
function _stepped_planetary_fallback_q(cfg,v,q,end,best) =
    q>end?best:
    let(b=_stepped_planetary_ring_bounds(cfg,v,q),
        ideal=is_undef(b)?0:min(b[1],max(b[0],_stepped_planetary_target_k(cfg[6],cfg[7])*v[0]*q/v[1])),
        left=is_undef(b)?0:b[0]+b[2]*floor((ideal-b[0])/b[2]),
        updated=is_undef(b)?best:_stepped_planetary_walk(cfg,v,q,b,left,left+b[2],best))
    _stepped_planetary_fallback_q(cfg,v,q+1,end,updated);
function _stepped_planetary_walk(cfg,v,q,b,left,right,best) =
    left<b[0] && right>b[1]?best:
    let(le=left<b[0]?1/0:_stepped_planetary_error(cfg,left*v[1],v[0]*q),
        re=right>b[1]?1/0:_stepped_planetary_error(cfg,right*v[1],v[0]*q),
        use_left=le<=re,r=use_left?left:right,error=use_left?le:re)
    !is_undef(best) && error>best[0]+_stepped_planetary_error_tol(cfg)?best:
    let(c=_stepped_planetary_count(cfg,v[0],v[1],q,r),
        prune=!is_undef(best) && abs(error-best[0])<=_stepped_planetary_error_tol(cfg) &&
              !is_undef(c) && _stepped_planetary_cannot_improve(c,best[1]),
        d=is_undef(c)||prune?undef:_stepped_planetary_feasible(cfg,v,_stepped_planetary_planet_data(q,cfg[5]),r),
        score=is_undef(d)?undef:_stepped_planetary_score(cfg,d),
        good=!is_undef(score) && (is_undef(best) || error<best[0]-_stepped_planetary_error_tol(cfg) ||
              _stepped_planetary_quality_less(score,best[1][0])),
        updated=good?[error,[score,d]]:best)
    _stepped_planetary_walk(cfg,v,q,b,use_left?left-b[2]:left,use_left?right:right+b[2],updated);


// Interval mode makes ratio membership a constraint, not the primary score.
// Parameterize each count family by s,p,q,d with d=r-q.  Module bounds restrict
// d, and the requested ratio bounds restrict d/q before geometry is evaluated.
function _stepped_planetary_interval(cfg) =
    let(seed_limit=min(cfg[1],max(64,cfg[10]+1)),
        seed_cfg=[for(i=[0:len(cfg)-1]) i==1?seed_limit:cfg[i]],
        seed=seed_limit<cfg[1]?_stepped_planetary_interval_search(seed_cfg):undef,
        cap=is_undef(seed)?undef:seed[0][0],
        bounded=[for(i=[0:len(cfg)-1]) i==12 && !is_undef(cap)?
                    (is_undef(cfg[12])?cap:min(cap,cfg[12])):cfg[i]])
    _stepped_planetary_interval_search(bounded,seed);

// The small-count pass only supplies an incumbent. The full bounded search
// still considers every family that could improve it; there is no early
// heuristic answer. The incumbent diameter is a valid cap for the full search.
function _stepped_planetary_interval_search(cfg,best=undef) =
    let(N=cfg[1],m=cfg[10],domain=[_stepped_planetary_ratio_k(cfg[6],m/(N-1)),
                                _stepped_planetary_ratio_k(cfg[6],N*N/(m*m))],
        low=max(cfg[19][0],min(domain)),high=min(cfg[19][1],max(domain)))
    low>high?undef:
    let(k=[_stepped_planetary_target_k(cfg[6],low),_stepped_planetary_target_k(cfg[6],high)],
        kl=min(k),kh=max(k),Q=N*N,bmax=min(Q,_stepped_planetary_floor(Q/kl)),
        workload=(kh-kl)*bmax*(bmax+1)/2)
    // Narrow intervals have few bounded rational values. Enumerating all of
    // them proves success or failure without visiting every count family.
    workload<=200 ? _stepped_planetary_interval_fractions(cfg,[
        for(b=[1:bmax])
            let(lo=max(1,_stepped_planetary_ceil(kl*b)),hi=min(Q,_stepped_planetary_floor(kh*b)))
            if(lo<=hi) for(a=[lo:hi]) if(_stepped_planetary_gcd(a,b)==1)
                let(r=_stepped_planetary_ratio(cfg[6],b,1,1,a))
                if(r>=cfg[19][0] && r<=cfg[19][1]) [a,b]
    ],best=best) :
    let(groups=_stepped_planetary_interval_groups(cfg,kl,kh,best))
    _stepped_planetary_interval_pick(cfg,_stepped_planetary_sort(groups),best=best);

function _stepped_planetary_interval_fractions(cfg,fs,i=0,best=undef) =
    i>=len(fs)?best:
    let(f=fs[i],candidate=_stepped_planetary_exact(cfg,f[0],f[1]),
        good=!is_undef(candidate) &&
             _stepped_planetary_quality_less(candidate[0],is_undef(best)?undef:best[0]))
    _stepped_planetary_interval_fractions(cfg,fs,i+1,good?candidate:best);

// Group record: diameter lower bound,s,p,dmin,dmax,qmin,qmax,vmin,vmax.
// Here v=d/q.  All bounds are conservative; final membership uses the user's
// original ratio convention, including its inclusive endpoints.
function _stepped_planetary_interval_groups(cfg,kl,kh,best=undef) = [
    let(min_m1=is_undef(cfg[2])?cfg[3]/cfg[15][1]:cfg[2],
        total_limit=is_undef(cfg[12])?3*cfg[1]:cfg[13]*(cfg[12]/min_m1-2),
        smax=min(cfg[1],_stepped_planetary_floor(total_limit-2*cfg[10])))
    if(smax>=cfg[10])
    for(s=[cfg[10]:smax])
        let(pmax=min(cfg[1],_stepped_planetary_floor((total_limit-s)/2)))
        if(pmax>=cfg[10]) for(p=[cfg[10]:pmax])
        let(N=cfg[1],m=cfg[10],C=(s+p)*cfg[14]/cfg[13],b=cfg[15],
            dl=max(1,_stepped_planetary_ceil(C/b[1])),
            dh=min(N-m,_stepped_planetary_floor(C/b[0])))
        if(dl<=dh && _stepped_planetary_pair_ok(cfg,s,p))
        let(vl=max(dl/(N-dl),kl*s/p-1),vh=min(dh/m,kh*s/p-1))
        if(vh>0 && vl<=vh+1e-12*max(1,abs(vh)))
        let(ql=max(m,12-dh,_stepped_planetary_ceil(dl/vh)),
            qh=min(N-dl,_stepped_planetary_floor(dh/vl)))
        if(ql<=qh)
        let(m1lo=is_undef(cfg[2])?cfg[3]*dl/C:cfg[2],
            m2lo=is_undef(cfg[3])?cfg[2]*C/dh:cfg[3],
            a0=m1lo*(s+p)/(2*cfg[13]),
            lower=2*max(m1lo*(s/(2*cfg[13])+1+cfg[16][s]),
                        a0+m1lo*(p/(2*cfg[13])+1+cfg[16][p]),
                        a0*(1+1/vh)+1.25*m2lo+default(cfg[11],0),
                        a0+a0/vh+m2lo))
        if(is_undef(cfg[12]) || lower<=cfg[12]*(1+1e-10))
        let(g=[lower,s,p,dl,dh,ql,qh,vl,vh])
        if(!_stepped_planetary_cannot_improve(g,best)) g
];

function _stepped_planetary_interval_pick(cfg,groups,i=0,best=undef) =
    i>=len(groups) || _stepped_planetary_cannot_improve(groups[i],best)?best:
    let(g=groups[i],v=_stepped_planetary_sun_data(g[1],g[2],cfg[0],cfg[4],cfg[5]),
        cs=is_undef(v)?[]:_stepped_planetary_interval_counts(cfg,g,v,best),
        updated=_stepped_planetary_interval_candidates(cfg,v,_stepped_planetary_sort(cs),best=best))
    _stepped_planetary_interval_pick(cfg,groups,i+1,updated);

function _stepped_planetary_interval_counts(cfg,g,v,best) = [
    let(vl=g[7],vh=g[8],
        qlo=max(g[5],_stepped_planetary_ceil(g[3]/vh)),
        qhi=min(g[6],_stepped_planetary_floor(g[4]/vl)))
    if(vl<=vh && qlo<=qhi)
    for(q=[qlo:qhi])
        let(b=_stepped_planetary_ring_bounds(cfg,v,q))
        if(!is_undef(b))
        let(lo=max(b[0],q+_stepped_planetary_ceil(vl*q)),
            hi=min(b[1],q+_stepped_planetary_floor(vh*q)),
            first=lo+_stepped_planetary_mod(b[0]-lo,b[2]))
        if(first<=hi) for(r=[first:b[2]:hi])
            let(ratio=_stepped_planetary_ratio(cfg[6],g[1],g[2],q,r))
            if(ratio>=cfg[19][0] && ratio<=cfg[19][1])
            let(c=_stepped_planetary_count(cfg,g[1],g[2],q,r))
            if(!is_undef(c) && !_stepped_planetary_cannot_improve(c,best)) c
];

// Interval and scalar searches share the same geometry-only score and count tie-breaks.
function _stepped_planetary_interval_candidates(cfg,v,cs,i=0,best=undef) =
    i>=len(cs) || _stepped_planetary_cannot_improve(cs[i],best)?best:
    let(c=cs[i],d=_stepped_planetary_feasible(cfg,v,_stepped_planetary_planet_data(c[4],cfg[5]),c[1]),
        score=is_undef(d)?undef:_stepped_planetary_score(cfg,d),
        good=!is_undef(score) && _stepped_planetary_quality_less(score,is_undef(best)?undef:best[0]))
    _stepped_planetary_interval_candidates(cfg,v,cs,i+1,good?[score,d]:best);

function _stepped_planetary_result(d,n,mode,drive=0) =
    let(s=d[0],p=d[1],q=d[2],r=d[3],a=d[8],L=d[11],A=s*q,B=r*p,
        sun=mode==2 || mode==4?drive:mode==3?(A+B)/A*drive:mode==5?-B/A*drive:0,
        ring=mode==0 || mode==5?drive:mode==1?(A+B)/B*drive:mode==4?-A/B*drive:0,
        carrier=mode==0?B/(A+B)*drive:mode==1 || mode==3?drive:mode==2?A/(A+B)*drive:0,
        g=_stepped_planetary_gcd(p,q),P=p/g,Q=q/g,
        inverse=_stepped_planetary_inverse(Q,P),phi0=90+90*(2-s)/p,
        ring0=_stepped_planetary_mod(q/r*(phi0+90)-90,360/r),
        // The first planet is always the X+ reference at zero system drive.
        cells=[for(i=[0:n-1]) i==0?0:round(i*L/n)],
        angles=[for(j=cells) 360*j/L+carrier],
        positions=[for(t=angles) a*[cos(t),sin(t)]],
        motion=(s+p)/p*carrier-s/p*sun,
        spins=[for(j=cells)
                   let(k=P==1?0:_stepped_planetary_mod(-j*inverse,P))
                   _stepped_planetary_mod(phi0+360/p*((s+p)*j/L+k),360/g)+motion])
    [["sun",s,d[4],sun],
     ["ring",r,d[7],ring0+ring],
     ["planets",[p,q],[d[5],d[6]],spins,positions,angles],
     ["ratio",_stepped_planetary_ratio(mode,s,p,q,r)],
     ["mod",[d[9],d[10]]]];






// Function: wolfrom_planetary()
// Synopsis: Calculates a two-ring Wolfrom gear assembly
// Topics: Gears
// See Also: stepped_planetary(), spur_gear(), ring_gear(), attach_gear(), gear_carrier_frame()
// Usage: Calculate one layer's tooth size from the other
//   data = wolfrom_planetary(n, max_teeth, sun_ring=|ring_sun=|sun_carrier=|carrier_sun=|carrier_ring=|ring_carrier=, mod1=|circ_pitch1=|diam_pitch1=, [auto_size_range=], [min_teeth=], [uniform=], [exact=], [max_diam=], [backing=], [backing1=], [backing2=], [helical=], [helical1=], [helical2=], [gear_spin=]);
//   data = wolfrom_planetary(n, max_teeth, sun_ring=|ring_sun=|sun_carrier=|carrier_sun=|carrier_ring=|ring_carrier=, mod2=|circ_pitch2=|diam_pitch2=, [auto_size_range=], [min_teeth=], [uniform=], [exact=], [max_diam=], [backing=], [backing1=], [backing2=], [helical=], [helical1=], [helical2=], [gear_spin=]);
// Usage: Fix both tooth sizes
//   data = wolfrom_planetary(n, max_teeth, sun_ring=|ring_sun=|sun_carrier=|carrier_sun=|carrier_ring=|ring_carrier=, mod=|circ_pitch=|diam_pitch=, [min_teeth=], [uniform=], [exact=], [max_diam=], [backing=], [backing1=], [backing2=], [helical=], [helical1=], [helical2=], [gear_spin=]);
//   data = wolfrom_planetary(n, max_teeth, sun_ring=|ring_sun=|sun_carrier=|carrier_sun=|carrier_ring=|ring_carrier=, mod1=|circ_pitch1=|diam_pitch1=, mod2=|circ_pitch2=|diam_pitch2=, [min_teeth=], [uniform=], [exact=], [max_diam=], [backing=], [backing1=], [backing2=], [helical=], [helical1=], [helical2=], [gear_spin=]);
// Description:
//   Calculates tooth counts, tooth sizes, profile shifts, and installation angles for a Wolfrom gear assembly.
//   The sun meshes with identical compound planets. In layer 1, each planet also meshes with a fixed ring.
//   In layer 2, the rigidly connected second planet gear meshes with a second ring, which is the output.
//   .
//   Select the signed input/output ratio with sun_ring, ring_sun, sun_carrier, carrier_sun, carrier_ring, or ring_carrier.
//   All ratios use the first ring as the fixed member. The sign indicates relative rotation direction.
//   A scalar requests the closest ratio of that sign; a pair of same-sign endpoints specifies an inclusive interval.
//   Every ratio inside an interval is equally acceptable. With exact=true, a rational ratio is reconstructed using {{rational_approx()}}
//   and must be matched exactly.
//   .
//   Supply a positive tooth size. A shared size fixes both layers equally; numbered sizes specify each layer.
//   Supplying just one layer calculates the other from the common shaft spacing. Sizes cannot be changed independently afterward.
//   The default profile shifts avoid external undercut, and ring shifts close the three working mesh distances.
//   .
//   Among equally accurate results for a scalar ratio, or all results inside an interval, the smallest enclosing diameter is selected.
//   Both rings' backing and both planet envelopes are included. Supply the same backing values when constructing the rings.
//   Equal-diameter ties prefer fewer fixed-ring teeth, then output-ring teeth, sun teeth, first-planet teeth, and second-planet teeth.
//   .
//   Positions are as evenly spaced as tooth alignment permits. Set uniform=true to require exact equal spacing.
//   When `gear_spin=0` the first planet is on the X+ axis. All of the planets are identical to each other.  
//   .
//   The return is a list of entries describing the assembly:
//   - ["sun", teeth, profile_shift, spin]
//   - ["rings", [fixed_teeth, output_teeth], [fixed_shift, output_shift], [fixed_spin, output_spin]]
//   - ["planets", [teeth1, teeth2], [profile_shift1, profile_shift2], spins, positions, angles]
//   - ["ratio", realized_signed_ratio]
//   - ["mod", [mod1, mod2]]
//   - ["carrier", sun_carrier_ratio, carrier_spin]
//   .
//   Use the returned spins and positions for manual assembly or {{attach_gear()}} and {{gear_carrier_frame()}} for driven assembly. 
// Arguments:
//   n = Number of identical compound planets; a positive integer.
//   max_teeth = Maximum tooth count on every gear, including both rings; integer from 12 through 4096.
//   ---
//   sun_ring / ring_sun / sun_carrier / carrier_sun / carrier_ring / ring_carrier = Signed ratio of the named shafts, with the first ring fixed. Supply one finite nonzero scalar or two same-sign interval endpoints.
//   sun_carrier = Sun rotation / carrier rotation, with the first ring fixed.
//   carrier_sun = Carrier rotation / sun rotation, with the first ring fixed.
//   carrier_ring = Carrier rotation / output-ring rotation, with the first ring fixed.
//   ring_carrier = Output-ring rotation / carrier rotation, with the first ring fixed.
//   ring_sun = Output-ring rotation / sun rotation, with the first ring fixed.
//   sun_ring = Sun rotation / output-ring rotation, with the first ring fixed.
//   mod/circ_pitch/diam_pitch = Shared normal tooth size fixing both layers equally. Supply only one and do not combine with numbered sizes.
//   mod1/circ_pitch1/diam_pitch1 = Normal tooth size for the sun, first planet, and fixed ring. Supply only one. Calculated when only layer 2 is specified.
//   mod2/circ_pitch2/diam_pitch2 = Normal tooth size for the second planet and output ring. Supply only one. Calculated when only layer 1 is specified.
//   auto_size_range = Inclusive factors for calculated/supplied normal tooth size, measured with resolved modules. Applies only to a calculated layer. Default: [0.5,2]
//   min_teeth = Minimum sun and planet tooth count; integer at least 4 and no greater than max_teeth. Both rings have at least 12 teeth. Default: 8
//   uniform = Require exactly equally spaced planets. Default: false
//   exact = Require an exact reconstructed scalar ratio, with no approximate fallback. Default: false
//   max_diam = Inclusive maximum enclosing diameter, including both rings' backing. Default: no diameter limit
//   backing = Shared positive radial ring backing thickness. Numbered values override it. Default: each ring's tooth height
//   backing1 = Positive radial backing thickness for the fixed ring. Default: backing, or the fixed ring's tooth height
//   backing2 = Positive radial backing thickness for the output ring. Default: backing, or the output ring's tooth height
//   helical = Shared default for the layer-specific helix angles. Default: 0
//   helical1 = Sun and fixed-ring helix angle, strictly between -90 and 90 degrees. Default: helical
//   helical2 = Output-ring helix angle, strictly between -90 and 90 degrees. Default: helical
//   gear_spin = Rotation of the selected driving member (sun, output ring, or carrier), in degrees. Default: 0
// Example(3D,Med,NoAxes,Anim,Frames=96,FrameMS=20,VPR=[49.70,0.00,7.70],VPD=213.38,VPT=[0.85,-1.91,7.73]): Construct a reversing Wolfrom gear assembly with a sun/ring ratio of 60.  Watch the purple ring carefully.  
//   $fn=64;  $gear_steps=16;  $backlash=0.1;
//   h=10;
//   data=wolfrom_planetary(3,90,mod1=1.5,min_teeth=18,
//            sun_ring=-60,exact=false,uniform=true,gear_spin=480*$t);
//   sun=data[0]; ring=data[1]; planets=data[2]; mod=data[4][1];
//   up(1.5*h) color_this("royalblue")
//       linear_extrude(1) stroke(planets[4],width=1,closed=true);
//   spur_gear(mod=mod[0],teeth=sun[1],profile_shift=sun[2],thickness=h,gear_spin=sun[3]);
//   for(j=[0:1]) up(j*h)
//       color_this(j==0?"lightblue":"plum")
//       ring_gear(mod=mod[j],teeth=ring[1][j],profile_shift=ring[2][j],thickness=h,gear_spin=ring[3][j]);
//   move_copies(planets[4]) zrot(planets[3][$idx])
//       color_this("coral")
//       spur_gear(mod=mod[0],teeth=planets[1][0],profile_shift=planets[2][0],thickness=h)
//           align(TOP) color_this("mediumseagreen")
//           spur_gear(mod=mod[1],teeth=planets[1][1],profile_shift=planets[2][1]);
// Example(3D,Med,NoAxes,VPR=[49.70,0.00,7.70],VPD=213.38,VPT=[0.85,-1.91,7.73]): The same sun-driven assembly constructed with {{attach_gear()}}.
//   $fn=64;  $gear_steps=8;  $backlash=0.1;
//   h=10;
//   data=wolfrom_planetary(3,90,mod1=1.5,min_teeth=18,sun_ring=-60,exact=true,uniform=true);
//   sun=data[0]; rings=data[1]; planets=data[2]; mod=data[4][1];
//   ratio = data[5][1];
//   gear_spin(480*$t)
//   spur_gear(mod=mod[0],teeth=sun[1],profile_shift=sun[2],thickness=h)
//       gear_carrier_frame(ratio) {
//           up(1.5*h) color_this("royalblue")
//               linear_extrude(1) stroke(planets[4],width=1,closed=true);
//           attach_gear(planets[5],phase=planets[3])
//           let(i=$idx)
//           color_this("coral") spur_gear(teeth=planets[1][0],profile_shift=planets[2][0]) {
//               if(i==0) attach_gear(180) color_this("lightblue")
//                   ring_gear(teeth=rings[1][0],profile_shift=rings[2][0]);
//               align(TOP) color_this("mediumseagreen")
//               spur_gear(mod=mod[1],teeth=planets[1][1],profile_shift=planets[2][1])
//                   if(i==0) attach_gear(180) color_this("plum")
//                       ring_gear(teeth=rings[1][1],profile_shift=rings[2][1]);
//           }
//       }
// Example(3D,Med,NoAxes,Anim,Frames=96,FrameMS=20,VPR=[50.40,0.00,87.50],VPD=217,VPT=[0.03,1.25,5.76]): Non-reversing output selected from an interval, with separate helix angles and ring backing on the layers.  The calculated ratio is 60.  
//   $fn=64; $gear_steps=16;  $backlash=0.1;
//   h=15;
//   data=wolfrom_planetary(3,90,mod1=1.5,min_teeth=18,sun_ring=[59.5,60.5],uniform=true,
//       helical1=20,helical2=-15,backing1=3,backing2=2);
//   ratio = data[5][1];
//   echo(ratio=ratio);
//   sun=data[0]; rings=data[1]; planets=data[2]; mod=data[4][1];
//   gear_spin(1440*$t/3)  // One third carrier turn
//   spur_gear(mod=mod[0],teeth=sun[1],profile_shift=sun[2],thickness=h,helical=20)
//       gear_carrier_frame(ratio) {
//           up(1.5*h+1) recolor("royalblue")
//               linear_extrude(1) stroke(planets[4],width=1,closed=true);
//           attach_gear(planets[5],phase=planets[3])
//           let(i=$idx)
//           recolor("coral") spur_gear(teeth=planets[1][0],profile_shift=planets[2][0]) {
//               if(i==0) attach_gear(180) recolor("lightblue")
//                   ring_gear(teeth=rings[1][0],profile_shift=rings[2][0],backing=3);
//               align(TOP) recolor("mediumseagreen")
//               spur_gear(mod=mod[1],teeth=planets[1][1],profile_shift=planets[2][1],helical=15)
//                   if(i==0) attach_gear(180) recolor("plum")
//                       ring_gear(teeth=rings[1][1],profile_shift=rings[2][1],backing=2);
//           }
//       }
function wolfrom_planetary(
    n, max_teeth, _named, sun_ring, ring_sun, sun_carrier, carrier_sun, carrier_ring, ring_carrier, mod, mod1, mod2,
    circ_pitch, circ_pitch1, circ_pitch2, diam_pitch, diam_pitch1, diam_pitch2,
    auto_size_range=[0.5,2], min_teeth=8, uniform=false, exact=false,
    max_diam, backing, backing1, backing2, helical, helical1, helical2, gear_spin
) =
    assert(is_undef(_named), "\nToo many positional arguments (only 2 are accepted)")
    assert(is_int(n) && n>0, "\nn must be a positive integer")
    assert(is_int(max_teeth) && max_teeth>=12 && max_teeth<=4096,
           "\nmax_teeth must be an integer from 12 through 4096")
    assert(is_int(min_teeth) && min_teeth>=4 && min_teeth<=max_teeth,
           "\nmin_teeth must be an integer from 4 through max_teeth")
    assert(is_bool(uniform) && is_bool(exact), "\nuniform and exact must be boolean")
    assert(is_undef(max_diam) || (is_finite(max_diam) && max_diam>0), "\nmax_diam must be positive and finite")
    assert(len([for(b=[backing,backing1,backing2]) if(!is_undef(b) && !(is_finite(b) && b>0)) 1])==0,
           "\nRing backing thicknesses must be positive and finite")
    assert(num_defined([sun_ring,ring_sun,sun_carrier,carrier_sun,carrier_ring,ring_carrier])==1,
           "\nSpecify exactly one of sun_ring, ring_sun, sun_carrier, carrier_sun, carrier_ring and ring_carrier")
    let(selectors=[sun_ring,ring_sun,sun_carrier,carrier_sun,carrier_ring,ring_carrier],
        mode=[for(j=[0:5]) if(!is_undef(selectors[j])) j][0],
        request=selectors[mode],interval=is_list(request))
    assert(interval?is_vector(request,2) && is_finite(request[0]) && is_finite(request[1]):is_finite(request),
           "\nThe selected transmission ratio must be a finite scalar or a pair of finite interval endpoints")
    assert(interval?(min(request)>0 || max(request)<0):request!=0,
           "\nThe selected ratio must be nonzero; interval endpoints must have the same sign")
    assert(!interval || !exact, "\nA ratio interval cannot be combined with exact=true")
    assert((mode!=2 || min(interval?request:[request])>2) &&
           (mode!=3 || (min(interval?request:[request])>0 && max(interval?request:[request])<0.5)),
           "\nThe sun/carrier ratio must be greater than 2; the carrier/sun ratio must lie between 0 and 0.5")
    let(target=interval?undef:request, ends=interval?[min(request),max(request)]:undef,
        shared=num_defined([mod,circ_pitch,diam_pitch]),
        count1=num_defined([mod1,circ_pitch1,diam_pitch1]), count2=num_defined([mod2,circ_pitch2,diam_pitch2]))
    assert(shared<=1 && count1<=1 && count2<=1, "\nSpecify only one tooth-size convention in each scope")
    assert(shared==0 || count1+count2==0, "\nDo not combine shared tooth-size arguments with numbered tooth-size arguments")
    assert(shared+count1+count2>0, "\nSupply a tooth size for at least one layer")
    let(m=_stepped_planetary_size(mod,circ_pitch,diam_pitch,"Shared tooth size"),
        m1=shared?m:_stepped_planetary_size(mod1,circ_pitch1,diam_pitch1,"Layer 1 tooth size"),
        m2=shared?m:_stepped_planetary_size(mod2,circ_pitch2,diam_pitch2,"Layer 2 tooth size"))
    assert(is_vector(auto_size_range,2) && min(auto_size_range)>0 && auto_size_range[0]<=auto_size_range[1],
           "\nauto_size_range must be two positive finite factors in nondecreasing order")
    let(h=default(helical,0),h1=default(helical1,h),h2=default(helical2,h),u=default(gear_spin,0))
    assert(is_finite(h) && abs(h)<90 && is_finite(h1) && abs(h1)<90 && is_finite(h2) && abs(h2)<90,
           "\nHelical angles must be finite and strictly between -90 and 90 degrees")
    assert(is_finite(u), "\ngear_spin must be finite")
    let(fixed=!is_undef(m1) && !is_undef(m2),
        bounds=fixed?[m2/m1,m2/m1]:is_undef(m1)?[1/auto_size_range[1],1/auto_size_range[0]]:auto_size_range)
    assert(is_vector(bounds,2) && min(bounds)>0, "\nThe tooth-size ratio or its bounds exceed the supported numeric range")
    // The reduced ratio denominator is at most N^3; numerator at most 2*N^3.
    // Keep integer products within exact binary64 range by cross-cancellation below.
    let(f=interval?undef:rational_approx(abs(target),max_teeth^3),
        reconstructed=!interval && f[0]>0 && f[0]<=2*max_teeth^3 &&
                      abs(f[0]/f[1]-abs(target))<=1e-12*max(1,abs(target)),
        frac=reconstructed?[sign(target)*f[0],f[1]]:undef)
    assert(!exact || reconstructed, "\nThe ratio cannot be reconstructed exactly within this tooth-count budget; increase max_teeth or use exact=false")
    let(
        // cfg: n,N,m1,m2,h1,h2,target,interval,uniform,auto_range,min,b1,b2,max_diam,
        //      cos(h1),cos(h2),m2/m1 bounds,external shifts by layer,exact fraction.
        cfg=[n,max_teeth,m1,m2,h1,h2,target,ends,uniform,auto_size_range,min_teeth,
             default(backing1,backing),default(backing2,backing),max_diam,cos(h1),cos(h2),bounds,
             [for(z=[0:max_teeth]) auto_profile_shift(teeth=z,helical=h1)],
             [for(z=[0:max_teeth]) auto_profile_shift(teeth=z,helical=h2)],undef,mode],
        want_exact=!interval && reconstructed && (exact || frac[0]/frac[1]==target),
        exact_cfg=[for(i=[0:20]) i==19?frac:cfg[i]],
        seed=want_exact?_wolfrom_planetary_search(exact_cfg):undef,
        best=exact || !is_undef(seed)?seed:_wolfrom_planetary_search(cfg))
    assert(!is_undef(best),str("\nNo ",exact?"exact-ratio ":"",uniform?"uniform ":"",n,
           "-planet Wolfrom design satisfies the constraints with max_teeth=",max_teeth,
           ". Increase max_teeth, reduce n, relax the ratio or size limits, or permit a calculated tooth size."))
    _wolfrom_planetary_result(best[1],n,u,mode);

// Return [signed numerator, positive denominator], reduced without subtracting rounded ratios.
function _wolfrom_planetary_ratio_pair(s,p,q,r1,r2) =
    let(a=(s+r1)*p*r2,b=s*(p*r2-r1*q),g=_stepped_planetary_gcd(a,abs(b)))
    b==0?undef:[sign(b)*a/g,abs(b)/g];

// Signed ratios; the first ring is fixed. Modes: sun/ring, ring/sun,
// sun/carrier, carrier/sun, carrier/ring, ring/carrier.
function _wolfrom_planetary_mode_pair(mode,s,p,q,r1,r2) =
    let(A=s+r1,B=p*r2-r1*q,C=p*r2)
    mode==0 ? _wolfrom_planetary_ratio_pair(s,p,q,r1,r2) :
    mode==1 ? _wolfrom_planetary_reduce_pair(s*B,A*C) :
    mode==2 ? _wolfrom_planetary_reduce_pair(A,s) :
    mode==3 ? _wolfrom_planetary_reduce_pair(s,A) :
    mode==4 ? _wolfrom_planetary_reduce_pair(C,B) :
              _wolfrom_planetary_reduce_pair(B,C);
function _wolfrom_planetary_reduce_pair(a,b) =
    b==0?undef:let(g=_stepped_planetary_gcd(abs(a),abs(b)))
    [sign(b)*a/g,abs(b)/g];
// Convert the requested ratio to sun/output-ring for this sun/planet-1 family.
function _wolfrom_planetary_as_sun_ring(mode,s,p,v) =
    let(A=2*(s+p)/s)
    mode==0?v:mode==1?1/v:mode==4?A*v:mode==5?A/v:undef;
function _wolfrom_planetary_as_fraction(mode,s,p,f) =
    let(A=2*(s+p))
    mode==0?f:mode==1?_wolfrom_planetary_reduce_pair(f[1],f[0]):
    mode==4?_wolfrom_planetary_reduce_pair(A*f[0],s*f[1]):
    mode==5?_wolfrom_planetary_reduce_pair(A*f[1],s*f[0]):undef;
function _wolfrom_planetary_family_range(mode,s,p,v) =
    is_undef(v) || mode==2 || mode==3?undef:let(a=_wolfrom_planetary_as_sun_ring(mode,s,p,v[0]),
                          b=_wolfrom_planetary_as_sun_ring(mode,s,p,v[1]))
    [min(a,b),max(a,b)];

// Exact target fixes r2/q for each (s,p). All cross-cancellation precedes multiplication;
// reject factors whose reduced product cannot fit a bounded tooth count.
function _wolfrom_planetary_second_pair(s,p,f,N) =
    let(r1=s+2*p,g1=_stepped_planetary_gcd(abs(f[0]),s+r1),g2=_stepped_planetary_gcd(s,f[1]),
        a=(f[0]/g1)*(s/g2),b=(f[1]/g2)*((s+r1)/g1),d=a-b)
    d==0 || sign(a)!=sign(d)?undef:
    let(g=_stepped_planetary_gcd(abs(a),abs(d)),A=abs(a)/g,B=abs(d)/g,
        x=_stepped_planetary_gcd(A,p),y=_stepped_planetary_gcd(r1,B),
        aa=A/x,bb=B/y,cc=r1/y,dd=p/x,
        z=_stepped_planetary_gcd(cc,dd),c=cc/z,e=dd/z)
    aa>N/c || bb>N/e?undef:
    let(r=aa*c,q=bb*e) r<=q?undef:[q,r];

function _wolfrom_planetary_lattice(s,p,q,r2) =
    _stepped_planetary_gcd(2*(s+p),(s*q+r2*p)/_stepped_planetary_gcd(p,q));

/// Nominal fixed-ring count is derived, never changed to rescue incompatible fixed modules.
/// Layout: s,p,q,r1,r2,xs,xp,xq,xr1,xr2,a,m1,m2,L.
function _wolfrom_planetary_layout(s,p,q,r2,n,mod1,mod2,helical1=0,helical2=0,uniform=false,auto_size_range=[0.5,2],sun_data) =
    let(L=_wolfrom_planetary_lattice(s,p,q,r2))
    L<n || (uniform && L%n!=0) || p*r2==(s+2*p)*q?undef:
    let(v=is_undef(sun_data)?_stepped_planetary_sun_data(s,p,n,helical1,helical2):sun_data,
        scfg=[n,max(s,p,q,r2),mod1,mod2,helical1,helical2,0,2,uniform,auto_size_range],
        d=is_undef(v)?undef:_stepped_planetary_feasible(scfg,v,_stepped_planetary_planet_data(q,helical2),r2))
    is_undef(d)?undef:
    let(gap=n==1?1:2*d[8]*sin(180*floor(L/n)/L),
        rp=outer_radius(mod=d[9],teeth=p,profile_shift=d[5],helical=helical1),
        rq=outer_radius(mod=d[10],teeth=q,profile_shift=d[6],helical=helical2))
    n>1 && gap-2*max(rp,rq)<=1e-9*d[8]?undef:
    [s,p,q,s+2*p,r2,d[4],d[5],d[6],d[4]+2*d[5],d[7],d[8],d[9],d[10],L];

function _wolfrom_planetary_ring_radius(m,z,x,h,b) =
    let(ar=outer_radius(mod=m,teeth=z,profile_shift=x,helical=h,internal=true),
        rr=is_undef(b)?root_radius(mod=m,teeth=z,profile_shift=x,helical=h,internal=true):undef)
    _ring_gear_outer_radius(ar,rr,b);
function _wolfrom_planetary_diameter(d,h1=0,h2=0,backing1,backing2,ring1_radius) =
    2*max(is_undef(ring1_radius)?_wolfrom_planetary_ring_radius(d[11],d[3],d[8],h1,backing1):ring1_radius,
          _wolfrom_planetary_ring_radius(d[12],d[4],d[9],h2,backing2),
          d[10]+outer_radius(mod=d[11],teeth=d[1],profile_shift=d[6],helical=h1),
          d[10]+outer_radius(mod=d[12],teeth=d[2],profile_shift=d[7],helical=h2),
          outer_radius(mod=d[11],teeth=d[0],profile_shift=d[5],helical=h1));

// Lower envelope bounds ignore omitted backing, which is positive, and the
// nonnegative working-distance increase. They never rule out a better package.
function _wolfrom_planetary_lower(cfg,s,p,q,r2) =
    let(M=(s+p)*cfg[15]/cfg[14]/(r2-q),m1=is_undef(cfg[2])?cfg[3]/M:cfg[2],
        m2=is_undef(cfg[3])?cfg[2]*M:cfg[3],a=m1*(s+p)/(2*cfg[14]),
        xs=cfg[17][s],xp=cfg[17][p],xq=cfg[18][q])
    2*max(m1*((s+2*p)/(2*cfg[14])+1.25+xs+2*xp)+default(cfg[11],0),
          m2*(r2/(2*cfg[15])+1.25+xq)+default(cfg[12],0),
          a+m1*(p/(2*cfg[14])+1+xp),a+m2*(q/(2*cfg[15])+1+xq));
function _wolfrom_planetary_error_tol(cfg) =
    !is_undef(cfg[7]) || !is_undef(cfg[19])?0:4e-15*max(1,abs(cfg[6]));
function _wolfrom_planetary_better(cfg,a,b) =
    is_undef(b)?true:
    abs(a[0]-b[0])>_wolfrom_planetary_error_tol(cfg)?a[0]<b[0]:
    abs(a[1]-b[1])>1e-10*max(a[1],b[1])?a[1]<b[1]:
    _stepped_planetary_less([a[2],a[3],a[4],a[5],a[6]],[b[2],b[3],b[4],b[5],b[6]]);
function _wolfrom_planetary_diam_cap(cfg,best) =
    let(usebest=!is_undef(best) && (!is_undef(cfg[7]) || !is_undef(cfg[19]) || best[0][0]==0))
    !usebest?cfg[13]:is_undef(cfg[13])?best[0][1]:min(cfg[13],best[0][1]);

// Each candidate has two supplied motion constraints (sun input and fixed ring).
// The search ranks ratio accuracy first for scalars, and package size first for intervals.
function _wolfrom_planetary_candidate(cfg,s,p,q,r2,best) =
    let(r1=s+2*p,f=_wolfrom_planetary_mode_pair(cfg[20],s,p,q,r1,r2),M=(s+p)*cfg[15]/cfg[14]/(r2-q),
        L=_wolfrom_planetary_lattice(s,p,q,r2))
    is_undef(f) || M<cfg[16][0]*(1-1e-10) || M>cfg[16][1]*(1+1e-10) ||
    L<cfg[0] || (cfg[8] && L%cfg[0]!=0)?best:
    let(v=f[0]/f[1],interval=!is_undef(cfg[7]),ex=!is_undef(cfg[19]))
    (ex && f!=cfg[19]) ||
    (interval?(v<cfg[7][0] || v>cfg[7][1]):sign(v)!=sign(cfg[6]))?best:
    let(error=interval || ex?0:abs(v-cfg[6]),
        lo=max(_wolfrom_planetary_lower(cfg,s,p,q,r2),len(cfg)>22 && !is_undef(cfg[22])?2*cfg[22]:0),
        tied=!is_undef(best) && abs(error-best[0][0])<=_wolfrom_planetary_error_tol(cfg))
    (!is_undef(cfg[13]) && lo>cfg[13]*(1+1e-10)) ||
    (!is_undef(best) && (error>best[0][0]+_wolfrom_planetary_error_tol(cfg) ||
                        (tied && (lo>best[0][1]*(1+1e-10) ||
                         (lo>=best[0][1] && !_stepped_planetary_less([r1,r2,s,p,q],
                                           [best[0][2],best[0][3],best[0][4],best[0][5],best[0][6]]))))))?best:
    let(d=_wolfrom_planetary_layout(s,p,q,r2,cfg[0],cfg[2],cfg[3],cfg[4],cfg[5],cfg[8],cfg[9],len(cfg)>21?cfg[21]:undef),
        D=is_undef(d)?undef:_wolfrom_planetary_diameter(d,cfg[4],cfg[5],cfg[11],cfg[12],len(cfg)>22?cfg[22]:undef),
        score=is_undef(D)?undef:[error,D,r1,r2,s,p,q])
    is_undef(D) || !is_finite(D) || (!is_undef(cfg[13]) && D>cfg[13]*(1+1e-10))?best:
    _wolfrom_planetary_better(cfg,score,is_undef(best)?undef:best[0])?[score,d]:best;

function _wolfrom_planetary_group_lower(cfg,s,p) =
    let(C=(s+p)*cfg[15]/cfg[14],dl=max(1,_stepped_planetary_ceil(C/cfg[16][1])),
        dh=min(cfg[1]-cfg[10],_stepped_planetary_floor(C/cfg[16][0])),
        m1=is_undef(cfg[2])?cfg[3]*dl/C:cfg[2],a=m1*(s+p)/(2*cfg[14]))
    dl>dh?undef:
    2*max(m1*((s+2*p)/(2*cfg[14])+1.25+cfg[17][s]+2*cfg[17][p])+default(cfg[11],0),
          a+m1*(p/(2*cfg[14])+1+cfg[17][p]));
function _wolfrom_planetary_groups(cfg,best=undef) = [
    let(N=cfg[1],m=cfg[10],cap=_wolfrom_planetary_diam_cap(cfg,best))
    if(N>=3*m)
    for(s=[m:N-2*m],p=[m:floor((N-s)/2)])
        if(!cfg[8] || (2*(s+p))%cfg[0]==0)
        let(lower=_wolfrom_planetary_group_lower(cfg,s,p))
        if(!is_undef(lower) && (is_undef(cap) || lower<=cap*(1+1e-10))) [lower,s,p]
];
function _wolfrom_planetary_search(cfg) =
    let(limit=min(cfg[1],max(48,3*cfg[10])),
        seedcfg=[for(i=[0:20]) i==1?limit:cfg[i]],
        seed=limit<cfg[1]?_wolfrom_planetary_pick_groups(seedcfg,
                     _stepped_planetary_sort(_wolfrom_planetary_groups(seedcfg))):undef)
    _wolfrom_planetary_pick_groups(cfg,_stepped_planetary_sort(_wolfrom_planetary_groups(cfg,seed)),best=seed);
function _wolfrom_planetary_pick_groups(cfg,gs,i=0,best=undef) =
    i>=len(gs)?best:
    let(cap=_wolfrom_planetary_diam_cap(cfg,best),g=gs[i])
    !is_undef(cap) && g[0]>cap*(1+1e-10)?best:
    let(s=g[1],p=g[2],v=_stepped_planetary_sun_data(s,p,cfg[0],cfg[4],cfg[5]),
        r1radius=is_undef(v) || is_undef(cfg[2]) ||
                 (is_undef(cfg[7]) && is_undef(cfg[19]) && (is_undef(best) || best[0][0]!=0))?undef:
            _wolfrom_planetary_ring_radius(cfg[2],s+2*p,v[2]+2*v[3],cfg[4],cfg[11]),
        canonical=is_undef(cfg[6])?undef:_wolfrom_planetary_as_sun_ring(cfg[20],s,p,cfg[6]),
        range=_wolfrom_planetary_family_range(cfg[20],s,p,cfg[7]),
        frac=is_undef(cfg[19])?undef:_wolfrom_planetary_as_fraction(cfg[20],s,p,cfg[19]),
        family=concat(cfg,[v,r1radius,canonical,range,frac]),
        fixed_mode=cfg[20]==2 || cfg[20]==3,
        fp=_wolfrom_planetary_mode_pair(cfg[20],s,p,cfg[10],s+2*p,cfg[10]+1),
        fixed_error=is_undef(cfg[6])?undef:abs(fp[0]/fp[1]-cfg[6]),
        impossible_target=fixed_mode && (is_undef(cfg[7]) ?
                  (!is_undef(cfg[19]) ? fp!=cfg[19]:
                   !is_undef(best) && fixed_error>best[0][0]+_wolfrom_planetary_error_tol(cfg)) :
                  fp[0]/fp[1]<cfg[7][0] || fp[0]/fp[1]>cfg[7][1]),
        impossible=!is_undef(cap) && !is_undef(r1radius) && 2*r1radius>cap*(1+1e-10),
        updated=is_undef(v)||impossible||impossible_target?best:
                     !is_undef(cfg[19]) && !fixed_mode?_wolfrom_planetary_exact_family(family,s,p,best):
                     _wolfrom_planetary_q(family,s,p,cfg[10],best))
    _wolfrom_planetary_pick_groups(cfg,gs,i+1,updated);
function _wolfrom_planetary_exact_family(cfg,s,p,best) =
    let(f=_wolfrom_planetary_second_pair(s,p,cfg[25],cfg[1]))
    is_undef(f)?best:
    let(C=(s+p)*cfg[15]/cfg[14],delta=f[1]-f[0],
        lo=max(1,ceil(cfg[10]/f[0]),ceil(12/f[1]),_stepped_planetary_ceil(C/(cfg[16][1]*delta))),
        hi=min(floor(cfg[1]/f[1]),_stepped_planetary_floor(C/(cfg[16][0]*delta))))
    lo>hi?best:_wolfrom_planetary_multiples(cfg,s,p,f,lo,hi,best);
function _wolfrom_planetary_multiples(cfg,s,p,f,t,end,best) =
    t>end?best:_wolfrom_planetary_multiples(cfg,s,p,f,t+1,end,
        _wolfrom_planetary_candidate(cfg,s,p,f[0]*t,f[1]*t,best));

// Bounds for r2 at fixed s,p,q. Each sign branch is strictly decreasing in r2.
// Uniform indexing gives an arithmetic progression, not a guessed tooth rounding.
function _wolfrom_planetary_ring_bounds(cfg,s,p,q,best=undef) =
    let(N=cfg[1],C=(s+p)*cfg[15]/cfg[14],r1=s+2*p,K=(s+r1)/s,t=r1*q/p,
        fixed_mode=cfg[20]==2 || cfg[20]==3,
        target=cfg[23], interval=!is_undef(cfg[24]),
        positive=fixed_mode?undef:interval?cfg[24][0]>0:target>0,
        e=is_undef(best)?undef:best[0][0]+_wolfrom_planetary_error_tol(cfg),
        // The error envelope is in the requested ratio, then transformed.
        requested=fixed_mode || interval || is_undef(e) || e>=abs(cfg[6])?undef:[cfg[6]-e,cfg[6]+e],
        window=interval?cfg[24]:fixed_mode?undef:_wolfrom_planetary_family_range(cfg[20],s,p,requested),
        bounded=!is_undef(window),
        lo0=max(12,q+1,q+_stepped_planetary_ceil(C/cfg[16][1]),
                is_undef(positive)?0:positive?floor(t)+1:0),
        hi0=min(N,q+_stepped_planetary_floor(C/cfg[16][0]),
                is_undef(positive)||positive?N:ceil(t)-1))
    lo0>hi0 || (!is_undef(positive) && bounded && positive && window[1]<=K)?undef:
    let(lo=bounded?max(lo0,_stepped_planetary_ceil(window[1]*t/(window[1]-K))):lo0,
        hi=bounded && (!positive || window[0]>K)?
           min(hi0,_stepped_planetary_floor(window[0]*t/(window[0]-K))):hi0,
        g=_stepped_planetary_gcd(p,q),P=p/g,Q=q/g,
        d=cfg[8]?_stepped_planetary_gcd(P,cfg[0]):1)
    lo>hi || (cfg[8] && (s*Q)%d!=0)?undef:
    let(stride=cfg[8]?cfg[0]/d:1,
        residue=stride==1?0:_stepped_planetary_mod(-s*Q/d*_stepped_planetary_inverse(P/d,stride),stride),
        first=lo+_stepped_planetary_mod(residue-lo,stride),
        last=hi-_stepped_planetary_mod(hi-residue,stride))
    first>last?undef:[first,last,stride];
function _wolfrom_planetary_q(cfg,s,p,q,best) =
    q>=cfg[1]?best:
    let(b=_wolfrom_planetary_ring_bounds(cfg,s,p,q,best),
        target=cfg[23],K=2*(s+p)/s,fixed_mode=cfg[20]==2 || cfg[20]==3,
        ideal=is_undef(b) || !is_undef(cfg[7]) || fixed_mode?0:
                target>0 && target<=K?b[1]:
                min(b[1],max(b[0],target*(s+2*p)*q/p/(target-K))),
        left=is_undef(b)?0:b[0]+b[2]*floor((ideal-b[0])/b[2]),
        updated=is_undef(b)?best:!is_undef(cfg[7]) || fixed_mode?
               _wolfrom_planetary_interval_r(cfg,s,p,q,b,b[0],best):
               _wolfrom_planetary_walk(cfg,s,p,q,b,left,left+b[2],best))
    _wolfrom_planetary_q(cfg,s,p,q+1,updated);
function _wolfrom_planetary_interval_r(cfg,s,p,q,b,r,best) =
    r>b[1]?best:_wolfrom_planetary_interval_r(cfg,s,p,q,b,r+b[2],
        _wolfrom_planetary_candidate(cfg,s,p,q,r,best));
function _wolfrom_planetary_walk(cfg,s,p,q,b,left,right,best) =
    left<b[0] && right>b[1]?best:
    let(lf=left<b[0]?undef:_wolfrom_planetary_mode_pair(cfg[20],s,p,q,s+2*p,left),
        rf=right>b[1]?undef:_wolfrom_planetary_mode_pair(cfg[20],s,p,q,s+2*p,right),
        le=is_undef(lf)?1/0:abs(lf[0]/lf[1]-cfg[6]),
        re=is_undef(rf)?1/0:abs(rf[0]/rf[1]-cfg[6]),
        useleft=le<=re,r=useleft?left:right,e=min(le,re))
    !is_undef(best) && e>best[0][0]+_wolfrom_planetary_error_tol(cfg)?best:
    _wolfrom_planetary_walk(cfg,s,p,q,b,useleft?left-b[2]:left,useleft?right:right+b[2],
        _wolfrom_planetary_candidate(cfg,s,p,q,r,best));

function _wolfrom_planetary_result(d,n,drive=0,mode=0) =
    let(s=d[0],p=d[1],q=d[2],r1=d[3],r2=d[4],L=d[13],g=_stepped_planetary_gcd(p,q),
        P=p/g,Q=q/g,L2=(s*q+r2*p)/g,inverse=_stepped_planetary_inverse(Q,P),
        phi0=90+90*(2-s)/p,carrier_ratio=(s+r1)/s,ring_per_carrier=1-r1*q/(r2*p),
        c=mode==0 || mode==2?drive/carrier_ratio:mode==1 || mode==5?drive/ring_per_carrier:drive,
        sun_drive=carrier_ratio*c,ring_drive=ring_per_carrier*c,
        pf=_wolfrom_planetary_mode_pair(mode,s,p,q,r1,r2),ratio=pf[0]/pf[1],
        cells=[for(i=[0:n-1]) i==0?0:round(i*L/n)],
        angles=[for(j=cells) 360*j/L+c],positions=[for(a=angles) d[10]*[cos(a),sin(a)]],
        motion=(s+p)/p*c-s/p*sun_drive,
        spins=[for(j=cells) let(j2=j*(L2/L),k=P==1?0:_stepped_planetary_mod(-j2*inverse,P))
                   _stepped_planetary_mod(phi0+360/p*((s+p)*j/L+k),360/g)+motion],
        ring1=_stepped_planetary_mod(p/r1*(phi0+90)-90,360/r1),
        ring2=_stepped_planetary_mod(q/r2*(phi0+90)-90,360/r2)+ring_drive)
    [["sun",s,d[5],sun_drive],
     ["rings",[r1,r2],[d[8],d[9]],[ring1,ring2]],
     ["planets",[p,q],[d[6],d[7]],spins,positions,angles],
     ["ratio",ratio],["mod",[d[11],d[12]]],["carrier",carrier_ratio,c]];


// Section: Gear Attachment
//   Gear modules propagate construction parameters such as gear type, tooth size and tooth number, 
//   which enables child gear modules to inherit those parameters and construct a compatible
//   gear that will mate with the parent. 
//   Child gears inherit tooth size and applicable matching gear dimensions and parameters unless you explicitly provide them.
//   For spur gears helical angles are chosen to be equal and opposite in sign, and the herringbone
//   form inherits.  Bevel gears propagate their teeth counts and numerous parameters.  
//   Crown face width maps to pinion thickness and vice versa. Worm-pair dimensions also
//   propagate in the obvious fashion. For bevel gears profile shift inherits the negative of the parent value.
//   A spur gear child of a crown gear inherits the profile shift from its parent. Other gear types
//   do not inherit profile shift.  Settings like bore, backing, backlash, and finishing settings do not inherit.
//   .
//   You can use {{attach_gear()}} to attach a child gear to a parent gear in a designated location
//   so that the teeth mesh properly.  You can drive a chain of gears built using nested {{attach_gear()}}
//   calls by using {{gear_spin()}} before the first gear in the chain (or {{gear_travel()}} if the first gear is a rack).  
//   The specified driving motion propagates to the gear chain, making gear animations a simple matter.  
//   Each gear in the chain carries its ordinary children with its rotation or travel,
//   so it can have a child gear that shares a shaft, with the two rotating together.
//   To create children like that use the usual {{attach()}} or {{align()}} modules, or simply
//   make the gear a child of its parent.  
//   .
//   The gear assembly necessarily proceeds pairwise in a tree-like fashion, with each
//   gear constructed to mate properly with its parent.  If a gear meets an earlier gear
//   in the chain then it is your responsibility to ensure that the mesh is compatible. 


// Module: attach_gear()
// Synopsis: Positions a gear as a child of another gear with proper tooth mesh
// Topics: Gears, Attachments
// See Also: spur_gear(), ring_gear(), rack(), crown_gear(), bevel_gear(), worm_gear(), globoid_worm_gear()
// Usage: Attaching to a spur gear, ring gear, or a spur gear to a crown parent
//   PARENT() attach_gear([angle], [dir=], [shift=]) CHILD_GEAR();
// Usage: Attaching a spur gear to a rack
//   rack() attach_gear([pos=], [rack_inset=], [shift=]) spur_gear(...);
// Usage: Attaching a bevel gear to a parent bevel gear:
//   bevel_gear(..) attach_gear([angle], [dir=]) bevel_gear();
// Usage: Attaching a crown gear to a parent spur gear
//   spur_gear()attach_gear([angle], [dir=], [shift=], [crown_pos=]) crown_gear();
// Usage: Attaching a worm to a parent (worm gear or worm face gear)
//   PARENT() attach_gear([angle], [dir=], [shift=]) CHILD_GEAR();
// Usage: Attaching a worm gear to a parent worm
//   worm() attach_gear([angle], [dir=]) worm_gear();
// Usage: Attaching a worm face gear to a worm
//   worm(...) attach_gear([angle], [dir=], [shift=], [worm_face_pos=]) worm_face_gear();
// Usage: Selecting a rotary gear's ordinary-child frame
//   PARENT() attach_gear([angle], phase=, [dir=], [pos=], [shift=]) CHILD_GEAR();
// Description:
//   Places a child gear relative to its parent with meshing teeth, and propagates motion to the child
//   specified using {{gear_spin()}} (or {{gear_travel()}} for racks).
//   The child gear must be compatible with the parent, which will happen automatically if you
//   allow its parameters to inherit from the parent as described above.
//   .
//   Gear placement is defined before the drive rotation or travel is applied.
//   You specify the location of a child gear on the parent in one of two ways, using the
//   `angle` parameter or the `dir` parameter.  For planar arrangements of parallel axis gears attachment
//   angles and directions use the common reference frame defined by the first gear.  Angle is measured counterclockwise from X+
//   in that reference frame.  
//   A gear_carrier_frame() establishes a new reference for its planetary branch. Those placement directions
//   rotate with the carrier; a coaxial carrier-output gear instead starts a stationary-axis output branch.
//   If you provide a list of angles then a copy of the child gear will be placed
//   at each angle.  Alternatively `dir=` is a direction vector lying in the XY plane or a list
//   of direction vectors.  The children will appear in the directions of the listed vectors.
//   The vector magnitude is ignored.  
//   .
//   Rack coordinates have the X axis along the length of the rack and the Y axis pointing toward the teeth.
//   The position `pos=` selects a mounting location along the rack's X axis, with zero at its center.
//   An ordinary rack does not affect the coordinate system for the rotary gears, which all reference the first gear.
//   A chain starting with a rack uses the rack to establish that reference.
//   A rack attached in a skew mesh establishes a new coordinate frame and subsequent rotary gears use this new rotated frame.
// Figure(Big,2D,NoScales,VPD=356.40,VPT=[68.98,16.04,0.00]): A planar gear assembly.  Gear A is the root gear that defines the coordinate system, here aligned with the global coordinates.  The other rotary gears share the same coordinate system, and the diagrams show how their angles are interpreted to define the placement of the next gear.  The rack center is placed **approximately** at the specified point because it has to match the teeth of the parent gear.  The Rack's coordinate system is defined by its length and is **not** the same as the coordinate frame of the rotary gears.  But gear D, which is attached to the rack, again has the coordinate system of the root rotary gear.  
//   $fn = 64;
//   m = 2;
//   teeth_a = 24;  teeth_b = 29;  teeth_c = 28;  teeth_d = 17;
//   rack_teeth = 22;
//   angle_ab = 45;  angle_bc = -33;  angle_cr = 50;
//   rack_angle = angle_cr + 90;
//   pinion_pos = -50;
//   dim_y=-15;
//   rack_half = rack_teeth*PI*m/2;      // half the rack length (pitch line)
//   gearcolor="#CFE0EE";
//   rackcolor="PaleGoldenrod";
//   axescolor = "#2B3A4A";
//   angcolor = "DarkOrange";
//   module lbl(s, p, sz=4.8, fa=0) translate(p) rotate(-fa) text(s, size=sz, halign="center", valign="center");
//   module axes(len, w=1.05) { circle(d=2.2); stroke([[0,0],[len,0]], width=w, endcap2="arrow2"); stroke([[0,0],[0,len]], width=w, endcap2="arrow2"); }
//   gear_spin(0) recolor(gearcolor) spur_gear2d(mod=m, teeth=teeth_a) {
//       // ---- Gear A ----
//       color(axescolor) { axes(15); lbl("X+", [15.2,-5]);  lbl("Y+", [-4,16]); }
//       color("Black")   lbl("A", [-8,-8], 6.5);
//       color(angcolor) {
//           stroke([[0,0], gear_dist(mod=m,teeth1=teeth_a,teeth2=teeth_b)*[cos(angle_ab),sin(angle_ab)]], width=1.25, endcap2="arrow2", color=angcolor);
//           stroke(arc(n=33, r=9, angle=angle_ab), width=1.05);
//           lbl("45°", [14.8,6.1]);
//       }
//       attach_gear(angle_ab) recolor(gearcolor) spur_gear2d(teeth=teeth_b) {
//           // ---- Gear B ----
//           color(axescolor) { axes(20); lbl("X+", [18,5]);  lbl("Y+", [-6,20]); }
//           color("Black")   lbl("B", [-14,5], 6.5);
//           color(angcolor) {
//               stroke([[0,0], gear_dist(mod=m,teeth1=teeth_b,teeth2=teeth_c)*[cos(angle_bc),sin(angle_bc)]], width=1.25, endcap2="arrow2", color=angcolor);
//               stroke(arc(n=33, r=9, angle=angle_bc), width=1.05);
//               lbl("−33°", [18.1,-4.99]);
//           }
//           attach_gear(angle_bc) recolor(gearcolor) spur_gear2d(teeth=teeth_c) {
//               // ---- Gear C ----
//               color(axescolor) { axes(20); lbl("X+", [18,-5]);  lbl("Y+", [-6,17]); }
//               color("Black")   lbl("C", [-8,-9], 6.5);
//               color(angcolor) {
//                   stroke([[0,0], gear_dist(mod=m,teeth1=teeth_c,teeth2=0)*[cos(angle_cr),sin(angle_cr)]], width=1.25, endcap2="arrow2", color=angcolor);
//                   stroke(arc(n=33, r=8, angle=angle_cr), width=1.05);
//                   lbl("50°", [16.3,7.6]);
//               }
//               attach_gear(angle_cr) recolor(rackcolor) rack2d(teeth=rack_teeth, backing=7) {
//                   // ---- Rack ----
//                   color(axescolor) {
//                       stroke([[0,dim_y],[0.8*rack_half,dim_y]], width=1.5, endcap2="arrow2");
//                       lbl("X+", [0.8*rack_half+5, dim_y], fa=rack_angle);
//                   }
//                   color(angcolor) {
//                       stroke([[0,0],[0,-17]],          width=.9);                       // tick at rack origin
//                       stroke([[pinion_pos,0],[pinion_pos,-17]], width=.9);              // tick at pinion
//                       stroke([[0,-15],[pinion_pos,-15]], width=1.2, endcap2="arrow2");  // dimension
//                       lbl("x=−50", [-43,-24], fa=rack_angle);
//                   }
//                   attach_gear(pos=pinion_pos) recolor(gearcolor) spur_gear2d(teeth=teeth_d) {
//                       // ---- Gear D ----
//                       color(axescolor) { axes(12); lbl("X+", [8,-5]);  lbl("Y+", [-6,8]); }
//                       color("Black")   lbl("D", [-5,-6], 6.5);
//                   }
//               }
//           }
//       }
//   }
// Continues: 
//   A worm, bevel, crown, or skew mesh establishes a new local frame for its child. Subsequent
//   placements use that child's X and Y axes, with Z along its shaft.
//   When meshing spur gears if you do not give `helical` then the helical angle is chosen to create a parallel
//   axis configuration, but if you give the helical value for the child, the child gear mates with its parent at
//   the appropriate skew angle.   If you place the gear in the original planar coordinate system
//   and then rotate it around the line that connects the gear centers the result is the new skewed
//   coordinate system.
// Figure(Med,3D,NoScales,VPR=[55.00,0.00,86.60],VPD=488.89,VPT=[100.73,54.07,0.60]): The blue parent gear lies in the XY plane and the black line shows the rotational axis, the line between the two gear centers.  The yellow gear starts with the same coordinate system as the blue one but then rotates around the black axis, resulting in the coordinate system shown below with X in red and Y in green. 
//   w=5;
//   $fn=32;
//   ang=45;
//   color_this("lightblue")
//   spur_gear(mod=3, teeth=27)
//     attach_gear(ang)
//   spur_gear(teeth=19, helical=35) {
//       stroke(130*[[0,0,0],[1,0,0]], endcap2="arrow2",color="red",width=w);
//       stroke(130*[[0,0,0],[0,1,0]], endcap2="arrow2",color="green",width=w);
//   }
//   stroke([-zrot(45,RIGHT)/2, zrot(45,RIGHT)]*170, color="black", width=w*.8);
// Continues:
//    For either order of a worm pair, the child's X+ points away from the parent
//    shaft and its Y+ is parallel to the parent's shaft, in the parent's Z+ direction. The parent engagement
//    is on the child's X- side.
// Figure(3D,Med,NoAxes,VPR=[74.00,0.00,56.50],VPD=488.89,VPT=[81.99,42.07,43.67]): For a worm parent, the child worm gear's X+ (red) points away from the worm shaft and its Y+ (green) follows the worm's shaft (in the Z+ direction).
//   w=3;
//   color_this("lightblue")worm(mod=3, d=44, l=75)
//     attach_gear(30)
//      worm_gear(teeth=33)
//    {
//          stroke(130*[[0,0,0],[1,0,0]], endcap2="arrow2",color="red",width=w);
//          stroke(130*[[0,0,0],[0,1,0]], endcap2="arrow2",color="green",width=w);
//      }
// Figure(3D,Med,NoAxes,VPR=[63.00,0.00,50.50],VPD=488.89,VPT=[72.78,28.22,43.77]): For a worm gear parent, the child worm's X+ (red) points away from the worm gear shaft and its Y+ (green) follows the worm gear's shaft (in the Z+ direction).
//   w=3;
//   color_this("lightblue")      worm_gear(mod=3,teeth=33,worm_diam=44)
//     attach_gear(30)
//     worm(mod=3, d=44, l=75)
//    {
//          stroke(130*[[0,0,0],[1,0,0]], endcap2="arrow2",color="red",width=w);
//          stroke(130*[[0,0,0],[0,1,0]], endcap2="arrow2",color="green",width=w);
//      }
// Continues:
//   A worm face gear pair uses the same convention: the child's X+ points away from the parent shaft and
//   its Y+ is parallel to the parent shaft.  A worm engages with its worm face gear parent on its Y- side.
// Figure(3D,Med,NoScales,VPR=[45.20,0.00,26.40],VPD=292.71,VPT=[-4.26,22.97,-28.26]):  A worm child of a worm face gear has the child worm's X+ (red) pointing away from the worm face gear shaft, with the child worm's Y+ (green) following the worm face gear shaft (in the Z+ direction)
//   w=2; color_this("lightblue")
//   worm_face_gear(mod=2, teeth=41, worm_diam=20, shaft_offset=35, face_width=13, backing=3)
//       attach_gear(0)
//            worm(l=60)
//    {
//       stroke(.5*130*[[0,0,0],[1,0,0]], endcap2="arrow2",color="red",width=w);
//       stroke(.5*130*[[0,0,0],[0,1,0]], endcap2="arrow2",color="green",width=w);
//   }
// Figure(3D,Med,NoAxes,VPR=[95.60,0.00,278.60],VPD=446.13,VPT=[78.24,-41.83,-7.29]): A worm face gear child has its X+ axis pointing away from the worm and its Y+ axis aligned with the worm's shaft (Z+ axis)
//   w=3; color_this("lightblue")
//   worm(l=60,worm_diam=20,mod=2)
//          attach_gear(0)
//   worm_face_gear(mod=2, teeth=41, worm_diam=20, shaft_offset=35, face_width=15, backing=3)
//    {
//       stroke(.75*130*[[0,0,0],[1,0,0]], endcap2="arrow2",color="red",width=w);
//       stroke(.75*130*[[0,0,0],[0,1,0]], endcap2="arrow2",color="green",width=w);
//   }
// Figure(3D,VPR=[66.90,0.00,63.50],Med,NoAxes): For a crown gear parent the spur gear has its Z+ axis pointing outward, the X+ axis (red) is tangent to the crown gear and the Y+ axis (green) points opposite the crown gear's shaft (in the Z- direction).
//   w=3; color_this("lightblue")
//   crown_gear(mod=4, teeth=32, mate_teeth=9, backing=13, face_width=17)
//       attach_gear(0)
//            spur_gear(teeth=9)
//    {
//       stroke(130*[[0,0,0],[1,0,0]], endcap2="arrow2",color="red",width=w);
//       stroke(130*[[0,0,0],[0,1,0]], endcap2="arrow2",color="green",width=w);
//   }
// Figure(3D,Med,NoAxes,VPR=[55.00,0.00,309.40]): With a crown gear child the Y+ axis (green) points toward the parent spur gear and the X+ axis (red) is on its right side as seen from above the crown gear.  
//    w=3;  color_this("lightblue")
//        spur_gear(teeth=9,mod=4)
//           attach_gear(0,crown_pos=DOWN)
//       crown_gear(mod=4, teeth=32, backing=13, face_width=17)
//        {
//           stroke(130*[[0,0,0],[1,0,0]], endcap2="arrow2",color="red",width=w);
//           stroke(130*[[0,0,0],[0,1,0]], endcap2="arrow2",color="green",width=w);
//       }
// Continues:
//   For bevel gears, the child's Y+ is the projection of the parent's Z+ direction
//   onto the plane of the bevel gear. With perpendicular shafts,
//   its Y+ follows the parent's Z+.   The parent engagement is on Y-.
// Figure(3D,Med,NoScales,VPR=[63.00,0.00,341.60],VPD=670.63,VPT=[85.59,73.22,48.73]): The bevel gear child has its Y+ axis (in green) defined by the projection of the parent Z+ onto the face of the child gear.   The Z+ axis points up towards the teeth, and the X+ axis is determined by the other two.  
//     w=3;
//     bevel_gear(mod=4,teeth=20,mate_teeth=31,face_width=6,shaft_angle=70)
//       attach_gear(37) bevel_gear()    {
//          stroke(130*[[0,0,0],[1,0,0]], endcap2="arrow2",color="red",width=w);
//          stroke(130*[[0,0,0],[0,1,0]], endcap2="arrow2",color="green",width=w);
//      }
// Continues:
//   For attaching a spur gear to a rack give `pos=`, which gives the position of the child
//   on the rack, with zero at the rack center.  
//   When the rack is the child the usual `angle` or `dir` parameters identify the engagement point
//   on the parent.  By default the rack engages 
//   as near as possible to its midpoint while forming a correct mesh. 
//   Adding LEFT or RIGHT to the rack's anchor selects engagement near the specified end,
//   and in this case, `rack_inset=` controls the number of teeth inward to shift
//   from the very end.  
//   .
//   The thickness of gears inherits but if you create gears with differing thickness they
//   will align on their centers by default.  You can give `anchor=TOP` or `anchor=BOT` to
//   align the child at the top or bottom face respectively (side faces for racks).  For racks, whose native position
//   is different you can also give FWD or BACK to align the rack front or back side with the top or bottom of the pinion.
//   For more control over positioning you can use the `shift=` parameter, which adjusts the position of the child
//   spur gear or rack perpendicular to the gear's face.  This adjustment is relative to the alignment
//   you specify using the gear's anchor parameter.  For helical gears, shifting the gear also
//   requires adjusting its rotation for proper tooth mesh, so you cannot make this adjustment with
//   a direct translation in those cases.  Herringbone gears and skew helicals require center alignment.
//   .
//   Worm drive pairs inherit the shared worm diameter, worm starts, pressure angle and for
//   globoids, the teeth counts and working length.  They can be nested in either order and
//   the child is automatically rotated 90 degrees to create the proper mesh.  The child
//   cannot have any anchor but CENTER.  The engagement point is determined by `angle` or `dir=`.
//   You can shift the child in a a cylindrical worm drive using the `shift=` parameter, which
//   moves the child in the direction of the worm's shaft.  
//   .
//   For worm face drive in either order inheritance propagates the necessary parameters.
//   The engagement point on the parent is determined by `angle` or `dir=`.  
//   You can use `shift=` to shift the child in the direction of the worm's shaft.
//   A worm face gear can engage with the worm in four positions, given that the shaft offset is fixed. To flip the worm to the lower position change
//   to `left_handed=true`.  To control sideways position of the worm use `worm_face_pos=LEFT` or `worm_face_pos=RIGHT` (the default).  
//   .
//   A crown gear parent uses `angle` to choose the spur gear location around its toothed ring.
//   The spur gear is positioned with its top face pointed radially outward.  With a spur gear parent
//   and a crown child, `crown_pos=DOWN` or `UP` selects whether the crown center extends
//   down toward the spur gear's Z- axis or UP towards Z+.  Crown gears require mating spur
//   gears with zero helical angle.  A spur gear child inherits its thickness from
//   the crown face; a child crown inherits its face width from the spur gear's thickness.  
//   The spur gear is centered on the face width of the crown gear by default.  You can
//   give `shift=` to move the child gear radially outwoard relative to the parent gear.  
//   .
//   Bevel gears inherit tooth counts, `shaft_angle`, `face_width`, `spiral`, and `cutter_radius`,
//   and take opposite handedness and opposite profile shift. Backing, bore, and body thickness are not inherited.
//   The `angle` parameter to `attach_gear()` selects the position where the gears mate;
//   the `drive_angle` and `shaft_angle` parameters specify the angle between the shafts of
//   the two bevel gears.  A bevel child accepts only the default "pitchbase" anchor. 
//   .
//   Motion of the top level parent provided by {{gear_spin()}} (or for racks, {{gear_travel()}}) propagates
//   through the entire gear chain automatically.  You can animate the entire assembly by simply
//   changing the top level parameter.  Each gear and its regular attachments will move
//   in accordance with the driven gear motion.  If a gear in the chain meets a previous gear, it is your
//   responsibility to ensure that it meshes correctly.  
//   If you apply `gear_spin` to any child the spin applies on top of the above positioning,
//   which will lead to an incorrect mesh if your spin is not an even multiple of a tooth angle. 
//   .
//   When you provide multiple angles or directions the `$idx` variable indexes them in the
//   order you give them, and `$ang` also provides the angle, or for racks, `$pos` provides
//   the position.
//   .
//   Several variables starting with `$gear` are provided inside the child gear that you
//   create using `attach_gear()`.  The `$gear_contact_dir` and `$gear_contact_angle`
//   variables give the direction and angle to the nominal engagement point 
//   to the parent in the current child reference frame (which will change as the child rotates).
//   For external spur pairs it points toward the parent shaft.  For a pinion inside a parent ring
//   it points outward toward the ring teeth.  Actual tooth contact moves as the gears turn, so
//   this does not identify the actual point of contact.
//   For a rack the direction is the toothed-side, UP (Z+) for 3D racks and BACK (Y+) for 2D racks.  A root gear has no parent engagement
//   and reports undef.
//   .
//   You can also extract the gear ratio.  For a rotational input, `$gear_ratio` is the
//   (output angle)/(input angle) and `$gear_travel_ratio` is (output distance)/(input angle).
//   For a travel input, `$gear_ratio` is (output angle)/(input distance) and
//   `$gear_travel_ratio` is (output distance)/(input distance).  The angles are measured
//   in degrees and the distances in model units.  A rack has zero angular gain and a rotating
//   gear has zero travel distance.  When the direction reverses the ratio will be negative.  
//   
//   For placing gear shafts or shaft holes with automatically generated gears, you can use
//   `$gear_chain_locs` and `$gear_chain_axes`.  The first one contains the locations of
//   the gear centers in the gear chain, starting at the root gear and working up to the current gear.
//   For racks it gives the pitch-line origin. The second gives shaft-axis unit vectors
//   in the same order, or undef for racks. Both lists use the current child frame.
//
//   A rotary gear attached with `phase=` retains its automatically meshed tooth geometry, but its ordinary children
//   use an outgoing frame with the specified zero-drive orientation, in degrees relative to the gear's stationary
//   assembly reference.  The phase does not change the driven rotation, gear ratio, or automatic meshing.
//   Omitting phase preserves the existing child coordinate frame.  A scalar applies to every placement;
//   a list supplies one finite orientation for each attachment angle or position.
//   The option requires a rotary child; an attached rack does not accept it.  Fractional and negative angles are allowed.
//   Later automatic gear placements retain their stationary assembly reference; they do not follow the selected child-frame angle.
//   Within a carrier branch, this means the carrier reference: phase changes rigid-child indexing, not orbital placement.
//   An ordinary coaxial gear child inherits the selected frame, but not the parent's local tooth offset.
//   For a compound planet, use its zero-drive installation phase; keep animation in the driving module rather than in this phase.
//   The `$gear_rotation` parameter reports the driven rotation of the current gear around its shaft.
//   The `$gear_angle_offset` parameter reports the tooth-alignment offset  
//   plus any user specified local `gear_spin=` passed to the gear as a parameter.
//   Within the rotating child frame, this is
//   the extra angle needed to align a feature with the constructor's reference tooth geometry.
//   With `phase=`, `$gear_angle_offset` is measured relative to the selected outgoing child frame.
//   For racks, `$gear_travel` reports motion from the initially placed rack position, and
//   `$gear_travel_offset` reports the additional locally specified `gear_travel=` offset in model units.
//   The initial tooth-alignment translation is part of the rack's placement.
// Arguments:
//   angle = Placement angle in degrees, or a list of angles. Default: 0 for a non-rack parent when `dir` is omitted.
//   ---
//   phase = Zero-drive angular orientation, in degrees, of the attached rotary gear's ordinary-child frame in the stationary assembly reference.  Scalar or one value per placement. Does not rotate the teeth or affect meshing. Default: preserve the existing child frame.
//   dir = One 2D/3D direction vector, or a list of direction vectors, in the parent's stationary XY plane. Magnitude is ignored.   
//   pos = Child gear mounting position along a parent rack's X axis (scalar or list). Default: 0
//   shift = Signed distance to shift child gear or worm along the parent shaft for parallel 3D spur and ring gear pairs, along the pinion shaft for a 3D rack and pinion pair or for cylindrical worms or worm face gears. Default: 0
//   rack_inset = Nonnegative integer pitch count added inward from the most extreme mesh-compatible position at a child rack placed with LEFT or RIGHT. Default: 1
//   crown_pos = UP or DOWN in the spur parent's shaft frame, selecting where a child crown extends. Only for spur parent with crown child. Default: DOWN
//   worm_face_pos = RIGHT or LEFT, selects the offset side for a worm-face child of a cylindrical worm.  Default: RIGHT.
// Side Effects:
//   `$idx` is set to the zero-based placement index for each child copy.
//   `$ang` is set to the resolved placement angle, or undef for a rack parent.
//   `$pos` is set to the along-rack mounting position or the specified worm-face axial position; otherwise undef.
//   Sets internal variables requesting mating placement and gear inheritance.
//   `$gear_rotation` is set inside the child gear to the total gear rotation of a rotating gear resulting from {{gear_spin()}} or {{gear_travel()}} applied to the gear chain root.
//   `$gear_angle_offset` is set inside the child gear to its angular tooth-alignment offset in degrees, including meshing alignment and local `gear_spin`.
//   `$gear_angle_offset` includes the offset relative to any explicitly selected `phase=` child frame.
//   `$gear_ratio` is set inside the child gear to the signed angular gain: (output degrees)/(input degrees) for rotational input, or (output degrees)/(input travel) for travel input in model units.
//   `$gear_travel` is set inside the child rack to the displacement in model units of the rack resulting from {{gear_spin()}} or {{gear_travel()}} applied to the gear chain root.
//   `$gear_travel_offset` is set inside the child rack to the local `gear_travel`, in model units.
//   `$gear_travel_ratio` is set inside the child rack to signed linear gain: (out travel)/(input rotation) for rotational input, or (output travel)/(input travel) for travel input. 
//   `$gear_input` is set inside the child gear to "rotation" (degrees), "travel" (model units), or undef for an undriven chain.
//   `$gear_contact_dir` is set inside the child gear to the nominal engagement direction with the parent in the current child frame.
//   `$gear_contact_angle` is set inside the child gear to the corresponding engagement angle in degrees in the current child frame.
//   `$gear_chain_locs` is set inside the child gear to a list of gear center coordinates (pitch-line origins for racks) in the current child frame, with the root gear first and the current gear last.
//   `$gear_chain_axes` is set inside the child gear to a list of shaft-axis unit vectors (`undef` for racks) in the current child frame, with the root gear first and the current gear last.
// Example(2D,NoScales): Three attached spur gears with different sizes using `$idx`.
//   gear_spin(360*$t)  // For animation
//   color_this("lightblue")
//   spur_gear2d(mod=2,teeth=24)
//     attach_gear([0,120,240])
//       spur_gear2d(teeth=16+5*$idx);
// Example(2D,NoScales): Attach a rack to a spur gear, starting at the left edge of the rack (relative to the rack, so it looks like the right below)
//   gear_spin(-90*$t)  // For animation
//   color_this("lightblue")
//   spur_gear2d(mod=2,teeth=14)
//     attach_gear(90,rack_inset=2)
//       rack2d(teeth=15,anchor=LEFT);
// Example(2D,VPD=550,NoScales): A rack drives two stationary-axis pinions.
//   rack2d(mod=4,teeth=20,spin=-45)
//       attach_gear(pos=[-45,45])
//         spur_gear2d(teeth=14);
// Example(3D,NoScales): A matched bevel child inherits its pair definition.
//   bevel_gear(mod=2,teeth=20,mate_teeth=30,face_width=6)
//       recolor("lightblue")attach_gear(90) bevel_gear();
// Example(3D,NoScales,VPR=[79.10,0.00,44.10],VPD=172.84,VPT=[5.76,-3.86,2.72]): An internal-like bevel pair
//    gear_spin(30*sin(360*$t))
//       bevel_gear(mod=2,teeth=35,mate_teeth=15,shaft_angle=135,
//                  face_width=5,spiral=35,backing=4,backlash=.2)
//         color_this("lightblue")
//         attach_gear(90) bevel_gear(backing=4,backlash=.2);
// Example(3D,NoScales): A crown child extending toward the spur's positive shaft end.
//   gear_spin(360*$t)
//   spur_gear(mod=2,teeth=20,thickness=6)
//       recolor("lightblue")   
//       attach_gear(90,crown_pos=UP) crown_gear(teeth=40);
// Example(3D,NoScales): Place a helical child 4 units below the top of its parent
//   $fn=64;
//   spur_gear(mod=2,teeth=24,thickness=28,helical=25,backlash=.1,slices=24)
//       attach_gear(25,shift=-4)
//           recolor("lightblue") spur_gear(teeth=36,thickness=14,anchor=TOP,backlash=.1,slices=36);
// Example(3D,Med,VPR=[55.00,0.00,25.00],VPD=237.09,VPT=[33.17,10.33,-6.65],NoScales,Anim,Frames=48,FrameMS=55): A two-level compound train changes tooth size on the common shaft before driving its next mate.
//   $fn=64;
//   gear_spin(135*$t)
//   spur_gear(mod=2,teeth=24,thickness=6,shaft_diam=4)
//       attach_gear(0)
//           recolor("lightblue") spur_gear(teeth=36,shaft_diam=4)
//               attach(TOP,BOT)
//                   recolor("orange") spur_gear(mod=1,teeth=20,thickness=5,shaft_diam=4)
//                       attach_gear(90)
//                           recolor("gold") spur_gear(teeth=40,shaft_diam=4);
// Example(3D,Big,NoScales,VPR=[80.90,0.00,306.60],VPD=237,VPT=[7.82,-32.82,-6.88]): A crossed-helical input drives a coaxial cylindrical worm and a second compound spur stage.
//   $fn=48; $gear_steps=12;
//   gear_spin(90*sin(360*$t))
//   spur_gear(mod=1,teeth=24,thickness=8,helical=20,profile_shift=0,backlash=.1,slices=24)
//       attach_gear(0)
//           recolor("lightblue") spur_gear(teeth=36,helical=30,profile_shift=0,backlash=.1,slices=32)
//               attach(TOP,BOT)
//                   recolor("gold") worm(mod=1,d=14,l=38,starts=3)
//                       attach_gear(dir=FRONT)
//                           recolor("orange") worm_gear(teeth=30,thickness=6,backlash=.1,slices=8)
//                               attach(TOP,BOT)
//                                   recolor("lightgreen") spur_gear(mod=1,teeth=20,thickness=4,helical=0)
//                                       attach_gear(25)
//                                           recolor("pink") spur_gear(teeth=40)
//                                              echo($gear_ratio);   // Prints 0.03333333
// Example(3D,Big,VPR=[86.50,0.00,295.40],VPD=361.36,VPT=[20.49,-61.32,-2.35],NoScales): An asymmetric globoid stage followed by a two-level helical output with axial clearance.
//   $fn=48;
//   gear_spin(90*sin(360*$t))
//   globoid_worm(mod=2,d=24,l=35,mate_teeth=55,starts=5,pressure_angle=[45,5],
//                rounding=.2,mesh_tol=.08)
//       attach_gear(dir=FRONT)
//           recolor("lightblue") globoid_worm_gear(thickness=12,backlash=.15,rounding=.2,mesh_tol=.08)
//               attach(TOP,BOT)
//                   // The compound is a new tooth family: give its scalar pressure angle explicitly.
//                   recolor("orange") spur_gear(mod=1,teeth=24,thickness=6,pressure_angle=20,
//                                            helical=20,profile_shift=0,backlash=.1,slices=20)
//                       attach_gear(-25,shift=3)
//                           recolor("gold") spur_gear(teeth=36,helical=-20,profile_shift=0,backlash=.1,slices=24);
// Example(3D,NoAxes,Med,VPR=[90.00,0.00,0.00],VPD=1150,VPT=[-15.51,37.07,1.21]): The left hand image shows a worm face gear attached with `worm_face_pos=LEFT` and the right hand image shows `worm_face_pos=RIGHT` (the default). 
//   xcopies(n=2,spacing=330)   
//      worm(mod=3,worm_diam=45,worm_length=85)
//          attach_gear(dir=BACK,worm_face_pos=$idx ? LEFT:RIGHT)
//              worm_face_gear(teeth=47,shaft_offset=58);
// Example(3D,Med,Anim,FrameMS=55,Frames=60,NoScales,VPR=[72.10,0.00,25.20],VPD=325.23,VPT=[3.96,8.55,13.82]): A skew rack starts near the LEFT end.
//   gear_spin(-180*8/12*(0.5+0.5*cos(360*$t))) 
//       spur_gear(mod=2,teeth=24,thickness=10,helical=17.5,backlash=.15,slices=32)
//           attach_gear(90,rack_inset=2)
//               recolor("lightblue") rack(teeth=12,thickness=10,helical=22.5,anchor=LEFT,backlash=.15);
// Example(2D,Med,Anim,Frames=72,FrameMS=50,VPD=325,NoScales): A pinion rolling along a fixed rack is created by canceling the rack travel with an opposite movement
//   travel=30*sin(360*$t);
//   left(travel) gear_travel(travel)
//       rack2d(mod=1.5,teeth=32)
//           attach_gear(pos=0)
//               recolor("lightblue") spur_gear2d(teeth=20,profile_shift=0) {
//                   // Ordinary children of this automatically driven pinion follow its rotation.
//                   color("red") right(6) circle(d=3,$fn=16);
//               }
// Example(2D,Med,Anim,NoScales,Frames=120,VPD=325,FrameMS=30): The same method creates a pinion rolling around a fixed spur gear.
//   spin=360*$t;
//   zrot(-spin) gear_spin(spin)
//       spur_gear2d(mod=1.5,teeth=36) {
//           recolor("black") right(8) circle(d=3,$fn=16);
//           attach_gear(0)
//               recolor("lightblue") spur_gear2d(teeth=18,profile_shift=0) {
//                   color("red") right(5) circle(d=2.5,$fn=16);
//               }
//       }
// Example(3D,Med,NoAxes,Anim,Frames=20,FrameMS=30,VPT=[0.128673,0.24149,0.651451],VPR=[38.5,0,21],VPD=222.648): Planetary gear with fixed carrier, built from ring inward.  Helical angle is handled automatically.  
//   mod=1;
//   helical=25;
//   spin = 360/27*$t;
//   gear_data = planetary_gears(mod=mod, n=4, max_teeth=82, sun_ring=3, helical=helical);
//   gear_spin(spin)
//   ring_gear(mod=mod, teeth=gear_data[1][1], profile_shift=gear_data[1][2], helical=helical, backing=2)
//     attach_gear(gear_data[2][5])
//       color_this("red")
//       spur_gear(teeth=gear_data[2][1], profile_shift=gear_data[2][2])
//         if ($idx==0)
//           attach_gear(180)
//             spur_gear(teeth=gear_data[0][1], profile_shift=gear_data[0][2]);
// Example(2D,Med,NoAxes,Anim,Frames=90,FrameMS=30,VPT=[-0.875705,-0.110537,-66.3877],VPR=[0,0,0],VPD=102,Med): Planetary gear with fixed sun: build from the sun to the ring and counter-rotate the whole assembly to zero out the sun's rotation
//   gear_data = planetary_gears(mod=1, n=3, max_teeth=28, ring_carrier=1.341);
//   spin = 360*$t/3;
//   zrot(-spin) gear_spin(spin)
//   spur_gear2d(mod=1, teeth=gear_data[0][1], profile_shift=gear_data[0][2])   //sun
//     attach_gear(gear_data[2][5])
//       color_this("green")  
//       spur_gear2d(teeth=gear_data[2][1],profile_shift=gear_data[2][2])
//         if($idx==0)
//           attach_gear(180)ring_gear2d(teeth=gear_data[1][1], profile_shift=gear_data[1][2],backing=2);
// Example(2D,Med,NoAxes,Anim,FrameMS=55,Frames=72,VPT=[-0.125033,0.508151,-66.3877],VPR=[0,0,0],VPD=192.044): Planetary gear with fixed ring: build from the ring inward and counter-rotate to zero out the ring's rotation.
//   mod=1;
//   gear_data = planetary_gears(mod=mod, n=5, max_teeth=70, sun_carrier=3.6);
//   spin=360/5*$t;
//   zrot(-spin) gear_spin(spin)
//   ring_gear2d(mod=mod, teeth=gear_data[1][1], profile_shift=gear_data[1][2], backing=2)
//     attach_gear(gear_data[2][5])
//       color_this("purple")  
//       spur_gear2d(teeth=gear_data[2][1], profile_shift=gear_data[2][2])
//         if ($idx==0)
//           attach_gear(180)
//             spur_gear2d(teeth=gear_data[0][1], profile_shift=gear_data[0][2]);
// Example(3D,Big,NoAxes,Frames=150,FrameMS=30,VPR=[36.80,0.00,0],VPD=385,VPT=[-0.97,-0.43,11.29]): Two gear-cam cartridges with different phases.  Undoing the cartridge's in-plane rotation keeps the follower and guides parallel to the stationary mounting axes.
//    $fn=64;
//    $gear_steps=20;
//    $backlash=0.15;
//    input_angle=540*$t;
//    installed_phase=[-5,85];
//    cam_radius=10;
//    eccentricity=5;
//    gear_spin(input_angle)
//      recolor("gold")
//      spur_gear(mod=2,teeth=24,thickness=6)
//        attach_gear([0,180],phase=installed_phase)
//        let(cartridge_index=$idx)
//        recolor("cornflowerblue")
//        spur_gear(teeth=36,thickness=6) {
//            align(TOP)
//            recolor("mediumseagreen")
//            spur_gear(mod=1.5,teeth=18,thickness=6) {
//                // Components of the manufactured cartridge, all in its rotating frame.
//                align(TOP) recolor("dimgray") cuboid([10,7,6])
//                  align(TOP) right(eccentricity)
//                      recolor("darkorange")
//                        cyl(r=cam_radius,h=4){
//                          align(TOP,RIGHT,inset=2)
//                        recolor("crimson") cyl(d=2.5,h=2);
//                      }    
//                // Move the guide in Y as the eccentric cam turns, but NEVER rotate
//                // the stationary guide rails with the cartridge. Because these
//                // parts are here, the gear's attachment determines their X center.
//                let(cam_angle=installed_phase[cartridge_index]+$gear_rotation,
//                    cam_top=cam_radius+eccentricity*sin(cam_angle))
//                  up(11)zrot(-cam_angle) {
//                     back(cam_top) recolor("slategray") {
//                           cuboid([30,4,4],anchor=FWD);
//                           cuboid([4,24,4],anchor=FWD);
//                     }
//                     xcopies(spacing=17*2)
//                        back(25)
//                            recolor("silver") cuboid([3,36,3],anchor=CTR);
//                }
//            }
//        }
 
module attach_gear(angle, _named, dir, pos, rack_inset, crown_pos, shift, worm_face_pos, phase) {
    assert(is_undef(_named), "\nToo many positional arguments (only 1 is accepted)");
    assert(!is_undef($_gear_parent_spec), "\nattach_gear() needs a parent gear module");
    assert(is_undef($_gear_attach_request), "\nPlace a child gear between successive attach_gear() calls");
    assert(is_undef($attach_to), "\nPut attach_gear() directly below its parent gear, not after attach()");
    israck = _gear_is_rack($_gear_parent_spec[0]);
    assert(israck ? is_undef(angle)&&is_undef(dir) : is_undef(pos),
           str("\n",israck ? "Use pos=, not angle or dir, to place a pinion along a rack" :
                    "pos is only used for a rack parent. Use shift for axial gear placement."));
    assert(num_defined([angle,dir,pos])<=1, "\nSpecify only one of angle, dir or pos");
    assert(is_undef(shift) || is_finite(shift), "\nshift must be a finite signed axial distance");
    assert(is_undef(rack_inset) || (is_int(rack_inset) && rack_inset>=0),
           "\nrack_inset must be a nonnegative integer number of rack pitches");
    assert(is_undef(crown_pos) || crown_pos==UP || crown_pos==DOWN,
           "\ncrown_pos must be UP or DOWN in the spur parent's frame");
    assert(is_undef(worm_face_pos) || worm_face_pos==LEFT || worm_face_pos==RIGHT,
           "\nworm_face_pos must be LEFT or RIGHT");
    assert(is_undef(worm_face_pos) || $_gear_parent_spec[0]=="worm",
           "\nworm_face_pos is only used when a cylindrical worm parent receives a worm-face child");
    placements = israck ? _gear_placement_values(default(pos,0),"pos") :
                 is_undef(dir) ? _gear_placement_values(default(angle,0),"angle") :
                 [for(v=is_vector(dir)?[dir]:dir) _gear_direction_angle(v)];
    assert(is_undef(dir) || is_list(dir), "\ndir must be a direction vector or a list of direction vectors");
    phases = _gear_child_phase_values(phase,len(placements));
    for(i=[0:1:len(placements)-1])
        let($idx=i,$ang=israck?undef:placements[i],$pos=israck?placements[i]:pos,
            $_gear_attach_request=[israck?undef:placements[i],israck?placements[i]:pos,
                                   rack_inset,crown_pos,shift,worm_face_pos,phases[i]])
            children();
}
function _gear_child_phase_values(phase,n) =
    is_undef(phase) || is_finite(phase) ? [for(i=[0:1:n-1]) phase] :
    assert(is_list(phase) && len(phase)==n &&
           len([for(p=phase) if(!is_finite(p)) 1])==0,
           str("\nphase must be a finite number or a list of ",n,
               " finite numbers matching the placements")) phase;
function _gear_placement_values(v,name) =
    assert(is_finite(v) || (is_list(v) && len([for(x=v) if(!is_finite(x)) 1])==0),
           str("\n",name," must be a finite number or a list of finite numbers"))
    is_list(v)?v:[v];
function _gear_direction_angle(v) =
    assert(is_vector(v) && (len(v)==2 || len(v)==3) && norm(v)>0,
           "\ndir must contain nonzero 2D or 3D direction vectors")
    assert(len(v)==2 || abs(v.z)<=1e-10*norm(v), "\ndir must lie in the parent's local XY plane")
    atan2(v.y,v.x);
/// Resolved physical data; family_data supplies family-specific geometry and attachment data.
/// [type, module, teeth, PA, helix, face thickness, shift, worm_diameter,
/// starts, worm_length, hand, clearance, internal, herringbone, two_d, auto_shift,
/// family_data]. Rack data: [length]. Crown data:
/// [face_width, mate_teeth, mate_profile_shift, mate_clearance, bottom_z, top_z]. Bevel data:
/// [mate_teeth, shaft_angle, face_width, spiral, cutter_radius, left_handed,
/// apex_z, pitchbase_z]. The auto flag is private diagnostic provenance.
/// Worm data: [lead_in, full_height_min, full_height_max].
/// Worm-face data: [generator_parameters, bottom_z, top_z].
function _gear_spec(type,m,teeth,pa,helical=0,thickness=undef,shift=0,
                    worm_diam=undef,starts=undef,worm_length=undef,left_handed=false,
                    clearance=0,internal=false,herringbone=false,two_d=false,shift_auto=false,
                    family_data=[]) =
    [type,m,teeth,pa,helical,thickness,shift,worm_diam,starts,worm_length,
     left_handed,clearance,internal,herringbone,two_d,shift_auto,family_data];
function _gear_is_circular(t) = in_list(t,["spur","spur2D","ring","ring2D"]);
function _gear_is_rack(t) = t=="rack" || t=="rack2D";
function _gear_is_worm(t) = t=="worm" || t=="globoid_worm";
function _gear_is_wheel(t) = t=="worm_gear" || t=="globoid_worm_gear" || t=="worm_face";
function _gear_worm_family(t) = in_list(t,["worm","worm_gear","worm_face"]) ? 1 :
                              in_list(t,["globoid_worm","globoid_worm_gear"]) ? 2 : 0;
function _gear_same_number(a,b) = is_finite(a) && is_finite(b) && abs(a-b)<=1e-9*max(1,abs(a),abs(b));
function _gear_same_pa(a,b) =
    let(x=is_list(a)?a:[a,a],y=is_list(b)?b:[b,b])
    len(x)==2 && len(y)==2 && _gear_same_number(x[0],y[0]) && _gear_same_number(x[1],y[1]);
function _gear_axial_length(S) = _gear_is_worm(S[0]) ? S[9] : default(S[5],0);
function _gear_axes_in(M,axes) =
    let(R=[for(i=[0:2])[for(j=[0:2])M[i][j]]])
    [for(a=axes) is_undef(a)?undef:R*a];
function _gear_vector_in(M,v) = is_undef(v)?undef:
    [for(i=[0:2]) [for(j=[0:2])M[i][j]]]*v;
/// Under automatic 3D rack attachment, TOP/BOT mean pinion-style face alignment.
/// The canonical rack coordinates still use FWD/BACK; keep X for end selection.
function _gear_rack_anchor(anchor) =
    assert(is_vector(anchor,3) && in_list(anchor.x,[-1,0,1]) &&
           in_list(anchor.y,[-1,0,1]) && in_list(anchor.z,[-1,0,1]),
           "\nAn attached rack needs a CENTER/LEFT/RIGHT anchor with one face selection")
    assert(anchor.y==0 || anchor.z==0,
           "\nChoose either TOP/BOT or FWD/BACK for rack face alignment, not both")
    [anchor.x,anchor.y-anchor.z,0];
function _gear_anchor_transform(S,anchor) =
    S[0]=="worm_face" ?
        let(z=anchor=="pitchplane"?0:(S[16][1]+S[16][2])/2+anchor.z*S[5]/2)
        move([0,0,-z]) :
    S[0]=="bevel" ?
        assert(in_list(anchor,[CENTER,"pitchbase","apex"]),
               "\nAn automatically meshed bevel accepts CENTER, pitchbase, or apex")
        move([0,0,anchor=="apex"?-S[16][6]:anchor=="pitchbase"?-S[16][7]:0]) :
    _gear_is_rack(S[0]) ?
        // Rack side/corner anchors include the existing sheared end correction.
        // The mating reference is its pitch-line origin, not its bounding box.
        move([-anchor.x*S[16][0]/2 +
                  (!S[14] && anchor.x!=0 ? sin(S[4])*S[5]/2*anchor.y : 0),
              S[14]?0:-anchor.y*S[5]/2,0]) :
    move(-anchor*_gear_axial_length(S)/2);
/// Canonical rotary reference supplied by a rack-rooted branch. A saved rack
/// reference is a pure orientation matrix; translations remain native rack travel.
function _gear_rack_frame(S) = S[14] ? ident(4) : xrot(90);
function _gear_rotation_matrix(M) =
    [for(i=[0:3]) [for(j=[0:3]) i==3 || j==3 ? (i==j?1:0) : M[i][j]]];
/// Pose = [placement, local body spin, angular displacement, tooth phase,
/// angular gain, contact, ancestor locations, ancestor axes, child transform,
/// travel, tooth travel, linear gain, local body travel, full local motion,
/// root input kind, automatic-chain flag, optional rack rotary reference, optional outgoing frame phase]. The flag distinguishes driven motion
/// from a manual gear_spin/gear_travel even at zero displacement.
/// Angular and linear gains use degrees or length per unit of the root input.
/// Direct children keep their own tooth offsets. Only a frame established by
/// attach_gear() supplies inherited motion; parallel shaft/slide axes retain its
/// scalar gains while tilted compounds retain the carried coordinate frame.
// Append provenance after family-specific pose calculations. This is not a
// physical transform and does not change legacy public motion or histories.
function _gear_pose(S,phase=0,anchor=CENTER,spin=0,orient=UP,travel=0,geom) =
    let(p=is_undef($_gear_shaft_motion) ? _gear_pose_impl(S,phase,anchor,spin,orient,travel,geom) :
          _gear_shaft_root_pose(S,phase,anchor,spin,orient,travel),
        // A constructor reorientation establishes a different mounting reference.
        // Captured pre-gear motion belongs to the drive's axes, not these new axes.
        remount=is_undef($_gear_parent_spec) && !is_undef($_gear_driver) &&
                (default(spin,0)!=0 || default(orient,UP)!=UP),
        mount=is_undef($_gear_mount_id) || remount?function() 0:$_gear_mount_id,
        aligned=default($_gear_motion_plane_ok,true) &&
            (is_undef($_gear_parent_spec) || !is_undef($_gear_attach_request) ||
             _gear_motion_stack_ok(S,anchor,spin,orient,geom)))
    concat([for(i=[0:18]) i<len(p)?p[i]:i==17?0:undef],[[mount,$_gear_drive_id,aligned]]);
function _gear_motion_stack_ok(S,anchor,spin,orient,geom) =
    !_gear_is_circular(S[0]) || default(spin,0)!=0 || default(orient,UP)!=UP ? false :
    let(B=_gear_parent_attachment(),
        C=is_undef(geom)?_gear_anchor_transform(S,default(anchor,CENTER)):
          _attach_transform(default(anchor,CENTER),0,UP,_change_anchors(geom)), D=B*C)
    norm([D[0][3],D[1][3]])<1e-9;
function _gear_pose_impl(S,phase=0,anchor=CENTER,spin=0,orient=UP,travel=0,geom) =
    assert(is_finite(phase), "\ngear_spin must be finite")
    assert(is_finite(travel), "\ngear_travel must be finite")
    let(rack=_gear_is_rack(S[0]),driven=!is_undef($_gear_driver),
        q=driven?$_gear_driver[1]:0)
    assert(!driven || ($_gear_driver[0]=="travel")==rack,
           str("\n",rack?"Use gear_travel() to drive a rack":"Use gear_spin() to drive a rotary gear"))
    is_undef($_gear_parent_spec) ?
        let(motion=rack?0:q,slide=rack?q:0,
            full=rack?right(slide):zrot(motion))
        [ident(4),phase+motion,motion,rack?0:phase+motion,driven&&!rack?1:0,
         undef,[[0,0,0]],[rack?undef:UP],full,slide,slide+travel,driven&&rack?1:0,
         slide+travel,full,driven?$_gear_driver[0]:undef,driven,rack?_gear_rack_frame(S):undef] :
    let(mate=!is_undef($_gear_attach_request),
        anchor=mate && S[0]=="rack" ? _gear_rack_anchor(default(anchor,CENTER)) : default(anchor,CENTER),
        spin=default(spin,0),orient=default(orient,UP))
    !mate && !is_undef($_gear_carrier_parent) ?
        let($_gear_carrier=undef,$_gear_carrier_parent=undef)
            _gear_carrier_output_pose(S,phase,anchor,spin,orient,travel,geom) :
    mate ?
        assert(spin==0 && orient==UP,
               "\nUse spin and orient on the root or a direct child; attach_gear() sets its mate's shaft orientation")
        _gear_child_frame(S,
            _gear_mate_pose($_gear_parent_spec,S,$_gear_attach_request,phase,anchor,travel),
            len($_gear_attach_request)>6?$_gear_attach_request[6]:undef) :
        _gear_compound_pose(S,phase,anchor,spin,orient,travel,geom);
/// The outer part of plain BOSL2 attach(), or align() without extra offsets.
/// No general transform tracking is enabled. Constructor anchor/spin/orient are
/// resolved below by the same _attach_transform() used by attachable().
function _gear_parent_attachment() =
    !is_undef($attach_to) ?
        move($attach_anchor[1]) * rot($attach_anchor[3],
            from=$_gear_parent_spec[14]?BACK:UP,to=$attach_anchor[2]) :
    !is_undef($attach_alignment) ? move($attach_anchor[1]) : ident(4);
/// Ordinary nesting does not copy tooth phase or add a physical transform.
/// An explicitly selected outgoing frame is already outside the child;
/// retain its phase for coaxial pose bookkeeping even without a mechanical drive.
/// A driven parent's rotation/translation is already outside its children.
/// Re-express that motion only when it is about the child's own shaft/slide;
/// an offset or tilted child otherwise stays in the inherited moving frame.
/// A manual child keeps its local offsets; a drive module supplies physical input.
function _gear_compound_pose(S,phase,anchor,spin,orient,travel,geom) =
    let(rack=_gear_is_rack(S[0]),prack=_gear_is_rack($_gear_parent_spec[0]),
        B=_gear_parent_attachment(),
        C=is_undef(geom) ? rot(spin,from=UP,to=orient)*_gear_anchor_transform(S,anchor) :
          _attach_transform(anchor,spin,is_undef($anchor_override)?orient:UP,_change_anchors(geom)),
        D=B*C,active=$_gear_chain_active,driven=!is_undef($_gear_driver),
        q=driven?$_gear_driver[1]:0,
        axis=_gear_vector_in(D,UP),length_axis=_gear_vector_in(D,RIGHT),
        parallel=!rack && !prack && norm(cross(axis,UP))<1e-9 &&
                 norm(cross(point3d([D[0][3],D[1][3],D[2][3]]),UP))<1e-9,
        sliding=rack && prack && norm(cross(length_axis,RIGHT))<1e-9,
        sense=parallel?sign(axis.z):sliding?sign(length_axis.x):1,
        motion=driven ? (rack?0:q) : active&&parallel?sense*$gear_rotation:0,
        slide=driven ? (rack?q:0) : active&&sliding?sense*$gear_travel:0,
        frame_phase=parallel?sense*default($_gear_frame_phase,0):0,
        support=_gear_carrier_motion(),
        actual=motion+frame_phase+phase,travel_phase=slide+travel,
        gain=driven ? (rack?0:1) : active&&parallel?sense*$gear_ratio:0,
        linear_gain=driven ? (rack?1:0) : active&&sliding?sense*$gear_travel_ratio:0,
        full=driven ? (rack?right(slide):zrot(motion+frame_phase)) :
             parallel?zrot(motion-support+frame_phase):active&&sliding?right(slide):ident(4),
        // The inherited frame phase is physically present already. Add only new drive motion.
        childmotion=driven?(rack?right(slide):zrot(motion)):ident(4),
        inv=rot_inverse(D*childmotion),contact=_gear_vector_in(inv,$gear_contact_dir),
        // A same-plane compound rack retains the reference. A reoriented rack
        // establishes its own canonical reference, like a rack at the chain root.
        rackref=rack && prack && !is_undef($_gear_rack_reference) ?
                    rot_inverse(_gear_rotation_matrix(D))*$_gear_rack_reference :
                    rack?_gear_rack_frame(S):undef)
    assert(is_undef($_gear_carrier) ||
           (_gear_is_circular(S[0]) && parallel && sense==1 && spin==0 && orient==UP),
           "\nA rigid gear inside a carrier frame must be coaxial, parallel, and unrotated; use its local gear_spin for tooth indexing")
    _gear_carrier_pose([ident(4),phase+(driven?motion:0),motion,actual,gain,contact,
     concat(apply(inv,$gear_chain_locs),[[0,0,0]]),
     concat(_gear_axes_in(inv,$gear_chain_axes),[rack?undef:UP]),childmotion,
     slide,travel_phase,linear_gain,travel+(driven?slide:0),full,
     driven?$_gear_driver[0]:$gear_input,active||driven,rackref,frame_phase]);

// Only an ordinary, coaxial gear immediately inside the frame is an output
// member. It inherits carrier motion, then starts stationary-axis mating again.
function _gear_carrier_output_pose(S,phase,anchor,spin,orient,travel,geom) =
    let(B=_gear_parent_attachment(),
        C=is_undef(geom) ? rot(spin,from=UP,to=orient)*_gear_anchor_transform(S,anchor) :
          _attach_transform(anchor,spin,is_undef($anchor_override)?orient:UP,_change_anchors(geom)),
        D=B*C)
    assert(_gear_is_circular(S[0]) && spin==0 && orient==UP &&
           norm(cross(_gear_vector_in(D,UP),UP))<1e-9 &&
           _gear_vector_in(D,UP).z>0 && abs(D[0][3])+abs(D[1][3])<1e-9,
           "\nA carrier output gear must be a coaxial spur or ring with parallel axes; use only axial placement")
    _gear_compound_pose(S,phase,anchor,spin,orient,travel,geom);

function _gear_carrier_motion() = is_undef($_gear_carrier)?0:$_gear_carrier[0];
function _gear_carrier_gain() = is_undef($_gear_carrier)?0:$_gear_carrier[1];
function _gear_mesh_rotation() = !is_undef($_gear_carrier_parent)?$_gear_carrier_parent[0]:
                               $gear_rotation-_gear_carrier_motion();
function _gear_mesh_tooth_angle() = !is_undef($_gear_carrier_parent)?$_gear_carrier_parent[1]:
                                  $_gear_tooth_angle-_gear_carrier_motion();
function _gear_mesh_gain() = !is_undef($_gear_carrier_parent)?$_gear_carrier_parent[2]:
                           $gear_ratio-_gear_carrier_gain();
function _gear_carrier_pose(pose) = is_undef($_gear_carrier) ? pose :
    concat([for(i=[0:17]) i<len(pose)?pose[i]:i==17?0:undef],[$_gear_carrier]);

// Change only the outgoing ordinary-child frame, not the attached gear's body or mesh.
// The requested zero-drive angle is absolute in the gear's stationary assembly reference.
// Store the scalar angle as pose[17] for coaxial propagation; pose[13] carries
// the full frame transform that subsequent automatic mates cancel.
function _gear_child_frame(S,pose,phase) =
    is_undef(phase) ? pose :
    assert(!_gear_is_rack(S[0]),"\nphase requires a rotary attached gear, not a rack")
    assert(is_finite(phase),"\nphase must be finite")
    let(F=zrot(phase),inv=zrot(-phase))
    [for(i=[0:max(17,len(pose)-1)])
        i==5?_gear_vector_in(inv,pose[5]):
        i==6?apply(inv,pose[6]):
        i==7?_gear_axes_in(inv,pose[7]):
        i==8?pose[8]*F:
        i==13?pose[13]*F:
        i==17?phase:
        i<len(pose)?pose[i]:undef];

function _gear_mate_pose(A,B,request,offset,anchor,travel=0) =
    assert(is_undef($_gear_carrier) ||
           (_gear_is_circular(A[0]) && _gear_is_circular(B[0]) && abs(A[4]+B[4])<1e-9),
           "\nAutomatic mating inside a carrier frame requires parallel-axis spur or ring gears")
    let(reverse_face=A[0]=="worm" && B[0]=="worm_face" && len(request)>5 && request[5]==LEFT)
    assert(len(request)<6 || is_undef(request[5]) || (A[0]=="worm" && B[0]=="worm_face"),
           "\nworm_face_pos is only used when a cylindrical worm parent receives a worm-face child")
    assert(is_undef(request[1]) || _gear_is_rack(A[0]),
           "\npos is only supported for placement along a parent rack; use shift for axial gear placement")
    assert(_gear_same_number(A[1],B[1]),
           str("\nMeshing gears must have the same normal module; parent=",A[1],", child=",B[1]))
    assert(_gear_same_pa(A[3],reverse_face?_worm_swap_angles(B[3]):B[3]),
           reverse_face ? str("\nworm_face_pos=LEFT requires face-gear pressure_angle=",_worm_swap_angles(A[3]),
                              ". Let the face gear inherit pressure_angle, or set this reversed pair explicitly.") :
           str("\nMeshing gears must have matching pressure_angle; parent=",A[3],", child=",B[3]))
    assert(is_undef(request[2]) || (_gear_is_rack(B[0]) && is_vector(anchor,3) && abs(anchor.x)==1),
           "\nrack_inset is only used for a child rack anchored LEFT or RIGHT (optionally with FWD or BACK)")
    assert(len(request)<5 || is_undef(request[4]) ||
           (!A[14] && !B[14] &&
            ((_gear_is_circular(A[0]) && _gear_is_circular(B[0]) && abs(A[4]+B[4])<1e-9) ||
             (_gear_is_rack(A[0]) && _gear_is_circular(B[0])) ||
             (_gear_is_rack(B[0]) && _gear_is_circular(A[0])) ||
             (A[0]=="crown" && _gear_is_circular(B[0])) ||
             (B[0]=="crown" && _gear_is_circular(A[0])) ||
             (A[0]=="worm" && in_list(B[0],["worm_gear","worm_face"])) ||
             (B[0]=="worm" && in_list(A[0],["worm_gear","worm_face"])))),
           "\nshift is only supported for parallel-axis 3D spur/ring, supported 3D rack/pinion, crown/spur, or cylindrical worm pairs; not globoid pairs")
    assert(is_undef(request[3]) || (_gear_is_circular(A[0]) && !A[12] && B[0]=="crown"),
           "\ncrown_pos is only used when a spur parent receives a crown child")
    _gear_is_circular(A[0]) && _gear_is_circular(B[0]) ?
        assert(in_list(anchor,[CENTER,BOT,TOP]) && (!B[14] || anchor==CENTER),
               "\nA meshing spur/ring child accepts CENTER, BOT, or TOP (CENTER for 2D)")
        _gear_circular_pose(A,B,request[0],offset,anchor,
                            len(request)>4?default(request[4],0):0) :
    (_gear_is_rack(A[0]) && _gear_is_circular(B[0]) ||
     _gear_is_rack(B[0]) && _gear_is_circular(A[0])) ?
        _gear_rack_pose(A,B,request,offset,anchor,travel) :
    A[0]=="bevel" && B[0]=="bevel" ? _gear_bevel_pose(A,B,request[0],offset,anchor) :
    (A[0]=="crown" && _gear_is_circular(B[0]) ||
     B[0]=="crown" && _gear_is_circular(A[0])) ?
        _gear_crown_pose(A,B,request[0],offset,anchor,default(request[3],DOWN),
                         len(request)>4?default(request[4],0):0) :
    (A[0]=="worm" && B[0]=="worm_face" || B[0]=="worm" && A[0]=="worm_face") ?
        _gear_worm_face_pose(A,B,request[0],len(request)>4?default(request[4],0):0,offset,anchor,
                             len(request)>5?default(request[5],RIGHT):RIGHT) :
    _gear_worm_family(A[0])>0 && _gear_worm_family(A[0])==_gear_worm_family(B[0]) &&
        (_gear_is_worm(A[0]) && _gear_is_wheel(B[0]) || _gear_is_wheel(A[0]) && _gear_is_worm(B[0])) ?
        assert(anchor==CENTER,"\nAutomatically meshed worm pairs require anchor=CENTER on the child")
        _gear_worm_pose(A,B,request[0],offset,len(request)>4?default(request[4],0):0) :
    assert(false,str("\nUnsupported attach_gear() pair: ",A[0]," -> ",B[0],
                     ". Use a supported matching gear family.")) undef;
/// The stationary placement T includes the initial rack phase translation, but
/// never modulo-reduces mechanical motion. The same inverse rigid transform
/// converts location histories and cancels only motion actually applied above.

function _gear_finish_rotary(T,motion,actual,gain,contact,C=ident(4)) =
    let(relative=rot_inverse($_gear_frame_motion)*T,full=zrot(motion),
        inv=rot_inverse(relative*full),d=_gear_vector_in(rot_inverse(full),contact))
    _gear_carrier_pose([relative*rot_inverse(C),actual,
     motion+_gear_carrier_motion(),actual+_gear_carrier_motion(),gain+_gear_carrier_gain(),d,
     concat(apply(inv,$gear_chain_locs),[[0,0,0]]),
     concat(_gear_axes_in(inv,$gear_chain_axes),[UP]),full,
     0,0,0,0,full,$gear_input,$_gear_chain_active]);

function _gear_finish_pose(T,slope,phase,offset,period,contact,C=ident(4)) =
    let(p=phase-period*round(phase/period)+offset)
    _gear_finish_rotary(T,slope*_gear_mesh_rotation(),slope*_gear_mesh_tooth_angle()+p,
                       slope*_gear_mesh_gain(),contact,C);

function _gear_finish_linear(T,motion,offset,gain,contact,C=ident(4),rack_reference=undef) =
    let(relative=rot_inverse($_gear_frame_motion)*T,full=right(motion),
        inv=rot_inverse(relative*full))
    [relative*rot_inverse(C),0,0,0,0,contact,
     concat(apply(inv,$gear_chain_locs),[[0,0,0]]),
     concat(_gear_axes_in(inv,$gear_chain_axes),[undef]),full,
     motion,motion+offset,gain,motion+offset,full,$gear_input,$_gear_chain_active,rack_reference];

/// Existing circular and worm pair equations retain their geometry and phase conventions.
function _gear_circular_pose(A,B,angle,offset,anchor=CENTER,shift=0) =
    assert(A[14]==B[14], "\nBoth meshing spur/ring gears must have the same dimensionality")
    assert(!(A[12] && B[12]), "\nTwo internal gears cannot be directly meshed")
    let(parallel=abs(A[4]+B[4])<1e-9,inside=A[12]||B[12],
        ratio=A[2]/B[2],u=[cos(angle),sin(angle),0],
        dz=anchor.z*(default(A[5],0)-default(B[5],0))/2+shift)
    assert(parallel || !(inside||A[13]||B[13]||A[14]),
           "\nInternal, herringbone, and 2D gear pairs require opposite helix angles and parallel axes")
    assert(A[4]==0 || A[13]==B[13], "\nA helical herringbone gear requires a herringbone mate")
    assert(parallel || anchor==CENTER,
           "\nCrossed-axis attach_gear() requires anchor=CENTER on the child")
    assert(!A[13] || A[4]==0 || abs(dz)<1e-10,
           "\nHelical herringbone mates must share their middle plane; revise anchor and shift")
    let(ring=A[12]?A:B,spur=A[12]?B:A)
    assert(!inside || ring[6]+1e-12>=spur[6],
           str("\nRing gear profile_shift=",ring[6]," is less than the mating spur gear shift=",spur[6],". ",
               spur[15]?str("Automatic profile shifting selected ",spur[6]," for the ",spur[2],"-tooth external gear. "):"",
               "Specify at least ",spur[6]," on the ring gear."))
    let(a=parallel ? gear_dist(mod=A[1],teeth1=A[2],teeth2=B[2],helical=A[4],
                              profile_shift1=A[6],profile_shift2=B[6],pressure_angle=A[3],
                              internal1=A[12],internal2=B[12]) :
                        gear_dist_skew(mod=A[1],teeth1=A[2],teeth2=B[2],helical1=A[4],helical2=B[4],
                                       profile_shift1=A[6],profile_shift2=B[6],pressure_angle=A[3]),
        skew=parallel?0:gear_skew_angle(teeth1=A[2],teeth2=B[2],helical1=A[4],helical2=B[4],
                                       profile_shift1=A[6],profile_shift2=B[6],pressure_angle=A[3]),
        R=skew==0?ident(4):rot(a=skew,v=u),
        slope=inside?ratio:-ratio,
        base=A[12]?(1-ratio)*(angle-90): B[12]?(1-ratio)*(angle+90):
                    angle+90+ratio*(angle-90)-180/B[2],
        // Ring geometry reverses the helix extrusion. Compensate phase for
        // a shifted axial origin; working tooth position then agrees at all z.
        advance=(B[12]?1:-1)*tan(B[4])/pitch_radius(mod=B[1],teeth=B[2],helical=B[4])*180/PI,
        phase=base+advance*dz,
        incoming=A[12]?u:-u,
        C=move(-anchor*default(B[5],0)/2))
    _gear_finish_pose(move(a*u+[0,0,dz])*R,slope,phase,offset,360/B[2],incoming,C);

function _gear_worm_pose(A,B,angle,offset,shift=0) =
    let(pworm=_gear_is_worm(A[0]),W=pworm?A:B,G=pworm?B:A,
        globoid=_gear_worm_family(W[0])==2,
        hand=W[10]?-1:1,u=[cos(angle),sin(angle),0])
    assert(!globoid || shift==0,"\nshift is not supported for globoid worm pairs")
    assert(_gear_same_number(W[7],G[7]),str("\nWorm diameter mismatch: parent=",A[7],", child=",B[7]))
    assert(W[8]==G[8],str("\nWorm starts mismatch: parent=",A[8],", child=",B[8]))
    assert(W[10]==G[10], "\nWorm and wheel must use the same left_handed value")
    assert(!globoid || W[2]==G[2],str("\nGloboid worm was made for ",W[2]," wheel teeth, not ",G[2]))
    assert(!globoid || _gear_same_number(W[9],G[9]),
           str("\nGloboid worm_length mismatch: parent=",A[9],", child=",B[9]))
    assert(!globoid || _gear_same_number(W[11],G[11]),
           str("\nMatched globoid geometry requires the same clearance; parent=",A[11],", child=",B[11]))
    let(a=globoid?globoid_worm_dist(mod=W[1],teeth=G[2],worm_diam=W[7],worm_starts=W[8]):
                    worm_dist(mod=W[1],teeth=G[2],worm_diam=W[7],worm_starts=W[8],
                              pressure_angle=G[3],profile_shift=G[6]),
        delta=pworm?angle+90:angle-90,
        R=zrot(angle)*xrot(90),
        slope=hand*(pworm?W[8]/G[2]:G[2]/W[8]),
        // Axial pitch differs from normal circular pitch by the lead-angle cosine.
        // A shifted worm needs a screw rotation; a shifted wheel needs the
        // corresponding wheel phase, with the start count included in the ratio.
        turn=shift==0?0:360*shift*cos(asin(W[8]*W[1]/W[7]))/(PI*W[1]),
        phase=-slope*delta+(pworm?90:-90)+(pworm?turn/G[2]:hand*turn/W[8]),
        slide=pworm?[0,0,shift]:_gear_vector_in(R,[0,0,shift]))
    // X+ points away from the parent shaft; Y+ follows the parent's Z+.
    // The compensating quarter-turn preserves the physical meshing geometry.
    _gear_finish_pose(move(a*u+slide)*R,slope,phase,offset,
                      360/(pworm?G[2]:W[8]),LEFT);

/// Normalize phase at integer-pitch boundaries before selecting a finite rack
/// tooth. Floating-point remainder can otherwise return p instead of zero.
function _gear_pitch_remainder(x,p) =
  let(v=x/p,rem=v-floor(v)) rem<1e-10 || rem>1-1e-10 ? 0 : p*rem;

/// A rack's local +X is its length; teeth face +Y in 2D and +Z in 3D.
/// In 3D the automatic pinion axis points along rack -Y. In either dimension
/// positive pinion spin advances the rack toward its own +X.
function _gear_rack_pose(A,B,Q,offset,anchor,travel) =
    let(prack=_gear_is_rack(A[0]),K=prack?B:A,R=prack?A:B,
        p=PI*R[1]/cos(R[4]),k=K[2]*p/360,
        valley=R[2]%2==0?0:p/2,
        parallel=abs(R[4]+(R[13]?-1:1)*K[4])<1e-9,
        skew=parallel?0:R[4]+K[4])
    assert(!K[12],"\nA rack needs an external pinion, not a ring gear")
    assert(A[14]==B[14],"\nA rack and pinion must have the same dimensionality")
    assert(parallel || (!R[14] && !R[13] && !K[13]),
           "\nSkew rack attachment requires ordinary 3D helical gears, not 2D or herringbone gears")
    assert(parallel || (default(Q[4],0)==0 &&
                         (prack ? anchor==CENTER : in_list(anchor,[CENTER,LEFT,RIGHT]))),
           str("\nSkew rack attachment requires centered face-width alignment and shift=0. ",
               prack ? "Use anchor=CENTER on the pinion." :
                       "Use anchor=CENTER, LEFT, or RIGHT on the rack."))
    assert(R[4]==0 || R[13]==K[13],"\nA herringbone rack needs a herringbone pinion")
    assert(prack ? (R[14]?anchor==CENTER:in_list(anchor,[CENTER,TOP,BOT])) :
           (is_vector(anchor,3) && anchor.z==0 && in_list(anchor.x,[-1,0,1]) &&
            (R[14]?anchor.y==0:in_list(anchor.y,[-1,0,1]))),
           str("\n",prack?"A pinion attached to a rack accepts CENTER, TOP, or BOT (CENTER in 2D)":
                 "An attached rack accepts CENTER, LEFT, or RIGHT; in 3D combine with FWD or BACK for face alignment"))
    let(a=parallel ? gear_dist(mod=K[1],teeth1=K[2],teeth2=0,helical=K[4],
                   profile_shift1=K[6],profile_shift2=R[6],pressure_angle=K[3]) :
                   gear_dist_skew(mod=K[1],teeth1=K[2],teeth2=0,helical1=K[4],helical2=R[4],
                   profile_shift1=K[6],profile_shift2=R[6],pressure_angle=K[3]),
        // shift translates the CHILD along the pinion's +Z in either order.
        // A rack has no shaft; its +Y points opposite this direction.
        shift=len(Q)>4?default(Q[4],0):0,
        dz=R[14]?0:(prack?anchor.z:anchor.y)*(R[5]-K[5])/2+shift)
    assert(R[4]==0 || !R[13] || abs(dz)<1e-10,
           "\nHelical herringbone rack mates must share their width middle plane; revise anchor and shift")
    prack ?
        let(x=Q[1],native=_gear_rack_frame(R),
            saved=default($_gear_rack_reference,native),
            // Preserve roll only when the saved shaft is the same directed
            // shaft as this rack's canonical pinion. A skew mesh starts afresh.
            same_axis=norm(_gear_vector_in(saved,UP)-_gear_vector_in(native,UP))<1e-9,
            M=parallel && same_axis ? saved : zrot(skew)*native,
            local_x=_gear_vector_in(rot_inverse(native)*M,RIGHT),
            roll=parallel && same_axis ? atan2(local_x.y,local_x.x) : 0,
            T=move(R[14]?[x,a,0]:[x,-dz,a])*M,
            advance=-tan(K[4])/pitch_radius(mod=K[1],teeth=K[2],helical=K[4])*180/PI,
            base=(valley-x)/k-180+advance*dz,
            initial=base-360/K[2]*round(base/(360/K[2])),
            motion=$gear_travel/k,
            actual=$_gear_tooth_travel/k+initial+offset-roll)
        _gear_finish_rotary(T,motion,actual,$gear_travel_ratio/k,zrot(-roll,p=FRONT),
                           _gear_anchor_transform(K,anchor)) :
        let(angle=Q[0],u=[cos(angle),sin(angle),0],
            M=zrot(angle+90)*(R[14]?ident(4):xrot(-90)*zrot(-skew)),
            zero=$_gear_tooth_angle-$gear_rotation,
            raw=k*(zero-angle+90)-valley+dz*tan(R[4]),
            s0=_gear_pitch_remainder(raw+p/2,p)-p/2,L=R[16][0],inset=default(Q[2],1),
            delta=anchor.x<0?_gear_pitch_remainder(-raw+L/2,p):_gear_pitch_remainder(L/2+raw,p),
            inset_dist=delta+inset*p,
            s=anchor.x==0?s0:anchor.x<0?L/2-inset_dist:-L/2+inset_dist)
        assert(anchor.x==0 || inset_dist<L,
               str("\nrack_inset=",inset," leaves no phase-compatible position on this ",R[2],
                   "-tooth rack. Reduce rack_inset, lengthen the rack, or use anchor=CENTER."))
        _gear_finish_linear(move(a*u+[0,0,dz])*M*right(s),k*$gear_rotation,travel,
                            k*$gear_ratio,R[14]?BACK:UP,_gear_anchor_transform(R,anchor),
                            parallel?rot_inverse(M):_gear_rack_frame(R));
/// Crown-parent placement has one canonical orientation: the spur's +Z points
/// radially outward. For a crown child, crown_pos selects its center on the
/// spur's +Z/-Z side without changing the selected circumferential contact.
/// shift translates the child along the spur's Z+ in either attachment order.
/// Straight teeth need no phase adjustment when sliding along their shaft.
function _gear_crown_pose(A,B,angle,offset,anchor,crown_pos,shift=0) =
    let(pc=A[0]=="crown",C=pc?A:B,G=pc?B:A,
        u=[cos(angle),sin(angle),0],r=pitch_radius(mod=C[1],teeth=C[2])+C[16][0]/2,
        d=gear_dist(mod=G[1],teeth1=G[2],teeth2=0,helical=0,
                    profile_shift1=G[6],profile_shift2=C[6],pressure_angle=G[3]))
    assert(!G[12] && !G[14],"\nA crown gear needs a three-dimensional external spur gear")
    assert(G[4]==0,"\nCrown attachment supports straight spur teeth only; use helical=0")
    assert(G[2]==C[16][1],str("\nCrown was generated for mate_teeth=",C[16][1],"; the pinion has ",G[2]," teeth"))
    assert(_gear_same_number(G[6],C[16][2]),"\nPinion profile_shift must match the crown's mate_profile_shift")
    assert(_gear_same_number(G[11],C[16][3]),"\nPinion clearance must match the crown's mate_clearance")
    assert(anchor==CENTER || (!pc && anchor=="pitchplane"),"\nCrown/spur attachment requires CENTER; a crown child also accepts pitchplane")
    pc ?
        let(k=C[2]/G[2],M=zrot(angle-90)*xrot(-90))
        _gear_finish_pose(move((r+shift)*u+[0,0,d])*M,k,-k*(angle-90)+180/G[2],offset,360/G[2],BACK) :
        let(s=crown_pos.z,k=-s*G[2]/C[2],
            M=zrot(angle-90)*xrot(90)*zrot(s>0?180:0))
        _gear_finish_pose(move(d*u+[0,0,s*r+shift])*M,k,-k*(angle-90)+180/C[2],offset,360/C[2],BACK);
/// The child shaft is tilted away from the selected contact azimuth. Signed
/// cone heights cover external, flat, and internal-like bevel pitch surfaces.
/// Its reference Y+ is the projection of the parent Z+ onto its transverse plane.
/// Coincide the actual apex anchors so backing changes do not change the mesh.
function _gear_bevel_pose(A,B,angle,offset,anchor) =
    let(a=A[16],b=B[16],u=[cos(angle),sin(angle),0],
        da=bevel_pitch_angle(A[2],a[0],a[1]),db=bevel_pitch_angle(B[2],b[0],b[1]))
    assert(a[0]==B[2] && b[0]==A[2],
           str("\nBevel mate_teeth must be reciprocal; parent expects ",a[0],
               " teeth and child has ",B[2],"; child expects ",b[0]," and parent has ",A[2]))
    assert(_gear_same_number(a[1],b[1]),"\nBevel gears must use the same shaft_angle")
    assert(anchor=="pitchbase",
           "\nAn automatically meshed bevel uses anchor=\"pitchbase\"; omit the child anchor")
    assert(_gear_same_number(a[2],b[2]) && _gear_same_number(a[3],b[3]) && _gear_same_number(a[4],b[4]),
           "\nMatched bevel attachment requires the same face_width, spiral, and cutter_radius")
    assert(a[5]!=b[5],"\nMatched bevel gears must have opposite handedness")
    assert(_gear_same_number(A[6],-B[6]),"\nMatched bevel gears must have opposite profile_shift values")
    let(M=rot(a=-a[1],v=cross(UP,u))*zrot(angle-90),
        T=up(a[6])*M*down(b[6]),ratio=A[2]/B[2],
        phase=180+ratio*(angle-90)-180/B[2])
    // Y+ is the projected parent Z+; X is normal to the shaft plane.
    // The removed frame roll is added to tooth phase, keeping the mesh fixed.
    _gear_finish_pose(T,-ratio,phase,offset,360/B[2],FWD,_gear_anchor_transform(B,anchor));
/// Generating calls do not inherit pending mating or the outer mechanical frame.
/// BOSL2's attach() context is deliberately kept for supported compound stacking.
module _gear_place(pose) {
    multmatrix(pose[0])
    let($_gear_attach_request=undef,$_gear_parent_spec=undef,$_gear_driver=undef,
        $_gear_shaft_motion=undef,
        $_gear_frame_motion=ident(4),$_gear_frame_phase=0,
        $_gear_carrier=undef,$_gear_carrier_parent=undef,
        $_gear_chain_active=false,$_gear_rack_reference=undef,
        $parent_gear_type=undef,$parent_gear_mod=undef,
        $parent_gear_teeth=undef,$parent_gear_pa=undef,$parent_gear_helical=undef,
        $parent_gear_thickness=undef,$parent_gear_face_width=undef,$parent_gear_shaft_offset=undef,$_gear_worm_face_data=undef,$parent_gear_worm_diam=undef,
        $parent_gear_starts=undef,$parent_gear_worm_length=undef,$worm_length=undef,
        $parent_gear_wheel_teeth=undef,$parent_gear_left_handed=undef,
        $parent_gear_clearance=undef,$parent_gear_profile_shift=undef,
        $parent_gear_herringbone=undef,$gear_rotation=0,
        $_gear_tooth_angle=0,$gear_ratio=0,
        $gear_angle_offset=0,$gear_travel_offset=0,
        $gear_travel=0,$_gear_tooth_travel=0,$gear_travel_ratio=0,
        $gear_input=undef,
        $gear_contact_dir=undef,$gear_contact_angle=undef,
        $gear_chain_locs=[],$gear_chain_axes=[])
        children();
}
module _gear_publish(S,pose) {
    multmatrix(pose[8])
    let($_gear_attach_request=undef,$_gear_parent_spec=S,$_gear_driver=undef,
        $_gear_shaft_motion=undef,
        $_gear_mount_id=len(pose)>19?pose[19][0]:$_gear_mount_id,
        $_gear_motion_plane_ok=len(pose)>19?pose[19][2]:true,
        $_gear_drive_id=len(pose)>19?pose[19][1]:$_gear_drive_id,
        $_gear_frame_motion=pose[13],$_gear_frame_phase=len(pose)>17?pose[17]:0,
        $_gear_carrier=len(pose)>18?pose[18]:undef,$_gear_carrier_parent=undef,
        $_gear_chain_active=pose[15],
        $_gear_rack_reference=_gear_is_rack(S[0]) && len(pose)>16 ? pose[16] : undef,
        $parent_gear_type=S[0],$parent_gear_mod=S[1],
        $parent_gear_teeth=S[2],$parent_gear_pa=S[3],$parent_gear_helical=S[4],
        $parent_gear_thickness=S[14]||!is_finite(S[5])||S[5]<=0?undef:S[5],
        $parent_gear_face_width=S[0]=="crown"?S[16][0]:S[0]=="bevel"?S[16][2]:
                                S[0]=="worm_face"?S[16][0][4]-S[16][0][3]:undef,
        $parent_gear_shaft_offset=S[0]=="worm_face"?S[16][0][0][4]:undef,
        $_gear_worm_face_data=S[0]=="worm_face"?S[16][0]:undef,
        $parent_gear_profile_shift=S[6],
        $parent_gear_worm_diam=S[7],$parent_gear_starts=S[8],$parent_gear_worm_length=S[9],
        $worm_length=S[9],
        $parent_gear_wheel_teeth=_gear_is_wheel(S[0])||S[0]=="globoid_worm"?S[2]:undef,
        $parent_gear_left_handed=_gear_worm_family(S[0])>0?S[10]:S[0]=="bevel"?S[16][5]:undef,
        $parent_gear_clearance=S[11],$parent_gear_herringbone=S[13],
        $gear_rotation=pose[2],$_gear_tooth_angle=pose[3],$gear_ratio=pose[4],
        $gear_angle_offset=pose[3]-pose[2]-(len(pose)>17?pose[17]:0),
        $gear_travel_offset=pose[10]-pose[9],
        $gear_travel=pose[9],$_gear_tooth_travel=pose[10],$gear_travel_ratio=pose[11],
        $gear_input=pose[14],
        $gear_contact_dir=pose[5],
        $gear_contact_angle=is_undef(pose[5])?undef:
            let(v=S[0]=="rack"?[pose[5].x,pose[5].z]:[pose[5].x,pose[5].y])
            norm(v)<1e-12?undef:atan2(v.y,v.x),
        $gear_chain_locs=pose[6],$gear_chain_axes=pose[7])
        children();
}


// Module: gear_spin()
// Synopsis: Drives a rotary gear chain by an angle.
// Topics: Gears, Attachments
// See Also: gear_travel(), attach_gear()
// Usage:
//   gear_spin(angle) gear_1() attach_gear() gear_2() ...
// Description:
//   Supplies a rotary input for the assembly. Normally, the first gear turns by this angle and passes motion through {{attach_gear()}}.
//   Before constructing the first gear, {{gear_motion()}} can capture the input for a carrier, and {{gear_shaft()}} can select a different
//   motion for that first gear. For example, the central gear can stay fixed while its carrier follows the input.
//   Ordinary geometry directly beneath this module is not rotated; it is a motion source, not a replacement for zrot().
//   The root's `anchor`, `spin`, and `orient` place its reference frame normally.  Adding another `gear_spin()` or a {{gear_travel()}} into
//   the gear chain is not permitted. 
// Arguments:
//   angle = Angle to rotate the gear
// Side Effects:
//   Sets internal variables requesting rotational drive for the root gear.
// Example(2D,Anim,Frames=72,FrameMS=55,VPD=263.43,VPT=[35.99,-1.57,-6.88],NoScales): The central gear is driven and transfers it's motion to the child
//   gear_spin(360*$t)
//       spur_gear2d(mod=2,teeth=24) {
//           color("red") right(12) circle(d=3,$fn=16);
//           attach_gear(0) spur_gear2d(teeth=36)
//               color("blue") right(18) circle(d=3,$fn=16);
//        }
module gear_spin(angle)
{
    assert(is_finite(angle), "\nangle must be a finite number of degrees");
    _gear_drive("rotation",angle) children();
}
// Module: gear_travel()
// Synopsis: Drives a rack driven gear chain by a linear displacement.
// Topics: Gears, Attachments
// See Also: gear_spin(), attach_gear()
// Usage:
//   gear_travel(distance) rack() attach_gear() gear() ...
// Description:
//   Applies translation to its child rack.  This translation propagates through a chain of gears constrcuted with tested {{attach_gear()}} invocations.
//   Child gears placed with {{attach_gear()}} remain at their mounting locations and rotate according to the rack travel.
//   Adding another `gear_travel()` or a {{gear_spin()}} into the gear chain is not permitted.
// Arguments:
//   distance = Mechanical displacement in model units.
// Side Effects:
//   Sets internal variables requesting linear drive for the root rack.
// Example(2D,Anim,NoAxes,FrameMS=55,Frames=72): A sliding rack drives a fixed-axis pinion.
//   gear_travel(30*sin(360*$t))
//       rack2d(mod=4,teeth=12)
//           attach_gear(pos=0) spur_gear2d(teeth=10);
module gear_travel(distance) {
    assert(is_finite(distance), "\ndistance must be finite");
    _gear_drive("travel",distance) children();
}
module _gear_drive(kind,value) {
    assert(!$_gear_chain_active && is_undef($_gear_driver),
           "\nA driven gear chain cannot contain another gear_spin() or gear_travel()");
    assert(is_undef($_gear_attach_request),
           "\nPlace the drive module before the root gear, not between attach_gear() and its child");
    assert(is_undef($_gear_shaft_motion), "\nPlace a gear after gear_shaft() before adding a drive");
    // Establish the mounting identity before the first gear so a rotary input
    // can be captured and supplied to a carrier without a placeholder gear.
    let($_gear_driver=[kind,value],$_gear_drive_id=function() 0,
        $_gear_mount_id=is_undef($_gear_parent_spec)?function() 0:$_gear_mount_id)
        children();
}


// Module: gear_carrier_frame()
// Synopsis: Establishes a rotating support for a parallel-axis gear branch.
// Topics: Gears, Attachments
// See Also: attach_gear(), gear_spin(), planetary_gears(), stepped_planetary()
// Usage:
//   PARENT_GEAR gear_carrier_frame(ratio) CHILDREN;
//   PARENT_GEAR gear_carrier_frame(0) CHILDREN;   // Stationary carrier
// Usage: Carrier motion from another shaft in the same drive
//   PARENT_GEAR gear_carrier_frame(motion) CHILDREN;
// Description:
//   Builds a rotating gear support either as a rotational gain from the parent gear or using a precalculated gear motion from {{gear_motion()}}.
//   When you give a ratio value the carrier rotation is the parent rotation divided by the specified value.
//   A positional motion record from {{gear_motion()}} follows another shaft; a positional 0 holds the carrier stationary.  This is useful for planetary gear assemblies or other
//   assemblies where a gear rotates around another gear instead of rotating on a fixed shaft.  
//   .
//   The carrier's `gearspin=0` X+ and Y+ axes are aligned with the parent's starting reference frame, so attached gears use those axes for placement.
//   Non-gear objects inside the frame move with the carrier.  Use {{gear_exit_carrier()}} at a central output to leave the carrier and resume a fixed-axis gear train.  
//   .
//   The supported parent is a spur or ring. Automatic mates within the moving branch must have parallel axes, and
//   gear stacking must be coaxial.
//   Place this module directly under its gear.  
//   Nested moving carrier frames, racks in the planetary branch, bevel/crossed-axis planets, and an independently
//   driven carrier with a separate root input are not supported. 
// Arguments:
//   ratio/motion = If a ration, (parent rotation)/(carrier rotation).  If zero then fixed motion.  Or give a motion from {{gear_motion()}}.
// Side Effects:
//   `$gear_rotation` is set to carrier angular displacement in degrees inside the frame.
//   `$gear_ratio` is set to carrier angular gain: degrees per degree of rotational input, or degrees per model-unit travel input.
//   `$gear_angle_offset` is set to zero in the tooth-aligned carrier frame.
//   `$gear_input` retains the original chain input kind.
//   `$gear_contact_dir` and `$gear_contact_angle` are re-expressed in the carrier frame.
//   `$gear_chain_locs` and `$gear_chain_axes` are re-expressed in the carrier frame; no gear is added to their histories.
// Example(3D,Med,NoAxes,Anim,Frames=225,FrameMS=25,VPR=[36.80,0.00,0],VPD=325.23,VPT=[1.12,-4.39,8.33]): A moving arm traces an ellipse.  
//   $fn=48;  $gear_steps=8;
//   pen_radius=20;
//   spacing=gear_dist(mod=2,teeth1=36,teeth2=18);
//   arm_points=[[0,0],[spacing/2,-0.65*spacing-4],[spacing,0]];
//   major=spacing+pen_radius;
//   minor=spacing-pen_radius;
//   assert(minor>0,"\nKeep the pen offset shorter than the arm");
//   up(10) recolor("lightgray")
//     linear_extrude(height=1) stroke(ellipse([major,minor]),closed=true);
//   gear_spin(720*$t)
//   spur_gear(mod=2,teeth=36,thickness=6,helical=0,profile_shift=0)
//       gear_carrier_frame(2) {
//           recolor("slategray")down(5) linear_extrude(height=4)stroke(arm_points, width=8);
//           attach_gear(0)
//           recolor("mediumseagreen")
//           spur_gear(teeth=18,thickness=6){
//               up(5) recolor("darkorange") cyl(d=10,h=4);
//               up(7) right(pen_radius/2) recolor("darkorange")
//                   cuboid([pen_radius+6,5,3]);
//               up(9) right(pen_radius) recolor("crimson") cyl(d=3,h=6);
//           }
//       }
// Example(3D,Med,NoAxes,Anim,Frames=72,FrameMS=30,VPR=[246.00,0.00,336.50],VPD=142.49,VPT=[5.46,11.02,19.20]): The teal blue input gear and connected shaft drives the carrier with its six purple gears, while a gear train reverses the drive direction and then drives the ring gear in the opposite direction.  The planetary assembly thus receives two different inputs, one on the ring and one on the carrier, and produces output on the red sun gear.  The construction proceeds from the input gear, through the reversal gear chain, to the ring, the planets, and then the sun, with the sun ready to pass its output on to further gears.  The gear ratio of 6 is calculated and displayed.
//   $fn=48; $gear_steps=12; $backlash=0.1;
//   drive_teeth=18; upper_teeth=24; idler_teeth=12; planet_mod=1.08;
//   train_mod=9/gear_dist(mod=1,teeth1=upper_teeth,teeth2=idler_teeth);
//   sun_teeth=24; planet_teeth=18; ring_teeth=60;
//   planet_angles=[0,60,120,180,240,300];
//   orbit=gear_dist(mod=planet_mod,teeth1=sun_teeth,teeth2=planet_teeth);
//   pin_r=outer_radius(mod=planet_mod,teeth=ring_teeth,internal=true)+1;
//   sun_color = "#D95C5C";ring_color = "#70B85A";drive_color = "#48C8E8";planet_color = "#9B70C0";
//   gear_spin(60*$t) recolor(drive_color)
//     spur_gear(mod=1,teeth=drive_teeth,thickness=4) {   // Drive gear 
//       align(TOP) cyl(d=4,h=25);
//       let(carrier_motion=gear_motion())
//       attach_gear(0)
//         recolor("orange") spur_gear(teeth=drive_teeth)
//           align(TOP) cyl(d=4,h=4)
//           align(TOP) spur_gear(mod=train_mod,teeth=upper_teeth)
//           attach_gear(180) recolor("yellow") spur_gear(teeth=idler_teeth)
//           attach_gear(180) recolor(ring_color) spur_gear(teeth=upper_teeth,shaft_diam=6) {
//              align(TOP) tube(od=8,wall=1,h=11)
//              align(TOP){
//                tube(od=10,wall=2,h=2)
//                  zrot_copies([for(a=planet_angles) a+30]) {
//                     attach(RIGHT,LEFT,overlap=2) cuboid([pin_r-3,2,2]);
//                     right(pin_r) down(1) cyl(d=2,h=12,anchor=BOT);
//                  }
//              }
//              up(24)  // Up to ring gear layer
//                 ring_gear(mod=planet_mod,teeth=ring_teeth,backing=2)
//                   gear_carrier_frame(carrier_motion) {
//                     // Create carrier frame arms
//                     recolor(drive_color) { 
//                       down(6) cyl(d=8,h=2);
//                       down(3)
//                         zrot_copies(planet_angles)
//                           right(orbit) cyl(d=3,h=8)
//                           align(LEFT,BOT,overlap=2) cuboid([orbit,2,2]);
//                     }
//                     // Create planet gears
//                     attach_gear(planet_angles)
//                        recolor(planet_color) spur_gear(teeth=planet_teeth,shaft_diam=3.6)
//                          if($idx==0) attach_gear(180)
//                             // Create sun gear
//                             recolor(sun_color)
//                               spur_gear(teeth=sun_teeth) {
//                                  echo(gear_ratio=$gear_ratio);
//                                  align(BOT,RIGHT,inset=3) recolor("white") cyl(d=2,h=1/2);
//                               }
//                   }
//           }
module gear_carrier_frame(ratio, _named, motion) {
    assert(is_undef(_named), "\nToo many positional arguments (only 1 is accepted)");
    assert(num_defined([ratio,motion])==1, "\nSpecify one carrier ratio or motion value");
    assert(is_undef(motion) || (is_num(motion) && motion==0) || _gear_motion_record(motion),
           "\nSupply a motion value returned by gear_motion(), or 0 for a stationary carrier");
    assert(is_undef(ratio) || (is_finite(ratio) || _gear_motion_record(ratio)),
           "\nThe positional argument must be a finite gear ratio, 0, or a motion returned by gear_motion()");
    assert(is_undef(ratio) || !is_num(ratio) || ratio==0 || is_finite(ratio),
           str("\nThe carrier ratio must be finite; got ",ratio));
    assert(!is_undef($_gear_parent_spec) && _gear_is_circular($_gear_parent_spec[0]),
           "\ngear_carrier_frame() needs a parent spur or ring gear");
    assert(is_undef($_gear_attach_request), "\nPlace a gear between attach_gear() and gear_carrier_frame()");
    assert(is_undef($attach_to) && is_undef($attach_alignment),
           "\nPlace gear_carrier_frame() directly under its gear, before attach() or align()");
    assert(is_undef($_gear_driver), "\nPlace the drive before the parent gear, not before its carrier frame");
    assert(is_undef($_gear_carrier), "\nNested moving carrier frames are not supported");
    // Keep calculations in let() scopes after validation: ordinary assignments
    // in a module body are evaluated before its assertion statements.
    let(selected=is_undef(motion)?ratio:motion,
        m=is_num(selected) && selected!=0?undef:_gear_resolve_motion(selected),
        carrier=is_undef(m)?$gear_rotation/selected:m[2], gain=is_undef(m)?$gear_ratio/selected:m[3],
        relative_motion=$gear_rotation-carrier, relative_gain=$gear_ratio-gain,
        turn=$gear_angle_offset+carrier-$gear_rotation)
    assert(is_finite(carrier) && is_finite(gain) && is_finite(relative_motion) &&
           is_finite(relative_gain) && is_finite(turn), "\nCarrier motion exceeds the supported numeric range")
    let(F=zrot(turn), inv=zrot(-turn), contact=_gear_vector_in(inv,$gear_contact_dir))
    // Parent children already carry parent rotation. Replace only this branch's
    // frame with the carrier motion and the parent's initial tooth alignment.
    multmatrix(F)
    let($_gear_carrier=[carrier,gain,len($gear_chain_locs)-1],
        $_gear_carrier_parent=[relative_motion,relative_motion,relative_gain],
        $_gear_frame_motion=ident(4),$_gear_frame_phase=0,
        $gear_rotation=carrier,$gear_ratio=gain,$_gear_tooth_angle=carrier,
        $gear_angle_offset=0,
        $gear_contact_dir=contact,
        $gear_contact_angle=is_undef(contact) || norm([contact.x,contact.y])<1e-12?undef:atan2(contact.y,contact.x),
        $gear_chain_locs=apply(inv,$gear_chain_locs),
        $gear_chain_axes=_gear_axes_in(inv,$gear_chain_axes))
        children();
}


// Module: gear_exit_carrier()
// Synopsis: Takes a central output from a carrier branch into a fixed-axis gear train.
// Topics: Gears, Attachments
// See Also: gear_carrier_frame(), gear_motion(), gear_shaft(), attach_gear()
// Usage:
//   OUTPUT_GEAR gear_exit_carrier() CHILDREN;
// Description:
//   Continues a central carrier-branch output as a fixed-axis shaft, retaining its rotation.  
//   Its ordinary children turn with the shaft, and subsequent {{attach_gear()}} placements use
//   the stationary center as mounting reference.  
//   Call it directly beneath the central output gear. 
// Side Effects:
//   Leaves the current carrier context while retaining shaft motion, gain, tooth alignment, and spatial histories.
module gear_exit_carrier(_extra) {
    assert(is_undef(_extra), "\nToo many positional arguments (only 0 are accepted)");
    assert(_gear_motion_context(), "\ngear_exit_carrier() needs an enclosing rotary spur or ring gear");
    assert(is_undef($_gear_attach_request) && is_undef($attach_to) && is_undef($attach_alignment),
           "\nPlace gear_exit_carrier() directly under the output gear, before another attachment");
    assert(!is_undef($_gear_carrier) && is_undef($_gear_carrier_parent),
           "\ngear_exit_carrier() needs an output gear reached inside a carrier branch");
    assert(_gear_motion_parallel(), "\nA fixed-axis output must have a parallel, consistently directed axis");
    let(k=len($_gear_carrier)>2?$_gear_carrier[2]:undef)
    assert(is_int(k) && k>=0 && k<len($gear_chain_locs), "\nThe carrier-axis history is unavailable")
    let(v=$gear_chain_locs[k], scale=max(1,max([for(j=[k:len($gear_chain_locs)-1])
            let(d=$gear_chain_locs[j]-v) norm([d.x,d.y])]))) 
    assert(norm([v.x,v.y])<=1e-9*scale,
           "\nThe output shaft must coincide with the carrier's central axis; an orbiting shaft cannot be made stationary")
    let($_gear_carrier=undef,$_gear_carrier_parent=undef,
        $_gear_frame_motion=zrot($gear_rotation+default($_gear_frame_phase,0)))
        children();
}

// Module: gear_shaft()
// Synopsis: Establishes a separate coaxial shaft with a specified motion.
// Topics: Gears, Attachments
// See Also: gear_motion(), gear_carrier_frame(), gear_exit_carrier()
// Usage:
//   PARENT_GEAR gear_shaft([motion]) CHILD_GEAR();
// Usage: Start with a stationary or motion-connected shaft
//   gear_spin(angle) gear_shaft([motion]) FIRST_GEAR();
// Description:
//   Starts a separate coaxial shaft for the following gear. By default, the new shaft stays stationary even when the enclosing gear turns.
//   To make it follow another shaft, give a previous gear rotation from {{gear_motion()}}.  
//   The selected motion replaces rather than adds to inherited motion.
//   The new shaft has zero initial tooth phase and its gear begins a new tree.
//   Supply the new gear's tooth size explicitly. 
//   Construct the new gear directly beneath this module. From a carrier branch, first use {{gear_exit_carrier()}}.
//   The new coaxial spur/ring shaft inherits the original drive input and mounting frame. 
// Arguments:
//   motion = Motion returned by {{gear_motion()}}, or 0 for a stationary shaft. Default: 0
// Side Effects:
//   Starts a separate shaft context without changing the original drive identity or gain units.
//   Resets inherited tooth dimensions, initial phase, and spatial histories for the next gear.
// Example(3D,Med,NoAxes,VPR=[55,0,25],VPT=[0,0,4],VPD=90,Anim,Frames=64,FrameMS=55): Without `gear_shaft()` both gears turn together.
//   $fn=48;  $gear_steps=12;  $backlash=0.1;
//   gear_spin(360*$t)
//   spur_gear(mod=1,teeth=24,thickness=4) {
//       align(TOP,RIGHT) recolor("crimson") cyl(d=2,h=1);
//       align(TOP) recolor("mediumseagreen")
//       spur_gear(mod=1,teeth=20,thickness=4)
//         align(TOP,RIGHT,inset=3) recolor("crimson") cyl(d=2,h=1);
//   }
// Example(3D,Med,NoAxes,VPR=[55,0,25],VPT=[0,0,4],VPD=90,Anim,Frames=64,FrameMS=55): With `gear_shaft()` the upper gear stays fixed.  
//   $fn=48;  $gear_steps=12;  $backlash=0.1;
//   gear_spin(360*$t)
//   spur_gear(mod=1,teeth=24,thickness=4) {
//       align(TOP,RIGHT) recolor("crimson") cyl(d=2,h=1);
//       gear_shaft()
//       align(TOP) recolor("mediumseagreen")
//       spur_gear(mod=1,teeth=20,thickness=4)
//         align(TOP,RIGHT,inset=3) recolor("crimson") cyl(d=2,h=1);
//   }
// Example(2D,Med,NoAxes,VPR=[0,0,0],VPT=[0,0,1],VPD=220,Anim,Frames=100,FrameMS=40): Without `gear_shaft()` the two gears rotate together as a unit.
//   $fn=48;  $gear_steps=12;
//     gear_spin(360*$t)
//     let(arm_motion=gear_motion())
//       spur_gear2d(mod=1,teeth=24)
//       gear_carrier_frame(motion=arm_motion)  {
//           attach_gear(0)
//           recolor("mediumseagreen") spur_gear2d(teeth=24)
//                             align(TOP,RIGHT,inset=2) color_this("crimson")cyl(d=1,h=1);
//           up(4) recolor("royalblue")
//                stroke([[0,0],[24,0]],width=2);
//       }
// Example(2D,Med,NoAxes,VPR=[0,0,0],VPT=[0,0,1],VPD=220,Anim,Frames=100,FrameMS=40): With `gear_shaft()` the central gear is fixed and the equal sized planet rotates around it, making two turns for each single revolution of the arm.
//   $fn=48;  $gear_steps=12;
//     gear_spin(360*$t)
//     let(arm_motion=gear_motion())
//       gear_shaft()
//       spur_gear2d(mod=1,teeth=24)
//       gear_carrier_frame(motion=arm_motion)  {
//           attach_gear(0)
//           recolor("mediumseagreen") spur_gear2d(teeth=24)
//                             align(RIGHT,overlap=3) color_this("crimson")cyl(d=1,h=1);
//           recolor("royalblue")
//                stroke([[0,0],[24,0]],width=2);
//       }


module gear_shaft(motion=0, _named) {
    assert(is_undef(_named), "\nToo many positional arguments (only 1 is accepted)");
    assert(_gear_root_motion_context() || _gear_motion_context(),
           "\nPlace gear_shaft() inside a rotary spur or ring gear, or before the first gear inside gear_spin()");
    assert(is_undef($_gear_attach_request) && is_undef($attach_to) && is_undef($attach_alignment),
           "\nPlace gear_shaft() before a separate gear, not within an unfinished attachment");
    assert(is_undef($_gear_carrier), "\nLeave the carrier through gear_exit_carrier() before starting a separate shaft");
    assert(is_undef($_gear_shaft_motion), "\nPlace a gear between successive gear_shaft() calls");
    assert(_gear_motion_parallel(), "\nSeparate shafts require parallel, consistently directed axes");
    // Before the first gear, the root input has not rotated any geometry yet.
    // Consume that pending input without cancelling an unapplied rotation.
    let(m=_gear_resolve_motion(motion),
        turn=_gear_root_motion_context()?0:$gear_rotation+default($_gear_frame_phase,0))
    multmatrix(zrot(-turn))
    let($_gear_shaft_motion=m,$_gear_parent_spec=undef,$_gear_attach_request=undef,$_gear_driver=undef,
        $_gear_frame_motion=ident(4),$_gear_frame_phase=0,$_gear_carrier=undef,$_gear_carrier_parent=undef,
        $_gear_chain_active=!is_undef(m[4]),$_gear_rack_reference=undef,
        $parent_gear_type=undef,$parent_gear_mod=undef,$parent_gear_teeth=undef,$parent_gear_pa=undef,
        $parent_gear_helical=undef,$parent_gear_thickness=undef,$parent_gear_face_width=undef,
        $parent_gear_shaft_offset=undef,$_gear_worm_face_data=undef,$parent_gear_profile_shift=undef,
        $parent_gear_clearance=undef,$parent_gear_herringbone=undef,
        $parent_gear_worm_diam=undef,$parent_gear_starts=undef,$parent_gear_worm_length=undef,
        $parent_gear_wheel_teeth=undef,$parent_gear_left_handed=undef,$worm_length=undef,
        $gear_rotation=0,$gear_ratio=0,$_gear_tooth_angle=0,$gear_angle_offset=0,
        $gear_travel=0,$gear_travel_ratio=0,$_gear_tooth_travel=0,$gear_travel_offset=0,
        $gear_input=m[4],$gear_contact_dir=undef,$gear_contact_angle=undef,$gear_chain_locs=[],$gear_chain_axes=[])
        children();
}




// Function: gear_motion()
// Synopsis: Captures a shaft's motion for another shaft or a carrier.
// Topics: Gears, Attachments
// See Also: gear_shaft(), gear_carrier_frame(), gear_exit_carrier(), gear_spin()
// Usage:
//   motion = gear_motion();
// Description:
//    Returns the current shaft's rotation so another shaft or carrier can follow it.
//    Before the first gear inside {{gear_spin()}}, it returns that input rotation.   Use the returned data object as input to  {{gear_shaft()}} or {{gear_carrier_frame()}}.
//    Capture it with let() inside the source gear's scope, as subsequent scopes will change the motion.  
function gear_motion(_extra) =
    assert(is_undef(_extra), "\nToo many positional arguments (only 0 are accepted)")
    assert(is_undef($_gear_shaft_motion), "\nPlace a gear after gear_shaft() before capturing its motion")
    let(root=_gear_root_motion_context())
    assert(root || _gear_motion_context(),
           "\nCapture motion inside a rotary spur or ring gear, its carrier frame, or before the first gear inside gear_spin()")
    assert(is_undef($_gear_attach_request) && is_undef($attach_to) && is_undef($attach_alignment),
           "\nCapture motion before starting another attachment")
    assert(_gear_motion_parallel(), "\nMotion connections require parallel, consistently directed shaft axes")
    ["BOSL2_GEAR_MOTION",1,root?$_gear_driver[1]:$gear_rotation,root?1:$gear_ratio,
     _gear_motion_input(),$_gear_drive_id,$_gear_mount_id];






// Private motion records retain identity by closure identity, not by matching
// angles or input kinds. Records from different driver evaluations cannot match.
function _gear_motion_context() =
    !is_undef($_gear_parent_spec) && _gear_is_circular($_gear_parent_spec[0]) && is_function($_gear_mount_id);
// A rotary input is available before a gear consumes it. No synthetic gear,
// physical rotation, or change to the published shaft variables is necessary.
function _gear_root_motion_context() =
    is_undef($_gear_parent_spec) && is_undef($_gear_shaft_motion) && !$_gear_chain_active &&
    !is_undef($_gear_driver) && $_gear_driver[0]=="rotation" &&
    is_function($_gear_drive_id) && is_function($_gear_mount_id);
function _gear_motion_input() = _gear_root_motion_context()?"rotation":$gear_input;
function _gear_motion_parallel() =
    default($_gear_motion_plane_ok,true) && len([for(a=$gear_chain_axes) if(!is_undef(a) && (norm(cross(a,UP))>1e-9 || a.z<0)) 1])==0;
function _gear_motion_record(m) =
    !is_list(m) || len(m)!=7 ? false :
    m[0]=="BOSL2_GEAR_MOTION" && m[1]==1 && is_finite(m[2]) && is_finite(m[3]) &&
    (is_undef(m[4]) || m[4]=="rotation" || m[4]=="travel") &&
    (is_undef(m[5]) || is_function(m[5])) && is_function(m[6]);
function _gear_resolve_motion(m) =
    assert(_gear_motion_parallel(), "\nMotion connections require coaxial ordinary stacks and parallel, consistently directed shaft axes")
    let(input=_gear_motion_input(),
        v=is_num(m) && m==0 ? ["BOSL2_GEAR_MOTION",1,0,0,input,$_gear_drive_id,$_gear_mount_id] : m)
    assert(_gear_motion_record(v), "\nSupply a motion value returned by gear_motion(), or 0 for a stationary shaft")
    assert(v[5]==$_gear_drive_id && v[4]==input,
           "\nMotion values must belong to the same original driver; independent drives cannot be connected")
    assert(v[6]==$_gear_mount_id,
           "\nMotion values must belong to the same mounting reference")
    v;
function _gear_shaft_root_pose(S,phase,anchor,spin,orient,travel) =
    assert(_gear_is_circular(S[0]), "\nA separate motion-connected shaft requires a spur or ring gear")
    assert(default(spin,0)==0 && default(orient,UP)==UP,
           "\nA separate shaft must keep spin=0 and orient=UP; rotate the complete assembly instead")
    assert(is_finite(phase), "\ngear_spin must be finite")
    let(m=$_gear_shaft_motion,q=m[2],g=m[3],full=zrot(q))
    [ident(4),phase+q,q,phase+q,g,undef,[[0,0,0]],[UP],full,
     0,0,0,0,full,m[4],!is_undef(m[4]),undef,0];



// Section: Computing Gear Dimensions
//   These functions provide gear dimensions and mating distances. Use {{outer_radius()}}
//   for the tooth-tip envelope and {{pitch_radius()}} for the reference pitch circle.
//   For mating placement, use {{gear_dist()}}, {{gear_dist_skew()}}, {{worm_dist()}},
//   or {{globoid_worm_dist()}} as appropriate.


// Function: circular_pitch()
// Synopsis: Returns tooth size expressed as "circular pitch".
// Topics: Gears, Parts
// See Also: spur_gear(), diametral_pitch(), circular_pitch(), module_value()
// Usage: As a Function
//   value = circular_pitch(mod=|circ_pitch=|diam_pitch=);
// Description:
//   Get tooth size expressed as "circular pitch", or the distance between teeth centers around the pitch circle.
//   For example, an 11 tooth gear with a pitch circumference of 110 mm has a circular pitch of 110 mm /11, or 10 mm / tooth.
//   Note that this calculation is does not depend on units for circ_pitch or mod, but the `diam_pitch` argument is based
//   on inches and returns its value in millimeters.  
// Arguments:
//   ---
//   mod = The module of the gear (pitch diameter / teeth)
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  The diametral pitch is a completely different thing than the pitch diameter.
//   circ_pitch = Normal circular pitch.
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
    assert(is_undef(_named), "\nToo many positional arguments (only 0 are accepted)")
    assert(num_defined([mod,circ_pitch,diam_pitch])==1,
           "\nspecify exactly one of mod=, circ_pitch=, or diam_pitch=")
    circ_pitch != undef ? assert(is_finite(circ_pitch) && circ_pitch>0, str("
circ_pitch must be positive and finite; got ",circ_pitch)) circ_pitch :
    diam_pitch != undef ? assert(is_finite(diam_pitch) && diam_pitch>0, str("
diam_pitch must be positive and finite; got ",diam_pitch)) PI*INCH/diam_pitch :
    assert(is_finite(mod) && mod>0, str("
mod must be positive and finite; got ",mod)) mod*PI;
// Function: diametral_pitch()
// Synopsis: Returns tooth size expressed as "diametral pitch".
// Topics: Gears, Parts
// See Also: spur_gear(), diametral_pitch(), circular_pitch(), module_value()
// Usage: As a Function
//   value = diametral_pitch(mod=|circ_pitch=|diam_pitch=);
// Description:
//   Returns tooth density expressed as "diametral pitch", the number of teeth per inch of pitch diameter.
//   For example, if you have a gear with 30 teeth, with a 1.5 inch pitch diameter, then you have a
//   diametral pitch of 20 teeth/inch.
// Arguments:
//   ---
//   mod = The module of the gear (pitch diameter / teeth)
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  The diametral pitch is a completely different thing than the pitch diameter.
//   circ_pitch = Normal circular pitch.
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
    assert(is_undef(_named), "\nToo many positional arguments (only 0 are accepted)")
    let( circ_pitch = circular_pitch(circ_pitch=circ_pitch, mod=mod, diam_pitch=diam_pitch) )
    PI / circ_pitch * INCH;
// Function: module_value()
// Synopsis: Returns tooth density expressed as "module"
// Topics: Gears, Parts
// See Also: spur_gear(), diametral_pitch(), circular_pitch(), module_value()
// Usage: As a Function
//   value = module_value(mod=|circ_pitch=|diam_pitch=);
// Description:
//   Get tooth size expressed as "module".  The module is the pitch
//   diameter of a straight-tooth gear divided by its tooth count. For example, a straight-tooth gear with a pitch
//   diameter of 40 mm and 20 teeth has a module of 2 mm. For `circ_pitch` and `mod` this
//   calculation preserves the model's length unit. Diametral pitch is based on inches, so
//   the module is returned in millimeters.  
// Arguments:
//   ---
//   mod = The module of the gear (pitch diameter / teeth)
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  The diametral pitch is a completely different thing than the pitch diameter.
//   circ_pitch = Normal circular pitch.
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
    assert(is_undef(_named), "\nToo many positional arguments (only 0 are accepted)")
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
///   mod = Normal module: normal circular pitch divided by PI.
///   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  The diametral pitch is a completely different thing than the pitch diameter.
///   circ_pitch = The circular pitch, the distance between teeth centers around the pitch circle.
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
    assert(is_undef(_named), "\nToo many positional arguments (only 1 is accepted)")
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
///   mod = Normal module: normal circular pitch divided by PI.
///   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  The diametral pitch is a completely different thing than the pitch diameter.
///   circ_pitch = The circular pitch, the distance between teeth centers around the pitch circle.
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
    assert(is_undef(_named), "\nToo many positional arguments (only 2 are accepted)")
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
//   value = pitch_radius(mod=|circ_pitch=|diam_pitch=, teeth, [helical]);
// Description:
//   Calculates the reference pitch radius. Unshifted external gears with parallel axes
//   mesh at the sum of their pitch radii; an unshifted ring/pinion pair uses the difference.
//   Use {{gear_dist()}} for placement with profile shift or spacing backlash.
// Arguments:
//   teeth = The number of teeth on the gear.
//   helical = The helical angle (from vertical) of the teeth on the gear.  Default: 0
//   ---
//   mod = The module of the gear (pitch diameter / teeth)
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  The diametral pitch is a completely different thing than the pitch diameter.
//   circ_pitch = Normal circular pitch.
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
    assert(is_undef(_named), "\nToo many positional arguments (only 2 are accepted)")
    let(
        helical=is_undef(helical)?0:helical
    )
    let( circ_pitch = circular_pitch(circ_pitch=circ_pitch, mod=mod, diam_pitch=diam_pitch) )
    assert(is_finite(helical) && abs(helical)<90, str("\nhelical must be finite and strictly between -90 and 90 degrees; got ",helical))
    assert(is_finite(circ_pitch), "\nSpecify one positive finite tooth-size measure")
    circ_pitch * teeth / PI / 2 / cos(helical);
// Function: outer_radius()
// Synopsis: Returns the outer radius for a gear.
// Topics: Gears, Parts
// See Also: spur_gear(), diametral_pitch(), circular_pitch(), module_value(), pitch_radius(), outer_radius()
// Usage: As a Function
//   value = outer_radius(mod=|circ_pitch=|diam_pitch=, teeth, [clearance=], [profile_shift=], [pressure_angle=], [helical=], [shorten=], [internal=]);
// Description:
//   Calculates the standard outer radius for the gear. The gear fits entirely within a cylinder of this radius.  The gear
//   will fit exactly in the cylinder except in two cases:
//      1.  It has been strongly profile shifted, in which case it will be undersized due to tip clipping.
//      2.  The pressure angle is very high, in which case the tips meet in points before the standard radius, also resulting in undersized teeth
// Arguments:
//   teeth = The number of teeth on the gear.
//   ---
//   mod = The module of the gear (pitch diameter / teeth)
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  The diametral pitch is a completely different thing than the pitch diameter.
//   circ_pitch = Normal circular pitch.
//   clearance = If given, sets the clearance between meshing teeth.  Default: module/4
//   profile_shift = Profile shift factor x.  Default: "auto"
//   pressure_angle = Pressure angle.  Default: 20
//   helical = The helical angle (from vertical) of the teeth on the gear.  Default: 0
//   shorten = Shortening factor, needed to maintain clearance with profile shifting.  Default: 0
//   internal = Measure an internal gear when true. Default: false.
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
    assert(is_undef(_named), "\nToo many positional arguments (only 1 is accepted)")
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
//   value = root_radius(mod=|circ_pitch=|diam_pitch=, teeth, [helical], [profile_shift=], [pressure_angle=], [clearance=], [backlash=], [internal=]);
// Description:
//   Calculates the actual radius of the roots of the teeth.  The root radius is usually given as a straight forward calculation, but
//   when large pressure-angle teeth are clipped, it is more difficult to determine this radius.  This function calculates the actual
//   root radius so that you can, for example, place a partial tooth gear onto a matching circle.   The `backlash` parameter may seem
//   unnecessary, but when large pressure angle teeth are clipped, the value of backlash changes the clipping radius.  For regular
//   gear teeth, `backlash` has no effect on the radius.    
// Arguments:
//   teeth = The number of teeth on the gear.
//   helical = The helical angle (from vertical) of the teeth on the gear.  Default: 0
//   ---
//   mod = The module of the gear (pitch diameter / teeth)
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  The diametral pitch is a completely different thing than the pitch diameter.
//   circ_pitch = Normal circular pitch.
//   profile_shift = Profile shift factor x.  Default: "auto"
//   pressure_angle = Pressure angle.  Default: 20
//   clearance = If given, sets the clearance between meshing teeth.  Default: module/4
//   backlash = Tooth-thinning backlash of the gear whose root is measured; use the same value as in the gear constructor. Default: $backlash 
//   internal = Measure an internal gear when true. Default: false.
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
    assert(is_undef(_named), "\nToo many positional arguments (only 2 are accepted)")
    let(helical=default(helical,0),
        internal=default(internal,false),
        profile_shift=default(profile_shift,"auto"),
        pressure_angle=default(pressure_angle,20),
        backlash=_gear_backlash(backlash))
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
///   mod = Normal module: normal circular pitch divided by PI.
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
    assert(is_undef(_named), "\nToo many positional arguments (only 1 is accepted)")
    let( circ_pitch = circular_pitch(circ_pitch=circ_pitch, mod=mod, diam_pitch=diam_pitch) )
    pitch_radius(circ_pitch=circ_pitch, teeth=teeth, helical=helical) - (
        internal
          ? _adendum(circ_pitch=circ_pitch, profile_shift=-profile_shift)
          : _dedendum(circ_pitch=circ_pitch, clearance=clearance, profile_shift=profile_shift)
    );


/// Function: _base_radius()
/// Usage: As a Function
///   value = _base_radius(mod=|circ_pitch=|diam_pitch=, teeth, pressure_angle, [helical]);
/// Topics: Gears
/// Description:
///   Get the base circle for involute teeth, at the base of the teeth.
/// Arguments:
///   teeth = The number of teeth on the gear.
///   pressure_angle = Pressure angle in degrees.  Controls how straight or bulged the tooth sides are.
///   helical = The helical angle (from vertical) of the teeth on the gear.  Default: 0
///   ---
///   mod = Normal module: normal circular pitch divided by PI.
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
    assert(is_undef(_named), "\nToo many positional arguments (only 3 are accepted)")
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
//   value = bevel_pitch_angle(teeth, mate_teeth, [drive_angle|shaft_angle=]);
// Description:
//   Returns the pitch cone angle for a bevel gear with a given number of teeth, designed
//   for a mate with a possibly different tooth count, and with the specified shaft angle between the gears.  
// Arguments:
//   teeth = Number of teeth that this gear has.
//   mate_teeth = Number of teeth that the matching gear has.
//   drive_angle/shaft_angle = Angle between the shafts.  Default: 90.
// Example:  
//   ang = bevel_pitch_angle(teeth=18, mate_teeth=30);
// Example(3D,Med,NoAxes,VPR=[0.00,0.00,0.00],VPD=60.27,VPT=[0.06,-9.80,-6.88]):
//   t1 = 13; t2 = 19; pitch=5;
//   pang = bevel_pitch_angle(teeth=t1, mate_teeth=t2);
//   zrot_copies([0,pang])
//      stroke([[0,0,0], [0,-20,0]],width=0.3,color="black");
//   stroke(arc(n=10,r=3, angle=[270,270+pang]),width=0.3);
//   #bevel_gear(
//       circ_pitch=5, teeth=t1, mate_teeth=t2,
//       spiral=0, cutter_radius=1000,
//       slices=12, anchor="apex", orient=BACK
//   );
function bevel_pitch_angle(
    teeth, mate_teeth, drive_angle, _named, shaft_angle
) =
    assert(is_undef(_named), "\nToo many positional arguments (only 3 are accepted)")
    assert(is_finite(teeth) && teeth>0 && is_finite(mate_teeth) && mate_teeth>0,
           "\nteeth and mate_teeth must be supplied as positive finite numbers")
    let(drive_angle=_gear_shaft_angle(shaft_angle,drive_angle))
    atan2(sin(drive_angle),(mate_teeth/teeth)+cos(drive_angle));


// Function: gear_dist()
// Synopsis: Returns the distance between two gear centers for spur gears or parallel axis helical gears.
// Topics: Gears, Parts
// See Also: worm(), worm_gear(), globoid_worm_gear(), pitch_radius(), outer_radius()
// Usage: As a Function
//   value = gear_dist(mod=|circ_pitch=|diam_pitch=, teeth1, teeth2, [helical], [profile_shift1], [profile_shift2], [internal1=], [internal2=], [pressure_angle=], [backlash=]);
// Description:
//   Calculate the distance between the centers of two spur gears or helical gears with parallel axes,
//   taking into account profile shifting and helical angle.  You can give the helical angle as either positive or negative.  
//   If you set one of the tooth counts to zero then that gear is treated as a rack and the distance returned is the
//   distance between the rack's pitch line and the gear's center.  If you set internal1 or internal2 to true then the
//   specified gear is a ring gear;  the returned distance is still the distance between the centers of the gears.  
//   For a regular gear and ring gear to be compatible the ring gear must have more teeth and at least as much profile shift
//   as the regular gear.  Ring gear profile shifts default to zero.  Spur gears have automatic profile shifting that may
//   give a nonzero value by default.  
//   .
//   The backlash parameter computes the distance offset that produces a total backlash of `2*backlash` in the
//   two gear mesh system.  This is equivalent to giving the same backlash argument to both gears.  
// Arguments:
//   teeth1 = Total number of teeth in the first gear.  If given 0, we assume this is a rack or worm.
//   teeth2 = Total number of teeth in the second gear.  If given 0, we assume this is a rack or worm.
//   helical = The value of the helical angle (from vertical) of the teeth on the two gears (either sign).  Default: 0
//   profile_shift1 = Profile shift for gear 1.  Default: 0  if `internal1=true`, otherwise "auto".
//   profile_shift2 = Profile shift for gear 2.  Default: 0  if `internal2=true`, otherwise "auto".
//   ---
//   mod = The module of the gear (pitch diameter / teeth)
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  The diametral pitch is a completely different thing than the pitch diameter.
//   circ_pitch = Normal circular pitch.
//   internal1 = first gear is an internal (ring) gear.  Default: false
//   internal2 = second gear is an internal (ring) gear.  Default: false
//   pressure_angle = Normal pressure angle in degrees. Default: 20.
//   backlash = Increase spacing to create total nominal play 2*backlash; do not also thin teeth for the same play. Default: 0.
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
    assert(is_undef(_named), "\nToo many positional arguments (only 5 are accepted)")
    let(helical=default(helical,0),
        internal1=default(internal1,false),
        internal2=default(internal2,false),
        backlash=default(backlash,0),
        pressure_angle=default(pressure_angle,20))
    assert(all_nonnegative([teeth1,teeth2]),"\nMust give nonnegative values for teeth")
    assert(teeth1>0 || teeth2>0, "\nOne of the teeth counts must be nonzero")
    assert(is_bool(internal1), "\ninternal1 must be boolean")
    assert(is_bool(internal2), "\ninternal2 must be boolean")
    assert(is_finite(helical) && abs(helical)<90, str("\nhelical must be finite and strictly between -90 and 90 degrees; got ",helical))
    assert(!(internal1&&internal2), "\nCannot specify both gears as internal")
    assert(!(internal1 || internal2) || (teeth1>0 && teeth2>0), "\nCannot specify internal gear with rack (zero tooth count)")
    let(
        mod = module_value(mod=mod,circ_pitch=circ_pitch,diam_pitch=diam_pitch),
        spacing_backlash = _gear_spacing_backlash(backlash,pressure_angle,helical),
        ring_given = internal1 ? profile_shift1 : profile_shift2,
        spur_given = internal1 ? profile_shift2 : profile_shift1,
        ring_ps = default(ring_given,0),
        spur_ps = auto_profile_shift(teeth=internal1?teeth2:teeth1,
                                     pressure_angle=pressure_angle,helical=helical,
                                     profile_shift=spur_given),
        profile_shift1 = internal1 ? ring_ps :
                         auto_profile_shift(teeth=teeth1,pressure_angle=pressure_angle,
                                            helical=helical,profile_shift=profile_shift1),
        profile_shift2 = internal2 ? ring_ps :
                         auto_profile_shift(teeth=teeth2,pressure_angle=pressure_angle,
                                            helical=helical,profile_shift=profile_shift2),
        signed_teeth1 = internal2? -teeth1 : teeth1,
        signed_teeth2 = internal1? -teeth2 : teeth2
    )
    assert(!(internal1||internal2) || is_finite(ring_ps),
           "\nRing gear profile_shift must be numerical; omitted ring shift defaults to 0")
    assert(signed_teeth1+signed_teeth2>0, "\nInternal gear must have more teeth than the mated external gear")
    assert(!(internal1||internal2) || ring_ps+1e-12 >=spur_ps,
           str("\nRing gear profile_shift=",ring_ps," is less than the mating spur gear shift=",spur_ps,". ",
               is_undef(spur_given) || spur_given=="auto" ?
                   str("Automatic profile shifting selected ",spur_ps," for the ",internal1?teeth2:teeth1,
                       "-tooth external gear. ") : "",
               is_undef(ring_given) ? "The ring default is 0. " : "",
               "Specify at least ",spur_ps," on the ring and use the same shifts in gear_dist()."))
    let(teeth1=signed_teeth1,teeth2=signed_teeth2,
        profile_shift1=internal2?-profile_shift1:profile_shift1,
        profile_shift2=internal1?-profile_shift2:profile_shift2)
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
    assert(is_finite(backlash) && backlash>=0, "\nbacklash must be finite and nonnegative")
    assert(is_finite(pressure_angle) && pressure_angle>=0 && pressure_angle<90,
           "\npressure_angle must be in [0,90)")
    assert(is_finite(helical) && abs(helical)<90, "\nabs(helical) must be < 90")
    backlash==0 ? 0 :
    assert(pressure_angle>0, "\nPositive spacing backlash requires pressure_angle > 0")
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
  assert(rhs>0, "\nTotal profile shift is too small, so working pressure angle is negative, and no valid gear separation exists")
  let(
      pa_eff = root_find(function (x) _invol(a=x)-rhs, 1, 75)
  )
  pa_eff;


// Function: gear_dist_skew()
// Synopsis: Returns the distance between two helical gear centers with skew axes.  
// Topics: Gears, Parts
// See Also: gear_dist(), worm(), worm_gear(), globoid_worm_gear(), pitch_radius(), outer_radius()
// Usage: As a Function
//   value = gear_dist_skew(mod=|circ_pitch=|diam_pitch=, teeth1, teeth2, helical1, helical2, [profile_shift1], [profile_shift2], [pressure_angle=], [backlash=]);
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
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  The diametral pitch is a completely different thing than the pitch diameter.
//   circ_pitch = Normal circular pitch.
//   pressure_angle = Normal pressure angle in degrees. Default: 20.
//   backlash = Increase spacing to create total nominal play 2*backlash; do not also thin teeth for the same play. Default: 0.
// Example(3D,Med,NoAxes,VPT=[-0.302111,3.7924,-9.252],VPR=[55,0,25],VPD=155.556): Non-parallel Helical Gears (without any profile shifting)
//   circ_pitch=5; teeth1=15; teeth2=24; ha1=45; ha2=30; thick=10;
//   d = gear_dist_skew(circ_pitch=circ_pitch, teeth1=teeth1, teeth2=teeth2, helical1=ha1, helical2=ha2);
//   left(d/2) spur_gear(circ_pitch=circ_pitch, teeth=teeth1, helical=ha1, thickness=thick, gear_spin=-90);
//   right(d/2) xrot(ha1+ha2) spur_gear(circ_pitch=circ_pitch, teeth=teeth2, helical=ha2, thickness=thick, gear_spin=90-180/teeth2);
function gear_dist_skew(
    teeth1, teeth2, helical1, helical2, profile_shift1, profile_shift2, _named, mod, circ_pitch,
    diam_pitch, pressure_angle, backlash
) =
    assert(is_undef(_named), "\nToo many positional arguments (only 6 are accepted)")
    let(pressure_angle=default(pressure_angle,20),
        backlash=default(backlash,0))
  assert(all_nonnegative([teeth1,teeth2]),"\nMust give nonnegative values for teeth")
  assert(teeth1>0 || teeth2>0, "\nOne of the teeth counts must be nonzero")
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
//   value = gear_skew_angle(teeth1, teeth2, helical1, helical2, [profile_shift1], [profile_shift2], [pressure_angle=]);
// Synopsis: Returns corrected skew angle between two profile shifted helical gears.  
// Description:
//   Compute the corrected skew angle between the axes of two profile shifted helical gears.  When profile shifting is zero, or when one of
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
//   pressure_angle = Normal pressure angle in degrees. Default: 20.
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
    assert(is_undef(_named), "\nToo many positional arguments (only 6 are accepted)")
    let(pressure_angle=default(pressure_angle,20))
   assert(all_nonnegative([teeth1,teeth2]),"\nMust give nonnegative values for teeth")
   assert(teeth1>0 || teeth2>0, "\nOne of the teeth counts must be nonzero")
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
//   value = get_profile_shift(mod=|circ_pitch=|diam_pitch=, desired, teeth1, teeth2, [helical], [internal1=], [internal2=], [pressure_angle=]);
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
//   diam_pitch = The diametral pitch, or number of teeth per inch of pitch diameter.  The diametral pitch is a completely different thing than the pitch diameter.
//   circ_pitch = Normal circular pitch.
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
    assert(is_undef(_named), "\nToo many positional arguments (only 4 are accepted)")
    let(helical=default(helical,0),
        pressure_angle=default(pressure_angle,20),
        internal1=default(internal1,false),
        internal2=default(internal2,false))
  assert(all_nonnegative([teeth1,teeth2]),"\nMust give nonnegative values for teeth")
  assert(teeth1>0 || teeth2>0, "\nOne of the teeth counts must be nonzero")
  assert(is_bool(internal1), "\ninternal1 must be boolean")
  assert(is_bool(internal2), "\ninternal2 must be boolean")
  assert(is_finite(helical) && abs(helical)<90, str("\nhelical must be finite and strictly between -90 and 90 degrees; got ",helical))
  assert(!(internal1&&internal2), "\nCannot specify both gears as internal")
  assert(!(internal1 || internal2) || (teeth1>0 && teeth2>0), "\nCannot specify internal gear with rack (zero tooth count)")
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
// See Also: worm(), worm_gear(), globoid_worm_gear(), pitch_radius(), outer_radius()
// Usage: As a Function
//   value = auto_profile_shift(teeth, [pressure_angle], [helical], [min_teeth=], [get_min=], [profile_shift=]);
// Description:
//   Calculates the recommended profile shift to avoid gear tooth undercutting.  You can set `min_teeth` to a
//   value to allow small undercutting, and only activate the profile shift for more extreme cases. It is common
//   practice to make gears with 15-17 teeth with undercutting with the standard 20 deg pressure angle.
//   .
//   The `get_min` argument returns the minimum profile shift needed to avoid undercutting for the specified
//   number of teeth.  This will be a negative value for gears with a large number of teeth; such gears can
//   be given a negative profile shift without undercutting.  
// Arguments:
//   teeth = Total number of teeth in the gear.
//   pressure_angle = Normal pressure angle in degrees. Default: 20.
//   helical = Helix angle in degrees. Default: 0.
//   ---
//   min_teeth = Minimum tooth count with acceptable undercut. Default: calculated from pressure_angle and helical.
//   get_min = Return the minimum shift needed to avoid undercutting, including negative values for large gears. Default: false.
//   profile_shift = Return a supplied numerical value unchanged; otherwise calculate the recommended shift. Default: "auto".
function auto_profile_shift(
    teeth, pressure_angle, helical, _named, min_teeth, get_min, profile_shift
) =
    assert(is_undef(_named), "\nToo many positional arguments (only 3 are accepted)")
    let(pressure_angle=default(pressure_angle,20),
        helical=default(helical,0),
        get_min=default(get_min,false))
    assert(is_undef(profile_shift) || is_finite(profile_shift) || profile_shift=="auto", "\nProfile shift must be \"auto\" or a number")
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
//   value = gear_shorten(teeth1, teeth2, [helical], [profile_shift1], [profile_shift2], [pressure_angle=]);
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
    assert(is_undef(_named), "\nToo many positional arguments (only 5 are accepted)")
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
//   value = gear_shorten_skew(teeth1, teeth2, helical1, helical2, [profile_shift1], [profile_shift2], [pressure_angle=]);
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
//   pressure_angle = Normal pressure angle in degrees. Default: 20.
function gear_shorten_skew(
    teeth1, teeth2, helical1, helical2, profile_shift1, profile_shift2, _named, pressure_angle
) =
    assert(is_undef(_named), "\nToo many positional arguments (only 6 are accepted)")
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


// Function: worm_dist()
// Synopsis: Returns the center spacing between a cylindrical worm and its worm gear.
// Topics: Gears, Parts
// See Also: worm(), worm_gear(), globoid_worm_dist()
// Usage: As a Function
//   value = worm_dist([mod=|circ_pitch=|diam_pitch=], teeth, worm_diam|d=, [worm_starts=|starts=], [profile_shift=], [pressure_angle=], [backlash=]);
// Description:
//   Returns the center spacing between a cylindrical worm and its mating worm gear, produced by {{worm()}} and
//   {{worm_gear()}}. Use the same tooth size, `teeth`, `worm_diam` (or `worm_root_diam`), `worm_starts`,
//   `pressure_angle`, and `profile_shift` as the worm and worm gear. The default automatic
//   profile shift must agree with the worm gear's setting.  Positive backlash
//   moves the gears apart, targeting a total pitch-circle backlash of `2*backlash`.
//   .
//   Specify tooth size using `mod`, `circ_pitch`, or `diam_pitch` or inherit it.  
//   Positive `backlash` creates play by moving the axes farther apart. Use this or
//   tooth thinning, not both, to get the requested space.  For a double-enveloping
//   pair, use {{globoid_worm_dist()}} instead.
// Arguments:
//   teeth = Number of worm gear teeth.
//   worm_diam/d = Worm pitch diameter. Inherits when available.
//   ---
//   mod = Normal module.
//   diam_pitch = Normal diametral pitch, teeth per inch.
//   circ_pitch = Normal circular pitch.
//   worm_root_diam = Gives the worm root diameter, e.g. to ensure adequate space for a shaft.  An alternative to worm_diam or d. 
//   worm_starts/starts = Number of worm starts. Inherits when available. Default: 1
//   profile_shift = Worm-gear profile-shift coefficient. Profile shift is not inherited. Default: "auto"
//   pressure_angle = Normal pressure angle in degrees. Inherits from the parent when omitted.  Default: 20
//   clearance = Root-depth allowance used when worm_root_diam is supplied. Default: inherited from the matching worm family, otherwise module/4.
//   backlash = Increase spacing for total nominal worm gear backlash 2*backlash. Default: 0
function worm_dist(teeth,worm_diam,_named,worm_starts,profile_shift,pressure_angle,
                   mod,circ_pitch,diam_pitch,backlash,d,starts,worm_root_diam,clearance) =
    assert(is_undef(_named), "\nToo many positional arguments (only 2 are accepted)")
    let(worm_diam=_gear_worm_diameter(d,worm_diam,worm_root_diam=worm_root_diam,
            mod=mod,circ_pitch=circ_pitch,diam_pitch=diam_pitch,clearance=clearance,family=1),
        s=_gear_worm_starts(starts,worm_starts),
        cp=_inherit_gear_pitch("worm_dist()",circ_pitch,diam_pitch,mod),
        pa=_worm_pressure_angle(pressure_angle),
        ps=_wormgear_resolve_shift(cp/PI,teeth,worm_diam,s,pa,profile_shift),
        ref=_wormgear_reference(cp/PI,teeth,worm_diam,s,pa,ps))
    _wormgear_spacing(ref,default(backlash,0));
function _wormgear_spacing(ref,backlash) =
    assert(is_finite(x=backlash) && backlash>=0,
           "\nworm distance: backlash must be finite and nonnegative")
    // Avoid 0/0 at zero pressure angle when no spacing backlash was requested.
    backlash==0 ? ref[1] :
    assert(_worm_mean_slope(ref[3])>0,
           "\nworm distance: positive distance backlash requires pressure_angle > 0")
    ref[1]+backlash/_worm_mean_slope(ref[3]);


// Function: globoid_worm_dist()
// Synopsis: Returns the center spacing between a globoid worm and its worm gear.
// Topics: Gears, Parts
// See Also: globoid_worm(), globoid_worm_gear(), worm_dist()
// Usage:
//   value = globoid_worm_dist([mod=|circ_pitch=|diam_pitch=], teeth, worm_diam|d=, [worm_starts=|starts=]);
// Description:
//   Returns the center spacing between a globoid worm gear pair produced by {{globoid_worm()}} and {{globoid_worm_gear()}}.
//   Use the same tooth size, `teeth`, `worm_diam` (or `worm_root_diam`), and `worm_starts` as the worm gear.
//   The spacing is independent of `worm_length` and `pressure_angle`. Backlash is
//   set on the worm gear, not by increasing this distance. For a cylindrical pair,
//   use {{worm_dist()}} instead.
// Arguments:
//   teeth = Number of worm gear teeth.
//   worm_diam/d = Worm throat pitch diameter. Inherits when available.
//   ---
//   mod = Normal module.
//   diam_pitch = Normal diametral pitch, teeth per inch.
//   circ_pitch = Normal circular pitch.
//   worm_root_diam = Gives the worm root diameter, e.g. to ensure adequate space for a shaft.  An alternative to worm_diam or d. 
//   worm_starts/starts = Number of starts. Inherits when available. Default: 1
//   clearance = Root-depth allowance used when worm_root_diam is supplied. Default: inherited from the matching worm family, otherwise module/4.
function globoid_worm_dist(teeth,worm_diam,_named,mod,circ_pitch,diam_pitch,worm_starts,d,starts,worm_root_diam,
    clearance) =
    assert(is_undef(_named), "\nToo many positional arguments (only 2 are accepted)")
    let(worm_diam=_gear_worm_diameter(d,worm_diam,worm_root_diam=worm_root_diam,
            mod=mod,circ_pitch=circ_pitch,diam_pitch=diam_pitch,clearance=clearance,family=2),
        s=_gear_worm_starts(starts,worm_starts),
        m=_inherit_gear_pitch("globoid_worm_dist()",circ_pitch,diam_pitch,mod)/PI)
    assert(_globoid_check_reference(m,teeth,worm_diam,s), "\nInvalid gear parameters")
    worm_diam/2+m*teeth/(2*sqrt(1-pow(s*m/worm_diam,2)));


// Function: worm_outer_radius()
// Synopsis: Returns the nominal outside radius of a cylindrical worm.
// Topics: Gears, Parts
// See Also: worm(), worm_root_radius(), globoid_worm_outer_radius()
// Usage:
//   r = worm_outer_radius([mod=|circ_pitch=|diam_pitch=], [d|worm_diam=]);
// Description:
//   Returns the nominal outside radius of {{worm()}} before thread-end tapering
//   and crest rounding. The radius is the worm pitch radius plus the normal module.
// Arguments:
//   d/worm_diam = Worm pitch diameter. Inherits when available. Default: 15
//   ---
//   mod = Normal module; specify only one tooth-size measure.
//   diam_pitch = Normal diametral pitch, teeth per inch.
//   circ_pitch = Normal circular pitch.
//   worm_root_diam = Gives the worm root diameter, e.g. to ensure adequate space for a shaft.  An alternative to worm_diam or d. 
//   clearance = Root-depth allowance used when worm_root_diam is supplied. Default: inherited from the matching worm family, otherwise module/4.
// Example(3D): A cylindrical worm inside its nominal envelope.
//   m=2; d=24; L=35;
//   worm(mod=m,d=d,l=L);
//   %cyl(r=worm_outer_radius(mod=m,d=d),l=L);
function worm_outer_radius(d,_named,mod,circ_pitch,diam_pitch,worm_diam,worm_root_diam,clearance) =
    assert(is_undef(_named), "\nToo many positional arguments (only 1 is accepted)")
    let(d=_gear_worm_diameter(d,worm_diam,15,worm_root_diam=worm_root_diam,
            mod=mod,circ_pitch=circ_pitch,diam_pitch=diam_pitch,clearance=clearance,family=1),
        m=_inherit_gear_pitch("worm_outer_radius()",circ_pitch,diam_pitch,mod)/PI)
    assert(d>2*m, str("\nFor current tooth size, d must be greater than ",2*m,"; got ",d))
    d/2+m;

// Function: worm_root_radius()
// Synopsis: Returns the root radius of a cylindrical worm.
// Topics: Gears, Parts
// See Also: worm(), worm_outer_radius(), globoid_worm_root_radius()
// Usage:
//   r = worm_root_radius([mod=|circ_pitch=|diam_pitch=], d|worm_diam=, [clearance=], [pressure_angle=], [backlash=], [starts=|worm_starts=]);
// Description:
//   Returns the root radius of a cylindrical worm produced by {{worm()}}.  Use the same pitch diameter, tooth size,
//   `clearance`, `pressure_angle`, `backlash`, and start count as the worm.
//   Specify tooth size using `mod`, `circ_pitch`, or `diam_pitch`. If you don't give a tooth
//   size, it is inherited from the parent gear if available; otherwise, an error is displayed.
// Arguments:
//   d/worm_diam = Worm pitch diameter. Inherits when available.
//   ---
//   mod = Normal module; specify only one tooth-size measure.
//   diam_pitch = Normal diametral pitch, teeth per inch.
//   circ_pitch = Normal circular pitch.
//   worm_root_diam = Gives the worm root diameter, e.g. to ensure adequate space for a shaft.  An alternative to worm_diam or d. 
//   clearance = Requested extra thread-root depth, as supplied to {{worm()}}; the returned radius accounts for converging flanks. Inherits from a parent worm() or worm_gear() when omitted. Default: module/4
//   pressure_angle = Normal pressure angle in degrees. Default: inherited from the parent gear if available, 20 otherwise.
//   backlash = Gap between two meshing teeth, as supplied to {{worm()}}. Default: $backlash
//   starts/worm_starts = Number of worm starts. Inherits when available. Default: 1
// Example(3D): Shaft through a cylindrical worm.
//   m=2; d=24; L=35; 
//   shaft_r=worm_root_radius(mod=m,d=d,starts=5);
//   worm(mod=m,d=d,l=L,starts=5);
//   cyl(r=shaft_r,l=L+30,$fn=96);
function worm_root_radius(d,_named,mod,circ_pitch,diam_pitch,clearance,worm_diam,
                          pressure_angle,backlash,starts,worm_starts,worm_root_diam) =
    assert(is_undef(_named), "\nToo many positional arguments (only 1 is accepted)")
    let(d=_gear_worm_diameter(d,worm_diam,worm_root_diam=worm_root_diam,
            mod=mod,circ_pitch=circ_pitch,diam_pitch=diam_pitch,clearance=clearance,family=1),s=_gear_worm_starts(starts,worm_starts),
        m=_inherit_gear_pitch("worm_root_radius()",circ_pitch,diam_pitch,mod)/PI,
        c=default(clearance,default(_gear_worm_family($parent_gear_type)==1?$parent_gear_clearance:undef,m/4)),
        pa=_worm_pressure_angle(pressure_angle),ba=_gear_backlash(backlash))
    assert(is_int(s) && s>0, "\nstarts must be a positive integer")
    assert(is_finite(d) && d>max(2,s)*m,
           str("\nFor current parameters, d must be supplied and greater than ",max(2,s)*m,"; got ",d))
    assert(is_finite(c) && c>=0, str("\nclearance must be nonnegative and finite; got ",c))
    assert(d>2*(m+c), str("\nFor current tooth size and clearance, d must be greater than ",2*(m+c),
                         " to leave a positive nominal root radius; got ",d))
    assert(is_list(pa)?min(pa)>=0 && max(pa)<90:is_finite(pa) && pa>=0 && pa<90, "\npressure_angle must be at least zero and less than 90 degrees")
    assert(is_finite(ba) && ba>=0, "\nbacklash must be nonnegative and finite")
    d/2-_worm_thread_dedendum(m,asin(s*m/d),pa,c,ba);


// Function: globoid_worm_max_length()
// Synopsis: Returns the maximum supported globoid worm length.
// Topics: Gears, Parts
// See Also: globoid_worm(), globoid_worm_gear(), globoid_worm_root_radius(), globoid_worm_outer_radius()
// Usage:
//   length = globoid_worm_max_length([mod=|circ_pitch=|diam_pitch=], teeth, worm_diam|d=, [worm_starts=|starts=], [clearance=]);
// Description:
//   Returns the maximum supported length for {{globoid_worm()}} and its
//   mating {{globoid_worm_gear()}}. The returned number can be used directly as
//   the working length on both parts. Specifying `worm_length="max"`
//   selects the same value.
//   .
//   Use the same tooth size, mating tooth count, worm diameter, start count, and
//   clearance as the pair. Specify tooth size using `mod`, `circ_pitch`, or
//   `diam_pitch`, or inherit it from a parent gear.
// Arguments:
//   teeth = Number of teeth on the mating worm gear, at least 12. Inherits when available.
//   worm_diam/d = Worm throat pitch diameter. Inherits when available.
//   ---
//   mod = Normal module; specify only one tooth-size measure.
//   circ_pitch = Normal circular pitch.
//   diam_pitch = Normal diametral pitch, teeth per inch.
//   worm_root_diam = Gives the worm root diameter, e.g. to ensure adequate space for a shaft.  An alternative to worm_diam or d. 
//   worm_starts/starts = Number of worm starts. Inherits when available. Default: 1
//   clearance = Nominal root allowance. Inherits from a parent globoid worm or globoid worm gear when available. Default: module/4
// Example:
//   L = globoid_worm_max_length(mod=2, teeth=55, d=24, starts=5);
//   globoid_worm(mod=2, d=24, length=L, mate_teeth=55, starts=5);
function globoid_worm_max_length(teeth,worm_diam,_named,mod,circ_pitch,diam_pitch,
                                 d,worm_starts,starts,clearance,worm_root_diam) =
    assert(is_undef(_named), "\nToo many positional arguments (only 2 are accepted)")
    let(N=_gear_mate_teeth(teeth,undef),d=_gear_worm_diameter(d,worm_diam,worm_root_diam=worm_root_diam,
            mod=mod,circ_pitch=circ_pitch,diam_pitch=diam_pitch,clearance=clearance,family=2),
        s=_gear_worm_starts(starts,worm_starts),
        m=_inherit_gear_pitch("globoid_worm_max_length()",circ_pitch,diam_pitch,mod)/PI,
        c=default(clearance,default(_gear_worm_family($parent_gear_type)==2?$parent_gear_clearance:undef,m/4)))
    _globoid_length_limit(m,N,d,s,c);

// Function: globoid_worm_root_radius()
// Synopsis: Returns the root radius of a globoid worm at an axial position.
// Topics: Gears, Parts
// See Also: globoid_worm(), worm_root_radius(), globoid_worm_outer_radius(), globoid_worm_max_length()
// Usage:
//     r = globoid_worm_root_radius([mod=|circ_pitch=|diam_pitch=], teeth, worm_diam|d=, [worm_length=|l=|length=|h=|height=], [z=], [worm_starts=|starts=], [clearance=]);
// Description:
//   Returns the nominal root radius of {{globoid_worm()}} at the axial
//   location `z=`, measured from the worm's center. The radius is
//   smallest at `z=0` and increases toward either end of the hourglass.
//   Use the same `teeth`, `worm_diam`, start count, tooth size, and `clearance`
//   as the worm. Instead of `z=` you can specify `worm_length=` to get the
//   radius at the end of the worm.  Giving `length="max"` uses selects the maximum
//   supported worm length. 
// Arguments:
//   teeth = Number of teeth on the mating worm gear, at least 12. Inherits when available.
//   worm_diam/d = Worm throat pitch diameter. Inherits when available.
//   ---
//   mod = Normal module; specify only one tooth-size measure.
//   diam_pitch = Normal diametral pitch, teeth per inch.
//   circ_pitch = Normal circular pitch.
//   worm_root_diam = Gives the worm root diameter, e.g. to ensure adequate space for a shaft.  An alternative to worm_diam or d. 
//   worm_length/l/length/h/height = Worm length, or "max" for the maximum supported length. Inherits when available.
//   z = Local axial position measured from the worm's center. Default: `worm_length/2` if worm_length is given or inherited.  
//   worm_starts/starts = Number of starts on the worm. Inherits when available. Default: 1
//   clearance = Nominal extra root-depth allowance at the throat, as supplied to {{globoid_worm()}}. Inherits from a parent globoid worm or globoid worm gear when available. Default: module/4
// Example(3D): Add end shafts to a globoid worm
//   m=2; N=55; d=24; s=5; L=35;
//   extension=20;
//   shaft_r=globoid_worm_root_radius(mod=m,N,d,worm_starts=s, worm_length=L);
//   globoid_worm(mod=m,d,L,teeth=N,starts=s)
//     attach([BOT,TOP],BOT)
//       cyl(r=shaft_r,l=extension,$fn=96);
// Example(3D): Create a hole in the globoid worm with a safe wall thickness at the center (z=0)
//   m=2; N=55; d=24; s=5; L=35;
//   wall = 2;  // 2 unit minimum wall thickness
//   shaft_r=globoid_worm_root_radius(mod=m,N,d,worm_starts=s,z=0)-wall;
//   difference(){
//     globoid_worm(mod=m,d,L,teeth=N,starts=s);
//     cyl(r=shaft_r,l=2*L,$fn=96);
//   }
function globoid_worm_root_radius(teeth,worm_diam,_named,z,worm_starts,clearance,
                                  mod,circ_pitch,diam_pitch,d,starts,worm_length,l,length,h,height,
    worm_root_diam) =
    assert(is_undef(_named), "\nToo many positional arguments (only 2 are accepted)")
    let(N=_gear_mate_teeth(teeth,undef),d=_gear_worm_diameter(d,worm_diam,worm_root_diam=worm_root_diam,
            mod=mod,circ_pitch=circ_pitch,diam_pitch=diam_pitch,clearance=clearance,family=2),
        s=_gear_worm_starts(starts,worm_starts),
        m=_inherit_gear_pitch("globoid_worm_root_radius()",circ_pitch,diam_pitch,mod)/PI,
        c=default(clearance,default(_gear_worm_family($parent_gear_type)==2?$parent_gear_clearance:undef,m/4)),
        L=_globoid_length(worm_length,l,length,h,height))
    _globoid_worm_radius(N,d,m,s,c,L,z,false);

/// Root and crest queries share axial selection and validation. The radius is
/// nominal (before finishing), not a sampled polyhedron extremum.
function _globoid_worm_radius(N,d,m,s,c,length,z,outer) =
    let(L=_globoid_resolve_length(length,m,N,d,s,c,required=false),
        z=default(z,is_undef(L)?undef:L/2),
        R=m*N/(2*sqrt(1-pow(s*m/d,2))),a=R+d/2,
        meridian=outer?R-m:R+m+c)
    assert(is_def(z), "\nMust give a working length or z position")
    assert(is_finite(z), str("\nz must be finite; got ",z))
    assert(is_undef(L) || abs(z)<=L/2,
           str("\nz must be between ",-default(L,0)/2," and ",default(L,0)/2,
               " for the supplied worm_length; got ",z))
    assert(abs(z)<meridian,
           str("\nFor current parameters, abs(z) must be less than ",meridian,"; got ",z))
    a-sqrt(meridian*meridian-z*z);

// Function: globoid_worm_outer_radius()
// Synopsis: Returns the nominal outer radius of a globoid worm at an axial position.
// Topics: Gears, Parts
// See Also: globoid_worm(), globoid_worm_root_radius(), globoid_worm_max_length(), globoid_worm_gear_radius_bound()
// Usage:
//   r = globoid_worm_outer_radius([mod=|circ_pitch=|diam_pitch=], teeth, worm_diam|d=, [worm_length=|l=|length=|h=|height=], [z=], [worm_starts=|starts=], [clearance=]);
// Description:
//   Returns the nominal outer radius of {{globoid_worm()}} at the axial
//   location `z=`, measured from the worm's center. The radius is
//   smallest at `z=0` and increases toward either end of the hourglass.
//   Use the same `teeth`, `worm_diam`, start count, tooth size, and `clearance`
//   as the worm. Instead of `z=` you can specify `worm_length=` to get the
//   radius at the end of the worm.  Giving `length="max"` uses selects the maximum
//   supported worm length.
//   .
//   The radius ignores end taper and crest rounding.  
//   Use the same tooth count, diameter, and starts as the
//   worm. The clearance is used when calculating the maximum length. 
// Arguments:
//   teeth = Number of teeth on the mating worm gear, at least 12. Inherits when available.
//   worm_diam/d = Worm throat pitch diameter. Inherits when available.
//   ---
//   mod = Normal module; specify only one tooth-size measure.
//   circ_pitch = Normal circular pitch.
//   diam_pitch = Normal diametral pitch, teeth per inch.
//   worm_root_diam = Gives the worm root diameter, e.g. to ensure adequate space for a shaft.  An alternative to worm_diam or d. 
//   worm_length/l/length/h/height = Working length, or "max" for the maximum supported length. Inherits when available.
//   z = Local axial position from the worm's middle plane. Default: half the supplied or inherited working length.
//   worm_starts/starts = Number of worm starts. Inherits when available. Default: 1
//   clearance = Nominal root allowance used for the working-length limit. Inherits from a parent globoid worm or globoid worm gear when available. Default: module/4
// Example(3D): A nominal enclosing cylinder around a long globoid worm.
//   m=2; N=55; d=24; s=5; L=60;
//   r=globoid_worm_outer_radius(mod=m, teeth=N, d=d, starts=s, length=L);
//   globoid_worm(mod=m, d=d, length=L, mate_teeth=N, starts=s);
//   %cyl(r=r+0.5, l=L);
function globoid_worm_outer_radius(teeth,worm_diam,_named,z,worm_starts,clearance,
                                   mod,circ_pitch,diam_pitch,d,starts,worm_length,l,length,h,height,
    worm_root_diam) =
    assert(is_undef(_named), "\nToo many positional arguments (only 2 are accepted)")
    let(N=_gear_mate_teeth(teeth,undef),d=_gear_worm_diameter(d,worm_diam,worm_root_diam=worm_root_diam,
            mod=mod,circ_pitch=circ_pitch,diam_pitch=diam_pitch,clearance=clearance,family=2),
        s=_gear_worm_starts(starts,worm_starts),
        m=_inherit_gear_pitch("globoid_worm_outer_radius()",circ_pitch,diam_pitch,mod)/PI,
        c=default(clearance,default(_gear_worm_family($parent_gear_type)==2?$parent_gear_clearance:undef,m/4)),
        L=_globoid_length(worm_length,l,length,h,height))
    _globoid_worm_radius(N,d,m,s,c,L,z,true);


// Function: globoid_worm_radius_bound()
// Synopsis: Returns a taper-aware upper bound on the outside radius of a globoid worm.
// Topics: Gears, Parts
// See Also: globoid_worm(), globoid_worm_outer_radius(), globoid_worm_root_radius(), globoid_worm_max_length()
// Usage:
//   r = globoid_worm_radius_bound([mod=|circ_pitch=|diam_pitch=], [teeth], [worm_diam|d=], [worm_length=|l=|length=|h=|height=], [worm_starts=|starts=], [pressure_angle=], [clearance=], [lead_in=], [rounding=], [mesh_tol=], [steps=]);
// Description:
//   Returns an upper bound on the outer radius of the entire worm produced by {{globoid_worm()}} taking
//       into account the thread termination and tapering.
//   Use this radius to size a cylindrical space around the whole worm. Unlike
//   {{globoid_worm_outer_radius()}}, which returns a nominal radius at an axial
//   position or length, this calculation accounts for the reduced thread height
//   and width near the ends.
//       .
//   Specify tooth size using `mod`, `circ_pitch`, or `diam_pitch`, or inherit it
//   from a parent gear. The tooth count, throat pitch diameter, and working
//   length must also be supplied or inherited. Give the same pressure angle,
//   clearance, lead-in, rounding, and surface-detail tolerance as the worm.  Handedness does not change the bound.
// Arguments:
//   teeth = Number of teeth on the mating worm gear, at least 12. Inherits when available.
//   worm_diam/d = Worm pitch diameter at the throat. Inherits when available.
//   ---
//   mod = Normal module; specify only one tooth-size measure.
//   circ_pitch = Normal circular pitch.
//   diam_pitch = Normal diametral pitch, teeth per inch.
//   worm_length/l/length/h/height = Working worm length, or "max" for the maximum supported length. Inherits when available.
//   worm_starts/starts = Number of worm starts. Inherits when available. Default: 1
//   pressure_angle = Normal pressure angle, or [pa_bot, pa_top] pair, in degrees. Inherits when available. Default: 20
//   clearance = Nominal extra root depth at the throat. Inherits from a parent globoid worm or globoid worm gear when available. Default: module/4
//   lead_in = Length of the thread taper at each end, or zero for an abrupt cutoff. Does not inherit. Default: 2*module+clearance
//   rounding = Maximum crest and root rounding, matching the worm. Does not inherit. Default: 0
//   mesh_tol = Surface-detail tolerance used by the worm. Used here only to reproduce its thread-end inset. Does not inherit. Default: module/100
//   steps = Positive integer number of conservative taper intervals. Default: 32
// Example(3D): Size a cylindrical space around a tapered globoid worm.
//   m=2; N=55; d=24; s=5; L=60; pa=20;
//   r=globoid_worm_radius_bound(mod=m, teeth=N, d=d, starts=s,
//                               length=L, pressure_angle=pa);
//   globoid_worm(mod=m, d=d, length=L, mate_teeth=N, starts=s,
//                pressure_angle=pa);
//   %cyl(r=r+0.5, l=L);
function globoid_worm_radius_bound(teeth,worm_diam,_named,
    mod,circ_pitch,diam_pitch,d,starts,worm_starts,
    worm_length,l,length,h,height,pressure_angle,clearance,
    lead_in,rounding=0,mesh_tol,steps=32) =
    assert(is_undef(_named), "\nToo many positional arguments (only 2 are accepted)")
    let(steps=default(steps,32))
    assert(is_int(steps) && steps>0, "\nsteps must be a positive integer")
    let(N=_gear_mate_teeth(teeth,undef),d=_gear_worm_diameter(d,worm_diam),
        s=_gear_worm_starts(starts,worm_starts),
        L=_globoid_length(worm_length,l,length,h,height),
        P=_dew_parameters(N,d,mod,circ_pitch,diam_pitch,s,L,pressure_angle,clearance,false),
        tol=default(mesh_tol,P[0]/100))
    assert(_dew_mesh_tolerance(tol,P), "\nInvalid mesh tolerance")
    let(rd=_gw_round_data(P,default(rounding,0),tol),constants=_gw_constants(P),
        B=concat(P,[constants,undef,rd]),
        lead=_gw_lead_data(B,default(lead_in,2*P[0]+P[9]),tol),
        Q=concat(P,[constants,lead,rd]))
    _globoid_bound(Q,steps);


function _globoid_bound_value(T,b,tr,h,w,beta,side,p,a) =
    let(X=tr+(T-tr)*h,Z=side*w*(T*sin(beta)-b*cos(beta)),
        U=sqrt(max(0,X*X+b*b-Z*Z)),g=side*w*sin(beta))
    [a-U*cos(p)+Z*sin(p),-cos(p)*(h*X-g*Z)/U+g*sin(p)];

/// At fixed scales and phase the flank radius is a linear term minus the
/// square root of a quadratic. Its curvature has constant sign. Endpoints and
/// the (at most one) concave stationary maximum therefore suffice.
function _globoid_bound_flank(b,tr,tt,beta,side,h,w,p,a) =
    let(f0=_globoid_bound_value(tt,b,tr,h,w,beta,side,p,a),
        f1=_globoid_bound_value(tr,b,tr,h,w,beta,side,p,a),
        g=side*w*sin(beta),j=-side*w*b*cos(beta),d=(1-h)*tr,
        A=h*h-g*g,B=2*(h*d-g*j),
        D=4*((h*h-g*g)*b*b-pow(h*j-g*d,2)),s=g*tan(p),den=A-s*s,
        interior=D>0 && den>0 && A>0 && f0[1]>0 && f1[1]<0,
        t=interior?constrain((s*sqrt(D/den)-B)/(2*A),tt,tr):tt)
    max(f0[0],f1[0],interior?_globoid_bound_value(t,b,tr,h,w,beta,side,p,a)[0]:f0[0]);

function _globoid_bound_symmetric(Q,steps) =
    let(a=Q[4],lead=Q[12],er=Q[3]+Q[0]+Q[9],b=Q[7],
        tr=Q[11][6],tt=Q[11][7],beta=90/Q[1]+Q[6]+Q[13][2],
        root=a-sqrt(er*er-Q[8]*Q[8]),
        vals=lead[1]==0?
            [_globoid_bound_flank(b,tr,tt,beta,1,1,1,lead[0],a)]:
            [for(i=[0:steps-1])
                let(p0=lead[0]-lead[1]+lead[1]*i/steps,
                    p1=lead[0]-lead[1]+lead[1]*(i+1)/steps,
                    sc=_gw_lead_scales(p0,lead))
                _globoid_bound_flank(b,tr,tt,beta,1,sc.y,sc.x,p1,a)])
    max(root,max(vals));

/// Asymmetric radial flattening is enclosed by meridional straight-line
/// flattening on each flank (convexity of Euclidean norm). Both actual taper
/// ends are retained; do not replace their displaced center by zero.
function _globoid_bound_asymmetric(Q,steps) =
    let(a=Q[4],lead=Q[12],er=Q[3]+Q[0]+Q[9],et=Q[3]-Q[0],pivot=Q[11][4],
        root=a-sqrt(er*er-Q[8]*Q[8]),
        base=[for(flank=[0,1],end=[-1,1])
            let(b=Q[7][flank],tr=sqrt(er*er-b*b),tt=sqrt(et*et-b*b),
                beta=90/Q[1]+Q[6][flank]+(flank==0?pivot:-pivot)+Q[13][2],
                side=flank==0?-1:1,p=lead[4]+end*(lead[0]-lead[1])+pivot)
            _globoid_bound_flank(b,tr,tt,beta,side,1,1,p,a)],
        vals=lead[1]==0?base:concat(base,
            [for(i=[0:steps-1])
                let(d0=lead[0]-lead[1]+lead[1]*i/steps,
                    d1=lead[0]-lead[1]+lead[1]*(i+1)/steps,
                    sc0=_gw_lead_scales(lead[4]+d0,lead),
                    sc1=_gw_lead_scales(lead[4]+d1,lead))
                for(flank=[0,1],end=[-1,1],width=[sc0.x,sc1.x],dist=[d0,d1])
                    let(b=Q[7][flank],tr=sqrt(er*er-b*b),tt=sqrt(et*et-b*b),
                        beta=90/Q[1]+Q[6][flank]+(flank==0?pivot:-pivot)+Q[13][2],
                        side=flank==0?-1:1,p=lead[4]+end*dist+pivot)
                    _globoid_bound_flank(b,tr,tt,beta,side,sc0.y,width,p,a)]))
    max(root,max(vals));

function _globoid_bound(Q,steps) =
    min(_dew_worm_radius(Q[3]-Q[0],Q[8],Q),
        _gaw_asymmetric(Q)?_globoid_bound_asymmetric(Q,steps):_globoid_bound_symmetric(Q,steps));




// Function: worm_gear_radius_bound()
// Synopsis: Returns an upper bound on the outside radius of a cylindrical worm gear.
// Topics: Gears, Parts
// See Also: worm_gear(), worm_dist(), globoid_worm_gear_radius_bound()
// Usage:
//   r = worm_gear_radius_bound([mod=|circ_pitch=|diam_pitch=], teeth, [thickness], worm_diam=|d=, [worm_starts=|starts=], [pressure_angle=], [profile_shift=]);
// Description:
//   Returns an upper bound on the outside radius of {{worm_gear()}}.  The worm
//   may be smaller than the bound due to tip trimming.  
//   .
//   Use the same tooth size, tooth count, worm diameter, start count, thickness,
//   pressure angle, and profile shift as the worm gear.
// Arguments:
//   teeth = Number of worm gear teeth, greater than 7. Inherits from a parent worm gear when available.
//   thickness = Full axial thickness. Inherits thickness from any parent that provides it. Default: worm_diam/2
//   ---
//   worm_diam/d = Mating worm pitch diameter. Inherits when available.
//   mod = Normal module; specify only one tooth-size measure.
//   circ_pitch = Normal circular pitch.
//   diam_pitch = Normal diametral pitch, teeth per inch.
//   worm_root_diam = Gives the worm root diameter, e.g. to ensure adequate space for a shaft.  An alternative to worm_diam or d. 
//   worm_starts/starts = Number of worm starts. Inherits when available. Default: 1
//   pressure_angle = Normal pressure angle in degrees. Inherits when available. Default: 20
//   profile_shift = Worm-gear profile-shift coefficient. Profile shift is not inherited. Default: "auto"
//   clearance = Root-depth allowance used when worm_root_diam is supplied. Default: inherited from the matching worm family, otherwise module/4.
// Example(3D): Size a cylindrical space around a worm gear.
//   m=2; N=55; d=24; s=5; t=12;
//   r=worm_gear_radius_bound(mod=m, teeth=N, thickness=t, worm_diam=d, starts=s);
//   worm_gear(mod=m, teeth=N, thickness=t, worm_diam=d, worm_starts=s);
//   %cyl(r=r+0.5, l=t);
function worm_gear_radius_bound(teeth,thickness,_named,worm_diam,d,worm_starts,starts,
                                mod,circ_pitch,diam_pitch,pressure_angle,profile_shift,worm_root_diam,clearance) =
    assert(is_undef(_named), "\nToo many positional arguments (only 2 are accepted)")
    let(N=_gear_mate_teeth(teeth,undef),d=_gear_worm_diameter(d,worm_diam,worm_root_diam=worm_root_diam,
            mod=mod,circ_pitch=circ_pitch,diam_pitch=diam_pitch,clearance=clearance,family=1),
        s=_gear_worm_starts(starts,worm_starts),
        m=_inherit_gear_pitch("worm_gear_radius_bound()",circ_pitch,diam_pitch,mod)/PI,
        pa=_worm_pressure_angle(pressure_angle),
        ps=_wormgear_resolve_shift(m,N,d,s,pa,profile_shift),
        ref=_wormgear_reference(m,N,d,s,pa,ps),
        H=_wormgear_halfwidth(m,d,thickness),r=d/2-m)
    ref[1]-sqrt(r*r-H*H);

// Function: globoid_worm_gear_radius_bound()
// Synopsis: Returns an upper bound on the outside radius of a globoid worm gear.
// Topics: Gears, Parts
// See Also: globoid_worm_gear(), globoid_worm_outer_radius(), globoid_worm_max_length(), worm_gear_radius_bound()
// Usage:
//   r = globoid_worm_gear_radius_bound([mod=|circ_pitch=|diam_pitch=], teeth, [thickness], worm_diam=|d=, [worm_length=|l=|length=|h=|height=], [worm_starts=|starts=], [clearance=]);
// Description:
//   Returns an upper bound on the outside radius of {{globoid_worm_gear()}}.
//   The bound uses the full-height outer envelope,
//   before minimum-tip trimming, crowning, rounding, and chamfering, which can
//   all shrink the size of the worm gear.  
//   .
//   Use the same tooth size, tooth count, worm diameter, start count, working
//   length, and gear thickness as the pair. Giving `worm_length="max"` selects
//   the same supported length as the constructors, using the supplied clearance.
//   Specify tooth size using `mod`, `circ_pitch`, or `diam_pitch`, or inherit it
//   from a parent gear.
// Arguments:
//   teeth = Number of worm gear teeth, at least 12. Inherits when available.
//   thickness = Full axial thickness. Inherits thickness from any parent that provides it. Default: worm_diam/2
//   ---
//   worm_diam/d = Mating worm throat pitch diameter. Inherits when available.
//   worm_root_diam = Gives the worm root diameter, e.g. to ensure adequate space for a shaft.  An alternative to worm_diam or d. 
//   mod = Normal module; specify only one tooth-size measure.
//   circ_pitch = Normal circular pitch.
//   diam_pitch = Normal diametral pitch, teeth per inch.
//   worm_length/l/length/h/height = Working worm length, or "max" for the maximum supported length. Inherits when available.
//   worm_starts/starts = Number of worm starts. Inherits when available. Default: 1
//   clearance = Nominal root allowance used for the working-length limit. Inherits from a parent globoid worm or globoid worm gear when available. Default: module/4
// Example(3D): Size a cylindrical space around a globoid worm gear.
//   m=2; N=55; d=24; s=5; L=35; t=12;
//   r=globoid_worm_gear_radius_bound(mod=m, teeth=N, thickness=t, d=d, starts=s, length=L);
//   globoid_worm_gear(mod=m, teeth=N, thickness=t, worm_diam=d, worm_starts=s, worm_length=L);
//   %cyl(r=r+0.5, l=t);
function globoid_worm_gear_radius_bound(teeth,thickness,_named,worm_diam,d,worm_starts,starts,
                                        mod,circ_pitch,diam_pitch,clearance,
                                        worm_length,l,length,h,height,worm_root_diam) =
    assert(is_undef(_named), "\nToo many positional arguments (only 2 are accepted)")
    let(N=_gear_mate_teeth(teeth,undef),d=_gear_worm_diameter(d,worm_diam,worm_root_diam=worm_root_diam,
            mod=mod,circ_pitch=circ_pitch,diam_pitch=diam_pitch,clearance=clearance,family=2),
        s=_gear_worm_starts(starts,worm_starts),
        m=_inherit_gear_pitch("globoid_worm_gear_radius_bound()",circ_pitch,diam_pitch,mod)/PI,
        c=default(clearance,default(_gear_worm_family($parent_gear_type)==2?$parent_gear_clearance:undef,m/4)),
        L=_globoid_resolve_length(_globoid_length(worm_length,l,length,h,height),m,N,d,s,c),
        H=L/2,w=_wormgear_halfwidth(m,d,thickness),
        R=m*N/(2*sqrt(1-pow(s*m/d,2))),a=R+d/2,
        r=a-sqrt(pow(R+m,2)-H*H))
    // Same untrimmed axial-face envelope as _dew_rim(R+m,w,P).
    sqrt(pow(a-sqrt(r*r-w*w),2)+H*H);


// Function: globoid_worm_pressure_angle_limit()
// Synopsis: Returns the permitted pressure-angle limit with the other flank fixed.
// Topics: Gears, Parts
// See Also: globoid_worm(), globoid_worm_gear()
// Usage:
//   limit = globoid_worm_pressure_angle_limit(angle, teeth=, worm_diam=, mod=|circ_pitch=|diam_pitch=, [worm_starts=], [clearance=]);
// Description:
//   Returns the maximum pressure angle, for one flank of an
//   asymmetric globoid when the other flank angle is given.  
//   Keep the chosen angle below this limit. 
//   .
//   Clearance reduces the available tip and root space, so pass the clearance used
//   for the actual pair. The limit also depends on tooth count, tooth size, worm
//   diameter and start count. It does not depend on worm length or handedness.
//   .
//   Returns undef if no positive angle can satisfy this profile check with the
//   other angle fixed. In that case change the other angle, clearance or dimensions.
// Arguments:
//   angle = Pressure angle of a tooth flank, strictly between 0 and 90 degrees.
//   ---
//   teeth/mate_teeth = Number of teeth on the mating wheel; integer at least 12. Inherits when available.
//   worm_diam/d = Worm pitch diameter at the throat. Inherits when available.
//   worm_root_diam = Nominal minimum throat root diameter; alternative to worm_diam or d.
//   mod/circ_pitch/diam_pitch = Matching normal tooth size; inherits when available.
//   worm_starts/starts = Worm start count; inherits when available. Default: 1.
//   clearance = Matching root-clearance allowance. Default: inherited from a globoid parent or module/4.
// Example: Limit the first flank while retaining the second.
//   m=2; n=20; d=16; s=1; c=.5; fixed_angle=.1;
//   limit=globoid_worm_pressure_angle_limit(fixed_angle,mod=m,teeth=n,
//                                          worm_diam=d,worm_starts=s,clearance=c);
//   assert(is_def(limit),"Revise the fixed angle or dimensions");
//   pa=[min(45,.999*limit),fixed_angle];
//   globoid_worm(mod=m,teeth=n,d=d,starts=s,pressure_angle=pa,
//                clearance=c,worm_length="max");
function globoid_worm_pressure_angle_limit(angle,_named,teeth,mate_teeth,
                                         worm_diam,d,worm_root_diam,mod,circ_pitch,diam_pitch,
                                         worm_starts,starts,clearance) =
    assert(is_undef(_named),"\nToo many positional arguments (only 1 is accepted)")
    assert(is_finite(angle) && angle>0 && angle<90,
           "\nangle must be greater than zero and less than 90 degrees")
    let(m=_inherit_gear_pitch("globoid_worm_pressure_angle_limit()",circ_pitch,diam_pitch,mod)/PI,
        N=_gear_mate_teeth(teeth,mate_teeth),s=_gear_worm_starts(starts,worm_starts),
        c=default(clearance,default(_gear_worm_family($parent_gear_type)==2?$parent_gear_clearance:undef,m/4)),
        dia=_gear_worm_diameter(d,worm_diam,worm_root_diam=worm_root_diam,
                   mod=mod,circ_pitch=circ_pitch,diam_pitch=diam_pitch,clearance=c,family=2))
    assert(_globoid_length_limit(m,N,dia,s,c)>0,"\nInvalid globoid reference dimensions")
    let(cb=sqrt(1-pow(s*m/dia,2)),R=m*N/(2*cb),angles=[0,angle],
        at=[for(a=angles)atan(tan(a)/cb)],
        P=[m,N,dia/2,R,R+dia/2,s/N,at,[for(a=at)R*sin(a)],0,c,s])
    _gaw_profile_valid(P,angles)?_gaw_angle_limit(P,angles,0):undef;




// Function: worm_face_dist()
// Synopsis: Returns the vertical distance between a worm face gear and a worm. 
// Topics: Gears, Parts
// See Also: worm_face_gear(), worm_face_gear_worm_pos(), worm_face_gear_worm_spin()
// Usage:
//   height = worm_face_dist([worm_diam|d=]);
//   height = worm_face_dist(worm_root_diam=, mod=|circ_pitch=|diam_pitch=, [clearance=]);
// Description:
//   Returns half the cylindrical worm's pitch diameter. This is the distance along the face-gear
//   shaft from its "pitchplane" anchor to the worm axis, perpendicular to that axis.
//   Shaft offset is a separate dimension, available from worm_face_gear_info(). Backing and tooth thinning do not
//   change this mounting height. This helper does not supply axial centering or tooth phase.
//   .
//   Alternatively, supply worm_root_diam instead of worm_diam or d. It specifies a nominal
//   minimum worm-core diameter and resolves to worm_diam = worm_root_diam + 2*(module + clearance).
//   Cylindrical valleys that close early can leave a larger actual core.
//   An explicit root diameter overrides an inherited pitch diameter; explicit diameter alternatives
//   are mutually exclusive. Use the same clearance for the worm, wheel and placement helpers.
// Arguments:
//   worm_root_diam = Positive nominal minimum worm-core diameter; alternative to worm_diam or d. Uses tooth size and clearance; does not cut a bore.
//   mod/circ_pitch/diam_pitch = Normal tooth size, required or inherited when worm_root_diam is supplied.
//   clearance = Root-depth allowance used when worm_root_diam is supplied. Default: inherited from the matching worm family, otherwise module/4.
//   worm_diam/d = Worm pitch diameter. Inherits when available.
// Example:
//   height = worm_face_dist(20);  // 10

function worm_face_dist(worm_diam,_named,d,worm_root_diam,mod,circ_pitch,diam_pitch,clearance) =
    assert(is_undef(_named),"\nToo many positional arguments (only 1 is accepted)")
    let(d=_gear_worm_diameter(d,worm_diam,worm_root_diam=worm_root_diam,
            mod=mod,circ_pitch=circ_pitch,diam_pitch=diam_pitch,clearance=clearance,family=1))
    assert(is_finite(d) && d>0,"\nworm_diam must be positive and finite") d/2;

// Function: worm_face_gear_info()
// Synopsis: Resolves the dimensions and manual placement of a worm face drive.
// Topics: Gears, Parts
// See Also: worm_face_gear(), worm_face_gear_radius_bound(), worm_face_gear_worm_pos(), worm_face_gear_worm_spin()
// Usage:
//   info = worm_face_gear_info(teeth, worm_diam, mod=|circ_pitch=|diam_pitch=, [shaft_offset=], [gear_diam=], [face_width=], [worm_starts=], [pressure_angle=], [left_handed=], [clearance=], [backlash=], [min_tip=], [shift=], [angle=], [gear_spin=]);
// Description:
//   Returns a struct containing the resolved layout, without constructing a mesh.
//   Use struct_val(info,key) to retrieve a value. The same sizing parameters and
//   inheritance rules apply as for worm_face_gear(). Undefined shaft_offset and
//   gear_diam are calculated automatically. Explicit dimensions are preserved.
//   Pass the same clearance, backlash and min_tip to the gear and this helper.
//   .
//   The keys are "gear_diam" (outside diameter), "shaft_offset", "face_width",
//   "band_radius" (middle of the radial tooth band), "mesh_center", "worm_pos", "worm_spin",
//   "thread_span" and "overlap". The first three dimensions can be passed back
//   to worm_face_gear() to reuse the layout without repeating the sizing search.
//   .
//   The `worm_pos` and `worm_spin` parameters give the manual placement in the face gear's
//   pitch-plane frame. Translate to "worm_pos", rotate about Z by angle-90, then
//   yrot(90) the worm and give it the returned "worm_spin" as its `gear_spin`.
//   The "mesh_center" is a point on the worm axis at the midpoint of the required axial
//   working span. It is independent of shift and worm length, and is not a tooth-contact
//   point. With shift=0, worm_pos equals mesh_center. Positive shift moves worm_pos
//   along the worm's Z+ shaft. Both positions include the mounting angle.
//   thread_span is the conservative interval on the worm's native Z axis that
//   must have full-height threads. Allow additional length for its tapered ends.
//   attach_gear() checks both end coverage and opposite-side separation.
//   .
//   overlap is the band's projected axial width divided by the worm's axial
//   thread pitch. It is a geometric overlap estimate, not a loaded contact ratio
//   or a strength rating. See worm_face_gear() for the automatic sizing criteria.
// Arguments:
//   teeth = Face-gear tooth count, required or inherited from a face gear.
//   worm_diam = Mating worm pitch diameter; inherits when available.
//   ---
//   worm_root_diam = Nominal minimum worm-core diameter; alternative to worm_diam.
//   mod/circ_pitch/diam_pitch = Matching normal tooth size; inherits when available.
//   shaft_offset = Nonnegative shaft-axis separation; inherits from a face gear, otherwise calculated.
//   gear_diam = Wheel outside diameter; inherits from a face gear, otherwise calculated.
//   face_width = Radial tooth-band width; inherits from a face gear, otherwise three axial thread pitches.
//   worm_starts = Worm start count. Default: inherited or 1.
//   pressure_angle = Matching scalar or ordered pressure-angle pair. Default: inherited or 20.
//   left_handed = Worm handedness. Default: inherited or false.
//   clearance = Matching root clearance. Default: inherited or module/4.
//   backlash = Matching circumferential tooth thinning. Default: inherited from a face gear or $backlash.
//   min_tip = Matching minimum circumferential tooth-tip chord. Default: inherited from a face gear or 0.4*module.
//   shift = Signed distance to move the worm along its native Z+ shaft from centered engagement, as for a worm child in attach_gear(). Default: 0.
//   angle = Mounting azimuth as for a face-gear parent in attach_gear(). Default: 90.
//   gear_spin = Face-gear tooth rotation. Default: 0.
// Example(3D): Resolve once, then build a manually positioned pair.
//   m=3; n=47; d=45;
//   info=worm_face_gear_info(teeth=n,mod=m,worm_diam=d,backlash=.2);
//   worm_face_gear(teeth=n,mod=m,worm_diam=d,backlash=.2,
//       gear_diam=struct_val(info,"gear_diam"),
//       shaft_offset=struct_val(info,"shaft_offset"),
//       face_width=struct_val(info,"face_width"));
//   move(struct_val(info,"worm_pos")) yrot(90)
//       worm(mod=m,d=d,l=120,gear_spin=struct_val(info,"worm_spin"));
function worm_face_gear_info(teeth,worm_diam,_named,mod,circ_pitch,diam_pitch,
                            worm_starts,shaft_offset,gear_diam,face_width,pressure_angle,
                            left_handed,clearance,backlash,min_tip,worm_root_diam,
                            shift,angle=90,gear_spin=0) =
    assert(is_undef(_named),"\nToo many positional arguments (only 2 are accepted)")
    let(shift=default(shift,0))
    assert(is_finite(shift) && is_finite(angle) && is_finite(gear_spin),"\nshift, angle and gear_spin must be finite")
    let(P=_wfg_arguments(teeth,worm_diam,worm_starts,shaft_offset,face_width,pressure_angle,
                        clearance,backlash,min_tip,mod,circ_pitch,diam_pitch,worm_root_diam,left_handed,gear_diam),
        F=P[0],lh=default(left_handed,default($parent_gear_left_handed,false)),q=lh?-1:1,
        mesh=_wfg_mesh_center(P,lh),station=mesh.x+shift,span=_wfg_span(P),
        phase=90+F[1]/F[3]*(90-F[10])+_wfg_center_phase(P)
            +q*F[1]/F[3]*(gear_spin-angle+90)+q*shift/F[6]*180/PI)
    [["gear_diam",2*P[4]],["shaft_offset",F[4]],["face_width",P[4]-P[3]],
     ["band_radius",F[9]],["mesh_center",zrot(angle-90,p=mesh)],
     ["worm_pos",zrot(angle-90,p=[station,F[4],F[2]])],
     ["worm_spin",phase-(360/F[3])*round(phase/(360/F[3]))],
     ["thread_span",sort([q*span[0]-station,q*span[1]-station])],
     ["overlap",_wfg_overlap(P)]];


// Function: worm_face_gear_radius_bound()
// Synopsis: Returns the outside radius of a worm face gear.
// Topics: Gears, Parts
// See Also: worm_face_gear(), worm_face_dist()
// Usage:
//   radius = worm_face_gear_radius_bound(teeth, worm_diam, mod=|circ_pitch=|diam_pitch=, [shaft_offset=], [gear_diam=], [worm_starts=], [face_width=], [pressure_angle=], [clearance=], [backlash=], [min_tip=]);
// Description:
//   Returns the actual outer radius of the radial tooth band, including every tip. Use the same
//   tooth count, tooth size, worm parameters, shaft_offset, gear_diam and face_width as worm_face_gear().
//   Pass matching clearance, backlash, min_tip and handedness because they affect automatic sizing.
//   Body backing does not affect this radius. The bound is independent of tessellation.
//   .
//   Alternatively, supply worm_root_diam instead of worm_diam. It specifies a nominal
//   minimum worm-core diameter and resolves to worm_diam = worm_root_diam + 2*(module + clearance).
//   Cylindrical valleys that close early can leave a larger actual core.
//   An explicit root diameter overrides an inherited pitch diameter; explicit diameter alternatives
//   are mutually exclusive. Use the same clearance for the worm, wheel and placement helpers.
// Arguments:
//   teeth = Face-gear tooth count.
//   worm_diam = Worm pitch diameter. Inherits when available.
//   ---
//   worm_root_diam = Positive nominal minimum worm-core diameter; alternative to worm_diam. Uses tooth size and clearance; does not cut a bore.
//   mod/circ_pitch/diam_pitch = Matching normal tooth size; inherits when available.
//   shaft_offset = Distance between the shafts; inherits from a face gear or is computed.
//   gear_diam = Actual outside diameter; inherits from a face gear or is computed.
//   left_handed = Matching handedness; affects automatic sizing with asymmetric pressure angles.
//   worm_starts = Worm start count. Inherits when available. Default: 1.
//   face_width = Radial band width, with the same default as worm_face_gear().
//   pressure_angle = Matching normal pressure angle. Default: inherited or 20.
//   clearance = Matching root clearance. Default: inherited or module/4.
//   backlash = Matching wheel tooth thinning. Default: $backlash.
//   min_tip = Same positive circumferential tip-width setting as the gear. Default: 0.4*module.

function worm_face_gear_radius_bound(teeth,worm_diam,_named,mod,circ_pitch,diam_pitch,
                                    worm_starts,shaft_offset,face_width,pressure_angle,clearance,
                                    backlash,min_tip,worm_root_diam,gear_diam,left_handed) =
    assert(is_undef(_named),"\nToo many positional arguments (only 2 are accepted)")
    _wfg_arguments(teeth,worm_diam,worm_starts,shaft_offset,face_width,pressure_angle,
                   clearance,backlash,min_tip,mod,circ_pitch,diam_pitch,worm_root_diam=worm_root_diam,left_handed=left_handed,gear_diam=gear_diam)[4];

// Function: worm_face_gear_worm_pos()
// Synopsis: Returns the worm center for manual worm-face placement.
// Topics: Gears, Parts
// See Also: worm_face_gear(), worm_face_dist(), worm_face_gear_worm_spin()
// Usage:
//    center = worm_face_gear_worm_pos(teeth, worm_diam, mod=|circ_pitch=|diam_pitch=, [shaft_offset=], [gear_diam=], [worm_starts=], [pressure_angle=], [left_handed=], [shift=]);
// Description:
//   Use the same shaft_offset, gear_diam, face_width, clearance, backlash and min_tip as the wheel.
//   Undefined dimensions are resolved by the same automatic sizing search as worm_face_gear().
//   Returns [axial_position, shaft_offset, worm_diam/2] in the face gear's pitch-plane frame.
//   With shift=0 the worm center is at the midpoint of the required working span.
//   Positive shift moves the worm along its native Z+ shaft, negative toward Z-.
//   The reference does not depend on worm length or surface sampling.
//   This is the canonical angle=90 placement, with the worm oriented by yrot(90), so its native
//   Z+ shaft becomes X+. For a different angle, rotate the position and orientation together
//   about the face-gear axis by angle-90. Use worm_face_gear_worm_spin() for matching tooth phase.
//   This reference-position helper does not check finite worm length or end-taper coverage;
//   attach_gear() performs those checks when it has both completed gear specifications.
//   .
//   Alternatively, supply worm_root_diam instead of worm_diam. It specifies a nominal
//   minimum worm-core diameter and resolves to worm_diam = worm_root_diam + 2*(module + clearance).
//   Cylindrical valleys that close early can leave a larger actual core.
//   An explicit root diameter overrides an inherited pitch diameter; explicit diameter alternatives
//   are mutually exclusive. Use the same clearance for the worm, wheel and placement helpers.
//   .
//   pressure_angle accepts the same scalar or [pa_bot,pa_top] pair as worm_face_gear().
//   Use the same ordered pair on both gears; the placement and phase formulas remain
//   valid for asymmetric teeth and either handedness.
// Arguments:
//   teeth = Face-gear tooth count.
//   worm_diam = Worm pitch diameter. Inherits when available.
//   ---
//   worm_root_diam = Positive nominal minimum worm-core diameter; alternative to worm_diam. Uses tooth size and clearance; does not cut a bore.
//   clearance = Root-depth allowance used when worm_root_diam is supplied. Default: inherited from the matching worm family, otherwise module/4.
//   mod/circ_pitch/diam_pitch = Matching normal tooth size; inherits when available.
//   shaft_offset = Distance between shaft axes; inherits from a face gear or is computed.
//   gear_diam = Matching outside diameter; inherits from a face gear or is computed.
//   face_width = Matching radial band width; inherits from a face gear or defaults to three axial thread pitches.
//   backlash = Matching wheel tooth thinning. Default: inherited from a face gear or $backlash.
//   min_tip = Matching minimum tip chord. Default: inherited from a face gear or 0.4*module.
//   worm_starts = Number of worm starts. Default: inherited or 1.
//   pressure_angle = Matching normal pressure angle. Default: inherited or 20.
//   left_handed = Worm handedness. Default: inherited or false.
//   shift = Signed distance to move the worm along its native Z+ shaft from centered engagement, as for a worm child in attach_gear(). Default: 0.

function worm_face_gear_worm_pos(teeth,worm_diam,_named,mod,circ_pitch,diam_pitch,
                                worm_starts,shaft_offset,pressure_angle,left_handed,shift,worm_root_diam,
                                clearance,gear_diam,face_width,backlash,min_tip) =
    assert(is_undef(_named),"\nToo many positional arguments (only 2 are accepted)")
    let(shift=default(shift,0))
    assert(is_finite(shift),"\nshift must be a finite distance along the worm")
    let(P=_wfg_arguments(teeth,worm_diam,worm_starts,shaft_offset,face_width,pressure_angle,
                        clearance,backlash,min_tip,mod,circ_pitch,diam_pitch,worm_root_diam,left_handed,gear_diam),
        F=P[0],lh=default(left_handed,default($parent_gear_left_handed,false)))
    _wfg_mesh_center(P,lh)+[shift,0,0];

// Function: worm_face_gear_worm_spin()
// Synopsis: Returns the worm tooth phase for manual worm-face placement.
// Topics: Gears, Parts
// See Also: worm_face_gear(), worm_face_gear_worm_pos(), worm_face_dist()
// Usage:
//   phase = worm_face_gear_worm_spin(teeth, worm_diam, mod=|circ_pitch=|diam_pitch=, [shaft_offset=], [gear_diam=], [worm_starts=], [pressure_angle=], [left_handed=], [shift=], [angle=], [gear_spin=]);
// Description:
//   Use the same shaft_offset, gear_diam, face_width, clearance, backlash and min_tip as the wheel.
//   Undefined dimensions are resolved by the same automatic sizing search as worm_face_gear().
//   Returns the matching worm gear_spin in degrees, reduced by whole worm-thread periods.
//   Coordinates follow worm_face_gear_worm_pos(). angle is the mounting azimuth around the
//   face-gear axis, and gear_spin is the FACE GEAR's tooth rotation. The result includes
//   the start-count ratio, handedness, mounting azimuth and axial shift compensation.
//   .
//   Alternatively, supply worm_root_diam instead of worm_diam. It specifies a nominal
//   minimum worm-core diameter and resolves to worm_diam = worm_root_diam + 2*(module + clearance).
//   Cylindrical valleys that close early can leave a larger actual core.
//   An explicit root diameter overrides an inherited pitch diameter; explicit diameter alternatives
//   are mutually exclusive. Use the same clearance for the worm, wheel and placement helpers.
//   .
//   pressure_angle accepts the same scalar or [pa_bot,pa_top] pair as worm_face_gear().
//   Use the same ordered pair on both gears; the placement and phase formulas remain
//   valid for asymmetric teeth and either handedness.
// Arguments:
//   teeth = Face-gear tooth count.
//   worm_diam = Worm pitch diameter. Inherits when available.
//   ---
//   worm_root_diam = Positive nominal minimum worm-core diameter; alternative to worm_diam. Uses tooth size and clearance; does not cut a bore.
//   clearance = Root-depth allowance used when worm_root_diam is supplied. Default: inherited from the matching worm family, otherwise module/4.
//   mod/circ_pitch/diam_pitch = Matching normal tooth size; inherits when available.
//   shaft_offset = Distance between shaft axes; inherits from a face gear or is computed.
//   gear_diam = Matching outside diameter; inherits from a face gear or is computed.
//   face_width = Matching radial band width; inherits from a face gear or defaults to three axial thread pitches.
//   backlash = Matching wheel tooth thinning. Default: inherited from a face gear or $backlash.
//   min_tip = Matching minimum tip chord. Default: inherited from a face gear or 0.4*module.
//   worm_starts = Number of worm starts. Default: inherited or 1.
//   pressure_angle = Matching normal pressure angle. Default: inherited or 20.
//   left_handed = Worm handedness. Default: inherited or false.
//   shift = Signed distance to move the worm along its native Z+ shaft from centered engagement, as for a worm child in attach_gear(). Default: 0.
//   angle = Mounting azimuth, as with a face-gear parent in attach_gear(). Default: 90.
//   gear_spin = Face-gear tooth rotation in degrees. Default: 0.
// Example(3D): Manual placement with the two helpers.
//   m=2; n=40; d=20; e=35; p=3;
//   worm_face_gear(mod=m, teeth=n, worm_diam=d, shaft_offset=e,
//                  face_width=8, backing=3, backlash=.15);
//   center=worm_face_gear_worm_pos(mod=m, teeth=n, worm_diam=d, shaft_offset=e, shift=p, face_width=8, backlash=.15);
//   phase=worm_face_gear_worm_spin(mod=m, teeth=n, worm_diam=d, shaft_offset=e, shift=p, face_width=8, backlash=.15);
//   move(center) yrot(90) worm(mod=m, d=d, starts=1, l=65, gear_spin=phase);

function worm_face_gear_worm_spin(teeth,worm_diam,_named,mod,circ_pitch,diam_pitch,
                                 worm_starts,shaft_offset,pressure_angle,left_handed,
                                 shift,angle=90,gear_spin=0,worm_root_diam,clearance,
                                 gear_diam,face_width,backlash,min_tip) =
    assert(is_undef(_named),"\nToo many positional arguments (only 2 are accepted)")
    let(shift=default(shift,0))
    assert(is_finite(shift) && is_finite(angle) && is_finite(gear_spin),"\nshift, angle and gear_spin must be finite")
    let(P=_wfg_arguments(teeth,worm_diam,worm_starts,shaft_offset,face_width,pressure_angle,
                        clearance,backlash,min_tip,mod,circ_pitch,diam_pitch,worm_root_diam,left_handed,gear_diam),
        F=P[0],lh=default(left_handed,default($parent_gear_left_handed,false)),q=lh?-1:1,
        a=90+F[1]/F[3]*(90-F[10])+_wfg_center_phase(P)
          +q*F[1]/F[3]*(gear_spin-angle+90)+q*shift/F[6]*180/PI)
    a-(360/F[3])*round(a/(360/F[3]));



// Constant: $backlash
// Synopsis: Sets the default tooth-thinning allowance for gear constructors.
// Topics: Gears
// See Also: spur_gear(), rack(), worm(), worm_gear(), globoid_worm_gear()
// Usage:
//   $backlash = allowance;
// Description:
//   Supplies the default for omitted `backlash` arguments on gear constructors and
//   tooth-profile radius queries. An explicit argument, including zero, takes precedence.
//   The allowance uses the same model-unit tooth-thinning convention as each constructor.
//   Both members of a straight spur pair using 0.1 contribute a total nominal 0.2 of play.
//   A globoid pair applies this allowance on its worm gear.
//   The spacing helpers use their explicit `backlash` arguments independently.
//   A scoped assignment can set a common allowance for an assembly or one branch.
//   Default: 0
// Example(2D): A shared allowance with a local override.
//   $backlash=0.1;
//   spur_gear2d(mod=2,teeth=24)
//       attach_gear(0) spur_gear2d(teeth=36,backlash=0);




// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
