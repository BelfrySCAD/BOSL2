//////////////////////////////////////////////////////////////////////
// LibFile: vectors.scad
//   Vector math functions.
// Includes:
//   include <BOSL2/std.scad>
//////////////////////////////////////////////////////////////////////


// Section: Vector Manipulation


// Function: is_vector()
// Usage:
//   is_vector(v, [length], ...);
// Description:
//   Returns true if v is a list of finite numbers.
// Arguments:
//   v = The value to test to see if it is a vector.
//   length = If given, make sure the vector is `length` items long.
//   zero = If false, require that the length/`norm()` of the vector is not approximately zero.  If true, require the length/`norm()` of the vector to be approximately zero-length.  Default: `undef` (don't check vector length/`norm()`.)
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
    is_list(v) && len(v)>0 && []==[for(vi=v) if(!is_num(vi)) 0] 
    && (is_undef(length) || len(v)==length)
    && (is_undef(zero) || ((norm(v) >= eps) == !zero))
    && (!all_nonzero || all_nonzero(v)) ;


// Function: v_theta()
// Usage:
//   theta = v_theta([X,Y]);
// Description:
//   Given a vector, returns the angle in degrees counter-clockwise from X+ on the XY plane.
function v_theta(v) =
    assert( is_vector(v,2) || is_vector(v,3) , "Invalid vector")
    atan2(v.y,v.x);


// Function: v_mul()
// Description:
//   Element-wise multiplication.  Multiplies each element of `v1` by the corresponding element of `v2`.
//   Both `v1` and `v2` must be the same length.  Returns a vector of the products.
// Arguments:
//   v1 = The first vector.
//   v2 = The second vector.
// Example:
//   v_mul([3,4,5], [8,7,6]);  // Returns [24, 28, 30]
function v_mul(v1, v2) = 
    assert( is_list(v1) && is_list(v2) && len(v1)==len(v2), "Incompatible input")
    [for (i = [0:1:len(v1)-1]) v1[i]*v2[i]];
    

// Function: v_div()
// Description:
//   Element-wise vector division.  Divides each element of vector `v1` by
//   the corresponding element of vector `v2`.  Returns a vector of the quotients.
// Arguments:
//   v1 = The first vector.
//   v2 = The second vector.
// Example:
//   v_div([24,28,30], [8,7,6]);  // Returns [3, 4, 5]
function v_div(v1, v2) = 
    assert( is_vector(v1) && is_vector(v2,len(v1)), "Incompatible vectors")
    [for (i = [0:1:len(v1)-1]) v1[i]/v2[i]];


// Function: v_abs()
// Description: Returns a vector of the absolute value of each element of vector `v`.
// Arguments:
//   v = The vector to get the absolute values of.
// Example:
//   v_abs([-1,3,-9]);  // Returns: [1,3,9]
function v_abs(v) =
    assert( is_vector(v), "Invalid vector" ) 
    [for (x=v) abs(x)];


// Function: v_floor()
// Description:
//   Returns the given vector after performing a `floor()` on all items.
function v_floor(v) =
    assert( is_vector(v), "Invalid vector" ) 
    [for (x=v) floor(x)];


// Function: v_ceil()
// Description:
//   Returns the given vector after performing a `ceil()` on all items.
function v_ceil(v) =
    assert( is_vector(v), "Invalid vector" ) 
    [for (x=v) ceil(x)];


// Function: unit()
// Usage:
//   unit(v, [error]);
// Description:
//   Returns the unit length normalized version of vector v.  If passed a zero-length vector,
//   asserts an error unless `error` is given, in which case the value of `error` is returned.
// Arguments:
//   v = The vector to normalize.
//   error = If given, and input is a zero-length vector, this value is returned.  Default: Assert error on zero-length vector.
// Examples:
//   unit([10,0,0]);   // Returns: [1,0,0]
//   unit([0,10,0]);   // Returns: [0,1,0]
//   unit([0,0,10]);   // Returns: [0,0,1]
//   unit([0,-10,0]);  // Returns: [0,-1,0]
//   unit([0,0,0],[1,2,3]);    // Returns: [1,2,3]
//   unit([0,0,0]);    // Asserts an error.
function unit(v, error=[[["ASSERT"]]]) =
    assert(is_vector(v), str("Expected a vector.  Got: ",v))
    norm(v)<EPSILON? (error==[[["ASSERT"]]]? assert(norm(v)>=EPSILON,"Tried to normalize a zero vector") : error) :
    v/norm(v);


// Function: vector_angle()
// Usage:
//   vector_angle(v1,v2);
//   vector_angle([v1,v2]);
//   vector_angle(PT1,PT2,PT3);
//   vector_angle([PT1,PT2,PT3]);
// Description:
//   If given a single list of two vectors, like `vector_angle([V1,V2])`, returns the angle between the two vectors V1 and V2.
//   If given a single list of three points, like `vector_angle([A,B,C])`, returns the angle between the line segments AB and BC.
//   If given two vectors, like `vector_angle(V1,V2)`, returns the angle between the two vectors V1 and V2.
//   If given three points, like `vector_angle(A,B,C)`, returns the angle between the line segments AB and BC.
// Arguments:
//   v1 = First vector or point.
//   v2 = Second vector or point.
//   v3 = Third point in three point mode.
// Examples:
//   vector_angle(UP,LEFT);     // Returns: 90
//   vector_angle(RIGHT,LEFT);  // Returns: 180
//   vector_angle(UP+RIGHT,RIGHT);  // Returns: 45
//   vector_angle([10,10], [0,0], [10,-10]);  // Returns: 90
//   vector_angle([10,0,10], [0,0,0], [-10,10,0]);  // Returns: 120
//   vector_angle([[10,0,10], [0,0,0], [-10,10,0]]);  // Returns: 120
function vector_angle(v1,v2,v3) =
    assert( ( is_undef(v3) && ( is_undef(v2) || same_shape(v1,v2) ) )
            || is_consistent([v1,v2,v3]) ,
            "Bad arguments.")
    assert( is_vector(v1) || is_consistent(v1), "Bad arguments.") 
    let( vecs = ! is_undef(v3) ? [v1-v2,v3-v2] :
                ! is_undef(v2) ? [v1,v2] :
                len(v1) == 3   ? [v1[0]-v1[1], v1[2]-v1[1]] 
                               : v1
    )
    assert(is_vector(vecs[0],2) || is_vector(vecs[0],3), "Bad arguments.")
    let(
        norm0 = norm(vecs[0]),
        norm1 = norm(vecs[1])
    )
    assert(norm0>0 && norm1>0, "Zero length vector.")
    // NOTE: constrain() corrects crazy FP rounding errors that exceed acos()'s domain.
    acos(constrain((vecs[0]*vecs[1])/(norm0*norm1), -1, 1));
    

// Function: vector_axis()
// Usage:
//   vector_axis(v1,v2);
//   vector_axis([v1,v2]);
//   vector_axis(PT1,PT2,PT3);
//   vector_axis([PT1,PT2,PT3]);
// Description:
//   If given a single list of two vectors, like `vector_axis([V1,V2])`, returns the vector perpendicular the two vectors V1 and V2.
//   If given a single list of three points, like `vector_axis([A,B,C])`, returns the vector perpendicular to the plane through a, B and C.
//   If given two vectors, like `vector_axis(V1,V2)`, returns the vector perpendicular to the two vectors V1 and V2.
//   If given three points, like `vector_axis(A,B,C)`, returns the vector perpendicular to the plane through a, B and C.
// Arguments:
//   v1 = First vector or point.
//   v2 = Second vector or point.
//   v3 = Third point in three point mode.
// Examples:
//   vector_axis(UP,LEFT);     // Returns: [0,-1,0] (FWD)
//   vector_axis(RIGHT,LEFT);  // Returns: [0,-1,0] (FWD)
//   vector_axis(UP+RIGHT,RIGHT);  // Returns: [0,1,0] (BACK)
//   vector_axis([10,10], [0,0], [10,-10]);  // Returns: [0,0,-1] (DOWN)
//   vector_axis([10,0,10], [0,0,0], [-10,10,0]);  // Returns: [-0.57735, -0.57735, 0.57735]
//   vector_axis([[10,0,10], [0,0,0], [-10,10,0]]);  // Returns: [-0.57735, -0.57735, 0.57735]
function vector_axis(v1,v2=undef,v3=undef) =
    is_vector(v3)
    ?   assert(is_consistent([v3,v2,v1]), "Bad arguments.")
        vector_axis(v1-v2, v3-v2)
    :   assert( is_undef(v3), "Bad arguments.")
        is_undef(v2)
        ?   assert( is_list(v1), "Bad arguments.")
            len(v1) == 2 
            ?   vector_axis(v1[0],v1[1]) 
            :   vector_axis(v1[0],v1[1],v1[2])
        :   assert( is_vector(v1,zero=false) && is_vector(v2,zero=false) && is_consistent([v1,v2])
                    , "Bad arguments.")  
            let(
              eps = 1e-6,
              w1 = point3d(v1/norm(v1)),
              w2 = point3d(v2/norm(v2)),
              w3 = (norm(w1-w2) > eps && norm(w1+w2) > eps) ? w2 
                   : (norm(v_abs(w2)-UP) > eps)? UP 
                   : RIGHT
            ) unit(cross(w1,w3));



// Section: Vector Searching


// Function: vector_search()
// Usage:
//   indices = vector_search(query, r, target);
// See Also: vector_search_tree(), vector_nearest()
// Topics: Search, Points, Closest
// Description:
//   Given a list of query points `query` and a `target` to search, 
//   finds the points in `target` that match each query point. A match holds when the 
//   distance between a point in `target` and a query point is less than or equal to `r`. 
//   The returned list will have a list for each query point containing, in arbitrary 
//   order, the indices of all points that match that query point. 
//   The `target` may be a simple list of points or a search tree.
//   When `target` is a large list of points, a search tree is constructed to 
//   speed up the search with an order around O(log n) per query point. 
//   For small point lists, a direct search is done dispensing a tree construction. 
//   Alternatively, `target` may be a search tree built with `vector_tree_search()`.
//   In that case, that tree is parsed looking for matches.
// Arguments:
//   query = list of points to find matches for.
//   r = the search radius.
//   target = list of the points to search for matches or a search tree.
// Example: A set of four queries to find points within 1 unit of the query.  The circles show the search region and all have radius 1.  
//   $fn=32;
//   k = 2000;
//   points = array_group(rands(0,10,k*2,seed=13333),2);
//   queries = [for(i=[3,7],j=[3,7]) [i,j]];
//   search_ind = vector_search(queries, points, 1);
//   move_copies(points) circle(r=.08);
//   for(i=idx(queries)){
//       color("blue")stroke(move(queries[i],circle(r=1)), closed=true, width=.08);
//       color("red") move_copies(select(points, search_ind[i])) circle(r=.08);
//   }
// Example: when a series of search with different radius are needed, its is faster to pre-compute the tree
//   $fn=32;
//   k = 2000;
//   points = array_group(rands(0,10,k*2),2,seed=13333);
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
    assert( is_finite(r) && r>=0, 
            "The query radius should be a positive number." )
    let(
        tgpts  = is_matrix(target),   // target is a point list
        tgtree = is_list(target)      // target is a tree
                 && (len(target)==2)
                 && is_matrix(target[0])
                 && is_list(target[1])
                 && (len(target[1])==4 || (len(target[1])==1 && is_list(target[1][0])) )
    )
    assert( tgpts || tgtree, 
            "The target should be a list of points or a search tree compatible with the query." )
    let( 
        dim    = tgpts ? len(target[0]) : len(target[0][0]),
        simple = is_vector(query, dim),
        mult   = !simple && is_matrix(query,undef,dim)
    )
    assert( simple || mult, 
            "The query points should be a list of points compatible with the target point list.")
    tgpts 
    ?   len(target)<200
        ?   simple ? [for(i=idx(target)) if(norm(target[i]-query)<r) i ] :
            [for(q=query) [for(i=idx(target)) if(norm(target[i]-q)<r) i ] ]
        :   let( tree = _bt_tree(target, count(len(target)), leafsize=25) )
            simple ? _bt_search(query, r, target, tree) :
            [for(q=query) _bt_search(q, r, target, tree)]
    :   simple ?  _bt_search(query, r, target[0], target[1]) :
        [for(q=query) _bt_search(q, r, target[0], target[1])];


//Ball tree search
function _bt_search(query, r, points, tree) = //echo(tree)
    assert( is_list(tree) 
            && (   ( len(tree)==1 && is_list(tree[0]) )
                || ( len(tree)==4 && is_num(tree[0]) && is_num(tree[1]) ) ), 
            "The tree is invalid.")
    len(tree)==1 
    ?   assert( tree[0]==[] || is_vector(tree[0]), "The tree is invalid." )
        [for(i=tree[0]) if(norm(points[i]-query)<=r) i ]
    :   norm(query-points[tree[0]]) > r+tree[1] ? [] :
        concat( 
            [ if(norm(query-points[tree[0]])<=r) tree[0] ],
            _bt_search(query, r, points, tree[2]),
            _bt_search(query, r, points, tree[3]) ) ;
     

// Function: vector_search_tree()
// Usage:
//    tree = vector_search_tree(points,leafsize);
// See Also: vector_nearest(), vector_search()
// Topics: Search, Points, Closest
// Description:
//    Construct a search tree for the given list of points to be used as input
//    to the function `vector_search()`. The use of a tree speeds up the
//    search process. The tree construction stops branching when 
//    a tree node represents a number of points less or equal to `leafsize`.
//    Search trees are ball trees. Constructing the
//    tree should be O(n log n) and searches should be O(log n), though real life
//    performance depends on how the data is distributed, and it will deteriorate
//    for high data dimensions.  This data structure is useful when you will be
//    performing many searches of the same data, so that the cost of constructing 
//    the tree is justified. (See https://en.wikipedia.org/wiki/Ball_tree)
// Arguments:
//    points = list of points to store in the search tree.
//    leafsize = the size of the tree leaves. Default: 25
// Example: A set of four queries to find points within 1 unit of the query.  The circles show the search region and all have radius 1.  
//   $fn=32;
//   k = 2000;
//   points = array_group(rands(0,10,k*2,seed=13333),2);
//   queries = [for(i=[3,7],j=[3,7]) [i,j]];
//   search_tree = vector_search_tree(points);
//   search_ind = vector_tree_search(search_tree, queries, 1);
//   move_copies(points) circle(r=.08);
//   for(i=idx(queries)){
//       color("blue") stroke(move(queries[i],circle(r=1)), closed=true, width=.08);
//       color("red")  move_copies(select(points, search_ind[i])) circle(r=.08); }
//   }
function vector_search_tree(points, leafsize=25) =
    assert( is_matrix(points), "The input list entries should be points." )
    assert( is_int(leafsize) && leafsize>=1,
            "The tree leaf size should be an integer greater than zero.")
    [ points, _bt_tree(points, count(len(points)), leafsize) ];


//Ball tree construction
function _bt_tree(points, ind, leafsize=25) =
    len(ind)<=leafsize ? [ind] :
    let( 
        bounds = pointlist_bounds(select(points,ind)),
        coord  = max_index(bounds[1]-bounds[0]), 
        projc  = [for(i=ind) points[i][coord] ],
        pmc    = mean(projc), 
        pivot  = min_index([for(p=projc) abs(p-pmc)]),
        radius = max([for(i=ind) norm(points[ind[pivot]]-points[i]) ]),
        median = ninther(projc),
        Lind   = [for(i=idx(ind)) if(projc[i]<=median && i!=pivot) ind[i] ],
        Rind   = [for(i=idx(ind)) if(projc[i] >median && i!=pivot) ind[i] ]
      )
    [ ind[pivot], radius, _bt_tree(points, Lind, leafsize), _bt_tree(points, Rind, leafsize) ];


// Function: vector_nearest()
// Usage:
//    indices = vector_nearest(query, k, target)
// See Also: vector_search(), vector_search_tree()
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
//    points = array_group(rands(0,10,k*2,seed=13333),2);
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
    assert(is_vector(query), "Query must be a vector.")
    let(
        tgpts  = is_matrix(target,undef,len(query)), // target is a point list
        tgtree = is_list(target)      // target is a tree
                 && (len(target)==2)
                 && is_matrix(target[0],undef,len(query))
                 && (len(target[1])==4 || (len(target[1])==1 && is_list(target[1][0])) )
    )
    assert( tgpts || tgtree, 
            "The target should be a list of points or a search tree compatible with the query." )
    assert((tgpts && (k<=len(target))) || (tgtree && (k<=len(target[0]))), 
            "More results are requested than the number of points.")
    tgpts
    ?   let( tree = _bt_tree(target, count(len(target))) )
        subindex(_bt_nearest( query, k, target,  tree),0)
    :   subindex(_bt_nearest( query, k, target[0], target[1]),0);


//Ball tree nearest
function _bt_nearest(p, k, points, tree, answers=[]) =
    assert( is_list(tree) 
            && (   ( len(tree)==1 && is_list(tree[0]) )
                || ( len(tree)==4 && is_num(tree[0]) && is_num(tree[1]) ) ), 
            "The tree is invalid.")
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
  ?   list
  :   assert(is_vector(newlist[i],2), "The tree is invalid.")
      _insert_many(_insert_sorted(list,k,newlist[i]),k,newlist,i+1);



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
