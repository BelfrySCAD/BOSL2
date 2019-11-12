//////////////////////////////////////////////////////////////////////
// LibFile: edges.scad
//   Routines to work with edge sets and edge set descriptors.
//   To use this, add the following line to the top of your file.
//   ```
//   include <BOSL2/std.scad>
//   ```
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


// Function: corner_edge_count()
// Description: Counts how many given edges intersect at a specific corner.
// Arguments:
//   edges = Standard edges array.
//   v = Vector pointing to the corner to count edge intersections at.
function corner_edge_count(edges, v) =
	let(u = (v+[1,1,1])/2) edges[0][u.y+u.z*2] + edges[1][u.x+u.z*2] + edges[2][u.x+u.y*2];


// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
