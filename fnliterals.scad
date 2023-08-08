//////////////////////////////////////////////////////////////////////
// LibFile: fnliterals.scad
//   Handlers for function literals, and Function literal generators.
// Includes:
//   include <BOSL2/std.scad>
//   include <BOSL2/fnliterals.scad>
// FileGroup: Data Management
// FileSummary: Function Literal Algorithms, and factories for generating function literals for builtin functions.
// DefineHeader(Table;Headers=Positional|Definition||Named|Definition): FunctionLiteral Args
//////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////
// Section: Function Literal Algorithms


// Function: map()
// Synopsis: Applies a function to each item in a list.
// Topics: Function Literals, Looping
// See Also: filter(), reduce(), accumulate(), while(), for_n()
// Usage:
//   lst = map(func, list);
//   lst = map(function (x) x+1, list);
// Description:
//   Applies the function `func` to all items in `list`, returning the list of results.
//   In pseudo-code, this is effectively:
//   ```
//   function map(func,list):
//       out = [];
//       foreach item in list:
//           append func(item) to out;
//       return out;
//   ```
// Arguments:
//   func = The function of signature (x) to evaluate for each item in `list`.
//   list = The input list.
// Example:
//   func = function(x) x*x;
//   echo(map(func, [1,2,3,4]));
//   // ECHO: [1,4,9,16]
// Example:
//   path = star(n=5,step=2,d=100);
//   seglens = map(function (p) norm(p[1]-p[0]), pair(path,wrap=true));
function map(func, list) =
    assert(is_function(func))
    assert(is_list(list))
    [for (x=list) func(x)];


// Function: filter()
// Synopsis: Returns just the list items which the given function returns true for.
// Topics: Function Literals, Looping, Filters
// See Also: map(), reduce(), accumulate(), while(), for_n(), find_all()
// Usage:
//   lst = filter(func, list);
//   lst = filter(function (x) x>1, list);
// Description:
//   Returns all items in `list` that the function `func` returns true for.
//   In pseudo-code, this is effectively:
//   ```
//   function filter(func,list):
//       out = [];
//       foreach item in list:
//           if func(item) is true:
//               append item to out;
//       return out;
//   ```
// Arguments:
//   func = The function of signature `function (x)` to evaluate for each item in `list`.
//   list = The input list.
// Example:
//   func = function(x) x>5;
//   echo(filter(func, [3,4,5,6,7]));
//   // ECHO: [6,7]
function filter(func, list) =
    assert(is_function(func))
    assert(is_list(list))
    [for (x=list) if (func(x)) x];


// Function: reduce()
// Synopsis: Applies a 2-arg function cumulatively to the items of a list, returning the final result.
// Topics: Function Literals, Looping
// See Also: map(), filter(), accumulate(), while(), for_n()
// Usage:
//   res = reduce(func, list, [init]);
//   res = reduce(function (a,b) a+b, list, <init=);
// Description:
//   First the accumulator is set to the value in `init`.  Then, for each item in `list`, the function
//   in `func` is called with the accumulator and that list item, and the result is stored in the
//   acumulator for the next iteration.  Once all list items have been processed, the value in the
//   accumulator is returned.  Ie: `reduce(function (a,b) a+b, list)` is the equivalent of `sum(list)`.
//   In pseduo-code, this is effectively:
//   ```
//   function reduce(func, list, init=0):
//       x = init;
//       foreach item in list:
//           x = func(x, item);
//       return x;
//   ```
// Arguments:
//   func = The function of signature `function (x)` to evaluate for each item in `list`.
//   list = The input list.
//   init = The starting value for the accumulator.  Default: 0
// Example: Re-Implement sum()
//   x = reduce(f_add(),[3,4,5]);  // Returns: 12
// Example: Re-Implement product()
//   x = reduce(f_mul(),[3,4,5]);  // Returns: 60
// Example: Re-Implement all()
//   x = reduce(f_and(),[true,true,true]);   // Returns: true
//   y = reduce(f_and(),[true,false,true]);  // Returns: false
// Example: Re-Implement any()
//   x = reduce(f_or(),[false,false,false]); // Returns: false
//   y = reduce(f_or(),[true,false,true]);   // Returns: true
function reduce(func, list, init=0) =
    assert(is_function(func))
    assert(is_list(list))
    let(
        l = len(list),
        a = function (x,i) i<l? a(func(x,list[i]), i+1) : x
    ) a(init,0);


// Function: accumulate()
// Synopsis: Applies a 2-arg function cumulatively to the items of a list, returning a list of every result.
// Topics: Function Literals, Looping
// See Also: map(), filter(), reduce(), while(), for_n()
// Usage:
//   res = accumulate(func, list, [init]);
//   res = accumulate(function (a,b) a+b, list, [init=]);
// Description:
//   First the accumulator is set to the value in `init`.  Then, for each item in `list`, the function
//   in `func` is called with the accumulator and that list item, and the result is stored in the
//   acumulator for the next iteration.  That value is also appended to the output list.  Once all
//   list items have been processed, the list of accumulator values is returned.
//   In pseduo-code, this is effectively:
//   ```
//   function accumulate(func, list, init=0):
//       out = []
//       x = init;
//       foreach item in list:
//           x = func(x, item);
//           append x to out;
//       return out;
//   ```
// Arguments:
//   func = The function of signature `function (a,b)` to evaluate for each item in `list`.  Default: `f_add()`
//   list = The input list.
//   init = The starting value for the accumulator.  Default: 0
// Example: Reimplement cumsum()
//   echo(accumulate(function (a,b) a+b, [3,4,5],0));  // ECHO: [3,7,12]
// Example: Reimplement cumprod()
//   echo(accumulate(f_mul(),[3,4,5],1)); // ECHO: [3,12,60,360]
function accumulate(func, list, init=0) =
    assert(is_function(func))
    assert(is_list(list))
    let(
        l = len(list),
        a = function (x, i, out)
            i >= l ? out :
            let( x=func(x,list[i]) )
            a(x, i+1, [each out, x])
    ) a(init, 0, []);


// Function: while()
// Synopsis: While a `cond` function returns true, iteratively calls a work function, returning the final result.
// Topics: Function Literals, Looping, Iteration
// See Also: map(), filter(), reduce(), accumulate(), while(), for_n()
// Usage:
//   x = while(init, cond, func);
// Description:
//   Repeatedly calls the function literals in `cond` and `func` until the `cond` call returns false.
//   Both `cond` and `func` have the signature `function (i,x)`. The variable `i` is passed the iteration
//   number, starting with 0.  On the first iteration, the variable `x` is given by `init`.  On subsequent
//   iterations, `x` is given by the results of the previous call to `func`.  Returns the resulting `x` of
//   the final iteration.  In pseudo-code, this is effectively:
//   ```
//   function while(init, cond, func):
//       x = init;
//       i = 0;
//       while cond(i, x):
//           x = func(i, x);
//           i = i + 1;
//       return x;
//   ```
// Arguments:
//   init = The initial value for `x`.
//   cond = A function literal with signature `function (i,x)`, called to determine if the loop should continue.  Returns true if the loop should continue.
//   func = A function literal with signature `function (i,x)`, called on each iteration.  The returned value is passed as `x` on the next iteration.
// Example:
//   fibs = while(
//       init = [1,1],
//       cond = function (i,x) select(x,-1)<25,
//       func = function (i,x) concat(x, [sum(select(x,-2,-1))])
//   );  // Returns: [1,1,2,3,5,8,13,21]
function while(init, cond, func) =
    assert(is_function(cond))
    assert(is_function(func))
    let( a = function(x,i) cond(i,x) ? a(func(i,x),i+1) : x )
    a(init,0);


// Function: for_n()
// Synopsis: Iteratively calls a work function `n` times, returning the final result.
// Topics: Function Literals, Looping, Iteration
// See Also: map(), filter(), reduce(), accumulate(), while()
// Usage:
//   x = for_n(n, init, func);
// Description:
//   Given the function literal `func`, with the signature `function (i,x)`, repeatedly calls it `n` times.
//   If `n` is given as a scalar, the `i` value will traverse the range `[0:1:n-1]`, one value per call.
//   If `n` is given as a range, the `i` value will traverse the given range, one value per call.
//   The `x` value for the first  iteration is given in `init`, and in all subsequent iterations `x` will be the result of the previous call.
//   In pseudo-code, this is effectively:
//   ```
//   function for_n(n, init, func):
//       x = init;
//       if is_range(n):
//           iterate i over range n:
//               x = func(i,x);
//       else:
//           iterate i from 0 to n-1 by 1:
//               x = func(i,x);
//       return x;
//   ```
// Arguments:
//   n = The number of iterations to perform, or, if given as a range, the range to traverse.
//   init = The initial value to pass as `x` to the function in `func`.
//   func = The function literal to call, with signature `function (i,x)`.
// Example:
//   fib = function(n) for_n(
//       n, [],
//       function(i,x) x? [x[1], x[0]+x[1]] : [0,1]
//   )[1];
function for_n(n,init,func) =
    assert(is_finite(n))
    assert(is_function(func))
    let(
        n = is_num(n)? [0:1:n-1] : n,
        a = function(x,i) i <= n[2]? a(func(i,x), i+n[1]) : x
    )
    a(init, n[0]);


// Function: find_all()
// Synopsis: Returns the indices of all items in a list that a given function returns true for.
// Topics: Function Literals, Looping, Filters
// See Also: find_all(), reduce(), find_first(), binsearch()
// Usage:
//   indices = find_all(func, list);
//   indices = find_all(function (x) x>1, list);
// Description:
//   Returns the indices of all items in `list` that the function `func` returns true for.
//   In pseudo-code, this is effectively:
//   ```
//   function find_all(func,list):
//       out = [];
//       foreach item in list:
//           if func(item) is true:
//               append item index to out;
//       return out;
//   ```
// Arguments:
//   func = The function of signature `function (x)` to evaluate for each item in `list`.
//   list = The input list.
// Example:
//   func = function(x) x>5;
//   echo(find_all(func, [3,4,5,6,7]));
//   // ECHO: [3,4]
function find_all(func, list) =
    assert(is_function(func))
    assert(is_list(list))
    [for (indexnum=idx(list)) if (func(list[indexnum])) indexnum];


// Function: find_first()
// Synopsis: Returns the index of the first item in a list, after `start`, that a given function returns true for.
// Topics: Function Literals, Searching
// See Also: find_all(), filter(), binsearch(), find_all()
// Usage:
//   idx = find_first(func, list, [start=]);
// Description:
//   Finds the index of the first item in `list`, after index `start`,  which the function literal in `func` will return true for.
//   The signature of the function literal in `func` is `function (x)`, and it is expected to return true when the
//   value compares as matching.  It should return false otherwise.  If you need to find *all* matching items in the
//   list, you should use {{find_all()}} instead.
// Arguments:
//   func = The function literal to use to check each item in `list`.  Expects the signature `function (x)`, and a boolean return value.
//   list = The list to search.
//   ---
//   start = The first item to check.
// Example:
//   data = [8,5,3,7,4,2,9];
//   echo(find_first(f_lte(4), data));
//   // ECHO: 2
// Example:
//   data = [8,5,3,7,4,2,9];
//   echo(find_first(f_lte(4), data, start=3));
//   // ECHO: 4
function find_first(func, list, start=0) =
    assert(is_function(func))
    assert(is_list(list))
    assert(is_finite(start))
    let(
        listlen = len(list),
        _find_first = function(indexnum) (
            indexnum >= listlen? undef :
            func(list[indexnum])? indexnum :
            _find_first(indexnum+1)
        )
    )
    _find_first(start);


// Function: binsearch()
// Synopsis: Does a binary search of a sorted list to find the index of a given value.
// Topics: Function Literals, Data Structures, Searching
// See Also: map(), filter(), reduce(), accumulate(), hashmap(), find_all(), find_first()
// Usage:
//   idx = binsearch(key,list, [cmp]);
// Description:
//   Searches a sorted list for an entry with the given key, using a binary search strategy.
//   Returns the index of the matching item found.  If none found, returns undef.
// Arguments:
//   key = The key to look for.
//   list = The list of items to search through.
//   idx = If given, the index of the item sublists to use as the item key.
//   cmp = The comparator function literal to use.  Default: `f_cmp()`
// Example:
//   items = unique(rands(0,100,10000));
//   idx = binsearch(44, items);
// Example:
//   items = unique(rands(0,100,10000));
//   idx = binsearch(44, items, cmp=function(a,b) a-b);
// Example:
//   items = [for (i=[32:126]) [chr(i), i]];
//   idx = binsearch("G", items, idx=0);
function binsearch(key, list, idx, cmp=f_cmp()) =
    let(
        a = function(s,e)
            let(
                p = floor((s+e)/2),
                ikey = is_undef(idx)? list[p] : list[p][idx],
                c = cmp(ikey,key)
            )
            c == 0? p :
            c > 0? (p == s? undef : a(s, p-1)) :
            (p == e? undef : a(p+1, e))
    ) a(0,len(list)-1);


// Function: simple_hash()
// Synopsis: Returns an integer hash of a given value.
// Topics: Function Literals, Hashing, Data Structures
// See Also: hashmap()
// Usage:
//   hx = simple_hash(x);
// Description:
//   Given an arbitrary value, returns the integer hash value for it.
// Arguments:
//   x = The value to get the simple hash value  of.
// Example:
//   x = simple_hash("Foobar");
//   x = simple_hash([[10,20],[-5,3]]);
function simple_hash(x) =
    let( m = 0.5 * (sqrt(5) - 1) )
    is_num(x)? floor(m*x*256) :
    is_list(x)? let(
        l = len(x),
        a = function(i,v) i>=l? v : a(i+1, m*v + simple_hash(x[i]))
    ) floor(a(0,0)*4096) : let(
        s = str(x),
        l = len(s),
        a = function(i,v) i>=l? v : a(i+1, m*v + ord(s[i]))
    ) floor(a(0,0)*4096);


// Function: hashmap()
// Synopsis: Creates a hashmap manipulation function.
// Topics: Function Literals, Data Structures, Hashing
// See Also: simple_hash()
// Usage: Creating an Empty HashMap.
//   hm = hashmap([hashsize=]);
// Usage: Creating a Populated HashMap.
//   hm = hashmap(items=KEYVAL_LIST, [hashsize=]);
// Usage: Adding an Entry
//   hm2 = hm(key, val);
// Usage: Adding Multiple Entries
//   hm2 = hm(additems=KEYVAL_LIST);
// Usage: Removing an Entry
//   hm2 = hm(del=KEY);
// Usage: Fetching a Value
//   x = hm(key);
// Usage: Iterating a HashMap
//   for (kv=hm()) let(k=kv[0], v=kv[1]) ...
// Description:
//   This is a factory function for creating hashmap data structure functions.  You can use a hashmap
//   to store large amounts of [key,value] data.  At around 4000 items, this becomes faster than using
//   `search()` through the list.
// Arguments:
//   ---
//   hashsize = The number of hashtable buckets to form.
//   items = A list of [key,value] pairs to initialize the hashmap with.
// FunctionLiteral Args:
//   k = The key name.
//   v = The value to store with the key.
//   ---
//   del = If given the key of an item to delete, makes a new hashmap with that item removed.
//   additems = If given a list of [key,val] pairs, makes a new hashmap with the items added.
// Example:
//   hm = hashmap(items=[for (i=[0:9999]) [str("foo",i),i]]);
//   a = hm("foo37");  // Returns: 37
//   hm2 = hm("Blah", 39);  // Adds entry "Blah" with val 39.
//   b = hm2("Blah");  // Returns: 39
//   hm3 = hm2(additems=[["bar",39],["qux",21]]);  // Adds "bar" and "qux"
//   hm4 = hm3(del="Blah");  // Deletes entry "Blah".
//   for (kv = hm4()) {  // Iterates over all key/value pairs.
//      echo(key=kv[0], val=kv[1]);
//   }
function hashmap(hashsize=127,items,table) =
    let(
        table = !is_undef(table)? table : [for (i=[0:1:hashsize-1]) []]
    )
    items != undef? hashmap(hashsize=hashsize, table=table)(additems=items) :
    function(k,v,del,additems)
        additems!=undef? let(
            hashes = [for (item = additems) simple_hash(item[0]) % hashsize],
            grouped = list_pad(group_data(hashes, additems), hashsize, []),
            table = [for (i=idx(table)) concat(table[i],grouped[i])]
        ) hashmap(hashsize=hashsize, table=table) :
        del!=undef? let(
            bnum = simple_hash(del) % hashsize,
            bucket = [for (item=table[bnum]) if (item[0]!=del) item],
            table = [for (i=idx(table)) i==bnum? bucket : table[i]]
        ) hashmap(hashsize=hashsize, table=table) :
        k==undef && v==undef? [for (bucket=table, item=bucket) item] :
        let(
            bnum = simple_hash(k) % hashsize,
            bucket = table[bnum],
            fnd = search([k], bucket)
        )
        k!=undef && v==undef? (fnd==[]? undef : bucket[fnd[0]][1]) :
        let(
            newtable = [
                for (i=idx(table))
                i!=bnum? table[i] :
                !fnd? [[k,v], each bucket] :
                [[k,v], for (j=idx(bucket)) if (j!=fnd[0]) bucket[i]]
            ]
        ) hashmap(hashsize=hashsize, table=newtable);



//////////////////////////////////////////////////////////////////////
// Section: Function Meta-Generators


// Function: f_1arg()
// Synopsis: Creates a factory for a 2-arg function literal, where you can optionally pre-fill the arg.
// Topics: Function Literals
// See Also: f_2arg(), f_3arg()
// Usage:
//   fn = f_1arg(func);
// Description:
//   Takes a function literal that accepts one argument, and returns a function
//   literal factory that can be used to pre-fill out that argument with a constant.
// Example:
//   f_str = f_1arg(function(a) str(a));
//   fn_str = f_str();   // = function(a) str(a);
//   fn_str3 = f_str(3); // = function() str(3);
function f_1arg(target_func) =
    function(a)
        a==undef? function(x) target_func(x) :
        function() target_func(a);


// Function: f_2arg()
// Synopsis: Creates a factory for a 2-arg function literal, where you can optionally pre-fill the args.
// Topics: Function Literals
// See Also: f_1arg(), f_3arg()
// Usage:
//   fn = f_2arg(target_func);
// Description:
//   Takes a function literal that accepts two arguments, and returns a function
//   literal factory that can be used to pre-fill out one or both of those arguments
//   with a constant.
// Example:
//   f_lt = f_2arg(function(a,b) a<b);
//   fn_lt = f_lt();      // = function(a,b) a<b;
//   fn_3lt = f_lt(3);    // = function(b) 3<b;
//   fn_3lt = f_lt(a=3);  // = function(b) 3<b;
//   fn_lt3 = f_lt(b=3);  // = function(a) a<3;
//   fn_3lt4 = f_lt(3,4); // = function() 3<4;
function f_2arg(target_func) =
    function(a,b)
        a==undef && b==undef? function(x,y) target_func(x,y) :
        a==undef? function(x) target_func(x,b) :
        b==undef? function(x) target_func(a,x) :
        function() target_func(a,b);


// Function: f_2arg_simple()
// Synopsis: Creates a factory for a 2-arg function literal, where you can optionally pre-fill the args.
// Topics: Function Literals
// See Also: f_1arg(), f_3arg()
// Usage:
//   fn = f_2arg_simple(target_func);
// Description:
//   Takes a function literal that accepts two arguments, and returns a function
//   literal factory that can be used to pre-fill out one or both of those arguments
//   with a constant.  When given a single argument, fills out the segond function
//   argument with a constant.
// Example:
//   f_lt = f_2arg_simple(function(a,b) a<b);
//   fn_lt = f_lt();       // = function(a,b) a<b;
//   fn_lt3 = f_lt(3);     // = function(a) a<3;
//   fn_3lt4 = f_lt(3,4);  // = function() 3<4;
function f_2arg_simple(target_func) =
    function(a,b)
        a==undef && b==undef? function(x,y) target_func(x,y) :
        b==undef? function(x) target_func(x,a) :
        function() target_func(a,b);


// Function: f_3arg()
// Synopsis: Creates a factory for a 3-arg function literal, where you can optionally pre-fill the args.
// Topics: Function Literals
// See Also: f_1arg(), f_2arg()
// Usage:
//   fn = f_3arg(target_func);
// Description:
//   Takes a function literal that accepts three arguments, and returns a function
//   literal factory that can be used to pre-fill out some or all of those arguments
//   with a constant.
// Example:
//   p1 = [10,4]; p2 = [3,7];
//   f_va = f_3arg(function(a,b,c) vector_angle(a,b,c));
//   fn_va = f_va();       // = function(a,b,c) vector_angle(a,b,c);
//   fn_va2 = f_lt(c=p1);  // = function(a,b) vector_angle(a,b,p1);
//   fn_va3 = f_lt(a=p2);  // = function(a,c) vector_angle(a,p2,c);
//   fn_va4 = f_lt(a=p1,c=p2); // = function() vector_angle(p1,b,p2);
function f_3arg(target_func) =
    function(a,b,c)
        a==undef && b==undef && c==undef? function(x,y,z) target_func(x,y,z) :
        a==undef && b==undef? function(x,y) target_func(x,y,c) :
        a==undef && c==undef? function(x,y) target_func(x,b,y) :
        b==undef && c==undef? function(x,y) target_func(a,x,y) :
        a==undef? function(x) target_func(x,b,c) :
        b==undef? function(x) target_func(a,x,c) :
        c==undef? function(x) target_func(a,b,x) :
        function() target_func(a,b,c);


// Function: ival()
// Synopsis: Generates a function with signature `(i,x)` that calls `func(i)`
// Topics: Function Literals
// See Also: f_1arg(), f_2arg(), f_3arg(), ival(), xval()
// Usage:
//   newfunc = ival(func);
// Description:
//   Wraps a single-argument function literal so that it can take two arguments,
//   passing the first argument along to the wrapped function.
// Arguments:
//   target_func = The function of signature (x) to wrap.
// FunctionLiteral Args:
//   a = The argument that will be passed through.
//   b = The argumen that will be discarded.
// Example:
//   x = while(0, ival(f_lt(5)), xval(f_add(1)));
function ival(target_func) = function(a,b) target_func(a);


// Function: xval()
// Synopsis: Generates a function with signature `(i,x)` that calls `func(x)`
// Topics: Function Literals
// See Also: f_1arg(), f_2arg(), f_3arg(), ival(), xval()
// Usage:
//   newfunc = xval(func);
// Description:
//   Wraps a single-argument function literal so that it can take two arguments,
//   passing the first argument along to the wrapped function.
// Arguments:
//   target_func = The function of signature (x) to wrap.
// FunctionLiteral Args:
//   a = The argument that will be passed through.
//   b = The argumen that will be discarded.
// Example:
//   x = while(0, ival(f_lt(5)), xval(f_add(1)));
function xval(target_func) = function(a,b) target_func(b);



//////////////////////////////////////////////////////////////////////
// Section: Comparator Generators


// Function: f_cmp()
// Synopsis: Returns a function to compare values.
// Topics: Function Literals, Comparators
// See Also: f_cmp(), f_gt(), f_lt(), f_gte(), f_lte(), f_eq(), f_neq(), f_approx(), f_napprox()
// Usage:
//   fn = f_cmp();
//   fn = f_cmp(b);
//   fn = f_cmp(a,b);
// Description:
//   A factory that generates function literals that compare `a` and `b`, where one or
//   both arguments can be replaced with constants.  If `a` and `b` are equal, the function
//   literal will return 0.  If a<b then -1 is returned.  If a>b then 1 is returned.
// Example:
//   fn_cmp = f_cmp();       // = function(a,b) a==b?0: a>b?1: -1;
//   fn_cmp3 = f_cmp(3);     // = function(a) a==3?0: a>3?1: -1;
//   fn_3cmp4 = f_cmp(3,4);  // = function() 3==4?0: 3>4?1: -1;
function f_cmp(a,b) = f_2arg_simple(function (a,b) a==b?0: a>b?1: -1)(a,b);


// Function: f_gt()
// Synopsis: Returns a function to compare if `a` is greater than `b`.
// Topics: Function Literals, Comparators
// See Also: f_cmp(), f_gt(), f_lt(), f_gte(), f_lte(), f_eq(), f_neq(), f_approx(), f_napprox()
// Usage:
//   fn = f_gt();
//   fn = f_gt(b);
//   fn = f_gt(a,b);
// Description:
//   A factory that generates function literals based on `a > b`, where one
//   or both of the arguments can be replaced with constants.
// Example:
//   fn_gt = f_gt();       // = function(a,b) a>b;
//   fn_gt3 = f_gt(3);     // = function(a) a>3;
//   fn_3gt4 = f_gt(3,4);  // = function() 3>4;
function f_gt(a,b) = f_2arg_simple(function (a,b) a>b)(a,b);


// Function: f_lt()
// Synopsis: Returns a function to compare if `a` is less than `b`.
// Topics: Function Literals, Comparators
// See Also: f_cmp(), f_gt(), f_lt(), f_gte(), f_lte(), f_eq(), f_neq(), f_approx(), f_napprox()
// Usage:
//   fn = f_lt();
//   fn = f_lt(b);
//   fn = f_lt(a,b);
// Description:
//   A factory that generates function literals based on `a < b`, where one
//   or both of the arguments can be replaced with constants.
// Example:
//   fn_lt = f_lt();       // = function(a,b) a<b;
//   fn_lt3 = f_lt(3);     // = function(a) a<3;
//   fn_3lt4 = f_lt(3,4);  // = function() 3<4;
function f_lt(a,b) = f_2arg_simple(function (a,b) a<b)(a,b);


// Function: f_gte()
// Synopsis: Returns a function to compare if `a` is greater than or equal to `b`.
// Topics: Function Literals, Comparators
// See Also: f_cmp(), f_gt(), f_lt(), f_gte(), f_lte(), f_eq(), f_neq(), f_approx(), f_napprox()
// Usage:
//   fn = f_gte();
//   fn = f_gte(b);
//   fn = f_gte(a,b);
// Description:
//   A factory that generates function literals based on `a >= b`, where one
//   or both of the arguments can be replaced with constants.
// Example:
//   fn_gte = f_gte();       // = function(a,b) a>=b;
//   fn_gte3 = f_gte(3);     // = function(a) a>=3;
//   fn_3gte4 = f_gte(3,4);  // = function() 3>=4;
function f_gte(a,b) = f_2arg_simple(function (a,b) a>=b)(a,b);


// Function: f_lte()
// Synopsis: Returns a function to compare if `a` is less than or equal to `b`.
// Topics: Function Literals, Comparators
// See Also: f_cmp(), f_gt(), f_lt(), f_gte(), f_lte(), f_eq(), f_neq(), f_approx(), f_napprox()
// Usage:
//   fn = f_lte();
//   fn = f_lte(b);
//   fn = f_lte(a,b);
// Description:
//   A factory that generates function literals based on `a <= b`, where
//   one or both arguments can be replaced with constants.
// Example:
//   fn_lte = f_lte();       // = function(a,b) a<=b;
//   fn_lte3 = f_lte(3);     // = function(a) a<=3;
//   fn_3lte4 = f_lte(3,4);  // = function() 3<=4;
function f_lte(a,b) = f_2arg_simple(function (a,b) a<=b)(a,b);


// Function: f_eq()
// Synopsis: Returns a function to compare if `a` is exactly equal to `b`.
// Topics: Function Literals, Comparators
// See Also: f_cmp(), f_gt(), f_lt(), f_gte(), f_lte(), f_eq(), f_neq(), f_approx(), f_napprox()
// Usage:
//   fn = f_eq();
//   fn = f_eq(b);
//   fn = f_eq(a,b);
// Description:
//   A factory that generates function literals based on `a == b`, where
//   one or both arguments can be replaced with constants.
// Example:
//   fn_eq = f_eq();       // = function(a,b) a==b;
//   fn_eq3 = f_eq(3);     // = function(a) a==3;
//   fn_3eq4 = f_eq(3,4);  // = function() 3==4;
function f_eq(a,b) = f_2arg_simple(function (a,b) a==b)(a,b);


// Function: f_neq()
// Synopsis: Returns a function to compare if `a` is not exactly equal to `b`.
// Topics: Function Literals, Comparators
// See Also: f_cmp(), f_gt(), f_lt(), f_gte(), f_lte(), f_eq(), f_neq(), f_approx(), f_napprox()
// Usage:
//   fn = f_neq();
//   fn = f_neq(b);
//   fn = f_neq(a,b);
// Description:
//   A factory that generates function literals based on `a != b`, where
//   one or both arguments can be replaced with constants.
// Example:
//   fn_neq = f_neq();       // = function(a,b) a!=b;
//   fn_neq3 = f_neq(3);     // = function(a) a!=3;
//   fn_3neq4 = f_neq(3,4);  // = function() 3!=4;
function f_neq(a,b) = f_2arg_simple(function (a,b) a!=b)(a,b);


// Function: f_approx()
// Synopsis: Returns a function to compare if `a` is approximately equal to `b`.
// Topics: Function Literals, Comparators
// See Also: f_cmp(), f_gt(), f_lt(), f_gte(), f_lte(), f_eq(), f_neq(), f_approx(), f_napprox()
// Usage:
//   fn = f_approx();
//   fn = f_approx(b);
//   fn = f_approx(a,b);
// Description:
//   A factory that generates function literals based on `approx(a,b)`, where
//   one or both arguments can be replaced with constants.
// Example:
//   fn_approx = f_approx();       // = function(a,b) approx(a,b);
//   fn_approx3 = f_approx(3);     // = function(a) approx(a,3);
//   fn_3approx4 = f_approx(3,4);  // = function() approx(3,4);
function f_approx(a,b) = f_2arg_simple(function (a,b) approx(a,b))(a,b);


// Function: f_napprox()
// Synopsis: Returns a function to compare if `a` is not approximately equal to `b`.
// Topics: Function Literals, Comparators
// See Also: f_cmp(), f_gt(), f_lt(), f_gte(), f_lte(), f_eq(), f_neq(), f_approx(), f_napprox()
// Usage:
//   fn = f_napprox();
//   fn = f_napprox(b);
//   fn = f_napprox(a,b);
// Description:
//   A factory that generates function literals based on `!approx(a,b)`, where
//   one or both arguments can be replaced with constants.
// Example:
//   fn_napprox = f_napprox();       // = function(a,b) napprox(a,b);
//   fn_napprox3 = f_napprox(3);     // = function(a) napprox(a,3);
//   fn_3napprox4 = f_napprox(3,4);  // = function() napprox(3,4);
function f_napprox(a,b) = f_2arg_simple(function (a,b) !approx(a,b))(a,b);



//////////////////////////////////////////////////////////////////////
// Section: Logic Operators


// Function: f_or()
// Synopsis: Returns a function to check if either `a` or `b` is true.
// Topics: Function Literals, Logic, Boolean Operations
// See Also: f_or(), f_and(), f_nor(), f_nand(), f_xor(), f_not()
// Usage:
//   fn = f_or();
//   fn = f_or(a=);
//   fn = f_or(b=);
//   fn = f_or(a=,b=);
// Description:
//   A factory that generates function literals based on `a || b`, where
//   either or both of the `a` or `b` arguments can be replaced with constants.
// Arguments:
//   a = If given, replaces the first argument.
//   b = If given, replaces the second argument.
function f_or(a,b) = f_2arg(function(a,b) (a || b))(a,b);


// Function: f_and()
// Synopsis: Returns a function to check if both `a` and `b` are true.
// Topics: Function Literals, Logic, Boolean Operations
// See Also: f_or(), f_and(), f_nor(), f_nand(), f_xor(), f_not()
// Usage:
//   fn = f_and();
//   fn = f_and(a=);
//   fn = f_and(b=);
//   fn = f_and(a=,b=);
// Description:
//   A factory that generates function literals based on `a && b`, where
//   either or both of the `a` or `b` arguments can be replaced with constants.
// Arguments:
//   a = If given, replaces the first argument.
//   b = If given, replaces the second argument.
function f_and(a,b) = f_2arg(function(a,b) (a && b))(a,b);


// Function: f_nor()
// Synopsis: Returns a function to check if neither `a` nor `b` are true.
// Topics: Function Literals, Logic, Boolean Operations
// See Also: f_or(), f_and(), f_nor(), f_nand(), f_xor(), f_not()
// Usage:
//   fn = f_nor();
//   fn = f_nor(a=);
//   fn = f_nor(b=);
//   fn = f_nor(a=,b=);
// Description:
//   A factory that generates function literals based on `!(a || b)`, where
//   either or both of the `a` or `b` arguments can be replaced with constants.
// Arguments:
//   a = If given, replaces the first argument.
//   b = If given, replaces the second argument.
function f_nor(a,b) = f_2arg(function(a,b) !(a || b))(a,b);


// Function: f_nand()
// Synopsis: Returns a function to check if `a` and `b` are not both true.
// Topics: Function Literals, Logic, Boolean Operations
// See Also: f_or(), f_and(), f_nor(), f_nand(), f_xor(), f_not()
// Usage:
//   fn = f_nand();
//   fn = f_nand(a=);
//   fn = f_nand(b=);
//   fn = f_nand(a=,b=);
// Description:
//   A factory that generates function literals based on `!(a && b)`, where
//   either or both of the `a` or `b` arguments can be replaced with constants.
// Arguments:
//   a = If given, replaces the first argument.
//   b = If given, replaces the second argument.
function f_nand(a,b) = f_2arg(function(a,b) !(a && b))(a,b);


// Function: f_xor()
// Synopsis: Returns a function to check if either `a` or `b`, but not both, are true.
// Topics: Function Literals, Logic, Boolean Operations
// See Also: f_or(), f_and(), f_nor(), f_nand(), f_xor(), f_not()
// Usage:
//   fn = f_xor();
//   fn = f_xor(a=);
//   fn = f_xor(b);
//   fn = f_xor(a=,b=);
// Description:
//   A factory that generates function literals based on `(!a && b) || (a && !b)`, where
//   either or both of the `a` or `b` arguments can be replaced with constants.
// Arguments:
//   a = If given, replaces the first argument.
//   b = If given, replaces the second argument.
function f_xor(a,b) = f_2arg(function(a,b) (!a && b) || (a && !b))(a,b);


// Function: f_not()
// Synopsis: Returns a function to check if `a` is not true.
// Topics: Function Literals, Logic, Boolean Operations
// See Also: f_or(), f_and(), f_nor(), f_nand(), f_xor(), f_not()
// Usage:
//   fn = f_not();
//   fn = f_not(a);
// Description:
//   A factory that generates function literals based on `!a`, where the `a`
//   argument can be replaced with a constant.
// Arguments:
//   a = If given, replaces the argument.
function f_not(a) = f_1arg(function(a) !a)(a);


// Function: f_even()
// Synopsis: Returns a function to check if `a` is an even number.
// Topics: Function Literals, Math Operators
// See Also: f_even(), f_odd()
// Usage:
//   fn = f_even();
//   fn = f_even(a);
// Description:
//   A factory that generates function literals based on `a % 2 == 0`, where the `a`
//   argument can optionally be replaced with a constant.
// Arguments:
//   a = If given, replaces the argument.
// Example:
//   l2 = filter(f_even(), [3,4,5,6,7,8]);  // Returns: [4,6,8]
function f_even(a) = f_1arg(function(a) a % 2 == 0)(a);


// Function: f_odd()
// Synopsis: Returns a function to check if `a` is an odd number.
// Topics: Function Literals, Math Operators
// See Also: f_even(), f_odd()
// Usage:
//   fn = f_odd();
//   fn = f_odd(a);
// Description:
//   A factory that generates function literals based on `a % 2 != 0`, where the `a`
//   argument can optionally be replaced with a constant.
// Arguments:
//   a = If given, replaces the argument.
// Example:
//   l2 = filter(f_odd(), [3,4,5,6,7,8]);  // Returns: [3,5,7]
function f_odd(a) = f_1arg(function(a) a % 2 != 0)(a);



//////////////////////////////////////////////////////////////////////
// Section: Math Operators


// Function: f_add()
// Synopsis: Returns a function to add `a` and `b`.
// Topics: Function Literals, Math Operators
// See Also: f_add(), f_sub(), f_mul(), f_div(), f_mod(), f_pow(), f_neg()
// Usage:
//   fn = f_add();
//   fn = f_add(a=);
//   fn = f_add(b);
//   fn = f_add(a=,b=);
// Description:
//   A factory that generates function literals based on `a + b`, where either
//   or both of the `a` or `b` arguments can be replaced with constants.
// Arguments:
//   a = If given, replaces the first argument.
//   b = If given, replaces the second argument.
function f_add(a,b) = f_2arg(function(a,b) a + b)(a,b);


// Function: f_sub()
// Synopsis: Returns a function to subtract `a` from `b`.
// Topics: Function Literals, Math Operators
// See Also: f_add(), f_sub(), f_mul(), f_div(), f_mod(), f_pow(), f_neg()
// Usage:
//   fn = f_sub();
//   fn = f_sub(a=);
//   fn = f_sub(b);
//   fn = f_sub(a=,b=);
// Description:
//   A factory that generates function literals based on `a - b`, where either
//   or both of the `a` or `b` arguments can be replaced with constants.
// Arguments:
//   a = If given, replaces the first argument.
//   b = If given, replaces the second argument.
function f_sub(a,b) = f_2arg(function(a,b) a - b)(a,b);


// Function: f_mul()
// Synopsis: Returns a function to multiply `a` by `b`.
// Topics: Function Literals, Math Operators
// See Also: f_add(), f_sub(), f_mul(), f_div(), f_mod(), f_pow(), f_neg()
// Usage:
//   fn = f_mul();
//   fn = f_mul(a=);
//   fn = f_mul(b);
//   fn = f_mul(a=,b=);
// Description:
//   A factory that generates function literals based on `a * b`, where either
//   or both of the `a` or `b` arguments can be replaced with constants.
// Arguments:
//   a = If given, replaces the first argument.
//   b = If given, replaces the second argument.
function f_mul(a,b) = f_2arg(function(a,b) a * b)(a,b);


// Function: f_div()
// Synopsis: Returns a function to divide `a` by `b`.
// Topics: Function Literals, Math Operators
// See Also: f_add(), f_sub(), f_mul(), f_div(), f_mod(), f_pow(), f_neg()
// Usage:
//   fn = f_div();
//   fn = f_div(a=);
//   fn = f_div(b);
//   fn = f_div(a=,b=);
// Description:
//   A factory that generates function literals based on `a / b`, where either
//   or both of the `a` or `b` arguments can be replaced with constants.
// Arguments:
//   a = If given, replaces the first argument.
//   b = If given, replaces the second argument.
function f_div(a,b) = f_2arg(function(a,b) a / b)(a,b);


// Function: f_mod()
// Synopsis: Returns a function to calculate the modulo of `a` divided by `b`.
// Topics: Function Literals, Math Operators
// See Also: f_add(), f_sub(), f_mul(), f_div(), f_mod(), f_pow(), f_neg()
// Usage:
//   fn = f_mod();
//   fn = f_mod(a=);
//   fn = f_mod(b);
//   fn = f_mod(a=,b=);
// Description:
//   A factory that generates function literals based on `a % b`, where either
//   or both of the `a` or `b` arguments can be replaced with constants.
// Arguments:
//   a = If given, replaces the first argument.
//   b = If given, replaces the second argument.
function f_mod(a,b) = f_2arg(function(a,b) a % b)(a,b);


// Function: f_pow()
// Synopsis: Returns a function to calculate `a` to the power of `b`.
// Topics: Function Literals, Math Operators
// See Also: f_add(), f_sub(), f_mul(), f_div(), f_mod(), f_pow(), f_neg()
// Usage:
//   fn = f_pow();
//   fn = f_pow(a=);
//   fn = f_pow(b);
//   fn = f_pow(a=,b=);
// Description:
//   A factory that generates function literals based on `pow(a,b)`, where either
//   or both of the `a` or `b` arguments can be replaced with constants.
// Arguments:
//   a = If given, replaces the first argument.
//   b = If given, replaces the second argument.
function f_pow(a,b) = f_2arg(function(a,b) pow(a,b))(a,b);


// Function: f_neg()
// Synopsis: Returns a function to calculate `-a`
// Topics: Function Literals, Math Operators
// See Also: f_add(), f_sub(), f_mul(), f_div(), f_mod(), f_pow(), f_neg()
// Usage:
//   fn = f_neg();
//   fn = f_neg(a);
// Description:
//   A factory that generates function literals based on `-a`, where the `a`
//   argument can optionally be replaced with a constant.
// Arguments:
//   a = If given, replaces the argument.
function f_neg(a) = f_1arg(function(a) -a)(a);



//////////////////////////////////////////////////////////////////////
// Section: Min/Max Operators


// Function: f_min()
// Synopsis: Returns a function to calculate the minimum value of a list.
// Topics: Function Literals, Math Operators
// See Also: f_min(), f_max(), f_min2(), f_max2(), f_min3(), f_max3()
// Usage:
//   fn = f_min();
//   fn = f_min(a);
// Description:
//   A factory that generates function literals based on `min(a)`, where the `a`
//   argument can optionally be replaced with a constant.
// Arguments:
//   a = If given, replaces the argument.
function f_min(a) = f_1arg(function(a) min(a))(a);


// Function: f_max()
// Synopsis: Returns a function to calculate the maximum value of a list.
// Topics: Function Literals, Math Operators
// See Also: f_min(), f_max(), f_min2(), f_max2(), f_min3(), f_max3()
// Usage:
//   fn = f_max();
//   fn = f_max(a);
// Description:
//   A factory that generates function literals based on `max(a)`, where the `a`
//   argument can optionally be replaced with a constant.
// Arguments:
//   a = If given, replaces the argument.
function f_max(a) = f_1arg(function(a) max(a))(a);


// Function: f_min2()
// Synopsis: Returns a function to calculate the minimum of two values.
// Topics: Function Literals, Math Operators
// See Also: f_min(), f_max(), f_min2(), f_max2(), f_min3(), f_max3()
// Usage:
//   fn = f_min2();
//   fn = f_min2(a=);
//   fn = f_min2(b);
//   fn = f_min2(a=,b=);
// Description:
//   A factory that generates function literals based on `min(a,b)`, where either
//   or both of the `a` or `b` arguments can be replaced with constants.
// Arguments:
//   a = If given, replaces the first argument.
//   b = If given, replaces the second argument.
function f_min2(a,b) = f_2arg(function(a,b) min(a,b))(a,b);


// Function: f_max2()
// Synopsis: Returns a function to calculate the maximum of two values.
// Topics: Function Literals, Math Operators
// See Also: f_min(), f_max(), f_min2(), f_max2(), f_min3(), f_max3()
// Usage:
//   fn = f_max2();
//   fn = f_max2(a=);
//   fn = f_max2(b);
//   fn = f_max2(a=,b=);
// Description:
//   A factory that generates function literals based on `max(a,b)`, where either
//   or both of the `a` or `b` arguments can be replaced with constants.
// Arguments:
//   a = If given, replaces the first argument.
//   b = If given, replaces the second argument.
function f_max2(a,b) = f_2arg(function(a,b) max(a,b))(a,b);


// Function: f_min3()
// Synopsis: Returns a function to calculate the minimum of three values.
// Topics: Function Literals, Math Operators
// See Also: f_min(), f_max(), f_min2(), f_max2(), f_min3(), f_max3()
// Usage:
//   fn = f_min3();
//   fn = f_min3(a=);
//   fn = f_min3(b=);
//   fn = f_min3(c=);
//   fn = f_min3(a=,b=);
//   fn = f_min3(b=,c=);
//   fn = f_min3(a=,c=);
//   fn = f_min3(a=,b=,c=);
// Description:
//   A factory that generates function literals based on `min(a,b,c)`, where any
//   or all of the `a`, `b`, or`c` arguments can be replaced with constants.
// Arguments:
//   a = If given, replaces the first argument.
//   b = If given, replaces the second argument.
//   c = If given, replaces the third argument.
function f_min3(a,b,c) = f_3arg(function(a,b,c) min(a,b,c))(a,b,c);


// Function: f_max3()
// Synopsis: Returns a function to calculate the maximum of three values.
// Topics: Function Literals, Math Operators
// See Also: f_min(), f_max(), f_min2(), f_max2(), f_min3(), f_max3()
// Usage:
//   fn = f_max3();
//   fn = f_max3(a=);
//   fn = f_max3(b=);
//   fn = f_max3(c=);
//   fn = f_max3(a=,b=);
//   fn = f_max3(b=,c=);
//   fn = f_max3(a=,c=);
//   fn = f_max3(a=,b=,c=);
// Description:
//   A factory that generates function literals based on `min(a,b,c)`, where any
//   or all of the `a`, `b`, or`c` arguments can be replaced with constants.
// Arguments:
//   a = If given, replaces the first argument.
//   b = If given, replaces the second argument.
//   c = If given, replaces the third argument.
function f_max3(a,b,c) = f_3arg(function(a,b,c) max(a,b,c))(a,b,c);



//////////////////////////////////////////////////////////////////////
// Section: Trigonometry Operators


// Function: f_sin()
// Synopsis: Returns a function to calculate the sine of a value.
// Topics: Function Literals, Math Operators
// See Also: f_sin(), f_cos(), f_tan(), f_asin(), f_acos(), f_atan(), f_atan2()
// Usage:
//   fn = f_sin();
//   fn = f_sin(a);
// Description:
//   A factory that generates function literals based on `sin(a)`, where the `a`
//   argument can optionally be replaced with a constant.
// Arguments:
//   a = If given, replaces the argument.
function f_sin(a)  = f_1arg(function(a) sin(a))(a);


// Function: f_cos()
// Synopsis: Returns a function to calculate the cosine of a value.
// Topics: Function Literals, Math Operators
// See Also: f_sin(), f_cos(), f_tan(), f_asin(), f_acos(), f_atan(), f_atan2()
// Usage:
//   fn = f_cos();
//   fn = f_cos(a);
// Description:
//   A factory that generates function literals based on `cos(a)`, where the `a`
//   argument can optionally be replaced with a constant.
// Arguments:
//   a = If given, replaces the argument.
function f_cos(a)  = f_1arg(function(a) cos(a))(a);


// Function: f_tan()
// Synopsis: Returns a function to calculate the tangent of a value.
// Topics: Function Literals, Math Operators
// See Also: f_sin(), f_cos(), f_tan(), f_asin(), f_acos(), f_atan(), f_atan2()
// Usage:
//   fn = f_tan();
//   fn = f_tan(a);
// Description:
//   A factory that generates function literals based on `tan(a)`, where the `a`
//   argument can optionally be replaced with a constant.
// Arguments:
//   a = If given, replaces the argument.
function f_tan(a)  = f_1arg(function(a) tan(a))(a);


// Function: f_asin()
// Synopsis: Returns a function to calculate the arcsine of a value.
// Topics: Function Literals, Math Operators
// See Also: f_sin(), f_cos(), f_tan(), f_asin(), f_acos(), f_atan(), f_atan2()
// Usage:
//   fn = f_asin();
//   fn = f_asin(a);
// Description:
//   A factory that generates function literals based on `asin(a)`, where the `a`
//   argument can optionally be replaced with a constant.
// Arguments:
//   a = If given, replaces the argument.
function f_asin(a) = f_1arg(function(a) asin(a))(a);


// Function: f_acos()
// Synopsis: Returns a function to calculate the arccosine of a value.
// Topics: Function Literals, Math Operators
// See Also: f_sin(), f_cos(), f_tan(), f_asin(), f_acos(), f_atan(), f_atan2()
// Usage:
//   fn = f_acos();
//   fn = f_acos(a);
// Description:
//   A factory that generates function literals based on `acos(a)`, where the `a`
//   argument can optionally be replaced with a constant.
// Arguments:
//   a = If given, replaces the argument.
function f_acos(a) = f_1arg(function(a) acos(a))(a);


// Function: f_atan()
// Synopsis: Returns a function to calculate the arctangent of a value.
// Topics: Function Literals, Math Operators
// See Also: f_sin(), f_cos(), f_tan(), f_asin(), f_acos(), f_atan(), f_atan2()
// Usage:
//   fn = f_atan();
//   fn = f_atan(a);
// Description:
//   A factory that generates function literals based on `atan(a)`, where the `a`
//   argument can optionally be replaced with a constant.
// Arguments:
//   a = If given, replaces the argument.
function f_atan(a) = f_1arg(function(a) atan(a))(a);


// Function: f_atan2()
// Synopsis: Returns a function to calculate the arctangent of `y` and `x`
// Topics: Function Literals, Math Operators
// See Also: f_sin(), f_cos(), f_tan(), f_asin(), f_acos(), f_atan(), f_atan2()
// Usage:
//   fn = f_atan2();
//   fn = f_atan2(a=);
//   fn = f_atan2(b);
//   fn = f_atan2(a=,b=);
// Description:
//   A factory that generates function literals based on `atan2(a,b)`, where either
//   or both of the `a` or `b` arguments can be replaced with constants.
// Arguments:
//   a = If given, replaces the first argument.
//   b = If given, replaces the second argument.
function f_atan2(a,b) = f_2arg(function(a,b) atan2(a,b))(a,b);



//////////////////////////////////////////////////////////////////////
// Section: String Operators


// Function: f_len()
// Synopsis: Returns a function to calculate the length of a string or list.
// Topics: Function Literals, String Operators
// See Also: f_len(), f_chr(), f_ord(), f_str(), f_str2(), f_str3()
// Usage:
//   fn = f_len();
//   fn = f_len(a);
// Description:
//   A factory that generates function literals based on `len(a)`, where the `a`
//   argument can optionally be replaced with a constant.
// Arguments:
//   a = If given, replaces the argument.
function f_len(a) = f_1arg(function(a) len(a))(a);


// Function: f_chr()
// Synopsis: Returns a function to get a string character from its ordinal number.
// Topics: Function Literals, String Operators
// See Also: f_len(), f_chr(), f_ord(), f_str(), f_str2(), f_str3()
// Usage:
//   fn = f_chr();
//   fn = f_chr(a);
// Description:
//   A factory that generates function literals based on `chr(a)`, where the `a`
//   argument can optionally be replaced with a constant.
// Arguments:
//   a = If given, replaces the argument.
function f_chr(a) = f_1arg(function(a) chr(a))(a);


// Function: f_ord()
// Synopsis: Returns a function to get the ordinal number of a string character.
// Topics: Function Literals, String Operators
// See Also: f_len(), f_chr(), f_ord(), f_str(), f_str2(), f_str3()
// Usage:
//   fn = f_ord();
//   fn = f_ord(a);
// Description:
//   A factory that generates function literals based on `ord(a)`, where the `a`
//   argument can optionally be replaced with a constant.
// Arguments:
//   a = If given, replaces the argument.
function f_ord(a) = f_1arg(function(a) ord(a))(a);


// Function: f_str()
// Synopsis: Returns a function to get the string representation of an arbitrary value.
// Topics: Function Literals, String Operators
// See Also: f_len(), f_chr(), f_ord(), f_str(), f_str2(), f_str3()
// Usage:
//   fn = f_str();
//   fn = f_str(a);
// Description:
//   A factory that generates function literals based on `str(a)`, where the `a`
//   argument can optionally be replaced with a constant.
// Arguments:
//   a = If given, replaces the argument.
function f_str(a) = f_1arg(function(a) str(a))(a);


// Function: f_str2()
// Synopsis: Returns a function to concatenate the string representations of two arbitrary values.
// Topics: Function Literals, String Operators
// See Also: f_len(), f_chr(), f_ord(), f_str(), f_str2(), f_str3()
// Usage:
//   fn = f_str2();
//   fn = f_str2(a=);
//   fn = f_str2(b);
//   fn = f_str2(a=,b=);
// Description:
//   A factory that generates function literals based on `str(a,b)`, where either
//   or both of the `a` or `b` arguments can be replaced with constants.
// Arguments:
//   a = If given, replaces the first argument.
//   b = If given, replaces the second argument.
function f_str2(a,b) = f_2arg(function(a,b) str(a,b))(a,b);


// Function: f_str3()
// Synopsis: Returns a function to concatenate the string representations of three arbitrary values.
// Topics: Function Literals, Math Operators
// See Also: f_len(), f_chr(), f_ord(), f_str(), f_str2(), f_str3()
// Usage:
//   fn = f_str3();
//   fn = f_str3(a=);
//   fn = f_str3(b=);
//   fn = f_str3(c=);
//   fn = f_str3(a=,b=);
//   fn = f_str3(b=,c=);
//   fn = f_str3(a=,c=);
//   fn = f_str3(a=,b=,c=);
// Description:
//   A factory that generates function literals based on `str(a,b,c)`, where any
//   or all of the `a`, `b`, or`c` arguments can be replaced with constants.
// Arguments:
//   a = If given, replaces the first argument.
//   b = If given, replaces the second argument.
//   c = If given, replaces the third argument.
function f_str3(a,b,c) = f_3arg(function(a,b,c) str(a,b,c))(a,b,c);



//////////////////////////////////////////////////////////////////////
// Section: Miscellaneous Operators


// Function: f_floor()
// Synopsis: Returns a function to calculate the integer floor of a given number.
// Topics: Function Literals, Math Operators
// See Also: f_floor(), f_ceil(), f_round()
// Usage:
//   fn = f_floor();
//   fn = f_floor(a);
// Description:
//   A factory that generates function literals based on `floor(a)`, where the `a`
//   argument can optionally be replaced with a constant.
// Arguments:
//   a = If given, replaces the argument.
function f_floor(a) = f_1arg(function(a) floor(a))(a);


// Function: f_round()
// Synopsis: Returns a function to calculate the integer rounding of a given number.
// Topics: Function Literals, Math Operators
// See Also: f_floor(), f_ceil(), f_round()
// Usage:
//   fn = f_round();
//   fn = f_round(a);
// Description:
//   A factory that generates function literals based on `round(a)`, where the `a`
//   argument can optionally be replaced with a constant.
// Arguments:
//   a = If given, replaces the argument.
function f_round(a) = f_1arg(function(a) round(a))(a);


// Function: f_ceil()
// Synopsis: Returns a function to calculate the integer ceiling of a given number.
// Topics: Function Literals, Math Operators
// See Also: f_floor(), f_ceil(), f_round()
// Usage:
//   fn = f_ceil();
//   fn = f_ceil(a);
// Description:
//   A factory that generates function literals based on `ceil(a)`, where the `a`
//   argument can optionally be replaced with a constant.
// Arguments:
//   a = If given, replaces the argument.
function f_ceil(a)  = f_1arg(function(a) ceil(a))(a);


// Function: f_abs()
// Synopsis: Returns a function to calculate the absolute value of a given number.
// Topics: Function Literals, Math Operators
// See Also: f_abs(), f_sign(), f_ln(), f_log(), f_exp(), f_sqr(), f_sqrt()
// Usage:
//   fn = f_abs();
//   fn = f_abs(a);
// Description:
//   A factory that generates function literals based on `abs(a)`, where the `a`
//   argument can optionally be replaced with a constant.
// Arguments:
//   a = If given, replaces the argument.
function f_abs(a)   = f_1arg(function(a) abs(a))(a);


// Function: f_sign()
// Synopsis: Returns a function to calculate the sign of a given number.
// Topics: Function Literals, Math Operators
// See Also: f_abs(), f_sign(), f_ln(), f_log(), f_exp(), f_sqr(), f_sqrt()
// Usage:
//   fn = f_sign();
//   fn = f_sign(a);
// Description:
//   A factory that generates function literals based on `sign(a)`, where the `a`
//   argument can optionally be replaced with a constant.
// Arguments:
//   a = If given, replaces the argument.
function f_sign(a)  = f_1arg(function(a) sign(a))(a);


// Function: f_ln()
// Synopsis: Returns a function to calculate the natural logarithm of a given number.
// Topics: Function Literals, Math Operators
// See Also: f_abs(), f_sign(), f_ln(), f_log(), f_exp(), f_sqr(), f_sqrt()
// Usage:
//   fn = f_ln();
//   fn = f_ln(a);
// Description:
//   A factory that generates function literals based on `ln(a)`, where the `a`
//   argument can optionally be replaced with a constant.
// Arguments:
//   a = If given, replaces the argument.
function f_ln(a)    = f_1arg(function(a) ln(a))(a);


// Function: f_log()
// Synopsis: Returns a function to calculate the base 10 logarithm of a given number.
// Topics: Function Literals, Math Operators
// See Also: f_abs(), f_sign(), f_ln(), f_log(), f_exp(), f_sqr(), f_sqrt()
// Usage:
//   fn = f_log();
//   fn = f_log(a);
// Description:
//   A factory that generates function literals based on `log(a)`, where the `a`
//   argument can optionally be replaced with a constant.
// Arguments:
//   a = If given, replaces the argument.
function f_log(a)   = f_1arg(function(a) log(a))(a);


// Function: f_exp()
// Synopsis: Returns a function to calculate the natural exponent of a given number.
// Topics: Function Literals, Math Operators
// See Also: f_abs(), f_sign(), f_ln(), f_log(), f_exp(), f_sqr(), f_sqrt()
// Usage:
//   fn = f_exp();
//   fn = f_exp(a);
// Description:
//   A factory that generates function literals based on `exp(a)`, where the `a`
//   argument can optionally be replaced with a constant.
// Arguments:
//   a = If given, replaces the argument.
function f_exp(a)   = f_1arg(function(a) exp(a))(a);


// Function: f_sqr()
// Synopsis: Returns a function to calculate the square of a given number.
// Topics: Function Literals, Math Operators
// See Also: f_abs(), f_sign(), f_ln(), f_log(), f_exp(), f_sqr(), f_sqrt()
// Usage:
//   fn = f_sqr();
//   fn = f_sqr(a);
// Description:
//   A factory that generates function literals based on `a*a`, where the `a`
//   argument can optionally be replaced with a constant.
// Arguments:
//   a = If given, replaces the argument.
function f_sqr(a)   = f_1arg(function(a) a*a)(a);


// Function: f_sqrt()
// Synopsis: Returns a function to calculate the square root of a given number.
// Topics: Function Literals, Math Operators
// See Also: f_abs(), f_sign(), f_ln(), f_log(), f_exp(), f_sqr(), f_sqrt()
// Usage:
//   fn = f_sqrt();
//   fn = f_sqrt(a);
// Description:
//   A factory that generates function literals based on `sqrt(a)`, where the `a`
//   argument can optionally be replaced with a constant.
// Arguments:
//   a = If given, replaces the argument.
function f_sqrt(a)  = f_1arg(function(a) sqrt(a))(a);


// Function: f_norm()
// Synopsis: Returns a function to calculate the norm of a given vector.
// Topics: Function Literals, Vectors
// See Also: f_norm(), f_abs(), f_sign(), f_cross()
// Usage:
//   fn = f_norm();
//   fn = f_norm(a);
// Description:
//   A factory that generates function literals based on `norm(a)`, where the `a`
//   argument can optionally be replaced with a constant.
// Arguments:
//   a = If given, replaces the argument.
function f_norm(a)  = f_1arg(function(a) norm(a))(a);


// Function: f_cross()
// Synopsis: Returns a function to calculate the norm of a given vector.
// Topics: Function Literals, Vectors
// See Also: f_norm(), f_abs(), f_sign(), f_cross()
// Usage:
//   fn = f_cross();
//   fn = f_cross(a=);
//   fn = f_cross(b);
//   fn = f_cross(a=,b=);
// Description:
//   A factory that generates function literals based on `str(a,b)`, where either
//   or both of the `a` or `b` arguments can be replaced with constants.
// Arguments:
//   a = If given, replaces the first argument.
//   b = If given, replaces the second argument.
function f_cross(a,b) = f_2arg(function(a,b) cross(a,b))(a,b);


// Section: Type Queries

// Function: f_is_def()
// Synopsis: Returns a function to determine if a value is not `undef`.
// Topics: Function Literals, Type Queries
// See Also: f_is_undef(), f_is_bool(), f_is_num(), f_is_string(), f_is_list()
// Usage:
//   fn = f_is_def();
// Description:
//   A factory that returns function literals equivalent to `is_def(a)`.
// Arguments:
//   a = If given, replaces the argument.
function f_is_def(a) = f_1arg(function (a) is_def(a))(a);


// Function: f_is_undef()
// Synopsis: Returns a function to determine if a value is `undef`.
// Topics: Function Literals, Type Queries
// See Also: f_is_bool(), f_is_num(), f_is_string(), f_is_list()
// Usage:
//   fn = f_is_undef();
// Description:
//   A factory that returns function literals equivalent to `is_undef(a)`.
// Arguments:
//   a = If given, replaces the argument.
function f_is_undef(a) = f_1arg(function (a) is_undef(a))(a);


// Function: f_is_bool()
// Synopsis: Returns a function to determine if a value is a boolean.
// Topics: Function Literals, Type Queries
// See Also: f_is_undef(), f_is_num(), f_is_string(), f_is_list()
// Usage:
//   fn = f_is_bool();
// Description:
//   A factory that returns function literals equivalent to `is_bool(a)`.
// Arguments:
//   a = If given, replaces the argument.
function f_is_bool(a) = f_1arg(function (a) is_bool(a))(a);


// Function: f_is_num()
// Synopsis: Returns a function to determine if a value is a number.
// Topics: Function Literals, Type Queries
// See Also: f_is_undef(), f_is_bool(), f_is_string(), f_is_list()
// Usage:
//   fn = f_is_num();
// Description:
//   A factory that returns function literals equivalent to `is_num(a)`.
// Arguments:
//   a = If given, replaces the argument.
function f_is_num(a) = f_1arg(function (a) is_num(a))(a);


// Function: f_is_int()
// Synopsis: Returns a function to determine if a value is an integer number.
// Topics: Function Literals, Type Queries
// See Also: f_is_undef(), f_is_bool(), f_is_num(), f_is_string(), f_is_list()
// Usage:
//   fn = f_is_int();
// Description:
//   A factory that returns function literals equivalent to `is_int(a)`.
// Arguments:
//   a = If given, replaces the argument.
function f_is_int(a) = f_1arg(function (a) is_int(a))(a);


// Function: f_is_nan()
// Synopsis: Returns a function to determine if a value is a number type that is Not a Number (NaN).
// Topics: Function Literals, Type Queries
// See Also: f_is_undef(), f_is_bool(), f_is_num(), f_is_int(), f_is_string(), f_is_list()
// Usage:
//   fn = f_is_nan();
// Description:
//   A factory that returns function literals equivalent to `is_nan(a)`.
// Arguments:
//   a = If given, replaces the argument.
function f_is_nan(a) = f_1arg(function (a) is_nan(a))(a);


// Function: f_is_finite()
// Synopsis: Returns a function to determine if a value is a number type that is finite.
// Topics: Function Literals, Type Queries
// See Also: f_is_undef(), f_is_bool(), f_is_num(), f_is_int(), f_is_string(), f_is_list()
// Usage:
//   fn = f_is_finite();
// Description:
//   A factory that returns function literals equivalent to `is_finite(a)`.
// Arguments:
//   a = If given, replaces the argument.
function f_is_finite(a) = f_1arg(function (a) is_finite(a))(a);


// Function: f_is_string()
// Synopsis: Returns a function to determine if a value is a string.
// Topics: Function Literals, Type Queries
// See Also: f_is_undef(), f_is_bool(), f_is_num(), f_is_int(), f_is_list()
// Usage:
//   fn = f_is_string();
// Description:
//   A factory that returns function literals equivalent to `is_string(a)`.
// Arguments:
//   a = If given, replaces the argument.
function f_is_string(a) = f_1arg(function (a) is_string(a))(a);


// Function: f_is_list()
// Synopsis: Returns a function to determine if a value is a list.
// Topics: Function Literals, Type Queries
// See Also: f_is_undef(), f_is_bool(), f_is_num(), f_is_int(), f_is_string(), f_is_list()
// Usage:
//   fn = f_is_list();
// Description:
//   A factory that returns function literals equivalent to `is_list(a)`.
// Arguments:
//   a = If given, replaces the argument.
function f_is_list(a) = f_1arg(function (a) is_list(a))(a);


// Function: f_is_range()
// Synopsis: Returns a function to determine if a value is a range.
// Topics: Function Literals, Type Queries
// See Also: f_is_undef(), f_is_bool(), f_is_num(), f_is_int(), f_is_string(), f_is_list()
// Usage:
//   fn = f_is_range();
// Description:
//   A factory that returns function literals equivalent to `is_range(a)`.
// Arguments:
//   a = If given, replaces the argument.
function f_is_range(a) = f_1arg(function (a) is_range(a))(a);


// Function: f_is_function()
// Synopsis: Returns a function to determine if a value is a function literal.
// Topics: Function Literals, Type Queries
// See Also: f_is_undef(), f_is_bool(), f_is_num(), f_is_int(), f_is_string(), f_is_list()
// Usage:
//   fn = f_is_function();
// Description:
//   A factory that returns function literals equivalent to `is_function(a)`.
// Arguments:
//   a = If given, replaces the argument.
function f_is_function(a) = f_1arg(function (a) is_function(a))(a);


// Function: f_is_vector()
// Synopsis: Returns a function to determine if a value is a list of numbers.
// Topics: Function Literals, Type Queries
// See Also: f_is_undef(), f_is_bool(), f_is_num(), f_is_int(), f_is_string(), f_is_list()
// Usage:
//   fn = f_is_vector();
// Description:
//   A factory that returns function literals equivalent to `is_vector(a)`.
// Arguments:
//   a = If given, replaces the argument.
function f_is_vector(a,b) = f_2arg(function (a,b) is_vector(a,b))(a,b);


// Function: f_is_path()
// Synopsis: Returns a function to determine if a value is a Path (a list of points).
// Topics: Function Literals, Type Queries
// See Also: f_is_undef(), f_is_bool(), f_is_num(), f_is_int(), f_is_string(), f_is_list()
// Usage:
//   fn = f_is_path();
// Description:
//   A factory that returns function literals equivalent to `is_path(a)`.
// Arguments:
//   a = If given, replaces the argument.
function f_is_path(a,b) = f_2arg(function (a,b) is_path(a,b))(a,b);


// Function: f_is_region()
// Synopsis: Returns a function to determine if a value is a Region (a list of Paths).
// Topics: Function Literals, Type Queries
// See Also: f_is_undef(), f_is_bool(), f_is_num(), f_is_int(), f_is_string(), f_is_list()
// Usage:
//   fn = f_is_region();
// Description:
//   A factory that returns function literals equivalent to `is_region(a)`.
// Arguments:
//   a = If given, replaces the argument.
function f_is_region(a) = f_1arg(function (a) is_region(a))(a);


// Function: f_is_vnf()
// Synopsis: Returns a function to determine if a value is a VNF structure.
// Topics: Function Literals, Type Queries
// See Also: f_is_undef(), f_is_bool(), f_is_num(), f_is_int(), f_is_string(), f_is_list()
// Usage:
//   fn = f_is_vnf();
// Description:
//   A factory that returns function literals equivalent to `is_vnf(a)`.
// Arguments:
//   a = If given, replaces the argument.
function f_is_vnf(a) = f_1arg(function (a) is_vnf(a))(a);


// Function: f_is_patch()
// Synopsis: Returns a function to determine if a value is a Bezier Patch structure.
// Topics: Function Literals, Type Queries
// See Also: f_is_undef(), f_is_bool(), f_is_num(), f_is_int(), f_is_string(), f_is_list()
// Usage:
//   fn = f_is_patch();
// Description:
//   A factory that returns function literals equivalent to `is_patch(a)`.
// Arguments:
//   a = If given, replaces the argument.
function f_is_patch(a) = f_1arg(function (a) is_patch(a))(a);



// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
