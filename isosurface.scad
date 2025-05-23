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
//   This file provides modules and functions to create a [VNF](vnf.scad) using metaballs, or from
//   general isosurfaces. This file also provides modules and functions to create 2d metaballs and
//   contours, where the output is a list of [paths](paths.scad), which can be open or closed paths.
//   .
//   For isosurfaces and 3D metaballs, the point list in the generated VNF structure contains many duplicated
//   points. This is normally not a problem for rendering the shape, but machine roundoff differences may
//   result in Manifold issuing warnings when doing the final render, causing rendering to abort if you have
//   enabled the "stop on first warning" setting. You can prevent this by passing the VNF through {{vnf_quantize()}}
//   using a quantization of 1e-7, or you can pass the VNF structure into {{vnf_merge_points()}}, which also
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


//////////////////// 3D initializations and support functions ////////////////////

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


//////////////////// 2D initializations and support functions ////////////////////

/*
"Marching triangles" algorithm

A square pixel has 5 vertices, four on each corner and one in the center. Vertices and edges are numbered as follows:

(1)                 (3)
   +-------1-------+
   | \           / |
   |   5       6   |
   |     \   /     |
   0      (4)      2
   |     /   \     |
   |   4       7   |
   | /           \ |
   +-------3-------+
(0)                 (2)

The vertices are assigned a value 1 if greater than or equal to the isovalue, or 0 if less than the isovalue.

These ones and zeros, when arranged as a binary number with vertex (0) being the least significant bit and vertex (4) the most significant, forms an address ranging from 0 to 31.

This address is used as an index in _MTriSegmentTable to get the order of edges that are crossed.
*/

// vertices that make each edge
_MTEdgeVertexIndices = [
    [0, 1],
    [1, 3],
    [3, 2],
    [2, 0],
    [0, 4],
    [1, 4],
    [3, 4],
    [2, 4]
];

// edge order for drawing a contour (or two contours) through a pixel, for all 32 possibilities of vertices being higher or lower than isovalue
_MTriSegmentTable = [ // marching triangle segment table
    [[], []],            // 0 - 00000
    [[0,4,3], []],       // 1 - 00001
    [[1,5,0], []],       // 2 - 00010
    [[1,5,4,3], []],     // 3 - 00011
    [[3,7,2], []],       // 4 - 00100
    [[0,4,7,2], []],     // 5 - 00101
    [[1,5,0], [3,7,2]],  // 6 - 00110 - 2 corners
    [[1,5,4,7,2], []],   // 7 - 00111
    [[2,6,1], []],       // 8 - 01000
    [[0,4,3], [2,6,1]],  // 9 - 01001 - 2 corners
    [[2,6,5,0], []],     //10 - 01010
    [[2,6,5,4,3], []],   //11 - 01011
    [[3,7,6,1], []],     //12 - 01100
    [[0,4,7,6,1], []],   //13 - 01101
    [[3,7,6,5,0], []],   //14 - 01110
    [[7,6,5,4,7], []],   //15 - 01111 low center - pixel encloses contour
    [[4,5,6,7,4], []],   //16 - 10000 high center - pixel encloses contour
    [[0,5,6,7,3], []],   //17 - 10001
    [[1,6,7,4,0], []],   //18 - 10010
    [[1,6,7,3], []],     //19 - 10011
    [[3,4,5,6,2], []],   //20 - 10100
    [[0,5,6,2], []],     //21 - 10101
    [[1,6,2], [3,4,0]],  //22 - 10110 - 2 corners
    [[1,6,2], []],       //23 - 10111
    [[2,7,4,5,1], []],   //24 - 11000
    [[0,5,1], [2,7,3]],  //25 - 11001 - 2 corners
    [[2,7,4,0], []],     //26 - 11010
    [[2,7,3], []],       //27 - 11011
    [[3,4,5,1], []],     //28 - 11100
    [[0,5,1], []],       //29 - 11101
    [[3,4,0], []],       //30 - 11110
    [[], []]             //31 - 11111
];

_MTriSegmentTable_reverse = [
    [[],[]],
    [[3,4,0],[]],
    [[0,5,1],[]],
    [[3,4,5,1],[]],
    [[2,7,3],[]],
    [[2,7,4,0],[]],
    [[0,5,1],[2,7,3]],
    [[2,7,4,5,1],[]],
    [[1,6,2],[]],
    [[3,4,0],[1,6,2]],
    [[0,5,6,2],[]],
    [[3,4,5,6,2],[]],
    [[1,6,7,3],[]],
    [[1,6,7,4,0],[]],
    [[0,5,6,7,3],[]],
    [[7,4,5,6,7],[]],
    [[4,7,6,5,4],[]],
    [[3,7,6,5,0],[]],
    [[0,4,7,6,1],[]],
    [[3,7,6,1],[]],
    [[2,6,5,4,3],[]],
    [[2,6,5,0],[]],
    [[2,6,1],[0,4,3]],
    [[2,6,1],[]],
    [[1,5,4,7,2],[]],
    [[1,5,0],[3,7,2]],
    [[0,4,7,2],[]],
    [[3,7,2],[]],
    [[1,5,4,3],[]],
    [[1,5,0],[]],
    [[0,4,3],[]],
    [[],[]]
];
/*
Low-res "marching squares" case has the same labeling but without the center vertex
and extra edges. In the two ambiguous cases with two opposite corners above and the
other two below the isovalue, it is assumed that the high values connect, to make
contours compatible with isosurface() at pixel boundaries.

(1)           (3)
   +----1----+
   |         |
   0         2
   |         |
   +----3----+
(0)           (2)
*/
_MSquareSegmentTable = [ // marching square segment table (lower res)
    [[], []],       // 0 - 0000
    [[0,3], []],    // 1 - 0001
    [[1,0], []],    // 2 - 0010
    [[1,3], []],    // 3 - 0011
    [[3,2], []],    // 4 - 0100
    [[0,2], []],    // 5 - 0101
    [[1,2], [3,0]], // 6 - 0110 - 2 opposite corners
    [[1,2], []],    // 7 - 0111
    [[2,1], []],    // 8 - 1000
    [[0,1], [2,3]], // 9 - 1001 - 2 opposite corners
    [[2,0], []],    //10 - 1010
    [[2,3], []],    //11 - 1011
    [[3,1], []],    //12 - 1100
    [[0,1], []],    //13 - 1101
    [[3,0], []],    //14 - 1110
    [[], []]        //15 - 1111
];

_MSquareSegmentTable_reverse = [
    [[],[]],
    [[3,0],[]],
    [[0,1],[]],
    [[3,1],[]],
    [[2,3],[]],
    [[2,0],[]],
    [[2,1],[0,3]],
    [[2,1],[]],
    [[1,2],[]],
    [[1,0],[3,2]],
    [[0,2],[]],
    [[3,2],[]],
    [[1,3],[]],
    [[1,0],[]],
    [[0,3],[]],
    [[],[]]
];

/// _mctrindex() - private function
/// Return the index ID of a pixel depending on the field strength at each vertex exceeding isoval.
function _mctrindex(f, isoval) =
    (f[0] >= isoval ? 1 : 0) +
    (f[1] >= isoval ? 2 : 0) +
    (f[2] >= isoval ? 4 : 0) +
    (f[3] >= isoval ? 8 : 0) +
    (is_def(f[4]) && f[4] >= isoval ? 16 : 0);

/// return an array of edgee indices in _MTEdgeVertexIndices if the pixel at coordinate pc corresponds to the bounding box.
function _bbox_sides(pc, pixsize, bbox) = let(
    a = v_abs(pc-bbox[0]),
    bb1 = bbox[1] - pixsize,
    b = pc-bb1
) [
    if(a[0]<EPSILON) 0,
    if(a[1]<EPSILON) 3,
    if(b[0]>=-EPSILON) 2,
    if(b[1]>=-EPSILON) 1
];


function _contour_pixels(pixsize, bbox, fieldarray, fieldfunc, pixcenters, isovalmin, isovalmax, closed=true) = let(
    // get field intensities
    hp = 0.5*pixsize,
    field = is_def(fieldarray)
    ? fieldarray
    : let(v = bbox[0], b1 = bbox[1]+[hp.x,hp.y]) [
        for(x=[v.x:pixsize.x:b1.x]) [
            for(y=[v.y:pixsize.y:b1.y])
                fieldfunc(x,y)
        ]
    ],
    has_center_array = is_list(pixcenters),
    nx = len(field)-2,
    ny = len(field[0])-2,
    v0 = bbox[0]
) let(
    isocorrectmin = (isovalmin>=0?1:-1)*max(abs(isovalmin)*1.000001, isovalmin+0.0000001),
    isocorrectmax = (isovalmax>=0?1:-1)*max(abs(isovalmax)*1.000001, isovalmax+0.0000001)
) [
    for(i=[0:nx]) let(x=v0.x+pixsize.x*i)
        for(j=[0:ny]) let(y=v0.y+pixsize.y*j)
            let(i1=i+1, j1=j+1,
                pf = let(
                    // clamp corner values to ±1e9, make sure no corner=isovalmin or isovalmax
                    f0=let(c=min(1e9,max(-1e9,field[i][j]))) abs(c-isovalmin)<EPSILON ? isocorrectmin : abs(c-isovalmax)<EPSILON ? isocorrectmax : c,
                    f1=let(c=min(1e9,max(-1e9,field[i][j1]))) abs(c-isovalmin)<EPSILON ? isocorrectmin : abs(c-isovalmax)<EPSILON ? isocorrectmax : c,
                    f2=let(c=min(1e9,max(-1e9,field[i1][j]))) abs(c-isovalmin)<EPSILON ? isocorrectmin : abs(c-isovalmax)<EPSILON ? isocorrectmax : c,
                    f3=let(c=min(1e9,max(-1e9,field[i1][j1]))) abs(c-isovalmin)<EPSILON ? isocorrectmin : abs(c-isovalmax)<EPSILON ? isocorrectmax : c
                ) [  // pixel corner field values
                    f0, f1, f2, f3,
                    // get center value of pixel
                    if (has_center_array)
                        pixcenters[i][j]
                    else if(pixcenters)
                        is_def(fieldfunc)
                            ? min(1e9,max(-1e9,fieldfunc(x+hp.x, y+hp.y)))
                            : 0.25*(f0 + f1 + f2 + f3)
                ],
                minpf = min(pf),
                maxpf = max(pf),
                pixcoord = [x,y],
                psides = closed ? _bbox_sides(pixcoord, pixsize, bbox) : [],
                pixfound_isomin = (minpf <= isovalmin && isovalmin <= maxpf),
                pixfound_isomax = (minpf <= isovalmax && isovalmax <= maxpf),
                pixfound_outer = len(psides)==0 ? false
                : let(
                    ps = flatten([for(i=psides) _MTEdgeVertexIndices[i]]),
                    sumcond = len([for(p=ps) if(isovalmin<=pf[p] && pf[p]<=isovalmax) 1])
                ) sumcond == len(ps), // true if full edge is between isovalmin and isovalmax
                pixindex_isomin = pixfound_isomin ? _mctrindex(pf, isovalmin) : 0,
                pixindex_isomax = pixfound_isomax ? _mctrindex(pf, isovalmax) : 0
            ) if(pixfound_isomin || pixfound_isomax || pixfound_outer) [
                pixcoord,           // pixel lower coordinate
                pixindex_isomin,    // pixel ID for isomin
                pixindex_isomax,    // pixel ID for isomax
                pf,                 // clamped pixel corner values
                psides              // list of bounding box sides, if any
            ]
];


function _contour_vertices(pxlist, pxsize, isovalmin, isovalmax, segtablemin, segtablemax) = [
    for(px = pxlist) let(
        v = px[0],
        idxmin = px[1],
        idxmax = px[2],
        f = px[3],
        bbsides = px[4],
        vpix = [ v, v+[0,pxsize.y], v+[pxsize.x,0], v+[pxsize.x,pxsize.y], v+0.5*[pxsize.x,pxsize.y] ]
    ) each [
        for(sp=segtablemin[idxmin]) // min contour
            if(len(sp)>0) [
                for(p=sp)
                    let(
                        edge = _MTEdgeVertexIndices[p],
                        vi0 = edge[0],
                        vi1 = edge[1],
                        denom = f[vi1] - f[vi0],
                        u = abs(denom)<0.00001 ? 0.5 : (isovalmin-f[vi0]) / denom
                      ) vpix[vi0] + u*(vpix[vi1]-vpix[vi0])
            ],
        for(sp=segtablemax[idxmax]) // max contour
            if(len(sp)>0) [
                for(p=sp)
                    let(
                        edge = _MTEdgeVertexIndices[p],
                        vi0 = edge[0],
                        vi1 = edge[1],
                        denom = f[vi1] - f[vi0],
                        u = abs(denom)<0.00001 ? 0.5 : (isovalmax-f[vi0]) / denom
                      ) vpix[vi0] + u*(vpix[vi1]-vpix[vi0])
            ],
        if(len(bbsides)>0) for(b = bbsides)
            let(
                edge = _MTEdgeVertexIndices[b],
                vi0 = edge[0],
                vi1 = edge[1],
                rev = f[vi0]<f[vi1],
                f0 = f[vi0],
                f1 = f[vi1],
                p0 = vpix[vi0],
                p1 = vpix[vi1],
                denom = f1 - f0,
                umin = abs(denom)<0.00001 ? 0.5 : max(-1e9, min(1e9, isovalmin-f0)) / denom,
                umax = abs(denom)<0.00001 ? 0.5 : max(-1e9, min(1e9, isovalmax-f0)) / denom,
                midptmin = p0 + umin*(p1-p0),
                midptmax = p0 + umax*(p1-p0)
            ) 
            if(f0<=isovalmin && isovalmin<=f1 && f1<=isovalmax) [midptmin, p1]
            else if(f0>=isovalmax && isovalmax>=f1 && f1>=isovalmin) [midptmax, p1]
            else if(f1>=isovalmax && isovalmax>=f0 && f0>=isovalmin) [p0, midptmax]
            else if(f1<=isovalmin && isovalmin<=f0 && f0<=isovalmax) [p0, midptmin]
            else if(f0<isovalmin && f1>isovalmax) [midptmin, midptmax]
            else if(f0>isovalmax && f1<isovalmin) [midptmax, midptmin]
            else if((f0<f1 && isovalmin<=f0 && isovalmax>=f1) || (f1<f0 && isovalmin<=f1 && isovalmax>=f0))
                [p0, p1]
    ]
];




/// ---------- 3D metaball stuff starts here ----------

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
    neg * coef / (max(0,inside*dist+maxdist));

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
    neg * (coef / (max(0,inside*dist+maxdist)))^exp;

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
         d=max(0,inside*dist+maxdist)
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
         d=max(0,inside*dist+maxdist)
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
        dum2 = assert(is_finite(or) && or>0, "\ninvalid radius or diameter."),
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


/// metaball connector cylinder - calls mb_capsule_* functions after transform

function mb_connector(p1, p2, r, cutoff=INF, influence=1, negative=false, hide_debug=false, d) =
    assert(is_num(cutoff) && cutoff>0, "\ncutoff must be a positive number.")
    assert(is_finite(influence) && influence>0, "\ninfluence must be a positive number.")
    let(
        dum1 = assert(is_vector(p1,3), "\nConnector start point p1 must be a 3D coordinate."),
        dum2 = assert(is_vector(p2,3), "\nConnector end point p2 must be a 3D coordinate."),
        dum3 = assert(p1 != p2, "\nStart and end points p1 and p2 cannot be the same."),
        r = get_radius(r=r,d=d),
        dum4 = assert(is_finite(r) && r>0, "\ninvalid radius or diameter."),
        neg = negative ? -1 : 1,
        dc = p2-p1, // center-to-center distance
        h = norm(dc)/2, // center-to-center length (cylinder height)
        transform = submatrix(down(h)*rot(from=dc,to=UP)*move(-p1), [0:2], [0:3]),
        vnf=[neg, move(p1, rot(from=UP,to=dc,p=hide_debug ? debug_tetra(0.02) : up(h, cyl(2*(r+h),r,rounding=0.999*r,$fn=20))))]
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

// Section: Metaballs
//   ![Metaball animation](https://raw.githubusercontent.com/BelfrySCAD/BOSL2/master/images/metaball_demo.gif)
//   .
//   [Metaballs](https://en.wikipedia.org/wiki/Metaballs), also known as "blobby objects",
//   can produce smoothly varying blobs and organic forms. You create metaballs by placing metaball
//   objects at different locations. These objects have a basic size and shape when placed in
//   isolation, but if another metaball object is nearby, the two objects interact, growing larger
//   and melding together. The closer the objects are, the more they blend and meld.
//   .
//   The `metaballs()` module and function produce scenes of 3D metaballs. The `metaballs2d()` module and
//   function produces scenes of 2D metaballs. The metaball specification method, tranformations, bounding box,
//   and other parameters are used the say way in 3D and 2D, but in 2D, pixels replace voxels. This
//   introductory section describes features common to both 3D and 2D cases.
//   .
//   <a name="metaball-parameters"></a>
//   ***Parameters common to 3D and 2D metaballs***
//   .
//   **Parameter `spec`:** The simplest metaball specification is a 1D list of alternating transformation matrices and
//   metaball functions: `[trans0, func0, trans1, func1, ... ]`, passed as the `spec` parameter.
//   Each transformation matrix you supply can be constructed using the usual transformation commands
//   such as {{up()}}, {{right()}}, {{back()}}, {{move()}}, {{scale()}}, {{rot()}} and so on. You can
//   multiply the transformations together, similar to how the transformations can be applied
//   to regular objects in OpenSCAD. For example, to transform an object in regular OpenSCAD you
//   might write `up(5) zrot(45) scale(4)`. You would provide that transformation
//   as the transformation matrix `up(5) * zrot(45) * scale(4)`. You can use
//   scaling to produce an ellipsoid from a sphere, and you can even use {{skew()}} if desired. 
//   When no transformation is needed, give `IDENT` as the transformation.
//   .
//   The `spec` parameter is flexible. It doesn't have to be just a list of alternating transformation
//   matrices and metaball functions. It can also be a list of alternating transforms and *other specs*,
//   as `[trans0, spec0, trans1, spec1, ...]`, in which `spec0`, `spec1`, etc. can be one of:
//   * A built-in metaball function name as described below, such as `mb_sphere(r=10)`.
//   * A function literal accepting a vector representing a point in space relative to the metaball's center.
//   * An array containing a function literal and a debug VNF, as `[custom_func, [sign, vnf]]`, where `sign` is the sign of the metaball and `vnf` is the VNF to show in the debug view when `debug=true` is set.
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
//   **Parameters `bounding_box` and grid units:** The metaballs are evaluated over a bounding box. The `bounding_box` parameter can be specified by
//   its minimum and maximum corners: `[[xmin,ymin,zmin],[xmax,ymax,zmax]]` in 3D, or
//   `[[xmin,ymin],[xmax,ymax]]` in 2D. The bounding box can also be specified as a scalar size of a cube (in 3D)
//   or square (in 2D) centered on the origin. The contributions from **all**  metaballs, even those outside
//   the box, are evaluated over the bounding box.
//   .
//   This bounding box is divided into grid units, specified as `voxel_size` in 3D or `pixel_size` in 2D,
//   which can be a scalar or a vector size.
//   Alternately, you can set the grid count (`voxel_count` or `pixel_count`) to fit approximately the
//   specified number of grid units into the bounding box.
//   .
//   Objects in the scene having any dimension smaller than the grid spacing may not
//   be displayed, so if objects seem to be missing, try making the grid units smaller or the grid count
//   larger. By default, if the voxel size or pixel size doesn't exactly divide your specified bounding box,
//   then the bounding box is enlarged to contain whole grid units, and centered on your requested box.
//   Alternatively, you may set `exact_bounds=true`, which causes the grid units to adjust to fit instead,
//   resulting in non-square grid units. Either way, if the bounding box clips a metaball and `closed=true`
//   (the default), the object is closed at the intersection. Setting `closed=false` causes the object to end
//   at the bounding box. In 3D, this results in a non-manifold shape with holes, exposing the inside of the
//   object. In 2D, this results in an open-ended contour path with higher values on the right with respect to
//   the path direction. 
//   .
//   For metaballs with flat surfaces or sides, avoid letting any side of the bounding box coincide with one
//   of these flat surfaces or sides, otherwise unpredictable triangulation around the edge may result.
//   .
//   **Parameter `isovalue`:** The `isovalue` parameter applies globally to **all** your metaballs and changes
//   the appearance of your entire metaball object, possibly dramatically. It defaults to 1 and you don't usually
//   need to change it. If you increase the isovalue, then all the objects in your model shrink, causing some melded
//   objects to separate. If you decrease it, each metaball grows and melds more with others. As with `isosurface()`,
//   a range may be specified for isovalue, which can result in hollow metaballs, although this isn't particularly
//   useful except possibly in 2D.
//   .
//   ***Metaballs debug view***
//   .
//   The module form of `metaballs()` and `metaballs2d()` can take a `debug` argument. When you set
//   `debug=true`, the scene is rendered as a transparency (in 3D) or outline (in 2D) with the primitive
//   metaball shapes shown inside, colored blue for positive, orange for negative, or gray for custom
//   metaballs with no sign specified. These shapes are displayed at the sizes specified by the dimensional
//   parameters in the corresponding metaball functions, regardless of isovalue. Setting `hide_debug=true` in
//   individual metaball functions hides primitive shape from the debug view. Regardless the `debug` setting,
//   child modules can access the metaball geometry via `$metaball_vnf` in 3D, or `$metaball_pathlist` in 2D.
//   .
//   User-defined metaball functions are displayed by default as gray tetrahedrons (3D) or triangles (2D)
//   with a corner radius of 5, unless you also designate a shape for your custom function, as described
//   below in the documentation for {{metaballs()}} and {{metaballs2d()}}.
//   .
//   ***Metaballs run time***
//   .
//   The size of the grid units (voxels or pixels) and size of the bounding box affects the run time, which can
//   be long, especially in 3D.
//   Smaller grid units produce a finer, smoother result at the expense of execution time. Larger grid units
//   shorten execution time.
//   The affect on run time is most evident for 3D metaballs, less so for 2D metaballs.
//   .
//   For example, in 3D, a voxel size of 1 with a bounding box volume of 200×200×200 may be slow because it
//   requires the calculation and storage of eight million function values, and more processing and memory to
//   generate the triangulated mesh.  On the other hand, a voxel size of 5 over a 100×100×100 bounding box
//   requires only 8,000 function values and a modest computation time. A good rule is to keep the number
//   of voxels below 10,000 for preview, and adjust the voxel size smaller for final rendering. If you don't
//   specify `voxel_size` or `voxel_count`, then a default count of 10,000 voxels is used,
//   which should be reasonable for initial preview.
//   .
//   In 2D, If you don't specify `pixel_size` or `pixel_count`, then a default count of 1024 pixels is used,
//   which is reasonable for initial preview. You may find, however, that 2D metaballs are reasonably fast
//   even at finer resolution.
//   .
//   Because a bounding box that is too large wastes time
//   computing function values that are not needed, you can also set the parameter `show_stats=true` to get
//   the actual bounds of the voxels intersected by the surface. With this information, you may be able to
//   decrease run time, or keep the same run time but increase the resolution. 
//   .
//   ***Metaball functions and user defined functions***
//   .
//   You can construct complicated metaball models using only the built-in metaball functions described in
//   the documentation below for {{metaballs()}} and {{metaballs2d()}}.
//   However, you can create your own custom metaballs if desired.
//   .
//   When multiple metaballs are in a model, their functions are summed and compared to the isovalue to
//   determine the final shape of the metaball object.
//   Each metaball is defined as a function of a vector that gives the value of the metaball function
//   for that point in space. As is common in metaball implementations, we define the built-in metaballs
//   using an inverse relationship where the metaball functions fall off as $1/d$, where $d$ is distance
//   measured from the center or core of the metaball. The 3D spherical metaball and 2D circular metaball
//   therefore have a simple basic definition as $f(v) = 1/\text{norm}(v)$. If we choose an isovalue $c$,
//   then the set of points $v$ such that $f(v) >= c$ defines a bounded set; for example, a sphere with radius
//   depending on the isovalue $c$. The default isovalue is $c=1$. Increasing the isovalue shrinks the object,
//   and decreasing the isovalue grows the object.
//   .
//   To adjust interaction strength, the influence parameter applies an exponent, so if `influence=a`
//   then the decay becomes $1/d^{1/a}$. This means, for example, that if you set influence to
//   0.5 you get a $1/d^2$ falloff. Changing this exponent changes how the balls interact.
//   .
//   You can pass a custom function as a [function literal](https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/User-Defined_Functions_and_Modules#Function_literals)
//   that takes a vector as its first argument and returns a single numerical value.
//   Generally, the function should return a scalar value that drops below the isovalue somewhere within your
//   bounding box. If you want your custom metaball function to behave similar to to the built-in functions,
//   the return value should fall off with distance as $1/d$. See `metaballs()` Examples 20, 21, and 22 for
//   demonstrations of creating custom metaball functions. Example 22 also shows how to make a complete custom
//   metaball function that handles the `influence` and `cutoff` parameters.
//   .
//   By default, when `debug=true`, a custom 3D metaball function displays a gray tetrahedron with corner
//   radius 5, and a custom 2D metaball function displays a gray triangle with corner radius 5.
//   To specify a custom VNF for a custom function literal, enclose it in square brackets to make a  list with
//   the function literal as the first element, and another list as the second element, for example:
//   .
//   `[ function (point) custom_func(point, arg1,...), [sign, vnf] ]`
//   .
//   where `sign` is the sign of the metaball and `vnf` is the VNF to show in the debug view when `debug=true`.
//   For 2D metaballs, you would specify a polygon path instead of a VNF.
//   The sign determines the color of the debug object: `1` is blue, `-1` is orange, and `0` is gray.
//   See `metaballs()` Example 31 below for a demonstration of setting a VNF for a custom function.



// Function&Module: metaballs()
// Synopsis: Creates a group of 3D metaballs (smoothly connected blobs).
// SynTags: Geom,VNF
// Topics: Metaballs, Isosurfaces, VNF Generators
// See Also: isosurface()
// Usage: As a module
//   metaballs(spec, bounding_box, voxel_size, [isovalue=], [closed=], [exact_bounds=], [convexity=], [show_stats=], [show_box=], [debug=] ...) [ATTACHMENTS];
// Usage: As a function
//   vnf = metaballs(spec, bounding_box, voxel_size, [isovalue=], [closed=], [exact_bounds=], [convexity=], [show_stats=]);
// Description:
//   Computes a [VNF structure](vnf.scad) of a 3D metaball scene within a specified bounding box.
//   .
//   See [metaball parameters](#metaball-parameters) for details on the primary parameters common to
//   `metaballs()` and `metaballs2d()`. The `spec` parameter is described in more detail there. The `spec`
//   parameter is a 1D list of alternating transforms and metaball functions; for example, the array
//   `spec= [ left(9), mb_sphere(5), right(9), mb_sphere(5) ]` defines a scene with two spheres of radius
//   5 shifted 9 units to the left and right of the origin. The `spec` parameter completely defines the
//   metaballs in your scene, including their position, orientation, and scaling, as well as different shapes.
//   .
//   You can create metaballs in a variety of standard shapes using the predefined functions
//   listed below. If you wish, you can also create custom metaball shapes using your own functions
//   (see Examples 20 and 21). For all of the built-in metaballs, three parameters are available to control
//   the interaction of the metaballs with each other: `cutoff`, `influence`, and `negative`. These parameters
//   apply to the individual metaball functions specified in your `spec` array; they are **not** parameters
//   of `metaballs()`.
//   .
//   The `cutoff` parameter specifies the distance beyond which the metaball has no interaction
//   with other balls. When you apply `cutoff`, a smooth suppression factor begins
//   decreasing the interaction strength at half the cutoff distance and reduces the interaction to
//   zero at the cutoff. Note that the smooth decrease may cause the interaction to become negligible
//   closer than the actual cutoff distance, depending on the voxel size and `influence` of the
//   ball. Also, depending on the value of `influence`, a cutoff that ends in the middle of
//   another ball can result in strange shapes, as shown in Example 17, with the metaball
//   interacting on one side of the boundary and not interacting on the other side. If you scale
//   a ball, the cutoff value is also scaled.
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
//   * `mb_sphere(r|d=)` &mdash; spherical metaball, with radius `r` or diameter `d`.  You can create an ellipsoid using `scale()` as the last transformation entry of the metaball `spec` array. 
//   * `mb_cuboid(size, [squareness=])` &mdash; cuboid metaball with rounded edges and corners. The corner sharpness is controlled by the `squareness` parameter ranging from 0 (spherical) to 1 (cubical), and defaults to 0.5. The `size` parameter specifies the dimensions of the cuboid that circumscribes the rounded shape, which is tangent to the center of each cube face. The `size` parameter may be a scalar or a vector, as in {{cuboid()}}. Except when `squareness=1`, the faces are always a little bit curved.
//   * `mb_cyl(h|l|height|length, [r|d=], [r1=|d1=], [r2=|d2=], [rounding=])` &mdash; vertical cylinder or cone metaball with the same dimensional arguments as {{cyl()}}. At least one of the radius or diameter arguments is required. The `rounding` argument defaults to 0 (sharp edge) if not specified. Only one rounding value is allowed: the rounding is the same at both ends. For a fully rounded cylindrical shape, consider using `mb_disk()` or `mb_capsule()`, which are less flexible but have faster execution times.
//   * `mb_disk(h|l|height|length, r|d=)` &mdash; flat disk with rounded edge, using the same dimensional arguments as {{cyl()}}. The diameter specifies the total diameter of the shape including the rounded sides, and must be greater than its height.
//   * `mb_capsule(h|l|height|length, [r|d=]` &mdash; vertical cylinder with rounded caps, using the same dimensional arguments as {{cyl()}}. The object is a convex hull of two spheres. The height or length specifies the distance between the ends of the hemispherical caps.
//   * `mb_connector(p1, p2, [r|d=])` &mdash; a connecting rod of radius `r` or diameter `d` with hemispherical caps (like `mb_capsule()`), but specified to connect point `p1` to point `p2` (which must be different 3D coordinates). As with `mb_capsule()`, the object is a convex hull of two spheres. The points `p1` and `p2` are at the centers of the two round caps. The connectors themselves are still influenced by other metaballs, but it may be undesirable to have them influence others, or each other. If two connectors are connected, the joint may appear swollen unless `influence` or `cutoff` is reduced. Reducing `cutoff` is preferable if feasible, because reducing `influence` can produce interpolation artifacts.
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
//   isovalue = A scalar value specifying the isosurface value (threshold value) of the metaballs. At the default value of 1.0, the internal metaball functions are designd so the size arguments correspond to the size parameter (such as radius) of the metaball, when rendered in isolation with no other metaballs. You can also specify an isovalue range such as `[1,1.1]`, which creates hollow metaballs, where the hollow is evident when clipped by the bounding box. A scalar isovalue is equivalent to the range `[isovalue,INF]`. Default: 1.0
//   closed = When true, close the surface if it intersects the bounding box by adding a closing face. When false, do not add a closing face, possibly producing non-manfold metaballs with holes where the bounding box intersects them.  Default: true
//   exact_bounds = When true, shrinks voxels as needed to fit whole voxels inside the requested bounding box. When false, enlarges `bounding_box` as needed to fit whole voxels of `voxel_size`, and centers the new bounding box over the requested box. Default: false
//   show_stats = If true, display statistics about the metaball isosurface in the console window. Besides the number of voxels that the surface passes through, and the number of triangles making up the surface, this is useful for getting information about a possibly smaller bounding box to improve speed for subsequent renders. Enabling this parameter has a small speed penalty. Default: false
//   convexity = (Module only) Maximum number of times a line could intersect a wall of the shape. Affects preview only. Default: 6
//   show_box = (Module only) Display the requested bounding box as transparent. This box may appear slightly different than specified if the actual bounding box had to be expanded to accommodate whole voxels. Default: false
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
//   `$metaball_vnf` is set to the VNF of the metaball scene.
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
// Example(3D,Med,NoAxes,VPD=228,VPT=[1,-5,35]): A model of a bunny, assembled from separate body components made with metaballs, with each component rendered at a different voxel size, and then combined together along with eyes and teeth. In this way, smaller bounding boxes can be defined for each component, which speeds up rendering. A bit more time is saved by saving the repeated components (ear, front leg, hind leg) in VNF structures, to render copies with {{vnf_polyhedron()}}.
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
        let(
            bbox0 = is_num(bounding_box)
            ? let(hb=0.5*bounding_box) [[-hb,-hb,-hb],[hb,hb,hb]]
            : bounding_box,
            autovoxsize = is_def(voxel_size) ? voxel_size : _getautovoxsize(bbox0, default(voxel_count,22^3)),
            voxsize = _getvoxsize(autovoxsize, bbox0, exact_bounds),
            bbox = _getbbox(voxsize, bounding_box, exact_bounds, undef)
        ) %translate(bbox[0]) cube(bbox[1]-bbox[0]);
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
        bbcheck = assert(all_positive(newbbox[1]-newbbox[0]), "\nbounding_box must be a vector range [[xmin,ymin,zmin],[xmax,ymax,zmax]]."),

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
function _mb_unwind_list(list, parent_trans=[IDENT], depth=0, twoD=false) =
    let(
        dum1 = assert(is_list(list), "\nDid not find valid list of metaballs."),
        n=len(list),
        dum2 = assert(n%2==0, "\nList of metaballs must have an even number of elements with alternating transforms and functions/lists."),
        dfltshape = twoD ? circle(5,$fn=3) : debug_tetra(5)
    ) [
        for(i=[0:2:n-1])
            let(
                dum3 = assert(is_matrix(list[i],4,4), str("\nInvalid 4×4 transformation matrix found at position ",i,", depth ",depth,": ", list[i])),
                dum4 = assert(!twoD || (twoD && is_2d_transform(list[i])), str("\nFound 3D transform in 2D metaball spec at position ",i," depth ",depth)),
                trans = parent_trans[0] * list[i],
                j=i+1
            )   if (is_function(list[j])) // for custom function without brackets...
                    each [trans, [list[j], [0, dfltshape]]] // ...add brackets and default vnf
                else if (is_function(list[j][0]) &&  // for bracketed function with undef or empty VNF...
                   (is_undef(list[j][1]) || len(list[j][1])==0))
                    each [trans, [list[j][0], [0, dfltshape]]] // ...add brackets and default vnf
                else if (is_function(list[j][0]) &&  // for bracketed function with only empty VNF...
                   (len(list[j][1])>0 && is_num(list[j][1][0]) && len(list[j][1][1])==0))
                    each [trans, [list[j][0], [list[j][1][0], dfltshape]]] // ...do a similar thing
                else if(is_function(list[j][0]))
                    each [trans, list[j]]
                else if (is_list(list[j][0])) // likely a nested spec if not a function
                    each _mb_unwind_list(list[j], [trans], depth+1, twoD)
                else                 
                    assert(false, str("\nExpected function literal or list at position ",j,", depth ",depth,"."))
    ];


/// ---------- 2D metaball stuff starts here ----------

/// metaball circle

function _mb_circle_full(point, r, cutoff, ex, neg) = let(dist=norm(point))
    neg * mb_cutoff(dist, cutoff) * (r/dist)^ex;

function mb_circle(r, cutoff=INF, influence=1, negative=false, hide_debug=false, d) =
    assert(is_num(cutoff) && cutoff>0, "\ncutoff must be a positive number.")
    assert(is_finite(influence) && influence>0, "\ninfluence must be a positive number.")
    let(
        r = get_radius(r=r,d=d),
        dummy=assert(is_finite(r) && r>0, "\ninvalid radius or diameter."),
        neg = negative ? -1 : 1,
        poly = [neg, hide_debug ? circle(r=0.02, $fn=3) : circle(r=r, $fn=20)]
    )
    [function (point) _mb_circle_full(point,r,cutoff,1/influence,neg), poly];


/// metaball rounded rectangle / squircle

function _mb_squircle_full(point, inv_size, xp, ex, cutoff, neg) = let(
    point = inv_size * point,
    dist = xp >= 1100 ? max(v_abs(point))
                      :(abs(point.x)^xp + abs(point.y)^xp) ^ (1/xp)
) neg * mb_cutoff(dist, cutoff) / dist^ex;

function mb_rect(size, squareness=0.5, cutoff=INF, influence=1, negative=false, hide_debug=false) =
   assert(is_num(cutoff) && cutoff>0, "\ncutoff must be a positive number.")
   assert(is_finite(influence) && influence>0, "\ninfluence must be a positive number.")
   assert(squareness>=0 && squareness<=1, "\nsquareness must be inside the range [0,1].")
   assert((is_finite(size) && size>0) || (is_vector(size) && all_positive(size)), "\nsize must be a positive number or a 2-vector of positive values.")
   let(
       xp = _squircle_se_exponent(squareness),
       neg = negative ? -1 : 1,
       inv_size = is_num(size) ? 2/size
                : [[2/size.x,0,0],[0,2/size.y,0]],
        poly=[neg, hide_debug ? square(0.02,true) : squircle(size,squareness, $fn=20)]
   )
   [function (point) _mb_squircle_full(point, inv_size, xp, 1/influence, cutoff, neg), poly];


/// metaball rounded trapezoid

function _trapsurf_full(point, path, coef, cutoff, exp, neg, maxdist) =
    let(
        pt = [abs(point.x), point.y],
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
         d=max(0,inside*dist+maxdist)
    )
    neg * mb_cutoff(d, cutoff) * (coef/d)^exp;

function mb_trapezoid(h,w1,w2,ang=undef,rounding=0,w, cutoff=INF, influence=1, negative=false, hide_debug=false) =
    let(
        wbot = first_defined([w,w1]),
        wtop = first_defined([w,w2]),
        dims = _trapezoid_dims(h,wbot,wtop,0,[ang,ang]),
        h = dims[0],
        w1 = dims[1],
        w2 = dims[2]
    )
    assert(all_positive([influence]), "influence must be a positive number")
    assert(is_finite(rounding) && rounding>=0, "rounding must be a nonnegative number")
    assert(is_finite(w1) && w1>0, "w/w1/width1 must be a positive number")
    assert(is_finite(w2) && w2>0, "w/w2/width2 must be a positive number")
    assert(is_num(cutoff) && cutoff>0, "cutoff must be a positive number")
    let(r1=w1/2, r2=w2/2,
        vang = atan2(r1-r2,h),
        facelen = adj_ang_to_hyp(h, abs(vang)),
        roundlen1 = rounding/tan(45-vang/2),
        roundlen2 = rounding/tan(45+vang/2),
        sides = [[0,h/2], [r2,h/2], [r1,-h/2], [0,-h/2]],
        neg = negative ? -1 : 1
    )
    assert(roundlen1 <= r1, "size of rounding is larger than half the w1 width of the trapezoid")
    assert(roundlen2 <= r2, "size of rounding is larger than half the w2 width of the trapezoid")
    assert(roundlen1+roundlen2 < facelen, "Roundings don't fit on the edge length of the trapezoid")
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
        poly = [neg, hide_debug ? square(0.02,true) : trapezoid(h,w1,w2,rounding=rounding,$fn=20)]
    )
    [function (point) _trapsurf_full(point, shifted, maxdist+rounding, cutoff, 1/influence, neg, maxdist), poly];


/// metaball stadium

function _mb_stadium_full(dv, hl, r, cutoff, ex, neg) = let(
    dist = dv.y<-hl ? norm(dv-[0,-hl])
      : dv.y<hl ? abs(dv.x) : norm(dv-[0,hl])
) neg * mb_cutoff(dist, cutoff) * (r/dist)^ex;

function _mb_stadium_sideways_full(dv, hl, r, cutoff, ex, neg) = let(
    dist = dv.x<-hl ? norm(dv-[-hl,0])
      : dv.x<hl ? abs(dv.y) : norm(dv-[hl,0])
) neg * mb_cutoff(dist, cutoff) * (r/dist)^ex;

function mb_stadium(size, cutoff=INF, influence=1, negative=false, hide_debug=false) =
    assert(is_num(cutoff) && cutoff>0, "\ncutoff must be a positive number.")
    assert(is_finite(influence) && influence>0, "\ninfluence must be a positive number.")
    assert((is_finite(size) && size>0) || (is_vector(size) && all_positive(size)), "\nsize must be a positive number or a 2-vector of positive values.")
    let(
        siz = is_num(size) ? [size,size] : [size[0],size[1]],
        shape = siz[1]/siz[0] - 1,
        length = shape>=0 ? siz[1] : siz[0],
        r = shape>=0 ? siz[0]/2 : siz[1]/2,
        sl = length-2*r, // straight side length
        //dum3 = assert(sl>=0, "\nTotal length must accommodate rounded ends of rectangle."),
        neg = negative ? -1 : 1,
        poly = abs(shape)<=EPSILON ? [neg, hide_debug ? circle(r=0.02, $fn=3) : circle(r=r, $fn=20)]
        : shape>0 ? [neg, hide_debug ? square(0.02,center=true) : rect([2*r,length], rounding=0.999*r, $fn=20)]
        : [neg, hide_debug ? square(0.02,center=true) : rect([length,2*r], rounding=0.999*r, $fn=20)]
   ) abs(shape)<EPSILON ?
    [function (dv) _mb_circle_full(dv, r, cutoff, 1/influence, neg), poly]
    : shape>0 ? [function (dv) _mb_stadium_full(dv, sl/2, r, cutoff, 1/influence, neg), poly]
    : [function (dv) _mb_stadium_sideways_full(dv, sl/2, r, cutoff, 1/influence, neg), poly];


/// metaball 2D connector - calls mb_stadium after transform

function mb_connector2d(p1, p2, r, cutoff=INF, influence=1, negative=false, hide_debug=false, d) =
    assert(is_num(cutoff) && cutoff>0, "\ncutoff must be a positive number.")
    assert(is_finite(influence) && influence>0, "\ninfluence must be a positive number.")
    let(
        //dum1 = assert(is_vector(p1,2), "\n2D connector start point p1 must be a 3D coordinate.")
        //    assert(is_vector(p2,3), "\n2D connector end point p2 must be a 3D coordinate.")
        dum1 = assert(p1 != p2, "\nStart and end points p1 and p2 cannot be the same."),
        r = get_radius(r=r,d=d),
        dum2 = assert(is_finite(r) && r>0, "\ninvalid radius or diameter."),
        neg = negative ? -1 : 1,
        dc = p2-p1, // center-to-center distance
        h = norm(dc)/2, // center-to-center length (cylinder height)
        //transform = submatrix(down(h)*rot(from=dc,to=UP)*move(-p1), [0:2], [0:3]),
        transform = submatrix(back(h)*rot(from=dc,to=FWD)*move(-p1), [0:2], [0:3]),
        poly=[neg, move(p1, rot(from=BACK,to=dc,p=hide_debug ? square(0.2,true) : back(h, rect([2*r,2*(r+h)],rounding=0.999*r,$fn=20))))]
   )
   [function (dv)
        let(newdv = transform * [each dv,1])
            _mb_stadium_full(newdv, h, r, cutoff, 1/influence, neg), poly];

 
/// metaball ring or annulus

function _mb_ring_full(point, rmaj, rmin, cutoff, ex, neg) =
    let(dist = abs(norm([point.x,point.y])-rmaj))
        neg * mb_cutoff(dist, cutoff) * (rmin/dist)^ex;

function mb_ring(r1,r2, cutoff=INF, influence=1, negative=false, hide_debug=false, d1,d2) =
   assert(is_num(cutoff) && cutoff>0, "\ncutoff must be a positive number.")
   assert(is_finite(influence) && influence>0, "\ninfluence must be a positive number.")
   let(
        _r1 = get_radius(r=r1, d=d1, dflt=undef),
        _r2 = get_radius(r=r2, d=d2, dflt=undef),
        dum = assert(is_finite(_r1) && is_finite(_r2), "\nBad ring size parameter."),
        r_maj = (_r1 + _r2) / 2,
        r_min = abs(_r1 - _r2) / 2,
        neg = negative ? -1 : 1,
        poly = [neg, hide_debug ? square(0.02,true) : ring(r1=_r1,r2=_r2,n=20)]
   )
   [function(point) _mb_ring_full(point, r_maj, r_min, cutoff, 1/influence, neg), poly];



// Function&Module: metaballs2d()
// Synopsis: Creates a group of 2D metaballs (smoothly connected blobs).
// SynTags: Geom,Region
// Topics: Metaballs, Contours, Path Generators (2D), Regions
// See Also: contour(), metaballs()
// Usage: As a module
//   metaballs2d(spec, bounding_box, pixel_size, [isovalue=], [use_centers=], [smoothing=], [exact_bounds=], [show_stats=], [show_box=], [debug=] ...) [ATTACHMENTS];
// Usage: As a function
//   region = metaballs2d(spec, bounding_box, pixel_size, [isovalue=], [closed=], [use_centers=], [smoothing=], [exact_bounds=], [show_stats=]);
// Description:
//   ![Metaball animation](https://raw.githubusercontent.com/BelfrySCAD/BOSL2/master/images/metaball_demo2d.gif)
//   .
//   2D metaball shapes can be useful to create interesting polygons for extrusion. When invoked as a
//   module, a 2D metaball scene is displayed. When called as a function, a [region](regions.scad) or list of
//   [paths](paths.scad) is returned.
//   .
//   For a full explanation of metaballs, see [introduction](#section-metaballs) above. The
//   specification method, tranformations, bounding box, and other parameters are the same as in 3D,
//   but in 2D, pixels replace voxels.
//   .
//   See [metaball parameters](#metaball-parameters) for details on the primary parameters common to
//   `metaballs()` and `metaballs2d()`. The `spec` parameter is described in more detail there. The `spec`
//   parameter is a 1D list of alternating transforms and metaball functions; for example, the array
//   `spec= [ left(9), mb_circle(5), right(9), mb_circle(5) ]` defines a scene with two circles of radius
//   5 shifted 9 units to the left and right of the origin. The `spec` parameter completely defines the
//   metaballs in your scene, including their position, orientation, and scaling, as well as different shapes.
//   .
//   You can create 2D metaballs in a variety of standard shapes using the predefined functions
//   listed below. If you wish, you can also create custom metaball shapes using your own functions.
//   For all of the built-in 2D metaballs, three parameters are available to
//   control the interaction of the metaballs with each other: `cutoff`, `influence`, and `negative`.
//   .
//   The `cutoff` parameter specifies the distance beyond which the metaball has no interaction
//   with other balls. When you apply `cutoff`, a smooth suppression factor begins
//   decreasing the interaction strength at half the cutoff distance and reduces the interaction to
//   zero at the cutoff. Depending on the value of `influence`, a cutoff that ends in the middle of
//   another ball can result in strange shapes, as shown in Example 9, with the metaball
//   interacting on one side of the boundary and not interacting on the other side. If you scale
//   a ball, the cutoff value is also scaled.
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
//   model. Example 8 demonstrates this effect. To avoid these artifacts, keep `influence` above about
//   0.5 and consider using `cutoff` instead of using small influence.
//   .
//   The `negative` parameter, if set to `true`, creates a negative metaball, which can result in
//   hollows, dents, or reductions in size of other metaballs. 
//   Negative metaballs are never directly visible; only their effects are visible. The `influence`
//   argument may also behave in ways you don't expect with a negative metaball. See Examples 16 and 17.
//   .
//   ***Built-in 2D metaball functions***
//   .
//   Several metaballs are defined for you to use in your models. 
//   All of the built-in metaballs take positional and named parameters that specify the size of the
//   metaball (such as height or radius). The size arguments are the same as those for the regular objects
//   of the same type (e.g. a circle accepts both `r` for radius and the named parameter `d=` for
//   diameter). The size parameters always specify the size of the metaball **in isolation** with
//   `isovalue=1`. The metaballs can grow much bigger than their specified sizes when they interact
//   with each other. Changing `isovalue` also changes the sizes of metaballs. They grow bigger than their
//   specified sizes, even in isolation, if `isovalue < 1` and smaller than their specified sizes if
//   `isovalue > 1`.
//   .
//   The built-in 2D metaball functions are listed below. As usual, arguments without a trailing `=` can be used positionally; arguments with a trailing `=` must be used as named arguments.
//   .
//   * `mb_circle(r|d=)` &mdash; circular metaball, with radius `r` or diameter `d`.  You can create an ellipse using `scale()` as the last transformation entry of the metaball `spec` array. 
//   * `mb_rect(size, [squareness=])` &mdash; a square/circle hybrid known as a squircle, appearing as a square with rounded edges and corners. The corner sharpness is controlled by the `squareness` parameter ranging from 0 (circular) to 1 (square), and defaults to 0.5. The `size` parameter specifies the dimensions of the squircle that circumscribes the rounded shape, which is tangent to the center of each square side. The `size` parameter may be a scalar or a vector, as in {{squircle()}}. Except when `squareness=1`, the sides are always a little bit curved.
//   * `mb_trapezoid(h, w1|w=, w2|w=, [ang=], [rounding=])` &mdash; rounded trapezoid metaball with arguments similar to {{trapezoid()}}. Any three of the arguments `h` (height), `w1` (bottom width), `w2` (top width), or `ang` (bottom corner angle) may be specified, and `w` sets both `w1` and `w2` to the same size. The `rounding` argument defaults to 0 (sharp edge) if not specified. Only one rounding value is allowed: the rounding is the same at both ends. For a rounded rectangular shape, consider using `mb_rect()`, or `mb_stadium()`, which are less flexible but have faster execution time.
//   * `mb_stadium(size)` &mdash; rectangle with rounded caps on the narrow ends. The object is a convex hull of two circles. Set the `size` parameter to `[width,height]` to get an object that fits inside a rectangle of that size. Giving a scalar size produces a circle.
//   * `mb_connector2d(p1, p2, [r|d=])` &mdash; a stadium shape specified to connect point `p1` to point `p2` (which must be different 2D coordinates). As with `mb_stadium()`, the object is a convex hull of two circles. The points `p1` and `p2` are at the centers of the two round caps. The connectors themselves are still influenced by other metaballs, but it may be undesirable to have them influence others, or each other. If two connectors are connected, the joint may appear swollen unless `influence` or `cutoff` is reduced. Reducing `cutoff` is preferable if feasible, because reducing `influence` can produce interpolation artifacts.
//   * `mb_ring(r1|d1=, r2|d2=)` &mdash; 2D ring metaball using a subset of {{ring()}} parameters, with inner radius being the smaller of `r1` and `r2`, and outer radius being the larger of `r1` and `r2`. If `cutoff` is applied, it is measured from the circle midway between `r1` and `r2`.
//   .
//   In addition to the dimensional arguments described above, all of the built-in functions accept the
//   following named arguments:
//   * `cutoff` &mdash; positive value giving the distance beyond which the metaball does not interact with other balls.  Cutoff is measured from the object's center. Default: INF
//   * `influence` &mdash; a positive number specifying the strength of interaction this ball has with other balls.  Default: 1
//   * `negative` &mdash; when true, creates a negative metaball. Default: false
//   * `hide_debug` &mdash; when true, suppresses the display of the underlying metaball shape when `debug=true` is set in the `metaballs()` module. This is useful to hide shapes that may be overlapping others in the debug view. Default: false
//   .
//   ***Closed and unclosed paths***
//   .
//   The functional form of `metaballs2d()` supports a `closed` parameter. When `closed=true` (the default)
//   and a polygon is clipped by the bounding box, the bounding box edges are included in the polygon. The
//   resulting path list is a valid region with no duplicated vertices in any path. The module form of
//   `metaballs2d()` always closes the polygons.
//   .
//   When `closed=false`, paths that intersect the edge of the bounding box end at the bounding box. This
//   means that the list of paths may include a mixture of closed and open paths. Regardless of whether
//   any of the output paths are open, all closed paths have identical first and last points so that  closed and
//   open paths can be distinguished. You can use {{are_ends_equal()}} to determine if a path is closed. A path
//   list that includes open paths is not a region, because regions are lists of closed polygons. Duplicating the
//   ends of closed paths can cause problems for functions such as {{offset()}}, which would complain about
//   repeated points. You can pass a closed path to {{list_unwrap()}} to remove the extra endpoint.
// Arguments:
//   spec = Metaball specification in the form `[trans0, spec0, trans1, spec1, ...]`, with alternating transformation matrices and metaball specs, where `spec0`, `spec1`, etc. can be a metaball function or another metaball specification.
//   bounding_box = The volume in which to perform computations, expressed as a scalar size of a square centered on the origin, or a pair of 2D points `[[xmin,ymin], [xmax,ymax]]` specifying the minimum and maximum box corner coordinates. Unless you set `exact_bounds=true`, the bounding box size may be enlarged to fit whole pixels.
//   pixel_size = Size of the pixels used to sample the bounding box area, can be a scalar or 2-vector, or omitted if `pixel_count` is set. You may get a non-square pixels of a slightly different size than requested if `exact_bounds=true`.
//   ---
//   pixel_count = Approximate number of pixels in the bounding box. If `exact_bounds=true` then the pixels may not be squares. Use with `show_stats=true` to see the corresponding pixel size. Default: 1024 (if `pixel_size` not set)
//   isovalue = A scalar value specifying the isosurface value (threshold value) of the metaballs. At the default value of 1.0, the internal metaball functions are designd so the size arguments correspond to the size parameter (such as radius) of the metaball, when rendered in isolation with no other metaballs. You can also specify a range for isovalue, such as `[1,1.1]` in which case the metaball is displayed as a shell with the hollow inside corresponding to the higher isovalue. A scalar isovalue is equivalent to the vector `[isovalue,INF]`. Default: 1.0
//   closed = (Function only) When true, close the path if it intersects the bounding box by adding a closing side. When false, do not add a closing side. Default: true, and always true when called as a module.
//   use_centers = When true, uses the center value of each pixel as an additional data point to refine the contour path through the pixel. Default: false
//   smoothing = Number of times to apply a 2-point moving average to the contours. This can remove small zig-zag artifacts resulting from a contour that follows the profile of a triangulated 3D surface when `use_centers` is set. Default: 2 if `use_centers=true`, 0 otherwise.
//   exact_bounds = When true, shrinks pixels as needed to fit whole pixels inside the requested bounding box. When false, enlarges `bounding_box` as needed to fit whole pixels of `pixel_size`, and centers the new bounding box over the requested box. Default: false
//   show_stats = If true, display statistics about the metaball isosurface in the console window. Besides the number of pixels that the contour passes through, and the number of segments making up the contour, this is useful for getting information about a possibly smaller bounding box to improve speed for subsequent renders. Default: false
//   show_box = (Module only) Display the requested bounding box as a transparent rectangle. This box may appear slightly different than specified if the actual bounding box had to be expanded to accommodate whole pixels. Default: false
//   debug = (Module only) Display the underlying primitive metaball shapes using your specified dimensional arguments, overlaid by the metaball scene rendered as outlines. Positive metaballs appear blue, negative appears orange, and any custom function with no debug polygon defined appears as a gray triangle of radius 5.
//   cp = (Module only) Center point for determining intersection anchors or centering the shape. Determines the base of the anchor vector. Can be "centroid", "mean", "box" or a 3D point.  Default: "centroid"
//   anchor = (Module only) Translate so anchor point is at origin (0,0,0). See [anchor](attachments.scad#subsection-anchor).  Default: `"origin"`
//   spin = (Module only) Rotate this many degrees around the Z axis after anchor. See [spin](attachments.scad#subsection-spin).  Default: `0`
//   orient = (Module only) Vector to rotate top toward, after spin. See [orient](attachments.scad#subsection-orient).  Default: `UP`
//   atype = (Module only) Select "hull" or "intersect" anchor type.  Default: "hull"
// Anchor Types:
//   "hull" = Anchors to the virtual convex hull of the shape.
//   "intersect" = Anchors to the surface of the shape.
// Side Effects:
//   `$metaball_pathlist` is set to the region (array of contor paths) of the metaball scene.
// Example(2D,NoAxes): Two circles interacting.
//   spec = [
//       left(9), mb_circle(5),
//       right(9), mb_circle(5)
//   ];
//   metaballs2d(spec, pixel_size=1,
//       bounding_box=[[-16,-7], [16,7]]);
// Example(2D,NoAxes): Two rounded rectangles (squircles) interacting.
//   spec = [
//       move([-8,-6]), mb_rect(10),
//       move([8,6]), mb_rect(10)
//   ];
//   metaballs2d(spec, pixel_size=1,
//       bounding_box=[[-15,-13], [15,13]]);
// Example(2D,NoAxes): Two rounded trapezoids interacting.
//      spec = [
//          left(10), mb_trapezoid(15, w1=12, w2=8, rounding=2),
//          right(10), mb_trapezoid(15, w1=12, w2=8, rounding=2)
//      ];
//      metaballs2d(spec, pixel_size=1,
//          bounding_box=[[-17,-10], [17,10]]);
// Example(2D,NoAxes): Two stadiums interacting. The first stadium of size `[6,16]` has width less than height, which would normally be oriented vertically unless rotated 90° as done here. The second stadum of size `[16,6]` has width greater than height and is already oriented horizontally without rotation.
//   metaballs2d([
//       move([-8,4])*zrot(90), mb_stadium([6,16]),
//       move([8,-4]), mb_stadium([16,6])
//       ], [[-17,-8], [17,8]], 1);
// Example(2D,NoAxes): A circle with two connectors.
//   path = [[-20,0], [0,1], [-3,-10]];
//   spec = [
//       move(path[0]), mb_circle(6),
//       for(seg=pair(path)) each
//          [IDENT, mb_connector2d(seg[0],seg[1],
//           2, influence=0.5)]
//   ];
//   metaballs2d(spec, pixel_size=1,
//       bounding_box=[[-27,-13], [4,14]]);
// Example(2D,NoAxes): Interaction between two rings.
//    spec = [
//        move([-7,-3]), mb_ring(3,6),
//        move([7,3]),   mb_ring(3,7)
//    ];
//    pixel_size = 0.5;
//    boundingbox = [[-14,-11], [16,11]];
//    metaballs2d(spec, boundingbox, pixel_size);
// Example(3D,Med): Setting `influence` to less than 0.5 can cause interpolation artifacts in the contour. The only difference between these two circles is `influence`. Both have `cutoff` set to prevent them from affecting each other. The circle on the right has a low influence of 0.02, which translates to a falloff with distance $d$ proportional to $1/d^{50}$. That high exponent increases the *non-linear* nature of the function gradient at the contour isovalue, reducing the accuracy of the *linear* interpolation of where the the contour intersects each pixel, causing bumps to appear. It is usually better to use `cutoff` to limit the range of influence rather than reducing `influence` significantly below 1.
//   spec = [
//       left(10), mb_circle(8, cutoff=10, influence=1),
//       right(10), mb_circle(8, cutoff=10, influence=0.02)
//   ];
//   bbox = [[-18,-8], [18,8]];
//   metaballs2d(spec, bounding_box=bbox, pixel_size=0.4);
// Example(2D,NoAxes): A positive and negative metaball in close proximity, with the small negative metaball creating a dent in the large positive one. Small green cylinders indicate the center of each metaball. The negative metaball isn't visible because its field is negative; the contour encloses only field values greater than the isovalue of 1.
//   centers = [[-1,0], [1.25,0]];
//   spec = [
//       move(centers[0]), mb_circle(8),
//       move(centers[1]), mb_circle(3, negative=true)
//   ];
//   voxel_size = 0.25;
//   boundingbox = [[-7,-6], [3,6]];
//   metaballs2d(spec, boundingbox, voxel_size);
//   color("green") move_copies(centers) cylinder(h=1,d=1,$fn=16);
// Example(2D,VPD=105,VPT=[0,15,0]): When a positive and negative metaball interact, the negative metaball reduces the influence of the positive one, causing it to shrink, but not disappear because its contribution approaches infinity at its center. This example shows a large positive metaball near a small negative metaball at the origin. The negative ball has high influence, and a cutoff limiting its influence to 20 units. The negative metaball influences the positive one up to the cutoff, causing the positive metaball to appear smaller inside the cutoff range, and appear its normal size outside the cutoff range. The positive metaball has a small dimple at the origin (the center of the negative metaball) because it cannot overcome the infinite negative contribution of the negative metaball at the origin.
//   spec = [
//       back(10), mb_circle(20),
//       IDENT, mb_circle(2, influence=30,
//           cutoff=20, negative=true),
//   ];
//   pixel_size = 0.5;
//   boundingbox = [[-20,-1], [20,31]];
//   metaballs2d(spec, boundingbox, pixel_size);
// Example(2D,NoAxes,VPD=250,VPT=[0,8,0]): Profile of an airplane, constructed only from metaball circles with scaling. The bounding box is used to clip the wingtips and tail.
//   bounding_box = [[-55,-50],[35,50]];
//   spec = [
//       // fuselage
//       move([-18,0])*scale([27,4]), mb_circle(1),
//       // tail
//       move([30,0])*scale([3,15]),  mb_circle(1),
//       // wing
//       move([-15,0])*scale([6,45]), mb_circle(1)
//   ];
//   pixel_size = 1;
//   color("lightblue") zrot(-90)
//     metaballs2d(spec, bounding_box, pixel_size);
// Example(2D): This is the 2D version of the 3D Example 20 above, showing a custom metaball defined and passed as a function literal that takes a single [x,y] argument representing a coordinate relative to the metaball center, called `point` here, but can have any name. This distance vector from the origin is calculated internally and always passed to the function. Inside the function, it is converted to a scalar distance `dist`. The function literal expression sets all of your parameters. Only `point` is not set, and it becomes the single parameter to the function literal. The `spec` argument invokes your custom function as a function literal that passes `point` into it.
//   function threelobe2d(point) =
//      let(
//           ang=atan2(point.y, point.x),
//           dist=norm([point.x,point.y])*(1.3+cos(3*ang))
//      ) 3/dist;
//   metaballs2d(
//       spec = [
//           IDENT, function (point) threelobe2d(point),
//           IDENT, mb_circle(r=3)
//       ],
//       bounding_box = [[-14,-12],[8,12]],
//       pixel_size=0.5);
// Example(2D): Analogous to the 3D Example 21 above, here is a 2D function nearly identical to the previous example, introducing additional dimensional parameters into the function to control its size and number of lobes. If you expiriment with this using different argument values, you should increase the bounding box along with pixel size.
//   function multilobe2d(point, size, lobes) =
//      let(
//           ang=atan2(point.y, point.x),
//           dist = norm([point.x,point.y])
//               * (1.3+cos(lobes*ang))
//      ) size/dist;
//   metaballs2d(
//       spec = [
//           left(7),
//              function (point) multilobe2d(point,3,4),
//           right(7)*zrot(60),
//              function (point) multilobe2d(point,3,3)
//       ],
//       bounding_box = [[-16,-13],[18,13]],
//       pixel_size=0.4);
// Example(2D,Med,NoAxes: Demonstration of `debug=true` with a variety of metaball shapes. The metaballs themselves are shown as outlines, with the underlying primitive shape shown in blue (for positive metaballs) or orange (for negative metaballs).
//   spec = [
//       IDENT,          mb_ring(r1=6, r2=9),
//       move([15,0]),   mb_circle(3),
//       IDENT,          mb_connector2d([10,10],[15,15],1),
//       move([-12,12])*zrot(45),    mb_rect([3,5]),
//       move([-14,-14])*zrot(-45),  mb_trapezoid(10,w1=7,w2=2,rounding=0.99),
//       move([10,-10]), mb_circle(2, cutoff=10, negative=true)
//   ];
//   metaballs2d(spec, [[-20,-20],[20,17]], pixel_size=0.5, debug=true);

module metaballs2d(spec, bounding_box, pixel_size, pixel_count, isovalue=1, use_centers=false, smoothing=undef, exact_bounds=false, convexity=6, cp="centroid", anchor="origin", spin=0, atype="hull", show_stats=false, show_box=false, debug=false) {
    regionlist = metaballs2d(spec, bounding_box, pixel_size, pixel_count, isovalue, true, use_centers, smoothing, exact_bounds, show_stats, _debug=debug);
    $metaball_pathlist = debug ? regionlist[0] : regionlist; // for possible use with children
    if(debug) {
        // display debug polygons
        for(a=regionlist[1])
            if(len(a[1])>0)
                color(a[0]==0 ? "gray" : a[0]>0 ? "#3399FF" : "#FF9933")
                    region(a[1]);
            //else echo("WARNING: Empty metaball path found!");
        // display metaball as outline
        attachable(anchor, spin, two_d=true, region=regionlist[0], extent=atype=="hull", cp=cp) {
            wid = is_def(pixel_size) ? min(0.5, 0.5 * (is_num(pixel_size) ? pixel_size : 0.5*(pixel_size[0]+pixel_size[1]))) : 0.2;
            stroke(regionlist[0], width=wid, closed=true);
            children();
        }
    } else { // debug==false, just display the metaball polygons
        assert(len(regionlist)>0, "\nNo metaball polygons found! Check your isovalue.")
            attachable(anchor, spin, two_d=true, region=regionlist, extent=atype=="hull", cp=cp) {
                if(len(regionlist)>0)
                    region(regionlist, anchor=anchor, spin=spin, cp=cp, atype=atype);
                children();
            }
    }
    if(show_box)
        let(
            bbox0 = is_num(bounding_box)
            ? let(hb=0.5*bounding_box) [[-hb,-hb],[hb,hb]]
            : bounding_box,
            autopixsize = is_def(pixel_size) ? pixel_size : _getautopixsize(bbox0, default(pixel_count,32^2)),
            pixsize = _getpixsize(autopixsize, bbox0, exact_bounds),
            bbox = _getbbox2d(pixsize, bbox0, exact_bounds)
        ) %translate([bbox[0][0],bbox[0][1],-0.05]) linear_extrude(0.1) square(bbox[1]-bbox[0]);
}

function metaballs2d(spec, bounding_box, pixel_size, pixel_count, isovalue=1, closed=true, use_centers=false, smoothing=undef, exact_bounds=false, show_stats=false, _debug=false) =
    assert(all_defined([spec, bounding_box]), "\nThe parameters spec and bounding_box must both be defined.")
    assert(is_num(bounding_box) || len(bounding_box[0])==2, "\nBounding box must be 2D.")
    assert(num_defined([pixel_size, pixel_count])<=1, "\nOnly one of pixel_size or pixel_count can be defined.")
    assert(is_undef(pixel_size) || (is_finite(pixel_size) && pixel_size>0) || (is_vector(pixel_size) && all_positive(pixel_size)), "\npixel_size must be a positive number, a 2-vector of positive values, or not given.")
    assert(is_finite(isovalue) || (is_list(isovalue) && len(isovalue)==2 && is_num(isovalue[0]) && is_num(isovalue[1])), "\nIsovalue must be a number or a range; a number is the same as [number,INF].")
    assert(len(spec)%2==0, "\nThe spec parameter must be an even-length list of alternating transforms and functions")
    let(
        isoval = is_list(isovalue) ? isovalue : [isovalue,INF], 
        funclist = _mb_unwind_list(spec, twoD=true),
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

        // new pixel or bounding box centered around original, to fit whole pixels
        bbox0 = is_num(bounding_box)
            ? let(hb=0.5*bounding_box) [[-hb,-hb],[hb,hb]]
            : bounding_box,
       autopixsize = is_def(pixel_size) ? pixel_size : _getautopixsize(bbox0, default(pixel_count,32^2)),
        pixsize = _getpixsize(autopixsize, bbox0, exact_bounds),
        newbbox = _getbbox2d(pixsize, bbox0, exact_bounds),
        bbcheck = assert(all_positive(newbbox[1]-newbbox[0]), "\nbounding_box must be a vector range [[xmin,ymin],[xmax,ymax]]."),
        fieldarray = _metaballs2dfield(funclist, transmatrix, newbbox, pixsize, nballs),
        pxcenters = use_centers ? _metaballs2dfield(funclist, transmatrix,
            [newbbox[0]+0.5*pixsize, newbbox[1]-0.499*pixsize], pixsize, nballs)
            : false,
        contours = contour(fieldarray, isoval, newbbox, pixsize, closed=closed, use_centers=pxcenters, smoothing=smoothing, exact_bounds=true, show_stats=show_stats, _mball=true)
    ) _debug ? [
        contours, [
            for(i=[0:2:len(funclist)-1])
                let(fl=funclist[i+1][1])
                    [ fl[0], apply(funclist[i], fl[1]) ]
        ]
    ]
    : contours;


// set up 2D field array
// accumulate metaball contributions using matrices rather than sums
function _metaballs2dfield(funclist, transmatrix, bbox, pixsize, nballs) = let(
    bot = bbox[0],
    top = bbox[1],
    halfpix = 0.5*pixsize,
    xset = [bot.x:pixsize.x:top.x+halfpix.x],
    yset = list([bot.y:pixsize.y:top.y+halfpix.y]),
    allpts = [for(x=xset, y=yset) [x,y,0,1]],
    trans_pts = [for(i=[0:nballs-1]) allpts*transmatrix[i]],
    allvals = [for(i=[0:nballs-1]) [for(pt=trans_pts[i]) funclist[2*i+1][0](pt)]],
    //total = _sum(allvals,allvals[0]*EPSILON),
    total = _sum(slice(allvals,1,-1), allvals[0])
) list_to_matrix(total,len(yset));

/// ---------- isosurface stuff starts here ----------

// Section: Isosurfaces (3D) and contours (2D)
//   The isosurface of a function $f(x,y,z)$ is the set of points where $f(x,y,z)=c$ for some
//   constant isovalue $c$.
//   .
//   The contour of a function $f(x,y)$ is the set of points where $f(x,y)=c$ for some constant isovalue $c$.
//   Considered in the context of an elevation map, the function returns an elevation associated with any $(x,y)$
//   point, and the isovalue $c$ is a specific elevation at which to compute the contour paths.
//   Any 2D cross-section of an isosurface is a contour. 
//   .
//   <a name="isosurface-contour-parameters"></a>
//   ***Parameters common to `isosurface()` and `contour()`***
//   .
//   **Parameter `f` (function):** The [function literal](https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/User-Defined_Functions_and_Modules#Function_literals)
//   must take 3 parameters (x, y and z) for isosurface or two parameters (x and y) for contour, and must return a single numerical value.
//   You can also define an isosurface or contour using an array of values instead of a function, in which
//   case the isosurface or contour is the set of points equal to the isovalue as interpolated from the array.
//   The array indices are in the order `[x][y][z]` in 3D, and `[x][y]` in 2D.
//   .
//   **Parameter `isovalue:`** The isovalue must be specified as a range `[c_min,c_max]`.
//   The range can be finite or unbounded at one end, with either `c_min=-INF` or `c_max=INF`.
//   For isosurface, the returned object is the set of points `[x,y,z]` that satisfy `c_min <= f(x,y,z) <= c_max`,
//   or in 2D, the points `[x,y]` satisfying `c_min <= f(x,y) <= c_max`.  Strictly speaking, this means the
//   isosurface and contour modules don't return a single contour or isovalue by the shape **bounded** by isosurfaces
//   or contours.  If the function has values larger than `c_min` and values smaller than `c_max`, then the result
//   is a shell object (3D) or ring object (2D) with two
//   bounding surfaces/curves corresponding to the isovalues of `c_min` and `c_max`. If the function is smaller
//   than `c_max` everywhere (which is true when `c_max = INF`), then no isosurface exists for `c_max`, so the object
//   has only one bounding surface: the one defined by `c_min`. This can result in a bounded object&mdash;a sphere 
//   or circle&mdash;or an unbounded object such as all the points outside of a sphere out
//   to infinity. A similar situation arises if the function is larger than `c_min` everywhere (which is true when
//   `c_min = -INF`). Setting isovalue to `[-INF,c_max]` or `[c_min,INF]` always produces an object with a
//   single bounding isosurface or contour, which itself can be unbounded. To obtain a bounded object, think about
//   whether the function values inside your object are smaller or larger than your iso value. If
//   the values inside are smaller, you produce a bounded object using `[-INF,c_max]`. If the values
//   inside are larger, you get a bounded object using `[c_min,INF]`.  When your object is unbounded, it will
//   be truncated at the bounded box, which can result in an object that looks like a simple cube. 
//   .
//   **Parameters `bounding_box` and grid units:** The isosurface or contour is evaluated over a bounding box. The
//   `bounding_box` parameter can be specified by its minimum and maximum corners:
//   `[[xmin,ymin,zmin],[xmax,ymax,zmax]]` in 3D, or `[[xmin,ymin],[xmax,ymax]]` in 2D. The bounding box can
//   also be specified as a scalar of a cube (in 3D) or square (in 2D) centered on the origin.
//   .
//   This bounding box is divided into grid units, specified as `voxel_size` in 3D or `pixel_size` in 2D,
//   which can be a scalar or a vector size.
//   Alternately, you can set the grid count (`voxel_count` or `pixel_count`) to fit approximately the
//   specified number of grid units into the bounding box.
//   .
//   Features in the scene having any dimension smaller than the grid spacing may not
//   be displayed, so if something seems to be missing, try making the grid units smaller or the grid count
//   larger. By default, if the voxel size or pixel size doesn't exactly divide your specified bounding box,
//   then the bounding box is enlarged to contain whole grid units, and centered on your requested box.
//   Alternatively, you may set `exact_bounds=true` to cause the grid units to adjust in size to fit instead,
//   resulting in non-square grid units.
//   .
//   The isosurface or contour object is clipped by the bounding box.  The contour module always closes the shapes
//   at the boundary to produce displayable polygons.  The isosurface module and the function forms
//   accept a `closed` parameter.  Setting `closed=false` causes the closing segments or surfaces along the bounding
//   box to be excluded from the model.  In 3D, this results in a non-manifold shape with holes, exposing the inside of the
//   object. In 2D, this results in an open-ended contour path with higher values on the right with respect to
//   the path direction.
//   .
//   ***Isosurface and contour run time***
//   .
//   The size of the voxels or pixels, and size of the bounding box affects the run time, which can be long.
//   This is usually more noticeable in 3D than 2D. In 3D, a voxel size of 1 with a bounding box volume of
//   200×200×200 may be slow because it requires the calculation and storage of eight million function values,
//   and more processing and memory to generate the triangulated mesh. On the other hand, a voxel size of 5
//   over a 100×100×100 bounding box requires only 8,000 function values and a modest computation time. A
//   good rule is to keep the number of voxels below 10,000 for preview, and adjust the voxel size smaller
//   for final rendering. If you don't specify voxel_size or voxel_count then metaballs uses a default
//   voxel_count of 10000, which should be reasonable for initial preview. Because a bounding box that is too
//   large wastes time computing function values that are not needed, you can also set the parameter
//   `show_stats=true` to get the actual bounds of the voxels intersected by the surface. With this
//   information, you may be able to decrease run time, or keep the same run time but increase the resolution. 


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
//   .
//   See [Isosurface contour parameters](#isosurface-contour-parameters) for details about
//   how the primary parameters work for isosurfaces.
//   .
//   **Why does my object appear as a cube?** If your object is unbounded, then when it intersects with
//   the bounding box and `closed=true`, the result may appear to be a solid cube, because the clipping
//   faces are all you can see and the bounding surface is hidden inside. Setting `closed=false` removes
//   the bounding box faces and exposes the inside structure (with inverted faces). If you want the bounded
//   object, you can correct this problem by changing your isovalue range. If you were using a finite range
//   `[c1,c2]`, try changing it to `[c2,INF]` or `[-INF,c1]`. If you were using an unbounded range like
//   `[c,INF]`, try switching the range to `[-INF,c]`.
//   .
//   **Manifold warnings:**
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
//   f = The isosurface function literal or array. As a function literal, `x,y,z` must be the first arguments. 
//   isovalue = A 2-vector giving an isovalue range. For an unbounded range, use `[-INF, max_isovalue]` or `[min_isovalue, INF]`.
//   bounding_box = The volume in which to perform computations, expressed as a scalar size of a cube centered on the origin, or a pair of 3D points `[[xmin,ymin,zmin], [xmax,ymax,zmax]]` specifying the minimum and maximum box corner coordinates. Unless you set `exact_bounds=true`, the bounding box size may be enlarged to fit whole voxels. When `f` is an array of values, `bounding_box` cannot be supplied if `voxel_size` is supplied because the bounding box is already implied by the array size combined with `voxel_size`, in which case this implied bounding box is centered around the origin.
//   voxel_size = Size of the voxels used to sample the bounding box volume, can be a scalar or 3-vector, or omitted if `voxel_count` is set. You may get non-cubical voxels of a slightly different size than requested if `exact_bounds=true`.
//   ---
//   voxel_count = Approximate number of voxels in the bounding box. If `exact_bounds=true` then the voxels may not be cubes. Use with `show_stats=true` to see the corresponding voxel size. Default: 10000 (if `voxel_size` not set)
//   closed = When true, close the surface if it intersects the bounding box by adding a closing face. When false, do not add a closing face and instead produce a non-manfold VNF that has holes.  Default: true
//   reverse = When true, reverses the orientation of the VNF faces. Default: false
//   exact_bounds = When true, shrinks voxels as needed to fit whole voxels inside the requested bounding box. When false, enlarges `bounding_box` as needed to fit whole voxels of `voxel_size`, and centers the new bounding box over the requested box. Default: false
//   show_stats = If true, display statistics in the console window about the isosurface: number of voxels that the surface passes through, number of triangles, bounding box of the voxels, and voxel-rounded bounding box of the surface, which may help you reduce your bounding box to improve speed. Enabling this parameter has a slight speed penalty. Default: false
//   show_box = (Module only) display the requested bounding box as transparent. This box may appear slightly different than specified if the actual bounding box had to be expanded to accommodate whole voxels. Default: false
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
// Example(3D,Med,NoAxes,VPD=47,VPT=[0,0,2]): You can specify non-cubical voxels for efficiency. This example shows the result of two identical surface functions. The figure on the left uses `voxel_size=1`, which washes out the detail in the z direction. The figure on the right shows the same shape with `voxel_size=[0.5,1,0.2]` to give a bit more resolution in the x direction and much more resolution in the z direction. This example runs about six times faster than if we used a cubical voxel of size 0.2 to capture the detail in only one axis at the expense of unnecessary detail in other axes.
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
        let(
            bbox0 = is_num(bounding_box)
            ? let(hb=0.5*bounding_box) [[-hb,-hb,-hb],[hb,hb,hb]]
            : bounding_box,
            autovoxsize = is_def(voxel_size) ? voxel_size : _getautovoxsize(bbox0, default(voxel_count,22^3)),
            exactbounds = is_def(exact_bounds) ? exact_bounds : is_list(f),
            voxsize = _mball ? voxel_size : _getvoxsize(autovoxsize, bbox0, exactbounds),
            bbox = _mball ? bounding_box : _getbbox(voxsize, bbox0, exactbounds, f)
        ) %translate(bbox[0]) cube(bbox[1]-bbox[0]);
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
        dumiso2 = assert(isovalmin != -INF || isovalmax != INF, "\nIsovalue range must be finite on one end."),
        exactbounds = is_def(exact_bounds) ? exact_bounds : is_list(f),

        // new voxel or bounding box centered around original, to fit whole voxels
        bbox0 = is_num(bounding_box)
            ? let(hb=0.5*bounding_box) [[-hb,-hb,-hb],[hb,hb,hb]]
            : bounding_box,
        autovoxsize = is_def(voxel_size) ? voxel_size : _getautovoxsize(bbox0, default(voxel_count,22^3)),
        voxsize = _mball ? voxel_size : _getvoxsize(autovoxsize, bbox0, exactbounds),
        bbox = _mball ? bounding_box : _getbbox(voxsize, bbox0, exactbounds, f),
        bbcheck = assert(all_positive(bbox[1]-bbox[0]), "\nbounding_box must be a vector range [[xmin,ymin,zmin],[xmax,ymax,zmax]]."),
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

        

/// ---------- contour stuff starts here ----------

// Function&Module: contour()
// Synopsis: Creates a 2D contour from a function or array of values.
// SynTags: Geom,Path,Region
// Topics: Contours, Path Generators (2D), Regions
// Usage: As a module
//   contour(f, isovalue, bounding_box, pixel_size, [pixel_count=], [use_centers=], [smoothing=], [exact_bounds=], [show_stats=], [show_box=], ...) [ATTACHMENTS];
// Usage: As a function
//   region = contour(f, isovalue, bounding_box, pixel_size, [pixel_count=], [pc_centers=], [smoothing=], [closed=], [show_stats=]);
// Description:
//   Computes a [region](regions.scad) that contains one or more 2D contour [paths](paths.scad)
//   within a bounding box at a single isovalue.
//   .
//   See [Isosurface contour parameters](#isosurface-contour-parameters) for details about
//   how the primary parameters work for contours.
//   .
//   To provide a function, you supply a [function literal](https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/User-Defined_Functions_and_Modules#Function_literals)
//   taking two parameters as input to define the grid coordinate location (e.g. `x,y`) and
//   returning a single numerical value.
//   You can also define an contour using a 2D array of values (i.e. a height map) instead of a
//   function, in which case the contour is the set of points equal to the isovalue as interpolated
//   from the array. The array indices are in the order `[x][y]` with `y` changing fastest.
//   .
//   The contour is evaluated over a bounding box defined by its minimum and maximum corners,
//   `[[xmin,ymin],[xmax,ymax]]`. This bounding box is divided into pixels of the specified
//   `pixel_size`. Smaller pixels produce a finer, smoother result at the expense of execution time.
//   If the pixel size doesn't exactly divide your specified bounding box, then the bounding box is
//   enlarged to contain whole pixels, and centered on your requested box. If the bounding box clips
//   the contour and `closed=true` (the default), additional edges are added along the edges of the
//   bounds. Setting `closed=false` causes a clipped path to end at the bounding box.
//   .
//   ***Closed and unclosed paths***
//   .
//   The module form of `contour()` always closes the polygons at the bounding box edges to produce
//   valid polygons.  The functional form of `contour()` supports a `closed` parameter. When `closed=true` (the default)
//   and a polygon is clipped by the bounding box, the bounding box edges are included in the polygon. The
//   resulting path list is a valid region with no duplicated vertices in any path. 
//   .
//   When `closed=false`, paths that intersect the edge of the bounding box end at the bounding box. This
//   means that the list of paths may include a mixture of closed and open paths. Regardless of whether
//   any of the output paths are open, all closed paths have identical first and last points so that  closed and
//   open paths can be distinguished. You can use {{are_ends_equal()}} to determine if a path is closed. A path
//   list that includes open paths is not a region, because regions are lists of closed polygons. Duplicating the
//   ends of closed paths can cause problems for functions such as {{offset()}}, which will complain about
//   repeated points or produce incorrect results.  You can use {{list_unwrap()}} to remove the extra endpoint.
// Arguments:
//   f = The contour function or array.
//   isovalue = A scalar giving the isovalue for the contour, or a 2-vector giving an isovalue range (resulting in a polygon bounded by two contours). For an unbounded range, use `[-INF,max_isovalue]` or `[min_isovalue,INF]`.
//   bounding_box = The area in which to perform computations, expressed as a scalar size of a square centered on the origin, or a pair of 2D points `[[xmin,ymin], [xmax,ymax]]` specifying the minimum and maximum box corner coordinates. Unless you set `exact_bounds=true`, the bounding box size may be enlarged to fit whole pixels. When `f` is an array of values, `bounding_box` cannot be supplied if `pixel_size` is supplied because the bounding box is already implied by the array size combined with `pixel_size`, in which case this implied bounding box is centered around the origin.
//   pixel_size = Size of the pixels used to sample the bounding box volume, can be a scalar or 2-vector, or omitted if `pixel_count` is set. You may get rectangular pixels of a slightly different size than requested if `exact_bounds=true`.
//   ---
//   pixel_count = Approximate number of pixels in the bounding box. If `exact_bounds=true` then the pixels may not be square. Use with `show_stats=true` to see the corresponding pixel size. Default: 1024 (if `pixel_size` not set)
//   use_centers = When true, uses the center value of each pixel as an additional data point to refine the contour path through the pixel. The center value is the function value if `f` is a function, or the average of the four pixel corners if `f` is an array. If `use_centers` is set to another array of center values, then those values are used. If false, the contour path doesn't account for the pixel center. Default: true
//   smoothing = Number of times to apply a 2-point moving average to the contours. This can remove small zig-zag artifacts resulting from a contour that follows the profile of a triangulated 3D surface when `use_centers` is set. Default: 2 if `use_centers=true`, 0 otherwise.
//   closed = (Function only) When true, close the contour path if it intersects the bounding box by adding closing edges. When false, do not add closing edges. Default: true, and always true when called as a module.
//   exact_bounds = When true, shrinks pixels as needed to fit whole pixels inside the requested bounding box. When false, enlarges `bounding_box` as needed to fit whole pixels of `pixel_size`, and centers the new bounding box over the requested box. Default: false
//   show_stats = If true, display statistics in the console window about the contour: number of pixels that the surface passes through, number of points in all contours, bounding box of the pixels, and pixel-rounded bounding box of the contours, which may help you reduce your bounding box to improve speed. Default: false
//   show_box = (Module only) display the requested bounding box as a transparent rectangle. This box may appear slightly different than specified if the actual bounding box had to be expanded to accommodate whole pixels. Default: false
//   cp = (Module only) Center point for determining intersection anchors or centering the shape. Determines the base of the anchor vector. Can be "centroid", "mean", "box" or a 3D point.  Default: "centroid"
//   anchor = (Module only) Translate so anchor point is at origin (0,0,0). See [anchor](attachments.scad#subsection-anchor).  Default: `"origin"`
//   spin = (Module only) Rotate this many degrees around the Z axis after anchor. See [spin](attachments.scad#subsection-spin).  Default: `0`
//   atype = (Module only) Select "hull" or "intersect" anchor type.  Default: "hull"
// Anchor Types:
//   "hull" = Anchors to the virtual convex hull of the shape.
//   "intersect" = Anchors to the surface of the shape.
// Example(2D,NoAxes): A small height map consisting of 8×8 data values to create a 7×7 pixel area, showing a contour at one isovalue. When passing an array as the first argument, rotating the output 90° clockwise using `zrot(-90)` causes the features of the contour to correspond visually to features in the array. Setting `use_centers=false` results in only the corner values of each pixel to be considered when drawing contour lines, resulting in coarse outlines.
//   field =[
//       [0,2,2,1,0,0,0,0],
//       [2,4,1,0,0,0,0,0],
//       [2,2,2,1,0,0,0,0],
//       [0,0,1,2,2,2,1,1],
//       [0,0,2,1,0,3,1,0],
//       [0,2,0,2,0,3,4,0],
//       [0,0,0,1,2,3,2,0],
//       [0,0,0,0,0,1,0,0]
//   ];
//   isoval=[0.7,INF];
//   pixsize = 5;
//   color("lightgreen") zrot(-90)
//       contour(field, isoval, pixel_size=pixsize,
//           use_centers=false);
//   color("blue") down(1)
//       square((len(field)-1)*pixsize, true);
// Example(2D,NoAxes): The same height map with the same isovalue, this time setting `use_centers=true` to cause the pixel center values (average of the four corners) to be considered when drawing contours, giving somewhat finer resolution. When `use_centers=true`, some smoothing is applied to avoid some additional crookedness in the contours that occurs due to the contours following a slice of a triangulated mesh with triangles in varying orientations.
//   field =[
//       [0,2,2,1,0,0,0,0],
//       [2,4,1,0,0,0,0,0],
//       [2,2,2,1,0,0,0,0],
//       [0,0,1,2,2,2,1,1],
//       [0,0,2,1,0,3,1,0],
//       [0,2,0,2,0,3,4,0],
//       [0,0,0,1,2,3,2,0],
//       [0,0,0,0,0,1,0,0]
//   ];
//   isoval=[0.7,INF];
//   pixsize = 5;
//   color("lightgreen") zrot(-90)
//       contour(field, isoval, pixel_size=pixsize,
//           use_centers=true);
//   color("blue") down(1)
//       square((len(field)-1)*pixsize, true);
// Example(3D,NoAxes): You can pass a function literal taking x,y arguments, in which case the center value of each pixel is computed in addition to the corners for somewhat greater resolution than the specified pixel size. By default, two smoothing passes are performed on the output paths when making contours from a function.
//   wavelen=42;
//   wave2d = function(x,y)
//       40*cos(180/wavelen*norm([x,y]));
//   isoval=-30;
//   pixsize = 10;
//   translate([0,0,isoval]) color("green") zrot(-90)
//       contour(wave2d, 
//           bounding_box=[[-50,-50],[50,50]],
//           isovalue=[isoval,INF], pixel_size=pixsize);
//   %plot3d(wave2d, [-50:pixsize:50],[-50:pixsize:50],
//          style="quincunx",base=5);
// Example(2D,NoAxes): Here's a simple function that produces a contour in the shape of a flower with some petals. Note that the function has smaller values inside the shape so we choose a `-INF` bound for the isovalue.  
//   f = function (x, y, petals=5)
//       sin(petals*atan2(y,x)) + norm([x,y]);
//   contour(f, isovalue=[-INF,3], bounding_box=8.1);
// Example(2D,NoAxes): If we instead use a `+INF` bound then we get the bounding box with the flower shape removed.  
//   f = function (x, y, petals=5)
//       sin(petals*atan2(y,x)) + norm([x,y]);
//   contour(f, isovalue=[3,INF], bounding_box=8.1);
// Example(3D,NoAxes): We can take the previous function a step further and make the isovalue range bounded on both ends, resulting in a hollow shell shape. The nature of the function causes the thickness to vary, which is different from the constant thickness you would get if you subtracted an `offset()` polygon from the inside. Here we extrude this polygon with a twist.
//   f = function (x, y, petals=5)
//      sin(petals*atan2(y,x)) + norm([x,y]);
//   linear_extrude(6, twist=30, scale=0.75, slices=10)
//      contour(f, isovalue=[2,3], bounding_box=8.1);
// Example(2D,NoAxes): Another function that needs an isovalue range to create a solid polygon. Increasing the minimum value results in holes in the object.
//   f = function(x,y) (x^2+y-11)^2 + (x+y^2-7)^2;
//   contour(f, bounding_box=12, isovalue=[0,125]);
// Example(2D,NoAxes): The shape of these contours are somewhat sensitive to pixel size.
//   f = function(x,y)  x^2+y^2 + 10*(1-cos(360*x)-cos(360*y));
//   contour(f, bounding_box=13, isovalue=[-INF,35],
//       pixel_size=0.25);
// Example(2D,NoAxes,VPD=1920): An infinite periodic pattern showing contours at one elevation in red, overlaid with a transparent render of the 3D heightmap generated by the function.
//   f = function(x,y) 100*(sin(x)*sin(y) * sin(x+y));
//   pixel_size = 20;
//   isovalue = 1;
//   bbox = 720;
//   up(isovalue) color("red") linear_extrude(1)
//       contour(f, [isovalue,INF], bbox, pixel_size);
//   %plot3d(f, [-360:pixel_size/2:360],
//           [-360:pixel_size/2:360], style="quincunx");
// Example(2D,NoAxes): A [Cassini oval](https://en.wikipedia.org/wiki/Cassini_oval) is a curve drawn such that for any point on the perimeter, the product of the distances from two fixed points is constant. The curve resembles two circular [metaballs](#functionmodule-metaballs2d) interacting. When the ratio `b/a=1`, there is a cusp where two contours meet at the origin, although the contour algorithm doesn't allow the two contours to touch.
//   a=4;  b=4.1;
//   f = function(x,y) (x^2+y^2)^2 - 2*a^2*(x^2-y^2) + a^4;
//   contour(f,bounding_box=[[-6,-3],[6,3]], isovalue=[-INF,b^4]);
// Example(2D,NoAxes,VPD=65,VPT=[-7,0,0]): A contour of a function that looks like the contour should intersect itself at the origin, but if you zoom in, you see that it doesn't actually cross or intersect. It is theoretically possible to obtain a crossing path with `contour()` although the algorithm attempts to avoid it, primarily by disallowing the function values at the sample points to be equal to the specified isovalue.
//   g = function(x,y)
//       let(
//           theta=atan2(y,x),
//           r = norm([x,y])
//       )
//       r*sin(3*theta-theta^2/20+40*r);
//   contour(g, bounding_box=[[-23,-13],[9,13]],
//       isovalue=[0,INF], pixel_size=0.2);
 
module contour(f, isovalue, bounding_box, pixel_size, pixel_count=undef, use_centers=true, smoothing=undef, exact_bounds=false, cp="centroid", anchor="origin", spin=0, atype="hull", show_stats=false, show_box=false, _mball=false) {
    pathlist = contour(f, isovalue, bounding_box, pixel_size, pixel_count, use_centers, smoothing, true, exact_bounds, show_stats, _mball);
    assert(len(pathlist)>0, "\nNo contour lines found! Cannot generate polygon. Check your isovalue.")
        attachable(anchor, spin, two_d=true, region=pathlist, extent=atype=="hull", cp=cp) {
            region(pathlist, anchor=anchor, spin=spin, cp=cp, atype=atype);
            children();
        }
    if(show_box)
        let(
            bbox0 = is_num(bounding_box)
            ? let(hb=0.5*bounding_box) [[-hb,-hb],[hb,hb]]
            : bounding_box,
            autopixsize = is_def(pixel_size) ? pixel_size : _getautopixsize(bbox0, default(pixel_count,32^2)),
            pixsize = _mball ? pixel_size : _getpixsize(autopixsize, bbox0, exact_bounds),
            bbox = _mball ? bounding_box : _getbbox2d(pixsize, bbox0, exact_bounds, f)
        ) %translate([bbox[0][0],bbox[0][1],-0.05]) linear_extrude(0.1) square(bbox[1]-bbox[0]);
}

function contour(f, isovalue, bounding_box, pixel_size, pixel_count=undef, use_centers=true, smoothing=undef, closed=true, exact_bounds=false, show_stats=false, _mball=false) =
    assert(all_defined([f, isovalue]), "\nThe parameters f and isovalue must both be defined.")
    assert(is_function(f) ||
        (is_list(f) &&
            // _mball=true allows pixel_size and bounding_box to coexist with f as array, because metaballs2d() already calculated them
            (_mball || 
                ((is_def(bounding_box) && is_undef(pixel_size)) || (is_undef(bounding_box) && is_def(pixel_size)))
            )
        )
        , "\nWhen f is an array, either bounding_box or pixel_size is required (but not both).")
    assert(is_list(isovalue) && len(isovalue)==2 && is_num(isovalue[0]) && is_num(isovalue[1]),
           "\nThe isovalue parameter must be a list of two numbers")
    let(
        isovalmin = isovalue[0], 
        isovalmax = isovalue[1], 
        dumiso1 = assert(isovalmin < isovalmax, str("\nBad isovalue range (", isovalmin, ", >= ", isovalmax, "), should be expressed as [min_value, max_value].")),
        dumiso2 = assert(isovalmin != -INF || isovalmax != INF, "\nIsovalue range must be finite on one end."),
        exactbounds = is_def(exact_bounds) ? exact_bounds : is_list(f),
        smoothpasses = is_undef(smoothing) ? ((is_list(use_centers) || use_centers==true) ? 2 : 0) : abs(smoothing),
        // new pixel or bounding box centered around original, to fit whole pixels
        bbox0 = is_num(bounding_box)
            ? let(hb=0.5*bounding_box) [[-hb,-hb],[hb,hb]]
            : bounding_box,
        autopixsize = is_def(pixel_size) ? pixel_size : _getautopixsize(bbox0, default(pixel_count,32^2)),
        pixsize = _mball ? pixel_size : _getpixsize(autopixsize, bbox0, exactbounds),
        bbox = _mball ? bounding_box : _getbbox2d(pixsize, bbox0, exactbounds, f),
        bbcheck = assert(all_positive(bbox[1]-bbox[0]), "\nbounding_box must be a vector range [[xmin,ymin],[xmax,ymax]]."),
        // proceed with isosurface computations
        pixels = _contour_pixels(pixsize, bbox,
            fieldarray=is_function(f)?undef:f, fieldfunc=is_function(f)?f:undef,
            pixcenters=use_centers, isovalmin=isovalmin, isovalmax=isovalmax, closed=closed),
        segtablemin = is_list(use_centers) || use_centers ? _MTriSegmentTable : _MSquareSegmentTable,
        segtablemax = is_list(use_centers) || use_centers ? _MTriSegmentTable_reverse : _MSquareSegmentTable_reverse,
        pathlist = _contour_vertices(pixels, pixsize, isovalmin, isovalmax, segtablemin, segtablemax),
        region = _assemble_partial_paths(pathlist, closed),
        smoothregion = _region_smooth(region, smoothpasses, bbox),
        finalregion = closed ? smoothregion
            : [for(p=smoothregion) _pathpts_on_bbox(p, bbox)>1 ? p : concat(p, [p[0]])],
        dum2 = show_stats ? _showstats_contour(pixsize, bbox, isovalmin, isovalmax, pixels, finalregion) : 0
) finalregion;


/// internal function: do multiple 2-point smoothing passes of all the paths in a region
function _region_smooth(reg, passes, bbox, count=0) =
    count >= passes ? reg :
    let(sm = [
        for(r=reg) let(
            n = r[0]==last(r) ? len(r)-1 : len(r),
            pb = [for(i=[0:n-1]) _is_pt_on_bbox(r[i],bbox)]
            ) [
                for(i=[0:n-1]) let(j=(i+1)%n) each [
                    if(pb[i]) r[i],
                    if(!(pb[i] && pb[j])) 0.5*(r[i]+r[j])
                ]
            ]
        ]
    ) _region_smooth(sm, passes, bbox, count+1);


/// internal function: return true if a point is within EPSILON of the bounding box edge
function _is_pt_on_bbox(p, bbox) = let(
    a = v_abs(p-bbox[0]),
    b = v_abs(p-bbox[1])
) a[0]<EPSILON || a[1]<EPSILON || b[0]<EPSILON || b[1]<EPSILON;


/// internal function: return number of path points that fall on the bounding box edge
function _pathpts_on_bbox(path, bbox, i=0, count=0) =
    i==len(path) ? count
    : _pathpts_on_bbox(path, bbox, i+1, count+(_is_pt_on_bbox(path[i], bbox)?1:0));


/// internal function: get pixel size given a desired number of pixels in a bounding box
function _getautopixsize(bbox, numpixels) =
    let(
        bbsiz = bbox[1]-bbox[0],
        bbarea = bbsiz[0]*bbsiz[1],
        pixarea = bbarea/numpixels
    ) sqrt(pixarea);

    
/// internal function: get pixel size, adjusted if necessary to fit bounding box
function _getpixsize(pixel_size, bounding_box, exactbounds) =
    let(pixsize0 = is_num(pixel_size) ? [pixel_size, pixel_size] : pixel_size)
        exactbounds ? 
            let(
                reqboxsize = bounding_box[1] - bounding_box[0],
                bbnums = v_ceil(v_div(bounding_box[1]-bounding_box[0], pixsize0)),
                newboxsize = v_mul(bbnums, pixsize0)
            ) v_mul(pixsize0, v_div(reqboxsize, newboxsize))
        : pixsize0; // if exactbounds==false, we don't adjust pixel size

        
/// internal function: get 2D bounding box, adjusted in size and centered on requested box
function _getbbox2d(pixel_size, bounding_box, exactbounds, f=undef) =
    let(
        pixsize0 = is_num(pixel_size) ? [pixel_size, pixel_size] : pixel_size,
        bbox = is_list(bounding_box) ? bounding_box
        : is_num(bounding_box) ? let(hb=0.5*bounding_box) [[-hb,-hb],[hb,hb]]
        : let( // bounding_box==undef if we get here, then f must be an array
            bbnums = [len(f), len(f[0])] - [1,1],
            halfbb = 0.5 * v_mul(pixsize0, bbnums)
        ) [-halfbb, halfbb]
    )   exactbounds ?
            bbox // if grow_bounds==false, we don't adjust bounding box
        : let(    // adjust bounding box
            bbcenter = mean(bbox),
            bbnums = v_ceil(v_div(bbox[1]-bbox[0], pixsize0)),
            halfbb = 0.5 * v_mul(pixsize0, bbnums)
        ) [bbcenter - halfbb, bbcenter + halfbb];

        
/// _showstats_contour() (Private function) - called by contour()
/// Display statistics about a contour region
function _showstats_contour(pixelsize, bbox, isovalmin, isovalmax, pixels, pathlist) = let(
    v = column(pixels, 0), // extract pixel vertices
    x = column(v,0),    // extract x values
    y = column(v,1),    // extract y values
    xmin = min(x),
    xmax = max(x)+pixelsize.x,
    ymin = min(y),
    ymax = max(y)+pixelsize.y,
    npts = sum([for(p=pathlist) len(p)]),
    npix = len(pixels)
) echo(str("\nContour statistics:\n   Isovalue = ", [isovalmin,isovalmax], "\n   Pixel size = ", pixelsize,
    "\n   Pixels found containing surface = ", npix, "\n   Total path vertices = ", npts,
    "\n   Pixel bounding box for all data = ", bbox,
    "\n   Pixel bounding box for contour = ", [[xmin,ymin], [xmax,ymax]],
    "\n")) 0;
