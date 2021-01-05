//////////////////////////////////////////////////////////////////////
// LibFile: knurling.scad
//   Shapes and masks for knurling cylinders.
// Includes:
//   include <BOSL2/std.scad>
//   include <BOSL2/knurling.scad>
//////////////////////////////////////////////////////////////////////


// Section: Knurling


// Module: knurled_cylinder()
// Usage:
//   knurled_cylinder(l, r|d, [overage], [count], [profile], [helix]);
//   knurled_cylinder(l, r1|d1, r2|d2, [overage], [count], [profile], [helix]);
// Description:
//   Creates a mask to difference from a cylinder to give it a knurled surface.
// Arguments:
//   l = The length of the axis of the mask.  Default: 10
//   overage = Extra backing to the mask.  Default: 5
//   r = The radius of the cylinder to knurl.  Default: 10
//   r1 = The radius of the bottom of the conical cylinder to knurl.
//   r2 = The radius of the top of the conical cylinder to knurl.
//   d = The diameter of the cylinder to knurl.
//   d1 = The diameter of the bottom of the conical cylinder to knurl.
//   d2 = The diameter of the top of the conical cylinder to knurl.
//   count = The number of grooves to have around the surface of the cylinder.  Default: 30
//   profile = The angle of the bottom of the groove, in degrees.  Default 120
//   helix = The helical angle of the grooves, in degrees.  Default: 30
//   chamfer = The size of the chamfers on the ends of the cylinder.  Default: none.
//   chamfer1 = The size of the chamfer on the bottom end of the cylinder.  Default: none.
//   chamfer2 = The size of the chamfer on the top end of the cylinder.  Default: none.
//   chamfang = The angle in degrees of the chamfers on the ends of the cylinder.
//   chamfang1 = The angle in degrees of the chamfer on the bottom end of the cylinder.
//   chamfang2 = The angle in degrees of the chamfer on the top end of the cylinder.
//   from_end = If true, chamfer is measured from the end of the cylinder, instead of inset from the edge.  Default: `false`.
//   rounding = The radius of the rounding on the ends of the cylinder.  Default: none.
//   rounding1 = The radius of the rounding on the bottom end of the cylinder.
//   rounding2 = The radius of the rounding on the top end of the cylinder.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards.  See [orient](attachments.scad#orient).  Default: `UP`
// Examples(Med):
//   knurled_cylinder(l=30, r=20, count=30, profile=120, helix=45);
//   knurled_cylinder(l=30, r=20, count=30, profile=120, helix=30);
//   knurled_cylinder(l=30, r=20, count=30, profile=90, helix=30);
//   knurled_cylinder(l=30, r=20, count=20, profile=120, helix=30);
module knurled_cylinder(
    l=20,
    r=undef, r1=undef, r2=undef,
    d=undef, d1=undef, d2=undef,
    count=30, profile=120, helix=30,
    chamfer=undef, chamfer1=undef, chamfer2=undef,
    chamfang=undef, chamfang1=undef, chamfang2=undef,
    from_end=false,
    rounding=undef, rounding1=undef, rounding2=undef,
    anchor=CENTER, spin=0, orient=UP
) {
    r1 = get_radius(r1=r1, r=r, d1=d1, d=d, dflt=10);
    r2 = get_radius(r1=r2, r=r, d1=d2, d=d, dflt=10);
    inset = r1 * sin(180/count) / tan(profile/2);
    twist = 360*l*tan(helix)/(r1*2*PI);
    c1 = circle(r=r1,$fn=count);
    c2 = rot(-180/count,p=circle(r=r1-inset,$fn=count));
    path = [for (i=idx(c1)) each [c1[i],c2[i]]];
    knob_w = 2*PI*r1/count;
    knob_h = knob_w / tan(helix);
    layers = ceil(l/knob_h);
    plen = len(path);
    vertices = concat(
        [
            for (layer = [0:1:layers], pt=path)
                (layer%2)? [pt.x, pt.y, layer*knob_h-layers*knob_h/2] :
                rot(180/count, p=[pt.x, pt.y, layer*knob_h-layers*knob_h/2])
        ], [
            [0,0,-layers*knob_h/2],
            [0,0, layers*knob_h/2]
        ]
    );
    faces = concat(
        [
            for (layer = [0:1:layers-1], i=idx(path)) let(
                loff = (layer%2)? 2 : 0,
                i1 = layer*plen+((i+1)%plen),
                i2 = layer*plen+((i+2)%plen),
                i3 = (layer+1)*plen+posmod(i+1+loff,plen),
                i4 = (layer+1)*plen+posmod(i+2+loff,plen),
                i5 = (layer+1)*plen+posmod(i-0+loff,plen),
                i6 = (layer+1)*plen+posmod(i-1+loff,plen)
            ) each [
                [i1, i2, ((i%2)? i5 : i3)],
                [i3, i5, ((i%2)? i2 : i1)]
            ]
        ], [
            for (i=[0:1:count-1]) let(
                i1 = posmod(i*2+1,plen),
                i2 = posmod(i*2+2,plen),
                i3 = posmod(i*2+3,plen),
                loff = layers*plen
            ) each [
                [i1,i3,i2],
                [i1+loff,i2+loff,i3+loff],
                [i3,i1,len(vertices)-2],
                [i1+loff,i3+loff,len(vertices)-1]
            ]
        ]
    );
    attachable(anchor,spin,orient, r1=r1, r2=r2, l=l) {
        intersection() {
            polyhedron(points=vertices, faces=faces, convexity=2*layers);
            cyl(
                r1=r1, r2=r2, l=l,
                chamfer=chamfer, chamfer1=chamfer1, chamfer2=chamfer2,
                chamfang=chamfang, chamfang1=chamfang1, chamfang2=chamfang2,
                from_end=from_end,
                rounding=rounding, rounding1=rounding1, rounding2=rounding2, 
                $fn=count*2
            );
        }
        children();
    }
}


// Module: knurled_cylinder_mask()
// Usage:
//   knurled_cylinder_mask(l, r|d, [overage], [count], [profile], [helix]);
//   knurled_cylinder_mask(l, r1|d1, r2|d2, [overage], [count], [profile], [helix]);
// Description:
//   Creates a mask to difference from a cylinder to give it a knurled surface.
// Arguments:
//   l = The length of the axis of the mask.  Default: 10
//   overage = Extra backing to the mask.  Default: 5
//   r = The radius of the cylinder to knurl.  Default: 10
//   r1 = The radius of the bottom of the conical cylinder to knurl.
//   r2 = The radius of the top of the conical cylinder to knurl.
//   d = The diameter of the cylinder to knurl.
//   d1 = The diameter of the bottom of the conical cylinder to knurl.
//   d2 = The diameter of the top of the conical cylinder to knurl.
//   count = The number of grooves to have around the surface of the cylinder.  Default: 30
//   profile = The angle of the bottom of the groove, in degrees.  Default 120
//   helix = The helical angle of the grooves, in degrees.  Default: 30
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis.  See [spin](attachments.scad#spin).  Default: `0`
//   orient = Vector to rotate top towards.  See [orient](attachments.scad#orient).  Default: `UP`
// Examples:
//   knurled_cylinder_mask(l=30, r=20, overage=5, profile=120, helix=30);
//   knurled_cylinder_mask(l=30, r=20, overage=10, profile=120, helix=30);
module knurled_cylinder_mask(
    l=10, overage=5,
    r=undef, r1=undef, r2=undef,
    d=undef, d1=undef, d2=undef,
    count=30, profile=120, helix=30,
    anchor=CENTER, spin=0, orient=UP
) {
    r1 = get_radius(r1=r1, r=r, d1=d1, d=d, dflt=10);
    r2 = get_radius(r1=r2, r=r, d1=d2, d=d, dflt=10);
    attachable(anchor,spin,orient, r1=r1, r2=r2, l=l) {
        difference() {
            cylinder(r1=r1+overage, r2=r2+overage, h=l, center=true);
            knurled_cylinder(r1=r1, r2=r2, l=l+0.01);
        }
        children();
    }
}


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
