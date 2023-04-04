//////////////////////////////////////////////////////////////////////
// LibFile: ball_bearings.scad
//   Models for standard ball bearing cartridges.
// Includes:
//   include <BOSL2/std.scad>
//   include <BOSL2/ball_bearings.scad>
// FileGroup: Parts
// FileSummary: Models for standard ball bearing cartridges.
//////////////////////////////////////////////////////////////////////



// Section: Ball Bearing Models

// Module: ball_bearing()
// Synopsis: Creates a standardized ball bearing assembly.
// Topics: Parts, Bearings
// See Also: linear_bearing(), lmXuu_bearing(), lmXuu_housing()
// Description:
//   Creates a model of a ball bearing assembly.
// Arguments:
//   trade_size = String name of a standard ball bearing trade size.  ie: "608", "6902ZZ", or "R8"
//   id = Inner diameter of ball bearing assembly.
//   od = Outer diameter of ball bearing assembly.
//   width = Width of ball bearing assembly.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Example:
//   ball_bearing("608");
// Example:
//   ball_bearing("608ZZ");
// Example:
//   ball_bearing("R8");
// Example:
//   ball_bearing(id=12,od=32,width=10,shield=false);
module ball_bearing(trade_size, id, od, width, shield=true, anchor=CTR, spin=0, orient=UP) {
    info = is_undef(trade_size)? [id, od, width, shield] :
        ball_bearing_info(trade_size);
    check = assert(all_defined(info), "Bad Input");
    id = info[0];
    od = info[1];
    width = info[2];
    shield = info[3];
    mid_d = (id+od)/2;
    wall = (od-id)/2/3;
    color("silver")
    attachable(anchor,spin,orient, d=od, l=width) {
        if (shield) {
            tube(id=id, wall=wall, h=width);
            tube(od=od, wall=wall, h=width);
            tube(id=id+0.1, od=od-0.1, h=(wall*2+width)/2);
        } else {
            ball_cnt = floor(PI*mid_d*0.95 / (wall*2));
            difference() {
                union() {
                    tube(id=id, wall=wall, h=width);
                    tube(od=od, wall=wall, h=width);
                }
                torus(r_maj=mid_d/2, r_min=wall);
            }
            for (i=[0:1:ball_cnt-1]) {
                zrot(i*360/ball_cnt) right(mid_d/2) sphere(d=wall*2);
            }
        }
        children();
    }
}



// Section: Ball Bearing Info


// Function: ball_bearing_info()
// Synopsis: Creates a standardized ball bearing assembly.
// Topics: Parts, Bearings
// See Also: ball_bearing(), linear_bearing(), lmXuu_info()
// Description:
//   Get dimensional info for a standard metric ball bearing cartridge.
//   Returns `[SHAFT_DIAM, OUTER_DIAM, WIDTH, SHIELDED]` for the cylindrical cartridge.
// Arguments:
//   size = Inner diameter of lmXuu bearing, in mm.
function ball_bearing_info(trade_size) =
    assert(is_string(trade_size))
    let(
        IN = 25.4,
        data = [
            // trade_size, ID,     OD,      width,  shielded
            [      "R2",  1/8*IN,  3/8*IN,  5/32*IN, false],
            [      "R3", 3/16*IN,  1/2*IN,  5/32*IN, false],
            [      "R4",  1/4*IN,  5/8*IN, 0.196*IN, false],
            [      "R6",  3/8*IN,  7/8*IN,  7/32*IN, false],
            [      "R8",  1/2*IN,  9/8*IN,   1/4*IN, false],
            [     "R10",  5/8*IN, 11/8*IN,  9/32*IN, false],
            [     "R12",  3/4*IN, 13/8*IN,  5/16*IN, false],
            [     "R14",  7/8*IN, 15/8*IN,   3/8*IN, false],
            [     "R16",  8/8*IN, 16/8*IN,   3/8*IN, false],
            [     "R18",  9/8*IN, 17/8*IN,   3/8*IN, false],
            [     "R20", 10/8*IN, 18/8*IN,   3/8*IN, false],
            [     "R22", 11/8*IN, 20/8*IN,  7/16*IN, false],
            [     "R24", 12/8*IN, 21/8*IN,  7/16*IN, false],

            [    "R2ZZ",  1/8*IN,  3/8*IN,  5/32*IN, true ],
            [    "R3ZZ", 3/16*IN,  1/2*IN,  5/32*IN, true ],
            [    "R4ZZ",  1/4*IN,  5/8*IN, 0.196*IN, true ],
            [    "R6ZZ",  3/8*IN,  7/8*IN,  7/32*IN, true ],
            [    "R8ZZ",  1/2*IN,  9/8*IN,   1/4*IN, true ],
            [   "R10ZZ",  5/8*IN, 11/8*IN,  9/32*IN, true ],
            [   "R12ZZ",  3/4*IN, 13/8*IN,  5/16*IN, true ],
            [   "R14ZZ",  7/8*IN, 15/8*IN,   3/8*IN, true ],
            [   "R16ZZ",  8/8*IN, 16/8*IN,   3/8*IN, true ],
            [   "R18ZZ",  9/8*IN, 17/8*IN,   3/8*IN, true ],
            [   "R20ZZ", 10/8*IN, 18/8*IN,   3/8*IN, true ],
            [   "R22ZZ", 11/8*IN, 20/8*IN,  7/16*IN, true ],
            [   "R24ZZ", 12/8*IN, 21/8*IN,  7/16*IN, true ],

            [     "608",   8,  22,   7, false],
            [     "629",   9,  26,   8, false],
            [     "635",   5,  19,   6, false],
            [    "6000",  10,  26,   8, false],
            [    "6001",  12,  28,   8, false],
            [    "6002",  15,  32,   9, false],
            [    "6003",  17,  35,  10, false],
            [    "6007",  35,  62,  14, false],
            [    "6200",  10,  30,   9, false],
            [    "6201",  12,  32,  10, false],
            [    "6202",  15,  35,  11, false],
            [    "6203",  17,  40,  12, false],
            [    "6204",  20,  47,  14, false],
            [    "6205",  25,  52,  15, false],
            [    "6206",  30,  62,  16, false],
            [    "6207",  35,  72,  17, false],
            [    "6208",  40,  80,  18, false],
            [    "6209",  45,  85,  19, false],
            [    "6210",  50,  90,  20, false],
            [    "6211",  55, 100,  21, false],
            [    "6212",  60, 110,  22, false],
            [    "6301",  12,  37,  12, false],
            [    "6302",  15,  42,  13, false],
            [    "6303",  17,  47,  14, false],
            [    "6304",  20,  52,  15, false],
            [    "6305",  25,  62,  17, false],
            [    "6306",  30,  72,  19, false],
            [    "6307",  35,  80,  21, false],
            [    "6308",  40,  90,  23, false],
            [    "6309",  45, 100,  25, false],
            [    "6310",  50, 110,  27, false],
            [    "6311",  55, 120,  29, false],
            [    "6312",  60, 130,  31, false],
            [    "6403",  17,  62,  17, false],
            [    "6800",  10,  19,   5, false],
            [    "6801",  12,  21,   5, false],
            [    "6802",  15,  24,   5, false],
            [    "6803",  17,  26,   5, false],
            [    "6804",  20,  32,   7, false],
            [    "6805",  25,  37,   7, false],
            [    "6806",  30,  42,   7, false],
            [    "6900",  10,  22,   6, false],
            [    "6901",  12,  24,   6, false],
            [    "6902",  15,  28,   7, false],
            [    "6903",  17,  30,   7, false],
            [    "6904",  20,  37,   9, false],
            [    "6905",  25,  42,   9, false],
            [    "6906",  30,  47,   9, false],
            [    "6907",  35,  55,  10, false],
            [    "6908",  40,  62,  12, false],
            [   "16002",  15,  22,   8, false],
            [   "16004",  20,  42,   8, false],
            [   "16005",  25,  47,   8, false],
            [   "16100",  10,  28,   8, false],
            [   "16101",  12,  30,   8, false],

            [   "608ZZ",   8,  22,   7, true ],
            [   "629ZZ",   9,  26,   8, true ],
            [   "635ZZ",   5,  19,   6, true ],
            [  "6000ZZ",  10,  26,   8, true ],
            [  "6001ZZ",  12,  28,   8, true ],
            [  "6002ZZ",  15,  32,   9, true ],
            [  "6003ZZ",  17,  35,  10, true ],
            [  "6007ZZ",  35,  62,  14, true ],
            [  "6200ZZ",  10,  30,   9, true ],
            [  "6201ZZ",  12,  32,  10, true ],
            [  "6202ZZ",  15,  35,  11, true ],
            [  "6203ZZ",  17,  40,  12, true ],
            [  "6204ZZ",  20,  47,  14, true ],
            [  "6205ZZ",  25,  52,  15, true ],
            [  "6206ZZ",  30,  62,  16, true ],
            [  "6207ZZ",  35,  72,  17, true ],
            [  "6208ZZ",  40,  80,  18, true ],
            [  "6209ZZ",  45,  85,  19, true ],
            [  "6210ZZ",  50,  90,  20, true ],
            [  "6211ZZ",  55, 100,  21, true ],
            [  "6212ZZ",  60, 110,  22, true ],
            [  "6301ZZ",  12,  37,  12, true ],
            [  "6302ZZ",  15,  42,  13, true ],
            [  "6303ZZ",  17,  47,  14, true ],
            [  "6304ZZ",  20,  52,  15, true ],
            [  "6305ZZ",  25,  62,  17, true ],
            [  "6306ZZ",  30,  72,  19, true ],
            [  "6307ZZ",  35,  80,  21, true ],
            [  "6308ZZ",  40,  90,  23, true ],
            [  "6309ZZ",  45, 100,  25, true ],
            [  "6310ZZ",  50, 110,  27, true ],
            [  "6311ZZ",  55, 120,  29, true ],
            [  "6312ZZ",  60, 130,  31, true ],
            [  "6403ZZ",  17,  62,  17, true ],
            [  "6800ZZ",  10,  19,   5, true ],
            [  "6801ZZ",  12,  21,   5, true ],
            [  "6802ZZ",  15,  24,   5, true ],
            [  "6803ZZ",  17,  26,   5, true ],
            [  "6804ZZ",  20,  32,   7, true ],
            [  "6805ZZ",  25,  37,   7, true ],
            [  "6806ZZ",  30,  42,   7, true ],
            [  "6900ZZ",  10,  22,   6, true ],
            [  "6901ZZ",  12,  24,   6, true ],
            [  "6902ZZ",  15,  28,   7, true ],
            [  "6903ZZ",  17,  30,   7, true ],
            [  "6904ZZ",  20,  37,   9, true ],
            [  "6905ZZ",  25,  42,   9, true ],
            [  "6906ZZ",  30,  47,   9, true ],
            [  "6907ZZ",  35,  55,  10, true ],
            [  "6908ZZ",  40,  62,  12, true ],
            [ "16002ZZ",  15,  22,   8, true ],
            [ "16004ZZ",  20,  42,   8, true ],
            [ "16005ZZ",  25,  47,   8, true ],
            [ "16100ZZ",  10,  28,   8, true ],
            [ "16101ZZ",  12,  30,   8, true ],
        ],
        found = search([trade_size], data, 1)[0]
    )
    assert(found!=[], str("Unsupported ball bearing trade size: ", trade_size))
    select(data[found], 1, -1);



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
