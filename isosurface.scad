/////////////////////////////////////////////////////////////////////
// LibFile: isosurface.scad
//   [Metaballs](https://en.wikipedia.org/wiki/Metaballs) (also known as "blobby objects"),
//   are bounded and closed organic surfaces that smoothly blend together.
//   Metaballs are a specific kind of [isosurface](https://en.wikipedia.org/wiki/Isosurface).
//   . 
//   An isosurface, or implicit surface, is a three-dimensional surface representing all points of a
//   constant value (e.g. pressure, temperature, electric potential, density) in a
//   3D volume. It's the 3D version of a 2D contour; in fact, any 2D cross-section of an
//   isosurface **is** a 2D contour.
//   .
//   For computer-aided design, isosurfaces of abstract functions can generate complex curved surfaces
//   and organic shapes. For example, spherical metaballs can be formulated using a set of point
//   centers that define the metaball locations. For each metaball, a function is defined to compute
//   the contribution of the metaball to any point in a 3D volume. The
//   combined contributions from all the metaballs results in a function that varies in a complicated
//   way throughout the volume. When two metaballs are far apart, they appear simply as spheres, but when
//   they are close together they enlarge, reach toward each other, and meld together in a smooth
//   fashion. The resulting metaball model appears as smoothly blended blobby shapes. The
//   implementation below provides metaballs of a variety of types including spheres, cuboids, and
//   cylinders (cones), with optional parameters to adjust the influence of one metaball on others,
//   and the cutoff distance where the metaball's influence stops.
//   .
//   In general, an isosurface can be defined using any function of three variables $x, y, z$.
//   The isosurface of a function $f(x,y,z)$ is the set of points where $f(x,y,z)=c$ for some constant
//   value $c$. Such a function is also known as an "implicit surface" because the function *implies* a
//   surface of constant value within a volume of space. The constant $c$ is referred to as the "isovalue".
//   Changing the isovalue changes the position of the isosurface, depending on how the function is
//   defined. Because metaballs are isosurfaces, they also have an isovalue. The isovalue is also known
//   as the "threshold".
//   .
//   Some isosurface functions are unbounded, extending infinitely in all directions. A familiar example may
//   be a [gryoid](https://en.wikipedia.org/wiki/Gyroid), which is often used as a volume infill pattern in
//   [fused filament fabrication](https://en.wikipedia.org/wiki/Fused_filament_fabrication). The gyroid
//   isosurface is unbounded and periodic in all three dimensions.
//   .
//   This file provides modules and functions to create a [VNF](vnf.scad) using metaballs, or from general isosurfaces.
//   .
//   The point list in the generated VNF structure contains many duplicated points. This is normally not a
//   problem for rendering the shape, but machine roundoff differences may result in Manifold issuing
//   warnings when doing the final render, causing rendering to abort if you have enabled the "stop on
//   first warning" setting. You can prevent this by passing the VNF through {{vnf_quantize()}} using a
//   quantization of 1e-7, or you can pass the VNF structure into {{vnf_merge_points()}}, which also
//   removes the duplicates. Additionally, flat surfaces (often resulting from clipping by the bounding
//   box) are triangulated at the voxel size resolution, and these can be unified into a single face by
//   passing the vnf structure to {{vnf_unify_faces()}}. These steps can be computationally expensive
//   and are not normally necessary.
// Includes:
//   include <BOSL2/std.scad>
//   include <BOSL2/isosurface.scad>
// FileGroup: Advanced Modeling
// FileSummary: Isosurfaces and metaballs.
//////////////////////////////////////////////////////////////////////


/*
Lookup Tables for Transvoxel's Modified Marching Cubes

Adapted for OpenSCAD from https://gist.github.com/dwilliamson/72c60fcd287a94867b4334b42a7888ad

Unlike the original paper (Marching Cubes: A High Resolution 3D Surface Construction Algorithm), these tables guarantee a closed mesh in which connected components are continuous and free of holes.

Rotations are prioritized over inversions so that 3 of the 6 cases containing ambiguous faces are never added. 3 extra cases are added as a post-process, overriding inversions through custom-built rotations to eliminate the remaining ambiguities.

The cube index determines the sequence of edges to split. The index ranges from 0 to 255, representing all possible combinations of the 8 corners of the cube being greater or less than the isosurface threshold.

For example, a cube with corners 2, 3, and 7 greater than the threshold isovalue would have the index 10000110, an 8-bit binary number with bits 2, 3, and 7 set to 1, corresponding to decimal index 134. After determining the cube's index value this way, the triangulation order is looked up in a table.

Axes are
     z
   (top)
     |  y (back)
     | /
     |/
     +----- x (right)

Vertex and edge layout (heavier = and # indicate closer to viewer):

      3 +----------+ 7          +----10----+
       /:         /|           /:         /|
      / :        / |          1 2        5 6
   1 +==========+5 |         +=====9====+  |
     # 2+ - - - # -+ 6       #  +- - 11-# -+
     # /        # /          0 3        4 7
     #/         #/           #/         #/
   0 +==========+ 4          +=====8=====+

z changes fastest, then y, then x.
*/

/// Pair of vertex indices for each edge on the voxel
_MCEdgeVertexIndices = [
    [0, 1],
    [1, 3],
    [3, 2],
    [2, 0],
    [4, 5],
    [5, 7],
    [7, 6],
    [6, 4],
    [0, 4],
    [1, 5],
    [3, 7],
    [2, 6]
];

/// For each of the 256 configurations of a marching cube, define a list of triangles, specified as triples of edge indices.
_MCTriangleTable = [
 [],
 [3,8,0],
 [1,0,9],
 [9,1,8,8,1,3],
 [3,2,11],
 [2,11,0,0,11,8],
 [1,0,9,3,2,11],
 [11,1,2,11,9,1,11,8,9],
 [10,2,1],
 [2,1,10,0,3,8],
 [0,9,2,2,9,10],
 [8,2,3,8,10,2,8,9,10],
 [1,10,3,3,10,11],
 [10,0,1,10,8,0,10,11,8],
 [9,3,0,9,11,3,9,10,11],
 [9,10,8,8,10,11],
 [7,4,8],
 [0,3,4,4,3,7],
 [0,9,1,4,8,7],
 [1,4,9,1,7,4,1,3,7],
 [11,3,2,8,7,4],
 [4,11,7,4,2,11,4,0,2],
 [3,2,11,0,9,1,4,8,7],
 [9,1,4,4,1,7,7,1,2,7,2,11],
 [7,4,8,1,10,2],
 [7,4,3,3,4,0,10,2,1],
 [10,2,9,9,2,0,7,4,8],
 [7,4,9,7,9,2,9,10,2,3,7,2],
 [1,10,3,3,10,11,4,8,7],
 [4,0,7,0,1,10,7,0,10,7,10,11],
 [7,4,8,9,3,0,9,11,3,9,10,11],
 [7,4,11,4,9,11,9,10,11],
 [5,9,4],
 [8,0,3,9,4,5],
 [1,0,5,5,0,4],
 [5,8,4,5,3,8,5,1,3],
 [3,2,11,5,9,4],
 [2,11,0,0,11,8,5,9,4],
 [4,5,0,0,5,1,11,3,2],
 [11,8,2,8,4,5,2,8,5,2,5,1],
 [5,9,4,1,10,2],
 [0,3,8,1,10,2,5,9,4],
 [2,5,10,2,4,5,2,0,4],
 [4,5,8,8,5,3,3,5,10,3,10,2],
 [11,3,10,10,3,1,4,5,9],
 [4,5,9,10,0,1,10,8,0,10,11,8],
 [4,5,10,4,10,3,10,11,3,0,4,3],
 [4,5,8,5,10,8,10,11,8],
 [5,9,7,7,9,8],
 [3,9,0,3,5,9,3,7,5],
 [7,0,8,7,1,0,7,5,1],
 [3,7,1,1,7,5],
 [5,9,7,7,9,8,2,11,3],
 [5,9,0,5,0,11,0,2,11,7,5,11],
 [2,11,3,7,0,8,7,1,0,7,5,1],
 [2,11,1,11,7,1,7,5,1],
 [8,7,9,9,7,5,2,1,10],
 [10,2,1,3,9,0,3,5,9,3,7,5],
 [2,0,10,0,8,7,10,0,7,10,7,5],
 [10,2,5,2,3,5,3,7,5],
 [5,9,8,5,8,7,1,10,3,10,11,3],
 [1,10,0,0,10,11,0,11,7,0,7,5,0,5,9],
 [8,7,0,0,7,5,0,5,10,0,10,11,0,11,3],
 [5,11,7,10,11,5],
 [11,6,7],
 [3,8,0,7,11,6],
 [1,0,9,7,11,6],
 [9,1,8,8,1,3,6,7,11],
 [6,7,2,2,7,3],
 [0,7,8,0,6,7,0,2,6],
 [6,7,2,2,7,3,9,1,0],
 [9,1,2,9,2,7,2,6,7,8,9,7],
 [10,2,1,11,6,7],
 [2,1,10,3,8,0,7,11,6],
 [0,9,2,2,9,10,7,11,6],
 [6,7,11,8,2,3,8,10,2,8,9,10],
 [7,10,6,7,1,10,7,3,1],
 [1,10,0,0,10,8,8,10,6,8,6,7],
 [9,10,0,10,6,7,0,10,7,0,7,3],
 [6,7,10,7,8,10,8,9,10],
 [4,8,6,6,8,11],
 [6,3,11,6,0,3,6,4,0],
 [11,6,8,8,6,4,1,0,9],
 [6,4,11,4,9,1,11,4,1,11,1,3],
 [2,8,3,2,4,8,2,6,4],
 [0,2,4,4,2,6],
 [9,1,0,2,8,3,2,4,8,2,6,4],
 [9,1,4,1,2,4,2,6,4],
 [4,8,6,6,8,11,1,10,2],
 [1,10,2,6,3,11,6,0,3,6,4,0],
 [0,9,10,0,10,2,4,8,6,8,11,6],
 [11,6,3,3,6,4,3,4,9,3,9,10,3,10,2],
 [1,10,6,1,6,8,6,4,8,3,1,8],
 [1,10,0,10,6,0,6,4,0],
 [0,9,3,3,9,10,3,10,6,3,6,4,3,4,8],
 [4,10,6,9,10,4],
 [4,5,9,6,7,11],
 [7,11,6,8,0,3,9,4,5],
 [1,0,5,5,0,4,11,6,7],
 [11,6,7,5,8,4,5,3,8,5,1,3],
 [3,2,7,7,2,6,9,4,5],
 [5,9,4,0,7,8,0,6,7,0,2,6],
 [1,0,4,1,4,5,3,2,7,2,6,7],
 [4,5,8,8,5,1,8,1,2,8,2,6,8,6,7],
 [6,7,11,5,9,4,1,10,2],
 [5,9,4,7,11,6,0,3,8,2,1,10],
 [7,11,6,2,5,10,2,4,5,2,0,4],
 [6,7,11,3,8,4,3,4,5,3,5,2,2,5,10],
 [9,4,5,7,10,6,7,1,10,7,3,1],
 [5,9,4,8,0,1,8,1,10,8,10,7,7,10,6],
 [6,7,10,10,7,3,10,3,0,10,0,4,10,4,5],
 [4,5,8,8,5,10,8,10,6,8,6,7],
 [9,6,5,9,11,6,9,8,11],
 [0,3,9,9,3,5,5,3,11,5,11,6],
 [1,0,8,1,8,6,8,11,6,5,1,6],
 [11,6,3,6,5,3,5,1,3],
 [2,6,3,6,5,9,3,6,9,3,9,8],
 [5,9,6,9,0,6,0,2,6],
 [3,2,8,8,2,6,8,6,5,8,5,1,8,1,0],
 [1,6,5,2,6,1],
 [2,1,10,9,6,5,9,11,6,9,8,11],
 [2,1,10,5,9,0,5,0,3,5,3,6,6,3,11],
 [10,2,5,5,2,0,5,0,8,5,8,11,5,11,6],
 [10,2,5,5,2,3,5,3,11,5,11,6],
 [5,9,6,6,9,8,6,8,3,6,3,1,6,1,10],
 [5,9,6,6,9,0,6,0,1,6,1,10],
 [8,3,0,5,10,6],
 [6,5,10],
 [6,10,5],
 [3,8,0,5,6,10],
 [9,1,0,10,5,6],
 [3,8,1,1,8,9,6,10,5],
 [6,10,5,2,11,3],
 [8,0,11,11,0,2,5,6,10],
 [10,5,6,1,0,9,3,2,11],
 [5,6,10,11,1,2,11,9,1,11,8,9],
 [2,1,6,6,1,5],
 [5,6,1,1,6,2,8,0,3],
 [6,9,5,6,0,9,6,2,0],
 [8,9,3,9,5,6,3,9,6,3,6,2],
 [3,6,11,3,5,6,3,1,5],
 [5,6,11,5,11,0,11,8,0,1,5,0],
 [0,9,3,3,9,11,11,9,5,11,5,6],
 [5,6,9,6,11,9,11,8,9],
 [7,4,8,5,6,10],
 [0,3,4,4,3,7,10,5,6],
 [4,8,7,9,1,0,10,5,6],
 [6,10,5,1,4,9,1,7,4,1,3,7],
 [11,3,2,7,4,8,5,6,10],
 [10,5,6,4,11,7,4,2,11,4,0,2],
 [7,4,8,3,2,11,9,1,0,10,5,6],
 [10,5,6,7,4,9,7,9,1,7,1,11,11,1,2],
 [2,1,6,6,1,5,8,7,4],
 [7,4,0,7,0,3,5,6,1,6,2,1],
 [8,7,4,6,9,5,6,0,9,6,2,0],
 [5,6,9,9,6,2,9,2,3,9,3,7,9,7,4],
 [4,8,7,3,6,11,3,5,6,3,1,5],
 [7,4,11,11,4,0,11,0,1,11,1,5,11,5,6],
 [4,8,7,11,3,0,11,0,9,11,9,6,6,9,5],
 [5,6,9,9,6,11,9,11,7,9,7,4],
 [9,4,10,10,4,6],
 [6,10,4,4,10,9,3,8,0],
 [0,10,1,0,6,10,0,4,6],
 [3,8,4,3,4,10,4,6,10,1,3,10],
 [9,4,10,10,4,6,3,2,11],
 [8,0,2,8,2,11,9,4,10,4,6,10],
 [11,3,2,0,10,1,0,6,10,0,4,6],
 [2,11,1,1,11,8,1,8,4,1,4,6,1,6,10],
 [4,1,9,4,2,1,4,6,2],
 [3,8,0,4,1,9,4,2,1,4,6,2],
 [4,6,0,0,6,2],
 [3,8,2,8,4,2,4,6,2],
 [3,1,11,1,9,4,11,1,4,11,4,6],
 [9,4,1,1,4,6,1,6,11,1,11,8,1,8,0],
 [11,3,6,3,0,6,0,4,6],
 [8,6,11,4,6,8],
 [10,7,6,10,8,7,10,9,8],
 [10,9,6,9,0,3,6,9,3,6,3,7],
 [8,7,0,0,7,1,1,7,6,1,6,10],
 [6,10,7,10,1,7,1,3,7],
 [3,2,11,10,7,6,10,8,7,10,9,8],
 [6,10,7,7,10,9,7,9,0,7,0,2,7,2,11],
 [11,3,2,1,0,8,1,8,7,1,7,10,10,7,6],
 [6,10,7,7,10,1,7,1,2,7,2,11],
 [8,7,6,8,6,1,6,2,1,9,8,1],
 [0,3,9,9,3,7,9,7,6,9,6,2,9,2,1],
 [8,7,0,7,6,0,6,2,0],
 [7,2,3,6,2,7],
 [11,3,6,6,3,1,6,1,9,6,9,8,6,8,7],
 [11,7,6,1,9,0],
 [11,3,6,6,3,0,6,0,8,6,8,7],
 [11,7,6],
 [10,5,11,11,5,7],
 [10,5,11,11,5,7,0,3,8],
 [7,11,5,5,11,10,0,9,1],
 [3,8,9,3,9,1,7,11,5,11,10,5],
 [5,2,10,5,3,2,5,7,3],
 [0,2,8,2,10,5,8,2,5,8,5,7],
 [0,9,1,5,2,10,5,3,2,5,7,3],
 [10,5,2,2,5,7,2,7,8,2,8,9,2,9,1],
 [1,11,2,1,7,11,1,5,7],
 [8,0,3,1,11,2,1,7,11,1,5,7],
 [0,9,5,0,5,11,5,7,11,2,0,11],
 [3,8,2,2,8,9,2,9,5,2,5,7,2,7,11],
 [5,7,1,1,7,3],
 [8,0,7,0,1,7,1,5,7],
 [0,9,3,9,5,3,5,7,3],
 [9,7,8,5,7,9],
 [8,5,4,8,10,5,8,11,10],
 [10,5,4,10,4,3,4,0,3,11,10,3],
 [1,0,9,8,5,4,8,10,5,8,11,10],
 [9,1,4,4,1,3,4,3,11,4,11,10,4,10,5],
 [10,5,2,2,5,3,3,5,4,3,4,8],
 [10,5,2,5,4,2,4,0,2],
 [9,1,0,3,2,10,3,10,5,3,5,8,8,5,4],
 [10,5,2,2,5,4,2,4,9,2,9,1],
 [1,5,2,5,4,8,2,5,8,2,8,11],
 [2,1,11,11,1,5,11,5,4,11,4,0,11,0,3],
 [4,8,5,5,8,11,5,11,2,5,2,0,5,0,9],
 [5,4,9,2,3,11],
 [4,8,5,8,3,5,3,1,5],
 [0,5,4,1,5,0],
 [0,9,3,3,9,5,3,5,4,3,4,8],
 [5,4,9],
 [11,4,7,11,9,4,11,10,9],
 [0,3,8,11,4,7,11,9,4,11,10,9],
 [0,4,1,4,7,11,1,4,11,1,11,10],
 [7,11,4,4,11,10,4,10,1,4,1,3,4,3,8],
 [9,4,7,9,7,2,7,3,2,10,9,2],
 [8,0,7,7,0,2,7,2,10,7,10,9,7,9,4],
 [1,0,10,10,0,4,10,4,7,10,7,3,10,3,2],
 [7,8,4,10,1,2],
 [9,4,1,1,4,2,2,4,7,2,7,11],
 [8,0,3,2,1,9,2,9,4,2,4,11,11,4,7],
 [7,11,4,11,2,4,2,0,4],
 [3,8,2,2,8,4,2,4,7,2,7,11],
 [9,4,1,4,7,1,7,3,1],
 [9,4,1,1,4,7,1,7,8,1,8,0],
 [3,4,7,0,4,3],
 [7,8,4],
 [8,11,9,9,11,10],
 [0,3,9,3,11,9,11,10,9],
 [1,0,10,0,8,10,8,11,10],
 [10,3,11,1,3,10],
 [3,2,8,2,10,8,10,9,8],
 [9,2,10,0,2,9],
 [1,0,10,10,0,8,10,8,3,10,3,2],
 [2,10,1],
 [2,1,11,1,9,11,9,8,11],
 [2,1,11,11,1,9,11,9,0,11,0,3],
 [11,0,8,2,0,11],
 [3,11,2],
 [1,8,3,9,8,1],
 [1,9,0],
 [8,3,0],
 []
];

/// Same list as above, but with each row in reverse order. Needed for generating shells (two isosurfaces at slightly different iso values).
/// It is more efficient to have this static table than to call reverse() repeatedly while triangulating (although this static table was generated that way).
_MCTriangleTable_reverse = [
 [],
 [0,8,3],
 [9,0,1],
 [3,1,8,8,1,9],
 [11,2,3],
 [8,11,0,0,11,2],
 [11,2,3,9,0,1],
 [9,8,11,1,9,11,2,1,11],
 [1,2,10],
 [8,3,0,10,1,2],
 [10,9,2,2,9,0],
 [10,9,8,2,10,8,3,2,8],
 [11,10,3,3,10,1],
 [8,11,10,0,8,10,1,0,10],
 [11,10,9,3,11,9,0,3,9],
 [11,10,8,8,10,9],
 [8,4,7],
 [7,3,4,4,3,0],
 [7,8,4,1,9,0],
 [7,3,1,4,7,1,9,4,1],
 [4,7,8,2,3,11],
 [2,0,4,11,2,4,7,11,4],
 [7,8,4,1,9,0,11,2,3],
 [11,2,7,2,1,7,7,1,4,4,1,9],
 [2,10,1,8,4,7],
 [1,2,10,0,4,3,3,4,7],
 [8,4,7,0,2,9,9,2,10],
 [2,7,3,2,10,9,2,9,7,9,4,7],
 [7,8,4,11,10,3,3,10,1],
 [11,10,7,10,0,7,10,1,0,7,0,4],
 [11,10,9,3,11,9,0,3,9,8,4,7],
 [11,10,9,11,9,4,11,4,7],
 [4,9,5],
 [5,4,9,3,0,8],
 [4,0,5,5,0,1],
 [3,1,5,8,3,5,4,8,5],
 [4,9,5,11,2,3],
 [4,9,5,8,11,0,0,11,2],
 [2,3,11,1,5,0,0,5,4],
 [1,5,2,5,8,2,5,4,8,2,8,11],
 [2,10,1,4,9,5],
 [4,9,5,2,10,1,8,3,0],
 [4,0,2,5,4,2,10,5,2],
 [2,10,3,10,5,3,3,5,8,8,5,4],
 [9,5,4,1,3,10,10,3,11],
 [8,11,10,0,8,10,1,0,10,9,5,4],
 [3,4,0,3,11,10,3,10,4,10,5,4],
 [8,11,10,8,10,5,8,5,4],
 [8,9,7,7,9,5],
 [5,7,3,9,5,3,0,9,3],
 [1,5,7,0,1,7,8,0,7],
 [5,7,1,1,7,3],
 [3,11,2,8,9,7,7,9,5],
 [11,5,7,11,2,0,11,0,5,0,9,5],
 [1,5,7,0,1,7,8,0,7,3,11,2],
 [1,5,7,1,7,11,1,11,2],
 [10,1,2,5,7,9,9,7,8],
 [5,7,3,9,5,3,0,9,3,1,2,10],
 [5,7,10,7,0,10,7,8,0,10,0,2],
 [5,7,3,5,3,2,5,2,10],
 [3,11,10,3,10,1,7,8,5,8,9,5],
 [9,5,0,5,7,0,7,11,0,11,10,0,0,10,1],
 [3,11,0,11,10,0,10,5,0,5,7,0,0,7,8],
 [5,11,10,7,11,5],
 [7,6,11],
 [6,11,7,0,8,3],
 [6,11,7,9,0,1],
 [11,7,6,3,1,8,8,1,9],
 [3,7,2,2,7,6],
 [6,2,0,7,6,0,8,7,0],
 [0,1,9,3,7,2,2,7,6],
 [7,9,8,7,6,2,7,2,9,2,1,9],
 [7,6,11,1,2,10],
 [6,11,7,0,8,3,10,1,2],
 [6,11,7,10,9,2,2,9,0],
 [10,9,8,2,10,8,3,2,8,11,7,6],
 [1,3,7,10,1,7,6,10,7],
 [7,6,8,6,10,8,8,10,0,0,10,1],
 [3,7,0,7,10,0,7,6,10,0,10,9],
 [10,9,8,10,8,7,10,7,6],
 [11,8,6,6,8,4],
 [0,4,6,3,0,6,11,3,6],
 [9,0,1,4,6,8,8,6,11],
 [3,1,11,1,4,11,1,9,4,11,4,6],
 [4,6,2,8,4,2,3,8,2],
 [6,2,4,4,2,0],
 [4,6,2,8,4,2,3,8,2,0,1,9],
 [4,6,2,4,2,1,4,1,9],
 [2,10,1,11,8,6,6,8,4],
 [0,4,6,3,0,6,11,3,6,2,10,1],
 [6,11,8,6,8,4,2,10,0,10,9,0],
 [2,10,3,10,9,3,9,4,3,4,6,3,3,6,11],
 [8,1,3,8,4,6,8,6,1,6,10,1],
 [0,4,6,0,6,10,0,10,1],
 [8,4,3,4,6,3,6,10,3,10,9,3,3,9,0],
 [4,10,9,6,10,4],
 [11,7,6,9,5,4],
 [5,4,9,3,0,8,6,11,7],
 [7,6,11,4,0,5,5,0,1],
 [3,1,5,8,3,5,4,8,5,7,6,11],
 [5,4,9,6,2,7,7,2,3],
 [6,2,0,7,6,0,8,7,0,4,9,5],
 [7,6,2,7,2,3,5,4,1,4,0,1],
 [7,6,8,6,2,8,2,1,8,1,5,8,8,5,4],
 [2,10,1,4,9,5,11,7,6],
 [10,1,2,8,3,0,6,11,7,4,9,5],
 [4,0,2,5,4,2,10,5,2,6,11,7],
 [10,5,2,2,5,3,5,4,3,4,8,3,11,7,6],
 [1,3,7,10,1,7,6,10,7,5,4,9],
 [6,10,7,7,10,8,10,1,8,1,0,8,4,9,5],
 [5,4,10,4,0,10,0,3,10,3,7,10,10,7,6],
 [7,6,8,6,10,8,10,5,8,8,5,4],
 [11,8,9,6,11,9,5,6,9],
 [6,11,5,11,3,5,5,3,9,9,3,0],
 [6,1,5,6,11,8,6,8,1,8,0,1],
 [3,1,5,3,5,6,3,6,11],
 [8,9,3,9,6,3,9,5,6,3,6,2],
 [6,2,0,6,0,9,6,9,5],
 [0,1,8,1,5,8,5,6,8,6,2,8,8,2,3],
 [1,6,2,5,6,1],
 [11,8,9,6,11,9,5,6,9,10,1,2],
 [11,3,6,6,3,5,3,0,5,0,9,5,10,1,2],
 [6,11,5,11,8,5,8,0,5,0,2,5,5,2,10],
 [6,11,5,11,3,5,3,2,5,5,2,10],
 [10,1,6,1,3,6,3,8,6,8,9,6,6,9,5],
 [10,1,6,1,0,6,0,9,6,6,9,5],
 [6,10,5,0,3,8],
 [10,5,6],
 [5,10,6],
 [10,6,5,0,8,3],
 [6,5,10,0,1,9],
 [5,10,6,9,8,1,1,8,3],
 [3,11,2,5,10,6],
 [10,6,5,2,0,11,11,0,8],
 [11,2,3,9,0,1,6,5,10],
 [9,8,11,1,9,11,2,1,11,10,6,5],
 [5,1,6,6,1,2],
 [3,0,8,2,6,1,1,6,5],
 [0,2,6,9,0,6,5,9,6],
 [2,6,3,6,9,3,6,5,9,3,9,8],
 [5,1,3,6,5,3,11,6,3],
 [0,5,1,0,8,11,0,11,5,11,6,5],
 [6,5,11,5,9,11,11,9,3,3,9,0],
 [9,8,11,9,11,6,9,6,5],
 [10,6,5,8,4,7],
 [6,5,10,7,3,4,4,3,0],
 [6,5,10,0,1,9,7,8,4],
 [7,3,1,4,7,1,9,4,1,5,10,6],
 [10,6,5,8,4,7,2,3,11],
 [2,0,4,11,2,4,7,11,4,6,5,10],
 [6,5,10,0,1,9,11,2,3,8,4,7],
 [2,1,11,11,1,7,1,9,7,9,4,7,6,5,10],
 [4,7,8,5,1,6,6,1,2],
 [1,2,6,1,6,5,3,0,7,0,4,7],
 [0,2,6,9,0,6,5,9,6,4,7,8],
 [4,7,9,7,3,9,3,2,9,2,6,9,9,6,5],
 [5,1,3,6,5,3,11,6,3,7,8,4],
 [6,5,11,5,1,11,1,0,11,0,4,11,11,4,7],
 [5,9,6,6,9,11,9,0,11,0,3,11,7,8,4],
 [4,7,9,7,11,9,11,6,9,9,6,5],
 [6,4,10,10,4,9],
 [0,8,3,9,10,4,4,10,6],
 [6,4,0,10,6,0,1,10,0],
 [10,3,1,10,6,4,10,4,3,4,8,3],
 [11,2,3,6,4,10,10,4,9],
 [10,6,4,10,4,9,11,2,8,2,0,8],
 [6,4,0,10,6,0,1,10,0,2,3,11],
 [10,6,1,6,4,1,4,8,1,8,11,1,1,11,2],
 [2,6,4,1,2,4,9,1,4],
 [2,6,4,1,2,4,9,1,4,0,8,3],
 [2,6,0,0,6,4],
 [2,6,4,2,4,8,2,8,3],
 [6,4,11,4,1,11,4,9,1,11,1,3],
 [0,8,1,8,11,1,11,6,1,6,4,1,1,4,9],
 [6,4,0,6,0,3,6,3,11],
 [8,6,4,11,6,8],
 [8,9,10,7,8,10,6,7,10],
 [7,3,6,3,9,6,3,0,9,6,9,10],
 [10,6,1,6,7,1,1,7,0,0,7,8],
 [7,3,1,7,1,10,7,10,6],
 [8,9,10,7,8,10,6,7,10,11,2,3],
 [11,2,7,2,0,7,0,9,7,9,10,7,7,10,6],
 [6,7,10,10,7,1,7,8,1,8,0,1,2,3,11],
 [11,2,7,2,1,7,1,10,7,7,10,6],
 [1,8,9,1,2,6,1,6,8,6,7,8],
 [1,2,9,2,6,9,6,7,9,7,3,9,9,3,0],
 [0,2,6,0,6,7,0,7,8],
 [7,2,6,3,2,7],
 [7,8,6,8,9,6,9,1,6,1,3,6,6,3,11],
 [0,9,1,6,7,11],
 [7,8,6,8,0,6,0,3,6,6,3,11],
 [6,7,11],
 [7,5,11,11,5,10],
 [8,3,0,7,5,11,11,5,10],
 [1,9,0,10,11,5,5,11,7],
 [5,10,11,5,11,7,1,9,3,9,8,3],
 [3,7,5,2,3,5,10,2,5],
 [7,5,8,5,2,8,5,10,2,8,2,0],
 [3,7,5,2,3,5,10,2,5,1,9,0],
 [1,9,2,9,8,2,8,7,2,7,5,2,2,5,10],
 [7,5,1,11,7,1,2,11,1],
 [7,5,1,11,7,1,2,11,1,3,0,8],
 [11,0,2,11,7,5,11,5,0,5,9,0],
 [11,7,2,7,5,2,5,9,2,9,8,2,2,8,3],
 [3,7,1,1,7,5],
 [7,5,1,7,1,0,7,0,8],
 [3,7,5,3,5,9,3,9,0],
 [9,7,5,8,7,9],
 [10,11,8,5,10,8,4,5,8],
 [3,10,11,3,0,4,3,4,10,4,5,10],
 [10,11,8,5,10,8,4,5,8,9,0,1],
 [5,10,4,10,11,4,11,3,4,3,1,4,4,1,9],
 [8,4,3,4,5,3,3,5,2,2,5,10],
 [2,0,4,2,4,5,2,5,10],
 [4,5,8,8,5,3,5,10,3,10,2,3,0,1,9],
 [1,9,2,9,4,2,4,5,2,2,5,10],
 [11,8,2,8,5,2,8,4,5,2,5,1],
 [3,0,11,0,4,11,4,5,11,5,1,11,11,1,2],
 [9,0,5,0,2,5,2,11,5,11,8,5,5,8,4],
 [11,3,2,9,4,5],
 [5,1,3,5,3,8,5,8,4],
 [0,5,1,4,5,0],
 [8,4,3,4,5,3,5,9,3,3,9,0],
 [9,4,5],
 [9,10,11,4,9,11,7,4,11],
 [9,10,11,4,9,11,7,4,11,8,3,0],
 [10,11,1,11,4,1,11,7,4,1,4,0],
 [8,3,4,3,1,4,1,10,4,10,11,4,4,11,7],
 [2,9,10,2,3,7,2,7,9,7,4,9],
 [4,9,7,9,10,7,10,2,7,2,0,7,7,0,8],
 [2,3,10,3,7,10,7,4,10,4,0,10,10,0,1],
 [2,1,10,4,8,7],
 [11,7,2,7,4,2,2,4,1,1,4,9],
 [7,4,11,11,4,2,4,9,2,9,1,2,3,0,8],
 [4,0,2,4,2,11,4,11,7],
 [11,7,2,7,4,2,4,8,2,2,8,3],
 [1,3,7,1,7,4,1,4,9],
 [0,8,1,8,7,1,7,4,1,1,4,9],
 [3,4,0,7,4,3],
 [4,8,7],
 [10,11,9,9,11,8],
 [9,10,11,9,11,3,9,3,0],
 [10,11,8,10,8,0,10,0,1],
 [10,3,1,11,3,10],
 [8,9,10,8,10,2,8,2,3],
 [9,2,0,10,2,9],
 [2,3,10,3,8,10,8,0,10,10,0,1],
 [1,10,2],
 [11,8,9,11,9,1,11,1,2],
 [3,0,11,0,9,11,9,1,11,11,1,2],
 [11,0,2,8,0,11],
 [2,11,3],
 [1,8,9,3,8,1],
 [0,9,1],
 [0,3,8],
 []
];

/// _cubindex() - private function, called by _isosurface_cubes()
/// Return the index ID of a voxel depending on the field strength at each corner exceeding isoval.
function _cubeindex(f, isoval) =
    (f[0] >= isoval ? 1 : 0) +
    (f[1] >= isoval ? 2 : 0) +
    (f[2] >= isoval ? 4 : 0) +
    (f[3] >= isoval ? 8 : 0) +
    (f[4] >= isoval ? 16 : 0) +
    (f[5] >= isoval ? 32 : 0) +
    (f[6] >= isoval ? 64 : 0) +
    (f[7] >= isoval ? 128 : 0);

/*
-----------------------------------------------------------
Bounding box clipping support:

Vertex and face layout for triangulating one voxel face that corrsesponds to a side of the box bounding all voxels.

                    4(back)
               3 +----------+ 7
                /:  5(top) /|
               / :        / |
            1 +==========+5 |    <-- 3(side)
0(side) -->   # 2+ - - - # -+ 6
              # /        # /
              #/  2(bot) #/
            0 +----------+ 4
                1(front)

The clip face uses different indexing. After vertex coordinates and function values are assigned to each corner from the original voxel based on _MCFaceVertexIndices below, this is the clip face diagram:

(1)           (2)
   +----1----+
   |         |
   0         2
   |         |
   +----3----+
(0)           (3)
*/

/// four indices for each face of the cube, counterclockwise looking from inside out
_MCFaceVertexIndices = [
  [],
  [0,2,3,1], // left, x=0 plane
  [0,1,5,4], // front, y=0 plane
  [0,4,6,2], // bottom, z=0 plane
  [4,5,7,6], // right, x=voxsize plane
  [2,6,7,3], // back, y=voxsize plane
  [1,3,7,5], // top, z=voxsize plane
];

/// Pair of vertex indices for each edge on the clip face (using clip face indexing)
_MCClipEdgeVertexIndices = [
  [0,1], [1,2], [2,3], [3,0]
];

/// In keeping with the convention for triangulating an isosurface through a voxel, analogous to the case in which two surfaces separate two diagonally opposite high-value corners of one face, in 2D contour terms it is assumed there is a valley separating two high corners, not a ridge connecting them. The 8 ambiguous triangulation cases for opposing corners are set up accordingly. These are the rotational groups of indices {10,30}, {11,19,33,57}, {20,60} in the array below.
/// For each of the 81 possible configurations of a clip face intersected by a minimum and/or maximum isovalue, define a list of triangles, specified as pairs of corner ID and edge ID arrays, with a total of 3 points in each pair. Each pair has the form [corner],[edge1,edge2] or [corner1,corner2],[edge], or [corner1,corner2,corner3],[] or [],[edge1,edge2,edge3].
_MCClipTriangleTable = [
// Explanation of inline comments:
// "base-3 index = decimal index", followed by
//   "(xRotations)" for number of rotation versions, or
//   "(Rotation n from decimal index)" indicating which decimal index this was rotated from, where n=the number of 90° clockwise rotations from the original.
 [], // 0000 = 0 (×1)
 [[0],[0,3]], // 0001 = 1 (×4)
 [[],[7,4,3,3,4,0]], // 0002 = 2 (×4)
 [[1],[1,0]], // 0010 = 3 (r1 from 1)
 [[0,1],[1],[0],[1,3]], // 0011 = 4 (×4)
 [[1],[1,4],[],[4,3,7],[],[4,1,3]], // 0012 = 5 (×4)
 [[],[4,5,0,0,5,1]], // 0020 = 6 (r1 from 2)
 [[0],[4,3],[],[4,5,1],[],[4,1,3]], // 0021 = 7 (×4)
 [[],[7,5,1,1,3,7]], // 0022 = 8 (×4)
 [[2],[2,1]], // 0100 = 9 (r2 from 1)
 [[0],[0,3],[2],[2,1]], // 0101 = 10 (×2)
 [[],[7,4,3,3,4,0],[2],[2,1]], // 0102 = 11 (×4)
 [[1,2],[2],[1],[2,0]], // 0110 = 12 (r1 from 4)
 [[0,1],[3],[1],[2,3],[1,2],[2]], // 0111 = 13 (×4)
 [[1,2],[4],[2],[2,4],[],[2,3,7],[],[2,7,4]], // 0112 = 14 (×4)
 [[2],[2,5],[],[5,0,4],[],[5,2,0]], // 0120 = 15 (r1 from 5)
 [[0],[4,3],[2],[2,5],[],[4,5,2],[],[2,3,4]], // 0121 = 16 (×4)
 [[2],[2,5],[],[2,3,7],[],[5,2,7]], // 0122 = 17 (×4)
 [[],[5,6,1,1,6,2]], // 0200 = 18 (r2 from 2)
 [[],[5,6,1,1,6,2],[0],[0,3]], // 0201 = 19 (r2 from 11)
 [[],[7,4,0],[],[0,3,7],[],[1,5,6],[],[6,2,1]], // 0202 = 20 (×2)
 [[1],[5,0],[],[5,6,2],[],[5,2,0]], // 0210 = 21 (r1 from 7)
 [[0,1],[3],[1],[5,3],[],[3,5,2],[],[5,6,2]], // 0211 = 22 (×4)
 [[1],[5,4],[],[5,6,7],[],[6,2,3],[],[6,3,7],[],[7,4,5]], // 0212 = 23 (×4)
 [[],[4,6,2,2,0,4]], // 0220 = 24 (r1 from 8)
 [[0],[4,3],[],[3,4,6],[],[6,2,3]], // 0221 = 25 (×4)
 [[],[2,3,7,2,7,6]], // 0222 = 26 (×4)
 [[3],[3,2]], // 1000 = 27 (r3 from 1)
 [[3,0],[0],[3],[0,2]], // 1001 = 28 (r3 from 4)
 [[3],[7,2],[],[7,4,0],[],[7,0,2]], // 1002 = 29 (r3 from 7)
 [[1],[1,0],[3],[3,2]], // 1010 = 30 (r1 from 10)
 [[3,0],[2],[0],[1,2],[0,1],[1]], // 1011 = 31 (r3 from 13)
 [[3],[7,2],[1],[1,4],[],[7,4,1],[],[1,2,7]], // 1012 = 32 (r3 from 16)
 [[],[4,5,0,0,5,1],[3],[3,2]], // 1020 = 33 (r1 from 11)
 [[3,0],[2],[0],[4,2],[],[2,4,1],[],[4,5,1]], // 1021 = 34 (r3 from 22)
 [[3],[7,2],[],[2,7,5],[],[5,1,2]], // 1022 = 35 (r3 from 25)
 [[2,3],[3],[2],[3,1]], // 1100 = 36 (r2 from 4)
 [[2,3],[1],[3],[0,1],[3,0],[0]], // 1101 = 37 (r2 from 13)
 [[2,3],[1],[3],[7,1],[],[1,7,0],[],[7,4,0]], // 1102 = 38 (r2 from 22)
 [[1,2],[0],[2],[3,0],[2,3],[3]], // 1110 = 39 (r1 from 13)
 [[0,1,2],[],[0,2,3],[]], // 1111 = 40 (×1)
 [[1,2],[4],[2],[7,4],[2,3],[7]], // 1112 = 41 (×4)
 [[2,3],[5],[3],[3,5],[],[3,0,4],[],[3,4,5]], // 1120 = 42 (r1 from 14)
 [[2,3],[5],[3],[4,5],[3,0],[4]], // 1121 = 43 (r1 from 41)
 [[2],[7,5],[2,3],[7]], // 1122 = 44 (×4)
 [[3],[3,6],[],[6,1,5],[],[6,3,1]], // 1200 = 45 (r2 from 5)
 [[3,0],[6],[0],[0,6],[],[0,1,5],[],[0,5,6]], // 1201 = 46 (r2 from 14)
 [[3],[7,6],[],[7,4,5],[],[4,0,1],[],[4,1,5],[],[5,6,7]], // 1202 = 47 (r2 from 23)
 [[1],[5,0],[3],[3,6],[],[5,6,3],[],[3,0,5]], // 1210 = 48 (r1 from 16)
 [[3,0],[6],[0],[5,6],[0,1],[5]], // 1211 = 49 (r2 from 41)
 [[1],[5,4],[3],[7,6],[],[4,5,6],[],[4,6,7]], // 1212 = 50 (×2)
 [[3],[3,6],[],[3,0,4],[],[6,3,4]], // 1220 = 51 (r1 from 17)
 [[3],[4,6],[3,0],[4]], // 1221 = 52 (r1 from 44)
 [[3],[7,6]], // 1222 = 53 (×4)
 [[],[6,7,2,2,7,3]], // 2000 = 54 (r3 from 2)
 [[0],[0,7],[],[7,2,6],[],[7,0,2]], // 2001 = 55 (r3 from 5)
 [[],[6,4,0,0,2,6]], // 2002 = 56 (r3 from 8)
 [[],[6,7,2,2,7,3],[1],[1,0]], // 2010 = 57 (r3 from 11)
 [[0,1],[7],[1],[1,7],[],[1,2,6],[],[1,6,7]], // 2011 = 58 (r3 from 14)
 [[1],[1,4],[],[1,2,6],[],[4,1,6]], // 2012 = 59 (r3 from 17)
 [[],[4,5,1],[],[1,0,4],[],[2,6,7],[],[7,3,2]], // 2020 = 60 (r1 from 20)
 [[0],[4,7],[],[4,5,6],[],[5,1,2],[],[5,2,6],[],[6,7,4]], // 2021 = 61 (r3 from 23)
 [[],[1,2,6,1,6,5]], // 2022 = 62 (r3 from 26)
 [[2],[6,1],[],[6,7,3],[],[6,3,1]], // 2100 = 63 (r2 from 7)
 [[2],[6,1],[0],[0,7],[],[6,7,0],[],[0,1,6]], // 2101 = 64 (r2 from 16)
 [[2],[6,1],[],[1,6,4],[],[4,0,1]], // 2102 = 65 (r2 from 25)
 [[1,2],[0],[2],[6,0],[],[0,6,3],[],[6,7,3]], // 2110 = 66 (r1 from 22)
 [[0,1],[7],[1],[6,7],[1,2],[6]], // 2111 = 67 (r3 from 41)
 [[1],[6,4],[1,2],[6]], // 2112 = 68 (r3 from 44)
 [[2],[6,5],[],[6,7,4],[],[7,3,0],[],[7,0,4],[],[4,5,6]], // 2120 = 69 (r1 from 23)
 [[2],[6,5],[0],[4,7],[],[5,6,7],[],[5,7,4]], // 2121 = 70 (r1 from 50)
 [[2],[6,5]], // 2122 = 71 (r3 from 53)
 [[],[5,7,3,3,1,5]], // 2200 = 72 (r2 from 8)
 [[0],[0,7],[],[0,1,5],[],[7,0,5]], // 2201 = 73 (r2 from 17)
 [[],[0,1,5,0,5,4]], // 2202 = 74 (r2 from 26)
 [[1],[5,0],[],[0,5,7],[],[7,3,0]], // 2210 = 75 (r1 from 25)
 [[0],[5,7],[0,1],[5]], // 2211 = 76 (r2 from 44)
 [[1],[5,4]], // 2212 = 77 (r2 from 53)
 [[],[3,0,4,3,4,7]], // 2220 = 78 (r1 from 26)
 [[0],[4,7]], // 2221 = 79 (r1 from 53)
 [] // 2222 = 80 (×1)
];

/// _clipfacindex() - private function, called by _clipfacevertices()
/// Return the index ID of a voxel face depending on the field strength at each corner in relation to isovalmin and isovalmax.
// Returns a decimal version of a 4-digit base-3 index.
function _clipfacindex(f, isovalmin, isovalmax) =
    (f[0] >= isovalmax ? 2 : f[0] >= isovalmin ? 1 : 0) +
    (f[1] >= isovalmax ? 6 : f[1] >= isovalmin ? 3 : 0) +
    (f[2] >= isovalmax ? 18 : f[2] >= isovalmin ? 9 : 0) +
    (f[3] >= isovalmax ? 54 : f[3] >= isovalmin ? 27 : 0);

/// return an array of face indices in _MCFaceVertexIndices if the voxel at coordinate v0 corresponds to the bounding box. voxsize is a 3-vector.
function _bbox_faces(v0, voxsize, bbox) = let(
    a = v_abs(v0-bbox[0]),
    bb1 = bbox[1] - voxsize,
    b = v0-bb1
) [
    if(a[0]<EPSILON) 1,
    if(a[1]<EPSILON) 2,
    if(a[2]<EPSILON) 3,
    if(b[0]>=-EPSILON) 4,
    if(b[1]>=-EPSILON) 5,
    if(b[2]>=-EPSILON) 6
];
/// End of bounding-box face-clipping stuff
/// -----------------------------------------------------------


/// isosurface_cubes() - private function, called by isosurface()
/// This implements a marching cubes algorithm, sacrificing some memory in favor of speed.
/// Return a list of voxel cube structures that have one or both surfaces isovalmin or isovalmax intersecting them, and cubes inside the isosurface volume that are at the bounds of the bounding box.
/// The cube structure is:
/// [cubecoord, cubeindex_isomin, cubeindex_isomax, cf, bfaces]
/// where
///     cubecoord is the [x,y,z] coordinate of the front left bottom corner of the voxel.
///     cubeindex_isomin and cubeindex_isomax are the index IDs of the voxel corresponding to the min and max iso surface intersections.
///     cf (corner function) is vector containing the 8 field strength values at each corner of the voxel cube.
///     bfaces is an array of faces corresponding to the sides of the bounding box - this is empty most of the time; it has data only where the isosurface is clipped by the bounding box.
/// The bounding box 'bbox' is expected to be quantized for the voxel size already, and `voxsize` is a 3-vector.

function _isosurface_cubes(voxsize, bbox, fieldarray, fieldfunc, isovalmin, isovalmax, closed=true) = let(
    // get field intensities
    field = is_def(fieldarray)
    ? fieldarray
    : let(v = bbox[0], hv = 0.5*voxsize, b1 = bbox[1]+hv) [
        for(x=[v.x:voxsize.x:b1.x]) [
            for(y=[v.y:voxsize.y:b1.y]) [
                for(z=[v.z:voxsize.z:b1.z])
                    fieldfunc(x,y,z)
            ]
        ]
    ],
    nx = len(field)-2,
    ny = len(field[0])-2,
    nz = len(field[0][0])-2,
    v0 = bbox[0]
) [
    for(i=[0:nx]) let(x=v0[0]+i*voxsize.x)
        for(j=[0:ny]) let(y=v0[1]+j*voxsize.y)
            for(k=[0:nz]) let(z=v0[2]+k*voxsize.z)
                let(i1=i+1, j1=j+1, k1=k+1,
                    cf = [  // cube corner field values clamped to ±1e9
                        min(1e9,max(-1e9,field[i][j][k])),
                        min(1e9,max(-1e9,field[i][j][k1])),
                        min(1e9,max(-1e9,field[i][j1][k])),
                        min(1e9,max(-1e9,field[i][j1][k1])),
                        min(1e9,max(-1e9,field[i1][j][k])),
                        min(1e9,max(-1e9,field[i1][j][k1])),
                        min(1e9,max(-1e9,field[i1][j1][k])),
                        min(1e9,max(-1e9,field[i1][j1][k1]))
                    ],
                    mincf = min(cf),
                    maxcf = max(cf),
                    cubecoord = [x,y,z],
                    bfaces = closed ? _bbox_faces(cubecoord, voxsize, bbox) : [],
                    cubefound_isomin = (mincf<=isovalmin && isovalmin<=maxcf),
                    cubefound_isomax = (mincf<=isovalmax && isovalmax<=maxcf),
                    cubefound_outer = len(bfaces)==0 ? false
                    : let(
                        bf = flatten([for(i=bfaces) _MCFaceVertexIndices[i]]),
                        sumcond = len([for(b=bf) if(isovalmin<=cf[b] && cf[b]<=isovalmax) 1 ])
                    ) sumcond == len(bf), // true if full faces are inside
                    cubeindex_isomin = cubefound_isomin ? _cubeindex(cf, isovalmin) : 0,
                    cubeindex_isomax = cubefound_isomax ? _cubeindex(cf, isovalmax) : 0
                ) if(cubefound_isomin || cubefound_isomax || cubefound_outer)
                    [ // return data structure:
                        cubecoord,          // voxel lower coordinate
                        cubeindex_isomin,   // cube ID for isomin
                        cubeindex_isomax,   // cube ID for isomax
                        cf,                 // clamped voxel corner values
                        bfaces              // list of bounding box faces, if any
                    ]
];


/// _isosurface_trangles() - called by isosurface()
/// Given a list of voxel cubes structures, triangulate the isosurface(s) that intersect each cube and return a list of triangle vertices.
function _isosurface_triangles(cubelist, voxsize, isovalmin, isovalmax, tritablemin, tritablemax) = [
    for(cl=cubelist)
        let(
            v = cl[0],          // voxel coord
            cbidxmin = cl[1],   // cube ID for isomvalmin
            cbidxmax = cl[2],   // cube ID for isovalmax
            f = cl[3],          // function values for each cube corner
            bbfaces = cl[4],    // faces (if any) on the bounding box
            vcube = [           // list of cube corner vertex coordinates
                v, v+[0,0,voxsize.z], v+[0,voxsize.y,0], v+[0,voxsize.y,voxsize.z],
                v+[voxsize.x,0,0], v+[voxsize.x,0,voxsize.z],
                v+[voxsize.x,voxsize.y,0], v+voxsize
            ]
        )
        each [
            if(len(tritablemin[cbidxmin])>0) for(ei=tritablemin[cbidxmin]) // min surface
                let(
                    edge = _MCEdgeVertexIndices[ei],
                    vi0 = edge[0],
                    vi1 = edge[1],
                    denom = f[vi1] - f[vi0],
                    u = abs(denom)<0.00001 ? 0.5 : (isovalmin-f[vi0]) / denom
                )
                vcube[vi0] + u*(vcube[vi1]-vcube[vi0]),
            if(len(tritablemax[cbidxmax])>0) for(ei=tritablemax[cbidxmax]) // max surface
                let(
                    edge = _MCEdgeVertexIndices[ei],
                    vi0 = edge[0],
                    vi1 = edge[1],
                    denom = f[vi1] - f[vi0],
                    u = abs(denom)<0.00001 ? 0.5 : (isovalmax-f[vi0]) / denom
                )
                vcube[vi0] + u*(vcube[vi1]-vcube[vi0]),
            if(len(bbfaces)>0) for(bf = bbfaces)
                  each _clipfacevertices(vcube, f, bf, isovalmin, isovalmax)
        ]
];


/// Generate triangles for the special case of voxel faces clipped by the bounding box
function _clipfacevertices(vcube, fld, bbface, isovalmin, isovalmax) =
    let(
        vi = _MCFaceVertexIndices[bbface], // four voxel face vertex indices
        vface = [ for(i=vi) vcube[i] ], // four voxel face vertex coordinates
        f = [ for(i=vi) fld[i] ],   // four corner field values
        idx = _clipfacindex(f, isovalmin, isovalmax)
    ) [
        if(idx>0 && idx<80)
            let(tri = _MCClipTriangleTable[idx])
                for(i=[0:2:len(tri)-1]) let(
                    cpath = tri[i],
                    epath = tri[i+1]
                ) each [
                    for(corner=cpath) vface[corner],
                    for(edge=epath) let(
                        iso = edge>3 ? isovalmax : isovalmin,
                        e = edge>3 ? edge-4 : edge,
                        v0 = e,
                        v1 = (e+1)%4,
                        denom = f[v1]-f[v0],
                        u = abs(denom)<0.00001 ? 0.5 : (iso-f[v0]) / denom
                    ) vface[v0] + u*(vface[v1]-vface[v0])
                ]
    ];



/// ---------- metaball stuff starts here ----------

/// Animated metaball demo made with BOSL2 here: https://imgur.com/a/m29q8Qd

/// Built-in metaball functions corresponding to each MB_ index.
/// For speed, they are split into four functions, each handling a different combination of influence != 1 or influence == 1, and cutoff < INF or cutoff == INF.
/// Each function returns a list: [function literal [sign, vnf]]

/// public metaball cutoff function if anyone wants it (demonstrated in example)

function mb_cutoff(dist, cutoff) = dist>=cutoff ? 0 : 0.5*(cos(180*(dist/cutoff)^4)+1);


/// metaball sphere

function _mb_sphere_basic(point, r, neg) = neg*r/norm(point);
function _mb_sphere_influence(point, r, ex, neg) = neg * (r/norm(point))^ex;
function _mb_sphere_cutoff(point, r, cutoff, neg) = let(dist=norm(point))
    neg * mb_cutoff(dist, cutoff) * r/dist;
function _mb_sphere_full(point, r, cutoff, ex, neg) = let(dist=norm(point))
    neg * mb_cutoff(dist, cutoff) * (r/dist)^ex;

function mb_sphere(r, cutoff=INF, influence=1, negative=false, hide_debug=false, d) =
    assert(is_num(cutoff) && cutoff>0, "\ncutoff must be a positive number.")
    assert(is_finite(influence) && influence>0, "\ninfluence must be a positive number.")
    let(
        r = get_radius(r=r,d=d),
        dummy=assert(is_finite(r) && r>0, "\ninvalid radius or diameter."),
        neg = negative ? -1 : 1,
        vnf = [neg, hide_debug ? debug_tetra(0.02) : sphere(r=r, $fn=20)]
    )
   !is_finite(cutoff) && influence==1 ? [function(point) _mb_sphere_basic(point,r,neg), vnf]
 : !is_finite(cutoff) ? [function (point) _mb_sphere_influence(point,r,1/influence, neg), vnf]
 : influence==1 ? [function (point) _mb_sphere_cutoff(point,r,cutoff,neg), vnf]
 : [function (point) _mb_sphere_full(point,r,cutoff,1/influence,neg), vnf];


/// metaball rounded cube

function _mb_cuboid_basic(point, inv_size, xp, neg) =
   let(
       point=inv_size * point,
       dist = xp >= 1100 ? max(v_abs(point))
                         : (abs(point.x)^xp + abs(point.y)^xp + abs(point.z)^xp) ^ (1/xp)
      ) neg/dist;
function _mb_cuboid_influence(point, inv_size, xp, ex, neg) = let(
    point = inv_size * point,
    dist = xp >= 1100 ? max(v_abs(point))
                      :(abs(point.x)^xp + abs(point.y)^xp + abs(point.z)^xp) ^ (1/xp)
) neg / dist^ex;
function _mb_cuboid_cutoff(point, inv_size, xp, cutoff, neg) = let(
    point = inv_size * point, 
    dist = xp >= 1100 ? max(v_abs(point))
                      : (abs(point.x)^xp + abs(point.y)^xp + abs(point.z)^xp) ^ (1/xp)
) neg * mb_cutoff(dist, cutoff) / dist;
function _mb_cuboid_full(point, inv_size, xp, ex, cutoff, neg) = let(
    point = inv_size * point,
    dist = xp >= 1100 ? max(v_abs(point))
                      :(abs(point.x)^xp + abs(point.y)^xp + abs(point.z)^xp) ^ (1/xp)
) neg * mb_cutoff(dist, cutoff) / dist^ex;

function mb_cuboid(size, squareness=0.5, cutoff=INF, influence=1, negative=false, hide_debug=false) =
   assert(is_num(cutoff) && cutoff>0, "\ncutoff must be a positive number.")
   assert(is_finite(influence) && influence>0, "\ninfluence must be a positive number.")
   assert(squareness>=0 && squareness<=1, "\nsquareness must be inside the range [0,1].")
   assert((is_finite(size) && size>0) || (is_vector(size) && all_positive(size)), "\nsize must be a positive number or a 3-vector of positive values.")
   let(
       xp = _squircle_se_exponent(squareness),
       neg = negative ? -1 : 1,
       inv_size = is_num(size) ? 2/size
                : [[2/size.x,0,0],[0,2/size.y,0],[0,0,2/size.z]],
        vnf=[neg, hide_debug ? debug_tetra(0.02) : _debug_cube(size,squareness)]
   )
   !is_finite(cutoff) && influence==1 ? [function(point) _mb_cuboid_basic(point, inv_size, xp, neg), vnf]
 : !is_finite(cutoff) ? [function(point) _mb_cuboid_influence(point, inv_size, xp, 1/influence, neg), vnf]
 : influence==1 ? [function(point) _mb_cuboid_cutoff(point, inv_size, xp, cutoff, neg), vnf]
 : [function (point) _mb_cuboid_full(point, inv_size, xp, 1/influence, cutoff, neg), vnf];


/// metaball rounded cylinder / cone

function _revsurf_basic(point, path, coef, neg, maxdist) =
    let(
         pt = [norm([point.x,point.y]), point.z],
         segs = pair(path),
         dist = min([for(seg=segs)
                       let(
                           c=seg[1]-seg[0],
                           s0 = seg[0]-pt,
                           t = -s0*c/(c*c)
                        )
                        t<0 ? norm(s0)
                      : t>1 ? norm(seg[1]-pt)
                      : norm(s0+t*c)]),
         inside = [] == [for(seg=segs)
                          if (cross(seg[1]-seg[0], pt-seg[0]) > EPSILON) 1]
                  ? -1 : 1
    )
    neg * coef / (inside*dist+maxdist);

function _revsurf_influence(point, path, coef, exp, neg, maxdist) =
    let(
         pt = [norm([point.x,point.y]), point.z],
         segs = pair(path),
         dist = min([for(seg=segs)
                       let(
                           c=seg[1]-seg[0],
                           s0 = seg[0]-pt,
                           t = -s0*c/(c*c)
                        )
                        t<0 ? norm(s0)
                      : t>1 ? norm(seg[1]-pt)
                      : norm(s0+t*c)]),
         inside = [] == [for(seg=segs)
                          if (cross(seg[1]-seg[0], pt-seg[0]) > EPSILON) 1]
                  ? -1 : 1
    )
    neg * (coef / (inside*dist+maxdist))^exp;

function _revsurf_cutoff(point, path, coef, cutoff, neg, maxdist) =
    let(
         pt = [norm([point.x,point.y]), point.z],
         segs = pair(path),
         dist = min([for(seg=segs)
                       let(
                           c=seg[1]-seg[0],
                           s0 = seg[0]-pt,
                           t = -s0*c/(c*c)
                        )
                        t<0 ? norm(s0)
                      : t>1 ? norm(seg[1]-pt)
                      : norm(s0+t*c)]),
         inside = [] == [for(seg=segs)
                          if (cross(seg[1]-seg[0], pt-seg[0]) > EPSILON) 1]
                  ? -1 : 1,
         d=inside*dist+maxdist
    )
    neg * mb_cutoff(d, cutoff) * coef/d;

function _revsurf_full(point, path, coef, cutoff, exp, neg, maxdist) =
    let(
        pt = [norm([point.x,point.y]), point.z],
        segs = pair(path),
        dist = min([for(seg=segs)
           let(
               c=seg[1]-seg[0],
               s0 = seg[0]-pt,
               t = -s0*c/(c*c)
            )
            t<0 ? norm(s0)
            : t>1 ? norm(seg[1]-pt)
            : norm(s0+t*c)]),
         inside = [] == [for(seg=segs)
                          if (cross(seg[1]-seg[0], pt-seg[0]) > EPSILON) 1]
                  ? -1 : 1,
         d=inside*dist+maxdist
    )
    neg * mb_cutoff(d, cutoff) * (coef/d)^exp;

function mb_cyl(h,r,rounding=0,r1,r2,l,height,length,d1,d2,d, cutoff=INF, influence=1, negative=false, hide_debug=false) =
    let(
         r1 = get_radius(r1=r1,r=r, d1=d1, d=d),
         r2 = get_radius(r1=r2,r=r, d1=d2, d=d),
         h = first_defined([h,l,height,length],"h,l,height,length")
    )
    assert(all_positive([influence]), "influence must be a positive number")
    assert(is_finite(rounding) && rounding>=0, "rounding must be a nonnegative number")
    assert(is_finite(r1) && r1>0, "r/r1/d/d1 must be a positive number")
    assert(is_finite(r2) && r2>0, "r/r2/d/d2 must be a positive number")
    assert(is_num(cutoff) && cutoff>0, "cutoff must be a positive number")
    let(
        vang = atan2(r1-r2,h),
        facelen = adj_ang_to_hyp(h, abs(vang)),
        roundlen1 = rounding/tan(45-vang/2),
        roundlen2 = rounding/tan(45+vang/2),
        sides = [[0,h/2], [r2,h/2], [r1,-h/2], [0,-h/2]],
        neg = negative ? -1 : 1
    )
    assert(roundlen1 <= r1, "size of rounding is larger than the r1 radius of the cylinder/cone")
    assert(roundlen2 <= r2, "size of rounding is larger than the r2 radius of the cylinder/cone")
    assert(roundlen1+roundlen2 < facelen, "Roundings don't fit on the edge length of the cylinder/cone")
    let(
        shifted = offset(sides, delta=-rounding, closed=false, check_valid=false),
        bisect1 = [shifted[1],unit(shifted[0]-shifted[1])+unit(shifted[2]-shifted[1])+shifted[1]],
        bisect2 = [shifted[2],unit(shifted[3]-shifted[2])+unit(shifted[1]-shifted[2])+shifted[2]],
        side_isect = line_intersection(bisect1,bisect2),
        top_isect = line_intersection(bisect1,[[0,0],[0,1]]),
        bot_isect = line_intersection(bisect2,[[0,0],[0,1]]),
        maxdist = side_isect.x>0 ?point_line_distance(side_isect, select(shifted,1,2))
                : max(point_line_distance(top_isect, select(shifted,1,2)),
                      point_line_distance(bot_isect, select(shifted,1,2))),
        vnf = [neg, hide_debug ? debug_tetra(0.02) : cyl(h,r1=r1,r2=r2,rounding=rounding,$fn=20)]
    )
       !is_finite(cutoff) && influence==1 ? [function(point) _revsurf_basic(point, shifted, maxdist+rounding, neg, maxdist), vnf]
     : !is_finite(cutoff) ? [function(point) _revsurf_influence(point, shifted, maxdist+rounding, 1/influence, neg, maxdist), vnf]
     : influence==1 ? [function(point) _revsurf_cutoff(point, shifted, maxdist+rounding, cutoff, neg, maxdist), vnf]
     : [function (point) _revsurf_full(point, shifted, maxdist+rounding, cutoff, 1/influence, neg, maxdist), vnf];


/// metaball disk with rounded edge

function _mb_disk_basic(point, hl, r, neg) =
    let(
        rdist=norm([point.x,point.y]), 
        dist = rdist<r ? abs(point.z) : norm([rdist-r,point.z])
    ) neg*hl/dist;
function _mb_disk_influence(point, hl, r, ex, neg) =
    let(
        rdist=norm([point.x,point.y]), 
        dist = rdist<r ? abs(point.z) : norm([rdist-r,point.z])
    ) neg*(hl/dist)^ex;
function _mb_disk_cutoff(point, hl, r, cutoff, neg) =
    let(
        rdist=norm([point.x,point.y]), 
        dist = rdist<r ? abs(point.z) : norm([rdist-r,point.z])
    ) neg * mb_cutoff(dist, cutoff) * hl/dist;
function _mb_disk_full(point, hl, r, cutoff, ex, neg) =
    let(
        rdist=norm([point.x,point.y]), 
        dist = rdist<r ? abs(point.z) : norm([rdist-r,point.z])
    ) neg*mb_cutoff(dist, cutoff) * (hl/dist)^ex;

function mb_disk(h, r, cutoff=INF, influence=1, negative=false, hide_debug=false, d,l,height,length) =
    assert(is_num(cutoff) && cutoff>0, "\ncutoff must be a positive number.")
    assert(is_finite(influence) && influence>0, "\ninfluence must be a positive number.")
    let(
        h = one_defined([h,l,height,length],"h,l,height,length"),
        dum1 = assert(is_finite(h) && h>0, "\ncylinder height must be a positive number."),
        h2 = h/2,
        or = get_radius(r=r,d=d),
        dum2 = assert(is_finite(r) && or>0, "\ninvalid radius or diameter."),
        r = or - h2,
        dum3 = assert(r>0, "\nDiameter must be greater than height."),
        neg = negative ? -1 : 1,
        vnf = [neg, hide_debug ? debug_tetra(0.02) : cyl(h,r,rounding=min(0.499*h,0.999*r), $fn=20)]
   )
   !is_finite(cutoff) && influence==1 ? [function(point) _mb_disk_basic(point,h2,r,neg), vnf]
 : !is_finite(cutoff) ? [function(point) _mb_disk_influence(point,h2,r,1/influence, neg), vnf]
 : influence==1 ? [function(point) _mb_disk_cutoff(point,h2,r,cutoff,neg), vnf]
 : [function (point) _mb_disk_full(point, h2, r, cutoff, 1/influence, neg), vnf];


/// metaball capsule (round-ended cylinder)

function _mb_capsule_basic(dv, hl, r, neg) = let(
    dist = dv.z<-hl ? norm(dv-[0,0,-hl])
      : dv.z<=hl ? norm([dv.x,dv.y]) : norm(dv-[0,0,hl])
) neg*r/dist;
function _mb_capsule_influence(dv, hl, r, ex, neg) = let(
    dist = dv.z<-hl ? norm(dv-[0,0,-hl])
      : dv.z<=hl ? norm([dv.x,dv.y]) : norm(dv-[0,0,hl])
) neg * (r/dist)^ex;
function _mb_capsule_cutoff(dv, hl, r, cutoff, neg) = let(
    dist = dv.z<-hl ? norm(dv-[0,0,-hl])
      : dv.z<hl ? norm([dv.x,dv.y]) : norm(dv-[0,0,hl])
) neg * mb_cutoff(dist, cutoff) * r/dist;
function _mb_capsule_full(dv, hl, r, cutoff, ex, neg) = let(
    dist = dv.z<-hl ? norm(dv-[0,0,-hl])
      : dv.z<hl ? norm([dv.x,dv.y]) : norm(dv-[0,0,hl])
) neg * mb_cutoff(dist, cutoff) * (r/dist)^ex;

function mb_capsule(h, r, cutoff=INF, influence=1, negative=false, hide_debug=false, d,l,height,length) =
    assert(is_num(cutoff) && cutoff>0, "\ncutoff must be a positive number.")
    assert(is_finite(influence) && influence>0, "\ninfluence must be a positive number.")
    let(
        h = one_defined([h,l,height,length],"h,l,height,length"),
        dum1 = assert(is_finite(h) && h>0, "\ncylinder height must be a positive number."),
        r = get_radius(r=r,d=d),
        dum2 = assert(is_finite(r) && r>0, "\ninvalid radius or diameter."),
        sh = h-2*r, // straight side length
        dum3 = assert(sh>0, "\nTotal length must accommodate rounded ends of cylinder."),
        neg = negative ? -1 : 1,
        vnf = [neg, hide_debug ? debug_tetra(0.02) : cyl(h, r, rounding=0.999*r, $fn=20)]
   )
   !is_finite(cutoff) && influence==1 ? [function(dv) _mb_capsule_basic(dv,sh/2,r,neg), vnf]
 : !is_finite(cutoff) ? [function(dv) _mb_capsule_influence(dv,sh/2,r,1/influence,neg), vnf]
 : influence==1 ? [function(dv) _mb_capsule_cutoff(dv,sh/2,r,cutoff,neg), vnf]
 : [function (dv) _mb_capsule_full(dv, sh/2, r, cutoff, 1/influence, neg), vnf];


/// metaball connector cylinder - calls mb_capsule* functions after transform

function mb_connector(p1, p2, r, cutoff=INF, influence=1, negative=false, hide_debug=false, d) =
    assert(is_num(cutoff) && cutoff>0, "\ncutoff must be a positive number.")
    assert(is_finite(influence) && influence>0, "\ninfluence must be a positive number.")
    let(
        dum1 = assert(is_vector(p1,3), "\nConnector start point p1 must be a 3D coordinate.")
            assert(is_vector(p2,3), "\nConnector end point p2 must be a 3D coordinate.")
            assert(p1 != p2, "\nStart and end points p1 and p2 cannot be the same."),
        r = get_radius(r=r,d=d),
        dum2 = assert(is_finite(r) && r>0, "\ninvalid radius or diameter."),
        neg = negative ? -1 : 1,
        dc = p2-p1, // center-to-center distance
        midpt = reverse(-0.5*(p1+p2)),
        h = norm(dc)/2, // center-to-center length (cylinder height)
        transform = submatrix(down(h)*rot(from=dc,to=UP)*move(-p1) ,[0:2], [0:3]),
        vnf=[neg, move(p1, rot(from=UP,to=dc,p=up(h, hide_debug ? debug_tetra(0.02) : cyl(2*(r+h),r,rounding=0.999*r,$fn=20))))]
   )
   !is_finite(cutoff) && influence==1 ? [function(dv)
        let(newdv = transform * [each dv,1])
            _mb_capsule_basic(newdv,h,r,neg), vnf]
 : !is_finite(cutoff) ? [function(dv)
        let(newdv = transform * [each dv,1])
            _mb_capsule_influence(newdv,h,r,1/influence, neg), vnf]
 : influence==1 ? [function(dv)
        let(newdv = transform * [each dv,1])
            _mb_capsule_cutoff(newdv,h,r,cutoff,neg), vnf]
 : [function (dv)
        let(newdv = transform * [each dv,1])
            _mb_capsule_full(newdv, h, r, cutoff, 1/influence, neg), vnf];

 
/// metaball torus

function _mb_torus_basic(point, rmaj, rmin, neg) =
    let(dist = norm([norm([point.x,point.y])-rmaj, point.z])) neg*rmin/dist;
function _mb_torus_influence(point, rmaj, rmin, ex, neg) =
    let(dist = norm([norm([point.x,point.y])-rmaj, point.z])) neg * (rmin/dist)^ex;
function _mb_torus_cutoff(point, rmaj, rmin, cutoff, neg) =
    let(dist = norm([norm([point.x,point.y])-rmaj, point.z]))
        neg * mb_cutoff(dist, cutoff) * rmin/dist;
function _mb_torus_full(point, rmaj, rmin, cutoff, ex, neg) =
    let(dist = norm([norm([point.x,point.y])-rmaj, point.z]))
        neg * mb_cutoff(dist, cutoff) * (rmin/dist)^ex;

function mb_torus(r_maj, r_min, cutoff=INF, influence=1, negative=false, hide_debug=false, d_maj, d_min, or,od,ir,id) =
   assert(is_num(cutoff) && cutoff>0, "\ncutoff must be a positive number.")
   assert(is_finite(influence) && influence>0, "\ninfluence must be a positive number.")
   let(
        _or = get_radius(r=or, d=od, dflt=undef),
        _ir = get_radius(r=ir, d=id, dflt=undef),
        _r_maj = get_radius(r=r_maj, d=d_maj, dflt=undef),
        _r_min = get_radius(r=r_min, d=d_min, dflt=undef),
        r_maj = is_finite(_r_maj)? _r_maj :
            is_finite(_ir) && is_finite(_or)? (_or + _ir)/2 :
            is_finite(_ir) && is_finite(_r_min)? (_ir + _r_min) :
            is_finite(_or) && is_finite(_r_min)? (_or - _r_min) :
            assert(false, "Bad major size parameter."),
        r_min = is_finite(_r_min)? _r_min :
            is_finite(_ir)? (maj_rad - _ir) :
            is_finite(_or)? (_or - maj_rad) :
            assert(false, "\nBad minor size parameter."),
       neg = negative ? -1 : 1,
       vnf = [neg, hide_debug ? debug_tetra(0.02) : torus(r_maj,r_min,$fn=20)]
   ) 
   !is_finite(cutoff) && influence==1 ? [function(point) _mb_torus_basic(point, r_maj, r_min, neg), vnf]
 : !is_finite(cutoff) ? [function(point) _mb_torus_influence(point, r_maj, r_min, 1/influence, neg), vnf]
 : influence==1 ? [function(point) _mb_torus_cutoff(point, r_maj, r_min, cutoff, neg), vnf]
 : [function(point) _mb_torus_full(point, r_maj, r_min, cutoff, 1/influence, neg), vnf];


/// metaball octahedron

function _mb_octahedron_basic(point, invr, xp, neg) =
   let( p = point*invr,
        dist = xp>1100 ? abs(p.x)+abs(p.y)+abs(p.z)
        : (abs(p.x+p.y+p.z)^xp + abs(-p.x-p.y+p.z)^xp + abs(-p.x+p.y-p.z)^xp + abs(p.x-p.y-p.z)^xp) ^ (1/xp)
    ) neg/dist;
function _mb_octahedron_influence(point, invr, xp, ex, neg) =
   let( p = point*invr,
        dist = xp>1100 ? abs(p.x)+abs(p.y)+abs(p.z)
        : (abs(p.x+p.y+p.z)^xp + abs(-p.x-p.y+p.z)^xp + abs(-p.x+p.y-p.z)^xp + abs(p.x-p.y-p.z)^xp) ^ (1/xp)
    ) neg/dist^ex;
function _mb_octahedron_cutoff(point, invr, xp, cutoff, neg) =
   let( p = point*invr,
        dist = xp>1100 ? abs(p.x)+abs(p.y)+abs(p.z)
        : (abs(p.x+p.y+p.z)^xp + abs(-p.x-p.y+p.z)^xp + abs(-p.x+p.y-p.z)^xp + abs(p.x-p.y-p.z)^xp) ^ (1/xp)
    ) neg * mb_cutoff(dist, cutoff) / dist;
function _mb_octahedron_full(point, invr, xp, cutoff, ex, neg) =
   let( p = point*invr,
        dist = xp>1100 ? abs(p.x)+abs(p.y)+abs(p.z)
        : (abs(p.x+p.y+p.z)^xp + abs(-p.x-p.y+p.z)^xp + abs(-p.x+p.y-p.z)^xp + abs(p.x-p.y-p.z)^xp) ^ (1/xp)
    ) neg * mb_cutoff(dist, cutoff) / dist^ex;

function mb_octahedron(size, squareness=0.5, cutoff=INF, influence=1, negative=false, hide_debug=false) =
   assert(is_num(cutoff) && cutoff>0, "\ncutoff must be a positive number.")
   assert(squareness>=0 && squareness<=1, "\nsquareness must be inside the range [0,1].")
   assert(is_finite(influence) && is_num(influence) && influence>0, "\ninfluence must be a positive number.")
   assert((is_finite(size) && size>0) || (is_vector(size) && all_positive(size)), "\nsize must be a positive number or a 3-vector of positive values.")
    let(
        xp = _squircle_se_exponent(squareness),
        invr = _mb_octahedron_basic([1/3,1/3,1/3],1,xp,1) * // correction factor
            (is_num(size) ? 2/size : [[2/size.x,0,0],[0,2/size.y,0],[0,0,2/size.z]]),
        neg = negative ? -1 : 1,
        vnf = [neg, hide_debug ? debug_tetra(0.02) : _debug_octahedron(size,squareness)]
    )
    !is_finite(cutoff) && influence==1 ? [function(point) _mb_octahedron_basic(point,invr,xp,neg), vnf]
  : !is_finite(cutoff) ? [function(point) _mb_octahedron_influence(point,invr,xp,1/influence, neg), vnf]
  : influence==1 ? [function(point) _mb_octahedron_cutoff(point,invr,xp,cutoff,neg), vnf]
  : [function(point) _mb_octahedron_full(point,invr,xp,cutoff,1/influence,neg), vnf];


/// debug shape approximations

/// beveled cube with squareness argument to approximate mb_cuboid() for debug view
function _debug_cube(size, squareness) =
    squareness > 0.998 ? cube(size, true)
    : let(
        hw = is_num(size) ? [size,size,size]*0.5 : 0.5*size,
        sq2 = sqrt(2),
        cut = (2-sq2)*squareness + sq2 - 1,
        xo = hw.x, yo = hw.y, zo = hw.z,
        xi = xo*cut, yi = yo*cut, zi = zo*cut,
        pts = [
            [-xi,-yi,-zo], [xi,-yi,-zo], [xi,yi,-zo], [-xi,yi,-zo], // 0,1,2,3
            [-xi,-yo,-zi], [xi,-yo,-zi], [xo,-yi,-zi], [xo,yi,-zi], // 4,5,6,7
                [xi,yo,-zi], [-xi,yo,-zi], [-xo,yi,-zi], [-xo,-yi,-zi], // 8,9,10,11
            [-xi,-yo,zi], [xi,-yo,zi], [xo,-yi,zi], [xo,yi,zi], // 12,13,14,15
                [xi,yo,zi], [-xi,yo,zi], [-xo,yi,zi], [-xo,-yi,zi], // 16,17,18,19
            [-xi,-yi,zo], [xi,-yi,zo], [xi,yi,zo], [-xi,yi,zo] // 20,21,22,23
        ],
        faces = [
            [0,1,2,3], // bottom
            [4,5,1,0], [6,7,2,1], [8,9,3,2], [10,11,0,3], // bottom bevel
            [1,5,6], [2,7,8], [3,9,10], [0,11,4],   // bottom corners
            [4,12,13,5], [5,13,14,6], [6,14,15,7], [7,15,16,8], [8,16,17,9], [9,17,18,10], [10,18,19,11], [11,19,12,4], // vertical sides
            [21,14,13], [22,16,15], [23,18,17], [20,12,19], // top corners
            [20,21,13,12], [21,22,15,14], [22,23,17,16], [23,20,19,18], // top bevels
            [23,22,21,20] // top
        ]
    ) [pts, faces]; // vnf structure

/// beveled octahedron with squareness argument to approximate mb_octahedron for debug view
function _debug_octahedron(size, squareness) = 
    squareness > 0.998 ? octahedron(size)
    : let(
        hw = is_num(size) ? [size,size,size]*0.5 : 0.5*size,
        isq3 = 1/sqrt(3),
        r = hw*(isq3+squareness*(1-isq3)), // 3-vector radius to tips
        ra = hw - r, // distance from axis tip face corner
        rx = r.x, ry=r.y, rz=r.z, ax=ra.x, ay=ra.y, az=ra.z,
        pts = [
            [ax,0,-rz], [0,ay,-rz], [-ax,0,-rz], [0,-ay,-rz], // 0,1,2,3  botttom
            [rx,0,-az], [0,ry,-az], [-rx,0,-az], [0,-ry,-az], // 4,5,6,7  below waist
            [rx,ay,0], [ax,ry,0], [-ax,ry,0], [-rx,ay,0],         // 8,9,10,11 waist
                [-rx,-ay,0], [-ax,-ry,0], [ax,-ry,0], [rx,-ay,0], // 12,13,14,15 waist
            [rx,0,az], [0,ry,az], [-rx,0,az], [0,-ry,az], // 16,17,18,19  above waist
            [ax,0,rz], [0,ay,rz], [-ax,0,rz], [0,-ay,rz]  // 20,21,22,23  botttom
        ],
        faces = [
            [0,1,2,3], // bottom
            [1,0,4,8,9,5], [2,1,5,10,11,6], [3,2,6,12,13,7], [0,3,7,14,15,4], // bottom angle faces
            [4,15,16,8], [5,9,17,10], [6,11,18,12], [7,13,19,14], // corner faces
            [9,8,16,20,21,17], [11,10,17,21,22,18], [13,12,18,22,23,19], [15,14,19,23,20,16], // top angle faces
            [23,22,21,20] // top
        ]
    ) [pts, faces]; // vnf structure

/// simplest and smallest possible VNF, to display for hide_debug or undefined metaballs; r=corner radius
function debug_tetra(r) = let(size=r/norm([1,1,1])) [
    size*[[1,1,1], [-1,-1,1], [1,-1,-1], [-1,1,-1]],
    [[0,1,3],[0,3,2],[1,2,3],[1,0,2]]
];


// Function&Module: metaballs()
// Synopsis: Creates a group of 3D metaballs (smoothly connected blobs).
// SynTags: Geom,VNF
// Topics: Metaballs, Isosurfaces, VNF Generators
// See Also: isosurface()
// Usage: As a module
//   metaballs(spec, bounding_box, voxel_size, [isovalue=], [closed=], [exact_bounds=], [convexity=], [show_stats=], ...) [ATTACHMENTS];
// Usage: As a function
//   vnf = metaballs(spec, bounding_box, voxel_size, [isovalue=], [closed=], [exact_bounds=], [convexity=], [show_stats=]);
// Description:
//   ![Metaball animation](https://raw.githubusercontent.com/BelfrySCAD/BOSL2/master/images/metaball_demo.gif)
//   .
//   [Metaballs](https://en.wikipedia.org/wiki/Metaballs), also known as "blobby objects",
//   can produce smoothly varying blobs and organic forms. You create metaballs by placing metaball
//   objects at different locations. These objects have a basic size and shape when placed in
//   isolation, but if another metaball object is nearby, the two objects interact, growing larger
//   and melding together. The closer the objects are, the more they blend and meld.
//   .
//   The simplest metaball specification is a 1D list of alternating transformation matrices and
//   metaball functions: `[trans0, func0, trans1, func1, ... ]`, passed as the `spec` parameter.
//   Each transformation matrix you supply can be constructed using the usual transformation commands
//   such as {{up()}}, {{right()}}, {{back()}}, {{move()}}, {{scale()}}, {{rot()}} and so on. You can
//   multiply the transformations together, similar to how the transformations can be applied
//   to regular objects in OpenSCAD. For example, to transform an object in regular OpenSCAD you
//   might write `up(5) xrot(25) zrot(45) scale(4)`. You would provide that transformation
//   as the transformation matrix `up(5) * xrot(25) * zrot(45) * scale(4)`. You can use
//   scaling to produce an ellipsoid from a sphere, and you can even use {{skew()}} if desired. 
//   When no transformation is needed, give `IDENT` as the transformation.
//   .
//   The metaballs are evaluated over a bounding box. The `bounding_box` parameter can be specified by
//   its minimum and maximum corners `[[xmin,ymin,zmin],[xmax,ymax,zmax]]`,
//   or specified as a scalar size of a cube centered on the origin. The contributions from **all**
//   metaballs, even those outside the box, are evaluated over the bounding box. This bounding box is
//   divided into voxels of the specified `voxel_size`, which can also be a scalar cube or a vector size.
//   Alternately, you can set `voxel_count` to fit approximately the specified number of boxels into the
//   bounding box.
//   .
//   Smaller voxels produce a finer, smoother result at the expense of execution time. Larger voxels
//   shorten execution time. Objects in the scene having any dimension smaller than the voxel may not
//   be displayed, so if objects seem to be missing, try making `voxel_size` smaller or `voxel_count`
//   larger. By default, if the voxel size doesn't exactly divide your specified bounding box, then the
//   bounding box is enlarged to  contain whole voxels, and centered on your requested box. Alternatively,
//   you may set `exact_bounds=true` to cause the voxels to adjust in size to fit instead. Either way, if
//   the bounding box clips a metaball and `closed=true` (the default), the object is closed at the
//   intersection surface. Setting `closed=false` causes the [VNF](vnf.scad) faces to end at the bounding
//   box, resulting in a non-manifold shape with holes, exposing the inside of the object.
//   .
//   For metaballs with flat surfaces (the ends of `mb_cyl()`, and `mb_cuboid()` with `squareness=1`),
//   avoid letting any side of the bounding box coincide with one of these flat surfaces, otherwise
//   unpredictable triangulation around the edge may result.
//   .
//   You can create metaballs in a variety of standard shapes using the predefined functions
//   listed below. If you wish, you can also create custom metaball shapes using your own functions
//   (see Examples 20 and 21). For all of the built-in metaballs, three parameters are available to control
//   the interaction of the metaballs with each other: `cutoff`, `influence`, and `negative`.
//   .
//   The `cutoff` parameter specifies the distance beyond which the metaball has no interaction
//   with other balls. When you apply `cutoff`, a smooth suppression factor begins
//   decreasing the interaction strength at half the cutoff distance and reduces the interaction to
//   zero at the cutoff. Note that the smooth decrease may cause the interaction to become negligible
//   closer than the actual cutoff distance, depending on the voxel size and `influence` of the
//   ball. Also, depending on the value of `influence`, a cutoff that ends in the middle of
//   another ball can result in strange shapes, as shown in Example 17, with the metaball
//   interacting on one side of the boundary and not interacting on the other side. If you scale
//   a ball, the cutoff value is also scaled. The exact way that cutoff is defined
//   geometrically varies for different ball types; see below for details.
//   . 
//   The `influence` parameter adjusts the strength of the interaction that metaball objects have with
//   each other. If you increase `influence` of one metaball from its default of 1, then that metaball
//   interacts with others at a longer range, and surrounding balls grow bigger. The metaball with larger
//   influence can also grow bigger because it couples more strongly with other nearby balls, but it
//   can also remain nearly unchanged while influencing others when `isovalue` is greater than 1.
//   Decreasing influence has the reverse effect. Small changes in influence can have a large
//   effect; for example, setting `influence=2` dramatically increases the interactions at longer
//   distances, and you may want to set the `cutoff` argument to limit the range influence.
//   At the other exteme, small influence values can produce ridge-like artifacts or texture on the
//   model. Example 14 demonstrates this effect. To avoid these artifacts, keep `influence` above about
//   0.5 and consider using `cutoff` instead of using small influence.
//   .
//   The `negative` parameter, if set to `true`, creates a negative metaball, which can result in
//   hollows, dents, or reductions in size of other metaballs. 
//   Negative metaballs are never directly visible; only their effects are visible. The `influence`
//   argument may also behave in ways you don't expect with a negative metaball. See Examples 16 and 17.
//   .
//   The `spec` parameter is flexible. It doesn't have to be just a list of alternating transformation
//   matrices and metaball functions. It can also be a list of alternating transforms and *other specs*,
//   as `[trans0, spec0, trans1, spec1, ...]`, in which `spec0`, `spec1`, etc. can be one of:
//   * A built-in metaball function name as described below, such as `mb_sphere(r=10)`.
//   * A function literal accepting as its first argument a 3-vector representing a point in space relative to the metaball's center.
//   * An array containing a function literal and a debug VNF, as `[custom_func(point, arg1,...), [sign, vnf]]`, where `sign` is the sign of the metaball and `vnf` is the VNF to show in the debug view when `debug=true` is set.
//   * Another spec array, for nesting metaball specs together.
//   .
//   Nested metaball specs allow for complicated assemblies in which you can arrange components in a logical
//   way, or repeat a structure with different transformation matrices. That is,
//   instead of specifying a transform and function, you specify a transform and then another metaball
//   specification. For example, you could set `finger=[t0,f0,t1,f1,t2,f2]` and then set
//   `hand=[u0,finger,u1,finger,...]` and then invoke `metaballs()` with `spec=[s0, hand]`. In effect, any
//   metaball specification array can be treated as a single metaball in another specification array.
//   This is a powerful technique that lets you make groups of metaballs that you can use as individual
//   metaballs in other groups, and can make your code compact and simpler to understand. Keep in mind that
//   nested components aren't independent; they still interact with all other components. See Example 24.
//   .
//   The isovalue parameter applies globally to **all** your metaballs and changes the appearance of your
//   entire metaball object, possibly dramatically. It defaults to 1 and you don't usually need to change
//   it. If you increase the isovalue, then all the objects in your model shrink, causing some melded
//   objects to separate. If you decrease it, each metaball grows and melds more with others.
//   .
//   ***Built-in metaball functions***
//   .
//   Several metaballs are defined for you to use in your models. 
//   All of the built-in metaballs take positional and named parameters that specify the size of the
//   metaball (such as height or radius). The size arguments are the same as those for the regular objects
//   of the same type (e.g. a sphere accepts both `r` for radius and the named parameter `d=` for
//   diameter). The size parameters always specify the size of the metaball **in isolation** with
//   `isovalue=1`. The metaballs can grow much bigger than their specified sizes when they interact
//   with each other. Changing `isovalue` also changes the sizes of metaballs. They grow bigger than their
//   specified sizes, even in isolation, if `isovalue < 1` and smaller than their specified sizes if
//   `isovalue > 1`.
//   .
//   The built-in metaball functions are listed below. As usual, arguments without a trailing `=` can be used positionally; arguments with a trailing `=` must be used as named arguments.
//   .
//   * `mb_sphere(r|d=)` &mdash; spherical metaball, with radius r or diameter d.  You can create an ellipsoid using `scale()` as the last transformation entry of the metaball `spec` array. 
//   * `mb_cuboid(size, [squareness=])` &mdash; cuboid metaball with rounded edges and corners. The corner sharpness is controlled by the `squareness` parameter ranging from 0 (spherical) to 1 (cubical), and defaults to 0.5. The `size` parameter specifies the dimensions of the cuboid that circumscribes the rounded shape, which is tangent to the center of each cube face. The `size` parameter may be a scalar or a vector, as in {{cuboid()}}. Except when `squareness=1`, the faces are always a little bit curved.
//   * `mb_cyl(h|l|height|length, [r|d=], [r1=|d1=], [r2=|d2=], [rounding=])` &mdash; vertical cylinder or cone metaball with the same dimensional arguments as {{cyl()}}. At least one of the radius or diameter arguments is required. The `rounding` argument defaults to 0 (sharp edge) if not specified. Only one rounding value is allowed: the rounding is the same at both ends. For a fully rounded cylindrical shape, consider using `mb_capsule()` or `mb_disk()`, which are less flexible but have faster execution times.
//   * `mb_disk(h|l|height|length, r|d=)` &mdash; flat disk with rounded edge. The diameter specifies the total diameter of the shape including the rounded sides, and must be greater than its height.
//   * `mb_capsule(h|l|height|length, [r|d=]` &mdash; vertical cylinder with rounded caps, using the same dimensional arguments as {{cyl()}}. The object resembles a convex hull of two spheres. The height or length specifies the distance between the spherical centers of the ends.
//   * `mb_connector(p1, p2, [r|d=])` &mdash; a connecting rod of radius `r` or diameter `d` with hemispherical caps (like `mb_capsule()`), but specified to connect point `p1` to point `p2` (where `p1` and `p2` must be different 3D coordinates). As with `mb_capsule()`, the object resembles a convex hull of two spheres. The points `p1` and `p2` are at the centers of the two round caps. The connectors themselves are still influenced by other metaballs, but it may be undesirable to have them influence others, or each other. If two connectors are connected, the joint may appear swollen unless `influence` or `cutoff` is reduced. Reducing `cutoff` is preferable if feasible, because reducing `influence` can produce interpolation artifacts.
//   * `mb_torus([r_maj|d_maj=], [r_min|d_min=], [or=|od=], [ir=|id=])` &mdash; torus metaball oriented perpendicular to the z axis. You can specify the torus dimensions using the same arguments as {{torus()}}; that is, major radius (or diameter) with `r_maj` or `d_maj`, and minor radius and diameter using `r_min` or `d_min`. Alternatively you can give the inner radius or diameter with `ir` or `id` and the outer radius or diameter with `or` or `od`. You must provide a combination of inputs that completely specifies the torus. If `cutoff` is applied, it is measured from the circle represented by `r_min=0`.
//   * `mb_octahedron(size, [squareness=])` &mdash; octahedron metaball with rounded edges and corners. The corner sharpness is controlled by the `squareness` parameter ranging from 0 (spherical) to 1 (sharp), and defaults to 0.5. The `size` parameter specifies the tip-to-tip distance of the octahedron that circumscribes the rounded shape, which is tangent to the center of each octahedron face. The `size` parameter may be a scalar or a vector, as in {{octahedron()}}. At `squareness=0`, the shape reduces to a sphere curcumscribed by the octahedron. Except when `squareness=1`, the faces are always curved.
//   .
//   In addition to the dimensional arguments described above, all of the built-in functions accept the
//   following named arguments:
//   * `cutoff` &mdash; positive value giving the distance beyond which the metaball does not interact with other balls.  Cutoff is measured from the object's center. Default: INF
//   * `influence` &mdash; a positive number specifying the strength of interaction this ball has with other balls.  Default: 1
//   * `negative` &mdash; when true, creates a negative metaball. Default: false
//   * `hide_debug` &mdash; when true, suppresses the display of the underlying metaball shape when `debug=true` is set in the `metaballs()` module. This is useful to hide shapes that may be overlapping others in the debug view. Default: false
//   .
//   ***Metaball functions and user defined functions***
//   .
//   You can construct complicated metaball models using only the built-in metaball functions above.
//   However, you can create your own custom metaballs if desired.
//   .
//   When multiple metaballs are in a model, their functions are summed and compared to the isovalue to
//   determine the final shape of the metaball object.
//   Each metaball is defined as a function of a 3-vector that gives the value of the metaball function
//   for that point in space. As is common in metaball implementations, we define the built-in metaballs using an
//   inverse relationship where the metaball functions fall off as $1/d$, where $d$ is distance measured from
//   the center or core of the metaball. The spherical metaball therefore has a simple basic definition as
//   $f(v) = 1/\text{norm}(v)$. If we choose an isovalue $c$, then the set of points $v$ such that $f(v) >= c$
//   defines a bounded set; for example, a sphere with radius depending on the isovalue $c$. The
//   default isovalue is $c=1$. Increasing the isovalue shrinks the object, and decreasing the isovalue grows
//   the object.
//   .
//   To adjust interaction strength, the influence parameter applies an exponent, so if `influence=a`
//   then the decay becomes $1/d^{1/a}$. This means, for example, that if you set influence to
//   0.5 you get a $1/d^2$ falloff. Changing this exponent changes how the balls interact.
//   .
//   You can pass a custom function as a [function literal](https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/User-Defined_Functions_and_Modules#Function_literals)
//   that takes a 3-vector as its first argument and returns a single numerical value. In the `spec` array
//   Generally, the function should return a scalar value that drops below the isovalue somewhere within your
//   bounding box. If you want your custom metaball function to behave similar to to the built-in functions,
//   the return value should fall off with distance as $1/d$. See Examples 20, 21, and 22 for demonstrations
//   of creating custom metaball functions. Example 22 also shows how to make a complete custom metaball
//   function that handles the `influence` and `cutoff` parameters.
//   .
//   ***Debug view***
//   .
//   The module form of `metaballs()` can take a `debug` argument. When you set `debug=true`, the scene is
//   rendered as a transparency with the primitive metaball shapes shown inside, colored blue for positive,
//   orange for negative, and gray for unsigned metaballs. These shapes are displayed at the sizes specified by
//   the dimensional parameters in the corresponding metaball functions, regardless of isovalue. Setting
//   `hide_debug=true` in individual metaball functions hides primitive shape from the debug view. Regardless
//   the `debug` setting, child modules can access the metaball VNF via `$metaball_vnf`.
//   .
//   User-defined metaball functions are displayed by default as gray tetrahedrons with a corner radius of 5,
//   unless you also designate a VNF for your custom function. To specify a custom VNF for a custom function
//   literal, enclose it in square brackets to make a list with the function literal as the first element, and
//   another list as the second element, for example:   
//   `[ function (point) custom_func(point, arg1,...), [sign, vnf] ]`   
//   where `sign` is the sign of the metaball and `vnf` is the VNF to show in the debug view when `debug=true`.
//   The sign determines the color of the debug object: `1` is blue, `-1` is orange, and `0` is gray.
//   Example 31 below demonstrates setting a VNF for a custom function.
//   .
//   ***Voxel size and bounding box***
//   .
//   The size of the voxels and size of the bounding box affects the run time, which can be long.
//   A voxel size of 1 with a bounding box volume of 200×200×200 may be slow because it requires the
//   calculation and storage of 8,000,000 function values, and more processing and memory to generate
//   the triangulated mesh.  On the other hand, a voxel size of 5 over a 100×100×100 bounding box
//   requires only 8,000 function values and a modest computation time. A good rule is to keep the number
//   of voxels below 10,000 for preview, and adjust the voxel size smaller for final rendering. If you don't
//   specify either `voxel_size` or `voxel_count`, then a default count of 10,000 voxels is used,
//   which should be reasonable for initial preview. Because a bounding
//   box that is too large wastes time computing function values that are not needed, you can also set the
//   parameter `show_stats=true` to get the actual bounds of the voxels intersected by the surface. With this
//   information, you may be able to decrease run time, or keep the same run time but increase the resolution. 
//   .
//   ***Duplicated vertices***
//   .
//   The point list in the generated VNF structure contains many duplicated points. This is normally not a
//   problem for rendering the shape, but machine roundoff differences may result in Manifold issuing
//   warnings when doing the final render, causing rendering to abort if you have enabled the "stop on
//   first warning" setting. You can prevent this by passing the VNF through {{vnf_quantize()}} using a
//   quantization of 1e-7, or you can pass the VNF structure into {{vnf_merge_points()}}, which also
//   removes the duplicates. Additionally, flat surfaces (often resulting from clipping by the bounding
//   box) are triangulated at the voxel size resolution, and these can be unified into a single face by
//   passing the vnf structure to {{vnf_unify_faces()}}. These steps can be computationally expensive
//   and are not normally necessary.
// Arguments:
//   spec = Metaball specification in the form `[trans0, spec0, trans1, spec1, ...]`, with alternating transformation matrices and metaball specs, where `spec0`, `spec1`, etc. can be a metaball function or another metaball specification. See above for more details, and see Example 24 for a demonstration.
//   bounding_box = The volume in which to perform computations, expressed as a scalar size of a cube centered on the origin, or a pair of 3D points `[[xmin,ymin,zmin], [xmax,ymax,zmax]]` specifying the minimum and maximum box corner coordinates. Unless you set `exact_bounds=true`, the bounding box size may be enlarged to fit whole voxels.
//   voxel_size = Size of the voxels used to sample the bounding box volume, can be a scalar or 3-vector, or omitted if `voxel_count` is set. You may get a non-cubical voxels of a slightly different size than requested if `exact_bounds=true`.
//   ---
//   voxel_count = Approximate number of voxels in the bounding box. If `exact_bounds=true` then the voxels may not be cubes. Use with `show_stats=true` to see the corresponding voxel size. Default: 10000 (if `voxel_size` not set)
//   isovalue = A scalar value specifying the isosurface value (threshold value) of the metaballs. At the default value of 1.0, the internal metaball functions are designd so the size arguments correspond to the size parameter (such as radius) of the metaball, when rendered in isolation with no other metaballs. Default: 1.0
//   closed = When true, close the surface if it intersects the bounding box by adding a closing face. When false, do not add a closing face, possibly producing non-manfold metaballs with holes where the bounding box intersects them.  Default: true
//   exact_bounds = When true, shrinks voxels as needed to fit whole voxels inside the requested bounding box. When false, enlarges `bounding_box` as needed to fit whole voxels of `voxel_size`, and centers the new bounding box over the requested box. Default: false
//   show_stats = If true, display statistics about the metaball isosurface in the console window. Besides the number of voxels that the surface passes through, and the number of triangles making up the surface, this is useful for getting information about a possibly smaller bounding box to improve speed for subsequent renders. Enabling this parameter has a small speed penalty. Default: false
//   convexity = (Module only) Maximum number of times a line could intersect a wall of the shape. Affects preview only. Default: 6
//   show_box = (Module only) Display the requested bounding box as transparent. This box may appear slightly inside the bounds of the figure if the actual bounding box had to be expanded to accommodate whole voxels. Default: false
//   debug = (Module only) Display the underlying primitive metaball shapes using your specified dimensional arguments, overlaid by the transparent metaball scene. Positive metaballs appear blue, negative appears orange, and any custom function with no debug VNF defined appears as a gray tetrahedron of corner radius 5.
//   cp = (Module only) Center point for determining intersection anchors or centering the shape.  Determines the base of the anchor vector. Can be "centroid", "mean", "box" or a 3D point.  Default: "centroid"
//   anchor = (Module only) Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `"origin"`
//   spin = (Module only) Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = (Module only) Vector to rotate top toward, after spin. See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   atype = (Module only) Select "hull" or "intersect" anchor type.  Default: "hull"
// Anchor Types:
//   "hull" = Anchors to the virtual convex hull of the shape.
//   "intersect" = Anchors to the surface of the shape.
// Named Anchors:
//   "origin" = Anchor at the origin, oriented UP.
// Side Effects:
//   `$metaball_vnf` is available to child modules to get the VNF of the metaball scene.
// Example(3D,NoAxes): Two spheres interacting.
//   spec = [
//       left(9), mb_sphere(5),
//       right(9), mb_sphere(5)
//   ];
//   metaballs(spec, voxel_size=0.5,
//       bounding_box=[[-16,-7,-7], [16,7,7]]);
// Example(3D,NoAxes): Two rounded cuboids interacting.
//   spec = [
//       move([-8,-5,-5]), mb_cuboid(10),
//       move([8,5,5]), mb_cuboid(10)
//   ];
//   metaballs(spec, voxel_size=0.5,
//       bounding_box=[[-15,-12,-12], [15,12,12]]);
// Example(3D,NoAxes): Two rounded `mb_cyl()` cones interacting.
//      spec = [
//          left(10), mb_cyl(15, r1=6, r2=4, rounding=2),
//          right(10), mb_cyl(15, r1=6, r2=4, rounding=2)
//      ];
//      metaballs(spec, voxel_size=0.5,
//          bounding_box=[[-17,-8,-10], [17,8,10]]);
// Example(3D,NoAxes): Two disks interacting. Here the arguments are in order and not named.
//   metaballs([
//       move([-10,0,2]), mb_disk(5,9),
//       move([10,0,-2]), mb_disk(5,9)
//       ], [[-20,-10,-6], [20,10,6]], 0.5);
// Example(3D,NoAxes): Two capsules interacting.
//   metaballs([
//       move([-8,0,4])*yrot(90), mb_capsule(16,3),
//       move([8,0,-4])*yrot(90), mb_capsule(16,3)
//       ], [[-17,-5,-8], [17,5,8]],  0.5);
// Example(3D,NoAxes): A sphere with two connectors.
//   path = [[-20,0,0], [0,0,1], [0,-10,0]];
//   spec = [
//       move(path[0]), mb_sphere(6),
//       for(seg=pair(path)) each
//          [IDENT, mb_connector(seg[0],seg[1],
//           2, influence=0.5)]
//   ];
//   metaballs(spec, voxel_size=0.5,
//       bounding_box=[[-27,-13,-7], [4,7,14]]);
// Example(3D,NoAxes): Interaction between two tori in different orientations.
//    spec = [
//        move([-10,0,17]),        mb_torus(r_maj=6, r_min=2),
//        move([7,6,21])*xrot(90), mb_torus(r_maj=7, r_min=3)
//    ];
//    voxel_size = 0.5;
//    boundingbox = [[-19,-9,9], [18,10,32]];
//    metaballs(spec, boundingbox, voxel_size);
// Example(3D,NoAxes,VPR=[75,0,20]): Two octahedrons interacting. Here `voxel_size` is not given, so it defaults to a value that results in approximately 10,000 voxels in the bounding box. Adding the parameter `show_stats=true` displays the voxel size used, along with other information.
//   metaballs([
//       move([-11,0,4]), mb_octahedron(20),
//       move([11,0,-4]), mb_octahedron(20)
//       ], [[-21,-11,-14], [21,11,14]]);
// Example(3D,VPD=110): These next five examples demonstrate the different types of metaball interactions. We start with two spheres 30 units apart. Each would have a radius of 10 in isolation, but because they are influencing their surroundings, each sphere mutually contributes to the size of the other. The sum of contributions between the spheres add up so that a surface plotted around the region exceeding the threshold defined by `isovalue=1` looks like a peanut shape surrounding the two spheres.
//   spec = [
//       left(15),  mb_sphere(10),
//       right(15), mb_sphere(10)
//   ];
//   voxel_size = 1;
//   boundingbox = [[-30,-19,-19], [30,19,19]];
//   metaballs(spec, boundingbox, voxel_size);
// Example(3D,VPD=110): Adding a cutoff of 25 to the left sphere causes its influence to disappear completely 25 units away (5 units from the center of the right sphere). The left sphere is bigger because it still receives the full influence of the right sphere, but the right sphere is smaller because the left sphere has no contribution past 25 units. The right sphere is not abruptly cut off because the cutoff function is smooth and influence is normal. Setting cutoff too small can remove the interactions of one metaball from all other metaballs, leaving that metaball alone by itself.
//   spec = [
//       left(15),  mb_sphere(10, cutoff=25),
//       right(15), mb_sphere(10)
//   ];
//   voxel_size = 1;
//   boundingbox = [[-30,-19,-19], [30,19,19]];
//   metaballs(spec, boundingbox, voxel_size);
// Example(3D,VPD=110): Here, the left sphere has less influence in addition to a cutoff. Setting `influence=0.5` results in a steeper falloff of contribution from the left sphere. Each sphere has a different size and shape due to unequal contributions based on distance.
//   spec = [
//       left(15),  mb_sphere(10, influence=0.5, cutoff=25),
//       right(15), mb_sphere(10)
//   ];
//   voxel_size = 1;
//   boundingbox = [[-30,-19,-19], [30,19,19]];
//   metaballs(spec, boundingbox, voxel_size);
// Example(3D,VPD=110): In this example, we have two size-10 spheres as before and one tiny sphere of 1.5 units radius offset a bit on the y axis. With an isovalue of 1, this figure would appear similar to Example 9 above, but here the isovalue has been set to 2, causing the surface to shrink around a smaller volume values greater than 2. Remember, higher isovalue thresholds cause metaballs to shrink.
//   spec = [
//      left(15),  mb_sphere(10),
//      right(15), mb_sphere(10),
//      fwd(15),   mb_sphere(1.5)
//   ];
//   voxel_size = 1;
//   boundingbox = [[-30,-19,-19], [30,19,19]];
//   metaballs(spec, boundingbox, voxel_size,
//       isovalue=2);
// Example(3D,VPD=110): Keeping `isovalue=2`, the influence of the tiny sphere has been set quite high, to 10. Notice that the tiny sphere shrinks a bit, but it has dramatically increased its contribution to its surroundings, causing the two other spheres to grow and meld into each other. The `influence` argument on a small metaball affects its surroundings more than itself.
//   spec = [
//      move([-15,0,0]), mb_sphere(10),
//      move([15,0,0]),  mb_sphere(10),
//      move([0,-15,0]), mb_sphere(1.5, influence=10)
//   ];
//   voxel_size = 1;
//   boundingbox = [[-30,-19,-19], [30,19,19]];
//   metaballs(spec, boundingbox, voxel_size,
//       isovalue=2);
// Example(3D,Med): Setting `influence` to less than 0.5 can cause interpolation artifacts in the surface. The only difference between these two spheres is `influence`. Both have `cutoff` set to prevent them from affecting each other. The sphere on the right has a low influence of 0.02, which translates to a falloff with distance $d$ proportional to $1/d^{50}$. That high exponent increases the *non-linear* nature of the function gradient at the isosurface, reducing the accuracy of the *linear* interpolation of where the the surface intersects each voxel, causing ridges to appear. You could use this to create a texture deliberately, but it is usually better to use `cutoff` to limit the range of influence rather than reducing `influence` significantly below 1.
//   spec = [
//       left(10), mb_sphere(8, cutoff=10, influence=1),
//       right(10), mb_sphere(8, cutoff=10, influence=0.02)
//   ];
//   bbox = [[-18,-8,-8], [18,8,8]];
//   metaballs(spec, bounding_box=bbox, voxel_size=0.4);
// Example(3D,NoAxes): A group of five spherical metaballs with different sizes. The parameter `show_stats=true` (not shown here) was used to find a compact bounding box for this figure. Here instead of setting `voxel_size`, we set `voxel_count` for approximate number of voxels in the bounding box, and the voxel size is adjusted to fit. Setting `exact_bounds=true` forces the bounding box to be fixed, and a non-cubic voxel is then used to fit within that box.
//      spec = [ // spheres of different sizes
//          move([-20,-20,-20]), mb_sphere(5),
//          move([0,-20,-20]),   mb_sphere(4),
//          IDENT,               mb_sphere(3),
//          move([0,0,20]),      mb_sphere(5),
//          move([20,20,10]),    mb_sphere(7)
//      ];
//      voxel_size = 1.5;
//      boundingbox = [[-30,-31,-31], [32,31,30]];
//      metaballs(spec, boundingbox,
//          exact_bounds=true, voxel_count=40000);
// Example(3D,NoAxes): A metaball can be negative. In this case we have two metaballs in close proximity, with the small negative metaball creating a dent in the large positive one. The positive metaball is shown transparent, and small spheres show the center of each metaball. The negative metaball isn't visible because its field is negative; the isosurface encloses only field values greater than the isovalue of 1.
//   centers = [[-1,0,0], [1.25,0,0]];
//   spec = [
//       move(centers[0]), mb_sphere(8),
//       move(centers[1]), mb_sphere(3, negative=true)
//   ];
//   voxel_size = 0.25;
//   boundingbox = [[-7,-6,-6], [3,6,6]];
//   %metaballs(spec, boundingbox, voxel_size);
//   color("green") move_copies(centers) sphere(d=1, $fn=16);
// Example(3D,VPD=105,VPT=[3,5,4.7]): When a positive and negative metaball interact, the negative metaball reduces the influence of the positive one, causing it to shrink, but not disappear because its contribution approaches infinity at its center. In this example we have a large positive metaball near a small negative metaball at the origin. The negative ball has high influence, and a cutoff limiting its influence to 20 units. The negative metaball influences the positive one up to the cutoff, causing the positive metaball to appear smaller inside the cutoff range, and appear its normal size outside the cutoff range. The positive metaball has a small dimple at the origin (the center of the negative metaball) because it cannot overcome the infinite negative contribution of the negative metaball at the origin.
//   spec = [
//       back(10), mb_sphere(20),
//       IDENT, mb_sphere(2, influence=30,
//           cutoff=20, negative=true),
//   ];
//   voxel_size = 0.5;
//   boundingbox = [[-20,-4,-20], [20,30,20]];
//   metaballs(spec, boundingbox, voxel_size);
// Example(3D,NoAxes,VPD=80,VPT=[3,0,19]): A sharp cube, a rounded cube, and a sharp octahedron interacting. Because the surface is generated through cubical voxels, voxel corners are always cut off, resulting in difficulty resolving some sharp edges.
//   spec = [
//       move([-7,-3,27])*zrot(55), mb_cuboid(6, squareness=1),
//       move([5,5,21]),   mb_cuboid(5),
//       move([10,0,10]),  mb_octahedron(10, squareness=1)
//   ];
//   voxel_size = 0.5; // a bit slow at this resolution
//   boundingbox = [[-12,-9,3], [18,10,32]];
//   metaballs(spec, boundingbox, voxel_size);
// Example(3D,NoAxes,VPD=205,Med): A toy airplane, constructed only from metaball spheres with scaling. The bounding box is used to clip the wingtips, tail, and belly of the fuselage.
//   bounding_box = [[-55,-50,-5],[35,50,17]];
//   spec = [
//       move([-20,0,0])*scale([25,4,4]),   mb_sphere(1), // fuselage
//       move([30,0,5])*scale([4,0.5,8]),   mb_sphere(1), // vertical stabilizer
//       move([30,0,0])*scale([4,15,0.5]),  mb_sphere(1), // horizontal stabilizer
//       move([-15,0,0])*scale([6,45,0.5]), mb_sphere(1)  // wing
//   ];
//   voxel_size = 1;
//   color("lightblue") metaballs(spec, bounding_box, voxel_size);
// Example(3D,VPD=60,VPR=[57,0,50],VPT=[0.5,2,1.8]): Custom metaballs are an advanced technique in which you define your own metaball shape by passing a function literal that takes a single argument: a coordinate in space relative to the metaball center called `point` here, but can be given any name. This distance vector from the origin is calculated internally and always passed to the function. Inside the function, it is converted to a scalar distance `dist`. The function literal expression sets all of your parameters. Only `point` is not set, and it becomes the single parameter to the function literal. The `spec` argument invokes your custom function as a function literal that passes `point` into it.
//   function threelobe(point) =
//      let(
//           ang=atan2(point.y, point.x),
//           r=norm([point.x,point.y])*(1.3+cos(3*ang)),
//           dist=norm([point.z, r])
//      ) 3/dist;
//   metaballs(
//       spec = [
//           IDENT, function (point) threelobe(point),
//           up(7), mb_sphere(r=4)
//       ],
//       bounding_box = [[-14,-12,-5],[8,12,13]],
//       voxel_size=0.5);
// Example(3D,VPD=60,VPR=[57,0,50],VPT=[0.5,2,1.8]): Here is a function nearly identical to the previous example, introducing additional dimensional parameters into the function to control its size and number of lobes. The bounding box size here is as small as possible for calculation efficiency, but if you expiriment with this using different argument values, you should increase the bounding box along with voxel size.
//   function multilobe(point, size, lobes) =
//      let(
//           ang=atan2(point.y, point.x),
//           r=norm([point.x,point.y])*(1.3+cos(lobes*ang)),
//           dist=norm([point.z, r])
//      ) size/dist;
//   metaballs(
//       spec = [
//           left(7),
//              function (point) multilobe(point, 3, 4),
//           right(7)*zrot(60),
//              function (point) multilobe(point, 3, 3)
//       ],
//       bounding_box = [[-16,-13,-5],[18,13,6]],
//       voxel_size=0.4);
// Example(3D): Next we show how to create a function that works like the built-ins. **This is a full implementation** that allows you to specify the function directly by name in the `spec` argument without needing the function literal syntax, and without needing the `point` argument in `spec`, as in the prior examples. Here, `noisy_sphere_calcs() is the calculation function that accepts the `point` position argument and any other parameters needed (here `r` and `noise_level`), and returns a single value. Then there is a "master" function `noisy_sphere() that does some error checking and returns an array consisting of (a) a function literal expression that sets all of your parameters, and (b) another array containing the metaball sign and a simple "debug" VNF representation of the metaball for viewing when `debug=true` is passed to `metaballs()`. The call to `mb_cutoff()` at the end handles the cutoff function for the noisy ball consistent with the other internal metaball functions; it requires `dist` and `cutoff` as arguments. You are not required to use this implementation in your own custom functions; in fact it's easier simply to declare the function literal in your `spec` argument, but this example shows how to do it all.
//   //
//   // noisy sphere internal calculation function 
//   
//   function noisy_sphere_calcs(point, r, noise_level, cutoff, exponent, neg) =
//       let(
//           noise = rands(0, noise_level, 1)[0],
//           dist = norm(point) + noise // distance to point from metaball center
//       ) neg * mb_cutoff(dist,cutoff) * (r/dist)^exponent;
//   
//   // noisy sphere "master" entry function to use in spec argument
//   
//   function noisy_sphere(r, noise_level, cutoff=INF, influence=1, negative=false, hide_debug=false, d) =
//      assert(is_num(cutoff) && cutoff>0, "\ncutoff must be a positive number.")
//      assert(is_finite(influence) && influence>0, "\ninfluence must be a positive number.")
//      let(
//          r = get_radius(r=r,d=d),
//          dummy=assert(is_finite(r) && r>0, "\ninvalid radius or diameter."),
//          neg = negative ? -1 : 1,
//          // create [sign, vnf] for debug view; show tiny shape if hide_debug=true
//          debug_vnf = [neg, hide_debug ? debug_tetra(0.02) : sphere(r, $fn=16)]
//      ) [
//          // pass control as a function literal to the calc function
//          function (point) noisy_sphere_calcs(point, r, noise_level, cutoff, 1/influence, neg),
//          debug_vnf
//      ];
//   
//   // define the scene and render it
//   
//   spec = [
//       left(9),  mb_sphere(5),
//       right(9), noisy_sphere(r=5, noise_level=0.2)
//   ];
//   voxel_size = 0.5;
//   boundingbox = [[-16,-8,-8], [16,8,8]];
//   metaballs(spec, boundingbox, voxel_size);
// Example(3D,Med,NoAxes,VPR=[55,0,0],VPD=200,VPT=[7,2,2]): Demonstration of `debug=true` with a more complex example using ellipsoids, a capsule, spheres, and a torus to make a tetrahedral object with rounded feet and a ring on top. The bottoms of the feet are flattened by clipping with the bottom of the bounding box. The center of the object is thick due to the contributions of three ellipsoids and a capsule converging. Designing an object like this using metaballs requires trial and error with low-resolution renders.
//   include <BOSL2/polyhedra.scad>
//   tetpts = zrot(15, p = 22 * regular_polyhedron_info("vertices", "tetrahedron"));
//   tettransform = [ for(pt = tetpts) move(pt)*rot(from=RIGHT, to=pt)*scale([7,1.5,1.5]) ];
//   
//   spec = [
//       // vertical cylinder arm
//       up(15), mb_capsule(17, 2, influence=0.8),
//       // ellipsoid arms
//       for(i=[0:2]) each [tettransform[i], mb_sphere(1, cutoff=30)],
//       // ring on top
//       up(35)*xrot(90), mb_torus(r_maj=8, r_min=2.5, cutoff=35),
//       // feet
//       for(i=[0:2]) each [move(2.2*tetpts[i]), mb_sphere(5, cutoff=30)],
//   ];
//   voxel_size = 1;
//   boundingbox = [[-22,-32,-13], [36,32,46]];
//   metaballs(spec, boundingbox, voxel_size, isovalue=1, debug=true);
// Example(3D,Med,NoAxes,VPR=[70,0,30],VPD=520,VPT=[0,0,80]): This example demonstrates grouping metaballs together and nesting them in lists of other metaballs, to make a crude model of a hand. Here, just one finger is defined, and a thumb is defined from one less joint in the finger. Individual fingers are grouped together with different positions and scaling, along with the thumb. Finally, this group of all fingers is used to combine with a rounded cuboid, with a slight ellipsoid dent subtracted to hollow out the palm, to make the hand.
//   joints = [[0,0,1], [0,0,85], [0,-5,125], [0,-16,157], [0,-30,178]];
//   finger = [
//       for(i=[0:3]) each
//           [IDENT, mb_connector(joints[i], joints[i+1], 9+i/5, influence=0.22)]
//   ];
//   thumb = [
//       for(i=[0:2]) each [
//           scale([1,1,1.2]),
//           mb_connector(joints[i], joints[i+1], 9+i/2, influence=0.28)
//       ]
//   ];
//   allfingers = [
//       left(15)*zrot(5)*yrot(-50)*scale([1,1,0.6])*zrot(30), thumb,
//       left(15)*yrot(-9)*scale([1,1,0.9]), finger,
//       IDENT, finger,
//       right(15)*yrot(8)*scale([1,1,0.92]), finger,
//       right(30)*yrot(17)*scale([0.9,0.9,0.75]), finger
//   ];
//   hand = [
//       IDENT, allfingers,
//       move([-5,0,5])*scale([1,0.36,1.55]), mb_cuboid(90, squareness=0.3, cutoff=80),
//       move([-10,-95,50])*yrot(10)*scale([2,2,0.95]),
//           mb_sphere(r=15, cutoff=50, influence=1.5, negative=true)
//   ];
//   voxel_size=2.5;
//   bbox = [[-104,-40,-10], [79,18,188]];
//   metaballs(hand, bbox, voxel_size, isovalue=1);
// Example(3D,Med,NoAxes,VPR=[76,0,40],VPD=128,VPT=[4,-1,13]): A model of an elephant using cylinders, capsules, and disks.
//   legD1 = 4.6;
//   legD2 = 1;
//   spec = [
//       // legs
//       up(1)*fwd(8)*left(13), mb_cyl(d1=legD1, d2=legD2, h=20),
//       up(1)*fwd(8)*right(10), mb_cyl(d1=legD1, d2=legD2, h=20),
//       up(1)*back(8)*left(13), mb_cyl(d1=legD1, d2=legD2, h=20),
//       up(1)*back(8)*right(10), mb_cyl(d1=legD1, d2=legD2, h=20),
//       up(20)*yrot(90), mb_capsule(d=21, h=36, influence=0.5), // body
//       right(21)*up(25)*yrot(-20), mb_capsule(r=7, h=25, influence=0.5, cutoff=9), // head
//       right(24)*up(10)*yrot(15), mb_cyl(d1=3, d2=6, h=15, cutoff=3), // trunk
//       // ears
//       right(18)*up(29)*fwd(11)*zrot(-20)*yrot(80)*scale([1.4,1,1]), mb_disk(r=5,h=2, cutoff=3),
//       right(18)*up(29)*back(11)*zrot(20)*yrot(80)*scale([1.4,1,1]), mb_disk(r=5,h=2, cutoff=3),
//       // tusks
//       right(26)*up(13)*fwd(5)*yrot(135), mb_capsule(r=1, h=10, cutoff=1),
//       right(26)*up(13)*back(5)*yrot(135), mb_capsule(r=1, h=10, cutoff=1)
//   ];
//   bbox = [[-21,-17,-9], [31,17,38]];
//   metaballs(spec, bounding_box=bbox, voxel_size=1, isovalue=1);
// Example(3D,NoAxes,Med,VPD=235,VPR=[83,0,320],VPT=[-5,-5,43]): A model of a giraffe using a variety of different metaball shapes. Features such as the tail and lower legs are thin, so a small voxel size is required to render them.
//   legD = 1;
//   tibia = 14; 
//   femur = 12;
//   head = [-35,0,78];  // head position
//   stance = [12,6];    // leg position offsets
//   
//   spec = [
//       // Lower legs
//       move([-stance.x,-stance.y]), mb_connector([-4,0,0.25],[-6,0,tibia],legD, influence = 0.2),
//       move([-stance.x,stance.y]),  mb_connector([0,0,0],[0,0,tibia],legD, influence = 0.2),
//       move([stance.x,-stance.y]),  mb_connector([-2,0,0],[-3,0,tibia],legD, influence = 0.2),
//       move([stance.x,stance.y]),   mb_connector([0,0,0],[0,0,tibia],legD, influence = 0.2),
//       // Upper legs
//       move([-stance.x,-stance.y,tibia]), mb_connector([-6,0,0],[-2,0,femur],legD),
//       move([-stance.x,stance.y,tibia]),  mb_connector([0,0,0],[0,0,femur],legD),
//       move([stance.x,-stance.y,tibia]),  mb_connector([-3,0,0],[-1,0,femur],legD),
//       move([stance.x,stance.y,tibia]),   mb_connector([0,0,0],[0,0,femur],legD),
//   
//       // Hooves
//       move([-stance.x-5.5,-stance.y,1.25])*yrot(-5), mb_capsule(d=2, h=3, cutoff=2),
//       move([-stance.x-4.5,-stance.y,-1.4])*yrot(-5), mb_cuboid(size=4, squareness=1, cutoff=1, influence=20, negative=true), // truncate bottom of raised hoof
//       move([-stance.x-1,stance.y,1]),     mb_capsule(d=2, h=3, cutoff=2),
//       move([stance.x-3.5,-stance.y,1]),   mb_capsule(d=2, h=3, cutoff=2),
//       move([stance.x-1,stance.y,1]),      mb_capsule(d=2, h=3, cutoff=2),
//   
//       // Body
//       up(tibia+femur+10) * yrot(10),        mb_cuboid([16,7,7]),
//       up(tibia+femur+15)*left(10),          mb_sphere(2),
//       up(tibia+femur+8)*right(13)*xrot(90), mb_disk(1,4),
//   
//       // Tail
//       up(tibia+femur+8), mb_connector([18,0,0],[22,0,-16], 0.4, cutoff = 1),
//   
//       // Neck
//       up(tibia+femur+35)*left(22)*yrot(-30)* yscale(0.75), mb_cyl(d1 = 5, d2 = 3, l = 38),
//   
//       // Head
//       move(head + [-4,0,-3])*yrot(45)*xscale(0.75), mb_cyl(d1 = 1.5, d2 = 4, l = 12, rounding=0),
//       move(head), mb_cuboid(2),    
//   
//       // Horns
//       move(head), mb_connector([0,-2,5],[0,-2.5,8],0.3, cutoff = 1),
//       move(head + [0,-2.5,8]), mb_sphere(0.5, cutoff = 1),
//       move(head), mb_connector([0,2,5],[0,2.5,8],0.3, cutoff = 1),
//       move(head + [0,2.5,8]), mb_sphere(0.5, cutoff = 1),
//   
//       // Ears
//       move(head + [2,-8,4])* xrot(60) * scale([0.5,1,3]) , mb_sphere(d = 2, cutoff = 2),
//       move(head + [2,8,4])* xrot(-60) * scale([0.5,1,3]) , mb_sphere(d = 2, cutoff = 2),
//   ];
//   vsize = 0.85;
//   bbox =  [[-45.5, -11.5, 0], [23, 11.5, 87.55]];
//   metaballs(spec, bbox, voxel_size=vsize);
// Example(3D,Med,NoAxes,VPD=228,VPT=[1,-5,35]): A model of a bunny, made from separate body components made with metaballs, with each component rendered at a different voxel size, and then combined together along with eyes and teeth. In this way, smaller bounding boxes can be defined for each component, which speeds up rendering. A bit more time is saved by saving the repeated components (ear, front leg, hind leg) in VNF structures, to render copies with {{vnf_polyhedron()}}.
//   torso = [
//       up(20) * scale([1,1.2,2]), mb_sphere(10), 
//       up(10), mb_sphere(5) // fatten lower torso
//   ];
//   head = [
//       up(50) * scale([1.2,0.8,1]), mb_sphere(10, cutoff = 15),
//       // nose
//       move([0,-11,50]), mb_cuboid(2),
//       // eye sockets
//       move([5,-10,54]), mb_sphere(0.5, negative = true),
//       move([-5,-10,54]), mb_sphere(0.5, negative = true),
//       // tail
//       move([0,15,6]), mb_sphere(2, cutoff = 5)
//   ];
//   hind_leg = [ 
//       move([-15,-5,3]) * scale([1.5,4,1.75]), mb_sphere(5),
//       move([-15,10,3]), mb_sphere(3, negative = true)
//   ];
//   front_leg = [ 
//       move([-9,-4,30]) * zrot(30) * scale([1.5,5,1.75]), mb_sphere(3),
//       move([-9,10,30]), mb_sphere(2, negative = true)
//   ];
//   ear = [
//       yrot(10) * move([0,0,65]) * scale([4,1,7]), mb_sphere(2),
//       yrot(10)*move([0,-3,65])*scale([3,2,6]), mb_sphere(2, cutoff = 2, influence =2, negative = true)
//   ];
//   vnf_hindleg = metaballs(hind_leg, [[-22,-24,0],[-8,7,11]], voxel_size=0.8);
//   vnf_frontleg = metaballs(front_leg, [[-16,-17,25], [-1,7,35]], voxel_size=0.6);
//   vnf_ear = metaballs(ear, [[3,-2,50],[20,2,78]], voxel_size=0.6);
//   color("BurlyWood") {
//       metaballs([IDENT, torso, IDENT, head],
//           [[-16,-17,0],[16,20,63]], voxel_size=0.7);
//       xflip_copy() {
//           vnf_polyhedron(vnf_hindleg);
//           vnf_polyhedron(vnf_frontleg);
//           vnf_polyhedron(vnf_ear);;
//       }
//   }
//   // add eyes
//   xflip_copy() move([5,-8,54]) color("skyblue") sphere(2, $fn = 32);
//   // add teeth
//   xflip_copy() move([1.1,-10,44]) color("white") cuboid([2,0.5,4], rounding = 0.15);
// Example(3D,Med,NoAxes,VPD=120,VPT=[2,0,6],VPR=[60,0,320]): A model of a duck made from spheres, disks, a capsule, and a cone for the tail.
//   b_box = [[-31,-18,-10], [29,18,31]];
//   headZ = 21;
//   headX = 11;
//   spec = [
//       // head
//       left(headX)*up(headZ)*scale([1,0.9,1]), mb_sphere(10,cutoff=11), //skull
//       left(headX)*up(14), mb_disk(3,5, influence=0.5), //neck shim
//       left(headX+5)*up(headZ-1)*fwd(5),  mb_disk(1,2, cutoff=4), //cheek bulge
//       left(headX+5)*up(headZ-1)*back(5), mb_disk(1,2, cutoff=4), //cheek bulge
//       // eye indentations
//       move([-headX,0,headZ+3])*zrot(70)*left(9)*yrot(25)*scale([1,3,1.3]), mb_sphere(1, negative=true, influence=1, cutoff=10),
//       move([-headX,0,headZ+3])*zrot(-70)*left(9)*yrot(25)*scale([1,3,1.3]), mb_sphere(1, negative=true, influence=1, cutoff=10),
//       // beak
//       left(headX+13)*up(headZ)*zscale(0.4)*yrot(90), mb_capsule(12,3, cutoff=5),
//       left(headX+8)*up(headZ), mb_disk(2,4),
//       left(headX+16)*up(30), mb_sphere(5, negative=true, cutoff=8),
//       left(headX+12)*up(headZ+1)*scale([1.2,1,0.75]), mb_sphere(2, cutoff = 3),
//       // body
//       scale([1.5,1,1]), mb_disk(17,15), //body
//       // tail
//       right(20)*up(8)*yscale(1.7)*yrot(35), mb_cyl(h=15, r1=4, r2=0.5) 
//   ];
//   metaballs(spec, b_box, voxel_size=0.75);
//   // add eyeballs
//   yflip_copy()
//       move([-headX,0,headZ+2.5])zrot(53)left(4.9) color("#223300") sphere(3,$fn=64);
// Example(3D,Med,NoAxes,VPD=120,VPT=[2,0,6],VPR=[60,0,320]): Specifying `debug=true`, we can see the elements used to construct the duck. Positive metaballs are blue and negative metaballs are orange. Unfortunately, although the head is a rather complex structure, the big blue skull element covers up other details. Note also that removing the voxel_size parameter from `metaballs()` speeds up the preview.
//   b_box = [[-31,-18,-10], [29,18,31]];
//   headZ = 21;
//   headX = 11;
//   spec = [
//       // head
//       left(headX)*up(headZ)*scale([1,0.9,1]), mb_sphere(10,cutoff=11), //skull
//       left(headX)*up(14), mb_disk(3,5, influence=0.5), //neck shim
//       left(headX+5)*up(headZ-1)*fwd(5),  mb_disk(1,2, cutoff=4), //cheek bulge
//       left(headX+5)*up(headZ-1)*back(5), mb_disk(1,2, cutoff=4), //cheek bulge
//       // eye indentations
//       move([-headX,0,headZ+3])*zrot(70)*left(9)*yrot(25)*scale([1,3,1.3]), mb_sphere(1, negative=true, influence=1, cutoff=10),
//       move([-headX,0,headZ+3])*zrot(-70)*left(9)*yrot(25)*scale([1,3,1.3]), mb_sphere(1, negative=true, influence=1, cutoff=10),
//       // beak
//       left(headX+13)*up(headZ)*zscale(0.4)*yrot(90), mb_capsule(12,3, cutoff=5),
//       left(headX+8)*up(headZ), mb_disk(2,4),
//       left(headX+16)*up(30), mb_sphere(5, negative=true, cutoff=8),
//       left(headX+12)*up(headZ+1)*scale([1.2,1,0.75]), mb_sphere(2, cutoff = 3),
//       // body
//       scale([1.5,1,1]), mb_disk(17,15), //body
//       // tail
//       right(20)*up(8)*yscale(1.7)*yrot(35), mb_cyl(h=15, r1=4, r2=0.5) 
//   ];
//   metaballs(spec, b_box, debug=true); // removed voxel_size, set debug=true
//   // add eyeballs
//   yflip_copy()
//       move([-headX,0,headZ+2.5])zrot(53)left(4.9) color("#223300") sphere(3,$fn=64);
// Example(3D,Med,NoAxes,VPD=79,VPT=[-9,10,10],VPR=[50,0,340]): Adding `hide_debug=true` to the skull metaball function suppresses its display and reveals the neck and cheek components formerly covered by the skull metaball. Here we also disabled the addition of eyeballs, and reduced the size of the bounding box to enclose only the head. The bounding box is for computing the metaball surface; the debug components still display outside these bounds.
//   b_box = [[-31,-18,11], [0,18,31]];
//   headZ = 21;
//   headX = 11;
//   spec = [
//       // head
//       left(headX)*up(headZ)*scale([1,0.9,1]), mb_sphere(10,cutoff=11,hide_debug=true), //skull
//       left(headX)*up(14), mb_disk(3,5, influence=0.5), //neck shim
//       left(headX+5)*up(headZ-1)*fwd(5),  mb_disk(1,2, cutoff=4), //cheek bulge
//       left(headX+5)*up(headZ-1)*back(5), mb_disk(1,2, cutoff=4), //cheek bulge
//       // eye indentations
//       move([-headX,0,headZ+3])*zrot(70)*left(9)*yrot(25)*scale([1,3,1.3]), mb_sphere(1, negative=true, influence=1, cutoff=10),
//       move([-headX,0,headZ+3])*zrot(-70)*left(9)*yrot(25)*scale([1,3,1.3]), mb_sphere(1, negative=true, influence=1, cutoff=10),
//       // beak
//       left(headX+13)*up(headZ)*zscale(0.4)*yrot(90), mb_capsule(12,3, cutoff=5),
//       left(headX+8)*up(headZ), mb_disk(2,4),
//       left(headX+16)*up(30), mb_sphere(5, negative=true, cutoff=8),
//       left(headX+12)*up(headZ+1)*scale([1.2,1,0.75]), mb_sphere(2, cutoff = 3),
//       // body
//       scale([1.5,1,1]), mb_disk(17,15), //body
//       // tail
//       right(20)*up(8)*yscale(1.7)*yrot(35), mb_cyl(h=15, r1=4, r2=0.5) 
//   ];
//   metaballs(spec, b_box, debug=true); // removed voxel_size, set debug=true
//   // add eyeballs
//   * yflip_copy()
//       move([-headX,0,headZ+2.5])zrot(53)left(4.9) color("#223300") sphere(3,$fn=64);
// Example(3D,VPD=83,NoAxes): Adapting the multi-lobe function from Example 21 above, here we show how to display a debug-view VNF approximating the shape of the metaball when `debug=true`, *without* resorting to the full custom function implementation demonstrated in Example 22. Rather than having just the function literal in the `spec` array, we use `[function_literal, [sign,vnf]]` instead, where `sign` is the sign of the metaball (-1 or 1) and `vnf` is the VNF of the debug-view shape.
//   // custom metaball function - a lobed object
//   function multilobe(point, size, lobes) =
//      let(
//           ang=atan2(point.y, point.x),
//           r=norm([point.x,point.y])*(1.4+cos(lobes*ang)),
//           dist=norm([point.z, r])
//      ) size/dist;
//   
//   // custom metaball debug VNF - n-pointed star
//   function lobes_debug_vnf(r, n) =
//       let(nstar=zrot(180/n,p=path3d(star(n,r,r/6),0)))
//          vnf_vertex_array(
//            [down(0.3*r,nstar), up(0.3*r,nstar)],
//            col_wrap=true, caps=true);
//   
//   // show the object with debug VNF defined
//   lobes = 5;
//   size = 8;
//   spec = [
//       IDENT,
//       [ // use [func,[sign,vnf]] instead of func
//           function(point) multilobe(point,size,lobes),
//           [1, lobes_debug_vnf(size*2, lobes)]
//       ]
//   ];
//   metaballs(spec,
//       bounding_box = [[-20,-20,-8],[20,20,8]],
//       voxel_size=0.5, debug=true);

$metaball_vnf = undef; // set by module for possible use with children()

module metaballs(spec, bounding_box, voxel_size, voxel_count, isovalue=1, closed=true, exact_bounds=false, convexity=6, cp="centroid", anchor="origin", spin=0, orient=UP, atype="hull", show_stats=false, show_box=false, debug=false) {
    vnflist = metaballs(spec, bounding_box, voxel_size, voxel_count, isovalue, closed, exact_bounds, show_stats, _debug=debug);
    $metaball_vnf = debug ? vnflist[0] : vnflist; // for possible use with children
    if(debug) {
        // display debug polyhedrons
        for(a=vnflist[1])
            color(a[0]==0 ? "gray" : a[0]>0 ? "#3399FF" : "#FF9933")
                vnf_polyhedron(a[1]);
        // display metaball surface as transparent
        %vnf_polyhedron(vnflist[0], convexity=convexity, cp=cp, anchor=anchor, spin=spin, orient=orient, atype=atype)
            children();        
    } else { // debug==false, just display the metaball surface
        vnf_polyhedron(vnflist, convexity=convexity, cp=cp, anchor=anchor, spin=spin, orient=orient, atype=atype)
            children();
    }
    if(show_box)
        let(bbox = _getbbox(voxel_size, bounding_box, exact_bounds, undef))
            %translate(bbox[0]) cube(bbox[1]-bbox[0]);
}

function metaballs(spec, bounding_box, voxel_size, voxel_count, isovalue=1, closed=true, exact_bounds=false, show_stats=false, _debug=false) =
    assert(all_defined([spec, bounding_box]), "\nThe parameters spec and bounding_box must both be defined.")
    assert(num_defined([voxel_size, voxel_count])<=1, "\nOnly one of voxel_size or voxel_count can be defined.")
    assert(is_undef(voxel_size) || (is_finite(voxel_size) && voxel_size>0) || (is_vector(voxel_size) && all_positive(voxel_size)), "\nvoxel_size must be a positive number, a 3-vector of positive values, or not given.")
    assert(is_finite(isovalue) || (is_list(isovalue) && len(isovalue)==2 && is_num(isovalue[0]) && is_num(isovalue[1])), "\nIsovalue must be a number or a range; a number is the same as [number,INF].")
    assert(len(spec)%2==0, "\nThe spec parameter must be an even-length list of alternating transforms and functions")
    let(
        isoval = is_list(isovalue) ? isovalue : [isovalue, INF],
        funclist = _mb_unwind_list(spec),
        nballs = len(funclist)/2,
        dummycheck = [
            for(i=[0:len(spec)/2-1]) let(j=2*i)
                assert(is_matrix(spec[j],4,4), str("\nspec entry at position ", j, " must be a 4×4 matrix."))
                assert(is_function(spec[j+1]) || is_list(spec[j+1]), str("\nspec entry at position ", j+1, " must be a function literal or a metaball list.")) 0
        ],
        // set up transformation matrices in advance
        transmatrix = [
            for(i=[0:nballs-1])
                let(j=2*i)
                transpose(select(matrix_inverse(funclist[j]), 0,2))
        ],

        // new voxel or bounding box centered around original, to fit whole voxels
        bbox0 = is_num(bounding_box)
            ? let(hb=0.5*bounding_box) [[-hb,-hb,-hb],[hb,hb,hb]]
            : bounding_box,
        autovoxsize = is_def(voxel_size) ? voxel_size : _getautovoxsize(bbox0, default(voxel_count,22^3)),
        voxsize = _getvoxsize(autovoxsize, bbox0, exact_bounds),
        newbbox = _getbbox(voxsize, bbox0, exact_bounds),

        // set up field array
        bot = newbbox[0],
        top = newbbox[1],
        halfvox = 0.5*voxsize,
        // accumulate metaball contributions using matrices rather than sums
        xset = [bot.x:voxsize.x:top.x+halfvox.x],
        yset = list([bot.y:voxsize.y:top.y+halfvox.y]),
        zset = list([bot.z:voxsize.z:top.z+halfvox.z]),
        allpts = [for(x=xset, y=yset, z=zset) [x,y,z,1]],
        trans_pts = [for(i=[0:nballs-1]) allpts*transmatrix[i]],
        allvals = [for(i=[0:nballs-1]) [for(pt=trans_pts[i]) funclist[2*i+1][0](pt)]],
        //total = _sum(allvals,allvals[0]*EPSILON),
        total = _sum(slice(allvals,1,-1), allvals[0]),
        fieldarray = list_to_matrix(list_to_matrix(total,len(zset)),len(yset)),
        surface = isosurface(fieldarray, isoval, newbbox, voxsize, closed=closed, exact_bounds=true, show_stats=show_stats, _mball=true)
    ) _debug ? [
        surface, [
            for(i=[0:2:len(funclist)-1])
                let(fl=funclist[i+1][1])
                    [ fl[0], apply(funclist[i], fl[1]) ]
        ]
    ]
    : surface;

/// internal function: unwrap nested metaball specs in to a single list
function _mb_unwind_list(list, parent_trans=[IDENT], depth=0) =
    let(
        dum1 = assert(is_list(list), "\nDid not find valid list of metaballs."),
        n=len(list),
        dum2 = assert(n%2==0, "\nList of metaballs must have an even number of elements with alternating transforms and functions/lists.")
    ) [
        for(i=[0:2:n-1])
            let(
                dum = assert(is_matrix(list[i],4,4), str("\nInvalid 4×4 transformation matrix found at position ",i,", depth ",depth,": ", list[i])),
                trans = parent_trans[0] * list[i],
                j=i+1
            )   if (is_function(list[j])) // for custom function without brackets...
                    each [trans, [list[j], [0, debug_tetra(5)]]] // ...add brackets and default vnf
                else if (is_function(list[j][0]) &&  // for bracketed function with undef or empty VNF...
                   (is_undef(list[j][1]) || len(list[j][1])==0))
                    each [trans, [list[j][0], [0, debug_tetra(5)]]] // ...add brackets and default vnf
                else if (is_function(list[j][0]) &&  // for bracketed function with only empty VNF...
                   (len(list[j][1])>0 && is_num(list[j][1][0]) && len(list[j][1][1])==0))
                    each [trans, [list[j][0], [list[j][1][0], debug_tetra(5)]]] // ...do a similar thing
                else if(is_function(list[j][0]))
                    each [trans, list[j]]
                else if (is_list(list[j][0])) // likely a nested spec if not a function
                    each _mb_unwind_list(list[j], [trans], depth+1)
                else                 
                    assert(false, str("\nExpected function literal or list at position ",j,", depth ",depth,"."))
    ];



/// ---------- isosurface stuff starts here ----------

// Function&Module: isosurface()
// Synopsis: Creates a 3D isosurface (a 3D contour) from a function or array of values.
// SynTags: Geom,VNF
// Topics: Isosurfaces, VNF Generators
// Usage: As a module
//   isosurface(f, isovalue, bounding_box, voxel_size, [voxel_count=], [reverse=], [closed=], [exact_bounds=], [show_stats=], ...) [ATTACHMENTS];
// Usage: As a function
//   vnf = isosurface(f, isovalue, bounding_box, voxel_size, [voxel_count=], [reverse=], [closed=], [exact_bounds=], [show_stats=]);
// Description:
//   Computes a [VNF structure](vnf.scad) of an object bounded by an isosurface or a range between two isosurfaces, within a specified bounding box.
//   The isosurface of a function $f(x,y,z)$ is the set of points where $f(x,y,z)=c$ for some
//   constant isovalue $c$.
//   To provide a function, you supply a [function literal](https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/User-Defined_Functions_and_Modules#Function_literals)
//   taking an `[x,y,z]` coordinate as input to define the grid coordinate location and
//   returning a single numerical value.
//   You can also define an isosurface using a 3D array of values instead of a function, in which
//   case the isosurface is the set of points equal to the isovalue as interpolated from the array.
//   The array indices are in the order `[x][y][z]`.
//   .
//   The isovalue must be specified as a range `[c_min,c_max]`. The range can be finite or unbounded at one
//   end, with either `c_min=-INF` or `c_max=INF`. The returned object is the set of points `[x,y,z]` that
//   satisfy `c_min <= f(x,y,z) <= c_max`. If `f(x,y,z)` has values larger than `c_min` and values smaller than
//   `c_max`, then the result is a shell object with two bounding surfaces corresponding to the
//   isosurfaces at `c_min` and `c_max`. If `f(x,y,z) < c_max`
//   everywhere (which is true when `c_max = INF`), then no isosurface exists for `c_max`, so the object
//   has only one bounding surface: the one defined by `c_min`. This can result in a bounded object
//   like a sphere, or it can result an an unbounded object such as all the points outside of a sphere out
//   to infinity. A similar situation arises if `f(x,y,z) > c_min` everywhere (which is true when
//   `c_min = -INF`). Setting isovalue to `[-INF,c_max]` or `[c_min,INF]` always produces an object with a
//   single bounding isosurface, which itself can be unbounded. To obtain a bounded object, think about
//   whether the function values inside your object are smaller or larger than your isosurface value. If
//   the values inside are smaller, you produce a bounded object using `[-INF,c_max]`. If the values
//   inside are larger, you get a bounded object using `[c_min,INF]`.
//   .
//   The isosurface is evaluated over a bounding box, which can be a scalar cube, or specified by its
//   minimum and maximum corners `[[xmin,ymin,zmin],[xmax,ymax,zmax]]`. This bounding box is divided into
//   voxels of the specified `voxel_size`, which can also be a scalar cube, or a vector size. Smaller
//   voxels produce a finer, smoother result at the expense of execution time. By default, if the voxel
//   size doesn't exactly divide your specified bounding box, then the bounding box is enlarged to
//   contain whole voxels, and centered on your requested box. Alternatively, you may set
//   `exact_bounds=true` to force the voxels to adjust in size to fit instead.
//   Either way, if the bounding box clips the isosurface and `closed=true` (the default), a surface is
//   added to create a closed manifold object. Setting `closed=false` causes the VNF faces to end at the
//   bounding box, resulting in a non-manifold shape that exposes the inside of the object.
//   .
//   ***Why does my object appear as a cube?*** If your object is unbounded, then when it intersects with
//   the bounding box and `closed=true`, the result may appear to be a solid cube, because the clipping
//   faces are all you can see and the bounding surface is hidden inside. Setting `closed=false` removes
//   the bounding box faces and exposes the inside structure (with inverted faces). If you want the bounded
//   object, you can correct this problem by changing your isovalue range. If you were using a finite range
//   `[c1,c2]`, try changing it to `[c2,INF]` or `[-INF,c1]`. If you were using an unbounded range like
//   `[c,INF]`, try switching the range to `[-INF,c]`.
//   .
//   ***Run time:*** The size of the voxels and size of the bounding box affects the run time, which can be long.
//   A voxel size of 1 with a bounding box volume of 200×200×200 may be slow because it requires the
//   calculation and storage of 8,000,000 function values, and more processing and memory to generate
//   the triangulated mesh.  On the other hand, a voxel size of 5 over a 100×100×100 bounding box
//   requires only 8,000 function values and a modest computation time. A good rule is to keep the number
//   of voxels below 10,000 for preview, and adjust the voxel size smaller for final rendering. If you don't
//   specify voxel_size or voxel_count then metaballs uses a default voxel_count of 10000, which should be
//   reasonable for initial preview. Because a bounding
//   box that is too large wastes time computing function values that are not needed, you can also set the
//   parameter `show_stats=true` to get the actual bounds of the voxels intersected by the surface. With this
//   information, you may be able to decrease run time, or keep the same run time but increase the resolution. 
//   .
//   ***Manifold warnings:*** The point list in the generated VNF structure contains many duplicated points. This is normally not a
//   problem for rendering the shape, but machine roundoff differences may result in Manifold issuing
//   warnings when doing the final render, causing rendering to abort if you have enabled the "stop on
//   first warning" setting. You can prevent this by passing the VNF through {{vnf_quantize()}} using a
//   quantization of 1e-7, or you can pass the VNF structure into {{vnf_merge_points()}}, which also
//   removes the duplicates. Additionally, flat surfaces (often resulting from clipping by the bounding
//   box) are triangulated at the voxel size resolution, and these can be unified into a single face by
//   passing the vnf structure to {{vnf_unify_faces()}}. These steps can be computationally expensive
//   and are not normally necessary.
// Arguments:
//   f = The isosurface function literal or array. As a function literal, `x,y,z` must be the first arguments. 
//   isovalue = A 2-vector giving an isovalue range. For an unbounded range, use `[-INF, max_isovalue]` or `[min_isovalue, INF]`.
//   bounding_box = The volume in which to perform computations, expressed as a scalar size of a cube centered on the origin, or a pair of 3D points `[[xmin,ymin,zmin], [xmax,ymax,zmax]]` specifying the minimum and maximum box corner coordinates. Unless you set `exact_bounds=true`, the bounding box size may be enlarged to fit whole voxels. When `f` is an array of values, `bounding_box` cannot be supplied if `voxel_size` is supplied because the bounding box is already implied by the array size combined with `voxel_size`, in which case this implied bounding box is centered around the origin.
//   voxel_size = Size of the voxels used to sample the bounding box volume, can be a scalar or 3-vector, or omitted if `voxel_count` is set. You may get a non-cubical voxels of a slightly different size than requested if `exact_bounds=true`.
//   ---
//   voxel_count = Approximate number of voxels in the bounding box. If `exact_bounds=true` then the voxels may not be cubes. Use with `show_stats=true` to see the corresponding voxel size. Default: 10000 (if `voxel_size` not set)
//   closed = When true, close the surface if it intersects the bounding box by adding a closing face. When false, do not add a closing face and instead produce a non-manfold VNF that has holes.  Default: true
//   reverse = When true, reverses the orientation of the VNF faces. Default: false
//   exact_bounds = When true, shrinks voxels as needed to fit whole voxels inside the requested bounding box. When false, enlarges `bounding_box` as needed to fit whole voxels of `voxel_size`, and centers the new bounding box over the requested box. Default: false
//   show_stats = If true, display statistics in the console window about the isosurface: number of voxels that the surface passes through, number of triangles, bounding box of the voxels, and voxel-rounded bounding box of the surface, which may help you reduce your bounding box to improve speed. Enabling this parameter has a slight speed penalty. Default: false
//   show_box = (Module only) display the requested bounding box as transparent. This box may appear slightly inside the bounds of the figure if the actual bounding box had to be expanded to accommodate whole voxels. Default: false
//   convexity = (Module only) Maximum number of times a line could intersect a wall of the shape. Affects preview only. Default: 6
//   cp = (Module only) Center point for determining intersection anchors or centering the shape. Determines the base of the anchor vector. Can be "centroid", "mean", "box" or a 3D point.  Default: "centroid"
//   anchor = (Module only) Translate so anchor point is at origin (0,0,0). See [anchor](attachments.scad#subsection-anchor).  Default: `"origin"`
//   spin = (Module only) Rotate this many degrees around the Z axis after anchor. See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = (Module only) Vector to rotate top toward, after spin. See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   atype = (Module only) Select "hull" or "intersect" anchor type.  Default: "hull"
// Anchor Types:
//   "hull" = Anchors to the virtual convex hull of the shape.
//   "intersect" = Anchors to the surface of the shape.
// Named Anchors:
//   "origin" = Anchor at the origin, oriented UP.
// Example(3D,VPD=85,VPT=[0,0,2],VPR=[55,0,30]): These first three examples demonstrate the effect of isovalue range for the simplest of all surfaces: a sphere where $r=\sqrt{x^2+y^2+z^2}$, or `r = norm([x,y,z])` in OpenSCAD. Then, the isosurface corresponding to an isovalue of 10 is every point where the expression `norm([x,y,z])` equals a radius of 10. We use the isovalue range `[-INF,10]` here to make the sphere, with a bounding box that cuts off half the sphere. The isovalue range could also be `[0,10]` because the minimum value of the expression is zero.
//   isovalue = [-INF,10];
//   bbox = [[-11,-11,-11], [0,11,11]];
//   isosurface(function (x,y,z) norm([x,y,z]),
//      isovalue, bbox, voxel_size = 1);
// Example(3D,VPD=85,VPT=[0,0,2],VPR=[55,0,30]): An isovalue range `[8,10]` gives a shell with inner radius 8 and outer radius 10.
//   isovalue = [8,10];
//   bbox = [[-11,-11,-11], [0,11,11]];
//   isosurface(function (x,y,z) norm([x,y,z]),
//      isovalue, bbox, voxel_size = 1);
// Example(3D,VPD=85,VPT=[0,0,2],VPR=[55,0,30]): Here we set the isovalue range to `[10,INF]`. Because the sphere expression `norm(xyz)` has larger values growing to infinity with distance from the origin, the resulting object appears as the bounding box with a radius-10 spherical hole.
//   isovalue = [10,INF];
//   bbox = [[-11,-11,-11], [0,11,11]];
//   isosurface(function (x,y,z) norm([x,y,z]),
//      isovalue, bbox, voxel_size = 1);
// Example(3D,ThrownTogether,NoAxes): Unlike a sphere, a gyroid is unbounded; it's an isosurface defined by all the zero values of a 3D periodic function. To illustrate what the surface looks like, `closed=false` has been set to expose both sides of the surface. The surface is periodic and tileable along all three axis directions. This is a non-manifold surface as displayed, not useful for 3D modeling. This example also demonstrates using an additional parameter in the field function beyond just the `[x,y,z]` input; in this case to control the wavelength of the gyroid.
//   function gyroid(x,y,z, wavelength) = let(
//       p = 360/wavelength * [x,y,z]
//   ) sin(p.x)*cos(p.y)+sin(p.y)*cos(p.z)+sin(p.z)*cos(p.x);
//   isovalue = [0,INF];
//   bbox = [[-100,-100,-100], [100,100,100]];
//   isosurface(function(x,y,z) gyroid(x,y,z, wavelength=200),
//       isovalue, bbox, voxel_size=5, closed=false);
// Example(3D,NoAxes): If we remove the `closed` parameter or set it to true, the isosurface algorithm encloses the entire half-space bounded by the "inner" gyroid surface, leaving only the "outer" surface exposed. This is a manifold shape but not what we want if trying to model a gyroid.
//   function gyroid(x,y,z, wavelength) = let(
//       p = 360/wavelength * [x,y,z]
//   ) sin(p.x)*cos(p.y)+sin(p.y)*cos(p.z)+sin(p.z)*cos(p.x);
//   isovalue = [0,INF];
//   bbox = [[-100,-100,-100], [100,100,100]];
//   isosurface(function(x,y,z) gyroid(x,y,z, wavelength=200),
//       isovalue, bbox, voxel_size=5, closed=true);
// Example(3D,ThrownTogether,NoAxes): To make the gyroid a double-sided surface, we need to specify a small range around zero for `isovalue`. Now we have a double-sided surface although with `closed=false` the edges are not closed where the surface is clipped by the bounding box.
//   function gyroid(x,y,z, wavelength) = let(
//       p = 360/wavelength * [x,y,z]
//   ) sin(p.x)*cos(p.y)+sin(p.y)*cos(p.z)+sin(p.z)*cos(p.x);
//   isovalue = [-0.3, 0.3];
//   bbox = [[-100,-100,-100], [100,100,100]];
//   isosurface(function(x,y,z) gyroid(x,y,z, wavelength=200),
//       isovalue, bbox, voxel_size=5, closed=false);
// Example(3D,ThrownTogether,NoAxes): To make the gyroid a valid manifold 3D object, we remove the `closed` parameter (same as setting `closed=true`), which closes the edges where the surface is clipped by the bounding box.
//   function gyroid(x,y,z, wavelength) = let(
//       p = 360/wavelength * [x,y,z]
//   ) sin(p.x)*cos(p.y)+sin(p.y)*cos(p.z)+sin(p.z)*cos(p.x);
//   isovalue = [-0.3, 0.3];
//   bbox = [[-100,-100,-100], [100,100,100]];
//   isosurface(function(x,y,z) gyroid(x,y,z, wavelength=200),
//       isovalue, bbox, voxel_size=5);
// Example(3D,NoAxes): An approximation of the triply-periodic minimal surface known as [Schwartz P](https://en.wikipedia.org/wiki/Schwarz_minimal_surface).
//   function schwartz_p(x,y,z, wavelength) = let(
//       p = 360/wavelength,
//       px = p*x, py = p*y, pz = p*z
//   )  cos(px) + cos(py) + cos(pz);
//   isovalue = [-0.2, 0.2];
//   bbox = [[-100,-100,-100], [100,100,100]];
//   isosurface(function (x,y,z) schwartz_p(x,y,z, 100),
//       isovalue, bounding_box=bbox, voxel_size=4);
// Example(3D,NoAxes): Another approximation of the triply-periodic minimal surface known as [Neovius](https://en.wikipedia.org/wiki/Neovius_surface).
//   function neovius(x,y,z, wavelength) = let(
//       p = 360/wavelength,
//       px = p*x, py = p*y, pz = p*z
//   )  3*(cos(px) + cos(py) + cos(pz)) + 4*cos(px)*cos(py)*cos(pz);
//   bbox = [[-100,-100,-100], [100,100,100]];
//   isosurface(function (x,y,z) neovius(x,y,z, 200),
//       isovalue = [-0.3, 0.3],
//       bounding_box = bbox, voxel_size=4);
// Example(3D,NoAxes): Example of a bounded isosurface.
//   isosurface(
//       function (x,y,z)
//           let(a=xyz_to_spherical([x,y,z]), 
//               r=a[0],
//               phi=a[1],
//               theta=a[2]
//           ) 1/(r*(3+cos(5*phi)+cos(4*theta))),
//       isovalue = [0.1,INF],
//       bounding_box = [[-8,-7,-8],[6,7,8]],
//       voxel_size = 0.25);
// Example(3D,NoAxes): Another example of a bounded isosurface.
//   isosurface(function (x,y,z)
//         2*(x^4 - 2*x*x + y^4 
//            - 2*y*y + z^4 - 2*z*z) + 3,
//       bounding_box=3, voxel_size=0.07,
//       isovalue=[-INF,0]);
// Example(3D,NoAxes): For shapes that occupy a cubical bounding box centered on the origin, you can simply specify a scalar for the size of the box.
//   isosurface(
//       function (x,y,z) let(np=norm([x,y,z]))
//          (x*y*z^3 + 19*x^2*z^2) / np^2 + np^2,
//       isovalue=[-INF,35], bounding_box=12, voxel_size=0.25);
// Example(3D,Med,NoAxes,VPD=165,VPR=[72,0,290],VPT=[0,0,0]): An object that could be a sort of support pillar. Here we set `show_box=true` to reveal that the bounding box is slightly bigger than it needs to be. The argument `show_stats=true` also outputs the voxel bounding box size as a suggestion of what it should be.
//   isosurface(
//       function (x,y,z) let(np=norm([x,y,z]))
//          (x*y*z^3 - 3*x^2*z^2) / np^2 + np^2,
//       isovalue=[-INF,35], bounding_box=[[-32,-32,-14],[32,32,14]],
//       voxel_size = 0.8, show_box=true);
// Example(3D,Med,NoAxes,VPD=47,VPT=[0,0,2]): You can specify non-cubical voxels for efficiency. This example shows the result of two identical surface functions. The figure on the left uses a `voxel_size=1`, which washes out the detail in the z direction. The figure on the right shows the same shape with `voxel_size=[0.5,1,0.2]` to give a bit more resolution in the x direction and much more resolution in the z direction. This example runs about six times faster than if we used a cubical voxel of size 0.2 to capture the detail in only one axis at the expense of unnecessary detail in other axes.
//   function shape(x,y,z, r=5) =
//       r / sqrt(x^2 + 0.5*(y^2 + z^2) + 0.5*r*cos(200*z));
//   bbox = [[-6,-8,0], [6,8,7]];
//   
//   left(6) isosurface(function (x,y,z) shape(x,y,z),
//       isovalue=[1,INF], bounding_box=bbox, voxel_size=1);
//   
//   right(6) isosurface(function (x,y,z) shape(x,y,z),
//       isovalue=[1,INF], bounding_box=bbox, voxel_size=[0.5,1,0.2]);
// Example(3D,NoAxes,VPD=50,VPT=[2,0,1]): Nonlinear functions with steep gradients between voxel corners at the isosurface value can show interpolation ridges because the surface position is approximated by a linear interpolation of a highly nonlinear function. The appearance of the artifacts depends on the combination of function, voxel size, and isovalue, and can look different in different circumstances. If your isovalue is positive, then you may be able to smooth out the artifacts by using the log of your function and the log of your isovalue range to get the same isosurface without artifacts. On the left, an isosurface around a steep nonlinear function (clipped on the left by the bounding box) exhibits severe interpolation artifacts. On the right, the log of the isosurface around the log of the function smooths it out nicely.
//   bbox = [[0,-10,-5],[9,10,6]];
//   
//   function shape(x,y,z) =
//           exp(-((x+5)/5-3)^2-y^2)
//           *exp(-((x+5)/3)^2-y^2-z^2)
//           + exp(-((y+4)/5-3)^2-x^2)
//           *exp(-((y+4)/3)^2-x^2-0.5*z^2);
//   
//   left(6) isosurface(function(x,y,z) shape(x,y,z),
//       isovalue = [EPSILON,INF],
//       bounding_box=bbox, voxel_size=0.25);
//   right(6) isosurface(function(x,y,z) log(shape(x,y,z)),
//       isovalue = [log(EPSILON),INF],
//       bounding_box=bbox, voxel_size=0.25);
// Example(3D): Using an array for the `f` argument instead of a function literal. Each row of the array represents an X index for a YZ plane with the array Z indices changing fastest in each plane. The final object may need rotation to get the orientation you want. You don't pass the `bounding_box` argument here; it is implied by the array size and voxel size, and centered on the origin.
//   field = [
//     repeat(0,[6,6]),
//     [ [0,1,2,2,1,0],
//       [1,2,3,3,2,1],
//       [2,3,4,4,3,2],
//       [2,3,4,4,3,2],
//       [1,2,3,3,2,1],
//       [0,1,2,2,1,0]
//     ],
//     [ [0,0,0,0,0,0],
//       [0,0,1,1,0,0],
//       [0,2,3,3,2,0],
//       [0,2,3,3,2,0],
//       [0,0,1,1,0,0],
//       [0,0,0,0,0,0]
//     ],
//     [ [0,0,0,0,0,0],
//       [0,0,0,0,0,0],
//       [0,1,2,2,1,0],
//       [0,1,2,2,1,0],
//       [0,0,0,0,0,0],
//       [0,0,0,0,0,0]
//     ],
//     repeat(0,[6,6])
//   ];
//   rotate([0,-90,180])
//      isosurface(field, isovalue=[0.5,INF],
//          voxel_size=10);

module isosurface(f, isovalue, bounding_box, voxel_size, voxel_count=undef, reverse=false, closed=true, exact_bounds=false, convexity=6, cp="centroid", anchor="origin", spin=0, orient=UP, atype="hull", show_stats=false, show_box=false, _mball=false) {
    vnf = isosurface(f, isovalue, bounding_box, voxel_size, voxel_count, reverse, closed, exact_bounds, show_stats, _mball);
    vnf_polyhedron(vnf, convexity=convexity, cp=cp, anchor=anchor, spin=spin, orient=orient, atype=atype)
        children();
    if(show_box)
        let(bbox = _getbbox(voxel_size, bounding_box, exact_bounds, f))
            %translate(bbox[0]) cube(bbox[1]-bbox[0]);
}

function isosurface(f, isovalue, bounding_box, voxel_size, voxel_count=undef, reverse=false, closed=true, exact_bounds=false, show_stats=false, _mball=false) =

    assert(all_defined([f, isovalue]), "\nThe parameters f and isovalue must both be defined.")
    assert(num_defined([voxel_size, voxel_count])<=1, "\nOnly one of voxel_size or voxel_count can be defined.")
    assert(is_undef(voxel_size) || (is_finite(voxel_size) && voxel_size>0) || (is_vector(voxel_size) && all_positive(voxel_size)), "\nvoxel_size must be a positive number, a 3-vector of positive values, or undef.")
    assert(is_list(isovalue) && len(isovalue)==2 && is_num(isovalue[0]) && is_num(isovalue[1]), "\nIsovalue must be a range; use [minvalue,INF] or [-INF,maxvalue] for an unbounded range.")
    assert(is_function(f) ||
        (is_list(f) &&
            // _mball=true allows voxel_size and bounding_box to coexist with f as array, because metaballs() already calculated them
            (_mball || 
                ((is_def(bounding_box) && is_undef(voxel_size)) || (is_undef(bounding_box) && is_def(voxel_size)))
            )
        )
        , "\nWhen f is an array, either bounding_box or voxel_size is required (but not both).")
    let(
        isovalmin = is_list(isovalue) ? isovalue[0] : isovalue,
        isovalmax = is_list(isovalue) ? isovalue[1] : INF,
        dumiso1 = assert(isovalmin < isovalmax, str("\nBad isovalue range (", isovalmin, ", >= ", isovalmax, "), should be expressed as [min_value, max_value].")),
        dumiso2 = assert(isovalmin != -INF || isovalmin != INF, "\nIsovalue range must be finite on one end."),
        exactbounds = is_def(exact_bounds) ? exact_bounds : is_list(f),

        // new voxel or bounding box centered around original, to fit whole voxels
        bbox0 = is_num(bounding_box)
            ? let(hb=0.5*bounding_box) [[-hb,-hb,-hb],[hb,hb,hb]]
            : bounding_box,
        autovoxsize = is_def(voxel_size) ? voxel_size : _getautovoxsize(bbox0, default(voxel_count,22^3)),
        voxsize = _mball ? voxel_size : _getvoxsize(autovoxsize, bbox0, exactbounds),
        bbox = _mball ? bounding_box : _getbbox(voxsize, bbox0, exactbounds, f),
        // proceed with isosurface computations
        cubes = _isosurface_cubes(voxsize, bbox,
            fieldarray=is_function(f)?undef:f, fieldfunc=is_function(f)?f:undef,
            isovalmin=isovalmin, isovalmax=isovalmax, closed=closed),
        tritablemin = reverse ? _MCTriangleTable_reverse : _MCTriangleTable,
        tritablemax = reverse ? _MCTriangleTable : _MCTriangleTable_reverse,
        trianglepoints = _isosurface_triangles(cubes, voxsize, isovalmin, isovalmax, tritablemin, tritablemax),
        faces = [
            for(i=[0:3:len(trianglepoints)-1])
                let(i1=i+1, i2=i+2)
                    if (norm(cross(trianglepoints[i1]-trianglepoints[i],
                        trianglepoints[i2]-trianglepoints[i])) > EPSILON)
                            [i,i1,i2]
        ],
        dum2 = show_stats ? _showstats_isosurface(voxsize, bbox, isovalue, cubes, trianglepoints, faces) : 0
) [trianglepoints, faces];

/// internal function: get voxel size given a desired number of voxels in a bounding box
function _getautovoxsize(bbox, numvoxels) =
    let(
        bbsiz = bbox[1]-bbox[0],
        bbvol = bbsiz[0]*bbsiz[1]*bbsiz[2],
        voxvol = bbvol/numvoxels
    ) voxvol^(1/3);

/// internal function: get voxel size, adjusted if necessary to fit bounding box
function _getvoxsize(voxel_size, bounding_box, exactbounds) =
    let(voxsize0 = is_num(voxel_size) ? [voxel_size, voxel_size, voxel_size] : voxel_size)
        exactbounds ? 
            let(
                reqboxsize = bounding_box[1] - bounding_box[0],
                bbnums = v_ceil(v_div(bounding_box[1]-bounding_box[0], voxsize0)),
                newboxsize = v_mul(bbnums, voxsize0)
            ) v_mul(voxsize0, v_div(reqboxsize, newboxsize))
        : voxsize0; // if exactbounds==false, we don't adjust voxel size

/// internal function: get bounding box, adjusted in size and centered on requested box
function _getbbox(voxel_size, bounding_box, exactbounds, f=undef) =
    let(
        voxsize0 = is_num(voxel_size) ? [voxel_size, voxel_size, voxel_size] : voxel_size,
        bbox = is_list(bounding_box) ? bounding_box
        : is_num(bounding_box) ? let(hb=0.5*bounding_box) [[-hb,-hb,-hb],[hb,hb,hb]]
        : let( // bounding_box==undef if we get here, then f must be an array
            bbnums = [len(f), len(f[0]), len(f[0][0])] - [1,1,1],
            halfbb = 0.5 * v_mul(voxsize0, bbnums)
        ) [-halfbb, halfbb]
    )   exactbounds ?
            bbox // if grow_bounds==false, we don't adjust bounding box
        : let(    // adjust bounding box
            bbcenter = mean(bbox),
            bbnums = v_ceil(v_div(bbox[1]-bbox[0], voxsize0)),
            halfbb = 0.5 * v_mul(voxsize0, bbnums)
        ) [bbcenter - halfbb, bbcenter + halfbb];

/// _showstats_isosurface() (Private function) - called by isosurface()
/// Display statistics about isosurface
function _showstats_isosurface(voxsize, bbox, isoval, cubes, triangles, faces) =
    let(
        voxbounds = len(cubes)>0 ? let(
            v = column(cubes, 0), // extract cube vertices
            x = column(v,0),    // extract x values
            y = column(v,1),    // extract y values
            z = column(v,2),    // extract z values
            xmin = min(x),
            xmax = max(x)+voxsize.x,
            ymin = min(y),
            ymax = max(y)+voxsize.y,
            zmin = min(z),
            zmax = max(z)+voxsize.z
        ) [[xmin,ymin,zmin], [xmax,ymax,zmax]] : "N/A",
        nvox = len(cubes),
        ntri = len(triangles),
        tribounds = ntri>0 ? pointlist_bounds(triangles) : "N/A"
    ) echo(str("\nIsosurface statistics:\n   Isovalue = ", isoval, "\n   Voxel size = ", voxsize,
        "\n   Voxels intersected by the surface = ", nvox,
        "\n   Triangles = ", ntri,
        "\n   VNF bounds = ", tribounds,
        "\n   Bounds for all data = ", bbox,
        "\n   Voxel bounding box for isosurface = ", voxbounds,
        "\n"));
