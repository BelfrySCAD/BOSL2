//////////////////////////////////////////////////////////////////////
// LibFile: screws.scad
//   Functions and modules for creating metric (ISO) and English (UTS) standard screws and nuts.
//   Included is a function for calculating the standard dimensions of screws including the
//   tolerance values that are required to make screws mate properly when they are formed
//   precisely.  If you can fabricate objects accurately then the modeled screws will mate
//   with standard hardware without the need to introduce extra gaps for clearance.
// Includes:
//   include <BOSL2/std.scad>
//   include <BOSL2/screws.scad>
// FileGroup: Threaded Parts
// FileSummary: ISO (metric) and UTS screws and nuts.
//////////////////////////////////////////////////////////////////////

include <structs.scad>
include <threading.scad>
include <screw_drive.scad>

// Section: Screw and Nut Parameters
//    This modules in this file create standard ISO (metric) and UTS (English) threaded screws.
//    The {{screw()}} and {{nut()}} modules produce
//    screws and nuts that comply with the relevant ISO and ASME standards,
//    including tolerances for screw fit.  You can also create screws with
//    various head types and drive types that should match standard hardware.
// Subsection: Screw Naming
//    You can specify screws using a string that specifies the screw.
//    Metric or ISO screws are specified by a diameter in millimeters and a thread pitch in millimeters.  For example,
//    an M8x2 screw has a nominal diameter of 8 mm and a thread pitch of 2 mm.  
//    The screw specification for these screws has the form: "M`<size>`x`<pitch>`,`<length>`,
//    so "M6x1,10" specifies a 6mm diameter screw with a thread pitch of 1mm and length of 10mm.
//    You can omit the pitch or length, e.g. "M6x1", or "M6,10", or just "M6".  If you omit the
//    length then you must provide the `length` parameter.  If you omit the pitch, the library
//    provides a standard pitch for the specified diameter.
//    .
//    Imperial or UTS screws are specified by a diameter and the number of threads per inch.
//    For large screws, the diameter is simply the nominal diameter in inches, so a 5/16-18 screw
//    has a nominal diameter of 5/16 inches and 18 threads per inch.  For diameters smaller than
//    1/4 inch, the screw diameter is given using a screw gauge, which can be from 0 up to 12.
//    A common smaller size is #8-32, an 8 gauge screw with 32 threads per inch.  
//    For UTS screws the specification has the form `<size>`-`<threadcount>`,`<length>`, e.g. 
//    "#8-32,1/2", or "1/4-20,1".  The units are in inches, including the length.  Size can be a
//    gauge number from 0 to 12 with or without a leading # to specify a screw gauge size, or any other
//    value to specify a diameter in inches, either as a float or a fraction, so "0.5-13" and
//    "1/2-13" are equivalent.  To force interpretation of the value as inches add '' (two
//    single-quotes) to the end, e.g. "1''-4" is a one inch screw and "1-80" is a very small
//    1-gauge screw.  The pitch is specified using a thread count, the number of threads per inch.
//    As with the ISO screws, you can omit the pitch or length and specify "#6-32", "#6,3/4", or simply #6.
//    As in the metric case, if you omit the length then you must provide the `length` parameter.  If you omit the pitch, the
//    library provides a standard pitch for the specified diameter.
// Subsection: Standard Screw Pitch
//    If you omit the pitch when specifying a screw or nut then the library supplies a standard screw pitch based
//    on the screw diameter as listed in ISO 724 or ASME B1.1.  For many diameters, multiple standard pitches exist.
//    The available thread pitch types are different for ISO and UTS:
//    .
//    | ISO      |    UTS   |
//    | -------- | -------- |
//    | "coarse" |  "coarse" or "UNC" |
//    | "fine"   |   "fine" or "UNF"  |
//    | "extrafine" or "extra fine" | "extrafine", "extra fine", or "UNEF"  |
//    | "superfine" or "super fine" |   |
//    | "none"   |  "none"  |
//    .
//    The default pitch selection is "coarse".  Note that this selection is case insensitive.
//    To set the pitch using these pitch strings you use the `thread=` argument to the modules.
//    You cannot incorporate a named pitch into the thread name.  The finer pitch categories
//    are defined only for larger screw diameters.  You can also use the `thread=` argument to
//    directly specify a pitch, so `thread=2` produces a thread pitch of 2mm.  Setting the
//    pitch to zero produces an unthreaded screws, the same as setting it to "none".  Specifying
//    a numeric value this way overrides a value given in the specification.  You can also set
//    `thread=true` or `thread=false` to turn threading on and off, with the same default coarse
//    threading when you set it to true.  
// Subsection: Screw Heads
//    By default screws do not have heads.  
//    You can request a screw head using `head=` parameter to specify the desired head type.  If you want the
//    head to have a recess for driving the screw you must also specify a drive type using `drive=`.  
//    The table below lists the head options.  Only some combinations of head and drive
//    type are supported.  Different sized flat heads exist for the same screw type.
//    Sometimes this depends on the type of recess.  If you specify "flat" then the size will be chosen
//    appropriately for the recess you specify.
//    .
//    The `drive=` argument can be set to "none", "hex", "slot", 
//    "phillips", "ph0" to "ph4" (for phillips of the specified size), "torx" or
//    "t<size>" (for Torx at a specified size, e.g. "t20").  If you have no head but still
//    give a drive type you will get a set screw.  The table below lists all of the head types and
//    shows which drive type is compatible with each head types.  Different head types work in ISO and UTS,
//    as marked in the first column.  
//    .
//    |ISO|UTS|Head            | Drive  |
//    |---|---|--------------- | ----------------------------|
//    |X|X|"none"          | hex, torx, slot |
//    |X|X|"hex"           | *none*|
//    |X|X|"socket"        | hex, torx|
//    |X|X|"button"        | hex, torx|
//    |X|X|"flat"          | slot, phillips, hex, torx|
//    |X|X|"flat sharp"    | slot, phillips, hex, torx|
//    | |X|"flat small"    | slot, phillips|
//    | |X|"flat large"    | hex, torx |
//    | |X|"flat undercut" | slot, phillips |
//    | |X|"flat 82"       | slot, phillips |
//    | |X|"flat 100"      | slot, phillips |
//    | |X|"round"         | slot, phillips |
//    | |X|"fillister"     | slot, phillips |
//    |X|X|"pan"           | slot, phillips, torx (ISO only) |
//    |X| |"cheese"        | slot, phillips, torx |
//    .
//    The drive size is specified appropriately for the drive type: drive number for phillips or torx,
//    and recess width in mm or inches (as appropriate) for hex.  Drive size is determined automatically
//    from the screw size, but by passing the `drive_size=` argument you can override the default, or
//    in cases where no default exists you can specify it.  Flat head screws have variations such as 100 degree
//    angle for UTS, or undercut heads.  You can also request a "sharp" screw which will set the screw diameter 
//    the theoretical maximum and produce sharp corners instead of a flat edge on the head.  For a flat head screw
//    the drive specification must start with "flat", but the flat head options
//    can be mixed in any order, for example, "flat sharp undercut" or "flat undercut sharp".
// Subsection: Nuts
//    Nuts come in standard sizes and BOSL2 has tables to produce sizes for both Imperial and metric nuts.
//    A nut for a given thread size is defined by its shape, width and thickness.  The shape is either "hex"
//    for hexagonal nuts or "square" for square nuts.  For hexagonal Imperial nuts, you can choose from thickness values
//    of "thin", "normal" or "thick", but the thin and thick nuts are defined only for thread sizes of 1/4 inch and above.
//    .
//    Metric nut standards are more complicated because ISO has a series of standards and DIN has a series of conflicting
//    standards.  Nuts from McMaster-Carr in the USA comply with DIN rather than ISO.  Furthermore, ISO does not appear
//    to specify dimensions for square nuts.  For metric nuts you can specify "thin", "normal" and "thick" and the
//    nut will be constructed to ISO standards (ISO 4035, ISO 4032, and ISO 4033 respectively).  The DIN standard for thin
//    nuts matches ISO, but the DIN normal thickness nuts are thinner than ISO nuts.  You can request DIN nuts
//    by specifying a thickness of "DIN" or "undersized".  If you request a square nut it necessariliy derives from DIN
//    instead of ISO.  For most nut sizes, the nut widths match between ISO and DIN, but they do differ for M10, M12, M14 and M22.
//    .
//    You can of course specify nuts by giving an explicit numerical width and thickness in millimeters. 
// Subsection: Tolerance
//    Without tolerance requirements, screws would not fit together.  The screw standards specify a
//    nominal size, but the tolerance determines a range of allowed sizes based on that nominal size.
//    So for example, an M10 screw with the default tolerance has an outside (major) diameter between 9.74 mm and 9.97 mm.
//    The library will use the center point in the allowed range and create a screw with a diameter of 9.86 mm.
//    A M10 nut at the default tolerance has a major diameter (which is the inside diameter) between 10 mm and 10.4 mm.
//    Shrinking the major diameter of a screw makes the screw loose.  Shrinking the major diameter of a nut, on the other hand,
//    makes the hole smaller and hence makes the nut tighter.  For this reason, we need a difference tolerance
//    for a screw than for a nut.  Screw tolerances shrink the diameter to make the screw looser whereas nut tolerances
//    increase the diameter to make the nut looser.  Screws modeled using this library will have dimensions consistent with the
//    standards they are based on, so that they will interface properly if fabricated by an accurate method.  The ISO and UTS
//    systems use different tolerance designations.
//    .
//    For UTS screw threads the tolerance is one of "1A", "2A" or "3A", in
//    order of increasing tightness.  The default tolerance is "2A", which
//    is the general standard for manufactured bolts.
//    .
//    For UTS nut threads, the tolerance is one of "1B", "2B" or "3B", in
//    order of increasing tightness.  The default tolerance is "2B", which
//    is the general standard for manufactured nuts.
//    .
//    The ISO tolerances are more complicated.  For both screws and nuts the ISO tolerance has the form of a number
//    and letter.  The letter specifies the "fundamental deviation", also called the "tolerance position", the gap
//    from the nominal size.  The number specifies the allowed range (variability) of the thread heights.  For
//    screws, the letter must be "e", "f", "g", or "h", where "e" is the loosest and "h" means no gap.  The number
//    for a screw tolerance must be a value from 3-9 for crest diameter and one of 4, 6, or 8 for pitch diameter.
//    A tolerance "6g" specifies both pitch and crest diameter to be the same, but they can be different, with a
//    tolerance like "5g6g" specifies a pitch diameter tolerance of "5g" and a crest diameter tolerance of "6g".
//    Smaller numbers give a tighter tolerance.  The default ISO screw tolerance is "6g".
//    .
//    For ISO nuts the letters specifying the fundamental deviation are upper case and must be "G" or "H" where "G"
//    is loose and "H" means no gap. The number specifying the variability must range from 4-8.  An allowed (loose)
//    nut tolerance is "7G".  The default ISO tolerance is "6H".
//    .
//    Clearance holes have a different tolerance system, described in {{screw_hole()}}.
//    .
//    If you wish to create screws at the nominal size you can set the tolerance to 0 or "none".  
// Subsection: screw_info and nut_info structures
//    When you make a screw or nut, information about the object such as the thread characteristics 
//    head and drive size, or nut thickness are placed into a data structure.  The screw and nut 
//    modules can accept screw names, as described above, or they can accept screw structures. 
//    When you use a screw structure as a specification, computed values like head type and size and
//    driver characteristics are fixed and cannot be changed, but values that are not computed
//    like length can still be altered.  If you want to create an unusual part you can hand
//    generate the structure with your desired parameters to fill in values that would normally
//    be produced automatically from the standard tables.  So if your hardware is missing from the
//    tables, or is sized differently, you can still create the part.  For details on the
//    screw_info and nut_info structures, see {{screw_info()}} and {{nut_info()}}.  
//    .
//    All of the screw related modules set the variable `$screw_spec` to contain the specification
//    for their screw.  This means that child modules can make use of this variable to create
//    mating (or identical) parts.  Note that the `shaft_oversize` and `head_oversize` screw
//    info fields are only inherited into modules that are the same as the parent module.
//    This means that if you create an oversized screw hole and then make a screw as s child, the
//    child screw will **not** inherit the oversize parameters.  But a screw_hole will inherit 
//    oversize parameters from a parent screw_hole.  

/*
http://mdmetric.com/thddata.htm#idx

Seems to show JIS has same nominal thread as others
https://www.nbk1560.com/~/media/Images/en/Product%20Site/en_technical/11_ISO%20General%20Purpose%20Metric%20Screw%20Threads.ashx?la=en

Various ISO standards here:  https://www.fasteners.eu/standards/ISO/4026/

Torx values:  https://www.stanleyengineeredfastening.com/-/media/web/sef/resources/docs/other/socket_screw_tech_manual_1.ashx

*/


// Section: Making Screws

// Module: screw()
// Synopsis: Creates a standard screw with optional tolerances.
// SynTags: Geom
// Topics: Threading, Screws
// See Also: screw_hole(), shoulder_screw()
// Usage:
//   screw([spec], [head], [drive], [thread=], [drive_size=], [length=|l=], [thread_len=], [undersize=], [shaft_undersize=], [head_undersize=], [tolerance=], [blunt_start=], [details=], [anchor=], [atype=], [orient=], [spin=]) [ATTACHMENTS];
// Description:
//   Create a screw.  See [screw and nut parameters](#section-screw-and-nut-parameters) for details on
//   the parameters that define a screw.  The tolerance determines the dimensions of the screw based
//   on ISO and ASME standards.  Screws fabricated at those dimensions will mate properly with
//   standard hardware.  Note that the $slop argument does not affect the size of screws: it only
//   adjusts screw holes.  This will work fine if you are printing both parts, but if you need to mate
//   printed screws to metal parts you may need to adjust the size of the screws, which you can do
//   with the undersize arguments.
//   .
//   You can generate a screw specification from {{screw_info()}}, possibly create a modified version
//   using {{struct_set()}}, and pass that in rather than giving the parameters.
//   .
//   Various anchor types refer to different parts of the screw, some of which are labeled below.  The
//   "screw" anchor type (the default) is simply the entire screw, so TOP and BOTTOM refer to the head
//   end and tip respectively, and CENTER is the midpoint of the whole screw, including the head.  The
//   "head" anchor refers to the head alone.  Both of these anchor types refer to the bounding
//   cylinder for the specified screw part, except for hex heads, which anchor to a hexagonal prism.
// Figure(2D,Med,VPD = 140, VPT = [18.4209, 14.9821, -3.59741], VPR = [0, 0, 0],NoAxes):
//   rpos=33;
//   fsize=2.5;
//   projection(cut=true) xrot(-90)screw("M8", head="socket", length=25, thread_len=10,anchor=BOT);
//   right(rpos)projection(cut=true) xrot(-90)screw("M8", head="flat", length=25, thread_len=10,anchor=BOT);
//   color("black"){
//      stroke([[5,0],[5,10]],endcaps="arrow2",width=.3);
//      back(5)right(6)text("threads",size=fsize,anchor=LEFT);
//      stroke([[5,10],[5,25]],endcaps="arrow2",width=.3);
//      back(10+15/2)right(6)text("shank",size=fsize,anchor=LEFT);
//      stroke([[-5,0],[-5,25]],endcaps="arrow2",width=.3);
//      back(25/2)right(-6)text("shaft",size=fsize,anchor=RIGHT);
//   }
//   sh=10.2841;
//   right(rpos)
//   color("black"){
//      stroke([[5,0],[5,10]],endcaps="arrow2",width=.3);
//      back(5)right(6)text("threads",size=fsize,anchor=LEFT);
//      stroke([[5,10],[5,10+sh]],endcaps="arrow2",width=.3);
//      back(10+sh/2)right(6)text("shank",size=fsize,anchor=LEFT);
//      stroke([[-5,0],[-5,10+sh]],endcaps="arrow2",width=.3);
//      back((10+sh)/2)right(-6)text("shaft",size=fsize,anchor=RIGHT);
//   }
// Arguments:
//   spec = screw specification, e.g. "M5x1" or "#8-32".  See [screw naming](#subsection-screw-naming).  This can also be a screw specification structure of the form produced by {{screw_info()}}.  
//   head = head type.  See [screw heads](#subsection-screw-heads)  Default: none
//   drive = drive type.  See [screw heads](#subsection-screw-heads) Default: none
//   ---
//   length / l = length of screw (in mm)
//   thread = thread type or specification. See [screw pitch](#subsection-standard-screw-pitch). Default: "coarse"
//   drive_size = size of drive recess to override computed value
//   thread_len = length of threaded portion of screw (in mm), for making partly threaded screws.  Default: fully threaded
//   details = toggle some details in rendering.  Default: true
//   tolerance = screw tolerance.  Determines actual screw thread geometry based on nominal sizing.  See [tolerance](#subsection-tolerance). Default is "2A" for UTS and "6g" for ISO.  
//   undersize = amount to decrease screw diameter, a scalar to apply to all parts, or a 2-vector to control shaft and head.  Replaces rather than adding to the head_oversize value in a screw specification.  
//   shaft_undersize = amount to decrease diameter of the shaft of screw; replaces rather than adding to the shaft_oversize value in a screw specification. 
//   head_undersize = amount to decrease the head diameter of the screw; replaces rather than adding to the head_oversize value in a screw specification. 
//   bevel1 = bevel bottom end of screw.  Default: true
//   bevel2 = bevel top end of threaded section.  Default: true for fully threaded or unthreaded headless, false otherwise
//   bevel = bevel both ends of the threaded section.
//   blunt_start = if true and hole is threaded, create blunt start threads.  Default: true
//   blunt_start1 = if true and hole is threaded, create blunt start threads at bottom end.
//   blunt_start2 = if true and hole is threaded, create blunt start threads top end.
//   atype = anchor type, one of "screw", "head", "shaft", "threads", "shank"
//   anchor = Translate so anchor point on the shaft is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Side Effects:
//   `$screw_spec` is set to the spec specification structure. 
// Anchor Types:
//   screw = the entire screw (default)
//   head = screw head (invalid for headless screws)
//   shaft = screw shaft
//   shank = unthreaded section of shaft (invalid if screw is fully threaded)
//   threads = threaded section of screw     
// Named Anchors:
//   "top" = top of screw
//   "bot" = bottom of screw
//   "center" = center of screw
//   "head_top" = top of head (same as top for headless screws)
//   "head_bot" = bottom of head (same as top for headless screws)
//   "head_center" = center of head (same as top for headless screws)
//   "shaft_top" = top of shaft
//   "shaft_bot" = bottom of shaft
//   "shaft_center" = center of shaft
//   "shank_top" = top of shank (invalid if screw is fully threaded)
//   "shank_bot" = bottom of shank (invalid if screw is fully threaded)
//   "shank_center" = center of shank (invalid if screw is fully threaded)
//   "threads_top" = top of threaded portion of screw (invalid if thread_len=0)
//   "threads_bot" = bottom of threaded portion of screw (invalid if thread_len=0)
//   "threads_center" = center of threaded portion of screw (invalid if thread_len=0)
// Example(Med): Selected UTS (English) screws
//   $fn=32;
//   xdistribute(spacing=8){
//     screw("#6", length=12);
//     screw("#6-32", head="button", drive="torx",length=12);
//     screw("#6-32,3/4", head="hex");
//     screw("#6", thread="fine", head="fillister",length=12, drive="phillips");
//     screw("#6", head="flat small",length=12,drive="slot");
//     screw("#6-32", head="flat large", length=12, drive="torx");
//     screw("#6-32", head="flat undercut",length=12);
//     screw("#6-24", head="socket",length=12);          // Non-standard threading
//     screw("#6-32", drive="hex", drive_size=1.5, length=12);
//   }
// Example(Med): A few examples of ISO (metric) screws
//   $fn=32;
//   xdistribute(spacing=8){
//     screw("M3", head="flat small",length=12);
//     screw("M3", head="button",drive="torx",length=12);
//     screw("M3", head="pan", drive="phillips",length=12);
//     screw("M3x1", head="pan", drive="slot",length=12);   // Non-standard threading!
//     screw("M3", head="flat large",length=12);
//     screw("M3", thread="none", head="flat", drive="hex",length=12);  // No threads
//     screw("M3", head="socket",length=12);
//     screw("M5,18", head="hex");
//   }
// Example(Med): Demonstration of all head types for UTS screws (using pitch zero for fast preview)
//   xdistribute(spacing=15){
//     ydistribute(spacing=15){
//        screw("1/4", thread=0,length=8, anchor=TOP, head="none", drive="hex");
//        screw("1/4", thread=0,length=8, anchor=TOP, head="none", drive="torx");
//        screw("1/4", thread=0,length=8, anchor=TOP, head="none", drive="slot");
//        screw("1/4", thread=0,length=8, anchor=TOP, head="none");
//     }
//     screw("1/4", thread=0, length=8, anchor=TOP, head="hex");
//     ydistribute(spacing=15){
//        screw("1/4", thread=0,length=8, anchor=TOP, head="socket", drive="hex");
//        screw("1/4", thread=0,length=8, anchor=TOP, head="socket", drive="torx");
//        screw("1/4", thread=0,length=8, anchor=TOP, head="socket");
//     }
//     ydistribute(spacing=15){
//        screw("1/4", thread=0,length=8, anchor=TOP, head="socket ribbed", drive="hex",$fn=32);
//        screw("1/4", thread=0,length=8, anchor=TOP, head="socket ribbed", drive="torx",$fn=32);
//        screw("1/4", thread=0,length=8, anchor=TOP, head="socket ribbed",$fn=24);
//     }
//     ydistribute(spacing=15){
//        screw("1/4", thread=0,length=8, anchor=TOP, head="button", drive="hex");
//        screw("1/4", thread=0,length=8, anchor=TOP, head="button", drive="torx");
//        screw("1/4", thread=0,length=8, anchor=TOP, head="button");
//     }
//     ydistribute(spacing=15){
//        screw("1/4", thread=0,length=8, anchor=TOP, head="round", drive="slot");
//        screw("1/4", thread=0,length=8, anchor=TOP, head="round", drive="phillips");
//        screw("1/4", thread=0,length=8, anchor=TOP, head="round");
//     }     
//     ydistribute(spacing=15){
//        screw("1/4", thread=0,length=8, anchor=TOP, head="pan", drive="slot");
//        screw("1/4", thread=0,length=8, anchor=TOP, head="pan", drive="phillips");
//        screw("1/4", thread=0,length=8, anchor=TOP, head="pan");
//     }
//     ydistribute(spacing=15){
//        screw("1/4", thread=0,length=8, anchor=TOP, head="fillister", drive="slot");
//        screw("1/4", thread=0,length=8, anchor=TOP, head="fillister", drive="phillips");
//        screw("1/4", thread=0,length=8, anchor=TOP, head="fillister");
//     }
//     ydistribute(spacing=15){
//        screw("1/4", thread=0,length=8, anchor=TOP, head="flat", drive="slot");
//        screw("1/4", thread=0,length=8, anchor=TOP, head="flat", drive="phillips");
//        screw("1/4", thread=0,length=8, anchor=TOP, head="flat", drive="hex");
//        screw("1/4", thread=0,length=8, anchor=TOP, head="flat", drive="torx");
//        screw("1/4", thread=0,length=8, anchor=TOP, head="flat large");
//        screw("1/4", thread=0,length=8, anchor=TOP, head="flat small");
//     }
//     ydistribute(spacing=15){
//        screw("1/4", thread=0,length=8, anchor=TOP, head="flat undercut", drive="slot");
//        screw("1/4", thread=0,length=8, anchor=TOP, head="flat undercut", drive="phillips");
//        screw("1/4", thread=0,length=8, anchor=TOP, head="flat undercut");
//     }
//     ydistribute(spacing=15){
//        screw("1/4", thread=0,length=8, anchor=TOP, head="flat 100", drive="slot");
//        screw("1/4", thread=0,length=8, anchor=TOP, head="flat 100", drive="phillips");
//        screw("1/4", thread=0,length=8, anchor=TOP, head="flat 100");
//     }
//   }
// Example(Med): Demonstration of all head types for metric screws without threading.
//   xdistribute(spacing=15){
//     ydistribute(spacing=15){
//       screw("M6x0", length=8, anchor=TOP,  head="none", drive="hex");
//       screw("M6x0", length=8, anchor=TOP,  head="none", drive="torx");
//       screw("M6x0", length=8, anchor=TOP,  head="none", drive="slot");
//       screw("M6x0", length=8, anchor=TOP);
//     }
//     screw("M6x0", length=8, anchor=TOP,  head="hex");
//     ydistribute(spacing=15){
//       screw("M6x0", length=8, anchor=TOP,  head="socket", drive="hex");
//       screw("M6x0", length=8, anchor=TOP,  head="socket", drive="torx");
//       screw("M6x0", length=8, anchor=TOP,  head="socket");
//     }
//     ydistribute(spacing=15){
//       screw("M6x0", length=8, anchor=TOP,  head="socket ribbed", drive="hex", $fn=32);
//       screw("M6x0", length=8, anchor=TOP,  head="socket ribbed", drive="torx", $fn=32);
//       screw("M6x0", length=8, anchor=TOP,  head="socket ribbed", $fn=32);
//     }
//     ydistribute(spacing=15){
//       screw("M6x0", length=8, anchor=TOP,  head="pan", drive="slot");
//       screw("M6x0", length=8, anchor=TOP,  head="pan", drive="phillips");
//       screw("M6x0", length=8, anchor=TOP,  head="pan", drive="torx");
//       screw("M6x0", length=8, anchor=TOP,  head="pan");
//       screw("M6x0", length=8, anchor=TOP,  head="pan flat");
//     }
//     ydistribute(spacing=15){
//       screw("M6x0", length=8, anchor=TOP,  head="button", drive="hex");
//       screw("M6x0", length=8, anchor=TOP,  head="button", drive="torx");
//       screw("M6x0", length=8, anchor=TOP,  head="button");
//     }
//     ydistribute(spacing=15){
//       screw("M6x0", length=8, anchor=TOP,  head="cheese", drive="slot");
//       screw("M6x0", length=8, anchor=TOP,  head="cheese", drive="phillips");
//       screw("M6x0", length=8, anchor=TOP,  head="cheese", drive="torx");
//       screw("M6x0", length=8, anchor=TOP,  head="cheese");
//     }
//     ydistribute(spacing=15){
//       screw("M6x0", length=8, anchor=TOP,  head="flat", drive="phillips");
//       screw("M6x0", length=8, anchor=TOP,  head="flat", drive="slot");
//       screw("M6x0", length=8, anchor=TOP,  head="flat", drive="hex");
//       screw("M6x0", length=8, anchor=TOP,  head="flat", drive="torx");
//       screw("M6x0", length=8, anchor=TOP,  head="flat small");
//       screw("M6x0", length=8, anchor=TOP,  head="flat large");
//     }
//   }
// Example: The three different English (UTS) screw tolerances (labeled on their heads)
//   module label(val)
//   {
//     difference(){
//        children();
//        yflip()linear_extrude(height=.35) text(val,valign="center",halign="center",size=8);
//     }
//   }
//   $fn=64;
//   xdistribute(spacing=15){
//     label("1") screw("1/4-20,5/8", head="hex",orient=DOWN,atype="head", anchor=TOP,tolerance="1A");  // Loose
//     label("2") screw("1/4-20,5/8", head="hex",orient=DOWN,atype="head", anchor=TOP,tolerance="2A");  // Standard
//     label("3") screw("1/4-20,5/8", head="hex",orient=DOWN,atype="head", anchor=TOP,tolerance="3A");  // Tight
//   }
// Example(2D,NoAxes): This example shows the gap between nut and bolt at the loosest tolerance for UTS.  This gap is what enables the parts to mesh without binding and is part of the definition for standard metal hardware.  Note that this gap is part of the standard definition for the metal hardware, not the 3D printing adjustment provided by the $slop parameter.  
//   $fn=32;
//   projection(cut=true)xrot(-90){
//       screw("1/4-20,3/8", head="hex",orient=UP,anchor=BOTTOM,tolerance="1A");
//       down(INCH*1/20*1.5) nut("1/4-20", thickness=8, nutwidth=0.5*INCH, tolerance="1B");
//   }
// Example: Here is a screw with nonstandard threading and a weird head size, which we create by modifying the screw structure:
//   spec = screw_info("M6x2,12",head="socket");
//   newspec = struct_set(spec,["head_size",20,"head_height",3]);
//   screw(newspec);
// Example: A bizarre custom screw with nothing standard about it.  If your screw is very strange, consider setting tolerance to zero so you get exactly the screw you defined.  You'll need to create your own clearance between mating threads in this case.  
//   spec = [["system","ISO"],
//           ["type","screw_info"],
//           ["pitch", 2.3],
//           ["head", "flat"],
//           ["head_size", 20],
//           ["head_size_sharp", 22],
//           ["head_angle", 60],
//           ["diameter",12],
//           ["length",22]];
//   screw(spec,tolerance=0);

function _get_spec(spec, needtype, origin, thread,   // common parameters
                   head, drive, drive_size,          // screw parameters
                   shape, thickness                  // nut parameters
                  ) =
    assert(needtype=="screw_info" || needtype=="nut_info")
    assert(is_undef(thickness) || (is_num(thickness) && thickness>0) ||
           in_list(_downcase_if_str(thickness),["thin","normal","thick","undersized","din"]),
          "thickness must be a positive number of one of \"thin\", \"thick\", \"normal\", \"undersized\", or \"DIN\"")
    assert(!(is_undef(spec) && is_undef($screw_spec)), "No screw spec given and no parent spec available to inherit")
    let(
        spec=is_undef(spec) ? $screw_spec : spec,
        spec_origin = is_struct(spec) ? struct_val(spec,"origin") : undef
    )
    assert(is_string(spec) || is_struct(spec), "Screw/nut specification must be a string or struct")
    let(
        specname = is_struct(spec) ? struct_val(spec,"name") : undef,
        name = is_string(spec) ? spec
             : struct_val(spec,"type") != needtype ?       // if we switch between screw and nut we need a name 
                   let(specname=struct_val(spec,"name"))
                   assert(is_string(specname), 
                        "Parent screw_info or nut_info structure doesn't have a valid name, but a name is needed when child is of a different type")
               specname
             : undef,
        p = is_struct(spec) ? struct_val(spec,"pitch") : undef,
        thread = is_def(name) ? thread
                 // If the origin of the struct is a hole with pitch zero and we are making a screw, try to find a nonzero pitch
               : spec_origin=="screw_hole" && origin!="screw_hole" && p==0 && is_string(specname) ?
                    let(temp_info = screw_info(specname,thread))
                    struct_val(temp_info,"pitch")
//               : spec_origin=="screw_hole" && origin=="screw_hole" && all_positive([p]) ? p
//               : origin=="screw_hole" && is_undef(thread) ? 0
               : thread
    )
    is_def(name) ? (needtype=="screw_info" ? screw_info(name,_origin=origin, thread= origin=="screw_hole" ? default(thread,true) : thread,
                                                        head=head, drive=drive, drive_size=drive_size)
                                           : nut_info(name,_origin=origin, thread=thread, shape=shape, thickness=thickness))
  : 
    assert(in_list(struct_val(spec,"type"), ["nut_info","screw_info"]), "Screw/nut spec is invalid struct type")
    assert(is_undef(thread) || thread=="none" || thread==false || thread==true || is_num(thread),
           str("Thread type applied to struct specification must be numeric, \"none\" or false but got ",thread))
    assert(is_undef(thickness) || is_num(thickness), str("thickness applied to struct specification must be numeric but is ",thickness))
    assert(is_undef(head) || head=="none", str("The only head type allowed with struct specifications is \"none\" but got ",head))
    assert(num_defined([drive,drive_size])==0, "You cannot change drive or drive_size when using a struct specification")
    assert(is_undef(shape), "You cannot change nut shape when using a struct specification")
    let(
        spec = _struct_reset(spec,
                                   [ 
                                     ["origin", origin],
                                     if (origin=="screw") ["counterbore",0],
                                     if (head=="none") ["head","none"],
                                     if (head=="none") ["drive","none"],
                                     if (thread==false || thread=="none") ["pitch",0]
                                     else if (thread!=true) ["pitch",thread],
                                     ["thickness", thickness],
                                   ], grow=true),
        inherit = is_undef(spec_origin) || spec_origin==origin 
    )
    inherit ? spec
  : struct_remove(spec, ["shaft_oversize","head_oversize"]);


function _struct_reset(s, keyval, grow=true) =
  let(
      good = [for(kv=keyval) (grow || is_def(struct_val(s,kv[0]))) && is_def(kv[1])]
  )
  struct_set(s,flatten(bselect(keyval,good)));


function _nominal_diam(spec) = struct_val(spec,"diameter")+default(struct_val(spec,"shaft_oversize"),0);
                                                    
function screw(spec, head, drive, thread, drive_size, 
             length, l, thread_len, tolerance, details=true, 
             undersize, shaft_undersize, head_undersize,
             atype="screw",anchor, spin=0, orient=UP,
             _shoulder_diam=0, _shoulder_len=0,
             bevel,bevel1,bevel2,bevelsize,
             blunt_start,blunt_start1, blunt_start2,
             _internal=false, _counterbore, _teardrop=false)
   = no_function("screw");
module screw(spec, head, drive, thread, drive_size, 
             length, l, thread_len, tolerance, details=true, 
             undersize, shaft_undersize, head_undersize,
             atype="screw",anchor, spin=0, orient=UP,
             _shoulder_diam=0, _shoulder_len=0,
             bevel,bevel1,bevel2,bevelsize,
             blunt_start,blunt_start1, blunt_start2,
             _internal=false, _counterbore, _teardrop=false)
{
   tempspec = _get_spec(spec, "screw_info", _internal ? "screw_hole" : "screw",
                        thread=thread, head=head, drive=drive, drive_size=drive_size);
   undersize = is_num(undersize) ? [undersize,undersize]
             : undersize;
   dummyA=assert(is_undef(undersize) || is_vector(undersize,2), "Undersize must be a scalar or 2-vector")
          assert(is_undef(undersize) || num_defined([shaft_undersize, head_undersize])==0,
                 "Cannot combine \"undersize\" with other more specific undersize parameters")
          assert(is_bool(_teardrop) ||_teardrop=="max" || all_nonnegative([_teardrop]), str("Invalid teardrop parameter",_teardrop));
   _teardrop = _teardrop==true ? .05 : _teardrop;   // set teardrop default
   shaft_undersize = first_defined([shaft_undersize, undersize[0]]);
   head_undersize = first_defined([head_undersize, undersize[1]]);
   dummyB=assert(is_undef(shaft_undersize) || is_finite(shaft_undersize), "shaft_undersize must be a number")
          assert(is_undef(head_undersize) || is_finite(head_undersize), "head_undersize must be a number")
          assert(is_undef(_counterbore) || is_bool(_counterbore) || (is_finite(_counterbore) && _counterbore>=0),
                 "Counterbore must be a nonnegative number of boolean");
   l = one_defined([l,length],"l,length",dflt=undef);
   _counterbore = _counterbore==true ? struct_val(tempspec,"head_height") 
                : _counterbore==false ? undef
                : _counterbore;
   head = struct_val(tempspec,"head");
   headless = head=="none";
   flathead = is_def(head) && starts_with(head,"flat");
   reset_headsize = _internal && flathead ? struct_val(tempspec,"head_size_sharp") : undef;
   spec=_struct_reset(tempspec,[
                                ["length", l],
                                ["shaft_oversize", u_mul(-1,shaft_undersize)],
                                ["head_oversize", u_mul(-1,head_undersize)],
                                ["counterbore", _counterbore],
                                ["thread_len", thread_len],
                                ["head_size", reset_headsize],
                               ]);
   dummy = _validate_screw_spec(spec);
   $screw_spec = spec;
   pitch =  struct_val(spec, "pitch") ;
   threadspec = pitch==0 ? undef : thread_specification(spec, internal=_internal, tolerance=tolerance);
   nominal_diam = _nominal_diam(spec);
   d_major = pitch==0 ? nominal_diam : mean(struct_val(threadspec, "d_major"));
   length = struct_val(spec,"length");
   counterbore = default(struct_val(spec,"counterbore"),0);
   user_thread_len = struct_val(spec,"thread_len");
   dummyC = assert(in_list(atype,["shaft","head","shank","threads","screw","shoulder"]),str("Unknown anchor type: \"",atype,"\""))
            assert(is_finite(length) && length>0, "Must specify positive screw length")
            assert(is_finite(_shoulder_len) && _shoulder_len>=0, "Must specify a nonegative shoulder length")
            assert(is_finite(_shoulder_diam) && _shoulder_diam>=0, "Must specify nonnegative shoulder diameter")
            assert(is_undef(user_thread_len) || (is_finite(user_thread_len) && user_thread_len>=0), "Must specify nonnegative thread length");
   sides = max(pitch==0 ? 3 : 12, segs(nominal_diam/2));
   rad_scale = _internal? (1/cos(180/sides)) : 1;
   islop = _internal ? 4*get_slop() : 0;
   head_height = headless || flathead ? 0 
               : counterbore==true || is_undef(counterbore) || counterbore==0 ? struct_val(spec, "head_height")
               : counterbore;
   head_diam = struct_val(spec, "head_size",0) + struct_val(spec, "head_oversize",0);
   flat_height = !flathead ? 0 
               : let( given_height = struct_val(spec, "head_height"))
                 all_positive(given_height) ? given_height
               : (struct_val(spec,"head_size_sharp")+struct_val(spec,"head_oversize",0)-d_major*rad_scale-islop)/2/tan(struct_val(spec,"head_angle")/2);

   flat_cbore_height = flathead && is_num(counterbore) ? counterbore : 0;

   blunt_start1 = first_defined([blunt_start1,blunt_start,true]);
   blunt_start2 = first_defined([blunt_start2,blunt_start,true]);

   shoulder_adj = _shoulder_len>0 ? flat_height:0;  // Adjustment because flathead height doesn't count toward shoulder length
   shoulder_full = _shoulder_len==0 ? 0 : _shoulder_len + flat_height;
   shank_len = is_def(user_thread_len) ? length - user_thread_len - (_shoulder_len==0?flat_height:0) : 0;
   thread_len = is_def(user_thread_len) ? user_thread_len
              : length - (_shoulder_len==0?flat_height:0);
   dummyD = assert(!(atype=="shank" && shank_len==0), "Specified atype of \"shank\" but screw has no shank (thread_len not given or it equals shaft length)")
            assert(!(atype=="shoulder" && _shoulder_len==0), "Specified atype of \"shoulder\" but screw has no shoulder")
            assert(!(atype=="threads" && thread_len==0), "Specified atype of \"threads\" but screw has no threaded part (thread_len=0)")
            assert(!(atype=="head" && headless), "You cannot anchor headless screws with atype=\"head\"");
   eps_gen = 0.01;
   eps_shoulder = headless && !_internal ? 0 : eps_gen;
   eps_shank = headless && !_internal && _shoulder_len==0 ? 0 : eps_gen;
   eps_thread = headless && !_internal && shank_len==0 && _shoulder_len==0 ? 0 : eps_gen;
   dummyL = assert(_shoulder_len>0 || is_undef(flat_height) || flat_height < length,
                   str("Length of screw (",length,") is shorter than the flat head height (",flat_height,")"));
   offset = atype=="head" ? (-head_height+flat_height-flat_cbore_height)/2
          : atype=="shoulder" ? _shoulder_len/2 + flat_height
          : atype=="shaft" ? _shoulder_len + (length+flat_height+shoulder_adj)/2
          : atype=="shank" ? _shoulder_len + (length-thread_len+flat_height+shoulder_adj)/2
          : atype=="threads" ? _shoulder_len + shoulder_adj + length-thread_len + thread_len/2
          : atype=="screw" ? (length-head_height+_shoulder_len+shoulder_adj-flat_cbore_height)/2
          : assert(false,"Unknown atype");
   dummyM = //assert(!headless || !in_list(anchor,["head_top","head_bot","head_center"]), str("Anchor \"",anchor,"\" not allowed for headless screw"))
            assert(shank_len>0 || !in_list(anchor,["shank_top","shank_bot","shank_center"]),
                   str("Screw has no unthreaded shank so anchor \"",anchor,"\" is not allowed"));
   anchor_list = [
          named_anchor("top", [0,0,offset+head_height+flat_cbore_height]),
          named_anchor("bot", [0,0,-length-shoulder_full+offset]),
          named_anchor("center", [0,0, -length/2 - shoulder_full/2 + head_height/2 + offset]),
          named_anchor("head_top", [0,0,head_height+offset]),
          named_anchor("head_bot", [0,0,-flat_height+offset]),
          named_anchor("head_center", [0,0,(head_height-flat_height)/2+offset]),
          if (_shoulder_len>0) named_anchor("shoulder_top", [0,0,offset-flat_height]),
          if (_shoulder_len>0) named_anchor("shoulder_bot", [0,0,offset-shoulder_full]),
          if (_shoulder_len>0) named_anchor("shoulder_center", [0,0,offset-flat_height-_shoulder_len/2]),
          named_anchor("shaft_top", [0,0,-_shoulder_len-flat_height+offset]),
          named_anchor("shaft_bot", [0,0,-length-shoulder_full+offset]),
          named_anchor("shaft_center", [0,0,(-_shoulder_len-flat_height-length-shoulder_full)/2+offset]),
          if (shank_len>0) named_anchor("shank_top", [0,0,-_shoulder_len-flat_height+offset]),
          if (shank_len>0) named_anchor("shank_bot", [0,0,-shank_len-_shoulder_len-flat_height+offset]),
          if (shank_len>0) named_anchor("shank_center", [0,0,-shank_len/2-_shoulder_len-flat_height+offset]),
          named_anchor("threads_top", [0,0,-shank_len-_shoulder_len-flat_height+offset]),
          named_anchor("threads_bot", [0,0,-length-shoulder_full+offset]),
          named_anchor("threads_center", [0,0,(-shank_len-length-_shoulder_len-shoulder_full-flat_height)/2+offset])
   ];
   vnf = head=="hex" && atype=="head" && counterbore==0 ? linear_sweep(hexagon(id=head_diam*rad_scale),height=head_height,center=true) : undef;
   head_diam_full = head=="hex" ? 2*head_diam/sqrt(3) : head_diam;
   attach_d = in_list(atype,["threads","shank","shaft"]) ? d_major 
            : atype=="screw" ? max(d_major,_shoulder_diam,default(head_diam_full,0))
            : atype=="shoulder" ? _shoulder_diam
            : is_def(vnf) ? undef
            : head_diam_full;
   attach_l = atype=="shaft" ? length-(_shoulder_len>0?0:flat_height)
            : atype=="shoulder" ? _shoulder_len
            : atype=="shank" ? shank_len
            : atype=="threads" ? thread_len
            : atype=="screw" ? length+head_height+shoulder_full + flat_cbore_height
            : is_def(vnf) ? undef
            : head_height+flat_height+flat_cbore_height;
   bevelsize = default(bevelsize, d_major/12);
   bevel1 = first_defined([bevel1,bevel,true]);
   bevel2 = first_defined([bevel2,bevel,headless && _shoulder_len==0 && shank_len==0]);
   attachable(
              vnf = vnf, 
              d = u_add(u_mul(attach_d, rad_scale), islop),
              l = attach_l,
              orient = orient,
              anchor = anchor,
              spin = spin,
              anchors=anchor_list)
   {
     up(offset)
       difference(){
         union(){
           screw_head(spec,details,counterbore=counterbore,flat_height=flat_height,
                      slop=islop,teardrop=_teardrop);
           if (_shoulder_len>0)
             up(eps_shoulder-flat_height){
               if (_teardrop!=false) //////
                 teardrop(d=_shoulder_diam*rad_scale+islop,cap_h=is_num(_teardrop) ? (_shoulder_diam*rad_scale+islop)/2*(1+_teardrop):undef,
                          h=_shoulder_len+eps_shoulder, anchor=FRONT, orient=BACK, $fn=sides);
               else
                 cyl(d=_shoulder_diam*rad_scale+islop, h=_shoulder_len+eps_shoulder, anchor=TOP, $fn=sides, chamfer1=details ? _shoulder_diam/30:0);
             }
           if (shank_len>0 || pitch==0){
             L = pitch==0 ? length - (_shoulder_len==0?flat_height:0) : shank_len;
             bevsize = (_internal ? -1 : 1)*bevelsize;
             bev1 = pitch!=0 ? 0
                  : bevel1==true ? bevsize
                  : bevel1==false ? 0
                  : bevel1=="reverse" ? -bevsize
                  : bevel1;
             bev2 = pitch!=0 ? 0
                  : bevel2==true ? bevsize
                  : bevel2==false ? 0
                  : bevel2=="reverse" ? -bevsize
                  : bevel2;
             down(_shoulder_len+flat_height-eps_shank)
               if (_teardrop!=false)  ///////
                 teardrop(d=d_major*rad_scale+islop, cap_h=is_num(_teardrop) ? (d_major*rad_scale+islop)/2*(1+_teardrop) : undef,
                          h=L+eps_shank, anchor=FRONT, orient=BACK, $fn=sides, chamfer1=bev1, chamfer2=bev2);
               else
                 cyl(d=d_major*rad_scale+islop, h=L+eps_shank, anchor=TOP, $fn=sides, chamfer1=bev1, chamfer2=bev2);
           }
           if (thread_len>0 && pitch>0){
             down(_shoulder_len+flat_height+shank_len-eps_thread)
                   threaded_rod([mean(struct_val(threadspec, "d_minor")),
                                 mean(struct_val(threadspec, "d_pitch")),
                                 d_major], 
                      pitch = struct_val(threadspec, "pitch"),
                      l=thread_len+eps_thread, left_handed=false, internal=_internal, 
                      bevel1=bevel1,
                      bevel2=bevel2,teardrop=_teardrop,
                      blunt_start=blunt_start, blunt_start1=blunt_start1, blunt_start2=blunt_start2, 
                      $fn=sides, anchor=TOP);
            }
             
         }
         if (!_internal) _driver(spec);
       }
     children();
   }  
}



// Module: screw_hole()
// Synopsis: Creates a screw hole.
// SynTags: Geom
// Topics: Threading, Screws
// See Also: screw()
// Usage:
//   screw_hole([spec], [head], [thread=], [length=|l=], [oversize=], [hole_oversize=], [teardrop=], [head_oversize], [tolerance=], [$slop=], [blunt_start=], [anchor=], [atype=], [orient=], [spin=]) [ATTACHMENTS];
// Description:
//   Create a screw hole mask.  See [screw and nut parameters](#section-screw-and-nut-parameters) for details on the parameters that define a screw.
//   The screw hole can be threaded to receive a screw or it can be an unthreaded clearance hole.  
//   The tolerance determines the dimensions of the screw
//   based on ISO and ASME standards.  Screws fabricated at those dimensions will mate properly with standard hardware.
//   The $slop argument makes the hole larger by 4*$slop to account for printing overextrusion.  It defaults to 0.
//   .
//   You can generate a screw specification from {{screw_info()}}, possibly create a modified version, and pass that in rather than giving the parameters.
//   .
//   The tolerance should be a nut tolerance for a threaded hole or a clearance hole tolerance for clearance holes.
//   For clearance holes, the UTS tolerances are "normal", "loose" and "close".  ASME also specifies the same naming for metric clearance holes.
//   However, ISO gives "fine", "medium" and "coarse" instead.  This function accepts all of these in either system.  It also takes "tight" to be equivalent to "close",
//   even though no standard suggests it, because it's a natural opposite of "loose".  The official tolerance designations for ISO are "H12" for "fine", "H13" for "medium"
//   and "H14" for "coarse".  These designations will also work, but only for metric holes.  You can also set tolerance to 0 or "none" to produce holes at the nominal size.
//   .
//   If you want to produce holes for tapping you can use a tolerance of "tap".  This produces a hole of the nominal screw diameter reduced by the thread pitch.  You may still
//   need to adjust $slop for best results.  Some people screw machine screws directly into plastic without tapping.  This works better with a somewhat larger hole, so
//   a tolerance of "self tap" produces such a hole.  Note that this tolerance also makes the default bevel2=true to bevel the top, which makes it much easier
//   to start the screw.  The "self tap" tolerance subtracts `0.72 * pitch` when pitch is below 1mm, `0.6 * pitch` when the pitch is over 1.5mm, and it interpolates between.
//   It was tested in PLA with a Prusa MK3S and $slop=0.05 and worked on UTS screws from #2 up to 1/2 inch.  
//   .
//   The counterbore parameter adds a cylindrical clearance hole above the screw shaft.  For flat heads it extends above the flathead and for other screw types it 
//   replaces the head with a cylinder large enough in diameter for the head to fit.  For a flat head you must specify the length of the counterbore.  For other heads you can
//   set counterbore to true and it will be sized to match the head height.  The counterbore will extend 0.01 above the TOP of the hole mask to ensure no
//   problems with differences.  Note that the counterbore defaults to true for non-flathead screws.  If you want the actual head shape to appear, set counterbore to zero.
//   .
//   For 3d printing circular holes can be problematic.  One solution is to use octagonal holes, setting $fn=8.  Another option is to use a teardrop hole, which
//   can be accomplished by setting `teardrop=true`.  The point of the teardrop will point in the Y direction (BACK) so you will need to ensure that you orient it
//   correctly in your final model.  
//   .
//   Anchoring for screw_hole() is the same as anchoring for {{screw()}}, with all the same anchor types and named anchors.  If you specify a counterbore it is treated as
//   the "head", or in the case of flat heads, it becomes part of the head.  If you make a teardrop hole the point is ignored for purposes of anchoring.
// Arguments:
//   spec = screw specification, e.g. "M5x1" or "#8-32".  See [screw naming](#subsection-screw-naming).  This can also be a screw specification structure of the form produced by {{screw_info()}}.  
//   head = head type.  See [screw heads](#subsection-screw-heads)  Default: none
//   ---
//   thread = thread type or specification for threaded masks, true to make a threaded mask with the standard threads, or false to make an unthreaded mask.  See [screw pitch](#subsection-standard-screw-pitch). Default: false
//   teardrop = If true, adds a teardrop profile to the hole for 3d printability of horizontal holes. If numeric, specifies the proportional extra distance of the teardrop flat top from the screw center, or set to "max" for a pointed teardrop. Default: false
//   oversize = amount to increase diameter of the screw hole (hole and countersink).  A scalar or length 2 vector.  Default: use computed tolerance
//   hole_oversize = amount to increase diameter of the hole.  Overrides the use of tolerance and replaces any settings given in the screw specification. 
//   head_oversize = amount to increase diameter of head.  Overrides the user of tolerance and replaces any settings given in the screw specification.  
//   length / l= length of screw (in mm)
//   counterbore = set to length of counterbore, or true to make a counterbore equal to head height.  Default: false for flat heads and headless, true otherwise
//   tolerance = threading or clearance hole tolerance.  For internal threads, detrmines actual thread geometry based on nominal sizing.  See [tolerance](#subsection-tolerance). Default is "2B" for UTS and 6H for ISO.  For clearance holes, determines how much clearance to add.  Default is "normal".  
//   bevel = if true create bevel at both ends of hole.  Default: see below
//   bevel1 = if true create bevel at bottom end of hole.  Default: false
//   bevel2 = if true create bevel at top end of hole.     Default: true when tolerance="self tap", false otherwise
//   blunt_start = if true and hole is threaded, create blunt start threads.  Default: true
//   blunt_start1 = if true and hole is threaded, create blunt start threads at bottom end.
//   blunt_start2 = if true and hole is threaded, create blunt start threads top end.
//   $slop = add extra gap to account for printer overextrusion.  Default: 0
//   atype = anchor type, one of "screw", "head", "shaft", "threads", "shank"
//   anchor = Translate so anchor point on the shaft is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Side Effects:
//   `$screw_spec` is set to the spec specification structure. 
// Anchor Types:
//   screw = the entire screw (default)
//   head = screw head (invalid for headless screws)
//   shaft = screw shaft
//   shank = unthreaded section of shaft (invalid if screw is fully threaded)
//   threads = threaded section of screw     
// Named Anchors:
//   "top" = top of screw
//   "bot" = bottom of screw
//   "center" = center of screw
//   "head_top" = top of head (invalid for headless screws)
//   "head_bot" = bottom of head (invalid for headless screws)
//   "head_center" = center of head (invalid for headless screws)
//   "shaft_top" = top of shaft
//   "shaft_bot" = bottom of shaft
//   "shaft_center" = center of shaft
//   "shank_top" = top of shank (invalid if screw is fully threaded)
//   "shank_bot" = bottom of shank (invalid if screw is fully threaded)
//   "shank_center" = center of shank (invalid if screw is fully threaded)
//   "threads_top" = top of threaded portion of screw (invalid if thread_len=0)
//   "threads_bot" = bottom of threaded portion of screw (invalid if thread_len=0)
//   "threads_center" = center of threaded portion of screw (invalid if thread_len=0)
// Example: Counterbored clearance hole
//   diff()
//     cuboid(20)
//       attach(TOP)
//         screw_hole("1/4-20,.5",head="socket",counterbore=5,anchor=TOP);
// Example: Clearance hole for flathead 
//   diff()
//     cuboid(20)
//       attach(TOP)
//          screw_hole("1/4-20,.5",head="flat",counterbore=0,anchor=TOP);
// Example: Threaded hole, with inward bevel at the base
//   bottom_half()
//     diff()
//       cuboid(20)
//         attach(FRONT)
//           screw_hole("M16,15",anchor=TOP,thread=true,bevel1="reverse");
function screw_hole(spec, head, thread, oversize, hole_oversize, head_oversize, 
             length, l, thread_len, tolerance=undef, counterbore, teardrop=false,
             bevel, bevel1, bevel2, blunt_start, blunt_start1, blunt_start2, 
             atype="screw",anchor=CENTER,spin=0, orient=UP)
    = no_function("screw_hole");
module screw_hole(spec, head, thread, oversize, hole_oversize, head_oversize, 
             length, l, thread_len, tolerance=undef, counterbore, teardrop=false,
             bevel, bevel1, bevel2, blunt_start, blunt_start1, blunt_start2, 
             atype="screw",anchor=CENTER,spin=0, orient=UP)
{
   screwspec = _get_spec(spec, "screw_info", "screw_hole", 
                        thread=thread, head=head);
   bevel1 = first_defined([bevel1,bevel,false]);
   bevel2 = first_defined([bevel2,bevel,tolerance=="self tap"]);
   thread = default(thread,false);
   checkhead = struct_val(screwspec,"head");
   default_counterbore = checkhead=="none" || starts_with(checkhead,"flat") ? 0 : true;
   counterbore = default(counterbore, default_counterbore);
   dummy = _validate_screw_spec(screwspec);
   threaded = thread==true || (is_finite(thread) && thread>0) || (is_undef(thread) && struct_val(screwspec,"pitch")>0);
   oversize = force_list(oversize,2);
   hole_oversize = first_defined([hole_oversize, oversize[0],struct_val(screwspec,"shaft_oversize")]);
   head_oversize = first_defined([head_oversize, oversize[1],struct_val(screwspec,"head_oversize")]);
   if (threaded || is_def(hole_oversize) || tolerance==0 || tolerance=="none") {
     default_tag("remove")
       screw(spec,head=head,thread=thread,shaft_undersize=u_mul(-1,hole_oversize), head_undersize=u_mul(-1,head_oversize),
             blunt_start=blunt_start, blunt_start1=blunt_start1, blunt_start2=blunt_start2, 
             length=length,l=l,thread_len=thread_len, tolerance=tolerance, _counterbore=counterbore,
             bevel1=bevel1, bevel2=bevel2, 
             atype=atype, anchor=anchor, spin=spin, orient=orient, _internal=true, _teardrop=teardrop)
         children();
   }
   else {
     tolerance = default(tolerance, "normal");
     pitch = struct_val(screwspec,"pitch");
     dummy3 = assert((downcase(tolerance) != "tap" && downcase(tolerance)!="self tap") || pitch!=0,
                     "\"tap\" clearance requires a pitch size, but pitch is set to zero");
     // UTS clearances from ASME B18.2.8
     UTS_clearance = [
       [ // Close fit
         [0.1120 * INCH,0.008*INCH],
         [0.1250 * INCH, 1/64*INCH],
         [7/16   * INCH, 1/64*INCH],
         [1/2    * INCH, 1/32*INCH],
         [1.25   * INCH, 1/32*INCH],
         [1.375  * INCH, 1/16*INCH]
       ],
       [ // Normal fit
         [0.1120 * INCH, 1/64*INCH],
         [0.1250 * INCH, 1/32*INCH],
         [7/16   * INCH, 1/32*INCH],
         [1/2    * INCH, 1/16*INCH],
         [7/8    * INCH, 1/16*INCH],
         [1      * INCH, 3/32*INCH],
         [1.25   * INCH, 3/32*INCH],
         [1.375  * INCH,  1/8*INCH],
       ],
       [ // Loose fit
         [0.1120 * INCH, 1/32*INCH],
         [0.1250 * INCH, 3/64*INCH],
         [7/16   * INCH, 3/64*INCH],
         [1/2    * INCH, 7/64*INCH],
         [5/8    * INCH, 7/64*INCH],
         [3/4    * INCH, 5/32*INCH],
         [1      * INCH, 5/32*INCH],
         [1.125  * INCH, 3/16*INCH],
         [1.25   * INCH, 3/16*INCH],
         [1.375  * INCH,15/64*INCH]
       ]
     ];
     // ISO clearances appear in ASME B18.2.8 and ISO 273
     ISO_clearance = [
       [ // Close, Fine, H12 
         [2.5, 0.1],
         [3.5, 0.2],
         [4,   0.3],
         [5,   0.3],
         [6,   0.4],
         [8,   0.4],
         [10,  0.5],
         [12,  1],
         [42,  1],
         [48,  2],
         [80,  2],
         [90,  3],
         [100, 4],
       ],
       [  // Normal, Medium, H13
         [1.6, 0.2],
         [2,   0.4],
         [3.5, 0.4],
         [4,   0.5],
         [5,   0.5],
         [6,   0.6],
         [8,   1],
         [10,  1],
         [12,  1.5],
         [16,  1.5],
         [20,  2],
         [24,  2],
         [30,  3],
         [42,  3],
         [48,  4],
         [56,  6],
         [90,  6],
         [100, 7],
       ],
       [  // Loose, Coarse, H14
         [1.6, 0.25],
         [2,   0.3],
         [3,   0.6],
         [3.5, 0.7],
         [4,   0.8],
         [5,   0.8],
         [6,   1],
         [8,   2],
         [10,  2],
         [12,  2.5],
         [16,  2.5],
         [20,  4],
         [24,  4],
         [30,  5],
         [36,  6],
         [42,  6],
         [48,  8],
         [56, 10],
         [72, 10],
         [80, 11],
         [90, 11],
         [100,12],
       ]
     ];
     tol_ind = in_list(downcase(tolerance), ["close", "fine", "tight"]) ? 0
             : in_list(downcase(tolerance), ["normal", "medium", "tap", "self tap"]) ? 1
             : in_list(downcase(tolerance), ["loose", "coarse"]) ? 2
             : in_list(tolerance, ["H12","H13","H14"]) ?
                   assert(struct_val(screwspec,"system")=="ISO", str("Hole tolerance ", tolerance, " only allowed with ISO screws"))
                   parse_int(substr(tolerance,1))-12
             : assert(false,str("Unknown tolerance ",tolerance, " for unthreaded clearance hole.  Use one of \"close\", \"normal\", or \"loose\""));
     tol_table = struct_val(screwspec,"system")=="UTS" ? UTS_clearance[tol_ind] : ISO_clearance[tol_ind];
     tol_gap = lookup(_nominal_diam(screwspec), tol_table);
     // If we got here, hole_oversize is undefined and oversize is undefined
     hole_oversize = downcase(tolerance)=="tap" ? -pitch
                   : downcase(tolerance)=="self tap" ? -pitch*lookup(pitch,[[1,0.72],[1.5,.6]])
                   : tol_gap;
     head_oversize = default(head_oversize, tol_gap);
     default_tag("remove")     
       screw(spec,head=head,thread=0,shaft_undersize=-hole_oversize, head_undersize=-head_oversize, 
             length=length,l=l,thread_len=thread_len, _counterbore=counterbore,
             bevel1=bevel1, bevel2=bevel2, bevelsize=pitch>0?pitch:undef,
             atype=atype, anchor=anchor, spin=spin, orient=orient, _internal=true, _teardrop=teardrop)
         children();
   }
} 

// Module: shoulder_screw()
// Synopsis: Creates a shoulder screw.
// SynTags: Geom
// Topics: Threading, Screws
// See Also: screw(), screw_hole()
// Usage:
//   shoulder_screw(s, d, length, [head=], [thread_len=], [tolerance=], [head_size=], [drive=], [drive_size=], [thread=], [undersize=], [shaft_undersize=], [head_undersize=], [shoulder_undersize=],[atype=],[anchor=],[orient=],[spin=]) [ATTACHMENTS];
// Description:
//   Create a shoulder screw.  See [screw and nut parameters](#section-screw-and-nut-parameters) for details on the parameters that define a screw.
//   The tolerance determines the dimensions of the screw
//   based on ISO and ASME standards.  Screws fabricated at those dimensions will mate properly with standard hardware.
//   Note that the $slop argument does not affect the size of screws: it only adjusts screw holes.  This will work fine
//   if you are printing both parts, but if you need to mate printed screws to metal parts you may need to adjust the size
//   of the screws, which you can do with the undersize arguments.
//   .
//   Unlike a regular screw, a shoulder screw is based on its shoulder dimensions: diameter and length.  The ISO and ASME standards
//   specify for a given shoulder diameter the thread size and even the length of the threads.  Note that these standards specify only
//   a small range of sizes.  You can specify a shoulder screw by giving the system, either "ISO" or "UTS" and the shoulder diameter
//   and length, and shoulder_screw() will supply the other parameters.
//   .
//   Hardware sources like McMaster sell many screws that don't comply with the standards.  If you want to make such a screw then
//   you can specify parameters like thread_len, the length of the threaded portion below the shoulder, and you can choose a different head
//   type.  You will need to specify the size of the head, since it cannot be looked up in tables.  You can also 
//   generate a screw specification from {{screw_info()}}, possibly create a modified version using {{struct_set()}}, and pass that in rather than giving the parameters.
//   .
//   The anchors and anchor types are the same as for {{screw()}} except that there is an anchor type for the shoulder and an additional set of named anchors
//   refering to parts of the shoulder.  
// Arguments:
//   s = screw system to use, case insensitive, either "ISO", "UTS", "english" or "metric", or a screw name or specification.  See [screw naming](#subsection-screw-naming).
//   d = nominal shoulder diameter in mm for ISO or inches for UTS
//   length = length of the shoulder (in mm)
//   ---
//   thread_len = length of threads
//   tolerance = screw tolerance.  Determines actual screw thread geometry based on nominal sizing.  See [tolerance](#subsection-tolerance). Default is "2A" for UTS and "6g" for ISO.
//   drive = drive type.  See [screw heads](#subsection-screw-heads) set to "none" for no drive.  Default: "hex"
//   drive_size = size of the drive recess
//   thread = thread type or specification. See [screw pitch](#subsection-standard-screw-pitch). Default: "coarse"
//   spec = screw specification to define the thread size 
//   head_size = scalar or vector to give width or [width, height].  If you only give width, height is computed using a formula for socket heads.  For flat head screws the second value in the vector is the sharp size; if you don't give it then the sharp size will be 12% more than the given size
// Side Effects:
//   `$screw_spec` is set to the spec specification structure. 
// Anchor Types:
//   screw = the entire screw (default)
//   head = screw head (invalid for headless screws)
//   shoulder = the shoulder
//   shaft = screw shaft
//   threads = threaded section of screw     
// Named Anchors:
//   "top" = top of screw
//   "bot" = bottom of screw
//   "center" = center of screw
//   "head_top" = top of head (invalid for headless screws)
//   "head_bot" = bottom of head (invalid for headless screws)
//   "head_center" = center of head (invalid for headless screws)
//   "shoulder_top" = top of shoulder
//   "shoulder_bot" = bottom of shoulder
//   "shoulder_center" = center of shoulder
//   "shaft_top" = top of shaft
//   "shaft_bot" = bottom of shaft
//   "shaft_center" = center of shaft
//   "threads_top" = top of threaded portion of screw (invalid if thread_len=0)
//   "threads_bot" = bottom of threaded portion of screw (invalid if thread_len=0)
//   "threads_center" = center of threaded portion of screw (invalid if thread_len=0)
// Example: ISO shoulder screw
//   shoulder_screw("iso",10,length=20);
// Example: English shoulder screw
//   shoulder_screw("english",1/2,length=20);
// Example: Custom example.  You must specify thread_len and head_size when creating custom configurations.  
//   shoulder_screw("M6", 9.3, length=17, thread_len=8, head_size=14);
// Example: Another custom example:
//   shoulder_screw("M6", 9.3, length=17, thread_len=8, head_size=14, head="button", drive="torx");
// Example: Threadless 
//   shoulder_screw("iso",10,length=15,thread=0);
// Example: No drive recess
//   shoulder_screw("iso",10,length=15,drive="none");
// Example: Headless
//   shoulder_screw("iso", 16, length=20, head="none");
// Example: Changing head height
//   shoulder_screw("iso", 16, length=20, head_size=[24,5]);
function shoulder_screw(s,d,length,head, thread_len, tolerance, head_size, drive, drive_size, thread,
                      undersize, shaft_undersize, head_undersize, shoulder_undersize=0,
                      blunt_start, blunt_start1, blunt_start2, 
                      atype="screw", anchor=BOT, orient,spin) = no_function("shoulder_screw");
module shoulder_screw(s,d,length,head, thread_len, tolerance, head_size, drive, drive_size, thread,
                      undersize, shaft_undersize, head_undersize, shoulder_undersize=0,
                      blunt_start, blunt_start1, blunt_start2, 
                      atype="screw", anchor=BOT, orient,spin)
{
  d1= assert(is_num(d) && d>0, "Must specify shoulder diameter")
      assert (is_num(length) && length>0, "Must specify shoulder length");
  systemOK=is_string(s) && in_list(downcase(s),["iso","metric","uts","english"]);
  info_temp = systemOK ? undef
            : is_struct(s) ? s
            : screw_info(s);
  infoOK = systemOK ? false
         : _nominal_diam(info_temp) && struct_val(info_temp,"pitch") && struct_val(info_temp,"system");
  d2=assert(systemOK || infoOK, "System must be \"ISO\", \"UTS\", \"English\" or \"metric\" or a valid screw specification string")
     assert(!is_struct(s) || num_defined([drive, drive_size, thread, head])==0,
            "With screw struct, \"head\", \"drive\", \"drive_size\" and \"thread\" are not allowed");
  drive = drive=="none" ? undef : default(drive,"hex");
  thread = default(thread,"coarse");
  head = default(head, "socket");                                    
  usersize = systemOK ? undef : s;
  system = systemOK ? s : struct_val(info_temp,"system");
  undersize = is_undef(undersize) ? undersize
            : is_num(undersize) ? [undersize,undersize]
            : undersize;
  shaft_undersize = first_defined([shaft_undersize, undersize[0], 0]);
  head_undersize = first_defined([head_undersize, undersize[1], 0]);
  
  iso = in_list(downcase(system), ["iso","metric"]);

  factor = iso ? 1 : INCH;

  table = iso ?   //  iso shoulder screws, hex drive socket head  ISO 7379
                  //  Mcmaster has variations like 12mm shoulder for m10, 6mm shoulder for M5
                  // shld   screw  thread  head  hex  hex     head  
                  // diam   size   length  diam      depth     ht 
                  [                                                 
                     [6.5,  ["M5",   9.5,   10,   3,  2.4,     4.5]],
                     [8  ,  ["M6",   11 ,   13,   4,  3.3,     5.5]],
                     [10 ,  ["M8",   13 ,   16,   5,  4.2,     7  ]],
                     [13 ,  ["M10",  16 ,   18,   6,  4.9,     9  ]],
                     [16 ,  ["M12",  18 ,   24,   8,  6.6,    11  ]],
                     [20 ,  ["M16",  22 ,   30,  10,  8.8,    14  ]],
                     [25 ,  ["M20",  27 ,   36,  12,  10 ,    16  ]]
                   ]
        :
                   // UTS shoulder screws, b18.3 (table 13)
                   // sh diam  screw   thread len, head diam   hex size  hex depth
                   [
                      [1/8  ,  ["#4",     5/32 ,    1/4      ,  5/64   ,  0.067]],
                      [5/32 ,  ["#6",     3/16 ,    9/32     ,  3/32   ,  0.067]],
                      [3/16 ,  ["#8",     3/16 ,    5/16     ,  3/32   ,  0.079]],
                      [1/4  ,  ["#10",    3/8  ,    3/8      ,  1/8    ,  0.094]],
                      [5/16 ,  ["1/4",    7/16 ,    7/16     ,  5/32   ,  0.117]],
                      [3/8  ,  ["5/16",   1/2  ,    9/16     ,  3/16   ,  0.141]],
                      [1/2  ,  ["3/8",    5/8  ,    3/4      ,  1/4    ,  0.188]],
                      [5/8  ,  ["1/2",    3/4  ,    7/8      ,  5/16   ,  0.234]],
                      [3/4  ,  ["5/8",    7/8  ,    1        ,  3/8    ,  0.281]],
                      [1    ,  ["3/4",    1    ,    1+5/16   ,  1/2    ,  0.375]],
                      [1+1/4,  ["7/8",    1+1/8,    1+3/4    ,  5/8    ,  0.469]],
                      [1+1/2,  ["1.125",  1+1/2,    2+1/8    ,  7/8    ,  0.656]],
                      [1+3/4,  ["1.25",   1+3/4,    2+3/8    ,  1      ,  0.750]],
                      [2    ,  ["1.5",    2    ,    2+3/4    ,  1+1/4  ,  0.937]]
                   ];           
  entry = struct_val(table, d);
  shoulder_diam = d * factor - shoulder_undersize;
  spec = first_defined([usersize, entry[0]]);
  dummy2=assert(is_def(spec),"No shoulder screw found with specified diameter");
  thread_len = first_defined([thread_len, u_mul(entry[1],factor)]);
  head_size = first_defined([head_size, u_mul(entry[2],factor)]);
  drive_size = first_defined([drive_size, u_mul(entry[3],factor)]);
  drive_depth = u_mul(entry[4],factor);
  head_height_table = iso? first_defined([entry[5],d/2+1.5])
                    : d<3/4 ? (d/2 + 1/16)*INCH
                    : (d/2 + 1/8)*INCH;
  shoulder_tol = tolerance==0 || tolerance=="none" ? 0
               : iso ? lookup(d, [[10,0.03],[13,0.037],[16,0.037],[20,0.046]])
               : 1; //0.003 * INCH;
  info = is_struct(s) ? s
       : screw_info(spec, head, drive, drive_size=drive_size, thread=thread);

  final_headsize = is_num(head_size) ? head_size
                 : head_size[0];
  d5=assert(is_num(final_headsize), "Head size invalid or missing");
  final_sharpsize =  head!="flat" ? undef : is_vector(head_size)? head_size[1] : final_headsize*1.12;
  head_height_flat = head!="flat" ? undef : (final_sharpsize-(shoulder_diam-shoulder_tol))/2/tan(struct_val(info,"head_angle")/2);
  headfields = concat(
                      ["head_size", final_headsize],
                      head=="flat" ? ["head_size_sharp", final_sharpsize, "head_height", head_height_flat]
                                   : ["head_height",   is_vector(head_size) ? head_size[1]
                                                     : is_num(head_height_table)? head_height_table
                                                     : final_headsize/2 + 1.5],
                      is_def(drive_depth) ? ["drive_depth", drive_depth] :[]
                     );
  dummy3=assert(is_num(length) && length>0, "Must give a positive shoulder length");
  screw(struct_set(info, headfields),
        _shoulder_len = length, _shoulder_diam = shoulder_diam-shoulder_tol,
        length=thread_len, tolerance=tolerance, shaft_undersize=shaft_undersize, head_undersize=head_undersize,
        blunt_start=blunt_start, blunt_start1=blunt_start1, blunt_start2=blunt_start2,                 
        atype=atype, anchor=anchor, orient=orient, spin=spin)
    children();
}        
                     


module _driver(spec)
{
  drive = struct_val(spec,"drive");
  if (is_def(drive) && drive!="none") {
    head = struct_val(spec,"head");
    diameter = _nominal_diam(spec);
    drive_size = struct_val(spec,"drive_size");
    drive_diameter = struct_val(spec, "drive_diameter");
    drive_depth = first_defined([struct_val(spec, "drive_depth"), .7*diameter]); // Note hack for unspecified depth
    head_top = starts_with(head,"flat") || head=="none" ? 0 :
               struct_val(spec,"head_height");
    up(head_top-drive_depth){
      // recess should be positioned with its bottom center at (0,0) and the correct recess depth given above
      if (drive=="phillips") phillips_mask(drive_size,anchor=BOTTOM);
      if (drive=="torx") torx_mask(size=drive_size, l=drive_depth+1, center=false);
      if (drive=="hex") hex_drive_mask(drive_size,drive_depth+1,anchor=BOT);
      if (drive=="slot") {
          head_width = first_defined([u_add(struct_val(spec, "head_size"),struct_val(spec,"head_oversize",0)), diameter]);
          cuboid([2*head_width, drive_size, drive_depth+1],anchor=BOTTOM);
      }
    }
  }
}


function _ISO_thread_tolerance(diameter, pitch, internal=false, tolerance=undef) =
  let(
    P = pitch,
    H = P*sqrt(3)/2,
    tolerance = first_defined([tolerance, internal?"6H":"6g"]),

    pdiam = diameter - 2*3/8*H,          // nominal pitch diameter
    mindiam = diameter - 2*5/8*H,        // nominal minimum diameter

    EI = [   // Fundamental deviations for nut thread
          ["G", 15+11*P],
          ["H", 0],            // Standard practice
         ],

    es = [    // Fundamental deviations for bolt thread
          ["e", -(50+11*P)],   // Exceptions if P<=0.45mm
          ["f", -(30+11*P)],
          ["g", -(15+11*P)],   // Standard practice
          ["h", 0]             // Standard practice for tight fit
         ],

    T_d6 = 180*pow(P,2/3)-3.15/sqrt(P),
    T_d = [  // Crest diameter tolerance for major diameter of bolt thread
           [4, 0.63*T_d6],
           [6, T_d6],
           [8, 1.6*T_d6]
          ],

    T_D1_6 = 0.2 <= P && P <= 0.8 ? 433*P - 190*pow(P,1.22) :
             P > .8 ? 230 * pow(P,0.7) : undef,
    T_D1 = [ // Crest diameter tolerance for minor diameter of nut thread
             [4, 0.63*T_D1_6],
             [5, 0.8*T_D1_6],
             [6, T_D1_6],
             [7, 1.25*T_D1_6],
             [8, 1.6*T_D1_6]
           ],

    rangepts = [0.99, 1.4, 2.8, 5.6, 11.2, 22.4, 45, 90, 180, 300],
    d_ind = floor(lookup(diameter,hstack(rangepts,count(len(rangepts))))),
    avgd = sqrt(rangepts[d_ind]* rangepts[d_ind+1]),

    T_d2_6 = 90*pow(P, 0.4)*pow(avgd,0.1),
    T_d2 = [ // Pitch diameter tolerance for bolt thread
             [3, 0.5*T_d2_6],
             [4, 0.63*T_d2_6],
             [5, 0.8*T_d2_6],
             [6, T_d2_6],
             [7, 1.25*T_d2_6],
             [8, 1.6*T_d2_6],
             [9, 2*T_d2_6],
           ],

    T_D2 = [  // Tolerance for pitch diameter of nut thread
              [4, 0.85*T_d2_6],
              [5, 1.06*T_d2_6],
              [6, 1.32*T_d2_6],
              [7, 1.7*T_d2_6],
              [8, 2.12*T_d2_6]
           ],

    internal = is_def(internal) ? internal : tolerance[1] != downcase(tolerance[1]),
    internalok = !internal || (
                               len(tolerance)==2 && str_find("GH",tolerance[1])!=undef && str_find("45678",tolerance[0])!=undef),
    tol_str = str(tolerance,tolerance),
    externalok = internal || (
                              (len(tolerance)==2 || len(tolerance)==4)
                                                          && str_find("efgh", tol_str[1])!=undef
                                                          && str_find("efgh", tol_str[3])!=undef
                                                          && str_find("3456789", tol_str[0]) != undef
                                                          && str_find("468", tol_str[2]) !=undef)
  )
  assert(internalok,str("Invalid ISO internal thread tolerance, ",tolerance,".  Must have form <digit><letter>"))
  assert(externalok,str("invalid ISO external thread tolerance, ",tolerance,".  Must have form <digit><letter> or <digit><letter><digit><letter>"))
  let(
    tol_num_pitch = parse_num(tol_str[0]),
    tol_num_crest = parse_num(tol_str[2]),
    tol_letter = tol_str[1]
  )
  assert(tol_letter==tol_str[3],str("Invalid tolerance, ",tolerance,".  Cannot mix different letters"))
  internal ?
    let(  // Nut case
      fdev = struct_val(EI,tol_letter)/1000,
      Tdval = struct_val(T_D1, tol_num_crest)/1000,
      Td2val = struct_val(T_D2, tol_num_pitch)/1000,
      bot=[diameter+fdev, diameter+fdev+Td2val+H/6],
      xdiam = [mindiam+fdev,mindiam+fdev+Tdval],
      pitchdiam = [pdiam + fdev, pdiam+fdev+Td2val]
    )
    [["pitch",P],["d_minor",xdiam], ["d_pitch",pitchdiam], ["d_major",bot],["basic",[mindiam,pdiam,diameter]]]
  :
    let( // Bolt case
      fdev = struct_val(es,tol_letter)/1000,
      Tdval = struct_val(T_d, tol_num_crest)/1000,
      Td2val = struct_val(T_d2, tol_num_pitch)/1000,
      mintrunc = P/8,
      d1 = diameter-5*H/4,
      maxtrunc = H/4 - mintrunc * (1-cos(60-acos(1-Td2val/4/mintrunc)))+Td2val/2,
      bot = [diameter-2*H+2*mintrunc+fdev, diameter-2*H+2*maxtrunc+fdev],
      xdiam = [diameter+fdev,diameter+fdev-Tdval],
      pitchdiam = [pdiam + fdev, pdiam+fdev-Td2val]
    )
    [["pitch",P],["d_major",xdiam], ["d_pitch",pitchdiam], ["d_minor",bot],["basic",[mindiam,pdiam,diameter]]];

function _UTS_thread_tolerance(diam, pitch, internal=false, tolerance=undef) =
  let(
    d = diam/INCH,   // diameter in inches
    P = pitch/INCH,  // pitch in inches
    H = P*sqrt(3)/2,
    tolerance = first_defined([tolerance, internal?"2B":"2A"]),
    tolOK = in_list(tolerance, ["1A","1B","2A","2B","3A","3B"]),
    internal = tolerance[1]=="B"
  )
  assert(tolOK,str("Tolerance was ",tolerance,". Must be one of 1A, 2A, 3A, 1B, 2B, 3B"))
  let(
    LE = 9*P,   // length of engagement.  Is this right?
    pitchtol_2A = 0.0015*pow(d,1/3) + 0.0015*sqrt(LE) + 0.015*pow(P,2/3),
    pitchtol_table = [
                 ["1A", 1.500*pitchtol_2A],
                 ["2A",       pitchtol_2A],
                 ["3A", 0.750*pitchtol_2A],
                 ["1B", 1.950*pitchtol_2A],
                 ["2B", 1.300*pitchtol_2A],
                 ["3B", 0.975*pitchtol_2A]
               ],
     pitchtol = struct_val(pitchtol_table, tolerance),
     allowance = tolerance=="1A" || tolerance=="2A" ? 0.3 * pitchtol_2A : 0,
     majortol = tolerance == "1A" ? 0.090*pow(P,2/3) :
                tolerance == "2A" || tolerance == "3A" ? 0.060*pow(P,2/3) :
                pitchtol+pitch/4/sqrt(3),    // Internal case
     minortol = tolerance=="1B" || tolerance=="2B" ?
                    (
                      d < 0.25 ? constrain(0.05*pow(P,2/3)+0.03*P/d - 0.002, 0.25*P-0.4*P*P, 0.394*P)
                               : (P > 0.25 ? 0.15*P : 0.25*P-0.4*P*P)
                    ) :
                tolerance=="3B" ? constrain(0.05*pow(P,2/3)+0.03*P/d - 0.002, P<1/13 ? 0.12*P : 0.23*P-1.5*P*P, 0.394*P)
                     :0, // not used for external threads
     basic_minordiam = d - 5/4*H,
     basic_pitchdiam = d - 3/4*H,
     majordiam = internal ? [d,d] :          // A little confused here, paragraph 8.3.2
                          [d-allowance-majortol, d-allowance],
     pitchdiam = internal ? [basic_pitchdiam, basic_pitchdiam + pitchtol]
                          : [majordiam[1] - 3/4*H-pitchtol, majordiam[1]-3/4*H],
     minordiam = internal ? [basic_minordiam, basic_minordiam + minortol]
                          : [pitchdiam[0] - 3/4*H, basic_minordiam - allowance - H/8]   // the -H/8 is for the UNR case, 0 for UN case
    )
    [["pitch",P*INCH],["d_major",majordiam*INCH], ["d_pitch", pitchdiam*INCH], ["d_minor",minordiam*INCH],
     ["basic", INCH*[basic_minordiam, basic_pitchdiam, d]]];

function _exact_thread_tolerance(d,P) =
   let(
       H = P*sqrt(3)/2,
       basic_minordiam = d - 5/4*H,
       basic_pitchdiam = d - 3/4*H
      )
    [["pitch", P], ["d_major", [d,d]], ["d_pitch", [basic_pitchdiam,basic_pitchdiam]], ["d_minor", [basic_minordiam,basic_minordiam]],
     ["basic", [basic_minordiam, basic_pitchdiam, d]]];


// Takes a screw name as input and returns a list of the form
// [system, diameter, thread, length]
// where system is either "english" or "metric".  

function _parse_screw_name(name) =
    let( commasplit = str_split(name,","),
         length = parse_num(commasplit[1]),
         xdash = str_split(commasplit[0], "-x"),
         type = xdash[0],
         thread = parse_float(xdash[1])
    )
    assert(len(commasplit)<=2, str("More than one comma found in screw name, \"",name,"\""))
    assert(len(xdash)<=2, str("Screw name has too many '-' or 'x' characters, \"",name,"\""))
    assert(len(commasplit)==1 || is_num(length), str("Invalid length \"", commasplit[1],"\" in screw name, \"",name,"\""))
    assert(len(xdash)==1 || all_nonnegative(thread),str("Thread pitch not a valid number in screw name, \"",name,"\""))
    type[0] == "M" || type[0] == "m" ? 
        let(diam = parse_float(substr(type,1)))
        assert(is_num(diam), str("Screw size must be a number in screw name, \"",name,"\""))
        ["metric", parse_float(substr(type,1)), thread, length] 
    :
    let(
        diam = type[0] == "#" ? type :
               suffix(type,2)=="''" ? parse_float(substr(type,0,len(type)-2)) :
               let(val=parse_num(type))
               assert(all_positive(val), str("Screw size must be a number in screw name, \"",name,"\""))
               val == floor(val) && val>=0 && val<=12 ? str("#",type) : val
    )
    assert(is_str(diam) || is_num(diam), str("Invalid screw diameter in screw name, \"",name,"\""))
    ["english", diam, thread, u_mul(25.4,length)];


// drive can be "hex", "phillips", "slot", "torx", or "none"
// or you can specify "ph0" up to "ph4" for phillips and "t20" for torx 20
function _parse_drive(drive=undef, drive_size=undef) =
    is_undef(drive) ? ["none",undef] 
  : assert(is_string(drive))
    let(drive = downcase(drive))
    in_list(drive,["hex","phillips", "slot", "torx", "phillips", "none"]) ? [drive, drive_size] 
  : drive[0]=="t" ? let(size = parse_int(substr(drive,1))) ["torx",size,torx_depth(size) ] 
  : starts_with(drive,"ph") && search(drive[2], "01234")!=[] ? ["phillips", ord(drive[2])-ord("0")] 
  : assert(false,str("Unknown screw drive type ",drive));


// Module: screw_head()
// Synopsis: Creates a screw head.
// SynTags: Geom
// Topics: Threading, Screws
// See Also: screw(), screw_hole()
// Usage:
//    screw_head(screw_info, [details],[counterbore],[flat_height],[teardrop],[internal])
// Description:
//    Draws the screw head described by the data structure `screw_info`, which
//    should have the fields produced by {{screw_info()}}.  See that function for
//    details on the fields.  Standard orientation is with the head centered at (0,0)
//    and oriented in the +z direction.  Flat heads appear below the xy plane.
//    Other heads appear sitting on the xy plane.  
// Arguments:
//    screw_info = structure produced by {{screw_info()}}
//    ---
//    details = true for more detailed model.  Default: false
//    counterbore = counterbore height.  Default: no counterbore
//    flat_height = height of flat head (required for flat heads)
//    teardrop = if true make flatheads and counterbores teardrop shaped with the flat 5% away from the edge of the screw.  If numeric, specify the fraction of extra to add.  Set to "max" for a pointed teardrop.  Default: false
//    slop = enlarge diameter by this extra amount (beyond that specified in the screw specification).  Default: 0
function screw_head(screw_info,details=false, counterbore=0,flat_height,teardrop=false,slop=0) = no_function("screw_head");
module screw_head(screw_info,details=false, counterbore=0,flat_height,teardrop=false,slop=0) {
   no_children($children);
   head_oversize = struct_val(screw_info, "head_oversize",0) + slop;
   head = struct_val(screw_info, "head");
   head_size = struct_val(screw_info, "head_size",0) + head_oversize;
   head_height = struct_val(screw_info, "head_height");
   dum0=assert(is_def(head_height) || in_list(head,["flat","none"]), "Undefined head height only allowed with flat head or headless screws")
        assert(is_bool(teardrop) || teardrop=="max" || all_nonnegative([teardrop]),"Teardrop parameter invalid");
   teardrop = teardrop==true ? .05 : teardrop;
   heightok = (is_undef(head_height) && in_list(head,["flat","none"])) || all_positive(head_height);
   dum1=assert(heightok, "Head hight must be a postive number");
   dum2=assert(counterbore==0 || counterbore==false || head!="none", "Cannot counterbore a headless screw");
   counterbore_temp = counterbore==false? 0 
                    : head!="flat" && counterbore==true ? head_height 
                    : counterbore;
   dum3=assert(is_finite(counterbore_temp) && counterbore_temp>=0, str(counterbore==true? "Must specify numerical counterbore height with flat head screw"
                                                             : "Counterbore must be a nonnegative number"));

   counterbore = counterbore_temp==0 && head!="flat" ? counterbore_temp : counterbore_temp + 0.01;
   adj_diam = struct_val(screw_info, "diameter") + head_oversize;   // Used for determining chamfers and ribbing
   attachable(){
     union(){
         if (head!="flat" && counterbore>0){
           d = head=="hex"? 2*head_size/sqrt(3) : head_size;
           if (teardrop!=false)
             teardrop(d=d, l=counterbore, cap_h=is_num(teardrop) ? d/2*(1+teardrop):undef, orient=BACK, anchor=BACK);
           else                    
             cyl(d=d, l=counterbore, anchor=BOTTOM);
         }  
         if (head=="flat") {   // For flat head, counterbore is integrated
           dummy = assert(all_positive([flat_height]), "flat_height must be given for flat heads");
           angle = struct_val(screw_info, "head_angle")/2;
           sharpsize = struct_val(screw_info, "head_size_sharp")+head_oversize;
           sidewall_height = (sharpsize - head_size)/2 / tan(angle);
           cylheight = counterbore + sidewall_height;
           slopeheight = flat_height - sidewall_height;
           r1 = head_size/2;
           r2 = r1 - tan(angle)*slopeheight;
           n = segs(r1);
           prof1 = teardrop!=false ? teardrop2d(r=r1,cap_h=is_num(teardrop)?r1*(1+teardrop):undef,$fn=n) : circle(r=r1, $fn=n);
           prof2 = teardrop!=false ? teardrop2d(r=r2,cap_h=is_num(teardrop)?r2*(1+teardrop):undef,$fn=n) : circle(r=r2, $fn=n);
           skin([prof2,prof1,prof1], z=[-flat_height, -flat_height+slopeheight, counterbore],slices=0);
         }
         if (head!="flat" && counterbore==0) {
           if (in_list(head,["round","pan round","button","fillister","cheese"])) {
             base = head=="fillister" ? 0.75*head_height :
                    head=="pan round" ? .6 * head_height :
                    head=="cheese" ? .7 * head_height :
                    0.1 * head_height;   // round and button
             head_size2 = head=="cheese" ?  head_size-2*tan(5)*head_height : head_size; // 5 deg slope on cheese head
             segs = segs(head_size);
             cyl(l=base, d1=head_size, d2=head_size2,anchor=BOTTOM, $fn=segs)
               attach(TOP)
                 zrot(180) // Needed to align facets when $fn is odd
                 rotate_extrude($fn=segs)  // ensure same number of segments for cap as for head body
                   intersection(){
                     arc(points=[[-head_size2/2,0], [0,-base+head_height * (head=="button"?4/3:1)], [head_size2/2,0]]);
                     square([head_size2, head_height-base]);
                   }
           }
           if (head=="pan flat")
             cyl(l=head_height, d=head_size, rounding2=0.2*head_size, anchor=BOTTOM);
           if (head=="socket")
             cyl(l=head_height, d=head_size, anchor=BOTTOM, chamfer2=details? adj_diam/10:undef);
           if (head=="socket ribbed"){
             // These numbers are based on ISO specifications that dictate how much oversizsed a ribbed socket head can be
             // We are making our ribbed heads the same size as unribbed (by cutting the ribbing away), but these numbers are presumably a good guide
             rib_size = [[2, .09],
                         [3, .09],
                         [6, .11],
                         [12, .135],
                         [20, .165]];
             intersection() {
               cyl(h=head_height/4, d=head_size, anchor=BOT)
                  attach(TOP) cyl(l=head_height*3/4, d=head_size, anchor=BOT, texture="trunc_ribs", tex_reps=[31,1],
                                  tex_inset=true, tex_depth=-lookup(adj_diam,rib_size));
               cyl(h=head_height,d=head_size, chamfer2=adj_diam/10, anchor=BOT);
             }
           }
           if (head=="hex")
             up(head_height/2)_nutshape(head_size,head_height,"hex",false,true);
         }
     }    
     union(){};
   }
}


// Section: Nuts and nut traps


// Module: nut()
// Synopsis: Creates a standard nut.
// SynTags: Geom
// Topics: Threading, Screws
// See Also: screw(), screw_hole()
// Usage:
//   nut([spec], [shape], [thickness], [nutwidth], [thread=], [tolerance=], [hole_oversize=], [bevel=], [$slop=], [anchor=], [spin=], [orient=]) [ATTACHMENTS];
// Description:
//   Generates a hexagonal or square nut.  See [screw and nut parameters](#section-screw-and-nut-parameters) for details on the parameters that define a nut.
//   As with screws, you can give the specification in `spec` and then omit the name.  The diameter is the flat-to-flat
//   size of the nut produced.  The thickness can be "thin", "normal" or "thick" to choose standard nut dimensions.  For metric
//   nuts you can also use thickness values of "DIN" or "undersized".  The nut's shape is hexagonal by default; set shape to "square" for
//   a square nut.
//   .
//   By default all nuts have the internal holes beveled and hex nuts have their corners beveled.  Square nuts get no outside bevel by default.
//   ASME specifies that small square nuts should not be beveled, and many square nuts are beveled only on one side.   The bevel angle, specified with bevang,
//   gives the angle for the bevel.  The default of 15 is shallow and may not be printable.  Internal hole are beveled at 45 deg by the depth of one thread.  
//   .
//   The tolerance determines the actual thread sizing based on the nominal size in accordance with standards.  
//   The $slop parameter determines extra gaps left to account for printing overextrusion.  It defaults to 0.
// Arguments:
//   spec = nut specification, e.g. "M5x1" or "#8-32".  See [screw naming](#subsection-screw-naming).  This can also be a nut or screw specification structure of the form produced by {{nut_info()}} or {{screw_info()}}.  
//   shape = "hex" or "square" to specify nut shape.  Default: "hex"
//   thickness = "thin", "normal", "thick", or a thickness in mm.  See [nuts](#subsection-nuts).  Default: "normal"
//   ---
//   nutwidth = width of nut (overrides table values)
//   thread = thread type or specification. See [screw pitch](#subsection-standard-screw-pitch). Default: "coarse"
//   hole_oversize = amount to increase hole diameter.  Default: 0
//   bevel = if true, bevel the outside of the nut.  Default: true for hex nuts, false for square nuts
//   bevel1 = if true, bevel the outside of the nut bottom.
//   bevel2 = if true, bevel the outside of the nut top. 
//   bevang = set the angle for the outside nut bevel.  Default: 15
//   ibevel = if true, bevel the inside (the hole).   Default: true
//   ibevel1 = if true bevel the inside, bottom end.
//   ibevel2 = if true bevel the inside, top end.
//   blunt_start = If true apply truncated blunt start threads at both ends.  Default: true
//   blunt_start1 = If true apply truncated blunt start threads bottom end.
//   blunt_start2 = If true apply truncated blunt start threads top end.
//   tolerance = nut tolerance.  Determines actual nut thread geometry based on nominal sizing.  See [tolerance](#subsection-tolerance). Default is "2B" for UTS and "6H" for ISO.
//   $slop = extra space left to account for printing over-extrusion.  Default: 0
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Side Effects:
//   `$screw_spec` is set to the spec specification structure. 
// Example: All the UTS nuts at one size.  Note that square nuts come in only one thickness.  
//   xdistribute(spacing=0.75*INCH){
//       nut("3/8",thickness="thin");
//       nut("3/8",thickness="normal");
//       nut("3/8",thickness="thick");
//       nut("3/8",shape="square");
//   }
// Example: All the ISO (and DIN) nuts at one size.  Note that M10 is one of the four cases where the DIN nut width is larger.  
//   ydistribute(spacing=30){
//      xdistribute(spacing=22){
//         nut("M10", thickness="thin");
//         nut("M10",thickness="undersized");
//         nut("M10",thickness="normal");
//         nut("M10",thickness="thick");
//      }
//      xdistribute(spacing=25){
//         nut("M10", shape="square", thickness="thin");
//         nut("M10", shape="square", thickness="normal");      
//      }
//   }
// Example: The three different UTS nut tolerances (thickner than normal nuts)
//   module mark(number)
//   {
//     difference(){
//        children();
//        ycopies(n=number, spacing=1.5)right(.25*INCH-2)up(8-.35)cyl(d=1, h=1);
//     }
//   }
//   $fn=64;
//   xdistribute(spacing=17){
//     mark(1) nut("1/4-20", thickness=8, nutwidth=0.5*INCH,tolerance="1B");
//     mark(2) nut("1/4-20", thickness=8, nutwidth=0.5*INCH,tolerance="2B");
//     mark(3) nut("1/4-20", thickness=8, nutwidth=0.5*INCH,tolerance="3B");
//   }
// Example: Threadless nut
//   nut("#8", thread="none");

function nut(spec, shape, thickness, nutwidth, thread, tolerance, hole_oversize, 
           bevel,bevel1,bevel2,bevang=15,ibevel,ibevel1,ibevel2,blunt_start, blunt_start1, blunt_start2, anchor=BOTTOM, spin=0, orient=UP, oversize=0)
           = no_function("nut");
module nut(spec, shape, thickness, nutwidth, thread, tolerance, hole_oversize, 
           bevel,bevel1,bevel2,bevang=15,ibevel,ibevel1,ibevel2,blunt_start, blunt_start1, blunt_start2, anchor=BOTTOM, spin=0, orient=UP, oversize=0)
{
   dummyA = assert(is_undef(nutwidth) || (is_num(nutwidth) && nutwidth>0));
   
   tempspec = _get_spec(spec, "nut_info", "nut", 
                        thread=thread, shape=shape, thickness=thickness);
   spec=_struct_reset(tempspec,[
                                ["width", nutwidth],
                                ["shaft_oversize", hole_oversize],
                               ]);
   dummy=_validate_nut_spec(spec);
   $screw_spec = spec;
   shape = struct_val(spec, "shape");
   pitch =  struct_val(spec, "pitch") ;
   threadspec = pitch==0 ? undef : thread_specification(spec, internal=true, tolerance=tolerance);
   nutwidth = struct_val(spec, "width");
   thickness = struct_val(spec, "thickness");
   threaded_nut(
        nutwidth=nutwidth,
        id=pitch==0 ? _nominal_diam(spec)
          : [mean(struct_val(threadspec, "d_minor")),
             mean(struct_val(threadspec, "d_pitch")),
             mean(struct_val(threadspec, "d_major"))],
        pitch = pitch, 
        h=thickness,
        shape=shape, 
        bevel=bevel,bevel1=bevel1,bevel2=bevel2,bevang=bevang,
        ibevel=ibevel,ibevel1=ibevel1,ibevel2=ibevel2,
        blunt_start=blunt_start, blunt_start1=blunt_start1, blunt_start2=blunt_start2,         
        anchor=anchor,spin=spin,orient=orient) children();
}






// Module: nut_trap_side()
// Synopsis: Creates a side nut trap mask.
// SynTags: Geom
// Topics: Threading, Screws
// See Also: screw(), screw_hole()
// Usage:
//   nut_trap_side(trap_width, [spec], [shape], [thickness], [nutwidth=], [poke_len=], [poke_diam=], [$slop=], [anchor=], [orient=], [spin=]) [ATTACHMENTS];
// Description:
//   Create a nut trap that extends sideways, so the nut slides in perpendicular to the screw axis.
//   The CENTER anchor is the center of the screw hole location in the trap.  The trap width is
//   measured from the screw hole center point.  You can optionally create a poke hole to use for
//   removing the nut by specifying a poke_len value that determines the length of the poke hole, measured
//   from the screw center.  The diameter of the poke hole defaults to the thickness of the nut.  The nut dimensions
//   will be increased by `2*$slop` to allow adjusting the fit of the trap for your printer.  
//   The trap will have a default tag of "remove" if no other tag is in force.  
// Arguments:
//   trap_width = width of nut trap, measured from screw center, must be larger than half the nut width  (If spec is omitted this argument must be given by name.)
//   spec = nut specification, e.g. "M5" or "#8".  See [screw naming](#subsection-screw-naming).  This can also be a screw or nut specification structure of the form produced by {{nut_info()}} or {{screw_info()}}.  
//   shape = "hex" or "square" to specify the shape of the nut.   Default: "hex"
//   thickness = "thin", "normal", or "thick".  "DIN" or "undersized" for metric nuts.  See [nuts](#subsection-nuts). Default: "normal"
//   ---
//   nutwidth = width of the nut.  Default: determined from tables
//   poke_len = length of poke hole.  Default: no poke hole
//   poke_diam = diameter of poke hole.  Default: nut thickness
//   $slop = extra space left to account for printing over-extrusion.  Default: 0
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `BOTTOM`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Side Effects:
//   `$screw_spec` is set to the spec specification structure. 
// Example: Basic trap.  Note that screw center is at the origin and the width is measured from the origin.  
//   nut_trap_side(10, "#8");
// Example: Trap with poke hole for removing nut.  The poke hole length is also measured from the screw center at the origin
//   $fn=16;
//   nut_trap_side(10, "#8", poke_len=10);
// Example: Trap for square nut
//   $fn=16;
//   nut_trap_side(10, "#8", shape="square", poke_len=10);
// Example: Trap with looser fit
//   nut_trap_side(10, "#8", $slop=0.1);
// Example: Trap placed at the bottom of a screw hole
//   $fn=24;
//   screw_hole("#8,1") 
//     position(BOT) nut_trap_side(10,poke_len=8);
// Example: Trap placed at the bottom of a screw hole 2mm extra screw hole below the trap
//   $fn=24;
//   screw_hole("#8,1") 
//     up(2) position(BOT) nut_trap_side(trap_width=10,poke_len=8);
// Example: Hole-trap assembly removed from an object
//   $fn=24;
//   back_half()
//   diff()
//   cuboid(30)
//      position(TOP)screw_hole("#8,1",anchor=TOP) 
//        position(BOT) nut_trap_side(trap_width=16);
// Example: Hole-trap assembly where we position the trap relative to a feature on the model and then position the screw hole through the trap as a child to the trap.  
//  diff()
//   cuboid([30,30,20])
//     position(RIGHT)cuboid([4,20,3],anchor=LEFT)
//       right(1)position(TOP+LEFT)nut_trap_side(15, "#8",anchor=BOT+RIGHT)
//         screw_hole(length=20,anchor=BOT);
module nut_trap_side(trap_width, spec, shape, thickness, nutwidth, anchor=BOT, orient, spin, poke_len=0, poke_diam) {
  dummy9=assert(is_num(trap_width), "trap_width is missing or the wrong type");
  tempspec = _get_spec(spec, "nut_info", "nut_trap", shape=shape, thickness=thickness);
  nutdata = _struct_reset(tempspec, [["width", nutwidth]]);
  $screw_spec = is_def(spec) ? nutdata : $screw_spec;
  dummy8 = _validate_nut_spec(nutdata);
  nutwidth = struct_val(nutdata,"width")+2*get_slop();
  dummy = assert(is_num(poke_len) && poke_len>=0, "poke_len must be a nonnegative number")
          assert(is_undef(poke_diam) || (is_num(poke_diam) && poke_diam>0), "poke_diam must be a positive number")
          assert(is_num(trap_width) && trap_width>=nutwidth/2, str("trap_width is smaller than nut width: ",nutwidth));
  nutthickness = struct_val(nutdata, "thickness")+2*get_slop();
  cubesize = [trap_width, nutwidth,nutthickness];
  halfwidth = shape=="square" ? nutwidth/2 : nutwidth/sqrt(3);
  shift = cubesize[0]/2 - halfwidth/2;
  default_tag("remove")
    attachable(size=cubesize+[halfwidth,0,0], offset=[shift,0,0],anchor=anchor,orient=orient,spin=spin)
    {
       union(){
         if (shape=="square") left(nutwidth/2) cuboid(cubesize+[halfwidth,0,0],anchor=LEFT);
         else {
            cuboid(cubesize,anchor=LEFT);
            linear_extrude(height=nutthickness,center=true)hexagon(id=nutwidth);
         }
         if (poke_len>0)
           xcyl(l=poke_len, d=default(poke_diam, nutthickness), anchor=RIGHT);
       }
       children();
    }     
}

// Module: nut_trap_inline()
// Synopsis: Creates an inline nut trap mask.
// SynTags: Geom
// Topics: Threading, Screws
// See Also: screw(), screw_hole()
// Usage:
//   nut_trap_inline(length|l|heigth|h, [spec], [shape], [$slop=], [anchor=], [orient=], [spin=]) [ATTACHMENTS];
// Description:
//   Create a nut trap that extends along the axis of the screw.  The nut width
//   will be increased by `2*$slop` to allow adjusting the fit of the trap for your printer.
//   If no tag is present the trap will be tagged with "remove".  Note that you can omit the specification
//   and it will be inherited from a parent screw_hole to provide the screw size.  It's also possible to 
//   do this backwards, to declare a trap at a screw size and make a child screw hole, which will inherit
//   the screw dimensions.  
// Arguments:
//   length/l/height/h = length/height of nut trap
//   spec = nut specification, e.g. "M5" or "#8".  See [screw naming](#subsection-screw-naming).  This can also be a screw or nut specification structure of the form produced by {{nut_info()}} or {{screw_info()}}.  
//   shape = "hex" or "square to determine type of nut.  Default: "hex"
//   ---
//   $slop = extra space left to account for printing over-extrusion.  Default: 0
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `TOP`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Side Effects:
//   `$screw_spec` is set to the spec specification structure. 
// Example: Basic trap
//   nut_trap_inline(10, "#8");
// Example: Basic trap with allowance for a looser fit
//   nut_trap_inline(10, "#8", $slop=.1);
// Example: Square trap (just a cube, but hopefully just the right size)
//   nut_trap_inline(10, "#8", shape="square");
// Example: Attached to a screw hole
//   screw_hole("#8,1",head="socket",counterbore=true, $fn=32) 
//     position(BOT) nut_trap_inline(10);
// Example: Nut trap with child screw hole
//   nut_trap_inline(10, "#8")
//     position(TOP)screw_hole(length=10,anchor=BOT,head="flat",$fn=32);
// Example(Med,NoAxes): a pipe clamp
//   $fa=5;$fs=0.5;
//   bardiam = 32;
//   bandwidth = 10;
//   thickness = 3;
//   back_half()
//   diff()
//     tube(id=bardiam, wall = thickness, h=bandwidth, orient=BACK)
//       left(thickness/2) position(RIGHT) cube([bandwidth, bandwidth, 14], anchor = LEFT, orient=FWD)
//       {
//          screw_hole("#4",length=12, head="socket",counterbore=6,anchor=CENTER)
//             position(BOT) nut_trap_inline(l=6,anchor=BOT);
//          tag("remove")right(1)position(RIGHT)cube([11+thickness, 11, 2], anchor = RIGHT);
//       }
module nut_trap_inline(length, spec, shape, l, height, h, nutwidth, anchor, orient, spin) {
  tempspec = _get_spec(spec, "nut_info", "nut_trap", shape=shape, thickness=undef);
  nutdata = _struct_reset(tempspec, [["width", nutwidth]]);
  $screw_spec = is_def(spec) ? nutdata : $screw_spec;
  dummy = _validate_nut_spec(nutdata);
  length = one_defined([l,length,h,height],"l,length,h,height");
  assert(is_num(length) && length>0, "length must be a positive number");
  nutwidth = struct_val(nutdata,"width")+2*get_slop();
  default_tag("remove"){
    if (shape=="square")
      cuboid([nutwidth,nutwidth,length], anchor=anchor, orient=orient, spin=spin) children();
    else
      linear_sweep(hexagon(id=nutwidth),height=length, anchor=anchor,orient=orient, spin=spin) children();
  }
}



// Section: Screw and Nut Information


// Function: screw_info()
// Synopsis: Returns the dimensions and other info for the given screw.
// Topics: Threading, Screws
// See Also: screw(), screw_hole()
// Usage:
//   info = screw_info(name, [head], [drive], [thread=], [drive_size=], [oversize=], [head_oversize=])
// Description:
//   Look up screw characteristics for the specified screw type.
//   See [screw and nut parameters](#section-screw-and-nut-parameters) for details on the parameters that define a screw.
//   .
//   The `oversize=` parameter adds the specified amount to the screw and head diameter to make an
//   oversized screw.  Does not affect length, thread pitch or head height.
//   .
//   Note that flat head screws are defined by two different diameters, the theoretical maximum diameter, "head_size_sharp"
//   and the actual diameter, "head_size".  The screw form is defined using the theoretical maximum, which gives
//   sharp circular edge at the top of the screw.  Real screws have a flat chamfer around the edge.  
// Figure(2D,Med,NoAxes,VPD=39,VPT=[0,-4,0],VPR=[0,0,0]):  Flat head screw geometry
//   polysharp = [[0, -5.07407], [4.92593, -5.07407], [10, 0], [10, 0.01], [0, 0.01]];
//   color("blue"){
//       xflip_copy()polygon(polysharp);
//       back(1/2)stroke([[-10,0],[10,0]],endcaps="arrow2",width=.15);    
//       back(1.7)text("\"head_size_sharp\"", size=.75,anchor=BACK);
//   }
//   poly= [[0, -5.07407], [4.92593, -5.07407], [9.02, -0.98], [9.02, 0.01], [0, 0.01]];
//   xflip_copy()polygon(poly);
//   rect([10,10],anchor=TOP);
//   color("black"){
//     fwd(1/2)stroke([[-9.02,0],[9.02,0]],endcaps="arrow2",width=.15);
//     fwd(1)text("\"head_size\"", size=.75,anchor=BACK);
//   }  
// Continues:
//   The output is a [struct](structs.scad) with the following fields:
//   . 
//   Field              | What it is
//   ------------------ | ---------------
//   "type"           | Always set to "screw_info"
//   "system"         | Either `"UTS"` or `"ISO"` (used for correct tolerance computation).
//   "origin"         | Module that generated the structure
//   "name"           | Screw name used to make the structure
//   "diameter"       | The nominal diameter of the screw shaft in mm.
//   "pitch"          | The thread pitch in mm.  (0 for no threads)
//   "head"           | The type of head (a string)
//   "head_size"      | Size of the head (usually diameter) in mm.
//   "head_size_sharp"| Theoretical head diameter for a flat head screw if it is made with sharp edges (or for countersinks)
//   "head_angle"     | Countersink angle for flat heads.
//   "head_height"    | Height of the head beyond the screw's nominal length.  The screw's total length is "length" + "head_height".  For flat heads "head_height" is zero, because they do not extend the screw.  
//   "drive"          | The drive type (`"phillips"`, `"torx"`, `"slot"`, `"hex"`, `"none"`)
//   "drive_size"     | The drive size, either a drive number (phillips, torx) or a dimension in mm (hex, slot).
//   "drive_depth"    | Depth of the drive recess.
//   "length"         | Length of the screw in mm measured in the customary fashion.  For flat head screws the total length and for other screws, the length from the bottom of the head to the screw tip.
//   "thread_len"     | Length of threaded portion of screw in mm
//   "shaft_oversize"| Amount to oversize the threads
//   "head_oversize"   | Amount to oversize the head
//   .
//   If you want to define a custom drive for a screw you will need to provide the drive size and drive depth.  
//
// Arguments:
//   name = screw specification, e.g. "M5x1" or "#8-32".  See [screw naming](#subsection-screw-naming).
//   head = head type.  See [screw heads](#subsection-screw-heads)  Default: none
//   drive = drive type.  See [screw heads](#subsection-screw-heads) Default: none
//   ---
//   thread = thread type or specification. See [screw pitch](#subsection-standard-screw-pitch). Default: "coarse"
//   drive_size = size of drive recess to override computed value
//   shaft_oversize = amount to increase screw diameter for clearance holes.  Default: 0
//   head_oversize = amount to increase head diameter for countersink holes.  Default: 0 

function screw_info(name, head, drive, thread, drive_size, shaft_oversize, head_oversize, _origin) =
  assert(is_string(name), "Screw specification must be a string")
  let(
      thread = is_undef(thread) || thread==true ? "coarse"
             : thread==false || thread=="none" ? 0
             : thread,
      head = default(head,"none"),
      type=_parse_screw_name(name),
      drive_info = _parse_drive(drive, drive_size),
      drive=drive_info[0],
      screwdata =   type[0] == "english" ? _screw_info_english(type[1],type[2], head, thread, drive) 
                  : type[0] == "metric" ? _screw_info_metric(type[1], type[2], head, thread, drive) 
                  : []
    )
    assert(is_def(struct_val(screwdata,"head")),str("Screw head \"",head,"\" unknown or unsupported for specified screw"))
    _struct_reset(screwdata,
         [
          ["drive_depth", drive_info[2]],
          ["length", type[3]],
          ["drive_size", drive_info[1]],
          ["name", name],
          ["shaft_oversize", shaft_oversize],
          ["head_oversize", head_oversize],
          ["origin",_origin]
         ]);
      

// Function: nut_info()
// Synopsis: Returns the dimensions and other info for the given nut.
// Topics: Threading, Screws
// See Also: screw(), screw_hole()
// Usage:
//   nut_spec = nut_info(name, [shape], [thickness=], [thread=], [width=], [hole_oversize=]);
// Description:
//   Produces a nut specification structure that describes a nut.  You can specify the width
//   and thickness numerically, or you can let the width be calculated automatically from
//   the thread specification.  The thickness can be "normal" (the default) or "thin" or "thick".
//   Note that square nuts are only available in "normal" thickness, and "thin" and "thick" nuts
//   are only available for 1/4 inch and above.  
//   .
//   The output is a [struct](structs.scad) with the following fields:
//   . 
//   Field              | What it is
//   ------------------ | ---------------
//   "type"           | Always set to "nut_info"
//   "system"         | Either `"UTS"` or `"ISO"` (used for correct tolerance computation).
//   "origin"         | Module that created the structure
//   "name"           | Name used to specify threading, such as "M6" or "#8"
//   "diameter"       | The nominal diameter of the screw hole in mm.
//   "pitch"          | The thread pitch in mm.  (0 for no threads)
//   "shape"          | Shape of the nut, either "hex" or "square"
//   "width"          | Flat to flat width of the nut
//   "thickness"      | Thickness of the nut
//   "shaft_oversize" | amount to oversize the threads (not including $slop)
// Arguments:
//   name = screw name, e.g. "M5x1" or "#8-32".  See [screw naming](#subsection-screw-naming).
//   shape = shape of the nut, either "hex" or "square".  Default: "hex"
//   ---
//   thread = thread type or specification. See [screw pitch](#subsection-standard-screw-pitch). Default: "coarse"
//   thickness = thickness of the nut (in mm) or one of "thin", "normal", or "thick".  Default: "normal"
//   width = width of nut in mm.  Default: computed from thread specification
//   hole_oversize = amount ot increase diameter of hole in nut.  Default: 0

function nut_info(name, shape, thickness, thread, hole_oversize=0, width, _origin) =
  assert(is_undef(thickness) || (is_num(thickness) && thickness>0) ||
           in_list(_downcase_if_str(thickness),["thin","normal","thick","undersized","din"]),
          "thickness must be a positive number of one of \"thin\", \"thick\", \"normal\", \"undersized\", or \"DIN\"")
  let(
      shape = _downcase_if_str(default(shape,"hex")),
      thickness = _downcase_if_str(default(thickness, "normal"))
  )
  assert(is_string(name), str("Nut nameification must be a string ",name))
  assert(in_list(shape, ["hex","square"]), "Nut shape must be \"hex\" or \"square\"")
  assert(is_undef(width) || (is_num(width) && width>0), "Specified width must be a positive number")
  let(
      type = _parse_screw_name(name),
      thread = is_undef(thread) || thread==true ? "coarse"
             : thread==false || thread=="none" ? 0
             : thread,
      nutdata = type[0]=="english" ? _nut_info_english(type[1],type[2], thread, shape, thickness, width)
              : type[0]=="metric" ?  _nut_info_metric(type[1],type[2], thread, shape, thickness, width)
              : []
  )
  _struct_reset(nutdata, [["name", name],
                          ["shaft_oversize",hole_oversize],
                          ["width", width],
                          ["origin",_origin]
                         ]);


// Nut data is from ASME B18.2.2, mostly Table A-1
function _nut_info_english(diam, threadcount, thread, shape, thickness, width) =
  assert(!is_string(thickness) || in_list(thickness,["normal","thin","thick"]),
         "You cannot use thickness \"DIN\" or \"undersized\" with English nuts")
  let(
       screwspec=_screw_info_english(diam, threadcount, head="none", thread=thread),
       diameter = struct_val(screwspec,"diameter")/INCH,
       //         thickness  width
       normal = [
            ["#0", [ 3/64 , 5/32  ]],
            ["#1", [ 3/64 , 5/32  ]],
            ["#2", [ 1/16 , 3/16  ]],
            ["#3", [ 1/16 , 3/16  ]],
            ["#4", [ 3/32 ,  1/4  ]],
            ["#5", [ 7/64 , 5/16  ]],
            ["#6", [ 7/64 , 5/16  ]],
            ["#8", [  1/8 ,11/32  ]],
            ["#10",[  1/8 ,  3/8  ]],
            ["#12",[ 5/32 , 7/16  ]],
            [1/4,  [ 7/32 , 7/16  ]],
       ],
       thin = [  // thickness
            [1/4,  [ 5/32]],
            [5/16, [ 3/16]],
            [3/8,  [ 7/32]],
            [7/16, [  1/4]],
            [1/2,  [ 5/16]],
            [9/16, [ 5/16]],
            [5/8,  [  3/8]]
       ],
       thick = [
            [1/4,  [9/32 ]],
            [5/16, [21/64]],
            [3/8,  [13/32]],
            [7/16, [29/64]],
            [1/2,  [9/16]],
            [9/16, [39/64]],
            [5/8,  [23/32]],
            [3/4,  [13/16]],
            [7/8,  [29/32]],
            [1,    [1]],
            [1+1/8,[1+5/32]],
            [1+1/4,[1+1/4]],
            [1+3/8,[1+3/8]],
            [1+1/2,[1+1/2]]
       ]
  )
  assert(is_num(thickness) || thickness=="normal" || diameter >=1/4,
         str("No ", thickness, " nut available at requested thread size"))
  assert(diameter <= 1.5, "No thickness available for nut diameter over 1.5 inches")
  assert(shape=="hex" || thickness=="normal" || is_num(thickness),"Square nuts only come in normal thickness")
  let(
      table = thickness=="normal" ? normal
            : thickness=="thick" ? thick
            : thickness=="thin"  ? thin
            : [],
      entry = struct_val(table, diam),
      thickness = is_num(thickness) ? thickness/INCH
                : is_def(entry) ? entry[0]
                : shape=="square" ? ( approx(diameter,1.125) ? 1
                                                             : quantdn(7/8 * diameter,1/64))
                : thickness=="thin" ? (diameter < 1+3/16 ? quantdn(0.5*diameter + 3/64,1/64)
                                                         : 0.5*diameter + 3/32)
                  // remaining case is "normal" thickness
                : diameter < 11/16 ? quantdn(7/8*diameter,1/64)
                : diameter < 1+3/16 ? 7/8*diameter - 1/64
                : 7/8 * diameter - 1/32, 
      width = is_num(width) ? width/INCH
            : is_def(entry[1]) ? entry[1]
            : shape=="square" ? (diameter<5/8 ? quantup(1.5*diameter,1/16)+1/16 : 1.5*diameter)
            : quantup(1.5*diameter,1/16)
  )
  [["type","nut_info"],
   ["system", "UTS"],
   ["diameter", struct_val(screwspec, "diameter")],
   ["pitch", struct_val(screwspec,"pitch")],
   ["width", width*INCH],
   ["thickness", thickness*INCH],
   ["shape", shape]];


function _downcase_if_str(s) = is_string(s) ? downcase(s) : s;

function _nut_info_metric(diam, pitch, thread, shape, thickness, width) =
  let(
       screwspec=_screw_info_metric(diam, pitch, head="none", thread=thread),
       diameter = struct_val(screwspec,"diameter"),

       ISO_table =      //     - ASME B18.4.1M -    DIN 439
          //                   --- ISO 4032 ----   ISO 4035   ISO 4033 
          //                   normal     normal     thin       thick
          // diam    width     midpt      max        (max)      (max)
          // Preferred threads
          [
             [1.6,   [3.2 ,     1.2,       1.3,       1.0   ]],
             [2,     [4   ,     1.5,       1.6,       1.2   ]],
             [2.5,   [5   ,     1.875,     2,         1.6   ]],
             [3,     [5.5 ,     2.25,      2.4,       1.8   ]],
             [4,     [7   ,     3,         3.2,       2.2   ]],
             [5,     [8   ,     4.5 ,      4.7,       2.7,      5.1]],
             [6,     [10  ,     5,         5.2,       3.2,      5.7]],
             [8,     [13  ,     6.675,     6.8,      undef,      7.5]],
             [10,    [16  ,     8.25,      8.4,      undef,      9.3]],
             [12,    [18  ,     10.5,     10.8,      undef,     12  ]],
             [16,    [24  ,     14.5,     14.8,      undef,     16.4]],
             [20,    [30  ,     17.5,     18,        undef,     20.3]],
             [24,    [36  ,     21,       21.5,      undef,     23.9]],
             [30,    [46  ,     25,       25.6,      undef,     28.6]],
             [36,    [55  ,     30,       31,        undef,     34.7]],
             [42,    [65  ,     33,       34,        undef      ]],
             [48,    [75  ,     37,       38,        undef      ]],
             [56,    [85  ,     44,       45,        undef      ]],
             [64,    [95  ,     50,       51,        undef      ]],
          // Non-preferred threads
             [3.5,   [ 6,       2.675,     2.8,      2          ]],
             [14,    [21,      12.5,      12.8,      undef,     14.1]],
             [18,    [27,      15.5,      15.8,      undef,     17.6]],
             [22,    [34,      19,        19.4,      undef,     21.8]],
             [27,    [41,      23,        23.8,      undef,     26.7]],
             [33,    [50,      28,        28.7,      undef,     32.5]],
             [39,    [60,      33,        33.4,      undef      ]],
             [45,    [70,      35,        36,        undef      ]],
             [52,    [80,      41,        42,        undef      ]],
             [60,    [90,      47,        48,        undef      ]]
          ],
       DIN_table =
          [
             //                  DIN 934   DIN 936  DIN 562     DIN 557
             //diam      width   normal    thin    thin square   square
             [   1,    [   2.5,    0.8,   undef]],
             [   1.2,  [   3,      1  ,   undef]],
             [   1.4,  [   3,      1.2,   undef]],
             [   1.6,  [   3.2,    1.3,   undef,      1.0]],
             [   2,    [   4,      1.6,   undef,      1.2]],
             [   2.5,  [   5,      2  ,   undef,      1.6]],
             [   3,    [   5.5,    2.4,   undef,      1.8]],
             [   3.5,  [   6,      2.8,   undef,      2.0]],
             [   4,    [   7,      3.2,     2.8,      2.2]],
             [   5,    [   8,      4,       3.5,      2.7]],
             [   6,    [  10,      5,       4  ,      3.2]],
             [   7,    [  11,      5.5,     4  ]],
             [   8,    [  13,      6.5,     5        ]],
             [  10,    [  17,      8,       6        ]],     //
             [  12,    [  19,     10,       7  ]],  //
             [  14,    [  22,     11,       8  ]],  //
             [  16,    [  24,     13,       8  ]],
             [  18,    [  27,     15,       9  ]],
             [  20,    [  30,     16,       9  ]],
             [  22,    [  32,     18,      10  ]],  //
             [  24,    [  36,     19,      10  ]],
             [  27,    [  41,     22,      12  ]],
             [  30,    [  46,     24,      12  ]],
             [  33,    [  50,     26,      14  ]],
             [  36,    [  55,     29,      14  ]],
             [  39,    [  60,     31,      16  ]],
             [  42,    [  65,     34,      16  ]],
             [  45,    [  70,     36,      18  ]],
             [  48,    [  75,     38,      18  ]],
             [  52,    [  80,     42,      20  ]],
             [  56,    [  85,     45]],
             [  60,    [  90,     48]],
             [  64,    [  95,     51]],
             [  68,    [ 100,     54]],
             [  72,    [ 105,     58]],
             [  76,    [ 110,     61]],
             [  80,    [ 115,     64]],
             [  85,    [ 120,     68]],
             [  90,    [ 130,     72]],
             [ 100,    [ 145,     80]],
             [ 110,    [ 155,     88]],
             [ 125,    [ 180,    100]],
             [ 140,    [ 200,    112]],
             [ 160,    [ 230,    128]]
          ],
          useDIN = thickness=="din" || thickness=="undersized" || shape=="square", 
          entry = struct_val(useDIN ? DIN_table : ISO_table, diameter),
          width = is_def(width) ? width
                : entry[0],
          thickind = useDIN && thickness=="thin" ? 3
                   : useDIN ? 1 
                   : thickness=="normal" ? 2
                   : thickness=="thin" ? 3
                   : thickness=="thick" ? 4
                   : undef,
          thickness = is_num(thickness) ? thickness
                    : is_def(entry[thickind]) ? entry[thickind]
                    : thickness=="thin" && diameter > 8 ? diam/2
                    : undef
  )
  assert(is_def(thickness) && is_def(width), "Unknown thickness, size and shape combination for nut")
  [["type","nut_info"],
   ["system", "ISO"],
   ["diameter", struct_val(screwspec, "diameter")],
   ["pitch", struct_val(screwspec,"pitch")],
   ["width", width],
   ["thickness", thickness],
   ["shape", shape]];
          

function _screw_info_english(diam, threadcount, head, thread, drive) =
 let(
   diameter = is_string(diam) ? parse_int(substr(diam,1))*0.013 +0.06 
                              : diam,
   diamgroup = diameter<7/16 ? 0
             : diameter==7/16 ? 1
             : 2,
   pitch =
     is_num(thread) ? thread :
     is_def(threadcount) ? INCH/threadcount :
     let(
        tind=struct_val([["coarse",0],["unc",0],
                         ["fine",1],["unf",1],
                         ["extra fine",2],["extrafine",2],["unef",2]],
                         downcase(thread)),
        dummy = assert(is_def(tind), str("Unknown thread type, \"",thread,"\"")),
                 // coarse  fine  xfine
                 // UNC     UNF   UNEF
        UTS_thread = [
            ["#0", [undef,    80, undef]],
            ["#1", [   64,    72, undef]],
            ["#2", [   56,    64, undef]],
            ["#3", [   48,    56, undef]],
            ["#4", [   40,    48, undef]],
            ["#5", [   40,    44, undef]],
            ["#6", [   32,    40, undef]],
            ["#8", [   32,    36, undef]],
            ["#10",[   24,    32, undef]],
            ["#12",[   24,    28,    32]],
            [1/4,  [   20,    28,    32]],
            [5/16, [   18,    24,    32]],
            [3/8,  [   16,    24,    32]],
            [7/16, [   14,    20,    28]],
            [1/2,  [   13,    20,    28]],
            [9/16, [   12,    18,    24]],
            [5/8,  [   11,    18,    24]],
            [3/4,  [   10,    16,    20]],
            [7/8,  [    9,    14,    20]],
            [1,    [    8,    12,    20]],
            [1.125,[    7,    12,    18]],
            [1.25, [    7,    12,    18]],
            [1.375,[    6,    12,    18]],
            [1.5,  [    6,    12,    18]],
            [1.75, [    5, undef, undef]],
            [2,    [  4.5, undef, undef]],
         ],
       tentry = struct_val(UTS_thread, diam)
     )
     assert(is_def(tentry), str("Unknown screw size, \"",diam,"\""))
     assert(is_def(tentry[tind]), str("No ",thread," pitch known for screw size, \"",diam,"\""))
     INCH / tentry[tind],
   head_data =
       head=="none" ? let (
          UTS_setscrew = [
               // hex width, hex depth torx,  torx depth    slot width   slot depth 
            ["#0", [0.028,   0.050,   undef,     undef,       0.012,       0.018]],
            ["#1", [0.035,   0.060,   undef,     undef,       0.014,       0.018]],
            ["#2", [0.035,   0.060,   undef,     undef,       0.016,       0.022]],
            ["#3", [0.05 ,   0.070,   undef,     undef,       0.018,       0.025]],
            ["#4", [0.05 ,   0.045,      6,      0.027,       0.021,       0.028]],
            ["#5", [1/16 ,   0.080,      7,      0.036,       0.023,       0.031]],
            ["#6", [1/16 ,   0.080,      7,      0.036,       0.025,       0.035]],
            ["#8", [5/64 ,   0.090,      8,      0.041,       0.029,       0.041]],
            ["#10",[3/32 ,   0.100,      10,     0.049,       0.032,       0.048]],
            ["#12",[undef,   undef,   undef,    undef,        0.038,       0.056]],
            [1/4,  [1/8  ,   0.125,      15,     0.068,       0.045,       0.063]],
            [5/16, [5/32 ,   0.156,      25,     0.088,       0.051,       0.078]],
            [3/8,  [3/16 ,   0.188,      30,     0.097,       0.064,       0.094]],
            [7/16, [7/32 ,   0.219,      40,     0.117,       0.072,       0.109]],
            [1/2,  [1/4  ,   0.250,      45,     0.137,       0.081,       0.125]],
            [9/16, [undef,   undef,   undef,    undef,        0.091,       0.141]],
            [5/8,  [5/16 ,   0.312,      55,     0.202,       0.102,       0.156]],
            [3/4,  [3/8  ,   0.375,      60,     0.202,       0.129,       0.188]],
            [7/8,  [1/2  ,   0.500,      70,     0.291]],     
            [1,    [9/16 ,   0.562,      70,     0.291]],     
            [1.125,[9/16 ,   0.562]],
            [1.25, [5/8  ,   0.625]],
            [1.375,[5/8  ,   0.625]],
            [1.5,  [3/4  ,   0.750]],
            [1.75, [1    ,   1.000]],
            [2,    [1    ,   1.000]],
            ],
          entry = struct_val(UTS_setscrew, diam),
          dummy=assert(is_def(entry), str("Screw size ",diam," unsupported for headless screws")),
          drive_dims = drive == "hex" ? [["drive_size", INCH*entry[0]], ["drive_depth", INCH*entry[1]]]
                     : drive == "torx" ? [["drive_size", entry[2]], ["drive_depth", INCH*entry[3]]] 
                     : drive == "slot" ? [["drive_size", INCH*entry[4]], ["drive_depth", INCH*entry[5]]]
                     : []
         ) concat([["head","none"]], drive_dims) 
     : head=="hex" ? let( 
            UTS_hex = [
               // flat to flat width, height
               ["#2", [    1/8,   1/16]],
               ["#4", [   3/16,   1/16]],
               ["#6", [    1/4,   3/32]],
               ["#8", [    1/4,   7/64]],
               ["#10",[   5/16,    1/8]],
               ["#12",[   5/16,   5/32]],
               [1/4,  [   7/16,   5/32]],
               [5/16, [    1/2,  13/64]],
               [3/8,  [   9/16,    1/4]],
               [7/16, [    5/8,  19/64]],
               [1/2,  [    3/4,  11/32]],
               [9/16, [  13/16,  23/64]],
               [5/8,  [  15/16,  27/64]],
               [3/4,  [  1.125,    1/2]],
               [7/8,  [ 1+5/16,  37/64]],
               [1,    [    1.5,  43/64]],
               [1.125,[1+11/16,  11/16]],
               [1.25, [  1+7/8,  27/32]],
               [1.5,  [   2.25,  15/16]],
               [1.75, [  2+5/8, 1+3/32]],
               [2,    [      3, 1+7/32]],
            ],
            entry = struct_val(UTS_hex, diam)
           )
           assert(is_def(entry), str("Screw size ",diam," unsupported for head type \"",head,"\""))
           [["head", "hex"], ["head_size", INCH*entry[0]], ["head_height", INCH*entry[1]]] 
     : in_list(head,["socket","socket ribbed"]) ? let(
            UTS_socket = [    // height = screw diameter
                       //diam,   hex, torx size, hex depth, torx depth
               ["#0", [  0.096,  0.05, 6,         0.025,      0.027]],
               ["#1", [  0.118,  1/16, 7,         0.031,      0.036]],
               ["#2", [   9/64,  5/64, 8,         0.038,      0.037]],
               ["#3", [  0.161,  5/64, 8,         0.044,      0.041]],   // For larger sizes, hex recess depth is
               ["#4", [  0.183,  3/32, 10,        0.051,      0.049]],   // half the screw diameter
               ["#5", [  0.205,  3/32, 10,        0.057,      0.049]],
               ["#6", [  0.226,  7/64, 15,        0.064,      0.058]],
               ["#8", [  0.270,  9/64, 25,        0.077,      0.078]],
               ["#10",[   5/16,  5/32, 27,        undef,      0.088]],
               ["#12",[  0.324,  5/32, 27,        undef,      0.088]],
               [1/4,  [    3/8,  3/16, 30,        undef,      0.097]],
               [5/16, [  15/32,   1/4, 45,        undef,      0.137]],
               [3/8,  [   9/16,  5/16, 50,        undef,      0.155]],
               [7/16, [  21/32,   3/8, 55,        undef,      0.202]],
               [1/2,  [    3/4,   3/8, 55,        undef,      0.202]],
               [9/16, [  27/32,  7/16, 60,        undef,      0.240]],
               [5/8,  [  15/16,   1/2, 70,        undef,      0.291]],
               [3/4,  [  1.125,   5/8, 80,        undef,      0.332]],
               [7/8,  [ 1+5/16,   3/4, 100,       undef,      0.425]],
               [1,    [    1.5,   3/4, 100,       undef,      0.425]],
               [1.125,[1+11/16,   7/8, undef,     undef,      undef]],
               [1.25, [  1+7/8,   7/8, undef,     undef,      undef]],
               [1.375,[ 2+1/16,     1, undef,     undef,      undef]],
               [1.5,  [   2.25,     1, undef,     undef,      undef]],
               [1.75, [  2+5/8,  1.25, undef,     undef,      undef]],
               [2,    [      3,   1.5, undef,     undef,      undef]],
            ],
            entry = struct_val(UTS_socket, diam),
            dummy=assert(is_def(entry), str("Screw size ",diam," unsupported for head type \"",head,"\"")),
            hexdepth = is_def(entry[3]) ? entry[3]
                     : is_def(diameter) ? diameter/2
                     : undef,
            drive_size =  drive=="hex" ? [["drive_size",INCH*entry[1]], ["drive_depth",INCH*hexdepth]] :
                          drive=="torx" ? [["drive_size",entry[2]],["drive_depth",INCH*entry[4]]] : []
            )
            concat([["head",head],["head_size",INCH*entry[0]], ["head_height", INCH*diameter]],drive_size) 
     : head=="pan" ? let (
           UTS_pan = [  // pan head for phillips or slotted
                 //              head height 
                 //    diam,   slotted  phillips  phillips drive, phillips diam, phillips width, phillips depth, slot width, slot depth  torx size
               ["#0", [0.116,   0.039,   0.044,        0,          0.067,          0.013,           0.039,       0.023,         0.022]],
               ["#1", [0.142,   0.046,   0.053,        0,          0.085,          0.015,           0.049,       0.027,         0.027]],
               ["#2", [0.167,   0.053,   0.063,        1,          0.104,          0.017,           0.059,       0.031,         0.031,      8]],
               ["#3", [0.193,   0.060,   0.071,        1,          0.112,          0.019,           0.068,       0.035,         0.036]],
               ["#4", [0.219,   0.068,   0.080,        1,          0.122,          0.019,           0.078,       0.039,         0.040,     10]],
               ["#5", [0.245,   0.075,   0.089,        2,          0.158,          0.028,           0.083,       0.043,         0.045]],
               ["#6", [0.270,   0.082,   0.097,        2,          0.166,          0.028,           0.091,       0.048,         0.050,     15]],
               ["#8", [0.322,   0.096,   0.115,        2,          0.182,          0.030,           0.108,       0.054,         0.058,     20]],
               ["#10",[0.373,   0.110,   0.133,        2,          0.199,          0.031,           0.124,       0.060,         0.068,     25]],
               ["#12",[0.425,   0.125,   0.151,        3,          0.259,          0.034,           0.141,       0.067,         0.077]],
               [1/4,  [0.492,   0.144,   0.175,        3,          0.281,          0.036,           0.161,       0.075,         0.087,     30]],
               [5/16, [0.615,   0.178,   0.218,        4,          0.350,          0.059,           0.193,       0.084,         0.106]],
               [3/8,  [0.740,   0.212,   0.261,        4,          0.389,          0.065,           0.233,       0.094,         0.124]],
            ],
            htind = drive=="slot" ? 1 : 2,
            entry = struct_val(UTS_pan, diam),
            dummy=assert(is_def(entry), str("Screw size ",diam," unsupported for head type \"",head,"\"")),
            drive_size = drive=="phillips" ? [["drive_size", entry[3]],
                                             // ["drive_diameter",INCH*entry[4]],
                                             // ["drive_width",INCH*entry[5]],
                                              ["drive_depth",INCH*entry[6]]]
                                           : [["drive_size", INCH*entry[7]],
                                              ["drive_depth",INCH*entry[8]]])
           concat([["head","pan round"], ["head_size", INCH*entry[0]], ["head_height", INCH*entry[htind]]], drive_size) 
     : head=="button" || head=="round" ? let(
            UTS_button = [    // button, hex or torx drive
                 //   head diam, height, phillips, hex,   torx, hex depth
               ["#0", [0.114,    0.032,   undef,   0.035,  5    , 0.020, 0.015]],
               ["#1", [0.139,    0.039,   undef,   3/64,   5    , 0.028, 0.022]],
               ["#2", [0.164,    0.046,   undef,   3/64,   6    , 0.028, 0.023]],
               ["#3", [0.188,    0.052,   undef,   1/16,   undef, 0.035, undef]],
               ["#4", [0.213,    0.059,   undef,   1/16,   8    , 0.035, 0.032]],
               ["#5", [0.238,    0.066,   undef,   5/64,   10   , 0.044, 0.038]],
               ["#6", [0.262,    0.073,   undef,   5/64,   10   , 0.044, 0.038]],
               ["#8", [0.312,    0.087,   undef,   3/32,   15   , 0.052, 0.045]],
               ["#10",[0.361,    0.101,   undef,   1/8,    25   , 0.070, 0.052]],
               ["#12",[0.413,    0.114,   undef,   1/8,    undef, 0.070, undef]],   // also 0.410, .115, 9/64, hex depth guessed
               [1/4,  [0.437,    0.132,   undef,   5/32,   27   , 0.087, 0.068]],
               [5/16, [0.547,    0.166,   undef,   3/16,   40   , 0.105, 0.090]],
               [3/8,  [0.656,    0.199,   undef,   7/32,   45   , 0.122, 0.106]],
               [7/16, [0.750,    0.220,   undef,   1/4,    undef, 0.193, undef]],  // hex depth interpolated
               [1/2,  [0.875,    0.265,   undef,   5/16,   55   , 0.175, 0.158]],
               [5/8,  [1.000,    0.331,   undef,   3/8,    60   , 0.210, 0.192]],
               [3/4,  [1.1,      0.375,   undef,   7/16,   undef, 0.241]],  // hex depth extrapolated
             ],
             UTS_round = [   // slotted, phillips
                  // head diam, head height, phillips drive, hex, torx, ph diam, ph width, ph depth, slot width, slot depth
               ["#0", [0.113, 0.053, 0, undef, undef]],
               ["#1", [0.138, 0.061, 0, undef, undef]],
               ["#2", [0.162, 0.069, 1, undef, undef, 0.100, 0.017, 0.053, 0.031, 0.048]],
               ["#3", [0.187, 0.078, 1, undef, undef, 0.109, 0.018, 0.062, 0.035, 0.053]],
               ["#4", [0.211, 0.086, 1, undef, undef, 0.118, 0.019, 0.072, 0.039, 0.058]],
               ["#5", [0.236, 0.095, 2, undef, undef, 0.154, 0.027, 0.074, 0.043, 0.063]],
               ["#6", [0.260, 0.103, 2, undef, undef, 0.162, 0.027, 0.084, 0.048, 0.068]],
               ["#8", [0.309, 0.120, 2, undef, undef, 0.178, 0.030, 0.101, 0.054, 0.077]],
               ["#10",[0.359, 0.137, 2, undef, undef, 0.195, 0.031, 0.119, 0.060, 0.087]],
               ["#12",[0.408, 0.153, 3, undef, undef, 0.249, 0.032, 0.125, 0.067, 0.096]],
               [1/4,  [0.472, 0.175, 3, undef, undef, 0.268, 0.034, 0.147, 0.075, 0.109]],
               [5/16, [0.590, 0.216, 3, undef, undef, 0.308, 0.040, 0.187, 0.084, 0.132]],
               [3/8,  [0.708, 0.256, 4, undef, undef, 0.387, 0.064, 0.228, 0.094, 0.155]],
               [1/2,  [0.813, 0.355, 4, undef, undef, 0.416, 0.068, 0.256, 0.106, 0.211]]
             ],
             entry = struct_val(head=="button" ? UTS_button : UTS_round, diam),
             dummy=assert(is_def(entry), str("Screw size ",diam," unsupported for head type \"",head,"\"")),
             drive_index = drive=="phillips" ? 2 :
                           drive=="hex" ? 3 :
                           drive=="torx" ? 4 : undef,
             drive_size = drive=="phillips" && head=="round" ? [["drive_size", entry[2]],
                                                               // ["drive_diameter",u_mul(INCH,entry[5])],
                                                               // ["drive_width",INCH*entry[6]],
                                                                ["drive_depth",INCH*entry[7]]]
                        : drive=="slot" && head=="round" ?  [["drive_size", INCH*entry[8]],
                                                             ["drive_depth",u_mul(INCH,entry[9])]]
                        : drive=="hex" && head=="button" ? [["drive_size", INCH*entry[drive_index]],
                                                            ["drive_depth", u_mul(INCH,entry[5])]]
                        : drive=="torx" && head=="button" ? [["drive_size", entry[drive_index]],
                                                             ["drive_depth", u_mul(INCH,entry[6])]]
                        : is_def(drive_index) && head=="button" ? [["drive_size", entry[drive_index]]] : []
             )
             concat([["head",head],["head_size",INCH*entry[0]], ["head_height", INCH*entry[1]]],drive_size) 
     : head=="fillister" ? let(
             UTS_fillister = [ // head diam, head height, slot width, slot depth, phillips diam, phillips depth, phillips width, phillips #
                   ["#0", [0.096, 0.055, 0.023, 0.025, 0.067, 0.039, 0.013, 0]],
                   ["#1", [0.118, 0.069, 0.027, 0.031, 0.085, 0.049, 0.015,  ]],
                   ["#2", [0.140, 0.083, 0.031, 0.037, 0.104, 0.059, 0.017,  ]],
                   ["#3", [0.161, 0.095, 0.035, 0.043, 0.112, 0.068, 0.019, 1]],
                   ["#4", [0.183, 0.107, 0.039, 0.048, 0.122, 0.078, 0.019, 1]],
                   ["#5", [0.205, 0.120, 0.043, 0.054, 0.143, 0.067, 0.027, 2]],
                   ["#6", [0.226, 0.132, 0.048, 0.060, 0.166, 0.091, 0.028, 2]],
                   ["#8", [0.270, 0.156, 0.054, 0.071, 0.182, 0.108, 0.030, 2]],
                   ["#10",[0.313, 0.180, 0.060, 0.083, 0.199, 0.124, 0.031, 2]],
                   ["#12",[0.357, 0.205, 0.067, 0.094, 0.259, 0.141, 0.034, 3]],
                   [1/4,  [0.414, 0.237, 0.075, 0.109, 0.281, 0.161, 0.036, 3]],
                   [5/16, [0.518, 0.295, 0.084, 0.137, 0.322, 0.203, 0.042, 3]],
                   [3/8,  [0.622, 0.355, 0.094, 0.164, 0.389, 0.233, 0.065, 4]],
             ],
             entry = struct_val(UTS_fillister, diam),
             dummy=assert(is_def(entry), str("Screw size ",diam," unsupported for head type \"",head,"\"")),
             drive_size = drive=="phillips" ? [["drive_size", entry[7]],
                                            //   ["drive_diameter",INCH*entry[4]],
                                            //   ["drive_width",INCH*entry[6]],
                                               ["drive_depth",INCH*entry[5]]] 
                        : drive=="slot"?  [["drive_size", INCH*entry[2]],
                                           ["drive_depth",INCH*entry[3]]] : []
             )
             concat([["head", "fillister"], ["head_size", INCH*entry[0]], ["head_height", INCH*entry[1]]], drive_size) 
     : starts_with(head,"flat ") || head=="flat" ? 
         let(
             headparts = str_split(head," ",keep_nulls=false),
             partsok = [for (part=headparts) if (!in_list(part, ["flat","undercut","100","82","small","large","sharp"])) part], 
             dummy1=assert(partsok==[], str("Unknown flat head parameter(s) ",partsok)),
             dummy2=assert(!(in_list("small",headparts) && in_list("large",headparts)), "Cannot specify large and small flat head at the same time"),
             undercut = in_list("undercut", headparts),
             small = in_list("small",headparts) || (!in_list("large",headparts) && drive!="hex" && drive!="torx"),
             angle = in_list("100", headparts) ? 100 : 82,
             dummy3=assert(!undercut || angle==82, "Cannot make undercut 100 degree screw"),
             dummy4=assert(small || angle==82, "Only 82 deg large screws are supported"),
             dummy5=assert(small || !undercut, "Undercut only supported for small flatheads"),
             UTS_flat_small = [  // for phillips drive, slotted, and torx   ASME B18.6.3
                    //                     ----- Phillips ----              undercut phillips
                    //    ph drive, torx , diam,  depth, width, slotwidth,  diam, depth, width
                    //       0       1       2      3      4        5           6        7  
                   ["#0", [  0,     undef, 0.062, 0.035, 0.014,   0.023,   0.062, 0.035, 0.014]],
                   ["#1", [  0,     undef, 0.070, 0.043, 0.015,   0.026,   0.070, 0.043, 0.015]],
                   ["#2", [  1,     6    , 0.096, 0.055, 0.017,   0.031,   0.088, 0.048, 0.017]],
                   ["#3", [  1,     undef, 0.100, 0.060, 0.018,   0.035,   0.099, 0.059, 0.018]],
                   ["#4", [  1,     8    , 0.122, 0.081, 0.018,   0.039,   0.110, 0.070, 0.018]],
                   ["#5", [  2,     undef, 0.148, 0.074, 0.027,   0.043,   0.122, 0.081, 0.018]], //ph#1 for undercut
                   ["#6", [  2,     10   , 0.168, 0.094, 0.029,   0.048,   0.140, 0.066, 0.025]],
                   ["#8", [  2,     15   , 0.182, 0.110, 0.030,   0.054,   0.168, 0.094, 0.029]],
                   ["#10",[  2,     20   , 0.198, 0.124, 0.032,   0.060,   0.182, 0.110, 0.030]],
                   ["#12",[  3,     undef, 0.262, 0.144, 0.035,   0.067,   0.226, 0.110, 0.030]],
                   [1/4,  [  3,     27   , 0.276, 0.160, 0.036,   0.075,   0.244, 0.124, 0.032]],
                   [5/16, [  4,     40   , 0.358, 0.205, 0.061,   0.084,   0.310, 0.157, 0.053]],
                   [3/8,  [  4,     40   , 0.386, 0.234, 0.065,   0.094,   0.358, 0.205, 0.061]],
                   [1/2,  [  4,     undef, 0.418, 0.265, 0.069,   0.106,   0.402, 0.252, 0.068]]
             ],
             UTS_flat_small_100 = [  // for phillips drive, slotted, 100 deg angle  ASME B18.6.3
                    //                     ----- Phillips ----            
                    //    ph drive, torx , diam,  depth, width, slotwidth
                    //       0       1       2      3      4        5    
                   ["#0", [  0,     undef, 0.054, 0.027, 0.013,   0.023]],
                   ["#1", [  0,     undef, 0.062, 0.035, 0.014,   0.026]],
                   ["#2", [  1,     6    , 0.088, 0.048, 0.012,   0.031]],
                   ["#3", [  1,     undef, 0.096, 0.055, 0.014,   0.035]],
                   ["#4", [  1,     8    , 0.110, 0.070, 0.018,   0.039]],
                   ["#6", [  2,     10   , 0.148, 0.074, 0.027,   0.048]],
                   ["#8", [  2,     15   , 0.162, 0.090, 0.028,   0.054]],
                   ["#10",[  2,     20   , 0.178, 0.104, 0.030,   0.060]],
                   [1/4,  [  3,     27   , 0.240, 0.124, 0.033,   0.075]],
                   [5/16, [  4,     40   , 0.310, 0.157, 0.053,   0.084]],
                   [3/8,  [  4,     40   , 0.336, 0.182, 0.056,   0.094]],
             ],
             UTS_flat_large = [   // for hex drive, torx     ASME B18.3
                       // minimum
                       // head diam, hex drive size, torx size, hex depth, torx depth
                   ["#0", [ 0.117,   1/32,            3    ,     0.025,    0.016]],
                   ["#1", [ 0.143,   3/64,            6    ,     0.031,    0.036]],
                   ["#2", [ 0.168,   3/64,            6    ,     0.038,    0.036]],
                   ["#3", [ 0.193,   1/16,            8    ,     0.044,    0.041]],
                   ["#4", [ 0.218,   1/16,            10   ,     0.055,    0.038]],
                   ["#5", [ 0.240,   5/64,            10   ,     0.061,    0.038]],
                   ["#6", [ 0.263,   5/64,            15   ,     0.066,    0.045]],
                   ["#8", [ 0.311,   3/32,            20   ,     0.076,    0.053]],
                   ["#10",[ 0.359,    1/8,            25   ,     0.087,    0.061]],
                   [1/4,  [ 0.480,   5/32,            30   ,     0.111,    0.075]],
                   [5/16, [ 0.600,   3/16,            40   ,     0.135,    0.090]],
                   [3/8,  [ 0.720,   7/32,            45   ,     0.159,    0.106]],
                   [7/16, [ 0.781,    1/4,            50   ,     0.172,    0.120]],
                   [1/2,  [ 0.872,   5/16,            50   ,     0.220,    0.120]],
                   [5/8,  [ 1.112,    3/8,            55   ,     0.220,    0.158]],
                   [3/4,  [ 1.355,    1/2,            60   ,     0.248,    0.192]],
                   [7/8,  [ 1.604,   9/16,            undef,     0.297,    undef]],
                   [1,    [ 1.841,    5/8,            undef,     0.325,    undef]],
                   [1.125,[ 2.079,    3/4,            undef,     0.358,    undef]],
                   [1.25, [ 2.316,    7/8,            undef,     0.402,    undef]],
                   [1.375,[ 2.688,    7/8,            undef,     0.402,    undef]],
                   [1.5,  [ 2.938,      1,            undef,     0.435,    undef]],
             ],
             entry = struct_val(    angle==100 ? UTS_flat_small_100 
                                  : small ? UTS_flat_small 
                                  : UTS_flat_large, 
                                diam),
             dummy=assert(is_def(entry), str("Screw size ",diam," unsupported for head type \"",head,"\"")),
             a=[1.92+1.82, 1.88+1.8, 1.88+1.8]/2,
             b=[.003+.013, .063+.073, .125+.135]/2,
             smallsize = a[diamgroup]*diameter-b[diamgroup],
     
             csmall=[2.04, 2, 2],
             dsmall=[.003, .063, .125], 
             dlarge = [-.031, .031, .062],
             sharpsize = small ? csmall[diamgroup]*diameter-dsmall[diamgroup] // max theoretical (sharp) head diam
                                     : diameter < 0.1 ? [0.138,0.168,0.0822,0.0949][(diameter - 0.06)/.013] 
                                     : 2*diameter-dlarge[diamgroup],
             largesize = lerp(entry[0],sharpsize,.20),   // Have min size and max theory size.  Use point 20% up from min size
             undercut_height = let(
                                   a=[.432+.386, .417+.37, .417+.37]/2,
                                   b=[.001+.005, .026+.029, .052+.055]/2
                               )
                               a[diamgroup]*diameter + b[diamgroup],
             e=undercut ? [.202+.134, .192+.129, .192+.129]/2 
              : angle==100 ? [.222+.184]/2 
              : [.288+.192, .274+.184, .274+.184]/2,
             f=undercut ? [.002, .012+.011, .024+.019]/2
              : angle==100 ? [.0005+.004]/2 
              : [.004, .015+.017, .034+.027],
             tipdepth_small = e[diamgroup]*diameter + f[diamgroup],
             driveind = small && drive=="phillips" ? 0
                      : !small && drive=="hex" ? 1 
                      : drive=="torx" ? 2 
                      : undef,
             drive_dims = small ? (
                            drive=="phillips" && !undercut ? [
                                                            //  ["drive_diameter",INCH*entry[2]],
                                                            //  ["drive_width",INCH*entry[4]],
                                                              ["drive_depth",INCH*entry[3]]
                                                             ]
                          : drive=="phillips" && undercut ?  [
                                                             // ["drive_diameter",INCH*entry[6]],
                                                             // ["drive_width",INCH*entry[8]],
                                                              ["drive_depth",INCH*entry[7]]
                                                             ] 
                          : drive=="slot" ? [["drive_size", INCH*entry[5]], 
                                             ["drive_depth", INCH*tipdepth_small]] :
                            
                            []
                            )
                         :
                           (
                             drive=="hex" ? [["drive_depth", INCH*entry[3]]] :
                             drive=="torx" ? [["drive_depth", INCH*entry[4]]] : []
                           )
         )
         [
           ["head","flat"],
           ["head_angle",angle],
           ["head_size", in_list("sharp",headparts) ? sharpsize*INCH
                        : small ? smallsize*INCH : largesize*INCH], //entry[0]*INCH],
           ["head_size_sharp", sharpsize*INCH],
           if (is_def(driveind)) ["drive_size", (drive=="hex"?INCH:1)*entry[driveind]],
           if (undercut) ["head_height", undercut_height*INCH],
           each drive_dims
         ]
     : []
 )
 concat([
           ["type","screw_info"],
           ["system","UTS"],
           ["diameter",INCH*diameter],
           ["pitch", pitch],
           ["drive",drive]
         ],
         head_data
 );


function _screw_info_metric(diam, pitch, head, thread, drive) =
 let(
   pitch =
     is_num(thread) ? thread :
     is_def(pitch) ? pitch :
     let(
        tind=struct_val([["coarse",0],
                         ["fine",1],
                         ["extra fine",2],["extrafine",2],
             ["super fine",3],["superfine",3]],
                         downcase(thread)),
        dummy = assert(is_def(tind), str("Unknown thread type, \"",thread,"\"")),
                            // coarse  fine  xfine superfine
        ISO_thread = [
                      [1  , [0.25,    0.2 ,   undef, undef,]],
                      [1.2, [0.25,    0.2 ,   undef, undef,]],
                      [1.4, [0.3 ,    0.2 ,   undef, undef,]],
                      [1.6, [0.35,    0.2 ,   undef, undef,]],
                      [1.7, [0.35,   undef,   undef, undef,]],
                      [1.8, [0.35,    0.2 ,   undef, undef,]],
                      [2  , [0.4 ,    0.25,   undef, undef,]],
                      [2.2, [0.45,    0.25,   undef, undef,]],
                      [2.3, [0.4 ,   undef,   undef, undef,]],
                      [2.5, [0.45,    0.35,   undef, undef,]],
                      [2.6, [0.45,   undef,   undef, undef,]],
                      [3  , [0.5 ,    0.35,   undef, undef,]],
                      [3.5, [0.6 ,    0.35,   undef, undef,]],
                      [4  , [0.7 ,    0.5 ,   undef, undef,]],
                      [5  , [0.8 ,    0.5 ,   undef, undef,]],
                      [6  , [1   ,    0.75,   undef, undef,]],
                      [7  , [1   ,    0.75,   undef, undef,]],
                      [8  , [1.25,    1   ,    0.75, undef,]],
                      [9  , [1.25,    1   ,    0.75, undef,]],
                      [10 , [1.5 ,    1.25,    1   ,  0.75,]],
                      [11 , [1.5 ,    1   ,    0.75, undef,]],
                      [12 , [1.75,    1.5 ,    1.25,  1,   ]],
                      [14 , [2   ,    1.5 ,    1.25,  1,   ]],
                      [16 , [2   ,    1.5 ,    1   , undef,]],
                      [18 , [2.5 ,    2   ,    1.5 ,  1,   ]],
                      [20 , [2.5 ,    2   ,    1.5 ,  1,   ]],
                      [22 , [2.5 ,    2   ,    1.5 ,  1,]],
                      [24 , [3   ,    2   ,    1.5 ,  1,]],
                      [27 , [3   ,    2   ,    1.5 ,  1,]],
                      [30 , [3.5 ,    3   ,    2   ,  1.5,]],
                      [33 , [3.5 ,    3   ,    2   ,  1.5,]],
                      [36 , [4   ,    3   ,    2   ,  1.5,]],
                      [39 , [4   ,    3   ,    2   ,  1.5,]],
                      [42 , [4.5 ,    4   ,    3   ,  2,]],
                      [45 , [4.5 ,    4   ,    3   ,  2,]],
                      [48 , [5   ,    4   ,    3   ,  2,]],
                      [52 , [5   ,    4   ,    3   ,  2,]],
                      [56 , [5.5 ,    4   ,    3   ,  2,]],
                      [60 , [5.5 ,    4   ,    3   ,  2,]],
                      [64 , [6   ,    4   ,    3   ,  2,]],
                      [68 , [6   ,    4   ,    3   ,  2,]],
                      [72 , [6   ,    4   ,    3   ,  2,]],
                      [80 , [6   ,    4   ,    3   ,  2,]],
                      [90 , [6   ,    4   ,    3   ,  2,]],
                      [100, [6   ,    4   ,    3   ,  2,]],
        ],
        tentry = struct_val(ISO_thread, diam)
     )
     assert(is_def(tentry), str("Unknown screw size, M",diam))
     assert(is_def(tentry[tind]), str("No ",thread," pitch known for M",diam))
     tentry[tind],
   
   head_data =
       head=="none" ? let(
           metric_setscrew =
               [
                  //   hex    torx, torx depth, slot width, slot depth 
                [1.2, [undef, undef,   undef,    0.330,        0.460]],
                [1.4, [0.7,   undef,   undef,    undef,        undef]],
                [1.6, [0.7,   undef,   undef,    0.380,        0.650]],
                [1.8, [0.7,   undef,   undef,    undef,        undef]],
                [2,   [0.9,   undef,   undef,    0.380,        0.740]],
                [2.5, [1.3,   undef,   undef,    0.530,        0.835]],
                [3,   [1.5,     6,     0.77,     0.530,        0.925]],
                [3.5, [undef, undef,   undef,    0.630,        1.085]],
                [4,   [2,       8,     1.05,     0.730,        1.270]],
                [5,   [2.5,    10,     1.24,     0.930,        1.455]],
                [6,   [3,      15,     1.74,     1.130,        1.800]],
                [8,   [4,      25,     2.24,     1.385,        2.250]],
                [10,  [5,      40,     2.97,     1.785,        2.700]],
                [12,  [6,      45,     3.48,     2.185,        3.200]],
                [16,  [8,      55,     5.15]],
                [20,  [10,   undef,    undef]],    
               ],
            entry = struct_val(metric_setscrew, diam),
            dummy=assert(drive=="none" || is_undef(drive) || is_def(entry), str("Screw size M",diam," unsupported for headless screws")),
            drive_dim = drive=="hex" ? [["drive_size", entry[0]], ["drive_depth", diam/2]]
                      : drive=="torx" ? [["drive_size", entry[1]], ["drive_depth", entry[2]]]
                      : drive=="slot" ? [["drive_size", entry[3]], ["drive_depth", entry[4]]]
                      : []
           )
           concat([["head","none"]], drive_dim) 
     : head=="hex" ? let(
            metric_hex = [
              // flat to flat width, height
              [5, [8, 3.5]],
              [6, [10,4]],
              [8, [13, 5.3]],
              [10, [17, 6.4]],
              [12, [19, 7.5]],
              [14, [22, 8.8]],
              [16, [24, 10]],
              [18, [27,11.5]],
              [20, [30, 12.5]],
              [24, [36, 15]],
              [30, [46, 18.7]],
            ],
            entry = struct_val(metric_hex, diam)
           )
           assert(is_def(entry), str("Screw size M",diam," unsupported for head type \"",head,"\""))
           [["head", "hex"], ["head_size", entry[0]], ["head_height", entry[1]]] 
     : in_list(head,["socket","socket ribbed"]) ? let(
            // ISO 14579 gives dimensions for Torx (hexalobular) socket heads
            metric_socket = [    // height = screw diameter
                      //diam, hex, torx size, torx depth
                [1.4, [2.5,   1.3]],
                [1.6, [3,     1.5]],
                [2,   [3.8,   1.5,    6,        0.775]],
                [2.5, [4.5,     2,    8,        0.975]],
                [2.6, [5,       2,    8,        1.05]],
                [3,   [5.5,   2.5,    10,       1.14]],
                [3.5, [6.2,   2.5]]   ,
                [4,   [7,       3,    25,       1.61]],
                [5,   [8.5,     4,    27,       1.84]],
                [6,   [10,      5,    30,       2.22]],
                [7,   [12,      6]],
                [8,   [13,      6,    45,       3.115]],
                [10,  [16,      8,    50,       3.82]],
                [12,  [18,     10,    55,       5.015]],
                [14,  [21,     12,    60,       5.805]],
                [16,  [24,     14,    70,       6.815]],
                [18,  [27,     14,    80,       7.75]],
                [20,  [30,     17,    90,       8.945]],
                [22,  [33,     17]],
                [24,  [36,     19,    100,     10.79]],
                [27,  [40,     19]],
                [30,  [45,     22]],
                [33,  [50,     24]],
                [36,  [54,     27]],
                [42,  [63,     32]],
                [48,  [72,     36]],
            ],
            entry = struct_val(metric_socket, diam),
            dummy=assert(is_def(entry), str("Screw size M",diam," unsupported for head type \"",head,"\"")),
            drive_size =  drive=="hex" ? [["drive_size",entry[1]],["drive_depth",diam/2]] :
                          drive=="torx" ? [["drive_size", entry[2]], ["drive_depth", entry[3]]] :
                          []
            )
            concat([["head",head],["head_size",entry[0]], ["head_height", diam]],drive_size) 
     : in_list(head,["pan","pan round","pan flat"]) ? let (
           metric_pan = [  // pan head for phillips or slotted, torx from ISO 14583
                      //          head height
                      // diam, slotted  phillips phillips size  phillips diam, phillips depth, ph width, slot width,slot depth, torx size, torx depth
                 [1.6,   [3.2,   1  ,     1.3,        0,          undef,         undef,        undef,       0.4,      0.35]],
                 [2,     [4,     1.3,     1.6,        1,          1.82,          1.19,         0.48,        0.5,      0.5,        6,         0.7]],
                 [2.5,   [5,     1.5,     2,          1,          2.68,          1.53,         0.70,        0.6,      0.6,        8,         0.975]],
                 [3,     [5.6,   1.8,     2.4,        1,          2.90,          1.76,         0.74,        0.8,      0.7,        10,        1.14]],
                 [3.5,   [7,     2.1,     3.1,        2,          3.92,          1.95,         0.87,        1.0,      0.8,        15,        1.2]],
                 [4,     [8,     2.4 ,    3.1,        2,          4.40,          2.45,         0.93,        1.2,      1.0,        20,        1.465]],
                 [5,     [9.5,   3,       3.8,        2,          4.90,          2.95,         1.00,        1.2,      1.2,        25,        1.715]],
                 [6,     [12,    3.6,     4.6,        3,          6.92,          3.81,         1.14,        1.6,      1.4,        30,        2.22]],
                 [8,     [16,    4.8,     6,          4,          9.02,          4.88,         1.69,        2.0,      1.9,        45,        2.985]],
                 [10,    [20,    6.0,     7.5,        4,          10.18,         5.09,         1.84,        2.5,      2.4,        50,        3.82]], 
            ],
            type = head=="pan" ? (drive=="slot" ? "pan flat" : "pan round") : head,
            htind = drive=="slot" ? 1 : 2,
            entry = struct_val(metric_pan, diam),
            dummy=assert(is_def(entry), str("Screw size M",diam," unsupported for head type \"",head,"\"")),
            drive_size = drive=="phillips" ? [["drive_size", entry[3]],
                                              //["drive_diameter", entry[4]],
                                              ["drive_depth",entry[5]],
                                              //["drive_width",entry[6]]
                                             ] 
                       : drive=="torx" ? [["drive_size", entry[9]], ["drive_depth", entry[10]]]
                       : drive=="slot" ? [["drive_size", entry[7]], ["drive_depth", entry[8]]] 
                       : []
           )
           concat([["head",type], ["head_size", entry[0]], ["head_height", entry[htind]]], drive_size) 
     : head=="button" || head=="cheese" ? let(
            // hex drive depth from ISO 7380-1
            metric_button = [    // button, hex drive
                 //   head diam, height, hex, phillips, hex drive depth, torx size, torx depth
                 [1.6, [2.9,     0.8,    0.9, undef,    0.55]], // These four cases,
                 [2,   [3.5,     1.3,    1.3, undef,    0.69]], // extrapolated hex depth
                 [2.2, [3.8,     0.9,    1.3, undef,    0.76]], //
                 [2.5, [4.6,     1.5,    1.5, undef,    0.87]], //
                 [3,   [5.7,     1.65,   2,   undef,    1.04,                8,      0.81]],
                 [3.5, [5.7,     1.65,   2,   undef,    1.21]], // interpolated hex depth
                 [4,   [7.6,     2.2,    2.5, undef,    1.30,                15,     1.3]],
                 [5,   [9.5,     2.75,   3,   undef,    1.56,                25,     1.56]],
                 [6,   [10.5,    3.3,    4,   undef,    2.08,                27,     2.08]],
                 [8,   [14,      4.4,    5,   undef,    2.60,                40,     2.3]],
                 [10,  [17.5,    5.5,    6,   undef,    3.12,                45,     2.69]],
                 [12,  [21,      6.6,    8,   undef,    4.16,                55,     4.02]],    
                 [16,  [28,      8.8,    10,  undef,    5.2]], 
             ],
             metric_cheese = [   // slotted, phillips     ISO 1207, ISO 7048
                                 // hex drive is not supported (hence undefs)
                // head diam, head height, hex drive, phillips drive, slot width, slot depth, ph diam
                [1,   [2,     0.7,         undef,      undef]],
                [1.2, [2.3,   0.8,         undef,      undef]],
                [1.4, [2.6,   0.9,         undef,      undef]],
                [1.6, [3,     1,           undef,      undef,         0.4,        0.45]],
                [2,   [3.8,   1.3,         undef,      1    ,         0.5,        0.6,        undef,       undef]],
                [2.5, [4.5,   1.6,         undef,      1    ,         0.6,        0.7,          2.7,        1.20]],
                [3,   [5.5,   2,           undef,      2    ,         0.8,        0.85,         3.5,        0.86]],
                [3.5, [6,     2.4,         undef,      2    ,         1.0,        1.0,          3.8,        1.15]],
                [4,   [7,     2.6,         undef,      2    ,         1.2,        1.1,          4.1,        1.45]],
                [5,   [8.5,   3.3,         undef,      2    ,         1.2,        1.3,          4.8,        2.14]],
                [6,   [10,    3.9,         undef,      3    ,         1.6,        1.6,          6.2,        2.25]],
                [8,   [13,    5,           undef,      3    ,         2.0,        2.0,          7.7,        3.73]],
                [10,  [16,    6,           undef,      undef,         2.5,        2.4,        undef,       undef]]
             ],
             metric_cheese_torx = [ // torx cheese, ISO 14580, the heads are taller than other cheese screws
                      //head diam, head height, torx size, torx depth
                [2,   [3.8,        1.55,         6,         0.775]],
                [2.5, [4.5,        1.85,         8,         0.845]],
                [3,   [5.5,        2.4,         10,         1.14]],
                [3.5, [6,          2.6,         15,         1.2]],
                [4,   [7,          3.1,         20,         1.465]],
                [5,   [8.5,        3.65,        25,         1.715]],
                [6,   [10,         4.4,         30,         2.095]],
                [8,   [13,         5.8,         45,         2.855]],
                [10,  [16,         6.9,         59,         3.235]]
             ],

             entry = struct_val( head=="button" ? metric_button 
                               : drive=="torx"? metric_cheese_torx 
                               : metric_cheese, 
                            diam),
             dummy=assert(is_def(entry), str("Screw size M",diam," unsupported for head type \"",head,"\"")),
             drive_index = drive=="phillips" ? 3 
                         : drive=="hex" ? 2 
                         : undef,
             drive_dim = head=="button" && drive=="hex" ? [["drive_depth", entry[4]]] 
                       : head=="button" && drive=="torx" ? [["drive_size", entry[5]],["drive_depth", entry[6]]] 
                       : head=="cheese" && drive=="torx" ? [["drive_size", entry[2]],["drive_depth", entry[3]]] 
                       : head=="cheese" && drive=="slot" ? [["drive_size", entry[4]], ["drive_depth", entry[5]]] 
                       : head=="cheese" && drive=="phillips" ? [
                                                                //["drive_diameter", entry[6]],
                                                                ["drive_depth", entry[7]],
                                                                //["drive_width", entry[6]/4]  // Fabricated this width value to fill in missing field
                                                               ]  
                       :[],
             drive_size = is_def(drive_index) ? [["drive_size", entry[drive_index]]] : []
             )
             concat([["head",head],["head_size",entry[0]], ["head_height", entry[1]]],drive_size, drive_dim) 
     : starts_with(head,"flat ") || head=="flat" ?
         let(
             headparts = str_split(head," ",keep_nulls=false),
             partsok = [for (part=headparts) if (!in_list(part, ["flat","small","large","sharp","90"])) part], 
             dummy1=assert(partsok==[], str("Unknown flat head parameter(s) ",partsok)),
             dummy2=assert(!(in_list("small",headparts) && in_list("large",headparts)), "Cannot specify large and small flat head at the same time"),
             small = in_list("small",headparts) || (!in_list("large",headparts) && drive!="hex"),
             metric_flat_large = [ // for hex drive from ISO-10642, don't know where torx came from
                     // -- diam -----   hex size    hex depth     torx   torx depth
                     // theory  actual
                     //  max     min
                  [3,  [6.72,     5.54,      2  ,       1.1,        10,   0.96]],
                  [4,  [8.96,     7.53,      2.5,       1.5,        20,   1.34]],
                  [5,  [11.20,    9.43,      3  ,       1.9,        25,   1.54]],
                  [6,  [13.44,    11.34,     4  ,       2.2,        30,   1.91]],
                  [8,  [17.92,    15.24,     5  ,       3.0,        40,   2.3]],
                  [10, [22.4,     19.22,     6  ,       3.6,        50,   3.04]],
                  [12, [26.88,    23.12,     8  ,       4.3]], 
                  [14, [30.8,     26.52,    10  ,       4.5]],
                  [16, [33.6,     29.01,    10  ,       4.8]],
                  [20, [40.32,    36.05,    12  ,       5.6]]    
             ],
             metric_flat_small = [ // Phillips from ISO 7046
                                   // Slots from ISO 2009
                                   // Torx from ISO 14581
                    // theory    mean                                             nominal       mean             torx
                    //  diam, actual diam  ph size, ph diam, ph depth, ph width, slot width, slot depth  torx   mean depth
                 [1.6, [ 3.6,    2.85,         0,     1.6,    0.75,    undef,     0.4,         0.41,     undef,  undef  ]],
                 [2,   [ 4.4,    3.65,         0,     1.9,    1.05,     0.53,     0.5,         0.5,         6,    0.575 ]],
                 [2.5, [ 5.5,    4.55,         1,     2.9,    1.6,      0.74,     0.6,         0.625,       8,    0.725 ]],
                 [3,   [ 6.3,    5.35,         1,     3.2,    1.90,     0.79,     0.8,         0.725,      10,    0.765 ]],
                 [3.5, [ 8.2,    7.12,         2,     4.4,    2.15,     0.91,     1.0,         1.05,       15,    1.240 ]],
                 [4,   [ 9.4,    8.22,         2,     4.6,    2.35,     0.96,     1.2,         1.15,       10,    1.335 ]],
                 [5,   [10.4,    9.12,         2,     5.2,    2.95,     1.04,     1.2,         1.25,       25,    1.315 ]],
                 [6,   [12.6,   11.085,        3,     6.8,    3.25,     1.12,     1.6,         1.4,        30,    1.585 ]],
                 [8,   [17.3,   15.585,        4,     8.9,    4.30,     1.80,     2.0,         2.05,       45,    2.345 ]],
                 [10,  [20  ,   18.04,         4,    10.0,    5.40,    undef,     2.5,         2.3,        50,    2.605 ]],
                 [12,  [24  ,   21.75 ]],  // Additional screw head data from ISO 7721, but no driver data   
                 [14,  [28  ,   25.25 ]],
                 [16,  [32  ,   28.75 ]],
                 [18,  [36  ,   32.2  ]],
                 [20,  [40  ,   35.7  ]]
             ],
             entry = struct_val(small ? metric_flat_small : metric_flat_large, diam),
             dummy=assert(is_def(entry), str("Screw size M",diam," unsupported for head type \"",head,"\"")),
             driveind = small && drive=="phillips" ? 2
                      : !small && drive=="hex" ? 2
                      : !small && drive=="torx" ? 4
                      : small && drive=="torx" ? 8 : undef,
             drive_dim = small && drive=="phillips" ? [
                                                      // ["drive_diameter", entry[3]],
                                                       ["drive_depth",entry[4]],
                                                      // ["drive_width", entry[5]]
                                                      ] 
                       : small && drive=="slot" ? [["drive_size", entry[6]], ["drive_depth", entry[7]]] 
                       : drive=="torx" ? [["drive_depth", entry[driveind+1]]] 
                       : !small && drive=="hex" ? [["drive_depth", entry[3]]]
                       : [],
             sharpsize = entry[0]
         )
         [
           ["head","flat"],
           ["head_angle",90],
           ["head_size", in_list("sharp",headparts) ? sharpsize
                       : small ? entry[1]              // entry is mean diameter
                       : lerp(entry[1],entry[0],.2)],  // entry is min diameter, so enlarge it 20%
           ["head_size_sharp", sharpsize],
           if (is_def(driveind)) ["drive_size", entry[driveind]],
           each drive_dim
         ]
     : [] 
 )
 concat(
        [
          ["type","screw_info"],
          ["system","ISO"],
          ["diameter",diam],
          ["pitch", pitch],
          ["drive",drive]
        ],
        head_data
 );

function _is_positive(x) = is_num(x) && x>0;


function _validate_nut_spec(spec) =
   let(
       //dummy=echo_struct(spec,"Screw Specification"),
       systemOK = in_list(struct_val(spec,"system"), ["UTS","ISO"]),
       diamOK = _is_positive(struct_val(spec, "diameter")),
       pitch = struct_val(spec,"pitch"),
       pitchOK = is_undef(pitch) || (is_num(pitch) && pitch>=0),
       shape = struct_val(spec, "shape"),
       shapeOK = shape=="hex" || shape=="square",
       thicknessOK = _is_positive(struct_val(spec, "thickness")),
       widthOK = _is_positive(struct_val(spec, "width"))
    )
    assert(systemOK, str("Nut spec has invalid \"system\", ", struct_val(spec,"system"), ".  Must be \"ISO\" or \"UTS\""))
    assert(diamOK, str("Nut spec has invalid \"diameter\", ", struct_val(spec,"diameter")))
    assert(pitchOK, str("Nut spec has invalid \"pitch\", ", pitch))
    assert(shapeOK, str("Nut spec has invalid \"shape\", ", shape, ".  Must be \"square\" or \"hex\""))
    assert(thicknessOK, str("Nut spec thickness is not a postive number: ",struct_val(spec,"thickness")))
    assert(widthOK, str("Nut spec width is not a postive number: ",struct_val(spec,"width")))
    spec;

    
function _validate_screw_spec(spec) =
    let(
        //dummy=echo_struct(spec,"Screw Specification"),
        systemOK = in_list(struct_val(spec,"system"), ["UTS","ISO"]),
        diamOK = _is_positive(struct_val(spec, "diameter")),
        pitch = struct_val(spec,"pitch"),
        pitchOK = is_undef(pitch) || (is_num(pitch) && pitch>=0),
        head = struct_val(spec,"head"),
        headOK = head=="none" || 
                    (in_list(head, ["cheese","pan flat","pan round", "flat", "button","socket","socket ribbed", "fillister","round","hex"]) &&
                     _is_positive(struct_val(spec, "head_size"))),
        flatheadOK = (head!="flat" || _is_positive(struct_val(spec,"head_size_sharp"))),
        drive = struct_val(spec, "drive"),
        driveOK = is_undef(drive) || drive=="none"
                  || (_is_positive(struct_val(spec, "drive_depth")) && _is_positive(struct_val(spec, "drive_size")))
    )
    assert(systemOK, str("Screw spec has invalid \"system\", ", struct_val(spec,"system"), ".  Must be \"ISO\" or \"UTS\""))
    assert(diamOK, str("Screw spec has invalid \"diameter\", ", struct_val(spec,"diameter")))
    assert(pitchOK, str("Screw spec has invalid \"pitch\", ", pitch))
    assert(headOK, "Screw head type invalid or unknown for your screw type and size")  // head is "undef" for invalid heads; we don't know what the user specified
    assert(flatheadOK, "Flat head screw invalid because no \"head_size_sharp\" value is present.")
    assert(driveOK, str("Screw drive type \"",drive,"\" invalid or unknown for your screw size or head type, \"",head,"\""))
    spec;



// Function: thread_specification()
// Synopsis: Returns the thread geometry for a given screw.
// Topics: Threading, Screws
// See Also: screw(), screw_hole()
// Usage:
//   thread_specification(screw_spec, [tolerance], [internal])
// Description:
//   Determines actual thread geometry for a given screw with specified tolerance and nominal size.  See [tolerance](#subsection-tolerance) for
//   information on tolerances.  If tolerance is omitted the default is used.  If tolerance
//   is "none" or 0 then return the nominal thread geometry.  When `internal=true` the nut tolerance is used.  
//   .
//   The return value is a structure with the following fields:
//   - pitch: the thread pitch
//   - d_major: major diameter range
//   - d_pitch: pitch diameter range
//   - d_minor: minor diameter range
//   - basic: vector `[minor, pitch, major]` of the nominal or "basic" diameters for the threads
// Arguments:
//   screw_spec = screw specification structure
//   tolerance = thread geometry tolerance.  Default: For ISO, "6g" for screws, "6H" for internal threading (nuts).  For UTS, "2A" for screws, "2B" for internal threading (nuts).
//   internal = true for internal threads.  Default: false
function thread_specification(screw_spec, tolerance=undef, internal=false) =
  let( 
       diam = _nominal_diam(screw_spec),
       pitch = struct_val(screw_spec, "pitch"),
       tspec = tolerance == 0 || tolerance=="none" ? _exact_thread_tolerance(diam, pitch)
             :  struct_val(screw_spec,"system") == "ISO" ? _ISO_thread_tolerance(diam, pitch, internal, tolerance)
             :  struct_val(screw_spec,"system") == "UTS" ? _UTS_thread_tolerance(diam, pitch, internal, tolerance)
             :  assert(false,"Unknown screw system ",struct_val(screw_spec,"system"))
  )
  assert(min(struct_val(tspec,"d_minor"))>0, "Thread specification is too coarse for the diameter")
  tspec;





// recess sizing:
// http://www.fasnetdirect.com/refguide/Machinepancombo.pdf
//
/*   ASME B 18.6.3
http://www.smithfast.com/newproducts/screws/msflathead/


/* phillips recess diagram

http://files.engineering.com/getfile.aspx?folder=76fb0d5e-1fff-4c49-87a5-05979477ca88&file=Noname.jpg&__hstc=212727627.6c577ef84c12d9cc69c819eea7be49d2.1563972499721.1563972499721.1563972499721.1&__hssc=212727627.1.1563972499721&__hsfp=165344926

*/


//
// https://www.bayoucitybolt.com/socket-head-cap-screws-metric.html
//
// Torx drive depth for UTS and ISO (at least missing for "flat small", which means you can't select torx for this head type)
// Handle generic phillips (e.g. ph2) or remove it?

// https://www.fasteners.eu/tech-info/ISO/7721-2/
//
//    JIS 
//https://www.garagejournal.com/forum/media/jis-b-4633-vs-iso-8764-1-din-5260-ph.84492/

//square:
//https://www.aspenfasteners.com/content/pdf/square_drive_specification.pdf
//http://www.globalfastener.com/standards/index.php?narr58=149
//https://patents.google.com/patent/US1003657

// thread standards:
// https://www.gewinde-normen.de/en/index.html

/////////////////////////////////////////////////////////////////////////////////////////*
/////////////////////////////////////////////////////////////////////////////////////////*
/////////////////////////////////////////////////////////////////////////////////////////*
///  
///  TODO list:
///  
///  need to make holes at actual size instead of nominal?
///     or relative to actual size?
///     That means I need to preserve thread= to specify this
///  torx depth for UTS pan head
///  $fn control
///  phillips driver spec with ph# is confusing since it still looks up depth in tables
///     and can give an error if it's not found
///  torx depths missing for pan head
///  support for square drive?  (It's in the ASME standard)
///  
/////////////////////////////////////////////////////////////////////////////////////////*
/////////////////////////////////////////////////////////////////////////////////////////*
/////////////////////////////////////////////////////////////////////////////////////////*

// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap

