//////////////////////////////////////////////////////////////////////
// LibFile: vectors.scad
//   This file provides some mathematical operations that apply to each
//   entry in a vector.  It provides normalization and angle computation, and
//   it provides functions for searching lists of vectors for matches to
//   a given vector.  
// Includes:
//   include <BOSL2/std.scad>
// FileGroup: Math
// FileSummary: Vector arithmetic, angle, and searching.
// FileFootnotes: STD=Included in std.scad
//////////////////////////////////////////////////////////////////////


// Section: Vector Testing


// Function: is_vector()
// Synopsis: Returns true if the given value is a vector.
// Topics: Vectors, Math
// See Also: is_matrix(), is_path(), is_region()
// Usage:
//   bool = is_vector(v, [length], [zero=], [all_nonzero=], [eps=]);
// Description:
//   Returns true if v is a list of finite numbers.
// Arguments:
//   v = The value to test to see if it is a vector.
//   length = If given, make sure the vector is `length` items long.
//   ---
//   zero = If false, require that the `norm()` of the vector is not approximately zero.  If true, require the `norm()` of the vector to be approximately zero.  Default: `undef` (don't check vector `norm()`.)
//   all_nonzero = If true, requires all elements of the vector to be more than `eps` different from zero.  Default: `false`
//   eps = The minimum vector length that is considered non-zero.  Default: `EPSILON` (`1e-9`)
// Example:
//   is_vector(4);                          // Returns false
//   is_vector([4,true,false]);             // Returns false
//   is_vector([3,4,INF,5]);                // Returns false
//   is_vector([3,4,5,6]);                  // Returns true
//   is_vector([3,4,undef,5]);              // Returns false
//   is_vector([3,4,5],3);                  // Returns true
//   is_vector([3,4,5],4);                  // Returns true
//   is_vector([]);                         // Returns false
//   is_vector([0,4,0],3,zero=false);       // Returns true
//   is_vector([0,0,0],zero=false);         // Returns false
//   is_vector([0,0,1e-12],zero=false);     // Returns false
//   is_vector([0,1,0],all_nonzero=false);  // Returns false
//   is_vector([1,1,1],all_nonzero=false);  // Returns true
//   is_vector([],zero=false);              // Returns false
function is_vector(v, length, zero, all_nonzero=false, eps=EPSILON) =
    is_list(v) && len(v)>0 && []==[for(vi=v) if(!is_finite(vi)) 0] 
    && (is_undef(length) || (assert(is_num(length))len(v)==length))
    && (is_undef(zero) || ((norm(v) >= eps) == !zero))
    && (!all_nonzero || all_nonzero(v)) ;



// Section: Scalar operations on vectors

// Function: add_scalar()
// Synopsis: Adds a scalar value to every item in a vector.
// Topics: Vectors, Math
// See Also: v_mul(), v_div()
// Usage:  
//   v_new = add_scalar(v, s);
// Description:
//   Given a vector and a scalar, returns the vector with the scalar added to each item in it.
// Arguments:
//   v = The initial array.
//   s = A scalar value to add to every item in the array.
// Example:
//   a = add_scalar([1,2,3],3);            // Returns: [4,5,6]
function add_scalar(v,s) =
    assert(is_vector(v), "\nInput v must be a vector.")
    assert(is_finite(s), "\nInput s must be a finite scalar.")
    [for(entry=v) entry+s];


// Function: v_mul()
// Synopsis: Returns the element-wise multiplication of two equal-length vectors.
// Topics: Vectors, Math
// See Also: add_scalar(), v_div()
// Usage:
//   v3 = v_mul(v1, v2);
// Description:
//   Element-wise multiplication.  Multiplies each element of `v1` by the corresponding element of `v2`.
//   Both `v1` and `v2` must be the same length.  Returns a vector of the products. 
//   The items in `v1` and `v2` can be anything that OpenSCAD can multiply together.  
// Arguments:
//   v1 = The first vector.
//   v2 = The second vector.
// Example:
//   v_mul([3,4,5], [8,7,6]);  // Returns [24, 28, 30]
function v_mul(v1, v2) = 
    assert( is_list(v1) && is_list(v2) && len(v1)==len(v2), "\nIncompatible input.")
    [for (i = [0:1:len(v1)-1]) v1[i]*v2[i]];
    

// Function: v_div()
// Synopsis: Returns the element-wise division of two equal-length vectors.
// Topics: Vectors, Math
// See Also: add_scalar(), v_mul()
// Usage:
//   v3 = v_div(v1, v2);
// Description:
//   Element-wise vector division.  Divides each element of vector `v1` by
//   the corresponding element of vector `v2`.  Returns a vector of the quotients.
// Arguments:
//   v1 = The first vector.
//   v2 = The second vector.
// Example:
//   v_div([24,28,30], [8,7,6]);  // Returns [3, 4, 5]
function v_div(v1, v2) = 
    assert( is_vector(v1) && is_vector(v2,len(v1)), "\nIncompatible vectors.")
    [for (i = [0:1:len(v1)-1]) v1[i]/v2[i]];


// Function: v_abs()
// Synopsis: Returns the absolute values of the given vector.
// Topics: Vectors, Math
// See Also: v_ceil(), v_floor(), v_round()
// Usage:
//   v2 = v_abs(v);
// Description: Returns a vector of the absolute value of each element of vector `v`.
// Arguments:
//   v = The vector to get the absolute values of.
// Example:
//   v_abs([-1,3,-9]);  // Returns: [1,3,9]
function v_abs(v) =
    assert( is_vector(v), "\nInvalid vector." ) 
    [for (x=v) abs(x)];


// Function: v_ceil()
// Synopsis: Returns the values of the given vector, rounded up.
// Topics: Vectors, Math
// See Also: v_abs(), v_floor(), v_round()
// Usage:
//   v2 = v_ceil(v);
// Description:
//   Returns the given vector after performing a `ceil()` on all items.
function v_ceil(v) =
    assert(is_vector(v), "\nInvalid vector." ) 
    [for (x=v) ceil(x)];


// Function: v_floor()
// Synopsis: Returns the values of the given vector, rounded down.
// Topics: Vectors, Math
// See Also: v_abs(), v_ceil(), v_round()
// Usage:
//   v2 = v_floor(v);
// Description:
//   Returns the given vector after performing a `floor()` on all items.
function v_floor(v) =
    assert(is_vector(v), "\nInvalid vector." ) 
    [for (x=v) floor(x)];


// Function: v_round()
// Synopsis: Returns the values of the given vector, rounded to the nearest whole number.
// Topics: Vectors, Math
// See Also: v_abs(), v_floor(), v_ceil()
// Usage:
//   v2 = v_round(v);
// Description:
//   Returns the given vector after performing a `round()` on all items.
function v_round(v) =
    assert(is_vector(v), "\nInvalid vector." ) 
    [for (x=v) round(x)];


// Function: v_lookup()
// Synopsis: Like `lookup()`, but it can interpolate between vector results.
// Topics: Vectors, Math
// See Also: v_abs(), v_floor(), v_ceil(), v_round()
// Usage:
//   v2 = v_lookup(x, v);
// Description:
//   Works just like the built-in function [`lookup()`](https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/Mathematical_Functions#lookup), except that it can also interpolate between vector result values of the same length.
// Arguments:
//   x = The scalar value to look up.
//   v = A list of [KEY,VAL] pairs. KEYs are scalars.  VALs should either all be scalar, or all be vectors of the same length.
// Example:
//   x = v_lookup(4.5, [[4, [3,4,5]], [5, [5,6,7]]]);  // Returns: [4,5,6]
function v_lookup(x, v) =
    is_num(v[0][1])? lookup(x,v) :
    let(
        i = lookup(x, [for (i=idx(v)) [v[i].x,i]]),
        vlo = v[floor(i)],
        vhi = v[ceil(i)],
        lo = vlo[1],
        hi = vhi[1]
    )
    assert(is_vector(lo) && is_vector(hi),
        "\nResult values must all be numbers, or all be vectors.")
    assert(len(lo) == len(hi), "\nVector result values must be the same length.")
    vlo.x == vhi.x? vlo[1] :
    let( u = (x - vlo.x) / (vhi.x - vlo.x) )
    lerp(lo,hi,u);


// Section: Vector Properties


// Function: unit()
// Synopsis: Returns the unit length of a given vector.
// Topics: Vectors, Math
// See Also: v_abs(), v_floor(), v_ceil(), v_round()
// Usage:
//   v = unit(v, [error]);
// Description:
//   Returns the unit length normalized version of vector v.  If passed a zero-length vector,
//   asserts an error unless `error` is given, in which case the value of `error` is returned.
// Arguments:
//   v = The vector to normalize.
//   error = If given, and input is a zero-length vector, this value is returned.  Default: Assert error on zero-length vector.
// Example:
//   v1 = unit([10,0,0]);   // Returns: [1,0,0]
//   v2 = unit([0,10,0]);   // Returns: [0,1,0]
//   v3 = unit([0,0,10]);   // Returns: [0,0,1]
//   v4 = unit([0,-10,0]);  // Returns: [0,-1,0]
//   v5 = unit([0,0,0],[1,2,3]);    // Returns: [1,2,3]
//   v6 = unit([0,0,0]);    // Asserts an error.
function unit(v, error=[[["ASSERT"]]]) =
    assert(is_vector(v), "\nInvalid vector.")
    norm(v)<EPSILON? (error==[[["ASSERT"]]]? assert(norm(v)>=EPSILON,"\nCannot normalize a zero vector.") : error) :
    v/norm(v);


// Function: v_theta()
// Synopsis: Returns the angle counter-clockwise from X+ on the XY plane.
// Topics: Vectors, Math
// See Also: unit()
// Usage:
//   theta = v_theta([X,Y]);
// Description:
//   Given a vector, returns the angle in degrees counter-clockwise from X+ on the XY plane.
function v_theta(v) =
    assert( is_vector(v,2) || is_vector(v,3) , "\nInvalid vector.")
    atan2(v.y,v.x);



// Function: vector_angle()
// Synopsis: Returns the minor angle between two vectors.
// Topics: Vectors, Math
// See Also: unit(), v_theta()
// Usage:
//   ang = vector_angle(v1,v2);
//   ang = vector_angle([v1,v2]);
//   ang = vector_angle(PT1,PT2,PT3);
//   ang = vector_angle([PT1,PT2,PT3]);
// Description:
//   If given a single list of two vectors, like `vector_angle([V1,V2])`, returns the angle between the two vectors V1 and V2.
//   If given a single list of three points, like `vector_angle([A,B,C])`, returns the angle between the line segments AB and BC.
//   If given two vectors, like `vector_angle(V1,V2)`, returns the angle between the two vectors V1 and V2.
//   If given three points, like `vector_angle(A,B,C)`, returns the angle between the line segments AB and BC.
// Arguments:
//   v1 = First vector or point.
//   v2 = Second vector or point.
//   v3 = Third point in three point mode.
// Example:
//   ang1 = vector_angle(UP,LEFT);     // Returns: 90
//   ang2 = vector_angle(RIGHT,LEFT);  // Returns: 180
//   ang3 = vector_angle(UP+RIGHT,RIGHT);  // Returns: 45
//   ang4 = vector_angle([10,10], [0,0], [10,-10]);  // Returns: 90
//   ang5 = vector_angle([10,0,10], [0,0,0], [-10,10,0]);  // Returns: 120
//   ang6 = vector_angle([[10,0,10], [0,0,0], [-10,10,0]]);  // Returns: 120
function vector_angle(v1,v2,v3) =
    assert( ( is_undef(v3) && ( is_undef(v2) || same_shape(v1,v2) ) )
            || is_consistent([v1,v2,v3]) ,
            "\nBad arguments.")
    assert( is_vector(v1) || is_consistent(v1), "\nBad arguments.") 
    let( vecs = ! is_undef(v3) ? [v1-v2,v3-v2] :
                ! is_undef(v2) ? [v1,v2] :
                len(v1) == 3   ? [v1[0]-v1[1], v1[2]-v1[1]] 
                               : v1
    )
    assert(is_vector(vecs[0],2) || is_vector(vecs[0],3), "\nBad arguments.")
    let(
        norm0 = norm(vecs[0]),
        norm1 = norm(vecs[1])
    )
    assert(norm0>0 && norm1>0, "\nZero length vector.")
    // NOTE: constrain() corrects crazy FP rounding errors that exceed acos()'s domain.
    acos(constrain((vecs[0]*vecs[1])/(norm0*norm1), -1, 1));
    

// Function: vector_axis()
// Synopsis: Returns the perpendicular axis between two vectors.
// Topics: Vectors, Math
// See Also: unit(), v_theta(), vector_angle()
// Usage:
//   axis = vector_axis(v1,v2);
//   axis = vector_axis([v1,v2]);
//   axis = vector_axis(PT1,PT2,PT3);
//   axis = vector_axis([PT1,PT2,PT3]);
// Description:
//   If given a single list of two vectors, like `vector_axis([V1,V2])`, returns the vector perpendicular the two vectors V1 and V2.
//   If given a single list of three points, like `vector_axis([A,B,C])`, returns the vector perpendicular to the plane through a, B and C.
//   If given two vectors, like `vector_axis(V1,V2)`, returns the vector perpendicular to the two vectors V1 and V2.
//   If given three points, like `vector_axis(A,B,C)`, returns the vector perpendicular to the plane through a, B and C.
// Arguments:
//   v1 = First vector or point.
//   v2 = Second vector or point.
//   v3 = Third point in three point mode.
// Example:
//   axis1 = vector_axis(UP,LEFT);     // Returns: [0,-1,0] (FWD)
//   axis2 = vector_axis(RIGHT,LEFT);  // Returns: [0,-1,0] (FWD)
//   axis3 = vector_axis(UP+RIGHT,RIGHT);  // Returns: [0,1,0] (BACK)
//   axis4 = vector_axis([10,10], [0,0], [10,-10]);  // Returns: [0,0,-1] (DOWN)
//   axis5 = vector_axis([10,0,10], [0,0,0], [-10,10,0]);  // Returns: [-0.57735, -0.57735, 0.57735]
//   axis6 = vector_axis([[10,0,10], [0,0,0], [-10,10,0]]);  // Returns: [-0.57735, -0.57735, 0.57735]
function vector_axis(v1,v2=undef,v3=undef) =
    is_vector(v3)
    ?   assert(is_consistent([v3,v2,v1]), "\nBad arguments.")
        vector_axis(v1-v2, v3-v2)
    :   assert( is_undef(v3), "\nBad arguments.")
        is_undef(v2)
        ?   assert( is_list(v1), "\nBad arguments.")
            len(v1) == 2 
            ?   vector_axis(v1[0],v1[1]) 
            :   vector_axis(v1[0],v1[1],v1[2])
        :   assert( is_vector(v1,zero=false) && is_vector(v2,zero=false) && is_consistent([v1,v2])
                    , "\nBad arguments.")  
            let(
              eps = 1e-6,
              w1 = point3d(v1/norm(v1)),
              w2 = point3d(v2/norm(v2)),
              w3 = (norm(w1-w2) > eps && norm(w1+w2) > eps) ? w2 
                   : (norm(v_abs(w2)-UP) > eps)? UP 
                   : RIGHT
            ) unit(cross(w1,w3));


// Function: vector_bisect()
// Synopsis: Returns the vector that bisects two vectors.
// Topics: Vectors, Math
// See Also: unit(), v_theta(), vector_angle(), vector_axis()
// Usage:
//   newv = vector_bisect(v1,v2);
// Description:
//   Returns a unit vector that exactly bisects the minor angle between two given vectors.
//   If given two vectors that are directly opposed, returns `undef`.
function vector_bisect(v1,v2) =
    assert(is_vector(v1))
    assert(is_vector(v2))
    assert(!approx(norm(v1),0), "\nZero length vector.")
    assert(!approx(norm(v2),0), "\nZero length vector.")
    assert(len(v1)==len(v2), "\nVectors are of different sizes.")
    let( v1 = unit(v1), v2 = unit(v2) )
    approx(v1,-v2)? undef :
    let(
        axis = vector_axis(v1,v2),
        ang = vector_angle(v1,v2),
        v3 = unit(rot(ang/2, v=axis, p=v1))
    ) v3;


// Function: vector_perp()
// Synopsis: Returns component of a vector perpendicular to a second vector
// Topics: Vectors, Math
// Usage:
//   perp = vector_perp(v,w);
// Description:
//   Returns the component of vector w that is perpendicular to vector v.  Vectors must have the same length.  
// Arguments:
//   v = reference vector
//   w = vector whose perpendicular component is returned
// Example(2D):  We extract the component of the red vector that is perpendicular to the yellow vector.  That component appears in blue.  
//   v = [12,6];
//   w = [13,22];
//   stroke([[0,0],v],endcap2="arrow2");
//   stroke([[0,0],w],endcap2="arrow2",color="red");
//   stroke([[0,0],vector_perp(v,w)], endcap2="arrow2", color="blue");
function vector_perp(v,w) =
    assert(is_vector(v) && is_vector(w) && len(v)==len(w), "\nInvalid or mismatched inputs")
    w - w*v*v/(v*v);


// Section: Vector Searching


// Function: closest_point()
// Synopsis: Finds the closest point in a list of points.
// Topics: Geometry, Points, Distance
// See Also: pointlist_bounds(), furthest_point()
// Usage:
//   index = closest_point(pt, points);
// Description:
//   Given a list of `points`, finds the index of the closest point to `pt`.
// Arguments:
//   pt = The point to find the closest point to.
//   points = The list of points to search.
function closest_point(pt, points) =
    assert(is_vector(pt), "\nInvalid point." )
    assert(is_path(points,dim=len(pt)), "\nInvalid pointlist or incompatible dimensions." )
    min_index([for (p=points) norm(p-pt)]);


// Function: furthest_point()
// Synopsis: Finds the furthest point in a list of points.
// Topics: Geometry, Points, Distance
// See Also: pointlist_bounds(), closest_point()
// Usage:
//   index = furthest_point(pt, points);
// Description:
//   Given a list of `points`, finds the index of the furthest point from `pt`.
// Arguments:
//   pt = The point to find the farthest point from.
//   points = The list of points to search.
function furthest_point(pt, points) =
    assert( is_vector(pt), "\nInvalid point." )
    assert(is_path(points,dim=len(pt)), "\nInvalid pointlist or incompatible dimensions." )
    max_index([for (p=points) norm(p-pt)]);


// Function: vector_search()
// Synopsis: Finds points in a list that are close to a given point.
// Topics: Search, Points, Closest
// See Also: vector_search_tree(), vector_nearest()
// Usage:
//   indices = vector_search(query, r, target);
// Description:
//   Given a list of query points `query` and a `target` to search, 
//   finds the points in `target` that match each query point. A match holds when the 
//   distance between a point in `target` and a query point is less than or equal to `r`. 
//   The returned list contains a list for each query point containing, in arbitrary 
//   order, the indices of all points that match that query point. 
//   The `target` may be a simple list of points or a search tree.
//   When `target` is a large list of points, a search tree is constructed to 
//   speed up the search with an order around O(log n) per query point. 
//   For small point lists, a direct search is done dispensing a tree construction. 
//   Alternatively, `target` may be a search tree built with `vector_search_tree()`.
//   In that case, that tree is parsed looking for matches.
//   An empty list of query points returns a empty output list.
//   An empty list of target points returns a output list with an empty list for each query point.
// Arguments:
//   query = list of points to find matches for.
//   r = the search radius.
//   target = list of the points to search for matches or a search tree.
// Example: A set of four queries to find points within 1 unit of the query.  The circles show the search region and all have radius 1.  
//   $fn=32;
//   k = 2000;
//   points = list_to_matrix(rands(0,10,k*2,seed=13333),2);
//   queries = [for(i=[3,7],j=[3,7]) [i,j]];
//   search_ind = vector_search(queries, points, 1);
//   move_copies(points) circle(r=.08);
//   for(i=idx(queries)){
//       color("blue")stroke(move(queries[i],circle(r=1)), closed=true, width=.08);
//       color("red") move_copies(select(points, search_ind[i])) circle(r=.08);
//   }
// Example: when a series of searches with different radius are needed, its is faster to pre-compute the tree
//   $fn=32;
//   k = 2000;
//   points = list_to_matrix(rands(0,10,k*2),2,seed=13333);
//   queries1 = [for(i=[3,7]) [i,i]];
//   queries2 = [for(i=[3,7]) [10-i,i]];
//   r1 = 1;
//   r2 = .7;
//   search_tree = vector_search_tree(points);
//   search_1 = vector_search(queries1, r1, search_tree);
//   search_2 = vector_search(queries2, r2, search_tree);
//   move_copies(points) circle(r=.08);
//   for(i=idx(queries1)){
//       color("blue")stroke(move(queries1[i],circle(r=r1)), closed=true, width=.08);
//       color("red") move_copies(select(points, search_1[i])) circle(r=.08);
//   }
//   for(i=idx(queries2)){
//       color("green")stroke(move(queries2[i],circle(r=r2)), closed=true, width=.08);
//       color("red") move_copies(select(points, search_2[i])) circle(r=.08);
//   }
function vector_search(query, r, target) =
    query==[] ? [] :
    is_list(query) && target==[] ? is_vector(query) ? [] : [for(q=query) [] ] :
    assert( is_finite(r) && r>=0, 
            "\nThe query radius should be a positive number." )
    let(
        tgpts  = is_matrix(target),   // target is a point list
        tgtree = is_list(target)      // target is a tree
                 && (len(target)==2)
                 && is_matrix(target[0])
                 && is_list(target[1])
                 && (len(target[1])==4 || (len(target[1])==1 && is_list(target[1][0])) )
    )
    assert( tgpts || tgtree, 
            "\nThe target should be a list of points or a search tree compatible with the query." )
    let( 
        dim    = tgpts ? len(target[0]) : len(target[0][0]),
        simple = is_vector(query, dim)
        )
    assert( simple || is_matrix(query,undef,dim), 
            "\nThe query points should be a list of points compatible with the target point list.")
    tgpts 
    ?   len(target)<=400
        ?   simple ? [for(i=idx(target)) if(norm(target[i]-query)<=r) i ] :
            [for(q=query) [for(i=idx(target)) if(norm(target[i]-q)<=r) i ] ]
        :   let( tree = _bt_tree(target, count(len(target)), leafsize=25) )
            simple ? _bt_search(query, r, target, tree) :
            [for(q=query) _bt_search(q, r, target, tree)]
    :   simple ?  _bt_search(query, r, target[0], target[1]) :
        [for(q=query) _bt_search(q, r, target[0], target[1])];


//Ball tree search
function _bt_search(query, r, points, tree) = 
    assert( is_list(tree) 
            && (   ( len(tree)==1 && is_list(tree[0]) )
                || ( len(tree)==4 && is_num(tree[0]) && is_num(tree[1]) ) ), 
            "\nThe tree is invalid.")
    len(tree)==1 
    ?   assert( tree[0]==[] || is_vector(tree[0]), "\nThe tree is invalid." )
        [for(i=tree[0]) if(norm(points[i]-query)<=r) i ]
    :   norm(query-points[tree[0]]) > r+tree[1] ? [] :
        concat( 
            [ if(norm(query-points[tree[0]])<=r) tree[0] ],
            _bt_search(query, r, points, tree[2]),
            _bt_search(query, r, points, tree[3]) ) ;
     

// Function: vector_search_tree()
// Synopsis: Makes a distance search tree for a list of points.
// Topics: Search, Points, Closest
// See Also: vector_nearest(), vector_search()
// Usage:
//    tree = vector_search_tree(points,leafsize);
// Description:
//    Construct a search tree for the given list of points to be used as input
//    to the function `vector_search()`. The use of a tree speeds up the
//    search process. The tree construction stops branching when 
//    a tree node represents a number of points less or equal to `leafsize`.
//    Search trees are ball trees. Constructing the
//    tree should be O(n log n) and searches should be O(log n), although real life
//    performance depends on how the data is distributed, and it deteriorates
//    for high data dimensions.  This data structure is useful when you are
//    performing many searches of the same data, so that the cost of constructing 
//    the tree is justified. (See https://en.wikipedia.org/wiki/Ball_tree)
//    For a small lists of points, the search with a tree may be more expensive
//    than direct comparisons. The argument `treemin` sets the minimum length of 
//    the point set for which a tree search will be done by `vector_search`.
//    For an empty list of points it returns an empty list.
// Arguments:
//    points = list of points to store in the search tree.
//    leafsize = the size of the tree leaves. Default: 25
//    treemin = the minimum size of the point list for which a tree search is done. Default: 400
// Example: A set of four queries to find points within 1 unit of the query.  The circles show the search region and all have radius 1.  
//   $fn=32;
//   k = 2000;
//   points = random_points(k, scale=10, dim=2,seed=13333);
//   queries = [for(i=[3,7],j=[3,7]) [i,j]];
//   search_tree = vector_search_tree(points);
//   search_ind = vector_search(queries,1,search_tree);
//   move_copies(points) circle(r=.08);
//   for(i=idx(queries)){
//       color("blue") stroke(move(queries[i],circle(r=1)), closed=true, width=.08);
//       color("red")  move_copies(select(points, search_ind[i])) circle(r=.08);
//   }
function vector_search_tree(points, leafsize=25, treemin=400) =
    points==[] ? [] :
    assert( is_matrix(points), "\nThe input list entries should be points." )
    assert( is_int(leafsize) && leafsize>=1,
            "\nThe tree leaf size should be an integer greater than zero.")
    len(points)<treemin ? points :
    [ points, _bt_tree(points, count(len(points)), leafsize) ];


//Ball tree construction
function _bt_tree(points, ind, leafsize=25) =
    len(ind)<=leafsize ? [ind] :
    let( 
        bounds = pointlist_bounds(select(points,ind)),
        coord  = max_index(bounds[1]-bounds[0]), 
        projc  = [for(i=ind) points[i][coord] ],
        meanpr = mean(projc), 
        pivot  = min_index([for(p=projc) abs(p-meanpr)]),
        radius = max([for(i=ind) norm(points[ind[pivot]]-points[i]) ]),
        Lind   = [for(i=idx(ind)) if(projc[i]<=meanpr && i!=pivot) ind[i] ],
        Rind   = [for(i=idx(ind)) if(projc[i] >meanpr && i!=pivot) ind[i] ]
      )
    [ ind[pivot], radius, _bt_tree(points, Lind, leafsize), _bt_tree(points, Rind, leafsize) ];


// Function: vector_nearest()
// Synopsis: Finds the `k` nearest points in a list to a given point.
// Topics: Search, Points, Closest
// See Also: vector_search(), vector_search_tree()
// Usage:
//    indices = vector_nearest(query, k, target);
// Description:
//    Search `target` for the `k` points closest to point `query`.
//    The input `target` is either a list of points to search or a search tree
//    pre-computed by `vector_search_tree(). A list is returned containing the indices
//    of the points found in sorted order, closest point first.  
// Arguments:
//    query = point to search for
//    k = number of neighbors to return
//    target = a list of points or a search tree to search in
// Example:  Four queries to find the 15 nearest points.  The circles show the radius defined by the most distant query result.  Note they are different for each query.  
//    $fn=32;
//    k = 1000;
//    points = list_to_matrix(rands(0,10,k*2,seed=13333),2);
//    tree = vector_search_tree(points);
//    queries = [for(i=[3,7],j=[3,7]) [i,j]];
//    search_ind = [for(q=queries) vector_nearest(q, 15, tree)];
//    move_copies(points) circle(r=.08);
//    for(i=idx(queries)){
//        circle = circle(r=norm(points[last(search_ind[i])]-queries[i]));
//        color("red")  move_copies(select(points, search_ind[i])) circle(r=.08);
//        color("blue") stroke(move(queries[i], circle), closed=true, width=.08);  
//    }
function vector_nearest(query, k, target) =
    assert(is_int(k) && k>0)
    assert(is_vector(query), "\nQuery must be a vector.")
    let(
        tgpts  = is_matrix(target,undef,len(query)), // target is a point list
        tgtree = is_list(target)      // target is a tree
                 && (len(target)==2)
                 && is_matrix(target[0],undef,len(query))
                 && (len(target[1])==4 || (len(target[1])==1 && is_list(target[1][0])) )
    )
    assert( tgpts || tgtree, 
            "\nThe target should be a list of points or a search tree compatible with the query." )
    assert((tgpts && (k<=len(target))) || (tgtree && (k<=len(target[0]))), 
            "\nMore results are requested than the number of points.")
    tgpts
    ?   let( tree = _bt_tree(target, count(len(target))) )
        column(_bt_nearest( query, k, target,  tree),0)
    :   column(_bt_nearest( query, k, target[0], target[1]),0);


//Ball tree nearest
function _bt_nearest(p, k, points, tree, answers=[]) =
    assert( is_list(tree) 
            && (   ( len(tree)==1 && is_list(tree[0]) )
                || ( len(tree)==4 && is_num(tree[0]) && is_num(tree[1]) ) ), 
            "\nThe tree is invalid.")
    len(tree)==1
    ?   _insert_many(answers, k, [for(entry=tree[0]) [entry, norm(points[entry]-p)]])
    :   let( d = norm(p-points[tree[0]]) )
        len(answers)==k && ( d > last(answers)[1]+tree[1] ) ? answers :
        let(
            answers1 = _insert_sorted(answers, k, [tree[0],d]),
            answers2 = _bt_nearest(p, k, points, tree[2], answers1),
            answers3 = _bt_nearest(p, k, points, tree[3], answers2)
         )
         answers3;


function _insert_sorted(list, k, new) =
    (len(list)==k && new[1]>= last(list)[1]) ? list
    : [
        for(entry=list) if (entry[1]<=new[1]) entry,
        new,
        for(i=[0:1:min(k-1,len(list))-1]) if (list[i][1]>new[1]) list[i]
      ];


function _insert_many(list, k, newlist,i=0) =
  i==len(newlist) 
    ? list
    : assert(is_vector(newlist[i],2), "\nThe tree is invalid.")
      _insert_many(_insert_sorted(list,k,newlist[i]),k,newlist,i+1);



// Section: Bounds


// Function: pointlist_bounds()
// Synopsis: Returns the min and max bounding coordinates for the given list of points.
// Topics: Geometry, Bounding Boxes, Bounds, Scaling
// See Also: closest_point(), furthest_point(), vnf_bounds()
// Usage:
//   pt_pair = pointlist_bounds(pts);
// Description:
//   Finds the bounds containing all the points in `pts`, which can be a list of points in any dimension.
//   Returns a list of two items: a list of the minimums and a list of the maximums.  For example, with
//   3d points `[[MINX, MINY, MINZ], [MAXX, MAXY, MAXZ]]`
// Arguments:
//   pts = List of points.
function pointlist_bounds(pts) =
    assert(is_path(pts,dim=undef,fast=true) , "\nInvalid pointlist." )
    let(
        select = ident(len(pts[0])),
        spread = [
            for(i=[0:len(pts[0])-1])
            let( spreadi = pts*select[i] )
            [ min(spreadi), max(spreadi) ]
        ]
    ) transpose(spread);


// Function: fit_to_box()
// Synopsis: Scale the x, y, and/or z coordinantes of a list of points to span a range.
// Topics: Geometry, Bounding Boxes, Bounds, VNF Manipulation
// See Also: fit_to_range()
// Usage:
//   new_pts = fit_to_box(pts, [x=], [y=], [z=]);
//   new_vnf = fit_to_box(vnf, [x=], [y=], [z=]);
// Description:
//   Given a list of 2D or 3D points, or a VNF structure, rescale and position one or more of the coordinates
//   to fit within specified ranges. At least one range (`x`, `y`, or `z`) must be specified. A normal use case
//   for this function is to rescale a VNF texture to fit within `0 <= z <= 1`.
//   .
//   While a range is typically `[min_value,max_value]`, the minimum and maximum values can be reversed,
//   resulting in new coordinates being a rescaled mirror image of the original coordinates.
// Arguments:
//   pts = List of points, or a VNF structure.
//   x = `[min,max]` of rescaled x coordinates. Default: undef
//   y = `[min,max]` of rescaled y coordinates. Default: undef
//   z = `[min,max]` of rescaled z coordinates. Default: undef
// Example(2D): A 2D bezier path (red) rescaled (blue) to fit in a square box centered on the origin.
//   bez = [
//       [10,60], [-5,30],
//       [20,60], [50,50], [100,30],
//       [50,30], [70,20]
//   ];
//   path = bezpath_curve(bez);
//   newpath = fit_to_box(path, x=[0,40], y=[0,40]);
//   stroke(path, width=2, color="red");
//   stroke(square(40), width=1, closed=true);
//   stroke(newpath, width=2, color="blue");
// Example(3D): A prismoid (left) is rescaled to fit new x and z bounds. The z bounds minimum and maximum values are reversed, resulting in the new object on the right having inverted z coordinates.
//   vnf = prismoid(size1=[50,30], size2=[20,20], h=20, shift=[15,5]);
//   vnf_boxed = fit_to_box(vnf, x=[30,55], z=[5,-15]);
//   vnf_polyhedron(vnf);
//   vnf_polyhedron(vnf_boxed);
function fit_to_box(pts, x, y, z) =
    assert(is_path(pts) || is_vnf(pts), "\npts must be a valid 2D or 3D path, or a VNF structure.")
    assert(any_defined([x,y,z]), "\nAt least one [min,max] range x, y, or z must be defined.")
    assert(is_undef(x) || is_vector(x,2), "\nx must be a 2-vector [min,max].")
    assert(is_undef(y) || is_vector(y,2), "\nx must be a 2-vector [min,max].")
    assert(is_undef(z) || is_vector(z,2), "\nx must be a 2-vector [min,max].")
    let(
        isvnf = is_vnf(pts),
        p = isvnf ? pts[0] : pts,
        bounds = isvnf ? vnf_bounds(pts) : pointlist_bounds(pts),
        dim = len(bounds[0]),
        err = assert(is_undef(z) || (dim>2 && is_def(z)), "\n2D data detected with z range specified."),
        whichdim = [is_def(x), is_def(y), is_def(z)],
        xmin = bounds[0][0],
        ymin = bounds[0][1],
        zmin = dim>2 ? bounds[0][2] : 0,
        // new scales
        xscale = whichdim.x ? (x[1]-x[0]) / (bounds[1][0]-xmin) : 1,
        yscale = whichdim.y ? (y[1]-y[0]) / (bounds[1][1]-ymin) : 1,
        zscale = whichdim.z ? (z[1]-z[0]) / (bounds[1][2]-zmin) : 1,
        // new offsets
        xo = whichdim.x ? x[0] : 0,
        yo = whichdim.y ? y[0] : 0,
        zo = whichdim.z ? z[0] : 0,
        // shift original min to 0, rescale to new scale, shift back to new min
        newpts = move(dim>2 ? [xo,yo,zo] : [xo,yo],
                      scale(dim>2 ? [xscale,yscale,zscale] : [xscale,yscale],
                             move(dim>2 ? -[xmin,ymin,zmin] : -[xmin,ymin], pts)))
    ) isvnf ? [newpts[0], pts[1]] : newpts;


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
