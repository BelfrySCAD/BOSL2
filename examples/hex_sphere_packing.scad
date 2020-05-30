include <BOSL2/std.scad>

//$fa=2;
//$fs=2;

s = 20;
xyr = adj_ang_to_hyp(s/2,30);
h = hyp_adj_to_opp(s,xyr);
zcopies(h,n=8) union()
    back(($idx%2)*xyr*cos(60))
        grid2d(s,n=[12,7],stagger=($idx%2)? "alt" : true)
            sphere(d=s);


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
