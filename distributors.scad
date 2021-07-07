//////////////////////////////////////////////////////////////////////
// LibFile: distributors.scad
//   Functions and modules to distribute children or copies of children.
// Includes:
//   include <BOSL2/std.scad>
//////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////
// Section: Translational Distributors
//////////////////////////////////////////////////////////////////////


// Module: move_copies()
//
// Description:
//   Translates copies of all children to each given translation offset.
//
// Usage:
//   move_copies(a) ...
//
// Arguments:
//   a = Array of XYZ offset vectors. Default `[[0,0,0]]`
//
// Side Effects:
//   `$pos` is set to the relative centerpoint of each child copy, and can be used to modify each child individually.
//   `$idx` is set to the index number of each child being copied.
//
// Example:
//   #sphere(r=10);
//   move_copies([[-25,-25,0], [25,-25,0], [0,0,50], [0,25,0]]) sphere(r=10);
module move_copies(a=[[0,0,0]])
{
    assert(is_list(a));
    for ($idx = idx(a)) {
        $pos = a[$idx];
        assert(is_vector($pos),"move_copies offsets should be a 2d or 3d vector.");
        translate($pos) children();
    }
}


// Function&Module: line_of()
//
// Usage: Spread `n` copies by a given spacing
//   line_of(spacing, [n], [p1=]) ...
// Usage: Spread copies every given spacing along the line
//   line_of(spacing, [l=], [p1=]) ...
// Usage: Spread `n` copies along the length of the line
//   line_of([n=], [l=], [p1=]) ...
// Usage: Spread `n` copies along the line from `p1` to `p2`
//   line_of([n=], [p1=], [p2=]) ...
// Usage: Spread copies every given spacing, centered along the line from `p1` to `p2`
//   line_of([spacing], [p1=], [p2=]) ...
// Usage: As a function
//   pts = line_of([spacing], [n], [p1=]);
//   pts = line_of([spacing], [l=], [p1=]);
//   pts = line_of([n=], [l=], [p1=]);
//   pts = line_of([n=], [p1=], [p2=]);
//   pts = line_of([spacing], [p1=], [p2=]);
// Description:
//   When called as a function, returns a list of points at evenly spread positions along a line.
//   When called as a module, copies `children()` at one or more evenly spread positions along a line.
//   By default, the line will be centered at the origin, unless the starting point `p1` is given.
//   The line will be pointed towards `RIGHT` (X+) unless otherwise given as a vector in `l`,
//   `spacing`, or `p1`/`p2`.  The spread is specified in one of several ways:
//   .
//   If You Know...                   | Then Use Something Like...
//   -------------------------------- | --------------------------------
//   Spacing distance, Count          | `line_of(spacing=10, n=5) ...` or `line_of(10, n=5) ...`
//   Spacing vector, Count            | `line_of(spacing=[10,5], n=5) ...` or `line_of([10,5], n=5) ...`
//   Spacing distance, Line length    | `line_of(spacing=10, l=50) ...` or `line_of(10, l=50) ...`
//   Spacing distance, Line vector    | `line_of(spacing=10, l=[50,30]) ...` or `line_of(10, l=[50,30]) ...`
//   Spacing vector, Line length      | `line_of(spacing=[10,5], l=50) ...` or `line_of([10,5], l=50) ...`
//   Line length, Count               | `line_of(l=50, n=5) ...`
//   Line vector, Count               | `line_of(l=[50,40], n=5) ...`
//   Line endpoints, Count            | `line_of(p1=[10,10], p2=[60,-10], n=5) ...`
//   Line endpoints, Spacing distance | `line_of(p1=[10,10], p2=[60,-10], spacing=10) ...`
//
// Arguments:
//   spacing = Either the scalar spacing distance along the X+ direction, or the vector giving both the direction and spacing distance between each set of copies.
//   n = Number of copies to distribute along the line. (Default: 2)
//   ---
//   l = Either the scalar length of the line, or a vector giving both the direction and length of the line.
//   p1 = If given, specifies the starting point of the line.
//   p2 = If given with `p1`, specifies the ending point of line, and indirectly calculates the line length.
//
// Side Effects:
//   `$pos` is set to the relative centerpoint of each child copy, and can be used to modify each child individually.
//   `$idx` is set to the index number of each child being copied.
//
// Examples:
//   line_of(10) sphere(d=1);
//   line_of(10, n=5) sphere(d=1);
//   line_of([10,5], n=5) sphere(d=1);
//   line_of(spacing=10, n=6) sphere(d=1);
//   line_of(spacing=[10,5], n=6) sphere(d=1);
//   line_of(spacing=10, l=50) sphere(d=1);
//   line_of(spacing=10, l=[50,30]) sphere(d=1);
//   line_of(spacing=[10,5], l=50) sphere(d=1);
//   line_of(l=50, n=4) sphere(d=1);
//   line_of(l=[50,-30], n=4) sphere(d=1);
// Example(FlatSpin,VPD=133):
//   line_of(p1=[0,0,0], p2=[5,5,20], n=6) cube(size=[3,2,1],center=true);
// Example(FlatSpin,VPD=133):
//   line_of(p1=[0,0,0], p2=[5,5,20], spacing=6) cube(size=[3,2,1],center=true);
// Example: All Children are Copied at Each Spread Position
//   line_of(l=20, n=3) {
//       cube(size=[1,3,1],center=true);
//       cube(size=[3,1,1],center=true);
//   }
// Example(2D):
//   pts = line_of([10,5],n=5);
//   move_copies(pts) circle(d=2);
module line_of(spacing, n, l, p1, p2)
{
    pts = line_of(spacing=spacing, n=n, l=l, p1=p1, p2=p2);
    for (i=idx(pts)) {
        $idx = i;
        $pos = pts[i];
        translate($pos) children();
    }
}

function line_of(spacing, n, l, p1, p2) =
    assert(is_undef(spacing) || is_finite(spacing) || is_vector(spacing))
    assert(is_undef(n) || is_finite(n))
    assert(is_undef(l) || is_finite(l) || is_vector(l))
    assert(is_undef(p1) || is_vector(p1))
    assert(is_undef(p2) || is_vector(p2))
    let(
        ll = !is_undef(l)? scalar_vec3(l, 0) :
            (!is_undef(spacing) && !is_undef(n))? ((n-1) * scalar_vec3(spacing, 0)) :
            (!is_undef(p1) && !is_undef(p2))? point3d(p2-p1) :
            undef,
        cnt = !is_undef(n)? n :
            (!is_undef(spacing) && !is_undef(ll))? floor(norm(ll) / norm(scalar_vec3(spacing, 0)) + 1.000001) :
            2,
        spc = cnt<=1? [0,0,0] :
            is_undef(spacing)? (ll/(cnt-1)) :
            is_num(spacing) && !is_undef(ll)? (ll/(cnt-1)) :
            scalar_vec3(spacing, 0)
    )
    assert(!is_undef(cnt), "Need two of `spacing`, 'l', 'n', or `p1`/`p2` arguments in `line_of()`.")
    let( spos = !is_undef(p1)? point3d(p1) : -(cnt-1)/2 * spc )
    [for (i=[0:1:cnt-1]) i * spc + spos];


// Module: xcopies()
//
// Description:
//   Spreads out `n` copies of the children along a line on the X axis.
//
// Usage:
//   xcopies(spacing, [n], [sp]) ...
//   xcopies(l, [n], [sp]) ...
//
// Arguments:
//   spacing = spacing between copies. (Default: 1.0)
//   n = Number of copies to spread out. (Default: 2)
//   l = Length to spread copies over.
//   sp = If given as a point, copies will be spread on a line to the right of starting position `sp`.  If given as a scalar, copies will be spread on a line to the right of starting position `[sp,0,0]`.  If not given, copies will be spread along a line that is centered at [0,0,0].
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
module xcopies(spacing, n, l, sp)
{
    sp = is_finite(sp)? [sp,0,0] : sp;
    line_of(
        l=u_mul(l,RIGHT),
        spacing=u_mul(spacing,RIGHT),
        n=n, p1=sp
    ) children();
}


// Module: ycopies()
//
// Description:
//   Spreads out `n` copies of the children along a line on the Y axis.
//
// Usage:
//   ycopies(spacing, [n], [sp]) ...
//   ycopies(l, [n], [sp]) ...
//
// Arguments:
//   spacing = spacing between copies. (Default: 1.0)
//   n = Number of copies to spread out. (Default: 2)
//   l = Length to spread copies over.
//   sp = If given as a point, copies will be spread on a line back from starting position `sp`.  If given as a scalar, copies will be spread on a line back from starting position `[0,sp,0]`.  If not given, copies will be spread along a line that is centered at [0,0,0].
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
module ycopies(spacing, n, l, sp)
{
    sp = is_finite(sp)? [0,sp,0] : sp;
    line_of(
        l=u_mul(l,BACK),
        spacing=u_mul(spacing,BACK),
        n=n, p1=sp
    ) children();
}


// Module: zcopies()
//
// Description:
//   Spreads out `n` copies of the children along a line on the Z axis.
//
// Usage:
//   zcopies(spacing, [n], [sp]) ...
//   zcopies(l, [n], [sp]) ...
//
// Arguments:
//   spacing = spacing between copies. (Default: 1.0)
//   n = Number of copies to spread out. (Default: 2)
//   l = Length to spread copies over.
//   sp = If given as a point, copies will be spread on a line up from starting position `sp`.  If given as a scalar, copies will be spread on a line up from starting position `[0,0,sp]`.  If not given, copies will be spread along a line that is centered at [0,0,0].
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
module zcopies(spacing, n, l, sp)
{
    sp = is_finite(sp)? [0,0,sp] : sp;
    line_of(
        l=u_mul(l,UP),
        spacing=u_mul(spacing,UP),
        n=n, p1=sp
    ) children();
}



// Module: distribute()
//
// Description:
//   Spreads out each individual child along the direction `dir`.
//   Every child is placed at a different position, in order.
//   This is useful for laying out groups of disparate objects
//   where you only really care about the spacing between them.
//
// Usage:
//   distribute(spacing, dir, [sizes]) ...
//   distribute(l, dir, [sizes]) ...
//
// Arguments:
//   spacing = Spacing to add between each child. (Default: 10.0)
//   sizes = Array containing how much space each child will need.
//   dir = Vector direction to distribute copies along.
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


// Module: xdistribute()
//
// Description:
//   Spreads out each individual child along the X axis.
//   Every child is placed at a different position, in order.
//   This is useful for laying out groups of disparate objects
//   where you only really care about the spacing between them.
//
// Usage:
//   xdistribute(spacing, [sizes]) ...
//   xdistribute(l, [sizes]) ...
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
//
// Description:
//   Spreads out each individual child along the Y axis.
//   Every child is placed at a different position, in order.
//   This is useful for laying out groups of disparate objects
//   where you only really care about the spacing between them.
//
// Usage:
//   ydistribute(spacing, [sizes])
//   ydistribute(l, [sizes])
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
//
// Description:
//   Spreads out each individual child along the Z axis.
//   Every child is placed at a different position, in order.
//   This is useful for laying out groups of disparate objects
//   where you only really care about the spacing between them.
//
// Usage:
//   zdistribute(spacing, [sizes])
//   zdistribute(l, [sizes])
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



// Module: grid2d()
//
// Description:
//   Makes a square or hexagonal grid of copies of children.
//
// Usage:
//   grid2d(spacing, size, [stagger], [scale], [inside]) ...
//   grid2d(n, size, [stagger], [scale], [inside]) ...
//   grid2d(spacing, n, [stagger], [scale], [inside]) ...
//   grid2d(spacing, inside, [stagger], [scale]) ...
//   grid2d(n, inside, [stagger], [scale]) ...
//
// Arguments:
//   size = The [X,Y] size to spread the copies over.
//   spacing = Distance between copies in [X,Y] or scalar distance.
//   n = How many columns and rows of copies to make.  Can be given as `[COLS,ROWS]`, or just as a scalar that specifies both.  If staggered, count both staggered and unstaggered columns and rows.  Default: 2 (3 if staggered)
//   stagger = If true, make a staggered (hexagonal) grid.  If false, make square grid.  If `"alt"`, makes alternate staggered pattern.  Default: false
//   inside = If given a list of polygon points, or a region, only creates copies whose center would be inside the polygon or region.  Polygon can be concave and/or self crossing.
//
// Side Effects:
//   `$pos` is set to the relative centerpoint of each child copy, and can be used to modify each child individually.
//   `$col` is set to the integer column number for each child.
//   `$row` is set to the integer row number for each child.
//
// Examples:
//   grid2d(size=50, spacing=10) cylinder(d=10, h=1);
//   grid2d(size=50, spacing=[10,15]) cylinder(d=10, h=1);
//   grid2d(spacing=10, n=[13,7], stagger=true) cylinder(d=6, h=5);
//   grid2d(spacing=10, n=[13,7], stagger="alt") cylinder(d=6, h=5);
//   grid2d(size=50, n=11, stagger=true) cylinder(d=5, h=1);
//
// Example:
//   poly = [[-25,-25], [25,25], [-25,25], [25,-25]];
//   grid2d(spacing=5, stagger=true, inside=poly)
//      zrot(180/6) cylinder(d=5, h=1, $fn=6);
//   %polygon(poly);
//
// Example: Using `$row` and `$col`
//   grid2d(spacing=8, n=8)
//       color(($row+$col)%2?"black":"red")
//           cube([8,8,0.01], center=false);
//
// Example:
//   // Makes a grid of hexagon pillars whose tops are all
//   // angled to reflect light at [0,0,50], if they were shiny.
//   hexregion = circle(r=50.01,$fn=6);
//   grid2d(spacing=10, stagger=true, inside=hexregion) union() {
//       // Note: The union() is needed or else $pos will be
//       //   inexplicably unreadable.
//       ref_v = (unit([0,0,50]-point3d($pos)) + UP)/2;
//       half_of(v=-ref_v, cp=[0,0,5])
//           zrot(180/6)
//               cylinder(h=20, d=10/cos(180/6)+0.01, $fn=6);
//   }
module grid2d(spacing, n, size, stagger=false, inside=undef)
{
    assert(in_list(stagger, [false, true, "alt"]));
    bounds = is_undef(inside)? undef :
        is_path(inside)? pointlist_bounds(inside) :
        assert(is_region(inside))
        pointlist_bounds(flatten(inside));
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
    offset = v_mul(spacing, n-[1,1])/2;
    if (stagger == false) {
        for (row = [0:1:n.y-1]) {
            for (col = [0:1:n.x-1]) {
                pos = v_mul([col,row],spacing) - offset;
                if (
                    is_undef(inside) ||
                    (is_path(inside) && point_in_polygon(pos, inside)>=0) ||
                    (is_region(inside) && point_in_region(pos, inside)>=0)
                ) {
                    $col = col;
                    $row = row;
                    $pos = pos;
                    translate(pos) children();
                }
            }
        }
    } else {
        // stagger == true or stagger == "alt"
        staggermod = (stagger == "alt")? 1 : 0;
        cols1 = ceil(n.x/2);
        cols2 = n.x - cols1;
        for (row = [0:1:n.y-1]) {
            rowcols = ((row%2) == staggermod)? cols1 : cols2;
            if (rowcols > 0) {
                for (col = [0:1:rowcols-1]) {
                    rowdx = (row%2 != staggermod)? spacing.x : 0;
                    pos = v_mul([2*col,row],spacing) + [rowdx,0] - offset;
                    if (
                        is_undef(inside) ||
                        (is_path(inside) && point_in_polygon(pos, inside)>=0) ||
                        (is_region(inside) && point_in_region(pos, inside)>=0)
                    ) {
                        $col = col * 2 + ((row%2!=staggermod)? 1 : 0);
                        $row = row;
                        $pos = pos;
                        translate(pos) children();
                    }
                }
            }
        }
    }
}



// Module: grid3d()
//
// Description:
//   Makes a 3D grid of duplicate children.
//
// Usage:
//   grid3d(n, spacing) ...
//   grid3d(n=[Xn,Yn,Zn], spacing=[dX,dY,dZ]) ...
//   grid3d([xa], [ya], [za]) ...
//
// Arguments:
//   xa = array or range of X-axis values to offset by. (Default: [0])
//   ya = array or range of Y-axis values to offset by. (Default: [0])
//   za = array or range of Z-axis values to offset by. (Default: [0])
//   n = Optional number of copies to have per axis.
//   spacing = spacing of copies per axis. Use with `n`.
//
// Side Effects:
//   `$pos` is set to the relative centerpoint of each child copy, and can be used to modify each child individually.
//   `$idx` is set to the [Xidx,Yidx,Zidx] index values of each child copy, when using `count` and `n`.
//
// Examples(FlatSpin,VPD=222):
//   grid3d(xa=[0:25:50],ya=[0,40],za=[-20:40:20]) sphere(r=5);
// Examples(FlatSpin,VPD=800):
//   grid3d(n=[3, 4, 2], spacing=[60, 50, 40]) sphere(r=10);
// Examples:
//   grid3d(ya=[-60:40:60],za=[0,70]) sphere(r=10);
//   grid3d(n=3, spacing=30) sphere(r=10);
//   grid3d(n=[3, 1, 2], spacing=30) sphere(r=10);
//   grid3d(n=[3, 4], spacing=[80, 60]) sphere(r=10);
// Examples:
//   grid3d(n=[10, 10, 10], spacing=50) color($idx/9) cube(50, center=true);
module grid3d(xa=[0], ya=[0], za=[0], n=undef, spacing=undef)
{
    n = scalar_vec3(n, 1);
    spacing = scalar_vec3(spacing, undef);
    if (!is_undef(n) && !is_undef(spacing)) {
        for (xi = [0:1:n.x-1]) {
            for (yi = [0:1:n.y-1]) {
                for (zi = [0:1:n.z-1]) {
                    $idx = [xi,yi,zi];
                    $pos = v_mul(spacing, $idx - (n-[1,1,1])/2);
                    translate($pos) children();
                }
            }
        }
    } else {
        for (xoff = xa, yoff = ya, zoff = za) {
            $pos = [xoff, yoff, zoff];
            translate($pos) children();
        }
    }
}



//////////////////////////////////////////////////////////////////////
// Section: Rotational Distributors
//////////////////////////////////////////////////////////////////////


// Module: rot_copies()
//
// Description:
//   Given a list of [X,Y,Z] rotation angles in `rots`, rotates copies of the children to each of those angles, regardless of axis of rotation.
//   Given a list of scalar angles in `rots`, rotates copies of the children to each of those angles around the axis of rotation.
//   If given a vector `v`, that becomes the axis of rotation.  Default axis of rotation is UP.
//   If given a count `n`, makes that many copies, rotated evenly around the axis.
//   If given an offset `delta`, translates each child by that amount before rotating them into place.  This makes rings.
//   If given a centerpoint `cp`, centers the ring around that centerpoint.
//   If `subrot` is true, each child will be rotated in place to keep the same size towards the center.
//   The first (unrotated) copy will be placed at the relative starting angle `sa`.
//
// Usage:
//   rot_copies(rots, [cp], [sa], [delta], [subrot]) ...
//   rot_copies(rots, v, [cp], [sa], [delta], [subrot]) ...
//   rot_copies(n, [v], [cp], [sa], [delta], [subrot]) ...
//
// Arguments:
//   rots = A list of [X,Y,Z] rotation angles in degrees.  If `v` is given, this will be a list of scalar angles in degrees to rotate around `v`.
//   v = If given, this is the vector of the axis to rotate around.
//   cp = Centerpoint to rotate around.  Default: `[0,0,0]`
//   n = Optional number of evenly distributed copies, rotated around the axis.
//   sa = Starting angle, in degrees.  For use with `n`.  Angle is in degrees counter-clockwise.  Default: 0
//   delta = [X,Y,Z] amount to move away from cp before rotating.  Makes rings of copies.  Default: `[0,0,0]`
//   subrot = If false, don't sub-rotate children as they are copied around the ring.  Only makes sense when used with `delta`.  Default: `true`
//
// Side Effects:
//   `$ang` is set to the rotation angle (or XYZ rotation triplet) of each child copy, and can be used to modify each child individually.
//   `$idx` is set to the index value of each child copy.
//   `$axis` is set to the axis to rotate around, if `rots` was given as a list of angles instead of a list of [X,Y,Z] rotation angles.
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
module rot_copies(rots=[], v=undef, cp=[0,0,0], n=undef, sa=0, offset=0, delta=[0,0,0], subrot=true)
{
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
                    rot(a=(subrot? sang : $ang), v=v, reverse=true) {
                        translate(-cp) {
                            children();
                        }
                    }
                }
            }
        }
    }
}


// Module: xrot_copies()
//
// Usage:
//   xrot_copies(rots, [r], [cp], [sa], [subrot]) ...
//   xrot_copies(n, [r], [cp], [sa], [subrot]) ...
//
// Description:
//   Given an array of angles, rotates copies of the children to each of those angles around the X axis.
//   If given a count `n`, makes that many copies, rotated evenly around the X axis.
//   If given an offset radius `r`, distributes children around a ring of that radius.
//   If given a centerpoint `cp`, centers the ring around that centerpoint.
//   If `subrot` is true, each child will be rotated in place to keep the same size towards the center.
//   The first (unrotated) copy will be placed at the relative starting angle `sa`.
//
// Arguments:
//   rots = Optional array of rotation angles, in degrees, to make copies at.
//   cp = Centerpoint to rotate around.
//   n = Optional number of evenly distributed copies to be rotated around the ring.
//   sa = Starting angle, in degrees.  For use with `n`.  Angle is in degrees counter-clockwise from Y+, when facing the origin from X+.  First unrotated copy is placed at that angle.
//   r = Radius to move children back (Y+), away from cp, before rotating.  Makes rings of copies.
//   subrot = If false, don't sub-rotate children as they are copied around the ring.
//
// Side Effects:
//   `$idx` is set to the index value of each child copy.
//   `$ang` is set to the rotation angle of each child copy, and can be used to modify each child individually.
//   `$axis` is set to the axis vector rotated around.
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
module xrot_copies(rots=[], cp=[0,0,0], n=undef, sa=0, r=0, subrot=true)
{
    rot_copies(rots=rots, v=RIGHT, cp=cp, n=n, sa=sa, delta=[0, r, 0], subrot=subrot) children();
}


// Module: yrot_copies()
//
// Usage:
//   yrot_copies(rots, [r], [cp], [sa], [subrot]) ...
//   yrot_copies(n, [r], [cp], [sa], [subrot]) ...
//
// Description:
//   Given an array of angles, rotates copies of the children to each of those angles around the Y axis.
//   If given a count `n`, makes that many copies, rotated evenly around the Y axis.
//   If given an offset radius `r`, distributes children around a ring of that radius.
//   If given a centerpoint `cp`, centers the ring around that centerpoint.
//   If `subrot` is true, each child will be rotated in place to keep the same size towards the center.
//   The first (unrotated) copy will be placed at the relative starting angle `sa`.
//
// Arguments:
//   rots = Optional array of rotation angles, in degrees, to make copies at.
//   cp = Centerpoint to rotate around.
//   n = Optional number of evenly distributed copies to be rotated around the ring.
//   sa = Starting angle, in degrees.  For use with `n`.  Angle is in degrees counter-clockwise from X-, when facing the origin from Y+.
//   r = Radius to move children left (X-), away from cp, before rotating.  Makes rings of copies.
//   subrot = If false, don't sub-rotate children as they are copied around the ring.
//
// Side Effects:
//   `$idx` is set to the index value of each child copy.
//   `$ang` is set to the rotation angle of each child copy, and can be used to modify each child individually.
//   `$axis` is set to the axis vector rotated around.
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
module yrot_copies(rots=[], cp=[0,0,0], n=undef, sa=0, r=0, subrot=true)
{
    rot_copies(rots=rots, v=BACK, cp=cp, n=n, sa=sa, delta=[-r, 0, 0], subrot=subrot) children();
}


// Module: zrot_copies()
//
// Usage:
//   zrot_copies(rots, [r], [cp], [sa], [subrot]) ...
//   zrot_copies(n, [r], [cp], [sa], [subrot]) ...
//
// Description:
//   Given an array of angles, rotates copies of the children to each of those angles around the Z axis.
//   If given a count `n`, makes that many copies, rotated evenly around the Z axis.
//   If given an offset radius `r`, distributes children around a ring of that radius.
//   If given a centerpoint `cp`, centers the ring around that centerpoint.
//   If `subrot` is true, each child will be rotated in place to keep the same size towards the center.
//   The first (unrotated) copy will be placed at the relative starting angle `sa`.
//
// Arguments:
//   rots = Optional array of rotation angles, in degrees, to make copies at.
//   cp = Centerpoint to rotate around.  Default: [0,0,0]
//   n = Optional number of evenly distributed copies to be rotated around the ring.
//   sa = Starting angle, in degrees.  For use with `n`.  Angle is in degrees counter-clockwise from X+, when facing the origin from Z+.  Default: 0
//   r = Radius to move children right (X+), away from cp, before rotating.  Makes rings of copies.  Default: 0
//   subrot = If false, don't sub-rotate children as they are copied around the ring.  Default: true
//
// Side Effects:
//   `$idx` is set to the index value of each child copy.
//   `$ang` is set to the rotation angle of each child copy, and can be used to modify each child individually.
//   `$axis` is set to the axis vector rotated around.
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
module zrot_copies(rots=[], cp=[0,0,0], n=undef, sa=0, r=0, subrot=true)
{
    rot_copies(rots=rots, v=UP, cp=cp, n=n, sa=sa, delta=[r, 0, 0], subrot=subrot) children();
}


// Module: arc_of()
//
// Description:
//   Evenly distributes n duplicate children around an ovoid arc on the XY plane.
//
// Usage:
//   arc_of(r|d, n, [sa], [ea], [rot]
//   arc_of(rx|dx, ry|dy, n, [sa], [ea], [rot]
//
// Arguments:
//   n = number of copies to distribute around the circle. (Default: 6)
//   r = radius of circle (Default: 1)
//   rx = radius of ellipse on X axis. Used instead of r.
//   ry = radius of ellipse on Y axis. Used instead of r.
//   d = diameter of circle. (Default: 2)
//   dx = diameter of ellipse on X axis. Used instead of d.
//   dy = diameter of ellipse on Y axis. Used instead of d.
//   rot = whether to rotate the copied children.  (Default: false)
//   sa = starting angle. (Default: 0.0)
//   ea = ending angle. Will distribute copies CCW from sa to ea. (Default: 360.0)
//
// Side Effects:
//   `$ang` is set to the rotation angle of each child copy, and can be used to modify each child individually.
//   `$pos` is set to the relative centerpoint of each child copy, and can be used to modify each child individually.
//   `$idx` is set to the index value of each child copy.
//
// Example:
//   #cube(size=[10,3,3],center=true);
//   arc_of(d=40, n=5) cube(size=[10,3,3],center=true);
//
// Example:
//   #cube(size=[10,3,3],center=true);
//   arc_of(d=40, n=5, sa=45, ea=225) cube(size=[10,3,3],center=true);
//
// Example:
//   #cube(size=[10,3,3],center=true);
//   arc_of(r=15, n=8, rot=false) cube(size=[10,3,3],center=true);
//
// Example:
//   #cube(size=[10,3,3],center=true);
//   arc_of(rx=20, ry=10, n=8) cube(size=[10,3,3],center=true);
module arc_of(
    n=6,
    r=undef, rx=undef, ry=undef,
    d=undef, dx=undef, dy=undef,
    sa=0, ea=360,
    rot=true
) {
    rx = get_radius(r1=rx, r=r, d1=dx, d=d, dflt=1);
    ry = get_radius(r1=ry, r=r, d1=dy, d=d, dflt=1);
    sa = posmod(sa, 360);
    ea = posmod(ea, 360);
    n = (abs(ea-sa)<0.01)?(n+1):n;
    delt = (((ea<=sa)?360.0:0)+ea-sa)/(n-1);
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



// Module: ovoid_spread()
//
// Description:
//   Spreads children semi-evenly over the surface of a sphere.
//
// Usage:
//   ovoid_spread(r|d, n, [cone_ang], [scale], [perp]) ...
//
// Arguments:
//   r = Radius of the sphere to distribute over
//   d = Diameter of the sphere to distribute over
//   n = How many copies to evenly spread over the surface.
//   cone_ang = Angle of the cone, in degrees, to limit how much of the sphere gets covered.  For full sphere coverage, use 180.  Measured pre-scaling.  Default: 180
//   scale = The [X,Y,Z] scaling factors to reshape the sphere being covered.
//   perp = If true, rotate children to be perpendicular to the sphere surface.  Default: true
//
// Side Effects:
//   `$pos` is set to the relative post-scaled centerpoint of each child copy, and can be used to modify each child individually.
//   `$theta` is set to the theta angle of the child from the center of the sphere.
//   `$phi` is set to the pre-scaled phi angle of the child from the center of the sphere.
//   `$rad` is set to the pre-scaled radial distance of the child from the center of the sphere.
//   `$idx` is set to the index number of each child being copied.
//
// Example:
//   ovoid_spread(n=250, d=100, cone_ang=45, scale=[3,3,1])
//       cylinder(d=10, h=10, center=false);
//
// Example:
//   ovoid_spread(n=500, d=100, cone_ang=180)
//       color(unit(point3d(v_abs($pos))))
//           cylinder(d=8, h=10, center=false);
module ovoid_spread(r=undef, d=undef, n=100, cone_ang=90, scale=[1,1,1], perp=true)
{
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



//////////////////////////////////////////////////////////////////////
// Section: Reflectional Distributors
//////////////////////////////////////////////////////////////////////


// Module: mirror_copy()
//
// Description:
//   Makes a copy of the children, mirrored across the given plane.
//
// Usage:
//   mirror_copy(v, [cp], [offset]) ...
//
// Arguments:
//   v = The normal vector of the plane to mirror across.
//   offset = distance to offset away from the plane.
//   cp = A point that lies on the mirroring plane.
//
// Side Effects:
//   `$orig` is true for the original instance of children.  False for the copy.
//   `$idx` is set to the index value of each copy.
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
        translate(off) children();
        translate(cp) mirror(nv) translate(-cp) translate(off) children();
    }
}


// Module: xflip_copy()
//
// Description:
//   Makes a copy of the children, mirrored across the X axis.
//
// Usage:
//   xflip_copy([x], [offset]) ...
//
// Arguments:
//   offset = Distance to offset children right, before copying.
//   x = The X coordinate of the mirroring plane.  Default: 0
//
// Side Effects:
//   `$orig` is true for the original instance of children.  False for the copy.
//   `$idx` is set to the index value of each copy.
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
    mirror_copy(v=[1,0,0], offset=offset, cp=[x,0,0]) children();
}


// Module: yflip_copy()
//
// Description:
//   Makes a copy of the children, mirrored across the Y axis.
//
// Usage:
//   yflip_copy([y], [offset]) ...
//
// Arguments:
//   offset = Distance to offset children back, before copying.
//   y = The Y coordinate of the mirroring plane.  Default: 0
//
// Side Effects:
//   `$orig` is true for the original instance of children.  False for the copy.
//   `$idx` is set to the index value of each copy.
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
    mirror_copy(v=[0,1,0], offset=offset, cp=[0,y,0]) children();
}


// Module: zflip_copy()
//
// Description:
//   Makes a copy of the children, mirrored across the Z axis.
//
// Usage:
//   zflip_copy([z], [offset]) ...
//
// Arguments:
//   offset = Distance to offset children up, before copying.
//   z = The Z coordinate of the mirroring plane.  Default: 0
//
// Side Effects:
//   `$orig` is true for the original instance of children.  False for the copy.
//   `$idx` is set to the index value of each copy.
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
    mirror_copy(v=[0,0,1], offset=offset, cp=[0,0,z]) children();
}



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
