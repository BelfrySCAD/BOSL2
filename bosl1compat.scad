module translate_copies(a=[[0,0,0]]) move_copies(a) children();

module xspread(spacing, n, l, sp) xcopies(spacing=spacing, n=n, l=l, sp=sp) children();
module yspread(spacing, n, l, sp) ycopies(spacing=spacing, n=n, l=l, sp=sp) children();
module zspread(spacing, n, l, sp) zcopies(spacing=spacing, n=n, l=l, sp=sp) children();

module spread(p1=[0,0,0], p2=[10,0,0], spacing, l, n=2) line_copies(p1=p1, p2=p2, spacing=spacing, l=l, n=n) children();
module grid_of(xa=[0],ya=[0],za=[0],count,spacing) grid3d(xa=xa, ya=ya, za=za, n=count, spacing=spacing) children();

module xring(n=2,r=0,sa=0,cp=[0,0,0],rot=true) xrot_copies(n=n,r=r,sa=sa,cp=cp,subrot=rot) children();
module yring(n=2,r=0,sa=0,cp=[0,0,0],rot=true) yrot_copies(n=n,r=r,sa=sa,cp=cp,subrot=rot) children();
module zring(n=2,r=0,sa=0,cp=[0,0,0],rot=true) zrot_copies(n=n,r=r,sa=sa,cp=cp,subrot=rot) children();

module leftcube(size) cube(size, anchor=RIGHT);
module rightcube(size) cube(size, anchor=LEFT);
module fwdcube(size) cube(size, anchor=BACK);
module backcube(size) cube(size, anchor=FWD);
module downcube(size) cube(size, anchor=TOP);
module upcube(size) cube(size, anchor=BOT);

module cube2pt(p1,p2) cuboid(p1=p1,p2=p2);
module offsetcube(size=[1,1,1],v=[0,0,0]) cuboid(size,anchor=-v);
module rrect(size=[1,1,1], r=0.25, center=false) cuboid(size,rounding=r,edges="Z",anchor=center?CENTER:BOT);
module rcube(size=[1,1,1], r=0.25, center=false) cuboid(size,rounding=r,anchor=center?CENTER:BOT);
module chamfcube(size=[1,1,1],chamfer=0.25,chamfaxes=[1,1,1],chamfcorners=false) {
    cuboid(
        size=size, chamfer=chamfer,
        trimcorners=chamfcorners,
        edges=[
            if (chamfaxes.x) "X",
            if (chamfaxes.y) "Y",
            if (chamfaxes.z) "Z",
        ]
    );
}

module trapezoid(size1=[1,1], size2=[1,1], h=1, shift=[0,0], align=CTR, orient=0, center)
    prismoid(size1=size1, size2=size2, h=h, shift=shift, spin=orient, anchor=center==undef? -align : center?CENTER:BOT);

module pyramid(n=4, h=1, l=1, r, d, circum=false) {
    radius = get_radius(r=r, d=d, dflt=l/2/sin(180/n));
    cyl(r1=radius, r2=0, l=h, circum=circum, $fn=n, realign=true, anchor=BOT);
}

module prism(n=3, h=1, l=1, r, d, circum=false, center=false) {
    radius = get_radius(r=r, d=d, dflt=l/2/sin(180/n));
    cyl(r=radius, l=h, circum=circum, $fn=n, realign=true, anchor=center?CENTER:BOT);
}

module chamferred_cylinder(h,r,d,chamfer=0.25,chamfedge,angle=45,top=true,bottom=true,center=false) {
    chamf = chamfedge!=undef? chamfedge*sin(angle) : chamfer;
    cyl(h=h, r=r, d=d, chamfer1=(bottom?chamf:0), chamfer2=(top?chamf:0), chamfang=angle, anchor=center?CENTER:BOT);
}

module chamf_cyl(h=1, r, d, chamfer=0.25, chamfedge, angle=45, center=false, top=true, bottom=true) {
    chamf = chamfedge!=undef? chamfedge*sin(angle) : chamfer;
    cyl(h=h, r=r, d=d, chamfer1=(bottom?chamf:0), chamfer2=(top?chamf:0), chamfang=angle, anchor=center?CENTER:BOT);
}

module filleted_cylinder(h=1, r, d, r1, r2, d1, d2, fillet=0.25, center=false)
    cyl(l=h, r=r, d=d, r1=r1, r2=r2, d1=d1, d2=d2, rounding=fillet, anchor=center?CENTER:BOT);

module rcylinder(h=1, r=1, r1, r2, d, d1, d2, fillet=0.25, center=false)
    cyl(l=h, r=r, d=d, r1=r1, r2=r2, d1=d1, d2=d2, rounding=fillet, anchor=center?CENTER:BOT);

module thinning_brace(h=50, l=100, thick=5, ang=30, strut=5, wall=3, center=true)
    thinning_triangle(h=h, l=l, thick=thick, ang=ang, strut=strut, wall=wall, diagonly=true, center=center);


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap

