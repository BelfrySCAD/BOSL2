//////////////////////////////////////////////////////////////////////
// LibFile: attachments.scad
//   The modules in this file allows you to attach one object to another by making one object the child of another object.
//   You can place the child object in relation to its parent object and control the position and orientation
//   relative to the parent.  The modifiers allow you to treat children in different ways that simple union, such
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
$tag_prefix = "";
$overlap = 0;
$color = "default";          
$save_color = undef;         // Saved color to revert back for children

$attach_to = undef;
$attach_anchor = [CENTER, CENTER, UP, 0];
$attach_norot = false;

$parent_anchor = BOTTOM;
$parent_spin = 0;
$parent_orient = UP;

$parent_size = undef;
$parent_geom = undef;

$tags_shown = "ALL";
$tags_hidden = [];

_ANCHOR_TYPES = ["intersect","hull"];


// Section: Terminology and Shortcuts
//   This library adds the concept of anchoring, spin and orientation to the `cube()`, `cylinder()`
//   and `sphere()` builtins, as well as to most of the shapes provided by this library itself.
//   - An anchor is a place on an object which you can align the object to, or attach other objects
//     to using `attach()` or `position()`.  An anchor has a position, a direction, and a spin.
//     The direction and spin are used to orient other objects to match when using `attach()`.
//   - Spin is a simple rotation around the Z axis.
//   - Orientation is rotating an object so that its top is pointed towards a given vector.
//   An object will first be translated to its anchor position, then spun, then oriented.
//   For a detailed step-by-step explanation of attachments, see the [[Attachments Tutorial|Tutorial-Attachments]].
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
// Subsection: Spin
//   Spin is specified with the `spin` argument in most shape modules.  Specifying a scalar `spin`
//   when creating an object will rotate the object counter-clockwise around the Z axis by the given
//   number of degrees.  If given as a 3D vector, the object will be rotated around each of the X, Y, Z
//   axes by the number of degrees in each component of the vector.  Spin is always applied after
//   anchoring, and before orientation.  Since spin is applied after anchoring it is not what
//   you might think of intuitively as spinning the shape.  To do that, apply `zrot()` to the shape before anchoring.  
// Subsection: Orient
//   Orientation is specified with the `orient` argument in most shape modules.  Specifying `orient`
//   when creating an object will rotate the object such that the top of the object will be pointed
//   at the vector direction given in the `orient` argument.  Orientation is always applied after
//   anchoring and spin.  The constants `UP`, `DOWN`, `FRONT`, `BACK`, `LEFT`, and `RIGHT` can be
//   added together to form the directional vector for this.  ie: `LEFT+BACK`
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
// Figure(3D,Big,VPD=310,NoScales):  Next are some examples showing how you can combine edge descriptors to obtain different edge sets.    You can specify the top front edge with a numerical vector or by combining the named direction vectors.  If you combine them as a list you get all the edges around the front or top faces.  Adding `except` removes an edge.  
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



// Section: Attachment Positioning

// Module: position()
// Usage:
//   position(from) CHILDREN;
//
// Topics: Attachments
// See Also: attachable(), attach(), orient()
//
// Description:
//   Attaches children to a parent object at an anchor point.  For a step-by-step explanation
//   of attachments, see the [[Attachments Tutorial|Tutorial-Attachments]].
// Arguments:
//   from = The vector, or name of the parent anchor point to attach to.
// Example:
//   spheroid(d=20) {
//       position(TOP) cyl(l=10, d1=10, d2=5, anchor=BOTTOM);
//       position(RIGHT) cyl(l=10, d1=10, d2=5, anchor=BOTTOM);
//       position(FRONT) cyl(l=10, d1=10, d2=5, anchor=BOTTOM);
//   }
module position(from)
{
    req_children($children);
    assert($parent_geom != undef, "No object to attach to!");
    anchors = (is_vector(from)||is_string(from))? [from] : from;
    for (anchr = anchors) {
        anch = _find_anchor(anchr, $parent_geom);
        $attach_to = undef;
        $attach_anchor = anch;
        $attach_norot = true;
        translate(anch[1]) children();
    }
}


// Module: orient()
// Usage:
//   orient(dir, [spin=]) CHILDREN;
//   orient(anchor=, [spin=]) CHILDREN;
// Topics: Attachments
// Description:
//   Orients children such that their top is tilted towards the given direction, or towards the
//   direction of a given anchor point on the parent.  For a step-by-step explanation of
//   attachments, see the [[Attachments Tutorial|Tutorial-Attachments]].
// Arguments:
//   dir = The direction to orient towards.
//   ---
//   anchor = The anchor on the parent which you want to match the orientation of.  Use instead of `dir`.
//   spin = The spin to add to the children.  (Overrides anchor spin.)
// See Also: attachable(), attach(), orient()
// Example: Orienting by Vector
//   prismoid([50,50],[30,30],h=40) {
//       position(TOP+RIGHT)
//           orient(RIGHT)
//               prismoid([30,30],[0,5],h=20,anchor=BOT+LEFT);
//   }
// Example: When orienting to an anchor, the spin of the anchor may cause confusion:
//   prismoid([50,50],[30,30],h=40) {
//       position(TOP+RIGHT)
//           orient(anchor=RIGHT)
//               prismoid([30,30],[0,5],h=20,anchor=BOT+LEFT);
//   }
// Example: You can override anchor spin with `spin=`.
//   prismoid([50,50],[30,30],h=40) {
//       position(TOP+RIGHT)
//           orient(anchor=RIGHT,spin=0)
//               prismoid([30,30],[0,5],h=20,anchor=BOT+LEFT);
//   }
// Example: Or you can anchor the child from the back
//   prismoid([50,50],[30,30],h=40) {
//       position(TOP+RIGHT)
//           orient(anchor=RIGHT)
//               prismoid([30,30],[0,5],h=20,anchor=BOT+BACK);
//   }
module orient(dir, anchor, spin) {
    req_children($children);
    if (!is_undef(dir)) {
        assert(anchor==undef, "Only one of dir= or anchor= may be given to orient()");
        assert(is_vector(dir));
        spin = default(spin, 0);
        assert(is_finite(spin));
        two_d = _attach_geom_2d($parent_geom);
        fromvec = two_d? BACK : UP;
        rot(spin, from=fromvec, to=dir) children();
    } else {
        assert(dir==undef, "Only one of dir= or anchor= may be given to orient()");
        assert($parent_geom != undef, "No parent to orient from!");
        assert(is_string(anchor) || is_vector(anchor));
        anch = _find_anchor(anchor, $parent_geom);
        two_d = _attach_geom_2d($parent_geom);
        fromvec = two_d? BACK : UP;
        $attach_to = undef;
        $attach_anchor = anch;
        $attach_norot = true;
        spin = default(spin, anch[3]);
        assert(is_finite(spin));
        rot(spin, from=fromvec, to=anch[2]) children();
    }
}



// Module: attach()
// Usage:
//   attach(from, [overlap=], [norot=]) CHILDREN;
//   attach(from, to, [overlap=], [norot=]) CHILDREN;
// Topics: Attachments
// See Also: attachable(), position(), face_profile(), edge_profile(), corner_profile()
// Description:
//   Attaches children to a parent object at an anchor point and orientation.  Attached objects will
//   be overlapped into the parent object by a little bit, as specified by the `$overlap`
//   value (0 by default), or by the overriding `overlap=` argument.  This is to prevent OpenSCAD
//   from making non-manifold objects.  You can define `$overlap=` as an argument in a parent
//   module to set the default for all attachments to it.  For a step-by-step explanation of
//   attachments, see the [[Attachments Tutorial|Tutorial-Attachments]].
// Arguments:
//   from = The vector, or name of the parent anchor point to attach to.
//   to = Optional name of the child anchor point.  If given, orients the child such that the named anchors align together rotationally.
//   ---
//   overlap = Amount to sink child into the parent.  Equivalent to `down(X)` after the attach.  This defaults to the value in `$overlap`, which is `0` by default.
//   norot = If true, don't rotate children when attaching to the anchor point.  Only translate to the anchor point.
// Example:
//   spheroid(d=20) {
//       attach(TOP) down(1.5) cyl(l=11.5, d1=10, d2=5, anchor=BOTTOM);
//       attach(RIGHT, BOTTOM) down(1.5) cyl(l=11.5, d1=10, d2=5);
//       attach(FRONT, BOTTOM, overlap=1.5) cyl(l=11.5, d1=10, d2=5);
//   }
module attach(from, to, overlap, norot=false)
{
    req_children($children);
    assert($parent_geom != undef, "No object to attach to!");
    overlap = (overlap!=undef)? overlap : $overlap;
    anchors = (is_vector(from)||is_string(from))? [from] : from;
    for (anchr = anchors) {
        anch = _find_anchor(anchr, $parent_geom);
        two_d = _attach_geom_2d($parent_geom);
        $attach_to = to;
        $attach_anchor = anch;
        $attach_norot = norot;
        olap = two_d? [0,-overlap,0] : [0,0,-overlap];
        if (norot || (norm(anch[2]-UP)<1e-9 && anch[3]==0)) {
            translate(anch[1]) translate(olap) children();
        } else {
            fromvec = two_d? BACK : UP;
            translate(anch[1]) rot(anch[3],from=fromvec,to=anch[2]) translate(olap) children();
        }
    }
}

// Section: Attachment Modifiers

// Module: tag()
// Usage:
//   tag(tag) CHILDREN;
// Topics: Attachments
// See Also: force_tag(), recolor(), hide(), show_only(), diff(), intersect()
// Description:
//   Assigns the specified tag to all of the children. Note that if you want
//   to apply a tag to non-tag-aware objects you need to use {{force_tag()}} instead.
//   This works by setting the `$tag` variable, but it provides extra error checking and
//   handling of scopes.  You may set `$tag` directly yourself, but this is not recommended. 
//   .
//   For a step-by-step explanation of attachments, see the [[Attachments Tutorial|Tutorial-Attachments]].
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
    assert(is_string(tag),"tag must be a string");
    assert(undef==str_find($tag," "),str("Tag string \"",$tag,"\" contains a space, which is not allowed"))    ;
    $tag = str($tag_prefix,tag);
    children();
}


// Module: force_tag()
// Usage:
//   force_tag([tag]) CHILDREN;
// Topics: Attachments
// See Also: tag(), recolor(), hide(), show_only(), diff(), intersect()
// Description:
//   You use this module when you want to make a non-attachable or non-BOSL2 module respect tags.
//   It applies to its children the tag specified (or the tag currently in force if you don't specify a tag),
//   making a final determination about whether to show or hide the children.
//   This means that tagging in children's children will be ignored.
//   This module is specifically provided for operating on children that are not tag aware such as modules
//   that don't use {{attachable()}} or built in modules such as 
//   - `polygon()`
//   - `projection()`
//   - `polyhedron()`  (or use [`vnf_polyhedron()`](vnf.scad#vnf_polyhedron))
//   - `linear_extrude()`  (or use [`linear_sweep()`](regions.scad#linear_sweep))
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
//   For a step-by-step explanation of attachments, see the [[Attachments Tutorial|Tutorial-Attachments]].
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
    assert(is_undef(tag) || is_string(tag),"tag must be a string");
    $tag = str($tag_prefix,default(tag,$tag));
    assert(undef==str_find($tag," "),str("Tag string \"",$tag,"\" contains a space, which is not allowed"));
    if(_is_shown())
      show_all()
        children();
}



// Module: default_tag()
// Usage:
//   default_tag(tag) CHILDREN;
// Topics: Attachments
// See Also: force_tag(), recolor(), hide(), show_only(), diff(), intersect()
// Description:
//   Sets a default tag for all of the children.  This is intended to be used to set a tag for a whole module
//   that is then used outside the module, such as setting the tag to "remove" for easy operation with {{diff()}}.
//   The default_tag() module sets the `$tag` variable only if it is not already
//   set so you can have a module set a default tag of "remove" but that tag can be overridden by a {{tag()}}
//   in force from a parent.  If you use {{tag()}} it will override any previously
//   specified tag from a parent, which can be very confusing to a user trying to change the tag on a module.  
//   .
//   For a step-by-step explanation of attachments, see the [[Attachments Tutorial|Tutorial-Attachments]].
// Arguments:
//   tag = tag string, which must not contain any spaces.
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
module default_tag(tag)
{
    if ($tag=="") tag(tag) children();
    else children();
}


// Module: tag_scope()
// Usage:
//   tag_scope([scope]) CHILDREN;
// Description:
//   Creates a tag scope with locally altered tag names to avoid tag name conflict with other code.
//   This is necessary when writing modules because the module's caller might happen to use the same tags.
//   Note that if you directly set the `$tag` variable then tag scoping will not work correctly.  
// Example: In this example the ring module uses "remove" tags which will conflict with use of the same tags by the parent.  
//   module ring(r,h,w=1,anchor,spin,orient)
//   {
//     tag_scope("ringscope")
//       attachable(anchor,spin,orient,r=r,h=h){
//         diff()
//           cyl(r=r,h=h)
//             tag("remove") cyl(r=r-w,h=h+1);
//         children();
//       }
//   }
//   // Calling the module using "remove" tags
//   // will conflict with internal tag use in
//   // the ring module.
//   $fn=32;
//   diff(){
//       ring(10,7,w=4);
//       tag("remove")ring(8,8);
//       tag("remove")diff("rem"){
//          ring(9.5,8,w=1);
//          tag("rem")ring(9.5,8,w=.3);
//       }
//     }
module tag_scope(scope){
  req_children($children);
  scope = is_undef(scope) ? rand_str(20) : scope;
  assert(is_string(scope), "scope must be a string");
  $tag_prefix=scope;
  children();
}  


// Module: diff()
// Usage:
//   diff([remove], [keep]) CHILDREN;
// Topics: Attachments
// See Also: tag(), force_tag(), recolor(), show_only(), hide(), tag_diff(), intersect(), tag_intersect()
// Description:
//   Perform a differencing operation using tags to control what happens.  This is specifically intended to
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
//   For a step-by-step explanation of attachments, see the [[Attachments Tutorial|Tutorial-Attachments]].
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
//       // Leave the tag along here, so this one is removed
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
//     // "keep" prevents interior of the blue bar intact
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
// Example: Here is another example where two children are intersected using the native intersection operator, and then tagged with {{force_tag()}}.  Note that because the children are at the save level, you don't need to use a tagged operator for their intersection.  
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
// Usage:
//   tag_diff(tag, [remove], [keep]) CHILDREN;
// Topics: Attachments
// See Also: tag(), force_tag(), recolor(), show_only(), hide(), diff(), intersect(), tag_intersect()
// Description:
//   Perform a differencing operation in the manner of {{diff()}} using tags to control what happens,
//   and then tag the resulting difference object with the specified tag.  This forces the specified
//   tag to be resolved at the level of the difference operation.  In most cases, this is not necessary,
//   but if you have kept objects and want to operate on this difference object as a whole object using
//   more tag operations, you will probably not get the results you want if you simply use {{tag()}}.  
//   . 
//   For a step-by-step explanation of attachments, see the [[Attachments Tutorial|Tutorial-Attachments]].
// Arguments:
//   tag = Tag string to apply to this difference object
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
// 
module tag_diff(tag,remove="remove", keep="keep")
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
// Usage:
//   intersect([intersect], [keep]) CHILDREN;
// Topics: Attachments
// See Also: tag(), force_tag(), recolor(), show_only(), hide(), diff(), tag_diff(), tag_intersect()
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
//   For a step-by-step explanation of attachments, see the [[Attachments Tutorial|Tutorial-Attachments]].
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
// Usage:
//   tag_intersect(tag, [intersect], [keep]) CHILDREN;
// Topics: Attachments
// See Also: tag(), force_tag(), recolor(), show_only(), hide(), diff(), tag_diff(), intersect()
// Description:
//   Perform an intersection operation in the manner of {{intersect()}} using tags to control what happens,
//   and then tag the resulting difference object with the specified tag.  This forces the specified
//   tag to be resolved at the level of the intersect operation.  In most cases, this is not necessary,
//   but if you have kept objects and want to operate on this difference object as a whole object using
//   more tag operations, you will probably not get the results you want if you simply use {{tag()}}.  
//   .
//   For a step-by-step explanation of attachments, see the [[Attachments Tutorial|Tutorial-Attachments]].
// Arguments:
//   tag = Tag to set for the intersection
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
module tag_intersect(tag,intersect="intersect",keep="keep")
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
// Usage:
//   conv_hull([keep]) CHILDREN;
// Topics: Attachments
// See Also: tag(), recolor(), show_only(), hide(), diff(), intersect()
// Description:
//   Performs a hull operation on the children using tags to determine what happens.  The items
//   not tagged with the `keep` tags are combined into a convex hull, and the children tagged with the keep tags
//   are unioned with the result.  
//   .
//   For a step-by-step explanation of attachments, see the [[Attachments Tutorial|Tutorial-Attachments]].
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
// Usage:
//   tag,conv_hull(tag, [keep]) CHILDREN;
// Topics: Attachments
// See Also: tag(), recolor(), show_only(), hide(), diff(), intersect()
// Description:
//   Perform a convex hull operation in the manner of {{conv_hull()}} using tags to control what happens,
//   and then tag the resulting hull object with the specified tag.  This forces the specified
//   tag to be resolved at the level of the hull operation.  In most cases, this is not necessary,
//   but if you have kept objects and want to operate on the hull object as a whole object using
//   more tag operations, you will probably not get the results you want if you simply use {{tag()}}.  
//   .
//   For a step-by-step explanation of attachments, see the [[Attachments Tutorial|Tutorial-Attachments]].
// Arguments:
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
module tag_conv_hull(tag,keep="keep")
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
// Usage:
//   hide(tags) CHILDREN;
// Topics: Attachments
// See Also: tag(), recolor(), show_only(), diff(), intersect()
// Description:
//   Hides all attachable children with the given tags, which you supply as a space separated string. Previously hidden objects remain hidden, so hiding is cumulative, unlike `show_only()`.  
//   For a step-by-step explanation of attachments, see the [[Attachments Tutorial|Tutorial-Attachments]].
// Side Effects:
//   Sets `$tags_hidden` to include the tags you specify. 
// Example:  Hides part of the model.  
//   hide("A")
//     tag("main") cube(50, anchor=CENTER, $tag="Main") {
//       tag("A")attach(LEFT, BOTTOM) cylinder(d=30, l=30);
//       tag("B")attach(RIGHT, BOTTOM) cylinder(d=30, l=30);
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
    assert(is_string(tags), "tags must be a string");
    taglist = [for(s=str_split(tags," ",keep_nulls=false)) str($tag_prefix,s)];
    $tags_hidden = concat($tags_hidden,taglist);
    children();
}


// Module: show_only()
// Usage:
//   show_only(tags) CHILDREN;
// Topics: Attachments
// See Also: tag(), recolor(), hide(), diff(), intersect()
// Description:
//   Show only the children with the listed tags, which you sply as a space separated string.  Only unhidden objects will be shown, so if an object is hidden either before or after the `show_only()` call then it will remain hidden.  This overrides any previous `show_only()` calls.  Unlike `hide()`, calls to `show_only()` are not cumulative.  
//   For a step-by-step explanation of attachments, see the [[Attachments Tutorial|Tutorial-Attachments]].
// Side Effects:
//   Sets `$tags_shown` to the tag you specify. 
// Example:  Display the attachments but not the parent
//   show_only("visible")
//     cube(50, anchor=CENTER) 
//       tag("visible"){
//         attach(LEFT, BOTTOM) cylinder(d=30, l=30);
//         attach(RIGHT, BOTTOM) cylinder(d=30, l=30);
//       }
module show_only(tags)
{
    req_children($children);
    assert(is_string(tags), str("tags must be a string",tags));
    taglist = [for(s=str_split(tags," ",keep_nulls=false)) str($tag_prefix,s)];
    $tags_shown = taglist;    
    children();
}

// Module: show_all()
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
    assert(is_string(tags), str("tags must be a string",tags));
    taglist = [for(s=str_split(tags," ",keep_nulls=false)) str($tag_prefix,s)];
    $tags_shown = $tags_shown == "ALL" ? taglist : set_intersection($tags_shown,taglist);
    children();
}


// Section: Attachable Masks


// Module: edge_mask()
// Usage:
//   edge_mask([edges], [except]) CHILDREN;
// Topics: Attachments
// See Also: attachable(), position(), attach(), face_profile(), edge_profile(), corner_mask()
// Description:
//   Takes a 3D mask shape, and attaches it to the given edges, with the appropriate orientation to be
//   differenced away.  The mask shape should be vertically oriented (Z-aligned) with the back-right
//   quadrant (X+Y+) shaped to be diffed away from the edge of parent attachable shape.  If no tag is set
//   then `edge_mask` sets the tag for children to "remove" so that it will work with the default {{diff()}} tag.  
//   For details on specifying the edges to mask see [Specifying Edges](attachments.scad#subsection-specifying-edges).
//   For a step-by-step explanation of attachments, see the [[Attachments Tutorial|Tutorial-Attachments]].
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
    for (vec = vecs) {
        vcount = (vec.x?1:0) + (vec.y?1:0) + (vec.z?1:0);
        assert(vcount == 2, "Not an edge vector!");
        anch = _find_anchor(vec, $parent_geom);
        $attach_to = undef;
        $attach_anchor = anch;
        $attach_norot = true;
        rotang =
            vec.z<0? [90,0,180+v_theta(vec)] :
            vec.z==0 && sign(vec.x)==sign(vec.y)? 135+v_theta(vec) :
            vec.z==0 && sign(vec.x)!=sign(vec.y)? [0,180,45+v_theta(vec)] :
            [-90,0,180+v_theta(vec)];
        translate(anch[1]) rot(rotang)
           if ($tag=="") tag("remove") children();
           else children();
    }
}


// Module: corner_mask()
// Usage:
//   corner_mask([corners], [except]) CHILDREN;
// Topics: Attachments
// See Also: attachable(), position(), attach(), face_profile(), edge_profile(), edge_mask()
// Description:
//   Takes a 3D mask shape, and attaches it to the specified corners, with the appropriate orientation to
//   be differenced away.  The 3D corner mask shape should be designed to mask away the X+Y+Z+ octant.  If no tag is set
//   then `corner_mask` sets the tag for children to "remove" so that it will work with the default {{diff()}} tag.  
//   See [Specifying Corners](attachments.scad#subsection-specifying-corners) for information on how to specify corner sets.  
//   For a step-by-step explanation of attachments, see the [[Attachments Tutorial|Tutorial-Attachments]].
// Arguments:
//   corners = Corners to mask.  See [Specifying Corners](attachments.scad#subsection-specifying-corners).  Default: All corners.
//   except = Corners to explicitly NOT mask.  See [Specifying Corners](attachments.scad#subsection-specifying-corners).  Default: No corners.
// Side Effects:
//   Tags the children with "remove" (and hence sets `$tag`) if no tag is already set. 
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
    for (vec = vecs) {
        vcount = (vec.x?1:0) + (vec.y?1:0) + (vec.z?1:0);
        assert(vcount == 3, "Not an edge vector!");
        anch = _find_anchor(vec, $parent_geom);
        $attach_to = undef;
        $attach_anchor = anch;
        $attach_norot = true;
        rotang = vec.z<0?
            [  0,0,180+v_theta(vec)-45] :
            [180,0,-90+v_theta(vec)-45];
        translate(anch[1]) rot(rotang)
           if ($tag=="") tag("remove") children();
           else children();
    }
}


// Module: face_profile()
// Usage:
//   face_profile(faces, r|d=, [convexity=]) CHILDREN;
// Topics: Attachments
// See Also: attachable(), position(), attach(), edge_profile(), corner_profile()
// Description:
//   Given a 2D edge profile, extrudes it into a mask for all edges and corners bounding each given face. If no tag is set
//   then `face_profile` sets the tag for children to "remove" so that it will work with the default {{diff()}} tag.  
//   See  [Specifying Faces](attachments.scad#subsection-specifying-faces) for information on specifying faces.  
//   For a step-by-step explanation of attachments, see the [[Attachments Tutorial|Tutorial-Attachments]].
// Arguments:
//   faces = Faces to mask edges and corners of.
//   r = Radius of corner mask.
//   ---
//   d = Diameter of corner mask.
//   convexity = Max number of times a line could intersect the perimeter of the mask shape.  Default: 10
// Side Effects:
//   Tags the children with "remove" (and hence sets `$tag`) if no tag is already set. 
// Example:
//   diff()
//   cube([50,60,70],center=true)
//       face_profile(TOP,r=10)
//           mask2d_roundover(r=10);
module face_profile(faces=[], r, d, convexity=10) {
    req_children($children);
    faces = is_vector(faces)? [faces] : faces;
    assert(all([for (face=faces) is_vector(face) && sum([for (x=face) x!=0? 1 : 0])==1]), "Vector in faces doesn't point at a face.");
    r = get_radius(r=r, d=d, dflt=undef);
    assert(is_num(r) && r>0);
    edge_profile(faces) children();
    corner_profile(faces, convexity=convexity, r=r) children();
}


// Module: edge_profile()
// Usage:
//   edge_profile([edges], [except], [convexity]) CHILDREN;
// Topics: Attachments
// See Also: attachable(), position(), attach(), face_profile(), corner_profile()
// Description:
//   Takes a 2D mask shape and attaches it to the selected edges, with the appropriate orientation and
//   extruded length to be `diff()`ed away, to give the edge a matching profile.  If no tag is set
//   then `edge_profile` sets the tag for children to "remove" so that it will work with the default {{diff()}} tag.  
//   For details on specifying the edges to mask see [Specifying Edges](attachments.scad#subsection-specifying-edges).
//   For a step-by-step
//   explanation of attachments, see the [[Attachments Tutorial|Tutorial-Attachments]].
// Arguments:
//   edges = Edges to mask.  See [Specifying Edges](attachments.scad#subsection-specifying-edges).  Default: All edges.
//   except = Edges to explicitly NOT mask.  See [Specifying Edges](attachments.scad#subsection-specifying-edges).  Default: No edges.
//   convexity = Max number of times a line could intersect the perimeter of the mask shape.  Default: 10
// Side Effects:
//   Tags the children with "remove" (and hence sets `$tag`) if no tag is already set. 
// Example:
//   diff()
//   cube([50,60,70],center=true)
//       edge_profile([TOP,"Z"],except=[BACK,TOP+LEFT])
//           mask2d_roundover(r=10, inset=2);
module edge_profile(edges=EDGES_ALL, except=[], convexity=10) {
    req_children($children);
    assert($parent_geom != undef, "No object to attach to!");
    edges = _edges(edges, except=except);
    vecs = [
        for (i = [0:3], axis=[0:2])
        if (edges[axis][i]>0)
        EDGE_OFFSETS[axis][i]
    ];
    for (vec = vecs) {
        vcount = (vec.x?1:0) + (vec.y?1:0) + (vec.z?1:0);
        assert(vcount == 2, "Not an edge vector!");
        anch = _find_anchor(vec, $parent_geom);
        $attach_to = undef;
        $attach_anchor = anch;
        $attach_norot = true;
        psize = point3d($parent_size);
        length = [for (i=[0:2]) if(!vec[i]) psize[i]][0]+0.1;
        rotang =
            vec.z<0? [90,0,180+v_theta(vec)] :
            vec.z==0 && sign(vec.x)==sign(vec.y)? 135+v_theta(vec) :
            vec.z==0 && sign(vec.x)!=sign(vec.y)? [0,180,45+v_theta(vec)] :
            [-90,0,180+v_theta(vec)];
        translate(anch[1]) {
            rot(rotang) {
                linear_extrude(height=length, center=true, convexity=convexity) {
                   if ($tag=="") tag("remove") children();
                   else children();
                }
            }
        }
    }
}

// Module: corner_profile()
// Usage:
//   corner_profile([corners], [except], [r=|d=], [convexity=]) CHILDREN;
// Topics: Attachments
// See Also: attachable(), position(), attach(), face_profile(), edge_profile()
// Description:
//   Takes a 2D mask shape, rotationally extrudes and converts it into a corner mask, and attaches it
//   to the selected corners with the appropriate orientation. If no tag is set
//   then `corner_profile` sets the tag for children to "remove" so that it will work with the default {{diff()}} tag.  
//   See [Specifying Corners](attachments.scad#subsection-specifying-corners) for information on how to specify corner sets.  
//   For a step-by-step explanation of attachments, see the [[Attachments Tutorial|Tutorial-Attachments]].
// Arguments:
//   corners = Corners to mask.  See [Specifying Corners](attachments.scad#subsection-specifying-corners).  Default: All corners.
//   except = Corners to explicitly NOT mask.  See [Specifying Corners](attachments.scad#subsection-specifying-corners).  Default: No corners.
//   ---
//   r = Radius of corner mask.
//   d = Diameter of corner mask.
//   convexity = Max number of times a line could intersect the perimeter of the mask shape.  Default: 10
// Side Effects:
//   Tags the children with "remove" (and hence sets $tag) if no tag is already set. 
// Example:
//   diff()
//   cuboid([50,60,70],rounding=10,edges="Z",anchor=CENTER) {
//       corner_profile(TOP,r=10)
//           mask2d_teardrop(r=10, angle=40);
//   }
module corner_profile(corners=CORNERS_ALL, except=[], r, d, convexity=10) {
    assert($parent_geom != undef, "No object to attach to!");
    r = get_radius(r=r, d=d, dflt=undef);
    assert(is_num(r));
    corners = _corners(corners, except=except);
    vecs = [for (i = [0:7]) if (corners[i]>0) CORNER_OFFSETS[i]];
    for (vec = vecs) {
        vcount = (vec.x?1:0) + (vec.y?1:0) + (vec.z?1:0);
        assert(vcount == 3, "Not an edge vector!");
        anch = _find_anchor(vec, $parent_geom);
        $attach_to = undef;
        $attach_anchor = anch;
        $attach_norot = true;
        rotang = vec.z<0?
            [  0,0,180+v_theta(vec)-45] :
            [180,0,-90+v_theta(vec)-45];
        $tag = $tag=="" ? str($tag_prefix,"remove") : $tag;
        translate(anch[1]) {
            rot(rotang) {
                render(convexity=convexity)
                difference() {
                    translate(-0.1*[1,1,1]) cube(r+0.1, center=false);
                    right(r) back(r) zrot(180) {
                        rotate_extrude(angle=90, convexity=convexity) {
                            xflip() left(r) {
                                difference() {
                                    square(r,center=false);
                                    children();
                                }
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
//
// Usage: Square/Trapezoid Geometry
//   attachable(anchor, spin, two_d=true, size=, [size2=], [shift=], ...) {OBJECT; children();}
// Usage: Circle/Oval Geometry
//   attachable(anchor, spin, two_d=true, r=|d=, ...) {OBJECT; children();}
// Usage: 2D Path/Polygon Geometry
//   attachable(anchor, spin, two_d=true, path=, [extent=], ...) {OBJECT; children();}
// Usage: 2D Region Geometry
//   attachable(anchor, spin, two_d=true, region=, [extent=], ...) {OBJECT; children();}
// Usage: Cubical/Prismoidal Geometry
//   attachable(anchor, spin, [orient], size=, [size2=], [shift=], ...) {OBJECT; children();}
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
// Topics: Attachments
// See Also: reorient()
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
//   * Translates this part so it's anchor position matches the parent's anchor position.
//   * Rotates this part so it's anchor direction vector exactly opposes the parent's anchor direction vector.
//   * Rotates this part so it's anchor spin matches the parent's anchor spin.
//   .
//   For a step-by-step explanation of attachments, see the [[Attachments Tutorial|Tutorial-Attachments]].
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
//   geom = If given, uses the pre-defined (via {{attach_geom()}} geometry.
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
    axis=UP,
    geom
) {
    dummy1 =
        assert($children==2, "attachable() expects exactly two children; the shape to manage, and the union of all attachment candidates.")
        assert(is_undef(anchor) || is_vector(anchor) || is_string(anchor), str("Got: ",anchor))
        assert(is_undef(spin)   || is_vector(spin,3) || is_num(spin), str("Got: ",spin))
        assert(is_undef(orient) || is_vector(orient,3), str("Got: ",orient));
    anchor = default(anchor, CENTER);
    spin =   default(spin,   0);
    orient = default(orient, UP);
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
            two_d=two_d, axis=axis
        );
    m = _attach_transform(anchor,spin,orient,geom);
    multmatrix(m) {
        $parent_anchor = anchor;
        $parent_spin   = spin;
        $parent_orient = orient;
        $parent_geom   = geom;
        $parent_size   = _attach_geom_size(geom);
        $attach_to   = undef;
        if (_is_shown())
            _color($color) children(0);
        if (is_def($save_color)) {
            $color=$save_color;
            $save_color=undef;
            children(1);
        }
        else children(1);
    }
}

// Function: reorient()
//
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
//   pts = reorient(anchor, spin, [orient], size=, [size2=], [shift=], p=, ...);
// Usage: Cylindrical Geometry
//   mat = reorient(anchor, spin, [orient], r=|d=, l=, [axis=], ...);
//   pts = reorient(anchor, spin, [orient], r=|d=, l=, [axis=], p=, ...);
// Usage: Conical Geometry
//   mat = reorient(anchor, spin, [orient], r1=|d1=, r2=|d2=, l=, [axis=], ...);
//   pts = reorient(anchor, spin, [orient], r1=|d1=, r2=|d2=, l=, [axis=], p=, ...);
// Usage: Spheroid/Ovoid Geometry
//   mat = reorient(anchor, spin, [orient], r|d=, ...);
//   pts = reorient(anchor, spin, [orient], r|d=, p=, ...);
// Usage: Extruded Path/Polygon Geometry
//   mat = reorient(anchor, spin, [orient], path=, l=|h=, [extent=], ...);
//   pts = reorient(anchor, spin, [orient], path=, l=|h=, [extent=], p=, ...);
// Usage: Extruded Region Geometry
//   mat = reorient(anchor, spin, [orient], region=, l=|h=, [extent=], ...);
//   pts = reorient(anchor, spin, [orient], region=, l=|h=, [extent=], p=, ...);
// Usage: VNF Geometry
//   mat = reorient(anchor, spin, [orient], vnf, [extent], ...);
//   pts = reorient(anchor, spin, [orient], vnf, [extent], p=, ...);
//
// Topics: Attachments
// See Also: reorient(), attachable()
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
//   * Translates this part so it's anchor position matches the parent's anchor position.
//   * Rotates this part so it's anchor direction vector exactly opposes the parent's anchor direction vector.
//   * Rotates this part so it's anchor spin matches the parent's anchor spin.
//   .
//   For a step-by-step explanation of attachments, see the [[Attachments Tutorial|Tutorial-Attachments]].
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
    axis=UP,
    geom,
    p=undef
) = 
    assert(is_undef(anchor) || is_vector(anchor) || is_string(anchor), str("Got: ",anchor))
    assert(is_undef(spin)   || is_vector(spin,3) || is_num(spin), str("Got: ",spin))
    assert(is_undef(orient) || is_vector(orient,3), str("Got: ",orient))
    let(
        anchor = default(anchor, CENTER),
        spin =   default(spin,   0),
        orient = default(orient, UP),
        region = !is_undef(region)? region :
            !is_undef(path)? [path] :
            undef
    )
    (anchor==CENTER && spin==0 && orient==UP && p!=undef)? p :
    let(
        geom = is_def(geom)? geom :
            attach_geom(
                size=size, size2=size2, shift=shift,
                r=r, r1=r1, r2=r2, h=h,
                d=d, d1=d1, d2=d2, l=l,
                vnf=vnf, region=region, extent=extent,
                cp=cp, offset=offset, anchors=anchors,
                two_d=two_d, axis=axis
            ),
        $attach_to = undef
    ) _attach_transform(anchor,spin,orient,geom,p);


// Function: named_anchor()
// Usage:
//   a = named_anchor(name, pos, [orient], [spin]);
// Topics: Attachments
// See Also: reorient(), attachable()
// Description:
//   Creates an anchor data structure.  For a step-by-step explanation of attachments,
//   see the [[Attachments Tutorial|Tutorial-Attachments]].
// Arguments:
//   name = The string name of the anchor.  Lowercase.  Words separated by single dashes.  No spaces.
//   pos = The [X,Y,Z] position of the anchor.
//   orient = A vector pointing in the direction parts should project from the anchor position.  Default: UP
//   spin = If needed, the angle to rotate the part around the direction vector.  Default: 0
function named_anchor(name, pos, orient=UP, spin=0) = [name, pos, orient, spin];


// Function: attach_geom()
//
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
// Topics: Attachments
// See Also: reorient(), attachable()
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
//   geom = attach_geom(two_d=true, size=[x1,y], size2=x2, shift=shift);
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
    axis=UP
) =
    assert(is_bool(extent))
    assert(is_vector(cp) || is_string(cp))
    assert(is_vector(offset))
    assert(is_list(anchors))
    assert(is_bool(two_d))
    assert(is_vector(axis))
    !is_undef(size)? (
        two_d? (
            let(
                size2 = default(size2, size.x),
                shift = default(shift, 0)
            )
            assert(is_vector(size,2))
            assert(is_num(size2))
            assert(is_num(shift))
            ["trapezoid", point2d(size), size2, shift, cp, offset, anchors]
        ) : (
            let(
                size2 = default(size2, point2d(size)),
                shift = default(shift, [0,0])
            )
            assert(is_vector(size,3))
            assert(is_vector(size2,2))
            assert(is_vector(shift,2))
            ["prismoid", size, size2, shift, axis, cp, offset, anchors]
        )
    ) : !is_undef(vnf)? (
        assert(is_vnf(vnf))
        assert(two_d == false)
        extent? ["vnf_extent", vnf, cp, offset, anchors] :
        ["vnf_isect", vnf, cp, offset, anchors]
    ) : !is_undef(region)? (
        assert(is_region(region),2)
        let( l = default(l, h) )
        two_d==true
          ? assert(is_undef(l))
            extent==true
              ? ["rgn_extent", region, cp, offset, anchors]
              : ["rgn_isect",  region, cp, offset, anchors]
          : assert(is_finite(l))
            let(
                shift = default(shift, [0,0]),
                scale = is_num(scale)? [scale,scale] : default(scale, [1,1]),
                twist = default(twist, 0)
            )
            assert(is_vector(shift,2))
            assert(is_vector(scale,2))
            assert(is_num(twist))
            extent==true
              ? ["xrgn_extent", region, l, twist, scale, shift, cp, offset, anchors]
              : ["xrgn_isect",  region, l, twist, scale, shift, cp, offset, anchors]
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
    assert(false, "Unrecognizable geometry description.");






//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Attachment internal functions


/// Internal Function: _attach_geom_2d()
// Usage:
//   bool = _attach_geom_2d(geom);
/// Topics: Attachments
/// See Also: reorient(), attachable()
// Description:
//   Returns true if the given attachment geometry description is for a 2D shape.
function _attach_geom_2d(geom) =
    let( type = geom[0] )
    type == "trapezoid" || type == "ellipse" ||
    type == "rgn_isect" || type == "rgn_extent";


/// Internal Function: _attach_geom_size()
// Usage:
//   bounds = _attach_geom_size(geom);
/// Topics: Attachments
/// See Also: reorient(), attachable()
// Description:
//   Returns the `[X,Y,Z]` bounding size for the given attachment geometry description.
function _attach_geom_size(geom) =
    let( type = geom[0] )
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
    ) : type == "xrgn_isect" || type == "xrgn_extent"? ( //path, l
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


/// Internal Function: _attach_transform()
// Usage: To Get a Transformation Matrix
//   mat = _attach_transform(anchor, spin, orient, geom);
// Usage: To Transform Points, Paths, Patches, or VNFs
//   new_p = _attach_transform(anchor, spin, orient, geom, p);
/// Topics: Attachments
/// See Also: reorient(), attachable()
// Description:
//   Returns the affine3d transformation matrix needed to `anchor`, `spin`, and `orient`
//   the given geometry `geom` shape into position.
// Arguments:
//   anchor = Anchor point to translate to the origin `[0,0,0]`.  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = Vector to rotate top towards, after spin.  See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   geom = The geometry description of the shape.
//   p = If given as a VNF, path, or point, applies the affine3d transformation matrix to it and returns the result.
function _attach_transform(anchor, spin, orient, geom, p) =
    assert(is_undef(anchor) || is_vector(anchor) || is_string(anchor), str("Got: ",anchor))
    assert(is_undef(spin)   || is_vector(spin,3) || is_num(spin), str("Got: ",spin))
    assert(is_undef(orient) || is_vector(orient,3), str("Got: ",orient))
    let(
        anchor = default(anchor, CENTER),
        spin   = default(spin,   0),
        orient = default(orient, UP),
        two_d = _attach_geom_2d(geom),
        m = ($attach_to != undef)? (
            let(
                anch = _find_anchor($attach_to, geom),
                pos = anch[1]
            ) two_d? (
                assert(two_d && is_num(spin))
                affine3d_zrot(spin) *
                rot(to=FWD, from=point3d(anch[2])) *
                affine3d_translate(point3d(-pos))
            ) : (
                assert(is_num(spin) || is_vector(spin,3))
                let(
                    ang = vector_angle(anch[2], DOWN),
                    axis = vector_axis(anch[2], DOWN),
                    ang2 = (anch[2]==UP || anch[2]==DOWN)? 0 : 180-anch[3],
                    axis2 = rot(p=axis,[0,0,ang2])
                )
                affine3d_rot_by_axis(axis2,ang) * (
                    is_num(spin)? affine3d_zrot(ang2+spin) : (
                        affine3d_zrot(spin.z) *
                        affine3d_yrot(spin.y) *
                        affine3d_xrot(spin.x) *
                        affine3d_zrot(ang2)
                    )
                ) * affine3d_translate(point3d(-pos))
            )
        ) : (
            let(
                pos = _find_anchor(anchor, geom)[1]
            ) two_d? (
                assert(two_d && is_num(spin))
                affine3d_zrot(spin) *
                affine3d_translate(point3d(-pos))
            ) : (
                assert(is_num(spin) || is_vector(spin,3))
                let(
                    axis = vector_axis(UP,orient),
                    ang = vector_angle(UP,orient)
                )
                affine3d_rot_by_axis(axis,ang) * (
                    is_num(spin)? affine3d_zrot(spin) : (
                        affine3d_zrot(spin.z) *
                        affine3d_yrot(spin.y) *
                        affine3d_xrot(spin.x)
                    )
                ) * affine3d_translate(point3d(-pos))
            )
        )
    ) is_undef(p)? m :
    is_vnf(p)? [(p==EMPTY_VNF? p : apply(m, p[0])), p[1]] :
    apply(m, p);


function _get_cp(geom) =
    
    let(cp=select(geom,-3))
    is_vector(cp) ? cp
  : let(
        type = in_list(geom[0],["vnf_extent","vnf_isect"]) ? "vnf"
             : in_list(geom[0],["rgn_extent","rgn_isect"]) ? "path"
             : in_list(geom[0],["xrgn_extent","xrgn_isect"]) ? "xpath"
             : "other"
    )
    assert(type!="other", "Invalid cp value")
    cp=="centroid" ? (
       type=="vnf" && (len(geom[1][0])==0 || len(geom[1][1])==0) ? [0,0,0] :
       [each centroid(geom[1]), if (type=="xpath") 0]
    )
  : let(points = type=="vnf"?geom[1][0]:flatten(force_region(geom[1])))
    cp=="mean" ? [each mean(points), if (type=="xpath") geom[2]/2]
  : cp=="box" ?[each  mean(pointlist_bounds(points)), if (type=="xpath") geom[2]/2]
  : assert(false,"Invalid cp specification");


function _force_anchor_2d(anchor) =
  assert(anchor.y==0 || anchor.z==0, "Anchor for a 2D shape cannot be fully 3D.  It must have either Y or Z component equal to zero.")
  anchor.y==0 ? [anchor.x,anchor.z] : point2d(anchor);


/// Internal Function: _find_anchor()
// Usage:
//   anchorinfo = _find_anchor(anchor, geom);
/// Topics: Attachments
/// See Also: reorient(), attachable()
// Description:
//   Calculates the anchor data for the given `anchor` vector or name, in the given attachment
//   geometry.  Returns `[ANCHOR, POS, VEC, ANG]` where `ANCHOR` is the requested anchorname
//   or vector, `POS` is the anchor position, `VEC` is the direction vector of the anchor, and
//   `ANG` is the angle to align with around the rotation axis of th anchor direction vector.
// Arguments:
//   anchor = Vector or named anchor string.
//   geom = The geometry description of the shape.
function _find_anchor(anchor, geom) =
    is_string(anchor)? (  
          anchor=="origin"? [anchor, CENTER, UP, 0]
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
            size=geom[1], size2=geom[2],
            shift=point2d(geom[3]), axis=point3d(geom[4]),
            anch = rot(from=axis, to=UP, p=anchor),
            offset = rot(from=axis, to=UP, p=offset),
            h = size.z,
            u = (anch.z + 1) / 2,  // u is one of 0, 0.5, or 1
            axy = point2d(anch),
            bot = point3d(v_mul(point2d(size )/2, axy), -h/2),
            top = point3d(v_mul(point2d(size2)/2, axy) + shift, h/2),
            pos = point3d(cp) + lerp(bot,top,u) + offset,
            vecs = [
                if (anch.x!=0) unit(rot(from=UP, to=[(top-bot).x,0,h], p=[axy.x,0,0]), UP),
                if (anch.y!=0) unit(rot(from=UP, to=[0,(top-bot).y,h], p=[0,axy.y,0]), UP),
                if (anch.z!=0) anch==CENTER? UP : unit([0,0,anch.z],UP)
            ],
            vec = anchor==CENTER? UP : rot(from=UP, to=axis, p=unit(sum(vecs) / len(vecs))),
            pos2 = rot(from=UP, to=axis, p=pos)
        ) [anchor, pos2, vec, oang]
    ) : type == "conoid"? ( //r1, r2, l, shift
        assert(anchor.z == sign(anchor.z), "The Z component of an anchor for a cylinder/cone must be -1, 0, or 1")
        let(
            rr1=geom[1], rr2=geom[2], l=geom[3],
            shift=point2d(geom[4]), axis=point3d(geom[5]),
            r1 = is_num(rr1)? [rr1,rr1] : point2d(rr1),
            r2 = is_num(rr2)? [rr2,rr2] : point2d(rr2),
            anch = rot(from=axis, to=UP, p=anchor),
            offset = rot(from=axis, to=UP, p=offset),
            u = (anch.z+1)/2,
            axy = unit(point2d(anch),[0,0]),
            bot = point3d(v_mul(r1,axy), -l/2),
            top = point3d(v_mul(r2,axy)+shift, l/2),
            pos = point3d(cp) + lerp(bot,top,u) + offset,
            sidevec = rot(from=UP, to=top-bot, p=point3d(axy)),
            vvec = anch==CENTER? UP : unit([0,0,anch.z],UP),
            vec = anch==CENTER? CENTER :
                approx(axy,[0,0])? unit(anch,UP) :
                approx(anch.z,0)? sidevec :
                unit((sidevec+vvec)/2,UP),
            pos2 = rot(from=UP, to=axis, p=pos),
            vec2 = anch==CENTER? UP : rot(from=UP, to=axis, p=vec)
        ) [anchor, pos2, vec2, oang]
    ) : type == "spheroid"? ( //r
        let(
            rr = geom[1],
            r = is_num(rr)? [rr,rr,rr] : point3d(rr),
            anchor = unit(point3d(anchor),CENTER),
            pos = point3d(cp) + v_mul(r,anchor) + point3d(offset),
            vec = unit(v_mul(r,anchor),UP)
        ) [anchor, pos, vec, oang]
    ) : type == "vnf_isect"? ( //vnf
        let( vnf=geom[1] )
        approx(anchor,CTR)? [anchor, [0,0,0], UP, 0] :
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
        [anchor, pos, n, oang]
    ) : type == "vnf_extent"? ( //vnf
        let( vnf=geom[1] )
        approx(anchor,CTR)? [anchor, [0,0,0], UP, 0] :
        vnf==EMPTY_VNF? [anchor, [0,0,0], unit(anchor,UP), 0] :
        let(
            rpts = apply(rot(from=anchor, to=RIGHT) * move(point3d(-cp)), vnf[0]),
            maxx = max(column(rpts,0)),
            idxs = [for (i = idx(rpts)) if (approx(rpts[i].x, maxx)) i],
            avep = sum(select(rpts,idxs))/len(idxs),
            mpt = approx(point2d(anchor),[0,0])? [maxx,0,0] : avep,
            pos = point3d(cp) + rot(from=RIGHT, to=anchor, p=mpt)
        ) [anchor, pos, anchor, oang]
    ) : type == "trapezoid"? ( //size, size2, shift
        let(all_comps_good = [for (c=anchor) if (c!=sign(c)) 1]==[])
        assert(all_comps_good, "All components of an anchor for a rectangle/trapezoid must be -1, 0, or 1")
        let(
            anchor=_force_anchor_2d(anchor),
            size=geom[1], size2=geom[2], shift=geom[3],
            u = (anchor.y+1)/2,  // 0<=u<=1
            frpt = [size.x/2*anchor.x, -size.y/2],
            bkpt = [size2/2*anchor.x+shift,  size.y/2],
            pos = point2d(cp) + lerp(frpt, bkpt, u) + point2d(offset),
            svec = point3d(line_normal(bkpt,frpt)*anchor.x),
            vec = anchor.y < 0? (
                    anchor.x == 0? FWD :
                    size.x == 0? unit(-[shift,size.y], FWD) :
                    unit((point3d(svec) + FWD) / 2, FWD)
                ) :
                anchor.y == 0? ( anchor.x == 0? BACK : svec ) :
                (  // anchor.y > 0
                    anchor.x == 0? BACK :
                    size2 == 0? unit([shift,size.y], BACK) :
                    unit((point3d(svec) + BACK) / 2, BACK)
                )
        ) [anchor, pos, vec, 0]
    ) : type == "ellipse"? ( //r
        let(
            anchor = unit(_force_anchor_2d(anchor),[0,0]),
            r = force_list(geom[1],2),
            pos = approx(anchor.x,0) ? [0,sign(anchor.y)*r.y]
                      : let(
                             m = anchor.y/anchor.x,
                             px = sign(anchor.x) * sqrt(1/(1/sqr(r.x) + m*m/sqr(r.y)))
                        )
                        [px,m*px],
            vec = unit([r.y/r.x*pos.x, r.x/r.y*pos.y],BACK)
        ) [anchor, point2d(cp+offset)+pos, vec, 0]
    ) : type == "rgn_isect"? ( //region
        let(
            anchor = _force_anchor_2d(anchor),
            rgn = force_region(move(-point2d(cp), p=geom[1]))
        )
        approx(anchor,[0,0])? [anchor, [0,0,0], BACK, 0] :
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
        approx(anchor,[0,0])? [anchor, [0,0,0], BACK, 0] :
        let(
            rgn = force_region(geom[1]),
            rpts = rot(from=anchor, to=RIGHT, p=flatten(rgn)),
            maxx = max(column(rpts,0)),
            ys = [for (pt=rpts) if (approx(pt.x, maxx)) pt.y],            
            midy = (min(ys)+max(ys))/2,
            pos = rot(from=RIGHT, to=anchor, p=[maxx,midy])
        ) [anchor, pos, unit(anchor,BACK), 0]
    ) : type=="xrgn_extent" || type=="xrgn_isect" ? (  // extruded region
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
        approx(anchor_xy,[0,0]) ? [anchor, apply(mat, up(anchor.z*L/2,cp)), unit(anchor, UP), oang] :
        let(
            newrgn = apply(mat, rgn),
            newgeom = attach_geom(two_d=true, region=newrgn, extent=type=="xrgn_extent", cp=cp),
            result2d = _find_anchor(anchor_xy, newgeom),
            pos = point3d(result2d[1], cp.z+anchor.z*L/2),
            vec = unit(point3d(result2d[2], anchor.z),UP),
            oang = atan2(vec.y,vec.x) + 90
        )
        [anchor, pos, vec, oang]
    ) :
    assert(false, "Unknown attachment geometry type.");


/// Internal Function: _is_shown()
// Usage:
//   bool = _is_shown();
/// Topics: Attachments
/// See Also: reorient(), attachable()
// Description:
//   Returns true if objects should currently be shown based on the tag settings.  
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
// Usage:
//   ... show_anchors([s], [std=], [custom=]);
// Description:
//   Show all standard anchors for the parent object.
// Arguments:
//   s = Length of anchor arrows.
//   ---
//   std = If true (default), show standard anchors.
//   custom = If true (default), show custom anchors.
// Example(FlatSpin,VPD=333):
//   cube(50, center=true) show_anchors();
module show_anchors(s=10, std=true, custom=true) {
    check = assert($parent_geom != undef) 1;
    two_d = _attach_geom_2d($parent_geom);
    if (std) {
        for (anchor=_standard_anchors(two_d=two_d)) {
            if(two_d) {
                attach(anchor) anchor_arrow2d(s);
            } else {
                attach(anchor) anchor_arrow(s);
            }
        }
    }
    if (custom) {
        for (anchor=last($parent_geom)) {
            attach(anchor[0]) {
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
// Usage:
//   anchor_arrow([s], [color], [flag]);
// Description:
//   Show an anchor orientation arrow.  By default, tagged with the name "anchor-arrow".
// Arguments:
//   s = Length of the arrows.  Default: `10`
//   color = Color of the arrow.  Default: `[0.333, 0.333, 1]`
//   flag = If true, draw the orientation flag on the arrowhead.  Default: true
// Example:
//   anchor_arrow(s=20);
module anchor_arrow(s=10, color=[0.333,0.333,1], flag=true, $tag="anchor-arrow") {
    $fn=12;
    recolor("gray") spheroid(d=s/6) {
        attach(CENTER,BOT) recolor(color) cyl(h=s*2/3, d=s/15) {
            attach(TOP,BOT) cyl(h=s/3, d1=s/5, d2=0) {
                if(flag) {
                    position(BOT)
                        recolor([1,0.5,0.5])
                            cuboid([s/100, s/6, s/4], anchor=FRONT+BOT);
                }
                children();
            }
        }
    }
}



// Module: anchor_arrow2d()
// Usage:
//   anchor_arrow2d([s], [color], [flag]);
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



// Module: frame_ref()
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

// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
