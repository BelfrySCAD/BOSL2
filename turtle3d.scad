//////////////////////////////////////////////////////////////////////
// LibFile: turtle3d.scad
//   Three dimensional turtle graphics to generate 3d paths or sequences
//   of 3d transformations. 
// Includes:
//   include <BOSL2/std.scad>
//   include <BOSL2/turtle3d.scad>
// FileGroup: Advanced Modeling
// FileSummary: 3D turtle graphics for making paths or lists of transformations.
//////////////////////////////////////////////////////////////////////
include<structs.scad>

// Section: Functions

// Translation vector from a matrix
function _transpart(T) = [for(row=[0:2]) T[row][3]];

// The non-translation part of a matrix
function _rotpart(T) = [for(i=[0:3]) [for(j=[0:3]) j<3 || i==3 ? T[i][j] : 0]];


// Function: turtle3d()
// Synopsis: Extends [turtle graphics](https://en.wikipedia.org/wiki/Turtle_graphics) to 3d. Generates a 3D path or returns a list of transforms.
// SynTags: MatList, Path
// Topics: Shapes (3D), Path Generators (3D), Mini-Language
// See Also: turtle()
// Usage:
//   path = turtle3d(commands, [state=], [repeat=]);
//   mats = turtle3d(commands, transforms=true, [state=], [repeat=]);
//   state = turtle3d(commands, full_state=true, [state=], [repeat=]);
// Description:
//   Like the classic two dimensional turtle, the 3d turtle flies through space following a sequence
//   of turtle graphics commands to generate either a sequence of transformations (suitable for input
//   to {{sweep()}}) or a 3d path.
//   .
//   The turtle state keeps track of the position and orientation (including twist)
//   and scale of the turtle.  By default the turtle begins pointing along the X axis with the "right" direction
//   along the -Y axis and the "up" direction aligned with the Z axis.  You can give a direction vector
//   for the state input to change the starting direction.  You can also give a transformation for the state.
//   For example, if you want the turtle to start its trajectory at the coordinate [3,4,5] you could
//   give `state=move([3,4,5])`.
//   .
//   Because of the complexity of object positioning
//   in three space, some types of movement require compound commands.  These compound commands are lists that specify several operations
//   all applied to one turtle step.  For example:  ["move", 4, "twist", 25] executes a twist while moving, and
//   the command ["arc", 4, "grow", 2, "right", 45, "up", 30] turns to the right and up while also growing the object.
//   .
//   You can turn the turtle using relative commands, "right", "left", "up" and "down", which operate relative
//   to the turtle's current orientation.   This is sometimes confusing, so you can also use absolute
//   commands which turn the turtle relative to the absolute coordinate system, the "xrot", "yrot" and "zrot"
//   commands.  You can use "setdir" to point the turtle along a given vector.
//   If you want a valid transformation list for use with {{sweep()}} you will usually want to avoid abrupt changes
//   in the orientation of the turtle.  To do this, use the "arc"
//   forms for turns.  This form, with commands like "arcright" and "arcup" creates an arc with a gradual
//   change in the turtle orientation, which usually produces a better result for sweep operations.
//   .
//   Another potential problem for sweeps is a command that makes a movement that does not proceed in the turtle's current direction
//   such as "jump" or "untily".  These commands cause no issues when you trace out a path, but if you want a swept shape to
//   maintain a constant cross sectional shape then you need to avoid them.  
//   .
//   If you use sweep to convert a turtle path into a 3d shape the result depends both on the path the shape traces out but also
//   the twist and size of the shape.  The "twist" parameter described below to the compound commands has no effect on
//   the turtle orientation for the purpose of defining movement, but it will rotate the swept shape around the origin
//   as it traces out the path.  Similarly the "grow" and "shrink" options allow you to change the size of the swept
//   polygon without any effect on the turtle.  The "roll" command differs from "twist" in that it both rotates the swept
//   polygon but also changes the turtle's orientation, so it will alter subsequent operations of the turtle.  Note that
//   when making a path, "twist" will have no effect, but "roll" may have an effect because of how it changes the path.
//   After arcs it may be very confusing to understand exactly how the turtle is oriented in space.  The "rollto" option
//   lets you specify an "up" direction; the turtle will roll so its up matches, as well as possible, the direction you give.
//   (It will be the projection of your direction perpendicular to the turtle's direction of travel.)  The "lrollto" and "rrollto"
//   options are similar but force the rotational direction to be left or right respectively.  
//   .
//   The compound "move" command accepts a "reverse" argument.  If you specify "reverse" it reflects the
//   turtle direction to point backwards.  This enables you to back out to create a hollow shape.  But be
//   aware that everything is reversed, so turns will be the opposite direction.  So for example if you
//   used "arcright" on the outside you might expect arcleft when reversed on the inside, but it will
//   be "arcright" again.  (Note that "reverse" is the only command that appears by itself with no argument.)
//   .
//   By default you get a simple path (like the 2d turtle) which ignores growing/shrinking or twisting in the
//   transformation.  If you select transform=true then you will get a list of transformations returned.  Some of
//   of the commands are likely to produce transformation lists that are invalid for sweep.  The "jump" commands
//   can move in directions not perpendicular to the current direction of movement, which may produce bad results.
//   The turning commands like "left" or "up" can rotate the frame so that a sweep operation is invalid.
//   The `T` column in the list below marks commands that operate relative
//   to the current frame that should generally produce valid sweep transformations.
//   Be aware that it is possible to create a self intersection, and hence an invalid swept shape, if the radii of
//   arcs in turtle are smaller than the width of the polygon you use with sweep.  
//   .
//   The turtle state is a list containing:
//     - a list of path transformations, the transformations that move the turtle along the path
//     - a list of object transformations, the transformations that twist or scale the cross section as the turtle moves
//     - the current movement step size (scalar)
//     - the current default angle
//     - the current default arcsteps  
//   .
//   Commands   |T | Arguments          | What it does
//   ---------- |--| ------------------ | -------------------------------
//   "move"     |x | [dist]             | Move turtle scale*dist units in the turtle direction.  Default dist=1.  
//   "xmove"    |  | [dist]             | Move turtle scale*dist units in the x direction. Default dist=1.  Does not change turtle direction.
//   "ymove"    |  | [dist]             | Move turtle scale*dist units in the y direction. Default dist=1.  Does not change turtle direction.
//   "zmove"    |  | [dist]             | Move turtle scale*dist units in the y direction. Default dist=1.  Does not change turtle direction.
//   "xyzmove"  |  | vector             | Move turtle by the specified vector.  Does not change turtle direction. 
//   "untilx"   |x | xtarget            | Move turtle in turtle direction until x==xtarget.  Produces an error if xtarget is not reachable.
//   "untily"   |x | ytarget            | Move turtle in turtle direction until y==ytarget.  Produces an error if ytarget is not reachable.
//   "untilz"   |x | ztarget            | Move turtle in turtle direction until z==ztarget.  Produces an error if ztarget is not reachable.
//   "jump"     |  | point              | Move the turtle to the specified point
//   "xjump"    |  | x                  | Move the turtle's x position to the specified value
//   "yjump     |  | y                  | Move the turtle's y position to the specified value
//   "zjump     |  | z                  | Move the turtle's z position to the specified value
//   "left"     |  | [angle]            | Turn turtle left by specified angle or default angle
//   "right"    |  | [angle]            | Turn turtle to the right by specified angle or default angle
//   "up"       |  | [angle]            | Turn turtle up by specified angle or default angle
//   "down"     |  | [angle]            | Turn turtle down by specified angle or default angle
//   "xrot"     |x | [angle]            | Turn turtle around x-axis by specified angle or default angle
//   "yrot"     |x | [angle]            | Turn turtle around y-axis by specified angle or default angle
//   "zrot"     |x | [angle]            | Turn turtle around z-axis by specified angle or default angle
//   "rot"      |x | rotation           | Turn turtle by specified rotation relative to absolute coordinates
//   "angle"    |x | angle              | Set the default turn angle.
//   "setdir"   |  | vector             | Rotate the reference frame along the shortest path to specified direction
//   "length"   |x | length             | Change the turtle move distance to `length`
//   "scale"    |x | factor             | Multiply turtle move distances by `factor`.  Does not rescale the cross sectional shape in transformation lists.  
//   "addlength"|x | length             | Add `length` to the turtle move distance
//   "repeat"   |x | count, commands    | Repeats a list of commands `count` times.  (To repeat a compound command put it in a list: `[["move",10,"grow",2]]`)
//   "arcleft"  |x | radius, [angle]    | Draw an arc from the current position toward the left at the specified radius and angle.  The turtle turns by `angle`.
//   "arcright" |x | radius, [angle]    | Draw an arc from the current position toward the right at the specified radius and angle.  The turtle turns by `angle`.
//   "arcup"    |x | radius, [angle]    | Draw an arc from the current position upward at the specified radius and angle
//   "arcdown"  |x | radius, [angle]    | Draw an arc from the current position downward at the specified radius and angle
//   "arcxrot"  |x | radius, [angle]    | Draw an arc turning around x-axis by specified angle or default angle
//   "arcyrot"  |x | radius, [angle]    | Draw an arc turning around y-axis by specified angle or default angle
//   "arczrot"  |x | radius, [angle]    | Draw an arc turning around z-axis by specified angle or default angle
//   "arcrot"   |x | radius, rotation   | Draw an arc turning by the specified absolute rotation with given radius
//   "arctodir" |x | radius, vector     | Draw an arc turning to point in the (absolute) direction of given vector
//   "arcsteps" |x | count              | Specifies the number of segments to use for drawing arcs.  If you set it to zero then the standard `$fn`, `$fa` and `$fs` variables define the number of segments.
//   .
//   Compound commands are lists that group multiple commands to be applied simultaneously during a
//   turtle movement.  Example: `["move", 5, "shrink", 2]`.  The subcommands that may appear are
//   listed below.  Each compound command must begin with either "move" or "arc".  The order of
//   subcommands is not important.  Left/right turning is applied before up/down.  You cannot combine
//   "rot" or "todir" with any other turning commands.  
//   .
//   Subcommands  | Arguments          | What it does
//   ------------ | ------------------ | -------------------------------
//   "move"       | dist               | Compound command is a forward movement operation
//   "arc"        | radius             | Compound command traces an arc
//   "grow"       | factor             | Increase size by specified factor (e.g. 2 doubles the size); factor can be a 2-vector
//   "shrink"     | factor             | Decrease size by specified factor (e.g. 2 halves the size); factor can be a 2-vector
//   "twist"      | angle              | Twist by the specified angle over the arc or segment (does not change frame orientation)
//   "roll"       | angle              | Roll (right) by the specified angle over the arc or segment (changes the orientation of the frame)
//   "rollto"     | vector             | Roll by the shortest direction until the UP direction of the turtle is aligned as much as possible with the given vector direction
//   "lrollto"    | vector             | Roll left until the UP direction of the turtle is aligned as much as possible with the given vector direction
//   "rrollto"    | vector             | Roll right until the UP direction of the turtle is aligned as much as possible with the given vector direction
//   "steps"      | count              | Divide arc or segment into this many steps.  Default is 1 for segments without roll or twist, arcsteps otherwise
//   "reverse"    |                    | For "move" only: If given then reverses the turtle after the move
//   "right"      | angle              | For "arc" only: Turn to the right by specified angle
//   "left"       | angle              | For "arc" only: Turn to the left by specified angle
//   "up"         | angle              | For "arc" only: Turn up by specified angle
//   "down"       | angle              | For "arc" only: Turn down by specified angle
//   "xrot"       | angle              | For "arc" only: Absolute rotation around x axis. Cannot be combined with any other rotation.
//   "yrot"       | angle              | For "arc" only: Absolute rotation around y axis. Cannot be combined with any other rotation.
//   "zrot"       | angle              | For "arc" only: Absolute rotation around z axis. Cannot be combined with any other rotation.
//   "rot"        | rotation           | For "arc" only: Turn by specified absolute rotation as a matrix, e.g. xrot(33)*zrot(47).  Cannot be combined with any other rotation.
//   "todir"      | vector             | For "arc" only: Turn to point in the specified direction
//   .
//   The "twist", "shrink" and "grow" subcommands will only have an effect if you return a transformation list.  They do not
//   change the path the turtle traces.  The "roll" subcommand, on the other hand, changes the turtle frame orientation, so it can alter the path.
//   The "xrot", "yrot" and "zrot" subcommands can make turns larger than 180 degrees, and even larger than 360 degrees.  If you use "up",
//   "down", "left" or "right" alone then you can give any angle, but if you combine "up"/"down" with "left"/"right" then the specified
//   angles must be smaller than 180 degrees.  (This is because the algorithm decodes the rotation into an angle smaller than 180, so
//   the results are very strange if larger angles are permitted.)
// Arguments:
//   commands = List of turtle3d commands
//   state = Starting turtle direction, starting turtle transformation (e.g. move(pt)), or full turtle state (from a previous call).  Default: RIGHT
//   transforms = If true teturn list of transformations instead of points.  Default: false
//   full_state = If true return full turtle state for continuing the path in subsequent turtle calls.  Default: false
//   repeat = Number of times to repeat the command list.  Default: 1
// Example(3D): Angled rectangle
//   path = turtle3d(["up",25,"move","left","move",3,"left","move"]);
//   stroke(path,closed=true, width=.2);
// Example(3D): Path with rounded corners.  Note first and last point of the path are duplicates.  
//   r = 0.25;
//   path = turtle3d(["up",25,"move","arcleft",r,"move",3,"arcleft",r,"move","arcleft",r,"move",3,"arcleft",r]);
//   stroke(path,closed=true, width=.2);
// Example(3D): Non-coplanar figure
//   path = turtle3d(["up",25,"move","left","move",3,"up","left",0,"move"]);
//   stroke(path,closed=true, width=.2);
// Example(3D): Square spiral.  Note that the core twists because the "up" and "left" turns are relative to the previous turns.
//   include<BOSL2/skin.scad>
//   path = turtle3d(["move",10,"left","up",15],repeat=50);
//   path_sweep(circle(d=1, $fn=12), path);
// Example(3D): Square spiral, second try.  Use roll to create the spiral instead of turning up.  It still twists because the left turns are inclined.
//   include<BOSL2/skin.scad>
//   path = turtle3d(["move",10,"left","roll",10],repeat=50);
//   path_sweep(circle(d=1, $fn=12), path);
// Example(3D): Square spiral, third try.  One way to avoid the core twisting in the spiral is to use absolute turns.  Note that the vertical rise is controlled by the starting upward angle of the turtle, which is preserved as we rotate around the z axis.  
//   include<BOSL2/skin.scad>
//   path = turtle3d(["up", 5, "repeat", 12, ["move",10,"zrot"]]);
//   path_sweep(circle(d=1, $fn=12), path);
// Example(3D): Square spiral, rounded corners.  Careful use of rotations can work for sweep, but it may be better to round the corners.  Here we return a list of transforms and use sweep instead of path_sweep:
//   include<BOSL2/skin.scad>
//   path = turtle3d(["up", 5, "repeat", 12, ["move",10,"arczrot",4]],transforms=true);
//   sweep(circle(d=1, $fn=12), path);
// Example(3D): Mixing relative and absolute commands
//   include<BOSL2/skin.scad>
//   path = turtle3d(["repeat", 4, ["move",80,"arczrot",40],
//                    "arcyrot",40,-90,
//                    "move",40,
//                    "arcxrot",40,90,
//                    ["arc",14,"rot",xrot(90)*zrot(-33)],
//                    "move",80,
//                    "arcyrot",40,
//                    "arcup",40,
//                    "arcleft",40,
//                    "arcup",30,
//                    ["move",100,"twist",90,"steps",20],
//                   ],
//                   state=[1,0,.2],transforms=true);
//   ushape = rot(90,p=[[-10, 0],[-10, 10],[ -7, 10],[ -7, 2],[  7, 2],[  7, 7],[ 10, 7],[ 10, 0]]);
//   sweep(ushape, path);
// Example(3D): Generic helix, constructed by a sequence of movements and then rotations
//   include<BOSL2/skin.scad>
//   radius=14;       // Helix radius
//   pitch=20;        // Distance from one turn to the next
//   turns=3;         // Number of turns
//   turn_steps=32;   // Number of steps on each turn
//   axis = [1,4,1];  // Helix axis
//   up_angle = atan2(pitch,2*PI*radius);
//   helix = turtle3d([
//                      "up", up_angle,
//                      "zrot", 360/turn_steps/2,
//                      "rot", rot(from=UP,to=axis), // to correct the turtle direction
//                      "repeat", turn_steps*turns,
//                      [
//                       "move", norm([2*PI*radius, pitch])/turn_steps,
//                       "rot",  rot(360/turn_steps,v=axis)
//                      ],
//                     ], transforms=true);
//   sweep(subdivide_path(square([5,1]),20), helix);
// Example(3D): Helix generated by a single command.  Note this only works for x, y, or z aligned helixes because the generic rot cannot handle multi-turn angles.  
//   include<BOSL2/skin.scad>
//   pitch=20;       // Distance from one turn to the next
//   radius=14;      // Helix radius
//   turns=3;        // Number of turns
//   turn_steps=33;  // Steps on each turn
//   up_angle = atan2(pitch,2*PI*radius);
//   helix = turtle3d([
//                     "up", up_angle,
//                     [
//                       "arc", radius,
//                       "zrot", 360*turns,
//                       "steps", turn_steps*turns,
//                     ]
//                    ], transforms=true);
//   sweep(subdivide_path(square([5,1]),80), helix);
// Example(3D): Expanding helix
//   include<BOSL2/skin.scad>
//   path = turtle3d(["length",.2,"angle",360/20,"up",5,"repeat",50,["move","zrot","addlength",0.05]]);
//   path_sweep(circle(d=1, $fn=12), path);
// Example(3D): Adding some twist to the model
//   include<BOSL2/skin.scad>
//   r = 2.5;
//   trans = turtle3d(["move",10,
//                     "arcleft",r,
//                     ["move",30,"twist",180,"steps",40],
//                     "arcleft",r,
//                     "move",10,
//                     "arcleft",r,
//                     ["move",30,"twist",360,"steps",40],
//                     "arcleft",r],
//                    state=yrot(25,p=RIGHT),transforms=true);
//   sweep(supershape(m1=4,n1=4,n2=16,n3=1.5,a=.9,b=9,step=5),trans);
// Example(3D): Twist does not change the turtle orientation, but roll does.  The only change from the previous example is twist was changed to roll.
//   include<BOSL2/skin.scad>
//   r = 2;
//   trans = turtle3d(["move",10,
//                     "arcleft",r,
//                     ["move",30,"roll",180,"steps",40],
//                     "arcleft",r,
//                     "move",10,
//                     "arcleft",r,
//                     ["move",30,"roll",360,"steps",40],
//                     "arcleft",r],
//                    state=yrot(25,p=RIGHT),transforms=true);
//   sweep(supershape(m1=4,n1=4,n2=16,n3=1.5,a=.9,b=9,step=5),trans);
// Example(3D): Use of shrink and grow
//   include<BOSL2/skin.scad>
//   $fn=32;
//   T = turtle3d([
//                 "move",10,
//                 ["arc",8,"right", 90, "twist", 90, "grow", 2],
//                 ["move", 5,"shrink",4,"steps",4],
//                 ["arc",8, "right", 45, "up", 90],
//                 "move", 10,
//                 "arcright", 5, 90,
//                 "arcleft", 5, 90,
//                 "arcup", 5, 90,
//                 "untily", -1,
//                ],state=RIGHT, transforms=true);   
//   sweep(square(2,center=true),T);
// Example(3D): After several moves you may not understand the turtle orientation. An absolute reorientation with "arctodir" is helpful to head in a known direction
//   include<BOSL2/skin.scad>
//   trans = turtle3d([
//                  "move",5,
//                  "arcup",1,
//                  "move",8,
//                  "arcright",1,
//                  "move",6,
//                  "arcdown",1,
//                  "move",4,
//                  ["arc",2,"right",45,"up",25,"roll",25],
//                  "untilz",4,
//                  "move",1,
//                  "arctodir",1,DOWN,
//                  "untilz",0
//                  ],transforms=true);
//   sweep(square(1,center=true),trans);
// Example(3D): The "grow" and "shrink" commands can take a vector giving x and y scaling
//   include<BOSL2/skin.scad>
//   tr = turtle3d([
//                   "move", 1.5, 
//                   ["move", 5, "grow", [1,2],  "steps", 10],
//                   ["move", 5, "grow", [2,0.5],"steps", 10]
//                  ], transforms=true);
//   sweep(circle($fn=32,r=1), tr);
// Example(3D): With "twist" added the anisotropic "grow" interacts with "twist", producing a complex form
//   include<BOSL2/skin.scad>
//   tr = turtle3d([
//                   "move", 1.5, 
//                   ["move", 5, "grow", [1,2],  "steps", 20, "twist",90],
//                   ["move", 5, "grow", [0.5,2],"steps", 20, "twist",90]
//                  ], transforms=true);
//   sweep(circle($fn=64,r=1), tr);
// Example(3D): Making a tube with "reverse".  Note that the move direction is the same even though the direction is reversed.  
//   include<BOSL2/skin.scad>
//   tr = turtle3d([ "move", 4,
//                   ["move",0, "grow", .8, "reverse"],
//                   "move", 4
//                 ],  transforms=true);
//   back_half(s=10)
//     sweep(circle(r=1,$fn=16), tr, closed=true);
// Example(3D): To close the tube at one end we set closed to false in sweep.  
//   include<BOSL2/skin.scad>
//   tr = turtle3d([ "move", 4,
//                   ["move",0, "grow", .8, "reverse"],
//                   "move", 3.75
//                 ],  transforms=true);
//   back_half(s=10)
//     sweep(circle(r=1,$fn=16), tr, closed=false);
// Example(3D): Cookie cutter using "reverse" 
//   include<BOSL2/skin.scad>
//   cutter = turtle3d( [ 
//                       ["move", 10, "shrink", 1.3, ],
//                       ["move", 2, "reverse" ],
//                       ["move", 8, "shrink", 1.3 ],
//                      ], transforms=true,state=UP);
//   cookie_shape = star(5, r=10, ir=5);
//   sweep(cookie_shape, cutter, closed=true);
// Example(3D): angled shopvac adapter.  Shopvac tubing wedges together because the tubes are slightly tapered.  We can make this part without using any difference() operations by using "reverse" to trace out the interior portion of the part.  Note that it's "arcright" even when reversed.  
//   inch = 25.4;
//   insert_ID = 2.3*inch;        // Size of shopvac tube at larger end of taper
//   wall = 1.7;                  // Desired wall thickness
//   seg1_bot_ID = insert_ID;     // Bottom section, to have tube inserted, specify ID
//   seg2_bot_OD = insert_ID+.03; // Top section inserts into a tube, so specify tapered OD
//   seg2_top_OD = 2.26*inch;     // The slightly oversized value gave me a better fit
//   seg1_len = 3*inch;           // Length of bottom section
//   seg2_len = 2*inch;           // Length of top section
//   bend_angle=45;               // Angle to bend, 45 or less to print without supports!
//   // Other diameters derived from the wall thickness
//   seg1_bot_OD = seg1_bot_ID+2*wall;
//   seg2_bot_ID = seg2_bot_OD-2*wall;
//   seg2_top_ID = seg2_top_OD-2*wall;
//   bend_r = 0.5*inch+seg1_bot_OD/2;   // Bend radius to get constant wall thickness
//   trans = turtle3d([
//                       ["move", seg1_len, "grow", seg2_bot_OD/seg1_bot_OD],  
//                       "arcright", bend_r, bend_angle,
//                       ["move", seg2_len, "grow", seg2_top_OD/seg2_bot_OD],
//                       ["move", 0, "reverse", "grow", seg2_top_ID/seg2_top_OD],
//                       ["move", seg2_len, "grow", seg2_bot_ID/seg2_top_ID],
//                       "arcright", bend_r, bend_angle,
//                       ["move", seg1_len, "grow", seg1_bot_ID/seg2_bot_ID]
//                    ],
//                    state=UP, transforms=true);
//   back_half(s=400)    // Remove this to get a usable part
//     sweep(circle(d=seg1_bot_OD, $fn=128), trans, closed=true);
// Example(3D): Closed spiral
//   include<BOSL2/skin.scad>
//   steps = 500;
//   spiral = turtle3d([
//                      ["arc", 20,
//                       "twist", 120,
//                       "zrot", 360*4,
//                       "steps",steps,
//                       "shrink",1.5],
//                      ["arc", 20,
//                       "twist", 120,
//                       "zrot", 360*4,
//                       "steps",steps/5 ],
//                      ["arc", 20,
//                       "twist", 120,
//                       "zrot", 360*4,
//                       "steps",steps,
//                       "grow",1.5],
//                      ], transforms=true);
//   sweep(fwd(25,p=circle(r=2,$fn=24)), spiral, caps=false);
// Example(3D): Mobius strip (square)
//   include<BOSL2/skin.scad>
//   mobius = turtle3d([["arc", 20, "zrot", 360,"steps",100,"twist",180]], transforms=true);
//   sweep(subdivide_path(square(8,center=true),16), mobius, closed=false);
// Example(3D): Torus knot
//   include<BOSL2/skin.scad>
//   p = 3;      // (number of turns)*gcd(p,q)
//   q = 10;     // (number of dives)*gcd(p,q)
//   steps = 60; // steps per turn
//   cordR  = 2; // knot cord radius
//   torusR = 20;// torus major radius
//   torusr = 4; // torus minor radius
//   knot_radius = torusr + 0.75*cordR; // inner radius of knot, set to torusr to put knot
//   wind_angle = atan(p / q *torusR / torusr);            // center on torus surface
//   m = gcd(p,q);
//   torus_knot0 =
//       turtle3d([ "arcsteps", 1,
//                  "repeat", p*steps/m-1 ,
//                     [ [ "arc", torusR, "left", 360/steps, "twist", 360*q/p/steps ] ]
//                ], transforms=true);
//   torus_knot = [for(tr=torus_knot0) tr*xrot(wind_angle+90)];
//   torus = turtle3d( ["arcsteps", steps, "arcleft", torusR, 360], transforms=true);
//   fwd(torusR){ // to center the torus and knot at the origin
//       color([.8,.7,1])
//         sweep(right(knot_radius,p=circle(cordR,$fn=16)), torus_knot,closed=true);
//       color("blue")
//         sweep(circle(torusr,$fn=24), torus);
//   }

/*
turtle state: sequence of transformations ("path") so far
              sequence of pre-transforms that apply to the polygon (scaling and twist)
              default move
              default angle
              default arc steps
*/

function _turtle3d_state_valid(state) =
    is_list(state)
        && is_consistent(state[0],ident(4))
        && is_consistent(state[1],ident(4))
        && is_num(state[2])
        && is_num(state[3])
        && is_num(state[4]);

module turtle3d(commands, state=RIGHT, transforms=false, full_state=false, repeat=1) {no_module();}
function turtle3d(commands, state=RIGHT, transforms=false, full_state=false, repeat=1) =
  assert(is_bool(transforms))
  let(
       state = is_matrix(state,4,4) ? [[state],[yrot(90)],1,90,0] :
               is_vector(state,3) ?
                  let( updir = UP - (UP * state) * state / (state*state) )
                  [[frame_map(x=state, z=approx(norm(updir),0) ? FWD : updir)], [yrot(90)],1, 90, 0]
                : assert(_turtle3d_state_valid(state), "Supplied state is not valid")
                  state,
       finalstate = _turtle3d_repeat(commands, state, repeat)
  )
    assert(is_integer(repeat) && repeat>=0, "turtle3d repeat argument must be a nonnegative integer")
    full_state  ? finalstate 
  : !transforms ? deduplicate([for(T=finalstate[0]) apply(T,[0,0,0])])
  : [for(i=idx(finalstate[0])) finalstate[0][i]*finalstate[1][i]];

function _turtle3d_repeat(commands, state, repeat) =
   repeat<=0 ? state : _turtle3d_repeat(commands, _turtle3d(commands, state), repeat-1);

function _turtle3d_command_len(commands, index) =
    let( one_or_two_arg = ["arcleft","arcright", "arcup", "arcdown", "arczrot", "arcyrot", "arcxrot"] )
    in_list(commands[index],["repeat","arctodir","arcrot"]) ? 3 :   // Repeat, arctodir and arcrot commands require 2 args
    // For these, the first arg is required, second arg is present if it is not a string or list
    in_list(commands[index], one_or_two_arg) && len(commands)>index+2 && !is_string(commands[index+2]) && !is_list(commands[index+2])  ? 3 :  
    is_string(commands[index+1]) || is_list(commands[index])? 1 :  // If 2nd item is a string it must be a new command; 
                                                                   // If first item is a list it's a compound command
    2;                                 // Otherwise we have command and arg
       
function _turtle3d(commands, state, index=0) =
    index >= len(commands) ? state :
    _turtle3d(commands,
            _turtle3d_command(commands[index],commands[index+1],commands[index+2],state,index),
            index+_turtle3d_command_len(commands,index)
        );

function _turtle3d_rotation(command,angle,center) =
  let(
      myangle = (ends_with(command,"right") || ends_with(command,"up") ? -1 : 1 ) * angle
  )
  ends_with(command,"xrot") ? xrot(myangle,cp=center) :
  ends_with(command,"yrot") ? yrot(myangle,cp=center) :
  ends_with(command,"zrot") ? zrot(myangle,cp=center) :
  ends_with(command,"right") || ends_with(command,"left") ? zrot(myangle,cp=center) :
                                                            yrot(myangle,cp=center);

// The turtle3d state maintains two lists of transformations that must be updated together. 
// This function updates the state by appending a list of transforms and list of pre-transforms
// to the state.
function _tupdate(state, tran, pretran) =
    [
     concat(state[0],tran),
     concat(state[1],pretran),
     each list_tail(state,2)
    ];

function _turtle3d_command(command, parm, parm2, state, index) =
    command == "repeat"?
        assert(is_int(parm) && parm>=0,str("\"repeat\" command requires an integer repeat count at index ",index))
        assert(is_list(parm2),str("\"repeat\" command requires a command list parameter at index ",index))
        _turtle3d_repeat(parm2, state, parm) :
    let(
        trlist = 0,
        prelist = 1,
        movestep=2,
        angle=3,
        arcsteps=4,
        parm = !is_string(parm) ? parm : undef,
        parm2 = command=="arctodir" || command=="arcrot" ? parm2 
              : !is_string(parm2) && !is_list(parm2) ? parm2 : undef,
        needvec = ["jump", "xyzmove","setdir"],
        neednum = ["untilx","untily","untilz","xjump","yjump","zjump","angle","length","scale","addlength"],
        numornothing = ["right","left","up","down","xrot","yrot","zrot", "roll", "move"],
        needtran = ["rot"],
        chvec = !in_list(command,needvec) || is_vector(parm,3),
        chnum = (!in_list(command,neednum) || is_num(parm))
                && (!in_list(command,numornothing) || (is_undef(parm) || is_num(parm))),
        chtran = !in_list(command,needtran) || is_matrix(parm,4,4),
        lastT = last(state[trlist]),
        lastPre = last(state[prelist]),
        lastpt = apply(lastT,[0,0,0])
    )
    assert(chvec,str("\"",command,"\" requires a 3d vector parameter at index ",index))
    assert(chnum,str("\"",command,"\" requires a numeric parameter at index ",index))
    assert(chtran,str("\"",command,"\" requires a 4x4 transformation matrix at index ",index))
    command=="move" ? _tupdate(state, [lastT*right(default(parm,1)*state[movestep])], [lastPre]):
    in_list(command,["untilx","untily","untilz"]) ? (
        let(
            dirlist=[RIGHT, BACK, UP],
            plane = [each dirlist[search([command],["untilx","untily","untilz"])[0]], parm],
            step = [lastpt,apply(lastT,RIGHT)],
            int = plane_line_intersection(plane, step, bounded=[true,false])
        )
        assert(is_def(int), str("\"",command,"\" never reaches desired goal at index ",index))
        let(
            size = is_vector(int,3) ? norm(int-lastpt) / norm(step[1]-step[0]) : 0
        )
        _tupdate(state, [lastT*right(size)], [lastPre])
    ) :
    command=="xmove" ? _tupdate(state,[right(default(parm,1)*state[movestep])*lastT],[lastPre]):
    command=="ymove" ? _tupdate(state,[back(default(parm,1)*state[movestep])*lastT],[lastPre]):
    command=="zmove" ? _tupdate(state,[up(default(parm,1)*state[movestep])*lastT],[lastPre]):
    command=="xyzmove" ? _tupdate(state,[move(parm)*lastT],[lastPre]):
    command=="jump" ? _tupdate(state,[move(parm-lastpt)*lastT],[lastPre]):
    command=="xjump" ? _tupdate(state,[move([parm,lastpt.y,lastpt.z]-lastpt)*lastT],[lastPre]):
    command=="yjump" ? _tupdate(state,[move([lastpt.x,parm,lastpt.z]-lastpt)*lastT],[lastPre]):
    command=="zjump" ? _tupdate(state,[move([lastpt.x,lastpt.y,parm]-lastpt)*lastT],[lastPre]):
    command=="angle" ? assert(parm!=0,str("\"",command,"\" requires nonnegative argument at index ",index))
                       list_set(state, angle, parm) :
    command=="length" ? list_set(state, movestep, parm) :
    command=="scale" ?  list_set(state, movestep, parm*state[movestep]) :
    command=="addlength" ?  list_set(state, movestep, state[movestep]+parm) :
    command=="arcsteps" ?  assert(is_int(parm) && parm>0, str("\"",command,"\" requires a postive integer argument at index ",index))
                           list_set(state, arcsteps, parm) :
    command=="roll" ? list_set(state, trlist, concat(list_head(state[trlist]), [lastT*xrot(parm)])):
    in_list(command,["right","left","up","down"]) ? 
        list_set(state, trlist, concat(list_head(state[trlist]), [lastT*_turtle3d_rotation(command,default(parm,state[angle]))])):
    in_list(command,["xrot","yrot","zrot"]) ?
        let(
             Trot = _rotpart(lastT),      // Extract rotational part of lastT
             shift = _transpart(lastT)    // Translation part of lastT
        )
        list_set(state, trlist, concat(list_head(state[trlist]),
                                       [move(shift)*_turtle3d_rotation(command,default(parm,state[angle])) * Trot])):
    command=="rot" ?
        let(
             Trot = _rotpart(lastT),      // Extract rotational part of lastT
             shift = _transpart(lastT)    // Translation part of lastT
        )
        list_set(state, trlist, concat(list_head(state[trlist]),[move(shift) * parm * Trot])):
    command=="setdir" ?
        let(
             Trot = _rotpart(lastT),
             shift = _transpart(lastT)
        )
        list_set(state, trlist, concat(list_head(state[trlist]),
                                       [move(shift)*rot(from=apply(Trot,RIGHT),to=parm) * Trot ])):
    in_list(command,["arcleft","arcright","arcup","arcdown"]) ?
        assert(is_num(parm),str("\"",command,"\" command requires a numeric radius value at index ",index))
        let(
            radius = state[movestep]*parm,
            myangle = default(parm2,state[angle])
        )
        assert(myangle!=0, str("\"",command,"\" command requires a nonzero angle at index ",index))
        let(
            length = 2*PI*radius * abs(myangle)/360, 
            center = [0,
                      command=="arcleft"?radius:command=="arcright"?-radius:0,
                      command=="arcdown"?-radius:command=="arcup"?radius:0],
            steps = state[arcsteps]==0 ? segs(abs(radius)) : state[arcsteps]
        )    
        _tupdate(state,
                 [for(n=[1:1:steps]) lastT*_turtle3d_rotation(command,myangle*n/steps,center)],
                 repeat(lastPre,steps)):
    in_list(command,["arcxrot","arcyrot","arczrot"]) ?
        assert(is_num(parm),str("\"",command,"\" command requires a numeric radius value at index ",index))  
        let(
            radius = state[movestep]*parm,
            myangle = default(parm2,state[angle])
        )
        assert(myangle!=0, str("\"",command,"\" command requires a nonzero angle at index ",index))
        let(
            length = 2*PI*radius * abs(myangle)/360, 
            steps = state[arcsteps]==0 ? segs(abs(radius)) : state[arcsteps],
            Trot = _rotpart(lastT),
            shift = _transpart(lastT),
            v = apply(Trot,RIGHT),
            dir = command=="arcxrot" ? RIGHT
                : command=="arcyrot" ? BACK
                : UP,
            projv = v - (dir*v)*dir,
            center = sign(myangle) * radius * cross(dir,projv),
            slope = dir*v / norm(projv),
            vshift = dir*slope*length
        )
        assert(!all_zero(projv), str("Rotation acts as twist, which does not produce a valid arc, at index ",index))
        _tupdate(state,
                 [for(n=[1:1:steps]) move(shift+vshift*n/steps)*_turtle3d_rotation(command,myangle*n/steps,center)*Trot],
                 repeat(lastPre,steps)):
    command=="arctodir" || command=="arcrot"?
        assert(command!="arctodir" || is_vector(parm2,3),str("\"",command,"\" command requires a direction vector at index ",index))
        assert(command!="arcrot" || is_matrix(parm2,4,4),str("\"",command,"\" command requires a transformation matrix at index ",index))  
        let(
            Trot = _rotpart(lastT),
            shift = _transpart(lastT),
            v = apply(Trot,RIGHT),
            rotparms = command=="arctodir"
                              ? rot_decode(rot(from=v,to=parm2))
                              : rot_decode(parm2),
            dir = rotparms[1],
            myangle = rotparms[0],
            projv = v - (dir*v)*dir,
            slope = dir*v / norm(projv),
            radius = state[movestep]*parm,
            length = 2*PI*radius * myangle/360, 
            vshift = dir*slope*length,
            steps = state[arcsteps]==0 ? segs(abs(radius)) : state[arcsteps],
            center = radius * cross(dir,projv)
        )
        assert(!all_zero(projv), str("Rotation acts as twist, which does not produce a valid arc, at index ",index))
        _tupdate(state,
                 [for(n=[1:1:steps]) move(shift+vshift*n/steps)*rot(n/steps*myangle,v=rotparms[1],cp=center)*Trot],
                 repeat(lastPre,steps)):
    is_list(command) ?
        let(list_update = _turtle3d_list_command(command, state[arcsteps], state[movestep], lastT, lastPre, index))
        _tupdate(state, list_update[0], list_update[1]):
    assert(false,str("Unknown turtle command \"",command,"\" at index",index))
    [];
       

function _turtle3d_list_command(command,arcsteps,movescale, lastT,lastPre,index) =
   let(
       reverse_index = search(["reverse"], command, 0)[0],
       reverse = len(reverse_index)==1,
       arcind = search(["arc"], command, 0)[0],
       moveind = search(["move"], command, 0)[0],
       movearcok = (arcind==[] || max(arcind)==0) && (moveind==[] || max(moveind)==0)
   )
   assert(len(reverse_index)<=1, str("Only one \"reverse\" is allowed at index ",index))
   assert(!reverse || reverse_index[0]%2==0, str("Error processing compound command at index ",index))
   assert(movearcok, str("\"move\" or \"arc\" must appear at the beginning of the compound command at index ",index))
   assert(!reverse || len(command)%2==1,str("Odd number of entries in [keyword,value] list (after removing \"reverse\") at index ",index))
   assert(reverse || len(command)%2==0,str("Odd number of entries in [keyword,value] list at index ",index))
   let(
       
       command = list_remove(command, reverse_index),
       keys=command[0]=="move" ?
               struct_set([
                           ["move", 0],
                           ["twist",0],
                           ["grow",1],
                           ["shrink",1],
                           ["steps",0],
                           ["roll",0],
                           ["lrollto", 0],
                           ["rrollto", 0],
                           ["rollto", 0]
                          ],
                          command, grow=false)
          :command[0]=="arc" ?
               struct_set([
                           ["arc", 0],
                           ["up", 0],
                           ["down", 0],
                           ["left", 0],
                           ["right", 0],
                           ["twist",0],
                           ["grow",1],
                           ["shrink",1],
                           ["steps",0],
                           ["roll",0],
                           ["lrollto", 0],
                           ["rrollto", 0],
                           ["rollto", 0],
                           ["rot", 0],
                           ["todir", 0],
                           ["xrot", 0],
                           ["yrot", 0],
                           ["zrot", 0],
                          ],
                          command, grow=false)
          :assert(false,str("Unknown compound turtle3d command \"",command,"\" at index ",index)),
       move = command[0]=="move" ? movescale*struct_val(keys,"move") : 0,
       flip = reverse ? xflip() : ident(4),            // If reverse is given we set flip 
       radius = movescale*first_defined([struct_val(keys,"arc"),0]),  // arc radius if given
       twist = struct_val(keys,"twist"),
       grow = force_list(struct_val(keys,"grow"),2),
       shrink = force_list(struct_val(keys, "shrink"),2)
   )
   assert(is_num(radius), str("Radius parameter to \"arc\" must be a number in command at index ",index))
   assert(is_vector(grow,2), str("Parameter to \"grow\" must be a scalar or 2d vector at index ",index))
   assert(is_vector(shrink,2), str("Parameter to \"shrink\" must be a scalar or 2d vector at index ",index))
   let(
       scaling = point3d(v_div(grow,shrink),1),
       usersteps = struct_val(keys,"steps"),
       ////////////////////////////////////////////////////////////////////////////////////////
       ////  Next section is computations for relative rotations: "left", "right", "up" or "down"
       right = default(struct_val(keys,"right"),0),
       left = default(struct_val(keys,"left"),0),
       up = default(struct_val(keys,"up"),0),
       down = default(struct_val(keys,"down"),0),
       angleok = assert(command[0]=="move" || (is_num(right) && is_num(left) && is_num(up) && is_num(down)),
                        str("Must give numeric argument to \"left\", \"right\", \"up\" and \"down\" in command at index ",index))
                 command[0]=="move" || ((up-down==0 || abs(left-right)<180) && (left-right==0 || abs(up-down)<180))
   )
   assert(command[0]=="move" || right==0 || left==0, str("Cannot specify both \"left\" and \"right\" in command at index ",index))
   assert(command[0]=="move" || up==0 || down==0, str("Cannot specify both \"up\" and \"down\" in command at index ",index))
   assert(angleok, str("Mixed angles must all be below 180 at index ",index))
   let(
        newdir = apply(zrot(left-right)*yrot(down-up),RIGHT),     // This is the new direction turtle points relative to RIGHT
        relaxis = left-right == 0 ? BACK
                : down-up == 0 ? UP
                : cross(RIGHT,newdir),         // This is the axis of rotation for "right", "left", "up" or "down"
        angle = command[0]=="move" ? 0 :
                  left-right==0 || down-up==0 ? down-up+left-right :
                  vector_angle(RIGHT,newdir),    // And this is the angle for that case.
        center = -radius * (                     // Center of rotation for this case
                      left-right == 0 ? [0,0,sign(down-up)]
                    : down-up == 0 ? [0,sign(right-left),0]
                    :       unit(cross(RIGHT,cross(RIGHT,newdir)),[0,0,0])
                 ),    
        ///////////////////////////////////////////////
        // Next we compute values for absolute rotations: "xrot", "xrot", "yrot", "zrot", and "todir"
        //
        xrotangle = struct_val(keys,"xrot"),
        yrotangle = struct_val(keys,"yrot"),
        zrotangle = struct_val(keys,"zrot"),
        rot = struct_val(keys,"rot"),
        todir = struct_val(keys,"todir"),
        // Compute rotation angle and axis for the absolute rotation (or undef if no absolute rotation is given)
        abs_angle_axis =
            command[0]=="move" ? [undef,CENTER] :
            let(nzcount=len([for(entry=[xrotangle,yrotangle,zrotangle,rot,todir]) if (entry!=0) 1]))
            assert(nzcount<=1, str("You can only define one of \"xrot\", \"yrot\", \"zrot\", \"rot\", and \"todir\" at index ",index))
            rot!=0 ?   assert(is_matrix(rot,4,4),str("Argument to \"rot\" is not a 3d transformation matrix at index ",index))
                       rot_decode(rot)
          : todir!=0 ? assert(is_vector(todir,3),str("Argument to \"todir\" is not a length 3 vector at index ",index))
                       rot_decode(rot(from=v, to=todir))
          : xrotangle!=0 ? [xrotangle, RIGHT]
          : yrotangle!=0 ? [yrotangle, BACK]
          : zrotangle!=0 ? [zrotangle, UP]
          : [undef,CENTER],
        absangle = abs_angle_axis[0],
        absaxis = abs_angle_axis[1],
        // Computes the extra shift and center with absolute rotation
        Trot = _rotpart(lastT),  
        shift = _transpart(lastT), 
        v = apply(Trot,RIGHT),           // Current direction
        projv = v - (absaxis*v)*absaxis, // Component of rotation axis orthogonal to v
        abscenter = is_undef(absangle) ? undef : sign(absangle) * radius * cross(absaxis,projv),    // absangle might be undef if command is "move"
        slope = absaxis*v / norm(projv),       // This computes the shift in the direction along the rotational axis
        vshift = is_undef(absangle) ? undef : absaxis*slope* 2*PI*radius*absangle/360
    )
    // At this point angle is nonzero if and only if a relative angle command (left, right, up down) was given,
    //               absangle is defined if and only if an absolute angle command was given
    assert(is_undef(absangle) || absangle!=0, str("Arc rotation with zero angle at index ",index))
    assert(angle==0 || is_undef(absangle), str("Mixed relative and absolute rotations at index ",index))
    assert(is_int(usersteps) && usersteps>=0, str("Steps value ",usersteps," invalid at index ",index))
    assert(is_undef(absangle) || !all_zero(projv), str("Rotation acts as twist, which does not produce a valid arc at index ",index))
    let(
        rollval = struct_val(keys,"roll"),
        rrollto = struct_val(keys,"rrollto"),
        lrollto = struct_val(keys,"lrollto"),
        rollto = struct_val(keys,"rollto"),
        dummy = assert(num_true([rollval!=0, rrollto!=0, lrollto!=0, rollto!=0])<=1,
                       str("Cannot set more than one of roll, rollto, rrollto and lrollto at index ",index))
                assert((rrollto==0 || is_vector(rrollto,3)) && (lrollto==0 || is_vector(lrollto,3)) && (rollto==0 || is_vector(rollto,3)),
                       str("rollto, rrollto and lrollto must be 3-vectors at index ",index))
                assert(rollval==0 || is_finite(rollval), "roll must be a finite value"),
        finalT = is_undef(absangle) ? lastT * flip * right(move) * (angle==0?ident(4):rot(angle,v=relaxis,cp=center))
               : move(shift+vshift) * rot(absangle,v=absaxis,cp=abscenter)*Trot,
        finaldir = unit(apply(_rotpart(finalT),RIGHT)),
        finalup = apply(_rotpart(finalT),UP),
        roll = rollval!=0 ? rollval
             : rrollto==0 && lrollto==0 && rollto==0? 0 
             : let(
                    desired = rollto!=0 ? rollto : rrollto!=0 ? rrollto : lrollto,
                    dummy = assert(!approx(abs(unit(desired)*finaldir),1),
                                   str("\nRequested roll is impossible because roll direction is parallel to the turtle travel direction at index ",index)),
                    fe=echo(finalup=finalup),
                    
                    startang = _compute_spin(finaldir, finalup),
                    finalang = _compute_spin(finaldir, desired),
                    delta_ang = posmod(finalang-startang,360),
                    signed_ang = rrollto!=0 || delta_ang==0 ? delta_ang
                               : lrollto!=0 || delta_ang>180 ? delta_ang-360
                               : delta_ang
,                    ffe=echo(signed_ang=signed_ang, startang=startang, finalang=finalang)
               ) signed_ang,
        steps = usersteps==0 && command[0]=="move" && roll==0 && twist==0 ? 1
              : usersteps != 0 ? usersteps
              : arcsteps != 0 ? arcsteps
              : ceil(segs(abs(radius)) * abs(first_defined([absangle,angle]))/360),
        // The next line computes a list of pairs [trans,pretrans] for the segment or arc
        result =  is_undef(absangle)
                  ? [for(n=[1:1:steps]) let(frac=n/steps)
                              [lastT * flip * right(frac*move) * (angle==0?ident(4):rot(frac*angle,v=relaxis,cp=center)) * xrot(frac*roll),
                               lastPre * zrot(frac*twist) * scale(lerp([1,1,1],scaling,frac))]
                    ]
                  : [for(n=[1:1:steps]) let(frac=n/steps) 
                              [move(shift+vshift*frac) * rot(frac*absangle,v=absaxis,cp=abscenter)*Trot * xrot(frac*roll),
                               lastPre * zrot(frac*twist) * scale(lerp([1,1,1],scaling,frac))]
                    ]
    )                     // Transpose converts the result into a list of the form [[trans1,trans2,...],[pretran1,pretran2,...]],
    transpose(result);    // which is required by _tupdate


