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
//   centers that define the metaballs locations. For metaballs, a function is defined for
//   all points in a 3D volume based on the distance from any point to the centers of each metaball. The
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
//   value $c$. Such a function is also known as an "implied surface" because the function *implies* a
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
//   
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

-----------------------------------------------------------
Addition by Alex:
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

/// return an array of face indices in _MCFaceVertexIndices if the voxel at coordinate v0 corresponds to the bounding box.
function _bbox_faces(v0, voxsize, bbox) = let(
    a = v0-bbox[0],
    bb1 = bbox[1] - [voxsize,voxsize,voxsize],
    b = v0-bb1
) [
    if(a[0]==0) 1,
    if(a[1]==0) 2,
    if(a[2]==0) 3,
    if(b[0]>=0) 4,
    if(b[1]>=0) 5,
    if(b[2]>=0) 6
];
/// End of bounding-box face-clipping stuff. Back to the marching cubes triangulation....


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
    (f[0] > isoval ? 1 : 0) +
    (f[1] > isoval ? 2 : 0) +
    (f[2] > isoval ? 4 : 0) +
    (f[3] > isoval ? 8 : 0) +
    (f[4] > isoval ? 16 : 0) +
    (f[5] > isoval ? 32 : 0) +
    (f[6] > isoval ? 64 : 0) +
    (f[7] > isoval ? 128 : 0);


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
/// The bounding box 'bbox' is expected to be quantized for the voxel size already.

function _isosurface_cubes(voxsize, bbox, fieldarray, fieldfunc, isovalmin, isovalmax, closed=true) = let(
    // get field intensities
    field = is_def(fieldarray)
    ? fieldarray
    : let(v = bbox[0], hv = 0.5*voxsize, b1 = bbox[1]+[hv,hv,hv]) [
        for(x=[v.x:voxsize:b1.x]) [
            for(y=[v.y:voxsize:b1.y]) [
                for(z=[v.z:voxsize:b1.z])
                    fieldfunc(x,y,z)
            ]
        ]
    ],
    nx = len(field)-2,
    ny = len(field[0])-2,
    nz = len(field[0][0])-2,
    v0 = bbox[0]
) [
    for(i=[0:nx]) let(x=v0[0]+voxsize*i)
        for(j=[0:ny]) let(y=v0[1]+voxsize*j)
            for(k=[0:nz]) let(z=v0[2]+voxsize*k)
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
                    cubefound_isomin = (mincf<=isovalmin && isovalmin<maxcf),
                    cubefound_isomax = (mincf<=isovalmax && isovalmax<maxcf),
                    cubefound_outer = len(bfaces)==0 ? false
                    : let(
                        bf = flatten([for(i=bfaces) _MCFaceVertexIndices[i]]),
                        sumcond = len([for(b=bf) if(isovalmin<cf[b] && cf[b]<isovalmax) 1 ])
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
function _isosurface_triangles(cubelist, cubesize, isovalmin, isovalmax, tritablemin, tritablemax) = [
    for(cl=cubelist)
        let(
            v = cl[0],          // voxel coord
            cbidxmin = cl[1],   // cube ID for isomvalmin
            cbidxmax = cl[2],   // cube ID for isovalmax
            f = cl[3],          // function values for each cube corner
            bbfaces = cl[4],    // faces (if any) on the bounding box
            vcube = [           // cube corner vertex coordinates
                v, v+[0,0,cubesize], v+[0,cubesize,0], v+[0,cubesize,cubesize],
                v+[cubesize,0,0], v+[cubesize,0,cubesize],
                v+[cubesize,cubesize,0], v+[cubesize,cubesize,cubesize]
            ],
            outfacevertices = flatten([
                for(bf = bbfaces)
                    _bbfacevertices(vcube, f, bf, isovalmax, isovalmin)
            ])
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
            if(len(outfacevertices)>0) for(bf = bbfaces)
                  each _bbfacevertices(vcube, f, bf, isovalmax, isovalmin)
        ]
];


/// Generate triangles for the special case of voxel faces clipped by the bounding box
function _bbfacevertices(vcube, f, bbface, isovalmax, isovalmin) = let(
    vi = _MCFaceVertexIndices[bbface], // four voxel face vertex indices 
    //vfc = [ for(i=vi) vcube[i] ], // four voxel face vertex coordinates
    //fld = [ for(i=vi) f[i] ],   // four corner field values
    pgon = flatten([
        for(i=[0:3]) let(   // for each line segment...
            vi0=vi[i],          // voxel corner 0 index
            vi1=vi[(i+1)%4],    // voxel corner 1 index
            f0 = f[vi0],        // field value at corner 0
            f1 = f[vi1],        // field value at corner 1
            fmin = min(f0, f1), // min field of the corners
            fmax = max(f0, f1), // max field of the corners
            ilowbetween = (fmin < isovalmin && isovalmin < fmax),
            ihighbetween = (fmin < isovalmax && isovalmax < fmax),
            denom = f1-f0
        ) [ // traverse the edge, output vertices as they are found
            if(isovalmin <= f0 && f0 <= isovalmax)// && abs(f1-f0)>0.001)
                // vertex 0 is on or between min and max isovalues
                //echo(vfc, fld)
                vcube[vi0],
            // for f0<f1, find isovalmin, then isovalmax intersections
            if(ilowbetween && f0<f1)
                let(u = abs(denom)<0.00001 ? 0.5 : (isovalmin-f0)/denom)
                    vcube[vi0] + u*(vcube[vi1]-vcube[vi0]),
            if(ihighbetween && f0<f1)
                let(u = abs(denom)<0.00001 ? 0.5 : (isovalmax-f0)/denom)
                    vcube[vi0] + u*(vcube[vi1]-vcube[vi0]),
            // for f1<f0, find isovalmax, then isovalmin intersections
            if(ihighbetween && f0>f1)
                let(u = abs(denom)<0.00001 ? 0.5 : (isovalmax-f0)/denom)
                    vcube[vi0] + u*(vcube[vi1]-vcube[vi0]),
            if(ilowbetween && f0>f1)
                let(u = abs(denom)<0.00001 ? 0.5 : (isovalmin-f0)/denom)
                    vcube[vi0] + u*(vcube[vi1]-vcube[vi0])
        ]
    ]),
    npgon = len(pgon),
    triangles = npgon<3 ? [] : [
        for(i=[1:len(pgon)-2]) [pgon[0], pgon[i], pgon[i+1]]
    ]) flatten(triangles);


/// _showstats() (Private function) - called by isosurface() and metaballs()
/// Display statistics about isosurface
function _showstats(voxelsize, bbox, isoval, cubes, faces) = let(
    v = column(cubes, 0), // extract cube vertices
    x = column(v,0),    // extract x values
    y = column(v,1),    // extract y values
    z = column(v,2),    // extract z values
    xmin = min(x),
    xmax = max(x)+voxelsize,
    ymin = min(y),
    ymax = max(y)+voxelsize,
    zmin = min(z),
    zmax = max(z)+voxelsize,
    ntri = len(faces),
    nvox = len(cubes)
) echo(str("\nIsosurface statistics:\n   Outer isovalue = ", isoval, "\n   Voxel size = ", voxelsize,
    "\n   Voxels found containing surface = ", nvox, "\n   Triangles = ", ntri,
    "\n   Voxel bounding box for all data = ", bbox,
    "\n   Voxel bounding box for isosurface = ", [[xmin,ymin,zmin], [xmax,ymax,zmax]],
    "\n")) 0;



/// ---------- metaball stuff starts here ----------

/// Animated metaball demo made with BOSL2 here: https://imgur.com/a/m29q8Qd

/// Built-in metaball functions corresponding to each MB_ index.
/// For speed, they are split into four functions, each handling a different combination of influence != 1 or influence == 1, and cutoff < INF or cutoff == INF.

/// public metaball cutoff function if anyone wants it (demonstrated in example)

function mb_cutoff(dist, cutoff) = dist>=cutoff ? 0 : 0.5*(cos(180*(dist/cutoff)^4)+1);


/// metaball sphere

function _mb_sphere_basic(dv, r, neg) = neg*r/norm(dv);
function _mb_sphere_influence(dv, r, ex, neg) = neg * (r/norm(dv))^ex;
function _mb_sphere_cutoff(dv, r, cutoff, neg) = let(dist=norm(dv))
    neg * mb_cutoff(dist, cutoff) * r/dist;
function _mb_sphere_full(dv, r, cutoff, ex, neg) = let(dist=norm(dv))
    neg * mb_cutoff(dist, cutoff) * (r/dist)^ex;

function mb_sphere(r, cutoff=INF, influence=1, negative=false, d) =
   assert(is_num(cutoff) && cutoff>0, "\ncutoff must be a positive number.")
   assert(is_finite(influence) && influence>0, "\ninfluence must be a positive number.")
   let(
       r = get_radius(r=r,d=d),
       dummy=assert(is_finite(r) && r>0, "\ninvalid radius or diameter."),
       neg = negative ? -1 : 1
   )
   !is_finite(cutoff) && influence==1 ? function(dv) _mb_sphere_basic(dv,r,neg)
 : !is_finite(cutoff) ? function(dv) _mb_sphere_influence(dv,r,1/influence, neg)
 : influence==1 ? function(dv) _mb_sphere_cutoff(dv,r,cutoff,neg)
 : function(dv) _mb_sphere_full(dv,r,cutoff,1/influence,neg);


/// metaball rounded cube

function _mb_cuboid_basic(dv, inv_size, xp, neg) =
   let(
       dv=inv_size * dv,
       dist = xp >= 1100 ? max(v_abs(dv))
                         : (abs(dv.x)^xp + abs(dv.y)^xp + abs(dv.z)^xp) ^ (1/xp)
      ) neg/dist;
function _mb_cuboid_influence(dv, inv_size, xp, ex, neg) = let(
    dv=inv_size * dv,
    dist = xp >= 1100 ? max(v_abs(dv))
                      :(abs(dv.x)^xp + abs(dv.y)^xp + abs(dv.z)^xp) ^ (1/xp)
) neg / dist^ex;
function _mb_cuboid_cutoff(dv, inv_size, xp, cutoff, neg) = let(
    dv = inv_size * dv, 
    dist = xp >= 1100 ? max(v_abs(dv))
                      : (abs(dv.x)^xp + abs(dv.y)^xp + abs(dv.z)^xp) ^ (1/xp)
) neg * mb_cutoff(dist, cutoff) / dist;
function _mb_cuboid_full(dv, inv_size, xp, ex, cutoff, neg) = let(
    dv = inv_size * dv,
    dist = xp >= 1100 ? max(v_abs(dv))
                      :(abs(dv.x)^xp + abs(dv.y)^xp + abs(dv.z)^xp) ^ (1/xp)
) neg * mb_cutoff(dist, cutoff) / dist^ex;

function mb_cuboid(size, squareness=0.5, cutoff=INF, influence=1, negative=false) =
   assert(is_num(cutoff) && cutoff>0, "\ncutoff must be a positive number.")
   assert(is_finite(influence) && influence>0, "\ninfluence must be a positive number.")
   assert((is_finite(size) && size>0) || (is_vector(size) && all_positive(size)), "\nsize must be a positive number or a 3-vector of positive values.")
   let(
       xp = _squircle_se_exponent(squareness),
       neg = negative ? -1 : 1,
       inv_size = is_num(size) ? 2/size
                : [[2/size.x,0,0],[0,2/size.y,0],[0,0,2/size.z]]
   )
   !is_finite(cutoff) && influence==1 ? function(dv) _mb_cuboid_basic(dv, inv_size, xp, neg)
 : !is_finite(cutoff) ? function(dv) _mb_cuboid_influence(dv, inv_size, xp, 1/influence, neg)
 : influence==1 ? function(dv) _mb_cuboid_cutoff(dv, inv_size, xp, cutoff, neg)
 : function (dv) _mb_cuboid_full(dv, inv_size, xp, 1/influence, cutoff, neg);


/// metaball rounded cylinder / cone

function _revsurf_basic(dv, path, coef, neg) =
    let(
         pt = [norm([dv.x,dv.y]), dv.z],
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
         inside_check = [for(seg=segs)
                     if (cross(seg[1]-seg[0], pt-seg[0]) > EPSILON) 1]
    )
    neg * (inside_check==[] ? coef*(1+dist) : coef/(1+dist));

function _revsurf_influence(dv, path, coef, exp, neg) =
    let(
         pt = [norm([dv.x,dv.y]), dv.z],
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
         inside_check = [for(seg=segs)
                     if (cross(seg[1]-seg[0], pt-seg[0]) > EPSILON) 1]
    )
    neg * (inside_check==[] ? (coef*(1+dist))^exp : (coef/(1+dist))^exp);

function _revsurf_cutoff(dv, path, coef, cutoff, neg) =
    let(
         pt = [norm([dv.x,dv.y]), dv.z],
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
         inside_check = [for(seg=segs)
                     if (cross(seg[1]-seg[0], pt-seg[0]) > EPSILON) 1]
    )
    neg * (inside_check==[]
        ? (coef*(1+dist)) : mb_cutoff(dist-coef, cutoff) * (coef/(1+dist)) );

function _revsurf_full(dv, path, coef, cutoff, exp, neg) =
    let(
        pt = [norm([dv.x,dv.y]), dv.z],
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
         inside_check = [
            for(seg=segs)
                if (cross(seg[1]-seg[0], pt-seg[0]) > EPSILON) 1
        ]
    )
    neg * (inside_check==[]
        ? (coef*(1+dist))^exp : mb_cutoff(dist-coef, cutoff) * (coef/(1+dist))^exp );

function mb_cyl(h,r,rounding=0,r1,r2,l,height,length,d1,d2,d, cutoff=INF, influence=1, negative=false) =
    let(
         r1 = get_radius(r1=r1,r=r, d1=d1, d=d),
         r2 = get_radius(r1=r2,r=r, d1=d2, d=d),
         h = first_defined([h,l,height,length],"h,l,height,length")
    )
    assert(is_finite(rounding) && rounding>=0, "rounding must be a nonnegative number")
    assert(is_finite(r1) && r1>0, "r/r1/d/d1 must be a positive number")
    assert(is_finite(r2) && r2>0, "r/r2/d/d2 must be a positive number")
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
    let(shifted = offset(sides, delta=-rounding, closed=false))
       !is_finite(cutoff) && influence==1 ? function(dv) _revsurf_basic(dv, shifted, 1+rounding, neg)
     : !is_finite(cutoff) ? function(dv) _revsurf_influence(dv, shifted, 1+rounding, 1/influence, neg)
     : influence==1 ? function(dv) _revsurf_cutoff(dv, shifted, 1+rounding, cutoff, neg)
     : function (dv) _revsurf_full(dv, shifted, 1+rounding, cutoff, 1/influence, neg);


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

function mb_capsule(h, r, cutoff=INF, influence=1, negative=false, d,l,height,length) =
    assert(is_num(cutoff) && cutoff>0, "\ncutoff must be a positive number.")
    assert(is_finite(influence) && influence>0, "\ninfluence must be a positive number.")
    let(
        h = one_defined([h,l,height,length],"h,l,height,length"),
        dum1 = assert(is_finite(h) && h>0, "\ncylinder height must be a positive number."),
        r = get_radius(r=r,d=d),
        dum2 = assert(is_finite(r) && r>0, "\ninvalid radius or diameter."),
        sh = h-2*r, // straight side length
        dum3 = assert(sh>0, "\nTotal length must accommodate rounded ends of cylinder."),
        neg = negative ? -1 : 1
   )
   !is_finite(cutoff) && influence==1 ? function(dv) _mb_capsule_basic(dv,sh/2,r,neg)
 : !is_finite(cutoff) ? function(dv) _mb_capsule_influence(dv,sh/2,r,1/influence, neg)
 : influence==1 ? function(dv) _mb_capsule_cutoff(dv,sh/2,r,cutoff,neg)
 : function (dv) _mb_capsule_full(dv, sh/2, r, cutoff, 1/influence, neg);


/// metaball disk with rounded edge

function _mb_disk_basic(dv, hl, r, neg) =
    let(
        rdist=norm([dv.x,dv.y]), 
        dist = rdist<r ? abs(dv.z) : norm([rdist-r,dv.z])
    ) neg*hl/dist;
function _mb_disk_influence(dv, hl, r, ex, neg) =
    let(
        rdist=norm([dv.x,dv.y]), 
        dist = rdist<r ? abs(dv.z) : norm([rdist-r,dv.z])
    ) neg*(hl/dist)^ex;
function _mb_disk_cutoff(dv, hl, r, cutoff, neg) =
    let(
        rdist=norm([dv.x,dv.y]), 
        dist = rdist<r ? abs(dv.z) : norm([rdist-r,dv.z])
    ) neg * mb_cutoff(dist, cutoff) * hl/dist;
function _mb_disk_full(dv, hl, r, cutoff, ex, neg) =
    let(
        rdist=norm([dv.x,dv.y]), 
        dist = rdist<r ? abs(dv.z) : norm([rdist-r,dv.z])
    ) neg* mb_cutoff(dist, cutoff) * (hl/dist)^ex;

function mb_disk(h, r, cutoff=INF, influence=1, negative=false, d,l,height,length) =
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
        neg = negative ? -1 : 1
   )
   !is_finite(cutoff) && influence==1 ? function(dv) _mb_disk_basic(dv,h2,r,neg)
 : !is_finite(cutoff) ? function(dv) _mb_disk_influence(dv,h2,r,1/influence, neg)
 : influence==1 ? function(dv) _mb_disk_cutoff(dv,h2,r,cutoff,neg)
 : function (dv) _mb_disk_full(dv, h2, r, cutoff, 1/influence, neg);


/// metaball connector cylinder - calls mb_capsule* functions after transform

function mb_connector(p1, p2, r, cutoff=INF, influence=1, negative=false, d) =
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
        transform = submatrix(down(h)*rot(from=dc,to=UP)*move(-p1) ,[0:2], [0:3])
   )
   !is_finite(cutoff) && influence==1 ? function(dv)
        let(newdv = transform * [each dv,1])
            _mb_capsule_basic(newdv,h,r,neg)
 : !is_finite(cutoff) ? function(dv)
        let(newdv = transform * [each dv,1])
            _mb_capsule_influence(newdv,h,r,1/influence, neg)
 : influence==1 ? function(dv)
        let(newdv = transform * [each dv,1])
            _mb_capsule_cutoff(newdv,h,r,cutoff,neg)
 : function (dv)
        let(newdv = transform * [each dv,1])
            _mb_capsule_full(newdv, h, r, cutoff, 1/influence, neg);


/// metaball torus

function _mb_torus_basic(dv, rmaj, rmin, neg) =
    let(dist = norm([norm([dv.x,dv.y])-rmaj, dv.z])) neg*rmin/dist;
function _mb_torus_influence(dv, rmaj, rmin, ex, neg) =
    let(dist = norm([norm([dv.x,dv.y])-rmaj, dv.z])) neg * (rmin/dist)^ex;
function _mb_torus_cutoff(dv, rmaj, rmin, cutoff, neg) =
    let(dist = norm([norm([dv.x,dv.y])-rmaj, dv.z]))
        neg * mb_cutoff(dist, cutoff) * rmin/dist;
function _mb_torus_full(dv, rmaj, rmin, cutoff, ex, neg) =
    let(dist = norm([norm([dv.x,dv.y])-rmaj, dv.z]))
        neg * mb_cutoff(dist, cutoff) * (rmin/dist)^ex;

function mb_torus(r_maj, r_min, cutoff=INF, influence=1, negative=false, d_maj, d_min, or,od,ir,id) =
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
       neg = negative ? -1 : 1
   )
   !is_finite(cutoff) && influence==1 ? function(dv) _mb_torus_basic(dv, r_maj, r_min, neg)
 : !is_finite(cutoff) ? function(dv) _mb_torus_influence(dv, r_maj, r_min, 1/influence, neg)
 : influence==1 ? function(dv) _mb_torus_cutoff(dv, r_maj, r_min, cutoff, neg)
 : function(dv) _mb_torus_full(dv, r_maj, r_min, cutoff, 1/influence, neg);


/// metaball octahedron

function _mb_octahedron_basic(dv, r, neg) =
    let(dist = abs(dv.x) + abs(dv.y) + abs(dv.z)) neg*r/dist;
function _mb_octahedron_influence(dv, r, ex, neg) =
    let(dist = abs(dv.x) + abs(dv.y) + abs(dv.z)) neg * (r/dist)^ex;
function _mb_octahedron_cutoff(dv, r, cutoff, neg) =
    let(dist = abs(dv.x) + abs(dv.y) + abs(dv.z)) neg * mb_cutoff(dist, cutoff) * r/dist;
function _mb_octahedron_full(dv, r, cutoff, ex, neg) =
    let(dist = abs(dv.x) + abs(dv.y) + abs(dv.z)) neg * mb_cutoff(dist, cutoff) * (r/dist)^ex;

function mb_octahedron(r, cutoff=INF, influence=1, negative=false, d) =
   assert(is_num(cutoff) && cutoff>0, "\ncutoff must be a positive number.")
   assert(is_finite(influence) && is_num(influence) && influence>0, "\ninfluence must be a positive number.")
   let(
       r = get_radius(r=r,d=d),
       dummy=assert(is_finite(r) && r>0, "\ninvalid radius or diameter."),
       neg = negative ? -1 : 1
   )
   !is_finite(cutoff) && influence==1 ? function(dv) _mb_octahedron_basic(dv,r,neg)
 : !is_finite(cutoff) ? function(dv) _mb_octahedron_influence(dv,r,1/influence, neg)
 : influence==1 ? function(dv) _mb_octahedron_cutoff(dv,r,cutoff,neg)
 : function(dv) _mb_octahedron_full(dv,r,cutoff,1/influence,neg);


// Function&Module: metaballs()
// Synopsis: Creates a group of 3D metaballs (smoothly connected blobs).
// SynTags: Geom,VNF
// Topics: Metaballs, Isosurfaces, VNF Generators
// See Also: isosurface()
// Usage: As a module
//   metaballs(spec, voxel_size, bounding_box, [isovalue=], [closed=], [convexity=], [show_stats=], ...) [ATTACHMENTS];
// Usage: As a function
//   vnf = metaballs(spec, voxel_size, bounding_box, [isovalue=], [closed=], [convexity=], [show_stats=]);
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
//   metaball functions: `[trans0, func0, trans1, func1, ... ]`. Each transformation matrix
//   you supply can be constructed using the usual transformation commands such as {{up()}},
//   {{right()}}, {{back()}}, {{move()}}, {{scale()}}, {{rot()}} and so on. You can multiply
//   the transformations together, similar to how the transformations can be applied
//   to regular objects in OpenSCAD. For example, to transform an object in regular OpenSCAD you
//   might write `up(5) xrot(25) zrot(45) scale(4)`. You would provide that transformation
//   as the transformation matrix `up(5) * xrot(25) * zrot(45) * scale(4)`. You can use
//   scaling to produce an ellipsoid from a sphere, and you can even use {{skew()}} if desired. 
//   When no transformation is needed, give `IDENT` as the transformation.
//   .
//   The metaballs are evaluated over a bounding box defined by its minimum and maximum corners,
//   `[[xmin,ymin,zmin],[xmax,ymax,zmax]]`. The contributions from **all** metaballs, even those outside
//   the bounds, are evaluated over the bounding box. This bounding box is divided into voxels of the
//   specified `voxel_size`. Smaller voxels produce a finer, smoother result at the expense of
//   execution time. If the voxel size doesn't exactly divide your specified bounding box, then
//   the bounding box is enlarged to contain whole voxels, and centered on your requested box. If
//   the bounding box clips a metaball and `closed=true` (the default), the object is closed at the
//   intersection surface. Setting `closed=false` causes the [VNF](vnf.scad) to end at the bounding box,
//   resulting in a non-manifold shape with holes, exposing the inside of the object.
//   .
//   For metaballs with flat surfaces (the ends of `mb_cyl()`, and `mb_cuboid()` with `squareness=1`),
//   avoid letting any side of the bounding box coincide with one of these flat surfaces, otherwise
//   unpredictable triangulation around the edge may result.
//   .
//   You can create metaballs in a variety of standard shapes using the predefined functions
//   listed below. If you wish, you can also create custom metaball shapes using your own functions
//   (see Example 19). For all of the built-in metaballs, three parameters are availableto control the
//   interaction of the metaballs with each other: `cutoff`, `influence`, and `negative`.
//   .
//   The `cutoff` parameter specifies the distance beyond which the metaball has no interaction
//   with other balls. When you apply `cutoff`, a smooth suppression factor begins
//   decreasing the interaction strength at half the cutoff distance and reduces the interaction to
//   zero at the cutoff. Note that the smooth decrease may cause the interaction to become negligible
//   closer than the actual cutoff distance, depending on the voxel size and `influence` of the
//   ball. Also, depending on the value of `influence`, a cutoff that ends in the middle of
//   another ball can result in strange shapes, as shown in Example 16, with the metaball
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
//   .
//   The `negative` parameter, if set to `true`, creates a negative metaball, which can result in
//   hollows or dents in other metaballs, or swallow other metaballs almost entirely.
//   Negative metaballs are always below the isovalue, so they are never directly visible;
//   only their effects are visible. See Examples 15 and 16.
//   .
//   The `isovalue` parameter in `metaballs()` defaults to 1. If you increase it, then all the objects
//   in your model shrink, causing some melded objects to separate. If you decrease it, each metaball
//   grows and melds more with others. Be aware that changing the isovalue affects **all** the metaballs
//   and changes the entire model, possibly dramatically.
//   .
//   For complicated metaball assemblies you may wish to repeat a structure in different locations or
//   otherwise transformed. Nested metaball specifications are supported:
//   Instead of specifying a transform and function, you specify a transform and then another metaball
//   specification. For example, you could set `finger=[t0,f0,t1,f1,t2,f2]` and then set
//   `hand=[u0,finger,u1,finger,...]` and then invoke `metaballs()` with `[s0, hand]`.
//   In effect, any metaball specification array can be treated as a single metaball in another specification array.
//   This is a powerful technique that lets you make groups of metaballs that you can use as individual
//   metaballs in other groups, and can make your code compact and simpler to understand. See Example 21.
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
//   All of the built-in functions accept these named arguments, which are not repeated in the list below:
//   * `cutoff` &mdash; positive value giving the distance beyond which the metaball does not interact with other balls.  Cutoff is measured from the object's center unless otherwise noted below.  Default: INF
//   * `influence` &mdash; a positive number specifying the strength of interaction this ball has with other balls.  Default: 1
//   * `negative` &mdash; when true, creates a negative metaball. Default: false
//   .
//   The built-in metaball functions are listed below. As usual, arguments without a trailing `=` can be used positionally; arguments with a trailing `=` must be used as named arguments.
//   The examples below illustrates each type of metaball interacting with another of the same type.
//   .
//   * `mb_sphere(r|d=)` &mdash; spherical metaball, with radius r or diameter d.  You can create an ellipsoid using `scale()` as the last transformation entry of the metaball `spec` array. 
//   * `mb_cuboid(size, [squareness=])` &mdash; cuboid metaball with rounded edges and corners. The corner sharpness is controlled by the `squareness` parameter ranging from 0 (spherical) to 1 (cubical), and defaults to 0.5. The `size` specifies the width of the cuboid shape between the face centers; `size` may be a scalar or a vector, as in {{cuboid()}}. Except when `squareness=1`, the faces are always a little bit curved.
//   * `mb_cyl(h|l|height|length, [r|d=], [r1=|d1=], [r2=|d2=], [rounding=])` &mdash; vertical cylinder or cone metaball with the same dimenional arguments as {{cyl()}}. At least one of the radius or diameter arguments is required. The `rounding` argument defaults to 0 (sharp edge) if not specified. Only one rounding value is allowed: the rounding is the same at both ends. For a fully rounded cylindrical shape, consider using `mb_capsule()` or `mb_disk()`, which are less flexible but have faster execution times.  For this metaball, the cutoff is measured from surface of the cone with the specified dimensions.
//   * `mb_disk(h|l|height|length, r|d=)` &mdash; rounded disk with flat ends. The diameter specifies the total diameter of the shape including the rounded sides, and must be greater than its height.
//   * `mb_capsule(h|l|height|length, r|d=)` &mdash; cylinder of radius `r` or diameter `d` with hemispherical caps. The height or length specifies the total height including the rounded ends.
//   * `mb_connector(p1, p2, r|d=)` &mdash; a connecting rod of radius `r` or diameter `d` with hemispherical caps (like `mb_capsule()`), but specified to connect point `p1` to point `p2` (where `p1` and `p2` must be different 3D coordinates). The specified points are at the centers of the two capping hemispheres. You may want to set `influence` quite low; the connectors themselves are still influenced by other metaballs, but it may be undesirable to have them influence others, or each other. If two connectors are connected, the joint may appear swollen unless `influence` is reduced.
//   * `mb_torus([r_maj|d_maj=], [r_min|d_min=], [or=|od=], [ir=|id=])` &mdash; torus metaball oriented perpendicular to the z axis. You can specify the torus dimensions using the same arguments as {{torus()}}; that is, major radius (or diameter) with `r_maj` or `d_maj`, and minor radius and diameter using `r_min` or `d_min`. Alternatively you can give the inner radius or diameter with `ir` or `id` and the outer radius or diameter with `or` or `od`. Both major and minor radius/diameter must be specified regardless of how they are named.
//   *`mb_octahedron(r|d=])` &mdash; octahedral metaball with sharp edges and corners. The `r` parameter specifies the distance from center to tip, while `d=` is the distance between two opposite tips.
//   .
//   ***Metaball functions and user defined functions***
//   .
//   Each metaball is defined as a function of a 3-vector that gives the value of the metaball function
//   for that point in space. As is common in metaball implementations, we define the built-in metaballs using an
//   inverse relationship where the metaball functions fall off as $1/d$, where $d$ is distance from the
//   metaball center. The spherical metaball therefore has a simple basic definition as `f(v) = 1/norm(v)`.
//   With this framework, `f(v) >= c` defines a bounded object. Increasing the isovalue shrinks the
//   object, and decreasing the isovalue grows the object.
//   .
//   To adjust interaction strength, the influence parameter applies an exponent, so if `influence=a`
//   then the decay becomes $\frac{1}{d^{\frac 1 a}}$. This means, for example, that if you set influence to
//   0.5 you get a $\frac{1}{d^2}$ falloff. Changing this exponent changes how the balls interact.
//   .
//   You can pass a custom function as a [function literal](https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/User-Defined_Functions_and_Modules#Function_literals)
//   that takes a single argument (a 3-vector) and returns a single numerical value. 
//   The returned value should define a function where in isovalue range [c,INF] defines a bounded object. See Example 19 for a demonstration of creating a custom metaball function.
//   .
//   ***Voxel size and bounding box***
//   .
//   The `voxel_size` and `bounding_box` parameters affect the run time, which can be long.
//   A voxel size of 1 with a bounding box volume of 200×200×200 may be slow because it requires the
//   calculation and storage of 8,000,000 function values, and more processing and memory to generate
//   the triangulated mesh.  On the other hand, a voxel size of 5 over a 100×100×100 bounding box
//   requires only 8,000 function values and a modest computation time. A good rule is to keep the
//   number of voxels below 10,000 for preview, and adjust the voxel size smaller for final
//   rendering.  A bounding box that is larger than your isosurface wastes time computing function
//   values that are not needed. If the metaballs fit completely within the bounding box, you can
//   call {{pointlist_bounds()}} on `vnf[0]` returned from the `metaballs()` function to get an
//   idea of a the optimal bounding box to use.  You may be able to decrease run time, or keep the
//   same run time but increase the resolution. You can also set the parameter `show_stats=true` to
//   get the bounds of the voxels containing the generated surfaces.
//   .
//   The point list in the returned VNF structure contains many duplicated points. This is not a
//   problem for rendering the shape, but if you want to eliminate these, you can pass
//   the structure to {{vnf_merge_points()}}. Additionally, flat surfaces (often
//   resulting from clipping by the bounding box) are triangulated at the voxel size
//   resolution, and these can be unified into a single face by passing the vnf
//   structure to {{vnf_unify_faces()}}. These steps can be computationally expensive
//   and are not normally necessary.
// Arguments:
//   spec = Metaball specification in the form `[trans0, spec0, trans1, spec1, ...]`, with alternating transformation matrices and metaball specs, where `spec0`, `spec1`, etc. can be a metaball function or another metaball specification. See above for more details, and see Example 21 for a demonstration.
//   voxel_size = scalar size of the voxel cube that is used to sample the bounding box volume. 
//   bounding_box = A pair of 3D points `[[xmin,ymin,zmin], [xmax,ymax,zmax]]`, specifying the minimum and maximum box corner coordinates. The actual bounding box enlarged if necessary to make the voxels fit perfectly, and centered around your requested box.
//   isovalue = A scalar value specifying the isosurface value (threshold value) of the metaballs. At the default value of 1.0, the internal metaball functions are designd so the size arguments correspond to the size parameter (such as radius) of the metaball, when rendered in isolation with no other metaballs. Default: 1.0
//   ---
//   closed = When true, close the surface if it intersects the bounding box by adding a closing face. When false, do not add a closing face, possibly producing a non-manfold VNF that has holes.  Default: true
//   show_stats = If true, display statistics about the metaball isosurface in the console window. Besides the number of voxels found to contain the surface, and the number of triangles making up the surface, this is useful for getting information about a possibly smaller bounding box to improve speed for subsequent renders. Enabling this parameter has a small speed penalty. Default: false
//   convexity = Maximum number of times a line could intersect a wall of the shape. Affects preview only. Default: 6
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
//   spec = [
//       left(10), mb_cyl(15, r1=8, r2=5, rounding=3),
//       right(10), mb_cyl(15, r1=8, r2=5, rounding=3)
//   ];
//   metaballs(spec, voxel_size=0.5,
//       bounding_box=[[-19,-9,-10], [19,9,10]]);
// Example(3D,NoAxes): Two disks interacting.
//   metaballs([
//       move([-10,0,2]), mb_disk(5,9),
//       move([10,0,-2]), mb_disk(5,9)
//       ], 0.5, [[-20,-10,-6], [20,10,6]]);
// Example(3D,NoAxes): Two capsules interacting.
//   metaballs([
//       move([-8,0,4])*yrot(90), mb_capsule(16,3),
//       move([8,0,-4])*yrot(90), mb_capsule(16,3)
//       ], 0.5, [[-17,-5,-8], [17,5,8]]);
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
//    voxelsize = 0.5;
//    boundingbox = [[-19,-9,9], [18,10,32]];
//    metaballs(spec, voxelsize, boundingbox);
// Example(3D,NoAxes,VPR=[75,0,20]): Two octahedrons interacting.
//   metaballs([
//       move([-10,0,3]), mb_octahedron(8),
//       move([10,0,-3]), mb_octahedron(8)
//       ], 0.5, [[-21,-11,-13], [21,11,13]]);
// Example(3D,VPD=110): These next five examples demonstrate the different types of metaball interactions. We start with two spheres 30 units apart. Each would have a radius of 10 in isolation, but because they are influencing their surroundings, each sphere mutually contributes to the size of the other. The sum of contributions between the spheres add up so that a surface plotted around the region exceeding the threshold defined by `isovalue=1` looks like a peanut shape surrounding the two spheres.
//   spec = [
//       left(15),  mb_sphere(10),
//       right(15), mb_sphere(10)
//   ];
//   voxelsize = 1;
//   boundingbox = [[-30,-19,-19], [30,19,19]];
//   metaballs(spec, voxelsize, boundingbox);
// Example(3D,VPD=110): Adding a cutoff of 25 to the left sphere causes its influence to disappear completely 25 units away (which is the center of the right sphere). The left sphere is bigger because it still receives the full influence of the right sphere, but the right sphere is smaller because the left sphere has no contribution past 25 units. The right sphere is not abruptly cut off because the cutoff function is smooth and influence is normal. Setting cutoff too small can remove the interactions of one metaball from all other metaballs, leaving that metaball alone by itself.
//   spec = [
//       left(15),  mb_sphere(10, cutoff=25),
//       right(15), mb_sphere(10)
//   ];
//   voxelsize = 1;
//   boundingbox = [[-30,-19,-19], [30,19,19]];
//   metaballs(spec, voxelsize, boundingbox);
// Example(3D,VPD=110): Here, the left sphere has less influence in addition to a cutoff. Setting `influence=0.5` results in a steeper falloff of contribution from the left sphere. Each sphere has a different size and shape due to unequal contributions based on distance.
//   spec = [
//       left(15),  mb_sphere(10, influence=0.5, cutoff=25),
//       right(15), mb_sphere(10)
//   ];
//   voxelsize = 1;
//   boundingbox = [[-30,-19,-19], [30,19,19]];
//   metaballs(spec, voxelsize, boundingbox);
// Example(3D,VPD=110): In this example, we have two size-10 spheres as before and one tiny sphere of 1.5 units radius offset a bit on the y axis. With an isovalue of 1, this figure would appear similar to Example 9 above, but here the isovalue has been set to 2, causing the surface to shrink around a smaller volume values greater than 2. Remember, higher isovalue thresholds cause metaballs to shrink.
//   spec = [
//      left(15),  mb_sphere(10),
//      right(15), mb_sphere(10),
//      fwd(15),   mb_sphere(1.5)
//   ];
//   voxelsize = 1;
//   boundingbox = [[-30,-19,-19], [30,19,19]];
//   metaballs(spec, voxelsize, boundingbox,
//       isovalue=2);
// Example(3D,VPD=110): Keeping `isovalue=2`, the influence of the tiny sphere has been set quite high, to 10. Notice that the tiny sphere shrinks a bit, but it has dramatically increased its contribution to its surroundings, causing the two other spheres to grow and meld into each other. The `influence` argument on a small metaball affects its surroundings more than itself.
//   spec = [
//      move([-15,0,0]), mb_sphere(10),
//      move([15,0,0]),  mb_sphere(10),
//      move([0,-15,0]), mb_sphere(1.5, influence=10)
//   ];
//   voxelsize = 1;
//   boundingbox = [[-30,-19,-19], [30,19,19]];
//   metaballs(spec, voxelsize, boundingbox,
//       isovalue=2);
// Example(3D,NoAxes): A group of five spherical metaballs with different sizes. The parameter `show_stats=true` (not shown here) was used to find a compact bounding box for this figure.
//   spec = [ // spheres of different sizes
//       move([-20,-20,-20]), mb_sphere(5),
//       move([0,-20,-20]),   mb_sphere(4),
//       IDENT,               mb_sphere(3),
//       move([0,0,20]),      mb_sphere(5),
//       move([20,20,10]),    mb_sphere(7)
//   ];
//   voxelsize = 1.5;
//   boundingbox = [[-30,-31,-31], [32,31,31]];
//   metaballs(spec, voxelsize, boundingbox);
// Example(3D,NoAxes): A metaball can be negative. In this case we have two metaballs in close proximity, with the small negative metaball creating a dent in the large positive one. The positive metaball is shown transparent, and small spheres show the center of each metaball. The negative metaball isn't visible because its field is negative; the isosurface encloses only field values greater than the isovalue of 1.
//   centers = [[-1,0,0], [1.25,0,0]];
//   spec = [
//       move(centers[0]), mb_sphere(8),
//       move(centers[1]), mb_sphere(3, negative=true)
//   ];
//   voxelsize = 0.25;
//   isovalue = 1;
//   boundingbox = [[-7,-6,-6], [3,6,6]];
//   #metaballs(spec, voxelsize, boundingbox, isovalue);
//   color("green") move_copies(centers) sphere(d=1, $fn=16);
// Example(3D,VPD=105,VPT=[3,5,4.7]): When a positive and negative metaball interact, the negative metaball reduces the influence of the positive one, causing it to shrink, but not disappear because its contribution approaches infinity at its center. In this example we have a large positive metaball near a small negative metaball at the origin. The negative ball as high influence, and a cutoff limiting its influence to 20 units. The negative metaball influences the positive one up to the cutoff, causing the positive metaball to appear smaller inside the cutoff range, and appear its normal size outside the cutoff range. The positive metaball has a small dimple at the origin (the center of the negative metaball) because it cannot overcome the infinite negative contribution of the negative metaball at the origin.
//   spec = [
//       back(10), mb_sphere(20),
//       IDENT, mb_sphere(2, influence=30,
//                        cutoff=20, negative=true),
//   ];
//   voxelsize = 0.5;
//   boundingbox = [[-20,-4,-20], [20,30,20]];
//   metaballs(spec, voxelsize, boundingbox);
// Example(3D,NoAxes): A cube, a rounded cube, and an octahedron interacting. Because the surface is generated through cubical voxels, voxel corners are always cut off, resulting in difficulty resolving some sharp edges.
//   spec = [
//       move([-7,-3,27])*zrot(55), mb_cuboid(6, squareness=1),
//       move([5,5,21]),   mb_cuboid(5),
//       move([10,0,10]),  mb_octahedron(5)
//   ];
//   voxelsize = 0.5; // a bit slow at this resolution
//   boundingbox = [[-12,-9,3], [18,10,32]];
//   metaballs(spec, voxelsize, boundingbox);
// Example(3D,NoAxes,VPD=205,Med): A toy airplane, constructed only from metaball spheres with scaling. The bounding box is used to clip the wingtips, tail, and belly of the fuselage.
//   bounding_box = [[-55,-50,-5],[35,50,17]];
//   spec = [
//       move([-20,0,0])*scale([25,4,4]),   mb_sphere(1), // fuselage
//       move([30,0,5])*scale([4,0.5,8]),   mb_sphere(1), // vertical stabilizer
//       move([30,0,0])*scale([4,15,0.5]),  mb_sphere(1), // horizontal stabilizer
//       move([-15,0,0])*scale([6,45,0.5]), mb_sphere(1)  // wing
//   ];
//   voxel_size = 1;
//   metaballs(spec, voxel_size, bounding_box);
// Example(3D): Demonstration of a custom metaball function, in this case a sphere with some random noise added to its value. The `dv` argument must be first; it is calculated internally as a distance vector from the metaball center to a probe point inside the bounding box, and you convert it to a scalar distance `dist` that is calculated inside your function (`dist` could be a more complicated expression, depending on the shape of the metaball). The call to `mb_cutoff()` at the end handles the cutoff function for the noisy ball consistent with the other internal metaball functions; it requires `dist` and `cutoff` as arguments. You are not required to include the `cutoff` and `influence` arguments in a custom function, but this example shows how.
//   function noisy_sphere(dv, r, noise_level, cutoff=INF, influence=1) =
//       let(
//           noise = rands(0, noise_level, 1)[0],
//           dist = norm(dv) + noise
//       ) mb_cutoff(dist,cutoff) * (r/dist)^(1/influence);
//      
//   spec = [
//       left(9),  mb_sphere(5),
//       right(9), function (dv) noisy_sphere(dv, 5, 0.2),
//   ];
//   voxelsize = 0.5;
//   boundingbox = [[-16,-8,-8], [16,8,8]];
//   metaballs(spec, voxelsize, boundingbox);
// Example(3D,Med,NoAxes,VPR=[55,0,0],VPD=200,VPT=[7,2,2]): A complex example using ellipsoids, a capsule, spheres, and a torus to make a tetrahedral object with rounded feet and a ring on top. The bottoms of the feet are flattened by clipping with the bottom of the bounding box. The center of the object is thick due to the contributions of three ellipsoids and a capsule converging. Designing an object like this using metaballs requires trial and error with low-resolution renders.
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
//   voxelsize = 1;
//   boundingbox = [[-22,-32,-13], [36,32,46]];
//   // useful to save as VNF for copies and manipulations
//   vnf = metaballs(spec, voxelsize, boundingbox, isovalue=1);
//   vnf_polyhedron(vnf);
// Example(3D,Med,NoAxes,VPR=[70,0,30],VPD=520,VPT=[0,0,80]): This example demonstrates grouping metaballs together and nesting them in lists of other metaballs, to make a crude model of a hand. Here, just one finger is defined, and a thumb is defined from one less joint in the finger. Individual fingers are grouped together with different positions and scaling, along with the thumb. Finally, this group of all fingers is used to combine with a rounded cuboid, with a slight ellipsoid dent subtracted to hollow out the palm, to make the hand.
//   joints = [[0,0,1], [0,0,85], [0,-5,125], [0,-16,157], [0,-30,178]];
//   finger = [
//       for(i=[0:3]) each
//           [IDENT, mb_connector(joints[i], joints[i+1], 9+i/5, influence=0.22)]
//   ];
//   thumb = [
//       for(i=[0:2]) each [
//           scale([1,1,1.2]),
//           mb_connector(joints[i], joints[i+1], 9+i/2, influence=.28)
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
//   voxsize=2.5;
//   bbox = [[-104,-40,-10], [79,18,188]];
//   metaballs(hand, voxsize, bbox, isovalue=1);

module metaballs(spec, voxel_size, bounding_box, isovalue=1, closed=true, convexity=6, cp="centroid", anchor="origin", spin=0, orient=UP, atype="hull", show_stats=false) {
        vnf = metaballs(spec, voxel_size, bounding_box, isovalue, closed, show_stats);
        vnf_polyhedron(vnf, convexity=convexity, cp=cp, anchor=anchor, spin=spin, orient=orient, atype=atype)
            children();
}

function metaballs(spec, voxel_size, bounding_box, isovalue=1, closed=true, show_stats=false) =
    assert(all_defined([spec, isovalue, bounding_box, voxel_size]), "\nThe parameters spec, isovalue, bounding_box, and voxel_size must all be defined.")
    assert(len(spec)%2==0, "\nThe spec parameter must be an even-length list of alternating transforms and functions")
    let(
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

        // new bounding box centered around original, forced to integer multiples of voxel size
        halfvox = 0.5*voxel_size,
        bbcenter = mean(bounding_box),
        bbnums = v_ceil((bounding_box[1]-bounding_box[0]) / voxel_size),
        newbbox = [bbcenter - halfvox*bbnums, bbcenter + halfvox*bbnums],

        // set up field array
        bot = newbbox[0],
        top = newbbox[1],
        // accumulate metaball contributions using matrices rather than sums
        xset = [bot.x:voxel_size:top.x+halfvox],
        yset = list([bot.y:voxel_size:top.y+halfvox]),
        zset = list([bot.z:voxel_size:top.z+halfvox]),
        allpts = [for(x=xset, y=yset, z=zset) [x,y,z,1]],
        trans_pts = [for(i=[0:nballs-1]) allpts*transmatrix[i]],
        allvals = [for(i=[0:nballs-1]) [for(pt=trans_pts[i]) funclist[2*i+1](pt)]],
        //total = _sum(allvals,allvals[0]*EPSILON),
        total = _sum(slice(allvals,1,-1), allvals[0]),
        fieldarray = list_to_matrix(list_to_matrix(total,len(zset)),len(yset))
    ) isosurface(fieldarray, isovalue, voxel_size, closed=closed, show_stats=show_stats, _mb_origin=newbbox[0]);


function _mb_unwind_list(list, parent_trans=[IDENT]) =
    let(
        dum1 = assert(is_list(list), "\nDid not find valid list of metaballs."),
        n=len(list),
        dum2 = assert(n%2==0, "\nList of metaballs must have an even number of elements with alternating transforms and functions/lists.")
    ) [
        for(i=[0:2:n-1])
            let(
                dum = assert(is_matrix(list[i],4,4), str("\nInvalid 4×4 transformation matrix found at position ",i,".")),
                trans = parent_trans[0] * list[i],
                j=i+1
            )   if(is_function(list[j]))
                    each [trans, list[j]]
                else if (is_list(list[j]))
                    each _mb_unwind_list(list[j], [trans])
                else                 
                    assert(false, str("\nExpected function literal or list at position ",j,"."))
    ];



/// ---------- isosurface stuff starts here ----------

// Function&Module: isosurface()
// Synopsis: Creates a 3D isosurface (a 3D contour) from a function or array of values.
// SynTags: Geom,VNF
// Topics: Isosurfaces, VNF Generators
// Usage: As a module
//   isosurface(f, isovalue, voxel_size, bounding_box, [reverse=], [closed=], [show_stats=], ...) [ATTACHMENTS];
// Usage: As a function
//   vnf = isosurface(f, isovalue, voxel_size, bounding_box, [reverse=], [closed=], [show_stats=]);
// Description:
//   Computes a [VNF structure](vnf.scad) of a 3D isosurface within a bounded box at a single
//   isovalue or range of isovalues.
//   The isosurface of a function $f(x,y,z)$ is the set of points where $f(x,y,z)=c$ for some
//   constant isovalue, $c$.
//   To provide a function you supply a [function literal](https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/User-Defined_Functions_and_Modules#Function_literals)
//   taking three parameters as input to define the grid coordinate location (e.g. `x,y,z`) and
//   returning a single numerical value.
//   You can also define an isosurface using a 3D array of values instead of a function, in which
//   case the isosurface is the set of points equal to the isovalue as interpolated from the array.
//   The array indices are in the order `[x][y][z]`.
//   .
//   The VNF that is computed has the isosurface as its bounding surface, with all the points where
//   $f(x,y,z)>c$ on the interior side of the surface.
//   When the isovalue is a range, `[c1, c2]`, then the resulting VNF has two bounding surfaces
//   corresponding to `c1` and `c2`, and the interior of the object are the points with intermediate
//   isovalues; this generally produces a shell object that has an inside and outside surface. The
//   range can start at `-INF` or end at `INF`. A single isovalue `c` is equivalent to `[c,INF]`.
//   .
//   The isosurface is evaluated over a bounding box defined by its minimum and maximum corners,
//   `[[xmin,ymin,zmin],[xmax,ymax,zmax]]`. This bounding box is divided into voxels of the
//   specified `voxel_size`. Smaller voxels produce a finer, smoother result at the expense of
//   execution time.  If the voxel size doesn't exactly divide your specified bounding box, then
//   the bounding box is enlarged to contain whole voxels, and centered on your requested box. If
//   the bounding box clips the isosurface and `closed=true` (the default), a surface is added to create
//   a closed manifold object. Setting `closed=false` causes the VNF to end at the bounding box,
//   resulting in a non-manifold shape that exposes the inside of the object.
//   .
//   The `voxel_size` and `bounding_box` parameters affect the run time, which can be long.
//   A voxel size of 1 with a bounding box volume of 200×200×200 may be slow because it requires the
//   calculation and storage of 8,000,000 function values, and more processing and memory to generate
//   the triangulated mesh.  On the other hand, a voxel size of 5 over a 100×100×100 bounding box
//   requires only 8,000 function values and a modest computation time. A good rule is to keep the
//   number of voxels below 10,000 for preview, and adjust the voxel size smaller for final
//   rendering. A bounding box that is larger than your isosurface wastes time computing function
//   values that are not needed. If the isosurface fits completely within the bounding box, you can
//   call {{pointlist_bounds()}} on `vnf[0]` returned from the `isosurface()` function to get an
//   idea of a the optimal bounding box to use. You may be able to decrease run time, or keep the
//   same run time but increase the resolution. You can also set the parameter `show_stats=true` to
//   get the bounds of the voxels containing the surface.
//   .
//   The point list in the VNF structure contains many duplicated points. This is not a
//   problem for rendering the shape, but if you want to eliminate these, you can pass
//   the structure to {{vnf_merge_points()}}. Additionally, flat surfaces (often
//   resulting from clipping by the bounding box) are triangulated at the voxel size
//   resolution, and these can be unified into a single face by passing the vnf
//   structure to {{vnf_unify_faces()}}. These steps can be computationally expensive
//   and are not normally necessary.
// Arguments:
//   f = The isosurface function or array.
//   isovalue = a scalar giving the isovalue parameter or a 2-vector giving an isovalue range.
//   voxel_size = scalar size of the voxel cube that is used to sample the surface. 
//   bounding_box = When `f` is a function, a pair of 3D points `[[xmin,ymin,zmin], [xmax,ymax,zmax]]`, specifying the minimum and maximum corner coordinates of the bounding box.  The actual bounding box enlarged if necessary to make the voxels fit perfectly, and centered around your requested box. When `f` is an array of values, `bounding_box` is already implied by the array size combined with `voxel_size`, in which case this implied bounding box is centered around the origin.
//   ---
//   closed = When true, close the surface if it intersects the bounding box by adding a closing face. When false, do not add a closing face and instead produce a non-manfold VNF that has holes.  Default: true
//   reverse = When true, reverses the orientation of the VNF faces. Default: false
//   show_stats = If true, display statistics in the console window about the isosurface: number of voxels that contain the surface, number of triangles, bounding box of the voxels, and voxel-rounded bounding box of the surface, which may help you reduce your bounding box to improve speed. Enabling this parameter has a slight speed penalty. Default: false
//   convexity = Maximum number of times a line could intersect a wall of the shape. Affects preview only. Default: 6
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
// Example(3D,ThrownTogether,NoAxes): A gyroid is an isosurface defined by all the zero values of a 3D periodic function. To illustrate what the surface looks like, `closed=false` has been set to expose both sides of the surface. The surface is periodic and tileable along all three axis directions. This a non-manifold surface as displayed, not useful for 3D modeling. This example also demonstrates using an additional parameter in the field function beyond just x,y,z; in this case controls the wavelength of the gyroid.
//   function gyroid(x,y,z, wavelength) = let(
//       p = 360/wavelength,
//       px = p*x, py = p*y, pz = p*z
//   ) sin(px)*cos(py) + sin(py)*cos(pz) + sin(pz)*cos(px);
//   isovalue = 0;
//   bbox = [[-100,-100,-100], [100,100,100]];
//   isosurface(function (x,y,z) gyroid(x,y,z, wavelength=200),
//       isovalue, voxel_size=5, bounding_box=bbox,
//       closed=false);
// Example(3D,NoAxes): If we remove the `closed` parameter or set it to true, the isosurface algorithm encloses the entire half-space bounded by the "inner" gyroid surface, leaving only the "outer" surface exposed. This is a manifold shape but not what we want if trying to model a gyroid.
//   function gyroid(x,y,z, wavelength) = let(
//       p = 360/wavelength,
//       px = p*x, py = p*y, pz = p*z
//   ) sin(px)*cos(py) + sin(py)*cos(pz) + sin(pz)*cos(px);
//   isovalue = 0;
//   bbox = [[-100,-100,-100], [100,100,100]];
//   isosurface(function (x,y,z) gyroid(x,y,z, wavelength=200),
//       isovalue, voxel_size=5, bounding_box=bbox);
// Example(3D,ThrownTogether,NoAxes): To make the gyroid a double-sided surface, we need to specify a small range around zero for `isovalue`. Now we have a double-sided surface although with `closed=false` the edges are not closed where the surface is clipped by the bounding box.
//   function gyroid(x,y,z, wavelength) = let(
//       p = 360/wavelength,
//       px = p*x, py = p*y, pz = p*z
//   ) sin(px)*cos(py) + sin(py)*cos(pz) + sin(pz)*cos(px);
//   isovalue = [-0.3, 0.3];
//   bbox = [[-100,-100,-100], [100,100,100]];
//   isosurface(function (x,y,z) gyroid(x,y,z, wavelength=200),
//       isovalue, voxel_size=5, bounding_box=bbox,
//       closed = false);
// Example(3D,ThrownTogether,NoAxes): To make the gyroid a valid manifold 3D object, we remove the `closed` parameter (same as setting `closed=true`), which closes the edges where the surface is clipped by the bounding box. The resulting object can be tiled, the VNF returned by the functional version can be wrapped around an axis using {{vnf_bend()}}, and other operations.
//   function gyroid(x,y,z, wavelength) = let(
//       p = 360/wavelength,
//       px = p*x, py = p*y, pz = p*z
//   ) sin(px)*cos(py) + sin(py)*cos(pz) + sin(pz)*cos(px);
//   isovalue = [-0.3, 0.3];
//   bbox = [[-100,-100,-100], [100,100,100]];
//   isosurface(function (x,y,z) gyroid(x,y,z, wavelength=200),
//       isovalue, voxel_size=5, bounding_box=bbox); 
// Example(3D,NoAxes): An approximation of the triply-periodic minimal surface known as [Schwartz P](https://en.wikipedia.org/wiki/Schwarz_minimal_surface).
//   function schwartz_p(x,y,z, wavelength) = let(
//       p = 360/wavelength,
//       px = p*x, py = p*y, pz = p*z
//   )  cos(px) + cos(py) + cos(pz);
//   isovalue = [-0.2, 0.2];
//   bbox = [[-100,-100,-100], [100,100,100]];
//   isosurface(function (x,y,z) schwartz_p(x,y,z, 100),
//       isovalue, voxel_size=4, bounding_box=bbox);
// Example(3D,NoAxes): Another approximation of the triply-periodic minimal surface known as [Neovius](https://en.wikipedia.org/wiki/Neovius_surface).
//   function neovius(x,y,z, wavelength) = let(
//       p = 360/wavelength,
//       px = p*x, py = p*y, pz = p*z
//   )  3*(cos(px) + cos(py) + cos(pz)) + 4*cos(px)*cos(py)*cos(pz);
//    isovalue = [-0.3, 0.3];
//   bbox = [[-100,-100,-100], [100,100,100]];
//   isosurface(function (x,y,z) neovius(x,y,z,200),
//       isovalue, voxel_size=4, bounding_box=bbox);
// Example(3D): Using an array for the `f` argument instead of a function literal.
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
//      isosurface(field, isovalue=0.5,
//          voxel_size=10);

module isosurface(f, isovalue, voxel_size, bounding_box, reverse=false, closed=true, convexity=6, cp="centroid", anchor="origin", spin=0, orient=UP, atype="hull", show_stats=false, _mb_origin=undef) {
    vnf = isosurface(f, isovalue, voxel_size, bounding_box, reverse, closed, show_stats, _mb_origin);
    vnf_polyhedron(vnf, convexity=convexity, cp=cp, anchor=anchor, spin=spin, orient=orient, atype=atype)
        children();
}

function isosurface(f, isovalue, voxel_size, bounding_box, reverse=false, closed=true, show_stats=false, _mb_origin=undef) =
    assert(all_defined([f, isovalue, voxel_size]), "\nThe parameters f, isovalue, and bounding_box must all be defined.")
    assert((is_function(f) && is_def(bounding_box)) || (is_list(f) && is_undef(bounding_box)),
        "\nbounding_box must be passed if f is a function, and cannot be passed if f is an array.")
    let(
        isovalmin = is_list(isovalue) ? isovalue[0] : isovalue,
        isovalmax = is_list(isovalue) ? isovalue[1] : INF,
        dum1 = assert(isovalmin < isovalmax, str("\nBad isovalue range (", isovalmin, ", >= ", isovalmax, "), should be expressed as [min_value, max_value].")),
        hv = 0.5*voxel_size,
        bbox = is_function(f)
        ? let( // new bounding box quantized for voxel_size, centered around original box
            bbcenter = mean(bounding_box),
            bbn = v_ceil((bounding_box[1]-bounding_box[0]) / voxel_size)
        ) [bbcenter - hv*bbn, bbcenter + hv*bbn]
        : let( // new bounding box, either centered on origin or using metaball origin
            dims = list_shape(f) - [1,1,1]
        ) is_def(_mb_origin)
            ? [_mb_origin, _mb_origin+voxel_size*dims] // metaball bounding box
            : [-hv*dims, hv*dims],  // centered bounding box
        cubes = _isosurface_cubes(voxel_size, bbox,
            fieldarray=is_function(f)?undef:f, fieldfunc=is_function(f)?f:undef,
            isovalmin=isovalmin, isovalmax=isovalmax, closed=closed),
        tritablemin = reverse ? _MCTriangleTable_reverse : _MCTriangleTable,
        tritablemax = reverse ? _MCTriangleTable : _MCTriangleTable_reverse,
        trianglepoints = _isosurface_triangles(cubes, voxel_size, isovalmin, isovalmax, tritablemin, tritablemax),
        faces = [ for(i=[0:3:len(trianglepoints)-1]) [i,i+1,i+2] ],
        dum2 = show_stats ? _showstats(voxel_size, bbox, isovalmin, cubes, faces) : 0
) [trianglepoints, faces];
