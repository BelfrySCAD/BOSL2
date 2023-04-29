//////////////////////////////////////////////////////////////////////
// LibFile: trigonometry.scad
//   Trigonometry shortcuts for people who can't be bothered to remember
//   all the function relations, or silly acronyms like SOHCAHTOA.
// Includes:
//   include <BOSL2/std.scad>
// FileGroup: Math
// FileSummary: Trigonometry shortcuts for when you can't recall the mnemonic SOHCAHTOA.
// FileFootnotes: STD=Included in std.scad
//////////////////////////////////////////////////////////////////////



// Section: 2D General Triangle Functions


// Function: law_of_cosines()
// Synopsis: Applies the Law of Cosines for an arbitrary triangle.
// Topics: Geometry, Trigonometry, Triangles
// See Also: law_of_sines()
// Usage:
//   C = law_of_cosines(a, b, c);
//   c = law_of_cosines(a, b, C=);
// Description:
//   Applies the Law of Cosines for an arbitrary triangle.  Given three side lengths, returns the
//   angle in degrees for the corner opposite of the third side.  Given two side lengths, and the
//   angle between them, returns the length of the third side.
// Figure(2D):
//   stroke([[-50,0], [10,60], [50,0]], closed=true);
//   color("black") {
//       translate([ 33,35]) text(text="a", size=8, halign="center", valign="center");
//       translate([  0,-6]) text(text="b", size=8, halign="center", valign="center");
//       translate([-22,35]) text(text="c", size=8, halign="center", valign="center");
//   }
//   color("blue") {
//       translate([-37, 6]) text(text="A", size=8, halign="center", valign="center");
//       translate([  9,51]) text(text="B", size=8, halign="center", valign="center");
//       translate([ 38, 6]) text(text="C", size=8, halign="center", valign="center");
//   }
// Arguments:
//   a = The length of the first side.
//   b = The length of the second side.
//   c = The length of the third side.
//   ---
//   C = The angle in degrees of the corner opposite of the third side.
function law_of_cosines(a, b, c, C) =
    // Triangle Law of Cosines:
    //   c^2 = a^2 + b^2 - 2*a*b*cos(C)
    assert(num_defined([c,C]) == 1, "Must give exactly one of c= or C=.")
    is_undef(c) ? sqrt(a*a + b*b - 2*a*b*cos(C)) :
    acos(constrain((a*a + b*b - c*c) / (2*a*b), -1, 1));


// Function: law_of_sines()
// Synopsis: Applies the Law of Sines for an arbitrary triangle.
// Topics: Geometry, Trigonometry, Triangles
// See Also: law_of_cosines()
// Usage:
//   B = law_of_sines(a, A, b);
//   b = law_of_sines(a, A, B=);
// Description:
//   Applies the Law of Sines for an arbitrary triangle.  Given two triangle side lengths and the
//   angle between them, returns the angle of the corner opposite of the second side.  Given a side
//   length, the opposing angle, and a second angle, returns the length of the side opposite of the
//   second angle.
// Figure(2D):
//   stroke([[-50,0], [10,60], [50,0]], closed=true);
//   color("black") {
//       translate([ 33,35]) text(text="a", size=8, halign="center", valign="center");
//       translate([  0,-6]) text(text="b", size=8, halign="center", valign="center");
//       translate([-22,35]) text(text="c", size=8, halign="center", valign="center");
//   }
//   color("blue") {
//       translate([-37, 6]) text(text="A", size=8, halign="center", valign="center");
//       translate([  9,51]) text(text="B", size=8, halign="center", valign="center");
//       translate([ 38, 6]) text(text="C", size=8, halign="center", valign="center");
//   }
// Arguments:
//   a = The length of the first side.
//   A = The angle in degrees of the corner opposite of the first side.
//   b = The length of the second side.
//   ---
//   B = The angle in degrees of the corner opposite of the second side.
function law_of_sines(a, A, b, B) =
    // Triangle Law of Sines:
    //   a/sin(A) = b/sin(B) = c/sin(C)
    assert(num_defined([b,B]) == 1, "Must give exactly one of b= or B=.")
    let( r = a/sin(A) )
    is_undef(b) ? r*sin(B) :
    asin(constrain(b/r, -1, 1));



// Section: 2D Right Triangle Functions
//   This is a set of functions to make it easier to perform trig calculations on right triangles.
//   In general, all these functions are named using these abbreviations:
//   - **hyp**: The length of the Hypotenuse.
//   - **adj**: The length of the side adjacent to the angle.
//   - **opp**: The length of the side opposite to the angle.
//   - **ang**: The angle size in degrees.
//   .
//   If you know two of those, and want to know the value of a third, you will need to call a
//   function named like `AAA_BBB_to_CCC()`.  For example, if you know the length of the hypotenuse,
//   and the length of the side adjacent to the angle, and want to learn the length of the side
//   opposite to the angle, you will call `opp = hyp_adj_to_opp(hyp,adj);`.
// Figure(2D):
//   color("brown") {
//       stroke([[40,0], [40,10], [50,10]]);
//       left(50) stroke(arc(r=37,angle=30));
//   }
//   color("lightgreen") stroke([[-50,0], [50,60], [50,0]], closed=true);
//   color("black") {
//       translate([ 62,25]) text(text="opp", size=8, halign="center", valign="center");
//       translate([  0,-6]) text(text="adj", size=8, halign="center", valign="center");
//       translate([  0,40]) text(text="hyp", size=8, halign="center", valign="center");
//       translate([-25, 5]) text(text="ang", size=7, halign="center", valign="center");
//   }


// Function: hyp_opp_to_adj()
// Alias: opp_hyp_to_adj()
// Synopsis: Returns the adjacent side length from the lengths of the hypotenuse and the opposite side.
// Topics: Geometry, Trigonometry, Triangles
// See Also: adj_ang_to_hyp(), adj_ang_to_opp(), adj_opp_to_ang(), adj_opp_to_hyp(), hyp_adj_to_ang(), hyp_adj_to_opp(), hyp_ang_to_adj(), hyp_ang_to_opp(), hyp_opp_to_adj(), hyp_opp_to_ang(), opp_ang_to_adj(), opp_ang_to_hyp()
// Usage:
//   adj = hyp_opp_to_adj(hyp,opp);
//   adj = opp_hyp_to_adj(opp,hyp);
// Description:
//   Given the lengths of the hypotenuse and opposite side of a right triangle, returns the length
//   of the adjacent side.
// Arguments:
//   hyp = The length of the hypotenuse of the right triangle.
//   opp = The length of the side of the right triangle that is opposite from the primary angle.
// Example:
//   hyp = hyp_opp_to_adj(5,3);  // Returns: 4
function hyp_opp_to_adj(hyp,opp) =
    assert(is_finite(hyp+opp) && hyp>=0 && opp>=0,
           "Triangle side lengths should be a positive numbers." )
    sqrt(hyp*hyp-opp*opp);

function opp_hyp_to_adj(opp,hyp) = hyp_opp_to_adj(hyp,opp);


// Function: hyp_ang_to_adj()
// Alias: ang_hyp_to_adj()
// Synopsis: Returns the adjacent side length from the length of the hypotenuse and the angle.
// Topics: Geometry, Trigonometry, Triangles
// See Also: adj_ang_to_hyp(), adj_ang_to_opp(), adj_opp_to_ang(), adj_opp_to_hyp(), hyp_adj_to_ang(), hyp_adj_to_opp(), hyp_ang_to_adj(), hyp_ang_to_opp(), hyp_opp_to_adj(), hyp_opp_to_ang(), opp_ang_to_adj(), opp_ang_to_hyp()
// Usage:
//   adj = hyp_ang_to_adj(hyp,ang);
//   adj = ang_hyp_to_adj(ang,hyp);
// Description:
//   Given the length of the hypotenuse and the angle of the primary corner of a right triangle,
//   returns the length of the adjacent side.
// Arguments:
//   hyp = The length of the hypotenuse of the right triangle.
//   ang = The angle in degrees of the primary corner of the right triangle.
// Example:
//   adj = hyp_ang_to_adj(8,60);  // Returns: 4
function hyp_ang_to_adj(hyp,ang) =
    assert(is_finite(hyp) && hyp>=0, "Triangle side length should be a positive number." )
    assert(is_finite(ang) && ang>-90 && ang<90, "The angle should be an acute angle." )
    hyp*cos(ang);

function ang_hyp_to_adj(ang,hyp) = hyp_ang_to_adj(hyp, ang);


// Function: opp_ang_to_adj()
// Alias: ang_opp_to_adj()
// Synopsis: Returns the adjacent side length from the length of the opposite side and the angle.
// Topics: Geometry, Trigonometry, Triangles
// See Also: adj_ang_to_hyp(), adj_ang_to_opp(), adj_opp_to_ang(), adj_opp_to_hyp(), hyp_adj_to_ang(), hyp_adj_to_opp(), hyp_ang_to_adj(), hyp_ang_to_opp(), hyp_opp_to_adj(), hyp_opp_to_ang(), opp_ang_to_adj(), opp_ang_to_hyp()
// Usage:
//   adj = opp_ang_to_adj(opp,ang);
//   adj = ang_opp_to_adj(ang,opp);
// Description:
//   Given the angle of the primary corner of a right triangle, and the length of the side opposite of it,
//   returns the length of the adjacent side.
// Arguments:
//   opp = The length of the side of the right triangle that is opposite from the primary angle.
//   ang = The angle in degrees of the primary corner of the right triangle.
// Example:
//   adj = opp_ang_to_adj(8,30);  // Returns: 4
function opp_ang_to_adj(opp,ang) =
    assert(is_finite(opp) && opp>=0, "Triangle side length should be a positive number." )
    assert(is_finite(ang) && ang>-90 && ang<90, "The angle should be an acute angle." )
    opp/tan(ang);

function ang_opp_to_adj(ang,opp) = opp_ang_to_adj(opp,ang);


// Function: hyp_adj_to_opp()
// Alias: adj_hyp_to_opp()
// Synopsis: Returns the opposite side length from the lengths of the hypotenuse and the adjacent side.
// Topics: Geometry, Trigonometry, Triangles
// See Also: adj_ang_to_hyp(), adj_ang_to_opp(), adj_opp_to_ang(), adj_opp_to_hyp(), hyp_adj_to_ang(), hyp_adj_to_opp(), hyp_ang_to_adj(), hyp_ang_to_opp(), hyp_opp_to_adj(), hyp_opp_to_ang(), opp_ang_to_adj(), opp_ang_to_hyp()
// Usage:
//   opp = hyp_adj_to_opp(hyp,adj);
//   opp = adj_hyp_to_opp(adj,hyp);
// Description:
//   Given the length of the hypotenuse and the adjacent side, returns the length of the opposite side.
// Arguments:
//   hyp = The length of the hypotenuse of the right triangle.
//   adj = The length of the side of the right triangle that is adjacent to the primary angle.
// Example:
//   opp = hyp_adj_to_opp(5,4);  // Returns: 3
function hyp_adj_to_opp(hyp,adj) =
    assert(is_finite(hyp) && hyp>=0 && is_finite(adj) && adj>=0,
           "Triangle side lengths should be a positive numbers." )
    sqrt(hyp*hyp-adj*adj);

function adj_hyp_to_opp(adj,hyp) = hyp_adj_to_opp(hyp,adj);


// Function: hyp_ang_to_opp()
// Alias: ang_hyp_to_opp()
// Synopsis: Returns the opposite side length from the length of the hypotenuse and the angle.
// Topics: Geometry, Trigonometry, Triangles
// See Also: adj_ang_to_hyp(), adj_ang_to_opp(), adj_opp_to_ang(), adj_opp_to_hyp(), hyp_adj_to_ang(), hyp_adj_to_opp(), hyp_ang_to_adj(), hyp_ang_to_opp(), hyp_opp_to_adj(), hyp_opp_to_ang(), opp_ang_to_adj(), opp_ang_to_hyp()
// Usage:
//   opp = hyp_ang_to_opp(hyp,ang);
//   opp = ang_hyp_to_opp(ang,hyp);
// Description:
//   Given the length of the hypotenuse of a right triangle, and the angle of the corner, returns the length of the opposite side.
// Arguments:
//   hyp = The length of the hypotenuse of the right triangle.
//   ang = The angle in degrees of the primary corner of the right triangle.
// Example:
//   opp = hyp_ang_to_opp(8,30);  // Returns: 4
function hyp_ang_to_opp(hyp,ang) =
    assert(is_finite(hyp)&&hyp>=0, "Triangle side length should be a positive number." )
    assert(is_finite(ang) && ang>-90 && ang<90, "The angle should be an acute angle." )
    hyp*sin(ang);

function ang_hyp_to_opp(ang,hyp) = hyp_ang_to_opp(hyp,ang);


// Function: adj_ang_to_opp()
// Alias: ang_adj_to_opp()
// Synopsis: Returns the opposite side length from the length of the adjacent side and the angle.
// Topics: Geometry, Trigonometry, Triangles
// See Also: adj_ang_to_hyp(), adj_ang_to_opp(), adj_opp_to_ang(), adj_opp_to_hyp(), hyp_adj_to_ang(), hyp_adj_to_opp(), hyp_ang_to_adj(), hyp_ang_to_opp(), hyp_opp_to_adj(), hyp_opp_to_ang(), opp_ang_to_adj(), opp_ang_to_hyp()
// Usage:
//   opp = adj_ang_to_opp(adj,ang);
//   opp = ang_adj_to_opp(ang,adj);
// Description:
//   Given the length of the adjacent side of a right triangle, and the angle of the corner, returns the length of the opposite side.
// Arguments:
//   adj = The length of the side of the right triangle that is adjacent to the primary angle.
//   ang = The angle in degrees of the primary corner of the right triangle.
// Example:
//   opp = adj_ang_to_opp(8,45);  // Returns: 8
function adj_ang_to_opp(adj,ang) =
    assert(is_finite(adj)&&adj>=0, "Triangle side length should be a positive number." )
    assert(is_finite(ang) && ang>-90 && ang<90, "The angle should be an acute angle." )
    adj*tan(ang);

function ang_adj_to_opp(ang,adj) = adj_ang_to_opp(adj,ang);


// Function: adj_opp_to_hyp()
// Alias: opp_adj_to_hyp()
// Synopsis: Returns the hypotenuse length from the lengths of the adjacent and opposite sides.
// Topics: Geometry, Trigonometry, Triangles
// See Also: adj_ang_to_hyp(), adj_ang_to_opp(), adj_opp_to_ang(), adj_opp_to_hyp(), hyp_adj_to_ang(), hyp_adj_to_opp(), hyp_ang_to_adj(), hyp_ang_to_opp(), hyp_opp_to_adj(), hyp_opp_to_ang(), opp_ang_to_adj(), opp_ang_to_hyp()
// Usage:
//   hyp = adj_opp_to_hyp(adj,opp);
//   hyp = opp_adj_to_hyp(opp,adj);
// Description:
//   Given the length of the adjacent and opposite sides of a right triangle, returns the length of the hypotenuse.
// Arguments:
//   adj = The length of the side of the right triangle that is adjacent to the primary angle.
//   opp = The length of the side of the right triangle that is opposite from the primary angle.
// Example:
//   hyp = adj_opp_to_hyp(3,4);  // Returns: 5
function adj_opp_to_hyp(adj,opp) =
    assert(is_finite(opp) && opp>=0 && is_finite(adj) && adj>=0,
           "Triangle side lengths should be a positive numbers." )
    norm([opp,adj]);

function opp_adj_to_hyp(opp,adj) = adj_opp_to_hyp(adj,opp);


// Function: adj_ang_to_hyp()
// Alias: ang_adj_to_hyp()
// Synopsis: Returns the hypotenuse length from the length of the adjacent and the angle.
// Topics: Geometry, Trigonometry, Triangles
// See Also: adj_ang_to_hyp(), adj_ang_to_opp(), adj_opp_to_ang(), adj_opp_to_hyp(), hyp_adj_to_ang(), hyp_adj_to_opp(), hyp_ang_to_adj(), hyp_ang_to_opp(), hyp_opp_to_adj(), hyp_opp_to_ang(), opp_ang_to_adj(), opp_ang_to_hyp()
// Usage:
//   hyp = adj_ang_to_hyp(adj,ang);
//   hyp = ang_adj_to_hyp(ang,adj);
// Description:
//   For a right triangle, given the length of the adjacent side, and the corner angle, returns the length of the hypotenuse.
// Arguments:
//   adj = The length of the side of the right triangle that is adjacent to the primary angle.
//   ang = The angle in degrees of the primary corner of the right triangle.
// Example:
//   hyp = adj_ang_to_hyp(4,60);  // Returns: 8
function adj_ang_to_hyp(adj,ang) =
    assert(is_finite(adj) && adj>=0, "Triangle side length should be a positive number." )
    assert(is_finite(ang) && ang>-90 && ang<90, "The angle should be an acute angle." )
    adj/cos(ang);

function ang_adj_to_hyp(ang,adj) = adj_ang_to_hyp(adj,ang);


// Function: opp_ang_to_hyp()
// Alias: ang_opp_to_hyp()
// Synopsis: Returns the hypotenuse length from the length of the opposite side and the angle.
// Topics: Geometry, Trigonometry, Triangles
// See Also: adj_ang_to_hyp(), adj_ang_to_opp(), adj_opp_to_ang(), adj_opp_to_hyp(), hyp_adj_to_ang(), hyp_adj_to_opp(), hyp_ang_to_adj(), hyp_ang_to_opp(), hyp_opp_to_adj(), hyp_opp_to_ang(), opp_ang_to_adj(), opp_ang_to_hyp()
// Usage:
//   hyp = opp_ang_to_hyp(opp,ang);
//   hyp = ang_opp_to_hyp(ang,opp);
// Description:
//   For a right triangle, given the length of the opposite side, and the corner angle, returns the length of the hypotenuse.
// Arguments:
//   opp = The length of the side of the right triangle that is opposite from the primary angle.
//   ang = The angle in degrees of the primary corner of the right triangle.
// Example:
//   hyp = opp_ang_to_hyp(4,30);  // Returns: 8
function opp_ang_to_hyp(opp,ang) =
    assert(is_finite(opp) && opp>=0, "Triangle side length should be a positive number." )
    assert(is_finite(ang) && ang>-90 && ang<90, "The angle should be an acute angle." )
    opp/sin(ang);

function ang_opp_to_hyp(ang,opp) = opp_ang_to_hyp(opp,ang);


// Function: hyp_adj_to_ang()
// Alias: adj_hyp_to_ang()
// Synopsis: Returns the angle from the lengths of the hypotenuse and the adjacent side.
// Topics: Geometry, Trigonometry, Triangles
// See Also: adj_ang_to_hyp(), adj_ang_to_opp(), adj_opp_to_ang(), adj_opp_to_hyp(), hyp_adj_to_ang(), hyp_adj_to_opp(), hyp_ang_to_adj(), hyp_ang_to_opp(), hyp_opp_to_adj(), hyp_opp_to_ang(), opp_ang_to_adj(), opp_ang_to_hyp()
// Usage:
//   ang = hyp_adj_to_ang(hyp,adj);
//   ang = adj_hyp_to_ang(adj,hyp);
// Description:
//   For a right triangle, given the lengths of the hypotenuse and the adjacent sides, returns the angle of the corner.
// Arguments:
//   hyp = The length of the hypotenuse of the right triangle.
//   adj = The length of the side of the right triangle that is adjacent to the primary angle.
// Example:
//   ang = hyp_adj_to_ang(8,4);  // Returns: 60 degrees
function hyp_adj_to_ang(hyp,adj) =
    assert(is_finite(hyp) && hyp>0 && is_finite(adj) && adj>=0,
            "Triangle side lengths should be positive numbers." )
    acos(adj/hyp);

function adj_hyp_to_ang(adj,hyp) = hyp_adj_to_ang(hyp,adj);


// Function: hyp_opp_to_ang()
// Alias: opp_hyp_to_ang()
// Synopsis: Returns the angle from the lengths of the hypotenuse and the opposite side.
// Topics: Geometry, Trigonometry, Triangles
// See Also: adj_ang_to_hyp(), adj_ang_to_opp(), adj_opp_to_ang(), adj_opp_to_hyp(), hyp_adj_to_ang(), hyp_adj_to_opp(), hyp_ang_to_adj(), hyp_ang_to_opp(), hyp_opp_to_adj(), hyp_opp_to_ang(), opp_ang_to_adj(), opp_ang_to_hyp()
// Usage:
//   ang = hyp_opp_to_ang(hyp,opp);
//   ang = opp_hyp_to_ang(opp,hyp);
// Description:
//   For a right triangle, given the lengths of the hypotenuse and the opposite sides, returns the angle of the corner.
// Arguments:
//   hyp = The length of the hypotenuse of the right triangle.
//   opp = The length of the side of the right triangle that is opposite from the primary angle.
// Example:
//   ang = hyp_opp_to_ang(8,4);  // Returns: 30 degrees
function hyp_opp_to_ang(hyp,opp) =
    assert(is_finite(hyp+opp) && hyp>0 && opp>=0,
            "Triangle side lengths should be positive numbers." )
    asin(opp/hyp);

function opp_hyp_to_ang(opp,hyp) = hyp_opp_to_ang(hyp,opp);


// Function: adj_opp_to_ang()
// Alias: opp_adj_to_ang()
// Synopsis: Returns the angle from the lengths of the adjacent and opposite sides.
// Topics: Geometry, Trigonometry, Triangles
// See Also: adj_ang_to_hyp(), adj_ang_to_opp(), adj_opp_to_ang(), adj_opp_to_hyp(), hyp_adj_to_ang(), hyp_adj_to_opp(), hyp_ang_to_adj(), hyp_ang_to_opp(), hyp_opp_to_adj(), hyp_opp_to_ang(), opp_ang_to_adj(), opp_ang_to_hyp()
// Usage:
//   ang = adj_opp_to_ang(adj,opp);
//   ang = opp_adj_to_ang(opp,adj);
// Description:
//   For a right triangle, given the lengths of the adjacent and opposite sides, returns the angle of the corner.
// Arguments:
//   adj = The length of the side of the right triangle that is adjacent to the primary angle.
//   opp = The length of the side of the right triangle that is opposite from the primary angle.
// Example:
//   ang = adj_opp_to_ang(sqrt(3)/2,0.5);  // Returns: 30 degrees
function adj_opp_to_ang(adj,opp) =
    assert(is_finite(adj+opp) && adj>0 && opp>=0,
            "Triangle side lengths should be positive numbers." )
    atan2(opp,adj);

function opp_adj_to_ang(opp,adj) = adj_opp_to_ang(adj,opp);



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
