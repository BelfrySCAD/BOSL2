//////////////////////////////////////////////////////////////////////
// LibFile: edges.scad
//   Routines to work with edge sets and edge set descriptors.
// Includes:
//   include <BOSL2/std.scad>
//////////////////////////////////////////////////////////////////////


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
            x.z>0? ["TOP"]   : x.z<0? ["BTM"]  : [],
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
    is_edge_array(edges) ? [""] :
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



// Section: Edge Constants

// Constant: EDGES_NONE
// Topics: Edges
// See Also: EDGES_ALL, edges()
// Description:
//   The set of no edges.
// Figure(3D):
//   show_edges(edges="NONE");
EDGES_NONE = [[0,0,0,0], [0,0,0,0], [0,0,0,0]];


// Constant: EDGES_ALL
// Topics: Edges
// See Also: EDGES_NONE, edges()
// Description:
//   The set of all edges.
// Figure(3D):
//   show_edges(edges="ALL");
EDGES_ALL = [[1,1,1,1], [1,1,1,1], [1,1,1,1]];


// Constant: EDGES_OFFSETS
// Topics: Edges
// See Also: EDGES_NONE, EDGES_ALL, edges()
// Description:
//   The vectors pointing to the center of each edge of a unit sized cube.
//   Each item in an edge array will have a corresponding vector in this array.
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


// Section: Edge Helpers

// Function: is_edge_array()
// Topics: Edges, Type Checking
// Usage:
//   bool = is_edge_array(x);
// Description:
//   Returns true if the given value has the form of an edge array.
// Arguments:
//   x = The item to check the type of.
// See Also: edges(), EDGES_NONE, EDGES_ALL
function is_edge_array(x) = is_list(x) && is_vector(x[0]) && len(x)==3 && len(x[0])==4;


function _edge_set(v) =
    is_edge_array(v)? v : [
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


// Function: normalize_edges()
// Topics: Edges
// Usage:
//   edges = normalize_edges(v);
// Description:
//   Normalizes all values in an edge array to be `1`, if it was originally greater than `0`,
//   or `0`, if it was originally less than or equal to `0`.
// See Also: is_edge_array(), edges(), EDGES_NONE, EDGES_ALL
function normalize_edges(v) = [for (ax=v) [for (edge=ax) edge>0? 1 : 0]];


// Function: edges()
// Topics: Edges
// Usage:
//   edgs = edges(v);
//   edgs = edges(v, except);
//
// Description:
//   Takes a list of edge set descriptors, and returns a normalized edges array
//   that represents all those given edges.  If the `except` argument is given
//   a list of edge set descriptors, then all those edges will be removed
//   from the returned edges array.  If either argument only has a single edge
//   set descriptor, you do not have to pass it in a list.
//   Each edge set descriptor can be any of:
//   - A vector pointing towards an edge.
//   - A vector pointing towards a face, indicating all edges surrounding that face.
//   - A vector pointing towards a corner, indicating all edges touching that corner.
//   - The string `"X"`, indicating all X axis aligned edges.
//   - The string `"Y"`, indicating all Y axis aligned edges.
//   - The string `"Z"`, indicating all Z axis aligned edges.
//   - The string `"ALL"`, indicating all edges.
//   - The string `"NONE"`, indicating no edges at all.
//   - A raw edges array, where each edge is represented by a 1 or a 0.  The edge ordering is:
//       ```
//       [
//           [Y-Z-, Y+Z-, Y-Z+, Y+Z+],
//           [X-Z-, X+Z-, X-Z+, X+Z+],
//           [X-Y-, X+Y-, X-Y+, X+Y+]
//       ]
//       ```
// Figure(3D,Big): Edge Vectors
//   ydistribute(50) {
//       xdistribute(30) {
//           show_edges(edges=BOT+RIGHT);
//           show_edges(edges=BOT+BACK);
//           show_edges(edges=BOT+LEFT);
//           show_edges(edges=BOT+FRONT);
//       }
//       xdistribute(30) {
//           show_edges(edges=FWD+RIGHT);
//           show_edges(edges=BACK+RIGHT);
//           show_edges(edges=BACK+LEFT);
//           show_edges(edges=FWD+LEFT);
//       }
//       xdistribute(30) {
//           show_edges(edges=TOP+RIGHT);
//           show_edges(edges=TOP+BACK);
//           show_edges(edges=TOP+LEFT);
//           show_edges(edges=TOP+FRONT);
//       }
//   }
// Figure(3D,Big): Corner Vector Edge Sets
//   ydistribute(50) {
//       xdistribute(30) {
//           show_edges(edges=FRONT+LEFT+TOP);
//           show_edges(edges=FRONT+RIGHT+TOP);
//           show_edges(edges=FRONT+LEFT+BOT);
//           show_edges(edges=FRONT+RIGHT+BOT);
//       }
//       xdistribute(30) {
//           show_edges(edges=TOP+LEFT+BACK);
//           show_edges(edges=TOP+RIGHT+BACK);
//           show_edges(edges=BOT+LEFT+BACK);
//           show_edges(edges=BOT+RIGHT+BACK);
//       }
//   }
// Figure(3D,Med): Face Vector Edge Sets
//   ydistribute(50) {
//       xdistribute(30) {
//           show_edges(edges=LEFT);
//           show_edges(edges=FRONT);
//           show_edges(edges=RIGHT);
//       }
//       xdistribute(30) {
//           show_edges(edges=TOP);
//           show_edges(edges=BACK);
//           show_edges(edges=BOTTOM);
//       }
//   }
// Figure(3D,Med): Named Edge Sets
//   ydistribute(50) {
//       xdistribute(30) {
//           show_edges(edges="X");
//           show_edges(edges="Y");
//           show_edges(edges="Z");
//       }
//       xdistribute(30) {
//           show_edges(edges="ALL");
//           show_edges(edges="NONE");
//       }
//   }
//
// Arguments:
//   v = The edge set to include.
//   except = The edge set to specifically exclude, even if they are in `v`.
//
// See Also: is_edge_array(), normalize_edges(), EDGES_NONE, EDGES_ALL
//
// Example(3D): Just the front-top edge
//   edg = edges(FRONT+TOP);
//   show_edges(edges=edg);
// Example(3D): All edges surrounding either the front or top faces
//   edg = edges([FRONT,TOP]);
//   show_edges(edges=edg);
// Example(3D): All edges around the bottom face, except any that are also on the front
//   edg = edges(BTM, except=FRONT);
//   show_edges(edges=edg);
// Example(3D): All edges except those around the bottom face.
//   edg = edges("ALL", except=BOTTOM);
//   show_edges(edges=edg);
// Example(3D): All Z-aligned edges except those around the back face.
//   edg = edges("Z", except=BACK);
//   show_edges(edges=edg);
// Example(3D): All edges around the bottom or front faces, except the bottom-front edge.
//   edg = edges([BOTTOM,FRONT], except=BOTTOM+FRONT);
//   show_edges(edges=edg);
// Example(3D): All edges, except Z-aligned edges on the front.
//   edg = edges("ALL", except=edges("Z", except=BACK));
//   show_edges(edges=edg);
function edges(v, except=[]) =
    (is_string(v) || is_vector(v) || is_edge_array(v))? edges([v], except=except) :
    (is_string(except) || is_vector(except) || is_edge_array(except))? edges(v, except=[except]) :
    except==[]? normalize_edges(sum([for (x=v) _edge_set(x)])) :
    normalize_edges(
        normalize_edges(sum([for (x=v) _edge_set(x)])) -
        sum([for (x=except) _edge_set(x)])
    );


// Module: show_edges()
// Topics: Edges, Debugging
// Usage:
//   show_edges(edges, [size=], [text=], [txtsize=]);
// Description:
//   Draws a semi-transparent cube with the given edges highlighted in red.
// Arguments:
//   edges = The edges to highlight.
//   size = The scalar size of the cube.
//   text = The text to show on the front of the cube.
//   txtsize = The size of the text.
// See Also: is_edge_array(), edges(), EDGES_NONE, EDGES_ALL
// Example:
//   show_edges(size=30, edges=["X","Y"]);
module show_edges(edges="ALL", size=20, text, txtsize=3) {
    edge_set = edges(edges);
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
}



// Section: Corner Constants
//   Constants for working with corners.


// Constant: CORNERS_NONE
// Topics: Corners
// Description:
//   The set of no corners.
// Figure(3D):
//   show_corners(corners="NONE");
// See Also: CORNERS_ALL, corners()
CORNERS_NONE = [0,0,0,0,0,0,0,0];  // No corners.


// Constant: CORNERS_ALL
// Topics: Corners
// Description:
//   The set of all corners.
// Figure(3D):
//   show_corners(corners="ALL");
// See Also: CORNERS_NONE, corners()
CORNERS_ALL = [1,1,1,1,1,1,1,1];


// Constant: CORNER_OFFSETS
// Topics: Corners
// Description:
//   The vectors pointing to each corner of a unit sized cube.
//   Each item in a corner array will have a corresponding vector in this array.
// See Also: CORNERS_NONE, CORNERS_ALL, corners()
CORNER_OFFSETS = [
    [-1,-1,-1], [ 1,-1,-1], [-1, 1,-1], [ 1, 1,-1],
    [-1,-1, 1], [ 1,-1, 1], [-1, 1, 1], [ 1, 1, 1]
];



// Section: Corner Helpers

// Function: is_corner_array()
// Topics: Corners, Type Checking
// Usage:
//   bool = is_corner_array(x)
// Description:
//   Returns true if the given value has the form of a corner array.
// See Also: CORNERS_NONE, CORNERS_ALL, corners()
function is_corner_array(x) = is_vector(x) && len(x)==8 && all([for (xx=x) xx==1||xx==0]);


// Function: normalize_corners()
// Topics: Corners
// Usage:
//   corns = normalize_corners(v);
// Description:
//   Normalizes all values in a corner array to be `1`, if it was originally greater than `0`,
//   or `0`, if it was originally less than or equal to `0`.
// See Also: CORNERS_NONE, CORNERS_ALL, is_corner_array(), corners()
function normalize_corners(v) = [for (x=v) x>0? 1 : 0];


function _corner_set(v) =
    is_corner_array(v)? v : [
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


// Function: corners()
// Topics: Corners
// Usage:
//   corns = corners(v);
//   corns = corners(v, except);
// Description:
//   Takes a list of corner set descriptors, and returns a normalized corners array
//   that represents all those given corners.  If the `except` argument is given
//   a list of corner set descriptors, then all those corners will be removed
//   from the returned corners array.  If either argument only has a single corner
//   set descriptor, you do not have to pass it in a list.
//   Each corner set descriptor can be any of:
//   - A vector pointing towards an edge indicating both corners at the ends of that edge.
//   - A vector pointing towards a face, indicating all the corners of that face.
//   - A vector pointing towards a corner, indicating just that corner.
//   - The string `"ALL"`, indicating all corners.
//   - The string `"NONE"`, indicating no corners at all.
//   - A raw corners array, where each corner is represented by a 1 or a 0.  The corner ordering is:
//       ```
//       [X-Y-Z-, X+Y-Z-, X-Y+Z-, X+Y+Z-, X-Y-Z+, X+Y-Z+, X-Y+Z+, X+Y+Z+]
//       ```
// Figure(3D,Big): Corners by Corner Vector
//   ydistribute(55) {
//       xdistribute(35) {
//           show_corners(corners=FRONT+LEFT+TOP);
//           show_corners(corners=FRONT+RIGHT+TOP);
//           show_corners(corners=FRONT+LEFT+BOT);
//           show_corners(corners=FRONT+RIGHT+BOT);
//       }
//       xdistribute(35) {
//           show_corners(corners=TOP+LEFT+BACK);
//           show_corners(corners=TOP+RIGHT+BACK);
//           show_corners(corners=BOT+LEFT+BACK);
//           show_corners(corners=BOT+RIGHT+BACK);
//       }
//   }
// Figure(3D,Big): Corners by Edge Vectors
//   ydistribute(55) {
//       xdistribute(35) {
//           show_corners(corners=BOT+RIGHT);
//           show_corners(corners=BOT+BACK);
//           show_corners(corners=BOT+LEFT);
//           show_corners(corners=BOT+FRONT);
//       }
//       xdistribute(35) {
//           show_corners(corners=FWD+RIGHT);
//           show_corners(corners=BACK+RIGHT);
//           show_corners(corners=BACK+LEFT);
//           show_corners(corners=FWD+LEFT);
//       }
//       xdistribute(35) {
//           show_corners(corners=TOP+RIGHT);
//           show_corners(corners=TOP+BACK);
//           show_corners(corners=TOP+LEFT);
//           show_corners(corners=TOP+FRONT);
//       }
//   }
// Figure(3D,Med): Corners by Face Vectors
//   ydistribute(55) {
//       xdistribute(35) {
//           show_corners(corners=LEFT);
//           show_corners(corners=FRONT);
//           show_corners(corners=RIGHT);
//       }
//       xdistribute(35) {
//           show_corners(corners=TOP);
//           show_corners(corners=BACK);
//           show_corners(corners=BOTTOM);
//       }
//   }
// Figure(3D,Med): Corners by Name
//   xdistribute(35) {
//       show_corners(corners="ALL");
//       show_corners(corners="NONE");
//   }
// See Also: CORNERS_NONE, CORNERS_ALL, is_corner_array(), normalize_corners()
// Example(3D): Just the front-top-right corner
//   crn = corners(FRONT+TOP+RIGHT);
//   show_corners(corners=crn);
// Example(3D): All corners surrounding either the front or top faces
//   crn = corners([FRONT,TOP]);
//   show_corners(corners=crn);
// Example(3D): All corners around the bottom face, except any that are also on the front
//   crn = corners(BTM, except=FRONT);
//   show_corners(corners=crn);
// Example(3D): All corners except those around the bottom face.
//   crn = corners("ALL", except=BOTTOM);
//   show_corners(corners=crn);
// Example(3D): All corners around the bottom or front faces, except those on the bottom-front edge.
//   crn = corners([BOTTOM,FRONT], except=BOTTOM+FRONT);
//   show_corners(corners=crn);
function corners(v, except=[]) =
    (is_string(v) || is_vector(v) || is_corner_array(v))? corners([v], except=except) :
    (is_string(except) || is_vector(except) || is_corner_array(except))? corners(v, except=[except]) :
    except==[]? normalize_corners(sum([for (x=v) _corner_set(x)])) :
    let(
        a = normalize_corners(sum([for (x=v) _corner_set(x)])),
        b = normalize_corners(sum([for (x=except) _corner_set(x)]))
    ) normalize_corners(a - b);


// Function: corner_edges()
// Topics: Corners
// Description:
//   Returns [XCOUNT,YCOUNT,ZCOUNT] where each is the count of edges aligned with that
//   axis that are in the edge set and touch the given corner.
// Arguments:
//   edges = Standard edges array.
//   v = Vector pointing to the corner to count edge intersections at.
// See Also: CORNERS_NONE, CORNERS_ALL, is_corner_array(), corners(), corner_edge_count()
function corner_edges(edges, v) =
    let(u = (v+[1,1,1])/2) [edges[0][u.y+u.z*2], edges[1][u.x+u.z*2], edges[2][u.x+u.y*2]];


// Function: corner_edge_count()
// Topics: Corners
// Description:
//   Counts how many given edges intersect at a specific corner.
// Arguments:
//   edges = Standard edges array.
//   v = Vector pointing to the corner to count edge intersections at.
// See Also: CORNERS_NONE, CORNERS_ALL, is_corner_array(), corners(), corner_edges()
function corner_edge_count(edges, v) =
    let(u = (v+[1,1,1])/2) edges[0][u.y+u.z*2] + edges[1][u.x+u.z*2] + edges[2][u.x+u.y*2];


function _corners_text(corners) =
    is_string(corners) ? [str("\"",corners,"\"")] :
    corners==CORNERS_NONE ? ["CORNERS_NONE"] :
    corners==CORNERS_ALL ? ["CORNERS_ALL"] :
    is_corner_array(corners) ? [""] :
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


// Module: show_corners()
// Topics: Corners, Debugging
// Usage:
//   show_corners(corners, [size=], [text=], [txtsize=]);
// Description:
//   Draws a semi-transparent cube with the given corners highlighted in red.
// Arguments:
//   corners = The corners to highlight.
//   size = The scalar size of the cube.
//   text = If given, overrides the text to be shown on the front of the cube.
//   txtsize = The size of the text.
// See Also: CORNERS_NONE, CORNERS_ALL, is_corner_array(), corners()
// Example:
//   show_corners(corners=FWD+RIGHT, size=30);
module show_corners(corners="ALL", size=20, text, txtsize=3) {
    corner_set = corners(corners);
    text = !is_undef(text) ? text : _corners_text(corners);
    for (i=[0:7]) if (corner_set[i]>0)
        translate(CORNER_OFFSETS[i]*size/2)
            color("red") sphere(d=2, $fn=16);
    fwd(size/2) _edges_text3d(text, size=txtsize);
    color("yellow",0.7) cuboid(size=size);
}



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
