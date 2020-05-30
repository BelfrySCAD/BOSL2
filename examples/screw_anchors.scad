include <BOSL2/std.scad>
include <BOSL2/threading.scad>
include <BOSL2/phillips_drive.scad>
include <BOSL2/torx_drive.scad>
include <BOSL2/metric_screws.scad>
include <BOSL2/debug.scad>


metric_bolt(headtype="oval", size=10, l=15, shank=5, details=true, phillips="#2")
show_anchors(5, std=false);


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
