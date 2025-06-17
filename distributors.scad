//////////////////////////////////////////////////////////////////////
// LibFile: distributors.scad
//   Functions and modules to distribute children or copies of children onto
//   a line, a grid, or an arbitrary path.  The $idx mechanism means that
//   the "copies" of children can vary.  Also includes shortcuts for mirroring.  
// Includes:
//   include <BOSL2/std.scad>
// FileGroup: Basic Modeling
// FileSummary: Copy or distribute objects onto a line, grid, or path.  Mirror shortcuts. 
// FileFootnotes: STD=Included in std.scad
//////////////////////////////////////////////////////////////////////

// Section: Adaptive Children Using `$` Variables
//   The distributor methods create multiple copies of their children and place them in various ways.  While many models 
//   require multiple identical copies of an object, this framework is more powerful than
//   might be immediately obvious because of `$` variables.  The distributors set `$` variables that the children can use to change their
//   behavior from one child to the next within a single distributor invocation.  This means the copies need not be identical.  
//   The {{xcopies()}} module sets `$idx` to the index number of the copy, and in the examples below we use `$idx`, but the various
//   distributors offer a variety of `$` variables that you can use in your children.  Check the "Side Effects" section for each module
//   to learn what variables that module provides.
//   .
//   Two gotchas may lead to models that don't behave as expected.  While `if` statements work to control modules, you cannot
//   use them to make variable assignments in your child object.  If you write a statement like 
//   ```
//   if (condition) { c="red";}
//   else {c="green";}
//   ```
//   then the `c` variable is set only in the scope of the `if` and `else` clauses and is not available later on when you actually
//   try to use it.  Instead you must use the ternary operator and write:
//   ```
//   c = condition ? "red" : "green";
//   ```
//   The second complication is
//   that in OpenSCAD version 2021.01 and earlier, assignments in children were executed before their parent.  This means 
//   that `$` variables like `$idx` are not available in assignments because the parent hasn't run to set them, so if you use them
//   you will get a warning about an unknown variable.
//   Two workarounds exist, neither of which are needed in newer versions of OpenSCAD.  The workarounds solve the problem because
//   **modules** execute after their parent, so the `$` variables **are** available in modules.  You can put your assignments
//   in a `let()` module, or you can wrap your child in a `union()`.  Both methods appear below.
// Figure(2D,NoScales): This example shows how we can use `$idx` to produce **different** geometry at each index.
//   xcopies(n=10, spacing=10)
//     text(str($idx));
// Continues:
//   ```
//   xcopies(n=10, spacing=10)
//     text(str($idx));
//   ```
// Figure(2D,NoScales): Here the children are sometimes squares and sometimes circles as determined by the conditional `if` module. This use of `if` is OK because no variables are assigned.  
//   xcopies(n=4, spacing=10)
//     if($idx%2==0) circle(r=3,$fn=16);
//     else rect(6);
// Continues:
//   ```
//   xcopies(n=4, spacing=10)
//     if($idx%2==0) circle(r=3,$fn=16);
//     else rect(6);
//   ```
// Figure(2D,NoScales): Suppose we would like to color odd and even index copies differently.  In this example we compute the color for a given child from `$idx` using the ternary operator.  The `let()` module is a module that sets variables and makes them available to its children.  Note that multiple assignments in `let()` are separated by commas, not semicolons.  
//   xcopies(n=6, spacing=10){
//       let(c = $idx % 2 == 0 ? "red" : "green")
//           color(c) rect(6);
//   }
// Continues:
//   ```
//   xcopies(n=6, spacing=10){
//       let(c = $idx % 2 == 0 ? "red" : "green")
//           color(c) rect(6);
//   }
//   ```
// Figure(2D,NoScales):  This example shows how you can change the position of children adaptively.  If you want to avoid repeating your code for each case, this requires storing a transformation matrix in a variable and then applying it using `multmatrix()`.  We wrap our code in `union()` to ensure that it works in OpenSCAD 2021.01.  
//   xcopies(n=5,spacing=10)
//     union()
//     {
//       shiftback = $idx%2==0 ? back(10) : IDENT;
//       spin = zrot(180*$idx/4);
//       multmatrix(shiftback*spin) stroke([[-4,0],[4,0]],endcap2="arrow2",width=3/4, color="red");
//     }
// Continues:
//   ```
//   xcopies(n=5,spacing=10)
//     union()
//     {
//       shiftback = $idx%2==0 ? back(10) : IDENT;
//       spin = zrot(180*$idx/4);
//       multmatrix(shiftback*spin) stroke([[-4,0],[4,0]],endcap2="arrow2",width=3/4,color="red");
//     }
//   ```


//////////////////////////////////////////////////////////////////////
// Section: Translating copies of all the children
//////////////////////////////////////////////////////////////////////

// Function&Module: move_copies()
// Synopsis: Translates copies of all children.
// SynTags: MatList, Trans
// Topics: Transformations, Distributors, Translation, Copiers
// See Also: xcopies(), ycopies(), zcopies(), line_copies(), grid_copies(), rot_copies(), xrot_copies(), yrot_copies(), zrot_copies(), arc_copies(), sphere_copies()
//
// Usage:
//   move_copies(a) CHILDREN;
// Usage: As a function to translate points, VNF, or Bezier patches
//   copies = move_copies(a, p=);
// Usage: Get Translation Matrices
//   mats = move_copies(a);
// Description:
//   When called as a module, translates copies of all children to each given translation offset.
//   When called as a function, with no `p=` argument, returns a list of transformation matrices, one for each copy.
//   When called as a function, *with* a `p=` argument, returns a list of transformed copies of `p=`.
//
// Arguments:
//   a = Array of XYZ offset vectors. Default `[[0,0,0]]`
//   ---
//   p = Either a point, pointlist, VNF or Bezier patch to be translated when used as a function.
//
// Side Effects:
//   `$pos` is set to the relative centerpoint of each child copy, and can be used to modify each child individually.
//   `$idx` is set to the index number of each child being copied.
//
//
// Example:
//   #sphere(r=10);
//   move_copies([[-25,-25,0], [25,-25,0], [0,0,50], [0,25,0]]) sphere(r=10);
module move_copies(a=[[0,0,0]])
{
    req_children($children);
    assert(is_list(a));
    for ($idx = idx(a)) {
        $pos = a[$idx];
        assert(is_vector($pos),"move_copies offsets should be a 2d or 3d vector.");
        translate($pos) children();
    }
}

function move_copies(a=[[0,0,0]],p=_NO_ARG) =
    assert(is_list(a))
    let(
        mats = [
            for (pos = a)
            assert(is_vector(pos),"move_copies offsets should be a 2d or 3d vector.")
            translate(pos)
        ]
    )
    p==_NO_ARG? mats : [for (m = mats) apply(m, p)];


// Function&Module: xcopies()
// Synopsis: Places copies of children along the X axis. 
// SynTags: MatList, Trans
// Topics: Transformations, Distributors, Translation, Copiers
// See Also: move_copies(), ycopies(), zcopies(), line_copies(), grid_copies(), rot_copies(), xrot_copies(), yrot_copies(), zrot_copies(), arc_copies(), sphere_copies()
//
// Usage:
//   xcopies(spacing, [n], [sp=]) CHILDREN;
//   xcopies(l=, [n=], [sp=]) CHILDREN;
//   xcopies(LIST) CHILDREN;
// Usage: As a function to translate points, VNF, or Bezier patches
//   copies = xcopies(spacing, [n], [sp=], p=);
//   copies = xcopies(l=, [n=], [sp=], p=);
//   copies = xcopies(LIST, p=);
// Usage: Get Translation Matrices
//   mats = xcopies(spacing, [n], [sp=]);
//   mats = xcopies(l=, [n=], [sp=]);
//   mats = xcopies(LIST);
// Description:
//   When called as a module, places `n` copies of the children along a line on the X axis.
//   When called as a function, *without* a `p=` argument, returns a list of transformation matrices, one for each copy.
//   When called as a function, *with* a `p=` argument, returns a list of transformed copies of `p=`.
//
// Arguments:
//   spacing = Given a scalar, specifies a uniform spacing between copies. Given a list of scalars, each one gives a specific position along the line. (Default: 1.0)
//   n = Number of copies to place. (Default: 2)
//   ---
//   l = If given, the length to place copies over.
//   sp = If given as a point, copies will be placed on a line to the right of starting position `sp`.  If given as a scalar, copies will be placed on a line segment to the right of starting position `[sp,0,0]`.  If not given, copies will be placed along a line segment that is centered at [0,0,0].
//   p = Either a point, pointlist, VNF or Bezier patch to be translated when used as a function.
//
// Side Effects:
//   `$pos` is set to the relative centerpoint of each child copy, and can be used to modify each child individually.
//   `$idx` is set to the index number of each child being copied.
//
// Examples:
//   xcopies(20) sphere(3);
//   xcopies(20, n=3) sphere(3);
//   xcopies(spacing=15, l=50) sphere(3);
//   xcopies(n=4, l=30, sp=[0,10,0]) sphere(3);
// Example:
//   xcopies(10, n=3) {
//       cube(size=[1,3,1],center=true);
//       cube(size=[3,1,1],center=true);
//   }
// Example:
//   xcopies([1,2,3,5,7]) sphere(d=1);
module xcopies(spacing, n, l, sp)
{
    assert(is_undef(n) || num_defined([l,spacing])==1, "When n is given must give exactly one of spacing or l")
    assert(is_def(n) || num_defined([l,spacing])>=1, "When n is not given must give at least one of spacing or l")  
    req_children($children);
    dir = RIGHT;
    sp = is_finite(sp)? (sp*dir) : sp;
    if (is_vector(spacing)) {
        translate(default(sp,[0,0,0])) {
            for (i = idx(spacing)) {
                $idx = i;
                $pos = spacing[i]*dir;
                translate($pos) children();
            }
        }
    } else {
        line_copies(
            l=u_mul(l,dir),
            spacing=u_mul(spacing,dir),
            n=n, p1=sp
        ) children();
    }
}


function xcopies(spacing, n, l, sp, p=_NO_ARG) =
    assert(is_undef(n) || num_defined([l,spacing])==1, "When n is given must give exactly one of spacing or l")
    assert(is_def(n) || num_defined([l,spacing])>=1, "When n is not given must give at least one of spacing or l")  
    let(
        dir = RIGHT,
        sp = is_finite(sp)? (sp*dir) : sp,
        mats = is_vector(spacing)
          ? let(sp = default(sp,[0,0,0])) [for (n = spacing) translate(sp + n*dir)]
          : line_copies(l=u_mul(l,dir), spacing=u_mul(spacing,dir), n=n, p1=sp)
    )
    p==_NO_ARG? mats : [for (m = mats) apply(m, p)];


// Function&Module: ycopies()
// Synopsis: Places copies of children along the Y axis. 
// SynTags: MatList, Trans
// Topics: Transformations, Distributors, Translation, Copiers
// See Also: move_copies(), xcopies(), zcopies(), line_copies(), grid_copies(), rot_copies(), xrot_copies(), yrot_copies(), zrot_copies(), arc_copies(), sphere_copies()
//
// Usage:
//   ycopies(spacing, [n], [sp=]) CHILDREN;
//   ycopies(l=, [n=], [sp=]) CHILDREN;
//   ycopies(LIST) CHILDREN;
// Usage: As a function to translate points, VNF, or Bezier patches
//   copies = ycopies(spacing, [n], [sp=], p=);
//   copies = ycopies(l=, [n=], [sp=], p=);
//   copies = ycopies(LIST, p=);
// Usage: Get Translation Matrices
//   mats = ycopies(spacing, [n], [sp=]);
//   mats = ycopies(l=, [n=], [sp=]);
//   mats = ycopies(LIST);
// Description:
//   When called as a module, places `n` copies of the children along a line on the Y axis.
//   When called as a function, *without* a `p=` argument, returns a list of transformation matrices, one for each copy.
//   When called as a function, *with* a `p=` argument, returns a list of transformed copies of `p=`.
//
// Arguments:
//   spacing = Given a scalar, specifies a uniform spacing between copies. Given a list of scalars, each one gives a specific position along the line. (Default: 1.0)
//   n = Number of copies to place on the line. (Default: 2)
//   ---
//   l = If given, the length to place copies over.
//   sp = If given as a point, copies will be place on a line back from starting position `sp`.  If given as a scalar, copies will be placed on a line back from starting position `[0,sp,0]`.  If not given, copies will be placed along a line that is centered at [0,0,0].
//   p = Either a point, pointlist, VNF or Bezier patch to be translated when used as a function.
//
// Side Effects:
//   `$pos` is set to the relative centerpoint of each child copy, and can be used to modify each child individually.
//   `$idx` is set to the index number of each child being copied.
//
// Examples:
//   ycopies(20) sphere(3);
//   ycopies(20, n=3) sphere(3);
//   ycopies(spacing=15, l=50) sphere(3);
//   ycopies(n=4, l=30, sp=[10,0,0]) sphere(3);
// Example:
//   ycopies(10, n=3) {
//       cube(size=[1,3,1],center=true);
//       cube(size=[3,1,1],center=true);
//   }
// Example:
//   ycopies([1,2,3,5,7]) sphere(d=1);
module ycopies(spacing, n, l, sp)
{
    assert(is_undef(n) || num_defined([l,spacing])==1, "When n is given must give exactly one of spacing or l")
    assert(is_def(n) || num_defined([l,spacing])>=1, "When n is not given must give at least one of spacing or l")  
    req_children($children);  
    dir = BACK;
    sp = is_finite(sp)? (sp*dir) : sp;
    if (is_vector(spacing)) {
        translate(default(sp,[0,0,0])) {
            for (i = idx(spacing)) {
                $idx = i;
                $pos = spacing[i]*dir;
                translate($pos) children();
            }
        }
    } else {
        line_copies(
            l=u_mul(l,dir),
            spacing=u_mul(spacing,dir),
            n=n, p1=sp
        ) children();
    }
}


function ycopies(spacing, n, l, sp, p=_NO_ARG) =
    assert(is_undef(n) || num_defined([l,spacing])==1, "When n is given must give exactly one of spacing or l")
    assert(is_def(n) || num_defined([l,spacing])>=1, "When n is not given must give at least one of spacing or l")  
    let(
        dir = BACK,
        sp = is_finite(sp)? (sp*dir) : sp,
        mats = is_vector(spacing)
          ? let(sp = default(sp,[0,0,0])) [for (n = spacing) translate(sp + n*dir)]
          : line_copies(l=u_mul(l,dir), spacing=u_mul(spacing,dir), n=n, p1=sp)
    )
    p==_NO_ARG? mats : [for (m = mats) apply(m, p)];


// Function&Module: zcopies()
// Synopsis: Places copies of children along the Z axis. 
// SynTags: MatList, Trans
// Topics: Transformations, Distributors, Translation, Copiers
// See Also: move_copies(), xcopies(), ycopies(), line_copies(), grid_copies(), rot_copies(), xrot_copies(), yrot_copies(), zrot_copies(), arc_copies(), sphere_copies()
//
// Usage:
//   zcopies(spacing, [n], [sp=]) CHILDREN;
//   zcopies(l=, [n=], [sp=]) CHILDREN;
//   zcopies(LIST) CHILDREN;
// Usage: As a function to translate points, VNF, or Bezier patches
//   copies = zcopies(spacing, [n], [sp=], p=);
//   copies = zcopies(l=, [n=], [sp=], p=);
//   copies = zcopies(LIST, p=);
// Usage: Get Translation Matrices
//   mats = zcopies(spacing, [n], [sp=]);
//   mats = zcopies(l=, [n=], [sp=]);
//   mats = zcopies(LIST);
// Description:
//   When called as a module, places `n` copies of the children along a line on the Z axis.
//   When called as a function, *without* a `p=` argument, returns a list of transformation matrices, one for each copy.
//   When called as a function, *with* a `p=` argument, returns a list of transformed copies of `p=`.
//
// Arguments:
//   spacing = Given a scalar, specifies a uniform spacing between copies. Given a list of scalars, each one gives a specific position along the line. (Default: 1.0)
//   n = Number of copies to place. (Default: 2)
//   ---
//   l = If given, the length to place copies over.
//   sp = If given as a point, copies will be placed on a line up from starting position `sp`.  If given as a scalar, copies will be placed on a line up from starting position `[0,0,sp]`.  If not given, copies will be placed on a line that is centered at [0,0,0].
//   p = Either a point, pointlist, VNF or Bezier patch to be translated when used as a function.
//
// Side Effects:
//   `$pos` is set to the relative centerpoint of each child copy, and can be used to modify each child individually.
//   `$idx` is set to the index number of each child being copied.
//
// Examples:
//   zcopies(20) sphere(3);
//   zcopies(20, n=3) sphere(3);
//   zcopies(spacing=15, l=50) sphere(3);
//   zcopies(n=4, l=30, sp=[10,0,0]) sphere(3);
// Example:
//   zcopies(10, n=3) {
//       cube(size=[1,3,1],center=true);
//       cube(size=[3,1,1],center=true);
//   }
// Example: Cubic sphere packing
//   s = 20;
//   s2 = s * sin(45);
//   zcopies(s2,n=8)
//       grid_copies([s2,s2],n=8,stagger=($idx%2)? true : "alt")
//          sphere(d=s);
// Example: Hexagonal sphere packing
//   s = 20;
//   xyr = adj_ang_to_hyp(s/2,30);
//   h = hyp_adj_to_opp(s,xyr);
//   zcopies(h,n=8)
//       back(($idx%2)*xyr*cos(60))
//           grid_copies(s,n=[12,7],stagger=($idx%2)? "alt" : true)
//               sphere(d=s);
// Example:
//   zcopies([1,2,3,5,7]) sphere(d=1);
module zcopies(spacing, n, l, sp)
{
    assert(is_undef(n) || num_defined([l,spacing])==1, "When n is given must give exactly one of spacing or l")
    assert(is_def(n) || num_defined([l,spacing])>=1, "When n is not given must give at least one of spacing or l")  
    req_children($children);  
    dir = UP;
    sp = is_finite(sp)? (sp*dir) : sp;
    if (is_vector(spacing)) {
        translate(default(sp,[0,0,0])) {
            for (i = idx(spacing)) {
                $idx = i;
                $pos = spacing[i]*dir;
                translate($pos) children();
            }
        }
    } else {
        line_copies(
            l=u_mul(l,dir),
            spacing=u_mul(spacing,dir),
            n=n, p1=sp
        ) children();
    }
}


function zcopies(spacing, n, l, sp, p=_NO_ARG) =
    assert(is_undef(n) || num_defined([l,spacing])==1, "When n is given must give exactly one of spacing or l")
    assert(is_def(n) || num_defined([l,spacing])>=1, "When n is not given must give at least one of spacing or l")  
    let(
        dir = UP,
        sp = is_finite(sp)? (sp*dir) : sp,
        mats = is_vector(spacing)
          ? let(sp = default(sp,[0,0,0])) [for (n = spacing) translate(sp + n*dir)]
          : line_copies(l=u_mul(l,dir), spacing=u_mul(spacing,dir), n=n, p1=sp)
    )
    p==_NO_ARG? mats : [for (m = mats) apply(m, p)];



// Function&Module: line_copies()
// Synopsis: Places copies of children along an arbitrary line. 
// SynTags: MatList, Trans
// Topics: Transformations, Distributors, Translation, Copiers
// See Also: move_copies(), xcopies(), ycopies(), zcopies(), rot_copies(), xrot_copies(), yrot_copies(), zrot_copies(), arc_copies(), sphere_copies()
//
// Usage: Place `n` copies at a given spacing along the line
//   line_copies(spacing, [n], [p1=]) CHILDREN;
// Usage: Place as many copies as will fit at a given spacing
//   line_copies(spacing, [l=], [p1=]) CHILDREN;
// Usage: Place `n` copies along the length of the line
//   line_copies([n=], [l=], [p1=]) CHILDREN;
// Usage: Place `n` copies along the line from `p1` to `p2`
//   line_copies([n=], [p1=], [p2=]) CHILDREN;
// Usage: Place copies at the given spacing, centered along the line from `p1` to `p2`
//   line_copies([spacing], [p1=], [p2=]) CHILDREN;
// Usage: As a function to translate points, VNF, or Bezier patches
//   copies = line_copies([spacing], [n], [p1=], p=);
//   copies = line_copies([spacing], [l=], [p1=], p=);
//   copies = line_copies([n=], [l=], [p1=], p=);
//   copies = line_copies([n=], [p1=], [p2=], p=);
//   copies = line_copies([spacing], [p1=], [p2=], p=);
// Usage: Get Translation Matrices
//   mats = line_copies([spacing], [n], [p1=]);
//   mats = line_copies([spacing], [l=], [p1=]);
//   mats = line_copies([n=], [l=], [p1=]);
//   mats = line_copies([n=], [p1=], [p2=]);
//   mats = line_copies([spacing], [p1=], [p2=]);
// Description:
//   When called as a function, *without* a `p=` argument, returns a list of transformation matrices, one for each copy.
//   When called as a function, *with* a `p=` argument, returns a list of transformed copies of `p=`.
//   When called as a module, copies `children()` at one or more evenly spaced positions along a line.
//   By default, the line will be centered at the origin, unless the starting point `p1` is given.
//   The line will be pointed towards `RIGHT` (X+) unless otherwise given as a vector in `l`,
//   `spacing`, or `p1`/`p2`.  The position of the copies is specified in one of several ways:
//   .
//   If You Know...                   | Then Use Something Like...
//   -------------------------------- | --------------------------------
//   Spacing distance, Count          | `line_copies(spacing=10, n=5) ...` or `line_copies(10, n=5) ...`
//   Spacing vector, Count            | `line_copies(spacing=[10,5], n=5) ...` or `line_copies([10,5], n=5) ...`
//   Spacing distance, Line length    | `line_copies(spacing=10, l=50) ...` or `line_copies(10, l=50) ...`
//   Spacing distance, Line vector    | `line_copies(spacing=10, l=[50,30]) ...` or `line_copies(10, l=[50,30]) ...`
//   Spacing vector, Line length      | `line_copies(spacing=[10,5], l=50) ...` or `line_copies([10,5], l=50) ...`
//   Line length, Count               | `line_copies(l=50, n=5) ...`
//   Line vector, Count               | `line_copies(l=[50,40], n=5) ...`
//   Line endpoints, Count            | `line_copies(p1=[10,10], p2=[60,-10], n=5) ...`
//   Line endpoints, Spacing distance | `line_copies(p1=[10,10], p2=[60,-10], spacing=10) ...`
//
// Arguments:
//   spacing = Either the scalar spacing distance along the X+ direction, or the vector giving both the direction and spacing distance between each set of copies.
//   n = Number of copies to distribute along the line. (Default: 2)
//   ---
//   l = Either the scalar length of the line, or a vector giving both the direction and length of the line.
//   p1 = If given, specifies the starting point of the line.
//   p2 = If given with `p1`, specifies the ending point of line, and indirectly calculates the line length.
//   p = Either a point, pointlist, VNF or Bezier patch to be translated when used as a function.
//
// Side Effects:
//   `$pos` is set to the relative centerpoint of each child copy, and can be used to modify each child individually.
//   `$idx` is set to the index number of each child being copied.
//
// Examples:
//   line_copies(10) sphere(d=1.5);
//   line_copies(10, n=5) sphere(d=3);
//   line_copies([10,5], n=5) sphere(d=3);
//   line_copies(spacing=10, n=6) sphere(d=3);
//   line_copies(spacing=[10,5], n=6) sphere(d=3);
//   line_copies(spacing=10, l=50) sphere(d=3);
//   line_copies(spacing=10, l=[50,30]) sphere(d=3);
//   line_copies(spacing=[10,5], l=50) sphere(d=3);
//   line_copies(l=50, n=4) sphere(d=3);
//   line_copies(l=[50,-30], n=4) sphere(d=3);
// Example(FlatSpin,VPD=133):
//   line_copies(p1=[0,0,0], p2=[5,5,20], n=6) cuboid([3,2,1]);
// Example(FlatSpin,VPD=133):
//   line_copies(p1=[0,0,0], p2=[5,5,20], spacing=6) cuboid([3,2,1]);
// Example: All children are copied to each position
//   line_copies(l=20, n=3) {
//       cube(size=[1,3,1],center=true);
//       cube(size=[3,1,1],center=true);
//   }
// Example(2D): The functional form of line_copies() returns a list of transform matrices.
//   mats = line_copies([10,5],n=5);
//   for (m = mats) multmatrix(m)  circle(d=3);
// Example(2D): The functional form of line_copies() returns a list of points if given a point.
//   pts = line_copies([10,5],n=5,p=[0,0,0]);
//   move_copies(pts) circle(d=3);

module line_of(spacing, n, l, p1, p2) {
    deprecate("line_copies");
    line_copies(spacing, n, l, p1, p2) children();
}

module line_copies(spacing, n, l, p1, p2)
{
    req_children($children);
    pts = line_copies(spacing=spacing, n=n, l=l, p1=p1, p2=p2, p=[0,0,0]);
    for (i=idx(pts)) {
        $idx = i;
        $pos = pts[i];
        translate($pos) children();
    }
}

function line_copies(spacing, n, l, p1, p2, p=_NO_ARG) =
    assert(is_undef(spacing) || is_finite(spacing) || is_vector(spacing))
    assert(!is_list(spacing) || len(spacing)==2 || len(spacing)==3, "Vector `spacing` must have length 2 or 3")
    assert(is_undef(n) || is_finite(n))
    assert(is_undef(l) || is_finite(l) || is_vector(l))
    assert(is_undef(p1) || is_vector(p1))
    assert(is_undef(p2) || is_vector(p2))
    assert(is_undef(p2) || is_def(p1), "If p2 is given must also give p1")
    assert(is_undef(p2) || is_undef(l), "Cannot give both p2 and l")
    assert(is_undef(n) || num_defined([l,spacing,p2])==1,"If n is given then must give exactly one of 'l', 'spacing', or the 'p1'/'p2' pair")
    assert(is_def(n) || num_defined([l,spacing,p2])>=1,"If n is not given then must give at least one of 'l', 'spacing', or the 'p1'/'p2' pair")
    assert(!(is_vector(spacing) && is_vector(l) && vector_angle(spacing,l)>EPSILON), "Cannot give conflicting vector 'spacing' and vector 'l' value.")
    assert(!(is_vector(spacing) && is_def(p2)), "Cannot combine vector 'spacing' with the 'p1'/'p2' pair")
    let(
        ll = is_def(l)? scalar_vec3(l, 0)
           : is_def(spacing) && is_def(n)? (n-1) * scalar_vec3(spacing, 0)
           : is_def(p1) && is_def(p2)? point3d(p2-p1)
           : undef,
        cnt = is_def(n)? n
            : is_def(spacing) && is_def(ll) ? floor(norm(ll) / norm(scalar_vec3(spacing, 0)) + 1.000001)
            : 2,
        spc = cnt<=1? [0,0,0]
            : is_undef(spacing) && is_def(ll)? ll/(cnt-1) 
            : is_num(spacing) && is_def(ll)? ll/(cnt-1)
            : scalar_vec3(spacing, 0)
    )
    assert(!is_undef(cnt), "Need two of `spacing`, 'l', 'n', or `p1`/`p2` arguments in `line_copies()`.")
    let( spos = !is_undef(p1)? point3d(p1) : -(cnt-1)/2 * spc )
    [for (i=[0:1:cnt-1]) translate(i * spc + spos, p=p)];


// Function&Module: grid_copies()
// Synopsis: Places copies of children in an [X,Y] grid. 
// SynTags: MatList, Trans
// Topics: Transformations, Distributors, Translation, Copiers
// See Also: move_copies(), xcopies(), ycopies(), zcopies(), line_copies(), rot_copies(), xrot_copies(), yrot_copies(), zrot_copies(), arc_copies(), sphere_copies()
//
// Usage:
//   grid_copies(spacing, size=, [stagger=], [scale=], [inside=], [axes=]) CHILDREN;
//   grid_copies(n=, size=, [stagger=], [scale=], [inside=], [axes=]) CHILDREN;
//   grid_copies(spacing, [n], [stagger=], [scale=], [inside=], [axes=]) CHILDREN;
//   grid_copies(n=, inside=, [stagger], [scale], [axes=]) CHILDREN;
// Usage: As a function to translate points, VNF, or Bezier patches
//   copies = grid_copies(spacing, size=, [stagger=], [scale=], [inside=], [axes=], p=);
//   copies = grid_copies(n=, size=, [stagger=], [scale=], [inside=], [axes=], p=);
//   copies = grid_copies(spacing, [n], [stagger=], [scale=], [inside=], [axes=], p=);
//   copies = grid_copies(n=, inside=, [stagger], [scale], [axes=], p=);
// Usage: Get Translation Matrices
//   mats = grid_copies(spacing, size=, [stagger=], [scale=], [inside=], [axes=]);
//   mats = grid_copies(n=, size=, [stagger=], [scale=], [inside=], [axes=]);
//   mats = grid_copies(spacing, [n], [stagger=], [scale=], [inside=], [axes=]);
//   mats = grid_copies(n=, inside=, [stagger], [scale], [axes=]);
// Description:
//   When called as a module, makes a square or hexagonal grid of copies of children, with an optional masking polygon or region.
//   When called as a function, *without* a `p=` argument, returns a list of transformation matrices, one for each copy.
//   When called as a function, *with* a `p=` argument, returns a list of transformed copies of `p=`.
//   .
//   The `stagger` parameter causes each row to be offset from the one below.  
//   By default the layout is in the xy plane where a row runs in the x direction.  You can choose
//   any pair of axes for the layout using the `axes` parameter, which is a two letter parameter
//   where the first letter gives the direction o a row.  The default is "xy".  The order matters because
//   whichever axis is first will correspond to the first entry in `size`, and if you set `stagger=true` that
//   operates on rows, so interchanging the axes will produce a different result.  
//
// Arguments:
//   spacing = Distance between copies in [X,Y] or scalar distance.
//   n = How many columns and rows of copies to make.  Can be given as `[COLS,ROWS]`, or just as a scalar that specifies both.  If staggered, count both staggered and unstaggered columns and rows.  Default: 2 (3 if staggered)
//   size = The [X,Y] size to spread the copies over.
//   ---
//   stagger = If true, make a staggered (hexagonal) grid.  If false, make square grid.  If `"alt"`, makes alternate staggered pattern.  Default: false
//   inside = If given a list of polygon points, or a region, only creates copies whose center would be inside the polygon or region.  Polygon can be concave and/or self crossing.
//   nonzero = If inside is set to a polygon with self-crossings then use the nonzero method for deciding if points are in the polygon.  Default: false
//   axes = Specify the axes to use for the row and column directions as a 2 character string.  Default: "xy"
//   p = Either a point, pointlist, VNF or Bezier patch to be translated when used as a function.
//
// Side Effects:
//   `$pos` is set to the relative centerpoint of each child copy, and can be used to modify each child individually.
//   `$col` is set to the integer column number for each child.
//   `$row` is set to the integer row number for each child.
//   `$idx` is set to a unique index for each child, progressing across rows first, from the bottom
//
// Examples:
//   grid_copies(size=50, spacing=10) cylinder(d=10, h=1);
//   grid_copies(size=50, spacing=[10,15]) cylinder(d=10, h=1);
//   grid_copies(spacing=10, n=[13,7], stagger=true) cylinder(d=6, h=5);
//   grid_copies(spacing=10, n=[13,7], stagger="alt") cylinder(d=6, h=5);
//   grid_copies(size=50, n=11, stagger=true) cylinder(d=5, h=1);
// Example(3D,VPR=[66.90,0.00,36.90],VPD=199.87,VPT=[4.05,9.59,-0.91]): Setting the axes to "xz"
//   grid_copies(size=50, n=[13,7], stagger=true, axes="xz") cylinder(d=5, h=4);
// Example(3D,VPR=[66.90,0.00,36.90],VPD=199.87,VPT=[4.05,9.59,-0.91]): The layout is different with axes="zx"
//   grid_copies(size=50, n=[13,7], stagger=true, axes="zx") cylinder(d=5, h=4);
//
// Example:
//   poly = [[-25,-25], [25,25], [-25,25], [25,-25]];
//   grid_copies(spacing=5, stagger=true, inside=poly)
//      zrot(180/6) cylinder(d=5, h=1, $fn=6);
//   %polygon(poly);
//
// Example: Using `$row` and `$col`
//   grid_copies(spacing=8, n=8)
//       color(($row+$col)%2?"black":"red")
//           cube([8,8,0.01], center=false);
//
// Example: Makes a grid of hexagon pillars whose tops are all angled to reflect light at [0,0,50], if they were shiny.
//   hexregion = circle(r=50.01,$fn=6);
//   grid_copies(spacing=10, stagger=true, inside=hexregion)
//     union() {   // Needed for OpenSCAD 2021.01 as noted above
//       ref_v = (unit([0,0,50]-point3d($pos)) + UP)/2;
//       half_of(v=-ref_v, cp=[0,0,5])
//           zrot(180/6)
//               cylinder(h=20, d=10/cos(180/6)+0.01, $fn=6);
//     }

module grid2d(spacing, n, size, stagger=false, inside=undef, nonzero)
{
   deprecate("grid_copies");
   grid_copies(spacing, n, size, stagger, inside, nonzero) children();
}   

module grid_copies(spacing, n, size, stagger=false, inside=undef, nonzero, axes="xy")
{
    req_children($children);    
    dummy = assert(in_list(stagger, [false, true, "alt"]))
            assert(is_string(axes) && search(axes[0], "xyz")!=[] && search(axes[1], "xyz")!=[] && axes[0]!=axes[1], "Invalid axes specification");
    xind = search("x",axes);
    yind = search("y",axes);
    zind = search("z",axes);        
    permax = function(pt) [xind==[] ? 0 : pt[xind[0]],
                           yind==[] ? 0 : pt[yind[0]],
                           zind==[] ? 0 : pt[zind[0]]];
    bounds = is_undef(inside)? undef :
        is_path(inside)? pointlist_bounds(inside) :
        assert(is_region(inside))
        pointlist_bounds(flatten(inside));
    nonzero = is_path(inside) ? default(nonzero,false)
            : assert(is_undef(nonzero), "nonzero only allowed if inside is a polygon")
              false;
    size = is_num(size)? [size, size] :
        is_vector(size)? assert(len(size)==2) size :
        bounds!=undef? [
            for (i=[0:1]) 2*max(abs(bounds[0][i]),bounds[1][i])
        ] : undef;
    spacing = is_num(spacing)? (
            stagger!=false? polar_to_xy(spacing,60) :
            [spacing,spacing]
        ) :
        is_vector(spacing)? assert(len(spacing)==2) spacing :
        size!=undef? (
            is_num(n)? v_div(size,(n-1)*[1,1]) :
            is_vector(n)? assert(len(n)==2) v_div(size,n-[1,1]) :
            v_div(size,(stagger==false? [1,1] : [2,2]))
        ) :
        undef;
    n = is_num(n)? [n,n] :
        is_vector(n)? assert(len(n)==2) n :
        size!=undef && spacing!=undef? v_floor(v_div(size,spacing))+[1,1] :
        [2,2];
    dummy2 = assert(is_int(n[0]) && is_int(n[1]), "The number of rows/columns must be an integer");
    offset = v_mul(spacing, n-[1,1])/2;

    poslist = 
      stagger==false ? 
               [for (row = [0:1:n.y-1], col = [0:1:n.x-1])
                   let(
                       pos = v_mul([col,row],spacing) - offset
                   )
                   if (
                           is_undef(inside) ||
                           (is_path(inside) && point_in_polygon(pos, inside, nonzero=nonzero)>=0) ||
                           (is_region(inside) && point_in_region(pos, inside)>=0)
                   )
                   [pos,row,col]
               ]
      :
        let(  // stagger == true or stagger == "alt"
            staggermod = (stagger == "alt")? 1 : 0,
            cols1 = ceil(n.x/2),
            cols2 = n.x - cols1
         )
         [for (row = [0:1:n.y-1])
              let(
                rowcols = ((row%2) == staggermod)? cols1 : cols2
              )
              if (rowcols > 0) 
                for (col = [0:1:rowcols-1])
                  let(
                    rowdx = (row%2 != staggermod)? spacing.x : 0,
                    pos = v_mul([2*col,row],spacing) + [rowdx,0] - offset
                  )
                    if (
                        is_undef(inside) ||
                        (is_path(inside) && point_in_polygon(pos, inside, nonzero=nonzero)>=0) ||
                        (is_region(inside) && point_in_region(pos, inside)>=0)
                    )
                    [pos, row, col * 2 + ((row%2!=staggermod)? 1 : 0)]
        ];
    for(i=idx(poslist)){
      $idx=i;
      $pos=permax(poslist[i][0]);
      $row=poslist[i][1];
      $col=poslist[i][2];
      translate(permax(poslist[i][0]))children();
    }
}


function grid_copies(spacing, n, size, stagger=false, inside=undef, nonzero, axes="xy", p=_NO_ARG) =
    let(
        dummy = assert(in_list(stagger, [false, true, "alt"]))
                assert(is_string(axes) && search(axes[0], "xyz")!=[] && search(axes[1], "xyz")!=[] && axes[0]!=axes[1], "Invalid axes specification"),
        xind = search("x",axes),
        yind = search("y",axes),
        zind = search("z",axes),        
        permax = function(pt) [xind==[] ? 0 : pt[xind[0]],
                               yind==[] ? 0 : pt[yind[0]],
                               zind==[] ? 0 : pt[zind[0]]],
        bounds = is_undef(inside)? undef :
            is_path(inside)? pointlist_bounds(inside) :
            assert(is_region(inside))
            pointlist_bounds(flatten(inside)),
        nonzero = is_path(inside) ? default(nonzero,false)
                : assert(is_undef(nonzero), "nonzero only allowed if inside is a polygon")
                  false,
        size = is_num(size)? [size, size] :
            is_vector(size)? assert(len(size)==2) size :
            bounds!=undef? [
                for (i=[0:1]) 2*max(abs(bounds[0][i]),bounds[1][i])
            ] : undef,
        spacing = is_num(spacing)? (
                stagger!=false? polar_to_xy(spacing,60) :
                [spacing,spacing]
            ) :
            is_vector(spacing)? assert(len(spacing)==2) spacing :
            size!=undef? (
                is_num(n)? v_div(size,(n-1)*[1,1]) :
                is_vector(n)? assert(len(n)==2) v_div(size,n-[1,1]) :
                v_div(size,(stagger==false? [1,1] : [2,2]))
            ) :
            undef,
        n = is_num(n)? [n,n] :
            is_vector(n)? assert(len(n)==2) n :
            size!=undef && spacing!=undef? v_floor(v_div(size,spacing))+[1,1] :
            [2,2],
        offset = v_mul(spacing, n-[1,1])/2,
        mats = stagger == false
          ? [
                for (row = [0:1:n.y-1], col = [0:1:n.x-1])
                let( pos = v_mul([col,row],spacing) - offset )
                if (
                    is_undef(inside) ||
                    (is_path(inside) && point_in_polygon(pos, inside, nonzero=nonzero)>=0) ||
                    (is_region(inside) && point_in_region(pos, inside)>=0)
                )
                translate(permax(pos))
            ]
          : // stagger == true or stagger == "alt"
            let(
                staggermod = (stagger == "alt")? 1 : 0,
                cols1 = ceil(n.x/2),
                cols2 = n.x - cols1
            )
            [
                for (row = [0:1:n.y-1])
                let( rowcols = ((row%2) == staggermod)? cols1 : cols2 )
                if (rowcols > 0)
                for (col = [0:1:rowcols-1])
                let(
                    rowdx = (row%2 != staggermod)? spacing.x : 0,
                    pos = v_mul([2*col,row],spacing) + [rowdx,0] - offset
                )
                if (
                    is_undef(inside) ||
                    (is_path(inside) && point_in_polygon(pos, inside, nonzero=nonzero)>=0) ||
                    (is_region(inside) && point_in_region(pos, inside)>=0)
                )
                translate(permax(pos))
            ]
    )
    p==_NO_ARG? mats : [for (m = mats) apply(m, p)];


//////////////////////////////////////////////////////////////////////
// Section: Rotating copies of all children
//////////////////////////////////////////////////////////////////////

// Function&Module: rot_copies()
// Synopsis: Rotates copies of children.
// SynTags: MatList, Trans
// Topics: Transformations, Distributors, Rotation, Copiers
// See Also: rot_copies(), xrot_copies(), yrot_copies(), zrot_copies(), arc_copies(), sphere_copies(), move_copies(), xcopies(), ycopies(), zcopies(), line_copies(), grid_copies() 
//
// Usage:
//   rot_copies(rots, [cp=], [sa=], [delta=], [subrot=]) CHILDREN;
//   rot_copies(rots, v, [cp=], [sa=], [delta=], [subrot=]) CHILDREN;
//   rot_copies(n=, [v=], [cp=], [sa=], [delta=], [subrot=]) CHILDREN;
// Usage: As a function to translate points, VNF, or Bezier patches
//   copies = rot_copies(rots, [cp=], [sa=], [delta=], [subrot=], p=);
//   copies = rot_copies(rots, v, [cp=], [sa=], [delta=], [subrot=], p=);
//   copies = rot_copies(n=, [v=], [cp=], [sa=], [delta=], [subrot=], p=);
// Usage: Get Translation Matrices
//   mats = rot_copies(rots, [cp=], [sa=], [delta=], [subrot=]);
//   mats = rot_copies(rots, v, [cp=], [sa=], [delta=], [subrot=]);
//   mats = rot_copies(n=, [v=], [cp=], [sa=], [delta=], [subrot=]);
// Description:
//   When called as a module:
//   - Given a list of [X,Y,Z] rotation angles in `rots`, rotates copies of the children to each of those angles, regardless of axis of rotation.
//   - Given a list of scalar angles in `rots`, rotates copies of the children to each of those angles around the axis of rotation.
//   - If given a vector `v`, that becomes the axis of rotation.  Default axis of rotation is UP.
//   - If given a count `n`, makes that many copies, rotated evenly around the axis.
//   - If given an offset `delta`, translates each child by that amount before rotating them into place.  This makes rings.
//   - If given a centerpoint `cp`, centers the ring around that centerpoint.
//   - If `subrot` is true, each child will be rotated in place to keep the same size towards the center when making rings.
//   - The first (unrotated) copy will be placed at the relative starting angle `sa`.
//   .
//   When called as a function, *without* a `p=` argument, returns a list of transformation matrices, one for each copy.
//   When called as a function, *with* a `p=` argument, returns a list of transformed copies of `p=`.
//
// Arguments:
//   rots = A list of [X,Y,Z] rotation angles in degrees.  If `v` is given, this will be a list of scalar angles in degrees to rotate around `v`.
//   v = If given, this is the vector of the axis to rotate around.
//   cp = Centerpoint to rotate around.  Default: `[0,0,0]`
//   ---
//   n = Optional number of evenly distributed copies, rotated around the axis.
//   sa = Starting angle, in degrees.  For use with `n`.  Angle is in degrees counter-clockwise.  Default: 0
//   delta = [X,Y,Z] amount to move away from cp before rotating.  Makes rings of copies.  Default: `[0,0,0]`
//   subrot = If false, don't sub-rotate children as they are copied around the ring.  Instead maintain their native orientation.  The false setting is only allowed when `delta` is given.  Default: `true`
//   p = Either a point, pointlist, VNF or Bezier patch to be translated when used as a function.
//
// Side Effects:
//   `$ang` is set to the rotation angle (or XYZ rotation triplet) of each child copy, and can be used to modify each child individually.
//   `$idx` is set to the index value of each child copy.
//   `$axis` is set to the axis to rotate around, if `rots` was given as a list of angles instead of a list of [X,Y,Z] rotation angles.
//
//
// Example:
//   #cylinder(h=20, r1=5, r2=0);
//   rot_copies([[45,0,0],[0,45,90],[90,-45,270]]) cylinder(h=20, r1=5, r2=0);
//
// Example:
//   rot_copies([45, 90, 135], v=DOWN+BACK)
//       yrot(90) cylinder(h=20, r1=5, r2=0);
//   color("red",0.333) yrot(90) cylinder(h=20, r1=5, r2=0);
//
// Example:
//   rot_copies(n=6, v=DOWN+BACK)
//       yrot(90) cylinder(h=20, r1=5, r2=0);
//   color("red",0.333) yrot(90) cylinder(h=20, r1=5, r2=0);
//
// Example:
//   rot_copies(n=6, v=DOWN+BACK, delta=[10,0,0])
//       yrot(90) cylinder(h=20, r1=5, r2=0);
//   color("red",0.333) yrot(90) cylinder(h=20, r1=5, r2=0);
//
// Example:
//   rot_copies(n=6, v=UP+FWD, delta=[10,0,0], sa=45)
//       yrot(90) cylinder(h=20, r1=5, r2=0);
//   color("red",0.333) yrot(90) cylinder(h=20, r1=5, r2=0);
//
// Example:
//   rot_copies(n=6, v=DOWN+BACK, delta=[20,0,0], subrot=false)
//       yrot(90) cylinder(h=20, r1=5, r2=0);
//   color("red",0.333) yrot(90) cylinder(h=20, r1=5, r2=0);
module rot_copies(rots=[], v, cp=[0,0,0], n, sa=0, offset=0, delta=[0,0,0], subrot=true)
{
    assert(subrot || norm(delta)>0, "subrot can only be false if delta is not zero");
    req_children($children);  
    sang = sa + offset;
    angs = !is_undef(n)?
        (n<=0? [] : [for (i=[0:1:n-1]) i/n*360+sang]) :
        rots==[]? [] :
        assert(!is_string(rots), "Argument rots must be an angle, a list of angles, or a range of angles.")
        assert(!is_undef(rots[0]), "Argument rots must be an angle, a list of angles, or a range of angles.")
        [for (a=rots) a];
    for ($idx = idx(angs)) {
        $ang = angs[$idx];
        $axis = v;
        translate(cp) {
            rotate(a=$ang, v=v) {
                translate(delta) { 
                    rot(a=subrot? 0 : $ang, v=v, reverse=true) {
                        translate(-cp) {
                            children();
                        }
                    }
                }
            }
        }
    }
}


function rot_copies(rots=[], v, cp=[0,0,0], n, sa=0, offset=0, delta=[0,0,0], subrot=true, p=_NO_ARG) =
    assert(subrot || norm(delta)>0, "subrot can only be false if delta is not zero")
    let(
        sang = sa + offset,
        angs = !is_undef(n)?
            (n<=0? [] : [for (i=[0:1:n-1]) i/n*360+sang]) :
            rots==[]? [] :
            assert(!is_string(rots), "Argument rots must be an angle, a list of angles, or a range of angles.")
            assert(!is_undef(rots[0]), "Argument rots must be an angle, a list of angles, or a range of angles.")
            [for (a=rots) a],
        mats = [
            for (ang = angs)
            translate(cp) *
                rot(a=ang, v=v) *
                translate(delta) *
                rot(a=subrot? 0 : ang, v=v, reverse=true) *
                translate(-cp)
        ]
    )
    p==_NO_ARG? mats : [for (m = mats) apply(m, p)];


// Function&Module: xrot_copies()
// Synopsis: Rotates copies of children around the X axis.
// SynTags: MatList, Trans
// Topics: Transformations, Distributors, Rotation, Copiers
// See Also: rot_copies(), xrot_copies(), yrot_copies(), zrot_copies(), arc_copies(), sphere_copies(), move_copies(), xcopies(), ycopies(), zcopies(), line_copies(), grid_copies() 
//
// Usage:
//   xrot_copies(rots, [cp], [r=|d=], [sa=], [subrot=]) CHILDREN;
//   xrot_copies(n=, [cp=], [r=|d=], [sa=], [subrot=]) CHILDREN;
// Usage: As a function to translate points, VNF, or Bezier patches
//   copies = xrot_copies(rots, [cp], [r=|d=], [sa=], [subrot=], p=);
//   copies = xrot_copies(n=, [cp=], [r=|d=], [sa=], [subrot=], p=);
// Usage: Get Translation Matrices
//   mats = xrot_copies(rots, [cp], [r=|d=], [sa=], [subrot=]);
//   mats = xrot_copies(n=, [cp=], [r=|d=], [sa=], [subrot=]);
// Description:
//   When called as a module:
//   - Given an array of angles, rotates copies of the children to each of those angles around the X axis.
//   - If given a count `n`, makes that many copies, rotated evenly around the X axis.
//   - If given a radius `r` (or diameter `d`), distributes children around a ring of that size around the X axis.
//   - If given a centerpoint `cp`, centers the rotation around that centerpoint.
//   - If `subrot` is true, each child will be rotated in place to keep the same size towards the center when making rings.
//   - The first (unrotated) copy will be placed at the relative starting angle `sa`.
//   .
//   When called as a function, *without* a `p=` argument, returns a list of transformation matrices, one for each copy.
//   When called as a function, *with* a `p=` argument, returns a list of transformed copies of `p=`.
//
// Arguments:
//   rots = Optional array of rotation angles, in degrees, to make copies at.
//   cp = Centerpoint to rotate around.
//   ---
//   n = Optional number of evenly distributed copies to be rotated around the ring.
//   sa = Starting angle, in degrees.  For use with `n`.  Angle is in degrees counter-clockwise from Y+, when facing the origin from X+.  First unrotated copy is placed at that angle.
//   r = If given, makes a ring of child copies around the X axis, at the given radius.  Default: 0
//   d = If given, makes a ring of child copies around the X axis, at the given diameter.
//   subrot = If false, don't sub-rotate children as they are copied around the ring.  Instead maintain their native orientation.  The false setting is only allowed when `d` or `r` is given.  Default: `true`
//   subrot = If false, don't sub-rotate children as they are copied around the ring.
//   p = Either a point, pointlist, VNF or Bezier patch to be translated when used as a function.
//
// Side Effects:
//   `$idx` is set to the index value of each child copy.
//   `$ang` is set to the rotation angle of each child copy, and can be used to modify each child individually.
//   `$axis` is set to the axis vector rotated around.
//
//
// Example:
//   xrot_copies([180, 270, 315])
//       cylinder(h=20, r1=5, r2=0);
//   color("red",0.333) cylinder(h=20, r1=5, r2=0);
//
// Example:
//   xrot_copies(n=6)
//       cylinder(h=20, r1=5, r2=0);
//   color("red",0.333) cylinder(h=20, r1=5, r2=0);
//
// Example:
//   xrot_copies(n=6, r=10)
//       xrot(-90) cylinder(h=20, r1=5, r2=0);
//   color("red",0.333) xrot(-90) cylinder(h=20, r1=5, r2=0);
//
// Example:
//   xrot_copies(n=6, r=10, sa=45)
//       xrot(-90) cylinder(h=20, r1=5, r2=0);
//   color("red",0.333) xrot(-90) cylinder(h=20, r1=5, r2=0);
//
// Example:
//   xrot_copies(n=6, r=20, subrot=false)
//       xrot(-90) cylinder(h=20, r1=5, r2=0, center=true);
//   color("red",0.333) xrot(-90) cylinder(h=20, r1=5, r2=0, center=true);
module xrot_copies(rots=[], cp=[0,0,0], n, sa=0, r, d, subrot=true)
{
    req_children($children);  
    r = get_radius(r=r, d=d, dflt=0);
    assert(all_nonnegative([r]), "d/r must be nonnegative");
    assert(subrot || r>0, "subrot can only be false if d or r is given");
    rot_copies(rots=rots, v=RIGHT, cp=cp, n=n, sa=sa, delta=[0, r, 0], subrot=subrot) children();
}


function xrot_copies(rots=[], cp=[0,0,0], n, sa=0, r, d, subrot=true, p=_NO_ARG) =
    let( r = get_radius(r=r, d=d, dflt=0) )
    assert(all_nonnegative([r]), "d/r must be nonnegative")
    assert(subrot || r>0, "subrot can only be false if d or r is given")
    rot_copies(rots=rots, v=RIGHT, cp=cp, n=n, sa=sa, delta=[0, r, 0], subrot=subrot, p=p);


// Function&Module: yrot_copies()
// Synopsis: Rotates copies of children around the Y axis.
// SynTags: MatList, Trans
// Topics: Transformations, Distributors, Rotation, Copiers
// See Also: rot_copies(), xrot_copies(), yrot_copies(), zrot_copies(), arc_copies(), sphere_copies(), move_copies(), xcopies(), ycopies(), zcopies(), line_copies(), grid_copies() 
//
// Usage:
//   yrot_copies(rots, [cp], [r=|d=], [sa=], [subrot=]) CHILDREN;
//   yrot_copies(n=, [cp=], [r=|d=], [sa=], [subrot=]) CHILDREN;
// Usage: As a function to translate points, VNF, or Bezier patches
//   copies = yrot_copies(rots, [cp], [r=|d=], [sa=], [subrot=], p=);
//   copies = yrot_copies(n=, [cp=], [r=|d=], [sa=], [subrot=], p=);
// Usage: Get Translation Matrices
//   mats = yrot_copies(rots, [cp], [r=|d=], [sa=], [subrot=]);
//   mats = yrot_copies(n=, [cp=], [r=|d=], [sa=], [subrot=]);
// Description:
//   When called as a module:
//   - Given an array of angles, rotates copies of the children to each of those angles around the Y axis.
//   - If given a count `n`, makes that many copies, rotated evenly around the Y axis.
//   - If given a radius `r` (or diameter `d`), distributes children around a ring of that size around the Y axis.
//   - If given a centerpoint `cp`, centers the rotation around that centerpoint.
//   - If `subrot` is true, each child will be rotated in place to keep the same size towards the center when making rings.
//   - The first (unrotated) copy will be placed at the relative starting angle `sa`.
//   .
//   When called as a function, *without* a `p=` argument, returns a list of transformation matrices, one for each copy.
//   When called as a function, *with* a `p=` argument, returns a list of transformed copies of `p=`.
//
// Arguments:
//   rots = Optional array of rotation angles, in degrees, to make copies at.
//   cp = Centerpoint to rotate around.
//   ---
//   n = Optional number of evenly distributed copies to be rotated around the ring.
//   sa = Starting angle, in degrees.  For use with `n`.  Angle is in degrees counter-clockwise from X-, when facing the origin from Y+.
//   r = If given, makes a ring of child copies around the Y axis, at the given radius.  Default: 0
//   d = If given, makes a ring of child copies around the Y axis, at the given diameter.
//   subrot = If false, don't sub-rotate children as they are copied around the ring.  Instead maintain their native orientation.  The false setting is only allowed when `d` or `r` is given.  Default: `true`
//   p = Either a point, pointlist, VNF or Bezier patch to be translated when used as a function.
//
// Side Effects:
//   `$idx` is set to the index value of each child copy.
//   `$ang` is set to the rotation angle of each child copy, and can be used to modify each child individually.
//   `$axis` is set to the axis vector rotated around.
//
//
// Example:
//   yrot_copies([180, 270, 315])
//       cylinder(h=20, r1=5, r2=0);
//   color("red",0.333) cylinder(h=20, r1=5, r2=0);
//
// Example:
//   yrot_copies(n=6)
//       cylinder(h=20, r1=5, r2=0);
//   color("red",0.333) cylinder(h=20, r1=5, r2=0);
//
// Example:
//   yrot_copies(n=6, r=10)
//       yrot(-90) cylinder(h=20, r1=5, r2=0);
//   color("red",0.333) yrot(-90) cylinder(h=20, r1=5, r2=0);
//
// Example:
//   yrot_copies(n=6, r=10, sa=45)
//       yrot(-90) cylinder(h=20, r1=5, r2=0);
//   color("red",0.333) yrot(-90) cylinder(h=20, r1=5, r2=0);
//
// Example:
//   yrot_copies(n=6, r=20, subrot=false)
//       yrot(-90) cylinder(h=20, r1=5, r2=0, center=true);
//   color("red",0.333) yrot(-90) cylinder(h=20, r1=5, r2=0, center=true);
module yrot_copies(rots=[], cp=[0,0,0], n, sa=0, r, d, subrot=true)
{
    req_children($children);
    r = get_radius(r=r, d=d, dflt=0);
    assert(all_nonnegative([r]), "d/r must be nonnegative");
    assert(subrot || r>0, "subrot can only be false if d or r is given");
    rot_copies(rots=rots, v=BACK, cp=cp, n=n, sa=sa, delta=[-r, 0, 0], subrot=subrot) children();
}


function yrot_copies(rots=[], cp=[0,0,0], n, sa=0, r, d, subrot=true, p=_NO_ARG) =
    let( r = get_radius(r=r, d=d, dflt=0) )
    assert(all_nonnegative([r]), "d/r must be nonnegative")
    assert(subrot || r>0, "subrot can only be false if d or r is given")
    rot_copies(rots=rots, v=BACK, cp=cp, n=n, sa=sa, delta=[-r, 0, 0], subrot=subrot, p=p);


// Function&Module: zrot_copies()
// Synopsis: Rotates copies of children around the Z axis.
// SynTags: MatList, Trans
// Topics: Transformations, Distributors, Rotation, Copiers
// See Also: rot_copies(), xrot_copies(), yrot_copies(), zrot_copies(), arc_copies(), sphere_copies(), move_copies(), xcopies(), ycopies(), zcopies(), line_copies(), grid_copies() 
//
// Usage:
//   zrot_copies(rots, [cp], [r=|d=], [sa=], [subrot=]) CHILDREN;
//   zrot_copies(n=, [cp=], [r=|d=], [sa=], [subrot=]) CHILDREN;
// Usage: As a function to translate points, VNF, or Bezier patches
//   copies = zrot_copies(rots, [cp], [r=|d=], [sa=], [subrot=], p=);
//   copies = zrot_copies(n=, [cp=], [r=|d=], [sa=], [subrot=], p=);
// Usage: Get Translation Matrices
//   mats = zrot_copies(rots, [cp], [r=|d=], [sa=], [subrot=]);
//   mats = zrot_copies(n=, [cp=], [r=|d=], [sa=], [subrot=]);
//
// Description:
//   When called as a module:
//   - Given an array of angles, rotates copies of the children to each of those angles around the Z axis.
//   - If given a count `n`, makes that many copies, rotated evenly around the Z axis.
//   - If given a radius `r` (or diameter `d`), distributes children around a ring of that size around the Z axis.
//   - If given a centerpoint `cp`, centers the rotation around that centerpoint.
//   - If `subrot` is true, each child will be rotated in place to keep the same size towards the center when making rings.
//   - The first (unrotated) copy will be placed at the relative starting angle `sa`.
//   .
//   When called as a function, *without* a `p=` argument, returns a list of transformation matrices, one for each copy.
//   When called as a function, *with* a `p=` argument, returns a list of transformed copies of `p=`.
//
// Arguments:
//   rots = Optional array of rotation angles, in degrees, to make copies at.
//   cp = Centerpoint to rotate around.  Default: [0,0,0]
//   ---
//   n = Optional number of evenly distributed copies to be rotated around the ring.
//   sa = Starting angle, in degrees.  For use with `n`.  Angle is in degrees counter-clockwise from X+, when facing the origin from Z+.  Default: 0
//   r = If given, makes a ring of child copies around the Z axis, at the given radius.  Default: 0
//   d = If given, makes a ring of child copies around the Z axis, at the given diameter.
//   subrot = If false, don't sub-rotate children as they are copied around the ring.  Instead maintain their native orientation.  The false setting is only allowed when `d` or `r` is given.  Default: `true`
//   p = Either a point, pointlist, VNF or Bezier patch to be translated when used as a function.
//
// Side Effects:
//   `$idx` is set to the index value of each child copy.
//   `$ang` is set to the rotation angle of each child copy, and can be used to modify each child individually.
//   `$axis` is set to the axis vector rotated around.
//
//
// Example:
//   zrot_copies([180, 270, 315])
//       yrot(90) cylinder(h=20, r1=5, r2=0);
//   color("red",0.333) yrot(90) cylinder(h=20, r1=5, r2=0);
//
// Example:
//   zrot_copies(n=6)
//       yrot(90) cylinder(h=20, r1=5, r2=0);
//   color("red",0.333) yrot(90) cylinder(h=20, r1=5, r2=0);
//
// Example:
//   zrot_copies(n=6, r=10)
//       yrot(90) cylinder(h=20, r1=5, r2=0);
//   color("red",0.333) yrot(90) cylinder(h=20, r1=5, r2=0);
//
// Example:
//   zrot_copies(n=6, r=20, sa=45)
//       yrot(90) cylinder(h=20, r1=5, r2=0, center=true);
//   color("red",0.333) yrot(90) cylinder(h=20, r1=5, r2=0, center=true);
//
// Example:
//   zrot_copies(n=6, r=20, subrot=false)
//       yrot(-90) cylinder(h=20, r1=5, r2=0, center=true);
//   color("red",0.333) yrot(-90) cylinder(h=20, r1=5, r2=0, center=true);
module zrot_copies(rots=[], cp=[0,0,0], n, sa=0, r, d, subrot=true)
{
    req_children($children);
    r = get_radius(r=r, d=d, dflt=0);
    assert(all_nonnegative([r]), "d/r must be nonnegative");
    assert(subrot || r>0, "subrot can only be false if d or r is given");
    rot_copies(rots=rots, v=UP, cp=cp, n=n, sa=sa, delta=[r, 0, 0], subrot=subrot) children();
}


function zrot_copies(rots=[], cp=[0,0,0], n, sa=0, r, d, subrot=true, p=_NO_ARG) =
    let( r = get_radius(r=r, d=d, dflt=0) )
    assert(all_nonnegative([r]), "d/r must be nonnegative")
    assert(subrot || r>0, "subrot can only be false if d or r is given")
    rot_copies(rots=rots, v=UP, cp=cp, n=n, sa=sa, delta=[r, 0, 0], subrot=subrot, p=p);


// Function&Module: arc_copies()
// Synopsis: Distributes duplicates of children along an arc.
// SynTags: MatList, Trans
// Topics: Transformations, Distributors, Rotation, Copiers
// See Also: rot_copies(), xrot_copies(), yrot_copies(), zrot_copies(), sphere_copies(), move_copies(), xcopies(), ycopies(), zcopies(), line_copies(), grid_copies() 
//
// Usage:
//   arc_copies(n, r|d=, [sa=], [ea=], [rot=]) CHILDREN;
//   arc_copies(n, rx=|dx=, ry=|dy=, [sa=], [ea=], [rot=]) CHILDREN;
// Usage: As a function to translate points, VNF, or Bezier patches
//   copies = arc_copies(n, r|d=, [sa=], [ea=], [rot=], p=);
//   copies = arc_copies(n, rx=|dx=, ry=|dy=, [sa=], [ea=], [rot=], p=);
// Usage: Get Translation Matrices
//   mats = arc_copies(n, r|d=, [sa=], [ea=], [rot=]);
//   mats = arc_copies(n, rx=|dx=, ry=|dy=, [sa=], [ea=], [rot=]);
//
//
// Description:
//   When called as a module, evenly distributes n duplicate children around an elliptical arc on the XY plane.
//   When called as a function, *without* a `p=` argument, returns a list of transformation matrices, one for each copy.
//   When called as a function, *with* a `p=` argument, returns a list of transformed copies of `p=`.
//
// Arguments:
//   n = number of copies to distribute around the circle. (Default: 6)
//   r = radius of circle (Default: 1)
//   ---
//   rx = radius of ellipse on X axis. Used instead of r.
//   ry = radius of ellipse on Y axis. Used instead of r.
//   d = diameter of circle. (Default: 2)
//   dx = diameter of ellipse on X axis. Used instead of d.
//   dy = diameter of ellipse on Y axis. Used instead of d.
//   rot = whether to rotate the copied children.  (Default: true)
//   sa = starting angle. (Default: 0.0)
//   ea = ending angle. Will distribute copies CCW from sa to ea. (Default: 360.0)
//   p = Either a point, pointlist, VNF or Bezier patch to be translated when used as a function.
//
// Side Effects:
//   `$ang` is set to the rotation angle of each child copy, and can be used to modify each child individually.
//   `$pos` is set to the relative centerpoint of each child copy, and can be used to modify each child individually.
//   `$idx` is set to the index value of each child copy.
//
//
// Example:
//   #cube(size=[10,3,3],center=true);
//   arc_copies(d=40, n=5) cube(size=[10,3,3],center=true);
//
// Example:
//   #cube(size=[10,3,3],center=true);
//   arc_copies(d=40, n=5, sa=45, ea=225) cube(size=[10,3,3],center=true);
//
// Example:
//   #cube(size=[10,3,3],center=true);
//   arc_copies(r=15, n=8, rot=false) cube(size=[10,3,3],center=true);
//
// Example:
//   #cube(size=[10,3,3],center=true);
//   arc_copies(rx=20, ry=10, n=8) cube(size=[10,3,3],center=true);
// Example(2D): Using `$idx` to alternate shapes
//   arc_copies(r=50, n=19, sa=0, ea=180)
//       if ($idx % 2 == 0) rect(6);
//       else circle(d=6);

module arc_of(n=6,r,rx,ry,d,dx,dy,sa=0,ea=360,rot=true){
    deprecate("arc_copies");
    arc_copies(n,r,rx,ry,d,dx,dy,sa,ea,rot) children();
}    


module arc_copies(
    n=6,
    r=undef,
    rx=undef, ry=undef,
    d=undef, dx=undef, dy=undef,
    sa=0, ea=360,
    rot=true
) {
    req_children($children);
    rx = get_radius(r1=rx, r=r, d1=dx, d=d, dflt=1);
    ry = get_radius(r1=ry, r=r, d1=dy, d=d, dflt=1);
    sa = posmod(sa, 360);
    ea = posmod(ea, 360);
    extra_n = (abs(ea-sa)<0.01)?1:0;
    delt = (((ea<=sa)?360.0:0)+ea-sa)/(n-1+extra_n);
    for ($idx = [0:1:n-1]) {
        $ang = sa + ($idx * delt);
        $pos =[rx*cos($ang), ry*sin($ang), 0];
        translate($pos) {
            zrot(rot? atan2(ry*sin($ang), rx*cos($ang)) : 0) {
                children();
            }
        }
    }
}


function arc_copies(
    n=6,
    r=undef,
    rx=undef, ry=undef,
    d=undef, dx=undef, dy=undef,
    sa=0, ea=360,
    rot=true,
    p=_NO_ARG
) =
    let(
        rx = get_radius(r1=rx, r=r, d1=dx, d=d, dflt=1),
        ry = get_radius(r1=ry, r=r, d1=dy, d=d, dflt=1),
        sa = posmod(sa, 360),
        ea = posmod(ea, 360),
        extra_n = (abs(ea-sa)<0.01)?1:0,
        delt = (((ea<=sa)?360.0:0)+ea-sa)/(n-1+extra_n),
        mats = [
            for (i = [0:1:n-1])
            let(
                ang = sa + (i * delt),
                pos =[rx*cos(ang), ry*sin(ang), 0],
                ang2 = rot? atan2(ry*sin(ang), rx*cos(ang)) : 0
            )
            translate(pos) * zrot(ang2)
        ]
    )
    p==_NO_ARG? mats : [for (m = mats) apply(m, p)];



// Function&Module: sphere_copies()
// Synopsis: Distributes copies of children over the surface of a sphere. 
// SynTags: MatList, Trans
// Topics: Transformations, Distributors, Rotation, Copiers
// See Also: rot_copies(), xrot_copies(), yrot_copies(), zrot_copies(), arc_copies(), move_copies(), xcopies(), ycopies(), zcopies(), line_copies(), grid_copies() 
//
// Usage:
//   sphere_copies(n, r|d=, [cone_ang=], [scale=], [perp=]) CHILDREN;
// Usage: As a function to translate points, VNF, or Bezier patches
//   copies = sphere_copies(n, r|d=, [cone_ang=], [scale=], [perp=], p=);
// Usage: Get Translation Matrices
//   mats = sphere_copies(n, r|d=, [cone_ang=], [scale=], [perp=]);
//
// Description:
//   When called as a module, spreads children semi-evenly over the surface of a sphere or ellipsoid.
//   When called as a function, *without* a `p=` argument, returns a list of transformation matrices, one for each copy.
//   When called as a function, *with* a `p=` argument, returns a list of transformed copies of `p=`.
//
// Arguments:
//   n = How many copies to evenly spread over the surface.
//   r = Radius of the sphere to distribute over
//   ---
//   d = Diameter of the sphere to distribute over
//   cone_ang = Angle of the cone, in degrees, to limit how much of the sphere gets covered.  For full sphere coverage, use 180.  Measured pre-scaling.  Default: 180
//   scale = The [X,Y,Z] scaling factors to reshape the sphere being covered.
//   perp = If true, rotate children to be perpendicular to the sphere surface.  Default: true
//   p = Either a point, pointlist, VNF or Bezier patch to be translated when used as a function.
//
// Side Effects:
//   `$pos` is set to the relative post-scaled centerpoint of each child copy, and can be used to modify each child individually.
//   `$theta` is set to the theta angle of the child from the center of the sphere.
//   `$phi` is set to the pre-scaled phi angle of the child from the center of the sphere.
//   `$rad` is set to the pre-scaled radial distance of the child from the center of the sphere.
//   `$idx` is set to the index number of each child being copied.
//
//
// Example:
//   sphere_copies(n=250, d=100, cone_ang=45, scale=[3,3,1])
//       cylinder(d=10, h=10, center=false);
//
// Example:
//   sphere_copies(n=500, d=100, cone_ang=180)
//       color(unit(point3d(v_abs($pos))))
//           cylinder(d=8, h=10, center=false);

module ovoid_spread(n=100, r=undef, d=undef, cone_ang=90, scale=[1,1,1], perp=true)
{
  deprecate("sphere_copies");
  sphere_copies(n,r,d,cone_ang,scale,perp) children();
}  


module sphere_copies(n=100, r=undef, d=undef, cone_ang=90, scale=[1,1,1], perp=true)
{
    req_children($children);  
    r = get_radius(r=r, d=d, dflt=50);
    cnt = ceil(n / (cone_ang/180));

    // Calculate an array of [theta,phi] angles for `n` number of
    // points, almost evenly spaced across the surface of a sphere.
    // This approximation is based on the golden spiral method.
    theta_phis = [for (x=[0:1:n-1]) [180*(1+sqrt(5))*(x+0.5)%360, acos(1-2*(x+0.5)/cnt)]];

    for ($idx = idx(theta_phis)) {
        tp = theta_phis[$idx];
        xyz = spherical_to_xyz(r, tp[0], tp[1]);
        $pos = v_mul(xyz,point3d(scale,1));
        $theta = tp[0];
        $phi = tp[1];
        $rad = r;
        translate($pos) {
            if (perp) {
                rot(from=UP, to=xyz) children();
            } else {
                children();
            }
        }
    }
}


function sphere_copies(n=100, r=undef, d=undef, cone_ang=90, scale=[1,1,1], perp=true, p=_NO_ARG) =
    let(
        r = get_radius(r=r, d=d, dflt=50),
        cnt = ceil(n / (cone_ang/180)),

        // Calculate an array of [theta,phi] angles for `n` number of
        // points, almost evenly spaced across the surface of a sphere.
        // This approximation is based on the golden spiral method.
        theta_phis = [for (x=[0:1:n-1]) [180*(1+sqrt(5))*(x+0.5)%360, acos(1-2*(x+0.5)/cnt)]],

        mats = [
            for (tp = theta_phis)
            let(
                xyz = spherical_to_xyz(r, tp[0], tp[1]),
                pos = v_mul(xyz,point3d(scale,1))
            )
            translate(pos) *
            (perp? rot(from=UP, to=xyz) : ident(4))
        ]
    )
    p==_NO_ARG? mats : [for (m = mats) apply(m, p)];



// Section: Placing copies of all children on a path


// Function&Module: path_copies()
// Synopsis: Uniformly distributes copies of children along a path.
// SynTags: MatList, Trans
// Topics: Transformations, Distributors, Copiers
// See Also: line_copies(), move_copies(), xcopies(), ycopies(), zcopies(), grid_copies(), xflip_copy(), yflip_copy(), zflip_copy(), mirror_copy()
//
// Usage: Uniformly distribute copies 
//   path_copies(path, [n], [spacing], [sp], [rotate_children], [closed=]) CHILDREN;
// Usage: Place copies at specified locations
//   path_copies(path, dist=, [rotate_children=], [closed=]) CHILDREN;
// Usage: As a function to translate points, VNF, or Bezier patches
//   copies = path_copies(path, [n], [spacing], [sp], [rotate_children], [closed=], p=);
//   copies = path_copies(path, dist=, [rotate_children=], [closed=], p=);
// Usage: Get Translation Matrices
//   mats = path_copies(path, [n], [spacing], [sp], [rotate_children], [closed=]);
//   mats = path_copies(path, dist=, [rotate_children=], [closed=]);
//
// Description:
//   When called as a module:
//   - Place copies all of the children at points along the path based on path length.  You can specify `dist` as
//   - a scalar or distance list and the children will be placed at the specified distances from the start of the path.  Otherwise the children are
//   - placed at uniformly spaced points along the path.  If you specify `n` but not `spacing` then `n` copies will be placed
//   - with one at path[0] if `closed` is true, or spanning the entire path from start to end if `closed` is false.
//   - If you specify `spacing` but not `n` then copies will spread out starting from one set at path[0] for `closed=true` or at the path center for open paths.
//   - If you specify `sp` then the copies will start at distance `sp` from the start of the path.
//   .
//   When called as a function, *without* a `p=` argument, returns a list of transformation matrices, one for each copy.
//   When called as a function, *with* a `p=` argument, returns a list of transformed copies of `p=`.
//
// Arguments:
//   path = path or 1-region where children are placed
//   n = number of copies
//   spacing = space between copies
//   sp = if given, copies will start distance sp from the path start and spread beyond that point
//   rotate_children = if true, rotate children to line up with curve normal.  Default: true
//   ---
//   dist = Specify a list of distances to determine placement of children.  
//   closed = If true treat path as a closed curve.  Default: false
//   p = Either a point, pointlist, VNF or Bezier patch to be translated when used as a function.
//
// Side Effects:
//   `$pos` is set to the center of each copy
//   `$idx` is set to the index number of each copy.  In the case of closed paths the first copy is at `path[0]` unless you give `sp`.
//   `$dir` is set to the direction vector of the path at the point where the copy is placed.
//   `$normal` is set to the direction of the normal vector to the path direction that is coplanar with the path at this point
//
//
// Example(2D):
//   spiral = [for(theta=[0:360*8]) theta * [cos(theta), sin(theta)]]/100;
//   stroke(spiral,width=.25);
//   color("red") path_copies(spiral, n=100) circle(r=1);
// Example(2D):
//   circle = regular_ngon(n=64, or=10);
//   stroke(circle,width=1,closed=true);
//   color("green") path_copies(circle, n=7, closed=true) circle(r=1+$idx/3);
// Example(2D):
//   heptagon = regular_ngon(n=7, or=10);
//   stroke(heptagon, width=1, closed=true);
//   color("purple") path_copies(heptagon, n=9, closed=true) rect([0.5,3],anchor=FRONT);
// Example(2D): Direction at the corners is the average of the two adjacent edges
//   heptagon = regular_ngon(n=7, or=10);
//   stroke(heptagon, width=1, closed=true);
//   color("purple") path_copies(heptagon, n=7, closed=true) rect([0.5,3],anchor=FRONT);
// Example(2D):  Don't rotate the children
//   heptagon = regular_ngon(n=7, or=10);
//   stroke(heptagon, width=1, closed=true);
//   color("red") path_copies(heptagon, n=9, closed=true, rotate_children=false) rect([0.5,3],anchor=FRONT);
// Example(2D): Open path, specify `n`
//   sinwav = [for(theta=[0:360]) 5*[theta/180, sin(theta)]];
//   stroke(sinwav,width=.1);
//   color("red") path_copies(sinwav, n=5) rect([.2,1.5],anchor=FRONT);
// Example(2D): Open path, specify `n` and `spacing`
//   sinwav = [for(theta=[0:360]) 5*[theta/180, sin(theta)]];
//   stroke(sinwav,width=.1);
//   color("red") path_copies(sinwav, n=5, spacing=1) rect([.2,1.5],anchor=FRONT);
// Example(2D): Closed path, specify `n` and `spacing`, copies centered around circle[0]
//   circle = regular_ngon(n=64,or=10);
//   stroke(circle,width=.1,closed=true);
//   color("red") path_copies(circle, n=10, spacing=1, closed=true) rect([.2,1.5],anchor=FRONT);
// Example(2D): Open path, specify `spacing`
//   sinwav = [for(theta=[0:360]) 5*[theta/180, sin(theta)]];
//   stroke(sinwav,width=.1);
//   color("red") path_copies(sinwav, spacing=5) rect([.2,1.5],anchor=FRONT);
// Example(2D): Open path, specify `sp`
//   sinwav = [for(theta=[0:360]) 5*[theta/180, sin(theta)]];
//   stroke(sinwav,width=.1);
//   color("red") path_copies(sinwav, n=5, sp=18) rect([.2,1.5],anchor=FRONT);
// Example(2D): Open path, specify `dist`
//   sinwav = [for(theta=[0:360]) 5*[theta/180, sin(theta)]];
//   stroke(sinwav,width=.1);
//   color("red") path_copies(sinwav, dist=[1,4,9,16]) rect([.2,1.5],anchor=FRONT);
// Example(2D):
//   wedge = arc(angle=[0,100], r=10, $fn=64);
//   difference(){
//     polygon(concat([[0,0]],wedge));
//     path_copies(wedge,n=5,spacing=3) fwd(.1) rect([1,4],anchor=FRONT);
//   }
// Example(Spin,VPD=115): 3d example, with children rotated into the plane of the path
//   tilted_circle = lift_plane([[0,0,0], [5,0,5], [0,2,3]],regular_ngon(n=64, or=12));
//   path_sweep(regular_ngon(n=16,or=.1),tilted_circle);
//   path_copies(tilted_circle, n=15,closed=true) {
//      color("blue") cyl(h=3,r=.2, anchor=BOTTOM);      // z-aligned cylinder
//      color("red") xcyl(h=10,r=.2, anchor=FRONT+LEFT); // x-aligned cylinder
//   }
// Example(Spin,VPD=115): 3d example, with rotate_children set to false
//   tilted_circle = lift_plane([[0,0,0], [5,0,5], [0,2,3]], regular_ngon(n=64, or=12));
//   path_sweep(regular_ngon(n=16,or=.1),tilted_circle);
//   path_copies(tilted_circle, n=25,rotate_children=false,closed=true) {
//      color("blue") cyl(h=3,r=.2, anchor=BOTTOM);       // z-aligned cylinder
//      color("red") xcyl(h=10,r=.2, anchor=FRONT+LEFT);  // x-aligned cylinder
//   }

module path_spread(path, n, spacing, sp=undef, rotate_children=true, dist, closed){
  deprecate("path_copes");
  path_copies(path,n,spacing,sp,dist,rotate_children,dist, closed) children();
}  


module path_copies(path, n, spacing, sp=undef, dist, rotate_children=true, dist, closed)
{
    req_children($children);  
    is_1reg = is_1region(path);
    path = is_1reg ? path[0] : path;
    closed = default(closed, is_1reg);
    length = path_length(path,closed);
    distind = is_def(dist) ? sortidx(dist) : undef;
    distances =
        is_def(dist) ? assert(is_undef(n) && is_undef(spacing) && is_undef(sp), "Can't use n, spacing or undef with dist")
                       select(dist,distind)
      : is_def(sp)? (   // Start point given
            is_def(n) && is_def(spacing)? count(n,sp,spacing) :
            is_def(n)? lerpn(sp, length, n) :
            list([sp:spacing:length])
        )
      : is_def(n) && is_undef(spacing)? lerpn(0,length,n,!closed) // N alone given
      : (      // No start point and spacing is given, N maybe given
        let(
            n = is_def(n)? n : floor(length/spacing)+(closed?0:1),
            ptlist = count(n,0,spacing),
            listcenter = mean(ptlist)
        ) closed?
            sort([for(entry=ptlist) posmod(entry-listcenter,length)]) :
            [for(entry=ptlist) entry + length/2-listcenter ]
    );
    distOK = min(distances)>=0 && max(distances)<=length;
    dummy = assert(distOK,"Cannot fit all of the copies");
    cutlist = path_cut_points(path, distances, closed, direction=true);
    planar = len(path[0])==2;
    for(i=[0:1:len(cutlist)-1]) {
        $pos = cutlist[i][0];
        $idx = is_def(dist) ? distind[i] : i;
        $dir = !rotate_children ? (planar?[1,0]:[1,0,0]) : cutlist[i][2];
        $normal = !rotate_children? (planar?[0,1]:[0,0,1]) : cutlist[i][3];
        translate($pos) {
            if (rotate_children) {
                if(planar) {
                    rot(from=[0,1],to=cutlist[i][3]) children();
                } else {
                    frame_map(x=cutlist[i][2], z=cutlist[i][3])
                        children();
                }
            } else {
                children();
            }
        }
    }
}


function path_copies(path, n, spacing, sp=undef, dist, rotate_children=true, dist, closed, p=_NO_ARG) =
    let(
        is_1reg = is_1region(path),
        path = is_1reg ? path[0] : path,
        closed = default(closed, is_1reg),
        length = path_length(path,closed),
        distind = is_def(dist) ? sortidx(dist) : undef,
        distances =
            is_def(dist) ? assert(is_undef(n) && is_undef(spacing) && is_undef(sp), "Can't use n, spacing or undef with dist")
                           select(dist,distind)
          : is_def(sp)? (   // Start point given
                is_def(n) && is_def(spacing)? count(n,sp,spacing) :
                is_def(n)? lerpn(sp, length, n) :
                list([sp:spacing:length])
            )
          : is_def(n) && is_undef(spacing)? lerpn(0,length,n,!closed) // N alone given
          : (      // No start point and spacing is given, N maybe given
            let(
                n = is_def(n)? n : floor(length/spacing)+(closed?0:1),
                ptlist = count(n,0,spacing),
                listcenter = mean(ptlist)
            ) closed?
                sort([for(entry=ptlist) posmod(entry-listcenter,length)]) :
                [for(entry=ptlist) entry + length/2-listcenter ]
          ),
        distOK = min(distances)>=0 && max(distances)<=length,
        dummy = assert(distOK,"Cannot fit all of the copies"),
        cutlist = path_cut_points(path, distances, closed, direction=true),
        planar = len(path[0])==2,
        mats = [
            for(i=[0:1:len(cutlist)-1])
            translate(cutlist[i][0]) * (
                !rotate_children? ident(4) :
                planar? rot(from=[0,1],to=cutlist[i][3]) :
                frame_map(x=cutlist[i][2], z=cutlist[i][3])
            )
        ]
    )
    p==_NO_ARG? mats : [for (m = mats) apply(m, p)];



//////////////////////////////////////////////////////////////////////
// Section: Making a copy of all children with reflection
//////////////////////////////////////////////////////////////////////

// Function&Module: xflip_copy()
// Synopsis: Makes a copy of children mirrored across the X axis.
// SynTags: MatList, Trans
// Topics: Transformations, Distributors, Translation, Copiers
// See Also: yflip_copy(), zflip_copy(), mirror_copy(), path_copies(), move_copies(), xcopies(), ycopies(), zcopies(), line_copies(), grid_copies() 
//
// Usage:
//   xflip_copy([offset], [x]) CHILDREN;
// Usage: As a function to translate points, VNF, or Bezier patches
//   copies = xflip_copy([offset], [x], p=);
// Usage: Get Translation Matrices
//   mats = xflip_copy([offset], [x]);
//
// Description:
//   When called as a module, makes a copy of the children, mirrored across the X axis.
//   When called as a function, *without* a `p=` argument, returns a list of transformation matrices, one for each copy.
//   When called as a function, *with* a `p=` argument, returns a list of transformed copies of `p=`.
//
// Arguments:
//   offset = Distance to offset children right, before copying.
//   x = The X coordinate of the mirroring plane.  Default: 0
//   ---
//   p = Either a point, pointlist, VNF or Bezier patch to be translated when used as a function.
//
// Side Effects:
//   `$orig` is true for the original instance of children.  False for the copy.
//   `$idx` is set to the index value of each copy.
//
//
// Example:
//   xflip_copy() yrot(90) cylinder(h=20, r1=4, r2=0);
//   color("blue",0.25) cube([0.01,15,15], center=true);
//
// Example:
//   xflip_copy(offset=5) yrot(90) cylinder(h=20, r1=4, r2=0);
//   color("blue",0.25) cube([0.01,15,15], center=true);
//
// Example:
//   xflip_copy(x=-5) yrot(90) cylinder(h=20, r1=4, r2=0);
//   color("blue",0.25) left(5) cube([0.01,15,15], center=true);
module xflip_copy(offset=0, x=0)
{
    req_children($children);  
    mirror_copy(v=[1,0,0], offset=offset, cp=[x,0,0]) children();
}


function xflip_copy(offset=0, x=0, p=_NO_ARG) =
    mirror_copy(v=[1,0,0], offset=offset, cp=[x,0,0], p=p);


// Function&Module: yflip_copy()
// Synopsis: Makes a copy of children mirrored across the Y axis.
// SynTags: MatList, Trans
// Topics: Transformations, Distributors, Translation, Copiers
// See Also: xflip_copy(), zflip_copy(), mirror_copy(), path_copies(), move_copies(), xcopies(), ycopies(), zcopies(), line_copies(), grid_copies() 
//
// Usage:
//   yflip_copy([offset], [y]) CHILDREN;
// Usage: As a function to translate points, VNF, or Bezier patches
//   copies = yflip_copy([offset], [y], p=);
// Usage: Get Translation Matrices
//   mats = yflip_copy([offset], [y]);
//
// Description:
//   When called as a module, makes a copy of the children, mirrored across the Y axis.
//   When called as a function, *without* a `p=` argument, returns a list of transformation matrices, one for each copy.
//   When called as a function, *with* a `p=` argument, returns a list of transformed copies of `p=`.
//
// Arguments:
//   offset = Distance to offset children back, before copying.
//   y = The Y coordinate of the mirroring plane.  Default: 0
//   ---
//   p = Either a point, pointlist, VNF or Bezier patch to be translated when used as a function.
//
// Side Effects:
//   `$orig` is true for the original instance of children.  False for the copy.
//   `$idx` is set to the index value of each copy.
//
//
// Example:
//   yflip_copy() xrot(-90) cylinder(h=20, r1=4, r2=0);
//   color("blue",0.25) cube([15,0.01,15], center=true);
//
// Example:
//   yflip_copy(offset=5) xrot(-90) cylinder(h=20, r1=4, r2=0);
//   color("blue",0.25) cube([15,0.01,15], center=true);
//
// Example:
//   yflip_copy(y=-5) xrot(-90) cylinder(h=20, r1=4, r2=0);
//   color("blue",0.25) fwd(5) cube([15,0.01,15], center=true);
module yflip_copy(offset=0, y=0)
{
    req_children($children);
    mirror_copy(v=[0,1,0], offset=offset, cp=[0,y,0]) children();
}


function yflip_copy(offset=0, y=0, p=_NO_ARG) =
    mirror_copy(v=[0,1,0], offset=offset, cp=[0,y,0], p=p);


// Function&Module: zflip_copy()
// Synopsis: Makes a copy of children mirrored across the Z axis.
// SynTags: MatList, Trans
// Topics: Transformations, Distributors, Translation, Copiers
// See Also: xflip_copy(), yflip_copy(), mirror_copy(), path_copies(), move_copies(), xcopies(), ycopies(), zcopies(), line_copies(), grid_copies() 
//
// Usage:
//   zflip_copy([offset], [z]) CHILDREN;
// Usage: As a function to translate points, VNF, or Bezier patches
//   copies = zflip_copy([offset], [z], p=);
// Usage: Get Translation Matrices
//   mats = zflip_copy([offset], [z]);
//
// Description:
//   When called as a module, makes a copy of the children, mirrored across the Z axis.
//   When called as a function, *without* a `p=` argument, returns a list of transformation matrices, one for each copy.
//   When called as a function, *with* a `p=` argument, returns a list of transformed copies of `p=`.
//
// Arguments:
//   offset = Distance to offset children up, before copying.
//   z = The Z coordinate of the mirroring plane.  Default: 0
//   ---
//   p = Either a point, pointlist, VNF or Bezier patch to be translated when used as a function.
//
// Side Effects:
//   `$orig` is true for the original instance of children.  False for the copy.
//   `$idx` is set to the index value of each copy.
//
//
// Example:
//   zflip_copy() cylinder(h=20, r1=4, r2=0);
//   color("blue",0.25) cube([15,15,0.01], center=true);
//
// Example:
//   zflip_copy(offset=5) cylinder(h=20, r1=4, r2=0);
//   color("blue",0.25) cube([15,15,0.01], center=true);
//
// Example:
//   zflip_copy(z=-5) cylinder(h=20, r1=4, r2=0);
//   color("blue",0.25) down(5) cube([15,15,0.01], center=true);
module zflip_copy(offset=0, z=0)
{
    req_children($children);  
    mirror_copy(v=[0,0,1], offset=offset, cp=[0,0,z]) children();
}


function zflip_copy(offset=0, z=0, p=_NO_ARG) =
    mirror_copy(v=[0,0,1], offset=offset, cp=[0,0,z], p=p);


// Function&Module: mirror_copy()
// Synopsis: Makes a copy of children mirrored across a given plane.
// SynTags: MatList, Trans
// Topics: Transformations, Distributors, Translation, Copiers
// See Also: xflip_copy(), yflip_copy(), zflip_copy(), path_copies(), move_copies(), xcopies(), ycopies(), zcopies(), line_copies(), grid_copies() 
//
// Usage:
//   mirror_copy(v, [cp], [offset]) CHILDREN;
// Usage: As a function to translate points, VNF, or Bezier patches
//   copies = mirror_copy(v, [cp], [offset], p=);
// Usage: Get Translation Matrices
//   mats = mirror_copy(v, [cp], [offset]);
//
// Description:
//   When called as a module, makes a copy of the children, mirrored across the given plane.
//   When called as a function, *without* a `p=` argument, returns a list of transformation matrices, one for each copy.
//   When called as a function, *with* a `p=` argument, returns a list of transformed copies of `p=`.
//
// Arguments:
//   v = The normal vector of the plane to mirror across.
//   offset = distance to offset away from the plane.
//   cp = A point that lies on the mirroring plane.
//   ---
//   p = Either a point, pointlist, VNF or Bezier patch to be translated when used as a function.
//
// Side Effects:
//   `$orig` is true for the original instance of children.  False for the copy.
//   `$idx` is set to the index value of each copy.
//
//
// Example:
//   mirror_copy([1,-1,0]) zrot(-45) yrot(90) cylinder(d1=10, d2=0, h=20);
//   color("blue",0.25) zrot(-45) cube([0.01,15,15], center=true);
//
// Example:
//   mirror_copy([1,1,0], offset=5) rot(a=90,v=[-1,1,0]) cylinder(d1=10, d2=0, h=20);
//   color("blue",0.25) zrot(45) cube([0.01,15,15], center=true);
//
// Example:
//   mirror_copy(UP+BACK, cp=[0,-5,-5]) rot(from=UP, to=BACK+UP) cylinder(d1=10, d2=0, h=20);
//   color("blue",0.25) translate([0,-5,-5]) rot(from=UP, to=BACK+UP) cube([15,15,0.01], center=true);
module mirror_copy(v=[0,0,1], offset=0, cp)
{
    req_children($children);  
    cp = is_vector(v,4)? plane_normal(v) * v[3] :
        is_vector(cp)? cp :
        is_num(cp)? cp*unit(v) :
        [0,0,0];
    nv = is_vector(v,4)? plane_normal(v) : unit(v);
    off = nv*offset;
    if (cp == [0,0,0]) {
        translate(off) {
            $orig = true;
            $idx = 0;
            children();
        }
        mirror(nv) translate(off) {
            $orig = false;
            $idx = 1;
            children();
        }
    } else {
        translate(off) {
            $orig = true;
            $idx = 0;
            children();
        }
        translate(cp) mirror(nv) translate(-cp) translate(off) {
            $orig = false;
            $idx = 1;
            children();
        }
    }
}


function mirror_copy(v=[0,0,1], offset=0, cp, p=_NO_ARG) =
    let(
        cp = is_vector(v,4)? plane_normal(v) * v[3] :
            is_vector(cp)? cp :
            is_num(cp)? cp*unit(v) :
            [0,0,0],
        nv = is_vector(v,4)? plane_normal(v) : unit(v),
        off = nv*offset,
        mats = [
            translate(off),
            translate(cp) *
                mirror(nv) *
                translate(-cp) *
                translate(off)
        ]
    )
    p==_NO_ARG? mats : [for (m = mats) apply(m, p)];



////////////////////
// Section: Distributing children individually along a line
///////////////////
// Module: xdistribute()
// Synopsis: Distributes each child, individually, out along the X axis.
// SynTags: Trans
// See Also: xdistribute(), ydistribute(), zdistribute(), distribute()
//
// Usage:
//   xdistribute(spacing, [sizes]) CHILDREN;
//   xdistribute(l=, [sizes=]) CHILDREN;
//
//
// Description:
//   Spreads out the children individually along the X axis. 
//   Every child is placed at a different position, in order.
//   This is useful for laying out groups of disparate objects
//   where you only really care about the spacing between them.
//
// Arguments:
//   spacing = spacing between each child. (Default: 10.0)
//   sizes = Array containing how much space each child will need.
//   l = Length to distribute copies along.
//
// Side Effects:
//   `$pos` is set to the relative centerpoint of each child copy, and can be used to modify each child individually.
//   `$idx` is set to the index number of each child being copied.
//
// Example:
//   xdistribute(sizes=[100, 10, 30], spacing=40) {
//       sphere(r=50);
//       cube([10,20,30], center=true);
//       cylinder(d=30, h=50, center=true);
//   }
module xdistribute(spacing=10, sizes=undef, l=undef)
{
    req_children($children);  
    dir = RIGHT;
    gaps = ($children < 2)? [0] :
        !is_undef(sizes)? [for (i=[0:1:$children-2]) sizes[i]/2 + sizes[i+1]/2] :
        [for (i=[0:1:$children-2]) 0];
    spc = !is_undef(l)? ((l - sum(gaps)) / ($children-1)) : default(spacing, 10);
    gaps2 = [for (gap = gaps) gap+spc];
    spos = dir * -sum(gaps2)/2;
    spacings = cumsum([0, each gaps2]);
    for (i=[0:1:$children-1]) {
        $pos = spos + spacings[i] * dir;
        $idx = i;
        translate($pos) children(i);
    }
}


// Module: ydistribute()
// Synopsis: Distributes each child, individually, out along the Y axis.
// SynTags: Trans
// See Also: xdistribute(), ydistribute(), zdistribute(), distribute()
//
// Usage:
//   ydistribute(spacing, [sizes]) CHILDREN;
//   ydistribute(l=, [sizes=]) CHILDREN;
//
// Description:
//   Spreads out the children individually along the Y axis. 
//   Every child is placed at a different position, in order.
//   This is useful for laying out groups of disparate objects
//   where you only really care about the spacing between them.
//
// Arguments:
//   spacing = spacing between each child. (Default: 10.0)
//   sizes = Array containing how much space each child will need.
//   l = Length to distribute copies along.
//
// Side Effects:
//   `$pos` is set to the relative centerpoint of each child copy, and can be used to modify each child individually.
//   `$idx` is set to the index number of each child being copied.
//
// Example:
//   ydistribute(sizes=[30, 20, 100], spacing=40) {
//       cylinder(d=30, h=50, center=true);
//       cube([10,20,30], center=true);
//       sphere(r=50);
//   }
module ydistribute(spacing=10, sizes=undef, l=undef)
{
    req_children($children);  
    dir = BACK;
    gaps = ($children < 2)? [0] :
        !is_undef(sizes)? [for (i=[0:1:$children-2]) sizes[i]/2 + sizes[i+1]/2] :
        [for (i=[0:1:$children-2]) 0];
    spc = !is_undef(l)? ((l - sum(gaps)) / ($children-1)) : default(spacing, 10);
    gaps2 = [for (gap = gaps) gap+spc];
    spos = dir * -sum(gaps2)/2;
    spacings = cumsum([0, each gaps2]);
    for (i=[0:1:$children-1]) {
        $pos = spos + spacings[i] * dir;
        $idx = i;
        translate($pos) children(i);
    }
}


// Module: zdistribute()
// Synopsis: Distributes each child, individually, out along the Z axis.
// SynTags: Trans
// See Also: xdistribute(), ydistribute(), zdistribute(), distribute()
//
// Usage:
//   zdistribute(spacing, [sizes]) CHILDREN;
//   zdistribute(l=, [sizes=]) CHILDREN;
//
// Description:
//   Spreads out each individual child along the Z axis.
//   Every child is placed at a different position, in order.
//   This is useful for laying out groups of disparate objects
//   where you only really care about the spacing between them.
//
// Arguments:
//   spacing = spacing between each child. (Default: 10.0)
//   sizes = Array containing how much space each child will need.
//   l = Length to distribute copies along.
//
// Side Effects:
//   `$pos` is set to the relative centerpoint of each child copy, and can be used to modify each child individually.
//   `$idx` is set to the index number of each child being copied.
//
// Example:
//   zdistribute(sizes=[30, 20, 100], spacing=40) {
//       cylinder(d=30, h=50, center=true);
//       cube([10,20,30], center=true);
//       sphere(r=50);
//   }
module zdistribute(spacing=10, sizes=undef, l=undef)
{
    req_children($children);  
    dir = UP;
    gaps = ($children < 2)? [0] :
        !is_undef(sizes)? [for (i=[0:1:$children-2]) sizes[i]/2 + sizes[i+1]/2] :
        [for (i=[0:1:$children-2]) 0];
    spc = !is_undef(l)? ((l - sum(gaps)) / ($children-1)) : default(spacing, 10);
    gaps2 = [for (gap = gaps) gap+spc];
    spos = dir * -sum(gaps2)/2;
    spacings = cumsum([0, each gaps2]);
    for (i=[0:1:$children-1]) {
        $pos = spos + spacings[i] * dir;
        $idx = i;
        translate($pos) children(i);
    }
}



// Module: distribute()
// Synopsis: Distributes each child, individually, out along an arbitrary line.
// SynTags: Trans
// See Also: xdistribute(), ydistribute(), zdistribute(), distribute()
//
// Usage:
//   distribute(spacing, sizes, dir) CHILDREN;
//   distribute(l=, [sizes=], [dir=]) CHILDREN;
//
// Description:
//   Spreads out the children individually along the direction `dir`.
//   Every child is placed at a different position, in order.
//   This is useful for laying out groups of disparate objects
//   where you only really care about the spacing between them.
//
// Arguments:
//   spacing = Spacing to add between each child. (Default: 10.0)
//   sizes = Array containing how much space each child will need.
//   dir = Vector direction to distribute copies along.  Default: RIGHT
//   l = Length to distribute copies along.
//
// Side Effects:
//   `$pos` is set to the relative centerpoint of each child copy, and can be used to modify each child individually.
//   `$idx` is set to the index number of each child being copied.
//
// Example:
//   distribute(sizes=[100, 30, 50], dir=UP) {
//       sphere(r=50);
//       cube([10,20,30], center=true);
//       cylinder(d=30, h=50, center=true);
//   }
module distribute(spacing=undef, sizes=undef, dir=RIGHT, l=undef)
{
    req_children($children);  
    gaps = ($children < 2)? [0] :
        !is_undef(sizes)? [for (i=[0:1:$children-2]) sizes[i]/2 + sizes[i+1]/2] :
        [for (i=[0:1:$children-2]) 0];
    spc = !is_undef(l)? ((l - sum(gaps)) / ($children-1)) : default(spacing, 10);
    gaps2 = [for (gap = gaps) gap+spc];
    spos = dir * -sum(gaps2)/2;
    spacings = cumsum([0, each gaps2]);
    for (i=[0:1:$children-1]) {
        $pos = spos + spacings[i] * dir;
        $idx = i;
        translate($pos) children(i);
    }
}



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
