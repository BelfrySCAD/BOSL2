//////////////////////////////////////////////////////////////////////
// LibFile: arrays.scad
//   List and Array manipulation functions.
// Includes:
//   include <BOSL2/std.scad>
//////////////////////////////////////////////////////////////////////


// Section: Terminology
//   - **List**: An ordered collection of zero or more items.  ie: `["a", "b", "c"]`
//   - **Vector**: A list of numbers. ie: `[4, 5, 6]`
//   - **Array**: A nested list of lists, or list of lists of lists, or deeper.  ie: `[[2,3], [4,5], [6,7]]`
//   - **Dimension**: The depth of nesting of lists in an array.  A List is 1D.  A list of lists is 2D.  etc.
//   - **Set**: A list of unique items.


// Section: List Query Operations


// Function: is_homogeneous()
// Usage:
//   bool = is_homogeneous(list,depth);
// Description:
//   Returns true when the list have elements of same type up to the depth `depth`.
//   Booleans and numbers are not distinguinshed as of distinct types. 
// Arguments:
//   list = the list to check
//   depth = the lowest level the check is done
// Example:
//   a = is_homogeneous([[1,["a"]], [2,["b"]]]);     // Returns true
//   b = is_homogeneous([[1,["a"]], [2,[true]]]);    // Returns false
//   c = is_homogeneous([[1,["a"]], [2,[true]]], 1); // Returns true
//   d = is_homogeneous([[1,["a"]], [2,[true]]], 2); // Returns false
//   e = is_homogeneous([[1,["a"]], [true,["b"]]]);  // Returns true
function is_homogeneous(l, depth=10) =
    !is_list(l) || l==[] ? false :
    let( l0=l[0] )
    [] == [for(i=[1:len(l)-1]) if( ! _same_type(l[i],l0, depth+1) )  0 ];
                 
function _same_type(a,b, depth) = 
    (depth==0) ||
    (is_undef(a) && is_undef(b)) ||
    (is_bool(a) && is_bool(b)) ||
    (is_num(a) && is_num(b)) ||
    (is_string(a) && is_string(b)) ||
    (is_list(a) && is_list(b) && len(a)==len(b) 
          && []==[for(i=idx(a)) if( ! _same_type(a[i],b[i],depth-1) ) 0] ); 
  

// Function: select()
// Description:
//   Returns a portion of a list, wrapping around past the beginning, if end<start. 
//   The first item is index 0. Negative indexes are counted back from the end.
//   The last item is -1.  If only the `start` index is given, returns just the value
//   at that position.
// Usage:
//   item = select(list,start);
//   list = select(list,start,end);
// Arguments:
//   list = The list to get the portion of.
//   start = The index of the first item.
//   end = The index of the last item.
// Example:
//   l = [3,4,5,6,7,8,9];
//   a = select(l, 5, 6);   // Returns [8,9]
//   b = select(l, 5, 8);   // Returns [8,9,3,4]
//   c = select(l, 5, 2);   // Returns [8,9,3,4,5]
//   d = select(l, -3, -1); // Returns [7,8,9]
//   e = select(l, 3, 3);   // Returns [6]
//   f = select(l, 4);      // Returns 7
//   g = select(l, -2);     // Returns 8
//   h = select(l, [1:3]);  // Returns [4,5,6]
//   i = select(l, [1,3]);  // Returns [4,6]
function select(list, start, end=undef) =
    assert( is_list(list) || is_string(list), "Invalid list.")
    let(l=len(list))
    l==0 ? []
    :   end==undef? 
            is_num(start)?
                list[ (start%l+l)%l ]
            :   assert( is_list(start) || is_range(start), "Invalid start parameter")
                [for (i=start) list[ (i%l+l)%l ] ]
        :   assert(is_finite(start), "Invalid start parameter.")
            assert(is_finite(end), "Invalid end parameter.")
            let( s = (start%l+l)%l, e = (end%l+l)%l )
            (s <= e)? [for (i = [s:1:e]) list[i]]
            :   concat([for (i = [s:1:l-1]) list[i]], [for (i = [0:1:e]) list[i]]) ;


// Function: last()
// Usage:
//   item = last(list);
// Description:
//   Returns the last element of a list, or undef if empty.
// Arguments:
//   list = The list to get the last element of.
// Example:
//   l = [3,4,5,6,7,8,9];
//   x = last(l);  // Returns 9.
function last(list) = list[len(list)-1];

// Function: delete_last()
// Usage:
//   list = delete_last(list);
// Description:
//   Returns a list of all but the last entry.  If input is empty, returns empty list.
// Usage:
//   delete_last(list)
function delete_last(list) =
   assert(is_list(list))
   list==[] ? [] : slice(list,0,-2);

// Function: slice()
// Usage:
//   list = slice(list,start,end);
// Description:
//   Returns a slice of a list.  The first item is index 0.
//   Negative indexes are counted back from the end.  The last item is -1.
// Arguments:
//   list = The array/list to get the slice of.
//   start = The index of the first item to return.
//   end = The index after the last item to return, unless negative, in which case the last item to return.
// Example:
//   a = slice([3,4,5,6,7,8,9], 3, 5);   // Returns [6,7]
//   b = slice([3,4,5,6,7,8,9], 2, -1);  // Returns [5,6,7,8,9]
//   c = slice([3,4,5,6,7,8,9], 1, 1);   // Returns []
//   d = slice([3,4,5,6,7,8,9], 6, -1);  // Returns [9]
//   e = slice([3,4,5,6,7,8,9], 2, -2);  // Returns [5,6,7,8]
function slice(list,start,end) =
    assert( is_list(list), "Invalid list" )
    assert( is_finite(start) && is_finite(end), "Invalid number(s)" )
    let( l = len(list) )
    l==0 ? []
    :   let(
            s = start<0? (l+start): start,
            e = end<0? (l+end+1): end
        ) [for (i=[s:1:e-1]) if (e>s) list[i]];


// Function: in_list()
// Usage:
//   bool = in_list(val,list, <idx>);
// Description:
//   Returns true if value `val` is in list `list`. When `val==NAN` the answer will be false for any list.
// Arguments:
//   val = The simple value to search for.
//   list = The list to search.
//   idx = If given, searches the given subindex for matches for `val`.
// Example:
//   a = in_list("bar", ["foo", "bar", "baz"]);  // Returns true.
//   b = in_list("bee", ["foo", "bar", "baz"]);  // Returns false.
//   c = in_list("bar", [[2,"foo"], [4,"bar"], [3,"baz"]], idx=1);  // Returns true.
function in_list(val,list,idx=undef) = 
    assert( is_list(list) && (is_undef(idx) || is_finite(idx)),
            "Invalid input." )
    let( s = search([val], list, num_returns_per_match=1, index_col_num=idx)[0] )
    s==[] || s==[[]] ? false
    : is_undef(idx) ? val==list[s] 
    : val==list[s][idx];


// Function: min_index()
// Usage:
//   idx = min_index(vals);
//   idxlist = min_index(vals,all=true);
// Description:
//   Returns the index of the first occurrence of the minimum value in the given list. 
//   If `all` is true then returns a list of all indices where the minimum value occurs.
// Arguments:
//   vals = vector of values
//   all = set to true to return indices of all occurences of the minimum.  Default: false
// Example:
//   a = min_index([5,3,9,6,2,7,8,2,1]); // Returns: 8
//   b = min_index([5,3,9,6,2,7,8,2,7],all=true); // Returns: [4,7]
function min_index(vals, all=false) =
    assert( is_vector(vals) && len(vals)>0 , "Invalid or empty list of numbers.")
    all ? search(min(vals),vals,0) : search(min(vals), vals)[0];


// Function: max_index()
// Usage:
//   idx = max_index(vals);
//   idxlist = max_index(vals,all=true);
// Description:
//   Returns the index of the first occurrence of the maximum value in the given list. 
//   If `all` is true then returns a list of all indices where the maximum value occurs.
// Arguments:
//   vals = vector of values
//   all = set to true to return indices of all occurences of the maximum.  Default: false
// Example:
//   max_index([5,3,9,6,2,7,8,9,1]); // Returns: 2
//   max_index([5,3,9,6,2,7,8,9,1],all=true); // Returns: [2,7]
function max_index(vals, all=false) =
    assert( is_vector(vals) && len(vals)>0 , "Invalid or empty list of numbers.")
    all ? search(max(vals),vals,0) : search(max(vals), vals)[0];


// Function: list_increasing()
// Usage:
//    bool = list_increasing(list);
// Description:
//   Returns true if the list is (non-strictly) increasing
// Example:
//   a = list_increasing([1,2,3,4]);  // Returns: true
//   b = list_increasing([1,3,2,4]);  // Returns: false
//   c = list_increasing([4,3,2,1]);  // Returns: false
function list_increasing(list) =
    assert(is_list(list)||is_string(list))
    len([for (p=pair(list)) if(p.x>p.y) true])==0;


// Function: list_decreasing()
// Usage:
//   bool = list_decreasing(list);
// Description:
//   Returns true if the list is (non-strictly) decreasing
// Example:
//   a = list_decreasing([1,2,3,4]);  // Returns: false
//   b = list_decreasing([4,2,3,1]);  // Returns: false
//   c = list_decreasing([4,3,2,1]);  // Returns: true
function list_decreasing(list) =
    assert(is_list(list)||is_string(list))
    len([for (p=pair(list)) if(p.x<p.y) true])==0;



// Section: Basic List Generation


// Function: repeat()
// Usage:
//   list = repeat(val, n);
// Description:
//   Generates a list or array of `n` copies of the given value `val`.
//   If the count `n` is given as a list of counts, then this creates a
//   multi-dimensional array, filled with `val`.
// Arguments:
//   val = The value to repeat to make the list or array.
//   n = The number of copies to make of `val`.
// Example:
//   a = repeat(1, 4);        // Returns [1,1,1,1]
//   b = repeat(8, [2,3]);    // Returns [[8,8,8], [8,8,8]]
//   c = repeat(0, [2,2,3]);  // Returns [[[0,0,0],[0,0,0]], [[0,0,0],[0,0,0]]]
//   d = repeat([1,2,3],3);   // Returns [[1,2,3], [1,2,3], [1,2,3]]
function repeat(val, n, i=0) =
    is_num(n)? [for(j=[1:1:n]) val] :
    assert( is_list(n), "Invalid count number.")
    (i>=len(n))? val :
    [for (j=[1:1:n[i]]) repeat(val, n, i+1)];

// Function: list_range()
// Usage:
//   list = list_range(n, <s>, <e>);
//   list = list_range(n, <s>, <step>);
//   list = list_range(e, <step>);
//   list = list_range(s, e, <step>);
// Description:
//   Returns a list, counting up from starting value `s`, by `step` increments,
//   until either `n` values are in the list, or it reaches the end value `e`.
//   If both `n` and `e` are given, returns `n` values evenly spread from `s`
//   to `e`, and `step` is ignored.
// Arguments:
//   n = Desired number of values in returned list, if given.
//   s = Starting value.  Default: 0
//   e = Ending value to stop at, if given.
//   step = Amount to increment each value.  Default: 1
// Example:
//   a = list_range(4);                  // Returns [0,1,2,3]
//   b = list_range(n=4, step=2);        // Returns [0,2,4,6]
//   c = list_range(n=4, s=3, step=3);   // Returns [3,6,9,12]
//   d = list_range(n=5, s=0, e=10);     // Returns [0, 2.5, 5, 7.5, 10]
//   e = list_range(e=3);                // Returns [0,1,2,3]
//   f = list_range(e=7, step=2);        // Returns [0,2,4,6]
//   g = list_range(s=3, e=5);           // Returns [3,4,5]
//   h = list_range(s=3, e=8, step=2);   // Returns [3,5,7]
//   i = list_range(s=4, e=8.3, step=2); // Returns [4,6,8]
//   j = list_range(n=4, s=[3,4], step=[2,3]);  // Returns [[3,4], [5,7], [7,10], [9,13]]
function list_range(n=undef, s=0, e=undef, step=undef) =
    assert( is_undef(n) || is_finite(n), "Parameter `n` must be a number.")
    assert( is_undef(n) || is_undef(e) || is_undef(step), "At most 2 of n, e, and step can be given.")
    let( step = (n!=undef && e!=undef)? (e-s)/(n-1) : default(step,1) )
    is_undef(e) ? 
        assert( is_consistent([s, step]), "Incompatible data.")
        [for (i=[0:1:n-1]) s+step*i ]
    :   assert( is_vector([s,step,e]), "Start `s`, step `step` and end `e` must be numbers.")
        [for (v=[s:step:e]) v] ;
    


// Section: List Manipulation

// Function: reverse()
// Usage:
//   rlist = reverse(list);
// Description:
//   Reverses a list/array or string.
// Arguments:
//   x = The list or string to reverse.
// Example:
//   reverse([3,4,5,6]);  // Returns [6,5,4,3]
function reverse(x) =
    assert(is_list(x)||is_string(x), str("Input to reverse must be a list or string. Got: ",x))
    let (elems = [ for (i = [len(x)-1 : -1 : 0]) x[i] ])
    is_string(x)? str_join(elems) : elems;


// Function: list_rotate()
// Usage:
//   rlist = list_rotate(list,<n>);
// Description:
//   Rotates the contents of a list by `n` positions left.
//   If `n` is negative, then the rotation is `abs(n)` positions to the right.
//   If `list` is a string, then a string is returned with the characters rotates within the string.
// Arguments:
//   list = The list to rotate.
//   n = The number of positions to rotate by.  If negative, rotated to the right.  Positive rotates to the left.  Default: 1
// Example:
//   l1 = list_rotate([1,2,3,4,5],-2); // Returns: [4,5,1,2,3]
//   l2 = list_rotate([1,2,3,4,5],-1); // Returns: [5,1,2,3,4]
//   l3 = list_rotate([1,2,3,4,5],0);  // Returns: [1,2,3,4,5]
//   l4 = list_rotate([1,2,3,4,5],1);  // Returns: [2,3,4,5,1]
//   l5 = list_rotate([1,2,3,4,5],2);  // Returns: [3,4,5,1,2]
//   l6 = list_rotate([1,2,3,4,5],3);  // Returns: [4,5,1,2,3]
//   l7 = list_rotate([1,2,3,4,5],4);  // Returns: [5,1,2,3,4]
//   l8 = list_rotate([1,2,3,4,5],5);  // Returns: [1,2,3,4,5]
//   l9 = list_rotate([1,2,3,4,5],6);  // Returns: [2,3,4,5,1]
function list_rotate(list,n=1) =
    assert(is_list(list)||is_string(list), "Invalid list or string.")
    assert(is_finite(n), "Invalid number")
    let (elems = select(list,n,n+len(list)-1))
    is_string(list)? str_join(elems) : elems;


// Function: deduplicate()
// Usage:
//   list = deduplicate(list,<close>,<eps>);
// Description:
//   Removes consecutive duplicate items in a list.
//   When `eps` is zero, the comparison between consecutive items is exact.
//   Otherwise, when all list items and subitems are numbers, the comparison is within the tolerance `eps`.
//   This is different from `unique()` in that the list is *not* sorted.
// Arguments:
//   list = The list to deduplicate.
//   closed = If true, drops trailing items if they match the first list item.
//   eps = The maximum tolerance between items.
// Examples:
//   a = deduplicate([8,3,4,4,4,8,2,3,3,8,8]);  // Returns: [8,3,4,8,2,3,8]
//   b = deduplicate(closed=true, [8,3,4,4,4,8,2,3,3,8,8]);  // Returns: [8,3,4,8,2,3]
//   c = deduplicate("Hello");  // Returns: "Helo"
//   d = deduplicate([[3,4],[7,2],[7,1.99],[1,4]],eps=0.1);  // Returns: [[3,4],[7,2],[1,4]]
//   e = deduplicate([[7,undef],[7,undef],[1,4],[1,4+1e-12]],eps=0);    // Returns: [[7,undef],[1,4],[1,4+1e-12]]
function deduplicate(list, closed=false, eps=EPSILON) =
    assert(is_list(list)||is_string(list))
    let(
        l = len(list),
        end = l-(closed?0:1)
    )
    is_string(list) ? str_join([for (i=[0:1:l-1]) if (i==end || list[i] != list[(i+1)%l]) list[i]]) :
    eps==0 ? [for (i=[0:1:l-1]) if (i==end || list[i] != list[(i+1)%l]) list[i]] :
    [for (i=[0:1:l-1]) if (i==end || !approx(list[i], list[(i+1)%l], eps)) list[i]];


// Function: deduplicate_indexed()
// Usage:
//   new_idxs = deduplicate_indexed(list, indices, <closed>, <eps>);
// Description:
//   Given a list, and indices into it, removes consecutive indices that
//   index to the same values in the list.
// Arguments:
//   list = The list that the indices index into.
//   indices = The list of indices to deduplicate.
//   closed = If true, drops trailing indices if what they index matches what the first index indexes.
//   eps = The maximum difference to allow between numbers or vectors.
// Examples:
//   a = deduplicate_indexed([8,6,4,6,3], [1,4,3,1,2,2,0,1]);  // Returns: [1,4,3,2,0,1]
//   b = deduplicate_indexed([8,6,4,6,3], [1,4,3,1,2,2,0,1], closed=true);  // Returns: [1,4,3,2,0]
//   c = deduplicate_indexed([[7,undef],[7,undef],[1,4],[1,4],[1,4+1e-12]],eps=0);    // Returns: [0,2,4]
function deduplicate_indexed(list, indices, closed=false, eps=EPSILON) =
    assert(is_list(list)||is_string(list), "Improper list or string.")
    indices==[]? [] :
    assert(is_vector(indices), "Indices must be a list of numbers.")
    let( l = len(indices),
         end = l-(closed?0:1) ) 
    [ for (i = [0:1:l-1]) 
        let(
           a = list[indices[i]],
           b = list[indices[(i+1)%l]],
           eq = (a == b)? true :
                (a*0 != b*0) || (eps==0)? false :
                is_num(a) || is_vector(a) ? approx(a, b, eps=eps) 
                : false
        ) 
        if (i==end || !eq) indices[i]
    ];


// Function: repeat_entries()
// Usage:
//   newlist = repeat_entries(list, N, <exact>);
// Description:
//   Takes a list as input and duplicates some of its entries to produce a list
//   with length `N`.  If the requested `N` is not a multiple of the list length then
//   the entries will be duplicated as uniformly as possible.  You can also set `N` to a vector,
//   in which case len(N) must equal len(list) and the output repeats the ith entry N[i] times.
//   In either case, the result will be a list of length `N`.  The `exact` option requires
//   that the final length is exactly as requested.  If you set it to `false` then the
//   algorithm will favor uniformity and the output list may have a different number of
//   entries due to rounding.
//   .
//   When applied to a path the output path is the same geometrical shape but has some vertices
//   repeated.  This can be useful when you need to align paths with a different number of points.
//   (See also subdivide_path for a different way to do that.) 
// Arguments:
//   list = list whose entries will be repeated
//   N = scalar total number of points desired or vector requesting N[i] copies of vertex i.  
//   exact = if true return exactly the requested number of points, possibly sacrificing uniformity.  If false, return uniform points that may not match the number of points requested.  Default: True
// Examples:
//   list = [0,1,2,3];
//   a = repeat_entries(list, 6);  // Returns: [0,0,1,2,2,3]
//   b = repeat_entries(list, 6, exact=false);  // Returns: [0,0,1,1,2,2,3,3]
//   c = repeat_entries(list, [1,1,2,1], exact=false);  // Returns: [0,1,2,2,3]
function repeat_entries(list, N, exact=true) =
    assert(is_list(list) && len(list)>0, "The list cannot be void.")
    assert((is_finite(N) && N>0) || is_vector(N,len(list)),
            "Parameter N must be a number greater than zero or vector with the same length of `list`")
    let(
        length = len(list),
        reps_guess = is_list(N)? N : repeat(N/length,length),
        reps = exact ?
                 _sum_preserving_round(reps_guess) 
               : [for (val=reps_guess) round(val)]
    )
    [for(i=[0:length-1]) each repeat(list[i],reps[i])];


// Function: list_set()
// Usage:
//   list = list_set(list, indices, values, <dflt>, <minlen>);
// Description:
//   Takes the input list and returns a new list such that `list[indices[i]] = values[i]` for all of
//   the (index,value) pairs supplied and unchanged for other indices.  If you supply `indices` that are 
//   beyond the length of the list then the list is extended and filled in with the `dflt` value.  
//   If you set `minlen` then the list is lengthed, if necessary, by padding with `dflt` to that length.  
//   Repetitions in `indices` are not allowed. The lists `indices` and `values` must have the same length.  
//   If `indices` is given as a scalar, then that index of the given `list` will be set to the scalar value of `values`.
// Arguments:
//   list = List to set items in.  Default: []
//   indices = List of indices into `list` to set.
//   values = List of values to set.
//   dflt = Default value to store in sparse skipped indices.
//   minlen = Minimum length to expand list to.
// Examples:
//   a = list_set([2,3,4,5], 2, 21);  // Returns: [2,3,21,5]
//   b = list_set([2,3,4,5], [1,3], [81,47]);  // Returns: [2,81,4,47]
function list_set(list=[],indices,values,dflt=0,minlen=0) = 
    assert(is_list(list))
    !is_list(indices)? (
        (is_finite(indices) && indices<len(list))? 
           concat([for (i=idx(list)) i==indices? values : list[i]], repeat(dflt, minlen-len(list)))
        :  list_set(list,[indices],[values],dflt) )
    :indices==[] && values==[] ?
        concat(list, repeat(dflt, minlen-len(list)))
    :assert(is_vector(indices) && is_list(values) && len(values)==len(indices) ,
               "Index list and value list must have the same length")
        let( midx = max(len(list)-1, max(indices)) )
        [ for(i=[0:midx] ) 
            let( j = search(i,indices,0),
                 k = j[0] )
            assert( len(j)<2, "Repeated indices are not allowed." )
            k!=undef ? values[k] :
            i<len(list) ? list[i]:
                dflt ,
          each repeat(dflt, minlen-max(len(list),max(indices)))
        ];


// Function: list_insert()
// Usage:
//   list = list_insert(list, indices, values);
// Description:
//   Insert `values` into `list` before position `indices`.
// Example:
//   a = list_insert([3,6,9,12],1,5);  // Returns [3,5,6,9,12]
//   b = list_insert([3,6,9,12],[1,3],[5,11]);  // Returns [3,5,6,9,11,12]
function list_insert(list, indices, values) = 
    assert(is_list(list))
    !is_list(indices)? 
        assert( is_finite(indices) && is_finite(values), "Invalid indices/values." ) 
        assert( indices<=len(list), "Indices must be <= len(list) ." )
        [
          for (i=idx(list)) each ( i==indices?  [ values, list[i] ] : [ list[i] ] ),
          if (indices==len(list)) values
        ]
    :   indices==[] && values==[] ? list
    :   assert( is_vector(indices) && is_list(values) && len(values)==len(indices) ,
               "Index list and value list must have the same length")
        assert( max(indices)<=len(list), "Indices must be <= len(list) ." )
        let( maxidx = max(indices),
             minidx  = min(indices) )
        [ for(i=[0:1:minidx-1] ) list[i],
          for(i=[minidx: min(maxidx, len(list)-1)] ) 
            let( j = search(i,indices,0),
                 k = j[0],
                 x = assert( len(j)<2, "Repeated indices are not allowed." )
              )
            each ( k != undef  ? [ values[k], list[i] ] : [ list[i] ] ),
          for(i=[min(maxidx, len(list)-1)+1:1:len(list)-1] ) list[i],
          if(maxidx==len(list)) values[max_index(indices)]
        ];


// Function: list_remove()
// Usage:
//   list = list_remove(list, indices);
// Description:
//   Remove all items from `list` whose indexes are in `indices`.
// Arguments:
//   list = The list to remove items from.
//   indices = The list of indexes of items to remove.
// Example:
//   a = list_insert([3,6,9,12],1);      // Returns: [3,9,12]
//   b = list_insert([3,6,9,12],[1,3]);  // Returns: [3,9]
function list_remove(list, indices) =
    assert(is_list(list))
    is_finite(indices) ?
        [
            for (i=[0:1:min(indices, len(list)-1)-1]) list[i],
            for (i=[min(indices, len(list)-1)+1:1:len(list)-1]) list[i]
        ]
    :   indices==[] ? list
    :   assert( is_vector(indices), "Invalid list `indices`." )
        [
            for(i=[0:len(list)-1])
            if ( []==search(i,indices,1) )
            list[i]
        ]; 


// Function: list_remove_values()
// Usage:
//   list = list_remove_values(list,values);
//   list = list_remove_values(list,values,all=true);
// Description:
//   Removes the first, or all instances of the given `values` from the `list`.
//   Returns the modified list.
// Arguments:
//   list = The list to modify.
//   values = The values to remove from the list.
//   all = If true, remove all instances of the value `value` from the list `list`.  If false, remove only the first.  Default: false
// Example:
//   animals = ["bat", "cat", "rat", "dog", "bat", "rat"];
//   animals2 = list_remove_values(animals, "rat");   // Returns: ["bat","cat","dog","bat","rat"]
//   nonflying = list_remove_values(animals, "bat", all=true);  // Returns: ["cat","rat","dog","rat"]
//   animals3 = list_remove_values(animals, ["bat","rat"]);  // Returns: ["cat","dog","bat","rat"]
//   domestic = list_remove_values(animals, ["bat","rat"], all=true);  // Returns: ["cat","dog"]
//   animals4 = list_remove_values(animals, ["tucan","rat"], all=true);  // Returns: ["bat","cat","dog","bat"]
function list_remove_values(list,values=[],all=false) =
    assert(is_list(list))
    !is_list(values)? list_remove_values(list, values=[values], all=all) :
    let(
        idxs = all? flatten(search(values,list,0)) : search(values,list,1),
        uidxs = unique(idxs)
    ) list_remove(list,uidxs);


// Function: bselect()
// Usage:
//   array = bselect(array,index);
// Description:
//   Returns the items in `array` whose matching element in `index` is true.
// Arguments:
//   array = Initial list to extract items from.
//   index = List of booleans.
// Example:
//   a = bselect([3,4,5,6,7], [false,true,true,false,true]);  // Returns: [4,5,7]
function bselect(array,index) =
    assert(is_list(array)||is_string(array), "Improper array." )
    assert(is_list(index) && len(index)>=len(array) , "Improper index list." )
    is_string(array)? str_join(bselect( [for (x=array) x], index)) :
    [for(i=[0:len(array)-1]) if (index[i]) array[i]];


// Function: list_bset()
// Usage:
//   arr = list_bset(indexset, valuelist, <dflt>);
// Description:
//   Opposite of `bselect()`.  Returns a list the same length as `indexlist`, where each item will
//   either be 0 if the corresponding item in `indexset` is false, or the next sequential value
//   from `valuelist` if the item is true.  The number of `true` values in `indexset` must be equal 
//   to the length of `valuelist`.
// Arguments:
//   indexset = A list of boolean values.
//   valuelist = The list of values to set into the returned list.
//   dflt = Default value to store when the indexset item is false.
// Example:
//   a = list_bset([false,true,false,true,false], [3,4]);  // Returns: [0,3,0,4,0]
//   b = list_bset([false,true,false,true,false], [3,4], dflt=1);  // Returns: [1,3,1,4,1]
function list_bset(indexset, valuelist, dflt=0) =
    assert(is_list(indexset), "The index set is not a list." )
    assert(is_list(valuelist), "The `valuelist` is not a list." )
    let( trueind = search([true], indexset,0)[0] )
    assert( !(len(trueind)>len(valuelist)), str("List `valuelist` too short; its length should be ",len(trueind)) )
    assert( !(len(trueind)<len(valuelist)), str("List `valuelist` too long; its length should be ",len(trueind)) )
    concat(
        list_set([],trueind, valuelist, dflt=dflt),    // Fill in all of the values
        repeat(dflt,len(indexset)-max(trueind)-1)  // Add trailing values so length matches indexset
    );


// Section: List Length Manipulation

// Function: list_shortest()
// Usage:
//   llen = list_shortest(array);
// Description:
//   Returns the length of the shortest sublist in a list of lists.
// Arguments:
//   array = A list of lists.
function list_shortest(array) =
    assert(is_list(array), "Invalid input." )
    min([for (v = array) len(v)]);


// Function: list_longest()
// Usage:
//   llen = list_longest(array);
// Description:
//   Returns the length of the longest sublist in a list of lists.
// Arguments:
//   array = A list of lists.
function list_longest(array) =
    assert(is_list(array), "Invalid input." )
    max([for (v = array) len(v)]);


// Function: list_pad()
// Usage:
//   arr = list_pad(array, minlen, <fill>);
// Description:
//   If the list `array` is shorter than `minlen` length, pad it to length with the value given in `fill`.
// Arguments:
//   array = A list.
//   minlen = The minimum length to pad the list to.
//   fill = The value to pad the list with.
function list_pad(array, minlen, fill=undef) =
    assert(is_list(array), "Invalid input." )
    concat(array,repeat(fill,minlen-len(array)));


// Function: list_trim()
// Usage:
//   arr = list_trim(array, maxlen);
// Description:
//   If the list `array` is longer than `maxlen` length, truncates it to be `maxlen` items long.
// Arguments:
//   array = A list.
//   minlen = The minimum length to pad the list to.
function list_trim(array, maxlen) =
    assert(is_list(array), "Invalid input." )
    [for (i=[0:1:min(len(array),maxlen)-1]) array[i]];


// Function: list_fit()
// Usage:
//   arr = list_fit(array, length, fill);
// Description:
//   If the list `array` is longer than `length` items long, truncates it to be exactly `length` items long.
//   If the list `array` is shorter than `length` items long, pad it to length with the value given in `fill`.
// Arguments:
//   array = A list.
//   minlen = The minimum length to pad the list to.
//   fill = The value to pad the list with.
function list_fit(array, length, fill) =
    assert(is_list(array), "Invalid input." )
    let(l=len(array)) 
    l==length ? array : 
    l> length ? list_trim(array,length) 
              : list_pad(array,length,fill);


// Section: List Shuffling and Sorting


// returns true for valid index specifications idx in the interval [imin, imax) 
// note that idx can't have any value greater or EQUAL to imax
// this allows imax=INF as a bound to numerical lists
function _valid_idx(idx,imin,imax) =
    is_undef(idx) 
    || ( is_finite(idx)  
         && ( is_undef(imin) || idx>=imin ) 
         && ( is_undef(imax) || idx< imax ) )
    || ( is_list(idx)  
         && ( is_undef(imin) || min(idx)>=imin ) 
         && ( is_undef(imax) || max(idx)< imax ) )
    || ( is_range(idx) 
         && ( is_undef(imin) || (idx[1]>0 && idx[0]>=imin ) || (idx[1]<0 && idx[0]<=imax ) )
         && ( is_undef(imax) || (idx[1]>0 && idx[2]<=imax ) || (idx[1]<0 && idx[2]>=imin ) ) );
    

// Function: shuffle()
// Usage:
//   shuffled = shuffle(list,<seed>)
// Description:
//   Shuffles the input list into random order.
//   If given a string, shuffles the characters within the string.
//   If you give a numeric seed value then the permutation
//   will be repeatable.
// Arguments:
//   list = The list to shuffle.
//   seed = Optional random number seed for the shuffling.
function shuffle(list,seed) =
    assert(is_list(list)||is_string(list), "Invalid input." )
    is_string(list)? str_join(shuffle([for (x = list) x],seed=seed)) :
    len(list)<=1 ? list :
    let (
        rval = is_num(seed) ? rands(0,1,len(list),seed_value=seed)
                            : rands(0,1,len(list)),
        left  = [for (i=[0:len(list)-1]) if (rval[i]< 0.5) list[i]],
        right = [for (i=[0:len(list)-1]) if (rval[i]>=0.5) list[i]]
    ) 
    concat(shuffle(left), shuffle(right));


// Sort a vector of scalar values with the native comparison operator
// all elements should have the same type.
function _sort_scalars(arr) =
    len(arr)<=1 ? arr : 
    let(
        pivot   = arr[floor(len(arr)/2)],
        lesser  = [ for (y = arr) if (y  < pivot) y ],
        equal   = [ for (y = arr) if (y == pivot) y ],
        greater = [ for (y = arr) if (y  > pivot) y ]
    ) 
    concat( _sort_scalars(lesser), equal, _sort_scalars(greater) );


// lexical sort of a homogeneous list of vectors 
// uses native comparison operator
function _sort_vectors(arr, _i=0) =
    len(arr)<=1 || _i>=len(arr[0]) ? arr :
    let(
        pivot   = arr[floor(len(arr)/2)][_i],
        lesser  = [ for (entry=arr) if (entry[_i]  < pivot ) entry ],
        equal   = [ for (entry=arr) if (entry[_i] == pivot ) entry ],
        greater = [ for (entry=arr) if (entry[_i]  > pivot ) entry ]
      )
    concat(
        _sort_vectors(lesser,  _i   ), 
        _sort_vectors(equal,   _i+1 ), 
        _sort_vectors(greater, _i ) );
        

// lexical sort of a homogeneous list of vectors by the vector components with indices in idxlist
// all idxlist indices should be in the range of the vector dimensions
// idxlist must be undef or a simple list of numbers
// uses native comparison operator
function _sort_vectors(arr, idxlist, _i=0) =
    len(arr)<=1 || ( is_list(idxlist) && _i>=len(idxlist) ) || _i>=len(arr[0])  ? arr :
    let(
        k = is_list(idxlist) ? idxlist[_i] : _i,
        pivot   = arr[floor(len(arr)/2)][k],
        lesser  = [ for (entry=arr) if (entry[k]  < pivot ) entry ],
        equal   = [ for (entry=arr) if (entry[k] == pivot ) entry ],
        greater = [ for (entry=arr) if (entry[k]  > pivot ) entry ]
      )
    concat(
        _sort_vectors(lesser,  idxlist, _i  ), 
        _sort_vectors(equal,   idxlist, _i+1), 
        _sort_vectors(greater, idxlist, _i  ) );
        

// sorting using compare_vals(); returns indexed list when `indexed==true`
function _sort_general(arr, idx=undef, indexed=false) =
    (len(arr)<=1) ? arr :
    ! indexed && is_undef(idx)
    ? _lexical_sort(arr)
    : let( arrind = _indexed_sort(enumerate(arr,idx)) )
      indexed 
      ? arrind
      : [for(i=arrind) arr[i]];
      
// lexical sort using compare_vals()
function _lexical_sort(arr) = 
    arr==[] ? [] : len(arr)==1? arr : 
    let( pivot = arr[floor(len(arr)/2)] )
    let(
        lesser  = [ for (entry=arr) if (compare_vals(entry, pivot) <0 ) entry ],
        equal   = [ for (entry=arr) if (compare_vals(entry, pivot)==0 ) entry ],
        greater = [ for (entry=arr) if (compare_vals(entry, pivot) >0 ) entry ]
      )
    concat(_lexical_sort(lesser), equal, _lexical_sort(greater));


// given a list of pairs, return the first element of each pair of the list sorted by the second element of the pair
// the sorting is done using compare_vals()
function _indexed_sort(arrind) = 
    arrind==[] ? [] : len(arrind)==1? [arrind[0][0]] : 
    let( pivot = arrind[floor(len(arrind)/2)][1] )
    let(
        lesser  = [ for (entry=arrind) if (compare_vals(entry[1], pivot) <0 ) entry ],
        equal   = [ for (entry=arrind) if (compare_vals(entry[1], pivot)==0 ) entry[0] ],
        greater = [ for (entry=arrind) if (compare_vals(entry[1], pivot) >0 ) entry ]
      )
    concat(_indexed_sort(lesser), equal, _indexed_sort(greater));


// Function: sort()
// Usage:
//   slist = sort(list, <idx>);
// Description:
//   Sorts the given list in lexicographic order. If the input is a homogeneous simple list or a homogeneous 
//   list of vectors (see function is_homogeneous), the sorting method uses the native comparison operator and is faster. 
//   When sorting non homogeneous list the elements are compared with `compare_vals`, with types ordered according to
//   `undef < boolean < number < string < list`.  Comparison of lists is recursive. 
//   When comparing vectors, homogeneous or not, the parameter `idx` may be used to select the components to compare.
//   Note that homogeneous lists of vectors may contain mixed types provided that for any two list elements
//   list[i] and list[j] satisfies  type(list[i][k])==type(list[j][k]) for all k. 
//   Strings are allowed as any list element and are compared with the native operators although no substring
//   comparison is possible.  
// Arguments:
//   list = The list to sort.
//   idx = If given, do the comparison based just on the specified index, range or list of indices.  
// Example: 
//   // Homogeneous lists
//   l1 = [45,2,16,37,8,3,9,23,89,12,34];
//   sorted1 = sort(l1);  // Returns [2,3,8,9,12,16,23,34,37,45,89]
//   l2 = [["oat",0], ["cat",1], ["bat",3], ["bat",2], ["fat",3]];
//   sorted2 = sort(l2); // Returns: [["bat",2],["bat",3],["cat",1],["fat",3],["oat",0]]
//   // Non-homegenous list
//   l3 = [[4,0],[7],[3,9],20,[4],[3,1],[8]];
//   sorted3 = sort(l3); // Returns: [20,[3,1],[3,9],[4],[4,0],[7],[8]]
function sort(list, idx=undef) = 
    assert(is_list(list)||is_string(list), "Invalid input." )
    is_string(list)? str_join(sort([for (x = list) x],idx)) :
    !is_list(list) || len(list)<=1 ? list :
    is_homogeneous(list,1)
    ?   let(size = array_dim(list[0]))
        size==0 ?         _sort_scalars(list)
        : len(size)!=1 ?  _sort_general(list,idx)  
        : is_undef(idx) ? _sort_vectors(list)
        : assert( _valid_idx(idx) , "Invalid indices.")
          _sort_vectors(list,[for(i=idx) i])        
    : _sort_general(list,idx);
        

// Function: sortidx()
// Usage:
//   idxlist = sort_idx(list, <idx>);
// Description:
//   Given a list, sort it as function `sort()`, and returns
//   a list of indexes into the original list in that sorted order.
//   If you iterate the returned list in order, and use the list items
//   to index into the original list, you will be iterating the original
//   values in sorted order.
// Arguments:
//   list = The list to sort.
//   idx = If given, do the comparison based just on the specified index, range or list of indices.  
// Example:
//   lst = ["d","b","e","c"];
//   idxs = sortidx(lst);  // Returns: [1,3,0,2]
//   ordered = select(lst, idxs);   // Returns: ["b", "c", "d", "e"]
// Example:
//   lst = [
//       ["foo", 88, [0,0,1], false],
//       ["bar", 90, [0,1,0], true],
//       ["baz", 89, [1,0,0], false],
//       ["qux", 23, [1,1,1], true]
//   ];
//   idxs1 = sortidx(lst, idx=1); // Returns: [3,0,2,1]
//   idxs2 = sortidx(lst, idx=0); // Returns: [1,2,0,3]
//   idxs3 = sortidx(lst, idx=[1,3]); // Returns: [3,0,2,1]
function sortidx(list, idx=undef) = 
    assert(is_list(list)||is_string(list), "Invalid input." )
    !is_list(list) || len(list)<=1 ? list :
    is_homogeneous(list,1)
    ?   let( 
            size = array_dim(list[0]),
            aug  = ! (size==0 || len(size)==1) ? 0 // for general sorting
                   : [for(i=[0:len(list)-1]) concat(i,list[i])], // for scalar or vector sorting
            lidx = size==0? [1] :                                // scalar sorting
                   len(size)==1 
                   ? is_undef(idx) ? [for(i=[0:len(list[0])-1]) i+1] // vector sorting
                                   : [for(i=idx) i+1]                // vector sorting
                   : 0   // just to signal
            )
        assert( ! ( size==0 && is_def(idx) ), 
                "The specification of `idx` is incompatible with scalar sorting." ) 
        assert( _valid_idx(idx) , "Invalid indices." ) 
        lidx!=0
        ?   let( lsort = _sort_vectors(aug,lidx) )
            [for(li=lsort) li[0] ]
        :   _sort_general(list,idx,indexed=true)
    : _sort_general(list,idx,indexed=true);
        

// Function: unique()
// Usage:
//   ulist = unique(list);
// Description:
//   Returns a sorted list with all repeated items removed.
// Arguments:
//   list = The list to uniquify.
function unique(list) =
    assert(is_list(list)||is_string(list), "Invalid input." )
    is_string(list)? str_join(unique([for (x = list) x])) :
    len(list)<=1? list : 
    let( sorted = sort(list))
    [   for (i=[0:1:len(sorted)-1])
            if (i==0 || (sorted[i] != sorted[i-1]))
                sorted[i]
    ];


// Function: unique_count()
// Usage:
//   counts = unique_count(list);
// Description:
//   Returns `[sorted,counts]` where `sorted` is a sorted list of the unique items in `list` and `counts` is a list such 
//   that `count[i]` gives the number of times that `sorted[i]` appears in `list`.  
// Arguments:
//   list = The list to analyze. 
function unique_count(list) =
    assert(is_list(list) || is_string(list), "Invalid input." )
    list == [] ? [[],[]] : 
    let( list=sort(list) )
    let( ind = [0, for(i=[1:1:len(list)-1]) if (list[i]!=list[i-1]) i] )
    [ select(list,ind), deltas( concat(ind,[len(list)]) ) ];


// Section: List Iteration Helpers

// Function: idx()
// Usage:
//   rng = idx(list, <step>, <end>, <start>);
//   for(i=idx(list, <step>, <end>, <start>)) ...
// Description:
//   Returns the range of indexes for the given list.
// Arguments:
//   list = The list to returns the index range of.
//   step = The step size to stride through the list.  Default: 1
//   end = The delta from the end of the list.  Default: -1
//   start = The starting index.  Default: 0
// Example(2D):
//   colors = ["red", "green", "blue"];
//   for (i=idx(colors)) right(20*i) color(colors[i]) circle(d=10);
function idx(list, step=1, end=-1,start=0) =
    assert(is_list(list)||is_string(list), "Invalid input." )
    [start : step : len(list)+end];


// Function: enumerate()
// Usage:
//   arr = enumerate(l, <idx>);
//   for (x = enumerate(l, <idx>)) ... // x[0] is the index number, x[1] is the item.
// Description:
//   Returns a list, with each item of the given list `l` numbered in a sublist.
//   Something like: `[[0,l[0]], [1,l[1]], [2,l[2]], ...]`
// Arguments:
//   l = List to enumerate.
//   idx = If given, enumerates just the given subindex items of `l`.
// Example:
//   enumerate(["a","b","c"]);  // Returns: [[0,"a"], [1,"b"], [2,"c"]]
//   enumerate([[88,"a"],[76,"b"],[21,"c"]], idx=1);  // Returns: [[0,"a"], [1,"b"], [2,"c"]]
//   enumerate([["cat","a",12],["dog","b",10],["log","c",14]], idx=[1:2]);  // Returns: [[0,"a",12], [1,"b",10], [2,"c",14]]
// Example(2D):
//   colors = ["red", "green", "blue"];
//   for (p=enumerate(colors)) right(20*p[0]) color(p[1]) circle(d=10);
function enumerate(l,idx=undef) =
    assert(is_list(l)||is_string(list), "Invalid input." )
    assert( _valid_idx(idx,0,len(l)), "Invalid index/indices." )
    (idx==undef)
    ?   [for (i=[0:1:len(l)-1]) [i,l[i]]]
    :   [for (i=[0:1:len(l)-1]) [ i, for (j=idx) l[i][j]] ];


// Function: force_list()
// Usage:
//   list = force_list(value, <n>, <fill>)
// Description:
//   Coerces non-list values into a list.  Makes it easy to treat a scalar input
//   consistently as a singleton list, as well as list inputs.
//   - If `value` is a list, then that list is returned verbatim.
//   - If `value` is not a list, and `fill` is not given, then a list of `n` copies of `value` will be returned.
//   - If `value` is not a list, and `fill` is given, then a list `n` items long will be returned where `value` will be the first item, and the rest will contain the value of `fill`.
// Arguments:
//   value = The value or list to coerce into a list.
//   n = The number of items in the coerced list.  Default: 1
//   fill = The value to pad the coerced list with, after the firt value.  Default: undef (pad with copies of `value`)
// Examples:
//   x = force_list([3,4,5]);  // Returns: [3,4,5]
//   y = force_list(5);  // Returns: [5]
//   z = force_list(7, n=3);  // Returns: [7,7,7]
//   w = force_list(4, n=3, fill=1);  // Returns: [4,1,1]
function force_list(value, n=1, fill) =
    is_list(value) ? value :
    is_undef(fill)? [for (i=[1:1:n]) value] : [value, for (i=[2:1:n]) fill];


// Function: pair()
// Usage:
//   p = pair(v);
//   for (p = pair(v)) ...  // p contains a list of two adjacent items.
// Description:
//   Takes a list, and returns a list of adjacent pairs from it.
// Example(2D): Note that the last point and first point do NOT get paired together.
//   for (p = pair(circle(d=20, $fn=12)))
//       move(p[0])
//           rot(from=BACK, to=p[1]-p[0])
//               trapezoid(w1=1, w2=0, h=norm(p[1]-p[0]), anchor=FRONT);
// Example:
//   l = ["A","B","C","D"];
//   echo([for (p=pair(l)) str(p.y,p.x)]);  // Outputs: ["BA", "CB", "DC"]
function pair(v) =
    assert(is_list(v)||is_string(v), "Invalid input." )
    [for (i=[0:1:len(v)-2]) [v[i],v[i+1]]];


// Function: pair_wrap()
// Usage:
//   p = pair_wrap(v);
//   for (p = pair_wrap(v)) ...
// Description:
//   Takes a list, and returns a list of adjacent pairs from it, wrapping around from the end to the start of the list.
// Example(2D): 
//   for (p = pair_wrap(circle(d=20, $fn=12)))
//       move(p[0])
//           rot(from=BACK, to=p[1]-p[0])
//               trapezoid(w1=1, w2=0, h=norm(p[1]-p[0]), anchor=FRONT);
// Example:
//   l = ["A","B","C","D"];
//   echo([for (p=pair_wrap(l)) str(p.y,p.x)]);  // Outputs: ["BA", "CB", "DC", "AD"]
function pair_wrap(v) =
    assert(is_list(v)||is_string(v), "Invalid input." )
    [for (i=[0:1:len(v)-1]) [v[i],v[(i+1)%len(v)]]];


// Function: triplet()
// Usage:
//   list = triplet(v);
//   for (t = triplet(v)) ...
// Description:
//   Takes a list, and returns a list of adjacent triplets from it.
// Example:
//   l = ["A","B","C","D","E"];
//   echo([for (p=triplet(l)) str(p.z,p.y,p.x)]);  // Outputs: ["CBA", "DCB", "EDC"]
function triplet(v) =
    assert(is_list(v)||is_string(v), "Invalid input." )
    [for (i=[0:1:len(v)-3]) [v[i],v[i+1],v[i+2]]];


// Function: triplet_wrap()
// Usage:
//   list = triplet_wrap(v);
//   for (t = triplet_wrap(v)) ...
// Description:
//   Takes a list, and returns a list of adjacent triplets from it, wrapping around from the end to the start of the list.
// Example:
//   l = ["A","B","C","D"];
//   echo([for (p=triplet_wrap(l)) str(p.z,p.y,p.x)]);  // Outputs: ["CBA", "DCB", "ADC", "BAD"]
function triplet_wrap(v) =
    assert(is_list(v)||is_string(v), "Invalid input." )
    [for (i=[0:1:len(v)-1]) [v[i],v[(i+1)%len(v)],v[(i+2)%len(v)]]];


// Function: permute()
// Usage:
//   list = permute(l, <n>);
//   for (p = permute(l, <n>)) ...
// Description:
//   Returns an ordered list of every unique permutation of `n` items out of the given list `l`.
//   For the list `[1,2,3,4]`, with `n=2`, this will return `[[1,2], [1,3], [1,4], [2,3], [2,4], [3,4]]`.
//   For the list `[1,2,3,4]`, with `n=3`, this will return `[[1,2,3], [1,2,4], [1,3,4], [2,3,4]]`.
// Arguments:
//   l = The list to provide permutations for.
//   n = The number of items in each permutation. Default: 2
// Example:
//   pairs = permute([3,4,5,6]);  // Returns: [[3,4],[3,5],[3,6],[4,5],[4,6],[5,6]]
//   triplets = permute([3,4,5,6],n=3);  // Returns: [[3,4,5],[3,4,6],[3,5,6],[4,5,6]]
// Example(2D):
//   for (p=permute(regular_ngon(n=7,d=100))) stroke(p);
function permute(l,n=2,_s=0) =
    assert(is_list(l), "Invalid list." )
    assert( is_finite(n) && n>=1 && n<=len(l), "Invalid number `n`." )
    n==1
      ? [for (i=[_s:1:len(l)-1]) [l[i]]] 
      : [for (i=[_s:1:len(l)-n], p=permute(l,n=n-1,_s=i+1)) concat([l[i]], p)];



// Section: Set Manipulation

// Function: set_union()
// Usage:
//   s = set_union(a, b, <get_indices>);
// Description:
//   Given two sets (lists with unique items), returns the set of unique items that are in either `a` or `b`.
//   If `get_indices` is true, a list of indices into the new union set are returned for each item in `b`,
//   in addition to returning the new union set.  In this case, a 2-item list is returned, `[INDICES, NEWSET]`,
//   where INDICES is the list of indices for items in `b`, and NEWSET is the new union set.
// Arguments:
//   a = One of the two sets to merge.
//   b = The other of the two sets to merge.
//   get_indices = If true, indices into the new union set are also returned for each item in `b`.  Returns `[INDICES, NEWSET]`.  Default: false
// Example:
//   set_a = [2,3,5,7,11];
//   set_b = [1,2,3,5,8];
//   set_u = set_union(set_a, set_b);
//   // set_u now equals [2,3,5,7,11,1,8]
//   set_v = set_union(set_a, set_b, get_indices=true);
//   // set_v now equals [[5,0,1,2,6], [2,3,5,7,11,1,8]]
function set_union(a, b, get_indices=false) =
    assert( is_list(a) && is_list(b), "Invalid sets." )
    let(
        found1 = search(b, a),
        found2 = search(b, b),
        c = [ for (i=idx(b))
                if (found1[i] == [] && found2[i] == i)
                    b[i] 
            ],
        nset = concat(a, c)
    ) 
    ! get_indices ? nset :
    let(
        la = len(a),
        found3 = search(b, c),
        idxs =  [ for (i=idx(b))
                    (found1[i] != [])? found1[i] : la + found3[i]
                ]
    ) [idxs, nset];


// Function: set_difference()
// Usage:
//   s = set_difference(a, b);
// Description:
//   Given two sets (lists with unique items), returns the set of items that are in `a`, but not `b`.
// Arguments:
//   a = The starting set.
//   b = The set of items to remove from set `a`.
// Example:
//   set_a = [2,3,5,7,11];
//   set_b = [1,2,3,5,8];
//   set_d = set_difference(set_a, set_b);
//   // set_d now equals [7,11]
function set_difference(a, b) =
    assert( is_list(a) && is_list(b), "Invalid sets." )
    let( found = search(a, b, num_returns_per_match=1) )
    [ for (i=idx(a)) if(found[i]==[]) a[i] ];


// Function: set_intersection()
// Usage:
//   s = set_intersection(a, b);
// Description:
//   Given two sets (lists with unique items), returns the set of items that are in both sets.
// Arguments:
//   a = The starting set.
//   b = The set of items to intersect with set `a`.
// Example:
//   set_a = [2,3,5,7,11];
//   set_b = [1,2,3,5,8];
//   set_i = set_intersection(set_a, set_b);
//   // set_i now equals [2,3,5]
function set_intersection(a, b) =
    assert( is_list(a) && is_list(b), "Invalid sets." )
    let( found = search(a, b, num_returns_per_match=1) )
    [ for (i=idx(a)) if(found[i]!=[]) a[i] ];



// Section: Array Manipulation

// Function: add_scalar()
// Usage:  
//   v = add_scalar(v,s);
// Description:
//   Given a list and a scalar, returns the list with the scalar added to each item in it.
//   If given a list of arrays, recursively adds the scalar to the each array.
// Arguments:
//   v = The initial array.
//   s = A scalar value to add to every item in the array.
// Example:
//   a = add_scalar([1,2,3],3);            // Returns: [4,5,6]
//   b = add_scalar([[1,2,3],[3,4,5]],3);  // Returns: [[4,5,6],[6,7,8]]
function add_scalar(v,s) = 
    is_finite(s) ? [for (x=v) is_list(x)? add_scalar(x,s) : is_finite(x) ? x+s: x] : v;


// Function: subindex()
// Usage:
//   list = subindex(M, idx);
// Description:
//   Extracts the entries listed in idx from each entry in M.  For a matrix this means
//   selecting a specified set of columns.  If idx is a number the return is a vector, 
//   otherwise it is a list of lists (the submatrix).  
//   This function will return `undef` at all entry positions indexed by idx not found in the input list M.
// Arguments:
//   M = The given list of lists.
//   idx = The index, list of indices, or range of indices to fetch.
// Example:
//   M = [[1,2,3,4],[5,6,7,8],[9,10,11,12],[13,14,15,16]];
//   a = subindex(M,2);      // Returns [3, 7, 11, 15]
//   b = subindex(M,[2]);    // Returns [[3], [7], [11], [15]]
//   c = subindex(M,[2,1]);  // Returns [[3, 2], [7, 6], [11, 10], [15, 14]]
//   d = subindex(M,[1:3]);  // Returns [[2, 3, 4], [6, 7, 8], [10, 11, 12], [14, 15, 16]]
//   N = [ [1,2], [3], [4,5], [6,7,8] ];
//   e = subindex(N,[0,1]);  // Returns [ [1,2], [3,undef], [4,5], [6,7] ]
function subindex(M, idx) =
    assert( is_list(M), "The input is not a list." )
    assert( !is_undef(idx) && _valid_idx(idx,0,1/0), "Invalid index input." ) 
    is_finite(idx)
      ? [for(row=M) row[idx]]
      : [for(row=M) [for(i=idx) row[i]]];


// Function: submatrix()
// Usage:
//   mat = submatrix(M, idx1, idx2);
// Description:
//   The input must be a list of lists (a matrix or 2d array).  Returns a submatrix by selecting the rows listed in idx1 and columns listed in idx2.
// Arguments:
//   M = Given list of lists
//   idx1 = rows index list or range
//   idx2 = column index list or range
// Example:
//   M = [[ 1, 2, 3, 4, 5],
//        [ 6, 7, 8, 9,10],
//        [11,12,13,14,15],
//        [16,17,18,19,20],
//        [21,22,23,24,25]];
//   submatrix(M,[1:2],[3:4]);  // Returns [[9, 10], [14, 15]]
//   submatrix(M,[1], [3,4]));  // Returns [[9,10]]
//   submatrix(M,1, [3,4]));  // Returns [[9,10]]
//   submatrix(M,1,3));  // Returns [[9]]
//   submatrix(M, [3,4],1); // Returns  [[17],[22]]);
//   submatrix(M, [1,3],[2,4]); // Returns [[8,10],[18,20]]);
//   A = [[true,    17, "test"],
//        [[4,2],   91, false],
//        [6,    [3,4], undef]];
//   submatrix(A,[0,2],[1,2]);   // Returns [[17, "test"], [[3, 4], undef]]

function submatrix(M,idx1,idx2) =
    [for(i=idx1) [for(j=idx2) M[i][j] ] ];


// Function: zip()
// Usage: Zipping Two Lists
//   pairs = zip(v1, v2, <fit>, <fill>);
//   for (p = zip(v1, v2, <fit>, <fill>) ...
// Usage: Zipping Three Lists
//   triplets = zip(v1, v2, v3, <*fit*>, <*fill*>);
//   for (t = zip(v1, v2, v3, <*fit*>, <*fill*>)) ...
// Usage: Zipping N Lists
//   zips = zip(LISTS, <*fit*>, <*fill*>);
//   for (z = zip(LISTS, <*fit*>, <*fill*>)) ...
// Description:
//   Zips together corresponding items from two or more lists. Returns a list of lists,
//   where each sublist contains corresponding items from each of the input lists.
//   ie: For three lists, `[[A0, B0, C0], [A1, B1, C1], [A2, B2, C2], ...]`
// Arguments:
//   v1 = The first list if given with `v1`/`v2`.  A list of two or more lists to zipper, without `v1`/`v2`.
//   v2 = A second list.
//   v2 = A third list.
//   ---
//   fit = If `fit=="short"`, the zips together up to the length of the shortest list in vecs.  If `fit=="long"`, then pads all lists to the length of the longest, using the value in `fill`.  If `fit==false`, then requires all lists to be the same length.  Default: false.
//   fill = The default value to fill in with if one or more lists if short.  Default: undef
// Example:
//   v1 = [1,2,3,4];
//   v2 = [5,6,7];
//   v3 = [8,9,10,11];
//   a = zip(v1,v3);                       // returns [[1,8], [2,9], [3,10], [4,11]]
//   b = zip([v1,v3]);                     // returns [[1,8], [2,9], [3,10], [4,11]]
//   c = zip([v1,v2], fit="short");        // returns [[1,5], [2,6], [3,7]]
//   d = zip([v1,v2], fit="long");         // returns [[1,5], [2,6], [3,7], [4,undef]]
//   e = zip([v1,v2], fit="long, fill=0);  // returns [[1,5], [2,6], [3,7], [4,0]]
//   f = zip(v1,v2,v3, fit="long");        // returns [[1,5,8], [2,6,9], [3,7,10], [4,undef,11]]
//   g = zip([v1,v2,v3], fit="long");      // returns [[1,5,8], [2,6,9], [3,7,10], [4,undef,11]]
// Example:
//   v1 = [[1,2,3], [4,5,6], [7,8,9]];
//   v2 = [[20,19,18], [17,16,15], [14,13,12]];
//   zip(v1,v2);    // Returns [[1,2,3,20,19,18], [4,5,6,17,16,15], [7,8,9,14,13,12]]
function zip(v1, v2, v3, fit=false, fill=undef) =
    (v3!=undef)? zip([v1,v2,v3], fit=fit, fill=fill) :
    (v2!=undef)? zip([v1,v2], fit=fit, fill=fill) :
    assert(in_list(fit, [false, "short", "long"]), "Invalid fit value." )
    assert(all([for(v=v1) is_list(v)]), "One of the inputs to zip is not a list")
    let(
        minlen = list_shortest(v1),
        maxlen = list_longest(v1)
    )
    assert(fit!=false || minlen==maxlen, "Input vectors to zip must have the same length")
    fit == "long"
      ? [for(i=[0:1:maxlen-1]) [for(v=v1) for(x=(i<len(v)? v[i] : (fill==undef)? [fill] : fill)) x] ] 
      : [for(i=[0:1:minlen-1]) [for(v=v1) for(x=v[i]) x] ];


// Function: block_matrix()
// Usage:
//    bmat = block_matrix([[M11, M12,...],[M21, M22,...], ... ]);
// Description:
//    Create a block matrix by supplying a matrix of matrices, which will
//    be combined into one unified matrix.  Every matrix in one row
//    must have the same height, and the combined width of the matrices
//    in each row must be equal.  
function block_matrix(M) =
    let(
        bigM = [for(bigrow = M) each zip(bigrow)],
        len0=len(bigM[0]),
        badrows = [for(row=bigM) if (len(row)!=len0) 1]
    )
    assert(badrows==[], "Inconsistent or invalid input")
    bigM;


// Function: diagonal_matrix()
// Usage:
//   mat = diagonal_matrix(diag, <offdiag>);
// Description:
//   Creates a square matrix with the items in the list `diag` on
//   its diagonal.  The off diagonal entries are set to offdiag,
//   which is zero by default. 
// Arguments:
//   diag = A list of items to put in the diagnal cells of the matrix.
//   offdiag = Value to put in non-diagonal matrix cells.
function diagonal_matrix(diag, offdiag=0) =
  assert(is_list(diag) && len(diag)>0)
  [for(i=[0:1:len(diag)-1]) [for(j=[0:len(diag)-1]) i==j?diag[i] : offdiag]];


// Function: submatrix_set()
// Usage:
//   mat = submatrix_set(M,A,<m>,<n>);
// Description:
//   Sets a submatrix of M equal to the matrix A.  By default the top left corner of M is set to A, but
//   you can specify offset coordinates m and n.  If A (as adjusted by m and n) extends beyond the bounds
//   of M then the extra entries are ignored.  You can pass in A=[[]], a null matrix, and M will be
//   returned unchanged.  Note that the input M need not be rectangular in shape.  
// Arguments:
//   M = Original matrix.
//   A = Sub-matrix of parts to set.
//   m = Row number of upper-left corner to place A at.
//   n = Column number of upper-left corner to place A at.
function submatrix_set(M,A,m=0,n=0) =
    assert(is_list(M))
    assert(is_list(A))
    assert(is_int(m))
    assert(is_int(n))
    let( badrows = [for(i=idx(A)) if (!is_list(A[i])) i])
    assert(badrows==[], str("Input submatrix malformed rows: ",badrows))
    [for(i=[0:1:len(M)-1])
        assert(is_list(M[i]), str("Row ",i," of input matrix is not a list"))
        [for(j=[0:1:len(M[i])-1]) 
            i>=m && i <len(A)+m && j>=n && j<len(A[0])+n ? A[i-m][j-n] : M[i][j]]];


// Function: array_group()
// Usage:
//   groups = array_group(v, <cnt>, <dflt>);
// Description:
//   Takes a flat array of values, and groups items in sets of `cnt` length.
//   The opposite of this is `flatten()`.
// Arguments:
//   v = The list of items to group.
//   cnt = The number of items to put in each grouping.  Default:2
//   dflt = The default value to fill in with is the list is not a multiple of `cnt` items long.  Default: 0
// Example:
//   v = [1,2,3,4,5,6];
//   a = array_group(v,2) returns [[1,2], [3,4], [5,6]]
//   b = array_group(v,3) returns [[1,2,3], [4,5,6]]
//   c = array_group(v,4,0) returns [[1,2,3,4], [5,6,0,0]]
function array_group(v, cnt=2, dflt=0) =
    [for (i = [0:cnt:len(v)-1]) [for (j = [0:1:cnt-1]) default(v[i+j], dflt)]];


// Function: flatten()
// Usage:
//   list = flatten(l);
// Description:
//   Takes a list of lists and flattens it by one level.
// Arguments:
//   l = List to flatten.
// Example:
//   l = flatten([[1,2,3], [4,5,[6,7,8]]]);  // returns [1,2,3,4,5,[6,7,8]]
function flatten(l) = [for (a = l) each a];


// Function: full_flatten()
// Usage:
//   list = full_flatten(l);
// Description: 
//   Collects in a list all elements recursively found in any level of the given list.
//   The output list is ordered in depth first order.
// Arguments:
//   l = List to flatten.
// Example:
//   l = full_flatten([[1,2,3], [4,5,[6,7,8]]]);  // returns [1,2,3,4,5,6,7,8]
function full_flatten(l) = [for(a=l) if(is_list(a)) (each full_flatten(a)) else a ];


// Internal.  Not exposed.
function _array_dim_recurse(v) =
    !is_list(v[0])
    ?   len( [for(entry=v) if(!is_list(entry)) 0] ) == 0 ? [] : [undef]
    :   let(
          firstlen = is_list(v[0]) ? len(v[0]): undef,
          first = len( [for(entry = v) if(! is_list(entry) || (len(entry) != firstlen)) 0  ]   ) == 0 ? firstlen : undef,
          leveldown = flatten(v)
        ) 
        is_list(leveldown[0])
        ?  concat([first],_array_dim_recurse(leveldown))
        : [first];

function _array_dim_recurse(v) =
    let( alen = [for(vi=v) is_list(vi) ? len(vi): -1] )
    v==[] || max(alen)==-1 ? [] :
    let( add = max(alen)!=min(alen) ? undef : alen[0] ) 
    concat( add, _array_dim_recurse(flatten(v)));


// Function: array_dim()
// Usage:
//   dims = array_dim(v, <depth>);
// Description:
//   Returns the size of a multi-dimensional array.  Returns a list of
//   dimension lengths.  The length of `v` is the dimension `0`.  The
//   length of the items in `v` is dimension `1`.  The length of the
//   items in the items in `v` is dimension `2`, etc.  For each dimension,
//   if the length of items at that depth is inconsistent, `undef` will
//   be returned.  If no items of that dimension depth exist, `0` is
//   returned.  Otherwise, the consistent length of items in that
//   dimensional depth is returned.
// Arguments:
//   v = Array to get dimensions of.
//   depth = Dimension to get size of.  If not given, returns a list of dimension lengths.
// Examples:
//   a = array_dim([[[1,2,3],[4,5,6]],[[7,8,9],[10,11,12]]]);     // Returns [2,2,3]
//   b = array_dim([[[1,2,3],[4,5,6]],[[7,8,9],[10,11,12]]], 0);  // Returns 2
//   c = array_dim([[[1,2,3],[4,5,6]],[[7,8,9],[10,11,12]]], 2);  // Returns 3
//   d = array_dim([[[1,2,3],[4,5,6]],[[7,8,9]]]);                // Returns [2,undef,3]
function array_dim(v, depth=undef) =
    assert( is_undef(depth) || ( is_finite(depth) && depth>=0 ), "Invalid depth.")
    ! is_list(v) ? 0 :
    (depth == undef)
    ?   concat([len(v)], _array_dim_recurse(v))
    :   (depth == 0)
        ?  len(v)
        :  let( dimlist = _array_dim_recurse(v))
           (depth > len(dimlist))? 0 : dimlist[depth-1] ;
           
           


// Function: transpose()
// Usage:
//    arr = transpose(arr, <reverse>);
// Description:
//    Returns the transpose of the given input array.  The input should be a list of lists that are
//    all the same length.  If you give a vector then transpose returns it unchanged.  
//    When reverse=true, the transpose is done across to the secondary diagonal.  (See example below.)
//    By default, reverse=false.
// Example:
//   arr = [
//       ["a", "b", "c"],
//       ["d", "e", "f"],
//       ["g", "h", "i"]
//   ];
//   t = transpose(arr);
//   // Returns:
//   // [
//   //     ["a", "d", "g"],
//   //     ["b", "e", "h"],
//   //     ["c", "f", "i"],
//   // ]
// Example:
//   arr = [
//       ["a", "b", "c"],
//       ["d", "e", "f"]
//   ];
//   t = transpose(arr);
//   // Returns:
//   // [
//   //     ["a", "d"],
//   //     ["b", "e"],
//   //     ["c", "f"],
//   // ]
// Example:
//   arr = [
//       ["a", "b", "c"],
//       ["d", "e", "f"],
//       ["g", "h", "i"]
//   ];
//   t = transpose(arr, reverse=true);
//   // Returns:
//   // [
//   //  ["i", "f", "c"],
//   //  ["h", "e", "b"],
//   //  ["g", "d", "a"]
//   // ]
// Example: Transpose on a list of numbers returns the list unchanged
//   transpose([3,4,5]);  // Returns: [3,4,5]
function transpose(arr, reverse=false) =
    assert( is_list(arr) && len(arr)>0, "Input to transpose must be a nonempty list.")
    is_list(arr[0])
    ?   let( len0 = len(arr[0]) )
        assert([for(a=arr) if(!is_list(a) || len(a)!=len0) 1 ]==[], "Input to transpose has inconsistent row lengths." )
        reverse
        ? [for (i=[0:1:len0-1]) 
              [ for (j=[0:1:len(arr)-1]) arr[len(arr)-1-j][len0-1-i] ] ] 
        : [for (i=[0:1:len0-1]) 
              [ for (j=[0:1:len(arr)-1]) arr[j][i] ] ] 
    :  assert( is_vector(arr), "Input to transpose must be a vector or list of lists.")
           arr;


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
