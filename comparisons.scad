//////////////////////////////////////////////////////////////////////
// LibFile: comparisons.scad
//   Functions for comparisons with lists, ordering and sorting
// Includes:
//   include <BOSL2/std.scad>
// FileGroup: Data Management
// FileSummary: Comparisons and sorting.
// FileFootnotes: STD=Included in std.scad
//////////////////////////////////////////////////////////////////////


// Section: List comparison operations

// Function: approx()
// Synopsis: Returns true if two values are equal to within a small epsilon value.
// Topics: Comparisons
// See Also: all_zero(), all_nonzero()
// Usage:
//   test = approx(a, b, [eps])
// Description:
//   Compares two numbers, vectors, or matrices.  Returns true if they are closer than `eps` to each other.
//   Results are undefined if `a` and `b` are of different types, or if vectors or matrices contain non-numbers.
// Arguments:
//   a = First value.
//   b = Second value.
//   eps = The maximum allowed difference between `a` and `b` to consider as "no difference". Default: 1e-9.
// Example:
//   test1 = approx(-0.3333333333,-1/3);  // Returns: true
//   test2 = approx(0.3333333333,1/3);    // Returns: true
//   test3 = approx(0.3333,1/3);          // Returns: false
//   test4 = approx(0.3333,1/3,eps=1e-3); // Returns: true
//   test5 = approx(PI,3.1415926536);     // Returns: true
//   test6 = approx([0,0,sin(45)],[0,0,sqrt(2)/2]);  // Returns: true
function approx(a,b,eps=EPSILON) = 
    a == b? is_bool(a) == is_bool(b) :
    is_num(a) && is_num(b)? abs(a-b) <= eps :
    is_list(a) && is_list(b) && len(a) == len(b)? (
        [] == [
            for (i=idx(a))
            let(aa=a[i], bb=b[i])
            if(
                is_num(aa) && is_num(bb)? abs(aa-bb) > eps :
                !approx(aa,bb,eps=eps)
            ) 1
        ]
    ) : false;


// Function: all_zero()
// Synopsis: Returns true if the value(s) given are approximately zero.
// Topics: Comparisons, List Handling
// See Also: approx(), all_zero(), all_nonzero()
// Usage:
//   x = all_zero(x, [eps]);
// Description:
//   Returns true if its argument is approximately zero, to within `eps`.
//   If passed a list returns true if all its entries are approximately equal to zero. 
//   Otherwise, returns false.
// Arguments:
//   x = The value to check.
//   eps = The maximum allowed variance.  Default: `EPSILON` (1e-9)
// Example:
//   a = all_zero(0);  // Returns: true.
//   b = all_zero(1e-3);  // Returns: false.
//   c = all_zero([0,0,0]);  // Returns: true.
//   d = all_zero([0,0,1e-3]);  // Returns: false.
function all_zero(x, eps=EPSILON) =
    is_finite(x)? abs(x)<eps :
    is_vector(x) && [for (xx=x) if(abs(xx)>eps) 1] == [];


// Function: all_nonzero()
// Synopsis: Returns true if the value(s) given are not approximately zero.
// Topics: Comparisons, List Handling
// See Also: approx(), all_zero(), all_nonzero()
// Usage:
//   test = all_nonzero(x, [eps]);
// Description:
//   Returns true if its argument is finite and different from zero by `eps`.
//   If passed a list returns true if all the entries of the list are finite numbers that are different from zero by `eps`.  
//   Otherwise, returns false.
// Arguments:
//   x = The value to check.
//   eps = The maximum allowed variance.  Default: `EPSILON` (1e-9)
// Example:
//   a = all_nonzero(0);  // Returns: false.
//   b = all_nonzero(1e-3);  // Returns: true.
//   c = all_nonzero([0,0,0]);  // Returns: false.
//   d = all_nonzero([0,0,1e-3]);  // Returns: false.
//   e = all_nonzero([1e-3,1e-3,1e-3]);  // Returns: true.
function all_nonzero(x, eps=EPSILON) =
    is_finite(x)? abs(x)>eps :
    is_vector(x) && [for (xx=x) if(abs(xx)<eps) 1] == [];


// Function: all_positive()
// Synopsis: Returns true if the value(s) given are greater than zero.
// Topics: Comparisons, List Handling
// See Also: approx(), all_zero(), all_nonzero(), all_negative(), all_nonpositive(), all_nonnegative()
// Usage:
//   test = all_positive(x,[eps]);
// Description:
//   Returns true if the argument is finite and greater than zero, within epsilon tolerance if desired.
//   If passed a list returns true if all the entries are finite positive numbers.
//   Otherwise, returns false.
// Arguments:
//   x = The value to check.
//   eps = Tolerance. Default: 0
// Example:
//   a = all_positive(-2);  // Returns: false.
//   b = all_positive(0);  // Returns: false.
//   c = all_positive(2);  // Returns: true.
//   d = all_positive([0,0,0]);  // Returns: false.
//   e = all_positive([0,1,2]);  // Returns: false.
//   f = all_positive([3,1,2]);  // Returns: true.
//   g = all_positive([3,-1,2]);  // Returns: false.
function all_positive(x,eps=0) =
    is_finite(x)? x>eps :
    is_vector(x) && [for (xx=x) if(xx<=0) 1] == [];


// Function: all_negative()
// Synopsis: Returns true if the value(s) given are less than zero.
// Topics: Comparisons, List Handling
// See Also: approx(), all_zero(), all_nonzero(), all_positive(), all_nonpositive(), all_nonnegative()
// Usage:
//   test = all_negative(x, [eps]);
// Description:
//   Returns true if the argument is finite and less than zero, within epsilon tolerance if desired.
//   If passed a list, returns true if all the elements are finite negative numbers. 
//   Otherwise, returns false.
// Arguments:
//   x = The value to check.
//   eps = tolerance.  Default: 0
// Example:
//   a = all_negative(-2);  // Returns: true.
//   b = all_negative(0);  // Returns: false.
//   c = all_negative(2);  // Returns: false.
//   d = all_negative([0,0,0]);  // Returns: false.
//   e = all_negative([0,1,2]);  // Returns: false.
//   f = all_negative([3,1,2]);  // Returns: false.
//   g = all_negative([3,-1,2]);  // Returns: false.
//   h = all_negative([-3,-1,-2]);  // Returns: true.
function all_negative(x, eps=0) =
    is_finite(x)? x<-eps :
    is_vector(x) && [for (xx=x) if(xx>=-eps) 1] == [];


// Function: all_nonpositive()
// Synopsis: Returns true if the value(s) given are less than or equal to zero.
// Topics: Comparisons, List Handling
// See Also: approx(), all_zero(), all_nonzero(), all_positive(), all_negative(), all_nonpositive(), all_nonnegative()
// Usage:
//   all_nonpositive(x, [eps]);
// Description:
//   Returns true if its argument is finite and less than or equal to zero.
//   If passed a list, returns true if all the elements are finite non-positive numbers.
//   Otherwise, returns false. 
// Arguments:
//   x = The value to check.
//   eps = tolerance.  Default: 0
// Example:
//   a = all_nonpositive(-2);  // Returns: true.
//   b = all_nonpositive(0);  // Returns: true.
//   c = all_nonpositive(2);  // Returns: false.
//   d = all_nonpositive([0,0,0]);  // Returns: true.
//   e = all_nonpositive([0,1,2]);  // Returns: false.
//   f = all_nonpositive([3,1,2]);  // Returns: false.
//   g = all_nonpositive([3,-1,2]);  // Returns: false.
//   h = all_nonpositive([-3,-1,-2]);  // Returns: true.
function all_nonpositive(x,eps=0) =
    is_num(x)? x<=eps :
    is_vector(x) && [for (xx=x) if(xx>eps) 1] == []; 


// Function: all_nonnegative()
// Synopsis: Returns true if the value(s) given are greater than or equal to zero.
// Topics: Comparisons, List Handling
// See Also: approx(), all_zero(), all_nonzero(), all_positive(), all_negative(), all_nonpositive(), all_nonnegative()
// Usage:
//   all_nonnegative(x, [eps]);
// Description:
//   Returns true if the finite number passed to it is greater than or equal to zero.
//   If passed a list, returns true if all the elements are finite non-negative numbers. 
//   Otherwise, returns false.
// Arguments:
//   x = The value to check.
//   eps = tolerance.  Default: 0
// Example:
//   a = all_nonnegative(-2);  // Returns: false.
//   b = all_nonnegative(0);  // Returns: true.
//   c = all_nonnegative(2);  // Returns: true.
//   d = all_nonnegative([0,0,0]);  // Returns: true.
//   e = all_nonnegative([0,1,2]);  // Returns: true.
//   f = all_nonnegative([0,-1,-2]);  // Returns: false.
//   g = all_nonnegative([3,1,2]);  // Returns: true.
//   h = all_nonnegative([3,-1,2]);  // Returns: false.
//   i = all_nonnegative([-3,-1,-2]);  // Returns: false.
function all_nonnegative(x,eps=0) =
    is_num(x)? x>=-eps :
    is_vector(x) && [for (xx=x) if(xx<-eps) 1] == [];


// Function: all_equal()
// Synopsis: Returns true if all items in a list are approximately equal to each other.
// Topics: Comparisons, List Handling
// See Also: approx(), all_zero(), all_nonzero(), all_positive(), all_negative(), all_nonpositive(), all_nonnegative()
// Usage:
//   b = all_equal(vec, [eps]);
// Description:
//   Returns true if all of the entries in vec are equal to each other, or approximately equal to each other if eps is set.
// Arguments:
//   vec = vector to check
//   eps = Set to tolerance for approximate equality.  Default: 0
function all_equal(vec,eps=0) =
   eps==0 ? [for(v=vec) if (v!=vec[0]) v] == []
          : [for(v=vec) if (!approx(v,vec[0],eps)) v] == [];



// Function: are_ends_equal()
// Synopsis: Returns true if the first and last items in a list are approximately equal.
// Topics: Comparisons, List Handling
// See Also: approx(), all_zero(), all_nonzero(), all_positive(), all_negative(), all_nonpositive(), all_nonnegative()
// Usage:
//   are_ends_equal(list, [eps]);
// Description:
//   Returns true if the first and last points in the given list are equal to within epsilon.
// Arguments:
//   list = list to check
//   eps = Tolerance for approximate equality.  Default: `EPSILON` (1e-9)
function are_ends_equal(list, eps=EPSILON) =
  assert(is_list(list) && len(list)>0, "Must give a nonempty list")
  approx(list[0], list[len(list)-1], eps=eps);


// Function: is_increasing()
// Synopsis: Returns true if every item in a list is greater than the previous item. 
// Topics: Comparisons, List Handling
// See Also: max_index(), min_index(), is_increasing(), is_decreasing()
// Usage:
//    bool = is_increasing(list, [strict]);
// Description:
//   Returns true if the list is (non-strictly) increasing, or strictly increasing if `strict=true`.
//   The list can be a list of any items that OpenSCAD can compare, or it can be a string, which gets
//   evaluated character by character.
// Arguments:
//   list = list (or string) to check
//   strict = set to true to test that list is strictly increasing.  Default: false
// Example:
//   a = is_increasing([1,2,3,4]);  // Returns: true
//   b = is_increasing([1,3,2,4]);  // Returns: false
//   c = is_increasing([1,3,3,4]);  // Returns: true
//   d = is_increasing([1,3,3,4],strict=true);  // Returns: false
//   e = is_increasing([4,3,2,1]);  // Returns: false
function is_increasing(list,strict=false) =
    assert(is_list(list)||is_string(list))
    strict ? len([for (p=pair(list)) if(p.x>=p.y) true])==0
           : len([for (p=pair(list)) if(p.x>p.y) true])==0;


// Function: is_decreasing()
// Synopsis: Returns true if exery item in a list is less than the previous item. 
// Topics: Comparisons, List Handling
// See Also: max_index(), min_index(), is_increasing(), is_decreasing()
// Usage:
//   bool = is_decreasing(list, [strict]);
// Description:
//   Returns true if the list is (non-strictly) decreasing, or strictly decreasing if `strict=true`.
//   The list can be a list of any items that OpenSCAD can compare, or it can be a string, which gets
//   evaluated character by character.  
// Arguments:
//   list = list (or string) to check
//   strict = set to true to test that list is strictly decreasing.  Default: false
// Example:
//   a = is_decreasing([1,2,3,4]);  // Returns: false
//   b = is_decreasing([4,2,3,1]);  // Returns: false
//   c = is_decreasing([4,3,2,1]);  // Returns: true
function is_decreasing(list,strict=false) =
    assert(is_list(list)||is_string(list))
    strict ? len([for (p=pair(list)) if(p.x<=p.y) true])==0
           : len([for (p=pair(list)) if(p.x<p.y) true])==0;




function _type_num(x) =
    is_undef(x)?  0 :
    is_bool(x)?   1 :
    is_num(x)?    2 :
    is_nan(x)?    3 :
    is_string(x)? 4 :
    is_list(x)?   5 : 6;


// Function: compare_vals()
// Synopsis: Compares two values, possibly of different type.
// Topics: Comparisons, List Handling
// See Also: approx(), is_increasing(), is_decreasing()
// Usage:
//   test = compare_vals(a, b);
// Description:
//   Compares two values.  Lists are compared recursively.
//   Returns a negative value if a<b.  Returns a positive value if a>b.  Returns 0 if a==b.
//   If types are not the same, then undef < bool < nan < num < str < list < range.
// Arguments:
//   a = First value to compare.
//   b = Second value to compare.
function compare_vals(a, b) =
    (a==b)? 0 :
    let(t1=_type_num(a), t2=_type_num(b)) (t1!=t2)? (t1-t2) :
    is_list(a)? compare_lists(a,b) :
    is_nan(a)? 0 :
    (a<b)? -1 : (a>b)? 1 : 0;


// Function: compare_lists()
// Synopsis: Compares two lists of values, possibly of different type.
// Topics: Comparisons, List Handling
// See Also: compare_vals(), approx(), is_increasing(), is_decreasing()
// Usage:
//   test = compare_lists(a, b)
// Description:
//   Compare contents of two lists using `compare_vals()`.
//   Returns a negative number if `a`<`b`.
//   Returns 0 if `a`==`b`.
//   Returns a positive number if `a`>`b`.
// Arguments:
//   a = First list to compare.
//   b = Second list to compare.
function compare_lists(a, b) =
    a==b? 0 :
    let(
        cmps = [
            for (i = [0:1:min(len(a),len(b))-1])
            let( cmp = compare_vals(a[i],b[i]) )
            if (cmp!=0) cmp
        ]
    )
    cmps==[]? (len(a)-len(b)) : cmps[0];



// Section: Finding the index of the minimum or maximum of a list


// Function: min_index()
// Synopsis: Returns the index of the minimum value in the given list.
// Topics: List Handling
// See Also: max_index(), is_increasing(), is_decreasing()
// Usage:
//   idx = min_index(vals);
//   idxlist = min_index(vals, all=true);
// Description:
//   Returns the index of the first occurrence of the minimum value in the given list. 
//   If `all` is true then returns a list of all indices where the minimum value occurs.
// Arguments:
//   vals = vector of values
//   all = set to true to return indices of all occurrences of the minimum.  Default: false
// Example:
//   a = min_index([5,3,9,6,2,7,8,2,1]); // Returns: 8
//   b = min_index([5,3,9,6,2,7,8,2,7],all=true); // Returns: [4,7]
function min_index(vals, all=false) =
    assert( is_vector(vals), "Invalid or list of numbers.")
    all ? search(min(vals),vals,0) : search(min(vals), vals)[0];


// Function: max_index()
// Synopsis: Returns the index of the maximum value in the given list.
// Topics: List Handling
// See Also: min_index(), is_increasing(), is_decreasing()
// Usage:
//   idx = max_index(vals);
//   idxlist = max_index(vals, all=true);
// Description:
//   Returns the index of the first occurrence of the maximum value in the given list. 
//   If `all` is true then returns a list of all indices where the maximum value occurs.
// Arguments:
//   vals = vector of values
//   all = set to true to return indices of all occurrences of the maximum.  Default: false
// Example:
//   max_index([5,3,9,6,2,7,8,9,1]); // Returns: 2
//   max_index([5,3,9,6,2,7,8,9,1],all=true); // Returns: [2,7]
function max_index(vals, all=false) =
    assert( is_vector(vals) && len(vals)>0 , "Invalid or empty list of numbers.")
    all ? search(max(vals),vals,0) : search(max(vals), vals)[0];


// Section: Dealing with duplicate list entries


// Function: find_approx()
// Synopsis: Finds the indexes of the item(s) in the given list that are approximately the given value.
// Topics: List Handling
// See Also: in_list()
// Usage:
//   idx = find_approx(val, list, [start=], [eps=]);
//   indices = find_approx(val, list, all=true, [start=], [eps=]);
// Description:
//   Finds the first item in `list` that matches `val` to within `eps` tolerance, returning the index.  Returns `undef` if there is no match.
//   If `all=true` then returns all the items that agree within `eps` and returns the empty list if no such items exist.  
// Arguments:
//   val = The value to search for.  
//   list = The list to search.
//   ---
//   start = The index to start searching from.  Default: 0
//   all = If true, returns a list of all matching item indices.  Default: false
//   eps = The maximum allowed floating point rounding error for numeric comparisons.  Default: EPSILON (1e-9)
// Example:
//   find_approx(3,[4,5,3.01,2,2.99], eps=0.1);  // Returns 2
//   find_approx(9,[4,5,3.01,2,2.99], eps=0.1);  // Returns undef
//   find_approx(3,[4,5,3.01,2,2.99], all=true, eps=0.1);  // Returns [2,4]
//   find_approx(9,[4,5,3.01,2,2.99], all=true, eps=0.1);  // Returns []
function find_approx(val, list, start=0, all=false, eps=EPSILON) =
    all ? [for (i=[start:1:len(list)-1]) if (approx(val, list[i], eps=eps)) i]
        :  __find_approx(val, list, eps=eps, i=start);

function __find_approx(val, list, eps, i=0) =
    i >= len(list)? undef :
    approx(val, list[i], eps=eps)
          ? i
          : __find_approx(val, list, eps=eps, i=i+1);



// Function: deduplicate()
// Synopsis: Returns a list with all consecutive duplicate values removed.
// Topics: List Handling
// See Also: deduplicate_indexed()
// Usage:
//   list = deduplicate(list, [closed], [eps]);
// Description:
//   Removes consecutive duplicate items in a list.
//   When `eps` is zero, the comparison between consecutive items is exact.
//   Otherwise, when all list items and subitems are numbers, the comparison is within the tolerance `eps`.
//   Unlike `unique()` only consecutive duplicates are removed and the list is *not* sorted.
//   If `closed` is set to true then the first and last entries in `list` are treated as adjacent,
//   so all trailing items that match `list[0]` are dropped.  
// Arguments:
//   list = The list to deduplicate.
//   closed = If true, treats first and last list entry as adjacent.  Default: false
//   eps = The maximum tolerance between items.  Default: EPSILON
// Example:
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
// Synopsis: Takes a list of indices into a list of values, and returns a list of indices whose values are not consecutively the same.
// Topics: List Handling
// See Also: deduplicate()
// Usage:
//   new_idxs = deduplicate_indexed(list, indices, [closed], [eps]);
// Description:
//   Given a list, and a list of indices, removes consecutive indices corresponding to list values that are equal
//   or approximately equal.  
// Arguments:
//   list = The list that the indices index into.
//   indices = The list of indices to deduplicate.
//   closed = If true, drops trailing indices if their list value matches the list value corresponding to the first index. 
//   eps = The maximum difference to allow between numbers or vectors.
// Example:
//   a = deduplicate_indexed([8,6,4,6,3], [1,4,3,1,2,2,0,1]);  // Returns: [1,4,3,2,0,1]
//   b = deduplicate_indexed([8,6,4,6,3], [1,4,3,1,2,2,0,1], closed=true);  // Returns: [1,4,3,2,0]
//   c = deduplicate_indexed([[7,undef],[7,undef],[1,4],[1,4],[1,4+1e-12]],eps=0);    // Returns: [0,2,4]
function deduplicate_indexed(list, indices, closed=false, eps=EPSILON) =
    assert(is_list(list)||is_string(list), "Improper list or string.")
    indices==[]? [] :
    assert(is_vector(indices), "Indices must be a list of numbers.")
    let(
        ll = len(list),
        l = len(indices),
        end = l-(closed?0:1)
    ) [
        for (i = [0:1:l-1]) let(
           idx1 = indices[i],
           idx2 = indices[(i+1)%l],
           a = assert(idx1>=0,"Bad index.")
               assert(idx1<len(list),"Bad index in indices.")
               list[idx1],
           b = assert(idx2>=0,"Bad index.")
               assert(idx2<len(list),"Bad index in indices.")
               list[idx2],
           eq = (a == b)? true :
                (a*0 != b*0) || (eps==0)? false :
                is_num(a) || is_vector(a) ? approx(a, b, eps=eps) 
                : false
        ) 
        if (i==end || !eq) indices[i]
    ];




// Function: list_wrap()
// Synopsis: Returns a list whose last value is the same as the first.
// Topics: List Handling, Paths
// See Also: list_unwrap(), deduplicate()
// Usage:
//   list_wrap(path, [eps]);
// Description:
//   Force a list to wrap around so that its last point is equal to its first point:  if the first and last entries are equal, simply returns the list unchanged.
//   Otherwise returns the list with the first point duplicated at the end of the list.  Comparisons are done to the tolerance `eps`.  Lists of length 0 or
//   1 are returned unchanged.  
// Arguments:
//   list = list to unwrap
//   eps = epsilon for comparison.  Default: EPSILON (1e-9)

function list_wrap(list, eps=EPSILON) =
    assert(is_list(list))
    len(list)<2 || are_ends_equal(list,eps=eps)? list : [each list, list[0]];


function cleanup_path(list,eps=EPSILON) =
  echo("***** Function cleanup_path() has been replaced by list_unwrap() and will be removed in a future version *****")
  list_unwrap(list,eps);

function close_path(list,eps=EPSILON) =
  echo("***** Function close_path() has been replaced by list_wrap() and will be removed in a future version *****")
  list_wrap(list,eps);

// Function: list_unwrap()
// Synopsis: Removes the last item of a list if its first and last values are equal.
// Topics: List Handling, Paths
// See Also: list_wrap(), deduplicate()
// Usage:
//   list_unwrap(list, [eps]);
// Description:
//   If a list's last point matches its first point then delete the last point.  Inverse operation to {{list_wrap()}}.  Note that if the first/last points
//   are repeated then the output may still have the first point equal to the last point.  Comparisons are done to the tolerance `eps`.  If the list has
//   length 0 or 1 it is returned unchanged.  
// Arguments:
//   list = list to unwrap
//   eps = epsilon for comparison.  Default: EPSILON (1e-9)
function list_unwrap(list, eps=EPSILON) =
    assert(is_list(list))
    len(list)>=2 && are_ends_equal(list,eps=eps)? [for (i=[0:1:len(list)-2]) list[i]] : list;



// Function: unique()
// Synopsis: Returns a sorted list with all duplicates removed.
// Topics: List Handling
// See Also: shuffle(), sort(), sortidx(), unique_count()
// Usage:
//   ulist = unique(list);
// Description:
//   Given a string or a list returns the sorted string or the sorted list with all repeated items removed.
//   The sorting order of non homogeneous lists is the function `sort` order.
// Arguments:
//   list = The list to process.
// Example:
//   sorted = unique([5,2,8,3,1,3,8,7,5]);  // Returns: [1,2,3,5,7,8]
//   sorted = unique("axdbxxc");  // Returns: "abcdx"
//   sorted = unique([true,2,"xba",[1,0],true,[0,0],3,"a",[0,0],2]); // Returns: [true,2,3,"a","xba",[0,0],[1,0]]
function unique(list) =
    assert(is_list(list)||is_string(list), "Invalid input." )
    is_string(list)? str_join(unique([for (x = list) x])) :
    len(list)<=1? list : 
    is_homogeneous(list,1) && ! is_list(list[0])
    ?   _unique_sort(list)
    :   let( sorted = sort(list))
        [
            for (i=[0:1:len(sorted)-1])
                if (i==0 || (sorted[i] != sorted[i-1]))
                    sorted[i]
        ];

function _unique_sort(l) =
    len(l) <= 1 ? l : 
    let(
        pivot   = l[floor(len(l)/2)],
        equal   = [ for(li=l) if( li==pivot) li ],
        lesser  = [ for(li=l) if( li<pivot ) li ],
        greater = [ for(li=l) if( li>pivot) li ]
    )
    concat(
        _unique_sort(lesser), 
        equal[0], 
        _unique_sort(greater)
    );    


// Function: unique_count()
// Synopsis: Returns a sorted list of unique items with counts.
// Topics: List Handling
// See Also: shuffle(), sort(), sortidx(), unique()
// Usage:
//   sorted_counts = unique_count(list);
// Description:
//   Returns `[sorted,counts]` where `sorted` is a sorted list of the unique items in `list` and `counts` is a list such 
//   that `count[i]` gives the number of times that `sorted[i]` appears in `list`.  
// Arguments:
//   list = The list to analyze. 
// Example:
//   sorted = unique([5,2,8,3,1,3,8,3,5]);  // Returns: [ [1,2,3,5,8], [1,1,3,2,2] ]
function unique_count(list) =
    assert(is_list(list) || is_string(list), "Invalid input." )
    list == [] ? [[],[]] : 
    is_homogeneous(list,1) && ! is_list(list[0])
    ?    let( sorted = _group_sort(list) )
        [ [for(s=sorted) s[0] ], [for(s=sorted) len(s) ] ]
    :   let( 
            list = sort(list),
            ind = [0, for(i=[1:1:len(list)-1]) if (list[i]!=list[i-1]) i] 
        )
        [ select(list,ind), deltas( concat(ind,[len(list)]) ) ];


// Function: unique_approx()
// Usage:
//   ulist = unique_approx(data, [eps]);
// Description:
//   Returns a subset of items that differ by more thatn eps.  
function unique_approx(data,eps=EPSILON) =
  is_vector(data) ?
    let(
        sdata = sort(data)
    )
    [sdata[0],
     for(i=[1:1:len(data)-1]) if (abs(sdata[i]-sdata[i-1])>eps) sdata[i]
    ]
  :  
  let(
      dups = vector_search(data,eps,data)
  )
  [for(i=idx(data)) if (min(dups[i])==i) data[i]];

// Function: unique_approx_indexed()
// Usage:
//   ulist = unique_approx(data, [eps]);
// Description:
//   Returns the indices of a subset of items that differ by more thatn eps.  
function unique_approx_indexed(data,eps=EPSILON) =
  is_vector(data) ?
    let(
        sind = sortidx(data)
    )
    [sind[0], 
     for(i=[1:1:len(data)-1]) if (abs(data[sind[i]]-data[sind[i-1]])>eps) sind[i]
    ]
  :  
  let(
      dups = vector_search(data,eps,data)
  )
  [for(i=idx(data)) if (min(dups[i])==i) i];
  



// Section: Sorting


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

// idx should be an index of the arrays l[i]
function _group_sort_by_index(l,idx) =
    len(l) == 0 ? [] :
    len(l) == 1 ? [l] : 
    let(
        pivot   = l[floor(len(l)/2)][idx],
        equal   = [ for(li=l) if( li[idx]==pivot) li ],
        lesser  = [ for(li=l) if( li[idx]< pivot) li ],
        greater = [ for(li=l) if( li[idx]> pivot) li ]
    )
    concat(
        _group_sort_by_index(lesser,idx), 
        [equal], 
        _group_sort_by_index(greater,idx)
    );  
            

function _group_sort(l) =
    len(l) == 0 ? [] : 
    len(l) == 1 ? [l] : 
    let(
        pivot   = l[floor(len(l)/2)],
        equal   = [ for(li=l) if( li==pivot) li ],
        lesser  = [ for(li=l) if( li< pivot) li ],
        greater = [ for(li=l) if( li> pivot) li ]
    )
    concat(
        _group_sort(lesser), 
        [equal], 
        _group_sort(greater)
    );    


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
    : let( labeled = is_undef(idx) ? [for(i=idx(arr)) [i,arr[i]]]
                                   : [for(i=idx(arr)) [i, for(j=idx) arr[i][j]]],
           arrind = _indexed_sort(labeled))
      indexed 
      ? arrind
      : [for(i=arrind) arr[i]];
      
// lexical sort using compare_vals()
function _lexical_sort(arr) = 
    len(arr)<=1? arr : 
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
// Synopsis: Returns a sorted list.
// Topics: List Handling
// See Also: shuffle(), sortidx(), unique(), unique_count(), group_sort()
// Usage:
//   slist = sort(list, [idx]);
// Description:
//   Sorts the given list in lexicographic order. The sort is stable, meaning equivalent items do not change order. 
//   If the input is a homogeneous simple list or a homogeneous 
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
    ?   let(size = list_shape(list[0]))
        size==0 ?         _sort_scalars(list)
        : len(size)!=1 ?  _sort_general(list,idx)  
        : is_undef(idx) ? _sort_vectors(list)
        : assert( _valid_idx(idx) , "Invalid indices.")
          _sort_vectors(list,[for(i=idx) i])        
    : _sort_general(list,idx);
        

// Function: sortidx()
// Synopsis: Returns a list of sorted indices into a list.
// Topics: List Handling
// See Also: shuffle(), sort(), group_sort(), unique(), unique_count()
// Usage:
//   idxlist = sortidx(list, [idx]);
// Description:
//   Given a list, sort it as function `sort()`, and returns
//   a list of indexes into the original list in that sorted order.
//   The sort is stable, so equivalent items so not change order.  
//   If you iterate the returned list in order, and use the list items
//   to index into the original list, then you are accessing the original
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
    assert(is_list(list)||is_string(list), "Invalid list." )
    is_homogeneous(list,1)
    ?   let( 
            size = list_shape(list[0]),
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




// Function: group_sort()
// Synopsis: Returns a sorted list of groups of values.
// Topics: List Handling
// See Also: group_data(), shuffle(), sort(), sortidx(), unique(), unique_count()
// Usage:
//   ulist = group_sort(list,[idx]);
// Description:
//   Given a list of numbers, sorts the list into a sequence of lists, where each list contains any repeated values.
//   If there are no repeated values, the output is a list of singleton lists.  
//   If you apply {{flatten()}} to the output, the result is a simple sorted list.  
//   .
//   When the input is a list of lists, the sorting is done based on index `idx` of the entries in `list`.
//   In this case, `list[i][idx]` must be a number for every `i`, and the entries in `list` are grouped
//   together in the output if they match at index `idx`.  This function can be used to group together
//   items that are tagged with the same index.  
// Arguments:
//   list = The list to sort.
//   idx = If input is a list of lists, index to sort on.  Default: 0.  
// Example:
//   sorted = group_sort([5,2,8,3,1,3,8,7,5]);  // Returns: [[1],[2],[3,3],[5,5],[7],[8,8]]
//   // Next example returns: [ [[2,"b"],[2,"e"]], [[3,"d"]], [[5,"a"],[5,"c"]] ]
//   sorted2 = group_sort([[5,"a"],[2,"b"], [5,"c"], [3,"d"], [2,"e"] ], idx=0);  
function group_sort(list, idx) = 
    assert(is_list(list), "Input should be a list." )
    assert(is_undef(idx) || (is_int(idx) && idx>=0) , "Invalid index." )
    len(list)<=1 ? [list] :
    is_vector(list)? assert(is_undef(idx),"Cannot give idx with a vector input") _group_sort(list) :
    let( idx = default(idx,0) )
    assert( [for(entry=list) if(!is_list(entry) || len(entry)<idx || !is_num(entry[idx]) ) 1]==[],
        "Some entry of the list is a list shorter than `idx` or the indexed entry of it is not a number.")
    _group_sort_by_index(list,idx);
        


// Function: group_data()
// Synopsis: Groups list data by integer group numbers.
// Topics: List Handling
// See Also: group_sort(), shuffle(), sort(), sortidx(), unique(), unique_count()
// Usage:
//   groupings = group_data(groups, values);
// Description:
//   Given a list of integer group numbers, and an equal-length list of values,
//   returns a list of groups with the values sorted into the corresponding groups.
//   For example: if you have a groups index list of `[2,3,2]` and values of `["A","B","C"]`, then
//   the values `"A"` and `"C"` are put in group 2, and `"B"` is in group 3.
//   Groups that have no values grouped into them are empty lists. Therefore, the
//   above would return `[[], [], ["A","C"], ["B"]]`
// Arguments:
//   groups = A list of integer group index numbers.
//   values = A list of values to sort into groups.
// Example:
//   groups = group_data([1,2,0], ["A","B","C"]);  // Returns [["B"],["C"],["A"]]
// Example:
//   groups = group_data([1,3,1], ["A","B","C"]);  // Returns [[],["A","C"],[],["B"]]
function group_data(groups, values) =
    assert(all_integer(groups) && all_nonnegative(groups))
    assert(is_list(values))
    assert(len(groups)==len(values),
           "The groups and values arguments should be lists of matching length.")
    let( sorted = _group_sort_by_index([for(i=idx(groups))[groups[i],values[i]]],0) )
    // retrieve values and insert []
    [
        for (i = idx(sorted))
        let(
            a  = i==0? 0 : sorted[i-1][0][0]+1,
            g0 = sorted[i]
        )
        each [
            for (j = [a:1:g0[0][0]-1]) [],
            [for (g1 = g0) g1[1]]
        ]
    ];


// Function: list_smallest()
// Synopsis: Returns the `k` smallest values in the list, in arbitrary order.
// Topics: List Handling
// See Also: group_sort(), shuffle(), sort(), sortidx(), unique(), unique_count()
// Usage:
//   small = list_smallest(list, k)
// Description:
//   Returns a set of the k smallest items in list in arbitrary order.  The items must be
//   mutually comparable with native OpenSCAD comparison operations.
//   You get "undefined operation" errors if you provide invalid input. 
// Arguments:
//   list = list to process
//   k = number of items to return
function list_smallest(list, k) =
    assert(is_list(list))
    assert(is_int(k) && k>=0, "k must be nonnegative")
    let( 
        v       = list[rand_int(0,len(list)-1,1)[0]],
        smaller = [for(li=list) if(li<v) li ],
        equal   = [for(li=list) if(li==v) li ]
    )
    len(smaller)   == k ? smaller :
    len(smaller)<k && len(smaller)+len(equal) >= k ? [ each smaller, for(i=[1:k-len(smaller)]) v ] :
    len(smaller)   >  k ? list_smallest(smaller, k) :
    let( bigger  = [for(li=list) if(li>v) li ] )
    concat(smaller, equal, list_smallest(bigger, k-len(smaller) -len(equal)));



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
