//////////////////////////////////////////////////////////////////////
// LibFile: vectors.scad
//   Vector math functions.
// Includes:
//   include <BOSL2/std.scad>
//////////////////////////////////////////////////////////////////////


// Section: Vector Manipulation


// Function: is_vector()
// Usage:
//   is_vector(v, [length]);
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


// Function: vang()
// Usage:
//   theta = vang([X,Y]);
//   theta_phi = vang([X,Y,Z]);
// Description:
//   Given a 2D vector, returns the angle in degrees counter-clockwise from X+ on the XY plane.
//   Given a 3D vector, returns [THETA,PHI] where THETA is the number of degrees counter-clockwise from X+ on the XY plane, and PHI is the number of degrees up from the X+ axis along the XZ plane.
function vang(v) =
    assert( is_vector(v,2) || is_vector(v,3) , "Invalid vector")
    len(v)==2? atan2(v.y,v.x) :
    let(res=xyz_to_spherical(v)) [res[1], 90-res[2]];


// Function: vmul()
// Description:
//   Element-wise multiplication.  Multiplies each element of `v1` by the corresponding element of `v2`.
//   Both `v1` and `v2` must be the same length.  Returns a vector of the products.
// Arguments:
//   v1 = The first vector.
//   v2 = The second vector.
// Example:
//   vmul([3,4,5], [8,7,6]);  // Returns [24, 28, 30]
function vmul(v1, v2) = 
    assert( is_list(v1) && is_list(v2) && len(v1)==len(v2), "Incompatible input")
    [for (i = [0:1:len(v1)-1]) v1[i]*v2[i]];
    

// Function: vdiv()
// Description:
//   Element-wise vector division.  Divides each element of vector `v1` by
//   the corresponding element of vector `v2`.  Returns a vector of the quotients.
// Arguments:
//   v1 = The first vector.
//   v2 = The second vector.
// Example:
//   vdiv([24,28,30], [8,7,6]);  // Returns [3, 4, 5]
function vdiv(v1, v2) = 
    assert( is_vector(v1) && is_vector(v2,len(v1)), "Incompatible vectors")
    [for (i = [0:1:len(v1)-1]) v1[i]/v2[i]];


// Function: vabs()
// Description: Returns a vector of the absolute value of each element of vector `v`.
// Arguments:
//   v = The vector to get the absolute values of.
// Example:
//   vabs([-1,3,-9]);  // Returns: [1,3,9]
function vabs(v) =
    assert( is_vector(v), "Invalid vector" ) 
    [for (x=v) abs(x)];


// Function: vfloor()
// Description:
//   Returns the given vector after performing a `floor()` on all items.
function vfloor(v) =
    assert( is_vector(v), "Invalid vector" ) 
    [for (x=v) floor(x)];


// Function: vceil()
// Description:
//   Returns the given vector after performing a `ceil()` on all items.
function vceil(v) =
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
                   : (norm(vabs(w2)-UP) > eps)? UP 
                   : RIGHT
            ) unit(cross(w1,w3));


// Section: Vector Searching

// Function: vp_tree()
// Usage:
//    tree = vp_tree(points, <leafsize>)
// Description:
//    Organizes n-dimensional data into a Vantage Point Tree, which can be
//    efficiently searched for for nearest matches.  The Vantage Point Tree
//    is an effort to generalize binary search to n dimensions.  Constructing the
//    tree should be O(n log n) and searches should be O(log n), though real life
//    performance depends on how the data is distributed, and it will deteriorate
//    for high data dimensions.  This data structure is useful when you will be
//    performing many searches of the same data, so that the cost of constructing
//    the tree is justified.  
//    .
//    The vantage point tree at a given level chooses vp, the
//    "vantage point", and a radius, R, and divides the data based
//    on distance to vp.  Points closer than R go in on branch
//    of the tree and points farther than R go in the other branch.
//    .
//    The tree has the form [vp, R, inside, outside], where vp is
//    the vantage point index, R is the radius, inside is a
//    recursively computed tree for the inside points (distance less than
//    or equal to R from the vantage point), and outside
//    is a tree for the outside points (distance greater than R from the
//    vantage point).
//    .
//    If the number of points is less than or equal to leafsize then
//    vp_tree instead returns the list [ind] where ind is a list of
//    the indices of the points.  This means the list has the form
//    [[i0, i1, i2,...]], so tree[0] is a list of indices.  You can
//    tell that a node is a leaf node by checking if tree[0] is a list.
//    The leafsize parameter determines how many points can be
//    store in the leaf nodes.  The default value of 25 was found
//    emperically to be a reasonable option for 3d data searched with vp_search().
//    .
//    Vantage point tree is described here: http://web.cs.iastate.edu/~honavar/nndatastructures.pdf
// Arguments:
//    points = list of points to store in the tree
//    leafsize = maximum number of points to store in the tree's leaf nodes.  Default: 25
function vp_tree(points, leafsize=25) =
  assert(is_matrix(points),"points must be a consistent list of data points")
  _vp_tree(points, count(len(points)), leafsize);

function _vp_tree(ptlist, ind, leafsize) =
  len(ind)<=leafsize ? [ind] :
  let(
       center = mean(select(ptlist,ind)),
       cdistances = [for(i=ind) norm(ptlist[i]-center)],
       vpind = ind[max_index(cdistances)],
       vp = ptlist[vpind],
       vp_dist = [for(i=ind) norm(vp-ptlist[i])],
       r = ninther(vp_dist),
       inside = [for(i=idx(ind)) if (vp_dist[i]<=r && ind[i]!=vpind) ind[i]],
       outside = [for(i=idx(ind)) if (vp_dist[i]>r) ind[i]]
   )
   [vpind, r, _vp_tree(ptlist,inside,leafsize),_vp_tree(ptlist,outside,leafsize)];


// Function: vp_search()
// Usage:
//   indices = vp_search(points, tree, p, r);
// Description:
//   Search a vantage point tree for all points whose distance from p
//   is less than or equal to r.  Returns a list of indices of the points it finds
//   in arbitrary order.  The input points is a list of points to search and tree is the
//   vantage point tree computed from that point list.  The search should be
//   around O(log n).  
// Arguments:
//   points = points indexed by the vantage point tree
//   tree = vantage point tree from vp_tree
//   p = point to search for
//   r = search radius
function _vp_search(points, tree, p, r) =
    is_list(tree[0]) ? [for(i=tree[0]) if (norm(points[i]-p)<=r) i]
    :
    let(
        d = norm(p-points[tree[0]])  // dist to vantage point
    )
    [
      if (d <= r) tree[0],
      if (d-r <= tree[1]) each _vp_search(points, tree[2], p, r),
      if (d+r > tree[1]) each _vp_search(points, tree[3], p, r)
    ];

function vp_search(points, tree, p, r) =
    assert(is_list(tree[1]) && (len(tree[1])==4 || (len(tree[1])==1 && is_list(tree[0]))), "Vantage point tree not valid")
    assert(is_matrix(points), "Parameter points is not a consistent point list")
    assert(is_vector(p,len(points[0])), "Query must be a vector whose length matches the point list")
    assert(all_positive(r),"Radius r must be a positive number")
    _vp_search(points, tree, p, r);
  

// Function: vp_nearest()
// Usage:
//    indices = vp_nearest(points, tree, p, k)
// Description:
//    Search the vantage point tree for the k points closest to point p.
//    The input points is the list of points to search and tree is
//    the vantage point tree computed from that point list.  The list is
//    returned in sorted order, closest point first.  
// Arguments:
//    points = points indexed by the vantage point tree
//    tree = vantage point tree from vp_tree
//    p = point to search for
//    k = number of neighbors to return
function _insert_sorted(list, k, new) =
      len(list)==k && new[1]>= last(list)[1] ? list
    : [
        for(entry=list) if (entry[1]<=new[1]) entry,
        new,
        for(i=[0:1:min(k-1,len(list))-1]) if (list[i][1]>new[1]) list[i]
      ];

function _insert_many(list, k, newlist,i=0) =
  i==len(newlist) ? list :
                    _insert_many(_insert_sorted(list,k,newlist[i]),k,newlist,i+1);

function _vp_nearest(points, tree, p, k, answers=[]) =
  is_list(tree[0]) ? _insert_many(answers, k, [for(entry=tree[0]) [entry, norm(points[entry]-p)]]) :
  let(
      d = norm(p-points[tree[0]]),
      answers1 = _insert_sorted(answers, k, [tree[0],d]),
      answers2 = d-last(answers1)[1] <= tree[1] ? _vp_nearest(points, tree[2], p, k, answers1) : answers1,
      answers3 = d+last(answers2)[1] > tree[1] ? _vp_nearest(points, tree[3], p, k, answers2) : answers2
   )
   answers3;

function vp_nearest(points, tree, p, k) =
      assert(is_int(k) && k>0)
      assert(k<=len(points), "You requested more results that contained in the set")
      assert(is_matrix(points), "Parameter points is not a consistent point list")
      assert(is_vector(p,len(points[0])), "Query must be a vector whose length matches the point list")
      assert(is_list(tree) && (len(tree)==4 || (len(tree)==1 && is_list(tree[0]))), "Vantage point tree not valid")
      subindex(_vp_nearest(points, tree, p, k),0);


// Function: search_radius()
// Usage:
//    index_list = search_radius(points, queries, r, <leafsize>);
// Description:
//    Given a list of points and a compatible list of queries, for each query
//    search the points list for all points whose distance from the query
//    is less than or equal to r.  The return value index_list[i] lists the indices
//    in points of all matches to query q[i].  This list can be in arbitrary order.  
//    .
//    This function is advantageous to use especially when both `points` and `queries`
//    are large sets.  The method contructs a vantage point tree and then uses it
//    to check all the queries.  If you use queries=points and set r to epsilon then
//    you can find all of the approximate duplicates in a large list of vectors.
// Example:  Finding duplicates in a list of vectors.  With exact equality the order of the output is consistent, but with small variations [2,4] could occur in one position and [4,2] in the other one.
    v = array_group(rands(0,10,5*3,seed=9),3);
    points = [v[0],v[1],v[2],v[3],v[2],v[3],v[3],v[4]];
    echo(search_radius(points,points,1e-9));   // Prints [[0],[1],[2,4],[3,5,6],[2,4],[3,5,6],[3,5,6],[7]]
//    
function search_radius(points, queries, r, leafsize=25) =
  assert(is_matrix(points),"Invalid points list")
  assert(is_matrix(queries),"Invalid query list")
  assert(len(points[0])==len(queries[0]), "Query vectors don't match length of points")
  let(
       vptree = vp_tree(points, leafsize)
  )
  [for(q=queries) vp_search(points, vptree, q, r)];


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
