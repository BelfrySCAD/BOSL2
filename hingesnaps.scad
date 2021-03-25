//////////////////////////////////////////////////////////////////////
// LibFile: hingesnaps.scad
//   Useful hinge mask and snaps shapes.
// Includes:
//   include <BOSL2/std.scad>
//   include <BOSL2/hingesnaps.scad>
//////////////////////////////////////////////////////////////////////

// Section: Hinges and Snaps

// Module: folding_hinge_mask()
// Usage:
//   folding_hinge_mask(l, thick, [layerheight], [foldangle], [hingegap], [anchor], [spin], [orient]);
// Description:
//   Creates a mask to be differenced away from a plate to create a foldable hinge.
//   Center the mask at the bottom of the plate you want to make a hinge in.
//   The mask will leave  hinge material two `layerheight`s thick on the bottom of the hinge.
// Arguments:
//   l = Length of the hinge in mm.
//   thick = Thickness in mm of the material to make the hinge in.
//   layerheight = The expected printing layer height in mm.
//   foldangle = The interior angle in degrees of the joint to be created with the hinge.  Default: 90
//   hingegap = Size in mm of the gap at the bottom of the hinge, to make room for folding.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards.  See [orient](attachments.scad#orient).  Default: `UP`
// Example:
//   folding_hinge_mask(l=100, thick=3, foldangle=60);
module folding_hinge_mask(l, thick, layerheight=0.2, foldangle=90, hingegap=undef, anchor=CENTER, spin=0, orient=UP)
{
    hingegap = default(hingegap, layerheight)+2*$slop;
    size = [l, hingegap, 2*thick];
    size2 = [l, hingegap+2*thick*tan(foldangle/2)];
    attachable(anchor,spin,orient, size=size, size2=size2) {
        up(layerheight*2) prismoid([l,hingegap], [l, hingegap+2*thick/tan(foldangle/2)], h=thick, anchor=BOT);
        children();
    }
}


// Module: snap_lock()
// Usage:
//   snap_lock(thick, [snaplen], [snapdiam], [layerheight], [foldangle], [hingegap], [anchor], [spin], [orient]);
// Description:
//   Creates the central snaplock part.
// Arguments:
//   thick = Thickness in mm of the material to make the hinge in.
//   snaplen = Length of locking snaps.
//   snapdiam = Diameter/width of locking snaps.
//   layerheight = The expected printing layer height in mm.
//   foldangle = The interior angle in degrees of the joint to be created with the hinge.  Default: 90
//   hingegap = Size in mm of the gap at the bottom of the hinge, to make room for folding.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards.  See [orient](attachments.scad#orient).  Default: `UP`
// Example:
//   snap_lock(thick=3, foldangle=60);
module snap_lock(thick, snaplen=5, snapdiam=5, layerheight=0.2, foldangle=90, hingegap=undef, anchor=CENTER, spin=0, orient=UP)
{
    hingegap = default(hingegap, layerheight)+2*$slop;
    snap_x = (snapdiam/2) / tan(foldangle/2) + (thick-2*layerheight)/tan(foldangle/2) + hingegap/2;
    size = [snaplen, snapdiam, 2*thick];
    attachable(anchor,spin,orient, size=size) {
        back(snap_x) {
            cube([snaplen, snapdiam, snapdiam/2+thick], anchor=BOT) {
                attach(TOP) xcyl(l=snaplen, d=snapdiam, $fn=16);
                attach(TOP) xcopies(snaplen-snapdiam/4/3) xscale(0.333) sphere(d=snapdiam*0.8, $fn=12);
            }
        }
        children();
    }
}


// Module: snap_socket()
// Usage:
//   snap_socket(thick, [snaplen], [snapdiam], [layerheight], [foldangle], [hingegap], [anchor], [spin], [orient]);
// Description:
//   Creates the outside snaplock socketed part.
// Arguments:
//   thick = Thickness in mm of the material to make the hinge in.
//   snaplen = Length of locking snaps.
//   snapdiam = Diameter/width of locking snaps.
//   layerheight = The expected printing layer height in mm.
//   foldangle = The interior angle in degrees of the joint to be created with the hinge.  Default: 90
//   hingegap = Size in mm of the gap at the bottom of the hinge, to make room for folding.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards.  See [orient](attachments.scad#orient).  Default: `UP`
// Example:
//   snap_socket(thick=3, foldangle=60);
module snap_socket(thick, snaplen=5, snapdiam=5, layerheight=0.2, foldangle=90, hingegap=undef, anchor=CENTER, spin=0, orient=UP)
{
    hingegap = default(hingegap, layerheight)+2*$slop;
    snap_x = (snapdiam/2) / tan(foldangle/2) + (thick-2*layerheight)/tan(foldangle/2) + hingegap/2;
    size = [snaplen, snapdiam, 2*thick];
    attachable(anchor,spin,orient, size=size) {
        fwd(snap_x) {
            zrot_copies([0,180], r=snaplen+$slop) {
                diff("divot")
                cube([snaplen, snapdiam, snapdiam/2+thick], anchor=BOT) {
                    attach(TOP) xcyl(l=snaplen, d=snapdiam, $fn=16);
                    attach(TOP) left((snaplen+snapdiam/4/3)/2) xscale(0.333) sphere(d=snapdiam*0.8, $fn=12, $tags="divot");
                }
            }
        }
        children();
    }
}


// Module: apply_folding_hinges_and_snaps()
// Usage:
//   apply_folding_hinges_and_snaps(thick, [foldangle], [hinges], [snaps], [sockets], [snaplen], [snapdiam], [hingegap], [layerheight]) ...
// Description:
//   Adds snaplocks and removes hinges from children objects at the given positions.
// Arguments:
//   thick = Thickness in mm of the material to make the hinge in.
//   foldangle = The interior angle in degrees of the joint to be created with the hinge.  Default: 90
//   hinges = List of [LENGTH, POSITION, SPIN] for each hinge to difference from the children.
//   snaps = List of [POSITION, SPIN] for each central snaplock to add to the children.
//   sockets = List of [POSITION, SPIN] for each outer snaplock sockets to add to the children.
//   snaplen = Length of locking snaps.
//   snapdiam = Diameter/width of locking snaps.
//   hingegap = Size in mm of the gap at the bottom of the hinge, to make room for folding.
//   layerheight = The expected printing layer height in mm.
// Example(Med):
//   size=100;
//   apply_folding_hinges_and_snaps(
//       thick=3, foldangle=54.74,
//       hinges=[
//           for (a=[0,120,240], b=[-size/2,size/4]) each [
//               [200, polar_to_xy(b,a), a+90]
//           ]
//       ],
//       snaps=[
//           for (a=[0,120,240]) each [
//               [rot(a,p=[ size/4, 0        ]), a+90],
//               [rot(a,p=[-size/2,-size/2.33]), a-90]
//           ]
//       ],
//       sockets=[
//           for (a=[0,120,240]) each [
//               [rot(a,p=[ size/4, 0        ]), a+90],
//               [rot(a,p=[-size/2, size/2.33]), a+90]
//           ]
//       ]
//   ) {
//       $fn=3;
//       difference() {
//           cylinder(r=size-1, h=3);
//           down(0.01) cylinder(r=size/4.5, h=3.1, spin=180);
//           down(0.01) for (a=[0:120:359.9]) zrot(a) right(size/2) cylinder(r=size/4.5, h=3.1);
//       }
//   }
module apply_folding_hinges_and_snaps(thick, foldangle=90, hinges=[], snaps=[], sockets=[], snaplen=5, snapdiam=5, hingegap=undef, layerheight=0.2)
{
    hingegap = default(hingegap, layerheight)+2*$slop;
    difference() {
        children();
        for (hinge = hinges) {
            translate(hinge[1]) {
                folding_hinge_mask(
                    l=hinge[0], thick=thick, layerheight=layerheight,
                    foldangle=foldangle, hingegap=hingegap, spin=hinge[2]
                );
            }
        }
    }
    for (snap = snaps) {
        translate(snap[0]) {
            snap_lock(
                thick=thick, snaplen=snaplen, snapdiam=snapdiam,
                layerheight=layerheight, foldangle=foldangle,
                hingegap=hingegap, spin=snap[1]
            );
        }
    }
    for (socket = sockets) {
        translate(socket[0]) {
            snap_socket(
                thick=thick, snaplen=snaplen, snapdiam=snapdiam,
                layerheight=layerheight, foldangle=foldangle,
                hingegap=hingegap, spin=socket[1]
            );
        }
    }
}


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
