include <BOSL2/std.scad>
include <BOSL2/paths.scad>
include <BOSL2/beziers.scad>

module leaf(s) {
    path = [
        [0,0], [1.5,-1],
        [2,1], [0,3], [-2,1],
        [-1.5,-1], [0,0]
    ];
    xrot(90)
    linear_extrude(height=0.02)
        bezier_polygon(path*s/2);
}

module branches(minsize, s1, s2){
    if(s2>minsize) {
        attach(TOP)
        zrot(gaussian_rands(90,20)[0])
        zrot_copies(n=floor(log_rands(2,5,4)[0]))
        zrot(gaussian_rands(0,5)[0])
        yrot(gaussian_rands(30,10)[0]) {
            sc = gaussian_rands(0.7,0.05)[0];
            cylinder(d1=s2, d2=s2*sc, l=s1)
                branches(minsize, s1*sc, s2*sc);
        }
    } else {
        recolor("springgreen")
        attach(TOP) zrot(90)
        leaf(gaussian_rands(100,5)[0]);
    }
}

module tree(h, d, minsize) {
    sc = gaussian_rands(0.7,0.05)[0];
    recolor("lightgray") {
        cylinder(d1=d, d2=d*sc, l=h) {
            branches(minsize, h, d*sc);
        }
    }
}

tree(d=300, h=1500, minsize=10);


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
