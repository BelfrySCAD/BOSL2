//////////////////////////////////////////////////////////////////////
// LibFile: edges.scad
//   This file describes how to specify directions, face sets, edge sets and corner sets.
// Includes:
//   include <BOSL2/std.scad>
//////////////////////////////////////////////////////////////////////

// Section: Specifying Directions
//   You can use direction vectors to specify anchors for objects or to specify edges, faces, and
//   corners of cubes.  You can simply specify these direction vectors numerically, but another
//   option is to use named constants for direction vectors.  These constants define unit vectors
//   for the six axis directions as shown below.
// Figure(3D,Big,VPD=6): Named constants for direction vectors.  Some directions have more than one name.  
//   $fn=12;
//   stroke([[0,0,0],RIGHT], endcap2="arrow2", width=.05);
//   color("black")right(.05)up(.05)move(RIGHT)atext("RIGHT",size=.1,h=.01,anchor=LEFT,orient=FRONT);
//   stroke([[0,0,0],LEFT], endcap2="arrow2", width=.05);
//   color("black")left(.05)up(.05)move(LEFT)atext("LEFT",size=.1,h=.01,anchor=RIGHT,orient=FRONT);
//   stroke([[0,0,0],FRONT], endcap2="arrow2", width=.05);
//   color("black")
//   left(.1){
//   up(.12)move(FRONT)atext("FRONT",size=.1,h=.01,anchor=RIGHT,orient=FRONT);
//   move(FRONT)atext("FWD",size=.1,h=.01,anchor=RIGHT,orient=FRONT);
//   down(.12)move(FRONT)atext("FORWARD",size=.1,h=.01,anchor=RIGHT,orient=FRONT);
//   }
//   stroke([[0,0,0],BACK], endcap2="arrow2", width=.05);
//   right(.05)
//   color("black")move(BACK)atext("BACK",size=.1,h=.01,anchor=LEFT,orient=FRONT);
//   stroke([[0,0,0],DOWN], endcap2="arrow2", width=.05);
//   color("black")
//   right(.1){
//   up(.12)move(BOT)atext("DOWN",size=.1,h=.01,anchor=LEFT,orient=FRONT);
//   move(BOT)atext("BOTTOM",size=.1,h=.01,anchor=LEFT,orient=FRONT);
//   down(.12)move(BOT)atext("BOT",size=.1,h=.01,anchor=LEFT,orient=FRONT);
//   }
//   stroke([[0,0,0],TOP], endcap2="arrow2", width=.05);
//   color("black")left(.05){
//   up(.12)move(TOP)atext("TOP",size=.1,h=.01,anchor=RIGHT,orient=FRONT);
//   move(TOP)atext("UP",size=.1,h=.01,anchor=RIGHT,orient=FRONT);
//   }
// Section: Specifying Faces
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
// Section: Specifying Edges
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
// Section: Specifying Corners
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
                matches = count_true([
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
      for(h=idx(toplabel)) up(21+6*h)rot(vpr)atext(select(toplabel,-h-1),size=3.3,h=0.1,orient=UP,anchor=FRONT);
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
      for(h=idx(toplabel)) up(21+6*h)rot(vpr)atext(select(toplabel,-h-1),size=3.3,h=.1,orient=UP,anchor=FRONT);
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
     for(h=idx(toplabel)) up(21+6*h)rot(vpr)atext(select(toplabel,-h-1),size=3.3,h=.1,orient=UP,anchor=FRONT);
   if (is_def(botlabel))
     for(h=idx(botlabel)) down(26+6*h)rot(vpr)atext(botlabel[h],size=3.3,h=.1,orient=UP,anchor=FRONT);
   }
   color("yellow",0.7) cuboid(size=size);
}

// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
