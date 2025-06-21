//////////////////////////////////////////////////////////////////////
// LibFile: attachments.scad
//   The modules in this file allows you to attach one object to another by making one object the child of another object.
//   You can place the child object in relation to its parent object and control the position and orientation
//   relative to the parent.  The modifiers allow you to treat children in ways different from simple union, such
//   as differencing them from the parent, or changing their color.  Attachment only works when the parent and child
//   are both written to support attachment.  Also included in this file  are the tools to make your own "attachable" objects.
// Includes:
//   include <BOSL2/std.scad>
// FileGroup: Basic Modeling
// FileSummary: Positioning objects on or relative to other objects.  Making your own objects support attachment.
// FileFootnotes: STD=Included in std.scad
//////////////////////////////////////////////////////////////////////

// Default values for attachment code.
$tags=undef;      // for backward compatibility
$tag = "";
$save_tag = undef;
$tag_prefix = "";
$overlap = 0;
$color = "default";
$save_color = undef;         // Saved color to revert back for children

$anchor_override = undef;
$attach_to = undef;
$attach_anchor = [CENTER, CENTER, UP, 0];
$attach_alignment = undef;

$parent_anchor = BOTTOM;
$parent_spin = 0;
$parent_orient = UP;

$parent_size = undef;
$parent_geom = undef;

$attach_inside = false;  // If true, flip the meaning of the inside parameter for align() and attach()

$edge_angle = undef;
$edge_length = undef;

$tags_shown = "ALL";
$tags_hidden = [];

$ghost_this=false;
$ghost=false;
$ghosting=false;    // Ghosting is in effect, so don't apply it again

$highlight_this=false;
$highlight=false;

_ANCHOR_TYPES = ["intersect","hull"];


// Section: Terminology and Shortcuts
//   This library adds the concept of anchoring, spin and orientation to the `cube()`, `cylinder()`
//   and `sphere()` builtins, as well as to most of the shapes provided by this library itself.
//   - An anchor is a place on an object which you can align the object to, or attach other objects
//     to using `attach()` or `position()`. An anchor has a position, a direction, and a spin.
//     The direction and spin are used to orient other objects to match when using `attach()`.
//   - Spin is a simple rotation around the Z axis.
//   - Orientation is rotating an object so that its top is pointed towards a given vector.
//   .
//   An object will first be translated to its anchor position, then spun, then oriented.
//   For a detailed step-by-step explanation of attachments, see the [Attachments Tutorial](Tutorial-Attachment-Relative-Positioning).
//   .
//   For describing directions, faces, edges, and corners the library provides a set of shortcuts
//   all based on combinations of unit direction vectors.  You can use these for anchoring and orienting
//   attachable objects.  You can also them to specify edge sets for rounding or chamfering cuboids,
//   or for placing edge, face and corner masks.
// Subsection: Anchor
//   Anchoring is specified with the `anchor` argument in most shape modules.  Specifying `anchor`
//   when creating an object will translate the object so that the anchor point is at the origin
//   (0,0,0).  Anchoring always occurs before spin and orientation are applied.
//   .
//   An anchor can be referred to in one of two ways; as a directional vector, or as a named anchor string.
//   .
//   When given as a vector, it points, in a general way, towards the face, edge, or corner of the
//   object that you want the anchor for, relative to the center of the object.  You can simply
//   specify a vector like `[0,0,1]` to anchor an object at the Z+ end, but you can also use
//   directional constants with names like `TOP`, `BOTTOM`, `LEFT`, `RIGHT` and `BACK` that you can add together
//   to specify anchor points.  See [specifying directions](attachments.scad#subsection-specifying-directions)
//   below for the full list of pre-defined directional constants.
//   .
//   For example:
//   - `[0,0,1]` is the same as `TOP` and refers to the center of the top face.
//   - `[-1,0,1]` is the same as `TOP+LEFT`, and refers to the center of the top-left edge.
//   - `[1,1,-1]` is the same as `BOTTOM+BACK+RIGHT`, and refers to the bottom-back-right corner.
//   .
//   When the object is cubical or rectangular in shape the anchors must have zero or one values
//   for their components and they refer to the face centers, edge centers, or corners of the object.
//   The direction of a face anchor will be perpendicular to the face, pointing outward.  The direction of a edge anchor
//   will be the average of the anchor directions of the two faces the edge is between.  The direction
//   of a corner anchor will be the average of the anchor directions of the three faces the corner is
//   on.
//   .
//   When the object is cylindrical, conical, or spherical in nature, the anchors will be located
//   around the surface of the cylinder, cone, or sphere, relative to the center.
//   You can generally use an arbitrary vector to get an anchor positioned anywhere on the curved
//   surface of such an object, and the anchor direction will be the surface normal at the anchor location.
//   However, for anchor component pointing toward the flat face should be either -1, 1, or 0, and
//   anchors that point diagonally toward one of the flat faces will select a point on the edge.
//   .
//   For objects in two dimensions, the natural expectation is for TOP and BOTTOM to refer to the Y direction
//   of the shape.  To support this, if you give an anchor in 2D that has anchor.y=0 then the Z component
//   will be mapped to the Y direction.  This  means you can use TOP and BOTTOM for anchors of 2D objects.
//   But remember that TOP and BOTTOM are three dimensional vectors and this is a special interpretation
//   for 2d anchoring.
//   .
//   Some more complex objects, like screws and stepper motors, have named anchors to refer to places
//   on the object that are not at one of the standard faces, edges or corners.  For example, stepper
//   motors have anchors for `"screw1"`, `"screw2"`, etc. to refer to the various screwholes on the
//   stepper motor shape.  The names, positions, directions, and spins of these anchors are
//   specific to the object, and are documented when they exist.
//   .
//   The anchor argument is ignored if you use {{align()}} or the two-argument form of {{attach()}} because
//   these modules provide their own anchoring for their children.  
// Subsection: Spin
//   Spin is specified with the `spin` argument in most shape modules.  Specifying a spin
//   angle when creating an object will rotate the object counter-clockwise around the Z axis by the given
//   number of degrees.  Spin is always applied after anchoring, and before orientation.
//   Since spin is applied **after** anchoring it does not, in general, rotate around the object's center,
//   so it is not always what you might think of intuitively as spinning the shape.  
// Subsection: Orient
//   Orientation is specified with the `orient` argument in most shape modules.  Specifying `orient`
//   when creating an object will rotate the object such that the top of the object will be pointed
//   at the vector direction given in the `orient` argument.  Orientation is always applied after
//   anchoring and spin.  The constants `UP`, `DOWN`, `FRONT`, `BACK`, `LEFT`, and `RIGHT` can be
//   added together to form the directional vector for this (e.g. `LEFT+BACK`).  The orient parameter
//   is ignored when you use {{attach()}} with two arguments, because {{attach()}} provides its own orientation. 
// Subsection: Specifying Directions
//   You can use direction vectors to specify anchors for objects or to specify edges, faces, and
//   corners of cubes.  You can simply specify these direction vectors numerically, but another
//   option is to use named constants for direction vectors.  These constants define unit vectors
//   for the six axis directions as shown below.
// Figure(3D,Big,VPD=6): Named constants for direction vectors.  Some directions have more than one name.
//   $fn=12;
//   stroke([[0,0,0],RIGHT], endcap2="arrow2", width=.05);
//   color("black")right(.05)up(.05)move(RIGHT) text3d("RIGHT",size=.1,h=.01,anchor=LEFT,orient=FRONT);
//   stroke([[0,0,0],LEFT], endcap2="arrow2", width=.05);
//   color("black")left(.05)up(.05)move(LEFT) text3d("LEFT",size=.1,h=.01,anchor=RIGHT,orient=FRONT);
//   stroke([[0,0,0],FRONT], endcap2="arrow2", width=.05);
//   color("black")
//   left(.1){
//   up(.12)move(FRONT) text3d("FRONT",size=.1,h=.01,anchor=RIGHT,orient=FRONT);
//   move(FRONT) text3d("FWD",size=.1,h=.01,anchor=RIGHT,orient=FRONT);
//   down(.12)move(FRONT) text3d("FORWARD",size=.1,h=.01,anchor=RIGHT,orient=FRONT);
//   }
//   stroke([[0,0,0],BACK], endcap2="arrow2", width=.05);
//   right(.05)
//   color("black")move(BACK) text3d("BACK",size=.1,h=.01,anchor=LEFT,orient=FRONT);
//   stroke([[0,0,0],DOWN], endcap2="arrow2", width=.05);
//   color("black")
//   right(.1){
//   up(.12)move(BOT) text3d("DOWN",size=.1,h=.01,anchor=LEFT,orient=FRONT);
//   move(BOT) text3d("BOTTOM",size=.1,h=.01,anchor=LEFT,orient=FRONT);
//   down(.12)move(BOT) text3d("BOT",size=.1,h=.01,anchor=LEFT,orient=FRONT);
//   }
//   stroke([[0,0,0],TOP], endcap2="arrow2", width=.05);
//   color("black")left(.05){
//   up(.12)move(TOP) text3d("TOP",size=.1,h=.01,anchor=RIGHT,orient=FRONT);
//   move(TOP) text3d("UP",size=.1,h=.01,anchor=RIGHT,orient=FRONT);
//   }
// Figure(2D,Big): Named constants for direction vectors in 2D.  For anchors the TOP and BOTTOM directions are collapsed into 2D as shown here, but do not try to use TOP or BOTTOM as 2D directions in other situations.
//   $fn=12;
//   stroke(path2d([[0,0,0],RIGHT]), endcap2="arrow2", width=.05);
//   color("black")fwd(.22)left(.05)move(RIGHT) text("RIGHT",size=.1,anchor=RIGHT);
//   stroke(path2d([[0,0,0],LEFT]), endcap2="arrow2", width=.05);
//   color("black")right(.05)fwd(.22)move(LEFT) text("LEFT",size=.1,anchor=LEFT);
//   stroke(path2d([[0,0,0],FRONT]), endcap2="arrow2", width=.05);
//   color("black")
//   fwd(.2)
//   right(.15)
//   color("black")move(BACK) { text("BACK",size=.1,anchor=LEFT); back(.14) text("(TOP)", size=.1, anchor=LEFT);}
//   color("black")
//   left(.15)back(.2+.14)move(FRONT){
//   back(.14) text("FRONT",size=.1,anchor=RIGHT);
//       text("FWD",size=.1,anchor=RIGHT);
//   fwd(.14) text("FORWARD",size=.1,anchor=RIGHT);
//   fwd(.28) text("(BOTTOM)",size=.1,anchor=RIGHT);
//   fwd(.14*3) text("(BOT)",size=.1,anchor=RIGHT);
//   }
//   stroke(path2d([[0,0,0],BACK]), endcap2="arrow2", width=.05);
// Subsection: Specifying Faces
//   Modules operating on faces accept a list of faces to describe the faces to operate on.  Each
//   face is given by a vector that points to that face.  Attachments of cuboid objects onto their faces also
//   work by choosing an attachment face with a single vector in the same manner.
// Figure(3D,Big,NoScales,VPD=275): The six faces of the cube.  Some have faces have more than one name.
//   ydistribute(50) {
//      xdistribute(35){
//        _show_cube_faces([BACK], botlabel=["BACK"]);
//        _show_cube_faces([UP],botlabel=["TOP","UP"]);
//        _show_cube_faces([RIGHT],botlabel=["RIGHT"]);
//      }
//      xdistribute(35){
//        _show_cube_faces([FRONT],toplabel=["FRONT","FWD", "FORWARD"]);
//        _show_cube_faces([DOWN],toplabel=["BOTTOM","BOT","DOWN"]);
//        _show_cube_faces([LEFT],toplabel=["LEFT"]);
//      }
//   }
// Subsection: Specifying Edges
//   Modules operating on edges use two arguments to describe the edge set they will use: The `edges` argument
//   is a list of edge set descriptors to include in the edge set, and the `except` argument is a list of
//   edge set descriptors to remove from the edge set.
//   The default value for `edges` is `"ALL"`, the set of all edges.
//   The default value for `except` is the    empty set, meaning no edges are removed.
//   If either argument is just a single edge set
//   descriptor it can be passed directly rather than in a singleton list.
//   Each edge set descriptor must be one of:
//   - A vector pointing towards an edge, indicating that single edge.
//   - A vector pointing towards a face, indicating all edges surrounding that face.
//   - A vector pointing towards a corner, indicating all edges touching that corner.
//   - The string `"X"`, indicating all X axis aligned edges.
//   - The string `"Y"`, indicating all Y axis aligned edges.
//   - The string `"Z"`, indicating all Z axis aligned edges.
//   - The string `"ALL"`, indicating all edges.
//   - The string `"NONE"`, indicating no edges at all.
//   - A 3x4 array, where each entry corresponds to one of the 12 edges and is set to 1 if that edge is included and 0 if the edge is not.  The edge ordering is:
//       ```
//       [
//           [Y-Z-, Y+Z-, Y-Z+, Y+Z+],
//           [X-Z-, X+Z-, X-Z+, X+Z+],
//           [X-Y-, X+Y-, X-Y+, X+Y+]
//       ]
//       ```
//   .
//   You can specify edge descriptors directly by giving a vector, or you can use sums of the
//   named direction vectors described above.  Below we show all of the edge sets you can
//   describe with sums of the direction vectors, and then we show some examples of combining
//   edge set descriptors.
// Figure(3D,Big,VPD=300,NoScales): Vectors pointing toward an edge select that single edge
//   ydistribute(50) {
//       xdistribute(30) {
//           _show_edges(edges=BOT+RIGHT);
//           _show_edges(edges=BOT+BACK);
//           _show_edges(edges=BOT+LEFT);
//           _show_edges(edges=BOT+FRONT);
//       }
//       xdistribute(30) {
//           _show_edges(edges=FWD+RIGHT);
//           _show_edges(edges=BACK+RIGHT);
//           _show_edges(edges=BACK+LEFT);
//           _show_edges(edges=FWD+LEFT);
//       }
//       xdistribute(30) {
//           _show_edges(edges=TOP+RIGHT);
//           _show_edges(edges=TOP+BACK);
//           _show_edges(edges=TOP+LEFT);
//           _show_edges(edges=TOP+FRONT);
//       }
//   }
// Figure(3D,Med,VPD=205,NoScales): Vectors pointing toward a face select all edges surrounding that face.
//   ydistribute(50) {
//       xdistribute(30) {
//           _show_edges(edges=LEFT);
//           _show_edges(edges=FRONT);
//           _show_edges(edges=RIGHT);
//       }
//       xdistribute(30) {
//           _show_edges(edges=TOP);
//           _show_edges(edges=BACK);
//           _show_edges(edges=BOTTOM);
//       }
//   }
// Figure(3D,Big,VPD=300,NoScales): Vectors pointing toward a corner select all edges surrounding that corner.
//   ydistribute(50) {
//       xdistribute(30) {
//           _show_edges(edges=FRONT+LEFT+TOP);
//           _show_edges(edges=FRONT+RIGHT+TOP);
//           _show_edges(edges=FRONT+LEFT+BOT);
//           _show_edges(edges=FRONT+RIGHT+BOT);
//       }
//       xdistribute(30) {
//           _show_edges(edges=TOP+LEFT+BACK);
//           _show_edges(edges=TOP+RIGHT+BACK);
//           _show_edges(edges=BOT+LEFT+BACK);
//           _show_edges(edges=BOT+RIGHT+BACK);
//       }
//   }
// Figure(3D,Med,VPD=205,NoScales): Named Edge Sets
//   ydistribute(50) {
//       xdistribute(30) {
//           _show_edges(edges="X");
//           _show_edges(edges="Y");
//           _show_edges(edges="Z");
//       }
//       xdistribute(30) {
//           _show_edges(edges="ALL");
//           _show_edges(edges="NONE");
//       }
//   }
// Figure(3D,Big,VPD=310,NoScales):  Next are some examples showing how you can combine edge descriptors to obtain different edge sets.    You can specify the top front edge with a numerical vector or by combining the named direction vectors.  If you combine them as a list you get all the edges around the front and top faces.  Adding `except` removes an edge.
//   xdistribute(43){
//     _show_edges(_edges([0,-1,1]),toplabel=["edges=[0,-1,1]"]);
//     _show_edges(_edges(TOP+FRONT),toplabel=["edges=TOP+FRONT"]);
//     _show_edges(_edges([TOP,FRONT]),toplabel=["edges=[TOP,FRONT]"]);
//     _show_edges(_edges([TOP,FRONT],TOP+FRONT),toplabel=["edges=[TOP,FRONT]","except=TOP+FRONT"]);
//   }
// Figure(3D,Big,VPD=310,NoScales): Using `except=BACK` removes the four edges surrounding the back face if they are present in the edge set.  In the first example only one edge needs to be removed.  In the second example we remove two of the Z-aligned edges.  The third example removes all four back edges from the default edge set of all edges.  You can explicitly give `edges="ALL"` but it is not necessary, since this is the default.  In the fourth example, the edge set of Y-aligned edges contains no back edges, so the `except` parameter has no effect.
//   xdistribute(43){
//     _show_edges(_edges(BOT,BACK), toplabel=["edges=BOT","except=BACK"]);
//     _show_edges(_edges("Z",BACK), toplabel=["edges=\"Z\"", "except=BACK"]);
//     _show_edges(_edges("ALL",BACK), toplabel=["(edges=\"ALL\")", "except=BACK"]);
//     _show_edges(_edges("Y",BACK), toplabel=["edges=\"Y\"","except=BACK"]);
//   }
// Figure(3D,Big,NoScales,VPD=310): On the left `except` is a list to remove two edges.  In the center we show a corner edge set defined by a numerical vector, and at the right we remove that same corner edge set with named direction vectors.
//   xdistribute(52){
//    _show_edges(_edges("ALL",[FRONT+RIGHT,FRONT+LEFT]),
//               toplabel=["except=[FRONT+RIGHT,","       FRONT+LEFT]"]);
//    _show_edges(_edges([1,-1,1]),toplabel=["edges=[1,-1,1]"]);
//    _show_edges(_edges([TOP,BOT], TOP+RIGHT+FRONT),toplabel=["edges=[TOP,BOT]","except=TOP+RIGHT+FRONT"]);
//   }
// Subsection: Specifying Corners
//   Modules operating on corners use two arguments to describe the corner set they will use: The `corners` argument
//   is a list of corner set descriptors to include in the corner set, and the `except` argument is a list of
//   corner set descriptors to remove from the corner set.
//   The default value for `corners` is `"ALL"`, the set of all corners.
//   The default value for `except` is the   empty set, meaning no corners are removed.
//   If either argument is just a single corner set
//   descriptor it can be passed directly rather than in a singleton list.
//   Each corner set descriptor must be one of:
//   - A vector pointing towards a corner, indicating that corner.
//   - A vector pointing towards an edge indicating both corners at the ends of that edge.
//   - A vector pointing towards a face, indicating all the corners of that face.
//   - The string `"ALL"`, indicating all corners.
//   - The string `"NONE"`, indicating no corners at all.
//   - A length 8 vector where each entry corresponds to a corner and is 1 if the corner is included and 0 if it is excluded.  The corner ordering is
//       ```
//       [X-Y-Z-, X+Y-Z-, X-Y+Z-, X+Y+Z-, X-Y-Z+, X+Y-Z+, X-Y+Z+, X+Y+Z+]
//       ```
//   .
//   You can specify corner descriptors directly by giving a vector, or you can use sums of the
//   named direction vectors described above.  Below we show all of the corner sets you can
//   describe with sums of the direction vectors and then we show some examples of combining
//   corner set descriptors.
// Figure(3D,Big,NoScales,VPD=300): Vectors pointing toward a corner select that corner.
//   ydistribute(55) {
//       xdistribute(35) {
//           _show_corners(corners=FRONT+LEFT+TOP);
//           _show_corners(corners=FRONT+RIGHT+TOP);
//           _show_corners(corners=FRONT+LEFT+BOT);
//           _show_corners(corners=FRONT+RIGHT+BOT);
//       }
//       xdistribute(35) {
//           _show_corners(corners=TOP+LEFT+BACK);
//           _show_corners(corners=TOP+RIGHT+BACK);
//           _show_corners(corners=BOT+LEFT+BACK);
//           _show_corners(corners=BOT+RIGHT+BACK);
//       }
//   }
// Figure(3D,Big,NoScales,VPD=340): Vectors pointing toward an edge select the corners and the ends of the edge.
//   ydistribute(55) {
//       xdistribute(35) {
//           _show_corners(corners=BOT+RIGHT);
//           _show_corners(corners=BOT+BACK);
//           _show_corners(corners=BOT+LEFT);
//           _show_corners(corners=BOT+FRONT);
//       }
//       xdistribute(35) {
//           _show_corners(corners=FWD+RIGHT);
//           _show_corners(corners=BACK+RIGHT);
//           _show_corners(corners=BACK+LEFT);
//           _show_corners(corners=FWD+LEFT);
//       }
//       xdistribute(35) {
//           _show_corners(corners=TOP+RIGHT);
//           _show_corners(corners=TOP+BACK);
//           _show_corners(corners=TOP+LEFT);
//           _show_corners(corners=TOP+FRONT);
//       }
//   }
// Figure(3D,Med,NoScales,VPD=225): Vectors pointing toward a face select the corners of the face.
//   ydistribute(55) {
//       xdistribute(35) {
//           _show_corners(corners=LEFT);
//           _show_corners(corners=FRONT);
//           _show_corners(corners=RIGHT);
//       }
//       xdistribute(35) {
//           _show_corners(corners=TOP);
//           _show_corners(corners=BACK);
//           _show_corners(corners=BOTTOM);
//       }
//   }
// Figure(3D,Med,NoScales,VPD=200): Corners by name
//   xdistribute(35) {
//       _show_corners(corners="ALL");
//       _show_corners(corners="NONE");
//   }
// Figure(3D,Big,NoScales,VPD=300):     Next are some examples showing how you can combine corner descriptors to obtain different corner sets.   You can specify corner sets numerically or by adding together named directions.  The third example shows a list of two corner specifications, giving all the corners on the front face or the right face.
//   xdistribute(52){
//     _show_corners(_corners([1,-1,-1]),toplabel=["corners=[1,-1,-1]"]);
//     _show_corners(_corners(BOT+RIGHT+FRONT),toplabel=["corners=BOT+RIGHT+FRONT"]);
//     _show_corners(_corners([FRONT,RIGHT]), toplabel=["corners=[FRONT,RIGHT]"]);
//   }
// Figure(3D,Big,NoScales,VPD=300): Corners for one edge, two edges, and all the edges except the two on one edge.  Note that since the default is all edges, you only need to give the except argument in this case:
//    xdistribute(52){
//      _show_corners(_corners(FRONT+TOP), toplabel=["corners=FRONT+TOP"]);
//       _show_corners(_corners([FRONT+TOP,BOT+BACK]), toplabel=["corners=[FRONT+TOP,","        BOT+BACK]"]);
//       _show_corners(_corners("ALL",FRONT+TOP), toplabel=["(corners=\"ALL\")","except=FRONT+TOP"]);
//    }
// Figure(3D,Med,NoScales,VPD=240): The first example shows a single corner removed from the top corners using a numerical vector.  The second one shows removing a set of two corner descriptors from the implied set of all corners.
//    xdistribute(58){
//       _show_corners(_corners(TOP,[1,1,1]), toplabel=["corners=TOP","except=[1,1,1]"]);
//       _show_corners(_corners("ALL",[FRONT+RIGHT+TOP,FRONT+LEFT+BOT]),
//                    toplabel=["except=[FRONT+RIGHT+TOP,","       FRONT+LEFT+BOT]"]);
//    }
// Subsection: Anchoring of Non-Rectangular Objects and Anchor Type (atype)
//   We focused above on rectangular objects that have well-defined faces and edges aligned with the coordinate axes.
//   Things get difficult when the objects are curved, or even when their edges are not neatly aligned with the coordinate axes.
//   In these cases, the library may provide multiple different anchoring schemes, called the anchor types.  When a module supports
//   multiple anchor types, use the `atype=` parameter to select the anchor type you need.
//   .
//   First consider the case of a simple rectangle whose corners have been rounded.  Where should the anchors lie?
//   The default anchor type puts them in the same location as the anchors of an unrounded rectangle, which means that for
//   positive rounding radii, they are not even located on the perimeter of the object.
// Figure(2D,Med,NoAxes): Default "box" atype anchors for a rounded {{rect()}}
//   rect([100,50], rounding=[10,0,0,-20],chamfer=[0,10,-20,0]) show_anchors();
// Continues:
//   This choice enables you to position the box, or attach things to it, without regard to its rounding or chamfers.  If you need to
//   anchor onto the roundovers or chamfers then you can use the "perim" anchor type:
// Figure(2D,Med,NoAxes): The "perim" atype for a rounded and chamfered {{rect()}}
//   rect([100,50], rounding=[10,0,0,-20],chamfer=[0,10,-20,0],atype="perim") show_anchors();
// Continues:
//   With this anchor type, the anchors are located on the perimeter.  For positive roundings they point in the standard anchor direction;
//   for negative roundings they are parallel to the base.  As noted above, for circles, cylinders, and spheres, the anchor point is
//   determined by choosing the point where the anchor vector intersects the shape.  On a circle, this results in an anchor whose direction
//   matches the user provided anchor vector.  But on an ellipse, something else happens:
// Figure(2D,Med,NoAxes): Anchors on an ellipse.  The red arrow shows a TOP+RIGHT anchor direction. 
//   ellipse([70,30]) show_anchors();
//   stroke([[0,0],[45,45]], color="red",endcap2="arrow2");
// Continues:
//   For a TOP+RIGHT anchor direction, the surface normal at the intersection point does not match the anchor direction,
//   so the direction of the anchor shown in blue does not match the direction specified, in red.
//   Anchors computed this way have anchor type "intersect".  When a shape is concave, intersection anchors can produce
//   a result buried inside the shape's concavity.  Consider the RIGHT anchor of this supershape example:
// Figure(2D,Med,NoAxes): A supershape with "intersect" anchor type:
//   supershape(n=150,r=75, m1=4, n1=4.0,n2=16, n3=1.5, a=0.9, b=9,atype="intersect") show_anchors();
// Continues:
//   A different anchor type called "hull" finds anchors that are on the convex hull of the shape.  
// Figure(2D,Med,NoAxes): A supershape with "hull" anchor type:
//   supershape(n=150,r=55, m1=4, n1=4.0,n2=16, n3=1.5, a=0.9, b=9,atype="hull") show_anchors();
// Continues:
//   Hull anchoring works by creating the line (or plane in 3D) that is normal to the specified anchor direction, and
//   finding the point farthest from the center that intersects that line (or plane).
// Figure(2D,Med,NoAxes): Finding the RIGHT and BACK+LEFT "hull" anchors
//   supershape(n=128,r=55, m1=4, n1=4.0,n2=16, n3=1.5, a=0.9, b=9,atype="hull") {
//     position(RIGHT) color_this("red")rect([1,90],anchor=LEFT);
//     attach(RIGHT)anchor_arrow2d(13);
//     attach(BACK+LEFT) {
//        anchor_arrow2d(13);
//        color_this("red")rect([30,1]);
//        }
//     }
// Continues:
//   In the example the RIGHT anchor is found when the normal line (shown in red) is tangent to the shape at two points.
//   The anchor is then taken to be the midpoint.  The BACK+LEFT anchor occurs with a single tangent point, and the
//   anchor point is located at the tangent point.  For circles intersection is done to the exact circle, but for other
//   shapes these calculations are done on the point lists that defines the shape, so if you change the number of points
//   in the list, the precise location of the anchors can change.  You can also get surprising results if your point list is badly chosen.
// Figure(2D,Med,NoAxes): Circle anchor in blue.  The red anchor is computed to a point list of a circle with 17 segments.  
//   circle(r=31,$fn=128) attach(TOP)anchor_arrow2d(15);
//   region(circle(r=33,$fn=17)) {color("red")attach(TOP)anchor_arrow2d(13);}
// Continues:
//   The figure shows a large horizontal offset due to a poor choice of sampling for the circular shape when using the "hull" anchor type.
//   The determination of "hull" or "intersect" anchors may depend on the location of the centerpoint used in the computation.
//   Some of the modules allow you to change the centerpoint using a `cp=` argument.  If you need to change the centerpoint for
//   a module that does not provide this option, you can use the generic {{region()}} module, which will let you specify a centerpoint.
//   The default center point is the centroid, specified by "centroid".  You can also choose "mean", which gives the mean of all
//   the data points, or "bbox", which gives the centerpoint of the bounding box for the data.  Your last option for centerpoint is to
//   choose an arbitrary point that meets your needs.
// Figure(2D,Med,NoAxes): The centerpoint for "intersect" anchors is located at the red dot
//   region(supershape(n=128,r=55, m1=4, n1=4.0,n2=16, n3=1.5, a=0.9, b=9),atype="intersect",cp=[0,30]) show_anchors();
//   color("red")back(30)circle(r=2,$fn=16);
// Continues:
//   Note that all the anchors for an object have to be determined based on one anchor type and relative to the same centerpoint.
//   The supported anchor types for each module appear in the "Anchor Types" section of its entry.  





// Section: Attachment Positioning

// Module: position()
// Synopsis: Attaches children to a parent object at an anchor point.
// SynTags: Trans
// Topics: Attachments
// See Also: attachable(), attach(), orient()
// Usage:
//   PARENT() position(at) CHILDREN;
// Description:
//   Attaches children to a parent object at an anchor point.  For a step-by-step explanation
//   of attachments, see the [Attachments Tutorial](Tutorial-Attachment-Relative-Positioning).
// Arguments:
//   at = The vector, or name of the parent anchor point to attach to.
// Side Effects:
//   `$attach_anchor` for each `from=` anchor given, this is set to the `[ANCHOR, POSITION, ORIENT, SPIN]` information for that anchor.
//   `$attach_to` is set to `undef`.
//   `$edge_angle` is set to the angle of the edge if the anchor is on an edge and the parent is a prismoid, or vnf with "hull" anchoring
//   `$edge_length` is set to the length of the edge if the anchor is on an edge and the parent is a prismoid, or vnf with "hull" anchoring
// Example:
//   spheroid(d=20) {
//       position(TOP) cyl(l=10, d1=10, d2=5, anchor=BOTTOM);
//       position(RIGHT) cyl(l=10, d1=10, d2=5, anchor=BOTTOM);
//       position(FRONT) cyl(l=10, d1=10, d2=5, anchor=BOTTOM);
//   }
module position(at,from)
{
    if (is_def(from)){
      echo("'from' argument of position() has changed to 'at' and will be removed in a future version");
    }
    dummy0=assert(num_defined([at,from])==1, "Cannot give both `at` argument and the deprectated `from` argument to position()");
    at = first_defined([at,from]);
    req_children($children);
    dummy1=assert($parent_geom != undef, "No object to position relative to.");
    anchors = (is_vector(at)||is_string(at))? [at] : at;
    two_d = _attach_geom_2d($parent_geom);
    for (anchr = anchors) {
        anch = _find_anchor(anchr, $parent_geom);
        $edge_angle = len(anch)==5 ? struct_val(anch[4],"edge_angle") : undef;
        $edge_length = len(anch)==5 ? struct_val(anch[4],"edge_length") : undef;
        $attach_to = undef;
        $attach_anchor = anch;
        translate(anch[1]) children();
    }
}



// Module: orient()
// Synopsis: Orients children's tops in the directon of the specified anchor.
// SynTags: Trans
// Topics: Attachments
// See Also: attachable(), attach(), position()
// Usage:
//   PARENT() orient(anchor, [spin]) CHILDREN;
// Description:
//   Orients children such that their top is tilted in the direction of the specified parent anchor point. 
//   For a step-by-step explanation of attachments, see the [Attachments Tutorial](Tutorial-Attachment-Relative-Positioning).
// Arguments:
//   anchor = The anchor on the parent which you want to match the orientation of.
//   spin = The spin to add to the children.  (Overrides anchor spin.)
// Side Effects:
//   `$attach_to` is set to `undef`.
// Example: When orienting to an anchor, the spin of the anchor may cause confusion:
//   prismoid([50,50],[30,30],h=40) {
//       position(TOP+RIGHT)
//           orient(RIGHT)
//               prismoid([30,30],[0,5],h=20,anchor=BOT+LEFT);
//   }
// Example: You can override anchor spin with `spin=`.
//   prismoid([50,50],[30,30],h=40) {
//       position(TOP+RIGHT)
//           orient(RIGHT,spin=0)
//               prismoid([30,30],[0,5],h=20,anchor=BOT+LEFT);
//   }
// Example: Or you can anchor the child from the back
//   prismoid([50,50],[30,30],h=40) {
//       position(TOP+RIGHT)
//           orient(RIGHT)
//               prismoid([30,30],[0,5],h=20,anchor=BOT+BACK);
//   }
module orient(anchor, spin) {
    req_children($children);
    check=
      assert($parent_geom != undef, "No parent to orient from!")
      assert(is_string(anchor) || is_vector(anchor));
    anch = _find_anchor(anchor, $parent_geom);
    two_d = _attach_geom_2d($parent_geom);
    fromvec = two_d? BACK : UP;
    spin = default(spin, anch[3]);
    dummy=assert(is_finite(spin));

    $attach_to = undef;
    if (two_d)
        rot(spin)rot(from=fromvec, to=anch[2]) children();
    else
        rot(spin, from=fromvec, to=anch[2]) children();
}


// Module: align()
// Synopsis: Position children with alignment to parent edges.
// SynTags: Trans
// Topics: Attachments
// See Also: attachable(), attach(), position(), orient()
// Usage:
//   PARENT() align(anchor, [align], [inside=], [inset=], [shiftout=], [overlap=]) CHILDREN;
// Description:
//   Place a child on the face identified by `anchor`.  If align is not given or is CENTER
//   then the child will be centered on top of the specified face, outside the parent object.  The align parameter is a
//   direction defining an edge or corner to align to.  The child will be aligned to that edge or corner by
//   choosing an appropriate anchor on the child.  
//   Like {{position()}} this module never rotates the child.  If you give `anchor=RIGHT` then the child
//   will be given the LEFT anchor and placed adjacent to the parent.  You can use `orient=` or `spin=`
//   with the child and the alignment will adjust to select the correct child anchor.  Note that if
//   you spin the child by an amount not a multiple of 90 degrees then an edge of the child will be
//   placed against the parent.  This module makes it easy to place children aligned flush with the edges
//   of the parent, even after orienting them or spinning them.  In contrast {{position()}} can 
//   do the same thing but you would have to figure out the correct child anchor, which is not always obvious.
//   .
//   Because `align()` works by setting the child anchor, it overrides any anchor you specify to the child:
//   **any `anchor=` value given to the child is ignored.**
//   .
//   Several options can adjust how the child is positioned.  You can specify `inset=` to inset the
//   aligned object from its alignment location. If you set `inside=true` then the
//   child will appear inside the parent instead of on its surface so that you can use {{diff()}} to subract it.
//   In this case the child recieved a default "remove" tag.   The `shiftout=` option works with `inside=true` to 
//   shift the child out by the specified distance so that the child doesn't exactly align with the parent.
//   .
//   Note that in the description above the anchor was said to define a "face".  You can also use this module
//   with an edge anchor, in which case a corner of the child will be placed in contact with the specified
//   edge and the align direction will shift the child to either end of the edge.  You can even give a
//   corner as the anchor point, but in that case the only allowed alignment is CENTER.
//   .
//   If you give a list of anchors and/or a list of align directions then all combinations are generated.
//   In this way align() acts like a distributor, creating multiple copies of the child.  
//   Named anchors are not supported by `align()`.  
// Arguments:
//   anchor = parent anchor or list of parent anchors for positioning children.
//   align = optional alignment direction or directions for aligning the children.  Default: CENTER
//   ---
//   inside = if true, place object inside the parent instead of outside.  Default: false
//   inset = shift the child away from the alignment edge/corner by this amount.  Default: 0
//   shiftout = Shift an inside object outward so that it overlaps all the aligned faces.  Default: 0
//   overlap = Amount to sink the child into the parent.  Defaults to `$overlap` which is zero by default.
// Side Effects:
//   `$anchor` set to the anchor value used for the child.
//   `$align` set to the align value used for the child.
//   `$idx` set to a unique index for each child, increasing by alignment first.
//   `$attach_anchor` for each anchor given, this is set to the `[ANCHOR, POSITION, ORIENT, SPIN]` information for that anchor.
//   if `inside` is true then set default tag to "remove"
// Example:  Cuboid positioned on the right of its parent.  Note that it is in its native orientation.  
//   cuboid([20,35,25])
//     align(RIGHT)
//       color("lightgreen")cuboid([5,1,9]);
// Example: Child would require anchor of RIGHT+FRONT+BOT if placed with {{position()}}. 
//   cuboid([50,40,15])
//     align(TOP,RIGHT+FRONT)
//       color("lightblue")prismoid([10,5],[7,4],height=4);
// Example: Child requires a different anchor for each position, so a simple explicit specification of the anchor for children is impossible in this case, without using two separate commands.
//   cuboid([50,40,15])
//     align(TOP,[RIGHT,LEFT])
//       color("lightblue")prismoid([10,5],[7,4],height=4);
// Example: If you spin the child 90 deg it is still flush with the edge of the parent.  In this case the required anchor for the child is BOT+FWD:
//   cuboid([50,40,15])
//     align(TOP,RIGHT)
//       color("lightblue")
//          prismoid([10,5],[7,4],height=4,spin=90);
// Example: Here the child is placed on the RIGHT face.  Notice how the TOP+LEFT anchor of the prismoid is aligned with the edge of the parent.  The prismoid remains in the same orientation.  
//   cuboid([50,40,15])
//     align(RIGHT,TOP)
//       color("lightblue")prismoid([10,5],[7,4],height=4);
// Example: If you change the orientation of the child it still appears aligned flush in its changed orientation:
//   cuboid([50,40,15])
//     align(TOP, RIGHT)
//       color("lightblue")prismoid([10,5],[7,4],height=4,orient=DOWN);
// Example: The center of the cubes edge is lined up with the center of the prismoid edge, so this result is the expected result:  
//   prismoid(50,30,25)
//     align(RIGHT,FRONT)
//       color("lightblue")cuboid(8);
// Example: Spinning the cube means that the corner of the cube is the most extreme point, so that's what aligns with the front edge of the parent:
//   cuboid([50,40,15])
//     align(TOP,FWD)
//       color("lightblue")cuboid(9,spin=22);
// Example: A similar thing happens if you attach a cube to a cylinder with an arbitrary anchor angle:
//   cyl(h=20,d=10,$fn=128)
//     align([1,.3],TOP)
//       color("lightblue")cuboid(5);
// Example: Orienting the child is done in the global coordinate system (as usual) not in the parent coordinate system.  Note that the blue prismoid is not lined up with the parent face.  (To place the child on the face use {{attach()}}.
//   prismoid(50,30,25)
//     align(RIGHT)
//      color("lightblue")prismoid([10,5],[7,4],height=4,orient=RIGHT);
// Example: Setting `inside=true` enables us to subtract the child from the parent with {{diff()}}.  The "remove" tag is automatically applied when you set `inside=true`, and we used `shiftout=0.01` to prevent z-fighting on the faces.  
//   diff()
//     cuboid([40,30,10])
//       align(FRONT,TOP,inside=true,shiftout=0.01)
//         prismoid([10,5],[7,5],height=4);
// Example: Setting `inset` shifts all of the children away from their aligned edge, which is a different direction for each child.  
//   cuboid([40,30,30])
//     align(FRONT,[TOP,BOT,LEFT,RIGHT,TOP+RIGHT,BOT+LEFT], inset=3)
//       color("green") cuboid(5);
// Example: Changing the child characteristics based on the alignment
//   cuboid([20,20,8])
//     align(TOP,[for(i=[-1:1], j=[-1:1]) [i,j]])
//       color("orange")
//         if (norm($align)==0) cuboid([3,3,1]);
//         else if (norm($align)==norm([1,1])) cuboid([3,3,4.5]);
//         else cuboid(3);
// Example:  In this example the pink cubes are positioned onto an edge.  They meet edge-to-edge.  Aligning left shifts the cube to the left end of the edge. 
//   cuboid([30,30,20])
//      align(TOP+BACK,[CTR,LEFT])
//        color("pink")cuboid(4);
// Example: Normally `overlap` is used to create a tiny overlap to keep CGAL happy, but you can also give it a large value as shown here:
//   cuboid([30,30,20])
//     align(TOP+BACK,[RIGHT,CTR,LEFT],overlap=2)
//       color("lightblue")cuboid(4);

module align(anchor,align=CENTER,inside=false,inset=0,shiftout=0,overlap)
{
    req_children($children);
    overlap = (overlap!=undef)? overlap : $overlap;
    dummy1=assert($parent_geom != undef, "No object to align to.")
           assert(is_undef($attach_to), "Cannot use align() as a child of attach()");
    anchor = is_vector(anchor) ? [anchor] : anchor;
    align = is_vector(align) ? [align] : align;
    two_d = _attach_geom_2d($parent_geom);
    factor = ($anchor_inside ? -1 : 1)*(inside?-1:1);
    for (i = idx(anchor)) {
        $align_msg=false;     // Remove me when removing the message above
        face = anchor[i];
        $anchor=face;
        dummy=
          assert(!is_string(face),
                 str("Named anchor \"",face,"\" given for anchor, but align() does not support named anchors"))
          assert(is_vector(face) && (len(face)==2 || len(face)==3),
                 str("Invalid face ",face, ".  Must be a 2-vector or 3-vector"));
        thisface = two_d? _force_anchor_2d(face) : point3d(face);
        for(j = idx(align)) {
          edge=align[j];
          $idx = j+len(align)*i;
          $align=edge;
          dummy1=assert(is_vector(edge) && (len(edge)==2 || len(edge)==3),
                        "align direction must be a 2-vector or 3-vector");
          thisedge = two_d? _force_anchor_2d(edge) : point3d(edge);
          dummy=assert(all_zero(v_mul(thisedge,thisface)),
                       str("align (",thisedge,") cannot include component parallel to anchor ",thisface));
          thisface_anch = _find_anchor(thisface, $parent_geom);
          inset_dir = two_d ? -thisface
                    : unit(thisface_anch[1]-_find_anchor([thisedge.x,0,0]+thisface, $parent_geom)[1],CTR)
                       +unit(thisface_anch[1]-_find_anchor([0,thisedge.y,0]+thisface, $parent_geom)[1],CTR)
                       +unit(thisface_anch[1]-_find_anchor([0,0,thisedge.z]+thisface, $parent_geom)[1],CTR);
          
          pos_anch = _find_anchor(thisface+thisedge, $parent_geom);
          $attach_alignment = thisedge-factor*thisface;
          $attach_anchor=list_set(pos_anch,2,UP);
          translate(pos_anch[1]
                    +inset*inset_dir
                    +shiftout*(thisface_anch[2]-inset_dir)
                    -overlap*thisface_anch[2])
              default_tag("remove",inside) children();                  
        }
    }
}

// Quantize anchor entry to {-1,0,1}
function _quant_anch(x) = approx(x,0) ? 0 : sign(x);

// Make arbitrary anchor legal for a given geometry
function _make_anchor_legal(anchor,geom) =
   in_list(geom[0], ["prismoid","trapezoid"]) ? [for(v=anchor) _quant_anch(v)]
 : in_list(geom[0], ["conoid", "extrusion_extent"]) ? [anchor.x,anchor.y, _quant_anch(anchor.z)]
 : anchor;
    


// Module: attach()
// Synopsis: Attaches children to a parent object at an anchor point and with anchor orientation.
// SynTags: Trans
// Topics: Attachments
// See Also: attachable(), position(), align(), face_profile(), edge_profile(), corner_profile()
// Usage:
//   PARENT() attach(parent, child, [align=], [spin=], [overlap=], [inside=], [inset=], [shiftout=]) CHILDREN;
//   PARENT() attach(parent, [overlap=], [spin=]) CHILDREN;
// Description:
//   Attaches children to a parent object at an anchor point or points, oriented in the anchor direction.
//   This module differs from {{position()}} and {{align()}} in that it rotates the children to
//   the anchor direction, which generally means it places the children on the surface of a parent.
//   There are two modes of operation, parent anchor (single argument) and parent-child anchor (double argument).
//   In most cases you should use the parent-child (double argument) version of `attach()`.  
//   .
//   The parent-child anchor (double argument) version is usually easier to use, and it is more powerful because it supports
//   alignment.  You provide an anchor on the parent (`parent`) and an anchor on the child (`child`).
//   This module connects the `child` anchor on the child to the `parent` anchor on the parent.  
//   Imagine pointing the parent and child anchor arrows at each other and pushing the objects
//   together until they meet at the anchor point.    The most basic case
//   is `attach(TOP,BOT)` which puts the bottom of the child onto the top of the parent.  If you
//   do `attach(RIGHT,BOT)` this puts the bottom of the child onto the right anchor of the parent.
//   When an object is attached to the top or bottom its BACK direction will remaing pointing BACK.
//   When an object is attached to one of the other anchors its FRONT will be pointed DOWN and its
//   BACK pointed UP.  You can change this using the `spin=` argument to attach().  Note that this spin
//   rotates around the attachment vector and is not the same as the spin argument to the child, which
//   will usually rotate around some other direction that may be hard to predict.  For 2D objects you cannot
//   give spin because it is not possible to spin around the attachment vector; spinning the object around the Z axis
//   would change the child orientation so that the anchors are no longer parallel.  Furthermore, any spin
//   parameter you give to the child will be ignored so that the attachment condition of parallel anchors is preserved.  
//   .
//   As with {{align()}} you can use the `align=` parameter to align the child to an edge or corner of the
//   face where that child is attached.  For example `attach(TOP,BOT,align=RIGHT)` would stand the child
//   up on the top while aligning it with the right edge of the top face, and `attach(RIGHT,BOT,align=TOP)` which
//   stand the object on the right face while aligning with the top edge.  If you apply spin using the
//   argument to `attach()` then it will be taken into account for the alignment.  If you apply spin with
//   a parameter to the child it will NOT be taken into account.  The special spin value "align" will
//   spin the child so that the child's BACK direction is pointed towards the aligned edge on the parent. 
//   Note that spin is not permitted for
//   2D objects because it would change the child orientation so that the anchors are no longer parallel.  
//   When you use `align=` you can also adjust the position using `inset=`, which shifts the child
//   away from the edge or corner it is aligned to.
//   .
//   Note that the concept of alignment doesn't always make sense for objects without corners, such as spheres or cylinders.
//   In same cases the alignments using such children will be odd because the alignment computation is trying to
//   place a non-existent corner somewhere.  Because attach() doesn't have in formation about the child when
//   it runs it cannot handle curved shapes differently from cubes, so this behavior cannot be changed.  
//   .
//   If you give `inside=true` then the anchor arrows are lined up so they are pointing the same direction and
//   the child object will be located inside the parent.  In this case a default "remove" tag is applied to
//   the children.  
//   .
//   Because the attachment process forces an orientation and anchor point for the child, it overrides
//   any such specifications you give to the child:  **both `anchor=` and `orient=` given to the child are
//   ignored** with the **double argument** version of `attach()`.  As noted above, you can give `spin=` to the
//   child but using the `spin=` parameter to `attach()` is more likely to be useful.
//   .
//   You can overlap attached children into the parent by giving the `$overlap` value
//   which is 0 by default, or by the `overlap=` argument.    This is to prevent OpenSCAD
//   from making non-manifold objects.  You can define `$overlap=` as an argument in a parent
//   module to set the default for all attachments to it.  When you give `inside=true`, a positive overlap
//   value shifts the child object outward.
//   .
//   If you specify an `inset=` value then the child is shifted away from any edges it is aligned to, towards the middle
//   of the parent.  The `shiftout=` parameter is intended to simplify differences with aligned objects
//   placed inside the parent.  It will shift the child outward along every direction where it is aligned with
//   the parent.  For an inside child this is equivalent to giving a positive overlap and negative inset value.
//   For a child with `inside=false` it is equivalent to a negative overlap and negative inset.  
//   .
//   The single parameter version of `attach()` is rarely needed; to use it, you give only the `parent` anchor.  The `align` direction
//   is not permitted.  In this case the child is placed at the specified parent anchor point
//   and rotated to the anchor direction.  For example, `attach(TOP) cuboid(2);` will place a small
//   cube **with its center** located at the TOP anchor of the parent, so just half the cube will project
//   from the parent.  If you want the cube sitting on the parent you need to anchor the cube to its bottom:
//   `attach(TOP) cuboid(2,anchor=BOT);`.
//   .
//   The **single argument** version of `attach()` **respects `anchor=` and `orient=` given to the child.**
//   These options will probably be necessary, in fact, to get the child correctly positioned.  Note that
//   giving `spin=` to `attach()` in this case is the same as applying `zrot()` to the child. 
//   .
//   For a step-by-step explanation of attachments, see the [Attachments Tutorial](Tutorial-Attachment-Relative-Positioning).
// Arguments:
//   parent = The parent anchor point to attach to or a list of parent anchor points.
//   child = Optional child anchor point.  If given, orients the child to connect this anchor point to the parent anchor.
//   ---
//   align = If `child` is given you can specify alignment or list of alistnments to shift the child to an edge or corner of the parent. 
//   inset = Shift aligned children away from their alignment edge/corner by this amount.  Default: 0
//   overlap = Amount to sink child into the parent.  Equivalent to `down(X)` after the attach.  This defaults to the value in `$overlap`, which is `0` by default.
//   inside = If `child` is given you can set `inside=true` to attach the child to the inside of the parent for diff() operations.  Default: false
//   shiftout = Shift an inside object outward so that it overlaps all the aligned faces.  Default: 0
//   spin = Amount to rotate the parent around the axis of the parent anchor.  Can set to "align" to align the child's BACK with the parent aligned edge.  (Only permitted in 3D.)
// Side Effects:
//   `$anchor` set to the parent anchor value used for the child.
//   `$align` set to the align value used for the child.  
//   `$idx` set to a unique index for each child, increasing by alignment first.
//   `$attach_anchor` for each anchor given, this is set to the `[ANCHOR, POSITION, ORIENT, SPIN]` information for that anchor.
//   if inside is true then set default tag to "remove"
//   `$attach_to` is set to the value of the `child` argument, if given.  Otherwise, `undef`
//   `$edge_angle` is set to the angle of the edge if the anchor is on an edge and the parent is a prismoid or vnf with "hull" anchoring
//   `$edge_length` is set to the length of the edge if the anchor is on an edge and the parent is a prismoid or vnf with "hull" anchoring
// Example: Cylinder placed on top of cube:
//   cuboid(50)
//     attach(TOP,BOT) cylinder(d1=30,d2=15,h=25);
// Example: Cylinder on right and front side of cube:
//   cuboid(50)
//     attach([RIGHT,FRONT],BOT) cylinder(d1=30,d2=15,h=25);
// Example:  Using `align` can align child object(s) with edges
//   prismoid(50,25,25) color("green"){
//     attach(TOP,BOT,align=[BACK,FWD]) cuboid(4);
//     attach(RIGHT,BOT,align=[TOP,BOT]) cuboid(4);
//   }
// Example: One aligned to the corner upside down (light blue) and one inset fromt the corner (pink), one aligned on a side (orange) and one rotated and aligned (green).
//   cuboid(30) {
//     attach(TOP,TOP,align=FRONT+RIGHT) color("lightblue") prismoid(5,3,3);
//     attach(TOP,BOT,inset=3,align=FRONT+LEFT) color("pink") prismoid(5,3,3);
//     attach(FRONT,RIGHT,align=TOP) color("orange") prismoid(5,3,3);
//     attach(FRONT,RIGHT,align=RIGHT,spin=90) color("lightgreen") prismoid(5,3,3);    
//   }
// Example: Rotation not a multiple of 90 degrees with alignment.  The children are aligned on a corner.  
//   cuboid(30)
//     attach(FRONT,BOT,spin=33,align=[RIGHT,LEFT,TOP,BOT,RIGHT+TOP])
//       color("lightblue")cuboid(4);
// Example: Anchoring the cone onto the sphere gives a single point of contact. 
//   spheroid(d=20) 
//       attach([1,1.5,1], BOTTOM) cyl(l=11.5, d1=10, d2=5);
// Example: Using the `overlap` option can help:
//   spheroid(d=20) 
//       attach([1,1.5,1], BOTTOM, overlap=1.5) cyl(l=11.5, d1=10, d2=5);
// Example: Alignment works on the sides of cylinders but you can only align with either the top or bototm face:
//   cyl(h=30,d=10)
//     attach([LEFT,[1,1.3]], BOT,align=TOP) cuboid(6);
// Example: Attaching to edges.  The light blue and orange objects are attached to edges.  The purple object is attached to an edge and aligned. 
//   prismoid([20,10],[10,10],7){
//     attach(RIGHT+TOP,BOT,align=FRONT) color("pink")cuboid(2);
//     attach(BACK+TOP, BOT) color("lightblue")cuboid(2);
//     attach(RIGHT+BOT, RIGHT) color("orange")cyl(h=8,d=1);
//   }
// Example: Attaching inside the parent.  For inside attachment the anchors are lined up pointing the same direction, so the most natural way to anchor the child is using its TOP anchor.  This is equivalent to anchoring outside with the BOTTOM anchor and then lowering the child into the parent by its full depth.  
//   back_half()
//     diff()
//     cuboid(20)
//       attach(TOP,TOP,inside=true,shiftout=0.01) cyl(d1=10,d2=5,h=10);
// Example: Attaching inside the parent with alignment
//   diff()
//   cuboid(20){
//     attach(TOP,TOP,inside=true,align=RIGHT,shiftout=.01) cuboid([8,7,3]);
//     attach(TOP,TOP,inside=true,align=LEFT+FRONT,shiftout=0.01) cuboid([3,4,5]);
//     attach(RIGHT+FRONT, TOP, inside=true) cuboid([10,3,5]);
//     attach(RIGHT+FRONT, TOP, inside=true, align=TOP,shiftout=.01) cuboid([5,1,2]);  
//   }
// Example: Attaching a 3d edge mask.  Simple 2d masks can be done using {{edge_profile()}} but this mask varies along its length.
//   module wavy_edge(length,cycles, r, steps, n)
//   {
//     rmin = is_vector(r) ? r[0] : 0.01;
//     rmax = is_vector(r) ? r[1] : r;
//     layers = [for(z=[0:steps])
//                   let(
//                        r=rmin+(rmax-rmin)/2*(cos(z*360*cycles/steps)+1)
//                   )
//                   path3d( concat([[0,0]],
//                                  arc(corner=path2d([BACK,CTR,RIGHT]), n=n, r=r)),
//                           z/steps*length-length/2)
//               ];
//     attachable([rmax,rmax,length]){
//         skin(layers,slices=0);
//         children();
//     }  
//   }            
//   diff()
//   cuboid(25)
//     attach([TOP+RIGHT,TOP+LEFT,TOP+FWD, FWD+RIGHT], FWD+LEFT, inside=true, shiftout=.01)
//       wavy_edge(length=25.1,cycles=1.4,r=4,steps=24,n=15); 


module attach(parent, child, overlap, align, spin=0, norot, inset=0, shiftout=0, inside=false, from, to)
{
    dummy3=
      assert(num_defined([to,child])<2, "Cannot combine deprecated 'to' argument with 'child' parameter")
      assert(num_defined([from,parent])<2, "Cannot combine deprecated 'from' argument with 'parent' parameter")
      assert(spin!="align" || is_def(align), "Can only set spin to \"align\" when the 'align' parameter is given")
      assert(is_finite(spin) || spin=="align", "Spin must be a number (unless align is given)")
      assert((is_undef(overlap) || is_finite(overlap)) && (is_def(overlap) || is_undef($overlap) || is_finite($overlap)),
             str("Provided ",is_def(overlap)?"":"$","overlap is not valid."));
    removetag = inside;
    inside = $anchor_inside ? !inside : inside;
    if (is_def(to))
      echo("The 'to' option to attach() is deprecated and will be removed in the future.  Use 'child' instead.");
    if (is_def(from))
      echo("The 'from' option to attach(0 is deprecated and will be removed in the future.  Use 'parent' instead");
    if (norot)
      echo("The 'norot' option to attach() is deprecated and will be removed in the future.  Use position() instead.");
    req_children($children);
    
    dummy=assert($parent_geom != undef, "No object to attach to!")
          assert(is_undef(child) || is_string(child) || (is_vector(child) && (len(child)==2 || len(child)==3)),
                 "child must be a named anchor (a string) or a 2-vector or 3-vector")
          assert(is_undef(align) || !is_string(child), "child is a named anchor.  Named anchors are not supported with align=");

    two_d = _attach_geom_2d($parent_geom);
    basegeom = $parent_geom[0]=="conoid" ? attach_geom(r=2,h=2,axis=$parent_geom[5])
             : $parent_geom[0]=="prismoid" ? attach_geom(size=[2,2,2],axis=$parent_geom[4])
             : attach_geom(size=[2,2,2]);
    childgeom = attach_geom([2,2,2]);
    child_abstract_anchor = is_vector(child) && !two_d ? _find_anchor(_make_anchor_legal(child,childgeom), childgeom) : undef;
    overlap = (overlap!=undef)? overlap : $overlap;
    parent = first_defined([parent,from]);
    anchors = is_vector(parent) || is_string(parent) ? [parent] : parent;
    align_list = is_undef(align) ? [undef]
               : is_vector(align) || is_string(align) ? [align] : align;
    dummy4 = assert(is_string(parent) || is_list(parent), "Invalid parent anchor or anchor list")
             assert(spin==0 || (!two_d || is_undef(child)), "spin is not allowed for 2d objects when 'child' is given");
    child_temp = first_defined([child,to]);
    child = two_d ? _force_anchor_2d(child_temp) : child_temp;
    dummy2=assert(align_list==[undef] || is_def(child), "Cannot use 'align' without 'child'")
           assert(!inside || is_def(child), "Cannot use 'inside' without 'child'")
           assert(inset==0 || is_def(child), "Cannot specify 'inset' without 'child'")
           assert(inset==0 || is_def(align), "Cannot specify 'inset' without 'align'")
           assert(shiftout==0 || is_def(child), "Cannot specify 'shiftout' without 'child'");
    factor = inside?-1:1;
    $attach_to = child;
    for (anch_ind = idx(anchors)) {
        dummy=assert(is_string(anchors[anch_ind]) || (is_vector(anchors[anch_ind]) && (len(anchors[anch_ind])==2 || len(anchors[anch_ind])==3)),
                     str("parent[",anch_ind,"] is ",anchors[anch_ind]," but it must be a named anchor (string) or a 2-vector or 3-vector"))
              assert(align_list==[undef] || !is_string(anchors[anch_ind]),
                     str("parent[",anch_ind,"] is a named anchor (",anchors[anch_ind],"), but named anchors are not supported with align="));
        anchor = is_string(anchors[anch_ind])? anchors[anch_ind]
               : two_d?_force_anchor_2d(anchors[anch_ind])
               : point3d(anchors[anch_ind]);
        $anchor=anchor;
        anchor_data = _find_anchor(anchor, $parent_geom);
        $edge_angle = len(anchor_data)==5 ? struct_val(anchor_data[4],"edge_angle") : undef;
        $edge_length = len(anchor_data)==5 ? struct_val(anchor_data[4],"edge_length") : undef;
        $edge_end1 = len(anchor_data)==5 ? struct_val(anchor_data[4],"vec") : undef;
        anchor_pos = anchor_data[1];
        anchor_dir = factor*anchor_data[2];
        anchor_spin = two_d || !inside || anchor==TOP || anchor==BOT ? anchor_data[3]
                    : let(spin_dir = rot(anchor_data[3],from=UP, to=-anchor_dir, p=BACK))
                      _compute_spin(anchor_dir,spin_dir);
        parent_abstract_anchor = is_vector(anchor) && !two_d ? _find_anchor(_make_anchor_legal(anchor,basegeom),basegeom) : undef;
        for(align_ind = idx(align_list)){
            align = is_undef(align_list[align_ind]) ? undef
                  : assert(is_vector(align_list[align_ind],2) || is_vector(align_list[align_ind],3), "align direction must be a 2-vector or 3-vector")
                    two_d ? _force_anchor_2d(align_list[align_ind])
                  : point3d(align_list[align_ind]);
            spin = is_num(spin) ? spin
                 : align==CENTER ? 0
                 : sum(v_abs(anchor))==1 ?   // parent anchor is a face
                   let(
                       spindir = in_list(anchor,[TOP,BOT]) ? BACK : UP,
                       proj = project_plane(point4d(anchor),[spindir,align]),
                       ang = v_theta(proj[1])-v_theta(proj[0])
                   )
                   ang
                 : // parent anchor is not a face, so must be an edge (corners not allowed)
                   let(
                        nativeback = apply(rot(to=parent_abstract_anchor[2],from=UP)
                                       *affine3d_zrot(parent_abstract_anchor[3]), BACK)
                    )
                    nativeback*align<0 ? -180:0;
            $idx = align_ind+len(align_list)*anch_ind;
            $align=align;
            goodcyl = $parent_geom[0] != "conoid" || is_undef(align) || align==CTR ? true
                    : let(
                           align=rot(from=$parent_geom[5],to=UP,p=align),
                           anchor=rot(from=$parent_geom[5],to=UP,p=anchor)
                      )
                      anchor==TOP || anchor==BOT || align==TOP || align==BOT;
            badcorner = !in_list($parent_geom[0],["conoid","spheroid"]) && !is_undef(align) && align!=CTR && sum(v_abs(anchor))==3;
            badsphere = $parent_geom[0]=="spheroid" && !is_undef(align) && align!=CTR;
            dummy=assert(is_undef(align) || all_zero(v_mul(anchor,align)),
                         str("Invalid alignment: align value (",align,") includes component parallel to parent anchor (",anchor,")"))
                  assert(goodcyl, str("Cannot use align with an anchor on a curved edge or surface of a cylinder at parent anchor (",anchor,")"))
                  assert(!badcorner, str("Cannot use align at a corner anchor (",anchor,")"))
                  assert(!badsphere, "Cannot use align on spheres.");
            // Now compute position on the parent (including alignment but not inset) where the child will be anchored
            pos = is_undef(align) ? anchor_data[1] : _find_anchor(anchor+align, $parent_geom)[1];
            $attach_anchor = list_set(anchor_data, 1, pos);      // Never used;  For user informational use?  Should this be set at all?
            // Compute adjustment to the child anchor for position purposes.  This adjustment
            // accounts for the change in the anchor needed to to alignment.
            child_adjustment = is_undef(align)? CTR
                              : two_d ? rot(to=child,from=-factor*anchor,p=align)
                              : apply(   rot(to=child_abstract_anchor[2],from=UP)
                                            * affine3d_zrot(child_abstract_anchor[3])
                                            * affine3d_yrot(inside?0:180)
                                       * affine3d_zrot(-parent_abstract_anchor[3])
                                            *  rot(from=parent_abstract_anchor[2],to=UP)
                                            * rot(v=anchor,-spin),
                                      align);
            // The $anchor_override anchor value forces an override of the *position* only for the anchor
            // used when attachable() places the child
            $anchor_override = all_zero(child_adjustment)? inside?child:undef
                             : child+child_adjustment;

            reference = two_d? BACK : UP;
            // inset_dir is the direction for insetting when alignment is in effect
            inset_dir = is_undef(align) ? CTR
                      : two_d ? rot(to=reference, from=anchor,p=align)
                      : apply(affine3d_yrot(inside?180:0)
                                * affine3d_zrot(-parent_abstract_anchor[3])
                                * rot(from=parent_abstract_anchor[2],to=UP)
                                * rot(v=anchor,-spin),
                              align);

            
            spinaxis = two_d? UP : anchor_dir;
            olap = - overlap * reference - inset*inset_dir + shiftout * (inset_dir + factor*reference*($anchor_inside?-1:1));
            if (norot || (approx(anchor_dir,reference) && anchor_spin==0)) 
                translate(pos) rot(v=spinaxis,a=factor*spin) translate(olap) default_tag("remove",removetag) children();
            else  
                translate(pos)
                    rot(v=spinaxis,a=factor*spin)
                    rot(anchor_spin,from=reference,to=anchor_dir)
                    translate(olap)
                    default_tag("remove",removetag) children();
        }
    }
}



// Module: attach_part()
// Synopsis: Select a named attachable part for subsequent attachment operations
// Topics: Attachment
// See Also: attach(), align(), attachable(), define_part(), parent_part()
// Usage:
//   PARENT() attach_part(name) CHILDREN;
// Description:
//   Most attachable objects have a single geometry defined that is used by the attachment commands,
//   but some objects also define attachable parts.  This module selects 
//   an attachable part using a name defined by the parent object.  Any operations
//   that use the parent geometry such as {{attach()}}, {{align()}}, {{position()}} or {{parent()}}
//   will reference the geometry for the specified part.  This allows you to access the inner wall
//   of tubes, for example.  Note that you cannot call `attach_part()` as a child of another `attach_part()`.  
// Arguments:
//   name = name of part to use for subsequent attachments.  
// Example: This example shows attaching the light blue cube normally, on the outside of the tube, and the pink cube using the "inside" attachment part.  
//   tube(ir1=10,ir2=20,h=20, wall=3){
//     color("lightblue")attach(RIGHT,BOT) cuboid(4);
//     color("pink")
//        attach_part("inside")
//        attach(BACK,BOT) cuboid(4);
//   }  

module attach_part(name)
{
  req_children($children);
  dummy=assert(!is_undef($parent_parts), "Parent does not exist or does not have any parts");
  ind = search([name], $parent_parts, 1,0)[0];
  dummy2 = assert(ind!=[], str("Parent does not have a part named ",name));
  $parent_geom = $parent_parts[ind][1];
  $anchor_inside = $parent_parts[ind][2];
  T = $parent_parts[ind][3];
  $parent_parts = [];
  multmatrix(T)
    children();
}

 
// Section: Tagging

// Module: tag()
// Synopsis: Assigns a tag to an object
// Topics: Attachments
// See Also: tag_this(), force_tag(), recolor(), hide(), show_only(), diff(), intersect()
// Usage:
//   PARENT() tag(tag) CHILDREN;
// Description:
//   Assigns the specified tag to all of the children. Note that if you want
//   to apply a tag to non-tag-aware objects you need to use {{force_tag()}} instead.
//   This works by setting the `$tag` variable, but it provides extra error checking and
//   handling of scopes.  You may set `$tag` directly yourself, but this is not recommended.
//   .
//   For a step-by-step explanation of tagged attachments, see the [Attachments Tutorial](Tutorial-Attachment-Tags).
// Arguments:
//   tag = tag string, which must not contain any spaces.
// Side Effects:
//   Sets `$tag` to the tag you specify, possibly with a scope prefix.
// Example(3D):  Applies the tag to both cuboids instead of having to repeat `$tag="remove"` for each one.
//   diff("remove")
//     cuboid(10){
//       position(TOP) cuboid(3);
//       tag("remove")
//       {
//         position(FRONT) cuboid(3);
//         position(RIGHT) cuboid(3);
//       }
//     }
module tag(tag)
{
    req_children($children);
    check=
      assert(is_string(tag),"tag must be a string")
      assert(undef==str_find(tag," "),str("Tag string \"",tag,"\" contains a space, which is not allowed"));
    $tag = str($tag_prefix,tag);
    children();
}



// Module: tag_this()
// Synopsis: Assigns a tag to an object at the current level only.
// Topics: Attachments
// See Also: tag(), force_tag(), recolor(), hide(), show_only(), diff(), intersect()
// Usage:
//   PARENT() tag(tag) CHILDREN;
// Description:
//   Assigns the specified tag to the children at the current level only, with tags reverting to
//   the previous tag in force for deeper descendents.  This works using `$tag` and `$save_tag`.  
//   .
//   For a step-by-step explanation of tagged attachments, see the [Attachments Tutorial](Tutorial-Attachment-Tags).
// Arguments:
//   tag = tag string, which must not contain any spaces.
// Side Effects:
//   Sets `$tag` to the tag you specify, possibly with a scope prefix, and saves current tag in `$save_tag`. 
// Example(3D):  Here we subtract a cube while keeping its child.  With {{tag()}} the child would inherit the "remove" tag and we would need to explicitly retag the child to prevent it from also being subtracted.  
//   diff()
//   cuboid([10,10,4])
//     tag_this("remove")position(TOP) cuboid(3)  // This cube is subtracted
//       attach(TOP,BOT) cuboid(1);  // Tag is reset so this cube displays

module tag_this(tag)
{
    req_children($children);
    check=
      assert(is_string(tag),"tag must be a string")
      assert(undef==str_find(tag," "),str("Tag string \"",tag,"\" contains a space, which is not allowed"));
    $save_tag=default($tag,"");
    $tag = str($tag_prefix,tag);
    children();
}


// Module: force_tag()
// Synopsis: Assigns a tag to a non-attachable object.
// Topics: Attachments
// See Also: tag(), recolor(), hide(), show_only(), diff(), intersect()
// Usage:
//   PARENT() force_tag([tag]) CHILDREN;
// Description:
//   You use this module when you want to make a non-attachable or non-BOSL2 module respect tags.
//   It applies to its children the tag specified (or the tag currently in force if you don't specify a tag),
//   making a final determination about whether to show or hide the children.
//   This means that tagging in children's children will be ignored.
//   This module is specifically provided for operating on children that are not tag aware such as modules
//   that don't use {{attachable()}} or built in modules such as
//   - `polygon()`
//   - `projection()`
//   - `polyhedron()`  (or use {{vnf_polyhedron()}})
//   - `linear_extrude()`  (or use {{linear_sweep()}})
//   - `rotate_extrude()`
//   - `surface()`
//   - `import()`
//   - `difference()`
//   - `intersection()`
//   - `hull()`
//   .
//   When you use tag-based modules like {{diff()}} with a non-attachable module, the result may be puzzling.
//   Any time a test occurs for display of child() that test will succeed.  This means that when diff() checks
//   to see if it should show a module it will show it, and when diff() checks to see if it should subtract the module
//   it will subtract it.  The result will be a hole, possibly with zero-thickness edges or faces.  In order to
//   get the correct behavior, every non-attachable module needs an invocation of force_tag, even ones
//   that are not tagged.
//   .
//   For a step-by-step explanation of tagged attachments, see the [Attachments Tutorial](Tutorial-Attachment-Tags).
// Arguments:
//   tag = tag string, which must not contain any spaces
// Side Effects:
//   Sets `$tag` to the tag you specify, possibly with a scope prefix.
// Example(2D): This example produces the full square without subtracting the "remove" item.  When you use non-attachable modules with tags, results are unpredictable.
//   diff()
//   {
//     polygon(square(10));
//     move(-[.01,.01])polygon(square(5),$tag="remove");
//   }
// Example(2D): Adding force_tag() fixes the model.  Note you need to add it to *every* non-attachable module, even the untagged ones, as shown here.
//   diff()
//   {
//     force_tag()
//       polygon(square(10));
//     force_tag("remove")
//       move(-[.01,.01])polygon(square(5));
//   }
module force_tag(tag)
{
    req_children($children);
    check1=assert(is_undef(tag) || is_string(tag),"tag must be a string");
    $tag = str($tag_prefix,default(tag,$tag));
    assert(undef==str_find($tag," "),str("Tag string \"",$tag,"\" contains a space, which is not allowed"));
    if(_is_shown())
      show_all()
        children();
}



// Module: default_tag()
// Synopsis: Sets a default tag for all children.
// Topics: Attachments
// See Also: force_tag(), recolor(), hide(), show_only(), diff(), intersect()
// Usage:
//   PARENT() default_tag(tag) CHILDREN;
// Description:
//   Sets a default tag for all of the children.  This is intended to be used to set a tag for a whole module
//   that is then used outside the module, such as setting the tag to "remove" for easy operation with {{diff()}}.
//   The default_tag() module sets the `$tag` variable only if it is not already
//   set so you can have a module set a default tag of "remove" but that tag can be overridden by a {{tag()}}
//   in force from a parent.  If you use {{tag()}} it will override any previously
//   specified tag from a parent, which can be very confusing to a user trying to change the tag on a module.
//   The `do_tag` parameter allows you to apply a default tag conditionally without having to repeat the children.  
//   .
//   For a step-by-step explanation of tagged attachments, see the [Attachments Tutorial](Tutorial-Attachment-Tags).
// Arguments:
//   tag = tag string, which must not contain any spaces.
//   do_tag = if false do not set the tag.  
// Side Effects:
//   Sets `$tag` to the tag you specify, possibly with a scope prefix.
// Example(3D):  The module thing() is defined with {{tag()}} and the user applied tag of "keep_it" is ignored, leaving the user puzzled.
//   module thing() { tag("remove") cuboid(10);}
//   diff()
//     cuboid(20){
//       position(TOP) thing();
//       position(RIGHT) tag("keep_it") thing();
//   }
// Example(3D):  Using default_tag() fixes this problem: the user applied tag does not get overridden by the tag hidden in the module definition.
//   module thing() { default_tag("remove") cuboid(10);}
//   diff()
//     cuboid(20){
//       position(TOP) thing();
//       position(RIGHT) tag("keep_it") thing();
//   }
module default_tag(tag,do_tag=true)
{
    if ($tag=="" && do_tag) tag(tag) children();
    else children();
}


// Module: tag_scope()
// Synopsis: Creates a new tag scope.
// See Also: tag(), force_tag(), default_tag()
// Topics: Attachments
// Usage:
//   tag_scope([scope]) CHILDREN;
// Description:
//   Creates a tag scope with locally altered tag names to avoid tag name conflict with other code.
//   This is necessary when writing modules because the module's caller might happen to use the same tags.
//   Note that if you directly set the `$tag` variable then tag scoping will not work correctly.
//   Usually you will want to use tag_scope in the first child of {{attachable()}} to isolate the geometry
//   of your attachable object.  If you put it **outside** the {{attachable()}} call, then it will
//   set a scope that also applies to the children passed to your attachable object, which is probably not what you want.  
// Side Effects:
//   `$tag_prefix` is set to the value of `scope=` if given, otherwise is set to a random string.
// Example(3D,NoAxes): In this example, tag_scope() is required for things to work correctly. 
//   module myring(){
//      attachable(anchor=CENTER, spin=0, d=60, l=60) {
//         tag_scope()
//         diff()
//           cyl(d=60, l=60){
//              tag("remove")
//                color_this("lightblue")
//                cyl(d=30, l=61);
//           }      
//         children();
//      }
//   }
//   diff()
//     myring()
//       color_this("green") cyl(d=20, l=61)
//         tag("remove") color_this("yellow") cyl(d=10, l=65);
// Example(3D,NoAxes): Without tag_scope() we get this result
//   module myring(){
//      attachable(anchor=CENTER, spin=0, d=60, l=60) {
//         diff()
//           cyl(d=60, l=60){
//              tag("remove")
//                color_this("lightblue")
//                cyl(d=30, l=61);
//           }      
//         children();
//      }
//   }
//   diff()
//     myring()
//       color_this("green") cyl(d=20, l=61)
//         tag("remove") color_this("yellow") cyl(d=10, l=65);
// Example(3D,NoAxes): If the tag_scope() is outside the attachable() call then the scope applies to the children and something different goes wrong:
//   module myring(){
//      tag_scope()
//      attachable(anchor=CENTER, spin=0, d=60, l=60) {
//         diff()
//           cyl(d=60, l=60){
//              tag("remove")
//                color_this("lightblue")
//                cyl(d=30, l=61);
//           }      
//         children();
//      }
//   }
//   diff()
//     myring()
//       color_this("green") cyl(d=20, l=61)
//         tag("remove") color_this("yellow") cyl(d=10, l=65);
// Example: In this example the myring module uses "remove" tags which will conflict with use of the same tags elsewhere in a diff() operation, even without a parent-child relationship.  Without the tag_scope() the result is a solid cylinder.    
//   module myring(r,h,w=1,anchor,spin,orient)
//   {
//       attachable(anchor,spin,orient,r=r,h=h){
//         tag_scope("myringscope")
//         diff()
//           cyl(r=r,h=h)
//             tag("remove") cyl(r=r-w,h=h+1);
//         children();
//       }
//   }
//   // Calling the module using "remove" tags
//   // will conflict with internal tag use in
//   // the myring module.
//   $fn=32;
//   diff(){
//       myring(10,7,w=4);
//       tag("remove")myring(8,8);
//       tag("remove")diff("rem"){
//          myring(9.5,8,w=1);
//          tag("rem")myring(9.5,8,w=.3);
//       }
//     }
module tag_scope(scope){
  req_children($children);
  scope = is_undef(scope) ? rand_str(20) : scope;
  assert(is_string(scope), "scope must be a string");
  assert(undef==str_find(scope," "),str("Scope string \"",scope,"\" contains a space, which is not allowed"));
  $tag_prefix=scope;
  children();
}


// Section: Tagged Operations with Attachable Objects

// Module: diff()
// Synopsis: Performs a differencing operation using tags rather than hierarchy to control what happens.
// Topics: Attachments
// See Also: tag(), force_tag(), recolor(), show_only(), hide(), tag_diff(), intersect(), tag_intersect()
// Usage:
//   diff([remove], [keep]) PARENT() CHILDREN;
// Description:
//   Performs a differencing operation using tags to control what happens.  This is specifically intended to
//   address the situation where you want differences between a parent and child object, something
//   that is impossible with the native difference() module.
//   The children to diff are grouped into three categories, regardless of nesting level.
//   The `remove` argument is a space delimited list of tags specifying objects to
//   subtract.  The `keep` argument is a similar list of tags giving objects to be kept.
//   Objects not matching either the `remove` or `keep` lists form the third category of base objects.
//   To produce its output, diff() forms the union of all the base objects and then
//   subtracts all the objects with tags in `remove`.  Finally it adds in objects listed in `keep`.
//   Attachable objects should be tagged using {{tag()}}
//   and non-attachable objects with {{force_tag()}}.
//   .
//   Remember when using tagged operations with that the operations don't happen in hierarchical order, since
//   the point of tags is to break the hierarchy.  If you tag an object with a keep tag, nothing will be
//   subtracted from it, no matter where it appears because kept objects are unioned in at the end.
//   If you want a child of an object tagged with a remove tag to stay in the model it may be
//   better to give it a tag that is not a remove tag or a keep tag.  Such an object *will* be subject to
//   subtractions from other remove-tagged objects.
//   .
//   Note that `diff()` invokes its children three times.
//   .
//   For a step-by-step explanation of tagged attachments, see the [Attachments Tutorial](Tutorial-Attachment-Tags).
// Arguments:
//   remove = String containing space delimited set of tag names of children to difference away.  Default: `"remove"`
//   keep = String containing space delimited set of tag names of children to keep; that is, to union into the model after differencing is completed.  Default: `"keep"`
// Example: Diffing using default tags
//   diff()
//   cuboid(50) {
//       tag("remove") attach(TOP) sphere(d=40);
//       tag("keep") attach(CTR) cylinder(h=40, d=10);
//   }
// Example: The "hole" items are subtracted from everything else.  The other tags can be anything you find convenient.
//   diff("hole")
//     tag("body")sphere(d=100) {
//       tag("pole") zcyl(d=55, h=100);  // attach() not needed for center-to-center.
//       tag("hole") {
//          xcyl(d=55, h=101);
//          ycyl(d=55, h=101);
//       }
//       tag("axle")zcyl(d=15, h=140);
//     }
// Example:
//   diff(keep="axle")
//   sphere(d=100) {
//       tag("axle")xcyl(d=40, l=120);
//       tag("remove")cuboid([40,120,100]);
//   }
// Example: Masking
//   diff()
//   cube([80,90,100], center=true) {
//       edge_mask(FWD)
//           rounding_edge_mask(l=max($parent_size)*1.01, r=25);
//   }
// Example: Here we subtract the parent object from the child.  Because tags propagate to children we need to clear the "remove" tag from the child.
//  diff()
//     tag("remove")cuboid(10)
//       tag("")position(RIGHT+BACK)cyl(r=8,h=9);
// Example(3D,VPR=[104,0,200], VPT=[-0.9,3.03, -0.74], VPD=19,NoAxes,NoScales): A pipe module that subtracts its interior when you call it using diff().  Normally if you union two pipes together, you'll get interfering walls at the intersection, but not here:
//   $fn=16;
//   // This module must be called by subtracting with "diff"
//   module pipe(length, od, id) {
//       // Strip the tag the user is using to subtract
//       tag("")cylinder(h=length, d=od, center=true);
//       // Leave the tag alone here, so this one is removed
//       cylinder(h=length+.02, d=id, center=true);
//   }
//   // Draw some intersecting pipes
//   diff(){
//     tag("remove"){
//       pipe(length=5, od=2, id=1.9);
//       zrot(10)xrot(75)
//         pipe(length=5, od=2, id=1.9);
//     }
//     // The orange bar has its center removed
//     color("orange") down(1) xcyl(h=8, d=1);
//     // "keep" preserves the interior of the blue bar intact
//     tag("keep") recolor("blue") up(1) xcyl(h=8, d=1);
//   }
//   // Objects outside the diff don't have pipe interiors removed
//   color("purple") down(2.2) ycyl(h=8, d=0.3);
// Example(3D,NoScales,NoAxes): Nested diff() calls work as expected, but be careful of reusing tag names, even hidden in submodules.
//   $fn=32;
//   diff("rem1")
//   cyl(r=10,h=10){
//     diff("rem2",$tag="rem1"){
//       cyl(r=8,h=11);
//       tag("rem2")diff("rem3"){
//           cyl(r=6,h=12);
//           tag("rem3")cyl(r=4,h=13);
//           }
//       }
//   }
// Example: This example shows deep nesting, where all the differences cross levels.  Unlike the preceding example, each cylinder is positioned relative to its parent.  Note that it suffices to use two remove tags, alternating between them at each level.
//   $fn=32;
//   diff("remA")
//     cyl(r=9, h=6)
//       tag("remA")diff("remB")
//         left(.2)position(RIGHT)cyl(r=8,h=7,anchor=RIGHT)
//           tag("remB")diff("remA")
//            left(.2)position(LEFT)cyl(r=7,h=7,anchor=LEFT)
//              tag("remA")diff("remB")
//                left(.2)position(LEFT)cyl(r=6,h=8,anchor=LEFT)
//                  tag("remB")diff("remA")
//                    right(.2)position(RIGHT)cyl(r=5,h=9,anchor=RIGHT)
//                      tag("remA")diff("remB")
//                        right(.2)position(RIGHT)cyl(r=4,h=10,anchor=RIGHT)
//                          tag("remB")left(.2)position(LEFT)cyl(r=3,h=11,anchor=LEFT);
// Example(3D,NoAxes,NoScales): When working with Non-Attachables like rotate_extrude() you must apply {{force_tag()}} to every non-attachable object.
//   back_half()
//     diff("remove")
//       cuboid(40) {
//         attach(TOP)
//           recolor("lightgreen")
//             cyl(l=10,d=30);
//         position(TOP+RIGHT)
//           force_tag("remove")
//             xrot(90)
//               rotate_extrude()
//                 right(20)
//                   circle(5);
//       }
// Example: Here is another example where two children are intersected using the native intersection operator, and then tagged with {{force_tag()}}.  Note that because the children are at the same level, you don't need to use a tagged operator for their intersection.
//  $fn=32;
//  diff()
//    cuboid(10){
//      force_tag("remove")intersection()
//        {
//          position(RIGHT) cyl(r=7,h=15);
//          position(LEFT) cyl(r=7,h=15);
//        }
//      tag("keep")cyl(r=1,h=9);
//    }
// Example: In this example the children that are subtracted are each at different nesting levels, with a kept object in between.
//   $fn=32;
//   diff()
//     cuboid(10){
//       tag("remove")cyl(r=4,h=11)
//         tag("keep")cyl(r=3,h=17)
//           tag("remove")position(RIGHT)cyl(r=2,h=18);
//     }
// Example: Combining tag operators can be tricky.  Here the `diff()` operation keeps two tags, "fullkeep" and "keep".  Then {{intersect()}} intersects the "keep" tagged item with everything else, but keeps the "fullkeep" object.
//   $fn=32;
//   intersect("keep","fullkeep")
//     diff(keep="fullkeep keep")
//       cuboid(10){
//         tag("remove")cyl(r=4,h=11);
//         tag("keep") position(RIGHT)cyl(r=8,h=12);
//         tag("fullkeep")cyl(r=1,h=12);
//     }
// Example: In this complex example we form an intersection, subtract an object, and keep some objects.  Note that for the small cylinders on either side, marking them as "keep" or removing their tag gives the same effect.  This is because without a tag they become part of the intersection and the result ends up the same.  For the two cylinders at the back, however, the result is different.  With "keep" the cylinder on the left appears whole, but without it, the cylinder at the back right is subject to intersection.
//   $fn=64;
//   diff()
//     intersect(keep="remove keep")
//       cuboid(10,$thing="cube"){
//         tag("intersect"){
//           position(RIGHT) cyl(r=5.5,h=15)
//              tag("")cyl(r=2,h=10);
//           position(LEFT) cyl(r=5.54,h=15)
//              tag("keep")cyl(r=2,h=10);
//         }
//         // Untagged it is in the intersection
//         tag("") position(BACK+RIGHT)
//           cyl(r=2,h=10,anchor=CTR);
//         // With keep the full cylinder appears
//         tag("keep") position(BACK+LEFT)
//           cyl(r=2,h=10,anchor=CTR);
//         tag("remove") cyl(r=3,h=15);
//       }
module diff(remove="remove", keep="keep")
{
    req_children($children);
    assert(is_string(remove),"remove must be a string of tags");
    assert(is_string(keep),"keep must be a string of tags");
    if (_is_shown())
    {
        difference() {
            hide(str(remove," ",keep)) children();
            show_only(remove) children();
        }
    }
    show_int(keep)children();
}


// Module: tag_diff()
// Synopsis: Performs a {{diff()}} and then sets a tag on the result.
// Topics: Attachments
// See Also: tag(), force_tag(), recolor(), show_only(), hide(), diff(), intersect(), tag_intersect()
// Usage:
//   tag_diff([tag], [remove], [keep]) PARENT() CHILDREN;
// Description:
//   Perform a differencing operation in the manner of {{diff()}} using tags to control what happens,
//   and then tag the resulting difference object with the specified tag.  This forces the specified
//   tag to be resolved at the level of the difference operation.  In most cases, this is not necessary,
//   but if you have kept objects and want to operate on this difference object as a whole object using
//   more tag operations, you will probably not get the results you want if you simply use {{tag()}}.
//   .
//   For a step-by-step explanation of tagged attachments, see the [Attachments Tutorial](Tutorial-Attachment-Tags).
// Arguments:
//   tag = Tag string to apply to this difference object.  Default: `""` (no tag)
//   remove = String containing space delimited set of tag names of children to difference away.  Default: `"remove"`
//   keep = String containing space delimited set of tag names of children to keep; that is, to union into the model after differencing is completed.  Default: `"keep"`
// Side Effects:
//   Sets `$tag` to the tag you specify, possibly with a scope prefix.
// Example: In this example we have a difference with a kept object that is then subtracted from a cube, but we don't want the kept object to appear in the final output, so this result is wrong:
//   diff("rem"){
//     cuboid([20,10,30],anchor=FRONT);
//     tag("rem")diff("remove","keep"){
//       cuboid([10,10,20]);
//       tag("remove")cuboid([11,11,5]);
//       tag("keep")cuboid([2,2,20]);
//     }
//   }
// Example: Using tag_diff corrects the problem:
//   diff("rem"){
//     cuboid([20,10,30],anchor=FRONT);
//       tag_diff("rem","remove","keep"){
//         cuboid([10,10,20]);
//         tag("remove")cuboid([11,11,5]);
//         tag("keep")cuboid([2,2,20]);
//       }
//   }
// Example: This concentric cylinder example uses "keep" and produces the wrong result.  The kept cylinder gets kept in the final output instead of subtracted.  This happens even when we make sure to change the `keep` argument at the top level {{diff()}} call.
//   diff("rem","nothing")
//     cyl(r=8,h=6)
//       tag("rem")diff()
//         cyl(r=7,h=7)
//           tag("remove")cyl(r=6,h=8)
//           tag("keep")cyl(r=5,h=9);
// Example: Changing to tag_diff() causes the kept cylinder to be subtracted, producing the desired result:
//   diff("rem")
//     cyl(r=8,h=6)
//       tag_diff("rem")
//         cyl(r=7,h=7)
//           tag("remove")cyl(r=6,h=8)
//           tag("keep")cyl(r=5,h=9);
module tag_diff(tag="",remove="remove", keep="keep")
{
    req_children($children);
    assert(is_string(remove),"remove must be a string of tags");
    assert(is_string(keep),"keep must be a string of tags");
    assert(is_string(tag),"tag must be a string");
    assert(undef==str_find(tag," "),str("Tag string \"",tag,"\" contains a space, which is not allowed"));
    $tag=str($tag_prefix,tag);
    if (_is_shown())
      show_all(){
         difference() {
            hide(str(remove," ",keep)) children();
            show_only(remove) children();
         }
         show_only(keep)children();
      }
}


// Module: intersect()
// Synopsis: Perform an intersection operation on children using tags rather than hierarchy to control what happens.
// Topics: Attachments
// See Also: tag(), force_tag(), recolor(), show_only(), hide(), diff(), tag_diff(), tag_intersect()
// Usage:
//   intersect([intersect], [keep]) PARENT() CHILDREN;
// Description:
//   Performs an intersection operation on its children, using tags to
//   determine what happens.  This is specifically intended to address
//   the situation where you want intersections involving a parent and
//   child object, something that is impossible with the native
//   intersection() module.  This module treats the children in three
//   groups: objects matching the tags listed in `intersect`, objects
//   matching tags listed in `keep`, and the remaining objects that
//   don't match any of the listed tags.  The intersection is computed
//   between the union of the `intersect` tagged objects and union of the objects that don't
//   match any of the listed tags.  Finally the objects listed in `keep` are
//   unioned with the result.  Attachable objects should be tagged using {{tag()}}
//   and non-attachable objects with {{force_tag()}}.
//   .
//   Note that `intersect()` invokes its children three times.
//   .
//   For a step-by-step explanation of tagged attachments, see the [Attachments Tutorial](Tutorial-Attachment-Tags).
// Arguments:
//   intersect = String containing space delimited set of tag names of children to intersect.  Default: "intersect"
//   keep = String containing space delimited set of tag names of children to keep whole.  Default: "keep"
// Example:
//   intersect("mask", keep="axle")
//     sphere(d=100) {
//         tag("mask")cuboid([40,100,100]);
//         tag("axle")xcyl(d=40, l=100);
//     }
// Example: Combining tag operators can be tricky.  Here the {{diff()}} operation keeps two tags, "fullkeep" and "keep".  Then `intersect()` intersects the "keep" tagged item with everything else, but keeps the "fullkeep" object.
//   $fn=32;
//   intersect("keep","fullkeep")
//     diff(keep="fullkeep keep")
//       cuboid(10){
//         tag("remove")cyl(r=4,h=11);
//         tag("keep") position(RIGHT)cyl(r=8,h=12);
//         tag("fullkeep")cyl(r=1,h=12);
//     }
// Example: In this complex example we form an intersection, subtract an object, and keep some objects.  Note that for the small cylinders on either side, marking them as "keep" or removing their tag gives the same effect.  This is because without a tag they become part of the intersection and the result ends up the same.  For the two cylinders at the back, however, the result is different.  With "keep" the cylinder on the left appears whole, but without it, the cylinder at the back right is subject to intersection.
//   $fn=64;
//   diff()
//     intersect(keep="remove keep")
//       cuboid(10,$thing="cube"){
//         tag("intersect"){
//           position(RIGHT) cyl(r=5.5,h=15)
//              tag("")cyl(r=2,h=10);
//           position(LEFT) cyl(r=5.54,h=15)
//              tag("keep")cyl(r=2,h=10);
//         }
//         // Untagged it is in the intersection
//         tag("") position(BACK+RIGHT)
//           cyl(r=2,h=10,anchor=CTR);
//         // With keep the full cylinder appears
//         tag("keep") position(BACK+LEFT)
//           cyl(r=2,h=10,anchor=CTR);
//         tag("remove") cyl(r=3,h=15);
//       }
module intersect(intersect="intersect",keep="keep")
{
   assert(is_string(intersect),"intersect must be a string of tags");
   assert(is_string(keep),"keep must be a string of tags");
   intersection(){
      show_only(intersect) children();
      hide(str(intersect," ",keep)) children();
   }
   show_int(keep) children();
}


// Module: tag_intersect()
// Synopsis: Performs an {{intersect()}} and then tags the result.
// Topics: Attachments
// See Also: tag(), force_tag(), recolor(), show_only(), hide(), diff(), tag_diff(), intersect()
// Usage:
//   tag_intersect([tag], [intersect], [keep]) PARENT() CHILDREN;
// Description:
//   Perform an intersection operation in the manner of {{intersect()}} using tags to control what happens,
//   and then tag the resulting difference object with the specified tag.  This forces the specified
//   tag to be resolved at the level of the intersect operation.  In most cases, this is not necessary,
//   but if you have kept objects and want to operate on this difference object as a whole object using
//   more tag operations, you will probably not get the results you want if you simply use {{tag()}}.
//   .
//   For a step-by-step explanation of tagged attachments, see the [Attachments Tutorial](Tutorial-Attachment-Tags).
// Arguments:
//   tag = Tag to set for the intersection.  Default: `""` (no tag)
//   intersect = String containing space delimited set of tag names of children to intersect.  Default: "intersect"
//   keep = String containing space delimited set of tag names of children to keep whole.  Default: "keep"
// Side Effects:
//   Sets `$tag` to the tag you specify, possibly with a scope prefix.
// Example:  Without `tag_intersect()` the kept object is not included in the difference.
//   $fn=32;
//   diff()
//     cuboid([20,15,9])
//     tag("remove")intersect()
//       cuboid(10){
//         tag("intersect")position(RIGHT) cyl(r=7,h=10);
//         tag("keep")position(LEFT)cyl(r=4,h=10);
//       }
// Example: Using tag_intersect corrects the problem.
//   $fn=32;
//   diff()
//     cuboid([20,15,9])
//     tag_intersect("remove")
//       cuboid(10){
//         tag("intersect")position(RIGHT) cyl(r=7,h=10);
//         tag("keep")position(LEFT)cyl(r=4,h=10);
//       }
module tag_intersect(tag="",intersect="intersect",keep="keep")
{
   assert(is_string(intersect),"intersect must be a string of tags");
   assert(is_string(keep),"keep must be a string of tags");
   assert(is_string(tag),"tag must be a string");
   assert(undef==str_find(tag," "),str("Tag string \"",tag,"\" contains a space, which is not allowed"));
   $tag=str($tag_prefix,tag);
   if (_is_shown())
     show_all(){
       intersection(){
          show_only(intersect) children();
          hide(str(intersect," ",keep)) children();
       }
       show_only(keep) children();
   }
}


// Module: conv_hull()
// Synopsis:  Performs a hull operation on the children using tags to determine what happens.
// Topics: Attachments, Hulling
// See Also: tag(), recolor(), show_only(), hide(), diff(), intersect(), hull()
// Usage:
//   conv_hull([keep]) CHILDREN;
// Description:
//   Performs a hull operation on the children using tags to determine what happens.  The items
//   not tagged with the `keep` tags are combined into a convex hull, and the children tagged with the keep tags
//   are unioned with the result.
//   .
//   Note that `conv_hull()` invokes its children twice.  
//   .
//   For a step-by-step explanation of tagged attachments, see the [Attachments Tutorial](Tutorial-Attachment-Tags).
// Arguments:
//   keep = String containing space delimited set of tag names of children to keep out of the hull.  Default: "keep"
// Example:
//   conv_hull("keep")
//      sphere(d=100, $fn=64) {
//        cuboid([40,90,90]);
//        tag("keep")xcyl(d=40, l=120);
//      }
// Example: difference combined with hull where all objects are relative to each other.
//   $fn=32;
//   diff()
//     conv_hull("remove")
//       cuboid(10)
//         position(RIGHT+BACK)cyl(r=4,h=10)
//           tag("remove")cyl(r=2,h=12);
module conv_hull(keep="keep")
{
    req_children($children);
    assert(is_string(keep),"keep must be a string of tags");
    if (_is_shown())
        hull() hide(keep) children();
    show_int(keep) children();
}


// Module: tag_conv_hull()
// Synopsis: Performs a {{conv_hull()}} and then sets a tag on the result.
// Topics: Attachments
// See Also: tag(), recolor(), show_only(), hide(), diff(), intersect()
// Usage:
//   tag_conv_hull([tag], [keep]) CHILDREN;
// Description:
//   Perform a convex hull operation in the manner of {{conv_hull()}} using tags to control what happens,
//   and then tag the resulting hull object with the specified tag.  This forces the specified
//   tag to be resolved at the level of the hull operation.  In most cases, this is not necessary,
//   but if you have kept objects and want to operate on the hull object as a whole object using
//   more tag operations, you will probably not get the results you want if you simply use {{tag()}}.
//   .
//   For a step-by-step explanation of tagged attachments, see the [Attachments Tutorial](Tutorial-Attachment-Tags).
// Arguments:
//   tag = Tag string to apply to this convex hull object.  Default: `""` (no tag)
//   keep = String containing space delimited set of tag names of children to keep out of the hull.  Default: "keep"
// Side Effects:
//   Sets `$tag` to the tag you specify, possibly with a scope prefix.
// Example: With a regular tag, the kept object is not handled as desired:
//   diff(){
//      cuboid([30,30,9])
//        tag("remove")conv_hull("remove")
//          cuboid(10,anchor=LEFT+FRONT){
//            position(RIGHT+BACK)cyl(r=4,h=10);
//            tag("keep")position(FRONT+LEFT)cyl(r=4,h=10);
//          }
//   }
// Example: Using `tag_conv_hull()` fixes the problem:
//   diff(){
//      cuboid([30,30,9])
//        tag_conv_hull("remove")
//          cuboid(10,anchor=LEFT+FRONT){
//            position(RIGHT+BACK)cyl(r=4,h=10);
//            tag("keep")position(FRONT+LEFT)cyl(r=4,h=10);
//          }
//   }
module tag_conv_hull(tag="",keep="keep")
{
    req_children($children);
    assert(is_string(keep),"keep must be a string of tags");
    assert(is_string(tag),"tag must be a string");
    assert(undef==str_find(tag," "),str("Tag string \"",tag,"\" contains a space, which is not allowed"));
    $tag=str($tag_prefix,tag);
    if (_is_shown())
      show_all(){
        hull() hide(keep) children();
        show_only(keep) children();
      }
}


// Module: hide()
// Synopsis: Hides attachable children with the given tags.
// Topics: Attachments
// See Also: tag(), recolor(), show_only(), show_all(), show_int(), diff(), intersect()
// Usage:
//   hide(tags) CHILDREN;
// Description:
//   Hides all attachable children with the given tags, which you supply as a space separated string. Previously hidden objects remain hidden, so hiding is cumulative, unlike `show_only()`.
//   For a step-by-step explanation of tagged attachments, see the [Attachments Tutorial](Tutorial-Attachment-Tags).
// Side Effects:
//   Sets `$tags_hidden` to include the tags you specify.
// Example:  Hides part of the model.
//   hide("A")
//     tag("main") cube(50, anchor=CENTER, $tag="Main") {
//       tag("A")attach(LEFT, BOTTOM) cylinder(d=30, h=30);
//       tag("B")attach(RIGHT, BOTTOM) cylinder(d=30, h=30);
//     }
// Example: Use an invisible parent to position children.  Note that children must be retagged because they inherit the parent tag.
//   $fn=16;
//   hide("hidden")
//     tag("hidden")cuboid(10)
//       tag("visible") {
//         position(RIGHT) cyl(r=1,h=12);
//         position(LEFT) cyl(r=1,h=12);
//       }
module hide(tags)
{
    req_children($children);
    dummy=assert(is_string(tags), "tags must be a string");
    taglist = [for(s=str_split(tags," ",keep_nulls=false)) str($tag_prefix,s)];
    $tags_hidden = concat($tags_hidden,taglist);
    children();
}


// Module: hide_this()
// Synopsis: Hides attachable children at the current level
// Topics: Attachments
// See Also: hide(), tag_this(), tag(), recolor(), show_only(), show_all(), show_int(), diff(), intersect()
// Usage:
//   hide_this() CHILDREN;
// Description:
//   Hides all attachable children at the current level, while still displaying descendants.  
//   For a step-by-step explanation of tagged attachments, see the [Attachments Tutorial](Tutorial-Attachment-Tags).
// Side Effects:
//   Sets `$tag` and `$save_tag`
// Example: Use an invisible parent to position children.  Unlike with {{hide()}} we do not need to explicitly use any tags.  
//   $fn=16;
//   hide_this() cuboid(10)
//       {
//         attach(RIGHT,BOT) cyl(r=1,h=5);
//         attach(LEFT,BOT) cyl(r=1,h=5);
//       }
// Example: Nesting applications of hide_this()
//   $fn=32;
//   hide_this() cuboid(10)
//     attach(TOP,BOT) cyl(r=2,h=5)
//       hide_this() attach(TOP,BOT) cuboid(4)
//         attach(RIGHT,BOT) cyl(r=1,h=2);

module hide_this()
{
  tag_scope()
    hide("child")
    tag_this("child")
    children();
}

// Module: show_only()
// Synopsis: Show only the children with the listed tags.
// See Also: tag(), recolor(), show_all(), show_int(), diff(), intersect()
// Topics: Attachments
// Usage:
//   show_only(tags) CHILDREN;
// Description:
//   Show only the children with the listed tags, which you supply as a space separated string.  Only unhidden objects will be shown, so if an object is hidden either before or after the `show_only()` call then it will remain hidden.  This overrides any previous `show_only()` calls.  Unlike `hide()`, calls to `show_only()` are not cumulative.
//   For a step-by-step explanation of tagged attachments, see the [Attachments Tutorial](Tutorial-Attachment-Tags).
// Side Effects:
//   Sets `$tags_shown` to the tag you specify.
// Example:  Display the attachments but not the parent
//   show_only("visible")
//     cube(50, anchor=CENTER)
//       tag("visible"){
//         attach(LEFT, BOTTOM) cylinder(d=30, h=30);
//         attach(RIGHT, BOTTOM) cylinder(d=30, h=30);
//       }
module show_only(tags)
{
    req_children($children);
    dummy=assert(is_string(tags), str("tags must be a string",tags));
    taglist = [for(s=str_split(tags," ",keep_nulls=false)) str($tag_prefix,s)];
    $tags_shown = taglist;
    children();
}

// Module: show_all()
// Synopsis: Shows all children and clears tags.
// See Also: tag(), recolor(), show_only(), show_int(), diff(), intersect()
// Topics: Attachments
// Usage;
//   show_all() CHILDREN;
// Description:
//   Shows all children.  Clears the list of hidden tags and shown tags so that all child objects will be
//   fully displayed.
// Side Effects:
//   Sets `$tags_shown="ALL"`
//   Sets `$tags_hidden=[]`
module show_all()
{
   req_children($children);
   $tags_shown="ALL";
   $tags_hidden=[];
   children();
}


// Module: show_int()
// Synopsis: Shows children with the listed tags which were already shown in the parent context.
// See Also: tag(), recolor(), show_only(), show_all(), show_int(), diff(), intersect()
// Topics: Attachments
// Usage:
//   show_int(tags) CHILDREN;
// Description:
//   Show only the children with the listed tags which were already shown in the parent context.
//   This intersects the current show list with the list of tags you provide.
// Arguments:
//   tags = list of tags to show
// Side Effects:
//   Sets `$tags_shown`
module show_int(tags)
{
    req_children($children);
    dummy=assert(is_string(tags), str("tags must be a string",tags));
    taglist = [for(s=str_split(tags," ",keep_nulls=false)) str($tag_prefix,s)];
    $tags_shown = $tags_shown == "ALL" ? taglist : set_intersection($tags_shown,taglist);
    children();
}


// Section: Mask Attachment


// Module: face_mask()
// Synopsis: Ataches a 3d mask shape to the given faces of the parent.
// SynTags: Trans
// Topics: Attachments, Masking
// See Also: attachable(), position(), attach(), edge_mask(), corner_mask(), face_profile(), edge_profile(), corner_profile()
// Usage:
//   PARENT() face_mask(faces) CHILDREN;
// Description:
//   Takes a 3D mask shape, and attaches it to the given faces, with the appropriate orientation to be
//   differenced away.  The mask shape should be vertically oriented (Z-aligned) with the bottom half
//   (Z-) shaped to be diffed away from the face of parent attachable shape.  If no tag is set then
//   `face_mask()` sets the tag for children to "remove" so that it will work with the default {{diff()}} tag.
//   For details on specifying the faces to mask see [Specifying Faces](attachments.scad#subsection-specifying-faces).
//   For a step-by-step explanation of masking attachments, see the [Attachments Tutorial](Tutorial-Attachment-Edge-Profiling).
// Arguments:
//   edges = Faces to mask.  See  [Specifying Faces](attachments.scad#subsection-specifying-faces) for information on specifying faces.  Default: All faces
// Side Effects:
//   Tags the children with "remove" (and hence sets `$tag`) if no tag is already set.
//   `$idx` is set to the index number of each face in the list of faces given.
//   `$attach_anchor` is set for each face given, to the `[ANCHOR, POSITION, ORIENT, SPIN]` information for that anchor.
// Example:
//   diff()
//   cylinder(r=30, h=60)
//       face_mask(TOP) {
//           rounding_cylinder_mask(r=30,rounding=5);
//           cuboid([5,61,10]);
//       }
// Example: Using `$idx`
//   diff()
//   cylinder(r=30, h=60)
//       face_mask([TOP, BOT])
//           zrot(45*$idx) zrot_copies([0,90]) cuboid([5,61,10]);
module face_mask(faces=[LEFT,RIGHT,FRONT,BACK,BOT,TOP]) {
    req_children($children);
    faces = is_vector(faces)? [faces] : faces;
    assert(all([for (face=faces) is_vector(face) && sum([for (x=face) x!=0? 1 : 0])==1]), "Vector in faces doesn't point at a face.");
    assert($parent_geom != undef, "No object to attach to!");
    attach(faces) {
       default_tag("remove") children();
    }
}


// Module: edge_mask()
// Synopsis: Attaches a 3D mask shape to the given edges of the parent.
// SynTags: Trans
// Topics: Attachments, Masking
// See Also: attachable(), position(), attach(), face_mask(), corner_mask(), face_profile(), edge_profile(), corner_profile()
// Usage:
//   PARENT() edge_mask([edges], [except]) CHILDREN;
// Description:
//   Takes a 3D mask shape, and attaches it to the given edges of a cuboid parent, with the appropriate orientation to be
//   differenced away.  The mask shape should be vertically oriented (Z-aligned) with the back-right
//   quadrant (X+Y+) shaped to be diffed away from the edge of parent attachable shape.  If no tag is set
//   then `edge_mask` sets the tag for children to "remove" so that it will work with the default {{diff()}} tag.
//   For details on specifying the edges to mask see [Specifying Edges](attachments.scad#subsection-specifying-edges).
//   For a step-by-step explanation of masking attachments, see the [Attachments Tutorial](Tutorial-Attachment-Edge-Profiling).
// Figure: A Typical Edge Rounding Mask
//   module roundit(l,r) difference() {
//       translate([-1,-1,-l/2])
//           cube([r+1,r+1,l]);
//       translate([r,r])
//           cylinder(h=l+1,r=r,center=true, $fn=quantup(segs(r),4));
//   }
//   roundit(l=30,r=10);
// Arguments:
//   edges = Edges to mask.  See [Specifying Edges](attachments.scad#subsection-specifying-edges).  Default: All edges.
//   except = Edges to explicitly NOT mask.  See [Specifying Edges](attachments.scad#subsection-specifying-edges).  Default: No edges.
// Side Effects:
//   Tags the children with "remove" (and hence sets `$tag`) if no tag is already set.
//   `$idx` is set to the index number of each edge.
//   `$attach_anchor` is set for each edge given, to the `[ANCHOR, POSITION, ORIENT, SPIN]` information for that anchor.
//   `$parent_size` is set to the size of the parent object.
// Example:
//   diff()
//   cube([50,60,70],center=true)
//       edge_mask([TOP,"Z"],except=[BACK,TOP+LEFT])
//           rounding_edge_mask(l=71,r=10);
module edge_mask(edges=EDGES_ALL, except=[]) {
    req_children($children);
    assert($parent_geom != undef, "No object to attach to!");
    edges = _edges(edges, except=except);
    vecs = [
        for (i = [0:3], axis=[0:2])
        if (edges[axis][i]>0)
        EDGE_OFFSETS[axis][i]
    ];
    for ($idx = idx(vecs)) {
        vec = vecs[$idx];
        vcount = (vec.x?1:0) + (vec.y?1:0) + (vec.z?1:0);
        dummy=assert(vcount == 2, "Not an edge vector!");
        anch = _find_anchor(vec, $parent_geom);
        $edge_angle = len(anch)==5 ? struct_val(anch[4],"edge_angle") : undef;
        $edge_length = len(anch)==5 ? struct_val(anch[4],"edge_length") : undef;
        $attach_to = undef;
        $attach_anchor = anch;
        rotang =
            vec.z<0? [90,0,180+v_theta(vec)] :
            vec.z==0 && sign(vec.x)==sign(vec.y)? 135+v_theta(vec) :
            vec.z==0 && sign(vec.x)!=sign(vec.y)? [0,180,45+v_theta(vec)] :
            [-90,0,180+v_theta(vec)];
        translate(anch[1]) rot(rotang)
           default_tag("remove") children();
    }
}


// Module: corner_mask()
// Synopsis: Attaches a 3d mask shape to the given corners of the parent.
// SynTags: Trans
// Topics: Attachments, Masking
// See Also: attachable(), position(), attach(), face_mask(), edge_mask(), face_profile(), edge_profile(), corner_profile()
// Usage:
//   PARENT() corner_mask([corners], [except]) CHILDREN;
// Description:
//   Takes a 3D mask shape, and attaches it to the specified corners, with the appropriate orientation to
//   be differenced away.  The 3D corner mask shape should be designed to mask away the X+Y+Z+ octant.  If no tag is set
//   then `corner_mask` sets the tag for children to "remove" so that it will work with the default {{diff()}} tag.
//   See [Specifying Corners](attachments.scad#subsection-specifying-corners) for information on how to specify corner sets.
//   For a step-by-step explanation of masking attachments, see the [Attachments Tutorial](Tutorial-Attachment-Edge-Profiling).
// Arguments:
//   corners = Corners to mask.  See [Specifying Corners](attachments.scad#subsection-specifying-corners).  Default: All corners.
//   except = Corners to explicitly NOT mask.  See [Specifying Corners](attachments.scad#subsection-specifying-corners).  Default: No corners.
// Side Effects:
//   Tags the children with "remove" (and hence sets `$tag`) if no tag is already set.
//   `$idx` is set to the index number of each corner.
//   `$attach_anchor` is set for each corner given, to the `[ANCHOR, POSITION, ORIENT, SPIN]` information for that anchor.
// Example:
//   diff()
//   cube(100, center=true)
//       corner_mask([TOP,FRONT],LEFT+FRONT+TOP)
//           difference() {
//               translate(-0.01*[1,1,1]) cube(20);
//               translate([20,20,20]) sphere(r=20);
//           }
module corner_mask(corners=CORNERS_ALL, except=[]) {
    req_children($children);
    assert($parent_geom != undef, "No object to attach to!");
    corners = _corners(corners, except=except);
    vecs = [for (i = [0:7]) if (corners[i]>0) CORNER_OFFSETS[i]];
    for ($idx = idx(vecs)) {
        vec = vecs[$idx];
        vcount = (vec.x?1:0) + (vec.y?1:0) + (vec.z?1:0);
        dummy=assert(vcount == 3, "Not an edge vector!");
        anch = _find_anchor(vec, $parent_geom);
        $attach_to = undef;
        $attach_anchor = anch;
        rotang = vec.z<0?
            [  0,0,180+v_theta(vec)-45] :
            [180,0,-90+v_theta(vec)-45];
        translate(anch[1]) rot(rotang)
            default_tag("remove") children();
    }
}


// Module: face_profile()
// Synopsis: Extrudes a 2D edge profile into a mask for all edges and corners of the given faces on the parent.
// SynTags: Geom
// Topics: Attachments, Masking
// See Also: attachable(), position(), attach(), edge_profile(), corner_profile(), face_mask(), edge_mask(), corner_mask()
// Usage:
//   PARENT() face_profile(faces, r|d=, [convexity=]) CHILDREN;
// Description:
//   Given a 2D edge profile, extrudes it into a mask for all edges and corners bounding each given face. If no tag is set
//   then `face_profile` sets the tag for children to "remove" so that it will work with the default {{diff()}} tag.
//   See  [Specifying Faces](attachments.scad#subsection-specifying-faces) for information on specifying faces.
//   For a step-by-step explanation of masking attachments, see the [Attachments Tutorial](Tutorial-Attachment-Edge-Profiling).
// Arguments:
//   faces = Faces to mask edges and corners of.
//   r = Radius of corner mask.
//   ---
//   d = Diameter of corner mask.
//   excess = Excess length to extrude the profile to make edge masks.  Default: 0.01
//   convexity = Max number of times a line could intersect the perimeter of the mask shape.  Default: 10
// Side Effects:
//   Tags the children with "remove" (and hence sets `$tag`) if no tag is already set.
//   `$idx` is set to the index number of each face.
//   `$attach_anchor` is set for each edge or corner given, to the `[ANCHOR, POSITION, ORIENT, SPIN]` information for that anchor.
//   `$profile_type` is set to `"edge"` or `"corner"`, depending on what is being masked.
// Example:
//   diff()
//   cube([50,60,70],center=true)
//       face_profile(TOP,r=10)
//           mask2d_roundover(r=10);
module face_profile(faces=[], r, d, excess=0.01, convexity=10) {
    req_children($children);
    faces = is_vector(faces)? [faces] : faces;
    assert(all([for (face=faces) is_vector(face) && sum([for (x=face) x!=0? 1 : 0])==1]), "Vector in faces doesn't point at a face.");
    r = get_radius(r=r, d=d, dflt=undef);
    assert(is_num(r) && r>=0);
    edge_profile(faces, excess=excess) children();
    corner_profile(faces, convexity=convexity, r=r) children();
}


// Module: edge_profile()
// Synopsis: Extrudes a 2d edge profile into a mask on the given edges of the parent.
// SynTags: Geom
// Topics: Attachments, Masking
// See Also: attachable(), position(), attach(), face_profile(), edge_profile_asym(), corner_profile(), edge_mask(), face_mask(), corner_mask()
// Usage:
//   PARENT() edge_profile([edges], [except], [convexity]) CHILDREN;
// Description:
//   Takes a 2D mask shape and attaches it to the selected edges, with the appropriate orientation and
//   extruded length to be `diff()`ed away, to give the edge a matching profile.  If no tag is set
//   then `edge_profile` sets the tag for children to "remove" so that it will work with the default {{diff()}} tag.
//   For details on specifying the edges to mask see [Specifying Edges](attachments.scad#subsection-specifying-edges).
//   For a step-by-step explanation of masking attachments, see the [Attachments Tutorial](Tutorial-Attachment-Edge-Profiling).
// Arguments:
//   edges = Edges to mask.  See [Specifying Edges](attachments.scad#subsection-specifying-edges).  Default: All edges.
//   except = Edges to explicitly NOT mask.  See [Specifying Edges](attachments.scad#subsection-specifying-edges).  Default: No edges.
//   excess = Excess length to extrude the profile to make edge masks.  Default: 0.01
//   convexity = Max number of times a line could intersect the perimeter of the mask shape.  Default: 10
// Side Effects:
//   Tags the children with "remove" (and hence sets `$tag`) if no tag is already set.
//   `$idx` is set to the index number of each edge.
//   `$attach_anchor` is set for each edge given, to the `[ANCHOR, POSITION, ORIENT, SPIN]` information for that anchor.
//   `$profile_type` is set to `"edge"`.
//   `$edge_angle` is set to the inner angle of the current edge.
// Example:
//   diff()
//   cube([50,60,70],center=true)
//       edge_profile([TOP,"Z"],except=[BACK,TOP+LEFT])
//           mask2d_roundover(r=10, inset=2);
// Example: Using $edge_angle on a conoid
//   diff()
//   cyl(d1=50, d2=30, l=40, anchor=BOT) {
//       edge_profile([TOP,BOT], excess=10, convexity=6) {
//           mask2d_roundover(r=8, inset=1, excess=1, mask_angle=$edge_angle);
//       }
//   }
// Example: Using $edge_angle on a prismoid
//   diff()
//   prismoid([60,50],[30,20],h=40,shift=[-25,15]) {
//       edge_profile(excess=10, convexity=20) {
//           mask2d_roundover(r=5,inset=1,mask_angle=$edge_angle,$fn=32);
//       }
//   }

module edge_profile(edges=EDGES_ALL, except=[], excess=0.01, convexity=10) {
    req_children($children);
    check1 = assert($parent_geom != undef, "No object to attach to!");
    conoid = $parent_geom[0] == "conoid";
    edges = !conoid? _edges(edges, except=except) :
        edges==EDGES_ALL? [TOP,BOT] :
        assert(all([for (e=edges) in_list(e,[TOP,BOT])]), "Invalid conoid edge spec.")
        edges;
    vecs = conoid
      ? [for (e=edges) e+FWD]
      : [
            for (i = [0:3], axis=[0:2])
            if (edges[axis][i]>0)
            EDGE_OFFSETS[axis][i]
        ];
    all_vecs_are_edges = all([for (vec = vecs) sum(v_abs(vec))==2]);
    check2 = assert(all_vecs_are_edges, "All vectors must be edges.");
    default_tag("remove")
    for ($idx = idx(vecs)) {
        vec = vecs[$idx];
        anch = _find_anchor(vec, $parent_geom);
        path_angs_T = _attach_geom_edge_path($parent_geom, vec);
        path = path_angs_T[0];
        vecs = path_angs_T[1];
        post_T = path_angs_T[2];
        $attach_to = undef;
        $attach_anchor = anch;
        $profile_type = "edge";
        multmatrix(post_T) {
            for (i = idx(path,e=-2)) {
                pt1 = select(path,i);
                pt2 = select(path,i+1);
                cp = (pt1 + pt2) / 2;
                v1 = vecs[i][0];
                v2 = vecs[i][1];
                $edge_angle = 180 - vector_angle(v1,v2);
                if (!approx(pt1,pt2)) {
                    seglen = norm(pt2-pt1) + 2 * excess;
                    move(cp) {
                        frame_map(x=-v2, z=unit(pt2-pt1)) {
                            linear_extrude(height=seglen, center=true, convexity=convexity)
                                mirror([-1,1]) children();
                        }
                    }
                }
            }
        }
    }
}


// Module: edge_profile_asym()
// Synopsis: Extrudes an asymmetric 2D profile into a mask on the given edges and corners of the parent.
// SynTags: Geom
// Topics: Attachments, Masking
// See Also: attachable(), position(), attach(), face_profile(), edge_profile(), corner_profile(), edge_mask(), face_mask(), corner_mask()
// Usage:
//   PARENT() edge_profile([edges], [except], [convexity=], [flip=], [corner_type=]) CHILDREN;
// Description:
//   Takes an asymmetric 2D mask shape and attaches it to the selected edges and corners, with the appropriate
//   orientation and extruded length to be `diff()`ed away, to give the edges and corners a matching profile.
//   If no tag is set then `edge_profile_asym()` sets the tag for children to "remove" so that it will work
//   with the default {{diff()}} tag.  For details on specifying the edges to mask see [Specifying Edges](attachments.scad#subsection-specifying-edges).
//   For a step-by-step explanation of masking attachments, see the [Attachments Tutorial](Tutorial-Attachment-Edge-Profiling).
//   The asymmetric profiles are joined consistently at the corners.  This is impossible if all three edges at a corner use the profile, hence
//   this situation is not permitted.  The profile orientation can be inverted using the `flip=true` parameter.
//   .
//   The standard profiles are located in the first quadrant and have positive X values.  If you provide a profile located in the second quadrant,
//   where the X values are negative, then it will produce a fillet.  You can flip any of the standard profiles using {{xflip()}}.  
//   Fillets are always asymmetric because at a given edge, they can blend in two different directions, so even for symmetric profiles,
//   the asymmetric logic is required.  You can set the `corner_type` parameter to select rounded, chamfered or sharp corners.
//   However, when the corners are inside (concave) corners, you must provide the size of the profile ([width,height]), because the
//   this information is required to produce the correct corner and cannot be obtain from the profile itself, which is a child object.  
// Arguments:
//   edges = Edges to mask.  See [Specifying Edges](attachments.scad#subsection-specifying-edges).  Default: All edges.
//   except = Edges to explicitly NOT mask.  See [Specifying Edges](attachments.scad#subsection-specifying-edges).  Default: No edges.
//   ---
//   excess = Excess length to extrude the profile to make edge masks.  Default: 0.01
//   convexity = Max number of times a line could intersect the perimeter of the mask shape.  Default: 10
//   flip = If true, reverses the orientation of any external profile parts at each edge.  Default false
//   corner_type = Specifies how exterior corners should be formed.  Must be one of `"none"`, `"chamfer"`, `"round"`, or `"sharp"`.  Default: `"none"`
//   size = If given the width and height of the 2D profile, will enable rounding and chamfering of internal corners when given a negative profile.
// Side Effects:
//   Tags the children with "remove" (and hence sets `$tag`) if no tag is already set.
//   `$idx` is set to the index number of each edge.
//   `$attach_anchor` is set for each edge given, to the `[ANCHOR, POSITION, ORIENT, SPIN]` information for that anchor.
//   `$profile_type` is set to `"edge"`.
//   `$edge_angle` is set to the inner angle of the current edge.
// Example:
//   ogee = [
//       "xstep",1,  "ystep",1,  // Starting shoulder.
//       "fillet",5, "round",5,  // S-curve.
//       "ystep",1,  "xstep",1   // Ending shoulder.
//   ];
//   diff()
//   cuboid(50) {
//       edge_profile_asym(FRONT)
//          mask2d_ogee(ogee);
//   }
// Example: Flipped
//   ogee = [
//       "xstep",1,  "ystep",1,  // Starting shoulder.
//       "fillet",5, "round",5,  // S-curve.
//       "ystep",1,  "xstep",1   // Ending shoulder.
//   ];
//   diff()
//   cuboid(50) {
//       edge_profile_asym(FRONT, flip=true)
//          mask2d_ogee(ogee);
//   }
// Example: Negative Chamfering
//   cuboid(50) {
//       edge_profile_asym(FWD, flip=false)
//           xflip() mask2d_chamfer(10);
//       edge_profile_asym(BACK, flip=true, corner_type="sharp")
//           xflip() mask2d_chamfer(10);
//   }
// Example: Negative Roundings
//   cuboid(50) {
//       edge_profile_asym(FWD, flip=false)
//           xflip() mask2d_roundover(10);
//       edge_profile_asym(BACK, flip=true, corner_type="round")
//           xflip() mask2d_roundover(10);
//   }
// Example: Cornerless
//   cuboid(50) {
//       edge_profile_asym(
//           "ALL", except=[TOP+FWD+RIGHT, BOT+BACK+LEFT]
//        ) xflip() mask2d_roundover(10);
//   }
// Example: More complicated edge sets
//   cuboid(50) {
//       edge_profile_asym(
//           [FWD,BACK,BOT+RIGHT], except=[FWD+RIGHT,BOT+BACK],
//           corner_type="round"
//        ) xflip() mask2d_roundover(10);
//   }
// Example: Mixing it up a bit.
//   diff()
//   cuboid(60) {
//       tag("keep") edge_profile_asym(LEFT, flip=true, corner_type="chamfer")
//           xflip() mask2d_chamfer(10);
//       edge_profile_asym(RIGHT)
//           mask2d_roundover(10);
//   }
// Example: Chamfering internal corners.
//   cuboid(40) {
//       edge_profile_asym(
//           [FWD+DOWN,FWD+LEFT],
//           corner_type="chamfer", size=[10,10]/sqrt(2)
//        ) xflip() mask2d_chamfer(10);
//   }
// Example: Rounding internal corners.
//   cuboid(40) {
//       edge_profile_asym(
//           [FWD+DOWN,FWD+LEFT],
//           corner_type="round", size=[10,10]
//        ) xflip() mask2d_roundover(10);
//   }

module edge_profile_asym(
    edges=EDGES_ALL, except=[],
    excess=0.01, convexity=10,
    flip=false, corner_type="none",
    size=[0,0]
) {
    function _corner_orientation(pos,pvec) =
        let(
            j = [for (i=[0:2]) if (pvec[i]) i][0],
            T = (pos.x>0? xflip() : ident(4)) *
                (pos.y>0? yflip() : ident(4)) *
                (pos.z>0? zflip() : ident(4)) *
                rot(-120*(2-j), v=[1,1,1])
        ) T;

    function _default_edge_orientation(edge) =
        edge.z < 0? [[-edge.x,-edge.y,0], UP] :
        edge.z > 0? [[-edge.x,-edge.y,0], DOWN] :
        edge.y < 0? [[-edge.x,0,0], BACK] :
        [[-edge.x,0,0], FWD] ;

    function _edge_transition_needs_flip(from,to) =
        let(
            flip_edges = [
                [BOT+FWD, [FWD+LEFT, FWD+RIGHT]],
                [BOT+BACK, [BACK+LEFT, BACK+RIGHT]],
                [BOT+LEFT, []],
                [BOT+RIGHT, []],
                [TOP+FWD, [FWD+LEFT, FWD+RIGHT]],
                [TOP+BACK, [BACK+LEFT, BACK+RIGHT]],
                [TOP+LEFT, []],
                [TOP+RIGHT, []],
                [FWD+LEFT, [TOP+FWD, BOT+FWD]],
                [FWD+RIGHT, [TOP+FWD, BOT+FWD]],
                [BACK+LEFT, [TOP+BACK, BOT+BACK]],
                [BACK+RIGHT, [TOP+BACK, BOT+BACK]],
            ],
            i = search([from], flip_edges, num_returns_per_match=1)[0],
            check = assert(i!=[], "Bad edge vector.")
        ) in_list(to,flip_edges[i][1]);

    function _edge_corner_numbers(vec) =
        let(
            v2 = [for (i=idx(vec)) vec[i]? (vec[i]+1)/2*pow(2,i) : 0],
            off = v2.x + v2.y + v2.z,
            xs = [0, if (!vec.x) 1],
            ys = [0, if (!vec.y) 2],
            zs = [0, if (!vec.z) 4]
        ) [for (x=xs, y=ys, z=zs) x+y+z + off];

    function _gather_contiguous_edges(edge_corners) =
        let(
            no_tri_corners = all([for(cn = [0:7]) len([for (ec=edge_corners) if(in_list(cn,ec[1])) 1])<3]),
            check = assert(no_tri_corners, "Cannot have three edges that meet at the same corner.")
        )
        _gather_contiguous_edges_r(
            [for (i=idx(edge_corners)) if(i) edge_corners[i]],
            edge_corners[0][1],
            [edge_corners[0][0]], []);

    function _gather_contiguous_edges_r(edge_corners, ecns, curr, out) =
        len(edge_corners)==0? [each out, curr] :
        let(
            i1 = [
                for (i = idx(edge_corners))
                if (in_list(ecns[0], edge_corners[i][1]))
                i
            ],
            i2 = [
                for (i = idx(edge_corners))
                if (in_list(ecns[1], edge_corners[i][1]))
                i
            ]
        ) !i1 && !i2? _gather_contiguous_edges_r(
            [for (i=idx(edge_corners)) if(i) edge_corners[i]],
            edge_corners[0][1],
            [edge_corners[0][0]],
            [each out, curr]
        ) : let(
            nu_curr = [
                if (i1) edge_corners[i1[0]][0],
                each curr,
                if (i2) edge_corners[i2[0]][0],
            ],
            nu_ecns = [
                if (!i1) ecns[0] else [
                    for (ecn = edge_corners[i1[0]][1])
                    if (ecn != ecns[0]) ecn
                ][0],
                if (!i2) ecns[1] else [
                    for (ecn = edge_corners[i2[0]][1])
                    if (ecn != ecns[1]) ecn
                ][0],
            ],
            rem = [
                for (i = idx(edge_corners))
                if (i != i1[0] && i != i2[0])
                edge_corners[i]
            ]
        )
        _gather_contiguous_edges_r(rem, nu_ecns, nu_curr, out);

    function _edge_transition_inversions(edge_string) =
        let(
            // boolean cumulative sum
            bcs = function(list, i=0, inv=false, out=[])
                    i>=len(list)? out :
                    let( nu_inv = list[i]? !inv : inv )
                    bcs(list, i+1, nu_inv, [each out, nu_inv]),
            inverts = bcs([
                false,
                for(i = idx(edge_string)) if (i)
                    _edge_transition_needs_flip(
                        edge_string[i-1],
                        edge_string[i]
                    )
            ]),
            boti = [for(i = idx(edge_string)) if (edge_string[i].z<0) i],
            topi = [for(i = idx(edge_string)) if (edge_string[i].z>0) i],
            lfti = [for(i = idx(edge_string)) if (edge_string[i].x<0) i],
            rgti = [for(i = idx(edge_string)) if (edge_string[i].x>0) i],
            idx = [for (m = [boti, topi, lfti, rgti]) if(m) m[0]][0],
            rinverts = inverts[idx] == false? inverts : [for (x = inverts) !x]
        ) rinverts;

    function _is_closed_edge_loop(edge_string) =
        let(
            e1 = edge_string[0],
            e2 = last(edge_string)
        )
        len([for (i=[0:2]) if (abs(e1[i])==1 && e1[i]==e2[i]) 1]) == 1 &&
        len([for (i=[0:2]) if (e1[i]==0 && abs(e2[i])==1) 1]) == 1 &&
        len([for (i=[0:2]) if (e2[i]==0 && abs(e1[i])==1) 1]) == 1;

    function _edge_pair_perp_vec(e1,e2) =
        [for (i=[0:2]) if (abs(e1[i])==1 && e1[i]==e2[i]) -e1[i] else 0];

    req_children($children);
    check1 = assert($parent_geom != undef, "No object to attach to!")
        assert(in_list(corner_type, ["none", "round", "chamfer", "sharp"]))
        assert(is_bool(flip));
    edges = _edges(edges, except=except);
    vecs = [
        for (i = [0:3], axis=[0:2])
        if (edges[axis][i]>0)
        EDGE_OFFSETS[axis][i]
    ];
    all_vecs_are_edges = all([for (vec = vecs) sum(v_abs(vec))==2]);
    check2 = assert(all_vecs_are_edges, "All vectors must be edges.");
    edge_corners = [for (vec = vecs) [vec, _edge_corner_numbers(vec)]];
    edge_strings = _gather_contiguous_edges(edge_corners);
    default_tag("remove")
    for (edge_string = edge_strings) {
        inverts = _edge_transition_inversions(edge_string);
        flipverts = [for (x = inverts) flip? !x : x];
        vecpairs = [
            for (i = idx(edge_string))
            let (p = _default_edge_orientation(edge_string[i]))
            flipverts[i]? [p.y,p.x] : p
        ];
        is_loop = _is_closed_edge_loop(edge_string);
        for (i = idx(edge_string)) {
            if (corner_type!="none" && (i || is_loop)) {
                e1 = select(edge_string,i-1);
                e2 = select(edge_string,i);
                vp1 = select(vecpairs,i-1);
                vp2 = select(vecpairs,i);
                pvec = _edge_pair_perp_vec(e1,e2);
                pos = [for (i=[0:2]) e1[i]? e1[i] : e2[i]];
                mirT = _corner_orientation(pos, pvec);
                $attach_to = undef;
                $attach_anchor = _find_anchor(pos, $parent_geom);
                $profile_type = "corner";
                position(pos) {
                    multmatrix(mirT) {
                        if (vp1.x == vp2.x && size.y > 0) {
                            zflip() {
                                if (corner_type=="chamfer") {
                                    fn = $fn;
                                    move([size.y,size.y]) {
                                        rotate_extrude(angle=90, $fn=4)
                                            left_half(planar=true, $fn=fn)
                                                zrot(-90) fwd(size.y) children();
                                    }
                                    linear_extrude(height=size.x) {
                                        mask2d_roundover(size.y, inset=0.01, $fn=4);
                                    }
                                } else if (corner_type=="round") {
                                    move([size.y,size.y]) {
                                        rotate_extrude(angle=90)
                                            left_half(planar=true)
                                                zrot(-90) fwd(size.y) children();
                                    }
                                    linear_extrude(height=size.x) {
                                        mask2d_roundover(size.y, inset=0.01);
                                    }
                                }
                            }
                        } else if (vp1.y == vp2.y) {
                            if (corner_type=="chamfer") {
                                fn = $fn;
                                rotate_extrude(angle=90, $fn=4)
                                    right_half(planar=true, $fn=fn)
                                        children();
                                rotate_extrude(angle=90, $fn=4)
                                    left_half(planar=true, $fn=fn)
                                        children();
                            } else if (corner_type=="round") {
                                rotate_extrude(angle=90)
                                    right_half(planar=true)
                                        children();
                                rotate_extrude(angle=90)
                                    left_half(planar=true)
                                        children();
                            } else { //corner_type == "sharp"
                                intersection() {
                                    rot([90,0, 0]) linear_extrude(height=100,center=true,convexity=convexity) children();
                                    rot([90,0,90]) linear_extrude(height=100,center=true,convexity=convexity) children();
                                }
                            }
                        }
                    }
                }
            }
        }
        for (i = idx(edge_string)) {
            $attach_to = undef;
            $attach_anchor = _find_anchor(edge_string[i], $parent_geom);
            $profile_type = "edge";
            edge_profile(edge_string[i], excess=excess, convexity=convexity) {
                if (flipverts[i]) {
                    mirror([-1,1]) children();
                } else {
                    children();
                }
            }
        }
    }
}



// Module: corner_profile()
// Synopsis: Rotationally extrudes a 2d edge profile into corner mask on the given corners of the parent.
// SynTags: Geom
// Topics: Attachments, Masking
// See Also: attachable(), position(), attach(), face_profile(), edge_profile(), corner_mask(), face_mask(), edge_mask()
// Usage:
//   PARENT() corner_profile([corners], [except], [r=|d=], [convexity=]) CHILDREN;
// Description:
//   Takes a 2D mask shape, rotationally extrudes and converts it into a corner mask, and attaches it
//   to the selected corners with the appropriate orientation. If no tag is set then `corner_profile()`
//   sets the tag for children to "remove" so that it will work with the default {{diff()}} tag.
//   See [Specifying Corners](attachments.scad#subsection-specifying-corners) for information on how to specify corner sets.
//   For a step-by-step explanation of masking attachments, see the [Attachments Tutorial](Tutorial-Attachment-Edge-Profiling).
// Arguments:
//   corners = Corners to mask.  See [Specifying Corners](attachments.scad#subsection-specifying-corners).  Default: All corners.
//   except = Corners to explicitly NOT mask.  See [Specifying Corners](attachments.scad#subsection-specifying-corners).  Default: No corners.
//   ---
//   r = Radius of corner mask.
//   d = Diameter of corner mask.
//   convexity = Max number of times a line could intersect the perimeter of the mask shape.  Default: 10
// Side Effects:
//   Tags the children with "remove" (and hence sets `$tag`) if no tag is already set.
//   `$idx` is set to the index number of each corner.
//   `$attach_anchor` is set for each corner given, to the `[ANCHOR, POSITION, ORIENT, SPIN]` information for that anchor.
//   `$profile_type` is set to `"corner"`.
// Example:
//   diff()
//   cuboid([50,60,70],rounding=10,edges="Z",anchor=CENTER) {
//       corner_profile(TOP,r=10)
//           mask2d_teardrop(r=10, angle=40);
//   }
module corner_profile(corners=CORNERS_ALL, except=[], r, d, convexity=10) {
    check1 = assert($parent_geom != undef, "No object to attach to!");
    r = max(0.01, get_radius(r=r, d=d, dflt=undef));
    check2 = assert(is_num(r), "Bad r/d argument.");
    corners = _corners(corners, except=except);
    vecs = [for (i = [0:7]) if (corners[i]>0) CORNER_OFFSETS[i]];
    all_vecs_are_corners = all([for (vec = vecs) sum(v_abs(vec))==3]);
    check3 = assert(all_vecs_are_corners, "All vectors must be corners.");
    for ($idx = idx(vecs)) {
        vec = vecs[$idx];
        anch = _find_anchor(vec, $parent_geom);
        $attach_to = undef;
        $attach_anchor = anch;
        $profile_type = "corner";
        rotang = vec.z<0?
            [  0,0,180+v_theta(vec)-45] :
            [180,0,-90+v_theta(vec)-45];
        default_tag("remove"){
            translate(anch[1]) {
                rot(rotang) {
                    down(0.01) {
                        linear_extrude(height=r+0.01, center=false) {
                            difference() {
                                translate(-[0.01,0.01]) square(r);
                                translate([r,r]) circle(r=r*0.999);
                            }
                        }
                    }
                    translate([r,r]) zrot(180) {
                        rotate_extrude(angle=90, convexity=convexity) {
                            right(r) xflip() {
                                children();
                            }
                        }
                    }
                }
            }
        }
    }
}


// Section: Making your objects attachable


// Module: attachable()
// Synopsis: Manages the anchoring, spin, orientation, and attachments for an object.
// Topics: Attachments
// See Also: reorient()
// Usage: Square/Trapezoid Geometry
//   attachable(anchor, spin, two_d=true, size=, [size2=], [shift=], [override=], ...) {OBJECT; children();}
// Usage: Circle/Oval Geometry
//   attachable(anchor, spin, two_d=true, r=|d=, ...) {OBJECT; children();}
// Usage: 2D Path/Polygon Geometry
//   attachable(anchor, spin, two_d=true, path=, [extent=], ...) {OBJECT; children();}
// Usage: 2D Region Geometry
//   attachable(anchor, spin, two_d=true, region=, [extent=], ...) {OBJECT; children();}
// Usage: Cubical/Prismoidal Geometry
//   attachable(anchor, spin, [orient], size=, [size2=], [shift=], [override=],  ...) {OBJECT; children();}
// Usage: Cylindrical Geometry
//   attachable(anchor, spin, [orient], r=|d=, l=, [axis=], ...) {OBJECT; children();}
// Usage: Conical Geometry
//   attachable(anchor, spin, [orient], r1=|d1=, r2=|d2=, l=, [axis=], ...) {OBJECT; children();}
// Usage: Spheroid/Ovoid Geometry
//   attachable(anchor, spin, [orient], r=|d=, ...) {OBJECT; children();}
// Usage: Extruded Path/Polygon Geometry
//   attachable(anchor, spin, path=, l=|h=, [extent=], ...) {OBJECT; children();}
// Usage: Extruded Region Geometry
//   attachable(anchor, spin, region=, l=|h=, [extent=], ...) {OBJECT; children();}
// Usage: VNF Geometry
//   attachable(anchor, spin, [orient], vnf=, [extent=], ...) {OBJECT; children();}
// Usage: Pre-Specified Geometry
//   attachable(anchor, spin, [orient], geom=) {OBJECT; children();}
//
// Description:
//   Manages the anchoring, spin, orientation, and attachments for OBJECT, located in a 3D volume or 2D area.
//   A managed 3D volume is assumed to be vertically (Z-axis) oriented, and centered.
//   A managed 2D area is just assumed to be centered.  The shape to be managed is given
//   as the first child to this module, and the second child should be given as `children()`.
//   For example, to manage a conical shape:
//   ```openscad
//   attachable(anchor, spin, orient, r1=r1, r2=r2, l=h) {
//       cyl(r1=r1, r2=r2, l=h);
//       children();
//   }
//   ```
//   .
//   If this is *not* run as a child of `attach()` with the `to` argument
//   given, then the following transformations are performed in order:
//   * Translates so the `anchor` point is at the origin (0,0,0).
//   * Rotates around the Z axis by `spin` degrees counter-clockwise.
//   * Rotates so the top of the part points towards the vector `orient`.
//   .
//   If this is called as a child of `attach(from,to)`, then the info
//   for the anchor points referred to by `from` and `to` are fetched,
//   which will include position, direction, and spin.  With that info,
//   the following transformations are performed:
//   * Translates this part so its anchor position matches the parent's anchor position.
//   * Rotates this part so its anchor direction vector exactly opposes the parent's anchor direction vector.
//   * Rotates this part so its anchor spin matches the parent's anchor spin.
//   .
//   In addition to handling positioning of the attachable object, 
//   this module is also responsible for handing coloring of objects with {{recolor()}} and {{color_this()}}, and
//   it is responsible for processing tags and determining whether the object should
//   display or not in the current context.  The determination based on the tags of whether to display the attachable object
//   often occurs in this module, which means that an object which does not display (e.g. a "remove" tagged object
//   inside {{diff()}}) cannot have internal {{tag()}} calls that change its tags and cause submodel
//   portions to display: the entire object simply does not run.  If you want the use the attachable object's internal tags outside
//   of the attachable object you can set `expose_tags=true` which delays the determination to display objects to the children.
//   For this to work correctly, all of the children must be attachables.  An example situation where you should set
//   `expose_tags=true` is when you want to have negative space in an attachable object that gets removed from the parent via
//   a "remove" tagged component of your attachable.  
//   .
//   Application of {{recolor()}} and {{color_this()}} also happens in this module and normally it applies to the
//   entire attachable object, so coloring commands that you give internally in the first child to `attachable()` have no effect.
//   Generally it makes sense that if a user specifies a color for an attachable object, the entire object is displayed
//   in that color, but if you want to retain control of color for sub-parts of an attachable object, you can use
//   the `keep_color=true` option, which delays the assignment of colors to the child level.  For this to work
//   correctly, all of the sub-parts of your attachable object must be attachables.  Also note that this option could
//   be confusing to users who don't understand why color commands are not working on the object.
//   .
//   Note that anchors created by attachable() are generally intended for use by the user-supplied children of the attachable object, but they
//   are available internally and can be used in the object's definition.  
//   .
//   For a step-by-step explanation of making objects attachable, see the [Attachments Tutorial](Tutorial-Attachment-Making).
//
// Arguments:
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   ---
//   size = If given as a 3D vector, contains the XY size of the bottom of the cuboidal/prismoidal volume, and the Z height.  If given as a 2D vector, contains the front X width of the rectangular/trapezoidal shape, and the Y length.
//   size2 = If given as a 2D vector, contains the XY size of the top of the prismoidal volume.  If given as a number, contains the back width of the trapezoidal shape.
//   shift = If given as a 2D vector, shifts the top of the prismoidal or conical shape by the given amount.  If given as a number, shifts the back of the trapezoidal shape right by that amount.  Default: No shift.
//   r = Radius of the cylindrical/conical volume.  Can be a scalar, or a list of sizes per axis.
//   d = Diameter of the cylindrical/conical volume.  Can be a scalar, or a list of sizes per axis.
//   r1 = Radius of the bottom of the conical volume.  Can be a scalar, or a list of sizes per axis.
//   r2 = Radius of the top of the conical volume.  Can be a scalar, or a list of sizes per axis.
//   d1 = Diameter of the bottom of the conical volume.  Can be a scalar, a list of sizes per axis.
//   d2 = Diameter of the top of the conical volume.  Can be a scalar, a list of sizes per axis.
//   l/h = Length of the cylindrical, conical, or extruded path volume along axis.
//   vnf = The [VNF](vnf.scad) of the volume.
//   path = The path to generate a polygon from.
//   region = The region to generate a shape from.
//   extent = If true, calculate anchors by extents, rather than intersection, for VNFs and paths.  Default: true.
//   cp = If given, specifies the centerpoint of the volume.  Default: `[0,0,0]`
//   offset = If given, offsets the perimeter of the volume around the centerpoint.
//   anchors = If given as a list of anchor points, allows named anchor points.
//   two_d = If true, the attachable shape is 2D.  If false, 3D.  Default: false (3D)
//   axis = The vector pointing along the axis of a geometry.  Default: UP
//   override = Function that takes an anchor and for 3d returns a triple `[position, direction, spin]` or for 2d returns a pair `[position,direction]` to use for that anchor to override the normal one.  You can also supply a lookup table that is a list of `[anchor, [position, direction, spin]]` entries.  If the direction/position/spin that is returned is undef then the default will be used.  This option applies only to the "trapezoid" and "prismoid" geometry types.  
//   geom = If given, uses the pre-defined (via {{attach_geom()}} geometry.
//   expose_tags = If true then delay the decision to display or not display this object to the children, which it possible for tags to respond to operations like {{diff()}} used outside the attachble object.  Only works correctly if everything in the attachable is also attachable.  Default: false
//   keep_color = If true then delay application of color to the children, which means that externally applied color is overridden by color specified within the attachable.  Only works properly if everything in the attachable is also attacahble.  Default: false
//
// Side Effects:
//   `$parent_anchor` is set to the parent object's `anchor` value.
//   `$parent_spin` is set to the parent object's `spin` value.
//   `$parent_orient` is set to the parent object's `orient` value.
//   `$parent_geom` is set to the parent object's `geom` value.
//   `$parent_size` is set to the parent object's cubical `[X,Y,Z]` volume size.
//   `$color` is used to set the color of the object
//   `$save_color` is used to revert color to the parent's color
//
// Example(NORENDER): Cubical Shape
//   attachable(anchor, spin, orient, size=size) {
//       cube(size, center=true);
//       children();
//   }
//
// Example(NORENDER): Prismoidal Shape
//   attachable(
//       anchor, spin, orient,
//       size=point3d(botsize,h),
//       size2=topsize,
//       shift=shift
//   ) {
//       prismoid(botsize, topsize, h=h, shift=shift);
//       children();
//   }
//
// Example(NORENDER): Cylindrical Shape, Z-Axis Aligned
//   attachable(anchor, spin, orient, r=r, l=h) {
//       cyl(r=r, l=h);
//       children();
//   }
//
// Example(NORENDER): Cylindrical Shape, Y-Axis Aligned
//   attachable(anchor, spin, orient, r=r, l=h, axis=BACK) {
//       cyl(r=r, l=h);
//       children();
//   }
//
// Example(NORENDER): Cylindrical Shape, X-Axis Aligned
//   attachable(anchor, spin, orient, r=r, l=h, axis=RIGHT) {
//       cyl(r=r, l=h);
//       children();
//   }
//
// Example(NORENDER): Conical Shape, Z-Axis Aligned
//   attachable(anchor, spin, orient, r1=r1, r2=r2, l=h) {
//       cyl(r1=r1, r2=r2, l=h);
//       children();
//   }
//
// Example(NORENDER): Conical Shape, Y-Axis Aligned
//   attachable(anchor, spin, orient, r1=r1, r2=r2, l=h, axis=BACK) {
//       cyl(r1=r1, r2=r2, l=h);
//       children();
//   }
//
// Example(NORENDER): Conical Shape, X-Axis Aligned
//   attachable(anchor, spin, orient, r1=r1, r2=r2, l=h, axis=RIGHT) {
//       cyl(r1=r1, r2=r2, l=h);
//       children();
//   }
//
// Example(NORENDER): Spherical Shape
//   attachable(anchor, spin, orient, r=r) {
//       sphere(r=r);
//       children();
//   }
//
// Example(NORENDER): Extruded Polygon Shape, by Extents
//   attachable(anchor, spin, orient, path=path, l=length) {
//       linear_extrude(height=length, center=true)
//           polygon(path);
//       children();
//   }
//
// Example(NORENDER): Extruded Polygon Shape, by Intersection
//   attachable(anchor, spin, orient, path=path, l=length, extent=false) {
//       linear_extrude(height=length, center=true)
//           polygon(path);
//       children();
//   }
//
// Example(NORENDER): Arbitrary VNF Shape, by Extents
//   attachable(anchor, spin, orient, vnf=vnf) {
//       vnf_polyhedron(vnf);
//       children();
//   }
//
// Example(NORENDER): Arbitrary VNF Shape, by Intersection
//   attachable(anchor, spin, orient, vnf=vnf, extent=false) {
//       vnf_polyhedron(vnf);
//       children();
//   }
//
// Example(NORENDER): 2D Rectangular Shape
//   attachable(anchor, spin, orient, two_d=true, size=size) {
//       square(size, center=true);
//       children();
//   }
//
// Example(NORENDER): 2D Trapezoidal Shape
//   attachable(
//       anchor, spin, orient,
//       two_d=true,
//       size=[x1,y],
//       size2=x2,
//       shift=shift
//   ) {
//       trapezoid(w1=x1, w2=x2, h=y, shift=shift);
//       children();
//   }
//
// Example(NORENDER): 2D Circular Shape
//   attachable(anchor, spin, orient, two_d=true, r=r) {
//       circle(r=r);
//       children();
//   }
//
// Example(NORENDER): Arbitrary 2D Polygon Shape, by Extents
//   attachable(anchor, spin, orient, two_d=true, path=path) {
//       polygon(path);
//       children();
//   }
//
// Example(NORENDER): Arbitrary 2D Polygon Shape, by Intersection
//   attachable(anchor, spin, orient, two_d=true, path=path, extent=false) {
//       polygon(path);
//       children();
//   }
//
// Example(NORENDER): Using Pre-defined Geometry
//   geom = atype=="perim"? attach_geom(two_d=true, path=path, extent=false) :
//       atype=="extents"? attach_geom(two_d=true, path=path, extent=true) :
//       atype=="circle"? attach_geom(two_d=true, r=r) :
//       assert(false, "Bad atype");
//   attachable(anchor, spin, orient, geom=geom) {
//       polygon(path);
//       children();
//   }
//
// Example: An object can be designed to attach as negative space using {{diff()}}, but if you want an object to include both positive and negative space then you run into trouble because tags inside the `attachable()` are ignored.  One solution is to call attachable() twice.  This example shows how two calls to  attachable can create an object with positive and negative space.  Note, however, that children in the negative space are differenced away: the highlighted little cube does not survive into the final model.
//   module thing(anchor,spin,orient) {
//      tag("remove") attachable(size=[15,15,15],anchor=anchor,spin=spin,orient=orient){
//        cuboid([10,10,16]);
//        union(){}   // dummy children
//      }
//      attachable(size=[15,15,15], anchor=anchor, spin=spin, orient=orient){
//        cuboid([15,15,15]);
//        children();
//      }
//   }
//   diff()
//     cube([19,10,19])
//       attach([FRONT],overlap=-4)
//         thing(anchor=TOP)
//           # attach(TOP) cuboid(2,anchor=TOP);
// Example: Here is an example where the "keep" tag allows children to appear in the negative space.  That tag is also needed for this module to produce the desired output.  As above, the tag must be applied outside the attachable() call.
//   module thing(anchor = CENTER, spin = 0, orient = UP) {
//      tag("remove") attachable(anchor, spin, orient, d1=0,d2=95,h=33) {
//          cylinder(h = 33.1, d1 = 0, d2 = 95, anchor=CENTER);
//          union(){}  // dummy children
//      }
//      tag("keep") attachable(anchor, spin, orient,d1=0,d2=95,h=33) {
//            cylinder(h = 33, d = 10,anchor=CENTER);
//            children();
//        }
//    }
//    diff()
//      cube(100)
//        attach([FRONT,TOP],overlap=-4)
//          thing(anchor=TOP)
//            tube(ir=12,h=10);
// Example: A different way to achieve similar effects to the above to examples is to use the `expose_tags` parameter.  This parameter allows you to use just one call to attachable.  The second example above can also be rewritten like this. 
//   module thing(anchor,spin,orient) {
//      attachable(size=[15,15,15],anchor=anchor,spin=spin,orient=orient,expose_tags=true){
//        union(){
//          cuboid([15,15,15]);
//          tag("remove")cuboid([10,10,16]);
//        }
//        children();
//      }
//   }
//   diff()
//     cube([19,10,19])
//       attach([FRONT],overlap=-4)
//         thing(anchor=TOP);
// Example: An advantage of using `expose_tags` is that it can work on nested constructions.  Here the child cylinder is aligned relative to its parent and removed from the calling parent object.
//   $fn=64;
//   module thing(anchor=BOT){
//     attachable(anchor = anchor,d=9,h=6,expose_tags=true){
//       cyl(d = 9, h = 6) 
//         tag("remove") 
//            align(RIGHT+TOP,inside=true) 
//                 left(1)up(1)cyl(l=11, d=3);
//       children();
//     }
//   }
//   back_half()
//     diff()
//       cuboid(10)
//         position(TOP)thing(anchor=BOT);
// Example(3D,NoAxes): Here an attachable module uses {{recolor()}} to change the color of a sub-part, producing the result shown on the left.  But if the caller applies color to the attachable, then both the green and yellow are changed, as shown on the right.  
//   module thing(anchor=CENTER) {
//       attachable(anchor,size=[10,10,10]) {
//           cuboid(10)
//             position(TOP) recolor("green")
//               cuboid(5,anchor=BOT);
//           children();
//       }
//   }
//   move([-15,-15])
//   thing()
//     attach(RIGHT,BOT)
//       recolor("blue") cyl(d=5,h=5);
//   recolor("pink") thing()
//     attach(RIGHT,BOT)
//       recolor("blue") cyl(d=5,h=5);
// Example(3D,NoAxes): Using the `keep_color=true` option enables the green color to persist, even when the user specifies a color.
//   module thing(anchor=CENTER) {
//       attachable(anchor,size=[10,10,10],keep_color=true) {
//           cuboid(10)
//             position(TOP) recolor("green")
//               cuboid(5,anchor=BOT);
//           children();
//       }
//   }
//   recolor("pink") thing()
//     attach(RIGHT,BOT)
//       recolor("blue") cyl(d=5,h=5);
// Example(3D,NoScale): This example defines named anchors and then uses them internally in the object definition to make a cutout in the socket() object and to attach the plug on the plug() object.  These objects can be connected using the "socket" and "plug" named anchors, which will fit the plug into the socket.
//   module socket(anchor, spin, orient) {
//       sz = 50;
//       prong_size = 10;
//       anchors = [
//           named_anchor("socket", [sz/2,.15*sz,.2*sz], RIGHT, 0)
//       ];
//       attachable(anchor, spin, orient, size=[sz,sz,sz], anchors=anchors) {
//           diff() {
//               cuboid(sz);
//               tag("remove") attach("socket") zcyl(d=prong_size, h=prong_size*2, $fn=6);
//           }
//           children();
//       }
//   }
//   module plug(anchor, spin, orient) {
//       sz = 30;
//       prong_size = 9.5;
//       anchors=[
//           named_anchor("plug", [0,sz/3,sz/2], UP, 0)
//       ];
//       attachable(anchor, spin, orient, size=[sz,sz,sz], anchors=anchors) {
//          union(){
//            cuboid(sz);
//            attach("plug") cyl(d=prong_size, h=prong_size*2,$fn=6);
//          }
//          children();
//       }
//   }
//   socket();
//   right(75) plug();



module attachable(
    anchor, spin, orient,
    size, size2, shift,
    r,r1,r2, d,d1,d2, l,h,
    vnf, path, region,
    extent=true,
    cp=[0,0,0],
    offset=[0,0,0],
    anchors=[],
    two_d=false,
    axis=UP,override,
    geom,
    parts=[],
    expose_tags=false, keep_color=false
) {
    dummy1 =
        assert($children==2, "attachable() expects exactly two children; the shape to manage, and the union of all attachment candidates.")
        assert(is_undef(anchor) || is_vector(anchor) || is_string(anchor), str("Invalid anchor: ",anchor))
        assert(is_undef(spin) || is_finite(spin), str("Invalid spin: ",spin))
        assert(is_undef(orient) || is_vector(orient,3), str("Invalid orient: ",orient));
        assert(in_list(v_abs(axis),[UP,RIGHT,BACK]), "axis must be a coordinate direction");
    anchor = default(anchor,CENTER);
    spin = default(spin,0); 
    orient = is_def($anchor_override)? UP : default(orient, UP);
    region = !is_undef(region)? region :
        !is_undef(path)? [path] :
        undef;
    geom = is_def(geom)? geom :
        attach_geom(
            size=size, size2=size2, shift=shift,
            r=r, r1=r1, r2=r2, h=h,
            d=d, d1=d1, d2=d2, l=l,
            vnf=vnf, region=region, extent=extent,
            cp=cp, offset=offset, anchors=anchors,
            two_d=two_d, axis=axis, override=override
        );
    m = _attach_transform(anchor,spin,orient,geom);
    multmatrix(m) {
        $parent_anchor = anchor;
        $parent_spin   = spin;
        $parent_orient = orient;
        $parent_geom   = geom;
        $parent_size   = _attach_geom_size(geom);
        $attach_to   = undef;
        $anchor_override=undef;
        $attach_alignment=undef;
        $parent_parts = parts;
        $anchor_inside = false;
        if (expose_tags || _is_shown()){
            if (!keep_color)
                _color($color)
                  _show_ghost() children(0);
            else {
                $save_color=undef; // Force color_this() color in effect to persist for the entire object
                _show_ghost() children(0);
            }
        }
        let(
            $ghost_this=false,
            $highlight_this=false,
            $tag=default($save_tag,$tag),
            $save_tag=undef,
            $color=default($save_color,$color),
            $save_color=undef
        )
        children(1);
   }
}

module _show_highlight()
{
  if ($highlight || $highlight_this)
    #children();
  else
    children();
}  


module _show_ghost()
{  
    if (($ghost || $ghost_this) && !$ghosting)
        %union(){
           $ghosting=true;
           _show_highlight()children();
        }
    else _show_highlight()children();
}



function _is_geometry(entry) = is_list(entry) && is_string(entry[0]);


// Function: reorient()
// Synopsis: Calculates the transformation matrix needed to reorient an object.
// SynTags: Trans, Path, VNF
// Topics: Attachments
// See Also: reorient(), attachable()
// Usage: Square/Trapezoid Geometry
//   mat = reorient(anchor, spin, [orient], two_d=true, size=, [size2=], [shift=], ...);
//   pts = reorient(anchor, spin, [orient], two_d=true, size=, [size2=], [shift=], p=, ...);
// Usage: Circle/Oval Geometry
//   mat = reorient(anchor, spin, [orient], two_d=true, r=|d=, ...);
//   pts = reorient(anchor, spin, [orient], two_d=true, r=|d=, p=, ...);
// Usage: 2D Path/Polygon Geometry
//   mat = reorient(anchor, spin, [orient], two_d=true, path=, [extent=], ...);
//   pts = reorient(anchor, spin, [orient], two_d=true, path=, [extent=], p=, ...);
// Usage: 2D Region/Polygon Geometry
//   mat = reorient(anchor, spin, [orient], two_d=true, region=, [extent=], ...);
//   pts = reorient(anchor, spin, [orient], two_d=true, region=, [extent=], p=, ...);
// Usage: Cubical/Prismoidal Geometry
//   mat = reorient(anchor, spin, [orient], size=, [size2=], [shift=], ...);
//   vnf = reorient(anchor, spin, [orient], size=, [size2=], [shift=], p=, ...);
// Usage: Cylindrical Geometry
//   mat = reorient(anchor, spin, [orient], r=|d=, l=, [axis=], ...);
//   vnf = reorient(anchor, spin, [orient], r=|d=, l=, [axis=], p=, ...);
// Usage: Conical Geometry
//   mat = reorient(anchor, spin, [orient], r1=|d1=, r2=|d2=, l=, [axis=], ...);
//   vnf = reorient(anchor, spin, [orient], r1=|d1=, r2=|d2=, l=, [axis=], p=, ...);
// Usage: Spheroid/Ovoid Geometry
//   mat = reorient(anchor, spin, [orient], r|d=, ...);
//   vnf = reorient(anchor, spin, [orient], r|d=, p=, ...);
// Usage: Extruded Path/Polygon Geometry
//   mat = reorient(anchor, spin, [orient], path=, l=|h=, [extent=], ...);
//   vnf = reorient(anchor, spin, [orient], path=, l=|h=, [extent=], p=, ...);
// Usage: Extruded Region Geometry
//   mat = reorient(anchor, spin, [orient], region=, l=|h=, [extent=], ...);
//   vnf = reorient(anchor, spin, [orient], region=, l=|h=, [extent=], p=, ...);
// Usage: VNF Geometry
//   mat = reorient(anchor, spin, [orient], vnf, [extent], ...);
//   vnf = reorient(anchor, spin, [orient], vnf, [extent], p=, ...);
//
// Description:
//   Given anchor, spin, orient, and general geometry info for a managed volume, this calculates
//   the transformation matrix needed to be applied to the contents of that volume.  A managed 3D
//   volume is assumed to be vertically (Z-axis) oriented, and centered.  A managed 2D area is just
//   assumed to be centered.
//   .
//   If `p` is not given, then the transformation matrix will be returned.
//   If `p` contains a VNF, a new VNF will be returned with the vertices transformed by the matrix.
//   If `p` contains a path, a new path will be returned with the vertices transformed by the matrix.
//   If `p` contains a point, a new point will be returned, transformed by the matrix.
//   .
//   If `$attach_to` is not defined, then the following transformations are performed in order:
//   * Translates so the `anchor` point is at the origin (0,0,0).
//   * Rotates around the Z axis by `spin` degrees counter-clockwise.
//   * Rotates so the top of the part points towards the vector `orient`.
//   .
//   If `$attach_to` is defined, as a consequence of `attach(from,to)`, then
//   the following transformations are performed in order:
//   * Translates this part so its anchor position matches the parent's anchor position.
//   * Rotates this part so its anchor direction vector exactly opposes the parent's anchor direction vector.
//   * Rotates this part so its anchor spin matches the parent's anchor spin.
//   .
//   For a step-by-step explanation of attachments, see the [Attachments Tutorial](Tutorial-Attachment-Basic-Positioning).
//
// Arguments:
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   ---
//   size = If given as a 3D vector, contains the XY size of the bottom of the cuboidal/prismoidal volume, and the Z height.  If given as a 2D vector, contains the front X width of the rectangular/trapezoidal shape, and the Y length.
//   size2 = If given as a 2D vector, contains the XY size of the top of the prismoidal volume.  If given as a number, contains the back width of the trapezoidal shape.
//   shift = If given as a 2D vector, shifts the top of the prismoidal or conical shape by the given amount.  If given as a number, shifts the back of the trapezoidal shape right by that amount.  Default: No shift.
//   r = Radius of the cylindrical/conical volume.  Can be a scalar, or a list of sizes per axis.
//   d = Diameter of the cylindrical/conical volume.  Can be a scalar, or a list of sizes per axis.
//   r1 = Radius of the bottom of the conical volume.  Can be a scalar, or a list of sizes per axis.
//   r2 = Radius of the top of the conical volume.  Can be a scalar, or a list of sizes per axis.
//   d1 = Diameter of the bottom of the conical volume.  Can be a scalar, a list of sizes per axis.
//   d2 = Diameter of the top of the conical volume.  Can be a scalar, a list of sizes per axis.
//   l/h = Length of the cylindrical, conical, or extruded path volume along axis.
//   vnf = The [VNF](vnf.scad) of the volume.
//   path = The path to generate a polygon from.
//   region = The region to generate a shape from.
//   extent = If true, calculate anchors by extents, rather than intersection.  Default: false.
//   cp = If given, specifies the centerpoint of the volume.  Default: `[0,0,0]`
//   offset = If given, offsets the perimeter of the volume around the centerpoint.
//   anchors = If given as a list of anchor points, allows named anchor points.
//   two_d = If true, the attachable shape is 2D.  If false, 3D.  Default: false (3D)
//   axis = The vector pointing along the axis of a geometry.  Default: UP
//   p = The VNF, path, or point to transform.
function reorient(
    anchor, spin, orient,
    size, size2, shift,
    r,r1,r2, d,d1,d2, l,h,
    vnf, path, region,
    extent=true,
    offset=[0,0,0],
    cp=[0,0,0],
    anchors=[],
    two_d=false,
    axis=UP, override, 
    geom,
    p=undef
) = 
    assert(is_undef(anchor) || is_vector(anchor) || is_string(anchor), str("Invalid anchor: ",anchor))
    assert(is_undef(spin) || is_finite(spin), str("Invalid spin: ",spin))
    assert(is_undef(orient) || is_vector(orient,3), str("Invalid orient: ",orient))
    let(
        anchor = default(anchor, CENTER),
        spin =   default(spin,   0),
        orient = default(orient, UP),
        region = !is_undef(region)? region :
            !is_undef(path)? [path] :
            undef,
        geom = is_def(geom)? geom :
            attach_geom(
                size=size, size2=size2, shift=shift,
                r=r, r1=r1, r2=r2, h=h,
                d=d, d1=d1, d2=d2, l=l,
                vnf=vnf, region=region, extent=extent,
                cp=cp, offset=offset, anchors=anchors,
                two_d=two_d, axis=axis, override=override
            ),
        $attach_to = undef,
        $anchor_override= undef,
        $attach_alignment = undef
    ) _attach_transform(anchor,spin,orient,geom,p);


// Function: named_anchor()
// Synopsis: Creates an anchor data structure.
// Topics: Attachments
// See Also: reorient(), attachable()
// Usage:
//   a = named_anchor(name, pos, [orient], [spin]);
//   a = named_anchor(name, [pos], rot=, [flip=]);
// Description:
//   Creates an anchor data structure.  You can specify the position, orient direction and spin directly.
//   Alternatively for the 3D case you can give a 4x4 rotation matrix which can specify the orient and spin, and optionally
//   the position, using a translation component of the matrix.  If you specify `pos` along with `rot` then the position you
//   give overrides any translation included in `rot`.  For a step-by-step explanation of attachments, 
//   see the [Attachments Tutorial](Tutorial-Attachment-Basic-Positioning).
// Arguments:
//   name = The string name of the anchor.  Lowercase.  Words separated by single dashes.  No spaces.
//   pos = The [X,Y,Z] position of the anchor.
//   orient = A vector pointing in the direction parts should project from the anchor position.  Default: UP
//   spin = If needed, the angle to rotate the part around the direction vector.  Default: 0
//   ---
//   info = structure listing info to be propagated to the attached child, e.g. "edge_anchor"
//   rot = A 4x4 rotations matrix, which may include a translation
//   flip = If true, flip the anchor the opposite direction.  Default: false
function named_anchor(name, pos, orient, spin, rot, flip, info) =
  assert(num_defined([orient,spin])==0 || num_defined([rot,flip])==0, "Cannot mix orient or spin with rot or flip")
  assert(num_defined([pos,rot])>0, "Must give pos or rot")
  is_undef(rot) ? [name, pos, default(orient,UP), default(spin,0), if (info) info]
 : 
  let(
      flip = default(flip,false),
      pos = default(pos,apply(rot,CTR)),
      rotpart = _force_rot(rot),
      dummy = assert(approx(det4(rotpart),1), "Input rotation is not a rotation matrix"),
      dir = flip ? apply(rotpart,DOWN)
                 : apply(rotpart,UP),
      rot = flip? affine3d_rot_by_axis(apply(rotpart,BACK),180)*rot
                      : rot,
      decode=rot_decode(rot(to=UP,from=dir)*_force_rot(rot)),
      spin = decode[0]*sign(decode[1].z)
  )
  [name, pos, dir, spin, if (info) info];
  

// Function: attach_geom()
// Synopsis: Returns the internal geometry description of an attachable object.
// Topics: Attachments
// See Also: reorient(), attachable()
// Usage: Null/Point Geometry
//   geom = attach_geom(...);
// Usage: Square/Trapezoid Geometry
//   geom = attach_geom(two_d=true, size=, [size2=], [shift=], ...);
// Usage: Circle/Oval Geometry
//   geom = attach_geom(two_d=true, r=|d=, ...);
// Usage: 2D Path/Polygon/Region Geometry
//   geom = attach_geom(two_d=true, region=, [extent=], ...);
// Usage: Cubical/Prismoidal Geometry
//   geom = attach_geom(size=, [size2=], [shift=], ...);
// Usage: Cylindrical Geometry
//   geom = attach_geom(r=|d=, l=|h=, [axis=], ...);
// Usage: Conical Geometry
//   geom = attach_geom(r1|d1=, r2=|d2=, l=, [axis=], ...);
// Usage: Spheroid/Ovoid Geometry
//   geom = attach_geom(r=|d=, ...);
// Usage: Extruded 2D Path/Polygon/Region Geometry
//   geom = attach_geom(region=, l=|h=, [extent=], [shift=], [scale=], [twist=], ...);
// Usage: VNF Geometry
//   geom = attach_geom(vnf=, [extent=], ...);
//
// Description:
//   Given arguments that describe the geometry of an attachable object, returns the internal geometry description.
//   This will probably not not ever need to be called by the end user.
//
// Arguments:
//   ---
//   size = If given as a 3D vector, contains the XY size of the bottom of the cuboidal/prismoidal volume, and the Z height.  If given as a 2D vector, contains the front X width of the rectangular/trapezoidal shape, and the Y length.
//   size2 = If given as a 2D vector, contains the XY size of the top of the prismoidal volume.  If given as a number, contains the back width of the trapezoidal shape.
//   shift = If given as a 2D vector, shifts the top of the prismoidal or conical shape by the given amount.  If given as a number, shifts the back of the trapezoidal shape right by that amount.  Default: No shift.
//   scale = If given as number or a 2D vector, scales the top of the shape, relative to the bottom.  Default: `[1,1]`
//   twist = If given as number, rotates the top of the shape by the given number of degrees clockwise, relative to the bottom.  Default: `0`
//   r = Radius of the cylindrical/conical volume.  Can be a scalar, or a list of sizes per axis.
//   d = Diameter of the cylindrical/conical volume.  Can be a scalar, or a list of sizes per axis.
//   r1 = Radius of the bottom of the conical volume.  Can be a scalar, or a list of sizes per axis.
//   r2 = Radius of the top of the conical volume.  Can be a scalar, or a list of sizes per axis.
//   d1 = Diameter of the bottom of the conical volume.  Can be a scalar, a list of sizes per axis.
//   d2 = Diameter of the top of the conical volume.  Can be a scalar, a list of sizes per axis.
//   l/h = Length of the cylindrical, conical or extruded region volume along axis.
//   vnf = The [VNF](vnf.scad) of the volume.
//   region = The region to generate a shape from.
//   extent = If true, calculate anchors by extents, rather than intersection.  Default: true.
//   cp = If given, specifies the centerpoint of the volume.  Default: `[0,0,0]`
//   offset = If given, offsets the perimeter of the volume around the centerpoint.
//   anchors = If given as a list of anchor points, allows named anchor points.
//   two_d = If true, the attachable shape is 2D.  If false, 3D.  Default: false (3D)
//   axis = The vector pointing along the axis of a geometry.  Default: UP
//   override = Function that takes an anchor and returns a pair `[position,direction,spin]` to use for that anchor to override the normal one.  You can also supply a lookup table that is a list of `[anchor, [position, direction,spin]]` entries.  If the direction/position/spin that is returned is undef then the default will be used.
//
// Example(NORENDER): Null/Point Shape
//   geom = attach_geom();
//
// Example(NORENDER): Cubical Shape
//   geom = attach_geom(size=size);
//
// Example(NORENDER): Prismoidal Shape
//   geom = attach_geom(
//       size=point3d(botsize,h),
//       size2=topsize, shift=shift
//   );
//
// Example(NORENDER): Cylindrical Shape, Z-Axis Aligned
//   geom = attach_geom(r=r, h=h);
//
// Example(NORENDER): Cylindrical Shape, Y-Axis Aligned
//   geom = attach_geom(r=r, h=h, axis=BACK);
//
// Example(NORENDER): Cylindrical Shape, X-Axis Aligned
//   geom = attach_geom(r=r, h=h, axis=RIGHT);
//
// Example(NORENDER): Conical Shape, Z-Axis Aligned
//   geom = attach_geom(r1=r1, r2=r2, h=h);
//
// Example(NORENDER): Conical Shape, Y-Axis Aligned
//   geom = attach_geom(r1=r1, r2=r2, h=h, axis=BACK);
//
// Example(NORENDER): Conical Shape, X-Axis Aligned
//   geom = attach_geom(r1=r1, r2=r2, h=h, axis=RIGHT);
//
// Example(NORENDER): Spherical Shape
//   geom = attach_geom(r=r);
//
// Example(NORENDER): Ovoid Shape
//   geom = attach_geom(r=[r_x, r_y, r_z]);
//
// Example(NORENDER): Arbitrary VNF Shape, Anchored by Extents
//   geom = attach_geom(vnf=vnf);
//
// Example(NORENDER): Arbitrary VNF Shape, Anchored by Intersection
//   geom = attach_geom(vnf=vnf, extent=false);
//
// Example(NORENDER): 2D Rectangular Shape
//   geom = attach_geom(two_d=true, size=size);
//
// Example(NORENDER): 2D Trapezoidal Shape
//   geom = attach_geom(two_d=true, size=[x1,y], size2=x2, shift=shift, override=override);
//
// Example(NORENDER): 2D Circular Shape
//   geom = attach_geom(two_d=true, r=r);
//
// Example(NORENDER): 2D Oval Shape
//   geom = attach_geom(two_d=true, r=[r_x, r_y]);
//
// Example(NORENDER): Arbitrary 2D Region Shape, Anchored by Extents
//   geom = attach_geom(two_d=true, region=region);
//
// Example(NORENDER): Arbitrary 2D Region Shape, Anchored by Intersection
//   geom = attach_geom(two_d=true, region=region, extent=false);
//
// Example(NORENDER): Extruded Region, Anchored by Extents
//   geom = attach_geom(region=region, l=height);
//
// Example(NORENDER): Extruded Region, Anchored by Intersection
//   geom = attach_geom(region=region, l=length, extent=false);
//


function attach_geom(
    size, size2,
    shift, scale, twist,
    r,r1,r2, d,d1,d2, l,h,
    vnf, region,
    extent=true,
    cp=[0,0,0],
    offset=[0,0,0],
    anchors=[],
    two_d=false,
    axis=UP, override
) =
    assert(is_bool(extent))
    assert(is_vector(cp) || is_string(cp))
    assert(is_vector(offset))
    assert(is_list(anchors))
    assert(is_bool(two_d))
    assert(is_vector(axis))
    let(
        over_f = is_undef(override) ? function(anchor) [undef,undef,undef]
               : is_func(override) ? override
               : function(anchor) _local_struct_val(override,anchor)
    )
    !is_undef(size)? (
        two_d? (
            let(
                size2 = default(size2, size.x),
                shift = default(shift, 0)
            )
            assert(is_vector(size,2))
            assert(is_num(size2))
            assert(is_num(shift))
            ["trapezoid", point2d(size), size2, shift, over_f, cp, offset, anchors]
        ) : (
            let(
                size2 = default(size2, point2d(size)),
                shift = default(shift, [0,0])
            )
            assert(is_vector(size,3))
            assert(is_vector(size2,2))
            assert(is_vector(shift,2))
            ["prismoid", size, size2, shift, axis, over_f, cp, offset, anchors]
        )
    ) : !is_undef(vnf)? (
        assert(is_vnf(vnf))
        assert(two_d == false)
        extent? ["vnf_extent", vnf, over_f, cp, offset, anchors] 
              : ["vnf_isect", vnf, over_f, cp, offset, anchors]
    ) : !is_undef(region)? (
        assert(is_region(region),2)
        let( l = default(l, h) )
        two_d==true
          ? assert(is_undef(l), "Cannot give l/h with region anchor types (when two_d is set)")
            extent==true
              ? ["rgn_extent", region, cp, offset, anchors]
              : ["rgn_isect",  region, cp, offset, anchors]
          : assert(is_finite(l), "Must give l/h with extrusion anchor types (did you forget to set two_d?)")
            let(
                shift = default(shift, [0,0]),
                scale = is_num(scale)? [scale,scale] : default(scale, [1,1]),
                twist = default(twist, 0)
            )
            assert(is_vector(shift,2))
            assert(is_vector(scale,2))
            assert(is_num(twist))
            extent==true
              ? ["extrusion_extent", region, l, twist, scale, shift, cp, offset, anchors]
              : ["extrusion_isect",  region, l, twist, scale, shift, cp, offset, anchors]
    ) :
    let(
        r1 = get_radius(r1=r1,d1=d1,r=r,d=d,dflt=undef)
    )
    !is_undef(r1)? (
        let( l = default(l, h) )
        !is_undef(l)? (
            let(
                shift = default(shift, [0,0]),
                r2 = get_radius(r1=r2,d1=d2,r=r,d=d,dflt=undef)
            )
            assert(is_num(r1) || is_vector(r1,2))
            assert(is_num(r2) || is_vector(r2,2))
            assert(is_num(l))
            assert(is_vector(shift,2))
            ["conoid", r1, r2, l, shift, axis, cp, offset, anchors]
        ) : (
            two_d? (
                assert(is_num(r1) || is_vector(r1,2))
                ["ellipse", r1, cp, offset, anchors]
            ) : (
                assert(is_num(r1) || is_vector(r1,3))
                ["spheroid", r1, cp, offset, anchors]
            )
        )
    ) :
    two_d?     ["point2d", cp, offset, anchors]
    : ["point", cp, offset, anchors];


// Function: define_part()
// Synopsis: Creates an attachable part data structure.
// Topics: Attachments
// See Also: attachable()
// Usage:
//   part = define_part(name, geom, [inside=], [T=]);
// Description:
//   Create a named attachable part that can be passed in the `parts` parameter of {{attachable()}}
//   and then selected using {{attach_part()}}.
// Arguments:
//   name = name of part
//   geom = geometry of part produced by {{attach_geom()}}
//   ---
//   inside = if true, reverse the attachment direction for children.  Default: false
//   T = Transformation to apply to children.  Default: IDENT
// Example(3D): This example shows how to create a custom object with two different parts that are both transformed away from the origin.  The basic object is two cylinders with a cube shaped attachment geometry that doesn't match the object very well.  The "left" and "right" parts attach to each of the two cylinders.  
//   module twocyl(d, sep, h, ang=20) 
//   {
//      parts = [
//                define_part("left", attach_geom(r=d/2,h=h), T=left(sep/2)*yrot(-ang)),
//                define_part("right", attach_geom(r=d/2,h=h), T=right(sep/2)*yrot(ang)),
//              ];
//      attachable(size=[sep+d,d,h], parts=parts){
//        union(){
//            left(sep/2) yrot(-ang) cyl(d=d,h=h);
//            right(sep/2) yrot(ang) cyl(d=d,h=h);
//        }
//        children();
//      }  
//   }
//   twocyl(d=10,sep=30,h=10){
//     attach(TOP,TOP) cuboid(3);
//     color("pink")attach_part("left")attach(TOP,BOT) cuboid(3);
//     color("green")attach_part("right")attach(TOP,BOT) cuboid(3);    
//   }

function define_part(name, geom, inside=false, T=IDENT) =
  assert(is_string(name), "name must be a string")
  assert(_is_geometry(geom), "geometry appears invalid")
  assert(is_bool(inside), "inside must be boolean")
  assert(is_matrix(T,4), "T must be a 4x4 transformation matrix")
  [name, geom, inside, T];





//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Attachment internal functions


/// Internal Function: _attach_geom_2d()
/// Topics: Attachments
/// See Also: reorient(), attachable()
/// Usage:
///   bool = _attach_geom_2d(geom);
/// Description:
///   Returns true if the given attachment geometry description is for a 2D shape.
function _attach_geom_2d(geom) =
    let( type = geom[0] )
    type == "trapezoid" || type == "ellipse" ||
    type == "rgn_isect" || type == "rgn_extent" || type=="point2d";


/// Internal Function: _attach_geom_size()
/// Usage:
///   bounds = _attach_geom_size(geom);
/// Topics: Attachments
/// See Also: reorient(), attachable()
/// Description:
///   Returns the `[X,Y,Z]` bounding size for the given attachment geometry description.
function _attach_geom_size(geom) =
    let( type = geom[0] )
    type == "point"? [0,0,0] :
    type == "point2d"? [0,0] :
    type == "prismoid"? ( //size, size2, shift, axis
        let(
            size=geom[1], size2=geom[2], shift=point2d(geom[3]),
            maxx = max(size.x,size2.x),
            maxy = max(size.y,size2.y),
            z = size.z
        ) [maxx, maxy, z]
    ) : type == "conoid"? ( //r1, r2, l, shift
        let(
            r1=geom[1], r2=geom[2], l=geom[3],
            shift=point2d(geom[4]), axis=point3d(geom[5]),
            rx1 = default(r1[0],r1),
            ry1 = default(r1[1],r1),
            rx2 = default(r2[0],r2),
            ry2 = default(r2[1],r2),
            maxxr = max(rx1,rx2),
            maxyr = max(ry1,ry2)
        )
        approx(axis,UP)? [2*maxxr,2*maxyr,l] :
        approx(axis,RIGHT)? [l,2*maxyr,2*maxxr] :
        approx(axis,BACK)? [2*maxxr,l,2*maxyr] :
        [2*maxxr, 2*maxyr, l]
    ) : type == "spheroid"? ( //r
        let( r=geom[1] )
        is_num(r)? [2,2,2]*r : v_mul([2,2,2],point3d(r))
    ) : type == "vnf_extent" || type=="vnf_isect"? ( //vnf
        let(
            vnf = geom[1]
        ) vnf==EMPTY_VNF? [0,0,0] :
        let(
            mm = pointlist_bounds(geom[1][0]),
            delt = mm[1]-mm[0]
        ) delt
    ) : type == "extrusion_isect" || type == "extrusion_extent"? ( //path, l
        let(
            mm = pointlist_bounds(flatten(geom[1])),
            delt = mm[1]-mm[0]
        ) [delt.x, delt.y, geom[2]]
    ) : type == "trapezoid"? ( //size, size2
        let(
            size=geom[1], size2=geom[2], shift=geom[3],
            maxx = max(size.x,size2+abs(shift))
        ) [maxx, size.y]
    ) : type == "ellipse"? ( //r
        let( r=geom[1] )
        is_num(r)? [2,2]*r : v_mul([2,2],point2d(r))
    ) : type == "rgn_isect" || type == "rgn_extent"? ( //path
        let(
            mm = pointlist_bounds(flatten(geom[1])),
            delt = mm[1]-mm[0]
        ) [delt.x, delt.y]
    ) :
    assert(false, "Unknown attachment geometry type.");



/// Internal Function: _attach_geom_edge_path()
/// Usage:
///   angle = _attach_geom_edge_path(geom, edge);
/// Topics: Attachments
/// See Also: reorient(), attachable()
/// Description:
///   Returns the path and post-transform matrix of the indicated edge.
///   If the edge is invalid for the geometry, returns `undef`.
function _attach_geom_edge_path(geom, edge) =
    assert(is_vector(edge),str("Invalid edge: edge=",edge))
    let(
        type = geom[0],
        cp = _get_cp(geom),
        offset_raw = select(geom,-2),
        offset = [for (i=[0:2]) edge[i]==0? 0 : offset_raw[i]],  // prevents bad centering.
        edge = point3d(edge)
    )
    type == "prismoid"? ( //size, size2, shift, axis
        let(all_comps_good = [for (c=edge) if (c!=sign(c)) 1]==[])
        assert(all_comps_good, "All components of an edge for a cuboid/prismoid must be -1, 0, or 1")
        let(edge_good = len([for (c=edge) if(c) 1])==2)
        assert(edge_good, "Invalid edge.")
        let(
            size = geom[1],
            size2 = geom[2],
            shift = point2d(geom[3]),
            axis = point3d(geom[4]),
            edge = rot(from=axis, to=UP, p=edge),
            offset = rot(from=axis, to=UP, p=offset),
            h = size.z,
            cpos = function(vec) let(
                        u = (vec.z + 1) / 2,
                        siz = lerp(point2d(size), size2, u) / 2,
                        z = vec.z * h / 2,
                        pos = point3d(v_mul(siz, point2d(vec)) + shift * u, z)
                    ) pos,
            ep1 = cpos([for (c=edge) c? c : -1]),
            ep2 = cpos([for (c=edge) c? c :  1]),
            cp = (ep1 + ep2) / 2,
            axy = point2d(edge),
            bot = point3d(v_mul(point2d(size )/2, axy), -h/2),
            top = point3d(v_mul(point2d(size2)/2, axy) + shift, h/2),
            xang = atan2(h,(top-bot).x),
            yang = atan2(h,(top-bot).y),
            vecs = [
                if (edge.x) yrot(90-xang, p=sign(axy.x)*RIGHT),
                if (edge.y) xrot(yang-90, p=sign(axy.y)*BACK),
                if (edge.z) [0,0,sign(edge.z)]
            ], 
            segvec = cross(unit(vecs[1]), unit(vecs[0])),
            seglen = norm(ep2 - ep1),
            path = [
                cp - segvec * seglen/2,
                cp + segvec * seglen/2
            ],
            m = rot(from=UP,to=axis) * move(offset)
        ) [path, [vecs], m]
    ) : type == "conoid"? ( //r1, r2, l, shift, axis
        assert(edge.z && edge.z == sign(edge.z), "The Z component of an edge for a cylinder/cone must be -1 or 1")
        let(
            rr1 = geom[1],
            rr2 = geom[2],
            l = geom[3],
            shift = point2d(geom[4]),
            axis = point3d(geom[5]),
            r1 = is_num(rr1)? [rr1,rr1] : point2d(rr1),
            r2 = is_num(rr2)? [rr2,rr2] : point2d(rr2),
            edge = rot(from=axis, to=UP, p=edge),
            offset = rot(from=axis, to=UP, p=offset),
            maxr = max([each r1, each r2]),
            sides = segs(maxr),
            top = path3d(move(shift, p=ellipse(r=r2, $fn=sides)), l/2),
            bot = path3d(ellipse(r=r1, $fn=sides), -l/2),
            path = edge.z < 0 ? bot : top,
            path2 = edge.z < 0 ? top : bot,
            zed = edge.z<0? [0,0,-l/2] : point3d(shift,l/2),
            vecs = [
                for (i = idx(top)) let(
                    pt1 = (path[i] + select(path,i+1)) /2,
                    pt2 = (path2[i] + select(path2,i+1)) /2,
                    v1 = unit(zed - pt1),
                    v2 = unit(pt2 - pt1),
                    v3 = unit(cross(v1,v2)),
                    v4 = cross(v3,v2),
                    v5 = cross(v1,v3)
                ) [v4, v5]
            ],
            m = rot(from=UP,to=axis) * move(offset)
        ) edge.z>0
          ? [reverse(list_wrap(path)), reverse(vecs), m]
          : [list_wrap(path), vecs, m]
    ) : undef;


/// Internal Function: _attach_transform()
/// Usage: To Get a Transformation Matrix
///   mat = _attach_transform(anchor, spin, orient, geom);
/// Usage: To Transform Points, Paths, Patches, or VNFs
///   new_p = _attach_transform(anchor, spin, orient, geom, p);
/// Topics: Attachments
/// See Also: reorient(), attachable()
/// Description:
///   Returns the affine3d transformation matrix needed to `anchor`, `spin`, and `orient`
///   the given geometry `geom` shape into position.
/// Arguments:
///   anchor = Anchor point to translate to the origin `[0,0,0]`.  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
///   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
///   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
///   geom = The geometry description of the shape.
///   p = If given as a VNF, path, or point, applies the affine3d transformation matrix to it and returns the result.

function _attach_transform(anchor, spin, orient, geom, p) =
    assert(is_undef(anchor) || is_vector(anchor) || is_string(anchor), str("Invalid anchor: ",anchor))
    assert(is_undef(spin) || is_finite(spin), str("Invalid spin: ",spin))
    assert(is_undef(orient) || is_vector(orient,3), str("Invalid orient: ",orient))
    let(
        anchor=default(anchor,CENTER),
        spin=default(spin,0),
        orient=default(orient,UP),
        two_d = _attach_geom_2d(geom),
        m = is_def($attach_to) ?   // $attach_to is the attachment point on this object
              (                       // which will attach to the parent
                   let(                           
                        anch = _find_anchor($attach_to, geom),
                        // if $anchor_override is set it defines the object position anchor (but note not direction or spin).  
                        // Otherwise we use the provided anchor for the object.  
                        pos = is_undef($anchor_override) ? anch[1]
                            : _find_anchor(_make_anchor_legal($anchor_override,geom),geom)[1]
                   )
                   two_d?
                     affine3d_zrot(spin)  
                        * rot(to=FWD, from=point3d(anch[2])) 
                        * affine3d_translate(point3d(-pos))
                 :
                   affine3d_yrot(180)
                      * affine3d_zrot(-anch[3]-spin)
                      * rot(from=anch[2],to=UP)
                      * affine3d_translate(point3d(-pos))
              )
          :
            let(
                anchor = is_undef($attach_alignment) ? anchor
                       : two_d? _make_anchor_legal(zrot(-spin,$attach_alignment),geom)
                       : _make_anchor_legal(rot(spin, from=UP,to=orient,reverse=true,p=$attach_alignment),geom),
                pos = _find_anchor(anchor, geom)[1]
            )
            two_d? affine3d_zrot(spin) * affine3d_translate(point3d(-pos))
            :
                let(
                    axis = vector_axis(UP,orient),    // Returns BACK if orient is UP
                    ang = vector_angle(UP,orient)
                )
                affine3d_rot_by_axis(axis,ang) 
                    * affine3d_zrot(spin)  
                    * affine3d_translate(point3d(-pos))
    )
    is_undef(p)? m
  : is_vnf(p) && p==[[],[]] ? p 
  : apply(m, p);


function _get_cp(geom) =
    let(cp=select(geom,-3))
    is_vector(cp) ? cp
  : let(
        type = in_list(geom[0],["vnf_extent","vnf_isect"]) ? "vnf"
             : in_list(geom[0],["rgn_extent","rgn_isect"]) ? "path"
             : in_list(geom[0],["extrusion_extent","extrusion_isect"]) ? "xpath"
             : "other"
    )
    assert(type!="other", "Invalid cp value")
    cp=="centroid" ? (
       type=="vnf" && (len(geom[1][0])==0 || len(geom[1][1])==0) ? [0,0,0] :
       [each centroid(geom[1]), if (type=="xpath") 0]
    )
  : let(points = type=="vnf"?geom[1][0]:flatten(force_region(geom[1])))
    cp=="mean" ? [each mean(points), if (type=="xpath") 0]
  : cp=="box" ?[each  mean(pointlist_bounds(points)), if (type=="xpath") 0]
  : assert(false,"Invalid cp specification");


function _get_cp(geom) =
    let(cp=select(geom,-3))
    is_vector(cp) ? cp
  : let(
        is_vnf = in_list(geom[0],["vnf_extent","vnf_isect"])
    )
    cp == "centroid" ? (
       is_vnf && len(geom[1][1])==0
          ? [0,0,0]
          : centroid(geom[1])
    )
  : let(points = is_vnf?geom[1][0]:flatten(force_region(geom[1])))
    cp=="mean" ? mean(points)
  : cp=="box" ? mean(pointlist_bounds(points))
  : assert(false,"Invalid cp specification");



/// Internal Function: _find_anchor()
/// Usage:
///   anchorinfo = _find_anchor(anchor, geom);
/// Topics: Attachments
/// See Also: reorient(), attachable()
/// Description:
///   Calculates the anchor data for the given `anchor` vector or name, in the given attachment
///   geometry.  Returns `[ANCHOR, POS, VEC, ANG]` where `ANCHOR` is the requested anchorname
///   or vector, `POS` is the anchor position, `VEC` is the direction vector of the anchor, and
///   `ANG` is the angle to align with around the rotation axis of th anchor direction vector.
/// Arguments:
///   anchor = Vector or named anchor string.
///   geom = The geometry description of the shape.

function _three_edge_corner_dir(facevecs,edges) =
      let(
           v1 = vector_bisect(facevecs[0],facevecs[2]),
           v2 = vector_bisect(facevecs[1],facevecs[2]),
           p1 = plane_from_normal(rot(v=edges[0],a=90,p=v1)),
           p2 = plane_from_normal(rot(v=edges[1],a=-90,p=v2)),
           line = plane_intersection(p1,p2),
           v3 = unit(line[1]-line[0],UP)
       )
       unit(v3,UP);

function _find_anchor(anchor, geom)=
    is_string(anchor)? (
          anchor=="origin"? [anchor, CENTER, UP, 0]    // Ok that this returns 3d anchor in the 2d case?
        : let(
              anchors = last(geom),
              found = search([anchor], anchors, num_returns_per_match=1)[0]
          )
          assert(found!=[], str("Unknown anchor: ",anchor))
          anchors[found]
    ) :
    let(
        cp = _get_cp(geom),
        offset_raw = select(geom,-2),
        offset = [for (i=[0:2]) anchor[i]==0? 0 : offset_raw[i]],  // prevents bad centering.
        type = geom[0]
    )
    assert(is_vector(anchor),str("Invalid anchor: anchor=",anchor))
    let(
        anchor = point3d(anchor),
        oang = (
            approx(point2d(anchor), [0,0])? 0 :
            atan2(anchor.y, anchor.x)+90
        )
    )
    type == "prismoid"? ( //size, size2, shift, axis
        let(all_comps_good = [for (c=anchor) if (c!=sign(c)) 1]==[])
        assert(all_comps_good, "All components of an anchor for a cuboid/prismoid must be -1, 0, or 1")
        let(
            size=geom[1],
            size2=geom[2],
            shift=point2d(geom[3]),
            axis=point3d(geom[4]),
            override = geom[5](anchor)
        )
        let(
            size = [for (c = size) max(0,c)],
            size2 = [for (c = size2) max(0,c)],
            anch = rot(from=axis, to=UP, p=anchor),
            offset = rot(from=axis, to=UP, p=offset),
            h = size.z,
            u = (anch.z + 1) / 2,  // u is one of 0, 0.5, or 1
            axy = point2d(anch),
            bot = point3d(v_mul(point2d(size )/2, axy), -h/2),
            top = point3d(v_mul(point2d(size2)/2, axy) + shift, h/2),
            degenerate = sum(v_abs(point2d(anch)))==1 && (point2d(bot)==[0,0] || v_mul(point2d(size2)/2, axy)==[0,0]),
            edge = top-bot,
            other_edge = degenerate ? move(shift,mirror(axy, move(-shift,top))) - mirror(point3d(point2d(anch)), p=bot):CTR,
            pos = point3d(cp) + lerp(bot,top,u) + offset,
               // Find vectors of the faces involved in the anchor
            facevecs =
                [
                    if (anch.x!=0) unit(rot(from=UP, to=[edge.x,0,max(0.01,h)], p=[axy.x,0,0]), UP),
                    if (anch.y!=0) unit(rot(from=UP, to=[0,edge.y,max(0.01,h)], p=[0,axy.y,0]), UP),
                    if (anch.z!=0 && !degenerate) unit([0,0,anch.z],UP),
                    if (anch.z!=0 && degenerate && anch.y!=0)
                       unit(rot(from=UP, to=[0,other_edge.y,max(0.01,h)], p=[0,-axy.y,0]), UP),
                    if (anch.z!=0 && degenerate && anch.x!=0)
                       unit(rot(from=UP, to=[other_edge.x,0,max(0.01,h)], p=[-axy.x,0,0]), UP),
                ],
            dir = anch==CENTER? UP
                : len(facevecs)==1? unit(facevecs[0],UP)
                : len(facevecs)==2? vector_bisect(facevecs[0],facevecs[1])
                : _three_edge_corner_dir(facevecs,[FWD,LEFT])*anch.z,            
            edgedir = len(facevecs)!=2 ? undef
                    : rot(from=UP,to=axis,p=unit(cross(facevecs[0], facevecs[1]))), 
            edgeang = len(facevecs)==2 ? 180-vector_angle(facevecs[0], facevecs[1]) : undef,
            edgelen = anch.z==0 ? norm(edge)
                    : anch.z>0 ? abs([size2.y,size2.x]*axy)
                    : abs([size.y,size.x]*axy),
            endvecs = len(facevecs)!=2 ? undef
                    : anch.z==0 ? [DOWN, UP]
                    : let(
                          raxy = zrot(-90,axy),
                          bot1 = point3d(v_mul(point2d(size )/2, raxy), -h/2),
                          top1 = point3d(v_mul(point2d(size2)/2, raxy) + shift, h/2),
                          edge1 = top1-bot1,
                          vec1 = (raxy.x!=0) ? unit(rot(from=UP, to=[edge1.x,0,max(0.01,h)], p=[raxy.x,0,0]), UP)
                               :               unit(rot(from=UP, to=[0,edge1.y,max(0.01,h)], p=[0,raxy.y,0]), UP),
                          raxy2 = zrot(90,axy),
                          bot2 = point3d(v_mul(point2d(size )/2, raxy2), -h/2),
                          top2 = point3d(v_mul(point2d(size2)/2, raxy2) + shift, h/2),
                          edge2 = top2-bot2,
                          vec2 = (raxy2.y!=0) ? unit(rot(from=UP, to=[edge.x,0,max(0.01,h)], p=[raxy2.x,0,0]), UP)
                               :               unit(rot(from=UP, to=[0,edge.y,max(0.01,h)], p=[0,raxy2.y,0]), UP)
                      )
                      [vec1,vec2],
            final_dir = default(override[1],anch==CENTER?UP:rot(from=UP, to=axis, p=dir)),
            final_pos = default(override[0],rot(from=UP, to=axis, p=pos)),

            // If the anchor is an edge anchor and not horizontal we point spin UP
            // If the anchor is horizontal edge we point spin clockwise:
            //     cross product of UP with the edge direction will point OUT if we are on top and edge direction
            //     is correct.  We check if it points out by comparing to the final_dir which points out at that edge,
            //     with a correction for top/bottom (anchor.z).  
            // Otherwise use the standard BACK/UP definition
            // The precomputed oang value seems to be wrong, at least when axis!=UP
            spin = is_def(edgedir) && degenerate ? _compute_spin(final_dir, unit(((BACK+RIGHT)*edgedir)*edgedir))
                 : is_def(edgedir) && !approx(edgedir.z,0) ? _compute_spin(final_dir, edgedir * (edgedir*UP>0?1:-1))
                 : is_def(edgedir) ? _compute_spin(final_dir,
                                                   edgedir * (approx(unit(cross(UP,edgedir)),unit([final_dir.x,final_dir.y,0])*anchor.z) ? 1 : -1))
                 : _compute_spin(final_dir, final_dir==DOWN || final_dir==UP ? BACK : UP)
        ) [anchor, final_pos, final_dir, default(override[2],spin),
           if (is_def(edgeang)) [["edge_angle",edgeang],["edge_length",edgelen], ["vec", endvecs]]]
    ) : type == "conoid"? ( //r1, r2, l, shift, axis
        let(
            rr1=geom[1],
            rr2=geom[2],
            length=geom[3],
            shift=point2d(geom[4]),
            axis=point3d(geom[5]),
            r1 = is_num(rr1)? [rr1,rr1] : point2d(rr1),
            r2 = is_num(rr2)? [rr2,rr2] : point2d(rr2),
            anch = rot(from=axis, to=UP, p=anchor),
            axisname = axis==UP ? "Z"
                     : axis==RIGHT ? "X"
                     : axis==BACK ? "Y"
                     : "",
            dummy = assert(anch.z == sign(anch.z), str("The ",axisname," component of an anchor for the cylinder/cone must be -1, 0, or 1")),
            offset = rot(from=axis, to=UP, p=offset),
            u = (anch.z+1)/2,
            // Returns [point,tangent_dir]
            solve_ellipse = function (r,dir) approx(dir,[0,0]) ? [[0,0],[0,0]]
                                            : let(
                                                  x = r.x*dir.x*r.y / sqrt(dir.x^2*r.y^2+dir.y^2*r.x^2),
                                                  y = r.x*dir.y*r.y / sqrt(dir.x^2*r.y^2+dir.y^2*r.x^2)
                                             )
                                             [[x,y], unit([y*r.x^2,-x*r.y^2],CTR)],
            on_center = approx(point2d(anch), [0,0]),
            botdata = solve_ellipse(r1,point2d(anch)),
            topdata = solve_ellipse(r2,point2d(anch)),
            bot = point3d(botdata[0], -length/2),
            top = move(shift,point3d(topdata[0], length/2)),
            tangent = lerp(botdata[1],topdata[1],u), 
            normal = [-tangent.y,tangent.x],
            axy = unit(point2d(anch),[0,0]),
            obot = point3d(v_mul(r1,axy), -length/2),
            otop = point3d(v_mul(r2,axy)+shift, length/2),
            pos = point3d(cp) + lerp(bot,top,u) + offset,
            sidevec = rot(from=UP, to=top==bot?UP:top-bot, p=point3d(normal)),
            vvec = anch==CENTER? UP : unit([0,0,anch.z],UP),
            vec = on_center? unit(anch,UP)
                : approx(anch.z,0)? sidevec
                : unit((sidevec+vvec)/2,UP),
            pos2 = rot(from=UP, to=axis, p=pos),
            vec2 = anch==CENTER? UP : rot(from=UP, to=axis, p=vec),
               // Set spin for top/bottom to be clockwise
            spin = anch.z!=0 && (!approx(anch.x,0) || !approx(anch.y,0)) ? _compute_spin(vec2,rot(from=UP,to=axis,p=point3d(tangent)*anch.z))
                 : anch.z==0 && norm(anch)>EPSILON ? _compute_spin(vec2, (approx(vec2,DOWN) || approx(vec2,UP))?BACK:UP)
                 : oang
        ) [anchor, pos2, vec2, spin]
    ) : type == "point"? (
        let(
            anchor = unit(point3d(anchor),CENTER),
            pos = point3d(cp) + point3d(offset),
            vec = unit(anchor,UP)
        ) [anchor, pos, vec, oang]
    ) : type == "point2d"? (
        let(
            anchor = unit(_force_anchor_2d(anchor), [0,0]),
            pos = point2d(cp) + point2d(offset),
            vec = unit(anchor,BACK)
        ) [anchor, pos, vec, oang]
    ) : type == "spheroid"? ( //r
        let(
            rr = geom[1],
            r = is_num(rr)? [rr,rr,rr] : point3d(rr),
            anchor = unit(point3d(anchor),CENTER),
            pos = point3d(cp) + v_mul(r,anchor) + point3d(offset),
            vec = unit(v_mul(r,anchor),UP)
        ) [anchor, pos, vec, oang]
    ) : type == "vnf_isect"? ( //vnf
        let(
            vnf=geom[1],
            override = geom[2](anchor)
        )                                                   // CENTER anchors anchor on cp, "origin" anchors on [0,0]
        approx(anchor,CTR)? [anchor, default(override[0],cp),default(override[1],UP),default(override[2], 0)] :     
        vnf==EMPTY_VNF? [anchor, [0,0,0], unit(anchor), 0] :
        let(
            eps = 1/2048,
            points = vnf[0],
            faces = vnf[1],
            rpts = apply(rot(from=anchor, to=RIGHT) * move(-cp), points),
            hits = [
                for (face = faces)
                    let(
                        verts = select(rpts, face),
                        ys = column(verts,1),
                        zs = column(verts,2)
                    )
                    if (max(ys) >= -eps && max(zs) >= -eps &&
                        min(ys) <=  eps &&  min(zs) <=  eps)
                        let(
                            poly = select(points, face),
                            isect = polygon_line_intersection(poly, [cp,cp+anchor], eps=eps),
                            ptlist = is_undef(isect) ? [] :
                                     is_vector(isect) ? [isect]
                                                      : flatten(isect),   // parallel to a face
                            n = len(ptlist)>0 ? polygon_normal(poly) : undef
                        )
                        for(pt=ptlist) [anchor * (pt-cp), n, pt]
            ]
        )
        assert(len(hits)>0, "Anchor vector does not intersect with the shape.  Attachment failed.")
        let(
            furthest = max_index(column(hits,0)),
            dist = hits[furthest][0],
            pos = hits[furthest][2],
            hitnorms = [for (hit = hits) if (approx(hit[0],dist,eps=eps)) hit[1]],
            unorms = [
                      for (i = idx(hitnorms))
                          let(
                              thisnorm = hitnorms[i],
                              isdup = [
                                       for (j = [i+1:1:len(hitnorms)-1])
                                           if (approx(thisnorm, hitnorms[j])) 1
                                      ] != []
                          )
                          if (!isdup) thisnorm
                     ],
            n = unit(sum(unorms)),
            oang = approx(point2d(n), [0,0])? 0 : atan2(n.y, n.x) + 90
        )
        [anchor, default(override[0],pos),default(override[1], n),default(override[2], oang)]
    ) : type == "vnf_extent"? ( //vnf
        let(
            vnf=geom[1],
            override = geom[2](anchor)
            ,fd=echo(cp=cp)
        )                                                   // CENTER anchors anchor on cp, "origin" anchors on [0,0]
        approx(anchor,CTR)? [anchor, default(override[0],cp),default(override[1],UP),default(override[2], 0)] :     
        vnf==EMPTY_VNF? [anchor, [0,0,0], unit(anchor,UP), 0] :
        let(
            rpts = apply(rot(from=anchor, to=RIGHT) * move(point3d(-cp)), vnf[0]),
            maxx = max(column(rpts,0)),

            idxmax = [for (i = idx(rpts)) approx(rpts[i].x, maxx)],
            idxs = [for (i = idx(rpts)) if(approx(rpts[i].x, maxx)) i],
            veflist=[
                     for(face=vnf[1])
                       let(
                           facemax = [for(vertind=face) if (idxmax[vertind]) vertind],
                           flip = facemax[0]==face[0] && facemax[1]==last(face)
                       )
                       [
                         if (len(facemax)==1) facemax else [],
                         if (len(facemax)==2) (flip ? reverse(facemax):facemax) else [],
                         if (len(facemax)>2) facemax else []
                       ]],
            vlist = [for(i=idx(veflist)) if (veflist[i][0]!=[]) veflist[i][0]],
            elist = [for(i=idx(veflist)) if (veflist[i][1]!=[] && !approx(rpts[veflist[i][1][0]],rpts[veflist[i][1][1]])) veflist[i][1]],
            flist = [for(i=idx(veflist)) if (veflist[i][2]!=[])  veflist[i][2]],
            faceinfo = [for(face=flist) let(poly=select(vnf[0],face)) [polygon_area(poly), centroid(poly)]],  //[ area, centroid]
            facearea = len(faceinfo)==0 ? 0 : sum(column(faceinfo,0)),
            basic_spin = _compute_spin(anchor, v_abs(anchor)==UP ? BACK: UP),
            res = len(flist)>0 && !approx(facearea,0) ?
                      let(
                          center = column(faceinfo,0)*column(faceinfo,1)/facearea
                      )
                      [center,anchor,basic_spin]
                : len(elist)==2 ?  // One edge (which appears twice, once in each direction)
                      let(
                          edge = select(vnf[0],elist[0]),
                          center = mean(edge),
                          edgefaces = _vnf_find_edge_faces(vnf,elist), //unique([for(e=elist) each _vnf_find_edge_faces(vnf,e)]),
                          facenormals = [for(face=edgefaces) polygon_normal(select(vnf[0],vnf[1][face]))],
                          direction = unit(mean(facenormals)),
                          projnormals = project_plane(point4d(cross(facenormals[0],facenormals[1])), facenormals),
                          ang = 180- posmod(v_theta(projnormals[1])-v_theta(projnormals[0]),360),
                          horiz_face = [for(i=[0:1]) if (approx(v_abs(facenormals[i]),UP)) i],  // index of horizontal face, at most one exists
                          spin = horiz_face==[] ?
                                     let(
                                         edgedir = edge[1]-edge[0],
                                         nz = [for(i=[0:2]) if (!approx(edgedir[i],0)) i],
                                         flip = edgedir[last(nz)] < 0 ? -1 : 1
                                     )
                                     _compute_spin(direction, flip*edgedir)
                                  :
                                     let(  // Determine whether the edge is the right or wrong direction compared to the horizongal face
                                           // which will determine what clockwise means so we can assign spin
                                         face = select(vnf[1],edgefaces[horiz_face[0]]),
                                         endptidx=search(column(elist,0),face),
                                         hedge = elist[endptidx[0]!=[] ? 0:1],
                                         edgedir = deltas(select(vnf[0],hedge))[0],
                                         flip = select(face,flatten(endptidx)[0]+1)== hedge[1] ? 1 : -1
                                     )
                                     _compute_spin(direction, flip*edgedir)
                      )
                      [center,direction,spin,[["edge_angle",ang],["edge_length",norm(edge[1]-edge[0])]]]
                : len(elist)>2 ?   // multiple edges, which must be coplanar, use average of edge endpoints
                      let(
                           plist = select(vnf[0],flatten(edge)),
                           center = mean(plist)
                      )
                      [center,anchor,basic_spin]
                : len(vlist)==0 ? assert(false,"Cannot find anchor on the VNF")
                : let(
                      vlist = flatten(vlist),
                      uind = unique_approx_indexed(select(vnf[0],vlist)),
                      ulist = select(vlist,uind)
                  )
                  len(ulist)>1 ?   // Multiple vertices: return average
                      let(
                           center = mean(select(vnf[0],ulist))
                      )
                      [center, anchor, basic_spin]
                : let(    // one vertex case
                      vuniq = unique(vlist),
                      vertices = vnf[0],
                      faces = vnf[1],
                      cornerfaces = _vnf_find_corner_faces(vnf,vuniq),    // faces = [3,9,12] indicating which faces
                      normals = [for(faceind=cornerfaces) polygon_normal(select(vertices, faces[faceind]))],
                      angles = [for(faceind=cornerfaces)
                                  let(
                                       thisface = faces[faceind],
                                       vind = flatten(search(vuniq,thisface))[0]
                                  )
                                  vector_angle(select(vertices, select(thisface,vind-1,vind+1)))
                               ],
                             direc = unit(angles*normals)
                   )
                   [vnf[0][ulist[0]], direc, atan2(direc.y,direc.x)+90]
        ) [anchor, default(override[0],res[0]),default(override[1],res[1]),default(override[2],res[2]),if (len(res)==3) res[2]]        
    ) : type == "trapezoid"? ( //size, size2, shift, override
        let(all_comps_good = [for (c=anchor) if (c!=sign(c)) 1]==[])
        assert(all_comps_good, "All components of an anchor for a rectangle/trapezoid must be -1, 0, or 1")
        let(
            anchor=_force_anchor_2d(anchor),
            size=geom[1], size2=geom[2], shift=geom[3],
            u = (anchor.y+1)/2,  // 0<=u<=1
            frpt = [size.x/2*anchor.x, -size.y/2],
            bkpt = [size2/2*anchor.x+shift, size.y/2],
            override = geom[4](anchor),
            pos = override[0] != undef? override[0] :
                point2d(cp) + lerp(frpt, bkpt, u) + point2d(offset),
            svec = approx(bkpt,frpt)? [anchor.x,0,0] :
                point3d(line_normal(bkpt,frpt)*anchor.x),
            vec = is_def(override[1]) ? override[1]
                : anchor.y == 0? ( anchor.x == 0? BACK : svec )
                : anchor.x == 0? [0,anchor.y,0]
                : unit((svec + [0,anchor.y,0]) / 2, [0,anchor.y,0])
        ) [anchor, pos, vec, 0]
    ) : type == "ellipse"? ( //r
        let(
            anchor = unit(_force_anchor_2d(anchor),[0,0]),
            r = force_list(geom[1],2),
            pos = approx(anchor.x,0)
                ? [0,sign(anchor.y)*r.y]
                : let(
                       m = anchor.y/anchor.x,
                       px = approx(min(r),0)? 0 :
                           sign(anchor.x) * sqrt(1/(1/sqr(r.x) + m*m/sqr(r.y)))
                  )
                  [px,m*px],
            vec = approx(min(r),0)? (approx(norm(anchor),0)? BACK : anchor) :
                unit([r.y/r.x*pos.x, r.x/r.y*pos.y],BACK)
        ) [anchor, point2d(cp+offset)+pos, vec, 0]
    ) : type == "rgn_isect"? ( //region
        let(
            anchor = _force_anchor_2d(anchor),
            rgn = force_region(move(-point2d(cp), p=geom[1]))
        )
        approx(anchor,[0,0])? [anchor, cp, BACK, 0] :     // CENTER anchors anchor on cp, "origin" anchors on [0,0]
        let(
            isects = [
                for (path=rgn, t=triplet(path,true)) let(
                    seg1 = [t[0],t[1]],
                    seg2 = [t[1],t[2]],
                    isect = line_intersection([[0,0],anchor], seg1, RAY, SEGMENT),
                    n = is_undef(isect)? [0,1] :
                        !approx(isect, t[1])? line_normal(seg1) :
                        unit((line_normal(seg1)+line_normal(seg2))/2,[0,1]),
                    n2 = vector_angle(anchor,n)>90? -n : n
                )
                if(!is_undef(isect) && !approx(isect,t[0])) [norm(isect), isect, n2]
            ]
        )
        assert(len(isects)>0, "Anchor vector does not intersect with the shape.  Attachment failed.")
        let(
            maxidx = max_index(column(isects,0)),
            isect = isects[maxidx],
            pos = point2d(cp) + isect[1],
            vec = unit(isect[2],[0,1])
        ) [anchor, pos, vec, 0]
    ) : type == "rgn_extent"? ( //region
        let( anchor = _force_anchor_2d(anchor) )
        approx(anchor,[0,0])? [anchor, cp, BACK, 0] :   // CENTER anchors anchor on cp, "origin" anchors on [0,0]
        let(
            rgn = force_region(geom[1]),
            indexed_pts = [for(i=idx(rgn), j=idx(rgn[i])) [i,j,rgn[i][j]]],
            rpts = rot(from=anchor, to=RIGHT, p=column(indexed_pts,2)), 
            maxx = max(column(rpts,0)),
            index = [for (i=idx(rpts)) if (approx(rpts[i].x, maxx)) i],
            ys = [for (i=index) rpts[i].y],
            midy = (min(ys)+max(ys))/2,
            pos = rot(from=RIGHT, to=anchor, p=[maxx,midy]),
            dir = len(ys) > 1 ? [unit(anchor)]
                : let(
                       path = rgn[indexed_pts[index[0]][0]],
                       ctr = indexed_pts[index[0]][1],
                       corner = select(path, [ctr-1,ctr,ctr+1]),
                       normal = unit(unit(corner[0]-corner[1])+unit(corner[2]-corner[1]))
                  )
                  [is_polygon_clockwise(path) ? -normal : normal, vector_angle(corner)]
        ) [anchor, pos, dir[0], 0, if(len(dir)>1) [["corner_angle",dir[1]]]]
    ) : type=="extrusion_extent" || type=="extrusion_isect" ? (  // extruded region
        assert(in_list(anchor.z,[-1,0,1]), "The Z component of an anchor for an extruded 2D shape must be -1, 0, or 1.")
        let(
            anchor_xy = point2d(anchor),
            rgn = geom[1],
            L = geom[2],
            twist = geom[3],
            scale = geom[4],
            shift = geom[5],
            u = (anchor.z + 1) / 2,
            shmat = move(lerp([0,0], shift, u)),
            scmat = scale(lerp([1,1], scale, u)),
            twmat = zrot(lerp(0, -twist, u)),
            mat = shmat * scmat * twmat
        )
        approx(anchor_xy,[0,0]) ? [anchor, apply(mat, point3d(cp,anchor.z*L/2)), unit(anchor, UP), oang] :
        let(
            newrgn = apply(mat, rgn),
            newgeom = attach_geom(two_d=true, region=newrgn, extent=type=="extrusion_extent", cp=cp),
            topmat = anchor.z!=0 ? []
                   : move(shift)*scale(scale)*zrot(-twist),
            topgeom = anchor.z!=0? []
                    : attach_geom(two_d=true, region=apply(topmat,rgn), extent=type=="extrusion_extent", cp=cp),
            top2d =  anchor.z!=0? []
                  : _find_anchor(anchor_xy, topgeom),
            result2d = _find_anchor(anchor_xy, newgeom),
            pos = point3d(result2d[1], anchor.z*L/2),
            vec = anchor.z==0? rot(from=UP,to=point3d(top2d[1],L/2)-point3d(result2d[1]),p=point3d(result2d[2]))
                : unit(point3d(result2d[2], anchor.z),UP),
            oang = atan2(vec.y,vec.x) + 90
        )
        [anchor, pos, vec, oang]
    ) :
    assert(false, "Unknown attachment geometry type.");


/// Internal Function: _is_shown()
/// Usage:
///   bool = _is_shown();
/// Topics: Attachments
/// See Also: reorient(), attachable()
/// Description:
///   Returns true if objects should currently be shown based on the tag settings.
function _is_shown() =
    assert(is_list($tags_shown) || $tags_shown=="ALL")
    assert(is_list($tags_hidden))
    let(
        dummy=is_undef($tags) ? 0 : echo("Use tag() instead of $tags for specifying an object's tag."),
        $tag = default($tag,$tags)
    )
    assert(is_string($tag), str("Tag value (",$tag,") is not a string"))
    assert(undef==str_find($tag," "),str("Tag string \"",$tag,"\" contains a space, which is not allowed"))
    let(
        shown  = $tags_shown=="ALL" || in_list($tag,$tags_shown),
        hidden = in_list($tag, $tags_hidden)
    )
    shown && !hidden;


// Section: Visualizing Anchors

/// Internal Function: _standard_anchors()
/// Usage:
///   anchs = _standard_anchors([two_d]);
/// Description:
///   Return the vectors for all standard anchors.
/// Arguments:
///   two_d = If true, returns only the anchors where the Z component is 0.  Default: false
function _standard_anchors(two_d=false) = [
    for (
        zv = [
            if (!two_d) TOP,
            CENTER,
            if (!two_d) BOTTOM
        ],
        yv = [FRONT, CENTER, BACK],
        xv = [LEFT, CENTER, RIGHT]
    ) xv+yv+zv
];



// Module: show_anchors()
// Synopsis: Shows anchors for the parent object.
// SynTags: Geom
// Topics: Attachments
// See Also: expose_anchors(), anchor_arrow(), anchor_arrow2d(), frame_ref()
// Usage:
//   PARENT() show_anchors([s], [std=], [custom=]);
// Description:
//   Show all standard anchors for the parent object.
// Arguments:
//   s = Length of anchor arrows.
//   ---
//   std = If true show standard anchors.  Default: true
//   custom = If true show named anchors.  Default: true
// Example(FlatSpin,VPD=333):
//   cube(50, center=true) show_anchors();
module show_anchors(s=10, std=true, custom=true) {
    check = assert($parent_geom != undef);
    two_d = _attach_geom_2d($parent_geom);
    if (std) {
        for (anchor=_standard_anchors(two_d=two_d)) {
            if(two_d) {
                attach(anchor,BOT) anchor_arrow2d(s);
            } else {
                attach(anchor,BOT) anchor_arrow(s);
            }
        }
    }
    if (custom) {
        for (anchor=last($parent_geom)) {
            attach(anchor[0],BOT) {
                if(two_d) {
                    anchor_arrow2d(s, color="cyan");
                } else {
                    anchor_arrow(s, color="cyan");
                }
                color("black")
                tag("anchor-arrow") {
                    xrot(two_d? 0 : 90) {
                        back(s/3) {
                            yrot_copies(n=2)
                            up(two_d? 0.51 : s/30) {
                                linear_extrude(height=0.01, convexity=12, center=true) {
                                    text(text=anchor[0], size=s/4, halign="center", valign="center", font="Helvetica", $fn=36);
                                }
                            }
                        }
                    }
                }
                color([1, 1, 1, 1])
                tag("anchor-arrow") {
                    xrot(two_d? 0 : 90) {
                        back(s/3) {
                             cube([s/4.5*len(anchor[0]), s/3, 0.01], center=true);
                        }
                   }
                }
            }
        }
    }
    children();
}


// Module: anchor_arrow()
// Synopsis: Shows a 3d anchor orientation arrow.
// SynTags: Geom
// Topics: Attachments
// See Also: anchor_arrow2d(), show_anchors(), expose_anchors(), frame_ref(), generic_airplane()
// Usage:
//   anchor_arrow([s], [color], [flag], [anchor=], [orient=], [spin=]) [ATTACHMENTS];
// Description:
//   Show an anchor orientation arrow.  By default, tagged with the name "anchor-arrow".
// Arguments:
//   s = Length of the arrows.  Default: `10`
//   color = Color of the arrow.  Default: `[0.333, 0.333, 1]`
//   flag = If true, draw the orientation flag on the arrowhead.  Default: true
//   ---
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
// Example:
//   anchor_arrow(s=20);
module anchor_arrow(s=10, color=[0.333,0.333,1], flag=true, $tag="anchor-arrow", $fn=12, anchor=BOT, spin=0, orient=UP) {
    attachable(anchor,spin,orient, r=s/6, l=s) {
        down(s/2)
        recolor("gray") spheroid(d=s/6) {
            attach(CENTER,BOT) recolor(color) cyl(h=s*2/3, d=s/15) {
                attach(TOP,BOT) cyl(h=s/3, d1=s/5, d2=0) {
                    if(flag) {
                        position(BOT)
                            recolor([1,0.5,0.5])
                                cuboid([s/100, s/6, s/4], anchor=FRONT+BOT);
                    }
                }
            }
        }
        children();
    }
}



// Module: anchor_arrow2d()
// Synopsis: Shows a 2d anchor orientation arrow.
// SynTags: Geom
// Topics: Attachments
// See Also: anchor_arrow(), show_anchors(), expose_anchors(), frame_ref()
// Usage:
//   anchor_arrow2d([s], [color]);
// Description:
//   Show an anchor orientation arrow.
// Arguments:
//   s = Length of the arrows.
//   color = Color of the arrow.
// Example:
//   anchor_arrow2d(s=20);
module anchor_arrow2d(s=15, color=[0.333,0.333,1], $tag="anchor-arrow") {
    color(color) stroke([[0,0],[0,s]], width=s/10, endcap1="butt", endcap2="arrow2");
}



// Module: expose_anchors()
// Synopsis: Used to show a transparent object with solid color anchor arrows.
// Topics: Attachments
// See Also: anchor_arrow2d(), show_anchors(), show_anchors(), frame_ref()
// Usage:
//   expose_anchors(opacity) {child1() show_anchors(); child2() show_anchors(); ...}
// Description:
//   Used in combination with show_anchors() to display an object in transparent gray with its anchors in solid color.
//   Children will appear transparent and any anchor arrows drawn with will appear in solid color.
// Arguments:
//   opacity = The opacity of the children.  0.0 is invisible, 1.0 is opaque.  Default: 0.2
// Example(FlatSpin,VPD=333):
//   expose_anchors() cube(50, center=true) show_anchors();
module expose_anchors(opacity=0.2) {
    show_only("anchor-arrow")
        children();
    hide("anchor-arrow")
        color(is_undef($color) || $color=="default" ? [0,0,0] :
              is_string($color) ? $color
                                : point3d($color),
              opacity)
            children();
}



// Module: show_transform_list()
// Synopsis: Shows a list of transforms and how they connect.
// SynTags: Geom
// Topics: Attachments
// See Also: generic_airplane(), anchor_arrow(), show_anchors(), expose_anchors(), frame_ref()
// Usage:
//   show_transform_list(tlist, [s]);
//   show_transform_list(tlist) CHILDREN;
// Description:
//   Given a list of transformation matrices, shows the position and orientation of each one.
//   A line is drawn from each transform position to the next one, and an orientation indicator is
//   shown at each position.  If a child is passed, that child will be used as the orientation indicator.
//   By default, a {{generic_airplane()}} is used as the orientation indicator.
// Arguments:
//   s = Length of the {{generic_airplane()}}.  Default: 5
// Example:
//   tlist = [
//       zrot(90),
//       zrot(90) * fwd(30) * zrot(30),
//       zrot(90) * fwd(30) * zrot(30) *
//           fwd(35) * xrot(-30),
//       zrot(90) * fwd(30) * zrot(30) *
//           fwd(35) * xrot(-30) * fwd(40) * yrot(15),
//   ];
//   show_transform_list(tlist, s=20);
// Example:
//   tlist = [
//       zrot(90),
//       zrot(90) * fwd(30) * zrot(30),
//       zrot(90) * fwd(30) * zrot(30) *
//           fwd(35) * xrot(-30),
//       zrot(90) * fwd(30) * zrot(30) *
//           fwd(35) * xrot(-30) * fwd(40) * yrot(15),
//   ];
//   show_transform_list(tlist) frame_ref();
module show_transform_list(tlist, s=5) {
    path = [for (m = tlist) apply(m, [0,0,0])];
    stroke(path, width=s*0.03);
    for (m = tlist) {
        multmatrix(m) {
            if ($children>0) children();
            else generic_airplane(s=s);
        }
    }
}


// Module: generic_airplane()
// Synopsis: Shows a generic airplane shape, useful for viewing orientations.
// SynTags: Geom
// Topics: Attachments
// See Also: anchor_arrow(), show_anchors(), expose_anchors(), frame_ref()
// Usage:
//   generic_airplane([s]);
// Description:
//   Creates a generic airplane shape.  This can be useful for viewing the orientation of 3D transforms.
// Arguments:
//   s = Length of the airplane.  Default: 5
// Example:
//   generic_airplane(s=20);
module generic_airplane(s=5) {
    $fn = max(segs(0.05*s), 12);
    color("#ddd")
    fwd(s*0.05)
    ycyl(l=0.7*s, d=0.1*s) {
        attach(FWD) top_half(s=s) zscale(2) sphere(d=0.1*s);
        attach(BACK,FWD) ycyl(l=0.2*s, d1=0.1*s, d2=0.05*s) {
            yrot_copies([-90,0,90])
                prismoid(s*[0.01,0.2], s*[0.01,0.05],
                    h=0.2*s, shift=s*[0,0.15], anchor=BOT);
        }
        yrot_copies([-90,90])
            prismoid(s*[0.01,0.2], s*[0.01,0.05],
                h=0.5*s, shift=s*[0,0.15], anchor=BOT);
    }
    color("#777") zcopies(0.1*s) sphere(d=0.02*s);
    back(0.09*s) {
        color("#f00") right(0.46*s) sphere(d=0.04*s);
        color("#0f0") left(0.46*s) sphere(d=0.04*s);
    }
}



// Module: frame_ref()
// Synopsis: Shows axis orientation arrows.
// SynTags: Geom
// Topics: Attachments
// See Also: anchor_arrow(), anchor_arrow2d(), show_anchors(), expose_anchors()
// Usage:
//   frame_ref(s, opacity);
// Description:
//   Displays X,Y,Z axis arrows in red, green, and blue respectively.
// Arguments:
//   s = Length of the arrows.
//   opacity = The opacity of the arrows.  0.0 is invisible, 1.0 is opaque.  Default: 1.0
// Examples:
//   frame_ref(25);
//   frame_ref(30, opacity=0.5);
module frame_ref(s=15, opacity=1) {
    cube(0.01, center=true) {
        attach([1,0,0]) anchor_arrow(s=s, flag=false, color=[1.0, 0.3, 0.3, opacity]);
        attach([0,1,0]) anchor_arrow(s=s, flag=false, color=[0.3, 1.0, 0.3, opacity]);
        attach([0,0,1]) anchor_arrow(s=s, flag=false, color=[0.3, 0.3, 1.0, opacity]);
        children();
    }
}


////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
///
/// Code after this is internal code for managing edge and corner sets and for displaying
/// edge and corners in the docs
///

module _edges_text3d(txt,size=3) {
    if (is_list(txt)) {
        for (i=idx(txt)) {
            down((i-len(txt)/2+0.5)*size*1.5) {
                _edges_text3d(txt[i], size=size);
            }
        }
    } else {
        xrot(90) color("#000")
        linear_extrude(height=0.1) {
            text(text=txt, size=size, halign="center", valign="center");
        }
    }
}


function _edges_vec_txt(x) = is_string(x)? str("\"", x, "\"") :
    assert(is_string(x) || is_vector(x,3), str(x))
    let(
        lst = concat(
            x.z>0? ["TOP"]   : x.z<0? ["BOT"]  : [],
            x.y>0? ["BACK"]  : x.y<0? ["FWD"]  : [],
            x.x>0? ["RIGHT"] : x.x<0? ["LEFT"] : []
        ),
        out = [
           for (i = idx(lst))
           i>0? str("+",lst[i]) : lst[i]
        ]
    ) out;


function _edges_text(edges) =
    is_string(edges) ? [str("\"",edges,"\"")] :
    edges==EDGES_NONE ? ["EDGES_NONE"] :
    edges==EDGES_ALL ? ["EDGES_ALL"] :
    _is_edge_array(edges) ? [""] :
    is_vector(edges,3) ? _edges_vec_txt(edges) :
    is_list(edges) ? let(
        lst = [for (x=edges) each _edges_text(x)],
        out = [
            for (i=idx(lst))
            str(
                (i==0? "[" : ""),
                lst[i],
                (i<len(lst)-1? "," : ""),
                (i==len(lst)-1? "]" : "")
            )
        ]
    ) out :
    [""];



/// Internal Constant: EDGES_NONE
/// Topics: Edges
/// See Also: EDGES_ALL, edges()
/// Description:
///   The set of no edges.
/// Figure(3D):
///   _show_edges(edges="NONE");
EDGES_NONE = [[0,0,0,0], [0,0,0,0], [0,0,0,0]];


/// Internal Constant: EDGES_ALL
/// Topics: Edges
/// See Also: EDGES_NONE, edges()
/// Description:
///   The set of all edges.
/// Figure(3D):
///   _show_edges(edges="ALL");
EDGES_ALL = [[1,1,1,1], [1,1,1,1], [1,1,1,1]];


/// Internal Constant: EDGES_OFFSETS
/// Topics: Edges
/// See Also: EDGES_NONE, EDGES_ALL, edges()
/// Description:
///   The vectors pointing to the center of each edge of a unit sized cube.
///   Each item in an edge array will have a corresponding vector in this array.
EDGE_OFFSETS = [
    [
        [ 0,-1,-1],
        [ 0, 1,-1],
        [ 0,-1, 1],
        [ 0, 1, 1]
    ], [
        [-1, 0,-1],
        [ 1, 0,-1],
        [-1, 0, 1],
        [ 1, 0, 1]
    ], [
        [-1,-1, 0],
        [ 1,-1, 0],
        [-1, 1, 0],
        [ 1, 1, 0]
    ]
];



/// Internal Function: _is_edge_array()
/// Topics: Edges, Type Checking
/// Usage:
///   bool = _is_edge_array(x);
/// Description:
///   Returns true if the given value has the form of an edge array.
/// Arguments:
///   x = The item to check the type of.
/// See Also: edges(), EDGES_NONE, EDGES_ALL
function _is_edge_array(x) = is_list(x) && is_vector(x[0]) && len(x)==3 && len(x[0])==4;


function _edge_set(v) =
    _is_edge_array(v)? v : [
    for (ax=[0:2]) [
        for (b=[-1,1], a=[-1,1]) let(
            v2=[[0,a,b],[a,0,b],[a,b,0]][ax]
        ) (
            is_string(v)? (
                v=="X"? (ax==0) :   // Return all X axis aligned edges.
                v=="Y"? (ax==1) :   // Return all Y axis aligned edges.
                v=="Z"? (ax==2) :   // Return all Z axis aligned edges.
                v=="ALL"? true :    // Return all edges.
                v=="NONE"? false :  // Return no edges.
                let(valid_values = ["X", "Y", "Z", "ALL", "NONE"])
                assert(
                    in_list(v, valid_values),
                    str(v, " must be a vector, edge array, or one of ", valid_values)
                ) v
            ) :
            let(nonz = sum(v_abs(v)))
            nonz==2? (v==v2) :  // Edge: return matching edge.
            let(
                matches = num_true([
                    for (i=[0:2]) v[i] && (v[i]==v2[i])
                ])
            )
            nonz==1? (matches==1) :  // Face: return surrounding edges.
            (matches==2)             // Corner: return touching edges.
        )? 1 : 0
    ]
];


/// Internal Function: _normalize_edges()
/// Topics: Edges
/// Usage:
///   edges = _normalize_edges(v);
/// Description:
///   Normalizes all values in an edge array to be `1`, if it was originally greater than `0`,
///   or `0`, if it was originally less than or equal to `0`.
/// See Also:  edges(), EDGES_NONE, EDGES_ALL
function _normalize_edges(v) = [for (ax=v) [for (edge=ax) edge>0? 1 : 0]];




/// Internal Function: _edges()
/// Topics: Edges
/// Usage:
///   edgs = _edges(v);
///   edgs = _edges(v, except);
///
/// Description:
///   Takes a list of edge set descriptors, and returns a normalized edges array
///   that represents all those given edges.
/// Arguments:
///   v = The edge set to include.
///   except = The edge set to specifically exclude, even if they are in `v`.
///
/// See Also:  EDGES_NONE, EDGES_ALL
///
function _edges(v, except=[]) =
    v==[] ? EDGES_NONE :
    (is_string(v) || is_vector(v) || _is_edge_array(v))? _edges([v], except=except) :
    (is_string(except) || is_vector(except) || _is_edge_array(except))? _edges(v, except=[except]) :
    except==[]? _normalize_edges(sum([for (x=v) _edge_set(x)])) :
    _normalize_edges(
        _normalize_edges(sum([for (x=v) _edge_set(x)])) -
        sum([for (x=except) _edge_set(x)])
    );


/// Internal Module: _show_edges()
/// Topics: Edges, Debugging
/// Usage:
///   _show_edges(edges, [size=], [text=], [txtsize=]);
/// Description:
///   Draws a semi-transparent cube with the given edges highlighted in red.
/// Arguments:
///   edges = The edges to highlight.
///   size = The scalar size of the cube.
///   text = The text to show on the front of the cube.
///   txtsize = The size of the text.
/// See Also: _edges(), EDGES_NONE, EDGES_ALL
/// Example:
///   _show_edges(size=30, edges=["X","Y"]);
module _show_edges(edges="ALL", size=20, text, txtsize=3,toplabel) {
    edge_set = _edges(edges);
    text = !is_undef(text) ? text : _edges_text(edges);
    color("red") {
        for (axis=[0:2], i=[0:3]) {
            if (edge_set[axis][i] > 0) {
                translate(EDGE_OFFSETS[axis][i]*size/2) {
                    if (axis==0) xcyl(h=size, d=2);
                    if (axis==1) ycyl(h=size, d=2);
                    if (axis==2) zcyl(h=size, d=2);
                }
            }
        }
    }
    fwd(size/2) _edges_text3d(text, size=txtsize);
    color("yellow",0.7) cuboid(size=size);
    vpr = [55,0,25];
    color("black")
    if (is_def(toplabel))
      for(h=idx(toplabel)) up(21+6*h)rot(vpr) text3d(select(toplabel,-h-1),size=3.3,h=0.1,orient=UP,anchor=FRONT);
}




/// Internal Constant: CORNERS_NONE
/// Topics: Corners
/// Description:
///   The set of no corners.
/// Figure(3D):
///   _show_corners(corners="NONE");
/// See Also: CORNERS_ALL, corners()
CORNERS_NONE = [0,0,0,0,0,0,0,0];  // No corners.


/// Internal Constant: CORNERS_ALL
/// Topics: Corners
/// Description:
///   The set of all corners.
/// Figure(3D):
///   _show_corners(corners="ALL");
/// See Also: CORNERS_NONE, _corners()
CORNERS_ALL = [1,1,1,1,1,1,1,1];


/// Internal Constant: CORNER_OFFSETS
/// Topics: Corners
/// Description:
///   The vectors pointing to each corner of a unit sized cube.
///   Each item in a corner array will have a corresponding vector in this array.
/// See Also: CORNERS_NONE, CORNERS_ALL, _corners()
CORNER_OFFSETS = [
    [-1,-1,-1], [ 1,-1,-1], [-1, 1,-1], [ 1, 1,-1],
    [-1,-1, 1], [ 1,-1, 1], [-1, 1, 1], [ 1, 1, 1]
];




/// Internal Function: _is_corner_array()
/// Topics: Corners, Type Checking
/// Usage:
///   bool = _is_corner_array(x)
/// Description:
///   Returns true if the given value has the form of a corner array.
/// See Also: CORNERS_NONE, CORNERS_ALL, _corners()
function _is_corner_array(x) = is_vector(x) && len(x)==8 && all([for (xx=x) xx==1||xx==0]);


/// Internal Function: _normalize_corners()
/// Topics: Corners
/// Usage:
///   corns = _normalize_corners(v);
/// Description:
///   Normalizes all values in a corner array to be `1`, if it was originally greater than `0`,
///   or `0`, if it was originally less than or equal to `0`.
/// See Also: CORNERS_NONE, CORNERS_ALL, _corners()
function _normalize_corners(v) = [for (x=v) x>0? 1 : 0];


function _corner_set(v) =
    _is_corner_array(v)? v : [
    for (i=[0:7]) let(
        v2 = CORNER_OFFSETS[i]
    ) (
        is_string(v)? (
            v=="ALL"? true :    // Return all corners.
            v=="NONE"? false :  // Return no corners.
            let(valid_values = ["ALL", "NONE"])
            assert(
                in_list(v, valid_values),
                str(v, " must be a vector, corner array, or one of ", valid_values)
            ) v
        ) :
        all([for (i=[0:2]) !v[i] || (v[i]==v2[i])])
    )? 1 : 0
];


/// Function: _corners()
/// Topics: Corners
/// Usage:
///   corns = _corners(v);
///   corns = _corners(v, except);
/// Description:
///   Takes a list of corner set descriptors, and returns a normalized corners array
///   that represents all those given corners.  If the `except` argument is given
///   a list of corner set descriptors, then all those corners will be removed
///   from the returned corners array.  If either argument only has a single corner
///   set descriptor, you do not have to pass it in a list.
function _corners(v, except=[]) =
    v==[] ? CORNERS_NONE :
    (is_string(v) || is_vector(v) || _is_corner_array(v))? _corners([v], except=except) :
    (is_string(except) || is_vector(except) || _is_corner_array(except))? _corners(v, except=[except]) :
    except==[]? _normalize_corners(sum([for (x=v) _corner_set(x)])) :
    let(
        a = _normalize_corners(sum([for (x=v) _corner_set(x)])),
        b = _normalize_corners(sum([for (x=except) _corner_set(x)]))
    ) _normalize_corners(a - b);


/// Internal Function: _corner_edges()
/// Topics: Corners
/// Description:
///   Returns [XCOUNT,YCOUNT,ZCOUNT] where each is the count of edges aligned with that
///   axis that are in the edge set and touch the given corner.
/// Arguments:
///   edges = Standard edges array.
///   v = Vector pointing to the corner to count edge intersections at.
/// See Also: CORNERS_NONE, CORNERS_ALL, _corners()
function _corner_edges(edges, v) =
    let(u = (v+[1,1,1])/2) [edges[0][u.y+u.z*2], edges[1][u.x+u.z*2], edges[2][u.x+u.y*2]];


/// InternalFunction: _corner_edge_count()
/// Topics: Corners
/// Description:
///   Counts how many given edges intersect at a specific corner.
/// Arguments:
///   edges = Standard edges array.
///   v = Vector pointing to the corner to count edge intersections at.
/// See Also: CORNERS_NONE, CORNERS_ALL, _corners()
function _corner_edge_count(edges, v) =
    let(u = (v+[1,1,1])/2) edges[0][u.y+u.z*2] + edges[1][u.x+u.z*2] + edges[2][u.x+u.y*2];


function _corners_text(corners) =
    is_string(corners) ? [str("\"",corners,"\"")] :
    corners==CORNERS_NONE ? ["CORNERS_NONE"] :
    corners==CORNERS_ALL ? ["CORNERS_ALL"] :
    _is_corner_array(corners) ? [""] :
    is_vector(corners,3) ? _edges_vec_txt(corners) :
    is_list(corners) ? let(
        lst = [for (x=corners) each _corners_text(x)],
        out = [
            for (i=idx(lst))
            str(
                (i==0? "[" : ""),
                lst[i],
                (i<len(lst)-1? "," : ""),
                (i==len(lst)-1? "]" : "")
            )
        ]
    ) out :
    [""];


/// Internal Module: _show_corners()
/// Topics: Corners, Debugging
/// Usage:
///   _show_corners(corners, [size=], [text=], [txtsize=]);
/// Description:
///   Draws a semi-transparent cube with the given corners highlighted in red.
/// Arguments:
///   corners = The corners to highlight.
///   size = The scalar size of the cube.
///   text = If given, overrides the text to be shown on the front of the cube.
///   txtsize = The size of the text.
/// See Also: CORNERS_NONE, CORNERS_ALL, corners()
/// Example:
///   _show_corners(corners=FWD+RIGHT, size=30);
module _show_corners(corners="ALL", size=20, text, txtsize=3,toplabel) {
    corner_set = _corners(corners);
    text = !is_undef(text) ? text : _corners_text(corners);
    for (i=[0:7]) if (corner_set[i]>0)
        translate(CORNER_OFFSETS[i]*size/2)
            color("red") sphere(d=2, $fn=16);
    fwd(size/2) _edges_text3d(text, size=txtsize);
    color("yellow",0.7) cuboid(size=size);
    vpr = [55,0,25];
    color("black")
    if (is_def(toplabel))
      for(h=idx(toplabel)) up(21+6*h)rot(vpr) text3d(select(toplabel,-h-1),size=3.3,h=.1,orient=UP,anchor=FRONT);
}

module _show_cube_faces(faces, size=20, toplabel,botlabel) {
   color("red")
     for(f=faces){
          move(f*size/2) rot(from=UP,to=f)
             cuboid([size,size,.1]);
     }
   vpr = [55,0,25];
   color("black"){
   if (is_def(toplabel))
     for(h=idx(toplabel)) up(21+6*h)rot(vpr) text3d(select(toplabel,-h-1),size=3.3,h=.1,orient=UP,anchor=FRONT);
   if (is_def(botlabel))
     for(h=idx(botlabel)) down(26+6*h)rot(vpr) text3d(botlabel[h],size=3.3,h=.1,orient=UP,anchor=FRONT);
   }
   color("yellow",0.7) cuboid(size=size);
}



/// Internal utility function

function _force_rot(T) =
   [for(i=[0:3])
       [for(j=[0:3]) j<3 ? T[i][j] :
                     i==3 ? 1
                       : 0]];

function _local_struct_val(struct, key)=
    assert(is_def(key),"key is missing")
    let(ind = search([key],struct)[0])
    ind == [] ? undef : struct[ind][1];


function _force_anchor_2d(anchor) =
  is_undef(anchor) || len(anchor)==2 || is_string(anchor) ? anchor :
  assert(anchor.y==0 || anchor.z==0, "Anchor for a 2D shape cannot be fully 3D.  It must have either Y or Z component equal to zero.")
  anchor.y==0 ? [anchor.x,anchor.z] : point2d(anchor);

// Compute spin angle based on a anchor direction and desired spin direction
// anchor_dir assumed to be a unit vector; no assumption on spin_dir
// Takes the component of the spin direction perpendicular to the anchor
// direction and gives the spin angle that achieves it.  
function _compute_spin(anchor_dir, spin_dir) =
   let(
        native_dir = rot(from=UP, to=anchor_dir, p=BACK),
        spin_dir = spin_dir - (spin_dir*anchor_dir)*anchor_dir,  // component of spin_dir perpendicular to anchor_dir
        dummy = assert(!approx(spin_dir,[0,0,0]),"spin direction is parallel to anchor"),
        angle = vector_angle(native_dir,spin_dir),
        sign = cross(native_dir,spin_dir)*anchor_dir<0 ? -1 : 1
   )
   sign*angle;

        
// Compute canonical edge direction so that edge is either Z+, Y+ or X+ in that order
function _canonical_edge(edge) =
  let(
       nz = [for(i=[0:2]) if (!approx(edge[i],0)) i],
       flip = edge[last(nz)] < 0 ? -1 : 1
  )
  flip * edge;



// Section: Attachable Descriptions for Operating on Attachables or Restoring a Previous State

// Function: parent()
// Topics: Transforms, Attachments, Descriptions
// See Also: restore(), parent_part()
// Synopsis: Returns a description (transformation state and attachment geometry) of the parent
// Usage:
//   PARENT() let( desc = parent() ) CHILDREN;
// Usage: in development releases only
//   PARENT() { desc=parent(); CHILDREN; }
// Description:
//   Returns a description of the closest attachable ancestor in the geometry tree, along with the current transformation.  You can use this
//   description to create new objects based on the described object or perform computations based on the described object.  You can also use it to
//   restore the context of the parent object and transformation state using {{restore()}}.  Note that with OpenSCAD 2021.01 you need to use `let` for
//   this function to work, and the definition of the variable is scoped to the children of the let module.
//   (In development versions the use of let is no longer necessary.)  Note that if OpenSCAD displays any warnings
//   related to transformation operations then the transformation that parent() returns is likely to be incorrect, even if OpenSCAD
//   continues to run and produces a valid result.  
function parent() =
    let(
        geom = default($parent_geom, attach_geom([0,0,0]))
    )                 
    [$transform, geom];



// Function: parent_part()
// Topics: Transforms, Attachments, Descriptions
// See Also: restore(), parent()
// Synopsis: Returns a description (transformation state and attachment geometry) of a part defined by the parent
// Usage:
//   PARENT() let( desc = parent_part(name) ) CHILDREN;
// Usage: in development releases only
//   PARENT() { desc=parent_part(name); CHILDREN; }
// Description:
//   Returns a description of the parent part with the specified name.  You can use this
//   description to create new objects based on the described object or perform computations based on the described object.  You can also use it to
//   restore the context of the parent object and transformation state using {{restore()}}.  Note that with OpenSCAD 2021.01 you need to use `let` for
//   this function to work, and the definition of the variable is scoped to the children of the let module.
//   (In development versions the use of let is no longer necessary.)  Note that if OpenSCAD displays any warnings
//   related to transformation operations then the transformation that parent_part() returns is likely to be incorrect, even if OpenSCAD
//   continues to run and produces a valid result.
// Example(3D): This example defines an object with two parts and then uses `parent_part()` to create a {{prism_connector()}} between the two parts of the object.
//   $fn=48;
//   module twocyl(d, sep, h, ang=20) 
//   {
//      parts = [
//                define_part("left", attach_geom(r=d/2,h=h),
//                                    T=left(sep/2)*yrot(-ang)),
//                define_part("right", attach_geom(r=d/2,h=h),
//                                     T=right(sep/2)*yrot(ang)),
//              ];
//      attachable(size=[sep+d,d,h], parts=parts){
//        union(){
//            left(sep/2) yrot(-ang) cyl(d=d,h=h);
//            right(sep/2) yrot(ang) cyl(d=d,h=h);
//        }
//        children();
//      }  
//   }
//   twocyl(d=10,sep=20,h=10) 
//     prism_connector(circle(r=2,$fn=32),
//                     parent_part("left"), RIGHT,
//                     parent_part("right"), LEFT,
//                     fillet=1);

function parent_part(name) =
    assert(!is_undef($parent_parts), "Parent does not exist or does not have any parts")
    let(
        ind = search([name], $parent_parts, 1,0)[0]
    )
    assert(ind!=[], str("Parent does not have a part named ",name))    
    [$transform * $parent_parts[ind][3], $parent_parts[ind][1]];


// Module: restore()
// Synopsis: Restores transformation state and attachment geometry from a description
// Topics: Transforms, Attachments, Descriptions
// See Also: parent()
// Usage:
//   restore([desc]) CHILDREN;
// Description:
//   Restores the transformation and parent geometry contained in the specified description which you obtained with {{parent()}}.  
//   If you don't give a description then restores the global world coordinate system with a zero size cuboid object as the parent.
// Arguments:
//   desc = saved description to restore.  Default: restore to world coordinates
// Example(3D):  The pink cube is a child of the green cube, but {{restore()}} restores the state to the yellow parent cube, so the pink cube attaches to the yellow cube
//  left(5) cuboid(10)
//    let(save_pt = parent())
//    attach(RIGHT,BOT) recolor("green") cuboid(3)
//    restore(save_pt)
//      attach(FWD,BOT) recolor("pink") cuboid(3);

module restore(desc)
{
   req_children($children);
   if (is_undef(desc)){
     T = matrix_inverse($transform);
     $parent_geom = attach_geom([0,0,0]);
     multmatrix(T) children();
   }
   else{
     check=assert(is_description(desc), "Invalid description");
     T = linear_solve($transform, desc[0]);
     $parent_geom = desc[1];
     multmatrix(T) children();
   }
}

// Function: desc_point()
// Synopsis: Computes the location in the current context of an anchor point from an attachable description
// Topics: Descriptions, Attachments
// See Also: parent(), desc_dist()
// Usage:
//   point = desc_point(desc,[p],[anchor]);
// Description:
//   Computes the coordinates of the specified point or anchor point in the given description relative to the current transformation state.
// Arguments:
//   desc = Description to use to get the point
//   p = Point or point list to transform.  Default: CENTER (if anchor not given)
//   ---
//   anchor = Anchor point (only one) that you want to extract.  Default: CENTER
// Example(3D): In this example we translate away from the parent object and then compute points on that object.  Note that with OpenSCAD 2021.01 you must use union() or alternatively place the pt1 and pt2 assignments in a let() statement.  This is not necessary in development versions.  
//  cuboid(10) let(desc=parent())
//    right(12) up(27)
//      union(){
//        pt1 = desc_point(desc,anchor=TOP+BACK+LEFT);
//        pt2 = desc_point(desc,anchor=TOP+FWD+RIGHT);
//        stroke([pt1,pt2,CENTER], closed=true, width=.5,color="red");
//      }
// Example(3D): Here we compute the point on the parent so we can draw a line anchored on the child object that connects to a computed point on the parent
//  cuboid(10) let(desc=parent())
//    attach(FWD,BOT) cuboid([3,3,7])
//    attach(TOP+BACK+RIGHT, BOT)
//    stroke([[0,0,0], desc_point(desc,anchor=TOP+FWD+RIGHT)],width=.5,color="red");
function desc_point(desc, p, anchor) =
    is_undef(desc) ?
       assert(is_undef(anchor), "Cannot give anchor withot desc")
       let(
            T = matrix_inverse($transform)
       )
       apply(T, default(p,UP))
  : assert(is_description(desc), "Invalid description")
    assert(num_defined([anchor,p])<2, "Cannot give both anchor and p")
    let (
         T = linear_solve($transform, desc[0]),
         p = is_def(p) ? p
           :  let(anch = _find_anchor(anchor, desc[1]))
              anch[1]
    )
    apply(T, p);


// Function: desc_dir()
// Synopsis: Computes the direction in the current context of a direction or anchor in a description's context
// Topics: Descriptions, Attachment
// See Also: parent(), desc_point()
// Usage:
//   dir = desc_anchor(desc,[dir], [anchor]);
// Description:
//   Computes the direction in the current context of a direction in the context of the description.  You can specify
//   the direction by giving a direction vector, or you can give an anchor that will be interpreted from the description.
//   If you don't give a description then the direction is computed relative to global world coordinates; in this case you
//   cannot give an anchor as the direction.  
// Arguments:
//   desc = Description to use.  Default: use the global world coordinate system
//   dir = Direction or list of directions to use.  Default: UP (if anchor is not given)
//   ---
//   anchor = Anchor (only one) to get the direction from.
// Example(3D): Here we don't give a description so the reference is to the global world coordinate system, and we don't give a direction, so the default of UP applies.  This lets the cylinder be placed so it is horizontal in world coordinates.  
//   prismoid(20,10,h=15)
//     attach(RIGHT,BOT) cuboid([4,4,15])
//     position(TOP) cyl(d=12,h=5,orient=desc_dir(),anchor=BACK);
// Example(3D,VPR=[78.1,0,76.1]): Here we use the description of the prismoid, which lets us place the rod so that it is oriented in the direction of the prismoid's face. 
//   prismoid(20,10,h=15) let(pris=parent())
//      attach(RIGHT,BOT) cuboid([4,4,15])
//      position(TOP) cyl(d=2,h=15,orient=desc_dir(pris,anchor=FWD),anchor=LEFT);
function desc_dir(desc, dir, anchor) =
    is_undef(desc) ?
       assert(is_undef(anchor), "Cannot give anchor without desc")
       let(
            T = matrix_inverse($transform)
       )
       move(-apply(T,CENTER), apply(T, default(dir,UP)))
  :
    assert(is_description(desc), "Invalid description")
    assert(num_defined([dir,anchor])<2, "Cannot give both dir and anchor")
    let(
         T = linear_solve($transform, desc[0]),
         dir = is_def(dir) ? dir
             : let(
                   anch = _find_anchor(anchor, desc[1])
               )
               anch[2]
    )
    move(-apply(T,CENTER),apply(T, dir));

function desc_attach(desc, anchor=UP, p, reverse=false) =
    assert(is_description(desc), "Invalid description")
    let(
         T = linear_solve($transform, desc[0]),
         anch = _find_anchor(anchor,desc[1]),
         centerpoint = apply(T,CENTER),
         pos = apply(T, anch[1]),
         y = apply(T*rot(from=UP,to=anch[2])*zrot(anch[3]),BACK)-centerpoint,
         z = apply(T,anch[2])-centerpoint
    )
    reverse ? frame_map(z=z,y=y,reverse=true, p=move(-pos,p))
            : move(pos,frame_map(z=z,y=y, p=p));


// Function: desc_dist()
// Synopsis: Computes the distance between two points specified by attachable descriptions
// Topics: Descriptions, Attachments
// See Also: parent(), desc_point()
// Usage:
//   dist = desc_dist(desc1,anchor1,desc2,anchor2);
//   dest = desc_dist(desc1=, desc2=, [anchor1=], [anchor2=]);
// Description:
//   Computes the distance between two points specified using attachable descriptions and optional anchor
//   points.  If you omit the anchor point(s) then the computation uses the CENTER anchor.
// Arguments:
//   desc1 = First description
//   anchor1 = Anchor for first description
//   desc2 = Second description
//   anchor2 = Anchor for second description
// Example(3D): Computes the distance between a point on each cube. 
//  cuboid(10) let(desc=parent()) {
//      color("red")attach(TOP+LEFT+FWD) sphere(r=0.75,$fn=12);
//      right(15) cuboid(10) {
//        color("red") attach(TOP+RIGHT+BACK) sphere(r=0.75,$fn=12);
//        echo(desc_dist(parent(),TOP+RIGHT+BACK, desc, TOP+LEFT+FWD));  // Prints 26.9258
//      }
//  }

function desc_dist(desc1,anchor1=CENTER, desc2, anchor2=CENTER)=
   assert(is_description(desc1),"Invalid description: desc1")
   assert(is_description(desc2),"Invalid description: desc2")
   let(
         anch1 = _find_anchor(anchor1, desc1[1]),
         anch2 = _find_anchor(anchor2, desc2[1]),         
         Tinv = matrix_inverse($transform),
         T1 = Tinv*desc1[0],
         T2 = Tinv*desc2[0],
         pt1 = apply(T1,anch1[1]),
         pt2 = apply(T2,anch2[1])
    )
    norm(pt1-pt2);

// Function: transform_desc()
// Synopsis: Applies a transformation matrix to a description
// Topics: Descriptions, Attachments
// See Also: parent()
// Usage:
//   new_desc = transform_desc(T, desc);
// Description:
//   Applies a transformation matrix to a description, producing a new transformed description as
//   output.  The transformation matrix can be produced using any of the usual transform commands.
//   The resulting description is as if it was produced from an object that had the transformation
//   applied.  You can also give a list of transformation matrices, in which case the output is
//   a list of descriptions.  
// Arguments:
//   T = transformation or list of transformations to apply (a 4x4 matrix or list of them)
//   desc = description to transform

function transform_desc(T,desc) =
    assert(is_description(desc), "Invalid description")
    is_consistent(T, ident(4)) ? [for(t=T) [t*desc[0], desc[1]]]
  : is_matrix(T,4,4) ? [T*desc[0], desc[1]]
  : assert(false,"T must be a 4x4 matrix or list of 4x4 matrices");


// Module: desc_copies()
// Synopsis: Places copies according to a list of transformation matrices and supplies descriptions for the copies.
// SynTags: MatList, Trans
// Topics: Transformations, Distributors, Copiers, Descriptions
// See Also: line_copies(), move_copies(), xcopies(), ycopies(), zcopies(), grid_copies(), xflip_copy(), yflip_copy(), zflip_copy(), mirror_copy()
// Usage:
//   desc_copies(transforms) CHILDREN;
// Description:
//   Makes a copy of the children and applies each matrix in the list of transformation matrices.
//   This is equivalent to running `multmatrix()` over all the transformations for the children.
//   This function provides a method for working with descriptions of the whole set of copies by
//   making all of their descriptions available to the children.  This functionality will primarly
//   be useful when the transformation consists only of translations and rotations and hence
//   does not change the size or shape of the children.  If you change the shape of the objects, care
//   is required to ensure that the descriptions match correctly. 
//   .
//   In a child object you obtain its description using {{parent()}} as usual.  Once you have
//   that description you can also access descriptions of the other objects, assuming they have
//   identical geometry.  (The geometry can vary if you make your object conditional on `$idx` for example.)
//   To get the next object use `$next()` and to get the previous one use `$prev()`.  You can also
//   get an arbitrary object description by index using `$desc(i)`.  You can use these descriptions
//   with {{prism_connector()}} to create prisms between the corresponding objects.
//   .
//   Note that in OpenSCAD version 2021.01 you cannot directly call `$next` or the other `$` functions.
//   You have to write `let(next=$next)` and then you can use the `next()` function.  Similar steps
//   are necessary for the other functions.  In development versions you can directly invoke `$next()`
//   and the other functions.  
//   .
//   The descriptions are made available through function literals provided in the `$` variables.  The
//   available functions are
//   * $next([di], [desc]): Returns the description of the next object, or if `di` is given, the object `di` steps forward.  The indexing wraps around.
//   * $prev([di], [desc]): Returns the description of the previous object, or if `di` is given, the object `di` steps before.  The indexing wraps around.
//   * $desc(i, [desc]): Returns a description of the object with index `i`.  Indexing does **not** wrap around.  
//   All of these functions have an optional `desc` parameter, which is the description that will be transformed to produce the next, previous, or indexed
//   description.  By default `desc` is set to {{parent()}}, but you may wish to use a different description if you have objects that vary.
//   .
//   See the last examples in {{prism_connector()}} for examples using this module.  
// Arguments:
//   transforms = list of transformation matrices to apply to the children
// Side Effects:
//   `$count` is set to the number of transformations
//   `$idx` is set to the index number of the current transformation
//   `$is_last` is set to true if this is the last copy and false otherwise
//   `$next()` is set to a function literal that produces the next description (see above)
//   `$prev()` is set to a function literal that produces the previous description (see above)
//   `$desc()` is set to a function literal that produces the description at a specified index (see above)

module desc_copies(transforms)
{
  $count=len(transforms);
  for(i=idx(transforms))
     let(
          $idx=i,
          $is_last = i==len(transforms)-1,
          $desc = function(i,desc) transform_desc(transforms[i]*matrix_inverse(transforms[i]),default(desc,parent())),
          $next = function(di=1,desc) transform_desc(select(transforms,i+di)*matrix_inverse(transforms[i]), default(desc,parent())),
          $prev = function(di=1,desc) transform_desc(select(transforms,i-di)*matrix_inverse(transforms[i]), default(desc,parent()))
     )
     multmatrix(transforms[i])children();
}       

           
// Function: is_description()
// Synopsis: Check if its argument is a descriptioni
// Topics: Descriptions
// Usage:
//   bool = is_description(desc);
// Description:
//   Returns true if the argument appears to be a description.  
// Arguments:
//   desc = argument to check
function is_description(desc) =
  is_list(desc) && len(desc)==2 && is_matrix(desc[0],4,4) && is_list(desc[1]) && is_string(desc[1][0]);




// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
