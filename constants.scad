//////////////////////////////////////////////////////////////////////
// LibFile: constants.scad
//   Useful Constants.
//   To use this, add the following line to the top of your file.
//   ```
//   include <BOSL2/std.scad>
//   ```
//////////////////////////////////////////////////////////////////////


// Section: General Constants

PRINTER_SLOP = 0.20;  // The printer specific amount of slop in mm to print with to make parts fit exactly.  You may need to override this value for your printer.



// Section: Directional Vectors
//   Vectors useful for `rotate()`, `mirror()`, and `anchor` arguments for `cuboid()`, `cyl()`, etc.

// Constant: LEFT
// Description: Vector pointing left.  [-1,0,0]
// Example(3D): Usage with `anchor`
//   cuboid(20, anchor=LEFT);
LEFT  = [-1,  0,  0];

// Constant: RIGHT
// Description: Vector pointing right.  [1,0,0]
// Example(3D): Usage with `anchor`
//   cuboid(20, anchor=RIGHT);
RIGHT = [ 1,  0,  0];

// Constant: FRONT
// Description: Vector pointing forward.  [0,-1,0]
// Example(3D): Usage with `anchor`
//   cuboid(20, anchor=FRONT);
FRONT = [ 0, -1,  0];

// Constant: BACK
// Description: Vector pointing back.  [0,1,0]
// Example(3D): Usage with `anchor`
//   cuboid(20, anchor=BACK);
BACK  = [ 0,  1,  0];

// Constant: BOTTOM
// Description: Vector pointing down.  [0,0,-1]
// Example(3D): Usage with `anchor`
//   cuboid(20, anchor=BOTTOM);
BOTTOM  = [ 0,  0, -1];

// Constant: TOP
// Description: Vector pointing up.  [0,0,1]
// Example(3D): Usage with `anchor`
//   cuboid(20, anchor=TOP);
TOP = [ 0,  0,  1];

// Constant: ALLPOS
// Description: Vector pointing right, back, and up.  [1,1,1]
// Example(3D): Usage with `anchor`
//     cuboid(20, anchor=ALLPOS);
ALLPOS = [ 1,  1,  1];  // Vector pointing X+,Y+,Z+.

// Constant: ALLNEG
// Description: Vector pointing left, forwards, and down.  [-1,-1,-1]
// Example(3D): Usage with `anchor`
//     cuboid(20, anchor=ALLNEG);
ALLNEG = [-1, -1, -1];  // Vector pointing X-,Y-,Z-.

// Constant: CENTER
// Description: Zero vector.  Centered.  [0,0,0]
// Example(3D): Usage with `anchor`
//     cuboid(20, anchor=CENTER);
CENTER = [ 0,  0,  0];  // Centered zero vector.


// Section: Vector Aliases
//   Useful aliases for use with `anchor`.

UP      = TOP;     // Vector pointing up, alias to `TOP`.
DOWN    = BOTTOM;  // Vector pointing down, alias to `BOTTOM`.
BTM     = BOTTOM;  // Vector pointing down, alias to `BOTTOM`.
BOT     = BOTTOM;  // Vector pointing down, alias to `BOTTOM`.
FWD     = FRONT;   // Vector pointing forward, alias to `FRONT`.
FORWARD = FRONT;   // Vector pointing forward, alias to `FRONT`.



// CommonCode:
//   orientations = [
//       ORIENT_X,        ORIENT_Y,        ORIENT_Z,
//       ORIENT_XNEG,     ORIENT_YNEG,     ORIENT_ZNEG,
//       ORIENT_X_90,     ORIENT_Y_90,     ORIENT_Z_90,
//       ORIENT_XNEG_90,  ORIENT_YNEG_90,  ORIENT_ZNEG_90,
//       ORIENT_X_180,    ORIENT_Y_180,    ORIENT_Z_180,
//       ORIENT_XNEG_180, ORIENT_YNEG_180, ORIENT_ZNEG_180,
//       ORIENT_X_270,    ORIENT_Y_270,    ORIENT_Z_270,
//       ORIENT_XNEG_270, ORIENT_YNEG_270, ORIENT_ZNEG_270
//   ];
//   axiscolors = ["red", "forestgreen", "dodgerblue"];
//   module text3d(text, h=0.01, size=3) {
//       linear_extrude(height=h, convexity=10) {
//           text(text=text, size=size, valign="center", halign="center");
//       }
//   }
//   module orient_cube(ang) {
//       color("lightgray") cube(20, center=true);
//       color(axiscolors.x) up  ((20-1)/2+0.01) back ((20-1)/2+0.01) cube([18,1,1], center=true);
//       color(axiscolors.y) up  ((20-1)/2+0.01) right((20-1)/2+0.01) cube([1,18,1], center=true);
//       color(axiscolors.z) back((20-1)/2+0.01) right((20-1)/2+0.01) cube([1,1,18], center=true);
//       for (axis=[0:2], neg=[0:1]) {
//           idx = axis + 3*neg + 6*ang/90;
//           rotate(orientations[idx]) {
//               up(10) {
//                   fwd(4) color("black") text3d(text=str(ang), size=4);
//                   back(4) color(axiscolors[axis]) text3d(text=str(["X","Y","Z"][axis], ["+","NEG"][neg]), size=4);
//               }
//           }
//       }
//   }


// Section: Standard Orientations
//   Orientations for `cyl()`, `prismoid()`, etc.  They take the form of standard [X,Y,Z]
//   rotation angles for rotating a vertical shape into the given orientations.
// Figure(Spin): Standard Orientations
//   orient_cube(0);

ORIENT_X        = [ 90,   0,  90];  // Orient along the X axis.
ORIENT_Y        = [ 90,   0, 180];  // Orient along the Y axis.
ORIENT_Z        = [  0,   0,   0];  // Orient along the Z axis.
ORIENT_XNEG     = [ 90,   0, -90];  // Orient reversed along the X axis.
ORIENT_YNEG     = [ 90,   0,   0];  // Orient reversed along the Y axis.
ORIENT_ZNEG     = [  0, 180,   0];  // Orient reversed along the Z axis.


// Section: Orientations Rotated 90º
//   Orientations for `cyl()`, `prismoid()`, etc.  They take the form of standard [X,Y,Z]
//   rotation angles for rotating a vertical shape into the given orientations.
// Figure(Spin): Orientations Rotated 90º
//   orient_cube(90);

ORIENT_X_90     = [ 90, -90,  90];  // Orient along the X axis, then rotate 90 degrees counter-clockwise on that axis, as seen when facing the origin from that axis orientation.
ORIENT_Y_90     = [ 90, -90, 180];  // Orient along the Y axis, then rotate 90 degrees counter-clockwise on that axis, as seen when facing the origin from that axis orientation.
ORIENT_Z_90     = [  0,   0,  90];  // Orient along the Z axis, then rotate 90 degrees counter-clockwise on that axis, as seen when facing the origin from that axis orientation.
ORIENT_XNEG_90  = [  0, -90,   0];  // Orient reversed along the X axis, then rotate 90 degrees counter-clockwise on that axis, as seen when facing the origin from that axis orientation.
ORIENT_YNEG_90  = [ 90, -90,   0];  // Orient reversed along the Y axis, then rotate 90 degrees counter-clockwise on that axis, as seen when facing the origin from that axis orientation.
ORIENT_ZNEG_90  = [  0, 180, -90];  // Orient reversed along the Z axis, then rotate 90 degrees counter-clockwise on that axis, as seen when facing the origin from that axis orientation.


// Section: Orientations Rotated 180º
//   Orientations for `cyl()`, `prismoid()`, etc.  They take the form of standard [X,Y,Z]
//   rotation angles for rotating a vertical shape into the given orientations.
// Figure(Spin): Orientations Rotated 180º
//   orient_cube(180);

ORIENT_X_180    = [-90,   0, -90];  // Orient along the X axis, then rotate 180 degrees counter-clockwise on that axis, as seen when facing the origin from that axis orientation.
ORIENT_Y_180    = [-90,   0,   0];  // Orient along the Y axis, then rotate 180 degrees counter-clockwise on that axis, as seen when facing the origin from that axis orientation.
ORIENT_Z_180    = [  0,   0, 180];  // Orient along the Z axis, then rotate 180 degrees counter-clockwise on that axis, as seen when facing the origin from that axis orientation.
ORIENT_XNEG_180 = [-90,   0,  90];  // Orient reversed along the X axis, then rotate 180 degrees counter-clockwise on that axis, as seen when facing the origin from that axis orientation.
ORIENT_YNEG_180 = [-90,   0, 180];  // Orient reversed along the Y axis, then rotate 180 degrees counter-clockwise on that axis, as seen when facing the origin from that axis orientation.
ORIENT_ZNEG_180 = [  0, 180, 180];  // Orient reversed along the Z axis, then rotate 180 degrees counter-clockwise on that axis, as seen when facing the origin from that axis orientation.


// Section: Orientations Rotated 270º
//   Orientations for `cyl()`, `prismoid()`, etc.  They take the form of standard [X,Y,Z]
//   rotation angles for rotating a vertical shape into the given orientations.
// Figure(Spin): Orientations Rotated 270º
//   orient_cube(270);

ORIENT_X_270    = [ 90,  90,  90];  // Orient along the X axis, then rotate 270 degrees counter-clockwise on that axis, as seen when facing the origin from that axis orientation.
ORIENT_Y_270    = [ 90,  90, 180];  // Orient along the Y axis, then rotate 270 degrees counter-clockwise on that axis, as seen when facing the origin from that axis orientation.
ORIENT_Z_270    = [  0,   0, -90];  // Orient along the Z axis, then rotate 270 degrees counter-clockwise on that axis, as seen when facing the origin from that axis orientation.
ORIENT_XNEG_270 = [ 90,  90, -90];  // Orient reversed along the X axis, then rotate 270 degrees counter-clockwise on that axis, as seen when facing the origin from that axis orientation.
ORIENT_YNEG_270 = [ 90,  90,   0];  // Orient reversed along the Y axis, then rotate 270 degrees counter-clockwise on that axis, as seen when facing the origin from that axis orientation.
ORIENT_ZNEG_270 = [  0, 180,  90];  // Orient reversed along the Z axis, then rotate 270 degrees counter-clockwise on that axis, as seen when facing the origin from that axis orientation.


// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
