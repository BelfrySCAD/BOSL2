//////////////////////////////////////////////////////////////////////
// LibFile: edges.scad
//   Routines to work with edge sets and edge set descriptors.
//   To use this, add the following line to the top of your file.
//   ```
//   include <BOSL2/std.scad>
//   ```
//////////////////////////////////////////////////////////////////////


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


// Function: edge()
// Usage:
//   edge(v);
// Description:
//   Takes an edge set descriptor and returns the edges array representing those edges.
//   This function is useful for modules that take `edges` arguments, like `cuboid()`.
//   An edge set descriptor can be any of:
//   - A raw edges array.
//   - A vector pointing towards an edge, indicating just that edge.
//   - A vector pointing towards a face, indicating all edges surrounding that face.
//   - A vector pointing towards a corner, indicating all edges that meet at that corner.
//   - The string `"X"`, indicating all X axis aligned edges.
//   - The string `"Y"`, indicating all Y axis aligned edges.
//   - The string `"Z"`, indicating all Y axis aligned edges.
//   - The string `"ALL"`, indicating all edges.
//   - The string `"NONE"`, indicating no edges at all.
function edge_set(v) =
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
//   - A raw edges array.
//   - A vector pointing towards an edge.
//   - A vector pointing towards a face, indicating all edges surrounding that face.
//   - A vector pointing towards a corner, indicating all edges touching that corner.
//   - The string `"X"`, indicating all X axis aligned edges.
//   - The string `"Y"`, indicating all Y axis aligned edges.
//   - The string `"Z"`, indicating all Y axis aligned edges.
//   - The string `"ALL"`, indicating all edges.
//   - The string `"NONE"`, indicating no edges at all.
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
	except==[]? normalize_edges(sum([for (x=v) edge_set(x)])) :
	normalize_edges(
		normalize_edges(sum([for (x=v) edge_set(x)])) -
		sum([for (x=except) edge_set(x)])
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
