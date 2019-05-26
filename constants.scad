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
//   cuboid(20, anchor=ALLPOS);
ALLPOS = [ 1,  1,  1];  // Vector pointing X+,Y+,Z+.

// Constant: ALLNEG
// Description: Vector pointing left, forwards, and down.  [-1,-1,-1]
// Example(3D): Usage with `anchor`
//   cuboid(20, anchor=ALLNEG);
ALLNEG = [-1, -1, -1];  // Vector pointing X-,Y-,Z-.

// Constant: CENTER
// Description: Zero vector.  Centered.  [0,0,0]
// Example(3D): Usage with `anchor`
//   cuboid(20, anchor=CENTER);
CENTER = [ 0,  0,  0];  // Centered zero vector.


// Section: Vector Aliases
//   Useful aliases for use with `anchor`.

CTR     = CENTER;  // Zero vector, `[0,0,0]`.  Alias to `CENTER`.
UP      = TOP;     // Vector pointing up, alias to `TOP`.
DOWN    = BOTTOM;  // Vector pointing down, alias to `BOTTOM`.
BTM     = BOTTOM;  // Vector pointing down, alias to `BOTTOM`.
BOT     = BOTTOM;  // Vector pointing down, alias to `BOTTOM`.
FWD     = FRONT;   // Vector pointing forward, alias to `FRONT`.
FORWARD = FRONT;   // Vector pointing forward, alias to `FRONT`.



// CommonCode:
//   orientations = [
//       RIGHT,  BACK,    UP,
//       LEFT,   FWD,     DOWN,
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
//           idx = axis + 3*neg;
//           rot(ang, from=UP, to=orientations[idx]) {
//               up(10) {
//                   fwd(4) color("black") text3d(text=str(ang), size=4);
//                   back(4) color(axiscolors[axis]) text3d(text=str(["X","Y","Z"][axis], ["+","NEG"][neg]), size=4);
//               }
//           }
//       }
//   }



// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
