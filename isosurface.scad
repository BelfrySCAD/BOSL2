/////////////////////////////////////////////////////////////////////
// LibFile: isosurface.scad
//   An isosurface is a three-dimensional surface representing points of a constant
//   value (e.g. pressure, temperature, electric potential, density) in a
//   3D volume. It's the 3D version of a 2D contour; in fact, any 2D cross-section of an
//   isosurface *is* a 2D contour.
//   .
//   For computer-aided design, isosurfaces of abstract functions can generate complex
//   curved surfaces and organic-looking shapes.
//   An isosurface may be represented generally by any function of three variables,
//   that is, the isosurface of a function $f(x,y,z)$ is the set of points where
//   $f(x,y,z)=c$ for some constant value $c$. The constant $c$ is referred to as the "isovalue". 
//   .
//   A [gryoid](https://en.wikipedia.org/wiki/Gyroid) (often used as a volume infill pattern in [fused filament fabrication](https://en.wikipedia.org/wiki/Fused_filament_fabrication))
//   is an exmaple of an isosurface that is unbounded and periodic in all three dimensions.
//   Other typical examples in 3D graphics are [metaballs](https://en.wikipedia.org/wiki/Metaballs) (also known as "blobby objects"),
//   which are bounded and closed organic-looking surfaces that smoothly meld together when in close proximity.
//   .
//   Below are modules and functions to create 3D models of isosurfaces as well as metaballs of various shapes.
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

For example, 10000110 (8-bit binary for decimal index 134) has corners 2, 3, and 7 greater than the threshold. After determining the cube's index value, the triangulation order is looked up in a table.

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
Addition by Alex Matulich:
Vertex and face layout for triangulating one voxel face that corrsesponds to a side of the box bounding all voxels.

                    4(back)
               3 +----------+ 7
                /:  5(top) /|
               / :        / |
            1 +==========+5 |    <-- 3 (side)
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
/// End of bounding-box faace-clipping stuff. Back to the marching cubes triangulation....


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
    [2, 6],
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
 [],
];

/// Same list as above, but with each row in reverse order. Needed for generating shells (two isosurfaces at slightly different iso values).
/// More efficient just to have a static table than to generate it each time by calling reverse() hundreds of times (although this static table was generated that way).
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


// Function&Module: isosurface()
// Synopsis: Creates a 3D isosurface.
// SynTags: Geom,VNF
// Topics: Isosurfaces, VNF Generators
// Usage: As a module
//   isosurface(f, isovalue, bounding_box, voxel_size, [reverse=], [closed=], [show_stats=]);
// Usage: As a function
//   vnf = isosurface(f, isovalue, bounding_box, voxel_size, [closed=], [show_stats=]);
// Description:
//   When called as a function, returns a [VNF structure](vnf.scad) (list of triangles and faces) representing a 3D isosurface within the specified bounding box at a single isovalue or range of isovalues.
//   When called as a module, displays the isosurface within the specified bounding box at a single isovalue or range of isovalues. This module just passes the parameters to the function, and then calls {{vnf_polyhedron()}} to display the isosurface.
//   .
//   A [marching cubes](https://en.wikipedia.org/wiki/Marching_cubes) algorithm is used
//   to identify an envelope containing the isosurface within the bounding box. The surface
//   intersecttion with a voxel cube is then triangulated to form a surface fragment, which is
//   combined with all other surface fragments. Ambiguities in triangulating the surfaces
//   in certain voxel cube configurations are resolved so that all triangular facets are
//   properly oriented with no holes in the surface. If a side of the bounding box clips
//   the isosurface, this clipped area is filled in so that the surface remains manifold.
//   .
//   Be mindful of how you set `voxel_size` and `bounding_box`. For example a voxel size
//   of 1 unit with a bounding box volume of 200×200×200 may be noticeably slow,
//   requiring calculation and storage of 8,000,000 field values, and more processing
//   and memory to generate the triangulated mesh. On the other hand, a voxel size of 5
//   in a 100×100×100 bounding box requires only 8,000 field values and the mesh
//   generates fairly quickly, just a handful of seconds. A good rule is to keep the
//   number of field values below 10,000 for preview, and adjust the voxel size
//   smaller for final rendering. If the isosurface fits completely within the bounding
//   box, you can call {{pointlist_bounds()}} on `vnf[0]` returned from the
//   `isosurface()` function to get an idea of a more optimal smaller bounding box to use,
//   possibly allowing increasing resolution by decresing the voxel size. You can also set
//   the parameter `show_stats=true` to get the bounds of the voxels containing the surface.
//   .
//   The point list in the VNF structure contains many duplicated points. This is not a
//   problem for rendering the shape, but if you want to eliminate these, you can pass
//   the structure to {{vnf_merge_points()}}. Additionally, flat surfaces (often
//   resulting from clipping by the bounding box) are triangulated at the voxel size
//   resolution, and these can be unified into a single face by passing the vnf
//   structure to {{vnf_unify_faces()}}. These steps can be expensive for execution time
//   and are not normally necessary.
// Arguments:
//   f = A [function literal](https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/User-Defined_Functions_and_Modules#Function_literals) taking as input `x,y,z` coordinates and optional additional parameters, and returns a single value. Say you have you created your own function, `my_func(x,y,z,a,b,c)` (call it whatever you want), which depends on x, y, z, and additional parameters a, b, c, and returns a single value. In the parameter list to `isosurface()`, you would set the `f` parameter to `function (x,y,z) my_func(x,y,z,a,b,c)`.
//   isovalue = As a scalar, specifies the output value of `field_function` corresponding to the isosurface. As a vector `[min_isovalue, max_isovalue]`, specifies the range of isovalues around which to generate a surface. For closed surfaces, a single value results in a closed volume, and a range results in a shell (with an inside and outside surface) enclosing a volume. A range must be specified for infinite-extent surfaces (such as gyroids) to create a manifold shape within the bounding box. 
//   bounding_box = A pair of 3D points `[[xmin,ymin,zmin], [xmax,ymax,zmax]]`, specifying the minimum and maximum corner coordinates of the bounding box. You don't have ensure that the voxels fit perfectly inside the bounding box. While the voxel at the minimum bounding box corner is aligned on that corner, the last voxel at the maximum box corner may extend a bit beyond it.
//   voxel_size = The size (scalar) of the voxel cube that determines the resolution of the surface.
//   ---
//   reverse = When true, reverses the orientation of the facets in the mesh. Default: false
//   closed = When true, maintains a manifold surface where the bounding box clips it (there is a negligible speed penalty in doing this). When false, the bounding box clips the surface, exposing the back sides of facets. Setting this to false can be useful with OpenSCAD's "View > Thrown Together" menu option to distinguish inside from outside. Default: true
//   show_stats = If true, display statistics about the isosurface in the console window. Besides the number of voxels found to contain the surface, and the number of triangles making up the surface, this is useful for getting information about a smaller bounding box possible for the isosurface, to improve speed for subsequent renders. Enabling this parameter has a speed penalty. Default: false
// Example(3D,ThrownTogether,NoAxes): A gyroid is an isosurface defined by all the zero values of a 3D periodic function. To illustrate what the surface looks like, `closed=false` has been set to expose both sides of the surface. The surface is periodic and tileable along all three axis directions. This a non-manifold surface as displayed, not useful for 3D modeling. This example also demonstrates using an additional parameters in the field function beyond just x,y,z; in this case controls the wavelength of the gyroid.
//   function gyroid(x,y,z, wavelength) = let(
//       p = 360/wavelength,
//       px = p*x, py = p*y, pz = p*z
//   ) sin(px)*cos(py) + sin(py)*cos(pz) + sin(pz)*cos(px);
//   
//   bbox = [[-100,-100,-100], [100,100,100]];
//   isosurface(function (x,y,z) gyroid(x,y,z, wavelength=200),
//       isovalue=0, bounding_box=bbox, voxel_size=5,
//       closed=false);
// Example(3D,NoAxes): If we remove the `closed` parameter or set it to true, the isosurface algorithm encloses the entire half-space bounded by the "inner" gyroid surface, leaving only the "outer" surface exposed. This is a manifold shape but not what we want if trying to model a gyroid.
//   function gyroid(x,y,z, wavelength) = let(
//       p = 360/wavelength,
//       px = p*x, py = p*y, pz = p*z
//   ) sin(px)*cos(py) + sin(py)*cos(pz) + sin(pz)*cos(px);
//   
//   bbox = [[-100,-100,-100], [100,100,100]];
//   isosurface(function (x,y,z) gyroid(x,y,z, wavelength=200),
//       isovalue=0, bounding_box=bbox, voxel_size=5);
// Example(3D,ThrownTogether,NoAxes): To make the gyroid a double-sided surface, we need to specify a small range around zero for `isovalue`. Now we have a double-sided surface although with `closed=false` the edges are not closed where the surface is clipped by the bounding box.
//   function gyroid(x,y,z, wavelength) = let(
//       p = 360/wavelength,
//       px = p*x, py = p*y, pz = p*z
//   ) sin(px)*cos(py) + sin(py)*cos(pz) + sin(pz)*cos(px);
//   
//   bbox = [[-100,-100,-100], [100,100,100]];
//   isosurface(function (x,y,z) gyroid(x,y,z, wavelength=200),
//       isovalue=[-0.3, 0.3], bounding_box=bbox, voxel_size=5, 
//       closed = false);
// Example(3D,ThrownTogether,NoAxes): To make the gyroid a valid manifold 3D object, we remove the `closed` parameter (same as setting `closed=true`), which closes the edges where the surface is clipped by the bounding box. The resulting object can be tiled, the VNF returned by the functional version can be wrapped around an axis using {{vnf_bend()}}, and other operations.
//   function gyroid(x,y,z, wavelength) = let(
//       p = 360/wavelength,
//       px = p*x, py = p*y, pz = p*z
//   ) sin(px)*cos(py) + sin(py)*cos(pz) + sin(pz)*cos(px);
//   
//   bbox = [[-100,-100,-100], [100,100,100]];
//   isosurface(function (x,y,z) gyroid(x,y,z, wavelength=200),
//       isovalue=[-0.3, 0.3], bounding_box=bbox, voxel_size=5); 
// Example(3D,NoAxes): An approximation of the triply-periodic minimal surface known as [Schwartz P](https://en.wikipedia.org/wiki/Schwarz_minimal_surface).
//   function schwartz_p(x,y,z, wavelength) = let(
//       p = 360/wavelength,
//       px = p*x, py = p*y, pz = p*z
//   )  cos(px) + cos(py) + cos(pz);
//   
//   bbox = [[-100,-100,-100], [100,100,100]];
//   isosurface(function (x,y,z) schwartz_p(x,y,z, 100),
//       isovalue=[-0.2,0.2], bounding_box=bbox, voxel_size=4);
// Example(3D,NoAxes): Another approximation of the triply-periodic minimal surface known as [Neovius](https://en.wikipedia.org/wiki/Neovius_surface).
//   function neovius(x,y,z, wavelength) = let(
//       p = 360/wavelength,
//       px = p*x, py = p*y, pz = p*z
//   )  3*(cos(px) + cos(py) + cos(pz)) + 4*cos(px)*cos(py)*cos(pz);
//   
//   bbox = [[-100,-100,-100], [100,100,100]];
//   isosurface(function (x,y,z) neovius(x,y,z,200),
//       isovalue=[-0.3,0.3], bounding_box=bbox, voxel_size=4);

module isosurface(f, isovalue, bounding_box, voxel_size, reverse=false, closed=true, show_stats=false) {
    vnf = isosurface(f, isovalue, bounding_box, voxel_size, reverse, closed, show_stats);
    vnf_polyhedron(vnf);
}

function isosurface(f, isovalue, bounding_box, voxel_size, reverse=false, closed=true, show_stats=false) =
    assert(all_defined([voxel_size, bounding_box, isovalue, f]), "The parameters f, isovalue, bounding_box, and voxel_size must all be defined.")
    let(
        isovalmin = is_list(isovalue) ? isovalue[0] : isovalue,
        isovalmax = is_list(isovalue) ? isovalue[1] : INF,
        newbbox = let( // new bounding box quantized for voxel_size
            hv = 0.5*voxel_size,
            bbn = (bounding_box[1]-bounding_box[0]+[hv,hv,hv]) / voxel_size,
            bbsize = [round(bbn[0]), round(bbn[1]), round(bbn[2])] * voxel_size
        ) [bounding_box[0], bounding_box[0]+bbsize],            
        cubes = _isosurface_cubes(voxel_size, bbox=newbbox, fieldfunc=f, isovalmin=isovalmin, isovalmax=isovalmax, closed=closed),
        tritablemin = reverse ? _MCTriangleTable_reverse : _MCTriangleTable,
        tritablemax = reverse ? _MCTriangleTable : _MCTriangleTable_reverse,
        trianglepoints = _isosurface_triangles(cubes, voxel_size, isovalmin, isovalmax, tritablemin, tritablemax),
        faces = [ for(i=[0:3:len(trianglepoints)-1]) [i,i+1,i+2] ],
        dummy = show_stats ? _showstats(voxel_size, newbbox, isovalmin, cubes, faces) : 0
) [trianglepoints, faces];


// Function&Module: isosurface_array()
// Synopsis: Creates a 3D isosurface from a 3D array of densities.
// SynTags: Geom,VNF
// Topics: Isosurfaces, VNF Generators
// Usage: As a module
//   isosurface_array(field, isovalue, voxel_size, [origin=], [reverse=], [closed=], [show_stats=]);
// Usage: As a function
//   vnf = isosurface_array(field, isovalue, voxel_size, [origin=], [reverse=], [closed=], [show_stats=]);
// Description:
//   When called as a function, returns a [VNF structure](vnf.scad) (list of triangles and
//   faces) representing a 3D isosurface within the passed array at a single isovalue or
//   range of isovalues.
//   When called as a module, displays the isosurface within the passed array at a single
//   isovalue or range of isovalues. This module just passes the parameters to the function,
//   and then calls {{vnf_polyhedron()}} to display the isosurface.
//   .
//   Use this when you already have a 3D array of field density values, for example like
//   what you may get from a [CT scan](https://en.wikipedia.org/wiki/CT_scan). This function is also
//   used by {{metaballs()}} after precalculating the array of points in the bounding volume. 
//   . 
//   By default, the returned VNF structure occupies a volume with its origin at [0,0,0]
//   extending in the positive x, y, and z directions by multiples of `voxel_size`.
//   This origin can be overridden by the `origin` parameter.
//   .
//   The point list in the VNF structure contains many duplicated points. This is not a
//   problem for rendering the shape, but if you want to eliminate these, you can pass
//   the structure to {{vnf_merge_points()}}. Additionally, flat surfaces at the outer limits
//   of the `field` array are triangulated at the voxel size
//   resolution, and these can be unified into a single face by passing the vnf
//   structure to {{vnf_unify_faces()}}. These steps can be expensive for execution time
//   and are not normally necessary.
// Arguments:
//   field = 3D array of numbers. This array should be organized so that the indices are in order of x, y, and z when the array is referenced; that is, `field[x_index][y_index][z_index]` has `z_index` changing most rapidly as the array is traversed. If you organize the array differently, you may have to perform a `rotate()` or `mirror()` operation on the final result to orient it properly.
//   isovalue = As a scalar, specifies the output value of `field_function` corresponding to the isosurface. As a vector `[min_isovalue, max_isovalue]`, specifies the range of isovalues around which to generate a surface. For closed surfaces, a single value results in a closed volume, and a range results in a shell (with an inside and outside surface) enclosing a volume. A range must be specified for surfaces (such as gyroids) that have both sides exposed within the bounding box. 
//   voxel_size = The size (scalar) of the voxel cube that determines the resolution of the surface.
//   ---
//   origin = Origin in 3D space corresponding to `field[0][0][0]`. The bounding box of the isosurface extends from this origin by multiples of `voxel_size` according to the size of the `field` array. Default: [0,0,0]
//   reverse = When true, reverses the orientation of the facets in the mesh. Default: false
//   closed = When true, maintains a manifold surface where the bounding box clips it (there is a negligible speed penalty in doing this). When false, the bounding box clips the surface, exposes the back sides of facets. Setting this to false can be useful with OpenSCAD's "View > Thrown together" menu option to distinguish inside from outside. Default: true
//   show_stats = If true, display statistics about the isosurface in the console window. Besides the number of voxels found to contain the surface, and the number of triangles making up the surface, this is useful for getting information about a smaller bounding box possible for the isosurface, to improve speed for subsequent renders. Enabling this parameter has a speed penalty. Default: false
// Example(3D):
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
//      isosurface_array(field, isovalue=0.5,
//          voxel_size=10);

module isosurface_array(field, isovalue, voxel_size, origin=[0,0,0], reverse=false, closed=true, show_stats=false) {
    vnf = isosurface_array(field, isovalue, voxel_size, origin, reverse, closed, show_stats);
    vnf_polyhedron(vnf);
}
function isosurface_array(field, isovalue, voxel_size, origin=[0,0,0], reverse=false, closed=true, show_stats=false) =
    assert(all_defined([field, isovalue, voxel_size]), "The parameters field, isovalue, and voxel_size must all be defined.")
    let(
        isovalmin = is_list(isovalue) ? isovalue[0] : isovalue,
        isovalmax = is_list(isovalue) ? isovalue[1] : INF,
        bbox = let(
            nx = len(field)-1,
            ny = len(field[0])-1,
            nz = len(field[0][0])-1
        ) [origin, origin+[nx*voxel_size, ny*voxel_size, nz*voxel_size]],
        cubes = _isosurface_cubes(voxel_size, bbox, fieldarray=field, isovalmin=isovalmin, isovalmax=isovalmax, closed=closed),
        tritablemin = reverse ? _MCTriangleTable_reverse : _MCTriangleTable,
        tritablemax = reverse ? _MCTriangleTable : _MCTriangleTable_reverse,
        trianglepoints = _isosurface_triangles(cubes, voxel_size, isovalmin, isovalmax, tritablemin, tritablemax),
        faces = [ for(i=[0:3:len(trianglepoints)-1]) [i,i+1,i+2] ],
        dummy = show_stats ? _showstats(voxel_size, bbox, isovalmin, cubes, faces) : 0
) [trianglepoints, faces];
    
    
/// isosurface_cubes() - private function, called by isosurface()
/// This implements a marching cube algorithm, sacrificing some memory in favor of speed.
/// Return a list of voxel cube structures that have one or both surfaces isovalmin or isovalmax intersecting them, and cubes inside the isosurface volume that are at the bounds of the bounding box.
/// The cube structure is:
/// [cubecoord, cubeindex_isomin, cubeindex_isomax, field, bfaces]
/// where
///     cubecoord is the [x,y,z] coordinate of the front left bottom corner of the voxel,
///     cubeindex_isomin and cubeindex_isomax are the index IDs of the voxel corresponding to the min and max iso surface intersections
///     cf is vector containing the 6 field strength values at each corner of the voxel cube
///     bfaces is an array of faces corresponding to the sides of the bounding box - this is empty most of the time; it has data only where the isosurface is clipped by the bounding box.
/// The bounding box 'bbox' is expected to be quantized for the voxel size already.

function _isosurface_cubes(voxsize, bbox, fieldarray, fieldfunc, isovalmin, isovalmax, closed=true) = let(
    // get field intensities
    field = is_def(fieldarray)
    ? fieldarray
    : let(v = bbox[0], hv = 0.5*voxsize, b1 = bbox[1]+[hv,hv,hv]) [
        for(x=[v[0]:voxsize:b1[0]]) [
            for(y=[v[1]:voxsize:b1[1]]) [
                for(z=[v[2]:voxsize:b1[2]])
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
                    cf = [
                        field[i][j][k],
                        field[i][j][k1],
                        field[i][j1][k],
                        field[i][j1][k1],
                        field[i1][j][k],
                        field[i1][j][k1],
                        field[i1][j1][k],
                        field[i1][j1][k1]
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
                        sumcond = sum([for(b=bf) isovalmin<=cf[b] && cf[b]<=isovalmax ? 1 : 0])
                    ) sumcond == len(bf),
                    cubeindex_isomin = cubefound_isomin ? _cubeindex(cf, isovalmin) : 0,
                    cubeindex_isomax = cubefound_isomax ? _cubeindex(cf, isovalmax) : 0
                ) if(cubefound_isomin || cubefound_isomax || cubefound_outer) [
                    cubecoord, 
                    cubeindex_isomin, cubeindex_isomax,
                    cf, bfaces
                ]
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

    
/// _isosurface_trangles() - called by isosurface()
/// Given a list of voxel cubes structures, triangulate the isosurface(s) that intersect each cube and return a list of triangle vertices.
function _isosurface_triangles(cubelist, cubesize, isovalmin, isovalmax, tritablemin, tritablemax) = [
    for(cl=cubelist) let(
        v = cl[0],
        cbidxmin = cl[1],
        cbidxmax = cl[2],
        f = cl[3],
        bbfaces = cl[4],
        vcube = [
            v, v+[0,0,cubesize], v+[0,cubesize,0], v+[0,cubesize,cubesize],
            v+[cubesize,0,0], v+[cubesize,0,cubesize],
            v+[cubesize,cubesize,0], v+[cubesize,cubesize,cubesize]
        ],
        epathmin = tritablemin[cbidxmin],
        epathmax = tritablemax[cbidxmax],
        lenmin = len(epathmin),
        lenmax = len(epathmax),
        outfacevertices = flatten([
            for(bf = bbfaces)
                _bbfacevertices(vcube, f, bf, isovalmax, isovalmin)
        ]),
        n_outer = len(outfacevertices)
    )
    // bunch of repeated code here in an attempt to gain some speed to avoid function calls and calls to flatten().
    // Where the face of the bounding box clips a voxel, those are done in separate if() blocks and require require a concat(), but the majority of voxels can have triangles generated directly. If there is no clipping, the list of trianges is generated all at once.
    if(lenmin>0 && lenmax>0) let(
        // both min and max surfaces intersect a voxel clipped by bounding box
        list = concat(
          // min surface
          [ for(ei=epathmin) let(
            edge = _MCEdgeVertexIndices[ei],
            vi0 = edge[0],
            vi1 = edge[1],
            denom = f[vi1] - f[vi0],
            u = abs(denom)<0.0001 ? 0.5 : (isovalmin-f[vi0]) / denom
          ) vcube[vi0] + u*(vcube[vi1]-vcube[vi0]) ],
          // max surface
          [ for(ei=epathmax) let(
            edge = _MCEdgeVertexIndices[ei],
            vi0 = edge[0],
            vi1 = edge[1],
            denom = f[vi1] - f[vi0],
            u = abs(denom)<0.0001 ? 0.5 : (isovalmax-f[vi0]) / denom
          ) vcube[vi0] + u*(vcube[vi1]-vcube[vi0]) ], outfacevertices)
        ) for(ls = list) ls
    else if(n_outer>0 && lenmin>0) let(
         // only min surface intersects a voxel clipped by bounding box
        list = concat(
          [ for(ei=epathmin) let(
            edge = _MCEdgeVertexIndices[ei],
            vi0 = edge[0],
            vi1 = edge[1],
            denom = f[vi1] - f[vi0],
            u = abs(denom)<0.0001 ? 0.5 : (isovalmin-f[vi0]) / denom
          ) vcube[vi0] + u*(vcube[vi1]-vcube[vi0]) ], outfacevertices)
        ) for(ls = list) ls
    else if(lenmin>0)
         // only min surface intersects a voxel
        for(ei=epathmin) let(
            edge = _MCEdgeVertexIndices[ei],
            vi0 = edge[0],
            vi1 = edge[1],
            denom = f[vi1] - f[vi0],
            u = abs(denom)<0.0001 ? 0.5 : (isovalmin-f[vi0]) / denom
        ) vcube[vi0] + u*(vcube[vi1]-vcube[vi0])
    else if(n_outer>0 && lenmax>0) let(
        // only max surface intersects the voxel on the bounding box
        list = concat(
          [ for(ei=epathmax) let(
            edge = _MCEdgeVertexIndices[ei],
            vi0 = edge[0],
            vi1 = edge[1],
            denom = f[vi1] - f[vi0],
            u = abs(denom)<0.0001 ? 0.5 : (isovalmax-f[vi0]) / denom
          ) vcube[vi0] + u*(vcube[vi1]-vcube[vi0]) ], outfacevertices)
        ) for(ls = list) ls
    else if(lenmax>0)
        // only max surface intersects the voxel
        for(ei=epathmax) let(
            edge = _MCEdgeVertexIndices[ei],
            vi0 = edge[0],
            vi1 = edge[1],
            denom = f[vi1] - f[vi0],
            u = abs(denom)<0.0001 ? 0.5 : (isovalmax-f[vi0]) / denom
        ) vcube[vi0] + u*(vcube[vi1]-vcube[vi0])
    else if(n_outer>0)
        // no surface intersects a voxel clipped by bounding box but the bounding box at this voxel is inside the volume between isomin and isomax
        for(ls = outfacevertices) ls
];


/// Generate triangles for voxel faces clipped by the bounding box
function _bbfacevertices(vcube, f, bbface, isovalmax, isovalmin) = let(
    vi = _MCFaceVertexIndices[bbface],
    vfc = [ for(i=vi) vcube[i] ],
    fld = [ for(i=vi) f[i] ],
    pgon = flatten([
        for(i=[0:3]) let(
            vi0=vi[i],
            vi1=vi[(i+1)%4],
            f0 = f[vi0],
            f1 = f[vi1],
            lowhiorder = (f0<f1),
            fmin = min(f0, f1),
            fmax = max(f0, f1),
            fbetweenlow = (fmin <= isovalmin && isovalmin <= fmax),
            fbetweenhigh = (fmin <= isovalmax && isovalmax <= fmax),
            denom = f1 - f0
        ) [
            if(isovalmin <= f0 && f0 <= isovalmax) vcube[vi0],
            if(fbetweenlow && f0<=f1) let(
                u = abs(denom)<0.0001 ? 0.5 : (isovalmin-f0)/denom
            ) vcube[vi0] + u*(vcube[vi1]-vcube[vi0]),
            if(fbetweenhigh && f0<=f1) let(
                u = abs(denom)<0.0001 ? 0.5 : (isovalmax-f0)/denom
            ) vcube[vi0] + u*(vcube[vi1]-vcube[vi0]),
            if(fbetweenhigh && f0>=f1) let(
                u = abs(denom)<0.0001 ? 0.5 : (isovalmax-f0)/denom
            ) vcube[vi0] + u*(vcube[vi1]-vcube[vi0]),
            if(fbetweenlow && f0>=f1) let(
                u = abs(denom)<0.0001 ? 0.5 : (isovalmin-f0)/denom
            ) vcube[vi0] + u*(vcube[vi1]-vcube[vi0])

        ]
    ]),
    npgon = len(pgon),
    triangles = npgon==0 ? [] : [
        for(i=[1:len(pgon)-2]) [pgon[0], pgon[i], pgon[i+1]]
    ]) flatten(triangles);


/// _showstats() (Private function) - called by isosurface() and isosurface_array()
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
    "\n   Bounding box for all data = ", bbox,
    "\n   Bounding box for isosurface = ", [[xmin,ymin,zmin], [xmax,ymax,zmax]],
    "\n")) 0;


/// ---------- metaball stuff starts here, uses isosurface_array() above ----------

/// Built-in metaball functions corresponding to each MB_ index.
/// Each function takes three parameters:
/// dv = cartesian distance, a vector [dx,dy,dz] being the distances from the ball center to the volume sample point
/// coeff = the "charge" of the metaball, can be a vector if the charges are different on each axis.
/// additional value or array of values needed by the function.
/// cutoff = radial cutoff; effect suppression increases with distance until zero at the rcutoff distance, and is zero from that point farther out. Default: INF

function _mb_sphere(dv, coeff, cutoff) = let(
    r = norm(dv),
    suppress = let(a=min(r,cutoff)/cutoff) 1-a*a
) r==0 ? 1e9 : suppress*coeff / r;

function mb_sphere(coeff=10, cutoff=INF) = function (dv) _mb_sphere(dv, coeff, cutoff);


_mb_ellipsoid = function (dv, coeff_vec, cutoff)
let(
    r = norm(v_div(dv,coeff_vec)),
    suppress = let(a = min(r,cutoff)/cutoff) 1-a*a,
    sgn = sign(coeff_vec[0]*coeff_vec[1]*coeff_vec[2])
) r==0 ? sgn*1e9
    : suppress * sgn / r;

function mb_ellipsoid(coeff_vec, cutoff=INF) = function (dv) _mb_ellipsoid(dv, coeff_vec, cutoff);


_mb_roundcube = function (dv, coeff, squareness, cutoff)
let(
    exponent = _squircle_se_exponent(squareness),
    r = abs(dv[0])^exponent + abs(dv[1])^exponent + abs(dv[2])^exponent,
    suppress = let(a = min(r,cutoff)/cutoff) 1-a*a
) r==0 ? 1e9 : suppress*sign(coeff)*abs(coeff)^exponent / r;

function mb_roundcube(coeff, squareness=0.5, cutoff=INF) = function (dv) _mb_roundcube(dv, coeff, squareness, cutoff);


_mb_cube = function (dv, coeff, cutoff)
let(
    r = max(v_abs(dv)),
    suppress = let(a = min(r,cutoff)/cutoff) 1-a*a
) r==0 ? 1e9 : suppress*coeff / r;

function mb_cube(coeff, cutoff=INF) = function (dv) _mb_cube(dv, coeff, cutoff);


_mb_octahedron = function (dv, coeff, cutoff)
let(
    r = abs(dv[0]) + abs(dv[1]) + abs(dv[2]),
    suppress = let(a = min(r,cutoff)/cutoff) 1-a*a
) r==0 ? 1e9 : suppress*coeff / r;

function mb_octahedron(coeff, cutoff=INF) = function (dv) _mb_octahedron(dv, coeff, cutoff);


_mb_torus = function (dv, rbig, rsmall, cutoff)
let( axis=[0,0,1],
    d_axisplane = norm(v_mul([1,1,1]-axis, dv)) - rbig,
    d_axis = axis*dv,
    r = norm([d_axisplane, d_axis]),
    suppress = let(a = min(r,cutoff)/cutoff) 1-a*a
) r==0 ? 1e9 : suppress*rsmall / r;

function mb_torus(rbig, rsmall, cutoff=INF) = function (dv) _mb_torus(dv, rbig, rsmall, cutoff);


/// metaball field function, calling any of the other metaball functions above to accumulate
/// the contribution of each metaball at point xyz
_metaball_fieldfunc = function(xyz1, nballs, transform, funcs)
let(
    contrib = [
        for(i=[0:nballs-1])
            let(dv = xyz1 * transform[i])
                funcs[i+i+1](dv)
    ]
) sum(contrib);


/// ANIMATED metaball demo made with BOSL2 here: https://imgur.com/a/m29q8Qd


// Function&Module: metaballs()
// Synopsis: Creates a model of metaballs within a bounding box.
// SynTags: Geom,VNF
// Topics: Metaballs, Isosurfaces, VNF Generators
// See Also: isosurface_array()
// Usage: As a module
//   metaballs(funcs, isovalue, bounding_box, voxel_size, [closed=], [show_stats=]);
// Usage: As a function
//   vnf = metaballs(funcs, isovalue, bounding_box, voxel_size, [closed=], [show_stats=]);
// Description:
//   [Metaballs](https://en.wikipedia.org/wiki/Metaballs), also known as "blobby objects",
//   are organic-looking ball-shaped blobs that meld together when in close proximity.
//   The melding property is determined by an interaction formula based on the coefficient
//   weight (which can be thought of as a charge, strength, density, or intensity) of
//   each ball and their distance from one another.
//   .
//   One analagous way to think of metaballs is, if you consider a "ball" to be a point
//   charge in 3D space, the electric field surrounding that charge decreases in intensity
//   with distance from the charge. The metaball is the isosurface corresponding to all value
//   where the electric field intensity is a constant value.
//   .
//   Another way to think of it could be, consdier each "ball" to be a point-light source in
//   a dark room. Pick an illumination value, and every point in the volume of the room with
//   that intensity of illumination defines the isosurface, which would be a sphere around a
//   single source, or blobs surrounding the points because the illumination is additive between them.
//   .
//   Regardless of how you think of it (charge, light, heat, pressure), a stronger metaball
//   intensity results in a stronger "field" around the metaball, and correspondingly a
//   larger metaball due to the isosurface of a particular value being farther away.
//   Electric fields with contributions from two charges add together, changing the shape of
//   the two corresponding metaballs when they are in close proximity.
//   .
//   In physics, the field density function falls off as an inverse-square relationship
//   with distance; that is, the field is proportional to $1/r^2$ where $r$ is the radial
//   distance from the ball center. However, most implementations of metaballs instead use
//   a simple inverse relationship proportional to $1/r$. That is true for the field
//   types available here, or you can define your own falloff function as the
//   `field_function` parameter.
//   .
//   .h3 Built-in metaball functions
//   Six shapes of metaball field density functions are built into this library. You can specify
//   different ones for each metaball in the list, and you can also specify your own
//   custom function. All of them require a coefficient weight. The coefficient must be a value or a vector, as described below.
//   .
//   Any other parameters are optional. In all cases, `cutoff` specifies the distance beyond which the metaball has no influence. Default: `INF`
//   .
//   These are the built-in metaball functions. Arguments with default values are optional:
//   * `mb_sphere(coeff, cutoff=INF)` - the standard spherical metaball with a $1/r$ field strength falloff. The intensity coefficient `coeff` must be specified as a scalar value.
//   * `mb_ellipsoid(coeff_vec, cutoff=INF)` - an ellipsoid-shaped field that requires specifying a [x,y,z] vector for `coeff_vec`, representing intensity of influence in each of the x, y, and z directions. One could accomplish a similar effect by combining `mb_sphere()` with scaling transforms, but this is a convenient alternative.
//   * `mb_roundcube(coeff, squareness=0.5, cutoff=INF)` - a cube-shaped metaball with corners that get more rounded with size, determined by the scalar `coeff` that you must specify. The squareness can be controlled with a value between 0 (spherical) or 1 (cubical) in the `squareness` parameter, and defaults to 0.5 if omitted.
//   * `mb_cube(coeff, cutoff=INF)` - a cube-shaped metaball with sharp edges and corners, resulting from using [Chebyshev distance](https://en.wikipedia.org/wiki/Chebyshev_distance) rather than Euclidean distance calculations. 
//   * `mb_octahedron(coeff, cutoff=INF)` - an octahedron-shaped metaball with sharp edges and corners, resulting from using [taxicab distance](https://en.wikipedia.org/wiki/Taxicab_geometry) rather than Euclidean distance calculations.
//   * `mb_torus(rbig, rsmall, cutoff=INF)` - a toroidal field oriented perpendicular to the z axis. The parameter `rbig` and `rsmall` control the major and minor radii. `rsmall` can be negative to create a negative influence on the surrounding volume.
//   .
//   Your own custom function must be written as a [function literal](https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/User-Defined_Functions_and_Modules#Function_literals)
//   and take `dv` as the first argument. `dv` is passed to your function as a 3D distance vector from the ball center
//   to the point in the bounding box volume for which to calculate the field intensity. The function retun must be a single
//   number such that higher values are enclosed by the metaball and lower values are outside the metaball.
//   In this case, if you have written `my_func()` , the array element you initialize must appear as `function (dv) my_func(dv, ...)`.
//   See Example 5 below.
//   .
//   Now for the arguments to this metaball() module or function....
// Arguments:
//   funcs = a 1-D list of transform and function pairs in the form `[trans0, func0, trans1, func1, ...]`, with one pair for each metaball. The transform should be at least `move([x,y,z])` to specify the location of the metaball center, but you can also include rotations, such as `move([x,y,z])*rot([ax,ay,az])`. You can multiply together any of BOSL2's affine operations like {{xrot()}}, {{scale()}}, and {{skew()}}. This is useful for orienting non-spherical metaballs. The priority order of the transforms is right to left, that is, `move([4,5,6])*rot([45,0,90])` does the rotation first, and then the move, similar to normal OpenSCAD syntax `translate([4,5,6]) rotate([45,0,90]) children()`.
//   isovalue = A scalar value specifying the isosurface value of the metaballs.
//   bounding_box = A pair of 3D points `[[xmin,ymin,zmin], [xmax,ymax,zmax]]`, specifying the minimum and maximum box corner coordinates. The voxels needn't fit perfectly inside the bounding box.
//   voxel_size = The size (scalar) of the voxel cube that determines the resolution of the metaball surface. **Start with a larger size for experimenting, and refine it gradually.** A small voxel size can significantly slow down processing time, especially with a large `bounding_box`.
//   ---
//   closed = When true, maintains a manifold surface where the bounding box clips it (there is a negligible speed penalty in doing this). When false, the bounding box clips the surface, exposing the back sides of facets. Setting this to false can be useful with OpenSCAD's "View > Thrown together" menu option to distinguish inside from outside. Default: true
//   show_stats = If true, display statistics about the metaball isosurface in the console window. Besides the number of voxels found to contain the surface, and the number of triangles making up the surface, this is useful for getting information about a smaller bounding box possible, to improve speed for subsequent renders. Enabling this parameter has a speed penalty. Default: false
// Example(3D,NoAxes): A group of five spherical metaballs with different charges. The parameter `show_stats=true` (not shown here) was used to find a compact bounding box for this figure.
//   funcs = [ // spheres of different sizes
//       move([-20,-20,-20]), mb_sphere(5),
//       move([0,-20,-20]),   mb_sphere(4),
//       move([0,0,0]),       mb_sphere(3),
//       move([0,0,20]),      mb_sphere(5),
//       move([20,20,10]),    mb_sphere(7)
//   ];
//   isovalue = 1;
//   voxelsize = 1.5;
//   boundingbox = [[-30,-31,-31], [32,31,31]];
//   metaballs(funcs, isovalue, boundingbox, voxelsize);
// Example(3D,NoAxes): A metaball can have negative charge. In this case we have two metaballs in close proximity, with the small negative metaball creating a dent in the large positive one. The positive metaball is shown transparent, and small spheres show the center of each metaball. The negative metaball isn't visible because its field is negative; the isosurface encloses only field values greater than the isovalue of 1.
//   centers = [[-1,0,0], [1.25,0,0]];
//   funcs = [
//       move(centers[0]), mb_sphere(8),
//       move(centers[1]), mb_sphere(-3)
//   ];
//   voxelsize = 0.25;
//   isovalue = 1;
//   boundingbox = [[-7,-6,-6], [3,6,6]];
//   #metaballs(funcs, isovalue, boundingbox, voxelsize);
//   color("green") move_copies(centers) sphere(d=1, $fn=16);
// Example(3D,NoAxes): A cube, a rounded cube, and an octahedron interacting.
//   funcs = [
//       move([-7,-3,27]), mb_cube(5),
//       move([7,5,21]),   mb_roundcube(5),
//       move([10,0,10]),  mb_octahedron(5)
//   ];
//   voxelsize = 0.4; // a bit slow at this resolution
//   isovalue = 1;
//   boundingbox = [[-13,-9,3], [16,11,33]];
//   metaballs(funcs, isovalue, boundingbox, voxelsize);
// Example(3D,NoAxes): Interaction between two torus-shaped fields in different orientations.
//   funcs = [
//       move([-10,0,17]),        mb_torus(rbig=6, rsmall=2),
//       move([7,6,21])*xrot(90), mb_torus(rbig=7, rsmall=3)
//   ];
//   voxelsize = 0.5;
//   isovalue = 1;
//   boundingbox = [[-19,-9,9], [18,10,32]];
//   metaballs(funcs, isovalue, boundingbox, voxelsize);
// Example(3D): Demonstration of a custom metaball function, in this case a sphere with some random noise added to its electric field.
// custom function, 'dv' is internal distance vector
//   function noisy_sphere(dv, charge, noise_level, rcutoff) =
//       let(
//           r = norm(dv) + rands(0, noise_level, 1)[0],
//           suppress = let(a=min(r,rcutoff)/rcutoff) 1-a*a
//       ) r==0 ? 1000*charge : suppress*charge / r;
//   
//   funcs = [
//       move([-9,0,0]), mb_sphere(5),
//       move([9,0,0]),  function (dv) noisy_sphere(dv, 5, 0.2, INF),
//   ];
//   voxelsize = 0.4;
//   isovalue = 1;
//   boundingbox = [[-16,-8,-8], [16,8,8]];
//   metaballs(funcs, isovalue, boundingbox, voxelsize);
// Example(3D,Med,NoAxes,VPR=[55,0,0],VPD=200,VPT=[7,2,2]): A complex example using ellipsoids, spheres, and a torus to make a tetrahedral object with rounded feet and a ring on top. The bottoms of the feet are flattened by limiting the minimum z value of the bounding box. The center of the object is thick due to the contributions of four ellipsoids converging. Designing an object like this using metaballs requires trial and error with low-resolution renders.
//   ztheta = 90-acos(-1/3);
//   cz = cos(ztheta);
//   sz = sin(ztheta);
//   funcs = [
//       // ellipsoid arms
//       move([0,0,20])*yrot(90),
//           mb_ellipsoid([6,2,2], cutoff=40),
//       move([20*cz,0,20*sz])*yrot(-ztheta),
//           mb_ellipsoid([7,2,2], cutoff=40),
//       move(zrot(120, p=[20*cz,0,20*sz]))*rot([0,-ztheta,120]),
//           mb_ellipsoid([7,2,2], cutoff=40),
//       move(zrot(-120, p=[20*cz,0,20*sz]))*rot([0,-ztheta,-120]),
//           mb_ellipsoid([7,2,2], cutoff=40),
//       // ring on top
//       move([0,0,35])*xrot(90), mb_torus(rbig=8, rsmall=2, cutoff=40),
//       // feet
//       move([32*cz,0,32*sz]), mb_sphere(5, cutoff=40),
//       move(zrot(120, p=[32*cz,0,32*sz])), mb_sphere(5, cutoff=40),
//       move(zrot(-120, p=[32*cz,0,32*sz])), mb_sphere(5, cutoff=40)
//   ];
//   voxelsize = 1;
//   isovalue = 1;
//   boundingbox = [[-23,-36,-15], [39,36,46]];
//   // useful to save as VNF for copies and manipulations
//   vnf = metaballs(funcs, isovalue, boundingbox, voxelsize);
//   vnf_polyhedron(vnf);

module metaballs(funcs, isovalue, bounding_box, voxel_size, closed=true, show_stats=false) {
        vnf = metaballs(funcs, isovalue, bounding_box, voxel_size, closed, show_stats);
        vnf_polyhedron(vnf);
}

function metaballs(funcs, isovalue, bounding_box, voxel_size, closed=true, show_stats=false) =
assert(all_defined([funcs, isovalue, bounding_box, voxel_size]), "\nThe parameters funcs, isovalue, bounding_box, and voxel_size must all be defined.")
assert(len(funcs)%2==0, "\nThe funcs parameter must be an even-length list of alternating transforms and functions")
let(
    isoval = is_vector(isovalue) ? isovalue[0] : isovalue,
    f = is_list(funcs) && is_def(funcs[0][0]) ? funcs : [funcs],
    nballs = round(len(f) / 2),
    // set up transformation matrices in advance
    transmatrix = [
        for(i=[0:nballs-1]) let(j=i+i)
            assert(is_matrix(f[j],4,4), str("\nfuncs entry at position ", j, " must be a 4×4 matrix."))
            assert(is_function(f[j+1]), str("\nfuncs entry at position ", j+1, "must be a function literal."))
            transpose(submatrix(matrix_inverse(f[j]), [0:2], [0:3]))
    ],

    // set up field array
    v0 = bounding_box[0],
    b1 = bounding_box[1],
    halfvox = 0.5*voxel_size,
    fieldarray = [
        for(x=[v0[0]:voxel_size:b1[0]+halfvox]) [
            for(y=[v0[1]:voxel_size:b1[1]+halfvox]) [
                for(z=[v0[2]:voxel_size:b1[2]+halfvox])
                    _metaball_fieldfunc([x,y,z,1], nballs, transmatrix, funcs)
            ]
        ]
    ]
) isosurface_array(fieldarray, isovalue, voxel_size, origin=v0, closed=closed, show_stats=show_stats);
