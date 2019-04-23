include <BOSL2/std.scad>

cube([20,4,4], anchor=TOP+FRONT) {
   attach(FRONT, BACK) cube([20,20,4]);
   attach(TOP, BOTTOM) cube([20,4,20]);
   attach(TOP+FRONT, norot=true) recolor("green") interior_fillet(l=20, r=10, orient=ORIENT_XNEG);
}
