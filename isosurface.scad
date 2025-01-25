/////////////////////////////////////////////////////////////////////
// LibFile: isosurface.scad
//   An isosurface is a three-dimensional surface representing points of a constant
//   value (e.g. density pressure, temperature, electric field strength, density) in a
//   3D volume. It is essentially a 3D cross-section of a 4-dimensional function.
//   An isosurface may be represented generally by any function of three variables,
//   that is, the function returns a single value based on [x,y,z] inputs. The
//   isosurface is defined by all return values equal to a constant isovalue.
//   .
//   A [gryoid](https://en.wikipedia.org/wiki/Gyroid) (often used as a volume infill pattern in [FDM 3D printing](https://en.wikipedia.org/wiki/Fused_filament_fabrication))
//   is an exmaple of an isosurface that is unbounded and periodic in all three dimensions.
//   Other typical examples in 3D graphics are [metaballs](https://en.wikipedia.org/wiki/Metaballs) (also known as "blobby objects"),
//   which are bounded and closed organic-looking surfaces that meld together when in close proximity.
//   
// Includes:
//   include <BOSL2/std.scad>
//   include <BOSL2/isosurface.scad>
// FileGroup: Advanced Modeling
// FileSummary: Isosurfaces and metaballs.
//////////////////////////////////////////////////////////////////////


/*
Lookup Tables for Transvoxel's Modified Marching Cubes

From https://gist.github.com/dwilliamson/72c60fcd287a94867b4334b42a7888ad

Unlike the original paper (Marching Cubes: A High Resolution 3D Surface Construction Algorithm), these tables guarantee a closed mesh in which connected components are continuous and free of holes.

Rotations are prioritized over inversions so that 3 of the 6 cases containing ambiguous faces are never added. 3 extra cases are added as a post-process, overriding inversions through custom-built rotations to eliminate the remaining ambiguities.

The cube index determines the sequence of edges to split. The index ranges from 0 to 255, representing all possible combinations of the 8 corners of the cube being greater or less than the isosurface threshold. For example, 10000110 (8-bit binary for decimal index 134) has corners 2, 3, and 7 greater than the threshold. After determining the cube's index value, the triangulation order is looked up in a table.

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

z changes fastest, then y, then x

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

/// For each of the 255 configurations of a marching cube, define a list of triangles, specified as triples of edge indices.
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
//   isosurface(voxel_size, bounding_box, isovalue, field_function, [additional=], [reverse=], [close_clip=], [show_stats=]);
// Usage: As a function
//   vnf = isosurface(voxel_size, bounding_box, isovalue, field_function, [additional=], [close_clip=], [show_stats=]);
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
//   voxel_size = The size (scalar) of the voxel cube that determines the resolution of the surface.
//   bounding_box = A pair of 3D points `[[xmin,ymin,zmin], [xmax,ymax,zmax]]`, specifying the minimum and maximum corner coordinates of the bounding box. You don't have ensure that the voxels fit perfectly inside the bounding box. While the voxel at the minimum bounding box corner is aligned on that corner, the last voxel at the maximum box corner may extend a bit beyond it.
//   isovalue = As a scalar, specifies the output value of `field_function` corresponding to the isosurface. As a vector `[min_isovalue, max_isovalue]`, specifies the range of isovalues around which to generate a surface. For closed surfaces, a single value results in a closed volume, and a range results in a shell (with an inside and outside surface) enclosing a volume. A range must be specified for infinite-extent surfaces (such as gyroids) to create a manifold shape within the bounding box. 
//   field_function = A [function literal](https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/User-Defined_Functions_and_Modules#Function_literals) taking as input an `[x,y,z]` coordinate and optional additional parameters, and returns a single value.
//   ---
//   additional = A single value, or an array of optional additional parameters that may be required by the field function. It is your responsibility to create a function literal compatible with these inputs. If `additional` is not set, only the `[x,y,z]` parameter is passed to the function; no additional parameters are passed. Default: undef
//   reverse = When true, reverses the orientation of the facets in the mesh. Default: false
//   close_clip = When true, maintains a manifold surface where the bounding box clips it (there is a negligible speed penalty in doing this). When false, the bounding box clips the surface, exposing the back sides of facets. Setting this to false can be useful with OpenSCAD's "View > Thrown Together" menu option to distinguish inside from outside. Default: true
//   show_stats = If true, display statistics about the isosurface in the console window. Besides the number of voxels found to contain the surface, and the number of triangles making up the surface, this is useful for getting information about a smaller bounding box possible for the isosurface, to improve speed for subsequent renders. Enabling this parameter has a speed penalty. Default: false
// Example(3D,ThrownTogether,NoAxes): A gyroid is an isosurface defined by all the zero values of a 3D periodic function. To illustrate what the surface looks like, `close_clip=false` has been set to expose both sides of the surface. The surface is periodic and tileable along all three axis directions. This a non-manifold surface as displayed, not useful for 3D modeling. This example also demonstrates the use of the `additional` parameter, which in this case controls the wavelength of the gyroid.
//   gyroid = function (xyz, wavelength) let(
//       p = 360/wavelength,
//       px = p*xyz[0],
//       py = p*xyz[1],
//       pz = p*xyz[2]
//   ) sin(px)*cos(py) + sin(py)*cos(pz) + sin(pz)*cos(px);
//   
//   bbox = [[-100,-100,-100], [100,100,100]];
//   isosurface(voxel_size=5, bounding_box=bbox, isovalue=0,
//       field_function=gyroid, additional=200, close_clip=false);
// Example(3D,NoAxes): If we remove the `close_clip` parameter or set it to true, the isosurface algorithm encloses the entire half-space bounded by the "inner" gyroid surface, leaving only the "outer" surface exposed. This is a manifold shape but not what we want if trying to model a gyroid.
//   gyroid = function (xyz, wavelength) let(
//       p = 360/wavelength,
//       px = p*xyz[0],
//       py = p*xyz[1],
//       pz = p*xyz[2]
//   ) sin(px)*cos(py) + sin(py)*cos(pz) + sin(pz)*cos(px);
//   
//   bbox = [[-100,-100,-100], [100,100,100]];
//   isosurface(voxel_size=5, bounding_box=bbox, isovalue=0,
//       field_function=gyroid, additional=200);
// Example(3D,ThrownTogether,NoAxes): To make the gyroid a double-sided surface, we need to specify a small range around zero for `isovalue`. Now we have a double-sided surface although with `close_clip=false` the edges are not closed where the surface is clipped by the bounding box.
//   gyroid = function (xyz, wavelength) let(
//       p = 360/wavelength,
//       px = p*xyz[0],
//       py = p*xyz[1],
//       pz = p*xyz[2]
//   ) sin(px)*cos(py) + sin(py)*cos(pz) + sin(pz)*cos(px);
//   
//   bbox = [[-100,-100,-100], [100,100,100]];
//   isosurface(voxel_size=5, bounding_box=bbox, isovalue=[-0.3, 0.3],
//       field_function=gyroid, additional=200, close_clip=false);
// Example(3D,ThrownTogether,NoAxes): To make the gyroid a valid manifold 3D object, we remove the `close_clip` parameter (same as setting `close_clip=true`), which closes the edges where the surface is clipped by the bounding box. The resulting object can be tiled, the VNF returned by the functional version can be wrapped around an axis using {{vnf_bend()}}, and other operations.
//   gyroid = function (xyz, wavelength) let(
//       p = 360/wavelength,
//       px = p*xyz[0],
//       py = p*xyz[1],
//       pz = p*xyz[2]
//   ) sin(px)*cos(py) + sin(py)*cos(pz) + sin(pz)*cos(px);
//   
//   bbox = [[-100,-100,-100], [100,100,100]];
//   isosurface(voxel_size=5, bounding_box=bbox, isovalue=[-0.3, 0.3],
//       field_function=gyroid, additional=200);
// Example(3D,NoAxes): An approximation of the triply-periodic minimal surface known as [Schwartz P](https://en.wikipedia.org/wiki/Schwarz_minimal_surface).
//   schwartz_p = function (xyz, wavelength) let(
//       p = 360/wavelength,
//       px = p*xyz[0],
//       py = p*xyz[1],
//       pz = p*xyz[2]
//   )  cos(px) + cos(py) + cos(pz);
//   
//   bbox = [[-100,-100,-100], [100,100,100]];
//   isosurface(voxel_size=4, bounding_box=bbox, isovalue=[-0.2,0.2],
//       field_function=schwartz_p, additional=100);
// Example(3D,NoAxes): Another approximation of the triply-periodic minimal surface known as [Neovius](https://en.wikipedia.org/wiki/Neovius_surface).
//   neovius = function (xyz, wavelength) let(
//       p = 360/wavelength,
//       px = p*xyz[0],
//       py = p*xyz[1],
//      pz = p*xyz[2]
//   )  3*(cos(px) + cos(py) + cos(pz)) + 4*cos(px)*cos(py)*cos(pz);
//   
//   bbox = [[-100,-100,-100], [100,100,100]];
//   isosurface(voxel_size=4, bounding_box=bbox, isovalue=[-0.3,0.3],
//       field_function=neovius, additional=200);

module isosurface(voxel_size, bounding_box, isovalue, field_function, additional, reverse=false, close_clip=true, show_stats=false) {
    vnf = isosurface(voxel_size, bounding_box, isovalue, field_function, additional, reverse, close_clip, show_stats);
    vnf_polyhedron(vnf);
}

function isosurface(voxel_size, bounding_box, isovalue, field_function, additional, reverse=false, close_clip=true, show_stats=false) =
    assert(all_defined([voxel_size, bounding_box, isovalue, field_function]), "The parameters voxel_size, bounding_box, isovalue, and field_function must all be defined.")
    let(
        isovalmin = is_list(isovalue) ? isovalue[0] : isovalue,
        isovalmax = is_list(isovalue) ? isovalue[1] : INF,
        newbbox = let( // new bounding box quantized for voxel_size
            hv = 0.5*voxel_size,
            bbn = (bounding_box[1]-bounding_box[0]+[hv,hv,hv]) / voxel_size,
            bbsize = [round(bbn[0]), round(bbn[1]), round(bbn[2])] * voxel_size
        ) [bounding_box[0], bounding_box[0]+bbsize],            
        cubes = _isosurface_cubes(voxel_size, bbox=newbbox, fieldfunc=field_function, additional=additional, isovalmin=isovalmin, isovalmax=isovalmax, close_clip=close_clip),
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
//   isosurface_array(voxel_size, isovalue, fields, [origin=], [reverse=], [close_clip=], [show_stats=]);
// Usage: As a function
//   vnf = isosurface_array(voxel_size, isovalue, fields, [origin=], [reverse=], [close_clip=], [show_stats=]);
// Description:
//   When called as a function, returns a [VNF structure](vnf.scad) (list of triangles and
//   faces) representing a 3D isosurface within the passed array at a single isovalue or
//   range of isovalues.
//   When called as a module, displays the isosurface within the passed array at a single
//   isovalue or range of isovalues. This module just passes the parameters to the function,
//   and then calls {{vnf_polyhedron()}} to display the isosurface.
//   .
//   Use this when you already have a 3D array of intensity or density data, for example like
//   what you may get from a [CT scan](https://en.wikipedia.org/wiki/CT_scan).
//   . 
//   By default, the returned VNF structure occupies a volume with its origin at [0,0,0]
//   extending in the positive x, y, and z directions by multiples of `voxel_size`.
//   This origin can be overridden by the `origin` parameter.
//   .
//   The point list in the VNF structure contains many duplicated points. This is not a
//   problem for rendering the shape, but if you want to eliminate these, you can pass
//   the structure to {{vnf_merge_points()}}. Additionally, flat surfaces at the outer limits
//   of the `fields` array are triangulated at the voxel size
//   resolution, and these can be unified into a single face by passing the vnf
//   structure to {{vnf_unify_faces()}}. These steps can be expensive for execution time
//   and are not normally necessary.
// Arguments:
//   voxel_size = The size (scalar) of the voxel cube that determines the resolution of the surface.
//   isovalue = As a scalar, specifies the output value of `field_function` corresponding to the isosurface. As a vector `[min_isovalue, max_isovalue]`, specifies the range of isovalues around which to generate a surface. For closed surfaces, a single value results in a closed volume, and a range results in a shell (with an inside and outside surface) enclosing a volume. A range must be specified for surfaces (such as gyroids) that have both sides exposed within the bounding box. 
//   fields = 3D array of field intesities. This array should be organized so that the indices are in order of x, y, and z when the array is referenced; that is, `fields[x_index][y_index][z_index]` has `z_index` changing most rapidly as the array is traversed. If you organize the array differently, you may have to perform a `rotate()` or `mirror()` operation on the final result to orient it properly.
//   ---
//   origin = Origin in 3D space corresponding to `fields[0][0][0]`. The bounding box of the isosurface extends from this origin by multiples of `voxel_size` according to the size of the `fields` array. Default: [0,0,0]
//   reverse = When true, reverses the orientation of the facets in the mesh. Default: false
//   close_clip = When true, maintains a manifold surface where the bounding box clips it (there is a negligible speed penalty in doing this). When false, the bounding box clips the surface, exposes the back sides of facets. Setting this to false can be useful with OpenSCAD's "View > Thrown together" menu option to distinguish inside from outside. Default: true
//   show_stats = If true, display statistics about the isosurface in the console window. Besides the number of voxels found to contain the surface, and the number of triangles making up the surface, this is useful for getting information about a smaller bounding box possible for the isosurface, to improve speed for subsequent renders. Enabling this parameter has a speed penalty. Default: false
// Example(3D):
//   fields = [
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
//      isosurface_array(voxel_size=10,
//                       isovalue=0.5, fields=fields);

module isosurface_array(voxel_size, isovalue, fields, origin=[0,0,0], reverse=false, close_clip=true, show_stats=false) {
    vnf = isosurface_array(voxel_size, isovalue, fields, origin, reverse, close_clip, show_stats);
    vnf_polyhedron(vnf);
}
function isosurface_array(voxel_size, isovalue, fields, origin=[0,0,0], reverse=false, close_clip=true, show_stats=false) =
    assert(all_defined([voxel_size, fields, isovalue]), "The parameters voxel_size, fields, and isovalue must all be defined.")
    let(
        isovalmin = is_list(isovalue) ? isovalue[0] : isovalue,
        isovalmax = is_list(isovalue) ? isovalue[1] : INF,
        bbox = let(
            nx = len(fields)-1,
            ny = len(fields[0])-1,
            nz = len(fields[0][0])-1
        ) [origin, origin+[nx*voxel_size, ny*voxel_size, nz*voxel_size]],
        cubes = _isosurface_cubes(voxel_size, bbox, fieldarray=fields, isovalmin=isovalmin, isovalmax=isovalmax, close_clip=close_clip),
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

function _isosurface_cubes(voxsize, bbox, fieldarray, fieldfunc, additional, isovalmin, isovalmax, close_clip=true) = let(
    // get field intensities
    fields = is_def(fieldarray)
    ? fieldarray
    : let(v = bbox[0], hv = 0.5*voxsize, b1 = bbox[1]+[hv,hv,hv]) [
        for(x=[v[0]:voxsize:b1[0]]) [
            for(y=[v[1]:voxsize:b1[1]]) [
                for(z=[v[2]:voxsize:b1[2]])
                    additional==undef
                        ? fieldfunc([x,y,z])
                        : fieldfunc([x,y,z], additional)
            ]
        ]
    ],
    nx = len(fields)-2,
    ny = len(fields[0])-2,
    nz = len(fields[0][0])-2,
    v0 = bbox[0]
) [
    for(i=[0:nx]) let(x=v0[0]+voxsize*i)
        for(j=[0:ny]) let(y=v0[1]+voxsize*j)
            for(k=[0:nz]) let(z=v0[2]+voxsize*k)
                let(i1=i+1, j1=j+1, k1=k+1,
                    cf = [
                        fields[i][j][k],
                        fields[i][j][k1],
                        fields[i][j1][k],
                        fields[i][j1][k1],
                        fields[i1][j][k],
                        fields[i1][j][k1],
                        fields[i1][j1][k],
                        fields[i1][j1][k1]
                    ],
                    mincf = min(cf),
                    maxcf = max(cf),
                    cubecoord = [x,y,z],
                    bfaces = close_clip ? _bbox_faces(cubecoord, voxsize, bbox) : [],
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

/// metaball function literal indices

MB_SPHERE=0;
MB_ELLIPSOID=1;
MB_ROUNDCUBE=2;
MB_CUBE=3;
MB_OCTAHEDRON=4;
MB_TORUS=5;
MB_CUSTOM=6;

/// Built-in metaball functions corresponding to each MB_ index.
/// Each function takes three parameters:
/// cdist = cartesian distance, a vector [dx,dy,dz] being the distances from the ball center to the volume sample point
/// charge = the charge of the metaball, can be a vector if the charges are different on each axis.
/// additional (named whatever's convenient) = additional value or array of values needed by the function.
/// rcutoff = radial cutoff; effect suppression increases with distance until zero at the rcutoff distance, and is zero from that point farther out. Default: INF

_metaball_sphere = function (cdist, charge, unused, rotm, rcutoff)
let(
    r = norm(cdist),
    suppress = let(a=min(r,rcutoff)/rcutoff) 1-a*a
) r==0 ? 10000*charge : suppress*charge / r;

_metaball_ellipsoid = function (cdist, charge, unused, rotm, rcutoff)
let(
    dist = concat(cdist,1) * rotm,
    r = norm([dist[0]/charge[0], dist[1]/charge[1], dist[2]/charge[2]]),
    suppress = let(a=min(r,rcutoff)/rcutoff) 1-a*a,
    sgn = sign(charge[0]*charge[1]*charge[2])
) r==0 ? 10000*sgn*max(abs(charge[0]), abs(charge[1]), abs(charge[2]))
    : suppress*sgn / r;

_metaball_roundcube = function (cdist, charge, exponent, rotm, rcutoff)
let(
    dist = concat(cdist,1) * rotm,
    r = abs(dist[0])^exponent + abs(dist[1])^exponent + abs(dist[2])^exponent,
    suppress = let(a=min(r,rcutoff)/rcutoff) 1-a*a
) r==0 ? 10000*charge : suppress*sign(charge)*abs(charge)^exponent / r;

_metaball_cube = function (cdist, charge, unused, rotm, rcutoff)
let(
    dist = concat(cdist,1) * rotm,
    r = max(abs(dist[0]), abs(dist[1]), abs(dist[2])),
    suppress = let(a=min(r,rcutoff)/rcutoff) 1-a*a
) r==0 ? 10000*charge : suppress*sign(charge)*abs(charge) / r;

_metaball_octahedron = function (cdist, charge, unused, rotm, rcutoff)
let(
    dist = concat(cdist,1) * rotm,
    r = abs(dist[0]) + abs(dist[1]) + abs(dist[2]),
    suppress = let(a=min(r,rcutoff)/rcutoff) 1-a*a
) r==0 ? 10000*charge : suppress*sign(charge)*abs(charge) / r;

_metaball_torus = function (cdist, charge, axis, rotm, rcutoff)
let(
    tmp = concat(cdist,1) * rotm,
    dist = [tmp[0], tmp[1], tmp[2]],
    bigdia = abs(charge[0]),
    smalldia = charge[1],
    d_axisplane = norm(v_mul([1,1,1]-axis, dist)) - bigdia,
    d_axis = axis*dist,
    r = norm([d_axisplane, d_axis]),
    suppress = let(a=min(r,rcutoff)/rcutoff) 1-a*a
) r==0 ? 1000*max(charge) : suppress*sign(charge[0])*smalldia / r;


/// metaball field function, calling any of the other metaball functions above to accumulate
/// the contribution of each metaball at point xyz
_metaball_fieldfunc = function(xyz, nballs, ball_centers, charges, ball_type, rotmatrix, additional, rcutoff, funcs)
let(
    contrib = [
        for(i=[0:nballs-1]) let(
            dist = xyz-ball_centers[i],
            func = ball_type[i]==MB_CUSTOM ? funcs[MB_CUSTOM][i] : funcs[ball_type[i]]
        ) func(dist, charges[i], additional[i], rotmatrix[i], rcutoff[i])
    ]
) sum(contrib);


// Function&Module: metaballs()
// Synopsis: Creates a model of metaballs within a bounding box.
// SynTags: Geom,VNF
// Topics: Metaballs, Isosurfaces, VNF Generators
// See Also: isosurface_array()
// Usage: As a module
//   metaballs(voxel_size, bounding_box, isovalue, ball_centers, [ball_sizes=], [ball_type=], [rotation=], [field_function=], [radial_cutoff=], [close_clip=], [show_stats=]);
// Usage: As a function
//   vnf = metaballs(voxel_size, bounding_box, isovalue, ball_centers, [ball_sizes=], [ball_type=], [rotation=], [field_function=], [radial_cutoff=], [close_clip=], [show_stats=]);
// Description:
//   [Metaballs](https://en.wikipedia.org/wiki/Metaballs), also known as "blobby objects",
//   are organic-looking ball-shaped blobs that meld together when in close proximity.
//   The melding property is determined by an interaction formula based on the "charge" of
//   each ball and their distance from one another. If you consider a "ball" to be a point
//   charge in 3D space, the electric field surrounding that charge decreases in intensity
//   with distance from the charge. The metaball is the isosurface corresponding to all value
//   where the electric field intensity is a constant value.
//   A stronger charge results in a stronger the electric field, and correspondingly a
//   larger metaball. Fields from two charges add together, changing the shape of the two
//   corresponding metaballs when they are in close proximity.
//   .
//   In physics, the electric field intensity falls off as an inverse-square relationship
//   with distance; that is, the field is proportional to $1/r^2$ where $r$ is the radial
//   distance from the point charge. However, most implementations of metaballs instead use
//   a simple inverse relationship proportional to $1/r$. That is true for the field
//   types available here, or you can define your own falloff function as the
//   `field_function` parameter.
//   .
//   Six shapes of fields around each metaball center are possible. You can specify
//   different types for each metaball in the list, and you can also specify your own
//   custom field equation. The five types are:
//   * `MB_SPHERE` - the standard spherical metaball with a 1/r field strength falloff.
//   * `MB_ELLIPSOID` - an ellipsoid-shaped field that requires specifying a [x,y,z] vector for the charge, representing field strength in each of the x, y, and z directions
//   * `MB_ROUNDCUBE` - a cube-shaped metaball with corners that get more rounded with size. The squareness can be controlled with a value between 0 (spherical) or 1 (cubical) in the `additional` parameter, and defaults to 0.5 if omitted.
//   * `MB_CUBE` - a cube-shaped metaball with sharp edges and corners, resulting from using [Chebyshev distance](https://en.wikipedia.org/wiki/Chebyshev_distance) rather than Euclidean distance calculations. 
//   * `MB_OCTAHEDRON` - an octahedron-shaped metaball with sharp edges and corners, resulting from using [taxicab distance](https://en.wikipedia.org/wiki/Taxicab_geometry) rather than Euclidean distance calculations.
//   * `MB_TORUS` - a toroidal field oriented perpendicular to the x, y, or z axis. The `charge` is a two-element vector determining the major and minor diameters, and the `additional` paramater sets the axis directions for each ball center (defaults to [0,0,1] if not set).
//   * `MB_CUSTOM` - your own custom field definition, requiring you to set the `field_function` parameter to your own function literal.
//   If either `MB_ELLIPSOID` or `MB_TORUS` occur in the list, the list of charges **must** be explicitly defined rather than supplying a single value for all.
// Arguments:
//   voxel_size = The size (scalar) of the voxel cube that determines the resolution of the metaball surface.
//   bounding_box = A pair of 3D points `[[xmin,ymin,zmin], [xmax,ymax,zmax]]`, specifying the minimum and maximum box corner coordinates. The voxels needn't fit perfectly inside the bounding box.
//   isovalue = A scalar value specifying the isosurface value of the metaballs.
//   ball_centers = an array of 3D points specifying each of the metaball centers.
//   ---
//   charge = a single value, or an array of values corresponding to `ball_centers`, specifying the charge intensity of each ball center. Default: 10
//   ball_type = shape of field that falls off from the metaball center. Can be one of `MB_SPHERE`, `MB_ELLIPSOID`, `MB_ROUNDCUBE`, `MB_CUBE`, `MB_OCTAHEDRON`, `MB_TORUS`, or `MB_CUSTOM`.  This may be an array of values corresponding to each ball. Where this value is `MB_CUSTOM`, the corresponding array element in `field_function` must also be set. Default: `_MB_SPHERE`
//   rotation = A vector `[x_rotation, y_rotation, z_rotation]`, or list of vectors for each ball, specifying the rotation angle in degrees around the x, y, and z axes. This is meaningless for `_MB_SPHERE` but allows you to orient the other metaball types. Default: undef
//   field_function = A single [function literal](https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/User-Defined_Functions_and_Modules#Function_literals) or array of function literals that return a single field value from one metaball, and takes as inputs a 3D distance vector, a single charge or list of charges, and a single additional parameter or list of parameters (that third parameter must exist in the function definition even if it isn't used). If the corresponding `ball_type` parameter is not `MB_CUSTOM`, then the function specified in `ball_type` is used instead; only where `ball_type` is `MB_CUSTOM` does this custom field function get invoked. Default: undef
//   additional = A single value, or a list of optional additional parameters that may be required by the field function. If you make a custom function, it is your responsibility to create a function literal compatible with these inputs. Nothing is passed to the function literal if `additional` is not set. This parameter must be specified as an entire list for all metaballs if MB_ELLIPSOID or MB_TORUS is included in `ball_type`. Default: `undef` for `ball_type=CUSTOM`
//   radial_cutoff = Maximum radial distance of a metaball's influence. This isn't a sharp cutoff; rather, the suppression increases with distance until the influence is zero at the `radial_cutoff` distance. Can be a single value or an array of values corresponding to each ball center, but typically it's sufficient to supply a single value approximately the average separation of each ball, so each ball mostly acts on its nearest neighbors. Default: INF
//   close_clip = When true, maintains a manifold surface where the bounding box clips it (there is a negligible speed penalty in doing this). When false, the bounding box clips the surface, exposing the back sides of facets. Setting this to false can be useful with OpenSCAD's "View > Thrown together" menu option to distinguish inside from outside. Default: true
//   show_stats = If true, display statistics about the metaball isosurface in the console window. Besides the number of voxels found to contain the surface, and the number of triangles making up the surface, this is useful for getting information about a smaller bounding box possible, to improve speed for subsequent renders. Enabling this parameter has a speed penalty. Default: false
// Example(3D,NoAxes): A group of five spherical metaballs with different charges. The parameter `show_stats=true` (not shown here) was used to find a compact bounding box for this figure.
//   centers = [[-20,-20,-20], [-0,-20,-20],
//              [0,0,0], [0,0,20], [20,20,10] ];
//   charges = [5, 4, 3, 5, 7];
//   type = MB_SPHERE;
//   isovalue = 1;
//   voxelsize = 1.5;
//   boundingbox = [[-30,-31,-31], [32,31,31]];
//   metaballs(voxelsize, boundingbox, isovalue=isovalue,
//       ball_centers=centers, charge=charges, ball_type=type);
// Example(3D,NoAxes): A metaball can have negative charge. In this case we have two metaballs in close proximity, with the small negative metaball creating a dent in the large positive one. The positive metaball is shown transparent, and small spheres show the center of each metaball. The negative metaball isn't visible because its field is negative; the isosurface encloses only field values greater than the isovalue of 1.
//   centers = [[-1,0,0], [1.25,0,0]];
//   charges = [8, -3];
//   type = MB_SPHERE;
//   voxelsize = 0.25;
//   isovalue = 1;
//   boundingbox = [[-7,-6,-6], [3,6,6]];
//   
//   #metaballs(voxelsize, boundingbox, isovalue=isovalue,
//       ball_centers=centers, charge=charges, ball_type=type);
//   color("green") for(c=centers) translate(c) sphere(d=1, $fn=16);
// Example(3D,NoAxes): A cube, a rounded cube, and an octahedron interacting.
//   centers = [[-7,-3,27], [7,5,21], [10,0,10]];
//   charge = 5;
//   type = [MB_CUBE, MB_ROUNDCUBE, MB_OCTAHEDRON];
//   voxelsize = 0.4; // a bit slow at this resolution
//   isovalue = 1;
//   boundingbox = [[-13,-9,3], [16,11,33]];
//   
//   metaballs(voxelsize, boundingbox, isovalue=isovalue,
//       ball_centers=centers, charge=charge, ball_type=type);
// Example(3D,NoAxes): Interaction between two torus-shaped fields in different orientations.
//   centers = [[-10,0,17], [7,6,21]];
//   charges = [[6,2], [7,3]];
//   type = MB_TORUS;
//   axis_orient = [[0,0,1], [0,1,0]];
//   voxelsize = 0.5;
//   isovalue = 1;
//   boundingbox = [[-19,-9,9], [18,10,32]];
//   
//   metaballs(voxelsize, boundingbox, isovalue=isovalue,
//      ball_centers=centers, charge=charges, ball_type=type,
//      additional=axis_orient);
// Example(3D): Demonstration of a custom metaball function, in this case a sphere with some random noise added to its electric field.
//   noisy_sphere = function (cdist, charge, additional,
//                   rotation_matrix_unused, rcutoff=INF)
//       let(
//           r = norm(cdist) + rands(0, 0.2, 1)[0],
//           suppress = let(a=min(r,rcutoff)/rcutoff) 1-a*a
//       ) r==0 ? 1000*charge : suppress*charge / r;
//   
//   centers = [[-9,0,0], [9,0,0]];
//   charge = 5;
//   type = [MB_SPHERE, MB_CUSTOM];
//   fieldfuncs = [undef, noisy_sphere];
//   voxelsize = 0.4;
//   boundingbox = [[-16,-8,-8], [16,8,8]];
//   
//   metaballs(voxelsize, boundingbox, isovalue=1,
//       ball_centers=centers, charge=charge, ball_type=type,
//       field_function=fieldfuncs);
// Example(3D,Med,NoAxes,VPR=[55,0,0],VPD=200,VPT=[7,2,2]): A complex example using ellipsoids, spheres, and a torus to make a tetrahedral object with rounded feet and a ring on top. The bottoms of the feet are flattened by limiting the minimum z value of the bounding box. The center of the object is thick due to the contributions of four ellipsoids converging. Designing an object like this using metaballs requires trial and error with low-resolution renders.
//   ztheta = 90-acos(-1/3);
//   cz = cos(ztheta);
//   sz = sin(ztheta);
//   type = [
//       MB_ELLIPSOID, MB_ELLIPSOID,
//       MB_ELLIPSOID, MB_ELLIPSOID,
//       MB_TORUS, MB_SPHERE, MB_SPHERE, MB_SPHERE
//   ];
//   centers = [
//       [0,0,20], [20*cz,0,20*sz],
//       zrot(120, p=[20*cz,0,20*sz]),
//       zrot(-120, p=[20*cz,0,20*sz]),
//       [0,0,35],  [32*cz,0,32*sz],
//       zrot(120, p=[32*cz,0,32*sz]),
//       zrot(-120, p=[32*cz,0,32*sz])];
//   cutoff = 40; // extent of influence of each ball
//   rotation = [
//       [0,90,0], [0,-ztheta,0], [0,-ztheta,120], [0,-ztheta,-120],
//       [0,0,0], undef, undef, undef];
//   axis = [
//       undef, undef, undef, undef,
//       [0,1,0], undef, undef, undef
//   ];
//   charge = [
//       [6,2,2], [7,2,2], [7,2,2], [7,2,2],
//       [8,2], 5, 5, 5
//   ];
//   
//   voxelsize = 1;
//   isovalue = 1;
//   boundingbox = [[-23,-36,-15], [39,36,46]];
//   
//   // useful to save as VNF for copies and manipulations
//   vnf = metaballs(voxelsize, boundingbox, isovalue=isovalue, ball_centers=centers,
//       charge=charge, ball_type=type, additional=axis, rotation=rotation,
//       radial_cutoff=cutoff);
//   vnf_polyhedron(vnf);

module metaballs(voxel_size, bounding_box, isovalue, ball_centers, charge=10, ball_type=MB_SPHERE, rotation=undef, field_function=undef, additional=undef, radial_cutoff=INF, close_clip=true, show_stats=false) {
        vnf = metaballs(voxel_size, bounding_box, isovalue, ball_centers, charge, ball_type, rotation, field_function, additional, radial_cutoff, close_clip, show_stats);
        vnf_polyhedron(vnf);
}

function metaballs(voxel_size, bounding_box, isovalue, ball_centers, charge=10, ball_type=MB_SPHERE, rotation=undef, field_function=undef, additional=undef, radial_cutoff=INF, close_clip=true, show_stats=false) = let(
    isoval = is_vector(isovalue) ? isovalue[0] : isovalue,
    nballs = len(ball_centers),
    chg = is_list(charge) ? charge : repeat(charge, nballs),
    interact = is_list(ball_type) ? ball_type : repeat(ball_type, nballs),
    rotations = is_list(rotation) ? rotation : repeat(rotation, nballs),
    fieldfuncs = is_list(field_function) ? field_function : repeat(field_function, nballs),
    addl0 = is_list(additional) ? additional : repeat(additional, nballs),
    rlimit = is_list(radial_cutoff) ? radial_cutoff : repeat(radial_cutoff, nballs)
)
    assert(all_defined([voxel_size, bounding_box, isovalue, ball_centers]), "\nThe parameters voxel_size, bounding_box, isovalue, and ball centers must all be defined.")
    assert(is_list(ball_centers), "\nball_centers must be a list of [x,y,z] coordinates; for a single value use [[x,y,z]].")
    assert(len(chg)==nballs, "\nThe list of charges must be equal in length to the list of ball_centers.")
    assert(len(interact)==nballs, "\nThe list of ball_types must be equal in length to the list of ball centers.")
    assert(len(rotations)==nballs, "\nThe list of rotation vectors must be equal in length to the list of ball centers.")
    assert(len(fieldfuncs)==nballs, "\nThe list of field_functions must be equal in length to the list of ball centers.")
    assert(len(addl0)==nballs, "\nThe list of additional field function parameters must be equal in length to the list of ball centers.")
    assert(len(rlimit)==nballs, "\nThe radial_cutoff list must be equal in length to the list of ball_centers.")
let(
    dum_align = _metaball_errchecks(nballs, interact, chg, addl0, fieldfuncs),

    // change MB_ROUNDCUBE squareness to exponents
    addl = [
        for(i=[0:nballs-1])
            if (interact[i]==MB_ROUNDCUBE)
                _squircle_se_exponent(addl0[i]==undef ? 0.5 : addl0[i])
            else if (interact[i]==MB_TORUS)
                addl0[i]==undef ? [0,0,1] : addl0[i]
            else
                addl0[i]
    ],

    // set up rotation matrices in advance
    rotmatrix = [
        for(i=[0:nballs-1])
            rotations[i]==undef ? rot([0,0,0]) : rot(rotations[i])
    ],

    //set up function call array
    funcs = [
        _metaball_sphere,       //MB_SPHERE
        _metaball_ellipsoid,    //MB_ELLIPSOID
        _metaball_roundcube,    //MB_ROUNDCUBE
        _metaball_cube,         //MB_CUBE
        _metaball_octahedron,   //MB_OCTAHEDRON
        _metaball_torus,        //MB_TORUS
        fieldfuncs              //MB_CUSTOM
    ],

    // set up field array
    v0 = bounding_box[0],
    b1 = bounding_box[1],
    halfvox = 0.5*voxel_size,
    fieldarray = [
        for(x=[v0[0]:voxel_size:b1[0]+halfvox]) [
            for(y=[v0[1]:voxel_size:b1[1]+halfvox]) [
                for(z=[v0[2]:voxel_size:b1[2]+halfvox])
                    _metaball_fieldfunc([x,y,z], nballs, ball_centers, chg, interact, rotmatrix, addl, rlimit, funcs)
            ]
        ]
    ]
) isosurface_array(voxel_size, isovalue, fieldarray, origin=v0, close_clip=close_clip, show_stats=show_stats);


function _metaball_errchecks(nballs, interact, charge, addl0, fieldfuncs) = [
for(i=[0:nballs-1]) let(
    dumm0 = assert(interact[i] != MB_ELLIPSOID || (interact[i]==MB_ELLIPSOID && is_vector(charge[i]) && len(charge[i])==3), "\nThe MB_ELLIPSOID charge value must be a vector of three numbers.") 0,
    dumm1 = assert(interact[i] != MB_ROUNDCUBE || (interact[i]==MB_ROUNDCUBE && (is_undef(addl0[i]) || (is_num(addl0[i]) && 0<=addl0[i] && addl0[i]<=1))), "\nFor MB_ROUNDCUBE, additional parameter must be undef or a single number between 0.0 and 1.0.") 0,
    dumm2 = assert(interact[i] != MB_TORUS || (interact[i]==MB_TORUS && is_vector(charge[i]) && len(charge[i])==2), "\nThe MB_TORUS charge value must be a vector of two numbers representing major and minor charges.") 0,
    dumm4 = assert(interact[i] != MB_TORUS || (interact[i]==MB_TORUS && (addl0[i]==undef || (norm(addl0[i])==1 && sum(addl0[i])==1))), str("\nMB_TORUS ", i, " additional parameters (", addl0[i], ") must be a unit vector in the x, y, or z direction only.")) 0,
    dumm5 = assert(interact[i] != MB_CUSTOM  || (interact[i]==MB_CUSTOM && is_def(fieldfuncs[i])), "\nThe MB_CUSTOM ball_type requires a field_function to be defined.") 0
    ) 0
];
