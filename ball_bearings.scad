//////////////////////////////////////////////////////////////////////
// LibFile: ball_bearings.scad
//   Models for standard ball bearing cartridges.
// Includes:
//   include <BOSL2/std.scad>
//   include <BOSL2/ball_bearings.scad>
// FileGroup: Parts
// FileSummary: Models for standard ball bearing cartridges.
//////////////////////////////////////////////////////////////////////

_BOSL2_BALL_BEARINGS = is_undef(_BOSL2_STD) && (is_undef(BOSL2_NO_STD_WARNING) || !BOSL2_NO_STD_WARNING) ?
       echo("Warning: ball_bearings.scad included without std.scad; dependencies may be missing\nSet BOSL2_NO_STD_WARNING = true to mute this warning.") true : true;


// Section: Ball Bearing Models

// Module: ball_bearing()
// Synopsis: Creates a standardized ball bearing assembly.
// SynTags: Geom
// Topics: Parts, Bearings
// See Also: linear_bearing(), lmXuu_bearing(), lmXuu_housing()
// Usage:
//   ball_bearing(trade_size, [rounding=], [anchor=], [spin=], [orient=]) [ATTACHMENTS];
//   ball_bearing(info, [rounding=], [anchor=], [spin=], [orient=]) [ATTACHMENTS];
//   ball_bearing(id=, od=, width=, [shield=], [flange=], [fd=], [fw=], [rounding=], [anchor=], [spin=], [orient=]) [ATTACHMENTS];
// Description:
//   Creates a model of a ball bearing assembly. A trade size string selects the complete catalog record.
//   You can also pass a bearing-info struct returned by `ball_bearing_info(..., struct=true)` as the first
//   argument.  With either form, id, od, width, shield, flange, fd, and fw are ignored.  Omit the first
//   argument to give custom dimensions.
//   The table contains nominal envelopes from the catalogs cited in the source. Check the manufacturer's
//   drawing for a critical fit, particularly flange dimensions. Rounding is independent of the bearing data.
// Arguments:
//   trade_size = String name of a standard ball bearing trade size, such as "608", "6902ZZ", or "R8", or a bearing-info struct returned by `ball_bearing_info(..., struct=true)`.
//   id = Inner diameter of ball bearing assembly.
//   od = Outer diameter of ball bearing assembly.
//   width = Width of ball bearing assembly.
//   shield = If true, the custom ball bearing assembly has a shield. Default for custom dimensions: true
//   flange = If true, the custom ball bearing assembly has a flange. Default for custom dimensions: false
//   fd = Diameter of the flange (required with custom dimensions and flange=true).
//   fw = Width of the flange (required with custom dimensions and flange=true).
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
// Example: Create bearing data now and use it later.
//   info = ball_bearing_info("608ZZ", struct=true);
//   ball_bearing(info, $fn=72);
module ball_bearing(trade_size, id, od, width, shield=true, flange=false, fd, fw, rounding, anchor=CTR, spin=0, orient=UP) {
    info = is_undef(trade_size)? [id, od, width, shield, flange, fd, fw] :
        is_struct(trade_size)?
            assert(_is_ball_bearing_info(trade_size), "Invalid ball bearing info struct")
            [
                struct_val(trade_size, "inner_diam"),
                struct_val(trade_size, "outer_diam"),
                struct_val(trade_size, "width"),
                struct_val(trade_size, "shielded"),
                struct_val(trade_size, "flanged"),
                struct_val(trade_size, "flange_diam"),
                struct_val(trade_size, "flange_width")
            ] :
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


/// Internal Function: _is_ball_bearing_info()
/// Description:
///   Returns true if `info` has the fields and basic types required for a ball-bearing info struct.
function _is_ball_bearing_info(info) =
    is_struct(info) &&
    is_string(struct_val(info, "trade_size")) &&
    is_num(struct_val(info, "inner_diam")) &&
    is_num(struct_val(info, "outer_diam")) &&
    is_num(struct_val(info, "width")) &&
    is_bool(struct_val(info, "shielded")) &&
    is_bool(struct_val(info, "flanged")) &&
    is_num(struct_val(info, "flange_diam")) &&
    is_num(struct_val(info, "flange_width"));


// Function: ball_bearing_info()
// Synopsis: Returns dimensional and feature information for a standardized ball bearing assembly.
// Topics: Parts, Bearings
// See Also: ball_bearing(), linear_bearing(), lmXuu_info(), struct_val(), echo_struct()
// Usage:
//   info = ball_bearing_info(trade_size);
//   info = ball_bearing_info(trade_size, struct=true);
// Description:
//   Returns nominal dimensional and feature information for a metric or inch-series ball bearing cartridge.
//   By default, returns the legacy array
//   `[INNER_DIAM, OUTER_DIAM, WIDTH, SHIELDED, FLANGED, FLANGE_DIAM, FLANGE_WIDTH]`.
//   If `struct=true`, returns the same bearing information as a struct, suitable for passing directly
//   to {{ball_bearing()}}.  All dimensions are in millimeters.
//   .
//   The returned struct contains the following fields:
//   .
//   Key              | Type    | Description
//   ---------------- | ------- | -------------------------------------------------------------
//   `"trade_size"`   | string  | Bearing designation, such as `"608ZZ"` or `"R8"`.
//   `"inner_diam"`   | number  | Inner diameter of the bearing.
//   `"outer_diam"`   | number  | Outer diameter of the bearing.
//   `"width"`        | number  | Overall axial width of the bearing.
//   `"shielded"`     | boolean | True if the bearing is shielded.
//   `"flanged"`      | boolean | True if the bearing has a flange.
//   `"flange_diam"`  | number  | Outside diameter of the flange.  Zero if unflanged.
//   `"flange_width"` | number  | Axial width of the flange.  Zero if unflanged.
// Arguments:
//   trade_size = String designation of a supported bearing, such as "608ZZ", "R8", or "MF105ZZ".
//   struct = If true, return a struct instead of the legacy array.  Default: false
// Example(NORENDER): Legacy array return
//   info = ball_bearing_info("608ZZ");
//   assert(info == [8,22,7,true,false,0,0]);
// Example(NORENDER): Struct return
//   info = ball_bearing_info("608ZZ", struct=true);
//   assert(struct_val(info,"outer_diam") == 22);
// Example: Pass the returned struct directly to ball_bearing()
//   info = ball_bearing_info("608ZZ", struct=true);
//   ball_bearing(info, $fn=72);
function ball_bearing_info(trade_size, struct=false) =
    assert(is_string(trade_size), "trade_size must be a string")
    assert(is_bool(struct), "struct must be true or false")
    let(
        IN = 25.4,
        // Nominal catalog entries, selected as complete records; dimensions are mm.
        // Inch fractions below are converted by IN. Sources were checked 2026-10-01.
        // Manufacturer variants can differ; suffixes identify separate records.
        // Open R24 follows AST, not the wider conflicting ZEN entry.
        // F6002ZZ and F6000ZZE use complete JVB records, not inferred flange widths.
        // [AMF128] AUB MF128ZZ
        // https://www.aubearing.com/product/mf128zz/
        // [AMF95] AUB MF95ZZ
        // https://www.aubearing.com/product/mf95zz/
        // [AST_F6800] AST F6800ZZ
        // https://www.astbearings.com/catalog/thin_section_metric/F6800ZZ
        // [AST_R24] AST R24 open, 0.4375-inch width
        // https://www.astbearings.com/catalog/precision_r_series/R24
        // [B16100] BSPD 16100
        // https://www.bspdbearing.com/product/16100/
        // [B16100ZZ] BSPD 16100ZZ
        // https://www.bspdbearing.com/product/16100zz/
        // [B16101] BSPD 16101
        // https://www.bspdbearing.com/product/16101/
        // [B16101ZZ] BSPD 16101ZZ
        // https://www.bspdbearing.com/product/16101zz/
        // [B6403] BSPD 6403
        // https://www.bspdbearing.com/product/6403/
        // [BMF83] BSPD MF83ZZ
        // https://www.bspdbearing.com/product/mf83zz/
        // [E3] EZO inch series, page 3 (R3/ZZ widths)
        // https://www.ezo-brg.co.jp/product/result.php?page=3&product_category=5
        // [EMF52] EZO MF52ZZ (body width)
        // https://www.ezo-brg.co.jp/product/result.php?product_category=2
        // [EMF83] EZO MF83ZZ (body width)
        // https://www.ezo-brg.co.jp/product/result.php?page=2&product_category=2
        // [EMF95] EZO MF95ZZ (body width)
        // https://www.ezo-brg.co.jp/product/result.php?page=4&product_category=2
        // [I] Ningbo Yuhong open versus shielded inch dimensions
        // https://www.jhbearing.com/product/r-series/
        // [JVB] JVB complete flanged-series dimension table; ZZ/ZZE variants
        // https://www.jvbbearing.com/flanged-series-ball-bearings/
        // [L608ZZ] LILY 608ZZ
        // https://www.lily-bearing.com/products/608zz/
        // [L635ZZ] LILY 635ZZ
        // https://www.lily-bearing.com/products/635zz/
        // [LF6000ZZ] LILY F6000ZZ
        // https://www.lily-bearing.com/products/f6000zz/
        // [LF6001ZZ] LILY F6001ZZ
        // https://www.lily-bearing.com/products/f6001zz/
        // [LF6003ZZ] LILY F6003ZZ
        // https://www.lily-bearing.com/products/f6003zz/
        // [LF6004ZZ] LILY F6004ZZ
        // https://www.lily-bearing.com/products/f6004zz/
        // [LF6005ZZ] LILY F6005ZZ
        // https://www.lily-bearing.com/products/f6005zz/
        // [LF6006ZZ] LILY F6006ZZ
        // https://www.lily-bearing.com/products/f6006zz/
        // [LF6700ZZ] LILY F6700ZZ
        // https://www.lily-bearing.com/products/f6700zz/
        // [LF6701ZZ] LILY F6701ZZ
        // https://www.lily-bearing.com/products/f6701zz/
        // [LF6801ZZ] LILY F6801ZZ
        // https://www.lily-bearing.com/products/f6801zz/
        // [LF6802ZZ] LILY F6802ZZ
        // https://www.lily-bearing.com/products/f6802zz/
        // [LF6803ZZ] LILY F6803ZZ
        // https://www.lily-bearing.com/products/f6803zz/
        // [LF6804ZZ] LILY F6804ZZ
        // https://www.lily-bearing.com/products/f6804zz/
        // [LF6805ZZ] LILY F6805ZZ
        // https://www.lily-bearing.com/products/f6805zz/
        // [LF683ZZ] LILY F683ZZ
        // https://www.lily-bearing.com/products/f683zz/
        // [LF685ZZ] LILY F685ZZ
        // https://www.lily-bearing.com/products/f685zz/
        // [LF686ZZ] LILY F686ZZ
        // https://www.lily-bearing.com/products/f686zz/
        // [LF687ZZ] LILY F687ZZ
        // https://www.lily-bearing.com/products/f687zz/
        // [LF688ZZ] LILY F688ZZ
        // https://www.lily-bearing.com/products/f688zz/
        // [LF689ZZ] LILY F689ZZ
        // https://www.lily-bearing.com/products/f689zz/
        // [LF6900ZZ] LILY F6900ZZ
        // https://www.lily-bearing.com/products/f6900zz/
        // [LF6901ZZ] LILY F6901ZZ
        // https://www.lily-bearing.com/products/f6901zz/
        // [LF6902ZZ] LILY F6902ZZ
        // https://www.lily-bearing.com/products/f6902zz/
        // [LF6903ZZ] LILY F6903ZZ
        // https://www.lily-bearing.com/products/f6903zz/
        // [LF6904ZZ] LILY F6904ZZ
        // https://www.lily-bearing.com/products/f6904zz/
        // [LF6905ZZ] LILY F6905ZZ
        // https://www.lily-bearing.com/products/f6905zz/
        // [LMF117ZZ] LILY MF117ZZ
        // https://www.lily-bearing.com/products/mf117zz/
        // [LMF148ZZ] LILY MF148ZZ
        // https://www.lily-bearing.com/products/mf148zz/
        // [LMF52ZZ] LILY MF52ZZ
        // https://www.lily-bearing.com/products/mf52zz/
        // [LNB6403] LNB 6403 open / ZZ / 2RS table
        // https://www.lnbbearing.com/6403-deep-groove-ball-bearing.html
        // [M] HHZC metric open/ZZ dimension table
        // https://www.nthaihuibearing.com/product/deep-groove-ball-bearing/
        // [N16002] NSK 16002: 15 x 32 x 8
        // https://www.nsk.com/engineering/products/bearings/ball-bearings/deep-groove-ball-bearings/single-row-deep-groove-ball-bearings/16002-apn.html
        // [N608] NSK 608
        // https://www.nsk.com/engineering/products/bearings/ball-bearings/deep-groove-ball-bearings/extra-small-ball-bearings-and-miniature-ball-bearings-metric-series/608-esm-md.html
        // [N629] NSK 629
        // https://www.nsk.com/engineering/products/bearings/ball-bearings/deep-groove-ball-bearings/extra-small-ball-bearings-and-miniature-ball-bearings-metric-series/629-esm-md.html
        // [N629ZZ] NSK 629ZZ
        // https://www.nsk.com/engineering/products/bearings/ball-bearings/deep-groove-ball-bearings/extra-small-ball-bearings-and-miniature-ball-bearings-metric-series/629zz-esm-md.html
        // [N635] NSK 635
        // https://www.nsk.com/engineering/products/bearings/ball-bearings/deep-groove-ball-bearings/extra-small-ball-bearings-and-miniature-ball-bearings-metric-series/635-esm-md.html
        // [NMF105ZZ] NSK MF105ZZ
        // https://www.nsk.com/engineering/products/bearings/ball-bearings/deep-groove-ball-bearings/extra-small-ball-bearings-and-miniature-ball-bearings-metric-series-with-flamge/mf105zz-esm-md-wf.html
        // [NMF63ZZ] NSK MF63ZZ
        // https://www.nsk.com/engineering/products/bearings/ball-bearings/deep-groove-ball-bearings/extra-small-ball-bearings-and-miniature-ball-bearings-metric-series-with-flamge/mf63zz-esm-md-wf.html
        // [NMF74ZZ] NSK MF74ZZ
        // https://www.nsk.com/engineering/products/bearings/ball-bearings/deep-groove-ball-bearings/extra-small-ball-bearings-and-miniature-ball-bearings-metric-series-with-flamge/mf74zz-esm-md-wf.html
        // [NMF85ZZ] NSK MF85ZZ
        // https://www.nsk.com/engineering/products/bearings/ball-bearings/deep-groove-ball-bearings/extra-small-ball-bearings-and-miniature-ball-bearings-metric-series-with-flamge/mf85zz-esm-md-wf.html
        // [NSK_F684ZZ] NSK F684ZZ
        // https://www.nsk.com/engineering/products/bearings/ball-bearings/deep-groove-ball-bearings/extra-small-ball-bearings-and-miniature-ball-bearings-metric-series-with-flamge/f684zz-esm-md-wf.html
        // [Z] ZEN inch-series dimensions
        // https://www.zen.biz/catalogue-Inch-series
        data = [
            // trade_size, ID, OD, width, shielded, flanged, fd, fw
            ["R2", 1/8*IN, 3/8*IN, 5/32*IN, false, false, 0, 0 ], // [I]
            ["R3", 3/16*IN, 1/2*IN, 5/32*IN, false, false, 0, 0 ], // [I]
            ["R4", 1/4*IN, 5/8*IN, 0.196*IN, false, false, 0, 0 ], // [I]
            ["R6", 3/8*IN, 7/8*IN, 7/32*IN, false, false, 0, 0 ], // [I]
            ["R8", 1/2*IN, 9/8*IN, 1/4*IN, false, false, 0, 0 ], // [Z]
            ["R10", 5/8*IN, 11/8*IN, 9/32*IN, false, false, 0, 0 ], // [Z]
            ["R12", 3/4*IN, 13/8*IN, 5/16*IN, false, false, 0, 0 ], // [Z]
            ["R14", 7/8*IN, 15/8*IN, 3/8*IN, false, false, 0, 0 ], // [Z]
            ["R16", 8/8*IN, 16/8*IN, 3/8*IN, false, false, 0, 0 ], // [Z]
            ["R18", 9/8*IN, 17/8*IN, 3/8*IN, false, false, 0, 0 ], // [Z]
            ["R20", 10/8*IN, 18/8*IN, 3/8*IN, false, false, 0, 0 ], // [Z]
            ["R22", 11/8*IN, 20/8*IN, 7/16*IN, false, false, 0, 0 ], // [Z]
            ["R24", 12/8*IN, 21/8*IN, 7/16*IN, false, false, 0, 0 ], // [AST_R24]
            ["R2ZZ", 1/8*IN, 3/8*IN, 5/32*IN, true, false, 0, 0 ], // [I]
            ["R3ZZ", 3/16*IN, 1/2*IN, 0.196*IN, true, false, 0, 0 ], // [I], [E3]
            ["R4ZZ", 1/4*IN, 5/8*IN, 0.196*IN, true, false, 0, 0 ], // [I]
            ["R6ZZ", 3/8*IN, 7/8*IN, 9/32*IN, true, false, 0, 0 ], // [I]
            ["R8ZZ", 1/2*IN, 9/8*IN, 5/16*IN, true, false, 0, 0 ], // [Z]
            ["R10ZZ", 5/8*IN, 11/8*IN, 11/32*IN, true, false, 0, 0 ], // [Z]
            ["R12ZZ", 3/4*IN, 13/8*IN, 7/16*IN, true, false, 0, 0 ], // [Z]
            ["R14ZZ", 7/8*IN, 15/8*IN, 1/2*IN, true, false, 0, 0 ], // [Z]
            ["R16ZZ", 8/8*IN, 16/8*IN, 1/2*IN, true, false, 0, 0 ], // [Z]
            ["R18ZZ", 9/8*IN, 17/8*IN, 1/2*IN, true, false, 0, 0 ], // [Z]
            ["R20ZZ", 10/8*IN, 18/8*IN, 1/2*IN, true, false, 0, 0 ], // [Z]
            ["R22ZZ", 11/8*IN, 20/8*IN, 9/16*IN, true, false, 0, 0 ], // [Z]
            ["R24ZZ", 12/8*IN, 21/8*IN, 9/16*IN, true, false, 0, 0 ], // [Z]

            ["608", 8, 22, 7, false, false, 0, 0 ], // [N608]
            ["629", 9, 26, 8, false, false, 0, 0 ], // [N629]
            ["635", 5, 19, 6, false, false, 0, 0 ], // [N635]
            ["6000", 10, 26, 8, false, false, 0, 0 ], // [M]
            ["6001", 12, 28, 8, false, false, 0, 0 ], // [M]
            ["6002", 15, 32, 9, false, false, 0, 0 ], // [M]
            ["6003", 17, 35, 10, false, false, 0, 0 ], // [M]
            ["6007", 35, 62, 14, false, false, 0, 0 ], // [M]
            ["6200", 10, 30, 9, false, false, 0, 0 ], // [M]
            ["6201", 12, 32, 10, false, false, 0, 0 ], // [M]
            ["6202", 15, 35, 11, false, false, 0, 0 ], // [M]
            ["6203", 17, 40, 12, false, false, 0, 0 ], // [M]
            ["6204", 20, 47, 14, false, false, 0, 0 ], // [M]
            ["6205", 25, 52, 15, false, false, 0, 0 ], // [M]
            ["6206", 30, 62, 16, false, false, 0, 0 ], // [M]
            ["6207", 35, 72, 17, false, false, 0, 0 ], // [M]
            ["6208", 40, 80, 18, false, false, 0, 0 ], // [M]
            ["6209", 45, 85, 19, false, false, 0, 0 ], // [M]
            ["6210", 50, 90, 20, false, false, 0, 0 ], // [M]
            ["6211", 55, 100, 21, false, false, 0, 0 ], // [M]
            ["6212", 60, 110, 22, false, false, 0, 0 ], // [M]
            ["6301", 12, 37, 12, false, false, 0, 0 ], // [M]
            ["6302", 15, 42, 13, false, false, 0, 0 ], // [M]
            ["6303", 17, 47, 14, false, false, 0, 0 ], // [M]
            ["6304", 20, 52, 15, false, false, 0, 0 ], // [M]
            ["6305", 25, 62, 17, false, false, 0, 0 ], // [M]
            ["6306", 30, 72, 19, false, false, 0, 0 ], // [M]
            ["6307", 35, 80, 21, false, false, 0, 0 ], // [M]
            ["6308", 40, 90, 23, false, false, 0, 0 ], // [M]
            ["6309", 45, 100, 25, false, false, 0, 0 ], // [M]
            ["6310", 50, 110, 27, false, false, 0, 0 ], // [M]
            ["6311", 55, 120, 29, false, false, 0, 0 ], // [M]
            ["6312", 60, 130, 31, false, false, 0, 0 ], // [M]
            ["6403", 17, 62, 17, false, false, 0, 0 ], // [B6403], [LNB6403]
            ["6800", 10, 19, 5, false, false, 0, 0 ], // [M]
            ["6801", 12, 21, 5, false, false, 0, 0 ], // [M]
            ["6802", 15, 24, 5, false, false, 0, 0 ], // [M]
            ["6803", 17, 26, 5, false, false, 0, 0 ], // [M]
            ["6804", 20, 32, 7, false, false, 0, 0 ], // [M]
            ["6805", 25, 37, 7, false, false, 0, 0 ], // [M]
            ["6806", 30, 42, 7, false, false, 0, 0 ], // [M]
            ["6900", 10, 22, 6, false, false, 0, 0 ], // [M]
            ["6901", 12, 24, 6, false, false, 0, 0 ], // [M]
            ["6902", 15, 28, 7, false, false, 0, 0 ], // [M]
            ["6903", 17, 30, 7, false, false, 0, 0 ], // [M]
            ["6904", 20, 37, 9, false, false, 0, 0 ], // [M]
            ["6905", 25, 42, 9, false, false, 0, 0 ], // [M]
            ["6906", 30, 47, 9, false, false, 0, 0 ], // [M]
            ["6907", 35, 55, 10, false, false, 0, 0 ], // [M]
            ["6908", 40, 62, 12, false, false, 0, 0 ], // [M]
            ["16002", 15, 32, 8, false, false, 0, 0 ], // [M], [N16002]
            ["16004", 20, 42, 8, false, false, 0, 0 ], // [M]
            ["16005", 25, 47, 8, false, false, 0, 0 ], // [M]
            ["16100", 10, 28, 8, false, false, 0, 0 ], // [B16100]
            ["16101", 12, 30, 8, false, false, 0, 0 ], // [B16101]
            ["608ZZ", 8, 22, 7, true, false, 0, 0 ], // [L608ZZ]
            ["629ZZ", 9, 26, 8, true, false, 0, 0 ], // [N629ZZ]
            ["635ZZ", 5, 19, 6, true, false, 0, 0 ], // [L635ZZ]
            ["6000ZZ", 10, 26, 8, true, false, 0, 0 ], // [M]
            ["6001ZZ", 12, 28, 8, true, false, 0, 0 ], // [M]
            ["6002ZZ", 15, 32, 9, true, false, 0, 0 ], // [M]
            ["6003ZZ", 17, 35, 10, true, false, 0, 0 ], // [M]
            ["6007ZZ", 35, 62, 14, true, false, 0, 0 ], // [M]
            ["6200ZZ", 10, 30, 9, true, false, 0, 0 ], // [M]
            ["6201ZZ", 12, 32, 10, true, false, 0, 0 ], // [M]
            ["6202ZZ", 15, 35, 11, true, false, 0, 0 ], // [M]
            ["6203ZZ", 17, 40, 12, true, false, 0, 0 ], // [M]
            ["6204ZZ", 20, 47, 14, true, false, 0, 0 ], // [M]
            ["6205ZZ", 25, 52, 15, true, false, 0, 0 ], // [M]
            ["6206ZZ", 30, 62, 16, true, false, 0, 0 ], // [M]
            ["6207ZZ", 35, 72, 17, true, false, 0, 0 ], // [M]
            ["6208ZZ", 40, 80, 18, true, false, 0, 0 ], // [M]
            ["6209ZZ", 45, 85, 19, true, false, 0, 0 ], // [M]
            ["6210ZZ", 50, 90, 20, true, false, 0, 0 ], // [M]
            ["6211ZZ", 55, 100, 21, true, false, 0, 0 ], // [M]
            ["6212ZZ", 60, 110, 22, true, false, 0, 0 ], // [M]
            ["6301ZZ", 12, 37, 12, true, false, 0, 0 ], // [M]
            ["6302ZZ", 15, 42, 13, true, false, 0, 0 ], // [M]
            ["6303ZZ", 17, 47, 14, true, false, 0, 0 ], // [M]
            ["6304ZZ", 20, 52, 15, true, false, 0, 0 ], // [M]
            ["6305ZZ", 25, 62, 17, true, false, 0, 0 ], // [M]
            ["6306ZZ", 30, 72, 19, true, false, 0, 0 ], // [M]
            ["6307ZZ", 35, 80, 21, true, false, 0, 0 ], // [M]
            ["6308ZZ", 40, 90, 23, true, false, 0, 0 ], // [M]
            ["6309ZZ", 45, 100, 25, true, false, 0, 0 ], // [M]
            ["6310ZZ", 50, 110, 27, true, false, 0, 0 ], // [M]
            ["6311ZZ", 55, 120, 29, true, false, 0, 0 ], // [M]
            ["6312ZZ", 60, 130, 31, true, false, 0, 0 ], // [M]
            ["6403ZZ", 17, 62, 17, true, false, 0, 0 ], // [B6403], [LNB6403]
            ["6800ZZ", 10, 19, 5, true, false, 0, 0 ], // [M]
            ["6801ZZ", 12, 21, 5, true, false, 0, 0 ], // [M]
            ["6802ZZ", 15, 24, 5, true, false, 0, 0 ], // [M]
            ["6803ZZ", 17, 26, 5, true, false, 0, 0 ], // [M]
            ["6804ZZ", 20, 32, 7, true, false, 0, 0 ], // [M]
            ["6805ZZ", 25, 37, 7, true, false, 0, 0 ], // [M]
            ["6806ZZ", 30, 42, 7, true, false, 0, 0 ], // [M]
            ["6900ZZ", 10, 22, 6, true, false, 0, 0 ], // [M]
            ["6901ZZ", 12, 24, 6, true, false, 0, 0 ], // [M]
            ["6902ZZ", 15, 28, 7, true, false, 0, 0 ], // [M]
            ["6903ZZ", 17, 30, 7, true, false, 0, 0 ], // [M]
            ["6904ZZ", 20, 37, 9, true, false, 0, 0 ], // [M]
            ["6905ZZ", 25, 42, 9, true, false, 0, 0 ], // [M]
            ["6906ZZ", 30, 47, 9, true, false, 0, 0 ], // [M]
            ["6907ZZ", 35, 55, 10, true, false, 0, 0 ], // [M]
            ["6908ZZ", 40, 62, 12, true, false, 0, 0 ], // [M]
            ["16002ZZ", 15, 32, 8, true, false, 0, 0 ], // [M], [N16002]
            ["16004ZZ", 20, 42, 8, true, false, 0, 0 ], // [M]
            ["16005ZZ", 25, 47, 8, true, false, 0, 0 ], // [M]
            ["16100ZZ", 10, 28, 8, true, false, 0, 0 ], // [B16100ZZ]
            ["16101ZZ", 12, 30, 8, true, false, 0, 0 ], // [B16101ZZ]

            ["MF52ZZ", 2, 5, 2.5, true, true, 6.2, 0.6 ], // [EMF52], [LMF52ZZ]
            ["MF63ZZ", 3, 6, 2.5, true, true, 7.2, 0.6 ], // [NMF63ZZ]
            ["MF74ZZ", 4, 7, 2.5, true, true, 8.2, 0.6 ], // [NMF74ZZ]
            ["MF83ZZ", 3, 8, 3, true, true, 9.2, 0.6 ], // [EMF83], [BMF83]
            ["MF85ZZ", 5, 8, 2.5, true, true, 9.2, 0.6 ], // [NMF85ZZ]
            ["MF95ZZ", 5, 9, 3, true, true, 10.2, 0.6 ], // [EMF95], [AMF95]
            ["MF105ZZ", 5, 10, 4, true, true, 11.6, 0.8 ], // [NMF105ZZ]
            ["MF117ZZ", 7, 11, 3, true, true, 12.2, 0.6 ], // [LMF117ZZ]
            ["MF128ZZ", 8, 12, 3.5, true, true, 13.6, 0.8 ], // [AMF128]
            ["MF148ZZ", 8, 14, 4, true, true, 15.6, 0.8 ], // [LMF148ZZ]
            ["F6700ZZ", 10, 15, 4, true, true, 16.5, 0.8 ], // [LF6700ZZ]
            ["F6701ZZ", 12, 18, 4, true, true, 19.5, 0.8 ], // [LF6701ZZ]
            ["F6800ZZ", 10, 19, 5, true, true, 21, 1 ], // [AST_F6800]
            ["F6801ZZ", 12, 21, 5, true, true, 23, 1.1 ], // [LF6801ZZ]
            ["F6802ZZ", 15, 24, 5, true, true, 26, 1.1 ], // [LF6802ZZ]
            ["F6803ZZ", 17, 26, 5, true, true, 28, 1.1 ], // [LF6803ZZ]
            ["F6804ZZ", 20, 32, 7, true, true, 35, 1.5 ], // [LF6804ZZ]
            ["F6805ZZ", 25, 37, 7, true, true, 40, 1.5 ], // [LF6805ZZ]
            ["F6900ZZ", 10, 22, 6, true, true, 25, 1.5 ], // [LF6900ZZ]
            ["F6901ZZ", 12, 24, 6, true, true, 26.5, 1.5 ], // [LF6901ZZ]
            ["F683ZZ", 3, 7, 3, true, true, 8.1, 0.8 ], // [LF683ZZ]
            ["F684ZZ", 4, 9, 4, true, true, 10.3, 1 ], // [NSK_F684ZZ]
            ["F685ZZ", 5, 11, 5, true, true, 12.5, 1 ], // [LF685ZZ]
            ["F686ZZ", 6, 13, 5, true, true, 15, 1.1 ], // [LF686ZZ]
            ["F687ZZ", 7, 14, 5, true, true, 16, 1.1 ], // [LF687ZZ]
            ["F688ZZ", 8, 16, 5, true, true, 18, 1.1 ], // [LF688ZZ]
            ["F689ZZ", 9, 17, 5, true, true, 19, 1.1 ], // [LF689ZZ]
            ["F6902ZZ", 15, 28, 7, true, true, 30.5, 1.5 ], // [LF6902ZZ]
            ["F6903ZZ", 17, 30, 7, true, true, 32.5, 1.5 ], // [LF6903ZZ]
            ["F6904ZZ", 20, 37, 9, true, true, 40, 2 ], // [LF6904ZZ]
            ["F6905ZZ", 25, 42, 9, true, true, 45, 2 ], // [LF6905ZZ]
            ["F6000ZZ", 10, 26, 8, true, true, 28, 2 ], // [LF6000ZZ]
            ["F6001ZZ", 12, 28, 8, true, true, 30, 2 ], // [LF6001ZZ]
            ["F6002ZZ", 15, 32, 9, true, true, 34.25, 2.25 ], // [JVB]
            ["F6003ZZ", 17, 35, 10, true, true, 37.5, 2.5 ], // [LF6003ZZ]
            ["F6004ZZ", 20, 42, 12, true, true, 45, 3 ], // [LF6004ZZ]
            ["F6005ZZ", 25, 47, 12, true, true, 50, 3 ], // [LF6005ZZ]
            ["F6006ZZ", 30, 55, 13, true, true, 58.25, 3.25 ], // [LF6006ZZ]
            ["F6000ZZE", 10, 26, 8, true, true, 28, 1.5 ], // [JVB]
        ],
        found = search([trade_size], data, 1)[0]
    )
    assert(found!=[], str("Unsupported ball bearing trade size: ", trade_size))
    let(row = data[found])
    !struct? select(row, 1, -1) :
        struct_set([], [
            "trade_size", row[0],
            "inner_diam", row[1],
            "outer_diam", row[2],
            "width", row[3],
            "shielded", row[4],
            "flanged", row[5],
            "flange_diam", row[6],
            "flange_width", row[7]
        ]);



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
