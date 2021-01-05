//////////////////////////////////////////////////////////////////////
// LibFile: edges.scad
//   Routines to work with edge sets and edge set descriptors.
// Includes:
//   include <BOSL2/std.scad>
//////////////////////////////////////////////////////////////////////


// CommonCode:
//   module text3d(txt,size=3) {
//       if (is_list(txt)) {
//           for (i=idx(txt)) {
//               down((i-len(txt)/2+1)*size*1.25) {
//                   text3d(txt[i], size=size);
//               }
//           }
//       } else {
//           xrot(90) color("#000")
//           linear_extrude(height=0.1) {
//               text(text=txt, size=size, halign="center", valign="center");
//           }
//       }
//   }
//   module edge_cube(size=20, chamfer=3, txtsize=3, edges="ALL") {
//       lbl = is_string(edges)? [str("\"",edges,"\"")] : concat(
//            edges.z>0? ["TOP"] : edges.z<0? ["BTM"] : [],
//            edges.y>0? ["BACK"] : edges.y<0? ["FWD"] : [],
//            edges.x>0? ["RIGHT"] : edges.x<0? ["LEFT"] : []
//       );
//       lbl2 = [for (i=idx(lbl)) i<len(lbl)-1? str(lbl[i],"+") : lbl[i]];
//       cuboid(size=size,chamfer=chamfer,edges=edges);
//       fwd(size/2) text3d(lbl2, size=txtsize);
//   }
//   module corner_cube(size=20, txtsize=3, corners="ALL") {
//       corner_set = _corner_set(corners);
//       lbl = is_string(corners)? [str("\"",corners,"\"")] : concat(
//            corners.z>0? ["TOP"] : corners.z<0? ["BTM"] : [],
//            corners.y>0? ["BACK"] : corners.y<0? ["FWD"] : [],
//            corners.x>0? ["RIGHT"] : corners.x<0? ["LEFT"] : []
//       );
//       lbl2 = [for (i=idx(lbl)) i<len(lbl)-1? str(lbl[i],"+") : lbl[i]];
//       for (i=[0:7]) if (corner_set[i]>0)
//         translate(CORNER_OFFSETS[i]*size/2)
//           color("red")
//             cube(1, center=true);
//       fwd(size/2) text3d(lbl2, size=txtsize);
//       color("yellow",0.7) cuboid(size=size);
//   }


// Section: Sets of Edges
//   Constants for specifying edges for `cuboid()`, etc.

EDGES_NONE     = [[0,0,0,0], [0,0,0,0], [0,0,0,0]];  // No edges.
EDGES_ALL      = [[1,1,1,1], [1,1,1,1], [1,1,1,1]];  // All edges.


// Section: Edge Helpers

// Function: is_edge_array()
// Usage:
//   is_edge_array(v)
// Description:
//   Returns true if the given value has the form of an edge array.
function is_edge_array(v) = is_list(v) && is_vector(v[0]) && len(v)==3 && len(v[0])==4;


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
            let(nonz = sum(vabs(v)))
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
// Usage:
//   normalize_edges(v);
// Description:
//   Normalizes all values in an edge array to be `1`, if it was originally greater than `0`,
//   or `0`, if it was originally less than or equal to `0`.
function normalize_edges(v) = [for (ax=v) [for (edge=ax) edge>0? 1 : 0]];


// Function: edges()
// Usage:
//   edges(v)
//   edges(v, except)
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
// Figure(3DBig): Edge Vectors
//   ydistribute(50) {
//       xdistribute(30) {
//           edge_cube(edges=BOT+RIGHT);
//           edge_cube(edges=BOT+BACK);
//           edge_cube(edges=BOT+LEFT);
//           edge_cube(edges=BOT+FRONT);
//       }
//       xdistribute(30) {
//           edge_cube(edges=FWD+RIGHT);
//           edge_cube(edges=BACK+RIGHT);
//           edge_cube(edges=BACK+LEFT);
//           edge_cube(edges=FWD+LEFT);
//       }
//       xdistribute(30) {
//           edge_cube(edges=TOP+RIGHT);
//           edge_cube(edges=TOP+BACK);
//           edge_cube(edges=TOP+LEFT);
//           edge_cube(edges=TOP+FRONT);
//       }
//   }
// Figure(3DBig): Corner Vector Edge Sets
//   ydistribute(50) {
//       xdistribute(30) {
//           edge_cube(edges=FRONT+LEFT+TOP);
//           edge_cube(edges=FRONT+RIGHT+TOP);
//           edge_cube(edges=FRONT+LEFT+BOT);
//           edge_cube(edges=FRONT+RIGHT+BOT);
//       }
//       xdistribute(30) {
//           edge_cube(edges=TOP+LEFT+BACK);
//           edge_cube(edges=TOP+RIGHT+BACK);
//           edge_cube(edges=BOT+LEFT+BACK);
//           edge_cube(edges=BOT+RIGHT+BACK);
//       }
//   }
// Figure(3D): Face Vector Edge Sets
//   ydistribute(50) {
//       xdistribute(30) {
//           edge_cube(edges=LEFT);
//           edge_cube(edges=FRONT);
//           edge_cube(edges=RIGHT);
//       }
//       xdistribute(30) {
//           edge_cube(edges=TOP);
//           edge_cube(edges=BACK);
//           edge_cube(edges=BOTTOM);
//       }
//   }
// Figure(3D): Named Edge Sets
//   ydistribute(50) {
//       xdistribute(30) {
//           edge_cube(edges="X");
//           edge_cube(edges="Y");
//           edge_cube(edges="Z");
//       }
//       xdistribute(30) {
//           edge_cube(edges="ALL");
//           edge_cube(edges="NONE");
//       }
//   }
// Example: Just the front-top edge
//   edges(FRONT+TOP)
// Example: All edges surrounding either the front or top faces
//   edges([FRONT,TOP])
// Example: All edges around the bottom face, except any that are also on the front
//   edges(BTM, except=FRONT)
// Example: All edges except those around the bottom face.
//   edges("ALL", except=BOTTOM)
// Example: All Z-aligned edges except those around the back face.
//   edges("Z", except=BACK)
// Example: All edges around the bottom or front faces, except the bottom-front edge.
//   edges([BOTTOM,FRONT], except=BOTTOM+FRONT)
// Example: All edges, except Z-aligned edges on the front.
//   edges("ALL", except=edges("Z", except=BACK))
function edges(v, except=[]) =
    (is_string(v) || is_vector(v) || is_edge_array(v))? edges([v], except=except) :
    (is_string(except) || is_vector(except) || is_edge_array(except))? edges(v, except=[except]) :
    except==[]? normalize_edges(sum([for (x=v) _edge_set(x)])) :
    normalize_edges(
        normalize_edges(sum([for (x=v) _edge_set(x)])) -
        sum([for (x=except) _edge_set(x)])
    );


EDGE_OFFSETS = [   // Array of XYZ offsets to the center of each edge.
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


// Section: Corner Sets
//   Constants for specifying corners.

CORNERS_NONE = [0,0,0,0,0,0,0,0];  // No corners.
CORNERS_ALL = [1,1,1,1,1,1,1,1];  // All corners.


// Section: Corner Helpers

// Function: is_corner_array()
// Usage:
//   is_corner_array(v)
// Description:
//   Returns true if the given value has the form of a corner array.
function is_corner_array(v) = is_vector(v) && len(v)==8 && all([for (x=v) x==1||x==0]);


// Function: normalize_corners()
// Usage:
//   normalize_corners(v);
// Description:
//   Normalizes all values in a corner array to be `1`, if it was originally greater than `0`,
//   or `0`, if it was originally less than or equal to `0`.
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
// Usage:
//   corners(v)
//   corners(v, except)
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
// Figure(3DBig): Edge Vectors
//   ydistribute(55) {
//       xdistribute(35) {
//           corner_cube(corners=BOT+RIGHT);
//           corner_cube(corners=BOT+BACK);
//           corner_cube(corners=BOT+LEFT);
//           corner_cube(corners=BOT+FRONT);
//       }
//       xdistribute(35) {
//           corner_cube(corners=FWD+RIGHT);
//           corner_cube(corners=BACK+RIGHT);
//           corner_cube(corners=BACK+LEFT);
//           corner_cube(corners=FWD+LEFT);
//       }
//       xdistribute(35) {
//           corner_cube(corners=TOP+RIGHT);
//           corner_cube(corners=TOP+BACK);
//           corner_cube(corners=TOP+LEFT);
//           corner_cube(corners=TOP+FRONT);
//       }
//   }
// Figure(3DBig): Corner Vector Edge Sets
//   ydistribute(55) {
//       xdistribute(35) {
//           corner_cube(corners=FRONT+LEFT+TOP);
//           corner_cube(corners=FRONT+RIGHT+TOP);
//           corner_cube(corners=FRONT+LEFT+BOT);
//           corner_cube(corners=FRONT+RIGHT+BOT);
//       }
//       xdistribute(35) {
//           corner_cube(corners=TOP+LEFT+BACK);
//           corner_cube(corners=TOP+RIGHT+BACK);
//           corner_cube(corners=BOT+LEFT+BACK);
//           corner_cube(corners=BOT+RIGHT+BACK);
//       }
//   }
// Figure(3D): Face Vector Edge Sets
//   ydistribute(55) {
//       xdistribute(35) {
//           corner_cube(corners=LEFT);
//           corner_cube(corners=FRONT);
//           corner_cube(corners=RIGHT);
//       }
//       xdistribute(35) {
//           corner_cube(corners=TOP);
//           corner_cube(corners=BACK);
//           corner_cube(corners=BOTTOM);
//       }
//   }
// Figure(3D): Named Edge Sets
//   xdistribute(35) {
//       corner_cube(corners="ALL");
//       corner_cube(corners="NONE");
//   }
// Example: Just the front-top-right corner
//   corners(FRONT+TOP+RIGHT)
// Example: All corners surrounding either the front or top faces
//   corners([FRONT,TOP])
// Example: All corners around the bottom face, except any that are also on the front
//   corners(BTM, except=FRONT)
// Example: All corners except those around the bottom face.
//   corners("ALL", except=BOTTOM)
// Example: All corners around the bottom or front faces, except those on the bottom-front edge.
//   corners([BOTTOM,FRONT], except=BOTTOM+FRONT)
function corners(v, except=[]) =
    (is_string(v) || is_vector(v) || is_corner_array(v))? corners([v], except=except) :
    (is_string(except) || is_vector(except) || is_corner_array(except))? corners(v, except=[except]) :
    except==[]? normalize_corners(sum([for (x=v) _corner_set(x)])) :
    let(
        a = normalize_corners(sum([for (x=v) _corner_set(x)])),
        b = normalize_corners(sum([for (x=except) _corner_set(x)]))
    ) normalize_corners(a - b);


CORNER_OFFSETS = [   // Array of XYZ offsets to each corner.
    [-1,-1,-1], [ 1,-1,-1], [-1, 1,-1], [ 1, 1,-1],
    [-1,-1, 1], [ 1,-1, 1], [-1, 1, 1], [ 1, 1, 1]
];


// Function: corner_edges()
// Description:
//   Returns [XCOUNT,YCOUNT,ZCOUNT] where each is the count of edges aligned with that axis that are in the edge set and touch the given corner.
// Arguments:
//   edges = Standard edges array.
//   v = Vector pointing to the corner to count edge intersections at.
function corner_edges(edges, v) =
    let(u = (v+[1,1,1])/2) [edges[0][u.y+u.z*2], edges[1][u.x+u.z*2], edges[2][u.x+u.y*2]];


// Function: corner_edge_count()
// Description: Counts how many given edges intersect at a specific corner.
// Arguments:
//   edges = Standard edges array.
//   v = Vector pointing to the corner to count edge intersections at.
function corner_edge_count(edges, v) =
    let(u = (v+[1,1,1])/2) edges[0][u.y+u.z*2] + edges[1][u.x+u.z*2] + edges[2][u.x+u.y*2];


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
