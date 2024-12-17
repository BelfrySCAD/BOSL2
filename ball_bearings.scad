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
// SynTags: Geom
// Topics: Parts, Bearings
// See Also: linear_bearing(), lmXuu_bearing(), lmXuu_housing()
// Description:
//   Creates a model of a ball bearing assembly.
// Arguments:
//   trade_size = String name of a standard ball bearing trade size.  ie: "608", "6902ZZ", or "R8"
//   id = Inner diameter of ball bearing assembly.
//   od = Outer diameter of ball bearing assembly.
//   width = Width of ball bearing assembly.
//   shield = If true, the ball bearing assembly has a shield.
//   flange = If true, the ball bearing assembly has a flange.
//   fd = Diameter of the flange (required if `flange=true`).
//   fw = Width of the flange (required if `flange=true`).
//   rounding = Edge rounding radius, if any. The outermost top and bottom edges are rounded by this amount. The edges of the inner hole are also rounded. If you set `trade_size` and you want edges rounded, you must set `rounding` yourself. This parameter has no default value because the rounding depends on manufacturer and bearing size.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Example:
//   ball_bearing("608", $fn=72);
// Example:
//   ball_bearing("608ZZ", $fn=72);
// Example:
//   ball_bearing("R8", $fn=72);
// Example:
//   ball_bearing(id=12,od=32,width=10,shield=false, $fn=72);
// Example:
//   ball_bearing("MF105ZZ", $fn=72);
// Example:
//   ball_bearing("F688ZZ", $fn=72);
// Example: With flange, shield, and rounded edges.
//   ball_bearing(id=12,od=24,width=6,shield=true, flange=true, fd=26.5, fw=1.5, rounding=0.6, $fn=72);
module ball_bearing(trade_size, id, od, width, shield=true, flange=false, fd, fw, rounding, anchor=CTR, spin=0, orient=UP) {
    info = is_undef(trade_size)? [id, od, width, shield, flange, fd, fw] :
        ball_bearing_info(trade_size);
    check = assert(all_defined(select(info, 0,4)), "Bad Input");
    if(flange){
        assert(!is_undef(fd), "If flange is set you must specify its diameter");
        assert(!is_undef(fw), "If flange is set you must specify its width");
    }
    id = info[0];
    od = info[1];
    width = info[2];
    shield = info[3];
    flange = info[4];
    fd = info[5];
    fw = info[6];
    mid_d = (id+od)/2;
    wall = (od-id)/2/3;
    color("silver")
    attachable(anchor,spin,orient, d=od, l=width) {
        if (shield) {
            tube(id=id, wall=wall, h=width, irounding=rounding);
            tube(od=od, wall=wall, h=width, orounding1=flange?undef:rounding, orounding2=rounding);
            tube(id=id+0.1, od=od-0.1, h=(wall*2+width)/2);
            if (flange){
                translate([0,0,-width/2+fw/2])tube(id=od, od=fd, h=fw, orounding1=rounding);
            }
        } else {
            ball_cnt = floor(PI*mid_d*0.95 / (wall*2));
            difference() {
                union() {
                    tube(id=id, wall=wall, h=width, irounding=rounding);
                    tube(od=od, wall=wall, h=width, orounding1=flange?undef:rounding, orounding2=rounding);
                }
                torus(r_maj=mid_d/2, r_min=wall);
            }
            for (i=[0:1:ball_cnt-1]) {
                zrot(i*360/ball_cnt) right(mid_d/2) sphere(d=wall*2);
            }
            if (flange){
                translate([0,0,-width/2+fw/2])tube(id=od, od=fd, h=fw, orounding1=rounding);
            }
        }
        children();
    }
}



// Section: Ball Bearing Info


// Function: ball_bearing_info()
// Synopsis: Returns size info for a standardized ball bearing assembly.
// Topics: Parts, Bearings
// See Also: ball_bearing(), linear_bearing(), lmXuu_info()
// Description:
//   Get dimensional info for a standard metric ball bearing cartridge.
//   Returns `[SHAFT_DIAM, OUTER_DIAM, WIDTH, SHIELDED, FLANGED, FLANGE_DIAM, FLANGE_WIDTH]` for the cylindrical cartridge.
// Arguments:
//   size = Inner diameter of lmXuu bearing, in mm.
function ball_bearing_info(trade_size) =
    assert(is_string(trade_size))
    let(
        IN = 25.4,
        data = [
            // trade_size, ID,     OD,      width,  shielded, flanged, fd, fw 
            [      "R2",  1/8*IN,  3/8*IN,  5/32*IN, false,   false,   0,  0 ],
            [      "R3", 3/16*IN,  1/2*IN,  5/32*IN, false,   false,   0,  0 ],
            [      "R4",  1/4*IN,  5/8*IN, 0.196*IN, false,   false,   0,  0 ],
            [      "R6",  3/8*IN,  7/8*IN,  7/32*IN, false,   false,   0,  0 ],
            [      "R8",  1/2*IN,  9/8*IN,   1/4*IN, false,   false,   0,  0 ],
            [     "R10",  5/8*IN, 11/8*IN,  9/32*IN, false,   false,   0,  0 ],
            [     "R12",  3/4*IN, 13/8*IN,  5/16*IN, false,   false,   0,  0 ],
            [     "R14",  7/8*IN, 15/8*IN,   3/8*IN, false,   false,   0,  0 ],
            [     "R16",  8/8*IN, 16/8*IN,   3/8*IN, false,   false,   0,  0 ],
            [     "R18",  9/8*IN, 17/8*IN,   3/8*IN, false,   false,   0,  0 ],
            [     "R20", 10/8*IN, 18/8*IN,   3/8*IN, false,   false,   0,  0 ],
            [     "R22", 11/8*IN, 20/8*IN,  7/16*IN, false,   false,   0,  0 ],
            [     "R24", 12/8*IN, 21/8*IN,  7/16*IN, false,   false,   0,  0 ],

            [    "R2ZZ",  1/8*IN,  3/8*IN,  5/32*IN, true,    false,   0,  0  ],
            [    "R3ZZ", 3/16*IN,  1/2*IN,  5/32*IN, true,    false,   0,  0  ],
            [    "R4ZZ",  1/4*IN,  5/8*IN, 0.196*IN, true,    false,   0,  0  ],
            [    "R6ZZ",  3/8*IN,  7/8*IN,  7/32*IN, true,    false,   0,  0  ],
            [    "R8ZZ",  1/2*IN,  9/8*IN,   1/4*IN, true,    false,   0,  0  ],
            [   "R10ZZ",  5/8*IN, 11/8*IN,  9/32*IN, true,    false,   0,  0  ],
            [   "R12ZZ",  3/4*IN, 13/8*IN,  5/16*IN, true,    false,   0,  0  ],
            [   "R14ZZ",  7/8*IN, 15/8*IN,   3/8*IN, true,    false,   0,  0  ],
            [   "R16ZZ",  8/8*IN, 16/8*IN,   3/8*IN, true,    false,   0,  0  ],
            [   "R18ZZ",  9/8*IN, 17/8*IN,   3/8*IN, true,    false,   0,  0  ],
            [   "R20ZZ", 10/8*IN, 18/8*IN,   3/8*IN, true,    false,   0,  0  ],
            [   "R22ZZ", 11/8*IN, 20/8*IN,  7/16*IN, true,    false,   0,  0  ],
            [   "R24ZZ", 12/8*IN, 21/8*IN,  7/16*IN, true,    false,   0,  0  ],

            [     "608",   8,  22,   7, false, false, 0, 0 ],
            [     "629",   9,  26,   8, false, false, 0, 0 ],
            [     "635",   5,  19,   6, false, false, 0, 0 ],
            [    "6000",  10,  26,   8, false, false, 0, 0 ],
            [    "6001",  12,  28,   8, false, false, 0, 0 ],
            [    "6002",  15,  32,   9, false, false, 0, 0 ],
            [    "6003",  17,  35,  10, false, false, 0, 0 ],
            [    "6007",  35,  62,  14, false, false, 0, 0 ],
            [    "6200",  10,  30,   9, false, false, 0, 0 ],
            [    "6201",  12,  32,  10, false, false, 0, 0 ],
            [    "6202",  15,  35,  11, false, false, 0, 0 ],
            [    "6203",  17,  40,  12, false, false, 0, 0 ],
            [    "6204",  20,  47,  14, false, false, 0, 0 ],
            [    "6205",  25,  52,  15, false, false, 0, 0 ],
            [    "6206",  30,  62,  16, false, false, 0, 0 ],
            [    "6207",  35,  72,  17, false, false, 0, 0 ],
            [    "6208",  40,  80,  18, false, false, 0, 0 ],
            [    "6209",  45,  85,  19, false, false, 0, 0 ],
            [    "6210",  50,  90,  20, false, false, 0, 0 ],
            [    "6211",  55, 100,  21, false, false, 0, 0 ],
            [    "6212",  60, 110,  22, false, false, 0, 0 ],
            [    "6301",  12,  37,  12, false, false, 0, 0 ],
            [    "6302",  15,  42,  13, false, false, 0, 0 ],
            [    "6303",  17,  47,  14, false, false, 0, 0 ],
            [    "6304",  20,  52,  15, false, false, 0, 0 ],
            [    "6305",  25,  62,  17, false, false, 0, 0 ],
            [    "6306",  30,  72,  19, false, false, 0, 0 ],
            [    "6307",  35,  80,  21, false, false, 0, 0 ],
            [    "6308",  40,  90,  23, false, false, 0, 0 ],
            [    "6309",  45, 100,  25, false, false, 0, 0 ],
            [    "6310",  50, 110,  27, false, false, 0, 0 ],
            [    "6311",  55, 120,  29, false, false, 0, 0 ],
            [    "6312",  60, 130,  31, false, false, 0, 0 ],
            [    "6403",  17,  62,  17, false, false, 0, 0 ],
            [    "6800",  10,  19,   5, false, false, 0, 0 ],
            [    "6801",  12,  21,   5, false, false, 0, 0 ],
            [    "6802",  15,  24,   5, false, false, 0, 0 ],
            [    "6803",  17,  26,   5, false, false, 0, 0 ],
            [    "6804",  20,  32,   7, false, false, 0, 0 ],
            [    "6805",  25,  37,   7, false, false, 0, 0 ],
            [    "6806",  30,  42,   7, false, false, 0, 0 ],
            [    "6900",  10,  22,   6, false, false, 0, 0 ],
            [    "6901",  12,  24,   6, false, false, 0, 0 ],
            [    "6902",  15,  28,   7, false, false, 0, 0 ],
            [    "6903",  17,  30,   7, false, false, 0, 0 ],
            [    "6904",  20,  37,   9, false, false, 0, 0 ],
            [    "6905",  25,  42,   9, false, false, 0, 0 ],
            [    "6906",  30,  47,   9, false, false, 0, 0 ],
            [    "6907",  35,  55,  10, false, false, 0, 0 ],
            [    "6908",  40,  62,  12, false, false, 0, 0 ],
            [   "16002",  15,  22,   8, false, false, 0, 0 ],
            [   "16004",  20,  42,   8, false, false, 0, 0 ],
            [   "16005",  25,  47,   8, false, false, 0, 0 ],
            [   "16100",  10,  28,   8, false, false, 0, 0 ],
            [   "16101",  12,  30,   8, false, false, 0, 0 ],

            [   "608ZZ",   8,  22,   7, true, false, 0, 0 ],
            [   "629ZZ",   9,  26,   8, true, false, 0, 0 ],
            [   "635ZZ",   5,  19,   6, true, false, 0, 0 ],
            [  "6000ZZ",  10,  26,   8, true, false, 0, 0 ],
            [  "6001ZZ",  12,  28,   8, true, false, 0, 0 ],
            [  "6002ZZ",  15,  32,   9, true, false, 0, 0 ],
            [  "6003ZZ",  17,  35,  10, true, false, 0, 0 ],
            [  "6007ZZ",  35,  62,  14, true, false, 0, 0 ],
            [  "6200ZZ",  10,  30,   9, true, false, 0, 0 ],
            [  "6201ZZ",  12,  32,  10, true, false, 0, 0 ],
            [  "6202ZZ",  15,  35,  11, true, false, 0, 0 ],
            [  "6203ZZ",  17,  40,  12, true, false, 0, 0 ],
            [  "6204ZZ",  20,  47,  14, true, false, 0, 0 ],
            [  "6205ZZ",  25,  52,  15, true, false, 0, 0 ],
            [  "6206ZZ",  30,  62,  16, true, false, 0, 0 ],
            [  "6207ZZ",  35,  72,  17, true, false, 0, 0 ],
            [  "6208ZZ",  40,  80,  18, true, false, 0, 0 ],
            [  "6209ZZ",  45,  85,  19, true, false, 0, 0 ],
            [  "6210ZZ",  50,  90,  20, true, false, 0, 0 ],
            [  "6211ZZ",  55, 100,  21, true, false, 0, 0 ],
            [  "6212ZZ",  60, 110,  22, true, false, 0, 0 ],
            [  "6301ZZ",  12,  37,  12, true, false, 0, 0 ],
            [  "6302ZZ",  15,  42,  13, true, false, 0, 0 ],
            [  "6303ZZ",  17,  47,  14, true, false, 0, 0 ],
            [  "6304ZZ",  20,  52,  15, true, false, 0, 0 ],
            [  "6305ZZ",  25,  62,  17, true, false, 0, 0 ],
            [  "6306ZZ",  30,  72,  19, true, false, 0, 0 ],
            [  "6307ZZ",  35,  80,  21, true, false, 0, 0 ],
            [  "6308ZZ",  40,  90,  23, true, false, 0, 0 ],
            [  "6309ZZ",  45, 100,  25, true, false, 0, 0 ],
            [  "6310ZZ",  50, 110,  27, true, false, 0, 0 ],
            [  "6311ZZ",  55, 120,  29, true, false, 0, 0 ],
            [  "6312ZZ",  60, 130,  31, true, false, 0, 0 ],
            [  "6403ZZ",  17,  62,  17, true, false, 0, 0 ],
            [  "6800ZZ",  10,  19,   5, true, false, 0, 0 ],
            [  "6801ZZ",  12,  21,   5, true, false, 0, 0 ],
            [  "6802ZZ",  15,  24,   5, true, false, 0, 0 ],
            [  "6803ZZ",  17,  26,   5, true, false, 0, 0 ],
            [  "6804ZZ",  20,  32,   7, true, false, 0, 0 ],
            [  "6805ZZ",  25,  37,   7, true, false, 0, 0 ],
            [  "6806ZZ",  30,  42,   7, true, false, 0, 0 ],
            [  "6900ZZ",  10,  22,   6, true, false, 0, 0 ],
            [  "6901ZZ",  12,  24,   6, true, false, 0, 0 ],
            [  "6902ZZ",  15,  28,   7, true, false, 0, 0 ],
            [  "6903ZZ",  17,  30,   7, true, false, 0, 0 ],
            [  "6904ZZ",  20,  37,   9, true, false, 0, 0 ],
            [  "6905ZZ",  25,  42,   9, true, false, 0, 0 ],
            [  "6906ZZ",  30,  47,   9, true, false, 0, 0 ],
            [  "6907ZZ",  35,  55,  10, true, false, 0, 0 ],
            [  "6908ZZ",  40,  62,  12, true, false, 0, 0 ],
            [ "16002ZZ",  15,  22,   8, true, false, 0, 0 ],
            [ "16004ZZ",  20,  42,   8, true, false, 0, 0 ],
            [ "16005ZZ",  25,  47,   8, true, false, 0, 0 ],
            [ "16100ZZ",  10,  28,   8, true, false, 0, 0 ],
            [ "16101ZZ",  12,  30,   8, true, false, 0, 0 ],

            [  "MF52ZZ",   2,   5,   2, true,  true,   6.2,  0.6 ],
            [  "MF63ZZ",   3,   6, 2.5, true,  true,   7.2,  0.6 ],
            [  "MF74ZZ",   4,   7, 2.5, true,  true,   8.2,  0.6 ],
            [  "MF83ZZ",   3,   8, 2.5, true,  true,   9.2,  0.6 ],
            [  "MF85ZZ",   5,   8, 2.5, true,  true,   9.2,  0.6 ],
            [  "MF95ZZ",   5,   9, 2.5, true,  true,  10.2,  0.6 ],
            [ "MF105ZZ",   5,  10,   3, true,  true,  11.2,  0.6 ],
            [ "MF117ZZ",   7,  11, 2.5, true,  true,  12.2,  0.6 ],
            [ "MF128ZZ",   8,  12, 3.5, true,  true,  13.6,  0.8 ],
            [ "MF148ZZ",   8,  14, 3.5, true,  true,  15.6,  0.8 ],
            [ "F6700ZZ",  10,  15,   4, true,  true,  16.8,  0.8 ],
            [ "F6701ZZ",  12,  18,   4, true,  true,  19.8,  0.8 ],
            [ "F6800ZZ",  10,  19,   5, true,  true,  21.1,  1.1 ],
            [ "F6801ZZ",  12,  21,   5, true,  true,  23.1,  1.1 ],
            [ "F6802ZZ",  15,  24,   5, true,  true,  26.1,  1.1 ],
            [ "F6803ZZ",  17,  26,   5, true,  true,  28.1,  1.1 ],
            [ "F6804ZZ",  20,  32,   7, true,  true,    35,  1.5 ],
            [ "F6805ZZ",  25,  37,   7, true,  true,  40.2,  1.5 ],
            [ "F6900ZZ",  10,  22,   6, true,  true,  24.5,  1.5 ],
            [ "F6901ZZ",  12,  24,   6, true,  true,  26.5,  1.5 ],
            
            [  "F683ZZ",   3,   7,   3, false, true,   8.1,  0.6 ],
            [  "F684ZZ",   4,   9,   4, false, true,  10.3,  0.6 ],
            [  "F685ZZ",   5,  11,   5, false, true,  12.5,  1   ],
            [  "F686ZZ",   6,  13,   5, false, true,    15,  1   ],
            [  "F687ZZ",   7,  14,   5, false, true,    16,  1   ],
            [  "F688ZZ",   8,  16,   5, false, true,    18,  1   ],
            [  "F689ZZ",   9,  17,   5, false, true,    19,  1   ],
            [ "F6900ZZ",  10,  22,   6, false, true,    25,  1.5 ],
            [ "F6901ZZ",  12,  24,   6, false, true,  26.5,  1.5 ],
            [ "F6902ZZ",  15,  28,   7, false, true,  31.5,  1.5 ],
            [ "F6903ZZ",  17,  30,   7, false, true,  33.5,  1.5 ],
            [ "F6904ZZ",  20,  37,   9, false, true,  40.5,  1.5 ],
            [ "F6905ZZ",  25,  42,   9, false, true,  45.5,  1.5 ],
            [ "F6000ZZ",  10,  26,   8, false, true,  28.5,  1.5 ],
            [ "F6001ZZ",  12,  28,   8, false, true,  30.5,  1.5 ],
            [ "F6001ZZ",  15,  32,   9, false, true,  34.5,  1.5 ],
            [ "F6003ZZ",  17,  35,  10, false, true,  37.5,  1.5 ],
            [ "F6004ZZ",  20,  42,  12, false, true,  44.5,  1.5 ],
            [ "F6005ZZ",  25,  47,  12, false, true,  49.5,  1.5 ],
            [ "F6006ZZ",  30,  55,  13, false, true,  57.5,  1.5 ],
        ],
        found = search([trade_size], data, 1)[0]
    )
    assert(found!=[], str("Unsupported ball bearing trade size: ", trade_size))
    select(data[found], 1, -1);



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
