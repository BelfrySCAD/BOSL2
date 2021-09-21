//////////////////////////////////////////////////////////////////////
// LibFile: phillips_drive.scad
//   Phillips driver bits
// Includes:
//   include <BOSL2/std.scad>
//   include <BOSL2/phillips_drive.scad>
//////////////////////////////////////////////////////////////////////


// Section: Modules


// Module: phillips_drive()
// Description: Creates a model of a phillips driver bit of a given named size.
// Arguments:
//   size = The size of the bit as a string.  "#0", "#1", "#2", "#3", or "#4"
//   shaft = The diameter of the drive bit's shaft.
//   l = The length of the drive bit.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#orient).  Default: `UP`
// Example:
//   xdistribute(10) {
//      phillips_drive(size="#1", shaft=4, l=20);
//      phillips_drive(size="#2", shaft=6, l=20);
//      phillips_drive(size="#3", shaft=6, l=20);
//   }
module phillips_drive(size="#2", shaft, l=20, $fn=36, anchor=BOTTOM, spin=0, orient=UP) {
    assert(is_string(size));
    assert(in_list(size,["#0","#1","#2","#3","#4"]));

    num = ord(size[1]) - ord("0");
    defshaft = [3,4.5,6,8,10][num];
    shaft = first_defined([defshaft,shaft,defshaft]);
    
    b =     [0.61, 0.97, 1.47, 2.41, 3.48][num];
    e =     [0.31, 0.435, 0.815, 2.005, 2.415][num];
//    e =     [0.31, 0.435, 0.815, 2.1505, 2.415][num];    
    g =     [0.81, 1.27, 2.29, 3.81, 5.08][num];
    //f =     [0.33, 0.53, 0.70, 0.82, 1.23][num];
    //r =     [0.30, 0.50, 0.60, 0.80, 1.00][num];
    alpha = [ 136,  138,  140,  146,  153][num];
    beta  = [7.00, 7.00, 5.75, 5.75, 7.00][num];
    gamma = 92.0;
    ang1 = 28.0;
    ang2 = 26.5;
    h1 = adj_ang_to_opp(g/2, ang1);   // height of the small conical tip
    h2 = adj_ang_to_opp((shaft-g)/2, 90-ang2);   // height of larger cone
    h3 = adj_ang_to_opp(b/2, ang1);   // height where cutout starts
    p0 = [0,0];
    p1 = [adj_ang_to_opp(e/2, 90-alpha/2), -e/2];
    p2 = p1 + [adj_ang_to_opp((shaft-e)/2, 90-gamma/2),-(shaft-e)/2];
    attachable(anchor,spin,orient, d=shaft, l=l) {
        down(l/2) {
            difference() {
                rotate_extrude()
                    polygon([[0,0],[g/2,h1],[shaft/2,h1+h2],[shaft/2,l],[0,l]]);
                zrot(45)
                zrot_copies(n=4, r=b/2) {                   
                    up(h3) {
                        yrot(beta) { 
                            linear_extrude(height=(h1+h2)*20, convexity=4, center=false) {
                                path = [p0, p1, p2, [p2.x,-p2.y], [p1.x,-p1.y]];
                                polygon(path);
                            }
                        }
                    }
                }
            }
        }
        children();
    }
}


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
