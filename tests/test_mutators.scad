include <../std.scad>


module test_HSL() {
    for (h = [0:30:360]) {
        for (s = [0:0.2:1]) {
            for (l = [0:0.2:1]) {
                c = (1 - abs(2*l-1)) * s;
                x = c * (1 - abs(((h/60)%2)-1));
                m = l - c/2;
                rgb = [m,m,m] + (
                    h<= 60? [c,x,0] :
                    h<=120? [x,c,0] :
                    h<=180? [0,c,x] :
                    h<=240? [0,x,c] :
                    h<=300? [x,0,c] :
                            [c,0,x]
                );
                assert_approx(HSL(h,s,l), rgb, str_format("h={}, s={}, l={}", [h,s,l]));
            }
        }
    }
}
test_HSL();


module test_HSV() {
    for (h = [0:30:360]) {
        for (s = [0:0.2:1]) {
            for (v = [0:0.2:1]) {
                c = v * s;
                x = c * (1 - abs(((h/60)%2)-1));
                m = v - c;
                rgb = [m,m,m] + (
                    h<= 60? [c,x,0] :
                    h<=120? [x,c,0] :
                    h<=180? [0,c,x] :
                    h<=240? [0,x,c] :
                    h<=300? [x,0,c] :
                            [c,0,x]
                );
                assert_approx(HSV(h,s,v), rgb, str_format("h={}, s={}, v={}", [h,s,v]));
            }
        }
    }
}
test_HSV();


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
