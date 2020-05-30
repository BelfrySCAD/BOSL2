include <BOSL2/std.scad>

//$fa=2;
//$fs=2;

s = 20;
s2 = s * sin(45);
zcopies(s2,n=8) union()
    grid2d([s2,s2],n=8,stagger=($idx%2)? true : "alt")
        sphere(d=s);


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
