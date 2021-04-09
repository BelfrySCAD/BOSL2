//////////////////////////////////////////////////////////////////////
// LibFile: screws.scad
//   Functions and modules for creating metric and UTS standard screws and nuts.
// Includes:
//   include <BOSL2/std.scad>
//   include <BOSL2/screws.scad>
//////////////////////////////////////////////////////////////////////

include <structs.scad>
include <threading.scad>
include <phillips_drive.scad>
include <torx_drive.scad>

// Section: Generic Screw Creation


/*
http://mdmetric.com/thddata.htm#idx

Seems to show JIS has same nominal thread as others
https://www.nbk1560.com/~/media/Images/en/Product%20Site/en_technical/11_ISO%20General%20Purpose%20Metric%20Screw%20Threads.ashx?la=en

Various ISO standards here:  https://www.fasteners.eu/standards/ISO/4026/

Torx values:  https://www.stanleyengineeredfastening.com/-/media/web/sef/resources/docs/other/socket_screw_tech_manual_1.ashx

*/

function _parse_screw_name(name) =
    let( commasplit = str_split(name,","),
         length = str_num(commasplit[1]),
         xdash = str_split(commasplit[0], "-x"),
         type = xdash[0],
         thread = str_float(xdash[1])
    )
    type[0] == "M" || type[0] == "m" ? ["metric", str_float(substr(type,1)), thread, length] :
    let(
        diam = type[0] == "#" ? type :
               suffix(type,2)=="''" ? str_float(substr(type,0,len(type)-2)) :
               let(val=str_num(type))
               val == floor(val) && val>=0 && val<=12 ? str("#",type) : val
        )
    ["english", diam, thread, u_mul(25.4,length)];


// drive can be "hex", "phillips", "slot", "torx", or "none"
// or you can specify "ph0" up to "ph4" for phillips and "t20" for torx 20
function _parse_drive(drive=undef, drive_size=undef) =
    is_undef(drive) ? ["none",undef] :
    let(drive = downcase(drive))
    in_list(drive,["hex","phillips", "slot", "torx", "phillips", "none"]) ? [drive, drive_size] :
    drive[0]=="t" ? ["torx", str_int(substr(drive,1))] :
    substr(drive,0,2)=="ph" ? ["phillips", str_int(substr(drive,2))] :
    assert(str("Unknown screw drive type ",drive));


// Function: screw_info()
// Usage:
//   info = screw_info(name, [head], [thread], [drive], [drive_size], [oversize])
//
// Description:
//   Look up screw characteristics for the specified screw type.
//   .
//   For metric (ISO) the `name=` argument is formatted in a string like: `"M<size>x<pitch>,<length>"`.
//   e.g. `"M6x1,10"` specifies a 6mm diameter screw with a thread pitch of 1mm and length of 10mm.
//   You can omit the pitch or length, e.g. `"M6x1"`, or `"M6,10"`, or just `"M6"`.
//   .
//   For English (UTS) `name=` is a string like `"<size>-<threadcount>,<length>"`.
//   e.g. `"#8-32,1/2"`, or `"1/4-20,1"`.  Units are in inches, including the length.  Size can be a
//   number from 0 to 12 with or without a leading `#` to specify a screw gauge size, or any other
//   value to specify a diameter in inches, either as a float or a fraction, so `"0.5-13"` and
//   `"1/2-13"` are equivalent.  To force interpretation of the value as inches add `''` (two
//   single-quotes) to the end, e.g. `"1''-4"` is a one inch screw and `"1-80"` is a very small
//   1-gauge screw.  The pitch is specified using a thread count, the number of threads per inch.
//   The length is in inches.
//   .
//   If you omit the pitch then a standard screw pitch will be supplied from lookup tables for the
//   screw diameter you have chosen.  For each screw diameter, multiple standard pitches are possible.
//   The available thread pitch types are:
//   - `"coarse"`
//   - `"fine"`
//   - `"extrafine"` or `"extra fine"`
//   - `"superfine"` or `"super fine"` (Metric/ISO only.)
//   - `"UNC"` (English/UTS only.  Same as `"coarse"`.)
//   - `"UNF"` (English/UTS only.  Same as `"fine"`.)
//   - `"UNEF"` (English/UTS only.  Same as `"extrafine"`.)
//   .
//   The default pitch selection is `"coarse"`.  Note that this selection is case insensitive.  Set the
//   `thread=` argument to one of these values to choose a different pitch.  Note that not every pitch
//   category is defined at every diameter.  You can also specify the thread pitch directly, for example
//   you could set `thread=2` which would produce threads with a pitch of 2mm.  The final option is to
//   specify `thread="none"` to produce an unthreaded screw either to simplify the model or to use for
//   cutting out screw holes.  Setting the pitch to `0` (zero) also produces an unthreaded screw.
//   If you specify a numeric thread value it will override any value given in the `name=` argument.
//   .
//   The `head=` parameter specifies the type of head the screw will have.  Options for the head are
//   `"flat"`, `"flat small"`, `"flat large"`, `"flat undercut"`, `"round"`, `"pan"`, `"pan flat"`,
//   `"pan round"`, `"socket"`, `"hex"`, `"button"`, `"cheese"`, `"fillister"`,  or `"none"`
//   .
//   Note that different sized flat heads exist for the same screw type.  Sometimes this depends on
//   the type of recess.  If you specify `"flat"` then the size will be chosen appropriately for the
//   recess you specify.  The default is `"none"`.
//   .
//   The `drive=` argument specifies the recess type.  Options for the drive are `"none"`, `"hex"`,
//   `"slot"`, `"phillips"`, `"ph0"` to `"ph4"` (for phillips of the specified size), `"torx"` or
//   `"t<size>"` (for Torx at a specified size, e.g. `"t20"`).  The default drive is `"none"`
//   .
//   Only some combinations of head and drive type are supported:
//   .
//   Head              | Drive
//   ----------------- | ----------------------------
//   `"none"`          | hex, torx
//   `"hex"`           | *none*
//   `"socket"`        | hex, torx
//   `"button"`        | hex, torx
//   `"flat"`          | slot, phillips, hex, torx
//   `"round"`         | slot, phillips (UTS/English only.)
//   `"fillister"`     | slot, phillips (UTS/English only.)
//   `"flat small"`    | phillips, slot (UTS/English only.)
//   `"flat large"`    | hex, torx (UTS/English only.)
//   `"flat undercut"` | slot, phillips (UTS/English only.)
//   `"pan"`           | slot, phillips (ISO/Metric only.)
//   `"cheese"`        | slot, phillips (ISO/Metric only.)
//   .
//   The drive size is specified appropriately to the drive type: drive number for phillips or torx,
//   and allen width in mm or inches (as appropriate) for hex.  Drive size is determined automatically
//   from the screw size, but by passing the `drive_size=` argument you can override the default, or
//   in cases where no default exists you can specify it.
//   .
//   The `oversize=` parameter adds the specified amount to the screw and head diameter to make an
//   oversized screw.  This is intended for generating clearance holes, not for dealing with printer
//   inaccuracy.  Does not affect length, thread pitch or head height.
//   .
//   The output is a [[struct|structs.scad]] with the following fields:
//   .
//   Field              | What it is
//   ------------------ | ---------------
//   `"system"`         | Either `"UTS"` or `"ISO"` (used for correct tolerance computation).
//   `"diameter"`       | The nominal diameter of the screw shaft in mm.
//   `"pitch"`          | The thread pitch in mm.
//   `"head"`           | The type of head (a string from the list above).
//   `"head_size"`      | Size of the head in mm.
//   `"head_angle"`     | Countersink angle for flat heads.
//   `"head_height"`    | Height of the head (when needed to specify the head).
//   `"drive"`          | The drive type (`"phillips"`, `"torx"`, `"slot"`, `"hex"`, `"none"`)
//   `"drive_size"`     | The drive size, either a drive number (phillips or torx) or a dimension in mm (hex).  Not defined for slot drive.
//   `"drive_diameter"` | Diameter of a phillips drive.
//   `"drive_width"`    | Width of the arms of the cross in a phillips drive or the slot for a slot drive.
//   `"drive_depth"`    | Depth of the drive recess.
//   `"length"`         | Length of the screw in mm measured in the customary fashion.  For flat head screws the total length and for other screws, the length from the bottom of the head to the screw tip.
//
// Arguments:
//   name = screw specification, e.g. "M5x1" or "#8-32"
//   head = head type (see list above).  Default: none
//   thread = thread type or specification.  Default: "coarse"
//   drive = drive type.  Default: none
//   drive_size = size of drive recess to override computed value
//   oversize = amount to increase screw diameter for clearance holes.  Default: 0
function screw_info(name, head, thread="coarse", drive, drive_size=undef, oversize=0) =
  let(type=_parse_screw_name(name),
      drive_info = _parse_drive(drive, drive_size),
      drive=drive_info[0],
    screwdata =
      type[0] == "english" ? _screw_info_english(type[1],type[2], head, thread, drive) :
      type[0] == "metric" ? _screw_info_metric(type[1], type[2], head, thread, drive) :
      [],
    over_ride = concat(
                        is_def(type[3]) ? ["length",type[3]] : [],
                        is_def(drive_info[1]) ? ["drive_size", drive_info[1]] : [],
                        ["diameter", oversize+struct_val(screwdata,"diameter"),
                         "head_size", u_add(oversize,struct_val(screwdata,"head_size"))]
                      )
  )
  struct_set(screwdata, over_ride);


function _screw_info_english(diam, threadcount, head, thread, drive) =
 let(
   inch = 25.4,
   diameter = is_string(diam) ? str_int(substr(diam,1))*0.013 +0.06 :
              diam,
   pitch =
     is_def(threadcount) ? inch/threadcount :
     is_num(thread) ? thread :
     let(
        tind=struct_val([["coarse",0],["unc",0],
                         ["fine",1],["unf",1],
                         ["extra fine",2],["extrafine",2],["unef",2]],
                         downcase(thread)),
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
         ]
       )
      inch / struct_val(UTS_thread, diam)[tind],
      head_data =
         head=="none" || is_undef(head) ? let (
          UTS_setscrew = [   // hex width, hex depth
            ["#0", [0.028, 0.050]],
            ["#1", [0.035, 0.060]],
            ["#2", [0.035, 0.060]],
            ["#3", [0.05 , 0.070]],
            ["#4", [0.05 , 0.045, 6, 0.027]],
            ["#5", [1/16 , 0.080, 7, 0.036]],
            ["#6", [1/16 , 0.080, 7, 0.036]],
            ["#8", [5/64 , 0.090, 8, 0.041]],
            ["#10",[3/32 , 0.100, 10, 0.049]],
            [1/4,  [1/8  , 0.125, 15, 0.068]],
            [5/16, [5/32 , 0.156, 25, 0.088]],
            [3/8,  [3/16 , 0.188, 30, 0.097]],
            [7/16, [7/32 , 0.219, 40, 0.117]],
            [1/2,  [1/4  , 0.250, 45, 0.137]],
            [5/8,  [5/16 , 0.312, 55, 0.202]],
            [3/4,  [3/8  , 0.375, 60, 0.202]],
            [7/8,  [1/2  , 0.500, 70, 0.291]],
            [1,    [9/16 , 0.562, 70, 0.291]],
            [1.125,[9/16 , 0.562]],
            [1.25, [5/8  , 0.625]],
            [1.375,[5/8  , 0.625]],
            [1.5,  [3/4  , 0.750]],
            [1.75, [1    , 1.000]],
            [2,    [1    , 1.000]],
            ],
          entry = struct_val(UTS_setscrew, diam),
          drive_dims = drive == "hex" ? [["drive_size", inch*entry[0]], ["drive_depth", inch*entry[1]]] :
                       drive == "torx" ? [["drive_size", entry[2]], ["drive_depth", inch*entry[3]]] : []
         ) concat([["head","none"]], drive_dims) :
         head=="hex" ? let(
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
           [["head", "hex"], ["head_size", inch*entry[0]], ["head_height", inch*entry[1]]] :
         head=="socket" ? let(
            UTS_socket = [    // height = screw diameter
                       //diam, hex, torx size, philips depth, torx depth
               ["#0", [  0.096,  0.05, 6,     0.025, 0.027]],
               ["#1", [  0.118,  1/16, 7,     0.031, 0.036]],
               ["#2", [   9/64,  5/64, 8,     0.038, 0.037]],
               ["#3", [  0.161,  5/64, 8,     0.044, 0.041]],   // For larger sizes, recess depth is
               ["#4", [  0.183,  3/32, 10,    0.051, 0.049]],   // half the diameter
               ["#5", [  0.205,  3/32, 10,    0.057, 0.049]],
               ["#6", [  0.226,  7/64, 15,    0.064, 0.058]],
               ["#8", [  0.270,  9/64, 25,    0.077, 0.078]],
               ["#10",[   5/16,  5/32, 27,    undef, 0.088]],
               ["#12",[  0.324,  5/32, undef, undef, undef]],
               [1/4,  [    3/8,  3/16, 30,    undef, 0.097]],
               [5/16, [  15/32,   1/4, 45,    undef, 0.137]],
               [3/8,  [   9/16,  5/16, 50,    undef, 0.155]],
               [7/16, [  21/32,   3/8, 55,    undef, 0.202]],
               [1/2,  [    3/4,   3/8, 55,    undef, 0.202]],
               [9/16, [  27/32,  7/16, undef, undef, undef]],
               [5/8,  [  15/16,   1/2, 70,    undef, 0.291]],
               [3/4,  [  1.125,   5/8, 80,    undef, 0.332]],
               [7/8,  [ 1+5/16,   3/4, 100,   undef, 0.425]],
               [1,    [    1.5,   3/4, 100,   undef, 0.425]],
               [1.125,[1+11/16,   7/8, undef, undef, undef]],
               [1.25, [  1+7/8,   7/8, undef, undef, undef]],
               [1.375,[ 2+1/16,     1, undef, undef, undef]],
               [1.5,  [   2.25,     1, undef, undef, undef]],
               [1.75, [  2+5/8,  1.25, undef, undef, undef]],
               [2,    [      3,   1.5, undef, undef, undef]],
            ],
            entry = struct_val(UTS_socket, diam),
            hexdepth = is_def(entry[3]) ? entry[3]
                     : is_def(diam) ? diam/2
                     : undef,
            drive_size =  drive=="hex" ? [["drive_size",inch*entry[1]], ["drive_depth",inch*hexdepth]] :
                          drive=="torx" ? [["drive_size",entry[2]],["drive_depth",inch*entry[4]]] : []
            )
            concat([["head","socket"],["head_size",inch*entry[0]], ["head_height", inch*diameter]],drive_size) :
         head=="pan" ? let (
           UTS_pan = [  // pan head for phillips or slotted
                 // diam, head ht slotted, head height phillips, phillips drive, phillips diam, phillips width, phillips depth, slot width, slot depth
               ["#0", [0.116, 0.039, 0.044, 0, 0.067, 0.013, 0.039, 0.023, 0.022]],
               ["#1", [0.142, 0.046, 0.053, 0, 0.085, 0.015, 0.049, 0.027, 0.027]],
               ["#2", [0.167, 0.053, 0.063, 1, 0.104, 0.017, 0.059, 0.031, 0.031]],
               ["#3", [0.193, 0.060, 0.071, 1, 0.112, 0.019, 0.068, 0.035, 0.036]],
               ["#4", [0.219, 0.068, 0.080, 1, 0.122, 0.019, 0.078, 0.039, 0.040]],
               ["#5", [0.245, 0.075, 0.089, 2, 0.158, 0.028, 0.083, 0.043, 0.045]],
               ["#6", [0.270, 0.082, 0.097, 2, 0.166, 0.028, 0.091, 0.048, 0.050]],
               ["#8", [0.322, 0.096, 0.115, 2, 0.182, 0.030, 0.108, 0.054, 0.058]],
               ["#10",[0.373, 0.110, 0.133, 2, 0.199, 0.031, 0.124, 0.060, 0.068]],
               ["#12",[0.425, 0.125, 0.151, 3, 0.259, 0.034, 0.141, 0.067, 0.077]],
               [1/4,  [0.492, 0.144, 0.175, 3, 0.281, 0.036, 0.161, 0.075, 0.087]],
               [5/16, [0.615, 0.178, 0.218, 4, 0.350, 0.059, 0.193, 0.084, 0.106]],
               [3/8,  [0.740, 0.212, 0.261, 4, 0.389, 0.065, 0.233, 0.094, 0.124]],
            ],
            htind = drive=="slot" ? 1 : 2,
            entry = struct_val(UTS_pan, diam),
            drive_size = drive=="phillips" ? [["drive_size", entry[3]], ["drive_diameter",inch*entry[4]],["drive_width",inch*entry[5]],["drive_depth",inch*entry[6]]] :
                                            [["drive_width", inch*entry[7]], ["drive_depth",inch*entry[8]]])
           concat([["head","pan"], ["head_size", inch*entry[0]], ["head_height", inch*entry[htind]]], drive_size) :
         head=="button" || head=="round" ? let(
            UTS_button = [    // button, hex or torx drive
                 //   head diam, height, phillips, hex, torx, hex depth
               ["#0", [0.114, 0.032, undef, 0.035,5    , 0.020, 0.017]],
               ["#1", [0.139, 0.039, undef, 3/64, 5    , 0.028, 0.020]],
               ["#2", [0.164, 0.046, undef, 3/64, 6    , 0.028, 0.023]],
               ["#3", [0.188, 0.052, undef, 1/16, undef, 0.035, undef]],
               ["#4", [0.213, 0.059, undef, 1/16, 8    , 0.035, 0.032]],
               ["#5", [0.238, 0.066, undef, 5/64, undef, 0.044, undef]],
               ["#6", [0.262, 0.073, undef, 5/64, 10   , 0.044, 0.038]],
               ["#8", [0.312, 0.087, undef, 3/32, 15   , 0.052, 0.045]],
               ["#10",[0.361, 0.101, undef, 1/8,  25   , 0.070, 0.052]],
               ["#12",[0.413, 0.114, undef, 1/8,  undef, 0.070, undef]],   // also 0.410, .115, 9/64, hex depth guessed
               [1/4,  [0.437, 0.132, undef, 5/32, 27   , 0.087, 0.068]],
               [5/16, [0.547, 0.166, undef, 3/16, 40   , 0.105, 0.090]],
               [3/8,  [0.656, 0.199, undef, 7/32, 45   , 0.122, 0.106]],
               [7/16, [0.750, 0.220, undef, 1/4,  undef, 0.193, undef]],  // hex depth interpolated
               [1/2,  [0.875, 0.265, undef, 5/16, 55   , 0.175, 0.158]],
               [5/8,  [1.000, 0.331, undef, 3/8,  60,  , 0.210, 0.192]],
               [3/4,  [1.1,   0.375, undef, 7/16, undef, 0.241]],  // hex depth extrapolated
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
             drive_index = drive=="phillips" ? 2 :
                           drive=="hex" ? 3 :
                           drive=="torx" ? 4 : undef,
             drive_size = drive=="phillips" && head=="round" ? [["drive_size", entry[2]], ["drive_diameter",inch*entry[5]],
                                              ["drive_width",inch*entry[6]],["drive_depth",inch*entry[7]]] :
                          drive=="slot" && head=="round" ?  [["drive_width", inch*entry[8]], ["drive_depth",inch*entry[9]]] :
                          drive=="hex" && head=="button" ? [["drive_size", inch*entry[drive_index]], ["drive_depth", inch*entry[5]]]:
                          drive=="torx" && head=="button" ? [["drive_size", entry[drive_index]], ["drive_depth", inch*entry[6]]]:
                          is_def(drive_index) && head=="button" ? [["drive_size", entry[drive_index]]] : []
             )
             concat([["head",head],["head_size",inch*entry[0]], ["head_height", inch*entry[1]]],drive_size) :
         head=="fillister" ? let(
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
             drive_size = drive=="phillips" ? [["drive_size", entry[7]], ["drive_diameter",inch*entry[4]],
                                              ["drive_width",inch*entry[6]],["drive_depth",inch*entry[5]]] :
                          drive=="slot"?  [["drive_width", inch*entry[2]], ["drive_depth",inch*entry[3]]] : []
             )
             concat([["head", "fillister"], ["head_size", inch*entry[0]], ["head_height", inch*entry[1]]], drive_size) :
         starts_with(head,"flat") ? let(
             small = head == "flat small" || head == "flat undercut" || (head=="flat" && (drive!="hex" && drive!="torx")),
             undercut = head=="flat undercut",
             UTS_flat_small = [  // for phillips drive, slotted, and torx
                //    diam, ph drive, torx drive, undercut height, phdiam, phdepth, phwidth, slotwidth, slotdepth, uc phdiam, uc phdepth, ucphwidth,ucslotdepth

                   ["#0", [ .112,  0, undef, 0.025, 0.062, 0.035, 0.014, 0.023, 0.015, 0.062, 0.035, 0.014, 0.011]],
                   ["#1", [ .137,  0, undef, 0.031, 0.070, 0.043, 0.015, 0.026, 0.019, 0.070, 0.043, 0.015, 0.014]],
                   ["#2", [ .162,  1, 6    , 0.036, 0.096, 0.055, 0.017, 0.031, 0.023, 0.088, 0.048, 0.017, 0.016]],
                   ["#3", [ .187,  1, undef, 0.042, 0.100, 0.060, 0.018, 0.035, 0.027, 0.099, 0.059, 0.018, 0.019]],
                   ["#4", [ .212,  1, 8    , 0.047, 0.122, 0.081, 0.018, 0.039, 0.030, 0.110, 0.070, 0.018, 0.022]],
                   ["#5", [ .237,  2, undef, 0.053, 0.148, 0.074, 0.027, 0.043, 0.034, 0.122, 0.081, 0.018, 0.024]],  // ph#1 for undercut
                   ["#6", [ .262,  2, 10   , 0.059, 0.168, 0.094, 0.029, 0.048, 0.038, 0.140, 0.066, 0.025, 0.027]],
                   ["#8", [ .312,  2, 15   , 0.070, 0.182, 0.110, 0.030, 0.054, 0.045, 0.168, 0.094, 0.029, 0.032]],
                   ["#10",[ .362,  2, 20   , 0.081, 0.198, 0.124, 0.032, 0.060, 0.053, 0.182, 0.110, 0.030, 0.037]],
                   ["#12",[ .412,  3, undef, 0.092, 0.262, 0.144, 0.035, 0.067, 0.060, 0.226, 0.110, 0.030, 0.043]],
                   [1/4,  [ .477,  3, 27   , 0.107, 0.276, 0.160, 0.036, 0.075, 0.070, 0.244, 0.124, 0.032, 0.050]],
                   [5/16, [ .597,  4, 40   , 0.134, 0.358, 0.205, 0.061, 0.084, 0.088, 0.310, 0.157, 0.053, 0.062]],
                   [3/8,  [ .717,  4, 40   , 0.161, 0.386, 0.234, 0.065, 0.094, 0.106, 0.358, 0.205, 0.061, 0.075]],
                   [1/2,  [ .815,  4, undef, 0.156, 0.418, 0.265, 0.069, 0.106, 0.103, 0.402, 0.252, 0.068, 0.072]]
             ],
             UTS_flat_large = [   // for hex drive, torx     ASME B18.3
                     // head diam, hex drive size, torx size, hex depth, torx depth
                   ["#0", [ 0.138, 1/32, 3    , 0.025, 0.016]],
                   ["#1", [ 0.168, 3/64, 6    , 0.031, 0.036]],
                   ["#2", [ 0.197, 3/64, 6    , 0.038, 0.036]],
                   ["#3", [ 0.226, 1/16, 8    , 0.044, 0.041]],
                   ["#4", [ 0.255, 1/16, 10   , 0.055, 0.038]],
                   ["#5", [ 0.281, 5/64, 10   , 0.061, 0.038]],
                   ["#6", [ 0.307, 5/64, 15   , 0.066, 0.045]],
                   ["#8", [ 0.359, 3/32, 20   , 0.076, 0.053]],
                   ["#10",[ 0.411,  1/8, 25   , 0.087, 0.061]],
                   ["#12",[ 0.422,  1/8, undef, 0.111, undef]],
                   [1/4,  [ 0.531, 5/32, 30   , 0.135, 0.075]],
                   [5/16, [ 0.656, 3/16, 40   , 0.159, 0.090]],
                   [3/8,  [ 0.810, 7/32, 45   , 0.159, 0.106]],
                   [7/16, [ 0.844,  1/4, 50   , 0.172, 0.120]],
                   [1/2,  [ 0.938, 5/16, 50   , 0.220, 0.120]],
                   [5/8,  [ 1.188,  3/8, 55   , 0.220, 0.158]],
                   [3/4,  [ 1.438,  1/2, 60   , 0.248, 0.192]],
                   [7/8,  [ 1.688, 9/16, undef, 0.297, undef]],
                   [1,    [ 1.938,  5/8, undef, 0.325, undef]],
                   [1.125,[ 2.188,  3/4, undef, 0.358, undef]],
                   [1.25, [ 2.438,  7/8, undef, 0.402, undef]],
                   [1.5,  [ 2.938,    1, undef, 0.435, undef]],
             ],
             entry = struct_val(small ? UTS_flat_small : UTS_flat_large, diam),
             driveind = small && drive=="phillips" || !small && drive=="hex" ? 1 :
                        drive=="torx" ? 2 :
                        undef,
             fff=echo("------------------------", driveind),
             drive_dims = small ? (
                            drive=="phillips" && !undercut ? [["drive_diameter",inch*entry[4]],
                                              ["drive_width",inch*entry[6]],["drive_depth",inch*entry[5]]] :
                            drive=="phillips" && undercut ?  [["drive_diameter",inch*entry[9]],
                                              ["drive_width",inch*entry[11]],["drive_depth",inch*entry[10]]] :
                            drive=="slot" && !undercut ? [["drive_width", inch*entry[7]], ["drive_depth",inch*entry[8]]] :
                            drive=="slot" && undercut ? [["drive_width", inch*entry[7]], ["drive_depth",inch*entry[12]]] :
                                 []
                            )
                         :
                           (
                             drive=="hex" ? [["drive_depth", inch*entry[3]]] :
                             drive=="torx" ? [["drive_depth", inch*entry[4]]] : []
                           )
             )
             concat([["head","flat"],["head_angle",82],["head_size",inch*entry[0]]],
                    is_def(driveind) ? [["drive_size", (drive=="hex"?inch:1)*entry[driveind]]] : [],
                    undercut ? [["head_height", inch*entry[3]]] : [], drive_dims
                   ) : []
    )
    concat([["system","UTS"],["diameter",inch*diameter],["pitch", pitch],["drive",drive]],
            head_data
          );


function _screw_info_metric(diam, pitch, head, thread, drive) =
 let(
   a=echo(metricsi=diam,pitch,head,thread,drive),
   pitch = is_num(thread) ? thread :
     is_def(pitch) ? pitch :
     let(
        tind=struct_val([["coarse",0],
                         ["fine",1],
                         ["extra fine",2],["extrafine",2],
             ["super fine",3],["superfine",3]],
                         downcase(thread)),
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
         ]
       )
      struct_val(ISO_thread, diam)[tind],
      head_data =
         head=="none" || is_undef(head) ? let(
           metric_setscrew =
               [
                [1.4, [0.7]],
                [1.6, [0.7]],
                [1.8, [0.7]],
                [2,   [0.9]],
                [2.5, [1.3]],
                [3,   [1.5, 6, 0.77]],
                [4,   [2, 8, 1.05]],
                [5,   [2.5, 10, 1.24]],
                [6,   [3, 15, 1.74]],
                [8,   [4, 25, 2.24]],
                [10,  [5, 40, 2.97]],
                [12,  [6, 45, 3.48]],
                [16,  [8, 55, 5.15]],
                [20,  [10, undef, undef]],
               ],
            entry = struct_val(metric_setscrew, diam),
            drive_dim = drive=="hex" ? [["drive_size", entry[0]], ["drive_depth", diam/2]] :
                        drive=="torx" ? [["drive_size", entry[1]], ["drive_depth", entry[2]]] : []
           )
           concat([["head","none"]], drive_dim) :
         head=="hex" ? let(
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
           [["head", "hex"], ["head_size", entry[0]], ["head_height", entry[1]]] :
         head=="socket" ? let(
            metric_socket = [    // height = screw diameter
                      //diam, hex
                [1.4, [2.5, 1.3]],
                [1.6, [3,   1.5]],
                [2,   [3.8, 1.5, 6, 0.77]],
                [2.5, [4.5,   2, 8, 1.05]],
                [2.6, [5,     2, 8, 1.05]],
                [3,   [5.5, 2.5, 10, 1.24]],
                [3.5, [6.2, 2.5]],
                [4,   [7,     3, 25, 1.76]],
                [5,   [8.5,   4, 27, 2.24]],
                [6,   [10,    5, 30, 2.47]],
                [7,   [12,    6]],
                [8,   [13,    6, 45, 3.48]],
                [10,  [16,    8, 50, 3.93]],
                [12,  [18,   10, 55, 5.15]],
                [14,  [21,   12]],
                [16,  [24,   14, 70, 7.39]],
                [18,  [27,   14]],
                [20,  [30,   17, 90, 9.67]],
                [22,  [33,   17]],
                [24,  [36,   19, 100, 10.79]],
                [27,  [40,   19]],
                [30,  [45,   22]],
                [33,  [50,   24]],
                [36,  [54,   27]],
                [42,  [63,   32]],
                [48,  [72,   36]],
            ],
            entry = struct_val(metric_socket, diam),
            drive_size =  drive=="hex" ? [["drive_size",entry[1]],["drive_depth",diam/2]] :
                          drive=="torx" ? [["drive_size", entry[2]], ["drive_depth", entry[3]]] :
                          []
            )
            concat([["head","socket"],["head_size",entry[0]], ["head_height", diam]],drive_size) :
         starts_with(head,"pan") ? let (
           metric_pan = [  // pan head for phillips or slotted
                 // diam, slotted diam, phillips diam, phillips depth, ph width, slot width,slot depth
                 [1.6,[3.2, 1  ,  1.3,    0, undef,undef,undef, 0.4, 0.35]],
                 [2,  [4,   1.3,  1.6,    1, 1.82, 1.19, 0.48, 0.5, 0.5]],
                 [2.5,[5,   1.5,  2,      1, 2.68, 1.53, 0.70, 0.6, 0.6]],
                 [3,  [5.6, 1.8,  2.4,    1, 2.90, 1.76, 0.74, 0.8, 0.7]],
                 [3.5,[7,   2.1,  3.1,    2, 3.92, 1.95, 0.87, 1.0, 0.8]],
                 [4,  [8,   2.4 , 3.1,    2, 4.40, 2.45, 0.93, 1.2, 1.0]],
                 [5,  [9.5, 3,    3.8,    2, 4.90, 2.95, 1.00, 1.2, 1.2]],
                 [6,  [12,  3.6,  4.6,    3, 6.92, 3.81, 1.14, 1.6, 1.4]],
                 [8,  [16,  4.8,  6,      4, 9.02, 4.88, 1.69, 2.0, 1.9]],
                 [10, [20,  6.0,  7.5,    4, 10.18, 5.09, 1.84,2.5, 2.4]],
            ],
            type = head=="pan" ? (drive=="slot" ? "pan flat" : "pan round") : head,
            htind = drive=="slot" ? 1 : 2,
            entry = struct_val(metric_pan, diam),
            drive_size = drive=="phillips" ? [["drive_size", entry[3]], ["drive_diameter", entry[4]], ["drive_depth",entry[5]], ["drive_width",entry[6]]] :
                        drive=="slot" ? [["drive_width", entry[7]], ["drive_depth", entry[8]]] : []
           )
           concat([["head",type], ["head_size", entry[0]], ["head_height", entry[htind]]], drive_size) :
         head=="button" || head=="cheese" ? let(
            metric_button = [    // button, hex drive
                 //   head diam, height, hex, phillips, hex drive depth
                 [1.6, [2.9, 0.8,  0.9, undef, 0.55]], // These four cases,
                 [2,   [3.5, 1.3,  1.3, undef, 0.69]], // extrapolated hex depth
                 [2.2, [3.8, 0.9,  1.3, undef, 0.76]], //
                 [2.5, [4.6, 1.5,  1.5, undef, 0.87]], //
                 [3,   [5.7, 1.65, 2,   undef, 1.04, 8, 0.81]],
                 [3.5, [5.7, 1.65, 2,   undef, 1.21]], // interpolated hex depth
                 [4,   [7.6, 2.2,  2.5, undef, 1.30, 15, 1.3]],
                 [5,   [9.5, 2.75, 3,   undef, 1.56, 25, 1.56]],
                 [6,   [10.5,3.3,  4,   undef, 2.08, 27, 2.08]],
                 [8,   [14,  4.4,  5,   undef, 2.60, 40, 2.3]],
                 [10,  [17.5,5.5,  6,   undef, 3.21, 45, 2.69]],
                 [12,  [21,  6.6,  8,   undef, 4.16, 55, 4.02]],
                 [16,  [28,  8.8,  10,  undef, 5.55]], // interpolated hex depth
             ],
             metric_cheese = [   // slotted, phillips     ISO 1207, ISO 7048
                // head diam, head height, hex drive, phillips drive, slot width, slight depth, ph diam
                [1,   [2,  0.7, undef, undef]],
                [1.2, [2.3,0.8, undef, undef]],
                [1.4, [2.6,0.9, undef, undef]],
                [1.6, [3,  1,   undef, undef, 0.4, 0.45]],
                [2,   [3.8,1.3, undef, 1    , 0.5, 0.6]],
                [2.5, [4.5,1.6, undef, 1    , 0.6, 0.7,  2.7,1.2]],
                [3,   [5.5,2,   undef, 2    , 0.8, 0.85, 3.5,0.86]],
                [3.5, [6,  2.4, undef, 2    , 1.0, 1.0, 3.8, 1.15]],
                [4,   [7,  2.6, undef, 2    , 1.2, 1.1, 4.1, 1.45]],
                [5,   [8.5,3.3, undef, 2    , 1.2, 1.3, 4.8, 2.14]],
                [6,   [10, 3.9, undef, 3    , 1.6, 1.6, 6.2, 2.25]],
                [8,   [13, 5,   undef, 3    , 2.0, 2.0, 7.7, 3.73]],
                [10,  [16, 6,   undef, undef, 2.5, 2.4]]
             ],
             entry = struct_val(head=="button" ? metric_button : metric_cheese, diam),
             drive_index = drive=="phillips" ? 3 :
                           drive=="hex" ? 2 : undef,
             drive_dim = head=="button" && drive=="hex" ? [["drive_depth", entry[4]]] :
                         head=="button" && drive=="torx" ? [["drive_size", entry[5]],["drive_depth", entry[6]]] :
                         head=="cheese" && drive=="slot" ? [["drive_width", entry[4]], ["drive_depth", entry[5]]] :
                         head=="cheese" && drive=="phillips" ? [["drive_diameter", entry[6]], ["drive_depth", entry[7]],
                                                                ["drive_width", entry[6]/4]]:  // Fabricated this width value to fill in missing field
                         [],
             drive_size = is_def(drive_index) ? [["drive_size", entry[drive_index]]] : []
             )
             concat([["head",head],["head_size",entry[0]], ["head_height", entry[1]]],drive_size, drive_dim) :
         starts_with(head,"flat") ? let(
             small = head == "flat small" || (head=="flat" && (drive!="hex" && drive!="torx")),
             metric_flat_large = [ // for hex drive
                  [2,  [4,  1.3,undef]],
                  [2.5,[5,  1.5, undef]],
                  [3,  [6,  2  , 1.1, 10, 0.96]],
                  [4,  [8,  2.5, 1.5, 20, 1.34]],
                  [5,  [10, 3  , 1.9, 25, 1.54]],
                  [6,  [12, 4  , 2.2, 30, 1.91]],
                  [8,  [16, 5  , 3.0, 40, 2.3]],
                  [10, [20, 6  , 3.6, 50, 3.04]],
                  [12, [24, 8  ,undef]],
                  [14, [27, 10 ,undef]],
                  [16, [30, 10 ,undef]],
                  [18, [33, 12 ,undef]],
                  [20, [36, 12 ,undef]],
             ],
             metric_flat_small = [ // for phillips, slotted
                                   // Phillips from ASME B18.6.7M (ISO 7046 gives different values),
                                   // Slots from ISO 2009/DIN 963, which gives more values than ASME (and also inconsistent)
                        // diam, ph size, ph diam, ph depth, ph width, slot width, slot depth
                 [1.6, [1.9, 0,undef,undef,undef, 0.25, .2]],
                 [1.6, [2.3, 0,undef,undef,undef, 0.3, 0.25]],
                 [1.6, [2.6, 0,undef,undef,undef, 0.3, 0.28]],
                 [1.6, [3,   0,undef,undef,undef, 0.4, 0.32]],
                 [2,   [3.8, 0, 2.14, 1.54, 0.53, 0.5, 0.4]],
                 [2.5, [4.7, 1, 2.80, 1.78, 0.74, 0.6, 0.5]],
                 [2.6, [4.7, 1, 2.80, 1.78, 0.74, 0.6, 0.5]],
                 [3,   [5.6, 1, 3.10, 2.08, 0.79, 0.8, 0.6]],
                 [3.5, [6.5, 1, 4.06, 2.25, 0.91, 0.8, 0.7]],
                 [4,   [7.5, 2, 4.46, 2.65, 0.96, 1.0, 0.8]],
                 [5,   [9.2, 2, 5.06, 3.25, 1.04, 1.2, 1.0]],
                 [6,   [11,  3, 6.62, 3.61, 1.12, 1.6, 1.2]],
                 [8,   [14.5,4, 8.78, 4.88, 1.80, 2.0, 1.6]],
                 [10,  [18,undef,undef,undef,undef,2.5,2 ]],
                 [12,  [22,undef,undef,undef,undef,3,2.4 ]],
                 [14,  [25,undef,undef,undef,undef,3,2.8 ]],
                 [16,  [29,undef,undef,undef,undef,4,3.2 ]],
                 [18,  [33,undef,undef,undef,undef,4,3.6 ]],
                 [20,  [36,undef,undef,undef,undef,5,4 ]],
             ],
             entry = struct_val(small ? metric_flat_small : metric_flat_large, diam),
             driveind = small && drive=="phillips" || !small && drive=="hex" ? 1 : !small && drive=="torx" ? 3 : undef,
             drive_dim = small && drive=="phillips" ? [["drive_diameter", entry[2]], ["drive_depth",entry[3]], ["drive_width", entry[4]]] :
                         small && drive=="slot" ? [["drive_width", entry[5]], ["drive_depth", entry[6]]] :
                         !small && drive=="torx" ? [["drive_size", entry[3]],["drive_depth", entry[4]]] :
                         !small && drive=="hex" ? [["drive_depth", entry[2]]] : []
             )
             concat([["head","flat"],["head_angle",90],["head_size",entry[0]]],
                    is_def(driveind) ? [["drive_size", entry[driveind]]] : [],
                    drive_dim
                   ) : []
    )
    concat([["system","ISO"],["diameter",diam],["pitch", pitch],["drive",drive]],
            head_data
          );


// Module: screw_head()
// Usage:
//    screw_head(screw_info, [details])
// Description:
//    Draws the screw head described by the data structure `screw_info`, which
//    should have the fields produced by `screw_info()`.  See that function for
//    details on the fields.  Standard orientation is with the head centered at (0,0)
//    and oriented in the +z direction.  Flat heads appear below the xy plane.
//    Other heads appear sitting on the xy plane.
module screw_head(screw_info,details=false) {
   head = struct_val(screw_info, "head");
   head_size = struct_val(screw_info, "head_size");
   head_height = struct_val(screw_info, "head_height");
   if (head=="flat") {
     angle = struct_val(screw_info, "head_angle")/2;
     full_height = head_size/2/tan(angle);
     height = is_def(head_height) ? head_height : full_height;
     d2 = head_size*(1-height/full_height);
     //down(height)
     zflip()
       cyl(d1=head_size, d2=d2, l=height, anchor=BOTTOM);
   }
   if (in_list(head,["round","pan round","button","fillister","cheese"])) {
     base = head=="fillister" ? 0.75*head_height :
            head=="pan round" ? .6 * head_height :
            head=="cheese" ? .7 * head_height :
            0.1 * head_height;   // round and button
     head_size2 = head=="cheese" ?  head_size-2*tan(5)*head_height : head_size; // 5 deg slope on cheese head
     cyl(l=base, d1=head_size, d2=head_size2,anchor=BOTTOM, $fn=32)
       attach(TOP)
         rotate_extrude($fn=32)
           intersection(){
             arc(points=[[-head_size2/2,0], [0,-base+head_height * (head=="button"?4/3:1)], [head_size2/2,0]]);
             square([head_size2, head_height-base]);
             }
   }
   if (head=="pan flat")
     cyl(l=head_height, d=head_size, rounding2=0.2*head_size, anchor=BOTTOM);
   if (head=="socket")
     cyl(l=head_height, d=head_size, anchor=BOTTOM);
   if (head=="hex")
     intersection(){
       linear_extrude(height=head_height) hexagon(id=head_size);
       if (details)
         down(.01)cyl(l=head_height+.02,d=2*head_size/sqrt(3), chamfer=head_size*(1/sqrt(3)-1/2), anchor=BOTTOM);
     }
}


// Module: screw()
// Usage:
//   screw([name],[head],[thread],[drive],[drive_size], [length], [shank], [oversize], [tolerance], [$slop], [spec], [details], [anchor], [anchor_head], [orient], [spin])
// Description:
//   Create a screw.
//   .
//   Most of these parameters are described in the entry for `screw_info()`.
//   .
//   The tolerance determines the actual thread sizing based on the
//   nominal size.  For UTS threads it is either "1A", "2A" or "3A", in
//   order of increasing tightness.  The default tolerance is "2A", which
//   is the general standard for manufactured bolts.  For ISO the tolerance
//   has the form of a number and letter.  The letter specifies the "fundamental deviation", also called the "tolerance position", the gap
//   from the nominal size, and must be "e", "f", "g", or "h", where "e" is
//   the loosest and "h" means no gap.  The number specifies the allowed
//   range (variability) of the thread heights.  It must be a value from
//   3-9 for crest diameter and one of 4, 6, or 8 for pitch diameter.  A
//   tolerance "6g" specifies both pitch and crest diameter to be the same,
//   but they can be different, with a tolerance like "5g6g" specifies a pitch diameter tolerance of "5g" and a crest diameter tolerance of "6g".
//   Smaller numbers give a tighter tolerance.  The default ISO tolerance is "6g".
//   .
//   The $slop argument gives an extra gap to account for printing overextrusion. It defaults to 0.2.  
// Arguments:
//   name = screw specification, e.g. "M5x1" or "#8-32"
//   head = head type (see list above).  Default: none
//   thread = thread type or specification.  Default: "coarse"
//   drive = drive type.  Default: none
//   drive_size = size of drive recess to override computed value
//   oversize = amount to increase screw diameter for clearance holes.  Default: 0
//   spec = screw specification from `screw_info()`.  If you specify this you can omit all the preceeding parameters.
//   length = length of screw (in mm)
//   shank = length of unthreaded portion of screw (in mm).  Default: 0
//   details = toggle some details in rendering.  Default: false
//   tolerance = screw tolerance.  Determines actual screw thread geometry based on nominal sizing.  Default is "2A" for UTS and "6g" for ISO.
//   $slop = add extra gap to account for printer overextrusion.  Default: 0.2
//   anchor = anchor relative to the shaft of the screw
//   anchor_head = anchor relative to the screw head
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
//     screw("M5", head="hex", length=12);
//   }
// Example(Med): Demonstration of all head types for UTS screws (using pitch zero for fast preview)
//   xdistribute(spacing=15){
//     ydistribute(spacing=15){
//        screw("1/4", thread=0,length=8, anchor=TOP, head="none", drive="hex");
//        screw("1/4", thread=0,length=8, anchor=TOP, head="none", drive="torx");
//        screw("1/4", thread=0,length=8, anchor=TOP, head="none");
//     }
//     screw("1/4", thread=0, length=8, anchor=TOP, head="hex");
//     ydistribute(spacing=15){
//        screw("1/4", thread=0,length=8, anchor=TOP, head="socket", drive="hex");
//        screw("1/4", thread=0,length=8, anchor=TOP, head="socket", drive="torx");
//        screw("1/4", thread=0,length=8, anchor=TOP, head="socket");
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
//   }
// Example(Med): Demonstration of all head types for metric screws without threading.
//   xdistribute(spacing=15){
//     ydistribute(spacing=15){
//       screw("M6x0", length=8, anchor=TOP,  head="none", drive="hex");
//       screw("M6x0", length=8, anchor=TOP,  head="none", drive="torx");
//       screw("M6x0", length=8, anchor=TOP);
//     }
//     screw("M6x0", length=8, anchor=TOP,  head="hex");
//     ydistribute(spacing=15){
//       screw("M6x0", length=8, anchor=TOP,  head="socket", drive="hex");
//       screw("M6x0", length=8, anchor=TOP,  head="socket", drive="torx");
//       screw("M6x0", length=8, anchor=TOP,  head="socket");
//     }
//     ydistribute(spacing=15){
//       screw("M6x0", length=8, anchor=TOP,  head="pan", drive="slot");
//       screw("M6x0", length=8, anchor=TOP,  head="pan", drive="phillips");
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
// Example: The three different English (UTS) screw tolerances
//   module label(val)
//   {
//     difference(){
//        children();
//        yflip()linear_extrude(height=.35) text(val,valign="center",halign="center",size=8);
//     }
//   }
//   $fn=64;
//   xdistribute(spacing=15){
//     label("1") screw("1/4-20,5/8", head="hex",orient=DOWN,anchor_head=TOP,tolerance="1A");  // Loose
//     label("2") screw("1/4-20,5/8", head="hex",orient=DOWN,anchor_head=TOP,tolerance="2A");  // Standard
//     label("3") screw("1/4-20,5/8", head="hex",orient=DOWN,anchor_head=TOP,tolerance="3A");  // Tight
//   }
// Example(2D): This example shows the gap between nut and bolt at the loosest tolerance for UTS.  This gap is what enables the parts to mesh without binding and is part of the definition for standard metal hardware.
//   $slop=0;
//   $fn=32;
//   inch=25.4;
//   projection(cut=true)xrot(-90){
//       screw("1/4-20,1/4", head="hex",orient=UP,anchor=BOTTOM,tolerance="1A");
//       down(inch*1/20*2.58) nut("1/4-20", thickness=8, diameter=0.5*inch,tolerance="1B");
//   }

module screw(name, head, thread="coarse", drive, drive_size, oversize=0, spec, length, shank=0, tolerance=undef, details=true, anchor=undef,anchor_head=undef,spin=0, orient=UP)
{
   spec = _validate_screw_spec(
                               is_def(spec) ? spec : screw_info(name, head, thread, drive, drive_size, oversize) );
   struct_echo(spec,"spec");
   head = struct_val(spec,"head");
   pitch = struct_val(spec, "pitch");
   diameter = struct_val(spec, "diameter");
   headless = head=="none" || head==undef;
   eps = headless || starts_with(head,"flat") ? 0 : 0.01;
   length = first_defined([length,struct_val(spec,"length")]) + eps;
   assert(length>0, "Must specify positive length");
   sides = max(12, segs(diameter/2));
   unthreaded = is_undef(pitch) || pitch==0 ? length : shank;
   threaded = length - unthreaded;
   echo(t=threaded,length,unthreaded);
   head_height = headless || starts_with(head, "flat") ? 0 : struct_val(spec, "head_height");
   head_diam = struct_val(spec, "head_size");
   head_size = headless ? [diameter, diameter, head_height] :
               head == "hex" ? [head_diam, head_diam*2/sqrt(3), head_height] :
                               [head_diam, head_diam, head_height];
   assert(num_defined([anchor,anchor_head])<=1, "Cannot define both `anchor` and `anchor_head`");
   head_anchor = is_def(anchor_head);
   attachable(
     d = head_anchor ? head_size[0] : diameter,  // This code should be tweaked to pass diameter and length more cleanly
     l = head_anchor ? head_size[2] : length,
     orient = orient,
     anchor = first_defined([anchor, anchor_head, BOTTOM]),
     //offset = head_anchor ? [0,0,head_height/2] : [0,0,-length/2],
     spin = spin
     )
   {
     up(head_anchor ? -head_height/2 : length/2)
       difference(){
         union(){
           screw_head(spec,details);
           up(eps){
             if (unthreaded>0){
                cyl(d=diameter, h=unthreaded+eps+(threaded>0?0.01:0), anchor=TOP, $fn=sides);
               }
             if (threaded>0)
               intersection(){
                 down(unthreaded)
                   _rod(spec, length=threaded+eps, tolerance=tolerance, $fn=sides, anchor=TOP );
                 if (details)
                   up(.01)cyl(d=diameter, l=length+.02+eps, chamfer1 = pitch/2, chamfer2 = headless ? pitch/2 : -pitch/2, anchor=TOP, $fn=sides);
              }
           }
         }
         _driver(spec);
       }
     children();
   }
}


module _driver(spec)
{
  drive = struct_val(spec,"drive");
  echo(drive=drive);
  if (is_def(drive) && drive!="none") {
    echo(inside_drive=drive);
    head = struct_val(spec,"head");
    diameter = struct_val(spec,"diameter");
    drive_size = struct_val(spec,"drive_size");
    drive_width = struct_val(spec,"drive_width");
    drive_diameter = struct_val(spec, "drive_diameter");
    drive_depth = first_defined([struct_val(spec, "drive_depth"), .7*diameter]); // Note hack for unspecified depth
    head_top = starts_with(head,"flat") || head=="none" ? 0 :
               struct_val(spec,"head_height");
               echo(drive_size=drive_size);
    up(head_top-drive_depth){
      // recess should be positioned with its bottom center at (0,0) and the correct recess depth given above
      if (drive=="phillips") phillips_drive(size=str("#",drive_size), shaft=diameter,anchor=BOTTOM);
      if (drive=="torx") torx_drive(size=drive_size, l=drive_depth+1, center=false);
      if (drive=="hex") linear_extrude(height=drive_depth+1) hexagon(id=drive_size);
      if (drive=="slot") cuboid([2*struct_val(spec,"head_size"), drive_width, drive_depth+1],anchor=BOTTOM);
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
  assert(internalok,str("Invalid internal thread tolerance, ",tolerance,".  Must have form <digit><letter>"))
  assert(externalok,str("invalid external thread tolerance, ",tolerance,".  Must have form <digit><letter> or <digit><letter><digit><letter>"))
  let(
    tol_num_pitch = str_num(tol_str[0]),
    tol_num_crest = str_num(tol_str[2]),
    tol_letter = tol_str[1]
  )
  assert(tol_letter==tol_str[3],str("Invalid tolerance, ",tolerance,".  Cannot mix different letters"))
  internal ?
    let(  // Nut case
      //a=echo("nut", tol_letter, tol_num_pitch, tol_num_crest),
      fdev = struct_val(EI,tol_letter)/1000,
      Tdval = struct_val(T_D1, tol_num_crest)/1000,
      df=     echo(T_D1=T_D1),
      Td2val = struct_val(T_D2, tol_num_pitch)/1000,
      //fe=   echo("nut",P,fdev=fdev, Tdval=Tdval, Td2val=Td2val),
      bot=[diameter+fdev, diameter+fdev+Td2val+H/6],
      xdiam = [mindiam+fdev,mindiam+fdev+Tdval],
      pitchdiam = [pdiam + fdev, pdiam+fdev+Td2val]
    )
    [["pitch",P],["d_minor",xdiam], ["d_pitch",pitchdiam], ["d_major",bot],["basic",[mindiam,pdiam,diameter]]]
  :
    let( // Bolt case
      //a=echo("bolt"),
      fdev = struct_val(es,tol_letter)/1000,
      Tdval = struct_val(T_d, tol_num_crest)/1000,
      Td2val = struct_val(T_d2, tol_num_pitch)/1000,
      mintrunc = P/8,
      d1 = diameter-5*H/4,
      maxtrunc = H/4 - mintrunc * (1-cos(60-acos(1-Td2val/4/mintrunc)))+Td2val/2,
      //cc=echo("bolt",P,fdev=fdev, Tdval=Tdval, Td2val=Td2val),
      bot = [diameter-2*H+2*mintrunc+fdev, diameter-2*H+2*maxtrunc+fdev],
      xdiam = [diameter+fdev,diameter+fdev-Tdval],
      pitchdiam = [pdiam + fdev, pdiam+fdev-Td2val]
    )
    [["pitch",P],["d_major",xdiam], ["d_pitch",pitchdiam], ["d_minor",bot],["basic",[mindiam,pdiam,diameter]]];

function _UTS_thread_tolerance(diam, pitch, internal=false, tolerance=undef) =
  let(
    inch = 25.4,
    d = diam/inch,   // diameter in inches
    P = pitch/inch,  // pitch in inches
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
     //f=echo(allowance=allowance),
     //g=echo(pta2 = pitchtol_2A),
     // ff=echo(minortol=minortol, pitchtol=pitchtol, majortol=majortol),
     basic_minordiam = d - 5/4*H,
     basic_pitchdiam = d - 3/4*H,
     majordiam = internal ? [d,d] :          // A little confused here, paragraph 8.3.2
                          [d-allowance-majortol, d-allowance],
     //ffda=echo(allowance=allowance, majortol=majortol, "*****************************"),
     pitchdiam = internal ? [basic_pitchdiam, basic_pitchdiam + pitchtol]
                          : [majordiam[1] - 3/4*H-pitchtol, majordiam[1]-3/4*H],
     minordiam = internal ? [basic_minordiam, basic_minordiam + minortol]
                          : [pitchdiam[0] - 3/4*H, basic_minordiam - allowance - H/8]   // the -H/8 is for the UNR case, 0 for UN case
    )
    [["pitch",P*inch],["d_major",majordiam*inch], ["d_pitch", pitchdiam*inch], ["d_minor",minordiam*inch],
     ["basic", inch*[basic_minordiam, basic_pitchdiam, d]]];

function _exact_thread_tolerance(d,P) =
   let(
       H = P*sqrt(3)/2,
       basic_minordiam = d - 5/4*H,
       basic_pitchdiam = d - 3/4*H
      )
    [["pitch", P], ["d_major", d], ["d_pitch", basic_pitchdiam], ["d_minor", basic_minordiam],
     ["basic", [basic_minordiam, basic_pitchdiam, d]]];


// Function: thread_specification()
// Usage:
//   thread_specification(screw_spec, [tolerance], [internal])
// Description:
//   Determines actual thread geometry for a given screw with specified tolerance.  If tolerance is omitted the default is used.  If tolerance
//   is "none" or 0 then return the nominal thread geometry.
//   .
//   The return value is a structure with the following fields:
//   - pitch: the thread pitch
//   - d_major: major diameter range
//   - d_pitch: pitch diameter range
//   - d_minor: minor diameter range
//   - basic: vector `[minor, pitch, major]` of the nominal or "basic" diameters for the threads
function thread_specification(screw_spec, internal=false, tolerance=undef) =
  let( diam = struct_val(screw_spec, "diameter"),
       pitch = struct_val(screw_spec, "pitch")
     ,k=
  tolerance == 0 || tolerance=="none" ? _exact_thread_tolerance(diam, pitch) :
  struct_val(screw_spec,"system") == "ISO" ? _ISO_thread_tolerance(diam, pitch, internal, tolerance) :
  struct_val(screw_spec,"system") == "UTS" ? _UTS_thread_tolerance(diam, pitch, internal, tolerance) :
  assert(false,"Unknown screw system ",struct_val(screw_spec,"system")),
    fff=echo(k))
    k;


function _thread_profile(thread) =
  let(
     pitch = struct_val(thread,"pitch"),
     basicrad = struct_val(thread,"basic")/2,
     meanpitchrad = mean(struct_val(thread,"d_pitch"))/2,
     meanminorrad = mean(struct_val(thread,"d_minor"))/2,
     meanmajorrad = mean(struct_val(thread,"d_major"))/2,
     depth = (meanmajorrad-meanminorrad)/pitch,
     crestwidth = (pitch/2 - 2*(meanmajorrad-meanpitchrad)/sqrt(3))/pitch

  )
    [
     [-1/2,-depth],
     [depth/sqrt(3)-1/2,0],
     [depth/sqrt(3)+crestwidth-1/2, 0],
     [crestwidth + 2*depth/sqrt(3)-1/2,-depth]
    ];

function _thread_profile_e(thread) =
  let(
     pitch = struct_val(thread,"pitch"),
     basicrad = struct_val(thread,"basic")/2,
     meanpitchrad = mean(struct_val(thread,"d_pitch"))/2,
     meanminorrad = mean(struct_val(thread,"d_minor"))/2,
     meanmajorrad = mean(struct_val(thread,"d_major"))/2,
     depth = (meanmajorrad-meanminorrad)/pitch,
     crestwidth = (pitch/2 - 2*(meanmajorrad-meanpitchrad)/sqrt(3))/pitch

  )
    [
     [-1/2,-1],  // -1 instead of -depth?
     [depth/sqrt(3)-1/2,0],
     [depth/sqrt(3)+crestwidth-1/2, 0],
     [crestwidth + 2*depth/sqrt(3)-1/2,-1]
    ];


module _rod(spec, length, tolerance, orient=UP, spin=0, anchor=CENTER)
{
      threadspec = thread_specification(spec, internal=false, tolerance=tolerance);
      echo(d_major_mean = mean(struct_val(threadspec, "d_major")));
      echo(bolt_profile=_thread_profile(threadspec));

      trapezoidal_threaded_rod( d=mean(struct_val(threadspec, "d_major")),
                                l=length,
                                pitch = struct_val(threadspec, "pitch"),
                                profile = _thread_profile(threadspec),left_handed=false,
                                bevel=false, orient=orient, anchor=anchor, spin=spin);
}


// Module: nut()
// Usage:
//   nut([name],diameter, thickness,[thread],[oversize],[spec],[tolerance],[details],[$slop])
// Description:
//   Generates a hexagonal nut.  
//   The name, thread and oversize parameters are described under `screw_info()`.  As for screws,
//   you can give the specification in `spec` and then omit the name.  The diameter is the flat-to-flat
//   size of the nut produced.  
//   .
//   The tolerance determines the actual thread sizing based on the
//   nominal size.  
//   For UTS threads the tolerance is either "1B", "2B" or "3B", in
//   order of increasing tightness.  The default tolerance is "2B", which
//   is the general standard for manufactured nuts.  For ISO the tolerance
//   has the form of a number and letter.  The letter specifies the "fundamental deviation", also called the "tolerance position", the gap
//   from the nominal size, and must be "G", or "H", where "G" is looser
//   he loosest and "H" means no gap.  The number specifies the allowed
//   range (variability) of the thread heights.  Smaller  numbers give tigher tolerances.  It must be a value from
//   4-8, so an allowed (loose) tolerance is "7G".  The default ISO tolerance is "6H".
//   .
//   The $slop parameter determines extra gaps left to account for printing overextrusion.  It defaults to 0.2.
// Arguments:
//   name = screw specification, e.g. "M5x1" or "#8-32"
//   diameter = outside diameter of nut (flat to flat dimension)
//   thickness = thickness of nut (in mm)
//   ---
//   thread = thread type or specification.  Default: "coarse"
//   oversize = amount to increase screw diameter for clearance holes.  Default: 0
//   spec = screw specification from `screw_info()`.  If you specify this you can omit all the preceeding parameters.
//   details = toggle some details in rendering.  Default: false
//   tolerance = nut tolerance.  Determines actual nut thread geometry based on nominal sizing.  Default is "2B" for UTS and "6H" for ISO.
//   $slop = extra space left to account for printing over-extrusion.  Default: 0.2
// Example: A metric and UTS nut
//   inch=25.4;
//   nut("3/8", 5/8*inch, 1/4*inch);
//   right(25)
//      nut("M8", 16, 6);
// Example: The three different UTS nut tolerances
//   inch=25.4;
//   module mark(number)
//   {
//     difference(){
//        children();
//        ycopies(n=number, spacing=1.5)right(.25*inch-2)up(8-.35)cyl(d=1, h=1);
//     }
//   }
//   $fn=64;
//   xdistribute(spacing=17){
//     mark(1) nut("1/4-20", thickness=8, diameter=0.5*inch,tolerance="1B");
//     mark(2) nut("1/4-20", thickness=8, diameter=0.5*inch,tolerance="2B");
//     mark(3) nut("1/4-20", thickness=8, diameter=0.5*inch,tolerance="3B");
//   }
module nut(name, diameter, thickness, thread="coarse", oversize=0, spec, tolerance=undef,
           details=true, anchor=BOTTOM,spin=0, orient=UP)
{
   assert(is_num(diameter) && diameter>0);
   assert(is_num(thickness) && thickness>0);
   spec = is_def(spec) ? spec : screw_info(name, thread=thread, oversize=oversize);
   threadspec = thread_specification(spec, internal=true, tolerance=tolerance);
   echo(threadspec=threadspec,"for nut threads");
   echo(nut_minor_diam = mean(struct_val(threadspec,"d_minor")));
   trapezoidal_threaded_nut(
        od=diameter, id=mean(struct_val(threadspec, "d_major")), h=thickness,
        pitch=struct_val(threadspec, "pitch"),
        profile=_thread_profile(threadspec),
        bevel=false,anchor=anchor,spin=spin,orient=orient);
}


function _is_positive(x) = is_num(x) && x>0;

function _validate_screw_spec(spec) = let(
    f=struct_echo(spec),
    systemOK = in_list(struct_val(spec,"system"), ["UTS","ISO"]),
    diamOK = _is_positive(struct_val(spec, "diameter")),
    pitch = struct_val(spec,"pitch"),
    pitchOK = is_undef(pitch) || (is_num(pitch) && pitch>=0),
    head = struct_val(spec,"head"),
    headOK = is_undef(head) || head=="none" || (
                 in_list(head, ["cheese","pan flat","pan round", "flat","flat large", "flat small", "flat undercut", "button","socket","fillister","round","hex"]) &&
                 _is_positive(struct_val(spec, "head_size"))),
    drive = struct_val(spec, "drive"),
    driveOK = is_undef(drive) || drive=="none"
              || (
                  _is_positive(struct_val(spec, "drive_depth")) &&
                    (
                      in_list(drive, ["torx","hex"])
                        || (drive=="phillips" && _is_positive(struct_val(spec, "drive_diameter")) &&
                                                 _is_positive(struct_val(spec, "drive_width")) &&
                                                 _is_positive(struct_val(spec, "drive_width")))
                        || (drive=="slot" && _is_positive(struct_val(spec, "drive_width")))
                    )
                  )
    )
    assert(systemOK, str("Screw spec has invalid \"system\", ", struct_val(spec,"system"), ".  Must be \"ISO\" or \"UTS\""))
    assert(diamOK, str("Screw spec has invalid \"diameter\", ", struct_val(spec,"diameter")))
    assert(pitchOK, str("Screw spec has invalid \"pitch\", ", pitch))
    assert(headOK, "Screw spec head type invalid or unknown for your screw size")
    assert(driveOK, "Screw drive type invalid or unknown for your screw size or head type")
    spec;



// recess sizing:
// http://www.fasnetdirect.com/refguide/Machinepancombo.pdf
//
/*   ASME B 18.6.3
http://www.smithfast.com/newproducts/screws/msflathead/


/* phillips recess diagram

http://files.engineering.com/getfile.aspx?folder=76fb0d5e-1fff-4c49-87a5-05979477ca88&file=Noname.jpg&__hstc=212727627.6c577ef84c12d9cc69c819eea7be49d2.1563972499721.1563972499721.1563972499721.1&__hssc=212727627.1.1563972499721&__hsfp=165344926

*/


// To do list
//
// Metric hex engagement:
// https://www.bayoucitybolt.com/socket-head-cap-screws-metric.html
//
// Torx drive depth for UTS and ISO (at least missing for "flat small", which means you can't select torx for this head type)
// Handle generic phillips (e.g. ph2) or remove it?
//
// How do you insert a threaded hole into a model?
// Default nut thickness
//

// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
