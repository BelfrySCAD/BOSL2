//////////////////////////////////////////////////////////////////////
// LibFile: polyhedra.scad
//   Generate Platonic solids, Archimedian solids, Catalan polyhedra, the trapezohedron, and some stellated polyhedra.
//   You can also stellate any of the polyhedra, select polyhedra by their characterics and position objects on polyhedra faces. 
// Includes:
//   include <BOSL2/std.scad>
//   include <BOSL2/polyhedra.scad>
// FileGroup: Parts
// FileSummary: Platonic, Archimidean, Catalan, and stellated polyhedra
//////////////////////////////////////////////////////////////////////


// CommonCode:
//   $fn=96;


// Section: Polyhedra


// Groups entries in "arr" into groups of equal values and returns index lists of those groups

function _unique_groups(m) = [
    for (i=[0:1:len(m)-1]) let(
        s = search([m[i]], m, 0)[0]
    ) if (s[0]==i) s
];


// TODO
//
// Use volume info?
// Support choosing a face number down
// Support multiple inspheres/outspheres when appropriate?
// face order for children?
// orient faces so an edge is parallel to the x-axis
//


// Module: regular_polyhedron()
// Synopsis: Creates a regular polyhedron with optional rounding.
// SynTags: Geom
// Topics: Polyhedra, Shapes, Parts
// See Also: regular_polyhedron_info()
// Usage: Selecting a polyhedron
//   regular_polyhedron([name],[index=],[type=],[faces=],[facetype=],[hasfaces=],...) [CHILDREN];
// Usage: Controlling the size and position of the polyhedron
//   regular_polyhedron(..., [or=|r=|d=],[ir=],[mr=],[side=],[facedown=],[anchor=], ...) [CHILDREN];]
// Usage: Other options that change the polyhedron or handling of children
//   regular_polyhedron(..., [draw=], [rounding=], [stellate=], [repeat=], [rotate_children=]) [CHILDREN];
// Usage: options only for the trapezohedron
//   regular_polyhedron("trapezohedron", [longside=],[h=], ...) [CHILDREN];
// Description:
//   Creates a regular polyhedron with optional rounding.  Children are placed on the polyhedron's faces.  (Note that this is not attachable.)
//   The regular_polyhedron module knows about many different regular and semi-regular polyhedra.  You can refer to them
//   by name.  The complete list with their names appears below in the examples.  You can also search the polyhedra
//   for ones that meet various critera using `type=`, `faces=`, `facetype=` or `hasfaces=`.  This will result in a list of polyhedra in a
//   canonical order that might include several options.  By default if you give specifications that produce several polyhedra, the first
//   one will be returned.  You can use the `index=` argument to select others from your list of hits.  Examples of polyhedron selection appear
//   after the full list of polyhedra below.  
//   .
//   **Selecting the polyhedron:**
//   You constrain the polyhedra list by specifying different characteristics, that must all be met
//   * `name`: e.g. `"dodecahedron"` or `"pentagonal icositetrahedron"`.  The name fully identifies the polyhedron, so no other characteristic should be given.
//   * `type`: Options are `"platonic"`, `"archimedean"` and `"catalan"`
//   * `faces`: The required number of faces
//   * `facetype`: The required face type(s).  List of vertex counts for the faces.  Exactly the listed types of faces must appear:
//     * `facetype = 3`: polyhedron with all triangular faces.
//     * `facetype = [5,6]`: polyhedron with only pentagons and hexagons. (Must have both!)
//   * hasfaces: The list of vertex counts for faces; at least one listed type must appear:
//     * `hasfaces = 3`: polygon has at least one triangular face
//     * `hasfaces = [5,6]`: polygon has a hexagonal or a pentagonal face
//   .
//   The result is a list of selected polyhedra.  You then specify `index` to choose which one of the
//   remaining polyhedra you want.  If you don't give `index` the first one on the list is created.
//   Two examples:
//   * `faces=12, index=2`:  Creates the 3rd solid with 12 faces
//   * `type="archimedean", faces=14`: Creates the first archimedean solid with 14 faces (there are 3)
//   .
//   **Choosing the size of your polyhedron:**
//   The default is to create a polyhedron whose smallest edge has length 1.  You can specify the
//   smallest edge length with the size option.  Alternatively you can specify the size of the
//   inscribed sphere, midscribed sphere, or circumscribed sphere using `ir`, `mr` and `cr` respectively.
//   If you specify `cr=3` then the outermost points of the polyhedron will be 3 units from the center.
//   If you specify `ir=3` then the innermost faces of the polyhedron will be 3 units from the center.
//   For the platonic solids every face meets the inscribed sphere and every corner touches the
//   circumscribed sphere.  For the Archimedean solids the inscribed sphere will touch only some of
//   the faces and for the Catalan solids the circumscribed sphere meets only some of the corners.
//   .
//   **Orientation:**
//   Orientation is controled by the facedown parameter.  Set this to false to get the canonical orientation.
//   Set it to true to get the largest face oriented down.  If you set it to a number the module searches for
//   a face with the specified number of vertices and orients that face down.
//   .
//   **Rounding:**
//   If you specify the rounding parameter the module makes a rounded polyhedron by first creating an
//   undersized model and then expanding it with `minkowski()`.  This only produces the correct result
//   if the in-sphere contacts all of the faces of the polyhedron, which is true for the platonic, the
//   catalan solids and the trapezohedra but false for the archimedean solids.
//   .
//   **Children:**
//   The module places children on the faces of the polyhedron.  The child coordinate system is
//   positioned so that the origin is the center of the face.  If `rotate_children` is true (default)
//   then the coordinate system is oriented so the z axis is normal to the face, which lies in the xy
//   plane.  If you give `repeat=true` (default) the children are cycled through to cover all faces.
//   With `repeat=false` each child is used once.  You can specify `draw=false` to suppress drawing of
//   the polyhedron, e.g. to use for `difference()` operations.  The module sets various parameters
//   you can use in your children (see the side effects list below).
//   .
//   **Stellation:**
//   Technically stellation is an operation of shifting the polyhedron's faces to produce a new shape
//   that may have self-intersecting faces.  OpenSCAD cannot handle self-intersecting faces, so we
//   instead erect a pyramid on each face, a process technically referred to as augmentation.  The
//   height of the pyramid is given by the `stellate` argument.  If `stellate` is `false` or `0` then
//   no stellation is performed.  Otherwise stellate gives the pyramid height as a multiple of the
//   edge length.  A negative pyramid height can be used to perform excavation, where a pyramid is
//   removed from each face.
//   .
//   **Special Polyhedra:**
//   These can be selected only by name and may require different parameters, or ignore some standard
//   parameters.
//   * Trapezohedron: a family of solids with an even number of kite shaped sides.
//     One example of a trapezohedron is the d10 die, which is a 10 face trapezohedron.
//     You must specify exactly two of `side`, `longside`, `h` (or `height`), and `r` (or `d`).
//     You cannot create trapezohedron shapes using `mr`, `ir`, or `or`.
//     * `side`: Length of the short side.
//     * `longside`: Length of the long side that extends to the apex.
//     * `h` or `height`: Distance from the center to the apex.
//     * `r`: Radius of the polygon that defines the equatorial vertices.
//     * `d`: Diameter of the polygon that defines the equatorial vertices.
//   .
//   * Named stellations: various polyhedra such as three of the four Kepler-Poinsot solids are stellations with
//    specific pyramid heights.  To make them easier to generate you can specify them by name.
//    This is equivalent to giving the name of the appropriate base solid and the magic stellate
//    parameter needed to produce that shape.  The supported solids are:
//     * `"great dodecahedron"`
//     * `"small stellated dodecahedron"`
//     * `"great stellated dodecahedron"`
//     * `"small triambic icosahedron"` (not a Kepler-Poinsot solid)
//
// Arguments:
//   name = Name of polyhedron to create.
//   ---
//   type = Type of polyhedron: "platonic", "archimedean", "catalan".
//   faces = Number of faces.
//   facetype = Scalar or vector listing required type of faces as vertex count.  Polyhedron must have faces of every type listed and no other types.
//   hasfaces = Scalar of vector list face vertex counts.  Polyhedron must have at least one of the listed types of face.
//   index = Index to select from polyhedron list.  Default: 0.
//   side = Length of the smallest edge of the polyhedron.  Default: 1 (if no radius or diameter is given).  
//   ir = inner radius.  Polyhedron is scaled so it has the specified inner radius. 
//   mr = middle radius.  Polyhedron is scaled so it has the specified middle radius.  
//   or / r / d = outer radius.   Polyhedron is scaled so it has the specified outer radius. 
//   anchor = Side of the origin to anchor to.  The bounding box of the polyhedron is aligned as specified.  Default: `CENTER`
//   facedown = If false display the solid in native orientation.  If true orient it with a largest face down.  If set to a vertex count, orient it so a face with the specified number of vertices is down.  Default: true.
//   rounding = Specify a rounding radius for the shape.  Note that depending on $fn the dimensions of the shape may have small dimensional errors.
//   repeat = If true then repeat the children to fill all the faces.  If false use only the available children and stop.  Default: true.
//   draw = If true then draw the polyhedron.  If false, draw the children but not the polyhedron.  Default: true.
//   rotate_children = If true then orient children normal to their associated face.  If false orient children to the parent coordinate system.  Default: true.
//   stellate = Set to a number to erect a pyramid of that height on every face of your polyhedron.  The height is a multiple of the side length.  Default: false.
//   longside = Specify the long side length for a trapezohedron.  Invalid for other shapes.
//   h = Specify the height of the apex for a trapezohedron.  Invalid for other shapes.
//
// Side Effects:
//   `$faceindex` - Index number of the face
//   `$face` - Coordinates of the face (2d if rotate_children==true, 3d if not)
//   `$center` - Face center in the child coordinate system
//
// Examples: All of the available polyhedra by name in their native orientation
//   regular_polyhedron("tetrahedron", facedown=false);
//   regular_polyhedron("cube", facedown=false);
//   regular_polyhedron("octahedron", facedown=false);
//   regular_polyhedron("dodecahedron", facedown=false);
//   regular_polyhedron("icosahedron", facedown=false);
//   regular_polyhedron("truncated tetrahedron", facedown=false);
//   regular_polyhedron("truncated octahedron", facedown=false);
//   regular_polyhedron("truncated cube", facedown=false);
//   regular_polyhedron("truncated icosahedron", facedown=false);
//   regular_polyhedron("truncated dodecahedron", facedown=false);
//   regular_polyhedron("cuboctahedron", facedown=false);
//   regular_polyhedron("icosidodecahedron", facedown=false);
//   regular_polyhedron("rhombicuboctahedron", facedown=false);
//   regular_polyhedron("rhombicosidodecahedron", facedown=false);
//   regular_polyhedron("truncated cuboctahedron", facedown=false);
//   regular_polyhedron("truncated icosidodecahedron", facedown=false);
//   regular_polyhedron("snub cube", facedown=false);
//   regular_polyhedron("snub dodecahedron", facedown=false);
//   regular_polyhedron("triakis tetrahedron", facedown=false);
//   regular_polyhedron("tetrakis hexahedron", facedown=false);
//   regular_polyhedron("triakis octahedron", facedown=false);
//   regular_polyhedron("pentakis dodecahedron", facedown=false);
//   regular_polyhedron("triakis icosahedron", facedown=false);
//   regular_polyhedron("rhombic dodecahedron", facedown=false);
//   regular_polyhedron("rhombic triacontahedron", facedown=false);
//   regular_polyhedron("deltoidal icositetrahedron", facedown=false);
//   regular_polyhedron("deltoidal hexecontahedron", facedown=false);
//   regular_polyhedron("disdyakis dodecahedron", facedown=false);
//   regular_polyhedron("disdyakis triacontahedron", facedown=false);
//   regular_polyhedron("pentagonal icositetrahedron", facedown=false);
//   regular_polyhedron("pentagonal hexecontahedron", facedown=false);
//   regular_polyhedron("trapezohedron",faces=10, side=1, longside=2.25, facedown=false);
//   regular_polyhedron("great dodecahedron");
//   regular_polyhedron("small stellated dodecahedron");
//   regular_polyhedron("great stellated dodecahedron");
//   regular_polyhedron("small triambic icosahedron");
// Example: Third Archimedean solid
//   regular_polyhedron(type="archimedean", index=2);
// Example(Med): Solids that have at least one face with either 8 vertices or 10 vertices
//   N = len(regular_polyhedron_info("index set", hasfaces=[8,10]));
//   for(i=[0:N-1]) right(3*i)
//     regular_polyhedron(hasfaces=[8,10], index=i, mr=1);
// Example(Big): Solids that include a quadrilateral face
//   N = len(regular_polyhedron_info("index set", hasfaces=4));
//   for(i=[0:N-1]) right(3*i)
//     regular_polyhedron(hasfaces=4, index=i, mr=1);
// Example(Med): Solids with only quadrilateral faces
//   N = len(regular_polyhedron_info("index set", facetype=4));
//   for(i=[0:N-1]) right(3*i)
//     regular_polyhedron(facetype=4, index=i, mr=1);
// Example: Solids that have both pentagons and hexagons and no other face types
//   N = len(regular_polyhedron_info("index set", facetype=[5,6]));
//   for(i=[0:N-1]) right(3*i)
//     regular_polyhedron(facetype=[5,6], index=i, mr=1);
// Example: Rounded octahedron
//   regular_polyhedron("octahedron", side=1, rounding=.2);
// Example: Rounded catalon solid
//   regular_polyhedron("rhombic dodecahedron", side=1, rounding=0.2);
// Example(Med): Rounded Archimedean solid compared to unrounded version.  The small faces are shifted back from their correct position.
//   %regular_polyhedron(type="archimedean", mr=1, rounding=0);
//   regular_polyhedron(type="archimedean", mr=1, rounding=0.3);
// Example: Two children are distributed arbitrarily over the faces
//   regular_polyhedron(faces=12,index=2,repeat=true) {
//     color("red") sphere(r=.1);
//     color("green") sphere(r=.1);
//   }
// Example(FlatSpin,VPD=100): Difference the children from the polyhedron; children depend on $faceindex
//   difference(){
//     regular_polyhedron("tetrahedron", side=25);
//     regular_polyhedron("tetrahedron", side=25,draw=false)
//       down(.3) linear_extrude(height=1)
//         text(str($faceindex),halign="center",valign="center");
//   }
// Example(Big): With `rotate_children` you can control direction of the children.
//   regular_polyhedron(name="tetrahedron", anchor=UP, rotate_children=true)
//     cylinder(r=.1, h=.5);
//   right(2) regular_polyhedron(name="tetrahedron", anchor=UP, rotate_children=false)
//     cylinder(r=.1, h=.5);
// Example(FlatSpin,Med,VPD=15): Using `$face` you can have full control of the construction of your children.  This example constructs the Great Icosahedron, the one Kepler-Poinsot solid that cannot be made directly with {{regular_polyhedron()}}.  
//   module makestar(pts) {    // Make a star from a point list
//       polygon(
//         [
//           for(i=[0:len(pts)-1]) let(
//             p0=select(pts,i),
//             p1=select(pts,i+1),
//             center=(p0+p1)/2,
//             v=sqrt(7/4-PHI)*(p1-p0)
//           ) each [p0, [v.y+center.x, -v.x+center.y]]
//         ]
//       );
//   }
//   regular_polyhedron("dodecahedron", side=1, repeat=true)
//   linear_extrude(scale=0, height=sqrt((5+2*sqrt(5))/5)) makestar($face);
// Example(Med): The spheres are all radius 1 and the octahedra are sized to match the in-sphere, mid-sphere and out-sphere.  The sphere size is slightly adjusted for the in-sphere and out-sphere so you can see the relationship: the sphere is tangent to the faces for the former and the corners poke out for the latter.  Note also the difference in the size of the three octahedra.
//   sphere(r=1.005);
//   %regular_polyhedron("octahedron", ir=1, facedown=false);
//   right(3.5) {
//     sphere(r=1);
//     %regular_polyhedron("octahedron", mr=1, facedown=false);
//   }
//   right(6.5) {
//     %sphere(r=.95);  // Slightly undersized sphere means the points poke out a bit
//     regular_polyhedron("octahedron", or=1,facedown=false);
//   }
// Example(Med): For the Archimdean solids the in-sphere does not touch all of the faces, as shown by this example, but the circumscribed sphere meets every vertex.  (This explains the problem for rounding over these solids because the rounding method uses the in-sphere.)
//   sphere(r=1.005);
//   %regular_polyhedron("snub dodecahedron", ir=1, facedown=false);
//   right(3) {
//     sphere(r=1);
//     %regular_polyhedron("snub dodecahedron", mr=1, facedown=false);
//   }
//   right(6) {
//     %sphere(r=.99);
//     regular_polyhedron("snub dodecahedron", or=1,facedown=false);
//   }
// Example(Med): For a Catalan solid the in-sphere touches every face but the circumscribed sphere only touches some vertices.
//   sphere(r=1.002);
//   %regular_polyhedron("pentagonal hexecontahedron", ir=1, facedown=false);
//   right(3) {
//     sphere(r=1);
//     %regular_polyhedron("pentagonal hexecontahedron", mr=1, facedown=false);
//   }
//   right(6) {
//     %sphere(r=.98);
//     regular_polyhedron("pentagonal hexecontahedron", or=1,facedown=false);
//   }
// Example: Stellate an Archimedian solid, which has mixed faces
//   regular_polyhedron("truncated icosahedron",stellate=1.5,or=1);
// Example: Stellate a Catalan solid where faces are not regular
//   regular_polyhedron("triakis tetrahedron",stellate=0.5,or=1);
module regular_polyhedron(
    name=undef,
    index=undef,
    type=undef,
    faces=undef,
    facetype=undef,
    hasfaces=undef,
    side=undef,
    ir=undef,
    mr=undef,
    or=undef,
    r=undef,
    d=undef,
    anchor=CENTER,
    rounding=0,
    repeat=true,
    facedown=true,
    draw=true,
    rotate_children=true,
    stellate = false,
    longside=undef,       // special parameter for trapezohedron
    h=undef,height=undef  // special parameter for trapezohedron
) {
    dummy=assert(is_num(rounding) && rounding>=0, "'rounding' must be nonnegative");
    entry = regular_polyhedron_info(
        "fullentry", name=name, index=index,
        type=type, faces=faces, facetype=facetype,
        hasfaces=hasfaces, side=side,
        ir=ir, mr=mr, or=or,
        r=r, d=d,
        anchor=anchor, 
        facedown=facedown,
        stellate=stellate,
        longside=longside, h=h, height=height
    );
    assert(len(entry)>0, "No polyhedra meet your specification");
    scaled_points = entry[0];
    translation = entry[1];
    face_triangles = entry[2];
    faces = entry[3];
    face_normals = entry[4];
    in_radius = entry[5];
    translate(translation){
        if (draw){
            if (rounding==0)
                polyhedron(scaled_points, faces = face_triangles);
            else {
                fn = segs(rounding);
                rounding = rounding/cos(180/fn);
                adjusted_scale = 1 - rounding / in_radius;
                minkowski(){
                    sphere(r=rounding, $fn=fn);
                    polyhedron(adjusted_scale*scaled_points, faces = face_triangles);
                }
            }
        }
        if ($children>0) {
            maxrange = repeat ? len(faces)-1 : $children-1;
            for(i=[0:1:maxrange]) {
                // Would like to orient so an edge (longest edge?) is parallel to x axis
                facepts = select(scaled_points, faces[i]);
                $center = -mean(facepts);
                cfacepts = move($center, p=facepts);
                $face = rotate_children
                          ? path2d(frame_map(z=face_normals[i], x=facepts[0]-facepts[1], reverse=true, p=cfacepts))
                          : cfacepts;
                $faceindex = i;
                translate(-$center)
                if (rotate_children) {
                    frame_map(z=face_normals[i], x=facepts[0]-facepts[1])
                    children(i % $children);
                } else {
                    children(i % $children);
                }
            }
        }
    }
}

/////////////////////////////////////////////////////////////////////////////
//
// Some internal functions used to generate polyhedra data
//
// All permutations and even permutations of three items
//
function _even_perms(v) = [v, [v[2], v[0], v[1]], [v[1],v[2],v[0]]];
function _all_perms(v) = [v, [v[2], v[0], v[1]], [v[1],v[2],v[0]], [v[1],v[0],v[2]],[v[2],v[1],v[0]],[v[0],v[2],v[1]]];
//
// Point reflections across all planes.    In the unconstrained case, this means one point becomes 8 points.
//
// sign=="even" means an even number of minus signs (odd number of plus signs)
// sign=="odd" means an odd number of minus signs (even number of plus signs)
//
function _point_ref(points, sign="both") =
    unique([
        for(i=[-1,1],j=[-1,1],k=[-1,1])
            if (sign=="both" || sign=="even" && i*j*k>0 || sign=="odd" && i*j*k<0)
                each [for(point=points) v_mul(point,[i,j,k])]
    ]);
//
_tribonacci=(1+4*cosh(acosh(2+3/8)/3))/3;
//
/////////////////////////////////////////////////////////////////////////////
//
// Polyhedra data table.
// The polyhedra information is from Wikipedia and http://dmccooey.com/polyhedra/
//
_polyhedra_ = [
    // Platonic Solids

    ["tetrahedron", "platonic", 4,[3], 2*sqrt(2), sqrt(6)/12, sqrt(2)/4, sqrt(6)/4, 1/6/sqrt(2),
            _point_ref([[1,1,1]], sign="even")],
    ["cube", "platonic", 6, [4], 2, 1/2, 1/sqrt(2), sqrt(3)/2, 1,
            _point_ref([[1,1,1]])],
    ["octahedron", "platonic", 8, [3], sqrt(2), sqrt(6)/6, 1/2, sqrt(2)/2, sqrt(2)/3,
            _point_ref(_even_perms([1,0,0]))],
    ["dodecahedron", "platonic", 12, [5], 2/PHI, sqrt(5/2+11*sqrt(5)/10)/2, (3+sqrt(5))/4, sqrt(3)*PHI/2, (15+7*sqrt(5))/4,
            _point_ref(concat([[1,1,1]],_even_perms([0,PHI,1/PHI])))],
    ["icosahedron", "platonic", 20, [3], 2, PHI*PHI/2/sqrt(3), cos(36), sin(72), 5*(3+sqrt(5))/12,
            _point_ref(_even_perms([0,1,PHI]))],

    // Archimedian Solids, listed in order by Wenniger number, W6-W18

    ["truncated tetrahedron", "archimedean", 8,[6,3], sqrt(8), sqrt(6)/4, 3*sqrt(2)/4, sqrt(11/8), 23*sqrt(2)/12,
            _point_ref(_all_perms([1,1,3]),sign="even")],
    ["truncated octahedron", "archimedean", 14, [6,4], sqrt(2), sqrt(6)/2, 1.5, sqrt(10)/2, 8*sqrt(2),
            _point_ref(_all_perms([0,1,2]))],
    ["truncated cube", "archimedean", 14, [8,3], 2*(sqrt(2)-1), (1+sqrt(2))/2, 1+sqrt(2)/2, sqrt(7+4*sqrt(2))/2, 7+14*sqrt(2)/3,
            _point_ref(_all_perms([1,1,sqrt(2)-1]))],
    ["truncated icosahedron", "archimedean", 32, [6, 5], 2, (3*sqrt(3)+sqrt(15))/4, 3*PHI/2, sqrt(58+18*sqrt(5))/4, (125+43*sqrt(5))/4,
            _point_ref(concat(
                _even_perms([0,1,3*PHI]),
                _even_perms([1,2+PHI,2*PHI]),
                _even_perms([PHI,2,PHI*PHI*PHI])
            ))],
    ["truncated dodecahedron", "archimedean", 32, [10, 3], 2*PHI-2, sqrt(7+11*PHI)/2, (3*PHI+1)/2,sqrt(11+PHI*15)/2, 5*(99+47*sqrt(5))/12,
            _point_ref(concat(
                _even_perms([0,1/PHI, 2+PHI]),
                _even_perms([1/PHI,PHI,2*PHI]),
                _even_perms([PHI,2,PHI+1])
            ))],
    ["cuboctahedron", "archimedean", 14, [4,3], sqrt(2), sqrt(2)/2, sqrt(3)/2, 1, 5*sqrt(2)/3,
            _point_ref(_all_perms([1,1,0]))],
    ["icosidodecahedron", "archimedean", 32, [5,3], 1, sqrt(5*(5+2*sqrt(5)))/5,sqrt(5+2*sqrt(5))/2, PHI, (14+17*PHI)/3,
            _point_ref(concat(_even_perms([0,0,PHI]),_even_perms([1/2,PHI/2,PHI*PHI/2])))],
    ["rhombicuboctahedron", "archimedean", 26, [4, 3], 2, (1+sqrt(2))/2, sqrt(2*(2+sqrt(2)))/2, sqrt(5+2*sqrt(2))/2, 4+10*sqrt(2)/3,
            _point_ref(_even_perms([1,1,1+sqrt(2)]))],
    ["rhombicosidodecahedron", "archimedean", 62, [5,4,3], 2, 3/10*sqrt(15+20*PHI), sqrt(3/2+2*PHI), sqrt(8*PHI+7)/2, (31+58*PHI)/3,
            _point_ref(concat(
                _even_perms([1,1,PHI*PHI*PHI]),
                _even_perms([PHI*PHI,PHI,2*PHI]),
                _even_perms([2+PHI,0,PHI*PHI])
            ))],
    ["truncated cuboctahedron", "archimedean", 26, [8, 6, 4], 2, (1+2*sqrt(2))/2, sqrt(6*(2+sqrt(2)))/2, sqrt(13+6*sqrt(2))/2, (22+14*sqrt(2)),
            _point_ref(_all_perms([1,1+sqrt(2), 1+2*sqrt(2)]))],
    ["truncated icosidodecahedron", "archimedean", 62, [10,6,4], 2*PHI - 2, sqrt(15/4+5*PHI),sqrt(9/2+6*PHI),sqrt(19/4+6*PHI), 95+50*sqrt(5),
            _point_ref(concat(
                _even_perms([1/PHI,1/PHI,3+PHI]),
                _even_perms([2/PHI,PHI,1+2*PHI]),
                _even_perms([1/PHI,PHI*PHI,3*PHI-1]),
                _even_perms([2*PHI-1,2,2+PHI]),
                _even_perms([PHI,3,2*PHI])
            ))],
    ["snub cube", "archimedean",    38, [4,3], 1.60972,1.14261350892596209,1.24722316799364325, 1.34371337374460170,
            sqrt((613*_tribonacci+203)/(9*(35*_tribonacci-62))),
            concat(
                _point_ref(_even_perms([1,1/_tribonacci,_tribonacci]), sign="odd"),
                _point_ref(_even_perms([1,_tribonacci,1/_tribonacci]), sign="even")
            )],
    ["snub dodecahedron", "archimedean", 92, [5, 3], 1, 1.98091594728184,2.097053835252087,2.155837375115, 37.61664996273336,
            concat(
                _point_ref(_even_perms([0.374821658114562,0.330921024729844,2.097053835252088]), sign="odd"),
                _point_ref(_even_perms([0.192893711352359,1.249503788463027,1.746186440985827]), sign="odd"),
                _point_ref(_even_perms([1.103156835071754,0.847550046789061,1.646917940690374]), sign="odd"),
                _point_ref(_even_perms([0.567715369466922,0.643029605914072,1.977838965420219]), sign="even"),
                _point_ref(_even_perms([1.415265416255982,0.728335176957192,1.454024229338015]), sign="even")
            )],

    // Catalan Solids, the duals to the Archimedean solids, listed in the corresponding order

    ["triakis tetrahedron","catalan", 12, [3], 9/5, 5*sqrt(22)/44, 5*sqrt(2)/12, 5*sqrt(6)/12, 25*sqrt(2)/36,
            concat(
                _point_ref([9*sqrt(2)/20*[1,1,1]],sign="even"),
                _point_ref([3*sqrt(2)/4*[1,1,1]],sign="odd")
            )],
    ["tetrakis hexahedron", "catalan", 24, [3], 1, 2/sqrt(5), 2*sqrt(2)/3, 2/sqrt(3), 32/9,
            _point_ref(concat([[2/3,2/3,2/3]],_even_perms([1,0,0])))],
    ["triakis octahedron", "catalan", 24, [3], 2, sqrt(17*(23+16*sqrt(2)))/34, 1/2+sqrt(2)/4,(1+sqrt(2))/2,3/2+sqrt(2),
            _point_ref(concat([[1,1,1]],_even_perms([1+sqrt(2),0,0])))],
    ["pentakis dodecahedron", "catalan", 60, [3], 1,sqrt(477/436+97*sqrt(5)/218), sqrt(5)/4+11/12, sqrt(7/4+sqrt(5)/3), 125*sqrt(5)/36+205/36,
            _point_ref(concat(
                _even_perms([0,(5-PHI)/6, PHI/2+2/3]),
                _even_perms([0,(PHI+1)/2,PHI/2]),[(4*PHI-1)/6 * [1,1,1]]
            ))],
    ["triakis icosahedron", "catalan", 60, [3], 1, sqrt((139+199*PHI)/244), (8*PHI+1)/10, sqrt(13/8+19/8/sqrt(5)), (13*PHI+3)/2,
            _point_ref(concat(
                _even_perms([(PHI+7)/10, 0, (8*PHI+1)/10]),
                _even_perms([0, 1/2, (PHI+1)/2]),[PHI/2*[1,1,1]]
            ))],
    ["rhombic dodecahedron", "catalan", 12, [4], sqrt(3), sqrt(2/3), 2*sqrt(2)/3, 2/sqrt(3), 16*sqrt(3)/9,
            _point_ref(concat([[1,1,1]], _even_perms([2,0,0])))],
    ["rhombic triacontahedron", "catalan", 30,[4], 1, sqrt(1+2/sqrt(5)), 1+1/sqrt(5), (1+sqrt(5))/2, 4*sqrt(5+2*sqrt(5)),
            concat(
                _point_ref(_even_perms([0,sqrt(1+2/sqrt(5)), sqrt((5+sqrt(5))/10)])),
                _point_ref(_even_perms([0,sqrt(2/(5+sqrt(5))), sqrt(1+2/sqrt(5))])),
                _point_ref([sqrt((5+sqrt(5))/10)*[1,1,1]])
            )],
    ["deltoidal icositetrahedron", "catalan", 24, [4], 2*sqrt(10-sqrt(2))/7, 7*sqrt((7+4*sqrt(2))/(34 * (10-sqrt(2)))),
            7*sqrt(2*(2+sqrt(2)))/sqrt(10-sqrt(2))/4, 7*sqrt(2)/sqrt(10-sqrt(2))/2,
            (14+21*sqrt(2))/sqrt(10-sqrt(2)),
            _point_ref(concat(
                _even_perms([0,1,1]), _even_perms([sqrt(2),0,0]),
                _even_perms((4+sqrt(2))/7*[1,1,1])
            ))],
    ["deltoidal hexecontahedron", "catalan", 60, [4], sqrt(5*(85-31*sqrt(5)))/11, sqrt(571/164+1269/164/sqrt(5)), 5/4+13/4/sqrt(5),
            sqrt(147+65*sqrt(5))/6, sqrt(29530+13204*sqrt(5))/3,
            _point_ref(concat(
                _even_perms([0,0,sqrt(5)]),
                _even_perms([0,(15+sqrt(5))/22, (25+9*sqrt(5))/22]),
                _even_perms([0,(5+3*sqrt(5))/6, (5+sqrt(5))/6]),
                _even_perms([(5-sqrt(5))/4, sqrt(5)/2, (5+sqrt(5))/4]),
                [(5+4*sqrt(5))/11*[1,1,1]]
            ))],
    ["disdyakis dodecahedron", "catalan", 48, [3], 1,sqrt(249/194+285/194/sqrt(2)) ,(2+3*sqrt(2))/4, sqrt(183/98+213/98/sqrt(2)),
            sqrt(6582+4539*sqrt(2))/7,
            _point_ref(concat(
                _even_perms([sqrt(183/98+213/98/sqrt(2)),0,0]),
                _even_perms(sqrt(3+3/sqrt(2))/2 * [1,1,0]),[7/sqrt(6*(10-sqrt(2)))*[1,1,1]]
            ))],
    ["disdyakis triacontahedron","catalan", 120, [3], sqrt(15*(85-31*sqrt(5)))/11, sqrt(3477/964+7707/964/sqrt(5)), 5/4+13/4/sqrt(5),
            sqrt(441+195*sqrt(5))/10,sqrt(17718/5+39612/5/sqrt(5)),
            _point_ref(concat(
                _even_perms([0,0,3*(5+4*sqrt(5))/11]),
                _even_perms([0,(5-sqrt(5))/2,(5+sqrt(5))/2]),
                _even_perms([0,(15+9*sqrt(5))/10,3*(5+sqrt(5))/10]),
                _even_perms([3*(15+sqrt(5))/44,3*(5+4*sqrt(5))/22, (75+27*sqrt(5))/44]), [sqrt(5)*[1,1,1]]
            ))],
    ["pentagonal icositetrahedron","catalan",24, [5], 0.593465355971, 1.950681331784, 2.1015938932963, 2.29400105368695, 35.6302020120713,
            concat(
                _point_ref(_even_perms([0.21879664300048044,0.740183741369857,1.0236561781126901]),sign="even"),
                _point_ref(_even_perms([0.21879664300048044,1.0236561781126901,0.740183741369857]),sign="odd"),
                _point_ref(_even_perms([1.3614101519264425,0,0])),
                _point_ref([0.7401837413698572*[1,1,1]])
            )],
    ["pentagonal hexecontahedron", "catalan", 60,[5], 0.58289953474498, 3.499527848905764,3.597624822551189,3.80854772878239, 189.789852066885,
            concat(
                _point_ref(_even_perms([0.192893711352359,0.218483370127321,2.097053835252087]), sign="even"),
                _point_ref(_even_perms([0,0.7554672605165955,1.9778389654202186])),
                _point_ref(_even_perms([0,1.888445389283669154,1.1671234364753339])),
                _point_ref(_even_perms([0.56771536946692131,0.824957552676275846,1.8654013108176956657]),sign="odd"),
                _point_ref(_even_perms([0.37482165811456229,1.13706613386050418,1.746186440985826345]), sign="even"),
                _point_ref(_even_perms([0.921228888309550,0.95998770139158,1.6469179406903744]),sign="even"),
                _point_ref(_even_perms([0.7283351769571914773,1.2720962825758121,1.5277030708585051]),sign="odd"),
                _point_ref([1.222371704903623092*[1,1,1]])
            )],
];


_stellated_polyhedra_ = [
    ["great dodecahedron", "icosahedron", -sqrt(5/3-PHI)],
    ["small stellated dodecahedron", "dodecahedron", sqrt((5+2*sqrt(5))/5)],
    ["great stellated dodecahedron", "icosahedron", sqrt(2/3+PHI)],
    ["small triambic icosahedron", "icosahedron", sqrt(3/5) - 1/sqrt(3)]
];


// Function: regular_polyhedron_info()
// Synopsis: Returns info used to create a regular polyhedron.
// Topics: Polyhedra, Shapes, Parts
// See Also: regular_polyhedron()
//
// Usage:
//   info = regular_polyhedron_info(info, ...);
//
// Description:
//   Calculate characteristics of regular polyhedra or the selection set for regular_polyhedron().
//   Invoke with the same polyhedron selection and size arguments used by {{regular_polyhedron()}} and use the `info` argument to
//   request the desired return value. Set `info` to:
//     * `"vnf"`: vnf for the selected polyhedron
//     * `"vertices"`: vertex list for the selected polyhedron
//     * `"faces"`: list of faces for the selected polyhedron, where each entry on the list is a list of point index values to be used with the vertex list
//     * `"face normals"`: list of normal vectors for each face
//     * `"in_radius"`: in-sphere radius for the selected polyhedron
//     * `"mid_radius"`: mid-sphere radius for the selected polyhedron
//     * `"out_radius"`: circumscribed sphere radius for the selected polyhedron
//     * `"index set"`: index set selected by your specifications; use its length to determine the valid range for `index`.
//     * `"face vertices"`: number of vertices on the faces of the selected polyhedron (always a list)
//     * `"edge length"`: length of the smallest edge of the selected polyhedron
//     * `"center"`: center for the polyhedron
//     * `"type"`: polyhedron type, one of "platonic", "archimedean", "catalan", or "trapezohedron"
//     * `"name"`: name of selected polyhedron
//   If you specify an impossible selection of polyhedrons, then `[]` is returned.  
//
// Arguments:
//   info = Desired information to return for the polyhedron
//   name = Name of polyhedron to create.
//   ---
//   type = Type of polyhedron: "platonic", "archimedean", "catalan".
//   faces = Number of faces.
//   facetype = Scalar or vector listing required type of faces as vertex count.  Polyhedron must have faces of every type listed and no other types.
//   hasfaces = Scalar of vector list face vertex counts.  Polyhedron must have at least one of the listed types of face.
//   index = Index to select from polyhedron list.  Default: 0.
//   side = Length of the smallest edge of the polyhedron.  Default: 1 (if no radius or diameter is given).
//   or / r / d = outer radius.   Polyhedron is scaled so it has the specified outer radius or diameter. 
//   mr = middle radius.  Polyhedron is scaled so it has the specified middle radius.  
//   ir = inner radius.  Polyhedron is scaled so it has the specified inner radius. 
//   anchor = Side of the origin to anchor to.  The bounding box of the polyhedron is aligned as specified.  Default: `CENTER`
//   facedown = If false display the solid in native orientation.  If true orient it with a largest face down.  If set to a vertex count, orient it so a face with the specified number of vertices is down.  Default: true.
//   stellate = Set to a number to erect a pyramid of that height on every face of your polyhedron.  The height is a multiple of the side length.  Default: false.
//   longside = Specify the long side length for a trapezohedron.  Invalid for other shapes.
//   h = Specify the height of the apex for a trapezohedron.  Invalid for other shapes.
function regular_polyhedron_info(
    info=undef, name=undef,
    index=undef, type=undef,
    faces=undef, facetype=undef,
    hasfaces=undef, side=undef,
    ir=undef, mr=undef, or=undef,
    r=undef, d=undef,
    anchor=CENTER,
    facedown=true, stellate=false,
    longside=undef, h=undef, height=undef  // special parameters for trapezohedron
) = let(
        argcount = num_defined([side,ir,mr,or,r,d])
    )
    assert(name=="trapezohedron" || argcount<=1, "You must specify only one of 'side', 'ir', 'mr', 'or', 'r', and 'd'")
    assert(name!="trapezohedron" || num_defined([ir,mr,or])==0, "Trapezohedron does not accept 'ir', 'mr' or 'or'")
    let(  
        //////////////////////
        //Index values into the _polyhedra_ array
        //
        pname = 0,        // name of polyhedron
        class = 1,        // class name (e.g. platonic, archimedean)
        facecount = 2,    // number of faces
        facevertices = 3, // vertices on the faces, e.g. [3] for all triangles, [3,4] for triangles and squares
        edgelen = 4,      // length of the edge for the vertex list in the database
        in_radius = 5,    // in radius for unit polyhedron (shortest side 1)
        mid_radius = 6,   // mid radius for unit polyhedron
        out_radius = 7,   // out radius for unit polyhedron
        volume = 8,       // volume of unit polyhedron (data not validated, not used right now)
        vertices = 9,     // vertex list (in arbitrary order)
        //////////////////////
        or = get_radius(r=r,r1=or,d=d),
        stellate_index = search([name], _stellated_polyhedra_, 1, 0)[0],
        name = stellate_index==[] ? name : _stellated_polyhedra_[stellate_index][1],
        stellate = stellate_index==[] ? stellate : _stellated_polyhedra_[stellate_index][2],
        indexlist = (
            name=="trapezohedron" ? [0] : [  // dumy list of one item
                for(i=[0:1:len(_polyhedra_)-1]) (
                    if (
                        (is_undef(name) || _polyhedra_[i][pname]==name) &&
                        (is_undef(type) || _polyhedra_[i][class]==type) &&
                        (is_undef(faces) || _polyhedra_[i][facecount]==faces) &&
                        (
                            is_undef(facetype) || 0==compare_lists(
                                is_list(facetype)? reverse(sort(facetype)) : [facetype],
                                _polyhedra_[i][facevertices]
                            )
                        ) &&
                        (is_undef(hasfaces) || any([for (ft=hasfaces) in_list(ft,_polyhedra_[i][facevertices])]))
                    ) i
                )
            ]
        )
    )
    len(indexlist)==0 ? []
  :
    let(validindex = is_undef(index) || (index>=0 && index<len(indexlist)))
    assert(validindex, str(
        len(indexlist),
        " polyhedra meet specifications, so 'index' must be in [0,",
        len(indexlist)-1,
        "], but 'index' is ",
        index
    ))
    let(
        entry = (
            name == "trapezohedron"? (
                _trapezohedron(faces=faces, side=side, longside=longside, h=h, r=r, d=d, height=height)
            ) : (
                _polyhedra_[!is_undef(index)?
                    indexlist[index] :
                    indexlist[0]]
            )
        ),
        valid_facedown = is_bool(facedown) || in_list(facedown, entry[facevertices])
    )
    assert(name == "trapezohedron" || num_defined([longside,h,height])==0, "The 'longside', 'h' and 'height' parameters are only allowed with trapezohedrons")
    assert(valid_facedown,str("'facedown' set to ",facedown," but selected polygon only has faces with size(s) ",entry[facevertices]))
    let(
        scalefactor = (
            name=="trapezohedron" ? 1 : (
                argcount == 0? 1     // Default side=1 if no size info given
              : is_def(side) ? side  
              : is_def(ir) ? ir/entry[in_radius] 
              : is_def(mr) ? mr/entry[mid_radius] 
              :              or/entry[out_radius]
            ) / entry[edgelen]
        ),
        face_triangles = hull(entry[vertices]),
        faces_normals_vertices = _stellate_faces(
            entry[edgelen], stellate, entry[vertices],
            entry[facevertices]==[3]?
                [face_triangles, [for(face=face_triangles) _facenormal(entry[vertices],face)]] :
                _full_faces(entry[vertices], face_triangles)
        ),
        faces = faces_normals_vertices[0],
        faces_vertex_count = [for(face=faces) len(face)],
        facedown = facedown == true ? (stellate==false? entry[facevertices][0] : 3) : facedown,
        down_direction = facedown == false?  [0,0,-1] :
            faces_normals_vertices[1][search(facedown, faces_vertex_count)[0]],
        scaled_points = scalefactor * rot(p=faces_normals_vertices[2], from=down_direction, to=[0,0,-1]),
        bounds = pointlist_bounds(scaled_points),
        boundtable = [bounds[0], [0,0,0], bounds[1]],
        translation = [for(i=[0:2]) -boundtable[1+anchor[i]][i]],
        face_normals = rot(p=faces_normals_vertices[1], from=down_direction, to=[0,0,-1]),
        radius_scale = name=="trapezohedron" ? 1 : scalefactor * entry[edgelen]
    )
    info == "fullentry" ? [
        scaled_points,
        translation,
        stellate ? faces : face_triangles,
        faces,
        face_normals,
        radius_scale*entry[in_radius]
    ] :
    info == "vnf" ? [move(translation,p=scaled_points), faces] :
    info == "vertices" ? move(translation,p=scaled_points) :
    info == "faces" ? faces :
    info == "face normals" ? face_normals :
    info == "in_radius" ? radius_scale * entry[in_radius] :
    info == "mid_radius" ? radius_scale * entry[mid_radius] :
    info == "out_radius" ? radius_scale * entry[out_radius] :
    info == "index set" ? indexlist :
    info == "face vertices" ? (stellate==false? entry[facevertices] : [3]) :
    info == "edge length" ? scalefactor * entry[edgelen] :
    info == "center" ? translation :
    info == "type" ? entry[class] :
    info == "name" ? entry[pname] :
    assert(false, str("Unknown info type '",info,"' requested"));


function _stellate_faces(scalefactor,stellate,vertices,faces_normals) =
    (stellate == false || stellate == 0)? concat(faces_normals,[vertices]) :
    let(
        faces = [for(face=faces_normals[0]) select(face,hull(select(vertices,face)))],
        direction = [for(i=[0:1:len(faces)-1]) _facenormal(vertices, faces[i])*faces_normals[1][i]>0 ? 1 : -1],
        maxvertex = len(vertices),
        newpts = [for(i=[0:1:len(faces)-1]) mean(select(vertices,faces[i]))+stellate*scalefactor*faces_normals[1][i]],
        newfaces = [for(i=[0:1:len(faces)-1], j=[0:len(faces[i])-1]) concat([i+maxvertex],select(faces[i], [j, j+direction[i]]))],
        allpts = concat(vertices, newpts),
        normals = [for(face=newfaces) _facenormal(allpts,face)]
    ) [newfaces, normals, allpts];


function _trapezohedron(faces, r, side, longside, h, height, d) =
    assert(faces%2==0, "Must set 'faces' to an even number for trapezohedron")
    assert(is_undef(h) || is_undef(height), "Cannot define both 'h' and 'height'")
    let(
        r = get_radius(r=r, d=d),
        h = first_defined([h,height]),
        N = faces/2,
        parmcount = num_defined([r,side,longside,h])
    )
    assert(parmcount==2,"Must define exactly two of 'r' (or 'd'), 'side', 'longside', and 'h' (or 'height')")
    let(       
        separation = (     // z distance between non-apex vertices that aren't in the same plane
            !is_undef(h) ? 2*h*sqr(tan(90/N)) :
            (!is_undef(r) && !is_undef(side))? sqrt(side*side+2*r*r*(cos(180/N)-1)) :
            (!is_undef(r) && !is_undef(longside))? 2 * sqrt(sqr(longside)-sqr(r)) / (1-sqr(tan(90/N))) * sqr(tan(90/N)) :
            2*sqr(sin(90/N))*sqrt((sqr(side) + 2*sqr(longside)*(cos(180/N)-1)) / (cos(180/N)-1) / (cos(180/N)+cos(360/N)))
        )
    )
    assert(separation==separation, "Impossible trapezohedron specification")
    let(
        h = !is_undef(h) ? h : 0.5*separation / sqr(tan(90/N)),
        r = (
            !is_undef(r) ? r :
            !is_undef(side) ? sqrt((sqr(separation) - sqr(side))/2/(cos(180/N)-1)) :
            sqrt(sqr(longside) - sqr(h-separation/2))
        ),
        top = [for(i=[0:1:N-1]) [r*cos(360/N*i), r*sin(360/N*i),separation/2]],
        bot = [for(i=[0:1:N-1]) [r*cos(180/N+360/N*i), r*sin(180/N+360/N*i),-separation/2]],
        vertices = concat([[0,0,h],[0,0,-h]],top,bot)
    ) [  
        "trapezohedron", "trapezohedron", faces, [4],
        !is_undef(side)? side : sqrt(sqr(separation)-2*r*(cos(180/N)-1)),  // actual side length
        h*r/sqrt(r*r+sqr(h+separation/2)),     // in_radius
        h*r/sqrt(r*r+sqr(h-separation/2)),     // mid_radius
        max(h,sqrt(r*r+sqr(separation/2))),  // out_radius
        undef,                               // volume
        vertices
    ];


function _facenormal(pts, face) = unit(cross(pts[face[2]]-pts[face[0]], pts[face[1]]-pts[face[0]]));

// hull() function returns triangulated faces.    This function identifies the vertices that belong to each face
// by grouping together the face triangles that share normal vectors.    The output gives the face polygon
// point indices in arbitrary order (not usable as input to a polygon call) and a normal vector.  Finally
// the faces are ordered based on angle with their center (will always give a valid order for convex polygons).
// Final return is [ordered_faces, facenormals] where the first is a list of indices into the point list
// and the second is a list of vectors.  

function _full_faces(pts,faces) =
    let(
        normals = [for(face=faces) quant(_facenormal(pts,face),1e-12)],
        groups = _unique_groups(normals),
        faces = [for(entry=groups) unique(flatten(select(faces, entry)))],
        facenormals = [for(entry=groups) normals[entry[0]]],
        ordered_faces = [
            for(i=idx(faces))
              let(
                  facepts = select(pts, faces[i]),
                  center = mean(facepts),
                  rotatedface = rot(from=facenormals[i], to=[0,0,1], p=move(-center, p=facepts)),
                  clockwise = sortidx([for(pt=rotatedface) -atan2(pt.y,pt.x)])
              )
            select(faces[i],clockwise)
        ]
    ) [ordered_faces, facenormals];


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
