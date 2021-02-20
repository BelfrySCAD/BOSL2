//////////////////////////////////////////////////////////////////////
// LibFile: constants.scad
//   Useful Constants.
// Includes:
//   include <BOSL2/std.scad>
//////////////////////////////////////////////////////////////////////


// Section: General Constants

// Constant: $slop
// Description:
//   The printer specific amount of slop in mm to print with to make parts fit exactly.
//   You may need to override this value for your printer.
$slop = 0.20;


// Constant: INCH
// Description:
//   The number of millimeters in an inch.
INCH = 25.4;



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

// Constant: CTR
// Description: Zero vector.  Centered.  `[0,0,0]`.  Alias to `CENTER`.
// Example(3D): Usage with `anchor`
//   cuboid(20, anchor=CTR);
CTR     = CENTER;

// Constant: UP
// Description: Vector pointing up.  [0,0,1]  Alias to `TOP`.
// Example(3D): Usage with `anchor`
//   cuboid(20, anchor=UP);
UP      = TOP;     // Vector pointing up, alias to `TOP`.

// Constant: DOWN
// Description: Vector pointing down.  [0,0,-1]  Alias to `BOTTOM`.
// Example(3D): Usage with `anchor`
//   cuboid(20, anchor=DOWN);
DOWN    = BOTTOM;  // Vector pointing down, alias to `BOTTOM`.

// Constant: BTM
// Description: Vector pointing down.  [0,0,-1]  Alias to `BOTTOM`.
// Example(3D): Usage with `anchor`
//   cuboid(20, anchor=BTM);
BTM     = BOTTOM;  // Vector pointing down, alias to `BOTTOM`.

// Constant: BOT
// Description: Vector pointing down.  [0,0,-1]  Alias to `BOTTOM`.
// Example(3D): Usage with `anchor`
//   cuboid(20, anchor=BOT);
BOT     = BOTTOM;  // Vector pointing down, alias to `BOTTOM`.

// Constant: FWD
// Description: Vector pointing forward.  [0,-1,0]  Alias to `FRONT`.
// Example(3D): Usage with `anchor`
//   cuboid(20, anchor=FWD);
FWD     = FRONT;   // Vector pointing forward, alias to `FRONT`.

// Constant: FORWARD
// Description: Vector pointing forward.  [0,-1,0]  Alias to `FRONT`.
// Example(3D): Usage with `anchor`
//   cuboid(20, anchor=FORWARD);
FORWARD = FRONT;   // Vector pointing forward, alias to `FRONT`.


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
